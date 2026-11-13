#!/usr/bin/env python3
"""Doc 10's figures: a jump traced over the screen, and the energy, the damage and a life lost as a timeline.

    python3 tools/fig_play.py jump WORK F0 F1 docs/img/play/jump-path.png
    python3 tools/fig_play.py energy WORK F0 F1 docs/img/play/energy-death.png

WORK is a re_session work folder whose instance holds the recording. Every value is read with TTD memory_at at the
start of each frame.
jump: the screen at F0 at 3 x, and over it the hero's record ($74E0: +0 the byte column, +1 the line, +8 the frame
of his set, +$0A his state) at every frame from F0 to F1 where it changed: a dot at his top left corner, coloured by
his state (2 the jump), numbered with the jump set's frame. Stage 1 (rzx-r1 3576-3632: one jump right).
energy: from F0 to F1, every 2 frames, Energy `$FE3F`, EnergyChange `$FE4E` (signed), Lives `$FE61`, the hero's
state `$74EA` and his death count `$74F0`: the energy as a line, each new damage as a bar, the state as a band under
it. Stage 1 (c1 15700-16300: a fight with a skeleton, a life lost at 15886, the respawn at 16222).
"""
import os
import sys

from PIL import Image

from figmyth import F, TEXT, DIM, HI, PANEL, COLOURS, canvas, save, kitlib

TOP = 48   # the play buffer's line 0 is the screen's line 48 (row 6), under the HUD

STATE_NAMES = {0: 'stand', 1: 'walk', 2: 'jump', 3: 'fall', 4: 'leap back', 5: 'strike mid', 6: 'strike high',
               7: 'strike low', 9: 'leap', 0x0B: 'recoil', 0x0F: 'dying'}


def session(work):
    sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    return s


def mem(s, frame, addr, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                               'offset': addr, 'length': n}, ok=False)
    body = r.structured or {}
    if r.is_error or not body.get('exact', False):
        raise SystemExit(f'memory_at {frame}: {r.text}')
    return bytes.fromhex(body['hex'])


