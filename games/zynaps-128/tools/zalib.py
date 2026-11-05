"""Shared helpers of the z128A scripts (docs 01-06, copied from ../zynaps/tools/zynlib.py): the session of a work folder, TTD memory reads."""
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


def read(s, frame, lo, n, tinframe=None):
    """n bytes from lo at the end of a frame, or at (frame, tinframe)"""
    out = bytearray()
    for a in range(lo, lo + n, 0x4000):
        args = {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'offset': a,
                'length': min(0x4000, lo + n - a)}
        if tinframe is not None:
            args['tinframe'] = tinframe
        r = s.call('time_travel', args, ok=False)
        if not r.structured or 'hex' not in r.structured:
            raise RuntimeError(f'memory_at {frame}:{tinframe} ${a:04X}: {r.text}')
        out += bytes.fromhex(r.structured['hex'])
    return bytes(out)
