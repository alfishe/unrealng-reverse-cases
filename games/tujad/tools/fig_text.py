#!/usr/bin/env python3
"""Doc 08: the font, the HUD, the messages, the scroller, the menu and the progress screen, drawn from the built image
(build/game.bin, `$60C0-$FDFF`), the screenshots of WALKTHROUGH 6.1 and the events of tools/sound_events.py.

    python3 tools/fig_text.py font       docs/img/text/font.png: the 60 characters of Font $E002, the ones the texts use
    python3 tools/fig_text.py hud        docs/img/text/hud.png: the HUD panel labelled (c1 frame 14450)
    python3 tools/fig_text.py hudgfx     docs/img/text/hud-graphics.png: HudGraphics, HudIcons, the menu frame and logo
    python3 tools/fig_text.py messages   docs/img/text/messages.png: the ten messages as the scroller shows them
    python3 tools/fig_text.py scroller   docs/img/text/scroller.png: one text row coming into the window, 8 steps
    python3 tools/fig_text.py timing     docs/img/text/message-timing.png: queued, taken, ended in the recordings
    python3 tools/fig_text.py menu       docs/img/text/menu.png: the menu labelled (c1 frame 13950)
    python3 tools/fig_text.py progress   docs/img/text/progress.png: the ED picture, the pieces' numbers and flags
    python3 tools/fig_text.py all
"""
import argparse
import json
import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.patches  # noqa: E402
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
OUT = os.path.join(CASE, 'docs', 'img', 'text')
PLAY = os.path.join(CASE, 'docs', 'img', 'play')
EV = os.path.join(CASE, 'work', 'docs', 'tjD')
BASE = 0x60C0
IMG = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
FONT, EDPIECES, HUDGFX, HUDICONS, MENUFRAME, LOGO = 0xE002, 0xE1E2, 0x8BFD, 0x8C55, 0xBC02, 0x8DB2
MESSAGES, MENUTEXTS, PROGRESSTEXT = 0x63D2, 0x8D38, 0x9072
BG, TXT, DIM = (24, 24, 30), (235, 235, 220), (150, 150, 140)
ZX = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
ZXB = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]

plt.rcParams.update({'font.size': 11, 'axes.titlesize': 11, 'xtick.labelsize': 10, 'ytick.labelsize': 10, 'text.parse_math': False})

MSGS = [  # address, priority, name, queued by, witness
    (0x63D2, 'TUJAD FROM ORPHEUS', 'Restart $690A', 'menu-cursor 132'),
    (0x63E7, 'EDS COMPLETED', 'WinTest $69F3', 'RZX log 71 845'),
    (0x6422, 'WARNING ENERGY LOW', 'EnergyTick $7AC9', 'energy-out 643'),
    (0x6437, 'ENERGY SOURCE ABSORBED', 'MoveDroidPickupEnergy $7687', 'rzx-028000 317'),
    (0x645F, 'TRANSPORTING', 'Teleport $778B', 'rzx-030000 118'),
    (0x6474, 'WEAPON LOCATED AND STORED', 'MoveDroidPickupStored $766A', 'rzx-059000 27'),
    (0x649C, 'GEN 19 COLLECTED', 'MoveDroidPickupGen $7671', 'rzx-036000 123'),
    (0x64B1, 'GEN 19 DESTROYED', 'LoseLife $6A51', 'energy-out 1570'),
    (0x64C6, 'CONGRATULATIONS', 'WinTestRoom $6A10', 'win 16 (taken)'),
    (0x654D, 'COMPUTER MALFUNCTION', 'LoseLifeGameOver $6A94', 'game-over 434'),
]


def m(a):
    return IMG[a - BASE]


def font(size):
    for p in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def glyph(code):
    """8 bytes as PrintText reads them: Font - $100 + 8 x code"""
    a = FONT - 0x100 + 8 * code
    return [m(a + k) for k in range(8)]


