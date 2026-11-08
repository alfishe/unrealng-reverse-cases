#!/usr/bin/env python3
"""The figures of docs/lenslok.md, from the c1 recording's screens (work/lenslok/*.scr, memory_at $4000 of each frame)
and the model of tools/lenslok.py.

    python3 tools/fig_lenslok.py [--scr work/lenslok] [--out docs/img/lenslok]

- steps.png: the three screens of one pass in c1 (the size screen, the code half drawn, the code screen);
- unscramble.png: the code's 12 glyph columns, the 14 slices they are drawn into, and what the lens puts back;
- model.png: the emulator's code screen, the model's, and the difference;
- optics.png: the lens seen from above: each prism turns the eye's line to one slice;
- slide.gif: the lens moved sideways over the real code screen: the code reads only when centred;
- width.gif: the screen drawn at other widths than the lens was made for (the size screen's job).
"""
import argparse
import colorsys
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import lenslok as L  # noqa: E402

BG = (24, 24, 28)
FG = (235, 235, 235)
DIM = (70, 70, 78)
YEL = (255, 210, 60)
CODE = b'si'
MARKS = (0x32, 0x62)
WIDTH = 144


def hue(i, n=12, v=1.0):
    r, g, b = colorsys.hsv_to_rgb(i / n, 0.65, v)
    return int(r * 255), int(g * 255), int(b * 255)


def fnt(size=12):
    for p in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def scr_image(scr, scale=2):
    return L.image_of(L.screen_pixels(scr), scale)


def wrap(d, text, font, width):
    lines, line = [], ''
    for word in text.split():
        cand = (line + ' ' + word).strip()
        if d.textlength(cand, font=font) > width and line:
            lines.append(line)
            line = word
        else:
            line = cand
    return lines + [line]


def steps(src, out):
    """a row per frame: the top of the screen at 2x (where the code is drawn), what it shows beside it"""
    frames = [('15750', 'frame 15750, the size screen: the test code "OK", already scrambled, under the bar; 5 and 8 '
                        'below it (cut off here) widen or narrow it until the lens reads OK'),
              ('15880', 'frame 15880: the code screen while its rows are drawn from the top down'),
              ('15900', 'frame 15900: the finished code screen; through the lens it reads "si"')]
    f, f17 = fnt(15), fnt(17)
    W, crop = 900, (0, 60, 512, 228)
    rh = crop[3] - crop[1]
    img = Image.new('RGB', (W, 40 + 3 * (rh + 14)), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 9), 'One pass in c1: the size screen, the code drawn row by row, the code', font=f17, fill=FG)
    for i, (fr, cap) in enumerate(frames):
        y = 40 + i * (rh + 14)
        img.paste(scr_image(open(os.path.join(src, fr + '.scr'), 'rb').read()).crop(crop), (10, y))
        for k, line in enumerate(wrap(d, cap, f, W - 540 - 10)):
            d.text((540, y + 10 + k * 21), line, font=f, fill=FG)
    img.save(out)


