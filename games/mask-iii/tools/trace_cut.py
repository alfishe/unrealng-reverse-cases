#!/usr/bin/env python3
"""Cut a window out of a kept access trace (unreal-ng `analysis trace`, `.uatr`), or list where a routine runs in it.

A routine animation (kit/routine_anim.py) slices its trace evenly in time. Over a window of whole frames a short
routine falls into few slices and most pictures show other code. Cut the trace down to the part of one pass that runs
the routine, then animate the cut:

    python3 tools/trace_cut.py work/docs/mxC/rzx-00000/traces/2515_0-2565_0.uatr --find BE0E
    python3 tools/trace_cut.py IN.uatr --from 2531:41000 --to 2531:47000 --out work/docs/fixB/penetrator.uatr
    python3 ../../kit/routine_anim.py --trace work/docs/fixB/penetrator.uatr ...

--find PC[,PC...] prints the frame:T of every instruction at those addresses (the routine's entry). The cut keeps the
instructions from --from up to --to; its start memory is the trace's start memory plus every write before the cut,
and its page at #C000 follows every OUT to #7FFD before the cut. The header's window and counts follow the cut.
"""
import argparse
import os
import struct
import sys

HEADER = struct.Struct('<4sHHQIIQIIQQB7x')
INSTRUCTION = struct.Struct('<IIHHHHHHHHB')
CYCLE = struct.Struct('<HBH')


def read(path):
    data = open(path, 'rb').read()
    fields = list(HEADER.unpack_from(data, 0))
    if fields[0] != b'UATR' or fields[1] != 1:
        raise SystemExit(f'{path}: not an access trace')
    at = fields[2]
    pages = data[at:at + 8]
    memory = data[at + 8:at + 8 + 0x10000]
    at += 8 + 0x10000
    records = []  # (instruction tuple, [(tag, address, value, dt)])
    while at < len(data):
        tag = data[at]
        at += 1
        if tag == 0x58:
            records.append((INSTRUCTION.unpack_from(data, at), []))
            at += INSTRUCTION.size
        else:
            records[-1][1].append((tag,) + CYCLE.unpack_from(data, at))
            at += CYCLE.size
    return fields, pages, memory, records


def moment(text):
    frame, _, t = text.partition(':')
    return int(frame), int(t or 0)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('trace')
    p.add_argument('--find', help='PC[,PC...]: list the moments these addresses run')
    p.add_argument('--from', dest='start', help='F:T, the first instruction kept (CPU T-states)')
    p.add_argument('--to', dest='end', help='F:T, the end of the cut (not kept)')
    p.add_argument('--out')
    a = p.parse_args()
    fields, pages, memory, records = read(a.trace)
    units, frame_t = max(1, fields[5]), fields[8]

    def when(x):
        t = x[1] // units
        return x[0] + t // frame_t, t % frame_t

    if a.find:
        wanted = {int(v, 16) for v in a.find.split(',')}
        for x, _ in records:
            if x[2] in wanted:
                f, t = when(x)
                print(f'{x[2]:04X} {f}:{t}')
        return 0
    if not (a.start and a.end and a.out):
        raise SystemExit('give --find, or --from, --to and --out')
    lo, hi = moment(a.start), moment(a.end)
    mem = bytearray(memory)
    page = list(struct.unpack('<4H', pages))
    kept = []
    for x, cycles in records:
        w = when(x)
        if w < lo:
            for tag, address, value, _ in cycles:
                if tag in (ord('W'), ord('E')):
                    mem[address] = value
                elif tag == ord('O') and address & 0xC002 == 0x4000:
                    page[3] = value & 7
        elif w < hi:
            kept.append((x, cycles))
    if not kept:
        raise SystemExit('no instruction in the cut')
    first = kept[0][0]
    fields[3], fields[4] = first[0], first[1]
    fields[6], fields[7] = hi[0], hi[1] * units
    fields[9] = len(kept)
    fields[10] = sum(len(c) for _, c in kept)
    fields[11] = 0
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with open(a.out, 'wb') as out:
        head = HEADER.pack(*fields)
        out.write(head + b'\0' * (fields[2] - len(head)))
        out.write(struct.pack('<4H', *page))
        out.write(bytes(mem))
        for x, cycles in kept:
            out.write(b'X' + INSTRUCTION.pack(*x))
            for c in cycles:
                out.write(bytes([c[0]]) + CYCLE.pack(*c[1:]))
    print(f'{a.out}: {len(kept)} instructions, {fields[3]}:{fields[4] // units}-{hi[0]}:{hi[1]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
