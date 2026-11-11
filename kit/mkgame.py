#!/usr/bin/env python3
"""Write the source of a code image from its annotations (.ann) and the recordings, and check it assembles to the
image's bytes: a case's game, or any other part of the medium (a loader, a menu, a driver, a bank, several pieces).

    python3 kit/mkgame.py [--case CASE] [--config FILE] [--ann FILE] [--out DIR] [--install]      the case's game
    python3 kit/mkgame.py [--case CASE] --part FILE.json [--install]                               a part file
    python3 kit/mkgame.py [--case CASE] --image BIN --org ADDR --ann FILE --top NAME --dest DIR     one image
                          [--range LO-HI] [--res DIR] [--l1 L1.json ...] [--l1-reads L1.json ...] [--blocks]
                          [--page N ...] [--bank N] [--built NAME=PATH ...] [--save PATH] [--title TEXT] [--install]
    every form also takes --venv VENV --sjasmplus BIN (else $SKOOLKIT_VENV / $SJASMPLUS, kit/toolpaths.py) and
    --fix-witness (rewrite the stale "Witness: L1 N (builds)" lines of the .ann, which every run prints)

The game: CASE/case.json (or --config) names the 64 K image, the range that is the game, the banks, the recordings
(read_builds: work/<build>/l1.json whose instructions and data reads count; code_builds: whose instructions only)
and the header; the source goes to src/game, the resources through tools/res_formats.py (case.json res_install
names another). A part: a JSON part file (one image, or segments of one image each with its own .ann, run address
and banks), or the command line for one image at its ORG. The keys and the reasons are in docs/ann-format.md
section 5, the .ann format in sections 1-4; what each file of a case is in docs/case-files.md.

The pipeline is the same for every form: the code is what the recordings ran (instruction starts whose bytes are the
image's, or whole basic blocks with --blocks), widened by a static walk over the branches no recording took and
from the .ann's code entries; everything else is data. Entries, names, comments, data shapes and resources come
from the .ann. SkoolKit (sna2skool.py with a control file, skool2asm.py) writes the listing, the kit cuts it into
the .ann's modules and writes the top file, sjasmplus assembles it, and --install writes the sources only when the
bytes are the image's. Install never deletes a file it did not write: only the modules an earlier top file
INCLUDEd that are gone now, and a resource's NAME.bin an earlier install left where the case's hook now writes the
editable form.
"""
import argparse
import fnmatch
import glob
import importlib.util
import json
import os
import re
import textwrap
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import toolpaths  # noqa: E402
import resinc  # noqa: E402

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
    """Instruction starts the recordings ran with the image's bytes, routine entries, data reads (the case's game:
    every path's instructions count, the data reads only of READ_BUILDS)"""
    sources = [Source(p, reads=os.path.basename(os.path.dirname(p)) in READ_BUILDS) for p in paths]
    return read_sources(sources, mem, LO, HI, BASES)


class Source:
    """One recording a part's code comes from: an unreal-ng L1 build (l1.json) or a simulator trace

        path      the file (a glob: every match, sorted)
        reads     its data reads count (they stop the walk): not for a build over a depacker's input
        lo, hi    only this window of addresses counts (the bytes that held this part's code while it ran)
        roots     False: a routine that is only the window's root (where the build began, mid-routine) is no entry
        format    'l1' (re_session.py build) or 'trace' ({"starts": {ADDR: length}, "entries": [ADDR],
                  "reads": {ADDR: count}}, a case's simulator: tools/bootmenu_sim.py)
        optional  a missing file is skipped (a window not every checkout has), not an error
    """

    def __init__(self, path, reads=False, lo=None, hi=None, roots=True, fmt='l1', optional=False):
        self.path, self.reads, self.lo, self.hi, self.roots, self.format = path, reads, lo, hi, roots, fmt
        self.optional = optional

    @staticmethod
    def parse(spec, root, read_builds=()):
        """a source from a part file: "PATH" or {"path", "reads", "lo", "hi", "roots", "format", "optional"}"""
        if isinstance(spec, str):
            spec = {'path': spec}
        path = os.path.join(root, spec['path'])
        reads = spec.get('reads', os.path.basename(os.path.dirname(path)) in read_builds)
        return Source(path, reads, hexa(spec['lo']) if 'lo' in spec else None,
                      hexa(spec['hi']) if 'hi' in spec else None, spec.get('roots', True), spec.get('format', 'l1'),
                      spec.get('optional', False))


EXECS = {}  # l1.json path -> {address: the runs of the instruction there}, filled by read_sources


def read_sources(sources, mem, lo, hi, bases, mode='instructions', same_bytes=False):
    """(instruction starts, routine entries, data reads) of the image lo..hi-1 from its recordings.

    mode 'instructions': every recorded instruction whose opcode and length are the image's (an operand may be
    self-modified; same_bytes: all its bytes), and the routines' entries. mode 'blocks': only the recorded basic
    blocks whose every instruction has the image's bytes (another program that ran at these addresses later in the
    same recording cannot make a lone byte look like code), no entries. Only the pages in bases count."""
    starts, entries, reads = set(), set(), [0] * 0x10000
    for src in sources:
        paths = sorted(glob.glob(src.path)) if any(c in src.path for c in '*?[') else [src.path]
        for path in paths:
            if not os.path.exists(path):
                if src.optional:
                    continue
                sys.exit(f'no recording {path} (the WALKTHROUGH command that makes it)')
            doc = json.load(open(path))
            wlo = lo if src.lo is None else max(lo, src.lo)
            whi = hi if src.hi is None else min(hi, src.hi)
            if src.format == 'l1':  # the runs of each instruction, for the witness check
                ran = EXECS.setdefault(path, {})
                for z80, page, _code, _kind, n, *_ in doc['instructions']:
                    if page in bases:
                        a = int(z80[1:], 16)
                        ran[a] = ran.get(a, 0) + n
            if src.format == 'trace':
                for a, n in doc['starts'].items():
                    if decode(mem, int(a, 16))[0] == n:
                        starts.add(int(a, 16))
                entries |= {int(a, 16) for a in doc['entries']}
                for a, n in doc['reads'].items():
                    reads[int(a, 16)] += n
                continue
            if mode == 'blocks':
                ran = {}
                for z80, page, code, *_ in doc['instructions']:
                    if page in bases:
                        ran[(page, int(z80[1:], 16))] = bytes.fromhex(code)
                for b in doc['blocks']:
                    first, last = int(b['start'][1:], 16), int(b['end'][1:], 16)
                    if b['page'] not in bases or first < wlo or last >= whi:
                        continue
                    a, block = first, []
                    while a <= last:
                        raw = ran.get((b['page'], a))
                        if raw is None or mem[a:a + len(raw)] != raw or decode(mem, a)[0] != len(raw):
                            break
                        block.append(a)
                        a += len(raw)
                    if a == last + 1:
                        starts.update(block)
            else:
                for z80, page, code, *_ in doc['instructions']:
                    a = int(z80[1:], 16)
                    raw = bytes.fromhex(code)
                    if a < wlo or page not in bases or a + len(raw) > whi:
                        continue
                    # The opcode as the image holds it (an operand may be self-modified)
                    if decode(mem, a)[0] == len(raw) and mem[a] == raw[0] and \
                            (not same_bytes or mem[a:a + len(raw)] == raw):
                        starts.add(a)
                for r in doc['routines']:
                    a = int(r['entry'][1:], 16)
                    if not src.roots and r.get('kinds') == 'root':
                        continue
                    if r['page'] in bases and wlo <= a < whi:
                        entries.add(a)
            # In the builds over the tape load the depacker reads its packed input where the game's code later lies:
            # their reads say nothing
            if not src.reads:
                continue
            for page in doc.get('byte_counts', []):
                base = bases.get(page['page'])
                if base is not None:
                    for i, n in enumerate(page['reads']):
                        if n and wlo <= base + i < whi:
                            reads[base + i] += n
    if same_bytes:  # a routine whose bytes another program later put there is not one of this image's
        entries &= starts
    return starts, entries, reads


def walk(mem, starts, reads, seeds=(), inline=(), cut=None, inline_len=None):
    """Code: the ran instructions and what their untaken branches reach, stopping at bytes read as data; seeds are
    entries the reverse knows as code that no recording ran (handlers reached through a table); a call to a routine in
    inline reads its data after the CALL: the walk does not go on past it (where the code resumes, a recording says)
    unless inline_len gives the routine's fixed count of data bytes, after which the walk goes on;
    cut(address, targets) gives the targets of the instruction at address the walk follows (@over, @bank)"""
    code, targets, calls = {}, set(), set()
    # The ran instructions own their bytes first: a walked one never cuts into them
    owner = {b: a for a in starts for b in range(a, a + decode(mem, a)[0])}
    todo = sorted(starts) + sorted(seeds, reverse=True)
    seen = set()
    while todo:
        a = todo.pop()
        while LO <= a < HI and a not in seen:
            n, tg, falls, call = decode(mem, a)
            if cut:
                tg = cut(a, tg)
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
            fixed = [inline_len[t] for t in tg if call and inline_len and t in inline_len]
            if fixed:
                a += n + fixed[0]
                continue
            if not falls or (call and any(t in inline for t in tg)):
                break
            a += n
    return code, targets, calls


ANNOTATION = re.compile(r'\$([0-9A-Fa-f]{4})(?:\s+([cbwts])\b)?(?:\s+([A-Za-z_]\w*))?(?:\s+(\d+))?\s*(?:;\s*(.*))?$')
HEX4 = r'\$([0-9A-Fa-f]{4})'
NAME = r'([A-Za-z_][\w.]*)'
# The directives the cases added, each also accepted in its old form behind '#' (a comment to the older kit)
CONST = re.compile(r'^@const\s+' + NAME + r'\s+(\$[0-9A-Fa-f]+|\d+)\s*(?:;\s*(.*))?$')
BANK = re.compile(r'^@bank\s+' + HEX4 + r'\s+' + NAME + r'\s+(\w+)\s*(?:;\s*(.*))?$')
VAR = re.compile(r'^@var\s+' + HEX4 + r'\s+' + NAME + r'(?:\s+(\d+))?\s*(?:;\s*(.*))?$')
ALIAS = re.compile(r'^@alias\s+' + NAME + r'\s+(\S+)\s*(?:;\s*(.*))?$')
OVER = re.compile(r'^@over\s+' + HEX4 + r'\s*(?:;\s*(.*))?$')
PIECE = re.compile(r'^@piece\s+(\w+)\s*$')
OLD_FORM = re.compile(r'^#\s*(@(?:bank|var|alias|over|piece)\s.*)$')


