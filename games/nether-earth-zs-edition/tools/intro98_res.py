#!/usr/bin/env python3
"""The resources of the '98 intro and BASIC (src/res/intro98) as editable files, built back into the bytes the
sources INCBIN (src/intro98/*.asm through kit/mkgame.py --part src/intro98/intro.json, src/basic98/basic.asm).

| Source (src/res/intro98)     | Built (build/intro98/res/intro98) | Format                                           |
| ---------------------------- | --------------------------------- | ------------------------------------------------ |
| `cool-winter.pt3`            | the same file                     | the Pro Tracker 3 module, as the tracker saves it |
| `scroll-text.txt`            | `scroll-text.bin`                 | UTF-8, markers [font $XXXX] [loop] [end] [$XX]    |
| `logo.png`                   | `logo-mask.bin`                   | 8 x 8 cells (8 x 8 pixels each), lit = 1          |
| `robot.png`, `robot.parse`   | `robot.bin`                       | the 4 animation frames + the token list           |
| `font.png`                   | `font.bin`                        | 96 glyphs from code $20, 16 a row, ink = 1        |
| `font-tail-leftover.bin`     | the same file                     | bytes (no code reads them)                        |
| `basic98-slack.bin`          | the same file                     | bytes (the BASIC sector's tail as saved)          |

The scroller text (ScrollText, $DAC2-$E3B8): KOI-7 N2 as the intro's font draws it: $20-$3F as ASCII, $40-$5F the
upper-case Cyrillic ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧЪ, $60-$7F the same in lower case; `$01 LO HI` switches the font
(written [font $3D00]: the ROM's font, its bytes read as ASCII; [font $E6CC]: the intro's own), `$00` ends it and
the word after it is the address the scroller goes on from ([loop] marks that place, [end] the `$00`). The text
lines of the file are joined with nothing between them (a line break is not a character; lines are broken only
before a space), lines starting with `#` are comments.

The robot (RobotStream, $E4B3-$E6CB): four frames of the animation RobotFrame ($E3FE) draws every 32 frames into
the box at column 13, row 16 (6 x 8 cells). robot.png holds the four screens of the box side by side (each the box
after its frame is decoded; the first from a black box), robot.parse the token list of the stream (one token a
line, the bytes of literals and fills come from the PNG): `skip N` (code $84-$BF, 1-60), `skipl N` ($80-$83 + a
byte, 0-1023), `lit N` (an even code $C2-$FE, 1-31 bytes), `fill N` (4j+1 codes: 3-17 times the next byte),
`filll N` ($C1 + count + byte), `zero N` (4j+3 codes: 2-16 zeros), `zerol N` ($C3 + count), `copy N -D` (codes
$00-$7F + a byte: N = 3-18 bytes from D = 1-2048 bytes back), `end` ($C0). The order of the output is the decoder's
(down each column of bytes of a screen third, then the next column).

    python3 tools/intro98_res.py build [--out build/intro98/res]   # the INCBIN files from the sources
    python3 tools/intro98_res.py check                             # each source built, written back, built again
    python3 tools/intro98_res.py export --from DIR                 # .bin files of DIR (an mkgame res/) to sources
    python3 tools/intro98_res.py pt3 FILE                          # parse a .pt3 and print what it holds
"""
import argparse
import io
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
PART = 'intro98'

TEXT_ORG = 0xDAC2                 # ScrollText: the address [loop] is counted from
INTRO_FONT, ROM_FONT = 0xE6CC, 0x3D00
CYRILLIC = 'ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧЪ'
BOX_COL, BOX_ROW, BOX_W, BOX_H = 13, 16, 6, 8   # the robot's box in cells (RobotHeader $E3F9 says the same)
FRAMES = 4

INK_PAPER = [(0, 0, 0), (215, 215, 0)]          # robot: yellow ink (attribute 6) on black
GLYPH = [(24, 24, 32), (230, 230, 230)]
LOGO = [(0, 0, 0), (0, 215, 215)]               # the logo's cells as at a frame with paper 5

