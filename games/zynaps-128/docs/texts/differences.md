# Zynaps 2 in 1 against the 48K original: the texts that differ

Side by side, every text a player meets that is not the same in Zynaps 2 in 1 (goodboy and tiboh, 2018, the TRD on a
Pentagon 128) and in the 48K original (Hewson, 1987). All texts on both sides are English.

The 48K side is the tape `work/ref48/ZYNAPS.TAP` (a copy of `R/games/zynaps/orig/ZYNAPS.TAP`: a 1993 re-tape by
"DRJ" of the Hewson game, whose code block is byte-identical to the Hewson TZX's, see the 48K case), recorded from
power-on on a 48K as `work/stage2/compare/r48/session.ttd`; the game texts also from its code block
`work/ref48/game48-6801.bin`. The 128K side: `work/stage1/c1/session.ttd` and `work/stage2/compare/k128/session.ttd`.
The figures in [`../img/compare/`](../img/compare/) show each moment from both recordings.

## How it was checked

- The game: a byte compare of the 48K code block (`$6801`-`$FFFE`) with the 128K memory at the game's entry
  (`work/images/game-entry-cpu.bin`): 392 bytes differ (151 before the 128K glue is written, stage 1), and in the
  text area (`$8188`-`$8520`) only two runs: the key table `$8188`-`$8191` and the credit `$8484`-`$848F`.
  `tools/game_text.py` over both images gives the same table except that line.
- The screens: `tools/fig_compare.py` measures each pair of matching screens cell by cell; the high-score page and
  PREPARE FOR COMBAT are byte-identical, the credits page differs only in row 17, the keyboard definition only in the
  five key names.

## The texts that differ

| Where | 48K original (Hewson 1987) | Zynaps 2 in 1 (2018) | Figure |
| --- | --- | --- | --- |
| power-on | `© 1982 Sinclair Research Ltd` (48 BASIC ROM), `LOAD ""` | the 128 menu (`Tape Loader` ... `TR-DOS`), `* TR-DOS Ver 5.04T*`, `RUN` ([boot.md](boot.md)) | [01](../img/compare/01-power-on.png) |
| the medium's names | tape blocks `Zynaps` (BASIC), `zynaps0.c`, `zynaps1.c` | disk label `ZYNAPS`, files `ZYNAPS.B`, `boot.B` | [02](../img/compare/02-load.png) |
| the loader's list | none | boot.B's framed list: `ZYNAPS` / `ZYNAPS` / `boot` | [02](../img/compare/02-load.png) |
| the first picture | the Hewson picture: `ZYNAPS`, `By Dominic Robinson`, `Jmp`, `HEWSON` (the loading screen) | the new title picture: `ZYNAPS`, `RVS.M.STAWICKI©` | [03](../img/compare/03-title.png) |
| the options screen | none (the game menu comes straight after the load) | `WITH AY` / `48/128K  MUSIC & SFX` / `1987 (C) HEWSON` / `2018 (R) GOODBOY&TIBOH` / `CONTROL IN THE GAME MENU` / `1&2 SELECT 1 OR 2 PLAYER` / `3 REDEFINE KEYS` / `4 HIGH SCORE` / `FIRE START GAME` / `0.START  1.INF.LIVES  2.K-MOUSE` ([intro.md](intro.md)) | [04](../img/compare/04-options.png) |
| the Hewson picture | the loading screen | the intro's third picture: the same texts (no text differs) | [05](../img/compare/05-hewson-picture.png) |
| credits, row 17 (`$8484`) | `STEVE TURNER` | `DAVE ROGERS ` | [08](../img/compare/08-credits.png) |
| keyboard definition, the default keys (key table `$8188`) | FIRE `P`, UP `L`, DOWN `SS`, LEFT `A`, RIGHT `S` | FIRE `SP`, UP `Q`, DOWN `A`, LEFT `O`, RIGHT `P` | [06](../img/compare/06-keyboard-definition.png) |
| the tape's BASIC (never shown on screen) | line 1 `REM Zynaps. DRJ 3/12/93 1824`; line 50 `REM Collect icon to advance power-up; hold fire and collect to activate` | none (the REMs of `ZYNAPS.B` and `boot.B` hold machine code) | |

The key table and the screen it is shown on: the defaults are not printed anywhere until the keys are typed on the
KEYBOARD DEFINITION screen; both recordings typed their own defaults there, and the table read back unchanged
afterwards (48K frames 11000 and 11900, 128K `k128` frames 3500 and 4000).

## The same on both sides

The game's other texts are byte-identical at the same addresses ([game.md](game.md)): KEYBOARD  DEFINITION, FIRE,
UP, DOWN, LEFT, RIGHT, the 40 key names, SELECTIONS, 1 PLAYER, 2  PLAYERS, BY, DOMINIC ROBINSON, GRAPHICS, STEVE
CROW, MUSIC, COPYRIGHT, HEWSON 1987, PLAYER n, PREPARE FOR COMBAT, ROLE OF HONOUR, UNRANKED, ENTER YOUR INITIALS,
and the high-score table (EGO 68000, DFR 25000, BAV 10000, HNR 5000, BMR 1000).
