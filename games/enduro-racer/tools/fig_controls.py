#!/usr/bin/env python3
"""The figures of doc 5 (controls) and the play animations of docs 5, 6 and 8.

    python3 tools/fig_controls.py methods --out docs/img/controls/methods.png
    python3 tools/fig_controls.py keymap --out docs/img/controls/keymap.png
    python3 tools/fig_controls.py steer --out docs/img/controls/steer.png
    python3 tools/fig_controls.py speed --work W --from F --to G --out docs/img/controls/speed.png
    python3 tools/fig_controls.py play --work W --from F --to G --step S --keys tests/inputs/c1.txt \
        --crop 0,0,256,192 --var 'Speed=7C34:1:dec' ... --title T --out docs/img/play/NAME.gif

methods: the five control methods of ControlTable ($8323, build/game.bin): for each, the keys (or the Kempston bits)
of THROTTLE, WHEELIE, LEFT, RIGHT, BRAKES on a keyboard, and the bit each sets in ReadControls' D. keymap: the 40
keys as ScanKeys finds them (half row, bit, KeyMap's character). steer: LeanTable ($8E56) and the even entries of
SteerTable ($8E5D), and the sideways speed they give (capped at 5) for each lean and speed. speed: SPEED as Throttle
($A9DC) computes it pass by pass (throttle held, then brakes), beside SPEED sampled in a recording. play: a window of
a recording, the screen (cropped) beside the keys of its input script and the bytes named by --var, all sampled at
T 0 of each frame (time_travel memory_at).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

WIDTH = 1050
BASE = 0x5B00

# the half rows as the ULA reads them: port high byte, keys from bit 0 to bit 4
ROWS = [(0xFE, ['CS', 'Z', 'X', 'C', 'V']), (0xFD, ['A', 'S', 'D', 'F', 'G']), (0xFB, ['Q', 'W', 'E', 'R', 'T']),
        (0xF7, ['1', '2', '3', '4', '5']), (0xEF, ['0', '9', '8', '7', '6']), (0xDF, ['P', 'O', 'I', 'U', 'Y']),
        (0xBF, ['EN', 'L', 'K', 'J', 'H']), (0x7F, ['SP', 'SS', 'M', 'N', 'B'])]
LAYOUT = [list('1234567890'), list('QWERTYUIOP'), list('ASDFGHJKL') + ['EN'], ['CS'] + list('ZXCVBNM') + ['SS', 'SP']]
ACTIONS = ['THROTTLE', 'WHEELIE', 'LEFT', 'RIGHT', 'BRAKES']
SHORT = ['T', 'W', 'L', 'R', 'B']
METHODS = ['0 KEYBOARD', '1 KEMPSTON', '2 SINCLAIR RIGHT', '3 SINCLAIR LEFT', '4 CURSOR']
KEMPSTON = {1: 'right', 2: 'left', 4: 'down', 8: 'up', 0x10: 'fire'}
COLOURS = [(240, 200, 70), (90, 200, 120), (90, 150, 250), (230, 90, 80), (200, 110, 230)]


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


def keyboard(draw, x0, y0, marks, fs, key=38, gap=4):
    """marks: key -> (text, colour)"""
    for r, row in enumerate(LAYOUT):
        x = x0 + r * 10
        for k in row:
            text, col = marks.get(k, ('', None))
            box = [x, y0 + r * (key + gap), x + key, y0 + r * (key + gap) + key]
            draw.rectangle(box, fill=col if col else K.PANEL, outline=K.DIM)
            draw.text((x + 3, box[1] + 2), k, fill=(0, 0, 0) if col else K.TEXT, font=fs)
            if text:
                draw.text((x + 3, box[1] + 19), text, fill=(0, 0, 0), font=fs)
            x += key + gap


def cmd_methods(args):
    mem = image()
    table = mem[0x8323:0x8323 + 50]
    f, fs, ft = K.font(14), K.font(12), K.font(16)
    pic = Image.new('RGB', (WIDTH, 1010), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), 'The five control methods: ControlTable $8323, 5 x 10 bytes, patched into ReadControls $85B0', fill=K.TEXT, font=ft)
    y = 40
    for m in range(5):
        row = table[m * 10:m * 10 + 10]
        x0 = 12 + (m % 2) * 520
        y0 = y + (m // 2) * 300
        d.text((x0, y0), METHODS[m] + ('   (the power-on method)' if m == 3 else ''), fill=K.TEXT, font=f)
        bytes_text = ' '.join(f'{b:02X}' for b in row)
        d.text((x0, y0 + 20), 'bytes: ' + bytes_text, fill=K.DIM, font=fs)
        if m == 1:
            # the Kempston: port $1F, active high, bit per direction
            d.text((x0, y0 + 44), 'port $001F, JR Z (a set bit is a press)', fill=K.TEXT, font=fs)
            for i in range(5):
                mask = row[5 + i]
                bit = mask.bit_length() - 1
                bx = x0 + i * 96
                d.rectangle([bx, y0 + 70, bx + 90, y0 + 130], fill=COLOURS[i], outline=K.DIM)
                d.text((bx + 4, y0 + 74), f'bit {bit}', fill=(0, 0, 0), font=fs)
                d.text((bx + 4, y0 + 92), KEMPSTON[mask], fill=(0, 0, 0), font=fs)
                d.text((bx + 4, y0 + 110), ACTIONS[i], fill=(0, 0, 0), font=fs)
            d.text((x0, y0 + 150), 'The Kempston interface puts the stick on the data bus', fill=K.DIM, font=fs)
            d.text((x0, y0 + 168), 'of any IN whose address has A5 = 0; the game reads $001F.', fill=K.DIM, font=fs)
            continue
        marks = {}
        for i in range(5):
            k = key_name(row[i], row[5 + i])
            marks[k] = (SHORT[i], COLOURS[i])
        d.text((x0, y0 + 44), 'port $xxFE, JR NZ (a clear bit is a press)', fill=K.TEXT, font=fs)
        keyboard(d, x0, y0 + 66, marks, fs)
    # the legend and D
    ly = y + 3 * 300 - 40
    d.text((12, ly), 'ReadControls returns D:', fill=K.TEXT, font=f)
    for i, a in enumerate(ACTIONS + ['PAUSE (H)', 'RESET (R)']):
        bx = 230 + i * 116
        col = COLOURS[i] if i < 5 else (185, 185, 185)
        d.rectangle([bx, ly - 2, bx + 110, ly + 36], fill=col, outline=K.DIM)
        d.text((bx + 4, ly), f'bit {i}', fill=(0, 0, 0), font=fs)
        d.text((bx + 4, ly + 17), a, fill=(0, 0, 0), font=fs)
    d.text((12, ly + 48), 'Letters on the keys: T throttle, W wheelie, L left, R right, B brakes. PAUSE H and RESET R '
                          'are always keys (bits 5, 6).', fill=K.DIM, font=fs)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_keymap(args):
    mem = image()
    keymap = mem[0x8520:0x8548]
    names = {1: 'SS', 2: 'EN', 3: 'SP', 4: 'CS'}
    f, fs, ft = K.font(14), K.font(12), K.font(16)
    pic = Image.new('RGB', (WIDTH, 440), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), 'ScanKeys $84F3 and KeyMap $8520: the character of each half row and bit', fill=K.TEXT, font=ft)
    hdr = ['loop B', 'port', 'bit 4', 'bit 3', 'bit 2', 'bit 1', 'bit 0']
    xs = [12, 110, 230, 390, 550, 710, 870]
    for x, h in zip(xs, hdr):
        d.text((x, 44), h, fill=K.DIM, font=f)
    # ScanKeys starts with C = $FE and rotates it left: $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F; B counts 8 down to 1
    c = 0xFE
    for i in range(8):
        b = 8 - i
        y = 70 + i * 40
        d.text((xs[0], y), str(b), fill=K.TEXT, font=f)
        d.text((xs[1], y), f'${c:02X}FE', fill=K.TEXT, font=f)
        for bit in range(5):
            dcount = 5 - bit
            idx = 5 * b + dcount - 6
            ch = keymap[idx]
            text = names.get(ch, chr(ch))
            x = xs[2 + (4 - bit)]
            d.rectangle([x, y - 4, x + 150, y + 28], fill=K.PANEL, outline=K.DIM)
            d.text((x + 6, y), f'{text:3s} KeyMap+{idx:<2d} D={dcount}', fill=K.TEXT, font=fs)
        c = ((c << 1) | (c >> 7)) & 0xFF
    d.text((12, 400), 'The index is 5 x B + D - 6 (the code adds B x 5 + D to KeyMap - 6). A half row is matched '
                      'only when exactly one of its five keys is down.', fill=K.DIM, font=fs)
    d.text((12, 418), 'Codes 1-4 are SYMBOL SHIFT, ENTER, SPACE, CAPS SHIFT (KeyNames prints them SYM ENT SPC CPS).',
           fill=K.DIM, font=fs)
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_steer(args):
    mem = image()
    lean = [mem[0x8E56 + i] for i in range(7)]
    steer = [mem[0x8E5D + i] for i in range(21)]
    f, fs, ft = K.font(13), K.font(12), K.font(16)
    pic = Image.new('RGB', (WIDTH, 560), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), 'The sideways speed: SteerTable[2 x (ScrollStep >> 8)] x LeanTable[lean + 3] / 8',
           fill=K.TEXT, font=ft)
    d.text((12, 30), 'ScrollStep = SPEED x 14; the high byte of the 8.8 result is capped at 5 (its low byte is kept)',
           fill=K.DIM, font=f)
    x0, y0, w, h = 80, 80, 600, 400
    d.rectangle([x0, y0, x0 + w, y0 + h], outline=K.DIM)
    for v in range(0, 7):
        yy = y0 + h - v * h / 6.5
        d.line([x0, yy, x0 + w, yy], fill=(40, 40, 52))
        d.text((x0 - 30, yy - 8), str(v), fill=K.DIM, font=fs)
    for sp in range(0, 201, 25):
        xx = x0 + sp * w / 200
        d.line([xx, y0, xx, y0 + h], fill=(40, 40, 52))
        d.text((xx - 10, y0 + h + 6), str(sp), fill=K.DIM, font=fs)
    d.text((x0 + w / 2 - 60, y0 + h + 26), 'SPEED (km/h)', fill=K.TEXT, font=f)
    d.text((10, y0 - 22), 'pixels a pass', fill=K.TEXT, font=f)
    for li, col in zip((1, 2, 3), COLOURS[:3]):
        pts = []
        for sp in range(0, 201):
            step = sp * 14
            s = steer[2 * (step >> 8)]
            de = s * lean[li + 3] // 8
            if de >> 8 >= 5:
                de = 5 * 256 + (de & 0xFF)   # the code caps the high byte only
            pts.append((x0 + sp * w / 200, y0 + h - de / 256 * h / 6.5))
        d.line(pts, fill=col, width=3)
        d.text((pts[-1][0] + 8, pts[-1][1] - 8), f'lean {li}', fill=col, font=f)
    tx = 760
    d.text((tx, 60), 'LeanTable $8E56', fill=K.TEXT, font=f)
    for i, v in enumerate(lean):
        d.text((tx, 84 + i * 18), f'lean {i - 3:+d}: ${v:02X} ({v})', fill=K.TEXT, font=fs)
    d.text((tx, 230), 'SteerTable $8E5D (even entries)', fill=K.TEXT, font=f)
    for i in range(0, 21, 2):
        d.text((tx, 254 + (i // 2) * 18), f'[{i:2d}] ${steer[i]:02X} ({steer[i]:3d})  {i // 2 * 256 / 14:5.1f} km/h+',
               fill=K.TEXT, font=fs)
    d.text((12, 530), 'Negative leans: the same, subtracted. One table entry every 18.3 km/h; '
                      'the cap holds lean 3 to 127 km/h, lean 2 to 54.', fill=K.DIM, font=fs)
    pic.save(args.out)
    print(args.out, pic.size)


def throttle(speed, keys):
    """One pass of Throttle $A9DC: speed in 8.8 units, keys bit 0 throttle, bit 4 brakes"""
    h = speed >> 8
    if keys & 1:
        if h < 0x14:
            de = (speed + 0x100) >> 2
        elif h < 0xA0:
            de = 0x220
        else:
            de = (0xC800 - speed) >> 4
        return speed + de
    if keys & 0x10:
        return max(0, speed - 0x580)
    return speed


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


def cmd_speed(args):
    live = Live(args.work)
    # the recording: SPEED and PassCount at each frame
    samples = []
    for fr in range(args.start, args.end + 1, 2):
        m = live.mem(fr, 0x7C2E, 7)
        samples.append((fr, m[0], m[6] + m[5] / 256))  # SPEED: $7C34 km/h, $7C33 the fraction
    # the model: from the recording's first pass, throttle held for --throttle passes, then brakes
    passes = []
    last = None
    for fr, pc, sp in samples:
        if pc != last:
            passes.append((fr, sp))
            last = pc
    events = input_events(args.keys)
    # the model starts at the first pass that moves (Throttle waits for the countdown's GO)
    first = next((i for i in range(1, len(passes)) if passes[i][1] != passes[i - 1][1]), 1) - 1
    passes = passes[first:]
    model = [passes[0][1] * 256]
    for i in range(1, len(passes)):
        held = keys_at(events, passes[i - 1][0])
        model.append(throttle(int(model[-1]), (1 if args.throttle in held else 0) |
                              (0x10 if args.brakes in held else 0)))
    f, fs, ft = K.font(13), K.font(12), K.font(16)
    pic = Image.new('RGB', (WIDTH, 520), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), args.title, fill=K.TEXT, font=ft)
    x0, y0, w, h = 70, 90, 940, 340
    top = 200
    d.rectangle([x0, y0, x0 + w, y0 + h], outline=K.DIM)
    for v in range(0, top + 1, 25):
        yy = y0 + h - v * h / top
        d.line([x0, yy, x0 + w, yy], fill=(40, 40, 52))
        d.text((x0 - 36, yy - 8), str(v), fill=K.DIM, font=fs)
    span = args.end - args.start

    def X(fr):
        return x0 + (fr - args.start) * w / span
    for t in range(args.start - args.start % 100 + 100, args.end + 1, 100):
        d.line([X(t), y0, X(t), y0 + h], fill=(40, 40, 52))
        d.text((X(t) - 18, y0 + h + 6), str(t), fill=K.DIM, font=fs)
    d.text((x0 + w / 2 - 80, y0 + h + 26), f'frame of {args.label}', fill=K.TEXT, font=f)
    d.line([(X(fr), y0 + h - sp * h / top) for fr, _, sp in samples], fill=(90, 150, 250), width=3)
    pts = [(X(fr), y0 + h - (m / 256) * h / top) for (fr, _), m in zip(passes, model)]
    for p in pts:
        d.ellipse([p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3], outline=(240, 200, 70))
    d.text((x0, 34), f'blue: SPEED $7C33-$7C34 in {args.label} (memory_at T 0, every 2nd frame)',
           fill=(90, 150, 250), font=f)
    d.text((x0, 54), f'yellow rings: Throttle\'s formula a pass from the first pass that moves, '
                               f'keys from the script ({args.throttle}, {args.brakes})', fill=(240, 200, 70), font=f)
    d.text((12, 480), args.note, fill=K.DIM, font=fs)
    pic.save(args.out)
    print(args.out, pic.size, len(passes), 'passes')


def input_events(path, offset=0):
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
    name, _, spec = text.rpartition('=')
    parts = spec.split(':')
    return name, int(parts[0], 16), int(parts[1]) if len(parts) > 1 else 1, parts[2] if len(parts) > 2 else 'hex'


def show(form, data):
    if form == 'bits':
        return ' '.join(f'{b:08b}' for b in data)
    if form == 'dec':
        return ' '.join(str(b) for b in data)
    if form == 'sdec':
        return ' '.join(str(b - 256 if b > 127 else b) for b in data)
    if form == 'word':
        return f'${data[0] | data[1] << 8:04X}'
    if form == 'tests':
        # ReadControls' five tests, 10 bytes each (LD A,n / IN A,(n) / AND n / JR cc): half row / mask, K for port $1F
        return ' '.join(f'{data[i + 1]:02X}{"/" if data[i + 3] == 0xFE else "K"}{data[i + 5]:02X}' for i in range(0, len(data) - 9, 10))
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


def screen(mem6912):
    buf = bytearray(0x10000)
    buf[0x4000:0x5B00] = mem6912
    return K.render_screen(buf)


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
    sw0, sh0 = crop[2] - crop[0], crop[3] - crop[1]
    sc = args.scale
    sw, sh = sw0 * sc, sh0 * sc
    f, fs = K.font(14), K.font(13)
    if sw > 640:
        xs, ys = 12, 52 + sh + 30     # the panel under the screen
        cw = WIDTH - 40
    else:
        xs, ys = sw + 30, 52
        cw = WIDTH - xs - 16
    span = max(1, args.end - args.start)
    panel = 34 + 20 * len(keys_used) + 22 * len(vars_) + 70
    H = max(52 + sh + 60, ys + panel) if xs > 12 else ys + panel

    def fx(fr):
        return xs + 70 + (fr - args.start) * (cw - 70) / span

    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    label_w = max([220] + [int(probe.textlength(f'{n} ${a:04X}', font=fs)) + 14 for n, a, _, _ in vars_])
    pictures = []
    for fr in frames:
        m = live.mem(fr, 0x4000, 0x1B00)
        vals = [live.mem(fr, a, n) for _, a, n, _ in vars_]
        pic = Image.new('RGB', (WIDTH, H), K.BACKGROUND)
        d = ImageDraw.Draw(pic)
        wrap(d, args.title, 12, 6, WIDTH - 24, K.font(15), K.TEXT)
        pic.paste(screen(m).crop(crop).resize((sw, sh), Image.NEAREST), (12, 52))
        y = ys
        held = keys_at(events, fr) if events else []
        d.text((xs, y), f'frame {fr}' + (f'    keys held: {" ".join(held) if held else "none"}' if events else ''),
               fill=(255, 210, 70), font=f)
        y += 26
        if keys_used:
            for key in keys_used:
                d.text((xs, y), key, fill=K.TEXT, font=fs)
                for (f0, k), nxt in zip(events, events[1:] + [(args.end + 1, [])]):
                    if key in k and nxt[0] > args.start and f0 < args.end:
                        a, b = max(f0, args.start), min(nxt[0], args.end)
                        d.rectangle([fx(a), y + 3, max(fx(a) + 2, fx(b)), y + 13], fill=(90, 150, 250))
                y += 20
            d.line([fx(fr), ys + 22, fx(fr), y], fill=(255, 210, 70), width=2)
            y += 8
        for (name, a, n, form), v in zip(vars_, vals):
            d.text((xs, y), f'{name} ${a:04X}', fill=K.DIM, font=fs)
            d.text((xs + label_w, y), show(form, v), fill=K.TEXT, font=fs)
            y += 22
        wrap(d, args.note or ('Screen and memory sampled at T 0 of each frame: what the code did before the frame '
                              'began.' + (' Blue bars: the keys of the input script; yellow line: this frame.'
                                          if events else '')),
             xs, y + 6, cw, K.font(12), K.DIM)
        pictures.append(pic)
    K.save_gif(args.out, pictures, [args.delay] * (len(pictures) - 1) + [args.hold])
    print(args.out, len(pictures), pictures[0].size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    for name in ('methods', 'keymap', 'steer'):
        s = sub.add_parser(name)
        s.add_argument('--out', required=True)
    s = sub.add_parser('speed')
    s.add_argument('--work', required=True)
    s.add_argument('--from', dest='start', type=int, required=True)
    s.add_argument('--to', dest='end', type=int, required=True)
    s.add_argument('--keys', required=True, help='the input script')
    s.add_argument('--throttle', default='Q', help="the throttle's key in the script")
    s.add_argument('--brakes', default='SPACE', help="the brakes' key in the script")
    s.add_argument('--label', default='c1')
    s.add_argument('--title', default='')
    s.add_argument('--note', default='')
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
    s.add_argument('--var', action='append', default=[], help='NAME=ADDR[:LEN[:hex|bits|dec|sdec|word|text|tests]]')
    s.add_argument('--title', default='')
    s.add_argument('--note', default='')
    s.add_argument('--delay', type=int, default=90)
    s.add_argument('--hold', type=int, default=1500)
    s.add_argument('--out', required=True)
    args = p.parse_args()
    {'methods': cmd_methods, 'keymap': cmd_keymap, 'steer': cmd_steer, 'speed': cmd_speed,
     'play': cmd_play}[args.cmd](args)


if __name__ == '__main__':
    main()
