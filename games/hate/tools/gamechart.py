#!/usr/bin/env python3
"""Draws the course of a game played by autopilot.py from its log (docs/10-gameplay-logic.md 10.1): the round
($C2F7), the lives ($C2F9), the followers ($ECE4) and the player's hits over the frames, with the rounds shaded and
the events named on the chart (dark theme, the style of tools/fig_l1.py).

    python3 gamechart.py work/p2/run.log docs/img/game-p2-timeline.png
"""
import re
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False

STATE = re.compile(r'^(\d+) round (\d+) lap \d+ lives (\d+) followers (\d+) scrolled \d+ me (None|\()')
HIT = re.compile(r'^HIT at (\d+)')
BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'
ROUND_C, LIVES_C, FOLLOW_C, HIT_C = '#e8e8ee', '#2ec4e6', '#f0a030', '#e5534b'


def main(log, out):
    frames, rounds, lives, followers, hits = [], [], [], [], []
    for line in open(log):
        m = STATE.match(line)
        if m and m.group(5) != 'None':  # a live player: the round's numbers are settled
            frames.append(int(m.group(1)))
            rounds.append(int(m.group(2)))
            lives.append(int(m.group(3)))
            followers.append(int(m.group(4)))
        m = HIT.match(line)
        if m:
            hits.append(int(m.group(1)))
    end = hits[-1] + 72  # the last loss: the GAME OVER box follows, then the menu and the demo (round 0)
    keep = [i for i, f in enumerate(frames) if f <= end and rounds[i] > 0]
    frames, rounds, lives, followers = ([v[i] for i in keep] for v in (frames, rounds, lives, followers))
    frames.append(end)
    for v in (rounds, lives, followers):
        v.append(v[-1])

    fig, ax = plt.subplots(figsize=(12, 4.8), dpi=100)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(AX)
    ax.tick_params(colors=DIM, labelsize=9)
    for s in ax.spines.values():
        s.set_color('#444')

    # the rounds as shaded spans, named at the top
    spans, start = [], 0
    for i in range(1, len(frames)):
        if rounds[i] != rounds[i - 1] or i == len(frames) - 1:
            spans.append((frames[start], frames[i], rounds[start]))
            start = i
    vehicle = {1: 'aircraft', 0: 'ground vehicle'}
    for k, (a, b, r) in enumerate(spans):
        ax.axvspan(a, b, color='#ffffff', alpha=0.035 if k % 2 else 0.08, lw=0)
        ax.text((a + b) / 2, 5.25, f'round {r}\n{vehicle[r % 2]}' if b - a > 1500 else f'{r}', color=DIM,
                fontsize=8.5, ha='center', va='bottom')

    ax.step(frames, rounds, where='post', color=ROUND_C, lw=2, label='round ($C2F7)')
    ax.step(frames, lives, where='post', color=LIVES_C, lw=2, label='lives ($C2F9)')
    ax.step(frames, followers, where='post', color=FOLLOW_C, lw=1.5, label='followers: pods picked up ($ECE4)')
    for h in hits:
        ax.axvline(h, color=HIT_C, lw=1.0, ls=':')
    ax.plot([], [], color=HIT_C, lw=1.0, ls=':', label='the player hit')

    box = dict(boxstyle='round,pad=0.2', fc=AX, ec='none')
    arrow = dict(arrowstyle='->', color=FG, lw=0.8)
    r2 = frames[rounds.index(2)]
    ax.annotate('hit with followers:\na follower lost, not a life', xy=(hits[0], 3.5), xytext=(hits[0] - 2500, 2.25),
                color=FG, fontsize=8.5, bbox=box, arrowprops=arrow)
    ax.annotate('the barrier passed with 3 followers:\nround 2 starts with 3 lives', xy=(r2, 3),
                xytext=(r2 + 500, 4.25), color=FG, fontsize=8.5, bbox=box, arrowprops=arrow)
    ax.annotate('round 2 retried twice:\ntwo lives lost to missiles', xy=(hits[2], 1.5), xytext=(hits[2] + 600, 2.25),
                color=FG, fontsize=8.5, bbox=box, arrowprops=arrow)
    for i in range(1, len(rounds)):
        if rounds[i] < rounds[i - 1]:
            ax.annotate('round 4 lost on its only life:\nfall back to round 3 with 3 - 1 = 2 lives', xy=(frames[i], 2),
                        xytext=(frames[i] - 2900, 4.25), color=FG, fontsize=8.5, bbox=box, arrowprops=arrow)
    ax.annotate(f'GAME OVER\n(last life lost at {hits[-1]})', xy=(end, 0), xytext=(end - 1400, 0.45), color=HIT_C,
                fontsize=8.5, ha='center', bbox=box, arrowprops=dict(arrowstyle='->', color=HIT_C, lw=0.8))

    ax.set_xlabel('frame of the recording work/p2 (50 a second)', color=DIM, fontsize=9)
    ax.set_yticks(range(0, 6))
    ax.set_ylim(-0.3, 5.2)
    ax.set_xlim(0, end + 150)
    ax.grid(axis='y', color='#ffffff', alpha=0.08)
    ax.legend(loc='upper left', bbox_to_anchor=(0, -0.13), fontsize=9, ncol=4, frameon=False, labelcolor='#d6d8e0')
    ax.set_title('The bot\'s game: rounds 1 to 4, a fall back to round 3, then GAME OVER', color=FG, fontsize=12,
                 loc='left', pad=34)
    fig.savefig(out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(out, 'hits', hits, 'end', end)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
