#!/usr/bin/env python3
"""Doc 04 / 09 figure: what the play interrupt does in each frame of a turn, against the Pentagon's beam.

    python3 tools/fig_interrupt.py --trace work/docR/d1/traces/13005_0-13017_0.uatr \
        --out docs/img/loop/interrupt-frames.png

One row a frame of the trace: the interrupt from its first instruction ($6969) to its RET, every instruction
coloured by the routine it belongs to (the radar, PlayInterrupt's own counting, the music player's parts in bank 1),
every AY data write a tick, and the T-states where the beam starts the paper (17 988) and the view (19 780).
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ane_trace as A  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'
PARTS = [  # key, label, colour
    ('count', 'PlayInterrupt: counters, the shot sound, PlayMusic\'s paging', '#7a7f8c'),
    ('radar', 'ShowRadar: 16 radar lines and their attributes', '#4caf50'),
    ('play', 'PlayFrame $C2B6, ApplyPending: the tick count, rows taken', '#80deea'),
    ('chan', 'ChADecode/ChBDecode/ChCDecode: a channel\'s next row', '#ffb74d'),
    ('tick', 'ChAOff/ChBOff/ChCOff: samples, ornaments, tone, volume', '#26c6da'),
    ('out', 'WriteAy, AyOut $C736: the AY register writes', '#e5534b'),
]
COLOUR = {k: c for k, l, c in PARTS}


def part(pc, bank, ph):
    if ph == 'music':
        if 0xC736 <= pc <= 0xC7A8 or 0xC2A7 <= pc < 0xC2B6:
            return 'out'
        if 0xC47B <= pc < 0xC736:
            return 'chan'
        if 0xC2B6 <= pc < 0xC47B or pc < 0xC0D8:
            return 'play'
        return 'tick'
    if 0xD300 <= pc < 0xD340 or 0xD460 <= pc < 0xD560 or 0x6A00 <= pc < 0x6780:
        return 'radar'
    return 'count'


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--trace', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--radar', default='D59E-D5C4,D32A-D339',
                   help='the radar routines\' address ranges in the trace\'s game (hex lo-hi, comma separated)')
    args = p.parse_args()
    radar = [tuple(int(v, 16) for v in r.split('-')) for r in args.radar.split(',')]
    trace = A.load(args.trace)
    rows = {}   # frame -> [[t0, t1, part]], [t of AY data writes], end t
    for x, bank, ph in A.walk(trace):
        if ph not in ('int', 'music') or x.t > 30000:
            continue
        f = x.frame
        r = rows.setdefault(f, [[], [], 0])
        if ph == 'music':
            k = part(x.pc, bank, ph)
        elif any(lo <= x.pc < hi for lo, hi in radar):
            k = 'radar'
        else:
            k = 'count'
        if r[0] and r[0][-1][2] == k and x.t - r[0][-1][1] < 400:
            r[0][-1][1] = x.t + 8
        else:
            r[0].append([x.t, x.t + 8, k])
        r[2] = max(r[2], x.t + 10)
        for c in x.cycles:
            if c.tag == 'O' and c.address & 0xC002 == 0x8000:
                r[1].append(trace.cycle_t(x, c)[1])
    frames = sorted(f for f in rows if rows[f][0][0][0] < 200)
    fig, ax = plt.subplots(figsize=(12.5, 6.6), dpi=110)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(AX)
    ax.tick_params(colors=DIM, labelsize=9)
    for s in ax.spines.values():
        s.set_color('#444')
    ends, music = [], []
    for i, f in enumerate(frames):
        spans, outs, end = rows[f]
        for t0, t1, k in spans:
            ax.barh(i, t1 - t0, left=t0, height=0.7, color=COLOUR[k], linewidth=0)
        ax.vlines(outs, i + 0.38, i + 0.52, color='#ffffff', lw=0.8)
        m = [s for s in spans if s[2] in ('play', 'chan', 'tick', 'out')]
        mt = (m[-1][1] - m[0][0]) if m else 0
        music.append(mt)
        ends.append(end)
        ax.text(end + 250, i, f'ends at T {end}; music {mt} T, {len(outs)} AY writes', color=DIM, fontsize=8,
                va='center')
    for t, label, ha, dx in ((A.PAPER_T, 'the beam reaches\nthe paper, T 17 988', 'right', -150),
                             (A.PAPER_T + 8 * A.LINE_T, 'the view\'s first\nline, T 19 780', 'left', 150)):
        ax.axvline(t, color='#ffffff', lw=0.8, ls='--', alpha=0.7)
        ax.text(t + dx, len(frames) - 0.2, label, color=FG, fontsize=8.5, va='top', ha=ha)
    ax.set_yticks(range(len(frames)))
    ax.set_yticklabels([str(f) for f in frames])
    ax.set_ylim(len(frames) - 0.2 + 1.0, -0.8)
    ax.set_xlim(0, 24000)
    ax.set_ylabel('frame of the recording d1 (one row an interrupt)', color=DIM, fontsize=9)
    ax.set_xlabel('T-states from the interrupt (white ticks under a bar: the AY data writes, OUT ($BFFD))', color=DIM,
                  fontsize=9)
    ax.set_title(f'The play interrupt in {len(frames)} frames: the radar, then the music; done by T {max(ends)}, '
                 f'before the beam reaches the paper', color=FG, fontsize=12, loc='left')
    ax.legend(handles=[Patch(color=c, label=l) for k, l, c in PARTS], loc='upper center', ncol=2, fontsize=8.5,
              bbox_to_anchor=(0.5, -0.1), frameon=False, labelcolor='#d6d8e0')
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(f'{len(frames)} interrupts, end T {min(ends)}..{max(ends)}, music {min(music)}..{max(music)} T')


if __name__ == '__main__':
    sys.exit(main())
