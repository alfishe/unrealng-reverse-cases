#!/usr/bin/env python3
"""R-Type recordings: a fresh muted machine (RAM zeroed, a Kempston card), the TTD recording started at power-on (or
after a start state is loaded), a plan of held keys played over emulated frames, screens at named moments, then
end.szx, l1.json, session.ttd, the input script of every key held (tests/inputs/<name>.txt, frames from the
recording's start) and record.json (the plan's note, the moments, the tape actions, the POKEs).

    python3 tools/record.py PLAN --work work/stage1/rec/NAME [--port-base 37780] [--start STATE.szx|.z80]
    python3 tools/record.py list

The tape is played at signal speed (fast and turbo tape off): the loader is SpeedLock 7, no ROM LD-BYTES, and the
level loader `$FE03` reads its own turbo blocks. The TZX stops the tape before each level (ID 20 with a pause of 0);
unreal-ng's tape plays on by itself when a loader listens, so a level load needs no PLAY.

The keys: the game has no default keyboard set; c1 defines them with ENTER on the title: O left, P right, Q up,
A down, M fire, N detach (the Force). A POKE, where a plan uses one, is applied on the recording's machine only,
written in record.json and in the plan's note; the image of the case is cut from c1 (case.json), never from a
recording with a POKE.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402

TAPE = os.path.join(CASE, 'work', 'stage1', 'media', 'rtype.tzx')
L, R, U, D, F, X = 'O', 'P', 'Q', 'A', 'M', 'N'


class Run:
    def __init__(self, lab, work):
        self.lab, self.work = lab, work
        self.moments, self.tape_log, self.pokes, self.keylog = [], [], [], []
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

    def poke(self, addr, data, why):
        self.lab.write(addr, bytes(data))
        self.pokes.append({'frame': self.lab.frame, 'address': f'${addr:04X}', 'bytes': list(data), 'why': why})

    def script(self, path, note):
        with open(path, 'w') as f:
            for line in (note or '').strip().splitlines():
                f.write('# ' + line.strip() + '\n')
            if self.start:
                f.write(f'# Start: {self.start}\n')
            lines = [(frame, f'{" ".join(keys) if keys else "-"}') for frame, keys in self.keylog]
            for t in self.tape_log:
                if t['action'] == 'insert+seek':
                    lines.append((t['frame'], f'TAPE rtype.tzx {t["block"]}'))
            for p in self.pokes:
                lines.append((p['frame'], f'POKE {int(p["address"][1:], 16)} ' + ' '.join(map(str, p['bytes']))))
            for frame, text in sorted(lines, key=lambda x: x[0]):
                f.write(f'{frame} {text}\n')
            f.write(f'{self.lab.frame} END\n')


LEVEL = 0x719C        # the level digit in "R TYPE LEVEL n" (ASCII '0'-'9'), the level loader's counter
LIVES = 0x7AA0
DEATH = 0x91F2        # the life-lost path (the POKE file's "absolute invincibility" puts RET here)


def level(r):
    return r.lab.read(LEVEL, 1)[0] - 0x30


def bottom_text(r):
    """True when the screen's last character row holds pixels in magenta ink (the key prompts print there)"""
    attrs = r.lab.read(0x5AE0, 32)
    return any(r.lab.read(0x50E0 + 256 * k, 32)[c] and attrs[c] & 7 == 3 for k in range(8) for c in range(32))


def boot(r, keys=('J', 'SS+P', 'SS+P', 'ENTER')):
    """Power-on to "REWIND SIDE 2 THEN PRESS ANY KEY": LOAD "" on a 48K (keys: ENTER for the 128K menu's Tape Loader), PLAY once, the SpeedLock part at signal
    speed until the tape stops at the stop block before level 1 (the emulator's block 32)"""
    lab = r.lab
    for name in ('fast_tape', 'turbo_tape'):
        lab.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                  'body': {'value': False}}, ok=False)
    lab.s.call('load_software', {'path': TAPE, 'autostart': False, 'play': False}, ok=False)
    lab.mute()
    r.tape_log.append({'frame': lab.frame, 'action': 'insert', 'path': 'rtype.tzx'})
    r.wait(200)
    r.shot('rom')
    for k in keys:
        r.tap(k, 3, 5)
    r.tape_play()
    block = 0
    for k in range(80):
        r.wait(250)
        if k in (6, 20, 32, 40):
            r.shot(f'loading-{k}')
        t = r.tape()
        block = (t.get('position') or {}).get('block') or 0
        if t.get('state') != 'playing' and block >= 32:
            break
    r.tape_log.append({'frame': lab.frame, 'action': 'stopped', 'block': block})
    r.wait(50)
    r.shot('rewind')


