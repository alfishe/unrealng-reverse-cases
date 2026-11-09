#!/usr/bin/env python3
"""The figures of doc 05 (controls), drawn from the image and from a recording read with time_travel memory_at.

    python3 tools/fig_controls.py devices  --out docs/img/controls/devices.png
    python3 tools/fig_controls.py keytable --out docs/img/controls/keytable.png
    python3 tools/fig_controls.py perimeter --work W --from 880 --to 1033 --out docs/img/controls/perimeter.png
    python3 tools/fig_controls.py power     --work W --from 1030 --to 1085 --out docs/img/controls/power.png
    python3 tools/fig_controls.py namegrid  --work W --at 12500 --out docs/img/controls/namegrid.png

W is a work folder whose instance holds the recording (re_session.py session.json): w1 replayed from
work/snaps/entry.z80 with tests/inputs/w1.txt. The image is work/mkgame/original.bin.
"""
import argparse
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, HERE)
import vplib  # noqa: E402

K = vplib.K
IMAGE = os.path.join(CASE, 'work', 'mkgame', 'original.bin')

BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (110, 110, 118), (200, 200, 205)
BIT_COLOURS = {0: (214, 39, 40), 1: (31, 119, 180), 2: (44, 160, 44), 3: (148, 103, 189), 4: (255, 127, 14),
               5: (140, 86, 75)}
BIT_NAMES = {0: 'right', 1: 'left', 2: 'up', 3: 'down', 4: 'fire', 5: 'BREAK'}
W = 1050


def fonts():
    return K.font(15), K.font(13), K.font(19)


def image():
    return open(IMAGE, 'rb').read()


def byte_boxes(d, x, y, labels, f, cell=44, h=34, colours=None, title=None, tf=None):
    """8 boxes, bit 7 at the left; labels[i] is bit i's label; returns each bit's box centre (bottom, top)"""
    pos = {}
    if title:
        d.text((x, y - 22), title, font=tf or f, fill=FG)
    for i in range(8):
        bit = 7 - i
        x0 = x + i * cell
        fill = (colours or {}).get(bit, (238, 238, 238))
        d.rectangle([x0, y, x0 + cell - 2, y + h], fill=fill, outline=FG)
        lab = labels.get(bit, '')
        lf = f if d.textlength(lab, font=f) < cell - 6 else K.font(12)
        tw = d.textlength(lab, font=lf)
        d.text((x0 + (cell - 2 - tw) / 2, y + (11 if lf is f else 13)), lab, font=lf, fill=FG)
        d.text((x0 + 3, y + 1), str(bit), font=K.font(10), fill=DIM)
        pos[bit] = (x0 + cell / 2 - 1, y + h / 2)
    return pos


def light(c, k=0.55):
    return tuple(int(v + (255 - v) * k) for v in c)


