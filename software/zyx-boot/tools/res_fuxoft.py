#!/usr/bin/env python3
"""The tune of Frantisek Fuka's (Fuxoft's) music player as text and back: music/fuxoft.bin <-> music/fuxoft.txt in a
variant's folder (tools/variants_music.py splits the music piece).

    python3 tools/res_fuxoft.py dump TUNE.bin       # print the text

The player (variants/players/fuxoft/fuxoft.ann) sits at $EB50 in every variant that has it and reads its tune from
$F035 on, by absolute addresses. The format, as the player's code reads it:
  $F035 three words: the start of channel A's, B's and C's stream;
  a stream, one item after another: a note byte $01-$7F (the note + the channel's transposition indexes the period
    table: 1 is A-0) or $00 (silence) and a duration byte (frames); or a command $80-$8E:
    $80 w goto, $81 w call (a sub-stream that ends with $89), $82 n repeat n times up to $83 (next),
    $84 n the noise period, $85 n the channel's mixer bits, $86 w the ornament, $87 w the instrument,
    $88 n the transposition, $89 return, $8A tie on (a note keeps the instrument running), $8B tie off,
    $8C w call machine code, $8D n noise += n, $8E n transposition += n;
  an instrument: a volume and its frames, then the volume stream: a byte below $1E and its frames, or a byte
    $1E or above (volume = byte - $32, one frame), or $80 w goto;
  an ornament, one byte a frame: $80 w goto, $82 the bytes are notes added to the note, $83 the bytes are signed
    steps added to the tone period, $84 toggle the channel's tone and noise (mixer bits XOR 9), else the value.
The text names every address a word points to (a label, its kind after the colon) and keeps the bytes in their order;
bytes no walk reaches are `bytes` lines where they lie. Text -> bytes assembles in that order and resolves the labels,
so a block may grow or shrink. The format is in src/res/music/README.md.
"""
import sys

ORG = 0xF035
NAMES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
# command byte: (name, argument: '' none, 'b' a byte, 'w' a word, kind of what the word points to, ends the block)
CMDS = {0x80: ('goto', 'w', 'stream', True), 0x81: ('call', 'w', 'stream', False), 0x82: ('repeat', 'b', '', False),
        0x83: ('next', '', '', False), 0x84: ('noise', 'b', '', False), 0x85: ('mixer', 'b', '', False),
        0x86: ('orn', 'w', 'ornament', False), 0x87: ('instr', 'w', 'instrument', False),
        0x88: ('transp', 'b', '', False), 0x89: ('ret', '', '', True), 0x8A: ('tie', '', '', False),
        0x8B: ('untie', '', '', False), 0x8C: ('code', 'w', 'code', False), 0x8D: ('noise+', 'b', '', False),
        0x8E: ('transp+', 'b', '', False)}
BYNAME = {v[0]: (k,) + v[1:] for k, v in CMDS.items()}
PITCH = {0x82: 'notes', 0x83: 'steps', 0x84: 'noisemix'}
PITCHB = {v: k for k, v in PITCH.items()}


def handles(name):
    return name.endswith('/fuxoft.bin')


