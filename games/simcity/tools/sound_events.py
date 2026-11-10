#!/usr/bin/env python3
"""Every speaker write and every entry of the sound routines in a window of a recording, from access traces.

    python3 tools/sound_events.py --work work/docs/scD/dis --frames 150-260 --out work/docs/scD/dis-150.json
          [--chunk 50] [--keep]

The traces are taken on the instance of --work (re_session.py open: its session.json holds the recording) one chunk
at a time and deleted after reading unless --keep. Kept per event:

- out_fe: [frame, T, value, PC] for each OUT to an even port (the ULA, port $FE);
- calls: [frame, T, name, A, BC, DE, HL, caller PC] for each entry of a routine of ENTRIES;
- irq: [frame, T, PC] for each interrupt taken (the instruction it interrupted);
- di: [frame, T, PC] for each DI and EI executed (op 'DI' / 'EI').

A frame of the trace is the frame in which the instruction ran (not the memory sample of a frame, which is the state
at its start). tools/fig_sound.py reads the JSON.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

# routine entries (build/game.lst)
ENTRIES = {
    0x5B48: 'NoiseBurst', 0x5B66: 'ToneBeep', 0x9108: 'FireNoise', 0x9116: 'FloodNoise', 0x9125: 'Earthquake',
    0x78BD: 'CrashNoise', 0x71E4: 'Refuse', 0x916E: 'RunDisaster', 0x90A7: 'FireDisaster', 0x90D5: 'FloodDisaster',
    0x78FE: 'AirCrash', 0x7913: 'NuclearMeltdown', 0x796C: 'StartTornado', 0x787E: 'MovePlane', 0x7103: 'CheckSite',
    0x71BC: 'PlaceNetwork', 0xF70B: 'Interrupt', 0x5CC6: 'Random',
}
SKIP_CALLS = {'Random', 'MovePlane'}   # counted, not listed one by one


def scan(trace, out):
    ins = trace.instructions
    units = max(1, trace.units_per_t)
    for i, x in enumerate(ins):
        for c in x.cycles:
            if c.tag == 'O' and (c.address & 0x01) == 0:
                f, t = trace.cycle_t(x, c)
                out['out_fe'].append([f, t, c.value, x.pc])
        name = ENTRIES.get(x.pc)
        if name:
            if name in SKIP_CALLS:
                out['counts'][name] = out['counts'].get(name, 0) + 1
            else:
                out['calls'].append([x.frame, x.t // units, name, x.af >> 8, x.bc, x.de, x.hl,
                                     ins[i - 1].pc if i else None])
        op = next((c.value for c in x.cycles if c.tag == 'F' and c.address == x.pc), None)
        if op in (0xF3, 0xFB):
            out['di'].append([x.frame, x.t // units, x.pc, 'DI' if op == 0xF3 else 'EI'])
        if x.interrupted:
            out['irq'].append([x.frame, x.t // units, x.pc])


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--frames', required=True, help='F0-F1')
    p.add_argument('--chunk', type=int, default=50)
    p.add_argument('--out', required=True)
    p.add_argument('--keep', action='store_true')
    p.add_argument('--unreal')
    a = p.parse_args()
    f0, f1 = (int(v) for v in a.frames.split('-'))
    out = {'work': os.path.relpath(a.work, os.path.join(HERE, '..')), 'frames': [f0, f1], 'frame_t': None,
           'instructions': 0, 'out_fe': [], 'calls': [], 'irq': [], 'di': [], 'counts': {}}
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
        print(f'{start}-{end}: {len(out["out_fe"])} speaker writes, {len(out["calls"])} calls', flush=True)
    with open(a.out, 'w') as f:
        json.dump(out, f)


if __name__ == '__main__':
    main()
