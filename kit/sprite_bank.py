#!/usr/bin/env python3
"""A sprite bank of "header + pixel rows" pieces reached through an offset table, as an image and a layout file: a
res format a case's tools/res_formats.py calls (export at install, build at build time, both for check).
kit/cells.py is the one for attribute cells; this is for pixel sprites with a small header of their own.

The bank: a count byte (at count_at), optionally a length word (at length_at: the offset of the bank's end, the
bytes after it are leftovers), then at table_at a table of little-endian word offsets from the bank's start, one a
number for each kind (kinds ('sprite',): a word a sprite; ('sprite', 'attrs'): a sprite's and an attribute block's
words a number, one after the other). A piece of kind `sprite`: a header of len(fields) bytes (fields name them:
`width` in bytes and `height` in lines must be among them; ATV Simulator: width, height, advance, shift), then
width x height bytes, a line at a time, bit 7 left. A piece of any other kind (`attrs`): +0 width, +1 height, then
width x height bytes.

    NAME.png   indexed: 0 paper, 1 ink, 2 no pixel; each sprite at a place of its own (rows of sheet pixels, gap
               pixels between)
    NAME.csv   a row a piece in byte order:  kind,offset,numbers,x,y,<fields but width, height>...,bytes
               the columns are kind, offset, numbers, x, y, then the fields in order (width and height among them),
               then bytes. offset: information (the build places the pieces one after another); numbers: the numbers
               whose table words point at the piece (the build makes the table and the count from them); x, y: a
               sprite's place in the PNG; the header fields; bytes: an attribute block's bytes after its two size
               bytes, in hex. `bytes` rows hold what no table word reaches (gaps before a piece; a last `bytes` row
               lies after the bank's end when the length word stops before it). A `head` row (offset $0000) keeps
               the bank's first table_at bytes only when one besides the count and the length word is not zero

The build reads only the two files.

    import sprite_bank as SB
    files = SB.export(data, **spec)      # {'.png': bytes, '.csv': bytes}
    data = SB.build(files, **spec)       # the bytes again
    spec: kinds=('sprite',), fields=('width', 'height'), count_at=0, length_at=None, table_at=1, sheet=512, gap=2

    python3 kit/sprite_bank.py export BANK.bin OUT [spec options]   # OUT.png, OUT.csv
    python3 kit/sprite_bank.py build OUT BANK.bin [spec options]    # the bytes from OUT.png, OUT.csv
    python3 kit/sprite_bank.py check BANK.bin [spec options]        # export, build: the same bytes?
    spec options: --kinds sprite[,attrs] --fields width,height[,...] --count-at N --length-at N --table-at N
                  --sheet PIXELS --gap PIXELS

ATV Simulator: `src/res/sprites/game` (kinds sprite, fields width,height,advance,shift, length at 1, table at 4)
and `menu` (kinds sprite,attrs), the build identical.
"""
import argparse
import csv
import io
import sys

from PIL import Image

PALETTE = [(24, 24, 32), (230, 230, 230), (110, 40, 40)]
NONE = 2
DEFAULTS = {'kinds': ('sprite',), 'fields': ('width', 'height'), 'count_at': 0, 'length_at': None, 'table_at': 1,
            'sheet': 512, 'gap': 2}


def _spec(spec):
    s = dict(DEFAULTS)
    for k, v in spec.items():
        if k not in DEFAULTS:
            raise TypeError(f'sprite_bank: no setting {k}')
        s[k] = v
    s['kinds'], s['fields'] = tuple(s['kinds']), tuple(s['fields'])
    if 'width' not in s['fields'] or 'height' not in s['fields']:
        raise ValueError('sprite_bank: fields must name width and height')
    return s


def _word(d, o):
    return d[o] | d[o + 1] << 8


def _h(v, n=2):
    return '$%0*X' % (n, v)


def _num(text):
    text = text.strip()
    return int(text[1:], 16) if text.startswith('$') else int(text)


