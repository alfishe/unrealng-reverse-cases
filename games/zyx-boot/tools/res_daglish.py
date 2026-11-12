#!/usr/bin/env python3
"""The tunes of Ben Daglish's music driver (the game rip that variant zyxrover carries) as text and back:
music/daglish.bin <-> music/daglish.txt (tools/variants_music.py splits the music piece).

    python3 tools/res_daglish.py dump TUNE.bin ORG     # print the text

The driver (variants/players/daglish/daglish.ann) reads its tunes by absolute addresses fixed in its code; offsets
here are from the start of the tune (org):
  the pattern table (org + $4B4): 52 low bytes, then 52 high bytes of the patterns' addresses;
  the song table (org + $51C): 6 bytes a song, the sequences of channels A, B and C (the init entry takes the song's
    number in A);
  the instruments (org + $6A3): records of 10 bytes (attack, decay, sustain level, release, peak, vibrato delay,
    vibrato length, vibrato step word, flags); a channel picks one through its 8 instrument slots, each slot an offset
    from the first record;
  a sequence, one item after another: a pattern number ($00-$7F), `rep N` ($80+N: the next pattern N times),
    `transp N` ($FE N: transposition), `slotK V` ($C0+K V: slot K & 7 of the channel = offset V), `end` ($FF: the
    channel stops);
  a pattern: a note ($00-$7D, then its duration in frames; written NAME/D), `period $XXXX/D` ($7E lo hi D: a raw tone
    period), `rest/D` ($7F D: no new note), `ins K` ($80+K: instrument slot K), `pitch N` ($88+N: pitch table
    N & $0F, read at $CE32 + 8 * N by the driver), `skip$XX` ($C2) or `skip$XX a b c` ($C0-$FE: ignored with their
    3 argument bytes), `end` ($FF: the pattern again until its repeat count runs out).
The text keeps every byte in its order: patterns (labelled pN by their number), the two tables, the songs, the
sequences (sN), the instrument records (rows of 10), the rest of the patterns; bytes no walk reaches are `bytes`
lines (or stay in the instrument rows they follow). Text -> bytes assembles in that order and resolves the labels.
"""
import sys

NAMES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
PATLO, SONGS, INSTR, NPAT = 0x4B4, 0x51C, 0x6A3, 52
LAST = {'org': 0}


def handles(name):
    return name.endswith('/daglish.bin')


def w(d, a):
    return d[a] | d[a + 1] << 8


