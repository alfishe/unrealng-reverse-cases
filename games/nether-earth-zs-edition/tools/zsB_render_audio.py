#!/usr/bin/env python3
"""Renders the case's tunes and sound effects to docs/audio/*.mp3 from unreal-ng's own audio output (never played).

    python3 tools/zsB_render_audio.py [--port-base 15430] [--only intro98,intro99,sfx99,pokes99] [--encode-only]

The capture machinery is advanced-nether-earth's tools/render_audio.py (imported, not changed: its Rig, Take and
the high-pass of write_mp3): an own unreal-qt instance (offscreen, master muted: nothing reaches the speakers), a
Pentagon 128 with TR-DOS, one plain AY in the AY socket, a Kempston card; AY-3-8910, ABC stereo, no punch or room;
the machine run in emulated frames while /audio/capture takes the samples, re-armed every 1400 frames.

Stages (WAVs and their event lists in work/zsB/audio/):
  intro98  NEZSED98.SCL inserted, work/stage1/inputs/r98.txt's RUN "NEZSEd" typed (to its frame 326), then the intro
           left alone for one pass of COOL WINTER and 250 frames more; SPACE: the game's menu, left alone for one
           pass of its beeper tune (5192 frames) and 250 more. Master mix.
  intro99  NEZSED.SCL autostarted, the intro left alone for one pass of its tune and 250 frames more. Master mix.
  sfx99    work/zsB/menu-hard/play.szx (the '99 on HARD, the first frame of play) and the bot of
           tools/zsB_play99.py to frame 1300: the construction menu (cursor clicks, parts paid, START ROBOT), the
           orders (choices, the order beep). Beeper buffer.
  pokes99  the same snapshot, SoundFx ($FD53) set to 1, $FC, $FA and $C8 in turn (an experiment: the game's
           PlayInterrupt and SoundEffect make the sound). Beeper buffer.
"""
import argparse
import json
import os
import subprocess
import sys
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ANE = os.path.join(CASE, '..', 'advanced-nether-earth', 'tools')
sys.path.insert(0, ANE)
import render_audio as ra  # noqa: E402

WORK = os.path.join(CASE, 'work', 'zsB', 'audio')
OUT = os.path.join(CASE, 'docs', 'audio')
SCL98 = os.path.join(CASE, 'work', 'scl', 'z98', 'NEZSED98.SCL')
SCL99 = os.path.join(CASE, 'work', 'scl', 'z99', 'NEZSED.SCL')
PLAY = os.path.join(CASE, 'work', 'zsB', 'menu-hard', 'play.szx')
# ne-mus-live: one pass in the running intro is 6920 frames, not the player's 6912 (eight interrupts a pass reach
# no Play call; found here by the loudness correlation, 0.987 at 6920 against 0.05 at 6912)
LOOP = {'cool-winter': (323, 4480), 'ne-mus': (0, 6912), 'ne-mus-live': (0, 6920), 'menu98': (0, 5192)}
# sfx99's beeps: (file, first frame, end frame, title) of the stage, the bursts of Take.bursts(0, 1096)
SFX99 = (('sfx-cursor-click.mp3', 211, 214, 'a click (Beep A = $14)'),
         ('sfx-part-paid.mp3', 244, 250, 'a part paid (Beep A = $64)'),
         ('sfx-robot-start.mp3', 270, 314, 'START ROBOT (BuildChirp, then A = $C8)'),
         ('sfx-target-chosen.mp3', 917, 931, 'a target chosen (A = $64, then OrderSet A = $78)'))
FADE = 250
SOUNDFX = 0xFD53


def events_to(stage, events, frames, source):
    with open(os.path.join(WORK, stage + '.json'), 'w') as f:
        json.dump({'frames': frames, 'source': source, 'events': events}, f, indent=1)


def ev(events, rig, name):
    events.append([rig.frame - rig.start_frame, name])
    print(f'{rig.frame - rig.start_frame:7d} {name}', flush=True)


