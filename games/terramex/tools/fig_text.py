#!/usr/bin/env python3
"""The figures of doc 08 (HUD and text), modelled from the bytes of the build and the ROM font.

    python3 tools/fig_text.py font  --out docs/img/text/font.png
    python3 tools/fig_text.py menu  --out docs/img/text/menu-model.png     the menu texts by the PrintString model
    python3 tools/fig_text.py help  --out docs/img/text/help-model.png     the five Help pages by the PrintPage model
    python3 tools/fig_text.py panel --out docs/img/text/panel.png          the panel with its fields and addresses
    python3 tools/fig_text.py score --out docs/img/text/score-cases.png    PrintNumber and PrintByte on chosen values
    python3 tools/fig_text.py check                                        the models against the screenshots

The models are Python copies of PrintChar `$90C6`, PrintString `$94F9`, PrintPage `$C574` (with PrintGlyph `$C4BB`),
PrintNumber `$BD78` and PrintByte `$90E1`. They read the texts from build/game.bin (`$7200`) and build/select.bin
(`$C000`) and the font from the 128 ROM's second half (the 48 BASIC ROM, paged in during play: `$3C00` + 8 x code).
"""
import argparse
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, HERE)
from sound_sim import rom1  # noqa: E402

GAME = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
SELECT = open(os.path.join(CASE, 'build', 'select.bin'), 'rb').read()
ROM = rom1()

TEXTS = {  # name: (image, address, bytes)
    'MenuText': ('game', 0x9540, 57), 'CreditsText': ('game', 0x9579, 132), 'CollisionText': ('game', 0xB07C, 58),
    'Help48KText': ('select', 0xC5F9, 271), 'HelpTitle': ('select', 0xC708, 25), 'HelpPage1': ('select', 0xC721, 606),
    'HelpPage2': ('select', 0xC97F, 510), 'HelpPage3': ('select', 0xCB7D, 530)}


def text(name):
    img, a, n = TEXTS[name]
    return GAME[a - 0x7200:a - 0x7200 + n] if img == 'game' else SELECT[a - 0xC000:a - 0xC000 + n]


def glyph(code):
    a = 0x3C00 + 8 * (code & 0xFF)
    return ROM[a:a + 8]


PAL = [(0, 0, 0), (0, 0, 0xCD), (0xCD, 0, 0), (0xCD, 0, 0xCD), (0, 0xCD, 0), (0, 0xCD, 0xCD), (0xCD, 0xCD, 0),
       (0xCD, 0xCD, 0xCD)]
PALB = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0),
        (0xFF, 0xFF, 0xFF)]


class Screen:
    """6912 bytes of a Spectrum screen at `$4000`"""

    def __init__(self, attr=0x38):
        self.m = bytearray(6144) + bytearray([attr]) * 768

    def poke(self, addr, v):
        self.m[addr - 0x4000] = v & 0xFF

    def print_char(self, code, hl):
        """PrintChar `$90C6` / PrintGlyph `$C4BB`: 8 font bytes down the cell (INC D); returns HL + 1"""
        for k, b in enumerate(glyph(code)):
            self.poke(hl + 256 * k, b)
        return hl + 1

    def image(self, scale=1):
        im = Image.new('RGB', (256, 192))
        px = im.load()
        for y in range(192):
            base = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
            for cx in range(32):
                b = self.m[base + cx - 0x4000]
                at = self.m[6144 + (y >> 3) * 32 + cx]
                pal = PALB if at & 0x40 else PAL
                ink, paper = pal[at & 7], pal[(at >> 3) & 7]
                for bit in range(8):
                    px[cx * 8 + bit, y] = ink if b & (0x80 >> bit) else paper
        return im.resize((256 * scale, 192 * scale), Image.NEAREST) if scale > 1 else im


def cell(row, col):
    return 0x4000 | ((row & 0x18) << 8) | ((row & 7) << 5) | col


def screen_to_attr(hl):
    """ScreenToAttr `$9536`: H = `$58` + the third, L kept"""
    return ((0x58 | ((hl >> 11) & 3)) << 8) | (hl & 0xFF)


def print_string(scr, data, hl, attr):
    """PrintString `$94F9`: 0 ends, `$0D` the next character row under the line start (self-modified `$9517`)"""
    start = hl
    for c in data:
        if c == 0:
            return hl
        if c == 0x0D:
            lo = (start & 0xFF) + 0x20
            start = (start & 0xFF00) | (lo & 0xFF)
            if lo > 0xFF:
                start += 0x0800
            hl = start
            continue
        scr.print_char(c, hl)
        scr.m[screen_to_attr(hl) - 0x4000] = attr
        hl = (hl & 0xFF00) | ((hl + 1) & 0xFF)  # INC L
    return hl


