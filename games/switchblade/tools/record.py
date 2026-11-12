#!/usr/bin/env python3
"""Switchblade recordings: a fresh muted machine (RAM zeroed, a Kempston card), the TTD recording started at power-on
(or after a start state is loaded), a plan of held keys played over emulated frames, screens at named moments, then
end.szx, l1.json, session.ttd, the input script of every key held (tests/inputs/<name>.txt, frames from the
recording's start) and record.json (the plan's note, the moments, the tape actions, the POKEs).

    python3 tools/record.py PLAN --work work/stage1/rec/NAME [--port-base 37470] [--start work/stage1/explore/loaded.szx]
    python3 tools/record.py list

The tape is loaded at signal speed (fast and turbo tape off): the game's own loader at `$FF00` is no ROM LD-BYTES.
A POKE, where a plan uses one, is applied on the recording's machine only, written in record.json and in the plan's
note; the image of the case is cut from c1 (case.json), never from a recording with a POKE.

The controls: the menu's option 4 (Protek or cursor) reads 5 left, 8 right, 7 up, 6 down, 0 fire; option 3 the
Kempston joystick (KL KR KU KD KF). In play the keys are held for whole moves.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402

TAPE = os.path.join(CASE, 'work', 'stage1', 'media', 'switchblade.tzx')
L, R, U, D, F = '5', '8', '7', '6', '0'
UL, UR = '5+7', '8+7'


class Run:
    def __init__(self, lab, work):
        self.lab, self.work = lab, work
        self.moments, self.tape_log, self.pokes, self.keylog = [], [], [], []
        self.held = []
        os.makedirs(os.path.join(work, 'screens'), exist_ok=True)

    # the keys, logged as an mm_session input script
    def keys(self, keys):
        keys = [k for k in keys if k]
        if sorted(keys) != sorted(self.held):
            self.keylog.append((self.lab.frame, keys))
        self.held = list(keys)
        self.lab.keys(keys)

    def hold(self, spec, frames):
        self.keys(spec.split('+') if spec else [])
        self.lab.run(frames)

    def tap(self, spec, hold=4, after=20):
        self.hold(spec, hold)
        self.hold('', after)

    def wait(self, frames):
        self.hold('', frames)

    def shot(self, name):
        self.lab.shot(os.path.join(self.work, 'screens', f'{self.lab.frame:06d}-{name}.png'))
        self.moments.append({'frame': self.lab.frame, 'name': name})

    def tape(self):
        t = self.lab.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/tape'}, ok=False)
        return (t.structured or {}).get('body') or {}

    def poke(self, addr, data, why):
        self.lab.write(addr, bytes(data))
        self.pokes.append({'frame': self.lab.frame, 'address': f'${addr:04X}', 'bytes': list(data), 'why': why})

    def script(self, path, note):
        with open(path, 'w') as f:
            for line in (note or '').strip().splitlines():
                f.write('# ' + line.strip() + '\n')
            for frame, keys in self.keylog:
                f.write(f'{frame} {"+".join(keys) if keys else "-"}\n')
            f.write(f'{self.lab.frame} END\n')


def boot(r):
    """Power-on to the menu: the 128K menu's Tape Loader (ENTER) or LOAD "" on a 48K, the tape at signal speed"""
    lab = r.lab
    for name in ('fast_tape', 'turbo_tape'):
        lab.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                  'body': {'value': False}}, ok=False)
    lab.s.call('load_software', {'path': TAPE, 'autostart': False, 'play': False}, ok=False)
    r.tape_log.append({'frame': lab.frame, 'action': 'insert', 'path': 'switchblade.tzx'})
    r.wait(200)
    r.shot('rom-menu')
    if lab.model == '48K':
        for k in ('J', 'SS+P', 'SS+P', 'ENTER'):
            r.tap(k, 3, 5)
    else:
        r.tap('ENTER', 3, 5)
    lab.post('/tape/play', {})
    r.tape_log.append({'frame': lab.frame, 'action': 'play'})
    k = 0
    while k < 40:
        r.wait(500)
        k += 1
        if k in (2, 6, 20, 25):
            r.shot(f'loading-{k}')
        if r.tape().get('state') in ('ended', 'idle', 'stopped') and k > 3:
            break
    r.tape_log.append({'frame': lab.frame, 'action': 'ended'})
    r.wait(300)
    r.shot('menu')


