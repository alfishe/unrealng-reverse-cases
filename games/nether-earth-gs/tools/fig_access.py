#!/usr/bin/env python3
"""Doc 02 figure: where the executed instructions, the reads and the writes of a recording fall, region by region of
the play memory map (docs/img/access-regions.png).

    python3 tools/fig_access.py --l1 work/gsA/deep/l1.json --out docs/img/arch/access-regions.png

Counts from an unreal-ng L1 build: `instructions` (each instruction's execution count, at its first byte) and
`byte_counts` (data reads and writes per byte, the four 48K pages). Each bar is the region's share of the
recording's total; the number at its end is that share. The regions are tools/memmap.txt's play stage, with the ROM
and the zero gap added. Prints the table too.
"""
import argparse
import json
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
BASES_48K = {5: 0x4000, 2: 0x8000, 0: 0xC000, 264: 0x0000, 1: 0x10000}   # Pentagon: ROM 3 = the 48K ROM; bank 1 apart
REGIONS = [  # start, end (inclusive), what, group colour
    (0x0000, 0x3FFF, 'ROM', 'other'),
    (0x4000, 0x5AFF, 'the screen', 'screen'),
    (0x5B00, 0x677F, 'ViewBuffer (the view drawn here)', 'screen'),
    (0x6780, 0x697F, 'Font', 'graphics'),
    (0x6980, 0xA568, 'sprites', 'graphics'),
    (0xA569, 0xA5FF, 'GsMenuSound, GsSound', 'code'),
    (0xA600, 0xD6A7, 'the game code', 'code'),
    (0xD6A8, 0xD7D2, 'tables', 'graphics'),
    (0xD7D3, 0xD7FF, 'Shots', 'world'),
    (0xD800, 0xD9FF, 'radar layers', 'world'),
    (0xDA00, 0xDCFF, 'Robots (ours and the enemy\'s)', 'world'),
    (0xDD00, 0xFCFF, 'Map, 16 x 512 cells', 'world'),
    (0xFD00, 0xFDFC, 'variables, capture points', 'world'),
    (0xFDFD, 0xFF00, 'IM 2 jump and vector table', 'other'),
    (0xFF01, 0xFFA8, 'Buildings', 'world'),
    (0xFFA9, 0xFFFF, 'the stack', 'other'),
    (0x10000, 0x13FFF, 'bank 1: the GS driver', 'code'),
]
GROUPS = {'screen': ('#5c8fd6', 'the screen and its back buffer'), 'graphics': ('#c77ddb', 'pictures and tables'),
          'code': ('#4caf50', 'code'), 'world': ('#d9a441', 'the game world (map, robots, variables)'),
          'other': ('#7a7d8c', 'ROM, interrupt, stack')}
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'


def counts(path):
    doc = json.load(open(path))
    executed, reads, writes = [0] * 0x14000, [0] * 0x14000, [0] * 0x14000
    for z80, page, _code, _cls, count, *_ in doc['instructions']:
        a = int(z80[1:], 16)
        executed[a - 0xC000 + 0x10000 if page == 1 and a >= 0xC000 else a] += count
    for page in doc['byte_counts']:
        base = BASES_48K.get(page['page'])
        if base is None:
            continue
        reads[base:base + 0x4000] = page['reads']
        writes[base:base + 0x4000] = page['writes']
    return executed, reads, writes, doc['replay']


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--l1', default=os.path.join(CASE, 'work', 'gsA', 'deep', 'l1.json'))
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'arch', 'access-regions.png'))
    args = p.parse_args()
    series = counts(args.l1)
    replay = series[3]
    totals = [sum(s) for s in series[:3]]
    shares = [[100 * sum(s[a:b + 1]) / t for a, b, *_ in REGIONS] for s, t in zip(series[:3], totals)]
    for (a, b, name, _), e, r, w in zip(REGIONS, *shares):
        print(f'${a:05X}-${b:05X} {name:36s} executed {e:5.1f} %  read {r:5.1f} %  written {w:5.1f} %')

    fig, axes = plt.subplots(1, 3, figsize=(11, 5.6), dpi=100, sharey=True)
    fig.patch.set_facecolor(BG)
    labels = [f'${a:04X}  {name}' if a < 0x10000 else f'$C000  {name}' for a, b, name, _ in REGIONS]
    ys = list(range(len(REGIONS)))[::-1]
    titles = [f'instructions executed\n({totals[0] / 1e6:.0f} million)', f'bytes read\n({totals[1] / 1e6:.0f} million)',
              f'bytes written\n({totals[2] / 1e6:.0f} million)']
    for ax, share, title in zip(axes, shares, titles):
        ax.set_facecolor(PANEL)
        ax.tick_params(colors=DIM, labelsize=9)
        for s in ax.spines.values():
            s.set_color('#444')
        ax.barh(ys, share, color=[GROUPS[g][0] for *_, g in REGIONS], height=0.7)
        for y, v in zip(ys, share):
            if v >= 0.05:
                ax.text(v + 2, y, f'{v:.1f} %' if v < 10 else f'{v:.0f} %', va='center', color=FG, fontsize=9)
        ax.set_xlim(0, 125)
        ax.set_xticks([0, 50, 100])
        ax.set_xticklabels(['0', '50 %', '100 %'])
        ax.set_title(title, color=FG, fontsize=10)
    axes[0].set_yticks(ys)
    axes[0].set_yticklabels(labels, color=FG, fontsize=10, family='monospace')
    handles = [plt.Rectangle((0, 0), 1, 1, color=c) for c, _ in GROUPS.values()]
    fig.legend(handles, [n for _, n in GROUPS.values()], loc='lower center', ncol=3, frameon=False,
               labelcolor=FG, fontsize=10, bbox_to_anchor=(0.55, -0.07))
    gs = sum(series[0][0xA569:0xA600]) + sum(series[0][0x10000:])
    fig.suptitle(f'{replay["frames"]} frames of play: the code at \\$A600-\\$D6A7 runs; the GS part ({gs} instructions) '
                 'does not show;\nreads go to the view buffer and the sprites, writes to the screen and the view buffer '
                 f'(work/gsA/deep, L1)', color=FG, fontsize=12, x=0.02, ha='left')
    fig.tight_layout()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=BG, bbox_inches='tight')
    print(args.out)


if __name__ == '__main__':
    sys.exit(main())
