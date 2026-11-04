#!/usr/bin/env python3
"""One pass of the game loop as it draws (docs/06-rendering.md 6.1): a GIF sampled every --step t-states, with
the bytes changed since the last picture lit where they show. The strip buffer `$8000-$BFFF` is drawn whole, as
stored: its four sets of 32 strips (even or odd pages, half `$00` or `$80`; 6.2), each strip upright with byte 0 at
the bottom, the set the blit shows this pass outlined. The screen is drawn as the Spectrum shows it. A changed byte flashes yellow and fades through red over the next pictures. A bar under the panels marks
the moment in the pass and how many bytes changed in the buffer, on the screen and in the object records
`$C000-$C1FF`.

Needs an unreal-ng instance with the recording open (re_session.py open):

    python3 pass_anim.py --work work/p2 --from 1000 --to 1005 --step 1750 out.gif [--still out.png]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import memanim  # noqa: E402
import playfield  # noqa: E402
import zxscreen  # noqa: E402

FADE = memanim.FADE
FRAME_T = memanim.FRAME_T
BG = (24, 24, 30)
BW, BH = 512, 258  # the buffer grid
REGIONS = (('buffer', 0x8000, 0xC000, (120, 200, 120)), ('screen', 0x4000, 0x5800, (240, 200, 80)),
           ('objects', 0xC000, 0xC200, (120, 170, 250)))


def screen_xy(address):
    a = address - 0x4000
    return (a & 31) * 8, ((a >> 8) & 7) | ((a >> 2) & 0x38) | ((a >> 5) & 0xC0)


def buffer_xy(address):
    """(x, y) of a buffer byte in the 2 x 2 grid of sets: set (page parity, half), column = page // 2"""
    page, offset = address >> 8, address & 0xFF
    parity, half = page & 1, offset >> 7
    return (parity * 256 + 8 * ((page - 0x80) >> 1), half * 130 + 127 - (offset & 0x7F))


