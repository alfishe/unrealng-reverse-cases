#!/usr/bin/env python3
"""A scripted, recorded session of Advanced Nether Earth for docs 01, 05 and 08: the game menu, the redefine screen,
a new game, a build at the warbase, orders, direct control, combat, the distance menu, the pause, a day of hovering,
then a lost game (Dead End) by a poke; and a second run that wins (Final Cut) by a poke.

The player reads the game's own variables (the addresses of docs/01, 05, 07) and steers the Kempston stick, as
Nether Earth's tools/bot.py does; every input is given at a fixed frame or on a memory condition and the emulator is
exact, so a run gives the same pictures every time. Own instance (offscreen, muted, Pentagon 128 + a Kempston card),
started from the game-menu snapshot work/stage1/explore/gamemenu.szx; killed at the end.

    python3 tools/fig_tour.py tour  [--port-base 12910]   work/docP/tour: session.ttd, events.json, samples.bin,
                                                         states.json, l1.json, play.szx (the game just started)
    python3 tools/fig_tour.py win   [--port-base 12910]   work/docP/win: from play.szx, EnemyBuildings poked to 0
    python3 tools/fig_tour.py lose  [--port-base 12910]   work/docP/lose: from play.szx, PlayerBuildings poked to 0,
                                                         SPACE twice (Dead End, GAME OVER, the menu)
    python3 tools/fig_tour.py draw                         the figures of docs 01, 05, 08 from the folders

Each sample is the screen the ULA shows (bank 5, or bank 7 when $7FFD bit 3 is set: read from state/paging).
"""
import argparse
import json
import os
import sys
import time

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
R = os.path.abspath(os.path.join(CASE, '..', '..'))
sys.path.insert(0, os.path.join(R, 'kit'))
import kitlib as K  # noqa: E402
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

UNREAL = toolpaths.unreal_ng(required=False) or 'unreal-ng'
BINARY = toolpaths.unreal_binary(required=False) or 'unreal-qt'
WORK = os.path.join(CASE, 'work', 'docP')
MENU_SNAPSHOT = os.path.join(CASE, 'work', 'stage1', 'explore', 'gamemenu.szx')

# The game's variables (docs/07, docs/11)
SHIP_Y, SHIP_X, ALTITUDE, INPUT = 0xFD0D, 0xFD0E, 0xFD10, 0xFD0C
MAP = 0xDD00          # 16 rows of 512 cells
ROBOTS = 0xDA00       # 48 records of 16 bytes: 0-23 ours, 24-47 the enemy's
BUILDINGS = 0xFF01    # 56 records of 3 bytes
CURSOR = 0xFD1F       # construction menu: column, part row, parts mask
HANDLER = 0x696A      # the IM 2 handler word (JP at $6969)
MUSIC_INTERRUPT = 0x6780   # the handler outside play: the tune only (menus, construction)
PLAY_INTERRUPT = 0xD566
SELECTED = 0x4E
PLAYER_BUILDINGS, ENEMY_BUILDINGS = 0xFD3A, 0xFD42

BIPOD, TRACKS, ANTIGRAV, CANNON, MISSILES, PHASERS, NUCLEAR, ELECTRONICS = range(8)
MAIN_MENU = (0x5837, 5)
ORDERS_MENU = (0x5897, 6)
TARGET_MENU = (0x5937, 4)
COMBAT_MENU = (0x5837, 7)
DIRECT, GIVE_ORDERS, COMBAT, LEAVE_ROBOT = 1, 2, 3, 4
ADVANCE, DESTROY, CAPTURE = 2, 4, 5

BG, FG, DIMC = K.BACKGROUND, K.TEXT, K.DIM
ACCENT = (255, 200, 80)


def cell_xy(address):
    o = address - MAP
    return o & 0x1FF, o >> 9


