#!/usr/bin/env python3
"""Difference report figure (work/diff/shell.md): Nether Earth's 48K in play next to ANE's eight banks in play, one
scale (16 K = one bar): which addresses changed their use, and what the five extra banks hold.

    python3 tools/fig_diff_shell_memory.py --out docs/img/diff/shell-memory.png

The regions are the play maps of the two cases, with their witnesses:
  Nether Earth: ../nether-earth/tools/memmap.txt (stage `play`) and the module ranges of its src/game/game.ann
                (doc 02 2.2, 2.6): the music module $C4A7-$C848 split into its player, tune and colour cycle;
  ANE:          tools/fig_banks.txt (stage `play`) and src/game/game.ann (@module, the @equ variables; world.asm on
                $FDFD-$FFFF: "never written by the game and zero in play").
The numbered marks are the five places where the same address holds something else (the text's table).
"""
import argparse
import sys
import textwrap

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Patch, Rectangle  # noqa: E402

import fig_diff_shell_common as C  # noqa: E402

NE_MAP = [  # start, end (inclusive), kind, label
    (0x4000, 0x5AFF, 'screen', 'the screen'),
    (0x5B00, 0x677F, 'work', 'ViewBuffer'),
    (0x6780, 0x697F, 'graphics', 'Font $6780 (64 glyphs)'),
    (0x6980, 0x7FFF, 'graphics', 'sprites'),
    (0x8000, 0xA569, 'graphics', 'sprites'),
    (0xA56A, 0xA5FF, 'free', 'zeros $A56A'),
    (0xA600, 0xBDA8, 'code', 'game code from Start $A600'),
    (0xBDA9, 0xC0FF, 'data', 'the level'),
    (0xC100, 0xC4A6, 'code', 'main menu, tape load / save, keys'),
    (0xC4A7, 0xC664, 'code', 'menu music player'),
    (0xC665, 0xC81F, 'music', 'the menu tune'),
    (0xC820, 0xC848, 'code', 'title colours'),
    (0xC849, 0xD6A7, 'code', 'construction, view, print, radar'),
    (0xD6A8, 0xD7D2, 'data', 'tables'),
    (0xD7D3, 0xFCFF, 'work', 'shots, radar, robots, map'),
    (0xFD00, 0xFDFC, 'work', 'variables'),
    (0xFDFD, 0xFF00, 'system', 'IM 2: JP $FDFD, table $FE00'),
    (0xFF01, 0xFFA8, 'work', 'Buildings'),
    (0xFFA9, 0xFFFF, 'stack', 'stack'),
]
ANE_MAP = {
    5: [(0x4000, 0x5AFF, 'screen', 'the screen'),
        (0x5B00, 0x677F, 'work', 'ViewBuffer'),
        (0x6780, 0x67FF, 'code', 'music glue $6780'),
        (0x6800, 0x6900, 'system', 'IM 2 table $6800'),
        (0x6901, 0x697F, 'code', 'GameSave, ImJump $6969'),
        (0x6980, 0x7FFF, 'graphics', 'sprites')],
    2: [(0x8000, 0xA569, 'graphics', 'sprites'),
        (0xA56A, 0xA5FF, 'code', 'GameLoad..Restart $A56A'),
        (0xA600, 0xBDA8, 'code', 'game code from Start $A600'),
        (0xBDA9, 0xBFFF, 'data', 'the level')],
    0: [(0xC000, 0xC0FF, 'data', 'the level'),
        (0xC100, 0xC4A7, 'code', 'main menu, disk calls'),
        (0xC4A8, 0xC4FF, 'free', 'free'),
        (0xC500, 0xC6FF, 'graphics', 'Cyrillic font $C500'),
        (0xC700, 0xC848, 'free', 'free'),
        (0xC849, 0xD6A7, 'code', 'construction, view, print, radar'),
        (0xD6A8, 0xD7D2, 'data', 'tables'),
        (0xD7D3, 0xFCFF, 'work', 'shots, radar, robots, map'),
        (0xFD00, 0xFDFC, 'work', 'variables'),
        (0xFDFD, 0xFF00, 'free', 'unused (zero)'),
        (0xFF01, 0xFFA8, 'work', 'Buildings'),
        (0xFFA9, 0xFFFF, 'stack', 'stack')],
    1: [(0xC000, 0xCA44, 'code', 'SoundTrack player'),
        (0xCA45, 0xD8E0, 'music', 'the tune TAIGA'),
        (0xD8E1, 0xE21A, 'code', 'title cards (once)'),
        (0xE21B, 0xFFFF, 'free', 'free')],
    3: [(0xC000, 0xCA42, 'code', 'player (a copy)'),
        (0xCA43, 0xD2EE, 'music', 'NETHER EARTH (END)'),
        (0xD2EF, 0xFE1E, 'sequence', 'Dead End $D2EF,\nmenu picture $E73B'),
        (0xFE1F, 0xFFFF, 'free', '')],
    4: [(0xC000, 0xCD2B, 'code', 'disk module'),
        (0xCD2C, 0xFFFF, 'packed', 'leftover game block')],
    6: [(0xC000, 0xF62C, 'packed', 'Final Cut block'),
        (0xF62D, 0xF636, 'free', ''),
        (0xF637, 0xFEE7, 'packed', 'disk module block'),
        (0xFEE8, 0xFFFF, 'free', '')],
    7: [(0xC000, 0xCE08, 'packed', 'game starter block'),
        (0xCE09, 0xFFFF, 'data', 'boot image (unused)')],
}
ANE_WHEN = {5: '$4000 always', 2: '$8000 always', 0: '$C000 in play', 1: 'every\ninterrupt', 3: 'Dead End, menu picture',
            4: 'disk save, load', 6: 'a won game', 7: 'never again'}
