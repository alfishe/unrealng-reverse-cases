#!/usr/bin/env python3
"""Doc 02's memory map: the RAM from $4000 in three states side by side, as the tape's loader leaves it, after
GameEntry's two copies, and in play, the regions named from game.ann (the addresses are its entries'; the stages from
recording c1: the loader's jump at frame 14 100, GameEntry's LDIRs at $D7E0 / $D7EB, play from frame 15 055).

    python3 tools/fig_memmap.py docs/img/arch/memmap.png
"""
import sys

from PIL import Image, ImageDraw, ImageFont

CODE, DATA, GFX, BUF, VARS, SCR, FREE, STACK, TUNE = ((90, 170, 250), (240, 200, 90), (200, 120, 230), (120, 210, 130),
                                                    (250, 140, 70), (150, 150, 160), (40, 40, 52), (230, 90, 90),
                                                    (90, 220, 220))
LOADED = [
    (0x4000, 0x5B00, SCR, 'loading screen'), (0x5B00, 0x5CCB, FREE, 'printer buffer, sysvars'),
    (0x5CCB, 0x6338, FREE, 'BASIC, ROM stack'),
    (0x6338, 0x6720, GFX, 'MenuGfx'), (0x6720, 0x69A6, VARS, 'menu vars, tables'), (0x69A6, 0x7C9C, CODE, 'front end, scores'),
    (0x7C9C, 0x8080, DATA, 'trails 1-4'), (0x8080, 0x82FE, VARS, 'render vars'), (0x82FE, 0x8F26, CODE, 'renderer'),
    (0x8F26, 0xD6B0, GFX, 'GameGfx: 203 sprites'), (0xD6B0, 0xD7D6, VARS, 'loop vars, records'),
    (0xD7D6, 0xEE84, CODE, 'game: loop, vehicle'), (0xEE84, 0xF03C, DATA, 'trail 5'),
    (0xF03C, 0xF230, FREE, ''), (0xF230, 0xF4BA, DATA, 'trail 6, source text tail'), (0xF4BA, 0xF850, FREE, ''),
    (0xF850, 0xFDFB, TUNE, 'tune player, tunes'), (0xFDFB, 0xFF78, FREE, ''), (0xFF78, 0xFFDC, FREE, ''),
    (0xFFDC, 0x10000, CODE, 'tape loader')]
ENTRY = [
    (0x4000, 0x5B00, SCR, 'loading screen'), (0x5B00, 0x60AC, TUNE, 'tune player copy'),
    (0x60AC, 0x6336, DATA, 'trail 6 (Trail6)'),
    (0x6338, 0x6720, GFX, 'MenuGfx'), (0x6720, 0x69A6, VARS, 'menu vars, tables'), (0x69A6, 0x7C9C, CODE, 'front end, scores'),
    (0x7C9C, 0x8080, DATA, 'trails 1-4'), (0x8080, 0x82FE, VARS, 'render vars'), (0x82FE, 0x8F26, CODE, 'renderer'),
    (0x8F26, 0xD6B0, GFX, 'GameGfx: 203 sprites'), (0xD6B0, 0xD7D6, VARS, 'loop vars, records'),
    (0xD7D6, 0xEE84, CODE, 'game: loop, vehicle'), (0xEE84, 0xF03C, DATA, 'trail 5'),
    (0xF03C, 0xF850, BUF, 'buffer (front end draws)'), (0xF850, 0xFDFB, TUNE, 'tune player (title)'),
    (0xFDFD, 0xFE00, CODE, 'TuneVector'), (0xFE00, 0xFF01, VARS, 'IM 2 table'), (0xFF01, 0xFFDC, STACK, 'stack'),
    (0xFFDC, 0x10000, CODE, 'tape loader (dead)')]
