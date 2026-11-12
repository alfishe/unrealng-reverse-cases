#!/usr/bin/env python3
"""The figures of doc 06 (the graphics): the logo, the rhombus phases, the column order, the stars, the twinkle, the
corners and ScreenCopy.

    python3 tools/fig_graphics.py --work work/docs/zbA/c1 [--frame 1000]

--work is an instance holding c1 (re_session.py open); the moment is kept in work/docs/figcache/, so a second run
needs no instance. Writes docs/img/graphics/*.png.
"""
import argparse

from PIL import Image, ImageDraw

import figzyx as Z

LOGO, LOGO_ATTR = 0xA900, 0xAC20
ROMB, PHASES_A, PHASES_B = 0x6E98, 0x7800, 0x8A00
PHASE_ORDER, COLUMN_ORDER, OFFSETS = 0x6ADD, 0x6B74, 0x6B9C
STARS = 0xAC84
TWINKLE = 0x6F60
CORNERS = 0xADF4
SCREEN_COPY = 0xE000


def attr_colours(attr):
    bright = attr & 0x40
    return Z.K.ink_colour(attr & 7, bright), Z.K.ink_colour((attr >> 3) & 7, bright)


def coloured_sprite(data, attrs, cols, scale):
    """A 40x40 sprite coloured cell by cell from a 5x5 slice of attributes"""
    img = Image.new('RGB', (40 * scale, 40 * scale))
    px = img.load()
    for y in range(40):
        for x in range(40):
            ink, paper = attr_colours(attrs[(y // 8) * cols + x // 8])
            on = data[y * 5 + x // 8] & (0x80 >> (x % 8))
            for dy in range(scale):
                for dx in range(scale):
                    px[x * scale + dx, y * scale + dy] = ink if on else paper
    return img


def fig_logo(img64):
    """The four logo sprites, plain and with LogoAttributes, labelled"""
    scale = 5
    out, d = Z.canvas(570)
    Z.title(d, 'The ZYX logo: four 40 x 40 sprites side by side, the Z takes two (Logo $A900, 800 bytes)',
            'top: the bytes as stored (ink white); bottom: as DrawScreen prints them, with LogoAttributes $AC20 '
            '(5 rows of 20 cells)')
    f = Z.font(13)
    attrs = img64[LOGO_ATTR:LOGO_ATTR + 100]
    x0 = 25
    for i in range(4):
        data = img64[LOGO + 200 * i:LOGO + 200 * i + 200]
        x = x0 + i * (40 * scale + 8)
        out.paste(Z.sprite(data, 40, 40, scale=scale), (x, 80))
        d.text((x, 62), f'{["Logo", "LogoPart2", "LogoPart3", "LogoPart4"][i]} ${LOGO + 200 * i:04X}', fill=Z.TEXT,
               font=f)
        sl = [attrs[r * 20 + i * 5 + c] for r in range(5) for c in range(5)]
        out.paste(coloured_sprite(data, sl, 5, scale), (x, 320))
        d.text((x, 302), f'at ${0x4006 + 5 * i:04X}, cols {6 + 5 * i}-{10 + 5 * i}', fill=Z.TEXT, font=f)
    d.text((x0, 290 - 4), '', fill=Z.DIM, font=f)
    d.text((x0, 530), 'The four sprites touch: one 160 x 40 picture at columns 6-25, rows 0-4. The colour is only in',
           fill=Z.DIM, font=f)
    d.text((x0, 546), 'the attributes: white, bright white, cyan and bright cyan cells give the letters their two '
                      'tones.', fill=Z.DIM, font=f)
    Z.save(out, 'docs/img/graphics/logo.png')


def fig_phases(img64, mem):
    """The 17 phases of each set, as the menu built them (memory of the recording)"""
    scale = 3
    cell = 40 * scale + 12
    per_row = 8
    out, d = Z.canvas(150 + 4 * (cell + 26) + 150)
    Z.title(d, 'The rhombus phases as BuildRombPhases, MirrorSprite and RotateSprite left them (c1 frame 1000)',
            'set A $7800 turns about the vertical axis, set B $8A00 about the horizontal one; phase n at set + n x 256;'
            ' 0-7 narrowing, 9-16 the mirrors')
    f = Z.font(12)
    y = 70
    for name, base in (('set A', PHASES_A), ('set B', PHASES_B)):
        for k, n in enumerate([m for m in range(17) if m != 8]):
            row, col = divmod(k, per_row)
            x = 20 + col * (cell - 6)
            yy = y + row * (cell + 26)
            data = mem[base + 256 * n:base + 256 * n + 200]
            ink = (240, 220, 80) if n <= 8 else (110, 210, 240)
            spr = Z.sprite(data, 40, 40, ink=ink, paper=(0, 0, 0), scale=scale)
            out.paste(spr, (x, yy + 18))
            d.rectangle([x - 1, yy + 17, x + 40 * scale, yy + 18 + 40 * scale], outline=(70, 70, 90))
            d.text((x, yy), f'{name} {n:2d} ${base + 256 * n:04X}', fill=Z.TEXT, font=f)
        y += 2 * (cell + 26)
    order = img64[PHASE_ORDER:PHASE_ORDER + 32]
    d.text((20, y + 6), 'PhaseOrder $6ADD, the phase shown at each of the 32 steps of a turn:', fill=Z.TEXT,
           font=Z.font(13))
    for i, p in enumerate(order):
        x = 20 + i * 31
        colour = (240, 220, 80) if p <= 8 else (110, 210, 240)
        d.rectangle([x, y + 28, x + 28, y + 52], fill=(30, 30, 40), outline=(70, 70, 90))
        d.text((x + 6, y + 32), f'{p:2d}', fill=colour, font=Z.font(13))
        d.text((x + 6, y + 56), f'{i}', fill=Z.DIM, font=Z.font(10))
    d.text((20, y + 80), 'yellow: phases 0-7 (the front face narrowing); blue: 9-16 (the back face, MirrorSprite of '
                         '0-7). Phase 8 ($8000, $9200), the edge-on one, is all zeros:', fill=Z.DIM, font=f)
    d.text((20, y + 98), 'not drawn here; steps 8 and 24 show it, so the rhombus vanishes for one step twice a turn.',
           fill=Z.DIM, font=f)
    y += 18
    d.text((20, y + 98), 'drawn by tools/fig_graphics.py from the memory of c1 at frame 1000 (TTD memory_at)',
           fill=Z.DIM, font=f)
    Z.save(out, 'docs/img/graphics/rhombus-phases.png')


def fig_columns(img64):
    """Which phase drops each column of the rhombus: the worked example of BuildRombPhases"""
    scale = 9
    order = img64[COLUMN_ORDER:COLUMN_ORDER + 40]
    offsets = img64[OFFSETS:OFFSETS + 9]
    src = img64[ROMB:ROMB + 200]
    # the phase that first drops column c: kept by phases 0..k-1 where k = 8 - rank // 5
    drop = {}
    for rank, c in enumerate(order):
        drop[c] = 8 - rank // 5          # kept in phases 0 .. drop-1
    colours = [(230, 90, 80), (250, 150, 60), (240, 200, 70), (160, 220, 80), (90, 200, 120), (70, 210, 220),
               (90, 150, 250), (200, 110, 230)]
    out, d = Z.canvas(40 * scale + 320)
    Z.title(d, 'BuildRombPhases: phase k keeps the first 5 x (8 - k) columns of RombColumnOrder, packed and centred',
            'left: RombSource $6E98, each pixel column coloured by the last phase that keeps it; right: phase 3 '
            'packed (25 columns from pixel 7)')
    f = Z.font(12)
    x0, y0 = 20, 80
    for y in range(40):
        for x in range(40):
            on = src[y * 5 + x // 8] & (0x80 >> (x % 8))
            col = colours[drop[x] - 1]
            fill = col if on else tuple(v // 6 for v in col)
            d.rectangle([x0 + x * scale, y0 + y * scale, x0 + x * scale + scale - 2, y0 + y * scale + scale - 2],
                        fill=fill)
    for x in range(40):
        d.text((x0 + x * scale + 1, y0 + 40 * scale + 4), f'{drop[x] - 1}', fill=colours[drop[x] - 1],
               font=Z.font(10))
    d.text((x0, y0 + 40 * scale + 20), 'the number under a column: the last phase that keeps it (7 = kept by '
                                       'every phase 0-7)', fill=Z.DIM, font=f)
    # phase 3 packed
    k = 3
    keep = sorted(order[:5 * (8 - k)])
    off = offsets[8 - (8 - k)] if False else offsets[8 - k]
    x1 = x0 + 40 * scale + 40
    scale2 = 9
    for y in range(40):
        for i, c in enumerate(keep):
            on = src[y * 5 + c // 8] & (0x80 >> (c % 8))
            col = colours[drop[c] - 1]
            fill = col if on else tuple(v // 6 for v in col)
            xx = x1 + (off + i) * scale2
            d.rectangle([xx, y0 + y * scale2, xx + scale2 - 2, y0 + y * scale2 + scale2 - 2], fill=fill)
    d.rectangle([x1 - 1, y0 - 1, x1 + 40 * scale2, y0 + 40 * scale2], outline=(70, 70, 90))
    d.text((x1, y0 + 40 * scale2 + 4), f'phase 3: {len(keep)} columns from pixel {off} '
                                       f'(RombPhaseOffsets[{8 - k}] = {off})', fill=Z.TEXT, font=f)
    yy = y0 + 40 * scale + 50
    d.text((x0, yy), 'RombColumnOrder $6B74 (40 values, 5 a phase):', fill=Z.TEXT, font=Z.font(13))
    for i, c in enumerate(order):
        x = x0 + i * 25
        d.rectangle([x, yy + 22, x + 23, yy + 44], fill=(30, 30, 40))
        d.text((x + 3, yy + 26), f'{c:2d}', fill=colours[drop[c] - 1], font=Z.font(12))
    d.text((x0, yy + 50), 'phase 7 keeps the first 5 (8 16 19 23 31), phase 6 the first 10, ... phase 0 all 40.',
           fill=Z.DIM, font=f)
    d.text((x0, yy + 68), 'RombPhaseOffsets $6B9C: ' + ' '.join(str(v) for v in offsets) + ' (phase k reads index '
                          '8 - k: the narrowed picture stays centred).', fill=Z.DIM, font=f)
    d.text((x0, yy + 86), 'The order is scattered: each narrower phase loses columns all across the picture, not '
                          'from one side, so the rhombus looks turned, not cropped.', fill=Z.DIM, font=f)
    Z.save(out, 'docs/img/graphics/rhombus-columns.png')


def fig_stars(img64, mem, frame):
    """The star field: 10 near stars of 2 x 2 pixels (StarsA + StarsB) and 20 far ones of 1 pixel (StarsC)"""
    scale = 3
    out, d = Z.canvas(192 * scale + 150)
    Z.title(d, f'The star field: 10 near stars (2 x 2 pixels) and 20 far ones (1 pixel), at the start and at c1 '
               f'frame {frame}',
            'circles: the start (the image); dots: the frame; near: StarsA $AC84 + StarsB $ACFC, far: StarsC $AD74')
    scr = Z.screen(mem).resize((256 * scale, 192 * scale), Image.NEAREST)
    scr = Image.eval(scr, lambda v: v // 3)
    x0, y0 = 20, 70
    out.paste(scr, (x0, y0))
    near, far = (255, 200, 40), (60, 130, 255)

    def place(rec):
        addr = rec[0] | rec[1] << 8
        bit = (rec[4] >> 3) & 7         # BIT n,(HL) = $46 | n << 3
        return (addr & 31) * 8 + (7 - bit), Z.K.screen_line(addr)

    for t, colour, size in ((0, near, 2), (2, far, 1)):
        step = 2 if t == 0 else 1       # a near star is a pair of records side by side
        for i in range(0, 20, step):
            a = STARS + 120 * t + 6 * i
            x, y = place(img64[a:a + 6])
            cx, cy = x0 + x * scale + size * scale // 2, y0 + y * scale + size * scale // 2
            r = 6 if size == 2 else 5
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=colour)
            x, y = place(mem[a:a + 6])
            d.rectangle([x0 + x * scale, y0 + y * scale, x0 + (x + size) * scale - 1, y0 + (y + size) * scale - 1],
                        fill=colour)
    f = Z.font(12)
    tx = x0 + 256 * scale + 20
    lines = ['A star record (6 bytes):', '+0 +1 screen address', '+2 RES n,(HL) 2nd byte',
             '+3 SET n,(HL) 2nd byte', '+4 BIT n,(HL) 2nd byte', '+5 pixel under it (0/1)', '',
             'near (yellow): A, B', 'records x, x+1 in A,', 'the same one row', 'lower in B: 2 x 2;',
             '2 rows (2 calls each)', 'every 2nd pass', '', 'far (blue): C', '1 pixel, 1 row', 'every 4th pass']
    for i, line in enumerate(lines):
        d.text((tx, y0 + i * 18), line, fill=Z.TEXT if i in (0, 7, 14) else Z.DIM, font=f)
    d.text((x0, y0 + 192 * scale + 10), f'The main loop runs from frame 890: by frame {frame} a near star has '
                                        'fallen 4 times as far as a far one (2 rows every 2nd pass against 1 every '
                                        '4th), wrapping', fill=Z.DIM, font=f)
    d.text((x0, y0 + 192 * scale + 28), 'from the bottom row to the top. Drawn by tools/fig_graphics.py from the '
                                        'image and c1 (TTD memory_at).', fill=Z.DIM, font=f)
    Z.save(out, 'docs/img/graphics/stars.png')


def fig_twinkle(img64):
    """The four twinkle frames and the 8-step cycle"""
    scale = 10
    out, d = Z.canvas(16 * scale + 250)
    Z.title(d, 'The twinkle: TwinkleSprites $6F60, four 16 x 16 frames ORed onto the screen',
            'frames 0 1 2 3 3 2 1 0, one every 4 interrupts: lit 30 frames, then 9 dark (erased at $3E, held 8): 39')
    f = Z.font(13)
    for i in range(4):
        data = img64[TWINKLE + 32 * i:TWINKLE + 32 * i + 32]
        x = 20 + i * (16 * scale + 30)
        out.paste(Z.sprite(data, 16, 16, scale=scale), (x, 90))
        Z.grid(out, scale, colour=(45, 45, 60), x0=x, y0=90, w=16 * scale, h=16 * scale)
        d.text((x, 70), f'frame {i}  ${TWINKLE + 32 * i:04X}', fill=Z.TEXT, font=f)
    y = 90 + 16 * scale + 20
    seq = [0, 1, 2, 3, 3, 2, 1, 0]
    d.text((20, y), 'TwinkleClock $DEAC (+2 a frame):', fill=Z.TEXT, font=f)
    for i, s in enumerate(seq):
        x = 20 + i * 120
        d.rectangle([x, y + 22, x + 112, y + 60], fill=(30, 30, 40), outline=(70, 70, 90))
        d.text((x + 6, y + 26), f'clock ${i * 8 + 2:02X}-${min(i * 8 + 8, 0x3C):02X}', fill=Z.DIM, font=Z.font(11))
        d.text((x + 6, y + 42), f'frame {s}', fill=(240, 220, 80), font=f)
    d.text((20, y + 70), 'bits 3-4 of the clock pick the frame, bit 5 counts it back down; bits 6-7 pick one of the '
                         'four places in Randoms $ADEC.', fill=Z.DIM, font=Z.font(12))
    Z.save(out, 'docs/img/graphics/twinkle.png')


def fig_corners(img64, mem):
    """The four corners' attributes"""
    cols = img64[CORNERS:CORNERS + 5]
    scale = 26
    out, d = Z.canvas(420)
    Z.title(d, 'ColourCorners $6CBF: the four 5 x 5 corners from the five CornerColours $ADF4',
            'top left, bottom right (ColourCornerRows): a colour a row; top right, bottom left (ColourCornerColumns):'
            ' a colour a column')
    f = Z.font(12)
    corners = [('top left $5800', 0, 0), ('top right $581B', 0, 27), ('bottom left $5A60', 19, 0),
               ('bottom right $5A7B', 19, 27)]
    scr = Z.screen(mem)
    for i, (name, row, col) in enumerate(corners):
        x = 20 + i * (5 * scale + 120)
        y = 80
        d.text((x, y - 18), name, fill=Z.TEXT, font=f)
        for r in range(5):
            for c in range(5):
                a = mem[0x5800 + (row + r) * 32 + col + c]
                ink, paper = attr_colours(a)
                d.rectangle([x + c * scale, y + r * scale, x + c * scale + scale - 2, y + r * scale + scale - 2],
                            fill=ink)
                d.text((x + c * scale + 2, y + r * scale + 6), f'{a:02X}', fill=(0, 0, 0), font=Z.font(10))
        crop = scr.crop((col * 8, row * 8, col * 8 + 40, row * 8 + 40)).resize((5 * scale, 5 * scale),
                                                                               Image.NEAREST)
        out.paste(crop, (x, y + 5 * scale + 30))
        d.text((x, y + 10 * scale + 34), 'on the screen', fill=Z.DIM, font=f)
    d.text((20, 395), 'CornerColours: ' + ' '.join(f'${v:02X}' for v in cols) + ' = white, yellow, bright yellow, '
                      'yellow, white: a light band across each rhombus (c1 frame 1000)', fill=Z.DIM, font=f)
    Z.save(out, 'docs/img/graphics/corners.png')


def fig_screencopy(mem, frame):
    """The screen against ScreenCopy at one frame, and where they differ"""
    scale = 2
    out, d = Z.canvas(192 * scale + 130)
    Z.title(d, f'The screen $4000 against ScreenCopy $E000 at c1 frame {frame}',
            'left: what the beam shows; middle: the clean copy the twinkle, the glint and the spin restore from; '
            'right: the pixels that differ (red: only on the screen)')
    a = Z.screen(mem, 0x4000)
    b = Z.screen(mem, SCREEN_COPY)
    diff = Image.new('RGB', (256, 192))
    pa, pb, pd = a.load(), b.load(), diff.load()
    for y in range(192):
        for x in range(256):
            if pa[x, y] != pb[x, y]:
                pd[x, y] = (255, 80, 60)
            else:
                pd[x, y] = tuple(v // 4 for v in pa[x, y])
    f = Z.font(13)
    for i, (img, name) in enumerate(((a, 'screen $4000'), (b, 'ScreenCopy $E000'), (diff, 'the difference'))):
        x = 10 + i * (256 * scale + 8)
        if x + 256 * scale > Z.WIDTH:
            break
    # three at 2x do not fit 1050: use 1.33x via two rows? keep two big and the difference small
    big = 2
    out, d = Z.canvas(192 * big + 120 + 192 + 10)
    Z.title(d, f'The screen $4000 against ScreenCopy $E000 at c1 frame {frame}',
            'the clean copy the twinkle, the glint and the spin restore from; the stars and the rhombi never touch it')
    out.paste(a.resize((256 * big, 192 * big), Image.NEAREST), (10, 70))
    out.paste(b.resize((256 * big, 192 * big), Image.NEAREST), (10 + 256 * big + 6, 70))
    d.text((10, 70 + 192 * big + 4), 'screen $4000', fill=Z.TEXT, font=f)
    d.text((10 + 256 * big + 6, 70 + 192 * big + 4), 'ScreenCopy $E000', fill=Z.TEXT, font=f)
    y = 70 + 192 * big + 26
    out.paste(diff, (10, y))
    n = sum(1 for yy in range(192) for xx in range(256) if pd[xx, yy] == (255, 80, 60))
    d.text((280, y + 10), f'the difference: {n} pixels (red) whose colour differs', fill=Z.TEXT, font=f)
    d.text((280, y + 30), 'the stars, the rhombi in their current phase', fill=Z.DIM, font=f)
    d.text((280, y + 48), '(ScreenCopy keeps phase 0 of each), the twinkle', fill=Z.DIM, font=f)
    d.text((280, y + 66), 'and the cursor colour (the text is in both).', fill=Z.DIM, font=f)
    d.text((280, y + 96), 'drawn by tools/fig_graphics.py (TTD memory_at)', fill=Z.DIM, font=Z.font(12))
    Z.save(out, 'docs/img/graphics/screencopy.png')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('--frame', default='1000')
    args = p.parse_args()
    img64 = Z.image()
    mem = Z.moment(args.work, args.frame)
    fig_logo(img64)
    fig_phases(img64, mem)
    fig_columns(img64)
    fig_stars(img64, mem, int(str(args.frame).split(':')[0]))
    fig_twinkle(img64)
    fig_corners(img64, mem)
    fig_screencopy(mem, args.frame)


if __name__ == '__main__':
    main()
