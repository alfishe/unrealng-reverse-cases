#!/usr/bin/env python3
"""Enduro Racer recordings: a fresh muted machine (RAM zeroed, a Kempston card), the TTD recording started at
power-on (or after a start state is loaded), a plan of held keys played over emulated frames, screens at named
moments, then end.szx, session.ttd, l1.json, the input script of every key held (tests/inputs/<name>.txt, frames from
the recording's start) and record.json (the plan's note, the moments, the tape actions, the POKEs).

    python3 tools/record.py PLAN --work work/stage1/rec/NAME [--port-base 37780] [--model 48K] [--start STATE.szx]
    python3 tools/record.py list

The tape: the SpeedLock 2 loader reads its own blocks (no ROM LD-BYTES), so it is played at signal speed (fast and
turbo tape off). The recordings load `[SpeedLock 2].tzx` (TOSEC), whose data blocks are the original's byte for byte
(tools/media_compare.py): on the case binary (before unreal-ng f13cee7da) the original TZX's last block, which ends
the file with no pause, does not load and the machine resets.

The keys (the game's defaults, DEFINE KEYS): Q throttle, A wheelie, O left, P right, SPACE brakes, H pause, R reset.
The control mode at power-on is SINCLAIR LEFT; the plans pick KEYBOARD on the menu first (CHANGE CONTROL MODE).
The menu: SPACE (or fire) executes the highlighted line, any other key advances.

A POKE, where a plan uses one, is applied on the recording's machine only, written in record.json and in the input
script; the case's image is cut from c1, never from a recording with a POKE.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402
import kitlib as K  # noqa: E402  (lab put the kit on the path)

TAPE = os.path.join(CASE, 'work', 'candidates', 'tosec-2023',
                    'Enduro Racer (1987)(Activision)(48K-128K)[SpeedLock 2].tzx')
THR, WHL, LEFT, RIGHT, BRK, PAUSE, RESET = 'Q', 'A', 'O', 'P', 'SPACE', 'H', 'R'

TIME = 0x5E1F          # the stage timer, BCD (LD A,($5E1F) / DEC A / DAA at $AA7B)
STAGE = 0x5E23         # the stage, 0-4 (0, 1, 2 at stages-try1 frames 2222, 3788, 5354)
SPEED = 0x7C34         # the speed (the "keep speed" POKEs NOP the stores to it)
# The POKEs of ZXDB's Enduro Racer .pok (the address, the POKE's byte, the image's byte)
POKES = {
    'time': (43649, 0x3A, 0x32),       # Infinite Time: LD ($5E1F),A becomes LD A,($5E1F)
    'obstacles': (42971, 0x01, 0xCD),  # Immune To Obstacles
    'trucks': (43151, 0x01, 0xCD),     # Immune To Trucks
    'offroad': (41457, 0x3A, 0x32),    # Keep Speed Off Road
    'byobst': (43033, 0x3A, 0x32),     # Keep Speed By Obstacles
    'turns': (43622, 0x3A, 0x32),      # Keep Speed By Turns
    'bikes': (43177, 0x00, 0x77),      # Keep Speed By Motorbike Collisions
}


class Run:
    def __init__(self, lab, work):
        self.lab, self.work = lab, work
        self.moments, self.tape_log, self.pokes, self.keylog, self.states = [], [], [], [], []
        self.held = []
        self.start = None
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

    def save(self, name):
        self.lab.save(os.path.join(self.work, name + '.szx'))
        self.states.append({'frame': self.lab.frame, 'state': name + '.szx'})

    def tape(self):
        t = self.lab.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/tape'}, ok=False)
        return (t.structured or {}).get('body') or {}

    def poke(self, name, on=True):
        addr, new, old = POKES[name]
        v = new if on else old
        self.lab.write(addr, bytes([v]))
        self.pokes.append({'frame': self.lab.frame, 'address': f'${addr:04X}', 'bytes': [v],
                           'why': f'{name} {"on" if on else "off (the image byte back)"}'})

    def rd(self, addr, n=1):
        return self.lab.read(addr, n)

    def script(self, path, note):
        with open(path, 'w') as f:
            for line in (note or '').strip().splitlines():
                f.write('# ' + line.strip() + '\n')
            if self.start:
                f.write(f'# Start: {self.start}\n')
            lines = [(frame, f'{" ".join(keys) if keys else "-"}') for frame, keys in self.keylog]
            for p in self.pokes:
                lines.append((p['frame'], f'POKE {int(p["address"][1:], 16)} ' + ' '.join(map(str, p['bytes']))))
            for t in self.tape_log:
                if t['action'] == 'insert':
                    lines.append((t['frame'], f'TAPE INSERT {os.path.relpath(TAPE, CASE)}'))
                elif t['action'] == 'play':
                    lines.append((t['frame'], 'TAPE PLAY'))
            for frame, text in sorted(lines, key=lambda x: x[0]):
                f.write(f'{frame} {text}\n')
            f.write(f'{self.lab.frame} END\n')


def boot(r):
    """Power-on to the end of the tape: LOAD "" on a 48K (ENTER, the Tape Loader, on a 128K), PLAY once, the
    SpeedLock 2 load at signal speed until the tape ends"""
    lab = r.lab
    for name in ('fast_tape', 'turbo_tape'):
        lab.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                  'body': {'value': False}}, ok=False)
    lab.s.call('load_software', {'path': TAPE, 'autostart': False, 'play': False}, ok=False)
    lab.mute()
    r.tape_log.append({'frame': lab.frame, 'action': 'insert', 'path': os.path.basename(TAPE)})
    r.wait(150)
    r.shot('rom')
    for k in (['J', 'SS+P', 'SS+P', 'ENTER'] if lab.model == '48K' else ['ENTER']):
        r.tap(k, 3, 5)
    lab.post('/tape/play', {})
    r.tape_log.append({'frame': lab.frame, 'action': 'play'})
    shots = {3: 'basic', 25: 'screen-loading', 45: 'screen-loaded', 80: 'loading-code'}
    for k in range(120):
        r.wait(100)
        if k in shots:
            r.shot(shots[k])
        t = r.tape()
        if t.get('state') == 'ended':
            break
    r.tape_log.append({'frame': lab.frame, 'action': t.get('state'), 'block': (t.get('position') or {}).get('block')})


def credits(r, frames=1600):
    """The credits scroll and the attract race after the load, then a key gives the menu"""
    for k in range(frames // 200):
        r.wait(200)
        r.shot(f'attract-{k}')


MAIN = {'start': 7, 'players': 10, 'control': 12, 'define': 14}       # the menu lines' character rows
METHODS = {'keyboard': 12, 'kempston': 13, 'sinclair-right': 14, 'sinclair-left': 15, 'cursor': 16}
DEFINE = {'exit': 14, 'throttle': 15, 'wheelie': 16, 'left': 17, 'right': 18, 'brakes': 19, 'pause': 20,
          'reset': 21}


def paper_rows(r, paper, lo=4, hi=23, cells=3):
    """The character rows lo..hi with at least @p cells cells of paper @p paper (kitlib.paper_rows): the menu's
    highlight is blue paper (1), the popups' highlight red paper (2) on a blue box"""
    return K.paper_rows(r.rd, paper, lo, hi, cells)


