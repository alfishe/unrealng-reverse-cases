#!/usr/bin/env python3
"""Doc 04's figure: the average pass of each stage, cut by what the time goes to.

    python3 tools/fig_loop.py docs/img/loop/pass-anatomy.png
    python3 tools/fig_loop.py passes C1.json R1.json docs/img/loop/pass-lengths.png

passes: the pass lengths of two stretches, each a tools/passes.py --json output: c1 frames 16158-16658 (room 8,
no pacing, one room change) and rzx-r1 frames 3000-3030 (room 0 of grid 0, paced by PacePass's busy wait).

For each stage the RZX run's L1 build (work/stage2/rec/rzx-rN/l1.json) is summed per routine with kit/fig_budget.py's
own reader (the stage's .ann over $6C3F-$F03E, the resident's over $F03F-$FFFF), then divided by the passes (the L1
count of the stage's MainLoop entry). The routines are grouped: the three render routines on their own, the rest of
the render module, the game logic (hero, actors, enemies, missiles, duel), the rooms, the HUD and texts, the busy waits
(DelayBC, TextPassDelay), HALT, the resident (the AY driver from the interrupt, the key readers) and the rest. The
grid marks whole frames of 70 908 T (the RZX run is a 128K).
"""
import json
import os
import sys

from figmyth import P, W, F, TEXT, DIM, HI, PANEL, canvas, save

sys.path.insert(0, P('..', '..', 'kit'))
import fig_budget  # noqa: E402

MAINLOOP = {1: 0x7839, 2: 0x7837, 3: 0x784A, 4: 0x7837, 5: 0x7843}
GROUPS = [
    ('ClearBuffer', (90, 140, 220)),
    ('CopyBuffer', (70, 110, 200)),
    ('UpdateAttributes', (120, 170, 240)),
    ('render, other', (150, 190, 240)),
    ('game logic', (220, 130, 60)),
    ('rooms', (110, 180, 110)),
    ('HUD and texts', (200, 160, 70)),
    ('busy wait', (200, 90, 90)),
    ('HALT', (90, 90, 100)),
    ('resident', (170, 110, 210)),
    ('other', (130, 130, 140)),
]
COLOUR = dict(GROUPS)
LOGIC = {'hero', 'actors', 'enemies', 'missiles', 'duel', 'stars', 'mainloop', 'entry'}


def group_of(name, module):
    if name in ('ClearBuffer', 'CopyBuffer', 'UpdateAttributes'):
        return name
    if name in ('DelayBC', 'TextPassDelay', 'DelayBCLoop', 'PacePassWait', 'DelayBCTest', 'PacePass'):
        return 'busy wait'
    if name == fig_budget.HALT_NAME:
        return 'HALT'
    if module.startswith('resident'):
        return 'resident'
    if module == 'render':
        return 'render, other'
    if module in LOGIC:
        return 'game logic'
    if module == 'rooms':
        return 'rooms'
    if module in ('hud', 'texts'):
        return 'HUD and texts'
    return 'other'


def passes(l1, address):
    doc = json.load(open(l1))
    for z80, page, code, cls, count, *_ in doc['instructions']:
        if int(z80[1:], 16) == address:
            return count
    raise SystemExit(f'{l1}: no ${address:04X}')


