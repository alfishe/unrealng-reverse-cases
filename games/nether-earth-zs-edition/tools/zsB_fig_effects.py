#!/usr/bin/env python3
"""Doc 09 figure: the '99's beeper sounds as unreal-ng played them, one row an effect (docs/img/sound/effects.png).

    python3 tools/zsB_render_audio.py --only sfx99,pokes99     # the WAVs in work/zsB/audio (an own muted instance)
    python3 tools/zsB_fig_effects.py --out docs/img/sound/effects.png

Each row: the spectrogram of the beeper buffer (0-10 kHz, 44.1 kHz capture) over the effect's frames, its length in
frames and milliseconds, and the code that sounds it. The menus' beeps come from the sfx99 stage (the bot in the
construction and order menus, frames of that stage), the play effects from pokes99 (SoundFx $FD53 set by hand: an
experiment, the interrupt's SoundEffect $D5C4 plays them).
"""
import argparse
import os
import sys

import matplotlib
import numpy as np

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', 'advanced-nether-earth', 'tools'))
import render_audio as ra  # noqa: E402

ra.WORK = os.path.join(CASE, 'work', 'zsB', 'audio')
BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'
FRAME_MS = 71680 / 3500000 * 1000      # a Pentagon frame, 20.48 ms
ROWS = [
    ('sfx99', 211, 214, 'a click: Beep $CCAC, A = $14 (CursorMoved $CB36, menu moves)'),
    ('sfx99', 244, 250, 'a part paid: Beep, A = $64 (PartPaid $CA89, ListMenuChosen $AD2F)'),
    ('sfx99', 270, 314, 'START ROBOT: BuildChirp $CB82 ($50 down to $14 by 5), then A = $C8'),
    ('sfx99', 917, 931, 'a target chosen: A = $64, then OrderSet $ABF5 A = $78'),
    ('pokes99', 10, 138, 'a shot: SoundFx 1 counting up to $7F, a falling sweep (FireShot $B6D6)'),
    ('pokes99', 160, 164, 'a miss: SoundFx $FC, noise, 3 frames (ShotGone $B7EA)'),
    ('pokes99', 190, 196, 'a hit: SoundFx $FA, noise, 5 frames (MoveShot $B724)'),
    ('pokes99', 220, 277, 'a kill: SoundFx $C8, noise, 55 frames (MoveShotKill $B7D7)'),
]


def esc(text):
    return text.replace('$', '\\$')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', required=True)
    a = p.parse_args()
    takes = {}
    fig, axes = plt.subplots(len(ROWS), 1, figsize=(12, 1.25 * len(ROWS) + 1.2), dpi=90)
    fig.patch.set_facecolor(BG)
    for ax, (stage, f0, f1, text) in zip(axes, ROWS):
        t = takes.setdefault(stage, ra.Take(stage))
        x = t.data[t.at(f0 - 1):t.at(f1 + 1)].mean(axis=1)
        x = x - np.convolve(x, np.ones(64) / 64, mode='same')      # no DC: the beeper's level steps
        ax.set_facecolor(AX)
        ax.specgram(x, NFFT=512, Fs=t.rate, noverlap=448, cmap='magma', vmin=-10, vmax=60)
        ax.set_ylim(0, 10000)
        ax.set_yticks([0, 5000, 10000])
        ax.set_yticklabels(['0', '5k', '10k'])
        ax.tick_params(colors=DIM, labelsize=8)
        for s in ax.spines.values():
            s.set_color('#444')
        n = f1 - f0
        ax.text(1.005, 0.5, f'{n} frames\n{n * FRAME_MS:.0f} ms', transform=ax.transAxes, color=FG, fontsize=9,
                va='center')
        ax.set_title(esc(f'{text}   [{stage} frames {f0}-{f1}]'), color=FG, fontsize=9.5, loc='left', pad=3)
        ax.set_xlim(0, len(x) / t.rate)
    axes[-1].set_xlabel('seconds from the effect\'s first frame (each row its own scale); y: Hz', color=DIM)
    fig.suptitle(esc('The \'99\'s beeper sounds: four menu beeps from one routine, four play effects from the '
                     'interrupt (spectrograms of unreal-ng\'s beeper buffer)'), color=FG, fontsize=11.5, x=0.01,
                 ha='left')
    fig.text(0.01, 0.004, f'python3 tools/zsB_fig_effects.py --out {os.path.relpath(a.out, CASE)}', color='#8a8e9a',
             fontsize=9)
    fig.tight_layout(rect=(0, 0.02, 0.93, 0.97))
    fig.savefig(a.out, facecolor=fig.get_facecolor())
    print(a.out)


if __name__ == '__main__':
    main()