MARKS = [  # number, address range, what changed
    (1, 0x6780, 0x697F, 'Font -> music glue, IM 2 table, disk glue'),
    (2, 0xA56A, 0xA5FF, 'zeros -> GameLoad, GameEntry, Restart'),
    (3, 0xC100, 0xC4A7, 'tape load / save -> disk calls (tape code left, dead)'),
    (4, 0xC4A7, 0xC848, 'beeper menu music -> Cyrillic font, free'),
    (5, 0xFDFD, 0xFF00, 'IM 2 jump and table -> unused'),
]


def spread(ys, gap=0.03):
    """label heights moved apart by at least gap, in order, kept near their marks"""
    out = []
    for y in sorted(ys, reverse=True):
        out.append(min(y, out[-1] - gap) if out else y)
    shift = max(0.0, (out[-1] if out else 0) - min(ys or [0])) if False else 0
    return [o + shift for o in out]


def bar(ax, x, w, base, regions, labels_right):
    side = []
    for a, b, kind, label in regions:
        y0, y1 = (a - base) / 0x4000, (b + 1 - base) / 0x4000
        ax.add_patch(Rectangle((x, 1 - y1), w, y1 - y0, facecolor=C.KIND[kind], edgecolor=C.BG, lw=0.8))
        if not label:
            continue
        if y1 - y0 > 0.075 or (y1 - y0 > 0.03 and len(label) <= 10):
            ax.text(x + 0.04, 1 - (y0 + y1) / 2, '\n'.join(textwrap.wrap(label, 13)), color='#f2f2f2', fontsize=7.8,
                    va='center', ha='left')
        elif labels_right is not None:
            side.append((1 - (y0 + y1) / 2, label))
    if not side:
        return
    side.sort(key=lambda s: -s[0])
    placed = spread([y for y, _ in side])
    for (y, label), py in zip(side, placed):
        sx = x + w + 0.05 if labels_right else x - 0.05
        ax.plot([x + w if labels_right else x, sx], [y, py], color='#666a75', lw=0.6)
        ax.text(sx + (0.01 if labels_right else -0.01), py, label, color=C.DIM, fontsize=7, va='center',
                ha='left' if labels_right else 'right')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=C.out_path('shell-memory.png'))
    args = p.parse_args()
    fig, ax = plt.subplots(figsize=(16, 9.4), dpi=100)
    C.style(fig, (ax,))
    ax.set_axis_off()
    w = 0.95
    pairs = [(0x4000, 5), (0x8000, 2), (0xC000, 0)]
    x = 0.0
    for base, bank in pairs:
        ne = [(max(a, base), min(b, base + 0x3FFF), k, l) for a, b, k, l in NE_MAP if a <= base + 0x3FFF and b >= base]
        bar(ax, x, w, base, ne, labels_right=False)
        bar(ax, x + w + 0.2, w, base, ANE_MAP[bank], labels_right=True)
        ax.text(x + w + 0.08, 1.07, f'Nether Earth\n${base:04X}-${base + 0x3FFF:04X}', color=C.NE_COL, ha='right',
                fontsize=8.5)
        ax.text(x + w + 0.12, 1.07, f'ANE bank {bank}\n{ANE_WHEN[bank]}', color=C.ANE_COL, ha='left',
                fontsize=8.5)
        for n, a, b, _ in MARKS:
            if base <= a <= base + 0x3FFF:
                y = 1 - ((a + b) / 2 - base) / 0x4000
                ax.add_patch(Rectangle((x - 0.005, 1 - (b + 1 - base) / 0x4000), 2 * w + 0.21,
                                       (b + 1 - a) / 0x4000, fill=False, edgecolor='#ffffff', lw=1.3, ls='--'))
                ax.text(x + w + 0.1, y, str(n), color='#ffffff', fontsize=9, ha='center', va='center',
                        fontweight='bold', bbox=dict(boxstyle='circle,pad=0.15', fc='#000000', ec='#ffffff', lw=0.8))
        x += 2 * w + 2.3
    x -= 0.6
    ax.text(x, 1.19, 'only ANE: five more banks, each paged at $C000', color=C.ANE_COL, fontsize=10)
    for bank in (1, 3, 4, 6, 7):
        bar(ax, x, w, 0xC000, ANE_MAP[bank], labels_right=None)
        ax.text(x + w / 2, 1.07, f'bank {bank}\n' + ANE_WHEN[bank].replace(', ', ',\n'), color=C.ANE_COL,
                ha='center', fontsize=7.5)
        x += w + 0.22
    ax.set_xlim(-1.6, x + 0.1)
    ax.set_ylim(-0.42, 1.3)
    ax.text(-1.55, 1.25, 'The 48K game sits where it was: same screen, buffer, sprites, code, world and variables; '
            'five places changed, and 80 K of banks were added', color=C.FG, fontsize=13)
    for i, (n, a, b, what) in enumerate(MARKS):
        ax.text(-0.7 + (i % 3) * 7.0, -0.12 - (i // 3) * 0.08, f'{n}  ${a:04X}-${b:04X}: {what}', color=C.FG,
                fontsize=9.2)
    handles = [Patch(color=C.KIND[k], label=k) for k in ('screen', 'code', 'data', 'graphics', 'work', 'system',
                                                         'stack', 'music', 'sequence', 'packed', 'free')]
    ax.legend(handles=handles, loc='lower center', ncol=11, fontsize=8.5, bbox_to_anchor=(0.5, 0.0), frameon=False,
              labelcolor='#d6d8e0')
    ax.text(-0.7, -0.33, 'One bar = 16 K, top = the lowest address. Dashed boxes: the same addresses, a different use. '
            '"sequence": an ending program; "packed": a HRUM block waiting to be unpacked.', color=C.DIM,
            fontsize=8.5)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print('wrote', args.out)


if __name__ == '__main__':
    sys.exit(main())
