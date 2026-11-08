#!/usr/bin/env python3
"""The line drawing and the wireframes at run time (docs/runtime-analysis.md, section 5), from the access traces.

    python3 tools/fig_rt_lines.py

For every DrawLine `$B044` call of the traces below: its T (the instructions from the entry to the RET back, an
interrupt inside left out), the pixels it set in the back buffer `$C000-$CFFF` (a byte written with new bits: the
lines OR into the buffer ClearView emptied), whether ClipLine `$B18A` ran, and the 3D update it belongs to (the
ClearView `$8080` calls). Figures (docs/img/runtime/):

- lines-cost.png: T against pixels per call, the fit T = a + b x pixels, and the clipped calls apart;
- wire-cost.png: one update of three scenes, each line coloured by the T of its call;
- wire-slowmo.gif: the title's ship drawn line by line (one picture a DrawLine call), with the T counters.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import eprof  # noqa: E402
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402

DRAW_LINE, CLIP_LINE, CLEAR_VIEW = 0xB044, 0xB18A, 0x8080
SCENES = [('title', 'd1', '100:0-200:0'), ('station', 'f1', '1500:0-1600:0'), ('combat', 'w1', '3470:0-3620:0'),
          ('death', 'w1', '4280:0-4380:0')]


def buffer_xy(addr):
    """(x0, y) of a back buffer byte: laid out as the screen's top two thirds, $C000 for $4000"""
    a = addr - 0xC000
    y = ((a >> 5) & 0xC0) | ((a >> 8) & 7) | ((a >> 2) & 0x38)
    return (a & 31) * 8, y


def scan(trace):
    """the DrawLine calls and the ClearView starts: (calls, clears); a call is a dict"""
    ins = trace.instructions
    times = eprof.K.instruction_times(trace)
    mem = bytearray(trace.memory_at(0))
    calls, clears = [], []
    cur = None  # the open DrawLine call
    int_ret = None  # the return address of an interrupt being served
    for i, x in enumerate(ins):
        dt = (times[i + 1] - times[i]) if i + 1 < len(ins) else 4
        if x.interrupted and int_ret is None and i:
            w = [c for c in ins[i - 1].cycles if c.tag == 'W']
            if len(w) >= 2:
                int_ret = w[-2].value << 8 | w[-1].value
        if int_ret is not None and x.pc == int_ret and not x.interrupted:
            int_ret = None
        in_int = int_ret is not None
        if x.pc == CLEAR_VIEW and not in_int:
            clears.append(i)
        if x.pc == DRAW_LINE and cur is None and not in_int:
            ret = mem[x.sp] | mem[x.sp + 1] << 8
            cur = {'i': i, 't0': times[i], 't': 0, 'pixels': [], 'clip': False, 'ret': ret, 'sp': x.sp + 2}
        if cur is not None:
            if not in_int:
                cur['t'] += dt
                if x.pc == CLIP_LINE:
                    cur['clip'] = True
            if x.pc == cur['ret'] and x.sp == cur['sp'] and i > cur['i']:
                cur['t'] -= dt  # the caller's instruction
                cur['end'] = i
                calls.append(cur)
                cur = None
        for c in x.cycles:
            if c.tag == 'W':
                if cur is not None and not in_int and 0xC000 <= c.address < 0xD000:
                    new = c.value & ~mem[c.address] & 0xFF
                    if new:
                        x0, y = buffer_xy(c.address)
                        for b in range(8):
                            if new & (0x80 >> b):
                                cur['pixels'].append((x0 + b, y))
                mem[c.address] = c.value
    return calls, clears


def update_of(call, clears):
    k = 0
    for j, c in enumerate(clears):
        if c <= call['i']:
            k = j
    return k


