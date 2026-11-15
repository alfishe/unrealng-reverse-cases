#!/usr/bin/env python3
"""The images of MASK III as the tape loader leaves them, cut from the original tape (orig/MASKIII-VENOMStrikesBack.tzx.zip).

    python3 tools/image.py OUT.bin            # the 64 K image: screen at $4000, code at $6000-$FDFF, zero elsewhere
    python3 tools/image.py OUT.bin --bank4    # the 128K block: 4000 bytes at $C000 in RAM 4 (16 K, zero after)
    python3 tools/image.py OUT.bin --block N  # TZX block N's data alone, flag and checksum removed
    python3 tools/image.py OUT.bin --basic    # a 64 K image with block 2 (the BASIC) at PROG $5CCB, zero elsewhere
    python3 tools/image.py OUT.tzx --tzx      # the original TZX as orig/ holds it ("Mask III.tzx")

TZX blocks (tools/tzxblocks.py list): 5 the loading screen (6912 bytes at $4000), 6 the code (40448 bytes at $6000,
loaded by the loader at $5E00 with the ROM's LD-BYTES), 7 the 128K block (4000 bytes, loaded only on a 128K into
RAM 4 at $C000). The loader itself is block 4 (256 bytes at $FF00, run at $5E00).
"""
import argparse
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402

ORIG = os.path.join(HERE, '..', 'orig', 'MASKIII-VENOMStrikesBack.tzx.zip')
MEMBER = 'Mask III.tzx'


def blocks():
    with zipfile.ZipFile(ORIG) as z:
        return list(tzxblocks.parse(z.read(MEMBER)))


def image():
    b = blocks()
    mem = bytearray(65536)
    mem[0x4000:0x5B00] = b[5]['data'][1:-1]
    code = b[6]['data'][1:-1]
    mem[0x6000:0x6000 + len(code)] = code
    return bytes(mem)


def bank4():
    data = blocks()[7]['data'][1:-1]
    return data + bytes(16384 - len(data))


def original_tzx():
    with zipfile.ZipFile(ORIG) as z:
        return z.read(MEMBER)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--bank4', action='store_true')
    ap.add_argument('--block', type=int)
    ap.add_argument('--basic', action='store_true')
    ap.add_argument('--tzx', action='store_true')
    a = ap.parse_args()
    if a.tzx:
        data, what = original_tzx(), 'the original TZX'
    elif a.block is not None:
        data = blocks()[a.block]['data'][1:-1]
        what = f'block {a.block}, {len(data)} bytes'
    elif a.basic:
        prog = blocks()[2]['data'][1:-1]
        mem = bytearray(65536)
        mem[0x5CCB:0x5CCB + len(prog)] = prog
        data, what = bytes(mem), f'the BASIC, {len(prog)} bytes at $5CCB'
    elif a.bank4:
        data, what = bank4(), 'RAM 4, 4000 bytes at $C000'
    else:
        data, what = image(), 'code $6000-$FDFF (40448 bytes), screen $4000'
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    open(a.out, 'wb').write(data)
    print(f'{a.out}: {what}')


if __name__ == '__main__':
    main()
