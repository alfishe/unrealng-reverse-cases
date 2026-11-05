#!/usr/bin/env python3
"""Doc 03 figure: the tape's signal against the load the power-on recording c1 shows (docs/img/load-tape.png).

    python3 tools/fig_load_tape.py [--out docs/img/load-tape.png]

Top row: the TZX's eight standard blocks end to end at their signal length (pilot, sync, bits, tzxblocks.seconds)
plus each block's pause, in frames of 50 Hz. Bottom row: c1 (re_session.py capture --record-load, work/c1): the
ROM-loaded part (BASIC and loader, fast-loaded by the emulator's LD-BYTES trap) done when the loader is entered at
frame 250, the picy file until its unpacker runs at frame 1830, the code file until MoveStub at frame 12310, the
move until the game's first instruction at frame 12323 (re_session.py stages, work/stage1/c1-stages.txt;
docs/03-build-and-load.md 3.5).
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
import image  # noqa: E402
import tzxblocks  # noqa: E402

# c1's stages (re_session.py stages --work work/c1): frame of the loader's entry, the picy unpacker, MoveStub, $8000
LOADER, PICY, STUB, GAME = 250, 1830, 12310, 12323
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
HEADER, BASIC, LOADERC, PICYC, GAMEC, PAUSE = '#7a7d8c', '#5c8fd6', '#d9a441', '#c46ad9', '#4caf50', '#2b2d36'


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'load-tape.png'))
    args = p.parse_args()
    blocks = [b for b in image.blocks() if b['kind'] == 'standard']
    colours = (HEADER, BASIC, HEADER, LOADERC, HEADER, PICYC, HEADER, GAMEC)
    fig, ax = plt.subplots(figsize=(11, 4.2), dpi=100)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(PANEL)
    ax.tick_params(colors=DIM, labelsize=10)
    for s in ax.spines.values():
        s.set_color('#444')
    ytape, yrec, h = 1.0, 0.0, 0.42
    t = 0.0
    starts = []
    for b, c in zip(blocks, colours):
        f = tzxblocks.seconds(b) * 50
        starts.append(t)
        ax.barh(ytape, f, left=t, height=h, color=c, edgecolor=PANEL)
        t += f
        pause = b['pause'] / 1000 * 50
        ax.barh(ytape, pause, left=t, height=h, color=PAUSE, edgecolor=PANEL)
        t += pause
    total = t
    ax.text(starts[7] + 200, ytape, 'block 8, the game, 40 535 bytes: %.0f frames' % (tzxblocks.seconds(blocks[7]) * 50),
            va='center', color='#10110f', fontsize=11)
    ax.annotate('blocks 1-4: the BASIC and the loader\n(ROM files), %.0f frames with the pauses' % starts[4],
                xy=(starts[4] / 2, ytape + h / 2), xytext=(400, ytape + 0.66), color=FG, fontsize=10, va='center',
                arrowprops=dict(arrowstyle='->', color=DIM))
    ax.annotate('blocks 5-6: picy, the packed screen', xy=((starts[5] + starts[6]) / 2, ytape + h / 2),
                xytext=(5600, ytape + 0.66), color=FG, fontsize=10, va='center',
                arrowprops=dict(arrowstyle='->', color=DIM))

    ax.barh(yrec, LOADER, left=0, height=h, color=BASIC, edgecolor=PANEL)
    ax.barh(yrec, PICY - LOADER, left=LOADER, height=h, color=PICYC, edgecolor=PANEL)
    ax.barh(yrec, STUB - PICY, left=PICY, height=h, color=GAMEC, edgecolor=PANEL)
    ax.barh(yrec, GAME - STUB, left=STUB, height=h, color=LOADERC, edgecolor=PANEL)
    ax.text(PICY + 200, yrec, f'the Countdown II loader reads the code file: frames {PICY}-{STUB}', va='center',
            color='#10110f', fontsize=11)
    ax.annotate(f'the loader entered at frame {LOADER}: the emulator\'s\nLD-BYTES trap took the ROM files fast',
                xy=(LOADER, yrec - h / 2), xytext=(300, yrec - 0.66), color=FG, fontsize=10, va='center',
                arrowprops=dict(arrowstyle='->', color=DIM))
    ax.annotate(f'MoveStub {STUB}, $8000 at {GAME}', xy=(GAME, yrec - h / 2), xytext=(GAME - 3500, yrec - 0.66),
                color=FG, fontsize=10, va='center', arrowprops=dict(arrowstyle='->', color=DIM))
    ax.set_yticks([yrec, ytape])
    ax.set_yticklabels(['c1, the\nrecording', 'the TZX at\nROM speed'], color=FG, fontsize=11)
    ax.set_ylim(-1.0, 2.0)
    ax.set_xlim(0, total + 100)
    ax.set_xlabel('frames from the start of the tape (50 a second); dark: the pauses', color=DIM, fontsize=10)
    ax.set_title('Zynaps.tzx: %.0f frames of signal and pauses; c1 reaches the game at frame %d' % (total, GAME),
                 color=FG, fontsize=12, loc='left')
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=BG, bbox_inches='tight')
    print(args.out)


if __name__ == '__main__':
    sys.exit(main())
