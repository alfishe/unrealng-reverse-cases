"""cs-setup: the way to the debris the cargo scoop recording cs starts from, played without recording from the title
of c1 (work/snaps/title-A.szx): the fixture work/tapes/rich.tap loaded by the game, Diso picked (O, N, D), the
launch (1), the pause menu's misjump option (CAPS SHIFT, F, SPACE), the hyperspace (H) into witch space, then the
laser (A, the pilot of tools/elitebot.py) until a Thargoid dies and leaves its plates about 1000 ahead; the state is
saved as work/snaps/cs-debris.szx (frame 6773 of this run).

    python3 tools/elitebot.py --work work/live tests/inputs/cs-setup.py

(A recorded run of the same keys plays differently: the fight there ends at close range, and the debris flies
apart faster than the ship can turn after it; this run's kill is far ahead.)"""


def plan(b):
    b.load_commander('work/tapes/rich.tap')
    t = lambda k, after=60: b.tap(k, 6, after)
    t('O', 80); t('N', 60); t('D', 100)
    t('1', 700)
    b.tap('CS', 15, 40); t('F', 40); t('SPACE', 60)
    t('H', 60)
    b.until(lambda: b.byte(0x7103) != 0, 1500, 10)
    b.run(400)
    b.fight(5000, stop=lambda: any(s['kind'] in ('Plate', 'Canister') and s['energy'] != 255 for s in b.slots()))
    print(b.frame, b.slots())
    b.save_snapshot('work/snaps/cs-debris.szx')
