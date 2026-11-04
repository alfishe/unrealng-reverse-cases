#!/usr/bin/env python3
"""A player for Nether Earth that reads the game's own variables and map (docs/07-objects.md) and steers the Kempston
stick, so a recording reaches what random play never does: robots built at a warbase, orders given, factories
captured, fights (docs/10-gameplay-logic.md).

    python3 bot.py launch --unreal U --binary B --start work/play/start.szx --work work/bot [--port-base 9310]
    python3 bot.py state --work work/bot
    python3 bot.py play --unreal U --binary B --start work/play/start.szx --work work/deep --frames 36000 [--record]

`play` starts the game (Kempston, key 0) and goes round PLAN: build a robot at the warbase when the resources pay for
it, give it its order, hover over the warbase while the resources grow (WALKTHROUGH 6). With --record it records the
run (TTD + analysis), builds W/l1.json, dumps W/session.ttd and keeps the instance.

`launch` starts an unreal-qt instance (offscreen, muted, a Kempston card) from the menu snapshot and writes
W/session.json, so re_session.py and the kit's scripts find it; the other commands attach to it. The emulator is exact
and every decision depends only on memory, so a run with --record replays the same game as the run without it.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, '..', '..', '..', 'kit')
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402

# The variables (src/game/game.ann @equ)
SHIP_Y, SHIP_X, ALTITUDE, INPUT = 0xFD0D, 0xFD0E, 0xFD10, 0xFD0C
VIEW_X = 0xFD0A
MAP = 0xDD00          # 16 rows of 512 cells: row y at $DD00 + $200 * y
ROBOTS = 0xDA00       # 48 records of 16 bytes: 0-23 the player's, 24-47 the enemy's
BUILDINGS = 0xFF01    # 56 records of 3 bytes: the cell address, the type (0 the player's warbase, 1-6 factories)
RESOURCES = 0xFD22    # general, electronics, nuclear, phasers, missiles, cannon, chassis
CURSOR = 0xFD1F       # the construction menu: column (0 exit, 1 start, 2 the parts), the part (0-7), the parts mask
HANDLER = 0xFDFE      # the IM2 handler the game installs: one per mode
START_INTERRUPT = 0xD59C
SELECTED = 0x4E       # the attribute of the highlighted item of a list menu (sub_ACD7); $4F once chosen
STICK = {'fire', 'left', 'right', 'up', 'down'}

# Parts (the construction menu rows, bit = row in the robot's mask +7) and their cost (data_CAF0)
BIPOD, TRACKS, ANTIGRAV, CANNON, MISSILES, PHASERS, NUCLEAR, ELECTRONICS = range(8)
COST = [3, 5, 10, 2, 4, 4, 20, 3]

# The robot menu (sub_A720) and its lists: (attribute of item 0, items + 1)
MAIN_MENU = (0x5837, 5)      # 1 direct control, 2 give orders, 3 combat mode, 4 leave robot
ORDERS_MENU = (0x5897, 6)    # 1 stop and defend, 2 advance, 3 retreat, 4 search and destroy, 5 search and capture
TARGET_MENU = (0x5937, 4)    # destroy: 1 robots, 2 factories, 3 warbases; capture: 1 neutral, 2 enemy factories,
                             # 3 enemy warbases
GIVE_ORDERS, LEAVE_ROBOT = 2, 4
DESTROY, CAPTURE = 4, 5
# The order byte (+$0B) each choice leaves: 0 stop, 1 advance, 2 retreat, 3-5 destroy, 6-8 capture
ORDER_NAMES = ['stop', 'advance', 'retreat', 'destroy robots', 'destroy factories', 'destroy warbases',
               'capture neutral', 'capture factories', 'capture warbases']


def cell_address(x, y):
    return MAP + 0x200 * y + x


def cell_xy(address):
    o = address - MAP
    return o & 0x1FF, o >> 9


class Game:
    def __init__(self, unreal, work):
        sys.path.insert(0, os.path.join(K.unreal_root(unreal), 'tools', 'verification', 'analysis'))
        import corpus  # noqa: E402
        self.corpus = corpus
        self.mcplib = corpus.mcplib
        self.work = os.path.abspath(work)
        self.held = set()
        self.frame = 0
        self.log = []

    def launch(self, binary, start, port_base, record=False):
        os.makedirs(self.work, exist_ok=True)
        start = os.path.abspath(start)
        here = os.getcwd()
        os.chdir(self.work)  # the emulator writes its features.ini where it starts
        try:
            process = self.mcplib.launch(binary, port_base)
        finally:
            os.chdir(here)
        s = self.mcplib.Session(f'http://127.0.0.1:{port_base + 200}/mcp', '48K')
        s.fresh_machine('48K', ram_power_on='zero')
        s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
        for _ in range(100):  # the plug restarts the machine: wait for the wired stick
            if 'slots_plug slot=edge.1' not in s.call('joystick_input', {'action': 'status'}, ok=False).text:
                break
            time.sleep(0.1)
        s.call('control_execution', {'action': 'pause'}, ok=False)
        s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                              'body': {'muted': True}}, ok=False)
        self.s = s
        self.m = self.corpus.Machine(s, port_base)
        self.m.post('/snapshot/load', {'path': os.path.abspath(start)})
        with open(os.path.join(self.work, 'session.json'), 'w') as f:
            json.dump({'pid': process.pid, 'binary': binary, 'port_base': port_base, 'model': '48K',
                       'ranges': '5B00-FFFF'}, f)
        if record:
            # The same files as re_session.py capture: re_session.py build / stages / stop work on this instance
            self.m.post('/snapshot/save', {'path': os.path.join(self.work, 'start.szx'), 'force': True})
            with open(os.path.join(self.work, 'start.bin'), 'wb') as f:
                f.write(self.m.read(0, 0x10000))
            s.call('analysis', {'action': 'start', 'record': True})
        return process

    def attach(self):
        with open(os.path.join(self.work, 'session.json')) as f:
            state = json.load(f)
        self.s = self.mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])
        self.s.call('control_execution', {'action': 'take_control'}, ok=False)
        self.m = self.corpus.Machine(self.s, state['port_base'])
        return self

    def finish(self):
        """Build L1 from the recording and dump it next to session.json"""
        self.stick(set())
        self.s.call('analysis', {'action': 'build', 'path': os.path.join(self.work, 'l1.json'), 'wait': 30000})
        state = self.s.call('analysis', {'action': 'status'}).text
        while ': running' in state:
            time.sleep(5)
            state = self.s.call('analysis', {'action': 'status'}).text
        print(state)
        dumped = self.s.call('time_travel', {'action': 'dump', 'path': os.path.join(self.work, 'session.ttd')},
                             ok=False)
        print((dumped.text or '').splitlines()[:1])

    # The stick and the clock

    def stick(self, buttons):
        """Hold exactly @p buttons (fire, left, right, up, down)"""
        buttons = set(buttons)
        for b in self.held - buttons:
            self.s.call('joystick_input', {'action': 'release', 'buttons': b}, ok=False)
        for b in buttons - self.held:
            self.s.call('joystick_input', {'action': 'press', 'buttons': b}, ok=False)
        self.held = buttons

    def key(self, key, hold=5, gap=20):
        self.s.call('type_input', {'action': 'press', 'key': key}, ok=False)
        self.run(hold)
        self.s.call('type_input', {'action': 'release', 'key': key}, ok=False)
        self.run(gap)

    def run(self, frames):
        self.s.call('control_execution', {'action': 'run_frames', 'frames': frames})
        self.frame += frames

    def hold_until(self, buttons, probe, limit=60, step=1):
        """Hold @p buttons until probe() changes (at most @p limit frames), then release; True if it changed"""
        before = probe()
        self.stick(buttons)
        for _ in range(0, limit, step):
            self.run(step)
            if probe() != before:
                break
        self.stick(set())
        self.run(2)
        return probe() != before

    def note(self, text):
        line = f'{self.frame:6d} {text}'
        self.log.append(line)
        print(line, flush=True)

    # Reading the game

    def screen(self, path):
        image = K.render_screen(self.m.read(0x4000, 6912), 0)
        image.resize((512, 384), resample=0).save(path)
        return path

    def state(self):
        v = self.m.read(0xFD00, 0x100)
        x = v[0x0E] | v[0x0F] << 8
        y = v[0x0D]
        return {'x': x, 'y': y, 'altitude': v[0x10], 'input': v[0x0C], 'view': v[0x0A] | v[0x0B] << 8,
                'cell': self.m.read(cell_address(x, y), 1)[0], 'resources': list(v[0x22:0x29]),
                'clock': list(v[0x35:0x38]), 'handler': v[0xFE] | v[0xFF] << 8}

    def robots(self):
        """[{slot, mine, x, y, parts, order, ...}] of the live robot records"""
        mem = self.m.read(ROBOTS, 48 * 16)
        out = []
        for i in range(48):
            r = mem[16 * i:16 * i + 16]
            if not r[1]:
                continue
            x, y = cell_xy(r[0] | r[1] << 8)
            out.append({'slot': i, 'address': ROBOTS + 16 * i, 'mine': i < 24, 'x': x, 'y': y, 'parts': r[7],
                        'height': r[9] + r[13], 'menu': r[10], 'order': r[11], 'raw': r.hex(' ')})
        return out

    def buildings(self):
        mem = self.m.read(BUILDINGS, 56 * 3)
        out = []
        for i in range(56):
            e = mem[3 * i:3 * i + 3]
            if e[1]:
                x, y = cell_xy(e[0] | e[1] << 8)
                out.append({'x': x, 'y': y, 'type': e[2]})
        return out

    # Flying

    def fly_to(self, x, y, cruise=40, limit=3000, follow=None):
        """Fly over (x, y) at least @p cruise high; @p follow() may move the target. True when over it"""
        for _ in range(0, limit, 2):
            if follow:
                target = follow()
                if target is None:
                    return False
                x, y = target
            st = self.state()
            if st['x'] == x and st['y'] == y:
                self.stick(set())
                return True
            buttons = set()
            if st['x'] != x:
                buttons.add('right' if st['x'] < x else 'left')
            if st['y'] != y:
                buttons.add('down' if st['y'] < y else 'up')
            if st['altitude'] < cruise:
                buttons.add('fire')
            self.stick(buttons)
            self.run(2)
        self.stick(set())
        return False

    def climb(self, altitude=40):
        self.stick({'fire'})
        for _ in range(60):
            self.run(2)
            if self.state()['altitude'] >= altitude:
                break
        self.stick(set())

    # The construction menu (sub_C849)

    def land_on_warbase(self, x, y):
        """Fly to the pad (x, y) and sink on it: the construction menu opens at altitude 15"""
        self.fly_to(x, y)
        self.stick(set())
        for _ in range(200):
            self.run(2)
            if self.state()['handler'] == START_INTERRUPT:
                # ConstructionMenu installs its handler first, then draws and resets MenuCursor / MenuParts: a part
                # chosen before the reset is lost. The menu is ready when its loop waits for a key (cursor 2, 0)
                for _ in range(100):
                    self.run(2)
                    if self.cursor() == (2, 0, 0):
                        self.run(10)
                        return True
                return False
        return False

    def cursor(self):
        return tuple(self.m.read(CURSOR, 3))

    def goto(self, column, part=0):
        for _ in range(20):
            c = self.cursor()
            if c[0] != column:
                self.hold_until({'right' if c[0] < column else 'left'}, self.cursor)
            elif column == 2 and c[1] != part:
                self.hold_until({'up' if c[1] < part else 'down'}, self.cursor)  # up: the next part
            else:
                return True
        return False

    def build(self, parts):
        """Choose exactly @p parts (a list of part numbers), START ROBOT, then leave climbing. The new robot's slot or
        None (refused: no chassis, no weapon, not enough resources)"""
        want = sum(1 << p for p in parts)
        before = {r['slot'] for r in self.robots()}
        for _ in range(3):  # a press can fall into the menu's pause after a move: look again
            for p in range(8):
                if (self.cursor()[2] ^ want) >> p & 1:
                    self.goto(2, p)
                    self.hold_until({'fire'}, lambda: self.cursor()[2])
            if self.cursor()[2] == want:
                break
        made = self.cursor()[2] == want
        if not made:
            self.note(f'parts ${self.cursor()[2]:02X}, wanted ${want:02X}, resources {self.state()["resources"]}')
        for _ in range(3):  # START ROBOT / EXIT MENU: again while the menu stays (a press lost in its pause)
            self.goto(1 if made else 0)
            if self.hold_until({'fire'}, lambda: self.m.read(HANDLER, 2), limit=400):
                break
        self.climb()
        new = [r for r in self.robots() if r['slot'] not in before and r['mine']]
        return new[0] if new else None

    # The robot menu (sub_A720)

    def menu_item(self, menu):
        base, count = menu
        attrs = self.m.read(base, 0x60 * count)
        for k in range(1, count):
            if attrs[0x60 * k] == SELECTED:
                return k
        return None

    def choose(self, menu, item, then=()):
        """Move a list menu's highlight to @p item and fire, then hold @p then; False if the menu did not show"""
        self.stick(set())
        for _ in range(100):
            if self.menu_item(menu):
                break
            self.run(1)
        else:
            return False
        for _ in range(10):
            k = self.menu_item(menu)
            if k == item:
                break
            self.hold_until({'down' if k < item else 'up'}, lambda: self.menu_item(menu), limit=30)
        before = self.menu_item(menu)
        self.stick({'fire'})
        for _ in range(60):
            self.run(1)
            if self.menu_item(menu) != before:
                break
        self.stick(set(then))
        self.run(10)
        return True

    def land_on_robot(self, slot, limit=3000):
        """Fly over our robot in @p slot and sink to its top: the robot menu opens"""
        def where():
            r = next((r for r in self.robots() if r['slot'] == slot), None)
            return (r['x'], r['y']) if r else None
        if not self.fly_to(0, 0, follow=where, limit=limit):
            return False
        for _ in range(0, 400, 2):
            target = where()
            if target is None:
                return False
            if self.m.read(ROBOTS + 16 * slot + 10, 1)[0]:
                return True
            st = self.state()
            buttons = set()
            if st['x'] != target[0]:
                buttons.add('right' if st['x'] < target[0] else 'left')
            if st['y'] != target[1]:
                buttons.add('down' if st['y'] < target[1] else 'up')
            self.stick(buttons)
            self.run(2)
        return False

    def order(self, slot, kind, target):
        """Give our robot in @p slot an order: @p kind DESTROY or CAPTURE, @p target 1-3 (TARGET_MENU)"""
        if not self.land_on_robot(slot):
            return False
        self.choose(MAIN_MENU, GIVE_ORDERS)
        self.choose(ORDERS_MENU, kind)
        self.choose(TARGET_MENU, target)
        self.choose(MAIN_MENU, LEAVE_ROBOT, then={'fire'})  # rise at once, or the menu opens again
        self.climb()
        return self.m.read(ROBOTS + 16 * slot + 11, 1)[0]


