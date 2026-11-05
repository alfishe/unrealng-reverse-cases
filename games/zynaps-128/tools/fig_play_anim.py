#!/usr/bin/env python3
"""Doc 01 figures: a GIF of the screen over a stretch of a recording, with its point as the title and a readout of
the game's state under each picture, read from the same frame's memory (adapted from games/zynaps/tools/fig_anim.py).

    python3 tools/fig_play_anim.py --work work/z128A/r3 --from F --to G --step 4 --title 'TEXT' --out docs/img/design/X.gif

The readout: the level counter (player 1 record `$7F9C` +6) and the level (LevelOrder `$8003`), the score (+0-+3,
BCD), lives (+4), the pod highlight (+7), the weapon (+8: 0 none, 2 plasma, 3 homing missiles, 4 seeker), the laser
(+A) and speed (+B) levels, Fuel `$80E6`. --mark F:TEXT (repeatable) writes TEXT on the pictures from frame F on
for 40 frames: an event the caller found in the recording. --info options shows instead the loader's flags
`$5D40` (INF.LIVES) and `$5D41` (K-MOUSE) that the intro's options screen toggles (keys 1 and 2).
"""
import argparse
import os
import sys
import textwrap

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_lib as Z  # noqa: E402

K = Z.K


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=4)
    p.add_argument('--title', required=True)
    p.add_argument('--sub', default='')
    p.add_argument('--mark', action='append', default=[])
    p.add_argument('--info', choices=['play', 'options'], default='play')
    p.add_argument('--delay', type=int, default=80)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    marks = [(int(m.split(':', 1)[0]), m.split(':', 1)[1]) for m in args.mark]
    s = Z.session(args.work)
    f, fb = K.font(13), K.font(16)
    pictures = []
    name = os.path.basename(os.path.normpath(args.work))
    for fr in range(args.start, args.end + 1, args.step):
        st = Z.state(s, fr) if args.info == 'play' else None
        tl = textwrap.wrap(args.title, 52)
        sl = textwrap.wrap(args.sub, 64) if args.sub else []
        top = 10 + 21 * len(tl) + 17 * len(sl) + 6
        im = Image.new('RGB', (532, top + 384 + 66), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        for i, line in enumerate(tl):
            d.text((10, 8 + 21 * i), line, fill=K.TEXT, font=fb)
        for i, line in enumerate(sl):
            d.text((10, 8 + 21 * len(tl) + 17 * i), line, fill=K.DIM, font=f)
        im.paste(Z.screen(s, fr).resize((512, 384), Image.NEAREST), (10, top))
        y = top + 384 + 6
        if st is None:
            fl = Z.read(s, fr, 0x5D40, 2)
            onoff = ['off', 'on']
            d.text((10, y), f"{name} frame {fr}", fill=K.TEXT, font=f)
            d.text((10, y + 18), f"INF.LIVES $5D40 = {fl[0]} ({onoff[fl[0] != 0]})   K-MOUSE $5D41 = {fl[1]} "
                                 f"({onoff[fl[1] != 0]})", fill=K.TEXT, font=f)
            for mf, text in marks:
                if mf <= fr < mf + 40:
                    d.text((10, y + 38), '> ' + text, fill=(255, 210, 70), font=f)
            pictures.append(im)
            continue
        lvl = f"#{st['counter'] + 1} = level {st['level']}"
        d.text((10, y), f"{name} frame {fr}   {lvl}   score {st['score']}   lives {st['lives']}", fill=K.TEXT, font=f)
        d.text((10, y + 18), f"weapon {Z.WEAPONS.get(st['weapon'], st['weapon'])}   laser {st['laser']}   speed "
                             f"{st['speed']}   pod highlight {st['highlight']}   fuel ${st['fuel']:02X}",
               fill=K.TEXT, font=f)
        for mf, text in marks:
            if mf <= fr < mf + 40:
                d.text((10, y + 38), '> ' + text, fill=(255, 210, 70), font=f)
        pictures.append(im)
    durations = [args.delay] * len(pictures)
    durations[0] = 1000
    durations[-1] = 2000
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), pictures[0].size, os.path.getsize(args.out))


if __name__ == '__main__':
    main()
