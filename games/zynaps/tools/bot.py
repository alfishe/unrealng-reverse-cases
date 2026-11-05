#!/usr/bin/env python3
"""A simple Zynaps bot on a live instance: it reads the game's own records each step and steers the Kempston stick.

    python3 tools/bot.py --work W --snapshot S.szx --frames N --script OUT.txt [--log OUT.tsv] [--step 2]

The records it reads (WALKTHROUGH 6, docs/02-architecture.md):
  $F36C  the player's object record (44 bytes): +3/+4 X (fraction, integer), +5/+6 Y (fraction, integer)
  $F398  five enemy records of the same shape, +8 bit 7 = active
  $7F9C  player 1's record: +0..+3 the score (BCD, high byte first), +4 the lives left, +5 the level counter
The steering: fire pressed every other step (the game fires on a press), stay near X 24, in Y move away from an
active enemy close ahead, else towards the nearest one to shoot it, else back to Y 8, inside Y --top..--bottom; a move into a row whose
look-ahead on the screen holds more than --wall set pixels (the scenery) is replaced by the emptiest of the three. Writes every change of the held inputs as
an input script (re_session.py capture --inputs), so the run can be recorded again from the same snapshot.
"""
import argparse
import json
import os
import sys

import zynlib as Z

PLAYER, ENEMIES, P1 = 0xF36C, 0xF398, 0x7F9C


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--snapshot')
    p.add_argument('--frames', type=int, default=3000)
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--script', required=True)
    p.add_argument('--log')
    p.add_argument('--poke', action='append', default=[],
                   help='ADDR=HEX written after the snapshot loads (a clone: the immunity POKE 9B5F=C9 of ZYNAPS.POK)')
    p.add_argument('--shots', help='a folder: the screen every --shot-every frames')
    p.add_argument('--shot-every', type=int, default=50)
    p.add_argument('--x', type=int, default=24)
    p.add_argument('--y', type=int, default=8)
    p.add_argument('--wall', type=int, default=60)
    p.add_argument('--top', type=int, default=5)
    p.add_argument('--bottom', type=int, default=11)
    args = p.parse_args()
    s = Z.session(args.work)
    sys.path.insert(0, os.path.join(Z.K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import corpus  # noqa: E402
    port = json.load(open(os.path.join(args.work, 'session.json')))['port_base']
    m = corpus.Machine(s, port)
    if args.snapshot:
        m.post('/snapshot/load', {'path': os.path.abspath(args.snapshot)})
    for poke in args.poke:
        addr, data = poke.split('=')
        s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': '0x' + addr, 'hex': data})
    names = {'KF': 'fire', 'KL': 'left', 'KR': 'right', 'KU': 'up', 'KD': 'down'}
    held, script, log = set(), ['0 -'], []
    last_change = 0
    frame = 0
    fire = False
    while frame < args.frames:
        mem = m.read(0x7F9C, 0x30)
        obj = m.read(PLAYER, 44 * 6)
        px, py = obj[4], obj[6]
        lives, score = mem[4], ''.join(f'{b:02X}' for b in mem[0:4])
        want = set()
        fire = not fire
        if fire:
            want.add('KF')
        if px < args.x - 1:
            want.add('KR')
        elif px > args.x + 1:
            want.add('KL')
        scr = m.read(0x4000, 6144)

        def busy(y_cell):
            """set pixels ahead of the ship (x 2X+20..2X+84) if it were at Y = y_cell (the ship: about 2X-4..2X+16 by 8Y+8..8Y+24)"""
            if y_cell < 1 or y_cell > 14:
                return 10 ** 6
            n = 0
            for y in range(max(0, 8 * y_cell + 4), min(150, 8 * y_cell + 28)):
                row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
                for xb in range(max(0, (2 * px + 20) // 8), min(32, (2 * px + 84) // 8)):
                    b = scr[row + xb]
                    if b:
                        n += bin(b).count('1')
            return n

        threat, target = None, None
        for i in range(1, 6):
            r = obj[44 * i:44 * i + 44]
            if not r[8] & 0x80:
                continue
            dx, dy = r[4] - px, r[6] - py
            if -3 <= dx <= 10 and abs(dy) <= 2 and (threat is None or dx < threat[0]):
                threat = (dx, dy)
            if dx > 0 and (target is None or dx < target[0]):
                target = (dx, dy)
        if threat:
            move = 1 if threat[1] <= 0 else -1
        elif target and target[1] != 0 and args.top <= py + (1 if target[1] > 0 else -1) <= args.bottom:
            move = 1 if target[1] > 0 else -1
        else:
            move = (args.y > py) - (args.y < py)
        # the scenery: never into a row whose look-ahead is crowded (walls, the lattice), away from it if here is
        cost = {dy: busy(py + dy) + (10 ** 5 if not args.top <= py + dy <= args.bottom else 0) for dy in (-1, 0, 1)}
        if cost[move] > args.wall:
            move = min((c, abs(dy - move), dy) for dy, c in cost.items())[2]
        if move < 0:
            want.add('KU')
        elif move > 0:
            want.add('KD')
        if want != held:
            for k in held - want:
                s.call('joystick_input', {'action': 'release', 'buttons': names[k]}, ok=False)
            for k in want - held:
                s.call('joystick_input', {'action': 'press', 'buttons': names[k]}, ok=False)
            script.append(f'+{frame - last_change} ' + (' '.join(sorted(want)) or '-'))
            last_change = frame
            held = want
        s.call('control_execution', {'action': 'run_frames', 'frames': args.step})
        frame += args.step
        if args.shots and frame % args.shot_every == 0:
            os.makedirs(args.shots, exist_ok=True)
            img = bytearray(0x10000)
            img[0x4000:0x5B00] = m.read(0x4000, 6912)
            Z.K.render_screen(img).save(os.path.join(args.shots, f'{frame:06d}.png'))
        if frame % 50 == 0:
            log.append((frame, lives, score, px, py, mem[5]))
            print(frame, 'lives', lives, 'score', score, 'x', px, 'y', py, 'level', mem[5], flush=True)
    for k in held:
        s.call('joystick_input', {'action': 'release', 'buttons': names[k]}, ok=False)
    script.append(f'+{frame - last_change} -')
    script.append('+1 END')
    open(args.script, 'w').write('# tools/bot.py, from ' + (args.snapshot or 'the live state') + '\n' + '\n'.join(script) + '\n')
    if args.log:
        with open(args.log, 'w') as f:
            f.write('frame\tlives\tscore\tx\ty\tlevel\n')
            for row in log:
                f.write('\t'.join(map(str, row)) + '\n')


if __name__ == '__main__':
    main()
