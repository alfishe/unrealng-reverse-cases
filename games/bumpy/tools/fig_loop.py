#!/usr/bin/env python3
"""Doc 04's charts, from the case's own logs (no emulator):

  python3 tools/fig_loop.py

- docs/img/loop/pass-lengths.png: how many frames a pass of MainLoop takes, and the work in T-states, over the whole
  RZX in play (work/stage1/passes.tsv, tools/rzx_passes.py: every fetch of the HALT's neighbours $B6E9 / $B6EB);
- docs/img/loop/states-level0.png: BallState $AA00, the prizes left $AA45 and the timer $AB04 frame by frame over the
  RZX's level 0 and its level end (work/stage2/rzx-states.tsv, tools/rzx_states.py: the state after each RZX frame).
"""
import csv
import os

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
OUT = os.path.join(CASE, 'docs', 'img', 'loop')
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'
STATES = ['0 bounce', '1 left', '2 right', '3 up', '4 down', '5 stopped', '6 burst', '7 out below', '8 level end']


def style(ax):
    ax.set_facecolor(PANEL)
    for s in ax.spines.values():
        s.set_color(DIM)
    ax.tick_params(colors=TEXT, labelsize=11)
    ax.xaxis.label.set_color(TEXT)
    ax.yaxis.label.set_color(TEXT)
    ax.title.set_color(TEXT)
    ax.grid(color='#2a2a36', linewidth=0.6)


def pass_lengths():
    rows = list(csv.DictReader(open(os.path.join(CASE, 'work/stage1/passes.tsv')), delimiter='\t'))
    frames = [int(r['frames_to_next']) for r in rows]
    work = [int(r['work_t']) for r in rows]
    play = [(f, w) for f, w in zip(frames, work) if f <= 7]      # the level ends (114-1285 frames) are not play
    pause = [(f, w) for f, w in play if f == 16]
    counts = {}
    for f, _ in play:
        counts[f] = counts.get(f, 0) + 1
    total = sum(counts.values())
    fig, (a, b) = plt.subplots(1, 2, figsize=(10.5, 4.2), dpi=100, facecolor=BG)
    ks = sorted(counts)
    bars = a.bar([str(k) for k in ks], [counts[k] for k in ks], color='#5a96fa')
    for k, bar in zip(ks, bars):
        a.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), f'{counts[k]}\n{100 * counts[k] / total:.1f} %',
               ha='center', va='bottom', color=TEXT, fontsize=10)
    a.set_yscale('log')
    a.set_ylim(1, 300000)
    a.set_xlabel('frames from one HALT to the next (a pass)')
    a.set_ylabel('passes (log)')
    a.set_title(f'{total} passes in play, the whole RZX', fontsize=12)
    style(a)
    w = sorted(x for _, x in play)
    b.hist([x / 1000 for x in w], bins=80, color='#5ac878', log=True)
    for frac, lab in ((0.5, 'median'), (0.95, '95 %')):
        v = w[int(frac * (len(w) - 1))]
        b.axvline(v / 1000, color='#f0c846', linewidth=1)
        b.text(v / 1000, 30000, f' {lab} {v} T', color='#f0c846', fontsize=10)
    b.axvline(69.888, color='#e65a50', linewidth=1)
    b.text(69.888, 3000, ' one frame 69 888 T', color='#e65a50', fontsize=10)
    b.set_xlabel('work of a pass, thousands of T (the HALT left out)')
    b.set_ylabel('passes (log)')
    b.set_title('the work between the HALT and the next wait', fontsize=12)
    style(b)
    fig.suptitle('A pass of MainLoop $ACC8: one frame four times in five; longer when the beeper or a big picture runs',
                 color=TEXT, fontsize=12)
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, 'pass-lengths.png'), facecolor=BG)
    print('pass-lengths.png', total, counts, len(pause))


def states_level0():
    rows = list(csv.DictReader(open(os.path.join(CASE, 'work/stage2/rzx-states.tsv')), delimiter='\t'))
    rows = [r for r in rows if 172 <= int(r['frame']) <= 1420]
    f = [int(r['frame']) for r in rows]
    st = [int(r['state']) for r in rows]
    prizes = [int(r['prizes']) for r in rows]
    timer = [int(r['timer']) + 256 * int(r['timer_hi']) for r in rows]
    level = [int(r['level']) for r in rows]
    fig, (a, b) = plt.subplots(2, 1, figsize=(10.5, 7.0), dpi=100, facecolor=BG, sharex=True,
                               gridspec_kw={'height_ratios': [3, 2]})
    a.step(f, st, where='post', color='#5a96fa', linewidth=1.2)
    a.set_yticks(range(9))
    a.set_yticklabels(STATES)
    a.set_ylabel('BallState $AA00')
    a.set_title('rzx: the RZX frame by frame over level 0 and its end (the state after each frame)', fontsize=12)
    change = next(x for x, lv in zip(f, level) if lv == 1)
    end8 = next(x for x, s in zip(f, st) if s == 8)
    for x, lab in ((end8, f'state 8 from {end8}:\nthe ball lands on the exit'), (change, f'Level $AB00 = 1 at {change}')):
        a.axvline(x, color='#f0c846', linewidth=1)
        a.text(x + 6, 6.2 if x == end8 else 4.5, lab, color='#f0c846', fontsize=10)
    style(a)
    b.plot(f, timer, color='#5ac878', label='Timer $AB04 (frames left)')
    b.set_ylabel('Timer', color=TEXT)
    b2 = b.twinx()
    b2.step(f, prizes, where='post', color='#e65a50', label='PrizesLeft $AA45')
    b2.set_ylabel('prizes left', color=TEXT)
    b2.tick_params(colors=TEXT, labelsize=11)
    b.set_xlabel('RZX frame')
    b.legend(loc='upper center', facecolor=PANEL, labelcolor=TEXT, fontsize=10)
    b2.legend(loc='upper right', facecolor=PANEL, labelcolor=TEXT, fontsize=10)
    style(b)
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, 'states-level0.png'), facecolor=BG)
    print('states-level0.png', end8, change)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    pass_lengths()
    states_level0()
