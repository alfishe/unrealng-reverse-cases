#!/usr/bin/env python3
"""The front99 part's sources (the '99 intro stage 2 at $61A8, the pictures block at $7D87, the Sound Tracker block
at $C000) from their annotations and the recordings: a copy of R/games/advanced-nether-earth/tools/disk_mkgame.py
(itself kit/mkgame.py widened to an image of several segments, each with its own run address and banks; the brief:
shared tools are copied, never edited) with this part's paths.

    python3 tools/front99_mkgame.py --part src/stage2/stage2.json [--venv VENV] [--sjasmplus BIN] [--install]

The part file (JSON): {"name", "image", "at", "out", "dest", "header", "l1", "segments": [{"ann", "lo", "hi", "run",
"bases", "read_builds", "title", "same_bytes", "data_entries"}]}. "image" is the block as the media hold it
(work/media/99, tools/zs_media.py), never a recording. "l1" lists this part's own L1 windows of work/stage1/r99
(work/stage2/front99/<window>/l1.json), never every work/*/l1.json. "same_bytes": true counts a recorded instruction
only when all its bytes are the image's (stage 3 is unpacked over stage 2 at the window's end); "data_entries": true
makes each annotated data entry, up to the next entry, data the walk never enters.
The work goes to work/stage2/front99/mk-<name>; --install writes <dest>/<name>.asm and its modules in
<dest>/<name>/ only when sjasmplus gives the original bytes; the raw resources stay in the work folder (their
editable sources in src/res/<part>/ are written by tools/front99_res.py). The modules INCBIN "res/...":
tools/build_front99.sh assembles in build/front99, where the resources are built from their editable sources.
"""
import argparse
import glob
import json
import os
import re
import shutil
import textwrap
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = None  # the case, set by main()
LO, HI = 0x0000, 0x10000
BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000}
# The builds whose data reads count: the ones that start after the loader (a depacker reads its packed input where
# the game's code later lies)
READ_BUILDS = ()
SAME_BYTES = False  # a segment's "same_bytes": only instructions whose bytes are all the image's

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
            if decode(mem, a)[0] == len(raw) and mem[a] == raw[0] and \
                    (not SAME_BYTES or mem[a:a + len(raw)] == raw):
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
    if SAME_BYTES:  # a routine whose bytes another program later put there is not one of this image's
        entries &= starts
    return starts, entries, reads


def walk(mem, starts, reads, seeds=(), inline=()):
    """Code: the ran instructions and what their untaken branches reach, stopping at bytes read as data; seeds are
    entries the reverse knows as code that no recording ran (handlers reached through a table); a call to a routine in
    inline reads its data after the CALL: the walk does not go on past it (where the code resumes, a recording says)"""
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
            if not falls or (call and any(t in inline for t in tg)):
                break
            a += n
    return code, targets, calls


ANNOTATION = re.compile(r'\$([0-9A-Fa-f]{4})(?:\s+([cbwts])\b)?(?:\s+([A-Za-z_]\w*))?(?:\s+(\d+))?\s*(?:;\s*(.*))?$')


