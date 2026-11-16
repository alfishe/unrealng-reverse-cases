#!/usr/bin/env python3
"""ATV Simulator's rules for doc 10: the course of the trails recording, trail 1's ground against the ATV's height,
and the physics tables run as the code runs them.

    python3 tools/fig_gameplay.py fig-course VARS.jsonl OUT.png    the whole recording: distance, speed, height,
                                                                   fuel, clock and score, with its events
    python3 tools/fig_gameplay.py fig-profile VARS.jsonl OUT.png   trail 1: list A1's items as the ground, the
                                                                   ATV's height and GroundY at each pass
    python3 tools/fig_gameplay.py fig-tables OUT.png               the jump and the fall (Rise, Fall, FallSteps),
                                                                   the crash by speed (Crash), the tumble

VARS.jsonl is work/docs/atC/sample.py's default sampling of a recording (one row a frame: LoopVars $D6B6-$D6DA, the
records $D70E-$D7A7, the scores $6947-$6951). The tables come from the build (build/game.bin at $6338); the trail
items from src/res/trails through res_formats.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import res_formats as RF  # noqa: E402

BASE = 0x6338
FALL_STEPS = 0xE319
TUMBLE_FRAMES = 0xE86C
TUMBLE_HEIGHTS = 0xE884


def font(size):
    from PIL import ImageFont
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf',
              '/System/Library/Fonts/Helvetica.ttc'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def image():
    mem = bytearray(0x10000)
    game = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem[BASE:BASE + len(game)] = game
    return mem


def rows(path):
    out = []
    for line in open(path):
        r = json.loads(line)
        lp = bytes.fromhex(r['D6B6'])
        rc = bytes.fromhex(r['D70E'])[:50]
        sc = bytes.fromhex(r['6947'])
        clock = lp[0xD6C9 - 0xD6B6:0xD6CC - 0xD6B6]
        try:
            cv = int(clock.decode('latin1'))
        except ValueError:
            cv = None
        out.append({'f': r['f'], 'trail': lp[0xD6BF - 0xD6B6], 'fc': lp[0xD6BC - 0xD6B6],
                    'groundy': lp[0xD6C4 - 0xD6B6], 'clock': cv, 'speed': rc[9], 'height': rc[6],
                    'vspeed': rc[1], 'mounted': rc[2], 'frame': rc[3], 'track': rc[24] | rc[25] << 8,
                    'fuel': rc[10] | rc[11] << 8, 'tumble': rc[37], 'riderx': rc[19], 'bonus': rc[41] | rc[42] << 8,
                    'score': int(sc[1:6].decode('latin1') or 0)})
    return out


def cmd_fig_course(vars_path, path):
    from PIL import Image, ImageDraw
    R = rows(vars_path)
    W = 1050
    panels = [('TrackPos (px)', 'track', 1800, (220, 40, 40)), ('Speed', 'speed', 21, (40, 80, 220)),
              ('AtvHeight (lines)', 'height', 50, (150, 60, 160)), ('Fuel', 'fuel', 0x2000, (200, 120, 0)),
              ('Clock (tenths)', 'clock', 600, (30, 120, 30)), ('Score', 'score', 3500, (0, 0, 0))]
    ph, X1, X2, T0 = 92, 175, 1035, 64
    H = T0 + ph * len(panels) + 120
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    fb, f, fs = font(16), font(14), font(13)
    d.text((10, 8), 'The trails recording, frame by frame (RecordP1 and the loop variables at the start of each frame)',
           fill='black', font=fb)
    d.text((10, 30), 'trail 1 from the start line to its finish, TIME OUT, the finish tune and the bonus count; '
                     'trail 2 to a crash, a tumble and a rider who walks the wrong way', fill='black', font=f)
    f0, f1 = R[0]['f'], R[-1]['f']

    def xv(fr):
        return X1 + (fr - f0) * (X2 - X1) / (f1 - f0)
    events = [(508, 'mounted'), (819, 'landing'), (1103, 'jump'), (1292, 'the dune'), (1673, 'finish'),
              (4490, 'TIME OUT, tune'), (4710, 'bonus'), (4932, 'trail 2'), (5417, 'mounted'), (5628, 'ramp jump'),
              (5851, 'crash'), (6012, 'tumble ends')]
    for k, (name, key, top, col) in enumerate(panels):
        y0 = T0 + k * ph
        y1 = y0 + ph - 14
        d.rectangle((X1, y0, X2, y1), outline=(190, 190, 190))
        d.text((10, y0 + 2), name, fill=col, font=f)
        d.text((X1 - 44, y0 - 2), str(top) if key != 'fuel' else '$2000', fill='black', font=fs)
        d.text((X1 - 14, y1 - 12), '0', fill='black', font=fs)
        if key == 'fuel':
            yy = y1 - 0x400 * (y1 - y0) / top
            d.line((X1, yy, X2, yy), fill=(230, 180, 180))
            d.text((X1 + 330, yy - 15), 'empty under $400', fill=(180, 60, 60), font=fs)
        pts = []
        for r in R:
            v = r[key]
            if v is None:
                continue
            pts.append((xv(r['f']), y1 - min(v, top) * (y1 - y0) / top))
        d.line(pts, fill=col, width=1)
        for fr, _ in events:
            d.line((xv(fr), y0, xv(fr), y1), fill=(225, 225, 225))
    yb = T0 + ph * len(panels)
    for fr in range(0, f1 + 1, 500):
        d.text((xv(fr) - 12, yb - 10), str(fr), fill='black', font=fs)
    for k, (fr, name) in enumerate(events):
        yy = yb + 12 + (k % 4) * 18
        d.line((xv(fr), yb - 12, xv(fr), yy), fill=(160, 160, 160))
        d.text((xv(fr) + 3, yy - 2), f'{name} {fr}', fill='black', font=fs)
    d.text((X2 - 50, yb + 88), 'frame', fill='black', font=fs)
    im.save(path)


def trail_items(name, index):
    blocks, lists = RF.trail_parse(name, RF.load(name))
    recs = [b for b in blocks if b[0] == 'record']
    a = recs[index][2]
    anims = {b[1]: b[2] for b in blocks if b[0] == 'anim'}
    for b in blocks:
        if b[0] == 'list' and b[1] == a:
            return b[2], anims
    return [], anims


def cmd_fig_profile(vars_path, path):
    from PIL import Image, ImageDraw
    R = [r for r in rows(vars_path) if r['trail'] == 0 and 500 <= r['f'] <= 1700 and r['f'] % 7 == 0]
    data = RF.load('sprites/game.bin')
    sizes = {i: (data[RF.word(data, 4 + 2 * i)], data[RF.word(data, 4 + 2 * i) + 1],
                 data[RF.word(data, 4 + 2 * i) + 2]) for i in range(data[0])}
    items, anims = trail_items('trails/trails14.bin', 0)
    W, H = 1050, 470
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    fb, f, fs = font(16), font(14), font(13)
    d.text((10, 8), 'Trail 1: the ground list A1 builds and how the ATV rode it in the trails recording',
           fill='black', font=fb)
    d.text((10, 30), 'grey: each ground item\'s box (distance, advance, y, height); purple: AtvHeight at the start of '
                     'each pass; green dots: GroundY, the ground under the rear wheel', fill='black', font=f)
    X1, X2, T, B = 60, 1035, 70, 400
    L = 1700
    S = 6.0

    def xv(v):
        return X1 + v * (X2 - X1) / L

    def yv(h):
        return B - h * S
    d.line((X1, B, X2, B), fill='black')
    for it in items:
        dist, y = it[0] | it[1] << 8, it[2]
        if it[5] & 0xF0 or it[5] & 0x07:
            continue
        w, h, adv = sizes[it[4]]
        y = y or h
        d.rectangle((xv(dist + 7), yv(y), xv(dist + 7 + adv), yv(y - h)), fill=(225, 225, 225),
                    outline=(150, 150, 150))
    # the ATV's rear wheel is at AtvX + 7 = 79 on screen: distance TrackPos + 79 under it
    pts = [(xv(r['track'] + 79), yv(r['height'])) for r in R]
    d.line(pts, fill=(150, 60, 160), width=2)
    for r in R:
        x, y = xv(r['track'] + 79), yv(r['groundy'])
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(30, 140, 30))
    for v in range(0, L + 1, 200):
        d.text((xv(v) - 10, B + 6), str(v), fill='black', font=fs)
    for h in (0, 10, 20, 30, 40, 50):
        d.text((20, yv(h) - 7), str(h), fill='black', font=fs)
    fin = 0x690 - 0x48 + 79
    d.line((xv(fin), T, xv(fin), B), fill=(0, 0, 0), width=2)
    d.text((xv(fin) - 175, T), 'the finish (TrackPos 1608)', fill='black', font=fs)
    d.text((X1, B + 26), 'x: the distance under the rear wheel (TrackPos + 79 px); y: lines above the window\'s bottom. '
                         'The items are drawn 7 px right of their distance, where the wheel meets them.',
           fill='black', font=fs)
    d.text((X1, B + 44), 'Where purple leaves the grey the ATV is in the air: off the dunes at x 400, 520, 900 and '
                         '1 520, and down the staircase at x 1 270-1 330.', fill='black', font=fs)
    im.save(path)


def cmd_fig_tables(path):
    from PIL import Image, ImageDraw
    mem = image()
    fall = list(mem[FALL_STEPS:FALL_STEPS + 6])
    tf = list(mem[TUMBLE_FRAMES:TUMBLE_FRAMES + 24])
    th = [b - 256 if b > 127 else b for b in mem[TUMBLE_HEIGHTS:TUMBLE_HEIGHTS + 24]]
    W, H = 1050, 640
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    fb, f, fs = font(16), font(14), font(13)
    d.text((10, 8), 'The physics tables run as the code runs them (FallSteps $E319, TumbleFrames $E86C, '
                    'TumbleHeights $E884, Crash $E94C)', fill='black', font=fb)

    # a jump: VSpeed = $FD - rise (0-5), then Rise each pass until 0, then Fall
    def flight(rise, ground=0):
        v = (0xFD - rise) & 0xFF
        h, path = 0, [0]
        for _ in range(40):
            if v & 0x80:
                v = (v + 1) & 0xFF
                if v == 0:
                    v = 1
                else:
                    n = min(256 - v, 5)
                    h += fall[n - 1]
            else:
                v = min(v + 1, 5)
                h -= fall[v - 1]
                if h <= ground:
                    path.append(ground)
                    break
            path.append(h)
        return path
    X1, X2, T, B = 60, 500, 70, 270
    d.text((10, 40), 'A jump: VSpeed = $FD less the last pass\'s rise (0-5), then Rise and Fall', fill='black', font=f)
    d.rectangle((X1, T, X2, B), outline=(190, 190, 190))
    cols = [(220, 40, 40), (200, 120, 0), (150, 150, 0), (30, 140, 30), (40, 80, 220), (150, 60, 160)]
    for rise in range(6):
        p = flight(rise)
        d.line([(X1 + i * 22, B - h * 6) for i, h in enumerate(p)], fill=cols[rise], width=2)
        d.text((X1 + 10 + rise * 72, B + 24), f'rise {rise}: {max(p)}', fill=cols[rise], font=fs)
    for i in range(0, 21, 4):
        d.text((X1 + i * 22 - 4, B + 4), str(i), fill='black', font=fs)
    for h in (0, 10, 20, 30):
        d.text((X1 - 26, B - h * 6 - 7), str(h), fill='black', font=fs)
    d.text((X1, B + 44), 'x: passes from the jump; y: lines above the take-off.', fill='black', font=fs)
    d.text((X1, B + 62), 'Rise and fall per pass by |VSpeed| 1-5 (FallSteps): ' + ', '.join(str(v) for v in fall[:5]),
           fill='black', font=fs)

    # the crash by speed
    X3, X4 = 560, 1035
    d.text((X3, 40), 'A crash by the speed after its SlowDown (speed - 2)', fill='black', font=f)
    for s in range(1, 22):
        after = max(0, s - 2)
        if after < 10:
            col, what = (120, 160, 220), 'stop'
        elif after < 15:
            col, what = (230, 170, 60), 'stop, throw'
        else:
            col, what = (220, 60, 60), 'tumble, throw'
        x = X3 + (s - 1) * 22
        d.rectangle((x, T + 20, x + 20, B - 30), fill=col)
        d.text((x + 3, B - 26), str(s), fill='black', font=fs)
    d.text((X3, B - 8), 'speed at the crash (1-21)', fill='black', font=fs)
    for k, (col, what) in enumerate([((120, 160, 220), 'speed 1-11: the ATV stops'),
                                     ((230, 170, 60), '12-16: stops and throws the rider'),
                                     ((220, 60, 60), '17-21: tumbles 24 passes, throws the rider')]):
        d.rectangle((X3, B + 14 + k * 18, X3 + 14, B + 28 + k * 18), fill=col)
        d.text((X3 + 20, B + 13 + k * 18), what, fill='black', font=fs)

    # the tumble
    T2, B2 = 430, 600
    d.text((10, T2 - 26), 'The tumble on flat ground, from Crash\'s AtvHeight 5: TumbleCount 2-24, each step adds '
                          '2 x TumbleHeights; the sprite from TumbleFrames, $85 once down', fill='black', font=f)
    h, hs = 15, [15]
    for c in range(3, 25):
        h = max(0, h + 2 * th[c - 2])
        hs.append(h)
    X5, X6 = 60, 1035
    d.rectangle((X5, T2, X6, B2), outline=(190, 190, 190))
    step = (X6 - X5) / len(hs)
    for i, hh in enumerate(hs):
        x = X5 + i * step
        d.rectangle((x + 2, B2 - hh * 2.5, x + step - 2, B2), fill=(240, 200, 200), outline=(200, 80, 80))
        d.text((x + 6, B2 - hh * 2.5 - 16), str(hh), fill='black', font=fs)
        d.text((x + 6, B2 + 4), f'${tf[i]:02X}' if hh or i == 0 else '$85', fill=(80, 80, 80), font=fs)
    im = im.crop((0, 0, W, B2 + 24))
    im.save(path)


def main():
    a = sys.argv[1:]
    if not a:
        sys.exit(__doc__)
    {'fig-course': cmd_fig_course, 'fig-profile': cmd_fig_profile, 'fig-tables': cmd_fig_tables}[a[0]](*a[1:])


if __name__ == '__main__':
    main()