def load_level1(r):
    """After the main load the scroller runs on (STOP THE TAPE !) until REWIND SIDE 2 THEN PRESS ANY KEY shows on the
    last row (magenta); a key there starts the level loader `$FE03` for level 1, and the tape, paused at its stop
    block, plays on by itself when the loader listens. No key is pressed while the tape plays (a key held during a
    level load gives ERROR IN LOADING). When the tape stops after level 1, STOP TAPE THEN PRESS ANY KEY: a key gives
    the title"""
    seen, asked = False, False
    for _ in range(600):
        r.wait(50)
        t = r.tape()
        block = (t.get('position') or {}).get('block') or 0
        if t.get('state') == 'playing':
            if not seen:
                seen = True
                r.tape_log.append({'frame': r.lab.frame, 'action': 'playing', 'block': block})
                r.shot('loading-level1')
        elif seen and block >= 35:
            break
        elif not seen and bottom_text(r):
            if not asked:
                r.shot('rewind-side2')
                asked = True
            r.tap('SPACE', 4, 20)
    r.tape_log.append({'frame': r.lab.frame, 'action': 'stopped', 'block': block})
    r.wait(20)
    r.shot('level1-loaded')
    for _ in range(20):                # STOP TAPE THEN PRESS ANY KEY (magenta, the last row) until the title shows
        r.tap('SPACE', 10, 40)
        if not bottom_text(r):
            break


def define_keys(r):
    """ENTER on the title (held until the first prompt shows on the last row), then O P Q A M N for LEFT RIGHT UP
    DOWN FIRE DETACH"""
    for _ in range(40):
        r.hold('ENTER', 10)
        r.wait(30)
        if bottom_text(r):
            break
    r.shot('define-left')
    for k in (L, R, U, D, F, X):
        r.tap(k, 6, 40)
    r.shot('defined')


def autopilot(r, frames, stop=None, every=500, name='play'):
    """Fire held in bursts while the ship weaves up and down and a little left and right; no key while the tape
    plays (a key held during a level load gives ERROR IN LOADING: stage 1's first chain); a key at every tape stop
    (STOP TAPE THEN PRESS ANY KEY). Ends after @p frames or when @p stop() is true"""
    pat = [(F + '+' + U, 12), ('', 3), (F + '+' + D, 12), ('', 3), (F + '+' + R, 6), (F + '+' + L, 6), ('', 3)]
    start, i = r.lab.frame, 0
    while r.lab.frame - start < frames:
        k, n = pat[i % len(pat)]
        i += 1
        if r.tape().get('state') == 'playing':
            k, n = '', 25
        before = r.lab.frame
        r.hold(k, n)
        if r.tape().get('state') == 'paused':
            r.tap(F, 4, 10)
        if (r.lab.frame - start) // every != (before - start) // every:
            r.shot(f'{name}-L{level(r)}')
        if stop and stop():
            return True
    return False


