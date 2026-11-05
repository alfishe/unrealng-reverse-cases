#!/usr/bin/env python3
"""Side-by-side figures for docs/img/compare/: the 48K original (Hewson 1987, ZYNAPS.TAP on a 48K, left) against
Zynaps 2 in 1 (the TRD on a Pentagon 128, right) at the same moments. Real emulator frames only: each panel is the
6912 screen bytes read from a TTD recording by tools/compare_shots.py (memory_at, exact), rendered here with the kit's
Spectrum palette at 2x, nearest neighbour, no border (the recordings hold memory, not the border). Under each panel
a caption strip names the recording and the frame; when both sides have one panel, the measured difference in
character cells (8x8 pixels + attribute) is added to the captions of MEASURED.

    python3 tools/compare_shots.py --work W --name r48 FRAME ...   # per recording, its instance open
    python3 tools/fig_compare.py [--shots work/stage2/compare/shots] [--out docs/img/compare]

The recordings (work folder of each, the input script in work/stage2/compare/inputs/):
  r48   work/stage2/compare/r48/session.ttd   48K, work/ref48/ZYNAPS.TAP, power-on, inputs r48.txt
  c1    work/stage1/c1/session.ttd            PENTAGON, the TRD, power-on to play (stage 1)
  k128  work/stage2/compare/k128/session.ttd  PENTAGON, the TRD, power-on to the keyboard definition, inputs k128.txt
"""
import argparse
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

RECORDINGS = {
    'r48': '48K ZYNAPS.TAP: work/stage2/compare/r48/session.ttd',
    'c1': 'Pentagon TRD: work/stage1/c1/session.ttd',
    'k128': 'Pentagon TRD: work/stage2/compare/k128/session.ttd',
}