def main_sel(r):
    """The highlighted main-menu line's row, or None when a popup is open or the menu is not shown"""
    if paper_rows(r, 2):
        return None
    rows = paper_rows(r, 1)
    return rows[0] if len(rows) == 1 and rows[0] in MAIN.values() else None


def to_menu(r, shot=True):
    """From the credits or the attract race: ENTER until the menu shows (the first presses can be ignored while
    the attract race runs)"""
    for _ in range(40):
        r.tap('ENTER', 4, 30)
        if main_sel(r) is not None:
            break
    if shot:
        r.shot('menu')


def menu_goto(r, line):
    for _ in range(8):
        if main_sel(r) == MAIN[line]:
            return
        r.tap('ENTER', 4, 25)
    raise RuntimeError(f'menu line {line} not reached')


def popup_goto(r, row):
    for _ in range(12):
        red = paper_rows(r, 2)
        if red and red[0] == row:
            return
        r.tap('ENTER', 4, 25)
    raise RuntimeError(f'popup row {row} not reached')


def pick_method(r, method, shots=False):
    """CHANGE CONTROL MODE, the popup cycled to @p method, SPACE"""
    menu_goto(r, 'control')
    r.tap(BRK, 4, 30)
    if shots:
        r.shot('control-popup')
        for k in range(5):
            r.tap('ENTER', 4, 25)
            r.shot(f'control-{k}')
    popup_goto(r, METHODS[method])
    if shots:
        r.shot(f'control-{method}')
    r.tap(BRK, 4, 30)


