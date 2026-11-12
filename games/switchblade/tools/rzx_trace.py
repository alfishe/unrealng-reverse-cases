#!/usr/bin/env python3
"""Play the RZX run (candidates/rzxarchive/switchblade.rzx) in SkoolKit's rzxplay and log the game's state once per
frame: the map row and column (`$69DF`, `$69E0`), the room (`$6BDD`), Hiro's Y and X (`$5D00`, `$5D01`), the lives
(`$664D`, BCD) and the energy (`$6642`). Writes OUT/trace.tsv (a line whenever one of them changes) and
OUT/rooms/RRR.png (the screen on the last frame before Hiro leaves the room, from the last visit: the most
blocks revealed).

    PYTHONPATH=$SKOOLKIT_VENV/lib/python3.12/site-packages python3 tools/rzx_trace.py RZX OUT [--stop FRAMES]
"""
import argparse
import os
import sys

from skoolkit import rzxplay

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import zxscreen  # noqa: E402

VARS = (('row', 0x69DF), ('col', 0x69E0), ('room', 0x6BDD), ('y', 0x5D00), ('x', 0x5D01), ('lives', 0x664D),
        ('energy', 0x6642))
CTX = []


class Ctx(rzxplay.RZXContext):
    def __init__(self, screen):
        super().__init__(screen)
        CTX.append(self)


class Logger:
    def __init__(self, out):
        self.out = out
        os.makedirs(os.path.join(out, 'rooms'), exist_ok=True)
        self.f = open(os.path.join(out, 'trace.tsv'), 'w')
        self.f.write('frame\t' + '\t'.join(k for k, _ in VARS) + '\n')
        self.last, self.seen, self.pending = None, set(), {}

    def draw(self, scr, frame, border):
        mem = CTX[0].simulator.memory
        v = tuple(mem[a] for _, a in VARS)
        if v != self.last:
            self.f.write(f'{frame}\t' + '\t'.join(str(x) for x in v) + '\n')
            self.last = v
        room = v[2]
        self.seen.add(room)
        if self.pending and self.pending['room'] != room:
            zxscreen.render(self.pending['scr'], 1).save(os.path.join(self.out, 'rooms', f"{self.pending['room']:03d}.png"))
        self.pending = {'room': room, 'scr': bytes(scr[:6912])}
        return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('out')
    ap.add_argument('--stop', type=int)
    a = ap.parse_args()
    log = Logger(a.out)
    rzxplay.RZXContext = Ctx
    rzxplay.get_screen = lambda *args: log
    argv = [a.rzx, '--quiet']
    if a.stop:
        argv += ['--stop', str(a.stop)]
    rzxplay.main(argv)
    log.f.close()
    print('rooms', len(log.seen), sorted(log.seen))


if __name__ == '__main__':
    main()
