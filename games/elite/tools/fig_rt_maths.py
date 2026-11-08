#!/usr/bin/env python3
"""The maths routines at run time (docs/runtime-analysis.md, section 7): calls a frame, T a call, share of the frame.

    python3 tools/fig_rt_maths.py

Every call of the routines in rtscenes.CALLS is logged by eprof with its inclusive T (from the CALL's target to the
RET back), so a call an interrupt cut carries the interrupt too: those (over 3000 T beyond the routine's own
median by more than 2000 T) are left out of the T a call and counted apart. Figure: docs/img/runtime/maths.png.
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402

MATHS = [
    ('Multiply8High', 'A = B x C / 256, quarter squares'),
    ('Multiply8', 'HL = B x C, quarter squares'),
    ('MultiplyScaled', 'B scaled x matrix byte'),
    ('MulBits', 'HL = A x C, shift and add'),
    ('Divide16', 'BC = HLA / DE, shifts'),
    ('DividePoint', 'perspective division'),
    ('Divide24', '24-bit fraction'),
    ('DivideFrac8', 'A x 256 / B, small A'),
    ('DivideShifted', 'stardust depth division'),
    ('DivideFraction', 'A x 256 / B'),
    ('LineFraction', 'the line\'s slope'),
    ('SquareRoot', 'Newton, 12 bits'),
]
SCENES = ['combat', 'station', 'deep', 'title']


def per_call(p, name):
    v = [d for _t, d in p['calls'].get(name, [])]
    if not v:
        return [], 0
    med = float(np.median(v))
    keep = [d for d in v if d <= med + 2000]
    return keep, len(v) - len(keep)


def main():
    profs = {k: S.profile(S.scene(k)) for k in SCENES}
    fig, axes = P.figure(9.6, 9, nrows=1, ncols=3, gridspec_kw={'width_ratios': [1.7, 1, 1]})
    names = [n for n, _d in MATHS]
    y = np.arange(len(names))
    cols = P.colours(SCENES)

    ax = axes[0]
    data = []
    for n in names:
        allv = []
        for k in SCENES:
            allv += per_call(profs[k], n)[0]
        data.append(allv or [0])
    bp = ax.boxplot(data, vert=False, positions=y, widths=0.6, patch_artist=True, showfliers=False)
    for b in bp['boxes']:
        b.set_facecolor(P.READ)
        b.set_edgecolor(P.TEXT)
    for el in ('whiskers', 'caps', 'medians'):
        for line in bp[el]:
            line.set_color(P.TEXT)
    for i, v in enumerate(data):
        ax.text(max(v) * 1.05 + 5, i, '%d T (n %d)' % (np.median(v), len(v)), va='center', fontsize=8.5)
    ax.set_yticks(y)
    ax.set_yticklabels(['%s\n%s' % (n, d) for n, d in MATHS], fontsize=8.5)
    ax.invert_yaxis()
    ax.set_xscale('log')
    ax.set_xlim(40, 20000)
    ax.set_xlabel('T-states a call, inclusive\n(log; the four scenes together)')
    ax.set_title('T a call (box: the spread, number: the median)', fontsize=10)

    ax = axes[1]
    h = 0.2
    for j, k in enumerate(SCENES):
        p = profs[k]
        fr = p['frames'][1] - p['frames'][0]
        vals = [len(p['calls'].get(n, [])) / fr for n in names]
        ax.barh(y + (j - 1.5) * h, vals, height=h, color=cols[k], label=S.scene(k)[1])
    ax.set_yticks(y)
    ax.set_yticklabels([])
    ax.invert_yaxis()
    ax.set_xscale('symlog', linthresh=1)
    ax.set_xlabel('calls a TV frame\n(log above 1)')
    ax.set_title('Calls a frame', fontsize=10)

    ax = axes[2]
    for j, k in enumerate(SCENES):
        p = profs[k]
        vals = [100 * p['routines'].get(n, {}).get('incl', 0) / p['total_t'] for n in names]
        ax.barh(y + (j - 1.5) * h, vals, height=h, color=cols[k])
        for i, v in enumerate(vals):
            if v >= 1:
                ax.text(v, i + (j - 1.5) * h, ' %.1f' % v, va='center', fontsize=8)
    ax.set_yticks(y)
    ax.set_yticklabels([])
    ax.invert_yaxis()
    ax.set_xlabel('% of the window\n(inclusive)')
    ax.set_title('Share of the time', fontsize=10)
    tot = {k: sum(profs[k]['routines'].get(n, {}).get('self', 0) for n in names) / profs[k]['total_t']
           for k in SCENES}
    fig.suptitle('The maths: the quarter-square products are cheap and many (83 and 128 T), the divisions dear '
                 '(500-1500 T), the square root 5000 T;\nthe maths\' self time is %s' % ', '.join(
                     '%.0f %% in %s' % (100 * v, S.scene(k)[1]) for k, v in tot.items()), fontsize=11)
    fig.legend(*axes[1].get_legend_handles_labels(), loc='lower center', ncol=2, fontsize=9, frameon=False)
    fig.tight_layout(rect=(0, 0.07, 1, 1))
    P.save(fig, 'docs/img/runtime/maths.png')
    for n in names:
        allv, cut = [], 0
        for k in SCENES:
            v, c = per_call(profs[k], n)
            allv += v
            cut += c
        if allv:
            print('%-15s median %5d min %5d max %5d n %6d cut %d' % (n, np.median(allv), min(allv), max(allv),
                                                                     len(allv), cut))


if __name__ == '__main__':
    main()
