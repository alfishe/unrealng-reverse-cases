#!/usr/bin/env python3
"""The figures of docs/galaxy.md, all from tools/galaxy.py (the game's generator step for step).

    python3 tools/fig_galaxy_md.py [seeds] [twist] [pairs] [names] [hist] [rotate]   # all when none named

- docs/img/galaxy/seeds.png: the three seed words of Lave bit by bit, each bit coloured by what reads it;
- docs/img/galaxy/twist.gif: from galaxy 1's seeds to Lave: the 28 twists, the words in binary, the pair each
  naming step picks, the names as they are made;
- docs/img/galaxy/pairs.png: the 32 two-letter pairs of StdPairs `$FDB3` and how often the 2048 names use each,
  the two holes (pair 0 means "no letters", pair 15 is one letter);
- docs/img/galaxy/names.png: the 2048 names: lengths, three or four pairs, the repeated names;
- docs/img/galaxy/hist.png: the economy, government, tech level and population of the 2048 systems;
- docs/img/galaxy/rotate.png: the galaxy seeds of galaxies 1-8 in binary, each byte rotated a bit per galaxy.
"""
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import galaxy as G  # noqa: E402
import rtplot as P  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402
import kitlib as K  # noqa: E402

OUT = os.path.join(G.E.CASE, 'docs', 'img', 'galaxy')
BG = (14, 14, 20)
TEXT = (220, 220, 230)
DIM = (110, 110, 125)
C_Y, C_ECO, C_FOUR, C_X, C_TECH, C_GOV, C_PAIR, C_TXT = [(80, 160, 255), (255, 170, 60), (240, 90, 90),
                                                         (80, 230, 110), (255, 230, 90), (190, 130, 255),
                                                         (60, 210, 210), (150, 150, 165)]


def use_of(word, bit):
    """what SystemData / SystemName read from bit `bit` (0 = lowest) of seed word `word`"""
    if word == 0:
        if bit >= 8:
            return (C_ECO, 'economy (and y)') if bit < 11 else (C_Y, 'y on the chart')
        if bit == 6:
            return C_FOUR, 'four pairs when set'
    if word == 1:
        if bit >= 8:
            return (C_TECH, 'tech level add (and x)') if bit < 10 else (C_X, 'x on the chart')
        if 3 <= bit <= 5:
            return C_GOV, 'government'
    if word == 2 and 8 <= bit <= 12:
        return C_PAIR, 'name pair index (each twist)'
    return None, None


def seeds():
    lave = G.systems(1)[7]
    s = lave['seeds']
    f, small = K.font(16), K.font(12)
    cell = 34
    im = Image.new('RGB', (16 * cell + 560, 3 * 92 + 90), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 8), "Lave's seeds bit by bit: what each bit becomes (s0, s1, s2 = %04X %04X %04X)" % tuple(s),
           fill=TEXT, font=f)
    for w in range(3):
        y = 50 + w * 92
        d.text((10, y + 8), 's%d' % w, fill=TEXT, font=f)
        d.text((10, y + 30), '%04X' % s[w], fill=DIM, font=small)
        for i in range(16):
            bit = 15 - i
            x = 60 + i * cell
            col, _ = use_of(w, bit)
            v = (s[w] >> bit) & 1
            d.rectangle((x, y, x + cell - 3, y + cell * 1.2), fill=col if col else (40, 40, 52),
                        outline=(70, 70, 85))
            d.text((x + 11, y + 8), str(v), fill=(10, 10, 14) if col else TEXT, font=f)
            d.text((x + 9, y + cell * 1.2 + 3), '%d' % bit, fill=DIM, font=small)
        d.line((60 + 8 * cell - 2, y - 4, 60 + 8 * cell - 2, y + cell * 1.2 + 4), fill=TEXT, width=2)
    d.text((60, 50 + 3 * 92 - 18), 'high byte (bits 15-8) | low byte (bits 7-0); s1 and s2 also seed the '
           'description (TextSeeds)', fill=DIM, font=small)
    legend = [(C_Y, 'y = s0 high (%d)' % lave['y']), (C_ECO, 'economy = s0 high AND 7 (%d: %s)' % (
        lave['economy'], G.ECONOMIES[lave['economy']])), (C_FOUR, 'bit 6 of s0 low: a fourth pair (%s)' % (
            'set' if s[0] & 0x40 else 'clear: three pairs')),
        (C_X, 'x = s1 high (%d)' % lave['x']), (C_TECH, 's1 high AND 3: added to the tech level (%d)' % (
            (s[1] >> 8) & 3)), (C_GOV, 'government = s1 bits 3-5 (%d: %s)' % (
                lave['government'], G.GOVERNMENTS[lave['government']])),
        (C_PAIR, 's2 high AND $1F: a name pair, read after each twist')]
    for k, (col, text) in enumerate(legend):
        x0, y0 = 16 * cell + 80, 50 + k * 30
        d.rectangle((x0, y0, x0 + 16, y0 + 16), fill=col)
        d.text((x0 + 24, y0), text, fill=TEXT, font=small)
    im.save(os.path.join(OUT, 'seeds.png'))
    print('wrote docs/img/galaxy/seeds.png')


