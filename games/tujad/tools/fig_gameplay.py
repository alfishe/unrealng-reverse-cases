#!/usr/bin/env python3
"""The figures of doc 10 (gameplay logic), drawn from the RZX log, the 1000-frame states and memory samples.

    python3 tools/fig_gameplay.py course --log work/stage1/rzx/frames.bin --states work/stage1/rzx \
        --out docs/img/gameplay/course.png
    python3 tools/fig_gameplay.py route  --log work/stage1/rzx/frames.bin --out docs/img/gameplay/route.png
    python3 tools/fig_gameplay.py deal   --state work/stage1/rzx/at001000.szx --out docs/img/gameplay/deal.png
    python3 tools/fig_gameplay.py energy --touch Z.jsonl --shield R.jsonl --out docs/img/gameplay/energy.png

The RZX log work/stage1/rzx/frames.bin holds $6300-$63FF after each of the 81 000 RZX frames (tools/rzx_keys.py
log); the states atNNNNNN.szx are the machine at RZX frame NNNNNN. A samples file is JSON lines {"frame", "hex"}
of $6300-$63FF written by work/docs/tjC/sample.py (TTD memory_at: the memory at the start of the frame).
"""
import argparse
import json
import os
import sys
from collections import Counter

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import szx  # noqa: E402

BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
WIDTH = 1050
ROOM, ENERGY, LIVES = 0x63, 0x6E, 0x6D
ED_FLAGS = 0x6681
ALIEN_MAP = 0xDB53
RED, GREEN, BLUE, YELLOW, VIOLET, CYAN = (235, 95, 80), (100, 215, 120), (100, 160, 250), (240, 210, 80), \
    (200, 120, 235), (80, 210, 220)


def bcd(v):
    return (v >> 4) * 10 + (v & 15)


def log_frames(path):
    data = open(path, 'rb').read()
    return [data[i:i + 256] for i in range(0, len(data), 256)]


def title(d, text, y=8, size=17):
    d.text((14, y), text, fill=TEXT, font=K.font(size))


def axis(d, box, x_lo, x_hi, y_lo, y_hi, y_ticks, label, x_ticks=None, x_fmt=str):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=PANEL)
    f = K.font(12)
    for v in y_ticks:
        y = y1 - (v - y_lo) * (y1 - y0) / (y_hi - y_lo)
        d.line([(x0, y), (x1, y)], fill=(40, 40, 52))
        d.text((x0 - 8 - d.textlength(str(v), font=f), y - 7), str(v), fill=DIM, font=f)
    for v in x_ticks or []:
        x = x0 + (v - x_lo) * (x1 - x0) / (x_hi - x_lo)
        d.line([(x, y0), (x, y1)], fill=(40, 40, 52))
        d.text((x - d.textlength(x_fmt(v), font=f) / 2, y1 + 4), x_fmt(v), fill=DIM, font=f)
    d.text((x0 + 6, y0 + 4), label, fill=TEXT, font=K.font(13))

    def at(x, y):
        return (x0 + (x - x_lo) * (x1 - x0) / (x_hi - x_lo), y1 - (y - y_lo) * (y1 - y0) / (y_hi - y_lo))
    return at


def ed_count(mem):
    return sum(bin(b & 0x1F).count('1') for b in mem[ED_FLAGS:ED_FLAGS + 10])


