# Chuckie Egg (A'n'F Software, 1983)

State: docs written, in review. The tape rebuilt byte for byte from the annotated source and `src/res`; docs 01-12
(12 documents, 102 figures, 37 animations, 12 WAVs, 61 mermaid diagrams), counted with
`ls docs/[0-9][0-9]-*.md | wc -l; for e in png gif wav; do find docs/img -name "*.$e" | wc -l; done; grep -h '^```mermaid' docs/*.md | wc -l`.

| | |
| --- | --- |
| Machine | 48K |
| Profile (AGENTS.md 4.0) | arcade, platform: one screen per level, eight level maps of 32 x 21 cells in the image (`$B3B0`, 672 bytes each), copied to a live map per player, the levels repeating with changes; sprites over a character background: DrawSprite rewrites Harry's whole 24 x 16 box with the background ORed with the frame, so a one-pixel move needs no erase (his frames have a blank border), the duck is erased with the blank frame 12 first, the hens are ORed without a background and erased by redrawing their map cells, the lifts erased and drawn a line up (doc 6.5); the hens and the duck flicker where the beam reads between erase and redraw (doc 6.10); a free-running main loop paced by its own counters, not by the frame (WALKTHROUGH 1.1), with an IM 2 interrupt (`$9C9C`) that only feeds a table of 33 phrases to an SP0256-type phrase chip on port `$9F` (the Fuller Orator's SP0256-AL2, which unreal-ng does not model; doc 9); the beeper by the game's own toggle loop (`$9CA4`) and tunes through the ROM's calculator and BEEP (`$AB60`: the title tune, the end of a life); a two-byte tape block loaded into ERR_SP that the main loop needs to be exactly 1 (a protection); no packer, no cipher, no turbo loader (doc 3); a crash bug in HenEatGrain `$9265`: a left peck that touches Harry makes the kill return into ROM `$0100` / `$0101` and the Spectrum resets (shown on a clone, doc 10.8); a difficulty cycle on the Level byte: the eight maps repeat, no hens on levels 9-16 and the duck free from 9, five hens from 25, faster hens from 33, 1000-point eggs from 37, less time every 16 levels to 400 from 81 (doc 10.13) |
| Authors | Nigel Alderton (the title page: "BY N.ALDERTON"; ZXDB 958) |
| Release | ZXDB 958, release 0: A'n'F Software 1983, £6.90. `orig/ChuckieEgg.tzx.zip` is ZXDB download 6194, which ZXDB marks "Original release": a BASIC program whose variables area holds a machine-code loader and the loading picture, then two headerless ROM-speed blocks (two bytes to ERR_SP `$5C3D`, the game's 18 900 bytes to `$8214`) |
| Original | `orig/ChuckieEgg.tzx.zip` (md5 `55706f7dc4ddb4f171705f21794732df`, SHA-1 `fc11317d8c0ebbc79105169d618f01d47ae3ebf7`): `Chuckie Egg.tzx` (md5 `08804f90e4a45aaa8180cc1338248033`, SHA-1 `03be8e55eb56ca49856b236f38bf81b76f4e57bf`), "Created with Ramsoft MakeTZX" |

## Other releases and copies

Each was compared with the original block by block (`tools/tzxblocks.py`, `kit/tapblocks.py`, `cmp`; WALKTHROUGH 0).
None of them is the case's source.

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| `ChuckieEgg(PickChoose).tzx.zip` (ZXDB 958 release 1, Pick & Choose 1984; md5 `862e88bb1e91b8357979bab817906f90`; zxart 96201) | the budget re-release | the same four data blocks byte for byte; no text block, other pauses (0 ms after the game) |
| `ChuckieEgg.tap.zip` (ZXDB download 6195, release 0, scheme "undetermined"; md5 `07b5263bc2bfbb4b1e1a03cb09b0041a`; zxart 96200) | a TAP conversion | the same two headerless blocks; the BASIC block is 1640 bytes, not 1624: no variables (VARS at the end), 16 bytes appended (`DI; XOR A; OUT ($FE),A; CALL $028E; INC E; JR Z,...; JP $A410`: a wait for a key) and the loader's `JP $A410` at `$5FC1` turned into `JP $6324` to run them |
| `433872/Chuckie Egg.tap` (zxart) | a tape copy | the same BASIC; the two-byte block is 88 bytes long (`01 00`, then `FE`, a valid parity byte for a two-byte load, then 85 bytes the load never reads); the game block differs in one byte, `$8A6F` = `$DF` (original `$FF`), inside graphics data |
| `433873/Chuckie Egg.tap` (zxart) | a re-saved crack | a 313-byte BASIC "CHUCKY EGG" and two headed blocks, "CH_EGG.1" (2552 bytes at 40000) and "CH_EGG.2" (15 706 bytes at 25000) |
| `433874/Chuckie Egg.tap` (zxart) | a Russian translation | the same BASIC; a 67-byte two-byte block (`01 00 FE ...`); the game block is 18 921 bytes and differs in 1483 bytes: the instructions and menu texts in transliterated Russian ("INCTRUKZI%", "zel^ igry - cobrat^ vce &iza"), a redrawn font |
| `CHUCKIE.ZIP` (zxart 245160): `CHUCKRUS.SCL` | a TR-DOS conversion (Russian) | a BASIC "CHUCKrus" and the game as a file of 18 900 bytes at 33300 (`$8214`) |
| `CHUCKEGT.zip`, `CHUCKIE_.ZIP`, `CHUCKPHL.zip` (zxart 253517-253519): one-file SCLs | TR-DOS conversions | one BASIC file each, of 63, 66 and 44 sectors, fewer than the 74 sectors of the game alone: the game is packed inside |

ZXDB also lists an RZX of a full play, a game map and an AY rip of the music; none of them is in the local
collection.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/ChuckieEgg.tap and compares it with the original's blocks 1-4 (build/orig.tap) byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`); the loader blocks are `src/loader/*.asm`, from `src/loader/loader.ann` and `errsp.ann`.
