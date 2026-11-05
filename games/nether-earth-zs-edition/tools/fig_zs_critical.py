#!/usr/bin/env python3
"""Doc 01 figure: what CRITICAL does to the enemy over the days of r-critical (docs/img/design/critical-days.png).

Samples the recording every --step frames with TTD memory_at: the clock Clock ($FD35 minutes, $FD36 hours,
$FD37-$FD38 days), the 24 enemy robot records EnemyRobots ($DB80, 16 bytes, +$01 not 0 = alive, +$07 the parts),
the enemy's robot count EnemyRobotCount ($FD49), the enemy's resources EnemyResources ($FD4A, 7 bytes) and the
player's Resources ($FD22). Top: the live enemy robots split by their parts byte (fully upgraded $FC, other);
bottom: the enemy's general resource and the player's. Midnights (the clock's day count stepping) are the dashed
lines: there DailyProduction runs, and on HARD / CRITICAL its call at $AE41 is UpgradeEnemyRobots ($A5D6).

    python3 tools/fig_zs_critical.py --work work/docs/zsA/rc --from 2920 --to 12100 --step 40 \
        --out docs/img/design/critical-days.png [--json work/docs/zsA/critical-days.json]
"""
import argparse
import json
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zsa_common as Z  # noqa: E402


def sample(s, frame):
    v = Z.memory_at(s, frame, 0, 0xFD00, 0x100)
    rob = Z.memory_at(s, frame, 0, 0xDA00, 0x300)
    enemy = [rob[0x180 + 16 * i: 0x190 + 16 * i] for i in range(24)]
    ours = [rob[16 * i: 16 * i + 16] for i in range(24)]
    return {'frame': frame, 'minutes': v[0x35], 'hours': v[0x36], 'day': v[0x37] | v[0x38] << 8,
            'enemy_count': v[0x49], 'enemy_res': list(v[0x4A:0x51]), 'res': list(v[0x22:0x29]),
            'enemy_parts': [r[7] for r in enemy if r[1]], 'our_parts': [r[7] for r in ours if r[1]],
            'enemy_slots_parts': [r[7] for r in enemy]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--from', dest='f0', type=int, default=2920)
    ap.add_argument('--to', dest='f1', type=int, default=12100)
    ap.add_argument('--step', type=int, default=40)
    ap.add_argument('--out', required=True)
    ap.add_argument('--json')
    a = ap.parse_args()
    s = Z.session(a.work)
    rows = [sample(s, f) for f in range(a.f0, a.f1 + 1, a.step)]
    if a.json:
        json.dump(rows, open(a.json, 'w'), indent=0)
    xs = [r['frame'] for r in rows]
    full = [sum(1 for p in r['enemy_parts'] if p == 0xFC) for r in rows]
    other = [len(r['enemy_parts']) - f for r, f in zip(rows, full)]
    midnights = [b['frame'] for a_, b in zip(rows, rows[1:]) if b['day'] != a_['day']]

    fig, (ax, bx) = plt.subplots(2, 1, figsize=(9.6, 5.6), sharex=True, gridspec_kw={'height_ratios': [3, 2]})
    fig.suptitle("CRITICAL in r-critical: at each midnight every enemy robot becomes $FC\n"
                 "(anti-grav, four weapons, electronics); the enemy's resources are refilled to 99 before each robot", fontsize=11)
    ax.stackplot(xs, full, other, colors=['#e5534b', '#5c8fd6'],
                 labels=['enemy robots with parts $FC (upgraded)', 'enemy robots with other parts (built since)'])
    ax.set_ylabel(r'live enemy robots (\$DB80, +\$01 not 0)')
    ax.legend(loc='upper left', fontsize=8)
    bx.plot(xs, [r['enemy_res'][0] for r in rows], color='#e5534b', lw=2.5, ls=(0, (6, 4)), label="enemy general ($FD4A), always 99")
    bx.plot(xs, [min(r['enemy_res'][1:]) for r in rows], color='#d9a441', label="enemy, lowest of the six others")
    bx.plot(xs, [r['res'][0] for r in rows], color='#4caf50', label='our general ($FD22), always 99 (the cap)')
    bx.set_ylabel('resources')
    bx.set_ylim(-5, 110)
    bx.legend(loc='center left', fontsize=8)
    bx.set_xlabel('frame of r-critical (50 a second; a game day is 2880 frames)')
    for m in midnights:
        r = next(r for r in rows if r['frame'] == m)
        for x_ in (ax, bx):
            x_.axvline(m, color='#888', ls='--', lw=0.8)
        ax.text(m, ax.get_ylim()[1] * 0.97, f" day {r['day']}", fontsize=8, va='top', color='#444')
    fig.tight_layout()
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    fig.savefig(a.out, dpi=100)
    for r in rows[::10]:
        print(r['frame'], f"day {r['day']} {r['hours']:02d}.{r['minutes']:02d}", 'enemy', len(r['enemy_parts']),
              'count', r['enemy_count'], 'parts', ' '.join(f'{p:02X}' for p in r['enemy_parts'][:8]),
              'eres', r['enemy_res'], 'res', r['res'], 'ours', len(r['our_parts']))
    print('midnights', midnights)


if __name__ == '__main__':
    main()
