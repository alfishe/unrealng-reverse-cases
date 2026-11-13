#!/usr/bin/env python3
"""Firebird's Bleepload as Rick Dangerous uses it: the block formats and the two ciphers, both ways
(docs/03-build-and-load.md 3.1).

    python3 tools/bleepload.py check        # decipher orig/'s TZX block by block, prove every rule below on it
    python3 tools/bleepload.py plain DIR    # write the plain views the parts and resources are cut from

**The blocks.** Every turbo block loads at `$FE00`, flag `$FF`, then:

| Offset | Address | Group 1 (marker `$64`, Rick1 `$CD00` loads it) | Groups 2, 3 (markers `$34`, `$35`, LoadGroup `$FA00`) |
| --- | --- | --- | --- |
| 0 | `$FE00` | the marker | the marker |
| 1-256 | `$FE01-$FF00` | the payload | the payload, each byte XOR the high byte of its address |
| 257 | `$FF01` | the block's number in its group | the same |
| 258-259 | `$FF02-$FF03` | where the payload goes | the same |
| 260 | `$FF04` | N, 1-8: the filler's length | 0 (no code reads it) |
| 261 | `$FF05` | N filler bytes (never run), then `JP $CD1B` (the next block; the second stage: `JP $5D00`) | the high byte after the group's last page |
| | | | `$FF06-$FF07`: where to go after the last block (0: return) |
| last | | the XOR of every byte from the marker on (CheckBlock `$CE2A`); its bits 0-2 + 1 are the next block's N | `$FF08`: XOR of `$FE01-$FF07` (LoadGroup's CheckBlock `$FB32`) |

A group 1 block is `$109` + N bytes: the loader reads the next block's length from this block's checksum, so N is
not free: N = (the previous checksum AND 7) + 1, and 8 for the first block (Rick1 sets it). The filler's bytes
are free; the tape's are kept in src/tape/tape.txt.

The TZX block adds the flag `$FF` before and the XOR of flag and bytes after (ROM style), which no loader checks.

**The key.** Group 1's first block ($C900) is a key page as the tape holds it. The second stage ($5D00, group 1's
block 46) XORs it with the two pages of Rick1 ($CD00 and $CE00), so the key is tied to the first stage's code: a
changed byte of Rick1 spoils everything after. key[i] = tape[$C900 + i] XOR Rick1[$CD00 + i] XOR Rick1[$CE00 + i].

**Group 1's ciphers.** Rick1 stores every payload as it comes. Then the second stage deciphers:
- its own bytes `$5D40-$5DFF`: byte XOR key[i - $40] (i = address - $5D00);
- `$CF00-$FBFF` (the pointers at `$FEE9` and `$FEEC` of the group's last block): byte XOR key[address & $FF].
  `$CF00-$E9FF` is the loading screen (copied to `$4000`), `$EA00-$F9FF` the bytes the game finds at `$5E00`
  (copied there), `$FA00-$FBFF` LoadGroup, the loader of groups 2 and 3.
The other blocks (`$C900` itself, the group's last block) are plain.
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
TZX_NAME = 'Rick Dangerous.tzx'
FLAG = 0xFF
MARKERS = {1: 0x64, 2: 0x34, 3: 0x35}
KEYED = (0xCF00, 0xFC00)          # the range the second stage XORs with the key (the last block's $FEE9, $FEEC)
STAGE2, STAGE2_KEYED = 0x5D00, 0x40  # the second stage, enciphered from its byte $40 on


def xor_all(data):
    x = 0
    for b in data:
        x ^= b
    return x


def key(tape_page, rick1):
    """the key the second stage makes: the tape's key page XOR Rick1's two pages"""
    return bytes(tape_page[i] ^ rick1[i] ^ rick1[256 + i] for i in range(256))


def tape_page(key_bytes, rick1):
    """the inverse: the key page the tape must hold for this key and this Rick1"""
    return key(key_bytes, rick1)


def group1_cipher(page, dest, k):
    """a group 1 payload: plain <-> tape (an XOR, so one function both ways)"""
    if KEYED[0] <= dest < KEYED[1]:
        return bytes(b ^ k[(dest + i) & 0xFF] for i, b in enumerate(page))
    if dest == STAGE2:
        return bytes(b ^ (k[i - STAGE2_KEYED] if i >= STAGE2_KEYED else 0) for i, b in enumerate(page))
    return bytes(page)


def group23_cipher(page, dest):
    """a group 2 or 3 payload: each byte XOR the high byte of its address (LoadGroup's StorePage $FA6C)"""
    return bytes(b ^ (dest >> 8) for b in page)


def group1_block(number, dest, payload, filler, jump):
    """the block LoadBlock `$CD6E` reads: marker, payload, number, dest, N, the N filler bytes, JP jump, the XOR of all
    of them (whose bits 0-2 + 1 are the next block's N)"""
    body = bytes([MARKERS[1]]) + payload + bytes([number, dest & 0xFF, dest >> 8, len(filler)]) + filler + \
        bytes([0xC3, jump & 0xFF, jump >> 8])
    return body + bytes([xor_all(body)])


def next_filler(block):
    """N of the block after this one: its checksum's bits 0-2, plus 1"""
    return (block[-1] & 7) + 1


def group23_block(group, number, dest, payload, end, go):
    """the block LoadGroup's LoadBlock `$FA85` reads: marker, payload, number, dest, 0, the end page, where to go"""
    head = payload + bytes([number, dest & 0xFF, dest >> 8, 0, end, go & 0xFF, go >> 8])
    return bytes([MARKERS[group]]) + head + bytes([xor_all(head)])


def turbo_data(block):
    """the TZX block's data: the flag, the block, the ROM-style XOR of both"""
    body = bytes([FLAG]) + block
    return body + bytes([xor_all(body)])


def original_tzx():
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'RickDangerous.tzx.zip')) as z:
        return z.read(TZX_NAME)


