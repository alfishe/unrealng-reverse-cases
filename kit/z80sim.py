#!/usr/bin/env python3
"""SkoolKit's Z80 simulator for a case's tools, with the one trap of its C version spelled out: CSimulator works on
its own copy of the memory, so the bytes a run wrote are in `sim.memory`, never in the bytearray passed in (the pure
Python Simulator works in that bytearray itself). Read the result through what this module returns.

    import z80sim                                       # (kit/ on sys.path; SkoolKit found as kit/toolpaths.py does)
    mem, regs = z80sim.run(memory, 0x8ED6, 0, {'SP': 0x5F00})   # from $8ED6 until PC = 0 (a RET to a pushed 0)
    sim = z80sim.simulator(memory, {'PC': 0x8ED6})      # several runs on one simulator (the C one is set up once)
    sim.memory[0xFD30] = 5                              # poke between runs: sim.memory, not memory
    sim.run(0x8ED6, 0)
    print(sim.memory[0x8ED2])                           # the result: sim.memory

    python3 kit/z80sim.py --self-test                   # shows the copy: CSimulator's memory is not the input's

simulator() gives a CSimulator when the venv's SkoolKit has it (SkoolKit 9+, built with its C extension; about 50
times faster) and a Simulator otherwise (fast=False forces it); both have `.memory`, `.registers` (24 = PC, 12 = SP)
and `.run(start, stop)`. need_skoolkit() makes SkoolKit importable: this Python's own, else the venv's
site-packages when its Python is this one's version, else the tool runs again under the venv's Python.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def need_skoolkit():
    try:
        import skoolkit  # noqa: F401
        return
    except ImportError:
        pass
    if os.environ.get('KIT_Z80SIM_REEXEC'):
        sys.exit('z80sim: no SkoolKit (kit/toolpaths.py venv)')
    venv = subprocess.run([sys.executable, os.path.join(HERE, 'toolpaths.py'), 'venv'],
                          capture_output=True, text=True).stdout.strip()
    if not venv:
        sys.exit('z80sim: no SkoolKit venv (kit/toolpaths.py venv)')
    site = os.path.join(venv, 'lib', 'python%d.%d' % sys.version_info[:2], 'site-packages')
    if os.path.isdir(os.path.join(site, 'skoolkit')):
        sys.path.append(site)
        return
    os.environ['KIT_Z80SIM_REEXEC'] = '1'
    os.execv(os.path.join(venv, 'bin', 'python'), [os.path.join(venv, 'bin', 'python')] + sys.argv)


def simulator(memory, registers=None, fast=True, config=None):
    """a simulator over a copy (CSimulator) or over memory itself (Simulator): read and poke through sim.memory"""
    need_skoolkit()
    if fast:
        try:
            from skoolkit.csimulator import CSimulator
            return CSimulator(bytearray(memory), registers or {}, config=config)
        except ImportError:
            pass
    from skoolkit.simulator import Simulator
    return Simulator(memory if isinstance(memory, bytearray) else bytearray(memory), registers or {}, config=config)


def run(memory, start, stop, registers=None, fast=True):
    """(the memory after the run, the registers): from start until PC = stop, on a simulator of memory"""
    sim = simulator(memory, registers, fast)
    sim.run(start, stop)
    return sim.memory, sim.registers


def self_test():
    mem = bytearray(0x10000)
    mem[0x8000:0x8006] = bytes([0x3E, 0x55, 0x32, 0x00, 0x90, 0x76])  # LD A,$55; LD ($9000),A; HALT
    sim = simulator(mem, {'PC': 0x8000})
    sim.run(0x8000, 0x8005)
    kind = type(sim).__name__
    print(f'{kind}: the input bytearray at $9000 = ${mem[0x9000]:02X}, sim.memory at $9000 = '
          f'${sim.memory[0x9000]:02X} ({"a copy" if sim.memory is not mem else "the same bytearray"})')
    after, _ = run(mem, 0x8000, 0x8005)
    assert after[0x9000] == 0x55
    print('run(): the returned memory holds the write')


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-test']:
        self_test()
    else:
        print(__doc__)