def twist():
    """the 28 twists from system 0 to Lave (system 7), plus Lave's own four"""
    tab = G.pairs()
    s = G.galaxy_seeds()
    f, small = K.font(15), K.font(12)
    pics, names = [], []
    for system in range(8):
        four = s[0] & 0x40
        t, name = list(s), ''
        for step in range(4):
            idx = (t[2] >> 8) & 0x1F
            reads = step < 3 or four
            if reads and idx:
                p = tab[idx]
                name += p[0] + (p[1] if p[1] != '?' else '')
            im = Image.new('RGB', (900, 330), BG)
            d = ImageDraw.Draw(im)
            d.text((10, 8), 'Galaxy 1, system %d, twist %d of 4: s0, s1, s2 = s1, s2, s0 + s1 + s2' % (system,
                                                                                                    step + 1),
                   fill=TEXT, font=f)
            for w in range(3):
                y = 46 + 40 * w
                d.text((10, y), 's%d %04X' % (w, t[w]), fill=TEXT, font=f)
                for i in range(16):
                    bit = 15 - i
                    v = (t[w] >> bit) & 1
                    col = (60, 210, 210) if (w == 2 and 8 <= bit <= 12) else (
                        (240, 90, 90) if (w == 0 and bit == 6 and step == 0) else (52, 52, 66))
                    x = 140 + i * 26
                    d.rectangle((x, y, x + 22, y + 26), fill=col if v else BG, outline=col)
            d.text((10, 176), 'pair index = s2 high AND $1F = %d -> %s' % (
                idx, ('"%s"' % tab[idx].replace('?', '') if idx else 'none (0)') if reads else
                'not read (three pairs: bit 6 of s0 was clear)'), fill=(60, 210, 210), font=f)
            d.text((10, 206), 'name so far: %s' % name, fill=(255, 210, 70), font=f)
            d.text((10, 246), 'earlier: ' + ', '.join(names[-7:]), fill=DIM, font=small)
            pics.append(im)
            t = G.twist(t)
        names.append(name.capitalize())
        for _ in range(4):
            s = G.twist(s)
    K.save_gif(os.path.join(OUT, 'twist.gif'), pics, [700] * (len(pics) - 1) + [3000])
    print('wrote docs/img/galaxy/twist.gif', len(pics), 'pictures:', names)


def pair_use():
    tab = G.pairs()
    use = Counter()
    for g in range(1, 9):
        for x in G.systems(g):
            t = list(x['seeds'])
            for n in range(4 if x['seeds'][0] & 0x40 else 3):
                use[(t[2] >> 8) & 0x1F] += 1
                t = G.twist(t)
    return tab, use


def pairs():
    tab, use = pair_use()
    fig, ax = P.figure(13, 4.6)
    cols = [P.HOT if i == 0 else (P.WRITE if '?' in tab[i] else P.READ) for i in range(32)]
    ax.bar(range(32), [use[i] for i in range(32)], color=cols)
    ax.set_xticks(range(32))
    ax.set_xticklabels(['%d\n%s' % (i, '-' if i == 0 else tab[i].replace('?', '')) for i in range(32)],
                       fontsize=8.5)
    ax.set_ylabel('picks over the 2048 names')
    total = sum(use.values())
    ax.set_title('StdPairs $FDB3: the 32 pairs and their use in all 8 galaxies (%d picks). Red: index 0 picks '
                 'nothing (its "AL" never appears); yellow: "A?" gives one letter' % total, fontsize=10, loc='left')
    P.save(fig, 'docs/img/galaxy/pairs.png')


