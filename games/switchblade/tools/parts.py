#!/usr/bin/env python3
"""The images of the case's parts, cut from orig/Switchblade.tzx.zip alone, for kit/mkgame.py (case.json and the
part files; docs/03-build-and-load.md 3.1):

    python3 tools/parts.py            # writes work/parts/*.bin and work/mkgame/resident.bin

| File | What | Org |
| --- | --- | --- |
| basic-5ccb.bin | TZX block 2: the BASIC line 0, its code, and the tape loader the code copies to `$FF00` (361 bytes) | `$5CCB` (PROG) |
| stage2-609c.bin | TZX block 3: the loader's second stage (2060 bytes) | `$609C` |
| boot-4000.bin | TZX block 5 `$4000-$4145`: the bootstrap and the 162-byte AY glue it copies to `$853F` on a 128K | `$4000` |
| bank4-c000.bin | TZX block 6: bank 4, the AY player, its tunes and the story pages (8441 bytes) | `$C000` |
| work/mkgame/resident.bin | the 64 K view of the game as it runs (the game's part, case.json): block 4 at `$6B5C-$FDFC`, block 5's `$4146-$5092` copied to `$5C00-$6B4C` and `$5093-$5190` to `$FF01-$FFFE` (the bootstrap's own copies, ResidentLow and ResidentHigh), zeros elsewhere | |

The bootstrap copies its pieces without changing a byte, so the game's part assembles them at their run addresses
and the tape's block 5 is the bootstrap followed by those two stretches of the game's assembled image
(src/tape/tape.txt, tools/mktape.py).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import image  # noqa: E402

BOOT, BOOT_END = 0x4000, 0x4146          # the bootstrap and the glue: block 5's first $146 bytes
LOW, LOW_FROM, LOW_LEN = 0x5C00, 0x4146, 0x0F4D     # BootCopyLow: $4146 -> $5C00
HIGH, HIGH_FROM, HIGH_LEN = 0xFF01, 0x5093, 0x00FE  # BootCopyHigh: $5093 -> $FF01
BLOCK4, BLOCK4_END = 0x6B5C, 0xFDFD


def parts():
    bl = image.blocks()
    mem, _ = image.image()
    resident = bytearray(0x10000)
    resident[BLOCK4:BLOCK4_END] = mem[BLOCK4:BLOCK4_END]
    resident[LOW:LOW + LOW_LEN] = mem[LOW_FROM:LOW_FROM + LOW_LEN]
    resident[HIGH:HIGH + HIGH_LEN] = mem[HIGH_FROM:HIGH_FROM + HIGH_LEN]
    return {
        'basic-5ccb.bin': bl[2][1:-1],
        'stage2-609c.bin': bl[3][1:-1],
        'boot-4000.bin': bl[5][1:-1][:BOOT_END - BOOT],
        'bank4-c000.bin': bl[6][1:-1],
    }, bytes(resident)


def main():
    out = os.path.join(CASE, 'work', 'parts')
    os.makedirs(out, exist_ok=True)
    files, resident = parts()
    for name, data in files.items():
        open(os.path.join(out, name), 'wb').write(data)
        print(name, len(data))
    os.makedirs(os.path.join(CASE, 'work', 'mkgame'), exist_ok=True)
    open(os.path.join(CASE, 'work', 'mkgame', 'resident.bin'), 'wb').write(resident)
    print('resident.bin', len(resident))


if __name__ == '__main__':
    main()
