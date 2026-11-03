#!/usr/bin/env python3
"""The playfield buffer of a recording against the course data (docs/06-rendering.md 6.4, 6.6).

    python3 tools/verify_buffer.py FRAME:T:ROUND ... [--unreal UNREAL_NG_CHECKOUT]

For each moment (TTD memory_at in an unreal-ng instance with work/p2 open, re_session.py open), the four sets of 32
strips are rebuilt from src/res and build/game.bin: set (even pages, half $00) the fresh strips of 6.5, the other
three a strip and its right neighbour moved by 2, 4 or 6 pixels with their line offsets (6.4). A strip is equal
when lines 4-123 match byte for byte (the first and last lines take bits from outside the strip). The strips that
differ are then tried as a pad or dish block (6.6) laid over the course: AND mask, OR pixels, strip k of the block
4 lines below strip k - 1, any frame, line and first column."""
import sys
import os
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
os.chdir(ROOT)
sys.path.insert(0, HERE)
UNREAL = os.environ.get('UNREAL_NG', '')
if '--unreal' in sys.argv:
    i = sys.argv.index('--unreal')
    UNREAL = sys.argv[i + 1]
    del sys.argv[i:i + 2]
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import re_session, res_preview, memanim
s, _ = re_session.session_of('work/p2')
mem0 = bytes(res_preview.LO) + open('build/game.bin', 'rb').read()

def cols(n):
    """The fresh strips of course n, with the courses before and after it joined on (the scroll runs from one into
    the next, 6.5), as (strip, edge phase) in order"""
    rows = []
    for m in (n - 1, n, n + 1):
        if 1 <= m <= 10:
            rows += res_preview.course_rows(mem0, open(f'src/res/course/round-{m:02d}.bin', 'rb').read())
    out = []
    for i0 in range(len(rows) - 14):
        strip = b''.join(bytes(mem0[0xC400 + 8 * mem0[rows[i0 + i] + i] + k] for k in range(8)) for i in range(15))
        for edge in (0xC4B8, 0xC4C0):  # the edge tile follows the strip count, not the course: try both
            out.append(bytes(mem0[edge + k] for k in range(8)) + strip)
    return out


def comb(a, b, k, da, db):
    return [((a[y + da] << k) | (b[y + db] >> (8 - k))) & 0xFF if 0 <= y + da < 128 and 0 <= y + db < 128 else None
            for y in range(128)]

SETS = {(0, 0x00): None, (0, 0x80): (2, 1, -3), (1, 0x00): (4, 2, -2), (1, 0x80): (6, 3, -1)}
STATICS = [open(f'src/res/gfx/sprites/{n}.bin', 'rb').read() for n in ('slot-1c', 'slot-1e')]
WIDTHS = (4, 4, 4, 3)  # strips of the four frames of a 420-byte block, 14 lines each


def rebuilt(C, rule):
    if rule is None:
        return [list(c) for c in C]
    return [comb(C[2 * m + u], C[2 * m + 2 + v], *rule) for m in range(len(C) // 2 - 1) for u in (0, 1) for v in (0, 1)]


def stamp(strips, bases):
    """A static block over the course that gives these adjacent strips exactly, or None"""
    for b, blk in enumerate(STATICS):
        for frame in range(4):
            start = sum(WIDTHS[:frame]) * 28
            for first in range(-3, 4):
                for y0 in range(128):
                    ok = True
                    for c, (st, base) in enumerate(zip(strips, bases)):
                        k = c + first
                        for y in range(4, 124):
                            e = base[y]
                            line = y - (y0 - 4 * k)
                            if 0 <= k < WIDTHS[frame] and 0 <= line < 14 and e is not None:
                                e = (e & blk[start + k * 28 + 2 * line]) | blk[start + k * 28 + 2 * line + 1]
                            if e != st[y]:
                                ok = False
                                break
                        if not ok:
                            break
                    if ok:
                        return f"{('slot-1c', 'slot-1e')[b]} frame {frame}"
    return None


for arg in sys.argv[1:]:
    f, t, rnd = map(int, arg.split(':'))
    mem = memanim.memory_at(s, f, t)
    C = cols(rnd)
    blit = (mem[0xC32E] & 1, mem[0xC32F])
    out = []
    for (parity, half), rule in SETS.items():
        R = rebuilt(C, rule)
        exact, odd = 0, []
        for j in range(32):
            page = 0x80 + 2 * j + parity
            st = mem[(page << 8) + half:(page << 8) + half + 128]
            best = min(R, key=lambda r: sum(1 for y in range(4, 124) if r[y] != st[y]))
            if all(best[y] == st[y] for y in range(4, 124)):
                exact += 1
            else:
                odd.append((j, st, best))
        groups, note = [], ''
        for j, st, best in odd:
            if groups and groups[-1][-1][0] == j - 1:
                groups[-1].append((j, st, best))
            else:
                groups.append([(j, st, best)])
        for g in groups:
            hit = stamp([x[1] for x in g], [x[2] for x in g])
            if not hit:
                each = [stamp([x[1]], [x[2]]) for x in g]
                if all(each):
                    hit = 'static strips (one block each column: blocks side by side)'
            note += f'; columns {g[0][0]}-{g[-1][0]}: ' + (f'a stamped {hit}, exact' if hit else 'not explained')
        live = ' (the set the blit shows: the pass draws its sprites here)' if (parity, half) == blit else ''
        out.append(f'{"odd" if parity else "even"} ${half:02X}{live}: {exact}/32 course strips{note}')
    print(f'{f}:{t} round {rnd}:\n  ' + '\n  '.join(out))
