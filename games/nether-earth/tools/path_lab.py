#!/usr/bin/env python3
"""Experiments on the robots' path finding (docs/13-path-finding.md), run on tools/path_model.py.

The model is the game's WorldTurn robot and shot loops, checked byte for byte against the emulator
(tools/path_check.py). A test world is a memory picture of work/deep (work/ill1/cache/deep10.npz, frame 3000) with
every robot and shot removed, the ship parked high, and then a test map window, one robot and one target written
into it. Between two turns the game draws Random outside the robot loop too (GameTurn once, EnemyCommander at least
once); a test turn draws it twice there (`EXTRA_DRAWS`), so successive turns do not reuse the same random bytes.

    python3 tools/path_lab.py odds --out work/path/odds.json        # the random choices, over the generator's orbit
    python3 tools/path_lab.py shapes --seeds 400 --out work/path/shapes.json   # obstacles: turns to the target
    python3 tools/path_lab.py ship --seeds 400 --out work/path/ship.json       # the ship parked in the way
    python3 tools/path_lab.py bug --seeds 400 --out work/path/bug.json         # 10.12: the aim past the table
    python3 tools/path_lab.py door --runs 300 --out work/path/door.json          # the approach to a door
    python3 tools/path_lab.py stuck --runs 6 --out work/path/stuck.npz         # where robots stay on the real map
    python3 tools/path_lab.py deep --out work/path/deep-stuck.json             # robots standing in work/deep

Each command prints the numbers docs/13 quotes and writes them as JSON (or .npz) for the figures (fig_path_*.py).
"""
import argparse
import collections
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import path_model as P  # noqa: E402

CASE = os.path.join(HERE, '..')
DEEP10 = os.path.join(CASE, 'work', 'ill1', 'cache', 'deep10.npz')
EXTRA_DRAWS = 2
BIPOD, TRACKS, ANTIGRAV, CANNON, ELECTRONICS = 0x01, 0x02, 0x04, 0x08, 0x80
LOCOMOTION = {'bipod': BIPOD, 'tracks': TRACKS, 'anti-grav': ANTIGRAV}
PARTS = {'bipod': BIPOD | CANNON, 'tracks': TRACKS | CANNON, 'anti-grav': ANTIGRAV | CANNON,
         'bipod-nuclear': BIPOD | CANNON | 0x40}
TALL, LOW, ROCK, TRENCH = 0x10, 0x0F, 0x08, 0x0C


# ----------------------------------------------------------------------------------------------------------------
# the test world

_BASE = {}


def deep_picture(frame=3000):
    if frame not in _BASE:
        d = np.load(DEEP10, allow_pickle=True)
        i = int(np.searchsorted(d['frames'], frame))
        _BASE[frame] = bytes(0x4000) + bytes(d['mems'][i])
    return _BASE[frame]


def empty_world(frame=3000):
    """work/deep's memory at @p frame without robots, shots or the ship's mark; the ship high above everything"""
    m = bytearray(deep_picture(frame))
    for slot in range(48):
        r = P.ROBOTS + 16 * slot
        if m[r + 1]:
            m[m[r] | m[r + 1] << 8] &= 0xBF
        m[r:r + 16] = bytes(16)
    for k in range(5):
        s = P.SHOTS + 9 * k
        if m[s + 1]:
            m[m[s] | m[s + 1] << 8] &= 0xBF
        m[s + 1] = 0
    for a in range(P.MAP, P.MAP + 0x2000):
        m[a] &= 0x7F
    m[P.ALTITUDE] = 0x30
    return m


def flatten(m, x0, x1, rows=range(16)):
    """bare ground (type 0) over columns x0..x1, buildings' object bits too"""
    for y in rows:
        for x in range(x0, x1 + 1):
            m[P.cell_address(x, y)] = 0


def block(m, x, y, tile=TALL):
    """PutBlock: a 2 x 2 block anchored at (x, y), covering x..x+1, y-1..y"""
    e = tile
    for row in (0, 1):
        for col in (0, 1):
            m[P.cell_address(x + col, y - row)] = e
            e |= 0x20


