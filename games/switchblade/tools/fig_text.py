#!/usr/bin/env python3
"""The figures of doc 08 (the text, the panel, the high scores), from the game's own code and bytes.

The print routines run in SkoolKit's simulator on build/game.bin (tools/sound_sim.Machine('48')): the pictures are
what the game's code writes into the screen, not a redrawing of it. The screen shots come from recordings
(work/docs/zsD/shots, taken with R/kit/screen_shot.py; the command is in each figure's caption in doc 08).

  python3 tools/fig_text.py font     docs/img/text/font.png
  python3 tools/fig_text.py tall     docs/img/text/tall.png
  python3 tools/fig_text.py meter    docs/img/text/meter.png
  python3 tools/fig_text.py weapon   docs/img/text/weapon.png
  python3 tools/fig_text.py blade    docs/img/text/blade.png
  python3 tools/fig_text.py panel    docs/img/text/panel.png  --shot work/docs/zsD/shots/s2050.png
  python3 tools/fig_text.py screens  docs/img/text/screens.png --shots A.png:title B.png:title ...
"""
import argparse
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sound_sim as S  # noqa: E402

G = S.G
FONT = G['Font']
BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0),
          (255, 255, 255)]
NORMAL = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215), (0, 215, 0), (0, 215, 215), (215, 215, 0),
          (215, 215, 215)]


def plt_setup():
    return S.plt_setup()


def machine():
    m = S.Machine('48')
    m.mem[0x4000:0x5B00] = bytes(0x1B00)
    # NewGame copies the score line and the status line ($5C15, 35 bytes) to ScoreLine $6657
    m.mem[G['ScoreLine']:G['ScoreLine'] + 35] = m.mem[0x5C15:0x5C15 + 35]
    return m


def screen_rgb(mem, col0=0, row0=0, cols=32, rows=24):
    """the Spectrum screen at $4000 as an RGB array, the cells col0.., row0.. (attributes with BRIGHT and FLASH off)"""
    img = np.zeros((rows * 8, cols * 8, 3), np.uint8)
    for r in range(rows):
        for c in range(cols):
            a = mem[0x5800 + (row0 + r) * 32 + col0 + c]
            pal = BRIGHT if a & 0x40 else NORMAL
            ink, paper = pal[a & 7], pal[(a >> 3) & 7]
            for y in range(8):
                py = (row0 + r) * 8 + y
                addr = 0x4000 | ((py & 0xC0) << 5) | ((py & 7) << 8) | ((py & 0x38) << 2) | (col0 + c)
                b = mem[addr]
                for x in range(8):
                    img[r * 8 + y, c * 8 + x] = ink if b & (0x80 >> x) else paper
    return img


def glyph(mem, code):
    a = FONT + (code - 0x20) * 8
    return [mem[a + i] for i in range(8)]


def cmd_font(args):
    plt = plt_setup()
    m = machine()
    per = 16
    codes = list(range(0x20, 0x87))
    rows = (len(codes) + per - 1) // per
    fig, axes = plt.subplots(rows, per, figsize=(10.5, 0.98 * rows + 0.6))
    for i, ax in enumerate(axes.flat):
        ax.set_xticks([])
        ax.set_yticks([])
        if i >= len(codes):
            ax.axis('off')
            continue
        code = codes[i]
        g = glyph(m.mem, code)
        arr = np.array([[1 if b & (0x80 >> x) else 0 for x in range(8)] for b in g])
        ax.imshow(arr, cmap='Greys', vmin=0, vmax=1, interpolation='nearest')
        ch = chr(code) if 0x21 <= code < 0x7F else ''
        ax.set_title('$%02X %s' % (code, ch), fontsize=10, pad=2)
        for s in ax.spines.values():
            s.set_color('#bbbbbb')
    fig.suptitle('Font $7BE5: the 103 glyphs, codes $20-$86, as PrintString draws them (8 x 8, ink black)',
                 fontsize=12)
    fig.subplots_adjust(left=0.01, right=0.99, top=0.93, bottom=0.01, wspace=0.15, hspace=0.45)
    fig.savefig(args.out, dpi=100)
    print('wrote', args.out)


def print_record(m, routine, y, x, text, a_low=0x47, a_cell=0x47):
    rec = bytes([y, x, a_low, a_cell]) + text.encode('latin-1') + b'\x00'
    base = 0x5B00
    m.mem[base:base + len(rec)] = rec
    su = m.su
    m.sim.registers[su.H], m.sim.registers[su.L] = base >> 8, base & 255
    return m.call(G[routine])


