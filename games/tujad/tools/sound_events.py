#!/usr/bin/env python3
"""Every sound, text and HUD event of a window of a recording, from access traces taken in chunks: the speaker writes
(`OUT` to port `$FE`: value, PC), the entries of the sound routines (RiseSweep, FallSweep, PassTick, PickupTone,
BeamDown, BeamUp, TeleportFlash, DeathEffect, HazardFlash), of the printers (PrintBcd A and HL, PrintText HL and DE,
ShowWeapon, DrawHud), of QueueMessage (HL and the priority shown), of ProgressScreen (A), of the scroller's steps
(InterruptScrollStep, ScrollLine), and every interrupt entry, each at its moment (frame, CPU T-state in the frame).

    python3 tools/sound_events.py --work work/docs/tjD/r30 --frames 0-672 --out work/docs/tjD/r30-events.json
          [--chunk 50] [--keep]

The traces are taken on the instance of --work (re_session.py open: session.json holds the recording) one chunk at a
time and deleted after reading unless --keep. A frame of the trace is the frame in which the instruction ran (not
the memory sample of a frame, which is the state at its start). The JSON is read by tools/fig_sound.py and
tools/fig_hud.py.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

# routine entries (from build/game.lst)
ENTRIES = {
    0x7F4D: 'RiseSweep', 0x7F5D: 'FallSweep', 0x7F6D: 'PassTick', 0x7856: 'PickupTone', 0x7F9C: 'BeamDown',
    0x8005: 'BeamUp', 0x8051: 'TeleportFlash', 0x7ADF: 'DeathEffect', 0x699B: 'HazardFlash', 0x7B3F: 'PrintBcd',
    0x8AB4: 'PrintText', 0x79C2: 'ShowWeapon', 0x8AE8: 'DrawHud', 0x6ACD: 'QueueMessage', 0x8F53: 'ProgressScreen',
    0x9046: 'ProgressPercent', 0x8854: 'Menu', 0x7A2F: 'NewGame', 0x6A3C: 'LoseLife', 0x7719: 'Teleport',
    0x7703: 'EdPickup', 0x69F9: 'WinTestRoom', 0x6A83: 'LoseLifeGameOver', 0x7AD2: 'EnergyTickStep',
    0x9658: 'ScrollStep', 0x96CB: 'ScrollEnd', 0x96E4: 'ScrollSet', 0x9013: 'ProgressFlash', 0x8F8A: 'ProgressDraw',
    0x9031: 'ProgressDone',
}


def caller_of(ins, i):
    return ins[i - 1].pc if i else None


def scan(trace, out):
    ins = trace.instructions
    units = max(1, trace.units_per_t)
    for i, x in enumerate(ins):
        for c in x.cycles:
            if c.tag == 'O' and (c.address & 0xFF) == 0xFE:
                f, t = trace.cycle_t(x, c)
                out['out_fe'].append([f, t, c.value, x.pc])
        name = ENTRIES.get(x.pc)
        if name:
            out['calls'].append([x.frame, x.t // units, name, x.af >> 8, x.bc, x.de, x.hl, caller_of(ins, i)])
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
           'instructions': 0, 'out_fe': [], 'calls': [], 'irq': []}
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
