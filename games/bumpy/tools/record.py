#!/usr/bin/env python3
"""Bumpy recordings: a fresh muted 48K (RAM zeroed, a Kempston card, the Kempston mouse's counters set to `$FF`, see
lab.quiet_mouse), the TTD recording started at power-on (or after a start state is loaded), a plan of held keys
played over emulated frames (one run call per key change), screens at named moments, then end.szx, session.ttd,
l1.json, the input script of every key held (tests/inputs/<name>.txt, frames from the recording's start) and
record.json (the plan's note, the moments, the tape actions, the POKEs).

    python3 tools/record.py PLAN --work work/stage1/rec/NAME [--port-base 37510] [--start STATE] [--rzx FIRST LAST]
    python3 tools/record.py list

The tape is loaded at ROM speed (fast and turbo tape off), LOAD "" typed. The controls (the menu's 2, 3, 4):
keyboard Q up, A down, O left, P right, SPACE fire; Sinclair 9 up, 8 down, 6 left, 7 right, 0 fire; Kempston.
A POKE, where a plan uses one, is applied on the recording's machine only, written in record.json and in the plan's
note; the image of the case is cut from the tape, never from a recording with a POKE.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402

RZX = os.path.join(CASE, 'work', 'stage1', 'rzx')
KEYB = dict(U='Q', D='A', L='O', R='P', F='SPACE')
SINC = dict(U='9', D='8', L='6', R='7', F='0')


class Run:
    def __init__(self, lab, work):
        self.lab, self.work = lab, work
        self.moments, self.tape_log, self.pokes, self.keylog, self.notes = [], [], [], [], []
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
        self.moments.append({'frame': self.lab.frame, 'name': name, 'state': self.state()})

    def state(self):
        b = self.lab.read(0xAAFB, 12)
        return {'score': b[0] | b[1] << 8, 'water': b[2], 'keys': b[3], 'hammers': b[4], 'level': b[5], 'lives': b[6],
                'timer': b[9] | b[10] << 8}

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
    """Power-on to the menu: LOAD "" typed, the tape at ROM speed"""
    lab = r.lab
    for name in ('fast_tape', 'turbo_tape'):
        lab.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                  'body': {'value': False}}, ok=False)
    from lab import tape_file
    lab.s.call('load_software', {'path': tape_file(), 'autostart': False, 'play': False}, ok=False)
    r.tape_log.append({'frame': lab.frame, 'action': 'insert', 'path': 'orig/Bumpy.tap.zip: BUMPY.TAP'})
    r.wait(150)
    r.shot('rom')
    for k in ('J', 'SS+P', 'SS+P', 'ENTER'):
        r.tap(k, 3, 5)
    lab.m.post('/tape/play', None)
    lab.mute()
    r.tape_log.append({'frame': lab.frame, 'action': 'play'})
    k = 0
    while k < 60:
        r.wait(500)
        k += 1
        if k in (1, 2, 4, 10, 20):
            r.shot(f'loading-{k}')
        st = lab.tape()
        if k > 3 and st.get('state') in ('ended', 'idle', 'stopped'):
            break
    r.tape_log.append({'frame': lab.frame, 'action': 'ended', 'state': lab.tape().get('state')})
    r.wait(100)
    r.shot('menu')


def play_moves(r, c, rounds=3, tag=''):
    """Each control in turn, held for a while, with fire taps between"""
    for i in range(rounds):
        r.hold(c['R'], 40); r.shot(f'{tag}right-{i}')
        r.hold(c['L'], 40); r.shot(f'{tag}left-{i}')
        r.hold(c['U'], 30); r.shot(f'{tag}up-{i}')
        r.hold(c['D'], 30); r.shot(f'{tag}down-{i}')
        r.hold(c['F'], 6); r.wait(30); r.shot(f'{tag}fire-{i}')
        r.hold(c['R'] + '+' + c['U'], 30)
        r.hold(c['L'] + '+' + c['U'], 30)
        r.wait(40)


def plan_c1(r):
    """c1: power-on on a 48K, the original tape (orig/Bumpy.tap.zip) loaded by LOAD "" at ROM speed (the BASIC, the
    screen, the code, RANDOMIZE USR 43900), the menu; 1 twice (ONE PLAYER, TWO PLAYERS, ONE PLAYER), 2 (keyboard), 0
    (game); READY? and a key; play on level 0 with every key (O P Q A SPACE) for about 1500 frames, then no key until
    the level's timer runs out or the ball is lost"""
    boot(r)
    r.tap('1', 4, 40); r.shot('menu-1')
    r.tap('1', 4, 40); r.shot('menu-1b')
    r.tap('2', 4, 40); r.shot('menu-keyboard')
    r.tap('0', 4, 100); r.shot('ready')
    r.tap('SPACE', 4, 60); r.shot('play-start')
    play_moves(r, KEYB, 4)
    for i in range(12):
        r.wait(250)
        r.shot(f'idle-{i}')


