#!/usr/bin/env python3
"""The figures of doc 8 (HUD and text), drawn from the game image (build/game.bin).

    python3 tools/fig_hud.py panel --out docs/img/hud/panel.png
    python3 tools/fig_hud.py font --out docs/img/hud/font.png

panel: the play panel (PlayPanel $F600, PanelAttrs $FC64, screen rows 18-23) as loaded, with the places the game
writes each pass: the four mask slots (MaskSlots $AF2B), the energy bar (DrawEnergyBar $AEA8), the score
(DrawScore $AE60) and the message line (Scroller $AF82). font: the 39 glyphs of Font $95FB (CharGlyph $96BE), the
eight-cell PrintChar $9CD9 makes of one, the score digits (Digits $D3A0), the mask icons (MaskIcons $D580) with
their colours (MaskColours $AF46) and the energy bar's partial cells (EnergyParts $AF04).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_controls as F  # noqa: E402
import fig_render as R  # noqa: E402

K = F.K
WIDTH = F.WIDTH

# (label, column, row, width, height in characters, colour, what)
PLACES = [
    ('slot 1', 1, 19, 2, 3, (250, 200, 60), 'MaskSlots $AF2B: icon at $5061 (DrawIcon $B024), charges at $50A1'),
    ('slot 2', 4, 19, 2, 3, (250, 200, 60), '$AF2F: icon $5064, charges $50A4'),
    ('slot 3', 7, 19, 2, 3, (250, 200, 60), '$AF33: icon $5067, charges $50A7'),
    ('slot 4', 10, 19, 2, 3, (250, 200, 60), '$AF37: icon $506A, charges $50AA'),
    ('energy', 13, 19, 8, 3, (240, 80, 70), 'DrawEnergyBar $AEA8 at $506D: 64 pixel columns, Energy / 4'),
    ('score', 23, 19, 8, 2, (90, 200, 120), 'DrawScore $AE60 at $5077: 8 digits of Digits $D3A0, every pass'),
    ('message', 1, 23, 11, 1, (90, 150, 250), 'Scroller $AF82 (interrupt): lines 1-6 of row 23, one pixel a frame'),
]


def panel_image(mem, scale):
    """rows 18-23 from PlayPanel $F600 (32 x 6 characters, 8 lines a character) and PanelAttrs $FC64"""
    im = Image.new('RGB', (256, 48))
    px = im.load()
    for row in range(6):
        for col in range(32):
            attr = mem[0xFC64 + 32 * row + col]
            ink, paper = R.zx(attr)
            for line in range(8):
                b = mem[0xF600 + (row * 32 + col) * 8 + line]
                for x in range(8):
                    px[col * 8 + x, row * 8 + line] = ink if b & (0x80 >> x) else paper
    return im.resize((256 * scale, 48 * scale), Image.NEAREST)


def cmd_panel(args):
    mem = F.image()
    f, fs = K.font(15), K.font(13)
    sc = 4
    im = Image.new('RGB', (WIDTH, 48 * sc + 330), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    F.title(d, 'The play panel, screen rows 18-23 (PlayPanel $F600, PanelAttrs $FC64) as the tape loads it')
    x0, y0 = 12, 40
    im.paste(panel_image(mem, sc), (x0, y0))
    for label, col, row, w, h, colour, _ in PLACES:
        r = (x0 + col * 8 * sc, y0 + (row - 18) * 8 * sc, x0 + (col + w) * 8 * sc - 1, y0 + (row - 18 + h) * 8 * sc - 1)
        d.rectangle(r, outline=colour, width=3)
    for i in range(32):
        if i % 4 == 0:
            d.text((x0 + i * 8 * sc + 2, y0 + 48 * sc + 2), str(i), fill=K.DIM, font=fs)
    yy = y0 + 48 * sc + 26
    for label, col, row, w, h, colour, what in PLACES:
        d.rectangle((x0, yy + 3, x0 + 14, yy + 15), fill=colour)
        d.text((x0 + 22, yy), '%-8s row %d, columns %d-%d: %s' % (label, row, col, col + w - 1, what), fill=K.TEXT,
               font=fs)
        yy += 22
    F.wrap(d, 'The pixels are the authors\' own play screen saved into the tape image: score 00012042 and four '
           'masks. The first start draws them as they are; DrawScore and the slot code then overwrite the score and '
           'the slots within the first pass. From the second game on, Menu $9723 saves the panel of the game just '
           'ended (SaveHud $9CA0) before BuildTables reuses $F600-$FDFF for its tables.', x0, yy + 8, WIDTH - 24, fs,
           fill=K.DIM)
    im.save(args.out)
    print(args.out, im.size)


def glyph_rows(mem, i):
    return [mem[0x95FB + 5 * i + r] for r in range(5)]


def cmd_font(args):
    mem = F.image()
    f, fs = K.font(15), K.font(13)
    im = Image.new('RGB', (WIDTH, 640), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    F.title(d, 'The font (Font $95FB, 39 glyphs of 5 lines), the score digits, the mask icons and the energy cells')
    names = [chr(65 + i) for i in range(26)] + [str(i) for i in range(10)] + ['.', ':', 'space']
    sc = 4
    x0, y0 = 12, 44
    for i, n in enumerate(names):
        x = x0 + (i % 13) * 79
        y = y0 + (i // 13) * 62
        im.paste(R.bits_image(glyph_rows(mem, i), 8, sc, grid=False), (x, y))
        d.text((x, y + 5 * sc + 4), '%s $%04X' % (n, 0x95FB + 5 * i), fill=K.DIM, font=fs)
    # PrintChar's cell for 'M'
    y1 = y0 + 3 * 62 + 10
    d.text((x0, y1), "PrintChar $9CD9 makes an 8-line cell: two blank lines, the glyph's 5 lines, a blank line "
           "(here 'M')", fill=K.TEXT, font=fs)
    rows = [0, 0] + glyph_rows(mem, 12) + [0]
    im.paste(R.bits_image(rows, 8, 14), (x0, y1 + 24))
    for i in range(8):
        d.text((x0 + 8 * 14 + 12, y1 + 24 + i * 14 - 1), 'line %d%s' % (i, ' glyph' if 2 <= i <= 6 else ''),
               fill=K.DIM, font=K.font(11))
    # digits
    x2 = 300
    d.text((x2, y1 + 24), 'Digits $D3A0: 10 of 1 x 2 characters (DrawScore)', fill=K.TEXT, font=fs)
    for i in range(10):
        rows = [mem[0xD3A0 + 16 * i + r] for r in range(16)]
        im.paste(R.bits_image(rows, 8, 4, grid=False), (x2 + i * 40, y1 + 48))
    # mask icons
    y2 = y1 + 150
    d.text((x0, y2), 'MaskIcons $D580: 11 of 2 x 2, coloured by MaskColours $AF46 | $40 (bright)', fill=K.TEXT, font=fs)
    names = ['EMPTY', 'PENETRATOR', 'ULTRA FLASH', 'MIRAGE', 'HEALER', 'JACKRABBIT', 'LIFTER', 'BLASTER',
             'BACKLASH', 'LAVA SHOT', 'STREAMER']
    for k in range(11):
        rows = R.frame_rows(mem, 0xD580 + 32 * k, 2, 2)
        attr = mem[0xAF46 + k] | 0x40
        ink, paper = R.zx(attr)
        x = x0 + k * 93
        im.paste(R.bits_image(rows, 16, 4, on=ink, off=paper, grid=False), (x, y2 + 24))
        d.text((x, y2 + 24 + 66), names[k], fill=K.DIM, font=K.font(11))
        d.text((x, y2 + 24 + 80), '$%02X' % mem[0xAF46 + k], fill=K.DIM, font=K.font(11))
    # energy parts
    y3 = y2 + 140
    d.text((x0, y3), 'EnergyParts $AF04: the partial cell for (Energy / 4) AND 7; full cells are $FF, empty $00',
           fill=K.TEXT, font=fs)
    for i in range(8):
        v = mem[0xAF04 + i]
        im.paste(R.bits_image([v] * 3, 8, 10), (x0 + i * 120, y3 + 24))
        d.text((x0 + i * 120, y3 + 58), '%d: $%02X' % (i, v), fill=K.DIM, font=fs)
    im = im.crop((0, 0, WIDTH, y3 + 84))
    im.save(args.out)
    print(args.out, im.size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    for name in ('panel', 'font'):
        s = sub.add_parser(name)
        s.add_argument('--out', required=True)
    args = p.parse_args()
    {'panel': cmd_panel, 'font': cmd_font}[args.cmd](args)


if __name__ == '__main__':
    main()