def main(out):
    rows = []
    for n in range(1, 6):
        l1 = P('work', 'stage2', 'rec', 'rzx-r%d' % n, 'l1.json')
        parts = [fig_budget.Part(P('src', 'stage%d' % n, 'stage%d.ann' % n) + ',page=0/2/5,range=6C3F-F03E', True),
                 fig_budget.Part(P('src', 'resident', 'resident.ann') + ',page=0/2/5,range=F03F-FFFF,label=resident',
                                 False)]
        b = fig_budget.budget(l1, parts, None, {})
        k = passes(l1, MAINLOOP[n])
        sums = {g: 0 for g, _ in GROUPS}
        for name, t in b['per'].items():
            sums[group_of(name, b['module_of'][name])] += t
        total = b['total']
        sums['other'] += total - sum(b['per'].values())   # T-states the L1 does not count, if any
        rows.append((n, k, b['frames'], b['frame'], {g: t / k for g, t in sums.items()}))
        print(n, k, b['frames'], {g: round(t / k) for g, t in sums.items()})
    im, d, y = canvas(560, 'The average pass of each stage, by what its time goes to',
                      'The RZX run, one L1 build a stage: every T-state of the recording divided by the passes of '
                      'the stage\'s MainLoop.\nThe grid marks frames of 70 908 T. Stages 1-4 run free; stage 5 '
                      'waits for the frame with a HALT each pass.')
    x0, x1 = 120, W - 20
    tmax = 4 * 70908
    px = lambda t: x0 + t * (x1 - x0) / tmax  # noqa: E731
    y += 14
    bh, gap = 46, 22
    for f in range(0, 5):
        x = px(f * 70908)
        d.line((x, y - 6, x, y + 5 * (bh + gap)), fill=(60, 60, 72))
        d.text((x - (24 if f < 4 else 64) if f else x, y + 5 * (bh + gap) + 4), '%d frame%s' % (f, '' if f == 1 else 's'), font=F(13),
               fill=DIM)
    for i, (n, k, frames, frame, per) in enumerate(rows):
        yy = y + i * (bh + gap)
        d.text((16, yy + 4), 'stage %d' % n, font=F(15), fill=TEXT)
        d.text((16, yy + 24), '%d passes' % k, font=F(13), fill=DIM)
        t = 0
        for g, colour in GROUPS:
            v = per[g]
            if v <= 0:
                continue
            a, b2 = px(t), px(t + v)
            d.rectangle((a, yy, max(b2 - 1, a + 1), yy + bh), fill=colour)
            if b2 - a > 52:
                d.text((a + 4, yy + 14), '%dK' % round(v / 1000), font=F(13), fill=(15, 15, 20))
            t += v
        d.text((px(t) + 6, yy + 14), '%.2f frames' % (t / 70908), font=F(13), fill=HI)
    yy = y + 5 * (bh + gap) + 34
    lx = x0
    for g, colour in GROUPS:
        tw = d.textlength(g, font=F(13))
        if lx + tw + 30 > x1:
            lx = x0
            yy += 22
        d.rectangle((lx, yy + 3, lx + 14, yy + 15), fill=colour)
        d.text((lx + 20, yy), g, font=F(13), fill=TEXT)
        lx += 40 + tw
    im = im.crop((0, 0, W, yy + 30))
    save(im, out)


def passes_fig(c1, r1, out):
    a = json.load(open(c1))
    b = json.load(open(r1))
    im, d, y = canvas(640, 'Every pass of two stretches of stage 1, in frames',
                      'Each bar is one pass of MainLoop, from one fetch of its top to the next (tools/passes.py). '
                      'Red: PacePass\'s busy wait.\nLeft: c1 frames 16158-16658, room 8, no wait; one room change. '
                      'Right: rzx-r1 frames 3000-3030, room 0, a wait every pass.')
    top = 6.0
    ph = 380
    y0 = y + 20
    panels = [(70, 700, a, 'c1, 48K, room 8, 160 passes'), (750, W - 20, b, 'rzx-r1, 128K, room 0, 11 passes')]
    for x0, x1, doc, label in panels:
        ft = doc['summary']['frame_t']
        rows = doc['passes']
        py = lambda v: y0 + ph - v * ph / top  # noqa: E731
        for f in range(0, 7):
            d.line((x0, py(f), x1, py(f)), fill=(50, 50, 62))
            if x0 < 100:
                d.text((x0 - 40, py(f) - 8), '%d' % f, font=F(13), fill=DIM)
        bw = (x1 - x0) / len(rows)
        for i, r in enumerate(rows):
            fr = r['t'] / ft
            xa, xb = x0 + i * bw, x0 + (i + 1) * bw - (1 if bw > 3 else 0)
            d.rectangle((xa, py(min(fr, top)), max(xb, xa + 1), py(0)), fill=(90, 140, 220))
            if r['wait']:
                d.rectangle((xa, py(r['wait'] / ft), max(xb, xa + 1), py(0)), fill=(210, 80, 80))
            if fr > top:
                d.text((xa - 240, py(top) + 4), 'the room change: %.2f frames,' % fr, font=F(13), fill=HI)
                d.text((xa - 240, py(top) + 22), '%d interrupts taken' % r['ints'], font=F(13), fill=HI)
        s = doc['summary']
        d.text((x0, py(0) + 8), label, font=F(13), fill=TEXT)
        d.text((x0, py(0) + 28), 'median %.2f frames' % s['frames_median'], font=F(13), fill=DIM)
    d.text((16, y0 - 18), 'frames', font=F(13), fill=DIM)
    im = im.crop((0, 0, W, y0 + ph + 60))
    save(im, out)


if __name__ == '__main__':
    if sys.argv[1] == 'passes':
        passes_fig(*sys.argv[2:5])
    else:
        main(sys.argv[1])
