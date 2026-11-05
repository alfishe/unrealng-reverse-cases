#!/usr/bin/env python3
"""Doc 03 figures: a packed block of ZYNAPS.B read from the disk to $6000, moved up by the depacker's LDDR and
unpacked in place by Hrust 1, as a GIF with the two pointers named on every picture.

    python3 tools/fig_unpack.py --work work/z128A/c1 --block 1 --out docs/img/load/unpack-block1.gif
    python3 tools/fig_unpack.py --work work/z128A/c1 --block 2 --out docs/img/load/unpack-block2.gif

W holds recording c1 open (re_session.py open). Each picture is the memory $5B00-$FFFF read with time_travel
memory_at at one moment (exact), drawn one row per 256 bytes. The colours come from comparing that memory with the
block's own bytes (work/parts/blkN-packed.bin, unpacked by tools/hrust1.py), never from guesses:

  green   a byte of the unpacked block already in place (equal to the final byte, below the output pointer)
  blue    the packed block where it lies (read from the disk, or after the move), still to be read by the depacker
  dim blue  the packed bytes the depacker has already read (they stay in memory, behind the input pointer)
  yellow  written since the previous picture
  grey    anything else (its value)

The output pointer is the first address from $6000 whose byte is not yet the final one; the input pointer is where
the depacker's bit reader stands for that much output, from tools/hrust1.py's decoder run on the same block (the
stream position after each token). The phase strip at the bottom is the stretch of the recording with the moments
of docs/03 3.7 marked.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import hrust1  # noqa: E402

FRAME_T = 71680  # Pentagon 128
BASE = 0x6000
LO, HI = 0x5B00, 0x10000
# block: (packed file, read start, move start, unpack end, sectors, label)
BLOCKS = {
    1: ('work/parts/blk1-packed.bin', (2061, 40000), (2125, 10448), (2182, 53027), 56,
        'Block 1, the intro: 56 sectors read to $6000, moved up, unpacked in place (c1, Pentagon 128 + TR-DOS)'),
    2: ('work/parts/blk2-packed.bin', (2838, 0), (2905, 56587), (2975, 28332), 79,
        'Block 2, the game: 79 sectors read to $6000, moved up, unpacked in place (c1, Pentagon 128 + TR-DOS)'),
}

GREEN, BLUE, BLUE_DONE = (70, 190, 100), (80, 140, 240), (40, 60, 110)


def stream_positions(block):
    """[(output length, stream offset)] after each token: where the bit reader stands for that much output"""
    marks = []
    readers = []

    class Tracked(hrust1.Reader):
        def __init__(self, d, p):
            super().__init__(d, p)
            readers.append(self)

    class Out(bytearray):
        def append(self, v):
            super().append(v)
            if readers:
                marks.append((len(self), readers[0].p))

    saved = hrust1.Reader, getattr(hrust1, 'bytearray', None)
    hrust1.Reader, hrust1.bytearray = Tracked, Out
    try:
        hrust1.decode(block, 12)
    finally:
        hrust1.Reader = saved[0]
        if saved[1] is None:
            del hrust1.bytearray
        else:
            hrust1.bytearray = saved[1]
    return marks


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    return s


def read_memory(s, frame, t):
    mem = bytearray(0x10000)
    for a in range(0x4000, 0x10000, 0x4000):
        r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                   'offset': a, 'length': 0x4000}, ok=False)
        if not r.structured or not r.structured.get('exact') or 'hex' not in r.structured:
            raise SystemExit(f'memory_at {frame}:{t}: {r.text[:200]}')
        mem[a:a + 0x4000] = bytes.fromhex(r.structured['hex'])
    return mem


def moments(t0, t1, n):
    a, b = t0[0] * FRAME_T + t0[1], t1[0] * FRAME_T + t1[1]
    return [divmod(a + (b - a) * i // (n - 1), FRAME_T) for i in range(n)]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--block', type=int, choices=(1, 2), required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--pictures', type=int, default=72)
    p.add_argument('--delay', type=int, default=90)
    args = p.parse_args()
    path, t_read, t_move, t_end, sectors, title = BLOCKS[args.block]
    packed = open(os.path.join(CASE, path), 'rb').read()
    unp, pk, _ = hrust1.header(packed)
    final, _ = hrust1.unpack(packed)
    marks = stream_positions(packed)
    end = BASE + unp                       # one past the last output byte
    moved = end - pk                       # where the block lies after the move
    s = session(args.work)

    cell, rows = 2, (HI - LO) // 256
    gx, gy = 70, 64
    grid_w, grid_h = 256 * cell, rows * cell
    sx = gx + grid_w + 250
    width, height = sx + 256 + 20, gy + max(grid_h, 192 + 170) + 70
    f, fb, fs = K.font(12), K.font(15), K.font(11)
    times = moments(t_read, t_end, args.pictures)
    # a few more pictures after the end: the result held
    times += [t_end] * 6
    pictures, durations = [], []
    previous, age = None, {}
    for i, (fr, t) in enumerate(times):
        mem = read_memory(s, fr, t)
        # output pointer: first byte from $6000 not yet final
        out = 0
        while out < unp and mem[BASE + out] == final[out]:
            out += 1
        in_place = 'moved' if (fr * FRAME_T + t) >= (t_move[0] * FRAME_T + t_move[1]) else 'read'
        if in_place == 'read':
            # how far the sectors have landed at $6000
            got = 0
            while got < len(packed) and mem[BASE + got] == packed[got]:
                got += 1
            src_lo, src_hi, consumed = BASE, BASE + got, BASE
            out = 0
        else:
            src_lo, src_hi = moved, end
            # the stream position for this much output (the first 12 bytes are the header)
            pos = 12
            for n, sp in marks:
                if n > out:
                    break
                pos = sp
            consumed = moved + pos if out else moved
        if previous is not None:
            for a in range(LO, HI):
                if mem[a] != previous[a]:
                    age[a] = 0
                elif a in age:
                    del age[a]
        previous = mem
        img = Image.new('RGB', (width, height), K.BACKGROUND)
        d = ImageDraw.Draw(img)
        d.text((10, 8), title, fill=K.TEXT, font=fb)
        phase = {'read': 'reading the sectors (TR-DOS, ROM $3D13)',
                 'moved': 'unpacking (Depack $5B00)' if out else 'the LDDR moves the block to the top'}[in_place]
        if (fr, t) == t_end:
            phase = 'done: the block unpacked at $6000'
        d.text((10, 30), f'frame {fr} T {t}:  {phase}', fill=(250, 220, 120), font=f)
        grid = Image.new('RGB', (grid_w, grid_h), K.PANEL)
        px = grid.load()
        for a in range(LO, HI):
            v = mem[a]
            if a in age:
                c = K.WRITE_FADE[age[a]]
            elif BASE <= a < BASE + out:
                c = tuple(int(g * (0.45 + 0.55 * v / 255)) for g in GREEN)
            elif src_lo <= a < src_hi and a >= consumed:
                c = tuple(int(g * (0.5 + 0.5 * v / 255)) for g in BLUE)
            elif src_lo <= a < src_hi:
                c = BLUE_DONE
            else:
                g = 30 + v * 90 // 255
                c = (g, g, g + 6)
            x, y = (a & 255) * cell, ((a - LO) >> 8) * cell
            for dy in range(cell):
                for dx in range(cell):
                    px[x + dx, y + dy] = c
        img.paste(grid, (gx, gy))
        for a in range(LO, HI, 0x1000):
            d.text((8, gy + ((a - LO) >> 8) * cell - 6), f'${a:04X}', fill=K.DIM, font=fs)

        def mark(addr, text, colour, dy=0):
            y = gy + ((min(addr, HI - 1) - LO) >> 8) * cell
            d.line((gx + grid_w + 2, y, gx + grid_w + 24, y + dy), fill=colour, width=2)
            d.text((gx + grid_w + 28, y + dy - 7), text, fill=colour, font=f)

        if in_place == 'read':
            mark(src_hi, f'read so far: $6000-${src_hi - 1:04X}', BLUE)
            mark(BASE, f'{(src_hi - BASE) // 256} of {sectors} sectors', K.DIM, -16) if src_hi > BASE else None
        else:
            mark(BASE + out, f'output (DE) ${BASE + out:04X}: {out} bytes', GREEN, -10)
            mark(consumed, f'input (stream) ${consumed:04X}', BLUE, 10)
            mark(end - 1, f'block end ${end - 1:04X}', K.DIM, 8)
            gap = consumed - (BASE + out)
            d.text((sx, gy + 330), f'input ahead of output: {gap} bytes', fill=K.TEXT, font=f)
        d.text((sx, gy + 348), f'packed {pk} -> unpacked {unp} bytes', fill=K.DIM, font=f)
        # the screen, 1x
        img.paste(K.render_screen(mem).resize((256, 192)), (sx, gy))
        d.text((sx, gy + 196), 'the screen meanwhile', fill=K.DIM, font=fs)
        # legend
        ly = gy + 230
        for c, text in ((GREEN, 'unpacked, final bytes'), (BLUE, 'packed, still to read'),
                        (BLUE_DONE, 'packed, already read'), (K.WRITE_FADE[0], 'written since the last picture'),
                        ((110, 110, 116), 'other bytes (grey = value)')):
            d.rectangle((sx, ly, sx + 12, ly + 10), fill=c)
            d.text((sx + 18, ly - 2), text, fill=K.TEXT, font=fs)
            ly += 18
        # the phase strip
        y0 = height - 52
        a0, a1 = t_read[0] * FRAME_T + t_read[1], t_end[0] * FRAME_T + t_end[1]
        x0, x1 = gx, width - 20

        def xat(ft):
            return x0 + (x1 - x0) * (ft[0] * FRAME_T + ft[1] - a0) // (a1 - a0)
        d.rectangle((x0, y0, xat(t_move), y0 + 12), fill=(50, 70, 120))
        d.rectangle((xat(t_move), y0, x1, y0 + 12), fill=(40, 100, 60))
        d.text((x0 + 4, y0 + 16), f'read {t_read[0]}-{t_move[0]}', fill=K.TEXT, font=fs)
        d.text((xat(t_move) + 4, y0 + 16), f'move + unpack {t_move[0]}-{t_end[0]}', fill=K.TEXT, font=fs)
        cx = xat((fr, t))
        d.line((cx, y0 - 4, cx, y0 + 16), fill=(255, 255, 255), width=2)
        pictures.append(img)
        durations.append(1500 if i in (0, len(times) - 1) else args.delay)
        print(f'{i:3d} {fr}:{t} out {out} in ${consumed:04X}', file=sys.stderr)
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), 'pictures', os.path.getsize(args.out), 'bytes')


if __name__ == '__main__':
    main()
