#!/usr/bin/env python3
"""The physics of Video Pool in Python, instruction for instruction: one tick of PhysicsTask $86C1 on the 98-byte
ball block BallRecords $8A88 (seven records of 14 bytes), with the large pockets (CushionsLarge $8FBB), the standard
game (no variation fouls) and the tables read from the image.

    import physics_model as P
    m = P.Model(image)                      # image: the 64 K view (work/mkgame/original.bin) for the four tables
    balls = P.Balls(block98, friction_turn=0)
    m.tick(balls)                           # one interrupt's PhysicsTask; balls.events lists what happened

    python3 tools/physics_model.py --image work/mkgame/original.bin --samples S.jsonl [--from F]

With --samples (JSON lines {"frame", "hex"} of $8A88-$8B4D: the ball block, FrictionTurn $8B4C and EventCount
$8B4D, read with TTD memory_at) it starts from the first sample whose cue ball moves (or --from), runs ticks and
reports, for every later sample, which tick it equals byte for byte (a frame whose interrupt was lost repeats the
last tick). This is the check that the model is the game's: docs/10-gameplay-logic.md 10.4.

The names follow src/game/game.ann; each method says the routine it mirrors.
"""
import argparse
import json
import sys

CONTACT, TABLE8, FRICTION, RECORDS = 0xDBFA, 0xDCFA, 0xDD3A, 0xDE3A


def s16(v):
    v &= 0xFFFF
    return v - 0x10000 if v & 0x8000 else v


def s8(v):
    v &= 0xFF
    return v - 0x100 if v & 0x80 else v


class Ball:
    """One 14-byte record: x, y 8.8 (+0..+3), vx, vy 8.8 (+4..+7), friction steps (+8, +9), sprite (+10, +11),
    pocket (+12), flags (+13)"""

    def __init__(self, raw):
        r = list(raw)
        self.x = r[0] | r[1] << 8
        self.y = r[2] | r[3] << 8
        self.vx = r[4] | r[5] << 8
        self.vy = r[6] | r[7] << 8
        self.fx, self.fy, self.sx, self.sy, self.pocket, self.flags = r[8:14]

    def raw(self):
        return bytes([self.x & 0xFF, self.x >> 8, self.y & 0xFF, self.y >> 8, self.vx & 0xFF, self.vx >> 8,
                      self.vy & 0xFF, self.vy >> 8, self.fx & 0xFF, self.fy & 0xFF, self.sx, self.sy, self.pocket,
                      self.flags])

    @property
    def px(self):
        return self.x >> 8

    @property
    def py(self):
        return self.y >> 8


class Balls:
    def __init__(self, block, friction_turn=0):
        self.b = [Ball(block[14 * i:14 * i + 14]) for i in range(7)]
        self.friction_turn = friction_turn
        self.event_count = 0
        self.events = []

    def raw(self):
        return b''.join(b.raw() for b in self.b)


