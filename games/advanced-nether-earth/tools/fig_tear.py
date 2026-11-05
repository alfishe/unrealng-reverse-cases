#!/usr/bin/env python3
"""Doc 04 / 06 figure: where the view copy starts in its frame decides whether, and where, the screen tears.

    python3 tools/fig_tear.py --trace work/docR/d1/traces/11400_0-11525_0.uatr ... --out docs/img/loop/tear-band.png

For every copy of the view the traces hold whole (tools/ane_trace.py): the T-state of its first instruction in
its frame, and the screen line where the beam overtakes it (none: the frame shows the old view whole, the next the
new one whole). Also, for each copy, the T-states the music player took in the interrupts between the turn's
start and the copy's start: without the music the copy would start that much earlier (a computation, not a
recording), drawn as a hollow mark on the same model.

The model: the copy writes view line L (screen line L) at t0 + 379 (L - 8) (379 T a line on the Pentagon, measured),
the beam reaches it at 17 988 + 224 L; a copy that starts before the beam reaches screen line 8 (T 19 780) is
overtaken at L = (21 020 - t0) / 155; one that starts while the beam is on the paper is behind it all the way and
shows whole in the next frame; one that starts late enough to run into the next interrupt is paused by it and
overtaken near the bottom of the next frame.
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ane_trace as A  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'
F = A.FRAME_T


def model_line(t0):
    if t0 < A.PAPER_T + 8 * A.LINE_T:
        return (21020 - t0) / 155
    return None


def collect(path):
    trace = A.load(path)
    out = []
    starts, copies = A.turns(trace)
    music = []  # (abs t, T) per instruction of the player
    prev = None
    for x, bank, ph in A.walk(trace):
        if prev is not None and prev[1] == 'music':
            px = prev[0]
            music.append((px.frame * F + px.t, (x.frame - px.frame) * F + x.t - px.t))
        prev = (x, ph)
    for cf, ct in copies:
        w = A.copy_writes(trace, cf)
        if len(w) < 3200:
            continue
        s = [st for st in starts if st[0] * F + st[1] < cf * F + ct]
        if not s:
            continue
        sf, stt = s[-1]
        a0 = sf * F  # the interrupt that ended the wait: its music delayed the turn's start
        a1 = cf * F + ct
        m = sum(dt for t, dt in music if a0 <= t < a1)
        tf, line, new = A.tear(w, cf)
        out.append((ct, line, m, cf, tf))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--trace', action='append', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    rows = []
    for t in args.trace:
        rows += collect(t)
    for r in rows:
        print('copy frame %d T %d tear %s music before it %d T' % (r[3], r[0], r[1], r[2]))
    fig, ax = plt.subplots(figsize=(12, 6.4), dpi=110)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(AX)
    ax.tick_params(colors=DIM, labelsize=9)
    for s in ax.spines.values():
        s.set_color('#444')
    NONE, LATE = 185, 172
    # bands
    ax.axvspan(0, 19780, color='#e5534b', alpha=0.12, lw=0)
    ax.axvspan(19780, 52000, color='#4caf50', alpha=0.10, lw=0)
    ax.axvspan(52000, F, color='#e5534b', alpha=0.12, lw=0)
    ax.text(1000, 5, 'starts before the beam reaches\nthe view (T 19 780): the beam\novertakes the copy, a tear',
            color='#f08a84', fontsize=9, va='top')
    ax.text(21000, 5, 'starts while the beam draws the paper: the copy stays behind the beam;\n'
            'this frame shows the old view whole, the next the new view whole', color='#7fd483', fontsize=9, va='top')
    ax.text(F - 500, 5, 'runs into the next\ninterrupt: overtaken\nnear the bottom', color='#f08a84', fontsize=9,
            va='top', ha='right')
    xs = list(range(0, 19780, 200))
    ax.plot(xs, [model_line(x) for x in xs], color='#e5534b', lw=1, ls='--')
    ax.text(7000, 80, 'model:\nline = (21 020 - T) / 155', color='#e5534b', fontsize=8.5)
    torn = [(t, l) for t, l, m, cf, tf in rows if l is not None]
    whole = [(t, NONE) for t, l, m, cf, tf in rows if l is None]
    ax.scatter(*zip(*torn), s=28, color='#e5534b', zorder=3, label=f'a copy of the recording, torn ({len(torn)})')
    ax.scatter(*zip(*whole), s=28, color='#4caf50', zorder=3, label=f'a copy of the recording, whole ({len(whole)})')
    hyp = []
    for t, l, m, cf, tf in rows:
        h = (t - m) % F
        ml = model_line(h)
        hyp.append((h, ml if ml is not None else (NONE if h < 52000 else LATE)))
    ax.scatter(*zip(*hyp), s=30, facecolors='none', edgecolors='#26c6da', zorder=3,
               label='the same copy without the music (computed)')
    ms = sorted(m for t, l, m, cf, tf in rows)
    med = ms[len(ms) // 2]
    ax.annotate('', xy=(30000 - med, 150), xytext=(30000, 150),
                arrowprops=dict(arrowstyle='->', color='#26c6da', lw=1.2))
    ax.text(30000 - med / 2, 146, f'the music before a copy: {ms[0]}-{ms[-1]} T (median {med})', color='#26c6da',
            fontsize=9, ha='center')
    ax.axhline(NONE - 6, color='#444', lw=0.6)
    ax.set_yticks([0, 25, 50, 75, 100, 125, 150, LATE, NONE])
    ax.set_yticklabels(['0', '25', '50', '75', '100', '125', '150', 'late (no model)', 'no tear'])
    ax.set_ylim(NONE + 8, -6)
    ax.set_xlim(0, F)
    ax.set_xlabel('T-state of the copy\'s start in its frame (from the interrupt; 71 680 a frame)', color=DIM,
                  fontsize=9)
    ax.set_ylabel('screen line of the tear', color=DIM, fontsize=9)
    ax.set_title(f'{len(rows)} view copies of d1: a copy that starts before T 19 780 tears the screen, '
                 f'one that starts later does not', color=FG, fontsize=12, loc='left')
    ax.legend(loc='lower center', fontsize=8.5, frameon=False, labelcolor='#d6d8e0', ncol=3,
              bbox_to_anchor=(0.5, -0.24))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(f'{len(rows)} copies, {len(torn)} torn; music before a copy {ms[0]}..{ms[-1]} median {med}')


if __name__ == '__main__':
    sys.exit(main())
