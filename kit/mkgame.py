#!/usr/bin/env python3
"""Write the first cut of a case's game source (src/game) from the pristine image and the recordings.

    python3 kit/mkgame.py --case CASE --venv VENV [--sjasmplus BIN] [--out CASE/work/mkgame] [--install]

CASE/case.json says what the image is (kit/case-template/case.json):

    {"image": "work/image.bin",          the 64 K image as the loader leaves it (or "image_cmd": a command
                                         run in CASE that prints nothing and writes it)
     "lo": "5FB4", "hi": "10000",        the bytes of it that are the game
     "device": "ZXSPECTRUM48",           sjasmplus DEVICE
     "bases": {"5": "4000", "2": "8000", "0": "C000"},   L1 pages -> Z80 base of the image's banks
     "read_builds": ["game", "p2"],      the work/<build>/l1.json whose data reads count (not the loader's)
     "header": ["; Game, Publisher 19xx: ...", "..."]}  the first comment lines of game.asm

The code is what the recordings
ran (work/*/l1.json: every instruction start whose bytes are the image's), widened by a static walk over the branches
the recordings did not take. Everything else is data. Entries, names, comments and descriptions come from
src/game/game.ann (the format is in the Annotations class, docs 4-12). The result goes through SkoolKit (sna2skool.py
with a control file, skool2asm.py) and sjasmplus; the assembled bytes must be the image's. The entries game.ann marks
as resources (@res) are written as files under res/ (src/res with --install) and assembled with INCBIN; src/res/README.md
lists them. --install writes src/game/*.asm and the resources only when the bytes are the image's. When the case
has tools/res_formats.py with install(files), the resources go through it (graphics as PNG, a tune as text);
else they are installed as the bytes.
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = None  # the case, set by main()
LO, HI = 0x0000, 0x10000
BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000}
# The builds whose data reads count: the ones that start after the loader (a depacker reads its packed input where
# the game's code later lies)
READ_BUILDS = ()

# Z80 instruction lengths (the unprefixed table; CB 2; ED 2 or 4; DD / FD add one and a displacement)
LEN2 = {0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E, 0xC6, 0xCE, 0xD6, 0xDE, 0xE6, 0xEE, 0xF6, 0xFE, 0xD3, 0xDB,
        0x10, 0x18, 0x20, 0x28, 0x30, 0x38}
LEN3 = {0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC2, 0xC3, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
        0xC4, 0xCC, 0xCD, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC}
DISP = {0x34, 0x35, 0x36, 0x46, 0x4E, 0x56, 0x5E, 0x66, 0x6E, 0x7E, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x77,
        0x86, 0x8E, 0x96, 0x9E, 0xA6, 0xAE, 0xB6, 0xBE}
ED4 = {0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B}
JP_COND = {0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
CALLS = {0xCD, 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC}
JR = {0x10, 0x18, 0x20, 0x28, 0x30, 0x38}


def decode(mem, a):
    """(length, targets, falls through, is a call) of the instruction at a"""
    op = mem[a]
    if op in (0xDD, 0xFD):
        nxt = mem[(a + 1) & 0xFFFF]
        if nxt == 0xCB:
            return 4, [], True, False
        if nxt in (0xDD, 0xFD, 0xED):
            return 1, [], True, False
        if nxt == 0xE9:
            return 2, [], False, False
        n = 1 + (3 if nxt in LEN3 else 2 if nxt in LEN2 else 1) + (1 if nxt in DISP else 0)
        return n, [], True, False
    if op == 0xCB:
        return 2, [], True, False
    if op == 0xED:
        nxt = mem[(a + 1) & 0xFFFF]
        return (4 if nxt in ED4 else 2), [], nxt not in (0x45, 0x4D), False
    word = mem[(a + 1) & 0xFFFF] | mem[(a + 2) & 0xFFFF] << 8
    if op == 0xC3:
        return 3, [word], False, False
    if op in JP_COND:
        return 3, [word], True, False
    if op in CALLS:
        return 3, [word], True, True
    if op in JR:
        target = (a + 2 + (mem[(a + 1) & 0xFFFF] ^ 0x80) - 0x80) & 0xFFFF
        return 2, [target], op != 0x18, False
    if op & 0xC7 == 0xC7:
        return 1, [op & 0x38], True, True
    if op in (0xC9, 0xE9):
        return 1, [], False, False
    return (3 if op in LEN3 else 2 if op in LEN2 else 1), [], True, False


def load_l1(paths, mem):
    """Instruction starts the recordings ran with the image's bytes, routine entries, data reads"""
    starts, entries, reads = set(), set(), [0] * 0x10000
    bases = BASES
    for path in paths:
        doc = json.load(open(path))
        for z80, page, code, *_ in doc['instructions']:
            a = int(z80[1:], 16)
            raw = bytes.fromhex(code)
            if a < LO or page not in bases or a + len(raw) > HI:
                continue
            # The opcode as the image holds it (an operand may be self-modified)
            if decode(mem, a)[0] == len(raw) and mem[a] == raw[0]:
                starts.add(a)
        for r in doc['routines']:
            a = int(r['entry'][1:], 16)
            if a >= LO and r['page'] in bases:
                entries.add(a)
        # In the builds over the tape load the depacker reads its packed input where the game's code later lies: their reads say nothing
        if os.path.basename(os.path.dirname(path)) not in READ_BUILDS:
            continue
        for page in doc.get('byte_counts', []):
            base = bases.get(page['page'])
            if base is not None:
                for i, n in enumerate(page['reads']):
                    reads[base + i] += n
    return starts, entries, reads


