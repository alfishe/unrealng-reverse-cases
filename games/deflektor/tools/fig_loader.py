#!/usr/bin/env python3
"""Three pictures of the load (doc 03), each drawn from the bytes it explains:

    python3 tools/fig_loader.py basic docs/img/load/basic-line.png    # line 0 of the BASIC, build/basic.bin
    python3 tools/fig_loader.py byte docs/img/load/turbo-byte.png     # the turbo block's first pulses, orig TZX
    python3 tools/fig_loader.py fill docs/img/load/chainfill.png      # ChainFill's stream and the chain's sum area

`basic`: the 52 bytes of line 0 coloured by kind; under each number the digits LIST shows and the hidden five-byte
value the ROM uses. `byte`: the pulse pairs after the sync, read as LoadBlock reads them (a lead pair, then ReadByte:
8 bits MSB first, the invert flag, zeros - 5 padding pairs), with the T-states of each. `fill`: the stream of
ChainStart `$7B52` (D = `$95`, D = 17 x D + L + 11) computed here and compared with the entry image
(work/stage1/images/entry.cpu.bin), and what `$4000-$FFFF` holds when ChainSum adds it up.
"""
import os
import sys
import zipfile

from PIL import Image, ImageDraw

import figlib

CASE = figlib.CASE
ZERO, ONE = 836, 1670           # the turbo block's pulse lengths in T (TZX block $11)


def five_byte(b):
    """A small integer in the ROM's five-byte form ($00, sign, low, high, $00)."""
    assert b[0] == 0 and b[4] == 0
    v = b[2] | b[3] << 8
    return -((65536 - v)) if b[1] == 0xFF else v


def basic(out):
    d = open(os.path.join(CASE, 'build', 'basic.bin'), 'rb').read()
    line = d[:52]
    toks = {0xF9: 'RANDOMIZE', 0xC0: 'USR', 0xBE: 'PEEK', 0x28: '(', 0x29: ')', 0x2B: '+', 0x2A: '*'}
    items = []          # (start, length, kind, label)
    items.append((0, 2, 'num', f'line {line[0] << 8 | line[1]}'))
    items.append((2, 2, 'len', f'length {line[2] | line[3] << 8}'))
    i = 4
    numbers = []
    while i < 51:
        b = line[i]
        if 0x30 <= b <= 0x39:
            j = i
            while 0x30 <= line[j] <= 0x39:
                j += 1
            digits = line[i:j].decode()
            assert line[j] == 0x0E
            hidden = five_byte(line[j + 1:j + 6])
            items.append((i, j - i, 'digits', digits))
            items.append((j, 6, 'hidden', f'{hidden}'))
            numbers.append((digits, hidden))
            i = j + 6
        else:
            items.append((i, 1, 'token', toks.get(b, f'{b:02X}')))
            i += 1
    items.append((51, 1, 'end', '$00: no ENTER'))
    col = {'num': (90, 150, 230), 'len': (230, 90, 160), 'token': (150, 150, 165), 'digits': (240, 200, 80),
           'hidden': (90, 210, 120), 'end': (230, 90, 90)}
    W, cw = 1060, 19
    o = Image.new('RGB', (W, 520), figlib.BG)
    dr = ImageDraw.Draw(o)
    figlib.text(dr, (10, 8), 'BASIC line 0: what LIST shows and what the ROM computes (build/basic.bin, 52 bytes)', 17,
                figlib.ACCENT)
    x0, y = 14, 48
    # two rows of 26 bytes
    for r in range(2):
        yy = y + r * 150
        for k in range(26):
            a = r * 26 + k
            kind = next(it[2] for it in items if it[0] <= a < it[0] + it[1])
            x = x0 + k * (cw * 2 + 1)
            dr.rectangle([x, yy, x + 2 * cw - 2, yy + 28], fill=col[kind])
            figlib.text(dr, (x + cw - 1, yy + 14), f'{line[a]:02X}', 13, (0, 0, 0), anchor='mm')
            figlib.text(dr, (x + cw - 1, yy - 8), f'{a}', 10, figlib.DIM, anchor='mm')
        for st, ln, kind, lab in items:
            if not (r * 26 <= st < r * 26 + 26):
                continue
            k = st - r * 26
            x = x0 + k * (cw * 2 + 1)
            wx = min(ln, 26 - k) * (cw * 2 + 1) - 3
            dr.line([x, yy + 34, x + wx, yy + 34], fill=col[kind], width=2)
            ly = yy + 40 + (18 if kind in ('hidden', 'len', 'end') else 0) + (36 if kind == 'token' and k % 2 else 0)
            if kind == 'token':
                ly = yy + 40 + 18 * (k % 3)
            if kind == 'end':
                figlib.text(dr, (x + 2 * cw - 2, ly), lab, 12, col[kind], anchor='ra')
            else:
                figlib.text(dr, (x, ly), lab if kind != 'hidden' else f'= {lab}', 12, col[kind])
    y = 48 + 150 + 104
    figlib.text(dr, (x0, y), 'LIST shows:   0 RANDOMIZE USR (PEEK ' + numbers[0][0] + '+' + numbers[1][0] + '*PEEK ' +
                numbers[2][0] + '+' + numbers[3][0] + ')', 14, (240, 200, 80))
    figlib.text(dr, (x0, y + 22), 'the ROM uses: 0 RANDOMIZE USR (PEEK ' + str(numbers[0][1]) + '+' +
                str(numbers[1][1]) + '*PEEK ' + str(numbers[2][1]) + '+' + str(numbers[3][1]) + ')', 14,
                (90, 210, 120))
    prog = 0x5CCB
    figlib.text(dr, (x0, y + 50), f'PEEK 23635 + 256 x PEEK 23636 = PROG = ${prog:04X}; + {numbers[3][1]} = '
                f'${prog + numbers[3][1]:04X}: the code after the line (BasicCode). 23641/23642 is E_LINE: the decoy.',
                13, figlib.FG)
    figlib.text(dr, (x0, y + 72), f'The length field says {line[2] | line[3] << 8} and the line ends in $00, not ENTER '
                '($0D): USR never returns, so the ROM reads neither.', 13, figlib.FG)
    y += 104
    x = x0
    for kind, name in (('num', 'line number'), ('len', 'length field'), ('token', 'token or sign'),
                       ('digits', 'digits LIST prints'), ('hidden', '$0E + five-byte value used'),
                       ('end', 'end byte')):
        dr.rectangle([x, y + 3, x + 12, y + 14], fill=col[kind])
        figlib.text(dr, (x + 18, y), name, 12, figlib.FG)
        x += 30 + int(dr.textlength(name, font=figlib.font(12)))
    o = o.crop((0, 0, W, y + 28))
    o.save(out)
    print(out, o.size, numbers)