def wall(m, x, rows, tile=TALL):
    """a column of blocks at x, x+1 over the rows (each block covers two rows)"""
    for y in rows:
        block(m, x, y, tile)


def add_robot(m, slot, x, y, parts=BIPOD | CANNON, order=6, target=0xFF, facing=P.RIGHT, enemy=False, distance=0,
              height=11):
    r = P.ROBOTS + 16 * slot
    cell = P.cell_address(x, y)
    m[r:r + 16] = bytes([cell & 0xFF, cell >> 8, x & 0xFF, x >> 8, y, 0, 0, parts, facing, height,
                         0x80 if enemy else 0, order, 100, 0, distance if order in (1, 2) else target, 1])
    m[cell] |= 0x40
    return r


def only_target(m, index, x, y, owner=0x00, kind=1, table=P.FACTORIES):
    """capture point @p index at door (x, y) with owner bits @p owner; every other point of both tables is ours
    ($40), so order 6 (capture neutral) or 7 (enemy factories, owner $20) has this one target"""
    for t, n in ((P.WARBASES, 4), (P.FACTORIES, 24)):
        for i in range(n):
            m[t + 5 * i + 3] = 0x40 | (m[t + 5 * i + 3] & 0x07)
    a = table + 5 * index
    m[a], m[a + 1], m[a + 2], m[a + 3], m[a + 4] = x & 0xFF, x >> 8, y, owner | kind, 0


def seed_rng(m, seed):
    """a state of the generator: Start's seed run on by @p seed x 7919 + 1000 draws"""
    r = P.Rng()
    for _ in range(1000 + seed * 7919 % 200003):
        r()
    m[P.RANDOM_SEED:P.RANDOM_SEED + 4] = bytes(r.s)
    m[P.RANDOM_INDEX] = r.i


def run(w, turns, stop=None, extra=EXTRA_DRAWS):
    """@p turns robot turns; stop(w) ends early. Returns the turns run"""
    for t in range(1, turns + 1):
        for _ in range(extra):
            w.random()
        w.world_turn()
        if stop and stop(w):
            return t
    return None


def robot(w, slot=0):
    r = P.ROBOTS + 16 * slot
    return w.m[r + 2] | w.m[r + 3] << 8, w.m[r + 4]


# ----------------------------------------------------------------------------------------------------------------
# odds: the random choices over the generator's orbit

def probe_world():
    """a world for single decisions: robot 0 in the open at (300, 8)"""
    m = empty_world()
    flatten(m, 280, 320)
    add_robot(m, 0, 300, 8)
    return P.World(bytes(m), log=False)


def orbit_states(n, gap=3):
    """@p n generator states along its orbit, @p gap draws apart (the game draws between decisions)"""
    r = P.Rng()
    for _ in range(5000):
        r()
    out = []
    for _ in range(n):
        out.append(r.state())
        for _ in range(gap):
            r()
    return out


def set_state(w, st):
    w.m[P.RANDOM_SEED:P.RANDOM_SEED + 4] = bytes(st[:4])
    w.m[P.RANDOM_INDEX] = st[4]


