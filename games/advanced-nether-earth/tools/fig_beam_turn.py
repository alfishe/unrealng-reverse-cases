#!/usr/bin/env python3
"""Doc 04 figures: one game turn frame by frame, and the tear it leaves on the TV.

    python3 tools/fig_beam_turn.py --trace work/docR/d1/traces/12446_0-12458_0.uatr --copy-frame 12454 \
        --turn-out docs/img/loop/turn-frames.png --tear-out docs/img/loop/tear-tv.png

turn-frames.png: one row per frame of the turn, time across the frame (0-71 680 T), every instruction coloured by
its phase (tools/ane_trace.py). The paper's beam time is marked, so it shows at a glance which work runs while the
TV draws the picture.

--turn-trace draws turn-frames.png from another trace (when --trace is not one whole turn).

tear-tv.png: top, the play view of the three TV pictures around the copy, rebuilt from the trace: every screen byte
takes the value it had when the beam fetched it (line L, column c at T 17 988 + 224 L + 4 c of its frame). Bottom, the copy against
the beam in the copy's first frame: above the crossing line the copy is ahead and the TV shows the new view, below
it the beam came first and the TV still shows the old one.
"""
import argparse
import bisect
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402
from PIL import Image  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ane_trace as A  # noqa: E402
import kitlib as K  # noqa: E402

FRAME_T, PAPER_T, LINE_T = A.FRAME_T, A.PAPER_T, A.LINE_T
BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'
VIEW_TOP, VIEW_LINES = 8, 160      # the play view on the screen: lines 8-167, columns 1-20 (20 bytes a line)


def style(fig, axes):
    fig.patch.set_facecolor(BG)
    for a in axes:
        a.set_facecolor(AX)
        a.tick_params(colors=DIM, labelsize=9)
        for s in a.spines.values():
            s.set_color('#444')


def fetch_t(frame, line, col):
    return frame * FRAME_T + PAPER_T + line * LINE_T + 4 * col


def tv_picture(trace, writes, frame):
    """The screen as the beam showed it in `frame`: per byte the last write before its fetch"""
    out = bytearray(trace.memory)
    for addr, (ts, vs) in writes.items():
        if addr < 0x5800:
            line, col = K.screen_line(addr), addr & 31
        else:
            line, col = ((addr - 0x5800) >> 5) * 8, addr & 31
        i = bisect.bisect_right(ts, fetch_t(frame, line, col)) - 1
        if i >= 0:
            out[addr] = vs[i]
    return K.render_screen(out)


def screen_writes(trace):
    """address -> ([absolute T], [value]) of every screen write in the trace"""
    writes = {}
    for x in trace.instructions:
        for c in x.cycles:
            if c.tag in 'WE' and 0x4000 <= c.address < 0x5B00:
                f, t = trace.cycle_t(x, c)
                ts, vs = writes.setdefault(c.address, ([], []))
                ts.append(f * FRAME_T + t)
                vs.append(c.value)
    return writes


def view_changed(trace, writes, w, cf):
    """how many of the copy's screen bytes differ after the copy from before it"""
    t0 = cf * FRAME_T + min(t for t, l, c in w)
    t1 = cf * FRAME_T + max(t for t, l, c in w) + 1
    n = 0
    for addr in {K.screen_address(l, c) for t, l, c in w}:
        ts, vs = writes[addr]
        i0, i1 = bisect.bisect_left(ts, t0) - 1, bisect.bisect_right(ts, t1) - 1
        n += (vs[i0] if i0 >= 0 else trace.memory[addr]) != vs[i1]
    return n


