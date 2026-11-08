#!/usr/bin/env python3
"""The ships in motion, drawn by the game's own code (tools/shipsim.py: the title loop's ClearView and TurnTitleShip
run in a Z80 simulator on a recorded title memory), for docs/01-game-design.md, docs/07-objects.md and
docs/06-rendering.md.

    python3 tools/fig_ships_anim.py [gallery] [hidden] [approach] [proof] [titles] [station]   # all when none named
    python3 tools/fig_ships_anim.py one [N ...]                                                # docs/ships.md

- docs/img/ships/gallery.gif: the 19 blueprints turning together, each at the nearest whole page of distance at
  which its picture stays inside the view, with its name, its number and that distance;
- docs/img/ships/gallery.png: the same, one still (the 10th picture), for print;
- docs/img/ships/hidden.gif: the Cobra Mk III with the game's face test (left) and with every face counted visible
  (right: FaceVisibility answered "all"), the hidden edges the test removes;
- docs/img/ships/approach.gif: a Viper flying in from 31 pages to 2: the dot (four pixels) beyond the blueprint's
  dot distance, then the wireframe, its far vertices and edges dropped by the detail level until it is near;
- docs/img/ships/proof.png: one title pass of d1 (the trace 116_30000-122_48700): the back buffer the emulator
  drew next to the one the simulator draws from the trace's first memory, and their difference;
- docs/img/ships/titles.png: the eight title ships as the emulator drew them (work/titleproof, written by
  tools/title_proof.py from a live instance) overlaid with the simulator's, pixel by pixel;
- docs/img/ships/station.gif: the Coriolis station turning, its slot (the door) facing round;
- docs/img/ships/one/<nn>-<name>.gif (`one`): each blueprint alone at 2x, through one closed loop on two axes,
  its header in the title (docs/ships.md).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import shipsim  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

OUT = os.path.join(shipsim.CASE, 'docs', 'img', 'ships')
INK = (235, 235, 245)
BG = (14, 14, 20)
LABEL = (150, 200, 255)
DIM = (120, 120, 135)


def picture(rows, colour=INK, crop=None):
    w, h = len(rows[0]), len(rows)
    im = Image.new('RGB', (w, h), BG)
    px = im.load()
    for y, r in enumerate(rows):
        for x, v in enumerate(r):
            if v:
                px[x, y] = colour
    return im.crop(crop) if crop else im


_EMPTY = []


def empty():
    """the view ClearView leaves: the frame (rows 0 and 127, the columns 8 and 247)"""
    if not _EMPTY:
        s = shipsim.Ship(4)
        s.call('ClearView')
        _EMPTY.append(shipsim.back_buffer(s.mem))
    return _EMPTY[0]


def fit_distance(n, steps=16):
    """the nearest page (1-12) at which the ship's own pixels stay 3 pixels inside the view's frame for a turn"""
    e = empty()
    for d in range(1, 13):
        s = shipsim.Ship(n, distance=d)
        ok = True
        for _ in range(steps):
            p = s.step()
            for y in range(128):
                for x in range(256):
                    if p[y][x] and not e[y][x] and (y < 4 or y > 123 or x < 12 or x > 243):
                        ok = False
                        break
                if not ok:
                    break
            if not ok:
                break
        if ok:
            return d
    return 12


# The view's frame ClearView draws (columns 8 and 247, rows 0 and 127) is cropped off the cells: inside it the
# ship is drawn, so the crop shows the view without its border.
VIEW = (9, 1, 247, 127)


def gallery(frames=48):
    """5 columns of 238 x 126 views at 1:1, labels on two lines; 1220 px wide, so 13 px text at 900 px"""
    font, small, big = K.font(18), K.font(16), K.font(20)
    cols, cw, vw, vh = 5, 244, 238, 126
    ch = vh + 52
    ships = []
    for n in range(19):
        d = fit_distance(n)
        ships.append((n, d, shipsim.Ship(n, distance=d)))
        print('blueprint %d %s: distance %d' % (n, shipsim.NAMES[n], d))
    pics = []
    for f in range(frames):
        im = Image.new('RGB', (cols * cw, 40 + 4 * ch), BG)
        dr = ImageDraw.Draw(im)
        dr.text((6, 8), 'The 19 blueprints drawn by the game\'s own code, each at the nearest page that fits',
                fill=INK, font=big)
        for n, d, s in ships:
            x, y = (n % cols) * cw, 40 + (n // cols) * ch
            im.paste(picture(s.step(), crop=VIEW), (x + 3, y))
            dr.rectangle((x + 2, y - 1, x + 3 + vw, y + vh), outline=(50, 50, 62))
            name, _, role = shipsim.NAMES[n].partition(' (')
            dr.text((x + 4, y + vh + 4), '%d %s' % (n, name), fill=LABEL, font=font)
            dr.text((x + 4, y + vh + 27), (role.rstrip(')') + ', ' if role else '') + 'z = %d page%s'
                    % (d, 's' if d > 1 else ''), fill=DIM, font=small)
        pics.append(im)
    K.save_gif(os.path.join(OUT, 'gallery.gif'), pics, [100] * len(pics))
    pics[9].save(os.path.join(OUT, 'gallery.png'))
    print('wrote docs/img/ships/gallery.gif, gallery.png')


def hidden(frames=40):
    """two views at 2x, one above the other's title: 1000 px wide"""
    font, small = K.font(17), K.font(15)
    a, b = shipsim.Ship(9, distance=1), shipsim.Ship(9, distance=1, hidden=False)
    pics = []
    W = 2 * 476 + 24
    for f in range(frames):
        im = Image.new('RGB', (W, 252 + 70), BG)
        dr = ImageDraw.Draw(im)
        pa, pb = a.step(), b.step()
        both = [[1 if v and not pa[y][x] else 0 for x, v in enumerate(r)] for y, r in enumerate(pb)]
        left = picture(pa, crop=VIEW)
        right = picture(pa)
        extra = picture(both, (240, 90, 90))
        mask = Image.new('L', (256, 128))
        mask.putdata([255 * v for r in both for v in r])
        right.paste(extra, (0, 0), mask)
        right = right.crop(VIEW)
        im.paste(left.resize((476, 252), Image.NEAREST), (0, 34))
        im.paste(right.resize((476, 252), Image.NEAREST), (476 + 24, 34))
        dr.text((4, 6), 'with the face test, as the game draws', fill=LABEL, font=font)
        dr.text((476 + 28, 6), 'every face visible: hidden edges in red', fill=(240, 90, 90), font=font)
        dr.text((4, 294), 'Cobra Mk III at 1 page: an edge is drawn when one of its two faces is visible '
                          '(FaceVisibility $BCD4)', fill=DIM, font=small)
        pics.append(im)
    K.save_gif(os.path.join(OUT, 'hidden.gif'), pics, [110] * len(pics))
    print('wrote docs/img/ships/hidden.gif')


