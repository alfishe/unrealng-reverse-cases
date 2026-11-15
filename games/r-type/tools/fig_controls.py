#!/usr/bin/env python3
"""The figures of doc 5 (controls) and the play animations of docs 5, 6 and 8.

    python3 tools/fig_controls.py methods --out docs/img/controls/methods.png
    python3 tools/fig_controls.py readkey --out docs/img/controls/readkey.png
    python3 tools/fig_controls.py play --work W --from F --to G --step S --keys tests/inputs/c1.txt \
        --crop 0,0,256,192 --var 'ControlBits=74FA:1:bits' ... --title T --out docs/img/play/NAME.gif

methods: the keyboard with the keys each control method reads (Interface 2 keys 1-5, the Sinclair keys 6-0, the
defined keys as loaded and as c1 defined them), the pause and define keys, and the ControlBits byte with the bit
each reader puts where (the Kempston's left and right swapped). Drawn from build/game.bin (DefinedKeys $7780 as
loaded) and the readers' code ($8B0A-$8B6F). readkey: ReadKey $BF55's code for a key (D = $2F - row - 8 x (bit + 1))
and the KeyBitTable lookup, the table of all 40 keys. play: a recording's window, the screen (cropped) beside the
keys its input script holds and the bytes named by --var, sampled at T 0 of each frame (time_travel memory_at).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

WIDTH = 1050
BASE = 0x7000

# the half-rows as the ULA reads them: port high byte, keys from bit 0 to bit 4
ROWS = [(0xFE, ['CS', 'Z', 'X', 'C', 'V']), (0xFD, ['A', 'S', 'D', 'F', 'G']), (0xFB, ['Q', 'W', 'E', 'R', 'T']),
        (0xF7, ['1', '2', '3', '4', '5']), (0xEF, ['0', '9', '8', '7', '6']), (0xDF, ['P', 'O', 'I', 'U', 'Y']),
        (0xBF, ['EN', 'L', 'K', 'J', 'H']), (0x7F, ['SP', 'SS', 'M', 'N', 'B'])]
# the keyboard as it looks: four rows of ten
LAYOUT = [list('1234567890'), list('QWERTYUIOP'), list('ASDFGHJKL') + ['EN'], ['CS'] + list('ZXCVBNM') + ['SS', 'SP']]
MOVES = ['LEFT', 'RIGHT', 'UP', 'DOWN', 'FIRE', 'DETACH']   # DefineKeys' order ($BF92)


def image():
    data = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem = bytearray(0x10000)
    mem[BASE:BASE + len(data)] = data
    return mem


def key_name(port, mask):
    for p, keys in ROWS:
        if p == port:
            for bit in range(5):
                if mask == 1 << bit:
                    return keys[bit]
    return '?'


def keyboard(draw, x0, y0, label, marks, f, fs, key=46, gap=5):
    """marks: key -> (text, colour)"""
    draw.text((x0, y0), label, fill=K.TEXT, font=f)
    y = y0 + 24
    for r, row in enumerate(LAYOUT):
        x = x0 + r * 12
        for k in row:
            text, colour = marks.get(k, ('', None))
            fill = colour or K.PANEL
            draw.rectangle([x, y, x + key, y + key], fill=fill, outline=(70, 70, 85))
            draw.text((x + 4, y + 3), {'EN': 'ENT', 'CS': 'CS', 'SS': 'SS', 'SP': 'SPC'}.get(k, k),
                      fill=(0, 0, 0) if colour else K.TEXT, font=fs)
            if text:
                draw.text((x + 4, y + key - 15), text, fill=(0, 0, 0), font=K.font(10))
            x += key + gap
        y += key + gap
    return y


def cmd_methods(args):
    mem = image()
    loaded = [key_name(mem[0x7780 + 2 * i], mem[0x7781 + 2 * i]) for i in range(6)]
    c1 = ['O', 'P', 'Q', 'A', 'M', 'N']
    H = 900
    pic = Image.new('RGB', (WIDTH, H), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs, small = K.font(15), K.font(13), K.font(12)
    d.text((12, 8), 'The four control methods: which keys or bits each reader turns into ControlBits $74FA',
           fill=K.TEXT, font=K.font(16))
    blue, green, yellow, pink, grey = (110, 160, 250), (110, 210, 130), (240, 200, 80), (230, 130, 190), (160, 160, 170)
    short = {'LEFT': 'L', 'RIGHT': 'R', 'UP': 'U', 'DOWN': 'D', 'FIRE': 'F', 'DETACH': 'X'}
    m1 = {k: (short[n], blue) for k, n in zip('12345', ['LEFT', 'RIGHT', 'DOWN', 'UP', 'FIRE'])}
    m1.update({k: (short[n], green) for k, n in zip('67890', ['LEFT', 'RIGHT', 'DOWN', 'UP', 'FIRE'])})
    m1['SP'] = ('X', grey)
    keyboard(d, 12, 40, 'Methods 1 and 4: Interface 2 (blue, ReadIf2 $8B0A, keys 1-5) and Sinclair (green, '
             'ReadSinclair $8B2D, keys 6-0)', m1, fs, small)
    m2 = {k: (short[n], yellow) for k, n in zip(loaded, MOVES)}
    keyboard(d, 12, 300, 'Method 2, the keys as loaded (DefinedKeys $7780)', m2, fs, small, key=40)
    m3 = {k: (short[n], yellow) for k, n in zip(c1, MOVES)}
    keyboard(d, 530, 300, 'Method 2, the keys c1 defined (O P Q A M N)', m3, fs, small, key=40)
    m4 = {'CS': ('pause', pink), '1': ('+1 off', pink), '2': ('+2 on', pink), 'EN': ('define', grey)}
    keyboard(d, 12, 540, 'Pause CS+1, resume CS+2 ($8B77); ENTER: DEFINE', m4, fs, small, key=40)
    # the ControlBits byte
    y = 540
    x0 = 530
    d.text((x0, y), 'ControlBits $74FA, written by every reader', fill=K.TEXT, font=fs)
    y += 26
    names = ['left', 'right', 'down', 'up', 'fire', 'detach', '0', '0']
    for b in range(8):
        x = x0 + (7 - b) * 60
        d.rectangle([x, y, x + 56, y + 40], fill=K.PANEL, outline=(90, 90, 100))
        d.text((x + 4, y + 2), f'bit {b}', fill=K.DIM, font=small)
        d.text((x + 4, y + 20), names[b], fill=K.TEXT, font=small)
    y += 52
    rows = [('Interface 2', 'keys 1 2 3 4 5 -> bits 0-4, SPACE -> 5'),
            ('keys', 'LEFT RIGHT UP DOWN FIRE DETACH -> 0 1 3 2 4 5'),
            ('Kempston', 'port $1F bits 0 1 swapped, 2-4 as read; SPACE -> 5'),
            ('Sinclair', 'keys 6 7 8 9 0 -> bits 0-4 (via BitReverse), SPACE -> 5')]
    for name, text in rows:
        d.text((x0, y), name, fill=K.TEXT, font=small)
        d.text((x0 + 100, y), text, fill=K.DIM, font=small)
        y += 20
    y = 780
    for colour, text in ((blue, 'Interface 2 (method 1)'), (green, 'Sinclair 6-0 (method 4)'),
                         (yellow, 'defined keys (method 2)'), (grey, 'SPACE: detach with a joystick (DetachKey $7794)'),
                         (pink, 'pause')):
        d.rectangle([12, y, 30, y + 14], fill=colour)
        d.text((38, y), text, fill=K.TEXT, font=small)
        y += 18
    d.text((530, 780), 'Letters on the keys: L R U D F = left, right, up, down,', fill=K.DIM,
           font=small)
    d.text((530, 798), 'fire; X = detach. Kempston (method 3) reads no key: port $1F,', fill=K.DIM, font=small)
    d.text((530, 816), 'offered only when ProbeKempston $73EC found the port quiet.', fill=K.DIM, font=small)
    pic = pic.crop((0, 0, WIDTH, 880))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    pic.save(args.out)
    print(args.out, pic.size, 'loaded keys', loaded)


def readkey_code(row, bit):
    """ReadKey $BF55: E = $2F - row, then 8 subtracted bit + 1 times"""
    return (0x2F - row - 8 * (bit + 1)) & 0xFF


def cmd_readkey(args):
    mem = image()
    table = [mem[0x72F0 + i] for i in range(5)]
    pic = Image.new('RGB', (WIDTH, 440), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, small = K.font(13), K.font(12)
    d.text((12, 8), 'ReadKey $BF55: one code a key, D = $2F - row - 8 x (bit + 1); KeyBitTable $72F0 turns it into a mask',
           fill=K.TEXT, font=K.font(15))
    x0, y0, cw, ch = 150, 70, 150, 40
    d.text((12, 40), 'half-row (port)', fill=K.DIM, font=small)
    for bit in range(5):
        d.text((x0 + bit * cw + 6, 40), f'bit {bit}  mask ${1 << bit:02X}', fill=K.DIM, font=small)
    for row, (port, keys) in enumerate(ROWS):
        y = y0 + row * ch
        d.text((12, y + 10), f'row {row}  ${port:02X}FE', fill=K.TEXT, font=f)
        for bit in range(5):
            code = readkey_code(row, bit)
            idx = (code & 0x38) >> 3
            x = x0 + bit * cw
            d.rectangle([x, y, x + cw - 6, y + ch - 6], fill=K.PANEL, outline=(70, 70, 85))
            d.text((x + 6, y + 3), keys[bit], fill=(240, 200, 80), font=f)
            d.text((x + 46, y + 3), f'D=${code:02X}', fill=K.TEXT, font=small)
            d.text((x + 46, y + 18), f'tab[{idx}]=${table[idx]:02X}', fill=K.DIM, font=small)
    y = y0 + 8 * ch + 8
    d.text((12, y), f'KeyBitTable $72F0: {" ".join("$%02X" % b for b in table)} (index = (D AND $38) / 8 = 4 - bit).'
           '; kept as (port, mask) for TestKey', fill=K.DIM, font=small)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    pic.save(args.out)
    print(args.out, pic.size)


# ---------------------------------------------------------------------------------------------------------------
# play: a window of a recording beside its keys and bytes

class Live:
    """time_travel memory_at on the instance a re_session work folder holds"""

    def __init__(self, work):
        sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
        import re_session  # noqa: E402
        self.session, _ = re_session.session_of(work)

    def mem(self, frame, address, length):
        r = self.session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': int(frame),
                                              'tinframe': 0, 'offset': address, 'length': length}, ok=False)
        data = (r.structured or {}).get('hex')
        if r.is_error or not data:
            raise SystemExit(f'memory_at {frame} ${address:04X}: {r.text}')
        return bytes.fromhex(data)


def screen(mem6912):
    buf = bytearray(0x10000)
    buf[0x4000:0x5B00] = mem6912
    return K.render_screen(buf)


def input_events(path, offset=0):
    """(frame, keys) of an input script; chords 'CS 1' are keys held together"""
    out = []
    for line in open(path):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        t, _, k = line.partition(' ')
        if not t.isdigit() or k.startswith(('POKE', 'TAPE')):
            continue
        if k == 'END':
            out.append((int(t) + offset, []))
            break
        out.append((int(t) + offset, [] if k.strip() in ('-', '') else k.replace('+', ' ').split()))
    return out


def keys_at(events, frame):
    held = []
    for f, k in events:
        if f > frame:
            break
        held = k
    return held


def parse_var(text):
    name, _, spec = text.partition('=')
    parts = spec.split(':')
    return name, int(parts[0], 16), int(parts[1]) if len(parts) > 1 else 1, parts[2] if len(parts) > 2 else 'hex'


def show(form, data):
    if form == 'bits':
        return ' '.join(f'{b:08b}' for b in data)
    if form == 'dec':
        return ' '.join(str(b) for b in data)
    if form == 'text':
        return ''.join(chr(b & 0x7F) if 32 <= (b & 0x7F) < 127 else '.' for b in data)
    return ' '.join(f'{b:02X}' for b in data)


def wrap(draw, text, x, y, width, fnt, fill):
    line = ''
    for w in text.split():
        trial = (line + ' ' + w).strip()
        if draw.textlength(trial, font=fnt) > width and line:
            draw.text((x, y), line, fill=fill, font=fnt)
            y += fnt.size + 4
            line = w
        else:
            line = trial
    if line:
        draw.text((x, y), line, fill=fill, font=fnt)
        y += fnt.size + 4
    return y


def cmd_play(args):
    live = Live(args.work)
    events = input_events(args.keys, args.offset) if args.keys else []
    frames = list(range(args.start, args.end + 1, args.step))
    vars_ = [parse_var(v) for v in args.var]
    crop = tuple(int(v) for v in args.crop.split(','))
    keys_used = []
    for f_, k in events:
        for key in k:
            if key not in keys_used and args.start - 200 <= f_ <= args.end:
                keys_used.append(key)
    sc = args.scale
    sw, sh = (crop[2] - crop[0]) * sc, (crop[3] - crop[1]) * sc
    f, fs = K.font(14), K.font(13)
    xs = sw + 30
    cw = WIDTH - xs - 16
    span = max(1, args.end - args.start)
    H = max(sh + 130, 150 + 20 * len(keys_used) + 22 * len(vars_) + 60)

    def fx(fr):
        return xs + 70 + (fr - args.start) * (cw - 70) / span

    pictures = []
    for fr in frames:
        m = live.mem(fr, 0x4000, 0x1B00)
        vals = [live.mem(fr, a, n) for _, a, n, _ in vars_]
        pic = Image.new('RGB', (WIDTH, H), K.BACKGROUND)
        d = ImageDraw.Draw(pic)
        d.text((12, 8), args.title, fill=K.TEXT, font=K.font(15))
        pic.paste(screen(m).crop(crop).resize((sw, sh), Image.NEAREST), (12, 40))
        y = 40
        d.text((xs, y), f'frame {fr}', fill=K.TEXT, font=f)
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
            d.text((xs + 230, y), show(form, v), fill=K.TEXT, font=fs)
            y += 22
        if events:
            held = keys_at(events, fr)
            d.text((12, 48 + sh), 'keys held: ' + (' '.join(held) if held else 'none'), fill=(255, 210, 70), font=f)
        wrap(d, args.note or ('Memory and screen sampled at T 0 of each frame: what the code did before the frame '
                              'began.' + (' Blue bars: the keys of the input script; yellow line: this frame.'
                                          if events else '')),
             12, max(76 + sh, y + 6), WIDTH - 24, K.font(12), K.DIM)
        pictures.append(pic)
    K.save_gif(args.out, pictures, [args.delay] * (len(pictures) - 1) + [args.hold])
    print(args.out, len(pictures), pictures[0].size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    for name in ('methods', 'readkey'):
        s = sub.add_parser(name)
        s.add_argument('--out', required=True)
    s = sub.add_parser('play')
    s.add_argument('--work', required=True)
    s.add_argument('--from', dest='start', type=int, required=True)
    s.add_argument('--to', dest='end', type=int, required=True)
    s.add_argument('--step', type=int, default=2)
    s.add_argument('--keys', help='the input script')
    s.add_argument('--offset', type=int, default=0, help="the recording's frame of the script's frame 0")
    s.add_argument('--crop', default='0,0,256,192', help='x0,y0,x1,y1 of the screen in pixels')
    s.add_argument('--scale', type=int, default=2)
    s.add_argument('--var', action='append', default=[], help='NAME=ADDR[:LEN[:hex|bits|dec|text]]')
    s.add_argument('--title', default='')
    s.add_argument('--note', default='')
    s.add_argument('--delay', type=int, default=90)
    s.add_argument('--hold', type=int, default=1500)
    s.add_argument('--out', required=True)
    args = p.parse_args()
    {'methods': cmd_methods, 'readkey': cmd_readkey, 'play': cmd_play}[args.cmd](args)


if __name__ == '__main__':
    main()
