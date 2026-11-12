#!/usr/bin/env python3
"""An ASC Sound Master tune as text and back: the music piece's (src/music/music.ann, TuneHeader $C478 - OrnamentData
$D592), music/disco.bin <-> music/disco.txt, and a variant's (the ASC player of zyxboot-14..18,
variants/players/asc2), music/asc.bin <-> music/asc.txt (tools/variants_music.py splits the variant's piece).
tools/res_formats.py asks it about every name under music/.

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
    return name == 'music/disco.bin' or name.endswith('/asc.bin') or name.endswith('/asc1.bin')


def note_name(n):
    return '%s%d' % (NAMES[n % 12], (n + 10) // 12)


NOTE_BY_NAME = {note_name(n): n for n in range(0x56)}


def signed(b):
    return b - 256 if b >= 128 else b


# ----------------------------------------------------------------------------------------------- bytes -> text

def stream_lines(d, start, end, v2=False):
    """the events of one channel stream d[start:end]: one line a row event (a note, a hold, a release, an off),
    the commands before it on the same line; 'end' for the $FF that closes the pattern. v2: the command set of the
    variants' player (variants/players/asc2), stream_lines_v2"""
    if v2 == 'asc1':
        return stream_lines_v2(d, start, end, asc1=True)
    if v2:
        return stream_lines_v2(d, start, end)
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


# ASC Sound Master 1.x (variants/players/asc1, zyxboot-01): $F0-$FF are 16 commands, some with an operand byte
ASC1 = {0xF0: ('noise', 1), 0xF1: ('contsmp', 0), 0xF2: ('contorn', 0), 0xF3: ('contboth', 0), 0xF4: ('delay', 1),
        0xF5: ('glissdn', 1), 0xF6: ('glissup', 1), 0xF7: ('slide', 1), 0xF8: ('shape8', 0), 0xF9: ('slidenote', 1),
        0xFA: ('shape10', 0), 0xFB: ('volslide', 1), 0xFC: ('shape12', 0), 0xFE: ('shape14', 0)}
ASC1_BY_NAME = {v[0]: (k, v[1]) for k, v in ASC1.items()}


def stream_lines_v2(d, start, end, asc1=False):
    """the variants' player (variants/players/asc2, ChannelRow): $00-$55 a note (and the envelope period byte in
    envelope mode), $56-$5D a hold, $5E release, $5F off; commands: $60-$9F the row length 0-63 (len), $A0-$BF the
    sample, $C0-$DF the ornament, $E0 envelope mode, $E1-$EF the volume, $F0 n the noise base, $F1-$FF the shape"""
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
        if b >= 0x60:
            if b < 0xA0:
                toks.append('len%d' % (b - 0x60))
            elif b < 0xC0:
                toks.append('s%d' % (b - 0xA0))
            elif b < 0xE0:
                toks.append('o%d' % (b - 0xC0))
            elif b == 0xE0:
                toks.append('env')
                env = True
            elif b < 0xF0:
                toks.append('v%d' % (b - 0xE0))
                env = False
            elif asc1 and b in ASC1 and i + ASC1[b][1] < end:
                name, n = ASC1[b]
                toks.append(name + ('%d' % d[i + 1] if n else ''))
                i += n
            elif asc1:
                toks.append('byte $%02X' % b)
            elif b == 0xF0 and i + 1 < end:
                toks.append('noise%d' % d[i + 1])
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
        elif b < 0x5E:
            toks.append('---$%02X' % b)
        elif b == 0x5E:
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


def layout(d, h=0):
    """the module's parts as absolute offsets in d (d = the module's bytes), checked to be in the canonical order;
    h = 1: the ASC Sound Master 1.x header (a loop position byte after the delay)"""
    w = lambda a: d[a] | d[a + 1] << 8
    pt, st, ot, npos = w(1 + h), w(3 + h), w(5 + h), d[7 + h]
    if pt != 8 + h + npos:
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


HEADER = ['# The ASC Sound Master tune of the ZYX boot menu (src/music/music.ann: TuneHeader $C478 to OrnamentData;',
          '# the format in src/res/music/README.md). The tables and the header offsets are rebuilt from the order of',
          '# the blocks below, so blocks may grow or shrink. "#" starts a comment line.']
VARIANT_HEADER = ['# An ASC Sound Master tune (the module after the player of variants/players/asc2; the format in',
                  '# src/res/music/README.md). The tables and the header offsets are rebuilt from the order of the',
                  '# blocks below, so blocks may grow or shrink. "#" starts a comment line.']


VARIANT1_HEADER = ['# An ASC Sound Master 1.x tune (the module after the player of variants/players/asc1: a loop position in',
                   '# the header, commands $F0-$FF with operands; the format in src/res/music/README.md). The tables and',
                   '# the header offsets are rebuilt from the order of the blocks below. "#" starts a comment line.']


