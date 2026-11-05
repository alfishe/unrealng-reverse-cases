# 2. Architecture

What this covers: the machine budget, the memory map of the Spectrum and of the card, and the stages from the disk to
play. The images it rests on are in `work/images/` (stage 1):

- `options-menu/`: the menu, after the boot;
- `play-music-gs512/`: level 1 in music mode on a 512 KB card;
- `play-fx-gs512/`: level 1 in effects-only mode on a 512 KB card;
- `play-music-gs128/` and `play-fx-gs128/`: the same on a 128 KB card.

Each holds the 8 RAM pages, the 64 K view and the card's RAM (`work/stage1/NOTES.md`).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the memory map (`kit/heatmap.py`, regions) -->
<!-- - the stages from power-on to play (mermaid) -->
<!-- - the card's memory (module, FX, the 128 KB half page) -->

## 2.1 The machine

The game needs a 128K Spectrum (it was run on a Pentagon 128) with TR-DOS and a General Sound card. Paging uses
`$7FFD` only (pages `$10`..`$17`: bank 0..7, ROM 1, the normal screen). The game is Hewson's 48K Zynaps (1987), run
in bank 0 at its own addresses. The GS version adds:

- the driver and the start jingle in bank 1;
- in-game effects in banks 3, 4 and 6;
- bank 7 as the screen copy during the load, and as the buffer for unpacking the level records.

The card runs its ROM firmware and plays the modules and samples it is given: 15 RAM pages on 512 KB, 3 on 128 KB.

## 2.2 The memory map in play

| Range | Bank | Contents |
| --- | --- | --- |
| `$4000-$5AFF` | 5 | the screen |
| `$5B00-$5D3A` | 5 | GS stub code at `$5B00` (`$23B` bytes, swapped with bank 1 `$D190` during a level load); the system variables up to `$5CFF` |
| `$5C00-$73FF` | 5, 2 | Zynaps's first 6 K, moved here from `$C800` by the installer |
| `$61A8-$65C0` | 5, 2 | Zynaps code; during a level load it is swapped with the level loader (bank 1 `$C44A`, `$419` bytes) |
| `$7400-$BFFF` | 2 | Zynaps as loaded, with the patched call sites ([9.4](09-sound.md#94-where-the-game-makes-a-sound)), the stubs `$A6AE`, `$AA28`, `$B2F0`, the trampolines `$B446-$B4A7`, and the GS flags `$B45F-$B486` |
| `$BE00-$BFFF` | 2 | saved to bank 1 `$CF90` during a level load (the loader's stack `$BED3` and the unpack heads at `$BED4`) |
| `$C000-$FF1B` | 0 | Zynaps |
| `$FF1C-$FFD1` | 0 | the 20 sound and level stubs |

The GS flags:

| Flag | Meaning |
| --- | --- |
| `$B45F` | the FX volume |
| `$B460` | the module volume of this level |
| `$B461` | the level whose sound is loaded |
| `$B462` | the next level |
| `$B463` | the load kind: 0 level, 1 game start, 2 title |
| `$B464` | enables SaturnSound (`$C095`) |
| `$B465` | `$C1DF`'s two bits |
| `$B486` | 0 music, 1 effects only |

The other banks:

| Bank | Range | Contents |
| --- | --- | --- |
| 1 | `$C000-$CFFF` | the GS driver file (from blk04 `$64B3`): entries `$C010..$C21D`, the core `$C22A-$C2F1`, the card control `$C2F3-$C384`, the level change `$C385`, the loader copy `$C44A`, the menu texts at `$CC00..` |
| 1 | `$CF90-$D18F` | the save of `$BE00` |
| 1 | `$D190-$D3CA` | the save of `$5B00` |
| 1 | `$D3CB-$FAA4` | the start jingle (9946 bytes) |
| 1 | `$FAA5-$FFFF` | FX 1, the start of FX 2 |
| 3 | `$C000-$FFFF` | the rest of FX 2, FX 3-4, the start of FX 5 (raw from the disk) |
| 4 | `$C000-$FFFF` | the rest of FX 5, FX 6-7, the start of FX 8 (from blk02) |
| 6 | `$C000-$FFFF` | the rest of FX 8, FX 9-10 (from blk03) |
| 7 | `$C000-$DAFF` | the loading screen, shown during the boot |
| 7 | `$C000-$FFFF` | the unpack buffer of the level records |

FX 10's last 7 bytes are read from bank 7 `$C000`, which holds zeros at that time.

## 2.3 The card's memory

The firmware loads in order into the sample pages, which start at card RAM `$08000`. On 512 KB:

- music mode: the module at `$08000`, then the 10 FX;
- effects-only mode: the title module at `$08000` (it stays), then the jingle at `$14900`, then the 21 FX. The title
  module is stopped (`#32`) at the game start.

On 128 KB the firmware's pages are 2, 3 and 4 (card RAM `$08000-$1FFFF`) and then the lower half of page 1
(`$00000-$03FFF`), whose upper half is its own work memory: 112 K in all, enough for every load
([9.5](09-sound.md#95-card-sizes)).

## 2.4 From the disk to play

1. TR-DOS loads the BASIC line. Its code reads the boot code over it ([3.1](03-build-and-load.md#31-the-medium)).
2. The boot reads and unpacks the loading screen, then banks 1, 3, 4 and 6, then blk04
   ([3.3](03-build-and-load.md#33-the-boot)).
3. The boot runs the options menu in place inside blk04 (`$6D60`, [5.1](05-controls.md#51-the-options-menu)). Up to
   this point nothing has been sent to the card.
4. Key 1 or 2 writes the options and goes on to blk04's installer, which copies the stubs and the driver, patches
   Zynaps, moves `$C800` → `$5C00` and starts Zynaps at `$B200` ([3.5](03-build-and-load.md#35-the-patch-installer)).
5. The title loop's first call loads the title module.
6. The title loop (the credits page, the high scores, the loading screen) waits for "1,2,3 & FIRE": key 1 or 2
   picks one or two players ("SELECTIONS"), 3 the key definition, and fire starts the game (the Kempston's fire
   selects the Kempston).
7. The game start plays the jingle. Each round's "PREPARE FOR COMBAT" goes through the level change, which loads the
   level's sound when the level changed ([9.2](09-sound.md#92-the-driver-bank-1-c000)).

The main loop and the frame: [4](04-game-loop.md). The module map of the source: `src/game/game.asm` (50 modules from
`src/game/game.ann`) and `src/disk/*/`; every routine: [12](12-routine-reference.md).
