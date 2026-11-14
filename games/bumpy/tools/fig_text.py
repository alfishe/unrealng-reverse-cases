#!/usr/bin/env python3
"""Doc 08's figures of the font and the hall of fame, from build/game.bin (no emulator):

    python3 tools/fig_text.py font     docs/img/hud/font.png
    python3 tools/fig_text.py hof      docs/img/hud/hof.png
    python3 tools/fig_text.py all

font: the 96 glyphs of Font $F5C9 (characters 32-127, 8 bytes each) as DrawGlyph $E73E and HudBlit $E644 use them;
the digits PrintDigit $E62B reads from Font + $80, and the five HUD icons 123-127 PrintHudIcon $E661 draws, are
framed. Each glyph is shown as the HUD shows it (rows 0-6) with row 7 dimmed, since HudBlit skips it.
hof: the four 32-byte records of HallOfFame $EEB3 as stored (each one a PrintText string with its score word after
it), then the table as EnterHallOfFame $EC40 changes it in the recording twoname: B U M with 2000 points, then
Z A P with 2100, computed the way the code inserts.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(CASE))
sys.path.insert(0, os.path.join(ROOT, 'kit'))
import kitlib  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'hud')
BASE = 0x61A8
BIN = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
FONT = 0xF5C9
HOF = 0xEEB3


def peek(a, n=1):
    return BIN[a - BASE:a - BASE + n]


def font():
    S, CW, CH = 5, 64, 70
    W = 1050
    H = 70 + 6 * CH + 60
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, small, tiny = kitlib.font(15), kitlib.font(12), kitlib.font(11)
    d.text((10, 8), 'The game\'s only font: 96 glyphs at Font $F5C9, characters 32-127; 123-127 are the HUD icons',
           fill=kitlib.TEXT, font=f)
    d.text((10, 30), 'framed: the digits PrintDigit $E62B takes from Font + $80, and the icons of PrintHudIcon $E661; '
           'row 7 (dimmed) is never drawn on the HUD', fill=kitlib.DIM, font=small)
    x0, y0 = 10, 60
    for i in range(96):
        ch = 32 + i
        r, c = divmod(i, 16)
        x, y = x0 + c * CW, y0 + r * CH
        g = peek(FONT + 8 * i, 8)
        for row in range(8):
            for bit in range(8):
                if g[row] >> (7 - bit) & 1:
                    col = (230, 230, 240) if row < 7 else (110, 110, 130)
                    d.rectangle((x + 4 + bit * S, y + 4 + row * S, x + 4 + (bit + 1) * S - 1,
                                 y + 4 + (row + 1) * S - 1), fill=col)
        frame = None
        if 48 <= ch <= 57:
            frame = (90, 220, 255)
        elif ch >= 123:
            frame = (255, 210, 70)
        if frame:
            d.rectangle((x + 1, y + 1, x + 8 * S + 7, y + 8 * S + 7), outline=frame, width=2)
        label = '%d $%02X' % (ch, ch)
        d.text((x + 2, y + 8 * S + 10), label, fill=kitlib.DIM, font=tiny)
    names = {123: 'lives', 124: 'water', 125: 'keys', 126: 'hammers', 127: 'level'}
    y = y0 + 6 * CH + 6
    d.text((10, y), 'HUD icons: ' + ', '.join('%d %s' % kv for kv in names.items()) +
           '. Characters 32-127 only: PrintChar $E717 prints "?" for any other code.', fill=kitlib.TEXT, font=small)
    d.text((10, y + 20), 'The glyph of character A is at Font - 256 + 8 x A ($F4C9 + 8A): DrawGlyph and PrintHudIcon '
           'load DE = $F4C9.', fill=kitlib.DIM, font=small)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'font.png')
    im.save(path)
    print('font:', os.path.relpath(path, CASE))


def records():
    return [bytearray(peek(HOF + 32 * i, 32)) for i in range(4)]


def score_of(r):
    return r[0x12] | r[0x13] << 8


def enter(tab, name, score):
    """EnterHallOfFame $EC40 + EnterName $ECC0, as the code does it: compare records 0-2; insert above the first
    one not above the score (LDDR moves the rest down, record 3 lost); else overwrite record 3"""
    if score < score_of(tab[3]):
        return tab, None
    k = 3
    for i in range(3):
        if score >= score_of(tab[i]):
            k = i
            break
    new = [bytearray(r) for r in tab]
    for j in range(3, k, -1):
        new[j] = bytearray(new[j - 1])
    rec = new[k]
    rec[0x12], rec[0x13] = score & 255, score >> 8
    rec[6:9] = name.encode()
    rec[0x0C:0x11] = ('%05d' % score).encode()
    for i, r in enumerate(new):
        r[1] = 7 + 3 * i
    return new, k


def hof():
    W, H = 1050, 530
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, small, tiny = kitlib.font(15), kitlib.font(12), kitlib.font(11)
    d.text((10, 8), 'The hall of fame is four PrintText strings with a score word after each: 32 bytes a record '
           'at $EEB3', fill=kitlib.TEXT, font=f)
    d.text((10, 30), 'top: the records as loaded, byte by byte; bottom: the table in twoname after each name entry '
           '(EnterHallOfFame $EC40)', fill=kitlib.DIM, font=small)
    parts = [(0, 3, 'AT row col', (255, 140, 255)), (3, 5, 'ATTR $0F', (120, 255, 120)),
             (5, 6, 'double', (120, 255, 120)), (6, 9, 'name', (255, 230, 60)), (9, 12, '" : "', kitlib.DIM),
             (12, 17, 'score digits', (90, 220, 255)), (17, 18, 'end', kitlib.DIM),
             (18, 20, 'score word', (255, 170, 80)), (20, 32, 'unused', (90, 90, 110))]
    x0, y0, bw = 70, 70, 29
    for n, (lo, hi, name, col) in enumerate(parts):
        d.text((x0 + lo * bw, y0 - 14 * (n % 2)), name, fill=col, font=tiny)
        d.line((x0 + lo * bw, y0 + 16, x0 + hi * bw - 4, y0 + 16), fill=col, width=2)
    tab = records()
    for i, r in enumerate(tab):
        y = y0 + 24 + i * 30
        d.text((10, y + 4), '$%04X' % (HOF + 32 * i), fill=kitlib.DIM, font=small)
        for k, v in enumerate(r):
            col = next(c for lo, hi, _, c in parts if lo <= k < hi)
            d.rectangle((x0 + k * bw, y, x0 + (k + 1) * bw - 4, y + 24), fill=(30, 30, 42))
            d.text((x0 + k * bw + 3, y + 5), '%02X' % v, fill=col, font=small)
    y = y0 + 24 + 4 * 30 + 6
    d.text((10, y), 'Row byte +1 is rewritten to 7, 10, 13, 16 by PrintHallOfFame $ED2D. The score word +$12 is compared, '
           'the digits at +$0C are shown.', fill=kitlib.TEXT, font=small)
    d.text((10, y + 18), 'GameOver $B755 lets a score in when it is not below the last record\'s ($EF25); '
           'EnterHallOfFame compares records 1-3 only.', fill=kitlib.TEXT, font=small)

    def table(x, y, t, title, mark=None):
        d.text((x, y), title, fill=kitlib.TEXT, font=small)
        for i, r in enumerate(t):
            yy = y + 24 + i * 26
            col = (255, 230, 60) if i == mark else (220, 220, 230)
            d.rectangle((x, yy, x + 300, yy + 22), fill=(10, 30, 120) if i != mark else (40, 60, 160))
            d.text((x + 10, yy + 4), '%d  %s : %s   (%d)' % (i + 1, r[6:9].decode(), r[12:17].decode(),
                                                            score_of(r)), fill=col, font=small)

    yt = y + 54
    table(10, yt, tab, 'at power-on')
    t1, k1 = enter(tab, 'BUM', 2000)
    table(350, yt, t1, 'player 1: BUM, 2000 (frames 3030-3300)', k1)
    t2, k2 = enter(t1, 'ZAP', 2100)
    table(690, yt, t2, 'player 2: ZAP, 2100 (frames 4625-4811)', k2)
    yb = yt + 24 + 4 * 26 + 14
    lines = [
        'BUM: 2000 is below 16000, 8000 and 4000, so no record moves and record 4 (POP 1700) is overwritten in place.',
        'ZAP: 2100 is again below the first three, so it overwrites record 4 too: BUM is gone. Only a score of 4000 or '
        'more',
        'would have moved the records below it down one place (LDDR from $EF12 to $EF32).',
        'Names start as "..." ($2E); each letter starts at "@" and is fixed by fire or up (EnterName $ECC0).',
    ]
    for i, t in enumerate(lines):
        d.text((10, yb + i * 19), t, fill=kitlib.DIM, font=small)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'hof.png')
    im.save(path)
    print('hof:', os.path.relpath(path, CASE))


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if what in ('font', 'all'):
        font()
    if what in ('hof', 'all'):
        hof()


if __name__ == '__main__':
    main()
