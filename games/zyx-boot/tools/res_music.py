#!/usr/bin/env python3
"""The ASC Sound Master tune of the music piece (src/music/music.ann, TuneHeader $C478 - OrnamentData $D592) as text
and back: music/disco.bin <-> music/disco.txt. tools/res_formats.py calls it for every name under music/.

The module is in the ASC Sound Master 0.x layout (no loop byte: the tune loops to position 0):
  +0 delay (frames a row), +1 word the pattern table, +3 word the sample table, +5 word the ornament table (all
  three offsets from the module's start), +7 the number of positions, +8 the positions (pattern numbers);
  the pattern table: per pattern three words, the streams of channels A, B and C (offsets from the pattern table);
  the sample and the ornament tables: 32 words each (offsets from their table); then the streams, the samples (rows
  of 3 bytes) and the ornaments (rows of 2 bytes).

The text keeps that order: the header lines, then `pattern N` with its channels `A`, `B`, `C` (each a stream of
events), then `sample N` and `ornament N` with their rows. The tables and the header's offsets are written back from
the layout, so a stream, a sample or an ornament may grow or shrink. The format is described in
src/res/music/README.md.

    python3 tools/res_music.py dump [music-c000.bin]     # print the text of the image's module (a check)
"""
import re
import sys

ORG = 0xC000
MODULE = 0xC478            # TuneHeader: the module's address in the image (LD DE,TuneHeader in InitPlayer $C053)
NAMES = ['A#', 'B-', 'C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-']   # note 0 = A#0 (MIDI 22)


def handles(name):
    return name == 'music/disco.bin'


