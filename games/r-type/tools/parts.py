#!/usr/bin/env python3
"""Cut the original tape into the images the part files and case.json read (work/parts/), and the loading screen
into src/res/screens/loading.scr (docs/03-build-and-load.md 3.1).

    python3 tools/parts.py            # under SkoolKit's interpreter (tools/speedlock7.py runs the chain in its simulator)

    basic-5ccb.bin       tape block 2, the BASIC "R-TYPE" at PROG $5CCB (4933 bytes)
    chain-ec00.bin       the decryption chain and the SpeedLock reader $EC00-$FEE7, the plain view (speedlock7.py)
    chain-trace.json     the chain's instructions $EC00-$FB7D as the simulator ran them (a part file's trace l1)
    stage2-fee8.bin      block 7: the reader's second stage $FEE8-$FFCF (232 bytes)
    table2-ff49.bin      block 23: the reader's second table over $FF49 (55 bytes)
    decipher-fe40.bin    block 29: Decipher and its padding at $FE40 (115 bytes)
    stage2end-fefc.bin   block 31: the second stage's new end at $FEFC (49 bytes)
    tail-61a8.bin        blocks 33 and 35: the tail at $61A8 (33 + 14 bytes)
    levelN-c4ae.bin      the body of level N as LoadLevel puts it at $C4AE (N = 1-8)

The game's image (case.json) is the 64 K at the entry, work/stage1/images/entry.cpu.bin.
"""
import json
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import mktape      # noqa: E402
import speedlock7  # noqa: E402
import tzxblocks   # noqa: E402

SL = [(7, 0xFEE8, True, 'stage2-fee8.bin'), (13, 0x4000, False, None), (15, 0x8000, False, None),
      (17, 0x9710, False, None), (19, 0xFD7F, False, None), (21, 0xFDB3, False, None),
      (23, 0xFF49, False, 'table2-ff49.bin'), (25, 0x7000, False, None), (27, 0xC544, False, None),
      (29, 0xFE40, False, 'decipher-fe40.bin'), (31, 0xFEFC, False, 'stage2end-fefc.bin'),
      (33, 0x61A8, False, 'tail'), (35, 0x61C9, True, 'tail')]


def main():
    out = os.path.join(ROOT, 'work', 'parts')
    os.makedirs(out, exist_ok=True)
    tzx = zipfile.ZipFile(os.path.join(ROOT, 'orig', 'R-Type.tzx.zip')).read('R-Type.tzx')
    blocks = list(tzxblocks.parse(tzx))
    basic = blocks[2]['data'][1:-1]
    open(os.path.join(out, 'basic-5ccb.bin'), 'wb').write(basic)
    chain, layers, lost = speedlock7.plain(speedlock7.chain_of(basic))
    assert not lost
    open(os.path.join(out, 'chain-ec00.bin'), 'wb').write(chain)
    starts = {('%04X' % k): v for k, v in sorted(speedlock7.run.starts.items()) if speedlock7.LO <= k < speedlock7.LOADER}
    json.dump({'starts': starts, 'entries': ['%04X' % speedlock7.LO] + ['%04X' % l[3] for l in layers if l[3:]],
               'reads': {}}, open(os.path.join(out, 'chain-trace.json'), 'w'), indent=0)
    keys = mktape.Keys(chain)
    plain = {}
    tail = b''
    for i, dest, check, name in SL:
        p = mktape.decode(keys, dest, blocks[i]['data'], check)
        plain[i] = p
        if name == 'tail':
            tail += p
        elif name:
            open(os.path.join(out, name), 'wb').write(p)
    open(os.path.join(out, 'tail-61a8.bin'), 'wb').write(tail)
    scr = os.path.join(ROOT, 'src', 'res', 'screens', 'loading.scr')
    os.makedirs(os.path.dirname(scr), exist_ok=True)
    open(scr, 'wb').write(plain[13] + plain[15])
    for n in range(8):
        body = blocks[40 + 4 * n]['data'][1:-1]
        open(os.path.join(out, 'level%d-c4ae.bin' % (n + 1)), 'wb').write(body)
    print('parts: %d chain rewrite loops; images in %s' % (len(layers), out))
    return 0


if __name__ == '__main__':
    sys.exit(main())
