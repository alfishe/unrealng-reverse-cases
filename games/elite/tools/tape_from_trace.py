#!/usr/bin/env python3
"""The tape a recording saved, read back from the speaker writes of its access trace (docs/10-gameplay-logic.md 10.8).

    python3 tools/tape_from_trace.py TRACE OUT.tap [--dump]

SA-BYTES toggles the MIC bit (bit 3) of port $FE once an edge: the pilot's edges are 2168 T apart, the sync's 667
and 735, a 0 bit two edges of 855 T, a 1 bit two of 1710 (the ROM's timing, as unreal-ng plays it). The edges are
taken from the OUTs to an even port in the trace, timed by each OUT's bus cycle; the pilot is the first run of 2168s,
the data the edge pairs after the sync. The block (flag, data, parity) goes into a .tap with its length word, the
parity checked. --dump prints the edge-length histogram and the bytes.
"""
import argparse
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import elitelib as E  # noqa: E402


def edges(trace):
    """The T-state of every change of the MIC bit"""
    out, last = [], None
    for x in trace.instructions:
        for c in x.cycles:
            if c.tag == 'O' and not c.address & 1:
                mic = c.value & 0x08
                if last is not None and mic != last:
                    f, t = trace.cycle_t(x, c)
                    out.append(f * trace.frame_t + t)
                last = mic
    return out


def decode(times):
    gaps = [b - a for a, b in zip(times, times[1:])]
    i = 0
    while i < len(gaps) and not 2000 < gaps[i] < 2400:
        i += 1
    pilot = i
    while i < len(gaps) and 2000 < gaps[i] < 2400:
        i += 1
    pilot_edges = i - pilot
    i += 2                                # the two sync edges
    bits = []
    while i + 1 < len(gaps):
        a, b = gaps[i], gaps[i + 1]
        if a > 3000 or b > 3000:
            break
        bits.append(1 if a + b > 2565 else 0)
        i += 2
    data = bytes(int(''.join(map(str, bits[k:k + 8])), 2) for k in range(0, len(bits) - 7, 8))
    return pilot_edges, data, Counter(round(g, -1) for g in gaps)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('trace')
    p.add_argument('out')
    p.add_argument('--dump', action='store_true')
    args = p.parse_args()
    trace = E.K.access_trace().load(args.trace)
    pilot, block, hist = decode(edges(trace))
    parity = 0
    for b in block[:-1]:
        parity ^= b
    ok = block and parity == block[-1]
    print(f'pilot {pilot} edges; block {len(block)} bytes: flag ${block[0]:02X}, {len(block) - 2} data, parity '
          f'{"ok" if ok else "BAD"}')
    if args.dump:
        print('edge lengths:', sorted(hist.items(), key=lambda kv: -kv[1])[:8])
        for k in range(1, len(block) - 1, 16):
            print(f'  +${k - 1:02X}', block[k:k + 16].hex(' '))
    if not ok:
        raise SystemExit('the parity does not match: not a whole block')
    with open(args.out, 'wb') as f:
        f.write(len(block).to_bytes(2, 'little') + block)


if __name__ == '__main__':
    main()
