#!/usr/bin/env python3
"""zsA's screen GIFs (docs 03-06): the Spectrum screen over a stretch of a recording, with a title over the
pictures and the recording's frame under each, read with TTD memory_at from the re_session instance of --work.
--changes prints, per sampled frame, how many screen bytes changed since the previous sample (to find the events).

    python3 tools/fig_zs_anim.py --work work/docs/zsA/r99 --from 1500 --to 1640 --step 2 \
        --title "..." --out docs/img/render/99-outro.gif [--scale 2] [--delay 60] [--changes]

An --out ending in .png writes the pictures side by side as one strip (the title once across).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zsa_common as Z  # noqa: E402
import zxscreen  # noqa: E402
from fig_common import font  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--from', dest='f0', type=int, required=True)
    ap.add_argument('--to', dest='f1', type=int, required=True)
    ap.add_argument('--step', type=int, default=2)
    ap.add_argument('--title', default='')
    ap.add_argument('--out')
    ap.add_argument('--scale', type=int, default=2)
    ap.add_argument('--delay', type=int, default=60)
    ap.add_argument('--hold', type=int, default=1500)
    ap.add_argument('--changes', action='store_true')
    a = ap.parse_args()
    s = Z.session(a.work)
    pics, prev = [], None
    f_title, f_count = font(15), font(13)
    for f in range(a.f0, a.f1 + 1, a.step):
        scr = Z.memory_at(s, f, 0, 0x4000, 0x1B00)
        if a.changes:
            n = sum(1 for x, y in zip(scr, prev) if x != y) if prev else 0
            print(f, n)
        prev = scr
        if not a.out:
            continue
        img = zxscreen.render(scr, a.scale).convert('RGB')
        out = Image.new('RGB', (img.width, img.height + 52), (21, 22, 27))
        d = ImageDraw.Draw(out)
        d.text((6, 6), a.title, fill=(230, 230, 230), font=f_title)
        out.paste(img, (0, 28))
        d.text((6, img.height + 32), f'frame {f}', fill=(184, 188, 200), font=f_count)
        pics.append(out.convert('P', palette=Image.ADAPTIVE, colors=32))
    if a.out and a.out.endswith('.png'):   # a strip of the pictures side by side, the title once
        strip = Image.new('RGB', (sum(p.width for p in pics) + 6 * (len(pics) - 1), pics[0].height), (21, 22, 27))
        x = 0
        for p in pics:
            strip.paste(p.convert('RGB'), (x, 0))
            x += p.width + 6
        d = ImageDraw.Draw(strip)
        d.rectangle([0, 0, strip.width, 27], fill=(21, 22, 27))
        d.text((6, 6), a.title, fill=(230, 230, 230), font=f_title)
        strip.save(a.out)
        print(a.out, strip.size)
    elif a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        durations = [a.delay] * (len(pics) - 1) + [a.hold]
        pics[0].save(a.out, save_all=True, append_images=pics[1:], duration=durations, loop=0, optimize=True)
        print(a.out, len(pics), os.path.getsize(a.out))


if __name__ == '__main__':
    main()
