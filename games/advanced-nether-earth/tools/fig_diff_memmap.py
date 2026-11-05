#!/usr/bin/env python3
"""The two game images byte by byte: what Advanced Nether Earth kept of Nether Earth's, what it changed, what is
new (docs/img/diff/memmap-diff.png and docs/img/diff/modules-diff.png, work/diff/code.md).

    python3 tools/fig_diff_memmap.py [--map PNG] [--modules PNG]

The classes come from tools/diff_game.py (both builds, entry by entry, label operands masked). One cell of the map is
one byte of the CPU's view, $5B00-$FFFF, 256 bytes a row:

  same        the same byte at the same address in both images
  operand     an absolute operand that points at a moved thing (diff_game: operands / retargeted)
  code        a changed byte inside a routine both games have
  text        a changed byte inside a text both games have (the Russian strings)
  new         ANE code or data where NE had something else (NE's entry gone)
  free        ANE bytes nothing uses (the entries ANE's game.ann names *Spare: zero, or an old string's tail)
  runtime     NE's image holds it, ANE's block does not: the same variables at the same addresses, built at run time
"""

import argparse
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

CLASSES = [('none', 'outside both images', '#0e0e14'),
           ('same', 'the same byte at the same address', '#3d6b47'),
           ('operand', 'an address operand that follows a moved thing', '#f2e86d'),
           ('code', 'a changed byte in a routine both have', '#e5534b'),
           ('text', 'a changed byte in a text both have (Russian)', '#e8913a'),
           ('new', 'new in ANE, where NE had other code or data', '#26c6da'),
           ('free', 'free in ANE (zero spares)', '#5a5d6a'),
           ('runtime', 'NE\'s image only: ANE builds it at run time, same addresses', '#2b3550')]
INDEX = {k: i for i, (k, _, _) in enumerate(CLASSES)}
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'


def classify():
    ne, ane = D.Case('NE'), D.Case('ANE')
    rows = D.compare(ne, ane)
    cls = {}
    for a in range(0x5B00, 0x10000):
        if a in ane.mem and a in ne.mem:
            cls[a] = 'same' if ane.mem[a] == ne.mem[a] else 'code'
        elif a in ne.mem:
            cls[a] = 'runtime'
        else:
            cls[a] = 'none'
    for r in rows:
        e, x = r['ne'], r['ane']
        if r['status'] in ('operands', 'retargeted', 'changed') and e['addr'] == x['addr']:
            text = e['kind'] == 't' or x['kind'] == 't'
            for k in range(max(e['size'], x['size'])):
                a = e['addr'] + k
                if a in ane.mem and a in ne.mem and ane.mem[a] != ne.mem[a]:
                    cls[a] = 'operand' if r['status'] != 'changed' else ('text' if text else 'code')
        elif r['status'] == 'changed':          # Start / Restart: moved by 17 bytes
            for k in range(x['size']):
                a = x['addr'] + k
                if ane.mem[a] != ne.mem.get(a):
                    cls[a] = 'code'
        if r['status'] == 'ane-only':
            spare = 'Spare' in x['name']
            for k in range(x['size']):
                a = x['addr'] + k
                if ane.mem[a] != ne.mem.get(a):
                    cls[a] = 'free' if spare else 'new'
    # an NE text entry rewritten wholly by an ANE code entry (the lost / won texts under the endings)
    return ne, ane, rows, cls


REGIONS = [  # (address, label) for the map's notes, each checked against the classes in the text
    (0x5B00, 'NE ViewBuffer $5B00-$677F: in ANE not loaded (79 tail bytes, same)'),
    (0x6780, 'NE Font $6780 -> ANE music glue, IM 2 table $6800, GameSave $6905, ImJump $6969'),
    (0x6980, 'sprites $6980-$A569: same, byte for byte'),
    (0xA56A, 'NE free $A56A -> ANE GameLoad, GlueStack, GameEntry; Start -> Restart $A5EF'),
    (0xA738, 'robot menu texts in Russian'),
    (0xAE6B, 'CheckGameEnd: the endings'),
    (0xC103, 'main menu: picture, tape load / save dead, texts'),
    (0xC4A7, 'NE menu tune $C4A7-$C848 -> ANE font $C500 + free'),
    (0xC8BE, 'construction texts'),
    (0xD1C5, 'status panel texts'),
    (0xD566, 'PlayInterrupt: JP PlayMusic'),
    (0xD7D3, 'NE shots, radar, robots, map: ANE builds them'),
]


