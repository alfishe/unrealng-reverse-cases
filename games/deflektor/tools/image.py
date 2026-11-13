#!/usr/bin/env python3
"""The 64 K image of the game at its entry `$8382`, computed from orig/Deflektor.tzx.zip alone: the BASIC's code and
the turbo loader decode the tape in SkoolKit's simulator (tools/tapesim.py), the decryption chain `$7B52` and the
mover `$FD00` run on to `$8382` (docs/03-build-and-load.md, 3.1).

    python3 tools/image.py work/mkgame/original.bin

Stage 1 took the same image from the `c1` recording (work/stage1/images/entry.cpu.bin, the 10 Mega Games copy at
ROM timing): the two are identical over `$4000-$FFFF`, which the script checks when that file is there.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import tapesim  # noqa: E402  (re-runs this tool under the SkoolKit venv when needed)
import tzxblocks  # noqa: E402
from parts import orig_tzx  # noqa: E402


def entry_image():
    blocks = list(tzxblocks.parse(orig_tzx()))
    turbo = blocks[2]
    mem, sim, _loads, _pairs = tapesim.decode(bytes(blocks[1]['data'][1:-1]),
                                              tapesim.bits_of(turbo['data'], turbo['timing']['last']))
    tapesim.run_to(mem, sim, 0x8382)
    return bytes(mem)


if __name__ == '__main__':
    data = entry_image()
    assert data[0xFD18:0xFD1B] == bytes([0xC3, 0x82, 0x83])
    ref = os.path.join(CASE, 'work', 'stage1', 'images', 'entry.cpu.bin')
    if os.path.exists(ref) and open(ref, 'rb').read()[0x4000:] != data[0x4000:]:
        sys.exit('image: differs from the c1 recording\'s entry image over $4000-$FFFF')
    os.makedirs(os.path.dirname(os.path.abspath(sys.argv[1])), exist_ok=True)
    open(sys.argv[1], 'wb').write(data)
