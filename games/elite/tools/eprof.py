#!/usr/bin/env python3
"""The runtime profile of a window of a recording, from its access trace (unreal-ng `analysis trace`).

Every instruction gets its routine (the `c` entry of src/game/game.ann it lies in; the ROM and the interrupt apart),
its cost in T-states (the next instruction's start minus its own, so a HALT and the interrupt's acknowledge count
where they happen) and its call stack. The stack is kept from the opcodes, not from SP: the game moves SP for its
fills (FillAttrs PUSHes over the attributes, the screens run on a stack in the back buffer), so a CALL is pushed
when the next instruction is its target, a RET pops back to the frame whose return address the new PC is, and an
accepted interrupt (the trace flags the handler's first instruction) pushes "IM2Handler" until its RETI.

    python3 tools/eprof.py --work work/f1 --window 2400:0-2500:0 [--out work/prof/f1-2400.json] [--top 30]

The JSON (read by the tools/fig_rt_*.py figures):

    frames        [first, last]          the trace's frames
    total_t       T-states traced
    routines      {name: {self, incl, calls, module}}
    frame_self    {name: [T a frame]}    per frame, for the routine x frame heatmap
    passes        [frame of each FlightLoop pass start]
    folded        {"A;B;C": T}           inclusive stacks (a flame graph)
    edges         {"A>B": T}             the T spent in B (and below) when called from A
    screen_writes [[t, address, routine]] writes to $4000-$5AFF, t from the trace start (the beam figures)
    port_out      [[t, port, value]]     OUT cycles (the beeper)
    calls         {name: [[t, T inclusive]]} for the routines named by --calls
    top_runs      [[t, T, routine]]      the bottom of the stack over time, run-length coded (with top_runs=True)
"""
import argparse
import json
import os
import re
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402

K = E.K
CASE = E.CASE
FLIGHT_LOOP = 0x7471


def entries():
    """[(address, kind, name, module)] of src/game/game.ann, sorted"""
    out, module = [], 'main'
    for line in open(os.path.join(CASE, 'src', 'game', 'game.ann')):
        m = re.match(r'^@module (\w+)', line)
        if m:
            module = m.group(1)
            continue
        m = re.match(r'^\$([0-9A-F]{4}) ([cbwts]) (\w+)', line)
        if m:
            out.append((int(m.group(1), 16), m.group(2), m.group(3), module))
    return sorted(out)


class Owners:
    """pc -> (routine, module)"""

    def __init__(self):
        self.list = entries()
        self.cache = {}
        self.module = {n: mod for _a, _k, n, mod in self.list}
        self.address = {n: a for a, _k, n, _m in self.list}

    def __call__(self, pc):
        if pc in self.cache:
            return self.cache[pc]
        if pc < 0x4000:
            r = 'ROM'
        else:
            r = 'other'
            lo, hi = 0, len(self.list)
            while lo < hi:
                mid = (lo + hi) // 2
                if self.list[mid][0] <= pc:
                    lo = mid + 1
                else:
                    hi = mid
            if lo:
                a, kind, name, _m = self.list[lo - 1]
                r = name if kind == 'c' else 'data:' + name
        self.cache[pc] = r
        return r


def opcode(x):
    """the fetched opcode bytes of an instruction"""
    return [c.value for c in x.cycles if c.tag == 'F']


def target(op, pc):
    """(kind, target) for CALL / RST / RET of the fetched bytes; kind None for the rest"""
    if not op:
        return None, None
    b = op[0]
    if b == 0xCD or (b & 0xC7) == 0xC4:
        if len(op) >= 3:
            return 'call', op[1] | op[2] << 8
        return 'call', None
    if (b & 0xC7) == 0xC7:
        return 'call', b & 0x38
    if b == 0xC9 or (b & 0xC7) == 0xC0:
        return 'ret', None
    if b == 0xED and len(op) > 1 and op[1] in (0x4D, 0x45, 0x55, 0x5D, 0x65, 0x6D, 0x75, 0x7D):
        return 'ret', None
    return None, None


def length(op):
    return len(op)


