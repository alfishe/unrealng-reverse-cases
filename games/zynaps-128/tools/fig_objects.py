#!/usr/bin/env python3
"""The object records of Zynaps 128 as figures (docs/07-objects.md). Adapted from ../zynaps/tools/fig_objects.py.

    python3 tools/fig_objects.py slots  [--npz work/z128B/w1-frames.npz]
    python3 tools/fig_objects.py record FRAME [--npz ...]
    python3 tools/fig_objects.py grid --work work/z128B/w1 FRAME [--npz ...]

  slots   docs/img/objects/slots-w1.png: the 16 records $F36C-$F62B over the whole recording, one line a slot, the
          colour the kind (+7) while +8 bit 7 says active: which slot holds what, and how full the enemy half is.
  record  docs/img/objects/records-FRAME.png: the 44 bytes of every active record at one frame as a byte grid, the
          fields named (src/game/game.ann: objects, movers), the ship and the screen beside them.
  grid    docs/img/objects/hit-grid.png: the collision grid of one frame (TTD memory_at of $FC00-$FD8F at the
          frame's end, RAM page 0): the X bytes ($FC00, a byte a quarter column) and the Y bytes ($FD00, a byte an eighth of a
          row) of the 8 enemy slots against the screen, and the AND that tells which enemy the ship overlaps.
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw

import z128plot as P
import fig_weapons as W

SLOTS = ['0 ship', '1 enemy', '2 enemy', '3 enemy', '4 enemy', '5 enemy', '6 enemy shot', '7 enemy shot',
         '8 enemy shot', '9 laser', '10 laser', '11 laser', '12 laser', '13 plasma 2', '14 side shot', '15 sight']
KIND_NAMES = {0: 'ship', 1: 'laser shot', 2: 'enemy (2)', 3: 'explosion', 4: 'pod', 5: 'enemy shot', 6: 'sight',
              7: 'seeker', 8: 'lockable (8)', 9: 'plasma ball', 10: 'missile', 11: 'enemy (11)', 12: 'big enemy'}


TEXT_MARK = (1.0, 1.0, 0.6)
# the moments of w1 marked on the slots figure
MARKS = {'w1': [(4530, 'A: homing lock, a missile out'), (6905, 'B: CmdLevelEnd'), (6972, 'C: level 2 starts'),
                (8596, 'D: extra life at 10000')]}


def slots(rec, name):
    F = rec.F
    n = len(F)
    kinds = np.full((16, n), -1)
    for i in range(n):
        for s, k, _, _ in rec.active(i):
            kinds[s, i] = k
    P.style()
    fig, ax = P.plt.subplots(figsize=(14, 6.2))
    cmap = {k: P.COLOURS[k % len(P.COLOURS)] for k in range(13)}
    cmap.update({0: (0.85, 0.85, 0.85), 4: (0.3, 0.9, 0.4), 3: (0.55, 0.42, 0.35), 5: (0.9, 0.3, 0.3),
                 1: (0.95, 0.9, 0.3), 2: (0.45, 0.6, 1.0), 11: (0.3, 0.45, 0.85), 9: (1.0, 0.6, 0.25),
                 6: (0.4, 0.8, 1.0), 7: (1.0, 0.45, 0.85), 8: (0.75, 0.45, 0.9), 10: (1, 0.3, 0.3), 12: (0.6, 0.3, 0.8)})
    img = np.zeros((16, n, 3)) + np.array(P.PANEL)
    for s in range(16):
        for i in range(n):
            k = kinds[s, i]
            if k >= 0:
                img[s, i] = cmap[k]
    ax.imshow(img, aspect='auto', interpolation='nearest', extent=(F[0], F[-1], 15.5, -0.5))
    ax.set_yticks(range(16))
    ax.set_yticklabels([f'{SLOTS[s]}  ${0xF36C + 44 * s:04X}' for s in range(16)], family='monospace', fontsize=8.5)
    seen = sorted({int(k) for k in np.unique(kinds) if k >= 0})
    for k in seen:
        ax.plot([], [], 's', color=cmap[k], label=f'{k} {KIND_NAMES[k]}', ms=9)
    ax.legend(loc='upper left', bbox_to_anchor=(1.005, 1.0), fontsize=8.5, title='kind (+7)')
    busy = [(kinds[1:6, i] >= 0).sum() for i in range(n)]
    ax.set_xlabel(f'{name} frame')
    full = sum(1 for b in busy if b == 5) / n * 100
    ax.set_title(f'The 16 object records over {name}: the enemy slots 1-5 hold enemies, their explosions and the pods '
                 f'(all five busy {full:.0f} % of the frames); 9-15 are the ship\'s', fontsize=10.5, pad=20)
    for s in (0.5, 5.5, 8.5, 12.5):
        ax.axhline(s, color=P.BG, lw=2)
    for f, text in MARKS.get(name, []):
        ax.axvline(f, color=TEXT_MARK, lw=1, ls='--')
        ax.text(f, -0.75, text.split(':')[0], color=TEXT_MARK, fontsize=10, ha='center', va='bottom',
                weight='bold')
    if MARKS.get(name):
        ax.set_xlabel(f'{name} frame;   ' + ';   '.join(t for _, t in MARKS[name]))
    fig.tight_layout()
    P.save(fig, P.out('objects', f'slots-{name}.png'))


FIELDS = [(0, 2, 'sprite descriptor'), (2, 1, 'frame'), (3, 2, 'X 8.8 (col + 16)'), (5, 2, 'Y 8.8 (row)'),
          (7, 1, 'kind'), (8, 1, 'flags'), (9, 2, 'strip buffer'), (0x0B, 1, 'row mask'),
          (0x0C, 1, 'score index'), (0x0D, 1, 'hit points / hit mask'), (0x0E, 2, 'Vx'), (0x10, 2, 'Ax'),
          (0x12, 2, 'Vy'), (0x14, 2, 'Ay'), (0x16, 1, 'direction 0-63'), (0x17, 1, 'speed'), (0x18, 1, 'fire rate'),
          (0x19, 1, 'shot speed'), (0x1A, 1, 'wave record'), (0x1B, 1, 'frames left'), (0x1C, 1, 'path command'),
          (0x1D, 2, 'path pointer'), (0x1F, 1, 'loop count'), (0x20, 1, 'shot colour'), (0x21, 1, 'aim mode'),
          (0x22, 1, 'shot life'), (0x23, 1, 'wave check'), (0x24, 1, 'collision bit'), (0x25, 1, 'colour'),
          (0x26, 1, 'counter 1 / pod'), (0x27, 1, 'counter 2'), (0x28, 1, 'counter 2 reload'), (0x29, 2, 'target'),
          (0x2B, 1, 'turn rate')]


def record(rec, frame, name):
    i = int(np.where(rec.F == frame)[0][0])
    act = rec.active(i)
    P.style()
    cell, left, top = 26, 230, 200
    rows = len(act)
    W_, H_ = left + 44 * cell + 20, top + rows * 40 + 210
    img = Image.new('RGB', (W_, H_ + 400), tuple(int(c * 255) for c in P.BG))
    d = ImageDraw.Draw(img)
    f, fs = P.K.font(13), P.K.font(10)
    d.text((10, 8), f'The active object records at {name} frame {frame}: 44 bytes each (hex), the fields named above '
                    f'(src/game/game.ann objects), the kind +7 picks the handler', fill=P.K.TEXT, font=P.K.font(15))
    shades = [(40, 44, 60), (52, 56, 76)]
    tx = P.K.font(11)
    for k, (off, n, label) in enumerate(FIELDS):
        x0 = left + off * cell
        d.rectangle([x0, top - 4, x0 + n * cell - 2, top + rows * 40], fill=shades[k % 2])
        # the field's name turned 90 degrees above its column
        tw = int(d.textlength(label, font=tx)) + 4
        lab = Image.new('RGB', (tw, 14), tuple(int(c * 255) for c in P.BG))
        ImageDraw.Draw(lab).text((2, 0), label, fill=P.K.TEXT if k % 2 == 0 else (180, 200, 255), font=tx)
        lab = lab.rotate(90, expand=True)
        img.paste(lab, (x0 + (n * cell - 14) // 2, top - 22 - lab.size[1]))
        d.text((x0 + 2, top - 18), f'{off:02X}', fill=P.K.DIM, font=fs)
    for r, (s, kind, x, y) in enumerate(act):
        y0 = top + 14 + r * 40
        rb = W.Rec.slot(rec, i, s)
        col = W.KIND_COLOUR.get(kind, (230, 230, 230))
        d.text((10, y0 + 4), f'slot {s:2d} ${0xF36C + 44 * s:04X}', fill=P.K.TEXT, font=f)
        d.text((10, y0 + 20), f'kind {kind} {KIND_NAMES.get(kind, "")}', fill=col, font=fs)
        for b in range(44):
            d.text((left + b * cell + 3, y0 + 10), f'{rb[b]:02X}', fill=col if b in (3, 4, 5, 6, 7, 8) else P.K.TEXT,
                   font=f)
    scr = W.screen_img(rec, i, 2)
    W.boxes(scr, rec, i, 2)
    img.paste(scr, (left, top + rows * 40 + 30))
    d.text((10, top + rows * 40 + 40), 'the same frame:\nevery active record\nboxed at its X, Y', fill=P.K.TEXT, font=f)
    img = img.crop((0, 0, W_, top + rows * 40 + 30 + 384 + 10))
    path = P.out('objects', f'records-{name}-{frame}.png')
    img.save(path)
    print('wrote', os.path.relpath(path, P.CASE))


def grid(work, frame, npz):
    import z128lib as Z
    rec = W.Rec(npz)
    s = Z.session(work)
    g = Z.read(s, frame, 0xFC00 - 0xC000, 0x190, space='ram', page=0)
    at = int(np.where(rec.F == frame)[0][0])
    xs, ys = g[0:0x100], g[0x100:0x190]
    scale = 3
    img = W.screen_img(rec, at, scale)
    W.boxes(img, rec, at, scale)
    L, T0 = 150, 170
    canvas = Image.new('RGB', (L + 256 * scale + 250, T0 + 192 * scale + 20), P.K.BACKGROUND)
    canvas.paste(img, (L, T0))
    d = ImageDraw.Draw(canvas)
    f = P.K.font(12)
    cols = [(255, 90, 80), (90, 200, 120), (90, 150, 250), (240, 200, 70), (200, 110, 230), (70, 210, 220),
            (255, 150, 60), (230, 230, 230)]
    for xi in range(256):
        col_x = xi / 4 - 16
        if not xs[xi] or not 0 <= col_x < 32:
            continue
        for b in range(8):
            if xs[xi] & (1 << b):
                px = L + col_x * 8 * scale
                d.rectangle([px, T0 - 12 - 12 * b - 9, px + 2 * scale - 1, T0 - 12 - 12 * b], fill=cols[b])
    for yi in range(0x90):
        for b in range(8):
            if ys[yi] & (1 << b):
                py = T0 + (yi + 8) * scale
                d.rectangle([L - 12 - 12 * b - 9, py, L - 12 - 12 * b, py + scale - 1], fill=cols[b])
    d.text((10, 8), f'The hit grid at the end of {rec.name} frame {frame}: each enemy record ORs its bit into the X bytes '
                    f'$FC00 (above, a quarter column each)', fill=P.K.TEXT, font=P.K.font(14))
    d.text((10, 26), 'and the Y bytes $FD00 (left, one a pixel line); a friendly record ANDs the two unions over its '
                     'own box into +$0D', fill=P.K.TEXT, font=P.K.font(14))
    x0 = L + 256 * scale + 16
    y = T0
    d.text((x0, y), 'bit = enemy record', fill=P.K.TEXT, font=f)
    for b in range(8):
        y += 16
        d.text((x0, y), f'bit {b}: slot {b + 1} ${0xF398 + 44 * b:04X}', fill=cols[b], font=f)
    y += 30
    d.text((x0, y), f'+$0D of the friendly records,', fill=P.K.TEXT, font=f)
    y += 16
    d.text((x0, y), f'frame {frame + 1} (TestHitGrid runs', fill=P.K.TEXT, font=f)
    y += 16
    d.text((x0, y), 'in the next interrupt)', fill=P.K.TEXT, font=f)
    for sl, k, _, _ in rec.active(at + 1):
        if sl in (0, 9, 10, 11, 12, 13, 14, 15):
            y += 16
            v = rec.slot(at + 1, sl)[0x0D]
            d.text((x0, y), f'slot {sl:2d} {W.KINDS.get(k, k)}: %{v:08b}', fill=P.K.TEXT if v else P.K.DIM, font=f)
    path = P.out('objects', 'hit-grid.png')
    canvas.save(path)
    print('wrote', os.path.relpath(path, P.CASE), canvas.size)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what')
    p.add_argument('rest', nargs='*')
    p.add_argument('--npz', default=os.path.join(P.CASE, 'work', 'z128B', 'w1-frames.npz'))
    p.add_argument('--name', default='w1')
    p.add_argument('--work')
    a = p.parse_args()
    if a.what == 'grid':
        grid(a.work, int(a.rest[0]), a.npz)
        return
    rec = W.Rec(a.npz)
    if a.what == 'slots':
        slots(rec, a.name)
    elif a.what == 'record':
        record(rec, int(a.rest[0]), a.name)


if __name__ == '__main__':
    main()
