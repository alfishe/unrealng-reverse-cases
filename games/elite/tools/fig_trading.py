#!/usr/bin/env python3
"""The trading guide's figures (docs/trading-guide.md), all from the game's market rules (tools/trade.py, which runs
galaxy.market(), MakeMarket `$E148` step for step):

    python3 tools/fig_trading.py [recipe fan heatmap map swing stonks hold risk pirates] [--runs 200]

-> docs/img/trading/*.png, *.gif. The league (stonks, hold) is 200 commanders a scheme, 120 jumps, the same
fluctuation bytes for every scheme (seeds 0-199).
"""
import argparse
import io
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import numpy as np  # noqa: E402
import rtplot as P  # noqa: E402
import trade as T  # noqa: E402
from PIL import Image  # noqa: E402

sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

OUT = 'docs/img/trading'
CYAN = P.rgb((110, 220, 255))
plt = P.plt
GROUP_COLOUR = {'agricultural': P.rgb((110, 210, 120)), 'minerals': P.rgb((210, 160, 110)),
                'high-tech': P.rgb((90, 160, 255)), 'illegal': P.rgb((240, 90, 90)), 'mix': P.rgb((255, 210, 70))}
GROUP_OF = {}
for g, items in T.GROUPS.items():
    if g != 'mix':
        for i in items:
            GROUP_OF[i] = g
GROUP_OF[16] = 'mix'
ECON_SHORT = ['rich ind.', 'avg ind.', 'poor ind.', 'mainly ind.', 'mainly agr.', 'rich agr.', 'avg agr.',
              'poor agr.']
GOV_SHORT = ['anarchy', 'feudal', 'multi-gov.', 'dictatorship', 'communist', 'confederacy', 'democracy',
             'corporate']


def colour(i):
    return GROUP_COLOUR[GROUP_OF[i]]


def by_name(n):
    return next(x for x in T.GAL if x['name'] == n)


def cr(tenths):
    return '%.1f' % (tenths / 10)


def to_image(fig):
    buf = io.BytesIO()
    fig.savefig(buf, format='png', dpi=100)
    plt.close(fig)
    buf.seek(0)
    return Image.open(buf).convert('RGB')


# ---------------------------------------------------------------------------------------------------------------

