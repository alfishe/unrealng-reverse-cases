#!/usr/bin/env python3
"""Every Lenslok challenge Elite can set, from the game's own code run in skoolkit's Z80 simulator.

    python3 tools/lenslok_sim.py enumerate [--start work/images/c1-C2A0.bin] [--out work/atlas] [--workers 8]
    python3 tools/lenslok_sim.py check     # the read-back again, on the saved challenges and screens
    (skoolkit from the environment, or from $SKOOLKIT_VENV's site-packages)

There is no table of challenges. A challenge is made at $C2A0-$C2A8 from three things (docs/lenslok.md 4.2):
- the generator's state byte, the second LD A,R at $C29A: bit 7 always set (the decryptor's LD R,$FF), so 128 values;
- the code shown before ($C79D, the "previous" code) and the code buffer $C799 ("OK" at the start of a round);
- the excluded set at $C7A9, whose first four bytes GlyphGather overwrites with font bytes of the codes drawn last.
The last two depend only on the previous code X, so the states of the challenge maker are: the first attempt of
the first round (taken from c1's memory at $C2A0, frame 15868), "a later attempt after X" (X's code drawn, X in
$C799 and $C79D) and "the first attempt of the second round after X" ($C799 = "OK" drawn by the size screen, X in
$C79D). enumerate walks them all breadth first: for every state and every state byte $80-$FF it runs SetMarks and
PickCode, and every new code X adds its two states (built by running DrawCode, and the size screen's ShowOK, on the
memory the challenge left). In the first state the bytes $00-$7F are run too, for what the R bit 7 rule keeps out.

Each challenge of the first attempt is then drawn by DrawCode ($C2A6) and read back through the model lens
(read_back): the 12 columns sampled in the slices the lens looks at, each half matched against all 62 glyphs of the
ROM font (0-9, A-Z, a-z) over the 8 rows as the game draws them. The check passes when every half matches exactly one
glyph and it is the code's character; it reports the halves that match several (g and q differ only in row 7).

Output: OUT/challenges.json (every state and byte: state, previous code, byte, code, marks), OUT/codes.json
(every reachable code with the states and bytes that give it), OUT/first/<byte>.scr (the 128 first-attempt screens),
OUT/check.json (read_back over the first-attempt screens and over the live ones of tools/lenslok_live.py).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import lenslok as L  # noqa: E402

REG = {'SP': 0xFFFB, 'IX': 0xC7B6, 'IY': 0x5C3A}
START = os.path.join(E.CASE, 'work', 'images', 'c1-C2A0.bin')
GLYPHS = [ord(c) for c in '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz']


def _simulator():
    try:
        from skoolkit.simulator import Simulator
    except ImportError:
        import glob
        venv = os.environ.get('SKOOLKIT_VENV', '')
        sys.path += glob.glob(os.path.join(venv, 'lib', 'python3*', 'site-packages'))
        from skoolkit.simulator import Simulator
    return Simulator


_WORK = {}


def sim(mem, start, stop, sp=None):
    """run mem (a bytearray, changed in place) from start to stop; one Simulator is kept on a 64 KB work buffer"""
    if 'sim' not in _WORK:
        buf = bytearray(0x10000)
        _WORK['buf'] = buf
        _WORK['sim'] = _simulator()(buf, dict(REG, PC=start))
    buf, s = _WORK['buf'], _WORK['sim']
    buf[:] = mem
    regs = s.registers
    regs[8], regs[9] = REG['IX'] >> 8, REG['IX'] & 0xFF
    regs[10], regs[11] = REG['IY'] >> 8, REG['IY'] & 0xFF
    regs[12] = sp or REG['SP']
    s.run(start, stop)
    mem[:] = buf


def pick(state, byte):
    """SetMarks + PickCode on a copy of state with the generator at byte; returns (code, marks, memory)"""
    m = bytearray(state)
    m[0xC784], m[0xC785] = byte, 0xFE
    sim(m, 0xC2A0, 0xC2A3)
    marks = (m[0xC77F], m[0xC780])
    sim(m, 0xC2A3, 0xC2A6)
    return bytes(m[0xC799:0xC79B]), marks, m


def draw(m):
    """DrawCode on m (after pick), in place; returns the screen"""
    sim(m, 0xC2A6, 0xC2A9)
    return bytes(m[0x4000:0x5B00])


def attempt(mem):
    """the challenge a live memory at $C2A0 makes: code, marks, screen"""
    m = bytearray(mem)
    sim(m, 0xC2A0, 0xC2A3)
    marks = (m[0xC77F], m[0xC780])
    sim(m, 0xC2A3, 0xC2A6)
    code = bytes(m[0xC799:0xC79B])
    return {'code': code, 'marks': marks, 'screen': draw(m)}


def next_states(m, base):
    """the two states a challenge leaves (m after pick): a later attempt, the second round's first attempt"""
    later = bytearray(m)
    draw(later)
    later[0x4000:0x5B00] = base[0x4000:0x5B00]       # LensClear + Bracket redraw the same screen
    second = bytearray(later)
    second[0xC799:0xC79B] = b'OK'                       # ShowOK $C4FF: "OK", then DrawCode
    sp = 0xFFF9
    second[sp], second[sp + 1] = 0xA9, 0xC2             # return to $C2A9, where the run stops
    sim(second, 0xC2C9, 0xC2A9, sp)
    second[0x4000:0x5B00] = base[0x4000:0x5B00]
    return later, second


def _state_rows(job):
    key, st, full = job
    rows, firsts = [], {}
    for byte in range(0 if full else 0x80, 256):
        code, marks, m = pick(st, byte)
        c = code.decode('latin-1')
        rows.append({'state': key[0], 'previous': key[1], 'byte': byte, 'code': c,
                     'marks': ['%02X' % x for x in marks], 'reachable': byte >= 0x80})
        if byte >= 0x80 and c not in firsts:
            firsts[c] = byte
    return key, rows, firsts