def cmd_course(args):
    fr = log_frames(args.log)
    n = len(fr)
    eds = [(0, 0)]
    for k in range(1000, n, 1000):
        p = os.path.join(args.states, f'at{k:06d}.szx')
        if os.path.exists(p):
            eds.append((k, ed_count(szx.read(p)[0])))
    h = 760
    img = Image.new('RGB', (WIDTH, h), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The RZX game: energy, lives, ED pieces and the room over 81 000 frames (27 minutes)')
    d.text((14, 32), 'RZX log work/stage1/rzx/frames.bin ($6300-$63FF after each frame); the ED count from '
                     'EdFlags $6681 in the 1000-frame states', fill=DIM, font=K.font(12))
    xt = list(range(0, n + 1, 9000))
    fmt = (lambda v: f'{v // 3000} min')
    x0, x1 = 70, WIDTH - 20
    start = next(i for i in range(1, n) if fr[i][LIVES] != fr[i - 1][LIVES])  # NewGame sets Lives 3
    # energy
    at = axis(d, (x0, 60, x1, 250), 0, n, 0, 100, [0, 25, 50, 75, 99], 'Energy $636E (BCD as decimal)', xt, fmt)
    pts = [at(i, bcd(fr[i][ENERGY])) for i in range(start, n, 20)]
    d.line(pts, fill=YELLOW, width=1)
    lost = [i for i in range(start + 1, n) if fr[i][LIVES] != fr[i - 1][LIVES]]
    for i in lost:
        x, _ = at(i, 0)
        up = bcd(fr[i][LIVES]) > bcd(fr[i - 1][LIVES])
        d.line([(x, 62), (x, 248)], fill=GREEN if up else RED, width=2)
    # lives and eds
    at2 = axis(d, (x0, 290, x1, 460), 0, n, 0, 50, [0, 10, 20, 30, 40, 50],
               'ED pieces (EdFlags bits, green) and lives $636D x 10 (red)', xt, fmt)
    d.line([at2(k, c) for k, c in eds], fill=GREEN, width=3)
    lv = [at2(i, bcd(fr[i][LIVES]) * 10) for i in range(start, n, 50)]
    d.line(lv, fill=RED, width=2)
    # room
    at3 = axis(d, (x0, 500, x1, 720), 0, n, 0, 128, [0, 32, 64, 84, 96, 127], 'Room $6363', xt, fmt)
    for i in range(0, n, 10):
        x, y = at3(i, fr[i][ROOM])
        d.point((x, y), fill=CYAN)
    x, y = at3(0, 84)
    d.line([(x0, y), (x1, y)], fill=(90, 60, 60))
    f = K.font(12)
    n_lost = len([i for i in lost if bcd(fr[i][LIVES]) < bcd(fr[i - 1][LIVES])])
    d.text((x0, h - 22), f'{n_lost} {"life" if n_lost == 1 else "lives"} lost (red '
           f'lines), {len([i for i in lost if bcd(fr[i][LIVES]) > bcd(fr[i - 1][LIVES])])} GEN 19 taken (green); '
           f'new game at frame {start}; room 84 (the start and the goal) marked',
           fill=TEXT, font=f)
    img.save(args.out)
    print(args.out, img.size, 'lives changes', [(i, fr[i][LIVES]) for i in lost], 'eds', eds[-3:])


def classify(a, b):
    return {1: 'east', -1: 'west', 8: 'south', -8: 'north'}.get(b - a, 'teleport')


def cmd_route(args):
    fr = log_frames(args.log)
    moves = Counter()
    visits = Counter()
    start = next(i for i in range(1, len(fr)) if fr[i][LIVES] != fr[i - 1][LIVES])  # NewGame
    for i in range(start + 1, len(fr)):
        a, b = fr[i - 1][ROOM], fr[i][ROOM]
        if a != b:
            moves[(a, b)] += 1
            visits[b] += 1
    kinds = Counter(classify(a, b) for (a, b), c in moves.items() for _ in range(c))
    base = Image.open(os.path.join(HERE, '..', 'docs', 'img', 'play', 'world-map-rooms.png')).convert('RGB')
    cw = (WIDTH - 40) // 8
    ch = int(cw * base.height / base.width * 8 / 16)
    grid = base.resize((cw * 8, ch * 16), Image.LANCZOS)
    grid = Image.blend(grid, Image.new('RGB', grid.size, (0, 0, 0)), 0.6)
    top = 68
    img = Image.new('RGB', (WIDTH, top + grid.height + 70), BG)
    ox = (WIDTH - grid.width) // 2
    img.paste(grid, (ox, top))
    d = ImageDraw.Draw(img)
    title(d, 'The route of the RZX game: every room change in 81 000 frames, on the room map')
    d.text((14, 32), 'Green lines: walks through an exit (+1 east, -1 west, +8 south, -8 north), width by count.',
           fill=DIM, font=K.font(12))
    d.text((14, 47), 'Violet arcs: teleports, the dot at the target. Rooms entered at least once are framed.',
           fill=DIM, font=K.font(12))

    def centre(r):
        return ox + (r % 8) * cw + cw / 2, top + (r // 8) * ch + ch / 2
    for r in range(128):
        if visits[r] or r == 84:
            x, y = ox + (r % 8) * cw, top + (r // 8) * ch
            d.rectangle([x + 1, y + 1, x + cw - 2, y + ch - 2], outline=YELLOW if r == 84 else (120, 120, 140))
    for (a, b), c in moves.items():
        if a > b and (b, a) in moves and classify(a, b) != 'teleport':
            continue
        c2 = c + moves.get((b, a), 0) if classify(a, b) != 'teleport' else c
        (xa, ya), (xb, yb) = centre(a), centre(b)
        if classify(a, b) == 'teleport':
            mx, my = (xa + xb) / 2 + (yb - ya) * 0.15, (ya + yb) / 2 - (xb - xa) * 0.15
            pts = [((1 - t) ** 2 * xa + 2 * (1 - t) * t * mx + t * t * xb,
                    (1 - t) ** 2 * ya + 2 * (1 - t) * t * my + t * t * yb) for t in [i / 20 for i in range(21)]]
            d.line(pts, fill=VIOLET, width=2)
            d.ellipse([xb - 4, yb - 4, xb + 4, yb + 4], fill=VIOLET)
        else:
            d.line([(xa, ya), (xb, yb)], fill=GREEN, width=min(8, 1 + c2 // 2))
    y = top + grid.height + 10
    d.text((ox, y), f'{sum(moves.values())} room changes: ' + ', '.join(f'{k} {v}' for k, v in kinds.most_common()) +
           f'; {len([r for r in visits if visits[r]])} rooms entered', fill=TEXT, font=K.font(13))
    d.text((ox, y + 22), 'Room 84 (yellow) is the start and the goal. Command: python3 tools/fig_gameplay.py route '
                         '--log work/stage1/rzx/frames.bin', fill=DIM, font=K.font(12))
    img.save(args.out)
    print(args.out, img.size, kinds, len(visits))


def alien_items(mem):
    out = []
    for room in range(0x7C):
        o = mem[ALIEN_MAP + 2 * room] | mem[ALIEN_MAP + 2 * room + 1] << 8
        a = o if o >= ALIEN_MAP else ALIEN_MAP + o
        for k in range(2):
            if mem[a] == 0:
                a += 1
                continue
            out.append((room, mem[a], mem[a + 1]))
            a += 2
    return out


def kind_text(k):
    k |= 0x80
    return 'GEN' if k == 0x80 else 'EN' if k == 0x81 else f'W{k - 0xC0}' if k >= 0xC1 else f'{k - 0x81}'


def kind_colour(k):
    k |= 0x80
    return GREEN if k == 0x80 else YELLOW if k == 0x81 else RED if k >= 0xC1 else BLUE


def cmd_deal(args):
    img_mem = bytearray(0x10000)
    g = open(os.path.join(HERE, '..', 'build', 'game.bin'), 'rb').read()
    img_mem[0x60C0:0x60C0 + len(g)] = g
    a = alien_items(img_mem)
    b = alien_items(szx.read(args.state)[0])
    ka = [x[2] | 0x80 for x in a if not x[2] & 0x40]
    kb = [x[2] | 0x80 for x in b if not x[2] & 0x40]
    shift = [s for s in range(len(ka)) if ka[-s:] + ka[:-s] == kb] if len(ka) == len(kb) else []
    slots = [(x, y) for x, y in zip(a, b) if not x[2] & 0x40]
    per_row = 16
    bw, bh = (WIDTH - 40) // per_row, 70
    rows = (len(slots) + per_row - 1) // per_row
    img = Image.new('RGB', (WIDTH, 130 + rows * (bh + 16) + 60), BG)
    d = ImageDraw.Draw(img)
    title(d, f'The deal: NewGame turns ScrambleRooms {shift[0] if shift else "?"} times, '
             'the non-weapon items move along the list')
    for i, text in enumerate([
            'Each box: one item slot of the alien map, in room order (the room on top).',
            f'Middle: the kind in the image; bottom: the kind in the RZX game at RZX frame 1000 '
            f'({os.path.basename(args.state)}).',
            'Blue: ED piece number; yellow EN: energy source; green GEN: GEN 19; grey: taken by frame 1000. '
            'The 16 weapon slots never move.']):
        d.text((14, 32 + 16 * i), text, fill=DIM, font=K.font(12))
    f = K.font(13)
    for i, ((room, pos, k1), (_, _, k2)) in enumerate(slots):
        x, y = 20 + (i % per_row) * bw, 90 + (i // per_row) * (bh + 16)
        d.rectangle([x + 2, y, x + bw - 3, y + bh], fill=PANEL, outline=(60, 60, 75))
        d.text((x + 6, y + 3), f'r{room}', fill=DIM, font=K.font(12))
        d.text((x + 6, y + 22), kind_text(k1), fill=kind_colour(k1), font=f)
        d.text((x + 6, y + 44), kind_text(k2), fill=kind_colour(k2) if k2 & 0x80 else DIM, font=f)
    y = 90 + rows * (bh + 16) + 4
    dup = [k for k, c in Counter(ka).items() if c > 1 and k >= 0x82]
    d.text((20, y), f'{len(slots)} slots: {sum(1 for k in ka if 0x82 <= k <= 0xB3)} ED pieces (piece '
                    f'{", ".join(kind_text(k) for k in dup)} twice), {ka.count(0x81)} energy sources, '
                    f'{ka.count(0x80)} GEN 19. Shift found: {shift}.', fill=TEXT, font=f)
    d.text((20, y + 22), f'Command: python3 tools/fig_gameplay.py deal --state {args.state}', fill=DIM,
           font=K.font(12))
    img.save(args.out)
    print(args.out, img.size, 'shift', shift, 'dup', [hex(k) for k in dup])


def load(path):
    return [(j['frame'], bytes.fromhex(j['hex'])) for j in map(json.loads, open(path))]


def cmd_energy(args):
    panels = [(load(args.touch), args.touch_title), (load(args.shield), args.shield_title)]
    h = 60 + len(panels) * 320
    img = Image.new('RGB', (WIDTH, h), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The energy clock: EnergyTimer $6366 counts interrupts, EnergyReload $6374 refills it')
    for p, (rows, label) in enumerate(panels):
        lo, hi = rows[0][0], rows[-1][0]
        y0 = 50 + p * 320
        at = axis(d, (70, y0, WIDTH - 20, y0 + 250), lo, hi, 0, 255, [0, 10, 50, 100, 150, 200, 250], label,
                  list(range(lo - lo % 10 + 10, hi + 1, 20)))
        series = [(lambda b: b[0x66], CYAN, 'EnergyTimer'), (lambda b: b[0x74], YELLOW, 'EnergyReload'),
                  (lambda b: b[0x77] * 4, RED, 'TouchTimer x 4'), (lambda b: bcd(b[ENERGY]) * 4 - 100, GREEN,
                                                                  'Energy x 4 - 100'),
                  (lambda b: 200 if b[0x5B] & 0x10 else 0, VIOLET, 'DroidFlags bit 4 (200 = on)')]
        for i, (fn, col, name) in enumerate(series):
            pts = [at(f, max(0, min(255, fn(b)))) for f, b in rows]
            d.line(pts, fill=col, width=2)
            d.text((70 + i * 190, y0 + 274), name, fill=col, font=K.font(12))
    img.save(args.out)
    print(args.out, img.size)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    c = sub.add_parser('course')
    c.add_argument('--log', required=True)
    c.add_argument('--states', required=True)
    c.add_argument('--out', required=True)
    r = sub.add_parser('route')
    r.add_argument('--log', required=True)
    r.add_argument('--out', required=True)
    s = sub.add_parser('deal')
    s.add_argument('--state', required=True)
    s.add_argument('--out', required=True)
    e = sub.add_parser('energy')
    for a in ('--touch', '--shield', '--out'):
        e.add_argument(a, required=True)
    e.add_argument('--touch-title', default='rzx-010000 frames 90-200: an enemy touches the droid at frame 110')
    e.add_argument('--shield-title', default='rzx-007000 frames 240-290: DOWN held alone, the shield 258-276')
    args = p.parse_args()
    {'course': cmd_course, 'route': cmd_route, 'deal': cmd_deal, 'energy': cmd_energy}[args.cmd](args)


if __name__ == '__main__':
    main()
