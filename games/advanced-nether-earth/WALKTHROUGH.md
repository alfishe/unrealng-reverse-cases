# Advanced Nether Earth: how the reverse was done

The case came after [Nether Earth](../nether-earth/WALKTHROUGH.md) and its [editor](../nether-earth-editor/WALKTHROUGH.md)
were finished: every name below is Nether Earth's (NE). One agent did stage 1 on 2026-11-04 (about 40 minutes);
its command log, with what each command proved, is `work/stage1/NOTES.md` (local).

## 0. The media

The owner's `anefc.zip` holds a TR-DOS disk "Advanced Nether Earth Final Cut". The local collection had an earlier
release too: the TOSEC SCL of 1998 (4 files). Both went to `orig/`.

## 1. The machine and the load

**Used:** `kit/re_session.py capture` (an own instance, muted, Pentagon 128 + TR-DOS 5.04T) from power-on, then
`re_session.py stages` on each recording.

- The Final Cut disk does not autostart; it boots from the 128 menu into TR-DOS with `RUN`. Its BASIC reads 55
  sectors to `$61A8`, a Hrust 1 depacker at `$FE4C` unpacks `$6060-$F76C`, and the Final Cut sequence plays. No game.
- The SCL boots with `RUN "A_NETHER"`: an UltraXOR v1.2 protection, a loader at `$6161`, blocks packed with
  HRUM 3.5, the intro, the boot menu; key 1 loads the game, which starts by frame 7452.
- Details: [3](docs/03-build-and-load.md).

## 2. The images and the memory map

**Used:** `tools/ttd_dump.py` on the recordings: all eight pages and the Z80 view at the intro, the menu and in play.
The map of which page holds what is [2](docs/02-architecture.md).

## 3. What is Nether Earth's

**Used:** `tools/ne_match.py`: NE's bytes (`../nether-earth/work/mkgame/original.bin`) cut by the entries of NE's
`game.ann` and the instruction boundaries of NE's listing, absolute operands masked so a relocated routine still
matches. Self-check on NE's own image: 551 same + 12 fill of 563.

- ANE in play: 427 same, 4 moved, 7 relocated, 14 changed, 12 fill, 99 absent. The absent ones are the texts (now
  Russian), the font and the menu tune. All 178 sprites are the same.
- `tools/entry_diff.py` shows the changed entries instruction by instruction.
- A plain byte diff of NE's code range `$A600-$D7D2` lists every changed byte. All of them fall in the start, the
  menu, the save and load, the menu tune, the game end, the interrupt and the print routines. The three in the view
  code are self-modified operands.
- So the gameplay answer, [10](docs/10-gameplay-logic.md): the logic is unchanged.

## 4. The claims

The authors' texts (`NETHER+.W` on the SCL, the intro scroller, the help program) were decoded
(`tools/help_text.py`, CP866) into `src/res/text/` and each claim was checked against the code:
[12](docs/12-claims.md).

## 5. The SCL against the Final Cut disk

A live SCL instance with `EnemyBuildings` (`$FD42`) poked to 0 wins at once and plays its Final Cut. Its memory
equals the Final Cut disk's unpacked image: `$8000-$BFFF` and `$C000-$F76C` in full, `$6060-$7FFF` but 4 bytes.

## 6. Tool gaps

| Gap | State |
| --- | --- |
| the kit's key names `SS` / `CS` become `symbol_shift` / `caps_shift`, which `type_input` rejects | open; the input scripts use `ss` / `cs` |

## 7. Review

- **Not run:** the Dead End sequence, the disk save and load, the help program's every page in a recording (it was
  read from a live instance).
- **Not yet known:** banks 4 and 7, the `$7FFD` writes of every stage, the file `nether.N`.
