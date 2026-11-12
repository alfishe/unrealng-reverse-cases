#!/usr/bin/env python3
"""Check the documentation: every mermaid diagram renders (mmdc, all of them in one run), every relative link and image exists, every
#anchor names a heading of its file, and no $ is left in prose (GitHub reads a pair of them as LaTeX math;
code_addresses.py fixes addresses).

    python3 kit/check_docs.py [--case CASE] [FILE.md ...]   # default: CASE's WALKTHROUGH.md, README.md, docs/**/*.md
    python3 kit/check_docs.py --repo [FILE.md ...]          # the repository's own: README, GUIDE, recipes, docs, kit
                                                            # (not the template's docs: their 11 and 12 come later)

A case: every figure under docs/img (any subfolder but docs/img/res, the resource previews src/res/README.md links)
must be linked by a document (GUIDE.md 4.2); the documents in docs/ subfolders (docs/texts, docs/audio) are checked
too. The resource READMEs (src/res/README.md, src/res/**/README.md) are read for their links: a figure they link
counts as linked, and a link of theirs to a file or heading that does not exist is a problem (their mermaid and
prose are not checked). Anchors follow GitHub's slugs: the heading's text with the Markdown marks dropped, lower case, every character
but letters, digits, '-', '_' and spaces removed, spaces as '-', a repeated slug numbered -1, -2. An explicit
<a name="..."> or id="..." counts as well. Links inside code (fenced blocks, `spans`) are not links.
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


def check_links(path, text, linked, rel):
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
                    bad += 1
                    print(f'{rel}:{number}: missing {target}')
                    continue
            if anchor and dest.endswith('.md') and os.path.isfile(dest) and anchor not in anchors(dest):
                bad += 1
                where = os.path.relpath(dest, base) if file_part else 'this file'
                print(f'{rel}:{number}: no heading #{anchor} in {where}')
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
            bad += check_links(path, text, linked, rel)
            for n in code_addresses.bare_dollars(text):
                bad += 1
                print(f'{rel}:{n}: $ in prose renders as math on GitHub (code_addresses.py)')
        bad += check_mermaid(blocks, tmp)
        if not argv and not repo_mode:
            for path in res_readmes():
                bad += check_links(path, open(path, encoding='utf-8').read(), linked, os.path.relpath(path, here))
    if not argv and not repo_mode:
        img = os.path.join(here, 'docs', 'img')
        for figure in sorted(glob.glob(os.path.join(img, '**', '*.*'), recursive=True)):
            if os.path.relpath(figure, img).split(os.sep)[0] == 'res':
                continue
            if figure.endswith(('.png', '.gif', '.svg', '.jpg')) and os.path.normpath(figure) not in linked:
                bad += 1
                print(f'{os.path.relpath(figure, here)}: no document links this figure')
    print('docs: ok' if not bad else f'docs: {bad} problem(s)')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
