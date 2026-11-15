#!/usr/bin/env python3
"""Doc 1's screen figures, from the screenshots of the recordings in docs/img/play (each taken by kit/screen_shot.py
or rendered from a recording's saved screen):

    python3 tools/fig_screens.py      # docs/img/design/screens.png (every screen and mode) and hud.png (the panel)
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

PLAY = os.path.join(CASE, 'docs', 'img', 'play')
OUT = os.path.join(CASE, 'docs', 'img', 'design')
BG, FG, DIM, MARK = (24, 24, 30), (235, 235, 235), (175, 175, 185), (255, 90, 90)

SCREENS = [
    ('c1-03000-loading-screen.png', '1 the loading screen', 'c1 frame 3000'),
    ('c1-17750-menu.png', '2 the menu', 'c1 frame 17750'),
    ('c1-17850-define-keys.png', '3 DEFINE KEYS', 'c1 frame 17850'),
    ('play2-000500-password-mayhem.png', '4 ENTER PASSWORD', 'play2 frame 500'),
    ('c1-18400-start-pod.png', '5 the start: Matt in the pod', 'c1 frame 18400'),
    ('c1-18600-pickups.png', '6 zone 0, the surface: P and BL lie', 'c1 frame 18600'),
    ('rzx-12000-0250-cavern.png', '7 zone 1, the caverns', 'rzx-12000 frame 250'),
    ('rzx-28000-0250-moon.png', '8 zone 2, the moon', 'rzx-28000 frame 250'),
    ('rzx-00000-3000-room10-base.png', '9 zone 3, the base (room 10)', 'rzx-00000 frame 3000'),
    ('door-000750-four-doors.png', '10 room 0, screen 5: the doors', 'door frame 750'),
    ('rzx-00000-1500-first-enemies.png', '11 enemies and a turret, room 0', 'rzx-00000 frame 1500'),
    ('rzx-28000-0750-mission-terminated.png', '12 MISSION TERMINATED', 'rzx-28000 frame 750'),
    ('rzx-28000-3250-menu-hiscore.png', '13 the menu, HISCORE 00019090', 'rzx-28000 frame 3250'),
    ('rzx-36000-0250-found-scott.png', '14 the end: YOU HAVE FOUND SCOTT', 'rzx-36000 frame 250'),
    ('play2-006500-well-done.png', '15 the end: WELL DONE', 'play2 frame 6500'),
]

# the panel, character rows 18-23 of the play screen: (x0, y0, x1, y1) in characters, the label, where it goes
HUD = [
    ((0, 18, 13, 21), 'MASK: the four slots, icon and charges (keys 1-4)', 'above'),
    ((13, 18, 22, 21), 'ENERGY: 8 cells, 255 full', 'above'),
    ((22, 18, 32, 21), 'SCORE: 8 digits', 'above'),
    ((0, 21, 13, 24), 'INFO: the message line (row 23)', 'below'),
    ((22, 21, 32, 24), 'the title panel', 'below'),
]


def screens():
    big, small = kitlib.font(16), kitlib.font(14)
    cols, w, h = 3, 336, 252
    cell_h = h + 48
    rows = (len(SCREENS) + cols - 1) // cols
    im = Image.new('RGB', (1050, 40 + rows * cell_h), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), 'MASK III: every screen and mode, from the recordings (frame numbers as each was loaded, '
                     'WALKTHROUGH 6.0)', fill=FG, font=big)
    for i, (name, title, where) in enumerate(SCREENS):
        r, c = divmod(i, cols)
        x, y = 10 + c * (w + 11), 40 + r * cell_h
        pic = Image.open(os.path.join(PLAY, name)).convert('RGB').resize((w, h), Image.NEAREST)
        d.text((x, y + 2), title, fill=FG, font=big)
        d.text((x, y + 22), where, fill=DIM, font=small)
        im.paste(pic, (x, y + 44))
    return im


def hud():
    big, small = kitlib.font(16), kitlib.font(15)
    shot = Image.open(os.path.join(PLAY, 'c1-19300-backlash-taken.png')).convert('RGB')
    scale = 3
    sw = shot.width // 256 * 1
    panel = shot.crop((0, 18 * 8 * sw, 256 * sw, 24 * 8 * sw)).resize((256 * scale, 48 * scale), Image.NEAREST)
    top, left = 120, (1050 - 256 * scale) // 2
    im = Image.new('RGB', (1050, top + panel.height + 120), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), 'The play panel (character rows 18-23), c1 frame 19300 (128K): BACKLASH taken, 99 charges',
           fill=FG, font=big)
    im.paste(panel, (left, top))
    above_y, below_y = 46, top + panel.height + 18
    for k, ((x0, y0, x1, y1), label, side) in enumerate(HUD):
        bx0, by0 = left + x0 * 8 * scale, top + (y0 - 18) * 8 * scale
        bx1, by1 = left + x1 * 8 * scale - 1, top + (y1 - 18) * 8 * scale - 1
        d.rectangle((bx0, by0, bx1, by1), outline=MARK, width=2)
        cx = (bx0 + bx1) // 2
        tw = d.textlength(label, font=small)
        tx = max(6, min(1044 - tw, cx - tw / 2))
        if side == 'above':
            ty = above_y + (k % 2) * 30
            d.line((cx, ty + 20, cx, by0), fill=MARK, width=1)
        else:
            ty = below_y + (k % 2) * 30
            d.line((cx, by1, cx, ty), fill=MARK, width=1)
        d.text((tx, ty), label, fill=MARK, font=small)
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    screens().save(os.path.join(OUT, 'screens.png'))
    hud().save(os.path.join(OUT, 'hud.png'))
    print(OUT, 'screens.png, hud.png')


if __name__ == '__main__':
    main()
