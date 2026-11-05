#!/usr/bin/env python3
"""A Zynaps bot on a live instance (play_live.py start): it reads the game's records each step, presses the keys
(SPACE fire, Q up, A down, O left, P right) and writes what it pressed as an input script, so the run records again
with re_session.py capture --snapshot S --inputs SCRIPT.

  play_bot.py --work W --snapshot S.szx --frames N --script OUT.txt [--log OUT.tsv] [--prefix PRE.txt]
              [--select 2,3,4] [--step 2]

--prefix: an input script played first (from the snapshot: the title keys, the start); the bot starts where it ends.
--select: the weapons to take, in order, by their index in the pod table `$80F0` (0 speed, 1 laser, 2 bombs,
3 homing missiles, 4 seekers): a pod taken with fire held 8 frames or more selects the highlighted entry
(player record +7, `$A209`); otherwise the pod moves the highlight on. The bot holds fire into a pod only when the
highlight is the next wanted entry.

The records (48K case docs/02, and this case's reading of `$9C83`-`$9DDD`, `$A1FD`-`$A25F`):
  $F36C + 44*i  object records: +0/+1 handler, +4 X, +6 Y, +8 bit 7 active; slot 0 the ship, 1-5 enemies;
                a pod has the handler $7EBB ($A303)
  $7F9C         player 1: +0..+3 score (BCD), +4 lives, +6 level, +7 highlight, +8 weapon (0, 2 bombs,
                3 homing, 4 seekers), +9 second bomb, +A laser level, +B speed, +C extra lives given
  $8184         frames fire has been held
The objects ($C000 up) are read from RAM page 0, the game's page: a pause can stop inside the interrupt's engine
call with page 4 at $C000.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import mcplib  # noqa: E402
import corpus  # noqa: E402
import mm_session  # noqa: E402

OBJ, P1, POD = 0xF36C, 0x7F9C, 0x7EBB


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--snapshot', required=True)
    p.add_argument('--prefix')
    p.add_argument('--frames', type=int, default=3000)
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--select', default='2,3')
    p.add_argument('--script', required=True)
    p.add_argument('--log')
    p.add_argument('--x', type=int, default=20)
    p.add_argument('--top', type=int, default=2)
    p.add_argument('--bottom', type=int, default=13)
    p.add_argument('--lock', action='store_true', help='with homing missiles (weapon 3): put the sight on a guardian')
    p.add_argument('--park', type=lambda v: tuple(int(x) for x in v.split(',')), default=(28, 7),
                   help='X,Y of the ship while --lock waits for the guardian (the sight at X+10, Y)')
    args = p.parse_args()
    state = json.load(open(os.path.join(args.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    m = corpus.Machine(s, state['port_base'])
    m.post('/snapshot/load', {'path': os.path.abspath(args.snapshot)})
    wanted = [int(x) for x in args.select.split(',') if x != '']

    def press(keys, down):
        for k in keys:
            s.call('type_input', {'action': 'press' if down else 'release', 'key': k}, ok=False)

    script, frame, held = [], 0, set()
    if args.prefix:
        last = 0
        for f, keys in mm_session.parse_script(args.prefix):
            if f > last:
                s.call('control_execution', {'action': 'run_frames', 'frames': f - last})
                last = f
            if keys is None:
                break
            press(held, False)
            held = set(keys)
            press(held, True)
            script.append(f'{f} ' + (' '.join(sorted(held)) or '-'))
        frame = last
    last_change = frame
    log, phase, events = [], 0, []
    prev = None
    last_target = 0
    start = frame
    while frame - start < args.frames:
        rec = m.read(P1, 0x10)
        # $C000-$FFFF of the game is RAM page 0; a pause can fall inside the frame's engine call with page 4 in
        obj = m.read_page('ram', 0)[OBJ - 0xC000:OBJ - 0xC000 + 44 * 16]
        fire_held = m.read(0x8184, 1)[0]
        target = m.read(0x80E2, 1)[0]  # the homing lock: the locked enemy's slot bit, 0 = none
        if target != last_target:
            events.append((frame, f'homing lock {last_target:02X}->{target:02X}'))
            print(frame, events[-1][1], flush=True)
            last_target = target
        px, py = obj[4], obj[6]
        weapon, highlight = rec[8], rec[7]
        if prev and (prev[7] != rec[7] or prev[8] != rec[8] or prev[12] != rec[12] or prev[4] != rec[4]):
            events.append((frame, f'highlight {prev[7]}->{rec[7]} weapon {prev[8]}->{rec[8]} '
                                  f'extra {prev[12]}->{rec[12]} lives {prev[4]}->{rec[4]}'))
            print(frame, events[-1][1], flush=True)
        prev = rec
        while wanted and weapon == wanted[0]:
            wanted.pop(0)
        pods, enemies, guards = [], [], []
        for i in range(1, 6):
            r = obj[44 * i:44 * i + 44]
            if not r[8] & 0x80:
                continue
            if r[0] | r[1] << 8 == POD:
                pods.append((r[4], r[6]))
            else:
                enemies.append((r[4], r[6]))
                if r[0x0D] >= 2:  # hit points left: a guardian ($9FC8), the only kind a homing sight locks on here
                    guards.append((r[4], r[6]))
        want = set()
        tx, ty = args.x, None
        select_now = False
        pod = min(pods, key=lambda q: abs(q[0] - px) + 4 * abs(q[1] - py)) if pods else None
        if pod and pod[0] > 2:
            tx, ty = max(4, min(pod[0], 90)), pod[1]
            select_now = bool(wanted) and highlight == wanted[0]
        else:
            ahead = [e for e in enemies if e[0] > px]
            if ahead:
                ty = min(ahead, key=lambda e: e[0])[1]
        near_pod = pod is not None and abs(pod[0] - px) < 20
        phase = (phase + args.step) % 10
        lock = args.lock and weapon == 3 and guards and not near_pod
        if lock:
            # the homing sight ($F600, $9E16) sits 10 X units ahead of the ship's place 8 moves ago, same Y (the ring
            # $80C0 fills only while the ship moves): park the ship at --park with a small wiggle, so the sight waits on
            # the guardian's round, and hold fire (one laser shot on the press; with a lock `$80E2` the guardian's
            # bit, `$9CCA` launches a missile each tick fire is held)
            tx, ty = args.park[0] + (1 if (frame // 8) % 2 else -1), args.park[1]
        if lock:
            want.add('space')
        elif select_now and near_pod:
            want.add('space')
        elif near_pod:
            if phase % 4 == 0:
                want.add('space')
        elif weapon >= 2:
            if phase < 8:
                want.add('space')
        elif phase % 4 == 0:
            want.add('space')
        if px < tx - 1:
            want.add('p')
        elif px > tx + 1:
            want.add('o')
        if ty is None:
            ty = 8
        ty = max(args.top, min(args.bottom, ty))
        if py < ty:
            want.add('a')
        elif py > ty:
            want.add('q')
        if want != held:
            press(held - want, False)
            press(want - held, True)
            script.append(f'{frame} ' + (' '.join(sorted(want)) or '-'))
            held = want
            last_change = frame
        s.call('control_execution', {'action': 'run_frames', 'frames': args.step})
        frame += args.step
        if frame % 100 == 0:
            score = ''.join(f'{b:02X}' for b in rec[0:4])
            log.append((frame, score, rec[4], rec[6], rec[7], rec[8], rec[12], px, py, len(pods)))
            print(frame, 'score', score, 'lives', rec[4], 'level', rec[6], 'hl', rec[7], 'weapon', rec[8],
                  'x', px, 'y', py, 'pods', len(pods), 'fire', fire_held, flush=True)
    press(held, False)
    script.append(f'{frame} -')
    script.append(f'{frame + 1} END')
    with open(args.script, 'w') as f:
        f.write(f'# tools/play_bot.py --snapshot {args.snapshot} --select {args.select} --frames {args.frames}'
                f'{" --prefix " + args.prefix if args.prefix else ""}'
                f'{" --lock --park %d,%d" % args.park if args.lock else ""}\n')
        f.write('\n'.join(script) + '\n')
    if args.log:
        with open(args.log, 'w') as f:
            f.write('frame\tscore\tlives\tlevel\thighlight\tweapon\textra\tx\ty\tpods\n')
            for row in log:
                f.write('\t'.join(map(str, row)) + '\n')
            for fr, text in events:
                f.write(f'# {fr} {text}\n')


if __name__ == '__main__':
    main()
