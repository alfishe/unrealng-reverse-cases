#!/usr/bin/env python3
"""Write the data of one block of a TAP file (no flag byte, no checksum) and check its checksum.

    python3 tapblocks.py FILE.tap INDEX OUT.bin       # INDEX counts every block, headers included (0-based)
"""
import sys


def blocks(tap):
    i = 0
    while i < len(tap):
        length = tap[i] | tap[i + 1] << 8
        body = tap[i + 2:i + 2 + length]
        checksum = 0
        for b in body:
            checksum ^= b
        if checksum:
            raise SystemExit(f'block at {i}: bad checksum')
        yield body[1:-1]
        i += 2 + length


def main():
    data = list(blocks(open(sys.argv[1], 'rb').read()))[int(sys.argv[2])]
    open(sys.argv[3], 'wb').write(data)


if __name__ == '__main__':
    main()
