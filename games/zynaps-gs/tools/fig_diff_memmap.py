#!/usr/bin/env python3
"""The GS game image against Zynaps 48K's byte by byte (docs/img/diff/memmap-diff.png) and the eleven changed runs up
close, with both sides' bytes (docs/img/diff/runs-diff.png). Copied from nether-earth-gs's tools/fig_diff_memmap.py
and moved onto this pair.

    python3 tools/fig_diff_memmap.py [--map PNG] [--runs PNG] [--live BIN]

The classes come from tools/diff_zy.py (the 48K's build/game.bin put through Start, against the GS build/game.bin,
Trush block 4). One cell of the map is one byte of the CPU's view, $5B00-$FFFF, 256 bytes a row:

  same       the same byte at the same address in both images
  start      the same byte only after the 48K's Start ran (the tape holds it at $BC00 or inverted)
  differ     a byte the GS conversion changed in the block
  install    a byte the installer writes at run time (its 31 places and its stub areas), taken from a live view
  cache      $C800-$DFFF, the glyph cache: block 4 does not carry it
  none       outside both images ($5B00-$5BFF below them, $FFFF past the 48K's end)
"""

import argparse
import os
import sys
from collections import Counter

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False  # hex addresses: $ is not math
import numpy as np  # noqa: E402
from matplotlib.colors import ListedColormap  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import diff_zy as D  # noqa: E402

LO = 0x5B00
CLASSES = [('none', 'outside both images', '#0e0e14'),
           ('same', 'the same byte at the same address', '#3d6b47'),
           ('start', 'the same once the 48K\'s Start ran (moved or inverted on tape)', '#5e8f9e'),
           ('differ', 'changed in the block by the GS conversion', '#e5534b'),
           ('install', 'written by the installer at run time (31 places, stubs)', '#f2e86d'),
           ('cache', 'glyph cache $C800-$DFFF: not carried by block 4', '#2b3550')]
INDEX = {k: i for i, (k, _, _) in enumerate(CLASSES)}
BG, TEXT, DIM = '#0e0e14', '#d2d2dc', '#787887'

REGIONS = [  # (address, label, the class the label claims); checked by check_regions()
    (0x5B00, 'TitleStub $5B00, Mover $5BCC: below both images', 'install'),
    (0x5C00, 'tiles, glyphs $5C00-$67FF: the 48K\'s Start puts them here', 'start'),
    (0x6800, 'scripts, tables, texts: same', 'same'),
    (0x8001, 'GameEntry: JP Start -> JP MainLoop', 'differ'),
    (0x8479, 'credits text: MUSIC / STEVE TURNER -> PRESS / 1,2,3 & FIRE', 'differ'),
    (0x9C78, 'player, enemies: sound CALLs at the installer\'s places', 'install'),
    (0xA0C2, 'BigEnemyHandler: the three noise patterns -> NOPs', 'differ'),
    (0xA5FC, 'RedefineKeys, HighScoreEntry: WaitFrames -> HALT loops', 'differ'),
    (0xAA28, 'PlayInterrupt: the noise mask code -> GateStub', 'install'),
    (0xB0FF, 'EndOfPlay, MainLoop: the round end, the title loop', 'differ'),
    (0xB2F0, 'RequestEffect -> ObjectSoundStub', 'install'),
    (0xB446, 'TitleTune -> the Trampolines and the GS flags', 'install'),
    (0xC800, 'glyph cache: zero, rebuilt per level', 'cache'),
    (0xE000, 'sprite sets: inverted on tape, Start turns them', 'start'),
    (0xFF1C, 'tune data -> HookStubs $FF1C-$FFD1', 'install'),
]


def install_bytes(gs, live):
    """the addresses the installer writes: the sites' three bytes and the stub areas, where the live view differs"""
    sites, areas = D.installer_places()
    out = set()
    for a, _, _ in sites:
        out.update(x for x in range(a, a + 3) if live[x] != gs.mem.get(x))
    for a, _, n in areas:
        out.update(x for x in range(a, a + n) if live[x] != gs.mem.get(x))
    return out


def classify(live_path):
    z, gs = D.Case('Z48'), D.Case('GS')
    base = D.classify(z, gs)
    inst = install_bytes(gs, open(live_path, 'rb').read())
    cls = {}
    for a in range(LO, 0x10000):
        c = base.get(a, 'none')
        if c in ('gs-only', 'z48-only'):
            c = 'none'
        cls[a] = 'install' if a in inst else c
    return z, gs, cls, inst


def check_regions(cls):
    for addr, label, want in REGIONS:
        if cls[addr] != want:
            raise SystemExit(f'region ${addr:04X} "{label}" is {cls[addr]}, not {want}')