SOURCES = {  # built file: source(s)
    'scroll-text.bin': ['scroll-text.txt'],
    'logo-mask.bin': ['logo.png'],
    'robot.bin': ['robot.png', 'robot.parse'],
    'font.bin': ['font.png'],
}

# ---------------------------------------------------------------------------------------------------- text


def text_to_utf8(data):
    out, i, rom = [], 0, False
    end = 0
    while data[end]:  # the $00 that ends it (a font switch's low byte may be 0 too)
        end += 3 if data[end] == 1 else 1
    loop = (data[end + 1] | data[end + 2] << 8) - TEXT_ORG
    assert len(data) == end + 3, 'scroll text: bytes after the loop word'
    while i < len(data):
        if i == loop:
            out.append('[loop]')
        b = data[i]
        if b == 0:
            out.append('[end]')
            break
        if b == 1:
            font = data[i + 1] | data[i + 2] << 8
            rom = font == ROM_FONT
            assert font in (ROM_FONT, INTRO_FONT), f'font ${font:04X}'
            out.append(f'[font ${font:04X}]')
            i += 3
            continue
        if 0x20 <= b < 0x40 or (rom and 0x20 <= b < 0x7F and chr(b) != '['):
            out.append(chr(b))
        elif 0x40 <= b < 0x60 and not rom:
            out.append(CYRILLIC[b - 0x40])
        elif 0x60 <= b < 0x80 and not rom:
            out.append(CYRILLIC[b - 0x60].lower())
        else:
            out.append(f'[${b:02X}]')
        i += 1
    flat = ''.join(out)
    # lines broken only before a space, about 110 characters long
    lines, cur, inside = [], '', False
    for k, ch in enumerate(flat):
        if ch == ' ' and not inside and len(cur) >= 110 and (k == 0 or flat[k - 1] != ' '):
            lines.append(cur)
            cur = ''
        inside = (inside or ch == '[') and ch != ']'
        cur += ch
    lines.append(cur)
    head = ['# The intro scroller of Nether Earth ZS Edition \'98 (ScrollText, $DAC2-$E3B8 of the intro block).',
            '# KOI-7 N2 in the original; tools/intro98_res.py turns this file back into those bytes. Line breaks are',
            '# not characters; [font $3D00] / [font $E6CC] switch the font, [loop] is where the scroller goes on',
            '# after [end].']
    return ('\n'.join(head + lines) + '\n').encode('utf-8')


def utf8_to_text(raw, name='scroll-text.txt'):
    text = ''.join(l for l in raw.decode('utf-8').split('\n') if not l.startswith('#'))
    out, i, rom, loop, end = bytearray(), 0, False, None, None
    lower = CYRILLIC.lower()
    while i < len(text):
        ch = text[i]
        if ch == '[':
            j = text.index(']', i)
            tag = text[i + 1:j]
            i = j + 1
            if tag.startswith('font $'):
                font = int(tag[6:], 16)
                rom = font == ROM_FONT
                out += bytes([1, font & 255, font >> 8])
            elif tag == 'loop':
                loop = len(out)
            elif tag == 'end':
                end = len(out)
                out.append(0)
            elif tag.startswith('$'):
                out.append(int(tag[1:], 16))
            else:
                sys.exit(f'{name}: unknown marker [{tag}]')
            continue
        if rom:
            if not 0x20 <= ord(ch) < 0x7F:
                sys.exit(f'{name}: {ch!r} in the ROM font part')
            out.append(ord(ch))
        elif 0x20 <= ord(ch) < 0x40:
            out.append(ord(ch))
        elif ch in CYRILLIC:
            out.append(0x40 + CYRILLIC.index(ch))
        elif ch in lower:
            out.append(0x60 + lower.index(ch))
        else:
            sys.exit(f'{name}: {ch!r} has no code in the intro font')
        i += 1
    if end is None or loop is None:
        sys.exit(f'{name}: [end] or [loop] missing')
    address = TEXT_ORG + loop
    out += bytes([address & 255, address >> 8])
    return bytes(out)

# ---------------------------------------------------------------------------------------------------- PNG


def new_image(size, palette):
    image = Image.new('P', size, 0)
    image.putpalette([c for rgb in palette for c in rgb])
    return image


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG')
    return buffer.getvalue()


