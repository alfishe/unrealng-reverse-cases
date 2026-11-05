#!/usr/bin/env python3
"""The robots' turn of Nether Earth as Python: WorldTurn's robot and shot loops, exact to the byte.

The model is the code of src/game/world.asm (and Random of screen.asm, PutBlock, CountRobots, FindRobot, TerrainTop)
written as Python over a 64 K memory image. It is checked against the emulator turn by turn (tools/path_check.py):
the same robot records, shots, map, random state and counts after every WorldTurn. The experiments of
docs/13-path-finding.md (tools/path_lab.py) and its figures run it on the real map or on test maps.

Not modelled (the model raises Unmodelled, the checker skips such a turn): direct control (+$0A = 2) and the nuclear
blast (orders 4 and 5 on their target). The radar dots and the status panel are not drawn (no game decision reads
them).

    from path_model import World
    w = World(memory)          # 65536 bytes, e.g. a picture of $4000-$FFFF padded at the front
    w.world_turn()             # the robots and the shots of one game turn (EnemyCommander not included)
    w.log                      # one dict per robot step: where, what it saw, which branch, what it chose
"""

RANDOM_SEED, RANDOM_INDEX = 0xFD00, 0xD371   # the shift register; the operand of LD L,n inside Random
SIDE, SOUNDFX, ALTITUDE = 0xFD51, 0xFD53, 0xFD10
PLAYER_COUNT, ENEMY_COUNT = 0xFD41, 0xFD49
ROBOTS, ENEMY_ROBOTS, SHOTS = 0xDA00, 0xDB80, 0xD7D3
MAP = 0xDD00
WARBASES, FACTORIES = 0xFD70, 0xFD84
STEP_DELAYS = 0xB61D
TERRAIN_HEIGHTS = 0xD7BC
RIGHT, LEFT, DOWN, UP = 1, 2, 4, 8
NAMES = {0: '-', 1: 'R', 2: 'L', 4: 'D', 8: 'U'}


class Unmodelled(Exception):
    pass


def bits(n):
    """the set bits of a direction nibble, as a string: 'RLDU' order"""
    return ''.join(NAMES[b] for b in (1, 2, 4, 8) if n & b) or '-'


def count_directions(c):
    return bin(c & 0x0F).count('1')


def cell_address(x, y):
    return (MAP + 0x200 * y + x) & 0xFFFF


def cell_xy(address):
    o = address - MAP
    return o & 0x1FF, o >> 9


