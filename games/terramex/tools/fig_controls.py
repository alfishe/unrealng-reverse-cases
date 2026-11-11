#!/usr/bin/env python3
"""The figures of doc 05 (controls), drawn from the code's port reads and from recordings read with TTD memory_at.

    python3 tools/fig_controls.py keyboard --out docs/img/controls/keyboard.png
    python3 tools/fig_controls.py bits --out docs/img/controls/inputbits.png
    python3 tools/fig_controls.py menu --work W --inputs tests/inputs/explorers.txt --from 5128 --to 5240 \
        --out docs/img/play/device-menu-keys.gif
    python3 tools/fig_controls.py play --work W --inputs tests/inputs/explorers.txt --from 5950 --to 6130 \
        --out docs/img/play/walk-keyboard.gif
    python3 tools/fig_controls.py chart --work W --inputs SCRIPT --from A --to B --out PNG
    python3 tools/fig_controls.py selector --out docs/img/controls/selector-regions.png

W is a work folder whose instance holds the recording (`kit/rs.py open`, session.json). A memory sample of frame N is
the memory at the start of frame N (TTD memory_at, tinframe 0): it shows what the passes that ended before frame N
did. The keys of an input script are the keys held from their frame on (relative `+N` or absolute frames).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 1050
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (105, 105, 115), (205, 205, 210)

# the eight half rows: port high byte and the keys from bit 0 to bit 4
ROWS = {0xF7: ['1', '2', '3', '4', '5'], 0xEF: ['0', '9', '8', '7', '6'], 0xFB: ['Q', 'W', 'E', 'R', 'T'],
        0xDF: ['P', 'O', 'I', 'U', 'Y'], 0xFD: ['A', 'S', 'D', 'F', 'G'], 0xBF: ['ENTER', 'L', 'K', 'J', 'H'],
        0xFE: ['CS', 'Z', 'X', 'C', 'V'], 0x7F: ['SPACE', 'SS', 'M', 'N', 'B']}
LAYOUT = [['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'], ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
          ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENTER'],
          ['CS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SS', 'SPACE']]
NAMES = {'CS': 'CAPS SH.', 'SS': 'SYM SH.'}

COL = {'kbd': (46, 140, 60), 'sin': (40, 100, 200), 'menu': (170, 50, 170), 'panel': (225, 120, 20),
       'quit': (200, 40, 40), 'sel': (20, 150, 150), 'cur': (150, 150, 160)}
LEGEND = [('kbd', 'device 1 on the menu: the keyboard (ReadKeyboard $B8FE; the selector $C471 too)'),
          ('sin', 'device 3: Sinclair, keys 6-0 (port $EFFE, $B8A6; the selector $C416)'),
          ('menu', 'the device menu: 1 2 3 choose, 0 starts (MenuKeys $9468)'),
          ('panel', 'in play, any device: 1 2 scroll the bearers ($BC24), S swaps ($BA40), T thinks ($B031)'),
          ('quit', 'end of a pass: Q, then CAPS SHIFT quits ($905C) or A freezes while held ($9064)'),
          ('sel', 'Help pages: SPACE next, ENTER back ($C5E4); 48K screens: SPACE ($C2B1)'),
          ('cur', 'the cursor-key readers $B8D4 / $C444: 5 6 7 8 0, reached by no path')]

# every key the code reads: key -> [(group, text)]
USES = [('SPACE', 'kbd', 'fire/jump'), ('Z', 'kbd', 'left'), ('X', 'kbd', 'right'), ('O', 'kbd', 'up'),
        ('K', 'kbd', 'down'),
        ('0', 'sin', 'fire'), ('6', 'sin', 'left'), ('7', 'sin', 'right'), ('9', 'sin', 'up'), ('8', 'sin', 'down'),
        ('1', 'menu', 'keyboard'), ('2', 'menu', 'Kempston'), ('3', 'menu', 'Sinclair'), ('0', 'menu', 'start'),
        ('1', 'panel', 'bearer -1'), ('2', 'panel', 'bearer +1'), ('S', 'panel', 'swap'), ('T', 'panel', 'think'),
        ('Q', 'quit', 'Q + ...'), ('CS', 'quit', 'quit'), ('A', 'quit', 'freeze'),
        ('SPACE', 'sel', 'Help: next'), ('ENTER', 'sel', 'Help: back'),
        ('5', 'cur', 'left'), ('6', 'cur', 'down'), ('7', 'cur', 'up'), ('8', 'cur', 'right'), ('0', 'cur', 'fire')]

STATUS = {0: 'walk / stand', 1: 'forced jump', 2: 'jump', 3: 'hop out (room $18)', 4: 'hover (item $0A)',
          5: 'bounce up', 6: 'stay, animate', 10: 'think', 17: 'sink', 18: 'dying', 19: 'lift up', 20: 'lift down',
          22: 'teleport', 24: 'creature death', 26: 'fall death'}


def port_of(key):
    for row, keys in ROWS.items():
        if key in keys:
            return row, keys.index(key)
    raise KeyError(key)


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    return re_session.session_of(work)[0]


def mem(s, frame, addr, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                               'offset': addr, 'length': n}, ok=False)
    st = r.structured or {}
    if 'hex' not in st:
        raise SystemExit(f'memory_at {frame}: {r.text[:200]}')
    return bytes.fromhex(st['hex'])


def script_keys(path):
    """[(frame, [keys])] of an input script: each line's keys are held from its frame to the next line"""
    out, t = [], 0
    for raw in open(path):
        line = raw.split('#', 1)[0].strip()
        if not line:
            continue
        f, *k = line.split()
        t = t + int(f[1:]) if f.startswith('+') else int(f)
        if k == ['END']:
            break
        out.append((t, [] if k == ['-'] else k))
    return out