def cmd_odds(args):
    w = probe_world()
    states = orbit_states(args.states)
    iy = P.ROBOTS
    out = {'states': len(states)}

    # Random's own bits
    bit = np.zeros(8)
    for st in states:
        set_state(w, st)
        a = w.random()
        bit += [(a >> k) & 1 for k in range(8)]
    out['bit'] = list(bit / len(states))

    # the course length: Random AND 3 + 3
    lengths = collections.Counter()
    for st in states:
        set_state(w, st)
        lengths[(w.random() & 3) + 3] += 1
    out['course_len'] = {k: v / len(states) for k, v in sorted(lengths.items())}

    # PickOneDirection over sets of 2, 3, 4 directions: the share of each and the draws it takes
    picks = {}
    for b in (P.RIGHT | P.LEFT, P.RIGHT | P.DOWN, P.DOWN | P.UP, P.RIGHT | P.DOWN | P.UP, P.LEFT | P.DOWN | P.UP,
              0x0F):
        c = collections.Counter()
        draws = 0
        for st in states:
            set_state(w, st)
            d0 = w.draws
            c[w.pick_one(b)] += 1
            draws += w.draws - d0
        picks[P.bits(b)] = {'share': {P.bits(k): v / len(states) for k, v in sorted(c.items())},
                            'draws': draws / len(states)}
    out['pick'] = picks

    # RobotLeanTo for advance (right) and retreat (left), by the free set
    lean = {}
    for wanted in (P.RIGHT, P.LEFT):
        for free in (0x0F, 0x0F & ~(wanted ^ 3), wanted | P.DOWN, wanted | P.UP, wanted | (wanted ^ 3), wanted,
                     0x0F & ~wanted, (wanted ^ 3) | P.DOWN):
            c = collections.Counter()
            how = collections.Counter()
            for st in states:
                set_state(w, st)
                w.steer = {}
                c[w.lean_to(iy, wanted, free, free)] += 1
                how[w.steer['lean']] += 1
            lean[f'{P.bits(wanted)} free {P.bits(free)}'] = {
                'share': {P.bits(k): v / len(states) for k, v in sorted(c.items())},
                'how': {k: v / len(states) for k, v in sorted(how.items())}}
    out['lean'] = lean

    # a whole new course in the open: the joint of its length and its direction (advance, 4 directions free)
    joint = collections.Counter()
    for st in states:
        set_state(w, st)
        n = (w.random() & 3) + 3
        w.steer = {}
        joint[(n, P.bits(w.lean_to(iy, P.RIGHT, 0x0F, 0x0F)))] += 1
    out['course_joint'] = {f'{n} {d}': v / len(states) for (n, d), v in sorted(joint.items())}

    # the weapon choice: Random AND $38 AND the parts
    fire = {}
    for name, parts in (('cannon', 0x08), ('missiles', 0x10), ('phasers', 0x20), ('cannon+missiles', 0x18),
                        ('all three', 0x38)):
        c = collections.Counter()
        for st in states:
            set_state(w, st)
            a = w.random() & 0x38 & parts
            c[3 if a & 0x20 else 2 if a & 0x10 else 1 if a else 0] += 1
        fire[name] = {['none', 'cannon', 'missiles', 'phasers'][k]: v / len(states) for k, v in sorted(c.items())}
    out['fire'] = fire

    # the near aim (|dx| < 8) and the far aim (|dx| >= 8) toward a door up and to the right, all free
    aims = {}
    for name, dx in (('far', 20), ('near', 5)):
        c = collections.Counter()
        for st in states:
            set_state(w, st)
            w.steer = {}
            diff = (-dx) & 0xFFFF
            c[P.bits(w.aim(iy, diff, 5, 0x0F, horizontal=True))] += 1
        aims[name] = {k: v / len(states) for k, v in sorted(c.items())}
    out['aim'] = aims
    print(json.dumps(out, indent=1))
    save_json(args.out, out)


def save_json(path, data):
    if path:
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        with open(path, 'w') as f:
            json.dump(data, f, indent=1)



# ----------------------------------------------------------------------------------------------------------------
# shapes: one robot, one obstacle, many seeds

X0, START, OBST = 270, (285, 8), 300


def shape_open(m):
    pass


def shape_block(m):
    block(m, OBST, 8)                                   # one tall block on the robot's two rows


def shape_tower(m):
    wall(m, OBST, (6, 8, 10))                           # rows 5-10


def shape_wall_top_gap(m):
    wall(m, OBST, range(3, 16, 2))                      # rows 2-15: the gap is rows 0-1


def shape_wall_bottom_gap(m):
    wall(m, OBST, range(1, 14, 2))                      # rows 0-13: the gap is rows 14-15


def shape_wall_full(m):
    wall(m, OBST, range(1, 16, 2))                      # rows 0-15