def profile(trace, calls_of=(), keep_screen=True, top_runs=False):
    own = Owners()
    ins = trace.instructions
    times = K.instruction_times(trace)
    total = times[-1] if times else 0
    f0 = trace.from_frame
    nframes = trace.to_frame - f0 + 1
    selft = defaultdict(int)
    inclt = defaultdict(int)
    ncalls = defaultdict(int)
    frame_self = defaultdict(lambda: [0] * nframes)
    folded = defaultdict(int)
    edges = defaultdict(int)
    passes = []
    screen = []
    ports = []
    call_log = defaultdict(list)
    open_calls = []  # (name, start t) for calls_of
    stack = []  # [routine, return address]
    runs = []
    for i, x in enumerate(ins):
        t = times[i]
        dt = (times[i + 1] - t) if i + 1 < len(ins) else 4
        if x.interrupted:
            ret = None
            if i:
                w = [c for c in ins[i - 1].cycles if c.tag == 'W']
                if len(w) >= 2:
                    ret = w[-2].value << 8 | w[-1].value
            stack.append(['IM2Handler', ret])
            ncalls['IM2Handler'] += 1
        r = own(x.pc)
        if x.halted:
            r = 'HALT'
        if x.pc == FLIGHT_LOOP:
            passes.append(x.frame)
        names = [s[0] for s in stack]
        selft[r] += dt
        fi = x.frame - f0
        if 0 <= fi < nframes:
            frame_self[r][fi] += dt
        # inclusive: each distinct routine on the stack and the current one
        chain = names + ([r] if not names or names[-1] != r else [])
        for n in set(chain):
            inclt[n] += dt
        folded[';'.join(chain)] += dt
        if top_runs:
            if runs and runs[-1][2] == chain[0]:
                runs[-1][1] += dt
            else:
                runs.append([t, dt, chain[0]])
        for a, b in zip(chain, chain[1:]):
            edges[a + '>' + b] += dt
        for c in x.cycles:
            if c.tag == 'W' and 0x4000 <= c.address < 0x5B00 and keep_screen:
                screen.append([t, c.address, r])
            elif c.tag == 'O':
                ports.append([t, c.address, c.value])
        # the next instruction decides the control flow
        op = opcode(x)
        kind, tgt = target(op, x.pc)
        nxt = ins[i + 1].pc if i + 1 < len(ins) else None
        if nxt is None:
            continue
        if kind == 'call' and nxt == tgt and not ins[i + 1].interrupted:
            callee = own(tgt)
            stack.append([callee, x.pc + len(op)])
            ncalls[callee] += 1
            if callee in calls_of:
                open_calls.append((callee, len(stack), t + dt))
        elif kind == 'ret' and nxt != x.pc + len(op) and not ins[i + 1].interrupted:
            for k in range(len(stack) - 1, -1, -1):
                if stack[k][1] == nxt:
                    while open_calls and open_calls[-1][1] > k:
                        name, _d, start = open_calls.pop()
                        call_log[name].append([start, t + dt - start])
                    del stack[k:]
                    break
    rout = {}
    for n in set(selft) | set(inclt):
        rout[n] = {'self': selft.get(n, 0), 'incl': inclt.get(n, 0), 'calls': ncalls.get(n, 0),
                   'module': own.module.get(n, 'rom' if n == 'ROM' else n.lower())}
    return {
        'frames': [f0, trace.to_frame],
        'total_t': total,
        'routines': rout,
        'frame_self': {n: v for n, v in frame_self.items()},
        'passes': passes,
        'folded': dict(folded),
        'edges': dict(edges),
        'screen_writes': screen,
        'port_out': ports,
        'calls': dict(call_log),
        'top_runs': runs,
    }


def load(work, window, unreal=None, max_cycles=None):
    import argparse as A
    return K.load_trace(A.Namespace(trace=None, work=work, window=window, max_cycles=max_cycles, unreal=unreal))


def cached(work, window, calls=(), out=None):
    """the profile of a window, computed once and kept in work/prof/"""
    name = out or os.path.join(CASE, 'work', 'prof', '%s-%s.json' % (os.path.basename(os.path.normpath(work)),
                                                                     window.replace(':', '_')))
    if os.path.isfile(name):
        return json.load(open(name))
    p = profile(load(work, window), calls_of=set(calls))
    os.makedirs(os.path.dirname(name), exist_ok=True)
    json.dump(p, open(name, 'w'))
    return p


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--window', required=True)
    ap.add_argument('--out')
    ap.add_argument('--calls', default='', help='comma-separated routines whose calls are logged')
    ap.add_argument('--top', type=int, default=25)
    a = ap.parse_args()
    p = cached(a.work, a.window, [c for c in a.calls.split(',') if c], a.out)
    tot = p['total_t']
    print('frames %d-%d, %d T, %d FlightLoop passes' % (p['frames'][0], p['frames'][1], tot, len(p['passes'])))
    rs = sorted(p['routines'].items(), key=lambda kv: -kv[1]['self'])
    print('%-24s %8s %6s %8s %6s %7s' % ('routine', 'self', '%', 'incl', '%', 'calls'))
    for n, v in rs[:a.top]:
        print('%-24s %8d %5.1f%% %8d %5.1f%% %7d' % (n, v['self'], 100 * v['self'] / tot, v['incl'],
                                                    100 * v['incl'] / tot, v['calls']))


if __name__ == '__main__':
    main()