def note_name(n):
    return '%s%d' % (NAMES[n % 12], (n + 10) // 12)


NOTE_BY_NAME = {note_name(n): n for n in range(0x56)}


def signed(b):
    return b - 256 if b >= 128 else b


# ----------------------------------------------------------------------------------------------- bytes -> text

def stream_lines(d, start, end):
    """the events of one channel stream d[start:end]: one line a row event (a note, a hold, a release, an off),
    the commands before it on the same line; 'end' for the $FF that closes the pattern"""
    lines, toks, i, env = [], [], start, False
    while i < end:
        b = d[i]
        if b == 0xFF and i == end - 1:
            if toks:
                lines.append(' '.join(toks))
                toks = []
            lines.append('end')
            i += 1
            continue
        if b >= 0x80:
            if b < 0xA0:
                toks.append('s%d' % (b - 0x80))
            elif b < 0xC0:
                toks.append('o%d' % (b - 0xA0))
            elif b == 0xC0:
                toks.append('env')
                env = True
            elif b < 0xD0:
                toks.append('v%d' % (b - 0xC0))
                env = False
            elif b < 0xF0:
                toks.append('n%d' % (b - 0xD0))
            elif b == 0xF0 and i + 1 < end:
                toks.append('len%d' % d[i + 1])
                i += 1
            elif b == 0xF0:
                toks.append('byte $F0')
            else:
                toks.append('shape%d' % (b - 0xF0))
            i += 1
            continue
        if b < 0x56:
            toks.append(note_name(b))
            if env and i + 1 < end:
                toks.append('ep$%02X' % d[i + 1])
                i += 1
        elif b == 0x56:
            toks.append('---')
        elif b < 0x7E:
            toks.append('---$%02X' % b)
        elif b == 0x7E:
            toks.append('rel')
        else:
            toks.append('off')
        lines.append(' '.join(toks))
        toks = []
        i += 1
    if toks:
        lines.append(' '.join(toks))
    return lines


def sample_line(r):
    f, t, m = r
    flags = ('S' if f & 0x80 else '-') + ('L' if f & 0x40 else '-') + ('X' if f & 0x20 else '-')
    noise = f & 0x1F
    mix = ('T' if not m & 1 else '-') + ('N' if not m & 8 else '-') + ('E' if m & 2 else '-') + ('4' if m & 4 else '-')
    return '%s noise %+3d tone %+4d vol %2d %s' % (flags, noise - 32 if noise & 0x10 else noise, signed(t), m >> 4,
                                                     mix)


def ornament_line(r):
    f, n = r
    flags = ('S' if f & 0x80 else '-') + ('L' if f & 0x40 else '-') + ('X' if f & 0x20 else '-')
    noise = f & 0x1F
    return '%s noise %+3d note %+3d' % (flags, noise - 32 if noise & 0x10 else noise, signed(n))


def layout(d):
    """the module's parts as absolute offsets in d (d = the module's bytes), checked to be in the canonical order"""
    w = lambda a: d[a] | d[a + 1] << 8
    pt, st, ot, npos = w(1), w(3), w(5), d[7]
    if pt != 8 + npos:
        raise ValueError('music: the pattern table does not follow the positions')
    first = pt + w(pt)
    if (first - pt) % 6:
        raise ValueError('music: the pattern table is not whole patterns')
    npat = (first - pt) // 6
    streams = [pt + w(pt + 2 * k) for k in range(3 * npat)]
    nsmp = (st + w(st) - st) // 2
    samples = [st + w(st + 2 * k) for k in range(nsmp)]
    norn = (ot + w(ot) - ot) // 2
    orns = [ot + w(ot + 2 * k) for k in range(norn)]
    order = [pt + 6 * npat] + streams + [st, st + 2 * nsmp] + samples + [ot, ot + 2 * norn] + orns
    if streams[0] != pt + 6 * npat or samples[0] != st + 2 * nsmp or orns[0] != ot + 2 * norn:
        raise ValueError('music: a table is not followed by its first block')
    if any(b < a for a, b in zip(order, order[1:])) or order[-1] > len(d):
        raise ValueError('music: the blocks are not in the canonical order')
    return pt, st, ot, npos, streams, samples, orns


def to_text(d):
    pt, st, ot, npos, streams, samples, orns = layout(d)
    out = ['# The ASC Sound Master tune of the ZYX boot menu (src/music/music.ann: TuneHeader $C478 to OrnamentData;',
           '# the format in src/res/music/README.md). The tables and the header offsets are rebuilt from the order of',
           '# the blocks below, so blocks may grow or shrink. "#" starts a comment line.',
           '',
           'delay %d' % d[0],
           'positions ' + ' '.join(str(p) for p in d[8:8 + npos])]
    ends = streams[1:] + [st]
    for k, s in enumerate(streams):
        if k % 3 == 0:
            out += ['', 'pattern %d' % (k // 3)]
        out.append('  %s' % 'ABC'[k % 3])
        out += ['    ' + x for x in stream_lines(d, s, ends[k])]
    ends = samples[1:] + [ot]
    for k, s in enumerate(samples):
        out += ['', 'sample %d' % k]
        if (ends[k] - s) % 3:
            raise ValueError('music: sample %d is not whole rows' % k)
        out += ['  ' + sample_line(d[a:a + 3]) for a in range(s, ends[k], 3)]
    ends = orns[1:] + [len(d)]
    for k, s in enumerate(orns):
        out += ['', 'ornament %d' % k]
        if (ends[k] - s) % 2:
            raise ValueError('music: ornament %d is not whole rows' % k)
        out += ['  ' + ornament_line(d[a:a + 2]) for a in range(s, ends[k], 2)]
    return '\n'.join(out) + '\n'


def to_editable(name, data):
    return '.txt', to_text(data).encode('utf-8')


# ----------------------------------------------------------------------------------------------- text -> bytes

def number(s):
    s = s.strip()
    if s.startswith('$'):
        return int(s[1:], 16)
    return int(s, 10)


def stream_bytes(words, where):
    out = bytearray()
    it = iter(words)
    for t in it:
        if t == 'end':
            out.append(0xFF)
        elif t == 'byte':
            out.append(number(next(it)))
        elif t in NOTE_BY_NAME:
            out.append(NOTE_BY_NAME[t])
        elif t == '---':
            out.append(0x56)
        elif t.startswith('---$'):
            out.append(number(t[3:]))
        elif t == 'rel':
            out.append(0x7E)
        elif t == 'off':
            out.append(0x7F)
        elif t == 'env':
            out.append(0xC0)
        elif re.fullmatch(r's\d+', t):
            out.append(0x80 + int(t[1:]))
        elif re.fullmatch(r'o\d+', t):
            out.append(0xA0 + int(t[1:]))
        elif re.fullmatch(r'v\d+', t):
            out.append(0xC0 + int(t[1:]))
        elif re.fullmatch(r'n\d+', t):
            out.append(0xD0 + int(t[1:]))
        elif re.fullmatch(r'len\d+', t):
            out += bytes([0xF0, int(t[3:])])
        elif re.fullmatch(r'shape\d+', t):
            out.append(0xF0 + int(t[5:]))
        elif re.fullmatch(r'ep\$[0-9A-Fa-f]{2}', t):
            out.append(int(t[3:], 16))
        else:
            raise ValueError('music: line %d: cannot read %r' % (where['line'], t))
    return out


def flag_bits(s, letters, bits, where):
    v = 0
    for ch, letter, bit in zip(s, letters, bits):
        if ch == letter:
            v |= bit
        elif ch != '-':
            raise ValueError('music: line %d: flags %r' % (where['line'], s))
    return v


def row_bytes(kind, words, where):
    if kind == 'sample':
        # FLAGS noise N tone T vol V MIX
        if len(words) != 8 or words[1] != 'noise' or words[3] != 'tone' or words[5] != 'vol':
            raise ValueError('music: line %d: a sample row is FLAGS noise N tone T vol V MIX' % where['line'])
        f = flag_bits(words[0], 'SLX', (0x80, 0x40, 0x20), where) | (int(words[2]) & 0x1F)
        m = int(words[6]) << 4
        mix = words[7]
        m |= (0 if mix[0] == 'T' else 1) | (0 if mix[1] == 'N' else 8) | (2 if mix[2] == 'E' else 0) | \
            (4 if mix[3] == '4' else 0)
        return bytes([f, int(words[4]) & 255, m])
    if len(words) != 5 or words[1] != 'noise' or words[3] != 'note':
        raise ValueError('music: line %d: an ornament row is FLAGS noise N note D' % where['line'])
    f = flag_bits(words[0], 'SLX', (0x80, 0x40, 0x20), where) | (int(words[2]) & 0x1F)
    return bytes([f, int(words[4]) & 255])


def from_text(text):
    delay, positions = None, None
    patterns, samples, orns = [], [], []
    cur = None          # the list the next rows go to
    where = {}
    for no, raw in enumerate(text.splitlines(), 1):
        where['line'] = no
        line = raw.rstrip()
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        words = line.split()
        indent = len(line) - len(line.lstrip())
        if indent == 0:
            if words[0] == 'delay':
                delay = number(words[1])
            elif words[0] == 'positions':
                positions = [number(x) for x in words[1:]]
            elif words[0] in ('pattern', 'sample', 'ornament'):
                lst = {'pattern': patterns, 'sample': samples, 'ornament': orns}[words[0]]
                if number(words[1]) != len(lst):
                    raise ValueError('music: line %d: %s %s out of order' % (no, words[0], words[1]))
                lst.append([] if words[0] == 'pattern' else bytearray())
                cur = (words[0], lst[-1])
            else:
                raise ValueError('music: line %d: cannot read %r' % (no, line))
        elif cur and cur[0] == 'pattern':
            if words[0] in ('A', 'B', 'C') and len(words) == 1:
                if 'ABC'[len(cur[1])] != words[0]:
                    raise ValueError('music: line %d: channel %s out of order' % (no, words[0]))
                cur[1].append(bytearray())
            elif not cur[1]:
                raise ValueError('music: line %d: an event before the channel' % no)
            else:
                cur[1][-1] += stream_bytes(words, where)
        elif cur:
            cur[1].extend(row_bytes(cur[0], words, where))
        else:
            raise ValueError('music: line %d: a row before any block' % no)
    if delay is None or positions is None:
        raise ValueError('music: delay and positions are required')
    for k, p in enumerate(patterns):
        if len(p) != 3:
            raise ValueError('music: pattern %d needs channels A, B and C' % k)
    pt = 8 + len(positions)
    body = bytearray()
    table = bytearray()
    at = 6 * len(patterns)
    for p in patterns:
        for s in p:
            table += bytes([at & 255, at >> 8])
            at += len(s)
            body += s
    st = pt + len(table) + len(body)
    stab, sbody, at = bytearray(), bytearray(), 2 * len(samples)
    for s in samples:
        stab += bytes([at & 255, at >> 8])
        at += len(s)
        sbody += s
    ot = st + len(stab) + len(sbody)
    otab, obody, at = bytearray(), bytearray(), 2 * len(orns)
    for s in orns:
        otab += bytes([at & 255, at >> 8])
        at += len(s)
        obody += s
    head = bytes([delay, pt & 255, pt >> 8, st & 255, st >> 8, ot & 255, ot >> 8, len(positions)]) + bytes(positions)
    return bytes(head + table + body + stab + sbody + otab + obody)


def from_editable(name, data):
    return from_text(data.decode('utf-8'))


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == 'dump':
        path = sys.argv[2] if len(sys.argv) > 2 else 'work/parts/music-c000.bin'
        img = open(path, 'rb').read()
        mod = img[MODULE - ORG:0xD593 - ORG]
        text = to_text(mod)
        sys.stdout.write(text)
        if from_text(text) != mod:
            sys.stderr.write('music: the text does not give the module back\n')
            return 1
        return 0
    print(__doc__)
    return 0


if __name__ == '__main__':
    sys.exit(main())
