#!/usr/bin/env python3
"""ProTracker 2 / 3 modules: the file form (pointers are offsets from the module's start) and the form a compiled
player holds (ProTracker 2: every pointer has the module's address added; ProTracker 3: the file form, the player
adds the address at its init).

    music_ptmodule.py build FILE ADDR OUT          the module as it lies at ADDR (.pt2: compiled, then the pointers
                                             relocated; .pt3: as is)
    music_ptmodule.py unbuild IMAGE BASE ADDR LEN FORMAT OUT
                                             the LEN bytes of the module at ADDR in IMAGE (which starts at BASE)
                                             back to the file form (FORMAT pt2 / pt3)
    music_ptmodule.py info FILE                    the header, the pointers and the extents of the parts
    music_ptmodule.py diff A B                     two files of one format compared part by part (header, positions,
                                             patterns, samples, ornaments) and byte by byte
    music_ptmodule.py explain FILE IMAGE BASE AT ADDR
                                             every byte of the .pt2 module at AT in IMAGE (which starts at BASE),
                                             compiled for ADDR, accounted against FILE: the parts the compile
                                             dropped, the bytes moved down, the pointer words relocated, the
                                             bytes the image lacks; exit 1 on any byte the rule does not give

The pointers of a ProTracker 2 module (the layout of the format, as in Vortex Tracker II's and ZXTune's readers):
the header has 32 sample pointers at +3, 16 ornament pointers at +67 and the pattern table pointer at +99; the
pattern table has 3 channel pointers per pattern, as many patterns as the highest pattern number in the position
list plus one. A compiled module has the address added to the sample, ornament and channel pointers, not to the
pattern table pointer (the player's init adds it). ProTracker 3: the pattern table pointer at +103, 32 sample pointers at +105, 16 ornament pointers at
+169, the position list at +201 (pattern numbers times 3); every pointer is an offset already.
"""
import sys


def pt2_pointers(m, add=0):
    """the offsets in m of every pointer word of a ProTracker 2 module whose pointers have `add` added"""
    ptrs = [3 + 2 * i for i in range(32)] + [67 + 2 * i for i in range(16)]
    npos = m[1]
    positions = m[131:131 + npos]
    assert m[131 + npos] == 0xFF, 'no end of the position list'
    pat = m[99] | m[100] << 8
    for k in range(3 * (max(positions) + 1)):
        ptrs.append(pat + 2 * k)
    return ptrs, positions, pat


