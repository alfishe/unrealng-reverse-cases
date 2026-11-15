#!/usr/bin/env python3
"""Doc 10's measured figure: Rex's jump (c1), the shield recharging and the power level (rzx-p1-04000), from
memory samples of the recordings (TTD memory_at, the state at each frame's start).

    python3 tools/fig_gameplay.py OUT.png --c1 C1.jsonl --r04 R04.jsonl

C1.jsonl and R04.jsonl are samples of $A012-$A0C3 (and more) taken by work/docs/rxC/sample.py:
    sample.py --work W --frames 15000:20470 --range A012-A0C3 --range D832-D856 --range 5E66-614D --out C1.jsonl
    sample.py --work W --frames 0:2000:2 --range A012-A0C3 --range D832-D856 --range 5E66-614D --out R04.jsonl
on c1 (work/stage1/c1/session.ttd) and rzx-p1-04000 (work/stage1/rec/rzx-p1-04000/session.ttd).
"""
import argparse
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def labels():
    out = {}
    for line in open(os.path.join(ROOT, 'build', 'game.lst')):
        m = re.match(r'^\s*\d+\+*\s+([0-9A-F]{4})\s+([A-Za-z_]\w*):', line)
        if m:
            out[m.group(2)] = int(m.group(1), 16)
    return out


def rows(path, names):
    L = labels()
    for line in open(path):
        r = json.loads(line)
        v = bytes.fromhex(r['A012'])
        yield r['frame'], {n: v[L[n] - 0xA012] for n in names}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--c1', required=True)
    ap.add_argument('--r04', required=True)
    a = ap.parse_args()
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 10, 'axes.titlesize': 10})
    fig, axes = plt.subplots(1, 3, figsize=(10.5, 4.2), gridspec_kw={'width_ratios': [1.2, 1, 1.3]})
    # the jump: one point a pass (the samples where X changed)
    pts, last = [], None
    for f, v in rows(a.c1, ['RexX', 'RexY', 'Jumping', 'FallSpeed']):
        if 17000 <= f <= 17090 and (last is None or v['RexX'] != last['RexX'] or v['RexY'] != last['RexY']):
            pts.append((f, v))
            last = v
    ax = axes[0]
    for (f, v) in pts:
        c = '#d04040' if v['Jumping'] else ('#3060c0' if v['FallSpeed'] else '#303030')
        ax.plot(v['RexX'], v['RexY'], 'o', color=c, ms=5)
    ax.plot([v['RexX'] for _, v in pts], [v['RexY'] for _, v in pts], '-', color='#a0a0a0', lw=0.8, zorder=0)
    ax.invert_yaxis()
    ax.set_xlabel('RexX (pixels)')
    ax.set_ylabel('RexY (pixels, down)')
    ax.set_title(f'c1 TTD frames {pts[0][0]}-{pts[-1][0]}: a jump, one dot a pass\n'
                 'red rising (Jumping 1), blue falling, black on ground')
    # the shield recharging
    ax = axes[1]
    xs, ys = [], []
    for f, v in rows(a.r04, ['ShieldEnergy']):
        if f <= 120:
            xs.append(f)
            ys.append(v['ShieldEnergy'])
    ax.step(xs, ys, where='post', color='#30a030')
    ax.set_xlabel('rzx-p1-04000 TTD frame')
    ax.set_ylabel('ShieldEnergy')
    ax.set_title('the recharger: +1 a pass\nup to 99, the shield off')
    # the power
    ax = axes[2]
    xs, lv, pc = [], [], []
    for f, v in rows(a.r04, ['PowerLevel', 'PowerCount', 'Weapon', 'Dying']):
        xs.append(f)
        lv.append(v['PowerLevel'] + 6 * (v['Weapon'] != 0))
        pc.append(v['PowerCount'])
    ax.step(xs, pc, where='post', color='#3060c0', label='PowerCount')
    ax.set_ylabel('PowerCount', color='#3060c0')
    ax2 = ax.twinx()
    ax2.step(xs, lv, where='post', color='#d04040', label='level')
    ax2.set_yticks(range(1, 12))
    ax2.set_yticklabels(['gun 1', 'gun 2', 'gun 3', 'gun 4', 'gun 5', '', 'double 1', 'double 2', 'double 3', 'double 4', 'double 5'])
    ax2.set_ylim(0.5, 11.5)
    for f, text in ((440, 'double fire\nshots'), (1094, 'death'), (1528, 'big pod')):
        ax.axvline(f, color='#c0c0c0', lw=0.8)
        ax.text(f + 15, 115, text, fontsize=10, va='top')
    ax.set_ylim(0, 120)
    ax.set_xlabel('rzx-p1-04000 TTD frame')
    ax.set_title('weapon and power level (red, right)\nPowerCount (blue, left)')
    fig.tight_layout()
    fig.savefig(a.out, dpi=100)
    print(a.out)


if __name__ == '__main__':
    main()
