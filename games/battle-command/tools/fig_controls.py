#!/usr/bin/env python3
"""The figures of doc 05 (controls), drawn from the image and the recordings' screens.

    python3 tools/fig_controls.py zones    docs/img/controls/zones.png     # every menu screen with its click zones
    python3 tools/fig_controls.py devices  docs/img/controls/devices.png   # the five readers: ports, bits, the code
    python3 tools/fig_controls.py keyboard docs/img/controls/keyboard.png  # ScanKeyboard's codes and their actions
    python3 tools/fig_controls.py graph                                    # the ScreenList graph as text
    python3 tools/fig_controls.py timeline docs/img/controls/pointer-timeline.png --work W  # menu 0-60
    python3 tools/fig_controls.py driving docs/img/controls/driving.png --work W   # play 8360-8480, 10510-10650

The zones come from the zone tables of bank 6 (6-byte records x1, x2, y1, y2, routine; PointerZones `$6D42`), the
screen graph from ScreenList `$74E6` (src/game/screens.asm), the key codes from KeyCodes `$8950`, the device keys
from KeyTable `$9862`: all read from the banks the build cuts (work/mkgame/bankN.bin, tools/image.py's image of c1
at the entry). The screens are the recordings' named screens (work/stage1/rec/*/screens).
"""
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

BANKS = {n: open(os.path.join(CASE, 'work', 'mkgame', f'bank{n}.bin'), 'rb').read() for n in range(8)}


def rd(a, hi=6):
    if a < 0x4000:
        return 0
    if a < 0x8000:
        return BANKS[5][a - 0x4000]
    if a < 0xC000:
        return BANKS[2][a - 0x8000]
    return BANKS[hi][a - 0xC000]


def word(a, hi=6):
    return rd(a, hi) | rd(a + 1, hi) << 8


def names():
    out = {}
    for f, bank6 in (('game.lst', False), ('bank6.lst', True)):
        for line in open(os.path.join(CASE, 'build', f)):
            m = re.match(r'\s*\d+\+?\s+([0-9A-F]{4})\s+([A-Za-z_]\w*):', line)
            if m and not m.group(2).startswith(('l_', 'sub_', 'data_')):
                a = int(m.group(1), 16)
                if bank6 == (a >= 0xC000):
                    out.setdefault(a, m.group(2))
    return out


NAMES = names()


def zones(table):
    out = []
    a = table
    while table and rd(a):
        x1, x2, y1, y2 = rd(a), rd(a + 1), rd(a + 2), rd(a + 3)
        out.append((x1, x2, y1, y2, word(a + 4)))
        a += 6
    return out


# the ScreenList nodes: address -> (draw routine, zone table, transitions)
NODES = {}


def node(a):
    if a in NODES or a == 0:
        return
    draw, table = word(a), word(a + 2)
    trans = []
    k = a + 4
    while True:
        w = word(k)
        if w in (0xFFFF,) or not (0x74E8 <= w <= 0x7574 or w == 0):
            break
        trans.append(w)
        k += 2
        if k + 2 > 0x7578 or (k in [n for n in range(0x74E8, 0x7578)] and k in NODES):
            break
    NODES[a] = (draw, table, trans)


def graph():
    """the nodes as the code lays them: each node's transitions run to the next node's address"""
    starts = sorted({0x74E8, 0x74F2, 0x74F8, 0x74FE, 0x7504, 0x750E, 0x7514, 0x751A, 0x7528, 0x7536, 0x7544,
                     0x7552, 0x755E, 0x7564, 0x756A, 0x7572})
    out = {}
    for i, a in enumerate(starts):
        end = starts[i + 1] if i + 1 < len(starts) else 0x7578
        out[a] = (word(a), word(a + 2), [word(k) for k in range(a + 4, end, 2)])
    return out


