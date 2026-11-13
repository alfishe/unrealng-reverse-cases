#!/usr/bin/env python3
"""Draw a stage's map and every room from its resources (src/res/stageN/, never from the image):

    python3 tools/fig_rooms.py stage1            # -> docs/img/maps/stage1.png and docs/img/maps/stage1-rooms.png

Reads graphics.txt + tiles.png (the tiles, the blocks, the map grids), rooms.txt (the grid records, the room tables,
the placement lists), table-kinds.csv (each kind's Y offset and handler) and the sprite sets sprites-*.png. A
placement is drawn with the first frame of its kind's sprite set when KIND_SPRITES knows it for the stage (the
handler's SetActorFrame call gives the set, docs/07), else as a box with the kind number.

- the map: each grid with its blocks, the room windows (14 x 9 blocks, a step of 11 columns and 6 rows; the start
  window in yellow) and the placements (a dot and the kind number);
- the rooms: every window of every grid as the game builds it (RoomCells $9928: the window's blocks at 2 x 2 cells),
  with the placements that LoadRoomActors $A4CC puts in it, numbered as RoomNumber counts them (a grid row of rooms
  after another).
"""
import argparse
import csv
import io
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import res_stage  # noqa: E402

# kind -> (sprite set file under src/res/stageN/, frame) for each stage, from the handlers' SetActorFrame calls
KIND_SPRITES = {
    'stage1': {0: ('bitmaps-hanging-2x37.png', 0), 1: ('bitmaps-hanging-2x37.png', 0),
               2: ('sprites-flame-jet.png', 6), 3: ('sprites-strikeable.png', 6), 4: ('sprites-strikeable.png', 4),
               5: ('sprites-strikeable.png', 2), 6: ('sprites-strikeable.png', 0), 7: ('sprites-fire-pit.png', 0),
               8: ('bitmaps-boss-wing-3x33.png', 0), 9: ('bitmaps-boss-wing-3x33.png', 0),
               10: ('bitmaps-boss-body-6x32.png', 1), 11: ('bitmaps-boss-head-2x20.png', 0),
               12: ('sprites-statue.png', 0), 13: ('sprites-gate.png', 0), 14: ('sprites-statue.png', 0),
               15: ('sprites-arena-head.png', 0), 16: ('bitmaps-bridge-slab-4x8.png', 0)},
    'stage2': {0: ('sprites-statue.png', 3), 1: ('sprites-statue.png', 0), 2: ('sprites-harpy-lamp.png', 0),
               3: ('sprites-harpy-rise.png', 1), 4: ('sprites-pool.png', 0), 5: ('sprites-pool.png', 0),
               6: ('sprites-drop.png', 0), 7: ('bitmaps-hydra-head-3x22.png', 0),
               8: ('bitmaps-hydra-head-3x22.png', 0), 9: ('bitmaps-hydra-head-3x22.png', 0),
               10: ('bitmaps-hydra-head-3x22.png', 0), 11: ('sprites-medusa.png', 0), 12: ('sprites-medusa.png', 2),
               13: ('sprites-harpy-lamp.png', 5), 14: ('sprites-statue.png', 1), 15: ('sprites-statue.png', 2),
               16: ('sprites-strikeable.png', 6), 17: ('sprites-strikeable.png', 4),
               18: ('sprites-strikeable.png', 2), 19: ('sprites-strikeable.png', 0), 20: ('bitmaps-ripple-4x2.png', 0)},
    'stage3': {0: ('sprites-strikeable.png', 6), 1: ('sprites-strikeable.png', 4), 2: ('sprites-strikeable.png', 2),
               3: ('sprites-strikeable.png', 0), 4: ('bitmaps-water-4x4.png', 0),
               5: ('bitmaps-dragon-head-4x27.png', 0), 6: ('sprites-breath.png', 0), 7: ('sprites-drawbridge.png', 0),
               8: ('sprites-pyre-flame.png', 0), 9: ('sprites-pyre-flame.png', 0), 10: ('sprites-bier.png', 0),
               11: ('sprites-bier.png', 1), 12: ('bitmaps-lightning-4-3x104.png', 0)},
    'stage4': {0: ('sprites-objects.png', 5), 1: ('sprites-objects.png', 3), 2: ('sprites-objects.png', 1),
               3: ('sprites-objects.png', 0), 4: ('bitmaps-water-4x2.png', 0), 5: ('sprites-traps.png', 0),
               6: ('sprites-pendulum.png', 0), 7: ('sprites-traps.png', 17), 8: ('sprites-traps.png', 0),
               9: ('sprites-traps.png', 9), 10: ('sprites-pendulum.png', 0), 12: ('sprites-brazier.png', 0),
               13: ('bitmaps-disc-2x16.png', 0), 14: ('sprites-ledge.png', 0), 15: ('sprites-ledge.png', 0),
               16: ('sprites-boss-mouth.png', 0), 17: ('sprites-objects.png', 8), 18: ('sprites-ledge.png', 0),
               20: ('sprites-barrier.png', 0), 21: ('sprites-barrier.png', 1)},
}


