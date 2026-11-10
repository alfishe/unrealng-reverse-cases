#!/usr/bin/env python3
"""The figures of doc 4 (the game loop).

    python3 tools/fig_loop.py schedule                     # which tasks each slow tick 1-301 runs, from the counters
    python3 tools/fig_loop.py rate --work W --window F:T-F:T [--name NAME]
                                                           # passes a frame and slow ticks over a traced window

schedule replays MainLoop's countdowns ($98E6-$9946) from the values SetupLevel $AE9C gives them: BonusDelay,
DuckDelay, TimeDelay and HenDelay 1, LiftDelay 5, BonusRunning 1. A task runs when its counter, decremented, reaches
0, and the counter is reloaded (50, 12, 2, 10, 3). No grain is taken (grain sets BonusDelay and TimeDelay to 255 and
shifts both). The tick lengths are the medians measured by work/stage2/heavy_tasks.py over 300 ticks of level 4 with
Harry standing (work/stage2/heavy_tasks.out).

rate reads an access trace (kitlib.load_trace: --work W --window F:T-F:T, cached in W/traces/) and marks every
pass start (MainLoop $9858) and every slow tick ($98BE), with the tasks the tick called: D MoveDuck $A0C8, L MoveLifts
$A014, H MoveHen $911E, B / T CountDown $A1B8 with B 0 / 1. Writes docs/img/loop/schedule.png and
docs/img/loop/rate-NAME.png.
"""
import argparse
import os
import sys
from collections import Counter, defaultdict

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'loop')
WIDTH = 1050
BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
FRAME_T = 69888

TASKS = [('B', 'bonus: CountDown B = 0', 50, 1, (240, 200, 70)),
         ('D', 'duck: MoveDuck', 12, 1, (230, 90, 80)),
         ('L', 'lifts: MoveLifts', 2, 5, (90, 150, 250)),
         ('P', 'pickup: TakeEggOrGrain', 1, 1, (120, 120, 135)),
         ('T', 'time: CountDown B = 1', 10, 1, (200, 110, 230)),
         ('H', 'a hen: MoveHen', 3, 1, (90, 200, 120))]
# work/stage2/heavy_tasks.out: median T from $98BE to the next $9858, level 4, Harry standing
MEDIAN = {'BDLTH': 83985, 'DLTH': 82504, 'DLH': 79452, 'LTH': 42319, 'BLTH': 41763, 'H': 37380, 'LH': 39960,
          'BLT': 34284, 'LT': 31707, 'L': 30753, '': 28390, 'BDTH': 82504, 'DH': 79452, 'TH': 42319, 'BTH': 41763,
          'T': 31707, 'BT': 34284, 'B': 30753, 'DT': 79452, 'D': 79452, 'BD': 79452, 'BDT': 82504, 'BDH': 82504}
SET_COLOURS = {'BDLTH': (250, 90, 90), 'BDTH': (250, 90, 90), 'DLTH': (240, 130, 80), 'DLH': (230, 170, 80),
               'DH': (230, 170, 80)}


def fmt(n):
    return f'{n:,}'.replace(',', ' ')


def font(size):
    return K.font(size)


def schedule_tasks(ticks, lift=True):
    """the task letters of each slow tick 1..ticks, as MainLoop's countdowns give them"""
    counters = {k: start for k, _, _, start, _ in TASKS}
    out = []
    for _ in range(ticks):
        run = ''
        for key, _, period, _, _ in TASKS:
            if key == 'P':
                continue
            counters[key] -= 1
            if counters[key] == 0:
                counters[key] = period
                if key != 'L' or lift:
                    run += key
        out.append(run)
    return out


def text_lines(d, x, y, lines, size=14, step=21):
    f = font(size)
    for k, t in enumerate(lines):
        d.text((x, y + k * step), t, fill=DIM if t.startswith('python3') else TEXT, font=f)
    return y + len(lines) * step