def tzx_turbo():
    z = zipfile.ZipFile(os.path.join(CASE, 'orig', 'Deflektor.tzx.zip'))
    d = z.read('Deflektor.tzx')
    p = 10
    while p < len(d):
        t = d[p]
        if t == 0x10:
            p += 5 + int.from_bytes(d[p + 3:p + 5], 'little')
        elif t == 0x11:
            n = int.from_bytes(d[p + 16:p + 19], 'little')
            return d[p + 19:p + 19 + n]
        else:
            raise SystemExit(f'block {t:02X}')


def byte_bits(v):
    """ReadByte's form of a byte (as tools/tapesim.py): 8 bits and the invert flag, the padding count."""
    zeros = 8 - bin(v).count('1')
    if zeros >= 4:
        b = [(v >> (7 - i)) & 1 for i in range(8)] + [0]
    else:
        b = [((~v) >> (7 - i)) & 1 for i in range(8)] + [1]
    return b, b.count(0) - 5


def read_bytes(bits, n):
    """LoadBlock's reading of the first n bytes: [(kind, bit, label)] pairs and the bytes."""
    pairs = [('lead', bits[0], 'lead pair')]
    p, out = 1, []
    for _ in range(n):
        b = bits[p:p + 9]
        p += 9
        v = 0
        for x in b[:8]:
            v = v << 1 | x
        if b[8]:
            v ^= 0xFF
        zeros = b.count(0)
        for k, x in enumerate(b[:8]):
            pairs.append(('bit', x, f'bit {7 - k}'))
        pairs.append(('flag', b[8], 'invert'))
        for _ in range(zeros - 5):
            pairs.append(('pad', bits[p], 'pad'))
            p += 1
        assert byte_bits(v) == (b, zeros - 5)
        out.append(v)
    return pairs, out


