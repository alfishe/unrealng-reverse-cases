#!/usr/bin/env python3
"""The rooms of Switchblade drawn from the resources (src/res) and the 48K ROM: no game image, no emulator.

Each room is built as the game builds it and drawn as the game draws it (tools/swroom.py, the stage-2 port of
BuildRoomPlanes $9F34 and RedrawCell $8867), every zone revealed, the pickups in place, no actors. The memory the builder
reads is filled from src/res alone:

    rooms/rooms.txt $A928 (and the pointers the room table $7100 computed from its record order), rooms/map.txt $7048,
    rooms/outline-starts.csv $7300, outlines-1.txt $7310, outlines-2.txt $732E, strings.txt $7345,
    decor-tiles.txt $73BD, ledge-tiles.txt $73C5, solid-tiles.csv $7292, bars-1.csv $7400, horizon.txt $74F6,
    bars-2.csv $7511, default-zone.txt $75FB, pickup-tiles.csv $7BD8, graphics/tiles.png $D104,
    tables/cell-colours.csv at $66F7 (where BuildPageTails puts it at run time).

graphics/enemies.png $E154 and giants.png $E5BC are loaded too: tile n is drawn from $D104 + 24 (n - 1), and the
tile $FF that room 122's open-air rows leave in plane $68 (cells 80 and 81) reads past the 174 tiles into the giants'
frames, as the game does.

The open-air rooms' noise (BuildSurface $A039) reads the 48K ROM from $0000 + 257 - room: the ROM is data/rom/48.rom of
the unreal-ng checkout (kitlib.unreal_root: --unreal, $UNREAL_NG, the submodule R/unreal-ng), md5
4c42a2f075212361c3117015b107ff68.

    python3 tools/fig_rooms.py [--out work/stage2/fig/rooms] [--rooms 12,13,47-50] [--map]
    python3 tools/fig_rooms.py --rooms 12 --compare           # against work/stage2/rec/poke-room012/

Writes roomNNN.png (the 256 x 192 screen, the room at (8, 8), scaled 2x) and, with --map, map.png: the 20 map rows,
each room at its map column (240 x 176 pixels a room, scaled 1/2), room numbers in the corners.

--compare: for each room with a recording work/stage2/rec/poke-roomNNN/ (screen.png and end.szx, the room entered
by a POKE of the map position), the room is drawn with the zones end.szx has revealed ($6DFF) and compared with
screen.png in the revealed cells, colour by colour (the Spectrum colour of each pixel, ink or paper by its
attribute). The differences are the actors' cells (Hiro, the enemies), which the figure does not draw.
"""
import argparse
import glob
import hashlib
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import res_formats as RF  # noqa: E402
import swroom as SW  # noqa: E402

ROM_MD5 = '4c42a2f075212361c3117015b107ff68'
PLACES = [('rooms/rooms.bin', RF.ROOMS_AT), ('rooms/map.bin', 0x7048), ('rooms/outline-starts.bin', 0x7300),
          ('rooms/outlines-1.bin', 0x7310), ('rooms/outlines-2.bin', 0x732E), ('rooms/strings.bin', 0x7345),
          ('rooms/decor-tiles.bin', 0x73BD), ('rooms/ledge-tiles.bin', 0x73C5), ('rooms/solid-tiles.bin', 0x7292),
          ('rooms/bars-1.bin', 0x7400), ('rooms/horizon.bin', 0x74F6), ('rooms/bars-2.bin', 0x7511),
          ('rooms/default-zone.bin', 0x75FB), ('rooms/pickup-tiles.bin', 0x7BD8), ('graphics/tiles.bin', 0xD104),
          ('graphics/enemies.bin', 0xE154), ('graphics/giants.bin', 0xE5BC), ('tables/cell-colours.bin', 0x66F7)]


def rom48(hint=None):
    import kitlib
    path = os.path.join(kitlib.unreal_root(hint), 'data', 'rom', '48.rom')
    data = open(path, 'rb').read()
    if hashlib.md5(data).hexdigest() != ROM_MD5:
        raise SystemExit('fig_rooms: %s is not the 48K ROM the noise needs (md5 %s)' % (path, ROM_MD5))
    return data


def memory():
    """A 64K memory holding the resources at their addresses, and the room table $7100 from the rooms' order"""
    mem = bytearray(0x10000)
    for name, at in PLACES:
        data = RF.load(name)
        mem[at:at + len(data)] = data
    rooms = RF.load('rooms/rooms.bin')
    p = k = 0
    while p < len(rooms):
        end, _lines = RF.room_record_end(rooms, p)
        for r in RF.room_numbers(k):
            a = RF.ROOMS_AT + p
            mem[0x7100 + 2 * r:0x7102 + 2 * r] = bytes([a & 255, a >> 8])
        p, k = end, k + 1
    return mem


def room_above(grid, room):
    row, col = grid[room]
    return next((r for r, (rr, cc) in grid.items() if rr == row - 1 and cc == col), 0)


def build(mem, rom, grid, room):
    b = SW.Builder(mem, rom)
    b.build(room, room_above(grid, room))
    return b


def screen(b, zones=0xFC):
    pic, attrs = SW.render(b.m, revealed=zones)
    return SW.to_screen(pic, attrs)


