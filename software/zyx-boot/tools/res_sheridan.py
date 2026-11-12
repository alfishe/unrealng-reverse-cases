#!/usr/bin/env python3
"""The tune of Ian Sheridan's music driver (the game rip of Subway Vigilante in variant zyxboot-12) as text and back:
music/sheridan.bin <-> music/sheridan.txt (tools/variants_music.py splits the music piece).

    python3 tools/res_sheridan.py dump TUNE.bin ORG     # print the text

The driver (variants/players/sheridan/sheridan.ann) reads, by absolute addresses fixed in its code:
  the duration tables (org): rows of 8 bytes, the frames of a note's duration index 1-8 (command `speeds` picks one);
  the instruments (org + $41): 10 records of 35 bytes (the volume envelope's attack, decay, sustain and release,
    the vibrato, the arpeggio table and its loop, the noise and the hardware envelope, as the driver copies them
    into a channel);
  the pattern table (org + $19F): 12 words, the patterns' addresses;
  the song table (org + $1B7): 6 bytes a song, the sequences of channels A, B and C ($FFFF: no song);
  a sequence, one item after another: a pattern number and its repeat count, or $FA n (the note offset += n),
    $FB n (the note offset = n), $FC n (the duration table), $FD (the song again from its start), $FE (the sequence
    again), $FF (stop);
  a pattern: a note byte (the note = the byte - the note offset; the text names it for offset 11, the image's) and
    its duration index, or $60 d (a tie: the note goes on for duration index d), $61 i (the
    instrument), $64 n (the noise period), $65 s (the hardware envelope's shape), $FC n (fade in), $FD n (fade
    out), $FF (silence), $FE (the end: the pattern again until its repeat count runs out).
The text keeps every byte in its order; the tables are rows of numbers, the sequences and patterns are labelled
where a word points to them, bytes no walk reaches are `bytes` lines. Text -> bytes assembles in that order.
"""
import sys

NAMES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
INSTR, PATS, SONGS, NINSTR, NPATS = 0x41, 0x19F, 0x1B7, 10, 12
SEQ = {0xFA: ('offset+', 1, False), 0xFB: ('offset', 1, False), 0xFC: ('speeds', 1, False),
       0xFD: ('restart', 0, True), 0xFE: ('loop', 0, True), 0xFF: ('stop', 0, True)}
PAT = {0x60: ('cont', 1, False), 0x61: ('instr', 1, False), 0x64: ('noise', 1, False), 0x65: ('shape', 1, False),
       0xFC: ('fadein', 1, False), 0xFD: ('fadeout', 1, False), 0xFE: ('end', 0, True), 0xFF: ('off', 0, False)}
LAST = {'org': 0}


def handles(name):
    return name.endswith('/sheridan.bin')


def w(d, a):
    return d[a] | d[a + 1] << 8


