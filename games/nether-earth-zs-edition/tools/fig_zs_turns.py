#!/usr/bin/env python3
"""Doc 04 figure: where the time of every game turn goes, over the 30 turns of an access trace of r-critical
(docs/img/loop/turn-phases.png). The phases are tools/zs_turn_profile.py's: the PlayLoop call that is running, the
interrupts apart (from the jump to $FDFD until SP is back above what it pushed).

    python3 tools/fig_zs_turns.py --trace work/docs/zsA/rc/traces/8026_0-8326_0.uatr --out docs/img/loop/turn-phases.png
"""
import argparse
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zsa_common as Z  # noqa: E402
import kitlib as K  # noqa: E402

PLAY_LOOP = 0xA69A
CALLS = {0xA69A: 'WaitKey', 0xA69D: 'MoveShip', 0xA6A0: 'WorldTurn', 0xA6A3: 'DrawView', 0xA6A6: 'GameTurn',
         0xA6A9: 'landing checks'}
DRAW = {0xCFD7: 'DrawViewBackground', 0xCCC6: 'DrawMapObjects', 0xD071: 'CopyViewToScreen'}
TURN_PACE = (0xAE1D, 0xAE24)
SHOW = [('WorldTurn', 'the world: the enemy commander, 48 robots, 5 shots', '#5c8fd6'),
        ('DrawViewBackground', 'drawing: clear the view buffer', '#9b7fd1'),
        ('DrawMapObjects', 'drawing: the cells and sprites, back to front', '#c77ddb'),
        ('CopyViewToScreen', 'copying the buffer to the screen', '#e5534b'),
        ('interrupt', 'the interrupts (radar, frame count, sound)', '#4caf50'),
        ('GameTurn', 'GameTurn: clock, captures, game end', '#59c9a5'),
        ('rest', 'WaitKey, MoveShip, landing checks', '#999999'),
        ('TurnPace', 'TurnPace: waiting for the 10th interrupt', '#d9a441')]


def turns(trace):
    xs = trace.instructions
    absolute = [(x.frame - trace.from_frame) * trace.frame_t + x.t for x in xs]
    starts = [i for i, x in enumerate(xs) if x.pc == PLAY_LOOP]
    out = []
    for lo, hi in zip(starts, starts[1:]):
        phase, irq_sp, total = 'WaitKey', None, {}
        for i in range(lo, hi):
            x = xs[i]
            if irq_sp is None and x.pc == 0xFDFD:
                irq_sp = x.sp
            elif irq_sp is not None and x.sp > irq_sp:
                irq_sp = None
            if x.pc in CALLS:
                phase = CALLS[x.pc]
            elif x.pc in DRAW and phase.startswith('Draw'):
                phase = DRAW[x.pc]
            elif TURN_PACE[0] <= x.pc <= TURN_PACE[1] and phase == 'GameTurn':
                phase = 'TurnPace'
            name = 'interrupt' if irq_sp is not None else phase
            if name in ('WaitKey', 'MoveShip', 'landing checks', 'DrawView'):
                name = 'rest'
            total[name] = total.get(name, 0) + absolute[i + 1] - absolute[i]
        out.append((xs[lo].frame, absolute[hi] - absolute[lo], total))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--trace', required=True)
    p.add_argument('--out', required=True)
    a = p.parse_args()
    tr = K.access_trace(Z.UNREAL).load(a.trace)
    rows = turns(tr)
    keys = [k for k, _, _ in SHOW]
    print('| turn from frame | T | ' + ' | '.join(keys) + ' |')
    for f, t, tot in rows:
        print(f'| {f} | {t} | ' + ' | '.join(str(tot.get(k, 0)) for k in keys) + ' |')
    n = len(rows)
    print('mean', {k: round(sum(r[2].get(k, 0) for r in rows) / n) for k in keys}, 'turn', sum(r[1] for r in rows) / n)
    for k in keys:
        v = [r[2].get(k, 0) for r in rows]
        print(k, 'min', min(v), 'max', max(v))
    fig, ax = plt.subplots(figsize=(12, 5.8), dpi=110)
    fig.patch.set_facecolor('#15161b')
    ax.set_facecolor('#1c1d24')
    ax.tick_params(colors='#b8bcc8', labelsize=8.5)
    for s in ax.spines.values():
        s.set_color('#444')
    bottom = [0] * n
    for k, label, colour in SHOW:
        v = [r[2].get(k, 0) / Z.FRAME_T for r in rows]
        ax.bar(range(n), v, bottom=bottom, color=colour, label=label, width=0.8)
        bottom = [b + x for b, x in zip(bottom, v)]
    ax.axhline(10, color='#ffffff', lw=0.8, ls=':')
    ax.text(n - 0.5, 10.15, 'every turn lasts 10 frames: TurnPace waits for what the work left', ha='right',
            color='#e8e8ee', fontsize=9)
    ax.set_xticks(range(0, n, 3))
    ax.set_xticklabels([str(rows[i][0]) for i in range(0, n, 3)])
    ax.set_xlabel('the turn, by the frame its PlayLoop pass starts in (r-critical: CRITICAL, day 1 from 18:20, the ship parked: the view does not change)', color='#b8bcc8',
                  fontsize=9)
    ax.set_ylabel('frames (71680 T each)', color='#b8bcc8', fontsize=9)
    ax.set_ylim(0, 11.6)
    ax.set_title(f'{n} game turns of the \'99: the view takes 7.5 of the 10 frames, the world 0.4-1.0, the wait the rest',
                 color='#e8e8ee', fontsize=12, loc='left')
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.14), ncol=3, fontsize=8.5, frameon=False,
              labelcolor='#d6d8e0')
    fig.savefig(a.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(a.out)


if __name__ == '__main__':
    main()