SHOTS = [
    ('Title', 0xC4E9, 'stage1/rec/menu/screens/000000-title.png'),
    ('Catalogue', 0xC851, 'stage1/rec/menu/screens/006287-mission-1-marked.png'),
    ('Briefing', 0xCA10, 'stage1/rec/menu/screens/006600-mission-1-map.png'),
    ('Stores', 0xCBC4, 'stage1/rec/play/screens/007327-mission-1-stores.png'),
    ('Mission status', 0xC4DC, 'stage1/rec/menu/screens/010686-status.png'),
    ('Mission failed', 0xCD70, 'stage2/rec/fuel/screens/007904-drive-01.png'),
]
COLOURS = [(255, 64, 64), (64, 220, 255), (255, 220, 0), (120, 255, 120), (255, 120, 255), (255, 160, 60),
           (180, 180, 255), (255, 255, 255)]


def zones_figure(out):
    f = kitlib.font(13)
    fs = kitlib.font(12)
    tiles = []
    for title, table, shot in SHOTS:
        im = Image.open(os.path.join(CASE, 'work', shot))
        im = im.convert('RGB').resize((512, 384), Image.NEAREST)
        d = ImageDraw.Draw(im)
        legend = []
        for i, (x1, x2, y1, y2, r) in enumerate(zones(table)):
            c = COLOURS[i % len(COLOURS)]
            d.rectangle((2 * x1, 2 * y1, 2 * x2 - 1, 2 * y2 - 1), outline=c, width=3)
            d.text((2 * x1 + 3, 2 * y1 + 2), str(i + 1), fill=c, font=fs)
            legend.append((c, f'{i + 1} {x1}-{x2 - 1} x {y1}-{y2 - 1}: {NAMES.get(r, "$%04X" % r)}'))
        tile = Image.new('RGB', (512, 384 + 24 + 17 * max(1, len(legend))), (16, 16, 24))
        tile.paste(im, (0, 24))
        d = ImageDraw.Draw(tile)
        d.text((4, 4), f'{title}: zones at ${table:04X} (bank 6)', fill=(255, 255, 255), font=f)
        for k, (c, text) in enumerate(legend):
            d.text((6, 384 + 28 + 17 * k), text, fill=c, font=fs)
        tiles.append(tile)
    cols = 2
    w = 512 * cols + 10 * (cols - 1)
    rows = [tiles[i:i + cols] for i in range(0, len(tiles), cols)]
    h = sum(max(t.height for t in r) for r in rows) + 10 * (len(rows) - 1) + 40
    sheet = Image.new('RGB', (w, h), (16, 16, 24))
    d = ImageDraw.Draw(sheet)
    d.text((6, 8), 'The click zones of every menu screen (PointerZones $6D42): x1 <= X < x2, y1 <= Y < y2, '
                   'pointer pixels', fill=(255, 255, 255), font=kitlib.font(15))
    y = 40
    for r in rows:
        for i, t in enumerate(r):
            sheet.paste(t, (i * 522, y))
        y += max(t.height for t in r) + 10
    sheet = sheet.resize((1050, int(sheet.height * 1050 / sheet.width)), Image.LANCZOS)
    sheet.save(out)
    print(out, sheet.size)


def box(d, x, y, w, h, text, fill, f, ink=(0, 0, 0)):
    d.rectangle((x, y, x + w, y + h), fill=fill, outline=(200, 200, 200))
    tw = d.textlength(text, font=f)
    d.text((x + (w - tw) / 2, y + (h - 14) / 2), text, fill=ink, font=f)