class Annotations:
    """An annotation file (src/disk/*.ann): what the reverse knows, one line an address

        @module NAME [; title]    the entries from the next address on go to NAME.asm; the title heads the file
        @about text               a paragraph of the current module's header (what it holds, how its parts work)
        $ADDR c|b|w|t|s NAME [N]  an entry: code, bytes (N a line), words (N a line), text, space; ; its title
        > text                    the entry's description, one paragraph a line
        @res FILE                 the entry's bytes are a resource: src/res/FILE, assembled with INCBIN (entries
                                  naming one file share it: it holds the bytes from the first to the end of the last)
        $ADDR [NAME] ; comment    an instruction inside an entry: its label, its comment; inside a data entry the
                                  data line that starts at ADDR (the entry's rows are cut there)
        @isub $ADDR INSTRUCTION   the instruction at ADDR written so (a constant the image's bytes cannot tell from an
                                  address: LD HL,-6, not a label + offset)
        @inline $ADDR             a routine that reads data placed after its CALL (a print routine with the string
                                  inline): no walk goes past a call to it, the bytes after it are data unless a
                                  recording ran them
        @equ $ADDR NAME [N] ; c   a variable outside the image (the work space the game keeps past its loaded bytes):
                                  NAME EQU $ADDR in game.asm, and every instruction operand $ADDR..$ADDR+N-1 written
                                  as NAME / NAME+k (N defaults to 1)
    """

    def __init__(self, path):
        self.entries, self.inline, self.modules, self.descriptions = {}, {}, [], {}
        self.module_info = {}  # module name: [title, [paragraphs]]
        self.resources = {}  # entry address: the resource file under src/res
        self.isub = {}  # instruction address: the instruction as the source writes it
        self.equ = {}  # address outside the image: (name, size, comment)
        self.inline_data = set()  # routines whose callers place data after the CALL
        last = None
        if not os.path.exists(path):
            return
        for number, line in enumerate(open(path), 1):
            line = line.rstrip('\n')
            text = line.strip()
            if not text or text.startswith('#'):
                continue
            if text.startswith('@about'):
                if not self.modules:
                    sys.exit(f'{path}:{number}: @about before any @module')
                self.module_info[self.modules[-1][1]][1].append(text[len('@about'):].strip())
                continue
            if text.startswith('@module'):
                body, _, title = text.partition(';')
                name = body.split()[1]
                self.module_info[name] = [title.strip(), []]
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
            if text.startswith('@inline'):
                parts = text.split(';')[0].split()
                if len(parts) != 2 or not re.match(r'^\$[0-9A-Fa-f]{4}$', parts[1]):
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.inline_data.add(int(parts[1][1:], 16))
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
            sys.exit('annotation: $%04X is %s, the recordings say %s' % (a, known[0], 'code' if is_code else 'data'))
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
                lines[lines.index(None)] = '\n'.join(data_blocks(data_at, a, data_kind, data_width, ann))
    lines.append('i $%04X' % HI if HI < 0x10000 else 'i $10000')  # the bytes past the image are no entry's
    open(path, 'w').write('\n'.join(lines) + '\n')
    return extents


def data_blocks(lo, hi, kind, width, ann):
    """The ctl sub-blocks of the data entry lo..hi-1: cut where game.ann has a line inside it ($ADDR [Name] ; comment),
    so that line's comment goes on the data line it names and its name becomes a label there"""
    spec = DATA[kind]
    cuts = sorted({lo} | {c for c in ann.inline if lo < c < hi})
    out = []
    for k, start in enumerate(cuts):
        end = cuts[k + 1] if k + 1 < len(cuts) else hi
        name, comment = ann.inline.get(start, (None, None))
        if name and start != lo:
            out.append('@ $%04X label=%s' % (start, name))
        length = end - start
        if kind == 's' or not width:
            item = '%s $%04X,%d' % (spec, start, length)
        else:
            item = '%s $%04X,%d,%d' % (spec, start, length, width * (2 if kind == 'w' else 1))
        out.append(item + (' ' + comment if comment else ''))
    return out


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


def module_header(name, ann):
    """The comment block that opens a module's file: its title and @about paragraphs"""
    title, paragraphs = ann.module_info.get(name, ['', []])
    if not title and not paragraphs:
        return ''
    out = ['; ' + name + '.asm' + (': ' + title if title else ''), ';']
    for k, para in enumerate(paragraphs):
        out += ['; ' + line for line in textwrap.wrap(para, 116)]
        out.append(';')
    rule = '; ' + '-' * 116
    return rule + '\n' + '\n'.join(out[:-1] if out[-1] == ';' else out) + '\n' + rule + '\n\n'


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
        parts.append((name, module_header(name, ann) + '\n'.join(out_lines[at:end]).rstrip() + '\n'))
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
    lines = ['', '; Addresses outside this image (the annotations @equ lines): the ROMs, the system variables, the game']
    for address, (name, size, comment) in sorted(equ.items()):
        lines.append('%-14s EQU $%04X%s' % (name, address, ('  ; ' + comment) if comment else ''))
    return '\n'.join(lines) + '\n'




