#!/usr/bin/env python3
"""The figure of doc 04: the interrupt's length at each of the 256 frames of its cycle, by part, from a trace.

    python3 tools/fig_loop.py TRACE.uatr [--frames-at-start N]

TRACE is an access trace (unreal-ng `analysis trace`) of 256 or more frames of the menu idle; the parts are told
apart by the PC: the music ($C000-$C477), the twinkle (TwinkleStar to EraseTwinkle), the glint (LogoGlint to
GlintBright), the cursor (the paint and CursorAttrAddr), the spin (RotateCursorName to CopyNameToScreen), the keys
(ReadKeyboard and what it calls). Each bar is placed by the Frames value the handler writes, read from the trace's
write to $5C78. Writes docs/img/loop/interrupt-frames.png.
"""
import argparse

import figzyx as Z

PARTS = [  # (name, colour, ranges)
    ('music (ASC player)', (90, 150, 250), [(0xC000, 0xC477)]),
    ('twinkle', (230, 90, 80), [(0x6BA5, 0x6CA1)]),
    ('glint', (200, 110, 230), [(0x6D04, 0x6DC5)]),
    ('cursor colour', (160, 220, 80), [(0x6785, 0x67AE), (0x6848, 0x6862)]),
    ('spin (RotateCursorName)', (240, 200, 70), [(0x67AF, 0x682C), (0x6CA2, 0x6CBE)]),
    ('keys (ReadKeyboard)', (250, 150, 60), [(0x6864, 0x6A50)]),
    ('the rest of the handler', (120, 120, 135), [(0x0000, 0xFFFF)]),
]


def part_of(pc):
    for i, (_, _, ranges) in enumerate(PARTS):
        if any(lo <= pc <= hi for lo, hi in ranges):
            return i
    return len(PARTS) - 1


def measure(path):
    m = Z.K.access_trace(None)
    tr = m.load(path)
    times = Z.K.instruction_times(tr)
    runs = []          # (frames value, [T per part])
    cur, frames = None, None
    for k, x in enumerate(tr.instructions):
        if x.pc == 0x6757:
            cur, frames = [0] * len(PARTS), None
        if cur is not None:
            if k + 1 < len(times):
                cur[part_of(x.pc)] += times[k + 1] - times[k]
            if x.pc == 0x6774:          # LD (Frames),HL: HL is the new value
                frames = x.hl
            if x.pc == 0x6847:
                runs.append((frames, cur))
                cur = None
    return runs


def main():
    p = argparse.ArgumentParser()
    p.add_argument('trace')
    p.add_argument('--first', type=int, default=None, help='the Frames low byte of the first whole run')
    args = p.parse_args()
    runs = measure(args.trace)
    by_low = {}
    for i, (frames, parts) in enumerate(runs):
        low = (frames & 0xFF) if frames is not None else ((args.first or 0) + i) & 0xFF
        by_low[low] = parts
    frame_t = 71680
    out, d = Z.canvas(560)
    Z.title(d, 'The interrupt at each of the 256 frames of its cycle: T-states by part (c2 frames 1497-1752, page 1 '
               'idle)', 'x: the Frames low byte the handler has just set; y: the handler\'s T-states; the frame is '
                        '71 680 T (the top line)')
    x0, y0, w, h = 70, 70, 960, 360
    d.rectangle([x0, y0, x0 + w, y0 + h], outline=(60, 60, 75))
    scale = h / frame_t
    for t in range(0, frame_t + 1, 10000):
        yy = y0 + h - t * scale
        d.line([(x0 - 4, yy), (x0, yy)], fill=Z.DIM)
        d.text((8, yy - 7), f'{t:,}'.replace(',', ' '), fill=Z.DIM, font=Z.font(11))
    d.line([(x0, y0), (x0 + w, y0)], fill=(230, 90, 80))
    bw = w / 256
    for low in range(256):
        parts = by_low.get(low)
        if not parts:
            continue
        yy = y0 + h
        for i, t in enumerate(parts):
            if t <= 0:
                continue
            top = yy - t * scale
            d.rectangle([x0 + low * bw, top, x0 + (low + 1) * bw - 1, yy], fill=PARTS[i][1])
            yy = top
    for low in range(0, 256, 16):
        d.text((x0 + low * bw, y0 + h + 4), str(low), fill=Z.DIM, font=Z.font(11))
    for i, (name, colour, _) in enumerate(PARTS):
        xx = x0 + (i % 4) * 240
        yy = y0 + h + 26 + (i // 4) * 20
        d.rectangle([xx, yy + 2, xx + 14, yy + 14], fill=colour)
        d.text((xx + 20, yy), name, fill=Z.TEXT, font=Z.font(12))
    tot = sorted((sum(p), low) for low, p in by_low.items())
    note = (f'{len(by_low)} runs; the shortest {tot[0][0]} T (Frames {tot[0][1]}), the longest {tot[-1][0]} T '
            f'(Frames {tot[-1][1]}); drawn by tools/fig_loop.py from the trace')
    d.text((x0, y0 + h + 72), note, fill=Z.DIM, font=Z.font(12))
    Z.save(out, 'docs/img/loop/interrupt-frames.png')
    for low in sorted(by_low):
        print(low, sum(by_low[low]), by_low[low])


if __name__ == '__main__':
    main()
