#!/usr/bin/env python3
"""A bot that plays Video Pool with real keys from the entry snapshot, searching each shot on saved states, then
replays the chosen keys from the entry with the recording on, so the recording holds only real input.

    python3 tools/shot_bot.py --plan PLAN --work work/runs/NAME [--snapshot work/snaps/entry.z80] [--port-base 34200]

PLAN is a text file, one step a line (# comments):

    key K HOLD GAP        hold key K (mm_session names: A-Z 0-9 SPACE ENTER CS SS, Kempston KF KL KR KU KD;
                          K1+K2 holds both) for HOLD frames, then GAP frames with no key
    ready                 run until the game waits for a shot (balls still, fire grows the power bar)
    shot GOAL [N]         search a shot (a cursor key M or SS held 0-190 frames, then SPACE held 8-62 frames) that
                          meets GOAL, play it, wait until the balls stop; N times (default 1), each after `ready`
    shots GOAL UNTIL      shots of GOAL until UNTIL (with `frame`: after 150 tries without a pot, a shot that pots
                          nothing moves the balls and the search goes on): `frame` (six balls down: a new frame is racked, `$8357`), `over` (the lives run out)
    run N                 N frames with no key
    screen NAME, snap F   exploration aids: the screen as WORK/screen-NAME.png, the state as WORK/F

GOALS: pot (an object ball potted, the cue ball kept, no life lost), miss (a foul: no ball touched), cue (the cue
ball potted), out (a ball touched, none potted, a life lost: the shots ran out), last (a foul with no life left: the
game ends, `$9F4E` goes from 0 to `$FF`), nopot (no ball potted, no life lost: burns a shot), wrong (a life lost while an object ball went
down: wrong order or wrong pocket), any (the first shot tried).

Writes WORK/inputs.txt (the keys as an input script from the snapshot, mm_session format), WORK/bot.log (each shot:
frame, cursor, power, balls, lives) and keeps the instance with the recording: WORK/session.json, so
`re_session.py build / stages / stop --work WORK` work on it. The game's records it reads: tools/lab.py.
"""
import argparse
import math
import os
import signal
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab  # noqa: E402

SETTLE = 250     # frames after the balls stop before the outcome is read: a foul takes a life about 200 frames later
SETTLE_MAX = 3000  # more while the game is not back at the aim (several pots show their scores one by one)
TASKS = 0x91DF   # the scheduler's 25 slots of 4 bytes (routine, period, countdown)
POCKETS = [(7, 55), (128, 55), (248, 55), (7, 176), (128, 176), (248, 176)]  # the corners and middles of the
                 # balls' range (x 7..248, y 55..176: the clamps `$0700`-`$F800`, `$3700`-`$B000` of `$8701`)
RADIUS = 7       # a ball sprite's disc is 14 pixels across (tools/fig_sprites.py)
COARSE = 8       # the best held-key positions for a pot, each refined by taps
TAPS = 4         # one-frame presses of M or SS after the hold, each about a pixel
AIMED = 12       # aims tried first for a pot (three holds each), best first
LIMIT = 150      # tries for a pot in `shots pot frame` before a positional shot
LIVES = 0x9F4E   # the current player's lives (3 at the start; one less after a foul, c1 and the lab runs)