class Model:
    def __init__(self, image):
        self.m = image

    # ---------------------------------------------------------------------------------------------------------
    # PhysicsTask $86C1, MoveBall $8701

    def tick(self, s, redraw=True):
        """One interrupt: the redraw task $827E first (it runs before the physics in MovingTasks), then the physics"""
        if redraw:
            self.redraw(s)
        s.event_count = 0
        s.events = []
        for i in range(7):
            f = s.b[i].flags
            if f & 0x80 and f & 0x40 and not f & 0x20:
                self.move(s, i)
        s.friction_turn = (s.friction_turn + 1) % 7

    @staticmethod
    def redraw(s):
        """RedrawBall $8297's effect on the records: +10/+11 follow the ball, a potted ball goes to the top row"""
        for n, b in enumerate(s.b):
            if not (b.flags & 0x80 and b.flags & 0x10):
                continue
            if b.flags & 0x20:
                b.flags = 0
                if n:
                    b.x, b.y = (24 * (n - 1) + 7) << 8, 27 << 8
                    b.sx, b.sy = b.px - 7, b.py - 7
                continue
            b.sx, b.sy = (b.px - 7) & 0xFF, (b.py - 7) & 0xFF
            b.flags &= ~0x10

    @staticmethod
    def shot(s, cursor, power):
        """ShotReset $84BF, then AimShot $8A02: v = 16 P (d / r), rounded as FP-TO-BC does; FrictionSteps"""
        import math
        for b in s.b:
            b.vx = b.vy = b.fx = b.fy = b.pocket = 0
            b.flags &= 0x80
        s.friction_turn = 0
        cue = s.b[0]
        p = 0x7E if power >= 0x80 else power
        dx, dy = cursor[0] - cue.px, cursor[1] - cue.py
        r = math.sqrt(dx * dx + dy * dy)
        cue.vy = int(math.floor(16 * p * dy / r + 0.5)) & 0xFFFF
        cue.vx = int(math.floor(16 * p * dx / r + 0.5)) & 0xFFFF
        cue.flags |= 0x40
        return dx, dy, r

    def move(self, s, i):
        b = s.b[i]
        if s.friction_turn == 6 - i:
            self.friction_steps(b)
        # x += vx, clamped to $0700..$F800 with the carry of the add
        total = b.x + b.vx
        carry, hl = total > 0xFFFF, total & 0xFFFF
        if not b.vx & 0x8000:
            b.x = 0xF800 if carry or hl >= 0xF800 else hl
        else:
            b.x = 0x0700 if not carry or hl < 0x0700 else hl
        total = b.y + b.vy
        carry, hl = total > 0xFFFF, total & 0xFFFF
        if not b.vy & 0x8000:
            b.y = 0xB000 if carry or hl >= 0xB000 else hl
        else:
            b.y = 0x3700 if hl < 0x3700 else hl          # no carry test on this side
        b.flags &= ~0x10
        self.ball_contacts(s, i)
        self.pocket_or_cushion(s, i)
        b.vx = self.friction_add(b.vx, b.fx)
        b.vy = self.friction_add(b.vy, b.fy)
        if b.vx == 0 and b.vy == 0:
            b.flags &= ~0x40
            s.events.append(('stop', i))
        if not b.flags & 0x10 and (b.px != b.sx or b.py != b.sy):
            b.flags |= 0x10

    @staticmethod
    def friction_add(v, step):
        """$8771: v += sext(step); a carry that says the sign flipped gives 0 (ADD HL,DE, CCF for a positive v)"""
        if step == 0:
            return v
        de = step | (0xFF00 if step & 0x80 else 0)
        total = v + de
        carry = total > 0xFFFF
        if not v & 0x8000:
            carry = not carry
        return 0 if carry else total & 0xFFFF

    # ---------------------------------------------------------------------------------------------------------
    # FrictionSteps $90F5

    def friction_steps(self, b):
        de = abs(s16(b.vx)) & 0xFFFF
        hl = abs(s16(b.vy)) & 0xFFFF
        for _ in range(8):
            if hl & 0x0800 or de & 0x0800:
                break
            hl = hl << 1 & 0xFFFF
            de = de << 1 & 0xFFFF
        ny, nx = hl >> 8, de >> 8
        cell = self.m[FRICTION + ((ny << 4) + nx & 0xFF)]
        a = cell & 0x0F
        b.fx = a if b.vx & 0x8000 else -a & 0xFF
        a = cell >> 4
        b.fy = a if b.vy & 0x8000 else -a & 0xFF

    # ---------------------------------------------------------------------------------------------------------
    # StepBack $8E33

    @staticmethod
    def step_back(b):
        dx, dy = s16(b.vx), s16(b.vy)

        def small(v):
            v &= 0xFFFF
            hi, lo = v >> 8, v & 0xFF
            return hi == 0 or (hi == 0xFF and lo != 0)
        while not (small(dx) and small(dy)):
            dx >>= 1
            dy >>= 1
        b.x = (b.x - dx) & 0xFFFF
        b.y = (b.y - dy) & 0xFFFF
        return dx, dy

    # ---------------------------------------------------------------------------------------------------------
    # BallContacts $87EF, ScaleVelocity $89C4

    @staticmethod
    def scale(coef, v):
        if coef & 0x100:
            return v & 0xFFFF
        neg = bool(v & 0x8000)
        if neg:
            v = -s16(v) & 0xFFFF
        frac, lo, hi = coef & 0xFF, v & 0xFF, v >> 8
        p = frac * lo
        h = (p >> 8) + (1 if p & 0x80 else 0)
        r = (h + frac * hi) & 0xFFFF
        return -r & 0xFFFF if neg else r

    def ball_contacts(self, s, i):
        me = s.b[i]
        found = None
        for j in range(7):
            o = s.b[j]
            if not o.flags & 0x80:
                continue
            dx = abs(me.px - o.px)
            if dx >= 16:
                continue
            dy = abs(me.py - o.py)
            if dy >= 16:
                continue
            if dx == 0 and dy == 0:
                continue
            if not self.m[CONTACT + 16 * dy + dx] & 0x80:
                continue
            steps = []
            while True:
                steps.append(self.step_back(me))
                sx, sy = (me.px - o.px) & 0xFF, (me.py - o.py) & 0xFF
                signs = 2 * (me.px < o.px) + (me.py < o.py)
                ax = (-sx & 0xFF) if me.px < o.px else sx
                ay = (-sy & 0xFF) if me.py < o.py else sy
                n = self.m[CONTACT + ((ay << 4) + ax & 0xFF)]
                if not n & 0x80:
                    break
            found = dict(other=j, n=n, signs=signs, steps=steps, dx=me.px - o.px, dy=me.py - o.py,
                         record=RECORDS + ((n - 1) * 6 & 0xFF))
        if found is None:
            return
        o = s.b[found['other']]
        signs = found['signs']
        tx = (signs << 6 ^ me.vx >> 8) & 0x80
        ty = (signs << 7 ^ me.vy >> 8) & 0x80
        ex = None
        if tx or ty:
            rec = found['record']
            w0 = self.m[rec] | self.m[rec + 1] << 8
            w1 = self.m[rec + 2] | self.m[rec + 3] << 8
            w2 = self.m[rec + 4] | self.m[rec + 5] << 8
            dvx = (o.vx - me.vx) & 0xFFFF
            dvy = (o.vy - me.vy) & 0xFFFF
            a, c = self.scale(w0, dvx), self.scale(w2, dvx)
            bb, d = self.scale(w2, dvy), self.scale(w1, dvy)
            add = signs in (0, 3)
            before = (me.vx, me.vy, o.vx, o.vy)
            me.vx = (me.vx + a + (bb if add else -bb)) & 0xFFFF
            me.vy = (me.vy + d + (c if add else -c)) & 0xFFFF
            o.vx = (o.vx - a - (bb if add else -bb)) & 0xFFFF
            o.vy = (o.vy - d - (c if add else -c)) & 0xFFFF
            o.flags |= 0x40
            s.event_count += 2
            self.friction_steps(me)
            self.friction_steps(o)
            ex = dict(w=(w0, w1, w2), dv=(s16(dvx), s16(dvy)), terms=(s16(a), s16(bb), s16(c), s16(d)), add=add,
                      before=tuple(s16(v) for v in before),
                      after=(s16(me.vx), s16(me.vy), s16(o.vx), s16(o.vy)))
        me.x = me.x & 0xFF00 | 0x80
        me.y = me.y & 0xFF00 | 0x80
        s.events.append(('contact', i, found, ex))

    # ---------------------------------------------------------------------------------------------------------
    # PocketOrCushion $8B4E (large pockets), CushionsLarge $8FBB and the jaws

    def pocket_or_cushion(self, s, i):
        b = s.b[i]
        self.jaw_patched = False
        if 8 <= b.px < 0xF8 and 0x38 <= b.py < 0xB0:
            return self.cushions_large(s, b)
        x = b.px
        lo, hi = (8, 0x0F) if x < 0x40 else (0xF0, 0xF7) if x >= 0xC0 else (0x7A, 0x85)
        cx = lo if x < lo else hi if x >= hi else x
        y = b.py
        lo, hi = (0x38, 0x3F) if y < 0x73 else (0xA8, 0xAF)
        cy = lo if y < lo else hi if y >= hi else y
        b.x, b.y = cx << 8, cy << 8
        col = 1 if cx < 0x40 else 2 if cx < 0xC0 else 3
        b.pocket = 7 - col if cy & 0x80 else col
        b.flags = (b.flags | 0x30) & ~0x40
        s.events.append(('pot', i, b.pocket))

    def cushions_large(self, s, b):
        while True:                        # LargeCushionTest: the test repeated after a jaw's step back
            r = self._large(s, b)
            if r != 'again':
                return r

    def _large(self, s, b):
        x = b.px
        if x >= 0xEF:
            return self._end(s, b, right=True)
        if x < 0x11:
            return self._end(s, b, right=False)
        y = b.py
        if y < 0x41:
            return self._long(s, b, top=True)
        if y >= 0xA7:
            return self._long(s, b, top=False)
        return None

    def _end(self, s, b, right):
        while True:
            x, y = b.px, b.py
            if y >= 0xA0 or y < 0x47:
                return self._corner(s, b, right, top=y < 0x47)
            if (x < 0xEF) if right else (x >= 0x11):
                return self.reflect_x(s, b, 'end')
            self.step_back(b)

    def _corner(self, s, b, right, top):
        x, y = b.px, b.py
        if not right and top:
            c, bb, raw = 0x00, 0xFF, y - 0x30 - x
        elif not right:
            c, bb, raw = 0x00, 0x00, 0xB7 - y - x
        elif top:
            c, bb, raw = 0xFF, 0xFF, x + y - 303
        else:
            c, bb, raw = 0xFF, 0x00, x - y - 72
        return self.diagonal_jaw(s, b, raw, c, bb)

    def diagonal_jaw(self, s, b, offset, c, bb):
        if offset < 0:
            offset, c, bb = -offset, c ^ 0xFF, bb ^ 0xFF
        if offset in (6, 7):
            return self.jaw_contact(s, b, c, bb)
        if offset < 6:
            if self.jaw_patched:
                return self.jaw_contact(s, b, c, bb)
            return None
        self.jaw_patched = True
        self.step_back(b)
        s.events.append(('jaw-deep', s.b.index(b)))
        return 'again'

    def jaw_contact(self, s, b, c, bb):
        l = (c ^ b.vx >> 8) & 0x80
        h = (bb ^ b.vy >> 8) & 0x80
        if not (l or h):
            reflect = False
        elif l and h:
            reflect = True
        else:
            ax, ay = abs(s16(b.vx)), abs(s16(b.vy))
            reflect = ax > ay if l else ay > ax
        if reflect:
            b.x = b.x & 0xFF00 | c
            b.y = b.y & 0xFF00 | bb
            return self.reflect_diagonal(s, b, c, bb, 'corner jaw')
        b.x = b.x & 0xFF00 | (c ^ 0xFF)
        b.y = b.y & 0xFF00 | (bb ^ 0xFF)
        return None

    def _long(self, s, b, top):
        face = 0x3A if top else 0xAD
        while True:
            x = b.px
            if x < 0x17:
                return self._end(s, b, right=False)
            if x >= 0xE8:
                return self._end(s, b, right=True)
            if x < 0x7A:
                jx, wall = 0x73, 0x7A00
                channel = x >= 0x73
            elif x < 0x86:
                return None                    # the middle pocket's channel
            else:
                jx, wall = 0x8C, 0x85FF
                channel = x < 0x8D
            y = b.py
            if channel:
                if (y >= 0x3A) if top else (y < 0xAD):
                    return self.point_jaw(s, b, jx, face)
                b.x = wall
                return self.reflect_x(s, b, 'channel wall')
            if (y < 0x39) if top else (y >= 0xAE):
                b.x = b.x & 0xFF | jx << 8
                b.y = b.y & 0xFF | face << 8
                return self.point_jaw(s, b, jx, face)
            if (y >= 0x41) if top else (y < 0xA7):
                return self.reflect_y(s, b, 'cushion')
            self.step_back(b)

    def point_jaw(self, s, b, c, bb):
        dx = abs(b.px - c)
        if dx >= 8:
            return None
        dy = abs(b.py - bb)
        if dy >= 8:
            return None
        if dx == dy and dy >= 5:
            return None
        v = self.m[TABLE8 + 8 * dy + dx]
        if v == 0:
            return None
        while v & 0x80:
            self.step_back(b)
            dx, dy = abs(b.px - c) & 0xFF, abs(b.py - bb) & 0xFF
            v = self.m[TABLE8 + ((dy << 3) + dx & 0xFF)]
        l = (c ^ b.vx >> 8) & 0x80
        h = (bb ^ b.vy >> 8) & 0x80
        if l and h:
            b.x = b.x & 0xFF00 | (0xFF if b.px & 0x80 else 0)
            b.y = b.y & 0xFF00 | (0xFF if b.py & 0x80 else 0)
            return self.reflect_diagonal(s, b, c, bb, 'jaw point')
        if not (l or h):
            return None
        if not h:
            return self.reflect_x(s, b, 'jaw point')
        return self.reflect_y(s, b, 'jaw point')

    # ReflectX $8DCB, ReflectY $8DFF, ReflectDiagonal $8D7D

    def reflect_x(self, s, b, why):
        b.vx = -s16(b.vx) & 0xFFFF
        b.fx = -b.fx & 0xFF
        b.x = b.x & 0xFF00 | (0xFF if b.px & 0x80 else 0)
        s.event_count += 1
        s.events.append(('cushion-x', s.b.index(b), why))

    def reflect_y(self, s, b, why):
        b.vy = -s16(b.vy) & 0xFFFF
        b.fy = -b.fy & 0xFF
        b.y = b.y & 0xFF00 | (0xFF if b.py & 0x80 else 0)
        s.event_count += 1
        s.events.append(('cushion-y', s.b.index(b), why))

    def reflect_diagonal(self, s, b, c, bb, why):
        vx, vy, fx, fy = b.vx, b.vy, b.fx, b.fy
        if not (bb ^ c) & 0x80:
            vx, vy, fx, fy = -s16(vx) & 0xFFFF, -s16(vy) & 0xFFFF, -fx & 0xFF, -fy & 0xFF
        b.vx, b.vy, b.fx, b.fy = vy, vx, fy, fx
        s.event_count += 1
        s.events.append(('diagonal', s.b.index(b), why))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--image', required=True)
    p.add_argument('--samples', required=True, help='JSON lines of $8A88-$8B4D, one a frame')
    p.add_argument('--shot', required=True, help='F,X,Y,P: the last still frame, the cursor and the power')
    p.add_argument('--ticks', type=int, default=800)
    p.add_argument('--events', action='store_true')
    args = p.parse_args()
    frame0, cx, cy, power = (int(v) for v in args.shot.split(','))
    model = Model(open(args.image, 'rb').read())
    samples = [json.loads(line) for line in open(args.samples)]
    samples = [(d['frame'], bytes.fromhex(d['hex'])[:98]) for d in samples if d['frame'] >= frame0]
    balls = Balls(samples[0][1])
    model.shot(balls, (cx, cy), power)
    model.friction_steps(balls.b[0])
    tick, ok, last = 0, 0, None
    for frame, want in samples[1:]:
        lost = 0
        while balls.raw() != want and lost < 3 and tick < args.ticks:
            model.tick(balls)
            tick += 1
            lost += 1
            if args.events:
                for e in balls.events:
                    print(f'  frame {frame} tick {tick}: {e[0]} ball {e[1]} {e[2:3]}')
        if balls.raw() != want:
            print(f'frame {frame}: the model differs after tick {tick}')
            print('  model', balls.raw().hex())
            print('  game ', want.hex())
            break
        ok += 1
        last = (frame, tick)
    print(f'{ok} frames equal to a model tick byte for byte (98 bytes); last frame {last[0]}, tick {last[1]}')


if __name__ == '__main__':
    sys.exit(main())
