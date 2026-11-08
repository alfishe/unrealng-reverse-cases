#!/usr/bin/env python3
"""Elite's galaxies as the game makes them, step for step with its code (src/game/galaxy.asm), from the image.

    python3 tools/galaxy.py [--galaxy 1] [--check]     # the 256 systems of a galaxy as a table
    python3 tools/galaxy.py --describe Lave            # a system's description, as DataScreen prints it
    python3 tools/galaxy.py --market Lave --fluctuation 0   # its market (MakeMarket) for a fluctuation byte

- Twist `$E063`: s0, s1, s2 = s1, s2, s0 + s1 + s2 (16-bit words, the carry dropped).
- NextSystem `$DFC4`: four twists. SystemName `$E01C` twists as it names: three NamePair `$E03D` (each a pair of
  StdPairs `$FDB3` picked by s2's high byte AND `$1F`, 0 none, "?" left out, then a twist) and a fourth pair when
  bit 6 of s0's low byte is set, else a plain twist: four twists either way, so naming walks to the next system.
- SystemData `$E08C`: y = s0 high, x = s1 high, the economy s0 high AND 7 (OR 2 when the government is 0 or 1), the
  government s1 low bits 3-5, the tech level, the population and the productivity.
- GalaxyJump `$DC4E` (TwistSeed `$DC83`): each of the six bytes rotated left one bit.
- The description (DataScreenDescription `$EE8C`): TextSeeds `$DECC` = s1, s2, then other token 5 through PrintOther:
  each random pick ($5B-$80) one TextRandom `$D5E1` byte (below $33, $66, $99, $CC or above: the row's first to fifth
  token), control 18 a random name (TextRandom AND 3 + 1 pairs of OtherPairs `$FD99` + 2, each by TextRandom AND
  $3E), control 17 the name with IAN (a last vowel dropped), and the case rules of PrintChar `$D499`.

--check asserts every number docs/galaxy.md quotes: galaxy 1 holds Lave (system 7) and its neighbours Diso, Leesti,
Zaonce, Reorte, Riedquat, Lave is a rich agricultural dictatorship of tech level 5 (shown, 4 stored), the seeds of
the walk to Lave and its name pair by pair, the twist's period, the eight galaxies' seeds, the name statistics,
the data histograms, the groups no 7.0 ly jump leaves, the galactic jump's arrival and Lave's description.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import elitelib as E  # noqa: E402

BASE = 0x5B00
IMAGE = os.path.join(E.CASE, 'work', 'gameout', 'game-image.bin')
GALAXY_SEEDS = 0xD232 + (0xD090 - 0xD054)  # DefaultCommander's copy of the commander's galaxy seeds $D090
STD_PAIRS = 0xFDB3
ECONOMIES = ['Rich Industrial', 'Average Industrial', 'Poor Industrial', 'Mainly Industrial', 'Mainly Agricultural',
             'Rich Agricultural', 'Average Agricultural', 'Poor Agricultural']
GOVERNMENTS = ['Anarchy', 'Feudal', 'Multi-Government', 'Dictatorship', 'Communist', 'Confederacy', 'Democracy',
               'Corporate State']


def image():
    return open(IMAGE, 'rb').read()


def byte(img, a):
    return img[a - BASE]


def galaxy_seeds(img=None):
    img = img or image()
    b = [byte(img, GALAXY_SEEDS + i) for i in range(6)]
    return [b[0] | b[1] << 8, b[2] | b[3] << 8, b[4] | b[5] << 8]


def pairs(img=None):
    img = img or image()
    return [chr(byte(img, STD_PAIRS + 2 * i)) + chr(byte(img, STD_PAIRS + 2 * i + 1)) for i in range(32)]


def twist(s):
    return [s[1], s[2], (s[0] + s[1] + s[2]) & 0xFFFF]


def rotate_galaxy(s):
    """GalaxyJump: each byte rotated left one bit"""
    out = []
    for w in s:
        lo, hi = w & 0xFF, w >> 8
        lo = ((lo << 1) | (lo >> 7)) & 0xFF
        hi = ((hi << 1) | (hi >> 7)) & 0xFF
        out.append(lo | hi << 8)
    return out


def name(s, table):
    """SystemName: the name and the seeds after it (four twists on)"""
    four = s[0] & 0x40
    text = ''
    for n in range(4 if four else 3):
        i = (s[2] >> 8) & 0x1F
        if i:
            p = table[i]
            text += p[0] + (p[1] if p[1] != '?' else '')
        s = twist(s)
    if not four:
        s = twist(s)
    return text, s


def data(s):
    """SystemData of seeds s"""
    y, x = s[0] >> 8, s[1] >> 8
    economy = (s[0] >> 8) & 7
    government = (s[1] >> 3) & 7
    if government >> 1 == 0:
        economy |= 2
    gc = government & 1
    tech = (economy ^ 7) + ((s[1] >> 8) & 3) + (government >> 1) + gc
    population = tech * 4 + economy + government + 1
    productivity = ((economy ^ 7) + 3) * (government + 4) * population * 8
    return {'x': x, 'y': y, 'economy': economy, 'government': government, 'tech': tech,
            'population': population, 'productivity': productivity & 0xFFFF}


def systems(galaxy=1, img=None):
    """the 256 systems of galaxy N (1-8): [{index, name, seeds, x, y, ...}]"""
    img = img or image()
    table = pairs(img)
    s = galaxy_seeds(img)
    for _ in range(galaxy - 1):
        s = rotate_galaxy(s)
    out = []
    for i in range(256):
        d = data(s)
        nm, _after = name(s, table)
        d.update(index=i, name=nm.capitalize(), seeds=list(s))
        out.append(d)
        for _ in range(4):
            s = twist(s)
    return out


class Printer:
    """PrintOther and PrintChar's case rules, the text flat (the justified layout left out)"""

    def __init__(self, img, system):
        self.m = bytes(BASE) + img
        self.name = system['name'].upper()
        self.seeds = [system['seeds'][1], system['seeds'][2]]
        self.out, self.case, self.capital, self.capital_next, self.other_on = [], 0, 0, 0, True

    def random(self):
        """TextRandom: SLA the first word's low byte, add the second word with the carry; A = the sum's high byte"""
        w0, w1 = self.seeds
        lo = (w0 & 0xFF) << 1
        de = (w0 & 0xFF00) | (lo & 0xFF)
        total = (w1 + de + (lo >> 8)) & 0xFFFF
        self.seeds = [total, de]
        return total >> 8

    def char(self, c):
        o = ord(c)
        if not 0x41 <= o < 0x5B:
            self.capital = 1
        elif self.case == 1:
            pass
        elif self.capital_next:
            self.capital_next = self.capital = 0
        elif self.capital == 1:
            self.capital = 0
            if self.case == 2:
                c = c.lower()
        else:
            c = c.lower()
        self.out.append(c)

    def text(self, t):
        for c in t:
            self.char(c)

    def pair(self, table, i):
        a, b = chr(self.m[table + 2 * i]), chr(self.m[table + 2 * i + 1])
        self.text(a + ('' if b == '?' else b))

    def token(self, n):
        a = self.m[0xF11C] | self.m[0xF11D] << 8
        for _ in range(n - 1):
            while self.m[a]:
                a += 1
            a += 1
        while self.m[a]:
            self.code(self.m[a])
            a += 1

    def control(self, b):
        if b == 1:
            self.case = 1
        elif b == 2:
            self.case = 0
        elif b == 3:
            self.capital_next = 1
            self.text(self.name)
        elif b == 5:
            self.other_on = True
        elif b == 6:
            self.other_on = False
        elif b == 12:
            self.out.append('\n')
        elif b == 13:
            self.case = 2
        elif b == 17:
            self.capital_next = 1
            self.text(self.name[:-1] if self.name[-1] in 'AEIOU' else self.name)
            self.text('IAN')
        elif b == 18:
            self.capital_next = 1
            for _ in range((self.random() & 3) + 1):
                self.pair(0xFD99 + 2, (self.random() & 0x3E) // 2)
        elif b == 19:
            self.capital_next = 1

    def code(self, b):
        if not self.other_on:
            raise SystemExit('a standard code inside the description: not modelled')
        if b < 0x20:
            self.control(b)
        elif b < 0x5B:
            self.char(chr(b))
        elif b < 0x81:
            row = self.m[0xD5F5 + b - 0x5B]
            r = self.random()
            self.token(row + sum(r >= k for k in (0x33, 0x66, 0x99, 0xCC)))
        elif b < 0xD7:
            self.token(b)
        else:
            self.pair(0xFD99, b - 0xD7)


COMMODITIES = 0x701B
GOODS = ['Food', 'Textiles', 'Radioactives', 'Slaves', 'Liquor/Wines', 'Luxuries', 'Narcotics', 'Computers',
         'Machinery', 'Alloys', 'Firearms', 'Furs', 'Minerals', 'Gold', 'Platinum', 'Gem-Stones', 'Alien Items']


def market(economy, fluctuation, img=None):
    """MakeMarket: [(price in tenths, stock)] of the 17 commodities, step for step with $E148"""
    img = img or image()
    out = []
    for i in range(17):
        base, factor, quantity, mask = (byte(img, COMMODITIES + 4 * i + k) for k in range(4))
        product = (economy * (factor & 0x1F)) & 0xFF
        b = (quantity + (fluctuation & mask)) & 0xFF
        a = product if factor & 0x80 else (-(product + 1)) & 0xFF   # INC A / NEG for a positive factor
        stock = (a + b) & 0xFF
        stock = 0 if stock & 0x80 else stock & 0x3F
        c = base + (fluctuation & mask)
        price = (c - product) & 0xFF if factor & 0x80 else c + product   # the carry kept for a positive factor
        if factor & 0x80:
            price |= (c >> 8) << 8
        out.append(((price * 4) & 0xFFFF, stock))
    out[16] = (out[16][0], 0)  # the alien items' stock forced to 0
    return out


def describe(system, img=None):
    p = Printer(img or image(), system)
    p.token(5)
    return ''.join(p.out).strip()


class TracingPrinter(Printer):
    """Printer that keeps the expansion as a tree: (depth, what, text it produced)"""

    def __init__(self, img, system):
        super().__init__(img, system)
        self.steps, self.depth = [], 0

    def code(self, b):
        start = len(self.out)
        what = None
        if 0x5B <= b < 0x81:
            row = self.m[0xD5F5 + b - 0x5B]
            w0, w1 = self.seeds
            r = self.random()
            self.seeds = [w0, w1]
            k = sum(r >= x for x in (0x33, 0x66, 0x99, 0xCC))
            what = 'pick $%02X: row %d, TextRandom $%02X, choice %d: token %d' % (b, row, r, k, row + k)
        elif 0x81 <= b < 0xD7:
            what = 'token $%02X' % b
        elif b in (17, 18):
            what = 'control %d (%s)' % (b, 'the name + IAN' if b == 17 else 'a random name')
        elif b == 3:
            what = 'control 3 (the system name)'
        if what:
            i = len(self.steps)
            self.steps.append([self.depth, what, ''])
        self.depth += 1
        super().code(b)
        self.depth -= 1
        if what:
            self.steps[i][2] = ''.join(self.out[start:]).replace('\n', ' ')


def describe_steps(system, img=None):
    p = TracingPrinter(img or image(), system)
    p.token(5)
    return p.steps


def distance(a, b):
    """JumpDistance in tenths of a light year: 4 x the integer root of dx^2 + (dy / 2)^2"""
    import math
    dx, dy = abs(a['x'] - b['x']), abs(a['y'] - b['y']) // 2
    return 4 * math.isqrt(dx * dx + dy * dy)


def nearest(g, x, y):
    """the system nearest (x, y) by SquaredDistance (dy halved), the first of equals"""
    return min(g, key=lambda s: (s['x'] - x) ** 2 + ((abs(s['y'] - y)) // 2) ** 2)


def clusters(g):
    """the groups a chain of jumps of 7.0 ly or less links, the largest first"""
    comp, groups = [-1] * len(g), []
    for i in range(len(g)):
        if comp[i] >= 0:
            continue
        comp[i], stack, group = len(groups), [i], []
        while stack:
            a = stack.pop()
            group.append(g[a])
            for j in range(len(g)):
                if comp[j] < 0 and distance(g[a], g[j]) <= 70:
                    comp[j] = len(groups)
                    stack.append(j)
        groups.append(group)
    return sorted(groups, key=len, reverse=True)


def check():
    """every number docs/galaxy.md quotes, asserted"""
    from collections import Counter
    g = systems(1)
    names = [x['name'] for x in g]
    for n in ('Lave', 'Diso', 'Leesti', 'Zaonce', 'Reorte', 'Riedquat'):
        assert n in names, n
    lave = g[names.index('Lave')]
    assert lave['index'] == 7, lave
    assert ECONOMIES[lave['economy']] == 'Rich Agricultural' and GOVERNMENTS[lave['government']] == 'Dictatorship'
    assert lave['tech'] == 4 and lave['population'] == 25 and lave['productivity'] == 7000, lave
    assert (lave['x'], lave['y']) == (20, 173)
    # the seeds, the walk to Lave, Lave's name step by step
    s = galaxy_seeds()
    assert s == [0x5A4A, 0x0248, 0xB753], s
    assert names[:8] == ['Tibedied', 'Qube', 'Leleer', 'Biarge', 'Xequerin', 'Tiraor', 'Rabedira', 'Lave'], names[:8]
    assert lave['seeds'] == [0xAD38, 0x149C, 0x151D], lave['seeds']
    table = pairs()
    assert ''.join(table) == 'ALLEXEGEZACEBISOUSESARMAINDIREA?ERATENBERALAVETIEDORQUANTEISRION'
    t, picks = list(lave['seeds']), []
    for _ in range(4):
        picks.append((t[2] >> 8) & 0x1F)
        t = twist(t)
    assert picks == [21, 22, 0, 12] and not lave['seeds'][0] & 0x40, picks
    tib = g[0]
    t, picks = list(tib['seeds']), []
    for _ in range(4):
        picks.append((t[2] >> 8) & 0x1F)
        t = twist(t)
    assert tib['seeds'][0] & 0x40 and [table[i] for i in picks] == ['TI', 'BE', 'DI', 'ED'], picks
    # the twist's period, and the 257th system is not the first
    t, n = list(s), 0
    while True:
        t, n = twist(t), n + 1
        if t == s:
            break
    assert n == 131072, n
    t = list(s)
    for _ in range(1024):
        t = twist(t)
    assert t == [0x564A, 0xA048, 0x8753], t
    # the galaxies' seeds and the cycle of 8
    gs, r = [], s
    for _ in range(8):
        gs.append(r)
        r = rotate_galaxy(r)
    assert r == s
    assert gs[1] == [0xB494, 0x0490, 0x6FA6] and gs[7] == [0x2D25, 0x0124, 0xDBA9], gs
    allg = [systems(k) for k in range(1, 9)]
    every = [x for gl in allg for x in gl]
    assert [gl[7]['name'] for gl in allg] == ['Lave', 'Esrilees', 'Riarribi', 'Teceteis', 'Ereddive', 'Zarienla',
                                              'Sorezaan', 'Vegedius']
    # the names
    lengths = Counter(len(x['name']) for x in every)
    assert sorted(lengths.items()) == [(2, 1), (3, 2), (4, 87), (5, 100), (6, 1023), (7, 105), (8, 730)], lengths
    assert sum(1 for x in every if x['seeds'][0] & 0x40) == 960
    by = Counter(x['name'] for x in every)
    assert sum(1 for v in by.values() if v > 1) == 25 and max(by.values()) == 2
    assert [n for n, v in Counter(x['name'] for x in allg[7]).items() if v > 1] == ['Inzaan']
    assert sorted(x['name'] for x in every if len(x['name']) <= 3) == ['Ara', 'Ra', 'Rea']
    use = Counter()
    for x in every:
        t = list(x['seeds'])
        for _ in range(4 if x['seeds'][0] & 0x40 else 3):
            use[(t[2] >> 8) & 0x1F] += 1
            t = twist(t)
    assert sum(use.values()) == 7104 and use[0] == 205 and use[15] == 229, (sum(use.values()), use[0], use[15])
    # the data
    assert [Counter(x['government'] for x in every)[k] for k in range(8)] == [288, 224] * 4
    assert [Counter(x['economy'] for x in every)[k] for k in range(8)] == [218, 181, 320, 317, 187, 176, 331, 318]
    top = [x for x in every if x['tech'] == 14]
    assert len(top) == 6 and max(every, key=lambda x: x['population'])['name'] == 'Ceesxe'
    assert min(x['population'] for x in every) == 8 and max(x['population'] for x in every) == 64
    assert max(x['productivity'] for x in every) == 56320
    # the groups no 7.0 ly jump leaves
    cut = [[len(grp) for grp in clusters(gl)[1:]] for gl in allg]
    assert cut == [[], [], [2], [], [], [2, 2], [27], [1]], cut
    assert clusters(allg[7])[1][0]['name'] == 'Oresrati'
    # the galactic jump's arrival: nearest the cursor (the Spectrum) or (96, 96) (the BBC)
    assert nearest(allg[1], 20, 173)['name'] == 'Inoran' and nearest(allg[1], 96, 96)['name'] == 'Ororra'
    # the description
    assert describe(lave) == 'Lave is most famous for its vast rain forests and the Lavian tree warthog.', \
        describe(lave)
    assert distance(lave, g[names.index('Diso')]) == 36
    print('galaxy: ok (Lave 7 at %d,%d, tech %d shown %d, population %.1f billion, productivity %d M CR; twist '
          'period %d; 2048 names, 25 repeated; 34 systems cut off)' % (
              lave['x'], lave['y'], lave['tech'], lave['tech'] + 1, lave['population'] / 10, lave['productivity'],
              n))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--galaxy', type=int, default=1)
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--describe')
    ap.add_argument('--market', help='a system: its market for the fluctuation byte --fluctuation')
    ap.add_argument('--fluctuation', type=lambda v: int(v, 0), default=0)
    a = ap.parse_args()
    if a.check:
        check()
        return
    if a.market:
        x = next(x for x in systems(a.galaxy) if x['name'].lower() == a.market.lower())
        print('%s: %s, fluctuation $%02X' % (x['name'], ECONOMIES[x['economy']], a.fluctuation))
        for g, (price, stock) in zip(GOODS, market(x['economy'], a.fluctuation)):
            print('  %-13s %6.1f Cr  %3d' % (g, price / 10, stock))
        return
    if a.describe:
        for x in systems(a.galaxy):
            if x['name'].lower() == a.describe.lower():
                print(describe(x))
        return
    for x in systems(a.galaxy):
        print('%3d %-10s %3d %3d %-20s %-16s tech %2d pop %4.1f' % (
            x['index'], x['name'], x['x'], x['y'], ECONOMIES[x['economy']], GOVERNMENTS[x['government']],
            x['tech'] + 1, x['population'] / 10))


if __name__ == '__main__':
    main()
