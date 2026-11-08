#!/usr/bin/env python3
"""Play Elite on a live unreal-ng instance from a plan, with a pilot for the parts a fixed script cannot fly.

    python3 tools/elitebot.py --work work/live PLAN.py [--record work/REC] [--start SNAPSHOT]

The instance is the one `re_session.py open` launched into --work (its session.json). PLAN.py defines
`plan(bot)`, a function that drives the game through the Bot below: keys pressed for frames, the pilot steering at
a ship or the station, tapes inserted, snapshots saved. Nothing is poked into memory: every state the plan reaches
is reached through the game's own keys and its own tape loader.

With --record the run is recorded the way `re_session.py capture` records one (start.szx and start.bin, the screens
and RAM pages every 250 frames, the TTD session, L1, the findings) and every change of the held keys goes into
REC/inputs.txt (the tests/inputs format), with REC/log.tsv the pilot's view each step.

The ship record (docs/07-objects.md 7.2): x, y, z at +0, +3, +6, three bytes each, the top byte's bit 7 the sign;
+$22 the energy (0 a free slot), +$23 the blueprint header, +$26 the role. The pilot reads them every step.
"""
import argparse
import json
import os
import runpy
import sys
import time

import elitelib as E

K = E.K
SLOTS, SLOT_LEN = 0x6048, 39
BLUEPRINTS = {0x6A9D: 'Coriolis', 0x67A6: 'Missile', 0x6632: 'EscapePod', 0x68A7: 'Plate', 0x63E5: 'Canister',
              0x6BBC: 'Splinter', 0x630C: 'Asteroid', 0x62F5: 'RockHermit', 0x6E1B: 'Viper', 0x6490: 'CobraTrader',
              0x68E6: 'PythonTrader', 0x68FD: 'PythonPirate', 0x64A7: 'CobraPirate', 0x61CC: 'Asp',
              0x6689: 'FerDeLance', 0x6C13: 'Thargoid', 0x69F2: 'Sidewinder', 0x6D32: 'Krait', 0x6EF8: 'Thargon'}


def coord(b):
    v = b[0] | b[1] << 8 | (b[2] & 0x7F) << 16
    return -v if b[2] & 0x80 else v