class Annotations:
    """An annotation file (docs/ann-format.md): what the reverse knows, one line an address

        @module NAME [; title]    the entries from the next address on go to NAME.asm (NAME-module.asm when NAME is
                                  the top file's own name: @module game beside game.asm); the title heads the file;
                                  the same NAME again adds a stretch to the module (ORG before it in the one file)
        @about text               a paragraph of the current module's header (what it holds, how its parts work)
        $ADDR c|b|w|t|s NAME [N]  an entry: code, bytes (N a line), words (N a line), text, space; ; its title
        > text                    the entry's description, one paragraph a line
        @res FILE                 the entry's bytes are a resource: src/res/FILE, assembled with INCBIN (entries
                                  naming one file share it: it holds the bytes from the first to the end of the last);
                                  a w entry's words that name data labels become ASSERT lines after the INCBINs;
        @res FILE include         ... assembled with INCLUDE "res/FILE.inc" (FILE's suffix .inc): DB / DW lines the
                                  case's res tool writes from the editable form, words as label names (kit/resinc.py);
                                  one entry a file, its inner labels inside the .inc
        $ADDR [NAME] ; comment    an instruction inside an entry: its label, its comment; inside a data entry the
                                  data line that starts at ADDR (the entry's rows are cut there)
        @isub $ADDR INSTRUCTION   the instruction at ADDR written so (a constant the image's bytes cannot tell from an
                                  address: LD HL,-6, not a label + offset; a number stays one even when it is a
                                  label's address, a decimal number stays decimal)
        @inline $ADDR [N]         a routine that reads data placed after its CALL (a print routine with the string
                                  inline): no walk goes past a call to it, the bytes after it are data unless a
                                  recording ran them; with N (a fixed count of data bytes) the walk goes on after them
        @equ $ADDR NAME [N] [at $I,$J ...] ; c
                                  a variable outside the image (the work space the game keeps past its loaded bytes):
                                  NAME EQU $ADDR in the top file, and every instruction operand $ADDR..$ADDR+N-1
                                  written as NAME / NAME+k (N defaults to 1); with 'at', only the operands of the
                                  instructions at $I, $J, ... (a ROM entry $0000 named in its CALL, not in LD HL,$0000);
                                  never a Label+offset's offset, nor a port (LD BC,nn before IN / OUT (C)) unless 'at'
                                  names its instruction
        @const NAME VALUE ; c     NAME EQU VALUE in the top file: a port, a ROM entry, a page value, an address in
                                  another program; the instructions use it through @isub
        @bank $ADDR NAME BANK ; c an address in another RAM bank (BANK a number or a name): NAME EQU $ADDR; the walk
                                  does not follow the instructions whose @isub names it, and the entry mark the
                                  disassembler puts on this image's byte there is dropped
        @var $ADDR NAME [N] ; c   a variable inside the image's work space: a label in its data entry (the line is
                                  cut there), every instruction operand $ADDR+1..$ADDR+N-1 written NAME+k
        @alias NAME EXPR ; c      NAME EQU EXPR, for a name that cannot be a label (the operand of a JP into code)
        @over $ADDR ; why         a branch target that holds other bytes when the branch runs: not followed
        @piece NAME               the lines from here to the next @piece are piece NAME of a part file's segments
                                  (each piece is its own segment); the lines before the first piece hold for all

    @bank, @var, @alias, @over and @piece are also read behind '#' ('# @bank ...'), their form in the cases' first
    generators. piece: read only the common lines and that piece's (an @equ of the common lines inside this image is
    then dropped: another piece's address).
    """

    def __init__(self, path, piece=None, top=None):
        self.top = top  # the top file beside the modules: a module of its name goes to NAME-module.asm
        self.entries, self.inline, self.modules, self.descriptions = {}, {}, [], {}
        self.module_info = {}  # module name: [title, [paragraphs]]
        self.resources = {}  # entry address: the resource file under src/res
        self.res_include = set()  # of those, the entries assembled by INCLUDE of a .inc (@res FILE include)
        self.isub = {}  # instruction address: the instruction as the source writes it
        self.equ = {}  # address outside the image: (name, size, comment)
        self.equ_at = {}  # of those, the ones named only in some instructions: address -> {instruction address}
        self.inline_data = set()  # routines whose callers place data after the CALL
        self.inline_len = {}  # of those, the ones that read a fixed count of bytes: the walk goes on after them
        self.consts = []  # (name, value, comment)
        self.banks = []  # (address, name, bank, comment)
        self.vars = []  # (address, name, size, comment)
        self.aliases = []  # (name, expression, comment)
        self.over = set()  # branch targets not followed
        self.pieces = []  # the piece names, in the file's order
        self.path = path
        last = None
        if not os.path.exists(path):
            return
        current = None  # the piece the line belongs to
        where = os.path.basename(path)
        for number, line in enumerate(open(path, encoding='utf-8'), 1):
            line = line.rstrip('\n')
            text = line.strip()
            old = OLD_FORM.match(text)
            if old:
                text = old.group(1)
            if text.startswith('@piece'):
                m = PIECE.match(text)
                if not m:
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                current = m.group(1)
                self.pieces.append(current)
                continue
            if current is not None and current != piece:
                continue
            if not text or text.startswith('#'):
                continue
            if text.startswith('@const'):
                m = CONST.match(text)
                if not m:
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.consts.append((m.group(1), m.group(2), m.group(3) or ''))
                continue
            if text.startswith('@bank'):
                m = BANK.match(text)
                if not m:
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.banks.append((int(m.group(1), 16), m.group(2), m.group(3), m.group(4) or ''))
                continue
            if text.startswith('@var'):
                m = VAR.match(text)
                if not m:
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.vars.append((int(m.group(1), 16), m.group(2), int(m.group(3) or 1), m.group(4) or ''))
                continue
            if text.startswith('@alias'):
                m = ALIAS.match(text)
                if not m:
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.aliases.append((m.group(1), m.group(2), m.group(3) or ''))
                continue
            if text.startswith('@over'):
                m = OVER.match(text)
                if not m:
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.over.add(int(m.group(1), 16))
                continue
            if text.startswith('@about'):
                if not self.modules:
                    sys.exit(f'{path}:{number}: @about before any @module')
                self.module_info[self.modules[-1][1]][1].append(text[len('@about'):].strip())
                continue
            if text.startswith('@module'):
                body, _, title = text.partition(';')
                name = body.split()[1]
                if name in self.module_info:  # the module again: another stretch of it (its title kept)
                    if title.strip() and not self.module_info[name][0]:
                        self.module_info[name][0] = title.strip()
                else:
                    self.module_info[name] = [title.strip(), []]
                self.modules.append([None, name])
                continue
            if text.startswith('@equ'):
                body, _, comment = text.partition(';')
                parts = body.split()
                address = int(parts[1].lstrip('$'), 16)
                if LO <= address < HI:
                    if piece is not None and current is None:
                        continue  # a common line: another piece's address, a label in this one
                    raise SystemExit(f'{where}:{number}: @equ ${address:04X} is inside the image: name it as a label')
                rest, size = parts[3:], 1
                if rest and rest[0].isdigit():
                    size, rest = int(rest[0]), rest[1:]
                if rest:
                    # '@equ $ADDR NAME [N] at $I,$J ...': only the operands of these instructions
                    at = [x for x in ' '.join(rest[1:]).replace(',', ' ').split()]
                    if rest[0] != 'at' or not at or not all(re.match(r'^\$[0-9A-Fa-f]{4}$', x) for x in at):
                        sys.exit(f'{path}:{number}: cannot read: {line}')
                    self.equ_at[address] = {int(x[1:], 16) for x in at}
                self.equ[address] = (parts[2], size, comment.strip())
                continue
            if text.startswith('@inline'):
                parts = text.split(';')[0].split()
                if len(parts) not in (2, 3) or not re.match(r'^\$[0-9A-Fa-f]{4}$', parts[1]) or \
                        (len(parts) == 3 and not parts[2].isdigit()):
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.inline_data.add(int(parts[1][1:], 16))
                if len(parts) == 3:
                    self.inline_len[int(parts[1][1:], 16)] = int(parts[2])
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
                parts = text.split()
                if len(parts) not in (2, 3) or (len(parts) == 3 and parts[2] != 'include'):
                    sys.exit(f'{path}:{number}: cannot read: {line}')
                self.resources[last] = parts[1]
                if len(parts) == 3:
                    self.res_include.add(last)
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
                self.merge_inner(a, name, comment, f'{path}:{number}')
        if piece is not None and piece not in self.pieces:
            sys.exit(f'{path}: no @piece {piece}')
        # A variable is a label inside its data entry, as if its line came last: '$ADDR NAME ; comment'
        for a, name, _, comment in self.vars:
            self.merge_inner(a, name, comment or None, f'{path}: @var')
        for start, name in self.modules:
            if start is None:
                sys.exit(f'{path}: module {name} holds no entry')

    def merge_inner(self, a, name, comment, where):
        # Two lines for one address (a name on one, a comment on the other) are merged, not the last kept
        was_name, was_comment = self.inline.get(a, (None, None))
        if name and was_name and name != was_name:
            sys.exit(f'{where}: ${a:04X} named twice: {was_name}, {name}')
        self.inline[a] = (name or was_name, comment or was_comment)

    def name(self, a):
        if a in self.entries and self.entries[a][1]:
            return self.entries[a][1]
        if a in self.inline and self.inline[a][0]:
            return self.inline[a][0]
        return None

    def fields(self):
        """{address: name} of the inner names on the first address of a data entry that has a name of its own (a
        record's first field): a second label there, the name of the LDs through memory at that address"""
        return {a: self.inline[a][0] for a, (kind, name, _, _) in self.entries.items()
                if kind != 'c' and LO <= a < HI and name and self.inline.get(a, (None,))[0] not in (None, name)}

    def cut(self):
        """the walk's filter of branch targets: none into @over addresses, and none into an @bank address from an
        instruction whose @isub names a bank (it would read this image's bytes there as code); None when neither"""
        bank_names = {name for _, name, _, _ in self.banks}
        bank_targets = {a for a, _, _, _ in self.banks}
        crossing = {a for a, text in self.isub.items() if set(re.findall(r'[A-Za-z_]\w*', text)) & bank_names}
        if not self.over and not crossing:
            return None
        over = self.over

        def cut(at, targets):
            return [t for t in targets if t not in over and not (at in crossing and t in bank_targets)]
        return cut


