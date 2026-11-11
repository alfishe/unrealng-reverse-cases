#!/usr/bin/env python3
"""Doc 04's pass figures: the cost of each step of a main-loop pass, measured from access traces of our recordings.

    python3 tools/fig_loop.py steps --work W --window F:T-F:T --name rzx02000 --room 08 --out work/docs/tmA/steps.json
    python3 tools/fig_loop.py chart work/docs/tmA/steps.json docs/img/loop/pass-steps.png

`steps` traces the window in the instance of the re_session folder W (kit/kitlib.load_trace, kept in W/traces/) and
cuts every whole pass (one `$9018` to the next) at the main loop's call sites: the lift `$9028`, HeroUpdate `$902B`,
ItemsPass `$9034`, RoomEffects `$9037`, CountDown `$903A`, RunCreatures `$903D`, RenderPass `$9040` and the tail
`$9043-$906A`. The interrupt (from the vector `$5F5F` to the handler's RET `$94AE`, the music in RAM 6 included) is
counted apart, wherever it falls. A step's T-states are the CPU T-states from its first instruction to the next
step's, less the interrupt's inside it. The results are appended to the JSON under the given name.

`chart` draws the median pass of each recording as a stacked bar, a segment a step, in T-states and frames.
"""
import argparse
import json
import os
import statistics
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

FRAME_T = 70908
# the main loop's step starts, in order (MainLoop $9018, build/game.lst)
STEPS = [(0x9018, 'loop top, lift test'), (0x902B, 'HeroUpdate'), (0x902E, 'life test'), (0x9037, 'RoomEffects'),
         (0x903A, 'CountDown'), (0x903D, 'RunCreatures'), (0x9040, 'RenderPass'), (0x9043, 'tail and keys')]
# ItemsPass is CALLed at $9034, inside the 'life test' step: renamed below
NAMES = {'loop top, lift test': 'lift', 'HeroUpdate': 'HeroUpdate', 'life test': 'ItemsPass',
         'RoomEffects': 'RoomEffects', 'CountDown': 'CountDown', 'RunCreatures': 'RunCreatures',
         'RenderPass': 'RenderPass', 'tail and keys': 'tail and keys'}
COLOURS = {'lift': (150, 150, 150), 'HeroUpdate': (240, 110, 90), 'ItemsPass': (250, 200, 80),
           'RoomEffects': (120, 200, 120), 'CountDown': (255, 255, 255), 'RunCreatures': (110, 170, 250),
           'RenderPass': (200, 130, 230), 'tail and keys': (100, 100, 100), 'interrupt': (90, 220, 220)}


def steps(args):
    tr = kitlib.load_trace(args)
    times = kitlib.instruction_times(tr)
    start_pcs = {pc: NAMES[n] for pc, n in STEPS}
    passes, cur, step, step_t, in_int, int_t = [], None, None, 0, False, 0
    for i, x in enumerate(tr.instructions):
        t = times[i]
        dt = (times[i + 1] - t) if i + 1 < len(times) else 0
        if x.pc == 0x5F5F:
            in_int = True
        if in_int:
            if cur is not None:
                cur['interrupt'] = cur.get('interrupt', 0) + dt
                int_t += dt
            if x.pc == 0x94AE:
                in_int = False
            continue
        if x.pc in start_pcs and (x.pc != 0x902E or step == 'HeroUpdate'):
            name = start_pcs[x.pc]
            if x.pc == 0x9018:
                if cur is not None:
                    cur['end'] = f'{x.frame}:{x.t}'
                    passes.append(cur)
                cur = {'start': f'{x.frame}:{x.t}'}
            step = name
        if cur is not None and step:
            cur[step] = cur.get(step, 0) + dt
    passes = [p for p in passes if 'RenderPass' in p]
    for p in passes:
        p['total'] = sum(v for k, v in p.items() if k not in ('start', 'end'))
    data = json.load(open(args.out)) if os.path.isfile(args.out) else {}
    data[args.name] = {'room': args.room, 'window': args.window, 'passes': passes}
    json.dump(data, open(args.out, 'w'), indent=1)
    for p in passes:
        print(p['start'], p['total'], round(p['total'] / FRAME_T, 2),
              {k: v for k, v in p.items() if k not in ('start', 'end', 'total')})


def chart(args):
    from PIL import Image, ImageDraw
    data = json.load(open(args.json))
    order = ['lift', 'HeroUpdate', 'ItemsPass', 'RoomEffects', 'CountDown', 'RunCreatures', 'RenderPass',
             'tail and keys', 'interrupt']
    rows = []
    for name, d in data.items():
        ps = d['passes']
        med = {k: statistics.median(p.get(k, 0) for p in ps) for k in order}
        tot = statistics.median(p['total'] for p in ps)
        rows.append((name, d['room'], len(ps), med, tot))
    W, left, right = 1050, 230, 30
    top, bar_h, gap = 70, 34, 22
    H = top + len(rows) * (bar_h + gap) + 190
    img = Image.new('RGB', (W, H), (16, 16, 22))
    dr = ImageDraw.Draw(img)
    f, fs, fb = kitlib.font(15), kitlib.font(13), kitlib.font(18)
    dr.text((20, 14), args.title, font=fb, fill=(235, 235, 235))
    tmax = 3.5 * FRAME_T
    scale = (W - left - right) / tmax
    for k in range(4):
        x = left + k * FRAME_T * scale
        dr.line([(x, top - 8), (x, top + len(rows) * (bar_h + gap))], fill=(70, 70, 80))
        dr.text((x - 4, top - 28), f'{k} fr', font=fs, fill=(180, 180, 180))
    for r, (name, room, n, med, tot) in enumerate(rows):
        y = top + r * (bar_h + gap)
        dr.text((20, y + 2), f'{name}, room ${room}', font=f, fill=(230, 230, 230))
        dr.text((20, y + 19), f'{n} passes, median {tot / FRAME_T:.2f} fr', font=fs, fill=(170, 170, 170))
        x = left
        for k in order:
            w = med[k] * scale
            dr.rectangle([x, y, x + w, y + bar_h], fill=COLOURS[k])
            if w > 52:
                dr.text((x + 3, y + 9), f'{med[k] / 1000:.0f}k', font=fs, fill=(0, 0, 0))
            x += w
    y = top + len(rows) * (bar_h + gap) + 10
    x = 20
    for k in order:
        dr.rectangle([x, y + 3, x + 14, y + 17], fill=COLOURS[k])
        dr.text((x + 20, y), k, font=f, fill=(220, 220, 220))
        x += 30 + dr.textlength(k, font=f)
        if x > W - 160:
            x, y = 20, y + 26
    y += 34
    for line in args.note:
        dr.text((20, y), line, font=fs, fill=(190, 190, 190))
        y += 20
    img = img.crop((0, 0, W, y + 10))
    img.save(args.out)
    print(args.out)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('steps')
    kitlib.add_trace_args(s)
    s.add_argument('--name', required=True)
    s.add_argument('--room', required=True)
    s.add_argument('--out', required=True)
    c = sub.add_parser('chart')
    c.add_argument('json')
    c.add_argument('out')
    c.add_argument('--title', default='A main-loop pass, step by step: the median pass of five rooms')
    c.add_argument('--note', action='append', default=[])
    args = ap.parse_args()
    steps(args) if args.cmd == 'steps' else chart(args)


if __name__ == '__main__':
    main()