def shape_pocket(m):
    for x in range(OBST - 2, OBST + 6, 2):
        block(m, x, 4)                                  # the top arm, rows 3-4
        block(m, x, 13)                                 # the bottom arm, rows 12-13
    wall(m, OBST + 6, (4, 6, 8, 10, 12, 13))            # the back, rows 3-13: open to the left


def shape_corridor(m):
    for x in range(OBST - 4, OBST + 18, 2):
        block(m, x, 6)                                  # rows 5-6
        block(m, x, 10)                                 # rows 9-10: the corridor is rows 7-8


def shape_rocks(m):
    wall(m, OBST, range(1, 16, 2), tile=ROCK)          # rocks (type 8, height 6) over all 16 rows


def shape_trench(m):
    wall(m, OBST, range(1, 16, 2), tile=TRENCH)        # a trench (type $0C) over all 16 rows


SHAPES = {'open': shape_open, 'block': shape_block, 'tower': shape_tower, 'wall-top-gap': shape_wall_top_gap,
          'wall-bottom-gap': shape_wall_bottom_gap, 'wall-full': shape_wall_full, 'pocket': shape_pocket,
          'corridor': shape_corridor, 'rocks': shape_rocks, 'trench': shape_trench}
DOOR = (318, 8)          # the capture target: a door on the robot's row, past the obstacle
GOAL_X = 316             # advance: past the obstacle when the anchor reaches this column


def scenario(shape, order, parts=BIPOD | CANNON, door=DOOR, start=START, facing=P.RIGHT):
    m = empty_world()
    flatten(m, X0, X0 + 100)
    if not X0 <= start[0] <= X0 + 99:
        flatten(m, start[0] - 4, start[0] + 4)          # a start elsewhere: bare ground around it
    SHAPES[shape](m)
    if order in (1, 2):
        add_robot(m, 0, *start, parts=parts, order=order, distance=99, facing=facing)
    else:
        add_robot(m, 0, *start, parts=parts, order=order, facing=facing)
    # also: no enemy warbase left, so the enemy builds nothing; orders 4 and 7 go for an enemy factory
    only_target(m, 4, *door, owner=0x20 if order in (4, 7) else 0x00)
    return m


def done_test(order, door=DOOR):
    if order in (1, 2):
        return lambda w: robot(w)[0] >= GOAL_X
    return lambda w: robot(w) == door


def trial(m, seed, order, cap, door=DOOR, keep_log=False):
    seed_rng(m, seed)
    w = P.World(bytes(m), log=keep_log)
    track = []
    test = done_test(order, door)

    def stop(w):
        track.append(robot(w))
        if w.m[P.ROBOTS + 0x0B] != order and order in (1, 2):
            return True                  # the distance ran out
        return test(w)
    t = run(w, cap, stop)
    steps = sum(1 for a, b in zip(track, track[1:]) if a != b)
    return t, steps, track, w


def cmd_shapes(args):
    out = {}
    locos = {'bipod': BIPOD | CANNON, 'tracks': TRACKS | CANNON, 'anti-grav': ANTIGRAV | CANNON}
    for shape in args.shapes:
        for order in (1, 6):
            for loco in args.locos:
                m = scenario(shape, order, parts=locos[loco])
                times, stepn = [], []
                for seed in range(args.seeds):
                    t, steps, track, w = trial(m, seed, order, args.cap)
                    times.append(t if t is not None else -1)
                    stepn.append(steps)
                ok = [t for t in times if t >= 0]
                row = {'runs': len(times), 'done': len(ok), 'times': times, 'steps': stepn}
                if ok:
                    row.update(median=float(np.median(ok)), p10=float(np.percentile(ok, 10)),
                               p90=float(np.percentile(ok, 90)), best=min(ok), worst=max(ok))
                for n in (250, 500, 1000, 2000):
                    row[f'within_{n}'] = sum(1 for t in ok if t <= n) / len(times)
                key = f'{shape} order {order} {loco}'
                out[key] = row
                print(f"{key:40s} done {len(ok):4d}/{len(times)} median {row.get('median', '-')!s:>7} "
                      f"p90 {row.get('p90', '-')!s:>7} within 500 {row['within_500']:.2f} 1000 {row['within_1000']:.2f}",
                      flush=True)
    save_json(args.out, {'cap': args.cap, 'extra_draws': EXTRA_DRAWS, 'start': START, 'door': DOOR,
                         'goal_x': GOAL_X, 'results': out})