def walk(mem, starts, reads, seeds=()):
    """Code: the ran instructions and what their untaken branches reach, stopping at bytes read as data; seeds are
    entries the reverse knows as code that no recording ran (handlers reached through a table)"""
    code, targets, calls = {}, set(), set()
    # The ran instructions own their bytes first: a walked one never cuts into them
    owner = {b: a for a in starts for b in range(a, a + decode(mem, a)[0])}
    todo = sorted(starts) + sorted(seeds, reverse=True)
    seen = set()
    while todo:
        a = todo.pop()
        while LO <= a < HI and a not in seen:
            n, tg, falls, call = decode(mem, a)
            span = range(a, a + n)
            ran = a in starts
            if a + n > HI or any(owner.get(b, a) != a for b in span):
                break
            if not ran and any(reads[b] and b not in owner for b in span):
                break
            seen.add(a)
            code[a] = n
            for b in span:
                owner[b] = a
            for t in tg:
                if LO <= t < HI:
                    targets.add(t)
                    (calls if call else set()).add(t)
                    todo.append(t)
            if not falls:
                break
            a += n
    return code, targets, calls


ANNOTATION = re.compile(r'\$([0-9A-Fa-f]{4})(?:\s+([cbwts])\b)?(?:\s+([A-Za-z_]\w*))?(?:\s+(\d+))?\s*(?:;\s*(.*))?$')


