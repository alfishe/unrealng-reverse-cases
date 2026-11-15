#!/usr/bin/env python3
"""Doc 04's figures: where each frame of a pass goes, from access traces of recording l2; the pass lengths.

    python3 tools/fig_loop.py frames OUT.png LABEL=TRACE.uatr [LABEL=TRACE.uatr ...]
    python3 tools/fig_loop.py passes OUT.png work/stage1/pass-frames-l2.txt

frames: one row a frame (69 888 T, left to right), each instruction coloured by what it belongs to: the interrupt's
sound tasks (SoundTask1-3 and the tone and noise players, $F8E8-$FD9E), the interrupt's handler and star task
($8383, $BE23-$BF54), MainWait's idle loop ($868C-$8695), the level's own code ($C4AE-$F87B), else the game.ann
module of the PC. A white tick marks each entry of MainLoop $8649 (a pass starts). The traces are unreal-ng's
`analysis trace` of a window (kit/kitlib.load_trace); prints the T-states per frame and category.

passes: the histogram of the pass lengths of tools/pass_frames.py's output (the line "frames a pass: ...").
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

W = 1050
FIXED = [('interrupt: sound tasks', 0xF8E8, 0xFD9E, (240, 90, 80)),
         ('interrupt: handler, stars', 0xBE23, 0xBF54, (240, 200, 70)),
         ('interrupt: handler, stars', 0x8383, 0x8385, (240, 200, 70)),
         ('MainWait (idle)', 0x868C, 0x8695, (70, 70, 85)),
         ('level code', 0xC4AE, 0xF87B, (200, 110, 230)),
         ('PlaySound', 0xF87C, 0xF8E7, (250, 150, 120))]
MODULE_COLOURS = {'scroll': (90, 150, 250), 'sprites': (70, 210, 220), 'ship': (90, 200, 120),
                  'waves': (230, 140, 60), 'util': (180, 180, 120), 'main': (150, 150, 255), 'tail': (120, 220, 170),
                  'interrupt': (255, 230, 150), 'tapeload': (200, 60, 60), 'titlestate': (160, 120, 90),
                  'screen': (140, 100, 180), 'texts': (120, 120, 120), 'vars': (120, 120, 120),
                  'intro': (120, 120, 120), 'graphics': (120, 120, 120), 'levelspace': (120, 120, 120),
                  'sound': (240, 90, 80)}


def modules():
    """[(start, name)] of src/game/game.ann's modules"""
    out, cur = [], None
    for line in open(os.path.join(CASE, 'src', 'game', 'game.ann')):
        m = re.match(r'@module (\w+)', line)
        if m:
            cur = m.group(1)
            continue
        m = re.match(r'\$([0-9A-F]{4}) ', line)
        if m and cur:
            out.append((int(m.group(1), 16), cur))
            cur = None
    return sorted(out)


MODS = modules()


def category(pc):
    for name, lo, hi, col in FIXED:
        if lo <= pc <= hi:
            return name, col
    if pc < 0x4000:
        return 'ROM', (100, 100, 100)
    name = 'other'
    for start, mod in MODS:
        if pc >= start:
            name = mod
    return name, MODULE_COLOURS.get(name, (120, 120, 120))


def load(path):
    at = K.access_trace(None)
    return at.load(path)