def held(events, frame):
    keys = []
    for f, k in events:
        if f <= frame:
            keys = k
    return keys


def key_label(k):
    return {'KR': 'Kempston right', 'KL': 'Kempston left', 'KU': 'Kempston up', 'KD': 'Kempston down',
            'KF': 'Kempston fire', 'CS': 'CAPS SHIFT'}.get(k, k)


# ---------------------------------------------------------------------------------------------------------------------

def fig_keyboard(out):
    uses = {}
    for key, g, t in USES:
        uses.setdefault(key, []).append((g, t))
    kw, kh, gap = 99, 118, 5
    h = 60 + 4 * (kh + gap) + 30 + 22 * len(LEGEND) + 20
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(12), K.font(16)
    d.text((14, 10), 'Every key Terramex reads: its half row and bit, and what it does (keyboard, Sinclair, menus, '
                     'panel keys)', font=ft, fill=FG)
    d.text((14, 32), 'A key reads 0 in its bit while it is down. Grey keys are read by no code of the game, the '
                     'selector or Help.', font=fs, fill=DIM)
    y0 = 58
    for r, row in enumerate(LAYOUT):
        x0 = 14 + r * 12
        for c, key in enumerate(row):
            x, y = x0 + c * (kw - 1), y0 + r * (kh + gap)
            u = uses.get(key, [])
            fill = (255, 255, 255) if u else (228, 228, 230)
            d.rounded_rectangle((x, y, x + kw - 6, y + kh), 6, fill=fill, outline=(150, 150, 155))
            d.text((x + 6, y + 4), NAMES.get(key, key), font=K.font(15 if len(key) < 3 else 12), fill=FG)
            row_b, bit = port_of(key)
            d.text((x + 6, y + 24), f'${row_b:02X}FE b{bit}', font=fs, fill=DIM)
            for i, (g, t) in enumerate(u):
                yy = y + 42 + i * 18
                d.rectangle((x + 4, yy, x + kw - 10, yy + 16), fill=COL[g])
                d.text((x + 7, yy + 1), t, font=K.font(11), fill=(255, 255, 255))
    y = y0 + 4 * (kh + gap) + 14
    for g, t in LEGEND:
        d.rectangle((14, y + 2, 30, y + 16), fill=COL[g])
        d.text((38, y + 1), t, font=f, fill=FG)
        y += 22
    im.save(out)


