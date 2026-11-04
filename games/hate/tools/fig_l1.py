#!/usr/bin/env python3
"""The H.A.T.E. figures drawn from L1 builds (l1.json with byte_counts), each with its point in the title and every
mark named on it (matplotlib, dark theme, the style of nether-earth's fig_beam_turn.py):

    memory    docs/img/heat-memory.png    (doc 2.2) the 48 K as 192 rows of 256 bytes: how each byte was used, and
              when it was last touched, with the regions named
    modules   docs/img/heat-modules.png   (doc 2.6) which module's code reads and writes which part of memory
    records   docs/img/heat-records.png   (doc 7.2) the object list $C000-$C26F as a table: reads and writes per field
    screen    docs/img/heat-screen.png    (doc 6.7) the screen writes in the screen's geometry, by kind of byte
    coverage  docs/img/heat-coverage.png  (doc 10.1) the code run in the bot's game against the first recording
    routines  docs/img/routines-time.png  (doc 4.5) the own t-states of the top routines, coloured by job

    python3 tools/fig_l1.py memory   work/game2/l1.json docs/img/heat-memory.png
    python3 tools/fig_l1.py modules  work/p2/l1.json    docs/img/heat-modules.png
    python3 tools/fig_l1.py records  work/p2/l1.json    docs/img/heat-records.png
    python3 tools/fig_l1.py screen   work/p2/l1.json    docs/img/heat-screen.png
    python3 tools/fig_l1.py coverage work/p2/l1.json    docs/img/heat-coverage.png --other work/m1/l1.json
    python3 tools/fig_l1.py routines work/p2/l1.json    docs/img/routines-time.png
"""
import argparse
import bisect
import json
import math
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False  # '$8000-$BFFF' is an address range, not math
import numpy as np  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import heatmap  # noqa: E402
import heatviews  # noqa: E402

BG, AX, FG, DIM, GRID = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8', '#444'
PLAY_SCREEN = os.path.join(HERE, '..', 'docs', 'img', 'game-3-play.png')


def style(fig, axes):
    fig.patch.set_facecolor(BG)
    for a in axes:
        a.set_facecolor(AX)
        a.tick_params(colors=DIM, labelsize=8.5)
        for s in a.spines.values():
            s.set_color(GRID)