def devices(args):
    f, fs, ft = fonts()
    H = 1200
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((20, 12), 'Four readers, one byte: every device lands on InputState $827C, bits 0-5', font=ft, fill=FG)
    d.text((20, 40), 'ReadInput $8106 jumps through InputHandlers $811B by Control $B8BD; ReadBreak $8216 adds bit 5 '
                     'and stores the byte.', font=fs, fill=DIM)
    out_labels = {i: BIT_NAMES[i] for i in range(6)}
    out_labels.update({6: '0', 7: '0'})
    out_col = {i: light(BIT_COLOURS[i]) for i in range(6)}
    xr = 620
    bands = [
        ('0  K  ReadKeyboard $8123: KeyDown $822E for the three defined keys (default M, SYMBOL SHIFT, SPACE)',
         [('$7FFE (SPACE SYM M N B), the defaults', {0: 'SPC', 1: 'SYM', 2: 'M', 3: 'N', 4: 'B'},
           {2: 1, 1: 0, 0: 4})], 'no up or down: the cursor runs round the cushions with left and right alone'),
        ('1  I  ReadInterface2 $8151: two half rows, each CPL, ORed: either joystick',
         [('$EFFE (keys 0 9 8 7 6) = stick 1', {0: '0', 1: '9', 2: '8', 3: '7', 4: '6'},
           {0: 4, 3: 0, 4: 1, 2: 3, 1: 2}),
          ('$F7FE (keys 1 2 3 4 5) = stick 2', {0: '1', 1: '2', 2: '3', 3: '4', 4: '5'},
           {4: 4, 1: 0, 0: 1, 2: 3, 3: 2})], 'port bits are 0 when pressed: CPL first'),
        ('2  J  ReadKempston $81A0: IN A,($1F), active high',
         [('port $1F (Kempston)', {0: 'R', 1: 'L', 2: 'D', 3: 'U', 4: 'F'},
           {4: 4, 0: 0, 1: 1, 2: 3, 3: 2})], 'the only active-high input: no CPL'),
        ('3  C  ReadCursorKeys $81C4: KeyDown for 8 5 7 6; no direction: KEY-SCAN, any other key = fire',
         [('keys (through KeyDown)', {0: '8', 1: '5', 2: '7', 3: '6', 4: 'other'},
           {0: 0, 1: 1, 2: 2, 3: 3, 4: 4})], 'fire only when no direction is held ($81F7 RET NZ)'),
    ]
    y = 90
    for title, sources, note in bands:
        d.rectangle([14, y - 8, W - 14, y + 30 + 112 * len(sources) + 18], outline=GRID)
        d.text((24, y), title, font=f, fill=FG)
        yy = y + 50
        for stitle, labels, route in sources:
            src = byte_boxes(d, 30, yy, labels, f, cell=46, title=stitle, tf=fs)
            dst = byte_boxes(d, xr, yy, out_labels, f, cell=50, colours=out_col,
                             title='InputState $827C' if yy == y + 50 else None, tf=fs)
            for k, (sb, db) in enumerate(sorted(route.items(), key=lambda r: -r[0])):
                x0, y0 = src[sb]
                x1, y1 = dst[db]
                c = BIT_COLOURS[db]
                ym = y0 + 24 + 7 * k
                d.line([(x0, y0 + 17), (x0, ym), (x1, ym), (x1, y1 + 17)], fill=c, width=3)
            yy += 112
        d.text((30, yy - 26), note, font=fs, fill=DIM)
        y = yy + 18
    d.text((24, y + 4), 'BREAK: ReadBreak $8216 sets bit 5 when CAPS SHIFT ($FEFE bit 0) and SPACE ($7FFE bit 0) '
                        'are both down, for every device.', font=fs, fill=FG)
    d.text((24, y + 26), 'How to read: a line joins an input bit (left, bit 7 first) to the InputState bit it sets '
                         '(right), in that bit\'s colour.', font=fs, fill=DIM)
    d.text((24, y + 46), 'python3 tools/fig_controls.py devices (from the code of $8106-$822D)', font=fs, fill=DIM)
    img = img.crop((0, 0, W, y + 72))
    save(img, args.out)


def keytable(args):
    f, fs, ft = fonts()
    m = image()
    table = m[0x8254:0x8254 + 40]
    rows_left = [(0xF7FE, 15, 'L'), (0xFBFE, 10, 'L'), (0xFDFE, 5, 'L'), (0xFEFE, 0, 'L')]
    rows_right = [(0xEFFE, 20), (0xDFFE, 25), (0xBFFE, 30), (0x7FFE, 35)]
    names = {0x27: 'CAPS', 0x0D: 'ENTER', 0x20: 'SPACE', 0x18: 'SYM'}
    H = 620
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((20, 12), 'KeyTable $8254: one character a key, in the order KeyDown $822E reads them',
           font=ft, fill=FG)
    d.text((20, 40), 'Each key: its character, its index p in the table, and the port / bit mask KeyDown computes '
                     'from p.', font=fs, fill=DIM)
    kw, kh, x0, y0 = 96, 78, 30, 90
    special = {0x4D: 'left (default)', 0x18: 'right (default)', 0x20: 'fire (default)'}
    cursor = {0x35: 'cursor left', 0x36: 'cursor down', 0x37: 'cursor up', 0x38: 'cursor right'}

    def key_of(p):
        c = 39 - p
        port_hi = 0x7F
        while c >= 5:
            c -= 5
            port_hi = ((port_hi >> 1) | 0x80) & 0xFF
        return (port_hi << 8) | 0xFE, 0x10 >> c

    for r in range(4):
        # the left half of keyboard row r: rows_left[r] runs outer key (bit 0) at the left
        port, start, _ = rows_left[r]
        rport, rstart = rows_right[r]
        keys = [start + i for i in range(5)] + [rstart + 4 - i for i in range(5)]
        if r == 3:
            pass
        for i, p in enumerate(keys):
            x = x0 + i * kw + (14 if i >= 5 else 0) + r * 12
            y = y0 + r * (kh + 12)
            ch = table[p]
            port_p, bit = key_of(p)
            fill = (236, 236, 236)
            if ch in special:
                fill = (255, 214, 160)
            elif ch in cursor:
                fill = (190, 220, 250)
            d.rounded_rectangle([x, y, x + kw - 8, y + kh], 8, fill=fill, outline=FG)
            label = names.get(ch, chr(ch))
            d.text((x + 8, y + 6), label, font=ft, fill=FG)
            d.text((x + 8, y + 32), f'p {p}  ${ch:02X}', font=fs, fill=DIM)
            d.text((x + 8, y + 52), f'${port_p:04X} ${bit:02X}', font=fs, fill=FG)
    y = y0 + 4 * (kh + 12) + 12
    lines = [
        'KeyDown: CPIR finds the character at index p; then C = 39 - p.',
        'Port: B starts at $7F and rotates right once (a 1 in at the top) per 5 in C: p 35-39 read $7FFE, p 0-4 $FEFE.',
        'Bit: $10 shifted right (C mod 5) times: the outer key of each half row is bit 0, the inner key bit 4.',
        'Orange: the image\'s three defined keys M / SYMBOL SHIFT / SPACE ($B8BE-$B8C0); blue: the cursor joystick 5-8.',
        'python3 tools/fig_controls.py keytable (KeyTable read from work/mkgame/original.bin)',
    ]
    for i, t in enumerate(lines):
        d.text((24, y + i * 22), t, font=fs, fill=FG if i < 4 else DIM)
    save(img.crop((0, 0, W, y + 5 * 22 + 14)), args.out)


