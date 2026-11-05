#!/usr/bin/env python3
"""One bot, five games: Nether Earth, ZS'98, ZS'99 on its built-in level (HARD) and ZS'99 on NELEV_00 (Nether
Earth's own map) on EASY and on HARD, played by the same scripted player (docs/img/diff/samebot.png).

    python3 tools/fig_diff_samebot.py [--out PNG]

Nothing is run: the figure reads the four recordings' play.log and their screens/ (512 x 384 grabs the bot wrote at
each "day" line):

  NE        ../nether-earth/work/deep        48K, the tape image, the bot of that case
  '98       work/stage2/game98/deep          the same bot, the '98 on Pentagon 128 + TR-DOS
  '99       work/zsB/deep                    the same bot, the '99, HARD, the built-in level
  '99 easy0 work/diff/deep-easy-map0         the same bot, the '99, EASY, LOAD MAP NELEV_00 (made for doc 13:
                                             work/diff/play99_ports.py menu --level 1 --map 0, then deep)
  '99 map0  work/zsB/deep-map0               the same bot, the '99, HARD, LOAD MAP NELEV_00

The top row is the five screens at the bot's first log line of day 1 (the same moment of the game clock as near as
the log has it); the lower panels plot, against the game clock (days), the robots of each side and our general
(resource 0) from the "day" lines. A cross marks the first "the pad is blocked" line: from there the bot cannot
build ([13.9](../docs/13-differences-from-nether-earth.md)).
"""
import argparse
import os
import re

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False
from PIL import Image  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RUNS = [('NE', os.path.join(ROOT, '..', 'nether-earth', 'work', 'deep'), 'Nether Earth (48K, tape)', '#9ecbff'),
        ("'98", os.path.join(ROOT, 'work', 'stage2', 'game98', 'deep'), "ZS'98", '#f2e86d'),
        ("'99", os.path.join(ROOT, 'work', 'zsB', 'deep'), "ZS'99, HARD, built-in level", '#e5534b'),
        ("'99 easy0", os.path.join(ROOT, 'work', 'diff', 'deep-easy-map0'), "ZS'99, EASY, NELEV_00 (NE's map)",
         '#7ee08a'),
        ("'99 map0", os.path.join(ROOT, 'work', 'zsB', 'deep-map0'), "ZS'99, HARD, NELEV_00 (NE's map)", '#26c6da')]
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'
DAY = re.compile(r'\s*(\d+) day (\d+) (\d\d):(\d\d) resources \[([^\]]*)\] robots (\d+) vs (\d+)')


def read(run):
    days, blocked = [], None
    for line in open(os.path.join(run, 'play.log')):
        m = DAY.match(line)
        if m:
            f, d, hh, mm, res, ours, theirs = m.groups()
            days.append(dict(frame=int(f), t=int(d) + (int(hh) * 60 + int(mm)) / 1440,
                             clock=f'day {d} {hh}:{mm}', general=int(res.split(',')[0]),
                             ours=int(ours), theirs=int(theirs)))
        elif 'the pad is blocked' in line and blocked is None:
            blocked = int(line.split()[0])
    return days, blocked


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img', 'diff', 'samebot.png'))
    a = p.parse_args()
    data = [(tag, read(run), run, title, colour) for tag, run, title, colour in RUNS]
    fig = plt.figure(figsize=(17, 10.5), facecolor=BG)
    for i, (tag, (days, blocked), run, title, colour) in enumerate(data):
        d = next(x for x in days if x['t'] >= 1)
        ax = fig.add_axes((0.008 + i * 0.198, 0.56, 0.19, 0.33))
        ax.imshow(Image.open(os.path.join(run, 'screens', f"f{d['frame']:06d}.png")).convert('RGB'),
                  interpolation='nearest')
        ax.axis('off')
        ax.set_title(f"{title}\n{d['clock']}: robots {d['ours']} vs {d['theirs']}, general {d['general']}",
                     color=colour, fontsize=8.5, loc='left')
        print(f"{tag:9s} frame {d['frame']:6d} {d['clock']}  robots {d['ours']} vs {d['theirs']}  general "
              f"{d['general']}  last {days[-1]['clock']} {days[-1]['ours']} vs {days[-1]['theirs']}"
              f"  pad blocked from {blocked}")
    panels = [('ours', 'our robots'), ('theirs', 'the Insignians\' robots'), ('general', 'our general (resource 0)')]
    for j, (key, label) in enumerate(panels):
        ax = fig.add_axes((0.05 + j * 0.325, 0.07, 0.28, 0.4))
        ax.set_facecolor(PANEL)
        ax.tick_params(colors=DIM, labelsize=8)
        for s in ax.spines.values():
            s.set_color(DIM)
        for tag, (days, blocked), run, title, colour in data:
            ax.plot([x['t'] for x in days], [x[key] for x in days], color=colour, lw=1.8, marker='o', ms=3,
                    label=title)
            if blocked is not None:
                b = next((x for x in days if x['frame'] >= blocked), days[-1])
                ax.plot([b['t']], [b[key]], 'x', color=colour, ms=10, mew=2)
        ax.set_title(label, color=TEXT, fontsize=10, loc='left')
        ax.set_xlabel('game clock, days', color=DIM, fontsize=8)
        ax.grid(color='#2a2a35', lw=0.6)
        if j == 0:
            ax.legend(frameon=False, labelcolor=TEXT, fontsize=8, loc='upper left')
    fig.suptitle("The same bot in the three games (five runs): day 1 morning, and robots and the general over the days "
                 "(x: the bot's pad is blocked from here)", color=TEXT, fontsize=12, x=0.01, ha='left')
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=90, facecolor=BG)
    print('wrote', a.out)


if __name__ == '__main__':
    main()
