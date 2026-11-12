#!/usr/bin/env python3
"""The route of the RZX Archive run (another player's complete game) over the map drawn from src/res: the rooms in the
order the run entered them, coloured from the start (blue) to Havok (red); the Fireblade rooms, the giants' rooms, the
lives lost. Also writes the contact sheet of the 127 rooms, rooms-sheet.png.

    python3 tools/fig_route.py --map work/stage2/fig/rooms/map.png --state work/stage2/rzx/state.tsv --out docs/img/maps

state.tsv (tools/rzx_snap.py): one line a frame of the RZX, the room `$6BDD`, the map row and column, Y, X, lives
`$664D`, energy `$6642`, read in SkoolKit's simulator at the frame's end.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

FRAGMENTS = [15, 26, 29, 43, 56, 62, 63, 70, 71, 89, 93, 97, 101, 107, 120, 124]
GIANTS = {39: 'giant $26', 58: 'giant $27', 93: 'giant $29', 112: 'giant $28'}
HAVOK = 123


def read_map(path):
    pos = {}
    for line in open(path):
        if line.startswith('row'):
            head, _, rest = line.partition(':')
            r = int(head.split()[1])
            for c, tok in enumerate(rest.split()):
                if tok != '.':
                    pos[int(tok)] = (r, c)
    return pos


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--map', required=True)
    ap.add_argument('--state', required=True)
    ap.add_argument('--rooms-txt', default=os.path.join(HERE, '..', 'src', 'res', 'rooms', 'map.txt'))
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    pos = read_map(a.rooms_txt)
    seq, lives_lost, first = [], [], {}
    last_room, last_lives = None, None
    play = False
    for line in open(a.state):
        if line.startswith('frame'):
            continue
        f, room, row, col, y, x, lives, energy = map(int, line.split('\t'))
        if not play:
            if room == 4 and lives == 5 and f > 1000:
                play = True
            else:
                continue
        if room in pos and room != last_room:
            seq.append((f, room))
            first.setdefault(room, f)
            last_room = room
        if last_lives is not None and lives < last_lives and lives < 0x10:
            lives_lost.append((f, room))
        last_lives = lives
        if room == HAVOK and f > 140000:
            break
    src = Image.open(a.map).convert('RGB')
    W = 1050
    s = W / src.size[0]
    cw, ch = 120 * s, 88 * s
    im = src.resize((W, int(src.size[1] * s)), Image.LANCZOS)
    im = Image.eval(im, lambda v: int(v * 0.55))
    top = 30
    H = top + im.size[1] + 150
    out = Image.new('RGB', (W, H), (16, 16, 20))
    out.paste(im, (0, top))
    d = ImageDraw.Draw(out)
    f12, f11, f14 = K.font(12), K.font(11), K.font(14)
    d.text((10, 6), f'The RZX run\'s route: {len(first)} rooms entered, {len(seq)} room entries, '
                    f'start in room 4 at RZX frame {seq[0][0]}, Havok\'s room 123 at {first[HAVOK]}',
           fill='white', font=f14)

    def centre(room):
        r, c = pos[room]
        return c * cw + cw / 2, top + r * ch + ch / 2

    n = len(seq)
    for k in range(1, n):
        (fa, ra), (fb, rb) = seq[k - 1], seq[k]
        t = k / n
        col = (int(60 + 195 * t), int(140 - 80 * t), int(255 - 205 * t))
        d.line([centre(ra), centre(rb)], fill=col, width=3)
    for room in first:
        x, y = centre(room)
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(230, 230, 230))
    for room in FRAGMENTS:
        x, y = centre(room)
        d.rectangle([x - 6, y - 6, x + 6, y + 6], outline=(255, 220, 60), width=2)
    for room, name in GIANTS.items():
        x, y = centre(room)
        d.ellipse([x - 9, y - 9, x + 9, y + 9], outline=(255, 90, 200), width=2)
    x, y = centre(HAVOK)
    d.ellipse([x - 11, y - 11, x + 11, y + 11], outline=(255, 60, 60), width=3)
    d.text((x + 12, y - 20), 'Havok 123', fill=(255, 120, 120), font=f12)
    x, y = centre(4)
    d.text((x - 10, y + 6), 'start 4', fill=(140, 200, 255), font=f12)
    for f, room in lives_lost:
        x, y = centre(room)
        d.line([x - 6, y - 6, x + 6, y + 6], fill=(255, 60, 60), width=2)
        d.line([x - 6, y + 6, x + 6, y - 6], fill=(255, 60, 60), width=2)
    y0 = top + im.size[1] + 8
    lines = [
        'Map: all 127 rooms drawn from src/res by tools/fig_rooms.py --map (every zone revealed, no actors), darkened.',
        'Line: the room entries in order, blue (RZX frame %d) to red (Havok, %d); dots: every room the run entered.' % (seq[0][0], first[HAVOK]),
        'Yellow squares: the 16 Fireblade fragment rooms. Pink rings: the giants (39, 58, 93, 112). Red crosses: a life lost there.',
        'Lives lost: ' + ', '.join(f'room {r} at {f}' for f, r in lives_lost) + '.',
        'The RZX is another player\'s run (xmikex and Jamie Angus, with rollback); rooms and frames from state.tsv (SkoolKit, no emulator).',
    ]
    for i, t in enumerate(lines):
        d.text((10, y0 + 16 * i), t, fill=(210, 210, 210), font=f11)
    os.makedirs(a.out, exist_ok=True)
    p = os.path.join(a.out, 'route-rzx.png')
    out.save(p)
    print(p, out.size, 'rooms', len(first), 'entries', len(seq))
    order = sorted(first.items(), key=lambda kv: kv[1])
    print('first entries:', ' '.join(f'{r}@{f}' for r, f in order))
    print('fragment rooms first entered:', ' '.join(f'{r}@{first.get(r)}' for r in FRAGMENTS))
    # the contact sheet: every room in number order, its map place and the run's first entry under it
    rooms_dir = os.path.dirname(a.map)
    cols, tw = 8, W // 8
    th = int(tw * 176 / 240)
    rows_n = (127 + cols - 1) // cols
    lab = 16
    sheet = Image.new('RGB', (W, 30 + rows_n * (th + lab) + 40), (16, 16, 20))
    sd = ImageDraw.Draw(sheet)
    sd.text((10, 6), 'The 127 rooms from src/res: number, map row:column, the RZX run\'s first entry', fill='white', font=f14)
    for i, room in enumerate(range(1, 128)):
        r, c = divmod(i, cols)
        x0, y0 = c * tw, 30 + r * (th + lab)
        img = Image.open(os.path.join(rooms_dir, f'room{room:03d}.png')).crop((16, 16, 496, 368))
        sheet.paste(img.resize((tw - 4, th - 2), Image.LANCZOS), (x0 + 2, y0))
        mr, mc = pos[room]
        tag = 'F' if room in FRAGMENTS else ''
        tag += 'G' if room in GIANTS else ''
        tag += 'H' if room == HAVOK else ''
        seen = first.get(room)
        colour = (255, 220, 60) if tag else (200, 200, 200)
        sd.text((x0 + 3, y0 + th), f'{room} {mr}:{mc} {tag} ' + (f'@{seen}' if seen else '-'), fill=colour, font=f11)
    yb = 30 + rows_n * (th + lab) + 4
    sd.text((10, yb), 'F: a Fireblade fragment room, G: a giant, H: Havok (rooms 122 and 123 share one record). '
                      '"-": the RZX run never entered it.',
            fill=(210, 210, 210), font=f11)
    sd.text((10, yb + 16), 'Drawn by tools/fig_rooms.py (every zone revealed, no actors); each picture is the 240 x 176 play window. '
                     'Our recordings enter all 127.',
            fill=(210, 210, 210), font=f11)
    p2 = os.path.join(a.out, 'rooms-sheet.png')
    sheet.save(p2)
    print(p2, sheet.size, 'never entered by the RZX:', [r for r in range(1, 128) if r not in first])

if __name__ == '__main__':
    main()
