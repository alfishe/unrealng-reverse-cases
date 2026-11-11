#!/usr/bin/env python3
"""The figures of doc 05 (controls), drawn from src/res and the recordings' data.

    python3 tools/fig_controls.py keyboard --out docs/img/controls/keyboard.png
    python3 tools/fig_controls.py sites --out docs/img/controls/key-sites.png
    python3 tools/fig_controls.py timeline --keys work/docs/esB/keys-14255.txt \
        --player work/docs/esB/player-14255.txt --out docs/img/controls/input-timeline.png

keyboard: the 40 keys of KeyTable `$A900` (src/res/tables/keys.csv) in the Spectrum's layout, each with its half row,
bit mask, scan index and what the game does with it (the loaded key sites, the fixed keys F G H, the menu 1-5).
sites: the nine self-modified key sites as the three code sets (src/res/tables/keyboard-code.csv, kempston-code.csv,
and the hybrid RedefineKeys leaves on the Kempston code, from the experiment in work/docs/esB/exp_controls.py).
timeline: c1 frames 14255-14415, the keys of tests/inputs/c1.txt, the pass starts and moves from the access trace
(work/docs/esB/tr.py output) and PlayerIndex `$FD9C` sampled at each frame start (work/docs/esB/peek.py output).
"""
import argparse
import csv
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

FG, DIM, BG, PANEL = K.TEXT, K.DIM, K.BACKGROUND, K.PANEL
W = 1050
USE = {  # key -> (tag, colour)
    'O': ('left', (90, 150, 250)), 'P': ('right', (90, 200, 120)), 'Q': ('up', (240, 200, 70)),
    'A': ('down', (250, 150, 60)), 'M': ('fire', (230, 90, 80)),
    'F': ('map', (70, 210, 220)), 'G': ('abort', (200, 110, 230)), 'H': ('quit', (240, 120, 180)),
    '1': ('start', (160, 220, 80)), '2': ('redefine', (160, 220, 80)), '3': ('keyboard', (160, 220, 80)),
    '4': ('joystick', (160, 220, 80)), '5': ('reset', (160, 220, 80)),
}
NAMES = {'c': 'CS', 's': 'SS', 'e': 'ENT', ' ': 'SPC'}
LAYOUT = ['1234567890', 'QWERTYUIOP', 'ASDFGHJKLe', 'cZXCVBNMs ']


def keytable():
    rows = []
    with open(os.path.join(CASE, 'src', 'res', 'tables', 'keys.csv')) as f:
        for line in f:
            if line.startswith('#') or line.startswith('half_row'):
                continue
            r = next(csv.reader([line.strip()]))
            rows.append((int(r[0].lstrip('$'), 16), int(r[1].lstrip('$'), 16), r[2]))
    return rows


def fig_keyboard(out):
    keys = keytable()
    index = {ch: (i, row, mask) for i, (row, mask, ch) in enumerate(keys)}
    kw, kh, gap, x0, y0 = 92, 92, 6, 16, 74
    h = y0 + 4 * (kh + gap) + 250
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fb, fs = K.font(19), K.font(13), K.font(22), K.font(12)
    d.text((18, 14), 'The 40 keys of KeyTable $A900 and what Earth Shaker does with them', font=ft, fill=FG)
    d.text((18, 42), 'key, port $xxFE half row and bit mask, the scan index of WaitKey; coloured: its use', font=f,
           fill=DIM)
    for r, line in enumerate(LAYOUT):
        for c, ch in enumerate(line):
            x, y = x0 + c * (kw + gap) + r * 12, y0 + r * (kh + gap)
            i, row, mask = index[ch]
            label = NAMES.get(ch, ch)
            use = USE.get(ch)
            fill = use[1] if use else PANEL
            ink = (10, 10, 14) if use else FG
            d.rectangle((x, y, x + kw, y + kh), fill=fill, outline=(70, 70, 85))
            d.text((x + 7, y + 4), label, font=fb, fill=ink)
            d.text((x + 7, y + 34), f'${row:02X} ${mask:02X}', font=f, fill=ink if use else DIM)
            d.text((x + 7, y + 52), f'index {i}', font=fs, fill=ink if use else DIM)
            if use:
                d.text((x + 7, y + 70), use[0], font=f, fill=ink)
    y = y0 + 4 * (kh + gap) + 14
    notes = [
        'How to read:',
        '- O P Q A M: the five keys as loaded (nine key sites: left, right, up, down, fire); RedefineKeys $8C30 can put any',
        '  of the 40 keys there (the half row at site+1, the mask at site+7).',
        '- F G H: fixed keys read once a pass: MapKey $EA96 ($FD/$08), AbortKey $93A5 ($FD/$10), QuitKey $872D ($BF/$10).',
        '- 1-5: the menu (MenuKeys $8B29, ChooseControl $ECE3, ResetMachine $8B65), all on half row $F7.',
        '- index: the place in KeyTable; WaitKey $8C1D scans 0 to 39 and takes the first key down, so with two keys held the',
        '  lower index wins (V before C, ..., B before SPACE).',
        'The point: the game reads one half row and one bit per key, the plain Spectrum way; what the player can choose is',
        'exactly the 40 keys of the table, the shifts and ENTER included.',
        'Drawn from src/res/tables/keys.csv and the IN sites of build/game.lst: python3 tools/fig_controls.py keyboard',
    ]
    for i, line in enumerate(notes):
        d.text((18, y + i * 21), line, font=f, fill=FG if i < 9 else DIM)
    im.save(out)


