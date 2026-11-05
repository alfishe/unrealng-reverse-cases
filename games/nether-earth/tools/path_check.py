#!/usr/bin/env python3
"""Check tools/path_model.py against the emulator, one WorldTurn at a time.

`capture` stops an own instance (tools/bot.py launch) at two execution breakpoints of WorldTurn: `$B0CD`, right after
EnemyCommander (the robot loop is next), and `$B0F9`, its RET (the robots and the shots are done). It keeps the 64 K
memory at both, one pair a turn, in an .npz. `verify` runs the model's robot and shot loops on the first picture of
each pair and compares the result with the second, byte for byte, over everything the loops may change: the robot
records, the shot records, the map, the random state (`$FD00`-`$FD03` and its index `$D371`), Side, SoundFx and the
two robot counts.

    python3 tools/path_check.py capture --work work/path/live --load work/ill1/snaps/deep-17400.szx --turns 300 \
        --out work/path/check-17400.npz
    python3 tools/path_check.py verify --cache work/path/check-17400.npz

With `--poke ADDR=HEX` the capture first writes memory (a test map, a robot), so an experiment of tools/path_lab.py
can be replayed on the real code too.
"""
import argparse
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import path_model as P  # noqa: E402

ROBOT_LOOP, WORLD_RET = 0xB0CD, 0xB0F9
SCENARIO_RANGES = [(0xD371, 0xD372), (0xD7D3, 0xD7FC), (0xDA00, 0xFD04), (0xFD10, 0xFD11), (0xFD70, 0xFDEC)]
REGIONS = [('random index', 0xD371, 1), ('shots', 0xD7D3, 45), ('robots', 0xDA00, 0x300), ('map', 0xDD00, 0x2000),
           ('random', 0xFD00, 4), ('counts', 0xFD41, 1), ('counts', 0xFD49, 1), ('side', 0xFD51, 1),
           ('soundfx', 0xFD53, 1)]


def cmd_capture(args):
    import kitlib as K
    import bot
    g = bot.Game(K.unreal_root(args.unreal), args.work).attach()
    m = g.m
    if args.load:
        m.post('/snapshot/load', {'path': os.path.abspath(args.load)})
    for spec in args.poke or []:
        a, h = spec.split('=')
        g.s.call('memory_access', {'action': 'write', 'address': f'0x{int(a, 16):04X}', 'hex': h}, ok=False)
    g.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/feature/breakpoints',
                            'body': {'enabled': True}}, ok=False)
    ids = []
    for a in (ROBOT_LOOP, WORLD_RET):
        r = m.post('/breakpoints', {'type': 'exec', 'address': f'0x{a:04X}', 'note': 'path_check'})
        ids.append(r.get('id'))
    before, after = [], []
    scenario = None
    if args.scenario:
        import path_lab as L
        shape, order, loco, seed, *start = args.scenario.split(':')
        start = tuple(int(v) for v in start[0].split(',')) if start else L.START
        scenario = L.scenario(shape, int(order), parts=L.PARTS[loco], start=start)
        L.seed_rng(scenario, int(seed))
    try:
        while len(after) < args.turns:
            r = None
            for _ in range(100):           # a call runs at most 100000 instructions
                r = m.post('/steps', {'count': 100_000})
                stop = r.get('stop') or {}
                if stop.get('reason') == 'breakpoint':
                    break
            else:
                # the play loop is left (a won or lost game, a menu): keep the turns captured so far
                print(f'no breakpoint within 10M instructions, pc {r.get("pc", 0):04X}: stopped', flush=True)
                break
            if stop.get('reason') != 'breakpoint':
                break
            pc = stop.get('address')
            if scenario is not None and pc == ROBOT_LOOP:
                # the test world of path_lab.py into the running game, once, right before the robot loop
                for start, end in SCENARIO_RANGES:
                    for a in range(start, end, 1024):
                        chunk = bytes(scenario[a:min(a + 1024, end)])
                        g.s.call('memory_access', {'action': 'write', 'address': f'0x{a:04X}', 'hex': chunk.hex(' ')},
                                 ok=False)
                if bytes(m.read(0xDA00, 0x2300)) != bytes(scenario[0xDA00:0xFD00]):
                    raise SystemExit('the scenario did not land in memory')
                scenario = None
            mem = np.frombuffer(m.read(0, 0x10000), dtype=np.uint8).copy()
            if pc == ROBOT_LOOP:
                before.append(mem)
            elif pc == WORLD_RET and len(before) == len(after) + 1:
                after.append(mem)
            if len(after) % 50 == 0 and pc == WORLD_RET:
                print(f'{len(after)} turns', flush=True)
    finally:
        for i in ids:
            if i is not None:
                g.s.call('invoke_api', {'method': 'DELETE', 'path': '/api/v1/emulator/{id}/breakpoints/' + str(i)},
                         ok=False)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    np.savez_compressed(args.out, before=np.array(before), after=np.array(after),
                        meta=np.array({'load': args.load, 'poke': args.poke or []}, dtype=object))
    print(f'{args.out}: {len(after)} turns')