def recipe():
    """three prices of Diso at f1's arrival (fluctuation $A6), made as MakeMarket makes them"""
    fl = 0xA6
    diso = by_name('Diso')
    e = diso['economy']
    rows = [6, 11, 0]
    fig, axes = P.figure(9.6, 6.0, nrows=len(rows), ncols=2, gridspec_kw={'width_ratios': [1.0, 1.6]})
    for r, i in enumerate(rows):
        base, factor, _, mask = T.TABLE[i]
        f = fl & mask
        product = e * (factor & 0x1F)
        sign = -1 if factor & 0x80 else 1
        price = (base + f + sign * product) * 4
        assert price == T.market(e, fl)[i][0]
        ax = axes[r][0]
        ax.set_xlim(0, 8.6)
        ax.set_ylim(-0.4, 3.3)
        ax.axis('off')
        for k, (label, value, col) in enumerate((('byte', fl, P.WRITE), ('mask', mask, P.DIM),
                                                 ('AND', f, CYAN))):
            y = 2.6 - k * 1.05
            ax.text(-0.1, y, label, ha='right', va='center', fontsize=10, color=col)
            for b in range(8):
                bit = (value >> (7 - b)) & 1
                ax.add_patch(plt.Rectangle((b + 0.05, y - 0.4), 0.9, 0.8, facecolor=col if bit else P.PANEL,
                                           edgecolor=P.DIM, lw=0.6))
                ax.text(b + 0.5, y, str(bit), ha='center', va='center', fontsize=10,
                        color=P.BACKGROUND if bit else P.DIM)
            ax.text(8.2, y, '%d' % value if k else '$%02X' % value, ha='left', va='center', fontsize=10, color=col)
        ax.set_title('%s: factor %+d, mask $%02X' % (T.GOODS[i], T.FACTOR[i], mask), fontsize=11, loc='left',
                     color=colour(i))
        ax = axes[r][1]
        top = base + f + max(0, sign) * product
        ax.barh(0.25, base, color=P.DIM, height=0.4)
        ax.text(base / 2, 0.25, 'base %d' % base, ha='center', va='center', fontsize=9.5, color=P.BACKGROUND)
        left = base
        if sign > 0:
            ax.barh(0.25, product, left=left, color=colour(i), height=0.4)
            ax.text(left + product / 2, 0.25, '+ %d x %d = %d' % (e, factor & 0x1F, product), ha='center',
                    va='center', fontsize=9.5, color=P.BACKGROUND)
            left += product
        ax.barh(0.25, f, left=left, color=CYAN, height=0.4)
        ax.text(left + f + top * 0.01, 0.62, '+ f %d' % f, ha='left' if sign > 0 else 'center', va='center',
                fontsize=9.5, color=CYAN)
        end = base + f + sign * product
        if sign < 0:
            ax.barh(-0.3, product, left=end, color='none', edgecolor=colour(i), hatch='///', height=0.4, lw=1.2)
            ax.text(end - top * 0.02, -0.3, '- economy %d x %d = %d' % (e, factor & 0x1F, product), ha='right',
                    va='center', fontsize=9.5, color=colour(i))
        ax.axvline(end, color=P.WRITE, lw=1.4)
        ax.text(end - top * 0.02 if sign > 0 else top * 1.02, -0.3 if sign > 0 else -0.75,
                '(%d) x 4 = %d tenths = %s Cr' % (end, price, cr(price)), color=P.WRITE, fontsize=10.5,
                va='center', ha='right' if sign > 0 else 'right')
        ax.set_xlim(0, top * 1.08)
        ax.set_ylim(-1.0, 0.85)
        ax.set_yticks([])
        ax.tick_params(labelsize=8.5)
        if r == len(rows) - 1:
            ax.set_xlabel('the sum before x 4 (each row its own scale)')
    fig.suptitle("Three prices of Diso as f1 found them (economy 6, fluctuation $A6): base, the economy's push and "
                 "the byte through the mask", fontsize=12)
    P.save(fig, os.path.join(OUT, 'recipe.png'))


