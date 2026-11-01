#!/usr/bin/env python3
"""Reads the round table of H.A.T.E. at chosen frames of a kept recording (docs/04-game-loop.md 4.2, 4.4).

The instance left running by autopilot.py --record holds the time-travel session: each frame is reached by seeking,
then the table $EF4F (6 bytes a round: the lives at the round's start, then SCORE as 5 characters), SCORE $EF49, the
round number $C2F7 and the lives $C2F9 are read.

    python3 roundtable.py --unreal <unreal-ng checkout> [--port-base 9780] 10630 10990 11880 11950
"""
import argparse
import os
import sys


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--unreal', required=True)
    p.add_argument('--port-base', type=int, default=9780)
    p.add_argument('frames', type=int, nargs='+')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import corpus  # noqa: E402
    from corpus import mcplib  # noqa: E402
    s = mcplib.Session(f'http://127.0.0.1:{args.port_base + 200}/mcp', '48K')
    m = corpus.Machine(s, args.port_base)
    for frame in args.frames:
        s.call('time_travel', {'action': 'seek', 'frame': frame}, ok=False)
        table = m.read(0xEF4F, 66)
        rounds = ', '.join(f'{k + 1}: {table[k * 6]} "{table[k * 6 + 1:k * 6 + 6].decode("latin1").strip()}"'
                           for k in range(10) if table[k * 6] != 0x20)
        print(f'{frame}: round {m.read(0xC2F7, 1)[0]} lives {m.read(0xC2F9, 1)[0]} '
              f'SCORE "{m.read(0xEF49, 5).decode("latin1").strip()}" table {rounds}')


if __name__ == '__main__':
    main()