def note_name(n):
    i = n - 1 + 9
    return '%s%d' % (NAMES[i % 12], i // 12)


NOTE = {note_name(n): n for n in range(1, 0x80)}


def s8(b):
    return b - 256 if b >= 128 else b


def w(d, a):
    return d[a] | d[a + 1] << 8


# ----------------------------------------------------------------------------------------------- bytes -> text

def decode(d, org):
    """items {address: (length, kind, text with {target} slots, targets, ends)} reached from the three channels"""
    n = len(d)
    end = org + n
    items, todo, done = {}, [], set()
    roots = [w(d, 2 * k) for k in range(3)]
    for r in roots:
        todo.append((r, 'stream'))
    while todo:
        a, kind = todo.pop()
        if (a, kind) in done or not org + 6 <= a < end or kind == 'code':
            continue
        done.add((a, kind))
        first = True
        while org + 6 <= a < end:
            if a in items:
                break         # read before (as this kind, or as another one: the bytes then serve both)
            b = d[a - org]
            refs, stop, ln = [], False, 1
            if kind == 'stream':
                if b < 0x80:
                    ln, text = 2, ('%s/%d' % (note_name(b) if b else 'r', d[a + 1 - org]) if a + 1 < end else None)
                elif b in CMDS:
                    name, arg, tk, stop = CMDS[b]
                    if arg == 'b':
                        ln, text = 2, '%s:%d' % (name, s8(d[a + 1 - org]) if name.endswith('+') or name == 'transp'
                                                 else d[a + 1 - org])
                    elif arg == 'w':
                        ln, text, refs = 3, name + ':{0}', [(w(d, a + 1 - org), tk)]
                    else:
                        text = name
                else:
                    text = '$%02X' % b
            elif kind == 'instrument':
                if b == 0x80:
                    ln, text, refs, stop = 3, 'goto:{0}', [(w(d, a + 1 - org), 'instrument')], True
                elif first or b < 0x1E:
                    ln, text = 2, '%d/%d' % (b, d[a + 1 - org]) if a + 1 < end else None
                else:
                    text = '%d' % (b - 0x32)
            else:   # ornament
                if b == 0x80:
                    ln, text, refs, stop = 3, 'goto:{0}', [(w(d, a + 1 - org), 'ornament')], True
                elif b in PITCH:
                    text = PITCH[b]
                else:
                    text = '%d' % s8(b)
            if text is None or a + ln > end or (ln == 3 and refs[0][0] is None):
                break
            items[a] = (ln, kind, text, [t for t, _ in refs], stop)
            for t, tk in refs:
                todo.append((t, tk))
            a += ln
            first = False
            if stop:
                break
    return roots, items


def to_text(d, org=ORG):
    roots, items = decode(d, org)
    end = org + len(d)
    # labels: every address a word names that lies in the module
    kinds = {}
    for a, (ln, kind, text, tg, stop) in items.items():
        for t in tg:
            if org <= t < end:
                kinds.setdefault(t, items[t][1] if t in items else 'code')
    for k, r in enumerate(roots):
        kinds[r] = 'stream'
    labels = {}
    for k, r in enumerate(roots):
        labels.setdefault(r, 'channel' + 'ABC'[k])
    pre = {'stream': 's', 'instrument': 'instr', 'ornament': 'orn', 'code': 'code'}
    for t in sorted(kinds):
        labels.setdefault(t, '%s_%04X' % (pre[kinds[t]], t))
    for t in labels:     # a label must fall on an item or on bytes no item covers
        for a, it in items.items():
            if a < t < a + it[0]:
                raise ValueError('res_fuxoft: a word points inside the item at $%04X' % a)
    name = lambda t: labels.get(t, '$%04X' % t)
    out = ['# The tune of Fuxoft\'s player (the format in src/res/music/README.md). Labels stand for addresses;',
           '# "#" starts a comment line.', '', 'org $%04X' % org,
           'channels %s' % ' '.join(name(r) for r in roots), '']
    a, line, cur = org + 6, [], None

    def flush():
        if line:
            out.append('  ' + ' '.join(line))
            line.clear()
    while a < end:
        if a in labels:
            flush()
            cur = items[a][1] if a in items else 'bytes'
            out.append('%s: %s' % (labels[a], cur))
        if a in items:
            ln, kind, text, tg, stop = items[a]
            if kind != cur:
                flush()
                out.append(': %s' % kind)
                cur = kind
            line.append(text.format(*[name(t) for t in tg]))
            a += ln
            if stop or len(line) >= 12:
                flush()
        else:
            if cur != 'bytes':
                flush()
                out.append(': bytes')
                cur = 'bytes'
            line.append('%02X' % d[a - org])
            a += 1
            if len(line) >= 16:
                flush()
    flush()
    return '\n'.join(out) + '\n'


# ----------------------------------------------------------------------------------------------- text -> bytes

def item_bytes(kind, t, ref, at):
    """the bytes of one token; words as (offset, label) into ref"""
    if kind == 'bytes':
        return bytes([int(t, 16)])
    if ':' in t and not t[0].isdigit() and not t[0] == '-':
        name, arg = t.split(':', 1)
        if name == 'goto':
            ref.append((at + 1, arg))
            return bytes([0x80, 0, 0])
        code, typ = BYNAME[name][0], BYNAME[name][1]
        if typ == 'w':
            ref.append((at + 1, arg))
            return bytes([code, 0, 0])
        return bytes([code, int(arg) & 255])
    if kind == 'stream':
        if '/' in t:
            nm, dur = t.split('/')
            return bytes([0 if nm == 'r' else NOTE[nm], int(dur)])
        if t.startswith('$'):
            return bytes([int(t[1:], 16)])
        return bytes([BYNAME[t][0]])
    if kind == 'instrument':
        if '/' in t:
            v, dur = t.split('/')
            return bytes([int(v), int(dur)])
        return bytes([(int(t) + 0x32) & 255])
    if t in PITCHB:
        return bytes([PITCHB[t]])
    return bytes([int(t) & 255])


def from_text(text):
    org, chans, body, ref, labels, kind = ORG, [], bytearray(), [], {}, None
    for line in text.split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        t = line.split()
        if line.startswith('  '):
            for tok in t:
                body += item_bytes(kind, tok, ref, org + 6 + len(body))
        elif t[0] == 'org':
            org = int(t[1][1:], 16)
        elif t[0] == 'channels':
            chans = t[1:]
        elif t[0].endswith(':'):
            if t[0] != ':':
                labels[t[0][:-1]] = org + 6 + len(body)
            kind = t[1]
        else:
            raise ValueError('res_fuxoft: cannot read %r' % line)
    look = lambda s: int(s[1:], 16) if s.startswith('$') else labels[s]
    head = bytearray()
    for c in chans:
        v = look(c)
        head += bytes([v & 255, v >> 8])
    out = head + body
    for at, s in ref:
        v = look(s)
        out[at - org:at - org + 2] = bytes([v & 255, v >> 8])
    return bytes(out)


def length(d, org=ORG):
    """the tune's length in d (the module and what may follow it): the end of the last item the walk reaches"""
    roots, items = decode(d, org)
    return max([a + it[0] for a, it in items.items()] + [6]) - org


def to_editable(name, data):
    return '.txt', to_text(data).encode()


def from_editable(name, data):
    return from_text(data.decode())


if __name__ == '__main__':
    if sys.argv[1] == 'dump':
        sys.stdout.write(to_text(open(sys.argv[2], 'rb').read()))
