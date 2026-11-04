#!/usr/bin/env python3
"""The blocks of a TAP file: list them, or write the data of one (no flag byte, no checksum) after checking it.

    python3 tapblocks.py list FILE.tap                # index, length, ROM-speed time, header fields, checksum
    python3 tapblocks.py FILE.tap INDEX OUT.bin       # INDEX counts every block, headers included (0-based)
"""
import sys

KINDS = {0: 'Program', 1: 'Number array', 2: 'Character array', 3: 'Bytes'}


def raw_blocks(tap):
    """(offset, flag, data without flag and checksum, checksum ok)"""
    i = 0
    while i + 2 <= len(tap):
        length = tap[i] | tap[i + 1] << 8
        body = tap[i + 2:i + 2 + length]
        checksum = 0
        for b in body:
            checksum ^= b
        yield i, body[0] if body else None, body[1:-1], checksum == 0 and len(body) == length
        i += 2 + length


def blocks(tap):
    for offset, _flag, data, ok in raw_blocks(tap):
        if not ok:
            raise SystemExit(f'block at {offset}: bad checksum')
        yield data


def rom_seconds(flag, data, checksum_byte=0):
    """The block's play time at ROM speed (pilot, sync, the bits of flag, data and checksum; no pause)"""
    pilot = (8063 if (flag or 0) < 128 else 3223) * 2168 + 667 + 735
    ones = sum(bin(b).count('1') for b in [flag or 0, *data, checksum_byte])
    bits = 8 * (len(data) + 2)
    return (pilot + ones * 2 * 1710 + (bits - ones) * 2 * 855) / 3500000


def describe(flag, data):
    if flag == 0 and len(data) == 17:
        kind = KINDS.get(data[0], f'type {data[0]}')
        name = data[1:11].decode('latin-1').rstrip()
        length, p1, p2 = (int.from_bytes(data[k:k + 2], 'little') for k in (11, 13, 15))
        if data[0] == 0:
            return f'header {kind} "{name}" length {length}' + (f' LINE {p1}' if p1 < 32768 else '') + f' vars {p2}'
        return f'header {kind} "{name}" length {length} start {p1} (${p1:04X})' + (f' param2 {p2}' if data[0] == 3 else '')
    return f'data, flag ${flag:02X}' if flag is not None else 'empty'


def main():
    if len(sys.argv) == 3 and sys.argv[1] == 'list':
        tap = open(sys.argv[2], 'rb').read()
        total = 0.0
        for index, (offset, flag, data, ok) in enumerate(raw_blocks(tap)):
            seconds = rom_seconds(flag, data, tap[offset + 2 + len(data) + 1] if ok else 0)
            total += seconds
            print(f'{index:3}  offset {offset:6}  {len(data):6} bytes  {seconds:6.1f} s  {describe(flag, data)}'
                  f'{"" if ok else "  BAD CHECKSUM"}')
        print(f'total {total:.1f} s at ROM speed ({round(total * 3500000 / 69888)} 48K frames), pauses not included')
        return
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    data = list(blocks(open(sys.argv[1], 'rb').read()))[int(sys.argv[2])]
    open(sys.argv[3], 'wb').write(data)


if __name__ == '__main__':
    main()
