#!/usr/bin/env python3
"""The completion recordings (docs 01, 04, 07, 10): a mission driven to its goal by a closed-loop steering bot, the
Helicarrier called and met, MissionCompleteScreen, the status screen and the save code of a non-zero score.

    python3 tools/rec_complete.py m1 --work work/stage2/rec/m1complete --port-base 37390 \
        --start work/stage1/explore/loaded.szx --inputs tests/inputs/m1complete.txt
    python3 tools/rec_complete.py m4 --work work/stage2/rec/m4complete --port-base 37390 \
        --start work/stage2/rec/m1complete/end.szx --inputs tests/inputs/m4complete.txt

Plan m4: see plan_m4's docstring (the campaign continued from m1complete's end state).

Plan m1 (Blast Em Mission, the Turret): the tank steered from the start to the two fuel dumps (list records 55, 56 at
world X `$5800` / `$5C00`, Y `$5000`), stopped, aimed, the cannon fired at each until its destroyed bit (b1 of
`$DE74` / `$DE7C`) is set; GoalHook1 `$EB60` sets `$68E8`, PickupAnnounce prints the pickup text; H calls the
Helicarrier, which flies to the pad (`$7E82` +7 / +10: X word 0, Y word `$20`, world (0, 8192)) and lands; the tank is
driven into it: HelicarrierHit `$DAAB` with the goal flag goes to `$67EE`, MissionCompleteScreen, the status screen;
SAVE GAME shows the code.

POKEs (bank 0, on the recording's machine only, each in record.json with its frame): Immunity `$C875` = `$3A`
(CollisionPass `JP M,$C8AF` becomes `LD A,(nn)`) for the two long drives only, and the original `$FA` written back
before the cannon is fired (immunity also drops the shells' hits) and before the Helicarrier is met (its collision is
the completion). The end state has the original byte.

Steering: heading `$7612` (0 = +Y, P adds, O subtracts, about 0.37 a frame), X `$7613` / Y `$7616` (24-bit world
units), speed `$75F7` (Q raises it to 47, it holds without keys, A brakes and reverses). Every key hold is one
run_frames call (bcbot.Bot.hold), so tests/inputs/<name>.txt replays segment by segment.
"""
import argparse
import json
import math
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab  # noqa: E402
from record import Run, mission_tape, load_mission, fit, header_block, STORES, SIDE2  # noqa: E402

STATUS = {'save': (195, 30), 'selection': (195, 62)}
IMMUNITY = (0xC875, 0x3A, 0xFA)   # bank 0 CollisionPass: the POKE byte, the original byte


def st(lab):
    b = lab.read(0x75F0, 60)
    x = int.from_bytes(b[0x23:0x26], 'little', signed=True)
    y = int.from_bytes(b[0x26:0x29], 'little', signed=True)
    return b[0x22], x, y, b[7] - 256 if b[7] > 127 else b[7]


def bearing(x, y, tx, ty):
    return int(round(math.atan2(tx - x, ty - y) * 128 / math.pi)) & 255


def sdiff(a, b):
    d = (a - b) & 255
    return d - 256 if d > 127 else d


def state(r):
    lab = r.lab
    h, x, y, sp = st(lab)
    return {'frame': lab.frame, 'heading': h, 'x': x, 'y': y, 'speed': sp, 'goal': lab.read(0x68E8, 1)[0],
            'score': int.from_bytes(lab.read(0x68E2, 4), 'little'), 'fail': lab.read(0x7BF9, 2).hex(),
            'done': lab.read(0x6799, 10).hex(), 'fuel': int.from_bytes(lab.read(0x7C57, 2), 'little'),
            'armour': lab.read(0x8301, 4).hex()}


def drive_to(r, tx, ty, near, limit=12000, step=40, until=None, name='drive'):
    """Steers toward (tx, ty) until within @p near (or until() is true); one hold a segment"""
    used = n_log = 0
    while used < limit:
        h, x, y, sp = st(r.lab)
        d = math.hypot(tx - x, ty - y)
        if n_log % 20 == 0:
            r.moments.append({'name': name, **state(r), 'dist': int(d)})
        n_log += 1
        if d <= near or (until and until()):
            break
        diff = sdiff(bearing(x, y, tx, ty), h)
        if abs(diff) > 3:
            n = max(4, min(step, int(abs(diff) * 2.7)))
            keys = ['P'] if diff > 0 else ['O']
        else:
            n = step if d > 3 * near else 15
            keys = ['Q'] if sp < 47 else []
        r.b.hold(keys, n)
        used += n
    r.moments.append({'name': name + '-end', **state(r)})
    return used


