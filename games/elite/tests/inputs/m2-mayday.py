"""m2: the Thargoid mission, from the title of c1 (work/snaps/title-A.szx). The fixture work/tapes/mayday.tap
(tools/commander_tape.py: the galaxy-2 commander that gx saved, renamed MAYDAY, the jump count set to 253 and the
mission flags to 3, the nova and the cloak ship's triggers passed) loaded by the game at Inoran; Lemaed picked
on the chart (O, R and the name, ENTER), the launch (1), the hyperspace (H): the 254th jump outside galaxy 1 starts the MAYDAY (MissionState
1). The escape pod (Q) brings the ship to Lemaed's station, where the dock asks for the mission (Y: the briefing).
Fuel bought (4, 1), Ausis (galaxy 2's first system) picked (O, R and the name), the launch and H: the arrival there
makes the station a Thargoid base (MissionState 4); the pilot then heads for the planet (J; the bomb, the missiles
and the laser for any ship about). Played by tools/elitebot.py; the keys are in work/m2/inputs.txt, the pilot's
view each step in work/m2/log.tsv."""


def state(b, what):
    c = b.commander()
    ships = ' '.join(f"{s['slot']}:{s['kind']}/{s['energy']}" for s in b.slots())
    b.note(f"{what}: mission {c['mission']} flags ${c['flags']:02X} jumps {b.mem(0xD063, 2)[0]} cloak ship "
           f"{b.byte(0x9CB2)} score {c['score']} condition {b.byte(0x7104)} | {ships}")


def plan(b):
    b.start()
    b.load_commander('work/tapes/mayday.tap')
    t = lambda k, after=60: b.tap(k, 6, after)
    t('O', 80); t('R', 60); b.type('LEMAED', 6, 20); t('ENTER', 100)
    b.note('launch'); t('1', 700)
    b.note('hyperspace'); t('H', 60)
    b.until(lambda: b.byte(0xD03F) != 0, 300, 5)
    b.until(lambda: b.byte(0xD03F) == 0, 3000, 10)
    b.run(128)
    state(b, 'arrived')
    b.note('escape pod'); b.press('Q', 24)
    b.until(lambda: b.byte(0x7104) == 0, 1500, 5)
    b.run(100)
    state(b, 'docked')
    b.run(200)
    b.note('yes'); t('Y', 150)
    state(b, 'accepted')
    t('SPACE', 150)
    b.note('fuel'); t('4', 120); t('1', 80); t('ENTER', 80); t('L', 100)
    t('O', 80); t('R', 60); b.type('AUSIS', 6, 20); t('ENTER', 100)
    b.note('launch 2'); t('1', 700)
    b.note('hyperspace 2'); t('H', 60)
    b.until(lambda: b.byte(0xD03F) != 0, 300, 5)
    b.until(lambda: b.byte(0x711D) != 0 and b.byte(0xD03F) == 0, 3000, 10)
    b.run(128)
    state(b, 'Ausis')
    b.to_safe_zone(3000)
    state(b, 'towards the planet')
