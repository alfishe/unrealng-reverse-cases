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

## 7. Stage 2: the boot followed statically, the byte-exact build

- **A static machine instead of recordings.** `tools/ane_sim.py` runs the boot on SkoolKit's simulator with
  128 K paging, the 128 and TR-DOS ROMs and a WD1793 model reading the SCL; keys are scripted. It logs each sector
  read, each `$7FFD` write and each HRUM depack, and writes every depacked image. From `RUN "A_NETHER"` to
  `GameEntry` takes 15 s. The first try (traps on the TR-DOS entry) failed: UltraXOR reads the disk through ROM
  gadgets, not through `$3D13`, so the real ROM and a controller model were needed.
- **The disk map.** Every sector of the SCL has a known reader and destination ([03](docs/03-build-and-load.md)
  4.1). The game block is split: 16384 bytes in bank 4, its last 914 bytes in bank 3 between Dead End and the music.
- **HRUM 3.5.** The depacker was read instruction by instruction and written in Python (`tools/hrum.py`): it gives
  the simulator's output exactly. The packer was then guessed: greedy, longest match, nearest offset on ties. It gives
  all 13 streams byte for byte.
- **The game from NE's source.** NE's build gives NE's image; `tools/mkpatch.py` lists ANE's changes (90 runs);
  `src/game/ane-patches.asm` writes them as named code with reasons and the texts with their letters. One bug found
  on the way: `GameStop` writes `$6D6A` instead of `$696A`, harmless because nothing calls it any more.
- **The tunes** were found in the zxart.ee collection by the name inside the module ([07](docs/07-sound.md)). This
  also corrected stage 1: the play music's player is Phantom Family's SoundTrack player, not the PT3 one.
- **The build.** `tools/build.sh`: NE, the patches, the font from PNG, the blocks (inner ones first), the loader,
  the disk from `src/disk.txt`. The SCL is identical to the original.

## 8. Review

- **Not run:** the Dead End sequence, the disk save and load, the help program's every page in a recording (it was
  read from a live instance). Stage 2 ran no emulator: the paths are from the code and the static boot.
- **Kept as bytes:** UltraXOR (polymorphic layers), the intro, "Presents", the scroller, the boot program, bank 7,
  the two music banks, Dead End, the disk module, Final Cut (`src/res/img/`), `nether.N`.
- **Open:** the PT3 player against Pro Tracker 3.x sources; the code of the programs above.
