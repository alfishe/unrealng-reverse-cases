#!/usr/bin/env python3
"""The figures of doc 6 (rendering).

    python3 tools/fig_render.py layout --work W --built F:T --shown F --out docs/img/render/layout.png
    python3 tools/fig_render.py rows --work W --frame F --frame G --out docs/img/render/rows.png
    python3 tools/fig_render.py edges --out docs/img/render/edges.png

layout: the back buffer as RowTable maps it (lines 40-63 linear from $EB00, lines 64-191 at the screen's address +
$A600) at the moment just before CopyBuffer (--built F:T), beside the screen after the copy (--shown, T 0), with the
address of each band. rows: for each --frame (memory at T 0), the screen's lines 64-191 beside the road's tables:
RoadLines ($5C00, the screen line of each of the 128 rows), BendRows ($5B80, the sideways shift of each row) and the
lines RowList ($5B00) draws. edges: the edge patterns, EdgePatterns ($7880) and EdgePatterns2 ($7A80): 15 width
classes, 8 shifts of 3 bytes each (build/game.bin). horizons: the three horizon pictures and StageTable ($9E67).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, os.path.join(CASE, 'tools'))
import kitlib as K  # noqa: E402
from fig_controls import Live, image, wrap, WIDTH  # noqa: E402

INK, PAPER = (230, 230, 235), (30, 30, 40)


def screen_line(n):
    return 0x4000 | ((n & 0xC0) << 5) | ((n & 7) << 8) | ((n & 0x38) << 2)


def buffer_line(n):
    """the back buffer's line n as SetRowTable(DE = $A600) maps it (n >= 40)"""
    return 0xEB00 + 32 * (n - 40) if n < 64 else screen_line(n) + 0xA600


def mono(mem, lines, address_of, ink=INK, paper=PAPER):
    pic = Image.new('RGB', (256, len(lines)), paper)
    px = pic.load()
    for y, n in enumerate(lines):
        a = address_of(n)
        for c in range(32):
            b = mem[a + c]
            for bit in range(8):
                if b & (0x80 >> bit):
                    px[c * 8 + bit, y] = ink
    return pic



def cmd_layout(args):
    live = Live(args.work)
    frame, t = (int(v) for v in args.built.split(':'))
    buf = bytearray(0x10000)
    r = live.session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                          'offset': 0xEB00, 'length': 0x1300}, ok=False)
    buf[0xEB00:0xFE00] = bytes.fromhex(r.structured['hex'])
    scr = bytearray(0x10000)
    scr[0x4000:0x5B00] = live.mem(args.shown, 0x4000, 0x1B00)
    f, fs, ft = K.font(13), K.font(12), K.font(16)
    pic = Image.new('RGB', (WIDTH, 560), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), f'The back buffer before the copy (c1 {frame}:{t}) and the screen after it (c1 {args.shown}, T 0)',
           fill=K.TEXT, font=ft)
    x1, x2, y0 = 130, 600, 60
    back = mono(buf, range(40, 192), buffer_line).resize((384, 228), Image.NEAREST)
    pic.paste(back, (x1, y0 + 60))
    d.rectangle([x1, y0, x1 + 384, y0 + 60], outline=K.DIM)
    d.text((x1 + 8, y0 + 20), 'lines 0-39: the HUD, always the screen', fill=K.DIM, font=fs)
    shown = K.render_screen(scr).resize((384, 288), Image.NEAREST)
    pic.paste(shown, (x2, y0))
    d.text((x1, y0 - 18), 'back buffer (RowTable with DE = $A600)', fill=K.TEXT, font=f)
    d.text((x2, y0 - 18), 'screen $4000 after CopyBuffer', fill=K.TEXT, font=f)
    # the bands, in screen pixels x 1.5
    bands = [(40, 64, '$EB00-$EDFF', 'lines 40-63', (240, 200, 70)),
             (64, 192, '$EE00-$FDFF', 'lines 64-191', (90, 150, 250))]
    for top, bottom, addr, text, col in bands:
        ya, yb = y0 + top * 1.5, y0 + bottom * 1.5
        d.rectangle([x1 - 12, ya, x1 - 6, yb - 1], fill=col)
        d.text((12, ya + (2 if top == 40 else 20)), addr, fill=col, font=fs)
        d.text((12, ya + (18 if top == 40 else 38)), text, fill=K.DIM, font=fs)
        d.rectangle([x2 + 386, ya, x2 + 392, yb - 1], fill=col)
        d.text((x2 + 398, ya + 2), '$4000+' if top == 40 else '$4800+', fill=col, font=fs)
    d.line([x1, y0 + 40 * 1.5, x2 + 384, y0 + 40 * 1.5], fill=(240, 200, 70))
    d.line([x1, y0 + 64 * 1.5, x2 + 384, y0 + 64 * 1.5], fill=(90, 150, 250))
    notes = [
        'Yellow: lines 40-63, linear, 32 bytes a line, copied line by line from the highest line drawn (CopyRows, A = '
        '1).',
        'Blue: lines 64-191 in the screen\'s own order + $A600, copied in one block of 4096 bytes $EE00 -> $4800 '
        '(CopyLower: CopyRows with A = $80, 32 LDI a turn).',
        'The buffer has no attributes: the colours are fixed per band (StartRace: rows 5-13 sky $68, rows 14-23 the '
        'stage\'s ground).',
        'The bike, the riders and the objects are ORed into the buffer over the road; DrawHorizon then clears it for '
        'the next pass.',
        'Lines 40-63 in screen order would be $4000+: they are kept linear so that a line\'s address is $EB00 + 32 x '
        '(n - 40).',
    ]
    y = 365
    for n in notes:
        y = wrap(d, n, 12, y, WIDTH - 24, fs, K.DIM) + 4
    pic = pic.crop((0, 0, WIDTH, y + 10))
    pic.save(args.out)
    print(args.out, pic.size)


