#!/usr/bin/env python3
"""Doc 04 figure: the states of the program, one real screen each, from recording c1 (Pentagon 128 + TR-DOS, power-on
to six short games).

    python3 tools/fig_states.py --work work/z128A/c1 --out docs/img/loop/states.png

W holds c1 open (re_session.py open). Each screen is memory_at at the frame's end (exact). Under each: the frame, the
state, and the interrupt handler in force then: the word at $FDFE (the JP at $FDFD; the intro's IM 2 table at $FC00
has the same JP), read at the same frame; between the intro's end (IM 1, ShowHewson) and the game's start the ROM's
IM 1 handler runs instead. The frames come from find_last over c1 (docs/04 4.1): the stage starts of
docs/03 3.7, CreditsPage $B095, HiScorePage $B0C9, LevelStart $AF49, PlayLoop $B1B4, EndOfPlay $B0FF and
HighScoreEntry $A7F7.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zalib as Z  # noqa: E402

K = Z.K
SHOTS = [
    (2600, 'intro: the title (STarKos tune)'),
    (2700, 'intro: the options 1, 2, 0'),
    (2850, 'intro: Hewson; block 2 loads'),
    (3400, 'game: CreditsPage $B095'),
    (3600, 'game: HiScorePage $B0C9'),
    (3950, 'LevelStart $AF49: the banner'),
    (4200, 'play: PlayLoop $B1B4'),
    (4460, 'EndOfPlay $B0FF: the fade'),
    (5186, 'HighScoreEntry $A7F7'),
]
HANDLERS = {0x60D0: 'IntroInterrupt', 0xA9E4: 'TitleInterrupt', 0xA9ED: 'PlayInterrupt',
            0xA512: 'MenuRasterInterrupt'}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    s = Z.session(args.work)
    tw, th, gap = 280, 210, 14
    W = 3 * tw + 4 * gap
    top = 52
    H = top + 3 * (th + 44) + 10
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb, fs = K.font(12), K.font(15), K.font(11)
    d.text((10, 8), 'The program\'s states as c1 met them, each with its own screen and interrupt handler',
           fill=K.TEXT, font=fb)
    d.text((10, 30), 'c1, Pentagon 128 + TR-DOS; the handler is the JP target at $FDFD at that frame', fill=K.DIM, font=f)
    for i, (fr, label) in enumerate(SHOTS):
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = Z.read(s, fr, 0x4000, 6912)
        jp = Z.read(s, fr, 0xFDFD, 3)
        target = jp[1] | jp[2] << 8 if jp[0] == 0xC3 else None
        x = gap + (i % 3) * (tw + gap)
        y = top + (i // 3) * (th + 44)
        im.paste(K.render_screen(mem).resize((tw, th)), (x, y))
        d.text((x, y + th + 3), f'{fr}: {label}', fill=K.TEXT, font=fs)
        name = HANDLERS.get(target, '?') if target is not None else 'no JP at $FDFD'
        text = f'handler ${target:04X} {name}' if target is not None else name
        if 2780 < fr < 3313:
            text = 'IM 1 since the intro\'s end: the ROM\'s handler'
        d.text((x, y + th + 19), text, fill=(120, 230, 140), font=fs)
    im.save(args.out)
    print(args.out, im.size)


if __name__ == '__main__':
    main()