def jump(work, f0, f1, out):
    sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
    import zxscreen  # noqa: E402
    s = session(work)
    sc = 3
    scr = zxscreen.render(mem(s, f0, 0x4000, 0x1B00), sc).convert('RGB')
    pts = []
    prev = None
    for f in range(f0, f1 + 1):
        r = mem(s, f, 0x74E0, 18)
        key = (r[0], r[1], r[8], r[10])
        if key != prev:
            pts.append((f,) + key)
            prev = key
    first = next(i for i, p in enumerate(pts) if p[4] == 2)
    end = next((i for i in range(first, len(pts)) if pts[i][4] != 2), len(pts))
    pts = pts[:end + 1]
    xs = [p[1] * 8 for p in pts]
    ys = [p[2] + TOP for p in pts]
    x0, x1 = max(0, min(xs) - 24), min(256, max(xs) + 40)
    y0, y1 = max(0, min(ys) - 24), min(192, max(ys) + 40)
    crop = scr.crop((x0 * sc, y0 * sc, x1 * sc, y1 * sc))
    if crop.width > 1018:
        crop = crop.resize((1018, crop.height * 1018 // crop.width), Image.NEAREST)
        k = 1018 / ((x1 - x0) * sc)
    else:
        k = 1.0
    im, d, y = canvas(crop.height + 300, 'One jump in rzx-r1, frames %d-%d: the hero\'s record at every change' % (f0, f1),
                      'The screen at frame %d (3 x). A dot: the hero\'s top left corner (+0 the byte column x 8, +1 the '
                      'line + 48) when his record changed;\nthe number: the frame of his set (+8). Gold: the jump (state 2); '
                      'grey: walk and stand. The record is read with TTD memory_at.' % f0)
    ox, oy = 16, y + 4
    im.paste(crop, (ox, oy))

    def at(px, py):
        return ox + (px - x0) * sc * k, oy + (py - y0) * sc * k

    last = None
    for i, (f, x, yy, fr, st) in enumerate(pts):
        cx, cy = at(x * 8, yy + TOP)
        c = HI if st == 2 else (150, 150, 160)
        if last:
            d.line((last, (cx, cy)), fill=c, width=2)
        d.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=c, outline=(0, 0, 0))
        if st == 2:
            d.text((cx + 6, cy - 18 if i % 2 else cy + 4), '%d' % fr, font=F(13), fill=TEXT)
        last = (cx, cy)
    y = oy + crop.height + 12
    jumps = [p for p in pts if p[4] == 2]
    lines = [
        'The jump: state 2 from frame %d to %d, %d changes of the record; the jump set\'s frames 0 to $12 (19 frames).'
        % (jumps[0][0], jumps[-1][0], len(jumps)),
        'Column %d to %d (%d pixels) in %d recording frames; the line rises %d and comes back.'
        % (jumps[0][1], pts[-1][1], 8 * (pts[-1][1] - jumps[0][1]), pts[-1][0] - jumps[0][0],
           max(p[2] for p in jumps) - min(p[2] for p in jumps)),
        'The arc is in the frames\' own offsets: the base line (+$0E) stays %d the whole jump.' % mem(s, jumps[0][0], 0x74EE, 1)[0],
    ]
    for ln in lines:
        d.text((16, y), ln, font=F(13), fill=TEXT)
        y += 20
    y += 6
    d.text((16, y), 'frame by frame (recording frame: column, line, set frame):', font=F(13), fill=DIM)
    y += 20
    cells = ['%d: %d, %d, %d' % (f, x, yy, fr) for f, x, yy, fr, st in jumps]
    for k2 in range(0, len(cells), 6):
        d.text((16, y), '   '.join(cells[k2:k2 + 6]), font=F(13), fill=TEXT)
        y += 18
    save(im.crop((0, 0, im.width, y + 10)), out)


def energy(work, f0, f1, out):
    s = session(work)
    rows = []
    for f in range(f0, f1, 2):
        e, = mem(s, f, 0x0FE3F, 1)
        ch, = mem(s, f, 0xFE4E, 1)
        lives, = mem(s, f, 0xFE61, 1)
        st, = mem(s, f, 0x74EA, 1)
        rows.append((f, e, ch - 256 if ch >= 128 else ch, lives, st))
    gw, gh = 1018, 300
    im, d, y = canvas(gh + 360, 'A fight and a life lost in c1, frames %d-%d' % (f0, f1),
                      'Line: Energy $FE3F (0-46). Bars: EnergyChange $FE4E when it jumps, the damage just dealt '
                      '(red, down) or the refill (green, up).\nThe band under it: the hero\'s state $74EA. Every value '
                      'read with TTD memory_at every 2 frames.')
    gx, gy = 16, y + 10
    d.rectangle((gx, gy, gx + gw, gy + gh), fill=PANEL)
    n = len(rows)

    def X(i):
        return gx + i * gw / (n - 1)

    def Y(v):
        return gy + gh - 10 - v * (gh - 20) / 46

    for v in (0, 10, 20, 30, 46):
        d.line((gx, Y(v), gx + gw, Y(v)), fill=(55, 55, 70))
        d.text((gx + 4, Y(v) - 16), '%d' % v, font=F(13), fill=DIM)
    pts = [(X(i), Y(r[1])) for i, r in enumerate(rows)]
    d.line(pts, fill=HI, width=3)
    prevch = 0
    for i, r in enumerate(rows):
        ch = r[2]
        if ch != 0 and (prevch == 0 or abs(ch) > abs(prevch)):
            c = (230, 90, 90) if ch < 0 else (90, 200, 110)
            ya, yb = sorted((Y(23), Y(23) - ch * (gh - 20) / 46))
            ya = max(ya, gy + 50)
            d.rectangle((X(i) - 3, ya, X(i) + 3, yb), fill=c)
            d.text((X(i) + 6, (yb if ch < 0 else ya) - (0 if ch < 0 else 2)), '%+d' % ch, font=F(13), fill=c)
        prevch = ch
    for i in range(1, n):
        if rows[i][3] != rows[i - 1][3]:
            d.line((X(i), gy, X(i), gy + gh), fill=(230, 90, 90), width=2)
            d.text((X(i) + 6, gy + 26), 'frame %d: a life lost, Lives %d to %d' % (rows[i][0], rows[i - 1][3], rows[i][3]),
                   font=F(13), fill=(230, 90, 90))
        if rows[i][4] == 0 and rows[i - 1][4] == 0x0F:
            d.line((X(i), gy, X(i), gy + gh), fill=(90, 200, 110), width=2)
            d.text((X(i) - 250, gy + 50), 'frame %d: back at the respawn point' % rows[i][0], font=F(13),
                   fill=(90, 200, 110))
    by = gy + gh + 8
    pal = {}
    i = 0
    while i < n:
        j = i
        while j < n and rows[j][4] == rows[i][4]:
            j += 1
        st = rows[i][4]
        c = pal.setdefault(st, COLOURS[len(pal) % len(COLOURS)])
        d.rectangle((X(i), by, X(j - 1) + 2, by + 20), fill=c)
        i = j
    for i in range(0, n, max(1, n // 10)):
        d.text((X(i), by + 26), '%d' % rows[i][0], font=F(13), fill=DIM)
    ly = by + 52
    for k, (st, c) in enumerate(pal.items()):
        cx = 16 + (k % 4) * 250
        cy = ly + (k // 4) * 22
        d.rectangle((cx, cy + 3, cx + 12, cy + 15), fill=c)
        d.text((cx + 20, cy), 'state %d: %s' % (st, STATE_NAMES.get(st, '?')), font=F(13), fill=TEXT)
    ly += 22 * ((len(pal) + 3) // 4) + 10
    notes = ['Each hit sets EnergyChange negative; ApplyEnergyChange then takes 2 a pass from Energy and gives 2 back to '
             'EnergyChange.',
             'Energy reaching 0 calls LoseLife: Lives - 1, Energy 0, EnergyChange +46 (the refill), HeroDeath.',
             'The hero waits in state 15 while his count +$10 runs down, then stands at the room\'s respawn point.']
    for t in notes:
        d.text((16, ly), t, font=F(13), fill=TEXT)
        ly += 20
    save(im.crop((0, 0, im.width, ly + 10)), out)


if __name__ == '__main__':
    cmd, work, f0, f1, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
    {'jump': jump, 'energy': energy}[cmd](work, f0, f1, out)
