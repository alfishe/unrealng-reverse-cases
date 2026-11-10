#!/usr/bin/env python3
"""Every sound and HUD event of a window of a recording, from access traces taken in chunks: the speaker writes
(`OUT` to port `$FE`: value, PC), the speech writes (`OUT` to port `$9F`: the allophone, PC), the calls of Beep
`$9CA4` (H the half period, L the cycles, the caller), of the ROM's BEEPER `$03B5` (HL, DE, the caller), of
StartPhrase `$9CEB` (A, the caller), of AddScore `$A3A7` (B, the caller), of CountDown `$A1B8` (B), of PrintChar
`$9C40` (A, H, L, the caller), and every interrupt entry, each at its moment (frame, CPU T-state in the frame).

    python3 tools/sound_events.py --work work/docs/ceD/l13 --frames 0-2300 --out work/docs/ceD/l13-events.json
          [--chunk 100] [--keep]

The traces are taken on the instance of --work (re_session.py open: session.json holds the recording) one chunk at a
time and deleted after reading unless --keep. A frame of the trace is the frame in which the instruction ran.
The JSON is read by tools/fig_sound.py and tools/fig_hud.py.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BEEP, BEEPER, START_PHRASE, ADD_SCORE, COUNT_DOWN, PRINT_CHAR = 0x9CA4, 0x03B5, 0x9CEB, 0xA3A7, 0xA1B8, 0x9C40
PLAY_TUNE = 0xAB60


def caller_of(ins, i):
    return ins[i - 1].pc if i else None


def scan(trace, out, prints):
    ins = trace.instructions
    units = max(1, trace.units_per_t)
    for i, x in enumerate(ins):
        for c in x.cycles:
            if c.tag == 'O':
                port = c.address & 0xFF
                if port == 0xFE or port == 0x9F:
                    f, t = trace.cycle_t(x, c)
                    out['out_fe' if port == 0xFE else 'out_9f'].append([f, t, c.value, x.pc])
        pc = x.pc
        t = x.t // units
        if pc == BEEP:
            out['beep'].append([x.frame, t, x.hl >> 8, x.hl & 0xFF, caller_of(ins, i)])
        elif pc == BEEPER:
            out['beeper'].append([x.frame, t, x.hl, x.de, caller_of(ins, i)])
        elif pc == START_PHRASE:
            out['phrase'].append([x.frame, t, x.af >> 8, caller_of(ins, i)])
        elif pc == ADD_SCORE:
            out['addscore'].append([x.frame, t, x.bc >> 8, caller_of(ins, i)])
        elif pc == COUNT_DOWN:
            out['countdown'].append([x.frame, t, x.bc >> 8, caller_of(ins, i)])
        elif pc == PLAY_TUNE:
            out['tune'].append([x.frame, t, x.hl, caller_of(ins, i)])
        elif pc == PRINT_CHAR and prints:
            out['print'].append([x.frame, t, x.af >> 8, x.hl >> 8, x.hl & 0xFF, caller_of(ins, i)])
        if x.interrupted:
            out['irq'].append([x.frame, t, pc])


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--frames', required=True, help='F0-F1')
    p.add_argument('--chunk', type=int, default=100)
    p.add_argument('--out', required=True)
    p.add_argument('--keep', action='store_true')
    p.add_argument('--no-prints', action='store_true', help='leave out the PrintChar calls')
    p.add_argument('--unreal')
    a = p.parse_args()
    f0, f1 = (int(v) for v in a.frames.split('-'))
    keys = ('out_fe', 'out_9f', 'beep', 'beeper', 'phrase', 'addscore', 'countdown', 'tune', 'print', 'irq')
    out = {'work': os.path.relpath(a.work, os.path.join(HERE, '..')), 'frames': [f0, f1], 'frame_t': None,
           'instructions': 0, **{k: [] for k in keys}}
    for start in range(f0, f1, a.chunk):
        end = min(f1, start + a.chunk)
        ns = argparse.Namespace(trace=None, work=a.work, window=f'{start}:0-{end}:0', max_cycles=None,
                                unreal=a.unreal)
        trace = K.load_trace(ns)
        out['frame_t'] = trace.frame_t
        out['instructions'] += len(trace.instructions)
        if trace.truncated:
            print(f'{start}-{end}: TRUNCATED', file=sys.stderr)
        scan(trace, out, not a.no_prints)
        if not a.keep:
            os.remove(os.path.join(os.path.abspath(a.work), 'traces', f'{start}_0-{end}_0.uatr'))
        print(f'{start}-{end}: {len(out["out_fe"])} speaker writes, {len(out["beep"])} Beep calls, '
              f'{len(out["out_9f"])} speech writes', flush=True)
    with open(a.out, 'w') as f:
        json.dump(out, f)


if __name__ == '__main__':
    main()