class Game:
    """The instance and the player (after Nether Earth's tools/bot.py, with ANE's handler word and model)"""

    def __init__(self, args, work):
        sys.path.insert(0, os.path.join(K.unreal_root(args.unreal), 'tools', 'verification', 'analysis'))
        import corpus  # noqa: E402
        self.corpus = corpus
        self.mcplib = corpus.mcplib
        self.args = args
        self.work = os.path.abspath(work)
        self.held = set()
        self.frame = 0
        self.samples = []
        self.every = 0
        self.label = ''
        self.events = []
        self.states = {}
        self.process = None

    # the instance

    def launch(self, snapshot):
        os.makedirs(self.work, exist_ok=True)
        here = os.getcwd()
        os.chdir(self.work)
        try:
            self.process = self.mcplib.launch(self.args.binary, self.args.port_base)
        finally:
            os.chdir(here)
        s = self.mcplib.Session(f'http://127.0.0.1:{self.args.port_base + 200}/mcp', 'PENTAGON')
        s.fresh_machine('PENTAGON', ram_power_on='zero')
        s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
        for _ in range(100):
            if 'slots_plug slot=edge.1' not in s.call('joystick_input', {'action': 'status'}, ok=False).text:
                break
            time.sleep(0.1)
        s.call('control_execution', {'action': 'pause'}, ok=False)
        s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                              'body': {'muted': True}}, ok=False)
        self.s = s
        self.m = self.corpus.Machine(s, self.args.port_base)
        self.m.post('/snapshot/load', {'path': os.path.abspath(snapshot)})
        raw = self.m.read
        # $C000-$FFFF is the game's bank 0 whatever the pause point paged (the music handlers page bank 1 in a frame)
        self.m.read = lambda a, n: (self.m.read_page('ram', 0)[a - 0xC000:a - 0xC000 + n] if a >= 0xC000
                                    else raw(a, n))
        with open(os.path.join(self.work, 'session.json'), 'w') as f:
            json.dump({'pid': self.process.pid, 'binary': self.args.binary, 'port_base': self.args.port_base,
                       'model': 'PENTAGON', 'ranges': '4000-FFFF'}, f)
        self.m.post('/snapshot/save', {'path': os.path.join(self.work, 'start.szx'), 'force': True})
        with open(os.path.join(self.work, 'start.bin'), 'wb') as f:
            f.write(self.m.read(0, 0x10000))
        s.call('analysis', {'action': 'start', 'record': True})
        print('instance pid', self.process.pid, 'port base', self.args.port_base, flush=True)

    def finish(self):
        self.stick(set())
        self.s.call('analysis', {'action': 'build', 'path': os.path.join(self.work, 'l1.json'), 'wait': 30000})
        state = self.s.call('analysis', {'action': 'status'}).text
        while ': running' in state:
            time.sleep(5)
            state = self.s.call('analysis', {'action': 'status'}).text
        print(state.splitlines()[:3])
        r = self.s.call('time_travel', {'action': 'dump', 'path': os.path.join(self.work, 'session.ttd')}, ok=False)
        print((r.text or '').splitlines()[:1])

    def stop(self):
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(10)
            except Exception:
                self.process.kill()
            self.process = None

    def save_files(self):
        with open(os.path.join(self.work, 'events.json'), 'w') as f:
            json.dump(self.events, f)
        with open(os.path.join(self.work, 'samples.bin'), 'wb') as f:
            for frame, mem, bank in self.samples:
                f.write(frame.to_bytes(4, 'little') + bytes([bank]) + mem)
        with open(os.path.join(self.work, 'states.json'), 'w') as f:
            json.dump({k: [v[0], v[1].hex()] for k, v in self.states.items()}, f)

    # the clock and the screen

    def latch(self):
        for latch in self.m.get('/state/paging').get('latches', []):
            if str(latch.get('port')).upper() in ('0X7FFD', '7FFD'):
                v = latch.get('value')
                return int(v, 0) if isinstance(v, str) else v
        return 0x10

    def poke(self, address, value):
        """An experiment: one byte of the game's bank 0, written when bank 0 is paged at $C000"""
        for _ in range(50):
            if self.latch() & 7 == 0:
                break
            self.run(1)
        assert self.latch() & 7 == 0, 'bank 0 not paged'
        self.s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': hex(address),
                                      'hex': f'{value:02X}'}, ok=False)
        assert self.m.read(address, 1)[0] == value

    def screen(self):
        """(the shown screen's 6912 bytes, its bank)"""
        if self.latch() & 0x08:
            return self.m.read_page('ram', 7)[:6912], 7
        return self.m.read(0x4000, 6912), 5

    def run(self, frames):
        while frames > 0:
            step = frames if not self.every else min(frames, self.every - self.frame % self.every)
            self.s.call('control_execution', {'action': 'run_frames', 'frames': step})
            self.frame += step
            frames -= step
            if self.every and self.frame % self.every == 0:
                self.grab()

    def grab(self):
        mem, bank = self.screen()
        self.samples.append((self.frame, mem, bank))

    def capture(self, every):
        self.every = every
        if every:
            self.grab()

    def ev(self, name):
        self.events.append((self.frame, name))
        print(f'{self.frame:6d} {name}', flush=True)

    def shot(self, name):
        self.states[name] = (self.frame, self.screen()[0])

    # input

    def stick(self, buttons):
        buttons = set(buttons)
        for b in self.held - buttons:
            self.s.call('joystick_input', {'action': 'release', 'buttons': b}, ok=False)
        for b in buttons - self.held:
            self.s.call('joystick_input', {'action': 'press', 'buttons': b}, ok=False)
        self.held = buttons

    def key(self, key, hold=6, gap=20):
        self.s.call('type_input', {'action': 'press', 'key': key}, ok=False)
        self.run(hold)
        self.s.call('type_input', {'action': 'release', 'key': key}, ok=False)
        self.run(gap)

    def hold_until(self, buttons, probe, limit=60, step=1):
        before = probe()
        self.stick(buttons)
        for _ in range(0, limit, step):
            self.run(step)
            if probe() != before:
                break
        self.stick(set())
        self.run(2)
        return probe() != before

    def wait_for(self, probe, limit=600, step=1):
        for _ in range(0, limit, step):
            if probe():
                return True
            self.run(step)
        return probe()

    # reading the game

    def word(self, address):
        v = self.m.read(address, 2)
        return v[0] | v[1] << 8

    def handler(self):
        return self.word(HANDLER)

    def state(self):
        v = self.m.read(0xFD00, 0x60)
        return {'x': v[0x0E] | v[0x0F] << 8, 'y': v[0x0D], 'altitude': v[0x10], 'resources': list(v[0x22:0x29]),
                'clock': list(v[0x35:0x38])}

    def robots(self):
        mem = self.m.read(ROBOTS, 48 * 16)
        out = []
        for i in range(48):
            r = mem[16 * i:16 * i + 16]
            if not r[1]:
                continue
            x, y = cell_xy(r[0] | r[1] << 8)
            out.append({'slot': i, 'mine': i < 24, 'x': x, 'y': y, 'parts': r[7], 'menu': r[10], 'order': r[11]})
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

    def cursor(self):
        return tuple(self.m.read(CURSOR, 3))

    # flying and the menus

    def fly_to(self, x, y, cruise=40, limit=3000, follow=None):
        for _ in range(0, limit, 2):
            if follow:
                t = follow()
                if t is None:
                    return False
                x, y = t
            st = self.state()
            if st['x'] == x and st['y'] == y:
                self.stick(set())
                return True
            b = set()
            if st['x'] != x:
                b.add('right' if st['x'] < x else 'left')
            if st['y'] != y:
                b.add('down' if st['y'] < y else 'up')
            if st['altitude'] < cruise:
                b.add('fire')
            self.stick(b)
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

    def land_on_warbase(self, x, y):
        self.fly_to(x, y)
        self.stick(set())
        for _ in range(200):
            self.run(2)
            if self.handler() == MUSIC_INTERRUPT:
                for _ in range(100):
                    self.run(2)
                    if self.cursor() == (2, 0, 0):
                        self.run(10)
                        return True
                return False
        return False

    def goto(self, column, part=0):
        for _ in range(20):
            c = self.cursor()
            if c[0] != column:
                self.hold_until({'right' if c[0] < column else 'left'}, self.cursor)
            elif column == 2 and c[1] != part:
                self.hold_until({'up' if c[1] < part else 'down'}, self.cursor)
            else:
                return True
        return False

    def build(self, parts):
        want = sum(1 << p for p in parts)
        before = {r['slot'] for r in self.robots()}
        for _ in range(3):
            for p in range(8):
                if (self.cursor()[2] ^ want) >> p & 1:
                    self.goto(2, p)
                    self.hold_until({'fire'}, lambda: self.cursor()[2])
            if self.cursor()[2] == want:
                break
        made = self.cursor()[2] == want
        for _ in range(3):
            self.goto(1 if made else 0)
            if self.hold_until({'fire'}, lambda: self.m.read(HANDLER, 2), limit=400):
                break
        self.climb()
        new = [r for r in self.robots() if r['slot'] not in before and r['mine']]
        return new[0] if new else None

    def menu_item(self, menu):
        base, count = menu
        attrs = self.m.read(base, 0x60 * count)
        for k in range(1, count):
            if attrs[0x60 * k] == SELECTED:
                return k
        return None

    def choose(self, menu, item, then=()):
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
        def where():
            r = next((r for r in self.robots() if r['slot'] == slot), None)
            return (r['x'], r['y']) if r else None
        if not self.fly_to(0, 0, follow=where, limit=limit):
            return False
        for _ in range(0, 400, 2):
            t = where()
            if t is None:
                return False
            if self.m.read(ROBOTS + 16 * slot + 10, 1)[0]:
                return True
            st = self.state()
            b = set()
            if st['x'] != t[0]:
                b.add('right' if st['x'] < t[0] else 'left')
            if st['y'] != t[1]:
                b.add('down' if st['y'] < t[1] else 'up')
            self.stick(b)
            self.run(2)
        return False

    def toggle(self, part, name):
        self.goto(2, part)
        self.ev(name)
        self.hold_until({'fire'}, lambda: (self.cursor()[2], tuple(self.m.read(0xFD29, 7))), limit=40)
        self.run(14)


