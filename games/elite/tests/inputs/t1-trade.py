"""t1: from the title of c1 (work/snaps/title-A.szx): a new game, docked at Lave; the market (K), buy 5 t of food
and 2 t of textiles (2), the market again, sell 2 t of food (3), buy a missile (4), the inventory (ENTER), the status
(L), then save the commander as JAMESON on tape (SYMBOL SHIFT, 2, the name, ENTER, a key) and leave the menu (3).
Played by tools/elitebot.py; the keys it pressed are in work/t1/inputs.txt."""


def plan(b):
    b.start()
    t = lambda k, after=60: b.tap(k, 6, after)
    t('N', 30); t('SPACE', 300)
    b.note('docked'); t('K', 150)
    b.note('buy'); t('2', 80); t('5'); t('ENTER'); t('2'); t('ENTER'); t('L', 100)
    t('K', 150)
    b.note('sell'); t('3', 80); t('2'); t('ENTER', 100); t('L', 100)
    b.note('equip'); t('4', 80); t('2'); t('ENTER', 100); t('L', 100)
    t('ENTER', 120)
    b.note('save'); t('SS', 80); t('2', 60); b.type('JAMESON', 6, 20); t('ENTER', 60); t('SPACE', 60)
    b.run(400)
    b.note('saved'); t('3', 150)
    print(b.commander())
