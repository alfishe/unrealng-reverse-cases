#!/usr/bin/env python3
"""Write a TAP file of standard ROM blocks: a header and a data block for each part.

    python3 tap.py OUT.tap basic:NAME:LINE:FILE[:PROGRAM] code:NAME:ADDRESS:FILE[:PARAM2] data:-:-:FILE ...

`data` is a headerless block (flag $FF), for a loader that reads it with its own LD-BYTES.

PROGRAM, parameter 2 of a BASIC header, is the length of the program without its variables. By default it is found
as the ROM's SAVE writes it: the program's lines are walked (a line starts with its number, high byte first, below
$40) and the variables area is what follows them (its first byte is a letter code, $40 or more), so a block that
carries a variables area (an array that holds a loader) gets the right header; a line whose length runs past the
block (a protection's line 0 of length $FFFF) makes the whole block the program. PROGRAM given overrides it.
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


def program_length(data):
    """The length of a BASIC block's program without its variables (VARS - PROG, as SAVE writes parameter 2): the
    lines run while the next byte is a line number's high byte (below $40). A line whose length runs past the block
    (a protection's line 0 of length $FFFF) holds the rest of it: the whole block is the program"""
    at = 0
    while at + 4 <= len(data) and data[at] < 0x40:
        at += 4 + int.from_bytes(data[at + 2:at + 4], 'little')
    return min(at, len(data))


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
            program = int(rest[0], 0) if rest else program_length(data)
            out += block(0, header(0, name, len(data), int(param, 0), program))
        else:
            out += block(0, header(3, name, len(data), int(param, 0), int(rest[0], 0) if rest else 32768))
        out += block(0xFF, data)
    open(sys.argv[1], 'wb').write(out)


if __name__ == '__main__':
    main()