def tour(g):
    g.ev('the game menu, the AY tune playing')
    g.run(60)
    g.shot('menu')
    g.run(300)
    g.ev('key 4: REDEFINE KEYS')
    g.key('4', hold=6, gap=40)
    g.shot('redefine')
    for k, name in (('q', 'UP: Q'), ('a', 'DOWN: A'), ('o', 'LEFT: O'), ('p', 'RIGHT: P'),
                    ('ss', 'FIRE: SYMBOL SHIFT'), ('1', 'PAUSE: 1'), ('i', 'ABORT: I'), ('5', 'SAVE: 5')):
        g.ev('redefine ' + name)
        g.key(k, hold=6, gap=34)
        if name.startswith('ABORT'):
            g.shot('redefine-full')
    g.ev('the eighth key: back to the menu')
    print('KeyTable', g.m.read(0xD3CC, 25).hex(' '), flush=True)
    g.run(150)
    g.shot('menu-after-redefine')
    g.ev('key 2: KEMPSTON')
    g.key('2', hold=6, gap=40)
    g.shot('menu-kempston')
    g.ev('key 0: START GAME')
    g.key('0', hold=6, gap=20)
    g.wait_for(lambda: g.handler() == PLAY_INTERRUPT, limit=600, step=2)
    g.ev('a new game: the ship climbs')
    g.m.post('/snapshot/save', {'path': os.path.join(g.work, 'play.szx'), 'force': True})
    g.run(20)
    g.shot('play')
    home = next(b for b in g.buildings() if b['type'] == 0)
    g.ev(f'fly to the warbase pad ({home["x"]},{home["y"]})')
    g.fly_to(home['x'], home['y'])
    g.ev('sink onto the pad (altitude 15)')
    g.stick(set())
    for _ in range(200):
        g.run(2)
        if g.handler() == MUSIC_INTERRUPT:
            break
    g.ev('the construction menu opens')
    g.wait_for(lambda: g.cursor() == (2, 0, 0), limit=200, step=2)
    g.run(10)
    g.shot('construction')
    g.toggle(BIPOD, 'fire on BIPOD: 3 paid from the general resource')
    g.toggle(TRACKS, 'fire on TRACKS: replaces the bipod (3 back, 5 paid)')
    g.toggle(CANNON, 'fire on CANNON: 2 paid')
    g.toggle(NUCLEAR, 'fire on NUCLEAR: 20 is more than the 13 left: refused')
    g.toggle(MISSILES, 'fire on MISSILES: 4 paid')
    g.shot('construction-parts')
    g.toggle(MISSILES, 'fire on MISSILES again: taken back, 4 refunded')
    g.ev('START ROBOT')
    before = {r['slot'] for r in g.robots()}
    g.goto(1)
    g.hold_until({'fire'}, lambda: g.m.read(HANDLER, 2), limit=400)
    g.ev('the robot stands at the warbase door; the ship climbs')
    g.climb()
    r1 = next(r for r in g.robots() if r['slot'] not in before and r['mine'])
    g.run(40)
    g.ev('land on the robot')
    g.land_on_robot(r1['slot'])
    g.run(4)
    g.ev('the robot menu')
    g.run(12)
    g.shot('robot-menu')
    g.ev('GIVE ORDERS')
    g.choose(MAIN_MENU, GIVE_ORDERS)
    g.shot('orders')
    g.ev('SEARCH & CAPTURE')
    g.choose(ORDERS_MENU, CAPTURE)
    g.shot('target')
    g.ev('SELECT TARGET: NEUTRAL FACTORIES')
    g.choose(TARGET_MENU, 1)
    g.ev('LEAVE ROBOT, fire held: the ship climbs away')
    g.choose(MAIN_MENU, LEAVE_ROBOT, then={'fire'})
    g.climb()
    g.ev('the robot sets off for the nearest neutral factory')
    g.run(240)
    g.ev('back to the pad: a second robot')
    g.land_on_warbase(home['x'], home['y'])
    r2 = g.build([BIPOD, CANNON])
    g.run(30)
    g.ev('land on the second robot')
    g.land_on_robot(r2['slot'])
    g.run(10)
    rec = ROBOTS + 16 * r2['slot']
    where = lambda: tuple(g.m.read(rec, 2))  # noqa: E731
    g.ev('DIRECT CONTROL')
    g.choose(MAIN_MENU, DIRECT)
    g.run(10)
    g.ev('direct control: down, the robot turns, then steps')
    g.hold_until({'down'}, where, limit=200)
    for n in range(3):
        g.ev('direct control: right' + (', a turn first' if n == 0 else ''))
        g.hold_until({'right'}, where, limit=200)
        if n == 1:
            g.shot('direct')
    g.run(10)
    g.ev('fire: the robot menu again')
    g.hold_until({'fire'}, lambda: g.m.read(rec + 10, 1), limit=60)
    g.run(20)
    g.ev('COMBAT MODE')
    g.choose(MAIN_MENU, COMBAT)
    g.shot('combat')
    g.ev('FIRE CANNON: a shot in record 0')
    g.choose(COMBAT_MENU, 4)
    g.wait_for(lambda: g.m.read(0xD7D4, 1) != b'\0', limit=40)
    g.ev('the shot flies, 2 cells a turn')
    g.wait_for(lambda: g.m.read(0xD7D4, 1) == b'\0', limit=200)
    g.ev('the shot ends')
    g.run(30)
    g.ev('STOP COMBAT')
    g.choose(COMBAT_MENU, 6)
    g.run(10)
    g.ev('GIVE ORDERS')
    g.choose(MAIN_MENU, GIVE_ORDERS)
    g.ev('ADVANCE ?? MILES')
    g.choose(ORDERS_MENU, ADVANCE)
    g.run(20)
    g.shot('distance')
    miles = lambda: b''.join(g.m.read(K.screen_address(104 + k, 23), 3) for k in range(8))  # noqa: E731
    for n in (5, 10, 15, 20, 25):
        g.ev(f'up: {n} MILES')
        g.hold_until({'up'}, miles, limit=40)
        g.run(12)
    g.ev('down: 20 MILES')
    g.hold_until({'down'}, miles, limit=40)
    g.run(12)
    g.ev('fire: ADVANCE 20 MILES')
    g.hold_until({'fire'}, lambda: g.m.read(rec + 11, 1), limit=40)
    g.run(30)
    g.shot('robot-menu-advance')
    print('robot', r2['slot'], g.m.read(rec, 16).hex(' '), flush=True)
    g.ev('LEAVE ROBOT')
    g.choose(MAIN_MENU, LEAVE_ROBOT, then={'fire'})
    g.climb()
    g.run(100)
    g.ev('key 1: pause')
    g.s.call('type_input', {'action': 'press', 'key': '1'}, ok=False)
    g.run(30)
    g.s.call('type_input', {'action': 'release', 'key': '1'}, ok=False)
    g.run(40)
    g.shot('pause')
    g.ev('fire ends the pause')
    g.stick({'fire'})
    g.run(6)
    g.stick(set())
    g.ev('hover: the world runs, the day turns')
    g.capture(10)
    while True:
        v = g.m.read(0xFD35, 4)
        if (v[2] | v[3] << 8) >= 1 and v[1] >= 3:
            break
        g.run(50)
    g.shot('play-day1')
    g.capture(2)
    g.ev('PlayerBuildings $FD3A poked to 0 (an experiment): the game is lost')
    g.poke(PLAYER_BUILDINGS, 0)
    g.run(40)
    g.ev('Dead End')
    g.capture(4)
    last, same = None, 0
    for n in range(0, 4000, 20):
        g.run(20)
        if n in (200, 600, 1200, 2000):
            g.shot(f'deadend-{n}')
        cur = g.screen()[0]
        same = same + 1 if cur == last else 0
        last = cur
    g.ev('end')


