#!/usr/bin/env python3
"""The images of the case's parts, cut from orig/Terramex.tzx.zip alone, for kit/mkgame.py's part files
(docs/03-build-and-load.md 3.1):

    python3 tools/parts.py            # writes work/parts/*.bin

| File | What | Org |
| --- | --- | --- |
| basic-5ccb.bin | TZX block 2: the BASIC line 0 and the loader in its variables area (302 bytes) | `$5CCB` (PROG) |
| screen-4000.bin | TZX block 3: the loading screen (6912 bytes) | `$4000` |
| music-c000.bin | block 4 `$6000-$71FF`: the AY music player and its tunes, as the 128K setup copies them to RAM 6 | `$C000` |
| select-c000.bin | block 4 `$7200-$9CF7`: the 128K setup and the explorer selector, relocated to `$C000` as the setup's own relocation pass leaves them in RAM 1 (`reloc()`, below) | `$C000` |
| sets-9cf8.bin | block 4 `$9CF8-$F6F7`: the five explorer data sets, `$1200` bytes each | `$9CF8` |

The selector is relocatable: the tape holds its 16-bit addresses as offsets from its first byte, and a table of the
offsets of those words ends the code (its offset is the word at +3; the table ends with a zero word). The setup at
`$7200` adds the run address to each listed word (RelocateSelector in src/select). reloc(data, base) does the same;
reloc(data, -base) is its inverse, which tools/mktape.py applies to the assembled selector to give the tape's bytes.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import image  # noqa: E402

SELECT_LO, SETS_LO, BLOCK4 = 0x7200, 0x9CF8, 0x6000


def reloc_table(data):
    """the offsets of the relocatable words: the table at the word at +3, up to its zero word"""
    at, out = data[3] | data[4] << 8, []
    while True:
        w = data[at] | data[at + 1] << 8
        if not w:
            return out
        out.append(w)
        at += 2


def reloc(data, base):
    """data with base added to every word its relocation table lists (mod 64 K)"""
    out = bytearray(data)
    for o in reloc_table(data):
        w = (out[o] | out[o + 1] << 8) + base & 0xFFFF
        out[o], out[o + 1] = w & 0xFF, w >> 8
    return bytes(out)


def parts():
    hdr, basic, screen, block4, game = image.blocks()
    return {
        'basic-5ccb.bin': basic,
        'screen-4000.bin': screen,
        'music-c000.bin': block4[:SELECT_LO - BLOCK4],
        'select-c000.bin': reloc(block4[SELECT_LO - BLOCK4:SETS_LO - BLOCK4], 0xC000),
        'sets-9cf8.bin': block4[SETS_LO - BLOCK4:],
    }


if __name__ == '__main__':
    out = os.path.join(CASE, 'work', 'parts')
    os.makedirs(out, exist_ok=True)
    for name, data in parts().items():
        open(os.path.join(out, name), 'wb').write(data)
        print(f'work/parts/{name}: {len(data)} bytes')
