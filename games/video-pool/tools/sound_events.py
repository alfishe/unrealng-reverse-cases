#!/usr/bin/env python3
"""Every sound event of a recording, from access traces taken in chunks: the speaker writes (`OUT` to port `$FE`
with its value and the PC that wrote it), the BEEPER calls (`$03B5` with HL, DE and the caller), the SoundLoop
requests taken (`$8077` with the request), every write to SoundRequest `$827D` (value and PC), the SoundAbort exits
(`$80A8`), and the interrupt entries (the first instruction of each interrupt), each at its moment (frame, T in the
frame).

    python3 tools/sound_events.py --work work/docs/vpD/w1 --frames 0-16378 --out work/docs/vpD/w1-sound.json
          [--chunk 200] [--keep]

The traces are taken on the instance of --work (re_session.py session.json holding the recording) one chunk at a
time and deleted after reading unless --keep (a whole recording is gigabytes). The JSON is read by
tools/fig_sound.py.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BEEPER, REQUEST, ABORT = 0x03B5, 0x8077, 0x80A8
REQUEST_CELL = 0x827D  # SoundRequest



def scan(trace, out):
    ins = trace.instructions
    for i, x in enumerate(ins):
        for c in x.cycles:
            if c.tag == 'O' and c.address & 0xFF == 0xFE:
                f, t = trace.cycle_t(x, c)
                out['out'].append([f, t, c.value, x.pc])
            elif c.tag == 'W' and c.address == REQUEST_CELL:
                f, t = trace.cycle_t(x, c)
                out['write'].append([f, t, c.value, x.pc])
        if x.pc == BEEPER:
            caller = ins[i - 1].pc if i else None
            out['beeper'].append([x.frame, x.t // max(1, trace.units_per_t), x.hl, x.de, caller])
        elif x.pc == REQUEST:
            out['request'].append([x.frame, x.t // max(1, trace.units_per_t), x.af >> 8])
        elif x.pc == ABORT:
            out['abort'].append([x.frame, x.t // max(1, trace.units_per_t)])
        if x.interrupted:
            out['irq'].append([x.frame, x.t // max(1, trace.units_per_t), x.pc])


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--frames', required=True, help='F0-F1')
    p.add_argument('--chunk', type=int, default=200)
    p.add_argument('--out', required=True)
    p.add_argument('--keep', action='store_true')
    p.add_argument('--unreal')
    a = p.parse_args()
    f0, f1 = (int(v) for v in a.frames.split('-'))
    out = {'work': os.path.relpath(a.work, os.path.join(HERE, '..')), 'frames': [f0, f1], 'frame_t': None,
           'out': [], 'write': [], 'beeper': [], 'request': [], 'abort': [], 'irq': [], 'instructions': 0}
    for start in range(f0, f1, a.chunk):
        end = min(f1, start + a.chunk)
        ns = argparse.Namespace(trace=None, work=a.work, window=f'{start}:0-{end}:0', max_cycles=None,
                                unreal=a.unreal)
        trace = K.load_trace(ns)
        out['frame_t'] = trace.frame_t
        out['instructions'] += len(trace.instructions)
        if trace.truncated:
            print(f'{start}-{end}: TRUNCATED', file=sys.stderr)
        scan(trace, out)
        if not a.keep:
            os.remove(os.path.join(os.path.abspath(a.work), 'traces', f'{start}_0-{end}_0.uatr'))
        print(f'{start}-{end}: {len(out["out"])} speaker writes, {len(out["beeper"])} BEEPER calls', flush=True)
    with open(a.out, 'w') as f:
        json.dump(out, f)


if __name__ == '__main__':
    main()