def stop(r):
    for _ in range(30):
        sp = st(r.lab)[3]
        if sp == 0:
            return
        r.b.hold(['A'] if sp > 0 else ['Q'], max(1, min(10, abs(sp) // 5)))


def aim(r, tx, ty):
    for _ in range(20):
        h, x, y, _sp = st(r.lab)
        d = sdiff(bearing(x, y, tx, ty), h)
        if abs(d) <= 1:
            return
        r.b.hold(['P'] if d > 0 else ['O'], max(2, int(abs(d) * 2.7)))


def destroyed(lab, addr, typ=None):
    """b1 of list record byte @p addr; with @p typ the record's type byte must match (another bank paged at $C000
    between frames reads as garbage)"""
    b = lab.read(addr, 2)
    return bool(b[0] & 2) and (typ is None or b[1] == typ)


def fire_until(r, addr, name, n=16, typ=None):
    """The cannon fired (SPACE 25 frames, 25 after) until b1 of list record byte @p addr is set"""
    for i in range(n):
        if destroyed(r.lab, addr, typ):
            r.moments.append({'name': name + '-destroyed', 'shots': i, **state(r)})
            r.shot(name + '-destroyed')
            return i
        r.b.hold(['SPACE'], 25)
        r.b.wait(25)
    raise SystemExit(f'{name}: not destroyed after {n} shots')


def immunity(r, on):
    a, poke, orig = IMMUNITY
    r.poke(a, [poke if on else orig], 'Immunity on (.pok: CollisionPass JP M becomes LD A,(nn))' if on else
           'Immunity off: the original JP M opcode written back', bank=0)


def heli(lab):
    """The Helicarrier's record (type $8C) in the object table: (index, handler, x, y, height) or None"""
    for i in range(24):
        b = lab.read(0x75F0 + 60 * i, 60)
        if b[2] and b[1] == 0x8C:
            return (i, b[0x18] | b[0x19] << 8, int.from_bytes(b[0x23:0x26], 'little', signed=True),
                    int.from_bytes(b[0x26:0x29], 'little', signed=True), b[5] | b[6] << 8)
    return None


def pickup(r, limit=1500):
    """The tank steered into the Helicarrier until MissionsDone is set or the screen changes; screens every 10 frames"""
    lab = r.lab
    used = 0
    while used < limit:
        hc = heli(lab)
        r.moments.append({'name': 'pickup', 'heli': hc, **state(r)})
        if lab.read(0x6799, 10) != bytes(10) or hc is None or (hc[1] & 0xFF00) not in (0xDA00, 0xDB00, 0x6B00):
            break
        h, x, y, sp = st(lab)
        diff = sdiff(bearing(x, y, hc[2], hc[3]), h)
        keys = (['P'] if diff > 0 else ['O']) if abs(diff) > 3 else (['Q'] if sp < 47 else [])
        r.b.hold(keys, 10)
        used += 10
    for i in range(40):
        r.shot(f'complete-{i:02d}')
        r.moments.append({'name': f'complete-{i:02d}', **state(r)})
        r.b.wait(10)


def plan_m1(r):
    lab = r.lab
    r.shot('title')
    mission_tape(r)
    load_mission(r, 1)
    fit(r, {1: 'Turret'})
    r.b.click(*STORES['start'], after=150)
    r.shot('start')
    r.moments.append({'name': 'start', **state(r)})
    immunity(r, True)
    drive_to(r, 22528 + 512, 20480, near=2500, name='to-dumps')
    r.shot('dumps-near')
    stop(r)
    immunity(r, False)
    r.b.hold(['1'], 25)
    r.b.wait(10)
    aim(r, 22528, 20480)
    fire_until(r, 0xDE74, 'dump55')
    aim(r, 23552, 20480)
    fire_until(r, 0xDE7C, 'dump56')
    for _ in range(10):
        if lab.read(0x68E8, 1)[0]:
            break
        r.b.wait(5)
    r.moments.append({'name': 'goal', **state(r)})
    r.b.wait(30)
    r.shot('pickup-text')
    r.b.hold(['H'], 25)
    r.b.wait(25)
    r.moments.append({'name': 'helicarrier-called', 'heli': heli(lab), **state(r)})
    r.shot('helicarrier-called')
    immunity(r, True)
    drive_to(r, 0, 8192, near=1200, name='to-pad')
    r.moments.append({'name': 'pad', 'heli': heli(lab), **state(r)})
    r.shot('pad')
    immunity(r, False)
    pickup(r)
    r.shot('status')
    r.b.click(*STATUS['save'], after=80)
    r.shot('save-code')
    r.moments.append({'name': 'save-code', **state(r)})
    r.b.key('SPACE', 3, 60)
    r.shot('save-after')


def plan_m4(r):
    """m4: Railway Ambush after m1complete (its end.szx: the save code screen, Score 500, mission 1 done): SPACE,
    MISSION SELECTION (the catalogue is still in memory), side 2 inserted and wound to mission 4's header, SEARCH,
    SELECT, the Turret; the points (list record 10, type 11, hit handler $E638 writes $60 to $E7C0-$E7C2) shot at
    the start, the tank driven off the main line to the siding (Immunity on for the drive, off at the spot), the engine
    (record 2, type 8) shot on the siding (the train stops with record 3's Y high byte +7 = $FB), the station (record
    11, type 13, world (28672, 0)) shot, the goal, H, the pad (world (-20480, 4096)), the pickup, the save code"""
    lab = r.lab
    r.b.wait(100)
    r.shot('entry-string')
    r.b.key('SPACE', 3, 100)
    r.shot('status-before')
    r.b.click(*STATUS['selection'], after=100)
    r.shot('catalogue')
    r.tape_do('insert', path=SIDE2)
    load_mission(r, 4, seek_block=header_block(SIDE2, 4))
    fit(r, {1: 'Turret'})
    r.b.click(*STORES['start'], after=150)
    r.shot('start')
    r.moments.append({'name': 'start', **state(r)})
    r.b.hold(['1'], 25)
    r.b.wait(5)
    aim(r, -14336, 256)
    for _ in range(14):
        if lab.read(0xE7C0, 1)[0] == 0x60:
            break
        r.b.hold(['SPACE'], 25)
        r.b.wait(25)
    r.moments.append({'name': 'points', 'e7c0': lab.read(0xE7C0, 3).hex(), **state(r)})
    r.shot('points-shot')
    immunity(r, True)
    drive_to(r, -2000, -3300, near=300, limit=4000, name='to-siding')
    stop(r)
    immunity(r, False)
    r.shot('siding')
    for k in range(160):
        b = lab.read(0xDCC0, 16)
        if b[1] != 8 or b[9] != 9:
            r.b.wait(5)
            continue
        x = int.from_bytes(b[4:6], 'little', signed=True) * 4
        y = int.from_bytes(b[6:8], 'little', signed=True) * 4
        if k % 5 == 0:
            r.moments.append({'name': 'train', 'engine': b[:8].hex(), 'car3': b[8:].hex(), **state(r)})
        if b[0] & 2:
            break
        if y < -3000 and -9000 < x < 1000:
            aim(r, x + 300, y)
            r.b.hold(['SPACE'], 25)
            r.b.wait(15)
        else:
            r.b.wait(50)
    r.moments.append({'name': 'engine-destroyed', 'list2-3': lab.read(0xDCC0, 16).hex(), **state(r)})
    r.shot('engine-destroyed')
    immunity(r, True)
    drive_to(r, 28672 - 2400, 0, near=600, limit=9000, name='to-station')
    stop(r)
    immunity(r, False)
    aim(r, 28672, 0)
    fire_until(r, 0xDD08, 'station', n=20, typ=13)
    for _ in range(10):
        if lab.read(0x68E8, 1)[0]:
            break
        r.b.wait(5)
    r.moments.append({'name': 'goal', 'list2-3': lab.read(0xDCC0, 16).hex(), **state(r)})
    r.b.wait(30)
    r.shot('pickup-text')
    r.b.hold(['H'], 25)
    r.b.wait(25)
    r.moments.append({'name': 'helicarrier-called', 'heli': heli(lab), **state(r)})
    immunity(r, True)
    drive_to(r, -20480, 4096, near=1200, name='to-pad')
    r.moments.append({'name': 'pad', 'heli': heli(lab), **state(r)})
    r.shot('pad')
    immunity(r, False)
    pickup(r)
    r.b.key('SPACE', 3, 150)
    r.shot('status')
    r.b.click(*STATUS['save'], after=80)
    r.shot('save-code')
    r.moments.append({'name': 'save-code', **state(r)})
    r.b.key('SPACE', 3, 60)
    r.shot('save-after')


PLANS = {'m1': plan_m1, 'm4': plan_m4}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('plan', choices=sorted(PLANS))
    ap.add_argument('--work', required=True)
    ap.add_argument('--port-base', type=int, default=37390)
    ap.add_argument('--start', required=True)
    ap.add_argument('--inputs', help='the input script copy (tests/inputs/<name>.txt)')
    a = ap.parse_args()
    work = os.path.abspath(a.work)
    os.makedirs(work, exist_ok=True)
    lab = Lab(a.port_base)
    lab.session_json(work)
    r = Run(lab, work)
    began = time.time()
    try:
        lab.load(os.path.abspath(a.start))
        lab.start_recording()
        lab.frame = 0
        r.b.t0 = 0
        r.lab.keys([])
        PLANS[a.plan](r)
        lab.keys([])
        lab.save(os.path.join(work, 'end.szx'))
        rec = {'plan': a.plan, 'note': PLANS[a.plan].__doc__ or __doc__.split('\n\n')[0], 'start': a.start, 'frames': lab.frame,
               'moments': r.moments, 'mouse': r.b.mouse_log, 'tape': r.tape_log, 'pokes': r.pokes,
               'seconds': round(time.time() - began)}
        r.b.script(os.path.join(work, 'inputs.txt'), start=0)
        if a.inputs:
            r.b.script(os.path.abspath(a.inputs), start=0)
        s = lab.s
        s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 30000})
        st_text = s.call('analysis', {'action': 'status'}).text
        while ': running' in st_text:
            time.sleep(5)
            st_text = s.call('analysis', {'action': 'status'}).text
        d = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        rec['ttd'] = (d.text or '').splitlines()[:2]
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        print(json.dumps({k2: rec[k2] for k2 in ('frames', 'ttd', 'seconds', 'pokes')}, indent=1))
    finally:
        lab.close()


if __name__ == '__main__':
    main()
