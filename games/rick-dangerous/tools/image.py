#!/usr/bin/env python3
"""The game image as the Bleepload loader leaves it: a 64 K file, `$4000-$FFFF` at the game's entry `$AB4D` (DI,
LD SP,0, CALL `$A043`), RAM 5, 2 and 0 at `$4000`, `$8000`, `$C000` (`$0000-$3FFF` zero; the game is `$5B00-$FFFF`).

    python3 tools/image.py work/mkgame/original.bin [--z80 work/mkgame/entry.z80]

The tape's turbo blocks are enciphered, so the image is not
cut from the TZX: SkoolKit's tap2sna.py simulates the whole load of orig/RickDangerous.tzx.zip on a 128K, the ROM
and the loader's own code running every pulse, and stops when PC reaches `$AB4D`. The result matches unreal-ng's c1
recording at frame 19010, T-state 70580 (ROM speed) except 39 bytes of `$5B89-$5BDD`.
(doc 3, 3.1). Needs SKOOLKIT_VENV (work/env.sh).
"""
import argparse
import os
import subprocess
import sys
import tempfile
import zipfile

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENTRY = 0xAB4D
LO = 0x5B00


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--z80', help='also keep the entry snapshot here')
    a = ap.parse_args()
    venv = os.environ['SKOOLKIT_VENV']
    with tempfile.TemporaryDirectory() as tmp:
        tzx = os.path.join(tmp, 'RickDangerous.tzx')
        with zipfile.ZipFile(os.path.join(CASE, 'orig', 'RickDangerous.tzx.zip')) as z:
            open(tzx, 'wb').write(z.read('Rick Dangerous.tzx'))
        z80 = a.z80 or os.path.join(tmp, 'entry.z80')
        subprocess.run([os.path.join(venv, 'bin', 'tap2sna.py'), '-c', 'machine=128', '--start', hex(ENTRY), tzx, z80],
                       check=True, stdout=subprocess.DEVNULL)
        code = ('import sys\nfrom skoolkit.snapshot import Snapshot\ns = Snapshot.get(sys.argv[1])\n'
                'assert s.pc == %d, hex(s.pc)\nr = bytes(s.ram(-1))\n'
                'v = r[5 * 16384:6 * 16384] + r[2 * 16384:3 * 16384] + r[0:16384]\n'
                'open(sys.argv[2], "wb").write(bytes(16384) + v)\n') % ENTRY
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        subprocess.run([os.path.join(venv, 'bin', 'python3'), '-c', code, z80, a.out], check=True)
    print(f'{a.out}: 64 K, the game ${LO:04X}-$FFFF at the entry ${ENTRY:04X}')


if __name__ == '__main__':
    sys.exit(main())