def approach():
    """2x, the caption on two lines inside the picture"""
    font, small = K.font(17), K.font(15)
    s = shipsim.Ship(8, distance=31, rates=(0x82, 0x83))
    m, s7 = s.mem, s.slot
    pics = []
    z = 31 * 256
    while z >= 2 * 256:
        m[s7 + 6], m[s7 + 7] = z & 0xFF, z >> 8
        p = s.step()
        im = Image.new('RGB', (476, 252 + 56), BG)
        im.paste(picture(p, crop=VIEW).resize((476, 252), Image.NEAREST), (0, 0))
        dr = ImageDraw.Draw(im)
        far = z >> 8 > s.mem[shipsim.labels()['ShipViper'] + 0x0B]
        kind = 'a dot: beyond its dot distance' if far else 'wireframe, detail level %d' % max(0, min(z >> 7, 31) - 2)
        dr.text((6, 258), 'Viper at z %d (%d pages)' % (z, z >> 8), fill=LABEL, font=font)
        dr.text((6, 282), kind, fill=DIM, font=small)
        pics.append(im)
        z -= 96 if z > 8 * 256 else 48
    K.save_gif(os.path.join(OUT, 'approach.gif'), pics, [90] * (len(pics) - 1) + [1500])
    print('wrote docs/img/ships/approach.gif (%d pictures)' % len(pics))


def _real(path):
    m = bytearray(0x10000)
    m[0xC000:0xD000] = open(path, 'rb').read()
    return shipsim.back_buffer(m)