# name: (title, [48K panels], [128K panels], caption); a panel is (recording, frame, label)
FIGURES = {
    '01-power-on.png': (
        'Power-on',
        [('r48', 110, '48K: the ROM\'s copyright line')],
        [('c1', 1615, '128K: Pentagon 128 menu, TR-DOS chosen')],
        'The first screen after power-on. The 48K original is a tape: the 48 BASIC ROM\'s copyright line. The 128K '
        'version is a TR-DOS disk: on a Pentagon the 128 menu, its last item TR-DOS.'),
    '02-load.png': (
        'Loading',
        [('r48', 235, '48K: LOAD "" typed'), ('r48', 260, '48K: the loading screen arrives')],
        [('c1', 1990, '128K: the boot.B list, ZYNAPS'), ('c1', 2100, '128K: blocks loading (cleared screen)'),
         ('c1', 2200, '128K: title reveal, attribute rows')],
        'The load. The tape: LOAD "", then the Hewson picture loads as the loading screen (pixels first, the colours '
        'after) and stays up while the game block loads (frames 260 to 10 400 at ROM speed). The disk: RUN gives '
        'boot.B\'s framed list (the disk label ZYNAPS over the files ZYNAPS and boot), ENTER runs ZYNAPS; the screen '
        'stays clear while sector 1 and block 1 load and unpack, then the intro draws its first picture by '
        'attribute rows.'),
    '03-title.png': (
        'The first picture',
        [('r48', 5000, '48K: the loading screen (Hewson picture)')],
        [('c1', 2290, '128K: the new title picture (RVS / M. Stawicki)')],
        'The first full picture. The 48K original shows the Hewson picture "By Dominic Robinson" as its loading '
        'screen, with a four-arrow mark in the bottom left (in the picture\'s own bytes on the tape). The 128K '
        'version opens with a new picture '
        'signed RVS.M.STAWICKI (c) while the STarKos tune plays.'),
    '04-options.png': (
        'Options and menu',
        [('r48', 10450, '48K: the game menu (credits page)')],
        [('c1', 2740, '128K: the options screen'), ('c1', 3460, '128K: the game menu (credits page)')],
        'After the load the 48K original goes straight to its game menu (the credits and the high scores in '
        'turn). The 128K version first shows a new options screen: "WITH AY MUSIC & SFX", 1987 (C) '
        'HEWSON, 2018 (R) GOODBOY&TIBOH, the game-menu keys, and 0.START 1.INF.LIVES 2.K-MOUSE; 0 goes on to the '
        'Hewson picture and the same game menu.'),
    '05-hewson-picture.png': (
        'The Hewson picture',
        [('r48', 10400, '48K: loading screen, last frame')],
        [('c1', 3290, '128K: the intro\'s third picture')],
        'The Hewson picture appears in both: as the 48K loading screen and as the third picture of the 128K intro '
        '(after the options, before the game menu). What is seen to differ: the top pixel line (empty on the tape, '
        'the frame pattern in the 128K picture), the tape picture\'s four-arrow mark in the bottom left (not in '
        'the 128K one), and the colour of six stars; the rest are attribute bytes of empty cells.'),
    '06-keyboard-definition.png': (
        'Keyboard definition, default keys',
        [('r48', 11800, '48K: KEYBOARD DEFINITION, P L SS A S')],
        [('k128', 3900, '128K: KEYBOARD DEFINITION, SP Q A O P')],
        'Key 3 in the game menu. The screen asks for FIRE, UP, DOWN, LEFT, RIGHT in turn; each side was given its '
        'own default keys from the key table at $8188 (48K: df01 bf02 7f02 fd01 fd02 = P, L, SYMBOL SHIFT, A, S; '
        '128K: 7f01 fb01 fd01 df02 df01 = SPACE, Q, A, O, P), and the table read back unchanged after the '
        'definition in both recordings. The screen itself is the same code.'),
    '07-high-scores.png': (
        'High-score table',
        [('r48', 11900, '48K: the high-score page')],
        [('c1', 3540, '128K: the high-score page (key 4)')],
        'The high-score page of the game menu: the same five entries (EGO 68000, DFR 25000, BAV 10000, HNR 5000, '
        'BMR 1000) and the same layout.'),
    '08-credits.png': (
        'Credits',
        [('r48', 10450, '48K: MUSIC STEVE TURNER')],
        [('c1', 3460, '128K: MUSIC DAVE ROGERS')],
        'The credits page of the game menu. One name changed: MUSIC STEVE TURNER (48K) is MUSIC DAVE ROGERS in the '
        '128K version (the string at $8484, written by the 128K loader; Dave Rogers wrote the CPC version\'s music).'),
    '09-prepare-for-combat.png': (
        'Prepare for combat',
        [('r48', 12205, '48K: after 1 and fire (P)')],
        [('c1', 3945, '128K: after fire (SPACE)')],
        'Fire in the game menu starts a game: PREPARE FOR COMBAT / PLAYER 1, the same in both.'),
    '10-play-start.png': (
        'The first frames of play',
        [('r48', 12295, '48K: play, no input yet')],
        [('c1', 4020, '128K: play, QAOP + SPACE')],
        'The first frames of play: the same level start, panel and scroll (the panel\'s lamps blink, so their '
        'colours differ between any two frames). The visible game is the original\'s; what the '
        'player hears differs (AY music and effects in the 128K version, the beeper in the 48K).'),
}

# the figures whose two screens are compared cell by cell (the others show different screens on purpose)
MEASURED = {'05-hewson-picture.png', '06-keyboard-definition.png', '07-high-scores.png', '08-credits.png',
            '09-prepare-for-combat.png'}

BG, FG, DIM, MONO = (24, 24, 24), (235, 235, 235), (175, 175, 175), (140, 200, 255)
PAD, GAP, SCALE = 16, 16, 2


def font(size):
    return ImageFont.load_default(size=size)


def wrap(draw, text, fnt, width):
    lines, line = [], ''
    for word in text.split():
        trial = (line + ' ' + word).strip()
        if draw.textlength(trial, font=fnt) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def screen(shots, recording, frame):
    path = os.path.join(shots, recording, f'{frame}.scr')
    with open(path, 'rb') as f:
        data = f.read()
    if len(data) != 6912:
        raise SystemExit(f'{path}: {len(data)} bytes, not a screen')
    return data


