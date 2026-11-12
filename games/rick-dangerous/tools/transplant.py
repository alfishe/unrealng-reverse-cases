#!/usr/bin/env python3
"""Carry the game state of the RZX run (a re-release build) into the original's memory: a warp point for our own
recordings of the original. Run with the SkoolKit venv's python (it reads and writes Z80 snapshots).

    $SKOOLKIT_VENV/bin/python3 tools/transplant.py --orig work/stage1/rzx/orig-menu-banks.bin \
        --rzx0 work/stage1/rzx/snap-00000.z80 --rzx work/stage1/rzx/h/snap-13500.z80 --out work/stage1/rzx/t/t-13500.z80

The re-release moved the code: the same game, with a few routines changed or added, so that from `$A13B` its
addresses run 10 bytes later and from `$E2D1` 25 bytes later (SHIFTS below; --map counts the bytes that agree
through it). `--orig` is the original's eight RAM banks read from our instance at the menu after the load, `--rzx0`
the RZX's first snapshot (its menu).

Each byte of the original's RAM then becomes:
- the RZX's byte at the mapped address, when the two builds agree there at the menu (the same code, table or
  variable), or when the RZX's byte changed since its menu (a variable the game wrote);
- the original's own byte otherwise (code or data the re-release changed: never carried over).

The registers are the RZX's, PC mapped back to the original (the snapshots are taken at the main loop's HALT, the
re-release's `$E428`, the original's `$E40F`, so no call chain is on the stack), I and the interrupt mode the
original's (`I` = `$83`, IM 2). The result is an experiment on a clone: every recording started from it says so,
and none of its bytes goes into the case's image.
"""
import argparse
import os
import sys

from skoolkit.snapshot import Snapshot, write_snapshot

ORIG_I = 0x83


def banks_of(snap):
    allr = bytes(snap.ram(-1))
    return [allr[n * 16384:(n + 1) * 16384] for n in range(8)]


def cpu_view(banks, page=0):
    return bytes(16384) + banks[5] + banks[2] + banks[page]


# The shift from an original address to the re-release's, piecewise: from each address on, until the next row.
# Taken from the address operands that differ between the two builds' aligned code (work/stage1/refmap.py: 1 129
# operand pairs, e.g. 285 references in `$A6AE-$AF64` all +10, 130 in `$E397-$EC77` all +25) and the places the
# re-release inserted or shortened code (a JP made a JR: one byte less).
SHIFTS = [(0x4000, 0), (0xA13B, 8), (0xA1A4, 10), (0xE2D1, 26), (0xE397, 25), (0xEC7E, 24), (0xEC90, 23),
          (0xEC9A, 22), (0xED2D, 21), (0xED32, 20), (0xF88C, 19), (0xFEFE, 0)]


def shift_of(addr):
    s = 0
    for start, sh in SHIFTS:
        if addr >= start:
            s = sh
    return s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--orig', required=True, help="the original's eight RAM banks at the menu (131072 bytes)")
    ap.add_argument('--rzx0', required=True)
    ap.add_argument('--rzx')
    ap.add_argument('--out')
    ap.add_argument('--map', action='store_true', help='print the shift runs and stop')
    a = ap.parse_args()
    ob = open(a.orig, 'rb').read()
    obanks = [ob[n * 16384:(n + 1) * 16384] for n in range(8)]
    r0 = Snapshot.get(a.rzx0)
    r0banks = banks_of(r0)
    ov, r0v = cpu_view(obanks), cpu_view(r0banks)
    shifts = [shift_of(x) for x in range(0x10000)]
    if a.map:
        same = sum(1 for x in range(0x5B00, 0x10000) if 0 <= x + shifts[x] <= 0xFFFF and ov[x] == r0v[x + shifts[x]])
        print(f'{same} of {0x10000 - 0x5B00} bytes of `$5B00-$FFFF` equal through the map at the menu')
        return
    rf = Snapshot.get(a.rzx)
    rfbanks = banks_of(rf)
    p7 = rf.header[35] if len(rf.header) > 35 else 0
    rfv = cpu_view(rfbanks, p7 & 7)
    r0v = cpu_view(r0banks, p7 & 7)
    new = [bytearray(b) for b in obanks]
    carried = kept = 0
    for addr in range(0x4000, 0x10000):
        b = addr + shifts[addr]
        if not 0x4000 <= b <= 0xFFFF:
            continue
        bank, off = (5, addr - 0x4000) if addr < 0x8000 else (2, addr - 0x8000) if addr < 0xC000 else (0, addr - 0xC000)
        if ov[addr] == r0v[b] or rfv[b] != r0v[b]:
            new[bank][off] = rfv[b]
            carried += 1
        else:
            kept += 1
    for n in (1, 3, 4, 6, 7):
        for off in range(16384):
            if obanks[n][off] == r0banks[n][off] or rfbanks[n][off] != r0banks[n][off]:
                new[n][off] = rfbanks[n][off]
    regs = {k: v for k, v in (x.split('=') for x in rf_registers(rf))}
    pc = int(regs['PC'])
    regs['PC'] = str(pc - next(s for addr, s in ((x, shifts[x]) for x in range(0x4000, 0x10000))
                               if addr + s == pc))
    regs['I'] = str(ORIG_I)
    registers = [f'{k}={v}' for k, v in regs.items()]
    state = [f'7ffd={p7}', 'iff=1', 'im=2', f'border={rf.header[12] >> 1 & 7}']
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    write_snapshot(a.out, [list(b) for b in new], registers, state, '128K')
    print(f'{a.out}: {carried} bytes from the RZX, {kept} kept, PC ${int(regs["PC"]):04X} (RZX ${pc:04X}), '
          f'SP ${int(regs["SP"]):04X}, 7FFD {p7:02X}')


def rf_registers(s):
    h = s.header
    w = lambda i: h[i] | h[i + 1] << 8  # noqa: E731
    pc = w(6) or w(32)
    return [f'A={h[0]}', f'F={h[1]}', f'BC={w(2)}', f'HL={w(4)}', f'SP={w(8)}', f'R={h[11] & 127 | (h[12] & 1) << 7}',
            f'DE={w(13)}', f'^BC={w(15)}', f'^DE={w(17)}', f'^HL={w(19)}', f'^A={h[21]}', f'^F={h[22]}',
            f'IY={w(23)}', f'IX={w(25)}', f'PC={pc}']


if __name__ == '__main__':
    sys.exit(main())