def note_name(b):
    return '%s%d' % (NAMES[b % 12], b // 12)


NOTE = {note_name(b): b for b in range(0x7E)}


def pat_addr(d, p):
    return d[PATLO + p] | d[PATLO + NPAT + p] << 8


def nsongs(d, org):
    first, n = len(d), 0
    while SONGS + 6 * n + 6 <= first:
        first = min([first] + [w(d, SONGS + 6 * n + 2 * k) - org for k in range(3)])
        n += 1
    return n


def seq_len(b):
    return 2 if b == 0xFE or 0xC0 <= b < 0xFE else 1


def pat_len(b):
    if b == 0x7E:
        return 4
    if b < 0x80:
        return 2
    if 0xC0 <= b < 0xFF and b != 0xC2:
        return 4
    return 1


def decode(d, org):
    """the songs, and the walked blocks: {offset: (kind, [(offset, length)])}"""
    ns = nsongs(d, org)
    blocks, todo = {}, []
    for s in range(ns):
        todo += [(w(d, SONGS + 6 * s + 2 * k) - org, 'sequence') for k in range(3)]
    todo += [(pat_addr(d, p) - org, 'pattern') for p in range(NPAT)]
    for a, kind in todo:
        if a in blocks or not 0 <= a < len(d):
            continue
        items, i = [], a
        while True:
            b = d[i]
            n = seq_len(b) if kind == 'sequence' else pat_len(b)
            items.append((i, n))
            i += n
            if b == 0xFF:
                break
        blocks[a] = (kind, items)
    return ns, blocks


def to_text(d, org=None):
    org = LAST['org'] if org is None else org
    ns, blocks = decode(d, org)
    names, count = {}, 0
    for p in range(NPAT):
        names.setdefault(pat_addr(d, p) - org, 'p%d' % p)
    for a, (kind, _i) in sorted(blocks.items()):
        if kind == 'sequence':
            names[a] = 's%d' % count
            count += 1
    lab = lambda x: names.get(x - org, '$%04X' % x)
    pnum = {p: names.get(pat_addr(d, p) - org) for p in range(NPAT)}
    owner = {}
    for a, (kind, items) in blocks.items():
        for i, n in items:
            owner.setdefault(i, (kind, n))
    out = ['# The tunes of Ben Daglish\'s driver (tools/res_daglish.py): patterns (pN), the pattern table, the songs,',
           '# the sequences (sN), the instruments, more patterns; in the order they lie.', 'org $%04X' % org]
    end = max(i + n for i, (_k, n) in owner.items())
    raw, line = [], []

    def flush():
        if line:
            out.append('  ' + ' '.join(line))
            line.clear()
        for k in range(0, len(raw), 16):
            out.append('bytes ' + ' '.join('%02X' % x for x in raw[k:k + 16]))
        raw.clear()
    i = 0
    while i < end:
        if i == PATLO:
            flush()
            out.append('patterns ' + ' '.join(lab(pat_addr(d, p)) for p in range(NPAT)))
            i += 2 * NPAT
            continue
        if i == SONGS:
            flush()
            for s in range(ns):
                out.append('song ' + ' '.join(lab(w(d, SONGS + 6 * s + 2 * k)) for k in range(3)))
            i += 6 * ns
            continue
        if i == INSTR:
            flush()
            stop = min([x for x in list(owner) + [end] if x > i])
            for k in range(i, stop, 10):
                out.append('instrument ' + ' '.join('%d' % x for x in d[k:min(k + 10, stop)]))
            i = stop
            continue
        if i in names:
            flush()
            out.append('%s: %s' % (names[i], blocks[i][0]))
        if i not in owner:
            if line:
                out.append('  ' + ' '.join(line))
                line.clear()
            raw.append(d[i])
            i += 1
            continue
        if raw:
            flush()
        kind, n = owner[i]
        b = d[i]
        if kind == 'sequence':
            if b < 0x80:
                t = pnum.get(b) or 'pat%d' % b if b < NPAT else 'pat%d' % b
            elif b == 0xFF:
                t = 'end'
            elif b == 0xFE:
                t = 'transp %d' % d[i + 1]
            elif b < 0xC0:
                t = 'rep %d' % (b - 0x80)
            else:
                t = 'slot%d %d' % (b - 0xC0, d[i + 1])
        else:
            if b < 0x7E:
                t = '%s/%d' % (note_name(b), d[i + 1])
            elif b == 0x7E:
                t = 'period $%04X/%d' % (w(d, i + 1), d[i + 3])
            elif b == 0x7F:
                t = 'rest/%d' % d[i + 1]
            elif b < 0x88:
                t = 'ins %d' % (b - 0x80)
            elif b < 0xC0:
                t = 'pitch %d' % (b - 0x88)
            elif b == 0xFF:
                t = 'end'
            else:
                t = ' '.join(['skip$%02X' % b] + ['%d' % x for x in d[i + 1:i + n]])
        line.append(t)
        if b == 0xFF or len(line) >= 12:
            flush()
        i += n
    flush()
    return '\n'.join(out) + '\n'


def from_text(text):
    org, body, refs, labels, kind, pats = 0, bytearray(), [], {}, None, []
    for line in text.split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        t = line.split()
        if t[0] == 'org':
            org = int(t[1][1:], 16)
        elif t[0] == 'patterns':
            pats = t[1:]
            for p, x in enumerate(pats):
                refs.append((len(body) + p, len(body) + len(pats) + p, x))
            body += bytes(2 * len(pats))
        elif t[0] == 'song':
            for x in t[1:]:
                refs.append((len(body), len(body) + 1, x))
                body += b'\0\0'
        elif t[0] == 'instrument':
            body += bytes(int(x) for x in t[1:])
        elif t[0] == 'bytes':
            body += bytes(int(x, 16) for x in t[1:])
        elif t[0].endswith(':'):
            labels[t[0][:-1]] = len(body)
            kind = t[1]
        elif line.startswith('  '):
            k = 0
            while k < len(t):
                tok = t[k]
                if tok == 'end':
                    body.append(0xFF)
                elif tok in ('transp', 'rep', 'ins', 'pitch'):
                    v = int(t[k + 1])
                    body += bytes([0xFE, v]) if tok == 'transp' else bytes([(0x88 if tok == 'pitch' else 0x80) + v])
                    k += 1
                elif tok.startswith('slot'):
                    body += bytes([0xC0 + int(tok[4:]), int(t[k + 1])])
                    k += 1
                elif tok.startswith('skip$'):
                    b = int(tok[5:], 16)
                    body.append(b)
                    if b != 0xC2:
                        body += bytes(int(x) for x in t[k + 1:k + 4])
                        k += 3
                elif tok == 'period':
                    v, dur = t[k + 1].split('/')
                    v = int(v[1:], 16)
                    body += bytes([0x7E, v & 255, v >> 8, int(dur)])
                    k += 1
                elif kind == 'sequence':
                    body.append(pats.index(tok) if tok in pats else int(tok[3:]))
                else:
                    nm, dur = tok.split('/')
                    body += bytes([0x7F if nm == 'rest' else NOTE[nm], int(dur)])
                k += 1
        else:
            raise ValueError('res_daglish: cannot read %r' % line)
    LAST['org'] = org
    for lo, hi, x in refs:
        a = int(x[1:], 16) if x.startswith('$') else org + labels[x]
        body[lo], body[hi] = a & 255, a >> 8
    return bytes(body)


def length(d, org=None):
    org = LAST['org'] if org is None else org
    _ns, blocks = decode(d, org)
    return max(i + n for _a, (_k, items) in blocks.items() for i, n in items)


def set_org(org, version=None):
    LAST['org'] = org


def to_editable(name, data):
    return '.txt', to_text(data).encode()


def from_editable(name, data):
    return from_text(data.decode())


if __name__ == '__main__':
    if sys.argv[1] == 'dump':
        sys.stdout.write(to_text(open(sys.argv[2], 'rb').read(), int(sys.argv[3], 16)))
