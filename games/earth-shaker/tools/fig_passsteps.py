#!/usr/bin/env python3
"""The steps of PlayCave's pass, one bar a traced pass: where the T-states of a pass go, step by step, with the
frames and the interrupts the CPU took (doc 4).

Each pass is an access trace (unreal-ng `analysis trace`, as kit/routine_anim.py keeps them in WORK/traces/) from one
PassLoop `$888D` to the next. A step starts at the first execution of its call site in PassLoop (or of the routine's
entry, for the cell update reached inside AbortKey's chain) after the step before it; it ends where the next starts.
The frame starts are the thin lines, an accepted interrupt (the instruction at `$0038` flagged interrupted) a tick
under the bar, a frame start with no interrupt in it a red cross (the INT fell while interrupts were off).

    python3 tools/fig_passsteps.py --out docs/img/loop/pass-steps.png \
        "LABEL=work/docs/esA/c1/traces/13143_35781-13149_10971.uatr" ...
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

FRAME_T = 69888
# (boundary PC, step name, colour): the call sites of PlayCave's PassLoop, in order; $8075 is ScanCells, called from
# AntiGravPass inside AbortKey's patch chain (AbortKey -> AnimateCellCodes -> SwitchClear -> AntiGravPass -> ScanCells);
# $9381 is AnimateCellCodes' own loop, after the chain returns
STEPS = [
    (0x888D, 'start', (90, 90, 90)),
    (0x8892, 'KeysStep (player)', (230, 120, 200)),
    (0x8895, 'PutPlayer', (160, 160, 160)),
    (0x8898, 'AbortKey chain', (160, 160, 160)),
    (0x8075, 'ScanCells (cell update)', (90, 140, 250)),
    (0x9381, 'AnimateCellCodes', (240, 150, 60)),
    (0x889B, 'ClearVacated', (180, 110, 230)),
    (0x889E, 'WindowOrigin', (120, 120, 120)),
    (0x88A1, 'DrawWindow (from MapKey)', (235, 90, 80)),
    (0x88A4, 'ColourCycle', (200, 200, 90)),
    (0x88A7, 'FizzSound + PassSound', (250, 210, 60)),
    (0x88AA, 'TimerStep', (90, 210, 120)),
    (0x88AD, 'QuitKey', (110, 200, 220)),
    (0x88B0, 'end tests', (90, 90, 90)),
]


def segments(trace):
    units = max(1, trace.units_per_t)
    ins = trace.instructions
    t0 = ins[0].frame * FRAME_T + ins[0].t // units
    marks, k = [], 0
    ints, frames_seen = [], set()
    for x in ins:
        t = x.frame * FRAME_T + x.t // units - t0
        frames_seen.add(x.frame)
        if x.interrupted:
            ints.append((t, x.frame))
        if k < len(STEPS) and x.pc == STEPS[k][0]:
            marks.append(t)
            k += 1
    end = ins[-1].frame * FRAME_T + ins[-1].t // units - t0
    marks.append(end)
    segs = [(STEPS[i][1], STEPS[i][2], marks[i], marks[i + 1]) for i in range(len(marks) - 1)]
    first_frame = ins[0].frame
    frame_lines = [(f * FRAME_T - t0, f) for f in sorted(frames_seen) if f * FRAME_T - t0 > 0]
    int_frames = {f for _, f in ints}
    lost = [(t, f) for t, f in frame_lines if f not in int_frames]
    return segs, end, ints, frame_lines, lost, first_frame


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--title', default='Where a pass goes: the steps of PassLoop on a traced pass')
    ap.add_argument('--width', type=int, default=1050)
    ap.add_argument('--note', action='append', default=[])
    ap.add_argument('passes', nargs='+', help='LABEL=TRACE.uatr')
    a = ap.parse_args()
    at = K.access_trace(None)
    rows = []
    for p in a.passes:
        label, _, path = p.partition('=')
        rows.append((label, segments(at.load(path))))
    longest = max(r[1][1] for r in rows)
    f, fs, fb = K.font(13), K.font(11), K.font(15)
    left, right, top, bar_h, gap = 20, 20, 50, 34, 92
    plot_w = a.width - left - right
    scale = plot_w / (longest * 1.02)
    legend_rows = (len(STEPS) - 1 + 3) // 4
    h = top + len(rows) * gap + 30 + legend_rows * 22 + 20 + 18 * len(a.note) + 10
    img = Image.new('RGB', (a.width, h), (22, 22, 28))
    d = ImageDraw.Draw(img)
    d.text((left, 14), a.title, fill=(235, 235, 235), font=fb)
    for i, (label, (segs, end, ints, frame_lines, lost, first)) in enumerate(rows):
        y = top + i * gap
        d.text((left, y), '%s: %d T = %.2f frames, %d interrupts taken, %d lost' % (
            label, end, end / FRAME_T, len(ints), len(lost)), fill=(225, 225, 225), font=f)
        yb = y + 20
        for name, col, s, e in segs:
            x0, x1 = left + s * scale, left + e * scale
            d.rectangle([x0, yb, max(x0 + 1, x1), yb + bar_h], fill=col)
            short = name.split(' ')[0]
            if x1 - x0 > d.textlength(short, font=fs) + 6:
                d.text((x0 + 3, yb + 10), short, fill=(15, 15, 15), font=fs)
        for t, fr in frame_lines:
            x = left + t * scale
            d.line([x, yb - 3, x, yb + bar_h + 3], fill=(250, 250, 250), width=1)
            d.text((x + 2, yb + bar_h + 16), str(fr), fill=(150, 150, 150), font=fs)
        for t, _ in ints:
            x = left + t * scale
            d.line([x, yb + bar_h + 2, x, yb + bar_h + 12], fill=(120, 255, 120), width=2)
        for t, _ in lost:
            x = left + t * scale
            d.line([x - 4, yb + bar_h + 3, x + 4, yb + bar_h + 11], fill=(255, 70, 70), width=2)
            d.line([x - 4, yb + bar_h + 11, x + 4, yb + bar_h + 3], fill=(255, 70, 70), width=2)
    y = top + len(rows) * gap + 6
    d.text((left, y), 'white line: a frame starts (its number under it); green tick: an interrupt taken; red cross: '
           'a frame whose INT was lost', fill=(200, 200, 200), font=fs)
    y += 22
    colw = plot_w // 4
    for j, (_, name, col) in enumerate(STEPS[1:-1] + [STEPS[0]]):
        x, yy = left + (j % 4) * colw, y + (j // 4) * 22
        d.rectangle([x, yy + 2, x + 14, yy + 14], fill=col)
        d.text((x + 20, yy), name if name != 'start' else 'start / end tests', fill=(220, 220, 220), font=fs)
    y += legend_rows * 22 + 8
    for n in a.note:
        d.text((left, y), n, fill=(190, 190, 190), font=fs)
        y += 18
    img.save(a.out)
    for label, (segs, end, ints, frame_lines, lost, first) in rows:
        print(label, 'T', end, 'frames %.2f' % (end / FRAME_T), 'ints', len(ints), 'lost', len(lost))
        for name, _, s, e in segs:
            print('   %-26s %7d  %5.1f %%' % (name, e - s, 100.0 * (e - s) / end))


if __name__ == '__main__':
    main()
