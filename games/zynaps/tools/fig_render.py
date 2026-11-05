#!/usr/bin/env python3
"""Doc 06 figures: the renderer's structures read from a recording.

    python3 tools/fig_render.py spans  --work work/zyA/r1 --frame 2400 --out docs/img/render/spans.png
    python3 tools/fig_render.py glyphs --work work/zyA/r1 --frame 2400 --row 16 --out docs/img/render/glyphs.png
    python3 tools/fig_render.py scroll --work work/zyA/r1 --from 2400 --to 2432 --out docs/img/render/scroll.gif
    python3 tools/fig_render.py paper  --work work/zyA/r1 --window 2024:0-2026:0 --zoom 22,9,10,6
           --out docs/img/render/paper.png

spans: the 18 row records (RowRecords $F12C + 32 row) and their span-node chains (NodePool $F800) at the end of a
frame, drawn as 32 columns a row (gap columns dark, a node's glyph run coloured by its handler SpanDraw1-4, the first
glyph's number in it), beside the playfield as the screen shows it.
glyphs: the glyph cache $C000-$DFFF at the end of a frame: the four shift pages ($C0 shift 0, $C8 2 px, $D8 4 px,
$D0 6 px; line k of glyph n at page + 256 k + n) as 32 x 8 glyph grids, and one row's first run enlarged in all four.
scroll: one picture a frame: the playfield's left 12 columns at 3x, ShiftPage $7F6A, PassPhase $7F65, PassCount
$7F62 and the map column ScrollColumn $801C.
paper: from an access trace of one pass: which StripDraw branch took each sprite cell (StripCellPlain $8621: an
empty cell coloured with the sprite colour; StripCellMask $8643: ANDed into scenery; StripCellSkip $863E: black
cell left alone), over a zoom of the screen (--zoom column,row,columns,rows).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zynlib as Z  # noqa: E402

K = Z.K
LISTING = os.path.join(HERE, '..', 'build', 'game.lst')
HANDLER_COLOURS = {'SpanDraw0': (90, 90, 100), 'SpanDraw1': (250, 150, 60), 'SpanDraw2': (200, 110, 230),
                   'SpanDraw3': (240, 200, 70), 'SpanDraw4': (230, 90, 80)}
WIDTH_OF = {'SpanDraw0': 0, 'SpanDraw1': 1, 'SpanDraw2': 2, 'SpanDraw3': 3, 'SpanDraw4': 4}
SENTINEL = 0x85E4


def memory(s, frame, ranges):
    m = bytearray(0x10000)
    for lo, n in ranges:
        m[lo:lo + n] = Z.read(s, frame, lo, n)
    return m


def chains(m, lst):
    """[(row, [(column, width, glyph, gap, handler, node)])] from the row records"""
    out = []
    for row in range(18):
        rec = 0xF12C + 32 * row
        a = m[rec + 6] | m[rec + 7] << 8
        column, nodes = 0, []
        for _ in range(16):
            if a == SENTINEL:
                break
            handler = lst.routine(m[a] | m[a + 1] << 8)
            glyph, gap = m[a + 2], m[a + 3]
            width = WIDTH_OF.get(handler, 0)
            start = column + gap if nodes else gap
            nodes.append((start, width, glyph, gap, handler, a))
            column = start + width - 1 if width else start
            a = m[a + 4] | m[a + 5] << 8
        out.append((row, nodes))
    return out


def spans(args):
    s = Z.session(args.work)
    lst = K.listing(LISTING)
    m = memory(s, args.frame, [(0x4000, 6912), (0x7F00, 0x200), (0xF100, 0x700), (0xF800, 0x300)])
    rows = chains(m, lst)
    f, fb, fs = K.font(12), K.font(15), K.font(10)
    cell, top, left = 13, 64, 34
    W = 900
    H = top + 18 * cell * 1 + 8 + 260
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), f'Each playfield row is a chain of span nodes: gap, run of 1-4 glyphs, next (r1 frame {args.frame})',
           fill=K.TEXT, font=fb)
    d.text((10, 30), 'left: the chains read from RowRecords $F12C and NodePool $F800; right: the same rows on the '
                     'screen (rows 1-18)', fill=K.DIM, font=f)
    screen = K.render_screen(m).crop((0, 8, 256, 152)).resize((256 * 13 // 8, 144 * 13 // 8), Image.NEAREST)
    sx = left + 32 * cell + 24
    for row, nodes in rows:
        y = top + row * cell
        d.text((6, y), f'{row:2d}', fill=K.DIM, font=fs)
        for c in range(32):
            d.rectangle((left + c * cell, y, left + (c + 1) * cell - 1, y + cell - 2), fill=(32, 32, 42))
        for start, width, glyph, gap, handler, node in nodes:
            colour = HANDLER_COLOURS.get(handler, (120, 120, 120))
            if width == 0:
                d.rectangle((left + start * cell, y, left + start * cell + 3, y + cell - 2), fill=colour)
                continue
            d.rectangle((left + start * cell, y, left + (start + width) * cell - 2, y + cell - 2), fill=colour)
            d.text((left + start * cell + 2, y), f'{glyph:02X}', fill=(10, 10, 10), font=fs)
        if not nodes:
            d.text((left + 4, y), 'empty: head = SentinelNode $85E4', fill=K.DIM, font=fs)
    im.paste(screen, (sx, top))
    for c in range(0, 33, 8):
        d.text((left + c * cell - 4, top - 14), f'{c}', fill=K.DIM, font=fs)
    y = top + 18 * cell + 10
    x = 10
    for name in ('SpanDraw1', 'SpanDraw2', 'SpanDraw3', 'SpanDraw4', 'SpanDraw0'):
        d.rectangle((x, y + 2, x + 14, y + 12), fill=HANDLER_COLOURS[name])
        label = f'{name}: {WIDTH_OF[name]} glyph' + ('s' if WIDTH_OF[name] != 1 else '') if WIDTH_OF[name] \
            else 'SpanDraw0: empty node'
        d.text((x + 20, y), label, fill=K.TEXT, font=f)
        x += 172
    # one row's chain as bytes
    row = args.row
    nodes = rows[row][1]
    rec = 0xF12C + 32 * row
    y += 26
    d.text((10, y), f'row {row}: record ${rec:04X} = ' + ' '.join(f'{b:02X}' for b in m[rec:rec + 8]) +
           ' ... (+0 map pointer, +2 attribute address, +4 screen address, +6 head node)', fill=K.TEXT, font=f)
    y += 18
    for i, (start, width, glyph, gap, handler, node) in enumerate(nodes[:9]):
        nxt = m[node + 4] | m[node + 5] << 8
        d.text((10, y + 16 * i), f'node ${node:04X}: {" ".join(f"{b:02X}" for b in m[node:node + 8])}  = '
               f'{handler}, glyph ${glyph:02X}, gap {gap} -> columns {start}-{start + max(width, 1) - 1}, next '
               f'${nxt:04X}' + (' (SentinelNode: RowEnd)' if nxt == SENTINEL else ''), fill=K.DIM, font=f)
    im = im.crop((0, 0, W, y + 16 * min(9, len(nodes)) + 10))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)
    for row, nodes in rows:
        print(row, [(st, w, f'{g:02X}', gp, h) for st, w, g, gp, h, _ in nodes])


def glyph_bits(m, page, n):
    return [m[(page + k) * 256 + n] for k in range(8)]


def glyphs(args):
    s = Z.session(args.work)
    lst = K.listing(LISTING)
    m = memory(s, args.frame, [(0x4000, 6912), (0x7F00, 0x200), (0xC000, 0x2000), (0xF100, 0x700),
                               (0xF800, 0x300)])
    f, fb, fs = K.font(12), K.font(15), K.font(10)
    pages = [(0xC0, 0), (0xC8, 2), (0xD8, 4), (0xD0, 6)]
    W, scale = 900, 2
    top = 72
    gw = 16 * 8 * scale
    im = Image.new('RGB', (W, 1200), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), f'The glyph cache keeps every scenery glyph four times, shifted 0, 2, 4, 6 px (r1 frame {args.frame})',
           fill=K.TEXT, font=fb)
    d.text((10, 30), 'line k of glyph n at page + 256 k + n; each copy holds the glyph joined to its left neighbour '
                     f'(BuildGlyph)', fill=K.DIM, font=f)
    d.text((10, 46), f'grids: 256 glyphs, 16 a row, glyph $00 top left; the page in yellow is ShiftPage $7F6A '
                     f'(${m[0x7F6A]:02X}) now', fill=K.DIM, font=f)
    for i, (page, shift) in enumerate(pages):
        x0, y0 = 10 + (i % 2) * (gw + 30), top + (i // 2) * (16 * 8 * scale + 40)
        g = Image.new('RGB', (gw, 16 * 8 * scale), (20, 20, 28))
        gp = g.load()
        for n in range(256):
            cx, cy = (n % 16) * 8, (n // 16) * 8
            for k, b in enumerate(glyph_bits(m, page, n)):
                for bit in range(8):
                    if b & (0x80 >> bit):
                        for dx in range(scale):
                            for dy in range(scale):
                                gp[(cx + bit) * scale + dx, (cy + k) * scale + dy] = (220, 220, 230)
        im.paste(g, (x0, y0 + 16))
        d.text((x0, y0), f'${page:02X}00-${page + 7:02X}FF: shift {shift} px',
               fill=(240, 200, 70) if page == m[0x7F6A] else K.TEXT, font=f)
    # one run enlarged
    rows = chains(m, lst)
    run = next((nd for nd in rows[args.row][1] if nd[1] >= 3), rows[args.row][1][0])
    start, width, glyph, gap, handler, node = run
    y0 = top + 2 * (16 * 8 * scale + 40) + 6
    d.text((10, y0), f'row {args.row}, node ${node:04X} ({handler}): glyphs ${glyph:02X}-${glyph + width - 1:02X} '
                     'side by side, in each shift page, 6x; the box marks the same glyph', fill=K.TEXT, font=f)
    z = 6
    for i, (page, shift) in enumerate(pages):
        x0 = 10 + i * (width * 8 * z + 18) if width * 8 * z * 4 + 54 < W else 10 + (i % 2) * 440
        yy = y0 + 22 + (0 if width * 8 * z * 4 + 54 < W else (i // 2) * (8 * z + 30))
        for j in range(width):
            for k, b in enumerate(glyph_bits(m, page, glyph + j)):
                for bit in range(8):
                    colour = (230, 230, 240) if b & (0x80 >> bit) else (34, 34, 44)
                    px, py = x0 + (j * 8 + bit) * z, yy + k * z
                    d.rectangle((px, py, px + z - 2, py + z - 2), fill=colour)
        d.rectangle((x0 + 8 * z - 1, yy - 1, x0 + 16 * z - 1, yy + 8 * z - 1), outline=(240, 200, 70), width=2)
        d.text((x0, yy + 8 * z + 4), f'${page:02X}: shift {shift}', fill=K.DIM, font=f)
        last = yy + 8 * z + 24
    im = im.crop((0, 0, W, last + 6))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size, 'run', run)


def scroll(args):
    s = Z.session(args.work)
    f, fb = K.font(12), K.font(15)
    pictures, durations = [], []
    names = {0xC0: 'shift 0', 0xC8: 'shift 2', 0xD8: 'shift 4', 0xD0: 'shift 6'}
    history = []
    for fr in range(args.start, args.end + 1):
        m = memory(s, fr, [(0x4000, 6912), (0x7F60, 0x10), (0x8010, 0x10)])
        shift = m[0x7F6A]
        history.append((fr, shift, m[0x7F65], m[0x7F62], m[0x801C]))
        im = Image.new('RGB', (900, 500), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        d.text((10, 8), 'The fine scroll: 2 px a phase through the four shift pages, a new column every 4 phases',
               fill=K.TEXT, font=fb)
        d.text((10, 30), f'r1 frame {fr}: ShiftPage $7F6A = ${shift:02X} ({names.get(shift, "?")}), PassPhase '
                         f'$7F65 = {m[0x7F65]}, PassCount $7F62 = {m[0x7F62]}, ScrollColumn $801C = ${m[0x801C]:02X}',
               fill=K.DIM, font=f)
        crop = K.render_screen(m).crop((0, 8, 96, 152)).resize((96 * 3, 144 * 3), Image.NEAREST)
        im.paste(crop, (10, 56))
        for c in range(13):
            d.line([(10 + c * 24, 56), (10 + c * 24, 56 + 432)], fill=(60, 60, 80))
        x = 330
        d.text((x, 56), 'frame  ShiftPage  phase  count  column', fill=K.TEXT, font=f)
        for i, (hf, hs, hp, hc, hcol) in enumerate(history[-22:]):
            colour = (240, 200, 70) if hf == fr else K.DIM
            d.text((x, 76 + 17 * i), f'{hf:5d}  ${hs:02X} {names.get(hs, "?"):8s} {hp:5d}  {hc:5d}  ${hcol:02X}',
                   fill=colour, font=f)
        d.text((x, 470), 'grey lines: character columns; the scenery moves left within them',
               fill=K.DIM, font=f)
        pictures.append(im)
        durations.append(400)
    durations[-1] = 2000
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures))
    for h in history:
        print(h)


def paper(args):
    lst = K.listing(LISTING)
    labels = {n: a for a, n in lst.labels}
    plain, skip, mask = labels['StripCellPlain'], labels['StripCellSkip'], labels['StripCellMask']
    trace = K.load_trace(args)
    mem = bytearray(trace.memory)
    kinds = {}           # attribute address -> kind (the last in the window)
    sprite_colour = {}
    for x in trace.instructions:
        if x.pc in (plain, skip, mask):
            hl = x.hl
            kinds[hl] = {plain: 'plain', skip: 'skip', mask: 'mask'}[x.pc]
            if x.pc == plain:
                sprite_colour[hl] = x.bc & 0xFF
        for c in x.cycles:
            if c.tag == 'W':
                mem[c.address] = c.value
    c0, r0, cw, rh = (int(v) for v in args.zoom.split(','))
    z = 6
    whole = K.render_screen(mem)
    crop = whole.crop((c0 * 8, r0 * 8, (c0 + cw) * 8, (r0 + rh) * 8)).resize((cw * 8 * z, rh * 8 * z), Image.NEAREST)
    W = 900
    f, fb = K.font(12), K.font(15)
    H = 64 + rh * 8 * z + 230
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'Sprites are drawn in paper colour: plain on an empty cell, ANDed into scenery, skipped on black',
           fill=K.TEXT, font=fb)
    d.text((10, 30), f'{args.window}: the cells StripDraw took in this pass, columns {c0}-{c0 + cw - 1}, rows '
                     f'{r0}-{r0 + rh - 1}, 6x', fill=K.DIM, font=f)
    im.paste(crop, (10, 56))
    colours = {'plain': (90, 150, 250), 'mask': (240, 200, 70), 'skip': (255, 70, 70)}
    counts = {'plain': 0, 'mask': 0, 'skip': 0}
    for a, kind in kinds.items():
        cell = a - 0x5800
        col, row = cell & 31, cell >> 5
        counts[kind] += 1
        if not (c0 <= col < c0 + cw and r0 <= row < r0 + rh):
            continue
        x, y = 10 + (col - c0) * 8 * z, 56 + (row - r0) * 8 * z
        d.rectangle((x, y, x + 8 * z - 1, y + 8 * z - 1), outline=colours[kind], width=3)
        label = kind[0].upper() + (f' ${sprite_colour[a]:02X}' if kind == 'plain' else '')
        d.text((x + 3, y + 2), label, fill=colours[kind], font=K.font(11))
    small = whole.resize((256, 192))
    sx = W - 256 - 10
    im.paste(small, (sx, 56))
    d.rectangle((sx + c0 * 8, 56 + r0 * 8, sx + (c0 + cw) * 8, 56 + (r0 + rh) * 8), outline=(240, 200, 70))
    d.text((sx, 56 + 196), 'the whole screen, the zoom boxed', fill=K.DIM, font=f)
    y = 56 + rh * 8 * z + 12
    lines = [
        ('plain', 'boxes: P = plain (with the colour C\' it set), M = masked, S = skipped'),
        ('plain', f'StripCellPlain ${plain:04X}: attribute & $3F = 0 (an empty cell): the cell gets the sprite colour '
                  f'C\' and the 8 lines'),
        ('plain', '   are written as they are; the sprite is stored complemented, so its shape shows in PAPER colour'),
        ('mask', f'StripCellMask ${mask:04X}: attribute & $3F >= 8: the 8 lines ANDed into the scenery: the sprite '
                 'clears scenery pixels'),
        ('mask', '   and shows through as the scenery cell\'s paper; the attribute stays the scenery\'s'),
        ('skip', f'StripCellSkip ${skip:04X}: attribute & $3F = 1-7 (paper black): nothing is written'),
    ]
    for i, (kind, text) in enumerate(lines):
        d.text((10, y + 17 * i), text, fill=colours[kind], font=f)
    d.text((10, y + 17 * len(lines) + 6), f'cells in the whole pass: {counts["plain"]} plain, {counts["mask"]} '
                                          f'masked, {counts["skip"]} skipped', fill=K.TEXT, font=f)
    im = im.crop((0, 0, W, y + 17 * len(lines) + 30))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size, counts)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['spans', 'glyphs', 'scroll', 'paper'])
    K.add_trace_args(p)
    p.add_argument('--frame', type=int, default=2400)
    p.add_argument('--row', type=int, default=16)
    p.add_argument('--from', dest='start', type=int)
    p.add_argument('--to', dest='end', type=int)
    p.add_argument('--zoom', default='22,9,10,6')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    {'spans': spans, 'glyphs': glyphs, 'scroll': scroll, 'paper': paper}[args.what](args)


if __name__ == '__main__':
    main()
