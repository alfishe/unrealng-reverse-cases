#!/usr/bin/env python3
"""The map of a new game in both games, for the resources part of docs/13 (work/diff/resources.md).

Each game's own BuildMap ($BC6F) runs on SkoolKit's Simulator over its own image (tools/diff_res.py buildmap: the
memories go to work/diff/buildmap/ne.bin and ane.bin); the maps $DD00-$FCFF are compared cell by cell, and NE's
map renderer (games/nether-earth/tools/ill_render.py map_strip) draws them. A changed cell would get a red frame;
when none differs the map is drawn once.

    python3 tools/fig_diff_res_map.py [--out docs/img/diff/res-map.png]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
R = os.path.abspath(os.path.join(CASE, '..', '..'))
NE_TOOLS = os.path.join(R, 'games', 'nether-earth', 'tools')
sys.path.insert(0, os.path.join(R, 'kit'))
sys.path.insert(0, HERE)
sys.path.insert(0, NE_TOOLS)
import kitlib as K  # noqa: E402
import diff_res as D  # noqa: E402
import ill_render as NR  # noqa: E402  (NE's map renderer)

CHANGED = (255, 60, 60)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'diff', 'res-map.png'))
    p.add_argument('--map-dir', default=os.path.join(CASE, 'work', 'diff', 'buildmap'))
    args = p.parse_args()
    mems = D.map_memories(args.map_dir)
    if mems is None:
        sys.exit('no SkoolKit: set SKOOLKIT_PYTHON')
    ne, ane = mems
    diff = [(i % 0x200, i // 0x200) for i in range(D.MAP_END - D.MAP) if ne[D.MAP + i] != ane[D.MAP + i]]
    bases = sum(ne[i] != ane[i] for i in range(D.BASES, D.BASES_END))
    cs, n = 7, 128
    L = 46
    W = L + n * cs + 20
    strip_h = 16 * cs + 34
    panels = [('', ne)] if not diff else [('NE', ne), ('ANE', ane)]
    H = 92 + len(panels) * 4 * strip_h + 110
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    f, small, tiny = K.font(16), K.font(12), K.font(11)
    if diff:
        d.text((L, 10), 'The new-game map differs in %d of 8192 cells (red frames)' % len(diff), fill=K.TEXT, font=f)
    else:
        d.text((L, 10), 'The new-game map is the same in both games: 0 of 8192 cells differ, drawn once', fill=K.TEXT,
               font=f)
    d.text((L, 34), 'each game\'s own BuildMap $BC6F run over its own image (SkoolKit Simulator); the map $DD00, '
           '16 rows x 512 columns,', fill=K.DIM, font=small)
    d.text((L, 50), 'in four strips of 128 columns, %d pixels a cell; the 28 base records $FD70 differ in %d bytes'
           % (cs, bases), fill=K.DIM, font=small)
    y = 76
    for name, mem in panels:
        if name:
            d.text((L, y), name, fill=K.TEXT, font=small)
            y += 16
        for k in range(4):
            x0 = k * n
            out.paste(NR.map_strip(mem, x0, n, cs, robots=False, ship=False), (L, y))
            for (x, yy) in diff:
                if x0 <= x < x0 + n:
                    d.rectangle([L + (x - x0) * cs - 1, y + yy * cs - 1, L + (x - x0 + 1) * cs, y + (yy + 1) * cs],
                                outline=CHANGED, width=2)
            for c in range(0, n + 1, 16):
                d.line([L + c * cs, y + 16 * cs, L + c * cs, y + 16 * cs + 4], fill=K.DIM)
                if c < n:
                    d.text((L + c * cs + 2, y + 16 * cs + 3), str(x0 + c), fill=K.DIM, font=tiny)
            for r in (0, 8, 15):
                d.text((L - 22, y + r * cs - 4), str(r), fill=K.DIM, font=tiny)
            y += strip_h
    NR.legend(d, L, y, NR.TERRAIN_LEGEND[:4], tiny, 12)
    NR.legend(d, L, y + 18, NR.TERRAIN_LEGEND[4:], tiny, 12)
    NR.legend(d, L, y + 36, [(NR.NEUTRAL, 'capture point, neutral'), (NR.OURS, 'ours'), (NR.THEIRS, 'the enemy\'s'),
                             ((250, 210, 80), 'factory roof'), (NR.OURS, 'our pad / flag'),
                             (NR.THEIRS, 'enemy flag')], tiny, 12)
    d.text((L, y + 56), 'squares: the capture points (B warbase, E electronics, N nuclear, P phasers, M missiles, '
           'C cannon, W chassis); dark outlines: 2 x 2 blocks', fill=K.DIM, font=tiny)
    d.text((L, H - 22), 'python3 tools/fig_diff_res_map.py  (NE\'s renderer: nether-earth/tools/ill_render.py '
           'map_strip)', fill=K.DIM, font=tiny)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    out.save(args.out)
    print(args.out, out.size, '%d cells differ' % len(diff))


if __name__ == '__main__':
    main()
