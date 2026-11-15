# R-Type (Electric Dreams Software, 1988)

State: in progress (stage 1: the medium, the recordings, the first maps).

| | |
| --- | --- |
| Machine | 48K (ZXDB machine type "ZX-Spectrum 48K"; the inlay: "Spectrum 48K, Spectrum 128K, Spectrum +2"). ZXDB lists "Multi-loader in 128K mode" and "in 48K mode": the same tape loads level by level on both. The game speaks only to the beeper (`OUT ($FE)`, [WALKTHROUGH 1](WALKTHROUGH.md#1-one-recording-from-power-on)); one routine at `$61BF` writes `$30` to port `$7FFD` (locks the 128K paging in the 48K layout). This case runs the 48K |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 4256: Bob Pape (code), Mark A. Jones (graphics), Robert L. Hylands (Software Studios); the game's own loading scroller credits "SOFTWARE/R.C.PAPE" and "GRAPHICS/'MAK'" (recording c1) |
| Release | ZXDB 4256: R-Type, Electric Dreams Software (Activision), 1988, £9.99, licensed from Irem ("(c) 1987 BY IREM CORP." in the game's text); re-releases Proein Soft Line (Spain, 1988), MCM Software (Spain, 1989), The Hit Squad (1990); in the compilations The Biz and Dark Force; a demo on a C&VG cover tape. ZXDB genre "Arcade Game: Shoot-em-up". ZXDB denies the distribution of the tape files; the files here come from the collection's World of Spectrum mirror |
| Original | `orig/R-Type.tzx.zip` (81 125 bytes, md5 `a09eb6da4c815f6b384be83812f5254d`, SHA-1 `0a316071d8a2ea67d69f4b935a548d284886cde3`; World of Spectrum `games/r/R-Type.tzx.zip`; the TZX's archive info: "Electric Dreams Software / Activision Inc", Bob Pape, Mark A. Jones, 1988, £9.99, "Speedlock 7", "Original Release", TZXed by Andrew Barker): `R-Type.tzx` (138 996 bytes, md5 `3f080d43ca69df2b9623a5baac8dc68c`, SHA-1 `4c08a903023a97a41a5e57826de00b605e4e5f6e`): a BASIC with code in it, the SpeedLock 7 loader's pure-data blocks, a stop block, then the eight levels, each a turbo header block and a turbo data block behind its own stop block ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Profile

Each row from stage 1's recordings ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)); the documents will carry them.

| Row (AGENTS.md 4.0) | R-Type |
| --- | --- |
| Genre | a horizontally scrolling arcade shooter for one player: the R-9 flies right through eight levels, each a separate tape load, each ending with a boss; after level 8 the game asks for level 1 again: the level-end step `$C25E` turns the digit `$719C` from `'8'` to `'9'` and play goes on with level 8's boss, the next end turns it to `'0'` and LoadLevel to `'1'` ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings), recording ending) |
| Weapons and pick-ups | the shot, the beam charged by holding fire (the BEAM gauge on the HUD), the Force pod detached and called back (the DETACH key; SPACE with a joystick); the inlay names the jewels' weapons: reflection laser, anti-aircraft laser, ground laser, homing missiles, extra speed, shield orbs |
| Enemies and bosses | a boss at the end of each level (all eight reached by recordings l1-l8, ending); each level's objects drawn from its data in [the sprite sheets](WALKTHROUGH.md#61-the-screens); which object is which enemy is stage 2 |
| Rendering | a horizontal scroll of the playfield in colour above a two-row HUD (BEAM, the score, the lives, HI SCORE); the scroll and the sprite method are measured in stage 2 |
| Engine | IM 2 through `$8383` with a 5-entry task table at `$BE60`; a main loop that waits for 3 frames a pass; a multi-load (each level read by the game's own turbo loader LoadLevel `$FE03` to `$C4AE`); copy protection: SpeedLock 7 (the BASIC's hidden `RANDOMIZE USR` and encrypted pure-data blocks) ([WALKTHROUGH 1](WALKTHROUGH.md#1-one-recording-from-power-on), [doc 3](docs/03-build-and-load.md)) |
| Sound | the beeper only: the effects, with noise taken from ROM bytes (`OUT ($FE)` at `$86F6`, `$FAA2`, `$FB52`) |
| Controls | redefinable keys (ENTER on the title: LEFT, RIGHT, UP, DOWN, FIRE, DETACH), Kempston (ZXDB "Kempston, Redefineable keys"); pause CAPS SHIFT+1, resume CAPS SHIFT+2 (the inlay) |

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
| World of Spectrum `R-Type(MCM).tzx.zip`, TOSEC "(MCM)(ES)(en)(Side A/B)" | the MCM Software re-release | side A a standard-block re-save (a screen, `$7000` 21 678 bytes, `$DD18` 8841 bytes): the `$DD18` block equals the image at the entry byte for byte, the `$7000` block differs only at `$8F1F-$8FBA` (the level loader's edge loops, [doc 3, 3.2](docs/03-build-and-load.md#32-the-level-loader)); side B the eight levels as standard blocks, their bodies byte for byte |
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

- The game: R-Type, Electric Dreams Software 1988 (ZXDB 4256); Bob Pape, Mark A. Jones, Robert L. Hylands; the
  arcade game by Irem.
- The tape: the World of Spectrum mirror `games/r/R-Type.tzx.zip`, the file in `orig/`, TZXed by Andrew Barker.
- The instructions (The Hit Squad text) and the POKE file: ZXDB, in `work/candidates/zxdb/`.

## Build

```bash
tools/build.sh [SJASMPLUS]     # stage 4: builds the tape and compares it with orig/ byte for byte
```

The game source will be `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources
`src/res/`.
