#!/usr/bin/env python3
"""The game image as the tape's loader leaves it, cut from orig/ATVSimulator.tzx.zip: a 64 K file with the loading
screen (tape block 5) at `$4000` and the game (block 7, 40000 bytes) at `$6338`, the rest zero. The loader at `$FFDC`
(block 3) is left out: the game's image ends at `$FF77`.

    python3 tools/image.py OUT.bin
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import tapblocks  # noqa: E402


def main():
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'ATVSimulator.tzx.zip')) as z:
        raw = z.read('ATV Simulator.tzx')
    blocks = [b for b in tapblocks.parse_tzx(raw) if b.get('data')]
    data = [bytes(b['data'][1:-1]) for b in blocks]
    assert len(data[5]) == 6912 and len(data[7]) == 40000, [len(d) for d in data]
    img = bytearray(0x10000)
    img[0x4000:0x5B00] = data[5]
    img[0x6338:0x6338 + 40000] = data[7]
    with open(sys.argv[1], 'wb') as f:
        f.write(img)


if __name__ == '__main__':
    main()
