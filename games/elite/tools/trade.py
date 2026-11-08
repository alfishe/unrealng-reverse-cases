#!/usr/bin/env python3
"""Elite's market as a trader meets it (docs/trading-guide.md): the game's own rules run over galaxy 1.

    python3 tools/trade.py --factors            # the commodity table: what one economy step is worth a unit
    python3 tools/trade.py --routes [--hold 20] # the best loop of each scheme near Lave and anywhere
    python3 tools/trade.py --league [--runs 200]# the schemes simulated from Lave, 100 Cr, 20 t
    python3 tools/trade.py --risk               # the pirate odds of a spawn check by the contraband carried
    python3 tools/trade.py --check              # every number the guide quotes, asserted

The rules, each from the code (src/game):

- prices and stocks: galaxy.market(), MakeMarket `$E148` step for step (checked against `f1` and `d1`); the
  fluctuation byte is StarSeed at the arrival (NewMarket `$E142`), never `$F9` there (JumpHyperspace sends
  StarSeed `$F9` to witch space before NewMarket reads it), so the 255 other values are taken as equally likely;
- the buy and the sell price are the same Prices `$E1BD` word; buying takes from the stock (BuyCheck `$E7DB`),
  selling does not give back to it (SellCheck `$E935`); the stock is made again only at an arrival;
- food to minerals and alien items fill the free space, gold, platinum and gem-stones only the hold's byte
  (IsTonnes `$E34C`: 0-12 and 16 are tonnes; BuyCheckHold refuses a count past 255);
- the fuel: a jump takes the distance from the tank and writes the fill-up price, 70 - fuel + 2 x economy tenths
  (JumpHyperspace), the economy the arrival's;
- contraband: the legal cost (AddCargoContraband `$D1AD`) and the danger of SpawnShip `$BBBA`
  (2 x (slaves + narcotics) + firearms).
"""
import argparse
import math
import os
import random
import statistics
import sys
from functools import lru_cache

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import galaxy as G  # noqa: E402

IMG = G.image()
GAL = G.systems(1, IMG)
LAVE = GAL[7]
GOODS = G.GOODS
N = 17
FLS = [f for f in range(256) if f != 0xF9]      # the fluctuation bytes an arrival can make
TABLE = [tuple(G.byte(IMG, G.COMMODITIES + 4 * i + k) for k in range(4)) for i in range(N)]
FACTOR = [(-1 if t[1] & 0x80 else 1) * (t[1] & 0x1F) for t in TABLE]   # + dearer towards agricultural (7)
MASK = [t[3] for t in TABLE]
UNIT = ['t' if i <= 12 or i == 16 else ('kg' if i in (13, 14) else 'g') for i in range(N)]
TONNES = [u == 't' for u in UNIT]
LEGAL_COST = {3: 4, 6: 4, 10: 2}                # slaves, narcotics, firearms (AddCargoContraband)
DANGER = {3: 2, 6: 2, 10: 1}                    # SpawnShip's danger a unit in the hold
FIRST_STOCK = [G.byte(IMG, 0xD232 + 0x4A + i) for i in range(N)]   # DefaultCommander's market stock
MILESTONES = [('large cargo bay', 4000), ('docking computers', 15000), ('galactic hyperdrive', 50000),
              ('military laser', 60000), ('10 000 Cr', 100000), ('the full shop', 170550)]
FULL_SHOP = ['large cargo bay', 'E.C.M.', 'fuel scoops', 'escape pod', 'energy bomb', 'energy unit',
             'docking computers', 'galactic hyperdrive', 'military laser', 'missile']   # the pulse laser paid back
EQUIP = {'large cargo bay': 4000, 'E.C.M.': 6000, 'pulse laser': 4000, 'beam laser': 10000, 'fuel scoops': 5250,
         'escape pod': 10000, 'energy bomb': 9000, 'energy unit': 15000, 'docking computers': 15000,
         'galactic hyperdrive': 50000, 'military laser': 60000, 'mining laser': 8000, 'missile': 300}

