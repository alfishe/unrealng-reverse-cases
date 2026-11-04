#!/usr/bin/env python3
"""The figures of docs 06 and 07 that are not routine animations or writer maps: drawn from the memory of a
recording (TTD memory_at in the unreal-ng instance that holds it, read only) or from the start image.

    python3 tools/doc_figures.py sprite  --image work/deep/start.bin --out docs/img/sprite-format.png
    python3 tools/doc_figures.py areas   --work work/docB/rec --frame 2000 --out docs/img/screen-areas.png
    python3 tools/doc_figures.py robots  --work work/deep --step 250 --out work/figs/robots-raw.png  # doc 07 uses tools/fig_robots_time.py
    python3 tools/doc_figures.py map     --work work/deep --frames 200,36000 --out work/figs/map-owners.png  # not in the docs
    python3 tools/doc_figures.py records --work work/deep --frame 20000 --out docs/img/robot-records.png

`--cache FILE` keeps the memory_at answers (JSON), so a figure is redrawn without the instance.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

MAP, ROBOTS, BUILDINGS, POINTS, VARS = 0xDD00, 0xDA00, 0xFF01, 0xFD70, 0xFD00
SPRITE_TABLE = 0xD6E8
OURS, THEIRS, NEUTRAL = (90, 210, 110), (235, 85, 80), (200, 200, 210)


class Memory:
    """memory_at of a recording, cached"""

    def __init__(self, work, unreal=None, cache=None):
        self.work, self.unreal, self.cache_path = work, unreal, cache
        self.cache = json.load(open(cache)) if cache and os.path.isfile(cache) else {}
        self.session = None

    def read(self, frame, address, length):
        key = f'{frame}:{address:04X}:{length}'
        if key not in self.cache:
            if self.session is None:
                sys.path.insert(0, os.path.join(K.unreal_root(self.unreal), 'tools', 'verification', 'analysis'))
                import re_session  # noqa: E402
                self.session, _ = re_session.session_of(self.work)
            r = self.session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame,
                                                  'offset': address, 'length': length}, ok=False)
            st = r.structured or {}
            if r.is_error or not st.get('exact'):
                raise SystemExit(f'memory_at {key}: {r.text}')
            self.cache[key] = st['hex']
        return bytes.fromhex(self.cache[key])

    def save(self):
        if self.cache_path:
            json.dump(self.cache, open(self.cache_path, 'w'))


# ---------------------------------------------------------------------------------------------------------------
# sprite format

def sprite(image, sid, odd):
    entry = SPRITE_TABLE + 4 * sid + 2 * odd
    at = image[entry] | image[entry + 1] << 8
    rows, width = image[at], image[at + 1]
    return at, rows, width, image[at + 2:at + 2 + 2 * rows * width]


def sprite_picture(rows, width, data, scale, mode):
    """mode mask / graphic / result (on a dotted ground); top line first"""
    im = Image.new('RGB', (width * 8 * scale, rows * scale), K.PANEL)
    px = ImageDraw.Draw(im)
    for r in range(rows):
        y = (rows - 1 - r) * scale
        for b in range(width):
            mask, graphic = data[2 * (r * width + b)], data[2 * (r * width + b) + 1]
            for bit in range(8):
                m, g = mask >> (7 - bit) & 1, graphic >> (7 - bit) & 1
                x = (b * 8 + bit) * scale
                ground = (110, 110, 60) if (b * 8 + bit + r) % 2 else (70, 70, 40)
                if mode == 'mask':
                    c = (230, 230, 230) if m else (40, 40, 48)
                elif mode == 'graphic':
                    c = (250, 240, 120) if g else (40, 40, 48)
                else:
                    c = (250, 240, 120) if g else (ground if m else (20, 20, 24))
                px.rectangle([x, y, x + scale - 1, y + scale - 1], fill=c)
    return im


def fig_sprite(args):
    image = open(args.image, 'rb').read()
    f, small = K.font(13), K.font(11)
    sid = 27  # the cannon facing X+
    parts = []
    for odd in (0, 1):
        parts.append(sprite(image, sid, odd))
    scale = 6
    W = 1500
    pics = [sprite_picture(p[1], p[2], p[3], scale, m) for p in parts[:1] for m in ('mask', 'graphic', 'result')]
    pics.append(sprite_picture(parts[1][1], parts[1][2], parts[1][3], scale, 'result'))
    H = 40 + max(p.height for p in pics) + 40 + 18 * 9 + 20
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((12, 8), f'Sprite 27, the cannon facing X+: SpriteTable ${SPRITE_TABLE + 4 * sid:04X} -> '
           f'${parts[0][0]:04X} (even column), ${SPRITE_TABLE + 4 * sid + 2:04X} -> ${parts[1][0]:04X} (odd column, '
           f'shifted 4 pixels); work/deep/start.bin', fill=K.TEXT, font=f)
    x = 12
    labels = [f'mask ({parts[0][1]} x {parts[0][2]} bytes)', 'graphic', '(ground AND mask) OR graphic',
              f'odd block ({parts[1][1]} x {parts[1][2]})']
    for p, label in zip(pics, labels):
        d.text((x, 34), label, fill=K.DIM, font=small)
        out.paste(p, (x, 52))
        x += max(p.width, 220) + 30
    # the bytes as stored: header, then rows from the bottom line, pairs (mask, graphic)
    at, rows, width, data = parts[0]
    y = 52 + max(p.height for p in pics) + 20
    d.text((12, y), f'${at:04X}: {rows:02X} {width:02X}   (lines, bytes a line), then the lines from the BOTTOM up, '
           f'each {width} pairs (mask, graphic):', fill=K.TEXT, font=f)
    for r in range(8):
        offs = at + 2 + 2 * r * width
        pairs = '   '.join(f'{data[2 * (r * width + b)]:02X} {data[2 * (r * width + b) + 1]:02X}' for b in range(width))
        what = 'the bottom line' if r == 0 else ('... up to line %d, the top' % (rows - 1) if r == 7 else '')
        d.text((12, y + 20 + 18 * r), f'${offs:04X}  line {r:2d}:  {pairs}    {what}', fill=K.DIM, font=f)
    out.save(args.out)
    print(args.out, out.size)


# ---------------------------------------------------------------------------------------------------------------
# the play screen and its areas

def fig_areas(args):
    m = Memory(args.work, args.unreal, args.cache)
    scr = m.read(args.frame, 0x4000, 6912)
    m.save()
    s = 3
    im = K.render_screen(scr, 0).resize((256 * s, 192 * s), Image.NEAREST)
    pad = 300
    out = Image.new('RGB', (im.width + pad, im.height + 30), K.BACKGROUND)
    out.paste(im, (0, 30))
    d = ImageDraw.Draw(out)
    f = K.font(13)
    d.text((8, 6), f'The play screen, recording work/docB/rec frame {args.frame} (character cells: column, row)',
           fill=K.TEXT, font=f)
    areas = [
        ((1, 1, 20, 20), (255, 80, 200), 'view: ViewBuffer $5B00 copied to (1,1), 20 x 20 cells (CopyViewToScreen)'),
        ((0, 0, 22, 22), (255, 160, 40), 'frame: 22 x 22 cells, attribute $78; view $70 (DrawPlayScreen)'),
        ((22, 0, 10, 2), (80, 200, 255), 'DAY / TIME (0,22), the clock (GameTurn)'),
        ((22, 2, 10, 20), (120, 255, 120), 'right panel: STATUS + RESOURCES, or a robot menu'),
        ((0, 22, 6, 2), (255, 255, 120), '"RADAR:" (22,0), double height'),
        ((6, 22, 16, 2), (255, 60, 60), 'radar: 128 x 16 pixels at $50C6, RadarOwn / RadarEnemy'),
    ]
    for i, ((cx, cy, w, h), c, text) in enumerate(areas):
        x0, y0 = cx * 8 * s, 30 + cy * 8 * s
        d.rectangle([x0 + i % 2, y0 + i % 2, x0 + w * 8 * s - 1 - i % 2, y0 + h * 8 * s - 1 - i % 2], outline=c,
                    width=3)
        d.text((x0 + 6, y0 + 4), f'{i + 1}', fill=c, font=f)
    y = 40
    for i, (_, c, text) in enumerate(areas):
        for k, line in enumerate(wrap(text, 36)):
            d.text((im.width + 10, y), (f'{i + 1} ' if k == 0 else '  ') + line, fill=c, font=K.font(11))
            y += 15
        y += 8
    out.save(args.out)
    print(args.out, out.size)


def wrap(text, n):
    words, lines, line = text.split(), [], ''
    for w in words:
        if len(line) + len(w) + 1 > n and line:
            lines.append(line)
            line = w
        else:
            line = f'{line} {w}'.strip()
    return lines + [line]


# ---------------------------------------------------------------------------------------------------------------
# robots over time

def fig_robots(args):
    m = Memory(args.work, args.unreal, args.cache)
    frames = list(range(args.step, args.last + 1, args.step))
    data = []
    for f in frames:
        r = m.read(f, ROBOTS, 768)
        v = m.read(f, VARS, 256)
        ours = sum(1 for i in range(24) if r[16 * i + 1])
        theirs = sum(1 for i in range(24, 48) if r[16 * i + 1])
        data.append((f, ours, theirs, sum(v[0x3B:0x41]), sum(v[0x43:0x49]), v[0x3A], v[0x42], v[0x37] | v[0x38] << 8))
    m.save()
    W, H, L, T, B = 1400, 520, 60, 50, 60
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    f = K.font(13)
    top = 24
    sx = (W - L - 20) / args.last
    sy = (H - T - B) / top

    def xy(frame, value):
        return L + frame * sx, H - B - value * sy

    for v in range(0, top + 1, 4):
        d.line([xy(0, v), xy(args.last, v)], fill=K.PANEL)
        d.text((L - 28, xy(0, v)[1] - 7), f'{v:2d}', fill=K.DIM, font=f)
    day = None
    for fr, *_, dd in data:
        if dd != day:
            if day is not None:
                d.line([xy(fr, 0), xy(fr, top)], fill=(40, 40, 55))
                d.text((xy(fr, 0)[0] + 2, H - B + 6), f'day {dd}', fill=K.DIM, font=K.font(10))
            day = dd
    series = [(1, OURS, 'our robot records (+$01 != 0, slots 0-23)', 3),
              (2, THEIRS, 'enemy robot records (slots 24-47)', 3),
              (3, (140, 200, 140), 'our factories (PlayerBuildings 1-6)', 1),
              (4, (220, 140, 130), 'enemy factories (EnemyBuildings 1-6)', 1),
              (6, (240, 200, 70), 'enemy warbases (EnemyBuildings 0)', 1)]
    for k, colour, label, width in series:
        pts = [xy(row[0], row[k]) for row in data]
        step = []
        for i, p in enumerate(pts):
            if i:
                step.append((p[0], pts[i - 1][1]))
            step.append(p)
        d.line(step, fill=colour, width=width)
    d.text((L, 12), f'Robots and factories per side in the deep recording ({args.work}), sampled every {args.step} frames '
           f'with memory_at', fill=K.TEXT, font=f)
    lx, ly = L + 10, T
    for _, colour, label, _ in series:
        d.rectangle([lx, ly + 4, lx + 10, ly + 12], fill=colour)
        d.text((lx + 16, ly), label, fill=colour, font=K.font(11))
        ly += 16
    d.text((W - 120, H - 22), 'frame', fill=K.DIM, font=f)
    out.save(args.out)
    last = data[-1]
    print(args.out, 'peak ours', max(r[1] for r in data), 'peak enemy', max(r[2] for r in data), 'last', last)


# ---------------------------------------------------------------------------------------------------------------
# the map from memory

def cell_colour(c):
    t = c & 0x1F
    if t == 0 or t == 1:
        return (36, 36, 30)
    if 2 <= t <= 5:
        return (95, 85, 50)        # stones, height 2
    if t in (6, 7):
        return (110, 70, 50)       # boulders / wreck, height 3
    if 8 <= t <= 11:
        return (140, 125, 70)      # rocks, height 6
    if 12 <= t <= 14:
        return (40, 70, 110)       # trench, height 0
    if t in (15, 17):
        return (170, 170, 175)     # low blocks, height 7
    if t in (16, 18):
        return (230, 230, 235)     # tall blocks, height 15
    if t == 21:
        return (200, 60, 200)      # the fence posts
    return (255, 0, 255)


def draw_map(m, frame, cs):
    mp = m.read(frame, MAP, 0x2000)
    rb = m.read(frame, ROBOTS, 768)
    pts = m.read(frame, POINTS, 140)
    v = m.read(frame, VARS, 256)
    halves = []
    for half in (0, 1):
        im = Image.new('RGB', (256 * cs, 16 * cs), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        for y in range(16):
            for x in range(256):
                c = mp[0x200 * y + 256 * half + x]
                d.rectangle([x * cs, y * cs, x * cs + cs - 1, y * cs + cs - 1], fill=cell_colour(c))
        for i in range(28):
            p = pts[5 * i:5 * i + 5]
            x, y, own = p[0] | p[1] << 8, p[2], p[3]
            if x // 256 != half:
                continue
            colour = THEIRS if own & 0x20 else OURS if own & 0x40 else NEUTRAL
            if own & 0x80:
                colour = (90, 90, 90)
            X = (x % 256) * cs
            r = cs * (2 if i < 4 else 1)
            d.ellipse([X - r + cs // 2, y * cs - r + cs // 2, X + r + cs // 2, y * cs + r + cs // 2], outline=colour,
                      width=2)
            d.text((X + cs + 1, y * cs - 2), 'WFNMPEC'[own & 7] if i >= 4 else 'B', fill=colour, font=K.font(10))
        for i in range(48):
            r = rb[16 * i:16 * i + 16]
            if not r[1]:
                continue
            x, y = r[2] | r[3] << 8, r[4]
            if x // 256 != half:
                continue
            colour = OURS if i < 24 else THEIRS
            X = (x % 256) * cs
            d.rectangle([X, (y - 1) * cs, X + 2 * cs - 1, y * cs + cs - 1], fill=colour)
        sx, sy = v[0x0E] | v[0x0F] << 8, v[0x0D]
        if sx // 256 == half:
            X = (sx % 256) * cs
            d.line([X - cs, sy * cs + cs // 2, X + 2 * cs, sy * cs + cs // 2], fill=(255, 255, 255), width=2)
            d.line([X + cs // 2, sy * cs - cs, X + cs // 2, sy * cs + 2 * cs], fill=(255, 255, 255), width=2)
        halves.append(im)
    return halves, v


def fig_map(args):
    m = Memory(args.work, args.unreal, args.cache)
    cs = 5
    frames = [int(x) for x in args.frames.split(',')]
    f, small = K.font(13), K.font(11)
    blocks = []
    for fr in frames:
        halves, v = draw_map(m, fr, cs)
        blocks.append((fr, halves, v))
    m.save()
    W = 256 * cs + 70
    H = 40 + len(blocks) * (2 * (16 * cs + 18) + 26) + 60
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((10, 8), f'The map $DD00 (16 rows x 512 columns, row 0 at the top) from memory, {args.work}', fill=K.TEXT,
           font=f)
    y = 34
    for fr, halves, v in blocks:
        day = v[0x37] | v[0x38] << 8
        d.text((10, y), f'frame {fr}: day {day} {v[0x36]:02d}:{v[0x35]:02d}; our robots {v[0x41]}, the enemy\'s {v[0x49]}',
               fill=K.TEXT, font=f)
        y += 20
        for half, im in enumerate(halves):
            d.text((10, y + 30), f'{256 * half}-', fill=K.DIM, font=small)
            d.text((10, y + 44), f'{256 * half + 255}', fill=K.DIM, font=small)
            out.paste(im, (60, y))
            for c in range(0, 256, 32):
                d.text((60 + c * cs, y + 16 * cs + 2), f'{256 * half + c}', fill=K.DIM, font=K.font(9))
            y += 16 * cs + 18
        y += 6
    legend = [((36, 36, 30), 'ground'), ((95, 85, 50), 'stones h2'), ((140, 125, 70), 'rocks h6'),
              ((40, 70, 110), 'trench h0'), ((170, 170, 175), 'low block h7'), ((230, 230, 235), 'tall block h15'),
              ((110, 70, 50), 'wreck h3'), ((200, 60, 200), 'fence'), (OURS, 'ours'), (THEIRS, 'enemy'),
              (NEUTRAL, 'neutral')]
    x = 10
    for colour, text in legend:
        d.rectangle([x, y + 4, x + 10, y + 14], fill=colour)
        d.text((x + 14, y + 2), text, fill=K.DIM, font=small)
        x += 16 + 8 * len(text) + 10
    d.text((10, y + 22), 'circles: capture points $FD70 (B a warbase, factory letter E electronics N nuclear P phasers '
           'M missiles C cannon W chassis) in the owner\'s colour; squares: robots (2 x 2); cross: the ship',
           fill=K.DIM, font=small)
    out.save(args.out)
    print(args.out, out.size)


# ---------------------------------------------------------------------------------------------------------------
# the robot records as a data sheet

FIELDS = [('+00', 'cell lo', (90, 150, 250)), ('+01', 'cell hi', (90, 150, 250)), ('+02', 'X lo', (70, 210, 220)),
          ('+03', 'X hi', (70, 210, 220)), ('+04', 'Y', (70, 210, 220)), ('+05', 'course', (240, 200, 70)),
          ('+06', 'steps', (240, 200, 70)), ('+07', 'parts', (200, 110, 230)), ('+08', 'facing', (240, 200, 70)),
          ('+09', 'height', (200, 110, 230)), ('+0A', 'control', (230, 90, 80)), ('+0B', 'order', (230, 90, 80)),
          ('+0C', 'strength', (90, 200, 120)), ('+0D', 'ground', (200, 110, 230)), ('+0E', 'target', (230, 90, 80)),
          ('+0F', 'delay', (240, 200, 70))]
PARTS = ['bipod', 'tracks', 'a-grav', 'cannon', 'missiles', 'phasers', 'nuclear', 'electr']
ORDERS = ['stop', 'advance', 'retreat', 'dest robots', 'dest fact', 'dest bases', 'capt neutral', 'capt fact',
          'capt bases']


def fig_records(args):
    m = Memory(args.work, args.unreal, args.cache)
    rb = m.read(args.frame, ROBOTS, 768)
    m.save()
    f, small = K.font(12), K.font(11)
    cw, rh, L = 54, 17, 80
    live = [i for i in range(48) if rb[16 * i + 1]]
    W = L + 16 * cw + 330
    H = 70 + rh * (len(live) + 2) + 20
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((10, 8), f'The live robot records $DA00 + 16 x slot at frame {args.frame} of {args.work} '
           f'({len(live)} of 48)', fill=K.TEXT, font=f)
    for k, (off, name, colour) in enumerate(FIELDS):
        d.text((L + k * cw + 4, 32), off, fill=colour, font=small)
        d.text((L + k * cw + 4, 46), name, fill=colour, font=K.font(10))
    y = 66
    for i in live:
        r = rb[16 * i:16 * i + 16]
        side = OURS if i < 24 else THEIRS
        d.text((10, y), f'{i:2d} ${ROBOTS + 16 * i:04X}', fill=side, font=small)
        for k, b in enumerate(r):
            c = FIELDS[k][2]
            d.rectangle([L + k * cw, y - 1, L + k * cw + cw - 3, y + rh - 3], fill=tuple(v // 5 for v in c))
            d.text((L + k * cw + 14, y), f'{b:02X}', fill=c, font=f)
        parts = '+'.join(PARTS[p] for p in range(8) if r[7] >> p & 1)
        order = ORDERS[r[11]] if r[11] < 9 else '?'
        d.text((L + 16 * cw + 8, y), f'({r[2] | r[3] << 8},{r[4]}) {parts}, {order}', fill=K.DIM, font=K.font(10))
        y += rh
    out.save(args.out)
    print(args.out, out.size)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('figure', choices=['sprite', 'areas', 'robots', 'map', 'records'])
    p.add_argument('--out', required=True)
    p.add_argument('--image')
    p.add_argument('--work')
    p.add_argument('--unreal')
    p.add_argument('--cache')
    p.add_argument('--frame', type=int, default=20000)
    p.add_argument('--frames', default='200,36000')
    p.add_argument('--step', type=int, default=250)
    p.add_argument('--last', type=int, default=36000)
    args = p.parse_args()
    {'sprite': fig_sprite, 'areas': fig_areas, 'robots': fig_robots, 'map': fig_map, 'records': fig_records}[
        args.figure](args)


if __name__ == '__main__':
    main()
