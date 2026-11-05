#!/usr/bin/env python3
"""The figures of the programs around the game (docs 01, 05, 08): the intro and its scroller, the boot menu, the help
program's pages, the disk module's save and load screens. Drawn from stage 3's recordings (work/stage3/r1: power-on,
the intro, the boot menu, all 28 help pages, the game menu; work/stage3/r2: a disk save and two loads), each opened
on an own instance (re_session.py open), the screens read with TTD memory_at.

    python3 tools/fig_programs.py sample --rec r1 [--port-base 12910]   work/docP/r1/samples.bin: the bank 5 and
                                                                         bank 7 screens every 4 frames
    python3 tools/fig_programs.py sample --rec r2 ...
    python3 tools/fig_programs.py draw                                   docs/img/boot/*.gif, *.png

Recording frame = input-script frame + 1602 (work/stage3/NOTES.md). Both screen pages are sampled (bank 5 and
bank 7); every figure shows bank 5: it matches stage 3's own shots of the intro (work/stage3/r1/screens-intro), and
in r2 the disk module, the play screen and the menus all draw there. Bank 7 holds only a layer of the intro's
picture (2200-2900) and then other data.
"""
import argparse
import os
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

UNREAL = '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/wt-ane-stage1'
BINARY = os.path.join(UNREAL, 'cmake-build-agent-release/bin/unreal-qt.app/Contents/MacOS/unreal-qt')
WORK = os.path.join(CASE, 'work', 'docP')
OUT = os.path.join(CASE, 'docs', 'img', 'boot')
BG, FG, DIMC = K.BACKGROUND, K.TEXT, K.DIM
ACCENT = (255, 200, 80)
WINDOWS = {'r1': (1600, 21740, 4), 'r2': (6500, 10800, 4)}


def text(d, xy, s, size=12, fill=FG, anchor='la'):
    d.text(xy, s, font=K.font(size), fill=fill, anchor=anchor)


def cmd_sample(args):
    work = os.path.join(WORK, args.rec)
    os.makedirs(work, exist_ok=True)
    ttd = os.path.join(CASE, 'work', 'stage3', args.rec, 'session.ttd')
    rs = os.path.join(UNREAL, 'tools', 'verification', 'analysis', 're_session.py')
    subprocess.run([sys.executable, rs, 'open', '--work', work, '--ttd', ttd, '--model', 'PENTAGON', '--binary',
                    BINARY, '--port-base', str(args.port_base)], check=True)
    sys.path.insert(0, os.path.dirname(rs))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    f0, f1, step = WINDOWS[args.rec]
    try:
        with open(os.path.join(work, 'samples.bin'), 'wb') as f:
            for frame in range(f0, f1, step):
                pages = []
                for page in (5, 7):
                    r = s.call('time_travel', {'action': 'memory_at', 'space': 'ram', 'frame': frame, 'tinframe': 0,
                                               'offset': page * 0x4000, 'length': 6912}, ok=False)
                    body = r.structured or {}
                    if r.is_error or 'hex' not in body:
                        raise SystemExit(f'memory_at {frame}: {r.text}')
                    pages.append(bytes.fromhex(body['hex']))
                f.write(frame.to_bytes(4, 'little') + pages[0] + pages[1])
                if frame % 1000 == 0:
                    print(frame, flush=True)
    finally:
        subprocess.run([sys.executable, rs, 'stop', '--work', work])


def load(rec):
    raw = open(os.path.join(WORK, rec, 'samples.bin'), 'rb').read()
    n = 4 + 2 * 6912
    out = {}
    for at in range(0, len(raw), n):
        out[int.from_bytes(raw[at:at + 4], 'little')] = (raw[at + 4:at + 4 + 6912], raw[at + 4 + 6912:at + n])
    return out


def shown_pages(samples):
    """frame -> the screen page the figures show: bank 5 (see the module's note)"""
    return {f: 5 for f in samples}


def zx(mem):
    return K.render_screen(mem, 0)


def labeller(events):
    def label(frame):
        name = ''
        for f, n in events:
            if f <= frame:
                name = n
        return name
    return label


