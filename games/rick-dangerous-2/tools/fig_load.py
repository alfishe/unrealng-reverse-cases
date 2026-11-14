#!/usr/bin/env python3
"""The figures of doc 03 (build and load): the two tape sides as a picture, and the bit reversal of one byte.

    python3 tools/fig_load.py tape docs/img/load/tape.png
    python3 tools/fig_load.py reversal docs/img/load/reversal.png

tape: build/side-a.tzx and build/side-b.tzx (identical to the original, tools/build.sh), each block a bar as long as
its time on the tape (tools/tzxblocks.py), the pause after it in grey; under each data block where it loads, and the
loading screen (src/screen) as a thumbnail over block A 5. reversal: the first bytes of side A block 6 as they are
on the tape and as the loader stores them at `$6000`, bit by bit.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402
import tzxblocks as T  # noqa: E402
import zxscreen  # noqa: E402

W = 1050
BG, TEXT, DIM = K.BACKGROUND, K.TEXT, K.DIM
COL = K.ROUTINE_COLOURS

A_INFO = {1: ('header "RICK-II"', '', 8), 2: ('BASIC', 'program area', 3), 3: ('header "loader"', '', 8),
          4: ('loader, XOR $5C', '$FF00-$FFFF', 0), 5: ('screen, bit-reversed', '$4000-$5AFF', 2),
          6: ('code, bit-reversed', '$6000-$FEFD', 1)}
B_NAMES = ['level 1', 'level 2', 'level 3', 'level 4', 'level 5']


def blocks(path):
    out = []
    for b in T.parse(open(path, 'rb').read()):
        if b.get('kind') == 'standard':
            out.append((b, T.seconds(b), b['pause'] / 1000.0))
    return out


def fig_tape(out):
    a = blocks(os.path.join(CASE, 'build', 'side-a.tzx'))
    b = blocks(os.path.join(CASE, 'build', 'side-b.tzx'))
    total_b = sum(s + p for _, s, p in b)
    x0, x1 = 20, W - 20
    scale = (x1 - x0) / total_b  # one scale for both sides
    img = Image.new('RGB', (W, 540), BG)
    d = ImageDraw.Draw(img)
    f, fs = K.font(13), K.font(12)
    d.text((12, 10), 'The tape: side A loads the game and level 1, side B holds the five levels', font=K.font(18), fill=TEXT)
    d.text((12, 36), 'one scale for both sides: bar length = time on the tape (block coloured, pause after it grey); '
           'from build/side-a.tzx, side-b.tzx', font=fs, fill=DIM)

    def side(blks, y, info, title):
        d.text((x0, y - 22), title, font=f, fill=TEXT)
        x = x0
        for k, (blk, s, p) in enumerate(blks, 1):
            name, where, c = info(k)
            w = s * scale
            d.rectangle((x, y, x + w, y + 34), fill=COL[c])
            d.rectangle((x + w, y + 12, x + w + p * scale, y + 22), fill=(60, 60, 70))
            yield k, blk, s, p, x, w, name, where
            x += w + p * scale
        d.text((x0 + 160, y - 22), 'total %.1f s with the pauses' % sum(s + p for _, s, p in blks), font=f, fill=TEXT)

    # side A
    ya = 110
    labels = []
    for k, blk, s, p, x, w, name, where in side(a, ya, lambda k: A_INFO[k], 'side A: %d blocks' % len(a)):
        labels.append((x, w, '%d %s' % (k, name), '%d bytes, %.1f s%s' % (len(blk['data']) - 2, s, (', ' + where) if where else '')))
    lx, ly = 480, ya - 40
    for i, (x, w, l1, l2) in enumerate(labels):
        k = i + 1
        d.rectangle((lx, ly + i * 22 + 3, lx + 12, ly + i * 22 + 15), fill=COL[A_INFO[k][2]])
        d.text((lx + 18, ly + i * 22), '%s: %s' % (l1, l2), font=fs, fill=TEXT)
        if w >= 40:
            d.text((x + 5, ya + 9), str(k), font=f, fill=BG)
    d.text((x0, ya + 40), 'blocks 1-4: the thin bars at the left, %.1f s with their pauses' % sum(s + p for _, s, p in a[:4]), font=fs, fill=DIM)
    # the loading screen under block 5
    scr = open(os.path.join(CASE, 'build', 'screen.bin'), 'rb').read()[:6912]
    thumb = zxscreen.render(scr, 1).convert('RGB').resize((128, 96))
    bx = int(labels[4][0])
    img.paste(thumb, (bx, ya + 70))
    d.line((bx + 20, ya + 34, bx + 20, ya + 70), fill=DIM)
    d.text((bx + 140, ya + 110), 'block A 5 on the screen while block A 6 loads', font=fs, fill=DIM)
    # side B
    yb = 380
    for k, blk, s, p, x, w, name, where in side(b, yb, lambda k: (B_NAMES[k - 1], '$A800-$FCFF', 4 + k), 'side B: %d blocks' % len(b)):
        d.text((x + 6, yb + 9), '%s' % name, font=f, fill=BG)
        d.text((x + 2, yb + 42), '%d bytes, %.1f s' % (len(blk['data']) - 2, s), font=fs, fill=DIM)
    d.text((x0, yb + 64), 'each level block: 21 760 bytes at $A800, bit-reversed, the maps\' last 768 bytes enciphered; '
           'read by LoadLevel $840C', font=fs, fill=DIM)
    img.save(out)
    print(out, img.size)


def rev(x):
    return int('{:08b}'.format(x)[::-1], 2)


def fig_reversal(out):
    a = blocks(os.path.join(CASE, 'build', 'side-a.tzx'))
    data = a[5][0]['data']
    tape = data[1:5]
    img = Image.new('RGB', (W, 330), BG)
    d = ImageDraw.Draw(img)
    f, fs = K.font(14), K.font(13)
    d.text((12, 10), 'The bit reversal: the loader shifts each bit in from the top, so every byte is stored mirrored',
           font=K.font(17), fill=TEXT)
    d.text((12, 36), 'side A block 6, its first four data bytes (after the flag): on the tape, and at $6000-$6003 '
           'after the loader', font=fs, fill=DIM)
    cw, x0 = 26, 30
    for i, t in enumerate(tape):
        m = rev(t)
        bx = x0 + i * 250
        d.text((bx, 70), 'byte %d: $%02X on the tape' % (i, t), font=f, fill=TEXT)
        for q in range(8):
            bit = (t >> (7 - q)) & 1
            d.rectangle((bx + q * cw, 96, bx + q * cw + cw - 3, 96 + cw), fill=COL[2] if bit else (50, 50, 60))
            d.text((bx + q * cw + 8, 100), str(bit), font=fs, fill=BG if bit else TEXT)
        for q in range(8):
            bit = (m >> (7 - q)) & 1
            d.line((bx + (7 - q) * cw + cw // 2, 96 + cw, bx + q * cw + cw // 2, 180), fill=DIM)
            d.rectangle((bx + q * cw, 180, bx + q * cw + cw - 3, 180 + cw), fill=COL[1] if bit else (50, 50, 60))
            d.text((bx + q * cw + 8, 184), str(bit), font=fs, fill=BG if bit else TEXT)
        d.text((bx, 216), '$%04X = $%02X in memory' % (0x6000 + i, m), font=f, fill=TEXT)
    d.text((x0, 256), 'The ROM: LD L,$01 ... RL L, the first bit on the tape becomes bit 7.', font=fs, fill=DIM)
    d.text((x0, 276), 'The loader: LD L,$80 ... RR L ($FF9A, $FFA3), the first bit on the tape becomes bit 0.', font=fs, fill=DIM)
    d.text((x0, 296), 'The checksum byte is mirrored too: the XOR of a block\'s bytes is $FF, not $00, so the ROM '
           'refuses the block.', font=fs, fill=DIM)
    img.save(out)
    print(out, img.size, [hex(x) for x in tape], [hex(rev(x)) for x in tape])


if __name__ == '__main__':
    what, out = sys.argv[1], sys.argv[2]
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    {'tape': fig_tape, 'reversal': fig_reversal}[what](out)
