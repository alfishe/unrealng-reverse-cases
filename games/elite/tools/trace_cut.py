#!/usr/bin/env python3
"""Cut a window out of an access trace (unreal-ng `analysis trace`, read with its access_trace.py) into a new trace:
the memory at the window's first instruction, then the window's instructions and their bus cycles. The kit's
figure tools (routine_anim, writers_map, beam_timeline) then read one pass without tracing the recording again.

    python3 tools/trace_cut.py work/f1/traces/1500_0-1600_0.uatr 1504:0-1509:0 work/f1/traces/1504_0-1509_0.uatr

A moment is FRAME:T (the instruction's own frame and T-state); the window keeps the instructions from the first at or
after the start to the last before the end.
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402


def moment(text):
    f, _, t = text.partition(':')
    return int(f), int(t or 0)


def main():
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    src, window, out = sys.argv[1:]
    at = K.access_trace()
    trace = at.load(src)
    start, _, end = window.partition('-')
    a, b = moment(start), moment(end)
    units = max(1, trace.units_per_t)
    key = [(x.frame, x.t // units) for x in trace.instructions]
    first = next(i for i, k in enumerate(key) if k >= a)
    last = next((i for i, k in enumerate(key) if k >= b), len(key))
    memory = bytes(trace.memory_at(first))
    body = bytearray()
    cycles = 0
    for x in trace.instructions[first:last]:
        body += b'X' + at.INSTRUCTION.pack(x.frame, x.t, x.pc, x.sp, x.af, x.bc, x.de, x.hl, x.ix, x.iy, x.flags)
        for c in x.cycles:
            body += c.tag.encode() + at.CYCLE.pack(c.address, c.value, c.dt)
            cycles += 1
    header = at.HEADER.pack(at.MAGIC, 1, at.HEADER.size, a[0], a[1], trace.units_per_t, b[0], b[1], trace.frame_t,
                            last - first, cycles, 0)
    with open(out, 'wb') as f:
        f.write(header + struct.pack('<4H', *trace.pages) + memory + body)
    print(f'{out}: {last - first} instructions, {cycles} cycles, frames {a[0]}:{a[1]} .. {b[0]}:{b[1]}')


if __name__ == '__main__':
    main()