def gif(path, samples, frames, pages, label_of, title, delay=60, scale=2):
    pictures, durations = [], []
    for frame in frames:
        page = pages[frame]
        img = zx(samples[frame][page == 7]).resize((256 * scale, 192 * scale), Image.NEAREST)
        pic = Image.new('RGB', (img.size[0], img.size[1] + 46), BG)
        pic.paste(img, (0, 0))
        d = ImageDraw.Draw(pic)
        text(d, (6, img.size[1] + 4), f'{title}  frame {frame}  (the screen in bank {page})', 12, DIMC)
        text(d, (6, img.size[1] + 22), label_of(frame), 14, ACCENT)
        pictures.append(pic)
        durations.append(delay)
    durations[0] = 1500
    durations[-1] = 2500
    K.save_gif(path, pictures, durations)
    print(f'{path}: {len(pictures)} pictures, {os.path.getsize(path) // 1024} KB')


def png(mem, path, scale=2):
    zx(mem).resize((256 * scale, 192 * scale), Image.NEAREST).save(path)
    print(path)


# r1, recording frames (script frame + 1602), from work/stage3/inputs/r1-help.txt and work/stage3/NOTES.md
R1_EVENTS = [(1600, 'the 128 menu, TR-DOS, RUN "A_NETHER" typed'), (2300, 'the intro: the Eternity Industry picture'),
             (3500, 'Presents, then the credits scroller'), (8202, 'SPACE: the intro ends'),
             (8250, 'the title picture, then the boot menu'), (8702, 'key 2: the help menu'),
             (9002, 'O, then A: the pointer moves to item 1'), (9082, 'SPACE: item 1, Описание игры'),
             (9432, 'ENTER: the next page'), (9782, 'ENTER: the next page'), (10132, 'ENTER: the next page')]
HELP_PAGES = [  # (frame, item, page): the frame 3 before each key, work/stage3/NOTES.md
    (9429, 1, 1), (9779, 1, 2), (10129, 1, 3), (10479, 1, 4), (10829, 1, 5),
    (11339, 2, 1), (11689, 2, 2), (12039, 2, 3), (12389, 2, 4),
    (12899, 3, 1), (13249, 3, 2), (13599, 3, 3), (13949, 3, 4), (14299, 3, 5), (14649, 3, 6), (14999, 3, 7),
    (15349, 3, 8),
    (15859, 4, 1), (16209, 4, 2), (16559, 4, 3),
    (17069, 5, 1), (17419, 5, 2), (17769, 5, 3), (18119, 5, 4), (18469, 5, 5),
    (18979, 6, 1), (19329, 6, 2), (19679, 6, 3)]
ITEMS = {1: 'Game description', 2: 'Robot production', 3: 'The components', 4: 'Programming robots',
         5: 'Game features', 6: 'Creditz'}
# the help menu: hit boxes at $AC14 (column, row, width in characters), routines at $AC2A (d05 image)
MENU = [(9, 7, 14, 0xAEDB, 'Описание игры', 'Game description', 5),
        (9, 9, 14, 0xAF44, 'Производство роботов', 'Robot production', 4),
        (9, 11, 14, 0xAFDD, 'Характеристика компонентов', 'The components', 8),
        (9, 13, 14, 0xAF9A, 'Программирование роботов', 'Programming robots', 3),
        (9, 15, 14, 0xAE67, 'Особенности игры', 'Game features', 5),
        (9, 17, 14, 0xAE21, 'Creditz', 'Credits', 3),
        (9, 19, 14, 0xAA8B, 'Выход', 'Exit: the boot menu', 0)]


