#!/usr/bin/env python3
"""Three pictures of the load (doc 03), each drawn from the bytes it explains:

    python3 tools/fig_loader.py basic docs/img/load/basic-line.png    # line 0 of the BASIC, build/basic.bin
    python3 tools/fig_loader.py byte docs/img/load/turbo-byte.png     # the turbo block's first pulses, orig TZX
    python3 tools/fig_loader.py fill docs/img/load/chainfill.png      # ChainFill's stream and the chain's sum area
    python3 tools/fig_loader.py layers docs/img/load/layers.png       # the 30 layers and Final16 by address
    python3 tools/fig_loader.py steps docs/img/load/cipher-steps.gif  # XorLayer and Final16 step by step

`basic`: the 52 bytes of line 0 coloured by kind; under each number the digits LIST shows and the hidden five-byte
value the ROM uses. `byte`: the pulse pairs after the sync, read as LoadBlock reads them (a lead pair, then ReadByte:
8 bits MSB first, the invert flag, zeros - 5 padding pairs), with the T-states of each. `fill`: the stream of
ChainStart `$7B52` (D = `$95`, D = 17 x D + L + 11) computed here and compared with the entry image
(work/stage1/images/entry.cpu.bin), and what `$4000-$FFFF` holds when ChainSum adds it up. `layers`: the 30 calls
of src/head/keys.txt, each XorLayer as the range it deciphers, each SumLayer as a mark, the depth per address, and
Final16's range. `steps`: the first XorLayer over `$7BC0-$7BC7` and Final16 over the words at `$A07A-$A089`, a byte
or a word a picture, from build/main.bin (the tape's bytes, moved by `$1F2B`), checked against build/head.bin and
build/game.bin.
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


MOVE = 0x1F2B                   # BlockHead's LDDR distance: tape $5C27 -> run $7B52


def build_bytes():
    b = os.path.join(CASE, 'build')
    return (open(os.path.join(b, 'main.bin'), 'rb').read(), open(os.path.join(b, 'head.bin'), 'rb').read(),
            open(os.path.join(b, 'game.bin'), 'rb').read())


def run_byte(main, a):
    """The byte at run address a ($7B52-$FD1A) as BlockHead leaves it, before the chain."""
    return main[a - MOVE - 0x5C00]


def read_layers():
    out = []
    for line in open(os.path.join(CASE, 'src', 'head', 'keys.txt')):
        f = line.split('#', 1)[0].split()
        if f and f[0] in ('xor', 'sum'):
            out.append((f[0], int(f[1], 16), int(f[2]), int(f[3]), int(f[4])))
    return out


def layers(out):
    lay = read_layers()
    lo, hi = 0x7BB0, 0x7D40
    W, x0, x1 = 1060, 250, 1040
    sc = (x1 - x0) / (hi - lo)
    rh = 17
    o = Image.new('RGB', (W, 120 + rh * len(lay) + 190), figlib.BG)
    dr = ImageDraw.Draw(o)
    figlib.text(dr, (10, 8), "The chain's 30 layers by address: 18 decipher, 12 only sum", 17, figlib.ACCENT)
    figlib.text(dr, (10, 32), 'One row a call, in the order they run (src/head/keys.txt). Bar: the B bytes an XorLayer '
                'deciphers after its call;', 13, figlib.DIM)
    figlib.text(dr, (10, 50), 'dot: a SumLayer (deciphers nothing, adds memory into A). The tick on each row is the '
                'call\'s key byte (RET).', 13, figlib.DIM)
    y = 80
    for a in range(0x7BC0, hi, 0x20):
        x = x0 + (a - lo) * sc
        dr.line([x, y - 4, x, y + rh * len(lay)], fill=(55, 55, 65))
        figlib.text(dr, (x, y - 16), f'${a:04X}', 11, figlib.DIM, anchor='ma')
    depth = [0] * (hi - lo)
    total = 0
    for k, (kind, ret, b, c, a) in enumerate(lay):
        yy = y + 4 + k * rh
        n = b or 256
        col = (230, 90, 160) if kind == 'xor' else (90, 150, 230)
        label = f'{k + 1:2d} {kind} RET ${ret:04X} B {n:3d} C ${c:02X}'
        figlib.text(dr, (10, yy - 1), label, 12, col)
        rx = x0 + (ret - lo) * sc
        dr.line([rx, yy, rx, yy + rh - 6], fill=figlib.FG)
        if kind == 'xor':
            total += n
            dr.rectangle([x0 + (ret + 1 - lo) * sc, yy + 2, x0 + (ret + 1 + n - lo) * sc - 1, yy + rh - 8], fill=col)
            for t in range(ret + 1, ret + 1 + n):
                depth[t - lo] += 1
        else:
            dr.ellipse([rx + 3, yy + 1, rx + 11, yy + 9], fill=col)
    y += 8 + rh * len(lay)
    figlib.text(dr, (10, y), f'layers on one address (max {max(depth)})', 12, figlib.FG)
    m = max(depth)
    for i, d in enumerate(depth):
        if d:
            x = x0 + i * sc
            dr.rectangle([x, y + 40 - 36 * d / m, x + sc, y + 40], fill=(240, 200, 80))
    y += 52
    figlib.text(dr, (10, y), f'XorLayer bytes deciphered: {total}, on {sum(1 for d in depth if d)} addresses '
                f'(${lo + min(i for i, d in enumerate(depth) if d):04X}-${lo + max(i for i, d in enumerate(depth) if d):04X})',
                13, figlib.FG)
    y += 28
    figlib.text(dr, (10, y), 'Then Final16 (one layer of 16-bit words, autokey) over $7D00-$FD19, 16 397 words:', 13,
                figlib.FG)
    y += 22
    fx0, fx1 = 20, W - 20
    fs = (fx1 - fx0) / (0xFD1A - 0x7B52)
    dr.rectangle([fx0, y, fx1, y + 22], outline=figlib.DIM)
    dr.rectangle([fx0 + (0x7BC0 - 0x7B52) * fs, y + 1, fx0 + (0x7D34 - 0x7B52) * fs, y + 21], fill=(230, 90, 160))
    dr.rectangle([fx0 + (0x7D00 - 0x7B52) * fs, y + 6, fx1 - 1, y + 16], fill=(120, 200, 120))
    for a, t, anc in ((0x7B52, '$7B52 (the XOR layers to $7D33, Final16 from $7D00)', 'la'), (0xFD1A, '$FD1A', 'ra')):
        figlib.text(dr, (fx0 + (a - 0x7B52) * fs, y + 26), t, 11, figlib.FG, anchor=anc)
    figlib.text(dr, (fx0, y + 44), 'green: Final16 (the game and the mover); pink: the XOR layers; '
                '$7D00-$7D33 gets both', 11, figlib.DIM)
    o = o.crop((0, 0, W, y + 66))
    o.save(out)
    print(out, o.size, total, max(depth))


def steps(out):
    main, head, game = build_bytes()
    lay = read_layers()
    kind, ret, b, c, a = lay[0]
    frames = []
    W, H = 1000, 330
    plain_head = head[0x27 + 0x7BC0 - 0x7B52:]

    def cell(dr, x, y, v, hl, txt=None):
        g = (240, 200, 80) if hl else (60, 60, 72)
        dr.rectangle([x, y, x + 92, y + 30], fill=g)
        figlib.text(dr, (x + 46, y + 15), txt if txt is not None else f'{v:02X}', 15,
                    (0, 0, 0) if hl else figlib.FG, anchor='mm')

    # XorLayer, layer 1: 8 bytes from $7BC0
    addrs = list(range(ret + 1, ret + 9))
    cip = [run_byte(main, x) for x in addrs]
    keys, pl = [], []
    prev = a
    for k in range(8):
        key = (17 * prev + c) & 0xFF
        p = key ^ cip[k]
        keys.append(key)
        pl.append(p)
        prev = p
    assert bytes(pl[:7]) == plain_head[:7], (pl, plain_head[:7])
    assert pl[7] == 0x45                      # keys.txt: the byte at $7BC7 before layer 2 writes its C there
    for k in range(9):
        o = Image.new('RGB', (W, H), figlib.BG)
        dr = ImageDraw.Draw(o)
        figlib.text(dr, (10, 8), 'XorLayer $7B84, the first call: B = 198, C = $D9, incoming A = 0 (autokey)', 17,
                    figlib.ACCENT)
        figlib.text(dr, (10, 34), 'Each byte: key = 17 x (the previous plain byte, first A) + C; plain = cipher XOR key',
                    13, figlib.DIM)
        for j, x in enumerate(addrs):
            xx = 140 + j * 104
            figlib.text(dr, (xx + 46, 70), f'${x:04X}', 12, figlib.DIM, anchor='mm')
            cell(dr, xx, 84, cip[j], j == k)
            cell(dr, xx, 134, keys[j], j == k, None if j <= k else '')
            cell(dr, xx, 184, pl[j], j == k, None if j <= k else '')
        for r, t in ((84, 'cipher'), (134, 'key'), (184, 'plain')):
            figlib.text(dr, (10, r + 8), t, 14, figlib.FG)
        if k < 8:
            pv = a if k == 0 else pl[k - 1]
            figlib.text(dr, (10, 236), f'${addrs[k]:04X}: key = 17 x ${pv:02X} + ${c:02X} = ${17 * pv + c:03X} -> '
                        f'${keys[k]:02X};  ${cip[k]:02X} XOR ${keys[k]:02X} = ${pl[k]:02X}', 15, figlib.FG)
        figlib.text(dr, (10, 266), 'plain $7BC0-$7BC6: CB 38 CB F8 CD 84 7B = SRL B; SET 7,B; CALL XorLayer (the next '
                    'layer)', 13, figlib.DIM)
        figlib.text(dr, (10, 288), '$7BC7 = $45 here; the next call writes its C ($D9, EXX) over it. The layer runs on '
                    'for 198 bytes.', 13, figlib.DIM)
        frames.append(o)
    # Final16 over 8 words around the entry
    w0 = 0xA07A
    wa = list(range(w0, w0 + 16, 2))
    cw = [run_byte(main, x) | run_byte(main, x + 1) << 8 for x in wa]
    pw = [game[x - 0x1D00 - 0x6000] | game[x + 1 - 0x1D00 - 0x6000] << 8 for x in wa]
    prevw = game[w0 - 2 - 0x1D00 - 0x6000] | game[w0 - 1 - 0x1D00 - 0x6000] << 8
    kw = []
    for k in range(8):
        lo_, hi_ = (prevw if k == 0 else pw[k - 1]) & 0xFF, (prevw if k == 0 else pw[k - 1]) >> 8
        key = ((lo_ << 8 | lo_) + (hi_ << 8 | 0x29)) & 0xFFFF
        kw.append(key)
        assert cw[k] ^ key == pw[k], (hex(wa[k]), hex(cw[k]), hex(key), hex(pw[k]))
    for k in range(9):
        o = Image.new('RGB', (W, H), figlib.BG)
        dr = ImageDraw.Draw(o)
        figlib.text(dr, (10, 8), 'Final16 $7CBE: one word a step over $7D00-$FD19 (autokey on words)', 17, figlib.ACCENT)
        figlib.text(dr, (10, 34), 'key = (L:L) + (B:$29), L and B the previous plain word\'s low and high byte; '
                    'plain = cipher XOR key', 13, figlib.DIM)
        for j, x in enumerate(wa):
            xx = 140 + j * 104
            figlib.text(dr, (xx + 46, 70), f'${x:04X}', 12, figlib.DIM, anchor='mm')
            cell(dr, xx, 84, 0, j == k, f'{cw[j] & 0xFF:02X} {cw[j] >> 8:02X}')
            cell(dr, xx, 134, 0, j == k, f'{kw[j] & 0xFF:02X} {kw[j] >> 8:02X}' if j <= k else '')
            cell(dr, xx, 184, 0, j == k, f'{pw[j] & 0xFF:02X} {pw[j] >> 8:02X}' if j <= k else '')
        for r, t in ((84, 'cipher'), (134, 'key'), (184, 'plain')):
            figlib.text(dr, (10, r + 8), t, 14, figlib.FG)
        if k < 8:
            pv = prevw if k == 0 else pw[k - 1]
            figlib.text(dr, (10, 236), f'${wa[k]:04X}: key = ${pv & 0xFF:02X}{pv & 0xFF:02X} + ${pv >> 8:02X}29 = '
                        f'${kw[k]:04X};  ${cw[k]:04X} XOR ${kw[k]:04X} = ${pw[k]:04X}', 15, figlib.FG)
        figlib.text(dr, (10, 266), 'bytes in memory order (low first). $A082 = the game\'s $8382 after the mover: '
                    'C3 08 84 = JP $8408', 13, figlib.DIM)
        figlib.text(dr, (10, 288), 'The first key of all, at $7D00, is $FBFB + $4329 = $3F24 (FinalSum\'s $43FB).', 13,
                    figlib.DIM)
        frames.append(o)
    dur = [900] * 8 + [2500] + [900] * 8 + [2500]
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=dur, loop=0, optimize=True)
    print(out, len(frames), [hex(x) for x in pl], [hex(x) for x in kw])


if __name__ == '__main__':
    {'basic': basic, 'byte': byte, 'fill': fill, 'layers': layers, 'steps': steps}[sys.argv[1]](sys.argv[2])
