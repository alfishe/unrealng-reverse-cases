#!/usr/bin/env python3
"""Doc 09 figures: ANE's five tunes as the AY plays them, and what each player costs a frame.

    VENV/bin/python tools/ay_play.py ... --out work/docR/ay/<tune>.json     (tools/ay_play.py, once per tune)
    python3 tools/fig_tunes.py --ay work/docR/ay --frames 1500 --out-tunes docs/img/sound/tunes.png \
        --out-cost docs/img/sound/player-cost.png

tunes.png: one row a tune, its first --frames frames (48.8 a second on the Pentagon): each channel's tone as a note (from the period
in registers 0-5, 1.75 MHz AY clock), a dot a frame where the channel's tone is on and its volume above 0, the dot's
size the volume (the envelope's dots at full size), the noise frames as grey marks under the row. player-cost.png:
the T-states of every play call of each tune (the whole json), against a Pentagon frame.
"""
import argparse
import json
import math
import os

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'
CH = [('A', '#e5534b'), ('B', '#4caf50'), ('C', '#5c8fd6')]
TUNES = [  # json, title, player
    ('intro', 'MAD NIGHT (the intro), New SoundTrack Player, bank 6', 'STP'),
    ('boot', 'TOMY by X-Man (the boot menu and help), PT3 player, bank 1', 'PT3'),
    ('game', 'TAIGA (the game\'s menus and play), New SoundTrack Player, bank 1', 'STP'),
    ('deadend', 'NETHER EARTH (END) (Dead End), New SoundTrack Player, bank 3', 'STP'),
    ('finalcut', 'REM by X-Man (Final Cut), PT3 player at $DB00', 'PT3'),
]
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def note(period):
    if period <= 0:
        return None
    f = 1750000 / (16 * period)
    return 69 + 12 * math.log2(f / 440)


def style(fig, axes):
    fig.patch.set_facecolor(BG)
    for a in axes:
        a.set_facecolor(AX)
        a.tick_params(colors=DIM, labelsize=8.5)
        for s in a.spines.values():
            s.set_color('#444')


def tunes_figure(data, frames, out):
    fig, axes = plt.subplots(len(TUNES), 1, figsize=(13, 2.5 * len(TUNES)), dpi=100, sharex=True)
    style(fig, axes)
    for ax, (key, title, player) in zip(axes, TUNES):
        fr = data[key]['frames'][:frames]
        mixer_noise = []
        for c, (name, colour) in enumerate(CH):
            xs, ys, ss = [], [], []
            for i, f in enumerate(fr):
                r = f['r']
                tone_on = not (r[7] >> c) & 1
                vol = r[8 + c]
                level = 15 if vol & 16 else vol & 15
                if (r[7] >> (c + 3)) & 1 == 0 and level:
                    mixer_noise.append((i, c))
                if not tone_on or level == 0:
                    continue
                n = note(r[2 * c] | (r[2 * c + 1] & 15) << 8)
                if n is None:
                    continue
                xs.append(i)
                ys.append(n)
                ss.append(0.4 + level * 0.5)
            ax.scatter(xs, ys, s=ss, color=colour, linewidths=0, label=f'channel {name}')
        if mixer_noise:
            ax.scatter([i for i, c in mixer_noise], [22 - 2 * c for i, c in mixer_noise], s=1.2, marker='|',
                       color='#9a9eab', linewidths=0.6)
        ts = sorted(f['t'] for f in data[key]['frames'])
        ax.set_title(f'{title}: play {ts[0]}-{ts[-1]} T a frame (median {ts[len(ts) // 2]})', color=FG,
                     fontsize=10, loc='left')
        ticks = list(range(24, 109, 12))
        ax.set_yticks(ticks)
        ax.set_yticklabels([f'C{t // 12 - 1}' for t in ticks])
        ax.set_ylim(16, 108)
        ax.grid(axis='y', color='#333', lw=0.5)
    axes[0].legend(loc='upper right', fontsize=8, frameon=False, labelcolor='#d6d8e0', ncol=3, markerscale=4)
    axes[-1].set_xlabel(f'frame from the tune\'s first play call (48.8 a second on the Pentagon; {frames} frames = {frames / 48.83:.0f} s); '
                        f'grey marks at the bottom: the frames a channel mixes noise (A top, C bottom)', color=DIM,
                        fontsize=9)
    fig.suptitle('ANE\'s five tunes as the AY plays them: a dot a frame per channel at the note of its tone period, '
                 'its size the volume', color=FG, fontsize=12, x=0.01, ha='left', y=0.995)
    fig.tight_layout(rect=(0, 0, 1, 0.985))
    fig.savefig(out, facecolor=fig.get_facecolor())


