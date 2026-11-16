#!/usr/bin/env python3
"""Check the documentation: every mermaid diagram renders (mmdc, all of them in one run), every relative link and image exists, every
#anchor names a heading of its file, and no $ is left in prose (GitHub reads a pair of them as LaTeX math;
code_addresses.py fixes addresses).

    python3 kit/check_docs.py [--case CASE] [--no-refdocs] [FILE.md ...]
                                                            # default: CASE's WALKTHROUGH.md, README.md, docs/**/*.md
    python3 kit/check_docs.py --repo [FILE.md ...]          # the repository's own: README, GUIDE, recipes, docs, kit
                                                            # (not the template's docs: their 11 and 12 come later)

A case: every figure under docs/img (any subfolder but docs/img/res, the resource previews src/res/README.md links)
must be linked by a document (GUIDE.md 4.2); the documents in docs/ subfolders (docs/texts, docs/audio) are checked
too. The resource READMEs (src/res/README.md, src/res/**/README.md) are read for their links: a figure they link
counts as linked, and a link of theirs to a file or heading that does not exist is a problem (their mermaid and
prose are not checked). Anchors follow GitHub's slugs: the heading's text with the Markdown marks dropped, lower case, every character
but letters, digits, '-', '_' and spaces removed, spaces as '-', a repeated slug numbered -1, -2. An explicit
<a name="..."> or id="..." counts as well. Links inside code (fenced blocks, `spans`) are not links.

Animation captions: two captions whose `kit/routine_anim.py` / `memanim.py` / `screen_anim.py` commands write one
`--out` file with different options are a problem (two writers of one name, the second's picture replaced the
first's); a GIF that records its command (kitlib.save_gif, from 2026-11-16) must match its caption's, `"..."` standing
for any one argument (`routine_anim.py --command GIF` prints the recorded one, --title in full).

Docs 11 and 12 (11-data-reference.md, 12-routine-reference.md) are written by kit/refdocs.py once the sources are
in; a link to one that does not exist yet is a problem that says so ("not generated yet: kit/refdocs.py --case C
writes docs 11 and 12"). --no-refdocs (stages 1 and 2, before refdocs) skips those links and their anchors and
counts them in the last line instead: "docs: ok (2 links to docs 11/12 skipped: not generated yet)".
"""
import glob
import os
import re
import subprocess
import sys
import tempfile
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import code_addresses  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
here = os.getcwd()
LINK = re.compile(r'!?\[(?:[^\[\]]|\[[^\]]*\])*\]\(\s*<?([^)\s>]*)>?(?:\s+"[^"]*")?\s*\)')
HTML_TARGET = re.compile(r'<(?:img|a)\b[^>]*?\b(?:src|href)="([^"]+)"')


def prose(text):
    """the text with fenced blocks and code spans blanked (line numbers kept)"""
    out, fence = [], False
    for line in text.split('\n'):
        if line.lstrip().startswith(('```', '~~~')):
            fence = not fence
            out.append('')
            continue
        out.append('' if fence else re.sub(r'(`+)(?:(?!\1).)+?\1', lambda m: ' ' * len(m.group()), line))
    return out


def slug_text(heading):
    """a heading's text as GitHub renders it: links to their text, images, HTML tags and code marks dropped"""
    t = re.sub(r'!\[[^\]]*\]\([^)]*\)', '', heading)
    t = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', t)
    t = re.sub(r'<[^>]+>', '', t)
    return t.replace('`', '')


def github_slug(heading):
    t = slug_text(heading).strip().lower()
    out = []
    for ch in t:
        cat = unicodedata.category(ch)
        if ch in '-_' or cat[0] in 'LN' or cat == 'Mn':
            out.append(ch)
        elif ch == ' ':
            out.append('-')
    return ''.join(out)


_anchors = {}


def anchors(path):
    """every anchor a Markdown file offers"""
    if path not in _anchors:
        found, seen, fence = set(), {}, False
        for line in open(path, encoding='utf-8').read().split('\n'):
            if line.lstrip().startswith(('```', '~~~')):
                fence = not fence
                continue
            if fence:
                continue
            m = re.match(r'^ {0,3}(#{1,6})\s+(.*?)\s*#*\s*$', line)
            if m:
                s = github_slug(m.group(2))
                n = seen.get(s, 0)
                seen[s] = n + 1
                found.add(s if n == 0 else '%s-%d' % (s, n))
            for name in re.findall(r'<a\s+(?:name|id)="([^"]+)"', line) + re.findall(r'\bid="([^"]+)"', line):
                found.add(name)
        _anchors[path] = found
    return _anchors[path]