def draw_map(cls, out):
    grid = np.zeros(((0x10000 - 0x5B00) // 256, 256), dtype=int)
    for a, c in cls.items():
        grid[(a - 0x5B00) // 256, a & 255] = INDEX[c]
    fig = plt.figure(figsize=(13, 9.6), facecolor=BG)
    ax = fig.add_axes((0.11, 0.12, 0.47, 0.8))
    ax.imshow(grid, cmap=ListedColormap([c for _, _, c in CLASSES]), vmin=0, vmax=len(CLASSES) - 1,
              aspect='auto', interpolation='nearest', extent=(0, 256, grid.shape[0], 0))
    ticks = list(range(0, grid.shape[0], 8))
    ax.set_yticks([t + 0.5 for t in ticks])
    ax.set_yticklabels([f'${0x5B00 + 256 * t:04X}' for t in ticks], fontsize=7, color=DIM, family='monospace')
    ax.set_xticks([0, 64, 128, 192, 255])
    ax.set_xticklabels(['+$00', '+$40', '+$80', '+$C0', '+$FF'], fontsize=7, color=DIM, family='monospace')
    ax.tick_params(colors=DIM)
    for s in ax.spines.values():
        s.set_color(DIM)
    ax.axhline((0x6731 - 0x5B00) / 256, color='white', lw=0.6, ls=':')
    ax.axhline((0xD7D8 - 0x5B00) / 256, color='white', lw=0.6, ls=':')
    y_used = []
    for addr, label in REGIONS:
        y = (addr - 0x5B00) / 256 + 0.5
        ly = max([y] + [u + 3.2 for u in y_used])
        y_used.append(ly)
        ax.annotate(label, ((addr & 255) + 0.5, y), xytext=(262, ly), textcoords='data', fontsize=8, color=TEXT,
                    va='center', annotation_clip=False,
                    arrowprops=dict(arrowstyle='-', color=DIM, lw=0.6, shrinkA=0, shrinkB=0))
    ax.text(-2, (0x6731 - 0x5B00) / 256, 'ANE block $6731 ', color='white', fontsize=7, ha='right', va='bottom')
    ax.text(-2, (0xD7D8 - 0x5B00) / 256, 'ANE block end $D7D7 ', color='white', fontsize=7, ha='right',
            va='top')
    from collections import Counter
    n = Counter(c for a, c in cls.items() if 0x6731 <= a < 0xD7D8)
    total = sum(n.values())
    fig.legend(handles=[Patch(color=c, label=f'{lab}: {n[k]:,} bytes of the block' if k in n and k != 'runtime'
                              else lab) for k, lab, c in CLASSES[1:]],
               loc='lower left', ncol=2, frameon=False, labelcolor=TEXT, fontsize=8, bbox_to_anchor=(0.06, 0.0))
    same = n['same'] / total
    fig.suptitle(f'ANE\'s game block is NE\'s image at NE\'s addresses: {same:.1%} of its {total:,} bytes are the '
                 'same bytes', color=TEXT, fontsize=11, x=0.01, ha='left')
    fig.text(0.01, 0.945, 'One cell one byte of the Z80\'s view in play, 256 a row; classes from tools/diff_game.py '
             'over both builds', color=DIM, fontsize=8)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, dpi=100, facecolor=BG)
    print('wrote', out, dict(n))


MOD_PARTS = [('same', 'the same bytes', '#3d6b47'), ('operand', 'operands that follow a move', '#f2e86d'),
             ('code', 'changed code', '#e5534b'), ('text', 'changed text', '#e8913a'),
             ('gone', 'gone (removed or replaced)', '#9c4dcc'), ('runtime', 'not in ANE\'s block (built)', '#2b3550')]


def draw_modules(ne, ane, rows, out):
    per = {}
    for r in rows:
        e, x = r['ne'], r['ane']
        if not e:
            continue
        d = per.setdefault(e['module'], dict.fromkeys([k for k, _, _ in MOD_PARTS], 0))
        st = r['status']
        if st == 'same':
            d['same'] += e['size']
        elif st in ('operands', 'retargeted'):
            d['operand'] += r['diff']
            d['same'] += e['size'] - r['diff']
        elif st == 'changed':
            same = sum(1 for k in range(min(e['size'], x['size']))
                       if e['addr'] == x['addr'] and e['raw'][k] == x['raw'][k])
            d['same'] += same
            d['text' if e['kind'] == 't' else 'code'] += e['size'] - same
        elif st == 'runtime':
            d['runtime'] += e['size']
        else:
            d['gone'] += e['size']
    new = {}
    for r in rows:
        if r['status'] == 'ane-only':
            x = r['ane']
            if all(ne.mem.get(x['addr'] + k) == x['raw'][k] for k in range(x['size'])):
                continue  # NE's own bytes under another entry (ViewBufferTail)
            spare = 'Spare' in x['name']
            k = 'free' if spare else 'new'
            new.setdefault(x['module'], {'new': 0, 'free': 0})[k] += x['size']
    order = sorted(per, key=lambda m: min(e['addr'] for e in ne.entries if e['module'] == m))
    fig, (ax, bx) = plt.subplots(1, 2, figsize=(13, 7.4), facecolor=BG, gridspec_kw=dict(width_ratios=[3, 1.3]))
    for axis in (ax, bx):
        axis.set_facecolor(PANEL)
        axis.tick_params(colors=DIM, labelsize=8)
        for s in axis.spines.values():
            s.set_color(DIM)
    for i, m in enumerate(order):
        d = per[m]
        tot = sum(d.values())
        left = 0
        for k, lab, c in MOD_PARTS:
            if d[k]:
                ax.barh(i, d[k] / tot * 100, left=left, color=c, height=0.7, label=lab)
                left += d[k] / tot * 100
        changed = d['code'] + d['text'] + d['operand'] + d['gone']
        note = 'same' if not changed and not d['runtime'] else (
            f'{changed:,} differ' if not d['runtime'] else 'built at run time')
        ax.text(101, i, f'{tot:,} B, {note}', color=TEXT, fontsize=7.5, va='center')
    ax.set_yticks(range(len(order)))
    ax.set_yticklabels(order, color=TEXT, fontsize=8.5)
    ax.invert_yaxis()
    ax.set_xlim(0, 135)
    ax.set_xticks([0, 25, 50, 75, 100])
    ax.set_xlabel('share of the NE module\'s bytes (NE\'s modules in address order)', color=DIM, fontsize=8)
    ax.set_title('NE\'s 22 modules in ANE', color=TEXT, fontsize=10, loc='left')
    seen, handles = set(), []
    for h, lab in zip(*ax.get_legend_handles_labels()):
        if lab not in seen:
            seen.add(lab)
            handles.append(h)
    ax.legend(handles=handles, loc='upper center', bbox_to_anchor=(0.45, -0.07), ncol=3, frameon=False,
              labelcolor=TEXT, fontsize=7.5)
    names = sorted(new, key=lambda m: -(new[m]['new'] + new[m]['free']))
    for i, m in enumerate(names):
        bx.barh(i, new[m]['new'], color='#26c6da', height=0.7, label='new code / data')
        bx.barh(i, new[m]['free'], left=new[m]['new'], color='#5a5d6a', height=0.7, label='free (zero)')
        bx.text(new[m]['new'] + new[m]['free'] + 8, i, f"{new[m]['new']} + {new[m]['free']}", color=TEXT,
                fontsize=7.5, va='center')
    bx.set_yticks(range(len(names)))
    bx.set_yticklabels(names, color=TEXT, fontsize=8.5)
    bx.invert_yaxis()
    bx.set_xlim(0, max(v['new'] + v['free'] for v in new.values()) * 1.35)
    bx.set_xlabel('bytes', color=DIM, fontsize=8)
    bx.set_title('ANE-only entries, by ANE module', color=TEXT, fontsize=10, loc='left')
    seen, handles = set(), []
    for h, lab in zip(*bx.get_legend_handles_labels()):
        if lab not in seen:
            seen.add(lab)
            handles.append(h)
    bx.legend(handles=handles, loc='lower right', frameon=False, labelcolor=TEXT, fontsize=7.5)
    fig.suptitle('The game logic is untouched: ship, world, enemy, bases, level, view, controls, tables are the same '
                 'bytes', color=TEXT, fontsize=11, x=0.01, ha='left')
    fig.tight_layout(rect=(0, 0.02, 1, 0.95))
    fig.savefig(out, dpi=100, facecolor=BG)
    print('wrote', out)
    for m in order:
        print(f'  {m:13s}', per[m])
    for m in names:
        print(f'  ANE {m:9s}', new[m])


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--map', default=os.path.join(HERE, '..', 'docs', 'img', 'diff', 'memmap-diff.png'))
    p.add_argument('--modules', default=os.path.join(HERE, '..', 'docs', 'img', 'diff', 'modules-diff.png'))
    a = p.parse_args()
    ne, ane, rows, cls = classify()
    draw_map(cls, a.map)
    draw_modules(ne, ane, rows, a.modules)


if __name__ == '__main__':
    main()