def band_rows(width=WIDTH):
    s, sl = L.slices(width)
    return s, sl, max(1, 20 * s // 100)


def unscramble(out):
    """three panels joined by lines: glyph columns -> slices -> lens apertures"""
    f, fs = fnt(13), fnt(11)
    font = L.font()
    rows = [L.glyph_bits(CODE, r, font) for r in range(8)]
    outs = [L.scramble(rows[r], r, MARKS) for r in range(8)]
    s, sl, h = band_rows()
    C = 16                      # cell size of the glyph panels
    SX = 7                      # screen pixels -> figure pixels
    gw = 12 * C + C             # glyph panel width (gap between the two characters)
    sx0 = 40
    scr_left = sl[0][0]
    scr_w = (sl[-1][0] + sl[-1][1] - scr_left) * SX
    W = max(scr_w + 2 * sx0, 2 * gw + 300, 760)
    Hh = 8 * C
    bh = 12                     # one band row
    y_a, y_b, y_c = 40, 40 + Hh + 110, 40 + Hh + 110 + 8 * bh + 110
    img = Image.new('RGB', (W, y_c + Hh + 40), BG)
    d = ImageDraw.Draw(img)

    def gx(col, x0):            # x of glyph column col (0..11) in a glyph panel
        return x0 + col * C + (C if col >= 6 else 0)
    ax0 = (W - gw) // 2
    d.text((12, y_a - 26), f'1. the code "{CODE.decode()}": columns 1-6 of each ROM-font glyph, 8 rows', font=f, fill=FG)
    for r in range(8):
        for c in range(12):
            col = hue(c) if rows[r][c] else DIM
            x = gx(c, ax0)
            d.rectangle([x + 1, y_a + r * C + 1, x + C - 2, y_a + (r + 1) * C - 2], fill=col if rows[r][c] else None,
                        outline=DIM)
    for c in range(12):
        d.text((gx(c, ax0) + 3, y_a + Hh + 2), str(c + 1), font=fs, fill=hue(c))

    d.text((12, y_b - 26), f'2. on the screen: 14 slices, 2 marks (m) + the 12 columns permuted; table $C7B6, x{SX} wide',
           font=f, fill=FG)
    for j, (x, w) in enumerate(sl):
        X = sx0 + (x - scr_left) * SX
        if j in (0, 13):
            colr = (150, 150, 150)
        else:
            colr = hue(PERM_INV[j])
        for r in range(8):
            on = outs[r][j]
            d.rectangle([X, y_b + r * bh, X + w * SX - 1, y_b + (r + 1) * bh - 2],
                        fill=colr if on else None, outline=DIM)
        lab = 'm' if j in (0, 13) else str(PERM_INV[j] + 1)
        d.text((X + 2, y_b + 8 * bh + 2), lab, font=fs, fill=colr)
    cx = sx0 + (128 - scr_left) * SX
    d.line([cx, y_b - 12, cx, y_b + 8 * bh + 16], fill=YEL, width=1)
    d.text((cx + 4, y_b - 16), 'x = 128', font=fs, fill=YEL)

    for c in range(12):        # column -> slice
        j = L.PERM[c]
        x, w = sl[j]
        X = sx0 + (x - scr_left) * SX + w * SX // 2
        d.line([gx(c, ax0) + C // 2, y_a + Hh + 16, X, y_b - 4], fill=hue(c, v=0.8), width=1)

    d.text((12, y_c - 26), '3. through the lens: aperture i looks at the slice that holds column i', font=f, fill=FG)
    for c in range(12):
        j = L.PERM[c]
        x, w = sl[j]
        X = sx0 + (x - scr_left) * SX + w * SX // 2
        d.line([X, y_b + 8 * bh + 18, gx(c, ax0) + C // 2, y_c - 4], fill=hue(c, v=0.8), width=1)
        for r in range(8):
            on = outs[r][j]
            xx = gx(c, ax0)
            d.rectangle([xx + 1, y_c + r * C + 1, xx + C - 2, y_c + (r + 1) * C - 2], fill=hue(c) if on else None,
                        outline=DIM)
    img.save(out)


PERM_INV = {L.PERM[c]: c for c in range(12)}   # slice index -> glyph column (0-based)


def model(src, out):
    scr = open(os.path.join(src, '15900.scr'), 'rb').read()
    emu = L.screen_pixels(scr)
    mod = L.draw(CODE, WIDTH, MARKS)
    box = (0, 0, 256, 176)       # the whole screen above the prompt line (rows 176-191)
    inbox = (lambda q: {p for p in q if box[0] <= p[0] < box[2] and box[1] <= p[1] < box[3]})
    emu_c, mod = inbox(emu), inbox(mod)
    diff = emu_c ^ mod
    both = emu_c & mod
    pts = emu_c | mod
    bx0, by0 = max(0, min(x for x, _ in pts) - 8), max(0, min(y for _, y in pts) - 8)
    bx1, by1 = min(256, max(x for x, _ in pts) + 9), min(176, max(y for _, y in pts) + 9)
    W = 900
    f, f17 = fnt(14), fnt(17)

    def panel(layers, S):
        im = Image.new('RGB', ((bx1 - bx0) * S, (by1 - by0) * S), (0, 0, 0))
        dd = ImageDraw.Draw(im)
        for q, col in layers:
            for x, y in q:
                if bx0 <= x < bx1 and by0 <= y < by1:
                    X, Y = (x - bx0) * S, (y - by0) * S
                    dd.rectangle([X, Y, X + S - 1, Y + S - 1], fill=col)
        return im

    big = max(1, (W - 24) // (bx1 - bx0))
    small = max(1, (W - 36) // 2 // (bx1 - bx0))
    tops = [(panel([(emu_c, FG)], small), f'emulator, c1 frame 15900: {len(emu_c)} px'),
            (panel([(mod, FG)], small), f'model, tools/lenslok.py: {len(mod)} px')]
    ov = panel([(both, FG), (emu_c - mod, (255, 80, 80)), (mod - emu_c, (80, 255, 120))], big)
    th = tops[0][0].height
    img = Image.new('RGB', (W, 40 + th + 30 + ov.height + 58), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 9), f'The model draws the emulator\'s code screen exactly: {len(both)} px in both, {len(diff)} differ',
           font=f17, fill=FG)
    for i, (im, cap) in enumerate(tops):
        x0 = 12 + i * (im.width + 12)
        img.paste(im, (x0, 40))
        d.text((x0, 40 + th + 5), cap, font=f, fill=DIM)
    y = 40 + th + 30
    img.paste(ov, (12, y))
    d.text((12, y + ov.height + 6), f'the two overlaid at {big}x (screen x {bx0}-{bx1 - 1}, y {by0}-{by1 - 1}): white '
           f'in both,', font=f, fill=DIM)
    d.text((12, y + ov.height + 28), f'red the emulator only ({len(emu_c - mod)} px), green the model only '
           f'({len(mod - emu_c)} px)', font=f, fill=DIM)
    img.save(out)
    return len(diff)


def optics(out):
    """top view: the eye above, the 12 prisms of the lens in a row, each line of sight bent to its slice"""
    s, sl, h = band_rows()
    f, fs = fnt(13), fnt(11)
    SX = 5
    left = sl[0][0] - 4
    span = (sl[-1][0] + sl[-1][1] + 4 - left) * SX
    W = max(span + 80, 780)
    img = Image.new('RGB', (W, 520), BG)
    d = ImageDraw.Draw(img)
    x0 = 40
    y_eye, y_lens, y_scr = 40, 230, 470
    ex = x0 + (128 - left) * SX
    d.ellipse([ex - 10, y_eye - 6, ex + 10, y_eye + 6], outline=FG)
    d.text((ex + 16, y_eye - 8), 'eye (one eye closed, at least a foot away)', font=f, fill=FG)
    # the lens: 12 equal apertures centred on x = 128, split in two halves of 6 like the two characters
    aw = (sl[-1][0] + sl[-1][1] - sl[0][0]) * SX * 0.8 / 13
    for c in range(12):
        j = L.PERM[c]
        x, w = sl[j]
        tx = x0 + (x - left) * SX + w * SX / 2
        lx = ex + (c - 5.5 + (0.5 if c >= 6 else -0.5)) * aw
        d.polygon([(lx - aw / 2 + 1, y_lens + 14), (lx + aw / 2 - 1, y_lens + 14), (lx + (tx - lx) * 0.08, y_lens - 14)],
                  outline=hue(c))
        d.line([ex, y_eye + 6, lx, y_lens - 14], fill=DIM)
        d.line([lx, y_lens + 14, tx, y_scr], fill=hue(c, v=0.85))
        d.text((lx - 4, y_lens + 18), str(c + 1), font=fs, fill=hue(c))
    d.text((12, y_lens - 40), 'lens: 12 prisms, each turning the line of sight by its own angle', font=f, fill=FG)
    for j, (x, w) in enumerate(sl):
        X = x0 + (x - left) * SX
        colr = (150, 150, 150) if j in (0, 13) else hue(PERM_INV[j])
        d.rectangle([X, y_scr, X + w * SX - 1, y_scr + 14], fill=colr)
    d.line([ex, y_scr - 8, ex, y_scr + 24], fill=YEL)
    d.text((12, y_scr + 22), 'screen: the 14 slices (grey: the two marks, which no prism looks at)', font=f, fill=FG)
    img.save(out)


def view_strip(px, draw_width, lens_width, dx, ap=10):
    """what the 12 apertures show when the lens (made for lens_width) sits dx pixels off centre on a screen drawn at
    draw_width; band area taken from the drawn screen"""
    s, sl, h = band_rows(draw_width)
    _, lsl, _ = band_rows(lens_width)
    top = 175 - (120 - h)
    rows = 8 * h
    img = Image.new('RGB', (12 * ap + ap, rows), BG)
    for c in range(12):
        x, w = lsl[L.PERM[c]]
        X = c * ap + (ap if c >= 6 else 0)
        for yy in range(rows):
            for k in range(ap):
                sx = x + dx + k * w // ap
                if (sx, top + yy) in px:
                    img.putpixel((X + k, yy), hue(c))
    return img


def screen_strip(px, draw_width, lens_width, dx, S=3):
    s, sl, h = band_rows(draw_width)
    _, lsl, _ = band_rows(lens_width)
    y0, y1 = 175 - 120 - 6, 175 - (120 - 8 * h) + 6
    x0, x1 = 40, 216
    img = Image.new('RGB', ((x1 - x0) * S, (y1 - y0) * S), BG)
    d = ImageDraw.Draw(img)
    for x, y in px:
        if x0 <= x < x1 and y0 <= y < y1:
            d.rectangle([(x - x0) * S, (y - y0) * S, (x - x0) * S + S - 1, (y - y0) * S + S - 1], fill=FG)
    for c in range(12):
        x, w = lsl[L.PERM[c]]
        X = (x + dx - x0) * S
        d.rectangle([X, 2, X + w * S - 1, (y1 - y0) * S - 3], outline=hue(c))
    return img


def frame(px, draw_width, lens_width, dx, caption):
    f = fnt(13)
    a = screen_strip(px, draw_width, lens_width, dx)
    b = view_strip(px, draw_width, lens_width, dx).resize((260, 8 * band_rows(draw_width)[2] * 3), Image.NEAREST)
    W = a.width + 24
    img = Image.new('RGB', (W, 30 + a.height + 16 + b.height + 16), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 8), caption, font=f, fill=FG)
    img.paste(a, (12, 30))
    img.paste(b, ((W - b.width) // 2, 30 + a.height + 16))
    return img


def slide(src, out):
    px = L.screen_pixels(open(os.path.join(src, '15900.scr'), 'rb').read())
    offs = list(range(0, 13)) + list(range(12, -13, -1)) + list(range(-12, 1))
    fr = [frame(px, WIDTH, WIDTH, dx, f'lens {dx:+d} px off the centre line (c1 frame 15900, code "si")')
          for dx in offs]
    hold = [600 if dx == 0 else 120 for dx in offs]
    fr[0].save(out, save_all=True, append_images=fr[1:], duration=hold, loop=0, optimize=True)


def width(out):
    """the screen as the code draws it at other calibrated widths, the lens made for 144"""
    ws = list(range(144, 200, 4)) + list(range(200, 80, -4)) + list(range(80, 145, 4))
    fr = [frame(L.draw(CODE, w, MARKS), w, WIDTH, 0, f'screen calibrated to {w} px, lens fits 144 (model)')
          for w in ws]
    H = max(f.height for f in fr)
    W = max(f.width for f in fr)
    fr = [_pad(f, W, H) for f in fr]
    hold = [600 if w == WIDTH else 100 for w in ws]
    fr[0].save(out, save_all=True, append_images=fr[1:], duration=hold, loop=0, optimize=True)


def _pad(img, W, H):
    out = Image.new('RGB', (W, H), BG)
    out.paste(img, (0, 0))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--scr', default=os.path.join(E.CASE, 'work', 'lenslok'))
    p.add_argument('--out', default=os.path.join(E.CASE, 'docs', 'img', 'lenslok'))
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    steps(a.scr, os.path.join(a.out, 'steps.png'))
    unscramble(os.path.join(a.out, 'unscramble.png'))
    n = model(a.scr, os.path.join(a.out, 'model.png'))
    optics(os.path.join(a.out, 'optics.png'))
    slide(a.scr, os.path.join(a.out, 'slide.gif'))
    width(os.path.join(a.out, 'width.gif'))
    print(a.out, f'model vs emulator: {n} px differ')


if __name__ == '__main__':
    sys.exit(main())
