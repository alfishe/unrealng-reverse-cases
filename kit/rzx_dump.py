#!/usr/bin/env python3
"""Play an RZX in SkoolKit's simulator (rzxplay, no emulator instance) and keep what it reached: the kit's copy of
the cases' tools/rzx_dump.py (Deflektor's, Rex's), for any 48K or 128K RZX.

    python3 kit/rzx_dump.py RZX --out OUT [--every N] [--mem-every N] [--snap F,F,...] [--no-dump]
        [--watch ADDR,...] [--snap-on-change ADDR] [--pc-log PC] [--stop FRAMES]

- every --every frames the screen (6912 bytes, the CPU's view of $4000) into OUT/screens.bin, every --mem-every
  frames the 64 K the CPU sees into OUT/mem.bin; OUT/index.json names the frame of each sample;
- a Z80 snapshot at each frame of --snap (0: the RZX's own start), OUT/snap-FFFFFF.z80, and with --snap-on-change
  ADDR one at each frame where that byte changed;
- --watch ADDR,...: the frames where each watched byte changed, with its new value (OUT/watch.json);
- --pc-log PC: the frame and T-state of each port read at that PC (OUT/pclog.json; Rex's pass reads ENTER at `$95D5`
  once a pass: the passes' lengths);
- the port reads as the keys each frame ended with (OUT/inputs.json: for each port the frames where its last value
  changed) and the count of reads by PC and port (printed).

--stop FRAMES ends the play after that many frames (rzxplay's --stop). --no-dump leaves out the screens and the
memory samples (the slow part on a long RZX); --watch, --pc-log, --snap and --snap-on-change still work with it (the
cases' copies wrote no watch.json with --no-dump).

    python3 ../../kit/rzx_dump.py work/stage1/media/rzx/rex/rex1.rzx --out work/stage1/rzx-pass/p1 --no-dump \\
        --pc-log 95D5 --watch A063,A06C,A04D,A04F

SkoolKit is found as kit/toolpaths.py finds the venv. The RZX is someone else's run: a witness only where said.
"""
import argparse
import collections
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import z80sim  # noqa: E402

z80sim.need_skoolkit()
from skoolkit import rzxplay  # noqa: E402
from skoolkit.simutils import get_state  # noqa: E402
from skoolkit.snapshot import write_snapshot  # noqa: E402


def hexlist(text):
    return [int(x, 16) for x in text.split(',') if x]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('rzx')
    ap.add_argument('--out', required=True)
    ap.add_argument('--every', type=int, default=250, help='a screen every N frames (OUT/screens.bin)')
    ap.add_argument('--mem-every', type=int, default=1000, help='the 64 K every N frames (OUT/mem.bin)')
    ap.add_argument('--snap', default='', help='frames: a Z80 snapshot at each (0: the RZX start)')
    ap.add_argument('--watch', default='', help='hex addresses: OUT/watch.json lists the frames where each byte changed')
    ap.add_argument('--pc-log', default='', help='hex PC of a port read: OUT/pclog.json lists the frame and T-state of each')
    ap.add_argument('--no-dump', action='store_true', help='no screens or memory samples (the rest still works)')
    ap.add_argument('--snap-on-change', default='', help='hex address: a snapshot at each frame where its byte changed')
    ap.add_argument('--stop', type=int, default=None, help='end after FRAMES frames')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    snaps = {int(x) for x in args.snap.split(',') if x}
    watch = hexlist(args.watch)
    soc = int(args.snap_on_change, 16) if args.snap_on_change else None
    seen, wch = {}, collections.defaultdict(list)
    pclog_pc = int(args.pc_log, 16) if args.pc_log else None
    pclog = []
    screens = memf = None
    if not args.no_dump:
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

    def snapshot(sim, n):
        ram, registers, state, machine = get_state(sim)
        write_snapshot(os.path.join(args.out, f'snap-{n:06d}.z80'), ram, registers, state, machine)

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
            snapshot(self.simulator, 0)
        if self.frame_index >= 0:
            mem = self.simulator.memory  # a 128K's paged memory has no slices: byte by byte
            if not args.no_dump:
                if n % args.every == 0:
                    screens.write(bytes(mem[a] for a in range(0x4000, 0x5B00)))
                    index.append(n)
                if n % args.mem_every == 0:
                    memf.write(bytes(mem[a] for a in range(0x10000)))
                    mindex.append(n)
            for a in watch:
                if seen.get(a) != mem[a]:
                    seen[a] = mem[a]
                    wch[f'{a:04X}'].append([n, mem[a]])
            if soc is not None and seen.get(-1) != mem[soc]:
                if -1 in seen:
                    snaps.add(n)
                seen[-1] = mem[soc]
            if n in snaps and n:
                snapshot(self.simulator, n)
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
    stop = ['--stop', str(args.stop)] if args.stop else []
    rzxplay.main(['--no-screen', '--quiet', '--fps', '0'] + stop + [args.rzx, os.path.join(args.out, 'end.z80')])
    if not args.no_dump:
        screens.close()
        memf.close()
        json.dump({'rzx': args.rzx, 'every': args.every, 'frames': index, 'mem_every': args.mem_every,
                   'mem_frames': mindex}, open(os.path.join(args.out, 'index.json'), 'w'))
    if pclog_pc is not None:
        json.dump(pclog, open(os.path.join(args.out, 'pclog.json'), 'w'))
    if watch:
        json.dump(wch, open(os.path.join(args.out, 'watch.json'), 'w'))
    json.dump({'rzx': args.rzx, 'changes': {f'{p:04X}': v for p, v in changes.items()}},
              open(os.path.join(args.out, 'inputs.json'), 'w'))
    for (pc, port), n in by.most_common(30):
        print(f'PC ${pc:04X} port ${port:04X}: {n} reads')
    print(f'{len(index)} screens, {len(mindex)} memory samples, '
          f'{sum(len(v) for v in wch.values())} watched changes, {len(pclog)} logged reads')


if __name__ == '__main__':
    main()