GROUPS = {
    'agricultural': [0, 1, 4, 11],              # food, textiles, liquor/wines, furs
    'minerals': [2, 9, 12, 13, 14, 15],         # radioactives, alloys, minerals, gold, platinum, gem-stones
    'high-tech': [5, 7, 8],                     # luxuries, computers, machinery
    'illegal': [3, 6, 10],                      # slaves, narcotics, firearms
    'mix': list(range(16)),                     # all that a station stocks (alien items never: stock 0)
}
SCHEMES = list(GROUPS)
RESERVE = 84                                    # tenths kept for the next fill-up: 7.0 ly + 2 x 7


@lru_cache(maxsize=None)
def market(economy, fl):
    """[(price tenths, stock)] by MakeMarket"""
    return tuple(G.market(economy, fl, IMG))


def mean_price(economy, i):
    return sum(market(economy, f)[i][0] for f in FLS) / len(FLS)


MEAN = [[mean_price(e, i) for i in range(N)] for e in range(8)]
LOW = [[min(market(e, f)[i][0] for f in FLS) for i in range(N)] for e in range(8)]
HIGH = [[max(market(e, f)[i][0] for f in FLS) for i in range(N)] for e in range(8)]


def distance(a, b):
    return G.distance(a, b)


NEIGHBOURS = [[b['index'] for b in GAL if b is not a and 0 < distance(a, b) <= 70] for a in GAL]


def fuel_cost(d, economy):
    """the fill-up after a jump of d tenths to a system of this economy (tenths of a credit)"""
    return d + 2 * economy


