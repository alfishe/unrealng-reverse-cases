#!/usr/bin/env python3
"""Doc 6.1 figures: every byte a stretch of passes changed, coloured by the moment it first changed, in the strip
buffer and on the screen (docs/img/heat-pass.png: one pass, frames 1000-1005; docs/img/heat-pass4.png: four passes,
frames 1000-1018). Drawn from the cache pass_anim.py --cache writes (TTD memory_at samples of the bot's game).

    python3 tools/pass_anim.py --work work/p2 --from 1000 --to 1005 --step 1750 --cache work/passanim/pass-1000-1005.npz docs/img/anim-pass.gif
    python3 tools/fig_pass.py work/passanim/pass-1000-1005.npz docs/img/heat-pass.png --one
    python3 tools/pass_anim.py --work work/p2 --from 1000 --to 1018 --step 3500 --cache work/passanim/pass-1000-1018.npz scratch.gif
    python3 tools/fig_pass.py work/passanim/pass-1000-1018.npz docs/img/heat-pass4.png

Left: the buffer `$8000-$BFFF` as stored, its four sets of 32 upright strips (doc 6.2) in a 2 x 2 grid. Right: the
screen at the end of the stretch, dimmed. A changed byte is painted whole (8 pixels) in the colour of its first
change; the colour bar under the panels is the time line.
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

plt.rcParams['text.parse_math'] = False

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zxscreen  # noqa: E402

FRAME_T = 69888
BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'


def buffer_xy(a):
    page, offset = a >> 8, a & 0xFF
    return (page & 1) * 256 + 8 * ((page - 0x80) >> 1), (offset >> 7) * 130 + 127 - (offset & 0x7F)


def screen_xy(a):
    a -= 0x4000
    return (a & 31) * 8, ((a >> 8) & 7) | ((a >> 2) & 0x38) | ((a >> 5) & 0xC0)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('cache')
    p.add_argument('out')
    p.add_argument('--one', action='store_true', help='one pass: name its three phases on the figure')
    args = p.parse_args()
    z = np.load(args.cache)
    first, samples, mem = z['first'], z['samples'], z['mem'].tobytes()
    start, end = int(z['start']), int(z['end'])
    n = len(samples)
    cmap = plt.get_cmap('turbo')

    def colour(i):
        return np.array(cmap(0.08 + 0.84 * i / max(1, n - 1))[:3])

    buf = np.full((258, 512, 3), 0.05)
    for a in range(0x8000, 0xC000):
        x, y = buffer_xy(a)
        if first[a] >= 0:
            buf[y, x:x + 8] = colour(first[a])
        else:
            v = mem[a]
            for b in range(8):
                buf[y, x + b] = 0.36 if v & (0x80 >> b) else 0.10
    scr = np.asarray(zxscreen.render(mem[0x4000:0x5B00], 1), dtype=float) / 255 * 0.33
    for a in range(0x4000, 0x5800):
        if first[a] >= 0:
            x, y = screen_xy(a)
            scr[y, x:x + 8] = colour(first[a])

    fig = plt.figure(figsize=(13, 6.3), dpi=100)
    gs = fig.add_gridspec(2, 2, width_ratios=[512, 256 * 1.33], height_ratios=[1, 0.05], hspace=0.28, wspace=0.06)
    ax, sx, cx = fig.add_subplot(gs[0, 0]), fig.add_subplot(gs[0, 1]), fig.add_subplot(gs[1, :])
    fig.patch.set_facecolor(BG)
    for a in (ax, sx, cx):
        a.set_facecolor(AX)
        a.tick_params(colors=DIM, labelsize=8.5)
    ax.imshow(buf, interpolation='nearest', aspect='auto')
    sx.imshow(scr, interpolation='nearest')
    for a in (ax, sx):
        a.set_xticks([])
        a.set_yticks([])
    for (x, y), name in (((0, 0), 'even pages, half $00'), ((256, 0), 'odd pages, half $00'),
                         ((0, 130), 'even pages, half $80'), ((256, 130), 'odd pages, half $80')):
        ax.add_patch(plt.Rectangle((x - 0.5, y - 0.5), 256, 128, fill=False, ec='#8a8fa0', lw=0.8))
        ax.text(x + 3, y + 3, name, color='#e8e0a0', fontsize=8, va='top',
                bbox=dict(boxstyle='round,pad=0.15', fc='#0c0c10', ec='none', alpha=0.8))
    ax.set_title('The strip buffer $8000-$BFFF as stored: 4 sets of 32 upright strips (grey: unchanged)', color=FG,
                 fontsize=10, loc='left')
    sx.set_title('The screen: changed bytes, the rest dimmed', color=FG, fontsize=10, loc='left')

    # the time line: one colour per sample, the frames marked
    cx.imshow(np.array([[colour(i) for i in range(n)]]), aspect='auto', extent=(0, n, 0, 1))
    cx.set_yticks([])
    ticks = [((f * FRAME_T - samples[0]) / (samples[1] - samples[0]), f) for f in range(start, end + 1)]
    step = 1 if len(ticks) <= 8 else 3
    cx.set_xticks([t for t, _ in ticks][::step])
    cx.set_xticklabels([f'frame {f}' for _, f in ticks][::step])
    cx.set_xlim(0, n)
    cx.set_title('colour = when the byte first changed (blue early, red late)', color=DIM, fontsize=9, loc='left')

    box = dict(boxstyle='round,pad=0.25', fc='#0c0c10', ec='none', alpha=0.85)
    arrow = dict(arrowstyle='->', color=FG, lw=0.9)
    changed_buf = [(a, first[a]) for a in range(0x8000, 0xC000) if first[a] >= 0]
    changed_scr = [(a, first[a]) for a in range(0x4000, 0x5800) if first[a] >= 0]
    if args.one:
        sprite = [buffer_xy(a) for a, i in changed_buf if i < n * 0.35]
        if sprite:
            x, y = np.median([s[0] for s in sprite]), np.median([s[1] for s in sprite])
            ax.annotate(f'1. frame 1001: the sprites and shadows drawn\ninto the set the next blit shows '
                        f'({sum(1 for _, i in changed_buf if i < n * 0.35)} bytes)', xy=(x, y), xytext=(10, 168),
                        color=FG, fontsize=9, bbox=box, arrowprops=arrow)
        sx.text(6, 6, f'2. frames 1001-1003: the blit, column by column\nfrom the left ({len(changed_scr):,} bytes '
                f'changed)', color=FG, fontsize=9, va='top', bbox=box)
        sx.annotate('', xy=(235, 50), xytext=(30, 150), arrowprops=dict(arrowstyle='->', color='#ffffff', lw=1.8))
        ax.text(10, 250, '3. frame 1003: the saved strips put back over the sprites (the same bytes: a byte keeps\n'
                'the colour of its first change)', color=DIM, fontsize=8.5, va='bottom', bbox=box)
        title = 'One pass, frames 1000-1005: the sprites go into the buffer first, then the blit copies it left to right'
    else:
        # the strips the scroller rewrote: buffer columns (a strip of a set) with most of their 128 bytes changed
        column = {}
        for a, _ in changed_buf:
            x, y = buffer_xy(a)
            column[(x, y // 130)] = column.get((x, y // 130), 0) + 1
        bars = sorted(k for k, c in column.items() if c >= 64)
        for x, half in bars[:2]:
            ax.annotate('', xy=(x + 4, half * 130 + 100), xytext=(258, 228),
                        arrowprops=dict(arrowstyle='->', color=FG, lw=0.9))
        ax.text(258, 236, 'upright bars: the strips the scroller rewrites, one phase a pass\n'
                'patches: each pass\'s sprites, in the set that pass\'s blit shows', color=FG, fontsize=9,
                ha='center', va='top', bbox=box)
        sx.text(128, 194, 'blue: most bytes change in the first pass\'s blit;\nthe other colours: bytes that first '
                'changed later', color=FG, fontsize=8.5, ha='center', va='top', bbox=box)
        print('bars', bars)
        title = (f'Four passes, frames {start}-{end}: the sprites land in a different set each pass, '
                 'the scroller rewrites one strip phase a pass')
    fig.suptitle(title, color=FG, fontsize=12, x=0.125, ha='left', y=0.98)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(args.out, 'buffer', len(changed_buf), 'screen', len(changed_scr))


if __name__ == '__main__':
    main()
