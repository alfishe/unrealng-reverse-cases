#!/usr/bin/env python3
"""The Earth Shaker image as the loader leaves it, from the original tape: Side 1 of the Your Sinclair issue 63
covertape (`Your Sinclair (Issue 63) - Side 1.tzx` in orig/YSIssue63-SixPack.tzx.zip), TZX blocks 10-13 (the
game's own four blocks among the side's six programs). The CODE block "EARTH" (37 566 bytes) goes to
`$6D42-$FFFF`, where its header and the BASIC's `LOAD "" CODE` put it; the BASIC program (107 bytes) to PROG
`$5CCB-$5D35`, where the ROM's LOAD puts it. A 64 K file, zeros elsewhere. The game is entered at `$8B20`
(`RANDOMIZE USR 35616`).

    python3 tools/image.py OUT.bin
    python3 tools/image.py --blocks           # the four blocks' TZX indices, lengths and header fields
"""
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ORIG = os.path.join(CASE, 'orig', 'YSIssue63-SixPack.tzx.zip')
SIDE = 'Your Sinclair (Issue 63) - Side 1.tzx'
GAME_AT, GAME_LENGTH, ENTRY, PROG, BASIC_LENGTH = 0x6D42, 37566, 0x8B20, 0x5CCB, 107


def tzx():
    with zipfile.ZipFile(ORIG) as z:
        return z.read(SIDE)


def game_blocks():
    """The four blocks of Earth Shaker: (TZX index, data with flag and checksum), found by the header "EARTH" """
    bl = [(k, b) for k, b in enumerate(tzxblocks.parse(tzx())) if b.get('data')]
    for i, (k, b) in enumerate(bl):
        d = b['data']
        if d[0] == 0 and d[2:12] == b'EARTH     ' and d[1] == 0:
            return [(kk, bb['data']) for kk, bb in bl[i:i + 4]]
    raise SystemExit('no BASIC header "EARTH" on ' + SIDE)


def image():
    (_, hb), (_, basic), (_, hc), (_, code) = game_blocks()
    basic, code = basic[1:-1], code[1:-1]
    assert len(basic) == BASIC_LENGTH and len(code) == GAME_LENGTH
    assert hc[14] | hc[15] << 8 == GAME_AT
    mem = bytearray(0x10000)
    mem[GAME_AT:GAME_AT + GAME_LENGTH] = code
    mem[PROG:PROG + len(basic)] = basic
    return bytes(mem)


if __name__ == '__main__':
    if sys.argv[1:] == ['--blocks']:
        for k, d in game_blocks():
            print(k, len(d), d[:18].hex() if d[0] == 0 else f'flag {d[0]:02X}')
    else:
        open(sys.argv[1], 'wb').write(image())
