#!/usr/bin/env python3
"""The parts of the medium as images, cut from orig/RickDangerous2.tzx.zip alone (tools/image.py), each the bytes a
part file (src/*/*.json) assembles to:

    python3 tools/parts.py            # writes work/parts/*.bin and work/mkgame/original.bin

| File | What | Where it runs |
| --- | --- | --- |
| `basic-5ccb.bin` | side A block 2, the BASIC "RICK-II" (75 bytes) | PROG `$5CCB` |
| `loader-ff00.bin` | side A block 4, the loader, decrypted (XOR `$5C` from `$FF0B`, as its first loop does) | `$FF00` |
| `screen-4000.bin` | side A block 5, the loading screen (bits put back in order) | `$4000` |
| `music-c000.bin` | side A block 6 bytes 0-`$107F` (`$6000-$707F`): the AY music, copied to RAM 1 `$C000` | RAM 1 `$C000` |
| `levelN-a800.bin` | level N (21 760 bytes): level 1 as side A's block 6 holds it (`$A800-$FCFF`); levels 2-5 side B's blocks with the maps' last 768 bytes deciphered as `$894E` does | `$A800` |

The game (`$7080-$A7FF`) is cut from work/mkgame/original.bin by case.json.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import image as I  # noqa: E402

KEY = 0x5C  # the loader's XOR key: IYH, the ROM's IY = $5C3A
CRYPT_FROM = 0x0B  # the first enciphered byte, $FF0B


def crypt_loader(data):
    """the loader's cipher both ways: every byte from $FF0B XOR $5C (the loop $FF00-$FF0A)"""
    return bytes(data[:CRYPT_FROM]) + bytes(b ^ KEY for b in data[CRYPT_FROM:])


def crypt_maps(level):
    """the maps' cipher both ways on a 21 760-byte level image at $A800 (tools/image.py decrypt_maps)"""
    mem = bytearray(0x10000)
    mem[0xA800:0xA800 + len(level)] = level
    return I.decrypt_maps(bytes(mem))[0xA800:0xA800 + len(level)]


def parts():
    hdr, basic, lhdr, loader, screen, code = I.blocks('A')
    img = I.image()
    out = {
        'basic-5ccb.bin': basic[1:-1],
        'loader-ff00.bin': crypt_loader(loader[1:-1]),
        'screen-4000.bin': I.unreverse(screen),
        'music-c000.bin': img[0x6000:0x7080],
        'level1-a800.bin': img[0xA800:0xFD00],
    }
    for n, raw in enumerate(I.blocks('B')[1:], 2):
        out[f'level{n}-a800.bin'] = crypt_maps(I.unreverse(raw))
    return out, img


def main():
    folder = os.path.join(CASE, 'work', 'parts')
    os.makedirs(folder, exist_ok=True)
    out, img = parts()
    for name, data in out.items():
        open(os.path.join(folder, name), 'wb').write(data)
        print(f'work/parts/{name}: {len(data)} bytes')
    os.makedirs(os.path.join(CASE, 'work', 'mkgame'), exist_ok=True)
    open(os.path.join(CASE, 'work', 'mkgame', 'original.bin'), 'wb').write(img)


if __name__ == '__main__':
    main()
