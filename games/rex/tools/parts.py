#!/usr/bin/env python3
"""Cut every part of Rex out of the original tape (orig/Rex.tzx.zip) into work/parts/, the images kit/mkgame.py
reads (case.json, src/*/*.json):

    python3 tools/parts.py

    work/parts/basic-rex1.img, basic-rex2.img, basic-demo.img   the BASIC programs at PROG $5CCB in a 64 K image
    work/parts/screen-rex1.bin, screen-rex2.bin, screen-demo.bin the loading screens (6912 bytes, at $4000)
    work/mkgame/original.bin                                     part 1 (REX 1): screen and code as the ROM leaves them
    work/parts/rex2.img, work/parts/demo.img                     part 2 (REX 2) and DEMO, the same way

Side 1 is "Rex - Side 1.tzx" (blocks 1-6 REX 1, 7-12 REX 2), side 2 "Rex - Side 2.tzx" (blocks 1-6 DEMO); block 0
of each is the TZX text block (docs/03-build-and-load.md 3.1).
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402

SIDES = {1: 'Rex - Side 1.tzx', 2: 'Rex - Side 2.tzx'}
# part -> (side, the BASIC's data block, the screen's data block, the code's header block, the code's data block)
PARTS = {'rex1': (1, 2, 4, 5, 6), 'rex2': (1, 8, 10, 11, 12), 'demo': (2, 2, 4, 5, 6)}
PROG = 0x5CCB


def side(n):
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'Rex.tzx.zip')) as z:
        return z.read(SIDES[n])


def blocks(n):
    return list(tzxblocks.parse(side(n)))


def part(name):
    """{'basic', 'screen', 'code', 'start'} of one part: the blocks' data without flag and checksum."""
    s, bas, scr, hdr, code = PARTS[name]
    b = blocks(s)
    h = b[hdr]['data']
    return dict(basic=b[bas]['data'][1:-1], screen=b[scr]['data'][1:-1], code=b[code]['data'][1:-1],
                start=h[14] | h[15] << 8)


def image(name):
    p = part(name)
    mem = bytearray(65536)
    mem[0x4000:0x5B00] = p['screen']
    mem[p['start']:p['start'] + len(p['code'])] = p['code']
    return bytes(mem)


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)


def main():
    w = os.path.join(CASE, 'work', 'parts')
    for name in PARTS:
        p = part(name)
        mem = bytearray(65536)
        mem[PROG:PROG + len(p['basic'])] = p['basic']
        write(os.path.join(w, f'basic-{name}.img'), bytes(mem))
        write(os.path.join(w, f'screen-{name}.bin'), p['screen'])
        img = image(name)
        write(os.path.join(CASE, 'work', 'mkgame', 'original.bin') if name == 'rex1'
              else os.path.join(w, f'{name}.img'), img)
        print(f'{name}: BASIC {len(p["basic"])} bytes, code ${p["start"]:04X}-${p["start"] + len(p["code"]) - 1:04X}')


if __name__ == '__main__':
    main()