def mermaid_blocks(text):
    return re.findall(r'```mermaid\n(.*?)```', text, re.S)


def check_entities(text, rel):
    bad = 0
    for n, block in enumerate(mermaid_blocks(text)):
        # GitHub decodes HTML entities before mermaid parses the block, so &quot; becomes a bare quote that ends
        # the label; mmdc accepts it. Mermaid's own escapes are #quot; #amp; #lt; #gt; #NN;.
        for ent in re.findall(r'&(?:[a-z]+|#\d+);', block):
            bad += 1
            print(f'{rel}: mermaid diagram {n + 1}: HTML entity {ent} (GitHub breaks on it; write #{ent[1:]})')
    return bad


def mmdc(source, out):
    return subprocess.run(['mmdc', '-q', '-i', source, '-o', out], capture_output=True, text=True)


def check_mermaid(blocks, tmp):
    """blocks: [(rel, n, text)]. Every mmdc run starts a headless browser (1-2 s, far more on a busy machine, most of
    it waiting), so all the diagrams are rendered in one run: one Markdown file of them all. Only when that fails is
    each diagram rendered on its own, to name the broken ones"""
    if not blocks:
        return 0
    together = os.path.join(tmp, 'all.md')
    with open(together, 'w', encoding='utf-8') as f:
        for _, _, block in blocks:
            f.write('```mermaid\n' + block + '```\n\n')
    if mmdc(together, os.path.join(tmp, 'all-out.md')).returncode == 0:
        return 0
    bad = 0
    for i, (rel, n, block) in enumerate(blocks):
        src = os.path.join(tmp, f'd{i}.mmd')
        open(src, 'w', encoding='utf-8').write(block)
        r = mmdc(src, os.path.join(tmp, f'd{i}.svg'))
        if r.returncode != 0:
            bad += 1
            print(f'{rel}: mermaid diagram {n + 1}: {r.stderr.strip()[:400]}')
    return bad


REFDOCS = ('11-data-reference.md', '12-routine-reference.md')
SKIPPED = []  # --no-refdocs: the links to docs 11 / 12 not generated yet


def check_links(path, text, linked, rel, no_refdocs=False):
    bad = 0
    base = os.path.dirname(path)
    for number, line in enumerate(prose(text), 1):
        for target in LINK.findall(line) + HTML_TARGET.findall(line):
            if not target or '://' in target or target.startswith(('mailto:', 'data:')):
                continue
            file_part, _, anchor = target.partition('#')
            dest = os.path.normpath(os.path.join(base, file_part)) if file_part else path
            if file_part:
                linked.add(dest)
                if not os.path.exists(dest):
                    if os.path.basename(dest) in REFDOCS and os.path.basename(os.path.dirname(dest)) == 'docs':
                        if no_refdocs:
                            SKIPPED.append(f'{rel}:{number}')
                            continue
                        bad += 1
                        print(f'{rel}:{number}: missing {target} (not generated yet: kit/refdocs.py --case C writes '
                              f'docs 11 and 12; --no-refdocs before that)')
                        continue
                    bad += 1
                    print(f'{rel}:{number}: missing {target}')
                    continue
            if anchor and dest.endswith('.md') and os.path.isfile(dest) and anchor not in anchors(dest):
                bad += 1
                where = os.path.relpath(dest, base) if file_part else 'this file'
                print(f'{rel}:{number}: no heading #{anchor} in {where}')
    return bad


COMMAND = re.compile(r'`(python3 [^`]*?kit/(routine_anim|memanim|screen_anim)\.py\b[^`]*)`')


def caption_commands(files):
    """{output file: [(rel, line, tokens)]} of the animation commands the documents give in code spans"""
    import shlex
    found = {}
    for path in files:
        text = open(path, encoding='utf-8').read()
        for m in COMMAND.finditer(text):
            try:
                tokens = shlex.split(m.group(1).replace('\n', ' '))
            except ValueError:
                continue
            out = next((tokens[k + 1] for k, t in enumerate(tokens[:-1]) if t == '--out'), None)
            if out:
                found.setdefault(os.path.normpath(out), []).append(
                    (os.path.relpath(path, here), text.count('\n', 0, m.start()) + 1, tokens))
    return found


