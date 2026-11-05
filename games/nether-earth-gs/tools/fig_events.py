#!/usr/bin/env python3
"""The figures of doc 10 (gameplay logic): shots, damage, deaths, COMBAT MODE, the nuclear blast, capture, the enemy
commander, production and the two ends of the game, all from emulator memory.

Two sources, one cache format (an .npz of 48 K memory pictures `$4000-$FFFF` with their frame numbers):

* a recording, read with TTD `memory_at` on the instance that holds it (`re_session.py open`), read only:
      python3 tools/fig_events.py sample --work work/gsB/rT --frames 0:36046:120 --out work/ill1/cache/day.npz
  and a snapshot cut from it at a frame (`seek`, then `/snapshot/save`):
      python3 tools/fig_events.py snap --work work/gsB/rT --frame 17400 --out work/ill1/snaps/deep-17400.szx
* an experiment on a live instance started from such a snapshot (`tools/bot.py launch --start S`): the ship is
  flown over a place high enough not to block any robot, then one memory picture is taken every game turn (the
  first frame after the clock `$FD35` moved: the view copy of that turn is complete):
      python3 tools/fig_events.py turns --work work/ill1/live --fly 128,7 --turns 90 --out work/ill1/cache/duel.npz
  Experiments that need a rare event first poke the clone (`--poke ADDR=BYTES`, logged in the cache) or drive the
  menus (`combat`, `ends`).

The figure commands read only caches (`fig-*`, see `--help`); each writes one file under docs/img/events/.

Adapted for this case from ../nether-earth/tools/ill_events.py (the game code is the same at the same addresses): the
recording names point at work/gsB/rT (Hood's tape on Pentagon 128 + GS), the NE tools folder is on the path for the
modules it imports, and a memory picture taken while the GS driver's page (bank 6) was in at `$C000` (a sound sent
across the frame interrupt, docs/09-sound.md 9.8) is replaced by the next frame's.
"""
import argparse
import json
import os
import sys
import time

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
sys.path.insert(0, HERE)
sys.path.insert(1, os.path.join(HERE, '..', '..', 'nether-earth', 'tools'))
import kitlib as K  # noqa: E402

BASE = 0x4000
SHOTS, ROBOTS, MAP, POINTS = 0xD7D3, 0xDA00, 0xDD00, 0xFD70
CLOCK, SOUNDFX, HANDLER = 0xFD35, 0xFD53, 0xFDFE
PLAY_INTERRUPT = 0xD566
OURS, THEIRS, GREY = '#1080d0', '#d06010', '#808080'
OURS_RGB, THEIRS_RGB = (16, 128, 208), (208, 96, 16)
WEAPONS = {1: 'cannon', 2: 'missiles', 3: 'phasers'}


# ---------------------------------------------------------------------------------------------------------------
# memory pictures

class Pictures:
    """N memory pictures of $4000-$FFFF with their frame numbers and a note per picture"""

    def __init__(self, frames=None, mems=None, notes=None, meta=None):
        self.frames, self.mems = list(frames or []), list(mems or [])
        self.notes = list(notes or [''] * len(self.frames))
        self.meta = dict(meta or {})

    def add(self, frame, mem, note=''):
        self.frames.append(frame)
        self.mems.append(bytes(mem))
        self.notes.append(note)

    def save(self, path):
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        np.savez_compressed(path, frames=np.array(self.frames), mems=np.frombuffer(b''.join(self.mems), np.uint8)
                            .reshape(len(self.mems), 0xC000), notes=np.array(self.notes),
                            meta=np.array(json.dumps(self.meta)))
        print(f'{path}: {len(self.frames)} pictures, frames {self.frames[0]}-{self.frames[-1]}')

    @classmethod
    def load(cls, path):
        z = np.load(path)
        return cls(z['frames'].tolist(), [m.tobytes() for m in z['mems']], z['notes'].tolist(),
                   json.loads(str(z['meta'])))

    def __len__(self):
        return len(self.frames)

    def at(self, i):
        return View(self.mems[i], self.frames[i])


class View:
    """One memory picture, read by address"""

    def __init__(self, mem, frame=None):
        self.mem, self.frame = mem, frame

    def __getitem__(self, a):
        if isinstance(a, slice):
            return self.mem[a.start - BASE:a.stop - BASE]
        return self.mem[a - BASE]

    def word(self, a):
        return self[a] | self[a + 1] << 8

    def screen(self):
        return self[0x4000:0x5B00]

    def clock(self):
        return self[CLOCK + 2], self[CLOCK + 1], self[CLOCK]   # day, hour, minute

    def turn(self):
        d, h, m = self.clock()
        return (d * 24 + h) * 12 + m // 5

    def robot(self, slot):
        r = self[ROBOTS + 16 * slot:ROBOTS + 16 * slot + 16]
        if not r[1]:
            return None
        return {'slot': slot, 'x': r[2] | r[3] << 8, 'y': r[4], 'course': r[5], 'steps': r[6], 'parts': r[7],
                'facing': r[8], 'height': r[9], 'control': r[10], 'order': r[11], 'strength': r[12],
                'ground': r[13], 'target': r[14], 'delay': r[15], 'raw': r}

    def robots(self):
        return [r for r in (self.robot(i) for i in range(48)) if r]

    def shot(self, k):
        s = self[SHOTS + 9 * k:SHOTS + 9 * k + 9]
        return {'k': k, 'live': s[1] != 0, 'x': s[2] | s[3] << 8, 'y': s[4], 'dir': s[5], 'steps': s[6],
                'weapon': s[7], 'height': s[8], 'raw': s}

    def cell(self, x, y):
        return self[MAP + 0x200 * y + x]

    def view_x(self):
        return self.word(0xFD0A) & 0x1FF

    def point(self, i):
        p = self[POINTS + 5 * i:POINTS + 5 * i + 5]
        return {'x': p[0] | p[1] << 8, 'y': p[2], 'owner': p[3], 'count': p[4]}


def strength(s):
    """+$0C as a signed strength; $FC-$FF (dying) as negative"""
    return s - 256 if s >= 0x80 else s


# ---------------------------------------------------------------------------------------------------------------
# sources