# ----------------------------------------------------------------------------------------------------------------
# stuck: single robots on the real map, where they spend their time

def passable_start(m, x, y, limit):
    for cx, cy in ((x, y), (x + 1, y), (x, y - 1), (x + 1, y - 1)):
        v = m[P.cell_address(cx, cy)]
        if (v & 0x1F) >= limit or v & 0xC0:
            return False
    for cx in range(x - 2, x + 3):
        for cy in range(y - 1, y + 2):
            if 0 <= cy < 16 and 0 <= cx < 512 and m[P.cell_address(cx, cy)] & 0x40:
                return False
    return True


def cmd_stuck(args):
    rng = np.random.default_rng(args.rng)
    limits = {'bipod': 0x08, 'tracks': 0x0C, 'anti-grav': 0x0F}
    parts = {'bipod': BIPOD | CANNON, 'tracks': TRACKS | CANNON, 'anti-grav': ANTIGRAV | CANNON}
    base = empty_world(args.frame)
    # every factory neutral, as at a new game: order 6 goes for the nearest one nobody of the side is after
    for i in range(24):
        a = P.FACTORIES + 5 * i + 3
        base[a] &= 0x07
    occupancy = {k: np.zeros((16, 512)) for k in args.locos}
    arrived = {k: [] for k in args.locos}
    final = {k: [] for k in args.locos}
    for loco in args.locos:
        for run_no in range(args.runs):
            while True:
                x, y = int(rng.integers(14, 502)), int(rng.integers(1, 16))   # between the posts at 12-13 and 503-504
                if passable_start(base, x, y, limits[loco]):
                    break
            m = bytearray(base)
            add_robot(m, 0, x, y, parts=parts[loco], order=6, facing=P.RIGHT)
            seed_rng(m, run_no + 1000 * args.rng)
            w = P.World(bytes(m), log=False)
            goal = {}

            def at_door(w):
                rx, ry = robot(w)
                occupancy[loco][ry, rx] += 1
                t = w.m[P.ROBOTS + 0x0E]
                if t < 24:
                    a = P.FACTORIES + 5 * t
                    goal['door'] = (w.m[a] | w.m[a + 1] << 8, w.m[a + 2])
                    return (rx, ry) == goal['door']
                return False
            t = run(w, args.cap, at_door)
            arrived[loco].append(t if t is not None else -1)
            final[loco].append((x, y) + robot(w) + goal.get('door', (-1, -1)))
        ok = [t for t in arrived[loco] if t >= 0]
        print(f'{loco}: {len(ok)}/{args.runs} reached their door within {args.cap} turns; median {np.median(ok) if ok else "-"}',
              flush=True)
    np.savez_compressed(args.out, **{f'occ_{k}': v for k, v in occupancy.items()},
                        **{f'arrived_{k}': np.array(v) for k, v in arrived.items()},
                        **{f'final_{k}': np.array(v) for k, v in final.items()},
                        map=np.frombuffer(bytes(base[P.MAP:P.MAP + 0x2000]), dtype=np.uint8).reshape(16, 512),
                        points=np.frombuffer(bytes(base[P.WARBASES:P.WARBASES + 140]), dtype=np.uint8),
                        meta=np.array({'cap': args.cap, 'runs': args.runs, 'frame': args.frame}, dtype=object))


# ----------------------------------------------------------------------------------------------------------------
# deep: robots of work/deep that stood or paced for long with an order that moves them

