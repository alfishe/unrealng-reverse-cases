"""Shared helpers of the z128B scripts (docs 07-10): the session of a work folder, TTD memory reads, port events.

Copied from ../zynaps/tools/zynlib.py and extended. A work folder is one re_session.py capture / open folder whose
session.json names the live instance.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
KIT = os.path.normpath(os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402


def session(work, unreal=None):
    sys.path.insert(0, os.path.join(K.unreal_root(unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    return s


def tt(s, args):
    """one time_travel call: (text, structured)"""
    r = s.call('time_travel', args, ok=False)
    return r.text or '', r.structured or {}


def read(s, frame, lo, n, tinframe=None, space='cpu', page=None):
    """n bytes from lo at the end of a frame (or at frame, tinframe); space 'ram' with page for a RAM page (lo then counts
    from the page's start; the offset sent is page x $4000 + lo)"""
    out = bytearray()
    for a in range(lo, lo + n, 0x4000):
        args = {'action': 'memory_at', 'space': space, 'frame': frame,
                'offset': a + (page * 0x4000 if page is not None else 0), 'length': min(0x4000, lo + n - a)}
        if tinframe is not None:
            args['tinframe'] = tinframe
        text, st = tt(s, args)
        if 'hex' not in st:
            raise RuntimeError(f'memory_at {frame}:{tinframe} ${a:04X}: {text}')
        out += bytes.fromhex(st['hex'])
    return bytes(out)
