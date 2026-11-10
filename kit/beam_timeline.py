#!/usr/bin/env python3
"""Code vs the beam: when, in each frame, each routine runs and writes which screen line, against the raster.

One panel a frame of the trace. Across: the frame T, the T-state in the emulator's frame as the trace stores it (0 is
the frame start, not the interrupt; a green tick marks the INT). Down: the 192 paper lines. The diagonal is the
beam: the line the ULA is showing at that T-state. Every write into the screen is a dot at (when, which line) in its
routine's colour, a square outline for an attribute (at its character row). A dot left of the diagonal lands before
the beam reaches its line: it shows in this frame. A dot right of it lands after the beam passed: the line shows the
old byte until the next frame, the tearing a game avoids by drawing behind the beam or off screen. Above the panel a
strip shows which routine the CPU is in at each T-state.

    python3 beam_timeline.py (--trace pass.uatr | --work W --window F:T-F:T)
           --listing build/game.lst --out docs/img/beam-pass.png
           [--screen 4000] [--machine 48k|128k|pentagon] [--int-t T] [--int-to-paper T] [--paper-t T]
           [--line-t 224] [--frames 3] [--pc 8000-FFFF] [--title T] [--width 1050] [--unreal U]

The beam comes from unreal-ng's timing (core/src/emulator/config.cpp, ApplyModelTimingDefaults): the INT rises at
frame T intstart + 1 and the first paper pixel follows it by a fixed distance, so the paper starts at frame T
int-t + int-to-paper:

    machine    frame T   INT at frame T     INT to paper   paper at frame T   T a line
    48k        69888     1812               14340          16152              224
    128k       70908     1846               14366          16212              228
    pentagon   71680     -44 (71636 of      17988          17944              224
                         the frame before)

--machine picks the row (by default from the trace's frame length); --int-t and --int-to-paper override a column
(an emulator with another intstart), --paper-t gives the paper's frame T outright. The counts below the panel give
each routine's writes before and after the beam.

The picture is --width pixels wide (1050, the figure limit, readable shown at 900; the frame's time axis gets what the
labels leave of it), a long --title goes on several lines.
"""
import argparse
import os
import sys
from collections import Counter, defaultdict

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib as K  # noqa: E402
from routine_anim import wrap  # noqa: E402

LINES = 192
STRIP = 14
# machine: (frame T, the INT's frame T, INT to the first paper pixel, T a line), see the docstring
MACHINES = {'48k': (69888, 1812, 14340, 224), '128k': (70908, 1846, 14366, 228), 'pentagon': (71680, -44, 17988, 224)}


