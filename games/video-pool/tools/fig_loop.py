#!/usr/bin/env python3
"""Doc 04's figures: the scheduler's 25 task slots as the trace's memory holds them, and the length of every interrupt
of a window, stacked by task.

    python3 tools/fig_loop.py slots --trace A.uatr --at FRAME --trace B.uatr --at FRAME [--out docs/img/loop/slots.png]
    python3 tools/fig_loop.py irqs --trace A.uatr --name "..." [--trace B.uatr --name "..."] [--out ...]

slots: TaskSlots $91DF, 4 bytes a slot (the routine, the period, the countdown; high byte 0 = free), read with
access_trace's memory_at at the first instruction of frame FRAME; the names from build/game.lst.
irqs: one bar per interrupt from tools/task_costs.py --per-irq (its table parsed), the frame line 69 888 T, the
interrupts that never came (no entry in a frame) marked as lost.
"""
import argparse
import os
import re
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

WIDTH = 1050
FRAME_T = 69888
TASK_SLOTS = 0x91DF
LISTING = os.path.join(CASE, 'build', 'game.lst')
OUT = os.path.join(CASE, 'docs', 'img', 'loop')
TASK_COLOURS = {
    0x8506: (230, 170, 70), 0x934D: (120, 190, 120), 0x8546: (160, 120, 210), 0x85EB: (200, 160, 230),
    0x8106: (90, 140, 220), 0x96E6: (240, 230, 120), 0x970E: (180, 180, 180), 0x9CA7: (250, 130, 180),
    0x827E: (90, 200, 210), 0x86C1: (220, 90, 90), 0x8357: (150, 150, 110), 0x9CB7: (120, 120, 160),
}


def text(d, xy, s, size=13, fill=K.TEXT, anchor='la'):
    d.text(xy, s, font=K.font(size), fill=fill, anchor=anchor)


def names():
    lst = K.listing(LISTING)
    return lambda a: lst.name(a) or f'{a:04X}'


def slots_of(trace_path, frame):
    module = K.access_trace(None)
    tr = module.load(trace_path)
    index = next(i for i, x in enumerate(tr.instructions) if x.frame >= frame)
    mem = tr.memory_at(index)
    out = []
    for s in range(25):
        a = TASK_SLOTS + 4 * s
        routine = mem[a] | mem[a + 1] << 8
        out.append(None if mem[a + 1] == 0 else (routine, mem[a + 2], mem[a + 3]))
    return out