def schedule(_a):
    n = 301
    runs = schedule_tasks(n)
    left, cw = 132, 3
    rh, top = 26, 70
    rows = len(TASKS)
    bar_top = top + rows * rh + 40
    bar_h = 170
    im = Image.new('RGB', (WIDTH, bar_top + bar_h + 250), BG)
    d = ImageDraw.Draw(im)
    d.text((12, 10), 'The slow tick\'s tasks, ticks 1-301 of a level, from MainLoop\'s countdowns', fill=TEXT,
           font=font(20))
    d.text((12, 38), 'Each column is one slow tick (every 130 passes). A coloured cell: the task runs on that tick.',
           fill=DIM, font=font(14))
    for r, (key, name, period, start, colour) in enumerate(TASKS):
        y = top + r * rh
        d.rectangle([left, y, left + n * cw, y + rh - 6], fill=PANEL)
        d.text((12, y + 2), key + '  every ' + (str(period) if period > 1 else '1'), fill=TEXT, font=font(14))
        for i in range(n):
            on = key == 'P' or key in runs[i]
            if on:
                d.rectangle([left + i * cw, y, left + i * cw + cw - 1, y + rh - 6], fill=colour)
    for tick in (1, 13, 61, 151, 301):
        x = left + (tick - 1) * cw + 1
        d.line([x, top - 6, x, top + rows * rh - 6], fill=(255, 255, 255), width=1)
        d.text((x - 8, top - 22), str(tick), fill=TEXT, font=font(12))
    # tick lengths
    y0 = bar_top + bar_h
    d.rectangle([left, bar_top, left + n * cw, y0], fill=PANEL)
    scale = bar_h / 90000
    for ref in (30000, 60000, FRAME_T):
        yy = y0 - ref * scale
        d.line([left, yy, left + n * cw, yy], fill=(70, 70, 85))
        if ref != FRAME_T:
            d.text((left - 60, yy - 8), fmt(ref), fill=DIM, font=font(12))
    d.text((left + n * cw + 6, y0 - FRAME_T * scale - 8), 'a', fill=DIM, font=font(12))
    d.text((left + n * cw + 6, y0 - FRAME_T * scale + 6), 'frame', fill=DIM, font=font(12))
    for i, run in enumerate(runs):
        t = MEDIAN.get(run, 28390)
        c = SET_COLOURS.get(run, (110, 160, 230))
        d.rectangle([left + i * cw, y0 - t * scale, left + i * cw + cw - 1, y0], fill=c)
    d.text((12, bar_top + 4), 'tick length', fill=TEXT, font=font(14))
    d.text((12, bar_top + 24), 'median T', fill=DIM, font=font(12))
    counts = Counter(runs)
    total = sum(MEDIAN.get(r, 28390) for r in runs)
    lines = [
        f'Over 301 ticks: the duck runs {sum("D" in r for r in runs)} times, the lifts {sum("L" in r for r in runs)}, '
        f'a hen {sum("H" in r for r in runs)}, the time {sum("T" in r for r in runs)}, the bonus '
        f'{sum("B" in r for r in runs)}.',
        f'Tick 1 runs B D T H together (the lifts start at 5); tick 301 is the first B D L T H: '
        f'{fmt(MEDIAN["BDLTH"])} T, 1.2 frames.',
        f'The duck\'s ticks ({counts["DLH"] + counts["DH"] + counts["DLTH"] + counts["BDTH"] + counts["BDLTH"]}) '
        'are the heavy ones: the duck is drawn twice (erased, then drawn) with DrawSprite.',
        f'The 301 ticks take {fmt(total)} T in all, {total / FRAME_T:.0f} frames, plus 130 light passes '
        'of about 158 T before each.',
        'Lengths: medians of work/stage2/heavy_tasks.out (level 4, Harry standing, levels-1-3/end.szx);',
        'a set not met there (tick 1\'s B D T H) takes the length of the nearest measured set (D L T H).',
        'python3 tools/fig_loop.py schedule',
    ]
    text_lines(d, 12, y0 + 22, lines)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'schedule.png')
    im.save(path)
    print(path, im.size)


def trace_events(a):
    tr = K.load_trace(a)
    units = max(1, tr.units_per_t)
    ft = tr.frame_t
    passes, ticks, cur = [], [], None
    for x in tr.instructions:
        t = x.t // units
        at = x.frame * ft + t
        if x.pc == 0x9858:
            passes.append((x.frame, t, at))
            if cur is not None:
                cur['end'] = at
                ticks.append(cur)
                cur = None
        elif x.pc == 0x98BE:
            cur = {'frame': x.frame, 't': t, 'at': at, 'tasks': ''}
        elif cur is not None and x.pc in (0xA0C8, 0xA014, 0x911E):
            cur['tasks'] += {0xA0C8: 'D', 0xA014: 'L', 0x911E: 'H'}[x.pc]
        elif cur is not None and x.pc == 0xA1B8:
            cur['tasks'] += 'B' if (x.bc >> 8) == 0 else 'T'
    return tr, passes, ticks


