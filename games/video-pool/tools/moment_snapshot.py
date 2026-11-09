#!/usr/bin/env python3
"""A .z80 snapshot of any moment of a recording (the instance of WORK, started by this agent: it is seeked), with
optional POKEs: to start a clone run from the middle of play (exploration only).

    python3 tools/moment_snapshot.py --work work/stage1/c1 --at 5556:25555 --out work/snaps/entry.z80   # the entry $8000

The moment is the first instruction boundary at or after F:T (time_travel seek); the registers are those
inspect_state gives there; the memory is memory_at at the same moment.
"""
import argparse

import struct

import vplib as M


def z80(ram, regs, border=0):
    """A .z80 v1 file, uncompressed: the 30-byte header and the 48K RAM"""
    r = regs
    flags = ((r['r'] >> 7) & 1) | (border << 1)
    hdr = struct.pack('<BBHHHHBBBHHHHBBHHBBB', r['a'], r['f'], r['bc'], r['hl'], r['pc'], r['sp'], r['i'],
                      r['r'] & 0x7F, flags, r['de'], r['bc_'], r['de_'], r['hl_'], r['a_'], r['f_'], r['iy'],
                      r['ix'], 1, 1, r['im'])
    return hdr + ram


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--at', required=True)
    p.add_argument('--poke', action='append', default=[])
    p.add_argument('--out', required=True)
    args = p.parse_args()
    f, t = (int(x) for x in args.at.split(':'))
    s = M.session(args.work)
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    r = s.call('time_travel', {'action': 'seek', 'frame': f, 'tinframe': t}, ok=False)
    print(r.text.splitlines()[0])
    st = s.call('inspect_state', {'aspects': ['registers']}, ok=False).structured['registers']
    sp = st['special']
    t_at = sp['t']
    if st['interrupt']['halted']:
        raise SystemExit('the CPU is halted at this moment: pick another')
    ram = bytearray(M.read(s, f, 0x4000, 0xC000, t_at))
    for item in args.poke:
        k, v = item.split('=')
        a = int(k, 16)
        for i in range(0, len(v), 2):
            ram[a - 0x4000 + i // 2] = int(v[i:i + 2], 16)
    m, al, ix = st['main'], st['alternate'], st['index']
    regs = dict(a=m['af'] >> 8, f=m['af'] & 0xFF, bc=m['bc'], hl=m['hl'], de=m['de'], pc=sp['pc'], sp=sp['sp'],
                i=sp['i'], r=sp['r'], bc_=al['bc_'], de_=al['de_'], hl_=al['hl_'], a_=al['af_'] >> 8,
                f_=al['af_'] & 0xFF, iy=ix['iy'], ix=ix['ix'], im=st['interrupt']['im'])
    iff = st['interrupt']['iff1']
    data = bytearray(z80(bytes(ram), regs))
    data[27], data[28] = iff, st['interrupt']['iff2']
    open(args.out, 'wb').write(data)
    print('wrote', args.out, 'PC $%04X SP $%04X IM %d IFF %d at T %d' % (sp['pc'], sp['sp'], regs['im'], iff, t_at))


if __name__ == '__main__':
    main()
