#!/usr/bin/env python3
"""Figures that show Nether Earth at work (docs 01, 03, 04, 05, 08, 09): GIFs of real play and of each menu driven
by a script, the tape load with its border, the state machine with a screen per state, the panel changing, the
print routine's control codes, the beeper effects and the menu tune measured from access traces.

Every picture comes from an own unreal-qt instance (offscreen, muted) started from the menu snapshot
work/play/start.szx (or from power-on with orig/NETHER.TAP for `load`) and driven through tools/bot.py's Game: the
emulator is exact and every input is given at a fixed frame or on a memory condition, so a run gives the same
pictures every time. The instance is killed at the end.

    python3 tools/ill_ui.py load    [--port-base 29000]   docs/img/ui/load-tape.gif
    python3 tools/ill_ui.py tour    [--port-base 29000]   the scripted session (menus, a build, orders, a day):
                                                          docs/img/ui/play-*.gif, menu-*.gif, state-*.png,
                                                          panel-*.gif, screen-annotated.png, and the recording
                                                          work/ill3/tour (TTD + session.json) for `sound`
    python3 tools/ill_ui.py keys                          docs/img/ui/keyboard-map.png (the KeyTable of build/game.bin)
    python3 tools/ill_ui.py states                        docs/img/ui/state-machine.png (from tour's state-*.png)
    python3 tools/ill_ui.py print                         docs/img/ui/print-codes.png (PrintInline strings drawn
                                                          from build/game.bin with their control codes)
    python3 tools/ill_ui.py sound   --work work/ill3/tour docs/img/ui/sound-*.png (OUT $FE of access traces of the
                                                          tour recording and of work/docC/fight)
    python3 tools/ill_ui.py turn    --trace T.uatr        docs/img/ui/turn-film.png (a turn's routines and the
                                                          screen at the end of each frame)

Common options: --unreal (the unreal-ng checkout), --binary (unreal-qt), --port-base, --out (docs/img/ui).
"""
import argparse
import json
import math
import os
import shutil
import sys
import time

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
KIT = os.path.abspath(os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, KIT)
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402
import bot  # noqa: E402

UNREAL = '/Volumes/TB4-4Tb/Projects/Test/unreal-ng'
BINARY = os.path.join(UNREAL, 'scratch/wt-access-trace/cmake-build-agent-release/bin/unreal-qt.app/Contents/MacOS/'
                      'unreal-qt')
WORK = os.path.join(CASE, 'work', 'ill3')
FRAME_T = 69888

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


class Rig(bot.Game):
    """bot.Game with frame capture: every run() can sample the screen"""

    def __init__(self, args, work):
        super().__init__(args.unreal, work)
        self.args = args
        self.process = None
        self.samples = []      # (frame, screen bytes, label)
        self.every = 0
        self.label = ''

    def start(self, snapshot=None, record=False):
        if snapshot:
            self.process = self.launch(self.args.binary, snapshot, self.args.port_base, record=record)
        else:
            os.makedirs(self.work, exist_ok=True)
            here = os.getcwd()
            os.chdir(self.work)
            try:
                self.process = self.mcplib.launch(self.args.binary, self.args.port_base)
            finally:
                os.chdir(here)
            s = self.mcplib.Session(f'http://127.0.0.1:{self.args.port_base + 200}/mcp', '48K')
            s.fresh_machine('48K', ram_power_on='zero')
            s.call('control_execution', {'action': 'pause'}, ok=False)
            s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                  'body': {'muted': True}}, ok=False)
            self.s = s
            self.m = self.corpus.Machine(s, self.args.port_base)
            with open(os.path.join(self.work, 'session.json'), 'w') as f:
                json.dump({'pid': self.process.pid, 'binary': self.args.binary, 'port_base': self.args.port_base,
                           'model': '48K', 'ranges': '4000-FFFF'}, f)
        print('instance pid', self.process.pid, 'port base', self.args.port_base, flush=True)
        return self

    def stop(self):
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(10)
            except Exception:
                self.process.kill()
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
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', UNREAL))
    p.add_argument('--binary', default=BINARY)
    p.add_argument('--port-base', type=int, default=29000)
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'ui'))


# ---------------------------------------------------------------------------------------------------------------
# load: the tape at ROM speed, the border and the screen bytes as they arrive


def tap_blocks(path):
    data = open(path, 'rb').read()
    out, at = [], 0
    while at < len(data):
        n = data[at] | data[at + 1] << 8
        out.append(data[at + 2:at + 2 + n])
        at += 2 + n
    return out


def cmd_load(args):
    rig = Rig(args, os.path.join(WORK, 'load')).start()
    tape = tap_blocks(os.path.join(CASE, 'orig', 'NETHER.TAP'))
    game = tape[4][1:-1]
    frames_dir = os.path.join(rig.work, 'frames')
    shutil.rmtree(frames_dir, ignore_errors=True)
    os.makedirs(frames_dir)
    log = []
    try:
        rig.feature('fasttape', False)
        rig.feature('turbotape', False)
        r = rig.s.call('load_software', {'path': os.path.join(CASE, 'orig', 'NETHER.TAP'), 'autostart': False,
                                         'play': False}, ok=False)
        print(r.text.splitlines()[0])
        rig.run(200)
        for keys in (['j'], ['symbol', 'p'], ['symbol', 'p'], ['enter']):
            for k in keys:
                rig.s.call('type_input', {'action': 'press', 'key': k}, ok=False)
            rig.run(5)
            for k in keys:
                rig.s.call('type_input', {'action': 'release', 'key': k}, ok=False)
            rig.run(10)
        rig.m.post('/tape/play', None)
        t0 = rig.frame
        # dense while the ROM loads the short blocks, sparse over the game block
        plan = []
        f = 0
        while f < 14200:
            plan.append(f)
            f += 30 if f < 1200 else 200
        for target in plan:
            if rig.frame - t0 < target:
                rig.run(target - (rig.frame - t0))
            path = os.path.join(frames_dir, f'{target:05d}.png')
            rig.s.call('capture_media', {'action': 'screenshot', 'area': 'full', 'path': path}, ok=False)
            mem = rig.m.read(0x4000, 0xC000)
            regs = rig.m.get('/registers')
            pc = regs['special']['pc']
            ix = regs['index']['ix']
            st = rig.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/tape'}, ok=False)
            body = ((st.structured or {}).get('body') or {})
            # the game block's front: the highest address of a run of 8 bytes equal to the block, 4 non-zero
            arrived = 0
            for i in range(len(game) - 1, 7, -8):
                seg = mem[i - 7:i + 1]
                if seg == game[i - 7:i + 1] and sum(1 for b in seg if b) >= 4 and not (0x1800 <= i < 0x1B00):
                    arrived = i + 1
                    break
            log.append({'frame': target, 'pc': pc, 'ix': ix, 'arrived': arrived, 'tape': {'state': body.get('state'),
                        'block': (body.get('position') or {}).get('block'),
                        'sec': (body.get('position') or {}).get('seconds_into_block')},
                        'screen': mem[:6912].hex()})
            if target % 1000 == 0:
                print(target, hex(pc), arrived, log[-1]['tape'], flush=True)
            if body.get('state') not in ('playing',) and target > 2000 and 0xA600 <= pc < 0xFCDA:
                break  # the tape has ended and the game runs
        with open(os.path.join(rig.work, 'load.json'), 'w') as f:
            json.dump(log, f)
    finally:
        rig.stop()
    draw_load(args, tape, frames_dir, log)