def cmd_deep(args):
    d = np.load(DEEP10, allow_pickle=True)
    frames, mems = d['frames'], d['mems']
    base = 0x4000
    out = []
    for slot in range(48):
        r = P.ROBOTS - base + 16 * slot
        live = mems[:, r + 1] != 0
        xs = mems[:, r + 2].astype(int) | mems[:, r + 3].astype(int) << 8
        ys = mems[:, r + 4].astype(int)
        orders = mems[:, r + 0x0B].astype(int)
        targets = mems[:, r + 0x0E].astype(int)
        i = 0
        n = len(frames)
        while i < n:
            if not live[i] or orders[i] in (0, 1, 2):
                i += 1
                continue
            j = i
            # a stretch with the same order and target, the robot inside a box of args.box columns
            while (j + 1 < n and live[j + 1] and orders[j + 1] == orders[i] and targets[j + 1] == targets[i]
                   and max(xs[i:j + 2]) - min(xs[i:j + 2]) <= args.box):
                j += 1
            span = frames[j] - frames[i]
            if span >= args.frames:
                t = targets[i]
                door = None
                if orders[i] in (6, 7, 4) and t < 24:
                    a = P.FACTORIES - base + 5 * t
                    door = (int(mems[i][a]) | int(mems[i][a + 1]) << 8, int(mems[i][a + 2]))
                elif orders[i] in (5, 8) and t < 4:
                    a = P.WARBASES - base + 5 * t
                    door = (int(mems[i][a]) | int(mems[i][a + 1]) << 8, int(mems[i][a + 2]))
                on_door = door is not None and (xs[i], ys[i]) == door and (xs[j], ys[j]) == door
                parts = int(mems[i][r + 7])
                loco = 'bipod' if parts & 1 else 'tracks' if parts & 2 else 'anti-grav'
                out.append({'slot': slot, 'from': int(frames[i]), 'to': int(frames[j]), 'order': int(orders[i]),
                            'target': int(t), 'door': door, 'on_door': bool(on_door), 'loco': loco,
                            'xmin': int(min(xs[i:j + 1])), 'xmax': int(max(xs[i:j + 1])),
                            'ymin': int(min(ys[i:j + 1])), 'ymax': int(max(ys[i:j + 1]))})
            i = j + 1
    for e in out:
        print(e)
    save_json(args.out, out)


# ----------------------------------------------------------------------------------------------------------------
# bug: the first decision after a new building target (10.12, SteerByOrder `$B2B8`)

NUCLEAR = 0x40


def first_decision(m, slot, target, seed):
    """robot @p slot decides once with +$0E = @p target (`$FF`: no target yet, so FindTargetBuilding runs)"""
    m = bytearray(m)
    r = P.ROBOTS + 16 * slot
    m[r + 5], m[r + 6], m[r + 0x0E], m[r + 0x0F] = 0, 0, target, 1
    seed_rng(m, seed)
    w = P.World(bytes(m))
    try:
        w.world_turn()
    except P.Unmodelled as e:
        return {'rule': 'blast' if 'nuclear' in str(e) else str(e)}
    e = w.log[0]
    return {k: e.get(k) for k in ('rule', 'wanted', 'course', 'course_len', 'aim', 'new_target', 'past_table', 'lean')}


