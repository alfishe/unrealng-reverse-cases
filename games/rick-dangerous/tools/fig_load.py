#!/usr/bin/env python3
"""Doc 03 figures: the tape as a timeline, the Bleepload block formats byte by byte, the loader's screens.

    python3 tools/fig_load.py tape docs/img/load/tape.png
    python3 tools/fig_load.py format docs/img/load/blocks.png
    python3 tools/fig_load.py screens work/docs/rdA/shots docs/img/load/screens.png

The tape timeline is computed from orig/'s TZX alone (pulse lengths in T-states at 3.5 MHz, the pauses in ms). The c1
frame axis is placed by one event: Rick1 runs at c1 frame 1210 (find_last execute $CD00), right after its block ends.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import bleepload as B  # noqa: E402
import kitlib as K  # noqa: E402
import tzxblocks  # noqa: E402

BG, TEXT, DIM, FRAME = (24, 24, 30), (235, 235, 235), (170, 170, 180), (110, 110, 140)
CLOCK = 3_500_000
FRAME_T = 70908 * 50 / CLOCK  # the 128K frame in seconds is 70908 T at 3.5469 MHz; c1 counts 50 a second
COLOURS = {'basic': (90, 160, 230), 'rick1': (90, 200, 230), 'key': (240, 220, 80), 'screen': (220, 110, 200),
           'low': (240, 150, 60), 'loadgroup': (250, 90, 70), 'stage2': (120, 230, 120), 'decoy': (150, 150, 150),
           'g2': (110, 130, 240), 'g3': (60, 200, 170), 'tone': (90, 90, 110)}


def bits(data):
    return sum(bin(b).count('1') for b in data), len(data) * 8


def block_seconds(b):
    t = b['timing']
    ones, total = bits(b['data'])
    pulses = t['pilot'] * t['pilot_pulses'] + t['sync1'] + t['sync2'] + 2 * (ones * t['one'] + (total - ones) * t['zero'])
    return pulses / CLOCK, b.get('pause', 0) / 1000


def timeline():
    """[(start s, data s, pause s, what, label)] for every block of the tape"""
    std = dict(pilot=2168, sync1=667, sync2=735, zero=855, one=1710)
    out, now, g1n = [], 0.0, 0
    for b in tzxblocks.parse(B.original_tzx()):
        if b['kind'] == 'standard':
            t = dict(std, pilot_pulses=b['timing']['pilot_pulses'])
            d, p = block_seconds(dict(b, timing=t))
            what = 'basic' if b['index'] < 3 else 'rick1'
            out.append((now, d, p, what, 'header' if b['data'][0] == 0 else what))
            now += d + p
        elif b['kind'] == 'pure tone':
            d = b['timing']['pulse'] * b['timing']['count'] / CLOCK
            out.append((now, d, 0, 'tone', 'tone'))
            now += d
        elif b['kind'] == 'pause':
            now += b['pause'] / 1000
        elif b['kind'] == 'turbo':
            d, p = block_seconds(b)
            m, dest = b['data'][1], b['data'][1 + 0x102] | b['data'][1 + 0x103] << 8
            if m == 0x64:
                what = ('key' if dest == 0xC900 else 'stage2' if dest == 0x5D00 else 'screen' if dest < 0xEA00 else 'low' if dest < 0xFA00 else
                        'loadgroup' if dest < 0xFC00 else 'stage2' if dest == 0x5D00 else 'decoy')
                g1n += 1
            else:
                what = 'g2' if m == 0x34 else 'g3'
            out.append((now, d, p, what, f'{dest:04X}'))
            now += d + p
    return out


def tape(png):
    tl = timeline()
    total = tl[-1][0] + tl[-1][1] + tl[-1][2]
    rick1_end = [x for x in tl if x[3] == 'rick1' and x[4] == 'rick1'][0]
    rick1_end = rick1_end[0] + rick1_end[1]
    offset = 1210 - rick1_end * 50  # c1 frame = offset + 50 * second
    W, left, right = 1050, 150, 30
    span = W - left - right
    x = (lambda s: left + s / total * span)
    f_t, f_l, f_s = K.font(24), K.font(17), K.font(15)
    lanes = [('BASIC, Rick1', ('basic', 'rick1')), ('group 1: key', ('key',)), ('group 1: screen', ('screen',)),
             ('group 1: $5E00', ('low',)), ('group 1: loaders', ('loadgroup', 'stage2', 'decoy')),
             ('group 2', ('g2',)), ('group 3', ('g3',)), ('lead tones', ('tone',))]
    lane_h, top = 46, 130
    H = top + len(lanes) * lane_h + 210
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 10), f'The tape: 4 ROM blocks, then 194 Bleepload blocks ({total:.1f} s)',
           fill=TEXT, font=f_t)
    d.text((12, 46), 'Each bar = one block from its first pilot pulse to its last bit; gaps = the pauses. '
           'Time from orig/\'s TZX.', fill=DIM, font=f_s)
    # axes: seconds below, c1 frames above
    ay = top - 18
    for s in range(0, int(total) + 1, 50):
        d.line([(x(s), ay + 4), (x(s), top + len(lanes) * lane_h)], fill=(50, 50, 60))
        d.text((x(s) - 10, top + len(lanes) * lane_h + 4), f'{s} s', fill=DIM, font=f_s)
    for fr in range(0, 20001, 2500):
        s = (fr - offset) / 50
        if 0 <= s <= total:
            d.line([(x(s), ay - 2), (x(s), ay + 6)], fill=TEXT)
            d.text((x(s) - 18, ay - 24), f'{fr}', fill=TEXT, font=f_s)
    d.text((12, ay - 24), 'c1 frame', fill=TEXT, font=f_s)
    d.text((12, top + len(lanes) * lane_h + 4), 'tape time', fill=DIM, font=f_s)
    for i, (name, kinds) in enumerate(lanes):
        y = top + i * lane_h
        d.text((12, y + 12), name, fill=TEXT, font=f_l)
        for s0, ds, _p, what, _lab in tl:
            if what in kinds:
                d.rectangle((x(s0), y + 8, max(x(s0) + 1, x(s0 + ds)), y + lane_h - 8), fill=COLOURS[what])
    # events of c1 (find_last execute)
    events = [(1210, 'Rick1 $CD00'), (5473, 'stage 2 $5D00'), (5571, 'LoadGroup: group 2'),
              (18069, 'group 3'), (19010, 'game entry $AB4D')]
    ey = top + len(lanes) * lane_h + 40
    for j, (fr, label) in enumerate(events):
        s = (fr - offset) / 50
        xx = x(s)
        d.line([(xx, top), (xx, ey + 10 + 24 * j)], fill=(255, 255, 255), width=1)
        tw_ = d.textlength(f'c1 {fr}: {label}', font=f_l)
        tx = xx + 4 if xx + 4 + tw_ < W - 8 else xx - 4 - tw_
        d.text((tx, ey + 2 + 24 * j), f'c1 {fr}: {label}', fill=TEXT, font=f_l)
    ky = ey + 130
    kx = 12
    for what, label in (('basic', 'BASIC'), ('rick1', 'Rick1'), ('key', 'key page'), ('screen', 'screen (keyed)'),
                        ('low', '$5E00 (keyed)'), ('loadgroup', 'LoadGroup'), ('stage2', 'stage 2'),
                        ('decoy', 'decoy'), ('g2', 'group 2'), ('g3', 'group 3')):
        d.rectangle((kx, ky + 4, kx + 14, ky + 18), fill=COLOURS[what])
        d.text((kx + 18, ky), label, fill=TEXT, font=f_s)
        kx += 18 + d.textlength(label, font=f_s) + 14
    img.save(png)
    print(png, img.size, f'total {total:.2f} s, c1 offset {offset:.0f}')
    return tl


def fmt(png):
    W = 1050
    f_t, f_b, f_s = K.font(24), K.font(16), K.font(14)
    rows = [
        ('Group 1 block (marker $64, read by Rick1 LoadBlock $CD6E), $109 + N bytes', [
            ('$FE00', 1, 'marker $64', (240, 220, 80)),
            ('$FE01', 256, 'payload, 256 bytes (keyed in $CF00-$FBFF and $5D40-$5DFF)', (220, 110, 200)),
            ('$FF01', 1, 'number', (90, 200, 230)), ('$FF02', 2, 'dest', (120, 230, 120)),
            ('$FF04', 1, 'N', (240, 150, 60)), ('$FF05', 8, 'N filler bytes, 1-8', (110, 110, 130)),
            ('', 3, 'JP $CD1B', (250, 90, 70)), ('', 1, 'XOR', (255, 255, 255))]),
        ('Group 2 and 3 block (markers $34, $35, read by LoadGroup $FA85), 265 bytes', [
            ('$FE00', 1, 'marker', (240, 220, 80)),
            ('$FE01', 256, 'payload, each byte XOR the high byte of its dest', (110, 130, 240)),
            ('$FF01', 1, 'number', (90, 200, 230)), ('$FF02', 2, 'dest', (120, 230, 120)),
            ('$FF04', 1, '0', (110, 110, 130)), ('$FF05', 1, 'end', (240, 150, 60)),
            ('$FF06', 2, 'go', (250, 90, 70)), ('$FF08', 1, 'XOR', (255, 255, 255))]),
    ]
    img = Image.new('RGB', (W, 560), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 10), 'Bleepload blocks byte by byte: every block loads at $FE00', fill=TEXT, font=f_t)
    d.text((12, 46), 'Payload 1 px a byte, other fields 52 px a byte, filler 16. TZX adds flag $FF '
           'and a ROM XOR around each block.', fill=DIM, font=f_s)
    y = 90
    for title, fields in rows:
        d.text((12, y), title, fill=TEXT, font=f_b)
        y += 30
        xx = 12
        for addr, n, label, col in fields:
            w = 256 if n == 256 else (16 * n if n == 8 else 52 * n)
            d.rectangle((xx, y, xx + w - 2, y + 54), fill=col, outline=BG)
            if addr:
                d.text((xx + 2, y + 58), addr, fill=DIM, font=f_s)
            if w >= 60:
                d.text((xx + 6, y + 18), label.split(',')[0], fill=(0, 0, 0), font=f_s)
            xx += w
        # labels list below for the narrow fields
        y += 84
        names = '; '.join(f'{lab}' for _a, _n, lab, _c in fields)
        for line in K_wrap(names, d, f_s, W - 24):
            d.text((12, y), line, fill=DIM, font=f_s)
            y += 20
        y += 24
    d.text((12, y), 'Group 1: XOR of marker..JP; its bits 0-2, plus 1, are the next block\'s N (8 for the first).', fill=TEXT, font=f_s)
    d.text((12, y + 24), 'Groups 2, 3: XOR of $FE01-$FF07; end = the page after the group; go = the jump after it (0: return).', fill=TEXT, font=f_s)
    img = img.crop((0, 0, W, y + 60))
    img.save(png)
    print(png, img.size)


def K_wrap(text, d, font, width):
    words, line, out = text.split(' '), '', []
    for w in words:
        t = (line + ' ' + w).strip()
        if d.textlength(t, font=font) > width:
            out.append(line)
            line = w
        else:
            line = t
    out.append(line)
    return out


def screens(shots, png):
    picks = [('basic', 'c1 700: the BASIC has printed the title; LOAD "Rick1" CODE runs'),
             ('rick1', 'c1 3000: Rick1 loads group 1, "Loading 11" = block $11'),
             ('stage2', 'c1 5500: block $2E (stage 2) loads; the screen is still plain'),
             ('g2', 'c1 5600: stage 2 has shown the screen; LoadGroup searches group 2'),
             ('g3', 'c1 18600: screen cleared; group 3 loads unseen into $4000'),
             ('menu', 'c1 30250: the menu, the game running')]
    W, cols, gap = 1050, 3, 12
    tw = (W - gap * (cols + 1)) // cols
    ims = [Image.open(os.path.join(shots, f'{n}.png')).convert('RGB') for n, _ in picks]
    th = round(ims[0].height * tw / ims[0].width)
    f_t, f_s = K.font(24), K.font(15)
    rows = (len(picks) + cols - 1) // cols
    img = Image.new('RGB', (W, 56 + rows * (th + 56)), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 12), 'The load as the player sees it (c1: power-on, original TZX)', fill=TEXT, font=f_t)
    for i, ((_n, cap), im) in enumerate(zip(picks, ims)):
        x0 = gap + (i % cols) * (tw + gap)
        y0 = 56 + (i // cols) * (th + 56)
        img.paste(im.resize((tw, th), Image.LANCZOS), (x0, y0))
        for k, line in enumerate(K_wrap(cap, d, f_s, tw)):
            d.text((x0, y0 + th + 4 + 18 * k), line, fill=TEXT, font=f_s)
    img.save(png)
    print(png, img.size)


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'tape':
        tape(sys.argv[2])
    elif cmd == 'format':
        fmt(sys.argv[2])
    elif cmd == 'screens':
        screens(sys.argv[2], sys.argv[3])
