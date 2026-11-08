#!/usr/bin/env python3
"""A sheet of Spectrum screens with a caption under each: a 6912-byte .scr file, or WORK@FRAME[:T], the screen at
the end of a frame (or at a T-state) of the recording an instance holds (re_session.py open; TTD memory_at), kept
in WORK/screens-at/ and read from there the next time (one instance at a time can serve a sheet of several).

    python3 tools/fig_sheet.py --title '...' --columns 3 --out docs/img/design/modes.png \
        work/docs/docA/c1@12500='c1 12500: the menu' work/x/screen.scr='...' ...
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exlib  # noqa: E402

K = exlib.K


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('shots', nargs='+', help='PATH.scr=caption (a | in the caption breaks the line)')
    p.add_argument('--columns', type=int, default=3)
    p.add_argument('--scale', type=float, default=1.0)
    p.add_argument('--title', default='')
    p.add_argument('--subtitle', default='')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    tw, th = int(256 * args.scale), int(192 * args.scale)
    gap, cap = 12, 34
    cols = args.columns
    rows = (len(args.shots) + cols - 1) // cols
    top = 56 if args.subtitle else 38
    W = cols * tw + (cols + 1) * gap
    H = top + rows * (th + cap + gap) + 4
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb = K.font(12), K.font(15)
    d.text((gap, 10), args.title, fill=K.TEXT, font=fb)
    if args.subtitle:
        d.text((gap, 32), args.subtitle, fill=K.DIM, font=f)
    for k, shot in enumerate(args.shots):
        path, _, caption = shot.partition('=')
        if '@' in path:
            work, _, moment = path.partition('@')
            fr, _, t = moment.partition(':')
            cache = os.path.join(work, 'screens-at', f'{fr}_{t or 0}.scr')
            if os.path.isfile(cache):
                data = open(cache, 'rb').read()
            else:
                data = exlib.read(exlib.session(work), int(fr), 0x4000, 6912, int(t) if t else None)
                os.makedirs(os.path.dirname(cache), exist_ok=True)
                open(cache, 'wb').write(data)
        else:
            data = open(path, 'rb').read()[:6912]
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = data
        pic = K.render_screen(mem)
        if args.scale != 1:
            pic = pic.resize((tw, th), Image.LANCZOS if args.scale < 1 else Image.NEAREST)
        r, c = divmod(k, cols)
        x, y = gap + c * (tw + gap), top + r * (th + cap + gap)
        im.paste(pic, (x, y))
        d.multiline_text((x, y + th + 3), caption.replace('|', '\n'), fill=K.TEXT, font=f, spacing=2)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)


if __name__ == '__main__':
    main()
