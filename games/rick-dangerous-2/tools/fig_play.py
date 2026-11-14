#!/usr/bin/env python3
"""The figures and play animations of doc 10 (gameplay logic).

    python3 tools/fig_play.py anim --work W --from F --to T [--step 2] [--chart rick|bullet|detonator] [--title T] OUT.gif
    python3 tools/fig_play.py jump [--work W --window F-T] docs/img/play/jump.png
    python3 tools/fig_play.py fuse [--work W --window F-T] docs/img/play/fuse.png
    python3 tools/fig_play.py traps --level N docs/img/play/traps-levelN.png
    python3 tools/fig_play.py fatguy docs/img/play/fat-guy.png
    python3 tools/fig_play.py stats

anim: a GIF of a recording (TTD memory_at at T 0 of each frame, so a picture shows the state the previous frame
left): the screen with a box over Rick (green), table A's traps (yellow), table B's enemies (red), the bullet and
the detonator (white); beside it Rick's variables and a chart that grows picture by picture (--chart rick: RickY
and RickDy; bullet: BulletX; detonator: DetonatorFuse and RickY).

jump: Rick's vertical motion from the code's numbers (UpdateRick: RickDy + 0.5 a pass to at most 8.0, the 24-bit y
moved by it), for the jump (-6.0), the launch pad (-2175/256), the death (-5.0, no limit) and the hop off a
ladder's top (-2.0); with --work the recorded RickY at each pass, and the running jump's path on the 8-pixel cells.

fuse: the detonator's 64 passes from the code (BurnFuse): the sprite at each fuse value, the sounds, the passes
that kill Rick and the enemies; with --work the recorded fuse and Rick's y.

traps: every trap kind a level's map entries place (src/res/levels/levelN): its first animation frame, its size,
deadly or not, its path in short, how many entries place it, and who sets off its trigger boxes.

fatguy: level 5 section 7 drawn from src/res with the Fat Guy's five parts at his start (FatGuyStart), the body's
path FatGuyPath, the hit box, and the shot's start.
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import fig_rooms as FR  # noqa: E402
import fig_render as FRN  # noqa: E402
import zxscreen  # noqa: E402

W = 1050
YEL, RED, GRN, CYA, WHT, ORA, PUR = ((240, 210, 80), (240, 90, 80), (90, 200, 120), (80, 200, 230), (230, 230, 230),
                                     (250, 150, 60), (190, 120, 240))


def session_mem(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)

    def mem(frame, addr, n, t=0):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                         'offset': addr, 'length': n}, ok=False)
        return bytes.fromhex((r.structured or {})['hex'])
    return mem


def s16(v):
    return v - 0x10000 if v & 0x8000 else v


def rick_state(mem, fr):
    """Rick's and the weapons' variables at T 0 of frame fr ($9B95-$9BC6)"""
    b = mem(fr, 0x9B95, 0x32)
    o = lambda a: b[a - 0x9B95]  # noqa: E731
    return {
        'dy': s16(o(0x9B95) | o(0x9B96) << 8) / 256.0, 'x': o(0x9BAC), 'y': o(0x9BAD) | o(0x9BAE) << 8,
        'crawl': o(0x9B98), 'climb': o(0x9B99), 'over': o(0x9B9B), 'dying': o(0x9B9C), 'ground': o(0x9B9D),
        'punch': o(0x9BA3), 'facing': o(0x9BB1), 'bullet': o(0x9BB4), 'bx': o(0x9BB5),
        'by': o(0x9BB6) | o(0x9BB7) << 8, 'det': o(0x9BBD), 'dx': o(0x9BBE), 'dety': o(0x9BBF) | o(0x9BC0) << 8,
        'fuse': o(0x9BC6),
    }


def fig_anim(a):
    mem = session_mem(a.work)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    frames = list(range(a.start, a.end + 1, a.step))
    states = [rick_state(mem, fr) for fr in frames]
    pictures = []
    for i, fr in enumerate(frames):
        st = states[i]
        scr = mem(fr, 0x4000, 6912)
        ta, tb = mem(fr, 0x7B8F, 8 * 24), mem(fr, 0x7C20, 4 * 23)
        hud = mem(fr, 0x8B3B, 3)
        img = Image.new('RGB', (W, 440), K.BACKGROUND)
        img.paste(zxscreen.render(scr, 2).convert('RGB'), (4, 30))
        d = ImageDraw.Draw(img)
        d.text((8, 6), a.title, fill=K.TEXT, font=fb)

        def box(x, y, w, h, col):
            sy = y - 64          # view y 64 is the screen's pixel row 0 (the HUD row is drawn over it)
            if -h < sy < 192:
                d.rectangle((4 + 2 * x, 30 + 2 * sy, 4 + 2 * (x + w) - 1, 30 + 2 * (sy + h) - 1), outline=col, width=2)
        for j in range(8):
            r = ta[24 * j:24 * j + 24]
            if r[0] == 0xFF:
                break
            if r[0]:
                box(r[1], r[2] | r[3] << 8, r[7], r[8], YEL)
        for j in range(4):
            r = tb[23 * j:23 * j + 23]
            if r[0] == 0xFF:
                break
            if r[0]:
                box(r[1] + 4, r[2] | r[3] << 8, 16, 21, RED)
        box(st['x'] + 4, st['y'] + (5 if st['crawl'] else 0), 16, 16 if st['crawl'] else 21, GRN)
        if st['bullet']:
            box(st['bx'], st['by'], 8, 4, WHT)
        if st['det']:
            box(st['dx'], st['dety'], 16, 16, WHT)
        px = 530
        d.text((px, 30), 'frame %d (state at T 0)' % fr, fill=K.TEXT, font=fb)
        mode = ('dying' if st['dying'] else 'climbing' if st['climb'] else 'crawling' if st['crawl'] else
                'on the ground' if st['ground'] else 'in the air')
        rows = [
            (GRN, 'Rick x %3d  y %3d  RickDy %+5.2f  %s' % (st['x'], st['y'], st['dy'], mode)),
            (WHT, 'bullet %s  x %3d' % ('flying' if st['bullet'] else 'none', st['bx'])),
            (WHT, 'detonator %s  fuse %2d  x %3d' % ('out' if st['det'] else 'none', st['fuse'], st['dx'])),
            (K.TEXT, 'PunchTimer %d   lives %d  bullets %d  detonators %d' % (st['punch'], hud[0], hud[1], hud[2])),
        ]
        for j, (col, t) in enumerate(rows):
            d.text((px, 56 + 19 * j), t, fill=col, font=fs)
        # the growing chart
        cx, cy, cw, ch = px, 146, W - px - 12, 250
        d.rectangle((cx, cy, cx + cw, cy + ch), fill=K.PANEL)
        n = len(frames)
        xs = lambda k: cx + 30 + k * (cw - 40) / max(1, n - 1)  # noqa: E731
        # each series in its own band, with its own scale; True: larger values lower (a y), else higher
        if a.chart == 'rick':
            series = [('RickY: down is down', GRN, [s['y'] for s in states], True),
                      ('RickDy: down is down', ORA, [s['dy'] for s in states], True)]
        elif a.chart == 'bullet':
            series = [('BulletX', WHT, [s['bx'] if s['bullet'] else None for s in states], False),
                      ('RickX', GRN, [s['x'] for s in states], False)]
        else:
            series = [('DetonatorFuse', ORA, [s['fuse'] if s['det'] else None for s in states], False),
                      ('RickY: down is down', GRN, [s['y'] for s in states], True)]
        bh = (ch - 40) // len(series)
        for k, (name, col, vs, down) in enumerate(series):
            top = cy + 24 + k * bh
            vals = [v for v in vs if v is not None] or [0]
            lo, hi = min(vals), max(vals)
            if hi == lo:
                hi = lo + 1
            ys = (lambda v, top=top, lo=lo, hi=hi, down=down:
                  top + 14 + ((v - lo) if down else (hi - v)) * (bh - 24) / (hi - lo))
            d.text((cx + 8, top - 2), '%s (%s to %s)' % (name, ('%.2f' % lo).rstrip('0').rstrip('.'),
                                                          ('%.2f' % hi).rstrip('0').rstrip('.')), fill=col, font=fs)
            if lo < 0 < hi:
                d.line((cx + 30, ys(0), cx + cw - 10, ys(0)), fill=K.DIM)
            pts = [(xs(j), ys(v)) for j, v in enumerate(vs[:i + 1]) if v is not None]
            if len(pts) > 1:
                d.line(pts, fill=col, width=2)
            for p in pts[-1:]:
                d.ellipse((p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3), fill=col)
        d.text((cx + 8, cy + ch - 14), 'frames %d-%d, one point every %d' % (a.start, a.end, a.step), fill=K.DIM,
               font=fs)
        d.text((px, 404), 'boxes: green Rick, yellow traps, red enemies, white weapons',
               fill=K.DIM, font=fs)
        pictures.append(img)
    K.save_gif(a.out, pictures, [a.step * 20 * a.slow] * (len(pictures) - 1) + [2000])
    print(a.out, len(pictures), 'pictures')


def arc(dy0, y0=0.0, limit=8.0, gravity=0.5, passes=60, floor=None):
    """the 24-bit y a pass, as UpdateRick moves it: dy += gravity (to the limit), y += dy (whole pixels kept)"""
    y, dy, out = int(y0 * 256), int(dy0 * 256), []
    out.append(y >> 8)
    for _ in range(passes):
        dy = min(dy + int(gravity * 256), int(limit * 256)) if limit else dy + int(gravity * 256)
        y += dy
        out.append(y >> 8)
        if floor is not None and (y >> 8) >= floor and dy > 0:
            out[-1] = floor
            break
    return out


def fig_jump(a):
    rec = []
    if a.work:
        mem = session_mem(a.work)
        lo, hi = (int(v) for v in a.window.split('-'))
        rec = [rick_state(mem, fr) for fr in range(lo, hi + 1, 2)]
    f, fs, fb = K.font(13), K.font(12), K.font(16)
    img = Image.new('RGB', (W, 620), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'Rick\'s vertical motion from the code: RickDy + 0.5 a pass (at most 8.0), then y + RickDy',
           fill=K.TEXT, font=fb)
    curves = [
        ('jump: -6.0 (RickReadJump $97DB)', GRN, arc(-6.0, floor=0)),
        ('launch pad, level 5: -2175/256 ($9799 branch)', ORA, arc(-2175 / 256.0, floor=0)),
        ('death: -5.0, no limit (KillRick $93D0)', RED, arc(-5.0, limit=0, passes=34)),
        ('off a ladder\'s top: -2.0 (RickWalk)', CYA, arc(-2.0, floor=0)),
    ]
    cx, cy, cw, ch = 14, 44, 600, 520
    d.rectangle((cx, cy, cx + cw, cy + ch), fill=K.PANEL)
    ymin, ymax = -80, 60
    npass = 36
    X = lambda p: cx + 40 + p * (cw - 60) / npass  # noqa: E731
    Y = lambda v: cy + 30 + (v - ymin) * (ch - 60) / (ymax - ymin)  # noqa: E731
    for v in range(ymin, ymax + 1, 8):
        d.line((cx + 40, Y(v), cx + cw - 20, Y(v)), fill=(36, 36, 46))
        if v % 16 == 0:
            d.text((cx + 4, Y(v) - 7), '%+d' % v, fill=K.DIM, font=fs)
    for p in range(0, npass + 1, 4):
        d.text((X(p) - 6, cy + ch - 24), str(p), fill=K.DIM, font=fs)
    d.text((cx + cw - 150, cy + ch - 44), 'passes after the key', fill=K.DIM, font=fs)
    d.line((cx + 40, Y(0), cx + cw - 20, Y(0)), fill=K.DIM, width=1)
    for k, (name, col, ys) in enumerate(curves):
        pts = [(X(p), Y(v)) for p, v in enumerate(ys) if p <= npass and ymin <= v <= ymax]
        d.line(pts, fill=col, width=2)
        d.text((cx + 50, cy + 8 + 18 * k), name, fill=col, font=fs)
    if rec:
        y0 = rec[0]['y']
        for p, s in enumerate(rec):
            d.ellipse((X(p) - 3, Y(s['y'] - y0) - 3, X(p) + 3, Y(s['y'] - y0) + 3), outline=WHT)
        d.text((cx + 50, cy + 8 + 18 * len(curves)), 'white rings: RickY in %s frames %s, every 2nd frame (a pass)'
               % (os.path.basename(a.work.rstrip('/')), a.window), fill=WHT, font=fs)
    # right: the running jump on the cells
    rx, ry, rw, rh = 630, 44, 406, 520
    d.rectangle((rx, ry, rx + rw, ry + rh), fill=K.PANEL)
    d.text((rx + 8, ry + 6), 'A running jump on 8-pixel cells, x + 2 a pass', fill=K.TEXT, font=f)
    sc = 3
    gx, gy = rx + 20, ry + 60
    cols, rows = (rw - 40) // (8 * sc), 18
    for c in range(cols + 1):
        d.line((gx + 8 * sc * c, gy, gx + 8 * sc * c, gy + 8 * sc * rows), fill=(40, 40, 52))
    for r in range(rows + 1):
        d.line((gx, gy + 8 * sc * r, gx + 8 * sc * cols, gy + 8 * sc * r), fill=(40, 40, 52))
    fy = gy + 8 * sc * 14        # the floor line: feet at y + 21
    d.line((gx, fy, gx + 8 * sc * cols, fy), fill=K.TEXT, width=2)
    for name, col, ys in curves[:2]:
        pts = [(gx + sc * (4 + 8 + 2 * p), fy + sc * v) for p, v in enumerate(ys) if 2 * p <= 8 * cols - 24]
        d.line(pts, fill=col, width=2)
    j = curves[0][2]
    top = min(j)
    p_top = j.index(top)
    d.rectangle((gx + sc * (4 + 2 * p_top), fy + sc * (top - 21), gx + sc * (4 + 2 * p_top + 16), fy + sc * top),
                outline=GRN, width=1)
    d.rectangle((gx + sc * 4, fy - sc * 21, gx + sc * 20, fy), outline=K.DIM, width=1)
    land = len(j) - 1
    d.text((rx + 8, ry + 26), 'jump: up %d px at pass %d, down at pass %d' % (-top, p_top, land), fill=GRN, font=fs)
    d.text((rx + 8, ry + 42), '  %d px across while walking' % (2 * land), fill=GRN, font=fs)
    lp = curves[1][2]
    d.text((rx + 8, ry + rh - 44), 'launch pad: up %d px at pass %d' % (-min(lp), lp.index(min(lp))), fill=ORA,
           font=fs)
    d.text((rx + 8, ry + rh - 26), 'boxes: Rick\'s 16 x 21 body (x + 4)', fill=K.DIM, font=fs)
    d.text((14, 576), 'One pass is 2 or 3 frames in play (doc 04). The y has an 8-bit fraction; the curves keep '
           'whole pixels as the game does.', fill=K.DIM, font=fs)
    d.text((14, 596), 'White rings: the recording. A landing snaps the feet to the cell edge.', fill=K.DIM, font=fs)
    img.save(a.out)
    print(a.out, img.size, 'jump top', top, 'pass', p_top, 'land', land, 'launch', min(lp), lp.index(min(lp)))


def level_sprite(b, sp, scale=2):
    """a 24 x 21 sprite of the level as an RGB image (bit 7 of sp: mirrored)"""
    pix = FRN.sprite_pixels(b['level/sprites.bin'][128 * (sp & 0x7F):128 * (sp & 0x7F) + 128])
    im = Image.new('RGB', (24, 21), (0, 0, 0))
    px = im.load()
    for r, line in enumerate(pix[:21]):
        for c, v in enumerate(line):
            px[c, r] = {0: (0, 0, 0), 1: (230, 230, 230), 3: (40, 60, 40)}[v]
    if sp & 0x80:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    return im.resize((24 * scale, 21 * scale), Image.NEAREST)


def fig_fuse(a):
    b = FR.level_bytes(1)
    rec = []
    if a.work:
        mem = session_mem(a.work)
        lo, hi = (int(v) for v in a.window.split('-'))
        rec = [(fr, rick_state(mem, fr)) for fr in range(lo, hi + 1, 2)]
    f, fs, fb = K.font(13), K.font(12), K.font(16)
    img = Image.new('RGB', (W, 520), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'The detonator\'s 64 passes (BurnFuse $9351): the fuse counts down from 64, one a pass',
           fill=K.TEXT, font=fb)
    x0, x1 = 40, W - 20
    X = lambda fuse: x1 - (fuse - 0) * (x1 - x0) / 64.0  # noqa: E731
    y0 = 60
    # bands
    bands = [(64, 20, 'sprite 18', (60, 60, 80)), (20, 10, 'sprite 19', (90, 70, 50)),
             (10, 0, 'blast 24-20', (120, 50, 40))]
    for hi_, lo_, name, col in bands:
        d.rectangle((X(hi_), y0, X(lo_), y0 + 40), fill=col)
        d.text((X(hi_) + 6, y0 + 12), name, fill=K.TEXT, font=fs)
    d.rectangle((X(9.5), y0 + 50, X(3.5), y0 + 74), fill=(170, 40, 40))
    d.text((X(9.5) - 420, y0 + 54), 'fuse 9-4: a 32 x 21 box round it kills Rick', fill=RED, font=fs)
    d.rectangle((X(9.5), y0 + 80, X(3.5), y0 + 100), outline=ORA, width=2)
    d.text((X(9.5) - 420, y0 + 82), 'fuse 9-4: BlastHits hits enemies and the Fat Guy', fill=ORA, font=fs)
    for fuse in range(64, -1, -4):
        d.line((X(fuse), y0 + 104, X(fuse), y0 + 110), fill=K.DIM)
        d.text((X(fuse) - 6, y0 + 112), str(fuse), fill=K.DIM, font=fs)
    d.text((x0, y0 + 130), 'effect 2 (the hiss) every 4th pass while the fuse is 10 or more; effect 5 (the bang) '
           'at fuse 10; the record freed at 0', fill=K.TEXT, font=fs)
    for fuse in range(63, 9, -1):
        if fuse % 4 == 0:
            d.ellipse((X(fuse) - 3, y0 + 152, X(fuse) + 3, y0 + 158), fill=CYA)
    d.ellipse((X(10) - 5, y0 + 150, X(10) + 5, y0 + 160), fill=YEL)
    # sprites
    sx = 40
    d.text((sx, y0 + 180), 'The sprites (frames of every level, Sprites + 128 n):', fill=K.TEXT, font=f)
    for k, (sp, lab) in enumerate([(18, 'fuse >= 20'), (19, 'fuse 10-19'), (24, 'fuse 8-9'), (23, 'fuse 6-7'),
                                   (22, 'fuse 4-5'), (21, 'fuse 2-3'), (20, 'fuse 1')]):
        img.paste(level_sprite(b, sp, 3), (sx + 140 * k, y0 + 206))
        d.text((sx + 140 * k, y0 + 272), 'sprite %d\n%s' % (sp, lab), fill=K.TEXT, font=fs)
    if rec:
        d.text((sx, y0 + 312), 'The recording, %s frames %s (every 2nd frame, the state at T 0):'
               % (os.path.basename(a.work.rstrip('/')), a.window), fill=WHT, font=f)
        cy = y0 + 336
        for fr, s in rec:
            if s['det'] or s['fuse']:
                d.ellipse((X(s['fuse']) - 2, cy - 2, X(s['fuse']) + 2, cy + 2), fill=WHT)
        last = None
        for fr, s in rec:
            if s['dying'] and last is None:
                last = (fr, s)
        if last:
            fr, s = last
            d.text((sx, cy + 14), 'Rick dying first seen at frame %d with the fuse at %d: the blast\'s first pass '
                   'killed him (he stood on it)' % (fr, s['fuse']), fill=RED, font=fs)
        d.text((sx, cy + 34), 'One fuse step a pass; a pass is 2 frames here, so 64 passes take %d frames.'
               % (2 * 64), fill=K.DIM, font=fs)
    img = img.crop((0, 0, W, y0 + 400 if rec else y0 + 310))
    img.save(a.out)
    print(a.out, img.size)


def level_labels(n):
    out = {}
    for ln in open(os.path.join(CASE, 'build', 'level%d.lst' % n), errors='replace'):
        m = re.match(r'\s*\d+\+?\s+([0-9A-F]{4})\s+([A-Za-z0-9]+):', ln)
        if m:
            out[m.group(2)] = int(m.group(1), 16)
    return out


WHO = [(0, 'Rick'), (1, 'bullet'), (2, 'blast'), (3, 'punch'), (4, 'enemy'), (5, 'trap'), (6, 'each pass')]


def placed_kinds(n):
    """{kind: {'n': entries, 'who': set, 'beh': set, 'what': text}} from sections.txt"""
    out = {}
    cur = None
    for ln in open(os.path.join(CASE, 'src', 'res', 'levels', 'level%d' % n, 'level', 'sections.txt')):
        m = re.match(r'object kind=\$([0-9A-F]{2}) .*param=\$([0-9A-F]{2}) ; (.*)$', ln)
        if m:
            k = int(m.group(1), 16)
            cur = None
            if k < 0x74:
                cur = out.setdefault(k, {'n': 0, 'who': set(), 'beh': set(), 'what': m.group(3).split(';')[0]})
                cur['n'] += 1
                cur['beh'].add((int(m.group(2), 16) >> 2) & 15)
            continue
        m = re.match(r'\s+box .*who=\$([0-9A-F]{2})', ln)
        if m and cur is not None:
            w = int(m.group(1), 16)
            for bit, name in WHO:
                if w >> bit & 1:
                    cur['who'].add(name)
    return out


def fig_traps(a):
    import fig_objects as FO
    n = a.level
    b = FR.level_bytes(n)
    L = level_labels(n)
    kinds, recs = b['level/kinds.bin'], b['level/kinds-2.bin']
    anims, paths, fmap = b['level/anims.bin'], b['level/paths.bin'], b['level/frame-map.bin']
    placed = placed_kinds(n)
    addrs = sorted({kinds[2 * k] | kinds[2 * k + 1] << 8 for k in range(len(kinds) // 2)} - {0})
    f, fs, fb = K.font(12), K.font(11), K.font(16)
    cw, chh, per = 150, 150, 7
    rows = (len(placed) + per - 1) // per
    img = Image.new('RGB', (W, 60 + rows * chh + 30), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'Level %d: every trap and pickup kind its map entries place (%d kinds, %d entries)'
           % (n, len(placed), sum(v['n'] for v in placed.values())), fill=K.TEXT, font=fb)
    d.text((14, 32), 'red frame: deadly (flags bit 6); "trigger": who sets off its boxes; "no box": it starts on '
           'view', fill=K.DIM, font=fs)
    for i, k in enumerate(sorted(placed)):
        v = placed[k]
        x, y = 14 + (i % per) * cw, 56 + (i // per) * chh
        ra = kinds[2 * k] | kinds[2 * k + 1] << 8
        rec = recs[ra - L['KindRecords']:ra - L['KindRecords'] + 11]
        deadly = rec[2] >> 6 & 1
        aa = rec[5] | rec[6] << 8
        sp = None
        if 0 <= aa - L['TrapAnims'] < len(anims):
            for it in FO.decode_anim(anims, aa, L['TrapAnims']):
                if it[0] not in ('fx', 'jump') and it[0] != 0x7F and fmap[it[0] - 1] != 0x7F:
                    sp = fmap[it[0] - 1]
                    break
        d.rectangle((x, y, x + 52, y + 46), outline=RED if deadly else K.DIM, width=2)
        if sp is not None:
            img.paste(level_sprite(b, sp, 2), (x + 2, y + 2))
        what = v['what'].replace('trap behaviour', 'beh.')
        d.text((x + 58, y), 'kind %d' % k, fill=K.TEXT, font=f)
        d.text((x + 58, y + 15), 'x%d' % v['n'], fill=YEL, font=f)
        d.text((x + 58, y + 30), '%dx%d' % (rec[0], rec[1]), fill=K.DIM, font=fs)
        pa = rec[3] | rec[4] << 8
        ptxt = ''
        if 0 <= pa - L['TrapPaths'] < len(paths):
            steps, passes = FO.decode_path(paths, pa, L['TrapPaths'])
            sx = sum(p[0] for p in passes)
            sy = sum(p[1] for p in passes)
            ptxt = 'path %dp %+d,%+d' % (len(passes), sx, sy) if passes and (sx or sy) else 'still'
        d.text((x, y + 50), what.split(', ', 1)[-1][:21] if ',' in what else 'trap', fill=K.TEXT, font=fs)
        d.text((x, y + 64), ptxt, fill=GRN, font=fs)
        nxt = min([q for q in addrs if q > ra] + [L['KindRecords'] + len(recs)])
        d.text((x, y + 78), '2nd path' if nxt - ra >= 11 else '', fill=CYA, font=fs)
        who = sorted(v['who'])
        lines, cur = [], 'trigger:' if who else 'no box: on view'
        for w_ in who:
            if len(cur) + len(w_) + 2 > 21:
                lines.append(cur)
                cur = ' '
            cur += ' ' + w_ + ','
        lines.append(cur.rstrip(','))
        for j, t in enumerate(lines[:3]):
            d.text((x, y + 92 + 13 * j), t, fill=ORA if who else K.DIM, font=fs)
    img.save(a.out)
    print(a.out, img.size, len(placed), 'kinds')


def fig_fatguy(a):
    b = FR.level_bytes(5)
    L = level_labels(5)
    parts, path = b['level/fat-guy.bin'], b['level/fat-guy-path.bin']
    sec = FR.draw_section(b, 7)[0]
    sc = 2
    f, fs, fb = K.font(13), K.font(12), K.font(16)
    img = Image.new('RGB', (W, 30 + sec.height * sc // 1 + 120), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 8), 'Level 5 section 7: the Fat Guy at his start (FatGuyStart $F7E6) and his path (FatGuyPath $FAF4)',
           fill=K.TEXT, font=fb)
    vy0, vy1 = 64, 264          # the part of the view drawn (the screen shows view y 64-255 at the top row 0)
    big = sec.crop((0, vy0, 256, vy1)).resize((256 * sc, (vy1 - vy0) * sc), Image.NEAREST)
    ox, oy = 14, 36
    img.paste(big, (ox, oy))
    V = lambda x, y: (ox + sc * x, oy + sc * (y - vy0))  # noqa: E731  the map image's top is view y 0
    bx, by = 0xB0, 0x90
    recs = [parts[8 * i:8 * i + 8] for i in range(5)]
    spr0 = L['Sprites']
    names = []
    for i, r in enumerate(recs):
        sp = ((r[2] | r[3] << 8) - spr0) // 128
        px, py = (bx, by) if i == 0 else ((bx + r[0]) & 0xFF, by + (r[1] - 256 if r[1] > 127 else r[1]))
        im = level_sprite(b, sp, sc)
        mask = Image.eval(im.convert('L'), lambda v: 255 if v > 50 else 0)
        img.paste(im, V(px, py), mask)
        names.append('part %d: sprite %d at %s' % (i, sp, 'x $B0, y $90' if i == 0 else 'the body %+d, %+d' % (
            r[0] - 256 if r[0] > 127 else r[0], r[1] - 256 if r[1] > 127 else r[1])))
    # the path
    x, y, pts, pas = bx, by, [], 0
    p = 0
    while p + 1 < len(path) and path[p] != 0:
        c, v = path[p], path[p + 1]
        dx, dy = v >> 4, v & 15
        dx = dx - 16 if dx & 8 else dx
        dy = dy - 16 if dy & 8 else dy
        dx, dy = (8 if dx == 7 else dx), (8 if dy == 7 else dy)
        for _ in range(c):
            x, y = x + dx, y + dy
            pts.append(V(x + 12, y + 10))
            pas += 1
        p += 2
    if len(pts) > 1:
        d.line(pts, fill=CYA, width=2)
    p1 = recs[1]
    hx, hy = (bx + p1[0]) & 0xFF, by + (p1[1] - 256 if p1[1] > 127 else p1[1])
    d.rectangle(V(hx, hy) + V(hx + 48, hy + 42), outline=RED, width=2)
    sxy = V(bx - 24, (by + 52) & 0xFF)
    d.ellipse((sxy[0] - 5, sxy[1] - 5, sxy[0] + 5, sxy[1] + 5), outline=ORA, width=2)
    tx = ox + big.width + 16
    lines = [
        (K.TEXT, 'Five trap records, moved as one:'),
    ] + [(YEL, t) for t in names] + [
        (YEL, 'parts 1-4 follow the body every pass'),
        (K.TEXT, 'part 4\'s sprite toggles 43 / 44'),
        (CYA, 'cyan: the body\'s path, %d passes' % pas),
        (CYA, '  a loop (0 and the jump back)'),
        (RED, 'red: the hit box, 48 x 42 at part 1'),
        (RED, '  the bullet or the blast in it: a hit'),
        (RED, '  Rick touching it: he dies'),
        (ORA, 'orange: the shot starts at x - 24,'),
        (ORA, '  y + 52; one at a time, 50 passes'),
        (K.TEXT, '20 hits; a death of Rick sets 20 again'),
        (K.TEXT, 'at 0: 5000 points, effects 5 and 10,'),
        (K.TEXT, '  the parts fly off and blow up'),
    ]
    for j, (col, t) in enumerate(lines):
        d.text((tx, oy + 4 + 20 * j), t, fill=col, font=fs)
    d.text((14, oy + big.height + 10), 'Drawn from src/res/levels/level5 (sections, blocks, cells, sprites, '
           'fat-guy.bin, fat-guy-path.bin), view y 64-263 (the view top row 0).', fill=K.DIM, font=fs)
    img = img.crop((0, 0, W, max(oy + big.height + 34, oy + 20 * len(lines) + 20)))
    img.save(a.out)
    print(a.out, img.size, 'path passes', pas)


def fig_stats(a):
    """per level: the map entries by what they place, the deadly traps, the trigger boxes by who sets them off"""
    print('| Level | Enemies (patrol / chaser / climber) | Trap entries (deadly) | Treasures | Ammunition | '
          'Detonators | Bonus start / stop | Trigger boxes: Rick / bullet / blast / punch / enemy / trap / each pass |')
    print('| ---: | --- | --- | ---: | ---: | ---: | --- | --- |')
    for n in range(1, 6):
        b = FR.level_bytes(n)
        L = level_labels(n)
        kinds, recs = b['level/kinds.bin'], b['level/kinds-2.bin']
        en = [0, 0, 0, 0]
        traps = deadly = tre = amm = det = bs = be = 0
        who = [0] * 7
        for ln in open(os.path.join(CASE, 'src', 'res', 'levels', 'level%d' % n, 'level', 'sections.txt')):
            m = re.match(r'object kind=\$([0-9A-F]{2}) ', ln)
            if m:
                k = int(m.group(1), 16)
                if k == 0x78:
                    bs += 1
                elif k == 0x7C:
                    be += 1
                elif k >= 0x74:
                    en[k & 3] += 1
                elif 'treasure' in ln:
                    tre += 1
                elif 'ammunition' in ln:
                    amm += 1
                elif 'detonators' in ln:
                    det += 1
                else:
                    traps += 1
                    ra = kinds[2 * k] | kinds[2 * k + 1] << 8
                    deadly += recs[ra - L['KindRecords'] + 2] >> 6 & 1
                continue
            m = re.match(r'\s+box .*who=\$([0-9A-F]{2})', ln)
            if m:
                w = int(m.group(1), 16)
                for bit in range(7):
                    who[bit] += w >> bit & 1
        print('| %d | %d (%d / %d / %d) | %d (%d) | %d | %d | %d | %d / %d | %s |' % (
            n, sum(en), en[1], en[2], en[3] + en[0], traps, deadly, tre, amm, det, bs, be,
            ' / '.join(str(v) for v in who)))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('anim')
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--slow', type=int, default=2, help='each picture shown this many times its real time')
    p.add_argument('--chart', default='rick', choices=('rick', 'bullet', 'detonator'))
    p.add_argument('--title', default='')
    p.add_argument('out')
    p.set_defaults(fn=fig_anim)
    p = sub.add_parser('jump')
    p.add_argument('--work')
    p.add_argument('--window', default='')
    p.add_argument('out')
    p.set_defaults(fn=fig_jump)
    p = sub.add_parser('fuse')
    p.add_argument('--work')
    p.add_argument('--window', default='')
    p.add_argument('out')
    p.set_defaults(fn=fig_fuse)
    p = sub.add_parser('traps')
    p.add_argument('--level', type=int, required=True)
    p.add_argument('out')
    p.set_defaults(fn=fig_traps)
    p = sub.add_parser('fatguy')
    p.add_argument('out')
    p.set_defaults(fn=fig_fatguy)
    p = sub.add_parser('stats')
    p.set_defaults(fn=fig_stats, out='.')
    a = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    a.fn(a)


if __name__ == '__main__':
    main()
