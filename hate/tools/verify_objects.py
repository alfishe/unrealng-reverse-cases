#!/usr/bin/env python3
"""The round objects of src/res against the recording (docs/07-objects.md 7.1): for each round start of the bot's
game, the frame near it where the 16 course object records `$C0B0` + 16 k hold the round's block, 8 bytes each.

    python3 tools/verify_objects.py [--unreal UNREAL_NG_CHECKOUT]

Needs an unreal-ng instance with work/p2 open (re_session.py open).
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
unreal = os.environ.get('UNREAL_NG', '')
if '--unreal' in sys.argv:
    unreal = sys.argv[sys.argv.index('--unreal') + 1]
sys.path.insert(0, os.path.join(unreal, 'tools', 'verification', 'analysis'))
import re_session  # noqa: E402
s, _ = re_session.session_of('work/p2')
def rd(f, off, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0, 'offset': off, 'length': n}, ok=False)
    return bytes.fromhex(r.structured['hex'])
for rnd, start in ((1, 210), (2, 3480), (3, 7671), (4, 10635)):  # the round starts of doc 10.1
    blk = open(f'src/res/course/objects-round-{rnd:02d}.bin', 'rb').read()
    best = None
    for f in range(start - 40, start + 40):
        m = rd(f, 0xC0B0, 0x100)
        heads = sum(m[16 * k:16 * k + 8] == blk[8 * k:8 * k + 8] for k in range(16))
        if best is None or heads > best[1]:
            best = (f, heads)
        if heads == 16:
            break
    print(f'round {rnd}: frame {best[0]}: {best[1]}/16 records equal the file in +0-+7')
