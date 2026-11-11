#!/usr/bin/env python3
"""Doc 03 figures of the SpeedLock loader: the store cipher byte by byte, TimeCheck's windows, memory as it changes.

    python3 tools/fig_loader.py cipher [--stores work/stage2/stores.txt] [--count 24] OUT.gif
    python3 tools/fig_loader.py timecheck [--c1 HEX] OUT.png
    python3 tools/fig_loader.py memgrid --work W --from F[:T] --to F[:T] --step T --range AC00-BFFF
            [--row 64] [--cell 8] [--label TEXT] [--delay 120] [--hold 2000] OUT.gif

cipher: StoreByte `$BD9C` at work, one picture per stored byte: the tape byte L, L XOR k, (L XOR k) + a, the address
IX it goes to, the running XOR H of the tape bytes, and the stage's code as it appears. The bytes come from
work/stage2/stores.txt (SkoolKit's simulated load: every `LD (IX+0),A` at `$BDA1` with A, L, IX, H, DE); the stored
values equal c1's memory (TTD memory_at, frames 2366-2378, the stage at `$BF0D`), and the listing lines from
build/stage2.lst.

timecheck: the tape after block 7 (the stage) as the TZX times it: the 2407 ms pause, block 9's pilot (1578 x 2165 T),
the 255 samples of TimeCheck `$BE5D` (18 447 T each: 255 polls of 72 T and the loop), its two windows (samples 50-99
and 205-254) and the counts: c1's TimeBuffer `$9000-$90FE` (--c1, the 255 bytes in hex, read with TTD memory_at at
frame 2484) and a copy whose pause is cut to 1.0 s, computed with the same timing.

memgrid: memory over a stretch of a TTD recording (an instance opened with kit/rs.py open), --row bytes a grid row and
--cell pixels a byte, so a short range is drawn tall enough to read; a byte written since the last picture is yellow
and fades through red, the rest is its value in grey. Frames are 128K frames (70 908 T).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
KIT = os.path.join(CASE, '..', '..', 'kit')
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402

FRAME_T = 70908
BG, FG, DIM = (14, 14, 20), (235, 235, 235), (150, 150, 160)
YELLOW, CYAN, GREEN, RED, BLUE = (255, 220, 90), (110, 210, 230), (120, 220, 120), (240, 110, 90), (120, 150, 255)
FADE = [(255, 255, 120), (255, 200, 60), (240, 120, 40), (190, 60, 40), (130, 40, 50), (90, 35, 55)]


def listing_lines(path, lo, hi):
    """address -> (instruction, byte count) of the code lines of a sjasmplus listing in lo..hi"""
    import re
    out = {}
    pattern = re.compile(r'^\s*\d+\+?\s+([0-9A-F]{4}) ((?:[0-9A-F]{2} )+)\s*([A-Z].*)$')
    for line in open(path):
        m = pattern.match(line.rstrip('\n'))
        if not m:
            continue
        a = int(m.group(1), 16)
        if lo <= a <= hi and a not in out:
            out[a] = (m.group(3).split(';')[0].strip(), len(m.group(2).split()))
    return out


def bits(v):
    return format(v, '08b')


def cipher(args):
    rows = []
    for line in open(args.stores):
        p = line.split()
        if p[0] != 'BDA1':
            continue
        rows.append((int(p[1], 16), int(p[2], 16), int(p[3], 16), int(p[4], 16), int(p[5], 16)))
        if len(rows) >= args.count:
            break
    code = listing_lines(os.path.join(CASE, 'build', 'stage2.lst'), 0xBF0D, 0xBFFF)
    k, add = 0xC1, 0x11
    big, mid, small = K.font(22), K.font(15), K.font(13)
    W, H = 900, 540
    pictures = []
    for i in range(len(rows)):
        a_val, l_val, ix, h_val, de = rows[i]
        x_val = l_val ^ k
        im = Image.new('RGB', (W, H), BG)
        d = ImageDraw.Draw(im)
        d.text((20, 12), 'StoreByte $BD9C: the tape byte L becomes (L XOR k) + a at IX', fill=FG, font=mid)
        d.text((20, 34), 'LD A,$C1 / XOR L / ADD A,$11 / LD (IX+0),A     k = $C1, a = $11 (blocks 17 and 19 '
               'later make k $86)', fill=DIM, font=small)
        d.text((20, 54), f'byte {i + 1} of the stage block (196 bytes to $BF0D), DE = {de:#06x} left', fill=DIM,
               font=small)
        # the three steps, large
        y = 90
        steps = [('L, from the tape', l_val, CYAN), ('XOR k = $C1', x_val, FG), ('+ a = $11', a_val, YELLOW)]
        for j, (name, v, colour) in enumerate(steps):
            x = 20 + j * 290
            d.rectangle((x, y, x + 260, y + 110), outline=colour, width=2)
            d.text((x + 12, y + 8), name, fill=colour, font=mid)
            d.text((x + 12, y + 36), f'${v:02X}', fill=colour, font=big)
            d.text((x + 100, y + 40), bits(v), fill=colour, font=mid)
            if j < 2:
                d.text((x + 266, y + 40), '>', fill=DIM, font=big)
        d.text((20, y + 122), f'stored at IX = ${ix:04X}: ${a_val:02X}    H (the XOR of the tape bytes so far) = '
               f'${h_val:02X}', fill=FG, font=mid)
        # the memory row so far
        y = 250
        d.text((20, y), 'The stage at $BF0D so far (tape byte above, stored byte below):', fill=DIM, font=small)
        for j in range(len(rows)):
            x = 20 + j * 36
            colour = YELLOW if j == i else (FG if j < i else (60, 60, 70))
            d.text((x, y + 20), f'{rows[j][2] & 0xFF:02X}', fill=DIM if j <= i else (60, 60, 70), font=small)
            d.text((x, y + 40), f'{rows[j][1]:02X}' if j <= i else '..', fill=CYAN if j <= i else (60, 60, 70),
                   font=small)
            d.text((x, y + 60), f'{rows[j][0]:02X}' if j <= i else '..', fill=colour, font=small)
        d.text((20 + len(rows) * 36 + 4, y + 20), 'IX low', fill=DIM, font=small)
        d.text((20 + len(rows) * 36 + 4, y + 40), 'L', fill=CYAN, font=small)
        d.text((20 + len(rows) * 36 + 4, y + 60), 'stored', fill=YELLOW, font=small)
        # the code that has appeared
        y = 350
        d.text((20, y), 'The code these bytes make (build/stage2.lst): an instruction shows once all its bytes are '
               'in', fill=DIM, font=small)
        line = 0
        for a in sorted(code):
            text, n = code[a]
            done = a + n - 1 <= rows[i][2]
            started = a <= rows[i][2]
            if not started:
                break
            colour = GREEN if done else (90, 90, 100)
            hexes = ' '.join(f'{rows[a - 0xBF0D + m][0]:02X}' if a - 0xBF0D + m <= i else '..' for m in range(n))
            d.text((20, y + 22 + line * 20), f'${a:04X}  {hexes:<12} {text if done else ""}', fill=colour, font=mid)
            line += 1
        pictures.append(im)
    durations = [700] * (len(pictures) - 1) + [3000]
    pictures[0].save(args.out, save_all=True, append_images=pictures[1:], duration=durations, loop=0, optimize=True)
    print(args.out, len(pictures), 'pictures')


SAMPLE_T = 18447   # one TimeBuffer sample: 255 polls of 72 T, the call and the loop
POLL_T = 72
CLOCK = 3546900


def edge_counts(pilot_start_t, pilot_pulse=2165, pilot_count=1578):
    """TimeCheck's 255 counts when the next pilot starts pilot_start_t after the block's end"""
    edges = [pilot_start_t + n * pilot_pulse for n in range(pilot_count + 1)]
    counts = []
    j = 0
    for s in range(255):
        lo = s * SAMPLE_T
        hi = lo + 255 * POLL_T
        c = 0
        while j < len(edges) and edges[j] < lo:
            j += 1
        m = j
        while m < len(edges) and edges[m] < hi:
            c += 1
            m += 1
        counts.append(c)
    return counts


def timecheck(args):
    c1 = list(bytes.fromhex(args.c1)) if args.c1 else [0] * 255
    pause = int(2.407 * CLOCK)
    short = int(1.0 * CLOCK)
    cut = edge_counts(short)
    W, H = 900, 470
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f, fs = K.font(14), K.font(12)
    x0, x1, tmax = 60, 880, 3.5

    def x(sec):
        return x0 + (x1 - x0) * sec / tmax
    d.text((x0, 10), 'TimeCheck $BE5D: 255 samples of the EAR edges right after the stage block (block 7)', fill=FG,
           font=f)
    # the time axis
    y = 60
    for s in range(0, 8):
        sec = s * 0.5
        d.line((x(sec), y + 40, x(sec), y + 46), fill=DIM)
        d.text((x(sec) - 12, y + 48), f'{sec:.1f} s', fill=DIM, font=fs)
    d.line((x0, y + 40, x1, y + 40), fill=DIM)
    # the original tape
    d.text((4, y + 4), 'tape', fill=FG, font=fs)
    d.rectangle((x(0), y, x(pause / CLOCK), y + 30), outline=DIM)
    d.text((x(0) + 6, y + 8), 'pause 2407 ms (TZX block 7)', fill=DIM, font=fs)
    p_end = (pause + 1578 * 2165) / CLOCK
    d.rectangle((x(pause / CLOCK), y, x(min(p_end, tmax)), y + 30), fill=(40, 70, 110), outline=BLUE)
    d.text((x(pause / CLOCK) + 6, y + 8), 'block 9 pilot, 1578 x 2165 T', fill=FG, font=fs)
    # the samples and windows
    y = 140
    t_end = 255 * SAMPLE_T / CLOCK
    d.text((4, y + 4), 'samples', fill=FG, font=fs)
    for s in range(255):
        xs = x(s * SAMPLE_T / CLOCK)
        colour = YELLOW if 50 <= s <= 99 else (RED if 205 <= s <= 254 else (70, 70, 80))
        d.line((xs, y, xs, y + 24), fill=colour)
    d.text((x(50 * SAMPLE_T / CLOCK), y + 28), 'S1: samples 50-99', fill=YELLOW, font=fs)
    d.text((x(205 * SAMPLE_T / CLOCK) - 40, y + 28), 'S2: samples 205-254', fill=RED, font=fs)
    d.text((x(t_end) + 6, y + 6), f'end {t_end:.3f} s', fill=DIM, font=fs)

    def row(yy, name, counts, verdict, colour):
        d.text((4, yy - 18), name, fill=FG, font=fs)
        top = max(1, max(counts))
        for s, c in enumerate(counts):
            xs = x(s * SAMPLE_T / CLOCK)
            hgt = 40 * c / max(top, 10)
            col = YELLOW if 50 <= s <= 99 else (RED if 205 <= s <= 254 else DIM)
            d.rectangle((xs, yy + 40 - hgt, xs + 2, yy + 40), fill=col)
        d.line((x0, yy + 40, x(t_end), yy + 40), fill=(70, 70, 80))
        s1, s2 = sum(counts[50:100]), sum(counts[205:255])
        d.text((x(t_end) + 6, yy + 4), f'S1 = {s1}, S2 = {s2}', fill=FG, font=fs)
        d.text((x(t_end) + 6, yy + 22), verdict, fill=colour, font=fs)
    s1, s2 = sum(c1[50:100]), sum(c1[205:255])
    ok = (s2 >> 8) < 0x0D and s2 - s1 < 50
    row(230, 'c1: TimeBuffer $9000-$90FE at frame 2484 (all 255 counts 0)', c1,
        'passed' if ok else 'TimeFailed', GREEN if ok else RED)
    s1, s2 = sum(cut[50:100]), sum(cut[205:255])
    ok = (s2 >> 8) < 0x0D and s2 - s1 < 50
    row(330, 'a copy with the pause cut to 1.0 s: the pilot in window S2 (computed)', cut,
        'passed' if ok else f'S2 - S1 >= 50: TimeFailed = 1', GREEN if ok else RED)
    d.text((x0, 400), 'The test (sub_BE94): fail when S2 >= $0D00 (TimeFailed = S2 / 256) or S2 - S1 >= 50 '
           '(TimeFailed = 1);', fill=DIM, font=fs)
    d.text((x0, 418), 'skipped when the ROM byte at $006D is $28 (the +2A / +3 ROM 3; $20 on the 128K and +2 ROM 1).',
           fill=DIM, font=fs)
    d.text((x0, 436), 'A sample: 255 polls of IN ($FE) bit 6, 72 T each, counting the changes; 18 447 T with the '
           'loop.', fill=DIM, font=fs)
    im.save(args.out)
    print(args.out, im.size)


def memgrid(args):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    lo, hi = (int(v, 16) for v in args.range.split('-'))
    lo -= lo % args.row
    span = hi - lo + 1
    nrows = (span + args.row - 1) // args.row
    cell = args.cell
    gw, gh = args.row * cell, nrows * cell
    font = K.font(13)
    label = args.label or ''
    W = max(70 + gw + 20, 860)
    top = 56
    Hh = top + gh + 30

    def moment(text):
        f, _, t = text.partition(':')
        return int(f) * FRAME_T + int(t or 0)

    def mem_at(frame, t):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                         'offset': lo, 'length': span}, ok=False)
        body = r.structured or {}
        if r.is_error or not body.get('exact', False):
            raise SystemExit(f'memory_at {frame}:{t}: {r.text}')
        return bytes.fromhex(body['hex'])
    now, last = moment(args.start), moment(args.end)
    previous, age, pictures = None, {}, []
    while True:
        frame, t = divmod(now, FRAME_T)
        mem = mem_at(frame, t)
        written = 0
        if previous is not None:
            for i in range(span):
                if mem[i] != previous[i]:
                    age[i] = 0
                    written += 1
        im = Image.new('RGB', (W, Hh), BG)
        px = im.load()
        for i in range(span):
            v = mem[i]
            g = 28 + v * 110 // 255
            colour = FADE[min(age[i], len(FADE) - 1)] if i in age else (g, g, g + 6)
            x, y = 70 + (i % args.row) * cell, top + (i // args.row) * cell
            for dy in range(cell - (1 if cell > 4 else 0)):
                for dx in range(cell - (1 if cell > 4 else 0)):
                    px[x + dx, y + dy] = colour
        d = ImageDraw.Draw(im)
        d.text((10, 8), f'{label}', fill=FG, font=font)
        d.text((10, 28), f'frame {frame} t {t}: {written} bytes changed since the last picture; yellow written, '
               f'fading red earlier', fill=DIM, font=font)
        step_rows = max(1, 16 // cell * 4)
        for r in range(0, nrows, step_rows):
            d.text((8, top + r * cell - 2), f'${lo + r * args.row:04X}', fill=DIM, font=font)
        pictures.append(im)
        for i in list(age):
            age[i] += 1
            if age[i] >= len(FADE) * 2:
                del age[i]
        previous = mem
        if now >= last:
            break
        now = min(last, now + args.step)
    durations = [args.delay] * (len(pictures) - 1) + [args.hold]
    pictures[0].save(args.out, save_all=True, append_images=pictures[1:], duration=durations, loop=0, optimize=True)
    print(args.out, len(pictures), 'pictures', pictures[0].size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='mode', required=True)
    c = sub.add_parser('cipher')
    c.add_argument('--stores', default=os.path.join(CASE, 'work', 'stage2', 'stores.txt'))
    c.add_argument('--count', type=int, default=20)
    c.add_argument('out')
    t = sub.add_parser('timecheck')
    t.add_argument('--c1', default='')
    t.add_argument('out')
    m = sub.add_parser('memgrid')
    m.add_argument('--work', required=True)
    m.add_argument('--from', dest='start', required=True)
    m.add_argument('--to', dest='end', required=True)
    m.add_argument('--step', type=int, required=True)
    m.add_argument('--range', required=True)
    m.add_argument('--row', type=int, default=64)
    m.add_argument('--cell', type=int, default=8)
    m.add_argument('--label', default='')
    m.add_argument('--delay', type=int, default=120)
    m.add_argument('--hold', type=int, default=2000)
    m.add_argument('out')
    args = p.parse_args()
    {'cipher': cipher, 'timecheck': timecheck, 'memgrid': memgrid}[args.mode](args)


if __name__ == '__main__':
    main()
