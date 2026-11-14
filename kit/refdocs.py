#!/usr/bin/env python3
"""Write docs/11-data-reference.md and docs/12-routine-reference.md from the source and the recordings.

    python3 kit/refdocs.py --case CASE

Every entry of the main part (CASE/work/mkgame/<main>.ctl, written by kit/mkgame.py; <main> is case.json "main",
"game" when absent) with its name, title and description from src/<main>/<main>.ann; for code, what the recordings saw it do (the builds of case.json "ref_builds": work/<key>/
l1.json, each its own Runs row, then the case's other recordings: read_builds, code_builds and witness_builds, their
reads and writes from read_builds only; an entry no routine of a recording starts at, entered by a jump, gets the runs
of its first instruction as its witness line counts them): callers, callees, runs, own time, the memory it reads and writes, its ports, and a
link to each of its animations, docs/img/routines/<Label>.gif and <Label>-<what>.gif (kit/routine_anim.py,
kit/memanim.py). For data, the routines that read and write it (the ref builds', the other recordings' with the
first that saw it, and the LD through (nn), or through HL / DE / BC loaded with nn, of the code, named by the label
at or below the instruction), each inner label a row of its own.

Memory ranges name the label at or below their first byte, inner labels included (Label+offset). The interrupt's
acceptance (the IM 2 vector read, the return address pushed), which L1 books to the instruction it interrupted, is
the handler's: the routine the vector leads to (the L1 "interrupt" edge's callee), not the interrupted routine's.

case.json keys read here (beside mkgame.py's):

    "ref_builds": [["p2", "the bot game"], ["game", "the first recording's game window"]],
    "overlay": {"lo": "8000", "hi": "BFFF", "name": "the playfield buffer",
                "why": "laid over the title player and the start-up"},     a buffer laid over code (optional)
    "data_note": "The object records are laid out in [7. Objects](07-objects.md)."   (optional, doc 11)
    "ref_parts": ["src/bank3/bank3.json", ["src/loader/chain.json", "Decryption chain and loader"]]   (optional)
    "ref_load_end": {"stage1/c1": 15505}     (optional) per recording, the frame from which it runs the game's
                               image: a routine first run before it ran during the load (a loader at the game's
                               addresses), its writes are the blocks landing and are no entry's "Written by"
    "ref_skip_moves": true     (optional; a part file's own key for a part) doc 11's readers and writers leave out
                               the block moves: an L1 loop that copies (a read and a write stride of step 1 or -1
                               over as many bytes, 16 or more: LDIR, LDDR, an in-place decryption; not an LDIR
                               fill, its destination the source a byte on) or loads (a write
                               stride of step 1 or -1 alone, whose store wrote code a recording later ran: a tape
                               loader, a depacker of code). Their bytes are moved, not used (Myth's resident: the
                               SpeedLock chain's decryption over it). Doc 12's Reads and Writes keep them

Memory ranges outside the image that are not the screen (below the game's image: "system" without a name; outside a
part's image: its numbers) are named by the view's .ann @equ lines that cover them (NAME, NAME+offset), Myth's
`$5B00` PlayBuffer of the stages and TextBuffer of the front.

ref_parts: after the game's sections, one section a part file of the single layout, from its .ann, its image and its
recordings: the part's "ref_builds" (else the case's) first, then its other l1 sources ("other_builds" overrides
them), each counted inside the part's window only; a "mode": "blocks" part counts an instruction only where its bytes
are the part's. A part of segments (kit/mkgame.py's "segments") gets one section a segment with an .ann ("Title:
segment title"), at its run addresses, from the segment's work files (kit/mkgame.py names them after the .ann and
the piece, with "-RUN" when two segments share both) and the segment's l1 sources.
"""
import bisect
import json
import os
import re
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mkgame  # noqa: E402
import check_docs  # noqa: E402

ROOT = None
JUMPED = False  # a Runs row gave the first-instruction runs of an entry no routine starts at (doc 12's header says so)
BUILDS = []
LO, HI = 0, 0x10000
# A buffer laid over code once play starts: the accesses there of code outside it are the buffer's, not the entries
# of the code it covers. None: no overlay
BUFFER_LO, BUFFER_HI = 0x10000, 0x10000
OVERLAY_NAME, OVERLAY_WHY = '', ''
# the case's main part (case.json "main", "game" when absent) and how the documents call it
MAIN, WHOLE, WHOLE_IMAGE = 'game', 'the game', 'the game image'


def in_buffer(a):
    return BUFFER_LO <= a <= BUFFER_HI


def outside_buffer(rs):
    """Ranges with the buffer cut out, and the buffer's part as one range (or None)"""
    rest, inside = [], []
    for lo, hi, n in rs:
        if hi < BUFFER_LO or lo > BUFFER_HI:
            rest.append((lo, hi, n))
            continue
        if lo < BUFFER_LO:
            rest.append((lo, BUFFER_LO - 1, n))
        if hi > BUFFER_HI:
            rest.append((BUFFER_HI + 1, hi, n))
        inside.append((max(lo, BUFFER_LO), min(hi, BUFFER_HI)))
    return rest, ((min(x[0] for x in inside), max(x[1] for x in inside)) if inside else None)


# how a caller reaches its callee, when it is no CALL: a tail jump, or running on into it (no call at all)
KIND_NOTE = {'tail': ' (tail)', 'falls-into': ' (falls into)'}


def entries_of(ctl):
    """[(address, kind, label, title)] in address order, and {address: label} of every label (inner ones too)"""
    out, label = [], {}
    for line in open(ctl):
        m = re.match(r'@ \$([0-9A-F]{4}) label=(\w+)', line)
        if m:
            label[int(m.group(1), 16)] = m.group(2)
            continue
        m = re.match(r'([cb]) \$([0-9A-F]{4}) (.*)', line)
        if m:
            a = int(m.group(2), 16)
            out.append((a, m.group(1), label.get(a, '$%04X' % a), m.group(3).strip()))
    return out, label


# use flags of L1's byte_use (unreal-ng l1model.h): the stack's own accesses
STACK_READ, STACK_WRITE, CODE = 1 << 2, 1 << 3, 1 << 6 | 1 << 7


DOCS = {}  # l1.json path -> its document (a recording serves the game and every part)


class Build:
    def __init__(self, key, full=True):
        self.key = key
        path = self.path = os.path.join(ROOT, 'work', key, 'l1.json')
        if path not in DOCS:
            DOCS[path] = json.load(open(path))
        doc = DOCS[path]
        self.total = doc['replay']['tstates']
        self.frames = (doc['replay']['first_frame'], doc['replay']['last_frame'])
        self.routines = [r for r in doc['routines'] if r['page'] in mkgame.BASES]
        self.index = {i: r for i, r in enumerate(doc['routines'])}
        self.calls = doc['calls']
        # the interrupted routines: routine index -> the handlers (routine indexes) the interrupt entered from it
        self.interrupted = {}
        for c in self.calls:
            if c['kind'] == 'interrupt':
                self.interrupted.setdefault(c['caller'], set()).add(c['callee'])
        # the stack's slots, pushed and popped and never run (PUSH / CALL / an interrupt, POP / RET): where an
        # interrupt's return address goes. A byte only pushed to (an SP walk over data), code, or neither is no slot
        self.stack = set()
        if full and self.interrupted:
            for page, offset, length, flags, *_ in doc.get('byte_use', ()):
                if flags & STACK_READ and flags & STACK_WRITE and not flags & CODE and page in mkgame.BASES:
                    base = mkgame.BASES[page]
                    self.stack.update(range(base + offset, base + offset + length))


