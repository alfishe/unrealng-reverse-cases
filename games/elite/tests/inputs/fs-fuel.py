"""fs: the fuel scoop, from the title of c1 (work/snaps/title-A.szx). The fixture work/tapes/fs.tap
(tools/commander_tape.py: the rich commander renamed SCOOPER with 3.0 light years of fuel) loaded by the game;
Diso picked (O, N, D), the launch (1), the hyperspace (H); at Diso the pilot turns to the sun and jumps (J) towards
it while the game allows (no ship about, the sun and the planet not close), until SunNear: the cabin heats and the
fuel scoop fills the tank, a tenth of a light year at a time, until a whole light year more. Played by
tools/elitebot.py; the keys are in work/fs/inputs.txt."""


def state(b, what):
    h = b.health()
    b.note(f"{what}: fuel {b.commander()['fuel'] / 10:.1f} cabin {h['cabin']} banks {h['banks']} sun near "
           f"{b.byte(0x711E)} sun close {b.byte(0x81A4)} planet close {b.byte(0x81A5)}")


def plan(b):
    b.start()
    b.load_commander('work/tapes/fs.tap')
    t = lambda k, after=60: b.tap(k, 6, after)
    t('O', 80); t('N', 60); t('D', 100)
    b.note('launch'); t('1', 700)
    b.note('hyperspace'); t('H', 60)
    b.until(lambda: b.byte(0xD03F) != 0, 300, 5)
    b.until(lambda: b.byte(0xD03F) == 0, 3000, 10)
    b.run(300)
    state(b, 'Diso')
    start, fuel0, near = b.frame, b.commander()['fuel'], False
    while b.frame - start < 40000:
        if b.byte(0x9C94) and [x for x in b.slots() if x['slot'] not in (0, 7)]:
            b.clear_ships()
            continue
        sun = b.position(0x7107)
        ok = b.toward(sun, () if b.byte(0x711E) else ('SPACE',))
        if ok and not b.byte(0x81A4) and not b.byte(0x81A5) and not b.byte(0x711E) and (b.frame - start) % 16 < 4:
            b.press('J', 24)
        if b.byte(0x711E) and not near:
            near = True
            state(b, 'sun near')
        h = b.health()
        if b.commander()['fuel'] >= fuel0 + 10 or h['cabin'] > 120 or h['banks'][3] == 0:
            break
    b.hold('')
    state(b, 'scooped')
    b.note('away from the sun'); b.hold('X SS'); b.run(200); b.hold('')
    state(b, 'end')
