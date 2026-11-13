#!/usr/bin/env python3
"""The Myth images cut from the original tape (`Myth - History In The Making.tzx` in
orig/Myth-HistoryInTheMaking.tzx.zip, ZXDB download 20803). The main block and the five stage blocks are plain on
the tape (turbo data, flag `$56`) and each loads at `$6C3F` (proved against the RZX run's snapshots and c1's L1,
docs/03-build-and-load.md 3.1):

| TZX block | Bytes | Where | What |
| --- | ---: | --- | --- |
| 37 | 15 360 | `$6C3F-$A83E` | the main block (logo, credits, menu) |
| 40, 43, 46, 49, 52 | 33 792 each | `$6C3F-$F03E` | stages 1-5 |

Writes OUT/front.bin and OUT/stage1.bin ... OUT/stage5.bin: the 64 K Z80 view with the block at `$6C3F` and zeros
elsewhere. The resident part `$F03F-$FFFF` comes out of the Speedlock 7 blocks (enciphered) and is not cut here yet.

    python3 tools/image.py OUT_DIR
"""
import io
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ORIG = os.path.join(HERE, '..', 'orig', 'Myth-HistoryInTheMaking.tzx.zip')
BLOCKS = {'front': 37, 'stage1': 40, 'stage2': 43, 'stage3': 46, 'stage4': 49, 'stage5': 52}


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    z = zipfile.ZipFile(ORIG)
    tzx = z.read('Myth - History In The Making.tzx')
    blocks = list(tzxblocks.parse(tzx))
    for name, k in BLOCKS.items():
        data = blocks[k]['data']
        assert data[0] == 0x56, (name, data[0])
        body = data[1:-1]
        mem = bytearray(0x10000)
        mem[0x6C3F:0x6C3F + len(body)] = body
        open(os.path.join(out, f'{name}.bin'), 'wb').write(mem)
        print(f'{name}: TZX block {k}, {len(body)} bytes at $6C3F-${0x6C3F + len(body) - 1:04X}')


if __name__ == '__main__':
    main()
