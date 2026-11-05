#!/usr/bin/env python3
"""Doc 03 figure: how the '99 game block is packed, byte by byte (docs/img/load/lz-game.png).

Left: the unpacked game image $6780-$D7D2, 256 bytes a row ($6780 at the top), each byte coloured by the token
that made it in the original stream: a literal (single or in a literal run), or a match, its shade by the match's
offset class (near 1-$20, middle $21-$220, far $221 and up). Right: the five blocks' decisions, the share of the
output bytes each token kind makes, and the histogram of match lengths in the game block. Read with the original
streams' own token log (tools/zspack.py stream_tokens, the depacker tools/zsdepack.py), not the reimplemented
packer, so the figure shows the author's streams.

    python3 tools/fig_zs_lz.py --out docs/img/load/lz-game.png
"""
import argparse
import json
import os
import sys
from collections import Counter

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.colors import ListedColormap  # noqa: E402

plt.rcParams['text.parse_math'] = False
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zspack  # noqa: E402

BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
KINDS = [('literal', '#d9a441'), ('literal run (14-45)', '#e5534b'), ('match, offset 1-$20', '#9fc2f0'),
         ('match, offset $21-$220', '#5c8fd6'), ('match, offset $221+', '#7b4fc0')]


def classify(name):
    info = json.load(open(os.path.join(zspack.MEDIA, 'blocks.json')))[name]
    data = open(os.path.join(zspack.MEDIA, name + '-out.bin'), 'rb').read()
    stream = zspack.block_stream(open(os.path.join(zspack.MEDIA, name + '.bin'), 'rb').read())
    _, log = zspack.stream_tokens(stream, len(data), info['far_bits'])
    kinds, lengths, p = [0] * len(data), [], 0
    for e in log:
        if e[0] == 'lit':
            k, n = (0 if e[1] < 14 else 1), e[1]
        else:
            n, off = e[1], e[2]
            k = 2 if off <= 0x20 else 3 if off <= 0x220 else 4
            lengths.append(n)
        for i in range(n):
            kinds[len(data) - 1 - (p + i)] = k   # p counts from the top byte down
        p += n
    return info, data, kinds, lengths, log


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    info, data, kinds, lengths, log = classify('game')
    base = int(info['out'], 16)
    first_row = base & 0xFF00
    rows = (base + len(data) - 1 - first_row) // 256 + 1
    grid = [[-1] * 256 for _ in range(rows)]
    for i, k in enumerate(kinds):
        ad = base + i - first_row
        grid[ad // 256][ad % 256] = k
    cmap = ListedColormap(['#2a2c36'] + [c for _, c in KINDS])

    fig = plt.figure(figsize=(11.5, 6.8))
    fig.patch.set_facecolor(BG)
    ax = fig.add_axes([0.06, 0.08, 0.42, 0.78])
    ax.imshow([[v + 1 for v in r] for r in grid], cmap=cmap, vmin=0, vmax=len(KINDS), aspect='auto',
              interpolation='nearest')
    ax.set_facecolor(PANEL)
    ticks = list(range(0, rows, 8))
    ax.set_yticks(ticks)
    ax.set_yticklabels([f'${first_row + 256 * t:04X}' for t in ticks], color=FG, fontsize=8, family='monospace')
    ax.set_xticks([0, 64, 128, 192, 255])
    ax.set_xticklabels(['+$00', '+$40', '+$80', '+$C0', '+$FF'], color=DIM, fontsize=8)
    for s in ax.spines.values():
        s.set_color('#444')
    for start, label in ((0x6780, 'font'), (0x6980, 'sprites'), (0xA600, 'code'), (0xBDA9, 'level lists'),
                         (0xD6A8, 'tables')):
        y = (start - first_row) // 256
        ax.annotate(label, (255, y), (268, y), color=FG, fontsize=8, va='center', annotation_clip=False,
                    arrowprops=dict(arrowstyle='-', color=DIM))
    ax.set_title(f"the game image ${base:04X}-${base + len(data) - 1:04X}, 256 bytes a row: the token that "
                 "made each byte", color=FG, fontsize=9.5)

    bx = fig.add_axes([0.62, 0.52, 0.36, 0.33])
    names = ['stage2', 'stage3', 'game', 'patches', 'menu']
    shares = []
    for n in names:
        _, d, k, _, _ = classify(n)
        c = Counter(k)
        shares.append([100 * c[i] / len(d) for i in range(len(KINDS))])
    left = [0] * len(names)
    ys = list(range(len(names)))[::-1]
    for i, (label, colour) in enumerate(KINDS):
        vals = [s[i] for s in shares]
        bx.barh(ys, vals, left=left, color=colour, label=label, height=0.65)
        left = [l + v for l, v in zip(left, vals)]
    bx.set_yticks(ys)
    bx.set_yticklabels(names, color=FG, fontsize=9)
    bx.set_xlim(0, 100)
    bx.set_xlabel('% of the unpacked bytes', color=DIM, fontsize=9)
    bx.set_title('each block: who makes the bytes', color=FG, fontsize=9.5)
    bx.legend(fontsize=7.5, loc='upper center', bbox_to_anchor=(0.45, -0.25), ncol=2, facecolor=PANEL,
              labelcolor=FG, edgecolor='#444')

    cx = fig.add_axes([0.62, 0.08, 0.36, 0.2])
    c = Counter(min(n, 40) for n in lengths)
    xs = sorted(c)
    cx.bar(xs, [c[x] for x in xs], color='#5c8fd6')
    cx.set_xlabel('match length in the game block (40 = 40 or more)', color=DIM, fontsize=9)
    cx.set_ylabel('matches', color=DIM, fontsize=9)
    for x_ in (bx, cx):
        x_.set_facecolor(PANEL)
        x_.tick_params(colors=DIM, labelsize=8)
        for s in x_.spines.values():
            s.set_color('#444')
    lit = sum(1 for k in kinds if k < 2)
    mat = len(lengths)
    two = sum(1 for n in lengths if n <= 3)
    fig.suptitle(f"The game block: {mat} matches make {100 * (len(kinds) - lit) / len(kinds):.0f} % of its "
                 f"{len(kinds)} bytes, {100 * two / mat:.0f} % of them 2-3 bytes long;\nliterals make 9 % of the "
                 "sprites $6980-$A569 and a third of the code $A600-$D6A7", color=FG, fontsize=11.5,
                 x=0.02, ha='left')
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, facecolor=BG, dpi=100)
    print(a.out, 'matches', mat, 'literal bytes', lit, 'of', len(kinds), 'short', two)
    for n, s in zip(names, shares):
        print(n, ' '.join(f'{v:5.1f}' for v in s))


if __name__ == '__main__':
    main()
