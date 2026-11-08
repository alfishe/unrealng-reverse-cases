"""Shared helpers of the Elite case's scripts: the session of a work folder, TTD memory reads, the tape."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
KIT = os.path.normpath(os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, KIT)
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402

FRAME_T = 69888  # T-states a 48K frame


def session(work, unreal=None):
    sys.path.insert(0, os.path.join(K.unreal_root(unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    return s


def read(s, frame, lo, n, tinframe=None):
    """n bytes from lo at the end of a frame, or at (frame, tinframe)"""
    out = bytearray()
    a = lo
    while a < lo + n:
        ln = min(0x4000, lo + n - a)
        args = {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'offset': a, 'length': ln}
        if tinframe is not None:
            args['tinframe'] = tinframe
        r = s.call('time_travel', args, ok=False)
        if not r.structured or 'hex' not in r.structured:
            raise RuntimeError(f'memory_at {frame}:{tinframe} ${a:04X}: {r.text}')
        out += bytes.fromhex(r.structured['hex'])
        a += ln
    return bytes(out)


def tape_blocks(side='A'):
    """The data blocks of a side of orig/Elite.tzx.zip: [(tzx index, block dict)]"""
    import zipfile
    import tzxblocks as T
    name = f'Elite - 48k - Side {side}.tzx'
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'Elite.tzx.zip')) as z:
        t = z.read(name)
    return T.parse(t)