def stage_intro98(rig):
    rig.machine()
    r = rig.s.call('load_software', {'path': SCL98, 'autostart': False, 'play': False}, ok=False)
    print((r.text or '').splitlines()[0], flush=True)
    rig.run(1500)
    events = []
    rig.record(os.path.join(WORK, 'intro98.wav'))
    ev(events, rig, 'typing RUN "NEZSEd" (r98.txt)')
    rig.script(os.path.join(CASE, 'work', 'stage1', 'inputs', 'r98.txt'), stop_after=330)
    ev(events, rig, 'ENTER released')
    rig.run(600 + sum(LOOP['cool-winter']) + FADE)
    ev(events, rig, 'SPACE: the menu')
    rig.tap('space', hold=4, gap=0)
    rig.run(300 + LOOP['menu98'][1] + FADE)
    ev(events, rig, 'end')
    events_to('intro98', events, rig.done(), 'master')


def stage_intro99(rig):
    rig.machine()
    events = []
    rig.record(os.path.join(WORK, 'intro99.wav'))
    r = rig.s.call('load_software', {'path': SCL99, 'autostart': True, 'play': False}, ok=False)
    ev(events, rig, (r.text or '').splitlines()[0])
    rig.run(1000 + LOOP['ne-mus'][1] + FADE)
    ev(events, rig, 'end')
    events_to('intro99', events, rig.done(), 'master')


def stage_sfx99(rig):
    sys.path.insert(0, os.path.join(CASE, '..', 'nether-earth', 'tools'))
    import bot

    rig.machine()
    rig.load(PLAY)
    g = bot.Game(ra.UNREAL, os.path.join(WORK, 'bot'))
    g.s, g.m = rig.s, rig.m

    def run(frames):
        rig.run(frames)
        g.frame = rig.frame - rig.start_frame
    g.run = run
    events = []
    rig.record(os.path.join(WORK, 'sfx99.wav'), source='beeper')
    ev(events, rig, 'play.szx')
    home = next(b for b in g.buildings() if b['type'] == 0)
    g.land_on_warbase(home['x'], home['y'])
    ev(events, rig, 'the construction menu')
    robot = g.build([bot.BIPOD, bot.CANNON])
    ev(events, rig, f'robot built: {robot}')
    g.order(robot['slot'], bot.CAPTURE, 1)
    ev(events, rig, 'order given, the ship climbing')
    g.run(50)
    ev(events, rig, 'end')
    events_to('sfx99', events + [[None, line] for line in g.log], rig.done(), 'beeper')


def stage_pokes99(rig):
    rig.machine()
    rig.load(PLAY)
    events = []
    rig.record(os.path.join(WORK, 'pokes99.wav'), source='beeper')
    ev(events, rig, 'play.szx')
    for value, name, frames in ((0x01, 'fire', 140), (0xFC, 'miss', 20), (0xFA, 'hit', 20), (0xC8, 'kill', 70)):
        rig.run(10)
        rig.s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': hex(SOUNDFX),
                                     'hex': f'{value:02X}'}, ok=False)
        ev(events, rig, f'SoundFx = ${value:02X} ({name})')
        rig.run(frames)
    ev(events, rig, 'end')
    events_to('pokes99', events, rig.done(), 'beeper')


def write_mp3(take, start, end, fade, path, mono, title, album):
    ta = ra.write_mp3.__globals__['subprocess']

    class Tagged:
        @staticmethod
        def run(cmd, check):
            cmd = list(cmd)
            cmd[cmd.index('--ta') + 1] = album
            return subprocess.run(cmd, check=check)
    ra.write_mp3.__globals__['subprocess'] = Tagged
    try:
        return ra.write_mp3(take, start, end, fade, path, mono, title)
    finally:
        ra.write_mp3.__globals__['subprocess'] = ta


