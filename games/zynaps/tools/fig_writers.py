#!/usr/bin/env python3
"""kit/writers_map.py with its four panels stacked two by two, so a zoomed panel stays readable at ~900 px.

    python3 tools/fig_writers.py --out docs/img/hud/writers-panel.png --zoom 0,152,128,40 --title T -- <writers_map args>

Runs R/kit/writers_map.py --scale 1 with the zoom into a temporary file (work/zyB/check), then cuts the four panels
and the legend out of it (the kit's layout: panels side by side from x 12, y 34, gaps of 12) and lays them out as
view over writers on the left, zoom over zoomed writers on the right, the legend below.
"""
import argparse
import os
import subprocess
import sys

from PIL import Image, ImageDraw

import zybplot as P

KIT = os.path.normpath(os.path.join(P.CASE, '..', '..', 'kit'))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', required=True)
    p.add_argument('--zoom', required=True)
    p.add_argument('--title', default='')
    p.add_argument('rest', nargs=argparse.REMAINDER)
    a = p.parse_args()
    rest = [r for r in a.rest if r != '--']
    tmp = os.path.join(P.CASE, 'work', 'zyB', 'check', 'writers-raw.png')
    os.makedirs(os.path.dirname(tmp), exist_ok=True)
    subprocess.run([sys.executable, os.path.join(KIT, 'writers_map.py'), *rest, '--scale', '1', '--zoom', a.zoom,
                    '--out', tmp, '--title', 'x'], check=True, cwd=P.CASE)
    raw = Image.open(tmp).convert('RGB')
    zx, zy, zw, zh = (int(v) for v in a.zoom.split(','))
    f = max(2, min(12, 192 // zh))
    gap, top = 12, 34
    view = raw.crop((gap, top, gap + 256, top + 192))
    wr = raw.crop((2 * gap + 256, top, 2 * gap + 512, top + 192))
    x3 = 3 * gap + 512
    z1 = raw.crop((x3, top, x3 + zw * f, top + zh * f))
    z2 = raw.crop((x3 + zw * f + gap, top, x3 + 2 * zw * f + gap, top + zh * f))
    legend = raw.crop((0, top + 192 + 20, min(raw.width, 900), raw.height))
    W = gap * 3 + 256 + zw * f
    th = 18 * a.title.count('\\n')
    H = th + top + 18 + max(2 * 192 + 22, 2 * zh * f + 22) + legend.height
    img = Image.new('RGB', (max(W, legend.width), H), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((gap, 8), a.title.replace('\\n', '\n'), fill=P.K.TEXT, font=P.K.font(14))
    y0 = th + top + 4
    img.paste(view, (gap, y0))
    d.text((gap, y0 + 193), 'the screen at the window\'s end', fill=P.K.DIM, font=P.K.font(11))
    img.paste(wr, (gap, y0 + 192 + 22))
    d.text((gap, y0 + 2 * 192 + 23), 'who wrote each byte last', fill=P.K.DIM, font=P.K.font(11))
    xz = 2 * gap + 256
    img.paste(z1, (xz, y0))
    d.text((xz, y0 + zh * f + 1), f'zoom: x {zx}-{zx + zw - 1}, y {zy}-{zy + zh - 1}', fill=P.K.DIM,
           font=P.K.font(11))
    img.paste(z2, (xz, y0 + zh * f + 22))
    d.text((xz, y0 + 2 * zh * f + 23), 'zoom, writers', fill=P.K.DIM, font=P.K.font(11))
    for k in range(2):
        yy = y0 + k * (192 + 22)
        d.rectangle([gap + zx, yy + zy, gap + zx + zw, yy + zy + zh], outline=(255, 255, 255))
    img.paste(legend, (0, th + top + 18 + max(2 * 192 + 22, 2 * zh * f + 22)))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    img.save(a.out)
    print('wrote', os.path.relpath(os.path.abspath(a.out), P.CASE), img.size)


if __name__ == '__main__':
    main()
