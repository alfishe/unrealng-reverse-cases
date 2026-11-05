#!/usr/bin/env python3
"""The GS game file against Nether Earth's image byte by byte (docs/img/diff/memmap-diff.png) and the ten changed
runs up close, with both sides' bytes and the four bytes in which the Hood tape differs from the Tron Z disk
(docs/img/diff/runs-diff.png).

    python3 tools/fig_diff_memmap.py [--map PNG] [--runs PNG]

The classes come from tools/diff_ne.py (NE's build/game.bin and listing against the GS build/game/neart001.bin and its
listing). One cell of the map is one byte of the CPU's view, $5B00-$FFFF, 256 bytes a row:

  same        the same byte at the same address in both images
  conversion  a byte the GS conversion changed (the bridge, the sound hooks, the border OUTs)
  dump        a self-modified operand of the menu tune: the GS file is a memory dump taken in NE's main menu
  ne-only     NE's image holds it, the GS file does not start until $6590
  gs-only     the GS file holds it, NE's image ends at $FCE8 (the dump's work space, IM 2 table, stack)
"""

import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False  # hex addresses: $ is not math
import numpy as np  # noqa: E402
from matplotlib.colors import ListedColormap  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import diff_ne as D  # noqa: E402

CLASSES = [('none', 'outside both images', '#0e0e14'),
           ('same', 'the same byte at the same address', '#3d6b47'),
           ('conversion', 'changed by the GS conversion', '#e5534b'),
           ('dump', 'menu tune operand, self-modified (dump state)', '#f2e86d'),
           ('ne-only', 'NE\'s image only (the GS file starts at $6590)', '#2b3550'),
           ('gs-only', 'GS file only (dump work space, IM 2 table, stack)', '#26c6da')]
INDEX = {k: i for i, (k, _, _) in enumerate(CLASSES)}
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'
DUMP = {0xC4D0, 0xC4D6, 0xC4ED, 0xC4EF, 0xC4F3}

REGIONS = [  # (address, label); every label is checked against the classes by check_regions()
    (0x5B00, 'NE ViewBuffer $5B00-$658F: not in the GS file'),
    (0x6780, 'font, sprites $6780-$A568: same, byte for byte'),
    (0xA569, 'NE sprite tail + SpriteSpare -> GsMenuSound $A569, GsSound $A583'),
    (0xA5A9, 'start .. world, bases, level, main menu: same'),
    (0xBAEF, 'NuclearRumble: OUT ($FE) loop -> effect 14 + two delays'),
    (0xC4D0, 'menu tune: 5 dump operands, 8 OUT ($FE),A -> NOP NOP'),
    (0xC849, 'ConstructionMenu: LD IY,Robots -> CALL GsMenuSound'),
    (0xCCAC, 'Beep -> CALL GsSound; RET'),
    (0xD5C4, 'SoundEffect -> three ids to GsSound'),
    (0xD7D3, 'shots, radar, robots, map: zero in both'),
    (0xFCE9, 'GS dump: N1 remnant, IM 2 JP $FDFD, table $FE00'),
]


def classify():
    ne, gs = D.Case('NE'), D.Case('GS')
    cls = {}
    for a in range(0x5B00, 0x10000):
        if a in ne.mem and a in gs.mem:
            if ne.mem[a] == gs.mem[a]:
                cls[a] = 'same'
            else:
                cls[a] = 'dump' if a in DUMP else 'conversion'
        elif a in ne.mem:
            cls[a] = 'ne-only'
        elif a in gs.mem:
            cls[a] = 'gs-only'
        else:
            cls[a] = 'none'
    return ne, gs, cls


def check_regions(cls):
    for addr, label in REGIONS:
        c = cls[addr]
        want = ('ne-only' if 'not in the GS' in label else 'gs-only' if 'GS dump' in label else
                'same' if 'same' in label or 'zero' in label else None)
        if want and c != want:
            raise SystemExit(f'region ${addr:04X} "{label}" is {c}, not {want}')


