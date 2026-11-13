#!/usr/bin/env python3
"""Stage 2's own resource formats (src/res/stage2/), loaded by tools/res_formats.py after res_stage.py.

    stage2/map.bin -> map.txt   the grid records, their room tables and the placement lists

Stage 2 keeps its three grid records together (`$953E`, `$9547`, `$9550`), then the three room tables (`$9559`,
`$955F`, `$9567`), then the placement lists, where stages 1 and 3 put each room table right after its record. The
generic `stageN/rooms.bin` (res_stage.rooms_out) reads only the interleaved order, so stage 2's block is
`map.bin`. map.txt has rooms.txt's lines (res_stage.py: `grid W H COLUMN ROW ROOMS MAP STEP`, `rooms` with one exit
byte a room, `placements` with `KIND X Y [done]`, `end`) in the bytes' order: the three `grid` lines, then the
three room tables (a comment line names the grid of each), then the lists. The bytes back come from
res_stage.rooms_in, which writes the lines in their order.
"""
import res_stage


def map_out(name, data):
    # the records: the first record's room table lies right after the last record
    first = data[4] | data[5] << 8
    n, at = 0, first
    while 9 * n + 9 <= len(data):
        rec = data[9 * n:9 * n + 9]
        if (rec[4] | rec[5] << 8) != at or rec[0] < 14 or rec[1] < 9:
            break
        at += res_stage.rooms_per_grid(rec[0], rec[1])
        n += 1
    if not n:
        raise ValueError('map: no run of grid records followed by their room tables')
    base = first - 9 * n
    lines = ['# %s: the map grids (records first), their room tables and the placement lists '
             '(tools/res_stage2.py)' % res_stage.stage_of(name),
             '# grid W H COLUMN ROW ROOMS MAP STEP: blocks wide and high, the start window (blocks), the room table,',
             '#   the grid\'s offset in the map, rooms a grid row; rooms: one exit byte a room (1 right, 2 left, 4 up,',
             '#   8 down), a grid row of rooms a line; placements: KIND X Y (cells over the grid), "done" = bit 7',
             'base $%04X' % base]
    recs = [data[9 * i:9 * i + 9] for i in range(n)]
    for gw, gh, col, row, lo, hi, mlo, mhi, step in recs:
        lines.append('grid %d %d %d %d $%04X %d %d' % (gw, gh, col, row, lo | hi << 8, mlo | mhi << 8, step))
    i = 9 * n
    for g, rec in enumerate(recs):
        rooms = res_stage.rooms_per_grid(rec[0], rec[1])
        step = max(rec[8], 1)
        lines.append('# grid %d: %d room%s' % (g, rooms, '' if rooms == 1 else 's'))
        for r in range(0, rooms, step):
            lines.append('rooms ' + ' '.join('%X' % v for v in data[i + r:i + min(r + step, rooms)]))
        i += rooms
    while i < len(data):
        lines.append('placements')
        while i < len(data) and data[i] != 0xFF:
            k, x, y = data[i:i + 3]
            lines.append('%d %d %d%s' % (k & 0x7F, x, y, ' done' if k & 0x80 else ''))
            i += 3
        if data[i:i + 3] != b'\xff\xff\xff':
            raise ValueError('map: a placement list ends in %s at +%d' % (data[i:i + 3].hex(), i))
        lines.append('end')
        i += 3
    return res_stage.text_file(lines)


def map_in(name, raw):
    return res_stage.rooms_in(name, raw)


def figure_rooms_txt(raw):
    """map.txt as rooms.txt in the interleaved order (each grid line, then its rooms), for tools/fig_rooms.py,
    which gives each `rooms` line to the grid line before it"""
    lines = res_stage.lines_of(raw)
    grids = [ln for ln in lines if ln.split()[0] == 'grid']
    rooms = [ln for ln in lines if ln.split()[0] == 'rooms']
    rest = [ln for ln in lines if ln.split()[0] not in ('grid', 'rooms', 'base')]
    out, k = [], 0
    for g in grids:
        t = g.split()
        n = res_stage.rooms_per_grid(int(t[1]), int(t[2]))
        out.append(g)
        got = 0
        while got < n:
            out.append(rooms[k])
            got += len(rooms[k].split()) - 1
            k += 1
    return res_stage.text_file(out + rest)


FORMATS = [
    (r'^stage2/map\.bin$', '.txt', map_out, map_in),
]
