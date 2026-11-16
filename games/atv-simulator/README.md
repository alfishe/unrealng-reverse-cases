# ATV Simulator (Code Masters, 1987)

State: in progress (stage 1, 2026-11-16).

| | |
| --- | --- |
| Machine | 48K (ZXDB machine type "ZX-Spectrum 48K"): one tape, one load, no level loads. The image as the loader leaves it has no AY port write (no `LD BC,$FFFD` or `$BFFD` outside the screen bytes) and no paging (`$7FFD`): beeper only, the same on a 128K |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 9306: Tim Miller, James Wilson, David Whittaker (music), Nigel Fletcher (inlay and poster art). The game's own title screen (recording c1, frame 14 640): "GAME DESIGN AND CREATION TIM MILLER", "MUSIC BY DAVID WHITTAKER", "PUBLISHED BY CODE MASTERS LTD". The Oliver twins are not credited on this game, neither in ZXDB nor on its screens |
| Release | ZXDB 9306: ATV Simulator (alias All Terrain Vehicle Simulator), Code Masters Ltd, 1987, £1.99; ZXDB genre "Simulation", two players. Re-releases: EDOS, Serma Software (Spain, 1987, 550 ptas); in the compilations Quattro Power, Quattro Power Vol. 5, Quattro Racers, The CD Games Pack, Christmas Megapack, Mega-Hot and Poke City; on the covertape Load 'n' Run 46 as "Dune Buggy". ZXDB denies the distribution of the tape file (`/denied/entries/0009306/ATVSimulator.tzx.zip`, 25 525 bytes, md5 `8569b2a27f39c9ce029c0bfd37ccca4f`) |
| Original | `orig/ATVSimulator.tzx.zip` (25 601 bytes, md5 `3bf1d87bbaa288c2b81e2d9888a45770`, SHA-1 `f23c81b4d38b96c164482f586bd3d094d3e2d040`; the World of Spectrum file of ZXDB's release 0, from the collection's mirror; its zip is not ZXDB's (another size), the collection index names both as the same tape): `ATV Simulator.tzx` (47 124 bytes, md5 `ca7bb7957f69915fc965e81d49eb99a4`, SHA-1 `2846b7833e811716c5e12e4607391b4def90426e`; byte for byte TOSEC 2023-09 "ATV Simulator (1987)(Code Masters)[a].tzx" and zxart's "[p 1987 Code Masters Ltd].tzx"): eight standard-speed ROM blocks, a BASIC loader, a 34-byte machine-code loader and two headerless loads ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |
| Recorded from | the original TZX at ROM speed (recording c1). The case's unreal-ng binary (`e3d341d38`) lacks commit f13cee7da (an ended tape holds its last edge); this tape loads all the same: the game takes over at frame 14 114, the tape stops at 14 182 |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Profile

Stage 1, a first look; each row names its witness.

| Row (AGENTS.md 4.0) | ATV Simulator |
| --- | --- |
| Genre | a side-view off-road race against the clock on an all-terrain quad bike: six trails one after the other; one or two players; two ride the same trail at once on a split screen, player 1 above, player 2 below (the menu's ONE PLAYER / TWO PLAYERS; recording kb) ([WALKTHROUGH 6](WALKTHROUGH.md#6-the-game)) |
| The courses and the track | six trails: 1 SAND DUNING, 2 GRASSTRAKIN, 3 ICEBERGS, 4 PYRAMIDS, 5 TROPICANA, 6 SWAMP; each a course record (trails 1-4 at `$7C9C` + 6 n, trail 5 at `$EE84`, trail 6 at `$60AC`) with a length of `$690`, `$568`, `$5D4`, `$685`, `$6B5` and `$69B` distance units, and two lists: the objects and a second list along the distance ([doc 2, 2.3](docs/02-architecture.md#23-a-first-map-of-the-trails)) |
| The vehicle and its handling | the rider walks to the ATV and jumps on with fire; right accelerates, left slows, up and down the front wheel, fire jumps; an obstacle met wrongly throws the rider off: he walks back to the ATV and jumps on again ([WALKTHROUGH 6](WALKTHROUGH.md#6-the-game)) |
| Rivals and obstacles | no computer rival; in a two-player game the other player on the other half of the screen; obstacles per trail (trail 1: tyre walls and humps; the bot's first crashes at distances 876 and 1 268), a crash throws the rider off (recordings trail1, trails) |
| Timer and score | a clock in tenths, one tenth a game pass (7 frames), against a maximum per trail (60, 60, 60, 40, 50, 50; 30 once the six trails come round again); TIME OUT ends the game; a trail's finish shows EXTENDED PLAY and the LAP TIME; a score per player and a high-score table of five (HOT 20000 down to BUDDY 03000) with a name entry on a letter grid (recordings kb, warp) |
| Rendering | a scrolling side view of the trail above a HUD of SPEED and FUEL bars, the clock, the trail's name and two score panels |
| Engine | IM 2 (`I` = `$FE`, vector `$8080` to the handler `$D9D2`; the title tune's own vector `$FDFD` to `$F961`); a game pass of exactly 7 frames (a wait on the frame counter `$D6BC`) ([WALKTHROUGH 1](WALKTHROUGH.md#1-one-recording-from-power-on)) |
| Sound | David Whittaker's title tune on the beeper (played from `$F852`); the engine and effects on the beeper (to be mapped) |
| Controls | per player: player 1 KEYBOARD or KEMPSTON (the default), player 2 KEYBOARD or SINCLAIR; each keyboard redefinable on its table (player 1 S D F C Z, player 2 H J K M B: left, right, wheel up, wheel down, jump) (recording menu) |

## Other releases and copies

Each copy found is kept unchanged in `work/candidates/<source>/` (git-ignored). The blocks were compared byte for
byte with `tools/media_compare.py` against the original.

| Copy | Source | What differs |
| --- | --- | --- |
| `ATV Simulator (1987)(Code Masters).tzx` (md5 `8ff1487b…`) | TOSEC 2023-09 | the same BASIC, loader, screen and code; no headers before the screen and the code (the loader never reads them), other pauses |
| `ATV Simulator (1987)(Code Masters)[a2].tzx` and the `.tap` | TOSEC 2023-09 | the BASIC header says LINE 0 (one byte); the same data; no headers before the screen and the code |
| `[h Raf].tap` | TOSEC 2023-09 | a 2 148-byte BASIC ("RAF'90") in place of the loader; the same screen and code |
| `(EN)[p].tap` | zxart | a 103-byte BASIC, a 4 039-byte block `ATV.$` at 40000 and the code with 6 bytes changed (`$6338`, the text at `$696B-$696E`, `$DFE6` = `$C9`, `$EB5A` = `$00`: the ZXDB POKEs patched in) |
| eight `[h ...].scl` | TOSEC 2023-09 | TR-DOS conversions (Cleopatra '91, Vitaly System, Immortal Boneman '95, Integral '97, VAD '98, AmoNik / Welcome '00, Glen, Phantom, Tagilsoft '94, Popushin): not used |
| four `.z80` (one "(128K)"), the owner's `ATV_Simulator_1988_Codemasters.dsk` | TOSEC, the owner's archive | snapshots and a +3 disk: not used |
| `ATVSimulator.pok`, `ATVSimulator.txt`, three maps (`ATVSimulator.jpg`, `_2.png`, `_3.jpg`, Ladderman 2005) | ZXDB | the POKEs, the instructions (the inlay text of the C64 version), the trail maps |
| `David Whittaker - ATV Simulator (1987).ay` | the collection's AY rips | the title tune as an AY file |
