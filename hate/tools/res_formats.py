#!/usr/bin/env python3
"""Editable sources for the resources of src/res (src/res/README.md, "Editable sources"). The graphics are PNG and
the title tune is one text file. They become the original `.bin` files at build time (tools/build.sh), and the
build's byte-exact check against orig/HATE.TAP keeps them honest.

| Source | Files built | Format |
| --- | --- | --- |
| `gfx/font.png` | `gfx/font.bin` | 8 x 8 glyphs, 16 a row, from code `$20`; index 0 paper, 1 ink, 2 no glyph |
| `gfx/tiles.png` | `gfx/tiles.bin` | 8 x 8 course tiles, 16 a row, upright (the file stores each tile bottom line first) |
| `gfx/sprites/slot-NN.png` | `gfx/sprites/slot-NN.bin` | the 4 pre-shifted frames side by side, upright |
| `gfx/explosions/slot-NN.png` | `gfx/explosions/slot-NN.bin` | one frame of 4 strips, upright |
| `music/title/tune.txt` | `music/title/*.bin` | the song, its patterns and drum patterns as commands (docs/09-sound.md) |

Sprite pixels: 0 see-through (mask 1, pixel 0), 1 black (mask 0, pixel 0), 2 ink (mask 0, pixel 1), 3 ink over
the background (mask 1, pixel 1; not used by the game), 4 no strip (frame 3 is one strip narrower). A PNG may be
saved indexed or as RGB in exactly the palette's colours.

    python3 tools/res_formats.py build [--out build/res]      # every file of src/res, the sources converted
    python3 tools/res_formats.py export [--from DIR]          # .bin files (src/res or DIR) to sources in src/res
    python3 tools/res_formats.py check                        # export + build in memory give the same bytes

Other tools read a resource with `res_formats.load('gfx/sprites/slot-00.bin')`, built from its source on the fly.
"""
import argparse
import io
import os
import re
import shutil
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')

GLYPH_PALETTE = [(24, 24, 32), (230, 230, 230), (110, 40, 40)]
SPRITE_PALETTE = [(70, 110, 120), (24, 24, 32), (230, 230, 230), (240, 190, 60), (110, 40, 40)]
COLUMNS = 16
# lines a strip -> strips of frames 0-2 (frame 3 one fewer); docs/06-rendering.md 6.6
SPRITE_STRIPS = {21: 4, 14: 4, 17: 3, 13: 2}

TUNE = 'music/title/tune.txt'
TUNE_PARTS = [('TuneSong', 'song', 'song.bin'), ('PatternInit', 'pattern', 'pattern-init.bin'),
              ('PatternA', 'pattern', 'pattern-a.bin'), ('PatternB', 'pattern', 'pattern-b.bin'),
              ('PatternC', 'pattern', 'pattern-c.bin'), ('PatternD', 'pattern', 'pattern-d.bin'),
              ('DrumPatternA', 'drums', 'drums-a.bin'), ('DrumPatternB', 'drums', 'drums-b.bin')]
TUNE_ORG = 0x843F  # tune 0: the word at $843D (docs/09-sound.md 9.2)
DRUM_NAMES = ['rest', 'loop', 'click', 'noise', 'rise', 'sweep', 'fall']


# ---------------------------------------------------------------------------------------------------------- PNG


def indexed(image, palette, name):
    """the pixels of a PNG as palette indices"""
    if image.mode == 'P' and image.getpalette()[:3 * len(palette)] == [c for rgb in palette for c in rgb]:
        return image.load(), image.size
    rgb = image.convert('RGB')
    src = rgb.load()
    out = Image.new('P', rgb.size)
    dst = out.load()
    lookup = {c: i for i, c in enumerate(palette)}
    for y in range(rgb.height):
        for x in range(rgb.width):
            if src[x, y] not in lookup:
                sys.exit(f'{name}: colour {src[x, y]} at ({x}, {y}) is not in the palette {palette}')
            dst[x, y] = lookup[src[x, y]]
    return dst, rgb.size


