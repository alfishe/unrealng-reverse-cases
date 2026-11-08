#!/usr/bin/env python3
"""Doc 03 figure: the tape's signal, the load c1 made of it, and what the screen showed (docs/img/load/tape.png).

    python3 tools/fig_load_tape.py --work work/docs/docA/c1 [--out docs/img/load/tape.png]

Copied from the Zynaps case's tools/fig_load_tape.py and changed: Exolon's blocks and c1's stages, and a row of
screens read from the recording (TTD memory_at on the instance that holds c1, re_session.py open).

- Top bar: the TZX's eight standard blocks end to end at their signal length (tzxblocks.seconds) plus each block's
  pause, in frames of 50 Hz.
- Middle bar: c1 (re_session.py capture --record-load, work/c1): the ROM files taken by the emulator's LD-BYTES
  trap, done when the loader is entered at frame 250; the picy file until its unpacker runs at frame 1808; the code
  file until MoveStub at frame 12364; the move until the game's entry at frame 12376 (re_session.py stages,
  docs/03-build-and-load.md 3.5).
- Bottom: the screen at six moments of c1, each tied to its place on the middle bar.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, HERE)
import exlib  # noqa: E402
import image  # noqa: E402
import tzxblocks  # noqa: E402

K = exlib.K
LOADER, PICY, PICY_DONE, STUB, GAME = 250, 1808, 1825, 12364, 12376
HEADER, BASIC, LOADERC, PICYC, GAMEC, PAUSE = (122, 125, 140), (92, 143, 214), (217, 164, 65), (196, 106, 217), \
    (76, 175, 80), (43, 45, 54)
SHOTS = [(200, 'frame 200: the ROM\'s\nscreen; BASIC and\nloader taken fast'),
         (1818, 'frame 1818: picy\nunpacks, unseen:\nattributes black'),
         (1826, 'frame 1826: the\nattributes written,\nthe picture shows'),
         (12300, 'frame 12300: the code\nfile ends; counter\nat the bottom right'),
         (12500, 'frame 12500: the\ngame\'s menu')]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True, help='the work folder of an instance holding c1')
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'load', 'tape.png'))
    args = p.parse_args()
    s = exlib.session(args.work)
    blocks = [b for b in image.blocks() if b['kind'] == 'standard']
    colours = (HEADER, BASIC, HEADER, LOADERC, HEADER, PICYC, HEADER, GAMEC)
    W, left, right = 900, 120, 16
    plot = W - left - right
    segs, t = [], 0.0
    for b, c in zip(blocks, colours):
        f = tzxblocks.seconds(b) * 50
        segs.append((t, t + f, c))
        t += f
        pp = b['pause'] / 1000 * 50
        segs.append((t, t + pp, PAUSE))
        t += pp
    total = t
    sx = plot / total
    im = Image.new('RGB', (W, 520), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb, fs = K.font(12), K.font(15), K.font(11)
    d.text((10, 8), f'Exolon.tzx: {total:.0f} frames of signal; the picture done at {PICY_DONE}, '
                    f'the game at {GAME} (c1)', fill=K.TEXT, font=fb)
    d.text((10, 30), 'frames from the start of the tape (50 a second): the tape at ROM speed, the load in c1, '
                     'the screen at five moments', fill=K.DIM, font=f)
    yt, yr, h = 74, 150, 30
    for a, b, c in segs:
        d.rectangle((left + a * sx, yt, max(left + a * sx, left + b * sx - 1), yt + h), fill=c)
    d.text((10, yt + 2), 'the TZX at\nROM speed', fill=K.TEXT, font=f)
    st = [a for a, b, c in segs if c != PAUSE]
    d.text((left + st[7] * sx + 8, yt + 8), f'block 8, the game, 37 536 bytes: '
           f'{tzxblocks.seconds(blocks[7]) * 50:.0f} frames', fill=(16, 16, 16), font=f)
    d.text((left, yt - 16), 'blocks 1-4: BASIC, loader', fill=BASIC, font=fs)
    d.text((left + st[5] * sx - 10, yt + h + 3), 'block 6: picy', fill=PICYC, font=fs)
    stages = [(0, LOADER, BASIC), (LOADER, PICY, PICYC), (PICY, STUB, GAMEC), (STUB, GAME, LOADERC)]
    for a, b, c in stages:
        d.rectangle((left + a * sx, yr, max(left + a * sx, left + b * sx - 1), yr + h), fill=c)
    d.text((10, yr + 2), 'c1, the\nrecording', fill=K.TEXT, font=f)
    d.text((left + PICY * sx + 8, yr + 8), f'the Countdown II loader reads the code file: frames {PICY}-{STUB}',
           fill=(16, 16, 16), font=f)
    d.text((left, yr + h + 3), f'loader entered at {LOADER} (ROM files fast-loaded); picy {LOADER}-{PICY}',
           fill=K.DIM, font=fs)
    d.text((left + STUB * sx - 330, yr - 16), f'MoveStub {STUB}, the game at {GAME}', fill=LOADERC, font=fs)
    d.line([(left + total * sx, yt + h), (left + total * sx, yt + h + 6)], fill=K.DIM)
    tw, th = 160, 120
    gap = (W - 20 - 5 * tw) / 4
    ys = 250
    for k, (fr, label) in enumerate(SHOTS):
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = exlib.read(s, fr, 0x4000, 6912)
        th_im = K.render_screen(mem).resize((tw, th), Image.LANCZOS)
        x = int(10 + k * (tw + gap))
        im.paste(th_im, (x, ys))
        d.rectangle((x - 1, ys - 1, x + tw, ys + th), outline=(90, 90, 100))
        d.line([(left + fr * sx, yr + h), (x + tw // 2, ys - 2)], fill=(200, 200, 90), width=1)
        d.ellipse((left + fr * sx - 3, yr + h - 3, left + fr * sx + 3, yr + h + 3), fill=(255, 230, 90))
        d.multiline_text((x, ys + th + 6), label, fill=K.TEXT, font=fs, spacing=2)
    y = ys + th + 60
    for k, (c, txt) in enumerate([(HEADER, 'a header (17 bytes)'), (BASIC, 'the BASIC; in c1 the ROM files'),
                                  (LOADERC, 'the loader; in c1 the move'), (PICYC, 'picy, the packed screen'),
                                  (GAMEC, 'the game (code file)'), (PAUSE, 'a pause')]):
        xx, yy = 10 + (k % 3) * 296, y + (k // 3) * 18
        d.rectangle((xx, yy + 2, xx + 14, yy + 12), fill=c)
        d.text((xx + 20, yy), txt, fill=K.TEXT, font=f)
    d.text((10, y + 44), 'yellow dots: the moment of each screen on the c1 bar (TTD memory_at, the end of the frame)',
           fill=K.DIM, font=f)
    im = im.crop((0, 0, W, y + 66))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size, f'total {total:.0f} frames')


if __name__ == '__main__':
    sys.exit(main())