def pt3_parts(m):
    pat = m[103] | m[104] << 8
    pos = []
    i = 201
    while m[i] != 0xFF:
        pos.append(m[i] // 3)
        i += 1
    return pat, pos


def word(m, i):
    return m[i] | m[i + 1] << 8


def pt2_used(m):
    """the samples and ornaments the patterns name. The channel bytes, as the SoundTrack player decodes them
    (src/sound/stp-player.asm, PatternByteA): $E1-$FF sample 1-31; $E0 sound off, $80-$DF a note (both end the row);
    $70 an empty row, $7F envelope off, $71-$7E envelope type + 2 bytes; $60-$6F ornament 0-15; $20-$5F rows to
    skip; $10-$1F volume; $0F speed + 1 byte; $0E glissando + 1; $0D portamento + 3; $0C no glissando; $01-$0B noise
    + 1 byte; $00 the end of the pattern (channel A)"""
    ptrs, pos, pat = pt2_pointers(m)
    used_s, used_o = set(), {0}
    for k in range(3 * (max(pos) + 1)):
        i = word(m, pat + 2 * k)
        while i < len(m):
            b = m[i]
            i += 1
            if b == 0:
                break
            if b >= 0xE1:
                used_s.add(b - 0xE0)
            elif b >= 0x80 or b in (0x70, 0x7F, 0x0C) or 0x10 <= b < 0x60:
                pass
            elif b >= 0x71:
                i += 2
            elif b >= 0x60:
                used_o.add(b - 0x60)
            elif b == 0x0D:
                i += 3
            else:
                i += 1
    return used_s, used_o


def strip_unused(m):
    """ProTracker 2's compiled form, as ANE's tunes are: the samples and ornaments no pattern names dropped (ornament 0
    stays), their pointers 0, the bytes after them moved down, every pointer after them less"""
    m = bytearray(m)
    used_s, used_o = pt2_used(m)
    drops = []
    for k in range(32):
        s = word(m, 3 + 2 * k)
        if s and k not in used_s:
            drops.append((3 + 2 * k, s, 2 + 3 * m[s]))       # a sample: length, loop, 3 bytes a tick
    for k in range(16):
        s = word(m, 67 + 2 * k)
        if s and k not in used_o:
            drops.append((67 + 2 * k, s, 2 + m[s]))          # an ornament: length, loop, a byte a tick
    ptrs, _, _ = pt2_pointers(m)
    cut = sorted((s, n) for _, s, n in drops)
    for i, _, _ in drops:
        m[i], m[i + 1] = 0, 0

    def moved(v):
        return v - sum(n for s, n in cut if s < v)
    for i in ptrs:
        v = word(m, i)
        if v:
            v = moved(v)
            m[i], m[i + 1] = v & 0xFF, v >> 8
    v = moved(word(m, 99))
    m[99], m[100] = v & 0xFF, v >> 8
    for s, n in sorted(cut, reverse=True):
        del m[s:s + n]
    return bytes(m)


def dropped_parts(m):
    """[(start, length, what)] of the samples and ornaments strip_unused drops"""
    used_s, used_o = pt2_used(m)
    out = []
    for k in range(32):
        s = word(m, 3 + 2 * k)
        if s and k not in used_s:
            out.append((s, 2 + 3 * m[s], f'sample {k}'))
    for k in range(16):
        s = word(m, 67 + 2 * k)
        if s and k not in used_o:
            out.append((s, 2 + m[s], f'ornament {k}'))
    return sorted(out)


def explain(m, have, addr):
    """the account of `have` (the image's bytes) against the file-form module m compiled for addr; returns the
    number of bytes the rule does not explain"""
    drops = dropped_parts(m)
    gone = set()
    for s, n, _ in drops:
        gone.update(range(s, s + n))
    keep = [i for i in range(len(m)) if i not in gone]       # compiled offset j holds file offset keep[j]
    stripped = strip_unused(m)
    built = build(m, addr, 'pt2')
    ptrs, _, _ = pt2_pointers(bytearray(stripped))
    zero = [i for i in ptrs if word(stripped, i) == 0]
    lowered = [i for i in ptrs if word(stripped, i) and word(stripped, i) != word(m, keep[i])]
    print(f'file {len(m)} bytes, compiled {len(built)} bytes for ${addr:04X}, image {len(have)} bytes')
    print(f'dropped (no pattern names them): {len(gone)} bytes in {len(drops)} parts')
    for s, n, w in drops:
        print(f'  {w}: file offsets {s}-{s + n - 1}: {m[s:s + n].hex()}')
    moved = [j for j in range(len(built)) if keep[j] != j]
    if moved:
        print(f'moved down: compiled offsets {moved[0]}-{moved[-1]} (file offset minus 0..{keep[moved[-1]] - moved[-1]})')
    print(f'pointer words: {len(ptrs)} (32 samples, 16 ornaments, {len(ptrs) - 48} channel pointers); every one '
          f'+${addr:04X}: {len(ptrs) - len(zero)} offsets, {len(zero)} zero (unused) -> ${addr:04X}; '
          f'{len(lowered)} lowered by the drop first')
    for i in lowered:
        print(f'  +{i}: file {word(m, keep[i])} -> {word(stripped, i)} -> ${word(built, i):04X}')
    pw = set(ptrs) | {i + 1 for i in ptrs}
    other = [j for j in range(len(have)) if have[j] != m[keep[j]] and j not in pw]
    print(f'bytes differing from their file byte: {sum(1 for j in range(len(have)) if have[j] != m[keep[j]])}, all in '
          f'pointer words' + ('' if not other else f' except {other}'))
    bad = [j for j in range(min(len(have), len(built))) if have[j] != built[j]]
    if len(have) < len(built):
        print(f'the image lacks compiled offsets {len(have)}-{len(built) - 1}: {built[len(have):].hex()}')
    print('rule gives the image: ' + ('every byte' if not bad else f'NOT at {bad[:20]}'))
    return len(bad)


def build(data, addr, fmt):
    m = bytearray(data)
    if fmt == 'pt3':
        return bytes(m)
    m = bytearray(strip_unused(m))
    ptrs, _, _ = pt2_pointers(m)
    for i in ptrs:
        v = (word(m, i) + addr) & 0xFFFF
        m[i], m[i + 1] = v & 0xFF, v >> 8
    return bytes(m)


def unbuild(data, addr, fmt):
    m = bytearray(data)
    if fmt == 'pt3':
        return bytes(m)
    ptrs, _, _ = pt2_pointers(m, addr)
    for i in ptrs:
        v = (word(m, i) - addr) & 0xFFFF
        m[i], m[i + 1] = v & 0xFF, v >> 8
    return bytes(m)


def parts(m, fmt):
    """[(start, end, what)] of a file-form module"""
    if fmt == 'pt2':
        ptrs, positions, pat = pt2_pointers(m)
        name = bytes(m[101:131]).decode('latin-1')
        hdr = [(0, 131, f'header (delay {m[0]}, {m[1]} positions, loop {m[2]}, name "{name}")'),
               (131, 132 + m[1], 'positions')]
        npat = max(positions) + 1
        hdr.append((pat, pat + 6 * npat, f'pattern table ({npat} patterns)'))
        starts = []
        for k in range(32):
            starts.append((word(m, 3 + 2 * k), f'sample {k}'))
        for k in range(16):
            starts.append((word(m, 67 + 2 * k), f'ornament {k}'))
        for k in range(3 * npat):
            starts.append((word(m, pat + 2 * k), f'pattern {k // 3} channel {"ABC"[k % 3]}'))
    else:
        pat, positions = pt3_parts(m)
        name = bytes(m[0:99]).decode('latin-1')
        hdr = [(0, 201, f'header "{name.strip()}" (delay {m[100]}, {m[101]} positions, loop {m[102]})'),
               (201, 202 + len(positions), 'positions')]
        npat = max(positions) + 1
        hdr.append((pat, pat + 6 * npat, f'pattern table ({npat} patterns)'))
        starts = []
        for k in range(32):
            starts.append((word(m, 105 + 2 * k), f'sample {k}'))
        for k in range(16):
            starts.append((word(m, 169 + 2 * k), f'ornament {k}'))
        for k in range(3 * npat):
            starts.append((word(m, pat + 2 * k), f'pattern {k // 3} channel {"ABC"[k % 3]}'))
    # each part ends where the next part (of any kind) starts
    marks = sorted({s for s, _ in starts if s} | {e for _, e, _ in hdr} | {s for s, _, _ in hdr} | {len(m)})
    out = list(hdr)
    seen = set()
    for s, what in starts:
        if s == 0 or s in seen:
            continue
        seen.add(s)
        e = min(x for x in marks if x > s)
        names = [w for x, w in starts if x == s]
        out.append((s, e, ', '.join(names)))
    return sorted(out)


def fmt_of(path):
    return 'pt3' if path.lower().endswith('.pt3') else 'pt2'


def main():
    cmd = sys.argv[1]
    if cmd == 'build':
        path, addr, out = sys.argv[2], int(sys.argv[3], 16), sys.argv[4]
        open(out, 'wb').write(build(open(path, 'rb').read(), addr, fmt_of(path)))
    elif cmd == 'unbuild':
        img, base, addr, n, fmt, out = sys.argv[2:8]
        base, addr, n = int(base, 16), int(addr, 16), int(n)
        d = open(img, 'rb').read()[addr - base:addr - base + n]
        open(out, 'wb').write(unbuild(d, addr, fmt))
    elif cmd == 'info':
        path = sys.argv[2]
        m = open(path, 'rb').read()
        for s, e, w in parts(m, fmt_of(path)):
            print(f'{s:5d}-{e - 1:5d} {e - s:5d}  {w}')
        print(f'{len(m)} bytes')
    elif cmd == 'diff':
        a, b = open(sys.argv[2], 'rb').read(), open(sys.argv[3], 'rb').read()
        fmt = fmt_of(sys.argv[2])
        pa, pb = parts(a, fmt), parts(b, fmt)
        print(f'sizes {len(a)} / {len(b)}')
        da = {w: a[s:e] for s, e, w in pa}
        db = {w: b[s:e] for s, e, w in pb}
        for w in sorted(set(da) | set(db), key=lambda w: [s for s, e, x in pa + pb if x == w][0]):
            x, y = da.get(w), db.get(w)
            if x == y:
                continue
            if x is None or y is None:
                print(f'{w}: only in {"B" if x is None else "A"}')
                continue
            n = sum(1 for i in range(min(len(x), len(y))) if x[i] != y[i])
            print(f'{w}: {len(x)} / {len(y)} bytes, {n} differ at equal offsets')
    elif cmd == 'explain':
        path, img, base, at, addr = sys.argv[2:7]
        base, at, addr = int(base, 16), int(at, 16), int(addr, 16)
        m = open(path, 'rb').read()
        have = open(img, 'rb').read()[at - base:at - base + len(build(m, addr, 'pt2'))]
        sys.exit(1 if explain(m, have, addr) else 0)
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