def compare(a, b):
    diffs = []
    for name, start, n in REGIONS:
        x, y = a[start:start + n], b[start:start + n]
        if bytes(x) != bytes(y):
            where = [start + i for i in range(n) if x[i] != y[i]]
            diffs.append((name, where[:8], len(where)))
    return diffs


class InterruptedWorld(P.World):
    """the model with PlayInterrupt's noise sound (30 Random calls, NoiseSound) put in before the robot loop's own
    draws number @p at (one entry per interrupt)"""

    def __init__(self, memory, at=()):
        super().__init__(memory)
        self.at = sorted(at)
        self.own = 0

    def random(self):
        while self.at and self.at[0] == self.own:
            self.at.pop(0)
            for _ in range(30):
                super().random()
        self.own += 1
        return super().random()

    def world_turn(self, before_slot=None):
        super().world_turn(before_slot)
        for _ in self.at:                 # after the loop's last draw
            for _ in range(30):
                super().random()
        self.at = []


def model_turn(a, at=()):
    w = InterruptedWorld(bytes(a), at)
    w.world_turn()
    return w


def explain(a, b, own):
    """the draw positions (one or two interrupts) that make the model's turn match"""
    for k in range(own + 12):
        if matches(model_turn(a, (k,)), b):
            return (k,)
    for k1 in range(own + 12):
        for k2 in range(k1, own + 12):
            if matches(model_turn(a, (k1, k2)), b):
                return (k1, k2)
    return None


def matches(w, b):
    return not [x for x in compare(np.frombuffer(bytes(w.m), dtype=np.uint8), b) if x[0] != 'soundfx']


def cmd_verify(args):
    d = np.load(args.cache, allow_pickle=True)
    before, after = d['before'], d['after']
    noise_at = {}
    kinds = {'identical': 0, 'tone': 0, 'noise': 0, 'unexplained': 0, 'skipped': 0}
    steps = draws = 0
    branches = {}
    for t, (a, b) in enumerate(zip(before, after)):
        try:
            w = model_turn(a)
        except P.Unmodelled as e:
            kinds['skipped'] += 1
            print(f'turn {t}: skipped ({e})')
            continue
        diffs = compare(np.frombuffer(bytes(w.m), dtype=np.uint8), b)
        kind = 'identical'
        if diffs:
            # PlayInterrupt may run inside the robot loop: it counts SoundFx on (a tone: nothing else changes) and,
            # for the noise sounds ($80-$FF), calls Random 30 times (NoiseSound)
            rest = [x for x in diffs if x[0] != 'soundfx']
            if not rest:
                kind = 'tone'
            else:
                at = explain(a, b, w.draws)
                if at is None:
                    kind = 'unexplained'
                else:
                    kind, w = 'noise', model_turn(a, at)
                    noise_at[len(at)] = noise_at.get(len(at), 0) + 1
            if kind == 'unexplained':
                print(f'turn {t}: MISMATCH {diffs}')
                if args.stop:
                    break
        kinds[kind] += 1
        if kind != 'unexplained':
            steps += len(w.log)
            draws += getattr(w, 'own', w.draws)
            for e in w.log:
                key = e['branch'] + (':' + e['rule'] if e.get('rule') else '') + (' (past the table)' if 'past_table' in e else '')
                branches[key] = branches.get(key, 0) + 1
    print(f"{args.cache}: {len(before)} turns: {kinds['identical']} identical, {kinds['tone']} identical but SoundFx "
          f"(counted by the interrupt), {kinds['noise']} identical with the interrupt's 30 noise draws put in between "
          f"(once: {noise_at.get(1, 0)}, twice: {noise_at.get(2, 0)}), {kinds['unexplained']} unexplained, {kinds['skipped']} skipped; {steps} robot steps, {draws} random "
          f"draws; branches {dict(sorted(branches.items()))}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='command', required=True)
    c = sub.add_parser('capture')
    c.add_argument('--unreal')
    c.add_argument('--work', required=True)
    c.add_argument('--load')
    c.add_argument('--poke', nargs='*')
    c.add_argument('--scenario', help='shape:order:locomotion:seed[:x,y], a test world of path_lab.py')
    c.add_argument('--turns', type=int, default=100)
    c.add_argument('--out', required=True)
    v = sub.add_parser('verify')
    v.add_argument('--cache', required=True)
    v.add_argument('--stop', action='store_true')
    args = p.parse_args()
    {'capture': cmd_capture, 'verify': cmd_verify}[args.command](args)


if __name__ == '__main__':
    main()
