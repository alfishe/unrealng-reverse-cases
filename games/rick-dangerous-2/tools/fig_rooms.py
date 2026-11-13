#!/usr/bin/env python3
"""Every section of every level drawn from the resources (src/res/levels/levelN/level/), and each level's map.

    python3 tools/fig_rooms.py OUT [--levels 1,2,3,4,5] [--scale 2]

OUT/levelN-sS.png: section S as the screen can show it, the block rows 2 to limit / 4 + 7 of its map (maps.txt,
sections.txt), drawn with the level's blocks (blocks.txt) and cells (cells.png), 256 pixels wide. Marked on it: the
map entries (sections.txt "object": traps and pickups yellow, enemies red, the bonus countdown cyan; a dashed box for
each trigger box) and the exits (green at the left or right edge on Rick's feet row; magenta when the exit ends the
level). OUT/levelN.png: the level's sections side by side, each with its exits written under it ("R30>2": the right
edge, feet row 30, to section 2). The section count comes from SectionCounts ($8374, src/res/tables).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import res_formats as rf  # noqa: E402

ROOT = rf.ROOT


def level_bytes(n):
    """{level/NAME.bin: bytes} of level n from its editable files"""
    out = {}
    folder = os.path.join(rf.RES, 'levels', 'level%d' % n)
    for src, fold, rel, kind in rf.sources():
        if fold == os.path.join('levels', 'level%d' % n):
            out.update(rf.to_bytes(rel, kind, open(src, 'rb').read()))
    if not out:
        raise SystemExit('fig_rooms: no resources in %s' % folder)
    return out


def section_counts():
    raw = open(os.path.join(rf.RES, 'tables', 'section-counts.csv'), 'rb').read()
    return list(rf.csv_section_counts(raw))


def rgb(attr, ink):
    c = (attr & 7) if ink else (attr >> 3 & 7)
    return tuple(rf.spectrum_rgb(c, attr & 0x40))


def parse_lists(sec, off):
    """(exits, objects) of the lists at the offsets of a section's entry"""
    e, p = [], off[0]
    while p + 4 <= len(sec) and sec[p] & 0x0B:
        e.append(tuple(sec[p:p + 4]))
        p += 4
    o, p = [], off[1]
    while p + 4 <= len(sec) and sec[p]:
        rec = tuple(sec[p:p + 4])
        boxes = [tuple(sec[p + 4 + 4 * k:p + 8 + 4 * k]) for k in range(rec[3] & 3)]
        o.append((rec, boxes))
        p += 4 + 4 * (rec[3] & 3)
    return e, o


def draw_section(b, s):
    maps, sec, blocks = b['level/maps.bin'], b['level/sections.bin'], b['level/blocks.bin']
    gfx, attrs = b['level/cell-graphics.bin'], b['level/cell-attrs.bin']
    ent = sec[8 * s:8 * s + 8]
    moff, limit = ent[0] << 8 | ent[1], ent[3]
    first, last = 2, limit // 4 + 7
    img = Image.new('RGB', (256, (last - first + 1) * 32), (0, 0, 0))
    px = img.load()
    for r in range(first, last + 1):
        for c in range(8):
            a = moff + 8 * r + c
            blk = maps[a] if a < len(maps) else 0
            for cy in range(4):
                for cx in range(4):
                    cell = blocks[16 * blk + 4 * cy + cx]
                    at = attrs[cell]
                    for y in range(8):
                        row = gfx[8 * cell + y]
                        for x in range(8):
                            px[c * 32 + cx * 8 + x, (r - first) * 32 + cy * 8 + y] = rgb(at, row >> (7 - x) & 1)
    exits, objects = parse_lists(sec, (ent[4] << 8 | ent[5], ent[6] << 8 | ent[7]))
    d = ImageDraw.Draw(img)
    top = first * 32  # pixels of the map above the drawing
    for rec, boxes in objects:
        k, row, col, par = rec
        x = (col & 31) * 8 + (4 if col & 0x20 else 0)
        y = row * 8 + (3 if col & 0x40 else 0) - top
        colour = (255, 0, 0) if k >= 0x74 and k not in (0x78, 0x7C) else (0, 255, 255) if k in (0x78, 0x7C) else (255, 255, 0)
        d.rectangle([x, y, x + 15, y + 15], outline=colour)
        d.text((x + 2, y + 2), '%d' % (k & 0x7F), fill=colour)
        for bx in boxes:
            x0, y0 = bx[0], bx[1] * 8 - top
            w, h = ((bx[2] & 15) + 1) * 8, ((bx[2] >> 4) + 1) * 8
            for t in range(0, w, 4):
                d.point([(x0 + t, y0), (x0 + t, y0 + h - 1)], fill=colour)
            for t in range(0, h, 4):
                d.point([(x0, y0 + t), (x0 + w - 1, y0 + t)], fill=colour)
    for f, row, to, arrive in exits:
        y = row * 8 - top
        colour = (255, 0, 255) if f & 0x80 else (0, 255, 0)
        x0 = 0 if f & 1 else 250
        d.rectangle([x0, y - 20, x0 + 5, y], fill=colour)
    return img, exits


def exit_label(e):
    f, row, to, arrive = e
    side = 'L' if f & 1 else 'R'
    return '%s%d>%s' % (side, row, 'END' if f & 0x80 and f & 0x10 else ('END/%d' % to if f & 0x80 else str(to)))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('out')
    p.add_argument('--levels', default='1,2,3,4,5')
    p.add_argument('--scale', type=int, default=1)
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    counts = section_counts()
    for n in [int(x) for x in a.levels.split(',')]:
        b = level_bytes(n)
        shots = []
        for s in range(counts[n - 1]):
            img, exits = draw_section(b, s)
            if a.scale > 1:
                img = img.resize((img.width * a.scale, img.height * a.scale), Image.NEAREST)
            img.save(os.path.join(a.out, 'level%d-s%d.png' % (n, s)))
            shots.append((s, img, exits))
        w = sum(i.width + 8 for _s, i, _e in shots) + 8
        h = max(i.height for _s, i, _e in shots) + 40
        sheet = Image.new('RGB', (w, h), (40, 40, 40))
        d = ImageDraw.Draw(sheet)
        x = 8
        for s, img, exits in shots:
            d.text((x, 4), 'level %d section %d' % (n, s), fill=(255, 255, 255))
            sheet.paste(img, (x, 18))
            d.text((x, 20 + img.height), ' '.join(exit_label(e) for e in exits), fill=(200, 255, 200))
            x += img.width + 8
        sheet.save(os.path.join(a.out, 'level%d.png' % n))
        print('level %d: %d sections' % (n, len(shots)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