def byte(out):
    data = tzx_turbo()
    bits = [(x >> (7 - k)) & 1 for x in data[:8] for k in range(8)]
    pairs, vals = read_bytes(bits, 2)
    W = 1100
    o = Image.new('RGB', (W, 470), figlib.BG)
    dr = ImageDraw.Draw(o)
    figlib.text(dr, (10, 8), 'The turbo block\'s first pulses as LoadBlock reads them: a lead pair, then $32 and $26 '
                '(orig TZX)', 17, figlib.ACCENT)
    figlib.text(dr, (10, 32), 'TZX data bytes: ' + ' '.join(f'{x:02X}' for x in data[:4]) + ' ...  (one bit = one pulse '
                f'pair: 0 = 2 x {ZERO} T, 1 = 2 x {ONE} T)', 13, figlib.DIM)
    total = sum(2 * (ONE if b else ZERO) for _, b, _ in pairs)
    x0, x1 = 20, W - 20
    sc = (x1 - x0) / total
    col = {'lead': (150, 150, 165), 'bit': (90, 210, 120), 'flag': (240, 200, 80), 'pad': (230, 90, 160)}
    yb, hi, lo = 70, 70, 120
    x, level = x0, 0
    groups = []
    gi, cur = -1, None
    for i, (kind, b, lab) in enumerate(pairs):
        ln = ONE if b else ZERO
        xs = x
        for _ in range(2):
            nx = x + ln * sc
            y = hi if level else lo
            dr.line([x, yb + y - 70, nx, yb + y - 70], fill=col[kind], width=3)
            level ^= 1
            ny = hi if level else lo
            dr.line([nx, yb + y - 70, nx, yb + ny - 70], fill=col[kind], width=1)
            x = nx
        dr.rectangle([xs + 1, yb + 62, x - 1, yb + 80], fill=col[kind])
        figlib.text(dr, ((xs + x) / 2, yb + 71), str(b), 12, (0, 0, 0), anchor='mm')
        if kind == 'bit':
            figlib.text(dr, ((xs + x) / 2, yb + 90), lab.split()[1], 10, figlib.DIM, anchor='mm')
        elif kind in ('flag', 'pad', 'lead'):
            figlib.text(dr, ((xs + x) / 2, yb + 90), {'flag': 'inv', 'pad': 'pad', 'lead': 'lead'}[kind], 10,
                        figlib.DIM, anchor='mm')
        pairs[i] = (kind, b, lab, xs, x)
    # the bytes under their pairs
    y = yb + 112
    k = 1
    for n, v in enumerate(vals):
        seg = []
        while k < len(pairs) and (pairs[k][0] != 'bit' or not seg or pairs[k - 1][0] == 'bit'):
            seg.append(pairs[k])
            k += 1
            if len(seg) > 1 and seg[-1][0] == 'bit' and seg[-2][0] in ('flag', 'pad'):
                seg.pop()
                k -= 1
                break
        xa, xb = seg[0][3], seg[-1][4]
        dr.line([xa + 2, y, xb - 2, y], fill=figlib.FG, width=2)
        t = sum(2 * (ONE if p[1] else ZERO) for p in seg)
        nb = [p[1] for p in seg if p[0] == 'bit']
        zeros = [p[1] for p in seg if p[0] in ('bit', 'flag')].count(0)
        figlib.text(dr, (xa, y + 8), f'byte {n + 1} = ${v:02X}: bits {"".join(map(str, nb))}, invert '
                    f'{seg[8][1]}, {zeros} zeros of 9 -> {zeros - 5} pad', 13, figlib.FG)
        ones = [p[1] for p in seg].count(1)
        figlib.text(dr, (xa, y + 26), f'{ones} long + {len(seg) - ones} short pairs = {t} T; 13 short pairs are '
                    f'{13 * 2 * ZERO} T', 12, figlib.DIM)
    y += 64
    figlib.text(dr, (20, y), 'How ReadByte decides: EdgePair counts 56 T passes in B from $B0; above $CB is a 1. A 0 '
                f'pair is {2 * ZERO} T, a 1 pair {2 * ONE} T.', 13, figlib.FG)
    figlib.text(dr, (20, y + 20), 'A byte has at most four ones (else it is sent inverted with the flag 1); every 0 '
                'among the nine costs one more padding pair', 13, figlib.FG)
    figlib.text(dr, (20, y + 40), '(zeros - 5), so every byte lasts as long as 13 short pairs, whatever its value: the '
                'tape\'s timing never depends on the data.', 13, figlib.FG)
    y += 68
    x = 20
    for kind, name in (('lead', 'lead pair (LoadBlock)'), ('bit', 'data bit'), ('flag', 'invert flag'),
                       ('pad', 'padding pair (not tested)')):
        dr.rectangle([x, y + 3, x + 12, y + 14], fill=col[kind])
        figlib.text(dr, (x + 18, y), name, 12, figlib.FG)
        x += 230
    o = o.crop((0, 0, W, y + 26))
    o.save(out)
    print(out, o.size, [hex(v) for v in vals], total)


def stream():
    """ChainStart's two passes: {address: byte}."""
    mem = {}
    dd = 0x95
    for lo, n in ((0x5B00, 0x2052), (0xFD1B, 0x02E5)):
        for a in range(lo, lo + n):
            mem[a] = dd
            dd = (17 * dd + (a & 0xFF) + 11) & 0xFF
    return mem, dd


