#!/usr/bin/env python3
"""Side-by-side figures for docs/img/compare/: the GS conversion (left) against Nether Earth 1987 (right) at the same
moment, real emulator frames from tools/fig_capture.py scaled 2x with nearest neighbour, a title over each frame and
a caption under both. Where the screen areas match pixel for pixel, the caption says so (measured, not assumed).

    python3 tools/fig_capture.py                 # the frames, into work/stage2/shots (a few minutes)
    python3 tools/fig_compare.py [--shots work/stage2/shots] [--out docs/img/compare]
"""
import argparse
import os

from PIL import Image, ImageChops, ImageDraw, ImageFont

from fig_screens import ROOT, frame

NE = 'Nether Earth 1987: NETHER.TAP, 48K'

# output name: (GS frame, GS title, NE frame, caption)
FIGURES = {
    'start-tape.png': (
        'a/tl-b.png', 'GS: Hood\'s 2017 tape, its first screen',
        'ne/ne-b.png',
        'The first thing the tape does. Hood\'s loader asks "1-music ON / 2-music OFF" before anything else loads; '
        'NE\'s LOAD "" goes straight into its loader (black screen, border stripes in random colours).'),
    'loading-tape.png': (
        'a/u-f.png', 'GS: Hood\'s tape loading (128 BASIC, PRINT USR 0)',
        'ne/ne-c.png',
        'Loading. The GS tape loads a loading screen with the GS-512 label (here its pixels are in, its colours '
        'still coming); NE has no loading screen, its block loads into a black screen.'),
    'menu.png': (
        'a/u-g.png', 'GS: main menu (tape)',
        'ne/nm3.png',
        'The main menu is unchanged: same title, same options, same layout. The title cycles its colour in both; '
        'these two frames are at the same (yellow) phase.'),
    'play-start.png': (
        'a/scl-e-play.png', 'GS: key 0, 300 frames later (SCL)',
        'ne/ne-play.png',
        'The start of play is unchanged: the ship over the player\'s warbase, the status panel, the radar, '
        'DAY 0 TIME 02.15.'),
    'construction.png': (
        'a/uplay/tap-04-construction-menu.png', 'GS: construction menu (tape via USR 0)',
        'ne/play/tap-04-construction-menu.png',
        'The robot construction menu, reached by the same bot (play_gs.py) from the main menu: unchanged.'),
    'hang.png': (
        'a/tl-hang.png', 'GS: tape from the 128 menu\'s Tape Loader',
        'ne/play/tap-04-construction-menu.png',
        'The same bot input from the main menu. NE lands on its warbase and opens the construction menu. The GS '
        'tape started from the 128 menu\'s Tape Loader stops with the ship on the pad: its first sound calls $C000 '
        'in bank 6, which holds no driver on this route; the zeros run into HALT with interrupts off (PC $FFFA). '
        'The frame 500 frames later is the same.'),
}

BG, FG, DIM = (24, 24, 24), (235, 235, 235), (170, 170, 170)
PAD, GAP = 16, 16


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


def screen_diff(shots, left, right):
    """the number of differing pixels in the 256 x 192 screen areas of two raw frames"""
    box = (48, 48, 304, 240)
    a = Image.open(os.path.join(shots, left)).convert('RGB').crop(box)
    b = Image.open(os.path.join(shots, right)).convert('RGB').crop(box)
    d = ImageChops.difference(a, b).convert('L').point(lambda v: 255 if v else 0)
    return d.histogram()[255]


def figure(shots, left, title, right, caption):
    a, b = frame(shots, left), frame(shots, right)
    head, body = font(22), font(20)
    width = PAD * 2 + a.width + GAP + b.width
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    n = screen_diff(shots, left, right)
    note = ' The screen areas (the border aside) are pixel-identical.' if n == 0 else ''
    lines = wrap(probe, caption + note, body, width - 2 * PAD)
    top = PAD + 30
    height = top + a.height + PAD + len(lines) * 26 + PAD
    im = Image.new('RGB', (width, height), BG)
    d = ImageDraw.Draw(im)
    d.text((PAD, PAD), title, font=head, fill=FG)
    d.text((PAD + a.width + GAP, PAD), NE, font=head, fill=FG)
    im.paste(a, (PAD, top))
    im.paste(b, (PAD + a.width + GAP, top))
    y = top + a.height + PAD
    for line in lines:
        d.text((PAD, y), line, font=body, fill=DIM)
        y += 26
    return im, n


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--shots', default=os.path.join(ROOT, 'work', 'stage2', 'shots'))
    ap.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img', 'compare'))
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for out, (left, title, right, caption) in FIGURES.items():
        im, n = figure(a.shots, left, title, right, caption)
        im.save(os.path.join(a.out, out), optimize=True)
        print('%-18s %-40s %-38s diff %d px' % (out, left, right, n))


if __name__ == '__main__':
    main()