def cmd_tall(args):
    plt = plt_setup()
    cases = [('PrintString', 0x10, 'Y $10 (in a cell)'), ('PrintStringTall', 0x10, 'Y $10, tall'),
             ('PrintString', 0x13, 'Y $13 (3 lines into a cell)'), ('PrintStringTall', 0x13, 'Y $13, tall')]
    fig, axes = plt.subplots(1, 4, figsize=(10.5, 3.6))
    for ax, (routine, y, title) in zip(axes, cases):
        m = machine()
        t = print_record(m, routine, y, 4, 'AB8')
        img = screen_rgb(m.mem, 2, 1, 3, 3)
        ax.imshow(img, interpolation='nearest')
        for k in range(1, 3):
            ax.axhline(k * 8 - 0.5, color='#ff8800', lw=1)
            ax.axvline(k * 8 - 0.5, color='#ff8800', lw=1)
        top = y - 8
        ax.axhline(top - 0.5, color='#00aa00', lw=1.5, ls='--')
        ax.set_title('%s\n%s, %d T' % (routine, title, t), fontsize=10)
        ax.set_xticks([])
        ax.set_yticks(range(0, 24, 4))
        ax.set_yticklabels(['%d' % (8 + v) for v in range(0, 24, 4)], fontsize=10)
    axes[0].set_ylabel('pixel line')
    fig.suptitle('"AB8" printed at X 4 (column 2): one glyph row drawn twice in the tall mode', fontsize=12)
    fig.subplots_adjust(left=0.06, right=0.99, top=0.78, bottom=0.03, wspace=0.25)
    fig.savefig(args.out, dpi=100)
    print('wrote', args.out)


def cmd_meter(args):
    plt = plt_setup()
    values = [0x20, 0x1F, 0x1E, 0x1D, 0x1C, 0x10, 0x05, 0x01, 0x00]
    fig = plt.figure(figsize=(10.5, 0.62 * len(values) + 0.8))
    gs = fig.add_gridspec(len(values), 2, width_ratios=[1, 2.2], left=0.11, right=0.995, top=0.9, bottom=0.01,
                          hspace=0.35, wspace=0.03)
    for k, v in enumerate(values):
        ax = fig.add_subplot(gs[k, 0])
        tx = fig.add_subplot(gs[k, 1])
        tx.axis('off')
        m = machine()
        m.mem[0x5AE0:0x5B00] = m.mem[G['PanelAttrs']:G['PanelAttrs'] + 32]
        su = m.su
        reg = m.sim.registers
        reg[su.H], reg[su.L] = 0x5B, 0x80
        reg[su.D], reg[su.E] = 0x50, 0xE0
        t = m.call(G['DrawMeter'], a=v)
        part = m.mem[G['MeterPartial']]
        if v == 0x20:
            win = 0xBB
        elif v == 0:
            win = 0xC3
        else:
            win = 0xC2 - v // 4
        img = screen_rgb(m.mem, 0, 23, 8, 1)[0:6]
        ax.imshow(img, interpolation='nearest', aspect='auto', extent=(0, 64, 6, 0))
        ax.set_yticks([])
        ax.set_xticks([])
        for sp in ax.spines.values():
            sp.set_color('black')
            sp.set_linewidth(2)
        ax.set_ylabel('$%02X (%d)' % (v, v), rotation=0, ha='right', va='center', fontsize=10,
                      family='monospace')
        bytes8 = ' '.join('%02X' % m.mem[0xFF00 + win + i] for i in range(8))
        tx.text(0.01, 0.5, 'window $FF%02X: %s  partial %s  %d T' % (
            win, bytes8, ('$%02X' % part) if 0 < v < 0x20 else '-  ', t), va='center', fontsize=10,
            family='monospace', transform=tx.transAxes)
    fig.suptitle('DrawMeter on the vitality meter (row 23, columns 0-7): A, the picture, the 8-byte window',
                 fontsize=12)
    fig.savefig(args.out, dpi=100)
    print('wrote', args.out)


def cmd_weapon(args):
    plt = plt_setup()
    counts = [0, 1, 2, 3, 8, 9, 12, 16]
    fig, axes = plt.subplots(2, 4, figsize=(10.5, 4.6))
    for ax, n in zip(axes.flat, counts):
        m = machine()
        m.mem[0x5AE0:0x5B00] = m.mem[G['PanelAttrs']:G['PanelAttrs'] + 32]
        t = m.call(G['PanelWeaponBar'], a=n)
        img = screen_rgb(m.mem, 14, 23, 4, 1)
        ax.imshow(img, interpolation='nearest')
        ax.set_xticks([4, 12, 20, 28])
        ax.set_xticklabels(['$85', 'icon', '', '$86'], fontsize=10)
        ax.set_yticks([])
        ax.set_title('%d left, %d T' % (n, t), fontsize=10)
    fig.suptitle('PanelWeapon: the bar in glyphs $85 and $86 either side of the weapon icon (row 23, columns 14-17)',
                 fontsize=12)
    fig.subplots_adjust(left=0.01, right=0.99, top=0.86, bottom=0.07, wspace=0.12, hspace=0.45)
    fig.savefig(args.out, dpi=100)
    print('wrote', args.out)


