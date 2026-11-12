#!/usr/bin/env python3
"""The stage-1 input scripts (mm_session.py format: `FRAME KEYS`, `FRAME -` releases) for the recordings that start
from a stage's first state (an RZX snapshot taken at the stage's load, work/stage1/rzx/snapN.z80). Keys of the
original's default set: Q left, W right, I up (jump), J down, O fire.

    python3 tools/mkinputs.py            # writes tests/inputs/walk-right.txt, walk-left.txt, sj-walk-*.txt, idle.txt
"""
import os

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def walk(direction, frames, note, fire='O', up='I'):
    out = [f'# {note}']
    f = 200
    n = 0
    while f < frames - 100:
        out.append(f'{f} {direction} {fire}' if n % 3 == 0 else f'{f} {direction}')
        out.append(f'{f + 60} -')
        if n % 4 == 1:
            out.append(f'{f + 70} {up} {direction}')
            out.append(f'{f + 90} -')
        if n % 7 == 3:
            out.append(f'{f + 100} {fire} {up}')
            out.append(f'{f + 110} -')
        f += 120
        n += 1
    return '\n'.join(out) + '\n'


def main():
    d = os.path.join(CASE, 'tests', 'inputs')
    open(os.path.join(d, 'walk-right.txt'), 'w').write(walk(
        'W', 8000, 'walk-right: from a stage\'s first state, walk right for 8000 frames, fire every third step, a '
        'jump every fourth, fire upward now and then'))
    open(os.path.join(d, 'walk-left.txt'), 'w').write(walk(
        'Q', 8000, 'walk-left: the same towards the left'))
    # the RZX run's player chose SELECT JOYSTICK, Sinclair (the key readers `$FC90-$FCDA` read port `$EFFE`:
    # 6 left, 7 right, 8 down, 9 up, 0 fire), so the recordings from its snapshots use those keys
    open(os.path.join(d, 'sj-walk-right.txt'), 'w').write(walk(
        '7', 8000, 'sj-walk-right: walk-right with the Sinclair joystick keys (7 right, 9 up, 0 fire) the RZX run '
        'set', fire='0', up='9'))
    open(os.path.join(d, 'sj-walk-left.txt'), 'w').write(walk(
        '6', 8000, 'sj-walk-left: the same towards the left (6)', fire='0', up='9'))
    open(os.path.join(d, 'idle.txt'), 'w').write(
        '# idle: no key from a stage\'s first state; the enemies take the lives one by one up to the game over\n'
        '20000 -\n')


if __name__ == '__main__':
    main()
