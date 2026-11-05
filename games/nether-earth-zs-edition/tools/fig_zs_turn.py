#!/usr/bin/env python3
"""Doc 04 figures of the '99 (copied from the nether-earth case's tools/fig_beam_turn.py and turn_profile.py, adapted
to the Pentagon 128 and this game's modules): one game turn against the interrupts and the beam, and the turn's
phases as a table.

    python3 tools/fig_zs_turn.py --trace work/docs/zsA/rc/traces/8000_0-8026_0.uatr \
        --listing build/game99/game.lst --copy-frame F --out docs/img/loop/beam-turn.png [--table]

The trace: zsa_common.trace('work/docs/zsA/rc', 8000, 0, 8026, 0) on recording r-critical (an instance of our own,
re_session.py open). --table prints the phases of the first whole turn (PlayLoop $A69A to the next entry).

Top: the turn's 11 frames on one time line, every instruction coloured by the phase it belongs to (the interrupt,
the world turn, drawing the view, copying it to the screen, waiting for the tenth interrupt). Bottom: the two frames
of the copy, time across, screen line down, with the beam as the diagonal and every screen write as a dot: a write
left of the beam shows in this frame, one right of it only in the next. Where the copy crosses the beam the screen
shows two views at once: the tear.

The trace is cached in work/docs/zsA/rc/traces (zsa_common.trace).
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
sys.path.insert(0, HERE)
import zsa_common as Z  # noqa: E402

# Pentagon 128 in unreal-ng: 71680 T a frame, the INT at frame T -44 (71636 of the frame before: drawn at 0), the
# first paper pixel at frame T 17944, 224 T a line (zsa_common.py)
FRAME_T, PAPER_T, LINE_T = Z.FRAME_T, Z.PAPER_T, Z.LINE_T
INT_T = 0
MODS = Z.Modules('game99')
PHASES = [  # name, colour
    ('interrupt (radar, clock count)', '#4caf50'),
    ('ship, robots, shots, clock', '#5c8fd6'),
    ('drawing the view (in the buffer)', '#c77ddb'),
    ('copying the view to the screen', '#e5534b'),
    ('waiting for the 10th interrupt', '#d9a441'),
    ('ROM, other', '#666a75'),
]
COLOUR = dict(PHASES)


def module_of(pc):
    return MODS.module(pc) if pc >= 0x6780 else None


def phase_of(pc, routine):
    if routine in ('TurnPace',):
        return PHASES[4][0]
    if routine in ('CopyViewToScreen', 'CopyLineLoop'):
        return PHASES[3][0]
    if pc < 0x4000:
        return PHASES[5][0]
    m = module_of(pc)
    if m == 'interrupts':
        return PHASES[0][0]
    if m in ('view',):
        return PHASES[2][0]
    if m in ('screen', 'print', 'tables'):
        return PHASES[2][0]
    return PHASES[1][0]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--trace', required=True)
    p.add_argument('--listing', required=True)
    p.add_argument('--copy-frame', type=int, required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--copy-only', action='store_true', help='only the panel of the copy\'s two frames')
    p.add_argument('--title', help='the copy panel\'s title')
    p.add_argument('--frames', help='F0-F1: only these frames of the trace (one turn)')
    p.add_argument('--unreal', default=Z.UNREAL)
    args = p.parse_args()
    trace = K.access_trace(args.unreal).load(args.trace)
    if args.frames:
        a, b = (int(v) for v in args.frames.split('-'))
        trace.instructions = [x for x in trace.instructions if a <= x.frame <= b]
    lst = K.listing(args.listing)
    units = max(1, trace.units_per_t)
    f0 = min(x.frame for x in trace.instructions)
    frames = sorted({x.frame for x in trace.instructions})

    # top: phases over time, merged into runs
    runs = []
    for x in trace.instructions:
        when = (x.frame - f0) + (x.t // units) / FRAME_T
        ph = phase_of(x.pc, lst.routine(x.pc))
        if runs and runs[-1][2] == ph:
            runs[-1][1] = when
        else:
            if runs:
                runs[-1][1] = when
            runs.append([when, when, ph])

    # bottom: screen writes in the copy's two frames
    cf = args.copy_frame
    dots = {'copy': [], 'radar': [], 'other': [], 'copy_at': []}
    for x in trace.instructions:
        if x.frame not in (cf, cf + 1, cf + 2):
            continue
        routine = lst.routine(x.pc)
        for c in x.cycles:
            if c.tag not in 'WE' or not (0x4000 <= c.address < 0x5800):
                continue
            frame, t = trace.cycle_t(x, c)
            if frame not in (cf, cf + 1):
                continue
            line = K.screen_line(c.address)
            kind = 'copy' if routine in ('CopyViewToScreen', 'CopyLineLoop') else \
                'radar' if module_of(x.pc) == 'interrupts' else 'other'
            dots[kind].append(((frame - cf) * FRAME_T + t, line))
            if kind == 'copy':
                dots['copy_at'].append(((frame - cf) * FRAME_T + t, line, c.address & 31))

    if args.copy_only:
        fig = plt.figure(figsize=(13, 6.2), dpi=110)
        ax, bx = None, fig.add_subplot(1, 1, 1)
    else:
        fig = plt.figure(figsize=(13, 8.2), dpi=110)
        gs = fig.add_gridspec(2, 1, height_ratios=[1, 3.2], hspace=0.62)
        ax, bx = fig.add_subplot(gs[0]), fig.add_subplot(gs[1])
    fig.patch.set_facecolor('#15161b')
    for a in (ax, bx) if ax else (bx,):
        a.set_facecolor('#1c1d24')
        a.tick_params(colors='#b8bcc8', labelsize=9)
        for s in a.spines.values():
            s.set_color('#444')

    if ax:
        draw_turn(ax, runs, frames, f0, cf)
    draw_copy(bx, dots, cf, args.title)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')


def draw_turn(ax, runs, frames, f0, cf):
    for a0, a1, ph in runs:
        ax.barh(0, max(a1 - a0, 1e-4), left=a0, height=0.8, color=COLOUR[ph], linewidth=0)
    n = len(frames)
    for i in range(n):
        ax.axvline(i + INT_T / FRAME_T, color='#ffffff', lw=0.6, alpha=0.5)
    ax.set_xlim(0, n)
    ax.set_ylim(-0.6, 1.3)
    ax.set_yticks([])
    ax.set_xticks([i + 0.5 for i in range(n)])
    ax.set_xticklabels([str(f) for f in frames])
    ax.set_xlabel('frame of r-critical (white lines: the 50 Hz interrupts, at the start of each frame on the Pentagon)', color='#b8bcc8', fontsize=9)
    ax.set_title('One game turn of the \'99 on the Pentagon 128 (r-critical): 10 frames, two thirds of them drawing the view', color='#e8e8ee', fontsize=12, loc='left')
    ax.annotate('', xy=(cf - f0, 1.05), xytext=(cf - f0 + 2, 1.05),
                arrowprops=dict(arrowstyle='<->', color='#e8e8ee', lw=0.8))
    ax.text(cf - f0 + 1, 1.12, 'enlarged below', color='#e8e8ee', fontsize=9, ha='center', va='bottom')
    ax.legend(handles=[Patch(color=c, label=l) for l, c in PHASES], loc='upper center', ncol=3, fontsize=8.5,
              bbox_to_anchor=(0.5, -0.48), frameon=False, labelcolor='#d6d8e0')



def draw_copy(bx, dots, cf, title):
    total = 2 * FRAME_T
    for k in range(2):
        b0 = k * FRAME_T + PAPER_T
        bx.plot([b0, b0 + 191 * LINE_T], [0, 191], color='#ffffff', lw=1.2)
        bx.axvline(k * FRAME_T, color='#ffffff', lw=0.6, alpha=0.5)
        bx.text(k * FRAME_T + 600, -4, f'interrupt, frame {cf + k}', color='#b8bcc8', fontsize=8.5)
    bx.text(PAPER_T + 120 * LINE_T + 1200, 118, 'the beam: the screen line\nthe TV shows at this moment',
            color='#ffffff', fontsize=9)
    for kind, colour, size in (('other', '#5c8fd6', 3), ('radar', '#4caf50', 3), ('copy', '#e5534b', 2)):
        if dots[kind]:
            xs, ys = zip(*dots[kind])
            bx.scatter(xs, ys, s=size, color=colour, linewidths=0)

    # a byte at (line L, column c) shows in a frame when written before the beam fetches it there:
    # frame T 17944 + 224 L + 4 c of that frame
    def seen_in(t, line, col):
        k = t // FRAME_T
        return k if t <= k * FRAME_T + PAPER_T + line * LINE_T + 4 * col else k + 1
    shown = {}
    for t, line, col in dots['copy_at']:
        shown.setdefault(seen_in(t, line, col), []).append(line)
    lines = {}
    for t, line, col in dots['copy_at']:
        lines.setdefault(line, set()).add(seen_in(t, line, col))
    torn = [l for l in sorted(lines) if len(lines[l]) > 1]
    first_frame = {}
    for t, line, col in dots['copy_at']:
        first_frame[line] = max(first_frame.get(line, 0), seen_in(t, line, col))
    split = sorted({first_frame[l] for l in first_frame})
    copy = sorted(dots['copy'])
    summary = {cf + k: len(v) for k, v in sorted(shown.items())}
    print(f'copy: {len(copy)} bytes; frame that first shows each byte: {summary}; lines with bytes of two frames: {torn}')
    if copy:
        t0, l0 = copy[0]
        t1, l1 = copy[-1]
        beam0 = (t0 % FRAME_T - PAPER_T) // LINE_T
        bx.annotate(f'the view copy starts: screen line {l0},\nframe T {t0 % FRAME_T}; the beam is at line {beam0}',
                    xy=(t0, l0), xytext=(t0 - 34000, 46), color='#e5534b', fontsize=9,
                    arrowprops=dict(arrowstyle='->', color='#e5534b', lw=0.8))
        bx.annotate(f'it ends at line {l1}, frame T {t1 % FRAME_T}\nof frame {cf + t1 // FRAME_T}: '
                    f'{len(copy)} bytes in {t1 - t0} T with the interrupt\n(386 T a line against the beam\'s 224)',
                    xy=(t1, l1), xytext=(t1 + 9000, 62), color='#e5534b', fontsize=9,
                    arrowprops=dict(arrowstyle='->', color='#e5534b', lw=0.8))
    if not torn and len(shown) == 1:
        k = list(shown)[0]
        verdict = (f'no tear: every byte of the copy is written after the beam\npassed it in frame {cf}, '
                   f'and before the beam reaches it\nin frame {cf + 1}: frame {cf} shows the old view whole,\n'
                   f'frame {cf + 1} the new one whole')
    else:
        verdict = f'bytes first shown per frame: {summary}; torn lines {torn[:3]}...'
    bx.text(2 * FRAME_T - 1500, 196 - 4, verdict, ha='right', va='bottom', color='#e8e8ee', fontsize=9.5,
            bbox=dict(facecolor='#1c1d24', edgecolor='#666', alpha=0.9, pad=4))
    if dots['radar']:
        r = sorted(dots['radar'])
        bx.annotate('the radar, lines 176-191: drawn by every\ninterrupt, ahead of the beam',
                    xy=r[len(r) // 4], xytext=(r[0][0] + 9000, 150), color='#4caf50', fontsize=9,
                    arrowprops=dict(arrowstyle='->', color='#4caf50', lw=0.8))
    if dots['other']:
        o = sorted(dots['other'])
        bx.annotate('the clock (PrintChar, lines 0-15)', xy=o[0], xytext=(o[0][0] - 30000, 30), color='#5c8fd6',
                    fontsize=9, arrowprops=dict(arrowstyle='->', color='#5c8fd6', lw=0.8))
    bx.set_xlim(0, total)
    bx.set_ylim(196, -10)
    bx.set_ylabel('screen line', color='#b8bcc8', fontsize=9)
    bx.set_xlabel(f'frame T from the start of frame {cf} (71680 a frame on the Pentagon 128; the interrupt at its start)',
                  color='#b8bcc8', fontsize=9)
    bx.set_title(title or f'Frames {cf}-{cf + 1}: the view copy starts behind the beam and ends ahead of the next one: no tear', color='#e8e8ee',
                 fontsize=12, loc='left', pad=16)


if __name__ == '__main__':
    sys.exit(main())