def rate(a):
    tr, passes, ticks = trace_events(a)
    f0, f1 = tr.from_frame, tr.to_frame
    frames = list(range(f0 + 1, f1))
    per_frame = Counter(p[0] for p in passes)
    ticks_per_frame = Counter(k['frame'] for k in ticks)
    pass_len = [(nxt - at) for (_, _, at), (_, _, nxt) in zip(passes, passes[1:])]
    light = sorted(L for L in pass_len if L < 2000)
    left, top = 92, 70
    pw = WIDTH - left - 30
    ph = 220
    im = Image.new('RGB', (WIDTH, top + ph + 60 + 300 + 160), BG)
    d = ImageDraw.Draw(im)
    d.text((12, 10), f'Passes and slow ticks per frame: {a.name}, frames {f0 + 1}-{f1 - 1}', fill=TEXT, font=font(20))
    d.text((12, 38), 'Bars: the passes that start in each frame. Dots under them: the slow ticks that start in it, '
           'coloured by their tasks.', fill=DIM, font=font(14))
    d.rectangle([left, top, left + pw, top + ph], fill=PANEL)
    bw = pw / len(frames)
    mx = 280
    for ref in (0, 100, 200):
        yy = top + ph - ref * ph / mx
        d.line([left, yy, left + pw, yy], fill=(70, 70, 85))
        d.text((left - 40, yy - 8), str(ref), fill=DIM, font=font(12))
    colours = {'D': (230, 90, 80), 'L': (90, 150, 250), 'H': (90, 200, 120), 'T': (200, 110, 230),
               'B': (240, 200, 70)}

    def tick_colour(tasks):
        if 'D' in tasks:
            return colours['D']
        if 'H' in tasks:
            return colours['H']
        if 'T' in tasks or 'B' in tasks:
            return colours['T']
        if 'L' in tasks:
            return colours['L']
        return DIM

    for i, f in enumerate(frames):
        x = left + i * bw
        h = per_frame.get(f, 0) * ph / mx
        d.rectangle([x, top + ph - h, x + max(1, bw - 1), top + ph], fill=(110, 160, 230))
    by_frame = defaultdict(list)
    for k in ticks:
        by_frame[k['frame']].append(k)
    for i, f in enumerate(frames):
        for j, k in enumerate(by_frame.get(f, [])):
            x = left + i * bw + bw / 2
            y = top + ph + 12 + j * 9
            d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=tick_colour(k['tasks']))
    for i, f in enumerate(frames):
        if f % 25 == 0:
            d.text((left + i * bw - 12, top + ph + 32), str(f), fill=DIM, font=font(12))
    # tick lengths by task set
    y1 = top + ph + 70
    d.text((12, y1 - 4), 'Each slow tick\'s length (T from $98BE to the next pass) by the tasks it ran', fill=TEXT,
           font=font(16))
    groups = defaultdict(list)
    for k in ticks:
        groups[k['tasks'] or '-'].append(k['end'] - k['at'])
    order = sorted(groups, key=lambda g: sorted(groups[g])[len(groups[g]) // 2])
    gh = 250
    gy = y1 + 24
    d.rectangle([left, gy, left + pw, gy + gh], fill=PANEL)
    tmax = 110000
    for ref in (0, 30000, 60000, FRAME_T, 90000):
        yy = gy + gh - ref * gh / tmax
        d.line([left, yy, left + pw, yy], fill=(90, 90, 105) if ref == FRAME_T else (60, 60, 75))
        d.text((left - 64, yy - 8), f'{ref:,}'.replace(',', ' '), fill=DIM, font=font(12))
    d.text((left + 6, gy + gh - FRAME_T * gh / tmax - 17), 'a frame', fill=DIM, font=font(12))
    cw = pw / max(1, len(order))
    for i, g in enumerate(order):
        xs = left + i * cw + cw / 2
        vals = sorted(groups[g])
        for v in vals:
            yy = gy + gh - min(v, tmax) * gh / tmax
            d.line([xs - 10, yy, xs + 10, yy], fill=tick_colour(g if g != '-' else ''), width=2)
        med = vals[len(vals) // 2]
        d.text((xs - 18, gy + gh + 6), g, fill=TEXT, font=font(13))
        d.text((xs - 18, gy + gh + 24), f'n {len(vals)}', fill=DIM, font=font(12))
        d.text((xs + 14, gy + gh - med * gh / tmax - 7), f'{med // 1000}k', fill=DIM, font=font(11))
    pf = [per_frame.get(f, 0) for f in frames]
    tf = [ticks_per_frame.get(f, 0) for f in frames]
    zero = sum(1 for v in pf if v == 0)
    lines = [
        f'{len(passes)} passes and {len(ticks)} slow ticks over {len(frames) + 1} frames: '
        f'{len(passes) / (len(frames) + 1):.1f} passes and {len(ticks) / (len(frames) + 1):.2f} ticks a frame.',
        f'Passes a frame: {min(pf)} to {max(pf)}, median {sorted(pf)[len(pf) // 2]}; {zero} frames hold no pass start '
        f'(a tick longer than a frame covers them).',
        f'A pass without a tick: {light[0]} to {light[-1]} T, median {light[len(light) // 2]} T; long: '
        f'the IM 2 interrupt (270-288 T){", the pickup Beep (1000 T+)" if light[-1] > 1000 else ""}.' if light else '',
        'Dots: red the duck\'s ticks, green a hen\'s, purple the time or the bonus, blue the lifts alone, grey none.',
        f'python3 tools/fig_loop.py rate --work {a.work} --window {a.window} --name {a.name}',
    ]
    text_lines(d, 12, gy + gh + 52, [t for t in lines if t])
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f'rate-{a.name}.png')
    im.save(path)
    print(path, im.size)
    print('\n'.join(t for t in lines if t))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['schedule', 'rate'])
    K.add_trace_args(p)
    p.add_argument('--name', default='levels-1-9')
    a = p.parse_args()
    {'schedule': schedule, 'rate': rate}[a.what](a)


if __name__ == '__main__':
    main()
