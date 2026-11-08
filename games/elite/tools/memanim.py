#!/usr/bin/env python3
"""The case's copy of kit/memanim.py with text sized for a 900 px page (fonts 16-20 px, margins to fit).

Animate memory over a stretch of a TTD recording: a GIF of the 64 K address space, one picture per sample.

Every sample is the machine's memory at that moment of the recording (TTD memory_at in an unreal-ng instance that
has the recording loaded: re_session.py open). The grid is the heatmap's: one row per 256 bytes. A byte's grey is
its value; a byte written since the last sample flashes yellow, then fades through red over the next samples, so
the picture shows where a routine is writing and in what order. Optionally the screen ($4000-$5AFF) is drawn as the
Spectrum shows it, beside the grid. With --screen-geometry the grid is the screen page itself ($4000-$5AFF) drawn in
the screen's own geometry at the screen's size: each bitmap byte as its 8 pixels where they show (set bits light), a
written attribute as a frame round its 8 x 8 cell, so a byte flashes at the same place as on the screen beside it.

    python3 memanim.py --work W --from F[:T] --to F[:T] --step TSTATES out.gif [--from-address 5B00] [--screen]
           [--screen-geometry] [--label "text"] [--delay 80] [--cell 2] [--unreal UNREAL_NG_CHECKOUT]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import zxscreen  # noqa: E402

FRAME_T = 69888  # a 48K frame
FADE = [(255, 255, 120), (255, 200, 60), (240, 120, 40), (190, 60, 40), (130, 40, 50), (90, 35, 55)]


def moment(text):
    frame, _, t = text.partition(':')
    return int(frame) * FRAME_T + int(t or 0)


def memory_at(session, frame, t):
    data = bytearray()
    for offset in range(0, 0x10000, 0x4000):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                         'offset': offset, 'length': 0x4000}, ok=False)
        body = r.structured or {}
        if r.is_error or not body.get('exact', False):
            raise SystemExit(f'memory_at {frame}:{t}: {r.text}')
        data += bytes.fromhex(body['hex'])
    return bytes(data)


SCALE = 2  # the screen's pixels at 2 x 2


def screen_line(a):
    """The pixel line of bitmap byte a ($4000-$57FF)"""
    return ((a >> 8) & 7) | ((a >> 2) & 0x38) | ((a >> 5) & 0xC0)


def screen_heat(mem, age):
    """The screen page in its own geometry, 512 x 384: grey pixels, written bytes in their fade colour"""
    image = Image.new('RGB', (256 * SCALE, 192 * SCALE), (16, 16, 22))
    px = image.load()
    for a in range(0x4000, 0x5800):
        y, x0, v = screen_line(a) * SCALE, (a & 31) * 8 * SCALE, mem[a]
        hot = FADE[min(age[a], len(FADE) - 1)] if a in age else None
        for bit in range(8):
            on = v & (0x80 >> bit)
            if hot:
                colour = hot if on else tuple(c // 3 for c in hot)
            else:
                colour = (150, 150, 158) if on else (34, 34, 42)
            for dy in range(SCALE):
                for dx in range(SCALE):
                    px[x0 + bit * SCALE + dx, y + dy] = colour
    d = ImageDraw.Draw(image)
    for a in range(0x5800, 0x5B00):
        if a in age:
            x, y = ((a - 0x5800) & 31) * 8 * SCALE, ((a - 0x5800) >> 5) * 8 * SCALE
            d.rectangle((x, y, x + 8 * SCALE - 1, y + 8 * SCALE - 1), outline=FADE[min(age[a], len(FADE) - 1)])
    return image


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True, help='the work folder of re_session.py open (session.json)')
    p.add_argument('--from', dest='start', required=True, help='FRAME[:TINFRAME]')
    p.add_argument('--to', dest='end', required=True)
    p.add_argument('--step', type=int, default=FRAME_T, help='t-states between samples')
    p.add_argument('--from-address', default='5B00')
    p.add_argument('--to-address', default='FFFF')
    p.add_argument('--screen', action='store_true', help='draw the screen beside the grid')
    p.add_argument('--screen-geometry', action='store_true',
                   help='the grid is the screen page in its own geometry, the size of the screen beside it')
    p.add_argument('--label', default='')
    p.add_argument('--delay', type=int, default=80, help='ms per picture')
    p.add_argument('--hold', type=int, default=1500, help='ms on the last picture')
    p.add_argument('--cell', type=int, default=2)
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''),
                   help='an unreal-ng checkout (tools/verification/analysis/re_session.py)')
    p.add_argument('out')
    args = p.parse_args()
    import kitlib
    sys.path.insert(0, os.path.join(kitlib.unreal_root(args.unreal or None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    lo, hi = int(args.from_address, 16) & 0xFF00, int(args.to_address, 16) | 0xFF
    if args.screen_geometry:
        lo, hi = 0x4000, 0x5AFF
    rows, cell = (hi - lo + 1) // 256, args.cell
    font, small = K.font(20), K.font(17)
    LEFT, TOP = 78, 62
    grid_w, grid_h = (256 * SCALE, 192 * SCALE) if args.screen_geometry else (256 * cell, rows * cell)
    screen_w = 256 * 2 if args.screen else 0
    width = LEFT + grid_w + (16 + screen_w if args.screen else 0) + 10
    height = TOP + 4 + max(grid_h, 384 if args.screen else 0) + 22
    age = {}
    previous = None
    pictures = []
    now, last = moment(args.start), moment(args.end)
    while True:
        frame, t = divmod(now, FRAME_T)
        mem = memory_at(session, frame, t)
        written = 0
        if previous is not None:
            for a in range(lo, hi + 1):
                if mem[a] != previous[a]:
                    age[a] = 0
                    written += 1
        image = Image.new('RGB', (width, height), (20, 20, 26))
        grid = screen_heat(mem, age) if args.screen_geometry else Image.new('RGB', (grid_w, grid_h))
        px = grid.load()
        for a in ([] if args.screen_geometry else range(lo, hi + 1)):
            v = mem[a]
            g = 28 + v * 100 // 255
            colour = (g, g, g + 6)
            if a in age:
                colour = FADE[min(age[a], len(FADE) - 1)]
            x, y = (a & 0xFF) * cell, ((a - lo) >> 8) * cell
            for dy in range(cell):
                for dx in range(cell):
                    px[x + dx, y + dy] = colour
        image.paste(grid, (LEFT, TOP))
        d = ImageDraw.Draw(image)
        d.text((6, 6), f'{args.label}: frame {frame} t {t}, {written} bytes changed', fill=(235, 235, 235),
               font=font)
        d.text((6, 34), 'yellow: written since the last picture, fading red: earlier'
               + (' (attributes: a frame round the cell)' if args.screen_geometry else ''), fill=(160, 160, 170),
               font=small)
        if args.screen_geometry:  # the thirds of the bitmap
            for a in (0x4000, 0x4800, 0x5000):
                d.text((4, TOP + screen_line(a) * SCALE), f'${a:04X}', fill=(170, 170, 180), font=small)
        else:
            for a in range(lo, hi + 1, 0x1000):
                y = TOP + ((a - lo) >> 8) * cell
                d.text((4, y - 9), f'${a:04X}', fill=(170, 170, 180), font=small)
        if args.screen:
            image.paste(zxscreen.render(mem[0x4000:0x5B00], SCALE), (LEFT + grid_w + 16, TOP))
        pictures.append(image)
        for a in list(age):
            age[a] += 1
            if age[a] >= len(FADE) * 2:
                del age[a]
        previous = mem
        if now >= last:
            break
        now = min(last, now + args.step)
    durations = [args.delay] * (len(pictures) - 1) + [args.hold]
    pictures[0].save(args.out, save_all=True, append_images=pictures[1:], duration=durations, loop=0,
                     optimize=True)
    print(f'{args.out}: {len(pictures)} pictures')


if __name__ == '__main__':
    main()