def cmd_bug(args):
    """for each start cell: the wanted directions and the course of the first decision with a new target (the bug)
    and of the same decision with the target already known (the intended aim)"""
    out = []
    for order, owner, table, door in ((4, 0x20, P.FACTORIES, (311, 7)), (6, 0x00, P.FACTORIES, (311, 7)),
                                      (7, 0x20, P.FACTORIES, (62, 10)), (8, 0x20, P.WARBASES, (369, 8))):
        base = empty_world()
        flatten(base, 14, 502)
        index = 2
        only_target(base, index, *door, owner=owner, table=table)
        rows = []
        for x in range(16, 501, args.step):
            for y in range(1, 16):
                m = bytearray(base)
                parts = BIPOD | CANNON | (NUCLEAR if order in (4, 5) else 0)
                add_robot(m, 0, x, y, parts=parts, order=order, facing=P.UP)
                bugged, right = [], []
                for seed in range(args.seeds):
                    bugged.append(first_decision(m, 0, 0xFF, seed))
                    right.append(first_decision(m, 0, index, seed))
                rows.append({'x': x, 'y': y, 'bug': bugged, 'intended': right})
        summary = collections.Counter()

        def effect(row, d):
            """what the first course does: toward / away from the door's approach cell, or across"""
            if d['rule'] == 'blast':
                return 'blast'
            if d['rule'] == 'arrived':
                return 'stand (arrived)'
            c = d.get('course') or 0
            if not c:
                return 'stand'
            ty = door[1] + 3 if row['x'] != door[0] else door[1]
            dx, dy = {P.RIGHT: (1, 0), P.LEFT: (-1, 0), P.DOWN: (0, 1), P.UP: (0, -1)}[c]
            before = abs(row['x'] - door[0]) + abs(row['y'] - ty)
            after = abs(row['x'] + dx - door[0]) + abs(row['y'] + dy - ty)
            return 'toward' if after < before else 'away' if after > before else 'across'
        for row in rows:
            region = ('x<256 rows 1-8' if row['y'] <= 8 else 'x<256 rows 9-15') if row['x'] < 256 else 'x>=256'
            for kind, decisions in (('bug', row['bug']), ('intended', row['intended'])):
                for d in decisions:
                    summary[(region, kind, effect(row, d))] += 1
        print(f'order {order}, door {door}:')
        for region in ('x<256 rows 1-8', 'x<256 rows 9-15', 'x>=256'):
            for kind in ('bug', 'intended'):
                n = sum(v for k, v in summary.items() if k[:2] == (region, kind))
                parts = ', '.join(f'{k[2]} {v / n:.2f}' for k, v in sorted(summary.items()) if k[:2] == (region, kind))
                print(f'    {region:16s} {kind:9s} {parts}')
        lens = collections.Counter(b['course_len'] for row in rows for b in row['bug'] if b.get('course_len'))
        print('    course lengths', dict(sorted(lens.items())))
        out.append({'order': order, 'door': door, 'table': 'warbases' if table == P.WARBASES else 'factories',
                    'summary': {' / '.join(k): v for k, v in summary.items()}, 'cells': [
                        {'x': r['x'], 'y': r['y'], 'bug': [effect(r, b) for b in r['bug']],
                         'intended': [effect(r, i) for i in r['intended']]} for r in rows]})
    save_json(args.out, out)


# ----------------------------------------------------------------------------------------------------------------
# ship: the ship's cell (map bit 7) in the robot's way, low and high

def put_ship(m, x, y, altitude):
    m[P.cell_address(x, y)] |= 0x80
    m[P.ALTITUDE] = altitude


def cmd_ship(args):
    out = {}
    cases = [('none', None, 0x30), ('in the way, high ($30)', (300, 8), 0x30), ('in the way, low (0)', (300, 8), 0),
             ('in the way, low (0), one row up', (300, 7), 0), ('on the door, low (0)', DOOR, 0),
             ('on the door, high ($30)', DOOR, 0x30), ('at 10, over a bipod (top 11)', (300, 8), 10),
             ('at 12, over a bipod (top 11)', (300, 8), 12)]
    for name, cell, alt in cases:
        for order in (1, 6):
            m = scenario('open', order)
            if cell:
                put_ship(m, *cell, alt)
            times = []
            for seed in range(args.seeds):
                t, steps, track, w = trial(m, seed, order, args.cap)
                times.append(t if t is not None else -1)
            ok = [t for t in times if t >= 0]
            row = {'runs': len(times), 'done': len(ok), 'times': times}
            if ok:
                row.update(median=float(np.median(ok)), p90=float(np.percentile(ok, 90)))
            key = f'{name}, order {order}'
            out[key] = row
            print(f"{key:48s} done {len(ok):4d}/{len(times)} median {row.get('median', '-')!s:>7} "
                  f"p90 {row.get('p90', '-')!s:>7}", flush=True)
    save_json(args.out, {'cap': args.cap, 'start': START, 'door': DOOR, 'results': out})


