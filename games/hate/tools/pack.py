#!/usr/bin/env python3
"""Pack an image the way the packer of CODE "H_A_T_E.2" did; the inverse of depack.py, byte for byte.

The packer walks the image forwards. A run of three or more equal bytes becomes a token, longer runs become several:
zeros take 256 at a time while 256 remain (count byte $80), then at most 127; other bytes at most 127. A remainder
shorter than three stays literal. A literal $97 (the marker) is escaped as N|$80, $97.

    python3 pack.py unpacked.bin packed.bin [--from 5FB4]
"""
import argparse

MARKER = 0x97


def pack(data):
    out = bytearray()
    i = 0
    while i < len(data):
        v = data[i]
        j = i
        while j < len(data) and data[j] == v:
            j += 1
        n = j - i
        while n >= 3:
            if v == 0:
                take = 256 if n >= 256 else min(n, 127)
                out += bytes([(take & 0x7F) | 0x80, MARKER])
            else:
                take = min(n, 127)
                out += bytes([v, take, MARKER])
            n -= take
        for _ in range(n):
            out += bytes([0x81, MARKER]) if v == MARKER else bytes([v])
        i = j
    return bytes(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('image')
    p.add_argument('packed')
    p.add_argument('--from', dest='start', default='5FB4', help='first address of the image to pack (hex)')
    args = p.parse_args()
    image = open(args.image, 'rb').read()
    start = int(args.start, 16)
    open(args.packed, 'wb').write(pack(image[start:0x10000] if len(image) == 0x10000 else image))


if __name__ == '__main__':
    main()
