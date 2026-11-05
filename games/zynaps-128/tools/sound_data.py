#!/usr/bin/env python3
"""The page-4 sound engine's data of Zynaps 2 in 1 ($DE48-$FE6F, 8232 bytes, work/parts/engine-data-de48.bin) as
an editable text, src/res/sound/engine-data.txt, and back.

    python3 tools/sound_data.py decode work/parts/engine-data-de48.bin > src/res/sound/engine-data.txt
    python3 tools/sound_data.py encode src/res/sound/engine-data.txt OUT.bin
    python3 tools/sound_data.py check  src/res/sound/engine-data.txt work/parts/engine-data-de48.bin

The engine (src/sound/engine.ann) reads three tables and the blocks they point at:

    [periods]      $DE48, 95 words: the tone period of note 0-94 (PlayNote: $DE48 + 2 x note). Notes 0-12 are 0;
                   note 13 is 4126 and each note after it is a tempered semitone higher (4126 x 2^(-k/12)).
    [envelopes]    $DF06, 35 words + 1 byte: envelope 0-34 (the commands volenv, pitchenv, noiseenv: $DF06 + 2 x E)
    [sounds]       $DF4D, 36 words: sound 0-35 (StartSound and the command call: $DF4D + 2 x the sound number);
                   sounds $0B-$0D are the music's three channels, $0E-$1F the effects
    [envelope NAME]  steps of three bytes, `step F D R`: every F frames add D (signed; stored D + $80) to the
                   volume, the period (2 x D) or the noise period, R times; then the next step; `loop` ($FF) starts
                   the envelope again
    [sound NAME]   the commands of a channel, one a line:
        NOTE LEN       a note (1-100, + the channel's transposition) for LEN frames (2 bytes; LEN 0 = 256)
        NOTE           the same for 8 frames (1 byte: $80 + the note)
        rest LEN       period 0 for LEN frames ($00)
        noise N        the noise period N, noise on for the next note ($E4)
        volenv E / pitchenv E / noiseenv E   the envelope of the next notes ($E8 / $E9 / $EA)
        call S         play sound S, then go on here ($E5; S's `return` comes back)
        transpose N    add N to the next notes ($E6)
        mixer $M       mixer bits ORed into R7 at each note ($EB)
        swap           swap the sound table's entries 0 and 1 ($EC: the music alternates two phrases)
        return         back after the last call; at the top level the sound starts again ($FF)
        end            the channel stops, its volume 0 ($E1)
        byte $XX       any other byte the engine reads as a note (XX & $7F, 8 frames)
    [raw]          bytes no table reaches: `db` rows, `zeros N`
    @NAME          inside a block: a label (a pointer of a table may point into a block)
Note names: note 13 is A0 at the ZX AY clock (1.7734 MHz: 26.86 Hz, 40 cents below a tempered A0), each note a
semitone; a number nNN is also accepted. Blocks are in memory order; addresses are not written: the encoder lays the
blocks out from $DE48 and writes every pointer from the names. encode(decode(bytes)) == bytes; check proves it.
"""
import argparse
import re
import sys

ORG = 0xDE48
PERIODS, ENVTAB, SNDTAB, DATA = 0xDE48, 0xDF06, 0xDF4D, 0xDF95
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
SIMPLE = {0xE4: 'noise', 0xE8: 'volenv', 0xE9: 'pitchenv', 0xEA: 'noiseenv', 0xE5: 'call', 0xE6: 'transpose',
          0xEB: 'mixer'}
CODES = {v: k for k, v in SIMPLE.items()}


