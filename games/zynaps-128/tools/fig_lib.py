"""Shared helpers of z128A's figure scripts (tools/fig_levelshots.py, tools/fig_play_anim.py): the session of a
work folder and exact TTD memory reads (adapted from games/zynaps/tools/zynlib.py).

The game's `$C000`-`$FFFF` is RAM page 0; inside the interrupt's engine call page 4 is mapped there, so reads above
`$C000` go to RAM page 0 (space ram), never the CPU view.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
KIT = os.path.normpath(os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402,F401

P1, LEVEL_ORDER, OBJECTS, FUEL = 0x7F9C, 0x8003, 0xF36C, 0x80E6
WEAPONS = {0: 'none', 2: 'plasma', 3: 'homing missiles', 4: 'seeker'}


def session(work, unreal=None):
    sys.path.insert(0, os.path.join(K.unreal_root(unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    return s


def _read(s, space, frame, offset, n, tinframe=None):
    args = {'action': 'memory_at', 'space': space, 'frame': frame, 'offset': offset, 'length': n}
    if tinframe is not None:
        args['tinframe'] = tinframe
    r = s.call('time_travel', args, ok=False)
    if not r.structured or 'hex' not in r.structured:
        raise RuntimeError(f'memory_at {space} {frame}:{tinframe} ${offset:04X}: {r.text}')
    return bytes.fromhex(r.structured['hex'])


def read(s, frame, lo, n, tinframe=None):
    """n bytes from lo (below $C000: the CPU view; from $C000: RAM page 0) at the end of a frame or at frame:T"""
    out = bytearray()
    a = lo
    while a < lo + n:
        if a < 0xC000:
            m = min(0xC000, lo + n, (a & 0xC000) + 0x4000) - a
            out += _read(s, 'cpu', frame, a, m, tinframe)
        else:
            m = lo + n - a
            out += _read(s, 'ram', frame, a - 0xC000, m, tinframe)
        a += m
    return bytes(out)


def state(s, frame):
    """the player 1 record and the derived readout at the end of a frame"""
    rec = read(s, frame, P1, 16)
    order = read(s, frame, LEVEL_ORDER, 12)
    fuel = read(s, frame, FUEL, 1)[0]
    counter = rec[6]
    return {'score': int(rec[0:4].hex()), 'lives': rec[4], 'deaths': rec[5], 'counter': counter,
            'level': order[counter] if counter < 12 else None, 'highlight': rec[7], 'weapon': rec[8],
            'laser': rec[10], 'speed': rec[11], 'fuel': fuel, 'order': list(order)}


def screen(s, frame):
    mem = bytearray(0x10000)
    mem[0x4000:0x5B00] = read(s, frame, 0x4000, 6912)
    return K.render_screen(mem)
