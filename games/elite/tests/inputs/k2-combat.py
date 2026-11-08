"""k2: from the title of c1 (work/snaps/title-A.szx): the fixture work/tapes/k2.tap (tools/commander_tape.py: the rich
commander of dk renamed FIGHTER with the combat score $02FFD0, 80 short of the next top-byte step) loaded by the
game; the chart (O), Diso picked (N, D), the launch (1), the pause menu's misjump option (CAPS SHIFT, F, SPACE), the
hyperspace (H): the jump ends in witch space among four Thargoids. Then a missile armed (T), locked and fired (F) at
the nearest Thargoid; the E.C.M. (E); the military laser at the Thargons and Thargoids (A, the pilot of
tools/elitebot.py steering); the energy bomb (W); the laser again. Played by tools/elitebot.py; the keys are in
work/k2/inputs.txt, the pilot's view each step in work/k2/log.tsv."""


def state(b, what):
    c = b.commander()
    ships = ' '.join(f"{s['slot']}:{s['kind']}/{s['energy']}" for s in b.slots())
    b.note(f"{what}: score {c['score']} cash {c['cash'] / 10:.1f} missiles {c['missiles']} "
           f"missile state {b.byte(0xD047)} ecm {b.byte(0x9C9B)} | {ships}")


def plan(b):
    b.start()
    b.load_commander('work/tapes/k2.tap')
    t = lambda k, after=60: b.tap(k, 6, after)
    t('O', 80); t('N', 60); t('D', 100)
    b.note('launch'); t('1', 700)
    b.note('misjump option'); b.tap('CS', 15, 40); t('F', 40); t('SPACE', 60)
    b.note('hyperspace'); t('H', 60)
    b.until(lambda: b.byte(0x7103) != 0, 1500, 10)
    b.run(400)
    state(b, 'witch space')
    b.press('T')
    b.until(lambda: b.byte(0xD047) == 2, 600, 2)
    state(b, 'locked')
    b.press('F')
    state(b, 'fired')
    b.fight(300, fire=None, stop=lambda: b.mem(0x6048 + 39 * 7 + 0x22, 1)[0] == 0)
    state(b, 'missile over')
    b.press('E')
    state(b, 'ecm')
    b.run(60)
    b.fight(1500, stop=lambda: b.commander()['score'] >= 0x030000)
    state(b, 'laser')
    b.fight(600)
    state(b, 'laser 2')
    b.press('W')
    state(b, 'bomb')
    b.run(120)
    state(b, 'after bomb')
    b.fight(800)
    state(b, 'end')