def plan_menu(r):
    """menu: from the menu after a fast load (work/stage1/probe/load-fast-nokemp/end.szx): first no key for 4000
    frames (the menu's idle path: `$B3B1` = 4 at `$EF97` starts the game with `$ABA6` = 1 and the demo pointer
    `$ABA4` = `$D25A`), a key back to the menu; then for each control 2
    (keyboard Q A O P SPACE), 3 (Sinclair 9 8 6 7 0), 4 (Kempston, the card's stick): the option, 0 (game), READY?,
    a few moves, then H and R (the keys of the table's last two slots) and BREAK (CAPS SHIFT + SPACE); then 1 (TWO
    PLAYERS), 2, 0: the two-player game's first turns; R, 1 (ONE PLAYER), 2, and 0 with R, SPACE and V held (the
    test at `$ABBD`-`$ABD0` that calls `$BB56`)"""
    r.shot('menu')
    for i in range(16):
        r.wait(250); r.shot(f'idle-{i:02d}')
    r.tap('SPACE', 4, 200); r.shot('idle-key')
    for i in range(4):
        r.wait(250); r.shot(f'idle-after-{i}')
    for opt, c in (('2', KEYB), ('3', SINC), ('4', dict(U='KU', D='KD', L='KL', R='KR', F='KF'))):
        r.tap(opt, 4, 40); r.shot(f'opt{opt}')
        r.tap('0', 4, 100); r.shot(f'opt{opt}-ready')
        r.tap(c['F'], 4, 60); r.shot(f'opt{opt}-play')
        play_moves(r, c, 1, f'opt{opt}-')
        r.tap('H', 4, 60); r.shot(f'opt{opt}-H')
        r.tap('H', 4, 60); r.shot(f'opt{opt}-H2')
        r.tap('R', 4, 100); r.shot(f'opt{opt}-R')
        r.tap('CS+SPACE', 4, 100); r.shot(f'opt{opt}-break')
        r.wait(200); r.shot(f'opt{opt}-after')
    r.tap('1', 4, 40); r.shot('two-players')
    r.tap('2', 4, 40)
    r.tap('0', 4, 100); r.shot('p1-ready')
    r.tap('SPACE', 4, 60)
    play_moves(r, KEYB, 2, 'p1-')
    for i in range(10):
        r.wait(300); r.shot(f'p2-{i}')
        r.tap('SPACE', 4, 20)
    r.tap('R', 4, 150); r.shot('p2-R')
    r.tap('1', 4, 40); r.tap('2', 4, 40); r.shot('cheat-menu')
    r.hold('R+SPACE+V', 20)
    r.hold('R+SPACE+V+0', 10)
    r.hold('R+SPACE+V', 60); r.shot('cheat-start')
    r.tap('SPACE', 4, 100); r.shot('cheat-play')


def plan_gameover(r):
    """gameover: from the menu after a fast load (work/stage1/probe/load-fast-nokemp/end.szx): 2 (keyboard), 0,
    READY? and SPACE, a round of moves, then S (key code `$31`, tested at `$AE7A`: a life lost, `$BA71`) three times
    with SPACE at each READY?: two lives lost and the game over (`$B755`) with a score under the high score (1700,
    `$EF25`); back at the menu, a second game: 2, 0, SPACE, then a POKE on this machine, the score `$AAFB` = 2000
    (said so), and S three times: the game over with a new high score (`$EC40`), the name typed (B U M, ENTER)"""
    for game in range(2):
        r.tap('2', 4, 40)
        r.tap('0', 4, 100); r.shot(f'g{game}-ready')
        r.tap('SPACE', 4, 60); r.shot(f'g{game}-play')
        if game == 0:
            play_moves(r, KEYB, 1, 'g0-')
        else:
            r.poke(0xAAFB, [2000 & 255, 2000 >> 8], 'score 2000, over the high score 1700, to reach the name entry')
        for k in range(3):
            r.tap('S', 4, 10); r.shot(f'g{game}-S{k}')
            for i in range(4):
                r.wait(100); r.shot(f'g{game}-S{k}-{i}')
            r.tap('SPACE', 4, 60); r.shot(f'g{game}-S{k}-space')
        for i in range(6):
            r.wait(150); r.shot(f'g{game}-after-{i}')
        if game == 1:
            for key in ('B', 'U', 'M', 'ENTER'):
                r.tap(key, 4, 40); r.shot(f'name-{key}')
            for i in range(6):
                r.wait(150); r.shot(f'g1-end-{i}')


