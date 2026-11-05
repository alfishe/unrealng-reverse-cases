#!/usr/bin/env python3
"""Doc 09 figures: the two AY tunes of the case as their players drive the AY, and what a play call costs.

    VENV/bin/python tools/zsB_ay_play.py --load build/intro98/intro-c000.bin@C000 --init C000 --play C005 \
        --frames 16000 --out work/zsB/ay/cool-winter.json
    VENV/bin/python tools/zsB_ay_play.py --load build/front99/music-c000.bin@C000 --init C00B --play C00E \
        --frames 16000 --out work/zsB/ay/ne-mus.json
    python3 tools/zsB_fig_tunes.py --ay work/zsB/ay --out-dir docs/img/sound

For each tune: <key>-roll.png, its first pass and the start of the second (the loop found where the 14 registers
after each call repeat to the end of the run), in strips of --strip frames: a dot a frame per channel at the note of
its tone period (1.75 MHz AY clock), its size the volume (envelope dots at full size), grey ticks for the frames a
channel mixes noise, a dashed line at the loop point. player-cost.png: the T-states of every play call of both
tunes over 16000 frames against a Pentagon frame (71 680 T).
"""
import argparse
import json
import math
import os

import matplotlib
import numpy as np

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'
CH = [('A', '#e5534b'), ('B', '#4caf50'), ('C', '#5c8fd6')]
TUNES = {
    'cool-winter': ("COOL WINTER (KLIM/OHG/'97), the '98 intro: Pro Tracker 3 player at $C000, module $CE21", 'PT3'),
    'ne-mus': ("the '99 intro tune (\"SONG BY ST COMPILE\"): Sound Tracker 1 player at $C000, module $C4A8", 'STC'),
}
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
FRAME_T = 71680


def note(period):
    if period <= 0:
        return None
    return 69 + 12 * math.log2(1750000 / (16 * period) / 440)


def loop_of(frames):
    h = np.array([hash(tuple(f['r'])) for f in frames])
    n = len(h)
    for length in range(200, n - 2000):
        bad = np.nonzero(h[length:] != h[:-length])[0]
        start = bad[-1] + 1 if len(bad) else 0
        if n - length - start > 2000:
            return int(start), int(length)
    return None, None


def style(fig, axes):
    fig.patch.set_facecolor(BG)
    for a in axes:
        a.set_facecolor(AX)
        a.tick_params(colors=DIM, labelsize=8.5)
        for s in a.spines.values():
            s.set_color('#444')


def roll(key, data, strip, out):
    title, player = TUNES[key]
    fr = data['frames']
    start, length = loop_of(fr)
    total = start + length + 300
    strips = max(1, round(total / strip))
    strip = math.ceil(total / strips)
    fig, axes = plt.subplots(strips, 1, figsize=(14, 2.3 * strips + 0.8), dpi=90)
    axes = np.atleast_1d(axes)
    style(fig, axes)
    for k, ax in enumerate(axes):
        lo, hi = k * strip, min((k + 1) * strip, total)
        for c, (name, colour) in enumerate(CH):
            xs, ys, ss, nx = [], [], [], []
            for i in range(lo, hi):
                r = fr[i]['r']
                vol = r[8 + c]
                level = 15 if vol & 16 else vol & 15
                if not (r[7] >> (c + 3)) & 1 and level:
                    nx.append(i)
                if (r[7] >> c) & 1 or not level:
                    continue
                n = note(r[2 * c] | (r[2 * c + 1] & 15) << 8)
                if n is None:
                    continue
                xs.append(i)
                ys.append(n)
                ss.append(0.6 + level * 0.6)
            ax.scatter(xs, ys, s=ss, color=colour, linewidths=0, label=f'channel {name}' if k == 0 else None)
            ax.scatter(nx, [26 - 3 * c] * len(nx), s=4, marker='|', color='#9a9eab', linewidths=0.6)
        if lo <= start + length < hi:
            ax.axvline(start + length, color=FG, ls='--', lw=1)
            ax.text(start + length + 15, 104, f'frame {start + length}: the loop, back to frame {start}',
                    color=FG, fontsize=9, va='top')
        if lo <= start < hi and start:
            ax.axvline(start, color=DIM, ls=':', lw=1)
            ax.text(start + 15, 104, f'frame {start}: where the loop returns', color=DIM, fontsize=9, va='top')
        ticks = list(range(24, 109, 12))
        ax.set_yticks(ticks)
        ax.set_yticklabels([f'C{t // 12 - 1}' for t in ticks])
        ax.set_ylim(18, 108)
        ax.set_xlim(lo, lo + strip)
        ax.grid(axis='y', color='#333', lw=0.5)
    axes[0].legend(loc='upper right', fontsize=8, frameon=False, labelcolor='#d6d8e0', ncol=3, markerscale=3)
    axes[-1].set_xlabel(f'frame from the first play call (one call an interrupt, 48.8 a second on the Pentagon); '
                        f'grey ticks at the bottom: noise mixed in (A top, C bottom)', color=DIM, fontsize=9)
    fig.suptitle(f'{title.replace("$", chr(92) + "$")}: one pass is {length} frames ({length / 48.83:.1f} s), then it loops to frame {start}',
                 color=FG, fontsize=12, x=0.01, ha='left')
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    fig.savefig(out, facecolor=fig.get_facecolor())
    plt.close(fig)
    return start, length