DATA = {'b': 'B', 'w': 'W', 't': 'T', 's': 'S'}


def write_ctl(mem, code, targets, calls, entries, ann, path):
    lines = ['@ $%04X start' % LO, '@ $%04X org' % LO]
    extents = {}  # data entry address: its length
    starts_entry = set(entries) | set(calls)
    # the fixed data bytes after a CALL to an @inline routine with a count: a B sub-block of the calling entry
    inline_bytes = {}
    branched = set()  # the addresses an instruction names as its target
    for c in code:
        n, tg, falls, call = decode(mem, c)
        branched.update(tg)
        fixed = [ann.inline_len[t] for t in tg if call and t in ann.inline_len]
        if fixed and c + n not in code and c + n not in ann.entries:
            inline_bytes[c + n] = fixed[0]
    # where the code resumes after those bytes: the routine returns there (a recorded jump), no label unless named
    resumes = {c + n for c, n in inline_bytes.items()} - branched
    a = LO
    kind = None
    data_kind, data_width = 'b', None
    while a < HI:
        if a in inline_bytes and kind == 'c':
            lines.append('B $%04X,%d' % (a, inline_bytes[a]))
            a += inline_bytes[a]
            continue
        is_code = a in code
        known = ann.entries.get(a)
        if known and (known[0] == 'c') != is_code:
            sys.exit('game.ann: $%04X is %s, the recordings say %s' % (a, known[0], 'code' if is_code else 'data'))
        new_entry = (kind is None or is_code != (kind == 'c') or known is not None or
                     (is_code and a in starts_entry and a not in resumes) or (not is_code and kind == 'c'))
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
        elif is_code and ((a in targets and a not in resumes) or ann.name(a)):
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
        odd = kind == 'w' and length % 2 == 1  # a word block of odd length: sna2skool would write one byte more
        if odd:
            length -= 1
        if length and (kind == 's' or not width):
            item = '%s $%04X,%d' % (spec, start, length)
        elif length:
            item = '%s $%04X,%d,%d' % (spec, start, length, width * (2 if kind == 'w' else 1))
        else:
            item = 'B $%04X,1' % start
        out.append(item + (' ' + comment if comment else ''))
        if odd and length:
            out.append('B $%04X,1' % (start + length))
    return out


DATA_LINE = re.compile(r'^  DEF[BWMS] ')
LABEL_LINE = re.compile(r'^([A-Za-z_]\w*):$')
# the rest of a data line's comment that skool2asm wraps onto lines of their own (only spaces before the ';')
COMMENT_LINE = re.compile(r'^ +;')


def word_checks(lines, a, label, inner, is_data):
    """The ASSERT lines that keep the labels of a w entry's DEFW lines once they are INCBIN bytes: for each DEFW line
    with a data label among its words, its checks on lines of up to 116 columns ('  ASSERT {TileGraphics} ==
    TileData'). A word equal to a code label is taken for a number (a resource holds data: attributes that match an
    instruction's address), and so is $0000 or $FFFF (an end mark). lines: the entry's data, label and wrapped comment lines; a, label: the entry; inner:
    {label: address}; is_data(label): the label is on a data entry"""
    out, base, at = [], (label, a), a
    for line in lines:
        m = LABEL_LINE.match(line)
        if m:
            base = (m.group(1), inner.get(m.group(1), at))
            at = base[1]
            continue
        code = line.partition(';')[0].strip()
        if not code:
            continue
        kind, _, operands = code.partition(' ')
        items = [x.strip() for x in operands.split(',')]
        if kind == 'DEFB' and all(re.match(r'^(\$[0-9A-F]+|\d+)$', x) for x in items):
            at += len(items)
            continue
        if kind != 'DEFW':
            break  # a text or space line: the addresses after it are not followed
        checks = []
        for x in items:
            if re.match(r'^[A-Za-z_]\w*$', x) and is_data(x):
                where = base[0] + ('+%d' % (at - base[1]) if at > base[1] else '')
                checks.append('{%s} == %s' % (where, x))
            at += 2
        line = ''
        for check in checks:  # as many checks a line as 116 columns hold
            if line and len(line) + 4 + len(check) > 116:
                out.append(line)
                line = ''
            line = line + ' && ' + check if line else '  ASSERT ' + check
        if line:
            out.append(line)
    return out


INCLUDED = {}  # resource file: the numeric .inc of an @res FILE include (installed for a case without a res hook)


