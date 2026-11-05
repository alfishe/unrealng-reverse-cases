#!/usr/bin/env python3
"""The game's messages ($82EE-$8515, src/res/text/messages.bin) and the high-score table ($8261-$82A6,
src/res/text/hiscores.bin) as UTF-8 text and back.

A message is the bytes up to $FF (PrintString $A401, PrintChar $A321). Written in the text:
    letters $20-$7E      as they are; $5E is the font's arrow, $60 its pound sign, $7F its copyright sign: ↑ £ ©
    {attr $xx}           code 0: the attribute ($80AC)            {ink n} {paper n}   codes 1, 2: its ink, paper
    {col n} {row n}      codes 3, 4: the print column, row ($80AA) {col+n} {row+n}     codes 5, 6: move by n (signed)
    {code n $xx}         codes 7-$1A, $1C-$1F: the print routine skips them with their byte
    {msg n}              $1B n: print message n first (PrintMessage $A423)
    {Gxx}                $80-$FE: the game's own glyph xx ($B54F + (xx - $80) * 8: the logo, the frame)
    {x7B} {x7D}          the braces themselves
The high-score table: five entries of a message (the position and the initials) and the score, 4 BCD bytes.

    python3 tools/res_text.py decode messages|hiscores FILE.bin > FILE.txt
    python3 tools/res_text.py encode messages|hiscores FILE.txt > FILE.bin
"""
import re
import sys

NAMES = {0: 'attr', 1: 'ink', 2: 'paper', 3: 'col', 4: 'row', 5: 'col+', 6: 'row+'}
CHARS = {0x5E: '↑', 0x60: '£', 0x7F: '©'}
UNCHARS = dict((v, k) for k, v in CHARS.items())


def render(m, a):
    """The message at m[a:] as text, and the address past its $FF; None when no $FF ends it"""
    out = []
    while True:
        if a >= len(m):
            return None
        c = m[a]
        if c == 0xFF:
            return ''.join(out), a + 1
        if c < 0x20:
            if a + 1 >= len(m):
                return None
            p = m[a + 1]
            if c == 0x1B:
                out.append('{msg %d}' % p)
            elif c == 0:
                out.append('{attr $%02X}' % p)
            elif c in (5, 6):
                out.append('{%s%d}' % (NAMES[c], p - 256 if p >= 0x80 else p))
            elif c in NAMES:
                out.append('{%s %d}' % (NAMES[c], p))
            else:
                out.append('{code %d $%02X}' % (c, p))
            a += 2
        elif c in CHARS:
            out.append(CHARS[c])
            a += 1
        elif c in (0x7B, 0x7D):
            out.append('{x%02X}' % c)
            a += 1
        elif c < 0x80:
            out.append(chr(c))
            a += 1
        else:
            out.append('{G%02X}' % c)
            a += 1


TOKEN = re.compile(r'\{([^}]*)\}')


def parse(text, where):
    """A message's text as its bytes, the $FF included"""
    out = bytearray()
    k = 0
    while k < len(text):
        ch = text[k]
        if ch == '{':
            mt = TOKEN.match(text, k)
            if not mt:
                raise SystemExit('%s: an unclosed {' % where)
            t = mt.group(1)
            k = mt.end()
            mm = re.match(r'^(attr|ink|paper|col|row) (\S+)$', t)
            ms = re.match(r'^(col|row)\+(-?\d+)$', t)
            if t.startswith('msg '):
                out += bytes([0x1B, int(t[4:])])
            elif ms:
                out += bytes([5 if ms.group(1) == 'col' else 6, int(ms.group(2)) & 0xFF])
            elif mm:
                v = mm.group(2)
                v = int(v[1:], 16) if v.startswith('$') else int(v)
                out += bytes([dict((n, c) for c, n in NAMES.items())[mm.group(1)], v])
            elif t.startswith('code '):
                c, v = t[5:].split()
                out += bytes([int(c), int(v.lstrip('$'), 16)])
            elif re.match(r'^G[0-9A-Fa-f]{2}$', t):
                out.append(int(t[1:], 16))
            elif re.match(r'^x[0-9A-Fa-f]{2}$', t):
                out.append(int(t[1:], 16))
            else:
                raise SystemExit('%s: cannot read {%s}' % (where, t))
            continue
        if ch in UNCHARS:
            out.append(UNCHARS[ch])
        elif 0x20 <= ord(ch) < 0x7F:
            out.append(ord(ch))
        else:
            raise SystemExit('%s: %r is no character of the game' % (where, ch))
        k += 1
    return bytes(out) + b'\xff'


