#!/usr/bin/env python3
"""The figures of doc 5 (controls), from the listing and from recordings.

    python3 tools/fig_controls.py keyboard --out docs/img/controls/keyboard.png
    python3 tools/fig_controls.py bits --out docs/img/controls/inputbits.png
    python3 tools/fig_controls.py menu --work W --inputs tests/inputs/controls.txt --from 620 --to 700 --step 2 \
        --out docs/img/play/menu-keys.gif
    python3 tools/fig_controls.py rick --work W --inputs tests/inputs/controls.txt --from 150 --to 320 --step 2 \
        --out docs/img/play/rick-keys.gif
    python3 tools/fig_controls.py timeline --work W --inputs tests/inputs/controls.txt --from 150 --to 330 \
        --out docs/img/controls/timeline.png

W is a re_session work folder whose instance holds the recording (kit/rs.py open). Memory is read with time_travel
memory_at at each frame's start (tinframe 0): a sample of frame N shows what the passes that ended before N did.
The keys are those the input script holds from its frame on.

The keyboard and bits figures name each key by the instruction that reads it; the script checks every address it
draws against build/game.lst (the BIT instruction and the port loaded before it), so a figure cannot drift from the
source.
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

# (key, port high byte, bit, use, the BIT instruction's address)
READS = [
    ('O', 0xDF, 1, 'kbd', 0xA160), ('K', 0xBF, 2, 'kbd', 0xA16F), ('Z', 0xFE, 1, 'kbd', 0xA17B),
    ('X', 0xFE, 2, 'kbd', 0xA18A), ('ENTER', 0xBF, 0, 'kbd', 0xA196),
    ('0', 0xEF, 0, 'cur', 0xA1B4), ('8', 0xEF, 2, 'cur', 0xA1BB), ('7', 0xEF, 3, 'cur', 0xA1C2),
    ('6', 0xEF, 4, 'cur', 0xA1CC), ('5', 0xF7, 4, 'cur', 0xA1DD),
    ('0', 0xEF, 0, 'sin', 0xA1EB), ('6', 0xEF, 4, 'sin', 0xA1F2), ('7', 0xEF, 3, 'sin', 0xA1FC),
    ('9', 0xEF, 1, 'sin', 0xA203), ('8', 0xEF, 2, 'sin', 0xA20C),
    ('1', 0xF7, 0, 'menu', 0xA108), ('2', 0xF7, 1, 'menu', 0xA110), ('3', 0xF7, 2, 'menu', 0xA118),
    ('4', 0xF7, 3, 'menu', 0xA120),
    ('ENTER', 0xBF, 0, 'start', 0xA128), ('Q', 0xFB, 0, 'quit', 0xA141), ('P', 0xDF, 0, 'pause', 0xA149),
]
USES = {
    'kbd': ('keyboard (method 0)', (90, 200, 120)),
    'cur': ('cursor keys (method 2)', (240, 200, 70)),
    'sin': ('Sinclair (method 3)', (90, 150, 250)),
    'menu': ('menu: the method', (200, 110, 230)),
    'start': ('start / continue', (70, 210, 220)),
    'quit': ('Q: quit the game', (230, 90, 80)),
    'pause': ('P: pause', (250, 150, 60)),
}
MEANING = {('kbd', 'O'): 'up', ('kbd', 'K'): 'down', ('kbd', 'Z'): 'left', ('kbd', 'X'): 'right',
           ('kbd', 'ENTER'): 'fire', ('cur', '0'): 'fire', ('cur', '8'): 'right', ('cur', '7'): 'up',
           ('cur', '6'): 'down', ('cur', '5'): 'left', ('sin', '0'): 'fire', ('sin', '6'): 'left',
           ('sin', '7'): 'right', ('sin', '9'): 'up', ('sin', '8'): 'down', ('menu', '1'): 'keyboard',
           ('menu', '2'): 'Kempston', ('menu', '3'): 'cursor', ('menu', '4'): 'Sinclair', ('start', 'ENTER'): 'start',
           ('quit', 'Q'): 'quit', ('pause', 'P'): 'pause'}
ROWS = [['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
        ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
        ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENTER'],
        ['CAPS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SYM', 'SPACE']]
HALF = {}
for keys, left, right in ((ROWS[0][:5], 0xF7, None), (ROWS[0][5:], 0xEF, 'rev'), (ROWS[1][:5], 0xFB, None),
                          (ROWS[1][5:], 0xDF, 'rev'), (ROWS[2][:5], 0xFD, None), (ROWS[2][5:], 0xBF, 'rev'),
                          (ROWS[3][:5], 0xFE, None), (ROWS[3][5:], 0x7F, 'rev')):
    for i, k in enumerate(keys):
        HALF[k] = (left, 4 - i if right else i)
BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM


def check_listing():
    """every READS address holds BIT n,A with the bit drawn, after a LD BC,$ppFE or IN of the port drawn"""
    lst = open(os.path.join(CASE, 'build', 'game.lst')).read().splitlines()
    code = {}
    for line in lst:
        m = re.match(r'\s*\d+\+?\s+([0-9A-F]{4}) ((?:[0-9A-F]{2} )+)\s*(.*)$', line)
        if m:
            code[int(m.group(1), 16)] = m.group(3).split(';')[0].strip()
    addrs = sorted(code)
    for key, port, bit, use, at in READS:
        text = code.get(at, '')
        if text != f'BIT {bit},A':
            raise SystemExit(f'{key} {use}: ${at:04X} is "{text}", not BIT {bit},A')
        i = addrs.index(at)
        back = [code[a] for a in addrs[max(0, i - 24):i]]
        if not any(f'LD BC,${port:02X}FE' in b for b in back):
            raise SystemExit(f'{key} {use}: no LD BC,${port:02X}FE before ${at:04X}')
        if HALF[key] != (port, bit):
            raise SystemExit(f'{key}: the keyboard says ${HALF[key][0]:02X}FE bit {HALF[key][1]}')


def keyboard(out):
    check_listing()
    f, fs, fb = K.font(15), K.font(12), K.font(18)
    kw, kh, gap, x0, y0 = 92, 112, 6, 14, 60
    img = Image.new('RGB', (1050, y0 + 4 * (kh + gap) + 140), BG)
    d = ImageDraw.Draw(img)
    d.text((x0, 14), 'Rick Dangerous: every key the game reads, with its port, bit and uses', fill=TEXT, font=fb)
    uses = {}
    for key, port, bit, use, at in READS:
        uses.setdefault(key, []).append((use, at))
    for r, row in enumerate(ROWS):
        for c, key in enumerate(row):
            x, y = x0 + c * (kw + gap) + r * 10, y0 + r * (kh + gap)
            read = key in uses
            d.rounded_rectangle((x, y, x + kw, y + kh), 6, fill=(60, 60, 72) if read else (34, 34, 42),
                                outline=(150, 150, 165) if read else (60, 60, 70))
            d.text((x + 6, y + 4), key, fill=TEXT if read else DIM, font=fb)
            if key in HALF:
                p, b = HALF[key]
                d.text((x + 6, y + 27), f'${p:02X}FE b{b}', fill=DIM, font=fs)
            for i, (use, at) in enumerate(uses.get(key, [])):
                name, col = USES[use]
                ty = y + 45 + i * 17
                d.rectangle((x + 4, ty, x + kw - 4, ty + 15), fill=col)
                d.text((x + 7, ty), MEANING[(use, key)], fill=(0, 0, 0), font=fs)
    ly = y0 + 4 * (kh + gap) + 10
    lx = x0
    for use in ('kbd', 'cur', 'sin', 'menu', 'start', 'quit', 'pause'):
        name, col = USES[use]
        w = d.textlength(name, font=f) + 34
        if lx + w > 1040:
            lx, ly = x0, ly + 24
        d.rectangle((lx, ly + 2, lx + 18, ly + 18), fill=col)
        d.text((lx + 24, ly), name, fill=TEXT, font=f)
        lx += w + 12
    d.text((x0, ly + 30), 'Grey keys: read by no code. Kempston (method 1): no port is read at all (5.6).',
           fill=DIM, font=fs)
    d.text((x0, ly + 48), 'Port $FEFE bit 7, which no key drives, is also tested by the start test (5.7).',
           fill=DIM, font=fs)
    d.text((x0, ly + 66), 'Drawn from the BIT instructions of build/game.lst: tools/fig_controls.py keyboard',
           fill=DIM, font=fs)
    img.save(out)
    print(out)


def bits(out):
    check_listing()
    f, fs, fb = K.font(15), K.font(13), K.font(18)
    cols = ['bit 4: fire', 'bit 3: up', 'bit 2: down', 'bit 1: left', 'bit 0: right']
    rows = [
        ('0 keyboard', 'kbd', {4: 'ENTER  $BFFE b0', 3: 'O  $DFFE b1', 2: 'K  $BFFE b2  (not with O)',
                               1: 'Z  $FEFE b1', 0: 'X  $FEFE b2  (not with Z)'}),
        ('1 Kempston', None, {4: '-', 3: '-', 2: '-', 1: '-', 0: 'always 0  no port read:  right, for ever'}),
        ('2 cursor', 'cur', {4: '0  $EFFE b0', 3: '7  $EFFE b3', 2: '6  $EFFE b4  (not with 7)',
                             1: '5  $F7FE b4  (not with 8)', 0: '8  $EFFE b2'}),
        ('3 Sinclair', 'sin', {4: '0  $EFFE b0', 3: '9  $EFFE b1', 2: '8  $EFFE b2  (not with 9)',
                               1: '6  $EFFE b4', 0: '7  $EFFE b3  (not with 6)'}),
    ]
    lw, cw, rh, x0, y0 = 150, 176, 58, 14, 70
    img = Image.new('RGB', (1050, y0 + rh * 5 + 90), BG)
    d = ImageDraw.Draw(img)
    d.text((x0, 14), 'InputBits $A14D: which key sets which bit to 0, per control method', fill=TEXT, font=fb)
    d.text((x0, 40), 'ReadInput $A14E starts from $FF and clears one bit for each key it finds held (active low).',
           fill=DIM, font=fs)
    for c, name in enumerate(cols):
        d.text((x0 + lw + c * cw + 6, y0 + 18), name, fill=TEXT, font=f)
    for r, (name, use, cells) in enumerate(rows):
        y = y0 + rh * (r + 1)
        col = USES[use][1] if use else (230, 90, 80)
        d.rectangle((x0, y, x0 + lw - 6, y + rh - 6), fill=col)
        d.text((x0 + 8, y + 18), name, fill=(0, 0, 0), font=f)
        for c in range(5):
            text = cells[4 - c]
            x = x0 + lw + c * cw
            d.rectangle((x, y, x + cw - 6, y + rh - 6), fill=PANEL, outline=(70, 70, 82))
            parts = text.split('  ')
            d.text((x + 8, y + 6), parts[0], fill=TEXT if text != '-' else DIM, font=f)
            if len(parts) > 1:
                d.text((x + 8, y + 24), parts[1], fill=DIM, font=fs)
            if len(parts) > 2:
                d.text((x + 8, y + 39), parts[2], fill=(240, 160, 120), font=fs)
    y = y0 + rh * 5 + 8
    d.text((x0, y), '"not with": the reader tests the second key only when the first is up, so up beats down and '
           'left beats right (keyboard),', fill=DIM, font=fs)
    d.text((x0, y + 18), 'up beats down and left beats right (Sinclair), up beats down and right beats left '
           '(cursor). Kempston: InputKempston $A19F', fill=DIM, font=fs)
    d.text((x0, y + 36), 'stores CPL (1 AND $1F) = $FE without an IN. Drawn from build/game.lst: '
           'tools/fig_controls.py bits', fill=DIM, font=fs)
    img.save(out)
    print(out)


# ---------------------------------------------------------------------------------------------------------------
# recordings

def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    return re_session.session_of(work)[0]


def mem(s, frame, off, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                               'offset': off, 'length': n}, ok=False)
    body = r.structured or {}
    if r.is_error or not body.get('exact', False):
        raise SystemExit(f'memory_at {frame}: {r.text}')
    return bytes.fromhex(body['hex'])


def held_keys(path):
    """frame -> the keys the script holds"""
    events = []
    for line in open(path):
        line = line.split('#')[0].strip()
        if not line:
            continue
        parts = line.split()
        if parts[1] == 'END':
            events.append((int(parts[0]), None))
            break
        events.append((int(parts[0]), [] if parts[1] == '-' else parts[1:]))

    def at(frame):
        now = []
        for fr, keys in events:
            if fr > frame or keys is None:
                break
            now = keys
        return now
    return at


KEYNAME = {'KL': 'stick left', 'KR': 'stick right', 'KU': 'stick up', 'KD': 'stick down', 'KF': 'stick fire'}


def state(s, frame):
    m = mem(s, frame, 0xA14C, 2)
    r = mem(s, frame, 0xEAAC, 8)
    v = mem(s, frame, 0xFD54, 0x19)
    c = mem(s, frame, 0xA958, 1) + mem(s, frame, 0xA967, 1) + mem(s, frame, 0xA976, 1)
    vel = v[2] | v[3] << 8
    vel = vel - 0x10000 if vel & 0x8000 else vel
    return {'method': m[0], 'bits': m[1], 'x': r[1], 'y': r[2] | r[3] << 8, 'frame': r[4] | r[5] << 8,
            'mirror': r[6], 'vel': vel, 'facing': v[4], 'climb': v[5], 'crawl': v[6], 'air': v[7], 'poke': v[0x0F],
            'fire': v[0x13], 'dying': v[0x14], 'lives': c[0], 'a967': c[1], 'a976': c[2]}


def lamp_row(d, x, y, value, f):
    for i, (name, bit) in enumerate((('fire', 4), ('up', 3), ('down', 2), ('left', 1), ('right', 0))):
        on = not (value >> bit) & 1
        d.rounded_rectangle((x + i * 62, y, x + i * 62 + 56, y + 26), 5, fill=(80, 230, 110) if on else (40, 40, 50),
                            outline=(110, 110, 120))
        d.text((x + i * 62 + 6, y + 4), name, fill=(0, 0, 0) if on else DIM, font=f)


def rick_picture(s, frame, keys, title, scale=2):
    import zxscreen
    scr = mem(s, frame, 0x4000, 0x1B00)
    st = state(s, frame)
    screen = zxscreen.render(scr, scale).convert('RGB')
    img = Image.new('RGB', (1050, 192 * scale + 70), BG)
    img.paste(screen, (8, 54))
    d = ImageDraw.Draw(img)
    f, fs, fb = K.font(15), K.font(13), K.font(17)
    d.text((8, 8), title, fill=TEXT, font=fb)
    sy = st['y'] - 64
    if not st['dying'] and -21 < sy < 192:
        d.rectangle((8 + st['x'] * scale - 1, 54 + sy * scale - 1, 8 + (st['x'] + 24) * scale,
                     54 + (sy + 21) * scale), outline=(255, 80, 200), width=2)
    x = 256 * scale + 24
    d.text((x, 56), f'frame {frame}', fill=TEXT, font=fb)
    d.text((x, 84), 'keys held: ' + (' + '.join(KEYNAME.get(k, k) for k in keys) or 'none'), fill=(250, 220, 120),
           font=f)
    d.text((x, 114), f'InputBits $A14D = ${st["bits"]:02X}  (0 = held)', fill=TEXT, font=f)
    lamp_row(d, x, 136, st['bits'], fs)
    method = ('keyboard', 'Kempston', 'cursor', 'Sinclair')[st['method'] & 3]
    lines = [
        (f'ControlMethod $A14C = {st["method"]} ({method})', TEXT),
        (f'Rick x {st["x"]:3d}   y {st["y"]:3d} (screen y {st["y"] - 64})', TEXT),
        (f'Y velocity $FD56 = {st["vel"]:+5d} ({st["vel"] / 256:+.2f} px a pass)', TEXT),
        ('on a floor' if not st['air'] else 'in the air (Airborne $FD5B)', TEXT),
    ]
    flags = [n for n, k in (('climbing', 'climb'), ('crawling', 'crawl'), ('poking the stick', 'poke'),
                            ('dying', 'dying')) if st[k]]
    lines.append(('state: ' + (', '.join(flags) or 'walking / standing'), (120, 220, 255)))
    lines.append((f'facing {"left (mirrored)" if st["facing"] else "right"}', TEXT))
    lines.append((f'lives {st["lives"]}  $A976 bullets {st["a976"]}  $A967 sticks {st["a967"]}', DIM))
    for i, (t, col) in enumerate(lines):
        d.text((x, 176 + i * 24), t, fill=col, font=f)
    d.text((x, 176 + len(lines) * 24 + 6), 'pink box: Rick (24 x 21 at x, y - 64)', fill=(255, 80, 200), font=fs)
    return img


def anim(args, kind):
    s = session(args.work)
    at = held_keys(args.inputs)
    pics = []
    for frame in range(args.start, args.end + 1, args.step):
        pics.append(rick_picture(s, frame, at(frame), args.title))
    K.save_gif(args.out, pics, [args.delay] * (len(pics) - 1) + [args.hold])
    print(f'{args.out}: {len(pics)} pictures')


def menu_anim(args):
    import zxscreen
    s = session(args.work)
    at = held_keys(args.inputs)
    pics = []
    f, fb = K.font(15), K.font(17)
    for frame in range(args.start, args.end + 1, args.step):
        scr = mem(s, frame, 0x4000, 0x1B00)
        m = mem(s, frame, 0xA14C, 1)[0]
        ph = mem(s, frame, 0xAB3C, 1)[0]
        img = Image.new('RGB', (1050, 500), BG)
        crop = zxscreen.render(scr, 1).convert('RGB').crop((0, 0, 256, 192)).resize((512, 384),
                                                                                      Image.NEAREST)
        img.paste(crop, (8, 54))
        d = ImageDraw.Draw(img)
        d.text((8, 8), args.title, fill=TEXT, font=fb)
        x = 512 + 30
        keys = at(frame)
        d.text((x, 60), f'frame {frame}', fill=TEXT, font=fb)
        d.text((x, 92), 'keys held: ' + (' + '.join(keys) or 'none'), fill=(250, 220, 120), font=f)
        d.text((x, 122), f'ControlMethod $A14C = {m}', fill=TEXT, font=f)
        d.text((x, 146), '  ' + ('keyboard', 'Kempston', 'cursor', 'Sinclair')[m & 3], fill=(120, 220, 255), font=f)
        d.text((x, 176), f'CyclePhase $AB3C = {ph}', fill=TEXT, font=f)
        d.text((x, 200), '  +1 each call, every 2 frames', fill=DIM, font=f)
        d.text((x, 236), 'The lit row: CycleColours $AB3D', fill=TEXT, font=f)
        for i, a in enumerate((0x4F, 0x4F, 0x57, 0x57, 0x5F, 0x5F, 0x67, 0x67)):
            paper = K.ink_colour((a >> 3) & 7, 1)
            d.rectangle((x + i * 44, 262, x + i * 44 + 40, 290), fill=paper, outline=(255, 255, 255))
            d.text((x + i * 44 + 5, 268), f'{a:02X}', fill=(255, 255, 255), font=f)
        d.text((x, 300), 'cell k gets entry (phase + k) mod 8', fill=DIM, font=f)
        d.text((x, 330), 'The old row: PlainColours $AB45 ($47)', fill=TEXT, font=f)
        d.text((8, 54 + 384 + 8), 'the whole screen at 2 x, sampled at each frame\'s start',
               fill=DIM, font=K.font(13))
        pics.append(img)
    K.save_gif(args.out, pics, [args.delay] * (len(pics) - 1) + [args.hold])
    print(f'{args.out}: {len(pics)} pictures')


def timeline(args):
    s = session(args.work)
    at = held_keys(args.inputs)
    frames = list(range(args.start, args.end + 1))
    sts = [state(s, fr) for fr in frames]
    f, fs, fb = K.font(14), K.font(12), K.font(17)
    lanes_keys = args.keys.split(',')
    lanes_bits = [('fire', 4), ('up', 3), ('down', 2), ('left', 1), ('right', 0)]
    x0, x1 = 130, 1035
    lh = 20
    h = 60 + (len(lanes_keys) + len(lanes_bits)) * lh + 30 + 150 + 110 + 60
    img = Image.new('RGB', (1050, h), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 10), args.title, fill=TEXT, font=fb)
    span = frames[-1] - frames[0] + 1

    def fx(fr):
        return x0 + (fr - frames[0]) * (x1 - x0) / span
    y = 44
    d.text((10, y), 'keys held', fill=(250, 220, 120), font=f)
    y += 20
    for k in lanes_keys:
        d.text((14, y + 2), KEYNAME.get(k, k), fill=TEXT, font=fs)
        for fr in frames:
            if k in at(fr):
                d.rectangle((fx(fr), y + 3, fx(fr + 1), y + lh - 3), fill=(250, 220, 120))
        y += lh
    y += 6
    d.text((10, y), 'InputBits', fill=(80, 230, 110), font=f)
    y += 20
    for name, bit in lanes_bits:
        d.text((14, y + 2), f'b{bit} {name}', fill=TEXT, font=fs)
        for fr, st in zip(frames, sts):
            if not (st['bits'] >> bit) & 1:
                d.rectangle((fx(fr), y + 3, fx(fr + 1), y + lh - 3), fill=(80, 230, 110))
        y += lh
    y += 10
    # x and y plots
    ph = 140
    d.text((10, y), 'Rick x', fill=(90, 150, 250), font=f)
    d.text((10, y + 18), '(0 at the', fill=DIM, font=fs)
    d.text((10, y + 32), 'bottom)', fill=DIM, font=fs)
    d.text((10, y + 58), 'Rick y', fill=(240, 120, 180), font=f)
    d.text((10, y + 76), '(0 at the top,', fill=DIM, font=fs)
    d.text((10, y + 90), 'as on screen)', fill=DIM, font=fs)
    d.rectangle((x0, y, x1, y + ph), outline=(60, 60, 70))
    pts = [(fx(fr) + 1, y + ph - st['x'] * ph / 256) for fr, st in zip(frames, sts)]
    d.line(pts, fill=(90, 150, 250), width=2)
    pts = [(fx(fr) + 1, y + st['y'] * ph / 256) for fr, st in zip(frames, sts)]
    d.line(pts, fill=(240, 120, 180), width=2)
    for mark in [m for m in args.marks.split(',') if m]:
        fr, _, text = mark.partition(':')
        mx = fx(int(fr))
        d.line((mx, y, mx, y + ph), fill=(255, 255, 255))
        d.text((mx + 3, y + 2 + 15 * (args.marks.split(',').index(mark) % 3)), text, fill=(255, 255, 255), font=fs)
    y += ph + 10
    d.text((10, y), 'state', fill=(120, 220, 255), font=f)
    y += 20
    for name, key, col in (('airborne', 'air', (200, 170, 120)), ('poking', 'poke', (250, 150, 60)),
                           ('dying', 'dying', (230, 90, 80)), ('climbing', 'climb', (70, 210, 220)),
                           ('crawling', 'crawl', (160, 220, 80))):
        if not any(st[key] for st in sts):
            continue
        d.text((14, y + 2), name, fill=TEXT, font=fs)
        for fr, st in zip(frames, sts):
            if st[key]:
                d.rectangle((fx(fr), y + 3, fx(fr + 1), y + lh - 3), fill=col)
        y += lh
    y += 4
    for fr in range(frames[0] - frames[0] % 10, frames[-1] + 1, 10):
        if fr >= frames[0]:
            d.line((fx(fr), 60, fx(fr), y), fill=(40, 40, 50) if fr % 50 else (75, 75, 90))
            if fr % 50 == 0:
                d.text((fx(fr) - 14, y + 2), str(fr), fill=DIM, font=fs)
    words, line, ly = args.note.split(' '), '', y + 22
    for w in words:
        if d.textlength(line + ' ' + w, font=fs) > 1030:
            d.text((10, ly), line.strip(), fill=DIM, font=fs)
            line, ly = '', ly + 16
        line += ' ' + w
    d.text((10, ly), line.strip(), fill=DIM, font=fs)
    img = img.crop((0, 0, 1050, ly + 24))
    img.save(args.out)
    print(args.out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('what', choices=['keyboard', 'bits', 'menu', 'rick', 'timeline'])
    p.add_argument('--out', required=True)
    p.add_argument('--work')
    p.add_argument('--inputs')
    p.add_argument('--from', dest='start', type=int)
    p.add_argument('--to', dest='end', type=int)
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--delay', type=int, default=100)
    p.add_argument('--hold', type=int, default=1500)
    p.add_argument('--title', default='')
    p.add_argument('--keys', default='X,O,Z,ENTER,K')
    p.add_argument('--note', default='')
    p.add_argument('--marks', default='', help='FRAME:text,... vertical marks on the plot')
    a = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    if a.what == 'keyboard':
        keyboard(a.out)
    elif a.what == 'bits':
        bits(a.out)
    elif a.what == 'menu':
        menu_anim(a)
    elif a.what == 'rick':
        anim(a, 'rick')
    else:
        timeline(a)


if __name__ == '__main__':
    main()
