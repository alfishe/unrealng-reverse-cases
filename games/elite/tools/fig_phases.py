#!/usr/bin/env python3
"""One FlightLoop pass animated (docs/04-game-loop.md 4.4): the back buffer and the screen's view at each moment of
the pass, with the pass's strip of calls and a cursor on the work running.

    python3 tools/fig_phases.py [--window 1500:0-1600:0] [--step 6000]   # -> docs/img/loop/phases.gif

The window is an access trace of f1 (the station flight, one pass from ClearView to ClearView inside it). The
strip is eprof's top runs (the routine FlightLoop called, an interrupt shown as the routine it cut), as in
tools/fig_rt_pass.py. The pictures are the trace's memory at the first instruction at or after each step: the back
buffer `$C000-$CFFF` and the screen's top two thirds `$4000-$4FFF`, both in the screen's layout. Pixels set since
the last picture are yellow.
"""
import argparse
import bisect
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import eprof  # noqa: E402

BG, TEXT, DIM, NEW = (14, 14, 20), (220, 220, 230), (130, 130, 145), (255, 220, 60)
PALETTE = [(90, 160, 255), (110, 210, 120), (240, 120, 70), (200, 120, 230), (230, 200, 80), (90, 210, 210),
           (240, 100, 140), (170, 170, 110), (140, 140, 220), (120, 180, 140)]
FRAME_T = 69888


def pixels(m, base):
    """the 256 x 128 picture of the 4 KB at base in the screen's layout: a set of (x, y)"""
    out = set()
    for y in range(128):
        row = base | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for c in range(32):
            b = m[row + c]
            if b:
                for k in range(8):
                    if b & (0x80 >> k):
                        out.add((c * 8 + k, y))
    return out


def panel(now, before, scale):
    im = Image.new('RGB', (256 * scale, 128 * scale), (0, 0, 0))
    d = ImageDraw.Draw(im)
    for x, y in now:
        d.rectangle((x * scale, y * scale, x * scale + scale - 1, y * scale + scale - 1),
                    fill=NEW if (x, y) not in before else (225, 225, 225))
    return im


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--window', default='1500:0-1600:0')
    p.add_argument('--step', type=int, default=6000)
    p.add_argument('--out', default=os.path.join(HERE, '..', 'docs', 'img', 'loop', 'phases.gif'))
    a = p.parse_args()
    trace = eprof.load(os.path.join(HERE, '..', 'work', 'f1'), a.window)
    times = K.instruction_times(trace)
    runs = eprof.profile(trace, top_runs=True, keep_screen=False)['top_runs']
    starts = [i for i, r in enumerate(runs) if r[2] == 'ClearView']
    first, last = starts[0], starts[1]
    t0, t1 = runs[first][0], runs[last][0]
    seg = [r for r in runs[first:last]]
    names = []
    for _s, _d, n in seg:
        if n not in names and n != 'HALT':
            names.append(n)
    weight = {n: sum(d for _s, d, m in seg if m == n) for n in names}
    big = sorted(names, key=lambda n: -weight[n])[:len(PALETTE)]
    colour = {n: PALETTE[i] for i, n in enumerate(big)}
    scale, W = 1.5, 900
    pics, before_b, before_s = [], set(), set()
    for t in range(t0, t1 + 1, a.step):
        i = min(bisect.bisect_left(times, t), len(times) - 1)
        m = trace.memory_at(i)
        buf, scr = pixels(m, 0xC000), pixels(m, 0x4000)
        im = Image.new('RGB', (W, 300 + 110), BG)
        d = ImageDraw.Draw(im)
        d.text((10, 6), 'One station pass of f1 (%d T, %.1f frames): the buffer is drawn, then copied to the screen'
               % (t1 - t0, (t1 - t0) / FRAME_T), fill=TEXT, font=K.font(15))
        b = panel(buf, before_b, 2).resize((384, 192), Image.NEAREST)
        s = panel(scr, before_s, 2).resize((384, 192), Image.NEAREST)
        im.paste(b, (40, 52))
        im.paste(s, (476, 52))
        d.text((40, 32), 'the back buffer $C000-$CFFF', fill=DIM, font=K.font(13))
        d.text((476, 32), 'the screen\'s view $4000-$4FFF', fill=DIM, font=K.font(13))
        # the strip
        y0, x0, xw = 268, 40, 820
        cur = None
        for s0, dur, n in seg:
            xa = x0 + (s0 - t0) * xw // (t1 - t0)
            xb = x0 + (s0 + dur - t0) * xw // (t1 - t0)
            d.rectangle((xa, y0, max(xa, xb - 1), y0 + 26), fill=colour.get(n, (70, 70, 80)))
            if s0 <= t < s0 + dur:
                cur = n
        first_tick = (t0 // FRAME_T + 1) * FRAME_T
        for fb in range(first_tick, t1, FRAME_T):
            x = x0 + (fb - t0) * xw // (t1 - t0)
            d.line((x, y0 - 6, x, y0 + 32), fill=(255, 230, 90), width=1)
        x = x0 + (t - t0) * xw // (t1 - t0)
        d.polygon([(x, y0 + 30), (x - 6, y0 + 42), (x + 6, y0 + 42)], fill=TEXT)
        d.text((40, y0 + 48), 'T %d of the pass: %s' % (t - t0, cur or ''), fill=TEXT, font=K.font(15))
        lx = 40
        for n in big[:7]:
            d.rectangle((lx, y0 + 80, lx + 12, y0 + 92), fill=colour[n])
            d.text((lx + 16, y0 + 78), n, fill=DIM, font=K.font(12))
            lx += 20 + 8 * len(n)
        d.text((40, y0 + 104), 'strip: the routine FlightLoop runs, yellow ticks the frame starts; yellow pixels: '
               'set since the last picture', fill=DIM, font=K.font(12))
        pics.append(im)
        before_b, before_s = buf, scr
    K.save_gif(a.out, pics, [110] * (len(pics) - 1) + [1500])
    print('wrote', os.path.relpath(a.out), len(pics), 'pictures; the pass', t1 - t0, 'T;',
          ', '.join('%s %d' % (n, weight[n]) for n in big))


if __name__ == '__main__':
    main()
