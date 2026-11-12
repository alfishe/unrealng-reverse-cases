#!/usr/bin/env python3
"""Play the RZX Archive run (work/candidates/rzxarchive/switchblade.rzx, xmikex and Jamie Angus, SPIN, 48K) in
SkoolKit's simulator, no emulator instance, and keep what our own recordings need to replay it:

- every port read the game makes, per frame: the PC of the IN, the port and the value the RZX gave it, kept as the
  frame's distinct (pc, port, value) triples in order (OUT/inputs.json);
- a Z80 snapshot at each frame F of --snap (OUT/snap-FFFFFF.z80): the state at the end of RZX frame F-1, the
  interrupt that begins frame F pending (the simulator's T-state counter 0), the start of a segment our recordings
  replay (tools/rzx_replay.py); snap-000000.z80 is the RZX's own start snapshot;
- the game's state at the end of every frame (OUT/state.tsv: frame, room `$6BDD`, row `$69DF`, column `$69E0`,
  Hiro's Y and X `$5D00` / `$5D01`, lives `$664D`, energy `$6642`), to check a replay against.

Frames are counted as SkoolKit's rzxplay counts them: frame N's port reads are those its `frame_count` N names, and
the interrupt that begins frame N+1 is accepted after the hook at the end of frame N.

    python3 tools/rzx_snap.py work/candidates/rzxarchive/switchblade.rzx --out work/stage2/rzx --snap 0,20000,...

The RZX is someone else's run: a witness only where said.
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

STATE = (0x6BDD, 0x69DF, 0x69E0, 0x5D00, 0x5D01, 0x664D, 0x6642)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('--out', required=True)
    ap.add_argument('--snap', default='')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    snaps = {int(x) for x in args.snap.split(',') if x}
    frames = {}
    state = open(os.path.join(args.out, 'state.tsv'), 'w')
    state.write('frame\troom\trow\tcol\ty\tx\tlives\tenergy\n')
    orig_read = rzxplay.RZXTracer.read_port
    orig_next = rzxplay.RZXTracer.next_frame

    def read_port(self, registers, port):
        value = orig_read(self, registers, port)
        f = frames.setdefault(self.context.frame_count, [])
        t = (registers[24], port, value)
        if not f or f[-1] != t:
            f.append(t)
        return value

    def next_frame(self):
        n = self.context.frame_count
        if self.frame_index >= 0:
            mem = self.simulator.memory
            state.write('\t'.join(str(x) for x in [n] + [mem[a] for a in STATE]) + '\n')
            if n + 1 in snaps:
                ram, registers, st, machine = get_state(self.simulator)
                write_snapshot(os.path.join(args.out, f'snap-{n + 1:06d}.z80'), ram, registers, st, machine)
        elif 0 in snaps:
            ram, registers, st, machine = get_state(self.simulator)
            write_snapshot(os.path.join(args.out, 'snap-000000.z80'), ram, registers, st, machine)
        return orig_next(self)

    rzxplay.RZXTracer.read_port = read_port
    rzxplay.RZXTracer.next_frame = next_frame
    rzxplay.main(['--no-screen', '--quiet', '--fps', '0', args.rzx, os.path.join(args.out, 'end.z80')])
    state.close()
    last = max(frames) if frames else 0
    json.dump({'rzx': os.path.relpath(args.rzx, os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
               'frames': last + 1, 'reads': {str(k): v for k, v in sorted(frames.items())}},
              open(os.path.join(args.out, 'inputs.json'), 'w'))
    print(f'{len(frames)} frames with port reads, last {last}')


if __name__ == '__main__':
    main()
