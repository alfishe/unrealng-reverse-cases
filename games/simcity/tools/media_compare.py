#!/usr/bin/env python3
"""Every SimCity copy in work/candidates against the original Infogrames tape: its 512-byte loader block, its three
encrypted headerless blocks as stored (flag `$00`: the screen 6912, code1 37633, code2 4128 bytes) and the same three
decrypted (tools/decrypt_tape.py), plus the game image `$5B00-$FDFF` as the loader leaves it (code2's first 4096 bytes
moved to `$5B00`, then code1).

    python3 tools/media_compare.py ORIG.tzx work/candidates [--out work/stage1/media-compare.tsv]

For each file (TAP, TZX, Z80, SCL, TRD, RZX, a zip of them) it lists every block or file and says, per block,
whether it equals an original block, differs from it in N bytes at the same length, or holds a long run of the
original game block (the longest common run found by 64-byte anchors: a re-saved or moved copy), or none (packed).
A Z80 / RZX snapshot is compared over `$5B00-$FDFF` of its memory (a running game: its variables differ); a DSK
(+3) is read as its sectors in track order (one blob) and its CP/M directory names are listed.
"""
import io
import os
import struct
import sys
import zipfile
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402
import decrypt_tape  # noqa: E402


def tap_blocks(data):
    out, i = [], 0
    while i + 2 <= len(data):
        n = data[i] | data[i + 1] << 8
        blk = data[i + 2:i + 2 + n]
        out.append(('tap', blk[0] if blk else None, blk[1:-1]))
        i += 2 + n
    return out


def tzx_blocks(data):
    out = []
    for b in tzxblocks.parse(data):
        if 'data' in b:
            d = b['data']
            out.append((f"tzx id {b['id']:02X}", d[0] if d else None, d[1:-1]))
    return out


def z80_mem(data):
    """48K memory `$4000-$FFFF` of a Z80 snapshot (v1, v2, v3)"""
    pc = data[6] | data[7] << 8
    if pc != 0:
        body = data[30:]
        if data[12] & 0x20:
            body = rle(body, 49152)
        return bytes(body[:49152])
    hl = data[30] | data[31] << 8
    i = 32 + hl
    mem = bytearray(49152)
    page_at = {8: 0x0000, 4: 0x4000, 5: 0x8000}
    while i + 3 <= len(data):
        ln = data[i] | data[i + 1] << 8
        page = data[i + 2]
        i += 3
        raw = data[i:i + (16384 if ln == 0xFFFF else ln)]
        i += 16384 if ln == 0xFFFF else ln
        blk = raw if ln == 0xFFFF else rle(raw, 16384)
        if page in page_at:
            off = page_at[page]
            mem[off:off + 16384] = blk[:16384]
    return bytes(mem)


def rle(b, n):
    out = bytearray()
    i = 0
    while i < len(b) and len(out) < n:
        if b[i] == 0xED and i + 1 < len(b) and b[i + 1] == 0xED:
            out += bytes([b[i + 3]]) * b[i + 2]
            i += 4
        else:
            out.append(b[i])
            i += 1
    return out


def scl_files(data):
    assert data[:8] == b'SINCLAIR'
    n = data[8]
    off = 9 + 14 * n
    out = []
    for k in range(n):
        e = data[9 + 14 * k:9 + 14 * (k + 1)]
        name = e[:8].decode('latin-1').rstrip() + '.' + chr(e[8])
        start, ln, secs = struct.unpack('<HHB', e[9:14])
        out.append((f'{name} start {start} len {ln} sectors {secs}', None, data[off:off + secs * 256]))
        off += secs * 256
    return out


def trd_files(data):
    out = []
    for k in range(128):
        e = data[16 * k:16 * (k + 1)]
        if e[0] == 0:
            break
        if e[0] == 1:
            continue
        name = e[:8].decode('latin-1').rstrip() + '.' + chr(e[8])
        start, ln, secs, sec, trk = struct.unpack('<HHBBB', e[9:16])
        o = (trk * 16 + sec) * 256
        out.append((f'{name} start {start} len {ln} sectors {secs}', None, data[o:o + secs * 256]))
    return out


def dsk_files(data):
    """an (extended) CPC DSK: every sector's data in track order as one blob, and the CP/M directory names"""
    ext = data[:8] == b'EXTENDED'
    tracks, sides = data[0x30], data[0x31]
    sizes = list(data[0x34:0x34 + tracks * sides]) if ext else [data[0x32] | data[0x33] << 8 >> 8] * (tracks * sides)
    pos, blob = 0x100, bytearray()
    for t in range(tracks * sides):
        tsize = sizes[t] * 256 if ext else (data[0x32] | data[0x33] << 8)
        if tsize == 0:
            continue
        ti = data[pos:pos + tsize]
        n = ti[0x15]
        secs = sorted((ti[0x18 + 8 * k + 2], k) for k in range(n))
        off = 0x100
        datas = {}
        for k in range(n):
            ln = (ti[0x18 + 8 * k + 6] | ti[0x18 + 8 * k + 7] << 8) if ext else 128 << ti[0x18 + 8 * k + 3]
            datas[k] = ti[off:off + ln]
            off += ln
        for _, k in secs:
            blob += datas[k]
        pos += tsize
    names = set()
    d = blob[9 * 512:9 * 512 + 2048]   # +3: one reserved track of 9 x 512, then the directory
    for i in range(0, len(d), 32):
        e = d[i:i + 32]
        if e[0] < 16 and all(32 <= c < 127 for c in e[1:12]):
            names.add(e[1:9].decode().strip() + '.' + bytes(c & 0x7F for c in e[9:12]).decode().strip())
    return [(f'dsk blob (directory: {", ".join(sorted(names))})', None, bytes(blob))]


