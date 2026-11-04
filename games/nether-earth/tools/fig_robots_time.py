#!/usr/bin/env python3
"""Doc 07 figure: robots and factories per side over the whole game (docs/img/robots-over-time.png).

    python3 tools/fig_robots_time.py --cache work/ill2/cache/deep --step 120 --last 36000 \
        --out docs/img/robots-over-time.png

Reads the memory moments that tools/ill_render.py keeps (one 48 K file per frame, `<frame>_0.bin`, from TTD
memory_at of work/deep), so no emulator is needed. Counts: live robot records (`+$01` not 0) in slots 0-23 (ours)
and 24-47 (the enemy's); factories and warbases from PlayerBuildings `$FD3A` / EnemyBuildings `$FD42`.
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

ROBOTS, VARS = 0xDA00, 0xFD00
OURS, THEIRS = '#4caf50', '#e5534b'


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--cache', required=True)
    p.add_argument('--step', type=int, default=120)
    p.add_argument('--last', type=int, default=36000)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    rows = []
    for f in range(args.step, args.last + 1, args.step):
        path = os.path.join(args.cache, f'{f}_0.bin')
        if not os.path.isfile(path):
            continue
        m = open(path, 'rb').read()
        r = m[ROBOTS - 0x4000:ROBOTS - 0x4000 + 768]
        v = m[VARS - 0x4000:VARS - 0x4000 + 256]
        rows.append(dict(frame=f, ours=sum(1 for i in range(24) if r[16 * i + 1]),
                         theirs=sum(1 for i in range(24, 48) if r[16 * i + 1]),
                         our_fact=sum(v[0x3B:0x41]), their_fact=sum(v[0x43:0x49]),
                         our_bases=v[0x3A], their_bases=v[0x42], day=v[0x37]))
    fr = [x['frame'] for x in rows]
    peak_o = max(rows, key=lambda x: x['ours'])
    peak_t = max(rows, key=lambda x: x['theirs'])
    end = rows[-1]
    print(len(rows), 'samples; peak ours', peak_o['ours'], 'at', peak_o['frame'], 'peak enemy', peak_t['theirs'], 'at',
          peak_t['frame'], 'end', end)

    fig, ax = plt.subplots(figsize=(11, 5.0), dpi=100)
    fig.patch.set_facecolor('#15161b')
    ax.set_facecolor('#1c1d24')
    ax.tick_params(colors='#b8bcc8', labelsize=9)
    for s in ax.spines.values():
        s.set_color('#444')
    ax.step(fr, [x['ours'] for x in rows], where='post', color=OURS, lw=2.4, label='our robots')
    ax.step(fr, [x['theirs'] for x in rows], where='post', color=THEIRS, lw=2.4, label='the enemy\'s robots')
    ax.step(fr, [x['our_fact'] for x in rows], where='post', color=OURS, lw=1.2, ls='--', label='our factories')
    ax.step(fr, [x['their_fact'] for x in rows], where='post', color=THEIRS, lw=1.2, ls='--',
            label='the enemy\'s factories')
    # day boundaries
    ticks, labels, day = [], [], None
    for x in rows:
        if x['day'] != day:
            day = x['day']
            if x is not rows[0]:
                ax.axvline(x['frame'], color='#ffffff', lw=0.4, alpha=0.25)
            ticks.append(x['frame'])
            labels.append(f'day {day}')
    ax.set_xticks(ticks)
    ax.set_xticklabels(labels)
    ax.set_xlim(0, args.last)
    ax.set_ylim(0, 24)
    ax.set_yticks(range(0, 25, 4))
    ax.set_ylabel('count (24 robot slots a side)', color='#b8bcc8', fontsize=9)
    ax.set_xlabel(f'work/deep, frames 0-{args.last} (one sample every {args.step} frames)', color='#b8bcc8',
                  fontsize=9)
    ax.annotate(f'our peak: {peak_o["ours"]} robots', xy=(peak_o['frame'], peak_o['ours']),
                xytext=(peak_o['frame'] - 6000, peak_o['ours'] + 5), color=OURS, fontsize=9.5,
                arrowprops=dict(arrowstyle='->', color=OURS, lw=0.8))
    ax.annotate(f'the enemy\'s peak: {peak_t["theirs"]} robots', xy=(peak_t['frame'], peak_t['theirs']),
                xytext=(peak_t['frame'] - 12000, peak_t['theirs'] + 4), color=THEIRS, fontsize=9.5,
                arrowprops=dict(arrowstyle='->', color=THEIRS, lw=0.8))
    ax.text(args.last - 200, 21.5, f'at the end: robots {end["ours"]} : {end["theirs"]}, '
            f'factories {end["our_fact"]} : {end["their_fact"]}\n'
            f'warbases {end["our_bases"]} : {end["their_bases"]} (none fell)', color='#e8e8ee', fontsize=9.5,
            ha='right', va='top')
    ax.legend(loc='upper left', fontsize=9, frameon=False, labelcolor='#d6d8e0')
    ax.set_title(f'The enemy outbuilds us: three warbases against one, {peak_t["theirs"]} robots against our '
                 f'{peak_o["ours"]} at the peaks', color='#e8e8ee', fontsize=12, loc='left')
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')


if __name__ == '__main__':
    sys.exit(main())
