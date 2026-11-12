#!/usr/bin/env python3
"""The tunes of David Whittaker's music driver (the game rips of Platoon, Fantasy World Dizzy and Stormbringer that
five variants carry) as text and back: music/whittaker.bin <-> music/whittaker.txt in a variant's folder
(tools/variants_music.py splits the music piece).

    python3 tools/res_whittaker.py dump TUNE.bin VERSION ORG    # print the text

The driver (variants/players/whittaker-VERSION/*.ann) reads its tunes by absolute addresses from its song table on:
  the song table: one record a tune, 7 bytes: the tempo (frames a row) and three words, the order lists of channels
    A, B and C (the init entry takes the tune's number in A);
  an order list: words, each the address of a pattern, then a word 0: the list starts again;
  a pattern, one item after another:
    $00-$7F a note (an index into the period table; written as a note name), it sounds for the current duration;
    $80-$BF a command (a byte or two of arguments for some; the set differs by version, see CMDS);
    above that, by version: a duration (frames of the notes after it), an instrument (a volume envelope), an
    ornament (a pitch table), a tempo; the pattern ends with the command `end` (the next pattern of the order list)
    or `stop`.
The text keeps every byte in its order: the songs, then each order list and pattern where it lies, labelled when a
word points to it; bytes no walk reaches are `bytes` lines. Text -> bytes assembles in that order and resolves the
labels. The text's first lines name the driver version and the address of the song table (`version`, `org`).
"""
import sys

NAMES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
# version: command byte -> (name, argument bytes, ends the pattern); and the ranges above the commands:
# (first byte, last byte, name, argument bytes)
VERSIONS = {
    'platoon': {
        'cmds': {0x80: ('rest', 0, False), 0x81: ('sweepoff', 0, False), 0x82: ('sweepup', 0, False),
                 0x83: ('sweepdown', 0, False), 0x84: ('slide', 2, False), 0x85: ('bendup', 0, False),
                 0x86: ('benddown', 0, False), 0x87: ('end', 0, True), 0x88: ('sweep', 2, False),
                 0x89: ('transpose', 1, False), 0x8A: ('tone', 0, False), 0x8B: ('noise', 0, False),
                 0x8C: ('both', 0, False), 0x8D: ('flag', 0, False), 0x8E: ('stop', 0, True),
                 0x8F: ('hold', 0, False), 0x90: ('lock', 0, False), 0x91: ('unlock', 0, False)},
        'ranges': [(0xB8, 0xBF, 'tempo', 0), (0xC0, 0xCF, 'orn', 0), (0xD0, 0xDF, 'instr', 0),
                   (0xE0, 0xFF, 'dur', 0)]},
    'dizzy': {
        'cmds': {0x80: ('rest', 0, False), 0x81: ('sweepoff', 0, False), 0x82: ('sweepup', 0, False),
                 0x87: ('end', 0, True), 0x88: ('sweep', 2, False), 0x89: ('transpose', 1, False),
                 0x8A: ('tone', 0, False), 0x8E: ('stop', 0, True), 0x8F: ('hold', 0, False),
                 0x92: ('chtranspose', 1, False), 0x93: ('orders', 2, True)},
        'ranges': [(0xC0, 0xCF, 'durx', 0), (0xD0, 0xDF, 'instr', 0), (0xE0, 0xFF, 'dur', 0)]},
    'storm': {
        'cmds': {0x80: ('rest', 0, False), 0x81: ('sweepoff', 0, False), 0x82: ('sweepup', 0, False),
                 0x83: ('sweepdown', 0, False), 0x84: ('slide', 2, False), 0x85: ('bendup', 0, False),
                 0x86: ('benddown', 0, False), 0x87: ('end', 0, True), 0x88: ('sweep', 2, False),
                 0x89: ('transpose', 1, False), 0x8A: ('tone', 0, False), 0x8B: ('noise', 0, False),
                 0x8C: ('both', 0, False), 0x8D: ('flag', 0, False), 0x8E: ('stop', 0, True),
                 0x8F: ('hold', 0, False)},
        'ranges': [(0xC0, 0xCF, 'orn', 0), (0xD0, 0xDF, 'instr', 3), (0xE0, 0xFF, 'dur', 0)]},
}
LAST = {'version': 'platoon', 'org': 0}


