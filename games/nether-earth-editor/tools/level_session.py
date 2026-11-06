#!/usr/bin/env python3
"""Recordings of the editor tape's game edition and its levels (edA): the load, a level through the game's own
LoadGame, a SaveGame, and one play screenshot per level. docs/03-build-and-load.md, docs/10-gameplay-logic.md.

    python3 level_session.py load  --work W [--level 1] [--port-base 9810]
        Power-on, recorded (TTD + analysis): LOAD "" typed, orig/NETHER.TZX played (the ROM's fast-load trap on);
        the edition's four blocks; the menu; the tape stopped and seeked to the level's 2-byte block; key 5
        (LoadGame); the level loads at signal speed (LoadGameBlocks enters LD-BYTES past the trap's hook); play;
        then key 5 in play (SaveGame), a key at the prompt, and the bytes SA-BYTES is given, read while it runs.
        Writes W/events.json (frames of each stage), W/menu.szx (the menu, tape stopped), W/saved.bin, the
        recording W/session.ttd and W/l1.json; the instance stays up (re_session.py stop --work W).
    python3 level_session.py levels --work W --menu W0/menu.szx [--port-base 9812]
        Not recorded: from the menu snapshot, each of the eight saved games loaded through key 5 in turn; for each,
        the memory once play runs (W/<n>/play.bin, 64 K), screens at play frames 0, 100, 400 (W/<n>/play-F.scr) and
        a full screenshot with the border (W/<n>/play.png).

Every frame number is of the recording named, counted from power-on (load) or from the snapshot (levels).
"""
import argparse
import json
import os
import sys
import time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
UNREAL = toolpaths.unreal_ng(required=False) or 'unreal-ng'
BINARY = os.path.join(UNREAL, 'scratch/wt-access-trace/cmake-build-agent-release/bin/unreal-qt.app/Contents/MacOS/'
                      'unreal-qt')
TAPE = os.path.join(CASE, 'orig', 'NETHER.TZX')
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import corpus  # noqa: E402

mcplib = corpus.mcplib

HANDLER = 0xFDFE
MENU_INTERRUPT = 0xC4FD
PLAY_INTERRUPT = 0xD566
START_INTERRUPT = 0xD59C
# The saved games: the tape block of each one's 2-byte block, as the emulator's tape API counts them (the data
# blocks only, the TZX text blocks not counted: the TAP numbering of tzx_blocks.py's TAP)
LEVELS = [('enemy-at-the-gates', 'Enemy At The Gates', 6), ('break-through', 'Break Through', 8),
          ('fortifications', 'Fortifications', 10), ('the-chase', 'The Chase', 12),
          ('jungle-of-stone', 'Jungle Of Stone', 14), ('double-frontline', 'Double Frontline', 16),
          ('the-slogan', 'The Slogan', 18), ('editor-save', 'the editor tape\'s saved game', 26)]


class Rig:
    def __init__(self, work, port_base, binary):
        self.work = os.path.abspath(work)
        os.makedirs(self.work, exist_ok=True)
        self.port_base = port_base
        self.binary = binary
        self.frame = 0
        self.events = []

    def start(self):
        here = os.getcwd()
        os.chdir(self.work)  # the emulator writes its features.ini where it starts
        try:
            self.process = mcplib.launch(self.binary, self.port_base)
        finally:
            os.chdir(here)
        s = mcplib.Session(f'http://127.0.0.1:{self.port_base + 200}/mcp', '48K')
        s.fresh_machine('48K', ram_power_on='zero')
        s.call('control_execution', {'action': 'pause'}, ok=False)
        s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                              'body': {'muted': True}}, ok=False)
        self.s = s
        self.m = corpus.Machine(s, self.port_base)
        with open(os.path.join(self.work, 'session.json'), 'w') as f:
            json.dump({'pid': self.process.pid, 'binary': self.binary, 'port_base': self.port_base, 'model': '48K',
                       'ranges': '4000-FFFF'}, f)
        print('instance pid', self.process.pid, 'port base', self.port_base, flush=True)
        return self

    def stop(self):
        self.process.terminate()
        try:
            self.process.wait(10)
        except Exception:
            self.process.kill()

    def run(self, frames):
        self.s.call('control_execution', {'action': 'run_frames', 'frames': frames})
        self.frame += frames

    def key(self, keys, hold=5, gap=10):
        for k in keys:
            self.s.call('type_input', {'action': 'press', 'key': k}, ok=False)
        self.run(hold)
        for k in keys:
            self.s.call('type_input', {'action': 'release', 'key': k}, ok=False)
        self.run(gap)

    def word(self, address):
        b = self.m.read(address, 2)
        return b[0] | b[1] << 8

    def pc(self):
        return self.m.get('/registers')['special']['pc']

    def tape(self):
        r = self.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/tape'}, ok=False)
        return ((r.structured or {}).get('body') or {})

    def note(self, what, **extra):
        t = self.tape()
        e = dict(frame=self.frame, what=what, pc='%04X' % self.pc(), tape_state=t.get('state'),
                 tape_block=(t.get('position') or {}).get('block'), **extra)
        self.events.append(e)
        print(e, flush=True)

    def wait(self, probe, limit, step=1):
        for _ in range(0, limit, step):
            if probe():
                return True
            self.run(step)
        return probe()

    def seek(self, block):
        self.m.post('/tape/stop', None)
        self.m.post('/tape/seek', {'block': block})

    def load_level(self, block):
        """From the menu: the tape at the level's 2-byte block, key 5, play; returns once play runs"""
        self.seek(block)
        self.key(['5'])
        self.m.post('/tape/play', None)
        self.note('LoadGame: key 5, tape playing', block=block)
        ok = self.wait(lambda: self.word(HANDLER) == PLAY_INTERRUPT, 6000, 10)
        self.note('play' if ok else 'no play after 6000 frames')
        self.m.post('/tape/stop', None)
        return ok

    def screenshot(self, path):
        self.s.call('capture_media', {'action': 'screenshot', 'area': 'full', 'path': path}, ok=False)