def menu_keyboard(r, shots=True):
    """From the menu: KEYBOARD picked, back on START GAME"""
    pick_method(r, 'keyboard', shots)
    menu_goto(r, 'start')


def start_game(r):
    menu_goto(r, 'start')
    r.tap(BRK, 4, 10)


def menu_tour(r):
    """Every menu line: ONE / TWO PLAYERS toggled twice, the control popup cycled through all five methods and
    KEYBOARD picked, DEFINE KEYS opened (the defaults shown) and EXIT; back to START GAME"""
    menu_goto(r, 'players')
    r.tap(BRK, 4, 30)
    r.shot('two-players')
    r.tap(BRK, 4, 30)
    r.shot('one-player')
    pick_method(r, 'keyboard', shots=True)
    menu_goto(r, 'define')
    r.tap(BRK, 4, 30)
    r.shot('define-keys')
    popup_goto(r, DEFINE['exit'])
    r.tap(BRK, 4, 30)
    menu_goto(r, 'start')
    r.shot('menu-start')


def drive(r, frames, pattern, name='play', every=400, stop=None):
    """Plays @p pattern ((keys, frames) pairs) in a loop for @p frames, a screen every @p every frames"""
    start, i = r.lab.frame, 0
    while r.lab.frame - start < frames:
        k, n = pattern[i % len(pattern)]
        i += 1
        before = r.lab.frame
        r.hold(k, n)
        if (r.lab.frame - start) // every != (before - start) // every:
            r.shot(f'{name}-{r.lab.frame}')
        if stop and stop():
            return True
    return False


WEAVE = [(THR, 40), (THR + '+' + LEFT, 12), (THR, 30), (THR + '+' + RIGHT, 12), (THR, 30), (THR + '+' + RIGHT, 10),
         (THR + '+' + LEFT, 10)]


def name_entry(r, letters):
    """The name entry grid: O / P left and right, Q / A up and down, SPACE takes the letter under the cursor.
    @p letters is a list of (column, row) on the 14 x 3 grid; the cursor starts at (0, 0). Ends with the END key
    (column 11, row 0)"""
    x, y = 0, 0
    for cx, cy in letters + [(11, 0)]:
        while x < cx:
            r.tap(RIGHT, 4, 12)
            x += 1
        while x > cx:
            r.tap(LEFT, 4, 12)
            x -= 1
        while y < cy:
            r.tap(WHL, 4, 12)
            y += 1
        while y > cy:
            r.tap(THR, 4, 12)
            y -= 1
        r.tap(BRK, 4, 20)
    r.shot('name-entered')


def plan_c1(r):
    """c1: power-on on a 48K, LOAD "", the tape at signal speed by its own SpeedLock 2 loader, the credits and the
    attract race, ENTER for the menu, every menu line toured (one / two players, the five control methods, KEYBOARD
    picked, DEFINE KEYS with the defaults), START GAME; stage 1 without POKEs: throttle, weaving left and right,
    a wheelie, brakes, pause and resume, then the weave until the timer runs out and the game ends"""
    boot(r)
    credits(r)
    r.save('loaded')
    to_menu(r)
    r.save('menu')
    menu_tour(r)
    r.save('menu-kb')
    start_game(r)
    r.shot('countdown')
    r.wait(120)
    r.shot('go')
    r.save('play')
    r.hold(THR, 300)
    r.shot('throttle')
    r.hold(THR + '+' + LEFT, 20)
    r.shot('left')
    r.hold(THR + '+' + RIGHT, 20)
    r.shot('right')
    r.hold(THR + '+' + WHL, 40)
    r.shot('wheelie')
    r.hold(THR, 60)
    r.hold(BRK, 40)
    r.shot('brakes')
    r.tap(PAUSE, 6, 60)
    r.shot('pause')
    r.tap(PAUSE, 6, 30)
    r.shot('resume')
    over = lambda: r.rd(TIME)[0] == 0
    drive(r, 9000, WEAVE, name='c1', stop=over)
    r.shot('time-up')
    for k in range(10):
        r.wait(200)
        r.shot(f'after-{k}')


