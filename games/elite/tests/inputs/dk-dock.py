"""dk: from the title of c1 (work/snaps/title-A.szx): the commander tape work/tapes/rich.tap (a fixture made by
tools/commander_tape.py from the t1 save: TESTPILOT, 50000.0 Cr, every piece of equipment, the four lasers, see
docs/scenes.md) loaded by the game's own loader (Y at the title, 1 the tape, ENTER the empty name), the status page,
then the launch (1); the pilot stops the ship (SYMBOL SHIFT), turns it back to the station (X), lines the slot up
(the roll and pitch keys) and flies in (SPACE) until Condition is 0, the manual docking; then a second launch and the
docking computer (C), the instant dock. Played by tools/elitebot.py; the keys are in work/dk/inputs.txt."""


def nose(b):
    r = b.mem(0x6048 + 0x09, 6)
    return tuple(-(v & 0x7F) if v & 0x80 else v for v in (r[1], r[3], r[5]))


def station(b):
    return next((s for s in b.slots() if s['slot'] == 0), None)


def plan(b):
    b.feature('fasttape', False)
    b.tape('work/tapes/rich.tap')
    b.start()
    b.run(30)
    b.note('load'); b.tap('Y', 20, 60); b.tap('1', 6, 60); b.tap('ENTER', 6, 300)
    b.until(lambda: b.byte(0xD054) == ord('T'), 600)
    b.note('loaded'); b.tap('3', 6, 100); b.tap('SPACE', 20, 200)
    b.note('launch'); b.tap('1', 6, 400)
    b.note('stop'); b.hold('SS'); b.until(lambda: b.byte(0x70E6) == 0, 200, 2); b.hold('')
    b.note('turn'); b.hold('X')
    b.until(lambda: station(b)['z'] > 0 and abs(station(b)['y']) < 200, 600, 2); b.hold('')
    b.note('align')
    for i in range(60):
        keys, ok = b.aim(station(b), 4)
        b.hold(keys); b.run(2)
    b.note('approach')
    start = b.frame
    while b.frame - start < 3000 and b.byte(0x7104):
        s = station(b)
        if s is None:
            break
        keys, ok = b.aim(s, 4)
        if b.byte(0x70E6) < 6:
            keys.add('SPACE')
        b.hold(keys); b.run(2)
        b.log.append((b.frame, s['x'], s['y'], s['z'], *nose(b), b.byte(0x70E6)))
    b.hold('')
    b.note(f'docked (Condition {b.byte(0x7104)})')
    b.run(300)
    b.tap('3', 6, 100)
    b.note('launch 2'); b.tap('1', 6, 400)
    b.note('docking computer'); b.tap('C', 6, 400)
    b.note(f'docked (Condition {b.byte(0x7104)})')
    b.run(100)
    print(b.commander())
