#!/usr/bin/env python3
"""Doc 7's figures of the level blocks, drawn from build/levelN.bin and build/levelN.lst (tools/wavescript.py's
decode) and the map resources (tools/levelmap.py):

    python3 tools/fig_level.py blocks OUT.png        the 8 level bodies at $C4AE: what lies where
    python3 tools/fig_level.py formats OUT.png       the header, a wave entry, a kind record and a script step of
                                                     level 1, byte by byte (a data sheet)
    python3 tools/fig_level.py waves OUT.png         the 8 wave scripts on one axis: each entry at its map column
    python3 tools/fig_level.py strip N OUT.png       level N's map with every wave entry drawn where its enemy appears
    python3 tools/fig_level.py paths N OUT.png       level N's kinds: each kind's script walked from its start

Coordinates. MapColumn is the next block column the scroll feeds (a block column is 4 cells, 32 pixels); the screen's
left edge is 8 block columns behind it (l1: MapColumn 14 at the first pass, the start column 6 at the left edge). A
wave entry fires when MapColumn, the cell column inside the block (MetaColumn) and ScrollStep equal its first two
bytes; its enemy appears at screen cell (x, y) = the entry's word. On the map that is cell (column - 8) x 4 + meta + x.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wavescript  # noqa: E402

ORG = 0xC4AE
COLOURS = {'header': (120, 120, 120), 'spare': (205, 205, 205), 'sprites': (90, 150, 220), 'objects': (40, 90, 190), 'metatiles': (110, 190, 110),
           'map': (40, 140, 60), 'waves': (220, 120, 40), 'records': (200, 70, 70), 'kinds': (150, 40, 40),
           'scripts': (190, 90, 190), 'movers': (230, 200, 60), 'code': (60, 60, 60)}


def font(size):
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def label(labels, suffix, n):
    for a, name in labels.items():
        if name == f'L{n}{suffix}':
            return a
    raise SystemExit(f'no L{n}{suffix}')


def regions(n):
    d = wavescript.decode(n)
    lb = d['labels']
    h = d['header']
    first_record = min(k['record'] for k in d['kinds'])
    first_mover = min(a for a in d['movers_a'] + d['movers_b'])
    script_end = label(lb, 'MoversA', n)
    return d, [('header', ORG, 0xC4C4), ('spare', 0xC4C4, 0xC4E0), ('sprites', 0xC4E0, h['objects']),
               ('objects', h['objects'], label(lb, 'Metatiles', n)), ('metatiles', label(lb, 'Metatiles', n), h['map']),
               ('map', h['map'], h['waves'][0]), ('waves', h['waves'][0], first_record),
               ('records', first_record, h['kinds']), ('kinds', h['kinds'], h['kinds'] + 2 * len(d['kinds'])),
               ('scripts', h['kinds'] + 2 * len(d['kinds']), script_end), ('movers', script_end, first_mover),
               ('code', first_mover, d['end'])]


def cmd_blocks(out):
    W, top, rowh = 1050, 92, 74
    im = Image.new('RGB', (W, top + 8 * rowh + 88), 'white')
    dr = ImageDraw.Draw(im)
    f17, f14, f13 = font(17), font(14), font(13)
    dr.text((10, 8), 'The 8 level bodies: each loads at $C4AE and brings its own sprites, map, wave script, kinds and '
                     'mover code', fill='black', font=f17)
    dr.text((10, 32), 'tools/fig_level.py blocks, from build/levelN.bin and the labels of build/levelN.lst; x: the address '
                      '$C4AE-$F871 (the level space LoadLevel $FE03 fills); a box per part', fill=(60, 60, 60),
            font=f13)
    x0, x1 = 70, W - 100
    lo, hi = ORG, 0xF872

    def X(a):
        return x0 + (a - lo) * (x1 - x0) / (hi - lo)
    for a in range(0xC800, hi, 0x0800):
        dr.line([X(a), top - 6, X(a), top + 8 * rowh - 20], fill=(225, 225, 225))
        dr.text((X(a) - 18, top - 24), f'${a:04X}', fill=(110, 110, 110), font=f13)
    for n in range(1, 9):
        d, regs = regions(n)
        y = top + (n - 1) * rowh
        dr.text((10, y + 10), f'level {n}', fill='black', font=f14)
        for name, a, b in regs:
            if b <= a:
                continue
            dr.rectangle([X(a), y, X(b) - 1, y + 34], fill=COLOURS[name])
            if X(b) - X(a) > 46:
                dr.text((X(a) + 3, y + 37), f'${a:04X}', fill=(70, 70, 70), font=f13)
        dr.text((X(d['end']) + 4, y + 10), f'end ${d["end"] - 1:04X}', fill='black', font=f13)
    ly = top + 8 * rowh - 6
    x = 10
    for name, c in COLOURS.items():
        dr.rectangle([x, ly, x + 14, ly + 14], fill=c)
        dr.text((x + 18, ly - 1), name, fill='black', font=f13)
        x += 26 + int(dr.textlength(name, font=f13)) + 6
    dr.text((10, ly + 24), 'header $C4AE-$C4C3 (22 bytes); spare $C4C4-$C4DF (zeros; the levels\' LevelVars are $7DF9 in the game\'s '
                           'variables); SoundStack $F872 follows the space;', fill=(60, 60, 60), font=f13)
    dr.text((10, ly + 42), 'records: the kind records, between the wave script\'s end and the kind table; movers: the two tables '
                           'of 16 words; code: the level\'s own', fill=(60, 60, 60), font=f13)
    dr.text((10, ly + 60), 'movers and helpers. Levels 5 and 6 are about 4 KB shorter (less sprite data).',
            fill=(60, 60, 60), font=f13)
    im.save(out)
    print(out, im.size)


def boxes(dr, x, y, cells, f13, f14, w=58):
    """cells: [(top text, bottom text, colour)] drawn as byte boxes from x; returns the x after them"""
    for top, bottom, c in cells:
        dr.rectangle([x, y, x + w - 2, y + 30], fill=c, outline=(80, 80, 80))
        dr.text((x + 6, y + 7), top, fill='black', font=f14)
        if bottom:
            dr.text((x + 2, y + 34), bottom, fill=(60, 60, 60), font=f13)
        x += w
    return x


def cmd_formats(out):
    d = wavescript.decode(1)
    mem, _, _ = wavescript.load(1)
    W = 1050
    im = Image.new('RGB', (W, 900), 'white')
    dr = ImageDraw.Draw(im)
    f17, f14, f13 = font(17), font(14), font(13)
    dr.text((10, 8), 'Level 1\'s records byte by byte: the header, a wave entry, a command entry, a kind record, a '
                     'script step', fill='black', font=f17)
    dr.text((10, 32), 'tools/fig_level.py formats, from build/level1.bin (the bytes as loaded at $C4AE); every box is one '
                      'byte, its value inside, its meaning under it', fill=(60, 60, 60), font=f13)
    y = 70
    pale = {'grey': (225, 225, 225), 'blue': (200, 220, 250), 'green': (205, 235, 205), 'orange': (250, 225, 190),
            'red': (245, 205, 205), 'violet': (230, 210, 240), 'yellow': (250, 240, 190)}
    # the header
    dr.text((10, y), 'The header, $C4AE-$C4C3 (then 28 spare zeros to $C4DF)', fill='black', font=f14)
    y += 24
    hb = mem[ORG:ORG + 22]
    cells = [(f'{hb[0]:02X}', '+0', pale['grey']), (f'{hb[1]:02X}', '+1', pale['grey']), (f'{hb[2]:02X}', '+2', pale['grey'])]
    cells += [(f'{hb[3 + k]:02X}', f'+{3 + k}', pale['yellow']) for k in range(3)]
    cells += [(f'{hb[6 + k]:02X}', f'+{6 + k}', pale['orange']) for k in range(6)]
    cells += [(f'{hb[12 + k]:02X}', f'+{12 + k}', pale['blue'] if k < 4 else pale['red'] if k < 6 else pale['violet'])
              for k in range(10)]
    x = boxes(dr, 10, y, cells[:11], f13, f14, w=46)
    boxes(dr, 10, y + 74, cells[11:], f13, f14, w=46)
    notes = ['+0 restart column, +1/+2 restart wave: zero on tape, set by RestartPoint and CheckRestart',
             '+3, +4, +5: checkpoint columns 6, 37, 75 (the first is the start column; $FF = none)',
             '+6..+11: their wave entries $E788 (the script\'s start), $E8AF, $EA44',
             '+12 objects $D7F9, +14 map $E571 (the metatiles below it), +16 kinds $EFFB,',
             '+18 movers A $F365, +20 movers B $F385']
    for k, t in enumerate(notes):
        dr.text((10, y + 140 + k * 20), t, fill='black', font=f13)
    y += 250
    # a wave entry
    w = d['waves'][1]
    a = w['address']
    dr.text((10, y), f'A wave entry: 5 bytes (entry 1 at ${a:04X}: kind 1 at screen column 31, row 4 when the scroll '
                     f'reaches block column 16, cell 0, step 0)', fill='black', font=f14)
    y += 24
    b = mem[a:a + 5]
    boxes(dr, 10, y, [(f'{b[0]:02X}', 'column', pale['yellow']), (f'{b[1]:02X}', 'sub', pale['yellow']),
                      (f'{b[2]:02X}', 'kind', pale['red']), (f'{b[3]:02X}', 'x', pale['blue']),
                      (f'{b[4]:02X}', 'y', pale['blue'])], f13, f14)
    for k, t in enumerate(['column: the block column MapColumn must equal ($FF ends the script)',
                           'sub: bits 3-4 the cell column in the block (MetaColumn), bits 0-2 ScrollStep',
                           'kind: 1-62 an index into the kind table (kind - 1) x 2; $63 a command',
                           'x, y: the enemy\'s screen cell (column 0-31, row 0-19)']):
        dr.text((330, y - 2 + k * 20), t, fill='black', font=f13)
    y += 96
    c = next(e for e in d['waves'] if e.get('command') == 1)
    a = c['address']
    b = mem[a:a + 5]
    dr.text((10, y), f'A command entry: kind $63 (entry at ${a:04X}: command 1, halt the scroll for the boss, at block '
                     f'column {b[0]})', fill='black', font=f14)
    y += 24
    boxes(dr, 10, y, [(f'{b[0]:02X}', 'column', pale['yellow']), (f'{b[1]:02X}', 'sub', pale['yellow']),
                      (f'{b[2]:02X}', '$63', pale['grey']), (f'{b[3]:02X}', 'command', pale['orange']),
                      (f'{b[4]:02X}', 'argument', pale['orange'])], f13, f14, w=62)
    for k, t in enumerate(['1 halt the scroll (the boss), 2 resume it, 3 the next wave\'s slot = argument,',
                           '4 the shooter limit = argument, 5 the level\'s end (LevelEndTimer $41),',
                           '6 play sound = argument (channel bits $83)']):
        dr.text((330, y - 2 + k * 20), t, fill='black', font=f13)
    y += 96
    k1 = d['kinds'][0]
    a = k1['record']
    b = mem[a:a + 13]
    dr.text((10, y), f'A kind record: kind 1 at ${a:04X} (the kind table $EFFB, word 0), 3 bytes then the script list',
            fill='black', font=f14)
    y += 24
    boxes(dr, 10, y, [(f'{b[0]:02X}', 'movers', pale['violet']), (f'{b[1]:02X}', 'flags', pale['red']),
                      (f'{b[2]:02X}', 'score', pale['green'])] +
          [(f'{b[3 + i]:02X}', ('script' if i % 2 == 0 else '') if i < 8 else ('end' if i == 8 else ''),
            pale['blue'] if i < 8 else pale['grey']) for i in range(10)], f13, f14, w=50)
    for k, t in enumerate(['movers: low nibble mover A (before the draw), high nibble mover B (after it)',
                           'flags: bits 0-5 hits ($3F indestructible), bit 6 fires, bit 7 a shot out',
                           'score: high nibble explosion size, low nibble award (1-10 x 100 points)',
                           'then script addresses (words); a word $00xx frees the slot, $FFxx starts the list again',
                           '$41 = 1 hit, fires; $12 = size 1, award 2 (200 points); scripts $F057 x 4, then $0000']):
        dr.text((10, y + 58 + k * 20), t, fill='black', font=f13)
    y += 166
    s = k1['scripts'][0]
    b = mem[s:s + 16]
    dr.text((10, y), f'A script: ${s:04X}, 2 bytes a step (object, move); bit 7 of the move ends the script',
            fill='black', font=f14)
    y += 24
    cells = []
    for i in range(0, 16, 2):
        cells.append((f'{b[i]:02X}', 'object', pale['blue']))
        cells.append((f'{b[i + 1]:02X}', 'move', pale['orange'] if b[i + 1] < 0x80 else pale['red']))
        if b[i + 1] & 0x80:
            break
    boxes(dr, 10, y, cells, f13, f14, w=50)
    dr.text((10, y + 58), 'move: bits 0-1 the drawer (0 as stored, 1 mirrored, 2 upside down, 3 both), bit 2 up, bit 3 '
                          'down, bit 4 left, bit 5 right, bit 7 the last step', fill='black', font=f13)
    steps = wavescript.script(mem, s)
    txt = ', '.join(f'object {st["object"]}' + (' ' + '+'.join(st['dirs']) if st['dirs'] else ' still') for st in steps)
    dr.text((10, y + 78), f'${s:04X} reads: {txt}', fill='black', font=f13)
    y += 110
    im = im.crop((0, 0, W, y))
    im.save(out)
    print(out, im.size)


def cmd_waves(out):
    W, top, rowh = 1050, 80, 92
    im = Image.new('RGB', (W, top + 8 * rowh + 92), 'white')
    dr = ImageDraw.Draw(im)
    f17, f14, f13 = font(17), font(14), font(13)
    dr.text((10, 8), 'The 8 wave scripts on one axis: what starts at which map column, and where the scroll halts '
                     'and the level ends', fill='black', font=f17)
    dr.text((10, 32), 'tools/fig_level.py waves, from tools/wavescript.py\'s decode; x: the block column (MapColumn), '
                      'a tick per wave entry, its height the enemy\'s screen row', fill=(60, 60, 60), font=f13)
    x0, x1 = 70, W - 20
    cmax = 130

    def X(p):
        return x0 + p * (x1 - x0) / (cmax * 4)
    for c in range(0, cmax + 1, 10):
        dr.line([X(c * 4), top - 4, X(c * 4), top + 8 * rowh - 16], fill=(230, 230, 230))
        dr.text((X(c * 4) - 8, top - 22), str(c), fill=(110, 110, 110), font=f13)
    cmd_col = {1: (200, 0, 0), 2: (0, 150, 0), 3: (120, 120, 120), 4: (120, 120, 120), 5: (0, 0, 0), 6: (190, 0, 190)}
    for n in range(1, 9):
        d = wavescript.decode(n)
        y = top + (n - 1) * rowh
        dr.text((10, y + 24), f'level {n}', fill='black', font=f14)
        dr.line([x0, y + 62, x1, y + 62], fill=(180, 180, 180))
        h = d['header']
        for c in h['checks']:
            if c != 255:
                dr.polygon([(X(c * 4), y + 64), (X(c * 4) - 5, y + 74), (X(c * 4) + 5, y + 74)], fill=(40, 90, 190))
        for e in d['waves']:
            p = e['column'] * 4 + e['meta'] + e['step'] / 8
            if 'command' in e:
                cc = cmd_col.get(e['command'], (0, 0, 0))
                if e['command'] in (1, 2, 5, 6):
                    dr.line([X(p), y + (2 if e['command'] in (1, 5) else 40), X(p), y + 62], fill=cc, width=2)
                    if e['command'] in (1, 5):
                        dr.text((X(p) + 2, y), {1: 'halt', 5: 'end'}[e['command']], fill=cc, font=f13)
                continue
            yy = y + 62 - (min(e['hi'], 20) * 2.6)
            dr.line([X(p), y + 62, X(p), yy], fill=(220, 120, 40))
            dr.ellipse([X(p) - 1.5, yy - 1.5, X(p) + 1.5, yy + 1.5], fill=(150, 60, 0))
    ly = top + 8 * rowh - 6
    items = [((150, 60, 0), 'an enemy wave (height: its row, top = row 20)'), ((200, 0, 0), 'halt: the scroll stops (boss)'),
             ((0, 150, 0), 'resume (short line)'), ((0, 0, 0), 'end: the level ends'), ((190, 0, 190), 'a sound (short line)'),
             ((40, 90, 190), 'checkpoint (restart column)')]
    x = 10
    for c, t in items:
        dr.rectangle([x, ly, x + 14, ly + 14], fill=c)
        dr.text((x + 18, ly - 1), t, fill='black', font=f13)
        x += 30 + int(dr.textlength(t, font=f13))
        if x > 800:
            x, ly = 10, ly + 22
    dr.text((10, ly + 26), 'Level 1 has a second halt (116) for its second boss part; level 8 three ends (56, 66, 82): '
                           'the first turns the digit 8 to 9 and play goes on, the second loads level 1 (doc 10).', fill=(60, 60, 60),
            font=f13)
    dr.text((10, ly + 46), 'Levels 3 and 8 have no checkpoint.', fill=(60, 60, 60), font=f13)
    im.save(out)
    print(out, im.size)


KIND_COLOURS = [(230, 25, 75), (60, 180, 75), (255, 225, 25), (0, 130, 200), (245, 130, 48), (145, 30, 180),
                (70, 240, 240), (240, 50, 230), (210, 245, 60), (250, 190, 212), (0, 128, 128), (220, 190, 255),
                (170, 110, 40), (255, 250, 200), (128, 0, 0), (170, 255, 195)]


def cmd_strip(n, out):
    import levelmap
    lv = levelmap.levels()[n]
    s = levelmap.strip(lv)
    d = wavescript.decode(n)

    per = 32
    drawn = max(c for c in range(lv.columns) if any(lv.cell(c, r) for r in range(5))) + 1
    halts = [e['column'] for e in d['waves'] if e.get('command') == 1]
    drawn = min(lv.columns, max([drawn] + halts[:1]))     # up to the halted screen's right edge
    nrows = (drawn + per - 1) // per
    rh = 160 + 40
    W = 1050
    im = Image.new('RGB', (W, 76 + nrows * rh + 50), 'white')
    dr = ImageDraw.Draw(im)
    f17, f13 = font(17), font(13)
    dr.text((10, 8), f'Level {n} as its wave script places it: each enemy where it appears on the map', fill='black',
            font=f17)
    dr.text((10, 32), f'tools/fig_level.py strip {n}: the map from src/res/levels/level{n} (tools/levelmap.py), a circle '
                      'per wave entry at map cell (column - 8) x 4 + meta + x, row y; its number the kind;',
            fill=(60, 60, 60), font=f13)
    dr.text((10, 50), 'red line: the scroll halts (the boss); squares: waves started while halted, on the halted screen; '
                      'blue triangles: checkpoints.', fill=(60, 60, 60), font=f13)
    ox = 12
    for i in range(nrows):
        c0, c1 = i * per, min(drawn, (i + 1) * per)
        y = 76 + i * rh
        dr.text((ox, y), f'block columns {c0}-{c1 - 1}', fill='black', font=f13)
        im.paste(s.crop((c0 * 32, 0, c1 * 32, 160)), (ox, y + 18))
    pts = []
    halt = None     # while the scroll is halted MapColumn still counts, the screen stays: place on the halted screen
    for e in d['waves']:
        if 'command' in e:
            if e['command'] == 1 and halt is None:
                halt = (e['column'] - 8) * 4 + e['meta']
                pts.append(('cmd', halt + 32, 1))
            elif e['command'] == 2:
                halt = None
            continue
        left = halt if halt is not None else (e['column'] - 8) * 4 + e['meta']
        pts.append(('halted' if halt is not None else 'kind', left + e['lo'], e))
    for c in d['header']['checks']:
        if c != 255:
            pts.append(('check', c * 4, None))
    for what, cell, e in pts:
        blk = cell // 4
        row = blk // per
        if row >= nrows or cell < 0:
            continue
        x = ox + (cell - row * per * 4) * 8
        y = 76 + row * rh + 18
        if what == 'cmd':
            dr.line([x, y - 4, x, y + 162], fill=(220, 0, 0) if e == 1 else (0, 0, 0), width=3)
        elif what == 'check':
            dr.polygon([(x, y + 160), (x - 7, y + 174), (x + 7, y + 174)], fill=(40, 90, 230))
        else:
            yy = y + e['hi'] * 8 + 4
            k = e['kind']
            c = KIND_COLOURS[k % len(KIND_COLOURS)]
            if what == 'halted':
                dr.rectangle([x - 6, yy - 6, x + 6, yy + 6], fill=c, outline='white')
            else:
                dr.ellipse([x - 6, yy - 6, x + 6, yy + 6], fill=c, outline='black')
            dr.text((x + 7, yy - 8), str(k), fill='white', font=f13, stroke_width=2, stroke_fill='black')
    im.save(out)
    print(out, im.size)


def walk(mem, kind, start_x=26, start_y=8, limit=160):
    """the cells a kind's scripts visit from (start_x, start_y), one step a move, the script list once"""
    pts = [(start_x, start_y)]
    x, y = start_x, start_y
    for s in kind['scripts']:
        if not isinstance(s, int):
            break
        for st in wavescript.script(mem, s):
            x += ('right' in st['dirs']) - ('left' in st['dirs'])
            y += ('down' in st['dirs']) - ('up' in st['dirs'])
            pts.append((x, y))
            if len(pts) > limit:
                return pts
    return pts