def cmd_slots(a):
    name = names()
    panels = [(t, int(f)) for t, f in zip(a.trace, a.at)]
    img = Image.new('RGB', (WIDTH, 120 + 330 * len(panels)), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    text(d, (20, 10), 'TaskSlots 91DF hex: the 25 slots of the IM 2 scheduler, as the memory holds them', 16)
    text(d, (20, 34), 'Each cell: the slot number, the routine, its period p (runs every p + 1 ticks) and its '
         'countdown now. Grey: free.', 13, K.DIM)
    cw, ch = 198, 58
    for pi, (path, frame) in enumerate(panels):
        sl = slots_of(path, frame)
        y0 = 70 + pi * 330
        used = sum(1 for s in sl if s)
        label = a.label[pi] if a.label and pi < len(a.label) else ''
        text(d, (20, y0), f'w1 frame {frame}{": " + label if label else ""}  ({used} slots used, '
             f'{25 - used} free; the scheduler walks them in order 0-24)', 14)
        for s, v in enumerate(sl):
            x = 20 + (s % 5) * (cw + 4)
            y = y0 + 24 + (s // 5) * (ch + 4)
            if v is None:
                d.rectangle([x, y, x + cw, y + ch], fill=(38, 38, 44), outline=(60, 60, 66))
                text(d, (x + 6, y + 4), f'{s}', 12, K.DIM)
                text(d, (x + cw / 2, y + ch / 2 + 4), 'free', 13, K.DIM, 'mm')
                continue
            routine, period, count = v
            col = TASK_COLOURS.get(routine, (150, 150, 150))
            d.rectangle([x, y, x + cw, y + ch], fill=(30, 30, 36), outline=col, width=2)
            d.rectangle([x, y, x + 8, y + ch], fill=col)
            text(d, (x + 14, y + 4), f'{s}  {routine:04X}', 12, K.DIM)
            text(d, (x + 14, y + 20), name(routine)[:22], 14)
            text(d, (x + 14, y + 39), f'period {period}, countdown {count}', 12, col)
    img.save(a.out)
    print(f'{a.out}: {img.width} x {img.height}')


def per_irq(path):
    out = subprocess.run([sys.executable, os.path.join(HERE, 'task_costs.py'), '--trace', path, '--per-irq'],
                         check=True, capture_output=True, text=True).stdout
    rows, head = [], None
    for line in out.splitlines():
        if line.startswith('frame   T irq'):
            head = line.split()[3:]
            continue
        if head is None:
            continue
        cols = line.split()
        if not cols or not re.match(r'^\d+\.\d$', cols[0]):
            if rows:
                break
            continue
        frame, total = float(cols[0]), int(cols[1])
        tasks = {}
        for h, v in zip(head, cols[2:]):
            if h.startswith('$'):
                tasks[int(h[1:], 16)] = int(v)
        rows.append((int(frame), total, tasks))
    return rows


def cmd_irqs(a):
    name = names()
    panels = [(t, n) for t, n in zip(a.trace, a.name)]
    ph = 330
    img = Image.new('RGB', (WIDTH, 90 + ph * len(panels) + 70), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    text(d, (20, 10), 'The length of each interrupt, stacked by task (w1, kit access traces, tools/task_costs.py)', 16)
    text(d, (20, 34), 'One bar a frame; dashed: one frame, 69 888 T. A red cross: no interrupt in that frame, it came '
         'while the last one ran (DI).', 13, K.DIM)
    seen = {}
    left, right = 90, WIDTH - 20
    top_t = 80000
    for pi, (path, title) in enumerate(panels):
        rows = per_irq(path)
        y0 = 70 + pi * ph
        base = y0 + ph - 40
        height = ph - 80
        text(d, (20, y0), title, 14)
        nframes = max(r[0] for r in rows) + 1
        bw = (right - left) / nframes
        sc = height / top_t

        def ty(t):
            return base - min(t, top_t) * sc
        for t in range(0, top_t + 1, 20000):
            d.line([left - 4, ty(t), right, ty(t)], fill=(45, 45, 52))
            text(d, (left - 8, ty(t)), f'{t // 1000}k T', 12, K.DIM, 'rm')
        present = {r[0] for r in rows}
        for frame, total, tasks in rows:
            x = left + frame * bw
            y = base
            for addr in sorted(tasks, key=lambda k: list(TASK_COLOURS).index(k) if k in TASK_COLOURS else 99):
                v = tasks[addr]
                if not v:
                    continue
                seen[addr] = True
                h = min(v, top_t) * sc
                y2 = max(y - h, ty(top_t))
                d.rectangle([x + 1, y2, x + bw - 2, y], fill=TASK_COLOURS.get(addr, (150, 150, 150)))
                y = y2
            if total > top_t:
                d.polygon([(x + 1, ty(top_t) - 2), (x + bw - 2, ty(top_t) - 2), (x + bw / 2, ty(top_t) - 12)],
                          fill=K.TEXT)
                text(d, (x + bw + 4, ty(top_t) + 4), f'{total:,} T = {total / FRAME_T:.2f} frames: the shot set-up '.replace(',', ' ')
                     + '(AimShot), off the scale', 12)
            if pi == 0 or frame % 5 == 0:
                if frame % 5 == 0:
                    text(d, (x + bw / 2, base + 4), str(frame), 11, K.DIM, 'ma')
        for frame in range(nframes):
            if frame not in present:
                x = left + frame * bw + bw / 2
                d.line([x - 4, base - 10, x + 4, base - 2], fill=(255, 80, 80), width=2)
                d.line([x - 4, base - 2, x + 4, base - 10], fill=(255, 80, 80), width=2)
        fy = ty(FRAME_T)
        for x in range(left, right, 10):
            d.line([x, fy, x + 5, fy], fill=K.TEXT)
        text(d, (right, fy - 3), 'one frame 69 888 T', 12, K.TEXT, 'rb')
        text(d, (20, base + 4), 'frame:', 12, K.DIM)
    y = 90 + ph * len(panels) - 20
    x = 20
    for addr in seen:
        label = f'{name(addr)}'
        w = d.textlength(label, font=K.font(12)) + 30
        if x + w > WIDTH - 20:
            x, y = 20, y + 20
        d.rectangle([x, y + 2, x + 14, y + 14], fill=TASK_COLOURS.get(addr, (150, 150, 150)))
        text(d, (x + 18, y), label, 12)
        x += w
    img = img.crop((0, 0, WIDTH, y + 26))
    img.save(a.out)
    print(f'{a.out}: {img.width} x {img.height}')


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('slots')
    s.add_argument('--trace', action='append', required=True)
    s.add_argument('--at', action='append', required=True)
    s.add_argument('--label', action='append')
    s.add_argument('--out', default=os.path.join(OUT, 'slots.png'))
    i = sub.add_parser('irqs')
    i.add_argument('--trace', action='append', required=True)
    i.add_argument('--name', action='append', required=True)
    i.add_argument('--out', default=os.path.join(OUT, 'irqs.png'))
    a = ap.parse_args()
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    {'slots': cmd_slots, 'irqs': cmd_irqs}[a.cmd](a)


if __name__ == '__main__':
    main()
