#!/usr/bin/env python3
"""The figures of doc 06 (rendering), drawn from the image, the bank 7 pictures and an access trace.

    python3 tools/fig_rendering.py layout   docs/img/render/layout.png     # the back buffer rows on the screen, 4 blits
    python3 tools/fig_rendering.py patterns docs/img/render/patterns.png   # the 13 fill colours of FillPatterns $66D6
    python3 tools/fig_rendering.py pictures docs/img/render/pictures.png   # the 10 packed screens of bank 7, sizes
    python3 tools/fig_rendering.py tokens   docs/img/render/tokens.png     # the first tokens of PicTitle, bit by bit
    python3 tools/fig_rendering.py load     docs/img/render/load.png TRACE # T a pass by stage (death 8300-8450)
    python3 tools/fig_rendering.py sight    docs/img/render/sight.png      # the sight overlay in play 8570

The banks are the build's cuts (work/mkgame/bankN.bin); the pictures are build/bank7.bin decoded with
tools/bank7pic.py; the cockpit is src/res/pictures/cockpit.png. `load` reads an access trace (`analysis trace`, e.g.
work/docs/bcB/death/traces/8300_0-8450_0.uatr) and names each instruction from build/game.lst or build/bank3.lst by
the bank paged at `$C000` (followed through the `OUT` to `$7FFD`); the interrupt is the code on its own stack
(`$7B00-$7C49`) and the blits, which run with SP on the screen row table.
"""
import bisect
import collections
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, HERE)
import kitlib  # noqa: E402
import bank7pic  # noqa: E402

BG, FG, DIM = (16, 16, 24), (235, 235, 240), (170, 170, 180)
W = 1050


def bank(n):
    return open(os.path.join(CASE, 'work', 'mkgame', f'bank{n}.bin'), 'rb').read()


def zx(im, scale):
    return im.convert('RGB').resize((im.width * scale, im.height * scale), Image.NEAREST)


def layout(out):
    """the cockpit with the screen rows each blit writes (raster.asm)"""
    cockpit = zx(Image.open(os.path.join(CASE, 'src', 'res', 'pictures', 'cockpit.png')), 2)
    im = Image.new('RGB', (W, 450), BG)
    d = ImageDraw.Draw(im)
    f, fs = kitlib.font(15), kitlib.font(12)
    d.text((10, 8), 'Where the back buffer lands: the four blits over the cockpit picture (rows are screen lines)',
           fill=FG, font=f)
    cockpit_rows = [(0, 111, 88, 8), (168, 111, 88, 8), (8, 119, 16, 8), (232, 119, 16, 8)]
    blits = [('ViewBlitFront $8999', '(play, binoculars, rear view)', [(0, 32, 256, 79)] + cockpit_rows,
              (255, 120, 120)),
             ('ViewBlitWide $8A41', '(the title\'s turning model)', [(0, 64, 256, 86)], (120, 200, 255)),
             ('ViewBlitNarrow $8A98', '(the Dragonfly\'s flight view)', [(48, 40, 176, 95)], (255, 220, 120)),
             ('ViewBlitLow $898B', '(after a goal\'s pickup message)', [(0, 40, 256, 71)] + cockpit_rows,
              (150, 240, 150))]
    for k, (name, use, rects, col) in enumerate(blits):
        x0 = 10 + k * 260
        pic = cockpit.copy()
        pd = ImageDraw.Draw(pic, 'RGBA')
        for x, y, w, h in rects:
            pd.rectangle((x * 2, y * 2, (x + w) * 2 - 1, (y + h) * 2 - 1), fill=col + (90,), outline=col + (255,),
                         width=2)
        pic = pic.resize((250, 188))
        im.paste(pic, (x0, 40))
        d.text((x0, 236), name, fill=col, font=fs)
        d.text((x0, 254), use, fill=col, font=fs)
    notes = ['Front: buffer rows 0-78 to lines 32-110 full width; rows 79-86 only bytes 0-10 and 21-31 (the cockpit',
             'top cut out); rows 87-94 only bytes 1-2 and 29-30. 2736 bytes, one ScreenRowTable entry a line ($6540 on).',
             'Wide: buffer rows 0-85 to lines 64-149, 2752 bytes. The console and the status map use bank 6\'s',
             'BlitMapView $DBBD instead. Narrow: buffer rows 0-94, bytes 5-26, to lines 40-134 at column 6: 2090 bytes.',
             'Low: buffer rows 8-78 to lines 40-110, then the cockpit rows of Front: 2480 bytes (m1complete from 16138).']
    for i, t in enumerate(notes):
        d.text((10, 290 + i * 22), t, fill=DIM, font=fs)
    im.save(out)
    print(out, im.size)


