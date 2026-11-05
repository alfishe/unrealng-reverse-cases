"""Pro Tracker 3 / Vortex Tracker II modules in an image, by their header and structure.

+0 "ProTracker 3." or "Vortex Tracker II", +30 the title (32), +66 the author (32), +99 the tone table, +100 the
delay, +101 the positions, +102 the loop, +103 the pattern table offset, +105 32 sample offsets, +169 16 ornament
offsets, +201 the position list (pattern * 3), $FF. The offsets count from the module's start.
"""

SIGNS = (b'ProTracker 3.', b'Vortex Tracker II')


def _word(b, i):
    return b[i] | b[i + 1] << 8


def _text(b):
    return bytes(c if 32 <= c < 127 else 32 for c in b).decode('ascii').strip()


def detect(image, base):
    out = []
    for sign in SIGNS:
        at = image.find(sign)
        while at >= 0:
            hit = _check(image, at, base)
            if hit:
                out.append(hit)
            at = image.find(sign, at + 1)
    return out


def _check(m, at, base):
    if at + 202 > len(m):
        return None
    delay, loop = m[at + 100], m[at + 102]
    if not 1 <= delay <= 63:
        return None
    positions = []
    i = at + 201
    while i < len(m) and m[i] != 0xFF and len(positions) < 256:
        if m[i] % 3:
            return None
        positions.append(m[i] // 3)
        i += 1
    if i >= len(m) or not positions or loop >= len(positions):
        return None
    patterns = _word(m, at + 103)
    top = max(positions)
    end = at + patterns + 6 * (top + 1)
    if end > len(m):
        return None
    pointers = [_word(m, at + patterns + 2 * k) for k in range(3 * (top + 1))]
    samples = [_word(m, at + 105 + 2 * k) for k in range(32)]
    ornaments = [_word(m, at + 169 + 2 * k) for k in range(16)]
    used = [p for p in pointers + samples + ornaments if p]
    if not used or max(used) >= 0xC000:
        return None
    length = max(used)
    # the module runs at least to its last pointer; the data after it ends where the bytes no longer parse: keep the
    # last pointer as a floor, the caller reads the rest from the player
    return {'address': (base + at) & 0xFFFF, 'length': length, 'name': _text(m[at + 30:at + 62]),
            'fields': {'version': _text(m[at:at + 14]), 'author': _text(m[at + 66:at + 98]), 'delay': delay,
                       'positions': len(positions), 'loop': loop, 'patterns': top + 1, 'tone_table': m[at + 99]}}