def start_game(r, option='4', fire=F):
    """The control option, then fire: the intro story (about 1000 frames), then play"""
    r.tap(option, 4, 60)
    r.shot(f'title-{option}')
    r.tap(fire, 5, 100)
    r.shot('intro-1')
    r.wait(400)
    r.shot('intro-2')
    r.wait(600)
    r.shot('intro-3')
    r.wait(300)
    r.shot('play-start')


def walk(r, spec, frames, name=None):
    r.hold(spec, frames)
    if name:
        r.shot(name)


def plan_c1(r):
    """c1: power-on on a 128K, the original tape by its own loader at signal speed, the menu, 4 (Protek), fire,
    the intro story, then play: right through the first screens, a jump, fire held and let go (a punch, a kick),
    up and down, and back left"""
    boot(r)
    start_game(r, '4')
    walk(r, R, 150, 'right-1')
    walk(r, UR, 30, 'jump-right')
    r.wait(30)
    walk(r, F, 20)
    walk(r, '', 10, 'punch')
    walk(r, F, 60)
    walk(r, '', 20, 'kick')
    walk(r, R, 250, 'right-2')
    walk(r, U, 40, 'up')
    walk(r, D, 40, 'down')
    walk(r, L, 300, 'left')
    r.wait(200)
    r.shot('end')


def plan_menu(r):
    """menu: from the menu after the load (explore/loaded.szx), for each control option 1 (Joystick 1: keys 6 7 0),
    2 (Joystick 2: 1 2 5), 3 (Kempston), 4 (Protek or cursor: 5 8 0): the option, its left and right on the title (the
    music or effects choice), fire at once (the title takes it; later in the title cycle it did not), the intro
    (about 1600 frames), a move right in play, a pause (P) and its end, the quit (fire held, then P), then the title
    cycle (the high-score table) before the next option"""
    r.shot('menu')
    for opt, left, right, fire in (('1', '6', '7', '0'), ('2', '1', '2', '5'), ('3', 'KL', 'KR', 'KF'),
                                   ('4', L, R, F)):
        r.tap(opt, 4, 60)
        r.shot(f'title-{opt}')
        r.tap(left, 6, 40)
        r.shot(f'title-{opt}-left')
        r.tap(right, 6, 40)
        r.shot(f'title-{opt}-right')
        r.tap(fire, 5, 1700)
        r.shot(f'play-{opt}')
        r.tap(right, 60, 10)
        r.shot(f'play-{opt}-moved')
        r.tap('P', 4, 100)
        r.shot(f'pause-{opt}')
        r.tap('P', 4, 60)
        r.shot(f'unpause-{opt}')
        r.hold(fire, 10)
        r.hold(fire + '+P', 6)
        r.hold('', 300)
        r.shot(f'quit-{opt}')
        r.wait(1500)
        r.shot(f'cycle-{opt}')
        r.wait(600)
        r.shot(f'cycle-{opt}-b')


def plan_gameover(r):
    """gameover: from the menu after the load (explore/loaded.szx): 4 (Protek), the intro, then POKEs: lives `$664D`
    = 0 and energy `$6642` = 1 (so the first hit takes the last life); Hiro walks right through the first screens and
    jumps until a hit: the death, the game over and what follows (the high-score table or the title)"""
    start_game(r, '4')
    r.wait(400)                       # the intro ends about 1600 frames after fire: the game start sets lives 5
    r.shot('play')
    r.poke(0x664D, [0], 'lives 0: the next death ends the game')
    r.poke(0x6642, [1], 'energy 1: the next hit is a death')
    for i in range(24):
        walk(r, R, 80)
        walk(r, UR, 30)
        r.wait(30)
        if i % 2:
            r.shot(f'walk-{i:02d}')
    r.wait(1500)
    r.shot('after')
    r.wait(1500)
    r.shot('end')
    for _ in range(4):
        r.tap(F, 5, 400)
        r.shot('after-fire')