def main():
    data = {}
    for key, rec, window in SCENES:
        t = eprof.load(S.work(rec), window)
        calls, clears = scan(t)
        data[key] = (t, calls, clears)
        print('%-8s %5d DrawLine calls, %d updates, %d clipped' % (key, len(calls), len(clears),
                                                                   sum(c['clip'] for c in calls)))

    # 1. T against pixels
    fig, axes = P.figure(13, 5, nrows=1, ncols=2)
    ax = axes[0]
    cols = P.colours([k for k, _r, _w in SCENES])
    allx, ally = [], []
    for key, _r, _w in SCENES:
        calls = data[key][1]
        xs = [len(c['pixels']) for c in calls if not c['clip']]
        ys = [c['t'] for c in calls if not c['clip']]
        ax.scatter(xs, ys, s=6, color=cols[key], label='%s (%d calls)' % (key, len(xs)), alpha=0.7)
        cx = [len(c['pixels']) for c in calls if c['clip']]
        cy = [c['t'] for c in calls if c['clip']]
        ax.scatter(cx, cy, s=14, color=cols[key], marker='x', alpha=0.9)
        allx += [v for v in xs if v]
        ally += [y for v, y in zip(xs, ys) if v]
    b, a = np.polyfit(allx, ally, 1)
    xx = np.array([0, max(allx)])
    ax.plot(xx, a + b * xx, color=P.WRITE, lw=1.2, label='fit: %.0f T + %.1f T a pixel' % (a, b))
    ax.set_xlabel('pixels the call set')
    ax.set_ylabel('T-states of the call (the interrupt left out)')
    ax.legend(fontsize=8)
    ax.grid(True, lw=0.4)
    ax.set_title('DrawLine: %.0f T to set up a line, %.1f T a pixel (x: a clipped line)' % (a, b), fontsize=10)
    ax = axes[1]
    for key, _r, _w in SCENES:
        calls = data[key][1]
        tpp = [c['t'] / len(c['pixels']) for c in calls if len(c['pixels']) >= 2]
        ax.hist(tpp, bins=np.logspace(1, 4, 50), histtype='step', lw=1.5, color=cols[key],
                label='%s, median %.0f T a pixel' % (key, np.median(tpp)))
    ax.set_xscale('log')
    ax.set_xlabel('T a pixel of the line (log)')
    ax.set_ylabel('calls')
    ax.legend(fontsize=8)
    ax.set_title('T a pixel: the short lines pay the set-up', fontsize=10)
    fig.suptitle('The line routine: about 1800 T a line before its first pixel, then about 87 T a pixel', fontsize=12)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/lines-cost.png')

    # 2. one update of three scenes, each line coloured by its T
    shown = [('title', 'the title ship'), ('combat', 'combat: the laser beams and the sight')]
    fig, axes = P.figure(12, 3.9, nrows=1, ncols=2)
    cmap = P.plt.get_cmap('plasma')
    norm = P.plt.matplotlib.colors.Normalize(1500, 9500)
    for ax, (key, label) in zip(axes, shown):
        t, calls, clears = data[key]
        per = {}
        for c in calls:
            per.setdefault(update_of(c, clears), []).append(c)
        if key == 'death':  # the update with the most lines that are not the laser's (those reach the bottom)
            u = max(per, key=lambda k: sum(1 for c in per[k] if all(y < 120 for _x, y in c['pixels'])) -
                    100 * sum(1 for c in per[k] if any(y >= 120 for _x, y in c['pixels'])))
        else:
            u = max(per, key=lambda k: sum(len(c['pixels']) for c in per[k]))
        img = np.zeros((128, 256, 3))
        img[:] = P.PANEL
        for c in per[u]:
            for x, y in c['pixels']:
                if 0 <= y < 128:
                    img[y, x] = cmap(norm(c['t']))[:3]
        ax.imshow(img, interpolation='nearest')
        ax.set_xticks([])
        ax.set_yticks([])
        tt = sum(c['t'] for c in per[u])
        px = sum(len(c['pixels']) for c in per[u])
        ax.set_title('%s\n%d lines, %d pixels, %d T in DrawLine' % (label, len(per[u]), px, tt), fontsize=9)
    sm = P.plt.cm.ScalarMappable(cmap=cmap, norm=norm)
    cb = fig.colorbar(sm, ax=axes, fraction=0.02, pad=0.01)
    cb.set_label('T of the line (DrawLine call)')
    fig.suptitle('One 3D update\'s lines, each coloured by the T of its DrawLine call: 1800 T before the first '
                 'pixel, so the ship\'s short edges cost nearly as much as the long ones', fontsize=11)
    P.save(fig, 'docs/img/runtime/wire-cost.png')

    # 3. the title ship line by line
    t, calls, clears = data['title']
    per = {}
    for c in calls:
        per.setdefault(update_of(c, clears), []).append(c)
    u = max(per, key=lambda k: len(per[k]))
    lines = per[u]
    scale = 3
    frames = []
    done = np.zeros((128, 256), dtype=np.uint8)
    t_sum = 0
    px_sum = 0
    t_start = lines[0]['t0']
    for n, c in enumerate(lines + [None]):
        im = Image.new('RGB', (256 * scale, 128 * scale + 44), tuple(int(v * 255) for v in P.BACKGROUND))
        arr = np.zeros((128, 256, 3), dtype=np.uint8)
        arr[:] = (24, 24, 32)
        arr[done == 1] = (80, 230, 110)
        if c is not None:
            for x, y in c['pixels']:
                if 0 <= y < 128:
                    arr[y, x] = (255, 230, 90)
        big = Image.fromarray(arr).resize((256 * scale, 128 * scale), Image.NEAREST)
        im.paste(big, (0, 44))
        d = ImageDraw.Draw(im)
        if c is not None:
            t_sum += c['t']
            px_sum += len(c['pixels'])
            d.text((8, 4), 'title ship, d1 update %d: line %d of %d, %d pixels, %d T%s' % (
                u, n + 1, len(lines), len(c['pixels']), c['t'], ' (clipped)' if c['clip'] else ''),
                fill=(210, 210, 220))
            d.text((8, 22), 'so far: %d pixels, %d T in DrawLine; %d T since the first line' % (
                px_sum, t_sum, c['t0'] + c['t'] - t_start), fill=(255, 230, 90))
            for x, y in c['pixels']:
                if 0 <= y < 128:
                    done[y, x] = 1
        else:
            d.text((8, 4), 'the update done: %d lines, %d pixels, %d T in DrawLine' % (len(lines), px_sum, t_sum),
                   fill=(210, 210, 220))
        frames.append(im)
    out = os.path.join(S.CASE, 'docs/img/runtime/wire-slowmo.gif')
    frames[0].save(out, save_all=True, append_images=frames[1:] + [frames[-1]] * 8, duration=180, loop=0)
    print('wrote docs/img/runtime/wire-slowmo.gif (%d pictures)' % len(frames))
    for key, _r, _w in SCENES:
        calls = data[key][1]
        tot = sum(c['t'] for c in calls)
        clip = sum(c['t'] for c in calls if c['clip'])
        print('%s: DrawLine %d T, clipped calls %d T (%.1f %%), pixels %d' % (
            key, tot, clip, 100 * clip / max(tot, 1), sum(len(c['pixels']) for c in calls)))


if __name__ == '__main__':
    main()
