#!/usr/bin/env python3
"""Cut an access trace (.uatr loaded by the kit) to the instructions between the first and the last whose PC
lies in LO-HI (plus MARGIN instructions each side), the memory brought forward over the skipped writes, and run
kit/routine_anim.py on it (MAP_NOTE in the environment is added to the memory map's label). Usage: anim_cut.py TRACE LO-HI MARGIN -- routine_anim args (without --trace)."""
import os, sys
KIT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit')
sys.path.insert(0, os.path.abspath(KIT))
import kitlib as K  # noqa: E402

trace_path, rng, margin = sys.argv[1], sys.argv[2], int(sys.argv[3])
rest = sys.argv[sys.argv.index('--') + 1:]
lo, hi = (int(x, 16) for x in rng.split('-'))
real = K.load_trace


def cut(args):
    t = real(type('A', (), {'unreal': None, 'trace': trace_path})())
    ins = t.instructions
    idx = [i for i, x in enumerate(ins) if lo <= x.pc <= hi]
    a, b = max(0, idx[0] - margin), min(len(ins), idx[-1] + 1 + margin)
    mem = bytearray(t.memory)
    for x in ins[:a]:
        for c in x.cycles:
            if c.tag in 'WE':
                mem[c.address] = c.value
    t.memory = bytes(mem)
    t.instructions = ins[a:b]
    t.from_frame, t.from_t = ins[a].frame, ins[a].t      # the pictures' frame and T stay true
    print(f'cut: instructions {a}-{b} of {len(ins)}')
    return t


K.load_trace = cut
sys.argv = ['routine_anim.py', '--trace', trace_path] + rest
import importlib.util  # noqa: E402
spec = importlib.util.spec_from_file_location('routine_anim', os.path.join(os.path.abspath(KIT), 'routine_anim.py'))
ra = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ra)
NOTE = os.environ.get('MAP_NOTE')
if NOTE:
    old = ra.panel_labels
    ra.panel_labels = lambda view, lo, hi: [f'memory ${lo:04X}-${hi:04X} {NOTE}'] + old(view, lo, hi)[1:]
ra.main()
