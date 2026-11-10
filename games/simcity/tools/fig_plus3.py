#!/usr/bin/env python3
"""The +3 disk release against the tape (doc 2.8): for every entry of src/game/game.ann, where its first bytes are
found in the disk's game image, as the shift (disk address - tape address) along the tape's address space.

    python3 tools/fig_plus3.py work/stage2/plus3/disk-5A00.bin work/mkgame/original.bin docs/img/arch/plus3-shift.png

disk-5A00.bin is the 82 sectors the boot sector reads to $5A00 (work/stage2/plus3.py); original.bin the tape's
image. An entry is placed when its first 6, 8, 12 or 16 bytes occur exactly once within $800 of its tape address.
"""
import os
import re
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ANN = os.path.join(HERE, '..', 'src', 'game', 'game.ann')
MODULE_RE = re.compile(r'^@module (\w+)')


def entries():
    out, module = [], None
    for line in open(ANN):
        m = MODULE_RE.match(line)
        if m:
            module = m.group(1)
        m = re.match(r'^\$([0-9A-F]{4}) ([a-z]) (\w+)', line)
        if m:
            out.append((int(m.group(1), 16), m.group(2), m.group(3), module))
    return sorted(out)


def main():
    disk = bytes(0x5A00) + open(sys.argv[1], 'rb').read()
    tape = open(sys.argv[2], 'rb').read()
    out = sys.argv[3]
    ents = entries()
    pts = []
    for k, (a, kind, name, module) in enumerate(ents):
        nxt = ents[k + 1][0] if k + 1 < len(ents) else 0xFE00
        for ln in (6, 8, 12, 16):
            if a + ln > nxt:
                break
            pat = tape[a:a + ln]
            near = [m.start() for m in re.finditer(re.escape(pat), disk) if abs(m.start() - a) < 0x800]
            if len(near) == 1:
                pts.append((a, near[0] - a, kind, name))
                break
    plt.rcParams.update({'font.family': 'monospace', 'font.size': 10})
    fig, ax = plt.subplots(figsize=(10.5, 5.2), dpi=100, facecolor='#0e0e14')
    ax.set_facecolor('#181820')
    for kind, colour, label in (('c', '#5ad278', 'code entry'), ('b', '#5aa0ff', 'data entry'),
                                ('w', '#5aa0ff', None), ('t', '#f0c846', 'text entry'), ('s', '#8a8aa0', None)):
        xs = [p[0] for p in pts if p[2] == kind]
        ys = [p[1] for p in pts if p[2] == kind]
        if xs:
            ax.scatter(xs, ys, s=14, color=colour, label=label, zorder=3)
    for a, d, text, off in ((0x5B27, 6, 'Entry $5B27: +6 from here (6 bytes inserted)', (8, 10)),
                            (0xA32F, 403, 'OptionsMenu: +403, the disk menus', (8, 10)),
                            (0xE850, 610, 'IconTiles: +610', (-120, 14)),
                            (0xF70B, 610, 'Interrupt: $F96D on disk', (-100, -28))):
        ax.annotate(text.replace('$', r'\$'), (a, d), xytext=off, textcoords='offset points', color='#d2d2dc',
                    fontsize=10)
    ticks = [0x5B00, 0x6B00, 0x7B86, 0x8F97, 0x9F40, 0xA884, 0xC450, 0xE850, 0xF682, 0xFE00]
    ax.set_xticks(ticks)
    ax.set_xticklabels([f'\\${t:04X}' for t in ticks], color='#d2d2dc', rotation=30)
    ax.tick_params(colors='#d2d2dc')
    ax.set_xlabel('the entry\'s address on tape', color='#d2d2dc')
    ax.set_ylabel('bytes it moved on disk', color='#d2d2dc')
    ax.grid(color='#2c2c3a')
    for s in ax.spines.values():
        s.set_color('#3c3c50')
    ax.legend(facecolor='#181820', edgecolor='#3c3c50', labelcolor='#d2d2dc', loc='upper left')
    ax.set_title(f'The +3 disk image against the tape: {len(pts)} of {len(ents)} entries found, and how far each moved',
                 color='white', fontsize=12, loc='left')
    fig.tight_layout()
    fig.savefig(out, facecolor=fig.get_facecolor())
    print(out, len(pts), 'of', len(ents))
    for a, d, kind, name in pts:
        print(f'${a:04X} {kind} {name:24s} {d:+d}')


if __name__ == '__main__':
    main()
