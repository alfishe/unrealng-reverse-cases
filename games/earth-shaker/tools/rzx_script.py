#!/usr/bin/env python3
"""An RZX playthrough's input as an mm_session input script, so the play replays from the RZX's own start snapshot
with the TTD recording on (unreal-ng records no TTD history while an RZX plays).

    python3 tools/rzx_script.py work/stage1/rzx/earth01.ins.json --out tests/inputs/rzx-earth01.txt

The input is tools/rzx_inputs.py's log: every IN of the recording with its frame, PC, port and the value the RZX gave.
From it the keys held in each frame: a read of port `$xxFE` that selects one keyboard row tells which keys of that row
were down (a 0 bit), a read selecting several rows with no 0 bit tells that none of them was down; a read of port
`$xx1F` is the Kempston joystick (bits 0-4 right, left, down, up, fire). Between two reads that disagree the script
changes the state at the midpoint, so a replay whose read falls a frame or two away from the RZX's still sees the
same value. The game reads its controls once a pass (five or six frames in play), the ROM's interrupt scans the
whole keyboard each frame while interrupts are on (menus, the password prompt).
"""
import argparse
import json

ROWS = {0xFE: ['CS', 'Z', 'X', 'C', 'V'], 0xFD: ['A', 'S', 'D', 'F', 'G'], 0xFB: ['Q', 'W', 'E', 'R', 'T'],
        0xF7: ['1', '2', '3', '4', '5'], 0xEF: ['0', '9', '8', '7', '6'], 0xDF: ['P', 'O', 'I', 'U', 'Y'],
        0xBF: ['ENTER', 'L', 'K', 'J', 'H'], 0x7F: ['SPACE', 'SS', 'M', 'N', 'B']}
KEMPSTON = ['KR', 'KL', 'KD', 'KU', 'KF']


def observations(reads):
    """{key: [(frame, down)]} in frame order"""
    obs = {}
    for frame, _pc, port, value in reads:
        lo, hi = port & 0xFF, port >> 8
        if lo == 0x1F:
            for b, k in enumerate(KEMPSTON):
                obs.setdefault(k, []).append((frame, bool(value & 1 << b)))
        elif lo & 1 == 0:
            rows = [r for r in ROWS if not hi & (~r & 0xFF)]
            if len(rows) == 1:
                for b, k in enumerate(ROWS[rows[0]]):
                    obs.setdefault(k, []).append((frame, not value & 1 << b))
            elif value & 0x1F == 0x1F:
                for r in rows:
                    for k in ROWS[r]:
                        obs.setdefault(k, []).append((frame, False))
    return obs


def intervals(seq):
    """[(start, end, down)] covering frames, the state changing at the midpoint between disagreeing reads"""
    out = []
    state, since, last = seq[0][1], 0, seq[0][0]
    for frame, down in seq[1:]:
        if down != state:
            mid = (last + frame + 1) // 2
            out.append((since, mid, state))
            state, since = down, mid
        last = frame
    out.append((since, None, state))
    return out


def frame_keys(log):
    """[set of keys held] for each RZX frame of the log"""
    out = [set() for _ in range(log['frames'] + 1)]
    for key, seq in observations(log['reads']).items():
        for start, end, down in intervals(seq):
            if down:
                for f in range(start, len(out) if end is None else min(end, len(out))):
                    out[f].add(key)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('log')
    ap.add_argument('--out', required=True)
    ap.add_argument('--tail', type=int, default=50, help='frames run after the last RZX frame')
    args = ap.parse_args()
    d = json.load(open(args.log))
    events = {}
    for key, seq in observations(d['reads']).items():
        for start, end, down in intervals(seq):
            if down:
                events.setdefault(start, []).append(('+', key))
                if end is not None:
                    events.setdefault(end, []).append(('-', key))
    held, lines = set(), [f"# {d['rzx']}: {d['frames']} frames of someone else's RZX (tools/rzx_script.py)"]
    for frame in sorted(events):
        for op, key in events[frame]:
            (held.add if op == '+' else held.discard)(key)
        lines.append(f"{frame} {' '.join(sorted(held)) or '-'}")
    lines.append(f"{d['frames'] + args.tail} END")
    open(args.out, 'w').write('\n'.join(lines) + '\n')
    print(f'{args.out}: {len(lines)} lines, {d["frames"]} frames')


if __name__ == '__main__':
    main()
