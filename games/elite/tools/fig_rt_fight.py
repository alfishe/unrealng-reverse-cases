#!/usr/bin/env python3
"""The fight as an animation with its cost beside it (docs/runtime-analysis.md, section 4).

    python3 tools/fig_rt_fight.py [--scene combat] [--step 1]

Each picture is one TV frame of the scene's trace: the screen as it stood at the frame's end (the trace's start
memory with every write applied, no emulator), and beside it the frame's 69888 T as a stacked bar by module (the
profile's frame_self), with the 3D update counter and the frame's heaviest routine. Output:
docs/img/runtime/<scene>-fight.gif.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import eprof  # noqa: E402
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402
import zxscreen  # noqa: E402

BAR_W, BAR_H = 90, 384


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scene', default='combat')
    ap.add_argument('--step', type=int, default=1)
    a = ap.parse_args()
    sc = S.scene(a.scene)
    p = S.profile(sc)
    t = eprof.load(S.work(sc[2]), sc[3])
    f0 = p['frames'][0]
    fs = p['frame_self']
    n = len(next(iter(fs.values())))
    mods = {}
    for k, row in fs.items():
        m = P.module(p['routines'][k]['module'])
        m = 'other' if m.startswith('data:') else m
        mods.setdefault(m, [0] * n)
        for i, v in enumerate(row):
            mods[m][i] += v
    order = sorted(mods, key=lambda m: -sum(mods[m]))
    cols = P.colours([m for m in order if m != 'halt'], {'halt': P.OTHER})
    rgb = {m: tuple(int(255 * c) for c in cols[m]) for m in order}
    updates = sorted(f0 + tt // S.FRAME_T for tt, _d in p['calls'].get('ClearView', []))

    # the screen at each frame's end
    mem = bytearray(t.memory_at(0))
    ends = {}
    ins = t.instructions
    cur = ins[0].frame
    for x in ins:
        if x.frame != cur:
            ends[cur] = bytes(mem[0x4000:0x5B00])
            cur = x.frame
        for c in x.cycles:
            if c.tag == 'W' and 0x4000 <= c.address < 0x5B00:
                mem[c.address] = c.value
    ends[cur] = bytes(mem[0x4000:0x5B00])

    pictures = []
    for i in range(0, n, a.step):
        f = f0 + i
        if f not in ends:
            continue
        scr = zxscreen.render(ends[f], scale=2)
        W = scr.width + BAR_W + 260
        H = max(scr.height, BAR_H) + 50
        im = Image.new('RGB', (W, H), (14, 14, 20))
        im.paste(scr, (0, 30))
        d = ImageDraw.Draw(im)
        upd = sum(1 for u in updates if u <= f)
        heavy = max(fs, key=lambda k: fs[k][i])
        d.text((6, 6), '%s, %s frame %d: 3D update %d; the heaviest routine %s (%d T)' % (
            sc[1], sc[2], f, upd, heavy, fs[heavy][i]), fill=(210, 210, 220))
        x0 = scr.width + 20
        y = 30 + BAR_H
        for m in order:
            h = round(mods[m][i] / S.FRAME_T * BAR_H)
            if h:
                d.rectangle([x0, y - h, x0 + BAR_W, y - 1], fill=rgb[m])
            y -= h
        d.rectangle([x0, 30, x0 + BAR_W, 30 + BAR_H], outline=(120, 120, 135))
        d.text((x0, 30 + BAR_H + 4), '69888 T', fill=(120, 120, 135))
        # the frame's split, the five biggest modules
        tops = sorted(order, key=lambda m: -mods[m][i])[:6]
        for k, m in enumerate(tops):
            d.rectangle([x0 + BAR_W + 12, 34 + 18 * k, x0 + BAR_W + 22, 44 + 18 * k], fill=rgb[m])
            d.text((x0 + BAR_W + 28, 32 + 18 * k), '%s %d %%' % (P.module_label(m, False), 100 * mods[m][i] / S.FRAME_T),
                   fill=(210, 210, 220))
        if f in updates:
            d.text((x0 + BAR_W + 12, 34 + 18 * 7), 'a new 3D update starts', fill=(80, 230, 110))
        pictures.append(im)
    out = os.path.join(S.CASE, 'docs', 'img', 'runtime', '%s-fight.gif' % a.scene)
    pictures[0].save(out, save_all=True, append_images=pictures[1:], duration=60, loop=0, optimize=True)
    print('wrote', os.path.relpath(out, S.CASE), '(%d pictures)' % len(pictures))


if __name__ == '__main__':
    main()