def note_name(b):
    n = b - 0x0B
    return '%s%d' % (NAMES[n % 12], n // 12) if 0 <= n < 0x55 else 'n%d' % b


NOTE = {note_name(b): b for b in range(256) if b not in PAT}


def nsongs(d, org):
    """the songs: up to the first sequence any song points to"""
    first, n = len(d), 0
    while SONGS + 6 * n + 6 <= first:
        words = [w(d, SONGS + 6 * n + 2 * k) for k in range(3)]
        for x in words:
            if x != 0xFFFF:
                first = min(first, x - org)
        n += 1
    return n


def decode(d, org):
    ns = nsongs(d, org)
    blocks, todo = {}, []
    for s in range(ns):
        todo += [(w(d, SONGS + 6 * s + 2 * k) - org, 'sequence') for k in range(3)
                 if w(d, SONGS + 6 * s + 2 * k) != 0xFFFF]
    used = set()
    while todo:
        a, kind = todo.pop()
        if a in blocks or not 0 <= a < len(d):
            continue
        items, i = [], a
        while True:
            b = d[i]
            table = SEQ if kind == 'sequence' else PAT
            if b in table:
                n, end = 1 + table[b][1], table[b][2]
            else:
                n, end = 2, False
                if kind == 'sequence':
                    used.add(b)
            items.append((i, n))
            i += n
            if end:
                break
        blocks[a] = (kind, items)
    for p in range(NPATS):
        x = w(d, PATS + 2 * p) - org
        if x not in blocks:
            todo.append((x, 'pattern'))
    while todo:
        a, kind = todo.pop()
        if a in blocks or not 0 <= a < len(d):
            continue
        items, i = [], a
        while True:
            b = d[i]
            n, end = (1 + PAT[b][1], PAT[b][2]) if b in PAT else (2, False)
            items.append((i, n))
            i += n
            if end:
                break
        blocks[a] = ('pattern', items)
    return ns, blocks


def to_text(d, org=None):
    org = LAST['org'] if org is None else org
    ns, blocks = decode(d, org)
    names, count = {}, {}
    for a, (kind, _i) in sorted(blocks.items()):
        names[a] = '%s%d' % (kind[0], count.setdefault(kind, 0))
        count[kind] += 1
    pat_name = {}
    for p in range(NPATS):
        pat_name[p] = names.get(w(d, PATS + 2 * p) - org, '$%04X' % w(d, PATS + 2 * p))
    lab = lambda x: 'none' if x == 0xFFFF else names.get(x - org, '$%04X' % x)
    out = ['# The tune of Ian Sheridan\'s driver (tools/res_sheridan.py): the duration tables, the instruments, the',
           '# pattern table, the songs, then the sequences (sN) and patterns (pN) where they lie.', 'org $%04X' % org]
    for k in range(0, INSTR, 8):
        out.append('durations ' + ' '.join('%d' % x for x in d[k:min(k + 8, INSTR)]))
    for k in range(NINSTR):
        r = d[INSTR + 35 * k:INSTR + 35 * k + 35]
        out.append('instrument ' + ' '.join('%d' % x for x in r))
    out.append('patterns ' + ' '.join(pat_name[p] for p in range(NPATS)))
    for s in range(ns):
        out.append('song ' + ' '.join(lab(w(d, SONGS + 6 * s + 2 * k)) for k in range(3)))
    owner = {}
    for a, (kind, items) in blocks.items():
        for i, n in items:
            owner.setdefault(i, (kind, n))
    i = SONGS + 6 * ns
    end = max([i] + [x + n for x, (k, n) in owner.items()])
    raw, line = [], []

    def flush():
        if line:
            out.append('  ' + ' '.join(line))
            line.clear()
        for k in range(0, len(raw), 16):
            out.append('bytes ' + ' '.join('%02X' % x for x in raw[k:k + 16]))
        raw.clear()
    while i < end:
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
        table = SEQ if kind == 'sequence' else PAT
        if b in table:
            t = ' '.join([table[b][0]] + ['%d' % x for x in d[i + 1:i + n]])
        elif kind == 'sequence':
            t = '%s*%d' % (pat_name.get(b, 'pat%d' % b) if b < NPATS else 'pat%d' % b, d[i + 1])
        else:
            t = '%s/%d' % (note_name(b), d[i + 1])
        line.append(t)
        if table.get(b, ('', 0, False))[2] or len(line) >= 12:
            flush()
        i += n
    flush()
    return '\n'.join(out) + '\n'


def from_text(text):
    org, head, songs, pats, body, refs, labels, kind = 0, bytearray(), [], [], bytearray(), [], {}, None
    for line in text.split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        t = line.split()
        if t[0] == 'org':
            org = int(t[1][1:], 16)
        elif t[0] in ('durations', 'instrument'):
            head += bytes(int(x) for x in t[1:])
        elif t[0] == 'patterns':
            pats = t[1:]
        elif t[0] == 'song':
            songs.append(t[1:])
        elif t[0] == 'bytes':
            body += bytes(int(x, 16) for x in t[1:])
        elif t[0].endswith(':'):
            labels[t[0][:-1]] = len(body)
            kind = t[1]
        elif line.startswith('  '):
            table = SEQ if kind == 'sequence' else PAT
            byname = {v[0]: (b, v[1]) for b, v in table.items()}
            k = 0
            while k < len(t):
                tok = t[k]
                if tok in byname:
                    b, n = byname[tok]
                    body.append(b)
                    body += bytes(int(x) for x in t[k + 1:k + 1 + n])
                    k += 1 + n
                    continue
                if kind == 'sequence':
                    p, rep = tok.split('*')
                    body += bytes([pats.index(p) if p in pats else int(p[3:]), int(rep)])
                else:
                    nm, dur = tok.split('/')
                    body += bytes([NOTE[nm] if nm in NOTE else int(nm[1:]), int(dur)])
                k += 1
        else:
            raise ValueError('res_sheridan: cannot read %r' % line)
    LAST['org'] = org
    base = org + len(head) + 2 * len(pats) + 6 * len(songs)
    look = lambda s: 0xFFFF if s == 'none' else int(s[1:], 16) if s.startswith('$') else base + labels[s]
    out = bytearray(head)
    for p in pats:
        a = look(p)
        out += bytes([a & 255, a >> 8])
    for s in songs:
        for x in s:
            a = look(x)
            out += bytes([a & 255, a >> 8])
    return bytes(out + body)


def length(d, org=None):
    org = LAST['org'] if org is None else org
    ns, blocks = decode(d, org)
    return max([SONGS + 6 * ns] + [i + n for _a, (_k, items) in blocks.items() for i, n in items])


def set_org(org, version=None):
    LAST['org'] = org


def to_editable(name, data):
    return '.txt', to_text(data).encode()


def from_editable(name, data):
    return from_text(data.decode())


if __name__ == '__main__':
    if sys.argv[1] == 'dump':
        sys.stdout.write(to_text(open(sys.argv[2], 'rb').read(), int(sys.argv[3], 16)))
