#!/usr/bin/env python3
"""Sheets of screens from the case's recordings, each with its recording and frame, for doc 1:

    python3 tools/fig_screens.py docs/img/play/screens.png --set main        # c1 and the RZX run, menu to the end
    python3 tools/fig_screens.py docs/img/play/screens-more.png              # the load, the title, a fight, GAME OVER
    python3 tools/fig_screens.py docs/img/play/screens-moments.png --set moments  # the giants, a death, the pause

A picture is a recording's screens/FFFFFF-name.png (tools/record.py: the screen at the start of that frame, 512 x 384,
the 256 x 192 screen doubled, no border), a stage-1 RZX playback screen (work/stage1/rzx/fNNNNNN.png, 256 x 192), or
the screen of an RZX snapshot of stage 2 (work/stage2/rzx/snap-NNNNNN.z80, read with SkoolKit from $SKOOLKIT_VENV).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

REC = os.path.join(HERE, '..', 'work')
MORE = [
    ('stage1/rec/c48/screens/003232-loading-6.png', 'c48 3232: the loading screen (48K)'),
    ('stage1/rec/menu/screens/003915-cycle-1.png', 'menu 3915: the title, the logo builds up'),
    ('stage2/rec/play48/screens/000759-punch.png', 'play48 759: a punch (48K)'),
    ('stage1/rec/menu/screens/000110-title-1-left.png', 'menu 110: the title, left: music (the note)'),
    ('stage1/rec/menu/screens/000156-title-1-right.png', 'menu 156: the title, right: effects (FX)'),
    ('stage1/rec/c48/screens/020701-intro-1.png', 'c48 20701: the 48K story at the boot'),
    ('stage2/rec/play48/screens/002219-fight-6.png', 'play48 2219: a fight (48K)'),
    ('stage1/rec/gameover/screens/002429-walk-03.png', 'gameover 2429: GAME OVER (lives poked to 0)'),
    ('stage1/rec/gameover/screens/006729-after.png', 'gameover 6729: the table, no entry'),
]


MAIN = [
    ('stage1/c1/screens/016008-menu.png', 'c1 16008: the menu (controls)'),
    ('stage1/c1/screens/016072-title-4.png', 'c1 16072: the title, option 4'),
    ('stage1/c1/screens/016577-intro-2.png', 'c1 16577: the 128K story'),
    ('stage1/c1/screens/017477-play-start.png', 'c1 17477: the story, Hiro'),
    ('stage1/c1/screens/017797-kick.png', 'c1 17797: play, room 4 (the surface)'),
    ('stage1/rzx/f60000.png', 'RZX 60000: room 61, the Undercity'),
    ('stage1/rzx/late/f136000.png', 'RZX 136000: Havok, room 123'),
    ('stage1/rzx/late/f139000.png', 'RZX 139000: room 123, Havok fading'),
    ('stage1/rzx/late/f140000.png', 'RZX 140000: the end text'),
    ('stage1/rzx/late/f142000.png', 'RZX 142000: the high-score entry'),
    ('stage1/rzx/late/f142500.png', 'RZX 142500: back to the title'),
]
MOMENTS = [
    ('stage2/rec/play48/screens/000669-right-1.png', 'play48 669: room 5 and its patroller (48K)'),
    ('stage1/rec/deaths/screens/003149-walk-11.png', 'deaths 3149: a life lost, lives 04 to 03'),
    ('stage1/rec/menu/screens/002035-pause-1.png', 'menu 2035: paused (P): no banner'),
    ('stage2/rzx/snap-026000.z80', 'RZX 26000: the giant of room 39'),
    ('stage2/rec/bossgate/screens/000420-boss.png', 'bossgate 420: the giant of room 58'),
    ('stage2/rec/bossgate/screens/000492-gate-gone.png', 'bossgate 492: room 58, giant and gate gone'),
    ('stage2/rzx/snap-088000.z80', 'RZX 88000: the giant of room 112'),
    ('stage2/rzx/snap-114000.z80', 'RZX 114000: the giant of room 93'),
    ('stage2/rec/throw/screens/001921-spinblade-0-flying.png', 'throw 1921: a spinblade thrown'),
]
SETS = {'more': (MORE, 'More screens from our recordings: the load, the title, the 128K sound sign, the 48K story, '
                       'a fight, GAME OVER'),
        'main': (MAIN, 'Screens from c1 (128K) and the RZX run (48K): the menu, the title, the story, play, Havok, '
                       'the end, the name entry'),
        'moments': (MOMENTS, 'Moments of play: an enemy, a death, the pause, the four giants, a giant beaten, a throw')}


def snapshot_screen(path):
    venv = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
    for d in os.listdir(os.path.join(venv, 'lib')):
        sys.path.insert(0, os.path.join(venv, 'lib', d, 'site-packages'))
    from skoolkit.snapshot import Snapshot
    ram = Snapshot.get(path).ram(-1)
    return K.render_screen(bytearray(0x4000) + bytearray(ram[:0xC000]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--set', default='more', choices=sorted(SETS))
    a = ap.parse_args()
    out = a.out
    SHOTS, title = SETS[a.set]
    W, cols = (1056, 4) if len(SHOTS) > 9 else (1050, 3)
    tw = W // cols
    th = tw * 3 // 4
    lab = 18
    rows = (len(SHOTS) + cols - 1) // cols
    sheet = Image.new('RGB', (W, 30 + rows * (th + lab)), (16, 16, 20))
    d = ImageDraw.Draw(sheet)
    d.text((8, 6), title, fill='white', font=K.font(14))
    for i, (path, label) in enumerate(SHOTS):
        r, c = divmod(i, cols)
        x, y = c * tw, 30 + r * (th + lab)
        full = os.path.join(REC, path)
        im = snapshot_screen(full) if path.endswith('.z80') else Image.open(full).convert('RGB')
        im = im.resize((tw - 4, th - 3), Image.LANCZOS)
        sheet.paste(im, (x + 2, y))
        d.text((x + 4, y + th - 1), label, fill=(210, 210, 210), font=K.font(12))
    sheet.save(out)
    print(out, sheet.size)


if __name__ == '__main__':
    main()
