"""m1: the nova mission, from the title of c1 (work/snaps/title-A.szx). The fixture work/tapes/nova.tap
(tools/commander_tape.py: the galaxy-2 commander that gx saved, renamed NOVA, the jump count set to 31) loaded by
the game at Inoran; Atrazama picked on the chart (O, R and the name, ENTER), the launch (1), the hyperspace (H): the
32nd jump outside galaxy 1 starts the nova (the view red, the fuel leaked). The escape pod (Q) brings the ship to
Atrazama's station; there the buy key (2) asks THE SUN IS GOING NOVA, WILL YOU SAVE US, Y takes the refugees. Fuel
bought (4, 1), Vearin picked, the launch and H: out of the nova's system the jump goes to the next galaxy, to the
system nearest the cursor there (Ceedleon, a corporate state: few ships). In galaxy 3 the pilot jumps to the planet
(J, the energy bomb, missiles and the laser for any ship about), docks with the docking computer (C), and the sell
key (3) gives the reward. Played by tools/elitebot.py; the keys are in work/m1/inputs.txt."""


def state(b, what):
    c = b.commander()
    b.note(f"{what}: nova {b.byte(0xD081)} flags ${c['flags']:02X} jumps {b.mem(0xD063, 2)[0]} galaxy "
           f"{c['galaxy'] + 1} fuel {c['fuel'] / 10:.1f} free {c['free']} gems {c['hold'][15]} score {c['score']} "
           f"condition {b.byte(0x7104)}")


def plan(b):
    b.start()
    b.load_commander('work/tapes/nova.tap')
    t = lambda k, after=60: b.tap(k, 6, after)
    t('O', 80); t('R', 60); b.type('ATRAZAMA', 6, 20); t('ENTER', 100)
    b.note('launch'); t('1', 700)
    b.note('hyperspace'); t('H', 60)
    b.until(lambda: b.byte(0xD03F) != 0, 300, 5)
    b.until(lambda: b.byte(0xD03F) == 0, 3000, 10)
    b.run(128)
    state(b, 'arrived')
    b.note('escape pod'); b.press('Q', 24)
    b.until(lambda: b.byte(0x7104) == 0, 1500, 5)
    b.run(300)
    state(b, 'docked')
    b.note('buy key'); t('2', 150)
    b.note('yes'); t('Y', 150)
    state(b, 'refugees')
    b.note('fuel'); t('4', 120); t('1', 80); t('ENTER', 80); t('L', 100)
    t('O', 80); t('R', 60); b.type('VEARIN', 6, 20); t('ENTER', 100)
    b.note('launch 2'); t('1', 700)
    b.note('hyperspace 2'); t('H', 60)
    b.until(lambda: b.byte(0xD03F) != 0, 300, 5)
    b.until(lambda: b.byte(0xD03F) == 0, 3000, 10)
    b.run(200)
    state(b, 'galaxy 3')
    b.to_safe_zone(20000)
    state(b, 'safe zone')
    b.dock()
    b.run(300)
    state(b, 'docked 2')
    b.note('sell key'); t('3', 150)
    state(b, 'reward')
    t('SPACE', 150)
    b.note('status'); t('L', 150)