def draw_map(cls, cls_block, inst, out):
    grid = np.zeros(((0x10000 - LO) // 256, 256), dtype=int)
    for a, c in cls.items():
        grid[(a - LO) // 256, a & 255] = INDEX[c]
    fig = plt.figure(figsize=(13, 9.6), facecolor=BG)
    ax = fig.add_axes((0.11, 0.12, 0.47, 0.8))
    ax.imshow(grid, cmap=ListedColormap([c for _, _, c in CLASSES]), vmin=0, vmax=len(CLASSES) - 1,
              aspect='auto', interpolation='nearest', extent=(0, 256, grid.shape[0], 0))
    for a, c in cls.items():  # the changed bytes are few: ring them so they show at this scale
        if c in ('differ', 'install'):
            ax.add_patch(plt.Rectangle(((a & 255) - 1.5, (a - LO) // 256 - 0.4), 4, 1.8, fill=False,
                                       ec=CLASSES[INDEX[c]][2], lw=0.7))
    ticks = list(range(0, grid.shape[0], 8))
    ax.set_yticks([t + 0.5 for t in ticks])
    ax.set_yticklabels([f'${LO + 256 * t:04X}' for t in ticks], fontsize=7, color=DIM, family='monospace')
    ax.set_xticks([0, 64, 128, 192, 255])
    ax.set_xticklabels(['+$00', '+$40', '+$80', '+$C0', '+$FF'], fontsize=7, color=DIM, family='monospace')
    ax.tick_params(colors=DIM)
    for s in ax.spines.values():
        s.set_color(DIM)
    for addr, txt in ((0x5C00, 'GS block 4 $5C00 '), (0x61A8, '48K tape image $61A8 ')):
        ax.axhline((addr - LO) / 256, color='white', lw=0.6, ls=':')
        ax.text(1, (addr - LO) / 256 - 0.15, txt, color='white', fontsize=7, ha='left', va='bottom')
    y_used = []
    for addr, label, _ in REGIONS:
        y = (addr - LO) / 256 + 0.5
        ly = max([y] + [u + 3.2 for u in y_used])
        y_used.append(ly)
        ax.annotate(label, ((addr & 255) + 0.5, y), xytext=(262, ly), textcoords='data', fontsize=8, color=TEXT,
                    va='center', annotation_clip=False,
                    arrowprops=dict(arrowstyle='-', color=DIM, lw=0.6, shrinkA=0, shrinkB=0))
    n = Counter(cls.values())
    fig.legend(handles=[Patch(color=c, label=f'{lab}: {n[k]:,} bytes') for k, lab, c in CLASSES],
               loc='lower left', ncol=2, frameon=False, labelcolor=TEXT, fontsize=8, bbox_to_anchor=(0.06, 0.0))
    both = sum(1 for a in inst if cls_block.get(a) == 'differ')
    fig.suptitle(f'Zynaps GS is the 48K image after its start-up, at the 48K\'s addresses: {n["differ"] + both} bytes '
                 f'changed in the block ({both} written over again by the installer), {n["install"]} by the installer',
                 color=TEXT, fontsize=11, x=0.01, ha='left')
    fig.text(0.01, 0.945, 'One cell one byte of the Z80\'s view, 256 a row; changed bytes ringed; classes from '
             'tools/diff_zy.py over both builds, installer bytes from r1-play\'s live view', color=DIM, fontsize=8)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, dpi=100, facecolor=BG)
    print('wrote', out, dict(n))


def draw_runs(z, gs, out):
    runs = D.runs_of(z.mem, gs.mem, D.LO, D.HI, 8)
    fig = plt.figure(figsize=(13, 1.2 + 0.62 * len(runs) * 2.2), facecolor=BG)
    ax = fig.add_axes((0.24, 0.03, 0.75, 0.88))
    ax.set_facecolor(BG)
    ax.axis('off')
    width = 24
    y = 0
    for lo, hi in runs:
        for line in range((hi - lo + width - 1) // width):
            for side, (case, lab) in enumerate(((z, '48K'), (gs, 'GS'))):
                yy = y + side
                for k in range(width):
                    a = lo + line * width + k
                    if a >= hi:
                        break
                    diff = z.mem[a] != gs.mem[a]
                    col = CLASSES[INDEX['differ']][2] if diff else '#2a3f30'
                    ax.add_patch(plt.Rectangle((k, -yy), 0.94, 0.86, color=col))
                    ax.text(k + 0.47, -yy + 0.43, f'{case.mem[a]:02X}', ha='center', va='center', fontsize=7,
                            family='monospace', color='#101010' if diff else TEXT)
                e = case.entry_at(lo + line * width)
                ax.text(-0.6, -yy + 0.43, f'{lab} ${lo + line * width:04X} {e["name"] if e else ""}', ha='right',
                        va='center', fontsize=7.5, color=TEXT if line == 0 else DIM, family='monospace')
            y += 2
        y += 0.8
    ax.set_xlim(-0.2, width)
    ax.set_ylim(-y, 1)
    total = sum(z.mem[a] != gs.mem[a] for lo, hi in runs for a in range(lo, hi))
    fig.suptitle(f'The {len(runs)} changed runs of block 4, the 48K (after Start) above GS: {total} bytes differ',
                 color=TEXT, fontsize=10.5, x=0.01, ha='left')
    fig.legend(handles=[Patch(color='#2a3f30', label='same'), Patch(color=CLASSES[INDEX['differ']][2],
                                                                    label='changed by the conversion')],
               loc='upper right', ncol=2, frameon=False, labelcolor=TEXT, fontsize=8, bbox_to_anchor=(0.99, 0.965))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, dpi=100, facecolor=BG)
    print('wrote', out, 'runs', [f'${a:04X}-${b - 1:04X}' for a, b in runs])


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--map', default=os.path.join(D.GS, 'docs/img/diff/memmap-diff.png'))
    ap.add_argument('--runs', default=os.path.join(D.GS, 'docs/img/diff/runs-diff.png'))
    ap.add_argument('--live', default=os.path.join(D.GS, 'work/zgsA/r1-play/start.bin'))
    a = ap.parse_args()
    z, gs, cls, inst = classify(a.live)
    check_regions(cls)
    draw_map(cls, D.classify(z, gs), inst, a.map)
    draw_runs(z, gs, a.runs)
    print('installer bytes', len(inst))


if __name__ == '__main__':
    main()
