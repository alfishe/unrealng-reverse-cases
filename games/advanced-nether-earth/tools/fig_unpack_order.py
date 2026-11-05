#!/usr/bin/env python3
"""Doc 06 figure: the order in which ANE's screen depacker writes a picture: a third at a time, column by column,
each column's 64 lines top down, the attributes last.

    python3 tools/fig_unpack_order.py --out docs/img/render/unpack-order.png \
        --trace "the title picture (d1, frames 8215-8231)=work/docR/d1/traces/8215_0-8232_0.uatr" \
        --trace "Dead End's picture (r3, frames 10-25)=work/docR/r3/traces/0_0-100_0.uatr@D757-D7E5"

Per trace: the picture as the trace's screen writes leave it (the bytes written, on black), and every screen byte
coloured by the moment of its last write in the trace (dark: early, light: late). `@LO-HI` keeps only the writes of
instructions in that address range (the depacker), so a screen clear before it does not count.
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ane_trace as A  # noqa: E402
import kitlib as K  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'


def collect(path, rng):
    trace = A.load(path)
    mem = bytearray(0x10000)
    when = {}
    order = 0
    first = last = None
    for x in trace.instructions:
        if rng and not rng[0] <= x.pc < rng[1]:
            continue
        for c in x.cycles:
            if c.tag in 'WE' and 0x4000 <= c.address < 0x5B00:
                mem[c.address] = c.value
                when[c.address] = order
                order += 1
                f, t = trace.cycle_t(x, c)
                first = first or (f, t)
                last = (f, t)
    return mem, when, order, first, last


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--trace', action='append', required=True, help='TITLE=FILE[@LO-HI]')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    rows = []
    for spec in args.trace:
        title, _, rest = spec.partition('=')
        path, _, r = rest.partition('@')
        rng = tuple(int(v, 16) for v in r.split('-')) if r else None
        rows.append((title, collect(path, rng)))
    fig, axes = plt.subplots(len(rows), 3, figsize=(14, 3.6 * len(rows)), dpi=100,
                             gridspec_kw={'width_ratios': [1, 1, 1]})
    axes = np.atleast_2d(axes)
    fig.patch.set_facecolor(BG)
    for (title, (mem, when, n, first, last)), ax in zip(rows, axes):
        pic = np.array(K.render_screen(mem, 0x4000))
        order = np.full((192, 256), np.nan)
        attr = np.full((24, 32), np.nan)
        for a, k in when.items():
            if a < 0x5800:
                y = K.screen_line(a)
                order[y, (a & 31) * 8:(a & 31) * 8 + 8] = k / n
            else:
                attr[(a - 0x5800) // 32, (a - 0x5800) % 32] = k / n
        ax[0].imshow(pic, interpolation='nearest')
        ax[1].imshow(order, cmap='viridis', vmin=0, vmax=1, interpolation='nearest')
        im = ax[2].imshow(np.kron(attr, np.ones((8, 8))), cmap='viridis', vmin=0, vmax=1, interpolation='nearest')
        for a in ax:
            a.set_xticks([])
            a.set_yticks([])
            for s in a.spines.values():
                s.set_color('#444')
        for y in (64, 128):
            ax[1].axhline(y - 0.5, color='#ffffff', lw=0.6, ls='--')
        ax[0].set_title(f'{title}: {n} bytes written,\nframe {first[0]}:{first[1]} to {last[0]}:{last[1]}',
                        color=FG, fontsize=10, loc='left')
        ax[1].set_title('the 6144 pixel bytes: order of write', color=FG, fontsize=10, loc='left')
        ax[2].set_title('the 768 attributes: order of write', color=FG, fontsize=10, loc='left')
    cb = fig.colorbar(im, ax=axes[:, 1:].ravel().tolist(), shrink=0.6, pad=0.01)
    cb.set_label('order of the write in the depacker\'s output (0 first, 1 last)', color=DIM, fontsize=9)
    cb.ax.tick_params(colors=DIM, labelsize=8)
    fig.suptitle('The screen depacker writes a picture a third at a time, column by column, then the attributes\n'
                 'middle: thirds top down (dashed), within a third the columns left to right; right: all after the '
                 'pixels, in screen order', color=FG, fontsize=12, x=0.01, ha='left')
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')


if __name__ == '__main__':
    main()