def plan_c1(r):
    """c1: power-on on a 48K, LOAD "", the original tape at signal speed by its own loaders (SpeedLock 7, then the
    level loader for level 1), STOP TAPE and a key, the title cycle, ENTER and the keys defined (O P Q A M N), FIRE
    (M) starts the game; level 1 played without POKEs: moves, fire, a charged beam, the Force detached and called
    back, pause (CAPS SHIFT+1) and resume (CAPS SHIFT+2), then the autopilot until a life is lost and some more"""
    boot(r)
    load_level1(r)
    for k in range(6):
        r.wait(150)
        r.shot(f'title-{k}')
    r.lab.save(os.path.join(r.work, 'menu.szx'))
    define_keys(r)
    r.lab.save(os.path.join(r.work, 'defined.szx'))
    r.wait(100)
    r.tap(F, 8, 60)
    r.shot('play-start')
    r.lab.save(os.path.join(r.work, 'play.szx'))
    for spec, n in ((R, 40), (U, 30), (D, 30), (L, 30), (F, 4), ('', 20), (F, 4), ('', 20)):
        r.hold(spec, n)
    r.hold(F, 120)
    r.shot('beam-charged')
    r.hold('', 30)
    r.shot('beam-fired')
    r.tap(X, 6, 40)
    r.shot('detach')
    r.tap(X, 6, 40)
    r.tap('CS+1', 6, 50)
    r.shot('pause')
    r.tap('CS+2', 6, 30)
    r.shot('resume')
    lives = r.lab.read(LIVES, 1)[0]
    autopilot(r, 3000, stop=lambda: r.lab.read(LIVES, 1)[0] < lives, name='c1')
    r.shot('life-lost')
    autopilot(r, 600, name='c1-after')


def tape_at(r, block):
    """A state saved in another run holds no tape: the original goes in again, wound to emulator block @p block (the
    stop block before the level the loader will ask for) and left paused there, as a user leaves it"""
    r.lab.insert_tape(TAPE, play=False)
    r.lab.run(2)                       # the tape is parsed after the load call returns
    r.lab.post('/tape/seek', {'block': block})
    r.lab.post('/tape/play', {})
    r.lab.post('/tape/pause', {})
    t = r.tape()
    r.tape_log.append({'frame': r.lab.frame, 'action': 'insert+seek', 'path': 'rtype.tzx', 'block': block,
                       'state': t.get('state'), 'at': (t.get('position') or {}).get('block')})


def plan_level(r):
    """lN: from STATE (the moment the level digit `$719C` became N: the level loader about to read level N, or c1's
    play start for level 1; TAPE_BLOCK=35 then), the tape wound to the stop block before that level, POKE `$91F2` = `$C9` (RET at the life-lost path: the POKE file's absolute
    invincibility; the recording's machine only), the autopilot (fire in bursts, weaving) through the load, the
    level and its boss, until the digit steps to N+1 (the next level's load begins) and 300 frames more; next.szx is
    saved at that step for the next level's recording"""
    n0 = level(r)
    tape_at(r, int(os.environ.get('TAPE_BLOCK', str(32 + 3 * (n0 - 1)))))
    r.poke(DEATH, [0xC9], 'RET at the life-lost path $91F2: no life is lost (to reach the level end)')
    r.shot(f'start-L{n0}')
    cap = int(os.environ.get('FRAMES', '24000'))
    done = autopilot(r, cap, stop=lambda: level(r) != n0, name='play')
    if done:
        r.lab.save(os.path.join(r.work, 'next.szx'))
        r.shot(f'next-L{level(r)}')
        autopilot(r, 300, name='after')


METHODS = {   # LEFT RIGHT DOWN UP FIRE per control method ($C011 picks the method whose fire is pressed on the title)
    'if2': ('1', '2', '3', '4', '5'),          # keys 1-5, port $F7FE ($8B0A): method 1
    'kempston': ('KL', 'KR', 'KD', 'KU', 'KF'),  # port $1F ($8B19): method 3, offered when $73EC saw a quiet port
    'sinclair': ('6', '7', '8', '9', '0'),     # keys 6-0, port $EFFE ($8B2D): method 4
}
METHOD = 0x74FB       # the control method (1-4), the reader's vector at $74FC from the table at $778C


