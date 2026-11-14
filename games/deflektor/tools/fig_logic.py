#!/usr/bin/env python3
"""Doc 10's rule sheets: BeamMirror $8FFB's answer for every mirror code and incoming direction, and the wall bounce
tables InBounceTable $8140 and OutBounceTable $8080 for every slanted direction.

    python3 tools/fig_logic.py mirror OUT
    python3 tools/fig_logic.py bounce OUT
    python3 tools/fig_logic.py energy OUT [WORK]   # the energy bar over a recording's snapshots (default energy)

The new direction is (16 - direction + code - 1 + 8) AND 15 (the listing's BeamMirror). The answer equal to the
reverse of the incoming direction sends the beam back along itself: BeamVertex $906E sees the reversal and calls
BeamBackToLaser (OVERLOAD). Each mirror code is drawn through CellTable as the game draws it.
"""
import sys

from PIL import Image, ImageDraw

import figlib

ARROW = {0: (1, 0), 4: (0, 1), 8: (-1, 0), 12: (0, -1)}


def mirror(out):
    img = figlib.image()
    W = 1050
    cw, ch = 56, 34
    x0, y0 = 120, 120
    o = Image.new('RGB', (W, y0 + 16 * ch + 70), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'BeamMirror $8FFB: the direction out of a mirror, for each code and incoming direction', 17,
                figlib.ACCENT)
    figlib.text(d, (10, 32), 'out = (16 - in + code - 1 + 8) AND 15. Directions 0-15 clockwise from east (4 south, 8 '
                'west, 12 north). Red: out = in + 8, the beam goes back: OVERLOAD', 12, figlib.DIM)
    for k in range(16):
        code = k + 1
        x = x0 + k * cw
        o.paste(figlib.cell_image(img, code, 2), (x + 12, 52))
        figlib.text(d, (x + 14, 88), '$%02X' % code, 12, figlib.FG)
    figlib.text(d, (10, 92), 'in \\ code', 12, figlib.DIM)
    for din in range(16):
        y = y0 + din * ch
        figlib.text(d, (20, y + 9), 'in %2d' % din, 13, figlib.FG)
        for k in range(16):
            out_dir = (16 - din + k + 8) & 15
            x = x0 + k * cw
            back = out_dir == (din + 8) & 15
            fill = (150, 40, 40) if back else (36, 36, 46)
            d.rectangle([x + 2, y + 2, x + cw - 3, y + ch - 3], fill=fill)
            figlib.text(d, (x + 18, y + 9), '%2d' % out_dir, 13, figlib.FG)
    figlib.text(d, (10, y0 + 16 * ch + 12), 'Each column: one of the 16 mirror codes, drawn by the game; each row an '
                'incoming direction. Only the odd codes have red cells: two beams hit them square on.', 12,
                figlib.DIM)
    figlib.text(d, (10, y0 + 16 * ch + 32), 'Example (L01 frame 1514): in 8 (west) on $0F gives 14; in 14 on $08 gives '
                '1; in 1 on $02 gives 8, and the beam runs west into the receiver.', 12, figlib.DIM)
    o.save(out)


DELTAS = [(2, 0), (2, 1), (1, 1), (1, 2), (0, 2), (-1, 2), (-1, 1), (-2, 1), (-2, 0), (-2, -1), (-1, -1), (-1, -2),
          (0, -2), (1, -2), (1, -1), (2, -1)]


def arrow(d, cx, cy, direction, length, fill, width=3):
    dx, dy = DELTAS[direction]
    n = (dx * dx + dy * dy) ** 0.5
    ux, uy = dx / n, dy / n
    x0, y0 = cx - ux * length / 2, cy - uy * length / 2
    x1, y1 = cx + ux * length / 2, cy + uy * length / 2
    d.line([(x0, y0), (x1, y1)], fill=fill, width=width)
    px, py = -uy, ux
    d.polygon([(x1, y1), (x1 - ux * 9 + px * 5, y1 - uy * 9 + py * 5), (x1 - ux * 9 - px * 5, y1 - uy * 9 - py * 5)],
              fill=fill)


