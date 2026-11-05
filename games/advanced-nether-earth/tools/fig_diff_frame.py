#!/usr/bin/env python3
"""What the frame interrupt does in Nether Earth and in Advanced Nether Earth: the call graph of each handler, the
same code, changed code and new code apart (docs/img/diff/interrupt-graph.png, work/diff/code.md).

    python3 tools/fig_diff_frame.py [--out PNG]

The graph is read from both builds' listings, not typed: every box names an entry and its address, and the script
checks each address against the entry table of tools/diff_game.py and takes the box's colour from its status there
(same / operands / changed / ane-only). The edges are the CALL / JP of the handlers, as in the listings (NE
build/game.lst, ANE build/game/game.lst); the script checks that each edge's instruction is at the address given.
"""

import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import FancyBboxPatch, Patch  # noqa: E402

plt.rcParams['text.parse_math'] = False  # hex addresses: $ is not math

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import diff_game as D  # noqa: E402

BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'
COLOUR = {'same': '#3d6b47', 'changed': '#b8433b', 'new': '#1f8f9c', 'gone': '#7b3fa0', 'hw': '#3a3f55'}

# (game, key, x, y, entry address or None, text). x, y in axes units of the game's panel.
BOXES = [
    ('NE', 'irq', 0.5, 0.95, None, 'the frame interrupt (IM 2, I = $FE)\nvector from $FE00-$FF00 = $FDFD'),
    ('NE', 'jp', 0.5, 0.83, None, 'JP (Handler): $FDFD-$FDFF\nset at run time, outside the image'),
    ('NE', 'play', 0.27, 0.68, 0xD566, 'PlayInterrupt $D566\nTurnFrames + 1, radar phase'),
    ('NE', 'radar', 0.27, 0.50, 0xD59E, 'ShowRadar $D59E\n16 radar lines'),
    ('NE', 'sound', 0.27, 0.34, 0xD5C4, 'SoundEffect $D5C4\nthe shot sound (when SoundFx)'),
    ('NE', 'end', 0.27, 0.19, 0xD59C, 'EI; RET $D59C'),
    ('NE', 'idle', 0.83, 0.68, 0xD59C, 'StartInterrupt $D59C (EI; RET)\nmain menu, construction menu:\nnothing runs'),
    ('NE', 'menu', 0.74, 0.42, 0xC4FD, 'MenuInterrupt $C4FD\nthe beeper title tune\n(only while MenuMusic loops)'),
    ('ANE', 'irq', 0.5, 0.95, None, 'the frame interrupt (IM 2, I = $68)\nvector from ImTable $6800-$6900 = $6969'),
    ('ANE', 'jp', 0.5, 0.83, 0x6969, 'ImJump $6969: JP (ImHandler $696A)\nbelow $C000: no bank covers it'),
    ('ANE', 'play', 0.27, 0.68, 0xD566, 'PlayInterrupt $D566\n$D582: JP PlayMusic (was CALL ShowRadar)'),
    ('ANE', 'pm', 0.27, 0.55, 0x67B1, 'PlayMusic $67B1\nCALL ShowRadar, page bank 1'),
    ('ANE', 'radar', 0.08, 0.42, 0xD59E, 'ShowRadar $D59E'),
    ('ANE', 'pf', 0.45, 0.42, None, 'PlayerFrame bank 1 $C005\none frame of the AY tune'),
    ('ANE', 'back', 0.27, 0.30, 0x67C6, 'page GameBank, JP $D585'),
    ('ANE', 'sound', 0.27, 0.19, 0xD5C4, 'SoundEffect $D5C4 (when SoundFx)'),
    ('ANE', 'end', 0.27, 0.08, 0xD59C, 'EI; RET $D59C'),
    ('ANE', 'idle', 0.83, 0.66, 0x6780, 'MusicInterrupt $6780\nmain menu, construction menu:\npage bank 1, PlayerFrame,\npage GameBank back'),
    ('ANE', 'pf2', 0.83, 0.30, None, 'PlayerFrame bank 1 $C005'),
]
EDGES = [  # (game, from, to, label, (address of the instruction, its text in the listing) or None)
    ('NE', 'irq', 'jp', '', None), ('NE', 'jp', 'play', 'in play', None), ('NE', 'jp', 'idle', 'menus', None),
    ('NE', 'jp', 'menu', 'title tune', None),
    ('NE', 'play', 'radar', 'CALL', (0xD582, 'CALL ShowRadar')),
    ('NE', 'radar', 'sound', 'RET, CALL NZ', (0xD595, 'CALL NZ,SoundEffect')), ('NE', 'sound', 'end', '', None),
    ('ANE', 'irq', 'jp', '', None), ('ANE', 'jp', 'play', 'in play', None), ('ANE', 'jp', 'idle', 'menus', None),
    ('ANE', 'play', 'pm', 'JP', (0xD582, 'JP PlayMusic')), ('ANE', 'pm', 'radar', 'CALL', (0x67B1, 'CALL ShowRadar')),
    ('ANE', 'pm', 'pf', 'CALL', (0x67C3, 'CALL PlayerFrame')), ('ANE', 'pf', 'back', '', None),
    ('ANE', 'back', 'sound', 'JP, CALL NZ', (0x67D6, 'JP InterruptSound')), ('ANE', 'sound', 'end', '', None),
    ('ANE', 'idle', 'pf2', 'CALL', (0x6796, 'CALL PlayerFrame')),
]


