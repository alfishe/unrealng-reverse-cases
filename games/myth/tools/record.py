#!/usr/bin/env python3
"""Myth recordings: a fresh muted machine (RAM zeroed, a Kempston card), the TTD recording started at power-on (or
after a start state is loaded), a plan of held keys played over emulated frames, screens at named moments, then
end.szx, l1.json, session.ttd, the input script of every key held (tests/inputs/<name>.txt, frames from the
recording's start) and record.json (the plan's note, the moments, the tape actions, the POKEs).

    python3 tools/record.py PLAN --work work/stage1/rec/NAME [--port-base 37470] [--start STATE.szx|.z80]
    python3 tools/record.py list

The tape is played at signal speed (fast and turbo tape off): the loader is Speedlock 7, no ROM LD-BYTES. The TZX
stops the tape after the main block and after each stage block (ID 20 with a pause of 0); the game then waits, and
a plan presses play again when the game asks for the next stage (`tape_play`).

The controls (the instructions, checked in stage 1): Q left, W right, I up (jump), J down, O fire, H pause, SPACE
the item window. A POKE, where a plan uses one, is applied on the recording's machine only, written in record.json
and in the plan's note; the image of the case is cut from c1 (case.json), never from a recording with a POKE.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402

TAPE = os.path.join(CASE, 'work', 'stage1', 'media', 'myth.tzx')
L, R, U, D, F = 'Q', 'W', 'I', 'J', 'O'


class Run:
    def __init__(self, lab, work):
        self.lab, self.work = lab, work
        self.moments, self.tape_log, self.pokes, self.keylog = [], [], [], []
        self.held = []
        os.makedirs(os.path.join(work, 'screens'), exist_ok=True)

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

    def tape_play(self):
        """Play: a stop block (ID 20, pause 0) leaves the cursor on it; one press passes it, so press until playing"""
        for _ in range(3):
            self.lab.post('/tape/play', {})
            self.lab.run(2)
            if self.tape().get('state') == 'playing':
                break
        self.tape_log.append({'frame': self.lab.frame, 'action': 'play',
                              'block': (self.tape().get('position') or {}).get('block')})

    def wait_tape_stop(self, step=250, limit=60):
        """Runs until the tape stops by itself (the stop block after the block being loaded)"""
        for _ in range(limit):
            self.wait(step)
            if self.tape().get('state') != 'playing':
                break
        self.tape_log.append({'frame': self.lab.frame, 'action': 'stopped',
                              'block': (self.tape().get('position') or {}).get('block')})

    def menu_row(self):
        """The highlighted menu line: 10 START GAME, 12 DEFINE KEYS, 14 SELECT JOYSTICK (its two attribute rows
        are equal: the bright cycling colour), else None"""
        a = self.lab.read(0x5800, 768)
        for r in (10, 12, 14):
            if a[r * 32 + 16] == a[(r + 1) * 32 + 16]:
                return r
        return None

    def menu_select(self, row, limit=600):
        """Waits for the highlight to come to @p row, then SPACE"""
        n = 0
        while self.menu_row() != row and n < limit:
            self.wait(2)
            n += 2
        self.wait(6)
        self.tap('SPACE', 4, 30)

    def poke(self, addr, data, why):
        self.lab.write(addr, bytes(data))
        self.pokes.append({'frame': self.lab.frame, 'address': f'${addr:04X}', 'bytes': list(data), 'why': why})

    def script(self, path, note):
        with open(path, 'w') as f:
            for line in (note or '').strip().splitlines():
                f.write('# ' + line.strip() + '\n')
            for frame, keys in self.keylog:
                f.write(f'{frame} {" ".join(keys) if keys else "-"}\n')
            f.write(f'{self.lab.frame} END\n')


def boot(r):
    """Power-on to the logo: LOAD "" on a 48K (the 128K menu's Tape Loader on a 128K), the tape at signal speed
    until it stops after the main block"""
    lab = r.lab
    for name in ('fast_tape', 'turbo_tape'):
        lab.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                  'body': {'value': False}}, ok=False)
    lab.s.call('load_software', {'path': TAPE, 'autostart': False, 'play': False}, ok=False)
    lab.mute()
    r.tape_log.append({'frame': lab.frame, 'action': 'insert', 'path': 'myth.tzx'})
    r.wait(200)
    r.shot('rom')
    if lab.model == '48K':
        for k in ('J', 'SS+P', 'SS+P', 'ENTER'):
            r.tap(k, 3, 5)
    else:
        r.tap('ENTER', 3, 5)
    r.tape_play()
    for k in range(80):
        r.wait(250)
        if k in (4, 12, 20):
            r.shot(f'loading-{k}')
        t = r.tape()
        block = (t.get('position') or {}).get('block') or 0
        # unreal-ng's tape follows the loader (it pauses while no loader listens and starts again when one does):
        # play is pressed once; the load is over when the tape stands at the stop block after the main block
        if t.get('state') != 'playing' and block >= 33:
            break
    r.tape_log.append({'frame': lab.frame, 'action': 'stopped', 'block': block})
    r.wait(100)
    r.shot('logo')


def to_menu(r):
    """The logo waits for SPACE ($7966: IN $7FFE bit 0); then the credits cycle, and SPACE gives the menu (a press
    in the credits' change-over is not taken: pressed again until the menu shows)"""
    r.tap('SPACE', 4, 100)
    r.shot('credits')
    for _ in range(12):
        r.tap('SPACE', 4, 80)
        if any(r.menu_row() is not None for _ in [r.wait(40)] * 1):
            break
    r.shot('menu')


def start_stage(r, name='stage1'):
    """START GAME, the stage title, the stage block loaded until the tape stops (the tape starts by itself when the
    loader listens; play is pressed only if it does not)"""
    r.menu_select(10)
    r.shot('start')
    r.wait(100)
    if r.tape().get('state') != 'playing':
        r.tape_play()
    r.wait(100)
    r.shot(f'{name}-title')
    r.wait_tape_stop()
    r.wait(50)
    r.shot(f'{name}-loaded')


def walk(r, spec, frames, name=None):
    r.hold(spec, frames)
    if name:
        r.shot(name)


def plan_c1(r):
    """c1: power-on on a 48K, LOAD "", the original tape at signal speed by its own loader (Speedlock 7), the logo,
    SPACE, the credits, SPACE, the menu, START GAME, stage 1 loaded from the tape, then play: right, left, a jump,
    fire with each direction, crouch, the item window (SPACE), pause (H)"""
    boot(r)
    to_menu(r)
    r.lab.save(os.path.join(r.work, 'menu.szx'))
    start_stage(r, 'stage1')
    r.wait(450)                       # the first screen is built about 400 frames after the tape stops
    r.shot('play-start')
    r.lab.save(os.path.join(r.work, 'stage1.szx'))
    walk(r, R, 60, 'right')
    walk(r, L, 60, 'left')
    walk(r, U, 30, 'up')
    r.wait(30)
    walk(r, D, 20, 'down')
    r.wait(20)
    for d in ('', R, L, U, D, U + '+' + R, D + '+' + R):
        walk(r, F + ('+' + d if d else ''), 16, 'fire-' + (d.replace('+', '') or 'none'))
        r.wait(20)
    r.tap('SPACE', 4, 30)
    r.shot('items')
    r.tap(R, 4, 30)
    r.tap('SPACE', 4, 30)
    r.shot('items-out')
    r.tap('H', 4, 50)
    r.shot('pause')
    r.tap('H', 4, 50)
    r.shot('unpause')
    walk(r, R, 200, 'right-2')
    walk(r, L, 200, 'left-2')
    r.wait(100)
    r.shot('end')


def plan_menu(r):
    """menu: from c1's menu state (STATE work/stage1/c1/menu.szx or a fresh load): DEFINE KEYS (the prompts, each
    key typed: Z X K M SPACE-less fire L, pause P), SELECT JOYSTICK (each choice), then START GAME with the new
    keys and a short walk"""
    r.shot('menu')
    r.menu_select(12)
    r.wait(30)
    r.shot('define-1')
    for k in ('Z', 'X', 'K', 'M', 'L', 'P'):
        r.tap(k, 16, 60)
        r.shot(f'define-{k}')
    r.wait(100)
    r.shot('define-done')
    r.menu_select(14)
    r.wait(30)
    r.shot('joystick-1')
    for i in range(4):
        r.tap('SPACE', 16, 80)
        r.shot(f'joystick-{i + 2}')
    r.wait(200)
    r.shot('menu-after')


def plan_gameover(r):
    """gameover: from c1's stage 1 state in play (STATE work/stage1/c1/stage1.szx, 48K, lives 5): POKE lives `$FE61`
    to 1 (said: the only patched byte, never in the image), then the deaths plan's moves (back and forth by the
    first skeleton, no fire) until the energy runs out and the last life goes, then 1200 frames of what follows"""
    r.shot('start')
    r.poke(0xFE61, [1], 'lives to 1 to reach the game over quickly')
    for i in range(80):
        r.hold('W' if i % 8 < 4 else 'Q', 50)
        r.hold('', 25)
        if i % 4 == 0:
            r.shot(f'step-{i}-energy{r.lab.read(0xFE3F, 1)[0]}')
        if r.lab.read(0xFE61, 1)[0] == 0:
            r.shot('last-life-lost')
            break
    for i in range(12):
        r.wait(100)
        r.shot(f'after-{i}')


def plan_deaths(r):
    """deaths: from c1's stage 1 state in play (STATE work/stage1/c1/stage1.szx, 48K, no POKE): stand in the
    skeleton's way, then walk left into the cave without firing, losing lives one by one; the energy bar and the
    lives icons as they change"""
    r.shot('start')
    for i in range(40):
        r.hold('W' if i % 8 < 4 else 'Q', 50)
        r.hold('', 25)
        if i % 4 == 0:
            r.shot(f'step-{i}-lives{r.lab.read(0xFE61, 1)[0]}-energy{r.lab.read(0xFE3F, 1)[0]}')


def plan_stage(r):
    """stageN (N from $STAGE, 1-5): from c1's menu state (STATE work/stage1/c1/menu.szx, 48K), the original tape put
    back in and its cursor moved to stage N's block (the emulator's block 34 + 2 (N - 1); tape/seek, said: the only
    change from a user's load, who would have played through the stages before), START GAME, the block loaded at
    signal speed by the game's own stage loader, then about 6000 frames of play with the default keys: right and
    left in turns, jumps, fire"""
    n = int(os.environ.get('STAGE', '1'))
    r.lab.insert_tape(TAPE, play=False)
    r.menu_select(10)
    r.wait(60)
    r.lab.post('/tape/seek', {'block': 34 + 2 * (n - 1)})
    r.tape_log.append({'frame': r.lab.frame, 'action': 'seek', 'block': 34 + 2 * (n - 1)})
    r.shot('press-play')
    r.tape_play()
    r.wait(100)
    r.shot(f'stage{n}-title')
    r.wait_tape_stop()
    r.wait(450)
    r.shot(f'stage{n}-start')
    for i in range(50):
        d = 'W' if (i // 6) % 2 == 0 else 'Q'
        r.hold(d + ('+O' if i % 3 == 0 else ''), 60)
        r.hold('', 10)
        if i % 4 == 1:
            r.hold('I+' + d, 20)
        if i % 7 == 3:
            r.hold('O+I', 10)
        if i % 5 == 0:
            r.shot(f'stage{n}-play-{i}')
    r.shot(f'stage{n}-end')


PLANS = {'c1': plan_c1, 'menu': plan_menu, 'gameover': plan_gameover, 'deaths': plan_deaths, 'stage': plan_stage}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('plan')
    ap.add_argument('--work')
    ap.add_argument('--port-base', type=int, default=37470)
    ap.add_argument('--model', default='48K')
    ap.add_argument('--start')
    ap.add_argument('--ranges', default='4000-FFFF')
    ap.add_argument('--keep', action='store_true', help='leave the instance running (session.json)')
    ap.add_argument('--no-l1', action='store_true')
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
        lab.mute()
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
        d = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        rec['ttd'] = (d.text or '').splitlines()[:2]
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        if not a.no_l1:
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
        print(json.dumps({k: rec.get(k) for k in ('frames', 'status', 'ttd', 'seconds')}, indent=1))
    finally:
        if not a.keep:
            lab.close()


if __name__ == '__main__':
    main()
