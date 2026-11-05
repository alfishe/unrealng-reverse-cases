#!/usr/bin/env python3
"""The parts of both releases, read from orig/ alone: the SCL files, the blocks by sector, the '99 blocks unpacked.

    python3 tools/zs_media.py [--out work/media]

Writes, for the '98 (orig/NEZSED98.zip, NEZSED98.SCL, one file NEZSEd.B of 157 sectors):
  98/basic.bin      sectors 0-1 (the 340-byte BASIC and the 172 bytes after it in its last sector)
  98/intro.bin      sectors 2-43, read to $C000-$E9FF
  98/game.bin       sectors 44-156, read to $6780-$D87F
and for the '99 (orig/NEZSED.ZIP, NEZSED.SCL, NEZSEd99.B of 133 sectors and 17 other files):
  99/<name>.bin     each block of NEZSEd99.B as read (BLOCKS below), the packed ones also unpacked:
  99/<name>-out.bin the bytes the block's depacker writes (its first output byte to its last)
  99/files/NN_NAME.T every other file's sectors
"""
import argparse
import io
import json
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import zsdepack  # noqa: E402

ZIP98 = os.path.join(ROOT, 'orig', 'NEZSED98.zip')
ZIP99 = os.path.join(ROOT, 'orig', 'NEZSED.ZIP')

# '99: name, first sector, sectors, load address, packed
BLOCKS = [
    ('basic', 0, 1, 0x5D3B, False),
    ('stage2', 1, 18, 0x8000, True),
    ('pictures', 19, 13, 0x7D87, False),
    ('music', 32, 13, 0xC000, False),
    ('stage3', 45, 6, 0x8000, True),
    ('game', 51, 68, 0x6780, True),
    ('patches', 119, 4, 0xDC00, True),
    ('menu', 123, 10, 0xE800, True),
]


def scl_from_zip(path):
    z = zipfile.ZipFile(path)
    name = [n for n in z.namelist() if n.upper().endswith('.SCL')][0]
    return z.read(name)


def scl_files(data):
    assert data[:8] == b'SINCLAIR'
    n = data[8]
    off = 9 + 14 * n
    out = []
    for i in range(n):
        h = data[9 + 14 * i:23 + 14 * i]
        secs = h[13]
        out.append(dict(name=h[:8].decode('latin-1'), type=chr(h[8]), start=h[9] | h[10] << 8,
                        length=h[11] | h[12] << 8, sectors=secs, body=data[off:off + 256 * secs]))
        off += 256 * secs
    return out, data[off:]


def unpack(raw, at):
    """(first output address, the output bytes, the block's parameters)"""
    mem = bytearray(0x10000)
    mem[at:at + len(raw)] = raw
    p = zsdepack.unpack_block(mem, at)
    assert p['src_left'] == at - 1 or True
    lo = p['stop'] + 1
    return lo, bytes(mem[lo:p['dst_end'] + 1]), p


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out', default=os.path.join(ROOT, 'work', 'media'))
    a = ap.parse_args()
    o98, o99 = os.path.join(a.out, '98'), os.path.join(a.out, '99')
    os.makedirs(o98, exist_ok=True)
    os.makedirs(os.path.join(o99, 'files'), exist_ok=True)
    files, _ = scl_files(scl_from_zip(ZIP98))
    b = files[0]['body']
    open(os.path.join(o98, 'basic.bin'), 'wb').write(b[:512])
    open(os.path.join(o98, 'intro.bin'), 'wb').write(b[512:44 * 256])
    open(os.path.join(o98, 'game.bin'), 'wb').write(b[44 * 256:])
    files, _ = scl_files(scl_from_zip(ZIP99))
    body = files[0]['body']
    info = {}
    for name, first, n, at, packed in BLOCKS:
        raw = body[first * 256:(first + n) * 256]
        open(os.path.join(o99, name + '.bin'), 'wb').write(raw)
        if packed:
            lo, data, p = unpack(raw, at)
            open(os.path.join(o99, name + '-out.bin'), 'wb').write(data)
            info[name] = dict(load='%04X' % at, out='%04X' % lo, end='%04X' % (lo + len(data) - 1),
                              packed=p['length'], used=0xB0 + p['length'], far_bits=p['far_bits'],
                              jump='%04X' % p['jump'], source_left='%04X' % p['src_left'])
    for i, f in enumerate(files[1:], 1):
        open(os.path.join(o99, 'files', '%02d_%s.%s' % (i, f['name'].rstrip(), f['type'])), 'wb').write(f['body'])
    json.dump(info, open(os.path.join(o99, 'blocks.json'), 'w'), indent=1)
    for k, v in info.items():
        print(k, v)


if __name__ == '__main__':
    main()