def cost(data, out):
    fig, ax = plt.subplots(figsize=(12, 4.2), dpi=90)
    style(fig, [ax])
    rows = []
    for i, key in enumerate(TUNES):
        ts = np.array([f['t'] for f in data[key]['frames']])
        colour = '#26c6da' if TUNES[key][1] == 'STC' else '#d9a441'
        parts = ax.violinplot([ts], positions=[i], vert=False, widths=0.8, showextrema=False)
        for b in parts['bodies']:
            b.set_facecolor(colour)
            b.set_alpha(0.6)
        med = int(np.median(ts))
        ax.plot([ts.min(), ts.max()], [i, i], color=colour, lw=1)
        ax.plot([med], [i], 'o', color=FG, ms=4)
        ax.text(ts.max() + 100, i, f'{ts.min()} / {med} / {ts.max()} T (max {ts.max() / FRAME_T:.1%} of a frame)',
                color=DIM, fontsize=9, va='center')
        rows.append(f"{key} ({TUNES[key][1]}, init {data[key]['init_t']} T)")
    ax.set_yticks(range(len(rows)))
    ax.set_yticklabels(rows)
    ax.set_xlim(0, 12000)
    ax.set_ylim(-0.7, len(rows) - 0.3)
    ax.set_xlabel('T-states of one play call, min / median / max over 16 000 calls (Pentagon: no contention, '
                  '71 680 T a frame)', color=DIM, fontsize=9)
    ax.set_title('A play call costs 1 800-7 700 T: under 11 % of a frame for both players', color=FG, fontsize=12,
                 loc='left')
    fig.savefig(out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    plt.close(fig)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--ay', required=True)
    p.add_argument('--strip', type=int, default=1800)
    p.add_argument('--out-dir', required=True)
    a = p.parse_args()
    os.makedirs(a.out_dir, exist_ok=True)
    data = {k: json.load(open(os.path.join(a.ay, k + '.json'))) for k in TUNES}
    for k in TUNES:
        s, n = roll(k, data[k], a.strip, os.path.join(a.out_dir, k + '-roll.png'))
        regs = [f['r'] for f in data[k]['frames'][s:s + n]]
        used = {c: sum(1 for r in regs if not (r[7] >> c) & 1 and (r[8 + c] & 31)) for c in range(3)}
        noise = {c: sum(1 for r in regs if not (r[7] >> (c + 3)) & 1 and (r[8 + c] & 31)) for c in range(3)}
        env = sum(1 for r in regs if any(r[8 + c] & 16 for c in range(3)))
        print(k, 'loop start', s, 'length', n, 'tone frames', used, 'noise frames', noise, 'envelope frames', env)
    cost(data, os.path.join(a.out_dir, 'player-cost.png'))


if __name__ == '__main__':
    main()
