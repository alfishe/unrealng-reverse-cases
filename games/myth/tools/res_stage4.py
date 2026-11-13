#!/usr/bin/env python3
"""Stage 4's own resource format (src/res/stage4/), loaded by tools/res_formats.py after tools/res_stage.py.

    NAME (under stage4/)        editable form       what
    rooms-split.bin             rooms-split.txt     the grid records, their room tables and the placement lists, in
                                                    the "split" layout: all the records first, then all the room
                                                    tables, then the placement lists

Stage 1 keeps each grid record followed by its room table (res_stage.rooms_out reads that); stage 4 keeps its nine
records together (`$9AE2-$9B32`), then the nine room tables (`$9B33-$9B4F`), then the nine placement lists
(`$9B50-$9DAA`). The text is rooms.txt's language (res_stage.rooms_out): a `layout split` line, then each `grid W H
COLUMN ROW ROOMS MAP STEP` line followed by its `rooms` line(s), then the `placements` sections, so a reader of
rooms.txt (tools/fig_rooms.py) reads it unchanged. The bytes are written back records first, tables second: each
grid's table must lie at the address its record gives, one after another (checked).
"""
import res_stage as R


def rooms_split_out(name, data):
    lines = ['# %s: the map grids, their room tables and the placement lists (tools/res_stage4.py, the split layout:'
             % R.stage_of(name),
             '#   the records, then the room tables, then the placement lists)',
             '# grid W H COLUMN ROW ROOMS MAP STEP: blocks wide and high, the start window (blocks), the room table,',
             '#   the grid\'s offset in the map, rooms a grid row; rooms: one exit byte a room (1 right, 2 left, 4 up,',
             '#   8 down), a grid row of rooms a line; placements: KIND X Y (cells over the grid), "done" = bit 7']
    recs = []
    i = 0
    while i + 9 <= len(data):
        r = data[i:i + 9]
        tab = r[4] | r[5] << 8
        if r[0] < 14 or r[1] < 9:
            break
        if recs:
            prev, ptab = recs[-1]
            if tab != ptab + R.rooms_per_grid(prev[0], prev[1]):
                break
        recs.append((r, tab))
        i += 9
    if not recs:
        raise ValueError('rooms-split: no grid record')
    base = recs[0][1] - i
    lines.append('layout split')
    lines.append('base $%04X' % base)
    k = i
    for r, tab in recs:
        gw, gh, col, row = r[:4]
        mo = r[6] | r[7] << 8
        step = r[8]
        n = R.rooms_per_grid(gw, gh)
        if tab != base + k:
            raise ValueError('rooms-split: grid %d\'s room table $%04X is not at $%04X' % (len(lines), tab, base + k))
        lines.append('grid %d %d %d %d $%04X %d %d' % (gw, gh, col, row, tab, mo, step))
        t = data[k:k + n]
        for x in range(0, n, max(step, 1)):
            lines.append('rooms ' + ' '.join('%X' % v for v in t[x:x + max(step, 1)]))
        k += n
    while k < len(data):
        lines.append('placements')
        while k < len(data) and data[k] != 0xFF:
            kd, x, y = data[k:k + 3]
            lines.append('%d %d %d%s' % (kd & 0x7F, x, y, ' done' if kd & 0x80 else ''))
            k += 3
        if data[k:k + 3] != b'\xff\xff\xff':
            raise ValueError('rooms-split: a placement list ends in %s at +%d' % (data[k:k + 3].hex(), k))
        lines.append('end')
        k += 3
    return R.text_file(lines)


def rooms_split_in(name, raw):
    recs, tabs, places = bytearray(), bytearray(), bytearray()
    for ln in R.lines_of(raw):
        t = ln.split()
        if t[0] in ('base', 'placements', 'layout'):
            continue
        if t[0] == 'grid':
            gw, gh, col, row = (int(x) for x in t[1:5])
            rooms, mo, step = R.num(t[5]), int(t[6]), int(t[7])
            recs += bytes([gw, gh, col, row, rooms & 255, rooms >> 8, mo & 255, mo >> 8, step])
        elif t[0] == 'rooms':
            tabs += bytes(int(x, 16) for x in t[1:])
        elif t[0] == 'end':
            places += b'\xff\xff\xff'
        else:
            places += bytes([int(t[0]) | (0x80 if len(t) > 3 and t[3] == 'done' else 0), int(t[1]), int(t[2])])
    return bytes(recs + tabs + places)


FORMATS = [
    (r'^stage4/rooms-split\.bin$', '.txt', rooms_split_out, rooms_split_in),
]
