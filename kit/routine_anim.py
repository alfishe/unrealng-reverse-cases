#!/usr/bin/env python3
"""Animate a routine at work from an access trace (unreal-ng `analysis trace`): a GIF, one picture per slice of time.

Each picture has three panels:

  - the memory map: the address space as a grid of 256 bytes a row. A byte executed in this slice is green, read
    blue, written yellow, fading through red over the next slices; a byte touched earlier in the window keeps a dark
    trail of its colour, the rest is its value in grey. The routine's footprint builds up as it runs.
  - the view: what the routine draws, as it draws it. `screen` is the Spectrum screen (or `screen:C000` for a
    shadow screen), `buffer:ADDR:WxH` an off-screen bitmap of W bytes a row and H rows (`:columns` when it is stored
    column by column, H bytes a column; `:columns-up` the same with each column's first byte at the bottom; `:screen` a back buffer laid out
    like the screen's pixel lines), `none` leaves it out.
    Bytes written in the slice flash in the write colours.
  - the code: the listing round the instruction last executed, the lines run in the slice marked by how often, the
    registers, the moment and the routine's name.

    python3 routine_anim.py (--trace pass.uatr | --work W --window F:T-F:T)
           --listing build/game.lst --out docs/img/routines/DrawSprites.gif
           [--view screen | screen:C000 | buffer:8000:32x256[:columns|:columns-up|:screen] | none] [--range 4000-FFFF] [--pictures 90]
           [--step TSTATES] [--pc EAE3-EBFF[,EC40-EC9F] ...] [--title "DrawSprites $EAE3"] [--delay 80]
           [--unreal U]

--pc names the routine's code: instructions outside it (an interrupt, a callee you do not want to watch) still
change memory but are counted as "other" in the code panel. Several ranges (comma-separated, or --pc repeated)
take a routine together with the routines it calls elsewhere in memory. GUIDE.md 4.1 says where these figures go.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib as K  # noqa: E402

GRID_HEIGHT = 512
VIEW_HEIGHT = 512
CODE_WIDTH = 470
ROW = 15


def parse_view(text):
    if not text or text == 'none':
        return None
    kind, _, rest = text.partition(':')
    if kind == 'screen':
        return ('screen', K.hex_address(rest) if rest else 0x4000, 32, 192, 'rows')
    if kind == 'buffer':
        address, _, size = rest.partition(':')
        size, _, order = size.partition(':')
        width, _, height = size.lower().partition('x')
        return ('buffer', K.hex_address(address), int(width), int(height), order or 'rows')
    raise SystemExit(f'--view {text}: screen[:ADDR], buffer:ADDR:WxH[:rows|columns|columns-up|screen] or none')


class Ages:
    """The slice in which each byte was last executed, read and written (-1: never)"""

    def __init__(self):
        self.exec = [-1] * 0x10000
        self.read = [-1] * 0x10000
        self.write = [-1] * 0x10000


def grid_picture(mem, ages, now, lo, hi):
    fade = K.WRITE_FADE
    out = []
    for a in range(lo, hi + 1):
        w, x, r = ages.write[a], ages.exec[a], ages.read[a]
        if w >= 0 and now - w < len(fade):
            out.append(fade[now - w])
        elif x == now:
            out.append(K.EXEC)
        elif r == now:
            out.append(K.READ)
        elif x >= 0 and now - x < 3:
            out.append((50, 150, 75))
        elif r >= 0 and now - r < 3:
            out.append((50, 100, 170))
        elif w >= 0:
            out.append(K.WRITE_TRAIL)
        elif x >= 0:
            out.append(K.EXEC_TRAIL)
        elif r >= 0:
            out.append(K.READ_TRAIL)
        else:
            g = 18 + (mem[a] >> 5) * 4  # the value, coarse: 8 greys keep the GIF small
            out.append((g, g, g + 4))
    rows = (hi - lo + 1) // 256
    image = Image.new('RGB', (256, rows))
    image.putdata(out)
    return image


def view_picture(view, mem, ages, now):
    kind, base, width, height, order = view
    fade = K.WRITE_FADE
    if kind == 'screen':
        image = K.render_screen(mem, base)
        px = image.load()
        draw = ImageDraw.Draw(image)
        for a in range(base, base + 0x1800):
            w = ages.write[a]
            if w < 0 or now - w >= len(fade):
                continue
            colour = fade[now - w]
            dark = tuple(c // 4 for c in colour)
            y, x0, bits = K.screen_line(0x4000 + a - base), (a & 31) * 8, mem[a]
            for bit in range(8):
                px[x0 + bit, y] = colour if bits & (0x80 >> bit) else dark
        for a in range(base + 0x1800, base + 0x1B00):
            w = ages.write[a]
            if w >= 0 and now - w < len(fade):
                cell = a - base - 0x1800
                x, y = (cell & 31) * 8, (cell >> 5) * 8
                draw.rectangle([x, y, x + 7, y + 7], outline=fade[now - w])
        return image
    image = Image.new('RGB', (width * 8, height))
    px = image.load()
    for row, column, a in K.buffer_cells(base, width, height, order):
        bits, w = mem[a], ages.write[a]
        hot = fade[now - w] if w >= 0 and now - w < len(fade) else None
        on = hot or (205, 205, 205)
        off = tuple(c // 4 for c in hot) if hot else (28, 28, 34)
        for bit in range(8):
            px[column * 8 + bit, row] = on if bits & (0x80 >> bit) else off
    return image


def fit(image, height):
    scale = max(1, height // image.height)
    while image.width * scale > 2 * height and scale > 1:
        scale -= 1
    return image.resize((image.width * scale, image.height * scale), Image.NEAREST)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--listing')
    p.add_argument('--out', required=True)
    p.add_argument('--view', default='screen')
    p.add_argument('--range', default='0000-FFFF', help='the memory grid, whole 256-byte rows')
    p.add_argument('--pictures', type=int, default=90)
    p.add_argument('--step', type=int, help='T-states a picture (instead of --pictures)')
    p.add_argument('--pc', action='append',
                   help='the routine\'s code range LO-HI (several: comma-separated or repeated); the rest is '
                        '"other"')
    p.add_argument('--title')
    p.add_argument('--delay', type=int, default=80, help='ms a picture')
    p.add_argument('--hold', type=int, default=1500, help='ms on the last picture')
    args = p.parse_args()

    trace = K.load_trace(args)
    if not trace.instructions:
        raise SystemExit(f'{args.trace}: no instructions')
    lst = K.listing(args.listing)
    times = K.instruction_times(trace)
    total = times[-1] + 1
    step = args.step or max(1, -(-total // max(1, args.pictures)))
    lo, hi = K.hex_range(args.range)
    lo, hi = lo & 0xFF00, hi | 0xFF
    pc_ranges = [K.hex_range(r) for arg in args.pc for r in arg.split(',') if r.strip()] if args.pc \
        else [(0, 0xFFFF)]
    view = parse_view(args.view)
    small, normal = K.font(11), K.font(12)
    title = args.title or (lst.name(trace.instructions[0].pc) if args.listing else os.path.basename(args.trace or args.window))

    mem = bytearray(trace.memory)
    ages = Ages()
    pictures = []
    index, slice_no, n = 0, 0, len(trace.instructions)
    while index < n:
        end = (slice_no + 1) * step
        run_here = {}
        other = 0
        last = trace.instructions[index]
        while index < n and times[index] < end:
            x = trace.instructions[index]
            mine = any(lo_ <= x.pc <= hi_ for lo_, hi_ in pc_ranges)
            if mine:
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
        pictures.append(draw_picture(trace, lst, mem, ages, slice_no, view, lo, hi, last, run_here, other,
                                     min(end, total), total, title, small, normal))
        slice_no += 1

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    durations = [args.delay] * (len(pictures) - 1) + [args.hold]
    K.save_gif(args.out, pictures, durations)
    print(f'{args.out}: {len(pictures)} pictures, {step} T each, {n} instructions, '
          f'{os.path.getsize(args.out) // 1024} KB')


def draw_picture(trace, lst, mem, ages, now, view, lo, hi, last, run_here, other, t, total, title, small, normal):
    grid = fit(grid_picture(mem, ages, now, lo, hi), GRID_HEIGHT)
    panels = [grid]
    if view:
        panels.append(fit(view_picture(view, mem, ages, now), VIEW_HEIGHT))
    top, gap = 34, 12
    width = sum(i.width for i in panels) + gap * (len(panels) + 1) + CODE_WIDTH + gap
    height = top + max(GRID_HEIGHT, VIEW_HEIGHT) + 40
    image = Image.new('RGB', (width, height), K.BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.text((gap, 8), title, fill=K.TEXT, font=K.font(15))
    x = gap
    labels = [f'memory ${lo:04X}-${hi:04X}, 256 bytes a row']
    if view:
        kind, base, w, h, _ = view
        labels.append(f'screen ${base:04X}' if kind == 'screen' else f'buffer ${base:04X}, {w} x {h} bytes')
    for panel, label in zip(panels, labels):
        image.paste(panel, (x, top))
        draw.text((x, top + panel.height + 4), label, fill=K.DIM, font=small)
        x += panel.width + gap
    code_x = x
    draw_code(draw, code_x, top, lst, last, run_here, other, trace, t, total, small, normal)
    # the legend
    ly = height - 18
    lx = gap
    for colour, text in ((K.EXEC, 'executed'), (K.READ, 'read'), (K.WRITE_FADE[0], 'written'),
                         (K.WRITE_FADE[4], 'written before'), (K.WRITE_TRAIL, 'trail')):
        draw.rectangle([lx, ly + 2, lx + 10, ly + 12], fill=colour)
        draw.text((lx + 14, ly), text, fill=K.DIM, font=small)
        lx += 26 + int(draw.textlength(text, font=small))
    return image


def draw_code(draw, x, y, lst, last, run_here, other, trace, t, total, small, normal):
    frame_t = trace.frame_t or 69888
    absolute = trace.from_frame * frame_t + trace.from_t // max(1, trace.units_per_t) + t
    draw.text((x, y), f'frame {absolute // frame_t}  t {absolute % frame_t:5}', fill=K.TEXT, font=normal)
    bar_w = CODE_WIDTH - 10
    draw.rectangle([x, y + 18, x + bar_w, y + 24], outline=K.DIM)
    draw.rectangle([x, y + 18, x + int(bar_w * min(1.0, t / total)), y + 24], fill=K.DIM)
    draw.text((x, y + 30), lst.name(last.pc), fill=K.EXEC, font=normal)
    regs = (f'PC {last.pc:04X} SP {last.sp:04X} AF {last.af:04X} BC {last.bc:04X}\n'
            f'DE {last.de:04X} HL {last.hl:04X} IX {last.ix:04X} IY {last.iy:04X}')
    draw.multiline_text((x, y + 48), regs, fill=K.TEXT, font=small, spacing=3)
    runs = sum(run_here.values())
    draw.text((x, y + 82), f'{runs} instructions in this slice' + (f', {other} other' if other else ''),
              fill=K.DIM, font=small)
    top = y + 102
    rows = (GRID_HEIGHT - (top - y)) // ROW
    window = lst.window(last.pc, rows)
    if not window:
        draw.text((x, top), f'${last.pc:04X} (no listing line)', fill=K.DIM, font=small)
        return
    peak = max(run_here.values()) if run_here else 1
    for i, (address, kind, text, current) in enumerate(window):
        ry = top + i * ROW
        if current:
            draw.rectangle([x - 2, ry - 1, x + CODE_WIDTH - 8, ry + ROW - 2], fill=(44, 44, 60))
        if kind == 'label':
            draw.text((x + 40, ry), text + ':', fill=(240, 200, 90), font=small)
            continue
        count = run_here.get(address, 0)
        if count:
            level = 0.35 + 0.65 * count / peak
            draw.rectangle([x, ry + 2, x + 6, ry + ROW - 4], fill=tuple(int(c * level) for c in K.EXEC))
        draw.text((x + 10, ry), f'{address:04X}', fill=K.DIM, font=small)
        draw.text((x + 50, ry), text[:56], fill=K.TEXT if count else (150, 150, 160), font=small)


if __name__ == '__main__':
    sys.exit(main())
