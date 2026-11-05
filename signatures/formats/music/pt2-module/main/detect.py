"""Pro Tracker 2 modules in an image, by their structure (the format has no signature text).

+0 the delay, +1 the positions, +2 the loop, +3 32 sample pointers, +67 16 ornament pointers, +99 the pattern table
offset, +101 the name (30), +131 the position list, $FF. The file form keeps the sample, ornament and channel
pointers as offsets from the module's start; a module compiled with its player (Pro Tracker 2.40's New SoundTrack
Player) holds them absolute, the pattern table pointer still an offset. Both are accepted; the form is in the fields.
"""


def _word(b, i):
    return b[i] | b[i + 1] << 8


def detect(image, base):
    out = []
    n = len(image)
    for at in range(0, n - 132):
        delay, count, loop = image[at], image[at + 1], image[at + 2]
        if not (2 <= delay <= 31 and 1 <= count and loop < count):
            continue
        if at + 131 + count >= n or image[at + 131 + count] != 0xFF:
            continue
        name = image[at + 101:at + 131]
        if any(c < 32 or c > 126 for c in name):
            continue
        hit = _check(image, at, base, count)
        if hit:
            out.append(hit)
    return out


def _check(m, at, base, count):
    positions = list(m[at + 131:at + 131 + count])
    address = (base + at) & 0xFFFF
    for compiled in (False, True):
        origin = address if compiled else 0
        top = max(positions)
        table = at + _word(m, at + 99)
        if table + 6 * (top + 1) > len(m):
            continue
        pointers = [_word(m, table + 2 * k) for k in range(3 * (top + 1))]
        samples = [_word(m, at + 3 + 2 * k) for k in range(32)]
        ornaments = [_word(m, at + 67 + 2 * k) for k in range(16)]
        # an unused sample or ornament points at the module's start
        used = [(p - origin) & 0xFFFF for p in pointers + samples + ornaments]
        used = [u for u in used if u]
        if not used or min(used) < 131 + count or max(used) >= 0x4000:
            continue
        if not (samples[1] - origin) & 0xFFFF or not (ornaments[0] - origin) & 0xFFFF:
            continue
        name = bytes(m[at + 101:at + 131]).decode('ascii').strip()
        return {'address': address, 'length': max(used), 'name': name,
                'fields': {'form': 'compiled' if compiled else 'file', 'delay': m[at], 'positions': count,
                           'loop': m[at + 2], 'patterns': top + 1}}
    return None