def perimeter_of(x, y):
    if y == 0x33:
        return x - 3
    if y == 0xB4:
        return 378 + (252 - x)
    if x == 0xFC:
        return 249 + (y - 51)
    return 627 + (180 - y)


def perimeter(args):
    f, fs, ft = fonts()
    s = vplib.session(args.work)
    shot = vplib.read(s, args.base_frame, 0x4000, 0x1B00)
    samples = []
    for fr in range(args.lo, args.hi + 1):
        b = vplib.read(s, fr, 0x86BA, 3)
        samples.append((fr, b[0], b[1], b[2] if b[2] < 128 else b[2] - 256))
    sc = 3
    scr = K.render_screen(shot, 0).resize((256 * sc, 192 * sc), Image.NEAREST)
    left, top = 140, 70
    H = top + 192 * sc + 190
    img = Image.new('RGB', (W, H), BG)
    img.paste(scr, (left, top))
    d = ImageDraw.Draw(img)
    d.text((20, 12), 'The aiming cursor runs on one coordinate round the cushion line, modulo 756', font=ft, fill=FG)
    d.text((20, 40), f'w1 frames {args.lo}-{args.hi} (left key M held): CursorX/Y $86BA/$86BB at the end of each '
                     f'frame, on the screen of frame {args.base_frame}', font=fs, fill=DIM)

    def P(x, y):
        return left + x * sc + sc // 2, top + y * sc + sc // 2

    d.rectangle([P(3, 51), P(252, 180)], outline=(255, 255, 255), width=1)
    speed_col = {1: (255, 255, 0), 2: (255, 190, 0), 3: (255, 120, 0), 4: (255, 40, 40), 5: (220, 0, 160),
                 6: (150, 0, 255)}
    for fr, x, y, sp in samples:
        if sp == 0:
            continue
        cx, cy = P(x, y)
        c = speed_col[abs(sp)]
        d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=c, outline=(0, 0, 0))
    for (x, y, lab, dx, dy) in [(3, 51, '0 (and 756)', -120, -26), (252, 51, '249', 10, -26),
                                (252, 180, '378', 10, 6), (3, 180, '627', -60, 6)]:
        cx, cy = P(x, y)
        d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], outline=FG, width=2)
        d.text((cx + dx, cy + dy), lab, font=f, fill=FG)
    cx, cy = P(252, 115)
    d.text((cx + 12, cy - 30), 'right:', font=f, fill=FG)
    d.text((cx + 12, cy - 10), 'p = 249', font=f, fill=FG)
    d.text((cx + 12, cy + 10), '+ (y - 51)', font=f, fill=FG)
    cx, cy = P(3, 115)
    d.text((cx - 128, cy - 30), 'left:', font=f, fill=FG)
    d.text((cx - 128, cy - 10), 'p = 627', font=f, fill=FG)
    d.text((cx - 128, cy + 10), '+ (180 - y)', font=f, fill=FG)
    first = samples[0]
    cx, cy = P(252, 115)
    d.text((cx + 12, cy + 34), f'start (252, 115)', font=fs, fill=DIM)
    ly = top + 192 * sc + 16
    d.text((24, ly), 'Speed (CursorSpeed $86BC):', font=f, fill=FG)
    for i in range(1, 7):
        x = 270 + (i - 1) * 70
        d.ellipse([x, ly + 2, x + 14, ly + 16], fill=speed_col[i], outline=(0, 0, 0))
        d.text((x + 20, ly), str(i), font=f, fill=FG)
    lap = [r for r in samples if r[3]]
    d.text((24, ly + 30), f'One dot a frame: {len(lap)} frames moving; the speed grows by one every 10 interrupts '
                          'up to 6, so the dots spread apart.', font=fs, fill=FG)
    d.text((24, ly + 52), 'Top: p = x - 3.  Bottom: p = 378 + (252 - x).  Left (key): +1 on the lower half '
                          '(y >= 114), -1 on the upper; right: the opposite.', font=fs, fill=FG)
    d.text((24, ly + 72), 'Up: +1 on the left half (x < 128); down: +1 on the right half. Held left from the right '
                          'cushion, the cursor runs down,', font=fs, fill=FG)
    d.text((24, ly + 92), 'along the bottom, up the left and along the top. White: the cushion line x 3-252, '
                          'y 51-180; each corner carries its p.', font=fs, fill=FG)
    d.text((24, ly + 118), f'python3 tools/fig_controls.py perimeter --work work/docs/vpB/w1 --from {args.lo} '
                           f'--to {args.hi} (w1 replayed from entry.z80)', font=fs, fill=DIM)
    save(img.crop((0, 0, W, ly + 145)), args.out)


