#!/usr/bin/env python3
"""Doc 08's figures: the font as Print maps it, the HUD's fields with their places, the time bonus as the game
computes it against the formula it means.

    python3 tools/fig_hud.py docs/img/hud

font.png     every glyph Print `$7608` can reach, from src/res/sprites/game.png at 4 x: `A`-`Z` (the character less
             `$23`: sprites `$1E-$37`), `0`-`9` (plus `$69`: `$99-$A2`, drawn a line higher), `a`-`j` (plus `$2C`: the
             big digits `$8D-$96`), `!` `$56`, `"` `$5B`, `.` `$6F`, the end mark `$70` (a raw sprite number), and the
             HUD's word sprites (SPEED `$97`, FUEL `$98`, clock `$A3`, max `$A4`).
fields.png   recording c1, frame 15419 (one player, trail 1): the HUD's fields and the side panel with the places
             the code gives them (SpeedBar `$E55D`, UseFuel `$DF91`, ClockPlace `$EB3C`, ShowMaxTime `$EACF`,
             ShowScore `$EE37`), drawn on the screenshot docs/img/play/c1-015419-c1.png.
bonus.png    FinishCheck `$DB34`: Bonus = ((MaxTime - clock) / 2 + 1, low byte only) x (Trail + 1) + 1, against the
             value without the lost high byte, for a 600-pass trail (trails 1-3) and trail 1; the warp recording's
             finish (clock 062, Bonus 15) marked.
"""
import csv
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 1050
SPR = os.path.join(CASE, 'src', 'res', 'sprites')
YEL, RED, CYAN, GREEN, VIOLET = (240, 200, 70), (240, 90, 80), (90, 200, 220), (120, 220, 120), (200, 110, 230)


def sheet():
    im = Image.open(os.path.join(SPR, 'game.png'))
    rows = {}
    for r in csv.DictReader(open(os.path.join(SPR, 'game.csv'))):
        if r['kind'] == 'sprite':
            for n in r['numbers'].split():
                rows[int(n)] = r
    return im, rows


def glyph(im, r, s, ink=(235, 235, 240), paper=(40, 40, 52)):
    x, y, w, h = int(r['x']), int(r['y']), int(r['width']) * 8, int(r['height'])
    px = im.load()
    out = Image.new('RGB', (w * s, h * s), paper)
    d = ImageDraw.Draw(out)
    for j in range(h):
        for i in range(w):
            if px[x + i, y + j] == 1:
                d.rectangle((i * s, j * s, i * s + s - 1, j * s + s - 1), fill=ink)
    return out


def font(path, im, rows):
    groups = [
        ('A-Z: the character - $23 (sprites $1E-$37), advance + 2 pixels each', [(chr(c), c - 0x23) for c in range(65, 91)]),
        ('0-9: + $69 (sprites $99-$A2), drawn one line higher', [(chr(c), c + 0x69) for c in range(48, 58)]),
        ('a-j: + $2C, the big digits $8D-$96 (the clock, the trail number)', [(chr(c), c + 0x2C) for c in range(97, 107)]),
        ('the other glyphs and the HUD words', [('!', 0x56), ('"', 0x5B), ('.', 0x6F), ('end', 0x70), ('SPEED', 0x97),
                                                ('FUEL', 0x98), ('clock', 0xA3), ('max', 0xA4)]),
    ]
    s = 4
    H = 760
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    big, mid, small = K.font(15), K.font(12), K.font(11)
    d.text((14, 10), 'The font as Print $7608 maps it: a character is a game sprite (4 x, a grid line a byte)',
           fill=K.TEXT, font=big)
    y = 40
    for title, items in groups:
        d.text((14, y), title, fill=YEL, font=mid)
        y += 22
        x, rowh = 14, 0
        for ch, n in items:
            g = glyph(im, rows[n], s)
            if x + g.width > W - 14:
                x, y, rowh = 14, y + rowh + 8, 0
            out.paste(g, (x, y + 16))
            for b in range(1, int(rows[n]['width'])):
                d.line((x + b * 8 * s, y + 16, x + b * 8 * s, y + 16 + g.height - 1), fill=(90, 90, 110))
            d.text((x, y), f'{ch} ${n:02X}', fill=K.TEXT, font=small)
            x += max(g.width, 50) + 10
            rowh = max(rowh, g.height + 16)
        y += rowh + 18
    d.text((14, H - 46), 'Space moves x by 6, "]" sets x to $78 (the menus\' key column), "|" ends the text. Any other '
           'code from $6B up is drawn as that sprite number.', fill=K.DIM, font=mid)
    d.text((14, H - 26), 'Pixels: src/res/sprites/game.png. No recording. Command: python3 tools/fig_hud.py '
           'docs/img/hud', fill=K.DIM, font=mid)
    out.save(path)


