#!/usr/bin/env python3
"""Doc 04 figure: ANE's states as the player meets them, one screen each, with the interrupt handler and the tune
that run in it.

    python3 tools/fig_states.py --out docs/img/loop/states.png

The screens are PNGs taken from the recordings with kit/screen_shot.py (d1: work/docR/shots2, stage 3's r1, r3, r4:
work/stage3/*/screens-rec); the list below names each file, its recording and frame, and what runs.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

CASE = os.path.join(HERE, '..')
D1, S3 = 'work/docR/shots2', 'work/stage3'
ROWS = [
    ('the boot: intro, title, boot menu, help (the boot program, before the game exists)', [
        (f'{D1}/eternity.png', 'intro: Eternity logo', 'd1 2700', 'LoaderInterrupt $6161; MAD NIGHT'),
        (f'{D1}/presents.png', 'Presents', 'd1 3350', 'LoaderInterrupt; MAD NIGHT'),
        (f'{D1}/star.png', 'star + scroller', 'd1 5000', 'LoaderInterrupt; MAD NIGHT'),
        (f'{D1}/title.png', 'title picture (load)', 'd1 8400', 'IM 1 (ROM); silent while the disk loads'),
        (f'{D1}/boot.png', 'boot menu', 'd1 8690', 'IM 2 $6060 (boot program); TOMY'),
        (f'{S3}/r1/screens-rec/p9429.png', 'help, a page', 'r1 9429', 'IM 2 $6060 (boot program); TOMY'),
    ]),
    ('the game: title cards, the game menu, play (the game image, bank 1 music)', [
        (f'{D1}/card1.png', 'card 1', 'd1 8900', 'IM 1 (ROM); silent'),
        (f'{D1}/card2.png', 'card 2', 'd1 9050', 'IM 1 (ROM); silent'),
        (f'{D1}/card3.png', 'card 3', 'd1 9150', 'IM 1 (ROM); silent'),
        (f'{D1}/menu.png', 'game menu', 'd1 9216', 'MusicInterrupt $6780; TAIGA'),
        (f'{D1}/play.png', 'play', 'd1 13020', 'PlayInterrupt $D566 + PlayMusic; TAIGA'),
    ]),
    ('the ends: Dead End (back to the game menu) and Final Cut (never returns)', [
        (f'{S3}/r3/screens-rec/f100.png', 'Dead End', 'r3 100', 'bank 3 $FDFD; NETHER EARTH (END)'),
        (f'{S3}/r3/screens-rec/f900.png', 'GAME OVER, stars', 'r3 900', 'bank 3 $FDFD; NETHER EARTH (END)'),
        (f'{S3}/r4/screens-rec/f100.png', 'Final Cut: the base', 'r4 100', 'Final Cut $6060; REM'),
        (f'{S3}/r4/screens-rec/f2000.png', 'scroller + alien', 'r4 2000', 'Final Cut $6060; REM'),
        (f'{S3}/r4/screens-rec/f4000.png', 'GAME OVER', 'r4 4000', 'Final Cut $6060; REM'),
        (f'{S3}/r4/screens-rec/f5000.png', 'Victory is with U!!!', 'r4 5000', 'Final Cut $6060; REM'),
    ]),
]
BG, FG, DIM, ACC = (21, 22, 27), (232, 232, 238), (184, 188, 200), (217, 164, 65)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', required=True)
    args = p.parse_args()
    tw, th = 256, 192
    gap, cap = 14, 54
    cols = max(len(r[1]) for r in ROWS)
    W = gap + cols * (tw + gap)
    head = 30
    rh = head + th + cap + gap
    H = 50 + len(ROWS) * rh + 26
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((gap, 12), 'ANE\'s states in the order a player meets them: what each shows, which interrupt handler and '
                      'which tune run in it', fill=FG, font=K.font(18))
    y = 50
    for title, items in ROWS:
        d.text((gap, y + 4), title, fill=ACC, font=K.font(15))
        for i, (path, name, where, runs) in enumerate(items):
            x = gap + i * (tw + gap)
            img = Image.open(os.path.join(CASE, path)).convert('RGB')
            img = img.resize((tw, th), Image.NEAREST)
            out.paste(img, (x, y + head))
            if i:
                d.text((x - gap + 1, y + head + th // 2 - 8), '>', fill=ACC, font=K.font(16))
            d.text((x, y + head + th + 4), f'{name}  ({where})', fill=FG, font=K.font(13))
            d.text((x, y + head + th + 22), runs, fill=DIM, font=K.font(12))
        y += rh
    d.text((gap, H - 22), 'd1: work/docR/d1 (frames of its TTD recording); r1, r3, r4: stage 3\'s recordings '
                          '(r3, r4 frames from their snapshots). Arrows: the order of the states, not every transition '
                          '(the state diagram in the text has them all).', fill=DIM, font=K.font(12))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    out.save(args.out)
    print(f'{args.out}: {W} x {H}')


if __name__ == '__main__':
    main()
