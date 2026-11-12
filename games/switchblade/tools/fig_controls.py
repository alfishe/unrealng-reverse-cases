#!/usr/bin/env python3
"""Figures of doc 05 (controls).

    python3 tools/fig_controls.py keys --out docs/img/controls/keys.png
    python3 tools/fig_controls.py records --out docs/img/controls/records.png
    python3 tools/fig_controls.py play --work W --from F --to F --step N --out docs/img/play/keys.gif \
        [--key F0-F1=LABEL ...] [--crop X,Y,W,H] [--title T]

keys and records are drawn from build/game.bin (the control records at $6B0A, as loaded); play reads the screen
and the input variables of a recording frame by frame (TTD memory_at at T 0 of each frame) from an instance opened
with re_session.py, and writes the keys the recording's script held beside them.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
R = os.path.dirname(os.path.dirname(CASE))
sys.path.insert(0, os.path.join(R, 'kit'))
import kitlib as K  # noqa: E402

BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
ROLE = {'fire': (235, 80, 80), 'up': (90, 160, 255), 'down': (80, 200, 120), 'left': (245, 200, 70),
        'right': (200, 120, 240), 'pause': (150, 150, 150), 'left (also)': (245, 200, 70)}
ROWS = [('1', '2', '3', '4', '5', '6', '7', '8', '9', '0'), ('Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'),
        ('A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'EN'), ('CS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SS', 'SP')]
PORT = {'1': ('$F7FE', 0), '2': ('$F7FE', 1), '3': ('$F7FE', 2), '4': ('$F7FE', 3), '5': ('$F7FE', 4),
        '0': ('$EFFE', 0), '9': ('$EFFE', 1), '8': ('$EFFE', 2), '7': ('$EFFE', 3), '6': ('$EFFE', 4),
        'P': ('$DFFE', 0)}
RECORDS = 0x6B0A
OPCODES = {0x1D: ('DEC E', 'up'), 0x1C: ('INC E', 'down'), 0x14: ('INC D', 'right'), 0x15: ('DEC D', 'left')}
NAMES = ['1. JOYSTICK 1 (Sinclair 1)', '2. JOYSTICK 2 (Sinclair 2)', '3. KEMPSTON', '4. PROTEK OR CURSOR']


def text(d, xy, s, size=13, fill=TEXT):
    d.text(xy, s, font=K.font(size), fill=fill)


def game():
    data = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem = bytearray(0x10000)
    mem[0x5C00:0x5C00 + len(data)] = data
    return mem


def record(mem, n):
    return mem[RECORDS + 14 * n:RECORDS + 14 * n + 14]


def roles(mem, n):
    """bit -> role of option n (0-3) from its record: the fire mask, then the four direction opcodes"""
    r = record(mem, n)
    fire = r[0].bit_length() - 1
    first = 1 if r[2] == 0x1F else 0  # RRA: the fire bit (bit 0) is dropped first
    out = {fire: 'fire'}
    for k in range(4):
        out[first + k] = OPCODES[r[3 + k]][1]
    return out


KEYS_OF = [  # bit -> key of each option's reader (from its code, see doc 05)
    {0: '0', 1: '9', 2: '8', 3: '7', 4: '6'},
    {0: '1', 1: '2', 2: '3', 3: '4', 4: '5'},
    None,
    {0: '0', 1: '5', 2: '8', 3: '7', 4: '6'},
]


def keyboard(d, x0, y0, marks, kw=44, kh=34):
    for r, row in enumerate(ROWS):
        for c, key in enumerate(row):
            x = x0 + c * (kw + 4) + r * 10
            y = y0 + r * (kh + 4)
            role = marks.get(key)
            fill = ROLE[role] if role else PANEL
            d.rounded_rectangle([x, y, x + kw, y + kh], 5, fill=fill, outline=(90, 90, 105))
            text(d, (x + 6, y + 4), key, 13, (0, 0, 0) if role else TEXT)
            if key in PORT:
                p, b = PORT[key]
                text(d, (x + 6, y + 19), f'b{b}', 10, (30, 30, 30) if role else DIM)


def cmd_keys(args):
    mem = game()
    W = args.width
    kbw = 10 * 48 + 30
    H = 70 + 2 * (4 * 38 + 110) + 130
    pic = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), args.title or 'The four controls: which key or joystick bit gives which move (from the records at $6B0A)', 15)
    for n in range(4):
        x = 12 + (n % 2) * (kbw + 20)
        y = 50 + (n // 2) * (4 * 38 + 110)
        text(d, (x, y), NAMES[n], 13, (255, 210, 70))
        rl = roles(mem, n)
        if KEYS_OF[n] is None:
            text(d, (x, y + 24), 'IN A,($1F), then CPL: the Kempston interface, active high', 12, DIM)
            for b in range(5):
                role = rl.get(b)
                bx = x + b * 96
                d.rounded_rectangle([bx, y + 50, bx + 88, y + 90], 5, fill=ROLE[role])
                text(d, (bx + 8, y + 54), f'bit {b}', 12, (0, 0, 0))
                text(d, (bx + 8, y + 70), role, 12, (0, 0, 0))
            keyboard(d, x, y + 100, {'P': 'pause'}, kh=30)
            continue
        marks = {KEYS_OF[n][b]: role for b, role in rl.items()}
        if n == 3:
            marks['9'] = 'left (also)'
        marks['P'] = 'pause'
        keyboard(d, x, y + 26, marks)
        line = ', '.join(f'{KEYS_OF[n][b]} {rl[b]}' for b in sorted(rl))
        text(d, (x, y + 26 + 4 * 38 + 4), line, 12, DIM)
        if n == 3:
            text(d, (x, y + 26 + 4 * 38 + 20), '9 gives left too: the reader ANDs 5 and 9 into one bit', 12, DIM)
    y = H - 110
    x = 12
    for role in ('fire', 'up', 'down', 'left', 'right', 'pause'):
        d.rectangle([x, y, x + 14, y + 14], fill=ROLE[role])
        text(d, (x + 20, y - 1), role, 12)
        x += 110
    text(d, (12, y + 26), 'b0-b4: the bit of the half row read (key down = 0). P is read by the interrupt at port $DFFE for every control.', 12, DIM)
    text(d, (12, y + 44), 'Fire held with P quits to the title. Keys 1-4 ($F7FE) choose the control once, at the menu after the load.', 12, DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_records(args):
    mem = game()
    W = args.width
    H = 560
    pic = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), args.title or 'ControlMenu copies one 14-byte record into the input code: the same decoder serves four devices', 15)
    cols = [12, 300, 470, 640, 810]
    heads = ['record byte -> patched at', NAMES[0].split(' (')[0][3:], NAMES[1].split(' (')[0][3:], 'KEMPSTON', 'PROTEK']
    for c, h in zip(cols, heads):
        text(d, (c, 44), h, 12, (255, 210, 70))
    rows = [('+0 fire mask -> $84CA, $5C06', lambda r: f'${r[0]:02X}  AND ${r[0]:02X}'),
            ('+1 direction mask -> $850F, $8511', lambda r: f'${r[1]:02X}'),
            ('+2 -> $8513', lambda r: 'RRA (fire bit 0)' if r[2] == 0x1F else 'NOP (fire bit 4)'),
            ('+3 -> $851A (1st direction bit)', lambda r: f'{OPCODES[r[3]][0]} {OPCODES[r[3]][1]}'),
            ('+4 -> $851E (2nd)', lambda r: f'{OPCODES[r[4]][0]} {OPCODES[r[4]][1]}'),
            ('+5 -> $8522 (3rd)', lambda r: f'{OPCODES[r[5]][0]} {OPCODES[r[5]][1]}'),
            ('+6 -> $8526 (4th)', lambda r: f'{OPCODES[r[6]][0]} {OPCODES[r[6]][1]}')]
    y = 66
    for name, f in rows:
        text(d, (cols[0], y), name, 12)
        for n in range(4):
            text(d, (cols[n + 1], y), f(record(mem, n)), 12)
        y += 22
    text(d, (cols[0], y + 6), '+7 on -> ReadInput $8529', 12)
    text(d, (cols[0], y + 26), '(18 bytes, LDIR)', 12, DIM)
    code = [['LD A,$EF', 'IN A,($FE)', 'BIT 0,A', 'RET'],
            ['LD A,$F7', 'IN A,($FE)', 'BIT 4,A', 'RET'],
            ['IN A,($1F)', 'CPL', 'BIT 4,A', 'RET'],
            ['LD A,$F7', 'IN A,($FE)', 'OR $EF', 'RRCA x3', 'LD C,A', 'LD A,$EF', 'IN A,($FE)', 'AND C', 'BIT 0,A', 'RET']]
    for n in range(4):
        r = record(mem, n)
        for k, line in enumerate(code[n]):
            text(d, (cols[n + 1], y + 6 + 20 * k), line, 12, (120, 220, 140))
        raw = r[7:14]
        text(d, (cols[n + 1], y + 6 + 20 * len(code[n]) + 4), ' '.join(f'{b:02X}' for b in raw) + (' ...' if n == 3 else ''), 10, DIM)
    y2 = y + 6 + 20 * 10 + 30
    notes = ['Records 1-3 hold the whole reader in their last 7 bytes. LDIR copies 18 bytes, so the 11 bytes after a record',
             '(the next record) land after the RET and are never run. Record 4 runs on into the 11 bytes after it: its 18-byte reader.',
             'A = the five input bits, a key or switch down = 0 (Kempston made so by CPL). Z = fire pressed.']
    for k, s in enumerate(notes):
        text(d, (12, y2 + 18 * k), s, 12, DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_play(args):
    sys.path.insert(0, os.path.join(R, 'games', 'switchblade', 'work', 'docs', 'zsB'))
    import mem as M
    import zxscreen
    s = M.session(args.work)
    spans = []
    for k in args.key or []:
        a, _, lab = k.partition('=')
        f0, _, f1 = a.partition('-')
        spans.append((int(f0), int(f1), lab))
    crop = [int(v) for v in args.crop.split(',')] if args.crop else [0, 0, 256, 192]
    cx, cy, cw, ch = crop
    sc = args.scale
    W = args.width
    pictures = []
    for f in range(args.start, args.end + 1, args.step):
        scr = M.read(s, f, 0x4000, 0x1B00, t=0)
        var = M.read(s, f, 0x6640, 0x20, t=0)
        latch = M.read(s, f, 0x850D, 1, t=0)[0]
        im = zxscreen.render(scr, 1).convert('RGB').crop((cx, cy, cx + cw, cy + ch)).resize((cw * sc, ch * sc), Image.NEAREST)
        pic = Image.new('RGB', (W, max(im.size[1] + 70, 330)), BG)
        d = ImageDraw.Draw(pic)
        text(d, (12, 8), args.title or 'The player answering the keys', 15)
        pic.paste(im, (12, 40))
        x = 12 + im.size[0] + 24
        held = [lab for f0, f1, lab in spans if f0 <= f < f1]
        text(d, (x, 40), f'frame {f}', 14)
        text(d, (x, 66), 'keys held (script): ' + (', '.join(held) if held else 'none'), 13, (255, 210, 70) if held else DIM)
        text(d, (x, 96), f'input latch $850D: {latch:08b}', 13)
        text(d, (x, 116), '  (bit = 0: pressed; bits 1-4 directions,', 11, DIM)
        text(d, (x, 130), '   bit 0 fire for this control)', 11, DIM)
        charge, fprev, freq = var[0x05], var[0x08], var[0x10]
        text(d, (x, 160), f'Charge $6645: ${charge:02X}', 13)
        d.rectangle([x, 182, x + 200, 194], outline=(90, 90, 105))
        d.rectangle([x, 182, x + int(200 * min(charge, 0x20) / 0x20), 194], fill=(235, 80, 80))
        text(d, (x, 204), f'FirePrevious $6648: {fprev}   FireRequest $6650: {freq}', 13)
        text(d, (x, 236), 'sampled at T 0 of each frame (memory_at)', 11, DIM)
        pictures.append(pic)
    durations = [args.delay] * (len(pictures) - 1) + [args.hold]
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), 'pictures')


def cmd_shots(args):
    """Screenshots (screen_shot.py PNGs) two a row, each with its label"""
    items = [x.partition('=')[::2] for x in args.shot]
    W = args.width
    w = (W - 36) // 2
    h = w * 192 // 256
    rows = -(-len(items) // 2)
    font = K.font(12)

    def wrap(label):
        """The label in lines no wider than its picture (a '|' forces a break)"""
        lines = []
        for part in label.split('|'):
            line = ''
            for word in part.strip().split(' '):
                trial = (line + ' ' + word).strip()
                if line and font.getlength(trial) > w:
                    lines.append(line)
                    line = word
                else:
                    line = trial
            lines.append(line)
        return lines
    wrapped = [wrap(label) for _, label in items]
    gap = 18 + 16 * max(len(x) for x in wrapped)
    pic = Image.new('RGB', (W, 44 + rows * (h + gap) + 18 * len(args.note or [])), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), args.title or '', 15)
    for i, (path, _) in enumerate(items):
        im = Image.open(path).convert('RGB').resize((w, h), Image.NEAREST)
        x = 12 + (i % 2) * (w + 12)
        y = 44 + (i // 2) * (h + gap)
        pic.paste(im, (x, y))
        for k, line in enumerate(wrapped[i]):
            text(d, (x, y + h + 6 + 16 * k), line, 12)
    y = 44 + rows * (h + gap)
    for k, line in enumerate(args.note or []):
        text(d, (12, y + 18 * k), line, 12, DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('keys', 'records', 'play'):
        p = sub.add_parser(name)
        p.add_argument('--out', required=True)
        p.add_argument('--title')
        p.add_argument('--width', type=int, default=1050)
        if name == 'play':
            p.add_argument('--work', required=True)
            p.add_argument('--from', dest='start', type=int, required=True)
            p.add_argument('--to', dest='end', type=int, required=True)
            p.add_argument('--step', type=int, default=3)
            p.add_argument('--key', action='append')
            p.add_argument('--crop')
            p.add_argument('--scale', type=int, default=2)
            p.add_argument('--delay', type=int, default=80)
            p.add_argument('--hold', type=int, default=1500)
    p = sub.add_parser('shots')
    p.add_argument('--out', required=True)
    p.add_argument('--title')
    p.add_argument('--width', type=int, default=1050)
    p.add_argument('--shot', action='append', required=True)
    p.add_argument('--note', action='append')
    args = ap.parse_args()
    {'shots': cmd_shots, 'keys': cmd_keys, 'records': cmd_records, 'play': cmd_play}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