def tint(panel, x, y, s, colour, byte):
    """8 x 1 pixels at (x, y): ink in the colour, paper in a dark shade of it"""
    px = panel.load()
    dark = tuple(c // 4 for c in colour)
    for bit in range(8):
        c = colour if byte & (0x80 >> bit) else dark
        for dy in range(s):
            for dx in range(s):
                px[(x + bit) * s + dx, y * s + dy] = c


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True, help='first frame (t 0)')
    p.add_argument('--to', dest='end', type=int, required=True, help='last frame (t 0)')
    p.add_argument('--step', type=int, default=1750, help='t-states between pictures')
    p.add_argument('--scale', type=int, default=2)
    p.add_argument('--delay', type=int, default=90)
    p.add_argument('--still', help='a PNG of every byte changed over the whole stretch, coloured by its first change')
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''))
    p.add_argument('out')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    s, font = args.scale, ImageFont.load_default()
    w, h = 256 * s, 192 * s
    first, last = args.start * FRAME_T, args.end * FRAME_T
    samples = list(range(first, last + 1, args.step))
    age, previous, pictures, history = {}, None, [], []
    when = {}  # address -> sample index of its first change, for the still
    for index, now in enumerate(samples):
        frame, t = divmod(now, FRAME_T)
        mem = memanim.memory_at(session, frame, t)
        counts = dict.fromkeys((r[0] for r in REGIONS), 0)
        if previous is not None:
            for name, lo, hi, _ in REGIONS:
                for a in range(lo, hi):
                    if mem[a] != previous[a]:
                        age[a] = 0
                        when.setdefault(a, index)
                        counts[name] += 1
        history.append(counts)
        img = Image.new('RGB', (BW + w + 48, h + 110), BG)
        draw = ImageDraw.Draw(img)
        # 1: the strip buffer as stored, its four sets in a 2 x 2 grid, at scale 1
        panel = Image.new('RGB', (BW, BH), (12, 12, 16))
        for a in range(0x8000, 0xC000):
            playfield.bits(panel, *buffer_xy(a), mem[a], 1)
        for a, n in age.items():
            if 0x8000 <= a < 0xC000:
                tint(panel, *buffer_xy(a), 1, FADE[min(n, len(FADE) - 1)], mem[a])
        cur_e, cur_f = mem[0xC32E], mem[0xC32F]  # the state the next blit reads ($D3F9 steps it after)
        sx, sy = (cur_e & 1) * 256, (cur_f >> 7) * 130
        ImageDraw.Draw(panel).rectangle([(sx, sy), (sx + 255, sy + 127)], outline=(200, 90, 200))
        img.paste(panel, (16, 28))
        # 2: the screen
        panel = zxscreen.render(mem[0x4000:0x5B00], s)
        for a, n in age.items():
            if 0x4000 <= a < 0x5800:
                tint(panel, *screen_xy(a), s, FADE[min(n, len(FADE) - 1)], mem[a])
        img.paste(panel, (BW + 32, 28))
        draw.text((16, 8), 'the strip buffer $8000-$BFFF as stored (left even pages, right odd; top half $00, bottom $80)',
                  fill=(220, 220, 200), font=font)
        draw.text((16, 28 + BH + 6), 'magenta: the set the blit shows this pass', fill=(200, 90, 200), font=font)
        draw.text((BW + 32, 8), f'the screen   frame {frame} t {t}', fill=(220, 220, 200), font=font)
        # 3: the pass so far: changed bytes per sample, per region
        top, bar_h = h + 40, 48
        x0, span = 16, BW + w + 16
        draw.rectangle([(x0, top), (x0 + span, top + bar_h)], outline=(60, 60, 70))
        peak = 180
        bw = span / len(samples)
        for i, c in enumerate(history):
            y = top + bar_h
            for name, _, _, colour in REGIONS:
                n = min(c[name], peak)
                if n:
                    hgt = n * bar_h / peak
                    draw.rectangle([(x0 + i * bw, y - hgt), (x0 + (i + 1) * bw - 1, y)], fill=colour)
                    y -= hgt
        draw.line([(x0 + (index + 1) * bw, top), (x0 + (index + 1) * bw, top + bar_h)], fill=(240, 240, 240))
        for f in range(args.start, args.end + 1):
            x = x0 + (f * FRAME_T - first) / args.step * bw
            draw.text((x + 2, top + bar_h + 2), f'frame {f}', fill=(150, 150, 140), font=font)
        legend = '   '.join(f'{name} {counts[name]}' for name, _, _, _ in REGIONS)
        draw.text((16, top - 14), 'bytes changed since the last picture: ' + legend +
                  '   (green buffer, yellow screen, blue object records)', fill=(200, 200, 190), font=font)
        pictures.append(img.convert('P', palette=Image.ADAPTIVE, colors=64))
        for a in list(age):
            age[a] += 1
            if age[a] >= len(FADE):
                del age[a]
        previous = mem
    for name, _, _, _ in REGIONS:  # where each region changed: runs of samples with changes
        runs, begin = [], None
        for i, c in enumerate(history + [dict.fromkeys(history[0], 0)]):
            if c[name] and begin is None:
                begin = i
            elif not c[name] and begin is not None:
                runs.append((begin, i - 1))
                begin = None
        text = ', '.join('%d:%d-%d:%d (%d bytes)' % (*divmod(samples[a - 1], FRAME_T), *divmod(samples[b], FRAME_T),
                                                    sum(history[k][name] for k in range(a, b + 1))) for a, b in runs)
        print(f'{name}: {text}')
    durations = [args.delay] * (len(pictures) - 1) + [1500]
    pictures[0].save(args.out, save_all=True, append_images=pictures[1:], duration=durations, loop=0, optimize=True)
    print(args.out, len(pictures), 'pictures')
    if args.still:
        # every changed byte, coloured by the moment of its last change (blue early, red late)
        img = Image.new('RGB', (BW + w + 48, h + 40), BG)
        draw = ImageDraw.Draw(img)
        mem = previous

        def colour(i):
            f = i / max(1, len(samples) - 1)
            return (int(60 + 195 * f), int(90 + 120 * (1 - abs(2 * f - 1))), int(255 - 195 * f))

        panel = Image.new('RGB', (BW, BH), (12, 12, 16))
        for a in range(0x8000, 0xC000):
            if a in when:
                tint(panel, *buffer_xy(a), 1, colour(when[a]), 0xFF)
            else:
                playfield.bits(panel, *buffer_xy(a), mem[a], 1, ink=(90, 90, 96))
        img.paste(panel, (16, 28))
        panel = zxscreen.render(mem[0x4000:0x5B00], s).point(lambda v: v // 3)
        for a, i in when.items():
            if 0x4000 <= a < 0x5800:
                tint(panel, *screen_xy(a), s, colour(i), 0xFF)
        img.paste(panel, (BW + 32, 28))
        draw.text((16, 8), f'buffer bytes changed over frames {args.start}-{args.end} by first change (blue early, red late)',
                  fill=(220, 220, 200), font=font)
        draw.text((BW + 32, 8), 'screen bytes changed, by the same colours', fill=(220, 220, 200), font=font)
        img.save(args.still)
        print(args.still)


if __name__ == '__main__':
    main()
