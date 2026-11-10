#!/usr/bin/env python3
"""The tape as a picture (doc 03): the seven ROM-speed blocks of "Sim City.tzx" on a time line (pilot, data,
pause), which loader reads each one, which are encrypted, and where each lands in the 64 K, with the move of
code2 from $4000 to $5B00.

    python3 tools/fig_tape.py "work/media/zxdb-SimCity.tzx/Sim City.tzx" docs/img/load/tape.png

The timings come from the TZX (tools/tzxblocks.py); the c1 frames from probe_frames over work/stage1/c1
(exec $0556 for the ROM's four loads, exec $FEBD for LoadBlock's three: doc 3.6).
"""
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle, ConnectionPatch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402

CPU = 3_500_000
NAMES = {1: 'header "Simcity"', 2: 'BASIC, 144 bytes', 3: 'header "loader"', 4: 'loader, 512 bytes',
         5: 'loading screen\n6912 bytes', 6: 'code1, 37 633 bytes\n$6B00-$FE00', 7: 'code2 + mover\n4128 bytes'}
DEST = {2: (0x5CCB, 0x5D5A, 'BASIC'), 4: (0xFE00, 0xFFFF, 'loader'), 5: (0x4000, 0x5AFF, 'screen'),
        6: (0x6B00, 0xFE00, 'code1 $6B00-$FE00'), 7: (0x4000, 0x501F, 'code2')}
COLOURS = {1: '#8a8aa0', 2: '#5aa0ff', 3: '#8a8aa0', 4: '#e05a50', 5: '#f0c846', 6: '#5ad278', 7: '#c878f0'}
READER = {1: 'ROM', 2: 'ROM', 3: 'ROM', 4: 'ROM', 5: 'LoadBlock', 6: 'LoadBlock', 7: 'LoadBlock'}
FRAMES = {}  # filled from the command line: N=FRAME ...


def tex(s):
    return s.replace('$', r'\$')


