#!/usr/bin/env python3
"""ATV Simulator: short recordings of what no play recording reached (doc 05, doc 07, doc 10), made with
tools/record.py's machinery from c1's menu.szx (one player, KEMPSTON detected at power-on) or, for dropout, from
recording menu's menu-two-kb.szx (two players on the keyboard).

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
itemlow     A POKE at the menu: trail 1's list A item 2 (distance $0080, sprite $C9, 7 lines high) gets y 1 instead of
            23; START: the first pass's walk meets it, PlaceItem finds y under the height and runs ItemTooLow `$8EB2`
            (red border, SP = $6334, the restart); 400 frames after.
overhang    A POKE at the menu: trail 1's list A item 3 (distance $0148, sprite $67, 12 lines high, y 0 = on the
            ground) gets y 30: it floats 19-30 lines up, out of reach of the wheels' and the nose's scans. START,
            mount, right held: RiderMounted `$DE59` scans the column ahead of the rider from 32 above him down, meets
            the item's top 12-30 above him at speed 4 or more: ThrowOff `$E2E2` (an overhang; the wheel keys never
            pressed, AtvFrame not `$44`); 300 frames after.
dropout     From menu-two-kb.szx (two players: player 1 Q A O P M, player 2 H J K M B). START; player 1 walks and
            jumps on, player 2 stands; player 1's distance POKEd to the finish less 40 (RecordP1's TrackPos `$D726`,
            between passes); player 1 rides over the line and stops; at TIME OUT (the clock's 60) TrailEnd keeps only
            the finished rider (Riding = Finished = 1): trail 2 starts for player 1 alone; 700 frames of it.

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


def item_y(r, index, y, why):
    """POKEs trail 1's list A item @p index's y (list A's address is the word at TrailRecords $7C9C)"""
    a1 = int.from_bytes(r.rd(0x7C9C, 2), 'little')
    addr = a1 + 6 * index + 2
    r.lab.write(addr, bytes([y]))
    r.pokes.append({'frame': r.lab.frame, 'address': f'${addr:04X}', 'bytes': [y], 'why': why})


def plan_itemlow(r):
    """itemlow: from c1's menu.szx; POKE trail 1's list A item 2 (distance $0080, sprite $C9, 7 high) y 23 -> 1;
    START: PlaceItem's height test fails, ItemTooLow $8EB2 (red border, restart); 400 frames after"""
    R.to_menu(r)
    item_y(r, 2, 1, 'trail 1 list A item 2 (sprite $C9, 7 lines): y 23 -> 1, under its height')
    r.shot('menu')
    R.start_game(r)
    for _ in range(60):
        r.wait(5)
        if r.rd(0xD6BC)[0] != 0xFF:
            break
    r.shot('start')
    for k in range(8):
        r.wait(50)
        r.shot('after')


def plan_overhang(r):
    """overhang: from c1's menu.szx; POKE trail 1's list A item 3 (distance $0148, sprite $67, 12 high) y 0 -> 30, a
    floating piece 19-30 lines up; START; mount; right held until the rider is off (RiderMounted's overhang test,
    ThrowOff $E2E2) or 700 frames; 300 frames after. Samples of the record and FallPhase in log.json"""
    log = []
    R.to_menu(r)
    item_y(r, 3, 30, 'trail 1 list A item 3 (sprite $67, 12 lines): y 0 (on the ground) -> 30, an overhang')
    start(r, log)
    def off(v):
        v['fallphase'] = r.rd(0xD734)[0]
        return not v['mounted']
    until(r, log, 'KR', 700, off, 'throttle', 'thrown')
    RC.hold_log(r, log, '', 21, 'idle')
    r.shot('fallen')
    RC.hold_log(r, log, '', 280, 'idle')
    r.shot('after')
    json.dump(log, open(os.path.join(r.work, 'log.json'), 'w'), indent=0)


def two_state(r, log, note):
    v = {'frame_no': r.lab.frame, 'riding': r.rd(0xD6BE)[0], 'finished': r.rd(0xD7A5)[0], 'trail': r.rd(0xD6BF)[0],
         'clock': r.rd(0xD6C9, 3).decode('latin1'), 'track1': int.from_bytes(r.rd(0xD726, 2), 'little'),
         'track2': int.from_bytes(r.rd(0xD758, 2), 'little'), 'mounted1': r.rd(0xD710)[0],
         'speed1': r.rd(0xD717)[0], 'speed2': r.rd(0xD749)[0], 'held': '+'.join(r.held), 'note': note}
    log.append(v)
    return v


def plan_dropout(r):
    """dropout: from menu-two-kb.szx (two players on the keyboard); START; player 1 walks right and jumps on (A, M),
    player 2 stands; player 1's TrackPos ($D726) POKEd to the finish less 40; right until player 1 has finished,
    then nothing; TIME OUT drops player 2 (Riding = Finished = 1); trail 2 for player 1 alone, 700 frames"""
    log = []
    R.to_menu(r)
    R.start_game(r)
    r.wait(150)
    for _ in range(200):
        if r.rd(0xD6BC)[0] != 0xFF:
            break
        r.wait(7)
    r.shot('start')
    for _ in range(8):
        r.hold('A', 40)
        r.hold('A+M', 6)
        r.hold('A', 30)
        if two_state(r, log, 'mount')['mounted1']:
            break
    r.shot('mounted')
    fin = int.from_bytes(r.rd(0xD6C0, 2), 'little')
    to = fin - 40
    for _ in range(6):
        r.lab.write(0xD726, to.to_bytes(2, 'little'))
        r.pokes.append({'frame': r.lab.frame, 'address': '$D726', 'bytes': list(to.to_bytes(2, 'little')),
                        'why': f'player 1: distance to {to} (finish {fin} - 40)'})
        r.hold('A', 13)
        if two_state(r, log, 'poke')['track1'] >= to - 8:
            break
    for _ in range(300):
        r.hold('A', 13)
        if two_state(r, log, 'ride')['finished'] & 1:
            break
    r.shot('finished')
    for _ in range(1200):
        r.wait(13)
        v = two_state(r, log, 'wait')
        if v['trail'] != 0:
            break
    r.shot('trail2-name')
    for k in range(7):
        r.wait(100)
        two_state(r, log, 'trail 2')
        r.shot('trail2')
    json.dump(log, open(os.path.join(r.work, 'log.json'), 'w'), indent=0)


R.PLANS.update({'throwoff': plan_throwoff, 'speedcrash': plan_speedcrash, 'wallcrash': plan_wallcrash,
                'itemlow': plan_itemlow, 'overhang': plan_overhang, 'dropout': plan_dropout})

if __name__ == '__main__':
    R.main()
