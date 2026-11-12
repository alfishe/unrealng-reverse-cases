#!/usr/bin/env python3
"""The Switchblade image as the loader leaves it at the jump into the game (`JP $4000` at `$60A2`), cut from the
original tape (`Switch Blade.tzx` in orig/Switchblade.tzx.zip, ZXDB download 31610). The tape's blocks are plain
(no cipher, no packer on the tape): the ROM loads the BASIC "( Switch )" to PROG `$5CCB`; its machine code copies the
loader to `$FF00-$FFFC` and loads the headerless blocks with it:

| TZX block | Bytes | Where | Who loads it |
| --- | ---: | --- | --- |
| 2 | 361 | `$5CCB` (PROG) | the ROM (header "( Switch )", LINE 0) |
| 3 | 2060 | `$609C-$68A7` | the loader `$FF02`, called from the BASIC's code at `$FFEE` |
| 4 | 37 537 | `$6B5C-$FDFC` | the loader `$FF00`, called from `$612F` |
| 5 | 4497 | `$4000-$5190` | the same |
| 6 | 8441 | bank 4 `$C000-$E0F8` | the same, into `$8000`, swapped with bank 4 (`$616A`, twice), on a 128K only |

Writes OUT/original.bin (the 64 K Z80 view with banks 5, 2, 0 paged, zeros where no block lands: the system
variables, the BASIC's variables and the stack are left out) and OUT/bank4.bin (16 K, the 128K's music and story
bank; on a 48K the block is not loaded).

    python3 tools/image.py OUT_DIR
    python3 tools/image.py --blocks           # the TZX indices, lengths and a hash of every block
"""
import hashlib
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ORIG = os.path.join(CASE, 'orig', 'Switchblade.tzx.zip')
MEMBER = 'Switch Blade.tzx'
PROG, LOADER, LOADER_FROM, LOADER_LEN = 0x5CCB, 0xFF00, 0x5D37, 0xFD
PLACES = {3: 0x609C, 4: 0x6B5C, 5: 0x4000}


def tzx():
    with zipfile.ZipFile(ORIG) as z:
        return z.read(MEMBER)


def blocks():
    return {k: b['data'] for k, b in enumerate(tzxblocks.parse(tzx())) if b.get('data')}


def image():
    bl = blocks()
    mem = bytearray(0x10000)
    basic = bl[2][1:-1]
    mem[PROG:PROG + len(basic)] = basic
    # the BASIC's code (LDIR at $5D32) copies 253 bytes from $5D37 to $FF00
    mem[LOADER:LOADER + LOADER_LEN] = mem[LOADER_FROM:LOADER_FROM + LOADER_LEN]
    for k, at in PLACES.items():
        d = bl[k][1:-1]
        mem[at:at + len(d)] = d
    bank4 = bytearray(0x4000)
    d = bl[6][1:-1]
    bank4[:len(d)] = d
    return bytes(mem), bytes(bank4)


if __name__ == '__main__':
    if sys.argv[1:] == ['--blocks']:
        for k, d in blocks().items():
            print(k, len(d) - 2, f'flag {d[0]:02X}', hashlib.sha1(d[1:-1]).hexdigest())
    else:
        out = sys.argv[1]
        os.makedirs(out, exist_ok=True)
        mem, bank4 = image()
        open(os.path.join(out, 'original.bin'), 'wb').write(mem)
        open(os.path.join(out, 'bank4.bin'), 'wb').write(bank4)