# ----------------------------------------------------------------------------------------------------------------
# door: the approach to a door, from many starts on an open field

def cmd_door(args):
    """order 6 to a door at (318, 8) on an open field: the row the robot walks on while the columns differ"""
    rows_far = collections.Counter()
    rows_near = collections.Counter()
    last = collections.Counter()
    times = []
    rng = np.random.default_rng(1)
    base = empty_world()
    flatten(base, X0 - 60, X0 + 100)
    only_target(base, 4, *DOOR)
    for run_no in range(args.runs):
        m = bytearray(base)
        x, y = int(rng.integers(X0 - 50, 300)), int(rng.integers(1, 16))
        add_robot(m, 0, x, y, order=6)
        t, steps, track, w = trial(m, run_no, 6, args.cap)
        times.append(t if t is not None else -1)
        for (tx, ty), (ux, uy) in zip(track, track[1:]):
            if (tx, ty) == (ux, uy):
                continue
            dx = abs(DOOR[0] - ux)
            if dx >= 8:
                rows_far[uy] += 1
            elif dx:
                rows_near[uy] += 1
        # the cells walked in the last 6 moves
        moves = [b for a, b in zip(track, track[1:]) if a != b]
        for c in moves[-6:]:
            last[(c[0] - DOOR[0], c[1] - DOOR[1])] += 1
    ok = [t for t in times if t >= 0]
    print(f'{len(ok)}/{len(times)} on the door within {args.cap} turns, median {np.median(ok)}')
    print('rows walked 8+ columns away:', dict(sorted(rows_far.items())))
    print('rows walked 1-7 columns away:', dict(sorted(rows_near.items())))
    print('the last 6 cells, relative to the door:', last.most_common(12))
    save_json(args.out, {'door': DOOR, 'times': times, 'rows_far': rows_far, 'rows_near': rows_near,
                         'last': [[k[0], k[1], v] for k, v in last.items()]})


# ----------------------------------------------------------------------------------------------------------------
# main

def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='command', required=True)
    o = sub.add_parser('odds')
    o.add_argument('--states', type=int, default=100000)
    o.add_argument('--out')
    s = sub.add_parser('shapes')
    s.add_argument('--seeds', type=int, default=200)
    s.add_argument('--cap', type=int, default=3000)
    s.add_argument('--shapes', nargs='*', default=list(SHAPES))
    s.add_argument('--locos', nargs='*', default=['bipod'])
    s.add_argument('--out')
    k = sub.add_parser('stuck')
    k.add_argument('--runs', type=int, default=300)
    k.add_argument('--cap', type=int, default=2000)
    k.add_argument('--frame', type=int, default=3000)
    k.add_argument('--rng', type=int, default=1)
    k.add_argument('--locos', nargs='*', default=['bipod', 'tracks', 'anti-grav'])
    k.add_argument('--out', required=True)
    e = sub.add_parser('deep')
    e.add_argument('--box', type=int, default=12, help='at most this many columns apart')
    e.add_argument('--frames', type=int, default=6000, help='for at least this many frames')
    e.add_argument('--out')
    b = sub.add_parser('bug')
    b.add_argument('--step', type=int, default=8, help='start columns this far apart')
    b.add_argument('--seeds', type=int, default=8)
    b.add_argument('--out')
    h = sub.add_parser('ship')
    h.add_argument('--seeds', type=int, default=200)
    h.add_argument('--cap', type=int, default=3000)
    h.add_argument('--out')
    r = sub.add_parser('door')
    r.add_argument('--runs', type=int, default=300)
    r.add_argument('--cap', type=int, default=3000)
    r.add_argument('--out')
    args = p.parse_args()
    {'odds': cmd_odds, 'shapes': cmd_shapes, 'stuck': cmd_stuck, 'deep': cmd_deep, 'bug': cmd_bug, 'ship': cmd_ship,
     'door': cmd_door}[args.command](args)


if __name__ == '__main__':
    main()