def ranges(items):
    return [(int(x['from'][1:], 16), int(x['to'][1:], 16), x['bytes']) for x in items if x['page'] in mkgame.BASES]


def split(rs, take):
    """(ranges without the bytes for which take(address) is true, the ranges of those bytes)"""
    kept, taken = [], []
    for lo, hi, _ in rs:
        if not any(take(a) for a in range(lo, hi + 1)):
            kept.append((lo, hi, hi - lo + 1))
            continue
        for a in range(lo, hi + 1):
            out = taken if take(a) else kept
            if out and out[-1][1] == a - 1:
                out[-1] = (out[-1][0], a, out[-1][2] + 1)
            else:
                out.append((a, a, 1))
    return kept, taken


# a block move's stride covers at least this many bytes in one range (ref_skip_moves)
MOVE_MIN = 16


def block_moves(b):
    """ref_skip_moves: {L1 routine index: {'reads': [(lo, hi)], 'writes': [...]}}, the bytes the routine's block
    moves read and wrote. A move is an L1 loop's stride of step 1 or -1 with a range of MOVE_MIN bytes or more: a read
    and a write stride over as many such bytes (a copy: LDIR, LDDR, LD A,(HL) / LD (DE),A; or an in-place change, a
    decryption; not a fill, the destination its source shifted by a byte), or a write stride with no such read
    stride whose store wrote code a recording later ran (an L1 arrival's writer: a loader, a depacker of code). The
    ranges go to the routines whose blocks hold the stride's instruction"""
    if hasattr(b, 'moves'):
        return b.moves
    doc = DOCS[b.path]
    holds = {}  # (page, instruction address) -> the L1 routines whose blocks hold it
    for blk in doc.get('blocks', ()):
        for a in range(int(blk['start'][1:], 16), int(blk['end'][1:], 16) + 1):
            holds.setdefault((blk['page'], a), set()).add(blk['routine'])
    writers = {int(x['writer'][1:], 16) for x in doc.get('arrivals', ()) if x.get('writer')}

    def bigs(s):
        return [(int(x['from'][1:], 16), int(x['to'][1:], 16)) for x in s['ranges']
                if x['bytes'] >= MOVE_MIN and x['page'] in mkgame.BASES]

    def big(s):
        return sum(hi - lo + 1 for lo, hi in bigs(s))

    def copy(r, w):
        """a read and a write stride over as many bytes, not a fill: an LDIR whose destination is its source one
        byte on (the same bytes shifted) clears a buffer, its bytes are used"""
        if big(r) != big(w):
            return False
        return not any(rl != wl and rl <= wh and wl <= rh for (rl, rh), (wl, wh) in zip(bigs(r), bigs(w)))
    b.moves = {}
    for loop in doc.get('loops', ()):
        strides = [s for s in loop['strides'] if abs(s['stride']) == 1 and s.get('constant', True) and big(s)]
        reads = [s for s in strides if s['access'] == 'read']
        writes = [s for s in strides if s['access'] == 'write']
        moved = [s for s in reads if any(copy(s, w) for w in writes)] + \
            [w for w in writes if any(copy(s, w) for s in reads)]
        if not reads:
            moved += [w for w in writes if int(w['at'][1:], 16) in writers]
        for st in moved:
            kind = 'reads' if st['access'] == 'read' else 'writes'
            for i in holds.get((loop['page'], int(st['at'][1:], 16)), ()):
                got = b.moves.setdefault(i, {'reads': [], 'writes': []})[kind]
                got += [(int(x['from'][1:], 16), int(x['to'][1:], 16)) for x in st['ranges']
                        if x['page'] in mkgame.BASES]
    return b.moves


def cut(rs, out):
    """the ranges rs (lo, hi, n) without the bytes of out [(lo, hi)]"""
    for olo, ohi in out:
        kept = []
        for lo, hi, _ in rs:
            if hi < olo or lo > ohi:
                kept.append((lo, hi, hi - lo + 1))
                continue
            if lo < olo:
                kept.append((lo, olo - 1, olo - lo))
            if hi > ohi:
                kept.append((ohi + 1, hi, hi - ohi))
        rs = kept
    return rs


# LD through memory: LD r,(nn) reads, LD (nn),r writes (1 byte with A, 2 with a register pair)
LD_READ = re.compile(r'^LD (A|BC|DE|HL|SP|IX|IY),\(\$([0-9A-F]{4})\)$')
LD_WRITE = re.compile(r'^LD \(\$([0-9A-F]{4})\),(A|BC|DE|HL|SP|IX|IY)$')
# through a register pair loaded with nn: LD HL,nn ... LD (HL),n in one block
LD_PAIR = re.compile(r'^LD (HL|DE|BC),\$([0-9A-F]{4})$')
PAIR_PARTS = {'HL': ('HL', 'H', 'L'), 'DE': ('DE', 'D', 'E'), 'BC': ('BC', 'B', 'C')}
BLOCK_END = re.compile(r'^(CALL|RST|RET|RETI|RETN|JP|JR|DJNZ|HALT)\b')
CLOBBER_ALL = re.compile(r'^(EXX|LDI|LDIR|LDD|LDDR|CPI|CPIR|CPD|CPDR|INI|INIR|IND|INDR|OUTI|OTIR|OUTD|OTDR)$')


def pair_access(text, pair):
    """what an instruction does through (pair): 'reads', 'writes', 'both' or None"""
    ref = '(%s)' % pair
    if ref not in text:
        return None
    op, _, args = text.partition(' ')
    first = args.split(',')[0]
    if op == 'LD':
        return 'writes' if first == ref else 'reads'
    if op in ('INC', 'DEC', 'SET', 'RES', 'RLC', 'RRC', 'RL', 'RR', 'SLA', 'SRA', 'SLL', 'SRL', 'RLD', 'RRD'):
        return 'both'
    return 'reads'  # ADD / ADC / SUB / SBC / AND / OR / XOR / CP / BIT, JP (HL) never reaches here (block end)


def clobbers(text, pair):
    """the instruction changes the pair otherwise than INC / DEC of the whole pair"""
    op, _, args = text.partition(' ')
    if CLOBBER_ALL.match(text) or (op == 'EX' and pair in ('HL', 'DE') and args in ('DE,HL', '(SP),HL')):
        return True
    dest = args.split(',')[0] if args else ''
    if op in ('LD', 'POP', 'INC', 'DEC', 'ADD', 'ADC', 'SBC', 'RL', 'RR', 'RLC', 'RRC', 'SLA', 'SRA', 'SLL', 'SRL',
              'IN') or (op in ('SET', 'RES') and ',' in args):
        if op in ('SET', 'RES'):
            dest = args.split(',')[1]
        return dest in PAIR_PARTS[pair]
    return False


