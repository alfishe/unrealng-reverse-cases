#!/usr/bin/env python3
"""Docs 01 and 05: a GIF of the screen over a stretch of a recording, with a title and a live readout of the game's
state under each picture (read from the same frame's memory).

    python3 tools/fig_anim.py --work work/zyA/r1 --from 17000 --to 17400 --step 4 --info play
           --title 'A guardian fight' --out docs/img/design/guardian.gif
    python3 tools/fig_anim.py --work work/zyA/menu --from 860 --to 1340 --step 6 --info keys
           --title 'Redefining the keys' --out docs/img/controls/redefine.gif

--info play: the level counter and level (player record $7F9C +6, LevelOrder $8003), score (+0-+3), lives (+4), the
pod selector (+7), Fuel $80E6, PassPhase $7F65. --info keys: KeyTable $8188 (5 entries of half-row byte and bit mask:
fire, up, down, left, right) decoded to key names, FireHeld $8184 and ControlBits $8186. --info none: the frame only.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zynlib as Z  # noqa: E402

K = Z.K
# The Spectrum keyboard: half-row selector byte (the high byte of port $xxFE) -> the keys from bit 0 up
HALF_ROWS = {0xFE: ['CS', 'Z', 'X', 'C', 'V'], 0xFD: ['A', 'S', 'D', 'F', 'G'], 0xFB: ['Q', 'W', 'E', 'R', 'T'],
             0xF7: ['1', '2', '3', '4', '5'], 0xEF: ['0', '9', '8', '7', '6'], 0xDF: ['P', 'O', 'I', 'U', 'Y'],
             0xBF: ['ENTER', 'L', 'K', 'J', 'H'], 0x7F: ['SPACE', 'SS', 'M', 'N', 'B']}


def key_name(row, mask):
    keys = HALF_ROWS.get(row)
    if not keys:
        return f'?{row:02X}/{mask:02X}'
    for bit in range(5):
        if mask == 1 << bit:
            return keys[bit]
    return f'{row:02X}/{mask:02X}'


def info_lines(s, frame, kind):
    if kind == 'play':
        rec = Z.read(s, frame, 0x7F9C, 16)
        order = Z.read(s, frame, 0x8003, 12)
        v = Z.read(s, frame, 0x7F60, 0x10)
        fuel = Z.read(s, frame, 0x80E6, 1)[0]
        counter = rec[6]
        return [f'level #{counter + 1} = level {order[counter] if counter < 12 else "?"}   score '
                f'{int(rec[0:4].hex())}   lives {rec[4]}',
                f'pod selector {rec[7]}   Fuel ${fuel:02X}   PassPhase {v[5]}']
    if kind == 'keys':
        t = Z.read(s, frame, 0x8184, 14)
        names = ['fire', 'up', 'down', 'left', 'right']
        pairs = [key_name(t[4 + 2 * i], t[5 + 2 * i]) for i in range(5)]
        return ['KeyTable $8188: ' + '  '.join(f'{n} {k}' for n, k in zip(names, pairs)),
                f'FireHeld $8184 = {t[0]}   ControlBits $8186 = {t[2]:08b}']
    return []


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=4)
    p.add_argument('--info', choices=['play', 'keys', 'none'], default='none')
    p.add_argument('--title', required=True)
    p.add_argument('--delay', type=int, default=80)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    s = Z.session(args.work)
    f, fb = K.font(12), K.font(15)
    pictures = []
    frames = list(range(args.start, args.end + 1, args.step))
    for fr in frames:
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = Z.read(s, fr, 0x4000, 6912)
        lines = info_lines(s, fr, args.info)
        im = Image.new('RGB', (532, 34 + 384 + 12 + 16 * (len(lines) + 1)), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        d.text((10, 8), args.title, fill=K.TEXT, font=fb)
        im.paste(K.render_screen(mem).resize((512, 384), Image.NEAREST), (10, 34))
        y = 34 + 384 + 6
        d.text((10, y), f'{os.path.basename(os.path.normpath(args.work))} frame {fr}', fill=K.DIM, font=f)
        for i, line in enumerate(lines):
            d.text((10, y + 16 * (i + 1)), line, fill=K.TEXT, font=f)
        pictures.append(im)
    durations = [args.delay] * len(pictures)
    durations[-1] = 2000
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), pictures[0].size)


if __name__ == '__main__':
    main()
