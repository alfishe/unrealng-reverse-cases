#!/usr/bin/env python3
"""The length of each interrupt handler entry in a trace window, in T-states, however the handler leaves.

    python3 ../../kit/handler_time.py --trace work/c1/traces/16008_0-16015_0.uatr [--exit 6523] [--ann src/game/game.ann]
    python3 ../../kit/handler_time.py --work work/c1 --window 16008:0-16058:0 [--exit 6523] [--json OUT]

An entry starts at the instruction the trace flags as the first after an interrupt was taken (the handler's first;
the acknowledge, 13 T in IM 1 and 19 T in IM 2, comes before it and is not counted). It ends after the instruction
that hands the CPU back to the code it interrupted: the first instruction after which the PC is the interrupted
address (the word the interrupt pushed, read from the trace's memory at the entry's SP) and SP is back above that
word. That holds for RET / RETI / RETN and for a handler that returns by a patched `JP nn` (Enduro Racer `$643C`:
it copies the return address into the operand of the `JP` at `$6523`, takes its own stack and restores SP before
the jump). --exit ADDR (repeatable) ends an entry at that instruction instead (a handler that does not go back to
the interrupted address). An entry still running at the window's end is left out and counted.

The same handler measured by unreal-ng's `re_session.py interrupts` (kit/rs.py interrupts) is wrong when it leaves by
a JP: L1's inclusive count keeps running after the JP, through the main code, until a RET it can match (Enduro
Racer c1-play: 676 717 T an entry, "968.3 % of the CPU"). kit/rs.py interrupts prints the kit's own mean from the
same L1 beside it (11 357 T); this tool is the exact measure over a window (744 to 25 467 T in c1, frames 17945-17952).

Prints one line an entry (frame, T in the frame, length, how it left), then the count, the mean, the least and the
most, and the T-states an entry spent per routine (--ann: the .ann entries at or before each address; else per 256
bytes) over all entries. --json OUT writes the entries.
"""
import argparse
import json
import os
import re
import sys
from bisect import bisect_right

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib as K  # noqa: E402

ENTRY = re.compile(r'^\$([0-9A-Fa-f]{4}) [cbwts] (\w+)')


def ann_entries(paths):
    found = []
    for path in paths:
        for line in open(path, encoding='utf-8'):
            m = ENTRY.match(line)
            if m:
                found.append((int(m.group(1), 16), m.group(2)))
    found.sort()
    return found


def owner(entries, starts, a):
    if a < 0x4000:
        return 'ROM'
    if not entries:
        return f'${a & 0xFF00:04X}'
    i = bisect_right(starts, a) - 1
    return entries[i][1] if i >= 0 else f'${a & 0xFF00:04X}'


def measure(tr, exits=(), entries=()):
    """[{"frame", "t", "pc", "length", "exit", "how", "per": {routine: T}}] of the trace's interrupt entries, and
    the count of entries the window cut"""
    times = K.instruction_times(tr)
    starts = [a for a, _ in entries]
    ins = tr.instructions
    out, cut, k = [], 0, 0
    while k < len(ins):
        x = ins[k]
        if not x.interrupted:
            k += 1
            continue
        mem = tr.memory_at(k)
        sp = x.sp
        back = mem[sp] | mem[(sp + 1) & 0xFFFF] << 8  # the interrupted address the acknowledge pushed
        per, j, end, how = {}, k, None, None
        while j < len(ins):
            y = ins[j]
            if j > k and y.interrupted:
                break  # another interrupt before this one ended (interrupts enabled inside it)
            dt = times[j + 1] - times[j] if j + 1 < len(times) else 4
            name = owner(entries, starts, y.pc)
            per[name] = per.get(name, 0) + dt
            if y.pc in exits:
                end, how = j, f'--exit ${y.pc:04X}'
                break
            if j + 1 < len(ins):
                z = ins[j + 1]
                if z.pc == back and ((z.sp - sp) & 0xFFFF) in range(2, 0x100) and not z.interrupted:
                    fetch = next((c.value for c in y.cycles if c.tag == 'F'), None)
                    how = {0xC9: 'RET', 0xC3: f'JP ${back:04X} (patched)', 0xE9: 'JP (HL)'}.get(fetch)
                    if fetch == 0xED:
                        how = 'RETI/RETN'
                    end, how = j, how or f'to ${back:04X} by the instruction at ${y.pc:04X}'
                    break
            j += 1
        if end is None:
            cut += 1
            k = j if j > k else k + 1
            continue
        length = times[end + 1] - times[k] if end + 1 < len(times) else times[end] - times[k] + 4
        out.append({'frame': x.frame, 't': x.t // max(1, tr.units_per_t), 'pc': f'${x.pc:04X}',
                    'back': f'${back:04X}', 'exit': f'${ins[end].pc:04X}', 'how': how, 'length': length,
                    'per': per})
        k = end + 1
    return out, cut


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0], epilog=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    K.add_trace_args(p)
    p.add_argument('--exit', action='append', default=[], type=K.hex_address,
                   help='ADDR: an entry ends after the instruction at ADDR (repeatable)')
    p.add_argument('--ann', action='append', default=[], help='an .ann whose entries name the routines (repeatable)')
    p.add_argument('--json', help='write the entries to this file')
    p.add_argument('--quiet', action='store_true', help='the summary only, no line an entry')
    args = p.parse_args()
    tr = K.load_trace(args)
    entries = ann_entries(args.ann)
    found, cut = measure(tr, set(args.exit), entries)
    if not args.quiet:
        for e in found:
            print(f"frame {e['frame']} T {e['t']:6d}  {e['pc']} -> {e['exit']}  {e['length']:6d} T  {e['how']}")
    if not found:
        print('no interrupt entry ended in the window' + (f' ({cut} cut by its end)' if cut else ''))
        return 1
    lengths = [e['length'] for e in found]
    print(f'{len(found)} entries ({cut} cut by the window), mean {sum(lengths) / len(found):.0f} T, least '
          f'{min(lengths)}, most {max(lengths)}; window {tr.from_frame}:{tr.from_t}-{tr.to_frame}:{tr.to_t}')
    per = {}
    for e in found:
        for name, t in e['per'].items():
            per[name] = per.get(name, 0) + t
    for name, t in sorted(per.items(), key=lambda kv: -kv[1]):
        print(f'  {name:24s} {t / len(found):9.0f} T an entry  {100 * t / sum(lengths):5.1f}%')
    if args.json:
        with open(args.json, 'w') as f:
            json.dump({'window': f'{tr.from_frame}:{tr.from_t}-{tr.to_frame}:{tr.to_t}', 'cut': cut,
                       'entries': found}, f, indent=1)
    return 0


if __name__ == '__main__':
    sys.exit(main())