def code_rows(name):
    rows = []
    with open(os.path.join(CASE, 'src', 'res', 'tables', name)) as f:
        for line in f:
            if line.startswith('#') or line.startswith('site,'):
                continue
            site, bytes_ = line.strip().split(',')
            rows.append((site, [int(b, 16) for b in bytes_.split()]))
    return rows


def disasm(b):
    """The 9 bytes of a key site as the CPU runs them"""
    out, i = [], 0
    while i < 9:
        op = b[i]
        if op == 0x3E:
            out.append(f'LD A,${b[i + 1]:02X}'); i += 2
        elif op == 0xD3:
            out.append(f'OUT (${b[i + 1]:02X}),A'); i += 2
        elif op == 0xDB:
            out.append(f'IN A,(${b[i + 1]:02X})'); i += 2
        elif op == 0xE6:
            out.append(f'AND ${b[i + 1]:02X}'); i += 2
        elif op == 0xC0:
            out.append('RET NZ'); i += 1
        elif op == 0xC8:
            out.append('RET Z'); i += 1
        elif op == 0x28:
            out.append('JR Z,..'); i += 1
        elif op == 0x20:
            out.append('JR NZ,..'); i += 1
        elif op == 0x00:
            out.append('NOP'); i += 1
        elif op == 0xDF:
            out.append('RST $18'); i += 1
        elif op == 0xFB:
            out.append('EI'); i += 1
        elif op == 0xFD:
            out.append('(FD)'); i += 1
        elif op == 0x7F:
            out.append('LD A,A'); i += 1
        else:
            out.append(f'${op:02X}'); i += 1
    return '; '.join(out)


def fig_sites(out):
    kb = code_rows('keyboard-code.csv')
    kj = code_rows('kempston-code.csv')
    # the hybrid: RedefineKeys on the Kempston code (experiment A): row at +1, mask at +7, keys O P Q A M
    redefined = {'TryLeft': (0xDF, 0x02), 'TryRight': (0xDF, 0x01), 'TryUp': (0xFB, 0x01), 'TryDown': (0xFD, 0x01),
                 'KeysStep': (0x7F, 0x04), 'FireLeft': (0xDF, 0x02), 'FireRight': (0xDF, 0x01),
                 'FireUp': (0xFB, 0x01), 'FireDown': (0xFD, 0x01)}
    hy = []
    for site, b in kj:
        n = site.split()[0]
        b = list(b)
        b[1], b[7] = redefined[n]
        hy.append((site, b))
    panels = [
        ('KeyboardCode $EB15: the keyboard code (as loaded: O P Q A M), menu key 3', kb),
        ('KempstonCode $EAC4: the joystick code, menu key 4', kj),
        ('The hybrid: menu 4, 4, 3, then 2 with O P Q A M (experiment on a clone)', hy),
    ]
    bw, rh, x0 = 34, 24, 150
    h = 60 + len(panels) * (34 + 9 * rh + 18) + 220
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(18), K.font(13), K.font(12)
    d.text((18, 14), 'The nine key sites: 9 bytes each, rewritten whole by the control choice', font=ft, fill=FG)
    role = {1: (90, 150, 250), 7: (250, 150, 60)}
    y = 52
    for title, rows in panels:
        d.text((18, y), title, font=K.font(15), fill=FG)
        y += 28
        for site, b in rows:
            d.text((18, y + 4), site, font=f, fill=FG)
            for i, v in enumerate(b):
                x = x0 + i * (bw + 2)
                fill = role.get(i, PANEL)
                d.rectangle((x, y, x + bw, y + rh - 3), fill=fill)
                d.text((x + 8, y + 3), f'{v:02X}', font=f, fill=(10, 10, 14) if i in role else FG)
            d.text((x0 + 9 * (bw + 2) + 12, y + 4), disasm(b), font=f, fill=FG)
            y += rh
        y += 18
    notes = [
        'How to read: one line a site, its 9 bytes as hex, then the instructions the CPU runs. Blue: byte +1, the half row',
        'RedefineKeys writes; orange: byte +7, the bit mask it writes. Keyboard: a key down reads 0, so RET NZ leaves on no',
        'key; Kempston: a direction reads 1, so RET Z leaves. The fire site KeysStep $8759 ends in JR Z / JR NZ to FireStep.',
        'Third panel: 4 twice saves the Kempston code into KeyboardCode, 3 copies it back, and RedefineKeys then writes the',
        'rows into the NOP at +1 and the masks over the stick masks: the keys do nothing, the stick answers with the new masks.',
        'The point: the two control methods are two copies of the same 81 bytes of code, swapped by LDIR; the redefinition',
        'patches two bytes per site and assumes the keyboard copy is in place.',
        'Drawn from src/res/tables/keyboard-code.csv and kempston-code.csv (the hybrid as read back in work/docs/esB/',
        'exp_controls.py, case A): python3 tools/fig_controls.py sites',
    ]
    for i, line in enumerate(notes):
        d.text((18, y + i * 21), line, font=f, fill=FG if i < 9 else DIM)
    im.save(out)


