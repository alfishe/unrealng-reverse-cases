#!/usr/bin/env python3
"""The figures of doc 01 (the game design), 1050 pixels wide, into docs/img/design/.

    python3 tools/fig_design.py screens     # 12 screens from docs/img/play/, 4 a row, at 1:1 Spectrum pixels
    python3 tools/fig_design.py enemies     # every enemy and hazard cut from a screenshot of docs/img/play/
    python3 tools/fig_design.py coursemap   # both course scripts of src/res/courses/: segments x enemy kinds
    python3 tools/fig_design.py moments     # 14 key moments from docs/img/play/
    python3 tools/fig_design.py all

The screenshots in docs/img/play/ are 512x384: the 256x192 Spectrum screen (no border) at 2x, each the start of the
frame its name and doc 01 give. The sheets halve them to 256x192 (1:1); the enemy crops keep 2x.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
PLAY = os.path.join(CASE, 'docs', 'img', 'play')
OUT = os.path.join(CASE, 'docs', 'img', 'design')
WIDTH = 1050
BG = (250, 250, 247)
INK = (30, 30, 30)
GREY = (120, 120, 120)

sys.path.insert(0, os.path.join(CASE, 'work', 'docs'))


def font(size, bold=False):
    names = ['/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf',
             '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf']
    for f in names:
        if os.path.exists(f):
            return ImageFont.truetype(f, size, index=1 if bold and f.endswith('.ttc') else 0)
    return ImageFont.load_default()


F13, F14B, F16B = font(13), font(14, True), font(16, True)


def shot(name, half=True):
    im = Image.open(os.path.join(PLAY, name)).convert('RGB')
    return im.resize((256, 192), Image.NEAREST) if half else im


def sheet(cells, title, out):
    """cells: [(png, caption line 1, caption line 2)], 4 a row, each 256x192 with two caption lines"""
    cols, gap, cw, ch = 4, 8, 256, 192
    cap = 38
    rows = (len(cells) + cols - 1) // cols
    top = 30
    left = (WIDTH - cols * cw - (cols - 1) * gap) // 2
    img = Image.new('RGB', (WIDTH, top + rows * (ch + cap + gap) + 4), BG)
    d = ImageDraw.Draw(img)
    d.text((left, 6), title, font=F16B, fill=INK)
    for i, (png, l1, l2) in enumerate(cells):
        x = left + (i % cols) * (cw + gap)
        y = top + (i // cols) * (ch + cap + gap)
        img.paste(shot(png), (x, y))
        d.rectangle((x - 1, y - 1, x + cw, y + ch), outline=GREY)
        d.text((x, y + ch + 4), l1, font=F14B, fill=INK)
        d.text((x, y + ch + 21), l2, font=F13, fill=GREY)
    img.save(out)
    print(out, img.size)


def screens():
    cells = [
        ('a1-title.png', '1 the title', 'a1 frame 100'),
        ('a1-options.png', '2 the options page', 'a1 frame 700'),
        ('a1-score-advance-table.png', '3 SCORE ADVANCE TABLE', 'a1 frame 19 800'),
        ('a1-demo.png', '4 the demo', 'a1 frame 20 800'),
        ('a1-heroes-table.png', '5 the hi-score page', 'a1 frame 300'),
        ('a1-player1.png', '6 the banner PLAYER 1', 'a1 frame 1330'),
        ('a1-play-beginner.png', '7 play, Beginner', 'a1 frame 1700'),
        ('i1-bonus-e.png', '8 the bonus screen, E', 'i1 frame 5400'),
        ('g1-game-over.png', '9 GAME OVER', 'g1 frame 3950'),
        ('h1-initials.png', '10 the initials', 'h1 frame 4500'),
        ('h2-greatest-name.png', "11 THE GREATEST's name", 'h2 frame 700'),
        ('a1-hold.png', '12 the hold (H)', 'a1 frame 2100'),
    ]
    sheet(cells, "Moon Patrol's screens (each the screen at the start of the frame named)",
          os.path.join(OUT, 'screens.png'))


# (screenshot, crop box in its 512x384 pixels, name, shot / jumped points, recording and frame)
ENEMIES = [
    ('i1-crater.png', (412, 300, 512, 360), 'crater', '- / 100', 'i1 450'),
    ('i1-rock-point-a.png', (230, 284, 314, 330), 'rock', '100 / 80', 'i1 1200'),
    ('i2-mines.png', (88, 300, 160, 336), 'a mine', '- / 50', 'i2 12 950'),
    ('i1-ufos.png', (352, 86, 460, 136), 'saucers A, B', '100 / -', 'i1 1800'),
    ('i1-ufo-spinner.png', (242, 48, 300, 90), 'spinner', '200 / -', 'i1 9600'),
    ('i2-tank.png', (384, 276, 458, 328), 'tank', '250 / 200', 'i2 2400'),
    ('i2-low-flyer.png', (20, 278, 92, 326), 'low flyer, boulder', '300-800 / 125', 'i2 29 300'),
    ('i2-boulders.png', (336, 286, 470, 328), 'boulders S M L', '100-200 / 50-150', 'i2 3300'),
    ('i2-green-plant.png', (326, 290, 416, 358), 'plant (and a rock)', '500 / 200', 'i2 4200'),
]


def enemies():
    cols, gap = 3, 14
    cw = (WIDTH - 2 * 16 - (cols - 1) * gap) // cols
    boxh = 150
    cap = 60
    rows = (len(ENEMIES) + cols - 1) // cols
    top = 34
    img = Image.new('RGB', (WIDTH, top + rows * (boxh + cap + gap) + 4), BG)
    d = ImageDraw.Draw(img)
    d.text((16, 6), 'The enemies and hazards, cut from the screenshots (points: shot / jumped)', font=F16B,
           fill=INK)
    for i, (png, box, name, pts, frame) in enumerate(ENEMIES):
        x = 16 + (i % cols) * (cw + gap)
        y = top + (i // cols) * (boxh + cap + gap)
        crop = shot(png, half=False).crop(box)
        k = min(2, (cw - 8) // crop.width, (boxh - 8) // crop.height) or 1
        crop = crop.resize((crop.width * k, crop.height * k), Image.NEAREST)
        d.rectangle((x, y, x + cw - 1, y + boxh - 1), fill=(20, 20, 20))
        img.paste(crop, (x + (cw - crop.width) // 2, y + (boxh - crop.height) // 2))
        d.text((x, y + boxh + 4), name, font=F14B, fill=INK)
        d.text((x, y + boxh + 22), 'points ' + pts, font=F13, fill=INK)
        d.text((x, y + boxh + 39), '%s, %dx%d Spectrum pixels at %dx' % (frame, (box[2] - box[0]) // 2, (box[3] - box[1]) // 2, k * 2),
               font=F13, fill=GREY)
    out = os.path.join(OUT, 'enemies.png')
    img.save(out)
    print(out, img.size)


def coursemap():
    import importlib
    ct = importlib.import_module('mpA-coursetable')
    kinds = ct.KINDS
    cw, rh, lw = 24, 18, 98
    hdr = 3 * rh
    panel_h = hdr + len(kinds) * rh + 8
    top = 34
    legend = 40
    img = Image.new('RGB', (WIDTH, top + 2 * (panel_h + 30) + legend), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 6), 'The two course scripts: one column a segment, one row an enemy kind, the count it spawns',
           font=F16B, fill=INK)
    for p, course in enumerate(['Beginner', 'Champion']):
        segs = ct.segments(course)
        y0 = top + p * (panel_h + 30)
        d.text((10, y0), course + ' (src/res/courses/%sCourse.txt)' % course, font=F14B, fill=INK)
        y0 += 22
        x0 = 10 + lw
        for r, k in enumerate(kinds):
            y = y0 + hdr + r * rh
            d.text((10, y + 2), ct.SHORT[k], font=F13, fill=INK)
            d.line((x0, y, x0 + len(segs) * cw, y), fill=(225, 225, 220))
        d.text((10, y0 + 2), 'point', font=F13, fill=INK)
        d.text((10, y0 + rh + 2), 'scenery', font=F13, fill=INK)
        d.text((10, y0 + 2 * rh + 2), 'passes', font=F13, fill=INK)
        scenery = 0
        for c, s in enumerate(segs):
            x = x0 + c * cw
            if s['sector']:
                par = int(s['sector'][0][1:], 16)
                d.rectangle((x + 2, y0, x + cw - 3, y0 + hdr + len(kinds) * rh), fill=(205, 40, 40))
                txt = Image.new('RGBA', (len(kinds) * rh + hdr, cw - 4), (0, 0, 0, 0))
                ImageDraw.Draw(txt).text((6, 2), 'sector end: par %x s, bonus %s' % (par, s['sector'][1][1:]),
                                         font=F13, fill=(255, 255, 255))
                txt = txt.rotate(90, expand=True)
                img.paste(txt, (x + 2, y0), txt)
                scenery = 0 if s['sector'][2] == '$00' else 1
                continue
            if s['word']:
                d.rectangle((x + 2, y0, x + cw - 3, y0 + hdr + len(kinds) * rh), fill=(90, 90, 90))
                txt = Image.new('RGBA', (len(kinds) * rh + hdr, cw - 4), (0, 0, 0, 0))
                other = 'Champion' if course == 'Beginner' else 'Beginner'
                ImageDraw.Draw(txt).text((6, 2), 'word %s: on to %s' % (s['word'], other), font=F13,
                                         fill=(255, 255, 255))
                txt = txt.rotate(90, expand=True)
                img.paste(txt, (x + 2, y0), txt)
                continue
            if s['point']:
                d.text((x + 7, y0 + 1), s['point'], font=F14B, fill=INK)
            d.rectangle((x, y0 + rh + 3, x + cw - 1, y0 + 2 * rh - 3),
                        fill=(205, 60, 50) if scenery == 0 else (215, 190, 40))
            d.text((x + 1, y0 + 2 * rh + 3), str(s['wait']), font=font(10), fill=GREY)
            for r, k in enumerate(kinds):
                n = s['objs'].get(k, 0)
                if n:
                    y = y0 + hdr + r * rh
                    shade = max(60, 200 - 35 * n)
                    d.rectangle((x + 1, y + 1, x + cw - 2, y + rh - 1), fill=(shade, shade + 20, 235))
                    d.text((x + 8, y + 2), str(n), font=F13, fill=(255, 255, 255) if n > 2 else INK)
    ly = img.height - legend + 6
    d.rectangle((10, ly + 3, 30, ly + 13), fill=(205, 60, 50))
    d.text((36, ly), 'mountains', font=F13, fill=INK)
    d.rectangle((130, ly + 3, 150, ly + 13), fill=(215, 190, 40))
    d.text((156, ly), 'moon base (the city)', font=F13, fill=INK)
    d.rectangle((330, ly + 1, 340, ly + 15), fill=(205, 40, 40))
    d.text((346, ly), 'sector end (par in seconds, bonus BCD)', font=F13, fill=INK)
    d.text((10, ly + 18), 'passes: the segment wait (Wait), the segment\'s length in main-loop passes',
           font=F13, fill=GREY)
    out = os.path.join(OUT, 'coursemap.png')
    img.save(out)
    print(out, img.size)


def moments():
    cells = [
        ('i1-crater.png', '1 the first crater', 'i1 frame 450'),
        ('i1-rock-point-a.png', '2 the first rock', 'i1 frame 1200'),
        ('i1-ufos.png', '3 the first UFOs', 'i1 frame 1800'),
        ('i1-bonus-e.png', '4 bonus screen, E', 'i1 frame 5400'),
        ('i1-sector-f-city.png', '5 the city, sector F', 'i1 frame 6600'),
        ('i1-ufo-spinner.png', '6 the spinner', 'i1 frame 9600'),
        ('i2-mines.png', '7 the mines', 'i2 frame 12 950'),
        ('i1-tanks-point-y.png', '8 the tanks, point Y', 'i1 frame 28 400'),
        ('i1-bonus-z.png', '9 bonus screen, Z', 'i1 frame 29 000'),
        ('i1-champion-begins.png', '10 Champion begins', 'i1 frame 29 800'),
        ('i2-boulders.png', '11 the boulders', 'i2 frame 3300'),
        ('i2-green-plant.png', '11 the plant', 'i2 frame 4200'),
        ('i2-low-flyer.png', '12 the low flyer', 'i2 frame 29 300'),
        ('i2-loop-to-beginner.png', '13 back to Beginner', 'i2 frame 31 000'),
        ('g1-game-over.png', '14 GAME OVER', 'g1 frame 3950'),
    ]
    sheet(cells, 'Key moments of a game (each the screen at the start of the frame named)',
          os.path.join(OUT, 'moments.png'))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    for name, fn in [('screens', screens), ('enemies', enemies), ('coursemap', coursemap), ('moments', moments)]:
        if what in (name, 'all'):
            fn()
