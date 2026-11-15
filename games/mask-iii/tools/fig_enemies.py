#!/usr/bin/env python3
"""Doc 1's enemy figure: every enemy the screens spawn, its picture (src/res/sprites), and its template's numbers
(EnemyTemplates $BE3B: the score, the damage to Matt's energy, the hits) with the screens that spawn it (RoomTable
bytes 6-11, src/res/tables/rooms.csv).

    python3 tools/fig_enemies.py      # docs/img/design/enemies.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

SPR = os.path.join(CASE, 'src', 'res', 'sprites')
OUT = os.path.join(CASE, 'docs', 'img', 'design')
BG, FG, DIM, HEAD = (24, 24, 30), (235, 235, 235), (175, 175, 185), (255, 200, 90)

# (screen kind or source, the name in these documents, sprite file, frame width in characters, template index)
ROWS = [
    ('1', 'flyer', 'flyer.png', 3, 1),
    ('2', 'faller', 'faller.png', 2, 0),
    ('3', 'wave flyer', 'wave.png', 2, 4),
    ('4', 'walker', 'walker.png', 2, 5),
    ('5', 'chaser', 'chaser.png', 8, 6),
    ('6', 'kind 6 (obj 16)', 'big.png', 4, 12),
    ('7', 'riser', 'faller.png', 2, 8),
    ('8', 'guard', 'guard.png', 4, 9),
    ('9', 'boss', 'boss.png', 4, 10),
    ('9', 'the boss\'s shot', 'boss-shot.png', 2, 11),
    ('10', 'kind 10 (obj 18, 19)', 'part1.png', 3, 13),
    ('map', 'turret (block $12)', 'turret.png', 3, 2),
    ('map', 'the turret\'s shot', 'turret-shot.png', 1, 3),
]


def templates():
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    o = 0xBE3B - 0x6000
    return [img[o + 12 * k:o + 12 * k + 12] for k in range(20)]


def where(kind):
    rooms = open(os.path.join(CASE, 'src', 'res', 'tables', 'rooms.csv')).read().split('\n')[1:]
    out = []
    for line in rooms:
        f = line.split(',')
        if len(f) < 13 or not f[0].isdigit():
            continue
        for s in range(6):
            if int(f[7 + s], 16) == kind:
                out.append(f'{f[0]}/{s}')
    return out


def bcd(lo, hi):
    return int(f'{hi:02X}{lo:02X}')


def main():
    os.makedirs(OUT, exist_ok=True)
    big, mid = kitlib.font(16), kitlib.font(14)
    row_h, pic_w = 84, 210
    cols = [10, 10 + pic_w + 10, 470, 560, 640, 700]
    im = Image.new('RGB', (1050, 90 + len(ROWS) * row_h + 30), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), 'MASK III: the enemies, their pictures and their templates (EnemyTemplates $BE3B)', fill=FG,
           font=big)
    for x, t in zip(cols, ['picture (frame 0, x3)', 'screen kind: name', 'score', 'damage', 'hits',
                           'screens (room/screen) that spawn it']):
        d.text((x, 50), t, fill=HEAD, font=mid)
    tp = templates()
    for i, (kind, name, f, wch, k) in enumerate(ROWS):
        y = 80 + i * row_h
        sheet = Image.open(os.path.join(SPR, f)).convert('L')
        frame = sheet.crop((0, 0, wch * 8, sheet.height))
        frame = frame.point(lambda v: 255 if v else 0).resize((frame.width * 3, frame.height * 3), Image.NEAREST)
        frame = Image.merge('RGB', (frame, frame, frame))
        im.paste((0, 0, 0), (cols[0], y, cols[0] + pic_w - 8, y + 74))
        im.paste(frame.crop((0, 0, min(frame.width, pic_w - 8), min(frame.height, 74))), (cols[0], y))
        r = tp[k]
        d.text((cols[1], y + 4), f'{kind}: {name}', fill=FG, font=big)
        d.text((cols[1], y + 28), f'template {k} ${0xBE3B + 12 * k:04X}, {f}', fill=DIM, font=mid)
        d.text((cols[2], y + 4), str(bcd(r[0], r[1])), fill=FG, font=big)
        d.text((cols[3], y + 4), str(r[4]), fill=FG, font=big)
        d.text((cols[4], y + 4), str(r[10]), fill=FG, font=big)
        places = where(int(kind)) if kind.isdigit() else ['every block $12 of a screen']
        line, lines = '', []
        for p in places:
            if len(line) + len(p) > 38:
                lines.append(line)
                line = ''
            line += ('' if not line else ' ') + p
        lines.append(line)
        for j, t in enumerate(lines[:3]):
            d.text((cols[5], y + 4 + 20 * j), t, fill=DIM if kind == '9' and 'shot' in name else FG, font=mid)
    d.text((10, 80 + len(ROWS) * row_h + 4), 'damage: taken from Energy $AEA6 (255 full) on contact by Damage $C2CA; '
                                             'hits: the template\'s +$0A, copied to +$21', fill=DIM, font=mid)
    im.save(os.path.join(OUT, 'enemies.png'))
    print(os.path.join(OUT, 'enemies.png'), im.size)


if __name__ == '__main__':
    main()