def _next(job):
    st, byte, base = job
    _, _, m = pick(st, byte)
    return next_states(m, base)


def enumerate_all(base, workers=8):
    """level by level: every state of the frontier with every byte, then the two states of every new code"""
    from multiprocessing import Pool
    states = {('first', ''): base}
    frontier = [('first', '')]
    rows = []
    with Pool(workers) as pool:
        while frontier:
            res = pool.map(_state_rows, [(k, states[k], k[0] == 'first') for k in frontier])
            new = {}
            for key, rs, firsts in res:
                rows += rs
                for c, byte in firsts.items():
                    if ('later', c) not in states and c not in new:
                        new[c] = (key, byte)
            built = pool.map(_next, [(states[k], b, base) for k, b in new.values()])
            frontier = []
            for c, (later, second) in zip(new, built):
                states[('later', c)] = bytes(later)
                states[('second', c)] = bytes(second)
                frontier += [('later', c), ('second', c)]
            print(f'  {len(rows)} challenges, {len(states)} states, {len(frontier)} new', file=sys.stderr)
    return rows


def grid(screen, scale):
    """the 12 x 8 bits the model lens shows: column c in slice PERM[c-1], sampled at the slice's centre"""
    px = L.screen_pixels(screen)
    _, sl = L.slices(scale * 11)
    h = max(1, 20 * scale // 100)
    out = []
    for r in range(8):
        y = 175 - (120 - h * (r + 1))                  # the band's first drawn row
        out.append([1 if (sl[L.PERM[c]][0] + sl[L.PERM[c]][1] // 2, y) in px else 0 for c in range(12)])
    return out


def read_back(screen, scale, font=None):
    """the two characters the model lens reads: per half, the glyphs whose columns 1-6 match all 8 rows as the game
    draws them (the second character's row 7 is its row 6, 4.4 of docs/lenslok.md)"""
    font = font or L.font()
    g = grid(screen, scale)
    res = []
    for half in range(2):
        cand = []
        for ch in GLYPHS:
            if all(g[r][half * 6:(half + 1) * 6] == L.glyph_bits(bytes([ch, ch]), r, font)[half * 6:(half + 1) * 6]
                   for r in range(8)):
                cand.append(chr(ch))
        res.append(cand)
    return res


def check(screen, scale, code):
    rb = read_back(screen, scale)
    ok = all(len(rb[i]) == 1 and rb[i][0] == code[i] for i in range(2))
    return ok, [''.join(x) for x in rb]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('cmd', choices=['enumerate', 'check'])
    p.add_argument('--start', default=START)
    p.add_argument('--out', default=os.path.join(E.CASE, 'work', 'atlas'))
    p.add_argument('--live', default=os.path.join(E.CASE, 'work', 'atlas', 'live'))
    p.add_argument('--workers', type=int, default=8)
    a = p.parse_args()
    base = bytes(open(a.start, 'rb').read())
    os.makedirs(os.path.join(a.out, 'first'), exist_ok=True)
    if a.cmd == 'enumerate':
        rows = enumerate_all(base, a.workers)
        json.dump(rows, open(os.path.join(a.out, 'challenges.json'), 'w'))
    rows = json.load(open(os.path.join(a.out, 'challenges.json')))
    codes = {}
    for r in rows:
        if r['reachable']:
            codes.setdefault(r['code'], []).append([r['state'], r['previous'], '%02X' % r['byte']])
    json.dump(codes, open(os.path.join(a.out, 'codes.json'), 'w'), indent=0, sort_keys=True)
    unreach = {r['code'] for r in rows if not r['reachable']} - {r['code'] for r in rows
                                                                  if r['reachable'] and r['state'] == 'first'}
    first = [r for r in rows if r['state'] == 'first' and r['reachable']]
    scale = base[0xC7B6]
    results = []
    for r in first:
        path = os.path.join(a.out, 'first', '%02X.scr' % r['byte'])
        if a.cmd == 'enumerate' or not os.path.exists(path):
            _, _, m = pick(base, r['byte'])
            open(path, 'wb').write(draw(m))
        scr = open(path, 'rb').read()
        ok, rb = check(scr, scale, r['code'])
        results.append({'kind': 'first', 'byte': '%02X' % r['byte'], 'code': r['code'], 'read': rb, 'ok': ok})
    live = os.path.join(a.live, 'runs.json')
    if os.path.exists(live):
        for r in json.load(open(live)):
            scr = open(os.path.join(a.live, f"{r['run']}-{r['n']}.scr"), 'rb').read()
            mem = open(os.path.join(a.live, f"{r['run']}-{r['n']}.bin"), 'rb').read()
            ok, rb = check(scr, mem[0xC7B6], r['code'])
            results.append({'kind': 'live', 'id': f"{r['run']}-{r['n']}", 'code': r['code'], 'read': rb, 'ok': ok})
    json.dump(results, open(os.path.join(a.out, 'check.json'), 'w'), indent=0)
    nstates = len({(r['state'], r['previous']) for r in rows})
    print(f'states {nstates}, challenges {len(rows)}, reachable codes {len(codes)}, '
          f'first-attempt codes only with bit 7 clear {len(unreach)}, first-attempt codes {len({r["code"] for r in first})}, '
          f'lens read-back {sum(x["ok"] for x in results)}/{len(results)} ok; ambiguous: '
          f'{[(x.get("byte") or x.get("id"), x["code"], x["read"]) for x in results if not x["ok"]]}')


if __name__ == '__main__':
    sys.exit(main())
