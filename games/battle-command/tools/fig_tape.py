#!/usr/bin/env python3
"""Doc 03 figure: both tape sides as pictures, every TZX block at its time, coloured by what it is and where it goes.

    python3 tools/fig_tape.py docs/img/load/tape-sides.png

Reads work/stage1/media/side1.tzx and side2.tzx through tools/tzxblocks.py (the block timings and the pauses). The
two sides share one time scale; a third strip zooms into side 1 around the short control blocks (blocks 13-23), where
the marks `07 FF 00` and the key blocks sit between the screen and bank 5.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import tzxblocks  # noqa: E402
from kitlib import font  # noqa: E402

W = 1050
X0, X1 = 70, 1030
ROM, PILOT, MARK, CTRL, BAD = '#4a7bd0', '#9a9a9a', '#202020', '#d04090', '#d03030'
DEST = {'screen': '#e0a030', 'attrs': '#e8c060', 'bank 5': '#5aa05a', 'bank 0': '#3d8f8f', 'bank 1': '#8a6fc0',
        'bank 3': '#c07a3a', 'bank 4': '#a0a040', 'bank 6': '#6a8fd0', 'bank 7': '#b05a8a', 'stage 2': '#30a0c0'}
SIDE1 = {2: 'BASIC', 7: 'stage 2', 13: 'screen', 15: 'attrs', 17: 'key', 19: 'key', 21: 'table', 23: 'bank 5',
         25: 'bank 0', 27: 'bank 1', 29: 'bank 3', 31: 'bank 4', 33: 'bank 6', 35: 'bank 7', 37: '$BE5D', 39: '$BF21',
         41: '$8000', 43: '$8036'}


def timeline(path):
    """[(index, start s, end s, block)] with the pauses after each block."""
    out, t = [], 0.0
    for b in tzxblocks.parse(open(path, 'rb').read()):
        s = tzxblocks.seconds(b) or 0
        out.append((b['index'], t, t + s, b))
        t += s + b.get('pause', 0) / 1000
    return out, t


def colour(side, idx, blk, prev_text):
    data = blk.get('data')
    kind = blk['kind']
    if kind in ('pure tone', 'pulses'):
        return PILOT, None
    if data is None:
        return None, None
    if side == 1:
        if kind == 'standard':
            return ROM, 'BASIC' if idx == 2 else None
        if len(data) == 3 and data[0] == 0x07:
            return MARK, None
        name = SIDE1.get(idx)
        if name in DEST:
            return DEST[name], name
        return CTRL, name
    if kind == 'standard':
        if len(data) == 19:
            return ROM, None
        if idx == 2:
            return '#2a5aa0', 'DIRECTORY'
        if prev_text == 'Missile Battery':
            return BAD, 'm2'
        return ROM, prev_text
    return None, None


def strip(d, y, side, blocks, t0, t1, title, labels=True, small=False):
    f = font(12)
    d.text((4, y + 6), title, font=f, fill='black')
    d.rectangle([X0, y, X1, y + 26], outline='#888', fill='white')

    def x(t):
        return X0 + (t - t0) * (X1 - X0) / (t1 - t0)
    prev_text, mission = None, 0
    for idx, s, e, b in blocks:
        if b['kind'] == 'text':
            prev_text = b.get('text') or prev_text
        if e < t0 or s > t1:
            continue
        c, name = colour(side, idx, b, prev_text)
        if c is None:
            continue
        xa, xb = max(X0, x(s)), min(X1, x(e))
        if xb - xa < 1:
            xb = xa + 1
        d.rectangle([xa, y + 1, xb, y + 25], fill=c)
        if not labels:
            continue
        if side == 2 and b['kind'] == 'standard' and len(b['data']) > 19:
            mission += 1
            name = 'DIRECTORY' if idx == 2 else str(mission - 1)
        if name and (xb - xa > 22 or small):
            ty = y + 30 + (14 if side == 1 and name in ('bank 4', 'bank 1', 'bank 0', 'bank 7', 'screen') else 0)
            if small and xb - xa < 30:
                d.line([(xa + xb) / 2, y + 26, (xa + xb) / 2, y + 34], fill='black')
                ty = y + 36 + ((idx // 2) % 2) * 14
            d.text((xa + 2, ty), f'{name}' if not small else f'{idx}: {name}', font=font(11), fill='black')
    return x


def main():
    s1, t1 = timeline(os.path.join(HERE, '..', 'work', 'stage1', 'media', 'side1.tzx'))
    s2, t2 = timeline(os.path.join(HERE, '..', 'work', 'stage1', 'media', 'side2.tzx'))
    im = Image.new('RGB', (W, 470), 'white')
    d = ImageDraw.Draw(im)
    d.text((X0, 6), 'Battle Command, both tape sides on one time scale (TZX timings, pauses included)', font=font(14),
           fill='black')
    tend = max(t1, t2)
    x = strip(d, 40, 1, s1, 0, tend, 'side 1')
    strip(d, 110, 2, s2, 0, tend, 'side 2')
    for t in range(0, int(tend) + 1, 60):
        d.line([x(t), 180, x(t), 186], fill='black')
        d.text((x(t) - 10, 188), f'{t} s', font=font(11), fill='black')
    d.text((X0, 206), f'side 1: {len(s1)} blocks, {t1:.1f} s; side 2: {len(s2)} blocks, {t2:.1f} s; m2 = Ocean\'s short '
           'mission 2 block (6384 of 6406 bytes)', font=font(12), fill='black')
    z0 = [e for idx, s, e, b in s1 if idx == 15][0] - 0.08
    z1 = [s for idx, s, e, b in s1 if idx == 23][0] + 0.12
    d.text((X0, 240), f'side 1 zoomed, {z0:.2f}-{z1:.2f} s: the end of the attributes, the marks (black), the two key '
           'blocks and the table before bank 5', font=font(12), fill='black')
    xz = strip(d, 262, 1, s1, z0, z1, 'zoom', small=True)
    for k in range(6):
        t = z0 + k * (z1 - z0) / 5
        d.line([xz(t), 332, xz(t), 338], fill='black')
        d.text((xz(t) - 16, 340), f'{t:.2f} s', font=font(11), fill='black')
    ly = 380
    items = [(ROM, 'ROM-speed block'), (PILOT, 'SpeedLock pilot and sync'), (MARK, 'mark 07 FF 00'),
             (CTRL, 'control block'), (BAD, 'refused block')] + [(c, n) for n, c in DEST.items()]
    cx = X0
    for c, n in items:
        w = d.textlength(n, font=font(11)) + 30
        if cx + w > X1:
            cx, ly = X0, ly + 22
        d.rectangle([cx, ly, cx + 16, ly + 14], fill=c)
        d.text((cx + 20, ly), n, font=font(11), fill='black')
        cx += w + 8
    os.makedirs(os.path.dirname(sys.argv[1]), exist_ok=True)
    im.save(sys.argv[1])


if __name__ == '__main__':
    main()
