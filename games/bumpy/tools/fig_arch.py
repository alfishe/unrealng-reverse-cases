#!/usr/bin/env python3
"""Doc 02's figures, from the source alone (no emulator):

  python3 tools/fig_arch.py

- docs/img/arch/memory-map.png: `$6000-$FFFF` in rows of 1 KB, each byte coloured by the module of its entry in
  src/game/game.ann (the 14 modules); entries the code never reads or runs (their titles say "never read", "never
  called", "never run", "nothing calls" or "nothing reads", or an Unused name) are drawn pale; the labelled blocks are
  the large entries.
- docs/img/arch/leftovers.png: what the Spectrum never shows: the CPC side panel PanelPicture `$D2B4` (18 x 200 bytes,
  CPC mode 1, drawn here with all four pens; the Spectrum's pictures show only the low nibble), the CPC level editor's
  font EditorFont `$E21E` (26 letters 8 x 5) and its menu texts EditorTexts `$E1C9` (letters A = 1).
"""
import os
import re

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
OUT = os.path.join(CASE, 'docs', 'img', 'arch')
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'
START, END = 0x61A8, 0xF8D5
MODCOL = {
    'graphics': '#5a96fa', 'levels': '#5ac878', 'vars': '#f0c846', 'setup': '#e68cdc', 'mainloop': '#ff5050',
    'ball': '#ff9a3c', 'menu': '#46d2d2', 'render': '#a078ff', 'hud': '#c8ff64', 'hiscore': '#ff78a0',
    'objects': '#b4a078', 'sprites': '#ffffff', 'text': '#8cb4ff', 'sound': '#ffd28c'}
NEVER = re.compile(r'never read|never called|never run|nothing calls|nothing reads|never used|\(unrun|unrun\)',
                   re.I)


def entries():
    out, mod = [], None
    for line in open(os.path.join(CASE, 'src/game/game.ann'), encoding='utf-8'):
        m = re.match(r'@module (\w+)', line)
        if m:
            mod = m.group(1)
            continue
        m = re.match(r'\$([0-9A-F]{4}) ([cbwts]) (\w+)(?: [^;]*)?(?:; (.*))?', line)
        if m:
            title = m.group(4) or ''
            never = bool(NEVER.search(title)) or m.group(3).startswith('Unused')
            out.append((int(m.group(1), 16), m.group(2), m.group(3), mod, never))
    out.sort()
    return out


def hexrgb(h, pale=False):
    v = np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], dtype=float)
    return v * 0.33 if pale else v


def memory_map():
    ents = entries()
    rows = 40                                     # $6000-$FFFF, 1 KB a row
    img = np.zeros((rows, 1024, 3))
    img[:, :] = hexrgb('#24242e')
    for i, (a, k, n, mod, never) in enumerate(ents):
        b = ents[i + 1][0] if i + 1 < len(ents) else END
        col = hexrgb(MODCOL[mod], never)
        for x in range(a, b):
            r, c = divmod(x - 0x6000, 1024)
            img[r, c] = col
    fig, ax = plt.subplots(figsize=(10.5, 9.6), dpi=100, facecolor=BG)
    ax.imshow(img / 255, aspect='auto', interpolation='nearest', extent=(0, 1024, rows, 0))
    ax.set_yticks([r + 0.5 for r in range(0, rows, 2)])
    ax.set_yticklabels([f'\\${0x6000 + 1024 * r:04X}' for r in range(0, rows, 2)], fontsize=10, color=TEXT,
                       family='monospace')
    ax.set_xticks(range(0, 1025, 128))
    ax.set_xticklabels([f'+\\${x:03X}' for x in range(0, 1025, 128)], fontsize=10, color=TEXT, family='monospace')
    ax.tick_params(colors=TEXT)
    for s in ax.spines.values():
        s.set_color(DIM)
    big = [(a, n) for i, (a, k, n, mod, never) in enumerate(ents)
           if (ents[i + 1][0] if i + 1 < len(ents) else END) - a >= 700]
    for a, n in big:
        r, c = divmod(a - 0x6000, 1024)
        ax.text(min(c, 760) + 6, r + 0.62, f'{n} \\${a:04X}', fontsize=10, color='black',
                bbox=dict(facecolor='#f0f0f0', edgecolor='none', pad=1, alpha=0.85))
    for a, lab in ((0x6000, 'BASIC, stack \\$6170-\\$618F'), (0xF8D5, 'free: never touched')):
        r, c = divmod(a - 0x6000, 1024)
        ax.text(c + 6, r + 0.62, lab, fontsize=10, color=TEXT)
    handles = [Patch(color=MODCOL[m], label=m) for m in MODCOL]
    handles.append(Patch(color=tuple(hexrgb('#ff9a3c', True) / 255), label='never read or run (pale)'))
    ax.legend(handles=handles, loc='upper center', bbox_to_anchor=(0.5, -0.04), ncol=5, fontsize=10,
              facecolor=PANEL, labelcolor=TEXT, edgecolor=DIM)
    ax.set_title('The game block \\$61A8-\\$F8D4 by module (src/game/game.ann, 650 entries), 1 KB a row',
                 color=TEXT, fontsize=12)
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, 'memory-map.png'), facecolor=BG)
    plt.close(fig)
    print('memory-map.png')