def write_resources(text, mem, extents, ann, out, word_asserts=True):
    """The resource entries of game.ann as files under out/res and INCBIN lines in the listing: (text, {file: (lo,
    hi)}). An entry's data lines (and the labels inside it) become INCBIN slices of its file, its label and comments
    stay. A w entry's DEFW words that skool2asm wrote as labels become ASSERT lines after its INCBINs (word_checks;
    word_asserts False: not, in code assembled under DISP, where {address} reads other bytes)"""
    files = {}
    for a, name in ann.resources.items():
        if a not in extents:
            sys.exit('game.ann: @res %s on $%04X, which is no data entry' % (name, a))
        lo, hi = files.get(name, (a, a + extents[a]))
        files[name] = (min(lo, a), max(hi, a + extents[a]))
    for a in ann.res_include:
        name = ann.resources[a]
        if files[name] != (a, a + extents[a]):
            sys.exit('game.ann: @res %s include on $%04X: the file is shared with another entry (an INCLUDE takes '
                     'one entry)' % (name, a))
    for name, (lo, hi) in files.items():
        path = os.path.join(out, 'res', name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(mem[lo:hi])
    inner = {n: a for a, (n, _) in ann.inline.items() if n}
    where = dict(inner, **{e[1]: a for a, e in ann.entries.items() if e[1]})

    def is_data(name):
        m = re.match(r'^data_([0-9A-F]{4})$', name)
        at = int(m.group(1), 16) if m else where.get(name)
        # $0000 and $FFFF are a table's end marks far more often than pointers (Moon Patrol's TuneEnd $FFFF is not
        # Im2Vector's address)
        return at not in (None, 0x0000, 0xFFFF) and any(d <= at < d + n for d, n in extents.items())

    lines = text.splitlines()
    for a, name in sorted(ann.resources.items()):
        label = ann.name(a)
        at = lines.index(label + ':')
        end = at + 1
        cuts = []  # (address, label) of the labels inside the entry
        while end < len(lines) and (DATA_LINE.match(lines[end]) or LABEL_LINE.match(lines[end]) or
                                    COMMENT_LINE.match(lines[end])):
            m = LABEL_LINE.match(lines[end])
            if m:
                if m.group(1) not in inner or not a <= inner[m.group(1)] < a + extents[a]:
                    sys.exit('game.ann: %s inside the resource %s has no address in it' % (m.group(1), name))
                cuts.append((inner[m.group(1)], m.group(1)))
            end += 1
        if a in ann.res_include:
            # the numeric .inc: mkgame's own check (the case's res tool writes the one the build includes)
            fields = {k - a: n for k, n in ann.fields().items() if k == a}
            fields.update({k - a: n for k, n in cuts})
            text_inc = resinc.numeric(mem[a:a + extents[a]], fields,
                                      ['%s: %s (kit/mkgame.py, the image\'s bytes)' % (resinc.inc_name(name), label)])
            open(os.path.join(out, 'res', resinc.inc_name(name)), 'w').write(text_inc)
            INCLUDED[name] = text_inc
            lines[at + 1:end] = ['  INCLUDE "res/%s"' % resinc.inc_name(name)]
            continue
        body, start = [], a
        for cut, cut_label in cuts + [(a + extents[a], None)]:
            if cut > start:
                body.append('  INCBIN "res/%s",$%04X,%d' % (name, start - files[name][0], cut - start))
            if cut_label:
                body.append(cut_label + ':')
            start = cut
        if word_asserts and ann.entries.get(a, ('',))[0] == 'w':
            body += word_checks(lines[at + 1:end], a, label, inner, is_data)
        lines[at + 1:end] = body
    return '\n'.join(lines) + '\n', files


def module_file(name, top=None):
    """The file stem of module NAME: NAME, or NAME-module when the top file beside it is NAME.asm (a module 'game'
    next to game.asm, the file that includes the modules)"""
    return name + '-module' if top and name == top else name


def module_header(name, ann):
    """The comment block that opens a module's file: its title and @about paragraphs"""
    title, paragraphs = ann.module_info.get(name, ['', []])
    if not title and not paragraphs:
        return ''
    out = ['; ' + module_file(name, ann.top) + '.asm' + (': ' + title if title else ''), ';']
    for k, para in enumerate(paragraphs):
        out += ['; ' + line for line in textwrap.wrap(para, 116)]
        out.append(';')
    rule = '; ' + '-' * 116
    return rule + '\n' + '\n'.join(out[:-1] if out[-1] == ';' else out) + '\n' + rule + '\n\n'


def split_modules(text, ann):
    """The listing cut into the modules of game.ann: ([(name, text)], the head before the first). A module named
    again further on (@module NAME a second time: an IM 2 handler and its vector table far apart) holds several
    stretches of addresses in its one file; the files are included in the order of their first stretch, and a
    stretch the assembly does not reach in that order starts with ORG at its address"""
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
        cuts.append((at, name, start))
    head = out_lines[:cuts[0][0]] if cuts else out_lines
    stretches = {}  # module name -> [(start, end address, lines)], in address order
    for k, (at, name, start) in enumerate(cuts):
        end = cuts[k + 1][0] if k + 1 < len(cuts) else len(out_lines)
        stop = cuts[k + 1][2] if k + 1 < len(cuts) else None
        stretches.setdefault(name, []).append((start, stop, '\n'.join(out_lines[at:end]).rstrip()))
    parts, here = [], cuts[0][2]
    for name, pieces in stretches.items():  # dicts keep the order of the first stretches
        body = []
        for start, stop, lines in pieces:
            if start != here:
                lines = '  ORG $%04X\n\n' % start + lines
            body.append(lines)
            here = stop
        parts.append((name, module_header(name, ann) + '\n\n'.join(body) + '\n'))
    return parts, '\n'.join(head).rstrip() + '\n'


# The operands that are always addresses: an LD through memory ((nn) on either side, any register), the LD of an
# address register (HL, DE, IX, IY, SP), and a JP / CALL / JR / DJNZ target that has no label of its own (a jump into
# an instruction's operand, into a data entry). "operands": "narrow" keeps to these
ADDRESS_OPERAND = re.compile(r'^(LD (?:\((?=\$)|(?:A|BC|HL|DE|IX|IY|SP),\((?=\$)|(?:HL|DE|IX|IY|SP),)'
                             r'|(?:JP|CALL|JR|DJNZ) (?:(?:NZ|Z|NC|C|PO|PE|P|M),)?)\$([0-9A-F]{4})(\)?.*)$')
# LD BC,nn whose nn lies inside an entry of the image: by default only when BC is a pointer (bc_is_pointer), with
# "operands": "wide" always (a part where every such LD BC is a pointer), with "narrow" never
ADDRESS_OPERAND_WIDE = re.compile(r'^(LD (?:\((?=\$)|(?:A|BC|HL|DE|IX|IY|SP),\((?=\$)|(?:HL|DE|BC|IX|IY|SP),)'
                                  r'|(?:JP|CALL|JR|DJNZ) (?:(?:NZ|Z|NC|C|PO|PE|P|M),)?)\$([0-9A-F]{4})(\)?.*)$')


SKOOL_LINE = re.compile(r'^([ bcstuwi*])\$[0-9A-F]{4} (\S.*?)(\s*;.*)?$')
# BC changed, used as a number (a port, a count, an offset), or the flow leaving: the look for a use of LD BC,nn ends
BC_CHANGED = re.compile(r'^(?:LD (?:B|C|BC),|POP BC|EXX|EX |INC (?:B|C)$|DEC (?:B|C|BC)$|(?:ADD|ADC|SBC) HL,BC|'
                        r'(?:JP|JR|CALL|RET|RST|DJNZ)\b|(?:LD|CP|IN|OT)[ID]R?$|IN |OUT )')


def bc_is_pointer(lines, k, reach=12):
    """True when the LD BC,nn on skool line k loads a pointer: within the next reach instructions of its entry, before
    BC changes or the flow leaves, an instruction reads or writes through (BC). A port (OUT (C),A), a count (LDIR,
    DEC BC), an offset (ADD HL,BC) or a pair of bytes (B and C apart) never does, so they stay numbers; a pointer
    handed to a routine (CALL) needs an @isub"""
    seen = 0
    for line in lines[k + 1:]:
        m = SKOOL_LINE.match(line)
        if not m:
            continue
        if m.group(1) not in ' *' or m.group(2).startswith('DEF'):
            return False  # the next entry, or data
        text = m.group(2).upper()
        if '(BC)' in text:
            return True
        if BC_CHANGED.match(text):
            return False
        seen += 1
        if seen >= reach:
            return False
    return False


# an instruction that takes the port from BC: IN r,(C), OUT (C),r and the block forms (C the port, B the count)
PORT_USE = re.compile(r'^(?:IN [A-Z]+,\(C\)|IN \(C\)|OUT \(C\),|IN[ID]R?$|OT[ID]R$|OUT[ID]$)')


def port_loads(skool, reach=12):
    """{address: instruction} of the LD BC,nn whose BC is a port: within the next reach instructions of its entry,
    before BC changes or the flow leaves, an IN or OUT through (C) uses it ($797F LD BC,$7EFE, then IN A,(C)). Their
    nn stays a number whatever label or @equ name has that address"""
    lines = skool.splitlines()
    out = {}
    for k, line in enumerate(lines):
        m = SKOOL_LINE.match(line)
        if not m or m.group(1) not in ' c*' or not re.match(r'^LD BC,\$[0-9A-F]{4}$', m.group(2)):
            continue
        seen = 0
        for after in lines[k + 1:]:
            n = SKOOL_LINE.match(after)
            if not n:
                continue
            if n.group(1) not in ' *' or n.group(2).startswith('DEF'):
                break  # the next entry, or data
            text = n.group(2).upper()
            if PORT_USE.match(text):
                out[int(line[2:6], 16)] = m.group(2)
                break
            if BC_CHANGED.match(text) or '(BC)' in text:
                break
            seen += 1
            if seen >= reach:
                break
    return out


def label_inner_addresses(skool, written=None, operands='pointer', fields=None):
    """An address operand inside an entry (a field of a record, a byte of a table) as Label+offset: @isub lines for
    skool2asm, which only replaces the addresses that have a label of their own. fields: {address: name} of the
    field names on data entries' first addresses: an LD through memory there names the field, not the entry"""
    pattern = ADDRESS_OPERAND if operands == 'narrow' else ADDRESS_OPERAND_WIDE
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
    line_starts = set(starts)
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
    for k, line in enumerate(lines):
        m = re.match(r'^([ c*])\$([0-9A-F]{4}) (\S.*?)(\s*;.*)?$', line)
        if m and written and int(m.group(2), 16) in written:
            out.append('@isub=' + written.pop(int(m.group(2), 16)))
        elif m:
            op = pattern.match(m.group(3))
            if op and not op.group(1).startswith('LD') and int(op.group(2), 16) in line_starts:
                op = None  # a branch to a line start: skool2asm gives it a label of its own
            if op and op.group(1) == 'LD BC,' and operands == 'pointer' and not bc_is_pointer(lines, k):
                op = None  # a port, a count, an offset or two bytes, not an address
            if op:
                target = int(op.group(2), 16)
                if fields and target in fields and '(' in op.group(1):
                    name = fields[target]
                else:
                    name = resolve(target) if LO <= target < HI else None
                if name:
                    out.append('@isub=%s%s%s' % (op.group(1), name, op.group(3)))
                    count += 1
        out.append(line)
    return '\n'.join(out) + '\n', count


SKOOL_INSTRUCTION = re.compile(r'^[ c*]\$([0-9A-F]{4}) (?!DEF[BWMS] )\S')
ASM_INSTRUCTION = re.compile(r'^  (?!DEF[BWMS]|ORG )[A-Z]')


def instruction_order(skool):
    """The addresses of the instruction lines, in the order skool2asm writes them: name_variables leaves the @isub
    ones as the .ann wrote them, and names an '@equ ... at' variable only in its instructions"""
    return [int(m.group(1), 16) for m in map(SKOOL_INSTRUCTION.match, skool.splitlines()) if m]


def name_variables(text, equ, inner=None, order=None, isubs=(), equ_at=None):
    """Every instruction operand that is a variable's address (@equ; inner: {address: NAME+k} of the @var lines),
    written as the variable's name. order (instruction_order): the instructions' addresses; the @isub ones (isubs)
    are left as written, an @equ in equ_at ({address: {instruction address}}) names only those instructions"""
    equ_at = equ_at or {}
    names, only = {}, {}  # only: operand address -> (name, the instructions it is named in)
    for address, (name, size, _) in equ.items():
        for k in range(size):
            label = name if k == 0 else '%s+%d' % (name, k)
            if address in equ_at:
                only[address + k] = (label, equ_at[address])
            else:
                names[address + k] = label
    passes = [p for p in (names, inner or {}, only) if p]
    if not passes:
        return text
    lines = text.splitlines(True)
    if (isubs or only) and order is not None:
        found = sum(1 for line in lines if ASM_INSTRUCTION.match(line.partition(';')[0]))
        if found != len(order):  # the skool's instructions are not the listing's one for one
            print(f'warning: {len(order)} instructions in the skool file, {found} in the listing: @isub operands '
                  'may be renamed by @equ / @var, and no "@equ ... at" name is applied')
            order = None
    if order is None:
        order, isubs = [], ()
        only = {}
        passes = [p for p in (names, inner or {}) if p]
    for table in passes:
        out, n = [], 0
        for line in lines:
            code, semi, comment = line.partition(';')
            if re.match(r'^  [A-Z]', code) and not re.match(r'^  DEF[BWMS]', code):
                at = order[n] if n < len(order) else None
                if at not in isubs:
                    if table is only:
                        def sub(m):
                            label, where = only.get(int(m.group(1), 16), (None, ()))
                            return label if at in where else m.group(0)
                    else:
                        def sub(m):
                            return table.get(int(m.group(1), 16), m.group(0))
                    # not the offset of a Label+offset (LD HL,data_96FE+$4455 is no Screen address)
                    code = re.sub(r'(?<![\w)][+-])\$([0-9A-F]{4})\b', sub, code)
                n += not code.startswith('  ORG ')
            out.append(code + semi + comment)
        lines = out
    return ''.join(lines)


# a decimal number in an instruction (not a hex digit run after $, not part of a name)
DECIMAL = re.compile(r'(?<![$\w])\d+(?!\w)')


def restore_isubs(text, order, isubs):
    """The @isub instructions as the .ann writes them where skool2asm put a label for a number (@isub $797F
    LD BC,$7EFE written LD BC,ShiftGraphic4: the number is that label's address) or wrote a decimal number in hex
    (@isub $XXXX LD DE,-10000 written LD DE,-$2710). order: instruction_order; isubs: {address: instruction}. A name
    the .ann wrote stays. Returns (text, {address: the label skool2asm had put there})"""
    if not isubs:
        return text, {}
    lines = text.splitlines(True)
    found = sum(1 for line in lines if ASM_INSTRUCTION.match(line.partition(';')[0]))
    if found != len(order):
        print(f'warning: {len(order)} instructions in the skool file, {found} in the listing: an @isub number '
              'skool2asm wrote as a label stays so')
        return text, {}

    def names(s):
        return set(re.findall(r'[A-Za-z_]\w*', re.sub(r'\$[0-9A-Fa-f]+', ' ', s)))

    out, n, restored = [], 0, {}
    for line in lines:
        code, semi, comment = line.partition(';')
        if ASM_INSTRUCTION.match(code):
            at = order[n] if n < len(order) else None
            n += 1
            want = isubs.get(at)
            extra = names(code) - names(want) if want else set()
            if want and (extra or DECIMAL.search(want)) and code.strip() != want:
                if extra:
                    restored[at] = ', '.join(sorted(extra))
                body = '  ' + want
                if not semi:
                    code = body + '\n'
                else:  # the comment keeps its column when the instruction fits before it
                    code = body.ljust(len(code)) if len(body) < len(code) else body + ' '
        out.append(code + semi + comment)
    return ''.join(out), restored


def equates(equ, title='; The variables past the loaded image (game.ann @equ)'):
    """The variables outside the image (@equ), as EQU lines"""
    if not equ:
        return ''
    lines = ['', title]
    for address, (name, size, comment) in sorted(equ.items()):
        lines.append('%-14s EQU $%04X%s' % (name, address, ('  ; ' + comment) if comment else ''))
    return '\n'.join(lines) + '\n'


def constants(consts):
    """@const lines as EQU lines"""
    if not consts:
        return ''
    lines = ['', '; Constants: addresses outside this image, ROM entries, ports (@const)']
    for name, value, comment in consts:
        lines.append('%-18s EQU %s%s' % (name, value, ('  ; ' + comment) if comment else ''))
    return '\n'.join(lines) + '\n'


def bank_equates(banks):
    """@bank lines as EQU lines, by bank and address"""
    if not banks:
        return ''
    lines = ['', '; Addresses in other RAM banks (@bank)']

    def order(x):
        return (0, int(x[2]), '') if x[2].isdigit() else (1, 0, x[2]), x[0]

    for addr, name, bank, comment in sorted(banks, key=order):
        lines.append('%-14s EQU $%04X  ; bank %s%s' % (name, addr, bank, (': ' + comment) if comment else ''))
    return '\n'.join(lines) + '\n'


def alias_equates(aliases):
    if not aliases:
        return ''
    lines = ['', '; Names that cannot be labels (@alias)']
    for name, expr, comment in aliases:
        lines.append('%-14s EQU %s%s' % (name, expr, ('  ; ' + comment) if comment else ''))
    return '\n'.join(lines) + '\n'


def decimal_isubs(text, isubs):
    """skool2asm -H writes every number of an @isub in hex (LD DE,1*256+30 as LD DE,$0001*$0100+$001E): the
    instructions as the .ann writes them again"""
    for isub in set(isubs):
        parts = re.split(r'(?<![$\w])(\d+)(?!\w)', isub)
        if len(parts) == 1:
            continue
        pattern = ''.join(r'\$0*%X(?![0-9A-F])' % int(p) if k % 2 else re.escape(p) for k, p in enumerate(parts))
        text = re.sub(r'^  %s(?:\s+(;.*))?$' % pattern,
                      lambda m: ('%-26s%s' % ('  ' + isub, m.group(m.lastindex))).rstrip()
                      if m.lastindex and m.group(m.lastindex) else '  ' + isub, text, flags=re.M)
    return text


def run(cmd, **kw):
    p = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if p.returncode:
        sys.exit(f'{cmd[0]}: {p.stderr.strip() or p.stdout.strip()}')
    return p


def hexa(text):
    """'$C000', 'C000', '0xC000' -> 0xC000; an int stays"""
    if isinstance(text, int):
        return text
    text = text.strip()
    return int(text[2:], 16) if text.lower().startswith('0x') else int(text.lstrip('$'), 16)


def natural_bases(pages, run_at=None):
    """L1 page -> Z80 base: page 5 at $4000, 2 at $8000, any other at $C000 (the 128K's paged slot)"""
    return {p: {5: 0x4000, 2: 0x8000}.get(p, 0xC000) for p in pages}


# ------------------------------------------------------------------------------------------------- one segment


class Segment:
    """One run of the pipeline: an .ann over bytes lo..hi-1 of the image, run (assembled) at run..; its options
    fall back to the part's (docs/ann-format.md 5)"""

    def __init__(self, spec, part):
        get = lambda k, d=None: spec.get(k, part.get(k, d))  # noqa: E731
        self.spec = spec
        self.ann = os.path.join(ROOT, spec['ann']) if spec.get('ann') else None
        self.piece = spec.get('piece')
        self.lines = spec.get('lines')
        self.lo = hexa(spec['lo']) if 'lo' in spec else None
        self.hi = hexa(spec['hi']) if 'hi' in spec else None
        self.run = hexa(spec['run']) if 'run' in spec else self.lo
        self.title = spec.get('title')
        self.load_label = spec.get('load_label')
        self.bank = get('bank')
        if 'bases' in spec or 'bases' in part:
            self.bases = {int(k): hexa(v) for k, v in get('bases').items()}
        elif get('pages') is not None or self.bank is not None:
            pages = list(get('pages') or []) + ([self.bank] if self.bank is not None else [])
            self.bases = natural_bases(pages, self.run or 0)
        else:
            self.bases = {5: 0x4000, 2: 0x8000, 0: 0xC000}
        read_builds = tuple(get('read_builds', ()))
        l1 = spec['l1'] if 'l1' in spec else part.get('l1', [])
        self.sources = [Source.parse(s, ROOT, read_builds) for s in l1]
        self.mode = get('mode', 'instructions')
        self.same_bytes = bool(get('same_bytes'))
        self.data_entries = get('data_entries')
        self.overwritten = [(hexa(a), hexa(b)) for a, b in get('overwritten', [])]
        self.operands = get('operands', 'pointer')
        self.isub_as_written = bool(get('isub_as_written'))
        self.drop_data_refs = bool(get('drop_data_refs'))
        self.no_entries = bool(get('no_entries', self.mode == 'blocks'))
        self.entries_in_code = bool(get('entries_in_code'))
        self.single = False  # set by single_part

    def tag(self):
        return os.path.splitext(os.path.basename(self.ann))[0] + ('-' + self.piece if self.piece else '')


def generate(seg, mem, args, out, top):
    """The segment through the pipeline: (modules [(name, text)], head, resources {file: bytes}, ann, labels,
    stats); mem is the 64 K image with the segment's bytes at their run address; LO, HI set to the run range"""
    starts, entries, reads = read_sources(seg.sources, mem, LO, HI, seg.bases, seg.mode, seg.same_bytes)
    for s, e in seg.overwritten:  # code another block puts there later ran there, not this image's bytes
        starts = {a for a in starts if not s <= a < e}
        entries = {a for a in entries if not s <= a < e}
        for b in range(s, e):
            reads[b] = max(reads[b], 1)
    ann = Annotations(seg.ann, seg.piece, top)
    if seg.data_entries:
        # an annotated data entry (to the next entry) is data: an instruction a recording ran there is another
        # program's whose bytes match (a lone NOP equal to a zero of the font); the walk stops there
        bounds = sorted(ann.entries) + [HI]
        for k, a in enumerate(bounds[:-1]):
            if ann.entries[a][0] == 'c':
                continue
            if seg.data_entries == 'first':
                if a not in starts:
                    reads[a] += 1
                continue
            for b in range(a, bounds[k + 1]):
                reads[b] += 1
                starts.discard(b)
    if seg.no_entries:
        entries = set()
    code, targets, calls = walk(mem, starts, reads, [a for a, e in ann.entries.items() if e[0] == 'c'],
                                ann.inline_data, ann.cut(), ann.inline_len)
    if seg.entries_in_code:
        # a CALL a recording saw into code that is no longer this image's (copied over it later) is no entry
        entries = {a for a in entries if a in code}
    # the single layout's control file is work/.../game.ctl, as kit/refdocs.py and the cases' doc tools read it
    tag = 'game' if seg.single else seg.tag()
    ctl = os.path.join(out, tag + '.ctl')
    extents = write_ctl(mem, code, targets, calls, entries, ann, ctl)
    image = os.path.join(out, tag + '-image.bin')
    open(image, 'wb').write(mem[LO:])
    py = toolpaths.skoolkit_python(args.venv)
    sk = run([py, os.path.join(args.venv, 'bin', 'sna2skool.py'), '-H', '-c', ctl, '-o', str(LO), image]).stdout
    if seg.drop_data_refs:
        # sna2skool marks every operand's address as a reference (*); inside data that is only an operand the
        # source writes with a constant: no label for skool2asm to make
        sk = re.sub(r'^\*(\$[0-9A-F]{4} DEF)', r' \1', sk, flags=re.M)
    if ann.banks:
        # no entry mark on this image's byte at another bank's address
        marks = '|'.join('%04X' % a for a, _, _, _ in ann.banks)
        sk = re.sub(r'^\*\$(%s) ' % marks, r' $\1 ', sk, flags=re.M)
    written = dict(ann.isub)
    # an LD BC,nn that feeds IN / OUT (C) is a port: kept as the number unless an @isub or an '@equ ... at' says
    # otherwise
    listed = set().union(*ann.equ_at.values()) if ann.equ_at else set()
    ports = {a: t for a, t in port_loads(sk).items() if a not in written and a not in listed}
    written.update(ports)
    isubs = dict(written)
    fields = ann.fields()
    sk, inner = label_inner_addresses(sk, written, seg.operands, fields)
    if written:
        sys.exit('%s: @isub on no instruction: %s' % (os.path.relpath(seg.ann, ROOT),
                                                      ', '.join('$%04X' % a for a in sorted(written))))
    skool = os.path.join(out, tag + '.skool')
    open(skool, 'w').write(sk)
    text = run([py, os.path.join(args.venv, 'bin', 'skool2asm.py'), '-H', skool]).stdout
    for half in ('IXl', 'IXh', 'IYl', 'IYh'):
        text = text.replace(half, half.upper())
    for a, field in sorted(fields.items()):  # a field on an entry's first address: a second label there
        text = re.sub(r'^(%s:\n)' % re.escape(ann.name(a)), r'\g<1>%s:\n' % field, text, count=1, flags=re.M)
    var_names = {a + k: '%s+%d' % (name, k) for a, name, size, _ in ann.vars for k in range(1, size)}
    order = instruction_order(sk)
    stray = sorted(set().union(*ann.equ_at.values()) - set(order)) if ann.equ_at else []
    if stray:
        sys.exit('%s: @equ ... at no instruction: %s' % (os.path.relpath(seg.ann, ROOT),
                                                         ', '.join('$%04X' % a for a in stray)))
    text = name_variables(text, ann.equ, var_names, order, isubs, ann.equ_at)
    text, restored = restore_isubs(text, order, isubs)
    for a, instruction in sorted(ports.items()):
        value = int(instruction[-4:], 16)
        names = [n if value == e else '%s+%d' % (n, value - e) for e, (n, size, _) in sorted(ann.equ.items())
                 if e <= value < e + size and e not in ann.equ_at] + \
            [n for n in (var_names.get(value),) if n] + ([restored[a]] if a in restored else [])
        if names:
            print(f'port: ${a:04X} {instruction} feeds IN / OUT (C): kept a number, not {", ".join(names)}')
    if seg.isub_as_written:
        text = decimal_isubs(text, ann.isub.values())
    # a commented data sub-block of several lines: SkoolKit leaves a bare ';' on the lines after the first
    text = re.sub(r'^(  DEF[BWMS] .*?)\s+;$', r'\1', text, flags=re.M)
    text, files = write_resources(text, mem, extents, ann, out, seg.run == (seg.lo if seg.lo is not None else LO))
    names = [name for _, name in ann.modules]
    again = sorted({n for n in names if names.count(n) > 1})
    if again and seg.run != (seg.lo if seg.lo is not None else LO):
        sys.exit('%s: module %s named twice: a module of several stretches needs ORG, not a segment under DISP'
                 % (os.path.relpath(seg.ann, ROOT), ', '.join(again)))
    modules, head = split_modules(text, ann)
    resources = {name: mem[a:b] for name, (a, b) in files.items()}
    labels = set(re.findall(r'^([A-Za-z_]\w*):$', text, flags=re.M))
    stats = (f'code bytes {sum(code.values())} ({len(code)} instructions, {len(starts)} ran), '
             f'entries {sum(1 for line in open(ctl) if line[:2] in ("c ", "b ", "t ", "w ", "s "))}, '
             f'modules {len(modules)}, resources {len(files)}, addresses inside entries as Label+offset {inner}')
    return modules, head, resources, ann, labels, stats


# ------------------------------------------------------------------------------------------------- a part


def part_image(part):
    """(64 K memory with the image at its address, the image's bytes, the address of its byte 0)"""
    missing = not os.path.exists(os.path.join(ROOT, part['image']))
    if part.get('image_cmd') and (part.get('image_always', True) or missing):
        run(part['image_cmd'], cwd=ROOT)
    path = os.path.join(ROOT, part['image'])
    if not os.path.exists(path):
        sys.exit(f'{path}: no image (%s)' % (part.get('image_note') or 'its part file says what makes it'))
    data = open(path, 'rb').read()
    at = hexa(part['at']) if 'at' in part else (0 if len(data) == 0x10000 else hexa(part['org']))
    if at + len(data) > 0x10000:
        sys.exit(f'{path}: {len(data)} bytes at ${at:04X} run past $FFFF')
    mem = bytearray(0x10000)
    mem[at:at + len(data)] = data
    return bytes(mem), data, at


def call_hook(spec, *args):
    """'tools/x.py' (its install) or 'tools/x.py:function' of the case, called with args"""
    path, _, func = spec.partition(':')
    full = os.path.join(ROOT, path)
    sys.path.insert(0, os.path.dirname(full))
    name = os.path.splitext(os.path.basename(full))[0]
    mod = sys.modules.get(name)
    if mod is None or os.path.abspath(getattr(mod, '__file__', '')) != os.path.abspath(full):
        loader = importlib.util.spec_from_file_location(name, full)
        mod = importlib.util.module_from_spec(loader)
        sys.modules[name] = mod
        loader.loader.exec_module(mod)
    return getattr(mod, func or 'install')(*args)


def stamps(res, files):
    """{path: (mtime, size)} of every file under res named like a resource (NAME.bin and NAME.* beside it)"""
    out = {}
    for name in files:
        stem = os.path.splitext(os.path.join(res, name))[0]
        for path in glob.glob(glob.escape(stem) + '.*'):
            st = os.stat(path)
            out[path] = (st.st_mtime_ns, st.st_size)
    return out


def drop_stale_bins(res, files, before):
    """After the case's hook: a resource's NAME.bin the hook did not write, while it wrote the editable form beside
    it (NAME.png, NAME.txt), is an older install's: the case's build would read both. It is deleted"""
    for name in files:
        path = os.path.join(res, name)
        if not path.endswith('.bin') or path not in before or not os.path.exists(path):
            continue
        st = os.stat(path)
        if (st.st_mtime_ns, st.st_size) != before[path]:
            continue  # the hook wrote the bytes themselves
        stem = os.path.splitext(path)[0]
        written = [p for p in glob.glob(glob.escape(stem) + '.*') if p != path and
                   (os.stat(p).st_mtime_ns, os.stat(p).st_size) != before.get(p)]
        if written:
            os.remove(path)
            print(f'removed {os.path.relpath(path, ROOT)} (stale: the case writes '
                  f'{", ".join(os.path.basename(p) for p in written)})')


def install_resources(part, resources, built=()):
    """the part's resources into the case: through its res_install hook, as bytes into its res folder, or (the
    case's game) through tools/res_formats.py when the case has one, else as bytes into src/res"""
    files = {k: v for k, v in resources.items() if k not in built}
    if not files:
        return 0
    if part.get('res_install') or (part.get('game') and not part.get('res') and
                                   os.path.isfile(os.path.join(ROOT, 'tools', 'res_formats.py'))):
        res = os.path.join(ROOT, part.get('res') or os.path.join('src', 'res'))
        before = stamps(res, files)
        call_hook(part.get('res_install') or 'tools/res_formats.py', files)
        drop_stale_bins(res, files, before)
    elif part.get('res') or part.get('game'):
        for name, data in files.items():
            path = os.path.join(ROOT, part.get('res') or os.path.join('src', 'res'), name)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'wb').write(data)
            if name in INCLUDED:
                open(resinc.inc_name(path), 'w').write(INCLUDED[name])
    else:
        return 0
    return len(files)