def cmd_paths(n, out):
    d = wavescript.decode(n)
    mem, _, _ = wavescript.load(n)
    kinds = d['kinds']
    byk = {k['kind']: k for k in kinds}
    cols = 6
    pw, ph = 170, 150
    rows = (len(kinds) + cols - 1) // cols
    W = 1050
    im = Image.new('RGB', (W, 74 + rows * ph + 20), 'white')
    dr = ImageDraw.Draw(im)
    f17, f13 = font(17), font(13)
    dr.text((10, 8), f'Level {n}\'s {len(kinds)} enemy kinds: the path each kind\'s script list draws, one cell a step',
            fill='black', font=f17)
    dr.text((10, 32), f'tools/fig_level.py paths {n}: the screen (32 x 20 cells, 4 px a cell); green dot the start '
                      '(cell 26, 8 here; the wave gives the real one), red the end; the list once', fill=(60, 60, 60),
            font=f13)
    dr.text((10, 50), 'Movers can skip steps (half speed) or steer (toward the ship): the path is the script\'s, the '
                      'mover\'s changes are in doc 7, 7.8.', fill=(60, 60, 60), font=f13)
    for i, k in enumerate(kinds):
        x0, y0 = (i % cols) * (pw + 3) + 6, 74 + (i // cols) * ph
        src = byk.get(k['alias'], k) if k['alias'] else k
        title = f'kind {k["kind"]}: A{k["mover_a"]} B{k["mover_b"]}, ' + \
                ('indestr.' if k['hits'] == 63 else f'{k["hits"]} hit' + ('s' if k['hits'] != 1 else ''))
        dr.text((x0, y0), title, fill='black', font=f13)
        sx0, sy0 = x0 + 4, y0 + 20
        dr.rectangle([sx0, sy0, sx0 + 128, sy0 + 80], outline=(170, 170, 170))
        pts = walk(mem, src)
        sc = 4
        line = [(sx0 + max(-2, min(34, px)) * sc, sy0 + max(-2, min(22, py)) * sc) for px, py in pts]
        if len(line) > 1:
            dr.line(line, fill=(40, 90, 190), width=2)
        dr.ellipse([line[0][0] - 3, line[0][1] - 3, line[0][0] + 3, line[0][1] + 3], fill=(0, 160, 0))
        dr.ellipse([line[-1][0] - 3, line[-1][1] - 3, line[-1][0] + 3, line[-1][1] + 3], fill=(200, 0, 0))
        steps = len(pts) - 1
        end = src['scripts'][-1] if src['scripts'] else '?'
        tail = {'free': 'then free', 'again': 'loops'}.get(end, '')
        count = f'{steps}+ steps' if steps >= 160 else f'{steps} step' + ('s' if steps != 1 else '')
        dr.text((x0, sy0 + 84), f'{count}, {tail}' + (f' (= {k["alias"]})' if k['alias'] else ''),
                fill=(60, 60, 60), font=f13)
    im.save(out)
    print(out, im.size)


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        return
    if a[0] == 'blocks':
        cmd_blocks(a[1])
    elif a[0] == 'formats':
        cmd_formats(a[1])
    elif a[0] == 'waves':
        cmd_waves(a[1])
    elif a[0] == 'strip':
        cmd_strip(int(a[1]), a[2])
    elif a[0] == 'paths':
        cmd_paths(int(a[1]), a[2])


if __name__ == '__main__':
    main()
