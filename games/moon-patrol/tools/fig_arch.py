#!/usr/bin/env python3
"""The figures of doc 02 (architecture), 1050 pixels wide, into docs/img/arch/.

    python3 tools/fig_arch.py images   # the three images of c1 (loaded 252, entry 256, play 8000) side by side,
                                       # over the four windows where they differ (work/images/, tools/images.py)
    python3 tools/fig_arch.py stages   # the program's states from the entry to the hi-score entry, from the
                                       # screenshots of docs/img/play/, each with its routine and interrupt mode

The interrupt mode of each state is from the code: SetIm2 $A7D4 is called only by LifeStart ($9132) and by the end
of the hold ($AF0E); every other state runs in IM 1 (SetIm1 $A7CB). Doc 04 4.3 has the witnesses.
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig_design import BG, F13, F14B, F16B, GREY, INK, WIDTH, shot  # noqa: E402

CASE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(CASE, 'docs', 'img', 'arch')
IM = {1: (60, 110, 210), 2: (40, 160, 80)}

STAGES = [
    ('a1-title.png', 1, '1 TitlePage $8004', 'entered from MenuEntry $8000', 'a1 100'),
    ('a1-options.png', 1, '2 OptionsPage $8064', 'one of five menu pages', 'a1 700'),
    ('a1-player1.png', 1, '3 GameStart $8F10', 'the banner: 100 HALTs', 'a1 1330'),
    ('a1-play-beginner.png', 2, '4 MainLoop $9696', 'LifeStart set IM 2', 'a1 1700'),
    ('i1-bonus-e.png', 1, '5 SectorBonus $A4EE', 'back: LifeStart, JP MainLoop', 'i1 5400'),
    ('a1-hold.png', 1, '6 HoldCheck $AECE', 'H, S or fire: SetIm2', 'a1 2100'),
    ('g1-game-over.png', 1, '7 GameAfterLife $8F9F', 'GAME OVER: 200 HALTs', 'g1 3950'),
    ('g1-heroes-entry.png', 1, '8 HiScoreEntry', 'keys from the ROM: LAST_K', 'g1 4300'),
]


def stages():
    cols, gap, cw, ch = 4, 8, 256, 192
    cap = 62
    top = 52
    left = (WIDTH - cols * cw - (cols - 1) * gap) // 2
    rows = (len(STAGES) + cols - 1) // cols
    img = Image.new('RGB', (WIDTH, top + rows * (ch + cap + gap) + 30), BG)
    d = ImageDraw.Draw(img)
    d.text((left, 6), "The program's states and their interrupt mode (the band under each screen)", font=F16B,
           fill=INK)
    d.rectangle((left, 30, left + 16, 44), fill=IM[1])
    d.text((left + 22, 30), 'IM 1: the ROM handler at $0038 (FRAMES, the keyboard scan)', font=F13, fill=INK)
    d.rectangle((left + 520, 30, left + 536, 44), fill=IM[2])
    d.text((left + 542, 30), 'IM 2: Im2Handler $7F14 (FRAMES, tune, clock)', font=F13, fill=INK)
    for i, (png, im, l1, l2, frame) in enumerate(STAGES):
        x = left + (i % cols) * (cw + gap)
        y = top + (i // cols) * (ch + cap + gap)
        img.paste(shot(png), (x, y))
        d.rectangle((x, y + ch, x + cw - 1, y + ch + 6), fill=IM[im])
        d.text((x, y + ch + 9), l1, font=F14B, fill=INK)
        d.text((x, y + ch + 26), l2, font=F13, fill=INK)
        d.text((x, y + ch + 43), '%s, IM %d' % (frame, im), font=F13, fill=GREY)
    d.text((left, img.height - 22), 'python3 tools/fig_arch.py stages     (screens: docs/img/play/, the frame under '
           'each)', font=F13, fill=GREY)
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, 'stages.png')
    img.save(out)
    print(out, img.size)


# the windows of the image where the three images differ (work/stage1/images-diff.txt), 16 bytes a row
WINDOWS = [(0xB210, 12, 'game variables, player records'), (0xBEF0, 3, 'the object list'),
           (0xC2F0, 6, 'the stack'), (0xF000, 3, 'print variables'), (0xF0A0, 1, '')]
IMAGES = [('loaded-252-0.bin', 'loaded: c1 frame 252, T 0'), ('entry-256-58497.bin', 'entry: c1 256, T 58 497'),
          ('play-8000-0.bin', 'play: c1 frame 8000')]
CHG = [None, (255, 214, 102), (250, 160, 90)]


def images():
    mem = [open(os.path.join(CASE, 'work', 'images', f), 'rb').read() for f, _ in IMAGES]
    cw, rh, adw, gap = 19, 17, 52, 14
    pw = 16 * cw
    left = (WIDTH - adw - 3 * pw - 2 * gap) // 2
    top = 74
    rows = sum(n for _, n, _ in WINDOWS) + len(WINDOWS)
    img = Image.new('RGB', (WIDTH, top + rows * rh + 60), BG)
    d = ImageDraw.Draw(img)
    d.text((left, 8), 'The three images of c1 side by side: only the stack, the variables, the first objects and '
           'the print state change', font=F14B, fill=INK)
    d.rectangle((left, 32, left + 14, 46), fill=CHG[1])
    d.text((left + 20, 32), 'changed from loaded to entry (the BASIC\'s stack)', font=F13, fill=INK)
    d.rectangle((left + 450, 32, left + 464, 46), fill=CHG[2])
    d.text((left + 470, 32), 'changed from entry to play', font=F13, fill=INK)
    counts = [0, 0, 0]
    for k, (_, title) in enumerate(IMAGES):
        d.text((left + adw + k * (pw + gap), 54), title, font=F14B, fill=INK)
    y = top
    for base, n, label in WINDOWS:
        d.text((left, y + 2), label, font=F13, fill=GREY)
        y += rh
        for r in range(n):
            a0 = base + 16 * r
            d.text((left, y + 2), '$%04X' % a0, font=F13, fill=GREY)
            for k in range(3):
                x0 = left + adw + k * (pw + gap)
                for c in range(16):
                    a = a0 + c
                    v = mem[k][a]
                    x = x0 + c * cw
                    if k and v != mem[k - 1][a]:
                        d.rectangle((x, y, x + cw - 2, y + rh - 2), fill=CHG[k])
                        counts[k] += 1
                    d.text((x + 1, y + 2), '%02X' % v, font=F13, fill=INK if v else GREY)
            y += rh
    d.text((left, y + 8), 'changed bytes in the windows: %d loaded to entry, %d entry to play (all of the image\'s '
           '26 and 174)' % (counts[1], counts[2]), font=F13, fill=INK)
    d.text((left, y + 28), 'python3 tools/fig_arch.py images     (work/images/*.bin from tools/images.py)',
           font=F13, fill=GREY)
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, 'images.png')
    img.save(out)
    print(out, img.size, counts)


if __name__ == '__main__':
    figs = {'stages': stages, 'images': images}
    for name in (sys.argv[1:] or ['stages']):
        figs[name]()
