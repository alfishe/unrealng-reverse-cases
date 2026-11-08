#!/usr/bin/env python3
"""The load as pictures, from the tape alone (docs/03-build-and-load.md 3.5-3.8): no emulator, the steps of
tools/image.py drawn one by one.

    python3 tools/fig_load.py [--side A]

Figures (docs/img/load/):
- memory.gif: the 64 K address space (one row of 256 bytes a pixel row, $0000 at the top) as the load fills it:
  the turbo block, then each of the 14 chunks at the address it lands at (the reader's patches shift the chunks
  after TZX block 17 by +256 and those after block 31 by -256: the picture shows the landing address, not the one
  the chunk header claims), the decryptor's pass from $D0A8 down, the two ROM blocks and the kickoff's copy.
  A byte's grey is its value; the bytes of the step flash yellow and fade through red over the next steps.
- screen.gif: the screen while the turbo block loads ($4000 up, 256 bytes a picture), as the television showed it
  (the BASIC's CLS left black on black, so the picture appears only with its attributes) and the pixels alone.
- decrypt.png: the decryptor's input, key and output over $6049-$D0A8 as three bitmaps of 256 bytes a row: the
  encrypted bytes, the key (the screen and the 48K ROM read from $5AFF down) and the plain game.
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import elitelib as E  # noqa: E402
import image as I  # noqa: E402
import rtplot as P  # noqa: E402
import softlock as S  # noqa: E402
import kitlib as K  # noqa: E402
import zxscreen  # noqa: E402

OUT = os.path.join(E.CASE, 'docs', 'img', 'load')
FADE = [(255, 255, 140), (255, 210, 70), (245, 140, 45), (210, 80, 40), (160, 50, 50), (115, 40, 60)]
TRAIL = (80, 34, 52)
TZX_OF_CHUNK = [7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33]


def grid_picture(mem, age, label, scale=2):
    """mem: 64 K bytes, age: per byte the steps since it was written (-1 never)"""
    v = np.frombuffer(bytes(mem), dtype=np.uint8).reshape(256, 256)
    a = np.array(age).reshape(256, 256)
    img = np.zeros((256, 256, 3), dtype=np.uint8)
    g = (40 + v.astype(int) * 150 // 255).astype(np.uint8)
    img[..., 0] = img[..., 1] = img[..., 2] = g
    img[a < 0] = (24, 24, 32)
    for k, c in enumerate(FADE):
        img[a == k] = c
    old = a >= len(FADE)
    img[old] = (np.array(TRAIL) * 0.5 + img[old] * 0.5).astype(np.uint8)
    pic = Image.fromarray(img).resize((256 * scale, 256 * scale), Image.NEAREST)
    W = 256 * scale + 400
    big, small = K.font(17), K.font(15)
    im = Image.new('RGB', (W, 256 * scale + 80), (14, 14, 20))
    im.paste(pic, (0, 52))
    d = ImageDraw.Draw(im)
    d.text((6, 6), label, fill=(210, 210, 220), font=big)
    d.text((6, 30), 'one pixel a byte, 256 a row, $0000 at the top; grey: the value; yellow: written now, fading',
           fill=(150, 150, 165), font=small)
    d.text((6, 256 * scale + 58), 'through orange and red over the next steps; dark: not yet written',
           fill=(150, 150, 165), font=small)
    below = 52                              # under the subtitle
    for addr, name in ((0x0000, 'ROM'), (0x4000, 'screen $4000'), (0x5B00, '$5B00 reader / low data'),
                       (0x6049, '$6049 encrypted game'), (0xC000, '$C000 Lenslok / back buffer'),
                       (0xD0A8, '$D0A8 cipher end; ROM block 36 at $D0BA'),
                       (0xFF00, '$FF00 the loader')):
        y = 52 + (addr >> 8) * scale
        ty = max(y - 8, below)              # pushed down clear of the label above
        d.line([(256 * scale, y), (256 * scale + 8, y), (256 * scale + 12, ty + 8)], fill=(150, 150, 165))
        d.text((256 * scale + 16, ty), name, fill=(150, 150, 165), font=small)
        below = ty + 18
    return im


def memory_gif(side):
    rom = open(os.path.join(E.K.unreal_root(), 'data', 'rom', '48.rom'), 'rb').read()
    mem = bytearray(0x10000)
    mem[0:0x4000] = rom
    age = [-1] * 0x10000
    for i in range(0x4000):
        age[i] = 99
    pictures = []

    def step(addrs, label):
        for i in range(0x10000):
            if age[i] >= 0:
                age[i] += 1
        for x in addrs:
            age[x] = 0
        pictures.append(grid_picture(mem, age, label))

    turbo = S.stream(side)[0][2][1:1 + 0x1C00]
    mem[0x4000:0x5C00] = turbo
    step(range(0x4000, 0x5C00), 'TZX block 5 (turbo): the loading screen and the chunk reader, $4000-$5BFF')
    for k, (at, d) in enumerate(I.land(side)):
        span = [(at + i) & 0xFFFF for i in range(len(d)) if (at + i) & 0xFFFF >= 0x4000]
        for i, b in enumerate(d):
            if (at + i) & 0xFFFF >= 0x4000:
                mem[(at + i) & 0xFFFF] = b
        step(span, 'chunk %d (TZX block %d): %d bytes at $%04X' % (k + 1, TZX_OF_CHUNK[k], len(d), at))
    # the decryptor, top down, in 8 steps
    pairs = list(zip(range(0xD0A8, 0xD0A8 - 0x7060, -1), I.key_addresses(0x7060)))
    n = len(pairs)
    for s in range(8):
        part = pairs[s * n // 8:(s + 1) * n // 8]
        for addr, ix in part:
            mem[addr] = I.rlc(((mem[addr] - mem[ix]) & 0xFF) ^ (I.IY & 0xFF)) ^ (I.IY >> 8)
        step([a for a, _ in part], 'the decryptor $5B00: $%04X down to $%04X (%d of 8)' % (part[0][0], part[-1][0],
                                                                                           s + 1))
    for at, d in I.rom_blocks(side):
        mem[at:at + len(d)] = d
        step(range(at, at + len(d)), 'ROM block (LD-BLOCK): %d bytes at $%04X' % (len(d), at))
    mem[0xC000:0xC800] = mem[0xC800:0xD000]
    for nn in range(256):
        mem[0xBE00 + nn], mem[0xBF00 + nn] = (nn * nn) & 0xFF, (nn * nn) >> 8
    step(list(range(0xC000, 0xC800)) + list(range(0xBE00, 0xC000)),
         'the kickoff ($D05F, its last step $D07F): $C800-$CFFF copied to $C000, the squares at $BE00 / $BF00')
    for _ in range(4):
        step([], 'the image at $70E0, the game\'s entry (tools/image.py --stage entry)')
    ref = I.build(side)
    assert bytes(mem[0x5B00:0xFFA8]) == bytes(ref[0x5B00:0xFFA8])
    os.makedirs(OUT, exist_ok=True)
    pictures[0].save(os.path.join(OUT, 'memory.gif'), save_all=True, append_images=pictures[1:], duration=700,
                     loop=0)
    print('wrote docs/img/load/memory.gif (%d pictures)' % len(pictures))


def screen_gif(side):
    """the screen as the turbo block fills it; the BASIC's CLS left PAPER 0 INK 0 (3.2), so a pixel row shows only once
    its attribute row has loaded: the left panel is the television, the right one the pixels alone"""
    turbo = S.stream(side)[0][2][1:1 + 0x1C00]
    pictures = []
    big, small = K.font(19), K.font(17)
    for n in list(range(256, 0x1B00, 256)) + [0x1B00]:
        scr = bytearray(0x1B00)
        scr[0:n] = turbo[0:n]
        tv = zxscreen.render(bytes(scr), scale=2)
        bare = bytearray(scr[0:0x1800]) + bytes([0x07]) * 0x300
        px = zxscreen.render(bytes(bare), scale=2)
        canvas = Image.new('RGB', (tv.width * 2 + 16, tv.height + 60), (14, 14, 20))
        canvas.paste(tv, (0, 60))
        canvas.paste(px, (tv.width + 16, 60))
        d = ImageDraw.Draw(canvas)
        d.text((6, 6), 'TZX block 5: %d of 6912 screen bytes loaded ($4000-$%04X)%s' % (
            n, 0x4000 + n - 1, ', the attributes arriving' if n > 0x1800 else ''), fill=(210, 210, 220), font=big)
        d.text((6, 32), 'the television (the BASIC left PAPER 0 INK 0)', fill=(150, 150, 165), font=small)
        d.text((tv.width + 22, 32), 'the pixels alone (white ink)', fill=(150, 150, 165), font=small)
        pictures.append(canvas)
    pictures += [pictures[-1]] * 6
    pictures[0].save(os.path.join(OUT, 'screen.gif'), save_all=True, append_images=pictures[1:], duration=150,
                     loop=0)
    print('wrote docs/img/load/screen.gif (%d pictures)' % len(pictures))


def decrypt_png(side):
    pre = bytearray(0x10000)
    rom = open(os.path.join(E.K.unreal_root(), 'data', 'rom', '48.rom'), 'rb').read()
    pre[0:0x4000] = rom
    pre[0x4000:0x5C00] = S.stream(side)[0][2][1:1 + 0x1C00]
    for at, d in I.land(side):
        for i, b in enumerate(d):
            if (at + i) & 0xFFFF >= 0x4000:
                pre[(at + i) & 0xFFFF] = b
    plain = I.build(side, 'prekick')
    lo, hi = 0x6000, 0xD100
    rows = (hi - lo) // 256
    enc = np.frombuffer(bytes(pre[lo:hi]), dtype=np.uint8).reshape(rows, 256)
    key = np.zeros((rows, 256), dtype=np.uint8)
    for addr, ix in zip(range(0xD0A8, 0xD0A8 - 0x7060, -1), I.key_addresses(0x7060)):
        key[(addr - lo) // 256, (addr - lo) % 256] = pre[ix]
    out = np.frombuffer(bytes(plain[lo:hi]), dtype=np.uint8).reshape(rows, 256)
    fig, axes = P.figure(14, 7.2, nrows=1, ncols=3)
    for ax, m, title in ((axes[0], enc, 'what the chunks land (encrypted): noise, except\nwhere a run of equal key bytes lets the plain show'),
                         (axes[1], key, 'the key byte of each address:\nthe screen and the ROM from $5AFF down'),
                         (axes[2], out, 'after the decryptor: the game (tables and\nzero runs; $C800-$CFFF what the kickoff copies to $C000)')):
        ax.imshow(m, cmap='gray', interpolation='nearest', extent=(0, 256, hi, lo), aspect='auto')
        ax.set_title(title, fontsize=10)
        ax.set_xlabel('the byte\'s low address byte')
        ax.set_yticks(range(lo, hi + 1, 0x1000))
        ax.set_yticklabels(['$%04X' % a for a in range(lo, hi + 1, 0x1000)], fontsize=8)
        ax.axhline(0x6049, color=P.WRITE, lw=1.4)
        ax.axhline(0xD0A9, color=P.WRITE, lw=1.4)
    fig.suptitle('The decryptor at $5B00 over $6049-$D0A8 (between the yellow lines): plain = RLC((byte - key) XOR $6D)'
                 ' XOR $2E, the key the bytes from $5AFF down', fontsize=11)
    fig.tight_layout()
    P.save(fig, 'docs/img/load/decrypt.png')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--side', default='A')
    a = ap.parse_args()
    memory_gif(a.side)
    screen_gif(a.side)
    decrypt_png(a.side)


if __name__ == '__main__':
    main()
