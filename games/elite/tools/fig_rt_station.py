#!/usr/bin/env python3
"""The station flight's two pass lengths, taken apart (docs/04-game-loop.md 4.5, docs/runtime-analysis.md 3).

    python3 tools/fig_rt_station.py      # -> docs/img/loop/station-passes.png; prints the table of the passes

The window f1 1500-1600 (the station and the planet ahead, nothing else in view) holds 16 whole passes: twelve
of 383-389k T and four of about 450k. Each pass's T (from one ClearView to the next, eprof's top_runs) is split
into CloakKey (its HALT, run every second pass) and everything else, and CloakKey's start is placed after the last
interrupt (the HALTs all end at the same T of the trace's frame numbering, 4610: that is where the interrupt comes). The work is the same in every pass (380-389k T); the long passes are the ones whose
HALT starts just after an interrupt and so waits almost a whole frame.
"""
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import eprof  # noqa: E402
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402


def passes():
    sc = S.scene('station')
    t = eprof.load(S.work(sc[2]), sc[3])
    runs = eprof.profile(t, top_runs=True, keep_screen=False)['top_runs']
    first = int(sc[3].split(':')[0])
    starts = [i for i, r in enumerate(runs) if r[2] == 'ClearView']
    out = []
    for a, b in zip(starts, starts[1:]):
        per = defaultdict(int)
        halt_at = None
        for r in runs[a:b]:
            per[r[2]] += r[1]
            if r[2] == 'CloakKey' and halt_at is None:
                halt_at = r[0]
        length = runs[b][0] - runs[a][0]
        out.append({'frame': first + runs[a][0] // S.FRAME_T, 'length': length, 'halt': per['CloakKey'],
                    'work': length - per['CloakKey'], 'phase': halt_at % S.FRAME_T if halt_at is not None else None})
    return out


def main():
    rows = passes()
    # the interrupt's place in the trace's frame numbering: where every HALT ends
    ends = sorted({(r['phase'] + r['halt']) % S.FRAME_T for r in rows if r['halt'] > 1000})
    irq = ends[len(ends) // 2]
    print('the HALTs end at T %s of the frame (the interrupt)' % ends)
    for r in rows:
        if r['phase'] is not None:
            r['after'] = (r['phase'] - irq) % S.FRAME_T
    print('| Pass (frame) | Length | Work | CloakKey (HALT) | CloakKey starts, T after the interrupt |')
    print('| ---: | ---: | ---: | ---: | ---: |')
    for r in rows:
        print('| %d | %d | %d | %d | %s |' % (r['frame'], r['length'], r['work'], r['halt'], r.get('after')))
    fig, (ax, bx) = P.figure(14, 4.6, ncols=2, gridspec_kw={'width_ratios': [3, 2]})
    for i, r in enumerate(rows):
        ax.bar(i, r['work'], color=P.READ, width=0.7)
        ax.bar(i, r['halt'], bottom=r['work'], color=P.HOT, width=0.7)
    ax.axhline(S.FRAME_T * 5.5, color=P.DIM, lw=0.6, ls=':')
    ax.set_xticks(range(len(rows)))
    ax.set_xticklabels([str(r['frame']) for r in rows], fontsize=7.5, rotation=60)
    ax.set_xlabel('the pass, by the frame it starts in (f1)')
    ax.set_ylabel('T')
    ax.set_ylim(0, 480000)
    ax.legend(handles=[P.plt.matplotlib.patches.Patch(color=P.READ, label='the work (all but CloakKey)'),
                       P.plt.matplotlib.patches.Patch(color=P.HOT, label='CloakKey: its HALT')],
              fontsize=8, loc='lower right')
    ax.set_title('Every pass does the same 383-389k T of work; the four 450k passes add a HALT of a whole frame',
                 fontsize=9.5)
    xs = [r['after'] for r in rows if r['phase'] is not None and r['halt'] > 1000]
    ys = [r['halt'] for r in rows if r['phase'] is not None and r['halt'] > 1000]
    bx.scatter(xs, ys, color=P.HOT, s=22, zorder=3)
    bx.plot([0, S.FRAME_T], [S.FRAME_T, 0], color=P.DIM, lw=0.8, ls='--')
    bx.text(S.FRAME_T * 0.5, S.FRAME_T * 0.55, 'HALT = frame - start', color=P.DIM, fontsize=8, rotation=-28)
    bx.set_xlim(0, S.FRAME_T)
    bx.set_ylim(0, S.FRAME_T * 1.05)
    bx.set_xlabel('T after the last interrupt where CloakKey starts')
    bx.set_ylabel('the HALT\'s T')
    bx.set_title('The HALT waits for the next interrupt: the pass ends\njust after one (the drift of 1554-1590) and '
                 'waits a frame', fontsize=9.5)
    fig.tight_layout()
    P.save(fig, 'docs/img/loop/station-passes.png')


if __name__ == '__main__':
    main()
