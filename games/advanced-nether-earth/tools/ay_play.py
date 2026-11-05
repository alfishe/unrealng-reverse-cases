#!/usr/bin/env python3
"""Runs one of ANE's AY players on SkoolKit's simulator, frame by frame, and logs what it sends to the AY.

    VENV/bin/python tools/ay_play.py --load FILE@ADDR[:SKIP[:LEN]] ... --init C000 --play C005 \
        --frames 6000 --out work/docR/ay/game.json [--poke ADDR=HEX ...]

The memory is a plain 64 K (no paging, no ROM): each --load puts LEN bytes of FILE from offset SKIP at ADDR. The
player's init is called once, then its play entry once per frame, each call from a sentinel return address, as
the game's interrupt handlers call it. The players touch no ROM and no other port, so the run is exact; Pentagon
has no contended memory, so the simulator's T-states are the real ones.

The JSON holds, per frame: the T-states of the call, the AY writes in order ([register, value]), and the 14
registers as the AY holds them after the call. `summary` prints the cost per call (min / median / max) and the
first frame the module loops.
"""
import argparse
import json
import os
import statistics
import sys

from skoolkit.simulator import Simulator
from skoolkit import simutils as su

SENTINEL = 0x0000  # a HALT the players never reach on their own (no ROM is loaded)


class AY:
    def __init__(self):
        self.reg = 0
        self.regs = [0] * 16
        self.writes = []

    def write_port(self, registers, port, value, *a):
        if port & 0xC002 == 0xC000:
            self.reg = value & 15
        elif port & 0xC002 == 0x8000:
            self.regs[self.reg] = value
            self.writes.append((self.reg, value))

    def read_port(self, registers, port):
        if port & 0xC002 == 0xC000:
            return self.regs[self.reg]
        return 0xFF


def call(sim, addr, limit=2_000_000):
    r = sim.registers
    sp = r[su.SP] - 2
    sim.memory[sp], sim.memory[sp + 1] = SENTINEL & 255, SENTINEL >> 8
    r[su.SP] = sp
    r[su.PC] = addr
    t0 = r[su.T]
    ops, mem = sim.opcodes, sim.memory
    while r[su.PC] != SENTINEL:
        ops[mem[r[su.PC]]]()
        if r[su.T] - t0 > limit:
            raise SystemExit(f'call {addr:04X} did not return')
    return r[su.T] - t0


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--load', action='append', required=True)
    p.add_argument('--poke', action='append', default=[])
    p.add_argument('--init', required=True)
    p.add_argument('--play', required=True)
    p.add_argument('--frames', type=int, default=3000)
    p.add_argument('--sp', default='5FF0')
    p.add_argument('--out', required=True)
    args = p.parse_args()

    mem = [0] * 0x10000
    mem[SENTINEL] = 0x76
    for spec in args.load:
        path, _, where = spec.rpartition('@')
        parts = where.split(':')
        addr = int(parts[0], 16)
        data = open(path, 'rb').read()
        skip = int(parts[1], 16) if len(parts) > 1 else 0
        n = int(parts[2], 16) if len(parts) > 2 else len(data) - skip
        mem[addr:addr + n] = data[skip:skip + n]
    for spec in args.poke:
        a, _, h = spec.partition('=')
        b = bytes.fromhex(h)
        mem[int(a, 16):int(a, 16) + len(b)] = b
    ay = AY()
    sim = Simulator(mem, {'SP': int(args.sp, 16)}, config={'fast_ldir': False, 'fast_djnz': False})
    sim.set_tracer(ay)
    t_init = call(sim, int(args.init, 16))
    frames = []
    for _ in range(args.frames):
        ay.writes = []
        t = call(sim, int(args.play, 16))
        frames.append({'t': t, 'w': ay.writes, 'r': ay.regs[:14]})
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    json.dump({'init_t': t_init, 'args': vars(args), 'frames': frames}, open(args.out, 'w'))
    ts = [f['t'] for f in frames]
    print(f'init {t_init} T; play min {min(ts)} median {statistics.median(ts)} max {max(ts)} T '
          f'({max(ts) / 71680:.1%} of a Pentagon frame); writes a frame {statistics.median(len(f["w"]) for f in frames)}')


if __name__ == '__main__':
    sys.exit(main())
