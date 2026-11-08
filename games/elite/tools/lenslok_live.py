#!/usr/bin/env python3
"""Real Lenslok challenges from the emulator: branches of the c1 recording driven over MCP, never patched.

    python3 tools/lenslok_live.py [--work work/c1] [--out work/atlas/live]

c1 must be open (re_session.py open --work work/c1 --ttd work/c1/session.ttd). Each run seeks to frame 15760 (the
size screen, key loop at $C67D), turns the history live from there (time_travel resume: the instance's later history
is dropped, session.ttd is not touched), waits DELAY frames and presses ENTER. Each attempt is then stopped at
$C2A0 (the seed just stored at $C784; the 64 KB memory is saved) and at $C2A9 (the code drawn: the screen is saved).
The answer typed is either "99" (always wrong: Rand(9) never gives the digit 9) or the code computed from the saved
memory by running the game's own code $C2A0-$C2A5 in skoolkit's Z80 simulator (tools/lenslok_sim.py): the code is
never read from $C799 here. A run ends at the reset (RST 0 after two failed rounds) or at the game's entry $70E0.

Output: OUT/runs.json (per attempt: run, round, attempt, seed, marks, code, typed, accepted) and OUT/<run>-<n>.scr /
.bin, plus OUT/gif-<name>/NNNN.scr (screens every 2 frames while a code is typed, for tools/fig_lenslok.py).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import lenslok_sim as LS  # noqa: E402

BRANCH = 15760
FRAME = 69888
# (name, delay before the first ENTER, delay before the second round's ENTER, answers per attempt; 'right' = computed)
PLANS = [
    ('a', 0, 3, ['99', '99', '99', '99', '99', 'right']),
    ('b', 7, 11, ['99', '99', '99', '99', '99', '99']),
    ('c', 13, 0, ['right']),
]
GIFS = {('a', 1): 'wrong', ('a', 6): 'accepted'}


class Live:
    def __init__(self, s):
        self.s = s

    def call(self, tool, args):
        return self.s.call(tool, args, ok=False)

    def frames(self, n):
        if n > 0:
            self.call('control_execution', {'action': 'run_frames', 'frames': n})

    def until(self, pc, frames=400):
        r = self.call('control_execution', {'action': 'run_until_pc', 'pc': hex(pc), 'max_tstates': FRAME * frames})
        return bool(r.structured and r.structured.get('hit'))

    def until_film(self, pc, film, frames=800):
        """run to pc in steps of 2 frames, keeping each step's screen"""
        for _ in range(frames // 2):
            r = self.call('control_execution', {'action': 'run_until_pc', 'pc': hex(pc), 'max_tstates': FRAME * 2})
            film.append(self.read(0x4000, 6912))
            if r.structured and r.structured.get('hit'):
                return True
        return False

    def key(self, name, hold=3, gap=8, film=None):
        self.call('type_input', {'action': 'press', 'key': name})
        self.run_film(hold, film)
        self.call('type_input', {'action': 'release', 'key': name})
        self.run_film(gap, film)

    def run_film(self, n, film):
        if film is None:
            self.frames(n)
            return
        for _ in range(0, n, 2):
            self.frames(2)
            film.append(self.read(0x4000, 6912))

    def read(self, addr, n):
        out = bytearray()
        for a in range(addr, addr + n, 0x1000):
            ln = min(0x1000, addr + n - a)
            r = self.call('memory_access', {'action': 'read', 'offset': hex(a), 'length': ln})
            for line in r.text.split('\n'):
                if line.startswith('0x') and ':' in line:
                    out += bytes.fromhex(line.split(':', 1)[1].split('|')[0])
        if len(out) != n:
            raise RuntimeError(f'read ${addr:04X}+{n}: got {len(out)}')
        return bytes(out)

    def pc(self):
        t = self.call('inspect_state', {}).text.split('\n')[1]
        return int(t.split('PC=0x')[1][:4], 16)


def save_film(out, name, film):
    gd = os.path.join(out, 'gif-' + name)
    os.makedirs(gd, exist_ok=True)
    for f in os.listdir(gd):
        os.remove(os.path.join(gd, f))
    for i, f in enumerate(film):
        open(os.path.join(gd, '%04d.scr' % i), 'wb').write(f)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', default=os.path.join(E.CASE, 'work', 'c1'))
    p.add_argument('--out', default=os.path.join(E.CASE, 'work', 'atlas', 'live'))
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    lv = Live(E.session(a.work))
    rows = []
    for name, d1, d2, answers in PLANS:
        lv.call('time_travel', {'action': 'seek', 'frame': BRANCH})
        lv.call('time_travel', {'action': 'resume'})
        lv.call('control_execution', {'action': 'pause'})
        lv.frames(d1)
        lv.key('enter', gap=0)
        rnd, att = 1, 0
        pending = None                                  # a film carried into the next attempt
        for n, ans in enumerate(answers, 1):
            hit = lv.until_film(0xC2A0, pending) if pending is not None else lv.until(0xC2A0, 3000)
            if not hit:
                raise RuntimeError(f'{name}-{n}: no attempt')
            att += 1
            mem = lv.read(0, 0x10000)
            if not mem[0xC785] & 0x80:
                raise RuntimeError(f'{name}-{n}: not at the seed ({mem[0xC785]:02X})')
            open(os.path.join(a.out, f'{name}-{n}.bin'), 'wb').write(mem)
            if pending is not None:
                lv.until_film(0xC2A9, pending)
                lv.run_film(20, pending)
                save_film(a.out, pending_name, pending)
                pending = None
            else:
                lv.until(0xC2A9)
            scr = lv.read(0x4000, 6912)
            open(os.path.join(a.out, f'{name}-{n}.scr'), 'wb').write(scr)
            sim = LS.attempt(mem)
            typed = sim['code'].decode() if ans == 'right' else ans
            film = [scr] * 10 if (name, n) in GIFS else None
            for ch in typed[:-1]:
                lv.key(ch.lower(), film=film)
            last = typed[-1].lower()
            if ans != 'right':
                lv.key(last, gap=0, film=film)
            else:                                       # CheckCode runs while the key is still held
                lv.call('type_input', {'action': 'press', 'key': last})
                ok = lv.until_film(0x70E0, film, 100) if film is not None else lv.until(0x70E0, 100)
                lv.call('type_input', {'action': 'release', 'key': last})
            row = {'run': name, 'n': n, 'round': rnd, 'attempt': att, 'seed': '%04X' % (mem[0xC784] | mem[0xC785] << 8),
                   'marks': ['%02X' % m for m in sim['marks']], 'code': sim['code'].decode(), 'typed': typed}
            if ans == 'right':
                row['accepted'] = ok
                if film is not None:
                    lv.run_film(150, film)
                    save_film(a.out, GIFS[(name, n)], film)
            else:
                row['accepted'] = False
                if film is not None:
                    pending, pending_name = film, GIFS[(name, n)]
                if att == 3 and n < len(answers):
                    rnd, att = rnd + 1, 0
                    if not lv.until(0xC475, 600):
                        raise RuntimeError(f'{name}-{n}: no second size screen')
                    lv.frames(d2)
                    lv.key('enter', gap=0)
            rows.append(row)
            print(row)
        if answers[-1] != 'right':
            row = rows[-1]
            row['reset'] = lv.until(0x0000, 600)
    json.dump(rows, open(os.path.join(a.out, 'runs.json'), 'w'), indent=1)
    print(len(rows), 'attempts')


if __name__ == '__main__':
    sys.exit(main())
