#!/usr/bin/env python3
"""The mission blocks of side 2 (src/res/missions/NN-NAME.bin, loaded at bank 0 `$DBC5`) as text, and a figure of
each world.

    python3 tools/res_missions.py text BLOCK.bin OUT.txt      # a block to its text
    python3 tools/res_missions.py bin TEXT.txt OUT.bin        # back (byte for byte)
    python3 tools/res_missions.py fig TEXT_OR_BIN OUT.png     # the world from above: segments, objects, start, pad

The block (LoadMission `$84C1` copies the header's fields into the game, frag of bank 2 `$8598` / `$85F5`):

    $DBC5      the mission number 1-10
    $DBC6      "MISSION:::" (the tape name the loader checks)
    $DBD0/1    the world's half extents X / Y in coarse units (BoundaryCheck `$D4B8`; 4 more is desertion)
    $DBD2-6    five bytes the code does not read (known only from the code)
    $DBD7      word: the object templates (30 bytes each)
    $DBD9      the object count;  $DBDA word: the object list (and the start of the part a reload restores)
    $DBDC      the segment count; $DBDD a byte; $DBDE the first switchable segment ($FF none);
    $DBDF      word: the switch object
    $DBE1      word: the goal hook, called every pass (`$6A66`); it sets `$68E8` when the goal is met
    $DBE3      8 bytes to `$7611`: the player's flags, heading, X (3 bytes), Y (3 bytes)
    $DBEB      word: the model library;  $DBED word: the end of the restored part;  $DBEF word
    $DBF1      12 bytes to `$7E82` (the Helicarrier's pad X at +7, Y at +10)
    $DBFD      a byte to `$CAAF`;  $DBFE word to `$68EB`
    $DC00      64 vertex X, $DC40 64 vertex Y (signed bytes, x 1024 world units)
    $DC80      the segments, 6 bytes: vertex a, vertex b, orientation, two sizes, the style (terrain type)
    then       the object list, 8 bytes a record (flags, type, heading, spare, X word, Y word; x 4 world units),
               `$FF` after the last
    then       the templates (object record bytes +2 to +`$1F`; as many as the list's highest type + 1), then the mission's code, data and 3D models,
               kept here as hex lines

The text keeps every byte: a field the format does not name is a hex line.
"""
import struct
import sys

ORG = 0xDBC5
HEAD_FIELDS = [  # name, address, length, kind (b byte, w word, h hex, t text)
    ('mission', 0xDBC5, 1, 'b'), ('name', 0xDBC6, 10, 't'), ('extent', 0xDBD0, 2, 'b'),
    ('unread', 0xDBD2, 5, 'h'), ('templates', 0xDBD7, 2, 'w'), ('objects', 0xDBD9, 1, 'b'),
    ('object-list', 0xDBDA, 2, 'w'), ('segments', 0xDBDC, 1, 'b'), ('dd', 0xDBDD, 1, 'b'),
    ('switch-segment', 0xDBDE, 1, 'b'), ('switch-object', 0xDBDF, 2, 'w'), ('goal-hook', 0xDBE1, 2, 'w'),
    ('player', 0xDBE3, 8, 'h'), ('models', 0xDBEB, 2, 'w'), ('restore-end', 0xDBED, 2, 'w'),
    ('ef', 0xDBEF, 2, 'w'), ('pad-params', 0xDBF1, 12, 'h'), ('cafe', 0xDBFD, 1, 'b'),
    ('time', 0xDBFE, 2, 'w')]


def s8(v):
    return v - 256 if v > 127 else v


