#!/usr/bin/env python3
"""The figures of doc 07 (objects), drawn from the memory pictures of tools/fig_events.py (an .npz of $4000-$FFFF
per sampled frame: banks 5, 2 and 0 as the game's main code sees them). No emulator is needed.

    python3 tools/fig_objects.py records --cache work/docL/cache/deep10.npz --frame 20000 --out docs/img/objects/robot-records.png
    python3 tools/fig_objects.py time --cache work/docL/cache/deep10.npz --step 120 --out docs/img/objects/robots-over-time.png
    python3 tools/fig_objects.py owners --cache work/docL/cache/deep10.npz --out docs/img/objects/ownership-days.png
    python3 tools/fig_objects.py banks --image work/images/scl-play-bank0.bin --out docs/img/objects/bank0-tables.png
    python3 tools/fig_objects.py fields --cache work/docL/cache/deep10.npz --from 18000 --to 20000 [--slot 0]
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402

plt.rcParams['text.parse_math'] = False

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_events as E  # noqa: E402

OURS, THEIRS = '#1080d0', '#d06010'
ORDERS = ['stop', 'advance', 'retreat', 'destroy robots', 'destroy factories', 'destroy warbases',
          'capture neutral', 'capture enemy factories', 'capture enemy warbases']
PARTS = ['bipod', 'tracks', 'anti-grav', 'cannon', 'missiles', 'phasers', 'nuclear', 'electronics']
DIRS = {0: '-', 1: 'right', 2: 'left', 4: 'down', 8: 'up', 0xFF: 'stay'}


def in_play(v):
    return v.word(E.HANDLER) == E.PLAY_INTERRUPT


def index_of(pics, frame):
    return min(range(len(pics)), key=lambda i: abs(pics.frames[i] - frame))


def parts_text(p):
    return '+'.join(n for k, n in enumerate(PARTS) if p >> k & 1)


def cmd_records(a):
    pics = E.Pictures.load(a.cache)
    i = index_of(pics, a.frame)
    v = pics.at(i)
    rows = v.robots()
    fig, ax = plt.subplots(figsize=(17, 0.24 * len(rows) + 1.2), dpi=80)
    ax.axis('off')
    head = ['slot', 'record bytes +$00..+$0F', 'cell (x, y)', 'parts +$07', 'height\n+$09', 'control\n+$0A',
            'order +$0B', 'strength\n+$0C', 'ground\n+$0D', 'target\n+$0E', 'delay\n+$0F']
    cells = []
    colours = []
    for r in rows:
        raw = r['raw']
        cells.append([str(r['slot']), ' '.join(f'{b:02X}' for b in raw), f"({r['x']}, {r['y']})", parts_text(r['parts']),
                      str(r['height']), f"${r['control']:02X}", f"{r['order']} {ORDERS[r['order']] if r['order'] < 9 else '?'}",
                      str(E.strength(r['strength'])), str(r['ground']),
                      '-' if r['target'] == 0xFF else str(r['target']), str(r['delay'])])
        colours.append(['#dbe9f6' if r['slot'] < 24 else '#f6e2d3'] * len(head))
    t = ax.table(cellText=cells, colLabels=head, cellColours=colours, loc='upper center', cellLoc='left',
                 colWidths=[0.03, 0.25, 0.07, 0.20, 0.05, 0.05, 0.16, 0.055, 0.05, 0.05, 0.045])
    t.auto_set_font_size(False)
    t.set_fontsize(8)
    t.scale(1, 1.25)
    for (rr, cc), cell in t.get_celld().items():
        if rr == 0:
            cell.set_height(cell.get_height() * 1.8)
    ours = sum(r['slot'] < 24 for r in rows)
    d, h, m = v.clock()
    ax.set_title(f'{len(rows)} live robot records at frame {pics.frames[i]} (day {d}, {h:02d}:{m:02d}): {ours} ours (blue, '
                 f'slots 0-23 at $DA00), {len(rows) - ours} the enemy\'s (orange, slots 24-47 at $DB80)\n'
                 f'every free slot has +$01 = 0; work/docL/deep, memory of banks 5, 2, 0', fontsize=10)
    fig.savefig(a.out, bbox_inches='tight')
    print(a.out, pics.frames[i], len(rows), ours)


def cmd_time(a):
    pics = E.Pictures.load(a.cache)
    xs, ours, theirs, fo, ft, wo, wt = [], [], [], [], [], [], []
    for i in range(len(pics)):
        f = pics.frames[i]
        if f % a.step:
            continue
        v = pics.at(i)
        if not in_play(v):
            continue
        rs = v.robots()
        d, h, m = v.clock()
        xs.append(d + (h * 60 + m) / 1440)
        ours.append(sum(r['slot'] < 24 for r in rs))
        theirs.append(sum(r['slot'] >= 24 for r in rs))
        pb, eb = v[0xFD3A:0xFD41], v[0xFD42:0xFD49]
        fo.append(sum(pb[1:]))
        ft.append(sum(eb[1:]))
        wo.append(pb[0])
        wt.append(eb[0])
    E.plt_setup()
    fig, ax = plt.subplots(figsize=(11, 5), dpi=90)
    ax.plot(xs, ours, color=OURS, lw=2.5, label='our robots (live records, slots 0-23)')
    ax.plot(xs, theirs, color=THEIRS, lw=2.5, label="the enemy's robots (slots 24-47)")
    ax.plot(xs, fo, color=OURS, lw=1.5, ls='--', label='factories we hold ($FD3B-$FD40)')
    ax.plot(xs, ft, color=THEIRS, lw=1.5, ls='--', label="factories the enemy holds ($FD43-$FD48)")
    io, it = max(range(len(ours)), key=ours.__getitem__), max(range(len(theirs)), key=theirs.__getitem__)
    ax.annotate(f'our peak: {ours[io]}', (xs[io], ours[io]), (xs[io], ours[io] + 3), color=OURS,
                arrowprops=dict(arrowstyle='->', color=OURS), ha='center')
    ax.annotate(f'enemy peak: {theirs[it]}', (xs[it], theirs[it]), (xs[it] - 1, theirs[it] + 2), color=THEIRS,
                arrowprops=dict(arrowstyle='->', color=THEIRS), ha='center')
    ax.annotate(f'at the end: {ours[-1]} vs {theirs[-1]} robots,\n{fo[-1]} vs {ft[-1]} factories, warbases {wo[-1]} vs {wt[-1]}',
                (xs[-1], theirs[-1]), (xs[-1] - 3.5, theirs[-1] + 4.5), arrowprops=dict(arrowstyle='->', color='#555'))
    ax.set_xlabel(f'game day (clock $FD35-$FD37; one sample every {a.step} frames of work/docL/deep)')
    ax.set_ylabel('count')
    ax.set_ylim(0, max(max(theirs), max(ft)) + 8)
    ax.grid(alpha=0.3)
    ax.legend(loc='upper left', fontsize=9, frameon=False)
    ax.set_title(f'The enemy outbuilds us: {theirs[it]} robots against our {ours[io]} at the peaks', fontsize=12)
    fig.tight_layout()
    fig.savefig(a.out)
    print(a.out, 'peaks', ours[io], theirs[it], 'end', ours[-1], theirs[-1], fo[-1], ft[-1], wo[-1], wt[-1], 'days', xs[-1])


def owner_colour(o):
    if o & 0x80:
        return '#000000'
    if o & 0x40:
        return OURS
    if o & 0x20:
        return THEIRS
    return '#bbbbbb'


def cmd_owners(a):
    pics = E.Pictures.load(a.cache)
    last = {}
    for i in range(len(pics)):
        v = pics.at(i)
        if in_play(v):
            last[v.clock()[0]] = i
    days = sorted(last)
    E.plt_setup()
    fig, axes = plt.subplots(len(days), 1, figsize=(12, 0.62 * len(days) + 1.2), dpi=90, sharex=True)
    prev = None
    changes = []
    for ax, d in zip(axes, days):
        v = pics.at(last[d])
        pts = [v.point(k) for k in range(28)]
        ax.set_xlim(0, 512)
        ax.set_ylim(16, -1)
        ax.set_yticks([])
        for r in v.robots():
            ax.plot(r['x'], r['y'], '.', ms=3, color=OURS if r['slot'] < 24 else THEIRS)
        n = 0
        for k, p in enumerate(pts):
            mark = 's' if k < 4 else 'o'
            ax.plot(p['x'], p['y'], mark, ms=7, color=owner_colour(p['owner']), mec='#333', mew=0.5)
            if prev and (prev[k]['owner'] & 0xE0) != (p['owner'] & 0xE0):
                ax.plot(p['x'], p['y'], 'o', ms=13, mfc='none', mec='#d00000', mew=1.5)
                n += 1
                changes.append((d, k, prev[k]['owner'], p['owner']))
        o = sum(1 for p in pts[4:] if p['owner'] & 0x40)
        t = sum(1 for p in pts[4:] if p['owner'] & 0x20)
        ax.set_ylabel(f'day {d}', rotation=0, ha='right', va='center', fontsize=9)
        ax.text(514, 7, f'{o} : {t}' + (f'  ({n} taken)' if n else ''), fontsize=8, va='center')
        prev = pts
    axes[-1].set_xlabel('map column (0-511); squares warbases, circles factories; blue ours, orange the enemy\'s, '
                        'grey neutral; red ring: changed hands that day; dots: robots')
    fig.suptitle(f'Who holds what at the end of each day: {len(changes)} captures in work/docL/deep '
                 f'(factories ours : the enemy\'s on the right)', fontsize=12)
    fig.tight_layout()
    fig.savefig(a.out)
    print(a.out, changes)


def cmd_banks(a):
    """Bank 0 ($C000-$FFFF in play) by what holds it"""
    regions = [(0xC000, 0xC4A6, 'menu, save / load code', '#9e9e9e'),
               (0xC4A7, 0xC4FF, 'free', '#eeeeee'),
               (0xC500, 0xC6FF, 'the Cyrillic font', '#c0a060'),
               (0xC700, 0xC848, 'free', '#eeeeee'),
               (0xC849, 0xD7D2, 'construction, view, screen, print, interrupts, tables', '#9e9e9e'),
               (0xD7D3, 0xD7FF, 'Shots (5 x 9)', '#e53935'),
               (0xD800, 0xD9FF, 'the radar buffers', '#8e24aa'),
               (0xDA00, 0xDB7F, 'Robots: ours (24 x 16)', OURS),
               (0xDB80, 0xDCFF, "EnemyRobots (24 x 16)", THEIRS),
               (0xDD00, 0xFCFF, 'Map: 16 rows x 512 cells', '#43a047'),
               (0xFD00, 0xFDFF, 'variables: clock, resources, counts, capture points $FD70', '#fdd835'),
               (0xFE00, 0xFF00, 'unused in play', '#eeeeee'),
               (0xFF01, 0xFFC9, 'Buildings (56 x 3)', '#00897b'),
               (0xFFCA, 0xFFFF, 'the stack (SP = 0)', '#6d4c41')]
    fig, ax = plt.subplots(figsize=(12, 3.6), dpi=90)
    for lo, hi, name, col in regions:
        ax.add_patch(Rectangle((lo, 0), hi - lo + 1, 1, color=col, ec='white', lw=0.5))
    ax.add_patch(Rectangle((0xC000, 1.25), 0x4000, 0.5, color='#3949ab'))
    ax.text(0xE000, 1.5, 'bank 1 (the tunes and their player) paged over all of this while a music frame plays',
            color='white', ha='center', va='center', fontsize=9)
    ax.set_xlim(0xC000, 0x10000)
    ax.set_ylim(-2.5, 2.0)
    ax.set_yticks([])
    ax.set_xticks([0xC000, 0xD000, 0xD7D3, 0xDA00, 0xDD00, 0xE000, 0xF000, 0xFD00, 0xFF01])
    ax.set_xticklabels(['$C000', '$D000', '$D7D3', '$DA00', '$DD00', '$E000', '$F000', '$FD00', '$FF01'], fontsize=8)
    # label anchors: (x of the text, y, alignment) per region name
    place = {'the Cyrillic font': (0xC600, -0.4, 'center'), 'Shots (5 x 9)': (0xD300, -0.4, 'center'),
             'the radar buffers': (0xD300, -0.85, 'center'), 'Robots: ours (24 x 16)': (0xD300, -1.3, 'center'),
             'EnemyRobots (24 x 16)': (0xD300, -1.75, 'center'), 'Map: 16 rows x 512 cells': (0xED00, -0.4, 'center'),
             'unused in play': (0xFC80, -0.85, 'right'), 'Buildings (56 x 3)': (0xFC80, -1.3, 'right'),
             'the stack (SP = 0)': (0xFC80, -1.75, 'right')}
    for lo, hi, name, col in regions:
        key = next((k for k in place if name.startswith(k)), None)
        if name.startswith('variables'):
            key = None
            ax.annotate(f'{name}  ${lo:04X}-${hi:04X}', ((lo + hi) / 2, 0), (0xFC80, -2.2), fontsize=8, ha='right',
                        arrowprops=dict(arrowstyle='-', color='#777', lw=0.6))
        if not key:
            continue
        x, y, ha = place[key]
        ax.annotate(f'{name}  ${lo:04X}-${hi:04X}', ((lo + hi) / 2, 0), (x, y), fontsize=8, ha=ha,
                    arrowprops=dict(arrowstyle='-', color='#777', lw=0.6))
    ax.text(0xC000 + 0x200, 0.5, 'code', fontsize=8, va='center')
    ax.set_title('Every object table lives in bank 0 at $C000-$FFFF: the world is out of sight of the CPU '
                 'while the music handler pages bank 1 there', fontsize=11)
    fig.tight_layout()
    fig.savefig(a.out)
    print(a.out)


def cmd_fields(a):
    """Print the step fields of one slot over a window (doc 07 table)"""
    pics = E.Pictures.load(a.cache)
    prev = None
    for i in range(len(pics)):
        f = pics.frames[i]
        if f < a.frm or f > a.to:
            continue
        r = pics.at(i).robot(a.slot)
        if not r:
            continue
        key = (r['y'], r['x'], r['course'], r['steps'], r['facing'], r['delay'])
        if key != prev:
            print(f, 'x', r['x'], 'y', r['y'], 'course', r['course'], 'steps', r['steps'], 'facing', r['facing'],
                  'delay', r['delay'], 'ground', r['ground'], 'order', r['order'], 'parts', hex(r['parts']))
        prev = key


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('records')
    s.add_argument('--cache', required=True)
    s.add_argument('--frame', type=int, required=True)
    s.add_argument('--out', required=True)
    s = sub.add_parser('time')
    s.add_argument('--cache', required=True)
    s.add_argument('--step', type=int, default=120)
    s.add_argument('--out', required=True)
    s = sub.add_parser('owners')
    s.add_argument('--cache', required=True)
    s.add_argument('--out', required=True)
    s = sub.add_parser('banks')
    s.add_argument('--image')
    s.add_argument('--out', required=True)
    s = sub.add_parser('fields')
    s.add_argument('--cache', required=True)
    s.add_argument('--from', dest='frm', type=int, default=0)
    s.add_argument('--to', type=int, default=10 ** 9)
    s.add_argument('--slot', type=int, default=0)
    a = p.parse_args()
    {'records': cmd_records, 'time': cmd_time, 'owners': cmd_owners, 'banks': cmd_banks, 'fields': cmd_fields}[a.cmd](a)


if __name__ == '__main__':
    main()