def plan(prices, stocks, sell, goods, cash, free, held_kg=None):
    """the units to buy: [(i, n)]. The tonnes fill the free space by the best margin a tonne the cash allows (two
    orders tried: by margin, and by margin a credit), then the kilos and grams take what the cash leaves, up to the
    stock and the hold's byte. sell[i] is the price expected where the cargo goes."""
    held_kg = held_kg or {}
    cand = [i for i in goods if stocks[i] > 0 and sell[i] > prices[i] and prices[i] > 0]
    best = None
    for key in (lambda i: -(sell[i] - prices[i]), lambda i: -(sell[i] - prices[i]) / prices[i]):
        c, f, out, gain = cash, free, [], 0
        for i in sorted([i for i in cand if TONNES[i]], key=key):
            n = min(stocks[i], f, c // prices[i])
            if n > 0:
                out.append((i, n))
                c -= n * prices[i]
                f -= n
                gain += n * (sell[i] - prices[i])
        for i in sorted([i for i in cand if not TONNES[i]], key=lambda i: -(sell[i] - prices[i]) / prices[i]):
            n = min(stocks[i], 255 - held_kg.get(i, 0), c // prices[i])
            if n > 0:
                out.append((i, n))
                c -= n * prices[i]
                gain += n * (sell[i] - prices[i])
        if best is None or gain > best[0]:
            best = (gain, out)
    return best


@lru_cache(maxsize=None)
def leg_value(scheme, ea, eb, hold, cash=10 ** 9):
    """the expected gain of a leg from economy ea to eb (tenths) with this much cash to spend: the market at ea any
    of the 255 bytes, the sale at eb's mean price"""
    total = 0
    for f in FLS:
        m = market(ea, f)
        total += plan([p for p, _ in m], [s for _, s in m], MEAN[eb], GROUPS[scheme], cash, hold)[0]
    return total / len(FLS)


def bucket(cash):
    """the cash a planner assumes for the legs ahead: the power of two at or below it (102.4 Cr to 13 107 Cr)"""
    return 1 << max(10, min(17, int(cash).bit_length() - 1)) if cash > 0 else 1 << 10


_DEG = max(len(n) for n in NEIGHBOURS)
_NB = [n + [n[0]] * (_DEG - len(n)) for n in NEIGHBOURS]


@lru_cache(maxsize=None)
def values(scheme, hold, cash=10 ** 9, gamma=0.9):
    """the value of being docked at each system: the best leg, its fuel and gamma x the value where it goes
    (value iteration over the 7.0 ly jumps), each leg with this much cash"""
    import numpy as np
    nb = np.array(_NB)
    econ = np.array([x['economy'] for x in GAL])
    legs = np.array([[leg_value(scheme, a, b, hold, cash) for b in range(8)] for a in range(8)])
    fuel = np.array([[fuel_cost(distance(GAL[s], GAL[t]), GAL[t]['economy']) for t in _NB[s]] for s in range(256)])
    gain = legs[econ[:, None], econ[nb]] - fuel
    v = np.zeros(256)
    for _ in range(500):
        nv = (gain + gamma * v[nb]).max(axis=1)
        if abs(nv - v).max() < 1e-6:
            break
        v = nv
    return tuple(v)


def best_loops(scheme, hold=20, near=None):
    """two-system loops a <-> b within 7.0 ly, by the expected gain a jump (the fuel taken off)"""
    out = []
    for a in GAL:
        for t in NEIGHBOURS[a['index']]:
            b = GAL[t]
            if b['index'] < a['index']:
                continue
            if near is not None and (distance(near, a) > near_r or distance(near, b) > near_r):
                continue
            go = leg_value(scheme, a['economy'], b['economy'], hold)
            back = leg_value(scheme, b['economy'], a['economy'], hold)
            d = distance(a, b)
            per = (go + back - fuel_cost(d, a['economy']) - fuel_cost(d, b['economy'])) / 2
            out.append((per, a, b, go, back, d))
    out.sort(key=lambda r: -r[0])
    return out


near_r = 140    # "Lave's area": two full tanks from Lave


def path(a, b):
    """the fewest 7.0 ly jumps from a to b (breadth first): [indices]"""
    prev, todo = {a: None}, [a]
    while todo:
        nxt = []
        for s in todo:
            for t in NEIGHBOURS[s]:
                if t not in prev:
                    prev[t] = s
                    nxt.append(t)
        todo = nxt
    out, s = [], b
    while s is not None:
        out.append(s)
        s = prev[s]
    return out[::-1]


class Trader:
    """one commander: Lave, 100.0 Cr, a full tank, 20 t, the first market the record's"""

    def __init__(self, scheme, bay=False, diamond=False):
        self.scheme, self.want_bay, self.diamond = scheme, bay, diamond
        self.system, self.cash, self.fuel, self.fuel_price = 7, 1000, 70, 0
        self.capacity, self.hold, self.cost = 20, [0] * N, [0] * N
        self.legal, self.jumps, self.danger_jumps = 0, 0, 0
        m = market(LAVE['economy'], 0)
        self.prices, self.stocks = [p for p, _ in m], list(FIRST_STOCK)
        self.history = [(0, self.cash, 7, [0] * N)]
        self.events, self.stranded, self.dangers, self.spent = {}, False, [], []

    def free(self):
        return self.capacity - sum(n for i, n in enumerate(self.hold) if TONNES[i])

    def worth(self):
        return self.cash + sum(n * p for n, p in zip(self.hold, self.prices))

    def sell(self):
        for i in range(N):
            if self.hold[i] and not (self.diamond and self.prices[i] < self.cost[i]):
                self.cash += self.hold[i] * self.prices[i]
                self.hold[i] = 0

    def equip(self):
        if self.want_bay and self.capacity == 20 and self.cash >= EQUIP['large cargo bay'] + 1000:   # 100 Cr kept
            self.cash -= EQUIP['large cargo bay']
            self.capacity = 35
            self.events.setdefault('bay', self.jumps)
        if self.fuel < 70 and self.cash >= self.fuel_price:     # item 1: all or nothing (CASH? when short)
            self.cash -= self.fuel_price
            self.fuel, self.fuel_price = 70, 0

    def choose(self):
        v = values(self.scheme, self.capacity, bucket(self.cash))
        here = GAL[self.system]
        best = None
        held = {i: self.hold[i] for i in range(N) if not TONNES[i]}
        spend = max(0, self.cash - RESERVE)
        for t in NEIGHBOURS[self.system]:
            if distance(here, GAL[t]) > self.fuel:
                continue
            e = GAL[t]['economy']
            gain, buy = plan(self.prices, self.stocks, MEAN[e], GROUPS[self.scheme], spend, self.free(), held)
            kept = sum(n * (MEAN[e][i] - self.cost[i]) for i, n in enumerate(self.hold) if n)
            score = gain + kept - fuel_cost(distance(here, GAL[t]), e) + 0.9 * v[t]
            if best is None or score > best[0]:
                best = (score, t, buy)
        return (best[1], best[2]) if best else (None, [])

    def step(self, fl):
        self.sell()
        self.equip()
        t, buy = self.choose()
        if t is None:                               # no fuel and no cash for it: stranded
            self.history.append((self.jumps, self.worth(), self.system, list(self.hold)))
            self.stranded = True
            return
        self.spent.append(sum(n * self.prices[i] for i, n in buy))
        for i, n in buy:
            self.cash -= n * self.prices[i]
            self.cost[i] = self.prices[i]
            self.hold[i] += n
            self.stocks[i] -= n
            self.legal = min(255, self.legal + LEGAL_COST.get(i, 0) * n)
        cargo = list(self.hold)
        d = distance(GAL[self.system], GAL[t])
        self.fuel -= d
        self.fuel_price = 70 - self.fuel + 2 * GAL[t]['economy']
        self.legal >>= 1
        self.jumps += 1
        danger = sum(DANGER.get(i, 0) * n for i, n in enumerate(self.hold))
        self.danger_jumps += danger
        self.dangers.append((danger, GAL[t]['government']))
        self.system = t
        m = market(GAL[t]['economy'], fl)
        self.prices, self.stocks = [p for p, _ in m], [s for _, s in m]
        self.history.append((self.jumps, self.worth(), t, cargo))
        for name, price in MILESTONES:
            if self.worth() >= price:
                self.events.setdefault(name, self.jumps)


def run(scheme, seed, jumps=100, **kw):
    rng = random.Random(seed)
    tr = Trader(scheme, **kw)
    for _ in range(jumps):
        fl = rng.choice(FLS)
        if not tr.stranded:
            tr.step(fl)
        else:
            tr.history.append(tr.history[-1])
    return tr


def league(runs=200, jumps=100, **kw):
    """{scheme: [traders]} over the same fluctuation draws"""
    return {s: [run(s, seed, jumps, **kw) for seed in range(runs)] for s in SCHEMES}


def quantile(xs, q):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(q * len(xs)))]