def draw_glyph(px, x0, y0, rows, scale, ink, paper=None):
    for y, b in enumerate(rows):
        for bit in range(8):
            on = b & (0x80 >> bit)
            if on or paper is not None:
                for dy in range(scale):
                    for dx in range(scale):
                        px[x0 + bit * scale + dx, y0 + y * scale + dy] = ink if on else paper


def message_rows(addr):
    """the text after the priority byte, cut into rows of 19, up to the '.' after the last row"""
    text = []
    a = addr + 1
    while True:
        row = bytes(m(a + k) for k in range(19))
        text.append(row)
        a += 19
        if m(a) == 0x2E:
            return m(addr), text, a


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    im.save(path)
    print(os.path.relpath(path, CASE), im.size)


def savefig(fig, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=100)
    plt.close(fig)
    print(os.path.relpath(path, CASE))


# ------------------------------------------------------------------------------------------------ font

def used_codes():
    used = {}
    for addr, *_ in MSGS:
        _p, rows, _e = message_rows(addr)
        for r in rows:
            for c in r:
                used.setdefault(c, set()).add('M')
    for c in IMG[MENUTEXTS - BASE:0x8D85 - BASE]:
        if c != 0x2E or True:
            used.setdefault(c, set()).add('T')
    for c in IMG[PROGRESSTEXT - BASE:PROGRESSTEXT - BASE + 40]:
        if c == 0x2E:
            break
        used.setdefault(c, set()).add('P')
    for c in range(0x30, 0x3A):
        used.setdefault(c, set()).add('B')
    return used