def fig_bits(out):
    rows = [('keyboard (0)', 'ReadKeyboard $B8FE', ['SPACE $7FFE b0', 'O $DFFE b1', 'K $BFFE b2', 'Z $FEFE b1',
                                                    'X $FEFE b2'], COL['kbd']),
            ('Kempston (1)', 'ReadKempston $B8CC', ['port $1F b4', 'b3', 'b2', 'b1', 'b0'], (110, 110, 120)),
            ('Sinclair (2)', 'the code at $B8A3', ['0 $EFFE b0', '9 $EFFE b1', '8 $EFFE b2', '6 $EFFE b4',
                                                   '7 $EFFE b3'], COL['sin']),
            ('cursor (none)', 'ReadCursorKeys $B8D4', ['0 $EFFE b0', '7 $EFFE b3', '6 $EFFE b4', '5 $F7FE b4',
                                                       '8 $EFFE b2'], COL['cur'])]
    heads = ['bit 4 FIRE', 'bit 3 UP', 'bit 2 DOWN', 'bit 1 LEFT', 'bit 0 RIGHT']
    cw, x0, rh = 150, 290, 46
    h = 70 + rh * (len(rows) + 1) + 120
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(16), K.font(13), K.font(12)
    d.text((14, 10), 'InputBits $B87C: one byte, the Kempston layout, whatever the device', font=ft, fill=FG)
    d.text((14, 32), 'ReadDevice $B894 clears it and sets a bit for each control down; the device is InputDevice '
                     '$94AF (the menu: 1, 2, 3 store 0, 1, 2)', font=fs, fill=DIM)
    y = 62
    d.text((14, y + 14), 'device (InputDevice)', font=f, fill=DIM)
    for i, t in enumerate(heads):
        d.rectangle((x0 + i * cw, y, x0 + (i + 1) * cw - 4, y + rh - 6), fill=(60, 60, 70))
        d.text((x0 + i * cw + 10, y + 12), t, font=f, fill=(255, 255, 255))
    for r, (name, rout, cells, col) in enumerate(rows):
        y = 62 + (r + 1) * rh
        d.text((14, y + 4), name, font=f, fill=col)
        d.text((14, y + 22), rout, font=fs, fill=DIM)
        for i, t in enumerate(cells):
            d.rectangle((x0 + i * cw, y, x0 + (i + 1) * cw - 4, y + rh - 6), outline=col, width=2,
                        fill=(255, 255, 255))
            d.text((x0 + i * cw + 10, y + 12), t, font=f, fill=FG)
    y = 62 + (len(rows) + 1) * rh + 12
    notes = ['ReadControls $B87D then drops a reading with both bit 0 and bit 1 (left + right), or bit 2 and bit 3 '
             '(up + down): it gives 0.',
             'Kempston: IN A,($1F) AND $1F is stored as it is; the interface already answers in this order '
             '(1 = pressed).',
             'Keyboard and Sinclair: a key reads 0 while down; each reader tests one bit and SETs the InputBits bit.',
             'Cursor: no device number leads to $B8D4 (ReadDevice sends 2 and above to Sinclair); known only from '
             'the code.']
    for t in notes:
        d.text((14, y), t, font=f, fill=FG)
        y += 22
    im.save(out)


# ---------------------------------------------------------------------------------------------------------------------

def screen_image(s, frame):
    return K.render_screen(mem(s, frame, 0x4000, 0x1B00), 0)


def bits_boxes(d, x, y, bits, f):
    for i, name in enumerate(['F', 'U', 'D', 'L', 'R']):
        on = bits >> (4 - i) & 1
        d.rectangle((x + i * 50, y, x + i * 50 + 44, y + 30), fill=(230, 160, 40) if on else (60, 60, 70))
        d.text((x + i * 50 + 16, y + 6), name, font=f, fill=(255, 255, 255))


def fig_menu(work, script, a, b, step, out):
    s = session(work)
    ev = script_keys(script)
    pics, f, fs, fb = [], K.font(14), K.font(13), K.font(17)
    for fr in range(a, b + 1, step):
        scr = screen_image(s, fr).crop((0, 48, 256, 136)).resize((768, 264), Image.NEAREST)
        dev = mem(s, fr, 0x94AF, 1)[0]
        im = Image.new('RGB', (W, 330), K.BACKGROUND)
        im.paste(scr, (0, 50))
        d = ImageDraw.Draw(im)
        d.text((10, 8), 'The device menu: a lone 1, 2 or 3 moves the white bar (InputDevice $94AF), 0 starts',
               font=fb, fill=K.TEXT)
        d.text((10, 30), 'explorers, screen rows 6-16 at 3 x; memory sampled at the start of each frame',
               font=fs, fill=K.DIM)
        x = 784
        d.text((x, 60), f'frame {fr}', font=fb, fill=K.TEXT)
        keys = held(ev, fr)
        d.text((x, 92), 'keys held (script):', font=fs, fill=K.DIM)
        d.text((x, 110), ' '.join(key_label(k) for k in keys) or 'none', font=f, fill=(255, 210, 70))
        d.text((x, 146), 'InputDevice $94AF:', font=fs, fill=K.DIM)
        d.text((x, 164), f'{dev} = {["keyboard", "Kempston", "Sinclair"][dev] if dev < 3 else "?"}', font=f,
               fill=K.TEXT)
        d.text((x, 200), 'bar row = 8 + 2 x device', font=fs, fill=K.DIM)
        pics.append(im)
    K.save_gif(out, pics, [120] * (len(pics) - 1) + [2000])


