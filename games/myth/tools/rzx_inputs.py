#!/usr/bin/env python3
"""The port reads of the RZX Archive's myth.rzx (100 151 frames in six input blocks, each behind a 128K Z80 snapshot:
the menu, then each stage as loaded), played by SkoolKit's simulator, no emulator instance; what the case's keyed
replays of the run need (tools/rzx_script.py, tools/rzx_replay.py):

- every IN the game makes, per frame: the PC of the IN, the port and the value the RZX gave it, kept as the frame's
  distinct (pc, port, value) triples in order (OUT/inputs.json);
- the game's state at the end of every frame (OUT/state.tsv: frame, block, room column `$FE21` and row `$FE22`,
  energy `$FE3F`, lives `$FE61`, score `$F9FB` (word), the 128K bank port's last value, the CRC-32 of the screen
  `$4000-$5AFF` and of the stage's variables `$6D00-$77FF`), to check a replay against;
- a Z80 snapshot at each frame F of --snap (OUT/snap-FFFFFF.z80: the state at the end of RZX frame F-1, the
  interrupt that begins frame F pending), the start of a replay segment that does not begin at a block's own
  snapshot (work/stage1/rzx/snapN.z80 are those);
- every IN in order (OUT/reads.tsv: frame, PC, port, value, n = the IN's run count from the RZX's start, so a
  replay finds the n-th run of that IN from its own start), and the game's state at each IN of a keyboard half row
  whose keys (the low five bits) differ from that half row's last read (OUT/changes.tsv: frame, pc, port, value, n,
  then col row energy lives score and the CRC-32 of the screen and of `$6D00-$77FF` at the moment of the IN): the
  points where tools/rzx_replay.py changes the keys and checks its own state;
- the first frame of each input block (OUT/blocks.json), so segment N's script frame 0 is RZX frame blocks[N].

Frames are counted as SkoolKit's rzxplay counts them: frame N's port reads are those its `frame_count` N names.
Myth has no frame sync (a pass of its main loop takes about 3 frames, the interrupt only steps the AY), so a frame
here is the RZX's input frame, not a pass.

    python3 tools/rzx_inputs.py work/candidates/rzxarchive/myth.rzx --out work/stage2/rzx [--snap F,F,...]

Prints the reads by PC and port. The RZX is someone else's run: a witness only where the documents say so.
"""
import argparse
import collections
import json
import os
import sys
import zlib

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402
from skoolkit.simutils import get_state  # noqa: E402
from skoolkit.snapshot import write_snapshot  # noqa: E402

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = (('col', 0xFE21), ('row', 0xFE22), ('energy', 0xFE3F), ('lives', 0xFE61), ('score_lo', 0xF9FB),
         ('score_hi', 0xF9FC))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('--out', required=True)
    ap.add_argument('--snap', default='')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    snaps = {int(x) for x in args.snap.split(',') if x}
    frames, blocks = {}, []
    rows = (0xF7FE, 0xFDFE, 0xFBFE, 0xEFFE, 0x7FFE, 0xFEFE, 0xDFFE, 0xBFFE)
    runs, last = collections.Counter(), {}
    reads_tsv = open(os.path.join(args.out, 'reads.tsv'), 'w')
    reads_tsv.write('frame\tpc\tport\tvalue\tn\n')
    changes = open(os.path.join(args.out, 'changes.tsv'), 'w')
    changes.write('frame\tpc\tport\tvalue\tn\tcol\trow\tenergy\tlives\tscore\tscr\tvars\n')
    state = open(os.path.join(args.out, 'state.tsv'), 'w')
    state.write('frame\tblock\t' + '\t'.join(n for n, a in STATE) + '\t7ffd\tscr\tvars\n')
    orig_read = rzxplay.RZXTracer.read_port
    orig_next = rzxplay.RZXTracer.next_frame
    orig_set = rzxplay.RZXTracer.set_input_rec

    def set_input_rec(self, input_rec):
        # a block behind its own snapshot gets a new tracer; the last tracer's final next_frame has already counted
        # the frame up, so the block's first frame is the frame count now
        orig_set(self, input_rec)
        blocks.append(self.context.frame_count)

    def read_port(self, registers, port):
        value = orig_read(self, registers, port)
        f = frames.setdefault(self.context.frame_count, [])
        t = (registers[24], port, value)
        runs[t[0]] += 1
        n = runs[t[0]]
        reads_tsv.write(f'{self.context.frame_count}\t{t[0]}\t{port}\t{value}\t{n}\n')
        if port in rows and value & 0x1F != last.get(port, 0x1F):
            last[port] = value & 0x1F
            mem = self.simulator.memory
            changes.write('\t'.join(str(x) for x in (
                self.context.frame_count, t[0], port, value, n, mem[0xFE21], mem[0xFE22], mem[0xFE3F], mem[0xFE61],
                mem[0xF9FB] + 256 * mem[0xF9FC], zlib.crc32(bytes(mem.memory[1][:6912])),
                zlib.crc32(bytes(mem.memory[1][0x2D00:0x3800])))) + '\n')
        if not f or f[-1] != t:
            f.append(t)
        return value

    def next_frame(self):
        n = self.context.frame_count
        if self.frame_index >= 0:
            mem = self.simulator.memory
            state.write('\t'.join(str(x) for x in [n, len(blocks) - 1] + [mem[a] for _, a in STATE]
                                  + [self.out7ffd, zlib.crc32(bytes(mem.memory[1][:6912])),
                                     zlib.crc32(bytes(mem.memory[1][0x2D00:0x3800]))]) + '\n')
            if n + 1 in snaps:
                ram, registers, st, machine = get_state(self.simulator)
                write_snapshot(os.path.join(args.out, f'snap-{n + 1:06d}.z80'), ram, registers, st, machine)
        return orig_next(self)

    rzxplay.RZXTracer.read_port = read_port
    rzxplay.RZXTracer.next_frame = next_frame
    rzxplay.RZXTracer.set_input_rec = set_input_rec
    rzxplay.main(['--no-screen', '--quiet', '--fps', '0', args.rzx, os.path.join(args.out, 'end.z80')])
    state.close()
    reads_tsv.close()
    changes.close()
    last = max(frames) if frames else 0
    json.dump({'rzx': os.path.relpath(os.path.abspath(args.rzx), CASE), 'frames': last + 1,
               'reads': {str(k): v for k, v in sorted(frames.items())}},
              open(os.path.join(args.out, 'inputs.json'), 'w'))
    json.dump(blocks, open(os.path.join(args.out, 'blocks.json'), 'w'))
    print(f'{len(frames)} frames with port reads, last {last}; blocks start at {blocks}')
    by = collections.Counter()
    vals = collections.defaultdict(collections.Counter)
    for f, rows in frames.items():
        for pc, port, v in rows:
            by[(pc, port)] += 1
            vals[(pc, port)][v] += 1
    for (pc, port), n in by.most_common(40):
        print(f'PC ${pc:04X} port ${port:04X}: {n} frames, values {dict(vals[(pc, port)].most_common(6))}')


if __name__ == '__main__':
    main()