def plan_ctl(r):
    """ctl-METHOD: from c1's title (menu.szx), the game started with the fire of METHOD (if2: keys 1-5, kempston:
    the Kempston joystick, sinclair: keys 6-0), the method byte `$74FB` read, then each direction, fire, a charged
    beam and SPACE (the Force's detach with a joystick) with that method only; no POKE"""
    m = os.environ.get('METHOD', 'kempston')
    lf, rt, dn, up, fi = METHODS[m]
    r.wait(50)
    r.tap(fi, 8, 60)
    r.shot(f'start-{m}-method{r.lab.read(METHOD, 1)[0]}')
    for spec, n in ((rt, 40), (up, 30), (dn, 30), (lf, 30), (fi, 4), ('', 20), (fi, 4), ('', 20)):
        r.hold(spec, n)
    r.shot(f'moved-{m}')
    r.hold(fi, 120)
    r.shot('beam-charged')
    r.hold('', 30)
    r.shot('beam-fired')
    r.tap('SPACE', 6, 40)
    r.shot('detach')
    r.tap('SPACE', 6, 40)
    r.hold(rt + '+' + fi, 60)
    r.hold(up + '+' + fi, 30)
    r.hold(dn + '+' + fi, 30)
    r.wait(100)
    r.shot(f'end-method{r.lab.read(METHOD, 1)[0]}')


def plan_gameover(r):
    """gameover: from c1's play start (play.szx, level 1, five lives), no POKE: the autopilot until every life is
    lost (MISSION OVER, the CONTINUE count-down), no key there so it runs out; then whatever follows (the high score
    entry, the title) with screens every 50 frames; a name typed (AGENT, ENTER) if the game asks for one"""
    autopilot(r, 20000, stop=lambda: r.lab.read(LIVES, 1)[0] == 0, every=1000, name='play')
    r.shot('last-life')
    for k in range(80):
        r.wait(50)
        r.shot(f'over-{k:02d}')
        if bottom_text(r) and k > 40:
            break
    for c in ('A', 'G', 'E', 'N', 'T', 'ENTER'):
        r.tap(c, 4, 20)
    for k in range(12):
        r.wait(100)
        r.shot(f'after-{k:02d}')


def plan_continue(r):
    """continue: from c1's play start, no POKE: the autopilot until the lives run out, FIRE at the CONTINUE screen
    (a credit spent, `$72CB`), play on 1500 frames"""
    autopilot(r, 20000, stop=lambda: r.lab.read(LIVES, 1)[0] == 0, every=1000, name='play')
    r.shot('last-life')
    credits = r.lab.read(0x72CB, 1)[0]
    for k in range(60):
        r.wait(25)
        if k % 4 == 0:
            r.shot(f'over-{k:02d}')
        if r.lab.read(0x72CB, 1)[0] != credits or r.lab.read(LIVES, 1)[0]:
            break
        r.tap(F, 4, 10)
    r.shot(f'continued-credits-{chr(r.lab.read(0x72CB, 1)[0])}')
    autopilot(r, 1500, every=500, name='after')


def plan_ending(r):
    """ending: from l8's next.szx (level 8's boss dead, the level digit `$719C` just stepped to '9'), POKE `$91F2` =
    `$C9` as in l8, the autopilot with screens every 50 frames until the digit is '1' again and the level loader
    searches the tape for level 1 (which is not there after level 8: the tape is at its end)"""
    r.poke(DEATH, [0xC9], 'RET at the life-lost path $91F2, as in l8')
    r.shot(f'start-L{level(r)}')
    for k in range(120):
        autopilot(r, 50, every=10**6)
        r.shot(f'end-{k:03d}-L{chr(r.lab.read(LEVEL, 1)[0])}')
        if level(r) == 1:
            break
    autopilot(r, 500, every=100, name='search')



def plan_deaths(r):
    """deaths: from STATE (a level's start, as plan level), the tape wound as plan level does, no POKE: the autopilot
    until every life is lost or FRAMES (default 12000) run out, screens every 250 frames; the ways the ship dies
    are counted from the recording's branches at $956D (scenery ahead), $9574 (a cell of an enemy) and the runs at
    $C3CE (an enemy shot)"""
    n0 = level(r)
    if r.lab.read(DEATH, 1)[0] != 0xCD:   # the stage 1 level states carry their recording's RET there
        r.poke(DEATH, [0xCD], 'the original CALL byte back at $91F2: undoes the immortality POKE the start state holds')
    tape_at(r, int(os.environ.get('TAPE_BLOCK', str(32 + 3 * (n0 - 1)))))
    r.shot(f'start-L{n0}')
    autopilot(r, int(os.environ.get('FRAMES', '12000')), stop=lambda: r.lab.read(LIVES, 1)[0] == 0, every=250,
              name='play')
    r.shot(f'end-L{level(r)}-lives{r.lab.read(LIVES, 1)[0]}')