class Bot:
    def __init__(self, lab, work):
        self.lab, self.work = lab, work
        self.events = []        # (frame from the snapshot, keys held from then on)
        self.frame = 0          # frames since the snapshot on the main line
        self.state = os.path.join(work, 'state.szx')
        self.trial = os.path.join(work, 'trial.szx')
        self.log = open(os.path.join(work, 'bot.log'), 'w')

    # the main line: every key change is an event
    def hold(self, keys, frames):
        self.lab.keys(keys)
        self.events.append((self.frame, list(keys)))
        self.lab.run(frames)
        self.frame += frames

    def idle(self, frames):
        if self.lab.held:
            self.lab.keys([])
            self.events.append((self.frame, []))
        self.lab.run(frames)
        self.frame += frames

    def aiming(self):
        """The aim's tasks are installed: the cursor move `$8546` is in a task slot (`$91DF`, 25 x 4 bytes)"""
        m = self.lab.read(TASKS, 100)
        return any(m[i] | m[i + 1] << 8 == 0x8546 for i in range(0, 100, 4))

    def settle(self):
        """Runs until the game is back at the aim after a shot (the scores, messages and the life shown), or the game
        ended (the lives below 0), at least SETTLE frames; returns the frames run"""
        n = SETTLE
        self.lab.run(SETTLE)
        while n < SETTLE_MAX and not self.aiming() and self.lives() <= 3:
            self.lab.run(10)
            n += 10
        return n

    def settled(self):
        return all(b['flags'] & 0x50 == 0 for b in self.lab.balls())

    def lives(self):
        return self.lab.read(LIVES, 1)[0]

    def ready(self, limit=6000):
        """Runs until the balls are still, some object ball is on the table, and fire grows the power bar (probed
        on a saved state: SPACE held 6 frames changes the power `$86BF`)"""
        waited = 0
        while waited < limit:
            bs = self.lab.balls()
            if self.settled() and any(b['flags'] & 0x80 for b in bs[1:]) and self.lab.cursor() != (0, 0):
                self.lab.save(self.trial)
                before = self.lab.read(0x86BF, 1)
                self.lab.keys(['SPACE'])
                self.lab.run(6)
                grew = self.lab.read(0x86BF, 1) != before
                self.lab.keys([])
                self.lab.load(self.trial)
                if grew:
                    return True
            self.idle(10)
            waited += 10
        return False

    def aim(self, key, n, taps):
        """The cursor keys of a shot on the lab: @p key held @p n frames, then @p taps = (key, k): k presses of one
        frame with one frame between (the cursor's speed `$86BC` starts at 1 on each press, `$8546`), then one free
        frame; returns the frames it took"""
        lab = self.lab
        if n:
            lab.keys([key]); lab.run(n)
        lab.keys([])
        lab.run(1)
        tkey, k = taps or (None, 0)
        for _ in range(k):
            lab.keys([tkey]); lab.run(1); lab.keys([]); lab.run(1)
        return n + 1 + 2 * k

    def try_shot(self, key, n, hold, goal='any', taps=None):
        """Plays a shot from the current state on the lab; returns the outcome (the state is left after it), or None
        as soon as it cannot meet @p goal (a miss that moved an object ball, a pot that potted nothing)"""
        lab = self.lab
        lives0 = self.lives()
        b0 = lab.balls()
        aimed = self.aim(key, n, taps)
        cursor = lab.cursor()
        lab.keys(['SPACE']); lab.run(hold); lab.keys([])
        power = lab.read(0x86BF, 1)[0]
        cue_lost, moved, t = False, set(), 0
        while t < 3000:
            lab.run(25); t += 25
            bs = lab.balls()
            cue_lost |= not bs[0]['flags'] & 0x80
            moved |= {i for i, (a, b) in enumerate(zip(b0, bs)) if (round(a['x']), round(a['y'])) != (round(b['x']), round(b['y']))}
            if goal in ('miss', 'last') and (moved - {0} or cue_lost):
                return None
            if goal == 'pot' and cue_lost:
                return None
            if t > 100 and all(b['flags'] & 0x50 == 0 for b in bs):
                break
        bs = lab.balls()
        potted = [i for i in range(1, 7) if b0[i]['flags'] & 0x80 and not bs[i]['flags'] & 0x80]
        if goal in ('pot', 'wrong') and not potted or goal == 'nopot' and potted:
            return None
        settle = self.settle()
        bs = lab.balls()
        # the last ball down racks the next frame (`$8357`) within the settle: the balls are back on the table then,
        # so the pots seen when the balls stopped count too
        potted = sorted(set(potted) | {i for i in range(1, 7) if b0[i]['flags'] & 0x80 and not bs[i]['flags'] & 0x80})
        return dict(cursor=cursor, power=power, potted=potted, cue_lost=cue_lost, moved=sorted(moved),
                    lives=(lives0, self.lives()), frames=aimed + hold + t + settle)

    @staticmethod
    def meets(goal, o):
        lost = o['lives'][1] < o['lives'][0]
        if goal == 'any':
            return True
        if goal == 'pot':
            return bool(o['potted']) and not lost and not o['cue_lost']
        if goal == 'miss':
            return lost and o['moved'] == [0] and not o['cue_lost']
        if goal == 'cue':
            return o['cue_lost']
        if goal == 'nopot':
            return not o['potted'] and not lost and not o['cue_lost']
        if goal == 'wrong':
            return lost and bool(o['potted']) and not o['cue_lost']
        if goal == 'out':
            return lost and not o['potted'] and not o['cue_lost'] and o['moved'] != [0]
        if goal == 'last':
            return o['lives'][0] == 0 and o['lives'][1] != 0 and o['moved'] == [0]
        raise SystemExit('unknown goal ' + goal)

    @staticmethod
    def candidates(goal):
        """Strong shots first for a pot, weak ones first for a miss or a shot that pots nothing"""
        holds = list(range(8, 63, 6)) if goal in ('miss', 'nopot', 'last', 'out') else list(range(62, 7, -6))
        for n in range(0, 200, 10):
            for key in ('M', 'SS'):
                if n == 0 and key == 'SS':
                    continue
                for hold in holds:
                    yield key, n, hold, None

    def sweep(self, most=200):
        """Where the cursor gets with M or SS held n frames (n up to @p most), from the saved state"""
        out = []
        for key in ('M', 'SS'):
            self.lab.load(self.state)
            self.lab.keys([key])
            for n in range(1, most + 1):
                self.lab.run(1)
                out.append((key, n, self.lab.cursor()))
            self.lab.keys([])
        self.lab.load(self.state)
        return out

    def aimed(self):
        """Pot candidates by geometry: the cue ball runs at the cursor; a ball goes in a pocket when the cue ball meets
        it at the ghost point (two radii behind it on the pocket's line). The reachable cursor positions (sweep) by
        their angle to the nearest ghost line, best first; the strong holds for each"""
        bs = self.lab.balls()
        cx, cy = bs[0]['x'], bs[0]['y']
        cur0 = self.lab.cursor()
        ghosts = []
        for b in bs[1:]:
            if not b['flags'] & 0x80:
                continue
            for px, py in POCKETS:
                ux, uy = px - b['x'], py - b['y']
                d = math.hypot(ux, uy)
                gx, gy = b['x'] - ux / d * 2 * RADIUS, b['y'] - uy / d * 2 * RADIUS
                vx, vy = gx - cx, gy - cy
                if math.hypot(vx, vy) < 1:
                    continue
                cut = abs(math.degrees(math.atan2(vx * uy - vy * ux, vx * ux + vy * uy)))
                if cut < 70:
                    ghosts.append(math.atan2(vy, vx))
        def err(x, y):
            a = math.atan2(y - cy, x - cx)
            return min((abs((a - g + math.pi) % (2 * math.pi) - math.pi) for g in ghosts), default=9)

        coarse = sorted((err(x, y), key, n) for key, n, (x, y) in [('M', 0, cur0)] + self.sweep())
        fine = []
        for e, key, n in coarse[:COARSE]:
            fine.append((e, key, n, None))
            for tkey in ('M', 'SS'):
                for k in range(1, TAPS + 1):
                    self.lab.load(self.state)
                    self.aim(key, n, (tkey, k))
                    fine.append((err(*self.lab.cursor()), key, n, (tkey, k)))
        self.lab.load(self.state)
        fine.sort(key=lambda f: f[0])
        for e, key, n, taps in fine[:AIMED]:
            for hold in (62, 50, 38):
                yield key, n, hold, taps

    def shot(self, goal, limit=None):
        """Searches, plays and logs a shot that meets @p goal (at most @p limit tries); None when none did"""
        if not self.ready():
            raise SystemExit(f'frame {self.frame}: the game does not wait for a shot')
        self.lab.save(self.state)
        found, tried = None, 0
        first = list(self.aimed()) if goal in ('pot', 'wrong') else []
        for key, n, hold, taps in first + list(self.candidates(goal)):
            if limit and tried >= limit:
                break
            self.lab.load(self.state)
            o = self.try_shot(key, n, hold, goal, taps)
            tried += 1
            if o is not None and self.meets(goal, o):
                found = (key, n, hold, taps, o)
                break
        self.lab.load(self.state)
        if not found:
            print(f'frame {self.frame}: no shot meets {goal} in {tried} tries', file=self.log, flush=True)
            return None
        key, n, hold, taps, o = found
        # the chosen shot on the main line, as events
        if n:
            self.hold([key], n)
        self.idle(1)
        tkey, k = taps or (None, 0)
        for _ in range(k):
            self.hold([tkey], 1)
            self.idle(1)
        self.hold(['SPACE'], hold)
        aimed = n + 1 + 2 * k
        self.idle(o['frames'] - aimed - hold)
        tapped = f' taps {tkey} x{k}' if k else ''
        print(f"frame {self.frame - o['frames']}: {goal}: {key} {n}{tapped} SPACE {hold} cursor {o['cursor']} power "
              f"{o['power']} potted {o['potted']} cue_lost {o['cue_lost']} moved {o['moved']} lives "
              f"{o['lives'][0]}->{o['lives'][1]} ({tried} tries)", file=self.log, flush=True)
        return o

    def script(self, path, note):
        with open(path, 'w') as f:
            f.write(f'# {note}\n')
            for frame, keys in self.events:
                f.write(f"{frame} {' '.join(keys) if keys else '-'}\n")
            f.write(f'{self.frame} END\n')