def parse(d):
    g = lambda a: d[a - ORG]
    w = lambda a: d[a - ORG] | d[a - ORG + 1] << 8
    m = {'head': {}, 'size': len(d)}
    for name, a, n, k in HEAD_FIELDS:
        m['head'][name] = d[a - ORG:a - ORG + n]
    m['vertices'] = [(s8(g(0xDC00 + i)), s8(g(0xDC40 + i))) for i in range(64)]
    nseg = g(0xDBDC)
    m['segments'] = [tuple(d[0xDC80 - ORG + 6 * i:0xDC80 - ORG + 6 * i + 6]) for i in range(nseg)]
    a = 0xDC80 + 6 * nseg
    objs = []
    while g(a) != 0xFF:
        objs.append(tuple(d[a - ORG:a - ORG + 8]))
        a += 8
    m['objects'] = objs
    a += 1
    m['tail_at'] = a
    tm = []
    count = max((o[1] for o in objs), default=-1) + 1  # the types the list uses; later ones stay hex lines
    while len(tm) < count and a + 30 <= ORG + len(d):
        tm.append(bytes(d[a - ORG:a - ORG + 30]))
        a += 30
    m['templates'] = tm
    m['rest_at'] = a
    m['rest'] = bytes(d[a - ORG:])
    return m


def to_text(d, title=''):
    m = parse(d)
    hdr = d[:0xDC00 - ORG]
    out = ['# %s: a mission block of side 2, loaded at $DBC5 (tools/res_missions.py; src/res/missions/README.md).'
           % title,
           '# Header fields as the game reads them; vertices; segments (a b orientation size3 size4 style);',
           '# objects (flags type heading spare x y: the X and Y words); templates (record bytes +2..+$1F:',
           '# state flags colour height(2) speed wreck(2) ? box(6) ? max hp damage ? radius(2) step(2) hit(2)',
           '# model(2) score(2)); the rest (code, data, models) as hex lines at their addresses.']
    for name, a, n, k in HEAD_FIELDS:
        v = hdr[a - ORG:a - ORG + n]
        if k == 'b':
            out.append('%s %s' % (name, ' '.join(str(x) for x in v)))
        elif k == 'w':
            out.append('%s $%04X' % (name, v[0] | v[1] << 8))
        elif k == 't':
            out.append('%s "%s"' % (name, v.decode('latin-1')))
        else:
            out.append('%s %s' % (name, ' '.join('%02X' % x for x in v)))
    out.append('')
    for i, (x, y) in enumerate(m['vertices']):
        out.append('vertex %d %d %d' % (i, x, y))
    out.append('')
    for s in m['segments']:
        out.append('segment ' + ' '.join(str(x) for x in s))
    out.append('')
    for o in m['objects']:
        x, y = o[4] | o[5] << 8, o[6] | o[7] << 8
        out.append('object $%02X %d %d %d $%04X $%04X' % (o[0], o[1], o[2], o[3], x, y))
    out.append('')
    for i, t in enumerate(m['templates']):
        out.append('template %d %s' % (i, ' '.join('%02X' % x for x in t)))
    out.append('')
    r, a = m['rest'], m['rest_at']
    for i in range(0, len(r), 16):
        out.append('bytes $%04X %s' % (a + i, ' '.join('%02X' % x for x in r[i:i + 16])))
    return '\n'.join(out) + '\n'


def from_text(text):
    head = bytearray(0xDC00 - ORG)
    vx, vy = bytearray(64), bytearray(64)
    body = bytearray()
    rest = bytearray()
    fields = {f[0]: f for f in HEAD_FIELDS}
    segs, objs, tms = bytearray(), bytearray(), bytearray()
    for line in text.splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        key, _, val = line.partition(' ')
        if key in fields:
            _, a, n, k = fields[key]
            if k == 'b':
                v = bytes(int(x) for x in val.split())
            elif k == 'w':
                x = int(val.lstrip('$'), 16)
                v = bytes([x & 255, x >> 8])
            elif k == 't':
                v = val.strip()[1:-1].encode('latin-1')
            else:
                v = bytes(int(x, 16) for x in val.split())
            assert len(v) == n, 'res_missions: %s needs %d bytes' % (key, n)
            head[a - ORG:a - ORG + n] = v
        elif key == 'vertex':
            i, x, y = (int(t) for t in val.split())
            vx[i], vy[i] = x & 255, y & 255
        elif key == 'segment':
            segs += bytes(int(t) for t in val.split())
        elif key == 'object':
            f, t, h, s, x, y = val.split()
            x, y = int(x.lstrip('$'), 16), int(y.lstrip('$'), 16)
            objs += bytes([int(f.lstrip('$'), 16), int(t), int(h), int(s), x & 255, x >> 8, y & 255, y >> 8])
        elif key == 'template':
            tms += bytes(int(t, 16) for t in val.split()[1:])
        elif key == 'bytes':
            rest += bytes(int(t, 16) for t in val.split()[1:])
        else:
            raise ValueError('res_missions: cannot read %r' % line)
    return bytes(head + vx + vy + segs + objs + b'\xff' + tms + rest)