def fig_play(work, script, a, b, step, out, title):
    s = session(work)
    ev = script_keys(script)
    pics, f, fs, fb = [], K.font(14), K.font(13), K.font(17)
    trail = []
    for fr in range(a, b + 1, step):
        scr = screen_image(s, fr).crop((0, 0, 256, 128)).resize((768, 384), Image.NEAREST)
        hero = mem(s, fr, 0x5B04, 4)
        st = mem(s, fr, 0x5C06, 1)[0]
        bits = mem(s, fr, 0xB87C, 1)[0]
        room = mem(s, fr, 0x5C01, 1)[0]
        fall = mem(s, fr, 0x5C04, 2)
        im = Image.new('RGB', (W, 448), K.BACKGROUND)
        im.paste(scr, (0, 56))
        d = ImageDraw.Draw(im)
        d.text((10, 6), title, font=fb, fill=K.TEXT)
        d.text((10, 30), 'the play window at 3 x; the box = the hero sprite at (X, Y), 24 x 24; the dots = the last '
                         '30 samples of (X, Y)', font=fs, fill=K.DIM)
        hx, hy = hero[0], hero[1] & 0x7F
        trail = (trail + [(hx, hy)])[-30:]
        for px, py in trail:
            cx, cy = (px + 12) * 3, 56 + (py + 12) * 3
            d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(255, 80, 200))
        d.rectangle((hx * 3, 56 + hy * 3, hx * 3 + 72, 56 + hy * 3 + 72), outline=(255, 80, 200), width=2)
        x = 784
        d.text((x, 58), f'frame {fr}   room ${room:02X}', font=fb, fill=K.TEXT)
        keys = held(ev, fr)
        d.text((x, 88), 'keys held (script):', font=fs, fill=K.DIM)
        d.text((x, 106), ', '.join(key_label(k) for k in keys) or 'none', font=f, fill=(255, 210, 70))
        d.text((x, 138), 'InputBits $B87C (last read):', font=fs, fill=K.DIM)
        bits_boxes(d, x, 158, bits, f)
        d.text((x, 202), f'X ${hx:02X}  Y ${hero[1]:02X}', font=fb, fill=K.TEXT)
        d.text((x, 228), f'frame ${hero[2]:02X}  facing {"right" if hero[3] & 0x80 else "left"}', font=f,
               fill=K.TEXT)
        d.text((x, 258), f'Status $5C06 = {st}', font=f, fill=K.TEXT)
        d.text((x, 278), STATUS.get(st, '') + (', climbing' if 0x20 <= hero[2] <= 0x23 else ''), font=f,
               fill=(120, 220, 140))
        d.text((x, 308), f'Falling {fall[0]}  FallPasses {fall[1]}', font=f, fill=K.TEXT)
        pics.append(im)
    K.save_gif(out, pics, [100] * (len(pics) - 1) + [2000])