def plan_c48(r):
    """c48: c1's plan on a 48K (run with --model 48K): LOAD "" typed, the tape at signal speed; the 8441-byte block
    is not read; the menu, 4 (Protek), the intro, the same walk: the 48K's sound and what bank 4 leaves out"""
    plan_c1(r)


def plan_option(r, opt, left, right, up, fire):
    r.shot('menu')
    r.tap(opt, 4, 60)
    r.shot(f'title-{opt}')
    r.tap(fire, 5, 1700)
    r.shot('play')
    r.hold(right, 120)
    r.hold('', 20)
    r.shot('moved-right')
    r.hold(left, 60)
    r.hold('', 20)
    r.shot('moved-left')
    r.hold(up, 30)
    r.hold('', 30)
    r.shot('up')
    r.hold(fire, 40)
    r.hold('', 30)
    r.shot('fire')
    r.hold(fire, 10)
    r.hold(fire + '+P', 6)
    r.hold('', 300)
    r.shot('quit')


def plan_opt2(r):
    """opt2: from the menu after the load (explore/loaded.szx): option 2 (Joystick 2, the keys 1 left, 2 right,
    4 up, 5 fire), fire, the intro, then right, left, up (a jump), fire held (an attack), the quit (fire held, then P)"""
    plan_option(r, '2', '1', '2', '4', '5')


def plan_opt3(r):
    """opt3: as opt2 with option 3 (the Kempston joystick: KL KR KU KF)"""
    plan_option(r, '3', 'KL', 'KR', 'KU', 'KF')


def plan_opt4(r):
    """opt4: as opt2 with option 4 (Protek or cursor: 5 left, 8 right, 7 up, 0 fire)"""
    plan_option(r, '4', L, R, U, F)


def map_rooms():
    """{room: (row, column)} from the image's tables (`$70C7` counts, `$70DB` starts, `$7048` columns)"""
    img = open(os.path.join(CASE, 'work', 'mkgame', 'original.bin'), 'rb').read()
    out = {}
    for row in range(20):
        for i in range(img[0x70C7 + row]):
            out[img[0x70DB + row] + i + 1] = (row, img[0x7048 + img[0x70DB + row] + i])
    return out


UNSEEN = (11, 12, 13, 14, 18, 19, 21, 36, 47, 48, 49, 50, 52, 55, 91, 92)


def plan_rooms(r):
    """rooms: from play0 (work/stage1/probe/play0.szx, room 4 at the start of play, c1's state): left along the surface
    to rooms 3, 2, 1 (walks and jumps over the stones), then the rooms the RZX run never entered, by POKE: the map row
    `$69DF` and column `$69E0` set beside the target, so the next crossing of the screen edge (right after entering
    from the left, left after entering from the right) builds the target room; each room's screen 100 frames later"""
    for spec, n in ((L, 400), (L + '+7', 40), (L, 100), (L + '+7', 40), (L, 100), (L, 150), (L + '+7', 40), (L, 150),
                    ('7', 10), (L + '+7', 30), (L, 60), ('7', 10), (L + '+7', 30), (L, 200)):
        r.hold(spec, n)
    r.hold('', 50)
    r.shot('room-%d' % r.lab.read(0x6BDD, 1)[0])
    grid = map_rooms()
    right = True
    for room in UNSEEN:
        row, col = grid[room]
        r.poke(0x69DF, [row, col - 1 if right else col + 1], f'map row and column beside room {room}')
        r.hold(R if right else L, 40)
        r.hold('', 100)
        got = r.lab.read(0x6BDD, 1)[0]
        r.shot(f'room-{got}')
        right = not right


