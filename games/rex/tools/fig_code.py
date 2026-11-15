#!/usr/bin/env python3
"""The access code of doc 1, drawn place by place: what each of the 16 digits holds, and a real code decoded.

    python3 tools/fig_code.py [CODE] [--out docs/img/play/access-code.png]

CODE defaults to 8883898669979809, the code REX 1 printed at the end of the RZX run (`p1-code` frame 1000, `c2`
frame 3250). The layout follows CodePanel `$A7CE` (REX 1) and EnterCode `$DB27` (REX 2): places 0-12 are shown as
9 - digit, places 13-15 are the checksum (the sum of the 13 shown digits: 13 its units, 14 its hundreds, 15 its tens).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

C = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.join(C, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

# place: (what, group); the score digits are named by their power of ten (the score is held in hundreds)
PLACES = [('double fire', 'weapon'), ('score 10^3', 'score'), ('spray', 'weapon'), ('lives', 'state'),
          ('laser', 'weapon'), ('score 10^2', 'score'), ('multiple', 'weapon'), ('score 10^0', 'score'),
          ('shield units', 'state'), ('score 10^1', 'score'), ('bombs', 'state'), ('shield tens', 'state'),
          ('score 10^4', 'score'), ('sum units', 'check'), ('sum hundreds', 'check'), ('sum tens', 'check')]
COLOURS = {'weapon': (230, 110, 200), 'score': (220, 220, 80), 'state': (90, 200, 200), 'check': (255, 130, 90)}


def decode(code):
    shown = [int(c) for c in code]
    value = [9 - d for d in shown[:13]]
    total = sum(shown[:13])
    check = shown[13] + 10 * shown[15] + 100 * shown[14]
    score = (value[12] * 10000 + value[1] * 1000 + value[5] * 100 + value[9] * 10 + value[7])
    return shown, value, total, check, score


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('code', nargs='?', default='8883898669979809')
    p.add_argument('--out', default=os.path.join(C, 'docs/img/play/access-code.png'))
    a = p.parse_args()
    shown, value, total, check, score = decode(a.code)
    w, cell, left, top = 1050, 62, 29, 50
    im = Image.new('RGB', (w, 470), (24, 24, 30))
    d = ImageDraw.Draw(im)
    font, big, small = K.font(16), K.font(28), K.font(13)
    d.text((10, 10), f'The access code {a.code}, place by place (CodePanel $A7CE writes it, EnterCode $DB27 reads it)',
           fill=(240, 240, 240), font=font)
    for i, (what, group) in enumerate(PLACES):
        x = left + i * cell
        d.text((x + 20, top), str(i), fill=(200, 200, 200), font=small)
        d.rectangle((x + 2, top + 20, x + cell - 4, top + 70), fill=COLOURS[group])
        d.text((x + 20, top + 28), str(shown[i]), fill=(0, 0, 0), font=big)
        if i < 13:
            d.text((x + 8, top + 80), f'9-{shown[i]}', fill=(220, 220, 220), font=small)
            d.text((x + 22, top + 98), str(value[i]), fill=(255, 255, 255), font=font)
        # the name, written down the column; odd places lower, so neighbours never overlap
        for k, word in enumerate(what.split(' ')):
            d.text((x + 4, top + 124 + 38 * (i % 2) + 17 * k), word, fill=COLOURS[group], font=small)
    y = top + 222
    lives, shield, bombs = value[3], value[11] * 10 + value[8], value[10]
    lines = [
        ('top: the place; box: the digit as printed; under it: 9 - digit, the value it holds (places 0-12)', None),
        (f'weapons held (places 0, 2, 4, 6): double fire {value[0]}, spray {value[2]}, laser {value[4]}, '
         f'multiple {value[6]}', 'weapon'),
        (f'score (places 12, 1, 5, 9, 7, most significant first): {value[12]}{value[1]}{value[5]}{value[9]}{value[7]}'
         f' = {score} hundreds = {score * 100} points', 'score'),
        (f'lives {lives} (place 3); shield {shield} (places 11 and 8); bombs {bombs} (place 10, must be under 4)',
         'state'),
        (f'checksum: the 13 printed digits add up to {total}; units, tens, hundreds in places 13, 15, 14: '
         f'{check}', 'check'),
        ('a code is good when the sums agree, the sum is not 0 and the bombs are under 4; otherwise INVALID CODE',
         None),
    ]
    for text, group in lines:
        d.text((12, y), text, fill=COLOURS.get(group, (230, 230, 230)), font=font)
        y += 30
    im = im.crop((0, 0, w, y + 10))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size, 'sum', total, 'check', check, 'score', score)


if __name__ == '__main__':
    sys.exit(main())