def check(cases, rows):
    status = {}
    for r in rows:
        for side, game in (('ne', 'NE'), ('ane', 'ANE')):
            x = r[side]
            if x:
                status[(game, x['addr'])] = r['status']
    out = {}
    for game, key, x, y, addr, text in BOXES:
        if addr is None:
            out[(game, key)] = 'hw' if key in ('irq', 'jp') else 'new'
            continue
        case = cases[game]
        e = case.entry_at(addr)
        assert e, (game, hex(addr))
        st = status.get((game, e['addr']))
        if key == 'play':
            st = 'changed' if game == 'ANE' else 'same'   # the one changed instruction at $D582
        out[(game, key)] = {'same': 'same', 'operands': 'same', 'ane-only': 'new', 'ne-only': 'gone'}.get(st, 'changed')
        if game == 'NE' and st == 'same':
            out[(game, key)] = 'same'
    for game, a, b, label, ins in EDGES:
        if ins:
            case = cases[game]
            it = next((i for i in case.items if i['addr'] == ins[0]), None)
            assert it and D.strip_comment(it['text'])[0] == ins[1], (game, hex(ins[0]), it and it['text'])
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', default=os.path.join(HERE, '..', 'docs', 'img', 'diff', 'interrupt-graph.png'))
    a = p.parse_args()
    cases = {'NE': D.Case('NE'), 'ANE': D.Case('ANE')}
    rows = D.compare(cases['NE'], cases['ANE'])
    colour = check(cases, rows)
    fig, axes = plt.subplots(1, 2, figsize=(13, 7.2), facecolor=BG)
    pos = {}
    for ax, game in zip(axes, ('NE', 'ANE')):
        ax.set_facecolor(PANEL)
        ax.set_xlim(-0.06, 1.1)
        ax.set_ylim(0, 1.02)
        ax.set_xticks([])
        ax.set_yticks([])
        for s in ax.spines.values():
            s.set_color(DIM)
        ax.set_title({'NE': 'Nether Earth (1987)', 'ANE': 'Advanced Nether Earth (1998)'}[game], color=TEXT,
                     fontsize=10, loc='left')
        for g, key, x, y, addr, text in BOXES:
            if g != game:
                continue
            w = 0.42 if key not in ('radar',) or game == 'NE' else 0.24
            h = 0.03 + 0.033 * text.count('\n')
            ax.add_patch(FancyBboxPatch((x - w / 2, y - h / 2), w, h, boxstyle='round,pad=0.012',
                                        fc=COLOUR[colour[(game, key)]], ec='#cfd2dc', lw=0.6))
            ax.text(x, y, text, color='white', fontsize=7, ha='center', va='center', family='monospace')
            pos[(game, key)] = (x, y, h)
        for g, src, dst, label, ins in EDGES:
            if g != game:
                continue
            x0, y0, h0 = pos[(g, src)]
            x1, y1, h1 = pos[(g, dst)]
            ax.annotate('', (x1, y1 + h1 / 2 + 0.012), (x0, y0 - h0 / 2 - 0.012),
                        arrowprops=dict(arrowstyle='->', color='#cfd2dc', lw=0.9))
            if label:
                ax.text((x0 + x1) / 2 + 0.01, (y0 - h0 / 2 + y1 + h1 / 2) / 2, label, color=DIM, fontsize=7)
    fig.legend(handles=[Patch(color=COLOUR['same'], label='the same bytes as NE'),
                        Patch(color=COLOUR['changed'], label='changed'),
                        Patch(color=COLOUR['gone'], label='gone in ANE'),
                        Patch(color=COLOUR['new'], label='new in ANE (or a bank the NE image does not have)'),
                        Patch(color=COLOUR['hw'], label='the CPU and the IM 2 table')],
               loc='lower center', ncol=5, frameon=False, labelcolor=TEXT, fontsize=8)
    fig.suptitle('One instruction turns NE\'s play interrupt into ANE\'s: $D582 CALL ShowRadar becomes JP PlayMusic',
                 color=TEXT, fontsize=11, x=0.01, ha='left')
    fig.tight_layout(rect=(0, 0.05, 1, 0.95))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=100, facecolor=BG)
    print('wrote', a.out)


if __name__ == '__main__':
    main()
