#!/usr/bin/env python3
"""Figures of Nether Earth GS at work (docs 01, 04, 05): GIFs of each menu driven by a script, the state machine with
a screen per state, the keyboard map, an annotated play screen.

Every picture comes from an own unreal-qt instance (Pentagon 128 + GS 512 KB, offscreen, muted) started by
gs_session.py and loaded with the main menu snapshot work/gsA/deep/start.szx, then driven through play_gs.KeyGame
(the bot that reads the game's variables, steering by the keyboard). Every input is given at a fixed frame or on a
memory condition, so a run gives the same pictures every time. The instance is stopped at the end.

    python3 tools/fig_ui.py tour   [--port-base 15670]   the scripted session: docs/img/ui/menu-*.gif,
                                                         play-first-robot.gif, direct-control.gif, and
                                                         work/gsA/tour (events, screen samples, states, TTD)
    python3 tools/fig_ui.py draw-tour                    the GIFs again from work/gsA/tour
    python3 tools/fig_ui.py keys                         docs/img/ui/keyboard-map.png (KeyTable of neart001)
    python3 tools/fig_ui.py states                       docs/img/ui/state-machine.png (from the tour's states)
    python3 tools/fig_ui.py annotate                     docs/img/ui/play-annotated.png (a tour frame and the
                                                         variables read at it)

The code is NE's tools/ill_ui.py (copied, not imported), cut to these commands and pointed at this case.
"""
import argparse
import json
import math
import os
import subprocess
import sys
import time

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
KIT = os.path.abspath(os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, KIT)
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402
import play_gs  # noqa: E402
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402
bot = play_gs.bot

UNREAL = toolpaths.unreal_ng(required=False) or 'unreal-ng'
BINARY = os.path.join(UNREAL, 'cmake-build-agent-release/bin/unreal-qt.app/Contents/MacOS/unreal-qt')
WORK = os.path.join(CASE, 'work', 'gsA')
START = os.path.join(WORK, 'deep', 'start.szx')
IMAGE = os.path.join(CASE, 'build', 'game', 'neart001-scl.bin')    # neart001, loaded at $6590
IMAGE_AT = 0x6590
FRAME_T = 71680

# ---------------------------------------------------------------------------------------------------------------
# drawing helpers

BG = K.BACKGROUND
FG = K.TEXT
DIMC = K.DIM
ACCENT = (255, 200, 80)


def text(draw, xy, s, size=12, fill=FG, anchor='la'):
    draw.text(xy, s, font=K.font(size), fill=fill, anchor=anchor)


def zx(mem, flash=False):
    """The 6912 bytes of a screen as a 256 x 192 RGB picture; flash: the inverted phase of FLASH cells"""
    image = K.render_screen(mem, 0)
    if flash:
        px = image.load()
        for row in range(24):
            for col in range(32):
                if mem[0x1800 + row * 32 + col] & 0x80:
                    attr = mem[0x1800 + row * 32 + col]
                    ink = K.ink_colour(attr & 7, attr & 0x40)
                    paper = K.ink_colour((attr >> 3) & 7, attr & 0x40)
                    for y in range(row * 8, row * 8 + 8):
                        for x in range(col * 8, col * 8 + 8):
                            px[x, y] = paper if px[x, y] == ink else ink
    return image


def caption_bar(width, lines, size=13, pad=6):
    h = pad * 2 + len(lines) * (size + 4)
    bar = Image.new('RGB', (width, h), BG)
    d = ImageDraw.Draw(bar)
    for i, (s, colour) in enumerate(lines):
        text(d, (pad, pad + i * (size + 4)), s, size, colour)
    return bar


def stack(*images, bg=BG):
    w = max(i.size[0] for i in images)
    h = sum(i.size[1] for i in images)
    out = Image.new('RGB', (w, h), bg)
    y = 0
    for i in images:
        out.paste(i, (0, y))
        y += i.size[1]
    return out


def save_gif(path, pictures, durations):
    K.save_gif(path, pictures, durations)
    print(f'{path}: {len(pictures)} pictures, {os.path.getsize(path) // 1024} KB')


# ---------------------------------------------------------------------------------------------------------------
# the instance


class Rig(play_gs.KeyGame):
    """KeyGame with frame capture: every run() can sample the screen"""

    def __init__(self, args, work):
        os.makedirs(work, exist_ok=True)
        self.args = args
        gs = os.path.join(HERE, 'gs_session.py')
        env = dict(os.environ, UNREAL_NG=UNREAL)
        subprocess.run([sys.executable, gs, 'launch', '--work', work, '--port-base', str(args.port_base),
                        '--binary', args.binary, '--card', 'gs', '--card-ram', '512k'], check=True, env=env)
        subprocess.run([sys.executable, gs, 'steps', '--work', work, 'load:' + START, 'ttd:start'], check=True,
                       env=env)
        super().__init__(work, os.path.join(work, 'shots'))
        self.attach()
        self.process = True
        self.samples = []      # (frame, screen bytes, label)
        self.every = 0
        self.label = ''

    def shot(self, name):
        pass

    def choose(self, menu, item, then=()):
        for _ in range(100):
            if self.menu_item(menu):
                break
            self.run(1)
        return bot.Game.choose(self, menu, item, then)

    def start(self, snapshot=None, record=False):
        print('instance port base', self.args.port_base, flush=True)
        return self

    def stop(self):
        if self.process:
            subprocess.run([sys.executable, os.path.join(HERE, 'gs_session.py'), 'stop', '--work', self.work],
                           env=dict(os.environ, UNREAL_NG=UNREAL))
            self.process = None

    def feature(self, name, on):
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/feature/' + name,
                                   'body': {'enabled': on}}, ok=False)

    def run(self, frames):
        if not self.every:
            return super().run(frames)
        while frames > 0:
            step = min(frames, self.every - self.frame % self.every)
            super().run(step)
            frames -= step
            if self.frame % self.every == 0:
                self.grab()

    def grab(self, label=None):
        self.samples.append((self.frame, self.m.read(0x4000, 6912), label if label is not None else self.label))

    def capture(self, every, label=''):
        """Sample the screen every @p every frames from now on (0: stop)"""
        self.every = every
        self.label = label
        if every:
            self.grab()

    def take(self):
        out, self.samples = self.samples, []
        return out

    def wait_for(self, probe, limit=600, step=1):
        for _ in range(0, limit, step):
            if probe():
                return True
            self.run(step)
        return probe()