def pieces(data, **spec):
    """(count, end, [(offset, kind, [numbers], length)] in byte order); end the length word's value, or len(data)"""
    s = _spec(spec)
    count, kinds = data[s['count_at']], s['kinds']
    table = {}
    for i in range(count * len(kinds)):
        off = _word(data, s['table_at'] + 2 * i)
        table.setdefault((off, kinds[i % len(kinds)]), []).append(i // len(kinds))
    out, fields = [], s['fields']
    for (off, kind), numbers in sorted(table.items()):
        if kind == 'sprite':
            w, h = data[off + fields.index('width')], data[off + fields.index('height')]
            length = len(fields) + w * h
        else:
            length = 2 + data[off] * data[off + 1]
        out.append((off, kind, numbers, length))
    end = _word(data, s['length_at']) if s['length_at'] is not None else len(data)
    return count, end, out


def _head_bytes(data, s):
    """the bank's first table_at bytes with the count and the length word zeroed"""
    head = bytearray(data[:s['table_at']])
    head[s['count_at']] = 0
    if s['length_at'] is not None:
        head[s['length_at']:s['length_at'] + 2] = b'\0\0'
    return head


def export(data, **spec):
    """{'.png': ..., '.csv': ...} of a bank's bytes"""
    s = _spec(spec)
    fields = s['fields']
    count, end, found = pieces(data, **spec)
    header = ['kind', 'offset', 'numbers', 'x', 'y'] + list(fields) + ['bytes']
    rows = []
    head = _head_bytes(data, s)
    if any(head):
        rows.append(['head', _h(0, 4), '', '', ''] + [''] * len(fields) + [bytes(data[:s['table_at']]).hex().upper()])
    o = s['table_at'] + 2 * count * len(s['kinds'])
    places, x, y, tall = [], 0, 0, 0
    blank = [''] * (len(fields) + 1)
    for off, kind, numbers, length in found:
        if off < o:
            raise ValueError(f'sprite_bank: a {kind} at {_h(off, 4)} overlaps the bytes before it (to {_h(o, 4)})')
        if off > o:
            rows.append(['bytes', _h(o, 4), '', '', ''] + blank[:-1] + [data[o:off].hex().upper()])
        ns = ' '.join(str(n) for n in numbers)
        if kind == 'sprite':
            w, h = data[off + fields.index('width')], data[off + fields.index('height')]
            if x + w * 8 > s['sheet']:
                x, y, tall = 0, y + tall + s['gap'], 0
            places.append((x, y, data[off + len(fields):off + length], w, h))
            rows.append([kind, _h(off, 4), ns, x, y] + [data[off + k] for k in range(len(fields))] + [''])
            x += w * 8 + s['gap']
            tall = max(tall, h)
        else:
            sizes = {'width': data[off], 'height': data[off + 1]}
            rows.append([kind, _h(off, 4), ns, '', ''] + [sizes.get(f, '') for f in fields] +
                        [data[off + 2:off + length].hex().upper()])
        o = off + length
    if o != end:
        raise ValueError(f'sprite_bank: the pieces end at {_h(o, 4)}, the length word says {_h(end, 4)}')
    if o < len(data):
        rows.append(['bytes', _h(o, 4), '', '', ''] + blank[:-1] + [data[o:].hex().upper()])
    image = Image.new('P', (s['sheet'], max(1, y + tall)), NONE)
    image.putpalette([c for rgb in PALETTE for c in rgb])
    px = image.load()
    for x0, y0, bs, w, h in places:
        for j in range(h):
            for i in range(w):
                b = bs[j * w + i]
                for bit in range(8):
                    px[x0 + i * 8 + bit, y0 + j] = (b >> (7 - bit)) & 1
    f = io.BytesIO()
    image.save(f, 'PNG')
    text = io.StringIO()
    writer = csv.writer(text, lineterminator='\n')
    writer.writerow(header)
    writer.writerows(rows)
    return {'.png': f.getvalue(), '.csv': text.getvalue().encode('utf-8')}


def build(files, name='bank', **spec):
    """the bank's bytes from {'.png': ..., '.csv': ...}"""
    s = _spec(spec)
    fields, kinds = s['fields'], s['kinds']
    px = Image.open(io.BytesIO(files['.png'])).load()
    rows = list(csv.DictReader(io.StringIO(files['.csv'].decode('utf-8'))))
    head_row = [r for r in rows if r['kind'] == 'head']
    rows = [r for r in rows if r['kind'] != 'head']
    numbers = [int(n) for r in rows if r['numbers'] for n in r['numbers'].split()]
    if not numbers:
        raise SystemExit(f'{name}.csv: no piece has a number')
    count = max(numbers) + 1
    first = s['table_at'] + 2 * count * len(kinds)
    body, table, end = bytearray(), {}, None
    for i, r in enumerate(rows):
        off = first + len(body)
        if r['kind'] == 'bytes':
            if i == len(rows) - 1 and s['length_at'] is not None:  # after the bank's end: the length word stops
                end = off
            body += bytes.fromhex(r['bytes'])
            continue
        w, h = _num(r['width']), _num(r['height'])
        if r['kind'] == 'sprite':
            x0, y0 = _num(r['x']), _num(r['y'])
            body += bytes(_num(r[f]) for f in fields)
            for j in range(h):
                for c in range(w):
                    b = 0
                    for bit in range(8):
                        v = px[x0 + c * 8 + bit, y0 + j]
                        if v == NONE:
                            raise SystemExit(f'{name}.png: a pixel of index {NONE} (no pixel) at '
                                             f'({x0 + c * 8 + bit}, {y0 + j}) inside the sprite at {r["offset"]}')
                        b = b << 1 | (v == 1)
                    body.append(b)
        else:
            body += bytes([w, h]) + bytes.fromhex(r['bytes'])
        for n in r['numbers'].split():
            table[(int(n), r['kind'])] = off
    if end is None:
        end = first + len(body)
    head = bytearray(bytes.fromhex(head_row[0]['bytes'])) if head_row else bytearray(s['table_at'])
    head[s['count_at']] = count
    if s['length_at'] is not None:
        head[s['length_at']:s['length_at'] + 2] = bytes([end & 255, end >> 8])
    for n in range(count):
        for k in kinds:
            if (n, k) not in table:
                raise SystemExit(f'{name}.csv: no {k} row has number {n}')
            head += bytes([table[(n, k)] & 255, table[(n, k)] >> 8])
    return bytes(head + body)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('command', choices=['export', 'build', 'check'])
    ap.add_argument('paths', nargs='+')
    ap.add_argument('--kinds', default='sprite')
    ap.add_argument('--fields', default='width,height')
    ap.add_argument('--count-at', type=int, default=0)
    ap.add_argument('--length-at', type=int)
    ap.add_argument('--table-at', type=int, default=1)
    ap.add_argument('--sheet', type=int, default=512)
    ap.add_argument('--gap', type=int, default=2)
    a = ap.parse_args()
    spec = dict(kinds=a.kinds.split(','), fields=a.fields.split(','), count_at=a.count_at, length_at=a.length_at,
                table_at=a.table_at, sheet=a.sheet, gap=a.gap)
    if a.command == 'export':
        if len(a.paths) != 2:
            sys.exit('export BANK.bin OUT')
        files = export(open(a.paths[0], 'rb').read(), **spec)
        for ext, b in files.items():
            open(a.paths[1] + ext, 'wb').write(b)
        count, end, found = pieces(open(a.paths[0], 'rb').read(), **spec)
        print(f'{a.paths[1]}.png, .csv: {count} numbers, {len(found)} pieces, end {_h(end, 4)}')
        return 0
    if a.command == 'build':
        if len(a.paths) != 2:
            sys.exit('build OUT BANK.bin')
        files = {ext: open(a.paths[0] + ext, 'rb').read() for ext in ('.png', '.csv')}
        open(a.paths[1], 'wb').write(build(files, a.paths[0], **spec))
        return 0
    data = open(a.paths[0], 'rb').read()
    again = build(export(data, **spec), a.paths[0], **spec)
    print(f'{a.paths[0]}: ' + ('the same bytes' if again == data else f'differs ({len(data)} bytes, built {len(again)})'))
    return 0 if again == data else 1


if __name__ == '__main__':
    sys.exit(main())
