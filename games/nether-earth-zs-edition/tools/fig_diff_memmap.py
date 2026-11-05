#!/usr/bin/env python3
"""The three game images byte by byte: Nether Earth against ZS'98, against ZS'99, and ZS'98 against ZS'99
(docs/img/diff/memmap-diff.png, docs/img/diff/modules-diff.png). Made after games/advanced-nether-earth's
tools/fig_diff_memmap.py.

    python3 tools/fig_diff_memmap.py [--map PNG] [--modules PNG] [--json work/diff/bytes.json]

The classes come from tools/diff_game.py (the builds, entry by entry, each side's own .ann). The '99 side is the
game block with the disk set of the patches block laid at its run addresses, as stage 3 leaves it before play on
128 K. One cell of the map is one byte of the CPU's view, `$6700-$D8FF`, 256 bytes a row:

  same      the same byte at the same address in both images
  code      a changed byte inside a code entry of the newer side
  text      a changed byte inside a text entry
  data      a changed byte inside a data entry (the font, the sprites, the level lists)
  new       a byte of an entry only the newer side has (new code or data)
  free      a changed byte the newer side leaves zero and unused (its *Spare / *Room entries, NOPs of removed code
            are `code`)
  leftover  a changed operand the game writes while it runs (OrderLine, the menu tune's and TitleColourCycle's operands, MenuResourcePos,
            FillViewCorner, Random's index): the image holds what was there when the author saved it, the code is
            the same
  outside   one side's image does not hold the byte (NE's `$5B00-$677F` view buffer, the '98's zero tail
            `$D7D3-$D87F` past the others' block)

It prints the counts of each pair over the common block `$6780-$D7D2` (28 755 bytes) and the changed regions
(runs of changed bytes, gaps under 16 merged), each with the entry names of both sides.
"""

import argparse
import json
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False  # hex addresses: $ is not math
import numpy as np  # noqa: E402
from matplotlib.colors import ListedColormap  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import diff_game as D  # noqa: E402

LO, HI = 0x6780, 0xD7D3           # the block all three hold
MAP_LO, MAP_HI = 0x6700, 0xD900
PAIRS = [('NE', 'Z98'), ('NE', 'Z99'), ('Z98', 'Z99')]
CLASSES = [('outside', 'outside one image', '#0e0e14'),
           ('same', 'the same byte at the same address', '#3d6b47'),
           ('code', 'changed code', '#e5534b'),
           ('text', 'changed text', '#e8913a'),
           ('data', 'changed data (font, sprites, level lists)', '#c06ad8'),
           ('new', 'new code or data', '#26c6da'),
           ('free', 'zero, unused (removed code or text)', '#5a5d6a'),
           ('leftover', 'a run-time operand saved with the image', '#f2e86d')]
INDEX = {k: i for i, (k, _, _) in enumerate(CLASSES)}
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'
# Entries (A's or B's name) whose changed bytes are operands the code writes at run time ([2.7](../docs/02-architecture.md))
LEFTOVER = {'OrderLine', 'LeadStep', 'BassStep', 'MenuResourcePos', 'FillViewCorner', 'Random', 'TitleColourCycle'}


def entry_at(case, a):
    """the entry holding address A (a table built once per case: diff_game's entry_at is a linear scan)"""
    t = getattr(case, '_at', None)
    if t is None:
        t = case._at = {}
        for e in case.entries:
            for x in range(e['addr'], e['end']):
                t[x] = e
    return t.get(a)