def devices_figure(out):
    """the five readers: which port bit lands in which bit of the code DecodeDirections takes"""
    W = 1050
    f = kitlib.font(14)
    fb = kitlib.font(16)
    fs = kitlib.font(12)
    rows = [
        ('5 Keyboard (ReadKeys $9842)', 'IN ($xxFE) per key: KeyTable $9862',
         ['O ($DF b1)', 'P ($DF b0)', 'A ($FD b0)', 'Q ($FB b0)', 'SPACE ($7F b0)']),
        ('4 Kempston joystick (ReadKempston $982F)', 'IN ($1F): bits 0 R, 1 L, 2 D, 3 U, 4 fire, reordered',
         ['bit 1 left', 'bit 0 right', 'bit 2 down', 'bit 3 up', 'bit 4 fire']),
        ('1 Sinclair (ReadSinclair $9726)', 'IN ($EFFE) = keys 6 7 8 9 0, inverted (CPL)',
         ['key 6', 'key 7', 'key 8', 'key 9', 'key 0']),
        ('2 Cursor (ReadCursor $972D)', 'IN ($F7FE) key 5, IN ($EFFE) keys 6 7 8, IN ($7FFE) SPACE',
         ['key 5', 'key 8', 'key 6', 'key 7', 'SPACE']),
        ('3 Kempston mouse (ReadMouse $9822)', 'IN ($FBDF) X, IN ($FFDF) Y: deltas, no DecodeDirections',
         ['-', '-', '-', '-', 'bit 0 of dX']),
    ]
    head = ['bit 4: left', 'bit 3: right', 'bit 2: down', 'bit 1: up', 'bit 0: fire']
    cols = [(255, 140, 140), (140, 200, 255), (255, 220, 120), (150, 240, 150), (230, 160, 255)]
    rh = 64
    H = 120 + rh * len(rows) + 120
    im = Image.new('RGB', (W, H), (16, 16, 24))
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'The five control readers: each turns its port bits into one 5-bit code for DecodeDirections $9758',
           fill=(255, 255, 255), font=fb)
    x0, bw = 400, 126
    for i, h in enumerate(head):
        box(d, x0 + i * (bw + 4), 44, bw, 34, h, cols[i], f)
    d.text((10, 52), 'reader (option key) and its port', fill=(200, 200, 200), font=f)
    for r, (name, port, bits) in enumerate(rows):
        y = 96 + r * rh
        d.text((10, y), name, fill=(255, 255, 255), font=f)
        d.text((10, y + 22), port, fill=(170, 170, 190), font=fs)
        for i, b in enumerate(bits):
            fill = cols[i] if b != '-' else (60, 60, 70)
            box(d, x0 + i * (bw + 4), y, bw, 40, b, fill, fs if len(b) > 14 else f)
    y = 96 + len(rows) * rh + 10
    notes = ['A pressed key reads 0 on the port; ReadKeys turns each into 1 (AND mask, DEC A, RLA: the carry is',
             'the pressed bit). ReadSinclair and ReadCursor end in CPL. ReadKempston\'s port is already active high.',
             'The mouse never reaches DecodeDirections and reads no button: the steps keep their last values, and',
             'fire is bit 0 of the X delta, always 0 (X is doubled). Its store also clobbers $67BD (section 5.5).']
    for k, n in enumerate(notes):
        d.text((10, y + 18 * k), n, fill=(210, 210, 210), font=fs)
    im.save(out)
    print(out, im.size)


ROWS = [(0xFEFE, 'CAPS Z X C V'), (0xFDFE, 'A S D F G'), (0xFBFE, 'Q W E R T'), (0xF7FE, '1 2 3 4 5'),
        (0xEFFE, '0 9 8 7 6'), (0xDFFE, 'P O I U Y'), (0xBFFE, 'ENT L K J H'), (0x7FFE, 'SPC SYM M N B')]
ACTIONS = {
    'E': 'sound off', 'M': 'map view', 'D': 'Dragonfly', '1': 'weapon 1', '2': 'weapon 2', '3': 'weapon 3',
    '4': 'weapon 4', 'H': 'Helicarrier', 'N': 'night sight', 'R': 'rear view', 'B': 'binoculars', 'Z': 'zoom',
    'C': 'back to 3D', 'J': '(none)', 'K': '(none)', 'S': 'brake',
    'Q': 'up', 'A': 'down', 'O': 'left', 'P': 'right', 'SPC': 'fire',
}


