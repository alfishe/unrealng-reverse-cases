#!/usr/bin/env python3
"""re_session.py capture for Rick Dangerous 2: the original tape at ROM speed (the fast LD-BYTES trap and turbo tape
off: the game's own loaders read every block from the signal) and input scripts that also drive the tape.

With --media the machine loads the tape as a user does (on a 128K the 128 menu's Tape Loader taken with ENTER, on a
48K LOAD "" typed) and plays it for --load-frames; then the tape is paused. With --snapshot the state is loaded and
the tape settings are set off (PRETAPE=A or B in the environment: that side is inserted, paused, before the
recording starts). Either way the scripts run in the recording.

Besides mm_session's key lines an input script may hold tape lines, run at their frame (the next run call starts
after them):

    +10 TAPE A            insert side A of the original (work/media/orig/, unpacked from orig/), at its first block
    +10 TAPE B            insert side B (the five level blocks)
    +0 TAPE play          play from the head (the emulator pauses the tape by itself when the game stops reading it)
    +0 TAPE pause
    +0 TAPE seek 2        put the head at block 2
    +0 POKE 35376 0       write a byte (a cheat; the recording that uses one says so)

    python3 tools/capture.py --work work/stage1/c1 --media A --model 128K --record-load --load-frames 14600 \
        --inputs tests/inputs/c1.txt --port-base 37500 --binary $BIN
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.environ['RS']))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import corpus  # noqa: E402
import mm_session  # noqa: E402
import re_session  # noqa: E402
from lab import tape_file  # noqa: E402

LOG = []


def api(m, method, path, body=None):
    r = m.s.call('invoke_api', {'method': method, 'path': '/api/v1/emulator/{id}' + path, 'body': body}, ok=False)
    return (r.text or '').splitlines()[-1][:160] if r.text else ''


def settings_off(m):
    for name in ('fast_tape', 'turbo_tape'):
        api(m, 'PUT', f'/settings/{name}', {'value': False})


def load(m, game, media, report, args):
    side = 'B' if os.path.basename(media).upper() in ('B', 'SIDE-B') else 'A'
    r = m.s.call('load_software', {'path': tape_file(side), 'autostart': False, 'play': False}, ok=False)
    report['load'] = [line for line in (r.text or '').splitlines() if not line.startswith('Note:')]
    settings_off(m)
    frames = corpus.run_frames(m, corpus.TAPE_BOOT_FRAMES, None, 0)
    if game['model'] == '48K':
        for keys in (['j'], ['symbol', 'p'], ['symbol', 'p'], ['enter']):
            corpus.key_tap(m, keys)
            frames += 15
    else:
        corpus.key_tap(m, ['enter'])  # the 128 menu's first item, Tape Loader
        frames += 15
    m.post('/tape/play', None)
    frames = corpus.run_frames(m, args.load_frames - frames, None, frames)
    report['tape_after_load'] = api(m, 'POST', '/tape/pause')
    return frames


def parse(path):
    """[(frame, keys | None for END | ('TAPE'|'POKE', words))] like mm_session.parse_script, with tape and poke lines"""
    events, last = [], 0
    with open(path) as f:
        for raw in f:
            line = raw.split('#', 1)[0].strip()
            if not line:
                continue
            words = line.split()
            frame = last + int(words[0][1:]) if words[0].startswith('+') else int(words[0])
            rest = words[1:]
            if rest and rest[0] in ('TAPE', 'POKE'):
                events.append((frame, (rest[0], rest[1:])))
            elif rest == ['END']:
                events.append((frame, None))
                break
            else:
                events.append((frame, [] if rest in ([], ['-']) else rest))
            last = frame
    return events


def command(m, what, words):
    if what == 'POKE':
        out = api(m, 'POST', '/memory/write', {'address': str(int(words[0], 0)), 'data': [int(w, 0) for w in words[1:]]})
    elif words[0] in ('A', 'B'):
        out = api(m, 'POST', '/tape/load', {'path': tape_file(words[0])})
        settings_off(m)
    elif words[0] == 'seek':
        out = api(m, 'POST', '/tape/seek', {'block': int(words[1])})
    else:
        out = api(m, 'POST', '/tape/' + words[0])
    return out


def play_script(s, m, path, screens, at):
    held, last = [], 0
    for frame, ev in parse(path):
        if frame > last:
            corpus.run_frames(m, frame - last, screens, at + last)
            last = frame
        if ev is None:
            break
        if isinstance(ev, tuple):
            LOG.append(f'{os.path.basename(path)} frame {at + frame}: {ev[0]} {" ".join(ev[1])} -> '
                       f'{command(m, ev[0], ev[1])}')
            print(LOG[-1], flush=True)
            continue
        for key in held:
            re_session.set_key(s, key, False)
        for key in ev:
            re_session.set_key(s, key, True)
        held = ev
    for key in held:
        re_session.set_key(s, key, False)
    return last


corpus.load = load
re_session.corpus.load = load
re_session.play_script = play_script
_capture = re_session.capture


def capture(args):
    if args.snapshot:
        # settings off before the state: the snapshot keeps the machine, the settings are the instance's
        orig = corpus.Machine.post

        def post(self, path, body):
            out = orig(self, path, body)
            if path == '/snapshot/load':
                if os.environ.get('PRETAPE'):
                    # a tape inserted while the TTD records crashed unreal-ng (Tape::getTapeStreamBit, a null
                    # stream): with PRETAPE=A or B the side goes in before the recording starts, paused at block 0
                    api(self, 'POST', '/tape/load', {'path': tape_file(os.environ['PRETAPE'])})
                    api(self, 'POST', '/tape/pause')
                settings_off(self)
            return out
        corpus.Machine.post = post
    _capture(args)
    with open(os.path.join(args.work, 'tape-log.txt'), 'w') as f:
        f.write('\n'.join(LOG) + '\n')


re_session.capture = capture
sys.argv = ['re_session.py', 'capture', *sys.argv[1:]]
re_session.main()