def print_page(scr, data):
    """PrintPage `$C574`: CLS to attribute `$0F`; `$16` c r, `$0D`, `$01` pause and return, `$00` wait and return"""
    scr.m[:6144] = bytearray(6144)
    scr.m[6144:] = bytearray([0x0F]) * 768
    i, b, c = 0, 0, 0
    while i < len(data):
        a = data[i]
        i += 1
        if a == 0x16:
            c, b = data[i], data[i + 1]
            i += 2
        elif a in (0x01, 0x00):
            return a, i
        elif a == 0x0D:
            b, c = b + 1, 0
        else:
            hl = ((b & 0x18) | 0x40) << 8 | (((b << 5) & 0xE0) | c)
            scr.print_char(a, hl)
            c += 1
            if c == 0x20:
                c, b = 0, b + 1
    return None, i


def print_number(value):
    """PrintNumber `$BD78` on a 32-bit value: the four characters it prints after its four spaces"""
    n = value & 0xFFFFFFFF
    if n & 0x80000000:  # NegateNumber `$BCDE`: CPL the 4 bytes, + 1; no minus sign is printed
        n = (~n + 1) & 0xFFFFFFFF
    out, shown = [], 0
    for k, pv in enumerate((1000, 100, 10, 1)):
        c = 0
        while n >= pv:  # DivideNumber `$BDDF`: subtract until a borrow, C counts (8 bits)
            n -= pv
            c = (c + 1) & 0xFF
        if shown or c:
            shown = shown or c
            out.append((0x30 + c) & 0xFF)
        elif k == 3:
            out.append(0x30)  # PrintNumberZero: the last digit always prints
    return out


def print_byte(a):
    """PrintByte `$90E1`: three cells, digits first, a space for each leading zero"""
    h, t, u = a // 100, a // 10 % 10, a % 10
    digits = [0x30 + h, 0x30 + t, 0x30 + u]
    lead = 2 if h == 0 and t == 0 else (1 if h == 0 else 0)
    return digits[lead:] + [0x20] * lead


def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'axes.titlesize': 12, 'figure.dpi': 100, 'text.parse_math': False})
    return plt


def strip(codes, attr=0x38):
    """a row of cells as an image"""
    s = Screen(attr)
    hl = 0x4000
    for c in codes:
        hl = s.print_char(c, hl)
    return s.image().crop((0, 0, 8 * len(codes), 8))


# ---------------------------------------------------------------------------------------------------------------