def fan():
    fig, axes = P.figure(9.6, 9.0, nrows=4, ncols=4, sharex=True)
    xs = np.arange(8)
    for i in range(16):
        ax = axes[i // 4][i % 4]
        lo = np.array([T.LOW[e][i] for e in range(8)]) / 10
        hi = np.array([T.HIGH[e][i] for e in range(8)]) / 10
        mean = np.array([T.MEAN[e][i] for e in range(8)]) / 10
        c = colour(i)
        ax.fill_between(xs, lo, hi, color=c, alpha=0.35, lw=0)
        ax.plot(xs, mean, color=c, lw=1.8)
        ax.set_title('%s (%s)' % (T.GOODS[i], T.UNIT[i]), fontsize=11, color=c, loc='left')
        ax.text(0.97, 0.05 if T.FACTOR[i] > 0 else 0.95, '%+.1f Cr a step\nband %.1f Cr' % (
            T.FACTOR[i] * 0.4, T.MASK[i] * 0.4), transform=ax.transAxes, ha='right',
            va='bottom' if T.FACTOR[i] > 0 else 'top', fontsize=10, color=P.TEXT)
        ax.grid(True, lw=0.4)
        ax.tick_params(labelsize=9.5)
        ax.set_xticks([0, 7])
        ax.set_xticklabels(['rich\nind.', 'poor\nagr.'])
    for ax in axes[:, 0]:
        ax.set_ylabel('Cr', fontsize=10)
    fig.suptitle('Each price is a straight line across the eight economies: the factor sets the slope, the mask the '
                 'height of the band (line: the mean over the 255 bytes; each panel its own scale)', fontsize=12)
    P.save(fig, os.path.join(OUT, 'fan.png'))


def heatmap():
    lave = T.LAVE
    cols = []
    for t in T.NEIGHBOURS[7]:
        b = T.GAL[t]
        cols.append((lave, b))
        cols.append((b, lave))
    cols.sort(key=lambda ab: ab[1]['economy'] - ab[0]['economy'])
    cols += [(by_name('Isinor'), by_name('Qutiri')), (by_name('Qutiri'), by_name('Isinor'))]
    data = np.array([[(T.MEAN[b['economy']][i] - T.MEAN[a['economy']][i]) / 10 for a, b in cols] for i in range(16)])
    fig, ax = P.figure(9.6, 7.6)
    lim = 60
    cmap = plt.matplotlib.colors.LinearSegmentedColormap.from_list(
        'loss-gain', [P.rgb((215, 60, 60)), P.rgb((34, 34, 44)), P.rgb((50, 200, 90))])
    ax.imshow(data, cmap=cmap, vmin=-lim, vmax=lim, aspect='auto')
    for r in range(16):
        for c in range(len(cols)):
            v = data[r][c]
            ax.text(c, r, '%.1f' % v if abs(v) < 10 else '%.0f' % v, ha='center', va='center', fontsize=8.5,
                    color='white' if abs(v) > 10 else P.TEXT)
    ax.set_yticks(range(16))
    ax.set_yticklabels(['%s %+d' % (T.GOODS[i], T.FACTOR[i]) for i in range(16)], fontsize=9)
    for k, lab in enumerate(ax.get_yticklabels()):
        lab.set_color(colour(k))
    ax.set_xticks(range(len(cols)))
    ax.set_xticklabels(['%s\n\u2192%s\ngap %+d' % (a['name'][:6], b['name'][:6], b['economy'] - a['economy'])
                        for a, b in cols], fontsize=8.5, rotation=0)
    ax.tick_params(axis='x', top=True, labeltop=True, bottom=False, labelbottom=False)
    ax.axvline(len(cols) - 2.5, color=P.TEXT, lw=1.5)
    ax.set_title('Lave and its six neighbours, both ways, then the best pair near Lave (right of the line)',
                 fontsize=10, loc='left', y=-0.06)
    fig.suptitle('The mean profit a unit (Cr) is the factor x the economy gap x 0.4: columns with the same gap '
                 'are identical, whatever the planets are called', fontsize=12)
    P.save(fig, os.path.join(OUT, 'heatmap.png'))


def map_():
    g = T.GAL
    cmap = plt.get_cmap('coolwarm')
    pairs = [(a, T.GAL[t]) for a in g for t in T.NEIGHBOURS[a['index']]
             if a['economy'] == 0 and T.GAL[t]['economy'] == 7]
    fig, (ax, bx) = P.figure(9.6, 11.0, nrows=2, gridspec_kw={'height_ratios': [1.0, 1.15]})
    ax.scatter([x['x'] for x in g], [x['y'] for x in g], s=10, c=[cmap(x['economy'] / 7) for x in g], lw=0)
    for a, b in pairs:
        ax.plot([a['x'], b['x']], [a['y'], b['y']], color=P.WRITE, lw=3, solid_capstyle='round')
    lave = T.LAVE
    ax.plot(lave['x'], lave['y'], marker='*', ms=14, color='white')
    ax.text(lave['x'] + 3, lave['y'], 'Lave', fontsize=10, va='center')
    xe, la = by_name('Xexedi'), by_name('Laenin')
    ax.annotate('Xexedi - Laenin, 0.8 ly:\nthe shortest gap-7 pair', (xe['x'], xe['y']), xytext=(xe['x'] + 25,
                xe['y'] - 30), fontsize=9.5, color=P.WRITE, arrowprops={'arrowstyle': '->', 'color': P.WRITE})
    ax.add_patch(plt.Rectangle((0, 140), 75, 115, fill=False, ec=P.TEXT, ls='--', lw=0.8))
    ax.set_xlim(-2, 258)
    ax.set_ylim(258, -2)
    ax.set_aspect(0.5)
    ax.set_title('Galaxy 1: the %d pairs of a rich industrial and a poor agricultural world within one jump (yellow)'
                 % len(pairs), fontsize=10.5, loc='left')
    ax.set_xticks([])
    ax.set_yticks([])
    handles = [plt.matplotlib.patches.Patch(color=cmap(e / 7), label=n) for e, n in enumerate(T.G.ECONOMIES)]
    ax.legend(handles=handles, fontsize=8, ncol=4, loc='lower center', bbox_to_anchor=(0.5, -0.2), frameon=False)
    # Lave's area: every scheme's first jumps (seed 0)
    area = [x for x in g if 0 <= x['x'] <= 75 and 140 <= x['y'] <= 255]
    bx.scatter([x['x'] for x in area], [x['y'] for x in area], s=[30 + 10 * x['tech'] for x in area],
               c=[cmap(x['economy'] / 7) for x in area], lw=0, zorder=3)
    for a, b in pairs:
        if a in area and b in area:
            bx.plot([a['x'], b['x']], [a['y'], b['y']], color=P.WRITE, lw=4, alpha=0.5, solid_capstyle='round')
    courses = {sch: [T.GAL[h[2]]['name'] for h in T.run(sch, 0, 12).history] for sch in T.SCHEMES}
    common = courses['mix'][:4]
    assert all(c[:4] == common for c in courses.values()), courses

    def arrow(a, b, col, lw=2.2, rad=0.0, ls='-'):
        p, q = by_name(a), by_name(b)
        bx.annotate('', xy=(q['x'], q['y']), xytext=(p['x'], p['y']),
                    arrowprops={'arrowstyle': '-|>', 'color': col, 'lw': lw, 'shrinkA': 7, 'shrinkB': 7,
                                'connectionstyle': 'arc3,rad=%s' % rad, 'linestyle': ls}, zorder=4)
    arrow('Lave', 'Zaonce', P.TEXT)
    arrow('Zaonce', 'Isinor', P.TEXT)
    arrow('Isinor', 'Qutiri', P.TEXT, rad=0.3)
    arrow('Qutiri', 'Isinor', P.TEXT, rad=0.3)
    agr = courses['agricultural']
    k = next(n for n in range(4, len(agr)) if agr[n] not in common)
    for n in range(k - 1, k + 1):
        arrow(agr[n], agr[n + 1], GROUP_COLOUR['agricultural'], lw=1.8, ls='--')
    arrow(agr[k + 1], agr[k], GROUP_COLOUR['agricultural'], lw=1.8, rad=0.4)
    bx.set_xlabel('every scheme (white): %s, then %s and %s for good (jumps 3 on);\nagricultural (green) moves '
                  'from jump %d to %s and %s, %.1f ly apart:\nthe fuel 0.4 Cr cheaper a jump, but %s is an anarchy' % (
                ' > '.join(common[:3]), common[2], common[3], k, agr[k], agr[k + 1],
                T.distance(by_name(agr[k]), by_name(agr[k + 1])) / 10, agr[k + 1]), fontsize=10)
    names = [(x['x'], x['y'], '%s\n%s, %s' % (x['name'], ECON_SHORT[x['economy']], GOV_SHORT[x['government']]),
              'left' if x['name'] == 'Zaonce' else 'right') for x in area if x['name'] in ('Lave', 'Zaonce', 'Isinor', 'Qutiri', 'Ensoreus', 'Ararus',
                                                       'Diso', 'Leesti', 'Reorte', 'Riedquat', 'Orerve')]
    bx.set_xlim(-2, 90)
    bx.set_ylim(250, 140)
    bx.set_aspect(0.5)
    bx.set_xticks([])
    bx.set_yticks([])
    bx.set_title("Lave's corner (the dashed box): where each scheme's commander flies (the league's first run)",
                 fontsize=10.5, loc='left')
    fig.suptitle('Every scheme ends on the same kind of loop: one jump between economy 0 and economy 7', fontsize=12)
    fig.tight_layout()
    P.place_labels(fig, bx, names, fontsize=8.5)
    P.save(fig, os.path.join(OUT, 'map.png'))


def swing():
    """each commodity's profit a unit at the full gap over every pair of bytes (buy, sell)"""
    fig, ax = P.figure(9.6, 7.0)
    order = sorted(range(16), key=lambda i: abs(T.FACTOR[i]) * 7 * 4)
    for r, i in enumerate(order):
        ea, eb = (0, 7) if T.FACTOR[i] > 0 else (7, 0)
        buy = np.array([T.market(ea, f)[i][0] for f in T.FLS])
        sell = np.array([T.market(eb, f)[i][0] for f in T.FLS])
        prof = (sell[None, :] - buy[:, None]).ravel() / 10
        vals, counts = np.unique(prof, return_counts=True)
        w = counts / counts.max() * 0.42
        c = colour(i)
        step = min(np.diff(vals)) if len(vals) > 1 else 0.4
        for v, h in zip(vals, w):
            ax.add_patch(plt.Rectangle((v - step / 2, r - h), step, 2 * h, color=c, lw=0))
        m = prof.mean()
        ax.plot([m, m], [r - 0.45, r + 0.45], color='white', lw=1.4)
        ax.text(prof.max() + 4, r, '%s to %s, mean %.1f' % (cr(prof.min() * 10), cr(prof.max() * 10), m),
                va='center', fontsize=8.5, color=P.TEXT)
    ax.axvline(0, color=P.HOT, lw=1)
    ax.set_yticks(range(16))
    ax.set_yticklabels(['%s (%s)' % (T.GOODS[i], 'agr. > ind.' if T.FACTOR[i] < 0 else 'ind. > agr.')
                        for i in order], fontsize=9)
    for k, lab in enumerate(ax.get_yticklabels()):
        lab.set_color(colour(order[k]))
    ax.set_xlim(-15, 185)
    ax.set_xlabel('profit a unit (Cr), economy 0 to 7 or back; the height: how many byte pairs (buy, sell) give it')
    ax.grid(True, axis='x', lw=0.4)
    fig.suptitle('At the full gap the economy fixes the sign: only alloys, platinum and gem-stones can lose; '
                 'narcotics swing 33 to 129 Cr a tonne, computers 38 to 40', fontsize=12)
    P.save(fig, os.path.join(OUT, 'swing.png'))


def league_runs(runs):
    lg = T.league(runs, 120)
    dia = [T.run('mix', seed, 120, diamond=True) for seed in range(runs)]
    return lg, dia


def stonks(runs):
    lg, dia = league_runs(runs)
    jumps = np.arange(121)
    curves = {}
    for s, trs in lg.items():
        w = np.array([[h[1] / 10 for h in t.history] for t in trs])
        curves[s] = (np.median(w, axis=0), np.percentile(w, 10, axis=0), np.percentile(w, 90, axis=0))
    wd = np.array([[h[1] / 10 for h in t.history] for t in dia])
    dmed = np.median(wd, axis=0)
    marks = [(400, 'large cargo bay 400'), (1500, 'docking computers 1500'), (5000, 'galactic hyperdrive 5000'),
             (17055, 'the full shop 17 055')]

    def frame(n, meme):
        fig, ax = P.figure(9.6, 6.4)
        ax.set_yscale('log')
        ax.set_xlim(0, 120)
        ax.set_ylim(50, 4e5)
        for y, lab in marks:
            ax.axhline(y, color=P.DIM, lw=0.7, ls=':')
        rx = ax.twinx()
        rx.set_yscale('log')
        rx.set_ylim(50, 4e5)
        rx.set_yticks([y for y, _ in marks])
        rx.set_yticklabels([lab.replace(' 17', '\n17').replace(' 1500', '\n1500').replace(' 5000', '\n5000')
                            .replace(' 400', '\n400') for _, lab in marks], fontsize=9, color=P.DIM)
        rx.minorticks_off()
        for s in T.SCHEMES:
            med, lo, hi = curves[s]
            c = GROUP_COLOUR[s]
            ax.fill_between(jumps[:n + 1], lo[:n + 1], hi[:n + 1], color=c, alpha=0.18, lw=0)
            ax.plot(jumps[:n + 1], med[:n + 1], color=c, lw=2.2, label='%s: %s Cr' % (s, format(int(med[n]), ',')
                                                                                     .replace(',', ' ')))
        ax.plot(jumps[:n + 1], dmed[:n + 1], color=GROUP_COLOUR['mix'], lw=1.2, ls='--',
                label='mix, never selling below cost: %s Cr' % format(int(dmed[n]), ',').replace(',', ' '))
        ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.12), fontsize=9.5, frameon=False, ncol=2)
        ax.set_xlabel('jumps from Lave')
        ax.set_ylabel('worth: cash + cargo at the arrival prices (Cr, log scale)')
        ax.grid(True, which='major', lw=0.4)
        if meme:
            # the meme in the empty top-left corner, above every curve
            ax.text(3, 1.25e5, 'STONKS', fontsize=30, fontweight='bold', color=(1.0, 0.55, 0.15), alpha=0.95)
            ax.annotate('', xy=(52, 2.9e5), xytext=(36, 1.15e5),
                        arrowprops={'arrowstyle': 'simple,head_width=1.2,head_length=1.2,tail_width=0.45',
                                    'color': (1.0, 0.55, 0.15), 'alpha': 0.95})
        ax.set_title('jump %d' % n, loc='right', fontsize=10, color=P.WRITE)
        fig.suptitle('Credits over jumps from Lave (100 Cr, 20 t), 200 commanders a scheme:\nthe mix leads, '
                     'contraband second, minerals last (lines: the median; bands: 10-90 %)', fontsize=12)
        fig.tight_layout()
        return fig

    pics, durs = [], []
    for n in list(range(0, 121, 2)):
        pics.append(to_image(frame(n, False)))
        durs.append(90)
    for _ in range(1):
        pics.append(to_image(frame(120, True)))
        durs.append(4000)
    K.save_gif(os.path.join(P.CASE, OUT, 'stonks.gif'), pics, durs)
    print('wrote', os.path.join(OUT, 'stonks.gif'), len(pics), 'pictures')
    for s in T.SCHEMES:
        print('  %-13s median %8.0f at 120' % (s, curves[s][0][-1]))
    print('  diamond mix median %8.0f' % dmed[-1])