class Annotations:
    """src/game/game.ann: what the reverse knows, one line an address

        @module NAME              the entries from the next address on go to NAME.asm
        $ADDR c|b|w|t|s NAME [N]  an entry: code, bytes (N a line), words (N a line), text, space; ; its title
        > text                    the entry's description, one paragraph a line
        @res FILE                 the entry's bytes are a resource: src/res/FILE, assembled with INCBIN (entries
                                  naming one file share it: it holds the bytes from the first to the end of the last)
        $ADDR [NAME] ; comment    an instruction inside an entry: its label, its comment
        @isub $ADDR INSTRUCTION   the instruction at ADDR written so (a constant the image's bytes cannot tell from an
                                  address: LD HL,-6, not a label + offset)
        @equ $ADDR NAME [N] ; c   a variable outside the image (the work space the game keeps past its loaded bytes):
                                  NAME EQU $ADDR in game.asm, and every instruction operand $ADDR..$ADDR+N-1 written
                                  as NAME / NAME+k (N defaults to 1)
    """

    def __init__(self, path):
        self.entries, self.inline, self.modules, self.descriptions = {}, {}, [], {}
        self.resources = {}  # entry address: the resource file under src/res
        self.isub = {}  # instruction address: the instruction as the source writes it
        self.equ = {}  # address outside the image: (name, size, comment)
        last = None
        if not os.path.exists(path):
            return
        for number, line in enumerate(open(path), 1):
            line = line.rstrip('\n')
            text = line.strip()
            if not text or text.startswith('#'):
                continue
            if text.startswith('@module'):
                name = text.split()[1]
                if name == 'game':
                    # game.asm is the top file that includes the modules: a module of that name would include itself
                    raise SystemExit("game.ann: '@module game' is taken by game.asm, the file that includes the modules")
                self.modules.append([None, name])
                continue
            if text.startswith('@equ'):
                body, _, comment = text.partition(';')
                parts = body.split()
                address = int(parts[1].lstrip('$'), 16)
                if LO <= address < HI:
                    raise SystemExit(f'game.ann:{number}: @equ ${address:04X} is inside the image: name it as a label')
                self.equ[address] = (parts[2], int(parts[3]) if len(parts) > 3 else 1, comment.strip())
                continue
            if text.startswith('@isub'):
                parts = text.split(None, 2)
                if len(parts) != 3 or not re.match(r'^\$[0-9A-Fa-f]{4}$', parts[1]):
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.isub[int(parts[1][1:], 16)] = parts[2]
                continue
            if text.startswith('@res'):
                if last is None or self.entries[last][0] == 'c':
                    sys.exit(f'{path}:{number}: @res after no data entry')
                self.resources[last] = text.split(None, 1)[1].strip()
                continue
            if text.startswith('>'):
                if last is None:
                    sys.exit(f'{path}:{number}: a description before any entry')
                self.descriptions.setdefault(last, []).append(text[1:].strip())
                continue
            m = ANNOTATION.match(text)
            if not m:
                sys.exit(f'{path}:{number}: cannot read: {line}')
            a = int(m.group(1), 16)
            kind, name, width, comment = m.group(2), m.group(3), m.group(4), m.group(5)
            if kind:
                if a in self.entries:
                    sys.exit(f'{path}:{number}: ${a:04X} twice')
                self.entries[a] = (kind, name, int(width) if width else None, comment)
                last = a
                if self.modules and self.modules[-1][0] is None:
                    self.modules[-1][0] = a
            else:
                # Two lines for one address (a name on one, a comment on the other) are merged, not the last kept
                was_name, was_comment = self.inline.get(a, (None, None))
                if name and was_name and name != was_name:
                    sys.exit(f'{path}:{number}: ${a:04X} named twice: {was_name}, {name}')
                self.inline[a] = (name or was_name, comment or was_comment)
        for start, name in self.modules:
            if start is None:
                sys.exit(f'{path}: module {name} holds no entry')

    def name(self, a):
        if a in self.entries and self.entries[a][1]:
            return self.entries[a][1]
        if a in self.inline and self.inline[a][0]:
            return self.inline[a][0]
        return None


DATA = {'b': 'B', 'w': 'W', 't': 'T', 's': 'S'}


def write_ctl(mem, code, targets, calls, entries, ann, path):
    lines = ['@ $%04X start' % LO, '@ $%04X org' % LO]
    extents = {}  # data entry address: its length
    starts_entry = set(entries) | set(calls)
    a = LO
    kind = None
    data_kind, data_width = 'b', None
    while a < HI:
        is_code = a in code
        known = ann.entries.get(a)
        if known and (known[0] == 'c') != is_code:
            sys.exit('game.ann: $%04X is %s, the recordings say %s' % (a, known[0], 'code' if is_code else 'data'))
        new_entry = (kind is None or is_code != (kind == 'c') or known is not None or
                     (is_code and a in starts_entry) or (not is_code and kind == 'c'))
        if new_entry:
            kind = 'c' if is_code else 'b'
            if known:
                data_kind, data_width = known[0], known[2]
            elif not is_code:
                data_kind, data_width = 'b', None
            label = ann.name(a) or (('sub_%04X' if a in calls else 'l_%04X') % a if is_code else 'data_%04X' % a)
            lines.append('@ $%04X label=%s' % (a, label))
            title = known[3] if known and known[3] else label
            lines.append('%s $%04X %s' % (kind, a, title))
            for paragraph in ann.descriptions.get(a, []):
                lines.append('D $%04X %s' % (a, paragraph))
            if not is_code:
                # The data sub-block runs to the next entry: found below, written when it ends
                data_at = a
                lines.append(None)
        elif is_code and (a in targets or ann.name(a)):
            lines.append('@ $%04X label=%s' % (a, ann.name(a) or 'l_%04X' % a))
        if is_code:
            if a in ann.inline and ann.inline[a][1] and not new_entry:
                lines.append('C $%04X,%d %s' % (a, code[a], ann.inline[a][1]))
            elif new_entry and a in ann.inline and ann.inline[a][1]:
                lines.append('C $%04X,%d %s' % (a, code[a], ann.inline[a][1]))
            a += code[a]
        else:
            a += 1
            ends = a >= HI or a in code or a in ann.entries
            if ends:
                length = a - data_at
                extents[data_at] = length
                spec = DATA[data_kind]
                if data_kind == 's':
                    item = '%s $%04X,%d' % (spec, data_at, length)
                elif data_width:
                    step = data_width * (2 if data_kind == 'w' else 1)
                    item = '%s $%04X,%d,%d' % (spec, data_at, length, step)
                else:
                    item = '%s $%04X,%d' % (spec, data_at, length)
                lines[lines.index(None)] = item
    lines.append('i $10000')
    open(path, 'w').write('\n'.join(lines) + '\n')
    return extents


