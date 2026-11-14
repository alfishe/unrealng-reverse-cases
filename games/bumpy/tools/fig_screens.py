#!/usr/bin/env python3
"""Doc 01's sheet of every screen, from the screenshots in docs/img/play (kit/screen_shot.py, each named
<recording>-<frame>-<what>.png):

  python3 tools/fig_screens.py

docs/img/play/screens.png: twelve screens, four a row at their Spectrum size (256 x 192, the shots are 2 x), each
captioned with its recording and frame.
"""
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
PLAY = os.path.join(CASE, 'docs', 'img', 'play')
SHOTS = [
    ('c1-010182-loading', 'the loading screen'), ('c1-013782-menu', 'the menu'),
    ('menu-001500-demo', 'the demo'), ('c1-014018-ready', 'READY?'),
    ('c1-015086-play', 'play: level 0'), ('rzx-l00-000971-exit-open', 'every prize taken: the exit'),
    ('l83-000650-count', 'the level end: counting'), ('twoname-000200-two-ready', 'two players'),
    ('gameover-000602-life-lost', 'a life lost (S)'), ('twoname-003300-name', 'the name entry'),
    ('gameover-004618-hall-of-fame', 'the hall of fame'), ('menu-005820-pause', 'the pause'),
]
W, H, PAD, CAP = 256, 192, 4, 36


def font(size):
    for f in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Supplemental/Arial.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def main():
    cols = 4
    rows = (len(SHOTS) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * (W + PAD) + PAD + 2, rows * (H + CAP + PAD) + PAD + 30), (14, 14, 20))
    d = ImageDraw.Draw(sheet)
    d.text((PAD, 6), 'Bumpy: every screen (kit/screen_shot.py stills, recording and frame under each)',
           fill=(210, 210, 220), font=font(15))
    for i, (name, what) in enumerate(SHOTS):
        r, c = divmod(i, cols)
        x, y = PAD + c * (W + PAD), 30 + PAD + r * (H + CAP + PAD)
        img = Image.open(os.path.join(PLAY, name + '.png')).convert('RGB').resize((W, H), Image.NEAREST)
        sheet.paste(img, (x, y))
        parts = name.split('-')
        k = next(j for j, t in enumerate(parts) if t.isdigit() and len(t) == 6)
        rec, frame = '-'.join(parts[:k]).replace('rzx-l', 'rzx/l').replace('l83', 'rec/l83'), int(parts[k])
        d.text((x, y + H + 2), what, fill=(240, 200, 70), font=font(14))
        d.text((x, y + H + 19), f'{rec} frame {frame}', fill=(150, 150, 165), font=font(13))
    sheet.save(os.path.join(PLAY, 'screens.png'))
    print('screens.png', sheet.size)


if __name__ == '__main__':
    main()