def lose(g):
    g.ev('play, a moment after the start')
    g.capture(4)
    g.run(100)
    g.ev('PlayerBuildings $FD3A poked to 0 (an experiment): the game is lost')
    g.poke(PLAYER_BUILDINGS, 0)
    g.run(40)
    g.ev('Dead End: the picture and its tune, until a key')
    g.run(600)
    g.shot('deadend-picture')
    g.ev('SPACE')
    g.key('space', hold=6, gap=10)
    g.ev('GAME OVER on the stars, until a key')
    g.run(600)
    g.shot('deadend-gameover')
    g.ev('SPACE: back to the game menu')
    g.key('space', hold=6, gap=10)
    g.run(400)
    g.shot('deadend-menu')
    print('handler', hex(g.handler()), 'latch', hex(g.latch()), flush=True)
    g.ev('end')


def win(g):
    g.ev('play, a moment after the start')
    g.capture(4)
    g.run(100)
    g.ev('EnemyBuildings $FD42 poked to 0 (an experiment): the game is won')
    g.poke(ENEMY_BUILDINGS, 0)
    for n in range(0, 9000, 20):
        g.run(20)
        if n % 500 == 0:
            g.shot(f'finalcut-{n}')
    g.ev('SPACE')
    g.key('space', hold=6, gap=10)
    g.run(1500)
    g.shot('finalcut-after')
    print('handler', hex(g.handler()), 'latch', hex(g.latch()), flush=True)
    g.ev('end')