PLAY_INTERRUPT = 0xD566
# The build plan, round and round: the parts and the order each robot gets
PLAN = [
    ([BIPOD, CANNON], CAPTURE, 1),                                  # 5: neutral factories
    ([BIPOD, CANNON], CAPTURE, 1),                                  # 5
    ([TRACKS, CANNON, MISSILES], DESTROY, 1),                       # 11: enemy robots
    ([BIPOD, CANNON, ELECTRONICS], CAPTURE, 2),                     # 8: enemy factories
    ([BIPOD, CANNON, MISSILES], DESTROY, 1),                        # 9
    ([TRACKS, MISSILES, PHASERS, ELECTRONICS], CAPTURE, 2),         # 16
    ([ANTIGRAV, PHASERS, MISSILES, CANNON, ELECTRONICS], DESTROY, 1),  # 23
    ([TRACKS, NUCLEAR, CANNON, ELECTRONICS], CAPTURE, 3),           # 30: enemy warbases
]
POOL = {ELECTRONICS: 1, NUCLEAR: 2, PHASERS: 3, MISSILES: 4, CANNON: 5, BIPOD: 6, TRACKS: 6, ANTIGRAV: 6}


def affordable(parts, resources):
    """Each part takes its own resource first, the general one for the rest (sub_CAC1)"""
    pools = list(resources)
    for p in parts:
        own = min(pools[POOL[p]], COST[p])
        pools[POOL[p]] -= own
        pools[0] -= COST[p] - own
    return pools[0] >= 0


