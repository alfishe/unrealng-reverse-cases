#!/usr/bin/env python3
"""Unpack the loading screen of CODE "H_A_T_E.1" the way its code at $9C40 does.

The block is position independent: its header (IY = base + 2) holds the picture number, the first third, the
number of thirds and the flags; the pictures follow at base + 2 + $12A, each with a length word. A picture's
header always holds the first third, the thirds and the flags; the block's header takes the first two from it where it holds $FF. Flag bit 0 picks the
order of the bitmap bytes: set, by pixel lines across (32 bytes a line); clear, by columns down. The attributes of
the same thirds follow. Bytes are RLE: 00 N V is N copies of V (0 means 256), any other byte is itself.

    python3 screen_depack.py code1.bin screen.scr [--base 9C40]
"""
import argparse


def depack(block, base=0x9C40):
    iy = 2
    number, first, thirds = block[iy], block[iy + 1], block[iy + 2]
    hl = iy + 0x12A
    for _ in range(number - 1):
        hl += block[hl] | block[hl + 1] << 8
    hl += 2
    if first == 0xFF:
        first = block[hl]
    hl += 1                         # the picture always holds both bytes; $FF in the parameters takes them
    if thirds == 0xFF:
        thirds = block[hl]
    hl += 1
    flags = block[hl]
    hl += 1
    first = first if first < 3 else 0
    thirds = thirds if thirds < 4 else 1
    if first + thirds >= 4 or thirds == 0:
        thirds = 1
    screen = bytearray(6912)
    run = {'left': 0, 'value': 0, 'on': bool(flags & 4)}
    src = [hl]

    def byte():
        if run['on']:
            run['left'] = (run['left'] - 1) & 0xFF
            if run['left']:
                return run['value']
            run['on'] = False
        a = block[src[0]]
        src[0] += 1
        if a:
            return a
        run['left'], run['value'], run['on'] = block[src[0]], block[src[0] + 1], True
        src[0] += 2
        return run['value']

    across = bool(flags & 1)
    outer, inner = (1, 32) if across else (32, 1)
    for column in range(outer):
        for third in range(thirds):
            for row in range(8):
                for line in range(8):
                    address = (first + third) * 0x800 + line * 0x100 + row * 32 + column
                    for i in range(inner):
                        screen[address + i] = byte()
    for i in range(thirds * 256):
        screen[0x1800 + first * 256 + i] = byte()
    return screen, src[0], (first, thirds, flags)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('block')
    p.add_argument('screen')
    args = p.parse_args()
    block = open(args.block, 'rb').read()
    screen, end, header = depack(block)
    print(f'thirds {header[0]}+{header[1]}, flags ${header[2]:02X}, packed data ends at +${end:04X} of ${len(block):04X}')
    open(args.screen, 'wb').write(screen)


if __name__ == '__main__':
    main()