def classify(ta, tb):
    a, b = D.Case(ta), D.Case(tb)
    rows = D.compare(a, b)
    status = {}
    for r in rows:
        if r['ane'] is not None:
            status[r['ane']['addr']] = r['status']
    cls = {}
    for x in range(MAP_LO, MAP_HI):
        if x not in a.mem or x not in b.mem:
            cls[x] = 'outside'
            continue
        if a.mem[x] == b.mem[x]:
            cls[x] = 'same'
            continue
        ea, eb = entry_at(a, x), entry_at(b, x)
        names = {e['name'] for e in (ea, eb) if e}
        if names & LEFTOVER:
            cls[x] = 'leftover'
        elif eb and ('Spare' in eb['name'] or 'Room' in eb['name']) and b.mem[x] == 0:
            cls[x] = 'free'
        elif eb and status.get(eb['addr']) == 'b-only':
            cls[x] = 'new'
        elif not (eb or ea):
            cls[x] = 'data'
        elif (eb or ea)['kind'] == 't':
            cls[x] = 'text'
        elif (eb or ea)['kind'] == 'c':
            cls[x] = 'code'
        else:
            cls[x] = 'data'
    return a, b, rows, cls


def regions(a, b, cls, gap=16):
    """runs of changed bytes in the common block, gaps under GAP merged: (lo, hi, n changed, A names, B names)"""
    out, start, last = [], None, None
    for x in range(LO, HI + gap + 1):
        changed = x < HI and cls[x] not in ('same', 'outside')
        if changed:
            if start is None:
                start = x
            last = x
        elif start is not None and x - last >= gap:
            n = sum(1 for y in range(start, last + 1) if cls[y] not in ('same', 'outside'))
            na = list(dict.fromkeys(e['name'] for y in range(start, last + 1) for e in [a.entry_at(y)] if e))
            nb = list(dict.fromkeys(e['name'] for y in range(start, last + 1) for e in [b.entry_at(y)] if e))
            kinds = sorted({cls[y] for y in range(start, last + 1)} - {'same'})
            out.append((start, last, n, na, nb, kinds))
            start = None
    return out


def draw_map(results, out):
    nrow = (MAP_HI - MAP_LO) // 256
    fig = plt.figure(figsize=(15, 10.5), facecolor=BG)
    width = 0.27
    for i, ((ta, tb), (a, b, rows, cls)) in enumerate(results):
        grid = np.zeros((nrow, 256), dtype=int)
        for x, c in cls.items():
            grid[(x - MAP_LO) // 256, x & 255] = INDEX[c]
        ax = fig.add_axes((0.06 + i * (width + 0.045), 0.16, width, 0.74))
        ax.imshow(grid, cmap=ListedColormap([c for _, _, c in CLASSES]), vmin=0, vmax=len(CLASSES) - 1,
                  aspect='auto', interpolation='nearest', extent=(0, 256, nrow, 0))
        ticks = list(range(0, nrow, 8))
        ax.set_yticks([t + 0.5 for t in ticks])
        ax.set_yticklabels([f'${MAP_LO + 256 * t:04X}' for t in ticks], fontsize=7, color=DIM, family='monospace')
        ax.set_xticks([0, 128, 255])
        ax.set_xticklabels(['+$00', '+$80', '+$FF'], fontsize=7, color=DIM, family='monospace')
        ax.tick_params(colors=DIM)
        for s in ax.spines.values():
            s.set_color(DIM)
        same = sum(1 for x in range(LO, HI) if cls[x] == 'same')
        ax.set_title(f"{D.LABEL[ta]} -> {D.LABEL[tb]}: {same:,} of {HI - LO:,} bytes the same ({same / (HI - LO):.1%})",
                     color=TEXT, fontsize=10, loc='left')
    fig.legend(handles=[Patch(color=c, label=lab) for _, lab, c in CLASSES], loc='lower left', ncol=4,
               frameon=False, labelcolor=TEXT, fontsize=8.5, bbox_to_anchor=(0.05, 0.03))
    fig.suptitle('The three game images byte by byte: the 1987 game at its own addresses in both editions',
                 color=TEXT, fontsize=12, x=0.01, ha='left')
    fig.text(0.01, 0.945, "One cell one byte of $6700-$D8FF, 256 a row; classes from tools/diff_game.py over the "
             "three builds; the '99 with its disk pieces laid in (as before play on 128 K)", color=DIM, fontsize=8.5)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, dpi=100, facecolor=BG)
    print('wrote', out)