def help_menu(mem, path):
    scale = 3
    zxim = zx(mem).resize((256 * scale, 192 * scale), Image.NEAREST)
    pic = Image.new("RGB", (256 * scale + 420, 192 * scale + 90), BG)
    pic.paste(zxim, (0, 62))
    d = ImageDraw.Draw(pic)
    text(d, (8, 6), 'The help menu: seven hit boxes ($AC14) the pointer must touch before SPACE', 17)
    text(d, (8, 32), 'r1 frame 9079; the boxes 14 characters wide from column 9; the routine of each from the table '
         'at $AC2A', 12, DIMC)
    for i, (col, row, width, routine, ru, en, pages) in enumerate(MENU):
        x0, y0 = col * 8 * scale, 62 + row * 8 * scale
        d.rectangle([x0, y0, x0 + width * 8 * scale - 1, y0 + 8 * scale - 1], outline=ACCENT, width=2)
        ly = 62 + row * 8 * scale + 2
        d.line([x0 + width * 8 * scale, y0 + 12, 256 * scale + 12, ly + 8], fill=ACCENT)
        text(d, (256 * scale + 16, ly - 4), f'{i + 1}  ${routine:04X}  {en}', 13, ACCENT)
        text(d, (256 * scale + 34, ly + 12), f'{ru}' + (f', {pages} pages' if pages else ''), 12, DIMC)
    px, py = 0xC3, 0x37
    d.ellipse([px * scale - 7, 62 + py * scale - 7, px * scale + 7, 62 + py * scale + 7], outline=(255, 90, 90),
              width=2)
    d.rectangle([px * scale - 330, 62 + py * scale - 30, px * scale - 8, 62 + py * scale - 12], fill=BG)
    text(d, (px * scale - 12, 62 + py * scale - 28), 'the pointer starts here: $AD60 = $37C3 (x 195, y 55)', 12,
         (255, 90, 90), anchor='ra')
    text(d, (8, 192 * scale + 86), 'here the pointer (the arrow) already stands on item 1: O, then A moved it', 12,
         DIMC, anchor='ld')
    pic.save(path)
    print(path)


def nearest(samples, frame):
    return min(samples, key=lambda f: abs(f - frame))


def cmd_draw(args):
    os.makedirs(OUT, exist_ok=True)
    r1 = load('r1')
    pages = shown_pages(r1)
    fr = sorted(r1)
    lab = labeller(R1_EVENTS)
    gif(os.path.join(OUT, 'intro.gif'), r1, [f for f in fr if 2200 <= f <= 8320 and f % 40 == 0], pages, lab, 'r1')
    gif(os.path.join(OUT, 'boot-help.gif'), r1, [f for f in fr if 8180 <= f <= 10140 and f % 8 == 0], pages, lab,
        'r1', delay=50)
    help_menu(r1[nearest(r1, 9079)][0], os.path.join(OUT, 'help-menu-boxes.png'))
    for name, frame in (('boot-menu', 8699), ('help-menu', 9079), ('intro-picture', 2800), ('intro-scroller', 5200)):
        f = nearest(r1, frame)
        png(r1[f][pages[f] == 7], os.path.join(OUT, f'{name}.png'))
    cols, w, h = 4, 256, 192
    sheet = Image.new('RGB', (cols * (w + 8) + 8, 56 + 7 * (h + 24)), BG)
    d = ImageDraw.Draw(sheet)
    text(d, (8, 8), 'The help: all 28 pages of its six items, each as r1 shows it before the next key', 17)
    text(d, (8, 32), 'item.page, what the item is, the recording frame; the first page of each item in yellow', 12, DIMC)
    for i, (frame, item, page) in enumerate(HELP_PAGES):
        x, y = 8 + (i % cols) * (w + 8), 56 + (i // cols) * (h + 24)
        f = nearest(r1, frame)
        sheet.paste(zx(r1[f][pages[f] == 7]), (x, y))
        text(d, (x, y + h + 4), f'{item}.{page}  {ITEMS[item]}  (frame {frame})', 12, ACCENT if page == 1 else DIMC)
    path = os.path.join(OUT, 'help-pages.png')
    sheet.save(path)
    print(path)
    if os.path.exists(os.path.join(WORK, 'r2', 'samples.bin')):
        r2 = load('r2')
        p2 = shown_pages(r2)
        for name, frame in (('disk-save-prompt', 7652), ('disk-saving', 7947), ('disk-load-prompt', 8932),
                            ('disk-loaded-nether', 10602)):
            f = nearest(r2, frame)
            png(r2[f][p2[f] == 7], os.path.join(OUT, f'{name}.png'))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('command', choices=['sample', 'draw'])
    p.add_argument('--rec', default='r1')
    p.add_argument('--port-base', type=int, default=12910)
    args = p.parse_args()
    {'sample': cmd_sample, 'draw': cmd_draw}[args.command](args)


if __name__ == '__main__':
    main()
