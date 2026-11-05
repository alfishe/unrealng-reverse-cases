"""The 48K image of a recording's saved pages (W/snapshots/NNNNNN/ram-*.bin, every 250 frames): the reads of the
zyB figure scripts that need no live instance."""
import os

BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000}


def image(work, frame):
    """64 K: the ROM area zero, pages 5, 2, 0 at $4000, $8000, $C000 (the 48K map of case.json)"""
    mem = bytearray(0x10000)
    d = os.path.join(work, 'snapshots', f'{frame:06d}')
    for page, base in BASES.items():
        mem[base:base + 0x4000] = open(os.path.join(d, f'ram-{page}.bin'), 'rb').read()
    return mem


def frames(work):
    d = os.path.join(work, 'snapshots')
    return sorted(int(n) for n in os.listdir(d) if n.isdigit())