def length(d, h=0):
    """the module's length in d (the module and what follows it): the last ornament ends with its first row that
    has the loop flag (L)"""
    a = layout(d, h)[6][-1]
    while a + 2 <= len(d) and not d[a] & 0x40:
        a += 2
    return a + 2


def to_text(d, header=HEADER, v2=False):
    h = 1 if v2 == 'asc1' else 0
    pt, st, ot, npos, streams, samples, orns = layout(d, h)
    out = header + (['', 'layout asc1', 'commands asc1'] if h else ['', 'commands v2'] if v2 else []) + [
           '',
           'delay %d' % d[0]] + (['loop %d' % d[1]] if h else []) + [
           'positions ' + ' '.join(str(p) for p in d[8 + h:8 + h + npos])]
    ends = streams[1:] + [st]
    for k, s in enumerate(streams):
        if k % 3 == 0:
            out += ['', 'pattern %d' % (k // 3)]
        out.append('  %s' % 'ABC'[k % 3])
        out += ['    ' + x for x in stream_lines(d, s, ends[k], v2)]
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
    if name.endswith('/asc1.bin'):
        return '.txt', to_text(data, VARIANT1_HEADER, v2='asc1').encode('utf-8')
    if name == 'music/disco.bin':
        return '.txt', to_text(data).encode('utf-8')
    return '.txt', to_text(data, VARIANT_HEADER, v2=True).encode('utf-8')


# ----------------------------------------------------------------------------------------------- text -> bytes

def number(s):
    s = s.strip()
    if s.startswith('$'):
        return int(s[1:], 16)
    return int(s, 10)


V2 = {'---': 0x56, 'rel': 0x5E, 'off': 0x5F, 'env': 0xE0}


def stream_bytes_v2(words, where, asc1=False):
    out = bytearray()
    it = iter(words)
    for t in it:
        m1 = re.fullmatch(r'([a-z]+?)(\d*)', t) if asc1 else None
        if m1 and t not in ASC1_BY_NAME and m1.group(1) in ASC1_BY_NAME and ASC1_BY_NAME[m1.group(1)][1] and m1.group(2):
            out += bytes([ASC1_BY_NAME[m1.group(1)][0], int(m1.group(2))])
            continue
        if asc1 and t in ASC1_BY_NAME and not ASC1_BY_NAME[t][1]:
            out.append(ASC1_BY_NAME[t][0])
            continue
        if t == 'end':
            out.append(0xFF)
        elif t == 'byte':
            out.append(number(next(it)))
        elif t in NOTE_BY_NAME:
            out.append(NOTE_BY_NAME[t])
        elif t in V2:
            out.append(V2[t])
        elif t.startswith('---$'):
            out.append(number(t[3:]))
        else:
            m = re.fullmatch(r'(len|s|o|v|noise|shape)(\d+)', t)
            if m:
                k, n = m.group(1), int(m.group(2))
                out += bytes({'len': [0x60 + n], 's': [0xA0 + n], 'o': [0xC0 + n], 'v': [0xE0 + n], 'noise': [0xF0, n],
                        'shape': [0xF0 + n]}[k])
            elif re.fullmatch(r'ep\$[0-9A-Fa-f]{2}', t):
                out.append(int(t[3:], 16))
            else:
                raise ValueError('music: line %d: cannot read %r' % (where['line'], t))
    return out


def stream_bytes(words, where, v2=False):
    if v2 == 'asc1':
        return stream_bytes_v2(words, where, asc1=True)
    if v2:
        return stream_bytes_v2(words, where)
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
    delay, positions, v2, h, loop = None, None, False, 0, None
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
            if words == ['commands', 'v2']:
                v2 = True
            elif words == ['commands', 'asc1']:
                v2 = 'asc1'
            elif words == ['layout', 'asc1']:
                h = 1
            elif words[0] == 'loop':
                loop = number(words[1])
            elif words[0] == 'delay':
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
                cur[1][-1] += stream_bytes(words, where, v2)
        elif cur:
            cur[1].extend(row_bytes(cur[0], words, where))
        else:
            raise ValueError('music: line %d: a row before any block' % no)
    if delay is None or positions is None:
        raise ValueError('music: delay and positions are required')
    for k, p in enumerate(patterns):
        if len(p) != 3:
            raise ValueError('music: pattern %d needs channels A, B and C' % k)
    pt = 8 + h + len(positions)
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
    head = bytes([delay] + ([loop] if h else []) + [pt & 255, pt >> 8, st & 255, st >> 8, ot & 255, ot >> 8,
                                                     len(positions)]) + bytes(positions)
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
