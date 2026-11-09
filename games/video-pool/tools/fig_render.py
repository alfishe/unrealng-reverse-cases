#!/usr/bin/env python3
"""The figures of doc 06 (rendering), drawn from the image and from recordings read with time_travel memory_at.

    python3 tools/fig_render.py layout  --work W1 --at 1060 --out docs/img/render/layout.png
    python3 tools/fig_render.py sprites --out docs/img/render/ball-shifts.png
    python3 tools/fig_render.py split   --work W1 --at 1060 --out docs/img/render/ball-split.png
    python3 tools/fig_render.py tables  --work W1 --at 1060 --out docs/img/render/tables.png
    python3 tools/fig_render.py pen     --work M1 --at 900 --out docs/img/render/pen.png

W1 / M1 are work folders whose instance holds the recording (re_session.py session.json): w1 or m1 replayed from
work/snaps/entry.z80 with tests/inputs/<name>.txt (work/docs/vpB/replay.py). The image is work/mkgame/original.bin
(64 KB, the address is the offset). The small-pockets table is docs/img/play/m1-7998-small-pockets.png.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, HERE)
import vplib  # noqa: E402

K = vplib.K
IMAGE = os.path.join(CASE, 'work', 'mkgame', 'original.bin')
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (100, 100, 108), (200, 200, 205)
COLS = [(214, 39, 40), (31, 119, 180), (44, 160, 44), (148, 103, 189), (255, 127, 14), (140, 86, 75),
        (227, 119, 194), (23, 190, 207)]
W = 1050


def fonts():
    return K.font(15), K.font(13), K.font(19)


def image():
    return open(IMAGE, 'rb').read()


def screen_of(work, frame):
    s = vplib.session(work)
    return vplib.read(s, frame, 0x4000, 6912)


def header(d, title, sub, f, ft):
    d.text((20, 12), title, font=ft, fill=FG)
    d.text((20, 40), sub, font=f, fill=DIM)


# ---------------------------------------------------------------------------------------------------------------
def fig_layout(a):
    f, fs, ft = fonts()
    shot = screen_of(a.work, a.at)
    scr = K.render_screen(shot, 0).resize((768, 576), Image.NEAREST)
    img = Image.new('RGB', (W, 740), BG)
    d = ImageDraw.Draw(img)
    header(d, 'The play screen: 24 character rows in five bands, one attribute each',
           f'w1 frame {a.at}; the 8 x 8 cell grid over the screen, the attribute of each row on the right', f, ft)
    img.paste(scr, (20, 80))
    for c in range(33):
        d.line([(20 + c * 24, 80), (20 + c * 24, 656)], fill=(120, 120, 120))
    for r in range(25):
        d.line([(20, 80 + r * 24), (788, 80 + r * 24)], fill=(120, 120, 120))
    attrs = shot[0x1800:0x1B00]
    for r in range(24):
        row = attrs[r * 32:(r + 1) * 32]
        vals = sorted(set(row))
        txt = ' '.join(f'${v:02X}' for v in vals)
        d.text((798, 80 + r * 24 + 4), f'{r:2d}  {txt}', font=fs, fill=FG)
    bands = [(0, 1, 'HUD: scores, frame, shots,\npower box'), (2, 4, 'messages, potted row,\nlives'),
             (5, 5, 'pocket marks x1..x3'), (6, 22, 'the table: cushions,\nballs, cursor'),
             (23, 23, 'pocket marks x4..x6')]
    y0 = 80
    for i, (r0, r1, name) in enumerate(bands):
        c = COLS[i]
        d.rectangle([14, y0 + r0 * 24, 19, y0 + (r1 + 1) * 24], fill=c)
    d.text((20, 682), 'Attributes: $39 white paper, blue ink; $38 white, black; $3A white, red (the HUD digits); '
           '$60 BRIGHT green paper, black ink.', font=fs, fill=FG)
    d.text((20, 664), 'Bands (left bars): rows 0-1 HUD, 2-4 messages and potted row, 5 and 23 pocket marks, '
           '6-22 the table.', font=fs, fill=FG)
    d.text((20, 706), f'python3 tools/fig_render.py layout --work work/docs/vpB/w1 --at {a.at}', font=fs, fill=DIM)
    img.save(a.out)


# ---------------------------------------------------------------------------------------------------------------
def draw_sprite(d, mem, addr, x0, y0, scale, ink=FG, paper=(225, 240, 225), grid=True):
    for y in range(16):
        for xb in range(3):
            b = mem[addr + y * 3 + xb]
            for bit in range(8):
                on = b & (0x80 >> bit)
                px = x0 + (xb * 8 + bit) * scale
                py = y0 + y * scale
                d.rectangle([px, py, px + scale - 1, py + scale - 1], fill=ink if on else paper)
    if grid:
        for xb in range(4):
            d.line([(x0 + xb * 8 * scale, y0), (x0 + xb * 8 * scale, y0 + 16 * scale)], fill=COLS[0], width=2)


def fig_sprites(a):
    f, fs, ft = fonts()
    mem = image()
    img = Image.new('RGB', (W, 790), BG)
    d = ImageDraw.Draw(img)
    header(d, 'Pre-shifted, not masked: each ball is stored 8 times, one per pixel offset',
           'BallSprites $D000: 56 sprites, 3 bytes x 16 lines; index = 7 x (x AND 7) + ball; red = byte edges', f, ft)
    # ball 1 at the 8 shifts, scale 5
    sc = 5
    for s in range(8):
        idx = 7 * s + 1
        addr = 0xD000 + 48 * idx
        x0 = 20 + (s % 4) * 255
        y0 = 90 + (s // 4) * 125
        draw_sprite(d, mem, addr, x0, y0, sc)
        d.text((x0, y0 - 20), f'shift {s}: sprite {idx}, ${addr:04X}', font=fs, fill=FG)
    # all 7 balls at shift 0, scale 4, and the full sheet small
    y1 = 360
    d.text((20, y1), 'The seven balls at shift 0 (cue ball and 1-6), sprites 0-6, $D000-$D14F:', font=f, fill=FG)
    for b in range(7):
        draw_sprite(d, mem, 0xD000 + 48 * b, 20 + b * 145, y1 + 28, 4, grid=False)
        d.text((20 + b * 145, y1 + 28 + 68), 'cue' if b == 0 else f'ball {b}', font=fs, fill=DIM)
    y2 = 520
    d.text((20, y2), 'The sheet: shift 0-7 down, ball 0-6 across:', font=f, fill=FG)
    for s in range(8):
        d.text((20, y2 + 30 + s * 26 + 6), f'{s}', font=fs, fill=DIM)
        for b in range(7):
            draw_sprite(d, mem, 0xD000 + 48 * (7 * s + b), 40 + b * 56, y2 + 30 + s * 26, 2, grid=False)
    tx = 500
    notes = ['How to read:',
             '- The top two rows: ball 1 at shifts 0-7, 5 x scale.',
             '  The 15 x 15 ball moves one pixel right per shift;',
             '  the third byte fills as it moves.',
             '- No mask: DrawBall XORs the 3 bytes of each line',
             '  onto the screen. A second XOR at the same place',
             '  erases exactly; where two balls overlap their',
             '  ink cancels for a frame.',
             '- Line 16 of every sprite is empty, so a draw of',
             '  15 lines (y AND 7 not 0) loses nothing.',
             '- 2688 bytes buy a draw with no shifting at run time.',
             '',
             'python3 tools/fig_render.py sprites',
             '  (from work/mkgame/original.bin)']
    for i, t in enumerate(notes):
        d.text((tx, y2 + 30 + i * 17), t, font=fs, fill=DIM if t.startswith('python3') or t.startswith('  (') else FG)
    img.save(a.out)


# ---------------------------------------------------------------------------------------------------------------
def fig_split(a):
    """One ball of a real frame: the sprite, its address, and the three parts over the character rows."""
    f, fs, ft = fonts()
    s = vplib.session(a.work)
    shot = vplib.read(s, a.at, 0x4000, 6912)
    rec = vplib.read(s, a.at, 0x8A88, 14)
    mem = image()
    sx, sy = rec[10], rec[11]
    x, y = rec[1], rec[3]
    shift = sx & 7
    idx = 7 * shift + 0
    addr = 0xD000 + 48 * idx
    img = Image.new('RGB', (W, 640), BG)
    d = ImageDraw.Draw(img)
    header(d, 'One cue ball draw: the sprite chosen, three parts over the cell rows',
           f'w1 frame {a.at}: the cue ball record $8A88, sprite position (+10, +11) = ({sx}, {sy})', f, ft)
    # screen crop 6 cells x 4 rows around the sprite, scale 12
    cx0, cy0 = (sx // 8) - 1, (sy // 8) - 1
    sc = 12
    scr = K.render_screen(shot, 0)
    crop = scr.crop((cx0 * 8, cy0 * 8, cx0 * 8 + 48, cy0 * 8 + 32)).resize((48 * sc, 32 * sc), Image.NEAREST)
    ox, oy = 20, 80
    img.paste(crop, (ox, oy))
    for c in range(49):
        d.line([(ox + c * sc, oy), (ox + c * sc, oy + 32 * sc)], fill=(170, 170, 170) if c % 8 else (40, 40, 40),
               width=1 if c % 8 else 2)
    for r in range(33):
        d.line([(ox, oy + r * sc), (ox + 48 * sc, oy + r * sc)], fill=(170, 170, 170) if r % 8 else (40, 40, 40),
               width=1 if r % 8 else 2)
    # parts
    top = sy - cy0 * 8
    left = sx - cx0 * 8
    first = 8 - (sy & 7)
    parts = [(0, first), (first, first + 8), (first + 8, 16 if (sy & 7) == 0 else 15)]
    for i, (p0, p1) in enumerate(parts):
        if p1 <= p0:
            continue
        c = [COLS[1], COLS[4], COLS[6]][i]
        d.rectangle([ox + (left - (sx & 7) + 0) * sc - 2 + (sx & 7) * 0, oy + (top + p0) * sc,
                     ox + (left - (sx & 7) + 24) * sc + 2, oy + (top + p1) * sc], outline=c, width=3)
    tx = 620
    lines = [f'Record $8A88 (the cue ball):',
             f'  x = {x}, y = {y} (the centre)',
             f'  +10/+11 = ({sx}, {sy}) = centre - 7',
             '',
             f'shift = x AND 7 = {sx} AND 7 = {shift}',
             f'index = 7 x {shift} + 0 = {idx}',
             f'source = $D000 + 48 x {idx} = ${addr:04X}',
             f'target = ScreenCell(y {sy}, x {sx})',
             f'  + (y AND 7) = {sy & 7} lines down',
             f'  column {sx // 8}, 3 bytes wide',
             '',
             'XorSpriteLines $959F in three parts:']
    for i, (p0, p1) in enumerate(parts):
        lines.append(f'  part {i + 1}: lines {p0}-{p1 - 1} ({p1 - p0}), row {(sy + p0) // 8}')
    lines += ['', 'The boxes on the crop are the parts;', 'thick lines are the character cells.',
              f'Byte columns start at x = {(sx // 8) * 8}: the sprite',
              f'is pre-shifted {shift} pixels inside them.', '',
              f'python3 tools/fig_render.py split', f'  --work work/docs/vpB/w1 --at {a.at}']
    for i, t in enumerate(lines):
        col = [COLS[1], COLS[4], COLS[6]][i - 12] if 12 <= i < 15 else (DIM if t.strip().startswith(('python3', '--')) else FG)
        d.text((tx, 80 + i * 19), t, font=f, fill=col)
    img.save(a.out)


# ---------------------------------------------------------------------------------------------------------------
def fig_tables(a):
    f, fs, ft = fonts()
    shot = screen_of(a.work, a.at)
    large = K.render_screen(shot, 0).crop((0, 40, 256, 192))
    small = Image.open(os.path.join(CASE, 'docs', 'img', 'play', 'm1-7998-small-pockets.png')).convert('RGB')
    small = small.resize((256, 192), Image.NEAREST).crop((0, 40, 256, 192))
    img = Image.new('RGB', (W, 880), BG)
    d = ImageDraw.Draw(img)
    header(d, 'Two tables from one routine: Pockets $B8BC moves where the cushions start and stop',
           f'left: large pockets (w1 frame {a.at}); right: small pockets (m1 frame 7998); 2 x scale', f, ft)
    img.paste(large.resize((512, 304), Image.NEAREST), (10, 80))
    img.paste(small.resize((512, 304), Image.NEAREST), (528, 80))
    d.text((10, 390), 'large ($B8BC <> 0, key L)', font=f, fill=FG)
    d.text((528, 390), 'small ($B8BC = 0, key S)', font=f, fill=FG)
    # the difference in the cushion bands, the top half of the table (y 44-115), 4 x
    zs = 4
    diff = Image.new('RGB', (256, 72), (245, 245, 245))
    dp = diff.load()
    lp, sp = large.load(), small.load()
    for yy in range(72):
        y = yy + 44
        for x in range(256):
            band = y < 60 or x < 12 or x > 243
            if not band:
                continue
            a1 = lp[x, yy + 4] == (0, 0, 0)
            b1 = sp[x, yy + 4] == (0, 0, 0)
            dp[x, yy] = (60, 60, 60) if a1 and b1 else (214, 39, 40) if a1 else (31, 119, 180) if b1 else (205, 240, 205)
    img.paste(diff.resize((256 * zs, 72 * zs), Image.NEAREST), (13, 420))
    d.text((13, 712 - 6), 'Above, 4 x: y 44-115. Dark = black in both; blue = cushion only with small pockets; red = the cursor.', font=fs, fill=FG)
    notes = ['How to read: the top row is the whole table; the bottom strip is where the two differ.',
             'Large: the long cushions run x 19+i..114 and 141..236-i; small: 15+i..117 and 138..240-i (i = the line '
             '0-8).',
             'The middle gap is x 115-140 (large) or 118-137 (small). The side cushions start at y 67 (large) or 63.',
             'Every run is one XorLine $93B3 call (D = y, E = x, B = length): 4 x 9 sloped lines, 2 x (9 + 88 + 9) '
             'side lines,',
             'the frame (2 x 2 runs of 128, 2 x 134 one-pixel runs).',
             'python3 tools/fig_render.py tables --work work/docs/vpB/w1 --at 1060']
    for i, t in enumerate(notes):
        d.text((10, 734 + i * 22), t, font=fs, fill=DIM if t.startswith('python3') else FG)
    img.save(a.out)


# ---------------------------------------------------------------------------------------------------------------
def sext2(v):
    return v - 4 if v & 2 else v


def pen_trace(mem):
    x, y, down = 16, 128, False
    pts, moves, dots, ups = [], [], [], []
    i = 0xDA80
    n_cmd = 0
    while True:
        b = mem[i]
        i += 1
        n_cmd += 1
        if b >> 4 == 0:
            if b == 0:
                break
            if b == 1:
                down = False
                ups.append((x, y))
            elif b == 2:
                down = True
            elif b == 3:
                dx = mem[i] - 256 if mem[i] > 127 else mem[i]
                dy = mem[i + 1] - 256 if mem[i + 1] > 127 else mem[i + 1]
                i += 2
                dots.append((x + dx, y + dy))
            continue
        dy, dx, n = sext2(b >> 6), sext2((b >> 4) & 3), b & 15
        for _ in range(n):
            if down:
                pts.append((x, y - 1, len(moves)))
            nx, ny = x + dx, y + dy
            moves.append((x, y, nx, ny, down))
            x, y = nx, ny
    return pts, moves, dots, n_cmd, i - 0xDA80


def fig_pen(a):
    f, fs, ft = fonts()
    mem = image()
    pts, moves, dots, ncmd, nbytes = pen_trace(mem)
    shot = screen_of(a.work, a.at)
    img = Image.new('RGB', (W, 900), BG)
    d = ImageDraw.Draw(img)
    header(d, 'The signature is a pen path: 378 bytes of moves replayed one pixel a frame',
           f'SignatureScript $DA80 decoded: {ncmd} commands, {len(moves)} steps; the pen starts at (16, 128)', f, ft)
    # decoded path, x 8-192, y 112-152, scale 5
    sc, X0, Y0 = 5, 10, 70
    xmin, ymin = 8, 114
    d.rectangle([X0, Y0, X0 + 200 * sc, Y0 + 38 * sc], fill=(255, 255, 255), outline=GRID)
    total = len(moves)
    for (x0, y0, x1, y1, down) in moves:
        if not down:
            d.line([(X0 + (x0 - xmin) * sc + 2, Y0 + (y0 - ymin) * sc + 2),
                    (X0 + (x1 - xmin) * sc + 2, Y0 + (y1 - ymin) * sc + 2)], fill=(190, 190, 190), width=1)
    for (x, y, k) in pts:
        t = k / max(1, total - 1)
        c = (int(30 + 200 * t), int(80 + 60 * (1 - t)), int(220 - 180 * t))
        d.rectangle([X0 + (x - xmin) * sc, Y0 + (y - ymin) * sc, X0 + (x - xmin) * sc + sc - 1,
                     Y0 + (y - ymin) * sc + sc - 1], fill=c)
    for (x, y) in dots:
        d.ellipse([X0 + (x - xmin) * sc - 3, Y0 + (y - ymin) * sc - 3, X0 + (x - xmin) * sc + sc + 2,
                   Y0 + (y - ymin) * sc + sc + 2], outline=COLS[0], width=2)
    d.text((X0, Y0 + 38 * sc + 6), 'Ink pixels coloured by step (blue first, red last); grey = pen-up moves; red '
           'rings = dot commands (3 dx dy). x 8-208, y 114-152.', font=fs, fill=FG)
    # the real screen with the pen
    scr = K.render_screen(shot, 0).crop((0, 100, 256, 192)).resize((768, 276), Image.NEAREST)
    img.paste(scr, (10, 300))
    d.text((10, 580), f'm1 frame {a.at}: the pen on the screen, 3 x scale (nib, 45-degree shaft, cap); '
           'it writes at the nib\'s tip, (x, y - 1).', font=fs, fill=FG)
    # the byte format
    bx, by = 10, 615
    d.text((bx, by), 'One byte a command:', font=f, fill=FG)
    cells = [('7-6', 'dy', COLS[1]), ('5-4', 'dx', COLS[2]), ('3-0', 'n steps', COLS[4])]
    for i, (bits, name, c) in enumerate(cells):
        d.rectangle([bx + i * 150, by + 26, bx + i * 150 + 140, by + 70], outline=c, width=3)
        d.text((bx + i * 150 + 8, by + 30), f'bits {bits}', font=fs, fill=FG)
        d.text((bx + i * 150 + 8, by + 48), name, font=f, fill=c)
    rules = ['High nibble 0: a command. 0 end, 1 pen up, 2 pen down, 3 dot (two signed bytes dx, dy follow).',
             'Otherwise a move: dy and dx are 2-bit two\'s complement (0, +1, -2, -1; the script uses 0, +1, -1),',
             'n steps of one pixel, one frame each; the pen plots (x, y - 1) before each step while it is down.',
             f'Example: the first bytes 02 C4 44 13: pen down; $C4 = dy -1, dx 0, 4 steps up; $44 = dy +1, dx 0, 4 '
             f'down; $13 = dx +1, 3 right.',
             f'The script: {nbytes} bytes, {ncmd} commands, {len(moves)} steps = {len(moves)} frames, '
             f'{len(moves) / 50:.1f} s at 50 Hz (plus the commands, which take no frame).',
             'python3 tools/fig_render.py pen --work work/docs/vpB/m1 --at 900']
    for i, t in enumerate(rules):
        d.text((bx, by + 84 + i * 22), t, font=fs, fill=DIM if t.startswith('python3') else FG)
    img.save(a.out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('figure', choices=['layout', 'sprites', 'split', 'tables', 'pen'])
    p.add_argument('--out', required=True)
    p.add_argument('--work')
    p.add_argument('--at', type=int, default=1060)
    a = p.parse_args()
    {'layout': fig_layout, 'sprites': fig_sprites, 'split': fig_split, 'tables': fig_tables, 'pen': fig_pen}[
        a.figure](a)
    print(a.out)


if __name__ == '__main__':
    main()