def cmd_blade(args):
    plt = plt_setup()
    fig, axes = plt.subplots(4, 4, figsize=(10.5, 3.8))
    for n, ax in zip(range(1, 17), axes.flat):
        m = machine()
        for i in range(32):
            m.mem[0x5800 + i] = 0x47
        m.mem[G['Fragments']] = n
        m.mem[G['FragmentsShown']] = 0
        t = m.call(G['PanelFragments'])
        img = screen_rgb(m.mem, 26, 0, 6, 1)
        ax.imshow(img, interpolation='nearest')
        codes = ' '.join('%02X' % m.mem[G['FirebladeGlyphs'] + i] for i in range(6))
        ax.set_title('%d: %s' % (n, codes), fontsize=10, family='monospace')
        ax.set_xticks([])
        ax.set_yticks([])
    fig.suptitle('PanelFragments: the Fireblade at columns 26-31 of row 0 for 1-16 fragments (the six codes)',
                 fontsize=12)
    fig.subplots_adjust(left=0.01, right=0.99, top=0.85, bottom=0.01, wspace=0.1, hspace=0.6)
    fig.savefig(args.out, dpi=100)
    print('wrote', args.out)


def cmd_panel(args):
    plt = plt_setup()
    from PIL import Image
    im = np.array(Image.open(args.shot).convert('RGB'))
    s = im.shape[1] // 256
    top = im[0:8 * s, :, :]
    bot = im[23 * 8 * s:24 * 8 * s, :, :]
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 2.9))
    for ax, part, row, labels in (
            (axes[0], top, 0, [(0, 8, 'score: ScoreLine $6657, 8 digits'), (15, 2, 'lives'),
                               (26, 6, 'Fireblade')]),
            (axes[1], bot, 23, [(0, 8, 'vitality $6642'), (9, 5, 'EXTRA'), (14, 4, 'weapon'),
                                (18, 5, 'BONUS'), (24, 8, 'charge $6645')])):
        ax.imshow(part, interpolation='nearest', extent=(0, 32, 1, 0), aspect='auto')
        ax.set_xticks(range(0, 33, 2))
        ax.set_xticklabels([str(c) for c in range(0, 33, 2)], fontsize=10)
        ax.set_yticks([])
        ax.set_ylabel('row %d' % row, fontsize=10)
        for c0, w, text in labels:
            ax.annotate('', xy=(c0, 1.08), xytext=(c0 + w, 1.08), xycoords=('data', 'axes fraction'),
                        textcoords=('data', 'axes fraction'), arrowprops=dict(arrowstyle='<->', color='#cc6600'))
            ax.text(c0 + w / 2, 1.18, text, transform=ax.get_xaxis_transform(), ha='center', fontsize=10)
    fig.suptitle('The panel: row 0 and row 23 of the screen (menu recording, frame 2050)', fontsize=12, y=0.99)
    fig.subplots_adjust(left=0.05, right=0.99, top=0.78, bottom=0.1, hspace=1.1)
    fig.savefig(args.out, dpi=100)
    print('wrote', args.out)


def cmd_screens(args):
    plt = plt_setup()
    from PIL import Image
    shots = [a.split(':', 1) for a in args.shots]
    cols = 3
    rows = (len(shots) + cols - 1) // cols
    fig, axes = plt.subplots(rows, cols, figsize=(10.5, 2.95 * rows + 0.2))
    for ax in axes.flat:
        ax.axis('off')
    for ax, (path, title) in zip(axes.flat, shots):
        ax.imshow(np.array(Image.open(path).convert('RGB')), interpolation='nearest')
        ax.set_title(title, fontsize=10)
    fig.subplots_adjust(left=0.005, right=0.995, top=0.94, bottom=0.005, wspace=0.03, hspace=0.18)
    fig.savefig(args.out, dpi=100)
    print('wrote', args.out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('what', choices=['font', 'tall', 'meter', 'weapon', 'blade', 'panel', 'screens'])
    ap.add_argument('out')
    ap.add_argument('--shot')
    ap.add_argument('--shots', nargs='*')
    args = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    globals()['cmd_' + args.what](args)


if __name__ == '__main__':
    main()
