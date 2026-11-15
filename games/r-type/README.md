# R-Type (Electric Dreams Software, 1988)

State: docs written, in review (2026-11-15): docs 01-10 by three writers, docs 11 and 12 generated, integrated; the
tape builds identical from the sources. 12 documents, 100 figures (PNG), 43 animations (GIF), 78 mermaid diagrams and 31
audio files (24 short WAV, the longest 1.5 s; 7 MP3 over 2 s: the level 2 beat cut at 30 s, the level end tune and the
other long sounds; 1.6 MB), counted on 2026-11-15 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs -name '*.mp3' | wc -l; find docs -name '*.wav' | wc -l; du -sh docs/audio
```

| | |
| --- | --- |
| Machine | 48K (ZXDB machine type "ZX-Spectrum 48K"; the inlay: "Spectrum 48K, Spectrum 128K, Spectrum +2"). ZXDB lists "Multi-loader in 128K mode" and "in 48K mode": the same tape loads level by level on both. The game speaks only to the beeper (`OUT ($FE)`, [WALKTHROUGH 1](WALKTHROUGH.md#1-one-recording-from-power-on)); one routine at `$61BF` writes `$30` to port `$7FFD` (locks the 128K paging in the 48K layout). This case runs the 48K |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 4256: Bob Pape (code), Mark A. Jones (graphics), Robert L. Hylands (Software Studios); the game's own loading scroller credits "SOFTWARE/R.C.PAPE" and "GRAPHICS/'MAK'" (recording c1) |
| Release | ZXDB 4256: R-Type, Electric Dreams Software (Activision), 1988, £9.99, licensed from Irem ("(c) 1987 BY IREM CORP." in the game's text); re-releases Proein Soft Line (Spain, 1988), MCM Software (Spain, 1989), The Hit Squad (1990); in the compilations The Biz and Dark Force; a demo on a C&VG cover tape. ZXDB genre "Arcade Game: Shoot-em-up". ZXDB denies the distribution of the tape files; the files here come from the collection's World of Spectrum mirror |
| Original | `orig/R-Type.tzx.zip` (81 125 bytes, md5 `a09eb6da4c815f6b384be83812f5254d`, SHA-1 `0a316071d8a2ea67d69f4b935a548d284886cde3`; World of Spectrum `games/r/R-Type.tzx.zip`; the TZX's archive info: "Electric Dreams Software / Activision Inc", Bob Pape, Mark A. Jones, 1988, £9.99, "Speedlock 7", "Original Release", TZXed by Andrew Barker): `R-Type.tzx` (138 996 bytes, md5 `3f080d43ca69df2b9623a5baac8dc68c`, SHA-1 `4c08a903023a97a41a5e57826de00b605e4e5f6e`): a BASIC with code in it, the SpeedLock 7 loader's pure-data blocks, a stop block, then the eight levels, each a turbo header block and a turbo data block behind its own stop block ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Profile

Each row from the documents.

| Row (AGENTS.md 4.0) | R-Type |
| --- | --- |
| Genre | a horizontally scrolling arcade shooter for one player: the R-9 flies right through eight levels, each a separate tape load and each ending with a boss; five lives, restart points 8 block columns before the last checkpoint passed, 4 continues; after level 8 the game loads level 1 again with the score and lives kept (the wrap): the closing text in level 8's data is placed after the column that ends the game and never shows ([doc 1](docs/01-game-design.md), [doc 10, 10.14](docs/10-gameplay-logic.md#1014-the-level-end-and-the-wrap)) |
| Weapons and pick-ups | the shot, the beam charged by holding fire (BeamCharge up to `$3E`, three powers), the Force (three sizes, docked at the nose or the tail, detached and recalled with DETACH), laser crystals (bouncing, ground, anti-air), two bits, missiles and a shield that is drawn and does not protect; every pick-up 400 points ([doc 10, 10.4-10.9](docs/10-gameplay-logic.md#104-the-shot-and-the-charged-beam)) |
| Enemies and bosses | each level's enemy kinds, movement scripts and movers are in its own tape block; waves are started by a script tied to the map's columns; 28 enemy slots; the bosses are timed set pieces that end by the map's clock or a blast, not by a hit count; three death paths: scenery ahead of the nose, an enemy's cell, an enemy shot ([doc 7](docs/07-objects.md), [doc 10, 10.10-10.11](docs/10-gameplay-logic.md#1010-the-enemies-the-waves-and-the-bosses-of-each-level)) |
| Map | per level a map of block columns (5 bytes each: metatile in bits 0-5, a drawer in bits 6-7 that mirrors or flips it), metatiles of 4 x 4 cells below the map, the wave script and the checkpoints in the level header ([doc 6, 6.2](docs/06-rendering.md#62-the-map-and-the-metatiles), [doc 7, 7.2](docs/07-objects.md#72-the-level-block-what-lies-where)) |
| Rendering | a character-cell playfield of 20 rows in colour above a HUD; the scenery scrolled one pixel a pass by an unrolled `RL (HL)` chain over its runs, sprites drawn into a pixel shadow at `$6000` and copied cell by cell, SolidMap tags as collision, the erase free through DrawnMap; no attribute clash: one thing a cell; no sync with the beam ([doc 6](docs/06-rendering.md)) |
| Engine | IM 2 through `$8383` with a 5-entry task table at `$BE60` (stars, three sound channels, the title colour); a main loop of at least 3 interrupts a pass, 4.68 frames on average in level 2; a multi-load (each level read by the game's own loader LoadLevel `$FE03` to `$C4AE`); copy protection: SpeedLock 7 (a hidden `USR`, 119 rewrite loops, an enciphered game deciphered 0.4 s before it runs) ([doc 3](docs/03-build-and-load.md), [doc 4](docs/04-game-loop.md)) |
| Sound | the beeper only: 35 sounds (`$00`-`$22`) run by three script channels from the interrupt, chords from a period table and noise from ROM bytes; three explosions at once stretch a pass to 12 frames; 48K only, the same on a 128K ([doc 9](docs/09-sound.md)) |
| Controls | the title's fire picks the method: keys 1-5 (Interface 2), the defined keys (ENTER: LEFT, RIGHT, UP, DOWN, FIRE, DETACH), Kempston (only when the probe saw a quiet port), keys 6-0 (Sinclair); pause CAPS SHIFT+1, resume CAPS SHIFT+2; no abort key ([doc 5](docs/05-controls.md)) |

## Other releases and copies

Every copy of the standard tape that the collection index lists (`index/zx-image-locations.tsv`, `grep -i
"r-type\|rtype"`) was looked up; the tapes were copied unchanged into `work/candidates/<source>/` (World of
Spectrum, TOSEC 2023, ZXDB files, the RZX archive) and compared block by block with the original
(`tools/media_compare.py --min 3`, `work/stage1/media-compare.txt`); which of the eight level bodies each copy holds
whole is in `work/stage1/media-levels.txt`.

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| TOSEC "(Electric Dreams)[a3].tzx" | the original | the same file as `orig/` (same md5) |
| TOSEC "(Electric Dreams).tzx" | another transcription of the original (the loader's marker pulses as pulse blocks, "Speedlock 4") | every data block byte for byte |
| TOSEC "[a2].tzx" (Ramsoft) | another transcription | every data block byte for byte |
| World of Spectrum `R-Type(TheHitSquad).tzx.zip` (TOSEC "[a4].tzx" in the 2023 set) | The Hit Squad re-release, side 1 | the same 14 loader and game blocks byte for byte; no level blocks (43 384 bytes) |
| TOSEC "[a].tzx" | a re-save | a 158-byte BASIC and a 32 026-byte block; levels 1-7 byte for byte under flag `$AA`, level 8 differs |
| World of Spectrum `R-Type(MCM).tzx.zip`, TOSEC "(MCM)(ES)(en)(Side A/B)" | the MCM Software re-release | side A a standard-block re-save (a screen, `$7000` 21 678 bytes, `$DD18` 8841 bytes): the `$DD18` block equals the image at the entry byte for byte, the `$7000` block differs only at `$8F1F-$8FBA` (the level loader's edge loops, [doc 3, 3.2](docs/03-build-and-load.md#39-the-games-level-loader)); side B the eight levels as standard blocks, their bodies byte for byte |
| World of Spectrum `R-Type.tap.zip` (`RTYPE.TAP`), TOSEC "[a].tap", "[a3].tap", "[+D multiload].tap" (World of Spectrum `R-Type(+D).tap.zip`), "[h Pokes][t].tap", "[h S.S.Captain].tap" | TAP re-saves and hacks | other loaders; all eight level bodies byte for byte |
| TOSEC "[h Bill Gilbert].tap", "[h Mihal Soft][tr ru].tap" (Russian text), "[h Paco 958.274833].tap" | hacks | levels 1-7 byte for byte, level 8 differs |
| TOSEC "(128K)[cr Torasoft][t +3 Torasoft]", "[h Torasoft].tap"; ZXDB `r_type.zip` (Torasoft, RTYPE_1-4) | a 128K crack with the levels in memory | no level body whole |
| TOSEC "(Electric Dreams).tap", "[a2].tap", "[t].tap", "[t Pokes].tap", "[h Msinc]", "[h Phonex]", "[h Vitaly Corp]", "[h Bill Gilbert][a]"; World of Spectrum `R-TypeDemo.tap.zip` | single-load re-saves, hacks and the demo | no level body whole |
| TOSEC `.z80`, `.slt`, `.scl` (TR-DOS hacks) | snapshots and disk conversions | not studied (only the standard tape) |
| The RZX archive `rtype.zip` (`rtype.rzx`, 60 380 bytes) | someone else's run | kept in `work/candidates/nas-rzx/`; not used in stage 1 (the levels were reached by input scripts) |
| ZXDB POKE file "R-Type (1988)(Electric Dreams Software).pok" | POKEs | infinite lives `37374,0`; absolute invincibility `37362,201` (used by the level recordings, said so there) |

ZXDB notes that "the original release could not be completed because final level 8 was missing from tape (level 7
was stored twice instead)". The original here holds a level 8 of its own: its header's level digit is `'8'` and its
body 11 980 bytes against level 7's 12 997, and recording l8 plays it to its boss. So this TZX was made from a
tape without that fault.

## Sources and credits

- The game: R-Type, Electric Dreams Software 1988 (ZXDB 4256); Bob Pape (code; "SOFTWARE/R.C.PAPE" in the loading
  scroller), Mark A. Jones (graphics; "GRAPHICS/'MAK'"), Robert L. Hylands (Software Studios); the arcade game by
  Irem ("(c) 1987 BY IREM CORP.").
- The tape: the World of Spectrum mirror `games/r/R-Type.tzx.zip`, the file in `orig/`, TZXed by Andrew Barker.
- The instructions (The Hit Squad text) and the POKE file: ZXDB, in `work/candidates/zxdb/`.

## Build

```bash
sh tools/build.sh [SJASMPLUS]          # builds the tape from src/ and compares it with orig/ byte for byte
python3 tools/res_formats.py check     # every resource against the bytes it stands for
```

The sources are written by `kit/mkgame.py` from the `.ann` files: the game `src/game/*.asm` from
`src/game/game.ann`, each level `src/levelN/` from its `levelN.ann`, the loader `src/loader/` and the BASIC
`src/tape/`; the resources are in `src/res/` (a README in every folder). The commands: `work/stage2/NOTES.md`.
