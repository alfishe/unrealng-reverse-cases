#!/usr/bin/env python3
"""Live captures for docs 01, 05 and 06 (zgsA): the options menu driven, and each level started through the hidden
SELECT LEVEL and played for a while, on a live unreal-qt instance of tools/gs_session.py (launched, muted).

    python3 tools/cap_tour.py menu  --work W --out work/zgsA/menu
    python3 tools/cap_tour.py level --work W --level 5 --frames 600 --out work/zgsA/tour/L05
    python3 tools/cap_tour.py level --work W --level 1 --mode fx --mortal --frames 9000 --step 24 \
        --ttd work/zgsA/fx1/session.ttd --out work/zgsA/fx1

Every run boots the original TRD fresh (work/media/trd/ZYNAP_GS.TRD; a snapshot loaded without its disk hangs in
TR-DOS). The captures are files: NNNNNN.scr (the 6912 screen bytes at that frame of the run), NNNNNN.var ($7F00-$80FF:
the player records and LevelOrder) and NNNNNN.gsv ($B440-$B4A7: the GS trampolines and flags, $B461 the level whose
sound is loaded); steps.log names what was pressed when.

menu: the menu as it boots, then keys 3 4 5 6 7 7 (each option changed), 0 (the hidden lines), 8, T, a capture
every 2 frames; the code bytes the options write ($B218, $9B50, $B073 in bank 0, written in place in block 4's
image) are read after each key into the log.
--ttd: a TTD recording from the boot on, dumped at the end (the run's frames are the recording's frames).
level: keys 0, 8 (INFINITE LIFE; not with --mortal), the level key (Q-T 1-5, Y-P 6-10, A 11, S 12), 1 (music and effects); fire on
the title (key 1 held 15 frames, then fire 15 frames); when $B461 holds the level, a capture every --step frames while the Kempston stick follows a fixed
pattern with fire held (hooks2.py's pattern).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gs_session as g  # noqa: E402

TRD = os.path.join(HERE, '..', 'work', 'media', 'trd', 'ZYNAP_GS.TRD')
LEVEL_KEYS = 'QWERTYUIOPAS'
PATTERN = ['fire+up', 'fire', 'fire+down', 'fire+right', 'fire+down', 'fire+left', 'fire+up', 'fire+up', 'fire',
           'fire+down']


class Tour:
    def __init__(self, work, out):
        self.L = g.Live(work)
        self.s = self.L.s
        self.s.call('control_execution', {'action': 'take_control'}, ok=False)
        self.s.call('control_execution', {'action': 'pause'}, ok=False)
        self.out = out
        os.makedirs(out, exist_ok=True)
        self.frame = 0
        self.log = open(os.path.join(out, 'steps.log'), 'w')
        self.ttd = None
        self.pokes = []
        self.no_select = False

    def note(self, text):
        print(f'{self.frame:6d} {text}', flush=True)
        self.log.write(f'{self.frame:6d} {text}\n')
        self.log.flush()

    def mem(self, lo, n):
        return self.L.get(f'/memory/read/{lo}?length={n}&format=binary', raw=True)

    def run(self, n):
        self.L.run(n)
        self.frame += n

    def capture(self):
        base = os.path.join(self.out, f'{self.frame:06d}')
        open(base + '.scr', 'wb').write(self.mem(0x4000, 6912))
        open(base + '.var', 'wb').write(self.mem(0x7F00, 0x200))
        open(base + '.gsv', 'wb').write(self.mem(0xB440, 0x68))

    def tap(self, key, hold=3, after=15, capture_every=0):
        self.L.key(key, True)
        self.run(hold)
        self.L.key(key, False)
        self.note(f'key {key}')
        if capture_every:
            for _ in range(after // capture_every):
                self.run(capture_every)
                self.capture()
        else:
            self.run(after)

    def boot(self):
        self.s.call('emulator_manage', {'action': 'reset'}, ok=False)
        r = self.s.call('load_software', {'path': os.path.abspath(TRD), 'autostart': True}, ok=False)
        self.note('boot ' + (r.text or '').splitlines()[0][:100])
        self.s.call('control_execution', {'action': 'pause'}, ok=False)
        if self.ttd:
            self.note('ttd: ' + (self.s.call('analysis', {'action': 'start', 'record': True}, ok=False).text or '')[:80])
        self.run(900)
        self.capture()
        self.note('menu')


def menu(t):
    t.boot()
    for k in '345677':
        t.tap(k, after=30, capture_every=2)
    for k in '08T':
        t.tap(k, after=40, capture_every=2)
    code = t.mem(0x6000, 0xA000)
    t.note('block 4 image (not yet installed): ' + json.dumps({
        'RoundsJump $B218': code[0xB218 - 0x6000:0xB21A - 0x6000].hex(),
        'ShipHitJump $9B50': code[0x9B50 - 0x6000:0x9B51 - 0x6000].hex(),
        'LevelSelectCode $B073': code[0xB073 - 0x6000:0xB075 - 0x6000].hex()}))


def level(t, n, frames, step, mode, mortal=False):
    t.boot()
    t.tap('0')
    if not mortal:
        t.tap('8')
    if not t.no_select:
        t.tap(LEVEL_KEYS[n - 1])
    t.tap('1' if mode == 'music' else '2', after=50)
    t.run(700)
    t.capture()
    start = t.frame
    for attempt in range(8):  # the title takes key 1 and fire only on some of its pages: try until the level loads
        t.tap('1', hold=20, after=10)
        t.s.call('joystick_input', {'action': 'press', 'buttons': 'fire'}, ok=False)
        t.run(30)
        t.s.call('joystick_input', {'action': 'release', 'buttons': 'fire'}, ok=False)
        t.note(f'fire on the title (attempt {attempt + 1})')
        loaded = False
        for _ in range(40):
            t.run(25)
            if t.mem(0xB461, 1)[0] == n:
                loaded = True
                break
        if loaded:
            break
    t.note(f'level change begun: $B461 = {t.mem(0xB461, 1)[0]}, {t.frame - start} frames after the title capture')
    # the loader shows the loading screen until the module and FX are on the card: wait until its attributes go
    loading = open(os.path.join(HERE, '..', 'build', 'res', 'screen', 'loading.scr'), 'rb').read()[0x1800:0x1B00]
    for _ in range(80):
        t.run(10)
        if t.mem(0x5800, 0x300) != loading:
            break
    t.note('the loading screen is gone: play')
    for poke in t.pokes:  # an experiment, named in the log: e.g. FFD7=01, Zynaps's Invulnerable switch
        a, h = poke.split('=')
        t.s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': '0x' + a, 'hex': h})
        t.note(f'poke ${a} = {h}')
    t.run(30)
    i = 0
    done = 0
    while done < frames:
        b = PATTERN[i % len(PATTERN)]
        i += 1
        for k in b.split('+'):
            t.s.call('joystick_input', {'action': 'press', 'buttons': k}, ok=False)
        for _ in range(24 // step):
            t.run(step)
            t.capture()
            done += step
        for k in b.split('+'):
            t.s.call('joystick_input', {'action': 'release', 'buttons': k}, ok=False)
    t.note('end')
    if t.ttd:
        r = t.s.call('time_travel', {'action': 'dump', 'path': os.path.abspath(t.ttd)}, ok=False)
        t.note('ttd dump: ' + (r.text or '')[:120])


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('what', choices=['menu', 'level'])
    ap.add_argument('--work', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--level', type=int, default=1)
    ap.add_argument('--frames', type=int, default=600)
    ap.add_argument('--step', type=int, default=2)
    ap.add_argument('--mode', choices=['music', 'fx'], default='music')
    ap.add_argument('--mortal', action='store_true', help='no INFINITE LIFE (key 8 not pressed)')
    ap.add_argument('--no-select', action='store_true', help='no level key: the game plays its own level order')
    ap.add_argument('--poke', action='append', default=[], help='ADDR=HEX written once play starts')
    ap.add_argument('--ttd', help='record the run from the boot (TTD) and dump it here')
    a = ap.parse_args()
    t = Tour(a.work, a.out)
    t.ttd = a.ttd
    t.pokes = a.poke
    t.no_select = a.no_select
    if a.what == 'menu':
        menu(t)
    else:
        level(t, a.level, a.frames, a.step, a.mode, a.mortal)


if __name__ == '__main__':
    main()