def patterns(out):
    """FillPatterns $66D6: 13 colours, 2 bytes each (even row, odd row)"""
    b5 = bank(5)
    pats = [(b5[0x66D6 - 0x4000 + 2 * i], b5[0x66D6 - 0x4000 + 2 * i + 1]) for i in range(13)]
    im = Image.new('RGB', (W, 330), BG)
    d = ImageDraw.Draw(im)
    f, fs = kitlib.font(15), kitlib.font(12)
    d.text((10, 8), 'FillPatterns $66D6: the 13 colours (a, b); FillSpans writes b on one row and b XOR a on the next', fill=FG,
           font=f)
    for i, (a, b) in enumerate(pats):
        x0 = 10 + (i % 7) * 148
        y0 = 40 + (i // 7) * 140
        sw = Image.new('RGB', (32, 16))
        for y in range(16):
            v = b if y % 2 == 0 else b ^ a
            for x in range(32):
                sw.putpixel((x, y), (0, 0, 0) if v >> (7 - x % 8) & 1 else (230, 230, 230))
        im.paste(sw.resize((128, 64), Image.NEAREST), (x0, y0))
        d.text((x0, y0 + 70), f'{i}: rows {b:02X}, {b ^ a:02X}', fill=FG, font=fs)
    d.text((10, 300), 'Ink is a set bit (black here). When the light value $757A is 0, FillSpans ignores the colour and '
                      'writes $FF on every row.', fill=DIM, font=fs)
    im.save(out)
    print(out, im.size, pats)


def picture_blocks():
    b7 = bank(7)
    out = []
    names = dict(zip(bank7pic.BLOCKS, ['damage-board', 'stores', 'mission-select', 'grid-panel', 'cockpit',
                                       'completion', 'briefing', 'mission-status', 'title', 'map-frame']))
    for adr in bank7pic.BLOCKS:
        o = adr - 0xC000
        size = b7[o] | b7[o + 1] << 8
        block = b7[o:o + 2 + size + 2]
        screen, parse = bank7pic.decode(block)
        out.append((adr, names[adr], 2 + size + 2, screen, parse))
    return out


def pictures(out):
    blocks = picture_blocks()
    im = Image.new('RGB', (W, 1010), BG)
    d = ImageDraw.Draw(im)
    f, fs = kitlib.font(15), kitlib.font(12)
    d.text((10, 8), 'The ten packed screens of bank 7: address, packed size, tokens (UnpackPicture $FE95)', fill=FG,
           font=f)
    for i, (adr, name, size, screen, parse) in enumerate(blocks):
        x0 = 10 + (i % 4) * 260
        y0 = 36 + (i // 4) * 325
        pic = Image.open(os.path.join(CASE, 'src', 'res', 'pictures', name + '.png')).convert('RGB')
        im.paste(pic, (x0, y0))
        kinds = collections.Counter(t[0] for t in parse['tokens'])
        d.text((x0, y0 + 196), f'{name} ${adr:04X}', fill=FG, font=fs)
        d.text((x0, y0 + 212), f'{size} bytes = {size * 100 / 6912:.0f} % of 6912', fill=DIM, font=fs)
        d.text((x0, y0 + 228), f'{len(parse["tokens"])} tokens: COPY {kinds["COPY"]} RUN {kinds["RUN"] + kinds["RUNTAB"]}',
               fill=DIM, font=fs)
        d.text((x0, y0 + 244), f'LIT {kinds["LIT"]} TAB {kinds["TAB"]}', fill=DIM, font=fs)
        print(name, hex(adr), size, dict(kinds))
    total = sum(b[2] for b in blocks)
    d.text((530, 36 + 2 * 325 + 20), f'All ten: {total} bytes for {10 * 6912} bytes of screens', fill=FG, font=f)
    d.text((530, 36 + 2 * 325 + 46), f'({total * 100 / 69120:.0f} %). Bank7Free $D750-$DD74 holds 1573 zero', fill=FG,
           font=f)
    d.text((530, 36 + 2 * 325 + 72), 'bytes between grid-panel and cockpit.', fill=FG, font=f)
    im.save(out)
    print(out, im.size, total)


def tokens(out):
    """the first tokens of PicTitle with their bits, as UnpackPicture reads them"""
    b7 = bank(7)
    o = 0xF4E1 - 0xC000
    block = b7[o:o + 64]
    table = block[4:20]
    reader = bank7pic.BitReader(block, 21)
    rows = []
    produced = 0
    for _ in range(9):
        start = (reader.p - 21) * 8 - reader.n
        bits = []

        def get(k):
            v = reader.get(k)
            bits.append(format(v, f'0{k}b'))
            return v
        t = get(2)
        if t == 1:
            v = get(8)
            what, outb = f'LIT {v:02X}', [v]
        elif t == 3:
            i = 15 - get(4)
            what, outb = f'TAB {15 - i} -> table[{i}] = {table[i]:02X}', [table[i]]
        else:
            n = get(6)
            if t == 2:
                off = get(8) | get(1) << 8
                what, outb = f'COPY {n} from {off} back', [None] * n
            elif get(1):
                i = 15 - get(4)
                what, outb = f'RUN {n} x table[{i}] = {table[i]:02X}', [table[i]] * n
            else:
                v = get(8)
                what, outb = f'RUN {n} x {v:02X}', [v] * n
        rows.append((start, ' '.join(bits), what, produced, len(outb)))
        produced += len(outb)
    im = Image.new('RGB', (W, 140 + 26 * len(rows)), BG)
    d = ImageDraw.Draw(im)
    f, fs = kitlib.font(15), kitlib.font(13)
    d.text((10, 8), 'PicTitle $F4E1: the first nine tokens; each field as its value in binary (GetBits reads it LSB first)', fill=FG,
           font=f)
    d.text((10, 32), 'header ' + ' '.join(f'{v:02X}' for v in block[:4]) + '   table ' +
           ' '.join(f'{v:02X}' for v in table) + f'   long {block[20]}   stream ' +
           ' '.join(f'{v:02X}' for v in block[21:27]) + ' ...', fill=DIM, font=fs)
    cols = [10, 90, 420, 900]
    for c, h in zip(cols, ['bit', 'bits (type first)', 'token', 'output']):
        d.text((c, 64), h, fill=FG, font=fs)
    for k, (start, bits, what, at, n) in enumerate(rows):
        y = 90 + k * 26
        d.text((cols[0], y), str(start), fill=DIM, font=fs)
        d.text((cols[1], y), bits, fill=(120, 200, 255), font=fs)
        d.text((cols[2], y), what, fill=FG, font=fs)
        d.text((cols[3], y), f'+{at} ({n})', fill=DIM, font=fs)
    d.text((10, 100 + 26 * len(rows)), 'Types: 01 LIT (8 bits), 11 TAB (4 bits, table[15 - i]), 10 COPY (count, 8 + 1 '
                                       'offset bits), 00 RUN (count, 1 bit: table or literal)', fill=DIM, font=fs)
    im.save(out)
    print(out, im.size)
    for r in rows:
        print(r)


STAGES = [('interrupt (blit, keys)', (230, 120, 120)), ('clear', (255, 170, 90)),
          ('logic, radar, HUD, other', (150, 150, 160)), ('scripts and faces', (200, 160, 255)),
          ('projection (log divide)', (255, 220, 120)), ('clipping', (120, 200, 255)), ('fill', (120, 220, 140)),
          ('lines and dots', (240, 140, 220)), ('camera, rotate, multiply', (110, 160, 160))]


def stage_of(name):
    n = name
    if n == 'ClearBackBuffer':
        return 1
    if n in ('OpProject', 'Divide', 'DivideByLog', 'ApplySign', 'NegHL', 'ZeroQuotient'):
        return 4
    if n.startswith(('Clip', 'Intersect', 'NearClip')):
        return 5
    if n in ('FillPolygon', 'EdgeWalk', 'EdgeSlope', 'NextRightEdge', 'NextLeftEdge', 'FillSpans',
             'FillSpansThenReturn', 'FillSpansReturn', 'HighTimes32', 'LowTimes32', 'PushLeftover'):
        return 6
    if n in ('DrawLine', 'DrawVerticalLine', 'LinePixelBit', 'PlotBackBuffer', 'GroundDots', 'PlotGroundDot',
             'Bank3Lookup'):
        return 7
    if n.startswith(('Mul', 'Rotate', 'Box', 'SinCos')) or n in ('TransformObjects', 'DepthInsert', 'SetCamera',
                                                                 'CameraSinCos', 'CameraSinCosAgain', 'Sine8Half'):
        return 8
    if n.startswith('Op') or n in ('RunScript', 'TestFace', 'FillFaceList', 'FillFaceListClipped', 'SharedModels'):
        return 3
    return 2


def labels(path):
    out = []
    for line in open(os.path.join(CASE, path)):
        m = re.match(r'\s*\d+\+*\s+([0-9A-F]{4})\s+([A-Za-z]\w*):', line)
        if m and not re.match(r'l_[0-9A-F]{4}$', m.group(2)):
            out.append((int(m.group(1), 16), m.group(2)))
    out.sort()
    return [a for a, _ in out], [n for _, n in out]


def load(out, trace):
    sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
    import access_trace  # noqa: E402
    game, b3 = labels('build/game.lst'), labels('build/bank3.lst')

    def name(pc, bk):
        tab = b3 if pc >= 0xC000 and bk == 3 else game
        if pc >= 0xC000 and bk not in (0, 3):
            return f'bank {bk}'
        i = bisect.bisect_right(tab[0], pc) - 1
        return tab[1][i] if i >= 0 else '?'
    t = access_trace.load(trace)
    ins = t.instructions
    ft = t.frame_t
    bk = t.pages[3] & 7 if t.pages[3] < 8 else 0
    starts = [i for i, x in enumerate(ins) if x.pc == 0x9882]
    passes = []
    k = 0
    banks = []
    for x in ins:
        banks.append(bk)
        for c in x.cycles:
            if c.tag == 'O' and c.address & 0x8002 == 0:
                bk = c.value & 7
    for a, b in zip(starts, starts[1:]):
        cost = [0] * len(STAGES)
        fills = lines = 0
        for k in range(a, b):
            x = ins[k]
            dt = (ins[k + 1].frame - x.frame) * ft + ins[k + 1].t - x.t
            n = name(x.pc, banks[k])
            if 0x7B00 <= x.sp <= 0x7C49 or n.startswith('ViewBlit'):
                cost[0] += dt
                continue
            cost[stage_of(n)] += dt
            if x.pc == 0xC4C4 and banks[k] == 3:
                fills += 1
            if x.pc == 0xC9A7 and banks[k] == 3:
                lines += 1
        passes.append((ins[a].frame, ins[a].t, cost, fills, lines))
    im = Image.new('RGB', (W, 520), BG)
    d = ImageDraw.Draw(im)
    f, fs = kitlib.font(15), kitlib.font(12)
    d.text((10, 8), 'T a pass by stage, death %d-%d (one bar a pass of the 3D view, StartViewPass to StartViewPass)'
           % (ins[0].frame, ins[-1].frame), fill=FG, font=f)
    x0, y0, bh = 60, 420, 360
    maxt = max(sum(p[2]) for p in passes)
    bw = (W - 330 - x0) / len(passes)
    for fr in range(0, int(maxt / ft) + 2, 2):
        y = y0 - fr * ft / maxt * bh
        if y < 40:
            break
        d.line((x0, y, x0 + bw * len(passes), y), fill=(45, 45, 58))
        d.text((10, y - 7), f'{fr} fr', fill=DIM, font=fs)
    for i, (fr, tt, cost, fills, lines) in enumerate(passes):
        y = y0
        for s, c in enumerate(cost):
            h = c / maxt * bh
            d.rectangle((x0 + i * bw + 2, y - h, x0 + (i + 1) * bw - 2, y), fill=STAGES[s][1])
            y -= h
        d.text((x0 + i * bw + 2, y0 + 6), str(fr), fill=DIM, font=fs)
        d.text((x0 + i * bw + 2, y0 + 22), f'{fills}', fill=(120, 220, 140), font=fs)
        print(fr, tt, round(sum(cost) / ft, 2), [round(c / ft, 2) for c in cost], fills, lines)
    d.text((10, y0 + 6), 'start', fill=DIM, font=fs)
    d.text((10, y0 + 22), 'fills', fill=(120, 220, 140), font=fs)
    tot = [sum(p[2][s] for p in passes) for s in range(len(STAGES))]
    for s, (nm, col) in enumerate(STAGES):
        y = 60 + s * 26
        d.rectangle((W - 290, y, W - 276, y + 14), fill=col)
        d.text((W - 268, y), f'{nm} {tot[s] * 100 / sum(tot):.0f} %', fill=FG, font=fs)
    d.text((10, 470), 'Interrupt: the handler on its stack ($7B00-$7C49) and the blits; names from '
                      'game.lst and bank3.lst by the bank at $C000.', fill=DIM, font=fs)
    d.text((10, 490), f'Command: python3 tools/fig_rendering.py load {out} {os.path.relpath(trace, CASE)}', fill=DIM,
           font=fs)
    im.save(out)
    print(out, im.size, [round(v * 100 / sum(tot), 1) for v in tot])


def sight(out):
    """the sight overlay: play frame 8570 (Banshee RRSS selected, SelectPlain set $C4DC), the view enlarged, the
    16 rows x 2 bytes DrawSightOverlay masks into the buffer at $9000 (row 40, bytes 15-16) framed"""
    shot = Image.open(os.path.join(CASE, 'work', 'stage1', 'rec', 'play', 'screens', '008570-Banshee RRSS-lock.png'))
    shot = shot.convert('RGB').resize((256, 192), Image.NEAREST)
    s = 4
    view = zx(shot.crop((64, 32, 192, 96)), s)          # lines 32-95, columns 64-191 of the screen
    im = Image.new('RGB', (W, view.height + 150), BG)
    d = ImageDraw.Draw(im)
    f, fs = kitlib.font(15), kitlib.font(12)
    d.text((10, 8), 'The sight overlay: DrawSightOverlay $C4CD masks 16 rows x 2 bytes from $FD80 into the back buffer',
           fill=FG, font=f)
    im.paste(view, (10, 36))
    # buffer row 40 = screen line 72, bytes 15-16 = pixels 120-135
    x0, y0 = 10 + (120 - 64) * s, 36 + (72 - 32) * s
    d.rectangle((x0 - 2, y0 - 2, x0 + 16 * s + 1, y0 + 16 * s + 1), outline=(255, 220, 0), width=2)
    tx = 10 + view.width + 16
    for i, t in enumerate(['play 8570, slot 1 (Banshee RRSS)', 'selected at 8425: SelectPlain', '$C12C wrote $FF to $C4DC.',
                           '', 'Yellow: the 16 x 16 pixels at', 'buffer $9000 (row 40, bytes 15-16),',
                           'screen line 72, x 120-135.', '', 'Each byte: (buffer AND mask) OR', 'picture, the pairs at $FD80.']):
        d.text((tx, 40 + i * 20), t, fill=DIM, font=fs)
    y = 36 + view.height + 14
    notes = ['The view of the screenshot, lines 32-95 and columns 64-191, four times enlarged. DrawSightOverlay runs every pass',
             'after the objects; it draws while $C4DC is set and its counter $C4CE is even. TargetInCone sets the counter to 16',
             'when a target enters the cone, so the sight blinks for 16 passes, then shows steadily (the counter at 0).']
    for i, t in enumerate(notes):
        d.text((10, y + i * 20), t, fill=DIM, font=fs)
    im.save(out)
    print(out, im.size)


def main():
    what, out = sys.argv[1], sys.argv[2]
    if what == 'layout':
        layout(out)
    elif what == 'patterns':
        patterns(out)
    elif what == 'pictures':
        pictures(out)
    elif what == 'tokens':
        tokens(out)
    elif what == 'sight':
        sight(out)
    elif what == 'load':
        load(out, os.path.abspath(sys.argv[3]))
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
