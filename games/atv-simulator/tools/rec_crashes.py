#!/usr/bin/env python3
"""ATV Simulator: three short recordings of what no play recording reached (doc 05, doc 10), made with
tools/record.py's machinery from c1's menu.szx (one player, KEMPSTON detected at power-on).

    python3 tools/rec_crashes.py PLAN --work work/stage1/rec/PLAN --start work/stage1/rec/c1/menu.szx \
        --port-base 37780

throwoff    START, the rider walks to the ATV and jumps on; right 42 frames, then right + wheel up held 140 frames:
            WheelieUp lifts the nose two frames a pass to `$44`, the next pass with Up held runs ThrowOff `$E2E2`
            (Mounted 0, FallPhase 1) and FallRider `$E991` drops the rider behind the ATV; 210 frames idle after.
speedcrash  START, mount; right 140 frames (speed 20), then nothing held: the ATV keeps its speed, lands from the
            first dunes (Landing: -2 each) and meets trail 1's step at TrackPos 614 at speed 15. Crash `$E94C`
            from the step test (`$E6EB`): SlowDown to 13, so Stop and Throw (10-14), no tumble; 400 frames after.
wallcrash   START, mount; the distance POKEd to trail 1's finish less 40 (as recording warp: `$D78A` and `$D726`),
            right until trail 2 begins, mount again; right 140 frames, then nothing held: at TrackPos 296 the nose
            dips into the ground (the nose's line under the nose's ground) on a descent, the nose test (`$E76D`)
            finds the ground under the nose 7 below the wheels', unsigned `$F9`, `$15` or more: Crash from `$E771`
            at speed 21, a tumble; 400 frames after. No POKE but the distance.

Each pass-sized step (7 frames) logs player 1's record in W/log.json (tools/rec_controls.py's sample). The input
script goes to tests/inputs/<W's name>.txt, the recording (session.ttd, l1.json, record.json, screens) to W.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import record as R  # noqa: E402
import rec_controls as RC  # noqa: E402


def to_first_pass(r, log):
    for _ in range(200):                      # the trail intro: FrameCount `$D6BC` is $FF until the first pass
        if r.rd(0xD6BC)[0] != 0xFF:
            break
        r.wait(7)
    RC.sample(r, log, 'first pass')


def mount(r, log):
    """The rider walks right until he is 24 pixels short of the ATV, then jumps (right held) until MountCheck takes
    him on"""
    for _ in range(60):
        if log[-1]['rx'] >= log[-1]['x'] - 24:
            break
        RC.hold_log(r, log, 'KR', 7, 'walk to the ATV')
    for _ in range(6):
        RC.hold_log(r, log, 'KR+KF', 7, 'jump on')
        RC.hold_log(r, log, 'KR', 21, 'jump on')
        if log[-1]['mounted']:
            break
    r.shot('mounted')


def start(r, log):
    R.to_menu(r)
    R.start_game(r)
    r.wait(150)
    to_first_pass(r, log)
    mount(r, log)


def until(r, log, spec, frames, test, note, name):
    """Holds @p spec in 7-frame steps up to @p frames; a screen at the first step where @p test(sample) holds"""
    for _ in range(frames // 7):
        RC.hold_log(r, log, spec, 7, note)
        if test(log[-1]):
            r.shot(name)
            return True
    return False


def plan_throwoff(r):
    """throwoff: from c1's menu.szx, START; walk and jump onto the ATV; right 42 frames, then right + wheel up 140
    frames: the nose up to $44, ThrowOff and FallRider; 210 frames idle. Samples of the record in log.json"""
    log = []
    start(r, log)
    RC.hold_log(r, log, 'KR', 42, 'throttle')
    until(r, log, 'KR+KU', 140, lambda v: not v['mounted'], 'wheel up', 'thrown')
    RC.hold_log(r, log, 'KR+KU', 21, 'wheel up')
    r.shot('fallen')
    RC.hold_log(r, log, '', 210, 'idle')
    r.shot('after')
    json.dump(log, open(os.path.join(r.work, 'log.json'), 'w'), indent=0)


def plan_speedcrash(r):
    """speedcrash: from c1's menu.szx, START; walk and jump onto the ATV; right 140 frames, then nothing held until
    the crash at trail 1's step (TrackPos 613, speed 15: Stop and Throw) and 400 frames after. Samples in log.json"""
    log = []
    start(r, log)
    RC.hold_log(r, log, 'KR', 140, 'throttle')
    r.shot('top-speed')
    until(r, log, '', 1400, lambda v: v['speed'] == 0, 'coast', 'crash')
    RC.hold_log(r, log, '', 400, 'after')
    r.shot('after')
    json.dump(log, open(os.path.join(r.work, 'log.json'), 'w'), indent=0)


def plan_wallcrash(r):
    """wallcrash: from c1's menu.szx, START; mount; the distance POKEd to trail 1's finish less 40 ($D78A, $D726);
    right until trail 2; mount; right 140 frames, then nothing held until the nose test's crash (TrackPos 296, speed
    21, a tumble) and 400 frames after. Samples in log.json"""
    log = []
    start(r, log)
    fin = int.from_bytes(r.rd(0xD6C0, 2), 'little')
    to = fin - 40
    for addr in (0xD78A, 0xD726):
        r.lab.write(addr, to.to_bytes(2, 'little'))
        r.pokes.append({'frame': r.lab.frame, 'address': f'${addr:04X}', 'bytes': list(to.to_bytes(2, 'little')),
                        'why': f'trail 1: distance to {to} (finish {fin} - 40)'})
    for _ in range(400):
        r.hold('KR', 7)
        if r.rd(0xD6BF)[0] != 0:
            break
    r.shot('trail2-name')
    to_first_pass(r, log)
    mount(r, log)
    RC.hold_log(r, log, 'KR', 140, 'throttle')
    r.shot('top-speed')
    until(r, log, '', 1400, lambda v: v['speed'] == 0 or v['frame'] >= 0x7D, 'coast', 'crash')
    RC.hold_log(r, log, '', 400, 'after')
    r.shot('after')
    json.dump(log, open(os.path.join(r.work, 'log.json'), 'w'), indent=0)


R.PLANS.update({'throwoff': plan_throwoff, 'speedcrash': plan_speedcrash, 'wallcrash': plan_wallcrash})

if __name__ == '__main__':
    R.main()