def static_accesses(skool):
    """[(instruction address, 'reads' | 'writes', lo, hi)] of the LDs through (nn) in mkgame's skool file, and of
    the accesses through (HL), (DE) or (BC) after LD HL,nn (DE, BC) in the same block: no jump target, branch or
    call between, the pair not changed but by INC / DEC"""
    out = []
    pairs = {}
    for line in open(skool):
        if line.startswith('@') or line.startswith(';'):
            continue
        m = re.match(r'^([ c*])\$([0-9A-F]{4}) ([^;]*?)\s*(?:;.*)?$', line.rstrip('\n'))
        if not m:
            pairs = {}  # an entry's end, data
            continue
        if m.group(1) != ' ':
            pairs = {}  # an entry's or a jump target's first instruction: what came before is not known here
        at, text = int(m.group(2), 16), m.group(3)
        r, w = LD_READ.match(text), LD_WRITE.match(text)
        if r:
            a = int(r.group(2), 16)
            out.append((at, 'reads', a, a + (r.group(1) != 'A')))
        elif w:
            a = int(w.group(1), 16)
            out.append((at, 'writes', a, a + (w.group(2) != 'A')))
        for pair, a in list(pairs.items()):
            kind = pair_access(text, pair)
            if kind:
                for k in (('reads', 'writes') if kind == 'both' else (kind,)):
                    out.append((at, k, a, a))
        load = LD_PAIR.match(text)
        for pair in list(pairs):
            if text in ('INC ' + pair, 'DEC ' + pair):
                pairs[pair] = (pairs[pair] + (1 if text.startswith('INC') else -1)) & 0xFFFF
            elif clobbers(text, pair):
                del pairs[pair]
        if load:
            pairs[load.group(1)] = int(load.group(2), 16)
        if BLOCK_END.match(text):
            pairs = {}
    return out


def md(text):
    """Prose for GitHub: hex addresses in code spans (a bare $..$ pair is math there)"""
    parts = re.split(r'(`[^`]*`)', text)
    return ''.join(p if p.startswith('`') else re.sub(r'(\$[0-9A-Fa-f]{1,4}(?:-\$[0-9A-Fa-f]{1,4})?)', r'`\1`', p)
                   for p in parts)


def hexa(text):
    return int(str(text).lstrip('$').replace('0x', ''), 16)


def plain_span(lo, hi):
    """an address range outside every named image: its numbers (the screen says so)"""
    text = '`$%04X`' % lo if lo == hi else '`$%04X`-`$%04X`' % (lo, hi)
    return text + (' (screen)' if 0x4000 <= lo < 0x5B00 else '')


class View:
    """One image whose entries refdocs writes: the case's game, or a part of the medium (case.json "ref_parts": a part
    file of kit/mkgame.py, single layout, whose work folder holds <main>.ctl, <main>.skool and <main>-image.bin)

        game          True for the game
        title         the part's heading ("Bank 3"); its modules' headings are "TITLE: MODULE"
        lo, hi        the image's addresses; bases the L1 pages that count ({page: address of its byte 0})
        ref_builds    [(key, text)]: each its own Runs row (a part: its "ref_builds", else case.json's)
        read_builds   the other recordings whose reads and writes count; code_builds: their calls only (a part: its
                      L1 sources, those with "reads" or in case.json's read_builds the first; or its "other_builds",
                      calls only)
        windows       {key: (lo, hi)}: only the routines entered there count (a part's windowed source)
        blocks        a part in "mode": "blocks" (or same_bytes): only the routines whose first instruction, as the
                      recording ran it, has the image's bytes count (another program ran there earlier in the load)
        outside       how a range outside the image is named (a bank: the game's labels below $C000)
    """

    def __init__(self, **kw):
        self.__dict__.update(kw)

    @staticmethod
    def game(config):
        work = os.path.join(ROOT, 'work', 'mkgame')
        main = mkgame.main_name(config)
        return View(game=True, name=main, title=WHOLE, lo=mkgame.LO, hi=mkgame.HI, bases=dict(mkgame.BASES),
                    pages=(0, 2, 5), ctl=os.path.join(work, main + '.ctl'), skool=os.path.join(work, main + '.skool'),
                    image_path=os.path.join(work, main + '-image.bin'),
                    ann_path=os.path.join(ROOT, 'src', main, main + '.ann'), piece=None, top=main, src='src/' + main,
                    ref_builds=[tuple(b) for b in config.get('ref_builds', [])],
                    read_builds=tuple(config.get('read_builds', ())),
                    code_builds=tuple(dict.fromkeys(list(config.get('code_builds', ())) +
                                                    list(config.get('witness_builds', ())))),
                    windows={}, outside=None, h2='##', blocks=False, options=mkgame.Segment(config, config),
                    skip_moves=bool(config.get('ref_skip_moves')))

    @staticmethod
    def part(spec, config, game):
        """a part of case.json "ref_parts": "src/PART.json" or ["src/PART.json", "Title"]: [View], one for a part
        of the single layout, one a segment (with an .ann) for a part of segments"""
        path, title = (spec, None) if isinstance(spec, str) else (spec[0], spec[1])
        part = json.load(open(os.path.join(ROOT, path)))
        name = os.path.splitext(os.path.basename(path))[0]
        top = part.get('top') or part.get('name') or name
        data = open(os.path.join(ROOT, part['image']), 'rb').read() if os.path.exists(os.path.join(ROOT, part['image'])) \
            else None
        if data is None:
            sys.exit(f'{path}: no image {part["image"]} (run kit/mkgame.py --part {path} first)')
        at = hexa(part['at']) if 'at' in part else (0 if len(data) == 0x10000 else hexa(part['org']))
        work = os.path.join(ROOT, part.get('work') or os.path.join('work', 'mkpart', top))
        if not part.get('segments'):
            lo = hexa(part['lo']) if 'lo' in part else at
            hi = hexa(part['hi']) if 'hi' in part else at + len(data)
            mkgame.LO, mkgame.HI = lo, hi
            seg = mkgame.Segment(part, part)
            v = View.of_segment(seg, part, config, game, path, title or (f'Bank {seg.bank}' if seg.bank is not None
                                                                         else top), name, top, lo, hi, work,
                                mkgame.main_name(config), part['ann'], part.get('piece'), top)
            return [v]
        views = []
        segs = mkgame.segment_tags(part['segments'], part)
        for spec_s, seg in zip(part['segments'], segs):
            if seg is None or not seg.ann:
                continue
            lo, hi = seg.run, seg.run + seg.hi - seg.lo
            mkgame.LO, mkgame.HI = lo, hi
            v = View.of_segment(seg, part, config, game, path, f'{title or top}: {seg.title or seg.tag()}', name,
                                top, lo, hi, work, seg.tag(), spec_s['ann'], seg.piece,
                                None if part.get('subdir', True) else top)
            v.segment = (seg.lo, seg.hi, seg.run)
            v.part_title = title or top
            views.append(v)
        return views

    @staticmethod
    def of_segment(seg, part, config, game, path, title, name, top, lo, hi, work, tag, ann, piece, ann_top):
        """the View of one run of mkgame (a part of the single layout, or one segment of a part): its work files
        TAG.ctl, TAG.skool, TAG-image.bin; its recordings the segment's l1 sources"""
        bases = seg.bases
        if seg.bank is not None and 'bases' not in part and part.get('pages') is None:
            bases = mkgame.natural_bases([seg.bank], lo)
        ref = [tuple(b) for b in part.get('ref_builds', config.get('ref_builds', []))]
        keys = {k for k, _ in ref}
        read, code, windows = [], [], {}
        for src in seg.sources:
            if src.format != 'l1' or '*' in src.path:
                continue
            key = os.path.relpath(os.path.dirname(src.path), os.path.join(ROOT, 'work'))
            if key in keys or key in read or key in code:
                continue
            (read if src.reads or key in config.get('read_builds', ()) else code).append(key)
            if src.lo is not None or src.hi is not None:
                windows[key] = (src.lo if src.lo is not None else 0, src.hi if src.hi is not None else 0x10000)
        if 'other_builds' in part:
            read, code, windows = [], list(part['other_builds']), {}
        else:  # the witness-only recordings: their runs and calls, as code_builds
            code += [k for k in spec_get(seg, part, 'witness_builds') if k not in keys and k not in read + code]
        v = View(game=False, name=name, title=title,
                 path=path, header=part.get('header') or [], lo=lo, hi=hi, bases=bases, pages=tuple(bases),
                 ctl=os.path.join(work, tag + '.ctl'), skool=os.path.join(work, tag + '.skool'),
                 image_path=os.path.join(work, tag + '-image.bin'), ann_path=os.path.join(ROOT, ann),
                 piece=piece, top=top, ann_top=ann_top, src=part.get('dest') or os.path.dirname(ann),
                 ref_builds=ref, read_builds=tuple(read), code_builds=tuple(code), windows=windows,
                 outside=game_namer(game, lo) if seg.bank is not None else plain_span, h2='###',
                 blocks=seg.mode == 'blocks' or seg.same_bytes, segment=None, part_title=title, options=seg,
                 skip_moves=bool(part.get('ref_skip_moves')))
        if not os.path.exists(v.ctl):
            sys.exit(f'run kit/mkgame.py --part {path} first (it writes {os.path.relpath(v.ctl, ROOT)})')
        return v

    def load_ann(self):
        if self.game:
            return mkgame.Annotations(self.ann_path)
        import contextlib
        import io
        ann = mkgame.Annotations(self.ann_path, self.piece, self.ann_top)
        with contextlib.redirect_stdout(io.StringIO()):
            mkgame.clip_to_image(ann)  # an .ann shared by several parts: this image's entries
        self.module_top = ann.top
        return ann

    def heading(self, module):
        return module if self.game else f'{self.title}: {module}'

    def slug(self, module):
        return module.lower() if self.game else check_docs.github_slug(self.heading(module))

    def module_path(self, module):
        return f'{self.src}/{module}.asm' if self.game else f'{self.src}/{mkgame.module_file(module, self.module_top)}.asm'

    def in_window(self, key, a):
        """a counts for the build key: inside its window, outside its overwritten [LO, HI, BUILDS] ranges"""
        w = self.windows.get(key)
        if w is not None and not w[0] <= a < w[1]:
            return False
        return not any(lo <= a < hi for lo, hi in self.build_options(key)[1])

    def build_options(self, key):
        """(same_bytes, skip ranges) of a build by the per-build forms of same_bytes and overwritten"""
        if not hasattr(self, '_options'):
            self._options = {}
        if key not in self._options:
            self._options[key] = self.options.build_options(os.path.join(ROOT, 'work', key, 'l1.json')) \
                if getattr(self, 'options', None) else (False, [])
        return self._options[key]

    def intro(self, doc):
        """the part's heading and the paragraph under it"""
        about = ' '.join(h.lstrip(';').strip() for h in self.header)
        refs = ', '.join(f'`work/{k}` ({t})' for k, t in self.ref_builds)
        others = list(self.read_builds) + list(self.code_builds)
        text = (md(about) + ' ' if about else '') + \
            f'Its entries are `{self.src}/<module>.asm`, written from `{os.path.relpath(self.ann_path, ROOT)}` by ' \
            f'`kit/mkgame.py --part {self.path}`; ' + (
                f'the recordings: {refs}' + (', and ' + ', '.join(
                    f'`work/{k}`' + (' (`$%04X`-`$%04X`)' % (self.windows[k][0], self.windows[k][1] - 1)
                                     if k in self.windows else '') for k in others) if others else '')
                if doc == 12 else 'the readers and writers from ' + ', '.join(
                    [f'`work/{k}`' for k, _ in self.ref_builds] + [f'`work/{k}`' for k in self.read_builds])) + '.'
        if self.skip_moves and doc == 11:
            text = text[:-1] + ', block copies and loads left out (`ref_skip_moves`).'
        if self.segment:
            lo, hi, run = self.segment
            text += ' This section is the segment `$%04X-$%04X` of the image' % (lo, hi - 1) + (
                ', run at `$%04X-$%04X`' % (run, run + hi - lo - 1) if run != lo else '') + '.'
            # a segment's intro is longer: keep each code span on one line (check_docs reads prose by line)
            text = re.sub(r'`[^`]*`', lambda m: m.group(0).replace(' ', '\x00'), text)
            return ['', f'## {md(self.title)} (`{self.path}`)', ''] + [
                line.replace('\x00', ' ') for line in textwrap.wrap(text, 116)] + ['']
        return ['', f'## {md(self.title)} (`{self.path}`)', ''] + textwrap.wrap(text, 116) + ['']


