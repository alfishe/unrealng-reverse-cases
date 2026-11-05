#!/usr/bin/env python3
"""A Zynaps GS bot that takes the weapons, on a live gs_session.py instance (the 48K case's tools/podbot.py, moved
onto gs_session.Live and given a frame log of its own).

    python3 tools/gs_podbot.py --work W --frames N --out PREFIX [--plan 0,1,2,2,3,4] [--count ADDR,...]

The rule it plays by (PodStep `$A1FD`): a pod scooped with fire held for 8 passes or more (FireHeld `$8184`) runs
the pod action the selector (player record +7) points at and sets the selector to 0; a pod scooped without fire
moves the selector on by one. --plan lists the selector values to take, in order (0 speed, 1 laser, 2 plasma, a
second 2 the double plasma, 3 homing missiles, 4 seeker). After the plan it keeps playing (--after frames, or up
to --frames).

It starts from the instance's present state (a game running: gs_session.py steps has done the menu and the title)
and reads every --step frames: the player record `$7F9C` (+4 lives, +6 the level index, +7 selector, +8 side
weapon, +9 double, +$0A laser, +$0B speed), Fuel `$80E6`, FireHeld `$8184`, LevelOrder `$8003`, the 16 object
records `$F36C-$F62B` (read from RAM page 0, so a driver call that has bank 1 paged cannot spoil them) and the
screen (`$4000`, 6912 bytes). Away from pods it fires in bursts of --hold passes and follows the nearest enemy's
row; with a homing missile armed it holds fire while the sight has a lock (`$80E2` not 0) so HomingFrame `$9CCA`
can launch.

--count: Z80 addresses whose executions the memory profiler counts (kinds x); read at every level change and at
the end (PREFIX-counts.json). Out: PREFIX.npz (the frame log: frames, vars, objs, screen), PREFIX.tsv (one row a
step), PREFIX-script.txt (the input changes, re_session.py's script format), PREFIX-events.txt (each weapon
taken, each level change).
"""
import argparse
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gs_session as g  # noqa: E402