class Bot:
    def __init__(self, work, record=None):
        self.s = E.session(work)
        sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
        import corpus
        import mm_session
        self.corpus, self.mm = corpus, mm_session
        port = json.load(open(os.path.join(work, 'session.json')))['port_base']
        self.m = corpus.Machine(self.s, port)
        self.work, self.record = work, record
        self.frame, self.held, self.last_change = 0, set(), 0
        self.script, self.log, self.events = ['0 -'], [], []
        self.mute()

    # --- the machine
    def mute(self):
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                   'body': {'muted': True}}, ok=False)

    def load_snapshot(self, path):
        self.m.post('/snapshot/load', {'path': os.path.abspath(path)})
        self.mute()

    def save_snapshot(self, path):
        self.m.post('/snapshot/save', {'path': os.path.abspath(path), 'force': True})

    def feature(self, name, on):
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/feature/' + name,
                                   'body': {'enabled': bool(on)}}, ok=False)

    def tape(self, path):
        """Insert a tape image and start it playing (the game's loader reads it when it wants)"""
        self.m.post('/tape/load', {'path': os.path.abspath(path)})
        self.m.post('/tape/play', {})

    def shot(self, path):
        """The screen now as a PNG (scr2png.py), for looking while a plan is written"""
        import subprocess
        scr = path[:-4] + '.scr'
        open(scr, 'wb').write(self.m.read(0x4000, 6912))
        subprocess.run([sys.executable, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis',
                                                     'scr2png.py'), path, scr], check=True)
        os.remove(scr)

    def mem(self, addr, n=1):
        return self.m.read(addr, n)

    def byte(self, addr):
        return self.m.read(addr, 1)[0]

    def start(self):
        """Begin the recording here (after the plan's set-up)"""
        if not self.record:
            return
        os.makedirs(self.record, exist_ok=True)
        info = json.load(open(os.path.join(self.work, 'session.json')))
        info.pop('pid', None)
        info['instance_of'] = os.path.abspath(self.work)
        json.dump(info, open(os.path.join(self.record, 'session.json'), 'w'))
        self.save_snapshot(os.path.join(self.record, 'start.szx'))
        open(os.path.join(self.record, 'start.bin'), 'wb').write(self.m.read(0, 0x10000))
        self.s.call('analysis', {'action': 'start', 'record': True})
        self.frame, self.last_change, self.script = 0, 0, ['0 -']
        self.screens = os.path.join(self.record, 'screens')
        os.makedirs(self.screens, exist_ok=True)

    # --- time and keys
    def run(self, n):
        if n <= 0:
            return
        screens = getattr(self, 'screens', None)
        self.frame = self.corpus.run_frames(self.m, n, screens, self.frame)

    def hold(self, keys):
        """Hold exactly these keys from now (names as in tests/inputs: A-Z, 0-9, SPACE, ENTER, CS, SS, KF/KL/KR/KU/KD)"""
        want = set(keys.split()) if isinstance(keys, str) else set(keys)
        if want == self.held:
            return
        for k in self.held - want:
            self._key(k, False)
        for k in want - self.held:
            self._key(k, True)
        self.script.append(f'+{self.frame - self.last_change} ' + (' '.join(sorted(want)) or '-'))
        self.last_change = self.frame
        self.held = want

    def _key(self, key, down):
        action = 'press' if down else 'release'
        if key in self.mm.KEMPSTON:
            self.s.call('joystick_input', {'action': action, 'buttons': self.mm.KEMPSTON[key]}, ok=False)
        else:
            self.s.call('type_input', {'action': action, 'key': {'SS': 'symshift', 'CS': 'capsshift'}.get(key, self.mm.KEY_NAMES.get(key, key.lower()))})

    def tap(self, keys, hold=4, after=20):
        self.hold(keys)
        self.run(hold)
        self.hold('')
        self.run(after)

    def type(self, text, hold=4, after=8):
        for ch in text:
            self.tap('SPACE' if ch == ' ' else ch.upper(), hold, after)

    def load_commander(self, tape):
        """From the title: the commander tape loaded by the game (Y, 1 for the tape, ENTER for the first name on
        it), then the status page and back to the docked menu"""
        self.feature('fasttape', False)
        self.tape(tape)
        self.run(30)
        self.note('load ' + os.path.basename(tape))
        self.tap('Y', 20, 60)
        self.tap('1', 6, 60)
        self.tap('ENTER', 6, 300)
        self.until(lambda: self.byte(0xD054) != ord('J'), 600)
        self.note('loaded')
        self.tap('3', 6, 100)
        self.tap('SPACE', 20, 200)

    def press(self, key, frames=24):
        """A flight key held long enough for one pass of the flight loop to see it (a pass is up to 20 frames
        with ships about; T, F, U, W, Q are cleared after each pass)"""
        self.tap(key, frames, 4)

    def note(self, text):
        self.events.append((self.frame, text))
        print(f'{self.frame:6d} {text}', flush=True)

    def until(self, test, limit, step=5):
        """Run until test() is true or limit frames passed; returns whether it came true"""
        end = self.frame + limit
        while self.frame < end:
            if test():
                return True
            self.run(step)
        return test()

    # --- the game's state
    def slots(self):
        raw = self.mem(SLOTS, SLOT_LEN * 8)
        out = []
        for i in range(8):
            r = raw[SLOT_LEN * i:SLOT_LEN * (i + 1)]
            if not r[0x22]:
                continue
            hdr = r[0x23] | r[0x24] << 8
            out.append({'slot': i, 'x': coord(r[0:3]), 'y': coord(r[3:6]), 'z': coord(r[6:9]),
                        'energy': r[0x22], 'kind': BLUEPRINTS.get(hdr, f'${hdr:04X}'), 'flags': r[0x20],
                        'behaviour': r[0x21], 'role': r[0x26]})
        return out

    def health(self):
        """The dashboard values: the fore and aft shields, the fuel, the cabin and laser temperatures, the four
        energy banks (BarDrawn $70E7: each bar a pair, the value second)"""
        r = self.mem(0x70E8, 22)
        return {'fore': r[0], 'aft': r[2], 'fuel': r[4], 'cabin': r[6], 'laser': r[8],
                'banks': [r[14], r[16], r[18], r[20]]}

    def commander(self):
        r = self.mem(0xD054, 0x66)
        return {'legal': r[0x0B], 'score': r[0x0C] | r[0x0D] << 8 | r[0x0E] << 16, 'jumps': r[0x0F],
                'galaxy': r[0x11], 'cash': (r[0x12] | r[0x13] << 8) * 10000 + (r[0x14] | r[0x15] << 8),
                'fluctuation': r[0x16], 'hold': list(r[0x17:0x28]), 'free': r[0x28], 'lasers': list(r[0x29:0x2D]),
                'nova': r[0x2D], 'fuel': r[0x2E], 'missiles': r[0x2F], 'equipment': list(r[0x30:0x3A]),
                'stock': list(r[0x4A:0x5B]), 'mission': r[0x5B], 'flags': r[0x5C]}

    # --- the pilot
    def aim(self, target, tol=12):
        """The keys that turn the ship towards a target (x right, y up, z ahead): roll it onto the vertical axis,
        then pitch it to the centre; 'fire' when it is in the sights"""
        x, y, z = target['x'], target['y'], target['z']
        keys = set()
        if z <= 0:
            keys.add(self.pitch_up)           # behind: loop over
            return keys, False
        ax, ay = abs(x), abs(y)
        if ax * 8 > max(ay, 1) * 3 and ax > tol * 4:
            # roll so that the target goes to the top half's centre line
            keys.add(self.roll_right if (x > 0) == (y >= 0) else self.roll_left)
        if ay > tol * 2 or (ax <= tol * 4 and ay > tol):
            keys.add(self.pitch_up if y > 0 else self.pitch_down)
        in_sights = ax < max(tol * 8, z // 16) and ay < max(tol * 8, z // 16)
        return keys, in_sights

    roll_left, roll_right, pitch_up, pitch_down = 'N', 'M', 'X', 'S'

    def target(self, kinds=None):
        """The ship the pilot chased last while it lives, else the nearest (not the station, not a missile) of
        these kinds, or of any"""
        ships = [s for s in self.slots() if s['slot'] not in (0, 7) and (kinds is None or s['kind'] in kinds)]
        same = [s for s in ships if s['slot'] == getattr(self, '_chased', None) and s['energy'] != 0xFF]
        if same:
            return same[0]
        best = min(ships, key=lambda s: abs(s['x']) + abs(s['y']) + abs(s['z']), default=None)
        self._chased = best and best['slot']
        return best

    def fight(self, limit, kinds=None, stop=None, fire='A', strict=False):
        """Steer at the nearest ship and fire the laser while it is in the sights, for limit frames or until
        stop() is true; each step goes into the log (frame, slot, kind, x, y, z, energy, keys)"""
        end = self.frame + limit
        while self.frame < end and not (stop and stop()):
            t = self.target(kinds)
            if t is None:
                self.hold('')
                self.run(4)
                continue
            keys, ok = self.aim(t, 6)
            if strict:
                # fire only while the game has a ship in the gunsight (SightTarget, set each pass, so the last
                # sighting within 6 frames counts) and the laser is not near its overheat
                if self.byte(0x9C97):
                    self._sighted = self.frame
                ok = self.frame - getattr(self, '_sighted', -99) <= 6 and self.byte(0x70F0) < 140
            if ok and fire:
                keys.add(fire)
            self.hold(keys)
            self.run(2)
            self.log.append((self.frame, t['slot'], t['kind'], t['x'], t['y'], t['z'], t['energy'],
                             ' '.join(sorted(keys))))
        self.hold('')

    # --- navigation (the in-system jump and the docking computer)
    def position(self, addr):
        """The sun ($7107) or the planet ($7110): three sign-magnitude coordinates"""
        r = self.mem(addr, 9)
        return {'x': coord(r[0:3]), 'y': coord(r[3:6]), 'z': coord(r[6:9])}

    def toward(self, where, extra=('SPACE',), tol=4):
        """One step turning the ship towards a far body (scaled to the aim's range), with extra keys held"""
        sc = max(1, abs(where['z']) // 2000)
        keys, ok = self.aim({'x': where['x'] // sc, 'y': where['y'] // sc, 'z': where['z'] // sc}, tol)
        keys |= set(extra)
        self.hold(keys)
        self.run(4)
        return ok

    def to_safe_zone(self, limit=6000):
        """Aim at the planet and jump (J) whenever the game allows it (fighting any ship about first), until the safe zone (SafeZone is first
        looked at after 128 frames: an arrival keeps the old system's value for a while)"""
        self.run(128)
        start = self.frame
        while not self.byte(0x711C) and self.frame - start < limit:
            if self.byte(0x9C94) and [x for x in self.slots() if x['slot'] not in (0, 7)]:
                self.clear_ships()            # a ship about refuses the jump (ShipsAbout)
                continue
            ok = self.toward(self.position(0x7110), () if self.byte(0x81A5) else ('SPACE',))
            if ok and not self.byte(0x81A4) and not self.byte(0x81A5) and (self.frame - start) % 16 < 4:
                self.press('J', 24)
        self.hold('')
        return self.byte(0x711C)

    def clear_ships(self):
        """The ships about gone: the energy bomb (W) while fitted, else a missile (T, then F once locked), else
        the laser for 200 frames"""
        if self.byte(0xD08A):
            self.note('energy bomb')
            self.press('W', 24)
            self.run(60)
        elif self.byte(0xD083) and not self.mem(0x6048 + 39 * 7 + 0x22, 1)[0]:
            self.press('T', 24)
            if self.until(lambda: self.byte(0xD047) == 2, 100, 2):
                self.note('missile')
                self.press('F', 24)
                self.fight(300, fire=None, stop=lambda: self.mem(0x6048 + 39 * 7 + 0x22, 1)[0] == 0)
            else:
                self.fight(200, strict=True)
        else:
            self.fight(200, strict=True)

    def dock(self, limit=600):
        """The docking computer (C) in the safe zone, until docked (Condition 0)"""
        self.press('C', 24)
        return self.until(lambda: self.byte(0x7104) == 0, limit, 5)

    def scoop(self, kinds=('Plate', 'Canister', 'Splinter', 'EscapePod'), limit=3000):
        """Fly into a live scoopable ship of these kinds so that it passes a little below the centre (Collide
        scoops only below, y negative, within 180 on each axis). The debris drifts (16 to 40 a pass), so the pilot
        steers on where the piece will be 20 frames on (from its last two positions): the pitch keys while that
        point is off a line about 20 degrees under the centre, the roll keys while it is off to the side; stopped
        while it is well off that line (turning on the spot), full speed while it is far or moving away, slow once
        it closes; true once it is gone into the hold or away"""
        start, seen = self.frame, {}
        while self.frame - start < limit:
            p = [x for x in self.slots() if x['kind'] in kinds and x['energy'] != 255]
            if not p:
                self.hold('')
                return True
            p = min(p, key=lambda s: abs(s['x']) + abs(s['y']) + abs(s['z']))
            x, y, z = p['x'], p['y'], p['z']
            last = seen.get(p['slot'])
            seen[p['slot']] = (self.frame, x, y, z)
            vx = vy = vz = 0
            if last and self.frame > last[0]:
                d = self.frame - last[0]
                vx, vy, vz = (x - last[1]) / d, (y - last[2]) / d, (z - last[3]) / d
            px, py, pz = x + 20 * vx, y + 20 * vy, max(z + 20 * vz, 60)
            want = -0.35 * pz if pz < 260 else -90
            tol = max(15, pz * 0.08)
            keys = set()
            speed = self.byte(0x70E6)
            if z <= 0:
                keys.add(self.pitch_up if y > 0 else self.pitch_down)   # behind: turn over towards it
                aim = 0
            else:
                if py > want + tol:
                    keys.add(self.pitch_up)
                elif py < want - tol:
                    keys.add(self.pitch_down)
                if abs(px) > max(60, pz * 0.4):
                    keys.add(self.roll_right if (px > 0) == (py >= 0) else self.roll_left)
                off = abs(py - want) > max(60, pz * 0.5) or abs(px) > max(90, pz * 0.6)
                aim = 0 if off else 30 if (z > 500 or vz > 0) else 10
            if speed < aim:
                keys.add('SPACE')
            elif speed > aim + 2:
                keys.add('SS')
            self.hold(keys)
            self.run(2)
            self.log.append((self.frame, p['slot'], p['kind'], x, y, z, p['energy'], ' '.join(sorted(keys))))
        self.hold('')
        return False

    def finish(self):
        self.hold('')
        self.script.append('+1 END')
        if not self.record:
            return
        rec = os.path.abspath(self.record)
        self.s.call('analysis', {'action': 'build', 'path': os.path.join(rec, 'l1.json'), 'wait': 30000})
        while ': running' in self.s.call('analysis', {'action': 'status'}).text:
            time.sleep(5)
        status = self.s.call('analysis', {'action': 'status'}).text.splitlines()
        dumped = self.s.call('time_travel', {'action': 'dump', 'path': os.path.join(rec, 'session.ttd')}, ok=False)
        json.dump({'model': '48K', 'ranges': '5B00-FFFF', 'frames': self.frame, 'status': status,
                   'ttd': (dumped.text or '').splitlines()[:1], 'events': self.events},
                  open(os.path.join(rec, 'capture.json'), 'w'), indent=1)
        open(os.path.join(rec, 'inputs.txt'), 'w').write('# tools/elitebot.py\n' + '\n'.join(self.script) + '\n')
        with open(os.path.join(rec, 'log.tsv'), 'w') as f:
            for row in self.log:
                f.write('\t'.join(map(str, row)) + '\n')
        print('recorded', self.frame, 'frames;', status[-1] if status else '', flush=True)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('plan')
    p.add_argument('--record')
    p.add_argument('--start', help='a snapshot to start from (default: the title of c1, work/snaps/title-A.szx)')
    args = p.parse_args()
    bot = Bot(args.work, args.record)
    bot.load_snapshot(args.start or os.path.join(E.CASE, 'work', 'snaps', 'title-A.szx'))
    runpy.run_path(args.plan)['plan'](bot)
    bot.finish()


if __name__ == '__main__':
    main()
