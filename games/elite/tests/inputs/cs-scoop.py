"""cs: the cargo scoop, from work/snaps/cs-debris.szx (made by tests/inputs/cs-setup.py: the rich commander of
work/tapes/rich.tap, fuel scoops fitted, in witch space after a Thargoid's death, two plates of alloys about 1000
ahead). The pilot of tools/elitebot.py flies into a plate so that it passes a little below the centre (the scoop
takes only what is below, Collide `$B4D8`): the pitch keys (X, S) towards a point under the centre line, the roll
keys (N, M) while it is off to the side, SPACE and SYMBOL SHIFT for the speed; the hold gains one tonne of alloys.
The keys are in work/cs/inputs.txt, the pilot's view each step in work/cs/log.tsv.

    python3 tools/elitebot.py --work work/live tests/inputs/cs-scoop.py --record work/cs --start work/snaps/cs-debris.szx
"""


def state(b, what):
    c = b.commander()
    ships = ' '.join(f"{s['slot']}:{s['kind']}/{s['energy']}" for s in b.slots())
    b.note(f"{what}: alloys {c['hold'][9]} free {c['free']} | {ships}")


def plan(b):
    b.start()
    state(b, 'debris')
    free = b.commander()['free']
    b.scoop()
    b.run(10)
    state(b, 'scooped' if b.commander()['free'] != free else 'missed')
    b.run(100)
