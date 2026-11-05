#!/usr/bin/env python3
"""The intro tune of Zynaps 2 in 1: the STarKos song `SK10` at $8990 (1845 bytes, $8990-$90C4 of
work/parts/starkos-8000.bin) as an editable text, src/res/music/sk10.txt, and back.

    python3 tools/sk10.py decode IMAGE.bin [--org $8000] [--song $8990] [--size 1845] > src/res/music/sk10.txt
    python3 tools/sk10.py encode src/res/music/sk10.txt OUT.bin       # the song's bytes
    python3 tools/sk10.py check  src/res/music/sk10.txt IMAGE.bin     # encode, compare with the image's song bytes
    python3 tools/sk10.py rows   src/res/music/sk10.txt               # the patterns as a time grid (one line a row)

The text holds the song the way the STarKos player at $8000 reads it (src/sound/starkos.ann): the header, the three
per-pattern streams (transpositions, heights, the special-track list), the linker (three tracks a pattern), the
instrument table and the instruments, the tracks and the special tracks, each block in the order it lies in memory.
Every byte has a field, so encode(decode(bytes)) == bytes; check proves it. Addresses are not written: the encoder
lays the blocks out from the song address and writes every pointer from the block names.

The format, one statement a line, `;` starts a comment:

    song ADDR                     the address the song was compiled for (header bytes 4-5; the player does not
                                  relocate: it must sit there)
    drumchannel N                 header byte 6: copied into the player at init ($8123), the channel number a
                                  digidrum event reports in DigidrumChannel ($800C)
    rate N                        header bytes 7-8, a word the player skips (50: the replay rate in Hz)
    speed N                       header byte 25: frames a line (SpeedCounter counts 0..N, so N+1 frames a line)
    loop T H L S                  the four restart points (header 17-24): entry numbers in the transposition,
                                  height, linker and special-list streams the song restarts at after its last
                                  pattern
    [transpositions]              one entry a statement:
        set A [B|-] [C|-]           the tracks' transpositions (A: 5 bits signed; B, C a byte each, - = unchanged)
        hold N                      no change for N patterns (this one and N-1 more; stored N-1)
    [heights]
        lines N [xM]                the pattern has N lines (stored N-1); xM: the same height M patterns
    [linker]
        TA TB TC                    the three tracks of the next pattern (channels A, B, C)
    [speciallist]
        same N SNAME                one special track for N patterns, restarted at each
        list SNAME SNAME ...        one special track a pattern, in turn
    [instruments]                 the instrument table, one name a line (instrument 0, 1, ...)
    [instrument NAME]             header: speed N (frames a line - 1; 255 holds), loops yes|no, loopto INS.LINE
                                  (where the player goes after the last line: a line of this or another
                                  instrument), retrig N (ORed into the R13 retrigger flag at each note);
                                  then one line a statement (see INSTRUMENT LINES)
    [track NAME] / [special NAME] one line a statement (see TRACK LINES)

INSTRUMENT LINES (the player's InstrumentLine, $8444). Fields after the kind, in this order where present:
    soft vV [aA] [pP]             the tone, volume V 0-15 (1-15: an instrument volume, the track's attenuation is
                                  subtracted), arpeggio A (semitones), pitch P (a signed word added to the period)
    mute [eE]                     volume 0, tone and noise off; E = the line byte if it is not 0
    noise vV nN [tone [aA] [pP]]  noise period N (the noise byte also sets bit 5 = tone on)
    fixed vV [nN] P [eE]          a fixed period P (a word), noise N if not 0
    hard sS rR [retrig] [toff] [nN] [sync [oO]] (fixed P [env Q] | [aA] [pP] [env Q])  [xX]
                                  the hardware envelope: shape S (8, 10, 12, 14), ratio R (the envelope period is
                                  the tone period >> (7 - R)), sync: the tone is set back from the envelope period
                                  (+ offset O), env Q: the envelope period given; X: the unused bits of the
                                  second byte
    raw $XX...                    any other bytes
TRACK LINES (the player's ReadTrackLine, $83AF):
    NOTE                          a note (one byte), NOTE = C-1..B-6 or a number; then [vV] [iI] [pP] [bB]
                                  when the note has the second byte: V the track's attenuation (0 = loud),
                                  I the instrument, P a pitch slide (signed, added to the pitch each frame),
                                  B the unused bits of the second byte
    wait N                        no change for N lines, this one included (bytes $CE-$FE: N 1-25), or
                                  `waitb N` (the 2-byte form $C0, N 1-256)
    rest                          no change to the end of the pattern ($C2)
    vol V / slide P / volslide V P   change without a note ($C4 / $C6 / $C8)
    off                           instrument 0 (silence) from this line ($CA)
    drum N                        digidrum N (DigidrumNumber/Channel; the ZX intro reads neither), then off ($CC)
SPECIAL LINES (the special track: speed and digidrums):
    wait N (N lines, this one included) | speed N | drum N
Note names: STarKos note 12 is the CPC period 3822, C0 at the CPC's 1 MHz AY clock; names are scientific pitch at
that clock. On the ZX (1.7734 MHz, Pentagon 1.75 MHz) every note sounds 9.9 (9.7) semitones higher: docs/09-sound.md.
"""
import argparse
import re
import sys

NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def note_name(n):
    return '%s%d' % (NAMES[n % 12], n // 12 - 1)


def parse_note(tok):
    m = re.fullmatch(r'([A-G]#?)(-?\d+)', tok)
    if m and m.group(1) in NAMES:
        return NAMES.index(m.group(1)) + 12 * (int(m.group(2)) + 1)
    return None


def num(tok):
    tok = tok.strip()
    if tok.startswith('$'):
        return int(tok[1:], 16)
    return int(tok)


def s8(v):
    return v - 256 if v & 0x80 else v


def s16(v):
    return v - 65536 if v & 0x8000 else v


# ----------------------------------------------------------------------------------------------- decoding

class Song:
    def __init__(self, data, org):
        self.d, self.org = data, org

    def b(self, a):
        return self.d[a - self.org]

    def w(self, a):
        return self.b(a) | self.b(a + 1) << 8


def track_line(s, a, special=False):
    """one statement of a track at a: (text, length)"""
    x = s.b(a)
    if special:
        if x & 1:
            return 'wait %d' % ((x >> 1) + 1), 1
        if x & 2:
            return 'drum %d' % (x >> 2), 1
        return 'speed %d' % (x >> 2), 1
    if x & 1:
        return note_name(x >> 1), 1
    a7 = x >> 1
    if a7 < 0x60:
        b = s.b(a + 1)
        out, n = [note_name(a7)], 2
        if b & 1:
            out.append('v%d' % ((b >> 1) & 15))
        if b & 0x80:
            out.append('i%d' % s.b(a + n))
            n += 1
        if b & 0x40:
            out.append('p%d' % s8(s.b(a + n)))
            n += 1
        rest = b & (0x20 | (0 if b & 1 else 0x1E))
        if rest:
            out.append('b$%02X' % rest)
        return ' '.join(out), n
    k = a7 - 0x60
    if k == 0:
        return 'waitb %d' % (s.b(a + 1) + 1), 2
    if k == 1:
        return 'rest', 1
    if k == 2:
        return 'vol %d' % s.b(a + 1), 2
    if k == 3:
        return 'slide %d' % s8(s.b(a + 1)), 2
    if k == 4:
        return 'volslide %d %d' % (s.b(a + 1), s8(s.b(a + 2))), 3
    if k == 5:
        return 'off', 1
    if k == 6:
        return 'drum %d' % s.b(a + 1), 2
    return 'wait %d' % (k - 6), 1


def instrument_line(s, a):
    """one line of an instrument at a: (text, length)"""
    e = s.b(a)
    n = 1
    out = []
    if not e & 0x80:
        if not e & 0x10:
            vol = e & 15
            if vol == 0:
                return ('mute' + (' e$%02X' % e if e else '')), 1
            out = ['soft', 'v%d' % vol]
            tone = True
        else:
            nb = s.b(a + 1)
            n = 2
            if nb & 0x40:
                out = ['fixed', 'v%d' % (e & 15)]
                if nb & 0x1F:
                    out.append('n%d' % (nb & 0x1F))
                out.append('%d' % s.w(a + 2))
                n = 4
                extra = (e & 0x60) | (nb & 0xA0)
                if extra:
                    out.append('e$%02X' % extra)
                return ' '.join(out), n
            out = ['noise', 'v%d' % (e & 15), 'n%d' % (nb & 0x1F)]
            tone = bool(nb & 0x20)
            if nb & 0xC0:
                out.append('x$%02X' % (nb & 0xC0))
            if not tone:
                if e & 0x60:
                    out.append('e$%02X' % (e & 0x60))
                return ' '.join(out), n
            out.append('tone')
        if e & 0x20:
            out.append('a%d' % s8(s.b(a + n)))
            n += 1
        if e & 0x40:
            out.append('p%d' % s16(s.w(a + n)))
            n += 2
        return ' '.join(out), n
    # hardware envelope
    b = s.b(a + 1)
    n = 2
    out = ['hard', 's%d' % ((b & 3) * 2 + 8), 'r%d' % ((b >> 2) & 7)]
    if e & 0x40:
        out.append('retrig')
    if e & 0x01:
        out.append('toff')
    if e & 0x08:
        out.append('n%d' % s.b(a + n))
        n += 1
    if b & 0x80:
        out.append('sync')
        if b & 0x40:
            out.append('o%d' % s.b(a + n))
            n += 1
    if e & 0x10:
        out += ['fixed', '%d' % s.w(a + n)]
        n += 2
        if e & 0x20:
            out += ['env', '%d' % s.w(a + n)]
            n += 2
    else:
        if e & 0x02:
            out.append('a%d' % s8(s.b(a + n)))
            n += 1
        if e & 0x04:
            out.append('p%d' % s16(s.w(a + n)))
            n += 2
        if e & 0x20 and not b & 0x80:
            out += ['env', '%d' % s.w(a + n)]
            n += 2
    x = (b & 0x20) | (b & 0x40 if not b & 0x80 else 0)
    if x:
        out.append('x$%02X' % x)
    xe = e & 0x20 if (b & 0x80 and not e & 0x10) else 0
    if xe:
        out.append('e$%02X' % xe)
    return ' '.join(out), n


def decode(data, org, song):
    s = Song(data, org)
    end = org + len(data)
    if bytes(data[song - org:song - org + 4]) != b'SK10':
        sys.exit('no SK10 tag at $%04X' % song)
    h = song
    t_heights, t_linker, t_special, t_instr = s.w(h + 9), s.w(h + 11), s.w(h + 13), s.w(h + 15)
    loops = [s.w(h + 17 + 2 * k) for k in range(4)]
    t_transp = h + 26
    out = ['; The intro tune of Zynaps 2 in 1: the STarKos song SK10 (tools/sk10.py; the format in its docstring).',
           '; Read by the STarKos player at $8000 (src/sound/starkos.asm). Blocks in memory order.', '']
    out.append('song $%04X' % s.w(h + 4))
    out.append('drumchannel %d' % s.b(h + 6))
    out.append('rate %d' % s.w(h + 7))
    out.append('speed %d' % s.b(h + 25))

    # the three streams and the linker: entry starts
    def stream(a, stop, kind):
        ents = []
        while a < stop:
            x = s.b(a)
            if kind == 'transp':
                if x & 1:
                    ents.append((a, 'hold %d' % ((x >> 1) + 1)))
                    a += 1
                    continue
                t1 = (x >> 1) & 31
                t1 = t1 - 32 if t1 & 16 else t1
                parts, n = ['set', '%d' % t1], 1
                for flag in (0x80, 0x40):
                    if x & flag:
                        parts.append('%d' % s8(s.b(a + n)))
                        n += 1
                    else:
                        parts.append('-')
                while parts[-1] == '-':
                    parts.pop()
                ents.append((a, ' '.join(parts)))
                a += n
            elif kind == 'heights':
                if x & 1:
                    ents.append((a, 'lines %d x%d' % ((x >> 1) + 1, s.b(a + 1) + 1)))
                    a += 2
                else:
                    ents.append((a, 'lines %d' % ((x >> 1) + 1)))
                    a += 1
            elif kind == 'linker':
                ents.append((a, [s.w(a), s.w(a + 2), s.w(a + 4)]))
                a += 6
            else:
                c = x >> 1
                if x & 1:
                    ents.append((a, ('list', [s.w(a + 1 + 2 * k) for k in range(c + 1)])))
                    a += 1 + 2 * (c + 1)
                else:
                    ents.append((a, ('same', c, s.w(a + 1))))
                    a += 3
        if a != stop:
            sys.exit('%s stream overruns $%04X' % (kind, stop))
        return ents

    transp = stream(t_transp, t_heights, 'transp')
    heights = stream(t_heights, t_linker, 'heights')
    linker = stream(t_linker, t_special, 'linker')
    special = stream(t_special, t_instr, 'special')
    instr = []
    a = t_instr
    first = s.w(t_instr)
    while a < first:
        instr.append(s.w(a))
        a += 2
    if a != first:
        sys.exit('instrument table does not end at instrument 0')
    tracks = sorted({p for _, ps in linker for p in ps})
    specials = sorted({p for _, e in special for p in (e[1] if e[0] == 'list' else [e[2]])})
    order = sorted(set(tracks) | set(specials))
    idx = lambda ents, addr: [e[0] for e in ents].index(addr)
    out.append('loop %d %d %d %d' % (idx(transp, loops[0]), idx(heights, loops[1]), idx(linker, loops[2]),
                                      idx(special, loops[3])))
    tname = {p: 't%02d' % k for k, p in enumerate(tracks)}
    sname = {p: 's%02d' % k for k, p in enumerate(specials)}
    for p in set(tracks) & set(specials):
        sys.exit('$%04X is a track and a special track' % p)
    out += ['', '[transpositions]'] + [e for _, e in transp]
    out += ['', '[heights]'] + [e for _, e in heights]
    out += ['', '[linker]'] + ['%s %s %s' % tuple(tname[p] for p in ps) + '  ; pattern %d' % k
                               for k, (_, ps) in enumerate(linker)]
    out += ['', '[speciallist]']
    for _, e in special:
        out.append('list ' + ' '.join(sname[p] for p in e[1]) if e[0] == 'list' else 'same %d %s' % (e[1] + 1, sname[e[2]]))
    out += ['', '[instruments]'] + ['i%d' % k for k in range(len(instr))]
    # instruments: contiguous from instrument 0
    starts = sorted(set(instr))
    if starts != instr:
        sys.exit('the instruments are not in table order')
    ins_lines = {}
    a = first
    blocks = []
    for k, p in enumerate(instr):
        if a != p:
            sys.exit('instrument %d not where the previous ends ($%04X, $%04X)' % (k, a, p))
        stop = instr[k + 1] if k + 1 < len(instr) else order[0]
        if s.w(p + 2) != stop:
            sys.exit('instrument %d end $%04X is not the next block $%04X' % (k, s.w(p + 2), stop))
        a = p + 7
        lines = []
        while a < stop:
            text, n = instrument_line(s, a)
            lines.append((a, text))
            a += n
        if a != stop:
            sys.exit('instrument %d overruns' % k)
        ins_lines[k] = lines
        blocks.append((k, p))
    where = {}
    for k, lines in ins_lines.items():
        for j, (la, _) in enumerate(lines):
            where[la] = '%d.%d' % (k, j)
    for k, p in blocks:
        flag = s.b(p + 5)
        if flag not in (0x37, 0xB7):
            sys.exit('instrument %d loop byte $%02X' % (k, flag))
        out += ['', '[instrument i%d]' % k, 'speed %d' % s.b(p + 4),
                'loops %s' % ('yes' if flag == 0x37 else 'no'), 'loopto %s' % where[s.w(p)],
                'retrig %d' % s.b(p + 6)]
        out += [t for _, t in ins_lines[k]]
    for k, p in enumerate(order):
        stop = order[k + 1] if k + 1 < len(order) else end
        if p in sname:
            if stop > song + 0x10000:
                pass
        sp = p in sname
        out += ['', '[%s %s]' % ('special' if sp else 'track', sname[p] if sp else tname[p])]
        a = p
        if sp and k + 1 == len(order):
            stop = a + 1  # the last special track: its first wait ends the song's bytes
        while a < stop:
            text, n = track_line(s, a, sp)
            out.append(text)
            a += n
        if a != stop:
            sys.exit('track at $%04X overruns $%04X' % (p, stop))
    return '\n'.join(out) + '\n', a - song


# ----------------------------------------------------------------------------------------------- encoding

def parse(path):
    sections, cur = [('', [])], None
    for number, line in enumerate(open(path, encoding='utf-8'), 1):
        text = line.split(';', 1)[0].strip()
        if not text:
            continue
        m = re.fullmatch(r'\[(\w+)(?:\s+(\w+))?\]', text)
        if m:
            sections.append(((m.group(1), m.group(2)), []))
            continue
        sections[-1][1].append((number, text.split()))
    return sections


def encode(path):
    sections = parse(path)
    head = {t[0]: t[1:] for _, t in sections[0][1]}
    org = num(head['song'][0])
    sec = {}
    order = []
    for key, body in sections[1:]:
        sec[key] = body
        order.append(key)

    def fail(number, msg):
        sys.exit('%s:%d: %s' % (path, number, msg))

    def b8(v):
        return v & 0xFF

    def enc_transp(number, t):
        if t[0] == 'hold':
            return [(num(t[1]) - 1) << 1 | 1]
        vals = t[1:] + ['-'] * (3 - len(t))
        x = (num(vals[0]) & 31) << 1
        tail = []
        for flag, v in ((0x80, vals[1]), (0x40, vals[2])):
            if v != '-':
                x |= flag
                tail.append(b8(num(v)))
        return [x] + tail

    def enc_height(number, t):
        n = num(t[1]) - 1
        if len(t) > 2:
            return [n << 1 | 1, num(t[2][1:]) - 1]
        return [n << 1]

    def enc_track(number, t, special):
        k = t[0]
        if special:
            v = num(t[1])
            return [{'wait': (v - 1) << 1 | 1, 'drum': v << 2 | 2, 'speed': v << 2}[k]]
        simple = {'rest': [0xC2], 'off': [0xCA]}
        if k in simple:
            return simple[k]
        if k == 'wait':
            return [(num(t[1]) + 0x66) << 1]
        if k == 'waitb':
            return [0xC0, num(t[1]) - 1]
        if k == 'vol':
            return [0xC4, num(t[1])]
        if k == 'slide':
            return [0xC6, b8(num(t[1]))]
        if k == 'volslide':
            return [0xC8, num(t[1]), b8(num(t[2]))]
        if k == 'drum':
            return [0xCC, num(t[1])]
        note = parse_note(k)
        if note is None:
            note = num(k)
        if len(t) == 1:
            return [note << 1 | 1]
        b, tail = 0, []
        for f in t[1:]:
            if f[0] == 'v':
                b |= 1 | (num(f[1:]) & 15) << 1
            elif f[0] == 'i':
                b |= 0x80
                tail.append(('i', num(f[1:])))
            elif f[0] == 'p':
                b |= 0x40
                tail.append(('p', b8(num(f[1:]))))
            elif f[0] == 'b':
                b |= num(f[1:])
            else:
                fail(number, 'unknown field ' + f)
        tail.sort(key=lambda x: 'ip'.index(x[0]))
        return [note << 1, b] + [v for _, v in tail]

    def enc_instr(number, t):
        f = {}
        flags = []
        rest = []
        for tok in t[1:]:
            m = re.fullmatch(r'([a-z])(-?\$?[0-9A-Fa-f]+)', tok)
            if tok in ('tone', 'retrig', 'toff', 'sync', 'fixed', 'env'):
                flags.append(tok)
            elif m and m.group(1) in 'vnparsoex' and not rest_pending(flags):
                f[m.group(1)] = num(m.group(2))
            else:
                rest.append((flags[-1] if flags else '', tok))
        k = t[0]
        w16 = lambda v: [v & 0xFF, (v >> 8) & 0xFF]
        if k == 'mute':
            return [f.get('e', 0)]
        if k == 'soft' or (k == 'noise' and 'tone' in flags):
            e = f['v'] & 15
            out = []
            if k == 'noise':
                e |= 0x10
                out.append((f['n'] & 0x1F) | 0x20 | f.get('x', 0))
            tail = []
            if 'a' in f:
                e |= 0x20
                tail.append(b8(f['a']))
            if 'p' in f:
                e |= 0x40
                tail += w16(f['p'])
            return [e] + out + tail
        if k == 'noise':
            return [0x10 | (f['v'] & 15) | f.get('e', 0), (f['n'] & 0x1F) | f.get('x', 0)]
        if k == 'fixed':
            p = num(rest[0][1])
            e = 0x10 | (f['v'] & 15) | (f.get('e', 0) & 0x60)
            nb = 0x40 | f.get('n', 0) | (f.get('e', 0) & 0xA0)
            return [e, nb] + w16(p)
        if k == 'hard':
            e = 0x80
            b = ((f['s'] - 8) // 2) | (f['r'] << 2) | f.get('x', 0)
            e |= f.get('e', 0)
            if 'retrig' in flags:
                e |= 0x40
            if 'toff' in flags:
                e |= 0x01
            out = []
            if 'n' in f:
                e |= 0x08
                out.append(f['n'])
            if 'sync' in flags:
                b |= 0x80
                if 'o' in f:
                    b |= 0x40
                    out.append(f['o'])
            vals = dict(rest)
            if 'fixed' in flags:
                e |= 0x10
                out += w16(num(vals['fixed']))
                if 'env' in vals:
                    e |= 0x20
                    out += w16(num(vals['env']))
            else:
                if 'a' in f:
                    e |= 0x02
                    out.append(b8(f['a']))
                if 'p' in f:
                    e |= 0x04
                    out += w16(f['p'])
                if 'env' in vals:
                    e |= 0x20
                    out += w16(num(vals['env']))
            return [e, b] + out
        if k == 'raw':
            return [num(x) for x in t[1:]]
        fail(number, 'unknown instrument line ' + k)

    def rest_pending(flags):
        return bool(flags) and flags[-1] in ('fixed', 'env')

    # pass 1: sizes, pass 2: bytes
    def build(addr):
        out = bytearray(b'SK10')
        out += bytes([org & 255, org >> 8])
        out.append(num(head['drumchannel'][0]))
        r = num(head['rate'][0])
        out += bytes([r & 255, r >> 8])
        hdr_ptrs = len(out)
        out += bytes(17)  # 4 pointers, 4 loops, speed
        out[hdr_ptrs + 16] = num(head['speed'][0])
        pos = {}
        ents = {}
        for key in order:
            name = key[0] if key[1] is None else key[1]
            pos[name] = org + len(out)
            body = sec[key]
            starts = []
            if key[0] == 'transpositions':
                for number, t in body:
                    starts.append(org + len(out))
                    out += bytes(enc_transp(number, t))
            elif key[0] == 'heights':
                for number, t in body:
                    starts.append(org + len(out))
                    out += bytes(enc_height(number, t))
            elif key[0] == 'linker':
                for number, t in body:
                    starts.append(org + len(out))
                    for nm in t:
                        v = addr.get(nm, 0)
                        out += bytes([v & 255, v >> 8])
            elif key[0] == 'speciallist':
                for number, t in body:
                    starts.append(org + len(out))
                    if t[0] == 'same':
                        v = addr.get(t[2], 0)
                        out += bytes([(num(t[1]) - 1) << 1, v & 255, v >> 8])
                    else:
                        out.append((len(t) - 2) << 1 | 1)
                        for nm in t[1:]:
                            v = addr.get(nm, 0)
                            out += bytes([v & 255, v >> 8])
            elif key[0] == 'instruments':
                for number, t in body:
                    v = addr.get(t[0], 0)
                    out += bytes([v & 255, v >> 8])
            elif key[0] == 'instrument':
                hd = {t[0]: t[1:] for number, t in body[:4]}
                start = len(out)
                out += bytes(7)
                lines = []
                for number, t in body[4:]:
                    lines.append(org + len(out))
                    out += bytes(enc_instr(number, t))
                addr.setdefault('_lines', {})[key[1]] = lines
                lt = hd['loopto'][0].split('.')
                ref = addr.get('_lines', {}).get('i' + lt[0], [0] * 99)
                v = ref[int(lt[1])] if int(lt[1]) < len(ref) else 0
                v = addr.get('_loopto_' + key[1], v)
                e = org + len(out)
                out[start:start + 7] = bytes([v & 255, v >> 8, e & 255, e >> 8, num(hd['speed'][0]),
                                              0x37 if hd['loops'][0] == 'yes' else 0xB7, num(hd['retrig'][0])])
                addr['_ref_' + key[1]] = (start, hd['loopto'][0])
            elif key[0] in ('track', 'special'):
                for number, t in body:
                    out += bytes(enc_track(number, t, key[0] == 'special'))
            ents[key[0]] = starts
        # header pointers
        lp = [int(x) for x in head['loop']]
        vals = [pos['heights'], pos['linker'], pos['speciallist'], pos['instruments'],
                ents['transpositions'][lp[0]], ents['heights'][lp[1]], ents['linker'][lp[2]],
                ents['speciallist'][lp[3]]]
        for k, v in enumerate(vals):
            out[hdr_ptrs + 2 * k:hdr_ptrs + 2 * k + 2] = bytes([v & 255, v >> 8])
        return out, pos

    out, pos = build({})
    addr = dict(pos)
    out, pos = build(addr)
    # second pass for loopto references to later instruments
    lines = addr.get('_lines', {})
    for key in order:
        if key[0] == 'instrument':
            start, ref = addr['_ref_' + key[1]]
            i, j = ref.split('.')
            v = lines['i' + i][int(j)]
            out[start:start + 2] = bytes([v & 255, v >> 8])
    return bytes(out)


def rows(path):
    """the patterns as a time grid: pattern, line, the three tracks' statements"""
    sections = parse(path)
    sec = {k: b for k, b in sections[1:]}
    tracks = {k[1]: [t for _, t in b] for k, b in sections[1:] if k[0] == 'track'}
    heights = []
    for _, t in sec[('heights', None)]:
        n = int(t[1])
        heights += [n] * (int(t[2][1:]) if len(t) > 2 else 1)
    for p, (_, t) in enumerate(sec[('linker', None)]):
        cols = []
        for nm in t:
            out, wait = [], 0
            for st in tracks[nm]:
                if st[0] in ('wait', 'waitb'):
                    out += [''] * int(st[1])
                elif st[0] == 'rest':
                    out += [''] * 256
                else:
                    out.append(' '.join(st))
            cols.append(out)
        for line in range(heights[p]):
            print('%02d %02d | %s' % (p, line, ' | '.join('%-14s' % (c[line] if line < len(c) else '') for c in cols)))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    d = sub.add_parser('decode')
    d.add_argument('image')
    d.add_argument('--org', default='$8000')
    d.add_argument('--song', default='$8990')
    e = sub.add_parser('encode')
    e.add_argument('text')
    e.add_argument('out')
    c = sub.add_parser('check')
    c.add_argument('text')
    c.add_argument('image')
    c.add_argument('--org', default='$8000')
    c.add_argument('--song', default='$8990')
    r = sub.add_parser('rows')
    r.add_argument('text')
    a = p.parse_args()
    if a.cmd == 'decode':
        data = open(a.image, 'rb').read()
        text, size = decode(data, num(a.org), num(a.song))
        sys.stdout.write(text)
        print('; %d bytes' % size, file=sys.stderr)
    elif a.cmd == 'encode':
        open(a.out, 'wb').write(encode(a.text))
    elif a.cmd == 'check':
        data = open(a.image, 'rb').read()
        org, song = num(a.org), num(a.song)
        built = encode(a.text)
        ref = data[song - org:song - org + len(built)]
        if built != ref or song - org + len(built) != len(data):
            diff = next((i for i in range(min(len(built), len(ref))) if built[i] != ref[i]), min(len(built), len(ref)))
            sys.exit('sk10 check: differs at $%04X (%d bytes built, %d in the image after the song address)'
                     % (song + diff, len(built), len(data) - (song - org)))
        print('sk10 check: %d bytes identical ($%04X-$%04X)' % (len(built), song, song + len(built) - 1))
    else:
        rows(a.text)


if __name__ == '__main__':
    main()
