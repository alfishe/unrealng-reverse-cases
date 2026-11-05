#!/usr/bin/env python3
"""Lists and extracts the files of an SCL image.

  scl.py list FILE.scl
  scl.py extract FILE.scl OUTDIR      (each file as NAME.T with its sector-padded body; a .hdr.json beside)
"""
import json
import os
import struct
import sys


def read(path):
    d = open(path, 'rb').read()
    assert d[:8] == b'SINCLAIR', 'not an SCL'
    n = d[8]
    files, off = [], 9 + 14 * n
    for i in range(n):
        h = d[9 + 14 * i: 23 + 14 * i]
        name = h[:8].decode('latin-1')
        typ = chr(h[8])
        start, length = struct.unpack('<HH', h[9:13])
        secs = h[13]
        body = d[off: off + 256 * secs]
        off += 256 * secs
        files.append(dict(index=i, name=name, type=typ, start=start, length=length, sectors=secs, body=body))
    tail = d[off:]
    return files, tail, d


def main():
    cmd, path = sys.argv[1], sys.argv[2]
    files, tail, d = read(path)
    if cmd == 'list':
        print(f'{len(files)} files, {len(d)} bytes, checksum tail {tail.hex()}')
        for f in files:
            print(f"{f['index']:2} {f['name']!r:12} {f['type']} start {f['start']:5} (${f['start']:04X}) "
                  f"len {f['length']:5} (${f['length']:04X}) sectors {f['sectors']}")
    elif cmd == 'extract':
        out = sys.argv[3]
        os.makedirs(out, exist_ok=True)
        for f in files:
            base = f"{f['index']:02}_{f['name'].rstrip()}.{f['type']}"
            open(os.path.join(out, base), 'wb').write(f['body'])
            meta = {k: v for k, v in f.items() if k != 'body'}
            json.dump(meta, open(os.path.join(out, base + '.json'), 'w'))


if __name__ == '__main__':
    main()
