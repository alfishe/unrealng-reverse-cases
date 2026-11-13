#!/usr/bin/env python3
"""Play the RZX archive's deflektor.rzx (Roman Rugalenko's run, Spectaculator 0.75, 48K, 346 004 frames, recorded
with rollback) in SkoolKit's simulator, no emulator instance, and dump what it reached:

- every --every frames the screen (6912 bytes) into OUT/screens.bin;
- every --mem-every frames the whole 64 K into OUT/mem.bin;
- a Z80 snapshot at each frame of --snap (the warp points for our own recordings), OUT/snap-FFFFFF.z80;
- the port reads as the keys and the Kempston byte each frame ended with (OUT/inputs.json: for each port the frames
  where its last value changed), and the count of reads by PC and port (printed).

    python3 tools/rzx_dump.py work/candidates/rzxarchive/deflektor.rzx --out work/stage1/rzx --every 250 \
        --mem-every 1000 --snap 0,20000,... [--watch 81FF,837D --snap-on-change 81FF]

OUT/index.json names the RZX frame of each sample. The RZX is someone else's run: a witness only where said.
"""
import argparse
import collections
import json
import os
import sys
import time

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
    ap.add_argument('--mem-every', type=int, default=1000)
    ap.add_argument('--snap', default='')
    ap.add_argument('--watch', default='', help='hex addresses: OUT/watch.json lists the frames where each byte changed')
    ap.add_argument('--pc-log', default='', help='hex PC of a port read: OUT/pclog.json lists the frame and T-state of each')
    ap.add_argument('--no-dump', action='store_true', help='no screens, memory samples or snapshots')
    ap.add_argument('--snap-on-change', default='', help='hex address: a snapshot at each frame where its byte changed')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    snaps = {int(x) for x in args.snap.split(',') if x}
    watch = [int(x, 16) for x in args.watch.split(',') if x]
    soc = int(args.snap_on_change, 16) if args.snap_on_change else None
    seen, wch = {}, collections.defaultdict(list)
    pclog_pc = int(args.pc_log, 16) if args.pc_log else None
    pclog = []
    screens = open(os.path.join(args.out, 'screens.bin'), 'wb')
    memf = open(os.path.join(args.out, 'mem.bin'), 'wb')
    index, mindex = [], []
    last = {}          # port -> last value read this run
    changes = collections.defaultdict(list)  # port -> [[frame, value], ...] where the frame's last value changed
    frame_last = {}
    by = collections.Counter()
    began = time.time()
    orig_next = rzxplay.RZXTracer.next_frame
    orig_read = rzxplay.RZXTracer.read_port

    def flush_frame(n):
        for port, v in frame_last.items():
            if last.get(port) != v:
                changes[port].append([n, v])
                last[port] = v
        frame_last.clear()

    def next_frame(self):
        n = self.context.frame_count
        if self.frame_index >= 0:
            flush_frame(n - 1)
        if self.frame_index < 0 and 0 in snaps:
            ram, registers, state, machine = get_state(self.simulator)
            write_snapshot(os.path.join(args.out, 'snap-000000.z80'), ram, registers, state, machine)
        if self.frame_index >= 0 and not args.no_dump:
            mem = self.simulator.memory
            if n % args.every == 0:
                screens.write(bytes(mem[0x4000:0x5B00]))
                index.append(n)
            if n % args.mem_every == 0:
                memf.write(bytes(mem[0:0x10000]))
                mindex.append(n)
            for a in watch:
                if seen.get(a) != mem[a]:
                    seen[a] = mem[a]
                    wch[f'{a:04X}'].append([n, mem[a]])
            if soc is not None and seen.get(-1) != mem[soc]:
                if -1 in seen:
                    snaps.add(n)
                seen[-1] = mem[soc]
            if n in snaps:
                ram, registers, state, machine = get_state(self.simulator)
                write_snapshot(os.path.join(args.out, f'snap-{n:06d}.z80'), ram, registers, state, machine)
            if n % 20000 == 0:
                print(f'frame {n} after {time.time() - began:.0f} s', flush=True)
        return orig_next(self)

    def read_port(self, registers, port):
        value = orig_read(self, registers, port)
        key = port & 0xFF if port & 0xFF != 0xFE else port
        frame_last[key] = value
        by[(registers[24], key)] += 1
        if registers[24] == pclog_pc:
            pclog.append([self.context.frame_count, registers[25]])
        return value

    rzxplay.RZXTracer.next_frame = next_frame
    rzxplay.RZXTracer.read_port = read_port
    rzxplay.main(['--no-screen', '--quiet', '--fps', '0', args.rzx, os.path.join(args.out, 'end.z80')])
    json.dump({'rzx': args.rzx, 'every': args.every, 'frames': index, 'mem_every': args.mem_every, 'mem_frames': mindex},
              open(os.path.join(args.out, 'index.json'), 'w'))
    if pclog_pc is not None:
        json.dump(pclog, open(os.path.join(args.out, 'pclog.json'), 'w'))
    json.dump(wch, open(os.path.join(args.out, 'watch.json'), 'w'))
    json.dump({'rzx': args.rzx, 'changes': {f'{p:04X}': v for p, v in changes.items()}},
              open(os.path.join(args.out, 'inputs.json'), 'w'))
    for (pc, port), n in by.most_common(30):
        print(f'PC ${pc:04X} port ${port:04X}: {n} reads')
    print(f'{len(index)} screens, {len(mindex)} memory samples, last frame {index[-1] if index else None}')


if __name__ == '__main__':
    main()