def run(cmd, **kw):
    p = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if p.returncode:
        sys.exit(f'{cmd[0]}: {p.stderr.strip() or p.stdout.strip()}')
    return p


def set_segment(seg):
    global LO, HI, BASES, READ_BUILDS, SAME_BYTES
    SAME_BYTES = bool(seg.get('same_bytes'))
    LO, HI = int(seg['run'], 16), int(seg['run'], 16) + int(seg['hi'], 16) - int(seg['lo'], 16)
    BASES = {int(k): int(v, 16) for k, v in seg['bases'].items()}
    READ_BUILDS = tuple(seg.get('read_builds', ()))


def generate(seg, original, at, l1, args, out):
    """One segment through mkgame's steps: (modules [(name, text)], head, resources {file: bytes}, equ, labels)"""
    set_segment(seg)
    lo = int(seg['lo'], 16)
    mem = bytearray(0x10000)
    mem[LO:HI] = original[lo - at:lo - at + HI - LO]
    mem = bytes(mem)
    starts, entries, reads = load_l1(l1, mem)
    ann = Annotations(os.path.join(ROOT, seg['ann']))
    # With "data_entries", an annotated data entry (to the next entry) is data: a ran instruction there is another
    # program's whose bytes happen to match (the game's code over the starter's picture); the walk does not enter it
    marks = sorted(ann.entries) + [HI]
    for a, b in zip(marks, marks[1:]):
        if seg.get('data_entries') and ann.entries[a][0] != 'c':
            starts -= set(range(a, b))
            for i in range(a, b):
                reads[i] = reads[i] or 1
    code, targets, calls = walk(mem, starts, reads, [a for a, e in ann.entries.items() if e[0] == 'c'],
                                ann.inline_data)
    tag = os.path.splitext(os.path.basename(seg['ann']))[0]
    ctl = os.path.join(out, tag + '.ctl')
    extents = write_ctl(mem, code, targets, calls, entries, ann, ctl)
    image = os.path.join(out, tag + '.bin')
    open(image, 'wb').write(mem[LO:])
    py = os.path.join(args.venv, 'bin', 'python')
    text = run([py, os.path.join(args.venv, 'bin', 'sna2skool.py'), '-H', '-c', ctl, '-o', str(LO), image]).stdout
    written = dict(ann.isub)
    text, inner = label_inner_addresses(text, written)
    if written:
        sys.exit(f'{seg["ann"]}: @isub on no instruction: ' + ', '.join('$%04X' % a for a in sorted(written)))
    skool = os.path.join(out, tag + '.skool')
    open(skool, 'w').write(text)
    text = run([py, os.path.join(args.venv, 'bin', 'skool2asm.py'), '-H', skool]).stdout
    for half in ('IXl', 'IXh', 'IYl', 'IYh'):
        text = text.replace(half, half.upper())
    text = name_variables(text, ann.equ)
    text = re.sub(r'^(  DEF[BWMS] .*?)\s+;$', r'\1', text, flags=re.M)
    text, files = write_resources(text, mem, extents, ann, out)
    modules, head = split_modules(text, ann)
    resources = {name: mem[a:b] for name, (a, b) in files.items()}
    labels = set(re.findall(r'^([A-Za-z_]\w*):$', text, flags=re.M))
    print(f'{seg["ann"]}: code bytes {sum(code.values())} ({len(code)} instructions, {len(starts)} ran), '
          f'resources {len(files)}, modules {len(modules)}, Label+offset {inner}')
    return modules, head, resources, ann, labels


