#!/usr/bin/env python3
"""The figures of doc 5 (controls), and the helpers fig_render.py and fig_hud.py share.

    python3 tools/fig_controls.py keys --out docs/img/controls/keys.png
    python3 tools/fig_controls.py codes --out docs/img/controls/keycodes.png
    python3 tools/fig_controls.py play --work W --from F --to G --step S --keys tests/inputs/c1.txt --offset 17500 \
        --crop 0,0,256,144 --var Controls=A138:1:bits --var State=A43F:1 ... --title T --out docs/img/play/keys.gif

keys: what each control method reads for fire, up, down, left and right, from the game's own tables (KeysIf2 $A081,
KeysCursor $A086, KeysUser $A08B as loaded; the Kempston bits ReadControls $A13B takes as they come), and the keys
every method shares (1-4, BREAK). codes: the 40 key codes (row x 16 + bit) of KeyPressed $A090 and ReadKeyCode $A0C9,
with the character KeyChars $A0F1 gives each, and the Controls byte. play: a recording's window, the screen cropped,
beside the keys its input script holds and the bytes named by --var, all sampled at T 0 of each frame (memory_at).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(CASE, '..', '..', 'kit')
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402

WIDTH = 1050
BASE = 0x6000


# ---------------------------------------------------------------------------------------------------------------
# shared helpers (fig_render.py, fig_hud.py import them)

def image():
    """The 64 K as the loader leaves it: build/game.bin at $6000"""
    data = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem = bytearray(0x10000)
    mem[BASE:BASE + len(data)] = data
    return mem


def symbols():
    """label -> address from build/game.lst"""
    out = {}
    for line in open(os.path.join(CASE, 'build', 'game.lst'), encoding='latin-1'):
        m = K.LINE.match(line)
        if not m:
            continue
        lab = K.LABEL.match(m.group(3).strip())
        if lab and lab.group(1) not in out:
            out[lab.group(1)] = int(m.group(1), 16)
    return out


class Live:
    """time_travel memory_at on the instance a re_session work folder holds"""

    def __init__(self, work):
        sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
        import re_session  # noqa: E402
        self.session, _ = re_session.session_of(work)

    def mem(self, frame, address, length, t=0):
        body = {'action': 'memory_at', 'space': 'cpu', 'frame': int(frame), 'tinframe': int(t), 'offset': address,
                'length': length}
        r = self.session.call('time_travel', body, ok=False)
        data = (r.structured or {}).get('hex')
        if r.is_error or not data:
            raise SystemExit(f'memory_at {frame} ${address:04X}: {r.text}')
        return bytes.fromhex(data)


def screen(mem6912):
    """6912 screen bytes as a 256 x 192 RGB picture"""
    buf = bytearray(0x10000)
    buf[0x4000:0x5B00] = mem6912
    return K.render_screen(buf)


def title(draw, text, y=8, size=17, x=12):
    draw.text((x, y), text, fill=K.TEXT, font=K.font(size))


def wrap(draw, text, x, y, width, fnt, fill=None, gap=4):
    """text wrapped to width pixels; returns the y under it"""
    words, line = text.split(), ''
    for w in words:
        trial = (line + ' ' + w).strip()
        if draw.textlength(trial, font=fnt) > width and line:
            draw.text((x, y), line, fill=fill or K.TEXT, font=fnt)
            y += fnt.size + gap
            line = w
        else:
            line = trial
    if line:
        draw.text((x, y), line, fill=fill or K.TEXT, font=fnt)
        y += fnt.size + gap
    return y


def input_events(path, offset=0):
    """(frame, keys) of an input script, frames + offset; POKE lines are skipped"""
    f, out = 0, []
    for line in open(path):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        t, _, k = line.partition(' ')
        if t.startswith('+'):
            f += int(t[1:])
        elif t.isdigit():
            f = int(t)
        else:
            continue
        if k.startswith('POKE'):
            continue
        if k == 'END':
            out.append((f + offset, []))
            break
        out.append((f + offset, [] if k.strip() in ('-', '') else k.split()))
    return out


def keys_at(events, frame):
    held = []
    for f, k in events:
        if f > frame:
            break
        held = k
    return held


# ---------------------------------------------------------------------------------------------------------------
# the keyboard

ROWS = [('1', '2', '3', '4', '5', '6', '7', '8', '9', '0'),
        ('Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'),
        ('A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENT'),
        ('CS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SS', 'SPC')]
# key-code row (port $FEFE ... $7FFE) -> the keys of bits 0-4
HALF = [('CS', 'Z', 'X', 'C', 'V'), ('A', 'S', 'D', 'F', 'G'), ('Q', 'W', 'E', 'R', 'T'), ('1', '2', '3', '4', '5'),
        ('0', '9', '8', '7', '6'), ('P', 'O', 'I', 'U', 'Y'), ('ENT', 'L', 'K', 'J', 'H'),
        ('SPC', 'SS', 'M', 'N', 'B')]
MOVES = ['FIRE', 'UP', 'DOWN', 'LEFT', 'RIGHT']     # the order of KeysNow $A150-$A154
MOVE_COLOUR = {'FIRE': (240, 80, 70), 'UP': (240, 200, 70), 'DOWN': (200, 110, 230), 'LEFT': (90, 150, 250),
               'RIGHT': (80, 210, 120)}
CONTROL_BIT = {'RIGHT': 0, 'LEFT': 1, 'DOWN': 2, 'UP': 3, 'FIRE': 4}


def port_of(row):
    return ((~(1 << row)) & 0xFF) << 8 | 0xFE


def key_of(code):
    return HALF[code >> 4][code & 0x0F]


def draw_keyboard(draw, x0, y0, label, keyed, f, fs, grey=(), dark=()):
    kw, kh, gap = 38, 28, 4
    draw.text((x0, y0), label, fill=K.TEXT, font=f)
    y0 += 24
    for r, row in enumerate(ROWS):
        for c, k in enumerate(row):
            x = x0 + c * (kw + gap) + r * 8
            y = y0 + r * (kh + gap)
            fill, ink = (44, 44, 54), K.DIM
            if k in keyed:
                fill, ink = MOVE_COLOUR[keyed[k]], (10, 10, 10)
            elif k in grey:
                fill, ink = (150, 150, 160), (10, 10, 10)
            elif k in dark:
                fill, ink = (70, 70, 96), K.TEXT
            draw.rectangle([x, y, x + kw, y + kh], fill=fill, outline=(90, 90, 100))
            draw.text((x + 4, y + 6), k, fill=ink, font=fs)
    return y0 + 4 * (kh + gap)


def key_set(mem, address):
    return {key_of(mem[address + i]): MOVES[i] for i in range(5)}


def cmd_keys(args):
    mem, sym = image(), symbols()
    pic = Image.new('RGB', (WIDTH, 760), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs, ft = K.font(15), K.font(12), K.font(13)
    title(d, 'What each menu choice reads for FIRE, UP, DOWN, LEFT and RIGHT (the tables as loaded)')
    y = 42
    a, b, c = sym['KeysIf2'], sym['KeysCursor'], sym['KeysUser']
    yb = draw_keyboard(d, 12, y, f'2 INTERFACE 2: KeysIf2 ${a:04X} = ' + ' '.join(f'{mem[a + i]:02X}' for i in range(5)),
                       key_set(mem, a), f, fs, grey=('1', '2', '3', '4'), dark=('CS', 'SPC'))
    draw_keyboard(d, 530, y, f'3 CURSOR: KeysCursor ${b:04X} = ' + ' '.join(f'{mem[b + i]:02X}' for i in range(5)),
                  key_set(mem, b), f, fs, grey=('1', '2', '3', '4'), dark=('CS', 'SPC'))
    y2 = yb + 18
    yb2 = draw_keyboard(d, 12, y2, f'4 KEYBOARD: KeysUser ${c:04X} = ' + ' '.join(f'{mem[c + i]:02X}' for i in range(5))
                        + ' (K redefines)', key_set(mem, c), f, fs, grey=('1', '2', '3', '4'), dark=('CS',))
    x0 = 530
    d.text((x0, y2), '1 KEMPSTON: IN A,($1F) at $A148, AND $1F', fill=K.TEXT, font=f)
    for bit in range(8):
        x = x0 + (7 - bit) * 58
        move = next((m for m, v in CONTROL_BIT.items() if v == bit), None)
        fill = MOVE_COLOUR[move] if move else (44, 44, 54)
        d.rectangle([x, y2 + 30, x + 52, y2 + 72], fill=fill, outline=(90, 90, 100))
        d.text((x + 4, y2 + 34), f'bit {bit}', fill=(10, 10, 10) if move else K.DIM, font=fs)
        d.text((x + 4, y2 + 52), move if move else '0', fill=(10, 10, 10) if move else K.DIM, font=fs)
    yy = wrap(d, 'A pressed switch reads 1, and the five bits are already the Controls byte: no table, no '
                 'priority. KempstonTest $9F62 accepts the interface only if bits 5-7 read 0 in 256 reads in a row.',
              x0, y2 + 84, 500, ft, fill=K.DIM)
    ly = max(yb2, yy) + 16
    x = 12
    for m in MOVES:
        d.rectangle([x, ly, x + 22, ly + 18], fill=MOVE_COLOUR[m])
        d.text((x + 28, ly + 1), {'UP': 'UP (jump)', 'DOWN': 'DOWN (crouch, pod)'}.get(m, m), fill=K.TEXT, font=ft)
        x += 150 if m != 'DOWN' else 210
    ly += 30
    d.rectangle([12, ly, 34, ly + 18], fill=(150, 150, 160))
    d.text((40, ly + 1), 'every method, in play: 1-4 choose the mask slot (MaskKeys $B089 reads $F7FE itself)',
           fill=K.TEXT, font=ft)
    ly += 26
    d.rectangle([12, ly, 34, ly + 18], fill=(70, 70, 96))
    d.text((40, ly + 1), 'CAPS SHIFT + SPACE together: BREAK, back to the menu (the interrupt, $92A4-$92B0)',
           fill=K.TEXT, font=ft)
    ly += 26
    ly = wrap(d, 'With INTERFACE 2 or CURSOR, SPACE is not fire: it is only BREAK\'s second key. KEYBOARD as '
                 'loaded uses SPACE as fire; fire alone never breaks, CAPS SHIFT must be held too.', 12, ly, WIDTH - 24,
              ft, fill=K.DIM)
    pic = pic.crop((0, 0, WIDTH, ly + 10))
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_codes(args):
    mem, sym = image(), symbols()
    chars = sym['KeyChars']
    pic = Image.new('RGB', (WIDTH, 600), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs, fb = K.font(14), K.font(12), K.font(16)
    title(d, 'The 40 key codes: code = row x 16 + bit, the row naming the half-row port (KeyPressed $A090)')
    x0, y0, cw, ch = 210, 70, 158, 50
    for bit in range(5):
        d.text((x0 + bit * cw + 8, y0 - 24), f'bit {bit}', fill=K.TEXT, font=f)
    for row in range(8):
        y = y0 + row * ch
        d.text((12, y + 6), f'row {row}  port ${port_of(row):04X}', fill=K.TEXT, font=f)
        d.text((12, y + 26), f'B = ${port_of(row) >> 8:02X} (RES {row},B of $FF)', fill=K.DIM, font=fs)
        for bit in range(5):
            code = row * 16 + bit
            ch_ = mem[chars + row * 5 + bit]
            x = x0 + bit * cw
            used = code in [mem[a + i] for a in (sym['KeysIf2'], sym['KeysCursor'], sym['KeysUser']) for i in range(5)]
            fill = (52, 52, 70) if not used else (70, 90, 70)
            d.rectangle([x, y, x + cw - 6, y + ch - 6], fill=fill, outline=(90, 90, 100))
            d.text((x + 8, y + 4), HALF[row][bit], fill=K.TEXT, font=fb)
            d.text((x + 68, y + 6), f'${code:02X}', fill=(255, 210, 70), font=f)
            shown = {0x0D: 'ENTER', 0x20: 'space', 0x40: '@'}.get(ch_, chr(ch_))
            d.text((x + 8, y + 26), f'char ${ch_:02X} {shown}', fill=K.DIM, font=fs)
    y = y0 + 8 * ch + 10
    y = wrap(d, 'Yellow: the key code. Grey text: the character KeyChars $A0F1[row x 5 + bit] gives it '
                '(KeyCodeToChar $A119); both shifts give "@", which EnterPassword skips. Green cells: a key one of '
                'the three key tables names as loaded.', 12, y, WIDTH - 24, fs, fill=K.DIM)
    # the Controls byte
    y += 16
    d.text((12, y), 'Controls $A138 (ReadControls $A13B, once a pass; ControlsLast $A139 keeps the last pass\'s):',
           fill=K.TEXT, font=f)
    y += 26
    for bit in range(8):
        x = 12 + (7 - bit) * 70
        move = next((m for m, v in CONTROL_BIT.items() if v == bit), None)
        fill = MOVE_COLOUR[move] if move else (44, 44, 54)
        d.rectangle([x, y, x + 64, y + 44], fill=fill, outline=(90, 90, 100))
        d.text((x + 6, y + 4), f'bit {bit}', fill=(10, 10, 10) if move else K.DIM, font=fs)
        d.text((x + 6, y + 22), move or '0', fill=(10, 10, 10) if move else K.DIM, font=fs)
    wrap(d, 'The keyboard path sets a bit for a key that reads 0; right is tested first and skips left, down skips '
            'up. The Kempston path stores the port\'s bits 0-4 as they are (1 = pressed).', 590, y - 2, 448, fs,
         fill=K.DIM)
    pic = pic.crop((0, 0, WIDTH, y + 60))
    pic.save(args.out)
    print(args.out, pic.size)


# ---------------------------------------------------------------------------------------------------------------
# play: a window of a recording beside its keys and bytes

def parse_var(text):
    name, _, spec = text.partition('=')
    parts = spec.split(':')
    addr, length = int(parts[0], 16), int(parts[1]) if len(parts) > 1 else 1
    form = parts[2] if len(parts) > 2 else 'hex'
    return name, addr, length, form


def show(form, data):
    if form == 'bits':
        return ' '.join(f'{b:08b}' for b in data)
    if form == 'dec':
        return ' '.join(str(b) for b in data)
    if form == 'text':
        return ''.join(chr(b) if 32 <= b < 127 else '.' for b in data)
    return ' '.join(f'{b:02X}' for b in data)


def cmd_play(args):
    live = Live(args.work)
    events = input_events(args.keys, args.offset) if args.keys else []
    frames = list(range(args.start, args.end + 1, args.step))
    vars_ = [parse_var(v) for v in args.var]
    crop = tuple(int(v) for v in args.crop.split(','))
    samples = []
    for fr in frames:
        m = live.mem(fr, 0x4000, 0x1B00)
        vals = [live.mem(fr, a, n) for _, a, n, _ in vars_]
        samples.append((fr, m, vals))
    keys_used = []
    for f_, k in events:
        for key in k:
            if key not in keys_used and args.start <= f_ <= args.end:
                keys_used.append(key)
    sc = args.scale
    sw, sh = (crop[2] - crop[0]) * sc, (crop[3] - crop[1]) * sc
    f, fs = K.font(14), K.font(13)
    xs = sw + 30
    cw = WIDTH - xs - 16
    span = max(1, args.end - args.start)
    H = max(sh + 110, 150 + 20 * len(keys_used) + 22 * len(vars_) + 40)

    def fx(fr):
        return xs + 70 + (fr - args.start) * (cw - 70) / span

    pictures = []
    for fr, m, vals in samples:
        pic = Image.new('RGB', (WIDTH, H), K.BACKGROUND)
        d = ImageDraw.Draw(pic)
        d.text((12, 8), args.title, fill=K.TEXT, font=K.font(15))
        scr = screen(m).crop(crop).resize((sw, sh), Image.NEAREST)
        pic.paste(scr, (12, 40))
        y = 40
        sub = f' (script frame {fr - args.offset})' if args.offset else ''
        d.text((xs, y), f'frame {fr}{sub}', fill=K.TEXT, font=f)
        y += 26
        if keys_used:
            for key in keys_used:
                d.text((xs, y), key, fill=K.TEXT, font=fs)
                for (f0, k), nxt in zip(events, events[1:] + [(args.end + 1, [])]):
                    if key in k and nxt[0] > args.start and f0 < args.end:
                        a, b = max(f0, args.start), min(nxt[0], args.end)
                        d.rectangle([fx(a), y + 3, max(fx(a) + 2, fx(b)), y + 13], fill=(90, 150, 250))
                y += 20
            d.line([fx(fr), 62, fx(fr), y], fill=(255, 210, 70), width=2)
            y += 8
        for (name, a, n, form), v in zip(vars_, vals):
            d.text((xs, y), f'{name} ${a:04X}', fill=K.DIM, font=fs)
            d.text((xs + 200, y), show(form, v), fill=K.TEXT, font=fs)
            y += 22
        held = keys_at(events, fr)
        if events:
            d.text((12, 48 + sh), 'keys held: ' + (' '.join(held) if held else 'none'), fill=(255, 210, 70), font=f)
        wrap(d, args.note or 'Memory and screen sampled at T 0 of each frame (what the code did before the frame '
             'began).' + (' Blue bars: the keys of the input script; yellow line: this frame.' if events else ''),
             12, max(72 + sh, y + 6), WIDTH - 24, K.font(12), fill=K.DIM)
        pictures.append(pic)
    K.save_gif(args.out, pictures, [args.delay] * (len(pictures) - 1) + [args.hold])
    print(args.out, len(pictures), pictures[0].size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    for name in ('keys', 'codes'):
        s = sub.add_parser(name)
        s.add_argument('--out', required=True)
    s = sub.add_parser('play')
    s.add_argument('--work', required=True)
    s.add_argument('--from', dest='start', type=int, required=True)
    s.add_argument('--to', dest='end', type=int, required=True)
    s.add_argument('--step', type=int, default=2)
    s.add_argument('--keys', help='the input script')
    s.add_argument('--offset', type=int, default=0, help='TTD frame of the script\'s frame 0')
    s.add_argument('--crop', default='0,0,256,192', help='x0,y0,x1,y1 of the screen in pixels')
    s.add_argument('--scale', type=int, default=2)
    s.add_argument('--var', action='append', default=[], help='NAME=ADDR[:LEN[:hex|bits|dec|text]]')
    s.add_argument('--title', default='')
    s.add_argument('--note', default='')
    s.add_argument('--delay', type=int, default=90)
    s.add_argument('--hold', type=int, default=1500)
    s.add_argument('--out', required=True)
    args = p.parse_args()
    {'keys': cmd_keys, 'codes': cmd_codes, 'play': cmd_play}[args.cmd](args)


if __name__ == '__main__':
    main()