def turn_frames(trace, out, title):
    """turn-frames.png: the phase runs of every whole frame of the trace"""
    rows = {}
    for x, bank, ph in A.walk(trace):
        row = rows.setdefault(x.frame, [])
        if row and row[-1][2] == ph:
            row[-1][1] = x.t
        else:
            if row:
                row[-1][1] = x.t
            row.append([x.t, x.t, ph])
    frames = sorted(rows)[1:-1]          # whole frames only
    fig, ax = plt.subplots(figsize=(13, 0.42 * len(frames) + 1.8), dpi=110)
    style(fig, (ax,))
    for i, f in enumerate(frames):
        rows[f][-1][1] = FRAME_T
        for t0, t1, ph in rows[f]:
            ax.barh(i, max(t1 - t0, 30), left=t0, height=0.72, color=A.COLOUR[ph], linewidth=0)
    ax.axvspan(PAPER_T, PAPER_T + 192 * LINE_T, color='#ffffff', alpha=0.06, lw=0)
    ax.text(PAPER_T + 96 * LINE_T, -0.9, 'the beam draws the picture (screen lines 0-191)', color=DIM, fontsize=9,
            ha='center')
    ax.set_yticks(range(len(frames)))
    ax.set_yticklabels([f'frame {f}' for f in frames], fontsize=8.5)
    ax.set_ylim(len(frames) - 0.5, -1.4)
    ax.set_xlim(0, FRAME_T)
    ax.set_xlabel('T-states from the frame\'s interrupt (71 680 a frame on the Pentagon)', color=DIM, fontsize=9)
    ax.set_title(title or f'One game turn, frames {frames[0]}-{frames[-1]}', color=FG, fontsize=11.5, loc='left')
    used = {ph for f in frames for _, _, ph in rows[f]}
    ax.legend(handles=[Patch(color=c, label=l) for k, l, c in A.PHASES if k in used], loc='upper center',
              bbox_to_anchor=(0.5, -0.09), ncol=3, fontsize=8.5, frameon=False,
              labelcolor='#d6d8e0')
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    plt.close(fig)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--trace', required=True)
    p.add_argument('--copy-frame', type=int, required=True)
    p.add_argument('--turn-out', required=True)
    p.add_argument('--tear-out', required=True)
    p.add_argument('--turn-trace', help='draw turn-frames.png from this trace instead (a whole turn)')
    p.add_argument('--turn-title', help='the title of turn-frames.png (default: its frames)')
    args = p.parse_args()
    trace = A.load(args.trace)
    cf = args.copy_frame
    turn_frames(A.load(args.turn_trace) if args.turn_trace else trace, args.turn_out, args.turn_title)

    writes = screen_writes(trace)

    # ---- tear-tv.png
    w = A.copy_writes(trace, cf)
    tf, tline, new = A.tear(w, cf)
    pics = [tv_picture(trace, writes, f) for f in (tf - 1, tf, tf + 1)]
    changed = view_changed(trace, writes, w, cf)
    x0, x1, y0, y1 = 4, 172, 4, 172   # the view (columns 1-20, lines 8-167) and its frame
    fig = plt.figure(figsize=(13, 10.6), dpi=110)
    gs = fig.add_gridspec(2, 3, height_ratios=[1.25, 1], hspace=0.22, wspace=0.08)
    tv = [fig.add_subplot(gs[0, i]) for i in range(3)]
    bx = fig.add_subplot(gs[1, :])
    style(fig, tv + [bx])
    titles = [f'frame {tf - 1}: the old view', f'frame {tf}: torn at line {tline}', f'frame {tf + 1}: the new view']
    for a, pic, title in zip(tv, pics, titles):
        crop = pic.crop((x0, y0, x1, y1))
        a.imshow(crop.resize((crop.width * 3, crop.height * 3), Image.NEAREST), extent=(x0, x1, y1, y0))
        a.set_xticks([])
        a.set_yticks([VIEW_TOP, 64, 128, VIEW_TOP + VIEW_LINES - 1] if a is tv[0] else [])
        a.set_title(title, color=FG, fontsize=11)
    tv[0].set_ylabel('screen line', color=DIM, fontsize=9)
    tv[1].axhline(tline, color='#ff4040', lw=1.6)
    tv[1].set_xlabel(f'red line: line {tline}\nthe new view above it, the old view below', color='#ff8080',
                     fontsize=9.5)
    tv[0].set_xlabel('the TV picture\nbefore the copy', color=DIM, fontsize=9.5)
    tv[2].set_xlabel(f'the TV picture after the copy\n{changed} view bytes changed', color=DIM, fontsize=9.5)

    # the copy against the beam, frame tf (time from its interrupt)
    k = tf - cf
    pts = sorted((t - k * FRAME_T, line) for t, line, col in w)
    end = PAPER_T + 191 * LINE_T
    right = max(t for t, l in pts) + 4000
    bx.fill_between([0, right], 0, tline, color='#4caf50', alpha=0.10, lw=0)
    bx.fill_between([0, right], tline, 192, color='#e5534b', alpha=0.08, lw=0)
    bx.plot([PAPER_T, end], [0, 191], color='#ffffff', lw=2, label='the beam: the line the TV draws')
    bx.scatter([t for t, l in pts], [l for t, l in pts], s=3, color='#e5534b', linewidths=0,
               label='the copy: each byte written to the screen')
    bx.axhline(tline, color='#ff4040', lw=1, ls='--')
    bx.axvline(FRAME_T, color='#ffffff', lw=0.6, alpha=0.5)
    bx.text(FRAME_T + 500, 4, f'interrupt of\nframe {tf + 1}', color=DIM, fontsize=8.5, va='top')
    cross = PAPER_T + tline * LINE_T
    bx.text(cross + 6000, (VIEW_TOP + tline) / 2, f'lines 8-{tline - 1}: the copy writes them before the beam\n'
            f'gets there, so frame {tf} shows them new', color='#7fd68a', fontsize=9.5, va='center')
    bx.text(1500, 120, f'lines {tline}-167: the beam passes before\nthe copy writes them: frame {tf} still\n'
            f'shows them old, frame {tf + 1} new', color='#f08a84', fontsize=9.5, va='center')
    bx.set_xlim(0, right)
    bx.set_ylim(192, 0)
    bx.set_ylabel('screen line', color=DIM, fontsize=9)
    bx.set_xlabel(f'T-states from the interrupt of frame {tf}', color=DIM, fontsize=9)
    first = min(t for t, l in pts)
    bx.set_title(f'Why: the copy writes line 8 at T {first:,}'.replace(',', ' ') +
                 f', before the beam; the beam is faster and overtakes it at line {tline}', color=FG,
                 fontsize=11.5, loc='left')
    bx.legend(loc='lower left', fontsize=9, frameon=False, labelcolor='#d6d8e0', markerscale=4)
    fig.savefig(args.tear_out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(f'tear frame {tf} line {tline}, {new} of 20 new; copy {len(w)} bytes, {changed} view bytes changed')


if __name__ == '__main__':
    sys.exit(main())
