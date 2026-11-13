#!/usr/bin/env python3
"""Write the tape of Deflektor from the built parts, as orig/Deflektor.tzx.zip holds it (tools/build.sh):

    python3 tools/mktape.py src/tape/tape.txt OUT.tzx BUILD_DIR
    python3 tools/mktape.py --orig OUT.tzx                         # orig/Deflektor.tzx.zip's member, unchanged

The manifest (src/tape/tape.txt) lists the TZX blocks in order: the file header, the BASIC's header and the BASIC at
the ROM's speed, and the turbo block ($11) D.G. Cooke's loader reads. A standard block ($10) is its pause, its
length, the flag, the bytes and the XOR checksum, as the ROM's SA-BYTES writes it. The turbo block's pulses are what
the loader's own code asks for, load by load (tools/tapesim.py encode): its pilot, sync and bit lengths and the
pilot's count are the manifest's, its bits come from the BASIC (whose code is the first loader stage) and the loads.

An ITEM is a file of BUILD_DIR, or NAME@ORG:LO-HI, the bytes LO..HI-1 of NAME, whose first byte is at ORG (hex).
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import tapesim  # noqa: E402  (re-runs this tool under the SkoolKit venv when needed)


def std(pause, flag, data):
    body = bytes([flag]) + data
    ck = 0
    for b in body:
        ck ^= b
    body += bytes([ck])
    return bytes([0x10]) + pause.to_bytes(2, 'little') + len(body).to_bytes(2, 'little') + body


def read(build, item):
    name, _, cut = item.partition('@')
    data = open(os.path.join(build, name), 'rb').read()
    if not cut:
        return data
    org, _, span = cut.partition(':')
    lo, _, hi = span.partition('-')
    org, lo, hi = int(org, 16), int(lo, 16), int(hi, 16)
    if not org <= lo <= hi <= org + len(data):
        sys.exit(f'{item}: outside {name} (${org:04X}, {len(data)} bytes)')
    return data[lo - org:hi - org]


def turbo(f, build):
    pilot, sync1, sync2, zero, one, pulses, pause = (int(x) for x in f[:7])
    basic = read(build, f[7])
    loads = []
    for item in f[8:]:
        addr, _, src = item.partition('=')
        loads.append((int(addr, 16), read(build, src)))
    data, last = tapesim.pack_bits(tapesim.encode(basic, loads))
    head = b''.join(v.to_bytes(2, 'little') for v in (pilot, sync1, sync2, zero, one, pulses))
    return bytes([0x11]) + head + bytes([last]) + pause.to_bytes(2, 'little') + len(data).to_bytes(3, 'little') + data


def tape(manifest, build):
    out = bytearray()
    for line in open(manifest):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        kind, *f = line.split()
        if kind == 'tzx':
            major, minor = (int(x) for x in f[0].split('.'))
            out += b'ZXTape!\x1a' + bytes([major, minor])
        elif kind == 'header':
            pause, typ, name, length, p1, p2 = f
            name = name.replace('_', ' ')
            n = len(read(build, length[1:])) if length.startswith('@') else int(length)
            p2 = n if p2 == '=' else int(p2)
            hdr = bytes([int(typ)]) + name.encode('ascii').ljust(10) + n.to_bytes(2, 'little') + \
                int(p1).to_bytes(2, 'little') + p2.to_bytes(2, 'little')
            out += std(int(pause), 0x00, hdr)
        elif kind == 'data':
            out += std(int(f[0]), 0xFF, b''.join(read(build, n) for n in f[1:]))
        elif kind == 'turbo':
            out += turbo(f, build)
        else:
            sys.exit(f'{manifest}: cannot read: {line}')
    return bytes(out)


def main():
    if len(sys.argv) == 3 and sys.argv[1] == '--orig':
        with zipfile.ZipFile(os.path.join(CASE, 'orig', 'Deflektor.tzx.zip')) as z:
            open(sys.argv[2], 'wb').write(z.read('Deflektor.tzx'))
        return
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    open(sys.argv[2], 'wb').write(tape(sys.argv[1], sys.argv[3]))


if __name__ == '__main__':
    main()
