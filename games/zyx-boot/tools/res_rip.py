#!/usr/bin/env python3
"""The tunes of the one-off game-rip players of five variants as text and back: music/KIND.bin <-> music/KIND.txt in
a variant's folder (tools/variants_music.py splits the music piece; the players are variants/players/KIND/*.ann).

    python3 tools/res_rip.py dump KIND TUNE.bin      # print the text

    KIND        variant    the tune of
    hydrofool   zyxalex    Hydrofool (Rob Hubbard)
    megaapoc    zyxdimob   Mega Apocalypse (Rob Hubbard)
    ziutek      zyxfp4bt   Part V (Ziutek)
    awbt        zyxawbt    (not identified)
    fp3bt       zyxfp3bt   (not identified)

Each player reads its tune by absolute addresses fixed in its code, so a tune is a set of blocks at fixed places:
tables the code points at (the roots of SPECS) and what their words point to. The text is the tune's blocks in
address order, each under a header line `NAME: KIND [base $XXXX]` (`-: bytes` for bytes nothing points to):
  bytes, rows N    hex bytes (rows: N a line);
  words            words, each a label (`Name`, `Name+N`) or a raw value (`$XXXX`); with `base`, a word holds the
                   address less the base;
  offsets          bytes, each a label: the address less the block's own address;
  stream           the player's pattern items (GRAMMARS): `name`, `nameN` (a range of bytes, N from its first byte)
                   or a note name, and `:XX,YY` for the item's argument bytes;
  song, seq, voice the awbt player's song list (`play SEQ_A SEQ_B SEQ_C` or a command: `voices VA VB`, `call SONG`,
                   `ret`, `transpose XX YY`, `tempo XX YY`, `stopN`), its sequences (`speed XX`, then voice numbers
                   up to $FF) and voices (`head NOTE SPEED STEP`, then `VOLUME:PITCH` pairs up to $FF).
`format KIND` and `org $XXXX` (the first byte) head the text. Text -> bytes lays the blocks one after another,
resolves the labels and checks that every root lands where the player's code reads it.
"""
import re
import sys

NAMES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
LAST = {'org': 0, 'format': 'hydrofool'}


