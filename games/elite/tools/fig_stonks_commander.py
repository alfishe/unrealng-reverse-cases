"""The trading guide's mash-up: the stonks card made of Elite itself. The board is Lave's market screen as t1 saw it
(frame 1000), tilted and tinted like the meme's; the words are set in the game's own font ($5D70, from
src/res/fonts/font.png), the font that writes RIGHT ON COMMANDER on the message line:

    python3 tools/fig_stonks_commander.py       # -> docs/img/trading/stonks-commander.png

The arrow and the man are those of tools/fig_stonks_card.py.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import fig_stonks_card as SC  # noqa: E402
import res_formats as R  # noqa: E402
import zxscreen as Z  # noqa: E402

CASE = SC.CASE
W, H, S = SC.W, SC.H, SC.S
SCREEN = os.path.join(CASE, 'work', 't1', 'frames', '001000.scr')
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
    SC.arrow(img)
    SC.man(img)
    words(img, 'Stonks,', (615 * S, 420 * S), 9 * S)
    words(img, 'Commander', (640 * S, 500 * S), 5 * S)
    d = ImageDraw.Draw(img)
    d.rectangle([0, (H - 34) * S, W * S, H * S], fill=(8, 12, 30, 230))
    d.text((12 * S, (H - 17) * S), "the board: Lave's market screen (t1 frame 1000); the words in the game's own font "
           "($5D70)", font=SC.font('small', 17 * S), fill=(230, 235, 245), anchor='lm')
    out = os.path.join(CASE, 'docs', 'img', 'trading', 'stonks-commander.png')
    img.resize((W, H), Image.LANCZOS).convert('RGB').save(out)
    print('wrote', os.path.relpath(out, CASE))


if __name__ == '__main__':
    main()