def draw_modules(results, out):
    ne = results[0][1][0]
    order = sorted({e['module'] for e in ne.entries if LO <= e['addr'] < HI},
                   key=lambda m: min(e['addr'] for e in ne.entries if e['module'] == m))
    fig, axes = plt.subplots(1, 3, figsize=(15, 8.4), facecolor=BG, sharey=True)
    colours = ['#3d6b47', '#e5534b']
    for i, ((ta, tb), (a, b, rows, cls)) in enumerate(results):
        ax = axes[i]
        ax.set_facecolor(PANEL)
        ax.tick_params(colors=DIM, labelsize=8)
        for s in ax.spines.values():
            s.set_color(DIM)
        for j, m in enumerate(order):
            d = mod_by_ne_range(ne, m, cls)  # NE's ranges on every pair: the '98 and '99 keep NE's addresses
            tot = d['same'] + d['changed']
            if not tot:
                continue
            ax.barh(j, d['same'] / tot * 100, color=colours[0], height=0.7)
            ax.barh(j, d['changed'] / tot * 100, left=d['same'] / tot * 100, color=colours[1], height=0.7)
            ax.text(101, j, f"{d['changed']:,}" if d['changed'] else '-', color=TEXT, fontsize=7.5, va='center')
        ax.set_yticks(range(len(order)))
        ax.set_yticklabels(order, color=TEXT, fontsize=8.5)
        ax.invert_yaxis() if i == 0 else None
        ax.set_xlim(0, 118)
        ax.set_xticks([0, 50, 100])
        ax.set_title(f"{D.LABEL[ta]} -> {D.LABEL[tb]}", color=TEXT, fontsize=10, loc='left')
        ax.set_xlabel("share of the module's bytes the same (green) / changed (red); the number: changed bytes",
                      color=DIM, fontsize=7)
    fig.suptitle("Per NE module (NE's address ranges), over the common block $6780-$D7D2: the play logic is "
                 'untouched; the menu, the level and the font carry the edits', color=TEXT, fontsize=11, x=0.01,
                 ha='left')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    fig.savefig(out, dpi=100, facecolor=BG)
    print('wrote', out)


def mod_by_ne_range(ne, m, cls):
    d = dict(same=0, changed=0)
    for e in ne.entries:
        if e['module'] != m:
            continue
        for x in range(max(e['addr'], LO), min(e['end'], HI)):
            d['same' if cls[x] == 'same' else 'changed'] += 1
    return d


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--map', default=os.path.join(HERE, '..', 'docs', 'img', 'diff', 'memmap-diff.png'))
    p.add_argument('--modules', default=os.path.join(HERE, '..', 'docs', 'img', 'diff', 'modules-diff.png'))
    p.add_argument('--json', default=os.path.join(HERE, '..', 'work', 'diff', 'bytes.json'))
    a = p.parse_args()
    results = [(pair, classify(*pair)) for pair in PAIRS]
    dump = {}
    for (ta, tb), (ca, cb, rows, cls) in results:
        from collections import Counter
        n = Counter(cls[x] for x in range(LO, HI))
        print(f'== {D.LABEL[ta]} -> {D.LABEL[tb]}, ${LO:04X}-${HI - 1:04X}:', dict(sorted(n.items())))
        regs = regions(ca, cb, cls)
        print(f'   {len(regs)} changed regions (gaps under 16 merged)')
        for lo, hi, k, na, nb, kinds in regs:
            print(f"   ${lo:04X}-${hi:04X} {k:4d}  {','.join(kinds):18s} {D.LABEL[ta]}: {' '.join(na)[:70]}  |  "
                  f"{D.LABEL[tb]}: {' '.join(nb)[:70]}")
        dump[f'{ta}:{tb}'] = dict(counts=dict(n), regions=[dict(lo=lo, hi=hi, changed=k, a=na, b=nb, kinds=kinds)
                                                             for lo, hi, k, na, nb, kinds in regs])
    os.makedirs(os.path.dirname(os.path.abspath(a.json)), exist_ok=True)
    json.dump(dump, open(a.json, 'w'), indent=1)
    draw_map(results, a.map)
    draw_modules(results, a.modules)


if __name__ == '__main__':
    main()
