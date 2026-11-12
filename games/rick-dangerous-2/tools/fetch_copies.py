#!/usr/bin/env python3
"""Copy every Rick Dangerous 2 file of the collection index unchanged into work/candidates/<source>/, one per SHA-256.

The index (/Volumes/TB4-4Tb/Data/zx-spectrum/index/zx-image-locations.tsv: sha256, path) names files inside archives
with `!` (a zip, a rar, nested). Zips are read with zipfile, rars with 7zz; each copy's SHA-256 is checked against
the index. Prints one line a copy: source, name, sha256 prefix, ok.

    python3 tools/fetch_copies.py [--grep 'rick.?dangerous.?(2|ii)']
"""
import argparse
import hashlib
import io
import os
import re
import subprocess
import zipfile

DATA = '/Volumes/TB4-4Tb/Data/zx-spectrum'
SOURCES = [('software/zxart.ee-offline', 'zxart'), ('packs/archive.org/tosec-2020-02-18', 'tosec-2020'),
           ('packs/archive.org/tosec-2012', 'tosec-2012'), ('packs/archive.org/the-spectrum-tosec-knobchez', 'knobchez'),
           ('packs/archive.org/tosec-mdr', 'tosec-mdr'), ('packs/archive.org/the-spectrum-collection', 'spectrum-collection'),
           ('packs/archive.org/zx-spectrum-games-sorted', 'games-sorted'), ('packs/archive.org/tosec-2023', 'tosec-2023'),
           ('collected/consoles-zx/Collections/Worldofspectrum', 'wos-ftp'), ('collected/consoles-zx/Collections/TOSEC', 'tosec-2005'),
           ('collected/consoles-zx/Collections/zxaaa', 'zxaaa'), ('collected/consoles-zx/Collections/ULA+', 'ulaplus'),
           ('demos/zxaaa.net', 'zxaaa-demos'), ('vtrd', 'vtrd'), ('software/zxdb', 'zxdb')]


def read(path, tmp='work/stage1/tmp-extract'):
    parts = path.split('!')
    data, name = None, parts[0]
    for inner in parts[1:]:
        if name.lower().endswith(('.rar', '.7z')):
            src = os.path.join(DATA, name) if data is None else os.path.join(tmp, 'container' + os.path.splitext(name)[1])
            if data is not None:
                os.makedirs(tmp, exist_ok=True)
                open(src, 'wb').write(data)
            data = subprocess.run(['7zz', 'e', '-so', src, inner], capture_output=True, check=True).stdout
        else:
            data = zipfile.ZipFile(io.BytesIO(data) if data is not None else os.path.join(DATA, name)).read(inner)
        name = inner
    if data is None:
        data = open(os.path.join(DATA, name), 'rb').read()
    return data


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--grep', default=r'rick.?dangerous.?(2|ii)\b', help='regex on the path, case-insensitive')
    ap.add_argument('--out', default='work/candidates')
    a = ap.parse_args()
    seen = {}
    for line in open(os.path.join(DATA, 'index', 'zx-image-locations.tsv'), errors='replace'):
        f = line.rstrip('\n').split('\t')
        if len(f) < 2 or not re.search(a.grep, f[1], re.I):
            continue
        if f[0] not in seen or len(f[1]) < len(seen[f[0]]):
            seen[f[0]] = f[1]
    for h, p in sorted(seen.items(), key=lambda x: x[1]):
        src = next((s for pre, s in SOURCES if p.startswith(pre)), 'other')
        name = p.split('!')[-1].split('/')[-1]
        try:
            data = read(p)
        except Exception as e:  # noqa: BLE001
            print('FAIL', src, name, e)
            continue
        ok = hashlib.sha256(data).hexdigest() == h
        d = os.path.join(a.out, src)
        os.makedirs(d, exist_ok=True)
        out = os.path.join(d, name)
        if os.path.exists(out) and open(out, 'rb').read() != data:
            out = os.path.join(d, h[:8] + '-' + name)
        open(out, 'wb').write(data)
        print(src, '|', name, '|', h[:10], '|', 'ok' if ok else 'HASH MISMATCH')


if __name__ == '__main__':
    main()
