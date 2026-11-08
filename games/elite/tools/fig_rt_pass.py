#!/usr/bin/env python3
"""One pass of FlightLoop in space, step by step against the TV frames (docs/04-game-loop.md 4.3,
docs/runtime-analysis.md 3).

    python3 tools/fig_rt_pass.py

Each row is one pass (from a ClearView call to the next): the routine FlightLoop called at each moment (the bottom
of eprof's shadow stack; an interrupt shows as the routine it cut), as coloured spans along the pass's T, with the
TV frame boundaries. Rows: a median pass of empty space (f1 2400-2500), of the station flight (f1 1500-1600) and
the longest pass of the fight (w1 3470-3620, the laser firing). Figure: docs/img/loop/pass.png.
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import eprof  # noqa: E402
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402

ROWS = [('deep', 'median'), ('station', 'median'), ('combat', 'longest')]


def passes(runs):
    """[(start index, end index)] of the runs between ClearView starts"""
    starts = [i for i, r in enumerate(runs) if r[2] == 'ClearView']
    return list(zip(starts, starts[1:]))


def main():
    rows = []
    names = []
    for key, pick in ROWS:
        sc = S.scene(key)
        t = eprof.load(S.work(sc[2]), sc[3])
        p = eprof.profile(t, top_runs=True, keep_screen=False)
        runs = p['top_runs']
        ps = passes(runs)
        lengths = [runs[b][0] - runs[a][0] for a, b in ps]
        if pick == 'median':
            k = int(np.argsort(lengths)[len(lengths) // 2])
        else:
            k = int(np.argmax(lengths))
        a, b = ps[k]
        t0 = runs[a][0]
        seg = [(r[0] - t0, r[1], r[2]) for r in runs[a:b]]
        rows.append((key, pick, t0, lengths[k], seg))
        for _s, d, n in seg:
            if n not in names:
                names.append(n)
        print('%s: %d passes, lengths %s T; picked %d T' % (key, len(ps), sorted(lengths), lengths[k]))
    weight = {}
    for _k, _p, _t0, _L, seg in rows:
        for _s, d, n in seg:
            weight[n] = weight.get(n, 0) + d
    order = sorted(weight, key=lambda n: -weight[n])
    cols = P.colours(order, {'HALT': P.OTHER, 'FlightLoop': (0.5, 0.5, 0.55)})
    fig, ax = P.figure(14, 5.2)
    for i, (key, pick, t0, L, seg) in enumerate(rows):
        for s, d, n in seg:
            ax.barh(i, d, left=s, height=0.62, color=cols[n], edgecolor='none')
            if d > 16000:
                ax.text(s + d / 2, i, n, ha='center', va='center', fontsize=7, color='black', rotation=0,
                        clip_on=True)
        # the frame boundaries inside the pass
        first = (t0 // S.FRAME_T + 1) * S.FRAME_T - t0
        for fb in range(first, L, S.FRAME_T):
            ax.plot([fb, fb], [i - 0.38, i + 0.38], color=P.WRITE, lw=1)
        ax.text(L, i, '  %d T = %.2f frames' % (L, L / S.FRAME_T), va='center', fontsize=8)
    ax.set_yticks(range(len(rows)))
    ax.set_yticklabels(['%s\n(%s pass)' % (S.scene(k)[1], p) for k, p, _a, _b, _c in rows], fontsize=8.5)
    ax.invert_yaxis()
    ax.set_xlim(0, max(r[3] for r in rows) * 1.18)
    ax.set_xlabel('T from the pass\'s ClearView (yellow ticks: a TV frame starts)')
    top = [n for n in order if weight[n] > 0.02 * sum(weight.values())]
    handles = [P.plt.matplotlib.patches.Patch(color=cols[n], label=n) for n in top]
    ax.legend(handles=handles, ncol=6, fontsize=7.5, loc='upper center', bbox_to_anchor=(0.5, -0.16))
    ax.set_title('One FlightLoop pass in space, in the order FlightLoop calls its work: clear, sun and planet, '
                 'stardust, texts, ships, copy, scanner, bars,\nCloakKey (its HALT every second pass), dashboard; '
                 'the laser\'s sound stretches the fight\'s pass inside the copy', fontsize=10)
    fig.tight_layout()
    P.save(fig, 'docs/img/loop/pass.png')


if __name__ == '__main__':
    main()