def hold():
    """the mix commander's hold dock by dock (seed 0): the 20 t, and the kilos and grams that take no space"""
    tr = T.run('mix', 0, 24)
    abbrev = {0: 'food', 1: 'text', 2: 'radio', 3: 'slav', 4: 'liq', 5: 'lux', 6: 'narc', 7: 'comp', 8: 'mach',
              9: 'alloy', 10: 'fire', 11: 'furs', 12: 'min'}
    pics, durs = [], []
    worth = [h[1] / 10 for h in tr.history]
    for n in range(1, len(tr.history)):
        j, w, at, cargo = tr.history[n]
        frm = T.GAL[tr.history[n - 1][2]]
        to = T.GAL[at]
        fig = plt.figure(figsize=(9.0, 5.2))
        ax = fig.add_axes([0.03, 0.08, 0.42, 0.7])
        ax.set_xlim(0, 5)
        ax.set_ylim(4, 0)
        ax.axis('off')
        cells = [i for i in range(17) if T.TONNES[i] for _ in range(cargo[i])]
        for k in range(20):
            x, y = k % 5, k // 5
            if k < len(cells):
                i = cells[k]
                ax.add_patch(plt.Rectangle((x + 0.04, y + 0.04), 0.92, 0.92, color=colour(i)))
                ax.text(x + 0.5, y + 0.5, abbrev[i], ha='center', va='center', fontsize=10, color=P.BACKGROUND)
            else:
                ax.add_patch(plt.Rectangle((x + 0.04, y + 0.04), 0.92, 0.92, fill=False, ec=P.DIM, ls=':'))
        ax.text(0, -0.15, 'the hold: 20 t (one cell a tonne)', fontsize=10, color=P.TEXT)
        bx = fig.add_axes([0.52, 0.08, 0.17, 0.7])
        kg = [(13, 'gold kg'), (14, 'platinum kg'), (15, 'gems g')]
        for k, (i, lab) in enumerate(kg):
            bx.bar(k, cargo[i], color=colour(i), width=0.7)
            bx.text(k, cargo[i] + 4, str(cargo[i]), ha='center', fontsize=9.5)
        bx.set_ylim(0, 255)
        bx.set_xticks(range(3))
        bx.set_xticklabels([lab for _, lab in kg], fontsize=8.5, rotation=20)
        bx.set_title('outside the 20 t:\nup to 255 each', fontsize=9.5)
        bx.tick_params(labelsize=8.5)
        cx = fig.add_axes([0.77, 0.12, 0.21, 0.6])
        cx.plot(range(n + 1), worth[:n + 1], color=GROUP_COLOUR['mix'], lw=2)
        cx.set_xlim(0, len(worth) - 1)
        cx.set_ylim(0, max(worth) * 1.05)
        cx.set_title('worth (Cr)', fontsize=9.5)
        cx.tick_params(labelsize=8.5)
        cx.set_xlabel('jump', fontsize=9)
        danger = 2 * (cargo[3] + cargo[6]) + cargo[10]
        fig.text(0.03, 0.93, 'Jump %d: %s (%s) > %s (%s), %.1f ly' % (j, frm['name'], ECON_SHORT[frm['economy']],
                 to['name'], ECON_SHORT[to['economy']], T.distance(frm, to) / 10), fontsize=12, color=P.WRITE)
        fig.text(0.03, 0.87, 'cargo bought for %s Cr at %s; worth on arrival %s Cr; contraband danger %d' % (
            cr(tr.spent[n - 1]), frm['name'], format(int(w / 10), ',').replace(',', ' '), danger), fontsize=10.5,
            color=P.TEXT)
        pics.append(to_image(fig))
        durs.append(1100)
    durs[-1] = 3000
    K.save_gif(os.path.join(P.CASE, OUT, 'hold.gif'), pics, durs)
    print('wrote', os.path.join(OUT, 'hold.gif'), len(pics), 'pictures')


