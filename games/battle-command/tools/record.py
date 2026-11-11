#!/usr/bin/env python3
"""Battle Command recordings: a fresh muted 128K (RAM zeroed, a Kempston card), the TTD recording started at power-on
(or after a start state is loaded), a plan played with the pointer bot (tools/bcbot.py), the tapes handled as a player
does (side 1 played after the 128K menu's Tape Loader; side 2 inserted when the game asks for the mission tape, and
played again when a mission is to be searched; a `seek` is the player winding the tape), screens at named moments,
then end.szx, l1.json, session.ttd, the input script of every key held (tests/inputs/<name>.txt: keys only, the tape
actions are in record.json with their frames) and record.json.

    python3 tools/record.py PLAN --work work/stage1/rec/NAME [--port-base 37310] [--start work/stage1/lab/S.szx]
    python3 tools/record.py list

A POKE, where a plan uses one, is applied on the recording's machine after the load, written in record.json and in
the plan's note; the image of the case is cut from the tape (case.json), never from a recording.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402
from bcbot import Bot  # noqa: E402

SIDE1 = os.path.join(CASE, 'work', 'stage1', 'media', 'side1.tzx')
SIDE2 = os.path.join(CASE, 'work', 'stage1', 'media', 'side2.tzx')
MENU = {'start': (40, 182), 'options': (127, 182), 'load': (210, 182)}
MISSION_Y = [67 + 8 * k for k in range(10)]
CLIP = {'search': (65, 150), 'briefing': (65, 166), 'select': (65, 182), 'status': (195, 182)}
STORES = {'next': (96, 153), 'prev': (32, 153), 1: (150, 52), 2: (222, 52), 3: (150, 98), 4: (222, 98),
          'start': (190, 183)}
WEAPONS = ['Turret', 'Banshee RRSS', 'Banshee IRSS', 'Phoenix RRSA', 'Phoenix IRSA', 'K-40 Mortar', 'Sleeper mine',
           'Dragonfly', 'K-90 Cluster', 'Spectre', 'Phantasm', 'Skeet bomb', 'SLAM Laser']


class Run:
    def __init__(self, lab, work):
        self.lab, self.work = lab, work
        self.b = Bot(lab)
        self.moments, self.tape_log, self.pokes = [], [], []
        os.makedirs(os.path.join(work, 'screens'), exist_ok=True)

    def shot(self, name):
        self.lab.shot(os.path.join(self.work, 'screens', f'{self.lab.frame:06d}-{name}.png'))
        self.moments.append({'frame': self.lab.frame, 'name': name, 'cursor': self.b.cursor()})

    def tape(self):
        t = self.lab.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/tape'}, ok=False)
        return ((t.structured or {}).get('body') or {})

    def tape_do(self, what, **kw):
        self.tape_log.append({'frame': self.lab.frame, 'action': what, **kw})
        if what == 'insert':
            self.lab.insert_tape(kw['path'], play=False)
        elif what == 'seek':
            self.lab.post('/tape/seek', {'block': kw['block']})
        else:
            self.lab.post('/tape/' + what, {})

    def wait_tape(self, block_at_least, limit, step=100):
        """Runs until the tape is past @p block_at_least and no longer playing (the game stopped reading it)"""
        done = 0
        while done < limit:
            self.b.wait(step)
            done += step
            t = self.tape()
            pos = (t.get('position') or {}).get('block', 0)
            if pos >= block_at_least and t.get('state') != 'playing':
                return done
        return done

    def poke(self, addr, data, why, bank=None):
        """A POKE on the recording's machine: @p addr in the Z80 view, or with @p bank at $C000 + offset of that bank"""
        if bank is None:
            self.lab.write(addr, bytes(data))
        else:
            self.lab.post(f'/memory/page/ram/{bank}', {'offset': str(addr - 0xC000), 'data': list(data)})
        self.pokes.append({'frame': self.lab.frame, 'address': f'${addr:04X}', 'bank': bank, 'bytes': list(data),
                           'why': why})


