# Bumpy (Loriciels, 1989)

State: docs written, in review (2026-11-14): docs 01-10 by one writer, docs 11 and 12 generated, the tape builds
identical from the sources. 12 documents, 82 figures (PNG), 19 animations (GIF), 61 mermaid diagrams and 15 audio
files (15 short WAV, no MP3; 588 KB), counted on 2026-11-14 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs -name '*.mp3' | wc -l; find docs -name '*.wav' | wc -l; du -sh docs/img/sound
```

| | |
| --- | --- |
| Machine | 48K (ZXDB 763: ZX-Spectrum 48K). The game is one 38 700-byte block at `$61A8-$F8D3`, run by `RANDOMIZE USR 43900` (`$AB7C`); beeper only (port `$FE`); the AY register writer and two IM 2 set-ups at `$F183-$F3C7` are never called, so the 48K and the 128K play alike ([doc 2, 2.8](docs/02-architecture.md#28-the-leftovers)) |
| Profile (AGENTS.md 4.0) | a single-screen arcade puzzle for one or two players ([doc 1](docs/01-game-design.md)): Bumpy, a ball that never stops bouncing, is steered only at its landings; 100 levels (Level `$AB00`; level 99 wraps to 0 with everything kept), each a board of 6 x 6 cells from a 75-byte record (LevelRecords `$8C3C`, [doc 2, 2.5](docs/02-architecture.md#25-the-levels-as-data), [doc 7](docs/07-objects.md)); 12 platform types (plain, three crumbling, stopper, two conveyors, two burning, bricks, the exit, spikes), locks lowered by keys and fixed walls, and objects: hammers, keys, water drops, the bottle (an extra life) and 36 prize kinds of 15 points; the last prize opens the exit; a timer of 1000 passes that kills nobody and whose rest is the bonus; 2 spare lives, no enemies, five ways to die (spikes landed on or risen into, fire without water, the fall off the bottom row, the S key; [doc 10](docs/10-gameplay-logic.md)); the ball's nine states and five fixed move tables ([doc 10, 10.1](docs/10-gameplay-logic.md#101-the-ball-nine-states-and-five-fixed-moves)); MainLoop `$ACC8`, one ball step a pass, HALT-paced, 1.28 frames a pass on average ([doc 4](docs/04-game-loop.md)); the Amstrad CPC's mode-1 pictures and screen addresses drawn on the Spectrum one plane a pixel ([doc 6](docs/06-rendering.md)); 14 beeper effects, each followed by an AY register image no code reads ([doc 9](docs/09-sound.md)); a HUD row, a hall of fame of four with a name entry ([doc 8](docs/08-hud-and-text.md)); keyboard Q A O P SPACE, Sinclair 9 8 6 7 0, Kempston on port `$DF`; H pause, R quit, S self-destruct, the cheat R + SPACE + V, the demo after 3000 idle frames ([doc 5](docs/05-controls.md)); a standard ROM tape, no packer ([doc 3](docs/03-build-and-load.md)) |
| Authors | Spectrum conversion: Luis Jorge Garcia and J250 (ZXDB 763; the loading screen "CONVERSION SPECTRUM LUIS JORGE GARCIA Y J250", the menu "VERSIONED BY J250 (SPAIN)"); the original game by Loriciels |
| Release | ZXDB 763: Bumpy, Arcade Game: Platform, up to 2 players; release 0 Loriciels 1989, release 1 Proein Soft Line 1989 (Spain, TZX and +3 disk). The Proein tape's archive info: "BUMPY; LORICIELS / PROEIN SOFT LINE; SPECTRUM CONVERSION: LUIS JORGE GARCIA Y J250; 1989; ENGLISH; M-39542-1989" |
| Original | `orig/Bumpy.tap.zip` (md5 `da242969086de41598b7a3c8510d1e16`, SHA-1 `94cf909e4fd5f739c6b5c61aa78c18cc0cee8191`; ZXDB `pub/sinclair/games/b/Bumpy.tap.zip`, the Loriciels release): `BUMPY.TAP` (45 878 bytes, md5 `e4b397939057962033b57fef8ca3154c`, SHA-1 `351e52eba4097bd094a181f7395d5ec32ea45c85`), six standard-speed blocks: a Program header "BUMPY" and its 191-byte BASIC, "BUMPY.SCR" (6912 bytes, the loading screen) and "BUMPY.CDE" (38 700 bytes at `$61A8`) ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)); the zip also holds `SCRSHOT/BUMPY.SCR` (the same 6912 bytes as the screen block) and `POKES/BUMPY.POK` |

## Other releases and copies

Every copy the collection index lists (`index/zx-image-locations.tsv`: zxart, the TOSEC 2012, 2020 and MDR packs,
vtrd, zxaaa, the ZXDB tree and its extras) was copied unchanged into `work/candidates/<source>/` by
`tools/fetch_copies.py` (SHA-256 checked, `work/stage1/fetch-copies.txt`; four that sit inside nested rars were taken
from other paths by `work/stage1/fetch_more.py`). `tools/copy_compare.py` cut the original's three data blocks into
256-byte pieces and looked for each piece in every copy (`work/stage1/copy-compare.tsv`; the BASIC is shorter than
one piece and counts whole).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| ZXDB `Bumpy(ProeinSoftLine).tzx.zip`: `Bumpy (Proein).tzx` (46 035 bytes) | the Proein Soft Line re-release, a real dump (irregular pauses, the archive info above) | the three data blocks byte for byte (BASIC, screen, code) |
| World of Spectrum mirror `Bumpy(ProeinSoftLine).dsk.zip`: `Bumpy (Proein).dsk` (+3 disk, 194 816 bytes; the same file in the TOSEC 2020 and 2023 packs) | the Proein +3 disk release | another build: the code's first 18 901 bytes (`$61A8-$AB7C`) are the same; from `$AB7D` it differs in 22 places (89 of 151 pieces found); the screen 21 of 27 pieces |
| TOSEC 2020 `Bumpy (1989)(Loriciels)(FR)(en).tap` and `.tzx` | a transfer | an 83-byte BASIC "t:BUMPY" (`CLEAR 24999: LOAD "bumpy" CODE 25000: RANDOMIZE USR 43900`), no loading screen, one 39 000-byte block: the original code followed by 300 zero bytes |
| TOSEC MDR `(FR)(en).mdr`, `(FR)(en)[a].mdr` | Microdrive conversions | packed: one piece |
| zxart `(EN)[h Master Studio].tap`, vtrd `BUMPYRMS.SCL` | a Russian translation by Master Studio | 143 of 151 code pieces (texts changed), no screen |
| vtrd `BUMPY_R.SCL` | a TR-DOS version | 127 of 151 code pieces |
| zxart `(EN)[h Andy Tacker].tap`, `(EN)[h Bill Gilbert].tap` | hacks | 37 of 151 code pieces |
| vtrd and zxaaa `BUMPY128.SCL` (Eldar Agaev, 128), vtrd `BUMPYAXL.SCL` | TR-DOS conversions | 47 and 49 of 151 pieces |
| TOSEC 2012 `[h Ascendancy][t].$b`, `[h Code Monsters][t].$b`, `BUMPY_~1.$B`; TOSEC 2020 `[h Ascendancy].scl`; vtrd `BUMPY.SCL`, `BUMPY_.SCL`, `BUMPY_EM.SCL` (Energy Minds), `BUMPY_PP.SCL` (Power Project), `BUMPYAWS.SCL`, `BUMPYCDS.SCL`, `BUMPYPHL.SCL`; zxart `(Disk 1 of 2).scl` (two copies) | cracks and TR-DOS re-releases | packed: none of the pieces |
| zxaaa `bumpy_crackintro_gb.scl` | a crack intro | one piece |
| ZXDB extras `bumpy.rzx` (xmikex and Jamie Angus, SPIN 0.5, 48K, 150 437 frames, one snapshot, recorded with rollback) | someone else's run through all 100 levels to the wrap to level 0 | used, said so, to reach every level ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| ZXDB `Bumpy (1989)(Loriciels).pok`, `POKES/BUMPY.POK` | POKEs: infinite lives 47771 (`$BA9B`), hammers 47386 (`$B91A`), keys 51576 and 52155, water 51717, 52296 and 52807, the level 43776 (`$AB00`) | a POKE file |

ZXDB's known-errors note says the Kempston stick is read from port 223 (`$DF`) and gives POKE 46124,31 (the operand
of `IN A,($DF)` at `$B42B`) as the fix. No game called "Bampy" was found; GitHub has no SkoolKit disassembly of Bumpy
(`work/stage1/NOTES.md`).

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/BUMPY.TAP and compares it with orig/Bumpy.tap.zip's BUMPY.TAP byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann` (the BASIC from
`src/tape/basic.ann`, the loading screen from `src/screen/screen.ann`); the resources are `src/res/`
(`src/res/README.md`; `python3 tools/res_formats.py check`: 44 editable files, 0 bad). `python3 ../../kit/refdocs.py
--case .` writes docs 11 and 12.
