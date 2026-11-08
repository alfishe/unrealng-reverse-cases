#!/usr/bin/env python3
"""The eight galaxies and the trade between systems, from tools/galaxy.py (the game's own generator, step for step).

    python3 tools/fig_galaxies.py [galaxies] [route]        # all when none named

- docs/img/galaxy/galaxies.png: the eight galaxies, each 256 systems coloured by economy; the systems no chain of
  7.0 ly jumps (a full tank) links to the galaxy's main group ringed in red and named, system 7 of each marked;
- docs/img/galaxy/route.png: Lave's neighbourhood with the best legal trade on each jump in range, at the
  fluctuation 0 the market of an arrival starts from (MakeMarket `$E148`): the commodity and the credits a tonne
  earns, and the round trip that pays best for a new commander (20 t, 100.0 Cr).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import galaxy as G  # noqa: E402
import numpy as np  # noqa: E402
import rtplot as P  # noqa: E402

OUT = os.path.join(G.E.CASE, 'docs', 'img', 'galaxy')
ILLEGAL = {'Slaves', 'Narcotics', 'Firearms'}


distance, clusters = G.distance, G.clusters


def galaxies():
    os.makedirs(OUT, exist_ok=True)
    cmap = P.plt.get_cmap('coolwarm')
    fig, axes = P.figure(9, 12, nrows=4, ncols=2)
    stranded = 0
    for n, ax in enumerate(axes.flat, 1):
        g = G.systems(n)
        groups = clusters(g)
        cut = [x for grp in groups[1:] for x in grp]
        stranded += len(cut)
        ax.scatter([x['x'] for x in g], [x['y'] for x in g], s=[3 + 1.2 * x['tech'] for x in g],
                   c=[cmap(x['economy'] / 7) for x in g], lw=0)
        ax.scatter([x['x'] for x in cut], [x['y'] for x in cut], s=55, facecolors='none', edgecolors=P.HOT, lw=1)
        for grp in groups[1:]:
            far = grp[0]
            ax.text(far['x'] + 5, far['y'] + 9, ', '.join(x['name'] for x in grp[:2]) +
                    (' + %d' % (len(grp) - 2) if len(grp) > 2 else ''), color=P.HOT, fontsize=8.5)
        x = g[7]
        ax.scatter([x['x']], [x['y']], s=40, marker='+', color=P.WRITE)
        ax.text(x['x'] + 4, x['y'], x['name'], color=P.WRITE, fontsize=9, va='center')
        ax.set_xlim(-4, 260)
        ax.set_ylim(260, -4)
        ax.set_aspect(0.5)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_title('galaxy %d: %s' % (n, 'all 256 linked' if len(groups) == 1 else
                                         '%d cut off' % len(cut)), fontsize=10, loc='left')
    handles = [P.plt.matplotlib.patches.Patch(color=cmap(e / 7), label=nm) for e, nm in enumerate(G.ECONOMIES)]
    handles.append(P.plt.matplotlib.lines.Line2D([], [], marker='o', ls='', mfc='none', mec=P.HOT,
                                                 label='cut off: no chain of 7.0 ly jumps to the rest'))
    fig.legend(handles=handles, loc='lower center', ncol=3, fontsize=9, frameon=False)
    fig.suptitle('The eight galaxies from one set of seeds: %d of the 2048 systems sit in groups no 7.0 ly jump '
                 'leaves (red); yellow, system 7 of each' % stranded, fontsize=12)
    fig.tight_layout(rect=(0, 0.08, 1, 0.94))
    P.save(fig, 'docs/img/galaxy/galaxies.png')


def best_trade(a, b, cash=1000, hold=20):
    """the legal commodity that earns most a tonne bought at a and sold at b (fluctuation 0), and the first
    load's profit for cash (tenths) and hold (t)"""
    ma, mb = G.market(a['economy'], 0), G.market(b['economy'], 0)
    best = None
    for i, nm in enumerate(G.GOODS):
        if nm in ILLEGAL or ma[i][1] == 0 or i == 16:
            continue
        gain = mb[i][0] - ma[i][0]
        units = min(ma[i][1], hold if i not in (13, 14, 15) else 200, cash // ma[i][0])
        load = units * gain
        if best is None or load > best[2]:
            best = (nm, gain, load, units)
    return best


def route():
    os.makedirs(OUT, exist_ok=True)
    g = G.systems(1)
    lave = g[7]
    near = [x for x in g if distance(lave, x) <= 120 and abs(x['x'] - lave['x']) <= 32]
    cmap = P.plt.get_cmap('coolwarm')
    fig, ax = P.figure(12, 8.5)
    ax.scatter([x['x'] for x in near], [x['y'] for x in near], s=[60 + 12 * x['tech'] for x in near],
               c=[cmap(x['economy'] / 7) for x in near], lw=0, zorder=3)
    pairs = []
    for a in near:
        for b in near:
            if a is not b and distance(a, b) <= 70:
                t = best_trade(a, b)
                if t and t[1] > 0:
                    pairs.append((a, b, t))
    # the best round trip a -> b -> a
    loops = []
    for a, b, t in pairs:
        back = next((t2 for a2, b2, t2 in pairs if a2 is b and b2 is a), None)
        if back:
            loops.append((t[1] + back[1], a, b, t, back))
    loops.sort(key=lambda r: -r[0])
    top = loops[0]
    for a, b, t in pairs:
        if a is lave:
            ax.annotate('', xy=(b['x'], b['y']), xytext=(a['x'], a['y']),
                        arrowprops=dict(arrowstyle='->', color=P.DIM, lw=0.8, shrinkA=8, shrinkB=8))
            if a is lave:
                ax.text((a['x'] + b['x']) / 2, (a['y'] + b['y']) / 2 + 2.2, '%s +%.1f' % (t[0], t[1] / 10),
                        color=P.DIM, fontsize=8, ha='center', va='center',
                        bbox={'facecolor': P.PANEL, 'edgecolor': 'none', 'pad': 0.5})
    _, a, b, t, back = top
    for p, q, tt, col in ((a, b, t, P.EXEC), (b, a, back, P.WRITE)):
        ax.annotate('', xy=(q['x'], q['y']), xytext=(p['x'], p['y']),
                    arrowprops=dict(arrowstyle='-|>', color=col, lw=2.2, shrinkA=9, shrinkB=9,
                                    connectionstyle='arc3,rad=0.18'))
    names = [(x['x'], x['y'], x['name'], 'right') for x in near]
    tt = np.linspace(0, 2 * math.pi, 200)
    ax.plot(lave['x'] + 17.5 * np.cos(tt), lave['y'] + 35 * np.sin(tt), color=P.WRITE, lw=0.8, ls='--')
    ax.text(lave['x'], lave['y'] + 37.5, "Lave's 7.0 ly range", color=P.WRITE, fontsize=8.5, ha='center', va='top')
    ax.set_ylim(max(x['y'] for x in near) + 8, min(x['y'] for x in near) - 8)
    ax.set_xlim(min(x['x'] for x in near) - 4, max(x['x'] for x in near) + 30)
    ax.set_aspect(0.5)
    ax.set_xlabel('x (chart units)')
    ax.set_ylabel('y')
    handles = [P.plt.matplotlib.patches.Patch(color=cmap(e / 7), label=nm) for e, nm in enumerate(G.ECONOMIES)]
    ax.legend(handles=handles, loc='upper right', fontsize=8, frameon=False, title='economy (dot size: tech level)',
              title_fontsize=8)
    ax.set_title('Trade round Lave at fluctuation 0: grey, the best legal buy from Lave on each jump (+Cr a unit); '
                 'green and yellow, the best round trip: %s %s +%.1f, back %s +%.1f a unit' % (
                     a['name'], t[0], t[1] / 10, back[0], back[1] / 10), fontsize=10, loc='left')
    fig.suptitle('Buy where the economy makes it cheap, sell where it is dear: %s and %s, %.1f ly apart, earn %.1f Cr '
                 'a tonne each way' % (a['name'], b['name'], distance(a, b) / 10, (t[1] + back[1]) / 20), fontsize=12)
    fig.tight_layout()
    P.place_labels(fig, ax, names, fontsize=9)
    P.save(fig, 'docs/img/galaxy/route.png')
    print('round trips (gain a unit there + back, tenths):')
    for r in loops[:8]:
        print('  %-10s %-10s %4d  %s %d / %s %d  %.1f ly' % (r[1]['name'], r[2]['name'], r[0], r[3][0], r[3][1],
                                                           r[4][0], r[4][1], distance(r[1], r[2]) / 10))


if __name__ == '__main__':
    for n in sys.argv[1:] or ['galaxies', 'route']:
        globals()[n]()
