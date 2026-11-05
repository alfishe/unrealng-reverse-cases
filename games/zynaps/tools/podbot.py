#!/usr/bin/env python3
"""A Zynaps bot that takes the weapons: it scoops pods to move the selector and holds fire on the pod it wants.

    python3 tools/podbot.py --work W --snapshot S.szx --frames N --script OUT.txt --log OUT.tsv [--plan 0,1,2,2,3,4]

The rule it plays by (PodStep `$A1FD`): a pod scooped with fire held for 8 passes or more (FireHeld `$8184`) runs
the pod action the selector (player record +7) points at and sets the selector to 0; a pod scooped without fire
moves the selector on by one. --plan lists the selector values to take, in order (0 speed, 1 laser, 2 plasma, a
second 2 the double plasma, 3 homing missiles, 4 seeker). After the plan it keeps playing with --after frames.

The records it reads each step: the player record `$7F9C` (+7 selector, +8 side weapon, +9 double, +$0A laser, +$0B
speed), Fuel `$80E6`, FireHeld `$8184`, the ship `$F36C` and the five enemy slots `$F398` (+7 the kind, 4 = a pod;
+8 bit 7 active; +4 X, +6 Y). The fire pattern away from pods: held up to 6 passes and let go (a press and a
release each fire a laser, plasma leaves at 3 passes, the seeker at 7 when the pattern is --long). Every change of
the held inputs goes into an input script for re_session.py capture --inputs, so the run is recorded again from
the same snapshot.
"""
import argparse
import json
import os
import sys

import zynlib as Z

