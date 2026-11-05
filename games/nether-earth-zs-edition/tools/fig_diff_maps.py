#!/usr/bin/env python3
"""The maps of the three games cell by cell (docs/img/diff/maps-diff.png): Nether Earth's map, the '98's, NELEV_00
and NELEV_01 of the '99 disk against them, and the '99's built-in level.

    python3 tools/fig_diff_maps.py [--out PNG]

A map is BuildMap's 512 x 16 cells as tools/zs_level.py draws them (zs_level.cells: blocks 2 x 2, shapes from the
game's ShapeTable `$BF9C-$C08C`, which is the same in the three images). The lists are read where each image's
BuildMap points (the operands `$BC8A`, `$BC92`, `$BCA2`, `$BCAA`; for a NELEV file its tail at `$1F4`), so the '98's
level, whose lists do not lie end to end like a file's, is read as the game reads it. A compare panel paints the
cells two maps share grey and the cells that differ red (a cell only one map fills, or filled with another kind);
the warbases and factories keep their colours.

It prints, for each map: the cells filled, the cells the same as NE's and as the '98's map (over the cells either
fills), the bases, the warbases, the bases at the same place as NE's and the '98's, and a NELEV file's tail
(points, enemy warbases, general); then the records where NELEV_01 and the '98's lists differ.
"""
import argparse
import glob
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import zs_level as L  # noqa: E402
from fig_common import font  # noqa: E402

NE_BIN, NE_ORG = os.path.join(ROOT, '..', 'nether-earth', 'build', 'game.bin'), 0x5B00
Z98_BIN = os.path.join(ROOT, 'build', 'game98', 'game98-6780.bin')
Z99_BIN = os.path.join(ROOT, 'build', 'game99', 'game-6780.bin')
ORG = 0x6780
BG, FG, DIM = (21, 22, 27), (230, 230, 230), (150, 154, 166)
SAME, DIFF = (90, 92, 104), (235, 70, 60)
SCALE = 3


def image_lists(path, org):
    img = open(path, 'rb').read()
    rd = lambda a: img[a - org]  # noqa: E731
    ptrs = [rd(a) | rd(a + 1) << 8 for a in (0xBC8A, 0xBC92, 0xBCA2, 0xBCAA)]
    return lists_at(rd, ptrs), img


def lists_at(rd, ptrs):
    out = []
    for (kind, label, high), p in zip(L.SECTIONS, ptrs):
        end, recs = (0 if kind == 'scenery' else 0xFF), []
        while rd(p) != end:
            recs.append((rd(p), rd(p + 1) | high << 8, rd(p + 2)))
            p += 3
        out.append((kind, label, high, recs, 0))
    return out


def grid(ls, shapes):
    saved = L.lists
    L.lists = lambda data: (ls, 0)
    try:
        return L.cells(None, shapes)
    finally:
        L.lists = saved


def bases(ls):
    return [r for kind, _, _, recs, _ in ls if kind == 'bases' for r in recs]


