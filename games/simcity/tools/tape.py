#!/usr/bin/env python3
"""The tape's mastering transforms for the build, and the original's data blocks as TAP (tools/build.sh).

    python3 tools/tape.py loader PLAIN.bin OUT.bin        # the loader as on tape: $FE80-$FFFF XORed with R's keys
    python3 tools/tape.py blocks OUT.tap SCREEN GAME MOVER # append blocks 5-7: flag $00, encrypted for LoadBlock
    python3 tools/tape.py --orig OUT.tap                  # TZX blocks 1-7 of orig/SimCity.tzx.zip, each as a TAP block

The loader's tail: the byte at `$FE80 + k` is stored XOR `(2 + 8 k) AND $7F`, the value LoaderStart's LD A,R reads
for it (src/loader). Blocks 5-7: each byte of a block of n bytes is stored on tape as `byte XOR key XOR E`, key =
3 (i + 1) AND $FF for byte i, E = (n - i) AND $FF, the inverse of LoadBlock's store; flag `$00`, then the XOR
checksum of flag and data, as LD-BYTES checks it. Block 5 is the loading screen (6912 bytes at `$4000`), block 6
code1 (`$6B00-$FE00` of the game, 37 633 bytes), block 7 code2 (`$5B00-$6AFF`, 4096 bytes, as it loads at `$4000`)
and the mover's 32 bytes. The TZX's archive info, pulse timings and pauses are not data and are not rebuilt
(docs/03-build-and-load.md 3.1).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import decrypt_tape  # noqa: E402

GAME_ORG = 0x5B00
CODE1 = 0x6B00


def tap_block(raw):
    return len(raw).to_bytes(2, 'little') + raw


def blocks(out, screen, game, mover):
    g = open(game, 'rb').read()
    code1 = g[CODE1 - GAME_ORG:]
    code2 = g[:CODE1 - GAME_ORG] + open(mover, 'rb').read()
    data = bytearray()
    for part in (open(screen, 'rb').read(), code1, code2):
        data += tap_block(decrypt_tape.encrypt(part, 0))
    open(out, 'ab').write(data)


def orig(out):
    import image
    data = bytearray()
    for b in image.blocks(os.path.join(HERE, '..', 'orig', 'SimCity.tzx.zip')):
        data += tap_block(b)
    open(out, 'wb').write(data)


def main():
    a = sys.argv[1:]
    if a[:1] == ['--orig'] and len(a) == 2:
        orig(a[1])
    elif a[:1] == ['loader'] and len(a) == 3:
        open(a[2], 'wb').write(decrypt_tape.loader_r(open(a[1], 'rb').read()))
    elif a[:1] == ['blocks'] and len(a) == 5:
        blocks(*a[1:])
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
