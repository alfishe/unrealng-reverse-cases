#!/usr/bin/env python3
"""Where one game turn's time goes: the phases of PlayLoop ($A69A) along the T-states of an access trace, the
interrupts apart, as a table and a bar figure (docs/04-game-loop.md).

    python3 tools/turn_profile.py TRACE.uatr [--turn N] [--png work/figs/turn-phases.png]

A turn runs from one entry of PlayLoop to the next. The phase is the PlayLoop call that is running (WaitKey,
MoveShip, WorldTurn, DrawView split into its three calls, GameTurn up to the pacing loop TurnPace, TurnPace, then the
landing checks); an interrupt runs from the CPU's jump to the IM 2 vector $FDFD until SP is back above the stack
the interrupt pushed on. --turn picks the Nth whole turn of the trace (0 the first).
"""
import argparse
import os
import sys
from collections import OrderedDict

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

PLAY_LOOP = 0xA69A
CALLS = {0xA69A: 'WaitKey', 0xA69D: 'MoveShip', 0xA6A0: 'WorldTurn', 0xA6A3: 'DrawView', 0xA6A6: 'GameTurn',
         0xA6A9: 'landing checks'}
DRAW = {0xCFD7: 'DrawView: DrawViewBackground', 0xCCC6: 'DrawView: DrawMapObjects',
        0xD071: 'DrawView: CopyViewToScreen'}
TURN_PACE = (0xAE1D, 0xAE24)        # LD A,(TurnFrames); CP $0A; JR C,TurnPace
VECTOR = 0xFDFD
COLOURS = {'WaitKey': (120, 120, 120), 'DrawView': (150, 110, 220), 'MoveShip': (90, 160, 230), 'WorldTurn': (230, 150, 60),
           'DrawView: DrawViewBackground': (150, 110, 220), 'DrawView: DrawMapObjects': (200, 80, 200),
           'DrawView: CopyViewToScreen': (230, 70, 70), 'GameTurn': (90, 200, 120), 'TurnPace': (60, 60, 70),
           'landing checks': (200, 200, 90), 'interrupt': (250, 250, 250)}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('trace')
    p.add_argument('--turn', type=int, default=0)
    p.add_argument('--png')
    p.add_argument('--unreal')
    args = p.parse_args()
    trace = K.access_trace(args.unreal).load(args.trace)
    units = max(1, trace.units_per_t)
    ft = trace.frame_t or 69888
    xs = trace.instructions
    absolute = [(x.frame - trace.from_frame) * ft + x.t // units for x in xs]
    starts = [i for i, x in enumerate(xs) if x.pc == PLAY_LOOP]
    if len(starts) < args.turn + 2:
        raise SystemExit(f'{len(starts)} entries of PlayLoop in the trace: no whole turn {args.turn}')
    lo, hi = starts[args.turn], starts[args.turn + 1]
    phase, irq_sp = 'WaitKey', None
    spans = []          # (phase, t0, t1)
    total = OrderedDict()
    for i in range(lo, hi):
        x = xs[i]
        if irq_sp is None and x.pc == VECTOR:
            irq_sp = x.sp
        elif irq_sp is not None and x.sp > irq_sp:
            irq_sp = None
        if x.pc in CALLS:
            phase = CALLS[x.pc]
        elif x.pc in DRAW and phase.startswith('DrawView'):
            phase = DRAW[x.pc]
        elif TURN_PACE[0] <= x.pc <= TURN_PACE[1] and phase == 'GameTurn':
            phase = 'TurnPace'
        name = 'interrupt' if irq_sp is not None else phase
        t0, t1 = absolute[i], absolute[i + 1]
        total[name] = total.get(name, 0) + t1 - t0
        if spans and spans[-1][0] == name and spans[-1][2] == t0:
            spans[-1] = (name, spans[-1][1], t1)
        else:
            spans.append((name, t0, t1))
    t_lo, t_hi = absolute[lo], absolute[hi]
    f0, f1 = xs[lo], xs[hi]
    print(f'turn {args.turn}: PlayLoop at frame {f0.frame} T {f0.t // units} .. frame {f1.frame} T {f1.t // units}: '
          f'{t_hi - t_lo} T = {(t_hi - t_lo) / ft:.2f} frames, {hi - lo} instructions')
    print('| Phase | T-states | Frames | Share | Starts at (frame, T) |')
    print('| --- | ---: | ---: | ---: | --- |')
    first = {}
    for name, a, _ in spans:
        first.setdefault(name, a)
    for name, t in total.items():
        a = first[name]
        print(f'| {name} | {t} | {t / ft:.2f} | {100 * t / (t_hi - t_lo):.1f} % | '
              f'{trace.from_frame + a // ft}, {a % ft} |')
    if args.png:
        draw_bar(args.png, spans, t_lo, t_hi, ft, trace.from_frame, f0.frame)


def draw_bar(path, spans, t_lo, t_hi, ft, from_frame, first_frame):
    width, left, bar_h = 1100, 20, 60
    scale = (width - 2 * left) / (t_hi - t_lo)
    names = [n for n in COLOURS if n != 'DrawView' and any(s[0] == n for s in spans)]
    height = 90 + bar_h + 22 * ((len(names) + 2) // 3)
    image = Image.new('RGB', (width, height), (24, 24, 30))
    d = ImageDraw.Draw(image)
    f = K.font(13)
    d.text((left, 8), f'One game turn of the deep recording, frames {first_frame} on: PlayLoop phases along the '
           f'T-states ({(t_hi - t_lo) / ft:.2f} frames)', fill=(230, 230, 230), font=f)
    y0 = 40
    for name, a, b in spans:
        x0, x1 = left + (a - t_lo) * scale, left + (b - t_lo) * scale
        d.rectangle([x0, y0, max(x0, x1 - 1), y0 + bar_h], fill=COLOURS[name])
    first = ((t_lo // ft) + 1) * ft
    for t in range(first, t_hi, ft):
        x = left + (t - t_lo) * scale
        d.line([x, y0 - 6, x, y0 + bar_h + 6], fill=(255, 255, 255))
        if x < width - 100:
            d.text((x + 2, y0 + bar_h + 6), f'frame {from_frame + t // ft}', fill=(200, 200, 200), font=f)
    for i, name in enumerate(names):
        x, y = left + (i % 3) * 360, y0 + bar_h + 34 + 22 * (i // 3)
        d.rectangle([x, y, x + 14, y + 14], fill=COLOURS[name], outline=(160, 160, 160))
        d.text((x + 20, y), name, fill=(230, 230, 230), font=f)
    image.save(path)
    print(path)


if __name__ == '__main__':
    sys.exit(main())
