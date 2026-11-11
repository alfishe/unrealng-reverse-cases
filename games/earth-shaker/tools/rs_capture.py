#!/usr/bin/env python3
"""re_session.py capture of the covertape side as a user loads it: the tape wound to Earth Shaker's BASIC header
"EARTH" (`/tape/seek`: the side starts with Biggles and Timewarp), the fast LD-BYTES trap (fast_tape) and turbo
tape set off, so the ROM's LD-BYTES reads every block from the signal (`c1`: the whole load in the recording at
its real length), the tape stopped after --load-frames (the side goes on with Switchblade). Every other argument
is re_session.py capture's.

    python3 tools/rs_capture.py --work work/stage1/c1 --media "work/media/Your Sinclair (Issue 63) - Side 1.tzx" \
        --model 48K --record-load --load-frames 11800 --inputs tests/inputs/c1.txt --port-base 37100 --binary $BIN
"""
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
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
    frames = corpus.run_frames(m, corpus.TAPE_BOOT_FRAMES, None, 0)  # a recording machine takes the tape in its frames
    for _ in range(100):  # the tape lands asynchronously
        tape = (m.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/tape'}).structured or {})
        tape = tape.get('body') or {}
        if tape.get('blocks'):
            break
        frames = corpus.run_frames(m, 1, None, frames)
    else:
        raise RuntimeError(f'no tape after load_software: {report["load"]} {tape}')
    block = next(b['index'] for b in tape['blocks']
                 if b.get('kind') == 'header' and b.get('name') == 'EARTH' and b.get('param1', 0) < 10000)
    m.post('/tape/seek', {'block': block})
    report['seek'] = block
    for keys in (['j'], ['symbol', 'p'], ['symbol', 'p'], ['enter']):
        corpus.key_tap(m, keys)
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
sys.argv = ['re_session.py', 'capture', *sys.argv[1:]]
re_session.main()