def cost_figure(data, measured, out):
    fig, ax = plt.subplots(figsize=(12, 5.2), dpi=110)
    style(fig, [ax])
    labels = []
    for i, (key, title, player) in enumerate(TUNES):
        ts = sorted(f['t'] for f in data[key]['frames'])
        n = len(ts)
        colour = '#26c6da' if player == 'STP' else '#d9a441'
        parts = ax.violinplot([ts], positions=[i], vert=False, widths=0.8, showextrema=False)
        for b in parts['bodies']:
            b.set_facecolor(colour)
            b.set_alpha(0.55)
        ax.plot([ts[0], ts[-1]], [i, i], color=colour, lw=1)
        ax.plot([ts[n // 2]], [i], 'o', color=FG, ms=4)
        ax.text(ts[-1] + 120, i, f'{ts[0]} / {ts[n // 2]} / {ts[-1]} T  (max {ts[-1] / 71680:.1%} of a frame)',
                color=DIM, fontsize=8.5, va='center')
        labels.append(f'{key} ({player}, init {data[key]["init_t"]} T)')
    if measured:
        lo, hi = measured
        ax.axvspan(lo, hi, color='#ffffff', alpha=0.08, lw=0)
        ax.text((lo + hi) / 2, len(TUNES) - 0.45, f'measured in play,\nd1 13005-13016:\n{lo}-{hi} T', color=FG,
                fontsize=8.5, ha='center', va='bottom')
    ax.set_yticks(range(len(TUNES)))
    ax.set_yticklabels(labels)
    ax.set_ylim(-0.7, len(TUNES) + 0.4)
    ax.set_xlim(0, 7500)
    ax.set_xlabel('T-states of one play call (Pentagon: no contention, 71 680 T a frame); min / median / max',
                  color=DIM, fontsize=9)
    ax.set_title('A play call costs 750-4 777 T: under 7 % of a frame for every tune and both players', color=FG,
                 fontsize=12, loc='left')
    fig.savefig(out, facecolor=fig.get_facecolor(), bbox_inches='tight')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--ay', required=True, help='the folder of tools/ay_play.py jsons (intro, boot, game, ...)')
    p.add_argument('--frames', type=int, default=1500)
    p.add_argument('--measured', default='2745-3612', help='lo-hi T of the music measured in a recording')
    p.add_argument('--out-tunes', required=True)
    p.add_argument('--out-cost', required=True)
    args = p.parse_args()
    data = {k: json.load(open(os.path.join(args.ay, f'{k}.json'))) for k, t, pl in TUNES}
    for o in (args.out_tunes, args.out_cost):
        os.makedirs(os.path.dirname(os.path.abspath(o)), exist_ok=True)
    tunes_figure(data, args.frames, args.out_tunes)
    m = tuple(int(v) for v in args.measured.split('-')) if args.measured else None
    cost_figure(data, m, args.out_cost)
    for k, t, pl in TUNES:
        ts = [f['t'] for f in data[k]['frames']]
        print(k, pl, 'init', data[k]['init_t'], 'min', min(ts), 'max', max(ts), 'mean', sum(ts) // len(ts))


if __name__ == '__main__':
    main()