def proof():
    """d1's title pass: the emulator, the simulator, the two overlaid (white both, red emulator only, green
    simulator only); 2 rows so each view is 476 px wide"""
    trace = K.access_trace().load(os.path.join(shipsim.CASE, 'work', 'd1', 'traces', '116_30000-122_48700.uatr'))
    first = bytearray(trace.memory_at(0))
    last = trace.memory_at(len(trace.instructions) - 1)
    s = shipsim.Ship(9, mem=first)
    s.mem[:] = first
    p = s.step(('TitleTextPress',))
    real = shipsim.back_buffer(last)
    nd = sum(a != b for r1, r2 in zip(p, real) for a, b in zip(r1, r2))
    font, small = K.font(17), K.font(15)
    im = Image.new('RGB', (2 * 476 + 24, 252 + 74), BG)
    dr = ImageDraw.Draw(im)
    im.paste(picture(real, INK, VIEW).resize((476, 252), Image.NEAREST), (0, 34))
    im.paste(overlay(real, p).crop(VIEW).resize((476, 252), Image.NEAREST), (500, 34))
    dr.text((4, 6), 'the emulator: d1 frame 122', fill=LABEL, font=font)
    dr.text((504, 6), 'the simulator over it: %d pixels differ' % nd, fill=(120, 230, 140), font=font)
    dr.text((4, 296), 'One title pass (ClearView, TitleTextPress, TurnTitleShip) run again from the trace\'s first '
                      'memory', fill=DIM, font=small)
    im.save(os.path.join(OUT, 'proof.png'))
    print('wrote docs/img/ships/proof.png: %d pixels differ' % nd)


def overlay(real, sim):
    """white where both set a pixel, red the emulator only, green the simulator only"""
    im = Image.new('RGB', (256, 128), BG)
    px = im.load()
    for y in range(128):
        for x in range(256):
            a, b = real[y][x], sim[y][x]
            if a or b:
                px[x, y] = INK if a and b else ((240, 90, 90) if a else (120, 230, 140))
    return im


