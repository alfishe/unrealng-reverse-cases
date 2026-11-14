#!/usr/bin/env python3
"""The figures of doc 05 (the controls).

    python3 tools/fig_controls.py layout docs/img/controls/keys.png
    python3 tools/fig_controls.py keys --work W --inputs tests/inputs/controls-keyboard.txt --from F --to T
           [--step 2] docs/img/play/rick-keys.gif

layout: the Spectrum keyboard as the game reads it: 8 half rows of 5 keys, each with its port and the bit of each
key; a key's colour tags name its roles (the keyboard method, the cursor keys, Sinclair, the menu digits, pause,
quit, the two cheat chords). Under it the byte Controls `$7253` and the Kempston port `$1F`, bit by bit.

keys: a GIF of a recording, one picture every --step frames, read with TTD memory_at from the unreal-ng instance
that holds it (kit/rs.py open). Left: the screen. Right: the keys the input script holds at that frame, the byte
Controls `$7253` as ReadControls left it (a lit box is a control held, the bit at 0), Rick's variables
(`$9B95-$9BC6`), and a strip chart of RickX and RickY over the whole window with the current frame marked.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import zxscreen  # noqa: E402

W = 1050

# Half rows: port high byte, keys from bit 0 to bit 4
HALF_ROWS = [
    (0xF7, ['1', '2', '3', '4', '5']), (0xEF, ['0', '9', '8', '7', '6']),
    (0xFB, ['Q', 'W', 'E', 'R', 'T']), (0xDF, ['P', 'O', 'I', 'U', 'Y']),
    (0xFD, ['A', 'S', 'D', 'F', 'G']), (0xBF, ['ENT', 'L', 'K', 'J', 'H']),
    (0xFE, ['CS', 'Z', 'X', 'C', 'V']), (0x7F, ['SP', 'SS', 'M', 'N', 'B']),
]

ROLES = [
    ('keyboard (method 0)', (90, 200, 120), {'O': 'up', 'K': 'down', 'Z': 'left', 'X': 'right', 'SP': 'fire',
                                             'ENT': 'fire'}),
    ('cursor (method 2)', (90, 150, 250), {'5': 'left', '6': 'down', '7': 'up', '8': 'right', '0': 'fire'}),
    ('Sinclair (method 3)', (240, 200, 70), {'6': 'left', '7': 'right', '8': 'down', '9': 'up', '0': 'fire'}),
    ('menu digits', (200, 200, 200), {'0': 'start', '1': 'kbd/L1', '2': 'kemp/L2', '3': 'curs/L3',
                                      '4': 'sinc/L4', '5': 'L5'}),
    ('pause / quit', (250, 150, 60), {'P': 'pause', 'E': 'quit'}),
    ('C+S+3: infinite lives', (230, 90, 80), {'C': 'cheat', 'S': 'cheat', '3': 'cheat'}),
    ('SPACE+N+ENTER+J+Y: exits', (200, 110, 230), {'SP': 'cheat', 'N': 'cheat', 'ENT': 'cheat', 'J': 'cheat',
                                                    'Y': 'cheat'}),
]


def fig_layout(args):
    f, fs, fb = K.font(14), K.font(11), K.font(16)
    kw, kh, gap = 92, 86, 6
    img = Image.new('RGB', (W, 760), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((16, 10), 'The keys Rick Dangerous 2 reads: half row (port), key, bit, and each key\'s roles', fill=K.TEXT,
           font=fb)
    y0 = 44
    for row in range(4):
        for side in range(2):
            hi, keys = HALF_ROWS[row * 2 + side]
            order = keys if side == 1 else keys
            # the left half row shows bit 4 at the right end next to the middle, as on the keyboard: bit 0 outermost
            cols = list(range(5)) if side == 0 else list(range(4, -1, -1))
            x_base = 16 + side * (5 * (kw + gap) + 30)
            for slot, bit in enumerate(cols):
                key = order[bit]
                x = x_base + slot * (kw + gap)
                y = y0 + row * (kh + 30)
                d.rounded_rectangle((x, y, x + kw, y + kh), 6, fill=K.PANEL, outline=K.DIM)
                d.text((x + 6, y + 4), key, fill=K.TEXT, font=f)
                d.text((x + kw - 36, y + 6), 'bit %d' % bit, fill=K.DIM, font=fs)
                ty = y + 24
                for name, col, keymap in ROLES:
                    if key in keymap:
                        d.rectangle((x + 4, ty, x + kw - 4, ty + 13), fill=tuple(c // 3 for c in col), outline=col)
                        d.text((x + 7, ty), keymap[key], fill=col, font=fs)
                        ty += 15
            lx = x_base
            d.text((lx, y0 + row * (kh + 30) + kh + 4), 'port $%02XFE' % hi, fill=K.DIM, font=fs)
    # legend
    ly = y0 + 4 * (kh + 30) + 4
    x = 16
    for name, col, _ in ROLES:
        tw = d.textlength(name, font=fs)
        if x + tw + 30 > W:
            x, ly = 16, ly + 20
        d.rectangle((x, ly + 2, x + 12, ly + 14), fill=col)
        d.text((x + 18, ly), name, fill=K.TEXT, font=fs)
        x += tw + 40
    # Controls and Kempston bytes
    by = ly + 34
    for i, (title, bits) in enumerate([
            ('Controls $7253 (every interrupt): a bit at 0 is a control held',
             ['1', '1', '1', 'fire', 'up', 'down', 'left', 'right']),
            ('Kempston port $1F: 1 = held; ReadControls takes AND $1F, CPL',
             ['-', '-', '-', 'fire', 'up', 'down', 'left', 'right'])]):
        yy = by + i * 70
        d.text((16, yy), title, fill=K.TEXT, font=f)
        for b in range(8):
            x = 16 + b * 76
            d.rectangle((x, yy + 22, x + 70, yy + 56), fill=K.PANEL, outline=K.DIM)
            d.text((x + 4, yy + 24), 'bit %d' % (7 - b), fill=K.DIM, font=fs)
            d.text((x + 4, yy + 38), bits[b], fill=K.TEXT, font=fs)
    d.text((650, by + 22), 'O over K, Z over X: a held O hides K,\na held Z hides X (the keyboard).\n'
           'Cursor: 8 hides 5; 7 hides 6.\nSinclair: 6 hides 7; 9 hides 8.\nRead without CAPS SHIFT.',
           fill=K.TEXT, font=fs)
    img = img.crop((0, 0, W, by + 150))
    img.save(args.out)
    print(args.out, img.size)


def script_keys(path):
    """frame -> the keys held from that frame (an input script of kit's form: N or +N, then keys or -)."""
    held, frame, out = [], 0, []
    for line in open(path):
        line = line.split('#')[0].strip()
        if not line:
            continue
        parts = line.split()
        t = parts[0]
        frame = frame + int(t[1:]) if t.startswith('+') else int(t)
        keys = [k for k in parts[1:] if k != '-']
        if 'END' in keys:
            break
        out.append((frame, keys))
    return out


def held_at(table, frame):
    keys = []
    for f, k in table:
        if f <= frame:
            keys = k
    return keys


def fig_keys(args):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)

    def mem(frame, addr, n):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                         'offset': addr, 'length': n}, ok=False)
        return bytes.fromhex((r.structured or {})['hex'])

    table = script_keys(args.inputs)
    frames = list(range(args.start, args.end + 1, args.step))
    samples = []
    for fr in frames:
        samples.append((fr, mem(fr, 0x4000, 0x1B00), mem(fr, 0x7252, 2), mem(fr, 0x9B95, 0x32)))
    f, fs, fb = K.font(13), K.font(11), K.font(15)
    xs = [s[3][0x17] for s in samples]
    ys = [s[3][0x18] | s[3][0x19] << 8 for s in samples]
    pictures = []
    for i, (fr, scr, ctl, v) in enumerate(samples):
        img = Image.new('RGB', (W, 420), K.BACKGROUND)
        img.paste(zxscreen.render(scr, 2).convert('RGB'), (4, 30))
        d = ImageDraw.Draw(img)
        d.text((8, 6), args.title, fill=K.TEXT, font=fb)
        px = 530
        d.text((px, 30), 'frame %d' % fr, fill=K.TEXT, font=fb)
        keys = held_at(table, fr)
        d.text((px + 120, 30), 'keys held: ' + (' + '.join(keys) if keys else '(none)'), fill=(250, 220, 120),
               font=fb)
        c = ctl[1]
        d.text((px, 60), 'Controls $7253 = $%02X' % c, fill=K.TEXT, font=f)
        for b, name in enumerate(['right', 'left', 'down', 'up', 'fire']):
            x = px + 180 + (4 - b) * 66
            on = not (c >> b) & 1
            d.rectangle((x, 58, x + 60, 78), fill=(90, 200, 120) if on else K.PANEL, outline=K.DIM)
            d.text((x + 4, 60), name, fill=K.BACKGROUND if on else K.DIM, font=fs)
        dy = v[0] | v[1] << 8
        dy = (dy - 0x10000 if dy >= 0x8000 else dy) / 256.0
        rows = [
            ('RickX $9BAC', '%d' % v[0x17]), ('RickY $9BAD', '%d' % (v[0x18] | v[0x19] << 8)),
            ('RickDy $9B95', '%+.2f px a pass' % dy), ('RickOnGround $9B9D', '$%02X' % v[0x08]),
            ('RickCrawling $9B98', '$%02X' % v[0x03]), ('RickClimbing $9B99', '$%02X' % v[0x04]),
            ('RickFacing $9BB1', 'left' if v[0x1C] & 0x80 else 'right'),
            ('FireLatch $9BA8', '$%02X' % v[0x13]), ('PunchTimer $9BA3', '%d' % v[0x0E]),
            ('Bullet $9BB4', ('x %d' % v[0x20]) if v[0x1F] else 'off'),
            ('Detonator $9BBD', ('x %d fuse %d' % (v[0x29], v[0x31])) if v[0x28] else 'off'),
            ('RickDying $9B9C', '$%02X' % v[0x07]),
        ]
        for j, (name, val) in enumerate(rows):
            col, row = j % 2, j // 2
            x, y = px + col * 258, 90 + row * 20
            d.text((x, y), name, fill=K.DIM, font=fs)
            d.text((x + 140, y), val, fill=K.TEXT, font=fs)
        # strip chart
        cx0, cy0, cw, ch = px, 222, 510, 180
        d.rectangle((cx0, cy0, cx0 + cw, cy0 + ch), fill=K.PANEL)
        d.text((cx0 + 4, cy0 + 2), 'RickX (green, 0-232) and RickY (blue, 180-240, down) by frame', fill=K.DIM,
               font=fs)
        n = len(samples)

        def pt(k, val, lo, hi):
            return (cx0 + 4 + k * (cw - 8) / max(1, n - 1),
                    cy0 + 20 + (val - lo) * (ch - 26) / (hi - lo))
        d.line([pt(k, 232 - x_, 0, 232) for k, x_ in enumerate(xs)], fill=(45, 100, 60), width=1)
        d.line([pt(k, 232 - x_, 0, 232) for k, x_ in enumerate(xs[:i + 1])], fill=(90, 200, 120), width=2)
        d.line([pt(k, min(240, max(180, y_)), 180, 240) for k, y_ in enumerate(ys)], fill=(45, 75, 125), width=1)
        d.line([pt(k, min(240, max(180, y_)), 180, 240) for k, y_ in enumerate(ys[:i + 1])], fill=(90, 150, 250),
               width=2)
        mx = pt(i, 0, 0, 1)[0]
        d.line((mx, cy0 + 18, mx, cy0 + ch), fill=(250, 220, 120))
        for fr2, k2 in table:
            if args.start <= fr2 <= args.end and k2:
                kx = cx0 + 4 + (fr2 - args.start) / max(1, args.step) * (cw - 8) / max(1, n - 1)
                d.text((kx, cy0 + ch - 14), '+'.join(k2)[:9], fill=(200, 180, 110), font=K.font(10))
        pictures.append(img)
    K.save_gif(args.out, pictures, [args.step * 20] * (len(pictures) - 1) + [2000])
    print(args.out, len(pictures), 'pictures')


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('layout')
    p.add_argument('out')
    p.set_defaults(fn=fig_layout)
    p = sub.add_parser('keys')
    p.add_argument('--work', required=True)
    p.add_argument('--inputs', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--title', default='Rick answering the keys (controls-keyboard)')
    p.add_argument('out')
    p.set_defaults(fn=fig_keys)
    a = ap.parse_args()
    a.fn(a)


if __name__ == '__main__':
    main()
