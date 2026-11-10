#!/usr/bin/env python3
"""Memory of a recording at a frame (TTD memory_at, the state at the frame's start, tinframe 0 unless given), read
from the instance that holds a re_session.py work folder.

    python3 tools/ttdmem.py WORK FRAME ADDR LEN [--tinframe T] [--out F.bin]
    from ttdmem import session, mem; s = session(work); mem(s, frame, addr, n)
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    return re_session.session_of(work)[0]


def mem(s, frame, addr, n, tinframe=0):
    out = b''
    while n > 0:
        k = min(n, 16384)
        r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': tinframe,
                                   'offset': addr, 'length': k, 'format': 'base64'}, ok=False)
        st = r.structured or {}
        if 'hex' not in st:
            raise SystemExit(f'memory_at {frame}: {r.text[:200]}')
        out += bytes.fromhex(st['hex'])
        addr += k
        n -= k
    return out


def first_frame(s, lo, hi, test):
    """The first frame in [lo, hi] where test(frame) holds (test monotone)"""
    while lo < hi:
        mid = (lo + hi) // 2
        if test(mid):
            hi = mid
        else:
            lo = mid + 1
    return lo


if __name__ == '__main__':
    a = sys.argv
    t = int(a[a.index('--tinframe') + 1]) if '--tinframe' in a else 0
    d = mem(session(a[1]), int(a[2]), int(a[3], 0), int(a[4], 0), t)
    if '--out' in a:
        open(a[a.index('--out') + 1], 'wb').write(d)
    else:
        print(d.hex())
