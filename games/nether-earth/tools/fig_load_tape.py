#!/usr/bin/env python3
"""Doc 03 figure: the tape's signal time against what the play recording shows (docs/img/load-tape.png).

    python3 tools/fig_load_tape.py --out docs/img/load-tape.png

Top row: the five blocks of orig/NETHER.TAP laid end to end at their signal length at ROM speed (pilot, sync, bits;
pauses not included, the timing of load_stages.play_t). Bottom row: the same load as the play recording shows it,
from the frames of docs/03-build-and-load.md 3.3 (load_stages.py and re_session.py stages on work/play): blocks 0-3
in place and N1 entered by frame 253, N1 loading block 4 until frame 12660. The point: blocks 0-3 arrive far faster
than their signal (the emulator's LD-BYTES trap), block 4 takes its whole signal (N1 is a copy of LD-BYTES in RAM,
no trap catches it).
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, HERE)
import load_stages  # noqa: E402

FRAME_T = 69888
# measured on the play recording (docs/03-build-and-load.md 3.3)
N1_ENTERED, GAME_DONE = 253, 12660
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
HEADER, BASIC, N1, GAME = '#7a7d8c', '#5c8fd6', '#d9a441', '#4caf50'


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'load-tape.png'))
    args = p.parse_args()
    tape = load_stages.blocks(os.path.join(CASE, 'orig', 'NETHER.TAP'))
    frames = [load_stages.play_t(b) / FRAME_T for b in tape]
    small = sum(frames[:4])
    total = sum(frames)

    fig, ax = plt.subplots(figsize=(11, 3.9), dpi=100)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(PANEL)
    ax.tick_params(colors=DIM, labelsize=10)
    for s in ax.spines.values():
        s.set_color('#444')
    ytape, yrec, h = 1.0, 0.0, 0.42

    # the tape at signal speed
    t = 0.0
    for f, c in zip(frames, (HEADER, BASIC, HEADER, N1, GAME)):
        ax.barh(ytape, f, left=t, height=h, color=c, edgecolor=PANEL)
        t += f
    ax.text(frames[0] + frames[1] + frames[2] + frames[3] + 150, ytape,
            'block 4, the game, 48 361 bytes: ' + f'{frames[4]:,.0f}'.replace(',', ' ') + ' frames of signal',
            va='center', color='#10110f', fontsize=11)
    ax.annotate(f'blocks 0-3 (two headers, the BASIC, N1):\n{small:.0f} frames of signal', xy=(small / 2, ytape + h / 2),
                xytext=(900, ytape + 0.62), color=FG, fontsize=10, va='center',
                arrowprops=dict(arrowstyle='->', color=DIM))

    # the play recording
    ax.barh(yrec, N1_ENTERED, left=0, height=h, color=BASIC, edgecolor=PANEL)
    ax.barh(yrec, GAME_DONE - N1_ENTERED, left=N1_ENTERED, height=h, color=GAME, edgecolor=PANEL)
    ax.text(N1_ENTERED + 150, yrec,
            f'N1 loads block 4 with interrupts off: frames {N1_ENTERED}-{GAME_DONE}, '
            + f'{GAME_DONE - N1_ENTERED:,}'.replace(',', ' ') + ' frames', va='center', color='#10110f', fontsize=11)
    ax.annotate(f'blocks 0-3 in place, N1 entered: frame {N1_ENTERED}\n'
                f'{small / N1_ENTERED:.1f}x faster than their signal: the emulator\'s\n'
                'LD-BYTES trap loads them, not the signal', xy=(N1_ENTERED, yrec - h / 2),
                xytext=(900, yrec - 0.62), color=FG, fontsize=10, va='center',
                arrowprops=dict(arrowstyle='->', color=DIM))
    ax.text(total, yrec - 0.62, 'block 4 takes its whole signal (12 407 frames\nagainst 12 400): N1 is a copy of '
            'LD-BYTES\nin RAM, no trap catches it', color=FG, fontsize=10, ha='right', va='center')

    ax.set_yticks([yrec, ytape])
    ax.set_yticklabels(['the play\nrecording', 'the tape at\nROM speed'], color=FG, fontsize=11)
    ax.set_ylim(-1.0, 2.0)
    ax.set_xlim(0, total + 100)
    ax.set_xlabel('frames from the start of the tape (50 a second)', color=DIM, fontsize=10)
    ax.set_title('The headers, the BASIC and N1 load in 253 frames instead of 857; the game block takes its full '
                 '248 s', color=FG, fontsize=12, loc='left')
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=BG, bbox_inches='tight')
    print(args.out)


if __name__ == '__main__':
    sys.exit(main())