def same_command(given, recorded):
    """a caption's tokens against the GIF's: '...' (`--title "..."`) stands for any one token; the tool by name"""
    if len(given) != len(recorded):
        return False
    for k, (a, b) in enumerate(zip(given, recorded)):
        if k == 1:
            a, b = os.path.basename(a), os.path.basename(b)
        if a != b and a != '...':
            return False
    return True


def check_commands(files):
    """two captions whose animation commands write one file (two writers of one name: the second's picture
    replaced the first's), and a caption whose command is not the one its GIF recorded (kitlib.save_gif)"""
    import shlex
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import kitlib
    bad = 0
    for out, uses in sorted(caption_commands(files).items()):
        if any(not (same_command(a[2], b[2]) or same_command(b[2], a[2])) for a in uses for b in uses):
            bad += 1
            print(f'{out}: written by {len(uses)} different commands: ' +
                  ', '.join(f'{rel}:{n}' for rel, n, _ in uses) + ' (one file a picture: NAME-what.gif)')
            continue
        recorded = kitlib.gif_command(os.path.join(here, out)) if out.endswith('.gif') else None
        if recorded:
            try:
                rec = shlex.split(recorded)
            except ValueError:
                continue
            for rel, n, tokens in uses:
                if not same_command(tokens, rec):
                    bad += 1
                    print(f'{rel}:{n}: the caption\'s command is not the one {out} was drawn with: {recorded}')
    return bad


def default_files(repo_mode):
    if repo_mode:
        files = [os.path.join(REPO, 'README.md'), os.path.join(REPO, 'GUIDE.md')]
        for pattern in ('recipes/*.md', 'docs/*.md', 'kit/*.md', 'kit/case-template/*.md', 'kit/case-template/briefs/*.md', 'signatures/*.md'):
            files += sorted(glob.glob(os.path.join(REPO, pattern), recursive=True))
        return [f for f in files if os.path.isfile(f)]
    files = [os.path.join(here, 'WALKTHROUGH.md'), os.path.join(here, 'README.md')]
    files += sorted(glob.glob(os.path.join(here, 'docs', '**', '*.md'), recursive=True))
    return [f for f in files if os.path.isfile(f)]


def res_readmes():
    """the case's resource READMEs: src/res/README.md and those of its subfolders"""
    return sorted(glob.glob(os.path.join(here, 'src', 'res', '**', 'README.md'), recursive=True))


def main():
    global here
    argv = sys.argv[1:]
    repo_mode = False
    if argv[:1] in (['-h'], ['--help']):
        sys.exit(__doc__)
    if argv[:1] == ['--case']:
        if len(argv) < 2:
            sys.exit(__doc__)
        here, argv = os.path.abspath(argv[1]), argv[2:]
    elif argv[:1] == ['--repo']:
        repo_mode, here, argv = True, REPO, argv[1:]
    no_refdocs = '--no-refdocs' in argv
    argv = [a for a in argv if a != '--no-refdocs']
    files = [os.path.abspath(f) for f in argv] or default_files(repo_mode)
    bad = 0
    linked = set()
    blocks = []
    with tempfile.TemporaryDirectory() as tmp:
        for path in files:
            text = open(path, encoding='utf-8').read()
            rel = os.path.relpath(path, here)
            bad += check_entities(text, rel)
            blocks += [(rel, n, block) for n, block in enumerate(mermaid_blocks(text))]
            bad += check_links(path, text, linked, rel, no_refdocs)
            for n in code_addresses.bare_dollars(text):
                bad += 1
                print(f'{rel}:{n}: $ in prose renders as math on GitHub (code_addresses.py)')
        bad += check_mermaid(blocks, tmp)
        if not repo_mode:
            bad += check_commands(files)
        if not argv and not repo_mode:
            for path in res_readmes():
                bad += check_links(path, open(path, encoding='utf-8').read(), linked, os.path.relpath(path, here),
                                   no_refdocs)
    if not argv and not repo_mode:
        img = os.path.join(here, 'docs', 'img')
        for figure in sorted(glob.glob(os.path.join(img, '**', '*.*'), recursive=True)):
            if os.path.relpath(figure, img).split(os.sep)[0] == 'res':
                continue
            if figure.endswith(('.png', '.gif', '.svg', '.jpg')) and os.path.normpath(figure) not in linked:
                bad += 1
                print(f'{os.path.relpath(figure, here)}: no document links this figure')
    skipped = f' ({len(SKIPPED)} link{"s" if len(SKIPPED) != 1 else ""} to docs 11/12 skipped: not generated yet)' \
        if SKIPPED else ''
    print(('docs: ok' if not bad else f'docs: {bad} problem(s)') + skipped)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
