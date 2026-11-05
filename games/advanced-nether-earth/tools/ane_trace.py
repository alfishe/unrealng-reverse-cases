#!/usr/bin/env python3
"""Shared helpers of the docR figures: an access trace of ANE's play read with the bank paged at $C000.

    python3 tools/ane_trace.py turns --trace work/docR/d1/traces/12300_0-12420_0.uatr
    python3 tools/ane_trace.py frames --trace ...

The trace (unreal-ng's `analysis trace`, the kit's cache) has no page per instruction, so the bank is followed
from the `$7FFD` writes in it (the first from the trace's page list). Each instruction is put in one phase of the
game's frame by its address and bank (the address ranges of the game's modules in play).

`turns` prints one line a game turn found in the trace: where it starts (the instruction after the turn pace), the
copy's start, the frames between, and the tear line of the frame the copy crosses. `frames` prints the T-states of
each phase in each frame (the interrupt, the radar, the music, the rest). Every T is the frame T: the T-state in the
emulator's frame as the trace stores it (the INT is at frame T -44, 71636 of the frame before).
"""
import argparse
import os
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

# Pentagon in unreal-ng (core/src/emulator/config.cpp, ApplyModelTimingDefaults): 320 lines of 224 T. A trace's T is
# the frame T, counted from the emulator's frame start, not from the interrupt: the INT rises at frame T 71636 of the
# frame before (intstart 71635 + 1), INT_T = -44, and the first paper pixel comes 17 988 T later, at frame T 17944.
FRAME_T, INT_T, PAPER_T, LINE_T = 71680, -44, 17944, 224

PHASES = [  # key, label, colour
    ('int', 'the interrupt: radar, clock count, shot sound', '#4caf50'),
    ('music', 'the interrupt: the music (bank 1 player)', '#26c6da'),
    ('world', 'ship, robots, shots, clock (the world turn)', '#5c8fd6'),
    ('draw', 'drawing the view in the buffer', '#c77ddb'),
    ('copy', 'copying the view to the screen', '#e5534b'),
    ('wait', 'waiting for the 10th interrupt (turn pace)', '#d9a441'),
    ('other', 'ROM, other', '#666a75'),
]
LABEL = {k: l for k, l, c in PHASES}
COLOUR = {k: c for k, l, c in PHASES}


def phase(pc, bank):
    if pc >= 0xC000 and bank == 1:
        return 'music'
    if 0xAE1D <= pc <= 0xAE27:
        return 'wait'
    if 0xD071 <= pc <= 0xD0B8:
        return 'copy'
    if 0xCCBD <= pc <= 0xD070:
        return 'draw'
    if 0xD566 <= pc <= 0xD5F7 or 0x6780 <= pc <= 0x67D9 or 0x6969 <= pc <= 0x696B:
        return 'int'
    if 0xA600 <= pc < 0xFD00 or 0x6980 <= pc < 0xA600:
        return 'world'
    return 'other'


def load(path, unreal=None):
    return K.access_trace(unreal).load(path)


def walk(trace):
    """(instruction, bank at $C000 when it ran, its phase). An interrupt is followed from the IM 2 jump at $6969
    until SP rises above the interrupted frame again: all of it is 'int', but the player in bank 1 'music'"""
    bank = trace.pages[-1] if trace.pages else 0
    int_sp = None
    for x in trace.instructions:
        if x.pc == 0x6969 and int_sp is None:
            int_sp = x.sp
        elif int_sp is not None and x.sp >= (int_sp + 2) & 0xFFFF and x.pc != 0x6969:
            int_sp = None
        ph = phase(x.pc, bank)
        if int_sp is not None and ph != 'music':
            ph = 'int'
        yield x, bank, ph
        for c in x.cycles:
            if c.tag == 'O' and c.address & 0x8002 == 0:
                bank = c.value & 7


def per_frame(trace):
    """frame -> Counter(phase -> T-states), from the gaps between instruction starts"""
    out = defaultdict(Counter)
    prev = None
    for x, bank, ph in walk(trace):
        if prev:
            px, pph = prev
            dt = (x.frame - px.frame) * FRAME_T + x.t - px.t
            out[px.frame][pph] += dt
        prev = (x, ph)
    return out


def shown_new(t_from_cf, line, col):
    """a byte written at t (frame T counted from the start of the copy's first frame) shows in the next frame when
    written before the beam fetched it there"""
    return t_from_cf <= FRAME_T + PAPER_T + line * LINE_T + 4 * col


def copy_writes(trace, cf):
    """[(frame T counted from the start of frame cf, screen line, column)] of the view copy's screen writes"""
    out = []
    for x, bank, ph in walk(trace):
        if ph != 'copy':
            continue
        for c in x.cycles:
            if c.tag in 'WE' and 0x4000 <= c.address < 0x5800:
                frame, t = trace.cycle_t(x, c)
                if not cf <= frame <= cf + 2:
                    continue
                out.append(((frame - cf) * FRAME_T + t, K.screen_line(c.address), c.address & 31))
    return out


def tear(writes, cf):
    """(the first screen line the beam reaches before the copy in the frame after cf (None: none), bytes new)"""
    # the frame the beam overtakes: try cf (beam pass of cf) and cf + 1
    for k in (0, 1):
        lines = defaultdict(list)
        for t, line, col in writes:
            lines[line].append(t <= k * FRAME_T + PAPER_T + line * LINE_T + 4 * col)
        firsts = [l for l in sorted(lines) if not all(lines[l])]
        started = [l for l in sorted(lines) if any(lines[l])]
        if firsts and started and started[0] < firsts[0]:
            return cf + k, firsts[0], sum(lines[firsts[0]])
    return None, None, None


def turns(trace):
    starts, copies = [], []
    prev_ph = None
    for x, bank, ph in walk(trace):
        if prev_ph == 'wait' and ph != 'wait' and ph not in ('int', 'music'):
            starts.append((x.frame, x.t))
        if ph == 'copy' and prev_ph != 'copy' and x.pc == 0xD071:
            copies.append((x.frame, x.t))
        if ph not in ('int', 'music'):
            prev_ph = ph
    return starts, copies


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('what', choices=['turns', 'frames'])
    p.add_argument('--trace', required=True)
    args = p.parse_args()
    trace = load(args.trace)
    if args.what == 'frames':
        pf = per_frame(trace)
        for f in sorted(pf):
            c = pf[f]
            print(f, ' '.join(f'{k}={c[k]}' for k, l, col in PHASES))
        return
    starts, copies = turns(trace)
    print('turn starts', starts)
    for cf, ct in copies:
        w = copy_writes(trace, cf)
        if len(w) < 3200:
            print(f'copy {cf}:{ct} cut off by the trace ({len(w)} writes)')
            continue
        f, line, new = tear(w, cf)
        print(f'copy {cf}:{ct} ends {cf + max(t for t, l, c in w) // FRAME_T}:{max(t for t, l, c in w) % FRAME_T}'
              f'  tear frame {f} line {line} ({new} of 20 new)')


if __name__ == '__main__':
    sys.exit(main())
