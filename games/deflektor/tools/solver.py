#!/usr/bin/env python3
"""The level solver of tools/play_levels.py: which mirror to turn to which angle next, judged by the game's own beam
trace. The 64 K state read from the running game is copied, a mirror set to a trial angle in LevelGrid, and TraceBeam
`$8ED6` run on the copy in SkoolKit's simulator from the beam's start (`$8376`-`$8378`, as MainLoop sets it); what
the trace did to the copy is the answer: the cells (`$40`) it hit (they turn to explosions), the receiver reached
(LevelDone `$8ED2`), a mine (BeamOnMine `$8ED4`), the beam back in the laser or 40 steps long (BeamInLaser `$8ED5`).

Grid: cell (row r, column c) at `$FD23 + 17 r + c`, 9 rows of 15 cells; mirrors `$01-$10` (16 angles; Right on the
cell with fire held adds 1, Left subtracts 1, TurnMirror `$995E`); bit 7: an element that turns by itself.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tapesim  # noqa: E402,F401  (re-runs the caller under the SkoolKit venv when needed)
from skoolkit.simulator import Simulator  # noqa: E402
try:
    from skoolkit.csimulator import CSimulator
except ImportError:  # pragma: no cover
    CSimulator = None

GRID, ROWS, COLS, STRIDE = 0xFD23, 9, 15, 17
TRACE = 0x8ED6
START_X, START_Y, START_DIR = 0x8376, 0x8377, 0x8378
BANK, CELLS_LEFT = 0x8381, 0x8380
LEVEL_DONE, LIFE_LOST, ON_MINE, IN_LASER = 0x8ED2, 0x8ED3, 0x8ED4, 0x8ED5
BEAM_DIR, BEAM_X, BEAM_Y = 0x8ECB, 0x8ECD, 0x8ECE
CELL = 0x40
SLOTS = 0x81B8
SEED = 0x8E32


def cell_addr(r, c):
    return GRID + STRIDE * r + c


def mirrors(mem):
    """The turnable mirrors: (r, c, angle 1-16)"""
    out = []
    for r in range(ROWS):
        for c in range(COLS):
            v = mem[cell_addr(r, c)]
            if 1 <= v <= 0x10:
                out.append((r, c, v))
    return out


def cells(mem):
    return {(r, c) for r in range(ROWS) for c in range(COLS) if mem[cell_addr(r, c)] == CELL}


def slots(mem):
    """The cells in the explosion slots `$81B8` (7 x 4 bytes: grid address high, low, y, x): BeamBurn's hits"""
    out = set()
    for i in range(7):
        a = SLOTS + 4 * i
        if mem[a]:
            g = (mem[a] << 8 | mem[a + 1]) - GRID
            out.add((g // STRIDE, g % STRIDE))
    return out


CHAR_MAP, CELL_TABLE = 0xE000, 0x8200


def render(m):
    """RenderGrid `$8960`'s first half: every cell's four character codes from CellTable `$8200` + 4 x code (bit 7
    cleared) into CharMap `$E000`, the cell's top-left character at row 2r + 1, column 2c + 1. TraceBeam reads the
    character map, not the grid, so a trial angle counts only once the map is redrawn."""
    for r in range(ROWS):
        for c in range(COLS):
            t = CELL_TABLE + 4 * (m[cell_addr(r, c)] & 0x7F)
            a = CHAR_MAP + 32 * (2 * r + 1) + 2 * c + 1
            m[a], m[a + 1], m[a + 32], m[a + 33] = m[t], m[t + 1], m[t + 2], m[t + 3]


DRAW_MARKS = 0xE300


def trace(mem, changes=()):
    """Run TraceBeam on a copy of @p mem with @p changes [(r, c, code)]: (cells hit, done, mine, laser, steps)"""
    return trace_full(mem, changes)[:5]


_BASE = {'src': None}


def _base(mem):
    """The state prepared once per read: a copy with the character map rendered, the marks and the flags cleared, the
    beam at the laser's start; and one simulator kept for all trials (its memory put back before each)"""
    if _BASE['src'] is not None and _BASE['src'] == mem:
        return _BASE
    m = bytearray(mem)
    render(m)
    m[DRAW_MARKS:DRAW_MARKS + 0x280] = bytes(0x280)
    m[BEAM_DIR] = m[START_DIR]
    m[BEAM_X] = m[START_X]
    m[BEAM_Y] = m[START_Y]
    for a in (LEVEL_DONE, LIFE_LOST, ON_MINE, IN_LASER):
        m[a] = 0
    m[0x5F00] = m[0x5F01] = 0
    _BASE.update(src=bytes(mem), m=bytes(m), slots=slots(m), cells=[(r, c) for r, c, _v in mirrors(m)],
                 rot=[(r, c) for r, c, _v in turning(m)],
                 sim=CSimulator(bytearray(m), {'PC': TRACE, 'SP': 0x5F00}) if CSimulator else None)
    return _BASE


def trace_full(mem, changes=()):
    """trace() and the mirrors the beam met: those with a character the trace marked (DrawMarks `$E300`), and where
    the beam ended (BeamX, BeamY)"""
    if mem[START_DIR] == 0xFF:
        return set(), False, False, False, 0, [], (0, 0), []
    base = _base(mem)
    sim = base['sim']
    if sim is None:
        m = bytearray(base['m'])
    else:
        m = sim.memory
        m[:] = base['m']
    for r, c, v in changes:
        if r == 'seed':
            m[SEED] = c & 0xFF
            m[SEED + 1] = c >> 8
        else:
            m[cell_addr(r, c)] = v
            t = CELL_TABLE + 4 * (v & 0x7F)
            a = CHAR_MAP + 32 * (2 * r + 1) + 2 * c + 1
            m[a], m[a + 1], m[a + 32], m[a + 33] = m[t], m[t + 1], m[t + 2], m[t + 3]
    if sim is not None:
        regs = sim.registers
        regs[24] = TRACE
        regs[12] = 0x5F00
        sim.run(TRACE, 0)
    else:
        sim2 = Simulator(m, {'PC': TRACE, 'SP': 0x5F00})
        n = 0
        while sim2.registers[24] != 0 and n < 2000000:
            sim2.opcodes[m[sim2.registers[24]]]()
            n += 1
    hit = slots(m) - base['slots']
    met = []
    for r, c in base['cells']:
        a = DRAW_MARKS + 32 * (2 * r + 1) + 2 * c + 1
        if m[a] or m[a + 1] or m[a + 32] or m[a + 33]:
            met.append((r, c, m[cell_addr(r, c)]))
    touched = []
    for r, c in base['rot']:
        a = DRAW_MARKS + 32 * (2 * r + 1) + 2 * c + 1
        if m[a] or m[a + 1] or m[a + 32] or m[a + 33]:
            touched.append((r, c, m[cell_addr(r, c)]))
    return hit, bool(m[LEVEL_DONE]), bool(m[ON_MINE]), bool(m[IN_LASER]), m[0x8EBF], met, (m[BEAM_X], m[BEAM_Y]), \
        touched


def turn_path(cur, target):
    """The angles passed on the shorter way from @p cur to @p target and the key: ('R' or 'L', [angles])"""
    up = (target - cur) % 16
    down = (cur - target) % 16
    if up <= down:
        return 'R', [((cur - 1 + k) % 16) + 1 for k in range(1, up + 1)]
    return 'L', [((cur - 1 - k) % 16) + 1 for k in range(1, down + 1)]


def cycle(code):
    """The codes an element that turns by itself passes through (bit 7 kept): a mirror's 16 angles, a cyan or a
    yellow polariser's 8 (RenderGrid `$8960`, `$89B1`); [] for anything else"""
    v = code & 0x7F
    for lo, hi in ((0x01, 0x10), (0x11, 0x18), (0x19, 0x20)):
        if lo <= v <= hi:
            return [0x80 | x for x in range(lo, hi + 1)]
    return []


def turning(mem):
    """The elements that turn by themselves (bit 7: a mirror or a polariser): (r, c, code)"""
    out = []
    for r in range(ROWS):
        for c in range(COLS):
            v = mem[cell_addr(r, c)]
            if v & 0x80 and cycle(v):
                out.append((r, c, v))
    return out


def plan(mem, cursor, want_done=False):
    """The next moves: [(r, c, target angle, key)] or None. Cells first; with none left (or @p want_done) the
    receiver. Tried in order: one mirror, two mirrors, then the same with one self-turning element at any of its 16
    angles (it gets there by itself: the bot waits), so a cell reached only past a turning element counts too."""
    ms = mirrors(mem)
    rot = turning(mem)
    cx, cy = cursor
    left = cells(mem)

    seeds = [None]

    def score(changes):
        good, bad = 0, False
        for sd in seeds:
            ch = changes if sd is None else changes + [('seed', sd, 0)]
            hit, done, mine, laser, _steps = trace(mem, ch)
            g = (1 if done else 0) if (want_done or not left) else len(hit)
            good = max(good, g)
            bad = bad or ((mine or laser) and sd is None)
        return good, bad

    def score_rot(changes):
        best = 0
        for r, c, v in rot:
            for b in cycle(v):
                g, _bad = score(changes + [(r, c, b)])
                best = max(best, g)
        return best

    def path_safe(r, c, cur, a):
        for x in turn_path(cur, a)[1][:-1]:
            _h, _d, mine, laser, _s = trace(mem, [(r, c, x)])
            if mine or laser:
                return False
        return True

    def search(with_rot):
        best = None
        for r, c, v in ms:
            for a in range(1, 17):
                if a == v:
                    continue
                good, bad = score([(r, c, a)])
                if bad:
                    continue
                if with_rot and good <= 0:
                    good = score_rot([(r, c, a)])
                if good <= 0:
                    continue
                kp = turn_path(v, a)
                cost = max(abs(c - cx), abs(r - cy)) + len(kp[1]) + (0 if path_safe(r, c, v, a) else 30)
                key = (-good, cost)
                if best is None or key < best[0]:
                    best = (key, [(r, c, a, kp[0])])
        if best is not None or with_rot:
            return None if best is None else best[1]
        for i, (r1, c1, v1) in enumerate(ms):
            for r2, c2, v2 in ms[i + 1:]:
                for a in range(1, 17):
                    if a == v1:
                        continue
                    for b in range(1, 17):
                        if b == v2:
                            continue
                        ch = [(r1, c1, a), (r2, c2, b)]
                        good, bad = score(ch)
                        if bad:
                            continue
                        if with_rot and good <= 0:
                            if not rot:
                                continue
                            good = score_rot(ch)
                        if good <= 0:
                            continue
                        cost = max(abs(c1 - cx), abs(r1 - cy)) + len(turn_path(v1, a)[1]) + \
                            max(abs(c2 - c1), abs(r2 - r1)) + len(turn_path(v2, b)[1])
                        key = (-good, cost)
                        if best is None or key < best[0]:
                            best = (key, [(r1, c1, a, turn_path(v1, a)[0]), (r2, c2, b, turn_path(v2, b)[0])])
        return None if best is None else best[1]

    def guided(depth, base=(), first=1):
        """Follow the beam: try each mirror it meets at every angle, then the mirrors on the new path, to @p depth
        changes; every prefix must be safe too (the moves are made in this order)."""
        best = [None]
        seen = {}

        def go(changes, met, d):
            done_set = {(r, c) for r, c, _a in changes}
            for r, c, v in met:
                if (r, c) in done_set:
                    continue
                for a in range(1, 17):
                    if a == v:
                        continue
                    ch = changes + [(r, c, a)]
                    hit, done, mine, laser, _s, met2, end, touched = trace_full(mem, list(base) + ch)
                    if mine or laser:
                        continue
                    g = (1 if done else 0) if (want_done or not left) else len(hit)
                    wait = 0
                    if g <= 0 and touched:      # the beam passes a turning element: some of its angles may do
                        for r2, c2, v2 in touched:
                            for b2 in cycle(v2):
                                if b2 == v2:
                                    continue
                                h2, d2, _m2, _l2, *_x = trace_full(mem, list(base) + ch + [(r2, c2, b2)])
                                g2 = (1 if d2 else 0) if (want_done or not left) else len(h2)
                                if g2 > g:
                                    g, wait = g2, 8
                    if g > 0:
                        cost = wait
                        px, py = cx, cy
                        for rr, cc, aa in ch:
                            v0 = mem[cell_addr(rr, cc)]
                            cost += max(abs(cc - px), abs(rr - py)) + len(turn_path(v0, aa)[1])
                            px, py = cc, rr
                        if best[0] is None or (len(ch), -g) <= best[0][0][:2]:
                            pre = []
                            for rr, cc, aa in ch:
                                for x in turn_path(mem[cell_addr(rr, cc)], aa)[1][:-1]:
                                    _h, _d, mn, ls, _s = trace(mem, pre + [(rr, cc, x)])
                                    if mn or ls:
                                        cost += 30
                                pre.append((rr, cc, aa))
                        key = (len(ch), -g, cost)
                        if best[0] is None or key < best[0][0]:
                            best[0] = (key, [(rr, cc, aa, turn_path(mem[cell_addr(rr, cc)], aa)[0]) for rr, cc, aa in ch])
                    elif d > 1:
                        sig = (tuple((rr, cc) for rr, cc, _v in met2), end, frozenset((rr, cc) for rr, cc, _a in ch))
                        if seen.get(sig, 0) >= d - 1:
                            continue      # the same beam with the same mirrors left to turn: searched already
                        seen[sig] = d - 1
                        go(ch, met2, d - 1)

        met0 = trace_full(mem, list(base))[5]
        for dd in range(first, depth + 1):
            seen.clear()
            go([], met0, dd)
            if best[0] is not None:
                return best[0][1]
        return None

    if rot and score_rot([]) > 0:
        return []              # the mirrors as they are, once a turning element comes round: wait
    bases = [[(r, c, b)] for r, c, v in rot for b in cycle(v) if b != v]
    p = None
    # up to 3 moves, then 4 (a beam that passes a turning element counts the angles it comes round to)
    for depth, with_base in ((3, False), (4, False)):
        if with_base:
            for bs in bases:
                p = guided(depth, bs, depth)
                if p is not None:
                    break
        else:
            p = guided(depth, (), depth if depth == 4 else 1)
        if p is not None:
            break
    if p is None:
        p = search(False)
    if p is None and rot:
        if score_rot([]) > 0:
            return []          # the current mirrors do: wait for the turning element
        p = search(True)
    if p is None and any(mem[cell_addr(r, c)] == 0x42 for r in range(ROWS) for c in range(COLS)):
        seeds[:] = [None] + [(0x1234 * k + 0x0F0F) & 0xFFFF for k in range(1, 6)]   # the prism's random turns
        if score([])[0] > 0:
            return []          # the current mirrors do, on some of the prism's turns: wait
        p = search(False)
    return p
