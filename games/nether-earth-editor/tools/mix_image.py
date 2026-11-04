#!/usr/bin/env python3
"""The 64 K image kit/mkgame.py reads for nee.mix: the tape's "nee.mix" block (2244 bytes) at 50000 ($C350), zeros
elsewhere.

    python3 tools/mix_image.py ORIG.TZX OUT.bin
"""
import sys


def tzx_blocks(data):
    """The data of every standard-speed block (ID $10) of a TZX, flag and checksum included"""
    assert data[:8] == b'ZXTape!\x1a', 'not a TZX'
    i = 10
    skip = {0x20: 2, 0x22: 0}
    while i < len(data):
        kind = data[i]
        i += 1
        if kind == 0x10:
            length = data[i + 2] | data[i + 3] << 8
            yield data[i + 4:i + 4 + length]
            i += 4 + length
        elif kind in (0x30, 0x21):
            i += 1 + data[i]
        elif kind == 0x32:
            i += 2 + (data[i] | data[i + 1] << 8)
        elif kind in skip:
            i += skip[kind]
        else:
            raise SystemExit(f'TZX block ${kind:02X}: not handled')


def main():
    blocks = list(tzx_blocks(open(sys.argv[1], 'rb').read()))
    for header, body in zip(blocks, blocks[1:]):
        if len(header) == 19 and header[0] == 0 and header[2:12] == b'nee.mix   ':
            start = header[14] | header[15] << 8
            code = body[1:-1]
            image = bytearray(0x10000)
            image[start:start + len(code)] = code
            open(sys.argv[2], 'wb').write(image)
            return
    raise SystemExit('no "nee.mix" block')


if __name__ == '__main__':
    main()