def draw(g, other=None):
    """a map 512 x 16 as four strips of 128 columns; against OTHER: the same cells grey, the differing red"""
    img = Image.new('RGB', (128 * SCALE, (16 * 4 + 3) * SCALE), (0, 0, 0))
    d = ImageDraw.Draw(img)
    for (x, y), kind in list(g.items()) + ([(c, None) for c in other if c not in g] if other else []):
        if other is None or kind in ('player', 'enemy', 'factory') and other.get((x, y)) == kind:
            colour = L.COLOURS[kind]
        elif other.get((x, y)) == kind:
            colour = SAME
        else:
            colour = DIFF
        strip, cx = divmod(x, 128)
        top = (strip * 17 + y) * SCALE
        d.rectangle((cx * SCALE, top, cx * SCALE + SCALE - 1, top + SCALE - 1), fill=colour)
    return img


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img', 'diff', 'maps-diff.png'))
    a = p.parse_args()
    ne_ls, ne = image_lists(NE_BIN, NE_ORG)
    shapes = {x: ne[x - NE_ORG] for x in range(0xBF9C, 0xC08D)}
    for path, org in ((Z98_BIN, ORG), (Z99_BIN, ORG)):
        img = open(path, 'rb').read()
        assert all(img[x - org] == v for x, v in shapes.items()), 'the shape table differs'
    lev = {'NE': ne_ls, "'98": image_lists(Z98_BIN, ORG)[0], "'99 built-in": image_lists(Z99_BIN, ORG)[0]}
    tails = {}
    for f in sorted(glob.glob(os.path.join(ROOT, 'build', 'maps', 'NELEV_*.N'))):
        data = open(f, 'rb').read()
        rd = lambda x, data=data: data[x - L.ORG]  # noqa: E731
        name = os.path.basename(f)[:-2]
        lev[name] = lists_at(rd, [data[0x1F4 + 2 * i] | data[0x1F5 + 2 * i] << 8 for i in range(4)])
        tails[name] = dict(points=data[0x1F3], enemy=data[0x1FE], general=data[0x1FF])
    G = {k: grid(v, shapes) for k, v in lev.items()}
    nb, b98 = set(bases(lev['NE'])), set(bases(lev["'98"]))

    def same(k, o):
        keys = set(G[k]) | set(G[o])
        return sum(1 for c in keys if G[k].get(c) == G[o].get(c)), len(keys)

    for k in G:
        b = bases(lev[k])
        s1, s2 = same(k, 'NE'), same(k, "'98")
        t = tails.get(k)
        print(f"{k:13s} cells {len(G[k]):5d}  same as NE {s1[0]:5d}/{s1[1]:5d}  as '98 {s2[0]:5d}/{s2[1]:5d}  "
              f"bases {len(b):2d} warbases {sum(1 for x in b if x[0] == 0):2d}  at NE's {len(set(b) & nb):2d}  "
              f"at '98's {len(set(b) & b98):2d}" + (f"  tail points {t['points']} enemy {t['enemy']} general "
                                                  f"{t['general']}" if t else ''))
    print("NELEV_01 against the '98's lists, record by record:")
    for (kind, label, _, r1, _), (_, _, _, r2, _) in zip(lev['NELEV_01'], lev["'98"]):
        s1, s2 = set(r1), set(r2)
        for r in sorted(s1 - s2):
            print(f'  {label}: only NELEV_01 {r}')
        for r in sorted(s2 - s1):
            print(f"  {label}: only the '98 {r}")
    diff01 = sorted(c for c in set(G['NELEV_01']) | set(G["'98"]) if G['NELEV_01'].get(c) != G["'98"].get(c))
    print('  the cells:', diff01)

    panels = [("Nether Earth's map", draw(G['NE'])),
              ("ZS'98's map", draw(G["'98"])),
              (f"'98 against NE: {same(chr(39) + '98', 'NE')[0]} of {same(chr(39) + '98', 'NE')[1]} cells the same, "
               '0 bases in place', draw(G["'98"], G['NE'])),
              (f"'99 NELEV_00 against NE: all {len(G['NE'])} cells and 28 bases the same", draw(G['NELEV_00'], G['NE'])),
              (f"'99 NELEV_01 against the '98: {len(diff01)} cells differ", draw(G['NELEV_01'], G["'98"])),
              (f"'99 built-in level: {len(G[chr(39) + '99 built-in'])} cells, 2 warbases", draw(G["'99 built-in"]))]
    w, h = panels[0][1].size
    pad, title_h = 16, 22
    sheet = Image.new('RGB', (pad + 2 * (w + pad), 40 + 3 * (h + title_h + pad) + 34), BG)
    d = ImageDraw.Draw(sheet)
    f, small = font(13), font(11)
    d.text((pad, 10), 'The maps cell by cell: four strips of 128 columns a map (the radar\'s width)', fill=FG, font=f)
    for i, (title, img) in enumerate(panels):
        col, row = i % 2, i // 2
        x, y = pad + col * (w + pad), 40 + row * (h + title_h + pad)
        d.text((x, y), title, fill=FG, font=small)
        sheet.paste(img, (x, y + title_h))
    y, x = sheet.height - 26, pad
    for label, colour in [('our warbase', L.COLOURS['player']), ('enemy warbase', L.COLOURS['enemy']),
                          ('factory', L.COLOURS['factory']), ('scenery', L.COLOURS['low']),
                          ('compare: the same', SAME), ('compare: differs', DIFF)]:
        d.rectangle((x, y + 2, x + 10, y + 12), fill=colour)
        d.text((x + 15, y), label, fill=DIM, font=small)
        x += 30 + int(d.textlength(label, font=small))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    sheet.save(a.out)
    print('wrote', a.out)


if __name__ == '__main__':
    main()
