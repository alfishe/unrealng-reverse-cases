#!/usr/bin/env python3
"""The 48K memory of a .szx snapshot ($4000-$FFFF from its RAMP blocks: page 5 at $4000, 2 at $8000, 0 at $C000),
and the runs where two memories differ: the image as loaded against a state of the game.

    python3 tools/szxmem.py diff work/mkgame/original.bin work/snaps/ready.szx [--min-gap 8] [--from 8000]

A .bin argument is a 64K image (tools/image.py); a .szx or an uncompressed v1 .z80 (tools/moment_snapshot.py) is
read here.
"""
import argparse
import struct
import zlib

PAGES = {5: 0x4000, 2: 0x8000, 0: 0xC000}


def szx_memory(path):
    data = open(path, 'rb').read()
    if data[:4] != b'ZXST':
        raise SystemExit(f'{path}: not a .szx')
    mem = bytearray(0x10000)
    at = 8
    while at + 8 <= len(data):
        tag, size = data[at:at + 4], struct.unpack_from('<I', data, at + 4)[0]
        body = data[at + 8:at + 8 + size]
        if tag == b'RAMP':
            flags, page = struct.unpack_from('<HB', body)
            raw = zlib.decompress(body[3:]) if flags & 1 else body[3:]
            if page in PAGES:
                mem[PAGES[page]:PAGES[page] + 0x4000] = raw[:0x4000]
        at += 8 + size
    return bytes(mem)


def memory(path):
    if path.endswith('.szx'):
        return szx_memory(path)
    if path.endswith('.z80'):
        # only the uncompressed v1 files tools/moment_snapshot.py writes: a 30-byte header, then $4000-$FFFF
        data = open(path, 'rb').read()
        if len(data) != 30 + 0xC000:
            raise SystemExit(f'{path}: not an uncompressed v1 .z80')
        return bytes(0x4000) + data[30:]
    m = open(path, 'rb').read()
    return m + bytes(0x10000 - len(m))


def diff_runs(a, b, lo, hi, gap):
    runs, start, last = [], None, None
    for i in range(lo, hi + 1):
        if a[i] != b[i]:
            if start is None:
                start = i
            elif i - last > gap:
                runs.append((start, last))
                start = i
            last = i
    if start is not None:
        runs.append((start, last))
    return runs


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    d = sub.add_parser('diff')
    d.add_argument('a')
    d.add_argument('b')
    d.add_argument('--min-gap', type=int, default=8, help='runs closer than this many bytes are joined')
    d.add_argument('--from', dest='lo', default='4000')
    d.add_argument('--to', dest='hi', default='FFFF')
    args = p.parse_args()
    a, b = memory(args.a), memory(args.b)
    total = 0
    for s, e in diff_runs(a, b, int(args.lo, 16), int(args.hi, 16), args.min_gap):
        n = sum(a[i] != b[i] for i in range(s, e + 1))
        total += n
        print(f'${s:04X}-${e:04X} {e - s + 1:6} bytes, {n:5} differ')
    print(f'total {total} bytes differ')


if __name__ == '__main__':
    main()