def alive(r):
    """The game still runs: I is the game's $B2 (a reset leaves the ROM's $3F)"""
    return r.lab.regs()['special']['i'] == 0xB2


def plan_stages(r):
    """stages: from c1's menu (KEYBOARD picked), POKEs on the recording's machine: infinite time, immune to obstacles
    and trucks, speed kept off road, by obstacles, by turns and by bikes (ZXDB's .pok); START GAME, throttle held
    with a little weave through all five stages (a state saved when the HUD's stage digit changes), the lap-time
    table, the name entry (E N D, END), back to the menu. (The first take, `rec/stages-try1`, with 60-frame throttle
    runs, reset in stage 3 at frame 6714: see NOTES)"""
    for p in POKES:
        r.poke(p)
    start_game(r)
    r.wait(120)
    pat = [(THR, 50), (THR + '+' + LEFT, 6), (THR, 50), (THR + '+' + RIGHT, 6)]
    stage = r.rd(STAGE)[0]
    for _ in range(80):
        drive(r, 250, pat, name='stages', every=500)
        if not alive(r):
            r.shot('reset')
            raise RuntimeError(f'reset by frame {r.lab.frame}')
        if r.rd(STAGE)[0] != stage:
            stage = r.rd(STAGE)[0]
            r.shot(f'stage-{stage:02X}')
            r.save(f'stage-{stage:02X}')
        # the lap-time table: "TOTAL" on red paper at the left of character row 22
        if r.rd(0x5800 + 32 * 22, 32)[1] & 0x38 == 0x10:
            r.shot('table')
            break
    r.keys([])
    r.wait(150)
    r.shot('table-held')
    r.tap(BRK, 4, 100)
    r.shot('hiscore')
    name_entry(r, [(2, 0), (5, 1), (2, 1)])          # E N D
    for k in range(6):
        r.wait(200)
        r.shot(f'after-{k}')


def plan_gameover(r):
    """gameover: from c1's menu, POKEs speed kept and immune (no time POKE): the first stage is driven within the time
    at full speed; then the time POKE stays off and the weave goes on until the timer runs out: the score is on the
    table, the name entry (A B C), the menu"""
    for p in ('obstacles', 'trucks', 'offroad', 'byobst', 'turns', 'bikes'):
        r.poke(p)
    start_game(r)
    r.wait(120)
    over = lambda: r.rd(TIME)[0] == 0
    drive(r, 12000, [(THR, 60), (THR + '+' + LEFT, 6), (THR, 60), (THR + '+' + RIGHT, 6)], name='go', every=500,
          stop=over)
    r.keys([])
    r.shot('time-up')
    for k in range(8):
        r.wait(150)
        r.shot(f'over-{k}')
    r.tap(BRK, 4, 100)
    r.shot('after-key')
    name_entry(r, [(0, 1), (4, 2), (2, 2)])          # A B C
    for k in range(4):
        r.wait(200)
        r.shot(f'after-{k}')


