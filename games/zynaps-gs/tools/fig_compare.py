#!/usr/bin/env python3
"""Side-by-side figures for docs/img/compare/: the GS conversion (left) against the 48K Zynaps (right), or two GS
moments, from real emulator frames. The GS frames (352 x 288, unreal-qt screenshots) are cut to the 256 x 192
screen; the 48K frames are the 48K case's screen captures (512 x 384, the screen scaled 2x). Both are shown at 2x with
nearest neighbour, a title over each and a caption under both. The number of screen pixels lit in one and black in
the other is measured (the palettes differ) and stated where it is 0.

    python3 tools/fig_compare.py [--shots work/stage2/shots] [--out docs/img/compare]

The frames in work/stage2/shots (copies, so that the figures do not depend on the order of the captures):
    gs-options.png, gs-credits.png, gs-hiscore.png, gs-picture.png, gs-level1.png: work/stage1/screens (stage 1)
    gs-options-hidden.png: work/stage2/menu/m2-key8.png (fresh boot, keys 0 and 8 in the menu)
    gs-level5.png: work/stage2/menu/b4-play.png (keys 0, T, 1, then 2 and fire on the title: 500 frames into play)
    z48-*.png: ../zynaps/work/explore t0.png, t6.png, s1.png (the 48K case's captures; s1.png is level 1 in play)
"""
import argparse
import os

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# output: (left frame, left title, right frame, right title, caption)
FIGURES = {
    'start.png': (
        'gs-options.png', 'GS: the first screen after the loading screen',
        'z48-credits.png', '48K: the first screen after the tape',
        'The GS disk stops at its options menu (ZYNAPS OPTIONS) before the game is installed; key 1 starts with '
        'music and effects, key 2 with effects only. The 48K tape goes straight into the title pages.'),
    'menu-hidden.png': (
        'gs-options.png', 'GS: the options menu as shown',
        'gs-options-hidden.png', 'GS: after keys 0 and 8',
        'Key 0 is not listed. It turns the end of the menu text into an AT code, so the two hidden lines print, '
        'and turns on key 8 (INFINITE LIFE, here toggled to YES) and the level keys Q-P, A, S (SELECT LEVEL).'),
    'credits.png': (
        'gs-credits.png', 'GS: the credits page',
        'z48-credits.png', '48K: the credits page',
        'The credits page is the 48K\'s with one message changed: "MUSIC / STEVE TURNER" became '
        '"PRESS / 1,2,3 & FIRE" (message 21); the music is now the card\'s modules.'),
    'hiscore.png': (
        'gs-hiscore.png', 'GS: the high-score page',
        'z48-hiscore.png', '48K: the high-score page',
        'The high-score page is the 48K\'s. The chains turn and the logos cycle their colours, so two frames of '
        'it match only at the same phase: these two differ in phase.'),
    'title-picture.png': (
        'gs-picture.png', 'GS: between the title pages',
        'z48-credits.png', '48K: the title loop goes back to the credits',
        'The GS points the title loop\'s jump at its title stub, which shows the loading screen (kept in bank 7) '
        'between the rounds of title pages. Its bytes are the 48K tape\'s loading screen, byte for byte; the 48K '
        'shows that picture only while the tape loads.'),
    'select-level.png': (
        'gs-level5.png', 'GS: SELECT LEVEL key T (level 5)',
        'gs-level1.png', 'GS: a normal start (level 1)',
        'With key 0 then T in the menu, the game starts on level 5 (the driver loads level 5\'s module; the '
        'level index of the player record stays 0). The key writes LD B,5 over LD B,(HL) / INC B at $B073, which '
        'runs at every level start, so every level after a completed one is level 5 again.'),
    'play-level1.png': (
        'gs-level1.png', 'GS: level 1 in play',
        'z48-level1.png', '48K: level 1 in play',
        'The play screen is the 48K\'s: the same renderer, panel and sprites at the same addresses; the GS adds no '
        'graphics. The two frames are other moments of level 1, so the scenery, the score and the panel\'s '
        'gauges differ.'),
}

BG, FG, DIM = (24, 24, 24), (235, 235, 235), (170, 170, 170)
PAD, GAP = 16, 16


def font(size):
    return ImageFont.load_default(size=size)


def screen(shots, name):
    """the 256 x 192 screen of a frame"""
    im = Image.open(os.path.join(shots, name)).convert('RGB')
    if im.size == (352, 288):
        return im.crop((48, 48, 304, 240))
    if im.size == (512, 384):
        return im.resize((256, 192), Image.NEAREST)
    raise SystemExit('%s: unexpected frame size %s' % (name, im.size))


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


def figure(shots, left, ltitle, right, rtitle, caption):
    sa, sb = screen(shots, left), screen(shots, right)
    # the two emulators' captures use different palettes: the lit pixels (not black) are compared
    ma, mb = (x.convert('L').point(lambda v: 255 if v else 0) for x in (sa, sb))
    n = ImageChops.difference(ma, mb).histogram()[255]
    a, b = sa.resize((512, 384), Image.NEAREST), sb.resize((512, 384), Image.NEAREST)
    head, body = font(20), font(18)
    width = PAD * 2 + a.width + GAP + b.width
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    note = ' The lit pixels of the two screens are identical.' if n == 0 else ''
    lines = wrap(probe, caption + note, body, width - 2 * PAD)
    top = PAD + 30
    height = top + a.height + PAD + len(lines) * 24 + PAD
    im = Image.new('RGB', (width, height), BG)
    d = ImageDraw.Draw(im)
    d.text((PAD, PAD), ltitle, font=head, fill=FG)
    d.text((PAD + a.width + GAP, PAD), rtitle, font=head, fill=FG)
    im.paste(a, (PAD, top))
    im.paste(b, (PAD + a.width + GAP, top))
    y = top + a.height + PAD
    for line in lines:
        d.text((PAD, y), line, font=body, fill=DIM)
        y += 24
    return im, n


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--shots', default=os.path.join(ROOT, 'work', 'stage2', 'shots'))
    ap.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img', 'compare'))
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for out, (left, ltitle, right, rtitle, caption) in FIGURES.items():
        im, n = figure(a.shots, left, ltitle, right, rtitle, caption)
        im.save(os.path.join(a.out, out), optimize=True)
        print('%-18s %-24s %-24s diff %d px' % (out, left, right, n))


if __name__ == '__main__':
    main()
