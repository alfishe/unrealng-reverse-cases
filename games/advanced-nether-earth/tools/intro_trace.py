#!/usr/bin/env python3
"""The boot's pictures run in the simulator (tools/ane_sim.py): what each of the intro, "Presents", the scroller
and the title picture at $9C40 executes, reads and writes, for tools/intro_mkpart.py.

    VENV/bin/python tools/intro_trace.py [--space FRAME] [--frames N] OUT.json

The run: power-on to the scroller, SPACE at --space (the default lets the scroller's text wrap once), on to the
title picture's return to UltraXOR's reader. The phase of an access is the program that owns the CPU: the n-th
entry at $6600 (the intro's block, its image, "Presents"' block, its image, the scroller's block, its image) or the
entry at $9C40 (the title picture, plain), by the PC: the loader ($6161-$65FF) and the player it pages in (bank 6)
are phase "player", the ROMs, the depackers at $5B89 and UltraXOR's reader phase "system". OUT.json: per phase the instruction starts ([address, bank at $C000, the opcode bytes]),
the CALL targets that ran, the data reads and the writes ([address, bank]) with their first frame.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ane_sim  # noqa: E402
from skoolkit import simutils as su  # noqa: E402

FRAME = ane_sim.FRAME


def main():
    p = argparse.ArgumentParser()
    p.add_argument('out')
    p.add_argument('--space', type=int, default=5950, help='the frame SPACE is pressed (10 frames)')
    p.add_argument('--frames', type=int, default=6400)
    args = p.parse_args()
    m = ane_sim.Machine(keys=[(args.space, 10, 'space')])
    m.boot_basic()
    r = m.sim.registers
    mem = m.mem
    state = {'phase': 'boot', 'image': 'boot', 'pc': 0, 'entries6600': 0, 'span': (0, 0), 'in_player': 0}
    names = ['intro-block', 'intro', 'presents-block', 'presents', 'scroller-block', 'scroller']
    log = {}

    def rec(kind, key):
        d = log.setdefault(state['phase'], {}).setdefault(kind, {})
        if key not in d:
            d[key] = r[su.T] // FRAME

    def bank(a):
        return mem.o7ffd & 7 if a >= 0xC000 else -1

    class Traced(type(mem)):
        def __getitem__(self, a):
            v = self.memory[a // 0x4000][a % 0x4000]
            lo, hi = state['span']
            if not lo <= a < hi and a >= 0x4000:
                rec('reads', (a, bank(a)))
            return v

        def __setitem__(self, a, v):
            if a >= 0x4000:
                rec('writes', (a, bank(a)))
            self.memory[a // 0x4000][a % 0x4000] = v

    mem.__class__ = Traced
    prev = {'pc': None, 'op': None}

    def hook(mm, pc):
        if pc == 0x6600:
            state['entries6600'] += 1
            state['image'] = names[min(state['entries6600'], len(names)) - 1]
        elif pc == 0x9C40:
            state['image'] = 'title'
        elif pc == 0x6060:
            state['image'] = 'after'
        # the loader's code and the player it pages in (bank 6) are logged apart from the program they interrupt
        if 0x6161 <= pc < 0x6600 or (pc >= 0xC000 and mm.mem.o7ffd & 7 == 6 and state['image'] != 'intro-block'):
            state['phase'] = 'player'
        elif pc < 0x4000 or 0x5B00 <= pc < 0x6161:
            state['phase'] = 'system'
        else:
            state['phase'] = state['image']
        raw = mm.mem.memory
        n = ane_sim_len(raw, pc)
        state['span'] = (pc, pc + n)
        op = bytes(raw[(pc + i) // 0x4000 % 4][(pc + i) % 0x4000] for i in range(n))
        if pc >= 0x4000:
            rec('code', (pc, bank(pc), op.hex()))
            if prev['op'] in CALLS or prev['op'] in RSTS:
                rec('calls', (pc, bank(pc)))
        prev['pc'], prev['op'] = pc, op[0]

    stop = m.run([0x6060], args.frames, hook)
    out = {}
    for phase, kinds in log.items():
        out[phase] = {kind: sorted([list(k) + [f] for k, f in d.items()]) for kind, d in kinds.items()}
    json.dump(out, open(args.out, 'w'))
    print('stop $%04X frame %d; phases %s' % (stop, r[su.T] // FRAME,
                                              ', '.join('%s %d' % (k, len(v.get('code', []))) for k, v in out.items())))


CALLS = {0xCD, 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC}
RSTS = set()


def ane_sim_len(raw, a):
    def b(x):
        x &= 0xFFFF
        return raw[x // 0x4000][x % 0x4000]
    mem = _View(b)
    return _decode(mem, a)[0]


class _View:
    def __init__(self, f):
        self.f = f

    def __getitem__(self, a):
        return self.f(a)


sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
from mkgame import decode as _decode  # noqa: E402

if __name__ == '__main__':
    main()
