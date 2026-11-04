#!/usr/bin/env python3
"""The tape load as a picture (docs/03-build-and-load.md): the five blocks of orig/NETHER.TAP along the time their
signal takes at ROM speed, and under them what the recording shows arriving in memory: the BASIC at PROG, N1 at
$FCDA, the game block from $4000 up, measured as the number of bytes of the block already in place.

    python3 tools/load_stages.py --work W [--to 12700] [--step 50] [--png docs/img/load-tape.png]

W is a re_session.py work folder whose instance holds a recording made from power-on at ROM speed (the play
recording, work/play, opened with re_session.py open). Each sample is TTD memory_at at the end of a frame. Prints
the frames where each stage arrives.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import tapblocks  # noqa: E402

FRAME_T = 69888
PROG = 0x5CCB


def read(session, frame, lo, n):
    out = bytearray()
    for a in range(lo, lo + n, 0x4000):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'offset': a,
                                         'length': min(0x4000, lo + n - a)}, ok=False)
        out += bytes.fromhex(r.structured['hex'])
    return bytes(out)


def blocks(path):
    data = open(path, 'rb').read()
    out, at = [], 0
    while at < len(data):
        n = data[at] | data[at + 1] << 8
        out.append(data[at + 2:at + 2 + n])
        at += 2 + n
    return out


def play_t(block):
    """T-states of a standard ROM block's signal: pilot, sync, bits (tapblocks' timing)"""
    pilot = 8063 if block[0] < 0x80 else 3223
    ones = sum(bin(b).count('1') for b in block)
    zeros = 8 * len(block) - ones
    return pilot * 2168 + 667 + 735 + zeros * 2 * 855 + ones * 2 * 1710


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--to', type=int, default=12700)
    p.add_argument('--step', type=int, default=50)
    p.add_argument('--png')
    p.add_argument('--unreal')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(K.unreal_root(args.unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    tape = blocks(os.path.join(CASE, 'orig', 'NETHER.TAP'))
    basic, n1, game = tape[1][1:-1], tape[3][1:-1], tape[4][1:-1]
    samples = []
    events = {}
    for frame in range(0, args.to + 1, args.step):
        mem = read(session, frame, 0x4000, 0xC000)
        have_basic = mem[PROG - 0x4000:PROG - 0x4000 + len(basic)] == basic
        have_n1 = mem[0xFCDA - 0x4000:0xFCDA - 0x4000 + len(n1)] == n1
        # the loader's front: the highest byte of the block in place that ends a run of 8 matching bytes, 4 of them
        # non-zero (RAM is zero at power-on, so the block's zero runs, the attributes and the work space from $D7D3
        # up, arrive without a trace; the BASIC and N1 areas are left out)
        arrived = 0
        for i in range(min(len(game), 0xBCDA) - 1, 7, -1):
            if 0x1C00 <= i < 0x1E00:
                continue
            run = game[i - 7:i + 1]
            if mem[i - 7:i + 1] == run and sum(1 for v in run if v) >= 4:
                arrived = i + 1
                break
        samples.append((frame, have_basic, have_n1, arrived))
        for key, on in (('BASIC in place', have_basic), ('N1 in place', have_n1),
                        ('game block: first bytes', arrived > 0)):
            if on and key not in events:
                events[key] = frame
    # the block's last 15 bytes ($FCDA-$FCE8) land over N1's head: the first frame they are in, searched frame by frame
    # from the last sample that still holds N1 (the start-up clears the screen part right after, so the whole block
    # never shows at once)
    last = max((fr for fr, _, n, _ in samples if n), default=None)
    if last is not None:
        for frame in range(last, last + args.step + 1):
            mem = read(session, frame, 0x4000, 0xC000)
            if mem[0xFCDA - 0x4000:0xFCE9 - 0x4000] == game[-15:]:
                events['game block: complete'] = frame
                break
    for key, frame in events.items():
        note = '' if key == 'game block: complete' else f' (sampled every {args.step} frames)'
        print(f'{key}: by the end of frame {frame}{note}')
    if args.png:
        draw(args.png, tape, samples, args.to, len(game))


def draw(path, tape, samples, to, game_len):
    width, left, right = 1100, 70, 20
    span = width - left - right
    scale = span / (to * FRAME_T)
    image = Image.new('RGB', (width, 330), (24, 24, 30))
    d = ImageDraw.Draw(image)
    f = K.font(13)
    d.text((left, 8), 'orig/NETHER.TAP at ROM speed (block signal, pauses not included), and the play recording: '
           'bytes in place', fill=(230, 230, 230), font=f)
    names = ['header "N.EARTH"', 'BASIC 381', 'header "N1"', 'N1 180', 'game 48361']
    colours = [(120, 120, 140), (90, 160, 230), (120, 120, 140), (230, 150, 60), (90, 200, 120)]
    t = 0
    y0 = 34
    for i, block in enumerate(tape):
        n = play_t(block)
        x0, x1 = left + t * scale, left + (t + n) * scale
        d.rectangle([x0, y0, max(x0 + 1, x1 - 1), y0 + 26], fill=colours[i])
        label = f'{i} {names[i]}: {n / 3.5e6:.1f} s'
        d.rectangle([left + 218 * i, y0 + 34, left + 218 * i + 10, y0 + 44], fill=colours[i])
        d.text((left + 218 * i + 14, y0 + 32), label, fill=(220, 220, 220), font=f)
        t += n
    d.text((left, y0 + 66), f'signal total {t / 3.5e6:.1f} s = {t / FRAME_T:.0f} frames. The play recording: blocks 0-3 '
           'fast (the LD-BYTES trap), block 4 at signal speed (N1)', fill=(200, 200, 200), font=f)
    # the curve: game bytes in place, with the BASIC and N1 marks
    gy0, gy1 = 130, 290
    d.rectangle([left, gy0, left + span, gy1], outline=(90, 90, 100))
    d.text((left + span - 600, gy0 + 12), 'the loader\'s front: the highest non-zero byte of the game block in place',
           fill=(90, 200, 120), font=f)
    for frac, text in ((0, '$4000'), (0.5, ''), (1, '$FCE8')):
        y = gy1 - frac * (gy1 - gy0)
        d.text((8, y - 7), text, fill=(200, 200, 200), font=f)
    pts = [(left + fr * FRAME_T * scale, gy1 - a / game_len * (gy1 - gy0)) for fr, _, _, a in samples]
    d.line(pts, fill=(90, 200, 120), width=2)
    for key, idx, colour in (('BASIC', 1, (90, 160, 230)), ('N1', 2, (230, 150, 60))):
        first = next((fr for fr, *flags in samples if flags[idx - 1]), None)
        if first is not None:
            x = left + first * FRAME_T * scale
            d.line([x, gy0, x, gy1], fill=colour)
            d.text((x + 3, gy0 + 4 + 16 * (idx - 1)), f'{key} in place by frame {first} ',
                   fill=colour, font=f)
    for fr in range(0, to + 1, 2000):
        x = left + fr * FRAME_T * scale
        d.text((x - 10, gy1 + 6), str(fr), fill=(200, 200, 200), font=f)
    d.text((left + span - 220, gy1 + 22), 'frame of the play recording', fill=(200, 200, 200), font=f)
    image.save(path)
    print(path)


if __name__ == '__main__':
    sys.exit(main())
