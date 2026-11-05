#!/usr/bin/env python3
"""A copy of the SCL with the saved game nether.N damaged, for the recording of a damaged load (aneD).

    python3 tools/disk_damage.py IN.scl OUT.scl

nether.N is CODE 55595 ($D92B), 9941 bytes: the game's $D92B-$FFFF as the disk module saved it. Two runs of its
bytes become $E5 (the byte TR-DOS formats a sector with, what a lost sector reads as):

- the 7 resources $FD22-$FD28 (general, electronics, nuclear, phasers, missiles, cannon, chassis; 99 = $63 and
  others in the original): every one $E5 = 229;
- 16 bytes of the map at $DD00-$DD0F (the first map row's first cells).

The SCL's closing sum (the 32-bit sum of every byte before it) is written again, so the image is a valid SCL.
"""
import struct
import sys

DAMAGE = [(0xFD22, 7), (0xDD00, 16)]
FILL = 0xE5


def main():
    src, out = sys.argv[1], sys.argv[2]
    d = bytearray(open(src, 'rb').read())
    assert d[:8] == b'SINCLAIR'
    n = d[8]
    off = 9 + 14 * n
    for i in range(n):
        h = d[9 + 14 * i:23 + 14 * i]
        start, length = struct.unpack('<HH', h[9:13])
        if h[:8] == b'nether  ' and chr(h[8]) == 'N':
            for addr, count in DAMAGE:
                assert start <= addr and addr + count <= start + length
                p = off + addr - start
                print(f'${addr:04X}-${addr + count - 1:04X} (file offset {addr - start}): '
                      f'{bytes(d[p:p + count]).hex()} -> {FILL:02x} x {count}')
                d[p:p + count] = bytes([FILL]) * count
        off += h[13] * 256
    d[-4:] = struct.pack('<I', sum(d[:-4]) & 0xFFFFFFFF)
    open(out, 'wb').write(d)


if __name__ == '__main__':
    main()
