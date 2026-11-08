"""The trading guide's mash-up: the stonks card made of Elite itself. The board is Lave's market screen as t1 saw it
(frame 1000), tilted and tinted like the meme's; the words are set in the game's own font ($5D70, from
src/res/fonts/font.png), the font that writes RIGHT ON COMMANDER on the message line:

    python3 tools/fig_stonks_commander.py       # -> docs/img/trading/stonks-commander.png

The man is the meme's own Meme Man, cut out by tools/fig_mememan.py.
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import res_formats as R  # noqa: E402
import zxscreen as Z  # noqa: E402

CASE = os.path.dirname(HERE)
W, H = 900, 600
S = 3  # drawn at 3x, then scaled down: smooth edges
SCREEN = os.path.join(CASE, 'work', 't1', 'frames', '001000.scr')
MAN = os.path.join(HERE, 'data', 'mememan.png')
FONT = os.path.join(CASE, 'src', 'res', 'fonts', 'font.png')


def board():
    """the market screen at 12x, its black turned to the meme's blue, tilted, cropped to the card"""
    scr = Z.render(open(SCREEN, 'rb').read(), 1).convert('RGB')
    blue = Image.new('RGB', scr.size)
    d = ImageDraw.Draw(blue)
    for y in range(scr.height):
        t = y / scr.height
        d.line([(0, y), (scr.width, y)], fill=(int(12 + 25 * t), int(40 + 55 * t), int(130 + 80 * t)))
    dark = scr.convert('L').point(lambda v: 255 if v < 40 else 0)
    scr.paste(blue, (0, 0), dark)
    big = scr.resize((scr.width * 4 * S, scr.height * 4 * S), Image.NEAREST)
    big = big.rotate(-9, resample=Image.BICUBIC, expand=False)
    # the market's price columns sit on the left: shift the crop so the numbers fill the card behind the man
    cx, cy = big.width // 2 - 40 * S, big.height // 2 - 10 * S
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


def spectrum_text(text, px):
    """text in the game's font as a 1-bit mask, each pixel px x px"""
    data = R.font_build(open(FONT, 'rb').read())
    mask = Image.new('L', (len(text) * 8, 8), 0)
    m = mask.load()
    for k, ch in enumerate(text):
        code = ord(ch)
        if not 0x20 <= code <= 0x7A:
            continue
        glyph = data[(code - 0x20) * 8:(code - 0x20) * 8 + 8]
        for y, row in enumerate(glyph):
            for x in range(8):
                if row & (0x80 >> x):
                    m[k * 8 + x, y] = 255
    return mask.resize((mask.width * px, mask.height * px), Image.NEAREST)


def words(img, text, centre, px):
    """white letters in the game's font, a black outline, a white glow behind"""
    mask = spectrum_text(text, px)
    x0, y0 = centre[0] - mask.width // 2, centre[1] - mask.height // 2
    out = Image.new('L', img.size, 0)
    out.paste(mask, (x0, y0))
    outline = out.filter(ImageFilter.MaxFilter(2 * (px // 3) + 1))
    glow = outline.filter(ImageFilter.MaxFilter(2 * px + 1)).filter(ImageFilter.GaussianBlur(5 * S))
    img.paste((255, 255, 255, 255), (0, 0), glow)
    img.paste((0, 0, 0, 255), (0, 0), outline)
    img.paste((255, 255, 255, 255), (0, 0), out)


def main():
    img = board().convert('RGBA')
    arrow(img)
    man = Image.open(MAN).convert('RGBA')
    h = 470 * S
    man = man.resize((man.width * h // man.height, h), Image.LANCZOS)
    img.alpha_composite(man, (-10 * S, H * S - h))
    words(img, 'Stonks,', (615 * S, 420 * S), 9 * S)
    words(img, 'Commander', (640 * S, 500 * S), 5 * S)
    out = os.path.join(CASE, 'docs', 'img', 'trading', 'stonks-commander.png')
    img.resize((W, H), Image.LANCZOS).convert('RGB').save(out)
    print('wrote', os.path.relpath(out, CASE))


if __name__ == '__main__':
    main()