class World:
    def __init__(self, memory, log=True):
        self.m = bytearray(memory)
        if len(self.m) != 0x10000:
            raise ValueError('a 64 K image')
        self.logging = log
        self.log = []
        self.draws = 0          # Random calls
        self.turn_no = 0

    # ----------------------------------------------------------------------------------------------------------
    # memory helpers

    def word(self, a):
        return self.m[a & 0xFFFF] | self.m[(a + 1) & 0xFFFF] << 8

    def rec(self, iy, off):
        return self.m[(iy + off) & 0xFFFF]

    def put(self, iy, off, v):
        self.m[(iy + off) & 0xFFFF] = v & 0xFF

    # ----------------------------------------------------------------------------------------------------------
    # Random ($D358): a 32-bit shift register, then one of its four bytes chosen by the last index

    def random(self):
        m = self.m
        top = m[RANDOM_SEED]
        feedback = (((top & 0x48) + 0x38) >> 6) & 1         # bit 6 XOR bit 3 of $FD00
        carry = feedback
        for a in (0xFD03, 0xFD02, 0xFD01, 0xFD00):
            v = m[a]
            m[a] = ((v << 1) | carry) & 0xFF
            carry = v >> 7
        index = m[RANDOM_SEED + m[RANDOM_INDEX]] & 3
        m[RANDOM_INDEX] = index
        self.draws += 1
        return m[RANDOM_SEED + index]

    # ----------------------------------------------------------------------------------------------------------
    # the map

    def terrain_height(self, cell):
        return self.m[(TERRAIN_HEIGHTS + (self.m[cell] & 0x1F)) & 0xFFFF]

    def ground_under_footprint(self, x, y):
        """GroundUnderFootprint: the highest TerrainHeights of (X, Y), (X+1, Y), (X+1, Y-1), (X, Y-1)"""
        hl = self.map_cell(x, y)
        c = 0
        for cell in (hl, (hl + 1) & 0xFFFF, (hl + 1 - 0x200) & 0xFFFF, (hl - 0x200) & 0xFFFF):
            c = max(c, self.terrain_height(cell))
        return c

    def map_cell(self, x, y):
        """MapCell: L = the column's low byte, H = its high byte + 2 x row + $DD (8-bit)"""
        return ((x & 0xFF) | ((((x >> 8) + 2 * y + 0xDD) & 0xFF) << 8))

    def find_robot(self, cell):
        """FindRobot: the first of the 48 records whose cell +$00/+$01 is @p cell, else None"""
        for slot in range(48):
            iy = ROBOTS + 16 * slot
            if self.m[iy] == cell & 0xFF and self.m[iy + 1] == cell >> 8:
                return iy
        return None

    # ----------------------------------------------------------------------------------------------------------
    # FreeDirections ($B513) and its probes

    def free_directions(self, iy, hl):
        e = ((self.m[ALTITUDE] - self.rec(iy, 9) - self.rec(iy, 0x0D)) & 0x80) | 0x40
        parts = self.rec(iy, 7)
        d = 0x08 if parts & 1 else 0x0C if parts & 2 else 0x0F
        c = 0
        if self.can_move_right(hl, d, e):
            c |= RIGHT
        if self.can_move_left(hl, d, e):
            c |= LEFT
        if self.can_move_down(hl, d, e):
            c |= DOWN
        if self.can_move_up(hl, d, e):
            c |= UP
        return c, d, e

    def test_cell(self, hl, d, e):
        v = self.m[hl & 0xFFFF]
        return (v & 0x1F) < d and not (v & e)

    def anchor_free(self, hl, e):
        return not (self.m[hl & 0xFFFF] & e)

    def can_move_right(self, hl, d, e):
        hl = (hl + 2 - 0x200) & 0xFFFF
        if not self.test_cell(hl, d, e):
            return False
        hl = (hl + 0x200) & 0xFFFF
        if not self.test_cell(hl, d, e):
            return False
        hl = (hl + 0x200) & 0xFFFF
        if (hl >> 8) >= 0xFD:
            return True
        return self.anchor_free(hl, e)

    def can_move_left(self, hl, d, e):
        hl = (hl - 0x200 - 1) & 0xFFFF
        if not self.test_cell(hl, d, e):
            return False
        hl = (hl - 1) & 0xFFFF
        if not self.anchor_free(hl, e):
            return False
        hl = (hl + 0x200) & 0xFFFF
        if not self.anchor_free(hl, e):
            return False
        hl = (hl + 1) & 0xFFFF
        if not self.test_cell(hl, d, e):
            return False
        hl = (hl - 1 + 0x200) & 0xFFFF
        if (hl >> 8) >= 0xFD:
            return True
        return self.anchor_free(hl, e)

    def can_move_down(self, hl, d, e):
        hl = (hl + 0x200) & 0xFFFF
        if (hl >> 8) >= 0xFD:
            return False
        if not self.test_cell(hl, d, e):
            return False
        hl = (hl + 1) & 0xFFFF
        if not self.test_cell(hl, d, e):
            return False
        hl = (hl + 0x200) & 0xFFFF
        if (hl >> 8) >= 0xFD:
            return True
        for k in (0, -1, -2):
            if not self.anchor_free(hl + k, e):
                return False
        return True

    def can_move_up(self, hl, d, e):
        hl = (hl - 0x400) & 0xFFFF
        if (hl >> 8) < 0xDD:
            return False
        if not self.anchor_free(hl - 1, e):
            return False
        return self.test_cell(hl, d, e) and self.test_cell(hl + 1, d, e)

    # ----------------------------------------------------------------------------------------------------------
    # SpotEnemies ($B626) and ScanLane ($B66E)

    def scan_lane(self, iy, hl, direction, length):
        step = {RIGHT: 1, LEFT: -1, DOWN: 0x200, UP: -0x200}[direction]
        for _ in range(length):
            hl = (hl + step) & 0xFFFF
            if ((hl >> 8) - 0xDD) & 0xFF >= 0x20:
                return False
            if self.m[hl] & 0x40:
                other = self.find_robot(hl)
                if other is None:
                    return False
                if not ((self.m[other + 0x0A] ^ self.rec(iy, 0x0A)) & 0x80):
                    return False
                if (self.m[other + 0x0C] - 1) & 0x80:
                    return False
                return True
        return False

    def spot_enemies(self, iy):
        e = 0
        anchor = self.rec(iy, 0) | self.rec(iy, 1) << 8
        facing = self.rec(iy, 8)
        for direction in (UP, DOWN, LEFT, RIGHT):
            e = (e << 1) & 0xFF
            length = 8
            if direction == facing:
                length = 12 if self.rec(iy, 7) & 0x80 else 10
                if direction & 3:
                    lanes = (anchor - 0x200, anchor, anchor + 0x200)
                else:
                    lanes = (anchor - 1, anchor, anchor + 1)
            else:
                lanes = (anchor,)
            for hl in lanes:
                if self.scan_lane(iy, hl & 0xFFFF, direction, length):
                    e |= 1
        return e

    # ----------------------------------------------------------------------------------------------------------
    # the robot turn

    def world_turn(self, before_slot=None):
        """WorldTurn without EnemyCommander: the 48 robot records, then the 5 shot records. before_slot(slot), when
        given, runs before each robot record (path_check.py puts an interrupt's draws there)"""
        self.turn_no += 1
        for slot in range(48):
            iy = ROBOTS + 16 * slot
            if before_slot:
                before_slot(slot)
            if self.m[iy + 1]:
                self.update_robot(iy, slot)
        for k in range(5):
            iy = SHOTS + 9 * k
            if self.m[iy + 1]:
                self.update_shot(iy)

    def update_robot(self, iy, slot):
        s = self.rec(iy, 0x0C)
        if s == 0:
            return self.robot_destroyed(iy)
        if s < 0x80:
            return self.robot_step(iy, slot)
        self.put(iy, 0x0C, s + 1)
        cell = self.rec(iy, 0) | self.rec(iy, 1) << 8
        if s & 1:
            self.m[cell] |= 0x40
        else:
            self.m[cell] &= ~0x40 & 0xFF

    def robot_destroyed(self, iy):
        hl = self.rec(iy, 0) | self.rec(iy, 1) << 8
        self.m[hl] &= 0xBF
        a = self.m[hl] | self.m[(hl + 1) & 0xFFFF] | self.m[(hl + 1 - 0x200) & 0xFFFF] | self.m[(hl - 0x200) & 0xFFFF]
        if not (a & 0x3F):
            self.put_block(hl, (self.random() & 1) + 6)
        self.put(iy, 1, 0)
        self.count_robots()

    def put_block(self, hl, tile):
        e = tile                                         # only the anchor plain: SET 5,E stays for the rest
        for row in range(2):
            base = (hl - 0x200 * row) & 0xFFFF
            for col in range(2):
                self.m[(base + col) & 0xFFFF] = e
                e |= 0x20

    def count_robots(self):
        for side, out in ((0, PLAYER_COUNT), (1, ENEMY_COUNT)):
            self.m[out] = sum(1 for s in range(24) if self.m[ROBOTS + 16 * (24 * side + s) + 1])

    def robot_step(self, iy, slot):
        ctl = self.rec(iy, 0x0A)
        if ctl == 1:
            return
        self.m[SIDE] = (ctl >> 7) & 1
        self.put(iy, 0x0F, self.rec(iy, 0x0F) - 1)
        if self.rec(iy, 0x0F):
            return
        hl = self.rec(iy, 0) | self.rec(iy, 1) << 8
        self.m[hl] &= 0xBF
        c, limit, block = self.free_directions(iy, hl)
        if ctl == 2:
            raise Unmodelled('direct control')
        x, y = self.rec(iy, 2) | self.rec(iy, 3) << 8, self.rec(iy, 4)
        entry = {'turn': self.turn_no, 'slot': slot, 'x': x, 'y': y, 'facing': self.rec(iy, 8),
                 'course_in': self.rec(iy, 5), 'steps_in': self.rec(iy, 6), 'order': self.rec(iy, 0x0B),
                 'target': self.rec(iy, 0x0E), 'free': c, 'draw0': self.draws, 'ship_blocks': bool(block & 0x80)}
        e = self.spot_enemies(iy)
        entry['seen'] = e
        if e:
            if e & self.rec(iy, 8):
                ahead = e & self.rec(iy, 8) & c
                self.put(iy, 5, ahead)
                shot = self.find_free_shot(iy)
                fired = 0
                if shot is not None:
                    a = self.random() & 0x38 & self.rec(iy, 7)
                    if a:
                        weapon = 3 if a & 0x20 else 2 if a & 0x10 else 1
                        self.fire_shot(shot, iy, weapon)
                        self.put(iy, 5, 0)
                        fired = weapon
                self.put(iy, 6, 1)
                entry['branch'] = 'fire' if fired else 'ahead'
                entry['weapon'] = fired
            else:
                pick = e
                if count_directions(e) != 1:
                    pick = self.pick_one(e)
                self.put(iy, 5, pick)
                self.put(iy, 6, 2)
                entry['branch'] = 'turn-to-enemy'
        else:
            steps = (self.rec(iy, 6) - 1) & 0xFF
            self.put(iy, 6, steps)
            if not (steps & 0x80) and self.rec(iy, 5) & c:
                entry['branch'] = 'keep'
            else:
                self.put(iy, 6, (self.random() & 3) + 3)
                entry['course_len'] = self.rec(iy, 6)
                if count_directions(c) == 0:
                    pick = 0
                    entry['branch'] = 'boxed'
                else:
                    self.steer = {}
                    pick = self.steer_by_order(iy, c)
                    entry['branch'] = 'steer'
                    entry.update(self.steer)
                if not self.rec(iy, 1):
                    raise Unmodelled('robot gone in SteerByOrder')
                self.put(iy, 5, pick)
        entry['course'] = self.rec(iy, 5)
        self.robot_move(iy)
        entry['steps_out'] = self.rec(iy, 6)
        entry['x2'], entry['y2'] = self.rec(iy, 2) | self.rec(iy, 3) << 8, self.rec(iy, 4)
        entry['facing2'] = self.rec(iy, 8)
        entry['delay'] = self.rec(iy, 0x0F)
        entry['draws'] = self.draws - entry['draw0']
        if self.logging:
            self.log.append(entry)

    def robot_move(self, iy):
        a = self.rec(iy, 5)
        x, y = self.rec(iy, 2) | self.rec(iy, 3) << 8, self.rec(iy, 4)
        x, y = self.turn_or_step(iy, a, x, y)
        self.set_step_delay(iy)
        self.place_robot(iy, x, y)

    def place_robot(self, iy, x, y):
        self.put(iy, 2, x)
        self.put(iy, 3, x >> 8)
        self.put(iy, 4, y)
        cell = self.map_cell(x, y)
        self.put(iy, 0, cell)
        self.put(iy, 1, cell >> 8)
        self.m[cell] |= 0x40

    def turn_or_step(self, iy, a, x, y):
        if not a:
            return x, y
        facing = self.rec(iy, 8)
        if a != facing:
            c = a
            both = a | facing
            if both == 0x03:
                c = ((c << 2) | (c >> 6)) & 0xFF
            elif both == 0x0C:
                c = ((c >> 2) | (c << 6)) & 0xFF
            self.put(iy, 8, c)
            self.put(iy, 6, self.rec(iy, 6) + 1)
            return x, y
        x, y = self.step_position(iy, a, x, y)
        self.put(iy, 0x0D, self.ground_under_footprint(x, y))
        return x, y

    def step_position(self, iy, a, x, y):
        order = self.rec(iy, 0x0B)
        if a & RIGHT:
            x = (x + 1) & 0xFFFF
            if order == 1:
                self.distance_down(iy)
            elif order == 2:
                self.distance_up(iy)
        elif a & LEFT:
            x = (x - 1) & 0xFFFF
            if order == 1:
                self.distance_up(iy)
            elif order == 2:
                self.distance_down(iy)
        elif a & DOWN:
            y = (y + 1) & 0xFF
        elif a & UP:
            y = (y - 1) & 0xFF
        return x, y

    def distance_up(self, iy):
        if self.rec(iy, 0x0A) == 2:
            return
        v = (self.rec(iy, 0x0E) + 1) & 0xFF
        self.put(iy, 0x0E, 0x63 if v >= 0x64 else v)

    def distance_down(self, iy):
        if self.rec(iy, 0x0A) == 2:
            return
        v = (self.rec(iy, 0x0E) - 1) & 0xFF
        self.put(iy, 0x0E, v)
        if v == 0:
            self.put(iy, 0x0B, 0)
            self.put(iy, 6, 0)

    def set_step_delay(self, iy):
        g = self.rec(iy, 0x0D)
        row = 0 if g == 0 else 3 if g < 4 else 6
        parts = self.rec(iy, 7)
        d = 0
        while not (parts >> d) & 1:
            d += 1
            if d > 7:
                raise Unmodelled('no part bit')
        self.put(iy, 0x0F, self.m[STEP_DELAYS + ((row + d) & 0xFF)])

    # ----------------------------------------------------------------------------------------------------------
    # SteerByOrder ($B222) and its aims

    def steer_by_order(self, iy, c):
        b = c
        order = self.rec(iy, 0x0B)
        self.steer['rule'] = None
        if order == 0:
            self.steer['rule'] = 'stop'
            return 0
        if order < 3:
            self.steer['rule'] = 'lean'
            self.steer['wanted'] = order & 3
            return self.lean_to(iy, order, b, c)
        if order == 3:
            return self.steer_robot(iy, b, c)
        return self.steer_building(iy, order, b, c)

    def target_robot_record(self, iy):
        base = ROBOTS if self.m[SIDE] else ENEMY_ROBOTS
        return (base + ((((self.rec(iy, 0x0E) * 8) & 0xFF) * 2))) & 0xFFFF

    def steer_robot(self, iy, b, c):
        ours = self.rec(iy, 2) | self.rec(iy, 3) << 8
        keep = False
        if not (self.rec(iy, 0x0E) & 0x80):
            t = self.target_robot_record(iy)
            if self.m[t + 1]:
                theirs = self.word(t + 2)
                dist = abs(theirs - ours)
                keep = dist < 50
        if not keep:
            self.put(iy, 0x0E, 0xFF)
            d = self.find_nearest_opponent(iy, ours)
            self.put(iy, 0x0E, d)
            self.steer['new_target'] = d
            if d == 0xFF:
                self.steer['rule'] = 'no-opponent'
                return self.pick_one(b)
        t = self.target_robot_record(iy)
        tx, ty = self.word(t + 2), self.m[t + 4]
        brow = (self.rec(iy, 4) - ty) & 0xFF
        diff = (ours - tx) & 0xFFFF
        self.steer['aim'] = (tx, ty)
        return self.aim(iy, diff, brow, c, horizontal=diff != 0)

    def target_building_table(self, order):
        if order in (5, 8):
            hl, n = WARBASES + 3, 4
        else:
            hl, n = FACTORIES + 3, 24
        e = 0x40 if self.m[SIDE] else 0x20
        if order == 6:
            e = 0
        return hl, n, e

    def steer_building(self, iy, order, b, c):
        hl, n, e = self.target_building_table(order)
        hl = (hl + ((self.rec(iy, 0x0E) * 5) & 0xFF)) & 0xFFFF
        if (self.m[hl] & 0xE0) != e:
            ours = self.rec(iy, 2) | self.rec(iy, 3) << 8
            d, hl = self.find_target_building(iy, order, ours)
            self.steer['new_target'] = d
            if d == 0xFF:
                self.steer['rule'] = 'no-building'
                if self.rec(iy, 0x0A) & 0x80:
                    self.put(iy, 0x0B, 3)
                return 0
            self.put(iy, 0x0E, d)
            self.steer['past_table'] = hl      # the bug: HL is past the table here
        row = self.m[(hl - 1) & 0xFFFF]
        brow = (self.rec(iy, 4) - row) & 0xFF
        tx = self.m[(hl - 2) & 0xFFFF] << 8 | self.m[(hl - 3) & 0xFFFF]
        ours = self.rec(iy, 2) | self.rec(iy, 3) << 8
        diff = (ours - tx) & 0xFFFF
        self.steer['aim'] = (tx, row)
        if diff == 0:
            return self.aim(iy, diff, brow, c, horizontal=False)
        return self.aim(iy, diff, (brow - 3) & 0xFF, c, horizontal=True)

    def aim(self, iy, diff, brow, c, horizontal):
        """RobotAim / RobotAimVertical / RobotAimCheck / RobotAimMove / RobotAimColumns"""
        h, l = diff >> 8, diff & 0xFF
        d = 0
        if horizontal:
            d = ((((h >> 1) | (h << 7)) & 0xFF) & 3) ^ 2
        if brow:
            v = ((brow >> 2) | (brow << 6)) & 0xFF
            d |= (v & 0x0C) ^ 0x08
        self.steer['wanted'] = d
        if not d:
            order = self.rec(iy, 0x0B)
            if 4 <= order < 6:
                raise Unmodelled('nuclear blast')
            self.steer['rule'] = 'arrived'
            if self.rec(iy, 8) == DOWN:
                return 0
            self.put(iy, 6, 0xFF)
            return DOWN
        if l & 0x80:
            l = (-l) & 0xFF
        self.steer['dx_used'] = l
        b = c
        if l >= 8:
            self.steer['rule'] = 'far-lean'
            return self.lean_to(iy, d, b, c)
        a = d & c
        if not a:
            self.steer['rule'] = 'near-any'
            return self.pick_one(b)
        b = a
        if not (a & 3) or l == 0:
            self.steer['rule'] = 'near-wanted'
            return self.pick_one(b)
        self.put(iy, 6, l - 1)
        self.steer['rule'] = 'near-wanted-keep'
        self.steer['keep'] = l - 1
        return self.pick_one(b)

    def lean_to(self, iy, a, b, c):
        """RobotLeanTo: the horizontal part of A when free, 3/4 at once, else among the free set but the opposite"""
        d = a & 3
        e = d ^ 0xFC
        if not (c & d):
            self.steer['lean'] = 'blocked'
            return self.pick_one(b)
        if self.random() & d:
            self.steer['lean'] = 'first'
            return d
        if self.random() & d:
            self.steer['lean'] = 'second'
            return d
        self.steer['lean'] = 'pick'
        return self.pick_one(b & e)

    def pick_one(self, b):
        """PickOneDirection: mask with random bytes until one bit is left"""
        c = b
        while True:
            c = self.random() & c
            n = count_directions(c)
            if n == 1:
                return c
            if n == 0:
                c = b

    # ----------------------------------------------------------------------------------------------------------
    # the searches

    def find_target_building(self, iy, order, ours):
        hl, n, e = self.target_building_table(order)
        best, d = 0x2000, 0xFF
        base = ROBOTS if self.m[SIDE] == 0 else ENEMY_ROBOTS
        for index in range(n):
            if (self.m[hl] & 0xE0) == e:
                taken = False
                for s in range(24):
                    r = base + 16 * s
                    if self.m[r + 1] and self.m[r + 0x0B] == order and self.m[r + 0x0E] == index:
                        taken = True
                        break
                if not taken:
                    x = self.m[(hl - 2) & 0xFFFF] << 8 | self.m[(hl - 3) & 0xFFFF]
                    dist = abs(x - ours)
                    if dist < best:
                        best, d = dist, index
            hl = (hl & 0xFF00) | ((hl + 5) & 0xFF)
        return d, hl

    def find_nearest_opponent(self, iy, ours):
        base = ROBOTS if self.m[SIDE] else ENEMY_ROBOTS
        best, d = 0x2000, 0xFF
        for s in range(24):
            r = base + 16 * s
            if self.m[r + 1]:
                dist = abs(self.word(r + 2) - ours)
                if dist < best:
                    best, d = dist, s
        return d

    # ----------------------------------------------------------------------------------------------------------
    # shots

    def find_free_shot(self, iy):
        shot = SHOTS + 9 + (0x12 if self.rec(iy, 0x0A) & 0x80 else 0)
        if not self.m[shot + 1]:
            return shot
        shot += 9
        if not self.m[shot + 1]:
            return shot
        return None

    def fire_shot(self, sh, ix, weapon):
        self.m[sh + 7] = weapon
        c = 7 if weapon == 2 else 5
        if self.m[ix + 7] & 0x80:
            c += 1
        self.m[sh + 6] = c
        self.m[sh + 5] = self.m[ix + 8]
        self.m[sh + 8] = 0x0A
        x, y = self.word(ix + 2), self.m[ix + 4]
        self.move_shot(sh, x, y)
        if self.m[sh + 1]:
            self.m[SOUNDFX] = 1

    def update_shot(self, sh):
        cell = self.word(sh)
        self.m[cell] &= 0xBF
        self.m[sh + 6] = (self.m[sh + 6] - 1) & 0xFF
        if not self.m[sh + 6]:
            return self.shot_gone(sh)
        self.move_shot(sh, self.word(sh + 2), self.m[sh + 4])

    def shot_gone(self, sh):
        self.m[sh + 1] = 0
        self.m[SOUNDFX] = 0xFC

    def move_shot(self, sh, x, y):
        a = self.m[sh + 5]
        if a & 1:
            x = (x + 2) & 0xFFFF
        elif a & 2:
            x = (x - 2) & 0xFFFF
        elif a & 4:
            y = (y + 2) & 0xFF
            if y >= 0x10:
                return self.shot_gone(sh)
        elif a & 8:
            y = (y - 2) & 0xFF
            if y >= 0x10:
                return self.shot_gone(sh)
        self.m[sh + 2], self.m[sh + 3], self.m[sh + 4] = x & 0xFF, x >> 8, y
        if self.ground_under_footprint(x, y) >= self.m[sh + 8]:
            return self.shot_gone(sh)
        cell = self.map_cell(x, y)
        self.m[sh], self.m[sh + 1] = cell & 0xFF, cell >> 8
        hit = None
        rows = []
        if (((cell - 1 - 0x200) & 0xFFFF) >> 8) >= 0xDD:
            rows.append(-0x200)
        rows.append(0)
        rows.append(0x200)
        for dy in rows:
            if dy == 0x200 and (((cell - 1 + 0x200) & 0xFFFF) >> 8) >= 0xFD:
                break
            for dx in (-1, 0, 1):
                h = (cell + dy + dx) & 0xFFFF
                if self.m[h] & 0x40:
                    hit = h
                    break
            if hit is not None:
                break
        if hit is None:
            self.m[cell] |= 0x40
            return
        weapon = self.m[sh + 7]
        sound = 0xFC
        r = self.find_robot(hit)
        if r is not None and not ((self.m[r + 0x0C] - 1) & 0x80):
            dpt = ((0x3C - self.m[r + 9] - self.m[r + 0x0D]) & 0xFF) >> 2
            dmg = dpt
            for _ in range(weapon if weapon else 256):
                dmg = (dmg + dpt) & 0xFF
            sound = 0xFA
            left = (self.m[r + 0x0C] - dmg) & 0xFF
            if left == 0 or left & 0x80:
                left, sound = 0xFC, 0xC8
            self.m[r + 0x0C] = left
        self.m[sh + 1] = 0
        self.m[SOUNDFX] = sound


# ----------------------------------------------------------------------------------------------------------------
# the random generator alone (for the probability tables)

class Rng:
    """Random over its own 5 bytes: the shift register and the index"""

    def __init__(self, seed=(0x39, 0x30, 0x39, 0x30), index=0):
        self.s = list(seed)
        self.i = index

    def __call__(self):
        top = self.s[0]
        carry = (((top & 0x48) + 0x38) >> 6) & 1
        for k in (3, 2, 1, 0):
            v = self.s[k]
            self.s[k] = ((v << 1) | carry) & 0xFF
            carry = v >> 7
        self.i = self.s[self.i] & 3
        return self.s[self.i]

    def state(self):
        return tuple(self.s) + (self.i,)
