#!/usr/bin/env python3
"""re_session.py capture with the tape at signal speed: the fast LD-BYTES trap (fast_tape) and turbo tape are set
off before the tape is loaded, so the ROM's LD-BYTES reads every block from the signal (`c1`: the whole load in the
recording at its real length). Every other argument is re_session.py capture's.

    python3 tools/rs_capture.py --work work/stage1/c1 --media orig/Tujad.tzx.zip --record-load --load-frames 16000 ...
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.environ['RS']))
import corpus  # noqa: E402
import re_session  # noqa: E402

_load = corpus.load


def load(m, game, media, report, args):
    for name in ('fast_tape', 'turbo_tape'):
        r = m.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                    'body': {'value': False}}, ok=False)
        report.setdefault('settings', []).append(f'{name}: {(r.text or "")[:200]}')
    return _load(m, game, media, report, args)


corpus.load = load
re_session.corpus.load = load
sys.argv = ['re_session.py', 'capture', *sys.argv[1:]]
re_session.main()