def boot_side1(r):
    """Power-on to the title: 128K menu, Tape Loader (ENTER), side 1 at signal speed, the countdown, the title"""
    lab = r.lab
    for name in ('fast_tape', 'turbo_tape'):
        lab.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                  'body': {'value': False}}, ok=False)
    lab.s.call('load_software', {'path': SIDE1, 'autostart': False, 'play': False}, ok=False)
    r.tape_log.append({'frame': lab.frame, 'action': 'insert', 'path': 'side1.tzx'})
    r.b.wait(200)
    r.shot('128-menu')
    r.b.key('ENTER', 3, 5)
    r.tape_do('play')
    k = 0
    while k < 40:
        r.b.wait(1000)
        k += 1
        if k in (1, 3, 10):
            r.shot(f'loading-{k}')
        if r.tape().get('state') in ('ended', 'idle', 'stopped') and k > 3:
            break
    r.shot('tape-end')
    r.b.wait(300)
    r.shot('title')


def options(r, method_key='5'):
    r.b.click(*MENU['options'], after=40)
    r.shot('options')
    r.b.key(method_key, 3, 40)
    r.shot(f'options-{method_key}')


def mission_tape(r):
    """START GAME, the mission tape (side 2) inserted and played, the catalogue loaded"""
    r.b.click(*MENU['start'], after=60)
    r.shot('rewind-mission-tape')
    r.tape_do('insert', path=SIDE2)
    r.tape_do('play')
    r.wait_tape(3, 4000)
    r.b.wait(50)
    r.shot('catalogue')


def load_mission(r, n, seek_block=None):
    """Mission n (1..10) marked, SEARCH (the tape played until its header is found), SELECT (its block loaded)"""
    r.b.click(60, MISSION_Y[n - 1], after=20)
    r.shot(f'mission-{n}-marked')
    if seek_block is not None:
        r.tape_do('seek', block=seek_block)
    r.b.click(*CLIP['search'], after=20)
    r.tape_do('play')
    r.wait_tape(1, 30000, step=200)
    r.shot(f'mission-{n}-found')
    r.b.click(*CLIP['select'], after=20)
    r.tape_do('play')
    r.wait_tape(1, 5000, step=100)
    r.b.wait(100)
    r.shot(f'mission-{n}-stores')


def fit(r, slots):
    """slots: {slot: weapon name}; the stores list is stepped with >> to each weapon and the slot clicked"""
    shown = 0
    for slot, name in slots.items():
        want = WEAPONS.index(name)
        while shown != want:
            r.b.click(*STORES['next'], after=12)
            shown = (shown + 1) % len(WEAPONS)
        r.b.click(*STORES[slot], after=15)
    r.shot('stores-fitted')


def drive(r, frames, keys):
    r.b.hold(keys, frames)


def plan_c1(r):
    """c1: power-on, side 1 loaded by its own loader, the title, OPTIONS (keyboard), START GAME, the mission tape,
    Blast Em Mission searched and loaded, the Turret fitted, the mission started, a short drive with the cannon"""
    boot_side1(r)
    options(r, '5')
    mission_tape(r)
    load_mission(r, 1)
    fit(r, {1: 'Turret'})
    r.b.click(*STORES['start'], after=200)
    r.shot('mission-start')
    for k in range(6):
        drive(r, 50, ['Q'])
        r.b.key('SPACE', 3, 30)
        drive(r, 20, ['O'])
        r.shot(f'play-{k}')
    r.b.wait(300)
    r.shot('end')


BRIEF = {'map': (27, 31), 'text': (27, 87), 'close': (27, 103)}
STATUS = {'save': (195, 30), 'selection': (195, 62)}


def quit_to_title(r, n):
    r.b.key('E', 25, 40)
    r.shot(f'mission-{n}-pause')
    r.b.key('Y', 25, 120)
    r.shot(f'mission-{n}-quit')


