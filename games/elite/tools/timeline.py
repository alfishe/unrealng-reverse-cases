#!/usr/bin/env python3
"""The state of a recording frame by frame (sampled), from the live instance that holds it (re_session.py open):
the view, the condition, witch space, the speed, and the eight ship slots (blueprint, energy, distance).

    python3 tools/timeline.py --work work/f1 --step 10 [--out work/prof/f1-timeline.json]

One `memory_at` of `$6048-$7130` a sample (the slots and the flight variables) and one of `$D054-$D0BC` (the
commander record and the mission bytes). The JSON is a list of {frame, view, condition, witch, speed, safe, sun
near, slots: [[slot, blueprint, energy, z_top, z_high], ...], bars: {fore, aft, fuel, cabin, laser, banks},
commander: {legal, score, cash, fuel, missiles, hold, nova, mission, flags, jumps, galaxy, stock}}.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import elitelib as E  # noqa: E402

SLOTS, SLOT = 0x6048, 39
VARS = {'view': 0x70E3, 'speed': 0x70E6, 'witch': 0x7103, 'condition': 0x7104, 'safe': 0x711C, 'sun_near': 0x711E}


def sample(s, frame):
    lo = SLOTS
    mem = E.read(s, frame, lo, 0x7130 - lo)
    out = {'frame': frame}
    for k, a in VARS.items():
        out[k] = mem[a - lo]
    slots = []
    for n in range(8):
        b = mem[n * SLOT:(n + 1) * SLOT]
        if b[0x22]:
            slots.append([n, b[0x23], b[0x22], b[0x08], b[0x07]])
    out['slots'] = slots
    bar = lambda a: mem[a - lo]
    out['bars'] = {'fore': bar(0x70E8), 'aft': bar(0x70EA), 'fuel': bar(0x70EC), 'cabin': bar(0x70EE),
                   'laser': bar(0x70F0), 'banks': [bar(0x70F6), bar(0x70F8), bar(0x70FA), bar(0x70FC)]}
    r = E.read(s, frame, 0xD054, 0xD0BD - 0xD054)
    out['commander'] = {'legal': r[0x0B], 'score': r[0x0C] | r[0x0D] << 8 | r[0x0E] << 16,
                        'jumps': r[0x0F] | r[0x10] << 8, 'galaxy': r[0x11] + 1,
                        'cash': ((r[0x12] | r[0x13] << 8) * 10000 + (r[0x14] | r[0x15] << 8)) / 10,
                        'hold': list(r[0x17:0x28]), 'free': r[0x28], 'nova': r[0x2D], 'fuel': r[0x2E] / 10,
                        'missiles': r[0x2F], 'equipment': list(r[0x30:0x3A]), 'mission': r[0x5B], 'flags': r[0x5C], 'stock': list(r[0x4A:0x5B])}
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--step', type=int, default=10)
    ap.add_argument('--first', type=int, default=0)
    ap.add_argument('--last', type=int)
    ap.add_argument('--out')
    a = ap.parse_args()
    s = E.session(a.work)
    last = a.last or json.load(open(os.path.join(a.work, 'capture.json')))['frames']
    rows = [sample(s, f) for f in range(a.first, last, a.step)]
    out = a.out or os.path.join(E.CASE, 'work', 'prof', os.path.basename(os.path.normpath(a.work)) + '-timeline.json')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(rows, open(out, 'w'))
    print('%d samples -> %s' % (len(rows), out))


if __name__ == '__main__':
    main()
