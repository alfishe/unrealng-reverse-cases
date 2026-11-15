#!/usr/bin/env python3
"""The tape of doc 3 as a picture: both sides block by block on one time scale, at ROM speed, pauses included.

    python3 tools/fig_tape.py [--side1 build/orig-1.tzx] [--side2 build/orig-2.tzx] [--out docs/img/load/tape.png]

Each data block is a bar as long as it plays (tools/tzxblocks.py's timings at 3.5 MHz), coloured by what it holds
(a header, a BASIC, a screen, a code block); the pause after it is a thin grey bar. Under each long block: its
number, its program, its bytes and its time. Where each part's code starts to
run is not marked here; doc 3, 3.3 gives those frames from the recordings.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

C = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.join(C, 'tools'))
sys.path.insert(0, os.path.join(C, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import tzxblocks as T  # noqa: E402

COLOURS = {'header': (250, 210, 70), 'BASIC': (90, 200, 110), 'screen': (90, 130, 240), 'code': (230, 80, 80)}


def blocks(path):
    """[(number, what, bytes, seconds, pause seconds, name)] for the data blocks, numbered as doc 3 does (TZX index)"""
    out, last = [], None
    for b in T.parse(open(path, 'rb').read()):
        if b['kind'] != 'standard':
            continue
        data = b['data']
        if data[0] == 0 and len(data) == 19:
            what = 'header'
            kind = data[1]
            if kind == 0:
                last = data[2:12].decode('latin-1').strip()
        elif kind == 0:
            what = 'BASIC'
        elif len(data) == 6914:
            what = 'screen'
        else:
            what = 'code'
        out.append((b['index'], what, len(data), T.seconds(b), b['pause'] / 1000, last))
    return out


def lane(d, rows, x0, y, scale, small, label_y):
    t, lab = 0.0, 0
    for n, what, size, sec, pause, name in rows:
        x = x0 + t * scale
        d.rectangle((x, y, x + max(2, sec * scale) - 1, y + 34), fill=COLOURS[what])
        if what in ('code', 'screen'):
            d.text((x + 3, y + 9), f'{n}', fill=(0, 0, 0), font=small)
            text = f'{n}: {name} {what}, {size} B, {sec:.1f} s'
            d.text((x + 2, label_y + 18 * lab), text, fill=COLOURS[what], font=small)
            lab = 1 - lab
        t += sec
        d.rectangle((x0 + t * scale, y + 14, x0 + (t + pause) * scale, y + 20), fill=(110, 110, 120))
        t += pause
    return t


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--side1', default=os.path.join(C, 'build/orig-1.tzx'))
    p.add_argument('--side2', default=os.path.join(C, 'build/orig-2.tzx'))
    p.add_argument('--out', default=os.path.join(C, 'docs/img/load/tape.png'))
    a = p.parse_args()
    s1, s2 = blocks(a.side1), blocks(a.side2)
    rex2 = [r for r in s1 if r[0] >= 7]
    total = sum(r[3] + r[4] for r in s1)
    w, x0 = 1050, 110
    scale = (w - x0 - 20) / total
    im = Image.new('RGB', (w, 520), (24, 24, 30))
    d = ImageDraw.Draw(im)
    font, small = K.font(16), K.font(13)
    d.text((10, 8), 'The two sides of the tape at ROM speed: every block as long as it plays, the pauses in grey',
           fill=(240, 240, 240), font=font)
    rows = [('side 1', s1, 70), ('side 1 from\nblock 7', rex2, 210), ('side 2', s2, 350)]
    for name, r, y in rows:
        d.multiline_text((10, y + 4), name, fill=(240, 240, 240), font=small)
        end = lane(d, r, x0, y, scale, small, y + 40)
        d.text((x0 + end * scale - 70, y - 20), f'{end:.0f} s', fill=(200, 200, 200), font=small)
    for s in range(0, int(total) + 1, 60):
        x = x0 + s * scale
        d.line((x, 470, x, 476), fill=(200, 200, 200))
        d.text((x - 8, 478), f'{s} s', fill=(200, 200, 200), font=small)
    x = x0
    for what, colour in COLOURS.items():
        d.rectangle((x, 500, x + 14, 512), fill=colour)
        d.text((x + 18, 498), what, fill=(220, 220, 220), font=small)
        x += 110
    d.rectangle((x, 504, x + 14, 508), fill=(110, 110, 120))
    d.text((x + 18, 498), 'pause after a block', fill=(220, 220, 220), font=small)
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size, f'side 1 {total:.1f} s')


if __name__ == '__main__':
    sys.exit(main())