def plan_menu(r):
    """menu: from the title (explore/loaded.szx): OPTIONS with the control systems 1 (Sinclair), 2 (cursor keys) and
    5 (keyboard), the pointer moved and OPTIONS clicked with each; LOAD GAME with a level entry; START GAME, the
    mission tape's catalogue, the briefing text and map of all ten missions; STATUS; SAVE GAME (the entry string);
    MISSION SELECTION; last OPTIONS 4 (Kempston joystick), the pointer moved up, down and right with it"""
    r.shot('title')
    r.b.click(*MENU['options'], after=40)
    r.shot('options')
    for k, control in (('1', 'sinclair'), ('2', 'cursor'), ('5', 'keyboard')):
        r.b.key(k, 3, 40)
        r.b.control = control
        r.b.goto(60, 60)
        r.shot(f'options-{k}-pointer')
        r.b.click(*MENU['options'], after=40)
        r.shot(f'options-{k}-again')
    r.b.key('5', 3, 40)
    r.b.control = 'keyboard'
    r.b.click(*MENU['load'], after=60)
    r.shot('load-game')
    for k in '9999999999':
        r.b.key(k, 3, 8)
    r.shot('load-typed')
    r.b.key('ENTER', 8, 80)
    r.shot('load-entered')
    r.b.key('SPACE', 3, 60)
    r.shot('load-after')
    mission_tape(r)
    for n in range(1, 11):
        r.b.click(60, MISSION_Y[n - 1], after=20)
        r.shot(f'mission-{n}-marked')
        r.b.click(*CLIP['briefing'], after=60)
        r.shot(f'mission-{n}-briefing')
        r.b.click(*BRIEF['map'], after=60)
        r.shot(f'mission-{n}-map')
        r.b.click(*BRIEF['close'], after=40)
    r.b.click(*CLIP['status'], after=60)
    r.shot('status')
    r.b.click(*STATUS['save'], after=80)
    r.shot('save-code')
    r.b.key('SPACE', 3, 60)
    r.shot('save-after')
    r.b.click(*STATUS['selection'], after=60)
    r.shot('selection')