def colour(bm, at, x, y):
    """The Spectrum colour of a screen pixel: 0-7, +8 bright (black is 0 either way)"""
    a = at[y // 8][x // 8]
    c = a & 7 if bm[y][x] else (a >> 3) & 7
    return c + 8 if c and a & 0x40 else c


def png_colours(path):
    """The colours of a 2x screen PNG (512 x 384) by the nearest Spectrum colour"""
    img = Image.open(path).convert('RGB')
    sx, sy = img.size[0] // 256, img.size[1] // 192
    px = img.load()
    out = [[0] * 256 for _ in range(192)]
    for y in range(192):
        for x in range(256):
            r, g, b = px[x * sx, y * sy]
            hi = max(r, g, b)
            c = (1 if b > hi // 2 else 0) | (2 if r > hi // 2 else 0) | (4 if g > hi // 2 else 0) if hi > 0x40 else 0
            out[y][x] = c + 8 if c and hi > 0xE0 else c
    return out


def snapshot_ram(path):
    try:
        from skoolkit.snapshot import Snapshot
    except ImportError:
        sys.path += glob.glob(os.path.join(os.environ.get('SKOOLKIT_VENV', ''), 'lib', 'python3*', 'site-packages'))
        from skoolkit.snapshot import Snapshot
    s = Snapshot.get(path)
    r = bytes(s.ram(-1))
    if len(r) == 49152:
        return bytes(16384) + r
    page = lambda n: r[n * 16384:(n + 1) * 16384]  # noqa: E731
    return bytes(16384) + page(5) + page(2) + page(s.out7ffd & 7)


def compare(b, rec):
    ram = snapshot_ram(os.path.join(rec, 'end.szx'))
    zones = ram[0x6DFF]
    bm, at = screen(b, zones)
    shot = png_colours(os.path.join(rec, 'screen.png'))
    total = diff = 0
    cells = set()
    for cell in range(220):
        if not b.m[0x6700 + cell] & zones & 0xFC:
            continue
        r, c = divmod(cell, 20)
        for y in range(8 + 16 * r, 24 + 16 * r):
            for x in range(8 + 12 * c, 20 + 12 * c):
                total += 1
                if colour(bm, at, x, y) != shot[y][x]:
                    diff += 1
                    cells.add(cell)
    planes = [(page, cell) for page in range(0x67, 0x6D) for cell in range(220)
              if (b.m[page << 8 | cell] ^ ram[page << 8 | cell]) & (0xFD if page == 0x67 else 0xFF)]
    return ram[0x6BDD], zones, diff, total, sorted(cells), planes


def parse_rooms(text):
    out = []
    for part in text.split(','):
        a, _, b = part.partition('-')
        out += range(int(a), int(b or a) + 1)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(CASE, 'work', 'stage2', 'fig', 'rooms'))
    p.add_argument('--rooms', default='1-127')
    p.add_argument('--map', action='store_true', help='also map.png, every room at its map place')
    p.add_argument('--compare', action='store_true')
    p.add_argument('--unreal')
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    rom = rom48(a.unreal)
    mem = memory()
    grid = RF.map_grid(RF.load('rooms/map.bin'))
    rooms = parse_rooms(a.rooms)
    shots = {}
    for room in sorted(set(rooms) | (set(grid) if a.map else set())):
        b = build(mem, rom, grid, room)
        bm, at = screen(b)
        if room in rooms:
            SW.png(os.path.join(a.out, 'room%03d.png' % room), bm, at)
        shots[room] = (bm, at)
        if a.compare and room in rooms:
            rec = os.path.join(CASE, 'work', 'stage2', 'rec', 'poke-room%03d' % room)
            if os.path.exists(os.path.join(rec, 'end.szx')):
                in_room, zones, diff, total, cells, planes = compare(b, rec)
                print('room %3d vs %s (in room %d, zones $%02X): %d of %d pixels differ (%.2f %%), cells %s; '
                      'planes $67-$6C (cells 0-219, $67 bit 1 left out): %d bytes differ %s' % (
                          room, os.path.relpath(rec, CASE), in_room, zones, diff, total, 100.0 * diff / max(total, 1),
                          cells, len(planes), ' '.join('$%02X%02X' % pc for pc in planes[:8])))
    print('rooms: %d drawn in %s' % (len(rooms), os.path.relpath(a.out, CASE)))
    if a.map:
        w, h = 240, 176
        cols = max(c for _r, c in grid.values()) + 1
        img = Image.new('RGB', (cols * w // 2, 20 * h // 2), (40, 40, 40))
        draw = ImageDraw.Draw(img)
        for room, (row, col) in grid.items():
            bm, at = shots[room]
            tile = Image.new('RGB', (w, h))
            px = tile.load()
            for y in range(h):
                for x in range(w):
                    px[x, y] = SW.SPECTRUM[colour(bm, at, x + 8, y + 8)]
            img.paste(tile.resize((w // 2, h // 2), Image.LANCZOS), (col * w // 2, row * h // 2))
            draw.rectangle([col * w // 2, row * h // 2, (col + 1) * w // 2 - 1, (row + 1) * h // 2 - 1],
                           outline=(90, 90, 90))
            label = '%d' % room if room not in (122, 123) else '%d (122+123)' % room
            draw.text((col * w // 2 + 3, row * h // 2 + 2), label, fill=(255, 255, 0))
        path = os.path.join(a.out, 'map.png')
        img.save(path)
        print('map: %s, %d x %d' % (os.path.relpath(path, CASE), img.size[0], img.size[1]))


if __name__ == '__main__':
    main()