def risk():
    fig, (ax, bx) = P.figure(9.6, 5.2, ncols=2, gridspec_kw={'width_ratios': [1.3, 1]})
    ds = np.arange(0, 141, 2)
    gcol = [P.PALETTE[k] for k in (3, 1, 5, 7, 4, 6, 2, 0)]
    for gv in range(8):
        y = [T.hostile(d, gv) * 100 for d in ds]
        ax.plot(ds, y, color=gcol[gv], lw=1.6)
        ax.text(141, y[-1], ' %s' % GOV_SHORT[gv], color=gcol[gv], fontsize=9, va='center')
    isinor, qutiri = by_name('Isinor'), by_name('Qutiri')
    notes = []
    for k, (d, sysm, lab) in enumerate(((40, isinor, '20 t of narcotics into Isinor (confederacy)'),
                                        (40, qutiri, '20 t of slaves into Qutiri (multi-government)'),
                                        (70, isinor, '35 t of narcotics into Isinor'))):
        y0, y1 = T.hostile(0, sysm['government']) * 100, T.hostile(d, sysm['government']) * 100
        ax.plot([d], [y1], 'o', color='white', ms=6, zorder=5)
        ax.text(d + 1.5, y1 - 1.5, str(k + 1), fontsize=10, color='white', va='top', fontweight='bold')
        notes.append('%d  %s: %.1f%% (clean %.1f%%)' % (k + 1, lab, y1, y0))
    fig.text(0.07, 0.0, '\n'.join(notes), fontsize=9.5, color=P.TEXT, va='top')
    ax.set_xlim(0, 168)
    ax.set_ylim(0, 70)
    ax.set_xlabel('danger = 2 x (slaves + narcotics) + firearms (tonnes)')
    ax.set_ylabel('a pirate or a pack, % of spawn checks')
    ax.grid(True, lw=0.4)
    ax.set_title('SpawnShip: each unit of danger, one more byte of 256', fontsize=10, loc='left')
    for s in T.SCHEMES:
        per = T.best_loops(s, 20, T.LAVE)[0][0] / 10
        trs = [T.run(s, seed, 60) for seed in range(20)]
        dang = np.mean([np.mean([d for d, _ in t.dangers[20:]]) for t in trs])
        bx.plot(dang, per, 'o', color=GROUP_COLOUR[s], ms=11)
        bx.text(dang + 2.5, per + {'agricultural': 25, 'minerals': -25}.get(s, 0),
                '%s: %.0f Cr, danger %.0f' % (s, per, dang), fontsize=9, color=GROUP_COLOUR[s], va='center')
    bx.set_xlim(-3, 72)
    bx.set_ylim(0, 1200)
    bx.set_xlabel('mean danger on arrival (jumps 20-60)')
    bx.set_ylabel('Cr a jump, the Isinor - Qutiri loop')
    bx.grid(True, lw=0.4)
    bx.set_title('what the danger buys', fontsize=10, loc='left')
    fig.suptitle('Contraband does not call the police (nothing reads the legal status):\n'
                 'it calls pirates, about half as many again', fontsize=12)
    P.save(fig, os.path.join(OUT, 'risk.png'))


