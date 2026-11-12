#!/usr/bin/env python3
"""The figures of docs 02 and 03: the memory map at three moments, and the file `boot` on the disk.

    python3 tools/fig_arch.py

The memory map draws `$4000-$FFFF`, one line of pixels per 256 bytes, coloured by region; the brightness of a line
is the share of its bytes that are not zero. The first column is the image the Loader leaves
(`work/mkgame/original.bin`) with the BASIC that TR-DOS loads (`build/basic.bin`, its first 184 bytes at `$5D3B`);
the other two are the c1 moments kept in `work/docs/figcache/` (written by `tools/fig_overview.py`). The medium figure
draws the 46 sectors of `boot` from `build/basic.bin` and the part sizes. The heatmap is the composite panel of
`kit/heatmap.py` (red written, green read, blue executed, log2 of the counts) over c1's L1
(`work/stage1/c1/l1.json`), with an address axis every `$1000` and the regions of `work/stage2/regions.txt`. Writes
docs/img/arch/memory-map.png, docs/img/arch/medium.png and docs/img/arch/heatmap-composite.png.
"""
import os

import figzyx as Z

# (from, to, colour, label): the regions of doc 2, 2.2
REGIONS = [
    (0x4000, 0x5AFF, (150, 150, 165), 'the screen $4000-$5AFF'),
    (0x5B00, 0x5D3A, (110, 110, 125), 'system variables (FRAMES, CHARS, $5CF4)'),
    (0x5D3B, 0x61A7, (90, 200, 120), 'the BASIC and the Loader $5D3B-$5DF2'),
    (0x61A8, 0x70A7, (90, 150, 250), 'the code $61A8-$70A7 (sectors 1-15)'),
    (0x70A8, 0x75FF, (70, 70, 85), 'zeros (SoundOff reads $7530)'),
    (0x7600, 0x77FF, (200, 110, 230), 'the phase builder work $7600'),
    (0x7800, 0x9BFF, (240, 200, 70), 'rhombus sets A $7800, B $8A00'),
    (0x9C00, 0x9CFF, (200, 110, 230), 'RotateBuffer $9C00'),
    (0x9D00, 0xA5FF, (70, 210, 220), 'Catalogue $9D00 (8 sectors)'),
    (0xA600, 0xADFF, (230, 90, 80), 'graphics $A600-$ADFF (sectors 16-23)'),
    (0xAE00, 0xBFFF, (200, 110, 230), 'variables $AFC8, $B3B0'),
    (0xC000, 0xD5FF, (240, 140, 60), 'music $C000-$D5FF (sectors 24-45)'),
    (0xD600, 0xDFFF, (200, 110, 230), 'twinkle and spin variables $DEA8'),
    (0xE000, 0xFAFF, (150, 220, 150), 'ScreenCopy $E000-$FAFF'),
    (0xFB00, 0xFFFF, (200, 110, 230), 'stack $FCBB, Im2Jump $FCFC, Im2Table $FD00'),
]

ROW_PX = 3


def region(addr):
    for lo, hi, colour, _ in REGIONS:
        if lo <= addr <= hi:
            return colour
    return (60, 60, 70)


def loaded():
    mem = bytearray(Z.image())
    with open(os.path.join(Z.CASE, 'build', 'basic.bin'), 'rb') as f:
        basic = f.read()
    mem[0x5D3B:0x5D3B + 184] = basic[:184]
    return bytes(mem)


def cached(name):
    with open(os.path.join(Z.CASE, 'work', 'docs', 'figcache', name + '.bin'), 'rb') as f:
        return f.read()


def column(d, x, y, mem, w):
    for row in range(192):
        a = 0x4000 + row * 256
        used = sum(1 for b in mem[a:a + 256] if b) / 256
        r, g, b = region(a)
        k = 0.18 + 0.82 * used if used else 0.10
        d.rectangle([x, y + row * ROW_PX, x + w - 1, y + row * ROW_PX + ROW_PX - 1],
                    fill=(int(r * k), int(g * k), int(b * k)))


