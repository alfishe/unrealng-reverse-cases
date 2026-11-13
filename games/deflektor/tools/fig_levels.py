#!/usr/bin/env python3
"""The level contact sheets of doc 01: every level slot drawn by the game's own BuildLevel $891A from
src/res/levels/levels.txt (tools/level_maps.py's simulator run), labelled with its number, its address, its cells and
its LevelSettings $8385 pair (the energy rate in frames a bar step, the gremlin count).

    python3 tools/fig_levels.py docs/img/maps [--table work/docs/dfA/levels-table.md]

Writes levels-01-20.png, levels-21-40.png, levels-41-60.png and levels-practice.png (slots 60-63: P1-P3 and the slot
the game never sets up), 1050 px wide, and with --table a markdown table of every slot's contents.
"""
import argparse
import os

import figlib


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--table')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    img = figlib.image()
    items, rows = [], []
    for slot in range(64):
        pic, _ = figlib.play_area(img, slot)
        codes = figlib.level_bytes(img, slot)
        k = figlib.counts(codes)
        rate, grem = figlib.settings(img, slot)
        name = f'Level {slot + 1}' if slot < 60 else (f'Practice P{slot - 59}' if slot < 63 else 'Slot 63 (never set up)')
        addr = 0xB000 + 0x87 * slot
        items.append((pic, [f'{name}  ${addr:04X}',
                            f"{k['cells']} cells, rate {rate}, {grem} gremlins"]))
        rows.append((name, addr, k, rate, grem))
    groups = [('levels-01-20.png', 0, 20), ('levels-21-40.png', 20, 40), ('levels-41-60.png', 40, 60),
              ('levels-practice.png', 60, 64)]
    for fname, lo, hi in groups:
        title = (f'Levels {lo + 1}-{hi}: LevelData $B000 + $87 x slot, drawn by BuildLevel $891A' if lo < 60 else
                 'Slots 60-63: the practice levels P1-P3 and slot 63, drawn by BuildLevel $891A')
        sh = figlib.sheet(items[lo:hi], 4, 256, 160, title=title, label_h=38, gap=6,
                          notes=['Turning elements at their first angle; no beam, no cursor (they come in play).',
                                 'rate: frames a step of the 64-step energy bar (LevelSettings $8385 byte 0).'])
        sh.save(os.path.join(a.out, fname))
        print(os.path.join(a.out, fname), sh.size)
    if a.table:
        with open(a.table, 'w') as f:
            f.write('| Level | Address | Cells | Mirrors | Turning | Cyan / yellow polarisers | Absorbing / reflecting '
                    'walls | Mines | Prisms | Fibre ends | Energy rate | Gremlins |\n')
            f.write('| --- | --- | ---: | ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |\n')
            for name, addr, k, rate, grem in rows:
                f.write(f"| {name} | `${addr:04X}` | {k['cells']} | {k['mirrors']} | {k['turning']} | "
                        f"{k['cyan']} / {k['yellow']} | {k['absorbing']} / {k['reflecting']} | {k['mines']} | "
                        f"{k['prisms']} | {k['fibres']} | {rate} | {grem} |\n")
        print(a.table)


if __name__ == '__main__':
    main()