def common(p):
    p.add_argument('--binary', default=BINARY)
    p.add_argument('--port-base', type=int, default=15670)
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'ui'))


# ---------------------------------------------------------------------------------------------------------------
# tour: the scripted session


MENU_INTERRUPT = 0xC4FD
COMBAT_MENU = (0x5837, 7)    # 1 NUCLEAR BOMB, 2 FIRE PHASERS, 3 FIRE MISSILES, 4 FIRE CANNON, 5 MOVE ROBOT, 6 STOP
DIRECT, COMBAT = 1, 3
ADVANCE = 2
STATES = {}
ANNOTATE = {}


class Tour:
    def __init__(self, rig):
        self.g = rig
        self.events = []      # (frame, name)

    def ev(self, name):
        self.events.append((self.g.frame, name))
        self.g.label = name
        print(f'{self.g.frame:6d} {name}', flush=True)

    def shot(self, name):
        """A state's screen, kept for the state machine figure"""
        STATES[name] = (self.g.frame, self.g.m.read(0x4000, 6912))

    def annotate(self):
        """The screen and the variables of one frame, for the annotated play screen"""
        m = self.g.m
        ANNOTATE.update(frame=self.g.frame, screen=m.read(0x4000, 6912).hex(), vars=m.read(0xFD0A, 7).hex(),
                        robot0=m.read(0xDA00, 16).hex(), warbase0=m.read(0xFD70, 5).hex(),
                        buildings=m.read(0xFF01, 56 * 3).hex(), clock=m.read(0xFD35, 4).hex(),
                        resources=m.read(0xFD22, 7).hex())

    def handler(self):
        v = self.g.m.read(0xFDFE, 2)
        return v[0] | v[1] << 8

    def screen_hash(self):
        return hash(self.g.m.read(0x4000, 6912))

    def toggle(self, part, name):
        g = self.g
        g.goto(2, part)
        self.ev(name)
        g.hold_until({'fire'}, lambda: (g.cursor()[2], tuple(g.m.read(0xFD29, 7))), limit=40)
        g.run(14)

    def run(self):
        g = self.g
        self.ev('the main menu, the tune playing')
        g.run(60)
        self.shot('menu')
        g.run(640)
        # the redefine screen, typed with the default keys again
        self.ev('key 4: REDEFINE KEYS')
        g.key('4', hold=6, gap=40)
        self.shot('redefine')
        for k, name in (('q', 'UP: Q'), ('a', 'DOWN: A'), ('o', 'LEFT: O'), ('p', 'RIGHT: P'),
                        ('symbol', 'FIRE: SYMBOL SHIFT'), ('1', 'PAUSE: 1'), ('i', 'ABORT: I'), ('5', 'SAVE: 5')):
            self.ev('redefine ' + name)
            g.key(k, hold=6, gap=34)
        self.ev('the eighth key: back to the menu')
        print('KeyTable', g.m.read(0xD3CC, 25).hex(' '), flush=True)
        g.wait_for(lambda: self.handler() == MENU_INTERRUPT, limit=200)
        g.run(30)
        self.ev('key 0: START GAME')
        g.key('0', hold=6, gap=20)
        g.wait_for(lambda: self.handler() == bot.PLAY_INTERRUPT, limit=400, step=2)
        self.ev('a new game: the ship climbs')
        g.run(20)
        self.shot('play')
        home = next(b for b in g.buildings() if b['type'] == 0)
        self.ev(f'fly to the warbase pad ({home["x"]},{home["y"]})')
        g.fly_to(home['x'], home['y'])
        self.ev('sink onto the pad (altitude 15)')
        g.stick(set())
        for _ in range(200):
            g.run(2)
            if self.handler() == bot.START_INTERRUPT:
                break
        self.ev('the construction menu opens')
        g.wait_for(lambda: g.cursor() == (2, 0, 0), limit=200, step=2)
        g.run(10)
        self.shot('construction')
        self.toggle(bot.BIPOD, 'fire on BIPOD: paid 3 from the general resource')
        self.toggle(bot.TRACKS, 'fire on TRACKS: replaces the bipod (3 back, 5 paid)')
        self.toggle(bot.CANNON, 'fire on CANNON: paid 2')
        self.toggle(bot.NUCLEAR, 'fire on NUCLEAR: 20 is more than the 13 left: refused')
        self.toggle(bot.MISSILES, 'fire on MISSILES: paid 4')
        self.toggle(bot.MISSILES, 'fire on MISSILES again: taken back, 4 refunded')
        self.ev('START ROBOT: the build chirp')
        before = {r['slot'] for r in g.robots()}
        g.goto(1)
        g.hold_until({'fire'}, lambda: g.m.read(bot.HANDLER, 2), limit=400)
        self.ev('the robot stands at the warbase door; the ship climbs')
        g.climb()
        self.annotate()
        r1 = next(r for r in g.robots() if r['slot'] not in before and r['mine'])
        g.run(40)
        self.ev('land on the robot')
        g.land_on_robot(r1['slot'])
        g.run(4)
        self.ev('the robot menu')
        g.run(12)
        self.shot('robot-menu')
        self.ev('GIVE ORDERS')
        g.choose(bot.MAIN_MENU, bot.GIVE_ORDERS)
        self.shot('orders')
        self.ev('SEARCH & CAPTURE')
        g.choose(bot.ORDERS_MENU, bot.CAPTURE)
        self.ev('SELECT TARGET: NEUTRAL FACTORYS')
        g.choose(bot.TARGET_MENU, 1)
        self.ev('LEAVE ROBOT, fire held: the ship climbs away')
        g.choose(bot.MAIN_MENU, bot.LEAVE_ROBOT, then={'fire'})
        g.climb()
        self.ev('the robot sets off for the nearest neutral factory')
        g.run(240)
        # a second robot: combat mode, direct control, the distance menu
        self.ev('back to the pad: a second robot')
        g.land_on_warbase(home['x'], home['y'])
        r2 = g.build([bot.BIPOD, bot.CANNON])
        g.run(30)
        self.ev('land on the second robot')
        g.land_on_robot(r2['slot'])
        g.run(10)
        rec = bot.ROBOTS + 16 * r2['slot']
        where = lambda: tuple(g.m.read(rec, 2))
        self.ev('DIRECT CONTROL')
        g.choose(bot.MAIN_MENU, DIRECT)
        g.run(10)
        self.ev('direct control: down, the robot turns, then steps; the ship rides on it')
        g.hold_until({'down'}, where, limit=200)
        for n in range(3):
            self.ev('direct control: right' + (', a turn first' if n == 0 else ''))
            g.hold_until({'right'}, where, limit=200)
            if n == 1:
                self.shot('direct')
        g.run(10)
        self.ev('fire: the robot menu again')
        g.hold_until({'fire'}, lambda: g.m.read(rec + 10, 1), limit=60)
        g.run(20)
        self.ev('COMBAT MODE')
        g.choose(bot.MAIN_MENU, COMBAT)
        self.shot('combat')
        self.ev('FIRE CANNON: a shot in record 0')
        g.choose(COMBAT_MENU, 4)
        g.wait_for(lambda: g.m.read(0xD7D4, 1) != b'\0', limit=40)
        self.ev('the shot flies east, 2 cells a turn')
        g.wait_for(lambda: g.m.read(0xD7D4, 1) == b'\0', limit=200)
        self.ev('the shot ends: SoundFx $FC')
        g.run(30)
        self.ev('STOP COMBAT')
        g.choose(COMBAT_MENU, 6)
        g.run(10)
        self.ev('GIVE ORDERS')
        g.choose(bot.MAIN_MENU, bot.GIVE_ORDERS)
        self.ev('ADVANCE ?? MILES')
        g.choose(bot.ORDERS_MENU, ADVANCE)
        g.run(20)
        self.shot('distance')
        miles = lambda: b''.join(g.m.read(K.screen_address(104 + k, 23), 3) for k in range(8))
        for n in (5, 10, 15, 20, 25):
            self.ev(f'up: {n} MILES')
            g.hold_until({'up'}, miles, limit=40)
            g.run(12)
        self.ev('down: 20 MILES')
        g.hold_until({'down'}, miles, limit=40)
        g.run(12)
        self.ev('fire: ADVANCE 20 MILES')
        g.hold_until({'fire'}, lambda: g.m.read(rec + 11, 1), limit=40)
        g.run(30)
        self.ev('LEAVE ROBOT')
        g.choose(bot.MAIN_MENU, bot.LEAVE_ROBOT, then={'fire'})
        g.climb()
        g.run(100)
        self.ev('key 1: pause')
        g.s.call('type_input', {'action': 'press', 'key': '1'}, ok=False)
        g.run(30)
        g.s.call('type_input', {'action': 'release', 'key': '1'}, ok=False)
        g.run(40)
        self.shot('pause')
        self.ev('fire ends the pause')
        g.stick({'fire'})
        g.run(6)
        g.stick(set())
        self.ev('hover: the world runs, the day turns')
        self.g.capture(10, 'hover')
        while True:
            v = g.m.read(0xFD35, 4)
            if v[2] | v[3] << 8 >= 2 and v[1] >= 3:
                break
            g.run(50)
        self.g.capture(2, '')
        self.ev('PlayerBuildings $FD3A poked to 0 (an experiment): the game is lost')
        g.s.call('memory_access', {'action': 'write', 'offset': '0xFD3A', 'hex': '00'}, ok=False)
        g.wait_for(lambda: self.handler() == bot.START_INTERRUPT, limit=200, step=2)
        g.run(60)
        self.shot('gameover')
        g.run(80)
        self.ev('a control: back to Start, the main menu')
        g.hold_until({'fire'}, lambda: self.handler() == MENU_INTERRUPT, limit=300)
        g.run(80)
        self.shot('menu-again')
        self.ev('end')


