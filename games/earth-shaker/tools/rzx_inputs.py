#!/usr/bin/env python3
"""The port reads of an RZX recording, played by SkoolKit's simulator (no emulator instance): for every frame,
every IN with its PC, port and the value the RZX gave it, so the keys the player held can be told from the game's
own key tests (each test is `LD A,row; OUT ($FF),A; IN A,($FE); AND mask`, patched by the redefine menu).

    python3 tools/rzx_inputs.py work/stage1/rzxfiles/earth01.rzx --out work/stage1/rzx/earth01.ins.json \
        [--snapshot-out work/stage1/rzx/earth01-start.z80] [--end-out work/stage1/rzx/earth01-end.z80]

With it, NAME.state.bin next to the output: `$FD7E-$FFFF` (642 bytes: the variables and the unpacked cave) at the
end of every frame, for tools/rzx_align.py. The output: {"frames": N, "reads": [[frame, pc, port, value], ...], "start": {...}} with the PC of the IN
instruction (the address of its opcode). The RZX is someone else's recording (archive.org rzxarchive, "Earth Shaker",
32 files made with Spectaculator in April 2011).
"""
import argparse
import json
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402

STATE = 0xFD7E  # the game's variables and the unpacked cave, to the top of memory


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('--out', required=True)
    ap.add_argument('--end-out', help='a Z80 snapshot of the state after the last frame')
    args = ap.parse_args()
    reads, frames = [], []
    state = {'frame': 0}
    orig_next = rzxplay.RZXTracer.next_frame
    orig_read = rzxplay.RZXTracer.read_port

    def next_frame(self):
        if state['frame'] > 0:  # the state at the end of the frame just played
            mem = self.simulator.memory
            frames.append(bytes(mem[STATE:0x10000]))
        state['frame'] += 1
        return orig_next(self)

    def read_port(self, registers, port):
        value = orig_read(self, registers, port)
        pc = registers[24]
        reads.append([state['frame'] - 1, pc, port, value])
        return value

    rzxplay.RZXTracer.next_frame = next_frame
    rzxplay.RZXTracer.read_port = read_port
    argv = ['--no-screen', '--quiet', '--fps', '0', args.rzx]
    if args.end_out:
        argv.append(args.end_out)
    rzxplay.main(argv)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    json.dump({'rzx': args.rzx, 'frames': state['frame'], 'reads': reads}, open(args.out, 'w'))
    open(os.path.splitext(args.out)[0] + '.state.bin', 'wb').write(b''.join(frames))
    print(f"{args.rzx}: {state['frame']} frames, {len(reads)} port reads")


if __name__ == '__main__':
    main()
