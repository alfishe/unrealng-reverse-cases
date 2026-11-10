#!/usr/bin/env python3
"""SimCity's SAVE CITY as a TAP file, from memory at the moment of the save: the game writes two headerless ROM
blocks with flag `$FF` (code at `$9E36-$9E52`, ROM SA-BYTES entered at `$04C6`): `$1F` bytes from `$A930` (the
12-byte file name, the 7 bytes copied from `$8F97`, the 12 bytes copied from `$5F68`), then the city map, `$2400`
bytes from `$C450`. The emulator has no tape recorder, so the blocks are rebuilt from memory; LOAD CITY reads them
back with ROM LD-BYTES (`$0562`) at `$9E8A-$9ED6`.

    python3 tools/savetap.py out.tap --port-base 37030       # from a running Lab instance
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def block(data, flag=0xFF):
    b = bytes([flag]) + bytes(data)
    x = 0
    for v in b:
        x ^= v
    b += bytes([x])
    return len(b).to_bytes(2, 'little') + b


def tap_from(read):
    return block(read(0xA930, 0x1F)) + block(read(0xC450, 0x2400))


if __name__ == '__main__':
    from lab import Lab
    pb = int(sys.argv[sys.argv.index('--port-base') + 1]) if '--port-base' in sys.argv else 37030
    lab = Lab(pb, attach=True)
    open(sys.argv[1], 'wb').write(tap_from(lab.read))
    lab.close()
