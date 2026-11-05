#!/usr/bin/env python3
"""Doc 04 figure: the play interrupt's pass on a frame timeline, from an access trace.

    python3 tools/fig_pass.py --work work/zyA/c2 --window 300:0-310:0 --rows 300-305 --out docs/img/loop/pass.png
    python3 tools/fig_pass.py --work work/zyA/r1 --window 2250:0-2260:0 --rows 2252-2257 --out docs/img/loop/nested.png

One row a frame, the frame's T-states across (0 at the left, 69888 at the right). Each stretch of the row is
coloured by the part of the pass the CPU is in: a part starts where its routine is entered (PlayInterrupt's calls,
DrawPlayfield, PlayPass, the chain step) and lasts until the next part starts. "main loop" is everything outside the
interrupt: from the RET of PlayInterruptExit (back to the address the INT pushed) to the next accepted INT. A green
tick marks an accepted INT (the IM2 jump at $FDFD), a red cross an INT the CPU did not take (no $FDFD in the INT's
window, frame T 1812-1860: the CPU was under DI). The strip under each row is the interrupt depth: 0 main loop,
1 a pass, 2 a pass nested in a pass. The phase PlayInterrupt gave the pass ($7F65) is written at its INT.
The table printed at the end is the T-states of each part over the rows.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

PASS_PHASE, PASS_DEPTH = 0x7F65, 0x7F64
INT_T, INT_WINDOW = 1812, 48
# entry address -> part
MARKERS = {
    0xFDFD: 'interrupt entry', 0x8AED: 'scroll step', 0x894D: 'start column', 0x9150: 'hit grid',
    0x91C6: 'hit grid', 0x8894: 'stars', 0xAB13: 'panel', 0x85CA: 'draw playfield', 0xAA96: 'play logic',
    0xAAC3: 'chain wait', 0xAAEA: 'chain step (build column)', 0xAAEF: 'chain step (build column)',
    0xAAF4: 'chain step (build column)', 0xAAF9: 'chain end', 0xAAFF: 'interrupt exit',
}
COLOURS = {
    'main loop': (70, 70, 90), 'interrupt entry': (240, 240, 240), 'scroll step': (90, 150, 250),
    'start column': (70, 210, 220), 'hit grid': (200, 110, 230), 'wait (DJNZ)': (110, 110, 60),
    'stars': (250, 250, 140), 'panel': (250, 150, 60), 'draw playfield': (230, 90, 80),
    'play logic': (90, 200, 120), 'chain wait': (150, 150, 70), 'chain step (build column)': (70, 160, 160),
    'chain end': (160, 220, 80), 'interrupt exit': (240, 120, 180), 'before the first INT': (30, 30, 40),
}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--rows', required=True, help='F-F: the frames drawn, one row each')
    p.add_argument('--listing', default=os.path.join(HERE, '..', 'build', 'game.lst'))
    p.add_argument('--title', default='')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    lst = K.listing(args.listing)
    labels = {n: a for a, n in lst.labels}
    wait_lo = labels.get('PlayInterruptWait', 0)
    delay2 = labels.get('PlayInterruptDelay2', 0)
    trace = K.load_trace(args)
    units = max(1, trace.units_per_t)
    frame_t = trace.frame_t
    r0, r1 = (int(v) for v in args.rows.split('-'))
    mem = bytearray(trace.memory)
    part, stack, started = 'before the first INT', [], False
    spans = []         # (frame, t0, t1, part, depth)
    ints = []          # (frame, t, phase, depth after)
    xs = trace.instructions
    for i, x in enumerate(xs):
        t = x.t // units
        if x.pc == 0xFDFD:
            ret = mem[x.sp] | mem[(x.sp + 1) & 0xFFFF] << 8
            stack.append((x.sp, ret, part))
            started = True
        if started and stack and x.pc == stack[-1][1] and x.sp >= stack[-1][0] + 2:
            part = stack.pop()[2]
            if part == 'before the first INT':
                part = 'main loop'
        if x.pc in MARKERS and started:
            part = MARKERS[x.pc]
        elif started and (wait_lo <= x.pc < wait_lo + 8 or delay2 - 2 <= x.pc <= delay2):
            part = 'wait (DJNZ)'
        for c in x.cycles:
            if c.tag == 'W':
                mem[c.address] = c.value
        nxt = xs[i + 1] if i + 1 < len(xs) else None
        t_end = (nxt.t // units + (nxt.frame - x.frame) * frame_t) if nxt else t + 4
        spans.append((x.frame, t, t_end, part, len(stack)))
        if x.pc == 0xFDFD:
            ints.append([x.frame, t, None, len(stack)])
        if ints and ints[-1][2] is None and x.pc == labels.get('PlayInterruptWait', -2):
            ints[-1][2] = mem[PASS_PHASE]
        if ints and ints[-1][2] is None and x.pc == labels.get('PlayInterruptPhase', -2):
            ints[-1][2] = mem[PASS_PHASE]
    # draw
    W, left, row_h, depth_h, gap = 900, 74, 28, 8, 22
    rows = list(range(r0, r1 + 1))
    plot_w = W - left - 16
    sx = plot_w / frame_t
    legend_parts = [k for k in COLOURS if any(s[3] == k for s in spans if r0 <= s[0] <= r1)]
    top = 88
    legend_h = 18 * ((len(legend_parts) + 2) // 3) + 40
    H = top + len(rows) * (row_h + depth_h + gap) + 30 + legend_h
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb, fs = K.font(12), K.font(15), K.font(11)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    d.text((10, 30), 'one row a frame, its T-states left to right; colour = the part of the pass running; '
                     'strip below = interrupt depth', fill=K.DIM, font=f)
    for k in range(0, frame_t, 10000):
        x = left + k * sx
        d.line([(x, top - 28), (x, top - 24)], fill=K.DIM)
        d.text((x - 10, top - 42), f'{k // 1000}k', fill=K.DIM, font=fs)
    totals = {}
    for ri, fr in enumerate(rows):
        y = top + ri * (row_h + depth_h + gap)
        d.text((8, y + 7), f'{fr}', fill=K.TEXT, font=f)
        for frame, t0, t1, part, depth in spans:
            if frame != fr:
                continue
            t1 = min(t1, frame_t)
            totals[part] = totals.get(part, 0) + (t1 - t0)
            x0, x1 = left + t0 * sx, left + t1 * sx
            d.rectangle((x0, y, max(x0, x1 - 0.01), y + row_h), fill=COLOURS[part])
            dc = [(40, 40, 50), (120, 120, 160), (240, 200, 70), (255, 80, 80)][min(depth, 3)]
            d.rectangle((x0, y + row_h + 2, max(x0, x1 - 0.01), y + row_h + 2 + depth_h), fill=dc)
        # INTs
        taken = [a for a in ints if a[0] == fr]
        for frame, t, phase, depth in taken:
            x = left + t * sx
            d.line([(x, y - 4), (x, y + row_h + depth_h + 4)], fill=(80, 255, 110), width=2)
            label = f'INT phase {phase}' if phase is not None else 'INT'
            label += f', depth {depth}'
            d.text((x + 4, y - 15), label, fill=(80, 255, 110), font=fs)
        if not any(INT_T <= t <= INT_T + INT_WINDOW for _, t, _, _ in taken):
            x = left + INT_T * sx
            d.line([(x - 5, y + 4), (x + 5, y + 14)], fill=(255, 70, 70), width=2)
            d.line([(x - 5, y + 14), (x + 5, y + 4)], fill=(255, 70, 70), width=2)
            d.text((x + 8, y - 15), 'INT lost (DI)', fill=(255, 90, 90), font=fs)
    y = top + len(rows) * (row_h + depth_h + gap) + 6
    d.text((10, y), 'parts (each starts where its routine is entered):', fill=K.TEXT, font=f)
    for i, part in enumerate(legend_parts):
        cx, cy = 10 + (i % 3) * 296, y + 20 + (i // 3) * 18
        d.rectangle((cx, cy + 2, cx + 14, cy + 12), fill=COLOURS[part])
        share = 100 * totals.get(part, 0) / (len(rows) * frame_t)
        d.text((cx + 20, cy), f'{part} {share:.0f}%', fill=K.TEXT, font=f)
    cy = y + 20 + ((len(legend_parts) + 2) // 3) * 18
    d.text((10, cy), 'depth strip: dark 0 (main loop), blue-grey 1 (a pass), yellow 2 (a pass inside a pass); '
                     'green line = INT taken', fill=K.DIM, font=f)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)
    for part, t in sorted(totals.items(), key=lambda kv: -kv[1]):
        print(f'{part:28s} {t:8d} T {100 * t / (len(rows) * frame_t):5.1f}%')
    for a in ints:
        print('INT', a)


if __name__ == '__main__':
    main()