def cell_diff(a, b):
    """the character cells (row, column) whose 8 pixel bytes or attribute differ"""
    cells = {(((i >> 8) & 0x18) | ((i >> 5) & 7), i & 31) for i in range(6144) if a[i] != b[i]}
    cells |= {(i // 32, i % 32) for i in range(768) if a[6144 + i] != b[6144 + i]}
    return cells


def visible_cells(a, b):
    """the character cells whose rendered pixels differ (an attribute change in an empty cell is not seen)"""
    d = ImageChops.difference(K.render_screen(a, 0).convert('RGB'), K.render_screen(b, 0).convert('RGB')).convert('L')
    return {(y // 8, x // 8) for y in range(192) for x in range(256) if d.getpixel((x, y))}


def panel(shots, recording, frame, label):
    picture = K.render_screen(screen(shots, recording, frame), 0).convert('RGB')
    picture = picture.resize((256 * SCALE, 192 * SCALE), resample=Image.NEAREST)
    return picture, label, f'{RECORDINGS[recording]}, frame {frame}'


def figure(shots, title, left, right, caption, measure):
    head, small, body = font(22), font(14), font(18)
    panels = [panel(shots, *p) for p in left] + [panel(shots, *p) for p in right]
    pw, ph = 256 * SCALE, 192 * SCALE
    divider = GAP * 2
    width = PAD * 2 + len(panels) * pw + (len(panels) - 1) * GAP + divider
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    if measure and len(left) == 1 and len(right) == 1:
        cells = cell_diff(screen(shots, *left[0][:2]), screen(shots, *right[0][:2]))
        rows = sorted({r for r, _ in cells})
        if cells:
            if len(rows) == 1:
                where = f'row {rows[0]}'
            elif len(rows) == rows[-1] - rows[0] + 1:
                where = f'rows {rows[0]}-{rows[-1]}'
            else:
                where = 'rows ' + ', '.join(map(str, rows))
            seen = visible_cells(screen(shots, *left[0][:2]), screen(shots, *right[0][:2]))
            caption += f' Measured: {len(cells)} of 768 character cells differ in bytes ({where}), ' \
                       f'{len(seen)} of them in the rendered colours.'
        else:
            caption += ' Measured: the two screens are byte-identical.'
    lines = wrap(probe, caption, body, width - 2 * PAD)
    top = PAD + 34
    label_h, strip_h = 26, 22
    height = top + label_h + ph + strip_h + PAD + len(lines) * 24 + PAD
    im = Image.new('RGB', (width, height), BG)
    d = ImageDraw.Draw(im)
    d.text((PAD, PAD), f'{title}: Zynaps 48K (Hewson 1987, left), Zynaps 2 in 1 (128K, 2018, right)',
           font=head, fill=FG)
    x = PAD
    for n, (picture, label, strip) in enumerate(panels):
        if n == len(left):
            d.line([(x + divider // 2 - GAP // 2, top), (x + divider // 2 - GAP // 2, top + label_h + ph + strip_h)],
                   fill=DIM, width=2)
            x += divider
        d.text((x, top), label, font=font(16), fill=FG)
        im.paste(picture, (x, top + label_h))
        d.text((x, top + label_h + ph + 4), strip, font=small, fill=MONO)
        x += pw + GAP
    y = top + label_h + ph + strip_h + PAD
    for line in lines:
        d.text((PAD, y), line, font=body, fill=DIM)
        y += 24
    return im, caption


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--shots', default=os.path.join(ROOT, 'work', 'stage2', 'compare', 'shots'))
    ap.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img', 'compare'))
    ap.add_argument('only', nargs='*', help='figure names (default: all)')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for name, (title, left, right, caption) in FIGURES.items():
        if a.only and name not in a.only:
            continue
        im, text = figure(a.shots, title, left, right, caption, name in MEASURED)
        im.save(os.path.join(a.out, name), optimize=True)
        print(f'{name}: ' + '; '.join(f'{r} {f}' for r, f, _ in left + right) + (
            '  [' + text.split('Measured: ')[1] + ']' if 'Measured: ' in text else ''))


if __name__ == '__main__':
    main()
