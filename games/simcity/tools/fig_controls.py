#!/usr/bin/env python3
"""Doc 05 (controls): the static figures.

    python3 tools/fig_controls.py keys docs/img/controls/keys.png
    python3 tools/fig_controls.py speed work/docs/scB/pointer-tools-780.csv docs/img/controls/pointer-speed.png
    python3 tools/fig_controls.py zones work/stage1/rec/tools/end.szx docs/img/controls/click-zones.png

keys: the 40 keys in their eight half rows (KeyRows `$5B00-$5B07`), coloured by what the game does with them, and
how ReadKempston `$7A01` and ReadSinclair `$7A32` fold a joystick into the same bytes. speed: PointerX and the UI
pass counter per frame from a memory_at table (frame, pointer_x, pointer_y, pass, task_now, switch_off). zones: the
regions Click `$63CD` dispatches on, over a real screen.
"""
import csv
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import szx  # noqa: E402

BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
YEL, RED, GRN, BLU, CYA, ORA, MAG = (240, 200, 70), (230, 90, 80), (90, 200, 120), (90, 150, 250), \
    (70, 210, 220), (250, 150, 60), (200, 110, 230)

# The half rows as the ROM numbers them: port high byte, the keys from bit 0 to bit 4
ROWS = [
    (0xFE, 'CS Z X C V'), (0xFD, 'A S D F G'), (0xFB, 'Q W E R T'), (0xF7, '1 2 3 4 5'),
    (0xEF, '0 9 8 7 6'), (0xDF, 'P O I U Y'), (0xBF, 'EN L K J H'), (0x7F, 'SP SS M N B'),
]
ROLE = {  # key: (colour, label)
    'Q': (GRN, 'up'), 'A': (GRN, 'down'), 'O': (GRN, 'left'), 'P': (GRN, 'right'), 'SP': (YEL, 'click'),
    'EN': (CYA, 'maps'), 'CS': (ORA, 'shift'), 'SS': (MAG, 'shift'),
    '5': (ORA, 'CS: left'), '6': (ORA, 'CS: down'), '7': (ORA, 'CS: up'), '8': (ORA, 'CS: right'),
}
SINCLAIR = {'6': 'O', '7': 'P', '8': 'A', '9': 'Q', '0': 'SP'}


