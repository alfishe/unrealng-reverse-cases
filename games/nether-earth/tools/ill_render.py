#!/usr/bin/env python3
"""The illustrated figures of docs 06 (rendering) and 07 (objects): each drawn from real data, an access trace of a
recording, the memory of a recording (TTD memory_at, read only) or the start image, with tools/ill_view.py (DrawView
in Python, byte for byte the game's: `verify`) where a view is drawn that the camera never showed.

    python3 tools/ill_render.py verify     --work work/deep --views 60
    python3 tools/ill_render.py build      --trace work/docB/rec/traces/1995_21900-2003_60100.uatr --out docs/img/render/view-build.gif
    python3 tools/ill_render.py projection --trace work/docB/rec/traces/1995_21900-2003_60100.uatr --out docs/img/render/projection.png
    python3 tools/ill_render.py blit       --trace work/docB/rec/traces/1995_21900-2003_60100.uatr --out docs/img/render/blit.png
    python3 tools/ill_render.py order      --work work/deep --frames 7213,162 --out docs/img/render/draw-order.png
    python3 tools/ill_render.py parts      --image work/deep/start.bin --out docs/img/render/robot-parts.png
    python3 tools/ill_render.py radar      --work work/deep --frame 18500 --count 40 --out docs/img/render/radar.gif
    python3 tools/ill_render.py worldmap   --work work/deep --frame 200 --out docs/img/render/world-map.png
    python3 tools/ill_render.py tear       --trace work/ill2/deep/traces/25081_0-25083_0.uatr --out docs/img/render/tear.png
    python3 tools/ill_render.py record     --work work/deep --frame 7093 --slot 3 --out docs/img/render/robot-record.png
    python3 tools/ill_render.py movie      --work work/deep --step 120 --out docs/img/render/robots-movie.gif
    python3 tools/ill_render.py days       --work work/deep --step 120 --out docs/img/render/ownership-days.png
    python3 tools/ill_render.py fight      --work work/deep --frames 18670,18860 --slots 2,25 --view-x 105 --out docs/img/render/fight.gif
    python3 tools/ill_render.py bits       --work work/deep --frame 20000 --left 12 --hex-left 16 --hex-top 2 --out docs/img/render/cell-bits.png

The tear trace is the access trace of frames 25081:0-25083:0 of work/deep (kitlib.load_trace, as kit/routine_anim.py
takes it); its beam picture is tools/fig_beam_turn.py --trace work/ill2/deep/traces/25081_0-25083_0.uatr --listing
work/mkgame/game.lst --copy-frame 25081 --copy-only --title ... --out docs/img/render/tear-beam.png.

--work is a recording folder whose session.json names a live instance holding it (`re_session.py open --work W
--ttd W/session.ttd --port-base P` starts one); the memory it reads is kept in --cache (default work/ill2/cache), one
file a moment, so a figure is redrawn later without an instance. The traces are kit/routine_anim.py's.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402
import ill_view as V  # noqa: E402

MAP, ROBOTS, BUILDINGS, POINTS, VARS, SHOTS = 0xDD00, 0xDA00, 0xFF01, 0xFD70, 0xFD00, 0xD7D3
RADAR_OWN, RADAR_ENEMY = 0xD800, 0xD900
OURS, THEIRS, NEUTRAL = (90, 210, 110), (235, 85, 80), (200, 200, 210)
SHIP = (120, 200, 255)
PAPER, INK = K.ink_colour(6, True), (0, 0, 0)          # attribute $70: bright, yellow paper, black ink
PART_NAMES = ['bipod', 'tracks', 'anti-grav', 'cannon', 'missiles', 'phasers', 'nuclear', 'electronics']
FACING = {1: 'right (x+)', 2: 'left (x-)', 4: 'down (y+)', 8: 'up (y-)'}
ORDERS = ['stop', 'advance', 'retreat', 'destroy robots', 'destroy factories', 'destroy warbases',
          'capture neutral factories', 'capture enemy factories', 'capture enemy warbases']
POINT_LETTERS = 'BENPMCW'      # warbase, electronics, nuclear, phasers, missiles, cannon, chassis (+3 bits 0-2)


def rel(path):
    return os.path.relpath(os.path.abspath(path), CASE)


# ---------------------------------------------------------------------------------------------------------------
# memory of a recording

class Recording:
    """memory_at of a recording's live instance, each answer kept in a file"""

    def __init__(self, work, cache, unreal=None):
        self.work, self.unreal = work, unreal
        self.dir = os.path.join(cache, os.path.basename(os.path.abspath(work).rstrip('/')))
        os.makedirs(self.dir, exist_ok=True)
        self.session = None

    def call(self, args):
        if self.session is None:
            sys.path.insert(0, os.path.join(K.unreal_root(self.unreal), 'tools', 'verification', 'analysis'))
            import re_session  # noqa: E402
            self.session, _ = re_session.session_of(self.work)
        r = self.session.call('time_travel', args, ok=False)
        if r.is_error:
            raise SystemExit(f'time_travel {args}: {r.text}')
        return r.structured or {}

    def read(self, frame, address=0x4000, length=0xC000, tinframe=0):
        """bytes at address.. of the CPU view at frame:tinframe; whole 48 K reads are cached as one file"""
        path = os.path.join(self.dir, f'{frame}_{tinframe}.bin')
        if not os.path.isfile(path):
            st = self.call({'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': tinframe,
                            'offset': 0x4000, 'length': 0xC000})
            if not st.get('exact'):
                raise SystemExit(f'memory_at {frame}:{tinframe} not exact')
            open(path, 'wb').write(bytes.fromhex(st['hex']))
        data = open(path, 'rb').read()
        return data[address - 0x4000:address - 0x4000 + length]

    def memory(self, frame, tinframe=0):
        """the 64 K view (the ROM left as zeros)"""
        return bytes(0x4000) + self.read(frame, 0x4000, 0xC000, tinframe)

    def executions(self, address, before_frame, count):
        """(frame, tinframe) of the last `count` executions of address before before_frame, oldest first"""
        path = os.path.join(self.dir, f'exec_{address:04X}_{before_frame}_{count}.json')
        if not os.path.isfile(path):
            hits, before = [], None
            while len(hits) < count:
                args = {'action': 'find_last', 'addr': address, 'access': 'execute', 'all': True,
                        'limit': min(500, count - len(hits))}
                args.update({'before': before} if before else {'before_frame': before_frame})
                st = self.call(args)
                hits += [(h['frame'], h['tinframe']) for h in st.get('hits', [])]
                before = st.get('next_before')
                if not before or not st.get('hits'):
                    break
            json.dump(hits, open(path, 'w'))
        return sorted(tuple(h) for h in json.load(open(path)))


def load_trace(path, unreal=None):
    return K.access_trace(unreal).load(path)


# ---------------------------------------------------------------------------------------------------------------
# drawing helpers

def font(n):
    return K.font(n)


def buffer_image(buf, scale=3, paper=PAPER, ink=INK):
    """the 20 x 160 byte view buffer as the screen shows it (black ink on bright yellow paper)"""
    im = Image.new('RGB', (160, 160), paper)
    px = im.load()
    for y in range(160):
        for b in range(20):
            v = buf[20 * y + b]
            for bit in range(8):
                if v & 0x80 >> bit:
                    px[8 * b + bit, y] = ink
    return im.resize((160 * scale, 160 * scale), Image.NEAREST) if scale != 1 else im


def sprite_box(ev, scale):
    """the buffer rectangle (x0, y0, x1, y1) a DrawSprite event covers, in scaled pixels (may stick out)"""
    x0 = ev['col'] * 8 + 4 * ev['odd'] * 0      # the odd picture is already shifted inside its block
    y1 = ev['line'] + 1
    y0 = y1 - ev['rows']
    x1 = x0 + 8 * ev['width']
    return x0 * scale, y0 * scale, x1 * scale, y1 * scale


def cell_colour(c):
    t = c & 0x1F
    if t in (0, 1):
        return (36, 36, 30)
    if 2 <= t <= 5:
        return (95, 85, 50)
    if t in (6, 7):
        return (110, 70, 50)
    if 8 <= t <= 11:
        return (140, 125, 70)
    if 12 <= t <= 14:
        return (40, 70, 110)
    if t in (15, 17):
        return (170, 170, 175)
    if t in (16, 18):
        return (230, 230, 235)
    if t == 21:
        return (200, 60, 200)
    return (255, 0, 255)


TERRAIN_LEGEND = [((36, 36, 30), 'ground (0)'), ((95, 85, 50), 'stones 2-5, h 2'), ((110, 70, 50), 'boulders 6-7, h 3'),
                  ((140, 125, 70), 'rocks 8-11, h 6'), ((40, 70, 110), 'trench 12-14, h 0'),
                  ((170, 170, 175), 'low block 15/17, h 7'), ((230, 230, 235), 'tall block 16/18, h 15'),
                  ((200, 60, 200), 'edge post 21, h 99')]


def legend(d, x, y, items, f, gap=14):
    for colour, text in items:
        d.rectangle([x, y + 3, x + 10, y + 13], fill=colour)
        d.text((x + 15, y), text, fill=K.DIM, font=f)
        x += 15 + int(d.textlength(text, font=f)) + gap
    return x


def arrow(d, a, b, colour, width=2, head=8):
    import math
    d.line([a, b], fill=colour, width=width)
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    for s in (-0.45, 0.45):
        d.line([b, (b[0] - head * math.cos(ang + s), b[1] - head * math.sin(ang + s))], fill=colour, width=width)


def view_of(m):
    return V.word(m, V.MAP_VIEW) - MAP          # ViewX (MapView = $DD00 + ViewX)


def cell_xy(hl):
    return (hl - MAP) & 0x1FF, (hl - MAP) >> 9


def project(e, d, h=0):
    """DrawSprite's L and H as buffer pixels: the left x of a sprite's block and its bottom line"""
    return 8 * e + 4 * d - 96, 8 * d + 100 - 4 * e - h


# ---------------------------------------------------------------------------------------------------------------
# verify: ill_view.py against the game's own views over a recording