DATA_LINE = re.compile(r'^  DEF[BWMS] ')
LABEL_LINE = re.compile(r'^([A-Za-z_]\w*):$')


def write_resources(text, mem, extents, ann, out):
    """The resource entries of game.ann as files under out/res and INCBIN lines in the listing: (text, {file: (lo,
    hi)}). An entry's data lines (and the labels inside it) become INCBIN slices of its file, its label and comments
    stay"""
    files = {}
    for a, name in ann.resources.items():
        if a not in extents:
            sys.exit('game.ann: @res %s on $%04X, which is no data entry' % (name, a))
        lo, hi = files.get(name, (a, a + extents[a]))
        files[name] = (min(lo, a), max(hi, a + extents[a]))
    for name, (lo, hi) in files.items():
        path = os.path.join(out, 'res', name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(mem[lo:hi])
    inner = {n: a for a, (n, _) in ann.inline.items() if n}
    lines = text.splitlines()
    for a, name in sorted(ann.resources.items()):
        label = ann.name(a)
        at = lines.index(label + ':')
        end = at + 1
        cuts = []  # (address, label) of the labels inside the entry
        while end < len(lines) and (DATA_LINE.match(lines[end]) or LABEL_LINE.match(lines[end])):
            m = LABEL_LINE.match(lines[end])
            if m:
                if m.group(1) not in inner or not a < inner[m.group(1)] < a + extents[a]:
                    sys.exit('game.ann: %s inside the resource %s has no address in it' % (m.group(1), name))
                cuts.append((inner[m.group(1)], m.group(1)))
            end += 1
        body, start = [], a
        for cut, cut_label in cuts + [(a + extents[a], None)]:
            if cut > start:
                body.append('  INCBIN "res/%s",$%04X,%d' % (name, start - files[name][0], cut - start))
            if cut_label:
                body.append(cut_label + ':')
            start = cut
        lines[at + 1:end] = body
    return '\n'.join(lines) + '\n', files


def split_modules(text, ann):
    """The listing cut into the modules of game.ann: ([(name, text)], the head before the first)"""
    if not ann.modules:
        return [('code', text)], ''
    out_lines = text.splitlines()
    cuts = []
    for start, name in sorted(ann.modules):
        label = ann.name(start)
        if not label:
            sys.exit('game.ann: module %s starts at $%04X, an entry with no name' % (name, start))
        at = next(i for i, l in enumerate(out_lines) if l == label + ':')
        while at > 0 and out_lines[at - 1].startswith(';'):
            at -= 1
        cuts.append((at, name))
    parts = []
    head = out_lines[:cuts[0][0]] if cuts else out_lines
    for k, (at, name) in enumerate(cuts):
        end = cuts[k + 1][0] if k + 1 < len(cuts) else len(out_lines)
        parts.append((name, '\n'.join(out_lines[at:end]).rstrip() + '\n'))
    return parts, '\n'.join(head).rstrip() + '\n'


ADDRESS_OPERAND = re.compile(r'^(LD (?:\((?=\$)|(?:HL|DE|IX|IY|SP),\(?))\$([0-9A-F]{4})(\)?.*)$')


def label_inner_addresses(skool, written=None):
    """An address operand inside an entry (a field of a record, a byte of a table) as Label+offset: @isub lines for
    skool2asm, which only replaces the addresses that have a label of their own"""
    lines = skool.splitlines()
    labels, entry_of, entry = {}, {}, None
    pending = None
    for line in lines:
        if line.startswith('@label='):
            pending = line[7:]
            continue
        m = re.match(r'^([bcstuwi *])\$([0-9A-F]{4}) ', line)
        if m:
            a = int(m.group(2), 16)
            if m.group(1) not in ' *':
                entry = a
            entry_of[a] = entry
            if pending:
                labels[a] = pending
                pending = None
    starts = sorted(entry_of)
    import bisect

    def resolve(target):
        i = bisect.bisect_right(starts, target) - 1
        if i < 0 or target in labels:
            return None
        entry = entry_of[starts[i]]
        best = max((a for a in labels if entry_of.get(a) == entry and a <= target), default=None)
        if best is None:
            return None
        return '%s+%d' % (labels[best], target - best)

    out, count = [], 0
    for line in lines:
        m = re.match(r'^([ c*])\$([0-9A-F]{4}) (\S.*?)(\s*;.*)?$', line)
        if m and written and int(m.group(2), 16) in written:
            out.append('@isub=' + written.pop(int(m.group(2), 16)))
        elif m:
            op = ADDRESS_OPERAND.match(m.group(3))
            if op:
                target = int(op.group(2), 16)
                name = resolve(target) if LO <= target < HI else None
                if name:
                    out.append('@isub=%s%s%s' % (op.group(1), name, op.group(3)))
                    count += 1
        out.append(line)
    return '\n'.join(out) + '\n', count


def original_image(config):
    """The image as the original's loader leaves it (64K), from case.json"""
    if config.get('image_cmd'):
        run(config['image_cmd'], cwd=ROOT)
    path = os.path.join(ROOT, config['image'])
    mem = open(path, 'rb').read()
    if len(mem) != 0x10000:
        sys.exit(f'{path}: {len(mem)} bytes, not a 64 K image')
    return mem


def load_case(case):
    global ROOT, LO, HI, BASES, READ_BUILDS
    ROOT = os.path.abspath(case)
    config = json.load(open(os.path.join(ROOT, 'case.json')))
    LO, HI = int(config['lo'], 16), int(config.get('hi', '10000'), 16)
    BASES = {int(k): int(v, 16) for k, v in config.get('bases', {'5': '4000', '2': '8000', '0': 'C000'}).items()}
    READ_BUILDS = tuple(config.get('read_builds', ()))
    return config


def install_resources(files):
    """The case's res_formats.install when it has one, else the bytes into src/res"""
    tools = os.path.join(ROOT, 'tools')
    if os.path.isfile(os.path.join(tools, 'res_formats.py')):
        sys.path.insert(0, tools)
        import res_formats  # noqa: E402
        res_formats.install(files)
        return
    for name, data in files.items():
        path = os.path.join(ROOT, 'src', 'res', name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(data)


def run(cmd, **kw):
    p = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if p.returncode:
        sys.exit(f'{cmd[0]}: {p.stderr.strip() or p.stdout.strip()}')
    return p


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--case', required=True, help='the case folder (holds case.json)')
    p.add_argument('--venv', required=True, help='a virtualenv with SkoolKit')
    p.add_argument('--sjasmplus', default='sjasmplus')
    p.add_argument('--out')
    p.add_argument('--ann')
    p.add_argument('--install', action='store_true', help='write src/game/*.asm when the bytes are the image\'s')
    args = p.parse_args()
    config = load_case(args.case)
    args.out = args.out or os.path.join(ROOT, 'work', 'mkgame')
    args.ann = args.ann or os.path.join(ROOT, 'src', 'game', 'game.ann')
    os.makedirs(args.out, exist_ok=True)
    mem = original_image(config)
    starts, entries, reads = load_l1(sorted(glob.glob(os.path.join(ROOT, 'work', '*', 'l1.json'))), mem)
    ann = Annotations(args.ann)
    code, targets, calls = walk(mem, starts, reads, [a for a, e in ann.entries.items() if e[0] == 'c'])
    os.makedirs(args.out, exist_ok=True)
    ctl = os.path.join(args.out, 'game.ctl')
    extents = write_ctl(mem, code, targets, calls, entries, ann, ctl)
    image = os.path.join(args.out, 'image.bin')
    open(image, 'wb').write(mem[LO:])
    py = os.path.join(args.venv, 'bin', 'python')
    skool = os.path.join(args.out, 'game.skool')
    out = run([py, os.path.join(args.venv, 'bin', 'sna2skool.py'), '-H', '-c', ctl, '-o', str(LO), image]).stdout
    written = dict(ann.isub)
    out, inner = label_inner_addresses(out, written)
    if written:
        sys.exit('game.ann: @isub on no instruction: ' + ', '.join('$%04X' % a for a in sorted(written)))
    open(skool, 'w').write(out)
    asm = run([py, os.path.join(args.venv, 'bin', 'skool2asm.py'), '-H', skool])
    text = asm.stdout
    for half in ('IXl', 'IXh', 'IYl', 'IYh'):
        text = text.replace(half, half.upper())
    text = name_variables(text, ann.equ)
    text, resources = write_resources(text, mem, extents, ann, args.out)
    modules, head = split_modules(text, ann)
    for name, body in modules:
        open(os.path.join(args.out, name + '.asm'), 'w').write(body)
    main_asm = header(config) + equates(ann.equ) + head + ''.join('  INCLUDE "%s.asm"\n' % name for name, _ in modules) + \
        '\n  SAVEBIN "game.bin",$%04X,$%04X\n' % (LO, HI - LO)
    open(os.path.join(args.out, 'game.asm'), 'w').write(main_asm)
    run([args.sjasmplus, '--nologo', '--msg=war', 'game.asm'], cwd=args.out)
    built = open(os.path.join(args.out, 'game.bin'), 'rb').read()
    diff = next((LO + i for i in range(HI - LO) if built[i] != mem[LO + i]), None)
    print(f'resources {len(resources)} files, {sum(hi - lo for lo, hi in resources.values())} bytes')
    print(f'code bytes {sum(code.values())} ({len(code)} instructions, {len(starts)} ran), '
          f'entries {sum(1 for l in open(ctl) if l[:2] in ("c ", "b "))}, modules {len(modules)}, '
          f'addresses inside entries as Label+offset {inner}')
    print('assembled: identical to the original image' if diff is None else
          'assembled: first difference at $%04X: %02X, image %02X' % (diff, built[diff - LO], mem[diff]))
    if diff is None and args.install:
        dest = os.path.join(ROOT, 'src', 'game')
        for old in glob.glob(os.path.join(dest, '*.asm')):
            os.remove(old)
        for name in [n for n, _ in modules] + ['game']:
            open(os.path.join(dest, name + '.asm'), 'w').write(open(os.path.join(args.out, name + '.asm')).read())
        # the graphics and the tune go in as their editable sources (PNG, text), the rest as bytes
        install_resources({name: open(os.path.join(args.out, 'res', name), 'rb').read() for name in resources})
        print(f'installed {len(modules) + 1} files in src/game, {len(resources)} resources in src/res')
    return 0 if diff is None else 1


def name_variables(text, equ):
    """Every instruction operand that is a variable's address (@equ), written as the variable's name"""
    if not equ:
        return text
    names = {}
    for address, (name, size, _) in equ.items():
        for k in range(size):
            names[address + k] = name if k == 0 else '%s+%d' % (name, k)

    def operand(m):
        return names.get(int(m.group(1), 16), m.group(0))

    out = []
    for line in text.splitlines(True):
        code, semi, comment = line.partition(';')
        if re.match(r'^  [A-Z]', code) and not re.match(r'^  DEF[BWMS]', code):
            code = re.sub(r'\$([0-9A-F]{4})\b', operand, code)
        out.append(code + semi + comment)
    return ''.join(out)


def equates(equ):
    """The variables outside the image (game.ann @equ), as EQU lines"""
    if not equ:
        return ''
    lines = ['', '; The variables past the loaded image (game.ann @equ)']
    for address, (name, size, comment) in sorted(equ.items()):
        lines.append('%-14s EQU $%04X%s' % (name, address, ('  ; ' + comment) if comment else ''))
    return '\n'.join(lines) + '\n'


def header(config):
    lines = config.get('header') or ['; The game image $%04X-$%04X.' % (LO, HI - 1)]
    return '\n'.join(lines) + """
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE %s
""" % config.get('device', 'ZXSPECTRUM48')


if __name__ == '__main__':
    sys.exit(main())