def new_indexed(size, palette, fill):
    image = Image.new('P', size, fill)
    image.putpalette([c for rgb in palette for c in rgb])
    return image


def glyphs_to_png(data, upright_bottom_first):
    count = len(data) // 8
    rows = (count + COLUMNS - 1) // COLUMNS
    image = new_indexed((COLUMNS * 8, rows * 8), GLYPH_PALETTE, 2)
    px = image.load()
    for g in range(count):
        for line in range(8):
            y = (g // COLUMNS) * 8 + (7 - line if upright_bottom_first else line)
            for bit in range(8):
                px[(g % COLUMNS) * 8 + bit, y] = 1 if data[g * 8 + line] & (0x80 >> bit) else 0
    return image


def png_to_glyphs(image, upright_bottom_first, name):
    px, (w, h) = indexed(image, GLYPH_PALETTE, name)
    out = bytearray()
    for g in range((w // 8) * (h // 8)):
        x0, y0 = (g % COLUMNS) * 8, (g // COLUMNS) * 8
        cell = [px[x0 + x, y0 + y] for y in range(8) for x in range(8)]
        if all(c == 2 for c in cell):
            break
        if 2 in cell:
            sys.exit(f'{name}: glyph {g} is partly "no glyph"')
        for line in range(8):
            y = y0 + (7 - line if upright_bottom_first else line)
            out.append(sum(0x80 >> bit for bit in range(8) if px[x0 + bit, y] == 1))
    return bytes(out)


def sprite_layout(length, explosion):
    """(lines, strips of each frame) of a block of this size"""
    if explosion:
        return 21, [4]
    for lines, strips in SPRITE_STRIPS.items():
        if 2 * lines * (4 * strips - 1) == length:
            return lines, [strips] * 3 + [strips - 1]
    raise SystemExit(f'no sprite block is {length} bytes')


def sprite_to_png(data, explosion):
    lines, frames = sprite_layout(len(data), explosion)
    width = max(frames) * 8
    image = new_indexed((width * len(frames), lines), SPRITE_PALETTE, 4)
    px = image.load()
    at = 0
    for f, strips in enumerate(frames):
        for s in range(strips):
            for line in range(lines):
                mask, pixels = data[at], data[at + 1]
                at += 2
                for bit in range(8):
                    m, p = mask & (0x80 >> bit), pixels & (0x80 >> bit)
                    px[f * width + s * 8 + bit, lines - 1 - line] = (2 if p else 1) if not m else (3 if p else 0)
    return image


def png_to_sprite(image, explosion, name):
    px, (w, lines) = indexed(image, SPRITE_PALETTE, name)
    frames = 1 if explosion else 4
    width = w // frames
    out = bytearray()
    for f in range(frames):
        strips = width // 8 - (f == 3)
        for x in range(f * width, (f + 1) * width):
            for y in range(lines):
                if (px[x, y] == 4) != (x >= f * width + strips * 8):
                    sys.exit(f'{name}: frame {f}: "no strip" must fill exactly its last strip (frame 3 only)')
        for s in range(strips):
            for line in range(lines):
                mask = pixels = 0
                for bit in range(8):
                    c = px[f * width + s * 8 + bit, lines - 1 - line]
                    mask |= (0x80 >> bit) if c in (0, 3) else 0
                    pixels |= (0x80 >> bit) if c in (2, 3) else 0
                out += bytes((mask, pixels))
    return bytes(out)


# --------------------------------------------------------------------------------------------------------- tune

SONG = {0xFF: ('return', 0), 0xFE: ('call', 2), 0xFD: ('jump', 2), 0xFC: ('stop', 0), 0xFB: ('drums', 2)}
PATTERN = {0: ('hold', ''), 1: ('width A', 'b'), 2: ('width B', 'b'), 3: ('envelope A', 'b'), 4: ('envelope B', 'b'),
           5: ('sustain A', ''), 6: ('decay A', ''), 7: ('sustain B', ''), 8: ('decay B', ''), 9: ('end', ''),
           10: ('note AB', 'bb'), 11: ('note A', 'b'), 12: ('note B', 'b'), 13: ('off AB', ''), 14: ('off A', ''),
           15: ('off B', ''), 16: ('drums', 'w'), 17: ('length', 'b'), 18: ('long', 'b')}


def tune_to_text(parts):
    """parts: [bytes] in TUNE_PARTS order, laid out one after the other from TUNE_ORG"""
    starts, at = [], TUNE_ORG
    for data in parts:
        starts.append(at)
        at += len(data)

    def ref(address):
        best = max((i for i, s in enumerate(starts) if s <= address), default=None)
        if best is None or address >= at:
            return '$%04X' % address
        off = address - starts[best]
        return TUNE_PARTS[best][0] + ('+%d' % off if off else '')

    out = ['; The title tune (docs/09-sound.md 9.2-9.5), assembled by tools/res_formats.py into the files of',
           '; src/res/music/title. Sections follow each other from $%04X; an address is Label or Label+offset.' %
           TUNE_ORG,
           '; song:    play N Label (N < 251) | drums Label | jump Label | call Label | return | stop',
           '; pattern: note AB pa pb | note A p | note B p | hold | long n | length n | width A|B n |',
           ';          envelope A|B n | sustain A|B | decay A|B | off AB|A|B | drums Label | end',
           '; drums:   speed n, then steps: rest loop click noise rise sweep fall',
           '; db $xx,... any bytes as they are', '']
    for (label, kind, _), data in zip(TUNE_PARTS, parts):
        out.append(f'{kind} {label}')
        p = 0
        if kind == 'drums':
            out.append(f'  speed {data[0]}')
            steps = data[1:]
            if all(b < len(DRUM_NAMES) for b in steps):
                for i in range(0, len(steps), 8):
                    out.append('  steps ' + ' '.join(DRUM_NAMES[b] for b in steps[i:i + 8]))
            else:
                out.append('  db ' + ','.join('$%02X' % b for b in steps))
            out.append('')
            continue
        while p < len(data):
            b = data[p]
            if kind == 'song':
                name, n = SONG.get(b, ('play %d' % b, 2))
            else:
                name, args = PATTERN.get(b, (None, ''))
                n = 2 if args == 'w' else len(args)
            if (kind == 'pattern' and name is None) or p + 1 + n > len(data):
                out.append('  db ' + ','.join('$%02X' % x for x in data[p:]))
                break
            if n == 2 and (kind == 'song' or args == 'w'):
                out.append(f'  {name} {ref(data[p + 1] | data[p + 2] << 8)}')
            else:
                counts = name.split()[0] in ('long', 'length', 'envelope')  # counts in decimal, periods in hex
                out.append('  ' + ' '.join([name] + [('%d' if counts else '$%02X') % x for x in data[p + 1:p + 1 + n]]))
            p += 1 + n
        out.append('')
    return '\n'.join(out)


def text_to_tune(text, name=TUNE):
    """the bytes of each part, in TUNE_PARTS order"""
    sections, current = [], None
    for number, raw in enumerate(text.splitlines(), 1):
        line = raw.split(';')[0].strip()
        if not line:
            continue
        words = line.split()
        if words[0] in ('song', 'pattern', 'drums') and len(words) == 2 and not raw.startswith(' '):
            current = (words[0], words[1], [])
            sections.append(current)
        elif current is None:
            sys.exit(f'{name}:{number}: a command before the first section')
        else:
            current[2].append((number, words))
    order = [(k, label) for label, k, _ in TUNE_PARTS]
    if [(k, label) for k, label, _ in sections] != order:
        sys.exit(f'{name}: the sections must be {", ".join(f"{k} {label}" for k, label in order)}')

    def number_of(word, where):
        try:
            return int(word[1:], 16) if word.startswith('$') else int(word)
        except ValueError:
            sys.exit(f'{where}: {word!r} is no number')

    labels = {}

    def assemble(final):
        at, parts = TUNE_ORG, []
        for kind, label, commands in sections:
            labels[label] = at
            data = bytearray()

            def address(word, where):
                m = re.fullmatch(r'([A-Za-z_]\w*)(?:\+(\d+))?', word)
                if not m:
                    return number_of(word, where)
                if m.group(1) not in labels:
                    if final:
                        sys.exit(f'{where}: unknown label {m.group(1)}')
                    return 0
                return labels[m.group(1)] + int(m.group(2) or 0)

            for number, words in commands:
                where = f'{name}:{number}'
                op, rest = words[0], words[1:]
                if op == 'db':
                    data += bytes(number_of(w, where) for w in ' '.join(rest).replace(',', ' ').split())
                elif kind == 'drums':
                    if op == 'speed':
                        data.append(number_of(rest[0], where))
                    elif op == 'steps':
                        for w in rest:
                            if w not in DRUM_NAMES:
                                sys.exit(f'{where}: unknown drum step {w!r}')
                            data.append(DRUM_NAMES.index(w))
                    else:
                        sys.exit(f'{where}: {op!r} in a drum pattern')
                elif kind == 'song':
                    if op == 'play':
                        data += bytes((number_of(rest[0], where),))
                        target = rest[1]
                    else:
                        code = next((c for c, (n, _) in SONG.items() if n == op), None)
                        if code is None:
                            sys.exit(f'{where}: unknown song command {op!r}')
                        data.append(code)
                        target = rest[0] if SONG[code][1] else None
                    if target is not None:
                        a = address(target, where)
                        data += bytes((a & 0xFF, a >> 8))
                else:
                    key = ' '.join(words[:2]) if len(words) > 1 and words[1] in ('A', 'B', 'AB') else op
                    code = next((c for c, (n, _) in PATTERN.items() if n == key), None)
                    if code is None:
                        sys.exit(f'{where}: unknown pattern command {key!r}')
                    args = PATTERN[code][1]
                    values = words[len(key.split()):]
                    if len(values) != (1 if args == 'w' else len(args)):
                        sys.exit(f'{where}: {key} takes {len(args) if args != "w" else 1} value(s)')
                    data.append(code)
                    if args == 'w':
                        a = address(values[0], where)
                        data += bytes((a & 0xFF, a >> 8))
                    else:
                        data += bytes(number_of(v, where) for v in values)
            parts.append(bytes(data))
            at += len(data)
        return parts

    assemble(False)  # the labels first
    return assemble(True)


# -------------------------------------------------------------------------------------------------- the sources


def editable(name):
    """the source of a .bin file of src/res, or None"""
    if name.startswith('music/title/') and name.endswith('.bin'):
        return TUNE
    if name in ('gfx/font.bin', 'gfx/tiles.bin') or re.fullmatch(r'gfx/(sprites|explosions)/slot-..\.bin', name):
        return name[:-4] + '.png'
    return None


def decode(source, res=RES):
    """{file: bytes} built from one source of src/res"""
    path = os.path.join(res, source)
    if source == TUNE:
        parts = text_to_tune(open(path).read(), source)
        return {'music/title/' + f: data for (_, _, f), data in zip(TUNE_PARTS, parts)}
    image = Image.open(path)
    name = source[:-4] + '.bin'
    if source in ('gfx/font.png', 'gfx/tiles.png'):
        return {name: png_to_glyphs(image, source == 'gfx/tiles.png', source)}
    return {name: png_to_sprite(image, '/explosions/' in source, source)}


def encode(files):
    """{source: bytes of the file to write} for the editable files among {name: bytes}"""
    out = {}
    tune = [files.get('music/title/' + f) for _, _, f in TUNE_PARTS]
    if any(t is not None for t in tune):
        if None in tune:
            sys.exit('export: the title tune needs all of ' + ', '.join(f for _, _, f in TUNE_PARTS))
        out[TUNE] = tune_to_text(tune).encode()
    for name, data in files.items():
        source = editable(name)
        if source is None or source == TUNE:
            continue
        if name in ('gfx/font.bin', 'gfx/tiles.bin'):
            image = glyphs_to_png(data, name == 'gfx/tiles.bin')
        else:
            image = sprite_to_png(data, '/explosions/' in name)
        buffer = io.BytesIO()
        image.save(buffer, 'PNG')
        out[source] = buffer.getvalue()
    return out


def sources(res=RES):
    found = []
    for folder, _, names in os.walk(res):
        for n in names:
            rel = os.path.relpath(os.path.join(folder, n), res).replace(os.sep, '/')
            if rel == TUNE or (rel.endswith('.png') and editable(rel[:-4] + '.bin')):
                found.append(rel)
    return sorted(found)


_cache = {}


def load(name, res=RES):
    """the bytes of a resource file of src/res, built from its source when it has one"""
    path = os.path.join(res, name)
    if os.path.exists(path):
        return open(path, 'rb').read()
    source = editable(name)
    if source is None or not os.path.exists(os.path.join(res, source)):
        raise FileNotFoundError(path)
    if source not in _cache:
        _cache[source] = decode(source, res)
    return _cache[source][name]


def build(out, res=RES):
    """every file of src/res into out, the sources converted; the sources themselves are not copied"""
    if os.path.exists(out):
        shutil.rmtree(out)
    made = 0
    for folder, _, names in os.walk(res):
        for n in names:
            rel = os.path.relpath(os.path.join(folder, n), res).replace(os.sep, '/')
            if rel in sources(res) or n == 'README.md':
                continue
            os.makedirs(os.path.dirname(os.path.join(out, rel)), exist_ok=True)
            shutil.copyfile(os.path.join(res, rel), os.path.join(out, rel))
    for source in sources(res):
        for name, data in decode(source, res).items():
            if os.path.exists(os.path.join(res, name)):
                sys.exit(f'src/res/{name} and its source {source} both exist: delete one')
            os.makedirs(os.path.dirname(os.path.join(out, name)), exist_ok=True)
            open(os.path.join(out, name), 'wb').write(data)
            made += 1
    return made


def install(files, res=RES):
    """write {name: bytes} into src/res: editable files as their sources (the .bin removed), the others as they are"""
    for source, data in encode(files).items():
        os.makedirs(os.path.dirname(os.path.join(res, source)), exist_ok=True)
        open(os.path.join(res, source), 'wb').write(data)
    for name, data in files.items():
        path = os.path.join(res, name)
        if editable(name):
            if os.path.exists(path):
                os.remove(path)
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(data)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    e = sub.add_parser('export')
    e.add_argument('--from', dest='src', default=RES)
    sub.add_parser('check')
    args = p.parse_args()
    if args.cmd == 'build':
        made = build(args.out)
        print(f'res: {made} files built from {len(sources())} sources into {os.path.relpath(args.out, ROOT)}')
    elif args.cmd == 'export':
        files = {}
        for folder, _, names in os.walk(args.src):
            for n in names:
                rel = os.path.relpath(os.path.join(folder, n), args.src).replace(os.sep, '/')
                if editable(rel):
                    files[rel] = open(os.path.join(args.src, rel), 'rb').read()
        install(files)
        print(f'res: {len(files)} files exported as {len(encode(files))} sources in src/res')
    else:
        bad = 0
        for source in sources():
            built = decode(source)
            again = encode(built)[source]
            on_disk = open(os.path.join(RES, source), 'rb').read()
            if source.endswith('.png'):
                same = decode_bytes(source, again) == built
            else:
                same = again == on_disk or text_to_tune(again.decode()) == text_to_tune(on_disk.decode())
            bad += not same
            print(f'{source}: {"round trip exact" if same else "ROUND TRIP DIFFERS"}')
        sys.exit(1 if bad else 0)


def decode_bytes(source, data):
    image = Image.open(io.BytesIO(data))
    name = source[:-4] + '.bin'
    if source in ('gfx/font.png', 'gfx/tiles.png'):
        return {name: png_to_glyphs(image, source == 'gfx/tiles.png', source)}
    return {name: png_to_sprite(image, '/explosions/' in source, source)}


if __name__ == '__main__':
    main()