def cmd_record(args, which):
    work = os.path.join(WORK, which)
    g = Game(args, work)
    start = MENU_SNAPSHOT if which == 'tour' else os.path.join(WORK, 'tour', 'play.szx')
    g.launch(start)
    try:
        g.capture(2)
        {'tour': tour, 'win': win, 'lose': lose}[which](g)
        g.capture(0)
        g.save_files()
        g.finish()
    finally:
        g.stop()


# ---------------------------------------------------------------------------------------------------------------
# drawing


def load(which):
    work = os.path.join(WORK, which)
    events = [tuple(e) for e in json.load(open(os.path.join(work, 'events.json')))]
    raw = open(os.path.join(work, 'samples.bin'), 'rb').read()
    samples = []
    for at in range(0, len(raw), 6917):
        samples.append((int.from_bytes(raw[at:at + 4], 'little'), raw[at + 5:at + 6917]))
    states = {k: (v[0], bytes.fromhex(v[1])) for k, v in json.load(open(os.path.join(work, 'states.json'))).items()}
    return events, samples, states


def text(d, xy, s, size=12, fill=FG, anchor='la'):
    d.text(xy, s, font=K.font(size), fill=fill, anchor=anchor)


def zx(mem):
    return K.render_screen(mem, 0)


def label_at(events, frame):
    name = ''
    for f, n in events:
        if f <= frame:
            name = n
    return name


def event_frame(events, name, nth=0):
    return [f for f, n in events if n.startswith(name)][nth]


def screen_gif(path, samples, events, f0, f1, step=2, crop=None, scale=2, title='', delay=40, labels=None):
    pictures, durations, last = [], [], None
    for frame, mem in samples:
        if not (f0 <= frame < f1) or (last is not None and frame - last < step):
            continue
        last = frame
        img = zx(mem)
        if crop:
            img = img.crop(crop)
        img = img.resize((img.size[0] * scale, img.size[1] * scale), Image.NEAREST)
        w = max(img.size[0], 440)
        pic = Image.new('RGB', (w, img.size[1] + 46), BG)
        pic.paste(img, (0, 0))
        d = ImageDraw.Draw(pic)
        text(d, (6, img.size[1] + 4), f'{title}  frame {frame}', 12, DIMC)
        lab = labels(frame) if labels else label_at(events, frame)
        text(d, (6, img.size[1] + 22), lab, 14, ACCENT)
        pictures.append(pic)
        durations.append(delay)
    durations[0] = 1200
    durations[-1] = 2500
    K.save_gif(path, pictures, durations)
    print(f'{path}: {len(pictures)} pictures, {os.path.getsize(path) // 1024} KB')


def png(mem, path, scale=2):
    zx(mem).resize((256 * scale, 192 * scale), Image.NEAREST).save(path)
    print(path)


