#!/usr/bin/env python3
"""Difference report figure (work/diff/shell.md): one frame of play on each machine, on one T scale from the
interrupt: what the interrupt does, when the beam draws the paper, and where the view copy meets the beam.

    python3 tools/fig_diff_shell_frame.py --out docs/img/diff/shell-frame.png

The traces are the two cases' cached access traces of play:
  Nether Earth: ../nether-earth/work/docA/deep/traces/20004_0-20015_0.uatr (the turn of its doc 04 4.5; the copy
                starts in frame 20011 and is overtaken by the beam in 20012);
  ANE:          work/docR/d1/traces/12446_0-12458_0.uatr (the turn of doc 04 4.5; the copy starts and is overtaken
                in frame 12454).

A trace counts T from the emulator's frame start, not from the interrupt. unreal-ng raises the INT at frame T 1812 on
the 48K (intstart 1811: 14 340 T from the INT to the first paper pixel at frame T 16152) and at frame T 71636 on the
Pentagon (intstart 71635: 17 988 T to the paper, at frame T 17944), core/src/emulator/config.cpp,
ApplyModelTimingDefaults. Every time on the figure is counted from the INT.
"""
import argparse
import sys
from collections import defaultdict

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Patch, Rectangle  # noqa: E402

import fig_diff_shell_common as C  # noqa: E402

K = C.K
NE_INT, ANE_INT = 1812, -44                 # the INT in frame T (ANE: 71636 of the frame before)
NE_PAPER, ANE_PAPER = 14340, 17988          # from the INT to the first paper pixel
PH = [('radar', 'interrupt: the radar picture', '#4caf50'),
      ('music', 'interrupt: one frame of the AY music (ANE only)', '#26c6da'),
      ('int', 'interrupt: the rest (counter, paging, shot sound)', '#2e7d32'),
      ('world', 'ship, robots, shots, clock', '#5c8fd6'),
      ('draw', 'drawing the view in the buffer', '#c77ddb'),
      ('copy', 'copying the view to the screen', '#e5534b'),
      ('wait', 'waiting for the 10th interrupt', '#d9a441'),
      ('other', 'ROM, other', '#666a75')]
COL = {k: c for k, _, c in PH}
INT_KINDS = ('radar', 'music', 'int', 'sound')


def runs_from_int(walk, trace, frame, frame_t, int_at):
    """[(t0, t1, phase)] over one frame counted from its INT"""
    units = max(1, trace.units_per_t)
    out, prev = [], None
    for x, ph in walk:
        ph = 'int' if ph == 'sound' else ph
        t = (x.frame - frame) * frame_t + x.t // units - int_at
        if prev is not None:
            pt, pph = prev
            if pt < frame_t and t > 0:
                a, b = max(pt, 0), min(t, frame_t)
                if out and out[-1][2] == pph and abs(out[-1][1] - a) < 1:
                    out[-1] = (out[-1][0], b, pph)
                else:
                    out.append((a, b, pph))
        prev = (t, ph)
    return out


def interrupt_ends(walk, trace, frame_t, int_at):
    """{frame: T from its INT where its interrupt ends} for every frame of the trace"""
    units = max(1, trace.units_per_t)
    ends, inside, start = {}, False, None
    for x, ph in walk:
        t = x.t // units - int_at
        f = x.frame
        if t >= frame_t:
            f, t = f + 1, t - frame_t
        if t < 0:
            f, t = f - 1, t + frame_t
        if ph in INT_KINDS:
            if not inside:
                inside, start = True, f
        elif inside:
            ends[start] = t + (f - start) * frame_t
            inside = False
    return ends


def tear(writes, frame_t, paper, k):
    """the first screen line the beam reaches before the copy in the beam pass of frame cf + k; its new bytes; the
    copy's bytes the frame shows new"""
    lines = defaultdict(list)
    for t, line, col in writes:
        lines[line].append(t <= k * frame_t + paper + line * C.LINE_T + 4 * col)
    for line in sorted(lines):
        if not all(lines[line]):
            return line, sum(lines[line]), sum(1 for t, l, c in writes if t <= k * frame_t + paper + l * C.LINE_T + 4 * c)
    return None, 0, len(writes)