def cpc_mode1(data, w, h):
    pal = np.array([(0, 0, 0), (255, 255, 0), (0, 255, 255), (255, 60, 60)]) / 255
    img = np.zeros((h, w * 4, 3))
    for y in range(h):
        for x in range(w):
            v = data[y * w + x]
            for p in range(4):
                img[y, x * 4 + p] = pal[((v >> (7 - p)) & 1) | (((v >> (3 - p)) & 1) << 1)]
    return img


def leftovers():
    mem = open(os.path.join(CASE, 'work/mkgame/original.bin'), 'rb').read()
    panel = cpc_mode1(mem[0xD2B4:0xD2B4 + 3600], 18, 200)
    low = np.zeros((200, 72, 3))
    for y in range(200):                          # the low nibble: one bit a pixel, as the Spectrum's blitters show it
        for x in range(18):
            v = mem[0xD2B4 + y * 18 + x]
            for p in range(4):
                if (v >> (3 - p)) & 1:
                    low[y, x * 4 + p] = (1, 1, 1)
    font = mem[0xE21E:0xE21E + 130]
    glyphs = np.zeros((2 * 7, 13 * 9))
    for g in range(26):
        gy, gx = divmod(g, 13)
        for y in range(5):
            v = font[g * 5 + y]
            for x in range(8):
                glyphs[gy * 7 + y, gx * 9 + x] = (v >> (7 - x)) & 1
    words, cur = [], ''
    for v in mem[0xE1C9:0xE1C9 + 81]:
        if v == 0:
            words.append(cur)
            cur = ''
        else:
            cur += chr(64 + v) if 1 <= v <= 26 else f'[{v:02X}]'
    fig = plt.figure(figsize=(10.5, 7.4), dpi=100, facecolor=BG)
    a1 = fig.add_axes([0.02, 0.05, 0.2, 0.86])
    a2 = fig.add_axes([0.24, 0.05, 0.2, 0.86])
    a3 = fig.add_axes([0.48, 0.6, 0.5, 0.28])
    a4 = fig.add_axes([0.48, 0.02, 0.5, 0.52])
    a1.imshow(panel, interpolation='nearest', aspect=2)
    a1.set_title('PanelPicture \\$D2B4\nthe CPC panel, 4 pens', color=TEXT, fontsize=10)
    a2.imshow(low, interpolation='nearest', aspect=2)
    a2.set_title('the low nibble only, one bit a pixel\n(as the Spectrum blitters show a picture)', color=TEXT, fontsize=10)
    a3.imshow(glyphs, cmap='gray', interpolation='nearest', aspect=1)
    a3.set_title('EditorFont \\$E21E: A-Z, 8 x 5 (130 bytes)', color=TEXT, fontsize=10)
    a4.axis('off')
    a4.set_facecolor(BG)
    a4.text(0, 1, 'EditorTexts \\$E1C9 (81 bytes, A = 1, \\$00 ends a string):', color=TEXT, fontsize=11,
            va='top')
    for i, w in enumerate(words):
        a4.text(0.04, 0.9 - i * 0.075, f'{i:2d}  "{w}"', color='#f0c846', fontsize=11, va='top', family='monospace')
    a4.text(0, 0.9 - len(words) * 0.075 - 0.02, 'RETOUR, EDITEUR, CHARGER TABLEAUX, SAUVER, EFFACER, QUITTER:\n'
            'the French menu of the CPC level editor', color=DIM, fontsize=10, va='top')
    for a in (a1, a2, a3):
        a.set_xticks([])
        a.set_yticks([])
    fig.suptitle('Leftovers of the Amstrad CPC original: no Spectrum routine reads them', color=TEXT, fontsize=12)
    fig.savefig(os.path.join(OUT, 'leftovers.png'), facecolor=BG)
    plt.close(fig)
    print('leftovers.png', words)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    memory_map()
    leftovers()
