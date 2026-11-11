#!/usr/bin/env python3
"""Doc 07's figures: the cell codes, a cave record byte by byte, the game variables.

    python3 tools/fig_objects.py codes [--out docs/img/objects/cell-codes.png]
    python3 tools/fig_objects.py record [--cave 1] [--out docs/img/objects/cave-record.png]
    python3 tools/fig_objects.py vars --samples FILE.jsonl --frame F [--label TEXT] [--out docs/img/objects/vars.png]
    python3 tools/fig_objects.py table            # the 32 caves' parameters as a markdown table (doc 07)

The cell graphics come from src/res (fig_caves.resource_memory) with cave 1's colours (CaveSetup `$9313`); the cave
record from src/res/caves/caves.txt and, for its bytes, the loaded image work/mkgame/original.bin (the two agree:
tools/build.sh prints identical). A `vars` sample file holds JSON lines {"frame": F, "hex": ...} of `$FD7A-$FFFF`
taken with TTD memory_at (work/docs/esC/sample.py).
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import fig_caves  # noqa: E402
import kitlib as K  # noqa: E402
import res_formats  # noqa: E402

BG, FG, DIM, GRID = (22, 22, 28), (236, 236, 236), (160, 160, 170), (70, 70, 84)
FALL, SKIP, ANIM, PLAYER = (120, 200, 255), (150, 150, 150), (255, 190, 90), (130, 230, 130)
CHARS = '.X0RL#:*TZAS+DOF'

# code, name, gravity (ScanCells $8075), what the player's move does (TryLeft $83C3 ... and the specials)
CODES = [
    (0x00, 'empty', 'skipped; objects fall and roll into it', 'moves in'),
    (0x01, 'exit', 'skipped', 'blocks; open (ExitOpen): CaveDone'),
    (0x02, 'boulder', 'falls, rolls; over fire: dissolve $15', 'pushed left / right into 0'),
    (0x03, 'player facing right', 'skipped; under a fall: Crush', '(the player)'),
    (0x04, 'player facing left', 'skipped; under a fall: Crush', '(the player)'),
    (0x05, 'wall', 'skipped', 'blocks (BlockWall)'),
    (0x06, 'earth', 'skipped; falls in 5 caves', 'dug: moves in, DugEarth'),
    (0x07, 'gem', 'falls, rolls', 'taken: GemValue points'),
    (0x08, 'jelly bean', 'falls, rolls', 'taken: 32 bar pixels, 64 points'),
    (0x09, 'force field', 'skipped', 'blocks, 12 timer steps'),
    (0x0A, 'anti-gravity arrow', 'falls, rolls', 'taken: 99 upward scans, 200'),
    (0x0B, 'switch box', 'skipped; a fall on it: SwitchHit', 'blocks'),
    (0x0C, 'potion', 'falls, rolls', 'taken: a life (max 9), 20'),
    (0x0D, 'teleporter', 'skipped', 'to the first other $0D'),
    (0x0E, 'bubble', 'skipped', 'pushed; into fire: burst, 100'),
    (0x0F, 'fire', 'falls, rolls (and crushes)', 'kills (WalkIntoFire)'),
    (0x10, 'burst, first (not drawn)', 'not skipped (CP $10): MoveObject', 'blocks'),
    (0x11, 'burst, $11-$14', 'skipped; $14 steps to $20', 'blocks'),
    (0x15, 'dissolve, $15-$1B', 'skipped; $1B steps to $20', 'blocks'),
    (0x20, 'vacated', 'skipped; ClearVacated: 0', 'blocks (never seen)'),
]


def colour_of(code):
    if code in (2, 7, 8, 0xA, 0xC, 0xF):
        return FALL
    if code in (3, 4):
        return PLAYER
    if code >= 0x10:
        return ANIM
    return SKIP


def cave1_memory():
    base = fig_caves.resource_memory()
    return fig_caves.cave_setup(base, res_formats.read_caves()[0][0])


def codes(out):
    m = cave1_memory()
    f, fb, fs = K.font(15), K.font(17), K.font(13)
    row_h, top = 54, 70
    img = Image.new('RGB', (1050, top + row_h * len(CODES) + 70), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'Every cell code: its graphic, its letter in caves.txt, what the gravity scan and the player do',
           font=fb, fill=FG)
    cols = [(14, 'graphic'), (74, 'code'), (124, 'chr'), (166, 'cell'), (440, 'ScanCells $8075'),
            (760, 'the player moving into it')]
    for x, t in cols:
        d.text((x, 44), t, font=fs, fill=DIM)
    for i, (code, name, grav, player) in enumerate(CODES):
        y = top + i * row_h
        d.line((10, y - 3, 1040, y - 3), fill=GRID)
        g, addr = fig_caves.graphic(m, code & 0x1F)
        if code in (0x10, 0x15):  # words 16 and 21 are never read: show the first drawn frame's graphic
            g, _ = fig_caves.graphic(m, code + 1)
        if g:
            img.paste(g.resize((48, 48), Image.NEAREST), (14, y))
        d.rectangle((14, y, 61, y + 47), outline=GRID)
        d.text((74, y + 14), f'${code:02X}', font=f, fill=colour_of(code))
        d.text((130, y + 14), CHARS[code] if code < 16 else '', font=f, fill=FG)
        d.text((166, y + 6), name, font=f, fill=FG)
        d.text((166, y + 27), f'table word {code & 0x1F}: ${addr:04X}' if addr else 'no graphic', font=fs, fill=DIM)
        d.text((440, y + 14), grav, font=fs, fill=colour_of(code))
        d.text((760, y + 14), player, font=fs, fill=FG)
    y = top + row_h * len(CODES) + 6
    for x, (c, t) in zip((14, 230, 420, 640), ((FALL, 'falls (MoveObject $80DB)'), (SKIP, 'skipped by the scan'),
                                                (PLAYER, 'the player'), (ANIM, 'an animation code'))):
        d.rectangle((x, y + 4, x + 14, y + 18), fill=c)
        d.text((x + 22, y + 2), t, font=fs, fill=FG)
    d.text((14, y + 30), 'Graphics: src/res cell sheets, cave 1 colours.  python3 tools/fig_objects.py codes',
           font=fs, fill=DIM)
    img.save(out)


def record(out, n):
    params, cells = res_formats.read_caves()[n - 1]
    image = open(os.path.join(CASE, 'work', 'mkgame', 'original.bin'), 'rb').read()
    start = 0xC000 + 314 * (n - 1)
    rec = image[start:start + 314]
    m = fig_caves.cave_setup(fig_caves.resource_memory(), params)
    f, fb, fs = K.font(15), K.font(17), K.font(13)
    img = Image.new('RGB', (1050, 600), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), f'Cave {n} at ${start:04X}: 300 bytes of two cells each (low nibble = left cell), then 14 '
           'parameter bytes', font=fb, fill=FG)
    # the first row: 15 bytes -> 30 cells
    d.text((14, 44), f'Row 0 = bytes 0-14 (${start:04X}-${start + 14:04X}); each byte gives two cells, the low '
           'nibble first', font=fs, fill=DIM)
    bw = 68
    for i in range(15):
        x, y = 14 + i * bw, 70
        b = rec[i]
        d.rectangle((x, y, x + bw - 4, y + 30), outline=GRID, fill=(40, 40, 52))
        d.text((x + 18, y + 6), f'{b:02X}', font=f, fill=FG)
        for k, v in enumerate((b & 15, b >> 4)):
            cx = x + k * (bw // 2)
            g, _ = fig_caves.graphic(m, v)
            if g:
                img.paste(g.resize((32, 32), Image.NEAREST), (cx, y + 40))
            d.text((cx + 11, y + 76), f'{v:X}', font=f, fill=FALL if k == 0 else ANIM)
            d.text((cx + 6, y + 96), f'{2 * i + k:2d}', font=fs, fill=DIM)
    d.text((14, 188), 'low nibble (cell 2i)', font=fs, fill=FALL)
    d.text((200, 188), 'high nibble (cell 2i + 1)', font=fs, fill=ANIM)
    d.text((440, 188), 'numbers under the cells: the column', font=fs, fill=DIM)
    # the whole cave, small
    cave = fig_caves.draw_cave(m, cells).resize((480, 320), Image.NEAREST)
    img.paste(cave, (14, 220))
    d.rectangle((14, 220, 14 + 479, 220 + 15), outline=(255, 80, 80), width=2)
    d.text((14, 546), f'The cave decoded (row 0 framed red); the player starts at cell {params["start"]}',
           font=fs, fill=DIM)
    # the parameters
    names = [('gems_needed', 1, 'GemsNeeded $FD9A'), ('gem_value', 1, 'GemValue $FD9B'),
             ('start', 2, 'PlayerIndex $FD9C'), ('gems_digits', 2, 'GemsNeededDigits $FD9E'),
             ('earth_graphic', 2, 'EarthGraphic $FDA0'), ('wall_graphic', 2, 'WallGraphic $FDA2'),
             ('door_colour', 1, 'DoorColour $FDA4'), ('boulder_colour', 1, 'BoulderColour $FDA5'),
             ('wall1_colour', 1, 'Wall1Colour $FDA6'), ('earth_colour', 1, 'EarthColour $FDA7')]
    x0, y = 520, 220
    d.text((x0, y), f'Bytes 300-313 (${start + 300:04X}-${start + 313:04X}) -> CaveParams $FD9A-$FDA7', font=fs,
           fill=DIM)
    y += 26
    off = 300
    for key, size, var in names:
        bs = rec[off:off + size]
        v = params[key]
        if key == 'gems_digits':
            meaning = f'digits {bs[0]} {bs[1]}'
        elif size == 2:
            meaning = f'${v:04X}' + (f' = {v}: row {v // 30}, column {v % 30}' if key == 'start' else '')
        elif 'colour' in key:
            # SetGraphicColour forces BRIGHT on the left half and clears it on the right, whatever bit 6 says
            meaning = (('flash, ' if v & 0x80 else '') + ('bright, ' if v & 0x40 else '') +
                       f'ink {v & 7}, paper {v >> 3 & 7}')
        else:
            meaning = f'{v}'
        d.text((x0, y), ' '.join(f'{b:02X}' for b in bs), font=f, fill=FG)
        d.text((x0 + 64, y), var, font=fs, fill=FALL)
        d.text((x0 + 250, y), meaning, font=fs, fill=FG)
        y += 28
        off += size
    lab = {39760: 'GfxEarth', 40120: 'GfxWall1'}
    d.text((x0, y + 6), 'graphic words: ' + ', '.join(f'${params[k]:04X} {lab.get(params[k], "")}'
                                                    for k in ('earth_graphic', 'wall_graphic')), font=fs, fill=DIM)
    d.text((14, 572), f'python3 tools/fig_objects.py record --cave {n}   (src/res/caves/caves.txt, bytes from the '
           'loaded image)', font=fs, fill=DIM)
    img.save(out)


VARS = [(0xFD7A, 1, 'ClearStart'), (0xFD7B, 1, 'VarsFD7B'), (0xFD7C, 1, 'TimerSub'), (0xFD7D, 1, 'CaveOver'),
        (0xFD7E, 2, 'CaveDigits'), (0xFD80, 1, 'KeyMoved'), (0xFD81, 1, 'VarsFD81'), (0xFD82, 2, 'GemDigits'),
        (0xFD84, 1, 'CaveDone'), (0xFD85, 1, 'ExitOpen'), (0xFD86, 1, 'PlayerFacing'), (0xFD87, 2, 'Continuation'),
        (0xFD89, 2, 'SavedCell'), (0xFD8B, 2, 'AntiGravDigits'), (0xFD8D, 1, 'AntiGravSteps'),
        (0xFD8E, 1, 'ColourPhase'), (0xFD8F, 1, 'ColourCycleInk'), (0xFD90, 1, 'Unused99'),
        (0xFD91, 1, 'CaveNumber'), (0xFD92, 1, 'GemCount'), (0xFD93, 1, 'Lives'), (0xFD94, 6, 'ScoreDigits'),
        (0xFD9A, 1, 'GemsNeeded'), (0xFD9B, 1, 'GemValue'), (0xFD9C, 2, 'PlayerIndex'),
        (0xFD9E, 2, 'GemsNeededDigits'), (0xFDA0, 2, 'EarthGraphic'), (0xFDA2, 2, 'WallGraphic'),
        (0xFDA4, 1, 'DoorColour'), (0xFDA5, 1, 'BoulderColour'), (0xFDA6, 1, 'Wall1Colour'),
        (0xFDA7, 1, 'EarthColour')]
CLEARED = (255, 210, 120)
PARAM = (120, 200, 255)


def vars_fig(out, samples, frame, label):
    mem = None
    for ln in open(samples):
        s = json.loads(ln)
        if s['frame'] == frame:
            mem = bytes.fromhex(s['hex'])
    if mem is None:
        raise SystemExit(f'no sample of frame {frame}')
    at = lambda a: mem[a - 0xFD7A]  # noqa: E731
    f, fb, fs = K.font(15), K.font(17), K.font(13)
    cols, bw, bh = 2, 516, 34
    rows = (len(VARS) + 1) // 2
    img = Image.new('RGB', (1050, 90 + rows * bh + 30), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), f'The game variables $FD7A-$FDA7 at the start of {label}', font=fb, fill=FG)
    d.text((14, 38), 'yellow: cleared by ClearVars at the game start; blue: the 14 cave parameters UnpackCave copies',
           font=fs, fill=DIM)
    for i, (a, size, name) in enumerate(VARS):
        x, y = 14 + (i // rows) * bw, 70 + (i % rows) * bh
        bs = bytes(at(a + k) for k in range(size))
        col = PARAM if a >= 0xFD9A else CLEARED
        d.rectangle((x, y, x + bw - 14, y + bh - 4), outline=GRID)
        d.text((x + 6, y + 7), f'${a:04X}', font=fs, fill=DIM)
        d.text((x + 64, y + 6), name, font=f, fill=col)
        if name in ('ScoreDigits', 'CaveDigits', 'GemDigits', 'GemsNeededDigits', 'AntiGravDigits'):
            val = ''.join(str(b) for b in bs) + ' (digits)'
        elif size == 2:
            val = f'${bs[0] | bs[1] << 8:04X} = {bs[0] | bs[1] << 8}'
        else:
            val = f'${bs[0]:02X} = {bs[0]}'
        d.text((x + 250, y + 7), (' ' if size <= 2 else '').join(f'{b:02X}' for b in bs), font=fs, fill=FG)
        d.text((x + 360, y + 7), val, font=fs, fill=FG)
    d.text((14, 90 + rows * bh), f'python3 tools/fig_objects.py vars --samples {os.path.relpath(samples, CASE)} '
           f'--frame {frame}', font=fs, fill=DIM)
    img.save(out)


def table():
    caves = res_formats.read_caves()
    names = [res_formats.unquote(ln.strip()).decode('latin-1').strip()
             for ln in open(os.path.join(res_formats.RES, 'texts', 'cave-names.txt'), encoding='utf-8')
             if ln.startswith('"')]
    syms = res_formats.symbols()[0]
    print('| Cave | Name | Gems | Points a gem | Start (row, column) | Earth | Wall | Door, boulder, wall 1, earth '
          '| Gems in the cave | Boulders |')
    print('| ---: | --- | ---: | ---: | --- | --- | --- | --- | ---: | ---: |')
    for n, (p, cells) in enumerate(caves, 1):
        print(f'| {n} | {names[n - 1]} | {p["gems_needed"]} | {p["gem_value"]} | {p["start"]} ({p["start"] // 30}, '
              f'{p["start"] % 30}) | {syms.get(p["earth_graphic"], hex(p["earth_graphic"]))} | '
              f'{syms.get(p["wall_graphic"], hex(p["wall_graphic"]))} | `${p["door_colour"]:02X}` '
              f'`${p["boulder_colour"]:02X}` `${p["wall1_colour"]:02X}` `${p["earth_colour"]:02X}` | '
              f'{cells.count(7)} | {cells.count(2)} |')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=('codes', 'record', 'vars', 'table'))
    ap.add_argument('--out')
    ap.add_argument('--cave', type=int, default=1)
    ap.add_argument('--samples')
    ap.add_argument('--frame', type=int)
    ap.add_argument('--label', default='a frame')
    a = ap.parse_args()
    d = os.path.join(CASE, 'docs', 'img', 'objects')
    os.makedirs(d, exist_ok=True)
    if a.what == 'codes':
        codes(a.out or os.path.join(d, 'cell-codes.png'))
    elif a.what == 'record':
        record(a.out or os.path.join(d, 'cave-record.png'), a.cave)
    elif a.what == 'vars':
        vars_fig(a.out or os.path.join(d, 'vars.png'), a.samples, a.frame, a.label)
    else:
        table()


if __name__ == '__main__':
    main()