def rzx_snapshot(data):
    i = 10
    while i + 5 <= len(data):
        bid = data[i]
        ln = struct.unpack('<I', data[i + 1:i + 5])[0]
        if bid == 0x30:
            flags = struct.unpack('<I', data[i + 5:i + 9])[0]
            ext = data[i + 9:i + 13].rstrip(b'\0').decode()
            body = data[i + 17:i + ln]
            if flags & 2:
                body = zlib.decompress(body)
            return ext, body
        i += ln
    return None, None


def longest_run(blk, ref, anchor=64):
    """The longest run of BLK found in REF: (length, offset in blk, offset in ref)"""
    if len(blk) < anchor:
        return (0, 0, 0)
    index = {}
    for j in range(0, len(ref) - anchor + 1):
        index.setdefault(ref[j:j + anchor], j)
    best = (0, 0, 0)
    i = 0
    while i <= len(blk) - anchor:
        j = index.get(blk[i:i + anchor])
        if j is None:
            i += 16
            continue
        a, b = i, j
        while a > 0 and b > 0 and blk[a - 1] == ref[b - 1]:
            a, b = a - 1, b - 1
        n = 0
        while a + n < len(blk) and b + n < len(ref) and blk[a + n] == ref[b + n]:
            n += 1
        if n > best[0]:
            best = (n, a, b)
        i = a + n + 1
    return best


def judge(blk, refs):
    for name, ref in refs:
        if blk == ref:
            return f'= {name}'
    for name, ref in refs:
        if len(blk) == len(ref):
            diff = [k for k in range(len(blk)) if blk[k] != ref[k]]
            return f'{name} at the same length, {len(diff)} bytes differ' + (
                f' (first at +{diff[0]})' if diff else '')
    best = None
    for name, ref in refs:
        n, a, b = longest_run(blk, ref)
        if n and (best is None or n > best[0]):
            best = (n, a, b, name)
    if best and best[0] >= 256:
        n, a, b, name = best
        return f'longest run of {name}: {n} bytes (block +{a} = {name} +{b})'
    return 'no long run of the original (packed or other code)'


def blocks_of(path, data):
    low = path.lower()
    if low.endswith('.zip'):
        out = []
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            for m in z.namelist():
                if not m.endswith('/'):
                    out += [(f'{m}: {k}', f, b) for k, f, b in blocks_of(m, z.read(m))]
        return out
    if low.endswith('.tap'):
        return tap_blocks(data)
    if low.endswith('.tzx'):
        return tzx_blocks(data)
    if low.endswith('.z80'):
        return [('z80 memory $5B00-$FDFF', None, z80_mem(data)[0x1B00:0xBE00])]
    if low.endswith('.dsk'):
        return dsk_files(data)
    if low.endswith('.sna'):
        return [('sna memory $5B00-$FDFF', None, data[27 + 0x1B00:27 + 0xBE00])]
    if low.endswith('.scl'):
        return scl_files(data)
    if low.endswith('.trd'):
        return trd_files(data)
    if low.endswith('.rzx'):
        ext, snap = rzx_snapshot(data)
        if ext and ext.lower() == 'z80':
            return [('rzx snapshot (z80) memory $60C0-$FDFF', None, z80_mem(snap)[0x1B00:0xBE00])]
        if ext:
            return [(f'rzx snapshot ({ext}), not decoded', None, b'')]
    return []


def main():
    orig, root = sys.argv[1], sys.argv[2]
    out = sys.argv[sys.argv.index('--out') + 1] if '--out' in sys.argv else None
    ob = tzx_blocks(open(orig, 'rb').read())
    raw = [b[2] for b in ob[4:7]]
    dec = [decrypt_tape.decrypt(bytes([0]) + r + b'\0') for r in raw]
    image = dec[2][:4096] + dec[1][:-1]
    refs = [('loader block', ob[3][2]), ('screen as stored', raw[0]), ('code1 as stored', raw[1]),
            ('code2 as stored', raw[2]), ('game image $5B00-$FDFF', image), ('screen decrypted', dec[0]),
            ('code1 decrypted', dec[1]), ('code2 decrypted', dec[2])]
    rows = []
    for dirpath, _, files in sorted(os.walk(root)):
        for fn in sorted(files):
            p = os.path.join(dirpath, fn)
            data = open(p, 'rb').read()
            import hashlib
            md5 = hashlib.md5(data).hexdigest()
            print(f'== {os.path.relpath(p, root)}  ({len(data)} bytes, md5 {md5})')
            for k, (kind, flag, blk) in enumerate(blocks_of(p, data)):
                verdict = judge(blk, refs) if len(blk) >= 64 else 'short'
                fl = f' flag {flag:02X}' if flag is not None else ''
                print(f'   {k}: {kind}{fl} {len(blk)} bytes: {verdict}')
                rows.append((os.path.relpath(p, root), md5, str(k), kind, str(len(blk)), verdict))
    if out:
        with open(out, 'w') as f:
            f.write('# file\tmd5\tblock\tkind\tlength\tverdict\n')
            for r in rows:
                f.write('\t'.join(r) + '\n')


if __name__ == '__main__':
    main()
