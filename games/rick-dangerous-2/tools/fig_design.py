#!/usr/bin/env python3
"""The figures of doc 01 (game design), drawn from the case's screenshots, the resources and the RZX run's logs.

    python3 tools/fig_design.py screens docs/img/design/screens.png
    python3 tools/fig_design.py hud docs/img/design/hud.png
    python3 tools/fig_design.py sections N docs/img/design/levelN-sections.png   (N = 1-5; needs ROOMS, below)
    python3 tools/fig_design.py cast docs/img/design/cast.png
    python3 tools/fig_design.py moments docs/img/design/moments.png
    python3 tools/fig_design.py route docs/img/design/route.png

screens: the screenshots of docs/img/play (WALKTHROUGH 6.1) and the CONGRATULATIONS end (`end-congrats` frame
2500), 3 a row. hud: the top row of `c1` frame 16 200 at 4 x with each field named. sections: every section of
level N as tools/fig_rooms.py draws it at scale 1 (ROOMS = work/docs/wr/rooms1, made by `python3 tools/fig_rooms.py
work/docs/wr/rooms1 --scale 1`), packed 4 a row, each with its exits. cast: sprites 27-39 of every level (the
treasure and the enemies) and level 5's Fat Guy, from src/res/levels/levelN/level/sprites.png. moments: screens of
the RZX run (work/stage1/rzx/lN/screens.bin, one every 25 frames) at the frames listed in MOMENTS. route: the section
and the score of the RZX run over its frames, from work/stage1/rzx/lN/mem.bin (the 64 K every 250 frames).
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import zxscreen  # noqa: E402

W = 1050
BG, TEXT, DIM = K.BACKGROUND, K.TEXT, K.DIM
ROOMS = os.path.join(CASE, 'work', 'docs', 'wr', 'rooms1')


def text_size(d, s, f):
    b = d.textbbox((0, 0), s, font=f)
    return b[2] - b[0], b[3] - b[1]


def title(img, s, size=18):
    d = ImageDraw.Draw(img)
    d.text((12, 10), s, font=K.font(size), fill=TEXT)


def play(name):
    return Image.open(os.path.join(CASE, 'docs', 'img', 'play', name)).convert('RGB')


def rec_screen(rec, frame):
    with open(os.path.join(CASE, 'work', rec, 'screens', '%06d.scr' % frame), 'rb') as f:
        return zxscreen.render(f.read(6912), 2).convert('RGB')


def rzx_screen(level, frame):
    with open(os.path.join(CASE, 'work', 'stage1', 'rzx', 'l%d' % level, 'screens.bin'), 'rb') as f:
        f.seek(frame // 25 * 6912)
        return zxscreen.render(f.read(6912), 2).convert('RGB')


def grid(panels, cols, out, head, pw=336):
    """panels: (image, caption lines); scaled to pw wide, cols a row"""
    ph = pw * 3 // 4
    f = K.font(13)
    cap_h = 40
    rows = (len(panels) + cols - 1) // cols
    gap = (W - cols * pw) // (cols + 1)
    img = Image.new('RGB', (W, 44 + rows * (ph + cap_h + 10)), BG)
    title(img, head)
    d = ImageDraw.Draw(img)
    for i, (im, cap) in enumerate(panels):
        x = gap + (i % cols) * (pw + gap)
        y = 44 + (i // cols) * (ph + cap_h + 10)
        img.paste(im.resize((pw, ph), Image.LANCZOS), (x, y))
        for k, line in enumerate(cap.split('\n')):
            d.text((x, y + ph + 3 + 16 * k), line, font=f, fill=TEXT if k == 0 else DIM)
    img.save(out)


def fig_screens(out):
    panels = [
        (play('loading-screen.png'), 'the loading screen\nside A block 5, $4000'),
        (play('control-menu.png'), 'the control menu ($80B5)\nrzx-l5-full 11 750'),
        (play('level-menu.png'), 'the level menu ($7F44), level 5 open\nrzx-l5-full 12 750'),
        (play('tape-start-side-two.png'), 'START TAPE ON SIDE TWO ($840C)\nload-l3 1000'),
        (play('tape-stop-press-fire.png'), 'STOP TAPE AND PRESS FIRE\nload-l3 18 000'),
        (play('level1-start.png'), 'level 1, Hyde Park London, the start\nc1 16 200'),
        (play('level2-start.png'), 'level 2, the Ice Caverns of Freezia\nload-l2 13 750'),
        (play('level3-start.png'), 'level 3, the Forests of Vegetablia\nload-l3 20 000'),
        (play('level4-start.png'), 'level 4, the Atomic Mud Mines\nload-l4 26 500'),
        (play('level5-start.png'), "level 5, the Fat Guy's headquarters\nrzx-l5-full 250"),
        (play('game-over.png'), 'GAME OVER ($7E1E)\nrzx-l5-full 11 500'),
        (rec_screen('stage2/rec/end-congrats', 2500), 'CONGRATULATIONS ($8754)\nend-congrats 2500'),
        (play('level5-fat-guy.png'), 'the Fat Guy (level 5 section 7)\nrzx-l5-22000-poke 250'),
        (play('ending.png'), 'the ending ($883D)\nrzx-l5-24000-poke 250'),
    ]
    grid(panels, 3, out, 'Every screen of Rick Dangerous 2, in the order a player meets them (128K)')


HUD = [  # (first column, last column, colour name, what, address)
    (1, 6, 'white $47', 'the score, six digits', '$7F1D-$7F22, DrawScore $7A0C'),
    (9, 14, 'red $42', 'detonators (glyph 11)', '$8B3D, $79DF'),
    (17, 22, 'magenta $43', 'ray gun bolts (glyph 10)', '$8B3C, $79D1'),
    (25, 30, 'green $44', 'lives (glyph 12)', '$8B3B, $79C3'),
]


def fig_hud(out):
    s = play('level1-start.png').resize((256, 192), Image.NEAREST)
    z = 4
    strip = s.crop((0, 0, 256, 8)).resize((256 * z, 8 * z), Image.NEAREST)
    x0 = (W - 256 * z) // 2
    img = Image.new('RGB', (W, 300), BG)
    title(img, 'The HUD: screen row 0, four fields (c1 frame 16 200, a new game: 000000, 6 / 6 / 6)')
    img.paste(strip, (x0, 60))
    d = ImageDraw.Draw(img)
    f = K.font(13)
    for k, (c0, c1, col, what, addr) in enumerate(HUD):
        a, b = x0 + c0 * 8 * z, x0 + (c1 + 1) * 8 * z
        y = 60 + 8 * z + 6
        d.line([(a, y), (b - 1, y)], fill=TEXT, width=2)
        d.line([(a, y - 4), (a, y + 4)], fill=TEXT, width=2)
        d.line([(b - 1, y - 4), (b - 1, y + 4)], fill=TEXT, width=2)
        ty = y + 10 + (k % 2) * 62
        d.line([((a + b) // 2, y), ((a + b) // 2, ty)], fill=DIM)
        d.text((a, ty), 'columns %d-%d, %s' % (c0, c1, col), font=f, fill=TEXT)
        d.text((a, ty + 16), what, font=f, fill=TEXT)
        d.text((a, ty + 32), addr, font=f, fill=DIM)
    for c in range(0, 33, 4):
        d.text((x0 + c * 8 * z - 4, 42), str(c), font=K.font(11), fill=DIM)
    img.save(out)


def fig_sections(level, out):
    import re
    files = sorted((int(re.search(r'-s(\d+)\.png', f).group(1)), f) for f in os.listdir(ROOMS)
                   if f.startswith('level%d-s' % level))
    exits = section_exits(level)
    f = K.font(13)
    pw, gap, cols = 256, 8, 4
    left = (W - cols * pw - (cols - 1) * gap) // 2
    # shelf packing: the next section goes into the shortest column
    heights = [52] * cols
    place = []
    for s, name in files:
        im = Image.open(os.path.join(ROOMS, name)).convert('RGB')
        c = heights.index(min(heights))
        place.append((s, im, c, heights[c]))
        heights[c] += 20 + im.size[1] + 22 * max(1, len(wrap(exits.get(s, ''), 34))) + 14
    img = Image.new('RGB', (W, max(heights) + 10), BG)
    title(img, 'Level %d: every section as the screen can show it (%d sections, drawn from src/res)' %
          (level, len(files)))
    d = ImageDraw.Draw(img)
    for s, im, c, y in place:
        x = left + c * (pw + gap)
        d.text((x, y), 'section %d' % s, font=f, fill=TEXT)
        img.paste(im, (x, y + 18))
        for k, line in enumerate(wrap(exits.get(s, ''), 34)):
            d.text((x, y + 20 + im.size[1] + 2 + 16 * k), line, font=f, fill=DIM)
    img.save(out)


def wrap(s, n):
    out, line = [], ''
    for w in s.split():
        if len(line) + len(w) + 1 > n:
            out.append(line)
            line = w
        else:
            line = (line + ' ' + w).strip()
    if line:
        out.append(line)
    return out


def section_exits(level):
    """{section: 'R30>2 L74>0 ...'} from sections.txt"""
    path = os.path.join(CASE, 'src', 'res', 'levels', 'level%d' % level, 'level', 'sections.txt')
    out, cur = {}, None
    for line in open(path):
        if line.startswith('# +$') and 'exits of section' in line:
            cur = int(line.split('exits of section')[1].split()[0])
        elif line.startswith('exit ') and cur is not None:
            kv = dict(t.split('=') for t in line.split(';')[0].split()[1:])
            fl, row, to = int(kv['flags'][1:], 16), int(kv['row']), int(kv['to'])
            side = 'L' if fl & 3 == 1 else 'R'
            if fl & 0x80 and not fl & 0x10:
                tag = '%s%d>END (cheat: %d)' % (side, row, to)
            elif fl & 0x80:
                tag = '%s%d>END' % (side, row)
            else:
                tag = '%s%d>%d' % (side, row, to)
            if fl & 0x20:
                tag += ' bike'
            if fl & 0x40:
                tag += ' FatGuy'
            out[cur] = (out.get(cur, '') + ' ' + tag).strip()
    return out


def sprite_cell(sheet, n, z=3):
    cx, cy = (n % 8) * 25 + 1, (n // 8) * 22 + 1
    im = sheet.crop((cx, cy, cx + 24, cy + 21))
    px = im.load()
    out = Image.new('RGB', (24, 21))
    o = out.load()
    for y in range(21):
        for x in range(24):
            v = px[x, y]
            o[x, y] = {0: (0, 0, 0), 1: (240, 240, 240), 3: (40, 40, 52), 4: (230, 70, 70)}.get(v, (40, 40, 52))
    return out.resize((24 * z, 21 * z), Image.NEAREST)


CAST = {1: list(range(27, 40)), 2: list(range(27, 40)), 3: list(range(27, 40)), 4: list(range(27, 40)),
        5: list(range(27, 40))}
ROLE = {27: 'treasure', 28: 'walk', 29: 'walk', 30: 'walk', 31: 'dying', 32: 'climb', 33: 'climb',
        34: 'set 2', 35: 'set 2', 36: 'set 2', 37: 'set 2', 38: 'set 2', 39: 'set 2'}


def fig_cast(out):
    z = 2
    sw, sh = 24 * z, 21 * z
    f = K.font(12)
    left = 120
    gap = (W - left - 10 - 13 * sw) // 12
    rows = 6
    img = Image.new('RGB', (W, 70 + rows * (sh + 26) + 20), BG)
    title(img, 'The cast: the treasure (sprite 27), the enemies (28-39) per level, the Fat Guy')
    d = ImageDraw.Draw(img)
    for k, n in enumerate(range(27, 40)):
        d.text((left + k * (sw + gap), 40), str(n), font=f, fill=DIM)
    for lv in range(1, 6):
        sheet = Image.open(os.path.join(CASE, 'src', 'res', 'levels', 'level%d' % lv, 'level', 'sprites.png'))
        y = 62 + (lv - 1) * (sh + 26)
        d.text((10, y + 12), 'level %d' % lv, font=K.font(14), fill=TEXT)
        for k, n in enumerate(CAST[lv]):
            img.paste(sprite_cell(sheet, n, z), (left + k * (sw + gap), y))
    sheet = Image.open(os.path.join(CASE, 'src', 'res', 'levels', 'level5', 'level', 'sprites.png'))
    y = 62 + 5 * (sh + 26)
    d.text((10, y + 12), 'Fat Guy', font=K.font(14), fill=TEXT)
    for k, n in enumerate(list(range(40, 46)) + [62]):
        img.paste(sprite_cell(sheet, n, z), (left + k * (sw + gap), y))
        d.text((left + k * (sw + gap), y + sh + 2), str(n) if n != 62 else '62 shot', font=f, fill=DIM)
    d.text((10, 62 + 5 * (sh + 26) - 14), '27 treasure; enemies: walk 28-30, dying 31, climb 32-33; the second set '
           '34-39 (the same roles +6) when the kind has bit 2 clear', font=f, fill=DIM)
    img.save(out)


MOMENTS = [  # (level, RZX frame, caption)
    (1, 975, 'L1 s0: the first enemy shot\n(ammo 6->5, +50 by 1000)'),
    (1, 1500, 'L1 s3: a treasure room\n(score 50 -> 550)'),
    (1, 2300, 'L1 s2: crawling\n(RickCrawling $9B98 set at 2250)'),
    (1, 3250, 'L1 s5: on a ladder\n(RickClimbing $9B99 set)'),
    (1, 5500, 'L1 s5: a detonator burning\n(DetonatorOn $9BBD set)'),
    (1, 5750, 'L1 s5: a punch\n(PunchTimer $9BA3 set)'),
    (2, 21300, 'L2 s5: the anti-gravity bike\n(RideMode $945D = $FF)'),
    (4, 11100, 'L4 s4: the bike in the mud mines\n(RideMode set 11 000-12 750)'),
    (5, 20800, 'L5 s7: the Fat Guy\n(LevelHookOn $8A24 set from 20 750)'),
    (5, 25000, 'the end text after the tally\n(score 803 440)'),
]


def fig_moments(out):
    panels = [(rzx_screen(lv, fr), '%s\nRZX level %d, frame %d' % (cap.split('\n')[0], lv, fr) + '\n' +
               cap.split('\n')[1]) for lv, fr, cap in MOMENTS]
    pw = 336
    ph = pw * 3 // 4
    f = K.font(13)
    cols, cap_h = 3, 56
    rows = (len(panels) + cols - 1) // cols
    gap = (W - cols * pw) // (cols + 1)
    img = Image.new('RGB', (W, 44 + rows * (ph + cap_h + 8)), BG)
    title(img, 'Key moments of a game: the RZX run (someone else\'s play), screens every 25 frames')
    d = ImageDraw.Draw(img)
    for i, (im, cap) in enumerate(panels):
        x = gap + (i % cols) * (pw + gap)
        y = 44 + (i // cols) * (ph + cap_h + 8)
        img.paste(im.resize((pw, ph), Image.LANCZOS), (x, y))
        for k, line in enumerate(cap.split('\n')):
            d.text((x, y + ph + 2 + 16 * k), line, font=f, fill=TEXT if k == 0 else DIM)
    img.save(out)


def fig_route(out):
    f = K.font(12)
    panel_h, top = 190, 70
    img = Image.new('RGB', (W, top + 5 * (panel_h + 44)), BG)
    title(img, 'The RZX run\'s route: the section Rick is in ($9B93) over each level\'s frames, and the score')
    d = ImageDraw.Draw(img)
    counts = [9, 13, 10, 13, 8]
    left, right = 70, W - 90
    for lv in range(1, 6):
        m = open(os.path.join(CASE, 'work', 'stage1', 'rzx', 'l%d' % lv, 'mem.bin'), 'rb').read()
        n = len(m) // 65536
        y0 = top + (lv - 1) * (panel_h + 44)
        frames = n * 250
        sx = (right - left) / 27000
        d.rectangle([left, y0, right, y0 + panel_h], outline=(60, 60, 75))
        d.text((left, y0 - 18), 'level %d (%d sections)' % (lv, counts[lv - 1]), font=K.font(14), fill=TEXT)
        sc = counts[lv - 1]
        sy = (panel_h - 10) / (sc - 1)
        for s in range(sc):
            yy = y0 + panel_h - 5 - s * sy
            d.line([(left, yy), (right, yy)], fill=(34, 34, 44))
            d.text((left - 26, yy - 7), str(s), font=f, fill=DIM)
        pts, spts = [], []
        smax = None
        scores = []
        for i in range(n):
            s = m[i * 65536:(i + 1) * 65536]
            if s[0x7EF1] != lv:
                continue
            sec = s[0x9B93]
            score = int(''.join(str(b) for b in s[0x7F1D:0x7F23]))
            pts.append((left + i * 250 * sx, y0 + panel_h - 5 - sec * sy))
            scores.append((i * 250, score))
        for a, b in zip(pts, pts[1:]):
            d.line([a, (b[0], a[1]), b], fill=(240, 200, 70), width=3)
        if scores:
            lo, hi = scores[0][1], max(sc_ for _, sc_ in scores)
            span = max(1, hi - lo)
            sp = [(left + fr * sx, y0 + panel_h - 5 - (v - lo) / span * (panel_h - 10)) for fr, v in scores]
            for a, b in zip(sp, sp[1:]):
                d.line([a, b], fill=(90, 150, 250), width=1)
            d.text((right + 6, y0 + 4), '%d' % hi, font=f, fill=(90, 150, 250))
            d.text((right + 6, y0 + panel_h - 16), '%d' % lo, font=f, fill=(90, 150, 250))
        for t in range(0, 27001, 5000):
            d.text((left + t * sx - 10, y0 + panel_h + 2), str(t), font=f, fill=DIM)
        d.text((right - 200, y0 + panel_h + 14), 'RZX frames (%d in this file)' % frames, font=f, fill=DIM)
    d.text((12, 34), 'yellow: the section (left scale); blue: the score (right scale, from the level\'s first to its highest)', font=f, fill=TEXT)
    img.save(out)


def main():
    what, *args = sys.argv[1:]
    if what == 'screens':
        fig_screens(args[0])
    elif what == 'hud':
        fig_hud(args[0])
    elif what == 'sections':
        fig_sections(int(args[0]), args[1])
    elif what == 'cast':
        fig_cast(args[0])
    elif what == 'moments':
        fig_moments(args[0])
    elif what == 'route':
        fig_route(args[0])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
