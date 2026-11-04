# Nether Earth: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

Seven tapes on the shelf (WDC14Tb-3 `Consoles/ZX Spectrum/Games/Nether Earth`, the ZX-Uno card's TOSEC set). The
TOSEC one named "(Argus Press Software)" turned out to be a crack: its BASIC is a REM with "CRACKED BY BILL
GILBERT'87" and the game is one 42240-byte block (`kit/tapblocks.py list`). The World of Spectrum TZX
(`NETHEART.TZX` in `NetherEarth_ZXt.zip`) and the Mind Games España TAP are the same five standard blocks byte for
byte: that is the master, `orig/NETHER.TZX` and `orig/NETHER.TAP`.

```text
  0  header Program "N.EARTH" length 381 LINE 0 vars 381
  1  381 bytes   the BASIC: a line whose length word says 65535 (LIST shows nothing), LOAD "" CODE 64730, RANDOMIZE USR 64730
  2  header Bytes "N1" length 180 start 63800 ($F938), loaded at 64730 ($FCDA) instead
  3  180 bytes   N1 at $FCDA-$FD8D: a relocated ROM LD-BYTES, its edge routines at $FD69 / $FD6D
  4  48361 bytes the game, headerless: $4000-$FCE8, the screen included; entry $A600 (pushed as N1's return)
total 264.7 s at ROM speed (13258 48K frames)
```

The other copies (Leshij, AGAS, Mihal Soft, VS'93, Ziberov Oleg, Nikiforov, Voronin/Prokofiev, the Presto
compilation, the HGFX/esxDOS port) are Russian rereleases and ports: none is the original.

## 1. One recording from power-on

**Used:** `re_session.py capture --record-load` at ROM speed (no LD-BYTES trap), 48K, a Kempston card.

The first capture played seeded random keys after the load and picked "5..LOAD SAVED GAME": "LOADING ERROR!" and a
"PRESS RECORD AND PLAY" save prompt filled the run, so the recording was dropped (`work/load`, kept for the load
alone). The second (`work/play`, 16514 frames: the load to frame 12660, the menu, 3754 frames of play) plays
`tests/inputs/kempston-play.txt`: 2 (Kempston), 0 (start), then seeded moves and fire. It reaches the game: the
ship flies round the base, the clock runs into day 1 (`work/play/screens.png`). The play is shallow (no robot
built, no fight): a second recording with a bot is the next one doc 10 needs.

`re_session.py stages` on the first recording:

| Stage | Entry | Frame | What |
| --- | --- | --- | --- |
| 0 | `$FCDA` | 253 | N1, entered by the BASIC's USR 64730 (written by the ROM's LD-BYTES `$0802`: loaded at `$FCDA`, not at the header's `$F938`) |
| 1 | `$A600` | 12660 | the game, entered by N1's RET to the pushed `$A600` after the 48361-byte block; the block's last 15 bytes (`$FCDA-$FCE8`) land over N1's own start, code that has already run (its store is `$FD3B`, past them) |

**Interrupts** (`re_session.py interrupts`, `explain`): the start-up `$A600` fills the IM 2 table `$FE00-$FF00`
with `$FD` and puts `JP` at `$FDFD`; the handler is whatever that jump names. `$D59C` while the start-up runs (37
entries), `$C4FD` in the menu (144), `$D566` in play (3672: one a frame). The ROM `$0038` (171) runs only during the
load. `re_session.py stages` lists `$FDFD`, `$D59C`, `$C199`, `$D566` as stages: they are those handler swaps and the
menu, not new code (no block arrives after the load: every write the stages name is N1's store `$FD3B`).

## 2. Static pass over the medium

**The block's screen part.** The game block starts at `$4000`, so its first 6912 bytes load into the screen: noise,
with zero attributes, black on black, while the tape plays. An access trace of the start-up (`analysis trace`,
frames 12660-12900, 1.8 M instructions) shows every one of those bytes written first, by the screen clear at
`$D0C5` / `$D0C7`, and never read before: they are dead. They are not random either: `$4000-$5AFF` is the game's
own `$C350-$DE4F`, byte for byte (a mastering leftover: the save started 6912 bytes early, or the screen held a copy
of the code). The source keeps them as that copy: `tools/build.sh` prefixes the assembled `$5B00-$FCE8` with its own
`$C350-$DE4F`, nothing is typed twice.

**The first cut.** `kit/mkgame.py` on `case.json` (`lo` `$5B00`, the `work/game` build of the play recording from
frame 12661): 10378 code bytes (5954 instructions, 3117 of them ran), 254 entries, assembled identical to the image.
`src/basic.asm` and `src/loader.asm` are written by hand from the blocks; `tools/build.sh` gives `orig/NETHER.TAP`
byte for byte.

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

## 7. Review
