#!/usr/bin/env python3
"""Doc 06's figures: the screen with the room's open spans beside the memory the renderer uses, and the room change's
phases.

    python3 tools/fig_render.py spans WORK FRAME docs/img/render/spans.png
    python3 tools/fig_render.py phases docs/img/render/roomchange-phases.png

spans: WORK is a re_session work folder whose instance holds the recording (c1); at FRAME the screen `$4000-$5AFF`,
SpanCount `$FE1C` and the span table `$76A0` are read with TTD memory_at. Each span (6 bytes: the length in cells,
0, the play buffer's address, the screen's address) is outlined on the screen; the HUD rows 0-5 and the play area's
28 x 18 cells are marked. Right: the memory map of stage 1's drawing (from src/stage1/stage1.asm and variables.asm).
phases: the c1 room change 8 to 7 (frames 16531:33882-16549:64359), its T-states per phase, measured from the trace
(work/docs/myA/rc-spans.tsv and the routine entries; doc 06 6.3 gives the method).
"""
import os
import sys

from figmyth import F, TEXT, DIM, HI, PANEL, COLOURS, canvas, save, kitlib

sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
import zxscreen  # noqa: E402  (kit)

MEMORY = [
    (0x4000, 0x57FF, 'the screen bitmap', 'HUD drawn once; play area: RoomChange, CopyBuffer'),
    (0x5800, 0x5AFF, 'the attributes', 'UpdateAttributes writes the open cells'),
    (0x5B00, 0x6CFF, 'the play buffer, 4608 bytes', '18 rows x 8 lines x 32 bytes, linear; also the unpack area'),
    (0x6D00, 0x6FFF, 'ShadowAttributes, 768 bytes', 'the room colours with the actors painted in'),
    (0x7040, 0x727F, 'RoomAttributes', 'the scenery colours, put back after a room change'),
    (0x7280, 0x74BF, 'Cells', '32 x 18 tile numbers, then kinds (0 open)'),
    (0x74E0, 0x75DB, 'the actor records', '14 records of 18 bytes from HeroRecord'),
    (0x76A0, 0x76FF, 'SpanTable (and on)', '6 bytes a span: length, 0, buffer, screen'),
]


def spans(work, frame, out):
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)

    def mem(addr, n):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                         'offset': addr, 'length': n}, ok=False)
        body = r.structured or {}
        if r.is_error or not body.get('exact', False):
            raise SystemExit(f'memory_at {frame}: {r.text}')
        return bytes.fromhex(body['hex'])

    scr = mem(0x4000, 0x1B00)
    count = int.from_bytes(mem(0xFE1C, 2), 'little')
    table = mem(0x76A0, count * 6)
    sc = 2
    pic = zxscreen.render(scr, sc).convert('RGB')
    im, d, y = canvas(40 + 60 + pic.height + 40, 'The screen at c1 frame %d, room 8: the %d open spans' % (frame, count),
                      'Outlined: each span CopyBuffer copies from the play buffer (BuildSpans made them at the room change).\n'
                      'The rest of the play area is scenery, drawn once onto the screen by RoomChange.\n'
                      'Boxes: the HUD (rows 0-5) and the play area (rows 6-23, columns 2-29).')
    x0, y0 = 16, y + 4
    im.paste(pic, (x0, y0))
    d.rectangle((x0, y0, x0 + 256 * sc - 1, y0 + 48 * sc - 1), outline=DIM)
    d.rectangle((x0 + 16 * sc, y0 + 48 * sc, x0 + 240 * sc - 1, y0 + 192 * sc - 1), outline=DIM)
    for i in range(count):
        n, _, blo, bhi, slo, shi = table[i * 6:i * 6 + 6]
        saddr = slo | shi << 8
        off = saddr - 0x4000
        col = off & 31
        line = ((off >> 8) & 7) | ((off >> 2) & 0x38) | ((off >> 5) & 0xC0)
        d.rectangle((x0 + col * 8 * sc, y0 + line * sc, x0 + (col + n) * 8 * sc - 1, y0 + (line + 8) * sc - 1),
                    outline=HI, width=1)
    d.text((x0, y0 + pic.height + 8), '%d spans, %d open cells of 504' % (
        count, sum(table[i * 6] for i in range(count))), font=F(14), fill=HI)
    # the memory map
    mx = x0 + pic.width + 24
    my = y0
    d.text((mx, my), 'Stage 1\'s drawing memory', font=F(15), fill=TEXT)
    my += 26
    for i, (lo, hi, name, what) in enumerate(MEMORY):
        c = COLOURS[i % len(COLOURS)]
        d.rectangle((mx, my, mx + 10, my + 40), fill=c)
        d.text((mx + 18, my), '$%04X-$%04X  %s' % (lo, hi, name), font=F(13), fill=TEXT)
        d.text((mx + 18, my + 20), what, font=F(13), fill=DIM)
        my += 50
    save(im.crop((0, 0, im.width, max(y0 + pic.height + 34, my + 4))), out)


