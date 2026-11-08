#!/usr/bin/env python3
"""A recorded scene as a strip of its own screens, for a 900 px page (docs/scenes.md).

    python3 tools/fig_scene_strip.py OUT.png --title TEXT [--cols 2] [--crop X,Y,W,H] REC:FRAME:CAPTION ...

Each REC:FRAME is the recording's screen nearest that frame (`work/<rec>/frames/*.scr`, then `work/<rec>/screens/`),
(or the --crop part of it) drawn at the scale that fits --cols columns into 900 px, with the frame actually shown and the caption under it.
`--list REC` prints the frames a recording has.
"""
import argparse
import bisect
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 900


def frames(rec):
    out = {}
    for sub in ('screens', 'frames'):            # frames/ wins where both have one
        d = os.path.join(CASE, 'work', rec, sub)
        if os.path.isdir(d):
            for n in os.listdir(d):
                if n.endswith('.scr'):
                    out[int(n[:-4])] = os.path.join(d, n)
    return out


def screen(path):
    mem = bytearray(0x10000)
    data = open(path, 'rb').read()[:6912]
    mem[0x4000:0x4000 + len(data)] = data
    return K.render_screen(mem, 0x4000)


def wrap(d, text, font, width):
    out, line = [], ''
    for word in text.split():
        cand = (line + ' ' + word).strip()
        if d.textlength(cand, font=font) > width and line:
            out.append(line)
            line = word
        else:
            line = cand
    return out + [line] if line else out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('out', nargs='?')
    p.add_argument('shots', nargs='*')
    p.add_argument('--title', default='')
    p.add_argument('--cols', type=int, default=2)
    p.add_argument('--crop', default='0,0,256,192')
    p.add_argument('--list')
    a = p.parse_intermixed_args()
    if a.list:
        print(' '.join(str(f) for f in sorted(frames(a.list))))
        return
    f13, f14, f17 = K.font(13), K.font(14), K.font(17)
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    gap = 16
    cw = (W - 20 - gap * (a.cols - 1)) // a.cols
    cx, cy, cwid, chei = (int(v) for v in a.crop.split(','))
    scale = cw / cwid
    sh = int(chei * scale)
    cells = []
    for spec in a.shots:
        rec, fr, cap = spec.split(':', 2)
        have = frames(rec)
        keys = sorted(have)
        i = bisect.bisect_left(keys, int(fr))
        near = min(keys[max(0, i - 1):i + 1], key=lambda k: abs(k - int(fr)))
        pic = screen(have[near]).crop((cx, cy, cx + cwid, cy + chei)).resize((cw, sh), Image.NEAREST)
        lines = wrap(probe, '%s %d: %s' % (rec, near, cap), f14, cw)
        cells.append((pic, lines))
    title = wrap(probe, a.title, f17, W - 20)
    top = 10 + 23 * len(title) + 8
    rows = [cells[i:i + a.cols] for i in range(0, len(cells), a.cols)]
    heights = [sh + 6 + 19 * max(len(c[1]) for c in row) + 14 for row in rows]
    im = Image.new('RGB', (W, top + sum(heights)), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    for i, line in enumerate(title):
        d.text((10, 10 + 23 * i), line, fill=K.TEXT, font=f17)
    y = top
    for row, h in zip(rows, heights):
        for j, (pic, lines) in enumerate(row):
            x = 10 + j * (cw + gap)
            im.paste(pic, (x, y))
            for k, line in enumerate(lines):
                d.text((x, y + sh + 6 + 19 * k), line, fill=K.TEXT, font=f14)
        y += h
    im.save(a.out)
    print('%s: %s, %d screens' % (a.out, im.size, len(cells)))


if __name__ == '__main__':
    sys.exit(main())