def decode_messages(data):
    lines = ['# Zynaps: the messages $82EE-$8515, one a line (tools/res_text.py; src/res/text/README.md)']
    a = n = 0
    while a < len(data):
        got = render(data, a)
        if got is None:
            lines.append('tail: ' + ' '.join('$%02X' % b for b in data[a:]))
            break
        text, a2 = got
        lines.append('msg %d: %s' % (n, text))
        a, n = a2, n + 1
    return ('\n'.join(lines) + '\n').encode('utf-8')


def encode_messages(text):
    out = bytearray()
    n = 0
    for number, line in enumerate(text.decode('utf-8').splitlines(), 1):
        if not line.strip() or line.startswith('#'):
            continue
        if line.startswith('tail: '):
            out += bytes(int(x.lstrip('$'), 16) for x in line[6:].split())
            continue
        mt = re.match(r'^msg (\d+): (.*)$', line)
        if not mt or int(mt.group(1)) != n:
            raise SystemExit('messages:%d: "msg %d: text" expected' % (number, n))
        out += parse(mt.group(2), 'messages:%d' % number)
        n += 1
    return bytes(out)


def bcd_ok(bs):
    return all((b >> 4) < 10 and (b & 15) < 10 for b in bs)


def decode_hiscores(data):
    lines = ['# Zynaps: the high-score table $8261-$82A6 (ROLE OF HONOUR): "score: the line | the score"',
             '# (tools/res_text.py; src/res/text/README.md)']
    a = 0
    while a < len(data):
        got = render(data, a)
        if got is None or got[1] + 4 > len(data):
            lines.append('tail: ' + ' '.join('$%02X' % b for b in data[a:]))
            break
        text, a = got
        sc = data[a:a + 4]
        value = str(int(''.join('%02X' % b for b in sc))) if bcd_ok(sc) else '$' + sc.hex().upper()
        lines.append('score: %s | %s' % (text, value))
        a += 4
    return ('\n'.join(lines) + '\n').encode('utf-8')


def encode_hiscores(text):
    out = bytearray()
    for number, line in enumerate(text.decode('utf-8').splitlines(), 1):
        if not line.strip() or line.startswith('#'):
            continue
        if line.startswith('tail: '):
            out += bytes(int(x.lstrip('$'), 16) for x in line[6:].split())
            continue
        mt = re.match(r'^score: (.*) \| (\S+)$', line)
        if not mt:
            raise SystemExit('hiscores:%d: "score: text | value" expected' % number)
        out += parse(mt.group(1), 'hiscores:%d' % number)
        v = mt.group(2)
        out += bytes.fromhex(v[1:] if v.startswith('$') else '%08d' % int(v))
    return bytes(out)


KINDS = [
    ('text/messages.bin', '.msg.txt', lambda d, n: decode_messages(d), lambda d, n: encode_messages(d)),
    ('text/hiscores.bin', '.hsc.txt', lambda d, n: decode_hiscores(d), lambda d, n: encode_hiscores(d)),
]


if __name__ == '__main__':
    kind = {'messages': (decode_messages, encode_messages), 'hiscores': (decode_hiscores, encode_hiscores)}
    dec, enc = kind[sys.argv[2]]
    data = open(sys.argv[3], 'rb').read()
    sys.stdout.buffer.write(dec(data) if sys.argv[1] == 'decode' else enc(data))
