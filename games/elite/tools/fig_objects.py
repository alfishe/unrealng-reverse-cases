#!/usr/bin/env python3
"""The ship slots over a recorded window (docs/07-objects.md), read from an access trace: the eight 39-byte slots
of ShipSlots `$6048` at the start of every frame.

    python3 tools/fig_objects.py TRACE OUT.png [--title TEXT] [--dump]

The figure has three panels:

- the slots against the frame: a bar per slot while it holds a ship (+$22 energy non-zero), coloured by its
  blueprint (the header's address in +$23-+$24), with the energy written at each change;
- the ships seen from above as the scanner sees them: x across, z ahead, the player at the origin facing up, one
  track per slot over the window, coloured by slot (a dot at its start, the slot number at its end);
- each ship's distance (the largest of |x|, |y|, |z|) against the frame, coloured by slot.

A coordinate is three bytes, low, high and the top bits with the sign in bit 7. --dump prints the slots frame by
frame instead.
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import rtplot as P  # noqa: E402

SLOTS, SIZE, BASE = 8, 39, 0x6048
ANN = os.path.join(HERE, '..', 'src', 'game', 'game.ann')


def blueprints():
    """{header address: name} from the .ann's blueprint headers ($6A9D b ShipCoriolis 23 ; blueprint 0: ...)"""
    out = {}
    for line in open(ANN):
        m = re.match(r'^\$([0-9A-F]{4}) b Ship(\w+) 23 ; blueprint \d+', line)
        if m:
            out[int(m.group(1), 16)] = re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', m.group(2))
    return out


BLUEPRINTS = blueprints()


def coordinate(m, a):
    low, high, top = m[a], m[a + 1], m[a + 2]
    v = (top & 0x7F) << 16 | high << 8 | low
    return -v if top & 0x80 else v


def slots_by_frame(trace):
    """[(frame, [slot dict or None] * 8)] at the first instruction of each frame"""
    out, last = [], None
    for i, x in enumerate(trace.instructions):
        if x.frame == last:
            continue
        last = x.frame
        m = trace.memory_at(i)
        row = []
        for s in range(SLOTS):
            a = BASE + s * SIZE
            if m[a + 0x22] == 0:
                row.append(None)
                continue
            row.append({'x': coordinate(m, a), 'y': coordinate(m, a + 3), 'z': coordinate(m, a + 6),
                        'energy': m[a + 0x22], 'blueprint': BLUEPRINTS.get(m[a + 0x23] | m[a + 0x24] << 8, '?'), 'flags': m[a + 0x20],
                        'state': m[a + 0x25], 'speed': m[a + 0x1B]})
        out.append((x.frame, row))
    return out


def runs(rows, s):
    """the runs of slot s: [(blueprint, [(frame, record)])], a new run where the slot empties or changes blueprint"""
    out, prev = [], None
    for f, row in rows:
        r = row[s]
        if r is None:
            prev = None
            continue
        if prev is None or prev != r['blueprint']:
            out.append((r['blueprint'], []))
        out[-1][1].append((f, r))
        prev = r['blueprint']
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('trace')
    p.add_argument('out')
    p.add_argument('--title')
    p.add_argument('--dump', action='store_true')
    args = p.parse_args()
    trace = K.access_trace().load(args.trace)
    rows = slots_by_frame(trace)
    if args.dump:
        for f, row in rows:
            print(f, ' | '.join('-' if r is None else '%s e%d z%d s%02X' % (r['blueprint'][:8], r['energy'],
                                                                         r['z'], r['state']) for r in row))
        return
    frames = [f for f, _ in rows]
    SLOT_COLOURS = P.plt.get_cmap('Set2')
    colours = {}
    palette = P.plt.get_cmap('tab10')  # the blueprints (the slot panels use Set2 by slot)
    fig, axes = P.figure(9, 15, nrows=3, ncols=1)
    ax = axes[0]
    for s in range(SLOTS):
        for name, run in runs(rows, s):
            colours.setdefault(name, palette(len(colours) % 10))
            prev = None
            for f, r in run:
                ax.barh(s, 1, left=f, color=colours[name], height=0.7)
                if prev != r['energy']:
                    ax.text(f, s + 0.42, '%d' % r['energy'], fontsize=8, color=P.TEXT)
                prev = r['energy']
    ax.set_yticks(range(SLOTS))
    ax.set_yticklabels(['slot %d%s' % (s, ' (station)' if s == 0 else ' (missile)' if s == 7 else '')
                        for s in range(SLOTS)], fontsize=9)
    ax.invert_yaxis()
    ax.set_xlabel('frame')
    ax.set_title('1. the slots in use, by blueprint (the number: the energy, +$22)', fontsize=10)
    ax.legend(handles=[P.plt.matplotlib.patches.Patch(color=c, label=n) for n, c in colours.items()], fontsize=9,
              loc='lower right')
    ax = axes[1]
    labels = []
    for s in range(SLOTS):
        for name, run in runs(rows, s):
            xs, zs = [r['x'] for _, r in run], [r['z'] for _, r in run]
            ax.plot(xs, zs, color=SLOT_COLOURS(s), lw=1.5)
            ax.plot(xs[0], zs[0], 'o', color=SLOT_COLOURS(s), ms=4)
            labels.append((xs[-1], zs[-1], ' %d %s' % (s, name), P.TEXT))
    ax.plot(0, 0, '^', color=P.HOT, ms=10)
    labels.append((0, 0, '  the player', P.HOT))
    map_ax = ax
    ax.axhline(0, color=P.DIM, lw=0.6)
    ax.axvline(0, color=P.DIM, lw=0.6)
    ax.set_xlabel('x (across)')
    ax.set_ylabel('z (ahead)')
    ax.set_title('2. seen from above: x and z of each slot (a dot where a ship appears)', fontsize=10)
    ax = axes[2]
    for s in range(SLOTS):
        for name, run in runs(rows, s):
            ax.plot([f for f, _ in run], [max(abs(r['x']), abs(r['y']), abs(r['z'])) for _, r in run],
                    color=SLOT_COLOURS(s), lw=1.5, label='slot %d %s' % (s, name))
    ax.set_yscale('log')
    ax.set_xlabel('frame')
    ax.set_ylabel('the largest of |x|, |y|, |z|')
    ax.set_title('3. the distance of each slot (log scale)', fontsize=10)
    ax.legend(fontsize=9)
    import textwrap
    fig.suptitle(textwrap.fill(args.title or 'The ship slots, frame by frame', 80), fontsize=12)
    fig.tight_layout(rect=(0, 0, 1, 0.975))
    fig.canvas.draw()                              # the labels, pushed apart where they would overlap (pixels)
    placed = []
    for x, z, text, col in labels:
        px, py = map_ax.transData.transform((x, z))
        dy = 0
        while any(abs(px - qx) < 110 and abs(py - dy - qy) < 15 for qx, qy in placed):
            dy += 15
        placed.append((px, py - dy))
        pt = 72.0 / fig.dpi
        map_ax.annotate(text, (x, z), xytext=(4 * pt if dy else 0, -dy * pt), textcoords='offset points', fontsize=9,
                        color=col, va='center', arrowprops={'arrowstyle': '-', 'color': P.DIM, 'lw': 0.6} if dy else None)
    P.save(fig, args.out)


if __name__ == '__main__':
    main()