def draw_load(args, tape, frames_dir, log):
    # the tape at signal speed: each block's pulses, frames
    def play_t(block):
        pilot = 8063 if block[0] < 0x80 else 3223
        ones = sum(bin(b).count('1') for b in block)
        zeros = 8 * len(block) - ones
        return pilot * 2168 + 667 + 735 + zeros * 2 * 855 + ones * 2 * 1710
    names = ['header N.EARTH', 'BASIC', 'header N1', 'N1', 'the game, 48 361 bytes']
    lens = [play_t(b) / FRAME_T for b in tape]
    total = log[-1]['frame']
    scale = 2
    pictures, durations = [], []
    W = 352 * scale + 256 * scale + 30
    for i, entry in enumerate(log):
        frame = entry['frame']
        full = Image.open(os.path.join(frames_dir, f'{frame:05d}.png')).convert('RGB')
        full = full.resize((352 * scale, 288 * scale), Image.NEAREST)
        mem = bytes.fromhex(entry['screen'])
        # the bitmap with the attributes forced to white ink on blue paper: what the black screen hides
        forced = bytearray(mem[:6144]) + bytes([0x0F]) * 768
        bits = K.render_screen(bytes(forced), 0).resize((256 * scale, 192 * scale), Image.NEAREST)
        pic = Image.new('RGB', (W, 288 * scale + 150), BG)
        pic.paste(full, (0, 0))
        pic.paste(bits, (352 * scale + 30, 0))
        d = ImageDraw.Draw(pic)
        text(d, (352 * scale + 30, 192 * scale + 8), 'the same screen bytes, attributes', 13, DIMC)
        text(d, (352 * scale + 30, 192 * scale + 26), 'forced to white on blue', 13, DIMC)
        pc, ix, blk = entry['pc'], entry.get('ix', 0), entry['tape'].get('block')
        if pc >= 0xFCDA:
            stage, front = 'N1 loads the game block (DI)', f'IX = ${ix:04X}: {max(0, ix - 0x4000)} of 48361 bytes'
        elif pc < 0x4000:
            stage = 'the ROM: ' + (['block 0, header N.EARTH', 'block 1, the BASIC', 'block 2, header N1',
                                    'block 3, N1'][blk] if isinstance(blk, int) and blk < 4 else 'BASIC')
            front = ''
        else:
            stage, front = 'the game runs: Start $A600, the menu', 'all 48361 bytes in place'
        text(d, (352 * scale + 30, 192 * scale + 56), stage, 14, ACCENT)
        text(d, (352 * scale + 30, 192 * scale + 78), f'PC ${pc:04X}', 14, FG)
        text(d, (352 * scale + 30, 192 * scale + 100), front, 14, FG)
        text(d, (8, 288 * scale + 6), f'frame {frame} after PLAY (+{frame / 50:.1f} s).  Left: the emulator\'s '
             'picture with its border', 14, FG)
        # the timeline: the blocks at signal speed against frames, the measured position
        y0 = 288 * scale + 40
        x0, x1 = 10, W - 10
        span = max(total, 13300)
        d.rectangle([x0, y0, x1, y0 + 26], outline=DIMC)
        # the blocks start where the recording saw them start (see the stage marks)
        starts = stage_starts(log)
        for b, (start, n) in enumerate(zip(starts, lens)):
            if start is None:
                continue
            xa = x0 + (x1 - x0) * start / span
            xb = x0 + (x1 - x0) * min(span, start + n) / span
            colour = [(90, 150, 250), (90, 200, 120), (90, 150, 250), (240, 200, 70), (230, 90, 80)][b]
            d.rectangle([xa, y0 + 2, max(xa + 2, xb), y0 + 24], fill=colour)
            if b == 4:
                text(d, (xa + 6, y0 + 6), names[b], 12, (0, 0, 0))
        text(d, (x0, y0 + 32), 'the tape at signal speed: blue the headers, green the BASIC, yellow N1 '
             '(all by the ROM), red the game block (by N1)', 12, DIMC)
        # memory: $4000-$FCE8 filled up to N1's IX
        mx0, mx1, my = 352 * scale + 30, W - 10, 192 * scale + 148
        done = 1.0 if pc < 0xFCDA and pc >= 0x4000 else max(0, min(1, (ix - 0x4000) / 48361)) if pc >= 0xFCDA else 0
        d.rectangle([mx0, my, mx1, my + 18], outline=DIMC)
        if done:
            d.rectangle([mx0 + 1, my + 1, mx0 + 1 + (mx1 - mx0 - 2) * done, my + 17], fill=(230, 90, 80))
        for a in (0x4000, 0x5B00, 0x8000, 0xC000, 0xFCE8):
            xa = mx0 + (mx1 - mx0) * (a - 0x4000) / 48361
            d.line([xa, my + 18, xa, my + 22], fill=DIMC)
            text(d, (xa, my + 24), f'${a:04X}', 11, DIMC, 'ma' if a not in (0x4000, 0xFCE8) else
                 ('la' if a == 0x4000 else 'ra'))
        text(d, (mx0, my - 16), 'the game block in memory', 12, DIMC)
        xn = x0 + (x1 - x0) * frame / span
        d.line([xn, y0 - 6, xn, y0 + 30], fill=(255, 255, 255), width=3)
        for t in range(0, span + 1, 2500):
            xt = x0 + (x1 - x0) * t / span
            d.line([xt, y0 + 26, xt, y0 + 30], fill=DIMC)
            text(d, (xt, y0 + 52), f'{t}', 11, DIMC, 'ma')
        text(d, (x1, y0 + 52), 'frames', 11, DIMC, 'ra')
        pictures.append(pic)
        durations.append(60 if frame < 900 else 80)
    durations[0] = 1500
    durations[-1] = 3000
    out = os.path.join(args.out, 'load-tape.gif')
    # keep the GIF small: half the dense part
    keep = [i for i, e in enumerate(log) if e['frame'] >= 900 or e['frame'] % 20 == 0]
    save_gif(out, [pictures[i] for i in keep], [durations[i] for i in keep])


