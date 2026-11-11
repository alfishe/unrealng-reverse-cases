#!/usr/bin/env python3
"""The port reads of the RZX archive's terramex.rzx, played by SkoolKit's simulator (no emulator instance): for every
frame every IN with its PC, port and the value the RZX gave it, so the player's device and keys can be told from the
game's own input reads.

    python3 tools/rzx_inputs.py work/candidates/rzxarchive/terramex.rzx --out work/stage1/rzx/inputs.json

Output: {"frames": N, "reads": [[frame, pc, port, value], ...]} (PC of the IN's opcode). Prints the reads by PC and port.
"""
import argparse
import collections
import json
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    reads = []
    orig_read = rzxplay.RZXTracer.read_port

    def read_port(self, registers, port):
        value = orig_read(self, registers, port)
        reads.append([self.context.frame_count, registers[24], port, value])
        return value

    rzxplay.RZXTracer.read_port = read_port
    rzxplay.main(['--no-screen', '--quiet', '--fps', '0', args.rzx])
    json.dump({'rzx': args.rzx, 'frames': reads[-1][0] + 1 if reads else 0, 'reads': reads}, open(args.out, 'w'))
    by = collections.Counter((r[1], r[2] & 0xFF if r[2] & 0xFF != 0xFE else r[2]) for r in reads)
    for (pc, port), n in by.most_common(40):
        vals = collections.Counter(r[3] for r in reads if r[1] == pc and (r[2] & 0xFF if r[2] & 0xFF != 0xFE else r[2]) == port)
        print(f'PC ${pc:04X} port ${port:04X}: {n} reads, values {dict(vals.most_common(6))}')


if __name__ == '__main__':
    main()
