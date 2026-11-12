#!/usr/bin/env python3
"""Doc 6 figures of Switchblade: the renderer replayed from an access trace, and static sheets from src/res.

Trace modes (the trace of a recording window, unreal-ng `analysis trace`, taken through --work W --window F:T-F:T
from the instance that holds the recording, or --trace FILE; the memory is the trace's start memory plus every
write, so the pictures show the real screen and buffers, not only what was written):

    python3 tools/fig_render.py compose --work W --window F:T-F:T --out docs/img/routines/ActorUpdate-compose.gif
        one actor's redraw: the chunk buffer (pages $5D-$66, lines $42-$81) decoded as 3-pixel units, beside the
        screen round the window, at each step of ActorUpdate $8E2B (back cells, actors, front cells, blit)
    python3 tools/fig_render.py stages --work W --window F:T-F:T --out docs/img/render/compose-stages.png
        the same as one still: the buffer after each step and the screen after the blit
    python3 tools/fig_render.py screen --work W --window F:T-F:T --out docs/img/play/NAME.gif [--step T]
        [--crop X,Y,W,H] [--title TEXT]: the real screen, a picture every --step T-states, the routine running

Static modes (no emulator):

    python3 tools/fig_render.py format --out docs/img/render/units.png      the 3-bit format on Hiro's first frame
    python3 tools/fig_render.py outline --out docs/img/render/outline.png   OutlineMask $6F00 at work
    python3 tools/fig_render.py sheets --out docs/img/render/sheets.png     every column picture set, labelled
    python3 tools/fig_render.py packer --out docs/img/render/packer.png     PackerPhases $FD98: entries, stops, masks
    python3 tools/fig_render.py layers --room 4 --out docs/img/render/layers-room4.png  the planes of one room
    python3 tools/fig_render.py surface --room 4 --out docs/img/render/surface.png  the ground with and without the 48K ROM
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

LISTING = os.path.join(CASE, 'build', 'game.lst')
BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
INK = (235, 235, 235)
GRID = (60, 60, 75)
STAGES = [(0x8E5B, 'ComposeActorCells (back): layers $68/$69'), (0x8E61, 'DrawActorsAll: every actor in the box'),
          (0x8E68, 'ComposeActorCells (front): layers $6A/$6B'), (0x8E6E, 'DrawFrontActors (+$02 bit 7)'),
          (0x8E71, 'BlitWindow: pack and copy to the screen'), (0x8E74, 'done')]


def chunk_picture(mem, scale=5, lines=(0x42, 0x82), pages=10):
    """The chunk buffer: page $5D + n is unit column n, byte $42 + y line y; the low 3 bits are the pixels"""
    lo, hi = lines
    im = Image.new('RGB', (pages * 3, hi - lo), (0, 0, 0))
    px = im.load()
    for n in range(pages):
        for y in range(lo, hi):
            v = mem[((0x5D + n) << 8) | y] & 7
            for b in range(3):
                if v & (4 >> b):
                    px[n * 3 + b, y - lo] = INK
    im = im.resize((im.size[0] * scale, im.size[1] * scale), Image.NEAREST)
    d = ImageDraw.Draw(im)
    for n in range(1, pages):
        d.line([(n * 3 * scale, 0), (n * 3 * scale, im.size[1])], fill=GRID)
    for y in range(0, hi - lo, 8):
        d.line([(0, y * scale), (im.size[0], y * scale)], fill=GRID)
    return im


def window_box(mem):
    """The window the render works on: units $732A-$732B, 8-pixel rows $732C-$732D (screen pixels)"""
    c0, c1, r0, r1 = mem[0x732A], mem[0x732B], mem[0x732C], mem[0x732D]
    return 8 + 3 * c0, 8 + 8 * r0, 3 * (c1 - c0 + 1), 8 * (r1 - r0 + 1)


def label_of(listing, pc):
    return listing.name(pc)


def load(args):
    return K.load_trace(args)


def text(d, xy, s, size=13, fill=TEXT):
    d.text(xy, s, font=K.font(size), fill=fill)


def compose_pictures(args, still=False):
    tr = load(args)
    lst = K.listing(LISTING)
    ins = tr.instructions
    marks = {}
    for i, x in enumerate(ins):
        for k, (pc, _) in enumerate(STAGES):
            if x.pc == pc and k not in marks and (k == 0 or 0 in marks):
                marks[k] = i
    if 0 not in marks or 5 not in marks:
        raise SystemExit('no ActorUpdate redraw in this window')
    first, last = marks[0], marks[5]
    box_mem = bytes(tr.memory_at(marks[4] + 1))
    bx, by, bw, bh = window_box(box_mem)
    cx, cy = max(0, bx - 12), max(0, by - 12)
    cw, ch = min(256 - cx, bw + 24), min(192 - cy, bh + 24)
    pictures, durations, stills = [], [], []
    step = max(1, (last - first) // args.pictures)
    points = sorted(set(list(range(first, last + 1, step)) + list(marks.values())))
    for i in points:
        mem = tr.memory_at(i)
        stage = max(k for k, v in marks.items() if v <= i)
        x = ins[min(i, len(ins) - 1)]
        if still:
            if i in marks.values():
                stills.append((stage, bytes(mem)))
            continue
        pic = Image.new('RGB', (args.width, 470), BG)
        d = ImageDraw.Draw(pic)
        text(d, (12, 8), args.title or 'ActorUpdate: one actor redrawn', 15)
        chunk = chunk_picture(mem, 5)
        pic.paste(chunk, (12, 60))
        text(d, (12, 40), 'chunk buffer: pages $5D-$66 (unit columns), lines $42-$81', 12, DIM)
        scr = K.render_screen(mem).crop((cx, cy, cx + cw, cy + ch))
        sc = max(1, min(4, 360 // max(cw, ch)))
        scr = scr.resize((cw * sc, ch * sc), Image.NEAREST)
        sx = 12 + chunk.size[0] + 30
        pic.paste(scr, (sx, 60))
        dd = ImageDraw.Draw(pic)
        dd.rectangle([sx + (bx - cx) * sc, 60 + (by - cy) * sc, sx + (bx - cx + bw) * sc - 1,
                      60 + (by - cy + bh) * sc - 1], outline=(255, 60, 60), width=2)
        text(d, (sx, 40), f'screen ({cx},{cy}) {cw} x {ch} px, the window boxed', 12, DIM)
        tx = sx + scr.size[0] + 30
        text(d, (tx, 60), f'frame {x.frame}  T {x.t // max(1, tr.units_per_t)}', 13)
        text(d, (tx, 82), label_of(lst, x.pc), 13, K.EXEC)
        for k, (_, name) in enumerate(STAGES[:5]):
            col = (255, 210, 70) if k == stage else (DIM if k > stage else TEXT)
            text(d, (tx, 120 + 22 * k), f'{k + 1}. {name}', 12, col)
        pictures.append(pic)
        durations.append(args.delay)
    if still:
        return stills, (cx, cy, cw, ch), (bx, by, bw, bh), tr
    durations[-1] = args.hold
    return pictures, durations


def cmd_compose(args):
    pictures, durations = compose_pictures(args)
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), 'pictures')


def cmd_stages(args):
    stills, (cx, cy, cw, ch), (bx, by, bw, bh), tr = compose_pictures(args, still=True)
    names = ['before', 'back cells', '+ actors', '+ front cells', 'front actors', 'blitted']
    keep = [s for s in stills if s[0] in (0, 1, 2, 3, 5)]
    chunks = [(names[k], chunk_picture(m, 5)) for k, m in keep]
    last_mem = keep[-1][1]
    scr = K.render_screen(last_mem).crop((cx, cy, cx + cw, cy + ch))
    sc = 4
    scr = scr.resize((cw * sc, ch * sc), Image.NEAREST)
    cwid = chunks[0][1].size[0]
    W = args.width
    H = 70 + max(chunks[0][1].size[1], scr.size[1]) + 120
    pic = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), args.title or 'The window composed in the chunk buffer, step by step, then blitted', 15)
    x = 12
    for i, (name, im) in enumerate(chunks[:4]):
        pic.paste(im, (x, 60))
        text(d, (x, 40), f'{i + 1}. {name.split(":")[0]}', 12)
        x += cwid + 24
    pic.paste(scr, (x, 60))
    d.rectangle([x + (bx - cx) * sc, 60 + (by - cy) * sc, x + (bx - cx + bw) * sc - 1,
                 60 + (by - cy + bh) * sc - 1], outline=(255, 60, 60), width=2)
    text(d, (x, 40), '5. screen, 4x', 12)
    y = 70 + max(chunks[0][1].size[1], scr.size[1])
    for i, line in enumerate(args.note or []):
        text(d, (12, y + 18 * i), line, 12, DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_screen(args):
    tr = load(args)
    lst = K.listing(LISTING)
    ins = tr.instructions
    times = K.instruction_times(tr)
    crop = [int(v) for v in args.crop.split(',')] if args.crop else [0, 0, 256, 192]
    cx, cy, cw, ch = crop
    sc = max(1, min(4, 740 // cw, 600 // ch))
    pictures, durations = [], []
    nxt = 0
    for i, x in enumerate(ins):
        if times[i] < nxt and i != len(ins) - 1:
            continue
        nxt = times[i] + args.step
        mem = tr.memory_at(i)
        pic = Image.new('RGB', (args.width, max(ch * sc + 70, 260)), BG)
        d = ImageDraw.Draw(pic)
        text(d, (12, 8), args.title or '', 14)
        scr = K.render_screen(mem).crop((cx, cy, cx + cw, cy + ch)).resize((cw * sc, ch * sc), Image.NEAREST)
        pic.paste(scr, (12, 40))
        tx = 12 + scr.size[0] + 20
        text(d, (tx, 40), f'frame {x.frame}', 13)
        text(d, (tx, 60), f'T {x.t // max(1, tr.units_per_t)}', 13)
        text(d, (tx, 86), lst.routine(x.pc), 13, K.EXEC)
        for k, (a, n) in enumerate(args.watch or []):
            text(d, (tx, 120 + 20 * k), f'{n} = ${mem[a]:02X}', 12, DIM)
        pictures.append(pic)
        durations.append(args.delay)
    durations[-1] = args.hold
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), 'pictures')


# ---------------------------------------------------------------------------------------------------------------
# static figures from src/res

def res_image():
    """The game's image as tools/build.sh assembles it from src/ (build/game.bin, $5C00-$FFFF): the pictures and the
    tables at their addresses (the cell colours of the image, not the run-time copy at $66F7)"""
    mem = bytearray(0x10000)
    data = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem[0x5C00:0x5C00 + len(data)] = data
    return mem


def unpack(data, groups):
    out = []
    for g in range(groups):
        b0, b1, b2 = data[3 * g:3 * g + 3]
        bits = b0 << 16 | b1 << 8 | b2
        out += [(bits >> (21 - 3 * k)) & 7 for k in range(8)]
    return out


def cmd_format(args):
    mem = res_image()
    base = 0xE97C + 48 * args.frame  # HiroFrames, frame n: 4 units x 32 rows, 48 bytes
    data = mem[base:base + 48]
    W = args.width
    pic = Image.new('RGB', (W, 640), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), 'The picture format: 3 bytes = 8 values of 3 bits = 8 lines of a 3-pixel unit column', 15)
    text(d, (12, 30), f'Hiro, frame {args.frame} (HiroFrames $E97C + 48 x {args.frame} = ${base:04X}): 4 unit columns x 32 lines, 12 bytes a column, column 0 first',
         12, DIM)
    # bits of the first group
    best = max(((c, gg) for c in range(4) for gg in range(4)),
               key=lambda cg: bin(int.from_bytes(data[12 * cg[0] + 3 * cg[1]:12 * cg[0] + 3 * cg[1] + 3], 'big')).count('1'))
    col0, grp = best
    off = 12 * col0 + 3 * grp
    g = data[off:off + 3]
    x0, y0 = 12, 70
    cell = 26
    bits = ''.join(f'{b:08b}' for b in g)
    cols = [(230, 90, 80), (90, 200, 120), (90, 150, 250), (240, 200, 70), (200, 110, 230), (70, 210, 220),
            (250, 150, 60), (160, 220, 80)]
    for i in range(3):
        text(d, (x0 + i * 8 * cell, y0 - 2), f'byte {i}: ${g[i]:02X}  (${base + off + i:04X})', 12)
    for k, ch in enumerate(bits):
        v = k // 3
        xx = x0 + k * cell
        d.rectangle([xx, y0 + 18, xx + cell - 2, y0 + 18 + cell], fill=cols[v])
        text(d, (xx + 8, y0 + 22), ch, 14, (0, 0, 0))
    for i in range(1, 3):
        d.line([(x0 + i * 8 * cell - 1, y0 + 14), (x0 + i * 8 * cell - 1, y0 + 18 + cell + 4)], fill=INK, width=2)
    vals = unpack(g, 1)
    y1 = y0 + 70
    for v in range(8):
        xx = x0 + v * 3 * cell
        d.rectangle([xx, y1, xx + 3 * cell - 4, y1 + 22], fill=cols[v])
        text(d, (xx + 6, y1 + 3), f'v{v} = {vals[v]:03b}', 12, (0, 0, 0))
    text(d, (x0, y1 + 30), 'value k = line k of the column; bit 2 = the left pixel, bit 0 = the right one', 12, DIM)
    # the 8 lines drawn
    y2 = y1 + 70
    px = 16
    for v in range(8):
        for b in range(3):
            on = vals[v] & (4 >> b)
            d.rectangle([x0 + b * px, y2 + v * px, x0 + (b + 1) * px - 2, y2 + (v + 1) * px - 2],
                        fill=INK if on else (40, 40, 50), outline=cols[v])
    text(d, (x0 + 3 * px + 10, y2), f'lines {8 * grp}-{8 * grp + 7} of unit column {col0}', 12, DIM)
    # whole frame: raw values
    y3 = y2 + 8 * px + 30
    allv = []
    for c in range(4):
        allv.append(unpack(data[12 * c:12 * c + 12], 4))
    s = 8
    fr = Image.new('RGB', (12, 32), (40, 40, 50))
    p = fr.load()
    for c in range(4):
        for y in range(32):
            for b in range(3):
                if allv[c][y] & (4 >> b):
                    p[c * 3 + b, y] = INK
    fr = fr.resize((12 * s, 32 * s), Image.NEAREST)
    pic.paste(fr, (x0, y3))
    dd = ImageDraw.Draw(pic)
    for c in range(1, 4):
        dd.line([(x0 + c * 3 * s, y3), (x0 + c * 3 * s, y3 + 32 * s)], fill=(240, 200, 70))
    dd.rectangle([x0 + 3 * s * col0, y3 + 8 * s * grp, x0 + 3 * s * (col0 + 1) - 1, y3 + 8 * s * (grp + 1) - 1], outline=(255, 80, 80), width=2)
    text(d, (x0 + 12 * s + 14, y3), 'the whole frame: 4 columns (yellow lines) of 32 lines', 12)
    text(d, (x0 + 12 * s + 14, y3 + 20), 'boxed: the 8 lines unpacked above', 12, DIM)
    hexes = ' '.join(f'{b:02X}' for b in data[12 * col0:12 * col0 + 12])
    text(d, (x0 + 12 * s + 14, y3 + 50), f'column {col0}, 12 bytes: {hexes}', 12)
    text(d, (x0 + 12 * s + 14, y3 + 70), 'the 4 groups give its 32 values (UnpackGroups $8BC8, B = 4)', 12, DIM)
    pic = pic.crop((0, 0, W, y3 + 32 * s + 12))
    pic.save(args.out)
    print(args.out, pic.size)


MASK = [0xFF, 0xFC, 0xF8, 0xF8, 0xF1, 0xF0, 0xF0, 0xF0]


def outlined(values_cols, rows):
    """MaskedColumn $8C0F over a black buffer: line k = buf AND M[v(k-1)] AND M[v(k)] AND M[v(k+1)] OR v(k)"""
    return values_cols  # over a cleared buffer the AND clears nothing: the outline shows only over a background


def draw_units(cols, rows, bg=None, scale=6, outline=False):
    """cols: list of value lists; bg: list of value lists for the buffer under them (or None: paper)"""
    n = len(cols)
    buf = [[(bg[c][y] if bg else 0) for y in range(rows)] for c in range(n)]
    if outline:
        for c in range(n):
            v = cols[c]
            for k in range(rows):
                m = 0xFF
                if k > 0:
                    m &= MASK[v[k - 1]]
                m &= MASK[v[k]]
                if k < rows - 1:
                    m &= MASK[v[k + 1]]
                buf[c][k] = (buf[c][k] & m) | v[k]
    else:
        for c in range(n):
            for k in range(rows):
                buf[c][k] |= cols[c][k]
    im = Image.new('RGB', (n * 3, rows), (0, 0, 0))
    p = im.load()
    for c in range(n):
        for y in range(rows):
            for b in range(3):
                if buf[c][y] & (4 >> b):
                    p[c * 3 + b, y] = INK
    return im.resize((n * 3 * scale, rows * scale), Image.NEAREST)


def frame_values(mem, base, units, rows, frame):
    size = units * rows * 3 // 8
    a = base + frame * size
    per = rows * 3 // 8
    return [unpack(mem[a + c * per:a + (c + 1) * per], rows // 8) for c in range(units)]


def cmd_outline(args):
    mem = res_image()
    hiro = frame_values(mem, 0xE97C, 4, 32, args.frame)
    tile = frame_values(mem, 0xD104, 4, 16, 0x33 - 1)  # the sky tile $33 of room 4 as the background
    bg = [tile[c % 4] + tile[c % 4] for c in range(4)]
    W = args.width
    s = 10
    pic = Image.new('RGB', (W, 500), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), 'OutlineMask $6F00: no stored mask, the outline is computed from the 3-bit values', 15)
    panels = [('1. values alone', draw_units(hiro, 32, None, s)),
              ('2. ORed on tile $33', draw_units(hiro, 32, bg, s)),
              ('3. MaskedColumn', draw_units(hiro, 32, bg, s, outline=True))]
    x = 12
    for name, im in panels:
        pic.paste(im, (x, 60))
        text(d, (x, 40), name, 12)
        x += im.size[0] + 40
    # mask table
    tx = x + 10
    text(d, (tx, 40), 'M[v]: the bits a value clears', 12)
    for v in range(8):
        y = 64 + v * 30
        for b in range(3):
            on = v & (4 >> b)
            d.rectangle([tx + b * 18, y, tx + b * 18 + 16, y + 16], fill=INK if on else (40, 40, 50))
        text(d, (tx + 62, y), f'{v}: ${MASK[v]:02X} = {MASK[v]:08b}', 12)
    text(d, (12, 390), 'Line k of a unit column: buffer AND M[v(k-1)] AND M[v(k)] AND M[v(k+1)] OR v(k).', 12)
    text(d, (12, 410), 'A lit pixel clears its own place and its neighbours inside the unit (bits 0-2; bit 3 of', 12)
    text(d, (12, 428), '$F1 lies outside the unit and is 0 in the buffer), one line above and below: a black rim', 12)
    text(d, (12, 446), 'separates the sprite from the wall. Units never clear their neighbours: no rim at unit sides.',
         12)
    pic.save(args.out)
    print(args.out, pic.size)


SETS = [('Tiles', 0xD104, 4, 16, 174, 'tiles.png'), ('EnemyFrames', 0xE154, 4, 16, 47, ''),
        ('GiantFrames', 0xE5BC, 8, 32, 10, ''), ('HiroFrames', 0xE97C, 4, 32, 51, ''),
        ('HiroFrames15', 0xF30C, 5, 32, 7, ''), ('HiroFrames18', 0xF4B0, 6, 32, 6, ''),
        ('HiroFrames21', 0xF660, 7, 32, 2, ''), ('SparkFrames', 0xF708, 2, 8, 22, ''),
        ('ShotFrames', 0xF78C, 3, 8, 10, ''), ('ScoreFrames', 0xF7E6, 5, 8, 10, ''),
        ('MessageFrames', 0xF87C, 9, 16, 4, ''), ('GremlinLogo', 0xF954, 11, 16, 1, '')]


def cmd_sheets(args):
    mem = res_image()
    W = args.width
    sc = 2
    rows_out = []
    for name, base, u, r, n, _ in SETS:
        if args.only and name not in args.only:
            continue
        ims = [draw_units(frame_values(mem, base, u, r, f), r, None, sc) for f in range(n)]
        rows_out.append((name, base, u, r, n, ims))
    # layout: wrap frames
    y = 40
    placed = []
    for name, base, u, r, n, ims in rows_out:
        size = u * r * 3 // 8
        head = f'{name} ${base:04X}-${base + n * size - 1:04X}: {n} frames of {u * 3} x {r} px ({size} bytes)'
        placed.append(('t', 12, y, head))
        y += 20
        x = 12
        hmax = 0
        for i, im in enumerate(ims):
            if x + im.size[0] > W - 12:
                x = 12
                y += hmax + 14
                hmax = 0
            placed.append(('i', x, y, im, i))
            x += im.size[0] + 6
            hmax = max(hmax, im.size[1])
        y += hmax + 22
    pic = Image.new('RGB', (W, y + 10), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), args.title or 'Every 3-bit column picture of the game, from src/res (frame n at base + n x size)',
         15)
    for p in placed:
        if p[0] == 't':
            text(d, (p[1], p[2]), p[3], 12, (240, 200, 70))
        else:
            _, x, yy, im, i = p
            d.rectangle([x - 1, yy - 1, x + im.size[0], yy + im.size[1]], outline=GRID)
            pic.paste(im, (x, yy))
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_packer(args):
    mem = res_image()
    # PackerPhases $FD98: 3-byte records (entry word, mask); records 0-7: the phases' entries + left masks;
    # PackRow reads the stop of record p + B + 7 (HL = $FD98 + 3p + 2 + $13 + 3B)
    W = args.width
    pic = Image.new('RGB', (W, 560), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), 'PackerPhases $FD98: where PackRow enters the unrolled packer and where it plants the RET', 15)
    lst = K.listing(LISTING)
    recs = []
    for i in range(31):
        a = 0xFD98 + 3 * i
        w = mem[a] | mem[a + 1] << 8
        recs.append((a, w, mem[a + 2]))
    y = 40
    text(d, (12, y), 'rec  addr   word   name                 mask      bits', 12, DIM)
    for i, (a, w, m) in enumerate(recs):
        yy = y + 18 + 15 * i
        text(d, (12, yy), f'{i:3}  ${a:04X}  ${w:04X}  {lst.name(w):20} ${m:02X}  {m:08b}', 11,
             (240, 200, 70) if i < 8 else TEXT)
    text(d, (560, 40), 'Records 0-7 (yellow): the packer entry and the LEFT mask for the', 12)
    text(d, (560, 58), 'phase p = the window\'s first unit AND 7 (its place in a 3-byte group).', 12)
    text(d, (560, 82), 'Record p + B + 7 (B = the window width in units): the address', 12)
    text(d, (560, 100), 'after the last unit\'s code, where PackRow writes RET ($C9),', 12)
    text(d, (560, 118), 'and the RIGHT mask (the screen bits after the window to keep).', 12)
    text(d, (560, 146), 'A mask keeps the screen bits OUTSIDE the window: BlitRows', 12)
    text(d, (560, 164), 'ANDs the first and last byte of a line with them, then ORs', 12)
    text(d, (560, 182), 'the packed byte. BlitColumn uses left OR right for one byte.', 12)
    pic = pic.crop((0, 0, W, y + 18 + 15 * 31 + 12))
    pic.save(args.out)
    print(args.out, pic.size)


def room_screen(mem, zones=0xFC):
    import swroom as SW
    pic, attrs = SW.render(mem, revealed=zones)
    bm, at = SW.to_screen(pic, attrs)
    im = Image.new('RGB', (256, 192))
    px = im.load()
    for y in range(192):
        for x in range(256):
            a = at[y // 8][x // 8]
            br = 8 if a & 0x40 else 0
            px[x, y] = SW.SPECTRUM[(a & 7) + br] if bm[y][x] else SW.SPECTRUM[((a >> 3) & 7) + br]
    return im


def built_room(room, rom=None):
    import fig_rooms as FR
    import res_formats as RF
    mem = FR.memory()
    rom = FR.rom48() if rom is None else rom
    grid = RF.map_grid(RF.load('rooms/map.bin'))
    b = FR.build(mem, rom, grid, room)
    return b.m


def cmd_layers(args):
    m = built_room(args.room)
    variants = []
    def only(keep, shade=True, colour=True):
        mm = bytearray(m)
        for p in (0x68, 0x69, 0x6A, 0x6B):
            if p not in keep:
                mm[p << 8:(p << 8) + 220] = bytes(220)
        if not shade:
            for c in range(220):
                mm[0x6C00 + c] &= 0xF0
        if not colour:
            for c in range(220):
                mm[0x6C00 + c] &= 0x0F
            mm[0x66F7] = 0x07
        return mm
    variants = [('1. back layer $68 (walls, back tiles)', only({0x68}, False, False)),
                ('2. + back layer $69', only({0x68, 0x69}, False, False)),
                ('3. + front layers $6A / $6B', only({0x68, 0x69, 0x6A, 0x6B}, False, False)),
                ('4. + the shade nibble of $6C', only({0x68, 0x69, 0x6A, 0x6B}, True, False)),
                ('5. + the colour nibble of $6C', bytearray(m))]
    sc = 1.5
    W = args.width
    tw, th = int(256 * sc), int(192 * sc)
    cols = 2
    pic = Image.new('RGB', (W, 50 + 3 * (th + 30)), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), args.title or f'Room {args.room} layer by layer: the cell planes $68-$6C drawn as RedrawCell does', 15)
    for i, (name, mm) in enumerate(variants):
        im = room_screen(mm).resize((tw, th), Image.NEAREST)
        x = 12 + (i % cols) * (tw + 30)
        y = 50 + (i // cols) * (th + 30)
        text(d, (x, y - 2), name, 12)
        pic.paste(im, (x, y + 16))
    # plane dump of one cell
    x = 12 + (tw + 30)
    y = 50 + 2 * (th + 30)
    cell = args.cell
    r, c = divmod(cell, 20)
    lines = [f'cell {cell} (row {r}, column {c}):'] + [f'  plane ${p:02X}: ${m[(p << 8) + cell]:02X}' for p in range(0x67, 0x6D)]
    for k, s in enumerate(lines):
        text(d, (x, y + 18 * k), s, 12, TEXT if k == 0 else DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_surface(args):
    import fig_rooms as FR
    from kitlib import unreal_root
    romdir = os.path.join(unreal_root(None), 'data', 'rom')
    roms = [('48.rom, the 48K BASIC ROM: what the game sees (ROM 1 is paged in on a 128K too)', FR.rom48()),
            ('128_low.rom, the 128K editor ROM (ROM 0): what the game would see with ROM 0 in', open(os.path.join(romdir, '128_low.rom'), 'rb').read())]
    W = args.width
    sc = 4
    crop = (8, 8 + 16 * 4, 248, 8 + 16 * 7)
    tw, th = (crop[2] - crop[0]) * sc, (crop[3] - crop[1]) * sc
    start = 257 - args.room
    block = th + 150
    pic = Image.new('RGB', (W, 60 + len(roms) * block + 70), BG)
    d = ImageDraw.Draw(pic)
    text(d, (12, 8), args.title or f'Room {args.room}: the ground and floor tiles are chosen by ROM bytes from ${start:04X} on', 15)
    text(d, (12, 30), 'Cell rows 4-6 of the play window, 4x. Row 5: tiles $3C-$3E, row 6: tiles $81-$83 (variant 1-3 = ROM byte AND 3, never twice running).', 12, DIM)
    variants = []
    for i, (name, rom) in enumerate(roms):
        m = built_room(args.room, rom)
        im = room_screen(m).crop(crop).resize((tw, th), Image.NEAREST)
        y = 60 + i * block
        text(d, (12, y), name, 12)
        pic.paste(im, (12, y + 18))
        g = [m[0x6800 + 100 + c] - 0x3B for c in range(20)]
        f = [m[0x6B00 + 120 + c] - 0x80 for c in range(20)]
        variants.append((g, f))
        yy = y + 18 + th + 6
        text(d, (12, yy), 'row 5 variants: ' + ' '.join(str(v) for v in g), 12)
        text(d, (12, yy + 18), 'row 6 variants: ' + ' '.join(str(v) for v in f), 12)
        raw = rom[start:start + 48]
        text(d, (12, yy + 40), f'ROM ${start:04X}: ' + ' '.join(f'{x:02X}' for x in raw[:24]), 12, DIM)
        text(d, (12, yy + 58), '           ' + ' '.join(f'{x:02X}' for x in raw[24:48]), 12, DIM)
        asc = ''.join(chr(x & 0x7F) if 32 <= (x & 0x7F) < 127 else '.' for x in raw)
        text(d, (12, yy + 78), 'as text (bit 7 cleared): ' + asc, 12, DIM)
    diff = sum(a != b for a, b in zip(variants[0][0] + variants[0][1], variants[1][0] + variants[1][1]))
    y = 60 + len(roms) * block
    text(d, (12, y), f'{diff} of the 40 cells differ. The bytes are not the room data: BC was overwritten (LD C,A after NEG), so the reads land in', 12)
    text(d, (12, y + 18), 'the ROM page at $0000: on the 48K ROM that is the keyword table. With ROM 0 or another ROM the ground changes.', 12)
    text(d, (12, y + 36), 'A ROM of zeros would hang: AND 3 gives 0, INC A gives 1 each time, and 1 = D loops for ever.', 12)
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_layout(args):
    """The play screen with the cell grid: 20 x 11 cells of 12 x 16 px from (8, 8), the 3-pixel units, the panel"""
    shot = Image.open(args.shot).convert('RGB')
    shot = shot.resize((256, 192), Image.NEAREST)
    sc = 3
    im = shot.resize((256 * sc, 192 * sc), Image.NEAREST)
    d = ImageDraw.Draw(im)
    for c in range(21):
        x = (8 + 12 * c) * sc
        d.line([(x, 8 * sc), (x, (8 + 176) * sc)], fill=(255, 60, 60), width=1)
    for r in range(12):
        y = (8 + 16 * r) * sc
        d.line([(8 * sc, y), ((8 + 240) * sc, y)], fill=(255, 60, 60), width=1)
    d.rectangle([0, 184 * sc, 256 * sc - 1, 192 * sc - 1], outline=(90, 160, 255), width=2)
    d.rectangle([0, 0, 256 * sc - 1, 8 * sc - 1], outline=(90, 160, 255), width=2)
    W = args.width
    pic = Image.new('RGB', (W, im.size[1] + 70), BG)
    pic.paste(im, (12, 44))
    dd = ImageDraw.Draw(pic)
    text(dd, (12, 8), args.title or 'The play screen: a window of 20 x 11 cells of 12 x 16 pixels at (8, 8), the panel on the top and bottom rows', 14)
    x = 12 + im.size[0] + 20
    lines = [('red grid: the cells', 'column c at x = 8 + 12c'), ('', 'row r at y = 8 + 16r'),
             ('', 'cell = 20r + c (0-219),'), ('', 'its index in planes $67-$6C'), ('', ''),
             ('blue: the panel', 'character row 0: score, lives'), ('', 'row 23: energy, EXTRA, weapon,'),
             ('', 'BONUS; attributes $FFCB'), ('', 'copied to $5AE0'), ('', ''),
             ('the unit', 'a cell is 4 units of 3 px'), ('', 'actor X counts 1.5 px'),
             ('', 'unit u at x = 8 + 3u'), ('', ''),
             ('colour', 'per cell, from CellColours'), ('', '$66F7, into the attributes'),
             ('', 'under it (8 x 8 each)'), ('', ''),
             ('shot', args.caption or '')]
    y = 50
    for head, body in lines:
        if head:
            text(dd, (x, y), head, 13, (255, 210, 70))
            y += 20
        if body:
            text(dd, (x, y), body, 12)
            y += 18
        elif not head:
            y += 8
    pic.save(args.out)
    print(args.out, pic.size)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('compose', 'stages', 'screen'):
        p = sub.add_parser(name)
        K.add_trace_args(p)
        p.add_argument('--out', required=True)
        p.add_argument('--title')
        p.add_argument('--width', type=int, default=1050)
        p.add_argument('--pictures', type=int, default=40)
        p.add_argument('--delay', type=int, default=120)
        p.add_argument('--hold', type=int, default=2500)
        p.add_argument('--step', type=int, default=20000)
        p.add_argument('--crop')
        p.add_argument('--note', action='append')
        p.add_argument('--watch', action='append', type=lambda s: (int(s.split('=')[0], 16), s.split('=')[1]))
    for name in ('format', 'outline', 'sheets', 'packer', 'layers', 'surface'):
        p = sub.add_parser(name)
        p.add_argument('--out', required=True)
        p.add_argument('--title')
        p.add_argument('--width', type=int, default=1050)
        p.add_argument('--frame', type=int, default=41)
        p.add_argument('--room', type=int, default=4)
        p.add_argument('--only', action='append')
        p.add_argument('--cell', type=int, default=110)
    p = sub.add_parser('layout')
    p.add_argument('--out', required=True)
    p.add_argument('--shot', required=True)
    p.add_argument('--title')
    p.add_argument('--caption')
    p.add_argument('--width', type=int, default=1050)
    args = ap.parse_args()
    {'layout': cmd_layout, 'compose': cmd_compose, 'stages': cmd_stages, 'screen': cmd_screen, 'format': cmd_format,
     'outline': cmd_outline, 'sheets': cmd_sheets, 'packer': cmd_packer, 'layers': cmd_layers,
     'surface': cmd_surface}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
