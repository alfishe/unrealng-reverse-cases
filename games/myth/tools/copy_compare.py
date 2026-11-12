#!/usr/bin/env python3
"""Every Myth copy in work/candidates against the original tape's data blocks.

    python3 tools/copy_compare.py ORIG.tzx work/candidates [--out work/stage1/copy-compare.tsv]

For each TAP or TZX (also inside a zip) it lists every data block: its length, its flag, and whether it equals a
block of the original (`=oN`), differs from the original block of the same length in K bytes (`~oN:K`), or holds the
original's level data as a run (`run oN:len@off`, found by 64-byte anchors), else `new`. The block's data is the
bytes between the flag and the checksum, as `tzxblocks.py` gives them.
"""
import hashlib
import io
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402


def tap_blocks(data):
    out, i = [], 0
    while i + 2 <= len(data):
        n = data[i] | data[i + 1] << 8
        blk = data[i + 2:i + 2 + n]
        out.append(('tap', blk))
        i += 2 + n
    return out


def tzx_blocks(data):
    return [(f"{b['id']:02X}", b['data']) for b in tzxblocks.parse(data) if 'data' in b]


def blocks_of(name, data):
    low = name.lower()
    if low.endswith('.tap'):
        return tap_blocks(data)
    if low.endswith('.tzx'):
        return tzx_blocks(data)
    return None


def anchors(orig):
    idx = {}
    for k, (_, d) in enumerate(orig):
        if len(d) < 1024:
            continue
        for off in range(0, len(d) - 64, 64):
            idx.setdefault(d[off:off + 64], (k, off))
    return idx


def judge(d, orig, idx):
    for k, (_, o) in enumerate(orig):
        if d == o:
            return f'=o{k}'
    for k, (_, o) in enumerate(orig):
        if len(d) == len(o) and len(d) > 8:
            diff = sum(1 for a, b in zip(d, o) if a != b)
            if diff < len(d) // 4:
                return f'~o{k}:{diff}'
    best = None
    for p in range(0, max(0, len(d) - 64)):
        hit = idx.get(d[p:p + 64])
        if hit:
            k, off = hit
            o = orig[k][1]
            a, b = p, off
            while a > 0 and b > 0 and d[a - 1] == o[b - 1]:
                a, b = a - 1, b - 1
            n = 0
            while a + n < len(d) and b + n < len(o) and d[a + n] == o[b + n]:
                n += 1
            if not best or n > best[1]:
                best = (k, n, a, b)
            if n >= len(o) - 2:
                break
    if best and best[1] >= 256:
        return f'run o{best[0]}:{best[1]}@{best[2]}(o+{best[3]})'
    return 'new'


def files(root):
    for dp, _, fs in os.walk(root):
        for f in sorted(fs):
            p = os.path.join(dp, f)
            if f.lower().endswith('.zip'):
                try:
                    z = zipfile.ZipFile(p)
                except zipfile.BadZipFile:
                    continue
                for m in z.namelist():
                    yield f'{os.path.relpath(p, root)}!{m}', z.read(m)
            else:
                with open(p, 'rb') as fh:
                    yield os.path.relpath(p, root), fh.read()


def main():
    orig_path, root = sys.argv[1], sys.argv[2]
    out = sys.argv[sys.argv.index('--out') + 1] if '--out' in sys.argv else None
    orig = tzx_blocks(open(orig_path, 'rb').read())
    idx = anchors(orig)
    lines = []
    for name, data in sorted(files(root)):
        bl = blocks_of(name, data)
        if bl is None:
            continue
        try:
            parts = []
            for kind, d in bl:
                flag = f'{d[0]:02X}' if d else '--'
                parts.append(f'{len(d)}/{flag} {judge(d, orig, idx)}')
        except Exception as e:  # a broken file
            parts = [f'error {e}']
        lines.append(f"{name}\t{hashlib.md5(data).hexdigest()}\t{len(data)}\t{len(bl)}\t" + '; '.join(parts))
    text = '\n'.join(lines) + '\n'
    if out:
        open(out, 'w').write(text)
    sys.stdout.write(text)


if __name__ == '__main__':
    main()
