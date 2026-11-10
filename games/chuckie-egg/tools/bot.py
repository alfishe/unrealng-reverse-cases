#!/usr/bin/env python3
"""The Chuckie Egg play bot: finds key sequences that collect the eggs of each level by a search on the emulator,
then replays them with the TTD recording on.

    python3 tools/bot.py search --start S.szx --menu tests/inputs/menu-1p.txt --levels 2 --out work/stage1/bot/b1
    python3 tools/bot.py record --start S.szx --inputs tests/inputs/b1.txt --work work/stage1/b1 [--port-base 36200]

The search is a weighted best-first search over emulator states (tools/lab.py, one muted instance): a node is a
state reached from the start snapshot by a list of (keys, frames) segments; its children hold each of twelve key
sets (right, left, up, down, jump, jump right, jump left, none, and right or left with up or down: the game grabs a
ladder only where x AND 7 = 0, `$9E98`, so the up or down key must already be held as Harry walks past) for STEP
frames. The closed set is Harry's (x / KX, y / KY, direction). A child dies when the program
leaves the play loop for the ROM's BEEPER (the death tune, `$03B5`) or the lives of player 1 (`$6EF0`) drop; it
wins when the eggs left (`$6EE6`) drop. The heuristic is the pixel distance from Harry (`$72D8` x, `$72D9` y) to
the nearest egg (cell 3) of the live map (`$61A8`, 32 x 21 cells, row 0 at the bottom). Keys are key type 1
(2 up, W down, 9 left, 0 right, M jump), the game's default.

The game's records it reads (WALKTHROUGH 6.0): `$6EE6` eggs left of the current player, `$6EEB` its level (0 the
first), `$6EF0` the lives of player 1, `$72D8` / `$72D9` Harry's x / y (y grows upwards), `$61A8` the live map.

The keys found are written as an mm_session input script (frames from the start snapshot, the menu's lines first).
`record` plays a script from the start snapshot with the same segments, the TTD recording on from the snapshot,
builds L1 (WORK/l1.json), dumps WORK/session.ttd and saves screens (WORK/screens/FRAME.png) every SHOT frames.
"""
import argparse
import heapq
import itertools
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, mm_session  # noqa: E402

EGGS, LEVEL, LIVES1, HARRY, MAP = 0x6EE6, 0x6EEB, 0x6EF0, 0x72D8, 0x61A8
BLOCK = 0x6EE6  # one read: $6EE6-$72DF
ACTIONS = [('R', ['0']), ('L', ['9']), ('U', ['2']), ('D', ['W']), ('J', ['M']), ('RJ', ['0', 'M']),
           ('LJ', ['9', 'M']), ('-', []),
           # up or down held while walking: the game grabs a ladder only where x AND 7 = 0 ($9E98), on the way
           ('RU', ['0', '2']), ('LU', ['9', '2']), ('RD', ['0', 'W']), ('LD', ['9', 'W'])]
SHORT = []  # (name, keys) held SHORT_STEP frames; --short adds a 2-frame step left and right (a jump's take-off)