def beam_timing(args, frame_t):
    """(the INT's frame T, the first paper pixel's frame T, T a line) from --machine / --int-t / --int-to-paper /
    --paper-t / --line-t, the machine guessed from the trace's frame length when not given"""
    machine = args.machine or next((k for k, v in MACHINES.items() if v[0] == frame_t), '48k')
    _, int_t, to_paper, line_t = MACHINES[machine]
    int_t = int_t if args.int_t is None else args.int_t
    to_paper = to_paper if args.int_to_paper is None else args.int_to_paper
    paper_t = int_t + to_paper if args.paper_t is None else args.paper_t
    return int_t, paper_t, args.line_t or line_t


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--listing')
    p.add_argument('--out', required=True)
    p.add_argument('--screen', default='4000')
    p.add_argument('--machine', choices=sorted(MACHINES), help='the timing (default: from the trace\'s frame length)')
    p.add_argument('--int-t', type=int, help='the INT\'s frame T (default the machine\'s: 1812, 1846, -44)')
    p.add_argument('--int-to-paper', type=int, help='T from the INT to the first paper pixel (14340, 14366, 17988)')
    p.add_argument('--paper-t', type=int, help='the first paper pixel\'s frame T (default int-t + int-to-paper)')
    p.add_argument('--line-t', type=int, help='T a line (default the machine\'s: 224, 228)')
    p.add_argument('--frames', type=int, default=3, help='at most this many frames, the first of the trace')
    p.add_argument('--pc', help='only these instructions\' writes and time (hex range)')
    p.add_argument('--title')
    p.add_argument('--width', type=int, default=1050, help='the picture\'s width in pixels')
    args = p.parse_args()

    trace = K.load_trace(args)
    lst = K.listing(args.listing)
    base = K.hex_address(args.screen)
    pc_lo, pc_hi = K.hex_range(args.pc) if args.pc else (0, 0xFFFF)
    frame_t = trace.frame_t or 69888
    units = max(1, trace.units_per_t)
    int_t, paper_t, line_t = beam_timing(args, frame_t)
    print(f'frame {frame_t} T: the INT at frame T {int_t}, the paper at frame T {paper_t}, {line_t} T a line')

    frames = sorted({x.frame for x in trace.instructions})[:args.frames]
    keep = set(frames)
    spans = defaultdict(list)     # frame -> (t, routine) at each instruction start
    dots = defaultdict(list)      # frame -> (t, line, routine, is_attr)
    totals = Counter()
    order = Counter()
    ahead, behind = Counter(), Counter()
    for x in trace.instructions:
        if x.frame not in keep:
            continue
        mine = pc_lo <= x.pc <= pc_hi
        routine = lst.routine(x.pc) if mine else 'other'
        spans[x.frame].append((x.t // units, routine))
        totals[routine] += 1
        if not mine:
            continue
        for c in x.cycles:
            if c.tag not in 'WE':
                continue
            offset = (c.address - base) & 0xFFFF
            if offset >= 0x1B00:
                continue
            frame, t = trace.cycle_t(x, c)
            if frame not in keep:
                continue
            if offset < 0x1800:
                line, attr = K.screen_line(0x4000 + offset), False
            else:
                line, attr = ((offset - 0x1800) >> 5) * 8, True
            dots[frame].append((t, line, routine, attr))
            order[routine] += 1
            beam = paper_t + line * line_t
            (ahead if t < beam else behind)[routine] += 1

    names = [k for k, _ in order.most_common()] + [k for k, _ in totals.most_common() if k not in order]
    colour = {k: K.ROUTINE_COLOURS[i % len(K.ROUTINE_COLOURS)] for i, k in enumerate(n for n in names if n != 'other')}
    colour['other'] = (90, 90, 100)

    small, normal = K.font(11), K.font(12)
    left, gap = 44, 26
    plot = max(200, args.width - left - 20)  # the frame's T across
    title = wrap(args.title or f'Screen writes vs the beam, frames {frames[0]}..{frames[-1]} '
                 f'(frame T; INT {int_t} green; paper {paper_t})', K.font(15), plot)
    top = 16 + 18 * len(title)
    panel_h = STRIP + 6 + LINES * 2
    legend_h = 18 * (min(len(names), 12) + 1)
    height = top + len(frames) * (panel_h + gap) + legend_h + 10
    image = Image.new('RGB', (left + plot + 20, height), K.BACKGROUND)
    draw = ImageDraw.Draw(image)
    for i, line in enumerate(title):
        draw.text((left, 8 + 18 * i), line, fill=K.TEXT, font=K.font(15))

    def tx(t):
        return left + int(plot * t / frame_t)

    y = top
    for frame in frames:
        strip = spans[frame]
        for i, (t, routine) in enumerate(strip):
            t_end = strip[i + 1][0] if i + 1 < len(strip) else min(frame_t, t + 4)
            draw.rectangle([tx(t), y, max(tx(t), tx(t_end) - 1), y + STRIP], fill=colour.get(routine, (90, 90, 100)))
        py = y + STRIP + 6
        draw.rectangle([left, py, left + plot, py + LINES * 2], fill=K.PANEL)
        # the border time before the paper and after it
        draw.rectangle([left, py, tx(paper_t), py + LINES * 2], fill=(30, 26, 36))
        end = paper_t + LINES * line_t
        draw.rectangle([tx(end), py, left + plot, py + LINES * 2], fill=(30, 26, 36))
        draw.line([(tx(paper_t), py), (tx(end), py + LINES * 2)], fill=(255, 255, 255), width=1)
        int_x = tx(int_t % frame_t)  # a negative INT (Pentagon) rises in the frame before: its mark is at the end
        draw.line([(int_x, y - 3), (int_x, py + LINES * 2)], fill=(90, 220, 110), width=1)
        for t, line, routine, attr in dots[frame]:
            cx, cy = tx(t), py + line * 2
            if attr:
                draw.rectangle([cx - 2, cy, cx + 2, cy + 15], outline=colour[routine])
            else:
                draw.rectangle([cx, cy, cx + 1, cy + 1], fill=colour[routine])
        draw.text((4, y), f'{frame}', fill=K.DIM, font=small)
        for line in (0, 64, 128, 191):
            draw.text((4, py + line * 2 - 6), f'{line:3}', fill=K.DIM, font=small)
        y += panel_h + gap
    for t in range(0, frame_t, 10000):
        draw.text((tx(t), y - gap + 4), f'{t}', fill=K.DIM, font=small)
    draw.text((tx(frame_t) - 50, y - gap + 4), 'frame T', fill=K.DIM, font=small)

    for k in names[:12]:
        draw.rectangle([left, y + 2, left + 12, y + 14], fill=colour[k])
        note = (f'{order[k]} screen writes: {ahead[k]} before the beam, {behind[k]} after it; '
                if order[k] else '') + f'{totals[k]} instructions'
        draw.text((left + 18, y), f'{k}: {note}', fill=K.TEXT, font=normal)
        y += 18
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    image.save(args.out)
    print(f'{args.out}: {len(frames)} frames, {sum(order.values())} screen writes')
    for k in names[:12]:
        if order[k]:
            print(f'  {k}: {order[k]} writes, {ahead[k]} before the beam, {behind[k]} after')


if __name__ == '__main__':
    sys.exit(main())