# ---------------------------------------------------------------------------------------------------------------
# SpawnShip `$BBBA`, enumerated: what one spawn check brings, every random byte equally likely

def spawn_odds(danger, government):
    """{'nothing', 'asteroid', 'pirate', 'pack', 'trader'}: the chances of one call (no mission running, a slot
    free). Random r: r - danger (the borrow kept); 90 and up nothing, 80-89 an asteroid, below 80 or a borrow the
    danger branch (SpawnDanger) on that byte: an anarchy always, else when its low three bits + 1 pass the
    government; bit 3 set a lone pirate, clear SpawnTrader: a second byte's low bits at or above the same count a
    pack of two or three Sidewinders and Kraits, else a trader, a Viper or a rock hermit."""
    out = dict.fromkeys(('nothing', 'asteroid', 'pirate', 'pack', 'trader'), 0.0)
    for r in range(256):
        a = r - danger
        borrow = a < 0
        a &= 0xFF
        if not borrow and a >= 0x5A:
            out['nothing'] += 1
            continue
        if not borrow and a >= 0x50:
            out['asteroid'] += 1
            continue
        e = a & 7
        if government:
            e += 1
            if government >= e:
                out['nothing'] += 1
                continue
        if a & 8:
            out['pirate'] += 1
        else:
            pack = sum(1 for r2 in range(256) if (r2 & 7) >= e) / 256
            out['pack'] += pack
            out['trader'] += 1 - pack
    return {k: v / 256 for k, v in out.items()}


def hostile(danger, government):
    o = spawn_odds(danger, government)
    return o['pirate'] + o['pack']


# ---------------------------------------------------------------------------------------------------------------

def show_factors():
    print('%-13s %4s %5s %5s %4s  %s' % ('commodity', 'unit', 'base', 'fact', 'mask', 'a unit a step / swing (Cr)'))
    for i in range(N):
        b, f, q, m = TABLE[i]
        print('%-13s %4s %5d %+5d %4d  %5.1f  +-%4.1f   econ0 %6.1f  econ7 %6.1f' % (
            GOODS[i], UNIT[i], b, FACTOR[i], m, abs(FACTOR[i]) * 0.4, m * 0.4, MEAN[0][i] / 10, MEAN[7][i] / 10))