def plan_steps(path):
    for raw in open(path):
        line = raw.split('#', 1)[0].split()
        if line:
            yield line


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--plan', required=True)
    p.add_argument('--work', required=True)
    p.add_argument('--snapshot', default=os.path.join(HERE, '..', 'work', 'snaps', 'entry.z80'))
    p.add_argument('--port-base', type=int, default=34200)
    p.add_argument('--no-record', action='store_true', help='search only: write the script, no recording')
    args = p.parse_args()
    work = os.path.abspath(args.work)
    os.makedirs(work, exist_ok=True)
    # a SIGTERM (a stopped search) unwinds through `finally`, so the instance is closed with the bot
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))
    lab = Lab(args.port_base)
    ok = False
    try:
        lab.load(args.snapshot)
        bot = Bot(lab, work)
        for step in plan_steps(args.plan):
            print(f'{bot.frame}: {" ".join(step)}', file=bot.log, flush=True)
            if step[0] == 'key':
                bot.hold(step[1].split('+'), int(step[2]))
                bot.idle(int(step[3]))
            elif step[0] == 'screen':     # exploration: the screen now as WORK/screen-NAME.png
                import kitlib
                kitlib.render_screen(lab.read(0x4000, 6912), 0).save(os.path.join(work, f'screen-{step[1]}.png'))
            elif step[0] == 'snap':       # exploration: the state now as a snapshot
                lab.save(os.path.join(work, step[1]))
            elif step[0] == 'run':
                bot.idle(int(step[1]))
            elif step[0] == 'ready':
                bot.ready()
            elif step[0] == 'shot':
                for _ in range(int(step[2]) if len(step) > 2 else 1):
                    bot.shot(step[1])
            elif step[0] == 'shots':
                until, down = step[2], 0
                for _ in range(80):
                    if until == 'over' and bot.lives() == 0:
                        bot.shot('last')
                        break
                    o = bot.shot(step[1], LIMIT if until == 'frame' else None)
                    if o is None and until == 'frame':
                        # no pot from here: a shot that keeps the lives moves the balls, then search again
                        o = bot.shot('nopot', LIMIT) or bot.shot('any')
                    if o is None:
                        break
                    down += len(o['potted'])
                    if until == 'frame' and down >= 6:
                        break
            else:
                raise SystemExit('unknown step ' + step[0])
        script = os.path.join(work, 'inputs.txt')
        bot.script(script, f'shot_bot.py --plan {os.path.relpath(args.plan, os.path.join(HERE, ".."))}: from '
                           f'{os.path.basename(args.snapshot)}')
        bot.log.close()
        main_end = lab.read(0x8A88, 98)
        if args.no_record:
            return
        # the replay: the snapshot again, the recording on, the same keys at the same frames
        lab.load(args.snapshot)
        lab.start_recording()
        at = 0
        for frame, keys in bot.events:
            lab.run(frame - at)
            at = frame
            lab.keys(keys)
        lab.run(bot.frame - at)
        lab.keys([])
        lab.session_json(work)
        same = lab.read(0x8A88, 98) == main_end
        print(f'replay {"matches" if same else "DIFFERS from"} the searched line at the end (the ball records)')
        ok = True
        print(f'{work}: {bot.frame} frames recorded; the instance stays up (re_session.py build/stop --work)')
    finally:
        if not ok:
            lab.close()


if __name__ == '__main__':
    main()
