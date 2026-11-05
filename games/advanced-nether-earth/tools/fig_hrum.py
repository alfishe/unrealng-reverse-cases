#!/usr/bin/env python3
"""Doc 03: HRUM 3.5 unpacking, drawn from the streams (tools/hrum.py's tokens, replayed token by token).

    python3 tools/fig_hrum.py anim [--block introscreen] [--gif docs/img/load/hrum-introscreen.gif]
    python3 tools/fig_hrum.py gaps                 the closest the output comes to the unread stream, per block

anim: the intro's picture block (bank 7 `$C000-$DAFF`, the Eternity Industry screen) as the depacker fills it.
Left, the screen bytes written so far (the bitmap on fixed white-on-blue attributes until the attributes arrive;
the last picture is the real screen); right, the 6 912 bytes of the output as a bar: written by a literal (green),
copied by a match (blue), the packed stream not read yet (orange), moved up by the set-up's LDDR to end where the
output ends. The depacker reads the stream upwards and writes below it: the output chases the stream and never
reaches it.

The positions follow src/sfx/hrum35.asm: the stream ends at the output's last byte, SP starts at
Out + OutLen - StreamLen; the 5 tail bytes are copied last. Needs build/pk/*.hrm (tools/build.sh).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import hrum  # noqa: E402
import zxscreen  # noqa: E402

BLOCKS = {  # name: (out, outlen, the unpacked file)
    'introscreen': (0xC000, 6912, 'src/res/img/intro-screen-c000.bin'),
    'intro': (0x6600, 15789, 'build/img/intro-6600.bin'), 'd02': (0x6600, 28324, 'src/res/img/d02-6600.bin'),
    'd03': (0x6600, 39424, 'src/res/img/d03-6600.bin'), 'd04': (0xC000, 5647, 'src/res/img/d04-c000-bank1.bin'),
    'd05': (0x6060, 38517, 'src/res/img/d05-6060.bin'), 'd06': (0xC000, 16384, 'build/img/d06-c000-bank7.bin'),
    'd07': (0x9C40, 6992, 'src/res/img/d07-9c40.bin'), 'music': (0xC000, 8731, 'src/res/img/music-c000-bank1.bin'),
    'deadend': (0xC000, 15903, 'src/res/img/dead-end-c000-bank3.bin'),
    'diskio': (0xC000, 3372, 'src/res/img/disk-io-c000-bank4.bin'), 'game': (0x6731, 28839, 'build/img/game-6731.bin'),
    'finalcut': (0x6060, 38669, 'src/res/img/final-cut-6060.bin'),
}
BG, FG, DIM = (21, 22, 27), (230, 230, 230), (184, 188, 200)
LIT, COPY, STREAM, GAP = (76, 175, 80), (92, 143, 214), (232, 131, 58), (40, 42, 52)


class Tracer(hrum.BitReader):
    pass


def replay(name):
    """[(kind, out_pos_after, stream_pos_after, length)] for every token, the stream length, and the output"""
    data = open(os.path.join(CASE, 'build/pk/%s.hrm' % name), 'rb').read()
    r = hrum.BitReader(data)
    steps = []
    out = 0
    first = r.byte()
    out += 1
    steps.append(('lit', out, r.p, 1))
    while True:
        if r.bit():
            r.byte()
            out += 1
            steps.append(('lit', out, r.p, 1))
            continue
        e = 1
        while True:
            v = r.bit() << 1 | r.bit()
            if v < 3:
                code = e + v
                break
            e += 3
            if e == r.c:
                code = e
                break
        if code == 1:
            r.bit(), r.bit(), r.bit()
            length = 1
        elif code == 2:
            r.byte()
            length = 2
        else:
            if code == 4:
                length = r.byte()
                if length == 0:
                    break
            elif code == 3:
                length = 3
            else:
                length = code - 1
            if r.bit():
                r.bit(), r.bit(), r.bit(), r.bit()
            r.byte()
        out += length
        steps.append(('copy', out, r.p, length))
    del first
    return steps, len(data)


def gaps():
    print('block        out  outlen stream  tokens  literals  closest gap (bytes between the next write and the '
          'next unread stream byte)')
    for name, (o, n, _f) in BLOCKS.items():
        steps, slen = replay(name)
        start = n - slen  # the stream's first byte, as an offset in the output
        g = min(start + p - w for _k, w, p, _l in steps)
        lits = sum(1 for s in steps if s[0] == 'lit')
        print('%-11s $%04X %6d %6d %7d %9d %6d' % (name, o, n, slen, len(steps), lits, g))


def anim(name, gif, pictures=72):
    out0, n, fname = BLOCKS[name]
    final = open(os.path.join(CASE, fname), 'rb').read()
    steps, slen = replay(name)
    start = n - slen
    kinds = bytearray(n)  # 0 not written, 1 literal, 2 copy
    font = ImageFont.load_default()
    frames = []
    picks = sorted(set([0] + [round(i * (len(steps) - 1) / (pictures - 1)) for i in range(pictures)]))
    done = 0
    pos = 0
    W, H = 512 + 230, 384 + 80
    for idx in picks:
        while done <= idx:
            k, w, p, ln = steps[done]
            for a in range(w - ln, w):
                kinds[a] = 1 if k == 'lit' else 2
            pos = w
            sp = p
            done += 1
        screen = bytearray(6912)
        screen[:pos] = final[:pos]
        attrs_in = pos > 0x1800
        if not attrs_in:
            for a in range(0x1800, 0x1B00):
                screen[a] = 0x0F  # white on blue
        img = Image.new('RGB', (W, H), BG)
        img.paste(zxscreen.render(bytes(screen), 2), (10, 60))
        d = ImageDraw.Draw(img)
        d.text((10, 8), 'HRUM 3.5 unpacks the intro picture into bank 7 ($C000-$DAFF): %d of %d tokens' % (
            idx + 1, len(steps)), fill=FG, font=font)
        d.text((10, 26), 'written %5d of 6912 bytes; stream read %4d of %d; the screen on fixed attributes '
               'until they arrive' % (pos, sp, slen), fill=DIM, font=font)
        # the bar: 6912 bytes, top = $C000
        bx, by, bw, bh = 560, 60, 60, 384
        for y in range(bh):
            a0 = y * n // bh
            a1 = max(a0 + 1, (y + 1) * n // bh)
            stream_lo = start + sp
            if a0 >= stream_lo:
                col = STREAM
            else:
                ks = kinds[a0:a1]
                nl, nc = ks.count(1), ks.count(2)
                if nl + nc == 0:
                    col = GAP
                else:  # the line's mix of literal and copied bytes
                    f = nl / (nl + nc)
                    col = tuple(round(LIT[i] * f + COPY[i] * (1 - f)) for i in range(3))
            d.line([(bx, by + y), (bx + bw, by + y)], fill=col)
        d.text((bx + bw + 6, by - 4), '$C000', fill=DIM, font=font)
        d.text((bx + bw + 6, by + bh * 0x1800 // n - 6), '$D800 attrs', fill=DIM, font=font)
        d.text((bx + bw + 6, by + bh - 10), '$DAFF', fill=DIM, font=font)
        yo = by + pos * bh // n
        ys = by + (start + sp) * bh // n
        d.line([(bx - 14, yo), (bx - 2, yo)], fill=FG, width=2)
        d.text((bx - 50, yo - 6), 'DE out', fill=FG, font=font)
        d.line([(bx - 14, ys), (bx - 2, ys)], fill=STREAM, width=2)
        d.text((bx - 50, ys + 2), 'SP in', fill=STREAM, font=font)
        ly = by + bh + 8
        for i, (c, t) in enumerate([(LIT, 'literal byte'), (COPY, 'copied by a match (mixed: blend)'), (STREAM, 'stream, unread'),
                                    (GAP, 'free')]):
            d.rectangle([10 + i * 170, ly, 22 + i * 170, ly + 10], fill=c)
            d.text((28 + i * 170, ly - 1), t, fill=FG, font=font)
        frames.append(img)
    last = Image.new('RGB', (W, H), BG)
    last.paste(frames[-1])
    last.paste(zxscreen.render(final, 2), (10, 60))
    ImageDraw.Draw(last).text((10, 8 + 0), ' ' * 0, fill=FG)
    frames.append(last)
    durations = [1500] + [80] * (len(frames) - 3) + [800, 3000]
    os.makedirs(os.path.dirname(gif), exist_ok=True)
    frames[0].save(gif, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=True)
    print(gif, len(frames), 'pictures')


def main():
    a = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    a.add_argument('what', choices=['anim', 'gaps'])
    a.add_argument('--block', default='introscreen')
    a.add_argument('--gif', default=os.path.join(CASE, 'docs/img/load/hrum-introscreen.gif'))
    args = a.parse_args()
    if args.what == 'gaps':
        gaps()
    else:
        anim(args.block, args.gif)


if __name__ == '__main__':
    main()
