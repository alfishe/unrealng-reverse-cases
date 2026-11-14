#!/usr/bin/env python3
"""The figures of doc 04 (the game loop): the interrupt windows and the lost interrupts of a stretch of play.

    python3 tools/fig_loop.py steps --work W --window F:T-F:T docs/img/loop/steps.png [--title T]
    python3 tools/fig_loop.py di --work W --window F:T-F:T docs/img/loop/di-windows.png [--title T]

steps: the same rows, coloured by the main loop's step that runs (tools/pass_steps.py's attribution: the routine the
main loop called last, the IM 2 handler apart), a white tick where a pass ends.

di: an access trace of the window (unreal-ng `analysis trace`, kept in W/traces/), one row a frame. Along each row
the frame's 70 908 T-states: red where the interrupts are off (from a DI, or the IM 2 handler's entry, to the next
EI), the INT's moment (frame T 1846) as a mark, green when the handler ran in that frame and red when the interrupt
was lost; the routine that ran the DI is named over its window; a white tick where a pass ends (the frame wait's exit
at `$7A5B`). The listing build/game.lst names the routines.
"""
import argparse
import os
import sys
from bisect import bisect_right

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 1050
FRAME_T, INT_T = 70908, 1846
HANDLER, PASS_END = 0xFEFE, 0x7A5B


def labels():
    out = []
    for line in open(os.path.join(CASE, 'build', 'game.lst')):
        m = K.LINE.match(line)
        if m:
            lm = K.LABEL.match(m.group(3))
            if lm:
                out.append((int(m.group(1), 16), lm.group(1)))
    out.sort()
    return [a for a, _ in out], [n for _, n in out]


def name_of(addrs, names, pc):
    i = bisect_right(addrs, pc) - 1
    return names[i] if i >= 0 else '$%04X' % pc


def fig_di(args):
    tr = K.load_trace(args)
    addrs, names = labels()
    units = max(1, tr.units_per_t)
    f0 = tr.instructions[0].frame
    f1 = tr.instructions[-1].frame
    frames = list(range(f0, f1 + 1))
    off = {f: [] for f in frames}       # (t0, t1, who)
    taken = set()
    ends = {f: [] for f in frames}
    di_since, who = None, None
    for x in tr.instructions:
        t = x.t // units
        op = None
        for c in x.cycles:
            if c.tag == 'F' or c.tag == 'M':
                op = c.value
                break
        if x.pc == HANDLER:
            taken.add(x.frame)
            if di_since is None:
                di_since, who = (x.frame, t), 'the IM 2 handler'
        if x.pc == PASS_END:
            ends[x.frame].append(t)
        if op == 0xF3 and di_since is None:
            di_since, who = (x.frame, t), name_of(addrs, names, x.pc)
        elif op == 0xFB and di_since is not None:
            (fa, ta) = di_since
            for f in range(fa, x.frame + 1):
                if f in off:
                    off[f].append((ta if f == fa else 0, t if f == x.frame else FRAME_T, who if f == fa else ''))
            di_since = None
    rh, top, x0 = 44, 96, 70
    span = W - x0 - 20
    H = top + len(frames) * rh + 120
    img = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f, fs = K.font(13), K.font(12)
    d.text((12, 10), args.title, font=K.font(17), fill=K.TEXT)
    d.text((12, 36), 'one row a frame of %d T; red: interrupts off; the triangle at T %d: the INT, green taken, red lost; '
           'white tick: a pass ends' % (FRAME_T, INT_T), font=fs, fill=K.DIM)
    for k in range(0, FRAME_T, 10000):
        xx = x0 + k * span // FRAME_T
        d.text((xx - 10, top - 22), str(k), font=fs, fill=K.DIM)
    lost = 0
    for i, fr in enumerate(frames):
        y = top + i * rh
        d.text((12, y + 10), str(fr), font=f, fill=K.TEXT)
        d.rectangle((x0, y + 8, x0 + span, y + 30), fill=K.PANEL)
        for ta, tb, w in off[fr]:
            xa, xb = x0 + ta * span // FRAME_T, x0 + tb * span // FRAME_T
            d.rectangle((xa, y + 8, max(xa + 1, xb), y + 30), fill=(200, 70, 60))
            if w and xb - xa > 60:
                d.text((xa + 3, y + 11), w, font=fs, fill=K.BACKGROUND)
        xi = x0 + INT_T * span // FRAME_T
        ok = fr in taken
        lost += not ok
        d.polygon([(xi - 6, y + 2), (xi + 6, y + 2), (xi, y + 9)], fill=(90, 220, 110) if ok else (240, 60, 60))
        for t in ends[fr]:
            xe = x0 + t * span // FRAME_T
            d.line((xe, y + 4, xe, y + 34), fill=(255, 255, 255), width=2)
    y = top + len(frames) * rh + 10
    d.text((12, y), '%d frames, %d interrupts taken, %d lost' % (len(frames), len(frames) - lost, lost), font=f,
           fill=K.TEXT)
    who = {}
    for fr in frames:
        for ta, tb, w in off[fr]:
            if w:
                who[w] = who.get(w, 0) + 1
    d.text((12, y + 24), 'windows opened by: ' + ', '.join('%s %d' % kv for kv in sorted(who.items(), key=lambda kv: -kv[1])),
           font=fs, fill=K.DIM)
    img.save(args.out)
    print(args.out, img.size, 'lost', lost, who)