def tape_blocks():
    """(the standard blocks' data, the turbo blocks' data) of the original, in order"""
    sys.path.insert(0, HERE)
    import tzxblocks
    blocks = list(tzxblocks.parse(original_tzx()))
    return [b['data'] for b in blocks if b['id'] == 0x10], [b['data'] for b in blocks if b['id'] == 0x11]


def plain_views():
    """deciphered from the tape alone: {name: (address, bytes)} and the facts check() proves"""
    std, turbo = tape_blocks()
    rick1 = std[3][1:-1]
    blocks = [t[1:-1] for t in turbo]
    g1 = [b for b in blocks if b[0] == MARKERS[1]]
    k = key(g1[0][1:257], rick1)
    mem = {}
    for b in g1:
        dest = b[0x102] | b[0x103] << 8
        mem[dest] = group1_cipher(b[1:257], dest, k)
    last = g1[-1]
    page = lambda lo, hi: b''.join(mem[a] for a in range(lo, hi, 0x100))
    g2 = b''.join(group23_cipher(b[1:257], b[0x102] | b[0x103] << 8) for b in blocks if b[0] == MARKERS[2])
    g3 = b''.join(group23_cipher(b[1:257], b[0x102] | b[0x103] << 8) for b in blocks if b[0] == MARKERS[3])
    return {
        'basic': (0x5CCB, std[1][1:-1]),
        'rick1': (0xCD00, rick1),
        'keypage': (0xC900, g1[0][1:257]),
        'key': (0xC900, k),
        'stage2': (STAGE2, mem[STAGE2]),
        'screen': (0x4000, page(0xCF00, 0xEA00)),
        'low': (0x5E00, page(0xEA00, 0xFA00)),
        'loadgroup': (0xFA00, page(0xFA00, 0xFC00)),
        'lastblock': (0xFE00, last),
        'group2': (0x6E00, g2),
        'group3': (0xFA00, g3),
    }, g1, blocks


def check():
    views, g1, blocks = plain_views()
    std, turbo = tape_blocks()
    bad = 0
    last = g1[-1]
    ptr = lambda o: last[o] | last[o + 1] << 8
    print(f'the last group 1 block: key page ${ptr(0xE7):04X}, keyed from ${ptr(0xE9):04X} to ${last[0xEC]:02X}00')
    bad += (ptr(0xE7), ptr(0xE9), last[0xEC] << 8) != (0xC900, KEYED[0], KEYED[1])
    # every block rebuilt from its plain payload and its fields
    k = views['key'][1]
    extra = 8
    for i, (raw, b) in enumerate(zip(turbo, blocks)):
        dest = b[0x102] | b[0x103] << 8
        if b[0] == MARKERS[1]:
            if len(b) != 0x109 + extra:
                print(f'block {i}: {len(b)} bytes, the previous tail said {0x109 + extra}')
                bad += 1
            n = b[0x104]
            extra = next_filler(b)
            plain = group1_cipher(b[1:257], dest, k)
            again = group1_block(b[0x101], dest, group1_cipher(plain, dest, k), b[0x105:0x105 + n],
                                 b[0x106 + n] | b[0x107 + n] << 8)
        else:
            group = 2 if b[0] == MARKERS[2] else 3
            plain = group23_cipher(b[1:257], dest)
            again = group23_block(group, b[0x101], dest, group23_cipher(plain, dest), b[0x105],
                                  b[0x106] | b[0x107] << 8)
            bad += b[0x104] != 0
        if turbo_data(again) != raw:
            print(f'block {i} (${dest:04X}): not rebuilt')
            bad += 1
    rick1 = views['rick1'][1]
    bad += tape_page(k, rick1) != views['keypage'][1]
    # against the game image at the entry (tools/image.py: SkoolKit's simulated load)
    img = os.path.join(CASE, 'work', 'mkgame', 'original.bin')
    if os.path.exists(img):
        image = open(img, 'rb').read()
        for name in ('low', 'group2', 'group3'):
            at, data = views[name]
            same = image[at:at + len(data)] == data
            print(f'{name}: ${at:04X}-${at + len(data) - 1:04X} {"=" if same else "differs from"} the image')
            bad += not same
        s2 = views['stage2'][1]
        diff = [STAGE2 + i for i in range(256) if s2[i] != image[STAGE2 + i]]
        print(f'stage2: differs from the image at {len(diff)} bytes '
              f'${diff[0]:04X}-${diff[-1]:04X} (the stack at the entry; the tape has 0 there)' if diff else 'stage2: =')
        bad += any(s2[a - STAGE2] for a in diff)
    print(f'{len(turbo)} turbo blocks rebuilt from their plain payloads; {bad} bad')
    return bad


def main():
    if len(sys.argv) == 2 and sys.argv[1] == 'check':
        return 1 if check() else 0
    if len(sys.argv) == 3 and sys.argv[1] == 'plain':
        views = plain_views()[0]
        os.makedirs(sys.argv[2], exist_ok=True)
        for name, (at, data) in views.items():
            path = os.path.join(sys.argv[2], f'{name}-{at:04x}.bin')
            open(path, 'wb').write(data)
            print(f'{path}: {len(data)} bytes at ${at:04X}')
        return 0
    sys.exit(__doc__)


if __name__ == '__main__':
    sys.exit(main())
