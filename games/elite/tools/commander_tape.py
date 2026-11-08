#!/usr/bin/env python3
"""Read or write Elite's commander tape: one headerless block (flag $FF) of the 102-byte record $D054-$D0B9.

    python3 tools/commander_tape.py show IN.tap
    python3 tools/commander_tape.py edit IN.tap OUT.tap [--name N] [--cash CR] [--equip all] [--lasers 3,2,4,1]
            [--missiles N] [--fuel LY] [--hold i=t,...] [--jumps N] [--galaxy-from OTHER.tap] [--score N] [--legal N]
            [--mission N] [--flags N]

The layout (docs/10-gameplay-logic.md 10.8, the offsets from $D054): +$00 the name (10 letters and a 0), +$0B the
legal status, +$0C the combat score (three bytes, low first), +$0F the jumps, +$11 the galaxy, +$12 the cash (two
words: thousands of credits, then tenths below 10000), +$16 the fluctuation, +$17 the hold (17), +$28 the free
space, +$29 the lasers (4), +$2D the nova mission, +$2E the fuel, +$2F the missiles, +$30 the equipment (10 flags,
$FF fitted), +$3A the galaxy's and the system's seeds, +$4A the stock (17), +$5B the mission state, +$5C the
mission flags, +$5D the sun's position (9). The game checks nothing but the tape's parity, so an edited record
loads as a saved one; `edit` is how the case's later recordings get their commanders (each named in its plan).
"""
import argparse
import sys

GOODS = ['Food', 'Textiles', 'Radioactives', 'Slaves', 'Liquor/Wines', 'Luxuries', 'Narcotics', 'Computers',
         'Machinery', 'Alloys', 'Firearms', 'Furs', 'Minerals', 'Gold', 'Platinum', 'Gem-Stones', 'Alien Items']
EQUIP = ['large cargo bay', 'E.C.M.', 'spare', 'spare', 'fuel scoops', 'escape pod', 'energy bomb', 'energy unit',
         'docking computers', 'galactic hyperdrive']


def read(path):
    data = open(path, 'rb').read()
    n = int.from_bytes(data[0:2], 'little')
    block = data[2:2 + n]
    if n != 104 or block[0] != 0xFF:
        sys.exit(f'{path}: not a commander block (length {n}, flag ${block[0]:02X})')
    return bytearray(block[1:-1])


def write(path, r):
    block = bytes([0xFF]) + bytes(r)
    p = 0
    for b in block:
        p ^= b
    open(path, 'wb').write((len(block) + 1).to_bytes(2, 'little') + block + bytes([p]))


def cash(r):
    return (r[0x12] | r[0x13] << 8) * 10000 + (r[0x14] | r[0x15] << 8)


def show(r):
    print('name', bytes(r[0:10]).decode('latin-1').rstrip('\0 '), '| legal', r[0x0B], '| score',
          r[0x0C] | r[0x0D] << 8 | r[0x0E] << 16, '| jumps', r[0x0F], '| galaxy', r[0x11])
    print(f'cash {cash(r) / 10:.1f} Cr | fuel {r[0x2E] / 10:.1f} ly | missiles {r[0x2F]} | lasers {list(r[0x29:0x2D])}'
          f' | free {r[0x28]} t | nova {r[0x2D]} | mission {r[0x5B]} flags ${r[0x5C]:02X}')
    print('hold', {g: r[0x17 + i] for i, g in enumerate(GOODS) if r[0x17 + i]})
    print('equipment', [EQUIP[i] for i in range(10) if r[0x30 + i]])
    print('seeds', bytes(r[0x3A:0x4A]).hex(' '), '| stock', list(r[0x4A:0x5B]), '| sun', bytes(r[0x5D:0x66]).hex(' '))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('mode', choices=['show', 'edit'])
    p.add_argument('src')
    p.add_argument('out', nargs='?')
    p.add_argument('--name')
    p.add_argument('--cash', type=float)
    p.add_argument('--equip')
    p.add_argument('--lasers')
    p.add_argument('--missiles', type=int)
    p.add_argument('--fuel', type=float, help='light years, 0.0-7.0')
    p.add_argument('--hold')
    p.add_argument('--jumps', type=int)
    p.add_argument('--score', type=int)
    p.add_argument('--legal', type=int)
    p.add_argument('--mission', type=int, help='the mission state (+$5B)')
    p.add_argument('--flags', type=lambda v: int(v, 0), help='the mission flags (+$5C)')
    p.add_argument('--galaxy-from', help='take the galaxy, the seeds, the stock and the sun from another save')
    args = p.parse_args()
    r = read(args.src)
    if args.mode == 'show':
        show(r)
        return
    if args.name:
        r[0:11] = args.name.upper().encode()[:10].ljust(10, b' ') + b'\0'
    if args.cash is not None:
        t = round(args.cash * 10)
        k, t = divmod(t, 10000)
        r[0x12:0x16] = bytes([k & 0xFF, k >> 8, t & 0xFF, t >> 8])
    if args.equip == 'all':
        for i in (0, 1, 4, 5, 6, 7, 8, 9):
            r[0x30 + i] = 0xFF
        r[0x28] = 35 - sum(r[0x17:0x17 + 13])
    if args.lasers:
        r[0x29:0x2D] = bytes(int(v) for v in args.lasers.split(','))
    if args.fuel is not None:
        r[0x2E] = round(args.fuel * 10)
    if args.missiles is not None:
        r[0x2F] = args.missiles
    if args.hold:
        for item in args.hold.split(','):
            i, t = item.split('=')
            r[0x17 + int(i)] = int(t)
        r[0x28] = (35 if r[0x30] else 20) - sum(r[0x17:0x17 + 13])
    if args.jumps is not None:
        r[0x0F] = args.jumps
    if args.score is not None:
        r[0x0C:0x0F] = args.score.to_bytes(3, 'little')
    if args.legal is not None:
        r[0x0B] = args.legal
    if args.mission is not None:
        r[0x5B] = args.mission
    if args.flags is not None:
        r[0x5C] = args.flags
    if args.galaxy_from:
        o = read(args.galaxy_from)
        r[0x11] = o[0x11]
        r[0x3A:0x5B] = o[0x3A:0x5B]
        r[0x5D:0x66] = o[0x5D:0x66]
    write(args.out, r)
    show(r)


if __name__ == '__main__':
    main()