def bounce(out):
    img = figlib.image()
    inb = img[0x8140:0x8170]
    outb = img[0x8080:0x8100]
    dirs = [d for d in range(16) if d & 3]
    W = 1050
    rh = 52
    y0 = 118
    o = Image.new('RGB', (W, y0 + len(dirs) * rh + 70), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'A slanted beam meets a reflecting wall ($72) or a yellow polariser across it', 17,
                figlib.ACCENT)
    figlib.text(d, (10, 32), 'Incoming pass: InBounceTable $8140 + 3 x direction (new direction, dx, dy; $80 + n: a '
                'diagonal, InCornerTable $8100 + n). Outgoing pass:', 12, figlib.DIM)
    figlib.text(d, (10, 50), 'OutBounceTable $8080 + 8 x direction: two neighbours of the wall character met (grey: '
                'the character met; yellow 1, 2: tested),', 12, figlib.DIM)
    figlib.text(d, (10, 68), 'then the answer by which of them are walls ($31-$72). Red: the reverse of a beam that '
                'came straight, so OVERLOAD. Axis rows: never read.', 12, figlib.DIM)
    cols = [('direction', 20), ('incoming: $8140', 150), ('tested', 420), ('none', 560), ('1 only', 680),
            ('2 only', 800), ('both', 920)]
    for name, x in cols:
        figlib.text(d, (x, 94), name, 13, figlib.FG)
    for i, dr in enumerate(dirs):
        y = y0 + i * rh
        d.rectangle([10, y, W - 10, y + rh - 4], fill=(32, 32, 40))
        cy = y + rh // 2 - 2
        figlib.text(d, (20, cy - 8), '%2d' % dr, 14, figlib.FG)
        arrow(d, 80, cy, dr, 34, (255, 80, 255))
        nd, dx, dy = inb[3 * dr], inb[3 * dr + 1], inb[3 * dr + 2]
        dx = dx - 256 if dx > 127 else dx
        dy = dy - 256 if dy > 127 else dy
        if nd & 0x80:
            figlib.text(d, (150, cy - 8), '$%02X: InCornerTable $%04X' % (nd, 0x8100 + (nd & 0x7F)), 13, figlib.DIM)
        else:
            arrow(d, 175, cy, nd, 34, (120, 220, 255))
            figlib.text(d, (205, cy - 8), '%2d, step (%d, %d)' % (nd, dx, dy), 13, figlib.FG)
        w = outb[8 * dr:8 * dr + 8]
        t1 = w[0] | w[1] << 8
        t2 = w[2] | w[3] << 8
        t1 = t1 - 65536 if t1 > 32767 else t1
        t2 = t2 - 65536 if t2 > 32767 else t2
        g = 14
        gx, gy = 440, y + 2
        for rr in range(3):
            for cc in range(3):
                off = (rr - 1) * 32 + (cc - 1)
                fill = (110, 110, 120) if off == 0 else (200, 170, 40) if off in (t1, t2) else (50, 50, 60)
                d.rectangle([gx + cc * g, gy + rr * g, gx + cc * g + g - 2, gy + rr * g + g - 2], fill=fill)
                if off == t1:
                    figlib.text(d, (gx + cc * g + 3, gy + rr * g), '1', 10, (0, 0, 0))
                if off == t2:
                    figlib.text(d, (gx + cc * g + 3, gy + rr * g), '2', 10, (0, 0, 0))
        figlib.text(d, (492, cy - 8), '%+d %+d' % (t1, t2), 11, figlib.DIM)
        for k in range(4):
            a = w[4 + k]
            x = 560 + 120 * k
            back = a == (dr + 8) & 15
            col = (230, 80, 80) if back else (120, 220, 255)
            arrow(d, x + 22, cy, a, 30, col)
            figlib.text(d, (x + 48, cy - 8), '%2d' % a, 13, col)
    figlib.text(d, (10, y0 + len(dirs) * rh + 8), 'The row read is the beam\'s direction for the incoming pass and the '
                'new direction (after a mirror at the vertex) for the outgoing one.', 12, figlib.DIM)
    figlib.text(d, (10, y0 + len(dirs) * rh + 28), 'Example (an experiment on L01 frame 1514): direction 1 met $72 at '
                'row 15, column 12; only neighbour 2 (-1) is a wall: 15, up and away.', 12, figlib.DIM)
    o.save(out)