class Game:
    def __init__(self, lab):
        self.lab = lab

    def state(self):
        b = self.lab.read(BLOCK, HARRY + 8 - BLOCK)
        pc = self.lab.regs()['special']['pc']
        x, y = b[HARRY - BLOCK], b[HARRY + 1 - BLOCK]
        return dict(eggs=b[0], level=b[LEVEL - BLOCK], lives=b[LIVES1 - BLOCK], x=x, y=y, pc=pc,
                    d=b[HARRY + 3 - BLOCK])

    def eggs(self):
        m = self.lab.read(MAP, 672)
        return [(i % 32, i // 32) for i, v in enumerate(m) if v == 3]

    def lift_cols(self):
        """The columns of the level's lifts: `$7350` is `$FF` on a level without them; else the two lifts' screen
        addresses at `$734E` and `$7352` (the same column, half a screen apart) give the column (`$A014-$A072`)"""
        b = self.lab.read(0x734E, 6)
        if b[2] == 0xFF:
            return set()
        col = b[0] & 0x1F
        return {col, col + 1}


SOLID = 5
SHORT_STEP = 2
DEATH_COST = 400  # frames a death counts for in the search (allow_death)
KX, KY = 3, 3  # the closed set's cell in pixels (--kx, --ky)


class Graph:
    """Cells Harry's middle (x + 8, y - 8) can be in, from the live map: walk along a row where the cell below is a
    platform or a ladder, climb a ladder's cells, fall where nothing holds, jump up to four cells across and one up.
    Distances in cells from every egg (a breadth-first search over the reversed edges): the search's heuristic"""

    def __init__(self, cells, lifts=()):
        self.m = cells
        self.lifts = set(lifts)

    def at(self, c, r):
        if c < 0 or c > 31:
            return SOLID
        if r < 0:
            return SOLID
        if r > 20:
            return 0
        return self.m[r * 32 + c]

    def solid(self, c, r):
        v = self.at(c, r)
        return v >= SOLID

    def ladder(self, c, r):
        return self.at(c, r) in (1, 2)

    def holds(self, c, r):
        return self.solid(c, r - 1) or self.ladder(c, r - 1) or self.ladder(c, r)

    def edges(self, c, r):
        out = []
        if c in self.lifts:  # a lift carries Harry up; he walks or jumps off sideways
            if r < 20 and not self.solid(c, r + 1):
                out.append(((c, r + 1), 2))
            for d in (-1, 1):
                for k in range(1, 4):
                    t = (c + d * k, r)
                    if 0 <= t[0] < 32 and not self.solid(*t):
                        out.append((t, k + 1))
            return out
        if not self.holds(c, r):
            return [((c, r - 1), 1)] if r > 0 else []
        for d in (-1, 1):
            if not self.solid(c + d, r):
                out.append(((c + d, r), 1))
        if self.ladder(c, r + 1) or self.ladder(c, r):
            if not self.solid(c, r + 1):
                out.append(((c, r + 1), 1))
        if self.ladder(c, r - 1) and r > 0:
            out.append(((c, r - 1), 1))
        if self.solid(c, r - 1):
            for d in (-1, 1):
                for k in range(2, 5):
                    for up in (0, 1):
                        t = (c + d * k, r + up)
                        if 0 <= t[0] < 32 and not self.solid(*t):
                            out.append((t, k + 1))
        return out

    def distances(self, eggs):
        import collections
        rev = collections.defaultdict(list)
        for r in range(21):
            for c in range(32):
                if not self.solid(c, r):
                    for t, w in self.edges(c, r):
                        rev[t].append(((c, r), w))
        dist = {e: 0 for e in eggs}
        heap = [(0, e) for e in eggs]
        while heap:
            d, n = heapq.heappop(heap)
            if d > dist.get(n, 1e9):
                continue
            for m, w in rev[n]:
                if d + w < dist.get(m, 1e9):
                    dist[m] = d + w
                    heapq.heappush(heap, (d + w, m))
        return dist


def heuristic(st, eggs, dist=None):
    if not eggs:
        return 0
    if dist is not None:
        cell = ((st['x'] + 8) >> 3, (st['y'] - 8) >> 3)
        if cell in dist:
            return dist[cell] * 8 / 1.2
    hx, hy = st['x'] + 8, st['y'] - 8
    best = 1e9
    for c, r in eggs:
        dx, dy = abs(c * 8 + 4 - hx), abs(r * 8 + 4 - hy)
        best = min(best, dx + 2.0 * dy)
    return best / 1.2


def run_segments(lab, segments):
    for keys, frames in segments:
        lab.keys(keys)
        lab.run(frames)
    lab.keys([])


def menu_segments(path):
    """An mm_session script as (keys, frames) segments"""
    events = mm_session.parse_script(path)
    segs, last, keys = [], 0, []
    for frame, k in events:
        if frame > last:
            segs.append((keys, frame - last))
            last = frame
        if k is None:
            break
        keys = k
    return segs


def write_script(path, segments, header):
    with open(path, 'w') as f:
        for line in header:
            f.write(f'# {line}\n')
        frame, held = 0, None
        for keys, frames in segments:
            if keys != held:
                f.write(f"{frame} {' '.join(keys) if keys else '-'}\n")
                held = keys
            frame += frames
        f.write(f'{frame} -\n{frame + 1} END\n')


def in_play(st):
    return 0x9858 <= st['pc'] < 0xA000 or 0x911E <= st['pc'] < 0x9858


def survives(lab, game, tmp, lives, frames=24):
    """From the state now in the machine: does one of a few key sets keep Harry alive for FRAMES frames?"""
    snap = os.path.join(tmp, 'probe.szx')
    lab.save(snap)
    moves = ([], ['0'], ['9'], ['0', '2'], ['9', '2'], ['0', 'W'], ['9', 'W'], ['0', 'M'], ['9', 'M'])
    for first in moves:
        for second in moves:
            lab.load(snap)
            alive = True
            for keys in (first, second):
                lab.keys(keys)
                lab.run(frames)
                st = game.state()
                if st['pc'] < 0x4000 or st['lives'] < lives:
                    alive = False
                    break
            lab.keys([])
            if alive:
                lab.load(snap)
                return True
    lab.load(snap)
    return False


def respawn(lab, game, lives):
    """After a death: idle until the next life is in play; returns the frames waited"""
    waited = 0
    while waited < 1500:
        lab.run(10)
        waited += 10
        st = game.state()
        if st['lives'] < lives and 0x9858 <= st['pc'] <= 0x99F0:
            return waited
    return None


TARGET = None  # --target C,R: search for Harry standing in that cell instead of an egg (to set up a jump by hand)


def at_target(st):
    c, r = TARGET
    return ((st['x'] + 8) >> 3) == c and st['y'] == 8 * (r - 1) + 23


def search_egg(lab, game, base_snap, base_segs, tmp, step, limit, log, wait_bucket, allow_death=False, banned=()):
    """Best-first from the state BASE_SNAP (reached by BASE_SEGS); returns the segments that take one egg. With
    ALLOW_DEATH a death is a move too (it costs DEATH_COST frames): the last resort when no egg is reachable alive"""
    lab.load(base_snap)
    st0 = game.state()
    eggs = [TARGET] if TARGET else game.eggs()
    dist = Graph(lab.read(MAP, 672), game.lift_cols()).distances(eggs)
    tick = itertools.count()
    start = dict(segs=[], snap=base_snap, st=st0, g=0, lives=st0['lives'])
    heap = [(heuristic(st0, eggs, dist), next(tick), start)]
    seen = set()
    expanded = 0
    best = (1e9, 0, 0, 0)
    while heap and expanded < limit:
        _, _, node = heapq.heappop(heap)
        key = (node['st']['x'] // KX, node['st']['y'] // KY, node['st']['d'], node['lives'], node['g'] // wait_bucket)
        if key in seen:
            continue
        seen.add(key)
        expanded += 1
        hn = heuristic(node['st'], eggs, dist)
        best = min(best, (hn, node['st']['x'], node['st']['y'], node['g']))
        if expanded % 250 == 0:
            log(f"    {expanded} expanded, open {len(heap)}, best (h, x, y, g) {best}")
        if node['snap'] is None:  # materialise: the parent's snapshot and the child's segment
            lab.load(node['parent_snap'])
            run_segments(lab, node['segs'][node['nseg']:])
            node['snap'] = os.path.join(tmp, f'n{next(tick)}.szx')
            lab.save(node['snap'])
        for name, keys, frames in [(n, k, step) for n, k in ACTIONS] + [(n, k, SHORT_STEP) for n, k in SHORT]:
            lab.load(node['snap'])
            lab.keys(keys)
            lab.run(frames)
            lab.keys([])
            st = game.state()
            segs = node['segs'] + [(keys, frames)]
            g = node['g'] + frames
            level_done = st['lives'] >= node['lives'] and (st['eggs'] == 0 or st['level'] != st0['level'])
            if not level_done and (st['pc'] < 0x4000 or st['lives'] < node['lives']):
                # the last egg ends the level with a tune in the ROM: not a death
                if not allow_death:
                    continue
                waited = respawn(lab, game, node['lives'])
                if waited is None:
                    continue
                st = game.state()
                segs = segs + [([], waited)]
                g += waited + DEATH_COST
            child = dict(segs=segs, snap=None, parent_snap=node['snap'], st=st, g=g, lives=st['lives'],
                         nseg=len(node['segs']))
            if TARGET and at_target(st) and st['lives'] >= node['lives']:
                log(f"  target {TARGET} after {expanded} expansions, {child['g']} frames: {st}")
                return child['segs']
            if not TARGET and (st['eggs'] < st0['eggs'] or st['level'] != st0['level']):
                if (st['x'] // KX, st['y'] // KY, st['eggs']) in banned:
                    continue
                if st['eggs'] > 0 and st['level'] == st0['level'] and not survives(lab, game, tmp, st['lives']):
                    log(f"  egg after {expanded} expansions rejected: no way out alive")
                    continue
                log(f"  egg after {expanded} expansions, {child['g']} frames, eggs {st['eggs']}, lives {st['lives']}")
                return child['segs']
            ckey = (st['x'] // KX, st['y'] // KY, st['d'], child['lives'], child['g'] // wait_bucket)
            if ckey in seen:
                continue
            h = heuristic(st, eggs, dist)
            heapq.heappush(heap, (child['g'] * 0.25 + h, next(tick), child))
    log(f'  no egg within {expanded} expansions')
    return None


def search(args):
    global KX, KY, TARGET
    KX, KY = args.kx, args.ky
    if args.target:
        TARGET = tuple(int(v) for v in args.target.split(','))
    if args.short:
        SHORT[:] = [('r', ['0']), ('l', ['9'])]
    os.makedirs(args.out, exist_ok=True)
    tmp = os.path.join(args.out, 'nodes')
    os.makedirs(tmp, exist_ok=True)
    logf = open(os.path.join(args.out, 'search.log'), 'a')

    def log(text):
        line = f'{time.strftime("%H:%M:%S")} {text}'
        print(line, flush=True)
        logf.write(line + '\n')
        logf.flush()

    lab = Lab(args.port_base)
    game = Game(lab)
    try:
        lab.load(args.start)
        segs = menu_segments(args.menu)
        if segs and segs[-1] == ([], 1):  # a bot script's END frame: resume where its search stopped
            segs.pop()
        run_segments(lab, segs)
        for poke in args.poke:
            addr, value = poke.split(',')
            lab.write(int(addr, 0), bytes([int(value, 0)]))
        snap = os.path.join(args.out, 'base.szx')
        lab.save(snap)
        st = game.state()
        log(f'start: {st}')
        levels_done = 0
        history = []  # (snap, segs) before each egg of the current level: the search backs up when stuck
        banned = set()  # end states of eggs that led nowhere
        backups = 0
        while levels_done < args.levels:
            found = search_egg(lab, game, snap, segs, tmp, args.step, args.limit, log, args.wait_bucket,
                               banned=banned)
            if found is None and history and backups < args.backups:
                backups += 1
                banned.add(end_key(game, lab, snap))
                snap, segs = history.pop()
                log(f'  back one egg (backup {backups}), banned {len(banned)}')
                continue
            if found is None and args.allow_death:
                log('  again, deaths allowed')
                found = search_egg(lab, game, snap, segs, tmp, args.step, args.limit, log, args.wait_bucket, True,
                                   banned=banned)
            if found is None:
                break
            history.append((snap, segs))
            lab.load(snap)
            run_segments(lab, found)
            segs = segs + found
            snap = os.path.join(args.out, f'at{sum(f for _, f in segs)}.szx')
            lab.save(snap)
            st = game.state()
            log(f"frame {sum(f for _, f in segs)}: {st}")
            if TARGET:
                break
            if st['eggs'] == 0 or st['level'] != game_level(args, levels_done):
                # the level is done: let the bonus count and the next level start
                for _ in range(200):
                    lab.run(10)
                    segs.append(([], 10))
                    s2 = game.state()
                    if s2['eggs'] > 0 and 0x9858 <= s2['pc'] < 0xA000:
                        break
                lab.run(30)
                segs.append(([], 30))
                snap = os.path.join(args.out, f'at{sum(f for _, f in segs)}.szx')
                lab.save(snap)
                levels_done += 1
                history, banned, backups = [], set(), 0
                log(f'level done ({levels_done}): {game.state()}')
            write_script(args.script, segs, [f'bot.py search --menu {args.menu} from {args.start}',
                                             f'pokes: {args.poke or "none"}'])
        write_script(args.script, segs, [f'bot.py search --menu {args.menu} from {args.start}',
                                         f'pokes: {args.poke or "none"}'])
        log(f'script {args.script}: {sum(f for _, f in segs)} frames')
    finally:
        lab.close()


def end_key(game, lab, snap):
    lab.load(snap)
    st = game.state()
    return (st['x'] // KX, st['y'] // KY, st['eggs'])


def game_level(args, done):
    return args.first_level + done


def record(args):
    os.makedirs(args.work, exist_ok=True)
    lab = Lab(args.port_base)
    shots = os.path.join(args.work, 'screens')
    os.makedirs(shots, exist_ok=True)
    try:
        lab.load(args.start)
        lab.session_json(args.work)
        lab.start_recording()
        segs = menu_segments(args.inputs)
        frame = 0
        pokes = {}
        for p in args.poke:
            f, a, v = p.split(',')
            pokes.setdefault(int(f), []).append((int(a, 0), int(v, 0)))
        log = []
        for keys, frames in segs:
            lab.keys(keys)
            while frames > 0:
                n = min(frames, args.shot - frame % args.shot)
                lab.run(n)
                frame += n
                frames -= n
                if frame in pokes:
                    for a, v in pokes[frame]:
                        lab.write(a, bytes([v]))
                if frame % args.shot == 0:
                    lab.shot(os.path.join(shots, f'{frame:06d}.png'), 1)
                    st = Game(lab).state()
                    log.append(dict(frame=frame, **st))
        lab.keys([])
        with open(os.path.join(args.work, 'states.json'), 'w') as f:
            json.dump(log, f)
        lab.save(os.path.join(args.work, 'end.szx'))
        built = lab.s.call('analysis', {'action': 'build', 'path': os.path.join(args.work, 'l1.json'),
                                        'wait': 30000})
        state = lab.s.call('analysis', {'action': 'status'}).text
        while ': running' in state:
            time.sleep(5)
            state = lab.s.call('analysis', {'action': 'status'}).text
        print(state.splitlines()[-1] if state else built.text)
        r = lab.s.call('time_travel', {'action': 'dump', 'path': os.path.join(args.work, 'session.ttd')}, ok=False)
        print((r.text or '').splitlines()[:1])
        print(f'recorded {frame} frames')
    finally:
        if not args.keep:
            lab.close()


def on_term(*_):
    raise KeyboardInterrupt  # so the finally clauses stop the instance


def main():
    import signal
    signal.signal(signal.SIGTERM, on_term)
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('search')
    s.add_argument('--start', required=True)
    s.add_argument('--menu', required=True)
    s.add_argument('--levels', type=int, default=1)
    s.add_argument('--first-level', type=int, default=0)
    s.add_argument('--out', required=True)
    s.add_argument('--script', required=True)
    s.add_argument('--step', type=int, default=8)
    s.add_argument('--limit', type=int, default=1500)
    s.add_argument('--wait-bucket', type=int, default=64)
    s.add_argument('--allow-death', action='store_true', help='when no egg is reachable alive, search with deaths')
    s.add_argument('--backups', type=int, default=6, help='times a level may back up one egg when stuck')
    s.add_argument('--kx', type=int, default=3, help='closed-set cell width in pixels')
    s.add_argument('--ky', type=int, default=3, help='closed-set cell height in pixels')
    s.add_argument('--poke', action='append', default=[], help='ADDR,VALUE poked after the menu (a clone)')
    s.add_argument('--target', help='C,R: stop when Harry stands in this map cell (one search, no egg)')
    s.add_argument('--short', action='store_true', help='also try 2-frame steps left and right')
    s.add_argument('--port-base', type=int, default=36200)
    r = sub.add_parser('record')
    r.add_argument('--start', required=True)
    r.add_argument('--inputs', required=True)
    r.add_argument('--work', required=True)
    r.add_argument('--shot', type=int, default=50)
    r.add_argument('--poke', action='append', default=[], help='FRAME,ADDR,VALUE poked at that frame')
    r.add_argument('--keep', action='store_true')
    r.add_argument('--port-base', type=int, default=36200)
    args = p.parse_args()
    search(args) if args.cmd == 'search' else record(args)


if __name__ == '__main__':
    main()
