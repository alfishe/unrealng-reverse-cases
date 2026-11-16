#!/usr/bin/env python3
"""The stages' first map: per stage, the horizon its table entry at $9E67 names (4 bytes a stage: the horizon's
address, its rows, the horizon line), drawn from the entry image, next to a recorded screen of that stage.

    python3 tools/stage_map.py IMAGE.cpu.bin OUT.png SHOT1.png ... SHOT5.png"""
import sys
from PIL import Image, ImageDraw, ImageFont

img = open(sys.argv[1], 'rb').read()
shots = sys.argv[3:]
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 15)
rows = []
for k, shot in enumerate(shots):
    e = img[0x9E67 + 4 * k:0x9E6B + 4 * k]
    addr, h, line = e[0] | e[1] << 8, e[2], e[3]
    hz = Image.new('L', (256, h))
    px = hz.load()
    for y in range(h):
        for x in range(256):
            px[x, y] = 0 if img[addr + y * 32 + x // 8] & (0x80 >> (x % 8)) else 255
    rows.append((k, addr, h, line, hz.resize((512, 2 * h), Image.NEAREST).convert('RGB'),
                 Image.open(shot).convert('RGB').resize((256, 192), Image.NEAREST)))
W, RH = 512 + 256 + 30, 192 + 30
out = Image.new('RGB', (W, RH * len(rows)), 'white')
d = ImageDraw.Draw(out)
for i, (k, addr, h, line, hz, sh) in enumerate(rows):
    y = i * RH
    d.text((6, y + 6), f'Stage {k + 1}: horizon ${addr:04X}, {h} rows, table byte 3 = {line}', fill='black', font=font)
    out.paste(hz, (6, y + 30 + (192 - hz.height) // 2))
    out.paste(sh, (512 + 20, y + 28))
out.save(sys.argv[2])
print(sys.argv[2], out.size)
