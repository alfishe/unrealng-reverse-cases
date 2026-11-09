#!/usr/bin/env python3
"""The figures of doc 05 (the controls), 1050 pixels wide, into docs/img/controls/.

    python3 tools/fig_controls.py keyboard   # the 48K keyboard: every key the game reads, its port and bit, its uses
    python3 tools/fig_controls.py devices    # the six input handlers: which input bit becomes which control bit
    python3 tools/fig_controls.py all

The data is from the code (build/game.lst): ControlsRead $AE17 and its six handlers $AE3A-$AECD, OptionsSelect's key
tables $83BA-$83D7, the menu tests $8215-$8270 and $8321, HoldCheck $AECE, TuneToggleCheck $AF15, BuggyBreakTest
$AABF, BreakKeyTest $9737, EntryFieldEdit $8D0D.
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig_design import BG, F13, F14B, F16B, GREY, INK, WIDTH, font  # noqa: E402

CASE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(CASE, 'docs', 'img', 'controls')
F11 = font(11)

ROLE = {'play': (220, 60, 50), 'game': (230, 140, 30), 'menu': (60, 120, 220), 'option': (140, 80, 200),
        'joy60': (50, 150, 90), 'joy15': (40, 170, 170), 'cursor': (150, 150, 40), 'entry': (120, 120, 120),
        'dead': (170, 170, 170)}
ROLE_NAME = [('play', 'play: the keyboard controls'), ('game', 'play: hold, tune, abort'),
             ('menu', 'the menus'), ('option', 'the options page'), ('joy60', 'Sinclair joystick on 6-0'),
             ('joy15', 'Sinclair joystick on 1-5'), ('cursor', 'cursor joystick'),
             ('entry', 'the hi-score entry'), ('dead', 'tested, result unused')]

# the four rows of the 48K keyboard: (key, port, bit)
ROWS = [
    [('1', 'F7FE', 0), ('2', 'F7FE', 1), ('3', 'F7FE', 2), ('4', 'F7FE', 3), ('5', 'F7FE', 4),
     ('6', 'EFFE', 4), ('7', 'EFFE', 3), ('8', 'EFFE', 2), ('9', 'EFFE', 1), ('0', 'EFFE', 0)],
    [('Q', 'FBFE', 0), ('W', 'FBFE', 1), ('E', 'FBFE', 2), ('R', 'FBFE', 3), ('T', 'FBFE', 4),
     ('Y', 'DFFE', 4), ('U', 'DFFE', 3), ('I', 'DFFE', 2), ('O', 'DFFE', 1), ('P', 'DFFE', 0)],
    [('A', 'FDFE', 0), ('S', 'FDFE', 1), ('D', 'FDFE', 2), ('F', 'FDFE', 3), ('G', 'FDFE', 4),
     ('H', 'BFFE', 4), ('J', 'BFFE', 3), ('K', 'BFFE', 2), ('L', 'BFFE', 1), ('ENTER', 'BFFE', 0)],
    [('CAPS', 'FEFE', 0), ('Z', 'FEFE', 1), ('X', 'FEFE', 2), ('C', 'FEFE', 3), ('V', 'FEFE', 4),
     ('B', '7FFE', 4), ('N', '7FFE', 3), ('M', '7FFE', 2), ('SYMB', '7FFE', 1), ('SPACE', '7FFE', 0)],
]

USES = {
    '1': [('option', 'Beginner'), ('joy15', 'left')], '2': [('option', 'Champion'), ('joy15', 'right')],
    '3': [('joy15', 'down')], '4': [('joy15', 'up')], '5': [('joy15', 'fire'), ('cursor', 'left')],
    '6': [('joy60', 'left'), ('cursor', 'down')], '7': [('joy60', 'right'), ('cursor', 'up')],
    '8': [('joy60', 'down'), ('cursor', 'right')], '9': [('joy60', 'up')],
    '0': [('joy60', 'fire'), ('cursor', 'fire'), ('dead', 'test')],
    'Q': [('play', 'fast')], 'T': [('game', 'tune'), ('option', '2 players')],
    'O': [('play', 'jump'), ('option', '1 player')], 'P': [('play', 'fire')],
    'A': [('play', 'slow')], 'S': [('menu', 'start'), ('game', 'go on')], 'G': [('menu', 'verify')],
    'H': [('menu', 'heroes'), ('game', 'hold')], 'J': [('menu', 'save')], 'K': [('option', 'keyboard')],
    'L': [('menu', 'load')], 'ENTER': [('entry', 'done')],
    'CAPS': [('game', 'abort+SP'), ('dead', 'test+SP')], 'SPACE': [('game', 'abort+CS'), ('dead', 'test+CS')],
    'Z': [('option', 'Sinclair 1')], 'X': [('option', 'Kempston')], 'C': [('option', 'cursor')],
    'V': [('option', 'Fuller')], 'B': [('option', 'Sinclair 2')],
}


def keyboard():
    kw, kh, gap = 96, 112, 7
    left = (WIDTH - 10 * kw - 9 * gap) // 2
    top = 40
    img = Image.new('RGB', (WIDTH, top + 4 * (kh + gap) + 150), BG)
    d = ImageDraw.Draw(img)
    d.text((left, 8), 'The keys Moon Patrol reads: the key, its half-row port and bit, and what it does where',
           font=F16B, fill=INK)
    for r, row in enumerate(ROWS):
        for c, (key, port, bit) in enumerate(row):
            x = left + c * (kw + gap)
            y = top + r * (kh + gap)
            uses = USES.get(key, [])
            d.rounded_rectangle((x, y, x + kw, y + kh), 6, fill=(255, 255, 255) if uses else (232, 232, 228),
                                outline=GREY)
            d.text((x + 6, y + 4), key, font=F14B, fill=INK if uses else GREY)
            d.text((x + 6, y + 22), '%s b%d' % (port, bit), font=F11, fill=GREY)
            for k, (role, text) in enumerate(uses):
                ty = y + 40 + k * 23
                d.rectangle((x + 4, ty, x + kw - 4, ty + 19), fill=ROLE[role])
                d.text((x + 8, ty + 2), text, font=F13, fill=(255, 255, 255))
    ly = top + 4 * (kh + gap) + 8
    for i, (role, name) in enumerate(ROLE_NAME):
        x = left + (i % 3) * 340
        y = ly + (i // 3) * 22
        d.rectangle((x, y + 2, x + 16, y + 16), fill=ROLE[role])
        d.text((x + 22, y + 1), name, font=F13, fill=INK)
    d.text((left, ly + 74), 'Grey keys: never read by the game (the hi-score entry reads every key through the ROM\'s'
           ' LAST_K).', font=F13, fill=GREY)
    d.text((left, ly + 94), 'H in the menus needs H alone in its half-row; S alone in its half-row; abort and test: '
           'CAPS SHIFT and SPACE together.', font=F13, fill=GREY)
    d.text((left, ly + 114), 'python3 tools/fig_controls.py keyboard', font=F13, fill=GREY)
    out = os.path.join(OUT, 'keyboard.png')
    img.save(out)
    print(out, img.size)


CONTROL = ['fire', 'jump', 'down', 'fast', 'slow']
CCOL = [(220, 60, 50), (60, 120, 220), (150, 150, 150), (50, 150, 90), (230, 140, 30)]
# device: (option key, handler, [(source label, [bit names 0..7 or 0..4])], [(source index, source bit, control bit)])
DEVICES = [
    ('K keyboard', 'KeysQAOP $AEB2', [('IN $DFFE', 'P O I U Y'), ('IN $FBFE', 'Q W E R T'),
                                      ('IN $FDFE', 'A S D F G')],
     [(0, 0, 0), (0, 1, 1), (1, 0, 3), (2, 0, 4)], 'active low; P fire, O jump, Q fast, A slow'),
    ('Z Sinclair 1', 'JoySinclair1 $AE3A', [('IN $EFFE', '0 9 8 7 6'), ('IN $F7FE', '1 2 3 4 5')],
     [(0, 0, 0), (0, 1, 1), (0, 2, 2), (0, 3, 3), (0, 4, 4), (1, 4, 0), (1, 3, 1), (1, 2, 2), (1, 1, 3), (1, 0, 4)],
     'both joysticks ANDed: 1-5 reversed by 5 x RRA / RL C'),
    ('B Sinclair 2', 'JoySinclair2 $AE4F', [('IN $EFFE  player 1', '0 9 8 7 6'), ('IN $F7FE  player 2', '1 2 3 4 5')],
     [(0, 0, 0), (0, 1, 1), (0, 2, 2), (0, 3, 3), (0, 4, 4), (1, 4, 0), (1, 3, 1), (1, 2, 2), (1, 1, 3), (1, 0, 4)],
     'two players: each his own; one player: as Sinclair 1'),
    ('X Kempston', 'JoyKempston $AE64', [('IN $1F', 'R L D U F')],
     [(0, 4, 0), (0, 3, 1), (0, 2, 2), (0, 0, 3), (0, 1, 4)], 'active high: rebuilt bit by bit, then CPL'),
    ('C cursor', 'JoyCursor $AE7E', [('IN $EFFE', '0 9 8 7 6'), ('IN $F7FE', '1 2 3 4 5')],
     [(0, 0, 0), (0, 3, 1), (0, 4, 2), (0, 2, 3), (1, 4, 4)], '0 fire, 7 up, 6 down, 8 right, 5 left'),
    ('V Fuller', 'JoyFuller $AE9D', [('IN $7F', 'U D L R - - - F')],
     [(0, 7, 0), (0, 0, 1), (0, 1, 2), (0, 3, 3), (0, 2, 4)], 'active low; fire on bit 7'),
]


def devices():
    rh = 150
    top = 40
    img = Image.new('RGB', (WIDTH, top + len(DEVICES) * rh + 60), BG)
    d = ImageDraw.Draw(img)
    d.text((16, 8), 'ControlsRead $AE17: each handler routes its input bits to the five control bits',
           font=F16B, fill=INK)
    bw = 30
    ox = WIDTH - 20 - 5 * bw
    for i, name in enumerate(CONTROL):
        d.text((ox + (4 - i) * bw + 2, top - 2), name[:4], font=F11, fill=CCOL[i])
    for n, (opt, handler, sources, maps, note) in enumerate(DEVICES):
        y = top + 14 + n * rh
        d.text((16, y + 4), opt, font=F14B, fill=INK)
        d.text((16, y + 24), handler, font=F13, fill=GREY)
        d.text((16, y + rh - 34), note, font=F13, fill=GREY)
        sx0 = 230
        boxes = []
        for s, (label, bits) in enumerate(sources):
            names = bits.split()
            x = sx0 + s * 220
            d.text((x, y), label, font=F13, fill=INK)
            # bits drawn 7..0 or 4..0 right to left as on a byte
            cells = {}
            for b, nm in enumerate(names):
                cx = x + (len(names) - 1 - b) * bw
                d.rectangle((cx, y + 20, cx + bw - 2, y + 44), fill=(255, 255, 255), outline=GREY)
                d.text((cx + 4, y + 25), nm[:3], font=F13, fill=INK)
                d.text((cx + 10, y + 46), str(b), font=F11, fill=GREY)
                cells[b] = cx + bw // 2
            boxes.append(cells)
        cy = y + 20
        for i in range(5):
            cx = ox + (4 - i) * bw
            d.rectangle((cx, cy, cx + bw - 2, cy + 24), fill=CCOL[i])
            d.text((cx + 10, cy + 26), str(i), font=F11, fill=GREY)
        for k, (s, sb, cb) in enumerate(maps):
            x1 = boxes[s][sb]
            x2 = ox + (4 - cb) * bw + bw // 2
            yy = y + 62 + 6 * k
            d.line((x1, y + 58, x1, yy), fill=CCOL[cb], width=2)
            d.line((x1, yy, x2, yy), fill=CCOL[cb], width=2)
            d.line((x2, yy, x2, cy + 38), fill=CCOL[cb], width=2)
        d.line((16, y + rh - 12, WIDTH - 16, y + rh - 12), fill=(225, 225, 220))
    ly = img.height - 40
    d.text((16, ly), 'Right: the control byte, bit 4 at the left; ControlsReadDone $AE2C inverts it (CPL), so a 1 is '
           'pressed.', font=F13, fill=INK)
    d.text((16, ly + 18), 'Bit 2 (down) is read by no one.   python3 tools/fig_controls.py devices', font=F13,
           fill=GREY)
    out = os.path.join(OUT, 'devices.png')
    img.save(out)
    print(out, img.size)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    for name, fn in [('keyboard', keyboard), ('devices', devices)]:
        if what in (name, 'all'):
            fn()