def fig_memory_map():
    cols = [('as loaded', 'the Loader done', loaded()),
            ('c1 frame 850', 'set-up: phases built', cached('c1-850')),
            ('c1 frame 1000', 'the menu idle', cached('c1-1000'))]
    top = 92
    out, d = Z.canvas(top + 192 * ROW_PX + 40)
    Z.title(d, 'The memory map: what is loaded, what the set-up builds',
            '$4000-$FFFF, one line per 256 bytes, coloured by region; brighter = more bytes not zero, '
            'dark = all zeros')
    f, fs = Z.font(12), Z.font(11)
    x0, w, gap = 70, 160, 22
    for i, (name, sub, mem) in enumerate(cols):
        x = x0 + i * (w + gap)
        d.text((x, top - 34), name, fill=Z.TEXT, font=f)
        d.text((x, top - 18), sub, fill=Z.DIM, font=fs)
        column(d, x, top, mem, w)
    for a in range(0x4000, 0x10001, 0x2000):
        y = top + (a - 0x4000) // 256 * ROW_PX
        d.line([(x0 - 6, y), (x0 - 1, y)], fill=Z.DIM)
        d.text((8, y - 7), f'${a:04X}' if a < 0x10000 else '$FFFF', fill=Z.DIM, font=fs)
    lx = x0 + 3 * (w + gap) + 10
    lasty = -100
    for lo, hi, colour, label in REGIONS:
        y = top + ((lo + hi) // 2 - 0x4000) // 256 * ROW_PX - 6
        y = max(y, lasty + 15)
        lasty = y
        ry = top + ((lo + hi) // 2 - 0x4000) // 256 * ROW_PX
        d.line([(lx - 8, ry), (lx - 2, y + 6)], fill=Z.DIM)
        d.rectangle([lx, y + 1, lx + 10, y + 11], fill=colour)
        d.text((lx + 16, y), label, fill=Z.TEXT, font=fs)
    d.text((8, top + 192 * ROW_PX + 12), 'drawn by tools/fig_arch.py: work/mkgame/original.bin with build/basic.bin; '
                                         'c1 moments from work/docs/figcache/ (TTD memory_at, frame start)',
           fill=Z.DIM, font=fs)
    Z.save(out, 'docs/img/arch/memory-map.png')


def fig_medium():
    with open(os.path.join(Z.CASE, 'build', 'basic.bin'), 'rb') as f:
        basic = f.read()
    assert len(basic) == 256
    parts = [(0, 1, (90, 200, 120), 'sector 0', 'the BASIC: TR-DOS loads 184 bytes', 'to $5D3B-$5DF2 (frame 446)'),
             (1, 15, (90, 150, 250), 'sectors 1-15', 'the code, 3840 bytes', 'to $61A8-$70A7'),
             (16, 8, (230, 90, 80), 'sectors 16-23', 'the graphics, 2048 bytes', 'to $A600-$ADFF'),
             (24, 22, (240, 140, 60), 'sectors 24-45', 'the music, 5632 bytes', 'to $C000-$D5FF')]
    out, d = Z.canvas(400)
    Z.title(d, 'The file boot on the disk: 46 sectors, four parts',
            'one box a sector; TR-DOS loads only the program from sector 0, the Loader reads the other 45 itself '
            'from $5CF4 (frames 459-515 in c1)')
    f, fs = Z.font(12), Z.font(11)
    x0, y0, cw, ch = 12, 80, 22, 40
    for first, n, colour, name, what, where in parts:
        for s in range(first, first + n):
            x = x0 + s * cw
            d.rectangle([x, y0, x + cw - 3, y0 + ch], fill=colour)
            d.text((x + 3, y0 + ch + 4), str(s), fill=Z.DIM, font=Z.font(9))
        xm = x0 + first * cw
        ty = y0 + ch + 34 + (64 if first == 0 else 0)
        d.line([(xm + 1, y0 + ch + 18), (xm + 1, ty - 2)], fill=colour, width=2)
        d.text((xm + 6, ty), name, fill=Z.TEXT, font=f)
        d.text((xm + 6, ty + 16), what, fill=Z.DIM, font=fs)
        d.text((xm + 6, ty + 30), where, fill=Z.DIM, font=fs)
    # sector 0 in bytes
    by = 300
    d.text((x0, by - 22), 'sector 0 byte by byte (256 bytes, 4 px each):', fill=Z.TEXT, font=f)
    spans = [(0, 180, (90, 200, 120), 'the program, 180 bytes ($5D3B-$5DEE): loaded', 0),
             (180, 184, (240, 240, 240), 'the autostart mark, 4 bytes ($5DEF): loaded', 18),
             (184, 256, (80, 80, 95), 'the tail, 72 bytes: stays on the disk', 0)]
    for lo, hi, colour, label, dy in spans:
        d.rectangle([x0 + lo * 4, by, x0 + hi * 4 - 1, by + 18], fill=colour)
        d.text((x0 + lo * 4 + 2 if lo != 180 else x0 + 470, by + 24 + dy), label, fill=Z.DIM, font=fs)
    d.text((x0, by + 70), 'drawn by tools/fig_arch.py from build/basic.bin and the part sizes of tools/build.sh',
           fill=Z.DIM, font=fs)
    Z.save(out, 'docs/img/arch/medium.png')


def fig_heatmap():
    import heatmap as H
    lo, hi, cell = 0x4000, 0xFFFF, 3
    executes, reads, writes, _last, replay = H.load(os.path.join(Z.CASE, 'work/stage1/c1/l1.json'), H.BASES_48K)
    fx, _ = H.scale(executes, lo, hi)
    fr, _ = H.scale(reads, lo, hi)
    fw, _ = H.scale(writes, lo, hi)
    pan = H.panel(lo, hi, cell, lambda a: (int(255 * fw(a)), int(255 * fr(a)), int(255 * fx(a))))
    x0, y0, label_w = 78, 74, 330
    out, d = Z.canvas(y0 + pan.height + 74, x0 + pan.width + label_w)
    Z.title(d, 'c1: what the program wrote (red), read (green) and executed (blue), $4000-$FFFF',
            f'stage-1 L1, frames 104-7880; one row = 256 bytes, one column = the byte $xx00 + column; log2 of the counts')
    out.paste(pan, (x0, y0))
    fa = Z.font(15)
    for a in range(lo, hi + 1, 0x1000):
        y = y0 + ((a - lo) >> 8) * cell
        d.text((10, y - 8), f'${a:04X}', fill=Z.TEXT, font=fa)
        d.line([(x0 - 8, y), (x0 - 2, y)], fill=Z.TEXT)
    for c in range(0, 256, 0x40):
        x = x0 + c * cell
        d.line([(x, y0 + pan.height + 2), (x, y0 + pan.height + 8)], fill=Z.DIM)
        d.text((x - 8, y0 + pan.height + 10), f'+${c:02X}', fill=Z.DIM, font=Z.font(13))
    regions = [(0x4000, 0x5AFF, 'the screen $4000-$5AFF')]
    for line in open(os.path.join(Z.CASE, 'work/stage2/regions.txt')):
        parts = line.split(None, 2)
        if len(parts) == 3 and not line.startswith('#'):
            a, b = int(parts[0], 16), int(parts[1], 16)
            regions.append((a, b, f'{parts[2].strip()} ${a:04X}-${b:04X}'))
    rx = x0 + pan.width + 8
    fl = Z.font(15)
    for a, b, name in regions:
        ya = y0 + ((a - lo) >> 8) * cell
        yb = y0 + ((b - lo) >> 8) * cell + cell - 1
        d.line([(rx, ya), (rx + 6, ya), (rx + 6, yb), (rx, yb)], fill=(220, 220, 150))
        d.text((rx + 12, max(ya, (ya + yb) // 2 - 9)), name, fill=(230, 230, 170), font=fl)
    Z.save(out, 'docs/img/arch/heatmap-composite.png')


def main():
    fig_memory_map()
    fig_medium()
    fig_heatmap()


if __name__ == '__main__':
    main()
