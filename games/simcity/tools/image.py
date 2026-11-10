#!/usr/bin/env python3
"""The 64 K image at the game's entry `$5B1B`, cut from orig/SimCity.tzx.zip as the loader leaves it.

The loader (`$FE00`, its tail decrypted with R) loads three encrypted headerless blocks: the screen to `$4000`,
code1 (37633 bytes) to `$6B00-$FE00`, code2 (4128 bytes) to `$4000-$501F` after clearing the attributes; code2's
`$5000` moves `$4000-$4FFF` to `$5B00-$6AFF` and jumps to `$5B1B`. The ROM area `$0000-$3FFF` is left zero.

    python3 tools/image.py OUT.bin [--orig orig/SimCity.tzx.zip]
    python3 tools/image.py --part NAME OUT.bin [--orig ...]   # one tape part's plain bytes (PARTS below)

The parts are the plain bytes of the tape's other sources, as the kit's part files (src/*/NAME.json) read them:
basic (block 2, 144 bytes at PROG `$5CCB`), loader (block 4 with its tail decrypted, 512 bytes at `$FE00`), screen
(block 5 decrypted, 6912 bytes at `$4000`) and mover (block 7 decrypted, its last 32 bytes, at `$5000`).
"""
import io
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import decrypt_tape  # noqa: E402
import tzxblocks  # noqa: E402


def blocks(orig):
    z = zipfile.ZipFile(orig)
    tzx = z.read([n for n in z.namelist() if n.lower().endswith('.tzx')][0])
    return [b['data'] for b in tzxblocks.parse(tzx) if 'data' in b]


def image(orig):
    b = blocks(orig)
    mem = bytearray(65536)
    mem[0xFE00:0x10000] = decrypt_tape.loader_r(b[3][1:-1])
    mem[0x4000:0x5B00] = decrypt_tape.decrypt(b[4])          # the loading screen
    code1 = decrypt_tape.decrypt(b[5])
    mem[0x6B00:0x6B00 + len(code1)] = code1                    # to $FE00 inclusive: over the loader's DI
    mem[0x5800:0x5B00] = bytes(0x300)                          # LDIR at $FEA4: attributes cleared
    code2 = decrypt_tape.decrypt(b[6])
    mem[0x4000:0x4000 + len(code2)] = code2
    mem[0x5B00:0x6B00] = mem[0x4000:0x5000]                    # $5000: LDIR $4000 -> $5B00, $1000 bytes
    mem[0xFF32] = 3 * len(code2) & 0xFF                        # the loader's byte key after the last block
    return bytes(mem)


def part(name, orig):
    b = blocks(orig)
    if name == 'basic':
        return b[1][1:-1]
    if name == 'loader':
        return decrypt_tape.loader_r(b[3][1:-1])
    if name == 'screen':
        return decrypt_tape.decrypt(b[4])
    if name == 'mover':
        return decrypt_tape.decrypt(b[6])[0x1000:]
    sys.exit('image: no part ' + name)


def main():
    orig = sys.argv[sys.argv.index('--orig') + 1] if '--orig' in sys.argv else 'orig/SimCity.tzx.zip'
    if sys.argv[1] == '--part':
        out = sys.argv[3]
        os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
        open(out, 'wb').write(part(sys.argv[2], orig))
        return
    out = sys.argv[1]
    os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
    open(out, 'wb').write(image(orig))


if __name__ == '__main__':
    main()