def note_name(n):
    m = n + 8
    return '%s%d' % (NAMES[m % 12], m // 12 - 1)


def parse_note(tok):
    if re.fullmatch(r'n\d+', tok):
        return int(tok[1:])
    mt = re.fullmatch(r'([A-G]#?)(-?\d+)', tok)
    if mt and mt.group(1) in NAMES:
        return NAMES.index(mt.group(1)) + 12 * (int(mt.group(2)) + 1) - 8
    return None


def num(tok):
    return int(tok[1:], 16) if tok.startswith('$') else int(tok)


def decode(data):
    end = ORG + len(data)
    b = lambda a: data[a - ORG]
    w = lambda a: b(a) | b(a + 1) << 8
    env = [w(ENVTAB + 2 * k) for k in range(35)]
    snd = [w(SNDTAB + 2 * k) for k in range(36)]
    sound_at, env_at = {}, {}
    for k, p in enumerate(snd):
        if p:
            sound_at.setdefault(p, 's%02X' % k)
    for k, p in enumerate(env):
        if p:
            env_at.setdefault(p, 'e%02X' % k)
    # walk every sound: the commands and their lengths
    cmd, used_env = {}, set()

    def walk(a):
        while a not in cmd:
            x = b(a)
            if x in (0xE1, 0xFF, 0xEC) or 0x65 <= x < 0xDC or (x >= 0xDC and x not in SIMPLE):
                cmd[a] = 1
                if x in (0xE1, 0xFF):
                    return
                a += 1
                continue
            cmd[a] = 2
            if x == 0xE5:
                walk(snd[b(a + 1)])
            if x in (0xE8, 0xE9, 0xEA):
                used_env.add(b(a + 1))
            a += 2
    for p in sound_at:
        walk(p)
    envstep = {}
    walked_env = {env[k] for k in used_env}
    for p in env_at:
        if p not in walked_env:
            continue
        a = p
        while b(a) != 0xFF:
            envstep[a] = 3
            a += 3
        envstep[a] = 1
    owner = {}
    for a, n in cmd.items():
        for k in range(n):
            owner[a + k] = 'S'
    for a, n in envstep.items():
        for k in range(n):
            if owner.get(a + k) == 'S':
                sys.exit('$%04X: an envelope and a sound share bytes' % (a + k))
            owner[a + k] = 'E'
    lines = ['; The page-4 sound engine\'s data ($DE48-$FE6F), tools/sound_data.py (the format in its docstring).',
             '; Read by the engine at $C968 (src/sound/engine.asm). Blocks in memory order.', '', '[periods]']
    per = [w(PERIODS + 2 * k) for k in range(95)]
    for k in range(0, 95, 12):
        lines.append(' '.join('%d' % p for p in per[k:k + 12]) + '  ; notes %d-%d' % (k, min(k + 11, 94)))
    label = dict(sound_at)
    label.update(env_at)
    ref = lambda p: label[p] if p in label else ('%d' % p if p == 0 else None)
    for name, tab, vals in (('envelopes', ENVTAB, env), ('sounds', SNDTAB, snd)):
        lines += ['', '[%s]' % name]
        toks = []
        for p in vals:
            r = ref(p)
            if r is None:
                sys.exit('$%04X: no block at a table pointer' % p)
            toks.append(r)
        for k in range(0, len(toks), 12):
            lines.append(' '.join(toks[k:k + 12]))
        if name == 'envelopes':
            lines += ['', '[raw]', 'db $%02X  ; $DF4C, between the tables' % b(0xDF4C)]
    a = DATA
    kind = None
    run = []

    def flush_raw():
        if not run:
            return
        k = 0
        while k < len(run):
            z = k
            while z < len(run) and run[z] == 0:
                z += 1
            if z - k >= 16:
                lines.append('zeros %d' % (z - k))
                k = z
                continue
            row = []
            while k < len(run) and len(row) < 16:
                z = k
                while z < len(run) and run[z] == 0:
                    z += 1
                if z - k >= 16:
                    break
                row.append(run[k])
                k += 1
            lines.append('db ' + ','.join('$%02X' % x for x in row))
        run.clear()

    cont = False  # the previous unit was a sound command the next one follows
    while a < end:
        o = owner.get(a)
        if o is None:
            if kind is not None:
                lines += ['', '[raw]']
            kind, cont = None, False
            if a in label:
                flush_raw()
                lines.append('@' + label[a])
            run.append(b(a))
            a += 1
            continue
        flush_raw()
        if o == 'E':
            if a in env_at:
                lines += ['', '[envelope %s]' % env_at[a]]
            elif kind != 'E':
                sys.exit('$%04X: envelope bytes without a start' % a)
            kind, cont = 'E', False
            if b(a) == 0xFF:
                lines.append('loop')
                a += 1
            else:
                lines.append('step %d %d %d' % (b(a), b(a + 1) - 0x80, b(a + 2)))
                a += 3
            continue
        if a in sound_at:
            lines += ['@' + sound_at[a]] if cont else ['', '[sound %s]' % sound_at[a]]
        elif not cont:
            sys.exit('$%04X: sound bytes without a start' % a)
        kind = 'S'
        x = b(a)
        n = cmd[a]
        if n == 2:
            e = b(a + 1)
            if x == 0:
                lines.append('rest %d' % e)
            elif x < 0x65:
                lines.append('%s %d' % (note_name(x), e))
            elif x == 0xE5:
                lines.append('call s%02X' % e)
            elif x in (0xE8, 0xE9, 0xEA):
                lines.append('%s e%02X' % (SIMPLE[x], e))
            elif x == 0xE6:
                lines.append('transpose %d' % (e - 256 if e & 0x80 else e))
            elif x == 0xEB:
                lines.append('mixer $%02X' % e)
            else:
                lines.append('noise %d' % e)
        elif x == 0xE1:
            lines.append('end')
        elif x == 0xFF:
            lines.append('return')
        elif x == 0xEC:
            lines.append('swap')
        elif 0x81 <= x < 0xDC:
            lines.append(note_name(x & 0x7F))
        else:
            lines.append('byte $%02X' % x)
        cont = x not in (0xE1, 0xFF)
        a += n
    flush_raw()
    return '\n'.join(lines) + '\n'



def encode(path):
    blocks = []
    for number, line in enumerate(open(path, encoding='utf-8'), 1):
        text = line.split(';', 1)[0].strip()
        if not text:
            continue
        m = re.fullmatch(r'\[(\w+)(?:\s+(\w+))?\]', text)
        if m:
            blocks.append([m.group(1), m.group(2), []])
            continue
        blocks[-1][2].append((number, text.split()))

    def build(labels):
        out = bytearray()
        new = {}
        tables = {}

        def ptr(tok):
            if tok == '0':
                return 0
            return labels.get(tok, 0)
        for kind, name, body in blocks:
            here = ORG + len(out)
            if name:
                new[name] = here
            if kind == 'periods':
                for _, t in body:
                    for v in t:
                        out += bytes([num(v) & 255, num(v) >> 8])
            elif kind in ('envelopes', 'sounds'):
                for _, t in body:
                    for v in t:
                        p = ptr(v)
                        out += bytes([p & 255, p >> 8])
            elif kind == 'raw':
                for _, t in body:
                    if t[0].startswith('@'):
                        new[t[0][1:]] = ORG + len(out)
                    elif t[0] == 'zeros':
                        out += bytes(num(t[1]))
                    else:
                        out += bytes(num(v) for v in ' '.join(t[1:]).replace(' ', '').split(','))
            elif kind == 'envelope':
                for _, t in body:
                    if t[0] == 'loop':
                        out.append(0xFF)
                    else:
                        out += bytes([num(t[1]), (num(t[2]) + 0x80) & 255, num(t[3])])
            elif kind == 'sound':
                for number, t in body:
                    k = t[0]
                    if k.startswith('@'):
                        new[k[1:]] = ORG + len(out)
                    elif k == 'end':
                        out.append(0xE1)
                    elif k == 'return':
                        out.append(0xFF)
                    elif k == 'swap':
                        out.append(0xEC)
                    elif k == 'byte':
                        out.append(num(t[1]))
                    elif k == 'rest':
                        out += bytes([0, num(t[1])])
                    elif k in ('volenv', 'pitchenv', 'noiseenv', 'call'):
                        out += bytes([CODES[k], int(t[1][1:], 16)])
                    elif k in ('noise', 'transpose', 'mixer'):
                        out += bytes([CODES[k], num(t[1]) & 255])
                    else:
                        n = parse_note(k)
                        if n is None:
                            sys.exit('%s:%d: cannot read %s' % (path, number, ' '.join(t)))
                        out += bytes([n, num(t[1])]) if len(t) > 1 else bytes([0x80 | n])
            else:
                sys.exit('%s: unknown block [%s]' % (path, kind))
        return out, new
    out, labels = build({})
    out, labels2 = build(labels)
    return bytes(out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    d = sub.add_parser('decode')
    d.add_argument('image')
    e = sub.add_parser('encode')
    e.add_argument('text')
    e.add_argument('out')
    c = sub.add_parser('check')
    c.add_argument('text')
    c.add_argument('image')
    a = p.parse_args()
    if a.cmd == 'decode':
        sys.stdout.write(decode(open(a.image, 'rb').read()))
    elif a.cmd == 'encode':
        open(a.out, 'wb').write(encode(a.text))
    else:
        ref = open(a.image, 'rb').read()
        built = encode(a.text)
        if built != ref:
            diff = next((i for i in range(min(len(built), len(ref))) if built[i] != ref[i]), min(len(built), len(ref)))
            sys.exit('sound_data check: differs at $%04X (%d bytes built, %d in the image)'
                     % (ORG + diff, len(built), len(ref)))
        print('sound_data check: %d bytes identical ($%04X-$%04X)' % (len(built), ORG, ORG + len(built) - 1))


if __name__ == '__main__':
    main()