def stage_starts(log):
    """The frame each block's signal starts, from the tape API's block index where it answers, else None"""
    starts = [None] * 5
    for e in log:
        b = e['tape'].get('block')
        if e['tape'].get('state') == 'playing' and isinstance(b, int) and 0 <= b < 5 and starts[b] is None:
            starts[b] = e['frame'] - 50 * (e['tape'].get('sec') or 0)
    return starts


# ---------------------------------------------------------------------------------------------------------------
# tour: one scripted session from the menu snapshot, the screen sampled every 2 frames


MENU_INTERRUPT = 0xC4FD
COMBAT_MENU = (0x5837, 7)    # 1 NUCLEAR BOMB, 2 FIRE PHASERS, 3 FIRE MISSILES, 4 FIRE CANNON, 5 MOVE ROBOT, 6 STOP
DIRECT, COMBAT = 1, 3
ADVANCE = 2
STATES = {}


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
        self.ev('key 2: KEMPSTON J/S')
        g.key('2', hold=6, gap=40)
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
    rig = Rig(args, work).start(os.path.join(CASE, 'work', 'play', 'start.szx'), record=True)
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
        rig.stick(set())
        r = rig.s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 30000})
        state = rig.s.call('analysis', {'action': 'status'}).text
        while ': running' in state:
            time.sleep(5)
            state = rig.s.call('analysis', {'action': 'status'}).text
        print(state)
        print(rig.s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')},
                         ok=False).text.splitlines()[:1])
    finally:
        if not getattr(args, 'keep', False):
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
    f1 = event_frame(events, 'key 2')
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
    return open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()