# the c1 room change 8 to 7: (phase, T-states), from the trace 16531:33882-16549:64359
PHASES = [
    ('the pass to CheckRoomExits (ClearBuffer)', 35693),
    ('LeaveRoomLeft, ClearPlayBuffer (LDIR)', 123760),
    ('Unrle: StageGraphics $B4B2 to $5B00', 213849),
    ('ClearShots', 2555),
    ('RoomCells: 9 x 14 blocks to 28 x 18 cells', 98104),
    ('BlackOutPlayArea', 18570),
    ('the 18 rows: 504 tiles to the screen', 342677),
    ('BuildSpans', 126016),
    ('ClearBuffer (PUSH)', 32449),
    ('LoadRoomActors, the actors, DrawActors', 100671),
    ('UpdateAttributes after a HALT; the HUD', 194117),
]


def phases(out):
    total = sum(t for _, t in PHASES)
    im, d, y = canvas(118 + 34 * len(PHASES) + 60, 'The heaviest pass: c1\'s room change from room 8 to room 7',
                      'Frames 16531:33882-16549:64359, %s T-states (%.2f frames of 69 888 T).\nEach phase from the '
                      'trace\'s routine entries; its T-states from the instructions run.' % (
                          format(total, ',').replace(',', ' '), total / 69888))
    y += 10
    lx, bx, bw = 16, 400, 470
    scale = bw / max(t for _, t in PHASES)
    for i, (name, t) in enumerate(PHASES):
        c = COLOURS[i % len(COLOURS)]
        d.text((lx, y + 4), name, font=F(13), fill=TEXT)
        d.rectangle((bx, y + 2, bx + max(2, int(t * scale)), y + 24), fill=c)
        d.text((bx + int(t * scale) + 8, y + 4), '%s T  %.2f fr' % (format(t, ',').replace(',', ' '), t / 69888),
               font=F(13), fill=DIM)
        y += 34
    y += 10
    # the whole as one strip
    x = lx
    sw = 1050 - 2 * lx
    for i, (name, t) in enumerate(PHASES):
        w = t * sw / total
        d.rectangle((int(x), y, int(x + w), y + 22), fill=COLOURS[i % len(COLOURS)])
        x += w
    for k in range(0, int(total / 69888) + 1):
        fx = lx + k * 69888 * sw / total
        d.line((fx, y + 24, fx, y + 30), fill=DIM)
    d.text((lx, y + 32), 'the strip: the whole pass to scale, a tick every frame', font=F(13), fill=DIM)
    save(im.crop((0, 0, im.width, y + 54)), out)


if __name__ == '__main__':
    if sys.argv[1] == 'spans':
        spans(sys.argv[2], int(sys.argv[3]), sys.argv[4])
    else:
        phases(sys.argv[2])