def fig_verify(a):
    rec = Recording(a.work, a.cache, a.unreal)
    starts = rec.executions(0xCCBD, a.last, 4000)
    copies = rec.executions(0xD071, a.last, 4000)
    pick = [starts[i * (len(starts) - 1) // (a.views - 1)] for i in range(a.views)]
    bad, kinds = 0, {}
    for f, t in pick:
        c = next(x for x in copies if x > (f, t))
        mine, events, _ = V.draw_view(rec.memory(f, t))
        game = rec.read(c[0], V.VIEW, 3200, c[1])
        diff = sum(1 for i in range(3200) if mine[i] != game[i])
        for e in events:
            if e['kind'] in ('defer', 'ship_defer', 'undefer', 'ship_undefer'):
                kinds[e['kind']] = kinds.get(e['kind'], 0) + 1
        bad += diff != 0
        print(f'{f}:{t} -> copy {c[0]}:{c[1]}: {diff} bytes differ, '
              f'{sum(1 for e in events if e.get("drawn"))} sprites')
    print(f'{a.views} views, {bad} differ; deferral events {kinds}')


# ---------------------------------------------------------------------------------------------------------------
# 06: the view built step by step (from an access trace of one DrawView)

def trace_events(t):
    """the instruction indexes of the stages of the DrawView in trace t"""
    ins = t.instructions
    first = {}
    sprites = []
    for i, x in enumerate(ins):
        if x.pc in (0xCCBD, 0xCFFE, 0xD026, 0xD057, 0xCCC6, 0xD071) and x.pc not in first:
            first[x.pc] = i
        if x.pc == 0xCF2D:
            sprites.append(i)
    return first, sprites


PLAN_X, PLAN_Y = 100, 44          # buffer pixel (0, 0) inside a plan picture


def ground(u, v):
    """the buffer pixel of the ground point (u, v): u = map x - ViewX, v = map y (cell (x, y) is the unit square
    from (u, v) to (u + 1, v + 1)); DrawSprite puts a block's lowest vertex at its anchor's (u, v + 1)"""
    return 8 * u + 4 * v - 92, -4 * u + 8 * v + 92


def quad(u, v, scale, ox=PLAN_X, oy=PLAN_Y):
    return [((ground(a, b)[0] + ox) * scale, (ground(a, b)[1] + oy) * scale)
            for a, b in ((u, v), (u + 1, v), (u + 1, v + 1), (u, v + 1))]


def plan(m, view_x, scale, lit=None, current=None, size=(336, 272)):
    """the 32 x 16 cells of the view window projected as DrawSprite projects them (cell squares turned into the
    view's rhombi), the buffer's 160 x 160 window drawn over them"""
    im = Image.new("RGB", (int(size[0] * scale), int(size[1] * scale)), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    for v in range(16):
        for u in range(32):
            c = m[MAP + 0x200 * v + view_x + u]
            col = cell_colour(c)
            if lit is not None and not lit(u, v):
                col = tuple(int(k * 0.4) for k in col)
            d.polygon(quad(u, v, scale), fill=col, outline=(60, 60, 70))
    for v in range(16):
        for u in range(32):
            c = m[MAP + 0x200 * v + view_x + u]
            cx = sum(p[0] for p in quad(u, v, scale)) / 4
            cy = sum(p[1] for p in quad(u, v, scale)) / 4
            if c & 0x40:
                d.ellipse([cx - 3 * scale, cy - 3 * scale, cx + 3 * scale, cy + 3 * scale], outline=(255, 140, 60),
                          width=2)
            if c & 0x80:
                d.line([cx - 3 * scale, cy - 3 * scale, cx + 3 * scale, cy + 3 * scale], fill=SHIP, width=2)
                d.line([cx + 3 * scale, cy - 3 * scale, cx - 3 * scale, cy + 3 * scale], fill=SHIP, width=2)
    if current:
        d.polygon(quad(*current, scale), outline=(255, 60, 60), width=3)
    d.rectangle([PLAN_X * scale, PLAN_Y * scale, (PLAN_X + 160) * scale, (PLAN_Y + 160) * scale],
                outline=(255, 255, 0), width=2)
    return im


def walked_before(k, row):
    """the walk's order: is cell (u, v) walked when the walk is at diagonal u - v = k, row `row`?"""
    return lambda u, v: (u - v) > k or ((u - v) == k and v <= row)


def fig_build(a):
    t = load_trace(a.trace, a.unreal)
    first, sprite_idx = trace_events(t)
    start = bytes(t.memory_at(0))
    _, events, _ = V.draw_view(start)
    sprites = [e for e in events if 'sprite' in e]
    if len(sprites) != len(sprite_idx):
        raise SystemExit(f'{len(sprites)} sprites in ill_view, {len(sprite_idx)} DrawSprite calls in the trace')
    view_x = view_of(start)
    ins = t.instructions
    clear_end = first[0xD026]
    moments = [(0, 'the old view: the buffer as the last turn left it', None)]
    for k in (1, 2, 3):
        moments.append((first[0xCFFE] + (clear_end - first[0xCFFE]) * k // 4,
                        'ClearViewBuffer $CFFE: SP = $6780, PUSH HL = 0 eight times a pass, from the bottom up', None))
    moments.append((clear_end, 'cleared: 3168 bytes by PUSH, the last 32 by LDIR', None))
    moments.append((first[0xD057], 'FillViewCorner $D026: the far corner outside the map, 5 bands of $FF', None))
    moments.append((first[0xCCC6], "DrawEdgeStrips $D057: the map's far edge and its near right corner", None))
    pending, by_sprite = [], []
    for e in events:
        if e['kind'] == 'cell':
            pending.append(e)
        if 'sprite' in e:
            by_sprite.append((e, list(pending)))
            pending = []
    copy = first[0xD071]
    for n, (ev, cells) in enumerate(by_sprite):
        moments.append((sprite_idx[n + 1] if n + 1 < len(sprite_idx) else copy, None, (n, ev, cells)))
    S, PS = 3, 1.5
    pw, ph = int(336 * PS), int(272 * PS)
    W, H = 20 + 160 * S + 30 + pw + 70, 50 + 160 * S + 100
    f, small, tiny = font(14), font(12), font(11)
    pictures, durations = [], []
    last_cell = None
    for idx, text, info in moments:
        mem = bytes(t.memory_at(idx))
        out = Image.new('RGB', (W, H), K.BACKGROUND)
        d = ImageDraw.Draw(out)
        out.paste(buffer_image(mem[V.VIEW:V.FONT], S), (20, 50))
        x = ins[min(idx, len(ins) - 1)]
        d.text((20, 10), f'DrawView $CCBD, one call: work/docB/rec frame {x.frame} T {x.t}', fill=K.TEXT, font=f)
        d.text((20, 30), 'the view buffer $5B00, 20 bytes x 160 lines (3x), in the colours of the screen',
               fill=K.DIM, font=small)
        lit, current, label, label2 = (lambda u, v: False), None, text, ''
        if info:
            n, ev, cells = info
            if cells:
                last_cell = cells[-1]
            if last_cell:
                cx, cy = cell_xy(last_cell['hl'])
                current = (cx - view_x, cy)
                lit = walked_before(current[0] - current[1], cy)
            x0, y0, x1, y1 = sprite_box(ev, S)
            if ev['drawn'] and min(x1, 160 * S) > max(x0, 0) and min(y1, 160 * S) > max(y0, 0):
                d.rectangle([20 + max(x0, 0), 50 + max(y0, 0), 20 + min(x1, 160 * S) - 1, 50 + min(y1, 160 * S) - 1],
                            outline=(255, 40, 40), width=2)
            label = (f'sprite {n + 1} of {len(sprites)}: {ev["kind"]}, sprite {ev["sprite"]} (${ev["sprite"]:02X})'
                     f'{", the odd picture" if ev["odd"] else ""}, view column E {ev["e"]}, row D {ev["d"]}, '
                     f'height {ev["h"]}' + ('' if ev['drawn'] else ': clipped, nothing drawn'))
            if cells and ev['kind'] != 'shadow':
                c = cells[-1]
                label2 = (f'DrawCell: cell ({current[0]} + ViewX, {cy}) = ${c["v"]:02X}, diagonal x - y = '
                          f'{current[0] - cy}; {len(cells)} occupied cell(s) since the last sprite')
            elif ev['kind'] == 'shadow':
                label2 = 'DrawMapObjects $CCC6: the ship\'s shadow first, so that everything covers it'
            else:
                label2 = 'the same cell: the next part of the robot, or the ship over it'
        elif idx >= first[0xCCC6]:
            lit = lambda u, v: False
        d.text((20, 50 + 160 * S + 14), label, fill=K.TEXT, font=small)
        d.text((20, 50 + 160 * S + 34), label2, fill=K.DIM, font=small)
        mx = 20 + 160 * S + 30
        d.text((mx, 50), 'the 32 x 16 map cells of the view, projected as DrawSprite projects them;',
               fill=K.TEXT, font=small)
        d.text((mx, 66), 'yellow: the buffer\'s window. Walked cells lit, the current cell in red', fill=K.DIM,
               font=small)
        out.paste(plan(start, view_x, PS, lit, current), (mx, 90))
        y = 90 + ph - 30
        legend(d, mx, y - 17, TERRAIN_LEGEND[:3], tiny, 10)
        legend(d, mx, y, TERRAIN_LEGEND[3:6], tiny, 10)
        legend(d, mx, y + 17, TERRAIN_LEGEND[6:], tiny, 10)
        d.text((mx, y + 36), 'orange ring: bit 6 (an object), blue cross: bit 7 (the ship)', fill=K.DIM, font=tiny)
        d.text((mx, y + 52), 'the walk: diagonals x - y = 31 down to -15, each from row 0 down and right',
               fill=K.DIM, font=tiny)
        d.text((20, H - 22), f'tools/ill_render.py build --trace {rel(a.trace)} --out {rel(a.out)}', fill=K.DIM,
               font=tiny)
        pictures.append(out)
        durations.append(800 if info is None else 500)
    durations[0] = 2500
    durations[-1] = 3500
    K.save_gif(a.out, pictures, durations)
    print(a.out, len(pictures), os.path.getsize(a.out))


# ---------------------------------------------------------------------------------------------------------------
# 06: the projection over a real view

def final_view(t):
    first, _ = trace_events(t)
    return bytes(t.memory_at(first[0xD071])), bytes(t.memory_at(0))


def fig_projection(a):
    t = load_trace(a.trace, a.unreal)
    end, start = final_view(t)
    view_x = view_of(start)
    _, events, _ = V.draw_view(start)
    S, OX, OY = 4, 30, 60
    W, H = OX + 160 * S + 30 + 470, OY + 160 * S + 60
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    out.paste(buffer_image(end[V.VIEW:V.FONT], S), (OX, OY))
    over = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    o = ImageDraw.Draw(over)
    clip = Image.new('L', (W, H), 0)
    ImageDraw.Draw(clip).rectangle([OX, OY, OX + 160 * S - 1, OY + 160 * S - 1], fill=255)

    def g(u, v, h=0):
        x, y = ground(u, v)
        return OX + x * S, OY + (y - h) * S

    for u in range(0, 33):
        o.line([g(u, 0), g(u, 16)], fill=(0, 140, 255, 120), width=1)
    for v in range(0, 17):
        o.line([g(0, v), g(32, v)], fill=(0, 140, 255, 120), width=1)
    # the anchor cells of the objects and of three blocks, filled
    robot = next(e for e in events if e['kind'].startswith('robot 1 part 0'))
    marks = [((robot['e'], robot['d']), (255, 60, 60, 110), 'robot 1'),
             ((21, 5), (60, 200, 255, 110), 'pad'), ((17, 5), (60, 200, 255, 110), 'flag')]
    for (u, v), colour, _ in marks:
        o.polygon([g(u, v), g(u + 1, v), g(u + 1, v + 1), g(u, v + 1)], fill=colour)
    # a block's footprint: the low block anchored at (24, 8), its four cells and the anchor
    bu, bv = 23, 8
    o.polygon([g(bu, bv - 1), g(bu + 2, bv - 1), g(bu + 2, bv + 1), g(bu, bv + 1)], outline=(255, 140, 40, 255),
              width=3)
    o.polygon([g(bu, bv), g(bu + 1, bv), g(bu + 1, bv + 1), g(bu, bv + 1)], fill=(255, 140, 40, 120))
    alpha = Image.composite(over.getchannel('A'), Image.new('L', (W, H), 0), clip)
    over.putalpha(alpha)
    out.paste(over, (0, 0), over)
    d = ImageDraw.Draw(out)
    x, y = g(bu + 0.5, bv + 0.5)
    d.text((x - 50, y + 6), f'block anchor ({bu + view_x},{bv})', fill=(255, 255, 255), font=font(11), stroke_width=2,
           stroke_fill=(0, 0, 0))
    f, small, tiny = font(14), font(12), font(11)
    d.text((OX, 10), 'The projection: the map cells as DrawSprite places them, over the view of work/docB/rec frame 2003',
           fill=K.TEXT, font=f)
    d.text((OX, 30), f'the buffer $5B00 when CopyViewToScreen starts (2002:46058), 4x; ViewX = {view_x}; blue: the '
           'cell edges at height 0', fill=K.DIM, font=small)
    for (u, v), colour, name in marks:
        x, y = g(u + 0.5, v + 0.5)
        d.text((x - 20, y - 6), f'({u + view_x},{v})', fill=(255, 255, 255), font=tiny, stroke_width=2,
               stroke_fill=(0, 0, 0))
    # the robot's sprite box: L and H
    x0, y0, x1, y1 = sprite_box(robot, S)
    d.rectangle([OX + x0, OY + y0, OX + x1 - 1, OY + y1 - 1], outline=(255, 60, 60), width=2)
    # the axes from a ground point
    base = (17, 10)
    p0 = g(*base)
    for (du, dv, dh), colour, text in (((3, 0, 0), (255, 140, 40), 'x + 3'), ((0, 2, 0), (80, 230, 110), 'y + 2'),
                                       ((0, 0, 24), (230, 90, 230), 'h + 24')):
        p1 = g(base[0] + du, base[1] + dv, dh)
        arrow(d, p0, p1, colour, 3, 12)
        d.text((p1[0] + 6, p1[1] - 8), text, fill=colour, font=small, stroke_width=2, stroke_fill=(0, 0, 0))
    # the formulas
    px, y = OX + 160 * S + 30, OY
    lines = [
        ('DrawSprite $CF2D: A = sprite, E = view column, D = row,', K.TEXT),
        ('the height h in its own operand $CF3F', K.TEXT),
        ('', None),
        ('L = 2E + D - 24     the column in half bytes', (255, 230, 120)),
        ('H = 8D + 100 - 4E - h   the bottom line', (255, 230, 120)),
        ('byte = L >> 1 (SRA); the carry picks the', K.DIM),
        ('aligned picture or the one shifted 4 pixels', K.DIM),
        ('', None),
        ('one cell along x:  8 pixels right, 4 up', (255, 140, 40)),
        ('one cell along y:  4 pixels right, 8 down', (80, 230, 110)),
        ('one unit of height: 1 pixel up', (230, 90, 230)),
        ('the two steps are at right angles and equally', K.DIM),
        ('long: the cells are squares turned by 26.6 deg', K.DIM),
        ('(atan 1/2), not the 2:1 diamonds of most', K.DIM),
        ('isometric games', K.DIM),
        ('', None),
        (f'robot 1 (slot 1, $DA10): cell ({robot["e"] + view_x},{robot["d"]}), E = {robot["e"]}, D = {robot["d"]}',
         (255, 90, 90)),
        (f'  bipod, h = +$0D = {robot["h"]}:', (255, 90, 90)),
        (f'  L = 2 x {robot["e"]} + {robot["d"]} - 24 = {2 * robot["e"] + robot["d"] - 24}: byte '
         f'{robot["col"]}, even', (255, 90, 90)),
        (f'  H = 8 x {robot["d"]} + 100 - 4 x {robot["e"]} - 0 = {robot["line"]}', (255, 90, 90)),
        (f'  sprite {robot["sprite"]} (${robot["sprite"]:02X}), {robot["rows"]} lines x {robot["width"]} bytes, '
         'the red box', (255, 90, 90)),
        ('', None),
        ('orange: a low block (sprite 15) covers 2 x 2 cells,', (255, 140, 40)),
        ('(x, y), (x+1, y), (x, y-1), (x+1, y-1); only the', (255, 140, 40)),
        ('anchor (x, y), the cell nearest the viewer, draws', (255, 140, 40)),
        ('it: the sprite\'s lowest vertex is the anchor\'s', (255, 140, 40)),
        ('(x, y + 1) corner', (255, 140, 40)),
        ('', None),
        ('the far corner (top left) and the strip along', K.DIM),
        ('the bottom right are FillViewCorner and', K.DIM),
        ('DrawEdgeStrips: the map\'s edges', K.DIM),
    ]
    for text, colour in lines:
        if colour:
            d.text((px, y), text, fill=colour, font=small)
        y += 19
    d.text((OX, H - 24), f'tools/ill_render.py projection --trace {rel(a.trace)} --out {rel(a.out)}', fill=K.DIM,
           font=tiny)
    out.save(a.out)
    print(a.out, out.size)


# ---------------------------------------------------------------------------------------------------------------
# 06: one sprite, mask and graphic apart, then composed over the real background

def sprite_layers(m, ev):
    """per buffer byte the sprite covers: {(line, byte): (mask, graphic)} as DrawSprite applies them"""
    at = ev['block']
    rows, width = m[at], m[at + 1]
    out = {}
    for r in range(rows):
        line = ev['line'] - r
        for b in range(width):
            col = ev['col'] + b
            if 0 <= line < 160 and 0 <= col < 20:
                out[(line, col)] = (m[at + 2 + 2 * (r * width + b)], m[at + 3 + 2 * (r * width + b)])
    return out


def bits_image(lines, cols, value, scale, on, off, grid=(0, 0, 0)):
    """a picture of bytes: value(line, col) -> byte or None (outside the sprite)"""
    w, h = len(cols) * 8, len(lines)
    im = Image.new('RGB', (w * scale, h * scale), off)
    d = ImageDraw.Draw(im)
    for y, line in enumerate(lines):
        for x, col in enumerate(cols):
            v = value(line, col)
            for bit in range(8):
                if v is None:
                    c = (40, 40, 48)
                else:
                    c = on if v & 0x80 >> bit else off
                X = (8 * x + bit) * scale
                d.rectangle([X, y * scale, X + scale - 1, y * scale + scale - 1], fill=c)
    for x in range(len(cols) + 1):
        d.line([x * 8 * scale, 0, x * 8 * scale, h * scale], fill=(120, 120, 140))
    return im


def fig_blit(a):
    t = load_trace(a.trace, a.unreal)
    first, sprite_idx = trace_events(t)
    start = bytes(t.memory_at(0))
    _, events, _ = V.draw_view(start)
    sprites = [e for e in events if 'sprite' in e]
    picks = [i for i, e in enumerate(sprites) if e['kind'].startswith('robot 1')]
    S = 7
    f, small, tiny = font(14), font(12), font(11)
    rows = []
    for i in picks:
        ev = sprites[i]
        before = bytes(t.memory_at(sprite_idx[i]))
        after = bytes(t.memory_at(sprite_idx[i + 1] if i + 1 < len(sprite_idx) else first[0xD071]))
        lay = sprite_layers(start, ev)
        lines = list(range(max(0, ev['line'] - ev['rows'] - 1), min(160, ev['line'] + 3)))
        cols = list(range(max(0, ev['col']), min(20, ev['col'] + ev['width'])))
        buf = lambda m: (lambda line, col: m[V.VIEW + 20 * line + col])
        def masked(line, col):
            v = before[V.VIEW + 20 * line + col]
            return v & lay[(line, col)][0] if (line, col) in lay else v
        def composed(line, col):
            v = before[V.VIEW + 20 * line + col]
            return (v & lay[(line, col)][0]) | lay[(line, col)][1] if (line, col) in lay else v
        mask = lambda line, col: lay[(line, col)][0] if (line, col) in lay else None
        graphic = lambda line, col: lay[(line, col)][1] if (line, col) in lay else None
        same = all(composed(line, col) == after[V.VIEW + 20 * line + col] for line in lines for col in cols)
        panels = [
            ('the buffer before', bits_image(lines, cols, buf(before), S, INK, PAPER)),
            ('mask (1 keeps, 0 clears)', bits_image(lines, cols, mask, S, (235, 235, 235), (60, 60, 200))),
            ('buffer AND mask', bits_image(lines, cols, masked, S, INK, PAPER)),
            ('graphic (1 = ink)', bits_image(lines, cols, graphic, S, (255, 80, 80), (30, 30, 36))),
            ('(buffer AND mask) OR graphic', bits_image(lines, cols, composed, S, INK, PAPER)),
        ]
        rows.append((ev, panels, same, lines, cols, before, lay))
    pw = max(p.width for _, ps, *_ in rows for _, p in ps)
    ph = [max(p.height for _, p in ps) for _, ps, *_ in rows]
    W = 20 + 5 * (pw + 34) + 20
    H = 60 + sum(h + 105 for h in ph) + 30
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((20, 10), 'DrawSprite $CF2D: a byte of the buffer becomes (byte AND mask) OR graphic (SpriteByteLoop $CFBB)',
           fill=K.TEXT, font=f)
    d.text((20, 30), 'robot 1 ($DA10, bipod + cannon) at frame 2000 of work/docB/rec: each part over what is already '
           'there (the ship\'s shadow, then the bipod), 7x', fill=K.DIM, font=small)
    y = 60
    ops = ['', 'AND', '=', 'OR', '=']
    for (ev, panels, same, lines, cols, before, lay), h in zip(rows, ph):
        name = PART_NAMES[int(ev['kind'].split()[-1])]
        d.text((20, y), f'{name}: sprite {ev["sprite"]} (${ev["sprite"]:02X}) block ${ev["block"]:04X}, '
               f'{ev["rows"]} lines x {ev["width"]} bytes, bottom line {ev["line"]}, byte {ev["col"]}, height '
               f'{ev["h"]}', fill=(255, 200, 90), font=small)
        x = 20
        for k, (label, p) in enumerate(panels):
            d.text((x, y + 20), label, fill=K.DIM, font=tiny)
            out.paste(p, (x, y + 38))
            if k:
                d.text((x - 30, y + 38 + h // 2 - 8), ops[k], fill=K.TEXT, font=f)
            x += pw + 34
        # one row of bytes, written out
        mid = ev['line'] - ev['rows'] // 2
        yy = y + 38 + h + 10
        cells = [c for c in cols if (mid, c) in lay]
        bg = ' '.join(f'{before[V.VIEW + 20 * mid + c]:02X}' for c in cells)
        mk = ' '.join(f'{lay[(mid, c)][0]:02X}' for c in cells)
        gr = ' '.join(f'{lay[(mid, c)][1]:02X}' for c in cells)
        rs = ' '.join(f'{(before[V.VIEW + 20 * mid + c] & lay[(mid, c)][0]) | lay[(mid, c)][1]:02X}' for c in cells)
        d.text((20, yy), f'line {mid} (${V.VIEW + 20 * mid + cells[0]:04X}): buffer {bg}  AND mask {mk}  OR graphic '
               f'{gr}  =  {rs}', fill=K.TEXT, font=small)
        d.text((20, yy + 20), ('the result equals the buffer the game left after this call (the trace): yes' if same
                               else 'MISMATCH with the trace'), fill=(90, 210, 110) if same else (255, 60, 60),
               font=tiny)
        y += h + 105
    d.text((20, H - 22), f'tools/ill_render.py blit --trace {rel(a.trace)} --out {rel(a.out)}', fill=K.DIM, font=tiny)
    out.save(a.out)
    print(a.out, out.size, [r[2] for r in rows])


# ---------------------------------------------------------------------------------------------------------------
# 06: every chassis with every weapon, from the game's sprites and tables

def blit(canvas, cw, m, sid, odd, xbyte, bottom):
    """DrawSprite's inner loop on a canvas of cw bytes a line (no clipping)"""
    at = V.word(m, V.SPRITE_TABLE + 4 * sid + 2 * odd)
    rows, width = m[at], m[at + 1]
    for r in range(rows):
        for b in range(width):
            p = (bottom - r) * cw + xbyte + b
            canvas[p] = (canvas[p] & m[at + 2 + 2 * (r * width + b)]) | m[at + 3 + 2 * (r * width + b)]
    return rows, width


def canvas_image(canvas, cw, scale):
    h = len(canvas) // cw
    im = Image.new('RGB', (cw * 8, h), PAPER)
    px = im.load()
    for y in range(h):
        for b in range(cw):
            v = canvas[y * cw + b]
            for bit in range(8):
                if v & 0x80 >> bit:
                    px[8 * b + bit, y] = INK
    return im.resize((cw * 8 * scale, h * scale), Image.NEAREST)


def robot_picture(m, parts, facing, scale, cw=5, ch=80):
    """DrawRobot $CEE8 on a canvas: the parts from bit 0 up, each PartHeights higher"""
    canvas = bytearray(cw * ch)
    direction = [1, 2, 4, 8].index(facing)
    h, bottom = 0, ch - 4
    used = []
    for part in range(8):
        if parts >> part & 1:
            sid = 0x16 + m[V.PART_SPRITES + 4 * part + direction]
            blit(canvas, cw, m, sid, 0, 1, bottom - h)
            used.append((part, sid, h))
            h += m[V.PART_HEIGHTS + part]
    return canvas_image(canvas, cw, scale), used, h


def fig_parts(a):
    m = open(a.image, 'rb').read()
    S = 3
    f, small, tiny = font(14), font(12), font(11)
    chassis = [0, 1, 2]
    columns = [('no weapon', 0), ('cannon', 1 << 3), ('missiles', 1 << 4), ('phasers', 1 << 5), ('nuclear', 1 << 6),
               ('electronics', 1 << 7), ('all of them', 0xF8)]
    pics = {}
    for c in chassis:
        for name, w in columns:
            pics[(c, name)] = robot_picture(m, (1 << c) | w, 4, S)
    pw, ph = pics[(0, 'no weapon')][0].size
    L, T = 130, 74
    cw = pw + 16
    W = L + len(columns) * cw + 20
    facings_h = ph + 60
    H = T + len(chassis) * (ph + 34) + facings_h + 120
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((20, 10), 'Robots: every chassis with every weapon, drawn as DrawRobot $CEE8 draws them (facing down, +$08 = 4)',
           fill=K.TEXT, font=f)
    d.text((20, 30), f'the part sprites $16 + PartSpriteTable[4 x part + direction] ($D6C8), each part PartHeights[part] '
           f'($D7B4) above the last; {rel(a.image)}, 3x', fill=K.DIM, font=small)
    for k, (name, w) in enumerate(columns):
        d.text((L + k * cw, T - 22), name, fill=(255, 200, 90), font=small)
    for r, c in enumerate(chassis):
        y = T + r * (ph + 34)
        d.text((20, y + ph // 2 - 20), PART_NAMES[c], fill=(255, 200, 90), font=small)
        d.text((20, y + ph // 2 - 2), f'bit {c}, h {m[V.PART_HEIGHTS + c]}', fill=K.DIM, font=tiny)
        for k, (name, w) in enumerate(columns):
            im, used, h = pics[(c, name)]
            out.paste(im, (L + k * cw, y))
            d.text((L + k * cw, y + ph + 2), f'+$07 ${(1 << c) | w:02X}, +$09 {h}', fill=K.DIM, font=tiny)
    # one robot in its four facings
    y = T + len(chassis) * (ph + 34) + 20
    parts = (1 << 1) | (1 << 3) | (1 << 7)
    d.text((20, y), f'tracks + cannon + electronics (+$07 ${parts:02X}) in its four facings: +$08 picks the sprites '
           '(direction = its lowest set bit)', fill=K.TEXT, font=small)
    for k, facing in enumerate((1, 2, 4, 8)):
        im, used, h = robot_picture(m, parts, facing, S)
        out.paste(im, (L + k * cw, y + 24))
        sids = ' '.join(f'${sid:02X}' for _, sid, _ in used)
        d.text((L + k * cw, y + 26 + ph), f'+$08 = {facing}, {FACING[facing]}', fill=K.DIM, font=tiny)
        d.text((L + k * cw, y + 40 + ph), sids, fill=K.DIM, font=tiny)
    d.text((20, y + 24 + ph // 2), 'facing', fill=(255, 200, 90), font=small)
    lx = L + 4 * cw + 10
    d.text((lx, y + 30), 'the parts stack from bit 0 up:', fill=K.TEXT, font=tiny)
    yy = y + 48
    for part in range(8):
        d.text((lx, yy), f'{part} {PART_NAMES[part]:12s} h {m[V.PART_HEIGHTS + part]:2d}  sprites '
               + ' '.join(f'${0x16 + m[V.PART_SPRITES + 4 * part + k]:02X}' for k in range(4)), fill=K.DIM, font=tiny)
        yy += 15
    d.text((20, H - 22), f'tools/ill_render.py parts --image {rel(a.image)} --out {rel(a.out)}', fill=K.DIM, font=tiny)
    out.save(a.out)
    print(a.out, out.size)


# ---------------------------------------------------------------------------------------------------------------
# 06: the draw order and the deferral, one view of the deep recording

def view_moment(rec, frame, last=36040):
    """the first DrawView call at or after frame, and the CopyViewToScreen that ends it"""
    starts = rec.executions(0xCCBD, last, 4000)
    copies = rec.executions(0xD071, last, 4000)
    s = next(x for x in starts if x[0] >= frame)
    return s, next(x for x in copies if x > s)


def fig_order(a):
    rec = Recording(a.work, a.cache, a.unreal)
    frames = [int(x) for x in a.frames.split(',')]
    (f, t), (cf, ct) = view_moment(rec, frames[0])
    m = rec.memory(f, t)
    game = rec.read(cf, V.VIEW, 3200, ct)
    mine, events, _ = V.draw_view(m)
    plain, _, _ = V.draw_view(m, defer=False)
    if mine != game:
        raise SystemExit('ill_view does not give the game\'s buffer here')
    view_x = view_of(m)
    S, PS = 3, 2
    f14, small, tiny, micro = font(14), font(12), font(11), font(9)
    pw, ph = 336 * PS, 272 * PS
    W = 20 + 160 * S + 30 + pw + 20
    H = 70 + max(160 * S, ph) + 900
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((20, 10), f'The draw order: DrawMapObjects $CCC6 over one view of work/deep (DrawView at {f}:{t}, '
           f'ViewX {view_x})', fill=K.TEXT, font=f14)
    d.text((20, 30), 'left: the buffer the game copied to the screen, each sprite numbered in drawing order; right: the '
           'occupied cells numbered in the order the walk reaches them', fill=K.DIM, font=small)
    out.paste(buffer_image(game, S), (20, 60))
    # the sprites, numbered at their anchor cell
    n, seen = 0, {}
    for e in events:
        if 'sprite' not in e:
            continue
        n += 1
        if not e['drawn']:
            continue
        key = (e['e'], e['d'])
        k = seen.get(key, 0)
        seen[key] = k + 1
        x, y = ground(e['e'] + 0.5, e['d'] + 0.5)
        x, y = 20 + x * S + 16 * k, 60 + (y - e['h']) * S - 6
        if e['kind'] == 'ship':
            y -= 10
        if not (20 <= x <= 20 + 160 * S and 60 <= y <= 60 + 160 * S):
            continue
        colour = (255, 60, 60) if e['kind'].startswith('robot') else SHIP if e['kind'] in ('ship', 'shadow') else (
            60, 120, 255) if e['kind'] == 'building' else (0, 150, 0)
        d.ellipse([x - 9, y - 9, x + 9, y + 9], fill=colour, outline=(0, 0, 0))
        d.text((x - (7 if n >= 10 else 3), y - 7), str(n), fill=(255, 255, 255), font=tiny)
    # the plan, cells numbered
    plan_im = plan(m, view_x, PS)
    pd = ImageDraw.Draw(plan_im)
    order = 0
    for e in events:
        if e['kind'] == 'cell':
            order += 1
            u, v = cell_xy(e['hl'])
            u -= view_x
            q = quad(u, v, PS)
            cx, cy = sum(p[0] for p in q) / 4, sum(p[1] for p in q) / 4
            draws = e['v'] & 0x1F and not e['v'] & 0x20 or e['v'] & 0xC0
            pd.text((cx - (6 if order >= 10 else 3) - (3 if order >= 100 else 0), cy - 5), str(order),
                    fill=(255, 255, 255) if draws else (150, 150, 160), font=micro, stroke_width=1,
                    stroke_fill=(0, 0, 0))
    for e in events:
        if e['kind'] in ('defer', 'ship_defer'):
            u0, v0 = cell_xy(e['hl'])
            u1, v1 = cell_xy(e['to'])
            q0, q1 = quad(u0 - view_x, v0, PS), quad(u1 - view_x, v1, PS)
            c0 = (sum(p[0] for p in q0) / 4, sum(p[1] for p in q0) / 4)
            c1 = (sum(p[0] for p in q1) / 4, sum(p[1] for p in q1) / 4)
            colour = (255, 60, 60) if e['kind'] == 'defer' else SHIP
            pd.polygon(q0, outline=colour, width=3)
            pd.polygon(q1, outline=colour, width=3)
            arrow(pd, c0, c1, colour, 3, 9)
    out.paste(plan_im, (20 + 160 * S + 30, 60))
    # the text: what was deferred
    y = 60 + max(160 * S, ph) + 10
    px = 20
    numbered = [e for e in events if 'sprite' in e]
    def numbers(pred):
        ks = [i + 1 for i, e in enumerate(numbered) if pred(e)]
        return f'{ks[0]}-{ks[-1]}' if len(ks) > 1 else str(ks[0]) if ks else '-'
    lines = []
    for e in events:
        if e['kind'] == 'defer':
            (x0, y0), (x1, y1) = cell_xy(e['hl']), cell_xy(e['to'])
            vis = any(x.get('drawn') for x in numbered if x['kind'].startswith(f'robot {e["slot"]} '))
            lines.append((f'red arrow: robot {e["slot"]} at ({x0},{y0}). FindLatestBlock finds the block anchored at '
                          f'({x1},{y1}), drawn later: bit 6 is set there,', (255, 90, 90)))
            lines.append((f'   +$00/+$01 points at it (MoverDefer $CE76). There the record goes back to its own cell, '
                          f'bit 6 is cleared and the robot drawn over the block', (255, 90, 90)))
            if not vis:
                lines.append(('   (this robot stands past the right edge of the view: its sprites are clipped away)',
                              (255, 90, 90)))
        if e['kind'] == 'ship_defer':
            (x0, y0), (x1, y1) = cell_xy(e['hl']), cell_xy(e['to'])
            lines.append((f'blue arrow: the ship at ({x0},{y0}). The object at ({x1},{y1}) is drawn later: bit 7 is '
                          f'set there and ShipDrawPos $FD11 keeps the ship\'s view column and row', SHIP))
            lines.append((f'   (ShipDefer $CD6F). There bit 7 is cleared and the ship is drawn at its own place after '
                          f'what stands there (robot sprites {numbers(lambda x: x["kind"].startswith("robot") and (x["e"], x["d"]) == (x1 - view_x, y1))}, '
                          f'the ship {numbers(lambda x: x["kind"] == "ship")})', SHIP))
    lines.append(('numbers: green blocks, blue buildings (the pad, the flag), red robot parts, light blue the shadow '
                  'and the ship.', K.DIM))
    lines.append(('The walk: diagonals x - y = 31 down to -15, each from row 0 down and right; grey cell numbers: '
                  'cells walked that draw nothing (bit 5, the rest of a block)', K.DIM))
    for text, colour in lines:
        d.text((px, y), text, fill=colour, font=small)
        y += 18
    if len(frames) > 1:
        (f2, t2), (cf2, ct2) = view_moment(rec, frames[1])
        m2 = rec.memory(f2, t2)
        game, _, _ = V.draw_view(m2)
        if game != rec.read(cf2, V.VIEW, 3200, ct2):
            raise SystemExit('ill_view does not give the game\'s buffer here')
        plain, _, _ = V.draw_view(m2, defer=False)
    diff = [i for i in range(3200) if game[i] != plain[i]]
    if diff:
        xs = [8 * (i % 20) for i in diff]
        ys = [i // 20 for i in diff]
        box = (max(0, min(xs) - 16), max(0, min(ys) - 16), min(160, max(xs) + 24), min(160, max(ys) + 16))
        y += 8
        d.text((px, y), f'what the deferral changes ({len(diff)} bytes), the view of {f2}:{t2} where the ship, low after '
               'the start, is deferred past the warbase block: the game,', fill=K.TEXT, font=small)
        d.text((px, y + 18), 'and the same view drawn with every object at its own cell (ill_view.py, deferral off): '
               'the block would cover part of the ship', fill=K.TEXT, font=small)
        y += 18
        y += 22
        cx = px
        for buf, label in ((game, 'the game (deferred)'), (plain, 'not deferred; red: where they differ')):
            crop = buffer_image(buf, 1).crop(box)
            crop = crop.resize((crop.width * 7, crop.height * 7), Image.NEAREST)
            cd = ImageDraw.Draw(crop)
            cd.rectangle([(min(xs) - box[0]) * 7 - 2, (min(ys) - box[1]) * 7 - 2, (max(xs) + 8 - box[0]) * 7 + 1,
                          (max(ys) + 1 - box[1]) * 7 + 1], outline=(255, 40, 40), width=2)
            out.paste(crop, (cx, y))
            d.text((cx, y + crop.height + 4), label, fill=K.DIM, font=tiny)
            cx += crop.width + 60
        y += (box[3] - box[1]) * 7 + 24
    out = out.crop((0, 0, W, y + 30))
    d = ImageDraw.Draw(out)
    d.text((20, out.height - 20), f'tools/ill_render.py order --work work/deep --frames {a.frames} --out {rel(a.out)}',
           fill=K.DIM, font=tiny)
    out.save(a.out)
    print(a.out, out.size)


# ---------------------------------------------------------------------------------------------------------------
# 06: the radar, its two layers and the blink

def bitmap16(data, scale, ink, paper):
    im = Image.new('RGB', (128, 16), paper)
    px = im.load()
    for y in range(16):
        for b in range(16):
            v = data[16 * y + b]
            for bit in range(8):
                if v & 0x80 >> bit:
                    px[8 * b + bit, y] = ink
    return im.resize((128 * scale, 16 * scale), Image.NEAREST)


def screen_radar(mem, scale):
    """the radar as the screen holds it: character rows 22-23, columns 6-21, with their attributes"""
    im = Image.new('RGB', (128, 16))
    px = im.load()
    for y in range(16):
        line = 176 + y
        for b in range(16):
            v = mem[K.screen_address(line, 6 + b)]
            attr = mem[0x5800 + (line >> 3) * 32 + 6 + b]
            ink, paper = K.ink_colour(attr & 7, attr & 0x40), K.ink_colour(attr >> 3 & 7, attr & 0x40)
            for bit in range(8):
                px[8 * b + bit, y] = ink if v & 0x80 >> bit else paper
    return im.resize((128 * scale, 16 * scale), Image.NEAREST)


def window_map(mem, left, scale):
    """map columns left..left+127, rows 0-15, top down, with the robots (2 x 2, by side) and the ship"""
    im = Image.new('RGB', (128 * scale, 16 * scale), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    for y in range(16):
        for x in range(128):
            c = mem[MAP + 0x200 * y + left + x]
            col = (150, 150, 160) if (c & 0x1F) >= 0x0F else (34, 34, 40)
            d.rectangle([x * scale, y * scale, x * scale + scale - 1, y * scale + scale - 1], fill=col)
    for i in range(48):
        r = mem[ROBOTS + 16 * i:ROBOTS + 16 * i + 16]
        x, y = (r[2] | r[3] << 8) - left, r[4]
        if r[1] and 0 <= x < 128:
            d.rectangle([x * scale, (y - 1) * scale, (x + 2) * scale - 1, (y + 1) * scale - 1],
                        fill=OURS if i < 24 else THEIRS)
    sx, sy = V.word(mem, V.SHIP_X) - left, mem[V.SHIP_Y]
    if 0 <= sx < 128:
        d.rectangle([sx * scale - 2, sy * scale - 2, sx * scale + scale + 1, sy * scale + scale + 1], outline=SHIP,
                    width=2)
    return im


def fig_radar(a):
    rec = Recording(a.work, a.cache, a.unreal)
    frames = list(range(a.frame, a.frame + a.count))
    S = 6
    f, small, tiny = font(14), font(12), font(11)
    W, H = 40 + 128 * S + 30, 670
    pictures, durations = [], []
    cyan, yellow, blue = K.ink_colour(5, True), K.ink_colour(6, True), K.ink_colour(1, True)
    for fr in frames:
        mem = rec.memory(fr)
        v = mem[VARS:VARS + 256]
        out = Image.new('RGB', (W, H), K.BACKGROUND)
        d = ImageDraw.Draw(out)
        d.text((40, 10), f'The radar, work/deep frame {fr} (one picture a frame, shown 5x slower)', fill=K.TEXT, font=f)
        attr = mem[0x5800 + 22 * 32 + 6]
        layer = 'RadarOwn $D800, attribute $4D' if attr == 0x4D else 'RadarEnemy $D900, attribute $4E' if attr == 0x4E \
            else f'attribute ${attr:02X}'
        d.text((40, 34), f'the screen at $50C6 (rows 22-23, columns 6-21) as this frame starts: {layer}',
               fill=K.TEXT, font=small)
        out.paste(screen_radar(mem, S), (40, 54))
        y = 54 + 16 * S + 14
        for k, (addr, name, ink) in enumerate(((RADAR_OWN, 'RadarOwn $D800: the terrain + our robots (cyan, $4D)', cyan),
                                               (RADAR_ENEMY, 'RadarEnemy $D900: the terrain + the enemy\'s robots '
                                                '(yellow, $4E)', yellow))):
            shown = (attr == 0x4D) == (k == 0)
            d.text((40, y), name + ('   <- on the screen this frame' if shown else ''), fill=ink if shown else K.DIM,
                   font=small)
            im = bitmap16(mem[addr:addr + 256], S, ink, blue)
            if not shown:
                im = Image.blend(im, Image.new('RGB', im.size, K.BACKGROUND), 0.55)
            out.paste(im, (40, y + 18))
            if shown:
                d.rectangle([37, y + 15, 40 + 128 * S + 2, y + 18 + 16 * S + 2], outline=ink, width=2)
            y += 18 + 16 * S + 12
        d.text((40, y), f'the map under the window, columns {v[0x1C]}-{v[0x1C] + 127} (RadarColumn $FD1C), rows 0-15: '
               'cell types $0F and more grey', fill=K.DIM, font=small)
        d.text((40, y + 16), '(the pixels of both layers), our robots green, the enemy\'s red (2 x 2), the ship\'s '
               'cell blue', fill=K.DIM, font=small)
        out.paste(window_map(mem, v[0x1C], S), (40, y + 36))
        y += 36 + 16 * S + 14
        own, enemy = mem[RADAR_OWN:RADAR_OWN + 256], mem[RADAR_ENEMY:RADAR_ENEMY + 256]
        d.text((40, y), f'RadarPhase $FD1A = {v[0x1A]}, RadarBlink $FD1E = ${v[0x1E]:02X} (bit 0: the ship\'s blip '
               f'{"in" if v[0x1E] & 1 else "not in"} $D800), TurnFrames $FD34 = {v[0x34]}', fill=K.TEXT, font=small)
        d.text((40, y + 20), f'{sum(bin(p ^ q).count("1") for p, q in zip(own, enemy))} pixels differ between the '
               'layers: the robots of each side and the ship\'s blip', fill=K.DIM, font=small)
        d.text((40, H - 24), f'tools/ill_render.py radar --work work/deep --frame {a.frame} --count {a.count} '
               f'--out {rel(a.out)}', fill=K.DIM, font=tiny)
        pictures.append(out)
        durations.append(100)
    durations[0] = 1500
    durations[-1] = 2000
    K.save_gif(a.out, pictures, durations)
    print(a.out, len(pictures), os.path.getsize(a.out))


# ---------------------------------------------------------------------------------------------------------------
# 06 / 07: the whole map

POINT_NAMES = ['warbase', 'electronics', 'nuclear', 'phasers', 'missiles', 'cannon', 'chassis']


def owner_colour(own):
    if own & 0x80:
        return (110, 110, 110)
    return THEIRS if own & 0x20 else OURS if own & 0x40 else NEUTRAL


def map_strip(mem, x0, n, cs, robots=True, labels=True, ship=True):
    """map columns x0..x0+n-1 top down, cs pixels a cell: terrain by class, 2 x 2 blocks outlined, the capture points
    by owner, buildings, robots, the ship"""
    im = Image.new('RGB', (n * cs, 16 * cs), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    for y in range(16):
        for x in range(n):
            c = mem[MAP + 0x200 * y + x0 + x]
            d.rectangle([x * cs, y * cs, x * cs + cs - 1, y * cs + cs - 1], fill=cell_colour(c))
    for y in range(16):
        for x in range(n):
            c = mem[MAP + 0x200 * y + x0 + x]
            if c & 0x1F and not c & 0x20 and c & 0x1F != 21:      # an anchor: its 2 x 2 footprint
                d.rectangle([x * cs, (y - 1) * cs, (x + 2) * cs - 1, (y + 1) * cs - 1], outline=(20, 20, 24))
    for i in range(56):
        r = mem[BUILDINGS + 3 * i:BUILDINGS + 3 * i + 3]
        if not r[1]:
            continue
        x, y = cell_xy(r[0] | r[1] << 8)
        if x0 <= x < x0 + n:
            X = (x - x0) * cs
            colour = OURS if r[2] in (0, 7) else THEIRS if r[2] == 8 else (250, 210, 80)
            d.polygon([(X + cs // 2, y * cs - 1), (X + cs, y * cs + cs // 2), (X + cs // 2, y * cs + cs),
                       (X - 1, y * cs + cs // 2)], fill=colour, outline=(0, 0, 0))
    for i in range(28):
        p = mem[POINTS + 5 * i:POINTS + 5 * i + 5]
        x, y, own = p[0] | p[1] << 8, p[2], p[3]
        if not x0 <= x < x0 + n:
            continue
        X = (x - x0) * cs
        colour = owner_colour(own)
        d.rectangle([X - 2, y * cs - 2, X + cs + 1, y * cs + cs + 1], outline=colour, width=2)
        if labels:
            letter = 'B' if i < 4 else POINT_LETTERS[own & 7]
            d.text((X + cs + 3, y * cs - 3), letter, fill=colour, font=font(11), stroke_width=2,
                   stroke_fill=(0, 0, 0))
    if robots:
        for i in range(48):
            r = mem[ROBOTS + 16 * i:ROBOTS + 16 * i + 16]
            x, y = r[2] | r[3] << 8, r[4]
            if r[1] and x0 <= x < x0 + n:
                X = (x - x0) * cs
                d.ellipse([X, (y - 1) * cs, X + 2 * cs - 1, (y + 1) * cs - 1], fill=OURS if i < 24 else THEIRS,
                          outline=(0, 0, 0))
    if ship:
        sx, sy = V.word(mem, V.SHIP_X), mem[V.SHIP_Y]
        if x0 <= sx < x0 + n:
            X = (sx - x0) * cs
            d.line([X - cs, sy * cs + cs // 2, X + 2 * cs, sy * cs + cs // 2], fill=SHIP, width=2)
            d.line([X + cs // 2, sy * cs - cs, X + cs // 2, sy * cs + 2 * cs], fill=SHIP, width=2)
    return im


def fig_worldmap(a):
    rec = Recording(a.work, a.cache, a.unreal)
    mem = rec.memory(a.frame)
    cs, n = 7, 128
    f, small, tiny = font(14), font(12), font(11)
    L = 46
    W = L + n * cs + 20
    strip_h = 16 * cs + 34
    H = 70 + 4 * strip_h + 125
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    v = mem[VARS:VARS + 256]
    d.text((L, 10), f'The map $DD00, 16 rows x 512 columns, at frame {a.frame} of work/deep (as BuildMap $BC6F '
           f'built it)', fill=K.TEXT, font=f)
    d.text((L, 30), f'four strips of 128 columns, row 0 at the top of each, {cs} pixels a cell; the view shows 32 '
           'columns of it at a time', fill=K.DIM, font=small)
    y = 60
    for k in range(4):
        x0 = k * n
        out.paste(map_strip(mem, x0, n, cs), (L, y))
        for c in range(0, n + 1, 16):
            d.line([L + c * cs, y + 16 * cs, L + c * cs, y + 16 * cs + 4], fill=K.DIM)
            if c < n:
                d.text((L + c * cs + 2, y + 16 * cs + 3), str(x0 + c), fill=K.DIM, font=tiny)
        for r in (0, 8, 15):
            d.text((L - 22, y + r * cs - 4), str(r), fill=K.DIM, font=tiny)
        y += strip_h
    legend(d, L, y, TERRAIN_LEGEND[:4], tiny, 12)
    legend(d, L, y + 18, TERRAIN_LEGEND[4:], tiny, 12)
    items = [(NEUTRAL, 'capture point, neutral'), (OURS, 'ours'), (THEIRS, 'the enemy\'s'),
             ((250, 210, 80), 'factory roof (building 1-6)'), (OURS, 'our pad / flag (0, 7)'),
             (THEIRS, 'enemy flag (8)')]
    legend(d, L, y + 36, items, tiny, 12)
    d.text((L, y + 58), 'capture points $FD70, a square on the door cell: B a warbase, E electronics, N nuclear, '
           'P phasers, M missiles, C cannon, W chassis', fill=K.DIM, font=tiny)
    d.text((L, y + 73), 'dark outlines: the 2 x 2 footprint of each block (from its anchor cell, bit 5 clear)',
           fill=K.DIM, font=tiny)
    d.text((L, y + 88), 'diamonds: the building records $FF01; the cross: the ship', fill=K.DIM, font=tiny)
    d.text((L, H - 22), f'tools/ill_render.py worldmap --work work/deep --frame {a.frame} --out {rel(a.out)}',
           fill=K.DIM, font=tiny)
    out.save(a.out)
    print(a.out, out.size)


# ---------------------------------------------------------------------------------------------------------------
# 06: the screen copy against the beam: a torn frame

PAPER_T, LINE_T = 14336, 224          # 48K: the first paper line's first byte, T-states a line


def fig_tear(a):
    t = load_trace(a.trace, a.unreal)
    ins = t.instructions
    ft = t.frame_t
    copy = next(i for i, x in enumerate(ins) if x.pc == 0xD071)
    start = bytes(t.memory_at(0))
    new = bytes(t.memory_at(copy))[V.VIEW:V.FONT]
    shown_frame = ins[copy].frame + 1
    # every screen write with the T-state of its write cycle, counted from the start of shown_frame
    writes = {}
    for x in ins[copy:]:
        for c in x.cycles:
            if c.tag == 'W' and 0x4000 <= c.address < 0x5800:
                frame, when = t.cycle_t(x, c)
                writes.setdefault(c.address, []).append(((frame - shown_frame) * ft + when, c.value))
    old = [[start[K.screen_address(8 + l, 1 + b)] for b in range(20)] for l in range(160)]
    shown = [[0] * 20 for _ in range(160)]
    tear, torn = None, 0          # the view line where the beam overtakes the copy, its bytes written in time
    for l in range(160):
        in_time = 0
        for b in range(20):
            addr = K.screen_address(8 + l, 1 + b)
            fetch = PAPER_T + LINE_T * (8 + l) + 4 * (1 + b)
            v = old[l][b]
            for when, value in writes.get(addr, []):
                if when <= fetch:
                    v = value
                    in_time += 1
            shown[l][b] = v
        if tear is None and in_time < 20:
            tear, torn = l, in_time
    flat = lambda rows: bytes(v for row in rows for v in row)
    S = 2
    f, small, tiny = font(14), font(12), font(11)
    PW = 160 * S + 30
    W, H = 20 + 3 * PW + 150, 78 + 160 * S + 124
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    cs = ins[copy]
    top = 64
    if tear is not None:
        d.text((20, 10), f'A torn frame: the beam overtakes the view copy at view line {tear} (screen line {8 + tear}): '
               f'frame {shown_frame} shows the new view above, the old below', fill=K.TEXT, font=f)
    d.text((20, 32), f'the view copy (CopyViewToScreen $D071) starts at {cs.frame}:{cs.t}, {ft - cs.t} T before the '
           f'frame ends; the beam overtakes it in frame {shown_frame} (work/deep)', fill=K.DIM, font=small)
    panels = [(flat(old), ['on the screen before the copy', '(the turn before was a menu: blank)']),
              (new, ['the new view: the buffer $5B00', '(what the copy writes)']),
              (flat(shown), [f'what the beam showed in frame {shown_frame}'])]
    for k, (buf, label) in enumerate(panels):
        x = 20 + k * PW
        out.paste(buffer_image(buf, S), (x, top))
        for j, line in enumerate(label):
            d.text((x, top + 160 * S + 6 + 15 * j), line, fill=K.TEXT if j == 0 else K.DIM, font=small)
    x = 20 + 2 * PW
    if tear is not None:
        y = top + (tear + 1) * S
        same = all(shown[tear][b] == new[20 * tear + b] for b in range(20))
        d.line([x - 4, y, x + 160 * S + 12, y], fill=(255, 40, 40), width=2)
        for j, line in enumerate([f'the tear: view line {tear}', f'(screen line {8 + tear}):', f'{torn} of its 20 bytes',
                                  'written in time, the', f'other {20 - torn} ' + (
                                      'the same in' if same else 'still old'), 'both views' if same else '']):
            d.text((x + 160 * S + 16, y - 16 + 15 * j), line, fill=(255, 40, 40), font=small)
        d.text((x, top + 160 * S + 22), f'lines 0-{tear}: new (copied before the beam came)', fill=K.DIM, font=tiny)
        d.text((x, top + 160 * S + 36), f'lines {tear + 1}-159: old (the beam came first)', fill=K.DIM, font=tiny)
    y = top + 160 * S + 64
    d.text((20, y), f'The copy writes a view line every ~468 T-states, the beam shows a screen line every {LINE_T}: '
           'the beam catches the copy up', fill=K.DIM, font=tiny)
    d.text((20, y + 14), 'when the copy starts in the last ~23 400 T of a frame or the first ~15 600; started '
           'between those, the copy stays ahead and the frame is whole.', fill=K.DIM, font=tiny)
    d.text((20, H - 22), f'tools/ill_render.py tear --trace {rel(a.trace)} --out {rel(a.out)}', fill=K.DIM,
           font=tiny)
    out.save(a.out)
    print(a.out, out.size, 'tear', tear)


# ---------------------------------------------------------------------------------------------------------------
# 07: a robot record over the screen it is drawn on

def fig_record(a):
    rec = Recording(a.work, a.cache, a.unreal)
    (f, t), (cf, ct) = view_moment(rec, a.frame)
    m = rec.memory(f, t)
    buf, events, _ = V.draw_view(m)
    scr = rec.memory(cf + 2)
    if any(scr[K.screen_address(8 + l, 1 + b)] != buf[20 * l + b] for l in range(160) for b in range(20)):
        raise SystemExit('the screen does not show the view drawn from these records')
    slot = a.slot
    r = m[ROBOTS + 16 * slot:ROBOTS + 16 * slot + 16]
    view_x = view_of(m)
    parts = [e for e in events if e['kind'].startswith(f'robot {slot} ')]
    Z = 8
    f14, small, tiny = font(14), font(12), font(11)
    x0 = min(8 * e['col'] for e in parts) - 20
    x1 = max(8 * (e['col'] + e['width']) for e in parts) + 20
    y0 = min(e['line'] - e['rows'] for e in parts) - 8
    y1 = max(e['line'] for e in parts) + 16
    IX, IY = 20, 60
    TX = IX + (x1 - x0) * Z + 60
    W = TX + 600
    H = max(IY + (y1 - y0) * Z, IY + 14 * 36 + 20 + 192 * 2 // 1 + 30) + 60
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    inset = buffer_image(buf, 1).crop((x0, y0, x1, y1)).resize(((x1 - x0) * Z, (y1 - y0) * Z), Image.NEAREST)
    out.paste(inset, (IX, IY))
    d = ImageDraw.Draw(out)
    x, y = r[2] | r[3] << 8, r[4]
    d.text((IX, 10), f'A robot record and what it means on the screen: slot {slot} (${ROBOTS + 16 * slot:04X}), '
           f'work/deep frame {cf + 2}', fill=K.TEXT, font=f14)
    d.text((IX, 30), f'left: the view around the robot, {Z}x; the record as DrawView {f}:{t} read it', fill=K.DIM,
           font=small)
    # the whole screen, small, with the inset's place
    sx0, sy0, ss = TX, IY + 14 * 36 + 16, 2
    out.paste(K.render_screen(scr).resize((256 * ss, 192 * ss), Image.NEAREST), (sx0, sy0))
    d.rectangle([sx0 + (8 + x0) * ss, sy0 + (8 + y0) * ss, sx0 + (8 + x1) * ss, sy0 + (8 + y1) * ss],
                outline=(255, 40, 40), width=2)
    d.text((sx0, sy0 + 192 * ss + 4), f'the screen after CopyViewToScreen (2x); red: the part shown left',
           fill=K.DIM, font=tiny)

    def sc(u, v, h=0):
        gx, gy = ground(u, v)
        return IX + (gx - x0) * Z, IY + (gy - h - y0) * Z

    S = Z
    SX, SY = IX - (8 + x0) * Z, IY - (8 + y0) * Z      # so that the part labels below use screen pixels
    u, v = x - view_x, y
    colours = {'cell': (90, 150, 250), 'pos': (70, 210, 220), 'move': (240, 200, 70), 'parts': (200, 110, 230),
               'state': (230, 90, 80), 'life': (90, 200, 120)}
    over = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    o = ImageDraw.Draw(over)
    o.polygon([sc(u, v - 1), sc(u + 2, v - 1), sc(u + 2, v + 1), sc(u, v + 1)], fill=(70, 210, 220, 0),
              outline=(70, 210, 220, 255), width=3)
    o.polygon([sc(u, v), sc(u + 1, v), sc(u + 1, v + 1), sc(u, v + 1)], fill=(90, 150, 250, 60),
              outline=(90, 150, 250, 255), width=4)
    out.paste(over, (0, 0), over)
    d = ImageDraw.Draw(out)
    centre = sc(u + 0.5, v + 0.5)
    step = {1: (1, 0), 2: (-1, 0), 4: (0, 1), 8: (0, -1)}[r[8]]
    head = sc(u + 0.5 + 1.4 * step[0], v + 0.5 + 1.4 * step[1])
    arrow(d, centre, head, (240, 200, 70), 4, 16)
    top = r[0x0D] + r[9]
    bx = sc(u + 2, v)[0] + 14
    by0, by1 = sc(u + 1, v + 1)[1], sc(u + 1, v + 1, top)[1]
    for yy in (by0, by1):
        d.line([bx - 8, yy, bx + 8, yy], fill=(200, 110, 230), width=3)
    d.line([bx, by0, bx, by1], fill=(200, 110, 230), width=3)
    d.text((bx + 10, (by0 + by1) // 2 - 7), f'{r[9]}', fill=(200, 110, 230), font=small, stroke_width=2,
           stroke_fill=(0, 0, 0))
    # the table
    rows = [
        ('+$00/+$01', f'{r[0]:02X} {r[1]:02X}', 'cell', f'the anchor cell ${r[0] | r[1] << 8:04X} = $DD00 + $200 x {y} + {x} '
                                                    '(bit 6 set there)'),
        ('+$02/+$03', f'{r[2]:02X} {r[3]:02X}', 'pos', f'X = {x} (map column; ViewX {view_x}: view column {u})'),
        ('+$04', f'{r[4]:02X}', 'pos', f'Y = {y} (map row); the 2 x 2 footprint (X..X+1, Y-1..Y)'),
        ('+$05', f'{r[5]:02X}', 'move', f'course: {FACING.get(r[5], "standing")}'),
        ('+$06', f'{r[6]:02X}', 'move', f'steps left on the course: {r[6]}'),
        ('+$07', f'{r[7]:02X}', 'parts', 'parts: ' + ' + '.join(PART_NAMES[p] for p in range(8) if r[7] >> p & 1)),
        ('+$08', f'{r[8]:02X}', 'move', f'facing: {FACING.get(r[8], "?")} -> picks the part sprites'),
        ('+$09', f'{r[9]:02X}', 'parts', f'height {r[9]} = the sum of PartHeights (the bracket)'),
        ('+$0A', f'{r[10]:02X}', 'state', 'control: ' + {0: 'the AI', 1: 'the player sits on it', 2: 'direct control',
                                                       0x80: 'the enemy\'s'}.get(r[10], '?')),
        ('+$0B', f'{r[11]:02X}', 'state', f'order: {ORDERS[r[11]] if r[11] < 9 else "?"}'),
        ('+$0C', f'{r[12]:02X}', 'life', f'strength {r[12]} (100 at birth)'),
        ('+$0D', f'{r[13]:02X}', 'parts', f'ground {r[13]}: the parts start this high'),
        ('+$0E', f'{r[14]:02X}', 'state', f'target: {r[14]}'),
        ('+$0F', f'{r[15]:02X}', 'move', f'delay: {r[15]} turns to the next step (StepDelays)'),
    ]
    ty = IY
    anchors = {}
    for off, val, kind, text in rows:
        c = colours[kind]
        d.rectangle([TX, ty, TX + 74, ty + 30], fill=tuple(k // 5 for k in c))
        d.text((TX + 4, ty + 2), off, fill=c, font=small)
        d.text((TX + 4, ty + 16), val, fill=K.TEXT, font=small)
        words, line, ly = text.split(), '', ty + 1
        for w_ in words:
            if d.textlength(line + ' ' + w_, font=tiny) > 460 and line:
                d.text((TX + 82, ly), line, fill=c, font=tiny)
                ly += 14
                line = w_
            else:
                line = (line + ' ' + w_).strip()
        d.text((TX + 82, ly), line, fill=c, font=tiny)
        anchors[off] = (TX - 4, ty + 15)
        ty += 36
    # the arrows from the fields to the screen
    def link(off, target, colour):
        a0 = anchors[off]
        d.line([a0, (a0[0] - 14, a0[1])], fill=colour, width=2)
        arrow(d, (a0[0] - 14, a0[1]), target, colour, 2, 10)

    link('+$00/+$01', sc(u + 0.5, v + 0.5), colours['cell'])
    link('+$04', sc(u + 1.6, v - 0.6), colours['pos'])
    link('+$08', head, colours['move'])
    link('+$09', (bx + 4, (by0 + by1) // 2), colours['parts'])
    link('+$0D', (bx + 4, by0), colours['parts'])
    for e in parts:
        p = int(e['kind'].split()[-1])
        py_ = IY + (e['line'] - e['h'] * 0 - y0) * Z - (e['line'] - (e['line'] - 1)) * Z
        lx = IX + 4
        d.text((lx, IY + (e['line'] - y0) * Z - 16), f'{PART_NAMES[p]} (bit {p}), from h {e["h"]}',
               fill=(255, 255, 255), font=small, stroke_width=2, stroke_fill=(0, 0, 0))
        d.line([lx, IY + (e['line'] - y0) * Z, IX + (8 * e['col'] - x0) * Z, IY + (e['line'] - y0) * Z],
               fill=(255, 255, 255), width=1)
    link('+$07', (IX + (8 * parts[-1]['col'] + 4 * parts[-1]['width'] - x0) * Z,
                  IY + (parts[-1]['line'] - parts[-1]['rows'] // 2 - y0) * Z), colours['parts'])
    d.text((IX, H - 40), 'blue: the anchor cell (+$00-$04), cyan: the 2 x 2 footprint, yellow arrow: the facing, '
           'purple bracket: the height, from +$0D up +$09; the white lines: each part\'s bottom line', fill=K.DIM,
           font=tiny)
    d.text((IX, H - 22), f'tools/ill_render.py record --work work/deep --frame {a.frame} --slot {slot} '
           f'--out {rel(a.out)}', fill=K.DIM, font=tiny)
    out.save(a.out)
    print(a.out, out.size)


# ---------------------------------------------------------------------------------------------------------------
# 07: the robots over the whole game

def terrain_strip(mem, x0, n, cs, dim=0.55):
    im = Image.new('RGB', (n * cs, 16 * cs), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    for y in range(16):
        for x in range(n):
            c = cell_colour(mem[MAP + 0x200 * y + x0 + x])
            d.rectangle([x * cs, y * cs, x * cs + cs - 1, y * cs + cs - 1], fill=tuple(int(k * dim) for k in c))
    return im


def fig_movie(a):
    rec = Recording(a.work, a.cache, a.unreal)
    frames = list(range(a.step, a.last + 1, a.step))
    cs, n = 4, 256
    L, T = 50, 56
    W = L + n * cs + 20
    strip = 16 * cs + 22
    H = T + 2 * strip + 150
    f, small, tiny = font(14), font(12), font(11)
    history, pictures, durations = [], [], []
    series = []
    for fr in frames:
        mem = rec.memory(fr)
        v = mem[VARS:VARS + 256]
        rb = mem[ROBOTS:ROBOTS + 768]
        ours = [(rb[16 * i + 2] | rb[16 * i + 3] << 8, rb[16 * i + 4]) for i in range(24) if rb[16 * i + 1]]
        theirs = [(rb[16 * i + 2] | rb[16 * i + 3] << 8, rb[16 * i + 4]) for i in range(24, 48) if rb[16 * i + 1]]
        pts = mem[POINTS:POINTS + 140]
        owners = [pts[5 * i + 3] for i in range(28)]
        series.append((fr, len(ours), len(theirs), sum(1 for o in owners[4:] if o & 0x40),
                       sum(1 for o in owners[4:] if o & 0x20)))
        history.append((ours, theirs))
        out = Image.new('RGB', (W, H), K.BACKGROUND)
        d = ImageDraw.Draw(out)
        day = v[0x37] | v[0x38] << 8
        d.text((L, 10), f'The deep recording: robots over the map, every {a.step} frames ({a.step / 50:.0f} s of play a '
               f'picture)', fill=K.TEXT, font=f)
        d.text((L, 30), f'frame {fr:5d}   day {day} {v[0x36]:02d}:{v[0x35]:02d}   robots: ours {len(ours):2d}, '
               f'the enemy\'s {len(theirs):2d}   factories: ours {series[-1][3]:2d}, the enemy\'s {series[-1][4]:2d}',
               fill=(255, 220, 120), font=small)
        for half in range(2):
            x0 = half * n
            y = T + half * strip
            im = terrain_strip(mem, x0, n, cs)
            dd = ImageDraw.Draw(im)
            for age, (o, t_) in enumerate(history[-6:-1]):
                k = (age + 1) / 6
                for side, pos in ((OURS, o), (THEIRS, t_)):
                    colour = tuple(int(c * k * 0.6) for c in side)
                    for x, yy in pos:
                        if x0 <= x < x0 + n:
                            X = (x - x0) * cs
                            dd.rectangle([X + 1, yy * cs - 2, X + cs + 2, yy * cs + cs - 1], fill=colour)
            for i in range(28):
                x, yy, own = pts[5 * i] | pts[5 * i + 1] << 8, pts[5 * i + 2], pts[5 * i + 3]
                if x0 <= x < x0 + n:
                    X = (x - x0) * cs
                    rr = 7 if i < 4 else 5
                    dd.rectangle([X - rr + 2, yy * cs - rr + 2, X + rr + 2, yy * cs + rr + 2], outline=owner_colour(own),
                                 width=2)
            for side, pos in ((OURS, ours), (THEIRS, theirs)):
                for x, yy in pos:
                    if x0 <= x < x0 + n:
                        X = (x - x0) * cs
                        dd.ellipse([X - 1, yy * cs - 3, X + cs + 3, yy * cs + cs + 1], fill=side, outline=(0, 0, 0))
            sx, sy = V.word(mem, V.SHIP_X), mem[V.SHIP_Y]
            if x0 <= sx < x0 + n:
                X = (sx - x0) * cs
                dd.line([X - 6, sy * cs + 2, X + 8, sy * cs + 2], fill=SHIP, width=2)
                dd.line([X + 1, sy * cs - 5, X + 1, sy * cs + 9], fill=SHIP, width=2)
            out.paste(im, (L, y))
            for c in range(0, n, 32):
                d.text((L + c * cs, y + 16 * cs + 3), str(x0 + c), fill=K.DIM, font=tiny)
        # the counts so far, under the maps
        gy, gh = T + 2 * strip + 14, 70
        d.rectangle([L, gy, L + n * cs, gy + gh], outline=(50, 50, 60))
        sx_ = n * cs / a.last
        for k, colour in ((1, OURS), (2, THEIRS)):
            pts_ = [(L + s_[0] * sx_, gy + gh - s_[k] * gh / 24) for s_ in series]
            if len(pts_) > 1:
                d.line(pts_, fill=colour, width=2)
        for k, colour in ((3, (140, 200, 140)), (4, (220, 140, 130))):
            pts_ = [(L + s_[0] * sx_, gy + gh - s_[k] * gh / 24) for s_ in series]
            if len(pts_) > 1:
                d.line(pts_, fill=colour, width=1)
        d.line([L + fr * sx_, gy, L + fr * sx_, gy + gh], fill=(255, 255, 255))
        legend(d, L, gy + gh + 6, [(OURS, 'our robots'), (THEIRS, 'the enemy\'s robots'),
                                   ((140, 200, 140), 'our factories'), ((220, 140, 130), 'the enemy\'s factories'),
                                   (NEUTRAL, 'neutral point'), (SHIP, 'the ship')], tiny, 14)
        d.text((L, gy + gh + 24), 'squares: capture points by owner (big: warbases); dots: robots ($DA00, +$02-$04), '
               'with their last 5 places fading; counts out of 24', fill=K.DIM, font=tiny)
        d.text((L, H - 20), f'tools/ill_render.py movie --work work/deep --step {a.step} --out {rel(a.out)}',
               fill=K.DIM, font=tiny)
        pictures.append(out)
        durations.append(120)
    durations[0] = 1500
    durations[-1] = 4000
    K.save_gif(a.out, pictures, durations)
    print(a.out, len(pictures), os.path.getsize(a.out), 'peak', max(s_[1] for s_ in series), max(s_[2] for s_ in series))


# ---------------------------------------------------------------------------------------------------------------
# 07: who holds what, day by day

def fig_days(a):
    rec = Recording(a.work, a.cache, a.unreal)
    frames = list(range(a.step, a.last + 1, a.step))
    by_day = {}
    for fr in frames:
        v = rec.read(fr, VARS, 256)
        by_day[v[0x37] | v[0x38] << 8] = fr            # the last sample of each day
    days = sorted(by_day)
    cs = 2
    L, T = 120, 70
    strip = 16 * cs + 18
    W = L + 512 * cs + 190
    H = T + len(days) * strip + 110
    f, small, tiny = font(14), font(12), font(11)
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((20, 10), f'Who holds what, day by day: the capture points $FD70 and the robots at the last sample of each '
           f'day (work/deep, every {a.step} frames)', fill=K.TEXT, font=f)
    d.text((20, 30), 'the whole map, 512 columns x 16 rows, 2 pixels a cell; squares: capture points in the owner\'s '
           'colour (big: warbases), white ring: changed hands that day; dots: robots', fill=K.DIM, font=small)
    for c in range(0, 512, 64):
        d.text((L + c * cs, T - 16), str(c), fill=K.DIM, font=tiny)
    prev = None
    for k, day in enumerate(days):
        fr = by_day[day]
        mem = rec.memory(fr)
        v = mem[VARS:VARS + 256]
        y = T + k * strip
        im = terrain_strip(mem, 0, 512, cs, 0.5)
        dd = ImageDraw.Draw(im)
        pts = mem[POINTS:POINTS + 140]
        owners = [pts[5 * i + 3] for i in range(28)]
        for i in range(48):
            r = mem[ROBOTS + 16 * i:ROBOTS + 16 * i + 16]
            if r[1]:
                x, yy = r[2] | r[3] << 8, r[4]
                dd.ellipse([x * cs - 2, yy * cs - 2, x * cs + 3, yy * cs + 3], fill=OURS if i < 24 else THEIRS)
        out.paste(im, (L, y))
        for i in range(28):
            x, yy = pts[5 * i] | pts[5 * i + 1] << 8, pts[5 * i + 2]
            X, Y = L + x * cs, y + yy * cs
            rr = 6 if i < 4 else 4
            d.rectangle([X - rr, Y - rr, X + rr, Y + rr], fill=owner_colour(owners[i]), outline=(0, 0, 0))
            if prev is not None and (prev[i] & 0x60) != (owners[i] & 0x60):
                d.ellipse([X - rr - 5, Y - rr - 5, X + rr + 5, Y + rr + 5], outline=(255, 255, 255), width=2)
        d.text((20, y + 4), f'day {day}', fill=K.TEXT, font=small)
        d.text((20, y + 20), f'frame {fr}', fill=K.DIM, font=tiny)
        ours_f = sum(1 for o in owners[4:] if o & 0x40)
        theirs_f = sum(1 for o in owners[4:] if o & 0x20)
        rb = mem[ROBOTS:ROBOTS + 768]
        d.text((L + 512 * cs + 12, y + 2), f'factories {ours_f:2d} : {theirs_f:2d}', fill=K.TEXT, font=tiny)
        d.text((L + 512 * cs + 12, y + 17), f'robots    {sum(1 for i in range(24) if rb[16 * i + 1]):2d} : '
               f'{sum(1 for i in range(24, 48) if rb[16 * i + 1]):2d}', fill=K.DIM, font=tiny)
        prev = owners
    y = T + len(days) * strip + 6
    d.text((L + 512 * cs + 12, T - 16), 'ours : the enemy\'s', fill=K.DIM, font=tiny)
    legend(d, L, y, [(OURS, 'ours'), (THEIRS, 'the enemy\'s'), (NEUTRAL, 'neutral')], tiny, 14)
    d.text((L, y + 20), 'a point changes hands when a robot stands 144 turns on its door (CaptureLoop $ADB7); the '
           'enemy, with three warbases, takes the east half', fill=K.DIM, font=tiny)
    d.text((20, H - 22), f'tools/ill_render.py days --work work/deep --step {a.step} --out {rel(a.out)}', fill=K.DIM,
           font=tiny)
    out.save(a.out)
    print(a.out, out.size, days)


# ---------------------------------------------------------------------------------------------------------------
# 07: a fight, shot by shot

SOUND = {1: 'fire', 0xFC: 'a miss', 0xFA: 'a hit', 0xC8: 'a robot destroyed'}
WEAPONS = {1: 'cannon', 2: 'missiles', 3: 'phasers'}


def view_at(mem, view_x):
    """the memory with the view moved to view_x (ViewX, MapView), as if the ship had flown there; the ship itself
    stays where it is (off this view)"""
    m = bytearray(mem)
    m[0xFD0A], m[0xFD0B] = view_x & 0xFF, view_x >> 8
    mv = MAP + view_x
    m[V.MAP_VIEW], m[V.MAP_VIEW + 1] = mv & 0xFF, mv >> 8
    return bytes(m)


def fig_fight(a):
    rec = Recording(a.work, a.cache, a.unreal)
    f0, f1 = [int(x) for x in a.frames.split(',')]
    slots = [int(x) for x in a.slots.split(',')]
    frames = list(range(f0, f1 + 1, 2))
    S = 3
    f, small, tiny = font(14), font(12), font(11)
    TX = 20 + 160 * S + 30
    W, H = TX + 520, 60 + 160 * S + 160
    pictures, durations = [], []
    strength_log = {s_: [] for s_ in slots}
    trail = []
    for fr in frames:
        mem = rec.memory(fr)
        buf, events, _ = V.draw_view(view_at(mem, a.view_x))
        if any(e['kind'] in ('shadow', 'ship') and e['drawn'] for e in events):
            raise SystemExit('the ship is in this view: pick another --view-x')
        out = Image.new('RGB', (W, H), K.BACKGROUND)
        d = ImageDraw.Draw(out)
        v = mem[VARS:VARS + 256]
        d.text((20, 10), f'A fight in work/deep, frame {fr}: robots {slots[0]} (ours) and {slots[1]} (the enemy\'s) '
               f'shoot along map column 123', fill=K.TEXT, font=f)
        d.text((20, 30), f'the view at ViewX {a.view_x} drawn by tools/ill_view.py from the memory of this frame (the '
               f'game\'s camera was at the warbase), 3x', fill=K.DIM, font=small)
        out.paste(buffer_image(buf, S), (20, 60))
        sh = mem[SHOTS:SHOTS + 45]
        for e in events:
            if e['kind'] == 'shot' and e['drawn']:
                x0, y0, x1, y1 = sprite_box(e, S)
                d.rectangle([20 + max(0, x0) - 2, 60 + max(0, y0) - 2, 20 + x1 + 1, 60 + y1 + 1],
                            outline=(255, 40, 40), width=2)
        for s_ in slots:
            r = mem[ROBOTS + 16 * s_:ROBOTS + 16 * s_ + 16]
            if not r[1]:
                continue
            u, vv = (r[2] | r[3] << 8) - a.view_x, r[4]
            gx, gy = ground(u + 1, vv)
            colour = OURS if s_ < 24 else THEIRS
            st = r[12] if r[12] < 0x80 else r[12] - 256
            d.text((20 + gx * S + 30, 60 + (gy - 10) * S), f'{s_}: {st}', fill=colour, font=small, stroke_width=2,
                   stroke_fill=(0, 0, 0))
            strength_log[s_].append((fr, st))
        # the shot records
        y = 60
        d.text((TX, y), 'Shots $D7D3: 0 COMBAT MODE, 1-2 ours, 3-4 the enemy\'s', fill=K.TEXT,
               font=small)
        y += 20
        d.text((TX, y), '     +00 +01 +02 +03 +04 +05 +06 +07 +08', fill=K.DIM, font=tiny)
        y += 16
        for i in range(5):
            rr = sh[9 * i:9 * i + 9]
            live = rr[1] != 0
            colour = (OURS if i in (1, 2) else THEIRS if i in (3, 4) else SHIP) if live else (80, 80, 90)
            d.text((TX, y), f'{i}: ' + ' '.join(f'{b_:02X} ' for b_ in rr), fill=colour, font=tiny)
            if live:
                d.text((TX + 330, y), f'({rr[2] | rr[3] << 8},{rr[4]}) {WEAPONS.get(rr[7], "?")}, '
                       f'{FACING.get(rr[5], "?").split()[0]}, {rr[6]} steps', fill=colour, font=tiny)
                trail.append((fr, i, rr[2] | rr[3] << 8, rr[4]))
            else:
                d.text((TX + 330, y), 'free (+$01 = 0)', fill=(80, 80, 90), font=tiny)
            y += 16
        y += 10
        fx = v[0x53]
        d.text((TX, y), f'SoundFx $FD53 = ${fx:02X}' + (f': {SOUND[fx]}' if fx in SOUND else
                                                 ' (counted up by PlayInterrupt)' if fx else ''), fill=K.TEXT,
               font=small)
        y += 26
        # strength over the window
        d.text((TX, y), 'strength +$0C of the two robots', fill=K.TEXT, font=small)
        gy0, gh, gw = y + 20, 100, 480
        d.rectangle([TX, gy0, TX + gw, gy0 + gh], outline=(50, 50, 60))
        for lvl in (25, 50, 75):
            d.line([TX, gy0 + gh - lvl, TX + gw, gy0 + gh - lvl], fill=(35, 35, 45))
        for s_ in slots:
            pts = [(TX + (fr_ - f0) * gw / (f1 - f0), gy0 + gh - max(0, st)) for fr_, st in strength_log[s_]]
            if len(pts) > 1:
                d.line(pts, fill=OURS if s_ < 24 else THEIRS, width=2)
        d.text((TX, gy0 + gh + 4), f'{f0}', fill=K.DIM, font=tiny)
        d.text((TX + gw - 40, gy0 + gh + 4), f'{f1}', fill=K.DIM, font=tiny)
        y = gy0 + gh + 26
        # the top-down strip of the column: the shots' cells so far
        d.text((TX, y), f'map columns {a.view_x + 10}-{a.view_x + 26}, rows 0-15, top down; the shots\' cells so far',
               fill=K.TEXT, font=small)
        cs = 14
        im = terrain_strip(mem, a.view_x + 10, 17, cs, 0.6)
        dd = ImageDraw.Draw(im)
        for fr_, i, x, yy in trail:
            X = (x - a.view_x - 10) * cs
            colour = OURS if i in (1, 2) else THEIRS
            dd.ellipse([X + 4, yy * cs + 4, X + cs - 4, yy * cs + cs - 4], outline=colour, width=2)
        for s_ in slots:
            r = mem[ROBOTS + 16 * s_:ROBOTS + 16 * s_ + 16]
            if r[1]:
                X = ((r[2] | r[3] << 8) - a.view_x - 10) * cs
                dd.rectangle([X, (r[4] - 1) * cs, X + 2 * cs - 1, (r[4] + 1) * cs - 1], outline=OURS if s_ < 24
                             else THEIRS, width=3)
        im = im.rotate(0)
        out.paste(im, (TX, y + 20))
        d.text((20, H - 66), 'red boxes: the shot sprites, $2B + 2 x weapon + 1 flying along y: here the missile $30 and the cannon '
               'shell $2E, at height +$08 = 10', fill=K.DIM, font=tiny)
        d.text((20, H - 48), 'a shot flies 2 cells a turn (MoveShot $B724) and hits a robot anchored in '
               'the 3 x 3 cells round it: ((60 - (height + ground)) / 4) x (weapon + 1)', fill=K.DIM, font=tiny)
        d.text((20, H - 22), f'tools/ill_render.py fight --work work/deep --frames {a.frames} --slots {a.slots} '
               f'--view-x {a.view_x} --out {rel(a.out)}', fill=K.DIM, font=tiny)
        pictures.append(out)
        durations.append(110)
    durations[0] = 1500
    durations[-1] = 3000
    K.save_gif(a.out, pictures, durations)
    print(a.out, len(pictures), os.path.getsize(a.out))


# ---------------------------------------------------------------------------------------------------------------
# 07: the cell bits of a real region, layer by layer

def bit_layer(mem, x0, n, cs, test, colour, dim=0.3):
    """the terrain dimmed, the cells where test(byte) holds filled with colour"""
    im = terrain_strip(mem, x0, n, cs, dim)
    d = ImageDraw.Draw(im)
    for y in range(16):
        for x in range(n):
            c = mem[MAP + 0x200 * y + x0 + x]
            fill = test(c)
            if fill:
                d.rectangle([x * cs + 1, y * cs + 1, x * cs + cs - 2, y * cs + cs - 2],
                            fill=fill if isinstance(fill, tuple) else colour)
    return im


def object_names(mem):
    """cell -> what has its anchor there: robots, buildings, live shots"""
    names = {}
    for i in range(48):
        r = mem[ROBOTS + 16 * i:ROBOTS + 16 * i + 16]
        if r[1]:
            names[(r[2] | r[3] << 8, r[4])] = f'robot {i}'
    for i in range(56):
        r = mem[BUILDINGS + 3 * i:BUILDINGS + 3 * i + 3]
        if r[1]:
            names.setdefault(cell_xy(r[0] | r[1] << 8), f'building {i}')
    for i in range(5):
        r = mem[SHOTS + 9 * i:SHOTS + 9 * i + 9]
        if r[1]:
            names.setdefault((r[2] | r[3] << 8, r[4]), f'shot {i}')
    return names


def fig_bits(a):
    rec = Recording(a.work, a.cache, a.unreal)
    mem = rec.memory(a.frame)
    x0, n = a.left, 32
    f, small, tiny = font(14), font(12), font(11)
    names = object_names(mem)
    CS, cs = 18, 9
    L = 30
    lw = n * cs + 24
    W = max(L + n * CS + 40 + 470, L + 4 * lw)
    top = 60
    H = 1200
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((L, 10), f'The cell bits of map columns {x0}-{x0 + n - 1} at frame {a.frame} of work/deep: cell (x, y) = '
           f'$DD00 + $200 x y + x', fill=K.TEXT, font=f)
    d.text((L, 30), 'top: the composite (terrain, 2 x 2 blocks, buildings, capture points, robots, the ship) and the '
           'bytes of the boxed window; bottom: one layer a bit field', fill=K.DIM, font=small)
    out.paste(map_strip(mem, x0, n, CS), (L, top))
    for c in range(0, n + 1, 4):
        d.text((L + c * CS + 2, top + 16 * CS + 2), str(x0 + c), fill=K.DIM, font=tiny)
    for r in range(0, 16, 3):
        d.text((L - 20, top + r * CS + 3), str(r), fill=K.DIM, font=tiny)
    # the hex window round the ship
    hx, hy, hw, hh = a.hex_left, a.hex_top, 12, 9
    d.rectangle([L + (hx - x0) * CS - 1, top + hy * CS - 1, L + (hx - x0 + hw) * CS, top + (hy + hh) * CS],
                outline=(255, 255, 255), width=2)
    X = L + n * CS + 40
    d.text((X, top), f'bytes of columns {hx}-{hx + hw - 1}, rows {hy}-{hy + hh - 1}', fill=K.TEXT, font=small)
    d.text((X, top + 18), '    ' + ''.join(f'{(hx + i) % 1000:>4}' for i in range(hw)), fill=K.DIM, font=tiny)
    for j in range(hh):
        y = top + 36 + 18 * j
        d.text((X, y), f'{hy + j:>3}', fill=K.DIM, font=tiny)
        for i in range(hw):
            c = mem[MAP + 0x200 * (hy + j) + hx + i]
            colour = SHIP if c & 0x80 else (255, 90, 90) if c & 0x40 else (120, 120, 130) if c & 0x20 else \
                (240, 200, 90) if c & 0x1F else (70, 70, 80)
            d.text((X + 32 + 28 * i, y), f'{c:02X}', fill=colour, font=tiny)
    y = top + 36 + 18 * hh + 8
    for colour, text in [(SHIP, 'bit 7 set: the ship'), ((255, 90, 90), 'bit 6 set: an object\'s anchor'),
                         ((120, 120, 130), 'bit 5 set: a block cell, not its anchor'),
                         ((240, 200, 90), 'a block anchor (type in bits 0-4, bit 5 clear)'),
                         ((70, 70, 80), '00: flat ground')]:
        legend(d, X, y, [(colour, text)], small)
        y += 17
    y += 8
    marked = sorted((k, v_) for k, v_ in names.items() if hx <= k[0] < hx + hw and hy <= k[1] < hy + hh)
    for (cx, cy), what in marked:
        c = mem[MAP + 0x200 * cy + cx]
        d.text((X, y), f'({cx}, {cy}) = ${c:02X}: {what}', fill=K.TEXT, font=tiny)
        y += 15
    sx, sy = V.word(mem, V.SHIP_X), mem[V.SHIP_Y]
    d.text((X, y), f'({sx}, {sy}) = ${mem[MAP + 0x200 * sy + sx]:02X}: the ship (ShipX $FD0E, ShipY $FD0D)', fill=SHIP,
           font=tiny)
    # the four layers
    ly = max(top + 16 * CS + 30, y + 30)
    layers = [
        ('bits 0-4: the block type', lambda c: cell_colour(c & 0x1F) if c & 0x1F else None, None),
        ('bit 5: not the anchor', lambda c: bool(c & 0x20), (150, 150, 160)),
        ('bit 6: an object\'s anchor', lambda c: bool(c & 0x40), (255, 90, 90)),
        ('bit 7: the ship', lambda c: bool(c & 0x80), SHIP),
    ]
    for k, (title, test, colour) in enumerate(layers):
        lx = L + k * lw
        d.text((lx, ly), title, fill=K.TEXT, font=small)
        out.paste(bit_layer(mem, x0, n, cs, test, colour, 0.25 if k else 0.0), (lx, ly + 18))
    counts = [sum(1 for y_ in range(16) for x_ in range(n) if mem[MAP + 0x200 * y_ + x0 + x_] & bit)
              for bit in (0x20, 0x40, 0x80)]
    d.text((L, ly + 18 + 16 * cs + 6), f'in these 512 cells: {counts[0]} with bit 5, {counts[1]} with bit 6, '
           f'{counts[2]} with bit 7; over the whole map {sum(1 for i in range(8192) if mem[MAP + i] & 0x40)} with '
           f'bit 6 (robots + buildings + flying shots)', fill=K.DIM, font=small)
    legend(d, L, ly + 18 + 16 * cs + 26, TERRAIN_LEGEND, tiny, 15)
    H = ly + 18 + 16 * cs + 80
    out = out.crop((0, 0, W, H))
    d = ImageDraw.Draw(out)
    d.text((L, H - 22), f'tools/ill_render.py bits --work work/deep --frame {a.frame} --left {x0} --hex-left {hx} '
           f'--hex-top {hy} --out {rel(a.out)}', fill=K.DIM, font=tiny)
    out.save(a.out)
    print(a.out)


# ---------------------------------------------------------------------------------------------------------------

def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('what')
    p.add_argument('--out')
    p.add_argument('--trace')
    p.add_argument('--work')
    p.add_argument('--image')
    p.add_argument('--frame', type=int)
    p.add_argument('--frames')
    p.add_argument('--step', type=int, default=100)
    p.add_argument('--views', type=int, default=60)
    p.add_argument('--count', type=int, default=40)
    p.add_argument('--slot', type=int, default=0)
    p.add_argument('--slots', default='2,25')
    p.add_argument('--view-x', type=int, default=105)
    p.add_argument('--left', type=int, default=12)
    p.add_argument('--hex-left', type=int, default=16)
    p.add_argument('--hex-top', type=int, default=2)
    p.add_argument('--last', type=int, default=36040)
    p.add_argument('--cache', default=os.path.join(CASE, 'work', 'ill2', 'cache'))
    p.add_argument('--unreal')
    a = p.parse_args()
    globals()['fig_' + a.what](a)


if __name__ == '__main__':
    main()