def included(path):
    """the files a top file INCLUDEs (relative to its folder)"""
    if not os.path.exists(path):
        return set()
    return {os.path.normpath(os.path.join(os.path.dirname(path), m))
            for m in re.findall(r'^\s+INCLUDE\s+"([^"]+)"', open(path).read(), re.M)}


def install_files(files, dest_top):
    """write {path: text}; then delete the files the old top file INCLUDEd that are written no more (and only
    those: a file of the folder this generator does not write stays)"""
    stale = included(dest_top) - {os.path.normpath(p) for p in files}
    for path, text in files.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'w').write(text)
    for path in sorted(stale):
        if os.path.exists(path) and path.endswith('.asm'):
            os.remove(path)
            print(f'removed {os.path.relpath(path, ROOT)} (no module of the .ann now)')


def written_line(part, anns):
    """the top file's second comment line: what it is written from"""
    if part.get('written'):
        return part['written']
    names = ', '.join(os.path.relpath(a, ROOT) for a in anns)
    recorded = bool(part.get('l1')) or any(s.get('l1') for s in part.get('segments') or [])
    if len(anns) > 1:
        return '; Written by kit/mkgame.py from the annotations (%s)%s; edit the annotations,\n; not the .asm.' % (
            names, ' and the recordings' if recorded else '')
    return '; Written by kit/mkgame.py from %s%s; edit %s, not the .asm.' % (
        names, ' and the recordings' if recorded else '', os.path.basename(anns[0]))