def plan_ctl(r):
    """ctl: from c1's loaded state (control SINCLAIR LEFT, the power-on default): for each method the menu picks it,
    START GAME, the method's throttle, left, right, wheelie, brakes held in turn, then RESET (R) back to the menu.
    Kempston: up throttle, left, right, down wheelie, fire brakes; Sinclair right (keys 6-0: left right down up fire):
    9 throttle, 6 left, 7 right, 8 wheelie, 0 brakes; Sinclair left (keys 1-5: left right down up fire): 4 throttle,
    1 left, 2 right, 3 wheelie, 5 brakes; cursor (5 left, 8 right, 6 down, 7 up, 0 fire): 7 throttle, 5 left, 8 right,
    6 wheelie, 0 brakes (the joystick mappings are the guess this recording tests); last DEFINE KEYS: THROTTLE
    redefined to W and used"""
    to_menu(r)
    methods = [('sinclair-left', ['4', '1', '2', '3', '5']),
               ('kempston', ['KU', 'KL', 'KR', 'KD', 'KF']),
               ('sinclair-right', ['9', '6', '7', '8', '0']),
               ('cursor', ['7', '5', '8', '6', '0'])]
    for name, (thr, lf, rt, wh, br) in methods:
        pick_method(r, name)
        r.shot(f'{name}-picked')
        start_game(r)
        r.wait(120)
        sp0 = r.rd(SPEED)[0]
        r.hold(thr, 200)
        r.shot(f'{name}-throttle')
        r.hold(thr + '+' + lf, 25)
        r.shot(f'{name}-left')
        r.hold(thr + '+' + rt, 25)
        r.shot(f'{name}-right')
        r.hold(thr + '+' + wh, 30)
        r.shot(f'{name}-wheelie')
        sp1 = r.rd(SPEED)[0]
        r.hold(br, 40)
        r.shot(f'{name}-brakes')
        sp2 = r.rd(SPEED)[0]
        r.moments.append({'frame': r.lab.frame, 'name': f'{name}-speeds', 'speed': [sp0, sp1, sp2]})
        r.wait(10)
        r.tap(RESET, 6, 60)
        to_menu(r, shot=False)
        r.shot(f'{name}-reset')
    pick_method(r, 'keyboard')
    menu_goto(r, 'define')
    r.tap(BRK, 4, 30)
    r.shot('define-open')
    popup_goto(r, DEFINE['throttle'])
    r.tap(BRK, 4, 30)
    r.shot('define-wait')
    r.tap('W', 6, 40)
    r.shot('define-throttle-w')
    popup_goto(r, DEFINE['exit'])
    r.tap(BRK, 4, 30)
    start_game(r)
    r.wait(120)
    r.hold('W', 200)
    r.shot('keyboard-w-throttle')
    r.moments.append({'frame': r.lab.frame, 'name': 'w-speed', 'speed': [r.rd(SPEED)[0]]})
    r.hold('W+O', 25)
    r.hold('W+P', 25)
    r.tap(RESET, 6, 60)
    r.shot('keyboard-reset')


def plan_twoplayer(r):
    """twoplayer: from c1's menu (KEYBOARD picked), TWO PLAYERS, START GAME; each player's turn played with the weave
    and no POKE until its timer runs out, then the next turn; the end"""
    menu_goto(r, 'players')
    r.tap(BRK, 4, 30)
    r.shot('two-players')
    start_game(r)
    r.wait(120)
    for turn in range(2):
        drive(r, 9000, WEAVE, name=f'p{turn + 1}', every=500, stop=lambda: r.rd(TIME)[0] == 0)
        r.keys([])
        r.shot(f'p{turn + 1}-time-up')
        for k in range(6):
            r.wait(150)
            r.shot(f'p{turn + 1}-after-{k}')
        if main_sel(r) is not None:
            break
        r.tap(BRK, 4, 30)
        r.wait(150)
    for k in range(4):
        r.wait(200)
        r.shot(f'end-{k}')


def plan_crash(r):
    """crash: from c1's play start (KEYBOARD, the countdown over), no POKE: throttle held and steered hard to one
    side into the roadside, then the other, then into riders ahead; the falls and the restarts"""
    for k in range(6):
        r.hold(THR, 200)
        r.hold(THR + '+' + (LEFT if k % 2 else RIGHT), 120)
        r.shot(f'side-{k}')
        r.hold(THR, 100)
        r.shot(f'after-{k}')
    drive(r, 2000, [(THR, 100), (THR + '+' + WHL, 40)], name='wheelie', every=400)


def plan_m128(r):
    """m128: power-on on a 128K, the 128 menu's Tape Loader (ENTER), the tape at signal speed; the credits, the attract
    race, the menu, KEYBOARD, START GAME, stage 1 driven for a while: what a 128K does differently (sound, paging)"""
    boot(r)
    credits(r)
    r.save('loaded')
    to_menu(r)
    menu_keyboard(r)
    start_game(r)
    r.wait(120)
    r.shot('go')
    drive(r, 3000, WEAVE, name='m128', every=500)