def spec_get(seg, part, key):
    """a segment's key, else its part's (a list)"""
    return list(seg.spec.get(key, part.get(key, ())))


def game_namer(game, lo_part):
    """a range outside a bank part, by the game's labels below the bank's window (the resident pages), else its
    numbers"""
    entries, labels = entries_of(game.ctl)
    starts = [e[0] for e in entries]
    lstarts = sorted(a for a in labels if game.lo <= a < lo_part)

    def name(a):
        i = bisect.bisect_right(starts, a) - 1
        if i < 0 or not game.lo <= a < lo_part:
            return None
        e = entries[i]
        k = bisect.bisect_right(lstarts, a) - 1
        at = lstarts[k] if k >= 0 and lstarts[k] >= e[0] else e[0]
        label = labels.get(at, e[2])
        return label if at == a else '%s+%d' % (label, a - at)

    def outside(lo, hi):
        n = name(lo)
        if n is None:
            return plain_span(lo, hi)
        text = '`$%04X`' % lo if lo == hi else '`$%04X`-`$%04X`' % (lo, hi)
        return text + ' (`%s`)' % n
    return outside


def main():
    global ROOT, BUILDS, LO, HI, BUFFER_LO, BUFFER_HI, OVERLAY_NAME, OVERLAY_WHY, MAIN, WHOLE, WHOLE_IMAGE
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('--case', required=True)
    p.add_argument('--docs', help='where 11-data-reference.md and 12-routine-reference.md go (CASE/docs)')
    args = p.parse_args()
    config = mkgame.load_case(args.case)
    ROOT, LO, HI = mkgame.ROOT, mkgame.LO, mkgame.HI
    BUILDS = [tuple(b) for b in config.get('ref_builds', [])]
    if not BUILDS:
        sys.exit('case.json: no "ref_builds"')
    overlay = config.get('overlay')
    if overlay:
        BUFFER_LO, BUFFER_HI = int(overlay['lo'], 16), int(overlay['hi'], 16)
        OVERLAY_NAME, OVERLAY_WHY = overlay.get('name', 'the buffer'), overlay.get('why', 'laid over code')
    docs = args.docs or os.path.join(ROOT, 'docs')
    os.makedirs(docs, exist_ok=True)
    MAIN = mkgame.main_name(config)
    if MAIN != 'game':
        WHOLE, WHOLE_IMAGE = 'the main program', 'the main program\'s image'
    ctl = os.path.join(ROOT, 'work', 'mkgame', MAIN + '.ctl')
    if not os.path.exists(ctl):
        sys.exit(f'run kit/mkgame.py first (it writes work/mkgame/{MAIN}.ctl)')
    game = View.game(config)
    head12, head11, doc12, doc11 = reference(game, config)
    parts = [v for spec in config.get('ref_parts', ()) for v in View.part(spec, config, game)]
    if parts:
        note = textwrap.wrap('The parts of the medium (`case.json` `ref_parts`: ' + ', '.join(
            md(t) for t in dict.fromkeys(x.part_title for x in parts)) + ') follow ' + WHOLE + ', each under its own '
            'heading' + (' (a part of segments one a segment)' if any(x.segment for x in parts) else '') +
            ' with its modules, its source, its annotations and its recordings.', 116)
        head12[-2:-1] = [head12[-2]] + note
        head11[-2:-1] = [head11[-2]] + note
    for part in parts:
        _, _, p12, p11 = reference(part, config)
        doc12 += part.intro(12) + p12
        doc11 += part.intro(11) + p11
    if JUMPED:  # only then: the header of a case without such an entry stays as it was
        k = head12.index('recordings ran gives their calls.')
        head12[k:k + 1] = textwrap.wrap(
            'recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a '
            'table jump or by running on: L1 books its time to the routine it runs in) gives the runs of its first '
            'instruction, as its witness line counts them.', 116)
    open(os.path.join(docs, '12-routine-reference.md'), 'w').write('\n'.join(head12 + doc12))
    open(os.path.join(docs, '11-data-reference.md'), 'w').write('\n'.join(head11 + doc11))


