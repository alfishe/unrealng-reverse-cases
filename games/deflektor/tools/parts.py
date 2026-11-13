#!/usr/bin/env python3
"""The images of Deflektor's parts, cut from orig/Deflektor.tzx.zip alone, for kit/mkgame.py (the part files) and
tools/res_formats.py (the loader's resources):

    python3 tools/parts.py            # writes work/parts/*.bin

| File | What | Org |
| --- | --- | --- |
| basic-5ccb.bin | TZX block 1: the BASIC line 0, its code at `$5D05` and the first loader stage it copies to `$B626` (384 bytes) | `$5CCB` (PROG) |
| stage2-b75a.bin | the turbo block's first three loads: the loader's second stage `$B75A-$BBDE` (1157 bytes) | `$B75A` |
| glyphs-b326.bin | the fourth load: 59 characters over the ROM font's copy, for the loading screen's text (472 bytes) | `$B326` |
| script-998e.bin | the fifth load: the loading screen's script, printed while the game loads (6552 bytes) | `$998E` |
| head-5c00.bin | the main block's code that is not the game, as it stands when the chain has run (tools/cipher.py): BlockHead `$5C00-$5C26`, the chain `$7B52-$7CFF`, the mover `$FD00-$FD1A` (496 bytes) | `$5C00` |
| loaded-5c00.bin | the main block as loaded, `$5C00-$DDEF` (the last three loads; `$9DF0-$DDEF` is the load at `$C000` the end moves down) | `$5C00` |

The loader's code decodes the turbo block in SkoolKit's simulator (tools/tapesim.py) and runs on through the chain to
the mover, so every image is what the tape's own code makes.
"""
import io
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import tapesim  # noqa: E402  (re-runs this tool under the SkoolKit venv when needed)
import tzxblocks  # noqa: E402


def orig_tzx():
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'Deflektor.tzx.zip')) as z:
        name = [n for n in z.namelist() if n.lower().endswith('.tzx')][0]
        return z.read(name)


def parts():
    blocks = list(tzxblocks.parse(orig_tzx()))
    basic = bytes(blocks[1]['data'][1:-1])
    turbo = blocks[2]
    mem, sim, loads, _pairs = tapesim.decode(basic, tapesim.bits_of(turbo['data'], turbo['timing']['last']))
    got = dict(loads)
    loaded = mem[0x5C00:0x9DF0] + mem[0xC000:0x10000]
    head = bytes(mem[0x5C00:0x5C27])
    tapesim.run_to(mem, sim, 0xFD00)
    head += bytes(mem[0x7B52:0x7D00]) + bytes(mem[0xFD00:0xFD1B])
    return {
        'basic-5ccb.bin': basic,
        'stage2-b75a.bin': got[0xB75A] + got[0xB869] + got[0xB8DD],
        'glyphs-b326.bin': got[0xB326],
        'script-998e.bin': got[0x998E],
        'head-5c00.bin': head,
        'loaded-5c00.bin': bytes(loaded),
    }


def main():
    out = os.path.join(CASE, 'work', 'parts')
    os.makedirs(out, exist_ok=True)
    for name, data in parts().items():
        open(os.path.join(out, name), 'wb').write(data)
        print(name, len(data))


if __name__ == '__main__':
    main()