STEP_COLOURS = [('interrupt', (240, 240, 240)), ('WaitFrames', (60, 66, 84)), ('DrawSprites', (230, 120, 60)),
                ('DrawChangedCells', (80, 160, 240)), ('UpdateObjects', (110, 200, 110)),
                ('ScanMapObjects', (200, 200, 80)), ('CheckSectionExit', (210, 90, 200)),
                ('ScrollDown', (90, 220, 220)), ('ScrollUp', (90, 220, 220)), ('LoseLife', (240, 70, 70))]


def fig_steps(args):
    sys.path.insert(0, HERE)
    import pass_steps as P
    tr = K.load_trace(args)
    addrs, names = P.labels()
    units = max(1, tr.units_per_t)
    ins = tr.instructions
    f0, f1 = ins[0].frame, ins[-1].frame
    frames = list(range(f0, f1 + 1))
    segs = {f: [] for f in frames}
    ends = {f: [] for f in frames}
    step, in_h, prev_in = 'loop', False, False
    for i, x in enumerate(ins[:-1]):
        if x.pc == P.HANDLER:
            in_h = True
        if x.pc == P.PASS_END and not in_h:
            ends[x.frame].append(x.t // units)
        if in_h:
            key = 'interrupt'
        else:
            inloop = P.LOOP_LO <= x.pc < P.LOOP_HI
            if inloop:
                step = 'loop'
            elif prev_in:
                j = bisect_right(addrs, x.pc) - 1
                step = names[j] if j >= 0 else '$%04X' % x.pc
            prev_in = inloop
            key = step
        if key == 'WaitFramesLoop':
            key = 'WaitFrames'
        nx = ins[i + 1]
        ta, tb = x.t // units, (nx.t // units if nx.frame == x.frame else FRAME_T)
        sg = segs[x.frame]
        if sg and sg[-1][2] == key and sg[-1][1] == ta:
            sg[-1][1] = tb
        else:
            sg.append([ta, tb, key])
        if in_h and x.pc == P.HANDLER_RET:
            in_h = False
    cmap = dict(STEP_COLOURS)
    rh, top, x0 = 30, 96, 70
    span = W - x0 - 20
    used = []
    for f in frames:
        for _, _, k in segs[f]:
            if k not in used:
                used.append(k)
    legend = [k for k, _ in STEP_COLOURS if k in used] + ['other'] * any(k not in cmap for k in used)
    H = top + len(frames) * rh + 40 + 22 * ((len(legend) + 3) // 4)
    img = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f, fs = K.font(13), K.font(12)
    d.text((12, 10), args.title, font=K.font(17), fill=K.TEXT)
    d.text((12, 36), 'one row a frame of %d T, coloured by the step of the main loop that runs; white tick: a pass ends '
           '(the frame wait returns)' % FRAME_T, font=fs, fill=K.DIM)
    for k in range(0, FRAME_T, 10000):
        xx = x0 + k * span // FRAME_T
        d.text((xx - 10, top - 22), str(k), font=fs, fill=K.DIM)
    for i, fr in enumerate(frames):
        y = top + i * rh
        d.text((12, y + 6), str(fr), font=f, fill=K.TEXT)
        for ta, tb, k in segs[fr]:
            xa, xb = x0 + ta * span // FRAME_T, x0 + tb * span // FRAME_T
            d.rectangle((xa, y + 4, max(xa, xb - 1), y + 24), fill=cmap.get(k, (150, 150, 150)))
        for t in ends[fr]:
            xe = x0 + t * span // FRAME_T
            d.line((xe, y, xe, y + 28), fill=(255, 255, 255), width=3)
    y = top + len(frames) * rh + 14
    for j, k in enumerate(legend):
        xx, yy = 12 + (j % 4) * 255, y + (j // 4) * 22
        d.rectangle((xx, yy + 2, xx + 14, yy + 16), fill=cmap.get(k, (150, 150, 150)))
        d.text((xx + 20, yy + 1), k if k != 'WaitFrames' else 'WaitFrames (idle)', font=f, fill=K.TEXT)
    img.save(args.out)
    print(args.out, img.size)


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('what')
    K.add_trace_args(p)
    p.add_argument('out')
    p.add_argument('--title', default='Interrupts off and lost interrupts')
    a = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    {'di': fig_di, 'steps': fig_steps}[a.what](a)
