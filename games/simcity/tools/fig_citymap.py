#!/usr/bin/env python3
"""A whole city with its figures (doc 1.9): the 96 x 96 map drawn by tools/fig_city.py (768 x 768, one cell 8 x 8
pixels) and, beside it, what the memory image says of the city: its name, date, funds, last year's population, and
the cells of the map counted by kind (CellFlags `$6F9C`).

    python3 tools/fig_citymap.py work/stage1/rec/metro/end.szx docs/img/maps/metro-end.png --title "metro, frame 96 503"
"""
import argparse
import csv
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_city  # noqa: E402
import szx  # noqa: E402

MONTHS = 'JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC'.split()


def font(size):
    for f in ('/System/Library/Fonts/Menlo.ttc', '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def flags():
    out = {}
    with open(os.path.join(HERE, '..', 'src', 'res', 'tables', 'CellFlags.csv')) as fh:
        for row in csv.reader(l for l in fh if not l.startswith('#')):
            if row[0].startswith('$'):
                out[int(row[0][1:], 16)] = int(row[1][1:], 2)
    return out


def kinds(city):
    fl = flags()
    n = {}
    def add(k):
        n[k] = n.get(k, 0) + 1
    for b in city:
        f = fl.get(b, 0)
        if b >= 0x80:
            add('building cells')
        elif b == 0:
            add('water')
        elif b in (1, 3, 4, 5):
            add('coast')
        elif b == 2:
            add('land')
        elif b == 6:
            add('trees')
        elif f & 0x10:
            add('zone cells')
        elif f & 0x04:
            add('road')
        elif f & 0x02:
            add('rail')
        elif f & 0x08:
            add('power line')
        elif 0x38 <= b <= 0x39:
            add('park')
        else:
            add('other')
    return n


def main():
    p = argparse.ArgumentParser()
    p.add_argument('szx')
    p.add_argument('out')
    p.add_argument('--title', default='')
    a = p.parse_args()
    mem = szx.read(a.szx)[0]
    city = bytes(mem[0xC450:0xC450 + 9216])
    img = fig_city.draw(city)
    W, H = 1050, 768 + 40
    fig = Image.new('RGB', (W, H), (14, 14, 20))
    fig.paste(img, (0, 40))
    d = ImageDraw.Draw(fig)
    d.text((8, 10), a.title, font=font(16), fill='white')
    f = font(14)
    name = bytes(mem[0x5F68:0x5F74]).decode('latin-1').strip()
    funds = mem[0x8F97] | mem[0x8F98] << 8 | mem[0x8F99] << 16
    year = mem[0x8F9C] | mem[0x8F9D] << 8
    pop = mem[0x8E90] | mem[0x8E91] << 8 | mem[0x8E92] << 16
    lines = [('city', name), ('date', f'{MONTHS[mem[0x8F9B] % 12]} {year}'), ('funds', f'${funds}'),
             ('people last year', f'{pop}'), ('', ''), ('cells by kind', '')]
    for k, v in sorted(kinds(city).items(), key=lambda kv: -kv[1]):
        lines.append((k, str(v)))
    y = 50
    for k, v in lines:
        if k and not v:
            d.text((780, y), k, font=f, fill=(240, 200, 70))
        elif k:
            d.text((780, y), k, font=f, fill=(210, 210, 220))
            d.text((1040, y), v, font=f, fill='white', anchor='ra')
        y += 22
    d.text((780, H - 104), 'zone cells: houses, frames,', font=f, fill=(154, 154, 168))
    d.text((780, H - 82), 'centres; building cells: grown', font=f, fill=(154, 154, 168))
    d.text((780, H - 60), 'zones, stations; 8 x 8 px a cell,', font=f, fill=(154, 154, 168))
    d.text((780, H - 38), 'the screen shows 32 x 16 cells', font=f, fill=(154, 154, 168))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    fig.save(a.out)
    print(a.out, name, MONTHS[mem[0x8F9B] % 12], year, funds, pop)


if __name__ == '__main__':
    main()
