#!/usr/bin/env python3
"""Animate memory over a stretch of a TTD recording: a GIF of the 64 K address space, one picture per sample.

Every sample is the machine's memory at that moment of the recording (TTD memory_at in an unreal-ng instance that
has the recording loaded: re_session.py open). The grid is the heatmap's: one row per 256 bytes. A byte's grey is
its value; a byte written since the last sample flashes yellow, then fades through red over the next samples, so
the picture shows where a routine is writing and in what order. Optionally the screen ($4000-$5AFF) is drawn as the
Spectrum shows it, beside the grid.

    python3 memanim.py --work W --from F[:T] --to F[:T] --step TSTATES out.gif [--from-address 5B00] [--screen]
           [--label "text"] [--delay 80] [--cell 2] [--unreal UNREAL_NG_CHECKOUT]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
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


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True, help='the work folder of re_session.py open (session.json)')
    p.add_argument('--from', dest='start', required=True, help='FRAME[:TINFRAME]')
    p.add_argument('--to', dest='end', required=True)
    p.add_argument('--step', type=int, default=FRAME_T, help='t-states between samples')
    p.add_argument('--from-address', default='5B00')
    p.add_argument('--to-address', default='FFFF')
    p.add_argument('--screen', action='store_true', help='draw the screen beside the grid')
    p.add_argument('--label', default='')
    p.add_argument('--delay', type=int, default=80, help='ms per picture')
    p.add_argument('--hold', type=int, default=1500, help='ms on the last picture')
    p.add_argument('--cell', type=int, default=2)
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''),
                   help='an unreal-ng checkout (tools/verification/analysis/re_session.py)')
    p.add_argument('out')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    lo, hi = int(args.from_address, 16) & 0xFF00, int(args.to_address, 16) | 0xFF
    rows, cell = (hi - lo + 1) // 256, args.cell
    font = ImageFont.load_default()
    grid_w, grid_h = 256 * cell, rows * cell
    screen_w = 256 * 2 if args.screen else 0
    width = 52 + grid_w + (16 + screen_w if args.screen else 0) + 10
    height = 34 + max(grid_h, 384 if args.screen else 0) + 22
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
        grid = Image.new('RGB', (grid_w, grid_h))
        px = grid.load()
        for a in range(lo, hi + 1):
            v = mem[a]
            g = 28 + v * 100 // 255
            colour = (g, g, g + 6)
            if a in age:
                colour = FADE[min(age[a], len(FADE) - 1)]
            x, y = (a & 0xFF) * cell, ((a - lo) >> 8) * cell
            for dy in range(cell):
                for dx in range(cell):
                    px[x + dx, y + dy] = colour
        image.paste(grid, (52, 30))
        d = ImageDraw.Draw(image)
        d.text((52, 6), f'{args.label}  frame {frame} t {t}   {written} bytes changed', fill=(235, 235, 235),
               font=font)
        d.text((52, 18), 'yellow: written since the last picture, fading red: earlier', fill=(160, 160, 170),
               font=font)
        for a in range(lo, hi + 1, 0x1000):
            y = 30 + ((a - lo) >> 8) * cell
            d.text((4, y - 4), f'${a:04X}', fill=(170, 170, 180), font=font)
        if args.screen:
            image.paste(zxscreen.render(mem[0x4000:0x5B00], 2), (52 + grid_w + 16, 30))
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