def reference(v, config):
    """doc 12's and doc 11's header lines and sections of one view (the game, or a part of the medium)"""
    global BUILDS, LO, HI
    LO, HI = v.lo, v.hi
    mkgame.LO, mkgame.HI, mkgame.BASES = v.lo, v.hi, v.bases
    BUILDS = v.ref_builds
    ctl, ann = v.ctl, v.load_ann()
    entries, labels = entries_of(ctl)
    starts = [e[0] for e in entries]
    ends = {e[0]: (entries[i + 1][0] if i + 1 < len(entries) else HI) - 1 for i, e in enumerate(entries)}
    entry_at = {e[0]: e for e in entries}
    modules = sorted(ann.modules)
    mstarts = [m[0] for m in modules]
    # every label of the image, inner ones too, in address order
    lstarts = sorted(a for a in labels if LO <= a < HI)
    # the image (the vector's words): mkgame's copy from LO, else case.json's 64 K image; none in a scratch case
    image, image_at = b'', LO
    image_path = v.image_path
    if os.path.exists(image_path):
        image = open(image_path, 'rb').read()
    elif v.game and config.get('image') and os.path.exists(os.path.join(ROOT, config['image'])):
        image, image_at = open(os.path.join(ROOT, config['image']), 'rb').read(), 0

    def word(a):
        """the image's word at a (None outside it)"""
        k = a - image_at
        return image[k] | image[k + 1] << 8 if 0 <= k and k + 1 < len(image) and LO <= a < HI else None

    def same(b, page, a):
        """a part in blocks mode (a loader's piece, where other code ran at the same addresses earlier in the load):
        the routine's first instruction as the recording ran it has the image's bytes; always true otherwise"""
        if not (v.blocks or v.build_options(b.key)[0]) or not LO <= a < HI:
            return True
        if not hasattr(b, 'codes'):
            b.codes = {(x[1], int(x[0][1:], 16)): bytes.fromhex(x[2]) for x in DOCS[b.path]['instructions']}
        raw = b.codes.get((page, a))
        k = a - image_at
        return raw is not None and image[k:k + len(raw)] == raw

    def owner(a):
        i = bisect.bisect_right(starts, a) - 1
        return entries[i] if i >= 0 and LO <= a < HI else None

    def module(a):
        i = bisect.bisect_right(mstarts, a) - 1
        return modules[i][1] if i >= 0 else 'buffers'

    def inner_name(a):
        """the label at or below a inside a's entry, inner labels included: Label or Label+offset"""
        e = owner(a)
        if not e:
            return None
        i = bisect.bisect_right(lstarts, a) - 1
        at = lstarts[i] if i >= 0 and lstarts[i] >= e[0] else e[0]
        name = labels.get(at, e[2])
        return name if at == a else '%s+%d' % (name, a - at)

    # an '@equ ... at' name holds only its instructions' operands: no range is named after it
    equs = sorted((a, name, size) for a, (name, size, _) in ann.equ.items() if a not in ann.equ_at)

    def equ_span(lo, hi):
        """A range outside the image, not the screen, by the .ann's @equ lines: the one that holds its first byte
        (NAME+offset), then those that start inside it; None when none does"""
        if 0x4000 <= lo < 0x5B00:
            return None
        names = []
        held = [e for e in equs if e[0] <= lo < e[0] + e[2]]
        if held:
            a, name, _ = held[-1]
            names.append(name if a == lo else '%s+%d' % (name, lo - a))
        names += [name for a, name, _ in equs if lo < a <= hi and name not in names]
        if not names:
            return None
        shown = ', '.join('`%s`' % n for n in names[:4]) + (' and %d more' % (len(names) - 4) if len(names) > 4 else '')
        return ('`$%04X`' % lo if lo == hi else '`$%04X`-`$%04X`' % (lo, hi)) + ' (%s)' % shown

    def span(lo, hi):
        """A memory range as the labels it covers: the one at or below its first byte (inner labels included,
        Label+offset), then the entries it runs into, or within one entry its inner labels"""
        if v.outside and (hi < LO or lo >= HI):
            text = v.outside(lo, hi)
            return equ_span(lo, hi) or text if text == plain_span(lo, hi) else text
        if hi < LO and equ_span(lo, hi):
            return equ_span(lo, hi)
        if hi < LO:
            area = 'screen' if 0x4000 <= lo < 0x5B00 else 'system'
            return ('`$%04X`' % lo if lo == hi else '`$%04X`-`$%04X`' % (lo, hi)) + ' (%s)' % area
        names = []
        a = max(lo, LO)
        first = owner(a)
        if first:
            names.append(inner_name(a))
            if ends[first[0]] >= hi:  # within one entry: its inner labels after the first byte
                i = bisect.bisect_right(lstarts, a)
                while i < len(lstarts) and lstarts[i] <= hi:
                    names.append(labels[lstarts[i]])
                    i += 1
            a = ends[first[0]] + 1
        while a <= hi:
            e = owner(a)
            if not e:  # past the image: the work space above it (its EQUs)
                names.append('work space $%04X+' % a)
                break
            names.append(e[2])
            a = ends[e[0]] + 1
        shown = ', '.join('`%s`' % n for n in names[:4]) + (' and %d more' % (len(names) - 4) if len(names) > 4 else '')
        return ('`$%04X`' % lo if lo == hi else '`$%04X`-`$%04X`' % (lo, hi)) + ' (%s)' % shown

    def new_seen():
        return {'callers': {}, 'callees': {}, 'runs': {}, 'reads': [], 'writes': [], 'ports_in': set(),
                'ports_out': set(), 'interrupts': {}, 'by': {}, 'entered': {}}

    # Every recording of the case: the ref builds (each its own Runs row), then read_builds (their reads and
    # writes count too) and code_builds (runs, calls and callers only: their reads may be a depacker's input)
    ref_keys = [k for k, _ in BUILDS]
    read_keys = set(ref_keys) | set(v.read_builds)
    every = [k for k in dict.fromkeys(ref_keys + list(v.read_builds) + list(v.code_builds))
             if k in ref_keys or os.path.exists(os.path.join(ROOT, 'work', k, 'l1.json'))]
    builds = {}  # the ref builds (their totals)
    # Per routine entry of the game: what each build saw
    seen = {}
    users = {}  # data entry or inner label -> {'reads': set((name, source)), 'writes': ...}
    for key in every:
        b = Build(key)
        if key in ref_keys:
            builds[key] = b
        # case.json "ref_load_end" (the game only): the frame from which this recording runs the game's image; a
        # routine first run before it ran during the load (a loader at the game's addresses): its writes are the
        # blocks landing, not the writes of the entry that holds its address
        load_end = config.get('ref_load_end', {}).get(key) if v.game else None
        data = key in read_keys
        moves = block_moves(b) if v.skip_moves and data else {}
        # the interrupt's acceptance, booked by L1 to the interrupted instruction: the vector read (a word that
        # holds the handler's address) and the return address pushed (bytes the stack uses) go to the handler
        moved = {}  # handler routine index -> {'reads': [...], 'writes': [...]}
        # the vector: words holding an IM 2 handler's address in the page I selects, the page where the most
        # interrupted routines read such a word (a graphic's bytes may equal the address elsewhere)
        handlers_at = {int(b.index[h]['entry'][1:], 16) for hs in b.interrupted.values() for h in hs} - {0x38, 0x66}
        pages = {}
        for i in b.interrupted:
            hit = set()
            for lo, hi, _ in ranges(b.index[i]['profile']['reads']):
                hit.update(x >> 8 for x in range(lo, hi) if word(x) in handlers_at)
            for page in hit:
                pages[page] = pages.get(page, 0) + 1
        vector_page = max(pages, key=lambda k: (pages[k], k)) if pages else None
        # the word pairs at least half the routines an IM 2 interrupt entered (3 or more) read: the vector without
        # the image, or where the game fills its table at run time (Terramex's GameEntry: the image's words there
        # are not the handler's address, a stray word elsewhere may be)
        common = set()
        if handlers_at:
            pairs = {}
            # the routines an IM 2 handler interrupted (an IM 1 interrupt at $0038 reads no vector)
            im2 = [i for i, hs in b.interrupted.items()
                   if {int(b.index[h]['entry'][1:], 16) for h in hs} - {0x38, 0x66}]
            for i in im2:
                read = {x for lo, hi, _ in ranges(b.index[i]['profile']['reads']) for x in range(lo, hi + 1)}
                for x in read:
                    if x + 1 in read:
                        pairs[x] = pairs.get(x, 0) + 1
            need = max(3, (len(im2) + 1) // 2)
            # with the image, only a pair at $xxFF (I * 256 + the idle bus's $FF): a variable a few interrupted
            # routines share is no vector (Tujad's TeleportColumn, TeleportRow)
            common = {x for x, n in pairs.items() if n >= need and (not image or x & 0xFF == 0xFF)}
        for i, handlers in b.interrupted.items():
            r = b.index[i]
            entries_ = {int(b.index[h]['entry'][1:], 16) for h in handlers}
            p = r['profile']

            def vector(a, entries_=entries_):
                if not entries_ - {0x38, 0x66}:
                    return False
                if a in common or a - 1 in common:
                    return True
                if not image:
                    return False
                return any(word(x) in entries_ and x >> 8 == vector_page for x in (a, a - 1)
                           if word(x) is not None)
            reads, vread = split(ranges(p['reads']), vector)
            writes, pushed = split(ranges(p['writes']), b.stack.__contains__)
            r['_reads'], r['_writes'] = reads, writes
            to = min(handlers)
            m = moved.setdefault(to, {'reads': [], 'writes': []})
            m['reads'] += vread
            m['writes'] += pushed
        for i, r in b.index.items():
            if r['page'] not in v.pages:
                continue
            a = int(r['entry'][1:], 16)
            if not v.in_window(key, a) or not same(b, r['page'], a):
                continue
            e = owner(a)
            if not e or e[1] != 'c':
                continue
            s = seen.setdefault(e[0], new_seen())
            p = r['profile']
            runs = s['runs'].setdefault(key, [0, 0])
            runs[0] += p['entries'] if a == e[0] else 0
            runs[1] += p['tstates']
            if data:
                got = s['by'].setdefault(key, {'reads': [], 'writes': []})
                for kind in ('reads', 'writes'):
                    if kind == 'writes' and load_end is not None and p['first_frame'] < load_end:
                        continue
                    rs = r.get('_' + kind, ranges(p[kind])) + moved.get(i, {}).get(kind, [])
                    s[kind] += rs
                    # ref_skip_moves: the bytes the routine's block moves copied or loaded are no entry's use
                    got[kind] += cut(rs, moves[i][kind]) if i in moves else rs
            s['ports_in'].update(x if isinstance(x, str) else x.get('port', str(x)) for x in p['ports_in'])
            s['ports_out'].update(x if isinstance(x, str) else x.get('port', str(x)) for x in p['ports_out'])
        # a code entry no routine of this recording starts at (entered by a jump, a table jump or by running on: L1
        # books its time to the routine it runs in): the runs of its first instruction, as its witness line counts them
        # (one an L1 routine starts at with no entries counted, an "indirect" one, is such an entry too)
        started = {int(r['entry'][1:], 16) for r in b.index.values() if r['page'] in v.pages and
                   r['profile']['entries']}
        execs = {}
        for z80, page, _code, _kind, n, *_ in DOCS[b.path]['instructions']:
            if page in v.pages:
                execs[(page, int(z80[1:], 16))] = execs.get((page, int(z80[1:], 16)), 0) + n
        for a, kind, _label, _title in entries:
            if kind != 'c' or a in started or not v.in_window(key, a):
                continue
            n = sum(execs.get((page, a), 0) for page in v.pages if same(b, page, a))
            if n:
                seen.setdefault(a, new_seen())['entered'][key] = n
        for c in b.calls:
            ca, ce = b.index.get(c['caller']), b.index.get(c['callee'])
            if not ca or not ce or ca['page'] not in v.pages or ce['page'] not in v.pages:
                continue
            if not v.in_window(key, int(ca['entry'][1:], 16)) or not v.in_window(key, int(ce['entry'][1:], 16)) or \
                    not same(b, ca['page'], int(ca['entry'][1:], 16)) or not same(b, ce['page'], int(ce['entry'][1:], 16)):
                continue
            oa, oe = owner(int(ca['entry'][1:], 16)), owner(int(ce['entry'][1:], 16))
            if not oa or not oe:
                continue
            if c['kind'] == 'interrupt':  # no call: the handler is entered by the interrupt, in these routines
                if oa[0] != oe[0]:
                    seen.setdefault(oa[0], new_seen())
                    seen.setdefault(oe[0], new_seen())
                    seen[oe[0]]['interrupts'][oa[0]] = seen[oe[0]]['interrupts'].get(oa[0], 0) + c['count']
                continue
            # the caller is the entry that holds the call's site, not the L1 routine's entry: an L1 routine runs on
            # through the entries its code falls into (GameEntry, NewGame, ... MainLoop) and through its tail jumps,
            # so its entry would be named for a call that MainLoop makes
            sites = [owner(int(x[1:], 16)) for x in c.get('sites', ())]
            for oa in {x for x in sites if x} or {oa}:
                if oa[0] == oe[0]:
                    continue
                seen.setdefault(oa[0], new_seen())
                seen.setdefault(oe[0], new_seen())
                seen[oa[0]]['callees'][oe[0]] = c['kind']
                seen[oe[0]]['callers'][oa[0]] = c['kind']

    def touch(kind, lo, hi, name, static=None):
        """name reads / writes lo..hi: each data entry and inner label it covers; static: None (a ref build saw
        it), the build key of another recording that did, or ('code', the routine) (the code says so)"""
        x = max(lo, LO)
        while x <= hi and x < HI:
            e = owner(x)
            if e[1] == 'b':
                users.setdefault(e[0], {'reads': set(), 'writes': set()})[kind].add((name, static))
                i = bisect.bisect_right(lstarts, x) - 1
                at = lstarts[i] if i >= 0 and lstarts[i] > e[0] else None
                if at is not None:
                    users.setdefault(at, {'reads': set(), 'writes': set()})[kind].add((name, static))
                k = bisect.bisect_right(lstarts, hi)
                inner = [y for y in lstarts[bisect.bisect_right(lstarts, x):k] if y <= ends[e[0]]]
                for y in inner:
                    users.setdefault(y, {'reads': set(), 'writes': set()})[kind].add((name, static))
            x = ends[e[0]] + 1

    for a, s in seen.items():
        name = owner(a)[2]
        for key, got in s['by'].items():
            for kind in ('reads', 'writes'):
                rs = got[kind] if in_buffer(a) else outside_buffer(got[kind])[0]
                for lo, hi, _ in rs:
                    touch(kind, lo, hi, name, None if key in ref_keys else key)
    # the code's LD through (nn) and through HL / DE / BC loaded with nn: a reader or writer the recordings may not
    # have seen, named by the label at or below the instruction (a label inside the routine, WalkIntoFire, is its own)
    skool = v.skool
    if os.path.exists(skool):
        for at, kind, lo, hi in static_accesses(skool):
            e = owner(at)
            if e and e[1] == 'c' and owner(lo):
                i = bisect.bisect_right(lstarts, at) - 1
                touch(kind, lo, hi, labels[lstarts[i]] if i >= 0 and lstarts[i] >= e[0] else e[2], ('code', e[2]))

    # The runs the case's other recordings (read_builds, code_builds) saw
    other = {a: {k: v for k, v in s['runs'].items() if k not in ref_keys} for a, s in seen.items()}
    # the first-instruction runs of the entries no routine starts at (entered by a jump), the other recordings'
    other_entered = {a: {k: n for k, n in s['entered'].items() if k not in ref_keys} for a, s in seen.items()}

    def merged(rs):
        rs = sorted((lo, hi) for lo, hi, _ in rs)
        out = []
        for lo, hi in rs:
            if out and lo <= out[-1][1] + 16:
                out[-1][1] = max(out[-1][1], hi)
            else:
                out.append([lo, hi])
        return out

    def description(a):
        return '\n\n'.join(md(t) for t in ann.descriptions.get(a, []))

    def animations(label):
        """docs/img/routines/<label>.gif, then <label>-<what>.gif: a second animation of one routine (another
        document's) has a file of its own"""
        folder = os.path.join(ROOT, 'docs', 'img', 'routines')
        names = sorted(n for n in os.listdir(folder) if n.startswith(label + '-') and n.endswith('.gif')) \
            if os.path.isdir(folder) else []
        return ([label + '.gif'] if os.path.exists(os.path.join(folder, label + '.gif')) else []) + names

    ref_names = ', '.join(f'`{k}`' for k, _ in BUILDS)
    # Doc 12: the routines (the header is main's)
    head12 = ['# 12. Routine reference', '',
           f'Every code entry of {WHOLE}, in address order by module (`src/{MAIN}/<module>.asm`). The name, the title and',
           f'the description are the source\'s (`src/{MAIN}/{MAIN}.ann`); the rest is what the recordings saw: '
           + ', '.join(f'`work/{k}` ({t})' for k, t in BUILDS) + (
               ', and the case\'s other recordings (`case.json` `read_builds`, `code_builds`' + (
                   ', `witness_builds`' if any(k in every for k in config.get('witness_builds', ())) else '') +
               '): their calls in a Runs row'
               ' of their own, their callers, callees, reads and writes (`read_builds` only) with the others\''
               if len(every) > len(ref_keys) else '') + '. They are local, not in the repository; the WALKTHROUGH\'s commands rebuild them.',
           'Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share',
           'of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)',
           'and the entries they cover'
           + (f'; in `${BUFFER_LO:04X}-${BUFFER_HI:04X}` the accesses of code outside it are {OVERLAY_NAME}\'s, {OVERLAY_WHY}'
              if OVERLAY_NAME else '') + '. The interrupt\'s acceptance (the vector read, the return address pushed) is',
           'the handler\'s, not the interrupted routine\'s. An entry no recording reached says so; one the case\'s other',
           'recordings ran gives their calls.',
           f'Written by `kit/refdocs.py`; edit `src/{MAIN}/{MAIN}.ann`, then run `kit/mkgame.py --case . --install`',
           '(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.', '']
    out = []
    out.append('| Module | Entries | Code entries |')
    out.append('| --- | --- | --- |')
    # a module may hold several stretches of addresses (@module NAME again): one row and one section each module
    order = list(dict.fromkeys(name for _, name in modules))
    stretches = {}
    for k, (start, name) in enumerate(modules):
        end = modules[k + 1][0] if k + 1 < len(modules) else HI
        stretches.setdefault(name, []).append((start, end))
    for name in order:
        inside = [e for e in entries if any(s <= e[0] < t for s, t in stretches[name])]
        # a module with code has its heading here; one of data only, in doc 11 (GitHub's slug: lower case)
        if any(e[1] == 'c' for e in inside):
            link = f'[`{name}`](#{v.slug(name)})'
        elif any(e[1] == 'b' for e in inside):
            link = f'[`{name}`](11-data-reference.md#{v.slug(name)})'
        else:
            link = f'`{name}`'
        where = ', '.join(f'`${s:04X}`-`${t - 1:04X}`' for s, t in stretches[name])
        out.append(f'| {link} | {where} | '
                   f'{sum(1 for e in inside if e[1] == "c")} of {len(inside)} |')
    out.append('')
    rank = {name: k for k, name in enumerate(order)}

    def by_module(kind):
        """the entries of a kind, module by module (a module's stretches together), in address order"""
        picked = [e for e in entries if e[1] == kind]
        return sorted(picked, key=lambda e: (rank.get(module(e[0]), -1), e[0]))

    current = None
    for a, kind, label, title in by_module('c'):
        m = module(a)
        if m != current:
            current = m
            out += [f'{v.h2} {v.heading(m)}', '', f'`{v.module_path(m)}`', '']
        out += [f'{v.h2}# `{label}` (`${a:04X}`)', '', f'**{md(title)}**', '']
        if description(a):
            out += [description(a), '']
        for gif in animations(label):
            what = gif[len(label) + 1:-4].replace('-', ' ')
            out += [f'[Animation: `{label}` at work{", " + what if what else ""}](img/routines/{gif})', '']
        s = seen.get(a)
        rows = []

        def others(runs, entered=None):
            calls = sum(n for n, _ in runs.values())
            if calls:  # the builds that called it (one that only ran into it from another entry's code is left out)
                runs = {k: v for k, v in runs.items() if v[0]}
            elif entered:  # entered by a jump in every one: the runs of its first instruction
                global JUMPED
                JUMPED = True
                n = sum(entered.values())
                ranked = sorted(entered.items(), key=lambda x: (-x[1], x[0]))
                shown = ', '.join(f'`{k}` {c:,}' for k, c in ranked[:3]) + \
                    (f' and {len(ranked) - 3} more' if len(ranked) > 3 else '')
                return f'{n:,} run{"" if n == 1 else "s"} of its first instruction, entered by a jump', shown
            ranked = sorted(runs.items(), key=lambda x: (-x[1][0], -x[1][1], x[0]))
            called = f'{calls:,} call{"" if calls == 1 else "s"}' if calls else 'run into, not called'
            shown = ', '.join(f'`{k}`' + (f' {n:,}' if calls else '') for k, (n, _) in ranked[:3]) + \
                (f' and {len(ranked) - 3} more' if len(ranked) > 3 else '')
            return called, shown

        def jumped(n, t=None, total=None):
            """an entry no routine of the recording starts at: its first instruction's runs (and the t-states of
            the L1 routines that start inside it)"""
            global JUMPED
            JUMPED = True
            text = f'{n:,} run{"" if n == 1 else "s"} of its first instruction (entered by a jump or by running on, ' \
                   f'no routine of its own in the L1)'
            return text + (f', {t:,} t-states own ({100 * t / total:.2f} %)' if t else '')
        hit = (lambda k: k in s['runs'] or k in s['entered']) if s else None
        if not s:
            rows.append(('Runs', 'not reached in the recordings'))
        else:
            if not s['runs'] and not s['entered']:  # known only by a call site in it: run inside another entry
                rows.append(('Runs', 'ran within another entry\'s routine (reached by a jump or by running on, its '
                                     'calls below), no runs of its own counted'))
            elif not any(hit(k) for k in ref_keys):
                called, shown = others(other.get(a, {}), other_entered.get(a))
                rows.append(('Runs', f'not reached in {ref_names}; in the other recordings {called} ({shown})'))
            for key, text in BUILDS:
                calls, t = s['runs'].get(key, (0, 0))
                if not calls and s['entered'].get(key):
                    rows.append((f'Runs ({text})', jumped(s['entered'][key], t, builds[key].total)))
                elif key in s['runs']:
                    share = 100 * t / builds[key].total
                    called = f'{calls:,} call{"" if calls == 1 else "s"}' if calls else 'run into, not called'
                    rows.append((f'Runs ({text})', f'{called}, {t:,} t-states own ({share:.2f} %)'))
            if any(hit(k) for k in ref_keys) and (other.get(a) or other_entered.get(a)):
                called, shown = others(other.get(a, {}), other_entered.get(a))
                rows.append(('Runs (the other recordings)', f'{called} ({shown})'))
            if s['interrupts']:
                n = sum(s['interrupts'].values())
                rows.append(('Entered by', f'the interrupt, {n:,} time{"" if n == 1 else "s"} in '
                                           f'{len(s["interrupts"])} routine{"" if len(s["interrupts"]) == 1 else "s"}'))
            if s['callers']:
                rows.append(('Called from', ', '.join(f'`{owner(c)[2]}`' + KIND_NOTE.get(k, '')
                                                       for c, k in sorted(s['callers'].items()))))
            if s['callees']:
                rows.append(('Calls', ', '.join(f'`{owner(c)[2]}`' + KIND_NOTE.get(k, '')
                                                for c, k in sorted(s['callees'].items()))))
            for kind in ('reads', 'writes'):
                rs, buffer = (s[kind], None) if in_buffer(a) else outside_buffer(s[kind])
                spans = merged(rs)
                if buffer:
                    spans = sorted(spans + [list(buffer)])
                if spans:
                    shown = [('`$%04X`-`$%04X` (%s)' % (x[0], x[1], OVERLAY_NAME)) if buffer and tuple(x) == buffer
                             else span(*x) for x in spans[:6]]
                    more = f'; {len(spans) - 6} more ranges' if len(spans) > 6 else ''
                    rows.append(('Reads' if kind == 'reads' else 'Writes', '; '.join(shown) + more))
            if s['ports_in']:
                rows.append(('Ports in', ', '.join(f'`{p}`' for p in sorted(s['ports_in']))))
            if s['ports_out']:
                rows.append(('Ports out', ', '.join(f'`{p}`' for p in sorted(s['ports_out']))))
        out += ['| | |', '| --- | --- |'] + [f'| {k} | {v} |' for k, v in rows] + ['']
    doc12 = out

    # Doc 11: the data (the header is main's)
    head11 = ['# 11. Data reference', '',
           f'Every data entry of {WHOLE_IMAGE} `${LO:04X}`-`${HI - 1:04X}`, in address order by module (`src/{MAIN}/<module>.asm`):',
           'tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under',
           'its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,',
           'of the whole entry\'s ("17 of 34"). The name, the title and the description are the',
           f'source\'s (`src/{MAIN}/{MAIN}.ann`); the readers and writers are the routines the recordings saw touch it',
           '(' + ', '.join(f'`work/{k}`' for k, _ in BUILDS) + ', local and not in the repository'
           + (f'; {OVERLAY_NAME}\'s accesses are not counted as theirs' if OVERLAY_NAME else '')
           + ('; block copies and loads left out, `ref_skip_moves`' if v.skip_moves else '') + ')'
           + (', then those only the case\'s other recordings (`read_builds`) saw, with the first of them in brackets'
              if len(read_keys & set(every)) > len(ref_keys) else '') + ', and, marked',
           '"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE`'
           ' or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.'
           + (' ' + config['data_note'] if config.get('data_note') else ''),
           'Written by `kit/refdocs.py`.', '']
    out = []
    current = None
    rows = []

    def flush():
        nonlocal rows
        if rows:
            out.extend(['| Address | Name | Bytes | What | Read by | Written by |',
                        '| --- | --- | --- | --- | --- | --- |'] + rows + [''])
            rows = []

    def fmt(found):
        """the ref builds' names, then the other recordings' (with the first build that saw it), then the code's
        (marked; not when a recording already names the routine it lies in)"""
        run = {n for n, source in found if source is None}
        seen_in = {}
        for n, source in found:
            if isinstance(source, str) and n not in run:
                seen_in.setdefault(n, []).append(source)
        order = {k: i for i, k in enumerate(every)}
        names = [f'`{n}`' for n in sorted(run)] + \
            [f'`{n}` (`{min(seen_in[n], key=order.get)}`)' for n in sorted(seen_in)] + \
            [f'`{n}` (code)' for n in sorted({n for n, source in found if isinstance(source, tuple) and
                                              source[1] not in run and source[1] not in seen_in} - run - set(seen_in))]
        return ', '.join(names[:5]) + (f' +{len(names) - 5}' if len(names) > 5 else '') if names else '-'

    nothing = {'reads': set(), 'writes': set()}
    for a, kind, label, title in by_module('b'):
        m = module(a)
        if m != current:
            flush()
            current = m
            out += [f'{v.h2} {v.heading(m)}', '']
        u = users.get(a, nothing)
        inner = [x for x in lstarts if a < x <= ends[a]]
        # the entry's own bytes, up to its first inner label, of the whole entry's (JumpFrames 17 of 34, JumpRise
        # the other 17 on its own row)
        size = f'{inner[0] - a} of {ends[a] - a + 1}' if inner else ends[a] - a + 1
        what = md(title).replace('|', '\\|')
        if description(a):
            what += '. ' + description(a).replace('\n\n', ' ').replace('|', '\\|')
        rows.append(f'| `${a:04X}` | `{label}` | {size} | {what} | {fmt(u["reads"])} | {fmt(u["writes"])} |')
        for k, x in enumerate(inner):
            u = users.get(x, nothing)
            nxt = inner[k + 1] if k + 1 < len(inner) else ends[a] + 1
            comment = md((ann.inline.get(x, (None, None))[1] or '').replace('|', '\\|')) or '-'
            rows.append(f'| `${x:04X}` | `{labels[x]}` (`{label}`+{x - a}) | {nxt - x} | {comment} | '
                        f'{fmt(u["reads"])} | {fmt(u["writes"])} |')
    flush()
    print(f'{v.name}: routines {sum(1 for e in entries if e[1] == "c")}, '
          f'data entries {sum(1 for e in entries if e[1] == "b")}')
    return head12, head11, doc12, out


if __name__ == '__main__':
    main()