def font(size):
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf'):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default()


def load(stage, base=None):
    base = base or os.path.join(CASE, 'src', 'res')
    res_stage.RES = base
    res = os.path.join(base, stage)
    raw = open(os.path.join(res, 'graphics.txt'), 'rb').read()
    packed = res_stage.graphics_in(stage + '/graphics.bin', raw)
    d, _, _ = res_stage.unrle(packed)
    _, kinds, pix, att, blk, mp = res_stage.unpack_sections(d)
    # rooms.txt (res_stage), rooms-split.txt (res_stage4's split layout, the same language) or map.txt (res_stage2,
    # the records first; its figure_rooms_txt gives it in rooms.txt's order)
    rooms_path = os.path.join(res, 'rooms.txt')
    if not os.path.exists(rooms_path):
        rooms_path = os.path.join(res, 'rooms-split.txt')
    if os.path.exists(rooms_path):
        rooms_txt = open(rooms_path, 'rb').read()
    else:
        import res_stage2
        rooms_txt = res_stage2.figure_rooms_txt(open(os.path.join(res, 'map.txt'), 'rb').read())
        if isinstance(rooms_txt, str):
            rooms_txt = rooms_txt.encode('utf-8')
    grids, lists, cur = [], [], None
    for ln in res_stage.lines_of(rooms_txt):
        t = ln.split()
        if t[0] == 'grid':
            gw, gh, col, row = (int(x) for x in t[1:5])
            grids.append({'w': gw, 'h': gh, 'col': col, 'row': row, 'map': int(t[6]), 'step': int(t[7]),
                          'exits': []})
        elif t[0] == 'rooms':
            grids[-1]['exits'] += [int(x, 16) for x in t[1:]]
        elif t[0] == 'placements':
            cur = []
        elif t[0] == 'end':
            lists.append(cur)
        elif cur is not None and t[0][0].isdigit():
            cur.append((int(t[0]), int(t[1]), int(t[2]), len(t) > 3))
    kinds_tab = {}
    kpath = os.path.join(res, 'table-kinds.csv')
    if os.path.exists(kpath):
        rows = [r for r in csv.reader(io.StringIO('\n'.join(res_stage.lines_of(open(kpath, 'rb').read()))))]
        for r in rows[1:]:
            kinds_tab[int(r[0])] = int(r[1])
    sprites = {}
    for k, (fname, frame) in KIND_SPRITES.get(stage, {}).items():
        p = os.path.join(res, fname)
        if os.path.exists(p):
            bms, meta = res_stage.png_to_frames(open(p, 'rb').read(), 'tx-frames')
            dxdy = meta['frames'][frame][:2] if 'frames' in meta else (0, 0)
            sprites[k] = (bms[frame], meta['sizes'][frame], dxdy)
    return pix, att, blk, mp, grids, lists, kinds_tab, sprites


PAL = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215), (0, 215, 0), (0, 215, 215), (215, 215, 0),
       (215, 215, 215)]
PALB = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0),
        (255, 255, 255)]


def tile_images(pix, att):
    out = []
    for t in range(len(att)):
        a = att[t]
        p = PALB if a & 64 else PAL
        im = Image.new('RGB', (8, 8))
        for y in range(8):
            for x in range(8):
                im.putpixel((x, y), p[a & 7] if (pix[8 * t + y] >> (7 - x)) & 1 else p[(a >> 3) & 7])
        out.append(im)
    return out


