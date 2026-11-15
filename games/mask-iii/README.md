# MASK III: VENOM Strikes Back (Gremlin Graphics, 1988)

State: in progress (stage 1, 2026-11-15).

| | |
| --- | --- |
| Machine | 48K and 128K from one tape (ZXDB machine type "ZX-Spectrum 48K/128K"). The loader tests for the 128K (it writes a byte in RAM 0, pages RAM 4 through `$7FFD` and checks the two apart) and on a 128K loads one more block, the AY music and its player, into RAM 4 at `$C000`; the flag `$FFFE` (0 on a 128K) picks the AY player or the beeper in the interrupt handler ([doc 3, 3.3](docs/03-build-and-load.md#33-the-loader)). This case runs the 128K |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 3045: Colin Dooley (code), Marco Duroe (graphics), Ben Daglish (music), Ian Naylor (inlay); the menu credits "PROGRAM FUNGUS", "GRAPHICS MARCOS DUROE", "MUSIC BENN" |
| Release | ZXDB 3045: MASK III: VENOM Strikes Back, Gremlin Graphics Software Ltd, 1988, £7.99; re-releases IBSA and Erbe Software ("Serie Leyenda", Spain), the compilation Space Ace (Gremlin, 1989) and Erbe's +3 disk "2 Por 1" with Northstar. Genre in ZXDB "Arcade Game: Platform" |
| Original | `orig/MASKIII-VENOMStrikesBack.tzx.zip` (md5 `a3e2ca1d5031d3e244972c32cb0fa737`, SHA-1 `c7863f5386ceeb72b5cc7ba2b1ac10752f1db3c6`; ZXDB `pub/sinclair/games/m/MASKIII-VENOMStrikesBack.tzx.zip`, the Gremlin release, a Ramsoft dump): `Mask III.tzx` (51 775 bytes, md5 `558163ec2f9b32b86f1d00e1378a1481`, SHA-1 `beb94c095027c0e2df39fcc5cc86873df8b19406`): a BASIC "MASK3", a 256-byte loader at `$FF00`, the screen, the code (40 448 bytes at `$6000`) and the 128K block (4000 bytes), all standard ROM blocks ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Profile

From stage 1 play and the recordings ([WALKTHROUGH 6](WALKTHROUGH.md#6-the-game)); each row is to be confirmed by the
documents.

| Row (AGENTS.md 4.0) | MASK III |
| --- | --- |
| Genre | a flick-screen arcade platform shooter for one player: Matt Trakker walks, jumps and shoots through 16 rooms of six screens each in four zones (the green surface, the magenta caverns, the moon, the cyan base), linked by teleport pods; the game ends in room 15 with "YOU HAVE FOUND SCOTT"; one energy bar, a game ends with MISSION TERMINATED ([WALKTHROUGH 6](WALKTHROUGH.md#6-the-game), [doc 2, 2.5](docs/02-architecture.md#25-the-rooms-as-data-the-first-map)) |
| Weapons and pick-ups | four MASK slots switched by the keys 1-4, each mask with a counter; ten mask icons in the graphics (P, VE, M, H, JR, L, B, BL, LS, S); BACKLASH, JACKRABBIT, BLASTER, LIFTER, PENETRATOR seen; masks lie in the rooms |
| Enemies and bosses | the instructions name Deathsphere, Blockbuster, Angel of Death and Serpent; robots, guns and fliers seen in the screens |
| Map | the room table at `$953B` (exits left, right and by pod; the zone), the room maps at `$7600` (48 x 5 blocks a room), the blocks at `$8500`, four zone character sets swapped through `$E000` |
| Sound | Ben Daglish's AY music in RAM 4 on a 128K (`$C000` start tune, `$C00A` second entry, `$C003` play each frame), the beeper on a 48K, both from the interrupt |
| Engine | IM 2 through a `$FF` table at `$FE00` and a `JR` at `$FFFF` landing on `JP $9226`; the handler runs the music and part of the game each frame |
| Controls | menu: 1 KEMPSTON, 2 INTERFACE 2, 3 CURSOR, 4 KEYBOARD, K DEFINE KEYS (fire, up, down, left, right), P ENTER PASSWORD, FIRE START GAME; play: 1-4 masks, H pause, Q abort (instructions) |

## Other releases and copies

Every copy the collection index lists (`index/zx-image-locations.tsv`, the regex in `tools/fetch_copies.py`) was
fetched unchanged into `work/candidates/<source>/` (55 copies, SHA-256 checked, `work/stage1/fetch-copies.txt`) and
compared block by block with the original and with the IBSA dump (`tools/media_compare.py`,
`work/stage1/copy-compare.txt`). There are two builds of the game:

- **Build A** (the original here): BASIC "MASK3" `CLEAR 24570: LOAD ""CODE: RANDOMIZE USR 65280`; the code block md5
  `2281f690ea020272d9552d3ce41169ed`, the 128K block md5 `a110a2b07a80945ddddaca724c9b5a02`. ZXDB's four POKEs
  (`$CC1E`, `$C315`, `$B220`, `$B3DD`) fit this build, and the ZXDB AY rip holds the 128K block byte for byte.
- **Build B** (IBSA and Erbe): BASIC "VENOM" with `VAL` strings and `9999 SAVE "VENOM" LINE SIN PI: LOAD "MASTER"`;
  the code differs from build A in 13 991 bytes from offset 3042 (`$6BE2`, a shift of the code after it), the 128K
  block in 101 bytes from offset 3083.

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| TOSEC 2020 "Space Ace ... (Side B).tzx" and its `[m tzxtools].tap` | the Space Ace compilation (Gremlin, 1989) | screen, code and 128K block byte for byte (build A) |
| ZXDB `MASKIII-VENOMStrikesBack128.tap.zip` (`MASK3128.TAP`); TOSEC "(128K).tzx" and "(128K)[cr].tap" | a 128K crack "Venom SB" | the code and the 128K block byte for byte (build A); another loader and BASIC |
| zxart "[h]", "[h Bill Gilbert]", "[h Andrzej Staszewski]" TAPs; "Andrey Anoshkin" TAP | hacked loaders | screen and code byte for byte (build A); "[h]" and Anoshkin also the 128K block |
| ZXDB `MASKIII-VENOMStrikesBack(IBSA).tzx.zip`, TOSEC "(48K-128K).tzx", ZXDB "Erbe - Serie Leyenda" TZX | the IBSA / Erbe re-release | build B |
| ZXDB `MASKIII-VENOMStrikesBack48.tap.zip` (`MASK3.TAP`), TOSEC "[a2].tap" | a 48K TAP | build B without the 128K block |
| ZXDB `MASKIII-VENOMStrikesBack.dsk.zip`, "2 Por 1" disks | +3 disks | another layout (99 of 158 pieces of the code found) |
| TR-DOS SCL/TRD conversions (zxart, VTRD, TOSEC "[h Universal Company '94]"), TOSEC MDR and `$b`/`$c` files, LESHIJ TZX | conversions and hacks | most hold build A's code (the JK Soft SCL all 158 pieces); a few are translations or GS-music hacks |

The ZXDB documents (instructions, maps) are not in the local collection; the instructions were read on ZXDB's page.

## Build

The source is written in stage 2.
