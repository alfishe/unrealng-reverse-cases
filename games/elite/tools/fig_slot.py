#!/usr/bin/env python3
"""The ship record as a data sheet (docs/07-objects.md): one slot's 39 bytes frame by frame (a column a frame, a row a byte), each cell the byte's
value at the frame's start, coloured by the routine that wrote it during that frame (dark: not written).

    python3 tools/fig_slot.py OUT.png TRACE:SLOT:FRAMES:LABEL [TRACE:SLOT:FRAMES:LABEL ...] [--title TEXT]

FRAMES is how many frames from the trace's start to show. The routines are the .ann's code entries (c), so a byte
written by MovePosition's inner CombineParts counts as CombineParts. The header names the fields.
"""
import argparse
import bisect
import os
import re
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import rtplot as P  # noqa: E402

SIZE, BASE = 39, 0x6048
ANN = os.path.join(HERE, '..', 'src', 'game', 'game.ann')
FIELDS = [(0, 3, 'x'), (3, 3, 'y'), (6, 3, 'z'), (9, 6, 'nose axis'), (15, 6, 'roof axis'), (21, 6, 'side axis'),
          (27, 1, 'spd'), (28, 1, 'acc'), (29, 1, 'roll'), (30, 1, 'pitch'), (31, 1, ''), (32, 1, 'flags'),
          (33, 1, 'beh'), (34, 1, 'enrg'), (35, 2, 'blueprint'), (37, 1, 'tact'), (38, 1, 'role')]


def routines():
    out = []
    for line in open(ANN):
        m = re.match(r'^\$([0-9A-F]{4}) c (\w+)', line)
        if m:
            out.append((int(m.group(1), 16), m.group(2)))
    out.sort()
    return [a for a, _ in out], [n for _, n in out]


def sheet(path, slot, count):
    """[(frame, values[39], writer[39] or None)]"""
    addresses, names = routines()
    trace = K.access_trace().load(path)
    base = BASE + slot * SIZE
    rows, frame, writers = [], None, None
    for i, x in enumerate(trace.instructions):
        if x.frame != frame:
            if len(rows) == count:
                break
            frame = x.frame
            m = trace.memory_at(i)
            writers = [Counter() for _ in range(SIZE)]
            rows.append((frame, bytes(m[base:base + SIZE]), writers))
        for c in x.cycles:
            if c.tag == 'W' and base <= c.address < base + SIZE:
                writers[c.address - base][names[bisect.bisect_right(addresses, x.pc) - 1]] += 1
    return [(f, v, [w.most_common(1)[0][0] if w else None for w in ws]) for f, v, ws in rows]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('out')
    p.add_argument('panels', nargs='+')
    p.add_argument('--title')
    args = p.parse_args()
    panels = []
    for spec in args.panels:
        path, slot, count, label = spec.split(':', 3)
        panels.append((label, sheet(path, int(slot), int(count))))
    names = sorted({w for _, rows in panels for _, _, ws in rows for w in ws if w})
    palette = P.plt.get_cmap('tab10')
    colour = {n: palette(i % 10) for i, n in enumerate(names)}
    # a column a frame, a row a byte (39 rows read down like the record), the panels side by side
    fig, axes = P.figure(4.8 * len(panels), 0.25 * SIZE + 2.2, nrows=1, ncols=len(panels))
    axes = axes if len(panels) > 1 else [axes]
    field_of = {start: name for start, _, name in FIELDS}
    for ax, (label, rows) in zip(axes, panels):
        for c, (f, values, ws) in enumerate(rows):
            for b in range(SIZE):
                if ws[b]:
                    ax.add_patch(P.plt.Rectangle((c, b), 1, 1, color=colour[ws[b]], alpha=0.75))
                ax.text(c + 0.5, b + 0.55, '%02X' % values[b], ha='center', va='center', fontsize=8.5,
                        family='monospace', color=P.TEXT)
            ax.text(c + 0.5, -0.3, str(f), ha='center', va='bottom', fontsize=8.5, color=P.DIM)
        for b in range(SIZE):
            ax.text(-0.15, b + 0.55, '+%02X' % b, ha='right', va='center', fontsize=8, color=P.DIM,
                    family='monospace')
        for start, width, name in FIELDS:
            ax.axhline(start, color=P.DIM, lw=0.6)
            if name:
                ax.text(-1.55, start + width / 2 + 0.05, name, ha='right', va='center', fontsize=9, color=P.TEXT)
        ax.set_xlim(-4.6, len(rows))
        ax.set_ylim(SIZE + 0.2, -1.3)
        ax.set_xticks([])
        ax.set_yticks([])
        for side in ax.spines.values():
            side.set_visible(False)
        ax.set_title(label + '\na column a frame', fontsize=10, loc='left')
    handles = [P.plt.matplotlib.patches.Patch(color=colour[n], alpha=0.75, label=n) for n in names]
    fig.legend(handles=handles, loc='lower center', ncol=min(len(names), 4), fontsize=9, frameon=False)
    fig.suptitle(args.title or 'One ship slot, frame by frame', fontsize=11)
    fig.tight_layout(rect=(0, 0.06, 1, 1))
    P.save(fig, args.out)


if __name__ == '__main__':
    main()