def figure(d, out_png, title=''):
    from PIL import Image, ImageDraw
    m = parse(d)
    S = 8  # pixels per coarse unit (1024 world units)
    ex, ey = m['head']['extent'][0], m['head']['extent'][1]
    W, H = (2 * ex + 10) * S, (2 * ey + 10) * S
    img = Image.new('RGB', (W, H + 18), (24, 28, 24))
    dr = ImageDraw.Draw(img)
    cx, cy = W // 2, H // 2 + 18

    def pt(x, y):
        return cx + x * S, cy - y * S
    dr.rectangle([pt(-ex, ey), pt(ex, -ey)], outline=(90, 110, 90))
    dr.rectangle([pt(-ex - 4, ey + 4), pt(ex + 4, -ey - 4)], outline=(120, 60, 60))
    styles = [(200, 200, 200), (90, 160, 230), (200, 160, 80), (120, 200, 120), (220, 90, 90), (190, 120, 220)]
    for s in m['segments']:
        a, b = s[0], s[1]
        (x1, y1), (x2, y2) = m['vertices'][a], m['vertices'][b]
        dr.line([pt(x1, y1), pt(x2, y2)], fill=styles[s[5] % len(styles)], width=3)
    for o in m['objects']:
        x = struct.unpack('<h', bytes(o[4:6]))[0] * 4 / 1024
        y = struct.unpack('<h', bytes(o[6:8]))[0] * 4 / 1024
        px, py = pt(x, y)
        c = (240, 220, 80) if o[0] & 0x80 else (150, 150, 150)
        dr.rectangle([px - 1, py - 1, px + 1, py + 1], fill=c)
    pl = m['head']['player']
    px = struct.unpack('<i', bytes(pl[2:5]) + (b'\xff' if pl[4] & 0x80 else b'\0'))[0] / 1024
    py = struct.unpack('<i', bytes(pl[5:8]) + (b'\xff' if pl[7] & 0x80 else b'\0'))[0] / 1024
    a, b = pt(px, py)
    dr.ellipse([a - 4, b - 4, a + 4, b + 4], outline=(80, 240, 240), width=2)
    pp = m['head']['pad-params']
    hx = struct.unpack('<h', bytes(pp[7:9]))[0] * 4 / 1024
    hy = struct.unpack('<h', bytes(pp[10:12]))[0] * 4 / 1024
    a, b = pt(hx, hy)
    dr.rectangle([a - 4, b - 4, a + 4, b + 4], outline=(240, 120, 240), width=2)
    dr.text((4, 3), '%s: %d segments, %d objects; cyan the start, magenta the pickup pad, red the desertion line' % (
        title, len(m['segments']), len(m['objects'])), fill=(230, 230, 230))
    img.save(out_png)


def main():
    a = sys.argv[1:]
    if a[:1] == ['text']:
        open(a[2], 'w').write(to_text(open(a[1], 'rb').read(), a[1]))
    elif a[:1] == ['bin']:
        open(a[2], 'wb').write(from_text(open(a[1]).read()))
    elif a[:1] == ['fig']:
        src = a[1]
        d = from_text(open(src).read()) if src.endswith('.txt') else open(src, 'rb').read()
        figure(d, a[2], src.split('/')[-1].split('.')[0])
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
