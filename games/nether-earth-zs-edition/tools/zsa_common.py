#!/usr/bin/env python3
"""Shared by zsA's figure scripts (tools/fig_zs_*.py, docs 01-06): the case's paths, the modules of each .ann, the
Pentagon 128 beam timing, a re_session work folder's live session, TTD memory_at.

The recordings are opened in an instance of our own by re_session.py open (WALKTHROUGH, zsA's NOTES), e.g.

    python3 $RS open --work work/docs/zsA/rc --ttd work/stage2/game99/r-critical/session.ttd --model PENTAGON \
        --port-base 15220 --binary $BIN

and the scripts read it through --work.
"""
import json
import os
import re
import sys
from bisect import bisect_right
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
KIT = os.path.join(ROOT, '..', '..', 'kit')
sys.path.insert(0, KIT)
UNREAL = toolpaths.unreal_ng(required=False) or 'unreal-ng'
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
IMG = os.path.join(ROOT, 'docs', 'img')

# Pentagon 128 in unreal-ng (kit/beam_timeline.py's table): 71680 T a frame, the INT at frame T -44 (71636 of the
# frame before), the first paper pixel at frame T 17944, 224 T a line
FRAME_T, INT_T, PAPER_T, LINE_T = 71680, 71636, 17944, 224

ANN = {'game99': 'src/game99/game.ann', 'game98': 'src/game98/game.ann', 'patches99': 'src/patches99/patches.ann',
       'menu99': 'src/menu99/menu.ann', 'stage2': 'src/stage2/stage2.ann', 'stage3': 'src/stage3/stage3.ann',
       'intro98': 'src/intro98/intro.ann', 'music99': 'src/music99/music.ann', 'pictures99': 'src/pictures99/pictures.ann'}
ENTRY = re.compile(r'^\$([0-9A-F]{4}) ([a-z]) (\S+)')


class Modules:
    """address -> module and entry of an .ann, as kit/mkgame.py cuts them: a module runs from the first entry after
    its @module line to the next module's start; an entry from its address to the next entry"""

    def __init__(self, part):
        self.rows, self.mods = [], []
        pending = None
        for line in open(os.path.join(ROOT, ANN[part]), encoding='utf-8'):
            if line.startswith('@module'):
                pending = line.split()[1]
                continue
            m = ENTRY.match(line)
            if m:
                a = int(m.group(1), 16)
                self.rows.append((a, m.group(3), m.group(2)))
                if pending:
                    self.mods.append((a, pending))
                    pending = None
        self.rows.sort()
        self.mods.sort()
        self.starts = [r[0] for r in self.rows]
        self.mod_starts = [m[0] for m in self.mods]

    def at(self, address):
        """(address, name, kind) of the entry holding address"""
        i = bisect_right(self.starts, address) - 1
        return self.rows[i] if i >= 0 else (address, f'${address:04X}', '?')

    def module(self, address):
        i = bisect_right(self.mod_starts, address) - 1
        return self.mods[i][1] if i >= 0 else None


def session(work):
    """The live MCP session of a re_session work folder (the control taken)"""
    import mcplib  # noqa: E402
    st = json.load(open(os.path.join(work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{st['port_base'] + 200}/mcp", st['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    return s


def memory_at(s, frame, t=0, offset=0, length=0x10000):
    """The Z80 view at (frame, t) of the loaded recording"""
    data = bytearray()
    for o in range(offset, offset + length, 0x4000):
        n = min(0x4000, offset + length - o)
        r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                   'offset': o, 'length': n}, ok=False)
        body = r.structured or {}
        if r.is_error or 'hex' not in body:
            raise SystemExit(f'memory_at {frame}:{t}: {r.text}')
        data += bytes.fromhex(body['hex'])
    return bytes(data)


def trace(work, f0, t0, f1, t1):
    """An access trace of the loaded recording (cached in WORK/traces), through kit/kitlib.py"""
    import kitlib as K  # noqa: E402

    class A:
        pass
    a = A()
    a.trace, a.work, a.window, a.max_cycles, a.unreal = None, work, f'{f0}:{t0}-{f1}:{t1}', None, UNREAL
    return K.load_trace(a)
