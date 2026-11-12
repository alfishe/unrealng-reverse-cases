# Bumpy (Loriciels, 1989)

State: in progress (stage 1, 2026-11-12).

| | |
| --- | --- |
| Machine | 48K (ZXDB: "ZX-Spectrum 48K"). The game is one 38 700-byte block at `$61A8-$F8D3`, run by `RANDOMIZE USR 43900` (`$AB7C`); no 128K code, no AY (the beeper only, port `$FE` written from `$F513`, `$F534`, `$F54C`, `$F560`, `$F5AD`) |
| Profile (AGENTS.md 4.0) | a single-screen arcade puzzle for one or two players (to be confirmed from play): Bumpy, a bouncing ball, bounces on the platforms of 100 levels (`$AB00` 0-99; after level 99 the count wraps to 0), each one screen of 6 x 6 cells drawn from a 75-byte record (`$8C3C` + 75 x level; [doc 2, 2.3](docs/02-architecture.md#23-the-levels)): 11 platform types in use (low nibble of a cell, handlers `$C5A8`), 4 wall types (high nibble, handlers `$C5C2`), and 1 to 33 objects a level of 40 kinds (`$6CB0` + 56 x k; fruit, sweets and other prizes, and the hammers, keys and water drops the HUD counts; [sprites](docs/img/sprites/sheet.png)); when every prize is taken (record byte 37 counts them) an exit opens on the cell of byte 38 and the level ends; a timer from 1000 a level (`$AB04`) whose rest is a bonus; two lives at the start (`$AB01`); a hall of fame of four; no enemies seen in the 100 levels' start screens, the hazards seen are spikes; 14 beeper sound effects (`$F3C8-$F50F`), no music seen; controls: keyboard Q A O P SPACE, Sinclair (9 8 6 7 0), Kempston (port `$DF`, which unreal-ng's Kempston mouse also answers: [WALKTHROUGH 5](WALKTHROUGH.md#5-tool-gaps-found-and-fixed-in-unreal-ng)), H and R in play. Still to see in play: what each platform, wall and object does, every way to die |
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

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`). Not written yet (stage 4).