def copy_writes(walk, trace, cf, frame_t, int_at):
    """[(t from the INT of frame cf, line, column)] of the view copy"""
    out = []
    for x, ph in walk:
        if ph != 'copy':
            continue
        for c in x.cycles:
            if c.tag in 'WE' and 0x4000 <= c.address < 0x5800:
                f, t = trace.cycle_t(x, c)
                out.append(((f - cf) * frame_t + t - int_at, K.screen_line(c.address), c.address & 31))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--ne-trace', default=C.NE + '/work/docA/deep/traces/20004_0-20015_0.uatr')
    p.add_argument('--ane-trace', default=C.ANE + '/work/docR/d1/traces/12446_0-12458_0.uatr')
    p.add_argument('--ne-frame', type=int, default=20012, help='the frame the beam overtakes the copy in')
    p.add_argument('--ane-frame', type=int, default=12454)
    p.add_argument('--out', default=C.out_path('shell-frame.png'))
    p.add_argument('--unreal')
    args = p.parse_args()
    at = K.access_trace(args.unreal)
    ne, ane = at.load(args.ne_trace), at.load(args.ane_trace)

    machines = [
        ('Nether Earth, 48K', ne, C.ne_walk, args.ne_frame, C.NE_FRAME_T, NE_INT, NE_PAPER, C.NE_COL),
        ('ANE, Pentagon 128', ane, C.ane_walk, args.ane_frame, C.ANE_FRAME_T, ANE_INT, ANE_PAPER, C.ANE_COL),
    ]
    fig = plt.figure(figsize=(13, 9.6), dpi=110)
    gs = fig.add_gridspec(2, 1, height_ratios=[1.25, 3], hspace=0.42)
    ax, bx = fig.add_subplot(gs[0]), fig.add_subplot(gs[1])
    C.style(fig, (ax, bx))

    for row, (name, tr, walk, f, ft, ia, paper, col) in enumerate(machines):
        y = 1 - row
        ends = interrupt_ends(walk(tr), tr, ft, ia)
        full = sorted(v for k, v in ends.items() if min(x.frame for x in tr.instructions) < k < max(
            x.frame for x in tr.instructions))
        print(f'{name}: interrupt ends at T {full[0]}-{full[-1]} from the INT over {len(full)} frames')
        # the beam: top border, paper, bottom border
        ax.add_patch(Rectangle((paper, y - 0.45), 192 * C.LINE_T, 0.9, facecolor='#ffffff', alpha=0.07, lw=0))
        ax.plot([ft, ft], [y - 0.48, y + 0.48], color='#ffffff', lw=1.2)
        for a, b, ph in runs_from_int(walk(tr), tr, f, ft, ia):
            ax.barh(y, b - a, left=a, height=0.38, color=COL.get(ph, '#666a75'), lw=0)
        ax.text(-1500, y, name, color=col, fontsize=10.5, ha='right', va='center')
        ax.text(paper + 96 * C.LINE_T, y + 0.3, f'the beam draws the paper: T {paper:,} - {paper + 192 * C.LINE_T:,}'
                .replace(',', ' '), color=DIM_, fontsize=8.5, ha='center')
        ax.annotate(f'interrupt done by T {full[-1]:,}'.replace(',', ' '), xy=(full[-1], y - 0.19),
                    xytext=(full[-1] + 1200, y - 0.42), color='#4caf50', fontsize=8.5,
                    arrowprops=dict(arrowstyle='->', color='#4caf50', lw=0.8))
        ax.text(ft, y + 0.3, f' frame end {ft:,} T'.replace(',', ' '), color=FG_, fontsize=8.5, ha='left')
    ax.set_xlim(-16000, 76000)
    ax.set_ylim(-0.6, 1.6)
    ax.set_yticks([])
    ax.set_xlabel('T-states from the interrupt (the INT): both rows on one scale', color=C.DIM, fontsize=9)
    ax.set_title('One frame on each machine: the Pentagon frame is 1 792 T longer and its paper starts 3 648 T later;'
                 '\nANE\'s interrupt adds the music, and still ends before the paper', color=C.FG, fontsize=12,
                 loc='left')
    ax.text(-16000, 1.5, f'frames: Nether Earth deep {args.ne_frame}, ANE d1 {args.ane_frame}', color=C.DIM,
            fontsize=8.5)
    ax.legend(handles=[Patch(color=c, label=l) for k, l, c in PH if k != 'other'], loc='upper center', ncol=4,
              fontsize=8, bbox_to_anchor=(0.5, -0.32), frameon=False, labelcolor='#d6d8e0')

    # bottom: both copies against both beams, from the INT of the frame the beam overtakes the copy in
    for name, tr, walk, f, ft, ia, paper, col in machines:
        w = copy_writes(walk(tr), tr, f, ft, ia)
        bx.plot([paper, paper + 191 * C.LINE_T], [0, 191], color=col, lw=1.6, ls='--')
        xs = [t for t, l, c in w]
        ys = [l for t, l, c in w]
        bx.scatter(xs, ys, s=2, color=col, linewidths=0)
        line, new, shown = tear(w, ft, paper, 0)
        t0 = min(w)
        print(f'{name}: copy {len(w)} bytes from T {t0[0]} (line {t0[1]}); tear line {line} ({new}/20 new); '
              f'{shown} bytes show in frame {f}')
        bx.axhline(line, color=col, lw=0.6, ls=':', alpha=0.8)
        cross_t = paper + line * C.LINE_T
        if col == C.NE_COL:
            bx.annotate(f'Nether Earth: the copy began in frame {f - 1}\n(T {t0[0]:,} before this INT); the beam\n'
                        f'overtakes it at screen line {line}: {shown} of 3 200\nbytes are new in frame {f}'
                        .replace(',', ' '), xy=(cross_t, line), xytext=(1000, 150), color=col, va='top',
                        fontsize=9.5, arrowprops=dict(arrowstyle='->', color=col, lw=0.9))
        else:
            bx.annotate(f'ANE: the copy began at T {t0[0]:,} of this frame,\n'
                        f'{paper + 8 * C.LINE_T - t0[0]:,} T before the view\'s first line; the beam\n'
                        f'overtakes it at screen line {line}: {shown} of 3 200 bytes\nare new in frame {f}'
                        .replace(',', ' '), xy=(cross_t, line), xytext=(cross_t + 13000, line - 26), color=col,
                        fontsize=9.5, arrowprops=dict(arrowstyle='->', color=col, lw=0.9))
    bx.text(NE_PAPER - 600, 3, 'the 48K beam', color=C.NE_COL, fontsize=9, ha='right', va='center')
    bx.text(ANE_PAPER + 900, 3, 'the Pentagon beam', color=C.ANE_COL, fontsize=9, ha='left', va='center')
    bx.axvline(0, color='#ffffff', lw=0.6, alpha=0.5)
    bx.text(300, -4, 'the INT', color=C.DIM, fontsize=8.5)
    bx.text(-15500, 62, 'dots: the bytes the copy writes\ninto the screen (20 a line);\na dot left of its '
            'machine\'s beam\nshows in this frame,\nright of it only in the next', color=C.DIM, fontsize=8.5,
            va='top')
    bx.set_xlim(-16000, 76000)
    bx.set_ylim(196, -10)
    bx.set_ylabel('screen line', color=C.DIM, fontsize=9)
    bx.set_xlabel('T-states from the INT of the frame the beam overtakes the copy in', color=C.DIM, fontsize=9)
    bx.set_title('The same copy loop (CopyViewToScreen $D071) against each beam: the tear is where they cross',
                 color=C.FG, fontsize=12, loc='left', pad=10)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print('wrote', args.out)


FG_, DIM_ = C.FG, C.DIM

if __name__ == '__main__':
    sys.exit(main())