def cmd_tour(args):
    work = os.path.join(WORK, 'tour')
    rig = Rig(args, work).start()
    tour = Tour(rig)
    rig.capture(2, '')
    try:
        tour.run()
        rig.capture(0)
        samples = rig.take()
        with open(os.path.join(work, 'events.json'), 'w') as f:
            json.dump(tour.events, f)
        with open(os.path.join(work, 'samples.bin'), 'wb') as f:
            for frame, mem, label in samples:
                f.write(frame.to_bytes(4, 'little') + mem)
        with open(os.path.join(work, 'states.json'), 'w') as f:
            json.dump({k: [v[0], v[1].hex()] for k, v in STATES.items()}, f)
        with open(os.path.join(work, 'annotate.json'), 'w') as f:
            json.dump(ANNOTATE, f)
        rig.stick(set())
        print(rig.s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')},
                         ok=False).text.splitlines()[:1])
    finally:
        rig.stop()
    draw_tour(args)


def load_tour():
    work = os.path.join(WORK, 'tour')
    events = [tuple(e) for e in json.load(open(os.path.join(work, 'events.json')))]
    raw = open(os.path.join(work, 'samples.bin'), 'rb').read()
    samples = []
    for at in range(0, len(raw), 6916):
        samples.append((int.from_bytes(raw[at:at + 4], 'little'), raw[at + 4:at + 6916]))
    states = {k: (v[0], bytes.fromhex(v[1])) for k, v in json.load(open(os.path.join(work, 'states.json'))).items()}
    return events, samples, states