def plan_controls(r):
    """controls: from the title (explore/loaded.szx): OPTIONS 4 (Kempston joystick), each direction held; then
    OPTIONS 3 (Kempston mouse) reached with the joystick, the mouse moved in each direction and its button pressed"""
    r.b.click(*MENU['options'], after=40)
    r.b.key('4', 3, 40)
    r.shot('kempston-joystick')
    for k in ('KU', 'KD', 'KL', 'KR'):
        r.b.hold([k], 10)
        r.b.wait(4)
        r.shot(f'kempston-{k}')
    r.b.control = 'kempston'
    r.b.goto(*MENU['options'], tol=4)
    r.shot('kempston-goto-options')
    r.b.hold(['KF'], 3)
    r.b.wait(40)
    r.b.key('3', 3, 40)
    r.shot('mouse')
    r.b.control = 'mouse'
    for dx, dy in ((-20, 0), (20, 0), (0, 20), (0, -20)):
        for _ in range(10):
            r.b.mouse('move', dx=dx // 10, dy=dy // 10)
            r.b.wait(1)
        r.b.wait(4)
        r.shot(f'mouse-{dx}-{dy}')
    r.b.mouse('press', button='left')
    r.b.wait(3)
    r.b.mouse('release', button='left')
    r.b.wait(40)
    r.shot('mouse-click')


ERBE2 = os.path.join(CASE, 'work', 'stage1', 'media', 'zxdb__BattleCommand(ErbeSoftwareS.A.).tzx',
                     'Battle Command - Side 2 (Erbe).tzx')


def header_block(side, n):
    """The tape API's block index (GET /tape `blocks`: data and control blocks, the TZX text and info blocks left
    out) of mission n's `MISSHDR:n:` block: Ocean side 2 has a stop and the two blocks a mission (header 3, 6, 9,
    ...), the Erbe side 2 the two blocks (header 2, 4, 6, ...)"""
    return 3 + 3 * (n - 1) if side == SIDE2 else 2 + 2 * (n - 1)


def play_mission(r, n):
    fit(r, {1: 'Turret'})
    r.b.click(*STORES['start'], after=150)
    r.shot(f'mission-{n}-start')
    drive(r, 100, ['Q'])
    r.shot(f'mission-{n}-drive')
    r.b.key('M', 25, 60)
    r.shot(f'mission-{n}-mapscreen')
    r.b.key('C', 25, 40)
    quit_to_title(r, n)
    r.b.click(*MENU['start'], after=80)
    r.shot(f'after-{n}')


def plan_missions(r):
    """missions: from the title (explore/loaded.szx): the Ocean mission tape's catalogue, then missions 1 and 3-10,
    each with the tape wound to its header (SEARCH stops at the next header on the tape, whichever mission it is),
    SEARCH, SELECT, the Turret fitted, started, driven, its map screen, quit, START GAME back to the catalogue.
    Mission 2 is in m2ocean / m2erbe"""
    r.shot('title')
    mission_tape(r)
    for n in [1] + list(range(3, 11)):
        load_mission(r, n, seek_block=header_block(SIDE2, n))
        play_mission(r, n)


def mission2_from(r, side, label, wait, n=2):
    r.shot('title')
    r.b.click(*MENU['start'], after=60)
    r.shot('rewind-mission-tape')
    r.tape_do('insert', path=side)
    r.tape_do('play')
    r.wait_tape(3, 4000)
    r.b.wait(50)
    r.shot(f'{label}-catalogue')
    r.b.click(60, MISSION_Y[n - 1], after=20)
    r.tape_do('seek', block=header_block(side, n))
    r.b.click(*CLIP['search'], after=20)
    r.tape_do('play')
    r.wait_tape(1, 30000, step=200)
    r.shot(f'mission-{n}-found')
    r.b.click(*CLIP['select'], after=20)
    r.tape_do('play')
    r.wait_tape(1, wait, step=100)
    r.b.wait(100)
    r.shot(f'mission-{n}-after-load')


def plan_m2ocean(r):
    """m2ocean: from the title (explore/loaded.szx): Ocean side 2, its catalogue, the tape wound to Missile Battery's
    header (mission 2), SEARCH, SELECT: the 6384-byte block (its header says 6406) is read, and the game keeps
    reading the tape past it (screens every 1000 frames for 6000 frames)"""
    mission2_from(r, SIDE2, 'ocean', 2400)
    for i in range(6):
        r.b.wait(1000)
        r.shot(f'still-{i}')


def plan_m2erbe(r):
    """m2erbe: the same with the Erbe side 2 (its mission 2 block is 6406 bytes as the header says): it loads, the
    Turret is fitted, the mission started, driven, its map, quit"""
    mission2_from(r, ERBE2, 'erbe', 5000)
    play_mission(r, 2)


def k(r, key, after=30):
    """A key in play: the game reads keys once a 3D frame, so a key is held 25 frames"""
    r.b.key(key, 25, after)


def use_slot(r, slot, name):
    """Weapon slot @p slot selected, the module up button (J) held, fire twice (lock on, launch), then a look; the
    Dragonfly is launched by one fire, flown (forward, left) and left by fire again"""
    k(r, str(slot), 20)
    if name == 'Dragonfly':
        k(r, 'SPACE', 40)
        r.shot('Dragonfly-launched')
        r.b.hold(['Q'], 80)
        r.shot('Dragonfly-flying')
        r.b.hold(['O'], 40)
        r.shot('Dragonfly-turn')
        k(r, 'SPACE', 60)
        r.shot('Dragonfly-back')
        return
    k(r, 'J', 10)
    k(r, 'SPACE', 40)
    r.shot(f'{name}-lock')
    k(r, 'SPACE', 60)
    r.shot(f'{name}-fired')
    r.b.wait(60)
    r.shot(f'{name}-after')


LOADOUTS = [{1: 'Banshee RRSS', 2: 'K-40 Mortar', 3: 'Dragonfly', 4: 'Phantasm'},
            {1: 'Turret', 2: 'Banshee IRSS', 3: 'Phoenix RRSA', 4: 'Sleeper mine'},
            {1: 'Phoenix IRSA', 2: 'K-90 Cluster', 3: 'Spectre', 4: 'Skeet bomb'},
            {1: 'SLAM Laser'}]


def plan_play(r):
    """play: from the title (explore/loaded.szx): Blast Em Mission with the first four stores of LOADOUTS (play2 has
    the other nine), every slot used (module button, lock on, fire; the Dragonfly flown), the views
    (night sight N, binoculars B and zoom Z, rear view R), the Helicarrier call H, the damage screen D, the map M and
    its briefing, a drive, quit. POKEs (bank 6, from the release's .pok): `$C1C6` = $3A (no weight limit) at the
    stores and `$C875` = $3A (immunity) at the start of each mission"""
    r.shot('title')
    mission_tape(r)
    for n, loadout in enumerate(LOADOUTS[:1], 1):
        load_mission(r, n)
        r.poke(0xC1C6, [0x3A], 'no weight limit (.pok: 6 49606 58)', bank=6)
        fit(r, loadout)
        r.b.click(*STORES['start'], after=150)
        r.poke(0xC875, [0x3A], 'immunity (.pok: 8 51317 58, bank 6 paged in play)', bank=6)
        r.shot(f'm{n}-start')
        r.b.hold(['Q'], 60)
        for slot, name in loadout.items():
            use_slot(r, slot, name)
        if n == 1:
            for key, name in (('N', 'night'), ('N', 'night-off'), ('B', 'binoculars'), ('Z', 'zoom'), ('Z', 'zoom2'),
                              ('B', 'binoculars-off'), ('R', 'rear'), ('R', 'rear-off'), ('H', 'helicarrier'),
                              ('D', 'damage'), ('C', 'console'), ('M', 'map'), ('B', 'map-brief'), ('C', 'console2')):
                k(r, key, 40)
                r.shot(f'view-{name}')
        r.b.hold(['Q', 'P'], 100)
        r.shot(f'm{n}-drive')
        quit_to_title(r, n)
        r.b.click(*MENU['start'], after=80)


def plan_play2(r):
    """play2: from the title (explore/loaded.szx): three times the mission tape rewound and played (after a quit the
    game asks for it again), Blast Em Mission loaded with the next four stores of LOADOUTS (2-4), every slot used, a
    drive, quit. POKEs as in play: `$C1C6` = $3A (bank 6, no weight limit), `$C875` = $3A (bank 6, immunity)"""
    r.shot('title')
    for n, loadout in enumerate(LOADOUTS[1:], 2):
        mission_tape(r)
        load_mission(r, 1)
        r.poke(0xC1C6, [0x3A], 'no weight limit (.pok: 6 49606 58)', bank=6)
        fit(r, loadout)
        r.b.click(*STORES['start'], after=150)
        r.poke(0xC875, [0x3A], 'immunity (.pok: 8 51317 58, bank 6 paged in play)', bank=6)
        r.shot(f'l{n}-start')
        r.b.hold(['Q'], 60)
        for slot, name in loadout.items():
            use_slot(r, slot, name)
        r.b.hold(['Q', 'P'], 100)
        r.shot(f'l{n}-drive')
        quit_to_title(r, n)


def plan_death(r):
    """death: from the title (explore/loaded.szx): Blast Em Mission with the Turret, no POKE; the tank driven ahead
    and turned, the cannon fired, a screen every 200 frames, 60 rounds (about 12 000 frames)"""
    r.shot('title')
    mission_tape(r)
    load_mission(r, 1)
    fit(r, {1: 'Turret'})
    r.b.click(*STORES['start'], after=150)
    r.shot('start')
    k(r, '1', 10)
    for i in range(60):
        r.b.hold(['Q'] if i % 4 else ['Q', 'O'], 150)
        k(r, 'SPACE', 25)
        r.shot(f'drive-{i:02d}')
    r.b.wait(300)
    r.shot('end')


def plan_search(r):
    """search: from the title (explore/loaded.szx): the catalogue, Hostage Rescue (mission 3) marked, SEARCH three
    times from where the catalogue left the tape: each stops at the next mission header and lights that mission"""
    r.shot('title')
    mission_tape(r)
    r.b.click(60, MISSION_Y[2], after=20)
    r.shot('mission-3-marked')
    for i in range(1, 4):
        r.b.click(*CLIP['search'], after=20)
        r.tape_do('play')
        r.wait_tape(1, 30000, step=100)
        r.b.wait(30)
        r.shot(f'search-{i}')


def plan_m10(r):
    """m10: from the title (explore/loaded.szx): Ocean side 2, its catalogue, the tape wound to Grand Finale's header
    (mission 10), SEARCH, SELECT, a screen every 500 frames until the stores screen, then fitted, played, quit"""
    mission2_from(r, SIDE2, 'ocean', 200, n=10)
    for i in range(10):
        r.b.wait(500)
        r.shot(f'wait-{i}')
        if r.tape().get('state') != 'playing' and i >= 5:
            break
    play_mission(r, 10)


PLANS = {'c1': plan_c1, 'm10': plan_m10, 'search': plan_search, 'death': plan_death, 'play2': plan_play2, 'menu': plan_menu, 'controls': plan_controls, 'missions': plan_missions,
         'play': plan_play, 'm2ocean': plan_m2ocean, 'm2erbe': plan_m2erbe}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('plan')
    ap.add_argument('--work')
    ap.add_argument('--port-base', type=int, default=37310)
    ap.add_argument('--start')
    ap.add_argument('--keep', action='store_true', help='leave the instance running (session.json)')
    a = ap.parse_args()
    if a.plan == 'list':
        for k, f in PLANS.items():
            print(k, '-', (f.__doc__ or '').split('\n')[0])
        return
    work = os.path.abspath(a.work)
    os.makedirs(work, exist_ok=True)
    lab = Lab(a.port_base)
    lab.session_json(work)
    r = Run(lab, work)
    began = time.time()
    try:
        if a.start:
            lab.load(os.path.abspath(a.start))
        else:
            lab.save(os.path.join(work, 'power-on.szx'))
        lab.start_recording()
        lab.frame = 0
        r.b.t0 = 0
        PLANS[a.plan](r)
        lab.keys([])
        lab.save(os.path.join(work, 'end.szx'))
        rec = {'plan': a.plan, 'note': PLANS[a.plan].__doc__, 'start': a.start or 'power-on',
               'frames': lab.frame, 'moments': r.moments, 'mouse': r.b.mouse_log, 'tape': r.tape_log, 'pokes': r.pokes,
               'seconds': round(time.time() - began)}
        name = os.path.basename(work)
        os.makedirs(os.path.join(CASE, 'tests', 'inputs'), exist_ok=True)
        r.b.script(os.path.join(CASE, 'tests', 'inputs', f'{name}.txt'), start=0)
        s = lab.s
        built = s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 30000})
        st = s.call('analysis', {'action': 'status'}).text
        while ': running' in st:
            time.sleep(5)
            st = s.call('analysis', {'action': 'status'}).text
        rec['status'] = st.splitlines()[-3:]
        d = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        rec['ttd'] = (d.text or '').splitlines()[:2]
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        print(json.dumps({k: rec[k] for k in ('frames', 'status', 'ttd', 'seconds')}, indent=1))
    finally:
        if not a.keep:
            lab.close()


if __name__ == '__main__':
    main()
