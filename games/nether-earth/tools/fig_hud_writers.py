#!/usr/bin/env python3
"""Doc 08 figure: the first drawing of the play screen, each byte coloured by the job of the code that wrote it last
(docs/img/hud-panel-writers.png).

    python3 tools/fig_hud_writers.py --trace work/docC/rec/traces/436_0-470_0.uatr --listing build/game.lst \
        --out docs/img/hud-panel-writers.png

The trace is kit/writers_map.py's cache of `--work work/docC/rec --window 436:0-470:0`. The routines are grouped
into what they do (clearing, the view's copy, the frame, the radar, normal text, big text); the panel's columns
22-31 are marked. Left: the screen at the window's end; right: the same pixels in the colour of their writer.
"""
import argparse
import os
import sys
from collections import Counter

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

GROUPS = [  # name, colour, routine test
    ('clearing the screen (ClearScreen)', (90, 200, 110), lambda r: r.startswith('ClearScreen')),
    ('the view copied from its buffer (CopyViewToScreen)', (230, 80, 70),
     lambda r: r.startswith('CopyLine') or r.startswith('CopyView') or r.startswith('ViewAttr')),
    ('the frame around the view', (190, 120, 230),
     lambda r: r.startswith('Frame') or r.startswith('BlueCorner') or r == 'DrawPlayScreen'),
    ('the radar (drawn by every interrupt)', (80, 150, 240),
     lambda r: r.startswith('Radar') or r.startswith('FillAttr') or r.startswith('ShowRadar')),
    ('normal text: PrintChar, every word and digit of the panel', (240, 200, 70),
     lambda r: r.startswith('GlyphLine') or r.startswith('PrintChar')),
    ('big text: PrintBigChar (the tall RADAR:)', (255, 120, 200),
     lambda r: r.startswith('TallRepeat') or r.startswith('BigAttr') or r.startswith('Wide') or
     r.startswith('PrintBigChar') or r.startswith('BigChar')),
]
OTHER = ('other', (150, 150, 160))


def group_of(routine):
    for name, colour, test in GROUPS:
        if routine and test(routine):
            return name
    return OTHER[0]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--listing', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    trace = K.load_trace(args)
    lst = K.listing(args.listing)
    mem = bytearray(trace.memory)
    writer, writes, routines = {}, Counter(), {}
    for x in trace.instructions:
        routine = lst.routine(x.pc)
        g = group_of(routine)
        for c in x.cycles:
            if c.tag in 'WE':
                mem[c.address] = c.value
                if 0x4000 <= c.address < 0x5B00:
                    writer[c.address] = g
                    writes[g] += 1
                    routines.setdefault(g, Counter())[routine] += 1
    colour = {name: col for name, col, _ in GROUPS}
    colour[OTHER[0]] = OTHER[1]
    owned = Counter(writer.values())

    S = 2
    shown = K.render_screen(mem, 0x4000).convert('RGB')
    who = Image.new('RGB', (256, 192), (0, 0, 0))
    px = who.load()
    for a in range(0x1800):
        addr = 0x4000 + a
        x0, y = (a & 31) * 8, K.screen_line(addr)
        g = writer.get(addr)
        on = colour[g] if g else (90, 90, 96)
        off = tuple(v // 4 for v in on) if g else (26, 26, 32)
        bits = mem[addr]
        for bit in range(8):
            px[x0 + bit, y] = on if bits & (0x80 >> bit) else off
    panels = [shown.resize((256 * S, 192 * S), Image.NEAREST), who.resize((256 * S, 192 * S), Image.NEAREST)]

    font, small, big = K.font(13), K.font(12), K.font(16)
    gap, top = 14, 64
    legend_h = 22 * (len(GROUPS) + 2) + 30
    W = 2 * 256 * S + 3 * gap
    H = top + 192 * S + 30 + legend_h
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    text_bytes = owned[GROUPS[4][0]]
    d.text((gap, 8), 'The play screen\'s first drawing: every byte of the panel at the right is PrintChar text',
           fill=K.TEXT, font=big)
    d.text((gap, 32), f'work/docC/rec frames {trace.from_frame}-{trace.to_frame}: all {len(writer)} of 6912 bytes '
           f'written, {sum(writes.values())} writes. White box: the panel, columns 22-31.',
           fill=K.DIM, font=small)
    for i, panel in enumerate(panels):
        x = gap + i * (256 * S + gap)
        im.paste(panel, (x, top))
        # the panel: columns 22-31, all 24 rows
        px0, px1 = x + 22 * 8 * S, x + 32 * 8 * S
        d.rectangle([px0 - 1, top - 1, px1, top + 24 * 8 * S], outline=(255, 255, 255), width=2)
        d.text((x, top + 192 * S + 4), ['the screen at the window\'s end', 'who wrote each byte last'][i],
               fill=K.DIM, font=small)
    y = top + 192 * S + 30
    for name, col, _ in GROUPS + [(OTHER[0], OTHER[1], None)]:
        if not writes[name]:
            continue
        d.rectangle([gap, y + 2, gap + 14, y + 16], fill=col)
        d.text((gap + 22, y), name, fill=K.TEXT, font=font)
        d.text((gap + 560, y), f'{owned[name]:5d} bytes last, {writes[name]:5d} writes', fill=K.DIM, font=font)
        y += 22
    y += 6
    pc_counts = routines.get(GROUPS[4][0], Counter())
    d.text((gap, y), f'PrintChar wrote {writes[GROUPS[4][0]]} times ({text_bytes} bytes last): the glyph lines and the '
           'attributes of every character', fill=K.DIM, font=small)
    im.save(args.out)
    print(args.out, im.size, {k: (owned[k], writes[k]) for k in writes}, dict(pc_counts))


if __name__ == '__main__':
    sys.exit(main())