def fill(out):
    mem, last = stream()
    ent = open(os.path.join(CASE, 'work', 'stage1', 'images', 'entry.cpu.bin'), 'rb').read()
    same = [a for a in range(0x5B00, 0x6000) if ent[a] == mem[a]]
    diff = [a for a in range(0x5B00, 0x6000) if ent[a] != mem[a]]
    W = 1060
    o = Image.new('RGB', (W, 560), figlib.BG)
    dr = ImageDraw.Draw(o)
    figlib.text(dr, (10, 8), 'ChainFill: the memory ChainSum adds up, and the stream itself', 17, figlib.ACCENT)
    x0, x1 = 20, W - 20
    sc = (x1 - x0) / 0xC000
    y = 52
    figlib.text(dr, (x0, y - 18), '$4000-$FFFF when ChainSum $7B7D runs (after the move and the fill):', 13,
                figlib.DIM)
    parts = [(0x4000, 0x5B00, 'loading screen', (90, 150, 230)),
             (0x5B00, 0x7B52, 'fill, pass 1', (240, 200, 80)),
             (0x7B52, 0xFD1B, 'the moved block: chain, game, mover', (230, 90, 160)),
             (0xFD1B, 0x10000, 'fill, pass 2', (240, 200, 80))]
    for lo, hi, name, c in parts:
        dr.rectangle([x0 + (lo - 0x4000) * sc, y, x0 + (hi - 0x4000) * sc - 1, y + 36], fill=c)
        if hi - lo > 0x1800:
            figlib.text(dr, (x0 + (lo - 0x4000) * sc + 6, y + 10), name, 13, (0, 0, 0))
    for a in (0x4000, 0x5B00, 0x7B52):
        figlib.text(dr, (x0 + (a - 0x4000) * sc, y + 42), f'${a:04X}', 11, figlib.FG)
    figlib.text(dr, (x1, y + 42), 'fill, pass 2: $FD1B-$FFFF', 11, (240, 200, 80), anchor='ra')
    y += 72
    figlib.text(dr, (x0, y), 'Gone by then: the BASIC and the system variables (under the fill), the loader '
                '$B626-$BBDE (under MoveStub\'s LDIR and the block),', 13, figlib.FG)
    figlib.text(dr, (x0, y + 18), 'the block head at $5C00 (under the fill). So every key is a sum over the screen, '
                'the stream and the block.', 13, figlib.FG)
    y += 50
    figlib.text(dr, (x0, y), 'The first 32 bytes of the stream: (HL) = D, then D = 17 x D + L + 11 (mod 256), from D '
                '= $95 at $5B00', 13, figlib.DIM)
    y += 22
    for k in range(32):
        a = 0x5B00 + k
        x = x0 + (k % 16) * 64
        yy = y + (k // 16) * 64
        v = mem[a]
        g = v
        dr.rectangle([x, yy, x + 58, yy + 28], fill=(g, g, g))
        figlib.text(dr, (x + 29, yy + 14), f'{v:02X}', 13, (0, 0, 0) if g > 110 else (255, 255, 255), anchor='mm')
        figlib.text(dr, (x + 29, yy + 38), f'{a:04X}', 10, figlib.DIM, anchor='mm')
    y += 136
    lines = ['Worked: $5B00 = $95; 17 x $95 = $9E5, + L ($00) + 11 = $9F0 -> $F0 at $5B01;',
             '        17 x $F0 = $FF0, + $01 + 11 = $FFC -> $FC at $5B02; then $C9 at $5B03.',
             f'The entry image (entry.cpu.bin) still holds the stream at $5B00-$5FFF: {len(same)} of 1280 bytes;',
             f'        not equal: $5BFE-$5BFF = ${ent[0x5BFF]:02X}{ent[0x5BFE]:02X}, the last layer\'s return address (the '
             'chain runs with SP = $5C00),',
             '        and $5C09-$5C0A, REPDEL and REPPER, which the mover zeroes.',
             f'D after both passes: ${last:02X}; A = D + every byte of $4000-$FFFF is the first layer\'s key.']
    for k, t in enumerate(lines):
        figlib.text(dr, (x0, y + 20 * k), t, 13, figlib.FG)
    y += 20 * (len(lines) - 1)
    o = o.crop((0, 0, W, y + 66))
    o.save(out)
    print(out, o.size, len(same), [hex(a) for a in diff], hex(last))


if __name__ == '__main__':
    {'basic': basic, 'byte': byte, 'fill': fill}[sys.argv[1]](sys.argv[2])