def keyboard_figure(out):
    """the 40 keys at their places on the Spectrum keyboard, each with ScanKeyboard's code and its play action"""
    codes = [rd(0x8950 + i) for i in range(40)]
    # KeyCodes order: half rows $7FFE, $BFFE, $DFFE, $EFFE, $F7FE, $FBFE, $FDFE, $FEFE, bits 0-4
    order = [0x7FFE, 0xBFFE, 0xDFFE, 0xEFFE, 0xF7FE, 0xFBFE, 0xFDFE, 0xFEFE]
    labels = {0x7FFE: ['SPC', 'SYM', 'M', 'N', 'B'], 0xBFFE: ['ENT', 'L', 'K', 'J', 'H'],
              0xDFFE: ['P', 'O', 'I', 'U', 'Y'], 0xEFFE: ['0', '9', '8', '7', '6'],
              0xF7FE: ['1', '2', '3', '4', '5'], 0xFBFE: ['Q', 'W', 'E', 'R', 'T'],
              0xFDFE: ['A', 'S', 'D', 'F', 'G'], 0xFEFE: ['CAPS', 'Z', 'X', 'C', 'V']}
    code = {}
    for r, port in enumerate(order):
        for b in range(5):
            code[labels[port][b]] = (codes[r * 5 + b], port, b)
    layout = [['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
              ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
              ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENT'],
              ['CAPS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SYM', 'SPC']]
    W = 1050
    kw, kh, gap = 92, 74, 6
    im = Image.new('RGB', (W, 60 + 4 * (kh + gap) + 110), (16, 16, 24))
    d = ImageDraw.Draw(im)
    f, fs, fb = kitlib.font(15), kitlib.font(11), kitlib.font(16)
    d.text((10, 8), 'ScanKeyboard $8910: the code of every key (KeyCodes $8950) and what it does in play',
           fill=(255, 255, 255), font=fb)
    for r, row in enumerate(layout):
        for c, k in enumerate(row):
            x = 10 + c * (kw + gap) + (r * 12)
            y = 44 + r * (kh + gap)
            cv, port, bit = code[k]
            act = ACTIONS.get(k)
            if k in ('Q', 'A', 'O', 'P', 'SPC'):
                fill = (90, 170, 90)
            elif act and act != '(none)':
                fill = (70, 110, 190)
            else:
                fill = (50, 50, 62)
            d.rectangle((x, y, x + kw, y + kh), fill=fill, outline=(170, 170, 170))
            d.text((x + 6, y + 4), k, fill=(255, 255, 255), font=f)
            d.text((x + kw - 38, y + 6), f'${cv:02X}', fill=(255, 230, 120), font=fs)
            d.text((x + 6, y + 28), f'${port >> 8:02X} b{bit}', fill=(200, 200, 210), font=fs)
            if act:
                d.text((x + 6, y + 48), act, fill=(255, 255, 255), font=fs)
    y = 44 + 4 * (kh + gap) + 8
    notes = ['Each key: its name, its code (yellow, ASCII for letters and digits; ENTER 3, SPACE 2, CAPS 1, SYMBOL 0),',
             'its half row (the high byte of the port) and bit. Green: the default control keys (ReadKeys, KeyTable $9862).',
             'Blue: the play keys (PlayKeys $6B3B; S is read by PlayerStep $A8C7). CAPS SHIFT with 0 gives code $04 (delete).',
             'The scan returns the first pressed key of the order $7FFE, $BFFE, ... $FEFE, bit 0 first.']
    for k, n in enumerate(notes):
        d.text((10, y + 18 * k), n, fill=(210, 210, 210), font=kitlib.font(13))
    im.save(out)
    print(out, im.size)


def timeline_figure(out, work, f0=0, f1=60):
    """menu frames f0..f1: the A and SPACE keys of tests/inputs/menu.txt against StepY $985F, the repeat count $67B7,
    the pointer Y $7DC1 and the click flag $6D43, each read with memory_at at the frame's start"""
    sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)

    def at(f, a):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0,
                                         'offset': a, 'length': 1}, ok=False)
        return int(r.structured['hex'], 16)
    held = {}
    cur = set()
    events = []
    for line in open(os.path.join(CASE, 'tests', 'inputs', 'menu.txt')):
        parts = line.split()
        if len(parts) >= 2 and parts[0].isdigit():
            events.append((int(parts[0]), parts[1:]))
    k = 0
    for f in range(f0, f1 + 1):
        while k < len(events) and events[k][0] <= f:
            cur = set() if events[k][1] == ['-'] else set(events[k][1])
            k += 1
        held[f] = set(cur)
    rows = []
    for f in range(f0, f1 + 1):
        sy = at(f, 0x985F)
        rows.append((f, sy - 256 if sy > 127 else sy, at(f, 0x67B7), at(f, 0x7DC1), at(f, 0x6D43)))
    W, H = 1050, 470
    im = Image.new('RGB', (W, H), (16, 16, 24))
    d = ImageDraw.Draw(im)
    f, fs = kitlib.font(15), kitlib.font(12)
    d.text((10, 8), 'Pointer, menu %d-%d: A moves it down, the step grows by one per 4 held frames, '
                    'a release resets it' % (f0, f1), fill=(255, 255, 255), font=f)
    x0, x1 = 120, W - 20
    n = f1 - f0

    def X(fr):
        return x0 + (fr - f0) * (x1 - x0) / n
    lanes = [('keys held', 50, 30), ('StepY $985F', 100, 70), ('repeat $67B7', 190, 50), ('pointer Y $7DC1', 260, 120),
             ('click $6D43', 400, 24)]
    for name, y, h in lanes:
        d.text((10, y + h / 2 - 8), name, fill=(200, 200, 210), font=fs)
        d.line((x0, y + h, x1, y + h), fill=(60, 60, 75))
    for fr in range(f0, f1 + 1):
        x = X(fr)
        if fr % 10 == 0:
            d.line((x, 44, x, 430), fill=(45, 45, 58))
            d.text((x - 8, 436), str(fr), fill=(170, 170, 180), font=fs)
        if 'A' in held[fr]:
            d.rectangle((x, 52, X(fr + 1) - 1, 66), fill=(90, 170, 90))
        if 'SPACE' in held[fr]:
            d.rectangle((x, 66, X(fr + 1) - 1, 78), fill=(230, 160, 255))
    d.text((x1 - 190, 34), 'green A (down), violet SPACE', fill=(170, 170, 180), font=fs)
    pts = [(X(r[0]), 170 - r[1] * 8) for r in rows]
    d.line((x0, 170, x1, 170), fill=(80, 80, 95))
    for (fr, sy, rep, py, click), (x, y) in zip(rows, pts):
        d.rectangle((x - 2, y - 2, x + 2, y + 2), fill=(255, 220, 120))
        d.rectangle((x - 2, 240 - rep * 10, x + 2, 240), fill=(140, 200, 255))
        d.rectangle((x - 2, 380 - (py - 120) * 1.8 - 2, x + 2, 380 - (py - 120) * 1.8 + 2), fill=(255, 140, 140))
        if click:
            d.rectangle((x - 2, 402, x + 2, 422), fill=(230, 160, 255))
    d.line(pts, fill=(255, 220, 120))
    d.text((x0 + 4, 102), '+8 (down)', fill=(170, 170, 180), font=fs)
    d.text((x0 + 4, 172), '0', fill=(170, 170, 180), font=fs)
    py = [r[3] for r in rows]
    d.text((x0 + 4, 262), f'{max(py)}', fill=(170, 170, 180), font=fs)
    d.text((x0 + 4, 362), f'{min(py)}', fill=(170, 170, 180), font=fs)
    d.text((10, 452), 'frame (memory_at at the start of each frame: what the interrupt of the frame before wrote)',
           fill=(170, 170, 180), font=fs)
    im.save(out)
    print(out, im.size, rows[:3], rows[-3:])