def play(g, frames, shots):
    g.key('2')                        # the Kempston stick
    g.key('0', gap=100)               # start
    for _ in range(100):
        if g.state()['handler'] == PLAY_INTERRUPT:
            break
        g.run(10)
    home = next(b for b in g.buildings() if b['type'] == 0)
    g.note(f"game on, warbase at ({home['x']},{home['y']})")
    step, next_shot = 0, 0
    while g.frame < frames:
        st = g.state()
        if g.frame >= next_shot:
            g.screen(os.path.join(shots, f'f{g.frame:06d}.png'))
            mine = sum(r['mine'] for r in g.robots())
            g.note(f"day {st['clock'][2]} {st['clock'][1]:02d}:{st['clock'][0]:02d} resources {st['resources']} "
                   f"robots {mine} vs {len(g.robots()) - mine}")
            next_shot = g.frame + 1500
        if st['handler'] not in (PLAY_INTERRUPT, START_INTERRUPT):
            g.note(f"handler ${st['handler']:04X}: the game ended")
            break
        parts, kind, target = PLAN[step % len(PLAN)]
        if sum(r['mine'] for r in g.robots()) < 24 and affordable(parts, st['resources']):
            if not g.land_on_warbase(home['x'], home['y']):
                g.note('the pad is blocked')
                g.climb()
                g.fly_to(home['x'] + 3, home['y'])
                g.run(100)
                continue
            robot = g.build(parts)
            if robot is None:
                g.note(f'refused {parts}')
                step += 1
                continue
            g.note(f"robot {robot['slot']} parts ${robot['parts']:02X} at ({robot['x']},{robot['y']})")
            order = g.order(robot['slot'], kind, target)
            g.note(f"robot {robot['slot']} order {ORDER_NAMES[order] if order is not False else 'not given'}")
            step += 1
            continue
        # waiting for resources: hover over the warbase, a little away from the pad
        g.fly_to(home['x'] + 2, home['y'] + 2, cruise=30, limit=200)
        g.stick({'fire'} if g.state()['altitude'] < 30 else set())
        g.run(50)
    g.stick(set())


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('command', choices=['launch', 'state', 'play'])
    p.add_argument('--work', required=True)
    p.add_argument('--unreal')
    p.add_argument('--binary')
    p.add_argument('--start')
    p.add_argument('--port-base', type=int, default=9310)  # base+200 must not be 10000, the usual ZRCP port
    p.add_argument('--frames', type=int, default=30000)
    p.add_argument('--record', action='store_true', help='record the run (TTD + analysis), build L1, keep the instance')
    args = p.parse_args()
    g = Game(args.unreal, args.work)
    if args.command in ('launch', 'play') and args.binary:
        process = g.launch(args.binary, args.start, args.port_base, record=args.record)
        print(f'pid {process.pid}, MCP http://127.0.0.1:{args.port_base + 200}/mcp')
        if args.command == 'launch':
            return
    else:
        g.attach()
    if args.command == 'play':
        shots = os.path.join(g.work, 'screens')
        os.makedirs(shots, exist_ok=True)
        try:
            play(g, args.frames, shots)
        finally:
            with open(os.path.join(g.work, 'play.log'), 'w') as f:
                f.write('\n'.join(g.log) + '\n')
        if args.record:
            g.finish()
        return
    print(json.dumps(g.state()))
    for r in g.robots():
        print(r)


if __name__ == '__main__':
    sys.exit(main())
