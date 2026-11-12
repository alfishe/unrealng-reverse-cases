#!/usr/bin/env python3
"""Animate a routine at work from an access trace (unreal-ng `analysis trace`): a GIF, one picture per slice of time.

Each picture has three panels:

  - the memory map: the address space as a grid of 256 bytes a row (a small range fewer, see below). A byte executed in this slice is green, read
    blue, written yellow, fading through red over the next slices; a byte touched earlier in the window keeps a dark
    trail of its colour, the rest is its value in grey. The routine's footprint builds up as it runs.
  - the view: what the routine draws, as it draws it. `screen` is the Spectrum screen (or `screen:C000` for a
    shadow screen), `buffer:ADDR:WxH` an off-screen bitmap of W bytes a row and H rows (`:columns` when it is stored
    column by column, H bytes a column; `:columns-up` the same with each column's first byte at the bottom; `:screen` a back buffer laid out
    like the screen's pixel lines; `:hex` a stack or a record as numbers, W bytes a line in hex; `:words` the same
    as 16-bit words, W / 2 a line, low byte first in memory), `none` leaves it out.
    Bytes written in the slice flash in the write colours; in `:hex` / `:words` a number written earlier in the
    window keeps a dim rose trail (one only read, a dim blue one), as in the memory map.
  - the code: the listing round the instruction last executed, the lines run in the slice marked by how often, the
    registers, the moment and the routine's name.

    python3 routine_anim.py (--trace pass.uatr | --work W --window F:T-F:T)
           --listing build/game.lst --out docs/img/routines/DrawSprites.gif
           [--view screen | screen:C000 | buffer:8000:32x256[:columns|:columns-up|:screen|:hex|:words] | none]
           [--range 4000-FFFF] [--pictures 90]
           [--step TSTATES] [--pc EAE3-EBFF[,EC40-EC9F] ...] [--title "DrawSprites $EAE3"] [--delay 80]
           [--layout compact|wide] [--width 1050] [--grid-height 512] [--row-bytes 256]
           [--page N=LISTING ...] [--page-name N=NAME ...] [--unreal U]

--layout compact (the default) draws the picture --width pixels wide (1050, the figure limit, readable at 900): the
memory map and the view one above the other on the left, each at the largest whole scale that fits, the code on the
right; a view wider than that column at 1 x (a hex view of 30 bytes a line) goes on a row of its own under both,
its numbers a point or two smaller if it is wider than the picture. --layout wide is the older picture, the three panels side by side at up to 4 x (up to 2566 px).

--listing may be given more than once: several listings of one flat image (a 48K boot's menu and its music part,
`--listing build/main.lst --listing build/music.lst`) are merged by address, each naming its own code (where two
give code at one address, the first wins). --page is for 128K pages, not for a second listing of a flat image.

--pc names the routine's code: instructions outside it (an interrupt, a callee you do not want to watch) still
change memory but are counted as "other" in the code panel. Several ranges (comma-separated, or --pc repeated)
take a routine together with the routines it calls elsewhere in memory. GUIDE.md 4.1 says where these figures go.

The memory map is 256 bytes a row at the largest whole scale; a range so small that this is less than 96 px tall
(a few pages: two rows of 2 px for `$5B00-$5CFF`) is wrapped at 128, 64, 32 or 16 bytes a row until it is, the
label says how many. --row-bytes fixes the count, --grid-height caps the map's height (512; the code panel beside
it is as tall).

128K pages: --page N=LISTING names the code at `$C000-$FFFF` that runs while RAM N is paged in from that page's
listing ("UpdateChannel (RAM 6)"), --page-name N=NAME gives the whole page one name; both for one page combine:
the listing names the code and shows its lines, NAME stands for "RAM N" ("UpdateChannel (the music player)");
--listing names the rest. The page is the trace's start page, then each `OUT` to `$7FFD`. With either option (or a
`--pc N:LO-HI`) a plain --pc range at `$C000-$FFFF` is RAM 0's and `N:LO-HI` is RAM N's: `--listing build/game.lst
--page 6=build/music.lst --pc 6:C000-CD60` follows a player in RAM 6, and the game's code at the same addresses
counts as "other", its listing shown from the game's.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib as K  # noqa: E402

GRID_HEIGHT = 512
GRID_MIN_HEIGHT = 96  # a smaller range is wrapped at fewer bytes a row until its map is at least this tall
VIEW_HEIGHT = 512
CODE_WIDTH = 470
UNDER_CODE_HEIGHT = 360
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
    raise SystemExit(f'--view {text}: screen[:ADDR], buffer:ADDR:WxH[:rows|columns|columns-up|screen|hex|words] '
                     'or none')


class Ages:
    """The slice in which each byte was last executed, read and written (-1: never)"""

    def __init__(self):
        self.exec = [-1] * 0x10000
        self.read = [-1] * 0x10000
        self.write = [-1] * 0x10000


def grid_rows(lo, hi, width, height, row_bytes=None, min_height=GRID_MIN_HEIGHT):
    """(bytes a row, scale) of the memory map lo..hi in width x height pixels: 256 bytes a row at the largest
    whole scale, or, while that is less than min_height tall, half as many bytes a row (down to 16) at twice the
    rows, so that a few pages are a readable block, not a strip two pixels high. row_bytes: given"""
    size = hi - lo + 1
    candidates = [row_bytes] if row_bytes else [256, 128, 64, 32, 16]
    for n in candidates:
        rows = -(-size // n)
        scale = max(1, min(width // n, height // rows))
        if rows * scale >= min_height:
            break
    return n, scale


def grid_picture(mem, ages, now, lo, hi, row_bytes=256):
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
    rows = -(-(hi - lo + 1) // row_bytes)
    out += [K.BACKGROUND] * (rows * row_bytes - len(out))
    image = Image.new('RGB', (row_bytes, rows))
    image.putdata(out)
    return image


def view_picture(view, mem, ages, now, size=11):
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
    if order in ('hex', 'words'):
        return numbers_picture(base, width, height, order == 'words', mem, ages, now, size)
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


# the hex view's trails: a number written (read) earlier in the window, after its fade
NUMBER_WRITE_TRAIL = (190, 120, 140)
NUMBER_READ_TRAIL = (120, 150, 200)


def numbers_picture(base, width, height, words, mem, ages, now, size=11):
    """A buffer as numbers: H lines of W bytes from base, each line headed by its address, in hex (two digits a
    byte, or four a word with words: the high byte first as written, the low byte first in memory). A byte written in
    the slice is drawn in the write colours, fading over the next slices, read in blue; after that a byte written
    earlier in the window keeps a dim rose trail, one only read a dim blue one (as the memory map's trails), the rest
    is grey. size: the font's"""
    font = K.font(size)
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    digit = max(1, int(probe.textlength('0', font=font)))
    step = 2 if words else 1
    cell = digit * (4 if words else 2) + digit  # the number and a gap
    head = digit * 6
    line_h = size + 3
    image = Image.new('RGB', (head + cell * (width // step) + 2, height * line_h + 2), (20, 20, 26))
    draw = ImageDraw.Draw(image)
    fade = K.WRITE_FADE
    for row in range(height):
        at = (base + row * width) & 0xFFFF
        y = 1 + row * line_h
        draw.text((1, y), f'{at:04X}', fill=K.DIM, font=font)
        for column in range(width // step):
            a = (at + column * step) & 0xFFFF
            cells = [a, (a + 1) & 0xFFFF] if words else [a]
            written = [now - ages.write[c] for c in cells if ages.write[c] >= 0 and now - ages.write[c] < len(fade)]
            if written:
                colour = fade[min(written)]
            elif any(ages.read[c] == now for c in cells):
                colour = K.READ
            elif any(ages.write[c] >= 0 for c in cells):
                colour = NUMBER_WRITE_TRAIL
            elif any(ages.read[c] >= 0 for c in cells):
                colour = NUMBER_READ_TRAIL
            else:
                colour = (170, 170, 178)
            text = f'{mem[cells[-1]]:02X}{mem[a]:02X}' if words else f'{mem[a]:02X}'
            draw.text((head + column * cell, y), text, fill=colour, font=font)
    return image


def fit_width(image, width, height):
    """image at the largest whole scale no wider than width and no taller than height (at least 1 x)"""
    scale = max(1, min(width // image.width, height // image.height))
    return image.resize((image.width * scale, image.height * scale), Image.NEAREST)


def fit(image, height):
    scale = max(1, height // image.height)
    while image.width * scale > 2 * height and scale > 1:
        scale -= 1
    return image.resize((image.width * scale, image.height * scale), Image.NEAREST)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    K.add_listing_arg(p)
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
    p.add_argument('--layout', choices=('compact', 'wide'), default='compact',
                   help='compact: the memory map above the view, the code beside them, --width wide; wide: the '
                        'three panels side by side (the older, wider picture)')
    p.add_argument('--width', type=int, default=1050, help='the compact picture\'s width in pixels')
    p.add_argument('--grid-height', type=int, default=GRID_HEIGHT,
                   help='the memory map\'s largest height in pixels (512); the code panel beside it follows')
    p.add_argument('--row-bytes', type=int, choices=(16, 32, 64, 128, 256),
                   help='bytes a row of the memory map (default 256, fewer for a small range: at least '
                        f'{GRID_MIN_HEIGHT} px tall)')
    K.add_page_args(p)
    args = p.parse_args()

    trace = K.load_trace(args)
    if not trace.instructions:
        raise SystemExit(f'{args.trace}: no instructions')
    lst = K.code_listing(args)
    paged = lst.paged or any(':' in v for v in args.pc or [])
    locs = K.code_locations(trace, paged)
    times = K.instruction_times(trace)
    total = times[-1] + 1
    step = args.step or max(1, -(-total // max(1, args.pictures)))
    lo, hi = K.hex_range(args.range)
    lo, hi = lo & 0xFF00, hi | 0xFF
    pc_ranges = K.code_ranges(args.pc)
    view = parse_view(args.view)
    small, normal = K.font(11), K.font(12)
    title = args.title or (lst.name(locs[0]) if args.listing else os.path.basename(args.trace or args.window))
    grid = (args.row_bytes, args.grid_height)

    mem = bytearray(trace.memory)
    ages = Ages()
    pictures = []
    index, slice_no, n = 0, 0, len(trace.instructions)
    while index < n:
        end = (slice_no + 1) * step
        run_here = {}
        other = 0
        last, last_loc = trace.instructions[index], locs[index]
        while index < n and times[index] < end:
            x, loc = trace.instructions[index], locs[index]
            mine = any(lo_ <= loc <= hi_ for lo_, hi_ in pc_ranges)
            if mine:
                run_here[loc] = run_here.get(loc, 0) + 1
                last, last_loc = x, loc
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
        draw = draw_picture if args.layout == 'wide' else draw_compact
        pictures.append(draw(trace, lst, mem, ages, slice_no, view, lo, hi, last, run_here, other,
                             min(end, total), total, title, small, normal, args.width, last_loc, grid))
        slice_no += 1

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if os.path.exists(args.out):
        print(f'note: {args.out} exists and is replaced (a second animation of one routine: NAME-what.gif)')
    durations = [args.delay] * (len(pictures) - 1) + [args.hold]
    K.save_gif(args.out, pictures, durations)
    print(f'{args.out}: {len(pictures)} pictures, {step} T each, {n} instructions, '
          f'{os.path.getsize(args.out) // 1024} KB')


def panel_labels(view, lo, hi, row_bytes=256):
    labels = [f'memory ${lo:04X}-${hi:04X}, {row_bytes} bytes a row']
    if view:
        kind, base, w, h, _ = view
        labels.append(f'screen ${base:04X}' if kind == 'screen' else f'buffer ${base:04X}, {w} x {h} bytes')
    return labels


def draw_legend(draw, gap, height, small):
    ly = height - 18
    lx = gap
    for colour, text in ((K.EXEC, 'executed'), (K.READ, 'read'), (K.WRITE_FADE[0], 'written'),
                         (K.WRITE_FADE[4], 'written before'), (K.WRITE_TRAIL, 'trail')):
        draw.rectangle([lx, ly + 2, lx + 10, ly + 12], fill=colour)
        draw.text((lx + 14, ly), text, fill=K.DIM, font=small)
        lx += 26 + int(draw.textlength(text, font=small))


def wrap(text, font, width):
    """text cut into lines no wider than width pixels, at spaces"""
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    lines, line = [], ''
    for word in text.split(' '):
        candidate = (line + ' ' + word) if line else word
        if line and probe.textlength(candidate, font=font) > width:
            lines.append(line)
            line = word
        else:
            line = candidate
    return lines + [line]


def draw_compact(trace, lst, mem, ages, now, view, lo, hi, last, run_here, other, t, total, title, small, normal,
                 width, loc=None, grid=(None, GRID_HEIGHT)):
    """the memory map and the view one above the other on the left, the code on the right: width pixels wide"""
    gap, label_h = 12, 22
    big = K.font(15)
    lines = wrap(title, big, width - 2 * gap)
    top = 34 + 19 * (len(lines) - 1)
    left = max(256, width - 3 * gap - CODE_WIDTH)
    row_bytes, grid_h = grid
    row_bytes, scale = grid_rows(lo, hi, left, grid_h, row_bytes, min(GRID_MIN_HEIGHT, grid_h))
    labels = panel_labels(view, lo, hi, row_bytes)
    picture = grid_picture(mem, ages, now, lo, hi, row_bytes)
    panels = [picture.resize((picture.width * scale, picture.height * scale), Image.NEAREST)]
    under = None  # a view wider than the left column at 1 x (a hex view of 30 bytes a line): a row under all
    if view:
        picture = view_picture(view, mem, ages, now)
        if picture.width <= left:
            panels.append(fit_width(picture, left, VIEW_HEIGHT))
        else:
            full = width - 2 * gap
            size = 11
            while picture.width > full and view[4] in ('hex', 'words') and size > 9:
                size -= 1  # the numbers a point smaller, down to 9 (still readable at 900 px)
                picture = view_picture(view, mem, ages, now, size)
            under = fit_width(picture, full, VIEW_HEIGHT)
    column = max(p.width for p in panels)
    code_w = max(CODE_WIDTH, width - 3 * gap - column)
    # with the view under them the code beside the map needs only some 17 lines
    body = max(UNDER_CODE_HEIGHT if under else min(GRID_HEIGHT, grid_h), sum(p.height + label_h for p in panels))
    extra = under.height + label_h if under else 0
    image = Image.new('RGB', (max(gap + column + gap + code_w + gap, gap + (under.width if under else 0) + gap),
                              top + body + extra + 40), K.BACKGROUND)
    draw = ImageDraw.Draw(image)
    for i, line in enumerate(lines):
        draw.text((gap, 8 + 19 * i), line, fill=K.TEXT, font=big)
    y = top
    for panel, label in zip(panels, labels):
        image.paste(panel, (gap, y))
        draw.text((gap, y + panel.height + 4), label, fill=K.DIM, font=small)
        y += panel.height + label_h
    if under:
        image.paste(under, (gap, top + body))
        draw.text((gap, top + body + under.height + 4), labels[1], fill=K.DIM, font=small)
    draw_code(draw, gap + column + gap, top, lst, last, run_here, other, trace, t, total, small, normal, code_w,
              body, loc)
    draw_legend(draw, gap, image.height, small)
    return image


def draw_picture(trace, lst, mem, ages, now, view, lo, hi, last, run_here, other, t, total, title, small, normal,
                 width=None, loc=None, grid=(None, GRID_HEIGHT)):
    """--layout wide: the memory map, the view and the code side by side"""
    row_bytes = grid[0] or 256
    panels = [fit(grid_picture(mem, ages, now, lo, hi, row_bytes), GRID_HEIGHT)]
    if view:
        panels.append(fit(view_picture(view, mem, ages, now), VIEW_HEIGHT))
    top, gap = 34, 12
    width = sum(i.width for i in panels) + gap * (len(panels) + 1) + CODE_WIDTH + gap
    height = top + max(GRID_HEIGHT, VIEW_HEIGHT) + 40
    image = Image.new('RGB', (width, height), K.BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.text((gap, 8), title, fill=K.TEXT, font=K.font(15))
    x = gap
    for panel, label in zip(panels, panel_labels(view, lo, hi, row_bytes)):
        image.paste(panel, (x, top))
        draw.text((x, top + panel.height + 4), label, fill=K.DIM, font=small)
        x += panel.width + gap
    code_x = x
    draw_code(draw, code_x, top, lst, last, run_here, other, trace, t, total, small, normal, loc=loc)
    draw_legend(draw, gap, height, small)
    return image


def draw_code(draw, x, y, lst, last, run_here, other, trace, t, total, small, normal, width=CODE_WIDTH,
              height=GRID_HEIGHT, loc=None):
    frame_t = trace.frame_t or 69888
    absolute = trace.from_frame * frame_t + trace.from_t // max(1, trace.units_per_t) + t
    draw.text((x, y), f'frame {absolute // frame_t}  t {absolute % frame_t:5}', fill=K.TEXT, font=normal)
    bar_w = width - 10
    draw.rectangle([x, y + 18, x + bar_w, y + 24], outline=K.DIM)
    draw.rectangle([x, y + 18, x + int(bar_w * min(1.0, t / total)), y + 24], fill=K.DIM)
    loc = last.pc if loc is None else loc  # the code location: the PC, with its RAM page in paged mode
    draw.text((x, y + 30), lst.name(loc), fill=K.EXEC, font=normal)
    regs = (f'PC {last.pc:04X} SP {last.sp:04X} AF {last.af:04X} BC {last.bc:04X}\n'
            f'DE {last.de:04X} HL {last.hl:04X} IX {last.ix:04X} IY {last.iy:04X}')
    draw.multiline_text((x, y + 48), regs, fill=K.TEXT, font=small, spacing=3)
    runs = sum(run_here.values())
    draw.text((x, y + 82), f'{runs} instructions in this slice' + (f', {other} other' if other else ''),
              fill=K.DIM, font=small)
    top = y + 102
    rows = (height - (top - y)) // ROW
    window = lst.window(loc, rows)
    if not window:
        draw.text((x, top), f'${last.pc:04X} (no listing line)', fill=K.DIM, font=small)
        return
    peak = max(run_here.values()) if run_here else 1
    for i, (address, kind, text, current) in enumerate(window):
        ry = top + i * ROW
        if current:
            draw.rectangle([x - 2, ry - 1, x + width - 8, ry + ROW - 2], fill=(44, 44, 60))
        if kind == 'label':
            draw.text((x + 40, ry), text + ':', fill=(240, 200, 90), font=small)
            continue
        count = run_here.get(address, 0)
        if count:
            level = 0.35 + 0.65 * count / peak
            draw.rectangle([x, ry + 2, x + 6, ry + ROW - 4], fill=tuple(int(c * level) for c in K.EXEC))
        draw.text((x + 10, ry), f'{address & 0xFFFF:04X}', fill=K.DIM, font=small)
        draw.text((x + 50, ry), text[:56 + (width - CODE_WIDTH) // 7], fill=K.TEXT if count else (150, 150, 160),
                  font=small)


if __name__ == '__main__':
    sys.exit(main())