P1, OBJ, NOBJ = 0x7F9C, 0xF36C, 16
NAMES = {'KF': 'fire', 'KL': 'left', 'KR': 'right', 'KU': 'up', 'KD': 'down'}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--frames', type=int, default=9000)
    p.add_argument('--after', type=int, default=0, help='frames played after the plan is done (0: up to --frames)')
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--plan', default='0,1,2,2,3,4')
    p.add_argument('--hold', type=int, default=6, help='passes fire is held away from pods')
    p.add_argument('--out', required=True)
    p.add_argument('--count', default='')
    p.add_argument('--x', type=int, default=24)
    p.add_argument('--y', type=int, default=8)
    p.add_argument('--no-screen', action='store_true')
    args = p.parse_args()
    plan = [int(v) for v in args.plan.split(',') if v != '']
    L = g.Live(args.work)
    s = L.s
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)
    count = [int(a, 16) for a in args.count.split(',') if a]
    if count:
        s.call('analyze_performance', {'action': 'profiler', 'profiler': 'memory', 'op': 'start'}, ok=False)

    def counters():
        if not count:
            return {}
        r = s.call('analyze_performance', {'action': 'memory_counters', 'space': 'cpu',
                                           'addresses': ','.join(f'0x{a:04X}' for a in count), 'kinds': 'x',
                                           'view': 'sparse', 'min': 0, 'response_format': 'json'}, ok=False)
        d = json.loads(r.text[r.text.index('{'):])
        return {f'{c[0]:04X}': c[3] for c in d['cells']}

    def mem(addr, n):
        return L.get(f'/memory/read/{addr}?length={n}&format=binary', raw=True)

    def page0(addr, n):
        return L.get(f'/memory/page/ram/0?offset={addr - 0xC000}&length={n}&format=binary', raw=True)

    probe = page0(OBJ, 16)
    assert probe == mem(OBJ, 16) or True
    held, script, events = set(), ['0 -'], []
    last_change, frame, done_at = 0, 0, None
    F, V, O, S, rows = [], [], [], [], []
    level_counts = []
    prev_level = None
    while frame < args.frames and (done_at is None or not args.after or frame < done_at + args.after):
        rec = mem(P1, 0x10)
        var = mem(0x80E0, 0x10)
        fire_held = mem(0x8184, 1)[0]
        obj = page0(OBJ, 44 * NOBJ)
        sel, weapon, double, laser, speed = rec[7], rec[8], rec[9], rec[10], rec[11]
        if rec[6] != prev_level:
            c = counters()
            level_counts.append({'frame': frame, 'level_index': rec[6], 'counts': c})
            order = mem(0x8003, 12)
            events.append(f'{frame}\tlevel index {rec[6]} (level {order[rec[6]] + 1 if rec[6] < 12 else "?"}), '
                          f'order {list(order)}')
            print(events[-1], flush=True)
            prev_level = rec[6]
        px, py = obj[4], obj[6]
        pods, enemies = [], []
        for i in range(1, 6):
            r = obj[44 * i:44 * i + 44]
            if not r[8] & 0x80:
                continue
            (pods if r[7] == 4 else enemies).append((r[4], r[6]))
        goal = plan[0] if plan else None
        want = set()
        pod = min(pods, key=lambda q: abs(q[0] - px) + abs(q[1] - py)) if pods and goal is not None else None
        locked = var[2] != 0
        if pod:
            if sel == goal:
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
            if fire_held < args.hold or (weapon == 3 and locked):
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
        L.run(args.step)
        frame += args.step
        after = mem(P1, 0x10)
        if plan and (after[8], after[9], after[10], after[11]) != (weapon, double, laser, speed) and after[7] == 0 \
                and sel == goal:
            events.append(f'{frame}\taction {goal} taken: weapon {after[8]} double {after[9]} laser {after[10]} '
                          f'speed ${after[11]:02X}, fire held {fire_held} passes')
            print(events[-1], flush=True)
            plan.pop(0)
            if not plan:
                done_at = frame
        elif plan and goal == 0 and sel == 0 and after[7] == 0 and after[11] == speed and pod \
                and mem(0x80E6, 1)[0] == 0xBB and var[6] != 0xBB:
            events.append(f'{frame}\tspeed pod at the top speed (fuel refilled)')
            print(events[-1], flush=True)
            plan.pop(0)
            if not plan:
                done_at = frame
        F.append(frame)
        V.append(np.frombuffer(after + mem(0x80E0, 0x10) + mem(0x8184, 1) + mem(0x7F62, 0x20), dtype=np.uint8))
        O.append(np.frombuffer(page0(OBJ, 44 * NOBJ), dtype=np.uint8))
        if not args.no_screen:
            S.append(np.frombuffer(mem(0x4000, 6912), dtype=np.uint8))
        rows.append((frame, sel, after[8], after[9], after[10], after[11], mem(0x80E6, 1)[0], fire_held,
                     ''.join(f'{b:02X}' for b in after[0:4]), px, py, len(pods), after[6], after[4]))
        if frame % 500 == 0:
            print(frame, 'sel', sel, 'weapon', after[8], 'double', after[9], 'laser', after[10],
                  f'speed {after[11]:02X}', 'fuel', var[6], 'pods', len(pods), 'level', after[6], 'plan', plan,
                  flush=True)
    for k in held:
        s.call('joystick_input', {'action': 'release', 'buttons': NAMES[k]}, ok=False)
    script.append(f'+{frame - last_change} -')
    script.append('+1 END')
    level_counts.append({'frame': frame, 'level_index': None, 'counts': counters()})
    if count:
        s.call('analyze_performance', {'action': 'profiler', 'profiler': 'memory', 'op': 'stop'}, ok=False)
    json.dump(level_counts, open(args.out + '-counts.json', 'w'), indent=1)
    open(args.out + '-script.txt', 'w').write('# tools/gs_podbot.py\n' + '\n'.join(script) + '\n')
    open(args.out + '-events.txt', 'w').write('\n'.join(events) + '\n')
    np.savez_compressed(args.out + '.npz', frames=np.array(F), vars=np.array(V), objs=np.array(O),
                        **({'screen': np.array(S)} if S else {}))
    with open(args.out + '.tsv', 'w') as f:
        f.write('frame\tselector\tweapon\tdouble\tlaser\tspeed\tfuel\tfireheld\tscore\tx\ty\tpods\tlevel\tlives\n')
        for row in rows:
            f.write('\t'.join(map(str, row)) + '\n')
    print('done', frame, 'frames')


if __name__ == '__main__':
    main()
