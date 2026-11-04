#!/usr/bin/env python3
"""Write a TAP file of standard ROM blocks: a header and a data block for each part.

    python3 tap.py OUT.tap basic:NAME:LINE:FILE code:NAME:ADDRESS:FILE[:PARAM2] data:-:-:FILE ...

`data` is a headerless block (flag $FF), for a loader that reads it with its own LD-BYTES.

PARAM2 of a CODE header defaults to 32768, as the ROM's SAVE ... CODE writes it.
"""
import sys


def block(flag, data):
    body = bytes([flag]) + data
    checksum = 0
    for b in body:
        checksum ^= b
    body += bytes([checksum])
    return len(body).to_bytes(2, 'little') + body


def header(kind, name, length, param1, param2):
    return bytes([kind]) + name.encode('ascii').ljust(10)[:10] + length.to_bytes(2, 'little') + \
        param1.to_bytes(2, 'little') + param2.to_bytes(2, 'little')


def main():
    out = bytearray()
    for part in sys.argv[2:]:
        kind, name, param, path, *rest = part.split(':')
        data = open(path, 'rb').read()
        if kind == 'data':
            out += block(0xFF, data)
            continue
        if kind == 'basic':
            # param 1: the autostart line; param 2: the program length (no variables)
            out += block(0, header(0, name, len(data), int(param, 0), len(data)))
        else:
            out += block(0, header(3, name, len(data), int(param, 0), int(rest[0], 0) if rest else 32768))
        out += block(0xFF, data)
    open(sys.argv[1], 'wb').write(out)


if __name__ == '__main__':
    main()