def note_name(n):
    return '%s%d' % (NAMES[n % 12], n // 12)


NOTE = {note_name(n): n for n in range(0x80)}

# A grammar: (first byte, last byte, name, argument bytes, what the item does to the walk: '' goes on, 'row' ends
# a row (a new line), 'end' ends the block); name 'NOTE' writes the byte less the first byte as a note name.
GRAMMARS = {
    'hydrofool': [  # the stream reader at $F675
        (0x00, 0x7F, 'NOTE', 0, 'row'), (0x80, 0x80, 'rest', 0, 'row'), (0x81, 0x81, 'sweepoff', 0, ''),
        (0x82, 0x82, 'sweepup', 0, ''), (0x83, 0x83, 'sweepdown', 0, ''), (0x84, 0x84, 'slide', 2, ''),
        (0x85, 0x85, 'bendup', 0, ''), (0x86, 0x86, 'benddown', 0, ''), (0x87, 0x87, 'end', 0, 'end'),
        (0x88, 0x88, 'sweep', 2, ''), (0x89, 0x89, 'transpose', 1, ''), (0x8A, 0x8A, 'tone', 0, ''),
        (0x8B, 0x8B, 'noise', 0, ''), (0x8C, 0x8C, 'both', 0, ''), (0x8D, 0x8D, 'flag', 0, ''),
        (0x8E, 0x8E, 'stop', 0, 'end'), (0x8F, 0x8F, 'hold', 0, 'row'), (0x90, 0x90, 'lock', 0, ''),
        (0x91, 0x91, 'unlock', 0, ''), (0x92, 0xB7, 'x', 0, ''), (0xB8, 0xBF, 'tempo', 0, ''),
        (0xC0, 0xCF, 'orn', 0, ''), (0xD0, 0xDF, 'instr', 3, ''), (0xE0, 0xFF, 'dur', 0, '')],
    'megaapoc': [  # the stream reader at $E707
        (0x00, 0x7F, 'NOTE', 0, 'row'), (0x80, 0x80, 'rest', 0, 'row'), (0x81, 0x81, 'plain', 0, ''),
        (0x82, 0x82, 'sweep', 2, ''), (0x83, 0x83, 'drumon', 0, ''), (0x84, 0x84, 'hold', 0, ''),
        (0x85, 0x85, 'end', 0, 'end'), (0x86, 0x86, 'vibrato', 2, ''), (0x87, 0x87, 'noiseon', 0, ''),
        (0x88, 0x88, 'stop', 0, 'end'), (0x89, 0x89, 'transpose', 1, ''), (0x8A, 0x8A, 'mixon', 0, ''),
        (0x8B, 0x8B, 'noise', 1, ''), (0x8C, 0x8C, 'tie', 0, ''), (0x8D, 0xAF, 'x', 0, ''),
        (0xB0, 0xBF, 'arp', 0, ''), (0xC0, 0xDF, 'env', 0, ''), (0xE0, 0xFF, 'dur', 0, '')],
    'ziutek': [  # the pattern reader at $C861 (ranges from the table at $C845)
        (0x00, 0x0D, 'next', 0, 'end'), (0x0E, 0x1D, 'env', 1, ''), (0x1E, 0x34, 'off', 0, 'row'),
        (0x35, 0x44, 'orn', 0, ''), (0x45, 0x84, 'dur', 0, ''), (0x85, 0x8E, 'hold', 0, 'row'),
        (0x8F, 0xEE, 'NOTE', 0, 'row'), (0xEF, 0xFE, 'smp', 0, ''), (0xFF, 0xFF, 'xFF', 0, '')],
    'fp3bt': [  # the stream reader at $C182: two bytes an item (but `n.`), the second the duration or argument
        (0x00, 0x00, 'rest', 1, 'row'), (0x01, 0x08, 'start', 1, ''), (0x09, 0x64, 'NOTE', 1, 'row'),
        (0x65, 0xE3, 'TIE', 0, 'row'), (0xE4, 0xE5, 'stopa', 1, 'end'), (0xE6, 0xE6, 'noise', 1, ''),
        (0xE7, 0xE7, 'stop', 1, 'end'), (0xE8, 0xE8, 'hold', 0, ''), (0xE9, 0xE9, 'env', 1, ''),
        (0xEA, 0xEA, 'orn', 1, ''), (0xEB, 0xEB, 'vib', 1, ''), (0xEC, 0xEC, 'detune', 1, ''),
        (0xED, 0xED, 'transpose', 1, ''), (0xEE, 0xEE, 'call', 1, ''), (0xEF, 0xFE, 'stopb', 1, 'end'),
        (0xFF, 0xFF, 'ret', 0, 'end')],
}

# KIND: org (the tune's first byte), the roots (address, name, block kind, parameters), the walk of each word kind
SPECS = {
    'hydrofool': {'org': 0xF8F1, 'end': 0xFE24, 'roots': [
        (0xF8F1, 'Arpeggios', 'offsets', {'n': 'auto', 'child': 'arp'}),
        (0xF939, 'Playing', 'bytes', {'n': 1}),
        (0xF93A, 'Songs', 'words', {'n': 'auto', 'child': 'order'})]},
    'megaapoc': {'org': 0xE960, 'end': 0xEF05, 'roots': [
        (0xEA76, 'Arpeggios', 'bytes', {}),
        (0xEA8F, 'Envelopes', 'bytes', {}),
        (0xEB38, 'Tempo', 'bytes', {'n': 1}),
        (0xEB39, 'Song', 'words', {'n': 3, 'child': 'order'}),
        (0xEE94, 'Effects', 'rows', {'w': 18})]},
    'ziutek': {'org': 0xCA83, 'end': 0xD280, 'roots': [
        (0xCCFF, 'Positions', 'rows', {'n': 56, 'w': 2}),
        (0xCD37, 'Patterns', 'words', {'n': 21, 'child': 'stream'}),
        (0xCD61, 'Samples', 'rows', {'n': 9 * 98, 'w': 98}),
        (0xD0D3, 'Ornaments', 'rows', {'w': 32})]},
    'awbt': {'org': 0xC4E9, 'end': 0xD2FB, 'roots': [
        (0xC4E9, 'Songs', 'words', {'n': 6, 'child': 'song'})]},
    'fp3bt': {'org': 0xC518, 'end': 0xD600, 'roots': [
        (0xC518, 'Shapes', 'words', {'n': 44, 'base': 0xC450, 'child': 'shape'}),
        (0xC570, 'Shapes2', 'words', {'n': 16, 'base': 0xC450}),     # read by the same code: past the shapes
        (0xC590, 'Streams', 'words', {'n': 76, 'base': 0xC450, 'child': 'stream'})]},
}
BYTES = ('bytes', 'rows', 'arp', 'shape')
PREFIX = {'arp': 'Arpeggio', 'shape': 'Shape', 'order': 'Order', 'stream': 'Pattern', 'bytes': 'Data', 'song': 'Song', 'seq': 'Seq', 'voice': 'Voice',
          'rows': 'Data', 'words': 'Table', 'offsets': 'Table'}


def w(d, a):
    return d[a] | d[a + 1] << 8


class Tune:
    def __init__(self, d, kind):
        self.d, self.kind, self.spec = d, kind, SPECS[kind]
        self.org = self.spec['org']
        self.end = self.org + len(d)
        self.known = {r[0] for r in self.spec['roots']}

    def b(self, a):
        return self.d[a - self.org]

    def inside(self, a):
        return self.org <= a < self.end


# ------------------------------------------------------------------------------------------------ the items

def stream_item(g, d, i):
    """(length, text, flag) of the stream item at offset i"""
    b = d[i]
    for lo, hi, name, n, flag in g:
        if lo <= b <= hi:
            if name == 'NOTE':
                t = note_name(b - lo)
            elif name == 'TIE':
                t = 'n.' + note_name(b & 0x7F)
            else:
                t = name if lo == hi else '%s%d' % (name, b - lo)
            if n:
                t += ':' + ','.join('%02X' % x for x in d[i + 1:i + 1 + n])
            return 1 + n, t, flag
    raise ValueError('res_rip: no item for $%02X' % b)


def stream_encode(g, tok):
    name, _, args = tok.partition(':')
    ops = bytes(int(x, 16) for x in args.split(',')) if args else b''
    for lo, hi, gname, n, flag in g:
        if gname == 'NOTE' and name in NOTE and lo + NOTE[name] <= hi:
            return bytes([lo + NOTE[name]]) + ops
        if gname == 'TIE' and name.startswith('n.') and name[2:] in NOTE:
            v = NOTE[name[2:]]
            return bytes([v if v >= 0x65 else v | 0x80]) + ops
        if gname == name and lo == hi:
            return bytes([lo]) + ops
        m = re.match(re.escape(gname) + r'(\d+)$', name)
        if m and lo + int(m.group(1)) <= hi and lo != hi:
            return bytes([lo + int(m.group(1))]) + ops
    raise ValueError('res_rip: cannot read %r' % tok)


# the awbt player's song list (the reader at $C1C4): two bytes an item, the second not 0: three words, the
# sequences of channels A, B and C; the second 0: a command, the first byte its number
AW_CMDS = {1: ('voices', 'ww'), 2: ('call', 'w'), 3: ('transpose', 'bb'), 4: ('ret', ''), 5: ('tempo', 'bb')}


def walk(t, a, kind, p):
    """(the block's length or None: up to the next block, [(address, kind, parameters)] of what it points to)"""
    d, o = t.d, t.org
    i = a - o
    if kind in BYTES:
        return p.get('n'), []
    if kind in ('words', 'offsets'):
        size = 2 if kind == 'words' else 1
        n, out, k = p.get('n'), [], 0
        lim = min([x - o for x in t.known if x > a] + [len(d)])
        while (n == 'auto' and i + size * k < lim) or (isinstance(n, int) and k < n):
            v = w(d, i + size * k) if size == 2 else d[i + k]
            to = (p.get('base', 0) + v) if size == 2 else a + v
            k += 1
            if t.inside(to) and p.get('child'):
                out.append((to, p['child'], {}))
                t.known.add(to)
                if n == 'auto':
                    lim = min(lim, to - o)
        return size * k, out
    if kind == 'order':
        k, out = 0, []
        while i + 2 * k + 1 < len(d):
            v = w(d, i + 2 * k)
            k += 1
            if not v:
                break
            if t.inside(v):
                out.append((v, 'stream', {}))
        return 2 * k, out
    if kind == 'stream':
        g, j = GRAMMARS[t.kind], i
        while j < len(d):
            n, _t, flag = stream_item(g, d, j)
            j += n
            if flag == 'end':
                break
        return j - i, []
    if kind == 'song':
        j, out = i, []
        while j + 1 < len(d):
            if d[j + 1]:
                for k in range(3):
                    if t.inside(w(d, j + 2 * k)):
                        out.append((w(d, j + 2 * k), 'seq', {}))
                j += 6
                continue
            c = d[j]
            j += 2
            if c not in AW_CMDS:
                break
            for f in AW_CMDS[c][1]:
                if f == 'w' and t.inside(w(d, j)):
                    out.append((w(d, j), 'song' if c == 2 else 'voice', {}))
                j += 2 if f == 'w' else 1
        return j - i, out
    if kind == 'seq':      # a speed, then bytes up to $FF
        j = i + 1
        while j < len(d) and d[j] != 0xFF:
            j += 1
        return j + 1 - i, []
    if kind == 'voice':    # a base note, a speed and a step, then (volume, note) pairs up to a volume $FF
        j = i + 3
        while j < len(d) and d[j] != 0xFF:
            j += 2
        return j + 1 - i, []
    raise ValueError(kind)


def blocks_of(t):
    """{address: (name, kind, parameters)} of every block the roots reach"""
    starts, todo = {}, [(a, k, dict(p, name=nm)) for a, nm, k, p in t.spec['roots']]
    while todo:
        a, k, p = todo.pop(0)
        if a in starts:
            continue
        starts[a] = (p.get('name'), k, p)
        _n, more = walk(t, a, k, p)
        todo += more
    count = {}
    for a in sorted(starts):
        nm, k, p = starts[a]
        if not nm:
            pre = PREFIX[k]
            count[pre] = count.get(pre, 0) + 1
            starts[a] = ('%s%d' % (pre, count[pre]), k, p)
    return starts


def to_text(d, org=None, kind=None):
    kind = kind or LAST['format']
    t = Tune(d, kind)
    starts = blocks_of(t)
    order = sorted(starts)

    def ref(v, base=0):
        to = base + v
        if to in starts:
            return starts[to][0]
        if t.inside(to):
            s = max(x for x in order if x <= to)
            return '%s+%d' % (starts[s][0], to - s)
        return '$%04X' % v

    out = ['# A tune of the %s player (tools/res_rip.py): its blocks in address order.' % kind,
           'format ' + kind, 'org $%04X' % t.org]
    a = t.org
    if order[0] != a:
        order.insert(0, a)
        starts[a] = ('-', 'bytes', {})
    for k, s in enumerate(order):
        nxt = order[k + 1] if k + 1 < len(order) else t.end
        nm, kd, p = starts[s]
        n, _x = walk(t, s, kd, p)
        n = nxt - s if n is None else min(n, nxt - s)
        lines = block_lines(t, s, n, kd, p, ref)
        if lines is None:          # the block does not decode inside its room: bytes
            kd, n, p = 'bytes', nxt - s, {}
            lines = block_lines(t, s, n, kd, p, ref)
        head = '%s: %s' % (nm, kd)
        if p.get('base'):
            head += ' base $%04X' % p['base']
        if kd == 'rows':
            head += ' %d' % p['w']
        out.append(head)
        out += lines
        if n < nxt - s:
            out.append('-: bytes')
            out += block_lines(t, s + n, nxt - s - n, 'bytes', {}, ref)
    return '\n'.join(out) + '\n'


def block_lines(t, a, n, kind, p, ref):
    d, i = t.d, a - t.org
    hexrow = lambda bs: '  ' + ' '.join('%02X' % x for x in bs)
    if kind in BYTES:
        wd = p.get('w', 16)
        return [hexrow(d[k:min(k + wd, i + n)]) for k in range(i, i + n, wd)]
    if kind in ('words', 'order'):
        if n % 2:
            return None
        items = [ref(w(d, k), p.get('base', 0)) for k in range(i, i + n, 2)]
        return ['  ' + ' '.join(items[k:k + 8]) for k in range(0, len(items), 8)]
    if kind == 'offsets':
        items = []
        for k in range(i, i + n):
            to = a + d[k]
            items.append(ref(to - a, a) if to - a else '$%02X' % d[k])
        return ['  ' + ' '.join(items[k:k + 8]) for k in range(0, len(items), 8)]
    if kind == 'stream':
        g, j, lines, line = GRAMMARS[t.kind], i, [], []
        while j < i + n:
            m, tx, flag = stream_item(g, d, j)
            if j + m > i + n:
                return None
            line.append(tx)
            j += m
            if flag or len(line) >= 12:
                lines.append('  ' + ' '.join(line))
                line = []
        if line:
            lines.append('  ' + ' '.join(line))
        return lines
    if kind == 'song':
        j, lines = i, []
        while j < i + n:
            if j + 1 >= i + n:
                return None
            if d[j + 1]:
                if j + 6 > i + n:
                    return None
                lines.append('  play ' + ' '.join(ref(w(d, j + 2 * k)) for k in range(3)))
                j += 6
                continue
            c = d[j]
            nm, f = AW_CMDS.get(c, ('stop%d' % c, ''))
            j += 2
            args = []
            for x in f:
                if x == 'w':
                    args.append(ref(w(d, j)))
                    j += 2
                else:
                    args.append('%02X' % d[j])
                    j += 1
            if j > i + n:
                return None
            lines.append('  ' + ' '.join([nm] + args))
        return lines
    if kind == 'seq':
        return ['  speed %02X' % d[i], hexrow(d[i + 1:i + n])] if n > 1 else None
    if kind == 'voice':
        if n < 4 or (n - 4) % 2:
            return None
        lines = ['  head %02X %02X %02X' % tuple(d[i:i + 3])]
        pairs = ['%02X:%02X' % (d[k], d[k + 1]) for k in range(i + 3, i + n - 1, 2)]
        lines += ['  ' + ' '.join(pairs[k:k + 8]) for k in range(0, len(pairs), 8)]
        return lines + ['  FF']
    raise ValueError(kind)


def from_text(text):
    kind, org, blocks = None, 0, []
    for line in text.split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        tk = line.split()
        if tk[0] == 'format':
            kind = tk[1]
        elif tk[0] == 'org':
            org = int(tk[1][1:], 16)
        elif tk[0].endswith(':'):
            p = {}
            if 'base' in tk:
                p['base'] = int(tk[tk.index('base') + 1][1:], 16)
            blocks.append((tk[0][:-1], tk[1], p, []))
        elif line.startswith('  ') and blocks:
            blocks[-1][3].append(tk)
        else:
            raise ValueError('res_rip: cannot read %r' % line)
    LAST.update(format=kind, org=org)
    labels = {}

    def build(look):
        out = bytearray()
        for nm, kd, p, rows in blocks:
            a = org + len(out)
            if nm != '-':
                labels[nm] = a
            out += encode_block(kind, kd, p, rows, a, look)
        return out

    build(lambda s, base=0: 0)
    out = build(lambda s, base=0: resolve(s, labels) - base)
    for a, nm, _k, _p in SPECS[kind]['roots']:
        if labels.get(nm) != a:
            raise ValueError('res_rip: %s lands at $%04X, the player reads it at $%04X' % (nm, labels.get(nm, 0), a))
    return bytes(out)


def resolve(s, labels):
    if s.startswith('$'):
        return int(s[1:], 16)
    m = re.match(r'(\w+)\+(\d+)$', s)
    return labels[m.group(1)] + int(m.group(2)) if m else labels[s]


def encode_block(kind, kd, p, rows, a, look):
    out = bytearray()
    for tk in rows:
        if kd in BYTES:
            out += bytes(int(x, 16) for x in tk)
        elif kd in ('words', 'order'):
            for x in tk:
                v = int(x[1:], 16) if x.startswith('$') else look(x, p.get('base', 0)) & 0xFFFF
                out += bytes([v & 255, v >> 8])
        elif kd == 'offsets':
            for x in tk:
                out.append(int(x[1:], 16) if x.startswith('$') else (look(x, a)) & 255)
        elif kd == 'stream':
            for x in tk:
                out += stream_encode(GRAMMARS[kind], x)
        elif kd == 'song':
            if tk[0] == 'play':
                for x in tk[1:]:
                    v = int(x[1:], 16) if x.startswith('$') else look(x) & 0xFFFF
                    out += bytes([v & 255, v >> 8])
                continue
            byname = {v[0]: (c, v[1]) for c, v in AW_CMDS.items()}
            c, f = byname[tk[0]] if tk[0] in byname else (int(tk[0][4:]), '')
            out += bytes([c, 0])
            for x, y in zip(f, tk[1:]):
                if x == 'w':
                    v = int(y[1:], 16) if y.startswith('$') else look(y) & 0xFFFF
                    out += bytes([v & 255, v >> 8])
                else:
                    out.append(int(y, 16))
        elif kd == 'seq':
            out += bytes(int(x, 16) for x in (tk[1:] if tk[0] == 'speed' else tk))
        elif kd == 'voice':
            for x in (tk[1:] if tk[0] == 'head' else tk):
                if ':' in x:
                    v, nt = x.split(':')
                    out += bytes([int(v, 16), int(nt, 16)])
                else:
                    out.append(int(x, 16))
        else:
            raise ValueError('res_rip: no block kind %r' % kd)
    return out


def handles(name):
    return any(name.endswith('/%s.bin' % k) for k in SPECS)


def length(d, org=None, version=None):
    return len(d)


def set_org(org, version):
    LAST.update(org=org, format=version)


def to_editable(name, data):
    kind = next((k for k in SPECS if name.endswith('/%s.bin' % k)), LAST['format'])
    return '.txt', to_text(data, kind=kind).encode()


def from_editable(name, data):
    return from_text(data.decode())


if __name__ == '__main__':
    if sys.argv[1] == 'dump':
        sys.stdout.write(to_text(open(sys.argv[3], 'rb').read(), kind=sys.argv[2]))
