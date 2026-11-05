#!/usr/bin/env python3
"""Doc 04 figure: one game turn against the interrupts and the beam (docs/img/beam-turn.png).

    python3 tools/fig_beam_turn.py --trace work/docA/deep/traces/20004_0-20015_0.uatr \
        --listing work/mkgame/game.lst --copy-frame 20011 --out docs/img/beam-turn.png

Top: the turn's 11 frames on one time line, every instruction coloured by the phase it belongs to (the interrupt,
the world turn, drawing the view, copying it to the screen, waiting for the tenth interrupt). Bottom: the two frames
of the copy, time across, screen line down, with the beam as the diagonal and every screen write as a dot: a write
left of the beam shows in this frame, one right of it only in the next. Where the copy crosses the beam the screen
shows two views at once: the tear.

The trace comes from kit/beam_timeline.py's cache (`--work work/docA/deep --window 20004:0-20015:0`).
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

# 48K in unreal-ng (config.cpp ApplyModelTimingDefaults): the trace's T is the frame T (0 = the emulator's frame
# start); the INT rises at frame T 1812 (intstart 1811 + 1), the first paper pixel 14340 T later, at frame T 16152
FRAME_T, INT_T, PAPER_T, LINE_T = 69888, 1812, 16152, 224
# module ranges of src/game/game.ann
MODULES = [(0xA600, 'start'), (0xA720, 'robotmenu'), (0xAD62, 'gameturn'), (0xAF11, 'ship'), (0xB0CA, 'world'),
           (0xB7F4, 'enemy'), (0xBB09, 'bases'), (0xBDA9, 'level'), (0xC100, 'mainmenu'), (0xC4A7, 'music'),
           (0xC849, 'construction'), (0xCCBD, 'view'), (0xD0B9, 'screen'), (0xD37C, 'controls'), (0xD3E5, 'print'),
           (0xD566, 'interrupts'), (0xD6A8, 'tables')]
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
    name = None
    for start, m in MODULES:
        if pc >= start:
            name = m
    return name


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
    p.add_argument('--unreal')
    args = p.parse_args()
    trace = K.access_trace(args.unreal).load(args.trace)
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
    ax.set_xlabel('frame of work/deep (white lines: the 50 Hz interrupts, at frame T 1812)', color='#b8bcc8', fontsize=9)
    ax.set_title('One game turn: what the CPU does in each of its frames', color='#e8e8ee', fontsize=12, loc='left')
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
        bx.axvline(k * FRAME_T + INT_T, color='#ffffff', lw=0.6, alpha=0.5)
        bx.text(k * FRAME_T + INT_T + 600, -4, f'interrupt, frame {cf + k}', color='#b8bcc8', fontsize=8.5)
    bx.text(PAPER_T + 105 * LINE_T + 1500, 100, 'the beam: the screen line\nthe TV shows at this moment',
            color='#ffffff', fontsize=9, rotation=0)
    for kind, colour, size in (('other', '#5c8fd6', 2), ('radar', '#4caf50', 3), ('copy', '#e5534b', 2)):
        if dots[kind]:
            xs, ys = zip(*dots[kind])
            bx.scatter(xs, ys, s=size, color=colour, linewidths=0)
    # what frame cf+1 shows: a byte is new there when it was written before the beam fetched it in that frame
    # (line L, column c: frame T 16152 + 224 L + 4 c); the tear is the first line the beam reaches before the copy does
    def shown_new(t, line, col):
        return t <= FRAME_T + PAPER_T + line * LINE_T + 4 * col
    lines = {}
    for t, line, col in dots['copy_at']:
        lines.setdefault(line, []).append(shown_new(t, line, col))
    cross = None
    for line in sorted(lines):
        if not all(lines[line]):
            cross = (next(t for t, l, c in sorted(dots['copy_at']) if l == line and not shown_new(t, l, c)), line)
            break
    ahead = sum(1 for t, line, col in dots['copy_at'] if shown_new(t, line, col))
    copy = sorted(dots['copy'])
    if copy:
        t0 = copy[0][0]
        bx.annotate('the view copy starts\n(line 8, 20 bytes a line)', xy=(t0, copy[0][1]), xytext=(t0 - 22000, 40),
                    color='#e5534b', fontsize=9, arrowprops=dict(arrowstyle='->', color='#e5534b', lw=0.8))
    print(f'copy: {len(copy)} bytes, {ahead} shown new in frame {cf + 1}, tear {cross}')
    if cross:
        torn = sum(lines[cross[1]])
        bx.axhline(cross[1], color='#e5534b', lw=0.6, ls='--', alpha=0.7)
        bx.annotate(f'the tear: screen line {cross[1]} (view line {cross[1] - 8}),\n'
                    f'{torn} of its 20 bytes new; frame {cf + 1}\n'
                    f'shows the new view above it, the old below\n'
                    f'({ahead} of {len(copy)} bytes show in {cf + 1},\n'
                    f'the rest only in {cf + 2})',
                    xy=cross, xytext=(2 * FRAME_T - 1500, cross[1] - 55), ha='right', va='top', color='#e8e8ee',
                    fontsize=9.5, bbox=dict(facecolor='#1c1d24', edgecolor='none', alpha=0.85, pad=2),
                    arrowprops=dict(arrowstyle='->', color='#e8e8ee', lw=0.8))
    if dots['radar']:
        r = sorted(dots['radar'])
        bx.annotate('the radar, lines 176-191: drawn by every\ninterrupt, long before the beam gets there',
                    xy=r[len(r) // 2], xytext=(r[0][0] + 6000, 150), color='#4caf50', fontsize=9,
                    arrowprops=dict(arrowstyle='->', color='#4caf50', lw=0.8))
    if dots['other']:
        o = sorted(dots['other'])
        bx.annotate('the clock (PrintChar)', xy=o[0], xytext=(o[0][0] - 16000, 30), color='#5c8fd6', fontsize=9,
                    arrowprops=dict(arrowstyle='->', color='#5c8fd6', lw=0.8))
    bx.text(21000, 4, 'a dot left of the beam shows in this frame,\nright of it only in the next one',
            color='#b8bcc8', fontsize=8.5, ha='left', va='top')
    bx.set_xlim(0, total)
    bx.set_ylim(196, -10)
    bx.set_ylabel('screen line', color='#b8bcc8', fontsize=9)
    bx.set_xlabel(f'frame T from the start of frame {cf} (69888 a frame; the interrupts at frame T 1812)', color='#b8bcc8', fontsize=9)
    bx.set_title(title or f'Frames {cf}-{cf + 1}: every write into the screen against the beam', color='#e8e8ee',
                 fontsize=12, loc='left', pad=16)


if __name__ == '__main__':
    sys.exit(main())