def power(args):
    f, fs, ft = fonts()
    s = vplib.session(args.work)
    rows = []
    for fr in range(args.lo, args.hi + 1):
        b = vplib.read(s, fr, 0x827C, 1)[0]
        p = vplib.read(s, fr, 0x86BF, 2)
        rows.append((fr, b, p[0], p[1]))
    H = 620
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((20, 12), 'The power: +2 an interrupt while fire is held, the shot on the release', font=ft, fill=FG)
    d.text((20, 40), f'w1 frames {args.lo}-{args.hi}: InputState $827C bit 4, Power $86BF and the bar drawn last '
                     '($86C0) at the end of each frame', font=fs, fill=DIM)
    x0, y0, pw, ph = 90, 90, 600, 330
    d.rectangle([x0, y0, x0 + pw, y0 + ph], outline=FG)
    n = len(rows)
    for v in range(0, 141, 20):
        y = y0 + ph - v * ph / 140
        d.line([x0 - 4, y, x0 + pw, y], fill=GRID)
        d.text((x0 - 40, y - 8), str(v), font=fs, fill=DIM)
    for i, (fr, b, p, last) in enumerate(rows):
        x = x0 + i * pw / (n - 1)
        if b & 0x10:
            d.rectangle([x - pw / (n - 1) / 2, y0 + 1, x + pw / (n - 1) / 2, y0 + ph - 1], fill=(255, 236, 205))
        if i % 5 == 0:
            d.text((x - 16, y0 + ph + 6), str(fr), font=fs, fill=DIM)
    pts = [(x0 + i * pw / (n - 1), y0 + ph - p * ph / 140) for i, (_, _, p, _) in enumerate(rows)]
    d.line(pts, fill=(214, 39, 40), width=3)
    pts2 = [(x0 + i * pw / (n - 1), y0 + ph - min(p, 126 if p >= 128 else p) * ph / 140)
            for i, (_, _, p, _) in enumerate(rows)]
    d.line(pts2, fill=(31, 119, 180), width=1)
    rel = next((r for r in rows[1:] if not r[1] & 0x10 and r[2]), None)
    d.text((x0 + 10, y0 + 8), 'shaded: fire held (bit 4)', font=fs, fill=FG)
    d.text((x0 + 10, y0 + 28), 'red: Power $86BF; blue: the bar length (the same up to 126)', font=fs,
           fill=(214, 39, 40))
    last = rows[-1]
    d.text((x0 + pw - 250, y0 + ph - last[2] * ph / 140 - 26), f'released: Power {last[2]}', font=fs, fill=FG)
    d.text((x0 + pw / 2 - 40, y0 + ph + 26), 'frame', font=fs, fill=DIM)
    # the rule panel
    rx = x0 + pw + 50
    d.text((rx, y0), 'The whole range (code):', font=f, fill=FG)
    tx = [
        'Power 0, 2, ... $84 (132),',
        'then $86 wraps to 0:',
        'a cycle of 67 interrupts.',
        '',
        'Bar length = Power,',
        'drawn as 126 from 128 on',
        '($80, $82, $84 look full).',
        '',
        'Shot speed = Power / 16',
        'pixels a tick ($8A5D).',
        f'Here {last[2]} / 16 = {last[2] / 16:.3f}.',
    ]
    for i, t in enumerate(tx):
        d.text((rx, y0 + 30 + i * 22), t, font=fs, fill=FG)
    ly = y0 + ph + 60
    d.text((24, ly), 'How to read: each column is one frame; the line climbs 2 a frame while the column is shaded; '
                     'it stops when fire is let go,', font=fs, fill=FG)
    d.text((24, ly + 20), 'and AimPower $8506 plays the shot on that interrupt (Power > 0).', font=fs, fill=FG)
    d.text((24, ly + 44), f'python3 tools/fig_controls.py power --work work/docs/vpB/w1 --from {args.lo} '
                          f'--to {args.hi}', font=fs, fill=DIM)
    save(img.crop((0, 0, W, ly + 70)), args.out)


