#!/usr/bin/env python3
"""A Sound Tracker module (STC, the "SONG BY ST COMPILE" module a compiled ST player plays) as text and back:
music/stc.bin <-> music/stc.txt in a variant's folder (tools/variants_music.py splits the music piece).

    python3 tools/res_stc.py dump MODULE.bin       # print the text

The module, as the player reads it (variants/players/stc/stc.ann):
  +0 the delay (frames a row), +1 the positions' offset, +3 the ornaments', +5 the pattern table's (from the module's
  start), +7 the 18-byte identifier, +25 the size word, +27 the samples;
  a sample: its number, 32 rows of 3 bytes, the loop row and the loop length (99 bytes);
  the positions: the count - 1, then a pattern number and a transposition a position;
  an ornament: its number and 32 note offsets (33 bytes);
  the pattern table: its number and the offsets of the streams of channels A, B and C (7 bytes), a $FF after the last;
  the streams.
The text keeps the blocks in the order of the bytes and rebuilds every offset from that order; a block may grow or
shrink. Bytes no block covers are kept as `bytes` lines where they lie. The format is in src/res/music/README.md.
"""
import sys

NAMES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']   # note 0 = C-1 (as ST shows it)


def handles(name):
    return name.endswith('/stc.bin')


def note_name(n):
    return '%s%d' % (NAMES[n % 12], n // 12 + 1)


NOTE = {note_name(n): n for n in range(0x60)}


def s8(b):
    return b - 256 if b >= 128 else b


def hexs(bs):
    return ' '.join('%02X' % b for b in bs)


def w(d, a):
    return d[a] | d[a + 1] << 8


# ----------------------------------------------------------------------------------------------- bytes -> text

def sample_row(r):
    b0, b1, b2 = r
    mix = ('T' if not b1 & 0x40 else '-') + ('N' if not b1 & 0x80 else '-')
    return 'vol %2d noise %2d tone %s$%03X %s' % (b0 & 15, b1 & 0x1F, '+' if b1 & 0x20 else '-', (b0 >> 4) << 8 | b2,
                                                  mix)


def stream_lines(d):
    lines, toks, i = [], [], 0
    while i < len(d):
        b = d[i]
        if b < 0x60:
            toks.append(note_name(b))
        elif b < 0x70:
            toks.append('s%d' % (b - 0x60))
            i += 1
            continue
        elif b < 0x80:
            toks.append('o%d' % (b - 0x70))
            i += 1
            continue
        elif b == 0x80:
            toks.append('rest')
        elif b == 0x81:
            toks.append('---')
        elif b == 0x82:
            toks.append('noenv')
            i += 1
            continue
        elif b < 0x8F and i + 1 < len(d):
            toks.append('env%d,$%02X' % (b - 0x80, d[i + 1]))
            i += 2
            continue
        elif b >= 0xA1 and b != 0xFF:
            toks.append('len%d' % (b - 0xA1))
            i += 1
            continue
        elif b == 0xFF:
            toks.append('end')
        else:
            toks.append('$%02X' % b)
        lines.append(' '.join(toks))
        toks = []
        i += 1
    if toks:
        lines.append(' '.join(toks))
    return lines


def to_text(d):
    size = w(d, 25)
    pos, orn, pat = w(d, 1), w(d, 3), w(d, 5)
    ident = ''.join(chr(c) if 32 <= c < 127 and c not in (0x7B, 0x7D) else '{%02X}' % c for c in d[7:25])
    out = ['# A Sound Tracker module (STC); the format in src/res/music/README.md. Offsets are rebuilt from the block',
           '# order; "#" starts a comment line.', '',
           'delay %d' % d[0], 'id %s' % ident, 'size %d' % size, '']
    n = len(d)
    # the pattern table and the streams it names
    pt, entries = pat, []
    while pt + 7 <= n and d[pt] != 0xFF:
        entries.append((d[pt], w(d, pt + 1), w(d, pt + 3), w(d, pt + 5)))
        pt += 7
    pt_end = pt + 1 if pt < n and d[pt] == 0xFF else pt
    streams = sorted({s for e in entries for s in e[1:] if pt_end <= s < n})
    sid = {s: k for k, s in enumerate(streams)}
    blocks = sorted([(27, 'samples'), (pos, 'positions'), (orn, 'ornaments'), (pat, 'patterns')] +
                    [(s, 'stream') for s in streams])
    bounds = [b[0] for b in blocks] + [n]
    cur = 0
    for k, (a, kind) in enumerate(blocks):
        end = bounds[k + 1]
        if kind == 'samples':
            while a + 99 <= end:
                r = d[a:a + 99]
                out.append('sample %d loop %d %d' % (r[0], r[97], r[98]))
                out += ['  ' + sample_row(r[1 + 3 * j:4 + 3 * j]) for j in range(32)]
                a += 99
        elif kind == 'positions':
            cnt = d[a]
            items = ['%d:%d' % (d[a + 1 + 2 * j], s8(d[a + 2 + 2 * j])) for j in range(cnt + 1)]
            out.append('positions ' + ' '.join(items))
            a += 1 + 2 * (cnt + 1)
        elif kind == 'ornaments':
            while a + 33 <= end:
                out.append('ornament %d %s' % (d[a], ' '.join('%d' % s8(x) for x in d[a + 1:a + 33])))
                a += 33
        elif kind == 'patterns':
            for e in entries:
                out.append('pattern %d %s' % (e[0], ' '.join('s%d' % sid[s] if s in sid else '$%04X' % s
                                                             for s in e[1:])))
            if pt_end > pt:
                out.append('patterns end')
            a = pt_end
        else:
            out.append('stream %d' % sid[a])
            out += ['  ' + x for x in stream_lines(d[a:end])]
            a = end
        if a < end:
            out.append('bytes ' + hexs(d[a:end]))
        cur = end
        out.append('')
    assert cur == n
    return '\n'.join(out).rstrip('\n') + '\n'


# ----------------------------------------------------------------------------------------------- text -> bytes

def stream_bytes(toks):
    out = bytearray()
    for t in toks:
        if t in NOTE:
            out.append(NOTE[t])
        elif t == 'rest':
            out.append(0x80)
        elif t == '---':
            out.append(0x81)
        elif t == 'noenv':
            out.append(0x82)
        elif t == 'end':
            out.append(0xFF)
        elif t.startswith('env'):
            a, b = t[3:].split(',')
            out += bytes([0x80 + int(a), int(b[1:], 16)])
        elif t.startswith('len'):
            out.append(0xA1 + int(t[3:]))
        elif t.startswith('$'):
            out.append(int(t[1:], 16))
        elif t[0] == 's':
            out.append(0x60 + int(t[1:]))
        elif t[0] == 'o':
            out.append(0x70 + int(t[1:]))
        else:
            raise ValueError('res_stc: unknown token %r' % t)
    return out


def from_text(text):
    head = bytearray(27)
    body = bytearray()
    marks = {}                 # 'positions', 'ornaments', 'patterns' -> offset; stream k -> offset
    patrefs = []               # (offset in body of a stream word, stream id or fixed value)
    rows = None
    for line in text.split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        if line.startswith('  '):
            t = line.split()
            if rows is not None:
                vol, noise = int(t[1]), int(t[3])
                sign, val = t[5][0], int(t[5][2:], 16)
                mix = t[6]
                b1 = noise | (0x20 if sign == '+' else 0) | (0 if mix[0] == 'T' else 0x40) | (0 if mix[1] == 'N' else 0x80)
                body += bytes([(val >> 8) << 4 | vol, b1, val & 255])
                rows -= 1
                if rows == 0:
                    body += bytes(pending)
                    rows = None
            else:
                body += stream_bytes(t)
            continue
        t = line.split()
        o = 27 + len(body)
        if t[0] == 'delay':
            head[0] = int(t[1])
        elif t[0] == 'id':
            s = line[3:]
            ident = bytearray()
            i = 0
            while i < len(s):
                if s[i] == '{':
                    ident.append(int(s[i + 1:i + 3], 16))
                    i += 4
                else:
                    ident.append(ord(s[i]))
                    i += 1
            head[7:25] = ident[:18]
        elif t[0] == 'size':
            head[25:27] = bytes([int(t[1]) & 255, int(t[1]) >> 8])
        elif t[0] == 'sample':
            body.append(int(t[1]))
            rows, pending = 32, (int(t[3]), int(t[4]))
        elif t[0] == 'positions':
            marks['positions'] = o
            body.append(len(t) - 2)
            for it in t[1:]:
                p, tr = it.split(':')
                body += bytes([int(p), int(tr) & 255])
        elif t[0] == 'ornament':
            marks.setdefault('ornaments', o)
            body += bytes([int(t[1])] + [int(x) & 255 for x in t[2:34]])
        elif t[0] == 'patterns':
            body.append(0xFF)
        elif t[0] == 'pattern':
            if 'patterns' not in marks:
                marks['patterns'] = o
            body.append(int(t[1]))
            for ref in t[2:5]:
                patrefs.append((len(body), ref))
                body += b'\0\0'
        elif t[0] == 'stream':
            marks[int(t[1])] = 27 + len(body)
        elif t[0] == 'bytes':
            body += bytes.fromhex(''.join(t[1:]))
        else:
            raise ValueError('res_stc: cannot read %r' % line)
    for at, ref in patrefs:
        v = marks[int(ref[1:])] if ref[0] == 's' else int(ref[1:], 16)
        body[at:at + 2] = bytes([v & 255, v >> 8])
    for k, off in ((1, 'positions'), (3, 'ornaments'), (5, 'patterns')):
        v = marks.get(off, 0)
        head[k:k + 2] = bytes([v & 255, v >> 8])
    return bytes(head + body)


def to_editable(name, data):
    return '.txt', to_text(data).encode()


def from_editable(name, data):
    return from_text(data.decode())


if __name__ == '__main__':
    if sys.argv[1] == 'dump':
        sys.stdout.write(to_text(open(sys.argv[2], 'rb').read()))
