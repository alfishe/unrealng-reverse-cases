#!/usr/bin/env python3
"""Doc 03 figure: the disk as the boot and the loader read it, every sector coloured by what it holds.

    python3 tools/fig_disk.py [--out docs/img/load/disk-map.png]

The TRD is 160 logical tracks of 16 sectors (track = cylinder x 2 + side). One column a track, one row a sector
(sector 0 at the top). The witnesses: track 0 is TR-DOS's catalogue; the run from track 1 sector 0 is read in the
order of src/disk/boot.ann (the BASIC, the boot, Trush blocks 0-4 and bank 3 raw) and then src/disk/loader.ann's
record table (FxRecords, ModuleRecords), here from work/stage1/level-table.txt (one line a record: blob sector,
sectors, flags; bit 1 = a Trush block). Hatched: stored raw (no Trush).
"""
import argparse
import os
import re

import zgsplot as P
from matplotlib.patches import Patch, Rectangle

plt = P.plt
HERE = os.path.dirname(os.path.abspath(__file__))
CASE = P.CASE

BOOT = [  # blob sector, count, kind, label, packed
    (0, 1, 'basic', 'BASIC line', False),
    (1, 2, 'boot', 'boot code', False),
    (3, 13, 'screen', 'block 0: loading screen', True),
    (16, 40, 'bank', 'block 1: bank 1 (jingle, FX 1-2)', True),
    (56, 64, 'bank', 'bank 3 raw (FX 2-5)', False),
    (120, 58, 'bank', 'block 2: bank 4 (FX 5-8)', True),
    (178, 49, 'bank', 'block 3: bank 6 (FX 8-10)', True),
    (227, 94, 'game', 'block 4: installer, driver, menu, Zynaps', True),
]
KIND = {'catalogue': ('#7a7a8c', 'TR-DOS catalogue (track 0)'), 'basic': ('#e0e0e0', 'BASIC line'),
        'boot': ('#ff9f40', 'boot code (2 sectors)'), 'screen': ('#4fa3ff', 'block 0: loading screen + fade'),
        'bank': ('#c77ddb', 'boot FX banks 1, 3, 4, 6 (jingle, FX 1-10)'),
        'game': ('#4caf50', 'block 4: installer, GS driver, menu, Zynaps'),
        'fx': ('#e5534b', 'disk FX sets (effects-only FX 11-21)'),
        'mod': ('#d9a441', 'level modules (13, two shades to part them)'), 'free': ('#1c1c24', 'free (370 sectors)')}


def records():
    out = []
    for line in open(os.path.join(CASE, 'work', 'stage1', 'level-table.txt')):
        m = re.match(r'\$[0-9A-F]{4} (FX \(boot\)|level\s+(\d+) module)\s+(\d+)\s+(\d+)\s+0x([0-9a-f]+)', line)
        if m:
            fl = int(m.group(5), 16)
            kind = 'fx' if m.group(1).startswith('FX') else 'mod'
            out.append((int(m.group(3)), int(m.group(4)), kind, m.group(2), bool(fl & 2)))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--out', default=P.out('load', 'disk-map.png'))
    a = ap.parse_args()
    P.style()
    owner = {}
    for t in range(16):
        owner[t] = ('catalogue', None, False)
    for b, n, k, lab, packed in BOOT:
        for i in range(n):
            owner[16 + b + i] = (k, lab, packed)
    recs = records()
    for b, n, k, lvl, packed in recs:
        for i in range(n):
            owner[16 + b + i] = (k, lvl, packed)
    ORDER = []
    for b, n, k, lvl, packed in recs:
        if k == 'mod' and lvl not in ORDER:
            ORDER.append(lvl)
    fig, ax = plt.subplots(figsize=(11.5, 4.8), dpi=90)
    for sec in range(2560):
        t, s = divmod(sec, 16)
        k, lab, packed = owner.get(sec, ('free', None, False))
        colour = KIND[k][0]
        if k == 'mod' and ORDER.index(lab) % 2:
            colour = '#a8802e'
        ax.add_patch(Rectangle((t, s), 1, 1, facecolor=colour, edgecolor=P.BG, linewidth=0.25,
                               hatch='////' if (k not in ('free', 'catalogue') and not packed) else None))
    # module labels: the level number at the middle of each module's run
    spans = {}
    for b, n, k, lvl, packed in recs:
        key = ('FX' if k == 'fx' else 'L' + lvl)
        lo, hi = spans.get(key, (10 ** 9, 0))
        spans[key] = (min(lo, 16 + b), max(hi, 16 + b + n))
    for key, (lo, hi) in spans.items():
        mid = (lo + hi) / 2 / 16
        ax.annotate('', xy=(lo / 16, -0.6), xytext=(hi / 16, -0.6),
                    arrowprops=dict(arrowstyle='<->', color=P.TEXT, lw=0.8))
        ax.text(mid, -1.3, key if key != 'FX' else 'FX 11-21', ha='center', va='bottom', fontsize=9, color=P.TEXT)
    names = ['block 0 (screen)', 'block 1 (bank 1)', 'bank 3 raw', 'block 2 (bank 4)', 'block 3 (bank 6)',
             'block 4 (game)']
    for i, ((b, n, k, lab, packed), name) in enumerate(zip(BOOT[2:], names)):
        mid = (16 + b + n / 2) / 16
        x = 26 + i * 16
        ax.annotate(name, xy=(mid, 16.0), xytext=(x, 18.2), ha='left', va='center', fontsize=8, color=P.TEXT,
                    arrowprops=dict(arrowstyle='-', color=P.DIM, lw=0.7))
    ax.set_xlim(0, 160)
    ax.set_ylim(19.0, -3.2)
    ax.set_xticks(range(0, 161, 10))
    ax.set_yticks([0, 4, 8, 12, 15])
    ax.set_xlabel('track (cylinder x 2 + side); boot blocks named below, level modules (L1..L13 = level, L13 the title) above')
    ax.set_ylabel('sector')
    ax.set_title('One run of 2174 sectors from track 1: the boot reads tracks 1-21, a level change reads one module\n'
                 'and the 10 FX of the boot banks go from RAM; hatched = stored raw, plain = a Trush block')
    hand = [Patch(facecolor=c, label=l) for c, l in KIND.values()] + \
        [Patch(facecolor='#555', hatch='////', label='hatched: raw, not packed')]
    ax.legend(handles=hand, loc='upper center', bbox_to_anchor=(0.5, -0.17), ncol=3, fontsize=8.5, frameon=False)
    fig.tight_layout()
    fig.savefig(a.out)
    print(a.out)


if __name__ == '__main__':
    main()