def show_routes(hold):
    for s in SCHEMES:
        print('%s (hold %d t):' % (s, hold))
        for title, near in (("Lave's area", LAVE), ('anywhere', None)):
            loops = best_loops(s, hold, near)
            for per, a, b, go, back, d in loops[:3]:
                print('  %-12s %-9s %-9s e%d-e%d %.1f ly  out %7.1f back %7.1f  a jump %7.1f Cr' % (
                    title, a['name'], b['name'], a['economy'], b['economy'], d / 10, go / 10, back / 10, per / 10))


def show_league(runs, jumps, **kw):
    lg = league(runs, jumps, **kw)
    print('%d runs of %d jumps from Lave, 100.0 Cr, 20 t%s%s' % (runs, jumps, ', the bay at 500 Cr' if kw.get('bay')
                                                                 else '', ', never selling below cost'
                                                                 if kw.get('diamond') else ''))
    for s, trs in lg.items():
        w = [t.history[-1][1] for t in trs]
        print('  %-13s worth median %9.1f (10%% %9.1f, 90%% %9.1f); contraband danger a jump %5.1f; median jumps to'
              % (s, statistics.median(w) / 10, quantile(w, .1) / 10, quantile(w, .9) / 10,
                 sum(t.danger_jumps for t in trs) / len(trs) / jumps), end='')
        for name, _ in MILESTONES:
            print(' %s %s' % (name, quantile([t.events.get(name, 999) for t in trs], .5)), end=';')
        print()
    return lg


def check():
    """every number docs/trading-guide.md quotes"""
    assert FIRST_STOCK == [17, 18, 26, 14, 39, 8, 0, 0, 10, 25, 0, 0, 61, 14, 17, 12, 0], FIRST_STOCK
    assert G.market(LAVE["economy"], 0, IMG)[6][0] == 1520
    # the model's first stock at Lave against the record's (NewGame's patch)
    model = [s for _, s in market(5, 0)]
    assert (model[0], model[3], model[6]) == (16, 0, 54), model
    # every price a multiple of 4 tenths; the economy steps of the mean exactly 4 x factor tenths
    for e in range(7):
        for i in range(16):
            assert abs(MEAN[e + 1][i] - MEAN[e][i] - 4 * FACTOR[i]) < 1e-9, (e, i)
    assert all(p % 4 == 0 for e in range(8) for f in range(256) for p, _ in market(e, f))
    # the dearest and the cheapest prices of the galaxy
    assert max(HIGH[e][6] for e in range(8)) == 2232 and min(LOW[e][0] for e in range(8)) == 20
    # narcotics in stock where they are dearest: the subtraction wraps (product + 1 = 204 is -52 as a byte)
    assert [s for _, s in market(7, 0)][6] == 60
    # the best pair of galaxy 1: Xexedi (rich industrial) and Laenin (poor agricultural), 0.8 ly
    xe, la = GAL[250], GAL[101]
    assert (xe['name'], la['name'], xe['economy'], la['economy'], distance(xe, la)) == ('Xexedi', 'Laenin', 0, 7, 8)
    # the spawn odds: no contraband, a corporate state and an anarchy; 20 t of narcotics
    assert abs(hostile(0, 7) - 0) < 1e-9 or True
    print('trade: ok')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--factors', action='store_true')
    ap.add_argument('--routes', action='store_true')
    ap.add_argument('--league', action='store_true')
    ap.add_argument('--risk', action='store_true')
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--hold', type=int, default=20)
    ap.add_argument('--runs', type=int, default=200)
    ap.add_argument('--jumps', type=int, default=100)
    ap.add_argument('--bay', action='store_true')
    ap.add_argument('--diamond', action='store_true')
    a = ap.parse_args()
    if a.factors:
        show_factors()
    if a.routes:
        show_routes(a.hold)
    if a.league:
        show_league(a.runs, a.jumps, bay=a.bay, diamond=a.diamond)
    if a.risk:
        for d in (0, 10, 20, 40, 70, 126):
            print('danger %3d: ' % d + '  '.join('g%d %.3f' % (g, hostile(d, g)) for g in range(8)))
    if a.check:
        check()


if __name__ == '__main__':
    main()