def encode():
    ra.WORK = WORK
    os.makedirs(OUT, exist_ok=True)
    rows = []
    a98, a99 = "Nether Earth ZS Edition'98 (ZS, 1998)", "Nether Earth ZS Edition'99 (ZS, 1999)"

    def tune(stage, after, key, name, title, album, mono=False, nth=0):
        t = ra.Take(stage)
        f0 = t.event(after, nth)[0]
        start = t.onset(f0)
        s, n = LOOP[key]
        # one pass from the loop's return point, then FADE frames of the next pass faded out
        a = start + int(round(s * t.per))
        b = a + int(round((n + FADE) * t.per))
        sec, peak = write_mp3(t, a, b, int(FADE * t.per), os.path.join(OUT, name), mono, title, album)
        sim = t.similarity(a, a + int(round(n * t.per)), 6.0)
        rows.append((name, sec, f'loop check {sim:.3f}'))
        print(name, f'{sec:.1f} s, peak {peak:.0f}, loop check {sim:.3f}', flush=True)

    def cut(stage, after, frames, name, title, album, nth=0, lead=0):
        t = ra.Take(stage)
        f0 = t.event(after, nth)[0]
        a = t.at(f0 - lead)
        b = t.at(f0 + frames)
        sec, peak = write_mp3(t, a, b, 0, os.path.join(OUT, name), True, title, album)
        rows.append((name, sec, ''))
        print(name, f'{sec:.2f} s, peak {peak:.0f}', flush=True)

    if os.path.exists(os.path.join(WORK, 'intro98.wav')):
        tune('intro98', 'ENTER released', 'cool-winter', 'cool-winter.mp3', 'COOL WINTER (the \'98 intro)', a98)
        t = ra.Take('intro98')
        f0 = t.event('SPACE: the menu')[0]
        start = t.onset(f0, gap_frames=2)
        n = LOOP['menu98'][1]
        b = start + int(round((n + FADE) * t.per))
        sec, _ = write_mp3(t, start, b, int(FADE * t.per), os.path.join(OUT, 'menu-tune98.mp3'), True,
                           'the \'98 game menu tune (beeper)', a98)
        rows.append(('menu-tune98.mp3', sec, f'loop check {t.similarity(start, start + int(round(n * t.per)), 6.0):.3f}'))
        print('menu-tune98.mp3', f'{sec:.1f} s', flush=True)
    if os.path.exists(os.path.join(WORK, 'intro99.wav')):
        tune('intro99', 'Inserted', 'ne-mus-live', 'intro-tune99.mp3', 'the \'99 intro tune', a99)
    if os.path.exists(os.path.join(WORK, 'sfx99.wav')):
        t = ra.Take('sfx99')
        print('sfx99 bursts', t.bursts(0, t.meta['frames'] - 1), flush=True)
        for name, f0, f1, title in SFX99:
            sec, peak = write_mp3(t, t.at(f0), t.at(f1), 0, os.path.join(OUT, name), True, title, a99)
            rows.append((name, sec, f'frames {f0}-{f1}'))
            print(name, f'{sec:.2f} s, peak {peak:.0f}', flush=True)
    if os.path.exists(os.path.join(WORK, 'pokes99.wav')):
        for value, name, frames in (('$01', 'sfx-fire-sweep.mp3', 128), ('$FC', 'sfx-miss.mp3', 5),
                                    ('$FA', 'sfx-hit.mp3', 7), ('$C8', 'sfx-kill.mp3', 57)):
            cut('pokes99', f'SoundFx = {value}', frames, name, 'SoundFx ' + value, a99)
    json.dump(rows, open(os.path.join(WORK, 'encoded.json'), 'w'), indent=1)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--binary', default=ra.BINARY.replace('wt-ane-stage1', 'wt-nezs-stage1'))
    p.add_argument('--port-base', type=int, default=15430)
    p.add_argument('--only', default='intro98,intro99,sfx99,pokes99')
    p.add_argument('--encode-only', action='store_true')
    a = p.parse_args()
    os.makedirs(WORK, exist_ok=True)
    if not a.encode_only:
        rig = ra.Rig(a)
        try:
            for stage in a.only.split(','):
                globals()['stage_' + stage](rig)
        finally:
            rig.stop()
    encode()


if __name__ == '__main__':
    main()
