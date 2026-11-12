#!/usr/bin/env python3
"""A .z80 or .szx snapshot's RAM pages (48K or 128K) as bytes: load(path) -> (header fields, {page: 16384 bytes}).

    python3 tools/z80mem.py FILE.z80|FILE.szx   # the header and each page's non-zero byte count
    python3 tools/z80mem.py FILE OUT.bin        # also writes the 64 K view (banks 5, 2 and the paged one)
"""
import struct
import sys


def unrle(b, n=None):
    out, i = bytearray(), 0
    while i < len(b):
        if i + 3 < len(b) and b[i] == 0xED and b[i + 1] == 0xED:
            out += bytes([b[i + 3]]) * b[i + 2]
            i += 4
        else:
            out.append(b[i])
            i += 1
        if n and len(out) >= n:
            break
    return bytes(out)


def load_szx(path):
    """ZX-State: the Z80R block (registers) and the RAMP blocks (pages, zlib when flag bit 0 is set)."""
    import zlib
    d = open(path, 'rb').read()
    assert d[:4] == b'ZXST', path
    info, pages, i = {'machine': {0: '16K', 1: '48K'}.get(d[6], '128K')}, {}, 8
    while i + 8 <= len(d):
        bid, size = d[i:i + 4], struct.unpack('<I', d[i + 4:i + 8])[0]
        body = d[i + 8:i + 8 + size]
        if bid == b'Z80R':
            w = struct.unpack('<12H', body[:24])
            info.update(af=w[0], bc=w[1], de=w[2], hl=w[3], ix=w[8], iy=w[9], sp=w[10], pc=w[11],
                        i=body[24], r=body[25], iff1=body[26], iff2=body[27], im=body[28])
        elif bid == b'SPCR':
            info['7ffd'] = body[1]
        elif bid == b'RAMP':
            flags, page = struct.unpack('<H', body[:2])[0], body[2]
            pages[page] = zlib.decompress(body[3:]) if flags & 1 else body[3:]
        i += 8 + size
    return info, pages


def load(path):
    if path.lower().endswith('.szx'):
        return load_szx(path)
    d = open(path, 'rb').read()
    h = d[:30]
    pc = struct.unpack('<H', h[6:8])[0]
    info = dict(a=h[0], f=h[1], bc=struct.unpack('<H', h[2:4])[0], hl=struct.unpack('<H', h[4:6])[0],
                sp=struct.unpack('<H', h[8:10])[0], i=h[10], im=h[29] & 3, iff1=h[27])
    pages = {}
    if pc:
        info.update(pc=pc, version=1, machine='48K')
        mem = unrle(d[30:]) if h[12] & 0x20 else d[30:]
        pages = {5: mem[0:16384], 2: mem[16384:32768], 0: mem[32768:49152]}
        return info, pages
    xl = struct.unpack('<H', d[30:32])[0]
    x = d[32:32 + xl]
    info['pc'] = struct.unpack('<H', x[0:2])[0]
    hw = x[2]
    info['hw'] = hw
    info['version'] = 2 if xl == 23 else 3
    m128 = (hw in (3, 4) if xl == 23 else hw in (4, 5, 6)) or hw in (7, 9, 12, 13)
    info['machine'] = '128K' if m128 else '48K'
    info['7ffd'] = x[3]
    i = 32 + xl
    while i < len(d):
        ln, page = struct.unpack('<H', d[i:i + 2])[0], d[i + 2]
        body = d[i + 3:i + 3 + (16384 if ln == 0xFFFF else ln)]
        mem = body if ln == 0xFFFF else unrle(body, 16384)
        p = page - 3 if m128 else {8: 5, 4: 2, 5: 0}.get(page, page)
        pages[p] = mem
        i += 3 + (16384 if ln == 0xFFFF else ln)
    return info, pages


def flat48(pages, paged=0):
    return b'\0' * 0x4000 + pages[5] + pages[2] + pages[paged]


if __name__ == '__main__':
    info, pages = load(sys.argv[1])
    print(info)
    for p in sorted(pages):
        print(p, sum(1 for b in pages[p] if b))
    if len(sys.argv) > 2:
        open(sys.argv[2], 'wb').write(flat48(pages, info.get('7ffd', 0) & 7))
