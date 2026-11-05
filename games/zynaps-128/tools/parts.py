#!/usr/bin/env python3
"""The pristine code images of Zynaps 2 in 1, cut from the original medium (no recording): each part as the address
it runs at, the input of tools/part_mkasm.py and the compare target of the build.

    python3 tools/parts.py [--out work/parts]

From orig/Zynaps(2In1)(km).trd.zip (the TRD inside it: ZYNAPS.B and boot.B; ZYNAPS.B is the same in the SCL):

    zynaps-b-sector0.bin   ZYNAPS.B sector 0: the BASIC (168 bytes from PROG = $5D3B), the autostart, leftovers
    loader-5d3b.bin        the BASIC program (168 bytes: line 0 REM with the loader at $5D40, line 1) and the autostart
    depacker-5b00.bin      sector 1: the Hrust 1 depacker (256 bytes, at $5B00)
    blk1-packed.bin, blk2-packed.bin   the two HR blocks (header + stream)
    blk1-trailer.bin, blk2-trailer.bin the rest of each block's sectors (the packer's tail)
    intro-6000.bin         block 1 unpacked ($6000-$E8D4)
    intro-code-6000.bin    its code $6000-$632C
    engine-c968.bin        the page-4 sound engine (block 1 $632D, $3BB bytes; runs at $C968)
    engine-data-de48.bin   its music and effect data (block 1 $66E8, $2028 bytes; at $DE48)
    starkos-8000.bin       the STarKos player and the SK10 song (block 1 $D810, $10C5 bytes; at $8000)
    game-6000.bin          block 2 unpacked ($6000-$FB84)
    setup-6000.bin         its code $6000-$610D (the relocator and the patcher)
    stubs-b30d.bin         $610E-$61A9: the sound stubs (run at $B30D)
    glue-5b00.bin          $61B6-$6298: the 128K glue (runs at $5B00)
    mouse-fe00.bin         $6299-$6375: the Kempston mouse driver (runs at $FE00)
    game-6800.bin          $6385-$FB84: the 48K game as it runs at $6800-$FFFF (before the patches)
    boot-5d3b.bin          boot.B: the BASIC (988 bytes from PROG = $5D3B)
    boot-sectors.bin       boot.B's 4 sectors (the BASIC, the autostart and the rest)
"""
import argparse
import io
import os
import struct
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import disk  # noqa: E402
import hrust1  # noqa: E402

TRD_ZIP = os.path.join(CASE, 'orig', 'Zynaps(2In1)(km).trd.zip')


def medium():
    z = zipfile.ZipFile(TRD_ZIP)
    name = next(n for n in z.namelist() if n.lower().endswith('.trd'))
    files, _ = disk.read_trd(z.read(name))
    return {f['name'].rstrip() + '.' + f['type']: f for f in files}


def cut():
    f = medium()
    zb, boot = f['ZYNAPS.B']['body'], f['boot.B']
    blk1 = zb[512:512 + 56 * 256]
    blk2 = zb[512 + 56 * 256:]
    p1 = struct.unpack('<H', blk1[4:6])[0]
    p2 = struct.unpack('<H', blk2[4:6])[0]
    intro, _ = hrust1.unpack(blk1)
    game, _ = hrust1.unpack(blk2)

    def at(img, base, lo, hi):
        return img[lo - base:hi - base]
    return {
        'zynaps-b-sector0.bin': zb[:256],
        'loader-5d3b.bin': zb[:f['ZYNAPS.B']['length'] + 4],
        'depacker-5b00.bin': zb[256:512],
        'blk1-packed.bin': blk1[:p1], 'blk1-trailer.bin': blk1[p1:],
        'blk2-packed.bin': blk2[:p2], 'blk2-trailer.bin': blk2[p2:],
        'intro-6000.bin': intro,
        'intro-code-6000.bin': at(intro, 0x6000, 0x6000, 0x632D),
        'engine-c968.bin': at(intro, 0x6000, 0x632D, 0x66E8),
        'engine-data-de48.bin': at(intro, 0x6000, 0x66E8, 0x8710),
        'starkos-8000.bin': at(intro, 0x6000, 0xD810, 0xD810 + 0x10C5),
        'game-6000.bin': game,
        'setup-6000.bin': at(game, 0x6000, 0x6000, 0x610E),
        'stubs-b30d.bin': at(game, 0x6000, 0x610E, 0x61AA),
        'glue-5b00.bin': at(game, 0x6000, 0x61B6, 0x6299),
        'mouse-fe00.bin': at(game, 0x6000, 0x6299, 0x6376),
        'game-6800.bin': at(game, 0x6000, 0x6385, 0xFB85),
        'boot-5d3b.bin': boot['body'][:boot['length']],
        'boot-sectors.bin': boot['body'],
    }


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', default=os.path.join(CASE, 'work', 'parts'))
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for name, data in cut().items():
        open(os.path.join(a.out, name), 'wb').write(data)
        print(f'{name:24} {len(data):6} bytes')


if __name__ == '__main__':
    sys.exit(main())