PLAYER, ENEMIES, P1 = 0xF36C, 0xF398, 0x7F9C
NAMES = {'KF': 'fire', 'KL': 'left', 'KR': 'right', 'KU': 'up', 'KD': 'down'}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--snapshot')
    p.add_argument('--frames', type=int, default=20000)
    p.add_argument('--after', type=int, default=1500, help='frames played after the plan is done')
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--plan', default='0,1,2,2,3,4')
    p.add_argument('--hold', type=int, default=6, help='passes fire is held away from pods')
    p.add_argument('--script', required=True)
    p.add_argument('--log', required=True)
    p.add_argument('--x', type=int, default=24)
    p.add_argument('--y', type=int, default=8)
    p.add_argument('--record', help='a work folder: record the run of the bot itself there (TTD + L1, as re_session.py '
                   'capture leaves it), so no replay of the input script can drift from it')
    args = p.parse_args()
    plan = [int(v) for v in args.plan.split(',')]
    s = Z.session(args.work)
    sys.path.insert(0, os.path.join(Z.K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import corpus  # noqa: E402
    port = json.load(open(os.path.join(args.work, 'session.json')))['port_base']
    m = corpus.Machine(s, port)
    if args.snapshot:
        m.post('/snapshot/load', {'path': os.path.abspath(args.snapshot)})
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)
    if args.record:
        os.makedirs(args.record, exist_ok=True)
        json.dump(json.load(open(os.path.join(args.work, 'session.json'))), open(os.path.join(args.record, 'session.json'), 'w'))
        m.post('/snapshot/save', {'path': os.path.abspath(os.path.join(args.record, 'start.szx')), 'force': True})
        open(os.path.join(args.record, 'start.bin'), 'wb').write(m.read(0, 0x10000))
        s.call('analysis', {'action': 'start', 'record': True})
    held, script, log = set(), ['0 -'], []
    last_change, frame, done_at, step_no = 0, 0, None, 0
    taken = []
    prev = None
    while frame < args.frames and (done_at is None or frame < done_at + args.after):
        rec = m.read(P1, 0x10)
        var = m.read(0x80E0, 0x10)
        fire_held = m.read(0x8184, 1)[0]
        obj = m.read(PLAYER, 44 * 6)
        sel, weapon, double, laser, speed = rec[7], rec[8], rec[9], rec[10], rec[11]
        fuel = var[6]
        state = (weapon, double, laser, speed)
        if prev is not None and state != prev[0]:
            taken.append(frame)
        px, py = obj[4], obj[6]
        pods, enemies = [], []
        for i in range(1, 6):
            r = obj[44 * i:44 * i + 44]
            if not r[8] & 0x80:
                continue
            (pods if r[7] == 4 else enemies).append((r[4], r[6]))
        goal = plan[0] if plan else None
        want = set()
        pod = None
        if pods and goal is not None:
            pod = min(pods, key=lambda q: abs(q[0] - px) + abs(q[1] - py))
        if pod:
            arm = sel == goal
            if arm:
                want.add('KF')          # held: the pod runs the selected action
            tx, ty = pod
            tx = max(17, min(44, tx))
            if px < tx - 1:
                want.add('KR')
            elif px > tx:
                want.add('KL')
            if py < ty:
                want.add('KD')
            elif py > ty:
                want.add('KU')
        else:
            if fire_held < args.hold:
                want.add('KF')
            if px < args.x - 1:
                want.add('KR')
            elif px > args.x + 1:
                want.add('KL')
            target = None
            for ex, ey in enemies:
                dx = ex - px
                if dx > 0 and (target is None or dx < target[0]):
                    target = (dx, ey - py)
            if target and target[1]:
                want.add('KD' if target[1] > 0 else 'KU')
            elif py != args.y:
                want.add('KD' if py < args.y else 'KU')
            if py <= 3:
                want.discard('KU')
            if py >= 13:
                want.discard('KD')
        if want != held:
            for k in held - want:
                s.call('joystick_input', {'action': 'release', 'buttons': NAMES[k]}, ok=False)
            for k in want - held:
                s.call('joystick_input', {'action': 'press', 'buttons': NAMES[k]}, ok=False)
            script.append(f'+{frame - last_change} ' + (' '.join(sorted(want)) or '-'))
            last_change = frame
            held = want
        s.call('control_execution', {'action': 'run_frames', 'frames': args.step})
        frame += args.step
        step_no += 1
        after = m.read(P1, 0x10)
        if plan and (after[8], after[9], after[10], after[11]) != (weapon, double, laser, speed) and after[7] == 0 \
                and sel == goal:
            print(f'frame {frame}: action {goal} taken: weapon {after[8]} double {after[9]} laser {after[10]} '
                  f'speed {after[11]:02X}', flush=True)
            plan.pop(0)
            if not plan:
                done_at = frame
        elif plan and goal == 0 and sel == 0 and after[7] == 0 and after[11] == speed and pods and pod \
                and m.read(0x80E6, 1)[0] == 0xBB and fuel != 0xBB:
            print(f'frame {frame}: speed pod at the top speed (fuel refilled)', flush=True)
            plan.pop(0)
            if not plan:
                done_at = frame
        prev = (state,)
        log.append((frame, sel, after[8], after[9], after[10], after[11], m.read(0x80E6, 1)[0], fire_held,
                    ''.join(f'{b:02X}' for b in after[0:4]), px, py, len(pods), rec[6]))
        if frame % 500 == 0:
            print(frame, 'sel', sel, 'weapon', after[8], 'double', after[9], 'laser', after[10], f'speed {after[11]:02X}',
                  'fuel', fuel, 'pods', len(pods), 'plan', plan, flush=True)
    for k in held:
        s.call('joystick_input', {'action': 'release', 'buttons': NAMES[k]}, ok=False)
    script.append(f'+{frame - last_change} -')
    script.append('+1 END')
    if args.record:
        import time
        rec = os.path.abspath(args.record)
        s.call('analysis', {'action': 'build', 'path': os.path.join(rec, 'l1.json'), 'wait': 30000})
        while ': running' in s.call('analysis', {'action': 'status'}).text:
            time.sleep(5)
        status = s.call('analysis', {'action': 'status'}).text.splitlines()
        dumped = s.call('time_travel', {'action': 'dump', 'path': os.path.join(rec, 'session.ttd')}, ok=False)
        json.dump({'model': '48K', 'ranges': '5B00-FFFF', 'frames': frame, 'status': status,
                   'ttd': (dumped.text or '').splitlines()[:1], 'snapshot': args.snapshot},
                  open(os.path.join(rec, 'capture.json'), 'w'), indent=1)
        print('recorded', frame, 'frames;', status[-1] if status else '', flush=True)
    open(args.script, 'w').write('# tools/podbot.py, from ' + (args.snapshot or 'the live state') + '\n'
                                 + '\n'.join(script) + '\n')
    with open(args.log, 'w') as f:
        f.write('frame\tselector\tweapon\tdouble\tlaser\tspeed\tfuel\tfireheld\tscore\tx\ty\tpods\tlevel\n')
        for row in log:
            f.write('\t'.join(map(str, row)) + '\n')


if __name__ == '__main__':
    main()
