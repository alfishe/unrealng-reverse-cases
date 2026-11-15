#!/usr/bin/env python3
"""Run kit/routine_anim.py on a slice of a kept trace: --slice F:T-F:T keeps only the instructions inside it.

    python3 tools/anim_slice.py --slice 1528:17500-1528:19300 --trace W/traces/1522_0-1534_0.uatr [routine_anim args]
"""
import os
import sys

KIT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit')
sys.path.insert(0, os.path.abspath(KIT))
argv = sys.argv[1:]
i = argv.index('--slice')
lo, _, hi = argv[i + 1].partition('-')
del argv[i:i + 2]
(f0, t0), (f1, t1) = (tuple(int(x) for x in s.split(':')) for s in (lo, hi))
import kitlib  # noqa: E402

load = kitlib.load_trace


def sliced(args):
    trace = load(args)
    units = max(1, trace.units_per_t)
    trace.instructions = [n for n in trace.instructions if (f0, t0) <= (n.frame, n.t // units) <= (f1, t1)]
    if trace.instructions:                    # the code panel's clock starts at the slice's first instruction
        first = trace.instructions[0]
        trace.from_frame, trace.from_t = first.frame, first.t
    return trace


kitlib.load_trace = sliced
sys.argv = [os.path.join(KIT, 'routine_anim.py')] + argv
import runpy  # noqa: E402
runpy.run_path(sys.argv[0], run_name='__main__')