def cmd_font(args):
    import numpy as np
    plt = plt_setup()
    fig, ax = plt.subplots(figsize=(10.5, 4.9))
    img = np.full((6 * 12, 16 * 12), 0.0)
    for code in range(0x20, 0x80):
        r, c = (code - 0x20) // 16, (code - 0x20) % 16
        for y, b in enumerate(glyph(code)):
            for x in range(8):
                img[r * 12 + 2 + y, c * 12 + 2 + x] = 1.0 if b & (0x80 >> x) else 0.15
    ax.imshow(img, cmap='gray', vmin=0, vmax=1, interpolation='nearest')
    ax.set_xticks([c * 12 + 5.5 for c in range(16)])
    ax.set_xticklabels(['+%X' % c for c in range(16)])
    ax.set_yticks([r * 12 + 5.5 for r in range(6)])
    ax.set_yticklabels(['$%02X' % (0x20 + 16 * r) for r in range(6)])
    ax.tick_params(length=0)
    ax.set_title('The font every game print uses: the 48 BASIC ROM at $3C00 + 8 x code (codes $20-$7F; $7F the\n'
                 'copyright sign of the credits). PrintChar $90C6 and the selector\'s PrintGlyph $C4BB copy these bytes',
                 fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def menu_screen(device=2):
    scr = Screen(0x44)
    print_string(scr, text('MenuText'), cell(8, 8), 0x44)
    print_string(scr, text('CreditsText'), cell(17, 2), 0x47)
    for a in range(0x5908, 0x5908 + 5 * 32, 32):  # MenuLoop: the box $43, the chosen row $47 (row 8 + 2 x device)
        for k in range(14):
            scr.m[a + k - 0x4000] = 0x43
    for k in range(14):
        scr.m[0x5908 + 64 * device + k - 0x4000] = 0x47
    return scr


def telescope_screen(days=30, hours=23, minutes=11):
    scr = Screen(0x00)
    print_string(scr, text('CollisionText'), 0x48A2, 0x0F)
    for v, at in ((days, 0x48C7), (hours, 0x48D0), (minutes, 0x48DB)):
        hl = at
        for ch in print_byte(v):
            hl = scr.print_char(ch, hl)
    return scr


def cmd_menu(args):
    plt = plt_setup()
    shot = Image.open(os.path.join(CASE, 'docs', 'img', 'play', 'menu.png')).convert('RGB')
    model = menu_screen().image(2)
    tel = telescope_screen().image(2)
    fig, axes = plt.subplots(1, 3, figsize=(10.5, 3.6))
    for ax, im, t in ((axes[0], model, 'the model: MenuText at row 8, column 8,\nCreditsText at row 17, column 2; Sinclair chosen'),
                      (axes[1], shot, 'the screen: explorers frame 7750\n(docs/img/play/menu.png)'),
                      (axes[2], tel, 'the model: CollisionText at $48A2 and\n30 days 23 h 11 min (never on screen)')):
        ax.imshow(im, interpolation='nearest')
        ax.set_title(t, fontsize=10)
        ax.axis('off')
    fig.suptitle('PrintString $94F9 modelled from the bytes, against the device menu as the recording shows it', fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def help_screens():
    out = []
    for name in ('Help48KText', 'HelpTitle', 'HelpPage1', 'HelpPage2', 'HelpPage3'):
        scr = Screen()
        end, used = print_page(scr, text(name))
        out.append((name, scr, end, used))
    return out


def cmd_help(args):
    plt = plt_setup()
    pages = help_screens()
    fig, axes = plt.subplots(2, 3, figsize=(10.5, 6.6))
    ends = {0: '$00: wait for SPACE / ENTER', 1: '$01: a 10.2 M T pause'}
    for ax, (name, scr, end, used) in zip(axes.flat, pages):
        ax.imshow(scr.image(), interpolation='nearest')
        img, a, n = TEXTS[name]
        ax.set_title('%s $%04X, %d bytes\nends on %s' % (name, a, n, ends.get(end, '?')), fontsize=10)
        ax.axis('off')
    shot = Image.open(os.path.join(CASE, 'docs', 'img', 'play', 'help-2.png')).convert('RGB')
    axes.flat[5].imshow(shot, interpolation='nearest')
    axes.flat[5].set_title('the screen: explorers frame 14 000, page 3\n(docs/img/play/help-2.png)', fontsize=10)
    axes.flat[5].axis('off')
    fig.suptitle('The selector\'s Help pages as PrintPage $C574 draws them, modelled from select.bin; '
                 'the last panel is the recording', fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


PANEL_FIELDS = [  # (label, row, col, rows, cols, colour, where the text goes)
    ('Score $5C18: PrintScore $BD75 at $5029', 17, 9, 1, 4, 'tab:red', 'top'),
    ('HiScore $5B78: PrintHiScore $BD3B at $5049', 18, 9, 1, 4, 'tab:orange', 'bottom'),
    ('spare lives: DrawSpareLives $9E96 at $5081', 20, 1, 3, 9, 'tab:green', 'bottom'),
    ('held item $5B98 at $5032', 17, 18, 3, 3, 'tab:purple', 'top'),
    ('portrait (frame 9) at $5092', 20, 18, 3, 3, 'tab:blue', 'bottom'),
    ('BearerLoads $5B7C: DrawBearerItems at $5036', 17, 22, 3, 9, 'tab:cyan', 'top'),
    ('bearers: DrawBearers $9EBD at $5096', 20, 22, 3, 9, 'tab:olive', 'bottom'),
]


def cmd_panel(args):
    plt = plt_setup()
    import matplotlib.patches as mp
    shot = Image.open(os.path.join(CASE, args.shot)).convert('RGB').resize((256, 192), Image.NEAREST)
    third = shot.crop((0, 128, 256, 192))
    fig, ax = plt.subplots(figsize=(10.5, 5.4))
    ax.imshow(third, extent=(0, 32, 24, 16), interpolation='nearest')
    ax.set_xlim(-0.5, 32.5)
    ax.set_ylim(27.6, 12.2)
    tops = bottoms = 0
    for label, row, col, rows, cols, colour, where in PANEL_FIELDS:
        ax.add_patch(mp.Rectangle((col, row), cols, rows, fill=False, ec=colour, lw=2.2))
        if where == 'top':
            y = 15.6 - 1.0 * (tops % 2)
            tops += 1
            ax.annotate(label, (col + cols / 2, row), (col + cols / 2, y), ha='center', va='bottom', fontsize=10,
                        color=colour, arrowprops=dict(arrowstyle='-', color=colour, lw=1))
        else:
            y = 24.5 + 1.1 * (bottoms % 3)
            bottoms += 1
            ax.annotate(label, (col + cols / 2, row + rows), (col + cols / 2, y), ha='center', va='top', fontsize=10,
                        color=colour, arrowprops=dict(arrowstyle='-', color=colour, lw=1))
    ax.set_xticks(range(0, 33, 4))
    ax.set_yticks(range(16, 25, 2))
    ax.set_xlabel('screen column')
    ax.set_ylabel('screen row')
    ax.set_title('The panel, screen rows 16-23 (%s): the boxes are the fields the code writes;\n'
                 'the rest (SCORE, HISCORE, the frames, the tree) is the panel picture InitGame $8F69 copies from $E000'
                 % args.label, fontsize=11)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


SCORE_CASES = [(0, 'InitGame $8F69 at $8FCC: AddScore with DE = 0'), (50, 'one pickup, +50 ($BBE9)'),
               (2300, 'the RZX run\'s final score'), (9999, 'the largest four-digit score'),
               (10000, 'thousands = 10: the character after 9'), (12345, 'thousands = 12'),
               (256000, 'thousands = 256 wraps C to 0'), (-50, 'a negative score: no minus sign')]


def cmd_score(args):
    plt = plt_setup()
    n = len(SCORE_CASES)
    fig, axes = plt.subplots(n + 1, 3, figsize=(10.5, 0.62 * (n + 3)), gridspec_kw={'width_ratios': [2.3, 1.2, 4]})
    for ax, t in zip(axes[0], ('Score $5C18 (bytes low first)', 'printed at $5029', 'why')):
        ax.axis('off')
        ax.text(0, 0.2, t, fontsize=11, weight='bold')
    for row, (v, why) in enumerate(SCORE_CASES, start=1):
        b = (v & 0xFFFFFFFF).to_bytes(4, 'little')
        axes[row][0].axis('off')
        axes[row][0].text(0, 0.5, '%d  =  %s' % (v, ' '.join('%02X' % x for x in b)), fontsize=11, va='center',
                          family='monospace')
        codes = [0x20] * 4
        for k, c in enumerate(print_number(v)):
            codes[k] = c
        axes[row][1].imshow(strip(codes), interpolation='nearest', extent=(0, 32, 0, 8))
        axes[row][1].set_xticks([])
        axes[row][1].set_yticks([])
        axes[row][2].axis('off')
        axes[row][2].text(0, 0.5, why + '; codes ' + ' '.join('$%02X' % c for c in print_number(v)), fontsize=11,
                          va='center')
    fig.suptitle('PrintNumber $BD78 modelled on chosen values: four cells blanked, the digits left-aligned, '
                 'no leading zeros,\nno sign; the quotient by 1000 is printed as $30 + q, so 10 and up leave the digits',
                 fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_check(args):
    """the menu and Help models against the screenshots, cell by cell (ink pixels only)"""
    def ink_mask(im):
        px = im.load()
        return [[sum(px[x, y]) for x in range(im.width)] for y in range(im.height)]

    def compare(model, shot, cells):
        same = diff = 0
        mp, sp = model.load(), shot.load()
        for (r, c) in cells:
            for y in range(r * 8, r * 8 + 8):
                for x in range(c * 8, c * 8 + 8):
                    if mp[x, y] == sp[x, y]:
                        same += 1
                    else:
                        diff += 1
        return same, diff

    shot = Image.open(os.path.join(CASE, 'docs', 'img', 'play', 'menu.png')).convert('RGB').resize((256, 192),
                                                                                                      Image.NEAREST)
    cells = [(r, c) for r in (8, 10, 12, 14) for c in range(8, 22)] + [(r, c) for r in range(17, 22)
                                                                       for c in range(2, 30)]
    print('menu text cells: same %d, different %d pixels' % compare(menu_screen().image(), shot, cells))
    pages = {p[0]: p[1] for p in help_screens()}
    for name, f in (('HelpTitle', 'help-1.png'), ('HelpPage3', 'help-2.png'), ('HelpPage1', 'help-3.png')):
        shot = Image.open(os.path.join(CASE, 'docs', 'img', 'play', f)).convert('RGB').resize((256, 192), Image.NEAREST)
        allc = [(r, c) for r in range(24) for c in range(32)]
        print('%s vs %s: same %d, different %d pixels' % ((name, f) + compare(pages[name].image(), shot, allc)))
    for v, _ in SCORE_CASES:
        print(v, ''.join(chr(c) if 32 <= c < 127 else '\\x%02X' % c for c in print_number(v)))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    for name in ('font', 'menu', 'help', 'score'):
        s = sub.add_parser(name)
        s.add_argument('--out', required=True)
    s = sub.add_parser('panel')
    s.add_argument('--out', required=True)
    s.add_argument('--shot', default='docs/img/play/start-room-14.png')
    s.add_argument('--label', default='explorers frame 750, the start room')
    sub.add_parser('check')
    a = p.parse_args()
    {'font': cmd_font, 'menu': cmd_menu, 'help': cmd_help, 'panel': cmd_panel, 'score': cmd_score,
     'check': cmd_check}[a.cmd](a)


if __name__ == '__main__':
    main()