def keys_held(name, frames):
    """{frame: set of keys} from tests/inputs/<name>.txt (a line 'frame keys...' or 'frame -')"""
    events = []
    for line in open(os.path.join(CASE, 'tests', 'inputs', name + '.txt')):
        parts = line.split()
        if len(parts) >= 2 and parts[0].isdigit():
            events.append((int(parts[0]), parts[1:]))
    held, cur, k = {}, set(), 0
    for f in frames:
        while k < len(events) and events[k][0] <= f:
            cur = set() if events[k][1] == ['-'] else set(events[k][1])
            k += 1
        held[f] = set(cur)
    return held


def driving_figure(out, work):
    """play 8360-8480 (Q: faster) and 10510-10650 (Q P: turn right): StepX / StepY, the speed (player record +7,
    `$75F7`), the heading (+`$22`, `$7612`) and the fuel `$7C57`, read with memory_at at each frame's start"""
    sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)

    def at(f, a, n=1):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0,
                                         'offset': a, 'length': n}, ok=False)
        return bytes.fromhex(r.structured['hex'])

    def sg(b):
        return b - 256 if b > 127 else b
    W, H = 1050, 560
    im = Image.new('RGB', (W, H), (16, 16, 24))
    d = ImageDraw.Draw(im)
    f, fs = kitlib.font(15), kitlib.font(12)
    d.text((10, 8), 'Driving (play): Q steps the speed up to 47, P turns the heading by StepX / 2 '
                    'a pass', fill=(255, 255, 255), font=f)
    lanes = [('keys', 40, 24), ('StepX $985E (blue)', 80, 70), ('StepY $985F (yellow)', 80, 70), ('speed $75F7', 180, 90),
             ('heading $7612', 300, 90), ('fuel used $7C57', 420, 90)]
    for name, y, h in lanes:
        dy = 18 if 'yellow' in name else 0
        d.text((10, y + h / 2 - 16 + dy), name, fill=(200, 200, 210), font=fs)
    panels = [(8360, 8480, 170, 590), (10510, 10650, 620, 1040)]
    for f0, f1, x0, x1 in panels:
        frames = list(range(f0, f1 + 1, 2))
        held = keys_held('play', frames)
        rows = [(fr, sg(at(fr, 0x985E)[0]), sg(at(fr, 0x985F)[0]), sg(at(fr, 0x75F7)[0]), at(fr, 0x7612)[0],
                 int.from_bytes(at(fr, 0x7C57, 2), 'little')) for fr in frames]

        def X(fr):
            return x0 + (fr - f0) * (x1 - x0) / (f1 - f0)
        for name, y, h in lanes:
            d.line((x0, y + h, x1, y + h), fill=(60, 60, 75))
        for fr in range(f0 + 20, f1 + 1, 20):
            d.line((X(fr), 36, X(fr), 512), fill=(45, 45, 58))
            d.text((X(fr) - 16, 518), str(fr), fill=(170, 170, 180), font=fs)
        for fr in frames:
            x = X(fr)
            for key, col, y in (('Q', (90, 170, 90), 42), ('P', (140, 200, 255), 54)):
                if key in held[fr]:
                    d.rectangle((x, y, X(fr + 2) - 1, y + 10), fill=col)
        fuel0 = rows[0][5]
        for name, idx, y, scale, col in (('sx', 1, 115, 4, (140, 200, 255)), ('sy', 2, 115, 4, (255, 220, 120)),
                                         ('sp', 3, 270, 1.8, (255, 140, 140)), ('hd', 4, 390, 2.5, (200, 160, 255))):
            pts = [(X(r[0]), y - r[idx] * scale) for r in rows]
            d.line(pts, fill=col, width=2)
        pts = [(X(r[0]), 510 - (fuel0 - r[5]) * 1.5) for r in rows]
        d.line(pts, fill=(160, 230, 160), width=2)
        last = rows[-1]
        d.text((x1 - 70, 182), f'max {max(r[3] for r in rows)}', fill=(255, 140, 140), font=fs)
        d.text((x1 - 70, 302), f'end {last[4]}', fill=(200, 160, 255), font=fs)
        d.text((x1 - 160, 422), f'{fuel0} down to {last[5]}', fill=(160, 230, 160), font=fs)
        d.text((x0, 518), f'{f0}', fill=(170, 170, 180), font=fs)
        print(rows[::10])
    d.text((10, 538), 'green Q, blue P; memory_at at each frame start; the interrupt sets the steps, '
                      'the 3D pass (about 7 frames) uses them', fill=(170, 170, 180), font=fs)
    im.save(out)
    print(out, im.size)


def main():
    what = sys.argv[1]
    if what == 'zones':
        zones_figure(sys.argv[2])
    elif what == 'devices':
        devices_figure(sys.argv[2])
    elif what == 'keyboard':
        keyboard_figure(sys.argv[2])
    elif what == 'timeline':
        timeline_figure(sys.argv[2], sys.argv[sys.argv.index('--work') + 1])
    elif what == 'driving':
        driving_figure(sys.argv[2], sys.argv[sys.argv.index('--work') + 1])
    elif what == 'graph':
        for a, (draw, table, trans) in graph().items():
            print(f'${a:04X} draw {NAMES.get(draw, hex(draw))} zones {NAMES.get(table, hex(table))} '
                  f'-> {[("$%04X" % t) for t in trans]}')
            for z in zones(table):
                print('   ', z[:4], NAMES.get(z[4], hex(z[4])))


if __name__ == '__main__':
    main()