def make_part(part, args):
    """One part: the single layout (one .ann, the top file as kit/mkgame.py writes the game's) or the segments
    layout (several .ann / pieces, each at its run address with ORG / DISP, raw lines between). Returns 0 when the
    bytes are the image's"""
    global LO, HI
    mem, original, at = part_image(part)
    top = part.get('top') or part.get('name') or 'game'
    default_work = os.path.join('work', 'mkgame' if part.get('game') else os.path.join('mkpart', top))
    out = os.path.join(ROOT, part.get('work') or default_work)
    if part.get('clean_work', True):
        import shutil
        shutil.rmtree(os.path.join(out, 'res'), ignore_errors=True)
    os.makedirs(out, exist_ok=True)
    device = part.get('device', 'ZXSPECTRUM48')
    built = dict(part.get('built', {}))
    segments = part.get('segments')
    if not segments:
        return single_part(part, args, mem, original, at, top, out, device, built)

    results = []
    for spec in segments:
        if 'lines' in spec:
            results.append(None)
            continue
        seg = Segment(spec, part)
        lo, hi = seg.lo, seg.hi
        LO, HI = seg.run, seg.run + hi - lo
        smem = bytearray(0x10000)
        smem[LO:HI] = original[lo - at:hi - at]
        results.append(generate(seg, bytes(smem), args, out, None if part.get('subdir', True) else top))
        check_witness(seg, part.get('witness_skip', ()), args.fix_witness)
        print(f'{os.path.relpath(seg.ann, ROOT)}{" " + seg.piece if seg.piece else ""}: {results[-1][5]}')
    every_label = set().union(*(r[4] for r in results if r), set(part.get('external', ())),
                              {s['load_label'] for s in segments if 'load_label' in s})
    equ, seen = {}, set()
    for r in filter(None, results):
        for address, (var, size, comment) in r[3].equ.items():
            if var not in every_label and var not in seen:
                equ[address] = (var, size, comment)
                seen.add(var)
    names = [m for r in results if r for m, _ in r[0]]
    stems = [module_file(m, r[3].top) for r in results if r for m, _ in r[0]]
    if len(set(names)) != len(names):
        sys.exit('module names repeat across segments: ' + ', '.join(sorted({n for n in names if names.count(n) > 1})))
    subdir = part.get('subdir', True)
    inc = (top + '/') if subdir else ''
    anns = []
    for s in segments:
        if s.get('ann') and os.path.join(ROOT, s['ann']) not in anns:
            anns.append(os.path.join(ROOT, s['ann']))
    text = '\n'.join(part.get('header') or ['; ' + top]) + '\n'
    text += written_line(part, anns) + '\n\n  DEVICE %s\n' % device
    consts, banks, aliases = [], [], []
    for r in filter(None, results):
        consts += [c for c in r[3].consts if c not in consts]
        banks += [b for b in r[3].banks if b not in banks]
        aliases += [x for x in r[3].aliases if x not in aliases]
    text += constants(consts) + equates(equ, '; Addresses outside this image (@equ in the annotations)') + \
        bank_equates(banks) + alias_equates(aliases)
    if part.get('org_once'):
        text += '\n  ORG $%04X\n' % at
    for spec, result in zip(segments, results):
        lo = hexa(spec['lo'])
        if result is None:
            text += '\n  ORG $%04X\n' % lo + '\n'.join(spec['lines']) + '\n'
            if 'hi' in spec:
                text += '  ASSERT $ == $%04X\n' % hexa(spec['hi'])
            continue
        modules, head, _, ann, _, _ = result
        run_at = hexa(spec['run']) if 'run' in spec else lo
        title = spec.get('title') or (spec['ann'] + (' ' + spec['piece'] if spec.get('piece') else ''))
        text += '\n; %s: $%04X-$%04X%s\n' % (title, lo, hexa(spec['hi']) - 1,
                                             ', run at $%04X' % run_at if run_at != lo else '')
        if not part.get('org_once'):
            text += '  ORG $%04X\n' % lo
        if 'load_label' in spec:
            text += spec['load_label'] + ':\n'
        if run_at != lo:
            text += '  DISP $%04X\n' % run_at
        head = '\n'.join(line for line in head.splitlines() if not re.match(r'^\s+ORG ', line)).strip()
        if head:
            text += head + '\n'
        for module, _ in modules:
            mtitle = ann.module_info.get(module, [''])[0]
            text += '  INCLUDE "%s%s.asm"%s\n' % (inc, module_file(module, ann.top),
                                                ('  ; ' + mtitle) if mtitle else '')
        if run_at != lo:
            text += '  ENT\n'
    binary = os.path.basename(part.get('out') or top + '.bin')
    text += '\n  SAVEBIN "%s",$%04X,%d\n' % (binary, at, len(original))
    os.makedirs(os.path.join(out, top) if subdir else out, exist_ok=True)
    resources = {}
    for r in filter(None, results):
        for module, body in r[0]:
            open(os.path.join(out, inc + module_file(module, r[3].top) + '.asm'), 'w').write(body)
        resources.update(r[2])
    for res, data in resources.items():
        path = os.path.join(out, 'res', res)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(data)
    open(os.path.join(out, top + '.asm'), 'w').write(text)
    if part.get('before_assemble'):
        call_hook(part['before_assemble'], out)
    assemble(part, args, out, top)
    got = open(os.path.join(out, binary), 'rb').read()
    diff = next((i for i in range(len(original)) if i >= len(got) or got[i] != original[i]), None)
    print('assembled: identical to %s' % part['image'] if diff is None else
          'assembled: first difference at $%04X: %02X, original %02X' % (
              at + diff, got[diff] if diff < len(got) else 0, original[diff]))
    if diff is None and args.install:
        dest = os.path.join(ROOT, part['dest'])
        files = {os.path.join(dest, inc + m + '.asm'): open(os.path.join(out, inc + m + '.asm')).read() for m in stems}
        files[os.path.join(dest, top + '.asm')] = text
        install_files(files, os.path.join(dest, top + '.asm'))
        n = install_resources(part, resources, built)
        print(f'installed {os.path.relpath(dest, ROOT)}/{top}.asm, {len(names)} modules, {n} resources')
    return 0 if diff is None else 1