# ---- the integration's recordings: each starts from a state an earlier recording saved and plays that recording's
# own input script from the state's frame (the same machine, the same keys), with one change named in the plan.
FALL_TIME = 0x916E     # nonzero while the bike lies after a fall
CHEAT_STEP = 0xA670    # CheatStep: $FF while the cheat's fixed step is on


def script_keys(name):
    """[(frame, keys)] of tests/inputs/NAME.txt (frames from that recording's start)"""
    ev = []
    for line in open(os.path.join(CASE, 'tests', 'inputs', name + '.txt')):
        w = line.split()
        if not w or w[0] == '#' or w[1] in ('POKE', 'TAPE'):
            continue
        if w[1] == 'END':
            break
        ev.append((int(w[0]), [] if w[1] == '-' else w[1:]))
    return ev


def replay(r, name, f0, f1, change=None, stop=None):
    """Play tests/inputs/NAME.txt's keys from its frame f0 (the start state's) to f1; change(f, keys) may replace the
    keys of a frame; stop() ends early. Returns the script frame reached."""
    ev = script_keys(name)
    f = f0
    while f < f1:
        held = []
        for e, k in ev:
            if e > f:
                break
            held = k
        if change:
            held = change(f, held)
        r.keys(held)
        r.lab.run(1)
        f += 1
        if stop and stop():
            break
    return f


def after_fall(r, more=300):
    """a stop() that ends a replay MORE frames after the first fall"""
    seen = {}

    def stop():
        if 'f' not in seen and r.rd(FALL_TIME)[0]:
            seen['f'] = r.lab.frame
            r.shot('fall')
        return 'f' in seen and r.lab.frame - seen['f'] >= more
    return stop


def plan_truck(r):
    """truck: stages' state at stage 3's start (work/stage1/rec/stages/stage-02.szx, stages frame 5340), the Immune To
    Trucks POKE taken back (43151 = $CD, the image's CALL TruckCrash; the other POKEs stay, as in stages); stages' own
    keys from frame 5340: the first head-on truck now calls Crash (TruckCrash); 300 frames after the fall"""
    r.poke('trucks', on=False)
    replay(r, 'stages', 5340, 7806, stop=after_fall(r))
    r.shot('end')


def plan_fall5(r):
    """fall5: stages' state at stage 5's start (work/stage1/rec/stages/stage-04.szx, stages frame 10272), the Immune To
    Obstacles and Immune To Trucks POKEs taken back (42971 and 43151 = $CD; the speed POKEs stay); stages' own keys
    from frame 10272: the first object hit at speed is a fall on stage 5's sand; 300 frames after it"""
    r.poke('obstacles', on=False)
    r.poke('trucks', on=False)
    replay(r, 'stages', 10272, 13012, stop=after_fall(r))
    r.shot('end')


