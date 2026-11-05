#!/usr/bin/env python3
"""The play interrupt's cost per frame, Nether Earth against Advanced Nether Earth, from one access trace of each
(docs/img/diff/interrupt-cost.png, work/diff/code.md).

    python3 tools/fig_diff_interrupt.py [--ne TRACE] [--ane TRACE] [--out PNG]

NE: games/nether-earth/work/docA/deep/traces/20004_0-20015_0.uatr (the bot's game `deep`, 48K, 69 888 T a frame).
ANE: work/docR/d1/traces/13005_0-13017_0.uatr (recording d1, Pentagon 128, 71 680 T a frame).

An interrupt runs from the IM 2 jump (NE `$FDFD`, ANE `$6969`) until SP rises above the frame it pushed. Its time is
the sum of the gaps between instruction starts, split by the code that runs: the radar (ShowRadar `$D59E`,
FillAttr16 `$D5BD`), the shot sound (SoundEffect `$D5C4`), the music player (ANE: bank 1 at `$C000`), the paging
glue round it (ANE: PlayMusic `$67B1-$67D8`) and the rest (the IM 2 jump, PlayInterrupt's counters and pushes).
"""

import argparse
import os
import sys
from collections import Counter, defaultdict

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False  # hex addresses: $ is not math

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import ane_trace as A  # noqa: E402
import kitlib as K  # noqa: E402

NE_TRACE = os.path.join(HERE, '..', '..', 'nether-earth', 'work', 'docA', 'deep', 'traces', '20004_0-20015_0.uatr')
ANE_TRACE = os.path.join(HERE, '..', 'work', 'docR', 'd1', 'traces', '13005_0-13017_0.uatr')
PARTS = [('radar', 'the radar (ShowRadar, FillAttr16): the same code', '#4caf50'),
         ('own', 'PlayInterrupt\'s own work, the IM 2 jump: the same code', '#7a7d8a'),
         ('sound', 'the shot sound (SoundEffect): the same code', '#d9a441'),
         ('glue', 'ANE: the paging round the player (PlayMusic)', '#c77ddb'),
         ('music', 'ANE: the AY music player (bank 1)', '#26c6da')]
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'


def part(pc, bank, game):
    if game == 'ANE' and pc >= 0xC000 and bank == 1:
        return 'music'
    if game == 'ANE' and 0x67B1 <= pc <= 0x67D8:
        return 'glue'
    if 0xD59E <= pc <= 0xD5C3:
        return 'radar'
    if 0xD5C4 <= pc <= 0xD5F7:
        return 'sound'
    return 'own'


def interrupts(trace, game):
    """frame -> Counter(part -> T) over the interrupts that start in the frame"""
    vector = 0x6969 if game == 'ANE' else 0xFDFD
    if game == 'ANE':
        seq = ((x, bank) for x, bank, ph in A.walk(trace))
    else:
        seq = ((x, 0) for x in trace.instructions)
    out = defaultdict(Counter)
    ft = trace.frame_t
    int_sp, start, prev = None, None, None
    for x, bank in seq:
        if prev is not None and int_sp is not None:
            px, pb = prev
            out[start][part(px.pc, pb, game)] += (x.frame - px.frame) * ft + x.t - px.t
        if x.pc == vector and int_sp is None:
            int_sp, start = x.sp, x.frame
        elif int_sp is not None and x.sp >= (int_sp + 2) & 0xFFFF and x.pc != vector:
            int_sp = None
        prev = (x, bank)
    frames = sorted(out)
    return {f: out[f] for f in frames[1:-1]}   # whole interrupts only


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--ne', default=NE_TRACE)
    p.add_argument('--ane', default=ANE_TRACE)
    p.add_argument('--out', default=os.path.join(HERE, '..', 'docs', 'img', 'diff', 'interrupt-cost.png'))
    a = p.parse_args()
    at = K.access_trace(None)
    data = {}
    for game, path in (('NE', a.ne), ('ANE', a.ane)):
        tr = at.load(path)
        per = interrupts(tr, game)
        data[game] = (tr.frame_t, per, os.path.basename(path))
        tot = [sum(c.values()) for c in per.values()]
        mean = {k: sum(c[k] for c in per.values()) / len(per) for k, _, _ in PARTS}
        print(f'{game} {os.path.basename(path)}: {len(per)} interrupts, frame {tr.frame_t} T; '
              f'total min {min(tot)} max {max(tot)} mean {sum(tot) / len(tot):.0f} '
              f'({sum(tot) / len(tot) / tr.frame_t:.1%}); ' +
              ', '.join(f'{k} {v:.0f}' for k, v in mean.items() if v))
    fig, axes = plt.subplots(1, 2, figsize=(13, 5.2), facecolor=BG, sharey=True)
    for ax, game in zip(axes, ('NE', 'ANE')):
        ft, per, name = data[game]
        ax.set_facecolor(PANEL)
        frames = list(per)
        bottom = [0] * len(frames)
        for key, label, colour in PARTS:
            vals = [per[f][key] for f in frames]
            if not any(vals):
                continue
            ax.bar(range(len(frames)), vals, bottom=bottom, color=colour, width=0.75, label=label)
            bottom = [b + v for b, v in zip(bottom, vals)]
        mean = sum(bottom) / len(bottom)
        ax.axhline(mean, color='white', lw=0.8, ls='--')
        ax.text(len(frames) - 0.5, 13300, f'mean {mean:,.0f} T = {mean / ft:.1%} of a {ft:,} T frame',
                color='white', fontsize=8.5, ha='right')
        ax.set_ylim(0, 14000)
        ax.set_xticks(range(len(frames)))
        ax.set_xticklabels([str(f) for f in frames], rotation=60, fontsize=7, color=DIM)
        ax.set_xlabel(f'frame of the trace {name}', color=DIM, fontsize=8)
        ax.tick_params(colors=DIM, labelsize=7)
        for s in ax.spines.values():
            s.set_color(DIM)
        title = ('NE (48K, the bot\'s game deep): radar + counters' if game == 'NE'
                 else 'ANE (Pentagon 128, recording d1): the same + one frame of AY music')
        ax.set_title(title, color=TEXT, fontsize=9.5, loc='left')
    axes[0].set_ylabel('T-states in the interrupt', color=DIM, fontsize=8)
    handles, labels = [], []
    for ax in axes:
        for h, lab in zip(*ax.get_legend_handles_labels()):
            if lab not in labels:
                handles.append(h)
                labels.append(lab)
    fig.legend(handles, labels, loc='lower center', ncol=3, frameon=False, labelcolor=TEXT, fontsize=8)
    fig.suptitle('The play interrupt: ANE runs NE\'s radar and counters unchanged, then the music player',
                 color=TEXT, fontsize=11, x=0.01, ha='left')
    fig.tight_layout(rect=(0, 0.1, 1, 0.95))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=100, facecolor=BG)
    print('wrote', a.out)


if __name__ == '__main__':
    main()
