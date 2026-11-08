#!/usr/bin/env python3
"""Which routine wrote each byte of the dashboard, laid out for a 900 px page (the case's version of
kit/writers_map.py, whose four panels side by side come out 2108 px wide: 4 px text at 900).

    python3 tools/fig_writers_dash.py --trace work/w1/traces/3490_0-3500_0.uatr --listing build/game.lst \
        --out docs/img/hud/writers-dashboard.png [--zoom 0,128,256,64] [--title TEXT]

Same reading as kit/writers_map.py --by routine: each screen byte coloured by the routine whose instruction wrote it
last in the window (set pixels in the colour, clear pixels in its dark shade), bytes nobody wrote grey. Layout: the
zoomed area plain and coloured at 3x one above the other, the whole screen plain and coloured at 1x under them, the
legend in two columns (a writer, its bytes and writes, its main instructions).
"""
import argparse
import os
import sys
from collections import Counter, defaultdict

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import writers_map as WM  # noqa: E402

W = 900


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--listing')
    p.add_argument('--out', required=True)
    p.add_argument('--zoom', default='0,128,256,64')
    p.add_argument('--title', default='')
    a = p.parse_args()
    trace = K.load_trace(a)
    lst = K.listing(a.listing)
    cells, vw, vh = WM.view_bytes(('screen', 0x4000, 32, 192, None))
    mem = bytearray(trace.memory)
    writer, writes, by_pc = {}, Counter(), defaultdict(Counter)
    for x in trace.instructions:
        key = lst.routine(x.pc)
        for c in x.cycles:
            if c.tag in 'WE':
                mem[c.address] = c.value
                if c.address in cells:
                    writer[c.address] = key
                    writes[key] += 1
                    by_pc[key][x.pc] += 1
    order = [k for k, _ in writes.most_common()]
    colour = {k: K.ROUTINE_COLOURS[i % len(K.ROUTINE_COLOURS)] for i, k in enumerate(order)}
    owned = Counter(writer.values())
    shown = K.render_screen(mem, 0x4000)
    coded = Image.new('RGB', (vw, vh))
    px = coded.load()
    d = ImageDraw.Draw(coded)
    for address, (kind, x0, y) in cells.items():
        if kind != 'bits':
            continue
        who = writer.get(address)
        on = colour[who] if who else WM.UNWRITTEN_ON
        off = tuple(v // 4 for v in on) if who else WM.UNWRITTEN_OFF
        for bit in range(8):
            px[x0 + bit, y] = on if mem[address] & (0x80 >> bit) else off
    for address, (kind, x0, y) in cells.items():
        if kind == 'attr' and address in writer:
            d.rectangle([x0, y, x0 + 7, y + 7], outline=colour[writer[address]])

    zx, zy, zw, zh = (int(v) for v in a.zoom.split(','))
    f = 3

    def zoom(src):
        return src.crop((zx, zy, zx + zw, zy + zh)).resize((zw * f, zh * f), Image.NEAREST)

    f13, f14, f17 = K.font(13), K.font(14), K.font(17)
    rows = -(-len(order[:20]) // 2)
    top, gap = 36, 22
    height = top + 2 * (zh * f + gap) + vh + gap + 26 + rows * 36 + 10
    im = Image.new('RGB', (W, height), K.BACKGROUND)
    dr = ImageDraw.Draw(im)
    dr.text((10, 9), a.title, fill=K.TEXT, font=f17)
    x0 = (W - zw * f) // 2
    y = top
    for pic, cap in ((zoom(shown), f'the dashboard (screen {zx},{zy} {zw}x{zh}) at 3x, as shown'),
                     (zoom(coded), 'the same bytes, each in the colour of the routine that wrote it last')):
        im.paste(pic, (x0, y))
        dr.text((x0, y + pic.height + 3), cap, fill=K.DIM, font=f13)
        y += pic.height + gap
    sx = (W - 2 * vw - 80) // 2
    for i, (pic, cap) in enumerate(((shown, 'the screen at the end'), (coded, 'the screen, by writer'))):
        X = sx + i * (vw + 80)
        im.paste(pic, (X, y))
        dr.rectangle([X + zx - 1, y + zy - 1, X + zx + zw, y + zy + zh], outline=(255, 255, 255))
        dr.text((X, y + vh + 3), cap, fill=K.DIM, font=f13)
    y += vh + gap
    dr.text((10, y), f'{len(writer)} of {len(cells)} screen bytes written, {sum(writes.values())} writes, by:', fill=K.TEXT, font=f14)
    y += 26
    for i, k in enumerate(order[:20]):
        X, Y = 10 + (i // rows) * 445, y + (i % rows) * 36
        dr.rectangle([X, Y + 3, X + 12, Y + 15], fill=colour[k])
        dr.text((X + 18, Y), f'{k}: {owned[k]} byte{"s" if owned[k] != 1 else ""}, {writes[k]} write{"s" if writes[k] != 1 else ""}', fill=K.TEXT, font=f14)
        pcs = ', '.join(f'${pc:04X} x{n}' for pc, n in by_pc[k].most_common(3))
        dr.text((X + 18, Y + 17), f'by {pcs}', fill=K.DIM, font=f13)
    im.save(a.out)
    print(f'{a.out}: {im.size}, {len(order)} writers')


if __name__ == '__main__':
    sys.exit(main())
