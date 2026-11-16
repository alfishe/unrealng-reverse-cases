#!/usr/bin/env python3
"""ATV Simulator recordings: a fresh muted 48K (RAM zeroed, a Kempston card), the TTD recording started at power-on
(or after a start state is loaded), a plan of held keys played over emulated frames (one run_frames call a segment),
screens at named moments, then end.szx, session.ttd, l1.json, the input script of every key held
(tests/inputs/<name>.txt, frames from the recording's start) and record.json (the plan's note, the moments, the tape
actions, the POKEs).

    python3 tools/record.py PLAN --work work/stage1/rec/NAME [--port-base 37780] [--start STATE.szx]
    python3 tools/record.py list

The tape is the original (orig/ATVSimulator.tzx.zip, its TZX in work/media/). The game's loader at `$FFDC` calls the
ROM's LD-BYTES at `$0556`; the power-on recordings play the tape at signal speed (fast and turbo tape off), so every
edge of the load is in the recording.

The controls at power-on are KEMPSTON (KL KR KU KD KF: left, right, wheel up, wheel down, jump); CHOOSE CONTROL
picks KEYBOARD (player 1: S D F C Z) or KEMPSTON per player. The menu: ENTER moves the highlight down, SPACE uses
the line (the instructions' INSTRUCTIONS section). A POKE, where a plan uses one, is applied on the recording's machine
only, written in record.json and in the input script; the case's image is cut from c1, never from a recording with a
POKE.
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

TAPE = os.path.join(CASE, 'work', 'media', 'ATV Simulator.tzx')

CLOCK = 0xD6C9         # the clock, three ASCII digits (seconds tens, units, tenths); $EB53 adds 1 to the tenths
FUEL = 0xD77D          # the current player's fuel (31 at the start, less with distance); $D719 player 1's copy
POS = 0xD78E           # the current player's distance along the course, a word (8.8); $D72A player 1's copy
# The POKEs of ZXDB's .pok (address, the POKE's byte, the image's byte); the names are the .pok's
POKES = {
    'lives': (60250, 0x00, 0x01),      # "Infinite Lives": ADD A,$01 at $EB59 (the clock's tenths) becomes ADD A,0
    'fuel1': (49433, 0x51, 0xC0),      # "Infinite Fuel" (49433 = $C119)
    'time': (57318, 0xC9, 0x3E),       # "Infinite Time": RET at $DFE6
    'fuel2': (57276, 0xC9, 0xE6),      # "Infinite fuel": RET at $DFBC
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



def boot(r, signal=True):
    """Power-on to the end of the tape: LOAD "" typed, PLAY once; at signal speed (fast and turbo tape off) unless
    @p signal is False"""
    lab = r.lab
    for name in ('fast_tape', 'turbo_tape'):
        lab.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                  'body': {'value': not signal}}, ok=False)
    lab.s.call('load_software', {'path': TAPE, 'autostart': False, 'play': False}, ok=False)
    lab.mute()
    r.tape_log.append({'frame': lab.frame, 'action': 'insert', 'path': os.path.basename(TAPE)})
    r.wait(150)
    r.shot('rom')
    for k in ['J', 'SS+P', 'SS+P', 'ENTER']:
        r.tap(k, 3, 5)
    lab.post('/tape/play', {})
    r.tape_log.append({'frame': lab.frame, 'action': 'play'})
    shots = {3: 'basic', 10: 'loader', 30: 'screen-loading', 50: 'screen-loaded', 120: 'loading-code'}
    t = {}
    for k in range(200):
        r.wait(100)
        if k in shots:
            r.shot(shots[k])
        t = r.tape()
        if t.get('state') in ('ended', 'stopped', 'idle') and k > 5:
            break
    r.tape_log.append({'frame': lab.frame, 'action': t.get('state'), 'block': (t.get('position') or {}).get('block')})


MENU = {'start': 7, 'players': 9, 'control': 11}       # the menu lines' character rows
# The menu box is attribute $1F (paper 3, ink 7) with its pixels set, so it shows white; the highlighted line is $5E
# (bright, paper 3, ink 6), shown yellow


def menu_sel(r):
    rows = K.paper_rows(r.rd, 3, 5, 14, ink=6)
    return rows[0] if len(rows) == 1 else None


def to_menu(r, tries=60):
    """Waits for the menu (the highlight on one of its three lines)"""
    for _ in range(tries):
        if menu_sel(r) in MENU.values():
            return True
        r.wait(25)
    raise RuntimeError('no menu')


def menu_goto(r, line):
    for _ in range(6):
        if menu_sel(r) == MENU[line]:
            return
        r.tap('ENTER', 4, 25)
    raise RuntimeError(f'menu line {line} not reached')


def start_game(r):
    menu_goto(r, 'start')
    r.tap('SPACE', 4, 10)


def mount(r, run=40):
    """At the start line: run right to the ATV, jump on (fire), as the instructions say"""
    r.hold('KR', run)
    r.hold('KR+KF', 6)
    r.hold('KR', 30)


def ride(r, frames, name='ride', every=250, stop=None, pattern=None):
    """Holds right (accelerate) with a jump now and then for @p frames, a screen every @p every frames"""
    pattern = pattern or [('KR', 60), ('KR+KF', 6)]
    start, i = r.lab.frame, 0
    while r.lab.frame - start < frames:
        k, n = pattern[i % len(pattern)]
        i += 1
        before = r.lab.frame
        r.hold(k, n)
        if (r.lab.frame - start) // every != (before - start) // every:
            r.shot(f'{name}')
        if stop and stop():
            return True
    return False


def clock(r):
    return r.rd(CLOCK, 3).decode('latin1')


def plan_c1(r):
    """c1: power-on on a 48K, LOAD "", the tape at signal speed (BASIC, the loader at $FFDC, the screen and the game
    by the ROM's LD-BYTES), the title and credits, the menu, START with the power-on controls (KEMPSTON, one player);
    trail 1: run to the ATV, jump on, ride right with a jump every 66 frames until the run ends (time out, fuel or
    a crash), then the screens after"""
    boot(r)
    r.shot('loaded')
    r.save('loaded')
    to_menu(r)
    r.shot('menu')
    r.save('menu')
    start_game(r)
    r.shot('trail')
    r.wait(150)
    r.shot('start-line')
    r.save('play')
    mount(r)
    r.shot('mounted')
    ride(r, 6000, name='c1')
    for k in range(6):
        r.wait(250)
        r.shot(f'after-{k}')



def plan_menu(r):
    """menu: from c1's menu.szx (state frame 14657). ONE PLAYER -> TWO PLAYERS (SPACE on the line), CHOOSE CONTROL:
    PLAYER ONE, KEYBOARD, the key table (a redefinition: each key pressed is the next control's key; Q, A, O, P and M
    are given, then SPACE on EXIT), PLAYER TWO, KEYBOARD (its own table: H, J, K, M, B pressed, its defaults), saved as
    menu-two-kb.szx; then CHOOSE CONTROL again: player 1 KEMPSTON, player 2 SINCLAIR; the menu left idle 2500 frames"""
    to_menu(r)
    r.shot('menu')
    menu_goto(r, 'players')
    r.tap('SPACE', 4, 30)
    r.shot('two-players')
    menu_goto(r, 'control')
    r.tap('SPACE', 4, 30)
    r.shot('player-one')
    r.tap('SPACE', 4, 30)
    r.shot('keyboard-table')
    for k in ('Q', 'A', 'O', 'P', 'M'):
        r.tap(k, 4, 25)
        r.shot(f'table-{k}')
    r.tap('SPACE', 4, 30)
    r.shot('player-two')
    r.tap('SPACE', 4, 30)
    r.shot('p2-keyboard-table')
    for k in ('H', 'J', 'K', 'M', 'B'):
        r.tap(k, 4, 25)
    r.shot('p2-table-done')
    r.tap('SPACE', 4, 30)
    r.shot('p2-exit')
    r.wait(30)
    r.save('menu-two-kb')
    menu_goto(r, 'control')
    r.tap('SPACE', 4, 30)
    r.tap('ENTER', 4, 30)
    r.shot('p1-kempston')
    r.tap('SPACE', 4, 30)
    r.shot('p2-choice')
    r.tap('ENTER', 4, 30)
    r.shot('p2-sinclair')
    r.tap('SPACE', 4, 30)
    r.shot('p2-sinclair-chosen')
    r.wait(30)
    r.shot('menu-again')
    for i in range(10):
        r.wait(250)
        r.shot('idle')


def plan_kb(r):
    """kb: from menu-two-kb.szx (recording menu: two players, both on the keyboard; player 1 Q left, A right, O wheel
    up, P wheel down, M jump; player 2 H, J, K, M, B). START; both press right (A and J), jump on (M and B), ride with
    the wheel keys and jumps now and then, until the clock runs out; then the screens after"""
    to_menu(r)
    start_game(r)
    r.wait(150)
    r.shot('start')
    r.hold('A+J', 40)
    r.hold('A+J+M+B', 6)
    r.hold('A+J', 30)
    r.shot('mounted')
    for i in range(120):
        r.hold('A+J', 40)
        r.hold('A+J+O+K', 10)
        r.hold('A+J+P', 10)
        r.hold('A+J+M+B', 6)
        if i % 8 == 0:
            r.shot('ride')
        if r.lab.frame > 11000:
            break
    for i in range(10):
        r.wait(100)
        r.shot('after')


def replay(r, plan_path):
    """Replays a tools/autoride.py plan: its pokes, then each (keys, frames) segment as one hold"""
    import json
    p = json.load(open(plan_path))
    for addr, val in p['pokes']:
        r.lab.write(addr, bytes([val]))
        r.pokes.append({'frame': r.lab.frame, 'address': f'${addr:04X}', 'bytes': [val], 'why': 'autoride plan poke'})
    last_trail = None
    for n, (keys, frames) in enumerate(p['segments']):
        r.hold('+'.join(keys), frames)
        t = r.rd(0xD6BF)[0]
        if t != last_trail:
            r.shot(f'trail{t + 1}')
            last_trail = t
        elif n % 60 == 0:
            r.shot(f'trail{t + 1}-ride')
    r.shot('plan-end')


def plan_trails(r):
    """trails: from c1's menu.szx, the autoride bot's plan (work/stage1/ride/plan6b.json, no POKE): START with one
    player on Kempston, each trail ridden with the jumps and wheelies the bot found, as far as the plan goes; then the
    screens after it"""
    replay(r, os.path.join(CASE, 'work/stage1/ride/plan6b.json'))
    for i in range(12):
        r.wait(100)
        r.shot('after')


def ride_smart(r, frames, name='ride', every=300, pattern=None, stop=None):
    """Rides for @p frames: while mounted (the record's sprite frame `$D783` at `$40` or above) the @p pattern
    (default: right, a wheelie, wheel down, a jump: the pattern that took both riders of recording kb through trail
    1); on foot, back to the ATV (left when the crash threw the rider past x `$46`) and on it with fire"""
    pattern = pattern or [('KR', 40), ('KR+KU', 10), ('KR+KD', 10), ('KR+KF', 6)]
    start, i = r.lab.frame, 0
    while r.lab.frame - start < frames:
        before = r.lab.frame
        b = r.rd(0xD77D, 0x10)
        if b[6] >= 0x40:
            k, n = pattern[i % len(pattern)]
            i += 1
            r.hold(k, n)
        elif b[6] == 0x18:
            r.hold('', 7)
        elif b[8] > 0x46:
            r.hold('KL', 7)
        elif b[7] == 1:
            r.hold('KR', 2)
        elif b[8] < 0x30:
            r.hold('KR', 7)
        else:
            r.hold('KR+KF', 6)
        if (r.lab.frame - start) // every != (before - start) // every:
            r.shot(name)
        if stop and stop():
            return True
    return False


def plan_warp(r):
    """warp: from c1's menu.szx, START (one player, Kempston); on each trail, once mounted, 150 frames of riding,
    then the distance set by a POKE to 40 units before the finish (`$D6C0`, the word the trail setup puts there): the
    distance word at `$D78A` (the current player's record, `$D772` + `$18`) and at `$D726` (player 1's own record,
    `$D70E` + `$18`; the game copies the two records into each other every pass); ride_smart until the trail number
    `$D6BF` changes. Six trails and the loop back to trail 1 (max 30), then that trail ridden to its end"""
    to_menu(r)
    start_game(r)
    r.wait(150)
    for n in range(7):
        trail = r.rd(0xD6BF)[0]
        r.shot(f'trail{trail + 1}-name')
        if n:
            r.wait(400)         # the trail's name screen; the record still holds the last trail's values
        r.shot(f'trail{trail + 1}-start')
        ride_smart(r, 600, f'trail{trail + 1}', stop=lambda: r.rd(0xD783)[0] >= 0x40)
        ride_smart(r, 150, f'trail{trail + 1}')
        r.shot(f'trail{trail + 1}-ride')
        fin = int.from_bytes(r.rd(0xD6C0, 2), 'little')
        to = max(0, fin - 40)
        for addr in (0xD78A, 0xD726):
            r.lab.write(addr, to.to_bytes(2, 'little'))
            r.pokes.append({'frame': r.lab.frame, 'address': f'${addr:04X}', 'bytes': list(to.to_bytes(2, 'little')),
                            'why': f'trail {trail + 1}: distance to {to} (finish {fin} - 40)'})
        ride_smart(r, 2500, f'trail{trail + 1}-end', every=50, stop=lambda: r.rd(0xD6BF)[0] != trail)
        r.shot(f'trail{trail + 1}-done')
    ride_smart(r, 6000, 'loop', stop=lambda: K.paper_rows(r.rd, 3, 0, 8, ink=0) == [] and r.rd(0x5800)[0] == 0x12)
    name_entry(r)
    for i in range(8):
        r.wait(100)
        r.shot('after')


def name_entry(r):
    """The high-score name entry (a letter grid, the cursor on A): fire on A, right and fire on B, right and fire on
    C, then down three rows and right to the arrow, fire; a shot after each step"""
    r.shot('name-entry')
    r.tap('KF', 4, 20)
    for k in ('KR', 'KR'):
        r.tap(k, 4, 15)
        r.tap('KF', 4, 20)
    r.shot('name-abc')
    for k in ('KD', 'KD', 'KD', 'KR', 'KR', 'KR', 'KR'):
        r.tap(k, 4, 15)
    r.shot('name-arrow')
    r.tap('KF', 4, 30)
    r.shot('name-done')
    r.wait(200)
    r.shot('table')


def plan_trail1(r):
    """trail1: from c1's menu.szx, START (one player, Kempston), trail 1 with ride_smart until the trail changes,
    then trail 2 the same way, at most 9000 frames; then the screens after"""
    to_menu(r)
    start_game(r)
    r.wait(150)
    r.shot('start-line')
    ride_smart(r, 9000, 'ride')
    r.shot('end')
    for i in range(8):
        r.wait(100)
        r.shot('after')


def plan_fuel(r):
    """fuel: from c1's menu.szx, START (one player, Kempston), the clock stopped by the ZXDB POKE 60250,0 (`$EB5A`,
    the clock tick's increment; the .pok calls it infinite lives); ride_smart for 9000 frames with the fuel `$D77D`
    logged in the screen names, to see what an empty tank does"""
    to_menu(r)
    start_game(r)
    r.poke('lives')
    r.wait(150)
    last = None
    start = r.lab.frame
    while r.lab.frame - start < 9000:
        ride_smart(r, 140, 'ride', every=10 ** 6)
        f = r.rd(FUEL)[0]
        if f != last:
            r.shot(f'fuel-{f:02d}')
            last = f
    r.shot('end')


def plan_pokes(r):
    """pokes: from c1's menu.szx, START, all four ZXDB POKEs on (60250,0; 49433,81; 57318,201; 57276,201): what each
    changes is read from the screens and the fuel `$D77D` over 4000 frames of ride_smart"""
    to_menu(r)
    start_game(r)
    for name in ('lives', 'fuel1', 'time', 'fuel2'):
        r.poke(name)
    r.wait(150)
    start, last = r.lab.frame, None
    while r.lab.frame - start < 4000:
        ride_smart(r, 140, 'ride', every=10 ** 6)
        f = r.rd(FUEL)[0]
        if f != last:
            r.shot(f'fuel-{f:02d}')
            last = f
    r.shot('end')


def plan_empty(r):
    """empty: from c1's menu.szx, START (one player, Kempston), the clock stopped by the ZXDB POKE 60250,0; ride_smart
    for 400 frames (on the ATV), then the fuel's high byte `$D77D` POKEd to 5 (from $20 at the start: the tank all
    but empty) and ride_smart until the fuel is under $400 (UseFuel's test `$DFBC`, OutOfFuel `$DFE6`) and 1500
    frames more, a screen at each fuel step and every 150 frames after it ran out"""
    to_menu(r)
    start_game(r)
    r.poke('lives')
    r.wait(150)
    ride_smart(r, 400, 'ride', every=10 ** 6)
    r.lab.write(FUEL, bytes([5]))
    r.pokes.append({'frame': r.lab.frame, 'address': f'${FUEL:04X}', 'bytes': [5], 'why': 'fuel all but empty'})
    r.shot('fuel-05')
    start, last = r.lab.frame, 5
    while r.lab.frame - start < 6000 and r.rd(FUEL)[0] >= 4:
        ride_smart(r, 70, 'ride', every=10 ** 6)
        f = r.rd(FUEL)[0]
        if f != last:
            r.shot(f'fuel-{f:02d}')
            last = f
    r.shot('empty')
    ride_smart(r, 1500, 'after', every=150)
    r.shot('end')


PLANS = {'c1': plan_c1, 'menu': plan_menu, 'kb': plan_kb, 'trails': plan_trails, 'trail1': plan_trail1, 'warp': plan_warp, 'fuel': plan_fuel, 'pokes': plan_pokes, 'empty': plan_empty}

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