def titles():
    """the eight title ships of the emulator (work/titleproof, tools/title_proof.py) against the simulator"""
    font, small, big = K.font(17), K.font(15), K.font(20)
    names = ['Cobra Mk III', 'Python', 'Asp Mk II', 'Fer-de-Lance', 'Thargoid', 'Sidewinder', 'Krait', 'Viper']
    cw, vw, vh = 312, 304, 161
    im = Image.new('RGB', (4 * cw, 44 + 2 * 160 + 30), BG)
    dr = ImageDraw.Draw(im)
    total = 0
    for i in range(8):
        d = os.path.join(shipsim.CASE, 'work', 'titleproof')
        mem = bytearray(open(os.path.join(d, '%d-mem.bin' % i), 'rb').read())
        real = _real(os.path.join(d, '%d-real.bin' % i))
        s = shipsim.Ship(9, mem=mem)
        s.mem[:] = mem
        sim = s.step(('TitleTextLoad',) if i == 0 else ('TitleTextPress',))
        nd = sum(a != b for r1, r2 in zip(sim, real) for a, b in zip(r1, r2))
        total += nd
        x, y = (i % 4) * cw, 44 + (i // 4) * 160
        im.paste(overlay(real, sim).crop((9, 16, 247, 112)).resize((vw, int(vw * 96 / 238)), Image.NEAREST),
                 (x + 4, y))
        dr.text((x + 6, y + 126), '%s: %d px differ' % (names[i], nd), fill=LABEL, font=font)
    dr.text((6, 8), 'The 8 title ships: the emulator\'s back buffer and the simulator\'s, overlaid: %d pixels differ'
            % total, fill=INK, font=big)
    dr.text((6, im.height - 26), 'white: both; red: only the emulator; green: only the simulator (none). '
                                 'python3 tools/title_proof.py, then tools/fig_ships_anim.py titles', fill=DIM, font=small)
    im.save(os.path.join(OUT, 'titles.png'))
    print('wrote docs/img/ships/titles.png: %d pixels differ' % total)


def station(steps=200, every=4):
    """docs/img/ships/station.gif: the Coriolis with its nose (the slot's face) at the viewer, rolled by the game's
    TurnOwn at roll 4 a step (TurnRates `$84`, no pitch); the pictures repeat exactly after 200 steps"""
    font, small = K.font(17), K.font(14)
    s = shipsim.Ship(0, distance=fit_distance(0), rates=(0x80, 0x84))
    s.mem[s.slot + 9:s.slot + 27] = axes_bytes(0, 0)
    pics = []
    for f in range(steps):
        q = s.step()
        if f % every:
            continue
        title = wrap('The Coriolis rolling about its nose, the slot facing the viewer', font, 476 - 8)
        top = 6 + 22 * len(title) + 6
        im = Image.new('RGB', (476, top + 252 + 24), BG)
        dr = ImageDraw.Draw(im)
        for i, line in enumerate(title):
            dr.text((4, 6 + 22 * i), line, fill=LABEL, font=font)
        im.paste(picture(q, crop=VIEW).resize((476, 252), Image.NEAREST), (0, top))
        dr.rectangle((0, top, 475, top + 251), outline=(50, 50, 62))
        dr.text((4, top + 256), 'roll 4 a step, a turn in %d steps, every %dth shown' % (steps, every), fill=DIM,
                font=small)
        pics.append(im)
    K.save_gif(os.path.join(OUT, 'station.gif'), pics, [80] * len(pics))
    print('wrote docs/img/ships/station.gif, %d KB' % (os.path.getsize(os.path.join(OUT, 'station.gif')) // 1024))


SLUGS = ['coriolis', 'missile', 'escape-pod', 'plate', 'canister', 'splinter', 'asteroid', 'rock-hermit', 'viper',
         'cobra-trader', 'python-trader', 'python-pirate', 'cobra-pirate', 'asp', 'fer-de-lance', 'thargoid',
         'sidewinder', 'krait', 'thargon']
LAUNCHED = {0: ('missile', 'missiles'), 1: ('Viper', 'Vipers'), 2: ('trader', 'traders'), 3: ('Thargon', 'Thargons'),
            4: ('Thargoid', 'Thargoids'), 5: ('Sidewinder or Krait', 'Sidewinders or Kraits')}


def header(mem, n):
    """blueprint n's 23-byte header and its address, from the table Blueprints $6180 in the title memory"""
    e = shipsim.labels()['Blueprints'] + 4 * n
    a = mem[e + 1] | mem[e + 2] << 8
    return a, bytes(mem[a:a + 23])


def one_title(n, a, h):
    """the title's lines: the name and number, the counts, the weapons and the bounty"""
    parts = ['%s: blueprint %d at $%04X' % (shipsim.NAMES[n], n, a),
             '%d vertices, %d edges, %d faces' % (h[3], h[4], h[5])]
    extra = []
    if h[2]:
        extra.append('laser %d of 255' % h[2])
    if h[0x0A] & 7:
        k = h[0x0A] & 7
        extra.append('%d %s' % (k, LAUNCHED[h[0x0A] >> 4][k > 1]))
    bounty = h[8] | h[9] << 8
    if bounty:
        extra.append('bounty %d.%d Cr' % (bounty // 10, bounty % 10))
    return parts + ([', '.join(extra)] if extra else [])


def diff(p, q):
    return sum(a != b for r0, r1 in zip(p, q) for a, b in zip(r0, r1))


def axes_bytes(yaw, roll):
    """the nose, roof and side vectors (sign and magnitude words, $7FFF one) of a ship whose nose points at the
    viewer, turned by yaw then roll (radians): the start the catalogue's turns use in place of the title's axes"""
    import math
    cy, sy, cr, sr = math.cos(yaw), math.sin(yaw), math.cos(roll), math.sin(roll)

    def turned(v):                          # yaw about y, then roll about z
        x, y, z = v
        x, z = cy * x + sy * z, -sy * x + cy * z
        return cr * x - sr * y, sr * x + cr * y, z

    def word(c):
        m = int(round(abs(c) * 0x7FFF))
        return bytes([m & 0xFF, m >> 8 | (0x80 if c < 0 else 0)])
    return b''.join(word(c) for v in ((0, 0, -1), (0, 1, 0), (1, 0, 0)) for c in turned(v))


def one_loop(n, rates=(0x8A, 0x94), warm=300, most=80):
    """blueprint n turned from the title's axes by pitch 10 and roll 20 a step (the title's own roll; pitch `$8A`
    instead of `$8C`, the nearest rate whose turn closes). The first turns drift (MoveShip's small-angle steps);
    after `warm` steps the pictures repeat exactly, and the loop is the shortest period over which two loops'
    pictures at the nearest of 1, 3 or 6 pages where the ship shows are identical. Returns the ship, the memory at the loop's start, the loop's length and
    the faces seen in it."""
    e = empty()
    fv = shipsim.labels()['FaceVisible']
    for distance in (1, 3, 6):              # the nearest distance where every picture shows the ship
        s = shipsim.Ship(n, distance=distance, rates=rates)
        for _ in range(warm):
            s.step()
        start = bytes(s.mem)
        pics, seen = [], set()
        for _ in range(2 * most):
            pics.append(s.step())
            seen |= {i for i in range(16) if s.mem[fv + i]}
        if all(p != e for p in pics):
            break
    for k in range(8, most + 1):
        if all(pics[i] == pics[i + k] for i in range(2 * most - k)):
            return s, start, k, seen
    raise SystemExit('blueprint %d: no loop within %d steps' % (n, most))


def one_frames(s, start, z, steps):
    """the loop's pictures with the ship at z (in 256ths of a page); None when one touches the view's frame"""
    e = empty()
    s.mem[:] = start
    s.mem[s.slot + 6], s.mem[s.slot + 7] = z & 0xFF, z >> 8
    rows = []
    for _ in range(steps):
        p = s.step()
        if any(p[y][x] and not e[y][x] and (y < 4 or y > 123 or x < 12 or x > 243)
               for y in range(128) for x in range(256)):
            return None
        if p == e:                          # too near: the game does not draw it
            return None
        rows.append(p)
    return rows


def one(which=None):
    """docs/img/ships/one/<nn>-<name>.gif: each blueprint alone at 2x, turned on two axes by the game's own code
    through one closed loop, at the nearest quarter page where no picture touches the view's frame"""
    font, small = K.font(17), K.font(14)
    for n in (which if which is not None else range(19)):
        s, start, steps, seen = one_loop(n)
        for z in list(range(128, 512, 32)) + list(range(512, 13 * 256, 64)):
            rows = one_frames(s, start, z, steps)
            if rows:
                break
        a, h = header(s.mem, n)
        title = [w for part in one_title(n, a, h) for w in wrap(part, font, 476 - 8)]
        top = 6 + 22 * len(title) + 6
        pics = []
        for q in rows:
            im = Image.new('RGB', (476, top + 252 + 24), BG)
            dr = ImageDraw.Draw(im)
            for i, line in enumerate(title):
                dr.text((4, 6 + 22 * i), line, fill=LABEL if i == 0 else INK, font=font)
            im.paste(picture(q, crop=VIEW).resize((476, 252), Image.NEAREST), (0, top))
            dr.rectangle((0, top, 475, top + 251), outline=(50, 50, 62))
            dr.text((4, top + 256), 'z %.2f pages, pitch 10 and roll 20 a step, a loop of %d' % (z / 256, steps),
                    fill=DIM, font=small)
            pics.append(im)
        path = os.path.join(OUT, 'one', '%02d-%s.gif' % (n, SLUGS[n]))
        K.save_gif(path, pics, [100] * len(pics))
        faces = h[5]
        print('%s: z %d, %d steps, faces seen %d of %d, %d KB' % (
            os.path.relpath(path, shipsim.CASE), z, steps, len(seen & set(range(faces))), faces,
            os.path.getsize(path) // 1024))


def wrap(text, font, width):
    d = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    out, line = [], ''
    for word in text.split():
        cand = (line + ' ' + word).strip()
        if d.textlength(cand, font=font) > width and line:
            out.append(line)
            line = word
        else:
            line = cand
    return out + [line]


if __name__ == '__main__':
    todo = sys.argv[1:] or ['gallery', 'hidden', 'approach', 'proof', 'titles', 'station']
    if todo[0] == 'one':
        one([int(v) for v in todo[1:]] or None)
        sys.exit()
    for t in todo:
        globals()[t]()