def save(fig, out):
    fig.savefig(out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(out)


def screen_xy(a):
    """(x, line) of bitmap byte a"""
    return (a & 31) * 8, ((a >> 8) & 7) | ((a >> 2) & 0x38) | ((a >> 5) & 0xC0)


def logn(values, lo, hi):
    v = np.array(values[lo:hi + 1], dtype=float)
    top = v.max() or 1
    return np.log2(v + 1) / math.log2(top + 1)


# ---------------------------------------------------------------- memory

REGIONS = [  # start, end, name: the doc 2.2 list, in its words
    (0x4000, 0x57FF, 'screen bitmap'),
    (0x5800, 0x5AFF, 'attributes'),
    (0x5B00, 0x5FFF, 'shadow shapes'),
    (0x6000, 0x62FF, 'ground profile'),
    (0x6300, 0x64FF, 'font'),
    (0x6500, 0x7FFF, 'sprite graphics\n(read only)'),
    (0x8000, 0x85FF, 'title music player\n(run once, then buffer)'),
    (0x8600, 0xBFFF, 'playfield buffer\n$8000-$BFFF:\nread and written'),
    (0xC000, 0xC3FF, 'object records,\nvariables'),
    (0xC400, 0xF2FF, 'game code:\nexecuted'),
    (0xF300, 0xF7FF, 'course blocks (read)'),
    (0xFD00, 0xFFFF, 'IM 2 table, stack'),
]


def regions_axis(ax, lo, x):
    for a, b, name in REGIONS:
        y0, y1 = (a - lo) / 256 - 0.5, (b - lo) / 256 + 0.5
        ax.plot([x, x + 6, x + 6, x], [y0 + 0.3, y0 + 0.3, y1 - 0.3, y1 - 0.3], color='#d8d088', lw=0.9,
                clip_on=False)
        ax.text(x + 10, (y0 + y1) / 2, name, color='#e8e0a0', fontsize=8, va='center', ha='left', clip_on=False,
                linespacing=1.0)


def memory(l1, out):
    ex, rd, wr, last, replay = heatmap.load(l1, heatmap.BASES_48K)
    lo, hi = 0x4000, 0xFFFF
    rows = (hi + 1 - lo) // 256
    r, g, b = (logn(v, lo, hi).reshape(rows, 256) for v in (wr, rd, ex))
    rgb = np.clip(np.stack([r, g, b], axis=2) * 1.15, 0, 1)
    first, frames = replay['first_frame'], replay['last_frame']
    touched = np.array([(rd[a] or wr[a] or ex[a]) for a in range(lo, hi + 1)]).reshape(rows, 256)
    when = np.array(last[lo:hi + 1], dtype=float).reshape(rows, 256)
    when = np.ma.masked_where(~touched.astype(bool), when)

    fig, (ax, bx) = plt.subplots(1, 2, figsize=(13, 8.4), dpi=100, gridspec_kw={'wspace': 0.08})
    style(fig, (ax, bx))
    ax.imshow(rgb, aspect='auto', interpolation='nearest', extent=(-0.5, 255.5, rows - 0.5, -0.5))
    cmap = plt.get_cmap('cividis').copy()
    cmap.set_bad('#0c0c10')
    im = bx.imshow(when, aspect='auto', interpolation='nearest', cmap=cmap, vmin=first, vmax=frames,
                   extent=(-0.5, 255.5, rows - 0.5, -0.5))
    ticks = list(range(0, rows, 16))
    for a in (ax, bx):
        a.set_yticks(ticks)
        a.set_yticklabels([f'${lo + 256 * t:04X}' for t in ticks])
        a.set_xticks([0, 64, 128, 192, 255])
        a.set_xticklabels(['+$00', '+$40', '+$80', '+$C0', '+$FF'])
        a.set_xlabel('byte within the row (one row = 256 bytes)', color=DIM, fontsize=9)
    bx.set_yticklabels([])
    regions_axis(bx, lo, 262)
    for a in (ax, bx):
        a.set_xlim(-0.5, 255.5)
        a.set_ylim(rows - 0.5, -0.5)
    ax.set_title('How often: red = written, green = read, blue = executed\n'
                 '(mixes: yellow = read and written; brighter = more often, log scale)',
                 color=FG, fontsize=10, loc='left')
    bx.set_title('When: the frame each byte was last read or written\n(dark: early, bright: late; '
                 'black: never; running code does not count)', color=FG, fontsize=10, loc='left')
    cax = bx.inset_axes([0, -0.15, 1, 0.03])
    cb = fig.colorbar(im, cax=cax, orientation='horizontal')
    cb.set_label(f'frame last read or written (window {first}-{frames}: title, two games, demo)', color=DIM, fontsize=8.5)
    cb.ax.tick_params(colors=DIM, labelsize=8)
    # the marks the doc 2.2 list points at
    ax.annotate('the stack under $FFFF', xy=(250, rows - 1), xytext=(150, rows - 8), color=FG, fontsize=8.5,
                arrowprops=dict(arrowstyle='->', color=FG, lw=0.8))
    ax.annotate('the title music player (blue: it ran),\nthen overwritten by the buffer', xy=(40, (0x8000 - lo) / 256),
                xytext=(60, (0x7000 - lo) / 256), color='#8fb8ff', fontsize=8.5,
                arrowprops=dict(arrowstyle='->', color='#8fb8ff', lw=0.8))
    fig.suptitle(f'The game\'s memory over frames {first}-{frames}: the screen, the playfield buffer '
                 '$8000-$BFFF, the objects at $C000, code above', color=FG, fontsize=12, x=0.08, ha='left', y=0.99)
    save(fig, out)


# ---------------------------------------------------------------- modules

SPANS = [(0x4000, 0x5AFF, 'screen'), (0x6000, 0x64FF, 'profile,\nfont'), (0x8000, 0xBFFF, 'playfield buffer'),
         (0xC000, 0xC3FF, 'objects'), (0xC400, 0xF2FF, 'game code'), (0xF300, 0xF7FF, 'courses'),
         (0xFD00, 0xFFFF, 'stack')]
def module_touches(doc):
    mods = heatviews.module_ranges()
    starts = [m[0] for m in mods]
    touched = {}
    for r in doc['routines']:
        if r['page'] not in (0, 2, 5):
            continue
        i = bisect.bisect_right(starts, int(r['entry'][1:], 16)) - 1
        if i < 0:
            continue
        t = touched.setdefault(mods[i][1], {'reads': set(), 'writes': set()})
        for kind in ('reads', 'writes'):
            for x in r['profile'][kind]:
                if x['page'] in (0, 2, 5):
                    t[kind].update(range(int(x['from'][1:], 16), int(x['to'][1:], 16) + 1))
    return [m for _, m in mods if m in touched], touched


def modules(l1, out):
    doc = json.load(open(l1))
    rows, touched = module_touches(doc)
    rows = [m for m in rows if m not in ('gamedata', 'coursedata')] + [m for m in rows if m in ('coursedata',)]
    pages = np.arange(0x40, 0x100)
    fig, axes = plt.subplots(2, 1, figsize=(13, 9.2), dpi=100, gridspec_kw={'hspace': 0.38})
    style(fig, axes)
    for ax, kind in zip(axes, ('reads', 'writes')):
        grid = np.zeros((len(rows), len(pages)))
        for i, m in enumerate(rows):
            for a in touched[m][kind]:
                if a >= 0x4000:
                    grid[i, (a >> 8) - 0x40] += 1
        shown = np.ma.masked_where(grid == 0, np.log1p(grid) / math.log1p(256))
        cmap = plt.get_cmap('inferno').copy()
        cmap.set_bad(AX)
        ax.imshow(shown, aspect='auto', interpolation='nearest', cmap=cmap, vmin=0, vmax=1,
                  extent=(0x40 - 0.5, 0xFF + 0.5, len(rows) - 0.5, -0.5))
        ax.set_yticks(range(len(rows)))
        ax.set_yticklabels(rows, fontsize=8.5)
        for a, b, name in SPANS:
            x0, x1 = (a >> 8) - 0.5, (b >> 8) + 0.5
            ax.axvline(x0, color='#666', lw=0.6)
            ax.axvline(x1, color='#666', lw=0.6)
            ax.text((x0 + x1) / 2, -0.7, name.replace('\n', ' '), color='#e8e0a0', fontsize=8, ha='center',
                    va='bottom')
        ax.set_xticks([0x40, 0x60, 0x80, 0xA0, 0xC0, 0xE0, 0xFF])
        ax.set_xticklabels(['$4000', '$6000', '$8000', '$A000', '$C000', '$E000', '$FFFF'])
        ax.set_xlim(0x40 - 0.5, 0xFF + 0.5)
        ax.set_title(('READS: ' if kind == 'reads' else 'WRITES: ') + 'one row a module of the source, one cell a '
                     '256-byte page; brighter = more of its bytes (black: none)', color=FG, fontsize=10.5,
                     loc='left', pad=18)
    ax = axes[1]
    box = dict(boxstyle='round,pad=0.2', fc=AX, ec='none')
    ax.annotate('sprites, shadows, statics: into the buffer, not the screen', xy=(0xA0, rows.index('shadows')),
                xytext=(0x84, rows.index('hits') + 0.2), color=FG, fontsize=8.5, ha='left', bbox=box,
                arrowprops=dict(arrowstyle='->', color=FG, lw=0.8))
    ax.annotate('scroller (the blit): the screen\'s play area', xy=(0x4A, rows.index('scroller')),
                xytext=(0x5C, rows.index('mover') + 0.2), color=FG, fontsize=8.5, bbox=box,
                arrowprops=dict(arrowstyle='->', color=FG, lw=0.8))
    ax.annotate('hud: panel, status window,\nmenu text, GAME OVER', xy=(0x4C, rows.index('hud')),
                xytext=(0x5C, rows.index('menu') + 0.3), color=FG, fontsize=8.5, bbox=box,
                arrowprops=dict(arrowstyle='->', color=FG, lw=0.8))
    ax.annotate('mover, player, hits: only the\nobject records and variables', xy=(0xC1, rows.index('hits')),
                xytext=(0xC8, rows.index('menu') + 0.3), color=FG, fontsize=8.5, bbox=box,
                arrowprops=dict(arrowstyle='->', color=FG, lw=0.8))
    ax.annotate('startup: the screen\ncopied once', xy=(0x50, rows.index('startup')),
                xytext=(0x66, rows.index('startup') - 0.1), color=FG, fontsize=8.5, bbox=box, va='center',
                arrowprops=dict(arrowstyle='->', color=FG, lw=0.8))
    fig.suptitle(f'Who touches what in the bot\'s game (frames {doc["replay"]["first_frame"]}-'
                 f'{doc["replay"]["last_frame"]}): four modules fill the buffer, the blit alone copies it to the screen',
                 color=FG, fontsize=12, x=0.08, ha='left', y=0.98)
    save(fig, out)


# ---------------------------------------------------------------- records

FIELD_NAMES = ['+0 type, flags', '+1 along (lo)', '+2 along (hi)', '+3 across', '+4 height', '+5 direction',
               '+6 speed', '+7 behaviour', '+8 sprite / explosion', '+9 place in strips', '+A place in strips',
               '+B place in strips', '+C motion step', '+D', '+E motion step', '+F fire timer / hits']
GROUPS = [(0xC000, 1, 'player'), (0xC010, 5, 'player\'s shots'), (0xC060, 4, 'pods'), (0xC0A0, 1, 'parked vehicle'),
          (0xC0B0, 16, 'course objects'), (0xC1B0, 6, 'launched'), (0xC210, 5, 'enemy shots'),
          (0xC260, 1, 'vehicle before')]


def records(l1, out):
    _, rd, wr, _, replay = heatmap.load(l1, heatmap.BASES_48K)
    lo, n = 0xC000, 39
    fig, axes = plt.subplots(1, 2, figsize=(13, 9.6), dpi=100, gridspec_kw={'wspace': 0.05})
    style(fig, axes)
    cmap = plt.get_cmap('inferno').copy()
    cmap.set_bad('#0c0c10')
    for ax, values, kind in zip(axes, (rd, wr), ('reads', 'writes')):
        grid = np.array(values[lo:lo + 16 * n], dtype=float).reshape(n, 16)
        top = grid.max()
        shown = np.ma.masked_where(grid == 0, np.log2(grid + 1) / math.log2(top + 1))
        ax.imshow(shown, aspect='auto', interpolation='nearest', cmap=cmap, vmin=0, vmax=1)
        ax.set_xticks(range(16))
        ax.set_xticklabels(FIELD_NAMES, rotation=50, ha='left', rotation_mode='anchor', fontsize=8)
        ax.xaxis.tick_top()
        ax.set_xticks(np.arange(-0.5, 16), minor=True)
        ax.set_yticks(np.arange(-0.5, n), minor=True)
        ax.grid(which='minor', color='#0c0c10', lw=0.6)
        ax.tick_params(which='minor', length=0)
        for base, count, _ in GROUPS[1:]:
            ax.axhline((base - lo) / 16 - 0.5, color='#9aa0b0', lw=1.0)
        ax.set_xlabel(f'{kind.upper()} per byte (peak {int(top):,} in one byte; black: never)', color=FG,
                      fontsize=10.5)
        ax.set_yticks([(base - lo) / 16 + (count - 1) / 2 for base, count, _ in GROUPS])
        ax.set_yticklabels([f'{name}\n${base:04X}' + (f'-${base + 16 * (count - 1):04X}' if count > 1 else '')
                            for base, count, name in GROUPS] if kind == 'reads' else [], fontsize=8.5,
                           linespacing=1.0)
    ax = axes[0]
    ax.annotate('+0: read in\nevery slot,\nevery pass', xy=(0.3, 18), xytext=(11.6, 18), va='center', color=FG, fontsize=8.5,
                arrowprops=dict(arrowstyle='->', color=FG, lw=0.8),
                bbox=dict(boxstyle='round,pad=0.2', fc=AX, ec='none'))
    ax = axes[1]
    ax.annotate('enemy shots 4 and 5 ($C240, $C250):\nonly the round start\'s +0 and +8;\n'
                'never more than 3 enemy shots at once', xy=(4, 36.5), xytext=(3.2, 31.8), color=FG, fontsize=8.5,
                arrowprops=dict(arrowstyle='->', color=FG, lw=0.8),
                bbox=dict(boxstyle='round,pad=0.2', fc=AX, ec='none'))
    ax.annotate('+C-+E (the motion steps):\nnever for the player\nor the pods', xy=(13, 7.5), xytext=(9.6, 1.0),
                color=FG, fontsize=8.5, arrowprops=dict(arrowstyle='->', color=FG, lw=0.8),
                bbox=dict(boxstyle='round,pad=0.2', fc=AX, ec='none'))
    fig.suptitle(f'The object list $C000-$C26F as used in the bot\'s game (frames {replay["first_frame"]}-'
                 f'{replay["last_frame"]}): one row a 16-byte record, one column a field; brighter = more often (log)',
                 color=FG, fontsize=11.5, x=0.08, ha='left', y=1.03)
    save(fig, out)


# ---------------------------------------------------------------- screen

def screen(l1, out):
    _, _, wr, _, replay = heatmap.load(l1, heatmap.BASES_48K)
    blits = 2622  # the blit's entries over the game, doc 6.7
    kinds = [  # test, colour, label
        (lambda n: n == 2631, (0.35, 0.85, 0.95), 'status window (AUTO, DEMO, the gauge): every pass it shows'),
        (lambda n: 2600 <= n < 2631, (0.95, 0.75, 0.27), f'the play area: once a pass ({blits:,} blits)'),
        (lambda n: 2 <= n < 100, (0.90, 0.30, 0.35), 'the panel\'s numbers (SCORE, MAX, HIGH, round, lives): '
                                                      'when they change'),
        (lambda n: n == 1, (0.42, 0.42, 0.50), 'once: the copy of the game screen from $A000, nothing after'),
    ]
    counts = [[0, 0] for _ in kinds]
    bmp, att = np.full((192, 256, 3), 0.06), np.full((24, 32, 3), 0.06)
    attr_kinds = [  # attribute cells
        (lambda n: n == 2631, (0.35, 0.85, 0.95)),
        (lambda n: 2 <= n < 100, (0.55, 0.40, 0.80)),
        (lambda n: n == 1, (0.42, 0.42, 0.50)),
    ]
    for a in range(0x4000, 0x5800):
        for k, (test, colour, _) in enumerate(kinds):
            if wr[a] and test(wr[a]):
                x, y = screen_xy(a)
                bmp[y, x:x + 8] = colour
                counts[k][0] += 1
    acount = [0, 0, 0]
    for a in range(0x5800, 0x5B00):
        for k, (test, colour) in enumerate(attr_kinds):
            if wr[a] and test(wr[a]):
                i = a - 0x5800
                att[i >> 5, i & 31] = colour
                acount[k] += 1
    fig, (ax, bx) = plt.subplots(1, 2, figsize=(13, 5.6), dpi=100, gridspec_kw={'wspace': 0.06})
    style(fig, (ax, bx))
    ax.imshow(bmp, interpolation='nearest')
    bx.imshow(att, interpolation='nearest', extent=(0, 256, 192, 0))
    for a in (ax, bx):
        a.set_xticks(range(0, 257, 64))
        a.set_yticks(range(0, 193, 48))
        a.set_xlabel('pixel column', color=DIM, fontsize=8.5)
    ax.set_ylabel('screen line', color=DIM, fontsize=8.5)
    ax.set_title('Bitmap $4000-$57FF: each byte as its 8 x 1 pixels', color=FG, fontsize=10.5, loc='left')
    bx.set_title('Attributes $5800-$5AFF: each byte as its 8 x 8 cell', color=FG, fontsize=10.5, loc='left')
    handles = [Patch(color=c, label=f'{label} ({counts[k][0]:,} bytes)') for k, (_, c, label) in enumerate(kinds)]
    handles.append(Patch(color=(0.55, 0.40, 0.80), label=f'attribute cells written 9-19 times: the course colour of '
                                                         f'each round setup, the menu ({acount[1]} cells)'))
    fig.legend(handles=handles, loc='lower left', bbox_to_anchor=(0.12, -0.17), ncol=1, fontsize=9,
               frameon=False, labelcolor='#d6d8e0')
    fig.suptitle(f'Where the screen is written over the bot\'s game (frames {replay["first_frame"]}-'
                 f'{replay["last_frame"]}): the play area band every pass, the panel almost never',
                 color=FG, fontsize=12, x=0.12, ha='left', y=0.93)
    print('bitmap kinds', counts, 'attribute kinds', acount)
    save(fig, out)


# ---------------------------------------------------------------- coverage

RUNS = [  # address, label: the runs only the bot's game reached (doc 10.1)
    (0xD017, 'fall back: the look-back'),
    (0xDB1B, 'small shadows (types 11-13)'),
    (0xE008, 'small shadows, 2nd part'),
    (0xE271, 'a follower lost instead'),
    (0xE4C6, 'the barrier'),
    (0xE773, 'Kempston (the bot)'),
    (0xE7BE, 'the convoy follows'),
    (0xE848, 'the ground vehicle'),
    (0xECAC, 'a cube hit'),
    (0xECF3, 'a pod picked up'),
    (0xEDE3, 'a pod released'),
]
RUNS_M1 = [(0xD0C3, 'pause and abort keys'), (0xE789, 'the other input readers')]


def coverage(l1, other, out):
    a = heatmap.load(l1, heatmap.BASES_48K)[0]
    b = heatmap.load(other, heatmap.BASES_48K)[0]
    lo, hi = 0xC000, 0xFFFF
    rows = (hi + 1 - lo) // 256
    both, only_a, only_b, none = (0.40, 0.40, 0.46), (0.98, 0.67, 0.16), (0.30, 0.60, 0.95), (0.05, 0.05, 0.07)
    img = np.zeros((rows, 256, 3))
    n = [0, 0, 0]
    for x in range(lo, hi + 1):
        r, c = divmod(x - lo, 256)
        if a[x] and b[x]:
            img[r, c], n[0] = both, n[0] + 1
        elif a[x]:
            img[r, c], n[1] = only_a, n[1] + 1
        elif b[x]:
            img[r, c], n[2] = only_b, n[2] + 1
        else:
            img[r, c] = none
    r0, r1 = (0xCF00 - lo) >> 8, (0xF2FF - lo) >> 8  # the rows of the game code
    img = img[r0:r1 + 1]
    rows = r1 - r0 + 1
    fig, ax = plt.subplots(figsize=(13, 8.6), dpi=100)
    style(fig, (ax,))
    ax.imshow(img, aspect='auto', interpolation='nearest', extent=(-0.5, 255.5, rows - 0.5, -0.5))
    ticks = list(range(0, rows, 2))
    ax.set_yticks(ticks)
    ax.set_yticklabels([f'${0xCF00 + 256 * t:04X}' for t in ticks])
    ax.set_xticks([0, 64, 128, 192, 255])
    ax.set_xticklabels(['+$00', '+$40', '+$80', '+$C0', '+$FF'])
    ax.set_xlabel('byte within the row (one row = 256 bytes; rows $CF00-$F2FF, the game code)', color=DIM,
                  fontsize=9)
    ax.set_xlim(-0.5, 255.5)
    key = []
    for k, (addr, label) in enumerate(RUNS + RUNS_M1, 1):
        r, c = divmod(addr - 0xCF00, 256)
        colour = '#fbb040' if (addr, label) in RUNS else '#6fa8ff'
        ax.text(c, r - 0.62, str(k), color='#000', fontsize=8, ha='center', va='center', fontweight='bold',
                bbox=dict(boxstyle='circle,pad=0.18', fc=colour, ec='#000', lw=0.6))
        key.append((k, f'${addr:04X} {label}', colour))
    for i, (k, text, colour) in enumerate(key):
        ax.text(262, 0.2 + i * 1.25, f'{k:>2}  {text}', color=colour, fontsize=9, va='center', ha='left',
                family='monospace')
    ax.legend(handles=[Patch(color=both, label=f'run in both ({n[0]:,} bytes)'),
                       Patch(color=only_a, label=f'only in the bot\'s game, work/p2 ({n[1]:,} bytes)'),
                       Patch(color=only_b, label=f'only in the first recording, work/m1 ({n[2]:,} bytes)'),
                       Patch(color=none, label='never run: data, or code neither reached')],
              loc='upper left', bbox_to_anchor=(0, -0.07), ncol=2, fontsize=9, frameon=False, labelcolor='#d6d8e0')
    ax.set_title(f'What the bot\'s game reached: {n[1]} bytes of code the first recording never ran '
                 f'(rounds 2-4, pods, the convoy, the fall back)', color=FG, fontsize=12, loc='left')
    print('both', n[0], 'only first', n[1], 'only other', n[2])
    save(fig, out)


# ---------------------------------------------------------------- routines

JOBS = [  # name, colour
    ('drawing: playfield, objects, blit', '#c77ddb'),
    ('moving the objects, the hit test', '#5c8fd6'),
    ('sound effects (the game waits)', '#e5534b'),
    ('the menu waiting for a key', '#d9a441'),
    ('other (text, input, pauses)', '#7b7f8c'),
]
JOB_OF_MODULE = {'scroller': 0, 'sprites': 0, 'shadows': 0, 'statics': 0, 'objview': 0,
                 'mover': 1, 'hits': 1, 'player': 1}
JOB_OF_NAME = {'Sweep': 2, 'Beep': 2, 'Menu': 3, 'ReadControls': 4}


def routines(l1, out, top):
    doc = json.load(open(l1))
    mods = heatviews.module_ranges()
    starts = [m[0] for m in mods]

    def job(entry):
        name = heatviews.NAMES.get(entry, '')
        if name in JOB_OF_NAME:
            return JOB_OF_NAME[name]
        i = bisect.bisect_right(starts, int(entry[1:], 16)) - 1
        return JOB_OF_MODULE.get(mods[i][1] if i >= 0 else '', 4)

    total = doc['replay']['tstates']
    sums = [0] * len(JOBS)
    for r in doc['routines']:
        sums[job(r['entry'])] += r['profile']['tstates']
    rows = sorted(((r['profile']['tstates'], r['entry'], r['profile']['entries']) for r in doc['routines']),
                  reverse=True)[:top]
    fig, ax = plt.subplots(figsize=(11, 0.32 * len(rows) + 1.6), dpi=100)
    style(fig, (ax,))
    ys = np.arange(len(rows))
    ax.barh(ys, [100 * t / total for t, _, _ in rows], color=[JOBS[job(e)][1] for _, e, _ in rows], height=0.72)
    ax.set_yticks(ys)
    ax.set_yticklabels([f'{heatviews.NAMES.get(e, "")}  {e}' for _, e, _ in rows], fontsize=8.5)
    ax.invert_yaxis()
    for y, (t, _, calls) in zip(ys, rows):
        ax.text(100 * t / total + 0.3, y, f'{100 * t / total:.1f} %   {calls:,} calls', color=DIM, fontsize=8,
                va='center')
    ax.set_xlim(0, 100 * rows[0][0] / total + 7)
    ax.set_xlabel(f'% of all {total:,} t-states (own time of the routine, not of what it calls)', color=DIM,
                  fontsize=9)
    ax.grid(axis='x', color=GRID, lw=0.5)
    ax.set_axisbelow(True)
    ax.legend(handles=[Patch(color=c, label=f'{name}: {100 * s / total:.0f} % in all') for (name, c), s in
                       zip(JOBS, sums)], loc='lower right', fontsize=9, frameon=True, facecolor=AX, edgecolor=GRID,
              labelcolor='#d6d8e0', title='every routine of the game, by job', title_fontsize=9)
    ax.get_legend().get_title().set_color(FG)
    ax.set_title(f'Where the time goes in the bot\'s game: drawing {100 * sums[0] / total:.0f} %, the blit alone '
                 f'{100 * rows[0][0] / total:.0f} %', color=FG, fontsize=12, loc='left')
    print('jobs', [(name, round(100 * s / total, 1)) for (name, _), s in zip(JOBS, sums)])
    save(fig, out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('view', choices=['memory', 'modules', 'records', 'screen', 'coverage', 'routines'])
    p.add_argument('l1')
    p.add_argument('png')
    p.add_argument('--other', help='coverage: the build to compare with')
    p.add_argument('--top', type=int, default=24)
    args = p.parse_args()
    if args.view == 'coverage':
        coverage(args.l1, args.other, args.png)
    elif args.view == 'routines':
        routines(args.l1, args.png, args.top)
    else:
        globals()[args.view](args.l1, args.png)


if __name__ == '__main__':
    main()
