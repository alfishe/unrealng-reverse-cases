#!/usr/bin/env python3
"""re_session.py capture of a tape as a user loads it (48K: LOAD "" typed; 128K: the menu's Tape Loader), the
fast LD-BYTES trap and turbo tape set off, so every block is read from the signal by the ROM and the game's own loader
(`c1`: the whole load in the recording at its real length), the tape stopped after --load-frames. Every other argument is
re_session.py capture's, or kit/rs.py's (--stop, --expect; the --inputs check), as the capture goes through kit/rs.py.

    python3 tools/rs_capture.py --work work/stage1/c1 --media TAPE --model 48K \
        --record-load --load-frames 15700 --inputs tests/inputs/c1.txt --port-base 37485 --binary $BIN
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.environ['RS']))
import corpus  # noqa: E402
import re_session  # noqa: E402


def load(m, game, media, report, args):
    r = m.s.call('load_software', {'path': media, 'autostart': False, 'play': False}, ok=False)
    report['load'] = [line for line in (r.text or '').splitlines() if not line.startswith('Note:')]
    for name in ('fast_tape', 'turbo_tape'):
        r = m.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                    'body': {'value': False}}, ok=False)
        report.setdefault('settings', []).append(f'{name}: {(r.text or "")[:200]}')
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
    m.post('/tape/stop', None)
    tape = (m.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/tape'}).structured or {})['body']
    report['tape_state'] = tape.get('state')
    report['tape_position'] = tape.get('position')
    return frames


corpus.load = load
re_session.corpus.load = load
# through kit/rs.py: its input check (a "+" chord split, a word that is no key refused), --stop and --expect
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import rs  # noqa: E402
sys.exit(rs.main(['--unreal', os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.environ['RS'])))),
                  'capture', *sys.argv[1:]]))
