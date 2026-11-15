#!/usr/bin/env python3
"""Doc 7 and doc 10's figures of the play state:

    python3 tools/fig_objects.py vars SAMPLES.jsonl OUT.png   the game variables over a recording, a lane each
    python3 tools/fig_objects.py random ROM OUT.png           the boss blast's places: NextRandom over the ROM

SAMPLES.jsonl is a line per sample: {"f": frame, "v": hex of $7A80-$7AEF, "s": hex of the slots $8501-$85FC}, the
memory at the start of frame f (work/docs/rtC/sample.py writes it from a recording's work directory). ROM is the 16 KB
48K ROM: BossDestroyed `$C19C` sets RandomPtr to 0, so the explosions take their places from its first bytes.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

W = 1050
BASE = 0x7A80
# (label, address, max, colour, kind): kind 'line' draws a stepped line, 'flag' a filled band
LANES = [('MapColumn', 0x7A84, 130, (40, 120, 200), 'line'),
         ('ScrollHalted', 0x7A8E, 1, (200, 60, 60), 'flag'),
         ('WavesHalted', 0x7A8F, 0x41, (120, 40, 40), 'flag'),
         ('ShooterLimit', 0x7A9E, 8, (230, 140, 30), 'line'),
         ('Shooters', 0x7A9F, 8, (230, 180, 60), 'line'),
         ('enemy slots in use', None, 28, (150, 60, 170), 'line'),
         ('ForceLevel', 0x7ABE, 3, (40, 150, 70), 'line'),
         ('WeaponKind', 0x7ABD, 3, (90, 180, 90), 'line'),
         ('ForceAttached', 0x7AA3, 2, (30, 110, 50), 'line'),
         ('BitUpper + BitLower', (0x7AA5, 0x7AA6), 2, (60, 160, 160), 'line'),
         ('MissilesOn', 0x7AA7, 1, (60, 100, 160), 'flag'),
         ('BeamPower', 0x7AC0, 0x1E, (200, 60, 160), 'line'),
         ('ShieldTimer', 0x7A98, 0x30, (160, 160, 40), 'line')]


def font(size):
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def value(sample, lane):
    _, addr, _, _, _ = lane
    v = bytes.fromhex(sample['v'])
    if addr is None:
        s = bytes.fromhex(sample['s'])
        return sum(1 for k in range(28) if s[9 * k] & 0x3F)
    if isinstance(addr, tuple):
        return sum(1 for a in addr if v[a - BASE])
    return v[addr - BASE]


def cmd_vars(path, out):
    samples = [json.loads(line) for line in open(path)]
    f0, f1 = samples[0]['f'], samples[-1]['f']
    lane_h, top, left, right = 46, 60, 190, W - 50
    H = top + lane_h * len(LANES) + 60
    img = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(img)
    d.text((10, 10), f'The game variables over l1, frames {f0}-{f1}, a sample every '
                     f'{samples[1]["f"] - f0} frames (the memory at the frame\'s start)', fill='black', font=font(17))
    d.text((10, 34), 'each lane from 0 to the value at its right; filled bands are flags', fill=(80, 80, 80),
           font=font(14))

    def x_of(f):
        return left + (right - left) * (f - f0) / (f1 - f0)

    for i, lane in enumerate(LANES):
        name, _, vmax, col, kind = lane
        y0 = top + i * lane_h
        y1 = y0 + lane_h - 10
        d.rectangle([left, y0, right, y1], outline=(210, 210, 210))
        d.text((10, y0 + 8), name, fill='black', font=font(14))
        d.text((right + 5, y0 + 1), f'{vmax}', fill=(120, 120, 120), font=font(13))
        prev = None
        for s in samples:
            v = min(value(s, lane), vmax)
            x = x_of(s['f'])
            y = y1 - (y1 - y0 - 4) * v / vmax
            if kind == 'flag':
                if v:
                    d.rectangle([x, y0 + 4, x + (right - left) / len(samples) + 1, y1], fill=col)
            else:
                if prev:
                    d.line([prev[0], prev[1], x, prev[1], x, y], fill=col, width=2)
                prev = (x, y)
    yb = top + lane_h * len(LANES)
    for f in range(0, f1 + 1, 1000):
        if f < f0:
            continue
        x = x_of(f)
        d.line([x, yb - 6, x, yb], fill='black')
        d.text((x - 14, yb + 2), str(f), fill='black', font=font(13))
    d.text((left, yb + 24), 'frame of l1', fill='black', font=font(14))
    img.save(out)


def next_random(rom, ptr):
    while True:
        ptr += 1
        a = rom[ptr] & 0x1F
        if a:
            return a, ptr


def cmd_random(rom_path, out):
    rom = open(rom_path, 'rb').read()
    ptr, places = 0, []
    while len(places) < 128:
        c, ptr = next_random(rom, ptr)
        while c >= 0x1E:
            c, ptr = next_random(rom, ptr)
        b, ptr = next_random(rom, ptr)
        while b >= 0x12:
            b, ptr = next_random(rom, ptr)
        places.append((c, b, ptr))
    cell = 28
    left, top = 40, 70
    H = top + 20 * cell + 70
    img = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(img)
    d.text((10, 10), 'BossBlastOnce: the first 128 places NextRandom gives after BossDestroyed sets RandomPtr = 0',
           fill='black', font=font(17))
    d.text((10, 36), 'column from bytes below $1E, row below $12, both AND $1F of the 48K ROM from address 1; '
                     'a number is the draw\'s order', fill=(80, 80, 80), font=font(14))
    for r in range(20):
        for c in range(32):
            d.rectangle([left + c * cell, top + r * cell, left + (c + 1) * cell, top + (r + 1) * cell],
                        outline=(225, 225, 225), fill=(245, 245, 245) if 1 <= r < 18 and 1 <= c < 30 else (255, 235, 235))
    seen = {}
    for i, (c, b, _) in enumerate(places):
        seen.setdefault((c, b), []).append(i)
    for (c, b), idx in seen.items():
        x, y = left + c * cell, top + b * cell
        shade = max(60, 230 - 40 * len(idx))
        d.rectangle([x + 1, y + 1, x + cell - 1, y + cell - 1], fill=(255, shade, 60))
        d.text((x + 3, y + 6), str(idx[0]), fill='black', font=font(13))
    d.text((left, top + 20 * cell + 8), f'{len(seen)} different cells in 128 draws; the pink border (columns 0, 30, 31, '
           f'rows 0, 18, 19) is never drawn; RandomPtr ends at ${places[-1][2]:04X}', fill='black', font=font(14))
    d.text((left, top + 20 * cell + 30), 'a draw explodes only where SolidMap holds $80 or more (the cells '
           'BossDestroyed set to $FF); a miss draws again, 128 tries a blast', fill='black', font=font(14))
    img.save(out)


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__)
    elif a[0] == 'vars':
        cmd_vars(a[1], a[2])
    elif a[0] == 'random':
        cmd_random(a[1], a[2])


if __name__ == '__main__':
    main()