# The annotated screens: (row, Russian as printed, English, what it is); rows in character cells
PANEL = [(0, 'ДЕНЬ:', 'DAY:', 'the day, $FD37 ($D1C5)'), (1, 'ЧАС:', 'HOUR:', 'the clock hh.mm, $FD35 / $FD36'),
         (3, 'СТАТУС', 'STATUS', 'the counts below, aliens | humans'),
         (4, 'ИНОП.   ЛЮДИ', 'ALIENS  HUMANS', 'left column the enemy, right us'),
         (6, 'БАЗЫ', 'WARBASES', 'warbases each side holds'), (7, 'ЭЛЕКТР.', 'ELECTR.', 'electronics factories'),
         (8, 'А-БОМБЫ', 'A-BOMBS', 'nuclear factories'), (9, 'ФАЗОРЫ', 'PHASERS', 'phaser factories'),
         (10, 'РАКЕТЫ', 'MISSILES', 'missile factories'), (11, 'ПУШКИ', 'CANNONS', 'cannon factories'),
         (12, 'ШАССИ', 'CHASSIS', 'chassis factories'), (13, 'РОБОТЫ', 'ROBOTS', 'robots on the map'),
         (15, 'РЕСУРСЫ', 'RESOURCES', 'our resources, in space dollars'),
         (17, 'ОБЩИЕ', 'GENERAL', 'general resource $FD22: buys any part'),
         (18, 'ЭЛЕКТР.', 'ELECTR.', 'electronics'), (19, 'АТОМН.', 'NUCLEAR', 'nuclear (A-bombs)'),
         (20, 'ФАЗОРЫ', 'PHASERS', 'phasers'), (21, 'РАКЕТЫ', 'MISSILES', 'missiles'),
         (22, 'ПУШКИ', 'CANNONS', 'cannons'), (23, 'ШАССИ', 'CHASSIS', 'chassis')]

MENUS = [
    ('robot-menu', 'The robot menu ($A738)', [
        (4, 'ПРЯМОЕ УПРАВЛ.', 'DIRECT CONTROL'), (7, 'ОТДАТЬ ПРИКАЗ', 'GIVE ORDERS'),
        (10, 'БОЕВОИ РЕЖИМ', 'COMBAT MODE (И for Й)'), (13, 'ОСТАВИТЬ РОБОТА', 'LEAVE ROBOT'),
        (17, 'ПРИКАЗ', 'ORDERS: the current one'), (18, 'СТОЯТЬ И ДЕРЖАТЬ ОБОРОНУ', 'STOP AND DEFEND'),
        (22, 'СИЛА 100%', 'STRENGTH 100%')]),
    ('orders', 'Give orders ($A977)', [
        (4, 'ОТДАТЬ ПРИКАЗ', 'GIVE ORDERS (title)'), (7, 'ДЕРЖАТЫ ОБОРОНУ', 'DEFEND (Ы for Ь: a slip)'),
        (10, 'ВПЕРЕД ?? МИЛЬ', 'ADVANCE ?? MILES'), (13, 'НАЗАД ?? МИЛЬ', 'RETREAT ?? MILES'),
        (16, 'ПОИСК И ЛИКВИД.', 'SEARCH & DESTROY'), (19, 'ПОИСК И ЗАХВАТ', 'SEARCH & CAPTURE')]),
    ('target', 'The capture targets ($AB54)', [
        (4, 'ПОИСК И ЗАХВАТ', 'SEARCH & CAPTURE (green: slip)'), (8, 'ВЫБОР ЦЕЛИ', 'SELECT TARGET'),
        (12, 'НЕЙТР. ЗАВОДЫ', 'NEUTRAL FACTORIES'), (15, 'ВРАЖЕСК. ЗАВОДЫ', 'ENEMY FACTORIES'),
        (18, 'ВРАЖЕСК. БАЗЫ', 'ENEMY WARBASES')]),
    ('combat', 'Combat mode ($AC06)', [
        (4, 'АТОМНАЯ БОМБА', 'NUCLEAR BOMB'), (7, 'ОГОНЬ ФАЗОРОВ', 'FIRE PHASERS'),
        (10, 'ОГОНЬ РАКЕТ', 'FIRE MISSILES'), (13, 'ОГОНЬ ПУШЕК', 'FIRE CANNON'), (16, 'ДВИЖЕНИЕ', 'MOVE'),
        (19, 'ВЫХОД ИЗ МЕНЮ', 'EXIT MENU (stop combat)')]),
    ('distance', 'The distance ($AA1F, $AA43)', [
        (5, 'ВПЕРЕД ?? МИЛЬ', 'ADVANCE ?? MILES'), (9, 'ВЫБОР ДИСТАН.', 'SELECT DISTANCE'),
        (13, '0 МИЛЬ', '0 MILES: up / down, 5 a step')]),
    ('direct', 'Direct control: no item lit', [
        (4, 'ПРЯМОЕ УПРАВЛ.', 'the stick drives the robot'), (13, 'ОСТАВИТЬ РОБОТА', 'fire: the menu lights again'),
        (17, 'ПРИКАЗ', 'the order is kept')])]