def frames(out, specs):
    f_big, f = K.font(16), K.font(13)
    panels = []
    totals = {}
    for spec in specs:
        label, _, path = spec.partition('=')
        tr = load(path)
        ins = tr.instructions
        units = max(1, tr.units_per_t)
        rows = {}
        for i, x in enumerate(ins):
            t0 = x.t // units
            t1 = ins[i + 1].t // units + (ins[i + 1].frame - x.frame) * tr.frame_t if i + 1 < len(ins) else t0 + 4
            name, col = category(x.pc)
            rows.setdefault(x.frame, []).append((t0, max(t1, t0 + 1), name, col, x.pc == 0x8649))
            tot = totals.setdefault((label, x.frame), {})
            tot[name] = tot.get(name, 0) + (t1 - t0)
        panels.append((label, tr.frame_t, rows))
    row_h, gap = 22, 6
    x0, x1 = 70, W - 20
    h = 70 + sum(30 + len(r) * (row_h + gap) for _, _, r in panels) + 190
    im = Image.new('RGB', (W, h), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'Where each frame of a pass goes: a typical pass and the longest (recording l2)', fill=K.TEXT,
           font=f_big)
    d.text((14, 34), 'One row a frame, 69 888 T left to right; white ticks: MainLoop $8649 entered (a pass starts).',
           fill=K.DIM, font=f)
    y = 64
    used = {}
    for label, ft, rows in panels:
        d.text((14, y), label, fill=K.TEXT, font=f_big)
        y += 26
        for fr in sorted(rows):
            d.text((14, y + 4), str(fr), fill=K.DIM, font=f)
            d.rectangle((x0, y, x1, y + row_h), fill=K.PANEL)
            for t0, t1, name, col, start in rows[fr]:
                a = x0 + t0 * (x1 - x0) / ft
                b = x0 + min(t1, ft) * (x1 - x0) / ft
                d.rectangle((a, y, max(a, b - 0.01), y + row_h), fill=col)
                used[name] = col
            for t0, t1, name, col, start in rows[fr]:
                if start:
                    a = x0 + t0 * (x1 - x0) / ft
                    d.rectangle((a - 1, y - 3, a + 1, y + row_h + 3), fill=(255, 255, 255))
            y += row_h + gap
        y += 4
    for k in range(0, 70001, 10000):
        x = x0 + k * (x1 - x0) / 69888
        d.line((x, y, x, y + 4), fill=K.DIM)
        d.text((x - 14, y + 6), str(k), fill=K.DIM, font=f)
    d.text((x1 - 60, y + 22), 'frame T', fill=K.DIM, font=f)
    y += 46
    cx, cy = 14, y
    for name, col in sorted(used.items(), key=lambda t: t[0]):
        w = 26 + d.textlength(name, font=f) + 18
        if cx + w > W - 10:
            cx, cy = 14, cy + 22
        d.rectangle((cx, cy + 3, cx + 16, cy + 15), fill=col)
        d.text((cx + 22, cy), name, fill=K.TEXT, font=f)
        cx += w
    im = im.crop((0, 0, W, cy + 30))
    im.save(out)
    for (label, fr), tot in sorted(totals.items()):
        print(label, fr, ', '.join(f'{k} {v}' for k, v in sorted(tot.items(), key=lambda t: -t[1])))


def passes(out, path):
    text = open(path).read()
    m = re.search(r'frames a pass: (.*)', text)
    hist = {int(a): int(b) for a, b in re.findall(r'(\d+): (\d+)', m.group(1))}
    mean = re.search(r'mean ([\d.]+)', text).group(1)
    f_big, f = K.font(16), K.font(13)
    h = 400
    im = Image.new('RGB', (W, h), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), f'Frames a pass on level 2: {sum(hist.values())} passes, {mean} frames a pass on average',
           fill=K.TEXT, font=f_big)
    d.text((14, 34), 'l2 frames 3500-15 500, IntTicks $7A8A sampled at every frame start (tools/pass_frames.py). '
           'The loop waits for 3 at the least.', fill=K.DIM, font=f)
    x0, y0, y1 = 80, 70, h - 60
    top = max(hist.values())
    keys = list(range(2, 13))
    bw = (W - x0 - 30) / len(keys)
    for i, k in enumerate(keys):
        n = hist.get(k, 0)
        bh = (y1 - y0) * n / top
        x = x0 + i * bw
        d.rectangle((x + 6, y1 - bh, x + bw - 6, y1), fill=(90, 150, 250) if k < 10 else (240, 90, 80))
        d.text((x + bw / 2 - 12, y1 - bh - 18), str(n), fill=K.TEXT, font=f)
        d.text((x + bw / 2 - 6, y1 + 6), str(k), fill=K.TEXT, font=f)
    d.text((x0, y1 + 28), 'frames in the pass (red: 10 frames and more; the 12-frame pass is a noise burst in the interrupt)',
           fill=K.DIM, font=f)
    im.save(out)


if __name__ == '__main__':
    a = sys.argv[1:]
    if a and a[0] == 'frames':
        frames(a[1], a[2:])
    elif a and a[0] == 'passes':
        passes(a[1], a[2])
    else:
        print(__doc__)
