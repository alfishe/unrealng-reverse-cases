#!/usr/bin/env python3
"""The tape as a picture (doc 03): the five ROM-speed blocks of Tujad.tzx on a time line (pilot, data, pause), and
where each data block lands in the 64 K, with the c1 frames at which the ROM's LD-BYTES started each block.

    python3 tools/fig_tape.py work/media/zxdb-Tujad.tzx/Tujad.tzx docs/img/load/tape.png

The timings come from the TZX (tools/tzxblocks.py); the frames from c1 (probe_frames exec $0556, write $4000,
$5B1F, $60C0, $FDFF: doc 3.4).
"""
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402

CPU = 3_500_000
NAMES = {1: 'header\nProgram "TUJAD"', 2: 'BASIC\n88 bytes', 3: 'header\nBytes "TUJAD"',
         4: 'picture + stub\n6944 bytes', 5: 'game, headerless\n40 256 bytes'}
DEST = {2: (0x5CCB, 0x5D22, 'PROG (BASIC)'), 4: (0x4000, 0x5B1F, r'\$4000-\$5B1F'), 5: (0x60C0, 0xFDFF, r'\$60C0-\$FDFF')}
C1 = {1: 245, 2: 515, 3: 694, 4: 949, 5: 2908}          # c1 frame of each LD-BYTES call
COLOURS = {1: '#8a8aa0', 2: '#5aa0ff', 3: '#8a8aa0', 4: '#f0c846', 5: '#5ad278'}


def main():
    src, out = sys.argv[1], sys.argv[2]
    blocks = [b for b in tzxblocks.parse(open(src, 'rb').read()) if b['id'] == 0x10]
    plt.rcParams.update({'font.size': 11, 'font.family': 'monospace'})
    fig = plt.figure(figsize=(10.5, 5.6), dpi=100, facecolor='#0e0e14')
    ax = fig.add_axes([0.04, 0.44, 0.94, 0.36], facecolor='#181820')
    mem = fig.add_axes([0.04, 0.08, 0.94, 0.13], facecolor='#181820')
    t = 0.0
    centres = {}
    for n, b in enumerate(blocks, 1):
        data = b['data']
        pilot = b['timing']['pilot_pulses'] * b['timing']['pilot'] / CPU
        bits = sum(bin(x).count('1') for x in data)
        body = (bits * 2 * 1710 + (len(data) * 8 - bits) * 2 * 855 + 667 + 735) / CPU
        ax.add_patch(Rectangle((t, 0.15), pilot, 0.7, color='#3c3c50'))
        ax.add_patch(Rectangle((t + pilot, 0.15), body, 0.7, color=COLOURS[n]))
        centres[n] = t + pilot + body / 2
        ax.text(t + pilot + body / 2, 1.05, f'{n}', ha='center', va='bottom', color='white', fontsize=12)
        text = NAMES[n].replace('\n', ', ') + f': {pilot + body:.2f} s, LD-BYTES at c1 frame {C1[n]}'
        if n == 5:
            ax.text(t + pilot + body / 2, 0.5, NAMES[n].replace('\n', ', ') + f'\n{pilot + body:.2f} s, LD-BYTES at c1 frame {C1[n]}',
                    ha='center', va='center', color='#101010', fontsize=11)
        else:
            ax.text(t + 2, -0.12 - 0.22 * (n - 1), f'{n} ' + text, ha='left', va='top', color=COLOURS[n] if n != 1
                    and n != 3 else '#d2d2dc', fontsize=10)
        t += pilot + body + b['pause'] / 1000
    ax.set_xlim(0, t)
    ax.set_ylim(-1.15, 1.4)
    ax.set_yticks([])
    ax.tick_params(colors='#d2d2dc')
    for s in ax.spines.values():
        s.set_color('#3c3c50')
    ax.set_xlabel('seconds from the first pilot tone (the pauses after each block included)', color='#d2d2dc')
    ax.xaxis.set_label_coords(0.5, 1.22)
    ax.xaxis.tick_top()
    ax.set_title('The tape: five ROM-speed blocks, 273.7 s with the pauses; dark = pilot tone, colour = data',
                 color='white', fontsize=13, pad=34)
    mem.set_xlim(0, 0x10000)
    mem.set_ylim(0, 1)
    mem.set_yticks([])
    mem.add_patch(Rectangle((0, 0), 0x4000, 1, color='#2a2a38'))
    mem.text(0x2000, 0.5, 'ROM', ha='center', va='center', color='#d2d2dc')
    for n, (lo, hi, label) in DEST.items():
        mem.add_patch(Rectangle((lo, 0), hi - lo + 1, 1, color=COLOURS[n]))
        mem.text((lo + hi) / 2, -0.25 if n != 2 else 1.25, label, ha='center', va='top' if n != 2 else 'bottom',
                 color='#d2d2dc', fontsize=10)
        con = matplotlib.patches.ConnectionPatch((centres[n], 0.15), ax.transData.inverted().transform(
            ax.transData.transform((centres[n], 0.15))), coordsA='data', axesA=ax)
        del con
        fig.add_artist(matplotlib.patches.ConnectionPatch(
            xyA=(centres[n] if n == 5 else 1.5 * n, -0.95 if n == 5 else -1.1), coordsA=ax.transData, xyB=((lo + hi) / 2, 1.0), coordsB=mem.transData,
            color=COLOURS[n], lw=1.2, arrowstyle='->'))
    mem.add_patch(Rectangle((0xFE00, 0), 0x200, 1, color='#e05a50'))
    mem.text(0xFFFF, 1.25, 'IM 2 table, sprite list (the game, not the tape)', ha='right', va='bottom',
             color='#d2d2dc', fontsize=10)
    mem.set_xticks([0, 0x4000, 0x8000, 0xC000, 0x10000])
    mem.set_xticklabels([r'\$0000', r'\$4000', r'\$8000', r'\$C000', r'\$FFFF'], color='#d2d2dc')
    for s in mem.spines.values():
        s.set_color('#3c3c50')
    fig.savefig(out, facecolor=fig.get_facecolor())
    print(out)


if __name__ == '__main__':
    main()