CONSTRUCTION_LEFT = [(0, 'ЦЕХ РОБОТОВ', 'ROBOT FACTORY (title)'), (6, '-- НАЛИЧНЫЕ --', 'RESOURCES IN HAND'),
                     (9, 'ОБЩИЕ', 'general'), (11, 'ЭЛЕКТРОНИКА', 'electronics'), (12, 'А-БОМБЫ', 'A-bombs'),
                     (13, 'ФАЗОРЫ', 'phasers'), (14, 'РАКЕТЫ', 'missiles'), (15, 'ПУШКИ', 'cannons'),
                     (16, 'ШАССИ', 'chassis'), (18, 'ВСЕГО', 'TOTAL: what is left'),
                     (21, 'ВЫ-ХОД  ВЫ-ПУСК', 'EXIT   START ROBOT')]
CONSTRUCTION_RIGHT = [(1, 'ЭЛЕКТРОНИКА 3', 'ELECTRONICS, 3'), (4, 'А-БОМБЫ 20', 'NUCLEAR BOMB, 20'),
                      (7, 'ФАЗОРЫ 4', 'PHASERS, 4'), (10, 'РАКЕТЫ 4', 'MISSILES, 4'), (13, 'ПУШКИ 2', 'CANNON, 2'),
                      (16, 'АНТИГРАВЫ 10', 'ANTIGRAVITY, 10'), (19, 'ТРАКИ 5', 'TRACKS, 5'),
                      (22, 'БИПОД 3', 'BIPOD, 3')]


def legend(d, x, rows, top, scale, side, x_mark, colour=ACCENT):
    """One entry per row, level with it; a line from the mark at x_mark to the entry"""
    for row, ru, en, *more in rows:
        y = top + row * 8 * scale + 4 * scale
        if side == 'right':
            d.line([x_mark, y, x - 6, y], fill=colour)
            text(d, (x, y - 9), en, 13, colour)
            if more:
                text(d, (x + 8 + 8 * len(en), y - 8), more[0], 12, DIMC)
        else:
            d.line([x + 6, y, x_mark, y], fill=colour)
            text(d, (x, y - 9), en, 13, colour, anchor='ra')


def draw_panel(st, path):
    scale, top = 3, 64
    pic = Image.new('RGB', (256 * scale + 560, 192 * scale + top + 50), BG)
    pic.paste(zx(st['play-day1'][1]).resize((256 * scale, 192 * scale), Image.NEAREST), (0, top))
    d = ImageDraw.Draw(pic)
    text(d, (8, 6), 'The play screen: map left, the panel right (columns 22-31), the radar strip below', 17)
    text(d, (8, 32), f'tour frame {st["play-day1"][0]} (day 1, 03.00); every Russian label with its English and '
         'what its numbers count', 12, DIMC)
    legend(d, 256 * scale + 16, PANEL, top, scale, 'right', 256 * scale)
    radar = (120, 200, 255)
    d.rectangle([0, top + 22 * 8 * scale, 22 * 8 * scale - 1, top + 24 * 8 * scale - 1], outline=radar, width=2)
    d.rectangle([0, top, 22 * 8 * scale - 1, top + 22 * 8 * scale - 1], outline=(150, 150, 170), width=2)
    y = top + 192 * scale + 8
    text(d, (8, y), 'grey frame: the map window, 22 x 22 cells, our ship over our warbase (the H pad)', 13,
         (150, 150, 170))
    text(d, (8, y + 20), 'blue frame: РАДАР: = RADAR, the whole map in a strip; our ship flashes', 13, radar)
    pic.save(path)
    print(path)


