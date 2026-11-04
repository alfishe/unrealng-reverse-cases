# 02. Architecture and memory map 

Advanced Nether Earth (ANE, Eternity Industry 1998, 128 K, Russian) is Nether Earth (NE, Argus 1987) with its
game image kept at NE's own addresses and new parts added around it: an intro, a boot menu, a help program, AY
music in play from extra pages, a disk save, Russian texts with a Cyrillic font, and two ending sequences ("Dead
End" on a loss, "Final Cut" on a win) loaded from other pages. The game logic is NE's byte for byte
([10](10-gameplay-logic.md)).

## 1. The images

All in `work/images/` (16 K pages `PREFIX-bankN.bin` and the 64 K Z80 view `PREFIX-cpu.bin`):

| Prefix | Medium, moment | Made by |
| --- | --- | --- |
| `scl-intro` | SCL, the intro, recording `s2` frame 5000 | `tools/ttd_dump.py` |
| `scl-menu` | SCL, the game menu, frame 8400 | `tools/ttd_dump.py` |
| `scl-play` | SCL, in play, frame 11500 | `tools/ttd_dump.py` |
| `fc-unpacked` | Final Cut disk, after Hrust 1, recording `c1` frame 2038 | `tools/ttd_dump.py` |
| `fc-end` | Final Cut disk, the end of the sequence, frame 16000 | `tools/ttd_dump.py` |

Live-instance dumps (exploration, not recordings) in `work/stage1/explore/`: `help-bank*` (the help program),
`play-cpu.bin`, `won-bank*` (the Final Cut on the SCL after the `$FD42` poke).

## 2. Memory map in play (SCL, frame 11500)

| Range | Bank | What |
| --- | --- | --- |
| `$4000-$5AFF` | 5 | the screen |
| `$5B00-$677F` | 5 | NE's `ViewBuffer` (3200 bytes; a live buffer, so its bytes differ) |
| `$6780-$697F` | 5 | NE's font place, reused by ANE: the music glue `$67B1`, the IM 2 table `$6800-$6900` (`I=$68`, moved out of `$FE00` because `$C000` is now paged), the disk save `$6905`, the IM 2 `Handler` `$6969` / `$696A` |
| `$6980-$A56A` | 5, 2 | NE's sprites, all 178 entries at NE's addresses |
| `$A5EF` | 2 | ANE's new start (NE's `Start` `$A600` restarts here) |
| `$A600-$BFFF` | 2 | NE's code: start, construction, robot menu, game turn, ship, world, enemy, bases, level |
| `$C000-$D7D2` | 0 | NE's code: main menu (patched: disk load / save, no menu music), view, screen, controls, print, interrupt, tables; the menu tune `$C4A0-$C848` replaced (ANE's font at `$C400`, Cyrillic glyphs from `$C500`) |
| `$D7D3-$DB80` | 0 | NE's world state |
| `$DD00-$FCDA` | 0 | NE's map and the robot / building tables (`EnemyBuildings` `$FD42`) |
| bank 1 | | the PT3 player (`$C005`) and the play music |
| bank 3 | | "Dead End" (loss), entered at `$D2EF` |
| bank 6 | | "Final Cut" (win), HRUM-packed, unpacks to `$6060-$F76C` |
| banks 4, 7 | | further loaded blocks (to follow in stage 2) |

## 3. What is NE's: the match

`tools/ne_match.py` takes every entry of NE's `game.ann` (563 entries, the extents to the next entry), masks the
absolute operands in code (`$4000-$FFFF`) and address-like words in word tables, and looks for it in ANE's images.
Run on the play image (Z80 view) plus banks 1, 3, 4, 6, 7 at `$C000`:

```text
python3 tools/ne_match.py --image work/images/scl-play-cpu.bin@0000:play \
  --image work/images/scl-play-bank{1,3,4,6,7}.bin@C000:bN --out work/stage1/match.tsv --summary
```

| Status | Entries | Bytes |
| --- | ---: | ---: |
| same (NE's bytes at NE's address) | 427 | 24054 |
| moved | 4 | 8 |
| relocated (same bytes outside masked operands) | 7 | 433 |
| changed (best placement, similarity) | 14 | 4028 |
| fill (NE's padding, not compared) | 12 | 9786 |
| absent | 99 | 3140 |
| total | 563 | 41449 |

Per module: sprites 178 same; world 36, bases 17, enemy 3, tables 6, level 16, controls 4, ship 2, robot menu 3
all same; game turn 17 same + the end of game changed; construction 31 same, the texts absent (translated);
main menu 34 same, its texts absent, `LoadGameBlocks` / `SaveGameBlocks` / `MainMenuKeys` changed; the menu
music 52 of 72 absent (replaced); font absent (`$6780` -> `$C400`, Cyrillic); `PlayInterrupt` changed (one `JP`).
The "relocated" entries are at NE's address with another operand (`Handler`, the restart address, the font base),
not moved. `DrawSprite` and `FillViewCorner` show as changed only through their self-modified operands.

Assets: sprites same (all 178); NE's font replaced; the map and world state are run-time data (`fill`); NE's menu
tune replaced by PT3 music in bank 1. The routines and tables of the game logic: [10](10-gameplay-logic.md).

Self-check: the same tool on NE's own image gives 551 same + 12 fill.

## 4. The Final Cut disk

The 2017 disk's image matches none of NE's code (493 of 563 entries absent, the rest short runs): it is ANE's
Final Cut block only, the same bytes as the SCL's (`docs/03-build-and-load.md` 3).
