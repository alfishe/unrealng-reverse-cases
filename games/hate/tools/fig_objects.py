#!/usr/bin/env python3
"""Doc 7.3 / 1.10 figure: screens of the demo with every visible object record named at its sprite
(docs/img/objects-demo.png), from memory images saved by objects_shot.py (TTD memory_at, 64 K .bin).

Each live record of the list `$C000` that lies on the screen gets a dot where the isometric projection puts it
(x = distance - across, line = 215 - distance / 2 - across / 2 - height, distance = position - `$D14D`; doc 7.1) and
its kind (doc 7.3 table) in a label with a leader line. Labels that would overlap are moved up.

    python3 tools/fig_objects.py work/render/mem-41750.bin work/render/mem-45000.bin docs/img/objects-demo.png \
        --titles "frame 41 750, paused" "frame 45 000"
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zxscreen  # noqa: E402

NAMES = {0: 'player', 1: 'player', 2: 'dome', 3: 'dome', 4: 'missile', 5: 'missile', 6: 'missile', 7: 'missile',
         8: 'jet', 9: 'jet', 10: 'cube', 11: 'pod', 12: 'shot', 14: 'pad', 15: 'dish'}
BG = (24, 24, 30)
S = 2  # screen scale


def records(mem):
    """[(type, x, line)] of the live records on the screen, in list order"""
    scrolled = mem[0xD14D] | mem[0xD14E] << 8
    out, a = [], 0xC000
    while not mem[a] & 0x40:
        r = mem[a:a + 16]
        if not r[0] & 0x80:
            dist = (r[1] | r[2] << 8) - scrolled
            if 0 <= dist < 0x11F:
                out.append((r[0] & 15, dist - r[3] - 11, 215 - dist // 2 - r[3] // 2 - r[4] - 5))
        a += 16
    return out


def panel(mem, title, font, small):
    screen = zxscreen.render(mem[0x4000:0x5B00], S)
    img = Image.new('RGB', (screen.width, screen.height + 34), BG)
    img.paste(screen, (0, 34))
    d = ImageDraw.Draw(img)
    d.text((0, 6), title, fill=(235, 235, 220), font=font)
    boxes = []
    for kind, x, y in records(mem):
        if not (0 <= x < 256 and 0 <= y < 192):
            continue
        px, py = x * S, y * S + 34
        text = NAMES.get(kind, str(kind))
        w = int(d.textlength(text, font=small)) + 6
        lx, ly = min(max(0, px - w // 2), screen.width - w - 1), py - 30
        while any(not (lx + w < bx or lx > bx + bw or ly + 16 < by or ly > by + 16) for bx, by, bw in boxes):
            ly -= 17
        boxes.append((lx, ly, w))
        d.line((px, py, lx + w // 2, ly + 16), fill=(255, 255, 255), width=1)
        d.ellipse((px - 3, py - 3, px + 3, py + 3), fill=(255, 60, 255), outline=(0, 0, 0))
        d.rectangle((lx, ly, lx + w, ly + 16), fill=(20, 20, 26))
        d.text((lx + 3, ly + 1), text, fill=(255, 255, 255), font=small)
    return img


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('mems', nargs='+')
    p.add_argument('out')
    p.add_argument('--titles', nargs='+')
    args = p.parse_args()
    font, small = ImageFont.load_default(size=17), ImageFont.load_default(size=13)
    panels = [panel(open(m, 'rb').read(), t, font, small) for m, t in zip(args.mems, args.titles)]
    img = Image.new('RGB', (sum(x.width for x in panels) + 16 * (len(panels) - 1), panels[0].height + 26), BG)
    x = 0
    for im in panels:
        img.paste(im, (x, 0))
        x += im.width + 16
    d = ImageDraw.Draw(img)
    d.text((0, panels[0].height + 5), 'magenta dot: where the record\'s position puts the object; '
           'label: its kind, from the type in byte +0', fill=(180, 180, 170), font=small)
    img.save(args.out)
    print(args.out)


if __name__ == '__main__':
    main()
