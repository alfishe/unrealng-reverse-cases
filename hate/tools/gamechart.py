#!/usr/bin/env python3
"""Draws the course of a game played by autopilot.py from its log (docs/10-gameplay-logic.md): the round, the lives
($C2F9), the followers ($ECE4) and the player's hits over the frames.

    python3 gamechart.py work/p2/run.log docs/img/game-p2-timeline.png
"""
import re
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

STATE = re.compile(r'^(\d+) round (\d+) lap \d+ lives (\d+) followers (\d+) scrolled \d+ me (None|\()')
HIT = re.compile(r'^HIT at (\d+)')


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
    fig, ax = plt.subplots(figsize=(11, 3.6), dpi=110)
    ax.step(frames, rounds, where='post', color='#444444', lw=2, label='round ($C2F7)')
    ax.step(frames, lives, where='post', color='#00a0c0', lw=2, label='lives ($C2F9)')
    ax.step(frames, followers, where='post', color='#e08000', lw=1.5, label='followers ($ECE4)')
    for h in hits:
        ax.axvline(h, color='#d02020', lw=0.8, ls=':')
    ax.plot([], [], color='#d02020', lw=0.8, ls=':', label='player hit')
    for i in range(1, len(rounds)):
        if rounds[i] < rounds[i - 1]:
            ax.annotate('fall back', (frames[i], rounds[i]), xytext=(8, 14), textcoords='offset points', fontsize=8)
    ax.annotate('GAME OVER', (end, 0), xytext=(-62, 4), textcoords='offset points', fontsize=8, color='#d02020')
    ax.set_xlabel('frame')
    ax.set_yticks(range(0, 6))
    ax.set_xlim(0, end + 100)
    ax.grid(axis='y', alpha=0.3)
    ax.legend(loc='upper left', fontsize=8, ncol=4)
    fig.tight_layout()
    fig.savefig(out)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
