#!/usr/bin/env python3
"""Shared pieces of the shell-and-machine figures of the Nether Earth difference report (work/diff/shell.md):
the paths of both cases, the dark theme of the case figures, and the readers of both games' access traces.

Not a figure itself: imported by tools/fig_diff_shell_*.py.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ANE = os.path.abspath(os.path.join(HERE, '..'))
NE = os.path.abspath(os.path.join(ANE, '..', 'nether-earth'))
OUT = os.path.join(ANE, 'docs', 'img', 'diff')
sys.path.insert(0, os.path.join(ANE, '..', '..', 'kit'))
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402

# The theme of the case figures (tools/fig_banks.py, nether-earth/tools/fig_beam_turn.py)
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
KIND = {'screen': '#5c8fd6', 'code': '#4caf50', 'data': '#d9a441', 'graphics': '#8e7cc3', 'work': '#5a6380',
        'free': '#2b2d38', 'packed': '#e8833a', 'system': '#7a7d8c', 'music': '#e07ad0', 'sequence': '#d9534f',
        'stack': '#3d4256'}
# what a difference is: the same in both, changed, added by ANE, gone in ANE
SAME, CHANGED, ADDED, GONE = '#7a7d8c', '#d9a441', '#4caf50', '#e5534b'
NE_COL, ANE_COL = '#5c8fd6', '#e8833a'

# The machines
NE_FRAME_T, NE_PAPER_T = 69888, 14340      # 48K: 312 lines of 224 T, the paper 14340 T after the INT
ANE_FRAME_T, ANE_PAPER_T = 71680, 17988    # Pentagon: 320 lines of 224 T, the paper 17988 T after the INT
LINE_T = 224


import matplotlib  # noqa: E402
matplotlib.rcParams['text.parse_math'] = False   # the hex addresses' $ is text, not mathtext


def style(fig, axes):
    fig.patch.set_facecolor(BG)
    for a in axes:
        a.set_facecolor(PANEL)
        a.tick_params(colors=DIM, labelsize=9)
        for s in a.spines.values():
            s.set_color('#444')


def out_path(name):
    os.makedirs(OUT, exist_ok=True)
    return os.path.join(OUT, name)


# ---------------------------------------------------------------------------------------------------------------
# the traces

def ne_walk(trace):
    """(instruction, phase) of a Nether Earth access trace. An interrupt is followed from the IM 2 jump at $FDFD
    until SP rises above the interrupted frame (as ane_trace.walk does from $6969)"""
    int_sp = None
    for x in trace.instructions:
        if x.pc == 0xFDFD and int_sp is None:
            int_sp = x.sp
        elif int_sp is not None and x.sp >= (int_sp + 2) & 0xFFFF and x.pc != 0xFDFD:
            int_sp = None
        if int_sp is not None:
            ph = 'radar' if 0xD59E <= x.pc <= 0xD5C3 else 'sound' if 0xD5C4 <= x.pc <= 0xD5F7 else 'int'
        elif 0xAE1D <= x.pc <= 0xAE27:
            ph = 'wait'
        elif 0xD071 <= x.pc <= 0xD0B8:
            ph = 'copy'
        elif 0xCCBD <= x.pc <= 0xD070:
            ph = 'draw'
        elif x.pc >= 0x4000:
            ph = 'world'
        else:
            ph = 'other'
        yield x, ph


def ane_walk(trace):
    """(instruction, phase) of an ANE access trace: ane_trace.walk, the interrupt split into the radar and the rest"""
    import ane_trace
    for x, bank, ph in ane_trace.walk(trace):
        if ph == 'int' and 0xD59E <= x.pc <= 0xD5C3:
            ph = 'radar'
        elif ph == 'int' and 0xD5C4 <= x.pc <= 0xD5F7:
            ph = 'sound'
        yield x, ph


def runs_in_frame(walk, trace, frame, frame_t):
    """[(t0, t1, phase)] of one frame, from the gaps between instruction starts"""
    units = max(1, trace.units_per_t)
    out, prev = [], None
    for x, ph in walk:
        t = (x.frame - frame) * frame_t + x.t // units
        if prev is not None:
            pt, pph = prev
            if pt < frame_t and t > 0:
                a, b = max(pt, 0), min(t, frame_t)
                if out and out[-1][2] == pph and out[-1][1] == a:
                    out[-1] = (out[-1][0], b, pph)
                else:
                    out.append((a, b, pph))
        prev = (t, ph)
    return out


def screen_writes(walk, trace, frame, frame_t, kinds=('copy',)):
    """[(t from the interrupt of frame, screen line, column, phase)] of the screen writes of the given phases in
    frames frame - 1 .. frame + 1"""
    out = []
    for x, ph in walk:
        if ph not in kinds:
            continue
        for c in x.cycles:
            if c.tag in 'WE' and 0x4000 <= c.address < 0x5800:
                f, t = trace.cycle_t(x, c)
                if frame - 1 <= f <= frame + 1:
                    out.append(((f - frame) * frame_t + t, K.screen_line(c.address), c.address & 31, ph))
    return out
