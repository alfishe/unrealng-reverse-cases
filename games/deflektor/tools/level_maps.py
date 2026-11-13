#!/usr/bin/env python3
"""Every level drawn from the data by the game's own code: SkoolKit's simulator runs LevelSetup `$891A` over the
entry image (tools/image.py) with the level variable `$81FF` set, and the play-area buffers it fills are turned into
a picture. `$891A` takes the level's 135 bytes (15 x 9 cells) from `$B000 + $87 x level` (address kept at `$8912`),
copies them to the grid `$FD23` (17 bytes a row), and `$8960` turns each cell into four 8 x 8 character codes through
the table `$8200` (4 codes a cell code) in the map `$E000` (32 a row); `$8A09` draws each code's 8 bytes from
`$D700 + 8 x code` into the pixel buffer `$E900` (32 bytes a pixel row, 20 character rows) and its colour from
`$DF00 + code` into `$E600`. The beam is not drawn: it comes later, in play.

    python3 tools/level_maps.py docs/img/maps [--scale 2]

Writes level-NN.png (NN = level number 01-61, the slot + 1; slot `$3C` = 61 is the practice level), all.png (the 60
levels and the practice one), and levels.json (each level's address and its 135 cell codes).
"""
import argparse
import json
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit.simulator import Simulator  # noqa: E402
from PIL import Image  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
IMAGE = os.path.join(HERE, '..', 'work', 'mkgame', 'original.bin')
PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205),
       (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]


def draw_level(img, level):
    mem = bytearray(img)
    mem[0x81FF] = level
    sp = 0x5F00
    mem[sp] = mem[sp + 1] = 0
    sim = Simulator(mem, {'PC': 0x891A, 'SP': sp})
    steps = 0
    while sim.registers[24] != 0:
        sim.run()
        steps += 1
        if steps > 3000000:
            raise SystemExit(f'level {level}: $891A did not return')
    return bytes(sim.memory)


def picture(m, rows=20):
    im = Image.new('RGB', (256, rows * 8))
    px = im.load()
    for r in range(rows):
        for c in range(32):
            a = m[0xE600 + r * 32 + c]
            ink, paper = PAL[(a & 7) + (8 if a & 64 else 0)], PAL[((a >> 3) & 7) + (8 if a & 64 else 0)]
            for k in range(8):
                b = m[0xE900 + (r * 8 + k) * 32 + c]
                for x in range(8):
                    px[c * 8 + x, r * 8 + k] = ink if b & (0x80 >> x) else paper
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--scale', type=int, default=2)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    img = open(IMAGE, 'rb').read()
    info, pics = [], []
    for lv in range(61):
        m = draw_level(img, lv)
        addr = 0xB000 + 0x87 * lv
        pic = picture(m).crop((0, 0, 256, 160))
        pics.append(pic)
        pic.resize((256 * args.scale, 160 * args.scale), Image.NEAREST).save(os.path.join(args.out, f'level-{lv + 1:02d}.png'))
        info.append({'level': lv + 1, 'slot': lv, 'addr': f'${addr:04X}', 'cells': img[addr:addr + 0x87].hex()})
    cols = 6
    sheet = Image.new('RGB', (cols * 264, ((len(pics) + cols - 1) // cols) * 168), (40, 40, 40))
    for i, p in enumerate(pics):
        sheet.paste(p, ((i % cols) * 264 + 4, (i // cols) * 168 + 4))
    sheet.save(os.path.join(args.out, 'all.png'))
    json.dump(info, open(os.path.join(args.out, 'levels.json'), 'w'), indent=1)


if __name__ == '__main__':
    main()
