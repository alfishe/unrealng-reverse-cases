#!/usr/bin/env python3
"""The images of the case's parts, for kit/mkgame.py's part files (docs/03-build-and-load.md 3.1):

    python3 tools/parts.py            # writes work/parts/*.bin

| File | What | Org | From |
| --- | --- | --- | --- |
| basic-5ccb.bin | TZX block 2: the BASIC "Rick" (181 bytes) | `$5CCB` (PROG) | the tape |
| rick1-cd00.bin | TZX block 4: Rick1, the first loader stage (512 bytes) | `$CD00` | the tape |
| stage2-5d00.bin | group 1's block 46 deciphered: the second loader stage as the tape holds it (256 bytes) | `$5D00` | the tape, tools/bleepload.py |
| loadgroup-fa00.bin | group 1's blocks 44-45 deciphered: LoadGroup, the loader of groups 2 and 3 (512 bytes) | `$FA00` | the tape, tools/bleepload.py |
| music-c000.bin | the game image's `$5E00-$6BA3`: the AY player and tunes, as the entry copies them to RAM 1 | `$C000` | work/mkgame/original.bin (tools/image.py) |

tools/bleepload.py check proves that the image's `$5E00-$FFFF` is what the tape's groups give, deciphered.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import bleepload  # noqa: E402

MUSIC = (0x5E00, 0x6BA4)   # copied to RAM 1 $C000 by CopyMusicToRam1 $A069 (the length $0DA4)


def parts():
    views = bleepload.plain_views()[0]
    image = open(os.path.join(CASE, 'work', 'mkgame', 'original.bin'), 'rb').read()
    return {
        'basic-5ccb.bin': views['basic'][1],
        'rick1-cd00.bin': views['rick1'][1],
        'stage2-5d00.bin': views['stage2'][1],
        'loadgroup-fa00.bin': views['loadgroup'][1],
        'music-c000.bin': image[MUSIC[0]:MUSIC[1]],
    }


if __name__ == '__main__':
    out = os.path.join(CASE, 'work', 'parts')
    os.makedirs(out, exist_ok=True)
    for name, data in parts().items():
        open(os.path.join(out, name), 'wb').write(data)
        print(f'work/parts/{name}: {len(data)} bytes')