def main():
    global ROOT
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--part', required=True)
    p.add_argument('--venv', default='/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
    p.add_argument('--sjasmplus', default='/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus')
    p.add_argument('--install', action='store_true')
    args = p.parse_args()
    ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    part = json.load(open(os.path.join(ROOT, args.part)))
    name = part['name']
    original = open(os.path.join(ROOT, part['image']), 'rb').read()
    at = int(part['at'], 16)
    out = os.path.join(ROOT, 'work', 'stage2', 'front99', 'mk-' + name)
    shutil.rmtree(out, ignore_errors=True)  # no module or resource of an earlier run left behind
    os.makedirs(os.path.join(out, name), exist_ok=True)
    l1 = [os.path.join(ROOT, p_) for p_ in part['l1']]
    results = [generate(seg, original, at, l1, args, out) for seg in part['segments']]
    every_label = set().union(*(r[4] for r in results))
    equ, seen = {}, set()
    for _, _, _, ann, _ in results:
        for address, (var, size, comment) in ann.equ.items():
            if var not in every_label and var not in seen:
                equ[address] = (var, size, comment)
                seen.add(var)
    names = [m for r in results for m, _ in r[0]]
    if len(set(names)) != len(names):
        sys.exit('module names repeat across segments: ' + ', '.join(sorted({n for n in names if names.count(n) > 1})))
    top = '\n'.join(part.get('header') or ['; ' + name]) + '\n'
    top += '; Written by tools/front99_mkgame.py from the annotations (%s) and the recordings; edit the annotations,\n' \
           '; not the .asm.\n\n  DEVICE ZXSPECTRUM48\n' % ', '.join(s['ann'] for s in part['segments'])
    top += equates(equ)
    for seg, (modules, head, _, ann, _) in zip(part['segments'], results):
        lo, run_at = int(seg['lo'], 16), int(seg['run'], 16)
        top += '\n; %s: $%04X-$%04X%s\n  ORG $%04X\n' % (
            seg.get('title', seg['ann']), lo, int(seg['hi'], 16) - 1,
            ', run at $%04X' % run_at if run_at != lo else '', lo)
        if run_at != lo:
            top += '  DISP $%04X\n' % run_at
        # sna2skool's own ORG repeats the one above (inside a DISP it would be a displaced ORG)
        head = '\n'.join(l for l in head.split('\n') if l.strip().upper() not in ('ORG $%04X' % lo, 'ORG $%04X' % run_at))
        if head.strip():
            top += head
        for module, _ in modules:
            title = ann.module_info.get(module, [''])[0]
            top += '  INCLUDE "%s/%s.asm"%s\n' % (name, module, ('  ; ' + title) if title else '')
        if run_at != lo:
            top += '  ENT\n'
    top += '\n  SAVEBIN "%s",$%04X,%d\n' % (os.path.basename(part['out']), at, len(original))
    for modules, _, resources, _, _ in results:
        for module, body in modules:
            open(os.path.join(out, name, module + '.asm'), 'w').write(body)
        for res, data in resources.items():
            path = os.path.join(out, 'res', res)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'wb').write(data)
    open(os.path.join(out, name + '.asm'), 'w').write(top)
    run([args.sjasmplus, '--nologo', '--msg=war', '--lst=' + name + '.lst', name + '.asm'], cwd=out)
    built = open(os.path.join(out, os.path.basename(part['out'])), 'rb').read()
    diff = next((i for i in range(len(original)) if built[i] != original[i]), None)
    print('assembled: identical to %s' % part['image'] if diff is None else
          'assembled: first difference at $%04X: %02X, original %02X' % (at + diff, built[diff], original[diff]))
    if diff is None and args.install:
        dest = os.path.join(ROOT, part['dest'])
        os.makedirs(os.path.join(dest, name), exist_ok=True)
        for old in glob.glob(os.path.join(dest, name, '*.asm')):
            os.remove(old)
        for module in names:
            open(os.path.join(dest, name, module + '.asm'), 'w').write(open(os.path.join(out, name, module + '.asm')).read())
        open(os.path.join(dest, name + '.asm'), 'w').write(top)
        print(f'installed {part["dest"]}/{name}.asm, {len(names)} modules, '
              f'{sum(len(r[2]) for r in results)} resources (raw in {os.path.relpath(out, ROOT)}/res)')
    return 0 if diff is None else 1


if __name__ == '__main__':
    sys.exit(main())