def indices(raw, palette, name):
    """{(x, y): palette index} and the size of a PNG in exactly the palette's colours"""
    image = Image.open(io.BytesIO(raw)).convert('RGB')
    px = image.load()
    lookup = {c: i for i, c in enumerate(palette)}
    out = {}
    for y in range(image.height):
        for x in range(image.width):
            if px[x, y] not in lookup:
                sys.exit(f'{name}: colour {px[x, y]} at ({x}, {y}) is not one of {palette}')
            out[x, y] = lookup[px[x, y]]
    return out, image.size


def font_to_png(data):
    image = new_image((128, len(data) // 128 * 8), GLYPH)
    px = image.load()
    for g in range(len(data) // 8):
        for line in range(8):
            for bit in range(8):
                px[(g % 16) * 8 + bit, (g // 16) * 8 + line] = 1 if data[g * 8 + line] & (0x80 >> bit) else 0
    return png_bytes(image)


def png_to_font(raw, name='font.png'):
    px, (w, h) = indices(raw, GLYPH, name)
    if w != 128 or h % 8:
        sys.exit(f'{name}: {w} x {h}, not 128 wide and whole glyph rows')
    return bytes(sum(0x80 >> bit for bit in range(8) if px[(g % 16) * 8 + bit, (g // 16) * 8 + line])
                 for g in range(h // 8 * 16) for line in range(8))


def logo_to_png(data):
    assert set(data) <= {0, 1} and len(data) == 64
    image = new_image((64, 64), LOGO)
    px = image.load()
    for k, b in enumerate(data):
        for y in range(8):
            for x in range(8):
                px[(k % 8) * 8 + x, (k // 8) * 8 + y] = b
    return png_bytes(image)


def png_to_logo(raw, name='logo.png'):
    px, size = indices(raw, LOGO, name)
    if size != (64, 64):
        sys.exit(f'{name}: {size}, not 64 x 64 (8 x 8 cells)')
    out = []
    for k in range(64):
        cell = {px[(k % 8) * 8 + x, (k // 8) * 8 + y] for y in range(8) for x in range(8)}
        if len(cell) != 1:
            sys.exit(f'{name}: cell {k % 8},{k // 8} is not one colour')
        out.append(cell.pop())
    return bytes(out)

# ---------------------------------------------------------------------------------------------------- robot


def screen_address(v):
    """the screen byte of the decoder's output position v (RobotFrame's conversion: down a column of a third)"""
    h, l = v >> 8, v & 255
    if h >= 0x58:
        return v
    e = (l & 0xF8) | (h & 7)
    return ((h & 0xF8) | (l & 7)) << 8 | ((e << 2) | (e >> 6)) & 255


def box_bytes(screen):
    """the box's bytes, row by row of pixels"""
    out = bytearray()
    for y in range(BOX_H * 8):
        row = BOX_ROW * 8 + y
        a = 0x4000 | (row & 0xC0) << 5 | (row & 7) << 8 | (row & 0x38) << 2 | BOX_COL
        out += screen[a:a + BOX_W]
    return bytes(out)


def box_set(screen, data):
    for y in range(BOX_H * 8):
        row = BOX_ROW * 8 + y
        a = 0x4000 | (row & 0xC0) << 5 | (row & 7) << 8 | (row & 0x38) << 2 | BOX_COL
        screen[a:a + BOX_W] = data[y * BOX_W:(y + 1) * BOX_W]


def in_box(a):
    if a >= 0x5800:
        return False
    row = ((a >> 5) & 0xC0) | ((a >> 2) & 0x38) | ((a >> 8) & 7)
    col = a & 31
    return BOX_COL <= col < BOX_COL + BOX_W and BOX_ROW * 8 <= row < (BOX_ROW + BOX_H) * 8


def robot_decode(stream):
    """the four box images and the token list of the stream"""
    screen = bytearray(0x10000)
    frames, tokens, pos = [], [], 0
    while pos < len(stream):
        de = 0x4000
        while True:
            b = stream[pos]
            pos += 1
            if b >= 0xC0:
                n = b - 0xC0
                if n == 0:
                    tokens.append('end')
                    break
                if n % 2 == 0:
                    vals = list(stream[pos:pos + n // 2])
                    pos += n // 2
                    tokens.append(f'lit {n // 2}')
                else:
                    j = n >> 2
                    if j == 0:
                        cnt = stream[pos] or 256
                        pos += 1
                    else:
                        cnt = j + 1 if n & 2 else j + 2
                    if n & 2:
                        vals = [0] * cnt
                        tokens.append(f'zero{"l" if j == 0 else ""} {cnt}')
                    else:
                        vals = [stream[pos]] * cnt
                        pos += 1
                        tokens.append(f'fill{"l" if j == 0 else ""} {cnt}')
                for v in vals:
                    a = screen_address(de)
                    assert in_box(a), f'robot: a write outside the box at ${a:04X}'
                    screen[a] = v
                    de += 1
            elif b >= 0x80:
                n = b & 0x3F
                if n < 4:
                    skip = n * 256 + stream[pos]
                    pos += 1
                    tokens.append(f'skipl {skip}')
                else:
                    skip = n - 3
                    tokens.append(f'skip {skip}')
                de += skip
            else:
                cnt = ((b >> 3) & 15) + 3
                back = 0x800 - ((b & 7) << 8 | stream[pos])
                pos += 1
                for _ in range(cnt):
                    a = screen_address(de)
                    assert in_box(a), f'robot: a copy outside the box at ${a:04X}'
                    screen[a] = screen[screen_address(de - back)]
                    de += 1
                tokens.append(f'copy {cnt} -{back}')
        frames.append(box_bytes(screen))
    return frames, tokens


def robot_encode(frames, tokens, name='robot.parse'):
    """the stream from the box images and the token list; every frame checked against its image"""
    screen = bytearray(0x10000)
    out = bytearray()
    it = iter(tokens)
    for f, target in enumerate(frames):
        want = bytearray(0x10000)
        box_set(want, target)
        de = 0x4000
        for tok in it:
            kind, *args = tok.split()
            if kind == 'end':
                out.append(0xC0)
                break
            n = int(args[0]) if args else 0
            if kind in ('skip', 'skipl'):
                if kind == 'skip':
                    assert 1 <= n <= 60, f'{name}: skip {n}'
                    out.append(0x80 + n + 3)
                else:
                    assert 0 <= n < 0x400, f'{name}: skipl {n}'
                    out += bytes([0x80 + (n >> 8), n & 255])
                de += n
                continue
            if kind == 'copy':
                back = -int(args[1])
                assert 3 <= n <= 18 and 1 <= back <= 0x800, f'{name}: {tok}'
                field = 0x800 - back
                out += bytes([(n - 3) << 3 | field >> 8, field & 255])
                for _ in range(n):
                    screen[screen_address(de)] = screen[screen_address(de - back)]
                    de += 1
                continue
            vals = [want[screen_address(de + k)] for k in range(n)]
            if kind == 'lit':
                assert 1 <= n <= 31, f'{name}: {tok}'
                out += bytes([0xC0 + 2 * n]) + bytes(vals)
            elif kind in ('fill', 'filll', 'zero', 'zerol'):
                if len(set(vals)) != 1 or (kind.startswith('zero') and vals[0]):
                    sys.exit(f'{name}: frame {f + 1}: {tok} over bytes that differ: {bytes(vals).hex()}')
                if kind == 'fill':
                    assert 3 <= n <= 17, f'{name}: {tok}'
                    out += bytes([0xC0 + 4 * (n - 2) + 1, vals[0]])
                elif kind == 'zero':
                    assert 2 <= n <= 16, f'{name}: {tok}'
                    out.append(0xC0 + 4 * (n - 1) + 3)
                else:
                    assert 1 <= n <= 256, f'{name}: {tok}'
                    out += bytes([0xC1 if kind == 'filll' else 0xC3, n & 255])
                    if kind == 'filll':
                        out.append(vals[0])
            else:
                sys.exit(f'{name}: cannot read {tok!r}')
            for v in vals:
                screen[screen_address(de)] = v
                de += 1
        if box_bytes(screen) != target:
            sys.exit(f'{name}: frame {f + 1} decodes to another picture than robot.png\'s')
    if next(it, None) is not None:
        sys.exit(f'{name}: tokens after the last frame')
    return bytes(out)


def robot_to_sources(stream):
    frames, tokens = robot_decode(stream)
    assert len(frames) == FRAMES
    image = new_image((BOX_W * 8 * FRAMES, BOX_H * 8), INK_PAPER)
    px = image.load()
    for f, data in enumerate(frames):
        for y in range(BOX_H * 8):
            for x in range(BOX_W * 8):
                px[f * BOX_W * 8 + x, y] = 1 if data[y * BOX_W + x // 8] & (0x80 >> (x % 8)) else 0
    parse = ['# The robot animation\'s token list (tools/intro98_res.py: RobotStream, $E4B3-$E6CB). One token a line;',
             '# frames end with "end". The literal and fill bytes come from robot.png.']
    frame = 1
    parse.append(f'# frame {frame}')
    for k, t in enumerate(tokens):
        parse.append(t)
        if t == 'end' and k + 1 < len(tokens):
            frame += 1
            parse.append(f'# frame {frame}')
    return png_bytes(image), ('\n'.join(parse) + '\n').encode()


def sources_to_robot(png, parse):
    px, size = indices(png, INK_PAPER, 'robot.png')
    if size != (BOX_W * 8 * FRAMES, BOX_H * 8):
        sys.exit(f'robot.png: {size}, not {FRAMES} frames of {BOX_W * 8} x {BOX_H * 8}')
    frames = []
    for f in range(FRAMES):
        data = bytearray()
        for y in range(BOX_H * 8):
            for c in range(BOX_W):
                data.append(sum(0x80 >> b for b in range(8) if px[f * BOX_W * 8 + c * 8 + b, y]))
        frames.append(bytes(data))
    tokens = [l.strip() for l in parse.decode().split('\n') if l.strip() and not l.startswith('#')]
    return robot_encode(frames, tokens)

# ---------------------------------------------------------------------------------------------------- PT3


def pt3_info(data):
    """what a PT3 module holds; its length must be the end of its last sample or ornament"""
    w = lambda o: data[o] | data[o + 1] << 8
    assert data[:13] == b'ProTracker 3.', 'not a Pro Tracker 3 module'
    positions = []
    i = 201
    while data[i] != 0xFF:
        positions.append(data[i])
        i += 1
    patterns = max(positions) // 3 + 1
    samples = [w(105 + 2 * k) for k in range(32)]
    ornaments = [w(169 + 2 * k) for k in range(16)]
    ends = [s + 2 + 4 * data[s + 1] for s in samples if s] + [o + 2 + data[o + 1] for o in ornaments if o]
    table = w(103)
    tracks = [w(table + 6 * p + 2 * c) for p in range(patterns) for c in range(3)]
    return {'title': data[30:62].decode('latin-1').rstrip(), 'author': data[66:98].decode('latin-1').rstrip(),
            'version': chr(data[13]), 'tone table': data[99], 'delay': data[100], 'positions': positions,
            'loop': data[102], 'patterns': patterns, 'samples': sum(1 for s in samples if s),
            'ornaments': sum(1 for o in ornaments if o), 'first track': min(tracks), 'end': max(ends),
            'length': len(data)}

# ---------------------------------------------------------------------------------------------------- files


def decode_sources(res):
    """{built file: bytes} from the sources in res (src/res/intro98)"""
    read = lambda n: open(os.path.join(res, n), 'rb').read()
    out = {}
    for name in sorted(os.listdir(res)):
        if name.endswith(('.pt3', '.bin')):
            out[name] = read(name)
    out['scroll-text.bin'] = utf8_to_text(read('scroll-text.txt'))
    out['logo-mask.bin'] = png_to_logo(read('logo.png'))
    out['robot.bin'] = sources_to_robot(read('robot.png'), read('robot.parse'))
    out['font.bin'] = png_to_font(read('font.png'))
    return out


def encode_files(files):
    """{source: bytes} for the files of an mkgame res/ (names without the intro98/ folder)"""
    out = {}
    for name, data in files.items():
        if name == 'scroll-text.bin':
            out['scroll-text.txt'] = text_to_utf8(data)
        elif name == 'logo-mask.bin':
            out['logo.png'] = logo_to_png(data)
        elif name == 'robot.bin':
            out['robot.png'], out['robot.parse'] = robot_to_sources(data)
        elif name == 'font.bin':
            out['font.png'] = font_to_png(data)
        else:
            out[name] = data
    return out


def install(files, res=RES):
    """mkgame's {intro98/NAME: bytes} into src/res/intro98 as sources (called by kit/mkgame.py --part src/intro98/intro.json --install)"""
    folder = os.path.join(res, PART)
    os.makedirs(folder, exist_ok=True)
    plain = {}
    for name, data in files.items():
        assert name.startswith(PART + '/'), f'{name}: not under {PART}/'
        plain[name[len(PART) + 1:]] = data
    for name, data in encode_files(plain).items():
        open(os.path.join(folder, name), 'wb').write(data)
    built = decode_sources(folder)
    for name, data in plain.items():
        assert built[name] == data, f'{name}: its source does not build back'


def build(out, res=RES):
    files = decode_sources(os.path.join(res, PART))
    os.makedirs(os.path.join(out, PART), exist_ok=True)
    for name, data in files.items():
        open(os.path.join(out, PART, name), 'wb').write(data)
    return files


def check(res=RES):
    folder = os.path.join(res, PART)
    built = decode_sources(folder)
    bad = 0
    for name, srcs in SOURCES.items():
        again = decode_sources_from(encode_files({name: built[name]}), name)
        same = again == built[name]
        text_same = all(encode_files({name: built[name]})[s] == open(os.path.join(folder, s), 'rb').read()
                        for s in srcs if not s.endswith('.png'))
        bad += not same
        print(f'{", ".join(srcs)} -> {name}: {len(built[name])} bytes, round trip '
              f'{"exact" if same else "DIFFERS"}{"" if text_same else " (the text differs from the exported one)"}')
    info = pt3_info(built['cool-winter.pt3'])
    ok = info['end'] == info['length']
    bad += not ok
    print(f'cool-winter.pt3: "{info["title"]}" {info["author"]}, PT 3.{info["version"]}, {info["patterns"]} patterns, '
          f'{len(info["positions"])} positions (loop {info["loop"]}), {info["samples"]} samples, {info["ornaments"]} '
          f'ornaments, delay {info["delay"]}, tone table {info["tone table"]}; parsed to its last byte: '
          f'{"yes" if ok else "NO"} ({info["end"]} of {info["length"]})')
    return bad


def decode_sources_from(sources, name):
    if name == 'scroll-text.bin':
        return utf8_to_text(sources['scroll-text.txt'])
    if name == 'logo-mask.bin':
        return png_to_logo(sources['logo.png'])
    if name == 'robot.bin':
        return sources_to_robot(sources['robot.png'], sources['robot.parse'])
    return png_to_font(sources['font.png'])


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--res', default=RES)
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--out', default=os.path.join(ROOT, 'build', 'intro98', 'res'))
    sub.add_parser('check')
    e = sub.add_parser('export')
    e.add_argument('--from', dest='src', required=True)
    t = sub.add_parser('pt3')
    t.add_argument('file')
    a = p.parse_args()
    if a.cmd == 'build':
        files = build(a.out, a.res)
        print(f'intro98 res: {len(files)} files into {a.out}/{PART}')
    elif a.cmd == 'check':
        bad = check(a.res)
        print('intro98 res: every source round-trips' if not bad else f'intro98 res: {bad} source(s) differ')
        return 1 if bad else 0
    elif a.cmd == 'export':
        files = {f'{PART}/{n}': open(os.path.join(a.src, n), 'rb').read() for n in os.listdir(a.src)}
        install(files, a.res)
        print(f'intro98 res: {len(files)} files exported into {a.res}/{PART}')
    else:
        for k, v in pt3_info(open(a.file, 'rb').read()).items():
            print(f'{k}: {v}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