def energy(out):
    """The ENERGY bar ($54F1-$54F8, screen page 5), MessageNumber $A104, Lives $837D and LaserCharging $A509 read
    from each snapshot of a recording (48K pages: $4000 ram-5, $8000 ram-2)."""
    import glob
    import os
    work = sys.argv[3] if len(sys.argv) > 3 else os.path.join(figlib.CASE, 'work', 'stage1', 'energy')
    rows = []
    for dd in sorted(glob.glob(os.path.join(work, 'snapshots', '[0-9]*'))):
        scr = open(os.path.join(dd, 'ram-5.bin'), 'rb').read()
        hi = open(os.path.join(dd, 'ram-2.bin'), 'rb').read()
        px = sum(bin(b).count('1') for b in scr[0x14F1:0x14F9])
        rows.append((int(os.path.basename(dd)), px, hi[0x2104], hi[0x037D], hi[0x2509]))
    W, H = 1050, 520
    x0, y0, pw, ph = 70, 90, 940, 300
    fmax = rows[-1][0]
    o = Image.new('RGB', (W, H), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'The ENERGY bar of the energy recording (level 1, no key), one point a snapshot (every 250 '
                'frames)', 17, figlib.ACCENT)
    figlib.text(d, (10, 32), 'Pixels set in $54F1-$54F8 (64 = full). DrainEnergy $A613 takes one every 90 frames '
                '(level 1\'s rate); the charge refills it 4 a pass.', 12, figlib.DIM)
    figlib.text(d, (10, 50), 'Colour: the message shown (MessageNumber $A104). The vertical lines: a life lost '
                '(Lives $837D down).', 12, figlib.DIM)
    d.rectangle([x0, y0, x0 + pw, y0 + ph], outline=figlib.DIM)
    for v in (0, 16, 32, 48, 64):
        y = y0 + ph - v * ph // 64
        d.line([(x0 - 4, y), (x0, y)], fill=figlib.DIM)
        figlib.text(d, (x0 - 34, y - 8), '%2d' % v, 12, figlib.DIM)
    for f in range(0, fmax + 1, 2000):
        x = x0 + f * pw // fmax
        d.line([(x, y0 + ph), (x, y0 + ph + 4)], fill=figlib.DIM)
        figlib.text(d, (x - 16, y0 + ph + 8), str(f), 12, figlib.DIM)
    colours = {0: (150, 150, 160), 1: (90, 200, 255), 0x0A: (255, 220, 90), 0x0C: (255, 140, 60),
               0x17: (230, 70, 70)}
    names = {0: 'none', 1: '$01 CHARGING LASER', 0x0A: '$0A ENERGY LOW', 0x0C: '$0C CRITICAL',
             0x17: '$17 ENERGY DRAINED'}
    prev = None
    for f, px, msg, lives, chg in rows:
        x = x0 + f * pw // fmax
        y = y0 + ph - px * ph // 64
        if prev and lives < prev[3]:
            d.line([(x, y0), (x, y0 + ph)], fill=(200, 60, 60), width=1)
            figlib.text(d, (x + 3, y0 + 4), 'lives %d' % lives, 11, (230, 90, 90))
        if prev:
            d.line([(prev[0], prev[1]), (x, y)], fill=(90, 90, 100), width=1)
        c = colours.get(msg, figlib.FG)
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=c)
        prev = (x, y, msg, lives)
    for k, (m, nm) in enumerate(names.items()):
        x = 20 + 205 * k
        d.ellipse([x, y0 + ph + 44, x + 9, y0 + ph + 53], fill=colours[m])
        figlib.text(d, (x + 14, y0 + ph + 40), nm, 12, figlib.FG)
    figlib.text(d, (10, H - 52), 'Source: %s/snapshots/NNNNNN (ram-5: the screen, ram-2: $8000-$BFFF).'
                % os.path.relpath(work, figlib.CASE), 12, figlib.DIM)
    figlib.text(d, (10, H - 32), 'Level 1: full at 1000, two bytes left at 5000, one at 5750, empty at 6500; '
                'the charge refills it, and the clock starts again.', 12, figlib.DIM)
    o.save(out)


if __name__ == '__main__':
    {'mirror': mirror, 'bounce': bounce, 'energy': energy}[sys.argv[1]](sys.argv[2])
