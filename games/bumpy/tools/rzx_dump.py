#!/usr/bin/env python3
"""Play the RZX archive's bumpy.rzx (xmikex and Jamie Angus, SPIN 0.5, 48K, recorded with rollback) in SkoolKit's
simulator, no emulator instance, and dump what it reached: every EVERY frames the screen (6912 bytes) and every
RAMEVERY frames the whole RAM `$4000-$FFFF`, and a Z80 snapshot at each frame of --snap (the warp points for our own
recordings).

    python3 tools/rzx_dump.py work/candidates/zxdb-extra/bumpy.rzx --out work/stage1/rzx --every 250 \
        --snap 5000,10000,...

Writes OUT/screens.bin (6912 bytes a sample), OUT/ram.bin (49152 bytes a RAM sample, OUT/index.json 'ram'), OUT/index.json (the RZX frame of each
sample) and OUT/snap-FFFFF.z80. The RZX is someone else's run: a witness only where said.
"""
import argparse
import json
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402
from skoolkit.simutils import get_state  # noqa: E402
from skoolkit.snapshot import write_snapshot  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('--out', required=True)
    ap.add_argument('--every', type=int, default=250)
    ap.add_argument('--snap', default='')
    ap.add_argument('--ram-every', type=int, default=1000)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    snaps = {int(x) for x in args.snap.split(',') if x}
    screens = open(os.path.join(args.out, 'screens.bin'), 'wb')
    varsf = open(os.path.join(args.out, 'ram.bin'), 'wb')
    ramidx = []
    index = []
    orig_next = rzxplay.RZXTracer.next_frame

    def next_frame(self):
        n = self.context.frame_count
        if self.frame_index < 0 and 0 in snaps:  # the RZX's own start snapshot, before frame 0 runs
            ram, registers, state, machine = get_state(self.simulator)
            write_snapshot(os.path.join(args.out, 'snap-00000.z80'), ram, registers, state, machine)
        if self.frame_index >= 0:
            sim = self.simulator
            mem = sim.memory
            if n % args.every == 0:
                bank = 7 if self.out7ffd & 8 else 5
                scr = bytes(mem.banks[bank][:6912]) if hasattr(mem, 'banks') else bytes(mem[0x4000:0x5B00])
                screens.write(scr)
                index.append(n)
            if n % args.ram_every == 0:
                varsf.write(bytes(mem[0x4000:0x10000]))
                ramidx.append(n)
            if n in snaps:
                ram, registers, state, machine = get_state(sim)
                write_snapshot(os.path.join(args.out, f'snap-{n:05d}.z80'), ram, registers, state, machine)
        return orig_next(self)

    rzxplay.RZXTracer.next_frame = next_frame
    rzxplay.main(['--no-screen', '--quiet', '--fps', '0', args.rzx, os.path.join(args.out, 'end.z80')])
    json.dump({'rzx': args.rzx, 'every': args.every, 'frames': index, 'ram': ramidx}, open(os.path.join(args.out, 'index.json'), 'w'))
    print(f'{len(index)} samples, last frame {index[-1] if index else None}')


if __name__ == '__main__':
    main()
