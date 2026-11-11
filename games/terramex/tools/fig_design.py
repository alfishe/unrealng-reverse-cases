#!/usr/bin/env python3
"""Doc 01's figures: the screens, the five explorers, the panel, the rooms as a contact sheet, the map with the RZX
route, the items.

    python3 tools/fig_design.py screens docs/img/design/screens.png
    python3 tools/fig_design.py explorers docs/img/design/explorers.png
    python3 tools/fig_design.py panel docs/img/design/panel.png
    python3 tools/fig_design.py rooms docs/img/design/rooms-1.png --levels 0-2
    python3 tools/fig_design.py rooms docs/img/design/rooms-2.png --levels 3-5
    python3 tools/fig_design.py map docs/img/design/map-route.png
    python3 tools/fig_design.py items docs/img/design/items.png
    python3 tools/fig_design.py moments docs/img/design/moments.png

screens and panel use the screenshots of the recordings (docs/img/play/*.png, 512 x 384, and the case's screen
dumps in work/docs/tmA: work/stage1/<recording>/screens/*.scr drawn at 1 x). explorers uses the five play screens of
the explorers recording (frames 1250, 3750, 6250, 9250, 11750, explorer 0-4) and the sprite sets src/res/sprites/
explorer-N.png. rooms draws every room from src/res with tools/fig_rooms.py's room_image, at 1 x, four a row, with its
number. map draws the 72 rooms by level and column (room = level x 12 + column) and the RZX run's route over them:
the room sequence of work/docs/tmA/route-events.txt (the RZX played in SkoolKit's simulator by tools/rzx_dump.py,
sampled every 25 RZX frames). items draws the 32 item sprites from src/res/sprites/items.png (via fig_rooms'
resources) with their names and marks the professor's six wishes (src/res/tables/wanted-items.csv).
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402
import fig_rooms  # noqa: E402

BG, TEXT, DIM, HI = (20, 20, 26), (235, 235, 235), (175, 175, 185), (255, 220, 90)
W = 1050
NAMES = ['Unicycle', 'Flashgun', 'Cricket Ball', 'Spurs', 'Beer Barrel', 'Umbrella', 'Bellows', 'Party Manifesto',
         'Cannon', 'Barrel Medium', 'Vacuum Cleaner', 'ACME Bridge', 'Flute', 'Silver Lining', 'Spring', 'Formula',
         'Switch', 'Button', 'Battery', 'Coat Hanger', 'Trampoline', 'Atomic Pile', 'Anti Rad. Pills', 'Cup of tea',
         'Energy Crystal', 'Basket', 'Balloon', 'Barrel Big', 'Barrel Small', 'Silver Cross', 'Basket 2', 'Lift']
EXPLORERS = ['Fortisque-Smithe', 'Herr Krusche', 'Henri Beaucoup', 'Big John Caine', 'Wu Pong']


def P(*parts):
    return os.path.join(CASE, *parts)


def title(d, text, sub=None):
    d.text((20, 14), text, font=kitlib.font(19), fill=TEXT)
    if sub:
        d.text((20, 42), sub, font=kitlib.font(13), fill=DIM)


def screens(args):
    shots = [('play/loading-screen.png', 'the loading screen (c1, block 3)'),
             ('play/menu.png', 'the device menu'),
             ('play/selector.png', 'the explorer selector (128K)'),
             ('play/help-1.png', 'Help, page 1: the story'),
             ('play/start-room-14.png', 'play: the first room, $14'),
             ('play/gameover-1700.png', 'the space scene: the strike (gameover 1700)'),
             ('play/ending-lab-r48000-1999.png', 'the lab $3B: the professor (rzx48000)'),
             ('play/ending-room-28-r50000-500.png', 'the ending: the asteroid deflected (rzx50000)'),
             ('play/help-3.png', 'Help, page 3: the controls')]
    cols, sw, sh = 3, 336, 252
    gap = (W - cols * sw) // (cols + 1)
    rows = (len(shots) + cols - 1) // cols
    H = 70 + rows * (sh + 34) + 10
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The screens of Terramex, from the recordings (128K)', 'Each 256 x 192 screen at 1.3 x; '
          'the label names the screen and its recording')
    f = kitlib.font(13)
    for i, (rel, lab) in enumerate(shots):
        x, y = gap + (i % cols) * (sw + gap), 66 + (i // cols) * (sh + 34)
        im = Image.open(P('docs', 'img', rel)).convert('RGB').resize((sw, sh), Image.LANCZOS)
        img.paste(im, (x, y))
        d.text((x, y + sh + 6), lab, font=f, fill=TEXT)
    img.save(args.out)
    print(args.out)


def explorers(args):
    frames = [1250, 3750, 6250, 9250, 11750]
    f, fs = kitlib.font(15), kitlib.font(13)
    rh = 64 * 2 + 30
    H = 66 + 5 * rh + 30
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The five explorers: each one\'s panel and sprite set',
          'Left: the panel in play (explorers recording, 2 x). Right: the set src/res/sprites/explorer-N.png, '
          'frames $00-$3F, 1.2 x')
    for i, fr in enumerate(frames):
        y = 66 + i * rh
        scr = Image.open(P('work', 'docs', 'tmA', 'exp', f'{fr:06d}.png')).convert('RGB')
        panel = scr.crop((0, 128, 256, 192)).resize((512, 128), Image.NEAREST)
        d.text((20, y), f'{i}: {EXPLORERS[i]}  (explorers frame {fr}, $5B70 = {i})', font=f, fill=HI)
        img.paste(panel, (20, y + 22))
        sheet = Image.open(P('src', 'res', 'sprites', f'explorer-{i}.png')).convert('RGB')
        sw = round(sheet.width * 1.2)
        sheet = sheet.resize((sw, round(sheet.height * 1.2)), Image.NEAREST)
        img.paste(sheet, (W - 20 - sw, y + 22))
    d.text((20, H - 24), 'The sets differ in their figures; each explorer also has a room of his own, left of room $29 (ExplorerRooms $A66C).',
           font=fs, fill=DIM)
    img.save(args.out)
    print(args.out)


def panel(args):
    scr = Image.open(P('work', 'docs', 'tmA', 'exp', '001250.png')).convert('RGB')
    s = 3
    crop = scr.crop((0, 128, 256, 192)).resize((256 * s, 64 * s), Image.NEAREST)
    H = 66 + 64 * s + 150
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The status panel (the screen\'s bottom third), explorer 0 in room $14',
          'explorers frame 1250, 3 x; the boxes are the panel\'s parts as the panel module draws them (doc 8)')
    x0, y0 = (W - 256 * s) // 2, 66
    img.paste(crop, (x0, y0))
    f = kitlib.font(14)
    # (x0, y0, x1, y1) in panel pixels, label
    parts = [((0, 0, 104, 23), 'score and high score', (255, 220, 90)),
             ((0, 23, 90, 64), 'spare lives: one figure a life', (110, 220, 110)),
             ((90, 4, 140, 64), 'the portrait', (110, 170, 250)),
             ((140, 4, 172, 64), 'the item in the hero\'s hand', (250, 130, 110)),
             ((172, 4, 256, 64), 'the three bearers, an item above each one that carries one', (220, 140, 230))]
    ly = y0 + 64 * s + 14
    lx = 20
    for (a, b, c, e), lab, col in parts:
        d.rectangle([x0 + a * s, y0 + b * s, x0 + c * s - 1, y0 + e * s - 1], outline=col, width=3)
        tw = d.textlength(lab, font=f)
        if lx + tw + 30 > W - 20:
            lx, ly = 20, ly + 24
        d.rectangle([lx, ly + 3, lx + 14, ly + 17], outline=col, width=3)
        d.text((lx + 20, ly), lab, font=f, fill=TEXT)
        lx += tw + 50
    img.crop((0, 0, W, ly + 34)).save(args.out)
    print(args.out)


def rooms(args):
    lo, hi = (int(x) for x in args.levels.split('-'))
    r = fig_rooms.resources()
    alt = r['rooms/alt-rooms.bin']
    rlist = list(range(lo * 12, (hi + 1) * 12))
    cols, gap, lab = 4, 4, 20
    cw = 256
    x_left = (W - (cols * cw + (cols - 1) * gap)) // 2
    rows = (len(rlist) + cols - 1) // cols
    H = 66 + rows * (128 + lab + 6) + 10
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, f'The rooms of levels {lo}-{hi} (rooms ${rlist[0]:02X}-${rlist[-1]:02X}), drawn from src/res at 1 x',
          'Room = level x 12 + column; * alternate tile set; white: creatures at their start; yellow: items at the '
          'start')
    f = kitlib.font(14)
    for i, room in enumerate(rlist):
        x, y = x_left + (i % cols) * (cw + gap), 62 + (i // cols) * (128 + lab + 6)
        lv, col = divmod(room, 12)
        star = ' *' if room in alt else ''
        d.text((x, y), f'${room:02X}  level {lv}, column {col}{star}', font=f, fill=HI)
        img.paste(fig_rooms.room_image(r, room), (x, y + lab))
    img.save(args.out)
    print(args.out)


def route():
    seq = []
    for line in open(P('work', 'docs', 'tmA', 'route-events.txt')):
        m = re.match(r'(\d+) \[\$([0-9A-F]{2})\] room \$([0-9A-F]{2})', line)
        if m:
            seq.append((int(m.group(1)), int(m.group(3), 16)))
    return [(225, 0x14)] + seq


def map_route(args):
    r = fig_rooms.resources()
    cw, ch, gap = 80, 40, 3
    left, top = 40, 70
    H = top + 6 * (ch + gap + 16) + 120
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The map: 72 rooms by level and column, and the route of the RZX run',
          'Rooms from src/res; red: the route (57 rooms, 83 room changes; tools/rzx_dump.py every 25 RZX frames); '
          'grey: never entered')
    seq = route()
    visited = {room for _, room in seq}
    f, fs = kitlib.font(13), kitlib.font(12)

    def centre(room):
        lv, col = divmod(room, 12)
        return left + col * (cw + gap) + cw // 2, top + lv * (ch + gap + 16) + 16 + ch // 2

    for room in range(72):
        lv, col = divmod(room, 12)
        x, y = left + col * (cw + gap), top + lv * (ch + gap + 16)
        im = fig_rooms.room_image(r, room).resize((cw, ch), Image.LANCZOS)
        if room not in visited:
            im = Image.blend(im, Image.new('RGB', im.size, (60, 60, 60)), 0.6)
        img.paste(im, (x, y + 16))
        d.text((x, y), f'${room:02X}', font=f, fill=HI if room in visited else DIM)
    for lv in range(6):
        d.text((6, top + lv * (ch + gap + 16) + 26), f'L{lv}', font=f, fill=DIM)
    # route: lines between successive rooms; a jump of more than one cell (a teleport, a lift, a fall) dashed
    for (_, a), (_, b) in zip(seq, seq[1:]):
        xa, ya = centre(a)
        xb, yb = centre(b)
        d.line([(xa, ya), (xb, yb)], fill=(240, 70, 70), width=3)
    for _, room in seq:
        x, y = centre(room)
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(240, 70, 70))
    sx, sy = centre(0x14)
    d.ellipse([sx - 8, sy - 8, sx + 8, sy + 8], outline=(120, 255, 120), width=3)
    ex, ey = centre(0x3B)
    d.ellipse([ex - 8, ey - 8, ex + 8, ey + 8], outline=(120, 200, 255), width=3)
    y = top + 6 * (ch + gap + 16) + 6
    notes = ['Green ring: the start, room $14. Blue ring: the lab $3B, where the professor takes the six gifts '
             '(RZX frames 43 050-50 200).',
             'The run ends in room $28 (level 3, column 4), the space scene: GameWon set at RZX frame 50 200.',
             'A line across more than one cell is a pass through the explorer room $2D, a lift ($2B-$37), a teleport '
             '($30-$3D) or a respawn.',
             'Rooms $46 and $47 (L5, columns 10, 11) are the own rooms of explorers 3 and 4, left of room $29.']
    for n in notes:
        d.text((20, y), n, font=fs, fill=TEXT)
        y += 20
    img.crop((0, 0, W, y + 10)).save(args.out)
    print(args.out)


def items(args):
    r = fig_rooms.resources()
    sheet = r['sprites/items.bin']
    wanted = [int(l.split(',')[1].strip().lstrip('$'), 16) for l in open(P('src', 'res', 'tables', 'wanted-items.csv'))
              if re.match(r'\d+,', l)]
    cols, s = 8, 3
    cw, chh = W // cols, 24 * s + 44
    H = 66 + 4 * chh + 40
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The 32 items (sprites $8400, 72 bytes each), with the professor\'s six wishes',
          'Drawn from src/res/sprites/items.png at 3 x; a ring and a number: the professor\'s wish 1-6 '
          '(WantedItems $B6BB)')
    f = kitlib.font(13)
    for i in range(32):
        x, y = (i % cols) * cw + (cw - 24 * s) // 2, 64 + (i // cols) * chh
        spr = sheet[i * 72:i * 72 + 72]
        d.rectangle([x - 2, y - 2, x + 24 * s + 1, y + 24 * s + 1], fill=(0, 0, 0))
        for col in range(3):
            for row in range(24):
                byte = spr[col * 24 + row]
                for bit in range(8):
                    if byte & (0x80 >> bit):
                        px, py = x + (col * 8 + bit) * s, y + row * s
                        d.rectangle([px, py, px + s - 1, py + s - 1], fill=(240, 240, 240))
        lab = f'{i} {NAMES[i]}'
        tw = d.textlength(lab, font=f)
        d.text((min(max(4, (i % cols) * cw + (cw - tw) / 2), W - 4 - tw), y + 24 * s + 6), lab, font=f, fill=TEXT)
        if i in wanted:
            k = wanted.index(i) + 1
            d.rectangle([x - 5, y - 5, x + 24 * s + 4, y + 24 * s + 4], outline=HI, width=3)
            d.text((x + 24 * s + 8, y), str(k), font=kitlib.font(18), fill=HI)
    d.text((20, H - 28), 'Items 25, 26, 30, 31 (Basket, Balloon, Basket 2, Lift) are scenery drawn by room scripts, '
           'never carried.', font=f, fill=DIM)
    img.save(args.out)
    print(args.out)


def moments(args):
    """Key moments: four screenshots of the case's recordings (work/docs/tmA/shots, 512 x 384 dumps of
    time_travel memory_at screens)."""
    shots = [('fall-1366.png', 'the fall death in room $1C (gameover 1366)'),
             ('won-100.png', 'the professor in the lab $3B (rzx50000 100)'),
             ('space-1600.png', 'the asteroid falls on the building (gameover 1600)'),
             ('space-1900.png', 'after the strike (gameover 1900)')]
    sw, sh = 512, 384
    gap = (W - 2 * sw) // 3
    H = 66 + 2 * (sh + 30) + 6
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'Key moments of a game, from the recordings', 'gameover: the RZX state at 10000 with Lives poked to 1; '
          'rzx50000: the RZX run replayed')
    f = kitlib.font(14)
    for i, (rel, lab) in enumerate(shots):
        x, y = gap + (i % 2) * (sw + gap), 62 + (i // 2) * (sh + 30)
        im = Image.open(P('work', 'docs', 'tmA', 'shots', rel)).convert('RGB').resize((sw, sh), Image.NEAREST)
        img.paste(im, (x, y))
        d.text((x, y + sh + 6), lab, font=f, fill=TEXT)
    img.save(args.out)
    print(args.out)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('screens', 'explorers', 'panel', 'map', 'items', 'moments'):
        sub.add_parser(name).add_argument('out')
    ro = sub.add_parser('rooms')
    ro.add_argument('out')
    ro.add_argument('--levels', default='0-2')
    a = ap.parse_args()
    {'screens': screens, 'explorers': explorers, 'panel': panel, 'rooms': rooms, 'map': map_route,
     'items': items, 'moments': moments}[a.cmd](a)


if __name__ == '__main__':
    main()