def save(im, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    im.save(out)
    print(out, im.size)


def keys(out):
    W, H = 1050, 600
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f, fs, fk = K.font(15), K.font(12), K.font(14)
    d.text((12, 8), 'KeyRows $5B00-$5B07: one byte a half row, bit 0 the key nearest the edge; a 0 bit is a key down',
           font=f, fill=TEXT)
    d.text((12, 30), 'ReadInput $F781 reads them every frame in the interrupt; the joysticks clear the same bits',
           font=fs, fill=DIM)
    kw, kh, x0, y0 = 70, 46, 150, 70
    d.text((12, y0 - 18), 'byte / port', font=fs, fill=DIM)
    for b in range(5):
        d.text((x0 + b * (kw + 6) + 22, y0 - 18), f'bit {b}', font=fs, fill=DIM)
    for i, (hi, names) in enumerate(ROWS):
        y = y0 + i * (kh + 6)
        d.text((12, y + 6), f'${0x5B00 + i:04X}', font=fk, fill=TEXT)
        d.text((12, y + 24), f'IN ${hi:02X}FE', font=fs, fill=DIM)
        for b, k in enumerate(names.split()):
            x = x0 + b * (kw + 6)
            col, label = ROLE.get(k, (None, ''))
            if i == 3:
                col, label = (MAG, f'SS: tool {int(k) - 1}') if k != '5' else (ORA, 'CS: left\nSS: tool 4')
            if i == 4 and k in '09':
                col, label = MAG, 'SS: tool 9' if k == '0' else 'SS: tool 8'
            if i == 4 and k in '678':
                label = ROLE[k][1] + '\n' + f'SS: tool {int(k) - 1}'
                col = ORA
            d.rounded_rectangle([x, y, x + kw, y + kh], radius=6, fill=PANEL, outline=col or (60, 60, 72), width=2)
            d.text((x + 6, y + 3), k, font=fk, fill=col or DIM)
            yy = y + 21
            for part in label.split('\n'):
                d.text((x + 6, yy), part, font=K.font(10), fill=col or DIM)
                yy += 11
            if k in SINCLAIR and i == 4:
                d.text((x + kw - 22, y + 3), SINCLAIR[k], font=K.font(10), fill=BLU)
    # the joystick folding
    jx = x0 + 5 * (kw + 6) + 30
    d.text((jx, y0 - 18), 'the joysticks fold into the same bits', font=fs, fill=TEXT)
    rows = [
        ('Kempston bit', 'NOT IN $1F', 'clears'),
        ('0 right', '', '$5B05 bit 0 (P)'),
        ('1 left', '', '$5B05 bit 1 (O)'),
        ('2 down', '', '$5B01 bit 0 (A)'),
        ('3 up', '', '$5B02 bit 0 (Q)'),
        ('4 fire', '', '$5B07 bit 0 (SPACE)'),
    ]
    y = y0
    for a, _, c in rows:
        d.text((jx, y), a, font=fs, fill=GRN if y > y0 else DIM)
        d.text((jx + 120, y), c, font=fs, fill=TEXT if y > y0 else DIM)
        y += 20
    y += 14
    d.text((jx, y), 'Sinclair (keys 6-0 of $5B04,', font=fs, fill=BLU)
    d.text((jx, y + 18), 'only with both shifts up):', font=fs, fill=BLU)
    y += 42
    for a, c in [('8 / bit 2', 'A down'), ('7 / bit 3', 'P right'), ('6 / bit 4', 'O left'), ('9 / bit 1', 'Q up'),
                 ('0 / bit 0', 'SPACE fire')]:
        d.text((jx, y), a, font=fs, fill=BLU)
        d.text((jx + 120, y), c, font=fs, fill=TEXT)
        y += 20
    y += 14
    for line in ['ports frame 958 (Kempston right + down):', '$5B01 = $BE, $5B05 = $BE, the rest $BF']:
        d.text((jx, y), line, font=fs, fill=DIM)
        y += 18
    ly = y0 + 8 * (kh + 6) + 12
    items = [(GRN, 'move the pointer (MovePointer $635C)'), (YEL, 'click (Click $63CD); menus: choose'),
             (ORA, 'CAPS SHIFT + 5-8: scroll (ShiftScroll $7A6F)'), (MAG, 'SYMBOL SHIFT + 1-0: tool (ToolKeys $6D2D)'),
             (CYA, 'ENTER: the maps window (UiLoop)'), (BLU, 'blue letter: the Sinclair stick')]
    for i, (col, t) in enumerate(items):
        x = 12 + (i % 2) * 470
        yy = ly + (i // 2) * 22
        d.rectangle([x, yy + 3, x + 12, yy + 15], fill=col)
        d.text((x + 20, yy), t, font=fs, fill=TEXT)
    save(im, out)


def speed(table, out):
    rows = list(csv.DictReader(open(table)))
    fr = [int(r['frame']) for r in rows]
    px = [int(r['pointer_x']) for r in rows]
    ps = [int(r['pass']) for r in rows]
    tn = [int(r['task_now']) for r in rows]
    so = [int(r['switch_off']) for r in rows]
    W, H = 1050, 560
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f, fs = K.font(15), K.font(12)
    d.text((12, 8), 'O held from frame 788: PointerX steps by one each UI pass, about one step every 2.1 frames',
           font=f, fill=TEXT)
    d.text((12, 30), 'tools recording, frames %d-%d, memory_at at t = 0 of each frame: PointerX $5CFC, PassCount '
           '$8F9F, $F704/$F705' % (fr[0], fr[-1]), font=fs, fill=DIM)
    gx0, gx1, gy0, gy1 = 70, W - 20, 70, 380
    d.rectangle([gx0, gy0, gx1, gy1], outline=(60, 60, 72))
    f0, f1 = fr[0], fr[-1]

    def X(v):
        return gx0 + (v - f0) * (gx1 - gx0) / (f1 - f0)

    lo, hi = 15, 60

    def Y(v):
        return gy1 - (v - lo) * (gy1 - gy0) / (hi - lo)

    for v in range(20, 61, 10):
        d.line([gx0, Y(v), gx1, Y(v)], fill=(34, 34, 44))
        d.text((gx0 - 30, Y(v) - 7), str(v), font=fs, fill=DIM)
    for v in range(f0 - f0 % 10 + 10, f1 + 1, 10):
        d.line([X(v), gy1, X(v), gy1 + 5], fill=DIM)
        d.text((X(v) - 14, gy1 + 8), str(v), font=fs, fill=DIM)
    d.text((12, gy0 - 20), 'PointerX (half characters)', font=fs, fill=GRN)
    pts = []
    for i in range(len(fr)):
        pts.append((X(fr[i]), Y(px[i])))
        if i + 1 < len(fr):
            pts.append((X(fr[i + 1]), Y(px[i])))
    d.line(pts, fill=GRN, width=3)
    d.line([X(788), gy0, X(788), gy1], fill=YEL, width=1)
    d.text((X(788) + 4, gy0 + 4), 'O down', font=fs, fill=YEL)
    if 857 <= f1:
        d.line([X(857), gy0, X(857), gy1], fill=YEL, width=1)
        d.text((X(857) + 4, gy0 + 4), 'O up', font=fs, fill=YEL)
    # strips: the pass counter and the task
    sy = gy1 + 40
    d.text((12, sy), 'PassCount', font=fs, fill=TEXT)
    for i in range(len(fr) - 1):
        col = (70, 70, 90) if ps[i] % 2 else (110, 110, 140)
        d.rectangle([X(fr[i]), sy, X(fr[i + 1]) - 1, sy + 22], fill=col)
        if (i == 0 or ps[i] != ps[i - 1]) and ps[i] % 4 == 0:
            d.text((X(fr[i]) + 2, sy + 4), str(ps[i] % 100), font=K.font(10), fill=TEXT)
    sy += 36
    d.text((12, sy), 'task', font=fs, fill=TEXT)
    for i in range(len(fr) - 1):
        col = BLU if so[i] else (GRN if tn[i] == 0 else RED)
        d.rectangle([X(fr[i]), sy, X(fr[i + 1]) - 1, sy + 22], fill=col)
    sy += 34
    for x, (col, t) in zip((70, 330, 590), [(GRN, 'UI task ($F704 = 0)'), (RED, 'simulation ($F704 = 1)'),
                                            (BLU, 'switch held off ($F705 = 1)')]):
        d.rectangle([x, sy + 3, x + 12, sy + 15], fill=col)
        d.text((x + 20, sy), t, font=fs, fill=TEXT)
    steps = px[0] - min(px)
    d.text((12, sy + 26), f'{steps} steps of PointerX; passes {ps[0]}-{ps[-1]}; the same step at every pass: '
           'no acceleration', font=fs, fill=DIM)
    save(im, out)


def zones(src, out):
    mem = bytes(szx.read(src)[0])
    scr = K.render_screen(mem).resize((768, 576), Image.NEAREST)
    W, H = 1050, 650
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im, 'RGBA')
    f, fs = K.font(15), K.font(12)
    d.text((12, 8), 'Where SPACE goes: Click $63CD splits the screen by the pointer\'s character cell', font=f,
           fill=TEXT)
    x0, y0, c = 12, 40, 24
    im.paste(scr, (x0, y0))

    def box(r0, c0, r1, c1, col, label=None):
        d.rectangle([x0 + c0 * c, y0 + r0 * c, x0 + c1 * c - 1, y0 + r1 * c - 1], fill=col + (70,), outline=col,
                    width=3)
        if label:
            d.text((x0 + c0 * c + 6, y0 + r0 * c + 4), label, font=fs, fill=(255, 255, 255))

    for c0, c1, col, name in [(0, 7, YEL, 'SYSTEM'), (7, 15, ORA, 'OPTIONS'), (15, 24, RED, 'DISASTERS'),
                              (24, 32, MAG, 'WINDOWS')]:
        box(0, c0, 1, c1, col)
    box(1, 2, 3, 30, GRN)
    box(2, 0, 3, 1, CYA)
    box(8, 0, 24, 32, BLU)
    lx = x0 + 768 + 16
    texts = [
        (YEL, 'row 0', 'MenuClick $6401: the menu by', 'PointerX < 14, 30, 48, else'),
        (GRN, 'rows 1-2, cols 2-29', 'ToolClick $6D51: tool', '(column - 2) / 2'),
        (CYA, 'row 2, col 0', 'ScrollClick $6CBF: scroll', 'mode (no recording)'),
        (BLU, 'rows 8-23', 'MapClick $7012: the tool', 'on the cell (BoxShown)'),
        (DIM, 'elsewhere', 'rows 3-7 and the palette\'s', 'edges: nothing happens'),
    ]
    y = y0
    for col, a, b, t in texts:
        d.rectangle([lx, y + 4, lx + 12, y + 16], fill=col)
        d.text((lx + 20, y), a, font=f, fill=TEXT)
        d.text((lx + 20, y + 20), b, font=fs, fill=DIM)
        d.text((lx + 20, y + 36), t, font=fs, fill=DIM)
        y += 64
    d.text((lx, y + 6), 'the cell: row PointerY / 8,', font=fs, fill=DIM)
    d.text((lx, y + 22), 'column PointerX / 2', font=fs, fill=DIM)
    d.text((x0, y0 + 576 + 12), f'{src.split("/rec/")[-1]} (the recording\'s last frame), 3 x; the menu bar split '
           'at columns 7, 15 and 24 (PointerX 14, 30, 48)', font=fs, fill=DIM)
    save(im, out)


def main():
    a = sys.argv[1:]
    if not a:
        raise SystemExit(__doc__)
    if a[0] == 'keys':
        keys(a[1])
    elif a[0] == 'speed':
        speed(a[1], a[2])
    elif a[0] == 'zones':
        zones(a[1], a[2])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