def plan_play48(r):
    """play48: the 48K game played from the keyboard (run with --model 48K --start work/stage1/rec/c48/end.szx, c48's
    title): 4 (Protek or cursor), fire, the intro, then play for about 3000 frames: right through the first rooms,
    jumps, fire held and let go (punch, kick), up and down, back left and right again until enemies hit; the 48K effect
    player at `$853F` is the sound"""
    r.shot('title')
    r.tap('4', 4, 60)
    r.shot('title-4')
    r.tap(F, 5, 200)
    r.shot('intro-1')
    for k in range(12):
        r.wait(150)
        if r.lab.read(0x845F, 1)[0] == 0 and r.lab.read(0x5D02, 1)[0] & 1:
            break
    r.wait(100)
    r.shot('play-start')
    walk(r, R, 150, 'right-1')
    walk(r, UR, 30, 'jump-right')
    r.wait(30)
    walk(r, F, 20)
    walk(r, '', 10, 'punch')
    walk(r, F, 60)
    walk(r, '', 20, 'kick')
    walk(r, R, 250, 'right-2')
    walk(r, U, 40, 'up')
    walk(r, D, 40, 'down')
    for i in range(10):
        walk(r, R, 80)
        walk(r, UR, 30)
        walk(r, F, 25)
        walk(r, '', 15, f'fight-{i}' if i % 3 == 0 else None)
    walk(r, L, 300, 'left')
    for i in range(6):
        walk(r, L, 60)
        walk(r, D, 40, f'down-{i}' if i % 2 == 0 else None)
    r.wait(200)
    r.shot('end')


PLANS = {'play48': plan_play48, 'c1': plan_c1, 'c48': plan_c48, 'menu': plan_menu, 'gameover': plan_gameover, 'rooms': plan_rooms, 'opt2': plan_opt2, 'opt3': plan_opt3, 'opt4': plan_opt4}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('plan')
    ap.add_argument('--work')
    ap.add_argument('--port-base', type=int, default=37470)
    ap.add_argument('--model', default='128K')
    ap.add_argument('--start')
    ap.add_argument('--ranges', default='4000-FFFF')
    ap.add_argument('--keep', action='store_true', help='leave the instance running (session.json)')
    a = ap.parse_args()
    if a.plan == 'list':
        for k, f in PLANS.items():
            print(k, '-', (f.__doc__ or '').split('\n')[0])
        return
    work = os.path.abspath(a.work)
    os.makedirs(work, exist_ok=True)
    lab = Lab(a.port_base, model=a.model)
    lab.session_json(work, a.ranges)
    r = Run(lab, work)
    began = time.time()
    try:
        if a.start:
            lab.load(os.path.abspath(a.start))
        else:
            lab.save(os.path.join(work, 'power-on.szx'))
        lab.start_recording()
        lab.frame = 0
        PLANS[a.plan](r)
        r.keys([])
        lab.save(os.path.join(work, 'end.szx'))
        rec = {'plan': a.plan, 'note': PLANS[a.plan].__doc__, 'model': a.model, 'start': a.start or 'power-on',
               'frames': lab.frame, 'moments': r.moments, 'tape': r.tape_log, 'pokes': r.pokes,
               'seconds': round(time.time() - began)}
        name = os.path.basename(work)
        os.makedirs(os.path.join(CASE, 'tests', 'inputs'), exist_ok=True)
        r.script(os.path.join(CASE, 'tests', 'inputs', f'{name}.txt'), PLANS[a.plan].__doc__)
        s = lab.s
        # the TTD first: a build that outlives the HTTP timeout must not lose the recording
        d = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        rec['ttd'] = (d.text or '').splitlines()[:2]
        try:
            s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 1000}, ok=False)
        except OSError as e:
            rec['build_call'] = str(e)
        st = ''
        for _ in range(720):
            try:
                st = s.call('analysis', {'action': 'status'}, ok=False).text
            except OSError:
                st = ': running'
            if ': running' not in st and os.path.exists(os.path.join(work, 'l1.json')):
                break
            time.sleep(10)
        rec['status'] = st.splitlines()[-3:]
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        print(json.dumps({k: rec[k] for k in ('frames', 'status', 'ttd', 'seconds')}, indent=1))
    finally:
        if not a.keep:
            lab.close()


if __name__ == '__main__':
    main()