PLAY = [
    (0x4000, 0x5B00, SCR, 'screen: two halves'), (0x5B00, 0x60AC, TUNE, 'tune player copy'),
    (0x60AC, 0x6336, DATA, 'trail 6 (Trail6)'),
    (0x6338, 0x6720, GFX, 'MenuGfx'), (0x6720, 0x69A6, VARS, 'menu vars, scores'), (0x69A6, 0x7C9C, CODE, 'front end, scores'),
    (0x7C9C, 0x8080, DATA, 'trails 1-4'), (0x8080, 0x82FE, VARS, 'render vars, keys'), (0x82FE, 0x8F26, CODE, 'renderer'),
    (0x8F26, 0xD6B0, GFX, 'GameGfx (shifts in place)'), (0xD6B0, 0xD7D6, VARS, 'loop vars, records'),
    (0xD7D6, 0xEE84, CODE, 'game: loop, vehicle'), (0xEE84, 0xF03C, DATA, 'trail 5'),
    (0xF03C, 0xF71C, BUF, 'BufferP1 22 x 80'), (0xF71C, 0xFDFC, BUF, 'BufferP2 22 x 80'),
    (0xFDFD, 0xFE00, CODE, 'TuneVector'), (0xFE00, 0xFF01, VARS, 'IM 2 table: $80'),
    (0xFF01, 0xFFDC, STACK, 'stack (lowest SP FFA6)'), (0xFFDC, 0x10000, CODE, 'tape loader (dead)')]


def font(n):
    try:
        return ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', n)
    except OSError:
        return ImageFont.load_default()


def main():
    out = sys.argv[1]
    W, top, H = 1050, 70, 900
    im = Image.new('RGB', (W, top + H + 120), (22, 22, 30))
    d = ImageDraw.Draw(im)
    big, small = font(15), font(12)
    d.text((10, 8), 'The 48K RAM in three states: GameEntry moves the tune player and trail 6 under the image,', fill=(240, 240, 240), font=big)
    d.text((10, 28), 'so that the two play buffers can lie over them', fill=(240, 240, 240), font=big)

    def y(a):
        return top + (a - 0x4000) * H // 0xC000

    cols = [(66, 'as loaded (c1 frame 14 100)', LOADED), (378, 'after GameEntry (frame 14 101)', ENTRY),
            (690, 'in play (frame 15 055 on)', PLAY)]
    for a in range(0x4000, 0x10001, 0x1000):
        d.text((6, y(a) - 7), '%04X' % min(a, 0xFFFF), fill=(160, 160, 160), font=small)
        d.line([52, y(a), 60, y(a)], fill=(120, 120, 120))
    for x, title, regs in cols:
        d.text((x, top - 18), title, fill=(220, 220, 220), font=small)
        bw = 90
        last_label = -100
        for a, b, col, name in regs:
            d.rectangle([x, y(a), x + bw, max(y(b) - 1, y(a))], fill=col, outline=(22, 22, 30))
            if name:
                ly = max((y(a) + y(b)) // 2 - 7, last_label + 14)
                d.line([x + bw, (y(a) + y(b)) // 2, x + bw + 6, ly + 7], fill=(150, 150, 150))
                d.text((x + bw + 8, ly), '%04X %s' % (a, name), fill=(225, 225, 225), font=small)
                last_label = ly
    # arrows for the two copies
    ax = 70 + 110
    for src, dst, col in ((0xF850, 0x5B00, TUNE), (0xF230, 0x60AC, DATA)):
        d.line([cols[0][0] + 45, y(src), cols[1][0] + 45, y(dst)], fill=col, width=2)
    ly = top + H + 66
    for i, (col, name) in enumerate(((CODE, 'code'), (DATA, 'trail data'), (GFX, 'graphics'), (VARS, 'variables, tables'),
                                     (BUF, 'play buffers'), (TUNE, 'tune player'), (STACK, 'stack'), (SCR, 'screen'),
                                     (FREE, 'unused'))):
        x = 10 + (i % 5) * 200
        yy = ly + (i // 5) * 18
        d.rectangle([x, yy + 2, x + 12, yy + 14], fill=col, outline=(120, 120, 120))
        d.text((x + 16, yy), name, fill=(220, 220, 220), font=small)
    d.text((10, ly + 40), 'lines: GameEntry\'s LDIR at D7E0 (F850-FDFA to 5B00, 1 451 bytes) and at D7EB (F230-F4B9 to 60AC, 650 bytes)',
           fill=(200, 200, 200), font=small)
    im.save(out)
    print(out, im.size)


if __name__ == '__main__':
    main()