def recording(work, unreal=None):
    sys.path.insert(0, os.path.join(K.unreal_root(unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, state = re_session.session_of(work)
    return session, state


DRIVER_START = bytes.fromhex('FE012005')  # GsDriver $C000 (CP 1; JR NZ): bank 6 paged in


def memory_at(session, frame, address=BASE, length=0xC000):
    for f in range(frame, frame + 4):  # the GS driver's page in at $C000: the next frame
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0,
                                         'offset': BASE, 'length': 0xC000}, ok=False)
        st = r.structured or {}
        if r.is_error or not st.get('exact'):
            raise SystemExit(f'memory_at {f}: {r.text}')
        data = bytes.fromhex(st['hex'])
        if data[0x8000:0x8004] != DRIVER_START:
            break
    return data[address - BASE:address - BASE + length]


def cmd_sample(args):
    session, _ = recording(args.work, args.unreal)
    a, b, s = (int(v) for v in args.frames.split(':'))
    pics = Pictures(meta={'source': args.work, 'frames': args.frames})
    for f in range(a, b, s):
        pics.add(f, memory_at(session, f))
    pics.save(args.out)


def cmd_snap(args):
    session, state = recording(args.work, args.unreal)
    import corpus  # noqa: E402  (on the path through recording())
    m = corpus.Machine(session, state['port_base'])
    print(session.call('time_travel', {'action': 'seek', 'frame': args.frame}, ok=False).text.splitlines()[0])
    print(m.post('/snapshot/save', {'path': os.path.abspath(args.out), 'force': True})['status'])


class Live:
    """An experiment on a live instance (tools/bot.py launch), with per-turn memory pictures"""

    def __init__(self, work, unreal=None, frame0=0):
        import bot
        self.bot = bot
        self.g = bot.Game(K.unreal_root(unreal), work).attach()
        self.g.frame = frame0
        self.pics = Pictures(meta={'source': work})
        self.cruise = 0

    def load(self, snapshot, frame0):
        """Load @p snapshot into the instance (the menus' state too); frames count from @p frame0"""
        self.g.stick(set())
        self.g.m.post('/snapshot/load', {'path': os.path.abspath(snapshot)})
        self.g.frame = frame0
        self.pics.meta['snapshot'] = os.path.relpath(snapshot, os.path.join(HERE, '..'))

    def mem(self):
        return self.g.m.read(BASE, 0xC000)

    def view(self):
        return View(bytes(self.mem()), self.g.frame)

    def poke(self, address, data):
        self.g.s.call('memory_access', {'action': 'write', 'address': f'0x{address:04X}',
                                        'hex': bytes(data).hex(' ')}, ok=False)
        got = bytes(self.g.m.read(address, len(data)))
        if got != bytes(data):
            raise SystemExit(f'poke {address:04X}: wrote {bytes(data).hex()}, reads {got.hex()}')
        self.pics.meta.setdefault('pokes', []).append(f'{address:04X}={bytes(data).hex()}@{self.g.frame}')

    def hover(self):
        """Keep the ship at self.cruise or higher (fire = up): a high ship blocks no robot"""
        if self.cruise:
            alt = self.g.m.read(0xFD10, 1)[0]
            self.g.stick({'fire'} if alt < self.cruise else set())

    def turns(self, n, note='', stop=None, keep=True):
        """Run @p n game turns, one picture a turn. The clock moves in GameTurn, at the end of a pass of the play
        loop: the frame before it holds the state after this pass's WorldTurn (its view copy may still be under
        way), the frame after it the finished view of that state, and the next pass's WorldTurn may already have run
        in it. A picture is the memory of the frame before with the screen of the frame after. stop(view) ends
        early"""
        done = 0
        before = bytes(self.mem())
        limit = self.g.frame + 60 * n + 200
        while done < n and self.g.frame < limit:
            self.hover()
            self.g.run(1)
            now = bytes(self.mem())
            if now[CLOCK - BASE:CLOCK - BASE + 3] != before[CLOCK - BASE:CLOCK - BASE + 3]:
                done += 1
                mem = now[:0x1B00] + before[0x1B00:]
                if keep:
                    self.pics.add(self.g.frame, mem, note)
                if stop and stop(View(mem, self.g.frame)):
                    break
            before = now
        return done

    def capture(self, on=True, every_frame=False):
        """From now on every frame the bot runs goes through the turn picture rule of turns() (or, with
        @p every_frame, every frame is a picture): menus driven by tools/bot.py are captured too"""
        g, run = self.g, self.bot.Game.run
        if not on:
            g.run = run.__get__(g)
            return
        state = {'before': bytes(self.mem())}

        def run_captured(frames):
            for _ in range(frames):
                run(g, 1)
                now = bytes(self.mem())
                b = state['before']
                if every_frame:
                    self.pics.add(g.frame, now, self.note)
                elif now[CLOCK - BASE:CLOCK - BASE + 3] != b[CLOCK - BASE:CLOCK - BASE + 3]:
                    self.pics.add(g.frame, now[:0x1B00] + b[0x1B00:], self.note)
                state['before'] = now
        g.run = run_captured

    note = ''

    def frames(self, n, note='', every=1):
        """One picture every @p every frames (the flash, the end screens)"""
        for i in range(n):
            self.hover()
            self.g.run(every)
            self.pics.add(self.g.frame, self.mem(), note)


def cmd_turns(args):
    lv = Live(args.work, args.unreal, args.frame0)
    if args.load:
        lv.load(args.load, args.frame0)
    if args.fly:
        x, y = (int(v) for v in args.fly.split(','))
        lv.g.fly_to(x, y, cruise=args.cruise, limit=3000)
        lv.cruise = args.cruise
        print('over', x, y, 'at frame', lv.g.frame)
    for p in args.poke or []:
        a, d = p.split('=')
        lv.poke(int(a, 16), bytes.fromhex(d))
    lv.turns(args.turns)
    if args.frames:
        lv.frames(args.frames, 'after the turns', args.every)
    lv.g.stick(set())
    lv.pics.meta.update({'fly': args.fly, 'frame0': args.frame0, 'cruise': args.cruise})
    lv.pics.save(args.out)


def cmd_combat(args):
    """Land on our robot, COMBAT MODE, fire its weapons in --fire order (2 phasers, 3 missiles, 4 cannon, 1 bomb),
    a refused one buzzes; one picture a turn, the menus included"""
    lv = Live(args.work, args.unreal, args.frame0)
    if args.load:
        lv.load(args.load, args.frame0)
    g, bot = lv.g, lv.bot
    for p in args.poke or []:
        a, d = p.split('=')
        lv.poke(int(a, 16), bytes.fromhex(d))
    if args.fly:
        x, y = (int(v) for v in args.fly.split(','))
        g.fly_to(x, y, cruise=args.cruise, limit=3000)
    lv.cruise = args.cruise
    while g.frame < args.land_at:
        lv.hover()
        g.run(2)
    lv.cruise = 0
    g.stick(set())
    lv.capture(every_frame=args.every_frame)
    lv.note = 'landing'
    print('landed', g.land_on_robot(args.slot), g.frame)
    lv.note = 'robot menu: COMBAT MODE'
    g.choose(bot.MAIN_MENU, 3)
    combat = (0x5837, 7)
    names = {1: 'NUCLEAR BOMB', 2: 'FIRE PHASERS', 3: 'FIRE MISSILES', 4: 'FIRE CANNON', 5: 'MOVE ROBOT'}
    for item in args.fire:
        lv.note = f'COMBAT MODE: moving to {names[item]}, fire'
        before = bytes(g.m.read(SHOTS, 9))
        n = len(lv.pics)
        g.choose(combat, item)
        launched = bytes(g.m.read(SHOTS, 9)) != before
        if item == 1:
            launched = not g.m.read(0xDA00 + 16 * args.slot + 1, 1)[0]
        lv.note = ('NUCLEAR BOMB: NuclearBlast, NuclearFlash (the game stands still)' if item == 1 and launched
                   else f'{names[item]}: shot record 0 launched, then a turn' if launched else
                   f'{names[item]} refused: no such part; Beep $FA, menu again')
        for k in range(n, len(lv.pics)):     # the pictures since the fire press
            if not lv.pics.notes[k].startswith('COMBAT MODE: moving'):
                lv.pics.notes[k] = lv.note
        g.run(args.gap)
        print('item', item, 'frame', g.frame, 'shot 0', bytes(g.m.read(SHOTS, 9)).hex(' '))
    lv.note = ''
    g.run(args.tail)
    lv.capture(False)
    lv.pics.meta.update({'slot': args.slot, 'fire': args.fire})
    lv.pics.save(args.out)


# ---------------------------------------------------------------------------------------------------------------
# geometry of the view (docs/06-rendering.md 6.3): the screen pixel of a map cell's ground point

def cell_pixel(x, y, view_x, height=0):
    """The screen pixel (x, y) at the middle of the bottom of a 3-byte sprite drawn for cell (x, y): the buffer
    (8, 8) on the screen, half-byte column 2E + D - 24, bottom line 8D + 100 - 4E - h"""
    e = x - view_x
    return 8 + 4 * (2 * e + y - 24) + 12, 8 + 8 * y + 100 - 4 * e - height


def screen_image(v, scale=2):
    im = K.render_screen(v.screen(), 0)
    return im.resize((256 * scale, 192 * scale), Image.NEAREST)


def view_crop(im, scale):
    """The view area: the 160 x 160 buffer at (8, 8)"""
    return im.crop((8 * scale, 8 * scale, 168 * scale, 168 * scale))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG'))
    sub = p.add_subparsers(dest='command', required=True)
    q = sub.add_parser('sample')
    q.add_argument('--work', required=True)
    q.add_argument('--frames', required=True, help='from:to:step')
    q.add_argument('--out', required=True)
    q.set_defaults(fn=cmd_sample)
    q = sub.add_parser('snap')
    q.add_argument('--work', required=True)
    q.add_argument('--frame', type=int, required=True)
    q.add_argument('--out', required=True)
    q.set_defaults(fn=cmd_snap)
    q = sub.add_parser('turns')
    q.add_argument('--work', required=True)
    q.add_argument('--frame0', type=int, default=0, help='the frame of the snapshot the instance started from')
    q.add_argument('--load', help='a snapshot to load first (cut by snap)')
    q.add_argument('--fly', help='X,Y: fly the ship over this cell first')
    q.add_argument('--cruise', type=int, default=45)
    q.add_argument('--turns', type=int, default=60)
    q.add_argument('--poke', nargs='*')
    q.add_argument('--frames', type=int, default=0, help='then this many pictures, one every --every frames')
    q.add_argument('--every', type=int, default=5)
    q.add_argument('--out', required=True)
    q.set_defaults(fn=cmd_turns)
    q = sub.add_parser('combat')
    q.add_argument('--work', required=True)
    q.add_argument('--load')
    q.add_argument('--frame0', type=int, default=0)
    q.add_argument('--fly')
    q.add_argument('--land-at', type=int, default=0, help='hover until this frame, then land')
    q.add_argument('--cruise', type=int, default=45, help='the hover altitude: above the robots\' tops')
    q.add_argument('--slot', type=int, required=True)
    q.add_argument('--fire', type=int, nargs='+', required=True)
    q.add_argument('--gap', type=int, default=40)
    q.add_argument('--every-frame', action='store_true', help='a picture every frame (the nuclear flash stops '
                   'the clock)')
    q.add_argument('--tail', type=int, default=60)
    q.add_argument('--poke', nargs='*')
    q.add_argument('--out', required=True)
    q.set_defaults(fn=cmd_combat)
    for name, fn in FIGURES.items():
        q = sub.add_parser(name)
        q.add_argument('--cache', nargs='+', required=True)
        q.add_argument('--out', required=True)
        q.add_argument('--opt', nargs='*', default=[], help='KEY=VALUE options of the figure')
        q.set_defaults(fn=fn)
    args = p.parse_args()
    args.fn(args)


FIGURES = {}


def figure(name):
    def wrap(fn):
        FIGURES[name] = fn
        return fn
    return wrap



# ---------------------------------------------------------------------------------------------------------------
# figures


DIRS = {1: (1, 0), 2: (-1, 0), 4: (0, 1), 8: (0, -1)}
PART_NAMES = ['bipod', 'tracks', 'anti-grav', 'cannon', 'missiles', 'phasers', 'nuclear', 'electronics']


def parts_text(parts):
    return ', '.join(n for b, n in enumerate(PART_NAMES) if parts >> b & 1)


def opts(args):
    return dict(o.split('=', 1) for o in args.opt)


def robot_point(r, view_x):
    """The screen pixel at a robot's feet (the sprite's lowest drawn line is 8 lines above its bottom line)"""
    x, y = cell_pixel(r['x'], r['y'], view_x, r['ground'])
    return x, y - 8


def shot_point(x, y, view_x, height=10):
    """The screen pixel of a shot sprite at cell (x, y) and flight height 10"""
    px, py = cell_pixel(x, y, view_x, height)
    return px + 4, py - 12


def outlined(d, xy, text, fill, font, outline=(0, 0, 0)):
    x, y = xy
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            if dx or dy:
                d.text((x + dx, y + dy), text, fill=outline, font=font)
    d.text(xy, text, fill=fill, font=font)


def bar(d, x, y, w, h, value, colour, font, label):
    d.rectangle([x, y, x + w, y + h], outline=K.DIM, fill=K.BACKGROUND)
    v = max(0, min(100, value))
    if v:
        d.rectangle([x + 1, y + 1, x + 1 + (w - 2) * v // 100, y + h - 1], fill=colour)
    d.text((x + w + 6, y - 1), label, fill=K.TEXT, font=font)


class Events:
    """What changed between two pictures: shots fired / moved / gone, strengths, deaths, removals"""

    def __init__(self, pics, slots=range(48)):
        self.pics, self.slots = pics, slots
        self.trails = {}      # shot record -> [(x, y)], the current flight
        self.ended = {}       # shot record -> (trail, turns since the end)

    def step(self, i):
        v = self.pics.at(i)
        p = self.pics.at(i - 1) if i else None
        out = []
        for k in range(5):
            s = v.shot(k)
            was = p.shot(k) if p else None
            fresh = s['live'] and (not was or not was['live'] or s['steps'] > was['steps'])
            if fresh:
                dx, dy = DIRS.get(s['dir'], (0, 0))
                self.trails[k] = [(s['x'] - 2 * dx, s['y'] - 2 * dy), (s['x'], s['y'])]
                side = 'the player\'s' if k == 0 else 'our' if k < 3 else 'enemy'
                out.append((k, f"{side} {WEAPONS.get(s['weapon'], '?')} fired (record {k})"))
            elif s['live']:
                self.trails.setdefault(k, []).append((s['x'], s['y']))
            elif was and not was['live'] and s['raw'] != was['raw']:
                # fired and ended in the same turn (FireShot takes the first step at once): only the freed
                # record's bytes tell
                dx, dy = DIRS.get(s['dir'], (0, 0))
                self.ended[k] = [[(s['x'] - 2 * dx, s['y'] - 2 * dy), (s['x'], s['y'])], 0]
                side = 'our' if k < 3 else 'enemy'
                out.append((k, f"{side} {WEAPONS.get(s['weapon'], '?')} fired, ended at once"))
            elif was and was['live']:
                trail = self.trails.pop(k, [])
                trail.append((s['x'], s['y']))   # a freed record keeps the cell of its last step
                self.ended[k] = [trail, 0]
        for k in list(self.ended):
            self.ended[k][1] += 1
            if self.ended[k][1] > 3:
                del self.ended[k]
        hits = []
        if p:
            for slot in self.slots:
                a, b = p.robot(slot), v.robot(slot)
                if a and b and a['strength'] != b['strength']:
                    sa, sb = strength(a['strength']), strength(b['strength'])
                    if 0 <= sb < sa:
                        out.append((None, f"robot {slot} hit: {sa} -> {sb}"))
                        hits.append(slot)
                    elif sa > 0 and sb < 0:
                        out.append((None, f"robot {slot} destroyed: {sa} -> ${b['strength']:02X}"))
                        hits.append(slot)
                if a and not b:
                    out.append((None, f"robot {slot} removed: slot freed"))
        return v, out, hits


def panel_robot(d, x, y, v, slot, font, small):
    r = v.robot(slot)
    colour = OURS_RGB if slot < 24 else THEIRS_RGB
    who = f"{'our' if slot < 24 else 'enemy'} robot {slot}"
    if not r:
        d.text((x, y), f'{who}: removed', fill=K.DIM, font=font)
        return
    s = strength(r['strength'])
    state = f'{s}' if s >= 0 else f"dying ${r['strength']:02X}"
    d.text((x, y), f"{who} ({r['x']},{r['y']})", fill=colour, font=font)
    bar(d, x, y + 18, 150, 10, max(s, 0), colour, small, f'strength {state}')
    d.text((x, y + 32), f"{parts_text(r['parts'])}; h {r['height']} + ground {r['ground']}", fill=K.DIM, font=small)


def shot_text(s):
    raw = ' '.join(f'{b:02X}' for b in s['raw'])
    if not s['live']:
        return raw, 'free'
    return raw, (f"({s['x']},{s['y']}) dir {s['dir']} steps {s['steps']} {WEAPONS.get(s['weapon'], '?')}")


@figure('fig-fight')
def fig_fight(args):
    """The duel: the view with the shots' paths, the two robots' strengths and the shot records beside it.
    opts: from=I to=I (picture indices), slots=2,25, scale=2"""
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    a, b = int(o.get('from', 0)), int(o.get('to', len(pics) - 1))
    slots = [int(s) for s in o.get('slots', '2,25').split(',')]
    S = int(o.get('scale', 3))
    font, small, big = K.font(13), K.font(11), K.font(16)
    ev = Events(pics, slots)
    log = []
    pictures = []
    for i in range(0, b + 1):
        v, out, hits = ev.step(i)
        log += [(pics.frames[i], text) for _, text in out]
        if i < a:
            continue
        vx = v.view_x()
        im = view_crop(screen_image(v, S), S).convert('RGB')
        d = ImageDraw.Draw(im)

        def pt(x, y):
            px, py = shot_point(x, y, vx)
            return S * (px - 8), S * (py - 8)

        for k, trail in list(ev.trails.items()) + [(k, t[0]) for k, t in ev.ended.items()]:
            colour = OURS_RGB if k < 3 else THEIRS_RGB
            pts = [pt(x, y) for x, y in trail]
            d.line(pts, fill=(0, 0, 0), width=5)
            d.line(pts, fill=colour, width=2)
            for q in pts[1:]:
                d.ellipse([q[0] - 7, q[1] - 7, q[0] + 7, q[1] + 7], outline=(0, 0, 0), width=4)
                d.ellipse([q[0] - 6, q[1] - 6, q[0] + 6, q[1] + 6], outline=colour, width=2)
        for slot in slots:
            r = v.robot(slot)
            if not r:
                continue
            px, py = robot_point(r, vx)
            X, Y = S * (px - 8), S * (py - 8)
            colour = OURS_RGB if slot < 24 else THEIRS_RGB
            if slot in hits:
                for rad, w in ((34, 4), (24, 3)):
                    d.ellipse([X - rad, Y - 30 - rad, X + rad, Y - 30 + rad], outline=(220, 0, 0), width=w)
            label = f"{'ours' if slot < 24 else 'enemy'} {slot}"
            lx = min(X + 8 * S, im.width - 10 * len(label) - 4)
            outlined(d, (lx, Y - 30 * S), label, colour, big, (255, 255, 255))
        W = 340
        canvas = Image.new('RGB', (im.width + W, im.height + 26), K.BACKGROUND)
        canvas.paste(im, (0, 26))
        d = ImageDraw.Draw(canvas)
        day, hour, minute = v.clock()
        d.text((6, 5), f'frame {pics.frames[i]}   day {day} {hour:02d}:{minute:02d}   (turn picture {i})',
               fill=K.TEXT, font=font)
        x0 = im.width + 12
        y = 34
        for slot in slots:
            panel_robot(d, x0, y, v, slot, font, small)
            y += 58
        d.text((x0, y), 'shot records $D7D3 (9 bytes each)', fill=K.TEXT, font=font)
        y += 18
        for k in range(1, 5):
            s = v.shot(k)
            raw, text = shot_text(s)
            colour = (OURS_RGB if k < 3 else THEIRS_RGB) if s['live'] else K.DIM
            d.text((x0, y), f'{k} {raw}', fill=colour, font=small)
            d.text((x0 + 14, y + 13), text, fill=colour, font=small)
            y += 30
        y += 4
        d.text((x0, y), 'events', fill=K.TEXT, font=font)
        y += 18
        for f, text in log[-int(o.get('events', 9)):]:
            d.text((x0, y), f'{f} {text}', fill=K.TEXT if f == pics.frames[i] else K.DIM, font=small)
            y += 14
        pictures.append(canvas)
    delays = [int(o.get('delay', 160))] * (len(pictures) - 1) + [2500]
    K.save_gif(args.out, pictures, delays)
    print(args.out, len(pictures), os.path.getsize(args.out))


@figure('fig-strip')
def fig_strip(args):
    """Turn pictures side by side, zoomed on the robots of `slots`: a shot's flight.
    opts: rows=23,24,25,26;30,31,32 (picture indices), slots=2,25, scale=3, titles=TEXT;TEXT"""
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    rows = [[int(i) for i in r.split(',')] for r in o['rows'].split(';')]
    titles = o.get('titles', '').split(';')
    slots = [int(s) for s in o.get('slots', '2,25').split(',')]
    S = int(o.get('scale', 3))
    font, small = K.font(13), K.font(11)
    ev = Events(pics, slots)
    states = {}
    for i in range(max(max(r) for r in rows) + 1):
        v, out, hits = ev.step(i)
        states[i] = (v, out, hits, {k: list(t) for k, t in ev.trails.items()},
                     {k: list(t[0]) for k, t in ev.ended.items() if t[1] == 1})
    # one box for all: the robots' feet and heads over the pictures used
    xs, ys = [], []
    for r in rows:
        for i in r:
            v = states[i][0]
            for slot in slots:
                rb = v.robot(slot)
                if rb:
                    px, py = robot_point(rb, v.view_x())
                    xs += [px - 14, px + 14]
                    ys += [py - 40, py + 6]
    box = (min(xs) - 6, min(ys) - 6, max(xs) + 6, max(ys) + 6)
    pw, ph = S * (box[2] - box[0]), S * (box[3] - box[1])
    gap, head, foot = 10, 24, 58
    cols = max(len(r) for r in rows)
    legend = 30
    canvas = Image.new('RGB', (cols * (pw + gap) + gap, len(rows) * (ph + head + foot) + 4 + legend), K.BACKGROUND)
    d = ImageDraw.Draw(canvas)
    # the legend: what each mark is
    ly = len(rows) * (ph + head + foot) + 4 + 8
    lx = gap
    for colour, text in ((THEIRS_RGB, "the enemy's shot"), (OURS_RGB, 'our shot')):
        d.line([(lx, ly + 7), (lx + 34, ly + 7)], fill=colour, width=2)
        for q in (lx + 6, lx + 28):
            d.ellipse([q - 5, ly + 2, q + 5, ly + 12], outline=colour, width=2)
        d.text((lx + 42, ly), text, fill=K.TEXT, font=small)
        lx += 42 + int(d.textlength(text, font=small)) + 18
    d.text((lx, ly), '(a ring each turn)', fill=K.TEXT, font=small)
    lx += int(d.textlength('(a ring each turn)', font=small)) + 24
    d.ellipse([lx, ly - 2, lx + 18, ly + 16], outline=(220, 0, 0), width=3)
    d.text((lx + 26, ly), 'the robot hit', fill=K.TEXT, font=small)
    for ri, r in enumerate(rows):
        y0 = ri * (ph + head + foot) + 4
        if ri < len(titles) and titles[ri]:
            d.text((gap, y0), titles[ri], fill=K.TEXT, font=font)
        for ci, i in enumerate(r):
            v, out, hits, trails, ended = states[i]
            vx = v.view_x()
            im = screen_image(v, S).crop((S * box[0], S * box[1], S * box[2], S * box[3])).convert('RGB')
            dd = ImageDraw.Draw(im)
            for slot in slots:  # name the robots
                rb = v.robot(slot)
                if rb:
                    px, py = robot_point(rb, vx)
                    label = f"{'our robot' if slot < 24 else 'enemy'} {slot}"
                    lx0, ly0 = S * (px - box[0]) - 34, S * (py - box[1]) + 6
                    tw = int(dd.textlength(label, font=small))
                    dd.rectangle([lx0 - 3, ly0 - 2, lx0 + tw + 3, ly0 + 14], fill=K.BACKGROUND)
                    dd.text((lx0, ly0), label, fill=OURS_RGB if slot < 24 else THEIRS_RGB, font=small)
            for k, trail in list(trails.items()) + list(ended.items()):
                colour = OURS_RGB if k < 3 else THEIRS_RGB
                pts = [(S * (shot_point(x, y, vx)[0] - box[0]), S * (shot_point(x, y, vx)[1] - box[1]))
                       for x, y in trail]
                dd.line(pts, fill=(0, 0, 0), width=5)
                dd.line(pts, fill=colour, width=2)
                for q in pts[1:]:
                    dd.ellipse([q[0] - 7, q[1] - 7, q[0] + 7, q[1] + 7], outline=(0, 0, 0), width=4)
                    dd.ellipse([q[0] - 6, q[1] - 6, q[0] + 6, q[1] + 6], outline=colour, width=2)
            for slot in hits:
                rb = v.robot(slot)
                px, py = robot_point(rb, vx)
                X, Y = S * (px - box[0]), S * (py - box[1]) - 30
                dd.ellipse([X - 36, Y - 36, X + 36, Y + 36], outline=(220, 0, 0), width=4)
            x0 = gap + ci * (pw + gap)
            canvas.paste(im, (x0, y0 + head))
            yy = y0 + head + ph + 4
            d.text((x0, yy), f'frame {pics.frames[i]}', fill=K.TEXT, font=small)
            yy += 14
            for k in range(1, 5):
                s = v.shot(k)
                if s['live']:
                    d.text((x0, yy), f"rec {k}: ({s['x']},{s['y']}) steps {s['steps']}",
                           fill=OURS_RGB if k < 3 else THEIRS_RGB, font=small)
                    yy += 14
            for _, text in out:
                d.text((x0, yy), text.replace('robot ', 'r'), fill=(230, 90, 80), font=small)
                yy += 14
    canvas.save(args.out)
    print(args.out, canvas.size)


def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams['text.usetex'] = False
    plt.rcParams['text.parse_math'] = False
    return plt


SHOT_FIELDS = ['cell lo', 'cell hi', 'X lo', 'X hi', 'Y', 'dir', 'steps', 'weapon', 'height']


def shot_events(pics, a, b):
    """[(frame, text, colour)]: shots fired and robots hit between pictures a..b"""
    out = []
    for i in range(max(a, 1), b + 1):
        v, p = pics.at(i), pics.at(i - 1)
        for k in range(5):
            s, w = v.shot(k), p.shot(k)
            if s['live'] and (not w['live'] or s['steps'] > w['steps']):
                out.append((pics.frames[i], f"rec {k} fired", OURS if k < 3 else THEIRS))
        for slot in range(48):
            r, q = v.robot(slot), p.robot(slot)
            if r and q and r['strength'] != q['strength'] and strength(r['strength']) < strength(q['strength']):
                out.append((pics.frames[i], f"robot {slot} {strength(q['strength'])}->{strength(r['strength'])}",
                            '#c00000'))
    return out


@figure('fig-shot-record')
def fig_shot_record(args):
    """The bytes of the shot records $D7D3 at every frame, and the decoded flight.
    opts: from=FRAME to=FRAME recs=1,3 (the records shown; the others stayed 0)"""
    plt = plt_setup()
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    a = pics.frames.index(int(o.get('from', pics.frames[0])))
    b = pics.frames.index(int(o.get('to', pics.frames[-1])))
    recs = [int(k) for k in o.get('recs', '0,1,2,3,4').split(',')]
    frames = pics.frames[a:b + 1]
    full = np.array([list(pics.at(i)[SHOTS:SHOTS + 45]) for i in range(a, b + 1)]).T
    grid = np.concatenate([full[9 * k:9 * k + 9] for k in recs])
    n = len(grid)
    unused = [k for k in range(5) if k not in recs and not full[9 * k:9 * k + 9].any()]
    fig, (ax, ax2) = plt.subplots(2, 1, figsize=(12, 3.2 + 0.24 * n + 2.6), dpi=100, sharex=True,
                                  gridspec_kw={'height_ratios': [0.24 * n, 2.4]})
    ax.imshow(grid, aspect='auto', interpolation='nearest', cmap='magma', vmin=0, vmax=255,
              extent=(frames[0] - 0.5, frames[-1] + 0.5, n - 0.5, -0.5))
    ax.set_yticks(range(n))
    ax.set_yticklabels([f'+{j} {SHOT_FIELDS[j]}' for _ in recs for j in range(9)], fontsize=9)
    for k in range(1, len(recs)):
        ax.axhline(9 * k - 0.5, color='white', lw=1.5)
    # the values, written where they change
    for row in range(n):
        last = None
        for c, f in enumerate(frames):
            val = grid[row, c]
            if val != last:
                held = c + 3 >= len(frames) or all(grid[row, c + j] == val for j in range(1, 4))
                if held:  # a value held under 4 frames would overprint the next one
                    ax.text(f + 0.6, row, f'{val:02X}', fontsize=8, va='center', ha='left',
                            color='white' if val < 140 else 'black')
                last = val
    for i, k in enumerate(recs):
        side = 'the player' if k == 0 else 'ours' if k < 3 else 'the enemy'
        ax.text(1.008, 1 - (9 * i + 4.5) / n, f'record {k}\n({side})', transform=ax.transAxes, fontsize=10,
                va='center', ha='left', color=OURS if 0 < k < 3 else THEIRS if k >= 3 else GREY,
                fontweight='bold')
    ev = shot_events(pics, a, b)
    for f, text, colour in ev:
        for x in (ax, ax2):
            x.axvline(f, color=colour, lw=0.9, ls='--', alpha=0.8)
        ax.text(f, -0.8, text.replace('rec ', 'record ').replace('->', ' -> '), rotation=90, fontsize=8.5,
                color=colour, va='bottom', ha='center')
    ax.set_title(o.get('title', 'Two shots in their records: filled at once, +6 counts the steps down, '
                 '+1 = 0 frees the record and the other bytes stay')
                 + (f"\n(records {', '.join(map(str, unused))} stayed 0 in these frames)" if unused else ''),
                 fontsize=11, pad=96)
    ax3 = ax2.twinx()
    for k in recs:
        colour = OURS if k < 3 else THEIRS
        live = [pics.at(i).shot(k) for i in range(a, b + 1)]
        flown, start = [], None
        for s in live:
            c = (s['x'] if s['dir'] in (1, 2) else s['y']) if s['live'] else None
            start = None if c is None else (c if start is None else start)
            flown.append(np.nan if c is None else abs(c - start))
        ax2.step(frames, flown, where='post', color=colour, lw=2,
                 label=f'record {k}: cells flown since the first picture of the shot (+2 or +4), 2 a turn')
        ax3.step(frames, [s['steps'] if s['live'] else np.nan for s in live], where='post', color=colour, lw=1.4,
                 ls=':', label=f'record {k}: steps left (+6), right scale')
    ax2.set_ylabel('cells flown')
    ax3.set_ylabel('steps left')
    ax3.set_ylim(0, 9)
    ax2.set_xlabel('frame of work/gsB/rT (one game turn is about 10 frames)')
    h2, l2 = ax2.get_legend_handles_labels()
    h3, l3 = ax3.get_legend_handles_labels()
    ax2.legend(h2 + h3, l2 + l3, fontsize=9, ncol=1, loc='upper center')
    ax2.grid(alpha=0.3)
    ax2.set_ylim(0, 9)
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out)


def damage(height, ground, weapon):
    """MoveShot: ((60 - (+$09 + +$0D)) / 4) x (weapon + 1), integer division"""
    return ((60 - (height + ground)) // 4) * (weapon + 1)


@figure('fig-strength')
def fig_strength(args):
    """The strength +$0C of the robots in `slots` at every frame, each drop annotated with the formula.
    opts: slots=2,25"""
    plt = plt_setup()
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    slots = [int(s) for s in o.get('slots', '2,25').split(',')]
    fig, ax = plt.subplots(figsize=(12, 5.2), dpi=100)
    placed = []
    for slot in slots:
        colour = OURS if slot < 24 else THEIRS
        xs, ys, prev = [], [], None
        for i, f in enumerate(pics.frames):
            v = pics.at(i)
            r = v.robot(slot)
            s = strength(r['strength']) if r else None
            xs.append(f)
            ys.append(np.nan if s is None else s)
            if r and prev is not None and s < prev[0]:
                # the shot that hit: the record freed in this frame, else the stale one of the shooter's side
                q = pics.at(i - 1)
                k = next((k for k in range(5) if q.shot(k)['live'] and not v.shot(k)['live']), None)
                if k is None:
                    k = next((k for k in range(5) if q.shot(k)['raw'] != v.shot(k)['raw']), None)
                w = v.shot(k)['weapon'] if k is not None else 0
                h, g = r['height'], r['ground']
                dmg = damage(h, g, w)
                text = f"{WEAPONS.get(w, '?')} -{dmg}"
                if s < 0:
                    text += f': {prev[0]} - {dmg} <= 0, dying'
                late = f > pics.frames[-1] - 160
                ty = (prev[0] + max(s, 0)) / 2
                while any(abs(f - pf) < 120 and abs(ty - py) < 6 for pf, py in placed):
                    ty -= 7
                placed.append((f, ty))
                ax.text(f + (-6 if late else 6), ty, text, fontsize=8, color=colour,
                        ha='right' if late else 'left', va='center',
                        bbox={'facecolor': 'white', 'edgecolor': 'none', 'alpha': 0.85, 'pad': 1})
            prev = (s, r) if r else None
        name = parts_text(pics.at(0).robot(slot)['parts'])
        ax.step(xs, ys, where='post', color=colour, lw=2,
                label=f"{'our' if slot < 24 else 'enemy'} robot {slot} ({name}; height {pics.at(0).robot(slot)['height']})")
    ax.axhline(0, color='black', lw=0.8)
    ax.axhspan(-4.5, -0.5, color='#c00000', alpha=0.08)
    ax.text(pics.frames[0] + 5, -2.5, 'dying: $FC-$FF (-4..-1), + 1 a turn, then removed', fontsize=8,
            color='#c00000', va='center')
    ax.set_ylim(-6, 112)
    ax.set_xlim(pics.frames[0], pics.frames[-1])
    ax.set_ylabel('strength (+$0C, signed)')
    ax.set_xlabel('frame (work/gsB/rT)')
    ax.set_title(o.get('title', 'Every hit takes exactly the formula: height 19 on flat ground gives '
                 '(60 - 19) / 4 = 10 a point, cannon x 2 = 20, missiles x 3 = 30'), fontsize=11)
    ax.legend(loc='upper right', fontsize=9)
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out)


@figure('fig-damage-table')
def fig_damage_table(args):
    """The damage of one hit by the victim's height + ground and the weapon, with the hits seen in the
    recordings (cache: a 10-frame sampling, e.g. deep10.npz, and per-frame samples)"""
    plt = plt_setup()
    hs = list(range(13, 60))
    seen = {}
    for path in args.cache:
        pics = Pictures.load(path)
        for i in range(1, len(pics)):
            v, q = pics.at(i), pics.at(i - 1)
            for slot in range(48):
                r, p = v.robot(slot), q.robot(slot)
                if r and p and 0 < strength(p['strength']) and strength(r['strength']) < strength(p['strength']):
                    d = strength(p['strength']) - strength(r['strength'])
                    hg = r['height'] + r['ground']
                    if strength(r['strength']) >= 0:
                        seen.setdefault((hg, d), set()).add(slot)
    fig, ax = plt.subplots(figsize=(11, 5.4), dpi=100)
    colours = {1: '#4a9a4a', 2: '#c07000', 3: '#7040c0'}
    for w in (1, 2, 3):
        ax.step(hs, [damage(h, 0, w) for h in hs], where='mid', color=colours[w], lw=2,
                label=f'{WEAPONS[w]} (weapon {w}): x {w + 1}')
    for (hg, d), slots in sorted(seen.items()):
        w = next((w for w in (1, 2, 3) if damage(hg, 0, w) == d), None)
        ax.plot(hg, d, marker='o', ms=9, mfc='none', mew=2, color=colours.get(w, 'red'))
    ax.plot([], [], marker='o', ms=9, mfc='none', mew=2, color='#555', ls='', label='a hit seen in work/gsB/rT: every one '
            'on the line (samples every 30 frames)')
    for h, name in ((17, 'bipod + cannon'), (19, 'tracks + cannon + missiles'), (34, 'tracks + 3 weapons + electr.')):
        ax.axvline(h, color='#999', lw=0.8, ls=':')
        ax.text(h + 0.2, 61, name, rotation=90, fontsize=7.5, color='#666', va='top')
    ax.set_xlabel('the victim: height +$09 + ground +$0D')
    ax.set_ylabel('damage of one hit')
    ax.set_title('Damage = ((60 - (height + ground)) / 4) x (weapon + 1), integer division (MoveShot $B724); '
                 'a robot starts at 100', fontsize=10)
    ax.set_ylim(0, 62)
    ax.set_xlim(hs[0], hs[-1])
    ax.grid(alpha=0.3)
    ax.legend(fontsize=9, loc='upper right')
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out, sorted(seen))


def cell_rgb(c):
    import doc_figures
    return doc_figures.cell_colour(c)


@figure('fig-hit-test')
def fig_hit_test(args):
    """The 3 x 3 test of MoveShot over the real map: per panel the cells around a shot's new cell before the step,
    the order of the nine tests, the anchors (bit 6) and the robots' 2 x 2 footprints.
    opts: steps=FRAME:K,FRAME:K (the picture before the step, the shot record), cols=119-127, rows=4-13"""
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    steps = [tuple(int(v) for v in s.split(':')) for s in o['steps'].split(',')]
    c0, c1 = (int(v) for v in o.get('cols', '119-127').split('-'))
    r0, r1 = (int(v) for v in o.get('rows', '4-13').split('-'))
    cs = 46
    font, small, tiny = K.font(13), K.font(11), K.font(9)
    panels = []
    for frame, k in steps:
        v = pics.at(pics.frames.index(frame))
        s = v.shot(k)
        dx, dy = DIRS[s['dir']]
        nx, ny = s['x'] + 2 * dx, s['y'] + 2 * dy
        W, H = (c1 - c0 + 1) * cs, (r1 - r0 + 1) * cs
        im = Image.new('RGB', (max(W + 60, 660), H + 170), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        ox, oy = 40, 30

        def box(x, y):
            return ox + (x - c0) * cs, oy + (y - r0) * cs

        for y in range(r0, r1 + 1):
            d.text((6, box(c0, y)[1] + cs // 2 - 6), f'{y}', fill=K.DIM, font=small)
            for x in range(c0, c1 + 1):
                c = v.cell(x, y)
                if x == s['x'] and y == s['y']:
                    c &= ~0x40      # UpdateShot clears the shot's own mark before the step
                X, Y = box(x, y)
                d.rectangle([X, Y, X + cs - 1, Y + cs - 1], fill=cell_rgb(c), outline=(60, 60, 70))
                rgb = cell_rgb(c)
                d.text((X + 3, Y + 2), f'{c:02X}', fill=(20, 20, 20) if sum(rgb) > 450 else (230, 230, 230),
                       font=tiny)
                if c & 0x40:
                    d.ellipse([X + cs // 2 - 7, Y + cs // 2 - 7, X + cs // 2 + 7, Y + cs // 2 + 7],
                              fill=(255, 255, 255), outline=(0, 0, 0))
        for x in range(c0, c1 + 1):
            d.text((box(x, r0)[0] + cs // 2 - 10, 10), f'{x}', fill=K.DIM, font=small)
        for r in v.robots():
            if c0 <= r['x'] <= c1 and r0 <= r['y'] <= r1:
                X, Y = box(r['x'], r['y'] - 1)
                colour = OURS_RGB if r['slot'] < 24 else THEIRS_RGB
                d.rectangle([X + 2, Y + 2, X + 2 * cs - 3, Y + 2 * cs - 3], outline=colour, width=4)
                d.text((X + 18, Y + 14), f"{'ours' if r['slot'] < 24 else 'enemy'} {r['slot']}",
                       fill=colour, font=small)
        # the 3 x 3 window in test order: row above, own row, row below; each left to right
        hit = None
        n = 0
        for yy in (ny - 1, ny, ny + 1):
            for xx in (nx - 1, nx, nx + 1):
                n += 1
                if not (r0 <= yy <= r1 and c0 <= xx <= c1):
                    continue
                X, Y = box(xx, yy)
                c = v.cell(xx, yy) & ~(0x40 if (xx, yy) == (s['x'], s['y']) else 0)
                found = hit is None and c & 0x40
                if found:
                    hit = (n, xx, yy)
                outlined(d, (X + cs - 14, Y + cs - 17), str(n), (255, 80, 80) if found else (255, 230, 120), font)
        X0, Y0 = box(nx - 1, ny - 1)
        d.rectangle([X0, Y0, X0 + 3 * cs, Y0 + 3 * cs], outline=(255, 230, 120), width=3)
        colour = OURS_RGB if k < 3 else THEIRS_RGB
        a, b = box(s['x'], s['y']), box(nx, ny)
        d.line([a[0] + cs // 2, a[1] + cs // 2, b[0] + cs // 2, b[1] + cs // 2], fill=colour, width=5)
        d.ellipse([a[0] + cs // 2 - 9, a[1] + cs // 2 - 9, a[0] + cs // 2 + 9, a[1] + cs // 2 + 9], outline=colour,
                  width=3)
        d.ellipse([b[0] + cs // 2 - 12, b[1] + cs // 2 - 12, b[0] + cs // 2 + 12, b[1] + cs // 2 + 12],
                  fill=colour, outline=(0, 0, 0), width=2)
        y = oy + H + 10
        d.text((ox, y), f"frame {frame}: shot record {k} ({WEAPONS[s['weapon']]}) at ({s['x']},{s['y']}), "
                        f"dir {s['dir']}", fill=K.TEXT, font=font)
        y += 18
        d.text((ox, y), f"UpdateShot clears its mark, MoveShot steps 2 cells to ({nx},{ny})", fill=K.TEXT, font=font)
        y += 20
        if hit:
            r = next((r for r in v.robots() if (r['x'], r['y']) == (hit[1], hit[2])), None)
            who = f"robot {r['slot']}, strength {strength(r['strength'])}" if r else 'an object'
            d.text((ox, y), f"test {hit[0]} finds bit 6 at ({hit[1]},{hit[2]}): {who}: MoveShotHit",
                   fill=(255, 110, 110), font=font)
        else:
            d.text((ox, y), 'no bit 6 in the 9 cells: MoveShotFlies sets bit 6 on the new cell', fill=K.TEXT,
                   font=font)
        y += 24
        d.ellipse([ox, y + 2, ox + 12, y + 14], fill=(255, 255, 255), outline=(0, 0, 0))
        d.text((ox + 18, y), 'bit 6: an object anchored there (robot, building, shot)', fill=K.DIM,
               font=small)
        y += 18
        d.rectangle([ox, y + 2, ox + 12, y + 14], outline=OURS_RGB, width=3)
        d.text((ox + 18, y), "a robot's 2 x 2 footprint: only its anchor (lower left) has bit 6", fill=K.DIM,
               font=small)
        y += 18
        d.text((ox, y), "cell bytes: the map $DD00 + $200 x row + column; 1-9: the order of the tests",
               fill=K.DIM, font=small)
        panels.append(im)
    W = sum(p.width for p in panels) + 10 * (len(panels) - 1)
    out = Image.new('RGB', (W, max(p.height for p in panels)), K.BACKGROUND)
    x = 0
    for p in panels:
        out.paste(p, (x, 0))
        x += p.width + 10
    out.save(args.out)
    print(args.out, out.size)


def robot_box(v, r, margin=(22, 46, 22, 10)):
    """A screen box around robot r (feet point - margins)"""
    px, py = robot_point(r, v.view_x())
    x0, y0, x1, y1 = px - margin[0], py - margin[1], px + margin[2], py + margin[3]
    dx = max(0, x1 - 168) - max(0, 8 - x0)      # keep it inside the view (the buffer at 8-167)
    dy = max(0, y1 - 168) - max(0, 8 - y0)
    return x0 - dx, y0 - dy, x1 - dx, y1 - dy


@figure('fig-death')
def fig_death(args):
    """A dying robot, zoomed: +$0C from $FC to 0 and its cell's bit 6 toggled each turn, then removed.
    opts: slot=25 from=I to=I scale=5 (the out .gif); with wreck=I,J also the before / after picture (out2=PNG)"""
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    slot = int(o.get('slot', 25))
    a, b = int(o['from']), int(o['to'])
    S = int(o.get('scale', 5))
    font, small = K.font(14), K.font(12)
    r0 = next(pics.at(i).robot(slot) for i in range(a, b + 1) if pics.at(i).robot(slot))
    v0 = pics.at(a)
    bx = robot_box(v0, r0, (40, 64, 40, 18))
    cells = [(r0['x'], r0['y'] - 1), (r0['x'] + 1, r0['y'] - 1), (r0['x'], r0['y']), (r0['x'] + 1, r0['y'])]
    pictures = []
    for i in range(a, b + 1):
        v = pics.at(i)
        im = screen_image(v, S).crop(tuple(S * c for c in bx)).convert('RGB')
        r = v.robot(slot)
        canvas = Image.new('RGB', (im.width + 370, max(im.height, 230) + 30), K.BACKGROUND)
        canvas.paste(im, (0, 30))
        d = ImageDraw.Draw(canvas)
        day, hour, minute = v.clock()
        d.text((6, 7), f'frame {pics.frames[i]}  day {day} {hour:02d}:{minute:02d}', fill=K.TEXT, font=font)
        x0, y = im.width + 14, 40
        colour = OURS_RGB if slot < 24 else THEIRS_RGB
        d.text((x0, y), f"{'our' if slot < 24 else 'enemy'} robot {slot}", fill=colour, font=font)
        y += 24
        if r:
            s = r['strength']
            state = 'alive' if s < 0x80 and s else 'dying' if s >= 0xFC else 'removed next turn'
            d.text((x0, y), f'+$0C strength  ${s:02X} ({strength(s)}): {state}', fill=K.TEXT, font=small)
        else:
            d.text((x0, y), 'slot freed (RobotDestroyed)', fill=K.TEXT, font=small)
        y += 22
        d.text((x0, y), 'its cells (anchor last):', fill=K.TEXT, font=small)
        y += 18
        for (x, yy) in cells:
            c = v.cell(x, yy)
            mark = '  bit 6 set: drawn, can be hit' if c & 0x40 else ''
            d.text((x0 + 8, y), f'({x},{yy}) ${c:02X}{mark}', fill=(255, 230, 120) if c & 0x40 else K.DIM, font=small)
            y += 16
        y += 8
        d.text((x0, y), f'SoundFx $FD53 = ${v[SOUNDFX]:02X}', fill=K.DIM, font=small)
        y += 30
        for line in ('While dying, +$0C counts $FC..$FF, 0', 'and bit 6 of the anchor toggles each turn:',
                     'the robot is drawn (and can be hit)', 'only every other turn.'):
            d.text((x0, y), line, fill=K.TEXT, font=small)
            y += 16
        pictures.append(canvas)
    K.save_gif(args.out, pictures, [int(o.get('delay', 500))] * (len(pictures) - 1) + [2500])
    print(args.out, len(pictures), os.path.getsize(args.out))
    if 'wreck' in o:
        i, j = (int(v) for v in o['wreck'].split(','))
        parts = []
        for k, title in ((i, 'before: the robot at strength 10'), (j, 'after: the wreck, slot freed')):
            v = pics.at(k)
            im = screen_image(v, S).crop(tuple(S * c for c in bx)).convert('RGB')
            pane = Image.new('RGB', (im.width, im.height + 110), K.BACKGROUND)
            pane.paste(im, (0, 26))
            d = ImageDraw.Draw(pane)
            d.text((4, 5), f'{title}, frame {pics.frames[k]}', fill=K.TEXT, font=small)
            y = im.height + 34
            for (x, yy) in cells:
                c = v.cell(x, yy)
                d.text((8, y), f'cell ({x},{yy}) = ${c:02X}: type {c & 0x1F}' + (', bit 5: not an anchor'
                       if c & 0x20 else '') + (', bit 6: an anchor' if c & 0x40 else ''), fill=K.TEXT, font=small)
                y += 17
            parts.append(pane)
        out = Image.new('RGB', (sum(p.width for p in parts) + 12, max(p.height for p in parts)), K.BACKGROUND)
        out.paste(parts[0], (0, 0))
        out.paste(parts[1], (parts[0].width + 12, 0))
        out.save(o['out2'])
        print(o['out2'], out.size)


def draw_trails(d, ev, vx, S, off=(0, 0)):
    for k, trail in list(ev.trails.items()) + [(k, t[0]) for k, t in ev.ended.items()]:
        colour = (230, 60, 200) if k == 0 else OURS_RGB if k < 3 else THEIRS_RGB
        pts = [(S * (shot_point(x, y, vx)[0] - off[0]), S * (shot_point(x, y, vx)[1] - off[1])) for x, y in trail]
        d.line(pts, fill=(0, 0, 0), width=5)
        d.line(pts, fill=colour, width=2)
        for q in pts[1:]:
            d.ellipse([q[0] - 7, q[1] - 7, q[0] + 7, q[1] + 7], outline=(0, 0, 0), width=4)
            d.ellipse([q[0] - 6, q[1] - 6, q[0] + 6, q[1] + 6], outline=colour, width=2)


@figure('fig-screen')
def fig_screen(args):
    """The whole screen a picture (menus included), the shots' paths over the view, the picture's note and the
    events below. opts: from=I to=I scale=2 slots=2,25 delay=200 every=1 title=TEXT"""
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    a, b = int(o.get('from', 0)), int(o.get('to', len(pics) - 1))
    S = int(o.get('scale', 2))
    slots = [int(s) for s in o['slots'].split(',')] if 'slots' in o else range(48)
    every = int(o.get('every', 1))
    font, small = K.font(13), K.font(12)
    ev = Events(pics, slots)
    log = []
    pictures = []
    for i in range(0, b + 1):
        v, out, hits = ev.step(i)
        log += [(pics.frames[i], text) for _, text in out]
        if i < a or (i - a) % every and i != b:
            continue
        if 'dense' in o:
            # every-frame pictures: one a turn (the clock moved), and every n-th in the dense range
            rng, n = o['dense'].split(':')
            d0, d1 = (int(x) for x in rng.split('-'))
            turn = i == a or i == b or pics.at(i - 1).clock() != v.clock()
            if not (turn or (d0 <= i <= d1 and (i - d0) % int(n) == 0)):
                continue
        im = screen_image(v, S).convert('RGB')
        d = ImageDraw.Draw(im)
        if v.word(HANDLER) == PLAY_INTERRUPT:
            draw_trails(d, ev, v.view_x(), S)
            for slot in hits:
                r = v.robot(slot)
                if r:
                    px, py = robot_point(r, v.view_x())
                    X, Y = S * px, S * py - 30
                    d.ellipse([X - 30, Y - 30, X + 30, Y + 30], outline=(220, 0, 0), width=4)
        lines = int(o.get('lines', 4))
        canvas = Image.new('RGB', (im.width, im.height + 30 + 16 * lines), K.BACKGROUND)
        d = ImageDraw.Draw(canvas)
        day, hour, minute = v.clock()
        d.text((6, 6), f"{o.get('title', '')}  frame {pics.frames[i]}, day {day} {hour:02d}:{minute:02d}",
               fill=K.TEXT, font=font)
        canvas.paste(im, (0, 26))
        y = im.height + 30
        note = pics.notes[i]
        for spec in [s for s in o.get('notes', '').split('|') if s]:
            rng, text = spec.split(':', 1)
            n0, n1 = (int(x) for x in rng.split('-'))
            if n0 <= i <= n1:
                note = text
        if note:
            d.text((6, y), note, fill=(255, 230, 120), font=small)
            y += 16
        for f, text in log[-(lines - (1 if note else 0)):]:
            d.text((6, y), f'{f} {text}', fill=K.TEXT if f == pics.frames[i] else K.DIM, font=small)
            y += 16
        pictures.append(canvas)
    if args.out.endswith('.png'):
        pictures[-1].save(args.out)
    else:
        K.save_gif(args.out, pictures, [int(o.get('delay', 200))] * (len(pictures) - 1) + [3000])
    print(args.out, len(pictures), os.path.getsize(args.out))


BLAST_ROWS = [5, 7, 9, 9, 9, 9, 9, 7, 5]


@figure('fig-blast-map')
def fig_blast_map(args):
    """The map around a nuclear blast before and after: the round 9 x 9 area (BlastArea, rows 1-15 only), the
    cells that changed, the robots and the capture point. opts: before=I after=I x=97 y=3 point=8 cols=88-106
    rows=0-9"""
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    bx, by = int(o['x']), int(o['y'])
    c0, c1 = (int(v) for v in o.get('cols', '88-106').split('-'))
    r0, r1 = (int(v) for v in o.get('rows', '0-9').split('-'))
    pt = int(o.get('point', 8))
    va, vb = pics.at(int(o['before'])), pics.at(int(o['after']))
    cs = 34
    font, small, tiny = K.font(13), K.font(11), K.font(9)
    W, H = (c1 - c0 + 1) * cs, (r1 - r0 + 1) * cs
    area = set()
    for i, n in enumerate(BLAST_ROWS):
        yy = by - 4 + i
        if 1 <= yy <= 15:
            for xx in range(bx - n // 2, bx + n // 2 + 1):
                area.add((xx, yy))
    panels = []
    for v, title in ((va, 'before'), (vb, 'after')):
        im = Image.new('RGB', (W + 40, H + 66), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        ox, oy = 30, 40
        p = v.point(pt)
        d.text((ox, 6), f"{title}: frame {pics.frames[pics.mems.index(v.mem)]}; capture point {pt} at ({p['x']},{p['y']}): "
                        f"owner ${p['owner']:02X}, count {p['count']}", fill=K.TEXT, font=font)
        for y in range(r0, r1 + 1):
            d.text((6, oy + (y - r0) * cs + cs // 2 - 6), str(y), fill=K.DIM, font=small)
            for x in range(c0, c1 + 1):
                c = v.cell(x, y)
                X, Y = ox + (x - c0) * cs, oy + (y - r0) * cs
                rgb = cell_rgb(c)
                d.rectangle([X, Y, X + cs - 1, Y + cs - 1], fill=rgb, outline=(60, 60, 70))
                d.text((X + 3, Y + 2), f'{c:02X}', fill=(20, 20, 20) if sum(rgb) > 450 else (230, 230, 230), font=tiny)
                if c & 0x40:
                    d.ellipse([X + cs // 2 - 5, Y + cs // 2 - 2, X + cs // 2 + 5, Y + cs // 2 + 8],
                              fill=(255, 255, 255), outline=(0, 0, 0))
                if v is vb and va.cell(x, y) != c:
                    d.rectangle([X + 1, Y + 1, X + cs - 2, Y + cs - 2], outline=(255, 60, 60), width=3)
        for x in range(c0, c1 + 1, 2):
            d.text((ox + (x - c0) * cs + 6, oy - 14), str(x), fill=K.DIM, font=tiny)
        # the round area's outline
        for (x, y) in area:
            if not (c0 <= x <= c1 and r0 <= y <= r1):
                continue
            X, Y = ox + (x - c0) * cs, oy + (y - r0) * cs
            for (nx, ny), seg in (((x - 1, y), (X, Y, X, Y + cs)), ((x + 1, y), (X + cs, Y, X + cs, Y + cs)),
                                  ((x, y - 1), (X, Y, X + cs, Y)), ((x, y + 1), (X, Y + cs, X + cs, Y + cs))):
                if (nx, ny) not in area:
                    d.line(seg, fill=(255, 230, 120), width=3)
        for r in v.robots():
            if c0 <= r['x'] <= c1 and r0 <= r['y'] <= r1:
                X, Y = ox + (r['x'] - c0) * cs, oy + (r['y'] - 1 - r0) * cs
                colour = OURS_RGB if r['slot'] < 24 else THEIRS_RGB
                d.rectangle([X + 2, Y + 2, X + 2 * cs - 3, Y + 2 * cs - 3], outline=colour, width=3)
                outlined(d, (X + 4, Y + 3), f"r{r['slot']}", colour, small)
        X, Y = ox + (p['x'] - c0) * cs, oy + (p['y'] - r0) * cs
        d.rectangle([X - 2, Y - 2, X + cs + 1, Y + cs + 1], outline=(230, 60, 200), width=2)
        d.text((ox, oy + H + 6), 'yellow: the blast area (map rows 1-15 only); magenta: the door; red: changed; '
               'white dot: bit 6', fill=K.DIM, font=small)
        panels.append(im)
    out = Image.new('RGB', (panels[0].width, sum(p.height for p in panels) + 8), K.BACKGROUND)
    out.paste(panels[0], (0, 0))
    out.paste(panels[1], (0, panels[0].height + 8))
    out.save(args.out)
    print(args.out, out.size)


COUNT_NAMES = ['warbases', 'electronics', 'nuclear', 'phasers', 'missiles', 'cannon', 'chassis', 'robots']


def state_lines(v, spec):
    """Text lines about a picture: spec items point:N, counts, robot:N, cell:X,Y, res"""
    out = []
    for item in spec.split(','):
        if item.startswith('point'):
            n = int(item.split(':')[1])
            p = v.point(n)
            kind = 'warbase' if n < 4 else 'factory'
            out.append(f"capture point {n} ({kind}) at ({p['x']},{p['y']}): owner ${p['owner']:02X}, "
                       f"count {p['count']}")
        elif item == 'counts':
            ours, theirs = v[0xFD3A:0xFD42], v[0xFD42:0xFD4A]
            out.append('ours $FD3A:  ' + ' '.join(f'{n[:4]} {c}' for n, c in zip(COUNT_NAMES, ours)))
            out.append('enemy $FD42: ' + ' '.join(f'{n[:4]} {c}' for n, c in zip(COUNT_NAMES, theirs)))
        elif item.startswith('robot'):
            r = v.robot(int(item.split(':')[1]))
            out.append(f"robot {item.split(':')[1]}: " + (f"({r['x']},{r['y']}) strength {strength(r['strength'])} "
                       f"order {r['order']}" if r else 'free'))
        elif item.startswith('cell'):
            x, y = (int(c) for c in item.split(':')[1].split('/'))
            out.append(f'map cell ({x},{y}) = ${v.cell(x, y):02X}')
    return out


MARK_RGB = (255, 40, 200)


@figure('fig-pair')
def fig_pair(args):
    """Whole screens side by side with a title and state lines under each.
    opts: pics=I,J[,K] (C:I takes picture I of the C-th --cache) titles=A|B state=point:8,counts scale=2
    crop=view marks=ROW/COL/W/LABEL;... (boxes around screen character cells, in every pane)
    A state line that differs from the first pane's is drawn bright."""
    o = opts(args)
    caches = [Pictures.load(c) for c in args.cache]
    idx = [tuple(int(k) for k in i.split(':')) if ':' in i else (0, int(i)) for i in o['pics'].split(',')]
    titles = o.get('titles', '').split('|')
    S = int(o.get('scale', 2))
    font, small = K.font(13), K.font(11)
    marks = [m.split('/') for m in o['marks'].split(';')] if o.get('marks') else []
    rings = [m.split('/') for m in o['rings'].split(';')] if o.get('rings') else []
    panes, first = [], None
    for n, (c, i) in enumerate(idx):
        pics = caches[c]
        v = pics.at(i)
        im = screen_image(v, S).convert('RGB')
        md = ImageDraw.Draw(im)
        for row, col, w, label in marks:
            x0, y0 = 8 * S * int(col), 8 * S * int(row)
            md.rectangle([x0 - 2, y0 - 2, x0 + 8 * S * int(w) + 1, y0 + 8 * S + 1], outline=MARK_RGB, width=3)
        for cx, cy, h, label in rings:
            px, py = cell_pixel(int(cx), int(cy), v.view_x(), int(h))
            md.ellipse([S * px - 26, S * py - 26, S * px + 26, S * py + 26], outline=MARK_RGB, width=3)
        if o.get('crop') == 'view':
            im = view_crop(im, S)
        lines = state_lines(v, o.get('state', '')) if o.get('state') else []
        lines += [m[3] for m in marks + rings if m[3]]
        if first is None:
            first = lines
        pane = Image.new('RGB', (im.width, im.height + 30 + 15 * len(lines)), K.BACKGROUND)
        d = ImageDraw.Draw(pane)
        day, hour, minute = v.clock()
        d.text((4, 6), f"{titles[n] if n < len(titles) else ''}  (frame {pics.frames[i]}, day {day} "
                       f"{hour:02d}:{minute:02d})", fill=K.TEXT, font=font)
        pane.paste(im, (0, 26))
        y = im.height + 28
        for k, line in enumerate(lines):
            changed = n > 0 and (k >= len(first) or first[k] != line)
            mark = any(line == m[3] for m in marks + rings)
            d.text((4, y), line, fill=MARK_RGB if mark else (255, 230, 120) if changed else K.DIM, font=small)
            y += 15
        panes.append(pane)
    out = Image.new('RGB', (sum(p.width for p in panes) + 12 * (len(panes) - 1), max(p.height for p in panes)),
                    K.BACKGROUND)
    x = 0
    for p in panes:
        out.paste(p, (x, 0))
        x += p.width + 12
    out.save(args.out)
    print(args.out, out.size)


def owner_side(owner):
    return 'destroyed' if owner & 0x80 else 'ours' if owner & 0x40 else 'enemy' if owner & 0x20 else 'neutral'


@figure('fig-capture-counts')
def fig_capture_counts(args):
    """The capture counts (+4 of the 28 points at $FD70) over a game, and one capture turn by turn.
    caches: the game's samples (deep10.npz), the experiment's turn pictures (capture.npz); opts: point=4"""
    plt = plt_setup()
    o = opts(args)
    game, exp = Pictures.load(args.cache[0]), Pictures.load(args.cache[1])
    pt = int(o.get('point', 4))
    fig, (ax, ax2) = plt.subplots(2, 1, figsize=(12, 8), dpi=100, gridspec_kw={'height_ratios': [1.25, 1]})
    play = [i for i in range(len(game)) if game.at(i).word(HANDLER) == PLAY_INTERRUPT]
    days = [(lambda c: c[0] + (c[1] * 60 + c[2]) / 1440)(game.at(i).clock()) for i in play]
    caps = []
    for n in range(28):
        counts = [game.at(i).point(n)['count'] for i in play]
        owners = [game.at(i).point(n)['owner'] for i in play]
        if not any(counts):
            continue
        for j in range(1, len(play)):
            if owners[j] != owners[j - 1]:
                caps.append((days[j], n, owners[j - 1], owners[j]))
        j = 0
        while j < len(play):          # each run of counts > 0: a robot on the door
            if not counts[j]:
                j += 1
                continue
            k = j
            while k + 1 < len(play) and counts[k + 1]:
                k += 1
            end = min(k + 1, len(play) - 1)
            took = owners[end] != owners[j]
            colour = (OURS if owners[end] & 0x40 else THEIRS) if took else GREY
            ax.plot(days[max(j - 1, 0):end + 1], counts[max(j - 1, 0):end + 1], color=colour, lw=0.9)
            j = k + 1
    last_label = (-9, 0)
    for d, n, a, b in sorted(caps):
        colour = OURS if b & 0x40 else THEIRS
        ax.plot(d, 144, marker='v', color=colour, ms=7)
        ly = 158 if d - last_label[0] < 0.2 and last_label[1] == 149 else 149
        ax.text(d, ly, str(n), fontsize=8.5, ha='center', color=colour, fontweight='bold')
        last_label = (d, ly)
    ax.axhline(144, color='black', lw=0.8, ls='--')
    ax.text(0.05, 136, '144 ($90): the point changes hands', fontsize=8, va='top')
    ax.plot([], [], color=OURS, label='a point our robots took')
    ax.plot([], [], color=THEIRS, label='a point the enemy took')
    ax.plot([], [], color=GREY, label='a count that ran out (the robot left the door)')
    ax.plot([], [], marker='v', color='black', ls='', label='capture (point number above)')
    ax.set_xlim(0, days[-1])
    ax.set_ylim(0, 170)
    ax.set_xlabel(f'game day (work/gsB/rT, sampled every {game.frames[1] - game.frames[0]} frames)')
    ax.set_ylabel('count +4')
    ours = sum(1 for c in caps if c[3] & 0x40)
    ax.set_title(f'A point changes hands after 144 turns of a robot on its door: {len(caps)} captures in work/gsB/rT '
                 f'({ours} ours, {len(caps) - ours} the enemy\'s)\neach line is the count +4 of a point ($FD70), '
                 f'1 more each turn a robot stands on the door, 0 when it leaves', fontsize=10.5)
    ax.legend(fontsize=8, loc='center left', bbox_to_anchor=(0.0, 0.55), ncol=2)
    ax.grid(alpha=0.3)
    # the experiment, turn by turn
    turns = list(range(len(exp)))
    counts = [exp.at(i).point(pt)['count'] for i in turns]
    on = [1 if exp.at(i).cell(exp.at(i).point(pt)['x'], exp.at(i).point(pt)['y']) & 0x40 else 0 for i in turns]
    ax2.step(turns, counts, where='post', color=OURS, lw=2, label=f'point {pt} count +4')
    ax2.fill_between(turns, 0, [150 * x for x in on], step='post', color=OURS, alpha=0.08,
                     label='bit 6 on the door (a robot anchored there)')
    first = next(i for i in turns if counts[i])
    cap = next(i for i in turns if exp.at(i).point(pt)['owner'] != exp.at(0).point(pt)['owner'])
    a0, a1 = exp.at(0).point(pt)['owner'], exp.at(cap).point(pt)['owner']
    ax2.annotate('a robot steps onto the door', (first, 1), xytext=(max(first - 95, 2), 30), fontsize=9,
                 arrowprops={'arrowstyle': '->'})
    ax2.annotate(f'turn 144: GiveFactory, owner ${a0:02X} -> ${a1:02X}, count 0;\nCountBases, the panel reprinted, '
                 'a flag on the roof', (cap, 2), xytext=(max(cap - 60, 2), 60), fontsize=9,
                 arrowprops={'arrowstyle': '->'})
    ax2.axhline(144, color='black', lw=0.8, ls='--')
    ax2.set_xlim(0, len(exp) - 1)
    ax2.set_ylim(0, 160)
    ax2.set_title(f'One capture turn by turn: point {pt} counts 1 a turn from the turn the robot stands on the door',
                  fontsize=10.5)
    ax2.set_xlabel(f'picture of {exp.meta.get("source")}, every {exp.frames[1] - exp.frames[0]} frames (about a turn), '
                   f'frames {exp.frames[0]}-{exp.frames[-1]}')
    ax2.set_ylabel('count +4')
    ax2.legend(fontsize=8, loc='upper left')
    ax2.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out, caps)


DIR_NAMES = {0: 'stand', 1: 'right', 2: 'left', 4: 'down', 8: 'up', 0xFF: '-'}
ORDER_NAMES = ['stop', 'advance', 'retreat', 'destroy robots', 'destroy factories', 'destroy warbases',
               'capture neutral', 'capture enemy factories', 'capture enemy warbases']


def order_target(v, r):
    """The capture point a robot with a building order aims at: +$0E indexes the warbase or factory table"""
    if r['order'] in (4, 6, 7) and r['target'] < 24:
        return 4 + r['target']
    if r['order'] in (5, 8) and r['target'] < 4:
        return r['target']
    return None


@figure('fig-ai')
def fig_ai(args):
    """A robot's turns: the view with its target door and course, its record's decision fields beside it.
    opts: slot=0 from=I to=I every=1 scale=3"""
    o = opts(args)
    pics = Pictures.load(args.cache[0])
    slot = int(o.get('slot', 0))
    a, b = int(o['from']), int(o['to'])
    every = int(o.get('every', 1))
    S = int(o.get('scale', 3))
    font, small, big = K.font(13), K.font(12), K.font(15)
    pictures, log = [], []
    prev = pics.at(a - 1).robot(slot) if a else None
    for i in range(a, b + 1):
        v = pics.at(i)
        r = v.robot(slot)
        what = []
        if prev and r:
            if (r['x'], r['y']) != (prev['x'], prev['y']):
                what.append(f"step {DIR_NAMES[r['course']]} to ({r['x']},{r['y']}): RobotMove")
            elif r['facing'] != prev['facing']:
                what.append(f"turn to {DIR_NAMES[r['facing']]} (costs a step)")
            if r['steps'] > prev['steps'] and (r['x'], r['y']) == (prev['x'], prev['y']) or \
                    r['course'] != prev['course']:
                what.append(f"new course {DIR_NAMES[r['course']]} x {r['steps']} (SteerByOrder)")
        for w in what:
            log.append((pics.frames[i], w))
        changed = {k for k in ('course', 'steps', 'facing', 'order', 'target', 'delay', 'ground', 'x', 'y')
                   if prev and r and r[k] != prev[k]}
        prev = r
        if (i - a) % every and i != b:
            continue
        vx = v.view_x()
        im = view_crop(screen_image(v, S), S).convert('RGB')
        d = ImageDraw.Draw(im)
        tp = order_target(v, r) if r else None
        if r:
            px, py = robot_point(r, vx)
            X, Y = S * (px - 8), S * (py - 8)
            if tp is not None:
                p = v.point(tp)
                dx, dy = cell_pixel(p['x'], p['y'], vx)
                DX, DY = S * (dx - 8), S * (dy - 8 - 8)
                d.line([X, Y, DX, DY], fill=(0, 0, 0), width=5)
                d.line([X, Y, DX, DY], fill=(230, 60, 200), width=2)
                d.ellipse([DX - 12, DY - 7, DX + 12, DY + 7], outline=(230, 60, 200), width=3)
                outlined(d, (DX - 30, DY + 22), f'door of point {tp}', (230, 60, 200), small, (255, 255, 255))
            dxy = {1: (1, 0), 2: (-1, 0), 4: (0, 1), 8: (0, -1)}.get(r['course'])
            if dxy:
                ex, ey = cell_pixel(r['x'] + 2 * dxy[0], r['y'] + 2 * dxy[1], vx, r['ground'])
                EX, EY = S * (ex - 8), S * (ey - 8 - 8)
                d.line([X, Y, EX, EY], fill=(0, 0, 0), width=7)
                d.line([X, Y, EX, EY], fill=OURS_RGB, width=4)
            outlined(d, (X + 10, Y - 34 * S // 2 - 30), f'robot {slot}', OURS_RGB, big, (255, 255, 255))
        W = 400
        canvas = Image.new('RGB', (im.width + W, im.height + 26), K.BACKGROUND)
        canvas.paste(im, (0, 26))
        d = ImageDraw.Draw(canvas)
        day, hour, minute = v.clock()
        d.text((6, 5), f'frame {pics.frames[i]}  day {day} {hour:02d}:{minute:02d}', fill=K.TEXT, font=font)
        x0, y = im.width + 12, 34
        d.text((x0, y), f'robot {slot} record ${ROBOTS + 16 * slot:04X}', fill=OURS_RGB, font=font)
        y += 22
        if r:
            rows = [('X, Y', 'x', f"({r['x']},{r['y']})"), ('+$05 course', 'course', DIR_NAMES.get(r['course'], '?')),
                    ('+$06 steps left', 'steps', str(r['steps'])), ('+$08 facing', 'facing',
                                                                    DIR_NAMES.get(r['facing'], '?')),
                    ('+$0B order', 'order', f"{r['order']} {ORDER_NAMES[r['order']]}"),
                    ('+$0E target', 'target', f"{r['target']}" + (f' (point {tp})' if tp is not None else '')),
                    ('+$0F delay', 'delay', f"{r['delay']} turn(s) to the next step"),
                    ('+$0D ground', 'ground', str(r['ground']))]
            for name, key, val in rows:
                hot = key in changed or (key == 'x' and 'y' in changed)
                d.text((x0, y), name, fill=K.DIM, font=small)
                d.text((x0 + 130, y), val, fill=(255, 230, 120) if hot else K.TEXT, font=small)
                y += 18
            if tp is not None:
                p = v.point(tp)
                y += 4
                d.text((x0, y), f"door ({p['x']},{p['y']}): dx {p['x'] - r['x']}, dy {p['y'] - r['y']}; "
                                f"count {p['count']}", fill=(230, 60, 200), font=small)
                y += 18
        y += 10
        d.text((x0, y), 'what the turns did', fill=K.TEXT, font=font)
        y += 20
        for f, text in log[-8:]:
            d.text((x0, y), f'{f} {text}'[:52], fill=K.TEXT if f == pics.frames[i] else K.DIM, font=small)
            y += 16
        pictures.append(canvas)
    K.save_gif(args.out, pictures, [int(o.get('delay', 150))] * (len(pictures) - 1) + [2500])
    print(args.out, len(pictures), os.path.getsize(args.out))


RES_NAMES = ['general', 'electronics', 'nuclear', 'phasers', 'missiles', 'cannon', 'chassis']
RES_COLOURS = ['#4a4a4a', '#2fa36b', '#c03030', '#8a5ad0', '#d0a020', '#3070c0', '#a07040']


def day_boundaries(pics):
    """[(i, day)]: the first sample of each new game day after the first (the start of play is skipped)"""
    out = []
    play = [i for i in range(len(pics)) if pics.at(i).word(HANDLER) == PLAY_INTERRUPT]
    for a, b in zip(play, play[1:]):
        if pics.at(b).clock()[0] != pics.at(a).clock()[0] and pics.at(a).clock()[0] + 1 == pics.at(b).clock()[0]:
            out.append((a, b, pics.at(b).clock()[0]))
    return out


@figure('fig-production')
def fig_production(args):
    """DailyProduction per side and day: what the buildings earned, checked against the resources across midnight"""
    plt = plt_setup()
    pics = Pictures.load(args.cache[0])
    fig, axes = plt.subplots(2, 1, figsize=(12, 7.5), dpi=100, sharex=True)
    match = total = 0
    top, days = 0, []
    for ax, (side, R, C, colour) in zip(axes, (('ours', 0xFD22, 0xFD3A, OURS), ('the enemy', 0xFD4A, 0xFD42, THEIRS))):
        bottoms = {}
        for a, b, day in day_boundaries(pics):
            va, vb = pics.at(a), pics.at(b)
            r0, r1, c = list(va[R:R + 7]), list(vb[R:R + 7]), list(va[C:C + 7])
            gain = [5 * c[0]] + [2 * c[k] for k in range(1, 7)]
            exp = [min(99, r + g) for r, g in zip(r0, gain)]
            total += 1
            match += exp == r1
            bottom = 0
            for k in range(7):
                if gain[k]:
                    ax.bar(day, gain[k], bottom=bottom, color=RES_COLOURS[k], width=0.7, edgecolor='white',
                           label=RES_NAMES[k] if k not in bottoms else None)
                    bottoms[k] = 1
                    bottom += gain[k]
            ax.text(day, bottom + 0.4, f"{c[0]} wb\n{sum(c[1:])} f", ha='center', va='bottom', fontsize=8,
                    color='#333333')
            top, days = max(top, bottom), days + [day]
        ax.set_ylabel(f'{side}: resource earned')
        ax.grid(axis='y', alpha=0.3)
        ax.set_title(f'{side} (resources ${R:04X}, buildings ${C:04X})', color=colour, loc='left', fontsize=11)
    handles = {}
    for ax in axes:
        for h, l in zip(*ax.get_legend_handles_labels()):
            handles.setdefault(l, h)
    order = [n for n in RES_NAMES if n in handles]
    axes[0].legend([handles[n] for n in order], order, loc='upper left', ncol=4, fontsize=9, frameon=False)
    axes[1].set_xlabel('the midnight that starts game day N')
    axes[1].set_xticks(range(1, max(days) + 1))
    for ax in axes:
        ax.set_ylim(0, (top // 10 + 2) * 10)
    fig.suptitle('Three warbases against one: the enemy earns 15 general a day to our 5, and its factories add more\n'
                 'DailyProduction $AE38: general += 5 x warbases, each part += 2 x its factories (cap 99)\n'
                 f'labels: warbases (wb) and factories (f) at midnight; the formula matched the resources across '
                 f'midnight {match} of {total} times, work/gsB/rT', fontsize=11)
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out, match, total)


def enemy_lives(pics):
    """Enemy robot lives in a sampled game: {slot: [(i0, i1, parts, [(i, order)])]}"""
    lives = {}
    open_ = {}
    for i in range(len(pics)):
        v = pics.at(i)
        if v.word(HANDLER) != PLAY_INTERRUPT:
            continue
        for s in range(24, 48):
            r = v.robot(s)
            cur = open_.get(s)
            if cur and (not r or r['parts'] != cur['parts'] or r['strength'] == 100 and cur['dying']):
                lives.setdefault(s, []).append(cur)
                open_.pop(s)
                cur = None
            if not r:
                continue
            if not cur:
                cur = open_[s] = {'i0': i, 'i1': i, 'parts': r['parts'], 'orders': [], 'dying': False}
            cur['i1'] = i
            cur['dying'] = cur['dying'] or r['strength'] >= 0x80
            if not cur['orders'] or cur['orders'][-1][1] != r['order']:
                cur['orders'].append((i, r['order']))
    for s, cur in open_.items():
        lives.setdefault(s, []).append(cur)
    return lives


ORDER_COLOURS = {0: '#bbbbbb', 1: '#77aa77', 2: '#77aa77', 3: '#d03030', 4: '#e08020', 5: '#7a1f1f',
                 6: '#2a9d8f', 7: '#3070c0', 8: '#7a4fc0'}


@figure('fig-commander')
def fig_commander(args):
    """The enemy commander over a game: each enemy slot's robot lives, coloured by order, with the births' weapons"""
    plt = plt_setup()
    from matplotlib.patches import Patch
    pics = Pictures.load(args.cache[0])
    day = lambda i: (lambda c: c[0] + (c[1] * 60 + c[2]) / 1440)(pics.at(i).clock())
    lives = enemy_lives(pics)
    fig, (ax0, ax) = plt.subplots(2, 1, figsize=(13, 9.6), dpi=100, sharex=True, gridspec_kw={'height_ratios': [1, 3]})
    play = [i for i in range(len(pics)) if pics.at(i).word(HANDLER) == PLAY_INTERRUPT]
    xs = [day(i) for i in play]
    ax0.plot(xs, [pics.at(i)[0xFD42 + 7] for i in play], color=THEIRS, label='enemy robots ($FD49)')
    ax0.plot(xs, [pics.at(i)[0xFD4A] for i in play], color='#4a4a4a', label='enemy general ($FD4A)')
    ax0.plot(xs, [pics.at(i)[0xFD3A + 7] for i in play], color=OURS, label='our robots ($FD41)', alpha=0.7)
    for k in (8, 16):
        ax0.axhline(k, color=THEIRS, lw=0.6, ls=':')
        ax0.text(xs[0], k + 0.3, f'{k}: births need {k // 8 + 1} weapons', fontsize=8, color=THEIRS)
    ax0.legend(loc='upper right', fontsize=9, ncol=3, frameon=False)
    ax0.grid(alpha=0.3)
    births = 0
    for s, ls in lives.items():
        for life in ls:
            births += 1
            orders = life['orders'] + [(life['i1'], None)]
            for (i, o), (j, _) in zip(orders, orders[1:]):
                ax.plot([day(i), day(min(max(j, i + 1), len(pics) - 1))], [s, s], color=ORDER_COLOURS[o],
                        lw=6, solid_capstyle='butt')
            weapons = bin(life['parts'] & 0x78).count('1')
            ax.plot(day(life['i0']), s, marker='>', color='black', ms=5)
            nuc = 'N' if life['parts'] & 0x40 else ''
            ax.text(day(life['i0']) - 0.04, s + 0.33, f"{weapons}{nuc}", fontsize=7, ha='right', color='#222222')
            if life['dying']:
                ax.plot(day(life['i1']), s, marker='x', color='black', ms=6)
    ax.set_ylim(23.3, 47.7)
    ax.set_yticks(range(24, 48, 2))
    ax.set_ylabel('enemy slot ($DB80 + 16 x (slot - 24))')
    ax.set_xlabel('game day')
    ax.invert_yaxis()
    ax.grid(axis='x', alpha=0.3)
    used = sorted({o for ls in lives.values() for life in ls for _, o in life['orders']})
    names = {0: '0 none yet', 3: '3 destroy robots', 4: '4 destroy factories', 5: '5 destroy warbases',
             6: '6 capture neutral', 7: '7 capture our factories', 8: '8 capture our warbases'}
    handles = [Patch(color=ORDER_COLOURS[o], label=names.get(o, str(o))) for o in used]
    handles += [plt.Line2D([], [], marker='>', color='black', ls='', label='birth (weapons, N = nuclear)'),
                plt.Line2D([], [], marker='x', color='black', ls='', label='destroyed')]
    ax.legend(handles=handles, loc='upper center', bbox_to_anchor=(0.5, -0.08), fontsize=9, ncol=5, frameon=False)
    step = pics.frames[1] - pics.frames[0]
    fig.suptitle(f'The enemy commander builds {births} robots and sends them first to capture, then to hunt robots\n'
                 f'EnemyCommander $B7F4 in work/gsB/rT: the robots in slots 24-47, their orders '
                 f'(+$0B) over time\nsampled every {step} frames', fontsize=11)
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out, births)

#FIGURES-END

if __name__ == '__main__':
    main()
