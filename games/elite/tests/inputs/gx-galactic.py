"""gx: from the title of c1 (work/snaps/title-A.szx): the fixture work/tapes/rich.tap loaded by the game, the launch
(1), the galactic hyperdrive (G held with H): the jump to galaxy 2; then towards the planet with the in-system jump
(J, the pilot aiming at the planet) until the safe zone, the docking computer (C), the status page (L), and the
commander saved to tape as GALAXY2 (SYMBOL SHIFT, 2, the name, ENTER, a key): the save the mission fixtures start
from (tools/tape_from_trace.py reads it back from the trace). Played by tools/elitebot.py; the keys are in
work/gx/inputs.txt."""
import elitebot as EB


def pos(b, a):
    r = b.mem(a, 9)
    return {'x': EB.coord(r[0:3]), 'y': EB.coord(r[3:6]), 'z': EB.coord(r[6:9])}


def toward(b, s, keys_extra=('SPACE',)):
    sc = max(1, abs(s['z']) // 2000)
    keys, ok = b.aim({'x': s['x'] // sc, 'y': s['y'] // sc, 'z': s['z'] // sc}, 4)
    keys |= set(keys_extra)
    b.hold(keys)
    b.run(4)
    return ok


def plan(b):
    b.start()
    b.load_commander('work/tapes/rich.tap')
    b.note('launch'); b.tap('1', 6, 400)
    b.note('galactic hyperdrive'); b.hold('G'); b.run(10); b.hold('G H'); b.run(24); b.hold(''); b.run(20)
    b.until(lambda: b.byte(0xD03F) != 0, 200, 2)          # TunnelOn 2: the countdown
    b.until(lambda: b.byte(0xD03F) == 0, 3000, 10)        # the jump and its tunnel over
    b.run(200)
    c = b.commander()
    b.note(f"galaxy {c['galaxy'] + 1}, equipment {c['equipment']}, legal {c['legal']}")
    b.note('in-system jumps to the planet')
    start = b.frame
    while not b.byte(0x711C) and b.frame - start < 6000:
        ok = toward(b, pos(b, 0x7110), () if b.byte(0x81A5) else ('SPACE',))
        if ok and not b.byte(0x81A4) and not b.byte(0x81A5) and (b.frame - start) % 16 < 4:
            b.press('J', 24)
    b.hold('')
    b.note(f'safe zone {b.byte(0x711C)}')
    b.press('C', 24)
    b.until(lambda: b.byte(0x7104) == 0, 400, 5)
    b.note(f'docked (Condition {b.byte(0x7104)})')
    b.run(300)
    b.tap('L', 6, 150)
    b.note('save'); b.tap('SS', 6, 80); b.tap('2', 6, 60); b.type('GALAXY2', 6, 20); b.tap('ENTER', 6, 60)
    b.tap('SPACE', 6, 60)
    b.run(400)
    b.note('saved'); b.tap('3', 6, 150)
    print(b.commander())
