#!/usr/bin/env python3
"""Doc 03 figure: the two disks sector by sector, and what each packed block of the '99 grows to in memory
(docs/img/load/disks.png).

Top two rows: the files of NEZSED98.SCL and NEZSED.SCL, 256-byte sectors from the first file's first sector, each
part of a file in its colour (the parts of NEZSEd.B / NEZSEd99.B as their loaders read them, by sector number:
src/disk98.txt, src/disk99.txt, docs/03 3.2-3.3). Bottom: the five packed blocks of the '99, the stream's length
against the image it unpacks to (work/media/99/blocks.json, tools/zspack.py check), with the ratio.

    python3 tools/fig_zs_disk.py --out docs/img/load/disks.png
"""
import argparse
import json
import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
C = {'basic': '#7a7d8c', 'intro': '#c77ddb', 'game': '#4caf50', 'packed': '#5c8fd6', 'raw': '#d9a441',
     'text': '#59c9a5', 'map': '#e5534b'}

# (first sector, sectors, label, colour)
DISK98 = [(0, 2, '', 'basic'), (2, 42, "intro $C000-$E9FF\n(PT3, logo, scroller)", 'intro'),
          (44, 113, "the game $6780-$D87F, not packed", 'game')]
DISK99 = [(0, 1, '', 'basic'), (1, 18, 'stage 2\n(intro)', 'packed'), (19, 13, 'pictures\n$7D87', 'raw'),
          (32, 13, 'music\n$C000', 'raw'), (45, 6, 'st.3', 'packed'), (51, 68, 'the game, packed (to $6780)', 'packed'),
          (119, 4, '', 'packed'), (123, 10, 'menu', 'packed'),
          (133, 15, 'about', 'text'), (148, 22, 'description', 'text'), (170, 2, '', 'text'),
          (172, 22, 'advices', 'text'), (194, 22, 'readme', 'text')] + \
         [(216 + 2 * i, 2, '', 'map') for i in range(12)]


def row(ax, y, parts, file_marks):
    for first, n, label, kind in parts:
        ax.barh(y, n, left=first, height=0.62, color=C[kind], edgecolor=BG, linewidth=0.6)
        if label:
            ax.text(first + n / 2, y, label, ha='center', va='center', fontsize=8, color='#101010')
    for x, name in file_marks:
        ax.plot([x, x], [y - 0.42, y + 0.42], color=FG, lw=1.2)
        ax.text(x + 0.5, y + 0.36, name, fontsize=7.5, color=FG, va='bottom')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    info = json.load(open(os.path.join(ROOT, 'work', 'media', '99', 'blocks.json')))

    fig, (ax, bx) = plt.subplots(2, 1, figsize=(11, 7.0), gridspec_kw={'height_ratios': [1.35, 1]})
    fig.patch.set_facecolor(BG)
    for x_ in (ax, bx):
        x_.set_facecolor(PANEL)
        x_.tick_params(colors=DIM, labelsize=9)
        for s in x_.spines.values():
            s.set_color('#444')
    row(ax, 1, DISK98, [(0, 'NEZSEd.B (157 sectors): the BASIC with its REM loader $5D40 (sectors 0-1), the intro, the game')])
    row(ax, 0, DISK99, [(0, 'NEZSEd99.B (133)'), (133, 'NEabout.W'), (194, 'NEZSEd99.W'), (216, 'NELEV_00..11.N')])
    for x, name in ((148, 'NEdescri.W'), (170, 'NEgreets.W'), (172, 'NEadvice.W')):
        ax.plot([x, x], [-0.42, 0.42], color=FG, lw=1.2)
    ax.annotate('patches $DC00', (121, -0.3), (110, -0.85), color=FG, fontsize=8,
                arrowprops=dict(arrowstyle='->', color=DIM))
    ax.annotate('BASIC + reader $5D5B', (0.5, -0.3), (2, -0.85), color=FG, fontsize=8,
                arrowprops=dict(arrowstyle='->', color=DIM))
    ax.annotate('stage 3 reads 64 sectors from here to page 3:\nthe four texts and 3 sectors of the readme', (176, 0.32), (165, 1.0),
                color=FG, fontsize=8, arrowprops=dict(arrowstyle='->', color=DIM))
    ax.set_yticks([0, 1])
    ax.set_yticklabels(["'99 NEZSED.SCL", "'98 NEZSED98.SCL"], color=FG, fontsize=10)
    ax.set_xlim(-2, 242)
    ax.set_ylim(-1.05, 1.55)
    ax.set_xlabel('sector from the first file (256 bytes)', color=DIM, fontsize=9)
    handles = [plt.Rectangle((0, 0), 1, 1, color=C[k]) for k in ('basic', 'intro', 'game', 'packed', 'raw', 'text', 'map')]
    names = ['BASIC', "'98 intro", "'98 game (raw)", "'99 packed block (LZ)", "'99 raw block", 'ZX Word text',
             'map, 512 bytes']
    ax.legend(handles, names, ncol=4, loc='upper center', bbox_to_anchor=(0.5, -0.2), fontsize=8, facecolor=PANEL, labelcolor=FG, edgecolor='#444')

    names = ['stage2', 'stage3', 'game', 'patches', 'menu']
    labels = ['stage 2 (intro) $61A8-$7D86', 'stage 3 (System checking) $61A8-$67EB', 'the game $6780-$D7D2',
              'patches $D800-$DB6F', 'start-up menu $D800-$E6F3 (page 1)']
    ys = list(range(len(names)))[::-1]
    for y, n, lab in zip(ys, names, labels):
        b = info[n]
        out = int(b['end'], 16) - int(b['out'], 16) + 1
        bx.barh(y, out, height=0.62, color='#3a3d4a', edgecolor='#666')
        bx.barh(y, b['packed'], height=0.62, color=C['packed'])
        bx.text(out + 300, y, f"{b['packed']} -> {out} bytes ({100 * b['packed'] / out:.0f} %), far offset "
                f"{b['far_bits']} bits", va='center', color=FG, fontsize=8.5)
    bx.set_yticks(ys)
    bx.set_yticklabels(labels, color=FG, fontsize=9)
    bx.set_xlim(0, 48000)
    bx.set_xlabel('bytes: the stream (blue) inside the image it unpacks to (grey)', color=DIM, fontsize=9)
    total_p = sum(info[n]['packed'] for n in names)
    total_u = sum(int(info[n]['end'], 16) - int(info[n]['out'], 16) + 1 for n in names)
    fig.suptitle(f"The two disks: the '98 loads one raw file, the '99 reads every block of NEZSEd99.B by sector "
                 f"number;\nits five packed blocks hold {total_p} bytes that unpack to {total_u} "
                 f"({100 * total_p / total_u:.0f} %)", color=FG, fontsize=11.5, x=0.02, ha='left')
    fig.tight_layout()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, facecolor=BG, dpi=100)
    print(a.out, total_p, total_u)


if __name__ == '__main__':
    main()