def cmd_load(args):
    rig = Rig(args.work, args.port_base, args.binary).start()
    s, m = rig.s, rig.m
    m.post('/snapshot/save', {'path': os.path.join(rig.work, 'power-on.szx'), 'force': True})
    s.call('analysis', {'action': 'start', 'record': True})
    r = s.call('load_software', {'path': TAPE, 'autostart': False, 'play': False}, ok=False)
    print((r.text or '').splitlines()[:1])
    with open(os.path.join(rig.work, 'tape.json'), 'w') as f:
        json.dump(rig.tape(), f, indent=1)
    rig.run(200)
    for keys in (['j'], ['symbol', 'p'], ['symbol', 'p'], ['enter']):
        rig.key(keys)
    m.post('/tape/play', None)
    rig.note('LOAD "" typed, tape playing')
    # the stages: the BASIC line 10 runs ($5CCB on), the snapshot loader's trampoline $4002, the game
    seen = set()

    def stage():
        pc = rig.pc()
        if 0x5CCB <= pc < 0x5E00 and 'basic' not in seen:
            seen.add('basic')
            rig.note('the BASIC loader code (line 10) runs')
        if pc >= 0xA600 and 'game' not in seen:
            seen.add('game')
            rig.note('the game runs')
        return rig.word(HANDLER) == MENU_INTERRUPT and 0xA600 <= rig.pc()

    rig.wait(stage, 20000, 2)
    rig.note('menu: MenuInterrupt installed')
    m.post('/tape/stop', None)
    rig.run(50)
    m.post('/snapshot/save', {'path': os.path.join(rig.work, 'menu.szx'), 'force': True})
    with open(os.path.join(rig.work, 'menu.bin'), 'wb') as f:
        f.write(m.read(0, 0x10000))
    rig.note('menu snapshot')
    slug, name, block = LEVELS[args.level - 1]
    rig.load_level(block)
    with open(os.path.join(rig.work, 'loaded.bin'), 'wb') as f:
        f.write(m.read(0, 0x10000))
    rig.run(300)
    rig.screenshot(os.path.join(rig.work, 'play.png'))
    rig.note('play + 300')
    # SaveGame: key 5 in play, a key at the prompt; then read what SA-BYTES is given while it runs
    rig.key(['5'], hold=3, gap=5)
    ok = rig.wait(lambda: rig.word(HANDLER) == START_INTERRUPT, 200)
    rig.note('SaveGame prompt' if ok else 'no SaveGame prompt')
    rig.run(20)
    rig.key(['space'], hold=3, gap=0)
    ok = rig.wait(lambda: 0x04C2 <= rig.pc() < 0x0540 and m.get('/registers')['index']['ix'] > 0xD92B, 3000)
    regs = m.get('/registers')
    rig.note('SA-BYTES on the game block' if ok else 'no SA-BYTES', ix='%04X' % regs['index']['ix'])
    with open(os.path.join(rig.work, 'saved.bin'), 'wb') as f:
        f.write(m.read(0, 0x10000))
    rig.wait(lambda: rig.pc() >= 0x4000 and rig.word(HANDLER) == PLAY_INTERRUPT, 6000, 10)
    rig.note('play again after the save')
    rig.run(100)
    with open(os.path.join(rig.work, 'events.json'), 'w') as f:
        json.dump(rig.events, f, indent=1)
    built = s.call('analysis', {'action': 'build', 'path': os.path.join(rig.work, 'l1.json'), 'wait': 30000})
    state = s.call('analysis', {'action': 'status'}).text
    while ': running' in state:
        time.sleep(5)
        state = s.call('analysis', {'action': 'status'}).text
    print(state.splitlines()[-1:])
    dumped = s.call('time_travel', {'action': 'dump', 'path': os.path.join(rig.work, 'session.ttd')}, ok=False)
    print((dumped.text or '').splitlines()[:1])
    print('instance kept: re_session.py stop --work', rig.work)


def cmd_levels(args):
    rig = Rig(args.work, args.port_base, args.binary).start()
    try:
        for n, (slug, name, block) in enumerate(LEVELS, 1):
            out = os.path.join(rig.work, slug)
            os.makedirs(out, exist_ok=True)
            rig.m.post('/snapshot/load', {'path': os.path.abspath(args.menu)})
            rig.frame = 0
            rig.events = []
            if not rig.load_level(block):
                continue
            with open(os.path.join(out, 'play.bin'), 'wb') as f:
                f.write(rig.m.read(0, 0x10000))
            at = 0
            for f_ in (0, 100, 400):
                rig.run(f_ - at)
                at = f_
                with open(os.path.join(out, f'play-{f_}.scr'), 'wb') as f:
                    f.write(rig.m.read(0x4000, 6912))
            rig.screenshot(os.path.join(out, 'play.png'))
            with open(os.path.join(out, 'events.json'), 'w') as f:
                json.dump(rig.events, f, indent=1)
    finally:
        rig.stop()


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    for name in ('load', 'levels'):
        q = sub.add_parser(name)
        q.add_argument('--work', required=True)
        q.add_argument('--binary', default=BINARY)
        q.add_argument('--port-base', type=int, default=9810)
        if name == 'load':
            q.add_argument('--level', type=int, default=1)
        else:
            q.add_argument('--menu', required=True)
    args = p.parse_args()
    {'load': cmd_load, 'levels': cmd_levels}[args.cmd](args)


if __name__ == '__main__':
    main()