def pirates():
    fig, ax = P.figure(9.6, 4.6)
    basket = np.array([sum(T.market(2, f)[i][0] for i in range(16)) / 10 for f in range(256)])
    cols = []
    for f in range(256):
        if f == 0xF9:
            cols.append(P.OTHER)
        elif f <= 3:
            cols.append(P.HOT)
        else:
            cols.append(P.READ)
    ax.bar(range(256), basket, color=cols, width=1.0)
    ax.set_ylim(680, 920)
    ax.set_xlim(-1, 256)
    ax.set_xticks([0, 0x20, 0x40, 0x60, 0x80, 0xA0, 0xC0, 0xE0, 0xF9])
    ax.set_xticklabels(['$00', '$20', '$40', '$60', '$80', '$A0', '$C0', '$E0', '$F9'])
    ax.annotate('$00-$03: in galaxies 2-8 an anarchy or a feudal\nworld is pirate-held (the game ends at the dock);'
                '\n$00-$02, $00-$01 or $00 by the other governments', (2, basket[0] + 3), xytext=(6, 880),
                fontsize=9.5, color=P.HOT, va='center', arrowprops={'arrowstyle': '->', 'color': P.HOT})
    ax.annotate('$80: the same cheapest market, and safe\n(no mask reads bit 7)', (0x80, basket[0x80] + 3),
                xytext=(0x84, 898), fontsize=9.5, color=P.READ, va='center',
                arrowprops={'arrowstyle': '->', 'color': P.READ})
    ax.annotate('$F9: never a market\n(witch space instead)', (0xF9, basket[0xF9] + 3), xytext=(0xC4, 866),
                fontsize=9.5, color=P.TEXT, va='center', arrowprops={'arrowstyle': '->', 'color': P.DIM})
    ax.set_xlabel('the fluctuation byte (StarSeed at the arrival)')
    ax.set_ylabel('one unit of each of 16 goods (Cr)')
    fig.suptitle('The bargain bytes are the pirates\': a shopping basket at a poor industrial world over the 256 '
                 'bytes', fontsize=12)
    P.save(fig, os.path.join(OUT, 'pirates.png'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', nargs='*')
    ap.add_argument('--runs', type=int, default=200)
    a = ap.parse_args()
    os.makedirs(os.path.join(P.CASE, OUT), exist_ok=True)
    jobs = {'recipe': recipe, 'fan': fan, 'heatmap': heatmap, 'map': map_, 'swing': swing,
            'stonks': lambda: stonks(a.runs), 'hold': hold, 'risk': risk, 'pirates': pirates}
    for w in a.what or list(jobs):
        jobs[w]()


if __name__ == '__main__':
    main()