def assemble(part, args, out, top):
    cmd = [args.sjasmplus, '--nologo', '--msg=war'] + ['-I' + os.path.join(ROOT, d) for d in part.get('include', [])]
    run(cmd + ['--lst=%s.lst' % top, top + '.asm'], cwd=out)


WITNESS = re.compile(r'Witness: L1 (\d+) \(([^)]*)\)')


def build_name(build):
    """the short name of a build in a witness line: stage1/c1 -> c1, stage2/rzx04/cap -> rzx04, timer -> timer"""
    parts = build.split('/')
    return parts[1] if len(parts) > 1 else parts[0]


def witness_text(builds, address):
    """'N (names)' of a code entry: the runs of its first instruction summed over the builds {build: runs}, and the
    builds that ran it; names of a numbered family (rzx01 ... rzx32: two or more in the set) as 'rzx xK'"""
    family = {}
    for b in builds:
        m = re.match(r'(.*?)(\d+)$', build_name(b))
        if m:
            family.setdefault(m.group(1), []).append(b)
    singles, groups, total = [], {}, 0
    for b, ran in builds.items():
        n = ran.get(address, 0)
        if not n:
            continue
        total += n
        m = re.match(r'(.*?)(\d+)$', build_name(b))
        if m and len(family[m.group(1)]) > 1:
            groups[m.group(1)] = groups.get(m.group(1), 0) + 1
        else:
            singles.append(build_name(b))
    return total, ', '.join(sorted(singles) + ['%s x%d' % (k, v) for k, v in sorted(groups.items())])


def check_witness(seg, skip=(), fix=False):
    """The "Witness: L1 N (builds)" lines of the .ann's code entries against the recordings: N is the runs of the
    entry's first instruction summed over the segment's builds (the case's read_builds and code_builds, less
    witness_skip), the list the builds that ran it. Prints each stale line; fix: rewrites N and the list in the .ann.
    Returns the number of stale lines"""
    if not seg.ann or not os.path.exists(seg.ann):
        return 0
    work = os.path.join(ROOT, 'work')
    builds = {}
    for path, ran in EXECS.items():
        build = os.path.relpath(os.path.dirname(path), work)
        if build not in skip and any(os.path.abspath(path) == os.path.abspath(s.path) or
                                     ('*' in s.path and fnmatch.fnmatch(path, s.path)) for s in seg.sources):
            builds[build] = ran
    lines = open(seg.ann).read().split('\n')
    entry, stale = None, 0
    for i, line in enumerate(lines):
        text = line.strip()
        if text.startswith('$'):
            m = ANNOTATION.match(text)
            if m and m.group(2):
                entry = (int(m.group(1), 16), m.group(2), m.group(3))
            continue
        if not text.startswith('>') or entry is None or entry[1] != 'c':
            continue

        def sub(w):
            nonlocal stale
            n, names = witness_text(builds, entry[0])
            if (int(w.group(1)), w.group(2)) == (n, names):
                return w.group(0)
            stale += 1
            print('witness: %s:%d $%04X %s: L1 %s (%s), the builds give L1 %d (%s)%s' % (
                os.path.relpath(seg.ann, ROOT), i + 1, entry[0], entry[2] or '', w.group(1), w.group(2), n, names,
                ': rewritten' if fix else ''))
            return 'Witness: L1 %d (%s)' % (n, names)
        lines[i] = WITNESS.sub(sub, line)
    if fix and stale:
        open(seg.ann, 'w').write('\n'.join(lines))
    return stale