def block_images(tiles, blk):
    out = []
    for b in range(len(blk) // 4):
        im = Image.new('RGB', (16, 16))
        for k, (dx, dy) in enumerate(((0, 0), (8, 0), (0, 8), (8, 8))):
            im.paste(tiles[blk[4 * b + k]], (dx, dy))
        out.append(im)
    return out


def grid_image(g, blocks, mp):
    im = Image.new('RGB', (g['w'] * 16, g['h'] * 16))
    for j in range(g['h']):
        for i in range(g['w']):
            im.paste(blocks[mp[g['map'] + j * g['w'] + i]], (i * 16, j * 16))
    return im


def windows(g):
    cols = list(range(0, max(g['w'] - 14, 0) + 1, 11))
    rows = list(range(0, max(g['h'] - 9, 0) + 1, 6))
    return [(c, r) for r in rows for c in cols]


def draw_actor(dr, im, x, y, kind, kinds_tab, sprites, f):
    """an actor at cell X, line Y of the image"""
    ky = 0
    if kind in sprites:
        bm, (w, h), (dx, dy) = sprites[kind]
        for yy in range(h):
            for xx in range(w * 8):
                if (bm[yy * w + xx // 8] >> (7 - xx % 8)) & 1:
                    px, py = x * 8 + dx * 8 + xx, y + ky + dy + yy
                    if 0 <= px < im.width and 0 <= py < im.height:
                        im.putpixel((px, py), (255, 255, 255))
        return
    dr.rectangle([x * 8, y, x * 8 + 15, y + 15], outline=(255, 64, 255))
    dr.text((x * 8 + 2, y + 2), str(kind), font=f, fill=(255, 64, 255))


# the GridNumber ($FE47) of each grid record where the records are not in that order (build/stage4.lst, Grid0 $9AE2)
GRID_NUMBERS = {'stage4': [0, 9, 2, 1, 3, 4, 5, 8, 10]}


def grid_name(stage, n):
    """'grid G' by the code's GridNumber, with ' (record n)' where the records lie in another order"""
    if stage in GRID_NUMBERS:
        return f'grid {GRID_NUMBERS[stage][n]} (record {n})'
    return f'grid {n}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('stage')
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'maps'))
    ap.add_argument('--res', help='the resources folder (src/res)')
    a = ap.parse_args()
    pix, att, blk, mp, grids, lists, kinds_tab, sprites = load(a.stage, a.res)
    blocks = block_images(tile_images(pix, att), blk)
    f, fs = font(14), font(10)
    os.makedirs(a.out, exist_ok=True)

    # the map
    width = max(g['w'] for g in grids) * 16 + 20
    height = sum(g['h'] * 16 + 40 for g in grids) + 10
    im = Image.new('RGB', (width, height), (40, 40, 40))
    dr = ImageDraw.Draw(im)
    y0 = 10
    for n, g in enumerate(grids):
        dr.text((10, y0), f'{grid_name(a.stage, n)}: {g["w"]} x {g["h"]} blocks, {len(windows(g))} rooms; '
                f'{len(lists[n]) if n < len(lists) else 0} placements', font=f, fill=(255, 255, 255))
        y0 += 24
        im.paste(grid_image(g, blocks, mp), (10, y0))
        for c, r in windows(g):
            colour = (255, 255, 0) if (c, r) == (g['col'], g['row']) else (255, 255, 255)
            dr.rectangle([10 + c * 16, y0 + r * 16, 10 + (c + 14) * 16 - 1, y0 + (r + 9) * 16 - 1], outline=colour)
        for kind, x, y, done in (lists[n] if n < len(lists) else []):
            cx, cy = 10 + x * 8, y0 + y * 8
            dr.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(255, 64, 255))
            dr.text((cx + 4, cy - 6), str(kind), font=fs, fill=(255, 128, 255))
        y0 += g['h'] * 16 + 16
    path = os.path.join(a.out, a.stage + '.png')
    im.save(path)

    # the rooms
    rooms = [(n, g, c, r) for n, g in enumerate(grids) for c, r in windows(g)]
    cols = 4
    rw, rh = 14 * 16, 9 * 16
    sheet = Image.new('RGB', (cols * (rw + 10) + 10, ((len(rooms) + cols - 1) // cols) * (rh + 30) + 10),
                      (40, 40, 40))
    sd = ImageDraw.Draw(sheet)
    counter = {}
    for k, (n, g, c, r) in enumerate(rooms):
        room = grid_image(g, blocks, mp).crop((c * 16, r * 16, (c + 14) * 16, (r + 9) * 16))
        rd = ImageDraw.Draw(room)
        for kind, x, y, done in (lists[n] if n < len(lists) else []):
            if c * 2 <= x < c * 2 + 30 and r * 2 <= y < r * 2 + 18:
                ky = kinds_tab.get(kind, 0)
                draw_actor(rd, room, x - c * 2, (y - r * 2) * 8 + ky, kind, kinds_tab, sprites, fs)
        number = counter.setdefault(n, 0)
        counter[n] += 1
        exits = g['exits'][number] if number < len(g['exits']) else 0
        ex = ''.join(ch for bit, ch in ((1, 'R'), (2, 'L'), (4, 'U'), (8, 'D')) if exits & bit) or '-'
        x0, y0 = 10 + (k % cols) * (rw + 10), 10 + (k // cols) * (rh + 30)
        sd.text((x0, y0), f'{grid_name(a.stage, n)} room {number} (blocks {c},{r}) exits {ex}', font=fs, fill=(255, 255, 255))
        sheet.paste(room, (x0, y0 + 16))
    spath = os.path.join(a.out, a.stage + '-rooms.png')
    sheet.save(spath)
    print(f'fig_rooms: {os.path.relpath(path, CASE)} {im.size}, {os.path.relpath(spath, CASE)} {sheet.size}: '
          f'{len(grids)} grids, {len(rooms)} rooms, {sum(len(x) for x in lists)} placements, '
          f'{len(sprites)} kinds drawn as sprites')
    return 0


if __name__ == '__main__':
    sys.exit(main())
