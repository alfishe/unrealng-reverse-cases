#!/usr/bin/env python3
"""Doc 1's figures from src/res: the sixteen objects as the player sees them, the unused test cave in the leftovers,
and the table of the 32 caves (parameters and object counts).

    python3 tools/fig_design.py --out docs/img/design [--table work/docs/esA/caves-table.md]
    python3 tools/fig_design.py --sheet OUT.png --title TEXT [--note TEXT] SHOT.png=LABEL ...   # a labelled row of
        screenshots (kit/screen_shot.py PNGs of a recording)

The objects are drawn with cave 1's set-up (CaveSetup `$9313`: its earth and wall graphics and its colours). The test
cave is the 314-byte record at `$F9A6` inside src/res/leftovers/tunes-pad.bin (`$F49E-$FADF`): 300 bytes of cells,
two a byte (the left cell in the low nibble), then the 14 parameter bytes, the format of CaveData `$C000`; no table
points at it, it is drawn with its own parameters.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import fig_caves as FC  # noqa: E402
import res_formats  # noqa: E402
import kitlib as K  # noqa: E402

OBJECTS = [  # code, char, name, what it does (the rules of doc 10)
    (0, '.', 'empty', 'objects fall and roll into it'),
    (1, 'X', 'exit', 'opens when enough gems are taken'),
    (2, '0', 'boulder', 'falls, rolls, pushed; kills'),
    (3, 'R', 'player (right)', 'the start: one 3 or 4 a cave'),
    (4, 'L', 'player (left)', 'the same, facing left'),
    (5, '#', 'wall', 'blocks; its look per cave'),
    (6, ':', 'earth', 'dug away; falls in 5 caves'),
    (7, '*', 'gem', 'falls, rolls; taken for points'),
    (8, 'T', 'jelly bean', 'refills the time bar'),
    (9, 'Z', 'force field', 'holds the player 12 ticks'),
    (10, 'A', 'anti-gravity', 'objects rise for a while'),
    (11, 'S', 'switch box', 'hit from above: fields go'),
    (12, '+', 'potion', 'an extra life (up to 9)'),
    (13, 'D', 'teleporter', 'to the next teleporter'),
    (14, 'O', 'bubble', 'pushed; bursts in fire'),
    (15, 'F', 'fire', 'falls; walking in kills'),
]
TEST_CAVE = 0xF9A6
TUNES_PAD = 0xF49E


def params_of(b):
    return dict(gems_needed=b[0], gem_value=b[1], start=b[2] | b[3] << 8, gems_digits=(b[4], b[5]),
                earth_graphic=b[6] | b[7] << 8, wall_graphic=b[8] | b[9] << 8, door_colour=b[10],
                boulder_colour=b[11], wall1_colour=b[12], earth_colour=b[13])


def cells_of(packed):
    out = []
    for byte in packed:
        out += [byte & 0x0F, byte >> 4]
    return out


def sheet(out, title, note, shots, width=1050):
    ims = [(Image.open(p.partition('=')[0]).convert('RGB'), p.partition('=')[2]) for p in shots]
    n = len(ims)
    w = (width - 10 * (n + 1)) // n
    h = w * 3 // 4
    fb, fs = K.font(15), K.font(12)
    img = Image.new('RGB', (width, 40 + h + 30 + (22 if note else 0)), (22, 22, 28))
    d = ImageDraw.Draw(img)
    d.text((10, 10), title, fill=(235, 235, 235), font=fb)
    for i, (im, label) in enumerate(ims):
        x = 10 + i * (w + 10)
        img.paste(im.resize((w, h), Image.NEAREST), (x, 36))
        d.text((x, 40 + h), label, fill=(210, 210, 210), font=fs)
    if note:
        d.text((10, 40 + h + 24), note, fill=(150, 150, 150), font=K.font(11))
    img.save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out')
    ap.add_argument('--table')
    ap.add_argument('--sheet')
    ap.add_argument('--title', default='')
    ap.add_argument('--note', default='')
    ap.add_argument('shots', nargs='*')
    a = ap.parse_args()
    if a.sheet:
        sheet(a.sheet, a.title, a.note, a.shots)
        return
    os.makedirs(a.out, exist_ok=True)
    base = FC.resource_memory()
    caves = res_formats.read_caves()
    m = FC.cave_setup(base, caves[0][0])
    fb, f, fs = K.font(15), K.font(13), K.font(11)
    # the objects
    cols, cw, ch = 4, 262, 92
    img = Image.new('RGB', (cols * cw, 54 + 4 * ch + 40), (22, 22, 28))
    d = ImageDraw.Draw(img)
    d.text((10, 10), 'The sixteen cell codes of a cave as the player sees them (cave 1\'s colours and graphics)',
           fill=(235, 235, 235), font=fb)
    d.text((10, 30), 'code, the character of src/res/caves/caves.txt, the name, the rule in short (doc 10 has the '
           'code)', fill=(180, 180, 180), font=fs)
    for i, (code, char, name, rule) in enumerate(OBJECTS):
        x, y = (i % cols) * cw + 10, 54 + (i // cols) * ch
        g, addr = FC.graphic(m, code)
        if g:
            img.paste(g.resize((64, 64), Image.NEAREST), (x, y))
        d.rectangle([x - 1, y - 1, x + 64, y + 64], outline=(70, 70, 80))
        d.text((x + 72, y + 2), '%d  \'%s\'  %s' % (code, char, name), fill=(240, 240, 240), font=f)
        import textwrap
        for k, part in enumerate(textwrap.wrap(rule, 22)[:2]):
            d.text((x + 72, y + 22 + 15 * k), part, fill=(200, 200, 200), font=fs)
        d.text((x + 72, y + 54), 'graphic $%04X' % addr if addr else 'no graphic', fill=(150, 150, 150), font=fs)
    d.text((10, 54 + 4 * ch + 10), 'Command: python3 tools/fig_design.py --out docs/img/design (from src/res/caves '
           'and src/res/graphics)', fill=(150, 150, 150), font=fs)
    img.save(os.path.join(a.out, 'objects.png'))
    # the test cave
    pad = open(os.path.join(res_formats.RES, 'leftovers', 'tunes-pad.bin'), 'rb').read()
    rec = pad[TEST_CAVE - TUNES_PAD:TEST_CAVE - TUNES_PAD + 314]
    p = params_of(rec[300:])
    cells = cells_of(rec[:300])
    cave = FC.draw_cave(FC.cave_setup(base, p), cells)
    out = Image.new('RGB', (960 + 20, 640 + 110), (22, 22, 28))
    d = ImageDraw.Draw(out)
    d.text((10, 10), 'The unused test cave at $F9A6: one of each object along the top row', fill=(235, 235, 235),
           font=fb)
    d.text((10, 32), 'gems_needed %d, gem_value %d, start %d (row %d, column %d), digits %d %d, earth $%04X, wall $%04X, '
           'colours $%02X $%02X $%02X $%02X' % (p['gems_needed'], p['gem_value'], p['start'], p['start'] // 30,
                                                p['start'] % 30, p['gems_digits'][0], p['gems_digits'][1],
                                                p['earth_graphic'], p['wall_graphic'], p['door_colour'],
                                                p['boulder_colour'], p['wall1_colour'], p['earth_colour']),
           fill=(200, 200, 200), font=fs)
    out.paste(cave.resize((960, 640), Image.NEAREST), (10, 56))
    d.text((10, 56 + 646), '2x, from src/res/leftovers/tunes-pad.bin offset %d (314 bytes, CaveData format); no player cell. '
           'tools/fig_design.py' % (TEST_CAVE - TUNES_PAD),
           fill=(150, 150, 150), font=fs)
    out.save(os.path.join(a.out, 'test-cave.png'))
    row0 = ''.join(OBJECTS[v][1] for v in cells[:30])
    print('test cave', p, 'row 0:', row0)
    counts_t = {}
    for v in cells:
        counts_t[v] = counts_t.get(v, 0) + 1
    print('test cave counts', {OBJECTS[k][2]: v for k, v in sorted(counts_t.items())})
    # the table of caves
    names = [res_formats.unquote(ln.strip()).decode('latin-1').strip()
             for ln in open(os.path.join(res_formats.RES, 'texts', 'cave-names.txt'), encoding='utf-8')
             if ln.startswith('"')]
    try:
        sym = {v: k for k, v in res_formats.symbols()[1].items()}
    except Exception:  # noqa: BLE001
        sym = {}
    lines = ['| Cave | Name (the password) | Gems needed / there | Points a gem | Start (row, column) | Earth | Wall | '
             'Specials |', '| --- | --- | --- | --- | --- | --- | --- | --- |']
    for n, (pp, cc) in enumerate(caves, 1):
        cnt = {}
        for v in cc:
            cnt[v] = cnt.get(v, 0) + 1
        spec = ', '.join('%s %d' % (OBJECTS[k][2], cnt[k]) for k in range(8, 16) if cnt.get(k))
        eg = sym.get(pp['earth_graphic'], '$%04X' % pp['earth_graphic'])
        wg = sym.get(pp['wall_graphic'], '$%04X' % pp['wall_graphic'])
        lines.append('| %d | %s | %d / %d | %d | %d (%d, %d) | %s | %s | %s |' % (
            n, names[n - 1], pp['gems_needed'], cnt.get(7, 0), pp['gem_value'], pp['start'], pp['start'] // 30,
            pp['start'] % 30, eg, wg, spec or 'none'))
    text = '\n'.join(lines) + '\n'
    if a.table:
        open(a.table, 'w').write(text)
    print(text)


if __name__ == '__main__':
    main()
