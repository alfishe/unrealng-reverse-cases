"""The trading guide's "stonks" card: the meme's layout (a blue stock board, a glowing arrow, the word, a man in a
suit), drawn here from scratch, with the board's numbers taken from the league (tools/trade.py, 200 commanders a
scheme, 120 jumps from Lave):

    python3 tools/fig_stonks_card.py            # -> docs/img/trading/stonks-card.png

card(numbers) returns the picture for tools/fig_trading.py, which ends stonks.gif with it.
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
CASE = os.path.dirname(HERE)

W, H = 900, 600
S = 3  # drawn at 3x, then scaled down: smooth edges

FONTS = {
    'black': ['/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf',
              '/System/Library/Fonts/Supplemental/Arial Black.ttf', 'DejaVuSans-Bold.ttf'],
    'board': ['/System/Library/Fonts/Supplemental/Arial Bold.ttf', 'DejaVuSans-Bold.ttf'],
    'small': ['/System/Library/Fonts/Supplemental/Arial.ttf', 'DejaVuSans.ttf'],
}


def font(kind, size):
    for path in FONTS[kind]:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def board(numbers):
    """the tilted stock board: blue cells, light numbers, up and down triangles"""
    big = Image.new('RGB', (W * S * 2, H * S * 2))
    d = ImageDraw.Draw(big)
    for y in range(big.height):  # dark blue at the top, brighter at the bottom
        t = y / big.height
        d.line([(0, y), (big.width, y)], fill=(int(10 + 25 * t), int(35 + 60 * t), int(120 + 90 * t)))
    cw, ch = 300 * S, 120 * S
    f = font('board', 70 * S)
    ft = font('board', 60 * S)
    k = 0
    for row in range(big.height // ch + 1):
        for col in range(big.width // cw + 1):
            x, y = col * cw, row * ch
            d.rectangle([x, y, x + cw, y + ch], outline=(110, 170, 255), width=3 * S)
            text, up = numbers[k % len(numbers)]
            k += 1
            if (row + col) % 3 == 0:  # a triangle cell
                cx, cy = x + cw // 2, y + ch // 2
                r = 34 * S
                pts = ([(cx, cy - r), (cx - r, cy + r * 0.7), (cx + r, cy + r * 0.7)] if up else
                       [(cx, cy + r), (cx - r, cy - r * 0.7), (cx + r, cy - r * 0.7)])
                d.polygon(pts, fill=(140, 195, 255))
            else:
                d.text((x + cw - 18 * S, y + ch // 2), text, font=f if len(text) < 7 else ft,
                       fill=(150, 200, 255), anchor='rm')
    big = big.rotate(-9, resample=Image.BICUBIC, expand=False)
    cx, cy = big.width // 2, big.height // 2
    return big.crop((cx - W * S // 2, cy - H * S // 2, cx + W * S // 2, cy + H * S // 2))


def arrow(img):
    """the glowing arrow: a zigzag rising to the right, orange to yellow, a red glow under it"""
    pts = [(590, 610), (690, 400), (725, 425), (815, 175)]
    pts = [(x * S, y * S) for x, y in pts]
    tip = (850 * S, 85 * S)
    glow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.line(pts + [tip], fill=(255, 40, 30, 255), width=60 * S, joint='curve')
    glow = glow.filter(ImageFilter.GaussianBlur(18 * S))
    img.alpha_composite(glow)
    body = Image.new('RGBA', img.size, (0, 0, 0, 0))
    b = ImageDraw.Draw(body)
    full = pts + [tip]
    for i in range(len(full) - 1):  # each segment its own shade, orange at the foot, yellow at the head
        t = i / (len(full) - 1)
        c = (255, int(120 + 110 * t), int(20 + 40 * t), 255)
        b.line([full[i], full[i + 1]], fill=c, width=34 * S)
        b.ellipse([full[i][0] - 17 * S, full[i][1] - 17 * S, full[i][0] + 17 * S, full[i][1] + 17 * S], fill=c)
    # the head: a triangle along the last segment
    (x0, y0), (x1, y1) = full[-2], full[-1]
    a = math.atan2(y1 - y0, x1 - x0)
    L, Wd = 95 * S, 62 * S
    tipx, tipy = x1 + math.cos(a) * 55 * S, y1 + math.sin(a) * 55 * S
    bx, by = tipx - math.cos(a) * L, tipy - math.sin(a) * L
    px, py = math.cos(a + math.pi / 2) * Wd, math.sin(a + math.pi / 2) * Wd
    head = [(tipx, tipy), (bx + px, by + py), (bx - px, by - py)]
    b.polygon(head, fill=(255, 235, 90, 255))
    img.alpha_composite(body)


def man(img):
    """a bald man in a dark suit and a blue tie, smug, from simple shapes (not the meme's own picture)"""
    m = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(m)
    sx = lambda v: int(v * S)  # noqa: E731
    # the suit: shoulders and the jacket
    d.polygon([(sx(-20), sx(600)), (sx(10), sx(470)), (sx(110), sx(420)), (sx(250), sx(420)), (sx(350), sx(470)),
               (sx(390), sx(600))], fill=(28, 28, 34, 255))
    # the shirt and the tie
    d.polygon([(sx(140), sx(420)), (sx(220), sx(420)), (sx(205), sx(600)), (sx(155), sx(600))],
              fill=(235, 240, 250, 255))
    d.polygon([(sx(168), sx(432)), (sx(192), sx(432)), (sx(200), sx(452)), (sx(180), sx(600)),
               (sx(160), sx(452))], fill=(40, 120, 220, 255))
    # the lapels
    d.polygon([(sx(140), sx(420)), (sx(110), sx(430)), (sx(150), sx(600))], fill=(18, 18, 24, 255))
    d.polygon([(sx(220), sx(420)), (sx(250), sx(430)), (sx(210), sx(600))], fill=(18, 18, 24, 255))
    # the neck
    d.rectangle([sx(150), sx(360), sx(210), sx(425)], fill=(205, 175, 135, 255))
    # the head: a tall smooth egg, lit from the left
    head = Image.new('RGBA', img.size, (0, 0, 0, 0))
    h = ImageDraw.Draw(head)
    h.ellipse([sx(95), sx(130), sx(265), sx(395)], fill=(214, 184, 142, 255))
    hl = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(hl).ellipse([sx(115), sx(150), sx(195), sx(300)], fill=(255, 235, 200, 90))
    hl = hl.filter(ImageFilter.GaussianBlur(14 * S))
    head.alpha_composite(hl)
    sh = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([sx(200), sx(200), sx(275), sx(400)], fill=(120, 90, 60, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(14 * S))
    head.alpha_composite(sh)
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).ellipse([sx(95), sx(130), sx(265), sx(395)], fill=255)
    m.paste(head, (0, 0), mask)
    d = ImageDraw.Draw(m)
    # the eyes: small, blue, looking at the arrow
    for ex in (150, 215):
        d.ellipse([sx(ex - 13), sx(243), sx(ex + 13), sx(259)], fill=(250, 250, 250, 255))
        d.ellipse([sx(ex - 2), sx(244), sx(ex + 10), sx(258)], fill=(40, 110, 220, 255))
        d.ellipse([sx(ex + 2), sx(248), sx(ex + 7), sx(254)], fill=(10, 20, 40, 255))
        d.line([(sx(ex - 15), sx(234)), (sx(ex + 14), sx(232))], fill=(150, 115, 80, 255), width=sx(3))
    # the nose: one long wedge
    d.polygon([(sx(184), sx(252)), (sx(206), sx(314)), (sx(190), sx(322)), (sx(172), sx(316))], fill=(188, 154, 112, 255))
    d.line([(sx(184), sx(252)), (sx(206), sx(314))], fill=(160, 125, 88, 255), width=sx(2))
    # the smirk
    d.arc([sx(150), sx(318), sx(230), sx(352)], start=15, end=80, fill=(120, 80, 60, 255), width=sx(4))
    d.line([(sx(160), sx(338)), (sx(205), sx(343))], fill=(120, 80, 60, 255), width=sx(4))
    img.alpha_composite(m)


def word(img, text='stonks'):
    """the word: white, a thick black outline, a white glow behind"""
    f = font('black', 130 * S)
    pos = (640 * S, 455 * S)
    glow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).text(pos, text, font=f, fill=(255, 255, 255, 255), anchor='mm', stroke_width=26 * S,
                              stroke_fill=(255, 255, 255, 255))
    glow = glow.filter(ImageFilter.GaussianBlur(16 * S))
    img.alpha_composite(glow)
    ImageDraw.Draw(img).text(pos, text, font=f, fill=(255, 255, 255, 255), anchor='mm', stroke_width=9 * S,
                             stroke_fill=(0, 0, 0, 255))