def cmd_font(_a):
    scale, cw, ch, cols = 4, 64, 80, 16
    W, H = 1050, 70 + ch * 4 + 120
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    px = im.load()
    f, fs = font(15), font(13)
    d.text((14, 10), 'Font $E002-$E1E1: 60 characters, codes $20-$5B, 8 bytes each, top row first', fill=TXT, font=f)
    d.text((14, 32), 'PrintText and PrintBcd read Font - $100 + 8 x code; the scroller Font - $101 + 8 x code + ScrollLine',
           fill=DIM, font=fs)
    used = used_codes()
    x0 = (W - cols * cw) // 2
    for i, code in enumerate(range(0x20, 0x5C)):
        x, y = x0 + (i % cols) * cw, 62 + (i // cols) * ch
        u = used.get(code, set()) - ({'T'} if code == 0x2E else set())
        frame = (90, 160, 90) if u else (70, 70, 80)
        d.rectangle([x + 2, y + 2, x + cw - 3, y + ch - 3], outline=frame, width=2)
        draw_glyph(px, x + 16, y + 6, glyph(code), scale, (255, 255, 255), (0, 0, 0))
        tag = f'{code:02X} {chr(code)}'
        d.text((x + 8, y + 41), tag, fill=TXT if u else DIM, font=fs)
        if u:
            d.text((x + 8, y + 57), ''.join(sorted(u)), fill=(120, 210, 120), font=fs)
    yl = 62 + 4 * ch + 8
    lines = ['green frame: a code some text prints; the letters say which: M the messages, T the menu texts,',
             'P the progress line, B the HUD digits (PrintBcd); a grey frame: no text uses it (L1 reads 282 of 480 bytes)',
             '"." ($2E) ends every text and is never printed; a leading 0 of PrintBcd is the ROM font\'s space ($3D00)',
             '"[" ($5B) is a solid bottom row; "," and ";" have a tail in row 7, which the scroller never shows']
    for k, s in enumerate(lines):
        d.text((14, yl + 20 * k), s, fill=DIM, font=fs)
    save(im, 'font.png')


# ------------------------------------------------------------------------------------------------ hud

def cmd_hud(_a):
    shot = Image.open(os.path.join(PLAY, 'start-room.png')).convert('RGB')  # 512 x 384, two pixels a pixel
    top = shot.crop((0, 0, 512, 96)).resize((1024, 192), Image.NEAREST)
    fig = plt.figure(figsize=(10.5, 5.6))
    ax = fig.add_axes([0.055, 0.25, 0.935, 0.45])
    ax.imshow(top, extent=(0, 256, 48, 0), interpolation='nearest')
    ax.set_xlim(0, 256)
    ax.set_ylim(48, 0)
    ax.set_xticks(range(4, 256, 32))
    ax.set_xticklabels([f'col {c}' for c in range(0, 32, 4)], fontsize=10)
    ax.set_yticks(range(4, 48, 8))
    ax.set_yticklabels([f'row {r}' for r in range(6)], fontsize=10)
    for x in range(0, 257, 8):
        ax.axvline(x, color='white', lw=0.25, alpha=0.35)
    for y in range(0, 49, 8):
        ax.axhline(y, color='white', lw=0.25, alpha=0.35)
    marks = [  # x, y (pixels) of the arrow tip, label, text x, text y (figure fraction above / below)
        (20, 18, 'weapon icon: $4422,\nHudIcons + 32 x weapon\n(ShowWeapon, colour $47/$43/$44/$46)', 0.01, 0.96),
        (52, 18, 'GEN 19 icon $4425\n(DrawHud, the lives)', 0.21, 0.96),
        (76, 18, 'energy icon\n$4428 (DrawHud)', 0.355, 0.96),
        (92, 4, 'divider, col 11\n(HudDivider*)', 0.49, 0.96),
        (180, 16, 'the scroller\'s window: $402C, 19 bytes x 32 lines\n(rows 1-4, columns 12-30), colour $43,\nmoved by the interrupt (InterruptScroll)', 0.62, 0.96),
        (20, 36, 'ammo $4082: 2 BCD digits\n(PrintBcd; blank for weapon 0)', 0.01, 0.12),
        (52, 36, 'Lives $636D at $4085\n(PrintBcd, colour $45)', 0.22, 0.12),
        (76, 36, 'Energy $636E at $4088\n(PrintBcd, colour $42)', 0.42, 0.12),
        (250, 44, 'frame: HudGraphics $8BFD, 11 characters,\nrows 0 and 5, columns 0 and 31\n(DrawHud, colour 7)', 0.66, 0.12),
    ]
    for x, y, label, tx, ty in marks:
        fx, fy = fig.transFigure.inverted().transform(ax.transData.transform((x, y)))
        fig.text(tx, ty, label, fontsize=10, va='top' if ty > 0.5 else 'top', ha='left')
        fig.add_artist(matplotlib.lines.Line2D([tx + 0.03, fx], [ty - 0.135 if ty > 0.5 else ty + 0.01, fy],
                                               color='#d04040', lw=1.2, transform=fig.transFigure))
        ax.plot([x], [y], 'o', color='#d04040', ms=4)
    savefig(fig, 'hud.png')


# ------------------------------------------------------------------------------------------------ hudgfx

def blit(px, x0, y0, addr, wbytes, rows, scale, ink=(255, 255, 255), paper=(0, 0, 0)):
    for y in range(rows):
        for xb in range(wbytes):
            b = m(addr + y * wbytes + xb)
            for bit in range(8):
                on = b & (0x80 >> bit)
                for dy in range(scale):
                    for dx in range(scale):
                        px[x0 + (xb * 8 + bit) * scale + dx, y0 + y * scale + dy] = ink if on else paper


def cmd_hudgfx(_a):
    W, H = 1050, 680
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    px = im.load()
    f, fs = font(15), font(13)
    d.text((14, 8), 'HudGraphics $8BFD: the HUD frame, 11 characters of 8 x 8 (DrawHud $8AE8, through Print8 $8A79)',
           fill=TXT, font=f)
    names = ['top edge', 'bottom edge', 'left edge', 'right edge', 'corner TL', 'corner TR', 'corner BR', 'corner BL',
             'divider top', 'divider', 'divider bot.']
    for i, n in enumerate(names):
        x, y = 14 + i * 93, 36
        blit(px, x + 14, y, HUDGFX + 8 * i, 1, 8, 6)
        d.text((x, y + 54), f'${HUDGFX + 8 * i:04X}', fill=TXT, font=fs)
        d.text((x, y + 72), n, fill=DIM, font=fs)
    d.text((14, 140), 'HudIcons $8C55: seven 16 x 16 icons, 32 bytes each (ShowWeapon $79C2, DrawHud, DrawItem $6E0D)',
           fill=TXT, font=f)
    icons = [('weapon 0', '$47'), ('weapon 1', '$43'), ('weapon 2', '$44'), ('weapon 3', '$46'), ('GEN 19', '$45'),
             ('energy', '$42'), ('energy source', 'room item')]
    for i, (n, col) in enumerate(icons):
        x, y = 10 + i * 144, 168
        c = int(col[1:], 16) if col.startswith('$') else 0x47
        ink = ZXB[c & 7]
        blit(px, x + 22, y, HUDICONS + 32 * i, 2, 16, 5, ink=ink)
        d.text((x, y + 86), f'${HUDICONS + 32 * i:04X}  {n}', fill=TXT, font=fs)
        d.text((x, y + 104), f'colour {col}', fill=DIM, font=fs)
    d.text((14, 300), 'MenuFrame $BC02: eight 16 x 16 blocks (Menu $8854, Blit16 $8A93)', fill=TXT, font=f)
    frames = ['top edge', 'bottom edge', 'left edge', 'right edge', 'corner TL', 'corner TR', 'corner BL', 'corner BR']
    for i, n in enumerate(frames):
        x, y = 14 + i * 128, 328
        blit(px, x + 20, y, MENUFRAME + 32 * i, 2, 16, 4)
        d.text((x, y + 70), f'${MENUFRAME + 32 * i:04X}', fill=TXT, font=fs)
        d.text((x, y + 88), n, fill=DIM, font=fs)
    d.text((14, 440), 'MenuLogoGraphic $8DB2: the TUJAD logo\'s block, 16 rows of 2 bytes; MenuLogo $89E5 draws it three '
           'times', fill=TXT, font=f)
    d.text((14, 460), 'and its lower half ($8DC2) twice, then colours the 4 x 7 cells from MenuLogoAttrs', fill=TXT, font=f)
    blit(px, 30, 490, LOGO, 2, 16, 6)
    d.text((14, 592), '$8DB2 (upper half) / $8DC2 (lower half)', fill=DIM, font=fs)
    # the logo as MenuLogo leaves it on the screen: cropped from the menu screenshot (c1 frame 13950)
    shot = Image.open(os.path.join(PLAY, 'menu.png')).convert('RGB')
    logo = shot.crop((64, 48, 128, 160)).resize((96, 168), Image.NEAREST)
    im.paste(logo, (330, 496))
    for k, line in enumerate(['the logo as MenuLogo draws it at $4064 (c1 frame 13950):',
                              'the block at +1, +$60 and +$62 (16 rows), its lower half',
                              'at +$C0 and +$C2 (8 rows): three cubes; then the 4 x 7 cells',
                              'coloured from MenuLogoAttrs $8D96 (blue tops, red and',
                              'green sides on black)']):
        d.text((450, 516 + 18 * k), line, fill=DIM, font=fs)
    save(im, 'hud-graphics.png')


# ------------------------------------------------------------------------------------------------ messages

def cmd_messages(_a):
    scale = 2
    rowh = 8 * scale + 2
    f, fs = font(14), font(13)
    blocks = []
    for addr, name, by, wit in MSGS:
        p, rows, end = message_rows(addr)
        blocks.append((addr, p, rows, end, name, by, wit))
    H = 46 + sum(44 + len(b[2]) * rowh + 10 for b in blocks[:5])
    H2 = 46 + sum(44 + len(b[2]) * rowh + 10 for b in blocks[5:])
    W = 1050
    im = Image.new('RGB', (W, max(H, H2) + 10), BG)
    d = ImageDraw.Draw(im)
    px = im.load()
    d.text((14, 10), 'Messages $63D2-$65AD: a priority byte, rows of 19 characters, a "." after the last row', fill=TXT,
           font=font(15))
    for col, part in enumerate((blocks[:5], blocks[5:])):
        x0, y = 14 + col * 520, 44
        for addr, p, rows, end, name, by, wit in part:
            d.text((x0, y), f'${addr:04X}  priority {p}  {len(rows)} row{"s" if len(rows) > 1 else ""}, '
                            f'"." at ${end:04X}', fill=TXT, font=fs)
            d.text((x0, y + 18), f'{by}; seen: {wit}', fill=DIM, font=fs)
            y += 40
            for r in rows:
                d.rectangle([x0, y, x0 + 19 * 8 * scale + 3, y + rowh - 1], fill=(0, 0, 0))
                for k, c in enumerate(r):
                    draw_glyph(px, x0 + 2 + k * 8 * scale, y + 1, glyph(c)[:7] + [0], scale, ZXB[3])
                y += rowh
            y += 12
    save(im, 'messages.png')


# ------------------------------------------------------------------------------------------------ scroller

def scroll_sim(text_rows, steps):
    """InterruptScroll on a 19 x 32 window: each step moves the window up one line and writes the new bottom line,
    row ScrollLine - 1 of each glyph (Font - $101 + 8 x code + ScrollLine), ScrollLine counted 1..7, 0"""
    win = [[0] * 19 for _ in range(32)]
    line, ptr, row = 0, 0, 0
    out = []
    for s in range(steps):
        line = (line + 1) & 7
        win = win[1:] + [list(win[-1])]
        if row < len(text_rows):
            for k, c in enumerate(text_rows[row]):
                a = FONT - 0x101 + 8 * c + line
                win[31][k] = m(a)
            if line == 0:
                row += 1
        out.append([list(r) for r in win])
    return out


def cmd_scroller(_a):
    _p, rows, _e = message_rows(0x645F)  # TRANSPORTING
    states = scroll_sim(rows, 12)
    scale = 2
    W = 1050
    f, fs = font(15), font(13)
    im = Image.new('RGB', (W, 550), BG)
    d = ImageDraw.Draw(im)
    px = im.load()
    d.text((14, 8), 'InterruptScroll: one text row comes in, a pixel line a step (TRANSPORTING, as in rzx-030000 '
                    'frames 158-208)', fill=TXT, font=f)
    d.text((14, 30), 'the window $402C: 19 bytes x 32 lines; each step moves lines 1-31 up one and writes line 31 from '
                     'the glyphs', fill=DIM, font=fs)
    delays = [5, 5, 5, 5, 5, 5, 5, 15, 5, 5, 5, 5]
    t = 0
    for i, st in enumerate(states[:8] + [states[11]]):
        k = i if i < 8 else 11
        x0 = 14 + (i % 3) * 345
        y0 = 62 + (i // 3) * 150
        line = (k + 1) & 7
        src = 'byte before glyph' if line == 0 else f'glyph row {line - 1}'
        if k >= 8:
            src = 'no row left'
        d.text((x0, y0), f'step {k + 1}: ScrollLine {line}, {src}', fill=TXT, font=fs)
        d.rectangle([x0, y0 + 20, x0 + 19 * 8 * scale // 1 + 3, y0 + 20 + 32 * 2 * 1 + 3], fill=(0, 0, 0))
        for y, r in enumerate(st):
            for xb, b in enumerate(r):
                for bit in range(8):
                    if b & (0x80 >> bit):
                        X = x0 + 2 + (xb * 8 + bit) * scale
                        Y = y0 + 22 + y * 2
                        for dy in range(2):
                            for dx in range(scale):
                                px[X + dx, Y + dy] = ZXB[3]
        d.text((x0, y0 + 92), f'then wait {delays[k]} interrupts (ScrollDelay)', fill=DIM, font=fs)
    d.text((14, 550 - 44), 'Steps 1-7 draw glyph rows 0-6; step 8 (ScrollLine 0) draws the byte before the glyph '
                           '(row 7 of the previous code, blank).', fill=DIM, font=fs)
    d.text((14, 550 - 24), 'TRANSPORTING has one row: from step 9 the window scrolls on and line 31 keeps its last bytes.', fill=DIM, font=fs)
    save(im, 'scroller.png')


# ------------------------------------------------------------------------------------------------ timing

MSG_BY_ADDR = {a: n for a, n, *_ in MSGS}


def tk_next_queue(bars, i):
    """the frame of the next QueueMessage of the same recording (the one that replaced bar i)"""
    for b in bars[i + 1:]:
        if b[0] == bars[i][0] and b[2] is not None:
            return b[2]
    return bars[i][2] + 5


def cmd_timing(_a):
    recs = [('menu-cursor', 'menu-cursor'), ('r30', 'rzx-030000'), ('rzx-036000', 'rzx-036000'),
            ('rzx-028000', 'rzx-028000'), ('rzx-059000', 'rzx-059000'), ('energy-out', 'energy-out'),
            ('game-over', 'game-over'), ('win', 'win')]
    bars = []
    for key, label in recs:
        d = json.load(open(os.path.join(EV, f'{key}-events.json')))
        q, taken = {}, None
        for f, t, n, a, bc, de, hl, c in d['calls']:
            x = f + t / 69888
            if n == 'QueueMessage':
                bars.append([label, MSG_BY_ADDR.get(hl, hex(hl)), x, None, None])
            if n == 'ScrollSet' and hl and (hl - 1) in MSG_BY_ADDR:
                name = MSG_BY_ADDR[hl - 1]
                for b in reversed(bars):
                    if b[0] == label and b[1] == name and b[3] is None:
                        b[3] = x
                        break
                else:
                    bars.append([label, name, None, x, None])
            if n == 'ScrollEnd' and a == 0x2E:
                for b in reversed(bars):
                    if b[0] == label and b[3] is not None and b[4] is None:
                        b[4] = x
                        break
        last = d['frames'][1]
        for b in bars:
            if b[0] == label and b[3] is not None and b[4] is None:
                b[4] = -last  # still scrolling at the end
    fig, ax = plt.subplots(figsize=(10.5, 5.2))
    for i, (label, name, q, tk, end) in enumerate(bars):
        y = len(bars) - 1 - i
        base = q if q is not None else tk
        if q is not None and tk is not None:
            ax.barh(y, tk - q, left=0, color='#e0a040', height=0.55)
        if tk is not None:
            e = abs(end) if end else tk
            ax.barh(y, e - tk, left=(tk - base), color='#8060c0', height=0.55,
                    hatch='//' if end and end < 0 else None)
        status = ''
        if q is not None and tk is None:
            ax.barh(y, tk_next_queue(bars, i) - q, left=0, color='#c04040', height=0.55)
            ax.text(tk_next_queue(bars, i) - q + 4, y, 'never shown: replaced by a higher priority', va='center',
                    fontsize=10, color='#c04040')
        if q is None:
            status = '  (queued before the recording)'
        info = f'{label} {int(base)}: {name}{status}'
        ax.text(-3, y, info, ha='right', va='center', fontsize=10)
    ax.set_yticks([])
    ax.set_xlim(-430, 380)
    ax.set_xticks(range(0, 381, 50))
    ax.set_xlabel('frames from the QueueMessage call (orange: waiting; purple: scrolling until the "." row; '
                  'hatched: still running\nat the end; red: queued, then replaced while waiting)', fontsize=10)
    ax.axvline(0, color='k', lw=0.8)
    ax.grid(alpha=0.3, axis='x')
    ax.set_title('Every message of the traced recordings: queued, taken by the scroller at a row boundary, ended')
    fig.tight_layout()
    savefig(fig, 'message-timing.png')


# ------------------------------------------------------------------------------------------------ menu

def cmd_menu(_a):
    shot = Image.open(os.path.join(PLAY, 'menu.png')).convert('RGB')
    fig = plt.figure(figsize=(10.5, 6.6))
    ax = fig.add_axes([0.01, 0.02, 0.56, 0.93])
    ax.imshow(shot, extent=(0, 256, 192, 0), interpolation='nearest')
    ax.set_xticks([])
    ax.set_yticks([])
    labels = [
        (104, 52, 'MenuTexts $8D38 "TUJAD." at $40CD\n(row 6, col 13), colour $47'),
        (52, 100, 'MenuTextKeyboard $8D3E at $4886\n(row 12, col 6), $43; lit: $C3 (FLASH)'),
        (52, 116, 'MenuTextCursor $8D4B at $48C6\n(row 14, col 6), $45; lit: $C5'),
        (52, 132, 'MenuTextKempston $8D5F at $5006\n(row 16, col 6), $46; lit: $C6'),
        (52, 156, 'MenuTextStart $8D75 at $5066\n(row 19, col 6), colour $07'),
        (208, 50, 'MenuLogo $89E5 twice: at $4064\nand $4078, 4 x 7 cells each'),
        (250, 160, 'the frame: MenuFrame $BC02, 16 x 16\nblocks round the screen (Blit16)'),
    ]
    for i, (x, y, text) in enumerate(labels):
        ty = 0.94 - i * 0.135
        fig.text(0.6, ty, text, fontsize=10.5, va='top')
        fig.add_artist(matplotlib.patches.ConnectionPatch(xyA=(0.597, ty - 0.02), coordsA=fig.transFigure,
                                                          xyB=(x, y), coordsB=ax.transData, color='#d04040',
                                                          lw=1.1))
        ax.plot([x], [y], 'o', color='#d04040', ms=4)
    savefig(fig, 'menu.png')


# ------------------------------------------------------------------------------------------------ progress

def cmd_progress(_a):
    scale = 3
    W, H = 1050, 470
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    px = im.load()
    f, fs = font(15), font(12)
    d.text((14, 8), 'EdPieces $E1E2: the ED circuit, 10 x 5 tiles of 16 x 16 (32 bytes each, tile = row x 10 + column)',
           fill=TXT, font=f)
    d.text((14, 28), 'each tile: piece n, EdFlags $6681 + (n - 1) / 5, bit (n - 1) mod 5; ProgressScreen draws a taken '
                     'one at $4886 + 2 x column + 64 x row', fill=DIM, font=fs)
    x0, y0 = 14, 56
    for row in range(5):
        for col in range(10):
            tile = row * 10 + col
            a = EDPIECES + 32 * tile
            X, Y = x0 + col * (16 * scale + 52), y0 + row * (16 * scale + 30)
            blit(px, X, Y, a, 2, 16, scale, ink=(255, 255, 255), paper=(0, 140, 0))
            n = col * 5 + row + 1
            d.text((X + 16 * scale + 3, Y), f'n {n}', fill=TXT, font=fs)
            d.text((X + 16 * scale + 3, Y + 15), f'{(n - 1) // 5}.{(n - 1) % 5}', fill=DIM, font=fs)
            d.text((X, Y + 16 * scale + 1), f'${a:04X}', fill=DIM, font=fs)
    d.text((14, H - 22), 'under each tile its address; beside it the piece number n and "byte.bit" of EdFlags. '
                         'A piece n lies in a room as item kind $81 + n.', fill=DIM, font=fs)
    save(im, 'progress.png')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    cmds = {'font': cmd_font, 'hud': cmd_hud, 'hudgfx': cmd_hudgfx, 'messages': cmd_messages,
            'scroller': cmd_scroller, 'timing': cmd_timing, 'menu': cmd_menu, 'progress': cmd_progress}
    p.add_argument('what', choices=list(cmds) + ['all'])
    a = p.parse_args()
    for k in (cmds if a.what == 'all' else [a.what]):
        cmds[k](a)


if __name__ == '__main__':
    main()