def main():
    src, out = sys.argv[1], sys.argv[2]
    for a in sys.argv[3:]:
        k, v = a.split('=')
        FRAMES[int(k)] = int(v)
    blocks = [b for b in tzxblocks.parse(open(src, 'rb').read()) if b['id'] == 0x10]
    plt.rcParams.update({'font.size': 11, 'font.family': 'monospace'})
    fig = plt.figure(figsize=(10.5, 7.0), dpi=100, facecolor='#0e0e14')
    ax = fig.add_axes([0.03, 0.36, 0.95, 0.42], facecolor='#181820')
    mem = fig.add_axes([0.03, 0.115, 0.95, 0.12], facecolor='#181820')
    t = 0.0
    spans = {}
    for n, b in enumerate(blocks, 1):
        data = b['data']
        pilot = b['timing']['pilot_pulses'] * b['timing']['pilot'] / CPU
        bits = sum(bin(x).count('1') for x in data)
        body = (bits * 2 * 1710 + (len(data) * 8 - bits) * 2 * 855 + 667 + 735) / CPU
        ax.add_patch(Rectangle((t, 0.15), pilot, 0.7, color='#3c3c50'))
        enc = n >= 5
        ax.add_patch(Rectangle((t + pilot, 0.15), body, 0.7, facecolor=COLOURS[n],
                               hatch='//' if enc else None, edgecolor='#101010' if enc else COLOURS[n], lw=0))
        spans[n] = (t, t + pilot + body)
        if n in (5, 6):
            ax.text(t + pilot + body / 2, 0.5, tex(NAMES[n]) + f'\n{pilot + body:.1f} s',
                    ha='center', va='center', color='#101010', fontsize=10,
                    bbox=dict(facecolor=COLOURS[n], edgecolor='none', pad=1))
        ax.text(t + pilot + body / 2, 0.92, f'{n}', ha='center', va='bottom', color='white', fontsize=12)
        t += pilot + body + b['pause'] / 1000
    total = t
    # the list of the blocks under the line
    for n in range(1, 8):
        b = blocks[n - 1]
        a, e = spans[n]
        fr = f', called at c1 frame {FRAMES[n]}' if n in FRAMES else ''
        name = NAMES[n].replace('\n', ', ')
        ax.text(1, -0.06 - 0.21 * (n - 1), f'{n} {name}: {e - a:.2f} s, flag ${b["data"][0]:02X}, '
                f'{READER[n]}{fr}'.replace('$', r'\$'), ha='left', va='top',
                color=COLOURS[n] if n not in (1, 3) else '#d2d2dc', fontsize=10)
    ax.set_xlim(0, total)
    ax.set_ylim(-1.55, 1.25)
    ax.set_yticks([])
    ax.tick_params(colors='#d2d2dc')
    for s in ax.spines.values():
        s.set_color('#3c3c50')
    ax.xaxis.tick_top()
    ax.set_xlabel('seconds from the first pilot tone, the pauses after each block included', color='#d2d2dc')
    ax.xaxis.set_label_position('top')
    fig.suptitle(f'The tape: seven ROM-speed blocks, {total:.1f} s; the last three headerless, flag $00, encrypted'
                 .replace('$', r'\$'), color='white', fontsize=13, y=0.975)
    fig.text(0.03, 0.905, 'dark: pilot tone (8063 pulses on a flag $00 block, 3223 on $FF); colour: data; '
             'hatched: encrypted'.replace('$', r'\$'), color='#d2d2dc', fontsize=10)
    mem.set_xlim(0x4000, 0x10000)
    mem.set_ylim(0, 1)
    mem.set_yticks([])
    mem.add_patch(Rectangle((0x5B00, 0), 0x1000, 1, facecolor='#c878f0', alpha=0.45))
    for n, (lo, hi, label) in DEST.items():
        y0, h = (0.5, 0.5) if n == 7 else (0, 0.5) if n == 5 else (0, 1)
        mem.add_patch(Rectangle((lo, y0), hi - lo + 1, h, color=COLOURS[n]))
        a, e = spans[n]
        if n < 5:
            continue
        fig.add_artist(ConnectionPatch(xyA=((a + e) / 2, -1.55), coordsA=ax.transData,
                                       xyB=((lo + hi) / 2, 1.0), coordsB=mem.transData,
                                       color=COLOURS[n], lw=1.2, arrowstyle='->'))
    mem.text(0x4500, 0.75, 'code2', ha='center', va='center', color='#101010', fontsize=10)
    mem.text(0x4D80, 0.25, 'screen', ha='center', va='center', color='#101010', fontsize=10)
    mem.text(0x9400, 0.5, tex('code1 $6B00-$FE00'), ha='center', va='center', color='#101010', fontsize=10)
    mem.text(0x6300, 0.5, 'moved\ncode2', ha='center', va='center', color='white', fontsize=10)
    fig.add_artist(ConnectionPatch(xyA=(0x4A00, 0.75), coordsA=mem.transData, xyB=(0x5B00, 0.75),
                                   coordsB=mem.transData, color='white', lw=1.4, arrowstyle='->'))
    ticks = [0x4000, 0x5B00, 0x6B00, 0x8000, 0xA000, 0xC000, 0xE000, 0xFE00]
    mem.set_xticks(ticks)
    mem.set_xticklabels([f'\\${x:04X}' for x in ticks], color='#d2d2dc', fontsize=10)
    for s in mem.spines.values():
        s.set_color('#3c3c50')
    fig.text(0.03, 0.012, tex('where each block lands ($4000-$FFFF); the mover copies code2 $4000-$4FFF to '
                              '$5B00-$6AFF (white arrow)'), color='#d2d2dc', fontsize=10)
    fig.savefig(out, facecolor=fig.get_facecolor())
    print(out, f'{total:.2f} s')


if __name__ == '__main__':
    main()
