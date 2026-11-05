#!/usr/bin/env python3
"""Doc 02 figure: the Z80's 64 K at each stage of both releases (docs/img/arch/memmap-stages.png).

One column a stage, $0000 at the top; each range what is there at that moment, as doc 02 2.3 lists it from the
recordings (r98, r99: TTD memory_at at the frames under each column, and the arrivals of `re_session.py stages`).
The '99's 128 K pages that matter are two extra columns: page 1 (the start-up menu as stored) and page 3 (the
texts), both at $C000.

    python3 tools/fig_zs_memmap.py --out docs/img/arch/memmap-stages.png
"""
import argparse
import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
K = {'rom': '#5a5d6a', 'screen': '#5c8fd6', 'basic': '#7a7d8c', 'intro': '#c77ddb', 'game': '#4caf50',
     'packed': '#3d5f99', 'menu': '#d9a441', 'text': '#59c9a5', 'world': '#a07a3a', 'music': '#e5534b',
     'loader': '#9b7fd1'}

STAGES = [
    ("'98 intro\nr98 3000", [(0x0000, 0x3FFF, 'ROM', 'rom'), (0x4000, 0x5AFF, 'screen', 'screen'),
                             (0x5D3B, 0x5FFF, 'BASIC, REM loader', 'basic'),
                             (0x6780, 0x80FF, 'the game:\nread after\nthe intro', None),
                             (0x8100, 0x8201, 'IM 2 table $8100', 'loader'),
                             (0xC000, 0xD88E, 'PT3 player + tune', 'music'),
                             (0xD88F, 0xE9FF, 'the intro,\nscroller text', 'intro')]),
    ("'98 play\nr98 5900", [(0x0000, 0x3FFF, 'ROM', 'rom'), (0x4000, 0x5AFF, 'screen', 'screen'),
                            (0x5B00, 0x677F, 'ViewBuffer', 'screen'), (0x6780, 0xD7D2, 'the game image', 'game'),
                            (0xD800, 0xDCFF, 'radar, robots', 'world'), (0xDD00, 0xFCFF, 'Map', 'world'),
                            (0xFD00, 0xFFFF, 'variables, IM 2', 'world')]),
    ("'99 intro\nr99 1300", [(0x0000, 0x3FFF, 'ROM', 'rom'), (0x4000, 0x5AFF, 'screen', 'screen'),
                             (0x5B00, 0x5B99, 'depacker', 'loader'), (0x5D3B, 0x5D68, 'BASIC', 'basic'),
                             (0x61A8, 0x7D86, 'stage 2: the intro,\nscroller text', 'intro'),
                             (0x7D87, 0x8A86, 'RLE decoder\n+ pictures', 'intro'),
                             (0x8A87, 0xA586, 'picture buffer', 'intro'), (0xB000, 0xB1B3, 'IM 2 table $B000', 'loader'),
                             (0xC000, 0xCCFF, 'Sound Tracker\nplayer + tune', 'music')]),
    ("'99 loading\nr99 2400", [(0x0000, 0x3FFF, 'ROM', 'rom'), (0x4000, 0x5AFF, 'screen', 'screen'),
                               (0x5B00, 0x5B99, 'depacker', 'loader'),
                               (0x61A8, 0x67EB, 'stage 3', 'loader'),
                               (0x6780, 0xD7D2, 'the game,\nunpacking\nfrom the top\ndown', 'packed')]),
    ("'99 menu\nr99 3000", [(0x0000, 0x3FFF, 'ROM', 'rom'), (0x4000, 0x5AFF, 'screen', 'screen'),
                            (0x6700, 0x677F, 'copy stub $6700', 'loader'),
                            (0x6780, 0xD7D2, 'the game image', 'game'),
                            (0xD800, 0xE7FF, 'the start-up\nmenu (copy)', 'menu'),
                            (0xFD00, 0xFFFF, 'variables, IM 2', 'world')]),
    ("'99 play\nr99 6450", [(0x0000, 0x3FFF, 'ROM', 'rom'), (0x4000, 0x5AFF, 'screen', 'screen'),
                            (0x5B00, 0x677F, 'ViewBuffer', 'screen'), (0x6780, 0xD7D2, 'the game image', 'game'),
                            (0xD800, 0xDCFF, 'radar, robots', 'world'), (0xDD00, 0xFCFF, 'Map', 'world'),
                            (0xFD00, 0xFFFF, 'variables, IM 2', 'world')]),
    ("'99 page 1\n(at $C000)", [(0xD800, 0xE6F3, 'the menu\nas stored', 'menu')]),
    ("'99 page 3\n(at $C000)", [(0xC000, 0xCEFF, 'NEabout', 'text'), (0xCF00, 0xE4FF, 'NEdescri', 'text'),
                                (0xE500, 0xE6FF, 'NEgreets', 'text'), (0xE700, 0xFFFF, 'NEadvice', 'text')]),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    fig, ax = plt.subplots(figsize=(12, 7.6))
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(PANEL)
    w = 0.86
    for i, (title, ranges) in enumerate(STAGES):
        for s, e, label, kind in ranges:
            if kind is None:
                ax.text(i, (s + e) / 2, label, ha='center', va='center', fontsize=7.5, color=DIM, style='italic')
                continue
            ax.add_patch(plt.Rectangle((i - w / 2, s), w, e - s + 1, color=K[kind], ec=BG, lw=0.8))
            if e - s > 0x500:
                ax.text(i, (s + e) / 2, label, ha='center', va='center', fontsize=7.5, color='#101010')
            else:
                ax.text(i + w / 2 + 0.02, (s + e) / 2, label, ha='left', va='center', fontsize=6.5, color=FG)
    ax.set_xlim(-0.6, len(STAGES) - 0.4)
    ax.set_ylim(0x10000, 0)
    ax.set_xticks(range(len(STAGES)))
    ax.set_xticklabels([t for t, _ in STAGES], color=FG, fontsize=8.5)
    ax.xaxis.tick_top()
    ax.set_yticks(range(0, 0x10001, 0x1000))
    ax.set_yticklabels([f'${v:04X}' for v in range(0, 0x10001, 0x1000)], color=DIM, fontsize=8, family='monospace')
    for s in ax.spines.values():
        s.set_color('#444')
    ax.axvline(5.5, color=FG, lw=1, ls=':')
    fig.suptitle("Memory at each stage: the game image $6780-$D7D2 stays put in both releases; the '99's intro and "
                 "loader live below it,\nits start-up menu is kept in page 1 and copied over the radar and the map "
                 "at $D800 each time the menu is entered", color=FG, fontsize=11.5, x=0.02, ha='left')
    fig.tight_layout()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, facecolor=BG, dpi=100)
    print(a.out)


if __name__ == '__main__':
    main()
