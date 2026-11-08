#!/usr/bin/env python3
"""The case's copy of kit/writers_map.py with the legend text at 14-15 px (11-12 in the kit), for a 900 px page.

Code vs screen: which routine (or instruction) wrote each byte of the screen or of a buffer, from an access trace.

Three panels side by side, in the view's own geometry:

  - the view at the trace's end, as the game shows it;
  - the writers: each byte coloured by the routine whose instruction wrote it last in the window (set pixels in
    the colour, clear pixels in its dark shade), bytes nobody wrote in dark grey;
  - with --sources, where the written values came from: for each writer, the memory its loop read since its
    previous write (the graphic, the mask, the font), merged into ranges and listed in the legend.

The legend gives each writer's bytes, writes, the instructions that did them (with --by pc each instruction is
its own colour) and the source ranges. --zoom X,Y,W,H (view pixels) adds an enlarged inset of both views with the
byte grid, for one sprite or one character.

    python3 writers_map.py (--trace pass.uatr | --work W --window F:T-F:T)
           --listing build/game.lst --out docs/img/writers-pass.png
           [--view screen | screen:C000 | buffer:8000:32x256[:columns|:columns-up|:screen]] [--by routine | pc] [--sources]
           [--zoom 96,64,48,32] [--title T] [--unreal U]

--sources is a heuristic: it takes the data reads of the writing routine since its previous write, outside the
stack and outside the written byte itself. It names a sprite's graphic and mask, not computed values.
"""
import argparse
import os
import sys
from collections import Counter, defaultdict

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
from routine_anim import parse_view  # noqa: E402

UNWRITTEN_ON, UNWRITTEN_OFF = (90, 90, 96), (26, 26, 32)


def view_bytes(view):
    """The view's bytes: address -> (x, y) of its first pixel; attributes -> ('attr', x, y)"""
    kind, base, width, height, order = view
    cells = {}
    if kind == 'screen':
        for a in range(0x1800):
            cells[(base + a) & 0xFFFF] = ('bits', (a & 31) * 8, K.screen_line(0x4000 + a))
        for a in range(0x300):
            cells[(base + 0x1800 + a) & 0xFFFF] = ('attr', (a & 31) * 8, (a >> 5) * 8)
        return cells, 256, 192
    for row, column, a in K.buffer_cells(base, width, height, order):
        cells[a] = ('bits', column * 8, row)
    return cells, width * 8, height