def card(numbers, caption):
    img = board(numbers).convert('RGBA')
    arrow(img)
    man(img)
    word(img)
    d = ImageDraw.Draw(img)
    fc = font('small', 17 * S)
    d.rectangle([0, (H - 34) * S, W * S, H * S], fill=(8, 12, 30, 230))
    d.text((12 * S, (H - 17) * S), caption, font=fc, fill=(230, 235, 245), anchor='lm')
    return img.resize((W, H), Image.LANCZOS).convert('RGB')


def league_numbers():
    """the board's cells: the league's medians at jump 120 and per jump (tools/trade.py), and up / down marks"""
    import numpy as np
    import trade as T
    lg = T.league(200, 120)
    cells = []
    for s in T.SCHEMES:
        w = np.median(np.array([[h[1] / 10 for h in t.history] for t in lg[s]]), axis=0)
        cells.append(('%d' % w[-1], True))
        cells.append(('x%d' % (w[-1] / w[0]), True))
    return cells


CAPTION = 'the board: the five schemes\' median worth after 120 jumps from 100 Cr, and how many times over (tools/trade.py)'


def main():
    out = os.path.join(CASE, 'docs', 'img', 'trading', 'stonks-card.png')
    card(league_numbers(), CAPTION).save(out)
    print('wrote', os.path.relpath(out, CASE))


if __name__ == '__main__':
    main()