SCORE = 0x71C9        # the score, six ASCII digits ('053300' in l2's next.szx)


def plan_hiscore(r):
    """hiscore: from c1's play start, POKE the score `$71C9` = "045000" (six ASCII digits; recording hiscore only,
    so that the game over reaches the table: its 9th entry is 010000), the autopilot until every life is lost, no
    key at CONTINUE, then ENTER YOUR NAME PILOT: the keys NAME_KEYS (default A G E N T ENTER) one by one, a screen after
    each, then the table and the title"""
    r.poke(SCORE, list(b'045000'), 'the score set to 045000 so that the game over enters the best pilots table')
    autopilot(r, 20000, stop=lambda: r.lab.read(LIVES, 1)[0] == 0, every=1000, name='play')
    r.shot('last-life')
    for k in range(int(os.environ.get('NAME_AT', '1000')) // 25):   # MISSION OVER, CONTINUE 9 to 0, the prompt
        r.wait(25)
        r.shot(f'over-{k:02d}')
    r.shot('name-prompt')
    for i, c in enumerate(os.environ.get('NAME_KEYS', 'A G E N T ENTER').split()):
        r.tap(c, 6, 30)
        r.shot(f'name-{i:02d}-{c}')
    for k in range(16):
        r.wait(100)
        r.shot(f'after-{k:02d}')


def plan_m128(r):
    """m128 (run with --model 128k): power-on on a 128K, the menu's Tape Loader (ENTER), the original tape as in c1, the
    title, the keys defined, FIRE, the autopilot for PLAY frames (default 1500); the ROM's first bytes at the title and at
    the end show which ROM the tail's `OUT ($7FFD),$30` left paged in"""
    boot(r, keys=('ENTER',))
    load_level1(r)
    r.wait(300)
    r.shot('title')
    r.moments.append({'frame': r.lab.frame, 'name': 'rom-0000', 'bytes': r.lab.read(0, 8).hex()})
    define_keys(r)
    r.wait(100)
    r.tap(F, 8, 60)
    r.shot('play-start')
    autopilot(r, int(os.environ.get('PLAY', '1500')), every=500, name='play')
    r.moments.append({'frame': r.lab.frame, 'name': 'rom-0000', 'bytes': r.lab.read(0, 8).hex()})


FORCE_LEVEL, FORCE_ATTACHED, FORCE_RECORD = 0x7ABE, 0x7AA3, 0x7AA8
MAP_COLUMN, RESTART_COLUMN, SHIELD = 0x7A84, 0xC4AE, 0x7A98
SLOTS = 0x8501        # EnemySlots: 28 records of 9 bytes (+0 flags: bits 0-5 hits left; +5 movers: low nibble mover A)


def force_state(r):
    n = r.lab.read(FORCE_LEVEL, 1)[0]
    return r.lab.read(FORCE_RECORD + 3 * (n - 1), 1)[0] if n else 0


def note(r, name, **values):
    r.moments.append({'frame': r.lab.frame, 'name': name, **values})


def replay(r, name, until, stop=None):
    """The key changes of tests/inputs/NAME.txt (a recording made from the same start state) up to frame @p until, so
    that the run follows that recording exactly; its TAPE and POKE lines are the caller's (as the plan did them)"""
    steps = []
    for line in open(os.path.join(CASE, 'tests', 'inputs', f'{name}.txt')):
        parts = line.split()
        if not parts or line.startswith('#') or parts[1] in ('TAPE', 'POKE', 'END'):
            continue
        steps.append((int(parts[0]), [] if parts[1] == '-' else parts[1:]))
    for frame, keys in steps:
        if frame >= until:
            break
        if frame > r.lab.frame:
            r.lab.run(frame - r.lab.frame)
        r.keys(keys)
        if stop and stop():
            return True
    if until > r.lab.frame:
        r.lab.run(until - r.lab.frame)


def plan_force(r):
    """force: from c1's play start, the tape and POKE `$91F2` = `$C9` as in l1 (no life lost, the recording's machine
    only), l1's keys to frame 2100 (tests/inputs/l1.txt), the autopilot until a pick-up has given the Force (ForceLevel `$7ABE` > 0) and it docks (ForceAttached `$7AA3` > 0); then the
    detach key N held with fire until ForceAttached is 0 (ShieldControls `$95DF`), fire alone until the Force stops
    (state 3 or 7), N again (the recall, `$95F3`: state 6), fire until it docks again; screens at each step"""
    tape_at(r, 35)
    r.poke(DEATH, [0xC9], 'RET at the life-lost path $91F2: no life is lost (as in l1)')
    replay(r, 'l1', 2100)                               # l1's keys: the Force pick-up at 2056, docked at 2083
    autopilot(r, 3000, stop=lambda: r.lab.read(FORCE_LEVEL, 1)[0] and r.lab.read(FORCE_ATTACHED, 1)[0],
              every=10**6)
    note(r, 'docked', level=r.lab.read(FORCE_LEVEL, 1)[0], attached=r.lab.read(FORCE_ATTACHED, 1)[0])
    r.shot('docked')
    for _ in range(4):        # the detach: N read once a pass; at the nose the ship left of column 26, at the tail right of 3
        for _ in range(30):
            col, at = r.lab.read(0x7AA1, 1)[0], r.lab.read(FORCE_ATTACHED, 1)[0]
            if (at == 1 and col < 0x16) or (at == 2 and 8 <= col < 0x16):
                break
            r.hold(F + '+' + (L if col >= 0x16 else R), 6)
        note(r, 'detach-key', column=r.lab.read(0x7AA1, 1)[0], attached=r.lab.read(FORCE_ATTACHED, 1)[0])
        r.hold(F + '+' + X, 12)
        if not r.lab.read(FORCE_ATTACHED, 1)[0]:
            break
    note(r, 'detached', attached=r.lab.read(FORCE_ATTACHED, 1)[0], state=force_state(r))
    r.shot('detached')
    for k in range(60):
        r.hold(F, 5)
        if k == 6:
            r.shot('flying')
        if force_state(r) in (3, 7):
            break
    note(r, 'stopped', state=force_state(r))
    r.shot('stopped')
    r.hold(X, 12)
    r.hold('', 2)
    note(r, 'recalled', state=force_state(r))
    r.shot('recalled')
    for k in range(80):
        r.hold(F, 5)
        if r.lab.read(FORCE_ATTACHED, 1)[0]:
            break
    note(r, 'docked-again', attached=r.lab.read(FORCE_ATTACHED, 1)[0], state=force_state(r))
    r.shot('docked-again')
    autopilot(r, 100, every=10**6)


def plan_boss(r):
    """boss: from c1's play start, the tape and POKE `$91F2` = `$C9` as in l1 (no life lost), l1's keys
    (tests/inputs/l1.txt) to level 1's boss; when the
    boss tail (a slot run by mover A9 `$F559`) is out, slot 2's hits (`$850A` bits 0-5) are POKEd to 1 so that the
    autopilot's shots can destroy it (no recording killed a boss by hits); mover A9 then calls BossDestroyed `$C19C`.
    If slot 2 is still alive 1500 frames later, its flags are POKEd to 0 (said in record.json). Runs on until the level
    digit steps to 2"""
    def tail_out():
        slots = r.lab.read(SLOTS, 28 * 9)
        return any(slots[9 * k + 5] & 15 == 9 and (slots[9 * k] & 0x3F or slots[9 * k + 8] & 0x80) for k in range(28))

    tape_at(r, 35)
    r.poke(DEATH, [0xC9], 'RET at the life-lost path $91F2: no life is lost (as in l1)')
    if not replay(r, 'l1', 15000, stop=tail_out):      # l1's keys until the tail is out
        autopilot(r, int(os.environ.get('FRAMES', '3000')), stop=tail_out, every=1000, name='play')
    f = r.lab.read(SLOTS + 9, 1)[0]
    note(r, 'tail-out', map_column=r.lab.read(MAP_COLUMN, 1)[0], slot2=f)
    r.shot('tail-out')
    if f & 0x3F > 1:
        r.poke(SLOTS + 9, [(f & 0xC0) | 1], 'slot 2 hits left = 1: one shot destroys the boss part mover A9 waits for')
    start = r.lab.frame
    forced = False
    while r.lab.frame - start < 4000 and level(r) == 1:
        autopilot(r, 50, every=10**6)
        f = r.lab.read(SLOTS + 9, 1)[0]
        if f & 0x3F == 0:
            note(r, 'slot2-free', map_column=r.lab.read(MAP_COLUMN, 1)[0])
            r.shot('slot2-free')
            break
        if not forced and r.lab.frame - start > 1500:
            r.poke(SLOTS + 9, [0], 'slot 2 freed: the shots did not reach it in 1500 frames')
            forced = True
    for k in range(6):
        autopilot(r, 25, every=10**6)
        r.shot(f'after-{k}')
    autopilot(r, 600, stop=lambda: level(r) != 1, every=200, name='end')


def plan_restart(r):
    """restart: from c1's play start, POKE `$91F2` = `$C9` until MapColumn `$7A84` passes level 1's second checkpoint
    (column `$25`, CheckRestart `$C2D6` sets LevelRestartColumn `$C4AE` = `$25` - 8 = `$1D`), then the original `$CD` back
    (lives can be lost again), the autopilot until a life is lost and the next one starts; MapColumn and
    LevelRestartColumn are read at each step"""
    r.poke(DEATH, [0xC9], 'RET at the life-lost path $91F2 until the second checkpoint')
    autopilot(r, 12000, stop=lambda: r.lab.read(MAP_COLUMN, 1)[0] >= 0x27, every=10**6)
    note(r, 'past-checkpoint', map_column=r.lab.read(MAP_COLUMN, 1)[0],
         restart_column=r.lab.read(RESTART_COLUMN, 1)[0], lives=r.lab.read(LIVES, 1)[0])
    r.shot('past-checkpoint')
    r.poke(DEATH, [0xCD], 'the original CALL byte back at $91F2: lives can be lost again')
    lives = r.lab.read(LIVES, 1)[0]
    autopilot(r, 6000, stop=lambda: r.lab.read(LIVES, 1)[0] < lives, every=10**6)
    note(r, 'life-lost', map_column=r.lab.read(MAP_COLUMN, 1)[0], restart_column=r.lab.read(RESTART_COLUMN, 1)[0],
         lives=r.lab.read(LIVES, 1)[0])
    r.shot('life-lost')
    for k in range(80):                       # until the next life's shield is set (StartPlay: ShieldTimer $20)
        r.wait(10)
        if r.lab.read(SHIELD, 1)[0]:
            break
    note(r, 'restarted', map_column=r.lab.read(MAP_COLUMN, 1)[0], restart_column=r.lab.read(RESTART_COLUMN, 1)[0],
         shield=r.lab.read(SHIELD, 1)[0])
    r.shot('restarted')
    autopilot(r, 300, every=100, name='after')


def plan_pause(r):
    """pause: from c1's play start (play.szx, level 1, keys O P Q A M N), no POKE: 60 frames of flight right and
    up, CAPS SHIFT + 1 held 10 frames (GAME PAUSED), 150 frames with no key, CAPS SHIFT + 2 held 10 frames, 80
    frames of play (made by rtB's work/docs/rtB/tools/rec_pause.py, the same plan)"""
    r.hold('P', 30)
    r.hold('Q', 30)
    r.shot('before-pause')
    r.hold('CS+1', 10)
    r.shot('paused-held')
    r.hold('', 75)
    r.shot('paused')
    r.hold('', 75)
    r.hold('CS+2', 10)
    r.shot('resumed-held')
    r.hold('', 80)
    r.shot('after')


PLANS = {'m128': plan_m128, 'deaths': plan_deaths, 'hiscore': plan_hiscore, 'c1': plan_c1, 'level': plan_level, 'ctl': plan_ctl, 'gameover': plan_gameover,
         'continue': plan_continue, 'ending': plan_ending,
         'force': plan_force, 'boss': plan_boss, 'restart': plan_restart, 'pause': plan_pause}


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