def plan_names(r):
    """names: c1's play start (work/stage1/rec/c1/play.szx, c1 frame 14075, KEYBOARD, no POKE in the game), two POKEs on
    this recording's machine: Score ($5E18) = " 300000" and Timer ($5E1F) = $01, so the race ends at once with a score
    for the table; no key: the bike stays, the timer runs out, game over, the lap table (ENTER), the name entry: LEFT
    at the first column (the wrap to the last), 9 taken, RIGHT at the last column (the wrap to the first), = (the
    delete), E, R, ? (END); back to the menu"""
    r.lab.write(0x5E18, b' 300000')
    r.pokes.append({'frame': r.lab.frame, 'address': '$5E18', 'bytes': list(b' 300000'), 'why': 'score 300 000'})
    r.lab.write(TIME, bytes([1]))
    r.pokes.append({'frame': r.lab.frame, 'address': '$5E1F', 'bytes': [1], 'why': 'timer 1'})
    r.wait(10)
    r.shot('start')
    for _ in range(40):
        r.wait(50)
        if r.rd(0x5800 + 32 * 22, 32)[1] & 0x38 == 0x10:
            break
    r.shot('table')
    r.wait(150)
    r.tap('ENTER', 4, 100)
    r.shot('hiscore')

    def cursor():
        line, col = r.rd(0x83EB, 2)          # DrawCursor's LD BC operand: C the line, B the column
        return (col - 1) // 2, (line - 0x90) // 16

    def move(key, want):
        """tap KEY until the cursor's grid column is WANT (a tap at a time, the cursor read back)"""
        for _ in range(40):
            if cursor()[0] == want:
                return
            r.tap(key, 3, 16)
        raise RuntimeError(f'cursor {cursor()} not at column {want}')

    def pick():
        before = r.rd(0x8A1B)[0]                # NamePlace's B: the name's column
        for _ in range(4):
            r.tap(BRK, 3, 30)
            if r.rd(0x8A1B)[0] != before or r.rd(0x8A1B)[0] == 0:
                return
        raise RuntimeError('no pick')

    move(LEFT, 14)                              # LEFT at column 0: NameLeftWrap
    r.shot('left-wrap')
    pick()                                      # 9
    move(RIGHT, 0)                              # RIGHT at column 14: NameRightWrap
    r.shot('right-wrap')
    move(RIGHT, 10)
    pick()                                      # = : NameDelete, NameSpace
    r.shot('deleted')
    move(LEFT, 2)
    pick()                                      # E
    move(RIGHT, 3)
    pick()                                      # R
    r.shot('name-er')
    move(RIGHT, 11)
    r.tap(BRK, 3, 30)                           # ? : END
    r.shot('name-entered')
    for k in range(3):
        r.wait(200)
        r.shot(f'after-{k}')


TECH = {  # doc 10's technique runs (tools/play_techniques.py RUNS) as recordings: c1 frames
    'ramp-wheelie': (15700, [(15380, 15500, ['Q', 'A'])], None),
    'land-wheelie': (15700, [(15600, 15640, ['Q', 'A'])], None),
    'brake-bend': (15320, [(15130, 15170, ['SPACE'])], None),
    'cheat': (14700, [], 14200),
}


def tech(r, run):
    end, change, cheat = TECH[run]
    state = {'cheat': cheat}

    def keys(f, held):
        for c0, c1, k in change:
            if c0 <= f < c1:
                held = k
        if state['cheat'] is not None and f >= state['cheat']:
            if r.rd(CHEAT_STEP)[0] != 0xFF:
                return ['CS', 'Q']
            state['cheat'] = None
        return held
    replay(r, 'c1', 14075, end, change=keys)
    r.shot('end')


def plan_tech_ramp_wheelie(r):
    """tech-ramp-wheelie: c1's play start (play.szx, c1 frame 14075) and c1's keys, but THROTTLE + WHEELIE held from c1
    frame 15380 to 15500: a wheelie into the ramp at 15487 (doc 10's run ramp-wheelie); to c1 frame 15700"""
    tech(r, 'ramp-wheelie')


def plan_tech_land_wheelie(r):
    """tech-land-wheelie: c1's play start and keys, but THROTTLE + WHEELIE from c1 frame 15600 to 15640: a wheelie at the
    landing (doc 10's run land-wheelie); to c1 frame 15700"""
    tech(r, 'land-wheelie')


def plan_tech_brake_bend(r):
    """tech-brake-bend: c1's play start and keys, but BRAKES instead of THROTTLE from c1 frame 15130 to 15170 (doc 10's
    run brake-bend); to c1 frame 15320"""
    tech(r, 'brake-bend')


def plan_tech_cheat(r):
    """tech-cheat: c1's play start and keys, CAPS SHIFT + Q held from c1 frame 14200 until CheatStep reads $FF, then
    c1's keys (doc 10's run cheat); to c1 frame 14700"""
    tech(r, 'cheat')


PLANS = {k[5:].replace('_', '-'): v for k, v in globals().items() if k.startswith('plan_')}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('plan')
    ap.add_argument('--work')
    ap.add_argument('--port-base', type=int, default=37780)
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
    r.start = os.path.relpath(os.path.abspath(a.start), CASE) if a.start else None
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
               'frames': lab.frame, 'moments': r.moments, 'states': r.states, 'tape': r.tape_log, 'pokes': r.pokes,
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