def label_at(events, frame):
    name = ''
    for f, n in events:
        if f <= frame:
            name = n
    return name


def event_frame(events, name, nth=0):
    hits = [f for f, n in events if n.startswith(name)]
    return hits[nth]


def screen_gif(path, samples, events, f0, f1, step=2, crop=None, scale=2, title='', delay=40, extra=None):
    """A GIF of the samples in [f0, f1): each picture the screen (cropped, scaled) with the frame and the action"""
    pictures, durations = [], []
    picks, last = [], None
    for s in samples:
        if f0 <= s[0] < f1 and (last is None or s[0] - last >= step):
            picks.append(s)
            last = s[0]
    for frame, mem in picks:
        img = zx(mem, flash=(frame // 16) % 2 == 1)
        if crop:
            img = img.crop(crop)
        img = img.resize((img.size[0] * scale, img.size[1] * scale), Image.NEAREST)
        w = max(img.size[0], 420)
        bar = Image.new('RGB', (w, 44), BG)
        d = ImageDraw.Draw(bar)
        text(d, (6, 4), f'{title}  frame {frame}', 12, DIMC)
        text(d, (6, 22), label_at(events, frame), 14, ACCENT)
        pic = Image.new('RGB', (w, img.size[1] + 44), BG)
        pic.paste(img, (0, 0))
        pic.paste(bar, (0, img.size[1]))
        if extra:
            extra(pic, frame, mem)
        pictures.append(pic)
        durations.append(delay)
    durations[0] = 1200
    durations[-1] = 2500
    save_gif(path, pictures, durations)


def draw_tour(args):
    events, samples, states = load_tour()
    out = args.out
    dense = [s for s in samples]
    f_start = event_frame(events, 'a new game')
    f_leave = event_frame(events, 'the robot sets off')
    # 01: the first robot from the flight to its departure
    screen_gif(os.path.join(out, 'play-first-robot.gif'), dense, events, f_start - 10, f_leave + 240, step=6,
               title='tour')
    # 05: the construction menu
    f0 = event_frame(events, 'the construction menu opens')
    f1 = event_frame(events, 'the robot stands at the warbase door')
    screen_gif(os.path.join(out, 'menu-construction.gif'), dense, events, f0, f1 + 20, step=2, title='tour',
               delay=40)
    # 05: robot menu -> orders -> target -> leave
    f0 = event_frame(events, 'the robot menu') - 40
    f1 = event_frame(events, 'the robot sets off')
    screen_gif(os.path.join(out, 'menu-orders.gif'), dense, events, f0, f1 + 60, step=2, title='tour')
    # 05: combat, direct control, the distance menu
    f0 = event_frame(events, 'COMBAT MODE')
    f1 = event_frame(events, 'STOP COMBAT')
    screen_gif(os.path.join(out, 'menu-combat.gif'), dense, events, f0, f1 + 40, step=2, title='tour')
    f0 = event_frame(events, 'DIRECT CONTROL')
    f1 = event_frame(events, 'COMBAT MODE')
    screen_gif(os.path.join(out, 'direct-control.gif'), dense, events, f0, f1, step=4, title='tour')
    f0 = event_frame(events, 'ADVANCE ?? MILES')
    f1 = event_frame(events, 'LEAVE ROBOT', 1)
    screen_gif(os.path.join(out, 'menu-distance.gif'), dense, events, f0 - 30, f1 + 20, step=2, title='tour')
    # 05: the redefine screen
    f0 = event_frame(events, 'key 4')
    f1 = event_frame(events, 'key 0')
    screen_gif(os.path.join(out, 'menu-redefine.gif'), dense, events, f0, f1, step=2, title='tour')
    # the states, one PNG each
    for name, (frame, mem) in states.items():
        zx(mem).resize((512, 384), Image.NEAREST).save(os.path.join(WORK, 'tour', f'state-{name}.png'))
    print('states', sorted(states))


# ---------------------------------------------------------------------------------------------------------------
# keys: the keyboard map of KeyTable


HALF_ROWS = {0xFE: ['CAPS SHIFT', 'Z', 'X', 'C', 'V'], 0xFD: ['A', 'S', 'D', 'F', 'G'],
             0xFB: ['Q', 'W', 'E', 'R', 'T'], 0xF7: ['1', '2', '3', '4', '5'], 0xEF: ['0', '9', '8', '7', '6'],
             0xDF: ['P', 'O', 'I', 'U', 'Y'], 0xBF: ['ENTER', 'L', 'K', 'J', 'H'],
             0x7F: ['SPACE', 'SYMBOL SHIFT', 'M', 'N', 'B']}
ROWS = [['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'], ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
        ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENTER'],
        ['CAPS SHIFT', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SYMBOL SHIFT', 'SPACE']]
BIT_NAMES = ['right', 'left', 'down', 'up', 'fire', 'save', 'abort', 'pause']
BIT_COLOURS = [(90, 150, 250), (90, 150, 250), (90, 150, 250), (90, 150, 250), (230, 90, 80), (240, 200, 70),
               (200, 110, 230), (90, 200, 120)]


def game_bin():
    return open(IMAGE, 'rb').read()


def at(image, address, n=1):
    return image[address - IMAGE_AT:address - IMAGE_AT + n]


def cmd_keys(args):
    image = game_bin()
    table = at(image, 0xD3CC, 25)
    keys = {}
    for entry in range(8):
        port, mask, code = table[3 * entry:3 * entry + 3]
        name = HALF_ROWS[port][mask.bit_length() - 1]
        keys[name] = (7 - entry, f'{port:02X} {mask:02X} {code:02X}')
    assert table[24] == 1, 'KeyTable ends in $01'
    kw, kh, gap = 92, 70, 8
    W = 30 + 10 * (kw + gap) + 30
    H = 70 + 4 * (kh + gap) + 252
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    text(d, (30, 16), 'The default controls: KeyTable $D3CC in neart001, each key and the Input ($FD0C) bit it '
         'sets', 16, FG)
    for r, row in enumerate(ROWS):
        for c, name in enumerate(row):
            x = 30 + c * (kw + gap) + r * 18
            y = 60 + r * (kh + gap)
            if x + kw > W - 10:
                continue
            fill, edge = (34, 34, 44), (70, 70, 85)
            label2 = ''
            if name in keys:
                bit, raw = keys[name]
                fill, edge = tuple(v // 3 for v in BIT_COLOURS[bit]), BIT_COLOURS[bit]
                label2 = BIT_NAMES[bit]
            if name in ('6', '7', '8', '9', '0'):
                edge = (250, 150, 60)
            d.rounded_rectangle([x, y, x + kw, y + kh], 8, fill=fill, outline=edge, width=3 if label2 else 2)
            text(d, (x + 8, y + 6), name.replace(' SHIFT', '\nSHIFT'), 15, FG)
            if label2:
                if ' ' in name:
                    label2 = f'{label2}, bit {bit}'
                else:
                    text(d, (x + 8, y + kh - 40), f'bit {bit}', 12, BIT_COLOURS[bit])
                text(d, (x + 8, y + kh - 22), label2, 12, BIT_COLOURS[bit])
            if name in ('6', '7', '8', '9', '0'):
                text(d, (x + kw - 8, y + 6), {'6': 'L', '7': 'R', '8': 'D', '9': 'U', '0': 'F'}[name], 14,
                     (250, 150, 60), 'ra')
    y = 60 + 4 * (kh + gap) + 14
    text(d, (30, y), 'KeyTable: 8 records (half-row port byte, bit mask, the code the redefine screen prints), $01, '
         'Controls', 13, DIMC)
    for entry in range(8):
        port, mask, code = table[3 * entry:3 * entry + 3]
        name = HALF_ROWS[port][mask.bit_length() - 1]
        bit = 7 - entry
        short = name.replace('SYMBOL SHIFT', 'SYM SH')
        text(d, (30 + (entry % 4) * 260, y + 26 + (entry // 4) * 22),
             f'{entry}: {port:02X} {mask:02X} {code:02X} {short:<6s} bit {bit}', 13, BIT_COLOURS[bit])
    y += 82
    text(d, (30, y), 'Kempston (Controls = 2): IN ($1F) AND $1F, bits 0-4 = right, left, down, up, fire, ORed into '
         'Input', 13, FG)
    text(d, (30, y + 22), 'Interface 2 (Controls = 3): keys 6-0 (orange: L R D U F), IN ($EFFE) inverted and '
         'reordered, ORed in', 13, (250, 150, 60))
    text(d, (30, y + 44), 'The keys always count: a joystick player keeps 1 pause, I abort and 5 save on the '
         'keyboard. Redefine (key 4)', 13, DIMC)
    text(d, (30, y + 66), 'asks UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE and writes entries 4, 5, 6, 7, 3, 0, '
         '1, 2.', 13, DIMC)
    text(d, (30, y + 88), 'The image holds code $82 for SYMBOL SHIFT; redefining it writes $0E (the tour, KeyTable read '
         'back after key 4).', 13, DIMC)
    out = os.path.join(args.out, 'keyboard-map.png')
    img.save(out)
    print(out, keys)


# ---------------------------------------------------------------------------------------------------------------
# states: the state machine of doc 04 with the tour's screen in each state

NODES = {  # name: (column, row, title, code, handler)
    'redefine': (0, 0, 'redefine keys', 'RedefineKeys $C34A', 'StartInterrupt'),
    'menu': (1, 0, 'main menu', 'MainMenu $C100, MenuMusic', 'MenuInterrupt $C4FD'),
    'gameover': (2, 0, 'game over (poked)', 'CheckGameEnd $AE6B, GameOverWait', 'StartInterrupt'),
    'pause': (0, 1, 'pause', 'PauseLoop in WaitKey $D37C', 'PlayInterrupt'),
    'play': (1, 1, 'play: a game turn a pass', 'PlayLoop $A69A', 'PlayInterrupt $D566'),
    'construction': (2, 1, 'construction menu', 'ConstructionMenu $C849', 'StartInterrupt $D59C'),
    'direct': (0, 2, 'direct control', 'DirectControl $A941', 'PlayInterrupt'),
    'robot-menu': (1, 2, 'robot menu', 'RobotMenu $A720, ListMenu', 'PlayInterrupt'),
    'orders': (2, 2, 'orders / target / distance', 'OrdersMenu $A971', 'PlayInterrupt'),
    'combat': (3, 2, 'combat mode', 'CombatMenu $AC00', 'PlayInterrupt'),
}
EDGES = [('menu', 'redefine', 'key 4'), ('redefine', 'menu', '8th key'), ('menu', 'play', 'key 0: NewGameSetup'),
         ('play', 'menu', 'key I: abort'), ('play', 'pause', 'key 1'), ('pause', 'play', 'another control'),
         ('play', 'construction', 'land on the pad'), ('construction', 'play', 'START / EXIT'),
         ('play', 'robot-menu', 'land on a robot'), ('robot-menu', 'play', 'LEAVE ROBOT'),
         ('robot-menu', 'direct', 'DIRECT CONTROL'), ('direct', 'robot-menu', 'fire'),
         ('robot-menu', 'orders', 'GIVE ORDERS'), ('orders', 'robot-menu', 'an order set'),
         ('robot-menu', 'combat', 'COMBAT MODE'), ('play', 'gameover', 'no warbase left'),
         ('gameover', 'menu', 'a control: JP Start')]
CELL_W, CELL_H, THUMB = 400, 300, (256, 192)


def node_box(name):
    c, r = NODES[name][:2]
    x = 30 + c * CELL_W
    y = 50 + r * CELL_H
    return x, y, x + THUMB[0], y + THUMB[1] + 52


def cmd_states(args):
    events, samples, states = load_tour()
    W, H = 30 + 4 * CELL_W, 60 + 3 * CELL_H
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    text(d, (30, 12), 'Play is the hub: every in-game menu returns to it; abort and the game over go back to the main '
         'menu (frame colour: the interrupt handler)', 17, FG)
    for name, (c, r, title, code, handler) in NODES.items():
        x0, y0, x1, y1 = node_box(name)
        frame, mem = states[name]
        img.paste(zx(mem), (x0, y0))
        colour = (90, 200, 120) if 'PlayInterrupt' in handler else (240, 200, 70) if 'Menu' in handler else \
            (200, 110, 230)
        d.rectangle([x0 - 2, y0 - 2, x0 + THUMB[0] + 1, y0 + THUMB[1] + 1], outline=colour, width=2)
        text(d, (x0, y0 + THUMB[1] + 4), title, 15, colour)
        text(d, (x0, y0 + THUMB[1] + 22), code, 13, FG)
        text(d, (x0, y0 + THUMB[1] + 38), f'{handler}, tour frame {frame}', 13, DIMC)
    def anchor(name, other):
        x0, y0, x1, y1 = node_box(name)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        ox0, oy0, ox1, oy1 = node_box(other)
        ocx, ocy = (ox0 + ox1) / 2, (oy0 + oy1) / 2
        if abs(ocx - cx) > abs(ocy - cy) * 1.2:
            return (x1 + 4 if ocx > cx else x0 - 6), cy
        return cx, (y1 + 2 if ocy > cy else y0 - 6)
    def arrow(points, label, where=None, side='above'):
        d.line(points, fill=ACCENT, width=2, joint='curve')
        pa, pb = points[-2], points[-1]
        ang = math.atan2(pb[1] - pa[1], pb[0] - pa[0])
        for s_ in (-0.45, 0.45):
            d.line([pb, (pb[0] - 11 * math.cos(ang + s_), pb[1] - 11 * math.sin(ang + s_))], fill=ACCENT, width=2)
        f = K.font(13)
        tw = d.textlength(label, font=f)
        if where is None:
            i = max(range(len(points) - 1), key=lambda k: abs(points[k + 1][0] - points[k][0]) +
                    abs(points[k + 1][1] - points[k][1]))
            where = ((points[i][0] + points[i + 1][0]) / 2, (points[i][1] + points[i + 1][1]) / 2)
        mx, my = where
        if side == 'above':
            tx, ty = mx - tw / 2, my - 17
        elif side == 'below':
            tx, ty = mx - tw / 2, my + 4
        elif side == 'right':
            tx, ty = mx + 6, my - 7
        else:
            tx, ty = mx - tw - 6, my - 7
        d.text((tx, ty), label, font=f, fill=FG)
    seen = set()
    special = {('robot-menu', 'combat'), ('play', 'gameover'), ('gameover', 'menu')}
    for a, b, label in EDGES:
        if (a, b) in special:
            continue
        pa, pb = anchor(a, b), anchor(b, a)
        first = (b, a) not in seen
        seen.add((a, b))
        horizontal = abs(pa[0] - pb[0]) > abs(pa[1] - pb[1])
        off = -12 if first else 12
        if horizontal:
            pa, pb = (pa[0], pa[1] + off), (pb[0], pb[1] + off)
            arrow([pa, pb], label, side='above' if first else 'below')
        else:
            pa, pb = (pa[0] + off * 3, pa[1]), (pb[0] + off * 3, pb[1])
            arrow([pa, pb], label, side='left' if first else 'right')
    # the elbows
    rx0, ry0, rx1, ry1 = node_box('robot-menu')
    cx0, cy0, cx1, cy1 = node_box('combat')
    yb = ry1 + 22
    arrow([((rx0 + rx1) / 2 + 60, ry1 + 2), ((rx0 + rx1) / 2 + 60, yb), ((cx0 + cx1) / 2, yb),
           ((cx0 + cx1) / 2, cy1 + 4)], 'COMBAT MODE (STOP COMBAT back)', where=(((rx0 + rx1) / 2 + (cx0 + cx1) / 2) / 2,
                                                                      yb), side='below')
    px0, py0, px1, py1 = node_box('play')
    gx0, gy0, gx1, gy1 = node_box('gameover')
    ym = (py0 + node_box('menu')[3]) / 2 + 12
    arrow([(px1 - 20, py0 - 6), (px1 - 20, ym), ((gx0 + gx1) / 2, ym), ((gx0 + gx1) / 2, gy1 + 4)],
          'CheckGameEnd: no warbase', where=(((px1 - 20) + (gx0 + gx1) / 2) / 2 + 30, ym), side='above')
    mx0, my0, mx1, my1 = node_box('menu')
    arrow([(gx0 - 4, (gy0 + gy1) / 2 - 40), (mx1 + 6, (gy0 + gy1) / 2 - 40)], 'a control', side='above')
    lx = 30 + 3 * CELL_W
    y = 60
    for label, colour in (('handler PlayInterrupt: game turns run', (90, 200, 120)),
                          ('handler StartInterrupt: the world stands', (200, 110, 230)),
                          ('MenuInterrupt: the tune plays', (240, 200, 70))):
        d.rectangle([lx, y, lx + 14, y + 14], fill=colour)
        text(d, (lx + 22, y - 1), label, 14, FG)
        y += 26
    text(d, (lx, y + 10), 'The game over screen comes from an\nexperiment: PlayerBuildings $FD3A\npoked to 0 '
         'in the tour.', 14, DIMC)
    path = os.path.join(args.out, 'state-machine.png')
    img.save(path)
    print(path)


def project(column, row, height, view_x):
    """The screen pixel of DrawSprite's anchor (the sprite's lower left) for a map cell: 06-rendering 6.3, the view
    buffer copied to character (1,1)"""
    e = column - view_x
    return 8 * e + 4 * row - 96 + 8, 8 * row + 100 - 4 * e - height + 8


def cmd_annotate(args):
    events, samples, states = load_tour()
    a = json.load(open(os.path.join(WORK, 'tour', 'annotate.json')))
    frame = a['frame']
    mem = bytes.fromhex(a['screen'])
    v = {k: bytes.fromhex(a[k]) for k in ('vars', 'robot0', 'warbase0', 'buildings', 'clock', 'resources')}
    view_x, ship_y, ship_x, alt = v['vars'][0], v['vars'][3], v['vars'][4] | v['vars'][5] << 8, v['vars'][6]
    r = v['robot0']
    robot_x, robot_y, robot_ground = r[2] | r[3] << 8, r[4], r[13]
    door_x, door_y = v['warbase0'][0] | v['warbase0'][1] << 8, v['warbase0'][2]
    found = {}
    b = v['buildings']
    for i in range(56):
        if b[3 * i + 1] and b[3 * i + 2] in (0, 7):
            cell = (b[3 * i] | b[3 * i + 1] << 8) - 0xDD00
            found[b[3 * i + 2]] = (cell % 512, cell // 512)
    S, MX, TOP = 3, 360, 56
    W, H = 256 * S + 2 * MX, 192 * S + TOP + 116
    img = Image.new('RGB', (W, H), BG)
    img.paste(zx(mem).resize((256 * S, 192 * S), Image.NEAREST), (MX, TOP))
    d = ImageDraw.Draw(img)
    text(d, (20, 14), f'A play screen of the tour at frame {frame} (day 0): the ship has built a robot and climbs off '
         'the pad; the robot stands at the door', 16, FG)
    text(d, (20, 34), 'Dots: DrawSprite\'s anchor (the sprite\'s lower left) of each object, projected from its record '
         'in memory with 06-rendering 6.3', 12, DIMC)

    def sx(x):
        return MX + x * S

    def sy(y):
        return TOP + y * S

    def callout(point, label_y, side, lines, colour):
        x, y = sx(point[0]), sy(point[1])
        d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=colour, outline=(0, 0, 0), width=2)
        lx = MX - 16 if side == 'l' else MX + 256 * S + 16
        d.line([(x, y), (lx + (-4 if side == 'l' else 4), label_y + 8), (lx, label_y + 8)], fill=colour, width=2)
        d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=colour, outline=(0, 0, 0), width=2)
        for i, (s, size) in enumerate(lines):
            text(d, (lx, label_y + i * 18), s, size, colour if i == 0 else FG, 'ra' if side == 'l' else 'la')

    obj = []
    if 7 in found:
        obj.append((project(*found[7], 0, view_x), 'our flag', f'building record type 7 at ({found[7][0]},{found[7][1]})',
                    '$FF01 table', (120, 220, 120)))
    if 0 in found:
        obj.append((project(*found[0], 15, view_x), 'the pad: land here to build',
                    f'building type 0 at ({found[0][0]},{found[0][1]}), $FF01', 'on the warbase, height 15 (1.4)',
                    (240, 200, 70)))
    obj.append((project(ship_x, ship_y, alt, view_x), 'the ship', f'ShipX $FD0E = {ship_x}, ShipY $FD0D = {ship_y}',
                f'Altitude $FD10 = {alt}', (240, 110, 200)))
    obj.append((project(door_x, door_y, 0, view_x), 'our warbase\'s door cell',
                f'Warbases $FD70: ({door_x},{door_y}), owner $40', 'a robot on it 144 turns captures', (90, 200, 120)))
    obj.append((project(robot_x, robot_y, robot_ground, view_x), 'the new robot',
                f'record 0 at $DA00: ({robot_x},{robot_y}), parts ${r[7]:02X}',
                ' + '.join(n for i, n in enumerate(['bipod', 'tracks', 'anti-grav', 'cannon', 'missiles', 'phasers',
                                                    'nuclear', 'electronics']) if r[7] >> i & 1)
                + f', order {r[11]}' + (' (stop and defend)' if r[11] == 0 else ''),
                (90, 170, 250)))
    obj.sort(key=lambda o: o[0][1])
    for i, (pt, t1, t2, t3, colour) in enumerate(obj):
        callout(pt, TOP + 30 + i * 110, 'l', [(t1, 14), (t2, 12), (t3, 12)], colour)
    clock = v['clock']
    panel = [((22, 0.5), 'DAY and TIME', f'Clock $FD35: {clock[1]:02d}:{clock[0]:02d}, day {clock[2] | clock[3] << 8}',
              (240, 90, 80)),
             ((22, 3.3), 'STATUS: bases and robots', 'PlayerBuildings $FD3A, EnemyBuildings $FD42,', (90, 200, 120)),
             ((22, 13.4), '', 'PlayerRobotCount $FD41, EnemyRobotCount $FD49', (90, 200, 120)),
             ((22, 17.5), 'RESOURCES', f'Resources $FD22: general {v["resources"][0]}', (120, 220, 120)),
             ((21.5, 22.5), 'RADAR (left of here)', '128 columns round the ship, one pixel a cell', (90, 170, 250))]
    rows = [TOP + 10, TOP + 70, TOP + 300, TOP + 400, TOP + 500]
    for (cell, t1, t2, colour), ly in zip(panel, rows):
        px, py = cell[0] * 8, cell[1] * 8
        x, y = sx(px), sy(py)
        d.rectangle([x - 4, y - 4, x + 4, y + 4], outline=colour, width=2)
        lx = MX + 256 * S + 16
        d.line([(x, y), (lx - 4, ly + 8), (lx, ly + 8)], fill=colour, width=1)
        if t1:
            text(d, (lx, ly), t1, 14, colour)
        text(d, (lx, ly + (18 if t1 else 0)), t2, 12, FG)
    d.rectangle([sx(8) - 1, sy(8) - 1, sx(168), sy(168)], outline=(255, 255, 255), width=1)
    text(d, (MX, sy(192) + 6), 'the view: characters (1,1)-(20,20), the buffer at $5B00 copied in (6.2); the '
         'shadow of the ship (drawn first) is hidden under the warbase here', 12, FG)
    text(d, (20, H - 70), f'Recording: the tour (own instance from work/gsA/deep/start.szx), frame {frame}; the values '
         'read from memory at the same frame.', 12, DIMC)
    text(d, (20, H - 50), 'Map cell address = $DD00 + 512 Y + X (the building records hold cells). Pixel x = 8E + 4D - 96, '
         'bottom line = 8D + 100 - 4E - h, E = X - ViewX ($FD0A), D = Y.', 12, DIMC)
    text(d, (20, H - 30), 'Reproduce: python3 tools/fig_ui.py tour, then annotate', 12, DIMC)
    out = os.path.join(args.out, 'play-annotated.png')
    img.save(out)
    print(out)


# ---------------------------------------------------------------------------------------------------------------


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    for name in ('tour', 'draw-tour', 'keys', 'states', 'annotate'):
        common(sub.add_parser(name))
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    if args.cmd == 'draw-tour':
        draw_tour(args)
    else:
        globals()['cmd_' + args.cmd](args)


if __name__ == '__main__':
    main()