def rzx_rows():
    plays = [l.split() for l in open(os.path.join(RZX, 'levels', 'plays.tsv')) if not l.startswith('#')]
    lchg = [int(l.split()[0]) for l in open(os.path.join(RZX, 'levels', 'levels.tsv')) if not l.startswith('#')]
    return [(int(f), int(lv)) for f, lv in plays], lchg


def plan_rzx(r, first, last, margin=150):
    """rzx: the RZX archive's run (bumpy.rzx, xmikex and Jamie Angus, SPIN 0.5, recorded with rollback; someone
    else's play), one level a recording: from the RZX's play start of the level (tools/rzx_levels.py play-F.z80, the
    state after RZX frame F, the timer `$AB04`'s first count after READY?), the Kempston byte of the key buffer `$B43E`
    set to `$FF` (SPIN's own port `$DF` reads left another value there, which our machine never rewrites), then the
    player's keys (tools/rzx_keys.py: the Sinclair stick 6 7 8 9 0 and the key 3; in the next READY? wait B held on
    the RZX's start frame - 10) held frame by frame, one run call per change, to the next level change + 150 frames
    (the last level: to the RZX's end, the ending included). The game draws random numbers from the R register
    (`LD A,R`, `$F184`, `$F527`), so a replay holds only from the RZX's own state: a level a recording"""
    from rzx_keys import replay_keys, starts
    plays, lchg = starts()
    a = plays[first][0]
    nxt = [c for c in lchg if c > plays[last][0]]
    b = 150437 if last >= 99 or not nxt else min(nxt[0] + margin, 150437)
    fk = replay_keys(a, b)
    r.shot('start')
    f = a
    seen = r.state()['level']
    r.notes.append({'rzx_from': a, 'rzx_to': b, 'level': seen})
    k = 0
    while f < b:
        g = f + 1
        while g < b and fk[g + 1] == fk[f + 1] and g - f < 50:
            g += 1
        r.keys(fk[f + 1])
        r.lab.run(g - f)
        f = g
        k += 1
        st = r.state()
        if st['level'] != seen:
            r.notes.append({'frame': r.lab.frame, 'rzx_frame': f, 'level': st['level']})
            r.shot(f'level-{st["level"]:02d}')
            seen = st['level']
        elif r.lab.frame // 250 != (r.lab.frame - (g - (f - (g - f)))) // 250 and k % 8 == 0:
            pass
    r.keys([])
    r.shot('end')


PLANS = {'c1': plan_c1, 'menu': plan_menu, 'gameover': plan_gameover, 'rzx': plan_rzx}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('plan')
    ap.add_argument('--work')
    ap.add_argument('--port-base', type=int, default=37510)
    ap.add_argument('--model', default='48K')
    ap.add_argument('--start')
    ap.add_argument('--rzx', nargs=2, type=int)
    ap.add_argument('--ranges', default='4000-FFFF')
    ap.add_argument('--no-build', action='store_true')
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
        start = a.start
        if a.plan == 'rzx':
            plays, _ = rzx_rows()
            start = os.path.join(RZX, 'levels', f'play-{plays[a.rzx[0]][0]:06d}.z80')
        if start:
            lab.load(os.path.abspath(start))
        lab.quiet_mouse()
        if a.plan == 'rzx':
            r.poke(0xB43E, [0xFF], 'the key buffer\'s Kempston byte: no stick (SPIN\'s port $DF reads left another value)')
        if not start:
            lab.save(os.path.join(work, 'power-on.szx'))
        lab.start_recording()
        lab.frame = 0
        if a.plan == 'rzx':
            plan_rzx(r, *a.rzx)
        else:
            PLANS[a.plan](r)
        r.keys([])
        lab.save(os.path.join(work, 'end.szx'))
        rec = {'plan': a.plan, 'note': PLANS[a.plan].__doc__, 'model': a.model, 'start': start or 'power-on',
               'rzx': a.rzx, 'frames': lab.frame, 'moments': r.moments, 'tape': r.tape_log, 'pokes': r.pokes,
               'notes': r.notes, 'seconds': round(time.time() - began)}
        name = os.path.basename(work)
        r.script(os.path.join(CASE, 'tests', 'inputs', f'{name}.txt'), PLANS[a.plan].__doc__)
        s = lab.s
        d = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        rec['ttd'] = (d.text or '').splitlines()[:2]
        if not a.no_build:
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