def at(image, address, n=1):
    return image[address - 0x5B00:address - 0x5B00 + n]


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
    text(d, (30, 16), 'The default controls: KeyTable $D3CC in build/game.bin, each key and the Input ($FD0C) bit it '
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
# print: PrintInline strings with their control codes, over the screens the tour saw them on


POS_C, ATTR_C, NL_C, SIZE_C = (90, 150, 250), (240, 200, 70), (200, 110, 230), (230, 90, 80)
RUN_COLOURS = [(90, 200, 120), (70, 210, 220), (250, 150, 60), (240, 120, 180), (160, 220, 80), (140, 140, 250)]


def parse_string(image, address):
    """[(kind, bytes, value)] of the PrintInline string at address, to its 0"""
    out, a = [], address
    while True:
        b = at(image, a)[0]
        if b == 0:
            out.append(('end', [0], None))
            return out, a + 1
        if b == 1:
            y, x = at(image, a + 1, 2)
            out.append(('pos', [1, y, x], (y, x)))
            a += 3
        elif b == 2:
            out.append(('attr', [2, at(image, a + 1)[0]], at(image, a + 1)[0]))
            a += 2
        elif b == 3:
            out.append(('nl', [3], None))
            a += 1
        elif b == 4:
            n = at(image, a + 1)[0]
            out.append(('size', [4, n], n))
            a += 2
        else:
            out.append(('char', [b], chr(b)))
            a += 1


def print_runs(tokens, state):
    """Follow PrintControl: the cells each run of characters covers. state: row, col, left, attr, h, w"""
    runs, current = [], None
    for kind, raw, value in tokens:
        if kind == 'char':
            w = state['w'] or 1
            h = state['h'] if state['w'] else 1
            if current is None:
                current = {'cells': [], 'attr': state['attr'], 'size': (state['h'], state['w']), 'text': ''}
                runs.append(current)
            current['cells'].append((state['row'], state['col'], w, h))
            current['text'] += value
            state['col'] += w
        else:
            current = None
            if kind == 'pos':
                state['row'], state['col'] = value
                state['left'] = value[1]
            elif kind == 'attr':
                state['attr'] = value
            elif kind == 'nl':
                state['row'] += 1
                state['col'] = state['left']
            elif kind == 'size':
                state['h'], state['w'] = value >> 4, value & 15
    return runs


def token_strip(d, x, y, width, tokens, run_of):
    """The string's bytes as boxes, wrapped at width; returns the height used"""
    f = K.font(12)
    cx, cy = x, y
    run = -1
    for i, (kind, raw, value) in enumerate(tokens):
        if kind == 'char':
            label, colour = value if value != ' ' else '_', RUN_COLOURS[run_of[i] % len(RUN_COLOURS)]
        elif kind == 'pos':
            label, colour = f'1 {raw[1]},{raw[2]}', POS_C
        elif kind == 'attr':
            label, colour = f'2 ${raw[1]:02X}', ATTR_C
        elif kind == 'nl':
            label, colour = '3', NL_C
        elif kind == 'size':
            label, colour = f'4 ${raw[1]:02X}', SIZE_C
        else:
            label, colour = '0', DIMC
        w = int(d.textlength(label, font=f)) + (20 if kind == 'attr' else 8)
        if cx + w > x + width:
            cx, cy = x, cy + 24
        d.rectangle([cx, cy, cx + w - 2, cy + 19], outline=colour, fill=tuple(v // 4 for v in colour))
        d.text((cx + 4, cy + 3), label, font=f, fill=colour)
        if kind == 'attr':
            a = raw[1]
            ink, paper = K.ink_colour(a & 7, a & 0x40), K.ink_colour((a >> 3) & 7, a & 0x40)
            d.rectangle([cx + w - 10, cy + 2, cx + w - 4, cy + 8], fill=ink)
            d.rectangle([cx + w - 10, cy + 10, cx + w - 4, cy + 17], fill=paper)
        cx += w + 2
    return cy + 24 - y


def cmd_print(args):
    image = game_bin()
    events, samples, states = load_tour()
    panels = [
        ('menu', 'the main menu: NETHER / EARTH ($C1E6) and option 0 ($C109), option 1 ($C128) starts with 3 3 3',
         [0xC1E6, 0xC109, 0xC128]),
        ('robot-menu', 'the robot menu ($A738): one position, one attribute, code 3 for every next line',
         [0xA738]),
        ('play', 'the play screen frame ($D1C5): DAY / TIME at (0,22), RADAR: tall ($21) at (22,0)', [0xD1C5]),
    ]
    rows = []
    for state_name, title, addresses in panels:
        mem = states[state_name][1]
        tokens, run_of, runs = [], {}, []
        state = {'row': 0, 'col': 0, 'left': 0, 'attr': 0, 'h': 0, 'w': 0}
        for a in addresses:
            t, _ = parse_string(image, a)
            base = len(tokens)
            tokens += t
            r = print_runs(t, state)
            # map each char token to its run number
            k, prev_char = len(runs) - 1, False
            for i, (kind, raw, value) in enumerate(t):
                if kind == 'char':
                    if not prev_char:
                        k += 1
                    run_of[base + i] = k
                    prev_char = True
                else:
                    prev_char = False
            runs += r
        scr = zx(mem).resize((512, 384), Image.NEAREST)
        over = ImageDraw.Draw(scr)
        for k, run in enumerate(runs):
            colour = RUN_COLOURS[k % len(RUN_COLOURS)]
            xs = [c[1] for c in run['cells']] + [c[1] + c[2] for c in run['cells']]
            ys = [c[0] for c in run['cells']] + [c[0] + c[3] for c in run['cells']]
            box = [min(xs) * 16 - 1, min(ys) * 16 - 1, max(xs) * 16, max(ys) * 16]
            over.rectangle(box, outline=colour, width=2)
        for kind, raw, value in tokens:
            if kind == 'pos':
                y, x = value
                over.ellipse([x * 16 - 5, y * 16 - 5, x * 16 + 5, y * 16 + 5], fill=POS_C, outline=(0, 0, 0))
        panel = Image.new('RGB', (1180, 420), BG)
        panel.paste(scr, (8, 28))
        d = ImageDraw.Draw(panel)
        text(d, (8, 6), f'{title}   (screen: tour frame {states[state_name][0]})', 14, FG)
        h = token_strip(d, 540, 34, 630, tokens, run_of)
        y = 34 + h + 10
        for k, run in enumerate(runs):
            if y > 400:
                break
            colour = RUN_COLOURS[k % len(RUN_COLOURS)]
            r0, c0 = run['cells'][0][:2]
            hh, ww = run['size']
            size = 'normal' if not ww else f'size ${hh:X}{ww:X}: {ww * 8} x {hh * 8} pixels a glyph'
            text(d, (540, y), f'"{run["text"].strip()}" at ({r0},{c0}) attr ${run["attr"]:02X}, {size}', 12, colour)
            y += 17
        rows.append(panel)
    legend = Image.new('RGB', (1180, 64), BG)
    d = ImageDraw.Draw(legend)
    x, y = 8, 10
    for label, colour in (('1 Y,X: position, row and column in decimal (a blue dot on the screen)', POS_C),
                          ('2 A: attribute (ink over paper swatch)', ATTR_C), ('3: next row, the same column', NL_C),
                          ('4 N: size, high nibble height, low nibble width', SIZE_C),
                          ('characters: one colour a run, boxed on the screen', RUN_COLOURS[0]), ('0: the end', DIMC)):
        tw = int(d.textlength(label, font=K.font(12)))
        if x + tw + 40 > 1180:
            x, y = 8, y + 24
        d.rectangle([x, y, x + 14, y + 14], fill=colour)
        text(d, (x + 20, y), label, 12, FG)
        x += tw + 44
    out = stack(legend, *rows)
    path = os.path.join(args.out, 'print-codes.png')
    out.save(path)
    print(path)
    # big characters: one glyph from the font and the same letter as the three sizes drew it on real screens
    font = at(image, 0x6780, 512)
    big = Image.new('RGB', (1180, 300), BG)
    d = ImageDraw.Draw(big)
    text(d, (8, 6), 'One glyph, four sizes: the font at $6780 and the letters as PrintChar / PrintBigChar drew them '
         '(tour screens, 8x)', 14, FG)
    def glyph(code):
        g = Image.new('RGB', (8, 8), (0, 0, 0))
        for yy in range(8):
            for xx in range(8):
                if font[(code - 0x20) * 8 + yy] & (0x80 >> xx):
                    g.putpixel((xx, yy), (255, 255, 255))
        return g
    def crop(state_name, row, col, w, h):
        m = states[state_name][1]
        return zx(m).crop((col * 8, row * 8, (col + w) * 8, (row + h) * 8))
    items = [('the font: $6780 + 8 x ("E" - $20)', glyph(ord('E')), 'the 8 bytes of the glyph\n' +
              ' '.join(f'{b:02X}' for b in font[(ord('E') - 0x20) * 8:(ord('E') - 0x20) * 8 + 8])),
             ('size 0: "TIME:" (play)', crop('play', 1, 25, 1, 1), 'PrintChar: 8 x 8'),
             ('size $21: "START GAME" (menu)', crop('menu', 11, 20, 1, 2), 'PrintBigChar:\neach line twice: 8 x 16'),
             ('size $32: "NETHER" (menu)', crop('menu', 1, 12, 2, 3), 'PrintBigChar: each bit doubled,\n'
              'each line three times: 16 x 24')]
    x = 16
    for label, img, note in items:
        img = img.resize((img.size[0] * 8, img.size[1] * 8), Image.NEAREST)
        big.paste(img, (x, 60))
        text(d, (x, 36), label, 12, ACCENT)
        text(d, (x, 60 + img.size[1] + 6), note, 12, DIMC)
        x += 290
    path = os.path.join(args.out, 'print-sizes.png')
    big.save(path)
    print(path)


# ---------------------------------------------------------------------------------------------------------------
# panel: the status panel while the world runs (the tour's hover, every 10 frames), with the variables behind it

RES_NAMES = ['GENERAL', 'ELECTR\'S', 'NUCLEAR', 'PHASERS', 'MISSILES', 'CANNON', 'CHASSIS']
BLD_NAMES = ['WARBASES', 'ELECTR\'S', 'NUCLEAR', 'PHASERS', 'MISSILES', 'CANNON', 'CHASSIS']


def tour_session(args):
    sys.path.insert(0, os.path.join(K.unreal_root(args.unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    return re_session.session_of(os.path.join(WORK, 'tour'))[0]


def mem_at(session, frame, offset, length):
    r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                     'offset': offset, 'length': length}, ok=False)
    body = r.structured or {}
    if r.is_error or 'hex' not in body:
        raise SystemExit(f'memory_at {frame}: {r.text}')
    return bytes.fromhex(body['hex'])


def variables(v):
    """The panel's variables from $FD00-$FD5F"""
    return {'clock': (v[0x37] | v[0x38] << 8, v[0x36], v[0x35]), 'res': list(v[0x22:0x29]),
            'mine': list(v[0x3A:0x41]), 'robots': v[0x41], 'theirs': list(v[0x42:0x49]), 'enemy': v[0x49]}


def cmd_panel(args):
    events, samples, states = load_tour()
    session = tour_session(args)
    f0 = event_frame(events, 'hover')
    f1 = event_frame(events, 'PlayerBuildings')
    hover = [s for s in samples if f0 <= s[0] < f1 and s[0] % 10 == 0]
    cache_path = os.path.join(WORK, 'tour', 'panel-vars.json')
    cache = json.load(open(cache_path)) if os.path.isfile(cache_path) else {}
    rows = []
    for frame, mem in hover:
        if str(frame) not in cache:
            cache[str(frame)] = mem_at(session, frame, 0xFD00, 0x60).hex()
        rows.append((frame, mem, variables(bytes.fromhex(cache[str(frame)]))))
    json.dump(cache, open(cache_path, 'w'))
    # keep the pictures where the panel changed, with two before each change and the change held
    panel_box = (22 * 8, 0, 32 * 8, 24 * 8)
    def crop(mem):
        return zx(mem).crop(panel_box)
    pictures, durations = [], []
    prev, prev_vars, glow = None, None, {}
    for i, (frame, mem, var) in enumerate(rows):
        img = crop(mem)
        changed = []
        if prev is not None:
            a, b = numpy_cells(prev), numpy_cells(img)
            changed = [(r, c) for r in range(24) for c in range(10) if a[r][c] != b[r][c]]
        clock_only = all(r < 2 for r, c in changed)
        for cell in changed:
            if cell[0] >= 2:
                glow[cell] = 6
        if prev is None or not clock_only or i % 6 == 0 or any(glow.values()):
            big = img.resize((img.size[0] * 3, img.size[1] * 3), Image.NEAREST)
            d = ImageDraw.Draw(big)
            for (r, c), n in glow.items():
                if n:
                    col = K.WRITE_FADE[min(len(K.WRITE_FADE) - 1, 6 - n)]
                    d.rectangle([c * 24, r * 24, c * 24 + 23, r * 24 + 23], outline=col, width=3)
            pic = Image.new('RGB', (big.size[0] + 430, big.size[1] + 40), BG)
            pic.paste(big, (0, 0))
            dd = ImageDraw.Draw(pic)
            day, hour, minute = var['clock']
            text(dd, (big.size[0] + 20, 8), f'frame {frame}   day {day} {hour:02d}:{minute:02d}', 15, FG)
            y = 40
            text(dd, (big.size[0] + 20, y), 'Resources $FD22 (HUMN)', 13, DIMC)
            y += 20
            for k, name in enumerate(RES_NAMES):
                old = prev_vars['res'][k] if prev_vars else var['res'][k]
                hot = old != var['res'][k]
                text(dd, (big.size[0] + 30, y), f'{name:<9s} {var["res"][k]:3d}' + (f'   was {old}' if hot else ''),
                     13, ACCENT if hot else FG)
                y += 18
            y += 8
            text(dd, (big.size[0] + 20, y), 'Buildings INSG $FD42 / HUMN $FD3A', 13, DIMC)
            y += 20
            for k, name in enumerate(BLD_NAMES):
                o1 = prev_vars['theirs'][k] if prev_vars else var['theirs'][k]
                o2 = prev_vars['mine'][k] if prev_vars else var['mine'][k]
                hot = (o1, o2) != (var['theirs'][k], var['mine'][k])
                text(dd, (big.size[0] + 30, y), f'{name:<9s} {var["theirs"][k]:3d} {var["mine"][k]:3d}', 13,
                     ACCENT if hot else FG)
                y += 18
            hot = prev_vars and (prev_vars['enemy'], prev_vars['robots']) != (var['enemy'], var['robots'])
            text(dd, (big.size[0] + 30, y), f'{"ROBOTS":<9s} {var["enemy"]:3d} {var["robots"]:3d}  $FD49 / $FD41', 13,
                 ACCENT if hot else FG)
            y += 30
            note = ''
            if prev_vars and var['clock'][0] != prev_vars['clock'][0]:
                note = 'midnight: DailyProduction pays both sides'
            elif prev_vars and var['enemy'] != prev_vars['enemy']:
                note = 'the enemy built a robot (EnemyCommander)' if var['enemy'] > prev_vars['enemy'] else \
                    'an enemy robot was destroyed'
            elif prev_vars and (var['mine'], var['theirs']) != (prev_vars['mine'], prev_vars['theirs']):
                note = 'a base changed hands (GameTurnEnd captures)'
            if note:
                text(dd, (big.size[0] + 20, y), note, 14, ACCENT)
            text(dd, (6, big.size[1] + 12), 'tour: the panel cells that changed are boxed, fading', 12, DIMC)
            pictures.append(pic)
            durations.append(1500 if note else 120)
            prev_vars = var
        for cell in list(glow):
            glow[cell] = max(0, glow[cell] - 1)
        prev = img
    durations[0] = 1500
    durations[-1] = 3000
    save_gif(os.path.join(args.out, 'panel-events.gif'), pictures, durations)


def numpy_cells(img):
    """The panel crop as 22 x 10 character cells (bytes of each cell's pixels)"""
    px = img.tobytes()
    w = img.size[0] * 3
    cells = []
    for r in range(24):
        row = []
        for c in range(10):
            row.append(b''.join(px[(r * 8 + y) * w + c * 24:(r * 8 + y) * w + c * 24 + 24] for y in range(8)))
        cells.append(row)
    return cells


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
         ('play', 'menu', 'key I: JP Start'), ('play', 'pause', 'key 1'), ('pause', 'play', 'another control'),
         ('play', 'construction', 'land on the pad'), ('construction', 'play', 'START ROBOT / EXIT'),
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
    text(d, (30, 14), 'The game\'s states, each with its screen from the tour run (tools/ill_ui.py tour; the frame '
         'under each)', 16, FG)
    for name, (c, r, title, code, handler) in NODES.items():
        x0, y0, x1, y1 = node_box(name)
        frame, mem = states[name]
        img.paste(zx(mem), (x0, y0))
        colour = (90, 200, 120) if 'PlayInterrupt' in handler else (240, 200, 70) if 'Menu' in handler else \
            (200, 110, 230)
        d.rectangle([x0 - 2, y0 - 2, x0 + THUMB[0] + 1, y0 + THUMB[1] + 1], outline=colour, width=2)
        text(d, (x0, y0 + THUMB[1] + 4), title, 13, colour)
        text(d, (x0, y0 + THUMB[1] + 20), code, 11, FG)
        text(d, (x0, y0 + THUMB[1] + 34), f'{handler}, frame {frame}', 11, DIMC)
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
        f = K.font(12)
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
          'CheckGameEnd: no warbase left', where=(((px1 - 20) + (gx0 + gx1) / 2) / 2 + 30, ym), side='above')
    mx0, my0, mx1, my1 = node_box('menu')
    arrow([(gx0 - 4, (gy0 + gy1) / 2 - 40), (mx1 + 6, (gy0 + gy1) / 2 - 40)], 'a control: JP Start', side='above')
    lx = 30 + 3 * CELL_W
    y = 60
    for label, colour in (('handler PlayInterrupt: game turns run', (90, 200, 120)),
                          ('handler StartInterrupt: the world stands', (200, 110, 230)),
                          ('MenuInterrupt: the tune plays', (240, 200, 70))):
        d.rectangle([lx, y, lx + 14, y + 14], fill=colour)
        text(d, (lx + 22, y), label, 12, FG)
        y += 24
    text(d, (lx, y + 10), 'The game over screen comes from an\nexperiment: PlayerBuildings $FD3A\npoked to 0 '
         'in the tour.', 12, DIMC)
    path = os.path.join(args.out, 'state-machine.png')
    img.save(path)
    print(path)


# ---------------------------------------------------------------------------------------------------------------
# sound: every OUT to $FE in access traces of the tour (and of work/docC/fight for the hit and the kill)

CLOCK = 3500000
SOUND_DIR = os.path.join(WORK, 'sound')


def trace_outs(work, f0, f1, unreal, chunk=40):
    """[(T from f0's start, EAR bit, PC, B)] of every OUT to an even port in frames [f0, f1), traced in chunks; the
    trace files are removed once read"""
    out = []
    for a in range(f0, f1, chunk):
        b = min(f1, a + chunk)
        ns = argparse.Namespace(trace=None, work=work, window=f'{a}:0-{b}:0', max_cycles=40000000, unreal=unreal)
        trace = K.load_trace(ns)
        times = K.instruction_times(trace)
        base = (a - f0) * trace.frame_t
        for x, t in zip(trace.instructions, times):
            for c in x.cycles:
                if c.tag == 'O' and not c.address & 1:
                    out.append((base + t + c.dt, c.value >> 4 & 1, x.pc, x.reg('b')))
        if trace.truncated:
            print('truncated', a, b)
        os.remove(os.path.join(work, 'traces', f'{a}_0-{b}_0.uatr'))
        print(f'  {work}: frames {a}-{b}: {len(out)} OUTs', flush=True)
    return out


def sound_windows(events):
    e = lambda name, k=0: event_frame(events, name, k)
    return {
        'tune': (0, 700),
        'construction': (e('fire on BIPOD') - 25, e('the robot stands') + 5),
        'robotmenu': (e('the robot menu'), e('LEAVE ROBOT, fire held') + 40),
        'combat': (e('FIRE CANNON'), e('the shot ends') + 10),
        'gameover': (e('PlayerBuildings'), e('PlayerBuildings') + 160),
    }


def cmd_sound(args):
    os.makedirs(SOUND_DIR, exist_ok=True)
    events, samples, states = load_tour()
    tour = os.path.join(WORK, 'tour')
    for name, (f0, f1) in sound_windows(events).items():
        path = os.path.join(SOUND_DIR, f'{name}.json')
        if not os.path.isfile(path):
            print(name, f0, f1, flush=True)
            json.dump({'from_frame': f0, 'to_frame': f1, 'outs': trace_outs(tour, f0, f1, args.unreal)},
                      open(path, 'w'))
    path = os.path.join(SOUND_DIR, 'kill.json')
    if not os.path.isfile(path):
        fight = os.path.join(WORK, 'fight')
        if not os.path.isfile(os.path.join(fight, 'session.json')):
            raise SystemExit('open work/docC/fight/session.ttd first: re_session.py open --work work/ill3/fight '
                             '--ttd work/docC/fight/session.ttd --port-base 29600')
        json.dump({'from_frame': 19312, 'to_frame': 19372, 'outs': trace_outs(fight, 19312, 19372, args.unreal)},
                  open(path, 'w'))
    draw_sound(args)


def level_signal(outs, t0, t1, rate):
    """The EAR level sampled at @p rate between T t0 and t1"""
    import numpy as np
    n = int((t1 - t0) * rate / CLOCK)
    sig = np.zeros(n, dtype=np.float32)
    level, last = 0, 0
    for t, bit, pc, b in outs:
        if t < t0:
            level = bit
            continue
        if t >= t1:
            break
        i = int((t - t0) * rate / CLOCK)
        sig[last:i] = level
        level, last = bit, i
    sig[last:] = level
    return sig


def spectrogram(ax, sig, rate, t_ms0, fmax=16000, nfft=1024, hop=128, vmin=-60):
    import numpy as np
    sig = sig - sig.mean()
    win = np.hanning(nfft)
    cols = []
    for i in range(0, max(1, len(sig) - nfft), hop):
        seg = sig[i:i + nfft]
        if len(seg) < nfft:
            seg = np.pad(seg, (0, nfft - len(seg)))
        cols.append(np.abs(np.fft.rfft(seg * win)))
    spec = np.array(cols).T + 1e-9
    db = 20 * np.log10(spec / spec.max())
    freqs = np.fft.rfftfreq(nfft, 1 / rate)
    keep = freqs <= fmax
    ax.imshow(db[keep], origin='lower', aspect='auto', cmap='magma', vmin=vmin, vmax=0,
              extent=[t_ms0, t_ms0 + len(sig) / rate * 1000, 0, freqs[keep][-1] / 1000])
    ax.set_ylabel('kHz')


EFFECTS = [  # name, source, routine PCs, how to pick the run, the code's formula
    ('cursor click: Beep A = $14', 'construction', 'beep', 0x14, 'CursorMoved $CB47, ListMenuKey $AD17: '
     '3.5 MHz / (2 (13A + 50)) = 5.6 kHz, 23 ms'),
    ('part paid / item chosen: Beep A = $64', 'construction', 'beep', 0x64, 'PartPaid $CA91, ListMenuChosen $AD37: '
     '1.3 kHz, 98 ms'),
    ('refused, taken back, order set: Beep A = $78', 'construction', 'beep', 0x78, 'PartRefused $CAAE, OrderSet '
     '$ABF7, LeaveRobot $A803: 1.1 kHz, 117 ms'),
    ('START ROBOT: the build chirp, then $C8', 'construction', 'chirp', None, 'BuildChirp $CB82: A = $50 down to $14 '
     'by 5, LeaveConstructionMenu $C8 (660 Hz)'),
    ('a shot fired (SoundFx 1, 2, ...) and lost ($FC)', 'combat', 'fx', None, 'SoundEffect $D5C4 once a frame: '
     'pulses 13A + 63 T apart, then NoiseLoop'),
    ('a robot destroyed: SoundFx $C8 (work/docC/fight)', 'kill', 'fx', None, '55 frames of NoiseLoop: 30 levels '
     'from Random a frame'),
    ('the game\'s end: Beep A = $FA', 'gameover', 'beep', 0xFA, 'GameOverWait $AEEC: 530 Hz, 241 ms'),
    ('menu drum: "hiss" (kind 0)', 'tune', 'drum', 0xC608, 'DrumHiss $C608: LD A,(HL) with no INC HL, so one ROM '
     'byte 96 times'),
    ('menu drum: rasp (kind 1)', 'tune', 'drum', 0xC5EB, 'DrumRasp $C5EB: 80 bytes of ROM page $00 with gaps'),
    ('menu drum: falling sweep (kind 2)', 'tune', 'drum', 0xC616, 'DrumSweep $C616: 48 cycles, low half shorter, '
     'high half longer'),
]


def runs_of(outs, keep, gap):
    """Runs of the OUTs keep() selects, split at a pause longer than gap T"""
    runs, cur = [], None
    for o in outs:
        if not keep(o):
            continue
        if cur and o[0] - cur[-1][0] <= gap:
            cur.append(o)
        else:
            cur = [o]
            runs.append(cur)
    return runs


def in_routine(pc, lo, hi):
    return lo <= pc <= hi


def pick_effect(kind, arg, outs):
    """The OUTs of one sounding of an effect"""
    if kind == 'beep':
        runs = runs_of(outs, lambda o: in_routine(o[2], 0xCCAC, 0xCCBC), 4000)
        for run in runs:
            if len(run) >= 200 and run[len(run) // 2][3] == arg:
                return run
    if kind == 'chirp':
        runs = runs_of(outs, lambda o: in_routine(o[2], 0xCCAC, 0xCCBC), 4000)
        # the 14 beeps of the chirp and the $C8 follow each other closely: one long run
        long = [run for run in runs if len(run) > 1000]
        return long[0] if long else []
    if kind == 'fx':
        runs = runs_of(outs, lambda o: in_routine(o[2], 0xD5C4, 0xD5FF), 200000)
        return max(runs, key=len) if runs else []
    if kind == 'drum':
        lo = arg
        hi = {0xC608: 0xC615, 0xC5EB: 0xC607, 0xC616: 0xC65A}[arg]
        runs = runs_of(outs, lambda o: in_routine(o[2], lo, hi), 3000)
        runs = [r for r in runs if len(r) > 20]
        return runs[len(runs) // 2] if runs else []
    return []


def draw_sound(args):
    import numpy as np
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams['text.parse_math'] = False
    data = {name: json.load(open(os.path.join(SOUND_DIR, f'{name}.json')))
            for name in ('tune', 'construction', 'robotmenu', 'combat', 'gameover', 'kill')}
    rate = CLOCK / 16
    fig, axes = plt.subplots(len(EFFECTS), 2, figsize=(15, 2.05 * len(EFFECTS)), dpi=90,
                             gridspec_kw={'width_ratios': [1, 2.4]})
    for row, (title, source, kind, arg, formula) in enumerate(EFFECTS):
        d = data[source]
        run = pick_effect(kind, arg, d['outs'])
        axw, axs = axes[row]
        if not run:
            axw.text(0.5, 0.5, 'not found', ha='center')
            continue
        t0 = run[0][0] - 2000
        t1 = run[-1][0] + 4000
        frame0 = d['from_frame'] + run[0][0] / FRAME_T
        sig = level_signal(d['outs'], t0, t1, rate)
        # the waveform: the first 4 ms (8 ms for the slow ones)
        span = 8 if kind in ('beep', 'chirp') and (arg or 0) >= 0x64 or kind == 'chirp' else 4
        n = int(span / 1000 * rate)
        xs = np.arange(min(n, len(sig))) / rate * 1000
        axw.step(xs, sig[:len(xs)], where='post', lw=0.8, color='#1070d0')
        axw.set_ylim(-0.2, 1.2)
        axw.set_yticks([0, 1])
        axw.set_xlim(0, span)
        axw.set_title(title, fontsize=10, loc='left')
        axw.set_xlabel('ms (EAR bit 4 of OUT ($FE))', fontsize=8)
        if len({o[1] for o in run}) == 1:
            # one level all along: nothing to show in a spectrogram
            hits = runs_of(d['outs'], lambda o: in_routine(o[2], 0xC608, 0xC615), 3000)
            axs.axis('off')
            axs.text(0.0, 0.55, f'Silent. HL stays at $08xx with L = the drum position, so all 96 OUTs of a hit write the '
                     f'same byte;\nat frame 355 that is the 48K ROM byte at $0867 = $23, AND $18 = 0: EAR and MIC low. All '
                     f'{sum(len(h) for h in hits)} OUTs of the {len(hits)} hits in frames {d["from_frame"]}-'
                     f'{d["to_frame"]} have EAR = 0.\nWitness: access traces (the read at $0867 gives $23 on each of '
                     f'the 96 turns at frame 355; music.asm DrumHissLoop has no INC HL).', fontsize=9, va='center', transform=axs.transAxes)
        else:
            spectrogram(axs, sig, rate, 0, fmax=16000 if kind != 'beep' else 8000)
        axs.set_title(f'{formula}   [{source} frame {frame0:.0f}, {len(run)} OUTs, '
                      f'{(run[-1][0] - run[0][0]) / CLOCK * 1000:.0f} ms]', fontsize=9, loc='left')
        axs.set_xlabel('ms from the first OUT', fontsize=8)
        for a in (axw, axs):
            a.tick_params(labelsize=8)
    fig.tight_layout()
    path = os.path.join(args.out, 'sound-gallery.png')
    fig.savefig(path)
    plt.close(fig)
    print(path)
    draw_tune(args, data['tune'])


def draw_tune(args, tune):
    """The tune as the tone loop played it: each voice's pulse rate from its own OUT (bass and lead have their own
    OUT instructions), against the model of tools/tune_roll.py"""
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import tune_roll
    outs = tune['outs']
    pcs = {}
    for o in outs:
        pcs[o[2]] = pcs.get(o[2], 0) + 1
    print('tune OUT sites', {f'${k:04X}': v for k, v in sorted(pcs.items())})
    lead_pc = [pc for pc in pcs if 0xC4CB <= pc < 0xC4E0]
    bass_pc = [pc for pc in pcs if 0xC4E8 <= pc <= 0xC4FC]
    fig, ax = plt.subplots(1, 1, figsize=(15, 6.2), dpi=90)
    import math as m
    def pitch(f):
        return 12 * m.log2(f / 440) + 69
    colours = {'bass': '#e07020', 'lead': '#1070d0'}
    states, bass, lead = tune_roll.model(800)
    offset = 93
    measured, t_per_p = {}, {}
    for voice, sites in (('bass', bass_pc), ('lead', lead_pc)):
        k = 0 if voice == 'bass' else 1
        on = [o for o in outs if o[2] in sites and o[1]]
        per_frame = {}
        for a, b in zip(on, on[1:]):
            dt = b[0] - a[0]
            if 0 < dt < 30000:
                per_frame.setdefault(int(tune['from_frame'] + a[0] / FRAME_T), []).append(dt)
        xs, ys, ratios = [], [], []
        for f, dts in sorted(per_frame.items()):
            dts.sort()
            dt = dts[len(dts) // 2]  # the frame's median pulse distance: one note a frame
            xs.append(f + 0.5)
            ys.append(pitch(CLOCK / dt))
            period, sounding = states[f + offset][k]
            if sounding and period:
                ratios.append(dt / period)
        ratios.sort()
        t_per_p[voice] = ratios[len(ratios) // 2] if ratios else 0
        measured[voice] = (xs, ys)
        ax.plot(xs, ys, 'o', ms=2.6, color=colours[voice], label=f'{voice}: measured, 3.5 MHz / (median T between '
                f'its pulses in the frame), OUT at {", ".join(f"${p:04X}" for p in sites)}; T per p unit = '
                f'{t_per_p[voice]:.1f}')
    for voice, k in (('bass', 0), ('lead', 1)):
        f = 0
        frames = tune['to_frame']
        while f < frames:
            period, on = states[f + offset][k]
            g = f
            while g < frames and states[g + offset][k] == (period, on):
                g += 1
            if on and period:
                y = pitch(CLOCK / (125.5 * period))
                ax.plot([f, g], [y, y], color='black', lw=0.8, alpha=0.6)
            f = g
    drums = [o for o in outs if 0xC5DB <= o[2] <= 0xC65A]
    hits = runs_of(drums, lambda o: True, 3000)
    for run in hits:
        x = tune['from_frame'] + run[0][0] / FRAME_T
        kind = 'hiss' if 0xC608 <= run[0][2] <= 0xC615 else 'rasp' if run[0][2] < 0xC608 else 'sweep'
        ax.plot([x], [43], {'hiss': '|', 'rasp': 'x', 'sweep': 'v'}[kind], color='#555555', ms=6)
    ax.plot([], [], color='black', lw=0.8, label='model (tools/tune_roll.py, offset 93): 3.5 MHz / (125.5 p), '
            'the doc\'s estimate')
    ax.plot([], [], '|', color='#555555', label='drum hits by routine: | hiss (writes one level, silent), x rasp, v sweep')
    ticks = list(range(45, 82))
    ax.set_yticks(ticks)
    ax.set_yticklabels([f'{tune_roll.NAMES[t % 12]}{t // 12 - 1}' for t in ticks], fontsize=7)
    ax.set_ylim(41, 82)
    ax.set_xlim(tune['from_frame'], tune['to_frame'])
    ax.set_xlabel('tour frame (the menu, before key 4)')
    ax.set_ylabel('pitch (equal temperament, A4 = 440 Hz)')
    ax.grid(alpha=0.25)
    ax.legend(loc='lower left', bbox_to_anchor=(0.005, 0.1), fontsize=8)
    ax.set_title('The menu tune measured: every OUT ($FE) of the tone loop in access traces of the tour, frames '
                 f'{tune["from_frame"]}-{tune["to_frame"]}', fontsize=11, loc='left')
    fig.tight_layout()
    path = os.path.join(args.out, 'sound-tune-measured.png')
    fig.savefig(path)
    plt.close(fig)
    print(path)
    # the measured pitch against the estimate: the median ratio per voice
    for voice in measured:
        xs, ys = measured[voice]
        diffs = []
        for x, y in zip(xs, ys):
            f = int(x)
            period, on = states[f + offset][0 if voice == 'bass' else 1]
            if on and period:
                diffs.append(y - pitch(CLOCK / (125.5 * period)))
        diffs.sort()
        if diffs:
            print(voice, 'T per period unit', round(t_per_p[voice], 2), 'measured - estimate, semitones: median', round(diffs[len(diffs) // 2], 3), 'n', len(diffs))



# ---------------------------------------------------------------------------------------------------------------
# annotate: one play screen of the tour with its objects found in memory and projected (6.3)

ANNOTATE_FRAME = 1700


def project(column, row, height, view_x):
    """The screen pixel of DrawSprite's anchor (the sprite's lower left) for a map cell: 06-rendering 6.3, the view
    buffer copied to character (1,1)"""
    e = column - view_x
    return 8 * e + 4 * row - 96 + 8, 8 * row + 100 - 4 * e - height + 8


def annotate_vars(args, frame):
    path = os.path.join(WORK, 'tour', f'annotate-{frame}.json')
    if os.path.isfile(path):
        return {k: bytes.fromhex(v) for k, v in json.load(open(path)).items()}
    session = tour_session(args)
    v = {'vars': mem_at(session, frame, 0xFD0A, 7), 'robot0': mem_at(session, frame, 0xDA00, 16),
         'warbase0': mem_at(session, frame, 0xFD70, 5), 'buildings': mem_at(session, frame, 0xFF01, 56 * 3),
         'clock': mem_at(session, frame, 0xFD35, 4), 'resources': mem_at(session, frame, 0xFD22, 7)}
    json.dump({k: b.hex() for k, b in v.items()}, open(path, 'w'))
    return v


def cmd_annotate(args):
    events, samples, states = load_tour()
    frame = ANNOTATE_FRAME
    mem = [m for f, m in samples if f == frame][0]
    v = annotate_vars(args, frame)
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
         'the pad; the robot walks out of the door', 16, FG)
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
             ((22, 2.5), 'STATUS: bases and robots', 'PlayerBuildings $FD3A, EnemyBuildings $FD42,', (90, 200, 120)),
             ((22, 10.5), '', 'PlayerRobotCount $FD41, EnemyRobotCount $FD49', (90, 200, 120)),
             ((22, 13.5), 'RESOURCES', f'Resources $FD22: general {v["resources"][0]}', (120, 220, 120)),
             ((21.5, 22.5), 'RADAR (left of here)', '128 columns round the ship, one pixel a cell', (90, 170, 250))]
    rows = [TOP + 10, TOP + 70, TOP + 110, TOP + 180, TOP + 500]
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
    text(d, (20, H - 70), f'Recording: the tour (own instance from work/play/start.szx), frame {frame}; values read with '
         'time_travel memory_at at the same frame.', 12, DIMC)
    text(d, (20, H - 50), 'Map cell address = $DD00 + 512 Y + X (the building records hold cells). Pixel x = 8E + 4D - 96, '
         'bottom line = 8D + 100 - 4E - h, E = X - ViewX ($FD0A), D = Y.', 12, DIMC)
    text(d, (20, H - 30), 'Reproduce: python3 tools/ill_ui.py annotate', 12, DIMC)
    out = os.path.join(args.out, 'play-annotated.png')
    img.save(out)
    print(out)


# ---------------------------------------------------------------------------------------------------------------


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    for name in ('load', 'tour', 'draw-tour', 'keys', 'states', 'print', 'panel', 'sound', 'draw-sound', 'annotate',
                 'redraw-load'):
        q = sub.add_parser(name)
        common(q)
        if name in ('sound',):
            q.add_argument('--work', default=os.path.join(WORK, 'tour'))
        if name == 'tour':
            q.add_argument('--keep', action='store_true', help='keep the instance (for sound)')
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    if args.cmd == 'load':
        cmd_load(args)
    elif args.cmd == 'draw-sound':
        draw_sound(args)
    elif args.cmd == 'draw-tour':
        draw_tour(args)
    elif args.cmd == 'redraw-load':
        log = json.load(open(os.path.join(WORK, 'load', 'load.json')))
        draw_load(args, tap_blocks(os.path.join(CASE, 'orig', 'NETHER.TAP')), os.path.join(WORK, 'load', 'frames'),
                  log)
    else:
        globals()['cmd_' + args.cmd](args)


if __name__ == '__main__':
    main()