def fig_timeline(keys_path, player_path, out):
    f0, f1 = 14255, 14415
    held = [('O', 14260, 14310), ('A', 14310, 14360), ('P', 14360, 14410)]
    passes, moves = [], []
    kind = {'8428': 'left', '849E': 'right', '8535': 'down', 'E81F': 'push blocked'}
    for line in open(keys_path):
        p = line.split()
        if len(p) == 2 and len(p[0]) == 4 and ':' in p[1]:
            fr, t = map(int, p[1].split(':'))
            if p[0] == '8759':
                passes.append(fr + t / 69888)
            elif p[0] in kind:
                moves.append((fr + t / 69888, kind[p[0]]))
    player = []
    for line in open(player_path):
        fr, lo, hi = line.split()
        player.append((int(fr), int(hi + lo, 16)))
    x0, x1 = 120, W - 20
    def X(fr):
        return x0 + (fr - f0) * (x1 - x0) / (f1 - f0)
    h = 560
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(12)
    d.text((18, 12), 'From the key to the move: c1 frames 14255-14415, cave 1, keyboard (O left, A down, P right)',
           font=ft, fill=FG)
    col = {'O': USE['O'][1], 'A': USE['A'][1], 'P': USE['P'][1], 'left': USE['O'][1], 'down': USE['A'][1],
           'right': USE['P'][1], 'push blocked': (230, 90, 80)}
    # frame axis
    y = 50
    for fr in range(f0 + 5, f1 + 1, 20):
        d.line((X(fr), y + 16, X(fr), 400), fill=(40, 40, 52))
        d.text((X(fr) - 18, y), str(fr), font=fs, fill=DIM)
    # keys held
    y = 80
    d.text((18, y + 4), 'key held', font=f, fill=FG)
    for k, a, b in held:
        d.rectangle((X(a), y, X(b), y + 24), fill=col[k])
        d.text((X(a) + 6, y + 4), k, font=f, fill=(10, 10, 14))
    # passes
    y = 130
    d.text((18, y + 4), 'KeysStep', font=f, fill=FG)
    for p in passes:
        d.line((X(p), y, X(p), y + 26), fill=FG, width=2)
    # moves
    y = 180
    d.text((18, y + 4), 'the move', font=f, fill=FG)
    for p, k in moves:
        d.rectangle((X(p) - 4, y, X(p) + 4, y + 26), fill=col[k])
    # player column and row
    y0, y1 = 240, 400
    d.text((18, y0), 'PlayerIndex', font=f, fill=FG)
    d.text((18, y0 + 20), 'column (blue)', font=fs, fill=USE['O'][1])
    d.text((18, y0 + 38), 'row (orange)', font=fs, fill=USE['A'][1])
    def Y(v, lo, hi):
        return y1 - (v - lo) * (y1 - y0) / (hi - lo)
    cols = [(fr, v % 30) for fr, v in player]
    rows = [(fr, v // 30) for fr, v in player]
    for series, c, lo, hi in ((cols, USE['O'][1], 8, 26), (rows, USE['A'][1], 8, 26)):
        pts = []
        for fr, v in series:
            pts.append((X(fr), Y(v, lo, hi)))
            pts.append((X(fr + 1), Y(v, lo, hi)))
        d.line(pts, fill=c, width=3)
    for v in (10, 14, 18, 22):
        d.text((x1 - 22, Y(v, 8, 26) - 8), str(v), font=fs, fill=DIM)
    y = 418
    notes = [
        'How to read: the bars are the keys of tests/inputs/c1.txt; each white tick a KeysStep $8759 (a pass start, from the',
        'access trace); each square a move (MoveLeft $8428, MoveDown $8535, MoveRight $849E) or a push PushBoulder $E81F',
        'refused (red); the lines PlayerIndex $FD9C as column and row, sampled at each frame start (memory_at).',
        'The point: the keys are read once a pass (5.3 to 6.5 frames here), so the player moves one cell a pass while the key',
        'is held; O held against a boulder with no room behind it costs seven passes of refused pushes.',
        'python3 tools/fig_controls.py timeline (trace c1 14255:0-14415:0; work/docs/esB/tr.py, peek.py)',
    ]
    for i, line in enumerate(notes):
        d.text((18, y + i * 21), line, font=f, fill=FG if i < 5 else DIM)
    im.save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=['keyboard', 'sites', 'timeline'])
    ap.add_argument('--out', required=True)
    ap.add_argument('--keys')
    ap.add_argument('--player')
    a = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    if a.what == 'keyboard':
        fig_keyboard(a.out)
    elif a.what == 'sites':
        fig_sites(a.out)
    else:
        fig_timeline(a.keys, a.player, a.out)
    print(a.out)


if __name__ == '__main__':
    main()