def names():
    allg = [x for g in range(1, 9) for x in G.systems(g)]
    lengths = Counter(len(x['name']) for x in allg)
    four = sum(1 for x in allg if x['seeds'][0] & 0x40)
    fig, (ax, bx) = P.figure(13, 4.4, ncols=2, gridspec_kw={'width_ratios': [1, 1.2]})
    ks = sorted(lengths)
    ax.bar(ks, [lengths[k] for k in ks], color=P.READ)
    for k in ks:
        ax.text(k, lengths[k] + 12, str(lengths[k]), ha='center', fontsize=8.5, color=P.TEXT)
    ax.set_xlabel('letters in the name')
    ax.set_ylabel('systems (all 8 galaxies)')
    ax.set_title('Lengths: %d names of three pairs, %d of four' % (2048 - four, four),
                 fontsize=10, loc='left')
    by = {}
    for g in range(1, 9):
        for x in G.systems(g):
            by.setdefault(x['name'], []).append((g, x['index']))
    dups = sorted((n, v) for n, v in by.items() if len(v) > 1)
    bx.axis('off')
    bx.set_title('%d names used twice (galaxy:system; red, twice in one galaxy)' % len(dups), fontsize=10,
                 loc='left')
    for k, (n, v) in enumerate(dups):
        same = v[0][0] == v[1][0]
        bx.text((k // 13) * 0.5, 0.93 - (k % 13) * 0.072, '%-9s %s' % (n, '  '.join('%d:%d' % gv for gv in v)),
                fontsize=8.5, family='monospace', color=P.HOT if same else P.TEXT, transform=bx.transAxes)
    P.save(fig, 'docs/img/galaxy/names.png')


def hist():
    allg = [x for g in range(1, 9) for x in G.systems(g)]
    fig, axes = P.figure(14, 7.2, nrows=2, ncols=2)
    (a, b), (c, d) = axes
    eco = Counter(x['economy'] for x in allg)
    a.barh(range(8), [eco[i] for i in range(8)], color=P.READ)
    a.set_yticks(range(8))
    a.set_yticklabels(G.ECONOMIES, fontsize=8.5)
    a.set_title('Economy: 2, 3, 6, 7 commoner, as bit 1 is forced for anarchies and feudal states', fontsize=9.5,
                loc='left')
    gov = Counter(x['government'] for x in allg)
    b.barh(range(8), [gov[i] for i in range(8)], color=P.EXEC)
    b.set_yticks(range(8))
    b.set_yticklabels(G.GOVERNMENTS, fontsize=8.5)
    b.set_title('Government: 288 each for the even ones, 224 for the odd', fontsize=9.5, loc='left')
    tech = Counter(x['tech'] + 1 for x in allg)
    c.bar(sorted(tech), [tech[k] for k in sorted(tech)], color=P.WRITE)
    c.set_xlabel('tech level as shown (stored + 1)')
    c.set_title('Tech level 1-15: a sum of three small terms, so a hump', fontsize=9.5, loc='left')
    pop = Counter(x['population'] for x in allg)
    d.bar(sorted(pop), [pop[k] for k in sorted(pop)], color=P.HOT, width=0.8)
    d.set_xlabel('population (tenths of a billion)')
    d.set_title('Population 0.8-6.4 billion', fontsize=9.5, loc='left')
    fig.suptitle('The 2048 systems of the 8 galaxies: what three 16-bit seeds give', fontsize=12)
    fig.tight_layout()
    P.save(fig, 'docs/img/galaxy/hist.png')


def rotate():
    s = G.galaxy_seeds()
    f, small = K.font(14), K.font(11)
    cell = 13
    im = Image.new('RGB', (48 * cell + 260, 9 * 30 + 80), BG)
    d = ImageDraw.Draw(im)
    d.text((8, 8), 'GalaxyJump: each of the six seed bytes rotated left one bit (RLC); galaxy 9 is galaxy 1 again',
           fill=TEXT, font=f)
    for g in range(9):
        y = 44 + g * 30
        d.text((8, y + 2), 'galaxy %d' % (g + 1 if g < 8 else 1), fill=TEXT if g < 8 else (255, 210, 70), font=small)
        bits = ''.join(format(w & 0xFF, '08b') + format(w >> 8, '08b') for w in s)
        for i, ch in enumerate(bits):
            x = 100 + i * cell + (i // 8) * 3
            byte = i // 8
            col = P.PALETTE[byte]
            colour = tuple(int(255 * v) for v in col)
            d.rectangle((x, y, x + cell - 3, y + 20), fill=colour if ch == '1' else BG, outline=colour)
        s = G.rotate_galaxy(s)
    d.text((100, 44 + 9 * 30 + 4), 'bytes in memory order: s0 low, s0 high, s1 low, s1 high, s2 low, s2 high',
           fill=DIM, font=small)
    im.save(os.path.join(OUT, 'rotate.png'))
    print('wrote docs/img/galaxy/rotate.png')


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for n in sys.argv[1:] or ['seeds', 'twist', 'pairs', 'names', 'hist', 'rotate']:
        globals()[n]()