def handles(name):
    return name.endswith('/whittaker.bin')


def w(d, a):
    return d[a] | d[a + 1] << 8


def note_name(n):
    return '%s%d' % (NAMES[n % 12], n // 12)


NOTE = {note_name(n): n for n in range(0x80)}


def item(v, d, i):
    """(length, text) of the pattern item at offset i, and whether it ends the pattern; None: not a known item"""
    b = d[i]
    if b < 0x80:
        return 1, note_name(b), False
    c = v['cmds'].get(b)
    if c:
        name, n, end = c
        if name == 'orders':
            return 1 + n, None, end      # its word is a label: the caller writes it
        return 1 + n, ' '.join([name] + ['%d' % x for x in d[i + 1:i + 1 + n]]), end
    for lo, hi, name, n in v['ranges']:
        if lo <= b <= hi:
            return 1 + n, '%s%d%s' % (name, b - lo, ''.join(',%d' % x for x in d[i + 1:i + 1 + n])), False
    return None


def decode(d, org, version):
    """the songs, and the walked blocks: {offset: (kind, [(offset, length)])}"""
    v = VERSIONS[version]
    songs, first, a = [], len(d), 0
    while a + 7 <= first:
        rec = [d[a]] + [w(d, a + 1 + 2 * k) - org for k in range(3)]
        if not all(0 <= r < len(d) for r in rec[1:]):
            break
        songs.append(rec)
        first = min(first, *rec[1:])
        a += 7
    blocks, todo = {}, [(r, 'order') for s in songs for r in s[1:]]
    while todo:
        a, kind = todo.pop()
        if a in blocks:
            continue
        items = []
        if kind == 'order':
            while True:
                p = w(d, a + 2 * len(items))
                items.append((a + 2 * len(items), 2))
                if not p:
                    break
                todo.append((p - org, 'pattern'))
        else:
            i = a
            while True:
                it = item(v, d, i)
                if it is None:
                    raise ValueError('res_whittaker: unknown byte $%02X at $%04X' % (d[i], org + i))
                n, _t, end = it
                if d[i] in v['cmds'] and v['cmds'][d[i]][0] == 'orders':
                    todo.append((w(d, i + 1) - org, 'order'))
                items.append((i, n))
                i += n
                if end:
                    break
        blocks[a] = (kind, items)
    return songs, blocks


def to_text(d, org=None, version=None):
    org = LAST['org'] if org is None else org
    version = version or LAST['version']
    v = VERSIONS[version]
    songs, blocks = decode(d, org, version)
    owner = {}          # offset -> (kind, item length) of every walked item
    for a, (kind, items) in blocks.items():
        for i, n in items:
            owner.setdefault(i, (kind, n))
    names = {}
    for a, (kind, _items) in sorted(blocks.items()):
        names[a] = '%s%d' % ('o' if kind == 'order' else 'p', sum(1 for x in names.values() if x[0] == kind[0]))
    lab = lambda off: names.get(off, '$%04X' % (org + off))
    out = ['# A tune of David Whittaker\'s driver (tools/res_whittaker.py): the song table, then the order lists',
           '# (oN) and the patterns (pN) where they lie.', 'version ' + version, 'org $%04X' % org]
    for r in songs:
        out.append('song %d %s %s %s' % (r[0], lab(r[1]), lab(r[2]), lab(r[3])))
    i, end = 7 * len(songs), max([i + n for i, (k, n) in owner.items()] + [7 * len(songs)])
    raw = []

    def flush():
        for k in range(0, len(raw), 16):
            out.append('bytes ' + ' '.join('%02X' % x for x in raw[k:k + 16]))
        raw.clear()
    line = []

    def flush_line():
        if line:
            out.append('  ' + ' '.join(line))
            line.clear()
    while i < end:
        if i in names:
            flush_line()
            flush()
            out.append('%s: %s' % (names[i], blocks[i][0]))
        if i not in owner:
            flush_line()
            raw.append(d[i])
            i += 1
            continue
        flush()
        kind, n = owner[i]
        if kind == 'order':
            p = w(d, i)
            line.append(lab(p - org) if p else 'loop')
            if not p or len(line) >= 8:
                flush_line()
        else:
            n2, t, e = item(v, d, i)
            if t is None:
                t = 'orders %s' % lab(w(d, i + 1) - org)
            line.append(t)
            if e or len(line) >= 12:
                flush_line()
        i += n
    flush_line()
    flush()
    return '\n'.join(out) + '\n'


def from_text(text):
    version, org, songs, body, refs, labels, kind = 'platoon', 0, [], bytearray(), [], {}, None
    for line in text.split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        t = line.split()
        if t[0] == 'version':
            version = t[1]
        elif t[0] == 'org':
            org = int(t[1][1:], 16)
        elif t[0] == 'song':
            songs.append(t[1:])
        elif t[0] == 'bytes':
            body += bytes(int(x, 16) for x in t[1:])
        elif t[0].endswith(':'):
            labels[t[0][:-1]] = len(body)
            kind = t[1]
        elif line.startswith('  '):
            v = VERSIONS[version]
            byname = {c[0]: (b, c[1]) for b, c in v['cmds'].items()}
            k = 0
            while k < len(t):
                tok = t[k]
                if kind == 'order':
                    if tok == 'loop':
                        body += b'\0\0'
                    else:
                        refs.append((len(body), tok))
                        body += b'\0\0'
                    k += 1
                elif tok in NOTE:
                    body.append(NOTE[tok])
                    k += 1
                elif tok in byname:
                    b, n = byname[tok]
                    body.append(b)
                    if tok == 'orders':
                        refs.append((len(body), t[k + 1]))
                        body += b'\0\0'
                    else:
                        body += bytes(int(x) for x in t[k + 1:k + 1 + n])
                    k += 1 + n
                else:
                    for lo, hi, name, n in v['ranges']:
                        if tok.startswith(name) and tok[len(name):len(name) + 1].isdigit():
                            parts = tok[len(name):].split(',')
                            body.append(lo + int(parts[0]))
                            body += bytes(int(x) for x in parts[1:])
                            break
                    else:
                        raise ValueError('res_whittaker: cannot read %r' % tok)
                    k += 1
        else:
            raise ValueError('res_whittaker: cannot read %r' % line)
    LAST.update(version=version, org=org)
    head = bytearray()
    look = lambda s: int(s[1:], 16) if s.startswith('$') else org + 7 * len(songs) + labels[s]
    for s in songs:
        head.append(int(s[0]))
        for x in s[1:]:
            a = look(x)
            head += bytes([a & 255, a >> 8])
    out = head + body
    for at, s in refs:
        a = look(s)
        out[len(head) + at:len(head) + at + 2] = bytes([a & 255, a >> 8])
    return bytes(out)


def length(d, org=None, version=None):
    org = LAST['org'] if org is None else org
    songs, blocks = decode(d, org, version or LAST['version'])
    return max([i + n for _a, (_k, items) in blocks.items() for i, n in items] + [7 * len(songs)])


def set_org(org, version):
    LAST.update(org=org, version=version)


def to_editable(name, data):
    return '.txt', to_text(data).encode()


def from_editable(name, data):
    return from_text(data.decode())


if __name__ == '__main__':
    if sys.argv[1] == 'dump':
        sys.stdout.write(to_text(open(sys.argv[2], 'rb').read(), int(sys.argv[4], 16), sys.argv[3]))