def draw_map(cls, out):
    grid = np.zeros(((0x10000 - 0x5B00) // 256, 256), dtype=int)
    for a, c in cls.items():
        grid[(a - 0x5B00) // 256, a & 255] = INDEX[c]
    fig = plt.figure(figsize=(13, 9.6), facecolor=BG)
    ax = fig.add_axes((0.11, 0.12, 0.47, 0.8))
    ax.imshow(grid, cmap=ListedColormap([c for _, _, c in CLASSES]), vmin=0, vmax=len(CLASSES) - 1,
              aspect='auto', interpolation='nearest', extent=(0, 256, grid.shape[0], 0))
    # the changed bytes are few: ring them so they show at this scale
    for a, c in cls.items():
        if c in ('conversion', 'dump'):
            ax.add_patch(plt.Rectangle(((a & 255) - 1.5, (a - 0x5B00) // 256 - 0.4), 4, 1.8, fill=False,
                                       ec=CLASSES[INDEX[c]][2], lw=0.7))
    ticks = list(range(0, grid.shape[0], 8))
    ax.set_yticks([t + 0.5 for t in ticks])
    ax.set_yticklabels([f'${0x5B00 + 256 * t:04X}' for t in ticks], fontsize=7, color=DIM, family='monospace')
    ax.set_xticks([0, 64, 128, 192, 255])
    ax.set_xticklabels(['+$00', '+$40', '+$80', '+$C0', '+$FF'], fontsize=7, color=DIM, family='monospace')
    ax.tick_params(colors=DIM)
    for s in ax.spines.values():
        s.set_color(DIM)
    for addr, txt in ((0x6590, 'GS file $6590 '), (0xFCE9, 'NE image end $FCE8 ')):
        ax.axhline((addr - 0x5B00) / 256, color='white', lw=0.6, ls=':')
        ax.text(-2, (addr - 0x5B00) / 256, txt, color='white', fontsize=7, ha='right', va='center')
    y_used = []
    for addr, label in REGIONS:
        y = (addr - 0x5B00) / 256 + 0.5
        ly = max([y] + [u + 3.2 for u in y_used])
        y_used.append(ly)
        ax.annotate(label, ((addr & 255) + 0.5, y), xytext=(262, ly), textcoords='data', fontsize=8, color=TEXT,
                    va='center', annotation_clip=False,
                    arrowprops=dict(arrowstyle='-', color=DIM, lw=0.6, shrinkA=0, shrinkB=0))
    from collections import Counter
    n = Counter(cls.values())
    common = n['same'] + n['conversion'] + n['dump']
    fig.legend(handles=[Patch(color=c, label=f'{lab}: {n[k]:,} bytes') for k, lab, c in CLASSES[1:]],
               loc='lower left', ncol=2, frameon=False, labelcolor=TEXT, fontsize=8, bbox_to_anchor=(0.06, 0.0))
    fig.suptitle(f'The GS game is NE\'s image at NE\'s addresses: {n["same"] / common:.2%} of the {common:,} '
                 f'common bytes are the same, {n["conversion"] + n["dump"]} differ', color=TEXT, fontsize=11,
                 x=0.01, ha='left')
    fig.text(0.01, 0.945, 'One cell one byte of the Z80\'s view, 256 a row; changed bytes ringed; classes from '
             'tools/diff_ne.py over both builds', color=DIM, fontsize=8)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, dpi=100, facecolor=BG)
    print('wrote', out, dict(n))


def draw_runs(ne, gs, tap, out):
    runs = D.runs_of(ne.mem, gs.mem, 0x6590, 0xFCE9, 8)
    tape = [a for a in range(0x6590, 0x10000) if a in tap.mem and tap.mem[a] != gs.mem.get(a)]
    rows = [(lo, hi) for lo, hi in runs]
    # the tape's bytes outside the runs (the save entry, the same in NE and the disk): one row of their own
    outside = [a for a in tape if not any(lo <= a < hi for lo, hi in runs)]
    if outside:
        rows.append((outside[0] - 1, outside[-1] + 2))
    fig = plt.figure(figsize=(13, 1.2 + 0.62 * len(rows) * 2.2), facecolor=BG)
    ax = fig.add_axes((0.2, 0.03, 0.78, 0.88))
    ax.set_facecolor(BG)
    ax.axis('off')
    width = 32
    y = 0
    for lo, hi in rows:
        n_lines = (hi - lo + width - 1) // width
        for line in range(n_lines):
            for side, (mem, lab) in enumerate(((ne.mem, 'NE'), (gs.mem, 'GS'))):
                yy = y + side
                for k in range(width):
                    a = lo + line * width + k
                    if a >= hi:
                        break
                    v = mem[a]
                    diff = ne.mem[a] != gs.mem[a]
                    col = (CLASSES[INDEX['dump']][2] if a in DUMP else CLASSES[INDEX['conversion']][2]) \
                        if diff else '#2a3f30'
                    ax.add_patch(plt.Rectangle((k, -yy), 0.94, 0.86, color=col))
                    tv = f'{v:02X}|{tap.mem[a]:02X}' if side == 1 and a in tape else f'{v:02X}'
                    ax.text(k + 0.47, -yy + 0.43, tv, ha='center', va='center', fontsize=6.5 if len(tv) == 2 else 5,
                            family='monospace', color='#101010' if diff else TEXT)
                    if side == 1 and a in tape:
                        ax.add_patch(plt.Rectangle((k - 0.04, -yy - 0.04), 1.02, 0.94, fill=False, ec='white',
                                                   lw=1.6))
                e = (ne if side == 0 else gs).entry_at(lo + line * width)
                owner = e['name'] if e else ''
                ax.text(-0.6, -yy + 0.43, f'{lab} ${lo + line * width:04X} {owner}', ha='right', va='center',
                        fontsize=7.5, color=TEXT if line == 0 else DIM, family='monospace')
            y += 2
        y += 0.8
    ax.set_xlim(-0.2, width)
    ax.set_ylim(-y, 1)
    fig.suptitle(f'The {len(runs)} changed runs, NE above GS: {sum(ne.mem[a] != gs.mem[a] for lo, hi in runs for a in range(lo, hi))}'
                 ' bytes differ; last row: the save entry; white frame disk|tape = the Hood tape\'s other byte (4 in all)',
                 color=TEXT, fontsize=10.5, x=0.01, ha='left')
    fig.legend(handles=[Patch(color='#2a3f30', label='same'),
                        Patch(color=CLASSES[INDEX['conversion']][2], label='conversion'),
                        Patch(color=CLASSES[INDEX['dump']][2], label='dump state (self-modified operand)')],
               loc='upper right', ncol=3, frameon=False, labelcolor=TEXT, fontsize=8, bbox_to_anchor=(0.99, 0.965))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, dpi=100, facecolor=BG)
    print('wrote', out, 'runs', [f'${a:04X}-${b - 1:04X}' for a, b in runs], 'tape', [f'${a:04X}' for a in tape])


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--map', default=os.path.join(D.GS, 'docs/img/diff/memmap-diff.png'))
    ap.add_argument('--runs', default=os.path.join(D.GS, 'docs/img/diff/runs-diff.png'))
    a = ap.parse_args()
    ne, gs, cls = classify()
    check_regions(cls)
    draw_map(cls, a.map)
    draw_runs(ne, gs, D.Case('TAP'), a.runs)


if __name__ == '__main__':
    main()
