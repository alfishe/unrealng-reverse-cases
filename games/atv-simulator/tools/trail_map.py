#!/usr/bin/env python3
"""Draw ATV Simulator's six trails from the resources: src/res/trails/*.txt (the records, the lists, the animation
records) with the sprites of src/res/sprites/game.png, through tools/res_formats.py (the bytes the build makes).

    python3 tools/trail_map.py OUT.png [TRAIL ...]     # TRAIL 1-6, default all six

Each trail is a strip read left to right, one distance unit a pixel, wrapped every 1024 units: list A (the ground
pieces and the obstacles, each at its distance with its sprite, y counted up from the band's base line, y = 0 the
sprite's own height) above list B (the scenery, its own band); the red line is the finish (the length less $48,
FinishCheck). An item with flags bit 0 takes its picture from the menu bank (src/res/sprites/menu.png, PlaceItem's
MenuSprite), the others from the game bank; nothing is mirrored. An item drawn from an
animation record shows the record's sprite with a yellow mark under it. The drawing is a map of the data, not the
screen: the game scrolls list B at a quarter of list A's speed.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import res_formats as rf  # noqa: E402

NAMES = ['SAND DUNING', 'GRASSTRAKIN', 'ICEBERGS', 'PYRAMIDS', 'TROPICANA', 'SWAMP']
WRAP = 1024
BAND_A, BAND_B = 110, 70


def sprites():
    """sprite number -> (width in bytes, height, pixel bytes) from the game bank's bytes"""
    data = rf.load('sprites/game.bin')
    out = {}
    for n in range(data[0]):
        o = rf.word(data, 4 + 2 * n)
        w, h = data[o], data[o + 1]
        out[n] = (w, h, data[o + 4:o + 4 + w * h])
    return out


def menu_sprites():
    """menu picture number -> (width in bytes, height, pixel bytes) from the menu bank's bytes (MenuGfx: a pair of
    offsets a picture from +4, the sprite's first)"""
    data = rf.load('sprites/menu.bin')
    out = {}
    for n in range(data[0]):
        o = rf.word(data, 4 + 4 * n)
        w, h = data[o], data[o + 1]
        out[n] = (w, h, data[o + 4:o + 4 + w * h])
    return out


def bank(sp, menu, s, fl):
    """The picture an item draws: the menu bank's when its flags' bit 0 is set (PlaceItem `$8E61`)"""
    return (menu if fl & 1 else sp).get(s)


def trails():
    """trail number -> (length, list A items, list B items); an item is (distance, y, sprite, flags, anim)"""
    anims, recs = {}, {}
    for name in rf.TRAILS:
        blocks, _lists = rf.trail_parse(name, rf.load(name))
        byaddr = {}
        for b in blocks:
            if b[0] == 'anim':
                anims[b[1]] = b[2]
            elif b[0] == 'list':
                byaddr[b[1]] = b[2]
        for b in blocks:
            if b[0] == 'record':
                recs[int(b[1][5:])] = (b[4], byaddr[b[2]], byaddr[b[3]])

    def items(lst):
        r = []
        for it in lst:
            a = rf.word(it, 4) if it[5] & 0xF0 else None
            spr, fl = (anims[a][0], anims[a][1]) if a in anims else (it[4], it[5])
            r.append((rf.word(it, 0), it[2], spr, fl, a))
        return r
    return {t: (ln, items(la), items(lb)) for t, (ln, la, lb) in recs.items()}


def blit(px, size, spr, x0, ybase, y, mirror, colour):
    w, h, bs = spr
    top = ybase - (y if y else h)
    for j in range(h):
        for i in range(w * 8):
            if bs[j * w + i // 8] >> (7 - i % 8) & 1:
                xx, yy = x0 + (w * 8 - 1 - i if mirror else i), top + j
                if 0 <= xx < size[0] and 0 <= yy < size[1]:
                    px[xx, yy] = colour


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    which = [int(a) for a in sys.argv[2:]] or list(range(1, 7))
    sp, menu, tr = sprites(), menu_sprites(), trails()
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 12)
    except OSError:
        font = ImageFont.load_default()
    rows = [(t, r) for t in which for r in range((tr[t][0] + WRAP - 1) // WRAP)]
    strip = BAND_A + BAND_B + 30
    im = Image.new('RGB', (WRAP + 140, 10 + strip * len(rows)), (24, 24, 32))
    dr, px = ImageDraw.Draw(im), im.load()
    for k, (t, r) in enumerate(rows):
        ln, la, lb = tr[t]
        y0, x0 = 10 + k * strip, 130 - r * WRAP
        ga, gb = y0 + BAND_A, y0 + BAND_A + BAND_B
        label = '%d %s' % (t, NAMES[t - 1]) if r == 0 else '%d from %d' % (t, r * WRAP)
        dr.text((6, y0 + 4), label, fill=(230, 220, 120), font=font)
        if r == 0:
            dr.text((6, y0 + 20), 'length $%04X' % ln, fill=(200, 200, 200), font=font)
            dr.text((6, y0 + 36), 'A %d, B %d items' % (len(la), len(lb)), fill=(200, 200, 200), font=font)
        dr.text((6, ga - 14), 'list A', fill=(150, 190, 250), font=font)
        dr.text((6, gb - 14), 'list B', fill=(110, 200, 120), font=font)
        end = min(ln, (r + 1) * WRAP)
        for g in (ga, gb):
            dr.line([x0 + r * WRAP, g, x0 + end, g], fill=(90, 90, 110))
        fin = ln - 0x48
        if r * WRAP <= fin < (r + 1) * WRAP:
            dr.line([x0 + fin, y0 + 2, x0 + fin, gb], fill=(220, 80, 80))
        for lst, base, colour in ((lb, gb, (110, 200, 120)), (la, ga, (150, 190, 250))):
            for d, y, s, fl, a in lst:
                if not r * WRAP - 64 <= d < (r + 1) * WRAP:
                    continue
                pic = bank(sp, menu, s, fl)
                if pic:
                    blit(px, im.size, pic, x0 + d, base, y, False, colour)
                if a is not None:
                    dr.rectangle([x0 + d, base + 2, x0 + d + 3, base + 5], fill=(230, 200, 60))
    im.save(sys.argv[1])
    print('%s: %d x %d, trails %s' % (sys.argv[1], im.size[0], im.size[1], ' '.join(map(str, which))))
    return 0


if __name__ == '__main__':
    sys.exit(main())
