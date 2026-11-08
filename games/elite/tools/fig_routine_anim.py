#!/usr/bin/env python3
"""A routine at work from an access trace, laid out for a 900 px page (the case's version of kit/routine_anim.py,
whose three panels side by side come out 2566 px wide: a postage-stamp screen at 900 px).

    python3 tools/fig_routine_anim.py --trace T.uatr --listing build/game.lst --out docs/img/render/X.gif
           [--view buffer:C000:32x128:screen | screen] [--range A600-B4FF] [--pc A6DF-B4D5] [--pictures 90]
           [--title TEXT]

Each picture, 900 px wide: the view the routine draws at 2x (512 px wide) with the bytes written in the slice
flashing; to its right the moment, the routine running and the listing round the last instruction (the lines run in
the slice marked by how often); under the view the memory range at 256 bytes a row (executed green, read blue,
written yellow fading through red, as in the kit). Same trace reading and colours as kit/routine_anim.py.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import routine_anim as RA  # noqa: E402

W = 900
VIEW_W = 512
ROW = 17


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--listing')
    p.add_argument('--out', required=True)
    p.add_argument('--view', default='buffer:C000:32x128:screen')
    p.add_argument('--range', default='0000-FFFF')
    p.add_argument('--pictures', type=int, default=90)
    p.add_argument('--pc')
    p.add_argument('--title')
    p.add_argument('--delay', type=int, default=80)
    p.add_argument('--hold', type=int, default=1500)
    a = p.parse_args()
    trace = K.load_trace(a)
    lst = K.listing(a.listing)
    times = K.instruction_times(trace)
    total = times[-1] + 1
    step = max(1, -(-total // max(1, a.pictures)))
    lo, hi = K.hex_range(a.range)
    lo, hi = lo & 0xFF00, hi | 0xFF
    pc_lo, pc_hi = K.hex_range(a.pc) if a.pc else (0, 0xFFFF)
    view = RA.parse_view(a.view)
    title = a.title or lst.name(trace.instructions[0].pc)
    mem = bytearray(trace.memory)
    ages = RA.Ages()
    pictures = []
    index, slice_no, n = 0, 0, len(trace.instructions)
    while index < n:
        end = (slice_no + 1) * step
        run_here, other, last = {}, 0, trace.instructions[index]
        while index < n and times[index] < end:
            x = trace.instructions[index]
            if pc_lo <= x.pc <= pc_hi:
                run_here[x.pc] = run_here.get(x.pc, 0) + 1
                last = x
            else:
                other += 1
            for c in x.cycles:
                if c.tag == 'F':
                    ages.exec[c.address] = slice_no
                elif c.tag == 'R':
                    ages.read[c.address] = slice_no
                elif c.tag in 'WE':
                    mem[c.address] = c.value
                    ages.write[c.address] = slice_no
            index += 1
        pictures.append(picture(trace, lst, mem, ages, slice_no, view, lo, hi, last, run_here, other,
                                min(end, total), total, title))
        slice_no += 1
    K.save_gif(a.out, pictures, [a.delay] * (len(pictures) - 1) + [a.hold])
    print(f'{a.out}: {len(pictures)} pictures, {step} T each, {os.path.getsize(a.out) // 1024} KB')


def picture(trace, lst, mem, ages, now, view, lo, hi, last, run_here, other, t, total, title):
    f13, f14, f16 = K.font(13), K.font(14), K.font(17)
    v = RA.view_picture(view, mem, ages, now)
    v = v.resize((VIEW_W, v.height * VIEW_W // v.width), Image.NEAREST)
    g = RA.grid_picture(mem, ages, now, lo, hi)
    gh = max(24, min(96, g.height * 2))
    g = g.resize((VIEW_W, gh), Image.NEAREST)
    top = 34
    height = top + v.height + 22 + gh + 22 + 26
    im = Image.new('RGB', (W, height), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), title, fill=K.TEXT, font=f16)
    im.paste(v, (10, top))
    kind, base, w, h, _ = view
    d.text((10, top + v.height + 3), f'the screen ${base:04X}' if kind == 'screen' else
           f'the back buffer ${base:04X}, as the screen lays it out', fill=K.DIM, font=f13)
    gy = top + v.height + 22
    im.paste(g, (10, gy))
    d.text((10, gy + gh + 3), f'memory ${lo:04X}-${hi:04X}, 256 bytes a row', fill=K.DIM, font=f13)
    # the code
    x, y = 10 + VIEW_W + 16, top
    cw = W - x - 8
    frame_t = trace.frame_t or 69888
    absolute = trace.from_frame * frame_t + trace.from_t // max(1, trace.units_per_t) + t
    d.text((x, y), f'frame {absolute // frame_t}, T {absolute % frame_t}', fill=K.TEXT, font=f14)
    d.rectangle([x, y + 22, x + cw, y + 28], outline=K.DIM)
    d.rectangle([x, y + 22, x + int(cw * min(1.0, t / total)), y + 28], fill=K.DIM)
    d.text((x, y + 36), lst.name(last.pc), fill=K.EXEC, font=f16)
    runs = sum(run_here.values())
    d.text((x, y + 60), f'{runs} instructions here' + (f', {other} elsewhere' if other else ''), fill=K.DIM,
           font=f13)
    ly = y + 84
    rows = (height - 30 - ly) // ROW
    window = lst.window(last.pc, rows) or []
    peak = max(run_here.values()) if run_here else 1
    for i, (address, kind, text, current) in enumerate(window):
        ry = ly + i * ROW
        if current:
            d.rectangle([x - 2, ry - 1, x + cw, ry + ROW - 2], fill=(44, 44, 60))
        if kind == 'label':
            d.text((x + 10, ry), (text + ':')[:34], fill=(240, 200, 90), font=f13)
            continue
        count = run_here.get(address, 0)
        if count:
            level = 0.35 + 0.65 * count / peak
            d.rectangle([x, ry + 3, x + 5, ry + ROW - 4], fill=tuple(int(c * level) for c in K.EXEC))
        d.text((x + 10, ry), f'{address:04X}', fill=K.DIM, font=f13)
        d.text((x + 52, ry), ' '.join(text.split())[:30], fill=K.TEXT if count else (150, 150, 160), font=f13)
    lx, ly = 10, height - 22
    for colour, text in ((K.EXEC, 'executed'), (K.READ, 'read'), (K.WRITE_FADE[0], 'written now'),
                         (K.WRITE_FADE[4], 'written just before'), (K.WRITE_TRAIL, 'written earlier')):
        d.rectangle([lx, ly + 2, lx + 11, ly + 13], fill=colour)
        d.text((lx + 16, ly), text, fill=K.DIM, font=f13)
        lx += 30 + int(d.textlength(text, font=f13))
    return im


if __name__ == '__main__':
    sys.exit(main())
