#!/usr/bin/env python3
"""The block reveals of the RZX Archive run: the frames in which the revealed-zones byte `$6DFF` (BuildZones /
RevealZone) gains a bit while the room `$6BDD` stays the same, to set beside the main loop's stalls
(tools/rzx_stalls.py): each such stall is RedrawCellsMasked `$8855` drawing a newly revealed block.

    python3 tools/rzx_reveals.py work/candidates/rzxarchive/switchblade.rzx --stop 30000 > work/stage2/stalls/reveals.tsv
"""
import argparse
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('--stop', type=int, default=30000)
    a = ap.parse_args()
    orig_next = rzxplay.RZXTracer.next_frame
    last = {}
    print('frame\troom\trevealed_before\trevealed_after')

    def next_frame(self):
        n = self.context.frame_count
        mem = self.simulator.memory
        room, rev = mem[0x6BDD], mem[0x6DFF]
        if last and room == last['room'] and rev != last['rev'] and rev & ~last['rev'] & 0xFF:
            print(f"{n}\t{room}\t${last['rev']:02X}\t${rev:02X}", flush=True)
        last.update(room=room, rev=rev)
        if n >= a.stop:
            raise KeyboardInterrupt
        return orig_next(self)

    rzxplay.RZXTracer.next_frame = next_frame
    try:
        rzxplay.main(['--no-screen', '--quiet', '--fps', '0', a.rzx])
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
