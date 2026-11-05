#!/usr/bin/env python3
"""List and extract the files of an SCL or TRD image (TR-DOS catalogue).

  disk_files.py IMAGE            the catalogue: name, type, start, length, sectors, first track/sector, md5
  disk_files.py IMAGE --out DIR  also writes each file's sectors (name.T, length rounded to sectors as on disk
                                 is written to name.T.sec; the declared length to name.T)
"""
import argparse, hashlib, os, struct, sys


def entries_scl(data):
    assert data[:8] == b'SINCLAIR', 'not an SCL'
    n = data[8]
    pos = 9 + 14 * n
    out = []
    for i in range(n):
        e = data[9 + 14 * i: 9 + 14 * (i + 1)]
        name, typ = e[:8], e[8]
        start, length = struct.unpack('<HH', e[9:13])
        secs = e[13]
        body = data[pos: pos + secs * 256]
        pos += secs * 256
        out.append(dict(name=name, type=typ, start=start, length=length, secs=secs, trk=None, sec=None, body=body))
    return out


def entries_trd(data):
    out = []
    for i in range(128):
        e = data[16 * i: 16 * (i + 1)]
        if e[0] == 0:
            break
        name, typ = e[:8], e[8]
        start, length = struct.unpack('<HH', e[9:13])
        secs, sec, trk = e[13], e[14], e[15]
        off = (trk * 16 + sec) * 256
        out.append(dict(name=name, type=typ, start=start, length=length, secs=secs, trk=trk, sec=sec,
                        body=data[off: off + secs * 256], deleted=e[0] == 1))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image')
    ap.add_argument('--out')
    a = ap.parse_args()
    data = open(a.image, 'rb').read()
    ents = entries_scl(data) if data[:8] == b'SINCLAIR' else entries_trd(data)
    if data[:8] != b'SINCLAIR':
        s9 = data[8 * 256: 9 * 256]
        print(f'# TRD: free {s9[0xE1]}:{s9[0xE2]} type {s9[0xE3]:#x} files {s9[0xE4]} free secs '
              f'{struct.unpack("<H", s9[0xE5:0xE7])[0]} label {s9[0xF5:0xFD]!r}')
    print('# n name     T start  len   secs trk:sec md5(declared length)')
    for i, e in enumerate(ents):
        nm = e['name'].decode('latin-1')
        t = chr(e['type'])
        md5 = hashlib.md5(e['body'][:e['length'] if t != 'B' else e['length']]).hexdigest()
        loc = f"{e['trk']}:{e['sec']}" if e['trk'] is not None else '-'
        print(f"{i:2d} {nm!r:10} {t} {e['start']:5d}=${e['start']:04X} {e['length']:5d} {e['secs']:4d} {loc:7} {md5}")
        if a.out:
            os.makedirs(a.out, exist_ok=True)
            fn = nm.rstrip().replace('/', '_') + '.' + t
            open(os.path.join(a.out, fn), 'wb').write(e['body'][:e['length']] if t != 'B' else e['body'])
            open(os.path.join(a.out, fn + '.sec'), 'wb').write(e['body'])


if __name__ == '__main__':
    main()
