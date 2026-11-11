#!/usr/bin/env python3
"""A scripted play from a cave-start snapshot, written as an input script with one line a frame (the same split as
tools/rzx_align.py's, so re_session.py capture reaches the same states), for the deaths and rules no RZX shows.

    python3 tools/move_script.py --snapshot work/stage1/probe/level1.szx --moves Q,Q,A --tail 300 \
        --out tests/inputs/death-crush.txt [--port-base 37120]

From the snapshot the instance runs with no key until a pass of the cave has started (KeyMoved `$FD80` drops to 0,
PlayCave `$8885`). Then each move is one key held until the player has moved (PlayerIndex `$FD9C` changes) or is
killed (PlayerKilled `$7FFD` = `$FF`), then released: the game reads its controls once a pass, so a key held a fixed
number of frames would move the player one or two cells as the pass lengths fall. After the last move the script
runs --tail frames with no key. Keys are the case's names: O P Q A M (the default keys, keyboard) or KL KR KU KD KF
(the Kempston stick, the RZX snapshots' choice). A move `-N` waits N frames with no key.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lab import Lab  # noqa: E402

KEY_MOVED, PLAYER, KILLED, LIVES = 0xFD80, 0xFD9C, 0x7FFD, 0xFD93


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--snapshot', required=True)
    ap.add_argument('--moves', required=True, help='comma separated keys, -N waits N frames')
    ap.add_argument('--tail', type=int, default=300)
    ap.add_argument('--out', required=True)
    ap.add_argument('--port-base', type=int, default=37120)
    ap.add_argument('--limit', type=int, default=40, help='frames a key may be held before the move counts as blocked')
    a = ap.parse_args()
    lab = Lab(a.port_base)
    lines, log = [], []

    def step(keys):
        lab.keys(keys)
        lines.append(f"{len(lines)} {' '.join(keys) or '-'}")
        lab.run(1)

    def word(addr):
        b = lab.read(addr, 2)
        return b[0] | b[1] << 8

    try:
        lab.load(a.snapshot)
        for _ in range(2000):  # into play: the first pass clears KeyMoved
            step([])
            if lab.read(KEY_MOVED, 1)[0] == 0:
                break
        log.append(f'play from frame {len(lines)}, player {word(PLAYER)}, lives {lab.read(LIVES, 1)[0]}')
        for mv in a.moves.split(','):
            if mv.startswith('-'):
                for _ in range(int(mv[1:])):
                    step([])
                continue
            before, start = word(PLAYER), len(lines)
            while len(lines) - start < a.limit:
                step([mv])
                if word(PLAYER) != before or lab.read(KILLED, 1)[0] == 0xFF:
                    break
            log.append(f'{mv}: frames {start}-{len(lines) - 1}, player {before} -> {word(PLAYER)}, '
                       f'killed {lab.read(KILLED, 1)[0]:#04x}')
        lives = lab.read(LIVES, 1)[0]
        for _ in range(a.tail):
            step([])
        log.append(f'tail to frame {len(lines)}: lives {lives} -> {lab.read(LIVES, 1)[0]}, player {word(PLAYER)}')
        lab.keys([])
    finally:
        lab.close()
    head = [f'# {a.snapshot}: moves {a.moves}, then {a.tail} frames with no key (tools/move_script.py), one line a frame']
    head += ['# ' + x for x in log]
    open(a.out, 'w').write('\n'.join(head + lines + [f'{len(lines)} END']) + '\n')
    print('\n'.join(log))


if __name__ == '__main__':
    main()