def single_part(part, args, mem, original, at, top, out, device, built):
    """the single layout: the image's range lo..hi with one .ann (or one piece)"""
    global LO, HI
    seg = Segment(part, part)
    seg.single = True
    LO = seg.lo if seg.lo is not None else at
    HI = seg.hi if seg.hi is not None else at + len(original)
    seg.run = LO
    if seg.bank is not None and 'bases' not in part and part.get('pages') is None:
        seg.bases = natural_bases([seg.bank], LO)
    result = generate(seg, mem, args, out, top)
    modules, head, resources, ann, _, stats = result
    check_witness(seg, part.get('witness_skip', ()), args.fix_witness)
    if part.get('game'):
        print(f'resources {len(resources)} files, {sum(len(v) for v in resources.values())} bytes')
    print(f'{top}: {stats}')
    for name, body in modules:
        open(os.path.join(out, module_file(name, top) + '.asm'), 'w').write(body)
    text = '\n'.join(part.get('header') or ['; ' + top]) + '\n' + written_line(part, [seg.ann]) + \
        '\n\n  DEVICE %s\n' % device
    if seg.bank is not None and part.get('slot', True):
        text += '  SLOT 3\n  PAGE %s\n' % seg.bank
    text += constants(ann.consts) + equates(ann.equ) + bank_equates(ann.banks) + alias_equates(ann.aliases) + head
    text += ''.join('  INCLUDE "%s.asm"%s\n' % (module_file(name, top), ('  ; ' + ann.module_info[name][0])
                                                if ann.module_info.get(name, [''])[0] else '') for name, _ in modules)
    binary = part.get('bin') or top + '.bin'
    text += '\n  SAVEBIN "%s",$%04X,$%04X\n' % (binary, LO, HI - LO)
    open(os.path.join(out, top + '.asm'), 'w').write(text)
    if part.get('before_assemble'):
        call_hook(part['before_assemble'], out)
    assemble(part, args, out, top)
    got = open(os.path.join(out, binary), 'rb').read()
    diff = next((LO + i for i in range(HI - LO) if i >= len(got) or got[i] != mem[LO + i]), None)
    print(('assembled: identical to the original image' if part.get('game') else 'assembled: identical')
          if diff is None else 'assembled: first difference at $%04X: %02X, image %02X'
          % (diff, got[diff - LO] if diff - LO < len(got) else 0, mem[diff]))
    if diff is None and args.install:
        dest = os.path.join(ROOT, part.get('dest') or os.path.join('src', 'game'))
        prefix = os.path.relpath(os.path.join(ROOT, part['res']), dest) + '/' if part.get('res') else None
        files = {}
        for name in [module_file(n, top) for n, _ in modules] + [top]:
            body = open(os.path.join(out, name + '.asm')).read()
            for res, path in built.items():
                body = body.replace('INCBIN "res/%s"' % res, 'INCBIN "%s"' % path)
            if prefix:
                body = body.replace('INCBIN "res/', 'INCBIN "' + prefix).replace('INCLUDE "res/', 'INCLUDE "' + prefix)
            if part.get('save'):
                body = body.replace('SAVEBIN "%s"' % binary, 'SAVEBIN "%s"' % part['save'])
            files[os.path.join(dest, name + '.asm')] = body
        install_files(files, os.path.join(dest, top + '.asm'))
        n = install_resources(part, resources, built)
        print(f'installed {len(modules) + 1} files in {os.path.relpath(dest, ROOT)}, {n} resources')
    return 0 if diff is None else 1


# ------------------------------------------------------------------------------------------------- the case's game


def load_case(case, config_path=None):
    """case.json (or config_path) of the case: sets ROOT, LO, HI, BASES, READ_BUILDS"""
    global ROOT, LO, HI, BASES, READ_BUILDS
    ROOT = os.path.abspath(case)
    config = json.load(open(config_path or os.path.join(ROOT, 'case.json')))
    LO, HI = int(config['lo'], 16), int(config.get('hi', '10000'), 16)
    BASES = {int(k): int(v, 16) for k, v in config.get('bases', {'5': '4000', '2': '8000', '0': 'C000'}).items()}
    READ_BUILDS = tuple(config.get('read_builds', ()))
    return config


def case_builds(config):
    """the recordings of the case's game: work/<build>/l1.json of read_builds (instructions and data reads) and
    code_builds (instructions only), never every work/*/l1.json"""
    out = [{'path': os.path.join('work', b, 'l1.json'), 'reads': True} for b in config.get('read_builds', ())]
    out += [{'path': os.path.join('work', b, 'l1.json'), 'reads': False} for b in config.get('code_builds', ())]
    return out


def game_part(config, ann):
    """case.json as a part: the 64 K image, lo..hi, into src/game"""
    part = {'game': True, 'image': config['image'], 'at': '0', 'lo': config['lo'], 'hi': config.get('hi', '10000'),
            'bases': config.get('bases', {'5': '4000', '2': '8000', '0': 'C000'}), 'l1': case_builds(config),
            'ann': os.path.relpath(ann, ROOT), 'top': 'game', 'device': config.get('device', 'ZXSPECTRUM48'),
            'header': config.get('header') or ['; The game image $%04X-$%04X.' % (LO, HI - 1)],
            'dest': config.get('dest', os.path.join('src', 'game')), 'clean_work': False}
    if config.get('image_cmd'):
        part['image_cmd'] = config['image_cmd']
    for key in ('work', 'operands', 'res_install', 'mode', 'same_bytes', 'data_entries', 'overwritten',
                'isub_as_written', 'drop_data_refs', 'no_entries', 'entries_in_code', 'witness_skip'):
        if key in config:
            part[key] = config[key]
    return part


def original_image(config):
    """The image as the original's loader leaves it (64K), from case.json"""
    if config.get('image_cmd'):
        run(config['image_cmd'], cwd=ROOT)
    path = os.path.join(ROOT, config['image'])
    mem = open(path, 'rb').read()
    if len(mem) != 0x10000:
        sys.exit(f'{path}: {len(mem)} bytes, not a 64 K image')
    return mem


def cli_part(args):
    """the command line's one image as a part"""
    org = hexa(args.org)
    part = {'image': os.path.relpath(os.path.abspath(args.image), ROOT), 'at': '%04X' % org,
            'ann': os.path.relpath(os.path.abspath(args.ann), ROOT), 'top': args.top,
            'dest': os.path.relpath(os.path.abspath(args.dest), ROOT), 'device': args.device,
            'header': ['; ' + (args.title or args.top)], 'mode': 'blocks' if args.blocks else 'instructions',
            'data_entries': 'stop', 'isub_as_written': True, 'drop_data_refs': True,
            'l1': ([{'path': os.path.relpath(os.path.abspath(p), ROOT)} for p in args.l1] +
                   [{'path': os.path.relpath(os.path.abspath(p), ROOT), 'reads': True} for p in args.l1_reads]),
            'built': dict(b.split('=', 1) for b in args.built)}
    if args.range:
        lo, _, hi = args.range.partition('-')
        part['lo'], part['hi'] = lo, hi
    if args.res:
        part['res'] = os.path.relpath(os.path.abspath(args.res), ROOT)
    if args.page:
        part['pages'] = args.page
    if args.bank is not None:
        part['bank'] = args.bank
    if args.save:
        part['save'] = args.save
    if args.out:
        part['work'] = os.path.relpath(os.path.abspath(args.out), ROOT)
    if args.wide:
        part['operands'] = 'wide'
    if args.narrow:
        part['operands'] = 'narrow'
    return part


def main():
    global ROOT
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--case', default='.', help='the case folder (default: here)')
    p.add_argument('--config', help='the game\'s config instead of CASE/case.json')
    p.add_argument('--part', help='a part file (JSON, docs/ann-format.md 5)')
    p.add_argument('--image', help='one image: its bytes')
    p.add_argument('--org', help='the address of the image\'s first byte')
    p.add_argument('--range', help='LO-HI (hex, HI exclusive): only these addresses of the image')
    p.add_argument('--top', help='the top file\'s name (TOP.asm)')
    p.add_argument('--dest', help='where --install writes the .asm')
    p.add_argument('--res', help='where --install writes the resources (the INCBINs name it relative to --dest)')
    p.add_argument('--l1', action='append', default=[], help='an L1 build whose instructions count')
    p.add_argument('--l1-reads', action='append', default=[], help='an L1 build whose instructions and reads count')
    p.add_argument('--blocks', action='store_true', help='only whole recorded basic blocks with the image\'s bytes')
    p.add_argument('--page', type=int, action='append', help='an L1 page that counts (repeat; default 5, 2, 0)')
    p.add_argument('--bank', type=int, help='the RAM bank the image runs in at $C000 (SLOT 3 / PAGE in the top file)')
    p.add_argument('--built', action='append', default=[], metavar='NAME=PATH',
                   help='the resource NAME is made by the build: INCBIN PATH, not installed')
    p.add_argument('--save', help='the SAVEBIN path of the installed top file')
    p.add_argument('--title', default='', help='the top file\'s first comment line')
    p.add_argument('--device', default='ZXSPECTRUM128')
    p.add_argument('--wide', action='store_true', help='Label+offset for every LD BC,nn into an entry, not only '
                   'the pointers read through (BC)')
    p.add_argument('--narrow', action='store_true', help='no Label+offset for LD BC,nn at all')
    p.add_argument('--venv', help='a virtualenv with SkoolKit (else $SKOOLKIT_VENV, kit/toolpaths.py)')
    p.add_argument('--sjasmplus', help='sjasmplus (else $SJASMPLUS, kit/toolpaths.py)')
    p.add_argument('--out', help='the work folder')
    p.add_argument('--ann', help='the annotations (the game: src/game/game.ann)')
    p.add_argument('--install', action='store_true', help='write the sources when the bytes are the image\'s')
    p.add_argument('--fix-witness', action='store_true', help='rewrite the stale "Witness: L1 N (builds)" lines of '
                   'the .ann from the recordings (mkgame prints them in any case)')
    args = p.parse_args()
    args.venv = toolpaths.skoolkit_venv(args.venv)
    args.sjasmplus = toolpaths.sjasmplus(args.sjasmplus)
    if args.part:
        ROOT = os.path.abspath(args.case)
        part = json.load(open(os.path.join(ROOT, args.part) if not os.path.isabs(args.part) else args.part))
        if args.out:
            part['work'] = os.path.relpath(os.path.abspath(args.out), ROOT)
        part.setdefault('name', os.path.splitext(os.path.basename(args.part))[0])
        return make_part(part, args)
    if args.image:
        ROOT = os.path.abspath(args.case)
        missing = [k for k in ('org', 'ann', 'top', 'dest') if not getattr(args, k)]
        if missing:
            sys.exit('--image needs ' + ', '.join('--' + k for k in missing))
        return make_part(cli_part(args), args)
    config = load_case(args.case, args.config)
    ann = os.path.abspath(args.ann) if args.ann else os.path.join(ROOT, 'src', 'game', 'game.ann')
    part = game_part(config, ann)
    if args.out:
        part['work'] = os.path.relpath(os.path.abspath(args.out), ROOT)
    return make_part(part, args)


if __name__ == '__main__':
    sys.exit(main())