def ranges(addresses):
    out = []
    for a in sorted(addresses):
        if out and a <= out[-1][1] + 1:
            out[-1][1] = a
        else:
            out.append([a, a])
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--listing')
    p.add_argument('--out', required=True)
    p.add_argument('--view', default='screen')
    p.add_argument('--by', choices=['routine', 'pc'], default='routine')
    p.add_argument('--sources', action='store_true')
    p.add_argument('--zoom', help='X,Y,W,H in view pixels')
    p.add_argument('--title')
    p.add_argument('--scale', type=int, default=2)
    args = p.parse_args()

    trace = K.load_trace(args)
    lst = K.listing(args.listing)
    view = parse_view(args.view)
    if not view:
        raise SystemExit('--view none: nothing to map')
    cells, vw, vh = view_bytes(view)

    mem = bytearray(trace.memory)
    writer = {}                                  # address -> pc of its last write
    writes = Counter()                           # key -> writes into the view
    by_pc = defaultdict(Counter)                 # key -> pc -> writes
    pending = defaultdict(set)                   # key -> reads since its previous write
    sources = defaultdict(Counter)               # key -> source address -> uses
    for x in trace.instructions:
        key = lst.routine(x.pc) if args.by == 'routine' else lst.name(x.pc)
        for c in x.cycles:
            if c.tag == 'R':
                if abs(((c.address - x.sp) + 0x8000) % 0x10000 - 0x8000) > 32:
                    pending[key].add(c.address)
            elif c.tag in 'WE':
                mem[c.address] = c.value
                if c.address in cells:
                    writer[c.address] = (key, x.pc)
                    writes[key] += 1
                    by_pc[key][x.pc] += 1
                    if args.sources:
                        for s in pending[key]:
                            if s != c.address and s not in cells:
                                sources[key][s] += 1
                    pending[key].clear()

    order = [k for k, _ in writes.most_common()]
    colour = {k: K.ROUTINE_COLOURS[i % len(K.ROUTINE_COLOURS)] for i, k in enumerate(order)}
    owned = Counter(k for k, _ in writer.values())

    shown = K.render_screen(mem, view[1]) if view[0] == 'screen' else bitmap(mem, view)
    writers = Image.new('RGB', (vw, vh), (0, 0, 0))
    px = writers.load()
    draw_w = ImageDraw.Draw(writers)
    for address, (kind, x0, y) in cells.items():
        who = writer.get(address)
        if kind == 'bits':
            bits = mem[address]
            on = colour[who[0]] if who else UNWRITTEN_ON
            off = tuple(v // 4 for v in on) if who else UNWRITTEN_OFF
            for bit in range(8):
                px[x0 + bit, y] = on if bits & (0x80 >> bit) else off
    for address, (kind, x0, y) in cells.items():
        if kind == 'attr' and address in writer:
            draw_w.rectangle([x0, y, x0 + 7, y + 7], outline=colour[writer[address][0]])

    s = args.scale
    panels = [shown.resize((vw * s, vh * s), Image.NEAREST), writers.resize((vw * s, vh * s), Image.NEAREST)]
    captions = ['the view at the window\'s end', f'who wrote each byte (by {args.by})']
    zoom = None
    if args.zoom:
        zx, zy, zw, zh = (int(v) for v in args.zoom.split(','))
        factor = max(2, min(12, (vh * s) // max(1, zh)))
        zoom = (zx, zy, zw, zh, factor)
        for source in (shown, writers):
            inset = source.crop((zx, zy, zx + zw, zy + zh)).resize((zw * factor, zh * factor), Image.NEAREST)
            d = ImageDraw.Draw(inset)
            for gx in range(0, zw + 1, 8):
                d.line([(gx * factor, 0), (gx * factor, zh * factor)], fill=(70, 70, 80))
            for gy in range(0, zh + 1):
                if factor >= 6 or gy % 8 == 0:
                    d.line([(0, gy * factor), (zw * factor, gy * factor)], fill=(50, 50, 60))
            panels.append(inset)
        captions += [f'zoom {zx},{zy} {zw}x{zh}', 'zoom, writers']

    small, normal = K.font(14), K.font(15)
    gap, top = 12, 38
    legend_rows = len(order[:16]) * (3 if args.sources else 2) + 2
    legend_h = 21 * legend_rows
    width = sum(i.width for i in panels) + gap * (len(panels) + 1)
    height = top + max(i.height for i in panels) + 24 + legend_h
    image = Image.new('RGB', (max(width, 900), height), K.BACKGROUND)
    draw = ImageDraw.Draw(image)
    t0 = f'{trace.from_frame}:{trace.from_t // max(1, trace.units_per_t)}'
    t1 = f'{trace.to_frame}:{trace.to_t // max(1, trace.units_per_t)}'
    draw.text((gap, 8), args.title or f'Writers of ${view[1]:04X}, frames {t0} .. {t1}', fill=K.TEXT,
              font=K.font(18))
    x = gap
    for i, (panel, caption) in enumerate(zip(panels, captions)):
        image.paste(panel, (x, top))
        draw.text((x, top + panel.height + 5), caption, fill=K.DIM, font=small)
        if zoom and i < 2:
            zx, zy, zw, zh, _ = zoom
            draw.rectangle([x + zx * s, top + zy * s, x + (zx + zw) * s, top + (zy + zh) * s], outline=(255, 255, 255))
        x += panel.width + gap

    y = top + max(i.height for i in panels) + 24
    total = len(cells)
    draw.text((gap, y), f'{len(writer)} of {total} bytes written in the window; {sum(writes.values())} writes',
              fill=K.TEXT, font=normal)
    y += 23
    for k in order[:16]:
        draw.rectangle([gap, y + 3, gap + 13, y + 16], fill=colour[k])
        pcs = ', '.join(f'${pc:04X} x{n}' for pc, n in by_pc[k].most_common(4))
        draw.text((gap + 18, y), f'{k}: {owned[k]} bytes last, {writes[k]} writes', fill=K.TEXT, font=normal)
        y += 20
        draw.text((gap + 18, y), f'by {pcs}', fill=K.DIM, font=small)
        y += 20
        if args.sources:
            spans = ranges(sources[k])
            spans.sort(key=lambda r: -sum(sources[k][a] for a in range(r[0], r[1] + 1)))
            text = ', '.join(f'${lo:04X}-${hi:04X} ({lst.name(lo)})' if hi > lo else f'${lo:04X}'
                             for lo, hi in spans[:4]) or 'no data reads'
            draw.text((gap + 18, y), f'from {text}', fill=K.DIM, font=small)
            y += 20
    if len(order) > 16:
        draw.text((gap, y), f'and {len(order) - 16} more writers', fill=K.DIM, font=small)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    image.save(args.out)
    print(f'{args.out}: {len(writer)} bytes written by {len(order)} writers')
    for k in order[:16]:
        print(f'  {k}: {owned[k]} bytes, {writes[k]} writes')


def bitmap(mem, view):
    _, base, width, height, order = view
    image = Image.new('RGB', (width * 8, height))
    px = image.load()
    for row, column, a in K.buffer_cells(base, width, height, order):
        bits = mem[a]
        for bit in range(8):
            px[column * 8 + bit, row] = (205, 205, 205) if bits & (0x80 >> bit) else (28, 28, 34)
    return image


if __name__ == '__main__':
    sys.exit(main())