def draw_menus(st, path):
    scale, cw, top = 2, 410, 70
    pic = Image.new('RGB', (3 * cw + 10, top + 2 * (192 * scale + 40)), BG)
    d = ImageDraw.Draw(pic)
    text(d, (8, 6), "The robot's menus in the panel: every item and what it does", 17)
    text(d, (8, 32), 'tour states (the frame in each title); the menu text at columns 22-31, its English level with it; '
         'the string address in each title', 12, DIMC)
    for i, (state, title, rows) in enumerate(MENUS):
        x0, y0 = 8 + (i % 3) * cw, top + (i // 3) * (192 * scale + 40)
        crop = zx(st[state][1]).crop((176, 0, 256, 192)).resize((80 * scale, 192 * scale), Image.NEAREST)
        pic.paste(crop, (x0, y0 + 20))
        text(d, (x0, y0), f'{title}, frame {st[state][0]}', 13, FG)
        legend(d, x0 + 80 * scale + 14, [(r, ru, en) for r, ru, en in rows], y0 + 20, scale, 'right',
               x0 + 80 * scale)
    pic.save(path)
    print(path)


def draw_construction(st, path):
    scale, top, side = 3, 64, 250
    pic = Image.new('RGB', (256 * scale + 2 * side, 192 * scale + top + 10), BG)
    pic.paste(zx(st['construction-parts'][1]).resize((256 * scale, 192 * scale), Image.NEAREST), (side, top))
    d = ImageDraw.Draw(pic)
    text(d, (8, 6), 'The construction menu: the resources in hand left, the eight parts with their prices right', 17)
    text(d, (8, 32), f'tour frame {st["construction-parts"][0]} (tracks, cannon, missiles on the robot: '
         '20 - 5 - 2 - 4 = 9 left); '
         'strings at $C8BE', 12, DIMC)
    legend(d, side - 12, CONSTRUCTION_LEFT, top, scale, 'left', side)
    legend(d, side + 256 * scale + 12, CONSTRUCTION_RIGHT, top, scale, 'right', side + 256 * scale)
    pic.save(path)
    print(path)


ENDINGS = [('lose', 400, 'Dead End', 'БАЗА ЛЮДЕЙ ЗАХВАЧЕНА!'), ('lose', 1000, 'a key: GAME OVER', 'a second key: the menu'),
           ('lose', 1600, 'the game menu again', 'a new game may start'),
           ('win', 700, 'Final Cut: the picture', 'its caption: docs/08'),
           ('win', 1600, 'the scroller', '8 letters a row, English'),
           ('win', 2500, 'the scroller goes on', '... YOU ARE REAL HERO ...'),
           ('win', 4700, 'its last lines', 'GAME OVER (C) 1998 ...'),
           ('win', 8000, 'Victory is with U!!!', 'stays (SPACE at 9100)')]


def draw_endings(path):
    runs = {w: load(w)[1] for w in ('lose', 'win')}
    cw, ch, top = 270, 192 + 46, 64
    pic = Image.new('RGB', (4 * cw + 10, top + 2 * ch + 30), BG)
    d = ImageDraw.Draw(pic)
    text(d, (8, 6), 'The two endings: Dead End returns to the game menu, Final Cut never returns', 17)
    text(d, (8, 32), 'top: run lose (PlayerBuildings $FD3A poked to 0 at frame 100); bottom: run win (EnemyBuildings '
         '$FD42 poked to 0 at 100); the run frame under each', 12, DIMC)
    for i, (run, frame, title, note) in enumerate(ENDINGS):
        x0, y0 = 8 + (i % 4) * cw, top + (i // 4) * (ch + 14)
        f, mem = min(runs[run], key=lambda x: abs(x[0] - frame))
        pic.paste(zx(mem), (x0, y0))
        text(d, (x0, y0 + 196), f'{run} {f}: {title}', 12, ACCENT)
        text(d, (x0, y0 + 212), note, 11, DIMC)
    pic.save(path)
    print(path)


def cmd_draw(args):
    out = os.path.join(CASE, 'docs', 'img')
    ui = os.path.join(out, 'ui')
    os.makedirs(ui, exist_ok=True)
    ev, sm, st = load('tour')
    draw_panel(st, os.path.join(ui, 'play-panel.png'))
    draw_menus(st, os.path.join(ui, 'robot-menus.png'))
    draw_construction(st, os.path.join(ui, 'construction-menu.png'))
    draw_endings(os.path.join(ui, 'endings.png'))
    for name in ('menu', 'redefine-full'):
        if name in st:
            png(st[name][1], os.path.join(ui, f'state-{name}.png'))
    f_start = event_frame(ev, 'a new game')
    f_leave = event_frame(ev, 'the robot sets off')
    screen_gif(os.path.join(ui, 'play-first-robot.gif'), sm, ev, f_start - 10, f_leave + 240, step=6, title='tour')
    screen_gif(os.path.join(ui, 'menu-construction.gif'), sm, ev, event_frame(ev, 'the construction menu opens'),
               event_frame(ev, 'the robot stands') + 20, title='tour')
    screen_gif(os.path.join(ui, 'menu-orders.gif'), sm, ev, event_frame(ev, 'the robot menu') - 40,
               f_leave + 60, title='tour')
    screen_gif(os.path.join(ui, 'menu-combat.gif'), sm, ev, event_frame(ev, 'COMBAT MODE'),
               event_frame(ev, 'STOP COMBAT') + 40, title='tour')
    screen_gif(os.path.join(ui, 'direct-control.gif'), sm, ev, event_frame(ev, 'DIRECT CONTROL'),
               event_frame(ev, 'COMBAT MODE'), step=4, title='tour')
    screen_gif(os.path.join(ui, 'menu-distance.gif'), sm, ev, event_frame(ev, 'ADVANCE ?? MILES') - 30,
               event_frame(ev, 'LEAVE ROBOT', 1) + 20, title='tour')
    screen_gif(os.path.join(ui, 'menu-redefine.gif'), sm, ev, event_frame(ev, 'key 4'),
               event_frame(ev, 'key 2'), title='tour')
    if os.path.exists(os.path.join(WORK, 'lose', 'events.json')):
        ev3, sm3, _ = load('lose')
        f_dead = event_frame(ev3, 'PlayerBuildings')
        screen_gif(os.path.join(ui, 'dead-end.gif'), sm3, ev3, f_dead - 20, ev3[-1][0], step=20, title='lose',
                   delay=80)
    if os.path.exists(os.path.join(WORK, 'win', 'events.json')):
        ev2, sm2, _ = load('win')
        f_win = event_frame(ev2, 'EnemyBuildings')
        screen_gif(os.path.join(ui, 'final-cut.gif'), sm2, ev2, f_win - 20, f_win + 5400, step=40, title='win',
                   delay=80)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('command', choices=['tour', 'win', 'lose', 'draw'])
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', UNREAL))
    p.add_argument('--binary', default=BINARY)
    p.add_argument('--port-base', type=int, default=12910)
    args = p.parse_args()
    if args.command == 'draw':
        cmd_draw(args)
    else:
        cmd_record(args, args.command)


if __name__ == '__main__':
    main()
