#!/usr/bin/env python3
"""How a level is solved: the play area at two frames of a level recording side by side, every cell whose code
changed between them boxed (the mirrors the player, the turning blocks or the gremlins moved), and the list of the
changes. Read with TTD memory_at (state at the frame's start) from the instance that holds the recording.

    python3 tools/fig_solve.py --work work/docs/dfA/L01 --frames 230,1560 --title "..." out.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

import figlib

sys.path.insert(0, os.path.join(figlib.CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402
import zxscreen  # noqa: E402


def mem(session, frame, addr, n):
    r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                     'offset': addr, 'length': n}, ok=False)
    b = r.structured or {}
    if r.is_error or not b.get('exact', False):
        raise SystemExit(f'memory_at {frame}: {r.text}')
    return bytes.fromhex(b['hex'])


def grid(session, f):
    g = mem(session, f, 0xFD23, 17 * 9)
    return [[g[17 * r + c] for c in range(15)] for r in range(9)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--frames', required=True)
    ap.add_argument('--title', default='')
    ap.add_argument('--labels', default='')
    ap.add_argument('out')
    a = ap.parse_args()
    sys.path.insert(0, os.path.join(kitlib.unreal_root(os.environ.get('UNREAL_NG') or None), 'tools', 'verification',
                                    'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(a.work)
    f0, f1 = [int(x) for x in a.frames.split(',')]
    labels = a.labels.split('|') if a.labels else [f'frame {f0}', f'frame {f1}']
    g0, g1 = grid(session, f0), grid(session, f1)
    pics = [zxscreen.render(mem(session, f, 0x4000, 0x1B00), 2).convert('RGB').crop((0, 0, 512, 320))
            for f in (f0, f1)]
    changed = [(r, c) for r in range(9) for c in range(15) if g0[r][c] != g1[r][c]]
    W = 1050
    lines = []
    burnt = [(r, c) for r, c in changed if g0[r][c] == 0x40 and g1[r][c] == 0]
    for r, c in changed:
        a0, a1 = g0[r][c], g1[r][c]
        if (r, c) in burnt:
            continue
        def name(v):
            v7 = v & 0x7F
            if v7 == 0:
                return 'empty'
            if 1 <= v7 <= 0x10:
                return f'mirror {v7}' + (' turning' if v & 0x80 else '')
            if 0x11 <= v7 <= 0x18:
                return 'cyan polariser' + (' turning' if v & 0x80 else '')
            if 0x19 <= v7 <= 0x20:
                return 'yellow polariser' + (' turning' if v & 0x80 else '')
            if 0x21 <= v7 <= 0x2F:
                return 'absorbing wall'
            if 0x30 <= v7 <= 0x3E:
                return 'reflecting wall'
            if v7 == 0x40:
                return 'cell'
            if 0x4B <= v7 <= 0x4E:
                return 'receiver'
            return f'${v:02X}'
        lines.append(f'row {r}, column {c}: ${a0:02X} {name(a0)} -> ${a1:02X} {name(a1)}')
    cols = 1 if len(lines) <= 14 else 2
    per = (len(lines) + cols - 1) // cols
    h = 40 + 320 + 34 + 20 * per + 70
    o = Image.new('RGB', (W, h), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), a.title, 17, figlib.ACCENT)
    for i, p in enumerate(pics):
        x = 8 + i * 522
        dd = ImageDraw.Draw(p)
        for r, c in changed:
            px, py = 16 * (2 * c + 1), 16 * (2 * r + 1)
            dd.rectangle([px - 2, py - 2, px + 33, py + 33], outline=(255, 255, 255), width=3)
        o.paste(p, (x, 40))
        figlib.text(d, (x, 40 + 322), labels[i], 14, figlib.FG)
    y0 = 40 + 320 + 34
    for i, ln in enumerate(lines):
        figlib.text(d, (12 + (i // per) * 520, y0 + (i % per) * 20), ln, 12, figlib.FG)
    figlib.text(d, (12, y0 + per * 20 + 12),
                f'{len(changed)} cells changed (white boxes), {len(burnt)} of them cells burnt ($40 -> $00), the others above.', 12, figlib.DIM)
    figlib.text(d, (12, y0 + per * 20 + 30), f'LevelGrid $FD23 read with TTD memory_at from {a.work}; state at the start of each frame.', 12, figlib.DIM)
    o.save(a.out)
    print(a.out, o.size, len(changed))


if __name__ == '__main__':
    main()