def namegrid(args):
    f, fs, ft = fonts()
    s = vplib.session(args.work)
    shot = vplib.read(s, args.at, 0x4000, 0x1B00)
    sc = 3
    scr = K.render_screen(shot, 0).resize((256 * sc, 192 * sc), Image.NEAREST)
    # only the grid and name part: y 96-190
    crop = scr.crop((0, 96 * sc, 256 * sc, 190 * sc))
    left, top = (W - 256 * sc) // 2, 76
    H = top + crop.height + 200
    img = Image.new('RGB', (W, H), BG)
    img.paste(crop, (left, top))
    d = ImageDraw.Draw(img)
    d.text((20, 12), 'The name entry: 42 cells, one cursor box, a forward / back order that wraps', font=ft, fill=FG)
    d.text((20, 40), f'w1 frame {args.at}, screen lines 96-185; labels: row D, column E of CharacterGrid $B167 '
                     '(cell byte = grid[14 D + E])', font=fs, fill=DIM)

    def P(x, y):
        return left + x * sc, top + (y - 96) * sc

    for D in range(3):
        for E in range(14):
            x, y = 16 * E + 0x14 - 2, 16 * D + 0x70 - 3
            cx, cy = P(x, y)
            if D == 2 and E in (11, 13):
                continue
            lab = f'{D},{E}'
            lf = K.font(13)
            tw = d.textlength(lab, font=lf)
            d.rectangle([cx, cy - 17, cx + tw + 4, cy - 2], fill=(255, 255, 255))
            d.text((cx + 2, cy - 17), lab, font=lf, fill=(0, 0, 160))
    cx, cy = P(0x48, 0xB0)
    d.rectangle([cx - 200, cy - 2, cx - 20, cy + 42], fill=(255, 255, 255))
    d.text((cx - 196, cy + 2), 'NameBuffer $B227,', font=fs, fill=(0, 0, 160))
    d.text((cx - 196, cy + 22), '7 cells from x $48', font=fs, fill=(0, 0, 160))
    ly = top + crop.height + 14
    tx = [
        'Forward (right or down): E + 1, at 14 the next row; from (2, 10) "rub" to (2, 12) "end"; from "end" back to (0, 0).',
        'Back (left or up): E - 1, before 0 the row above at 13; from (2, 12) to (2, 10); before (0, 0) "end" (2, 12).',
        'The box: x = 16 E + $14, y = 16 D + $70, 12 pixels wide, 28 for rub and end (two cells); XORed, so drawn twice it '
        'goes.',
        'Fire picks: a character goes to the name cursor (the 7th is overwritten while the name is full); rub steps back '
        'and writes "_";',
        'end turns "_" into spaces, centres the name in its 7 cells and leaves.',
        f'python3 tools/fig_controls.py namegrid --work work/docs/vpB/w1 --at {args.at}',
    ]
    for i, t in enumerate(tx):
        d.text((24, ly + i * 22), t, font=fs, fill=FG if i < 5 else DIM)
    save(img.crop((0, 0, W, ly + 6 * 22 + 8)), args.out)


def save(img, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    img.save(out, optimize=True)
    print(f'{out}: {img.size[0]} x {img.size[1]}')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('figure', choices=['devices', 'keytable', 'perimeter', 'power', 'namegrid'])
    p.add_argument('--out', required=True)
    p.add_argument('--work')
    p.add_argument('--from', dest='lo', type=int)
    p.add_argument('--to', dest='hi', type=int)
    p.add_argument('--at', type=int, default=12500)
    p.add_argument('--base-frame', type=int, default=880)
    a = p.parse_args()
    globals()[a.figure](a)


if __name__ == '__main__':
    main()
