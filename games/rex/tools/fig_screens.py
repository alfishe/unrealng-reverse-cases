#!/usr/bin/env python3
"""Sheets of the game's screens for doc 1: each tile a screenshot taken from a recording (kit/screen_shot.py, the
PNGs named below) or a screen of src/res, captioned with the recording and its frame.

    python3 tools/fig_screens.py [--shots work/docs/rxA/shots] [--demo work/docs/rxA/demo]

writes docs/img/play/screens-part1.png, screens-part2.png and screens-demo.png: three tiles a row, 1050 px wide.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

C = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.join(C, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

PLAY = 'docs/img/play/'
SHEETS = {
    'screens-part1': ('REX 1 (side 1, part 1): from the load to the CODE panel', [
        ('src/res/screens/rex1.png', 'loading screen: side 1 block 4'),
        (PLAY + 'c1-000250-menu.png', 'title, menu, roll call: c1 250'),
        (PLAY + 'c1-000750-define.png', 'DEFINE: c1 750'),
        (PLAY + 'c1-001000-phase-one.png', 'PHASE ONE: c1 1000'),
        (PLAY + 'c1-001500-room0.png', 'room 0, the start: c1 1500'),
        ('{shots}/s1400.png', 'station, room 1: rzx-p1-00000 1400'),
        (PLAY + 'rzx-p1-31000-play.png', 'room 13: rzx-p1-30000 1000'),
        ('{shots}/go500.png', 'GAME OVER: p1-gameover 500'),
        ('{shots}/code1000.png', 'room 99, CODE: p1-code 1000'),
    ]),
    'screens-part2': ('REX 2 (side 1, part 2): the code, the Living Tower, the end', [
        ('src/res/screens/rex2.png', 'loading screen: side 1 block 10'),
        (PLAY + 'c2-001750-invalid-code.png', 'INVALID CODE: c2 1750'),
        (PLAY + 'c2-003250-code.png', 'the code from rex1.rzx: c2 3250'),
        (PLAY + 'rzx-p2-00500-phase-two.png', 'PHASE TWO: rzx-p2-00000 500'),
        (PLAY + 'rzx-p2-01000-room0.png', 'room 0: rzx-p2-00000 1000'),
        (PLAY + 'c2-004250-part2.png', 'room 0, score carried: c2 4250'),
        (PLAY + 'rzx-p2-21000-play.png', 'the tower: rzx-p2-20000 1000'),
        (PLAY + 'c1-004000-game-over.png', 'GAME OVER (part 1\'s): c1 4000'),
        (PLAY + 'rzx-p2-41500-ending.png', 'the ending: rzx-p2-40000 1500'),
    ]),
    'screens-demo': ('DEMO (side 2): the tutor', [
        ('src/res/screens/demo.png', 'loading screen: side 2 block 4'),
        (PLAY + 'd1-005500-tutor.png', 'room 4, prologue: d1 5500'),
        ('{demo}/d4750.png', 'room 1, weapons: demo-cycle 4750'),
        ('{demo}/d5250.png', 'power status: demo-cycle 5250'),
        ('{demo}/d12250.png', 'room 0: demo-cycle 12250'),
        ('{demo}/d14500.png', 'room 2, guideline: demo-cycle 14500'),
    ]),
}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--shots', default='work/docs/rxA/shots')
    p.add_argument('--demo', default='work/docs/rxA/demo')
    a = p.parse_args()
    tile_w, tile_h, cap, gap, cols, head = 336, 252, 24, 13, 3, 34
    font, small = K.font(16), K.font(15)
    for name, (title, tiles) in SHEETS.items():
        rows = (len(tiles) + cols - 1) // cols
        out = Image.new('RGB', (1050, head + rows * (tile_h + cap + gap)), (24, 24, 30))
        d = ImageDraw.Draw(out)
        d.text((10, 8), title, fill=(240, 240, 240), font=font)
        for i, (path, label) in enumerate(tiles):
            path = os.path.join(C, path.format(shots=a.shots, demo=a.demo))
            im = Image.open(path).convert('RGB')
            im = im.resize((512, 384), Image.NEAREST).resize((tile_w, tile_h), Image.LANCZOS)
            x = 10 + (i % cols) * (tile_w + gap)
            y = head + (i // cols) * (tile_h + cap + gap)
            out.paste(im, (x, y))
            d.text((x, y + tile_h + 3), label, fill=(220, 220, 220), font=small)
        path = os.path.join(C, 'docs/img/play', name + '.png')
        out.save(path)
        print(path, out.size)


if __name__ == '__main__':
    sys.exit(main())
