#!/usr/bin/env python3
"""The 64 K image of the game as the tape leaves it on a 128K, cut from orig/RickDangerous2.tzx.zip: side A's loader
block (256 bytes, standard ROM blocks, still encrypted) at `$FF00`, then the two headerless blocks the loader reads
with its own copy of LD-BYTES, which shifts every byte in reversed bit order (`LD L,$80` / `RR L`): the screen (6912
bytes) at `$4000` and the code (40 702 bytes) at `$6000-$FEFD`
([doc 3, 3.1](../docs/03-build-and-load.md#31-the-tape-block-by-block)). With --level N the image has side B's level
block N (21 760 bytes, bit-reversed the same way) at `$A800-$FCFF`, as the level loader leaves it (its maps' last
768 bytes still encrypted: `decrypt_maps`).

    python3 tools/image.py work/mkgame/original.bin [--level N]
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402

SIDES = {'A': 'Rick Dangerous 2 - Side A.tzx', 'B': 'Rick Dangerous 2 - Side B.tzx'}
REV = bytes(int(f'{i:08b}'[::-1], 2) for i in range(256))


def blocks(side):
    with zipfile.ZipFile(os.path.join(HERE, '..', 'orig', 'RickDangerous2.tzx.zip')) as z:
        t = z.read(SIDES[side])
    return [b['data'] for b in tzxblocks.parse(t) if b.get('data')]


def unreverse(raw):
    """A headerless block of the loader: flag, data and checksum all bit-reversed; the XOR of all bytes is `$FF`"""
    x = 0
    for c in raw:
        x ^= c
    assert x == 0xFF, 'not the inverted checksum'
    return raw[1:-1].translate(REV)


def decrypt_maps(mem):
    """The last 768 bytes of a level's maps (from the maps' base `$C204` + `$600`) are encrypted on the tape; `$894E`
    decrypts them when the level starts: each byte XOR a key that starts at 0 and becomes (key XOR the address's low
    byte) + 1. Level 1 in side A's code block is stored decrypted already."""
    mem = bytearray(mem)
    hl = (mem[0xC204] | mem[0xC205] << 8) + 0x600
    key = 0
    for _ in range(768):
        mem[hl] ^= key
        key = ((key ^ (hl & 0xFF)) + 1) & 0xFF
        hl += 1
    return bytes(mem)


def image(level=None):
    hdr, basic, lhdr, loader, screen, code = blocks('A')
    img = bytearray(0x10000)
    img[0x4000:0x5B00] = unreverse(screen)
    img[0x6000:0xFEFE] = unreverse(code)
    img[0xFF00:0x10000] = loader[1:-1]
    if level:
        lv = unreverse(blocks('B')[level - 1])
        img[0xA800:0xA800 + len(lv)] = lv
    return bytes(img)


if __name__ == '__main__':
    out = sys.argv[1]
    level = int(sys.argv[sys.argv.index('--level') + 1]) if '--level' in sys.argv else None
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    open(out, 'wb').write(image(level))
    print(f'{out}: 65536 bytes')