def fig_chart(work, script, a, b, step, out, title):
    """the input path over frames: InputBits, the hero's X, Y and frame, the status"""
    s = session(work)
    ev = script_keys(script)
    rows = []
    for fr in range(a, b + 1, step):
        rows.append((fr, mem(s, fr, 0xB87C, 1)[0], mem(s, fr, 0x5B04, 4), mem(s, fr, 0x5C06, 1)[0]))
    rooms = [(fr, mem(s, fr, 0x5C01, 1)[0]) for fr in range(a, b + 1, step)]
    h = 640
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(16), K.font(13), K.font(12)
    d.text((14, 8), title, font=ft, fill=FG)
    x0, x1 = 120, W - 20

    def xf(fr):
        return x0 + (fr - a) * (x1 - x0) / max(1, b - a)
    # keys held
    y = 44
    d.text((14, y + 4), 'keys held', font=f, fill=FG)
    for i, (fa, k) in enumerate(ev):
        fb = ev[i + 1][0] if i + 1 < len(ev) else b
        if k and fb > a and fa < b:
            d.rectangle((xf(max(fa, a)), y, xf(min(fb, b)), y + 20), fill=(255, 225, 150), outline=(200, 150, 60))
            d.text((xf(max(fa, a)) + 3, y + 3), ' '.join(k), font=fs, fill=FG)
    # InputBits lanes
    names = ['FIRE b4', 'UP b3', 'DOWN b2', 'LEFT b1', 'RIGHT b0']
    for i, nm in enumerate(names):
        yy = 80 + i * 24
        d.text((14, yy + 3), nm, font=fs, fill=FG)
        d.line((x0, yy + 18, x1, yy + 18), fill=GRID)
        for j, (fr, bits, hero, st) in enumerate(rows):
            if bits >> (4 - i) & 1:
                fr2 = rows[j + 1][0] if j + 1 < len(rows) else fr + step
                d.rectangle((xf(fr), yy + 2, xf(fr2), yy + 16), fill=(230, 140, 30))
    d.text((14, 202), 'InputBits $B87C sampled at each frame start', font=fs, fill=DIM)
    # X and Y
    for k, (lab, idx, col, lo, hi, top) in enumerate([('X', 0, (40, 100, 200), 0, 0xE8, 230),
                                                     ('Y', 1, (200, 40, 40), 0, 0x80, 380)]):
        d.text((14, top), f'hero {lab}', font=f, fill=col)
        d.text((14, top + 18), 'down = lower' if idx else '', font=fs, fill=DIM)
        d.rectangle((x0, top, x1, top + 120), outline=GRID)
        for v in (lo, (lo + hi) // 2, hi):
            yy = top + (v - lo) * 120 / (hi - lo) if idx else top + 120 - (v - lo) * 120 / (hi - lo)
            d.text((x0 - 40, yy - 7), f'${v:02X}', font=fs, fill=DIM)
        def yv(v, idx=idx, top=top, lo=lo, hi=hi):
            return top + (v - lo) * 120 / (hi - lo) if idx else top + 120 - (v - lo) * 120 / (hi - lo)
        pts = [(xf(fr), yv(hero[idx] & 0x7F if idx else hero[idx]))
               for fr, bits, hero, st in rows]
        d.line(pts, fill=col, width=2)
    # status
    top = 520
    d.text((14, top + 3), 'Status', font=f, fill=FG)
    prev, lane = None, 0
    for j, (fr, bits, hero, st) in enumerate(rows):
        fr2 = rows[j + 1][0] if j + 1 < len(rows) else fr + step
        col = {0: (180, 220, 180), 2: (250, 190, 120), 4: (190, 190, 250)}.get(st, (230, 180, 230))
        d.rectangle((xf(fr), top, xf(fr2), top + 20), fill=col)
        if st != prev:
            d.text((xf(fr) + 2, top + 22 + 16 * lane), str(st) if st in (0, 2) else f'{st}: {STATUS.get(st, "")}',
                   font=fs, fill=FG)
            lane, prev = 1 - lane, st
    d.text((14, top + 64), 'Room', font=f, fill=FG)
    prevr, lastx = None, -999
    for fr, room in rooms:
        if room != prevr:
            d.line((xf(fr), top + 62, xf(fr), top + 80), fill=FG)
            d.text((xf(fr) + 3, top + 64), f'${room:02X}', font=fs, fill=FG)
            prevr = room
    for t in range(a - a % 50 + 50, b + 1, 50):
        d.line((xf(t), 40, xf(t), 76), fill=GRID)
        d.text((xf(t) - 14, 626 - 14), str(t), font=fs, fill=DIM)
    im.save(out)


def fig_selector(out):
    """the regions of MoveCursor's ClassifyCursor $C206 over the selector picture (src/res/screens/selector.png)"""
    pic = Image.open(os.path.join(CASE, 'src', 'res', 'screens', 'selector.png')).convert('RGB')
    sc = 3
    im = Image.new('RGB', (W, 192 * sc + 150), K.BACKGROUND)
    im.paste(pic.resize((256 * sc, 192 * sc), Image.NEAREST), (0, 60))
    d = ImageDraw.Draw(im)
    f, fs, fb = K.font(13), K.font(12), K.font(16)
    d.text((10, 8), 'The selector: where the cursor\'s corner (CursorXY $C4A2) must be for each choice', font=fb,
           fill=K.TEXT)
    d.text((10, 32), 'ClassifyCursor $C206 tests the boxes in this order, the first match wins; outside all of them '
                     'Explorer $5B70 = $FF', font=fs, fill=K.DIM)
    # (name, x0, x1, y0, y1) half-open, from the CP constants of $C206-$C275
    regions = [('0 Fortisque-Smithe', 0x4C, 0x91, 0x00, 0x4D), ('1 Herr Krusche', 0xBC, 0xE9, 0x0C, 0x57),
               ('2 Henri Beaucoup', 0xB0, 0xDB, 0x6E, 0xA9), ('3 Big John Caine', 0x00, 0x36, 0x3C, 0x7D),
               ('4 Wu Pong', 0x52, 0x7F, 0x86, 0xA9), ('$FE Help', 0x0A, 0x22, 0x8C, 0xA9)]
    cols = [(255, 80, 200), (80, 200, 255), (120, 255, 120), (255, 200, 60), (200, 160, 255), (255, 120, 80)]
    for (n, x0, x1, y0, y1), c in zip(regions, cols):
        d.rectangle((x0 * sc, 60 + y0 * sc, x1 * sc - 1, 60 + y1 * sc - 1), outline=c, width=3)
        d.text((x0 * sc + 4, 60 + y0 * sc + 4), n.split()[0], font=fb, fill=c)
    # the start position and the cursor's reach
    d.rectangle((0x64 * sc, 60 + 0x50 * sc, (0x64 + 24) * sc, 60 + (0x50 + 16) * sc), outline=(255, 255, 255),
                width=2)
    d.text((0x64 * sc, 60 + (0x50 + 16) * sc + 2), 'start ($64, $50)', font=fs, fill=(255, 255, 255))
    d.rectangle((0, 60, 0xE8 * sc, 60 + 0xA8 * sc), outline=(150, 150, 160), width=1)
    x = 784
    y = 64
    d.text((x, y), 'box: x range, y range', font=fs, fill=K.DIM)
    for i, ((n, x0, x1, y0, y1), c) in enumerate(zip(regions, cols)):
        d.text((x, y + 22 + 40 * i), n, font=f, fill=c)
        d.text((x, y + 40 + 40 * i), f'x ${x0:02X}-${x1 - 1:02X}  y ${y0:02X}-${y1 - 1:02X}', font=fs, fill=K.TEXT)
    y += 22 + 40 * 6 + 10
    for t in ['grey frame: the corner\'s reach,', 'x 0-$E8, y 0-$A8 (MoveCursor $C1D5)', '',
              'FIRE on a face copies that', 'explorer\'s 64 frames to $6000;', 'FIRE on Help shows the pages;',
              'FIRE elsewhere does nothing.']:
        d.text((x, y), t, font=fs, fill=K.TEXT)
        y += 18
    yb = 60 + 192 * sc + 10
    for t in ['How to read: each box is the area the cursor\'s top-left corner must be in; the face it chooses is '
              'drawn below and right of it,',
              'because the hand cursor is 24 x 16 pixels with its finger near the corner. Boxes 1, 4 and Help are '
              'open towards the edge: their',
              'last test is a single "x >= " or "y >= ", and the cursor\'s reach ends them (drawn to the reach).']:
        d.text((10, yb), t, font=fs, fill=K.TEXT)
        yb += 20
    im = im.crop((0, 0, W, yb + 8))
    im.save(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('what', choices=['keyboard', 'bits', 'menu', 'play', 'chart', 'selector'])
    p.add_argument('--work')
    p.add_argument('--inputs')
    p.add_argument('--from', dest='a', type=int)
    p.add_argument('--to', dest='b', type=int)
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--title', default='')
    p.add_argument('--out', required=True)
    a = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    if a.what == 'keyboard':
        fig_keyboard(a.out)
    elif a.what == 'bits':
        fig_bits(a.out)
    elif a.what == 'selector':
        fig_selector(a.out)
    elif a.what == 'menu':
        fig_menu(a.work, a.inputs, a.a, a.b, a.step, a.out)
    elif a.what == 'play':
        fig_play(a.work, a.inputs, a.a, a.b, a.step, a.out, a.title)
    else:
        fig_chart(a.work, a.inputs, a.a, a.b, a.step, a.out, a.title)


if __name__ == '__main__':
    main()