def fields(path):
    shot = Image.open(os.path.join(CASE, 'docs', 'img', 'play', 'c1-015419-c1.png')).convert('RGB')
    k = 1.25
    shot = shot.resize((int(512 * k), int(384 * k)), Image.NEAREST)
    H = 540
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    big, mid = K.font(15), K.font(12)
    d.text((14, 10), 'The HUD: each field, its place and the routine that writes it (screen pixels, y from the top)',
           fill=K.TEXT, font=big)
    ox, oy = 14, 40
    im.paste(shot, (ox, oy))
    f = 2 * k

    def box(x1, y1, x2, y2):
        return (ox + x1 * f, oy + y1 * f, ox + (x2 + 1) * f - 1, oy + (y2 + 1) * f - 1)
    items = [
        ((64, 1, 107, 6), CYAN, 'SPEED bar: $40 + ((speed-1) x 2 AND $FC)', 'SpeedBar $E55D, BarNibble $E5A1'),
        ((144, 1, 175, 6), RED, 'FUEL bar: $90 to FuelBar ($B0 full)', 'UseFuel $DF91, FuelBarStep $DFCD'),
        ((68, 89, 111, 102), GREEN, 'clock: big at $44, $52, small at $60',
         'ClockTick $EB53: ModeCopyScreen'),
        ((124, 89, 153, 102), YEL, 'max: MaxTime "60" big at $7C, $8A', 'ShowMaxTime $EACF: once a trail'),
        ((204, 30, 239, 44), VIOLET, 'score 1: five digits, x $E8 the tens, y $9B',
         'ScoreUpP1 $EDBB: XOR off, XOR on'),
        ((204, 126, 239, 140), VIOLET, 'score 2: y $3B', 'ScoreUpP2 $EDC3'),
    ]
    tx, ty = ox + int(512 * k) + 20, 46
    for n, ((x1, y1, x2, y2), col, t1, t2) in enumerate(items, 1):
        b = box(x1, y1, x2, y2)
        d.rectangle(b, outline=col, width=3)
        cx, cy = b[0] - 2, b[1] - 2
        d.ellipse((cx - 11, cy - 11, cx + 11, cy + 11), fill=col)
        d.text((cx - 4, cy - 8), str(n), fill=(0, 0, 0), font=mid)
        d.ellipse((tx, ty, tx + 22, ty + 22), fill=col)
        d.text((tx + 7, ty + 3), str(n), fill=(0, 0, 0), font=mid)
        words = t1.split(': ')
        d.text((tx + 30, ty), words[0] + ':', fill=col, font=mid)
        d.text((tx + 30, ty + 17), words[1], fill=K.TEXT, font=mid)
        d.text((tx + 30, ty + 34), t2, fill=K.DIM, font=mid)
        ty += 72
    d.text((14, H - 26), 'Recording c1, frame 15419: clock 052, score 00100. Command: python3 tools/fig_hud.py '
           'docs/img/hud', fill=K.DIM, font=mid)
    im.save(path)


def bonus(path):
    H = 480
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    big, mid, small = K.font(15), K.font(12), K.font(11)
    d.text((14, 10), 'Trail 1\'s time bonus (MaxTime 600): as FinishCheck computes it, against the formula without '
           'the lost byte', fill=K.TEXT, font=big)
    x0, y0, x1, y1 = 80, 50, W - 30, H - 70
    maxc, maxb = 600, 310
    d.rectangle((x0, y0, x1, y1), outline=(70, 70, 85))

    def px(c, b):
        return x0 + (x1 - x0) * c / maxc, y1 - (y1 - y0) * b / maxb
    for b in range(0, maxb, 50):
        d.line((x0, px(0, b)[1], x1, px(0, b)[1]), fill=(40, 40, 52))
        d.text((x0 - 40, px(0, b)[1] - 7), str(b), fill=K.DIM, font=small)
    for c in range(0, maxc + 1, 50):
        d.text((px(c, 0)[0] - 10, y1 + 6), f'{c:03d}', fill=K.DIM, font=small)
    good, game = [], []
    for c in range(0, maxc + 1):
        half = (maxc - c) // 2 + 1
        good.append(px(c, half * 1 + 1))
        game.append(px(c, (half & 0xFF) * 1 + 1))
    d.line(good, fill=GREEN, width=2)
    d.line(game, fill=RED, width=3)
    wx, wy = px(62, 15)
    d.ellipse((wx - 6, wy - 6, wx + 6, wy + 6), outline=YEL, width=3)
    d.text((wx + 10, wy - 26), 'warp: clock 062, Bonus 15 (not 271)', fill=YEL, font=mid)
    cx = px(90, 0)[0]
    d.line((cx, y0, cx, y1), fill=(90, 90, 110))
    d.text((cx + 6, y0 + 6), 'clock 090: (600 - 90) / 2 + 1 = 256 -> 0', fill=K.TEXT, font=small)
    d.text((x0 + 300, y0 + 40), 'green: (MaxTime - clock) / 2 + 1, + 1', fill=GREEN, font=mid)
    d.text((x0 + 300, y0 + 60), 'red: the same with only the low byte kept (LD E,L at $DB75)', fill=RED, font=mid)
    d.text((x0 + 300, y0 + 80), 'trail N multiplies both by N; a point is 10 on the screen', fill=K.TEXT, font=mid)
    d.text((14, y1 + 26), 'x: the clock at the finish (passes); y: Bonus points. Computed from the code; the warp '
           'point is the recording.', fill=K.DIM, font=mid)
    d.text((14, H - 22), 'Command: python3 tools/fig_hud.py docs/img/hud', fill=K.DIM, font=small)
    im.save(path)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(CASE, 'docs', 'img', 'hud')
    os.makedirs(out, exist_ok=True)
    im, rows = sheet()
    font(os.path.join(out, 'font.png'), im, rows)
    fields(os.path.join(out, 'fields.png'))
    bonus(os.path.join(out, 'bonus.png'))


if __name__ == '__main__':
    main()