def plot_axes(d, x0, y0, w, h, xmax, ymin, ymax, fs, xlabel, ylabel, yticks):
    d.rectangle([x0, y0, x0 + w, y0 + h], outline=K.DIM)
    for v in yticks:
        yy = y0 + (v - ymin) * h / (ymax - ymin)
        d.line([x0, yy, x0 + w, yy], fill=(40, 40, 52))
        d.text((x0 - 34, yy - 7), str(v), fill=K.DIM, font=fs)
    for v in range(0, xmax + 1, 32):
        xx = x0 + v * w / xmax
        d.line([xx, y0, xx, y0 + h], fill=(40, 40, 52))
        d.text((xx - 8, y0 + h + 4), str(v), fill=K.DIM, font=fs)
    d.text((x0 + w / 2 - 40, y0 + h + 20), xlabel, fill=K.TEXT, font=fs)
    d.text((x0, y0 - 18), ylabel, fill=K.TEXT, font=fs)


def cmd_rows(args):
    live = Live(args.work)
    f, fs, ft = K.font(13), K.font(12), K.font(16)
    block = 330
    pic = Image.new('RGB', (WIDTH, 40 + block * len(args.frame) + 56), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), 'The road\'s rows: RoadLines (row to screen line) for a crest, BendRows (row to shift) for a '
                    'bend', fill=K.TEXT, font=ft)
    for i, (frame, label) in enumerate(zip(args.frame, args.label)):
        y0 = 40 + i * block
        scr = bytearray(0x10000)
        scr[0x4000:0x5B00] = live.mem(frame, 0x4000, 0x1B00)
        lines = live.mem(frame, 0x5C00, 128)
        hills = live.mem(frame, 0x5B80, 128)
        rowlist = live.mem(frame, 0x5B00, 128)
        seg = live.mem(frame, 0x5E2D, 5)
        top = live.mem(frame, 0x9177, 1)[0]
        d.text((12, y0), f'c1 {frame} (T 0): {label}.   BendDir {seg[0]:02X}, BendPrev {seg[1]}, Bend {seg[2]}, '
                         f'CrestPrev {seg[3]}, Crest {seg[4]}, RoadTopRow ${top:02X}', fill=K.TEXT, font=f)
        shot = K.render_screen(scr).crop((0, 64, 256, 192)).resize((384, 192), Image.NEAREST)
        pic.paste(shot, (12, y0 + 24))
        d.text((12, y0 + 222), 'screen lines 64-191', fill=K.DIM, font=fs)
        # RoadLines: row (x) against line (y, top down as on the screen)
        x0, w, h = 470, 250, 240
        py = y0 + 46
        plot_axes(d, x0, py, w, h, 128, 0x70, 0xC0, fs, 'road row (0 near ... 127 far)', 'RoadLines: screen line',
                  [0x70, 0x80, 0x90, 0xA0, 0xB0, 0xC0])
        pts = [(x0 + r * w / 128, py + (min(max(v, 0x70), 0xC0) - 0x70) * h / 0x50) for r, v in enumerate(lines)]
        d.line(pts, fill=(90, 150, 250), width=2)
        drawn = [v for v in rowlist if v < 0xFE]
        d.text((x0 + 6, py + h - 34), f'RowList: {len(drawn)} lines drawn,', fill=K.DIM, font=fs)
        d.text((x0 + 6, py + h - 18), f'{len(set(drawn))} distinct rows', fill=K.DIM, font=fs)
        # BendRows: row (x) against the shift
        x1 = 775
        plot_axes(d, x1, py, w, h, 128, 0, 192, fs, 'road row', 'BendRows: sideways shift',
                  [0, 32, 64, 96, 128, 160, 192])
        pts = [(x1 + r * w / 128, py + v * h / 192) for r, v in enumerate(hills)]
        d.line(pts, fill=(240, 200, 70), width=2)
    wrap(d, 'RoadLines is the line each row lands on (row 0 the nearest, at $BF on the flat); on a crest the near '
            'rows start higher ($9E) and the far ones crowd toward line $70. BendRows is added to each row\'s centre '
            'before the scaling: a bend. The .ann names them Crest (bits 2-3) and Bend (bits 0-1).', 12, pic.height - 50, WIDTH - 24, fs, K.DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def cmd_edges(args):
    mem = image()
    f, fs, ft = K.font(13), K.font(12), K.font(16)
    row, top = 22, 40
    pic = Image.new("RGB", (WIDTH, top + 2 * (30 + 15 * row) + 90), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), 'The edge patterns: 15 width classes x 8 shifts x 3 bytes (4 screen pixels a pixel), two sets for '
                    'the stripes', fill=K.TEXT, font=ft)
    y = top
    for base, name in ((0x7880, 'EdgePatterns $7880 (row + progress: bit 2 set)'),
                       (0x7A80, 'EdgePatterns2 $7A80 (bit 2 clear)')):
        d.text((12, y), name, fill=K.TEXT, font=f)
        for shift in range(8):
            d.text((60 + shift * 122, y + 4 + 14), f'x AND 7 = {shift}', fill=K.DIM, font=fs)
        y += 36
        for cls in range(15):
            d.text((12, y + 3), f'{cls * 8:3d}', fill=K.DIM, font=fs)
            for shift in range(8):
                a = base + cls * 24 + shift * 3
                cell = Image.new('RGB', (24, 1), PAPER)
                px = cell.load()
                for byte in range(3):
                    v = mem[a + byte]
                    for bit in range(8):
                        if v & (0x80 >> bit):
                            px[byte * 8 + bit, 0] = INK
                pic.paste(cell.resize((96, row - 4), Image.NEAREST), (60 + shift * 122, y))
            y += row
        y += 10
    wrap(d, 'Left: the width class, RowScale[row] / 2 capped at $70, AND $F8 (wider edges for nearer rows). Each '
            'cell is 3 bytes = 24 pixels written by LDI at the edge\'s byte. The set alternates with bit 2 of (row + '
            'the segment\'s progress): the stripes run toward the bike.', 12, y, WIDTH - 24, fs, K.DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('layout')
    s.add_argument('--work', required=True)
    s.add_argument('--built', required=True, help='F:T, the moment before CopyBuffer')
    s.add_argument('--shown', type=int, required=True, help='a frame after the copy')
    s.add_argument('--out', required=True)
    s = sub.add_parser('rows')
    s.add_argument('--work', required=True)
    s.add_argument('--frame', type=int, action='append', required=True)
    s.add_argument('--label', action='append', required=True)
    s.add_argument('--out', required=True)
    s = sub.add_parser('edges')
    s.add_argument('--out', required=True)
    args = p.parse_args()
    {'layout': cmd_layout, 'rows': cmd_rows, 'edges': cmd_edges}[args.cmd](args)


if __name__ == '__main__':
    main()
