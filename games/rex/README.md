# Rex (Martech Games, 1988)

State: docs written, in review (2026-11-15): docs 01-10 by the writers, docs 11 and 12 generated, integrated; both
tape sides build identical from the sources. 12 documents, 62 figures (PNG), 29 animations (GIF), 85 mermaid
diagrams and 16 audio files (16 short WAV, the longest 4.6 s, no MP3; 1.7 MB), counted on 2026-11-15 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs -name '*.mp3' | wc -l; find docs -name '*.wav' | wc -l; du -sh docs/audio
```

| | |
| --- | --- |
| Machine | 48K and 128K from one tape (ZXDB machine type "ZX-Spectrum 48K/128K"). Every part plays its effects on the AY (SoundWrite `$D759` in REX 1: `OUT ($FFFD)`, `OUT ($BFFD)`) and nothing tests for it: on a 48K the writes reach no device and the game is silent but for the beeper crackle of the explosions (DrawShard `$BF66`, `OUT ($FE)`) ([doc 9, 9.1](docs/09-sound.md#91-the-hardware-and-what-a-48k-hears)). No interrupts, no paging: the 48K and the 128K run the same code. This case runs the 128K (both RZX runs of the archive were made on a 128K) |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 4129: Neil Harris, John Anderson, Richard Allen (The Light); inlay art Steinar Lund |
| Release | ZXDB 4129: Rex (aka Zenith), Martech Games Ltd, 1988, £8.99; re-releases EDOS, Erbe Software S.A. (Spain, 1988), Winner (1988). Genre in ZXDB "Arcade Game: Shoot-em-up" |
| Original | `orig/Rex.tzx.zip` (80 296 bytes, md5 `b963f200cafcfe50904c51650ecb0612`, SHA-1 `dd2a79e594f5694f5d8a41892194a9cec18bf990`; ZXDB `pub/sinclair/games/r/Rex.tzx.zip`, release 0, Martech; "Created with Ramsoft MakeTZX"): `Rex - Side 1.tzx` (95 812 bytes, md5 `f06f195b520230fc99d89686c9524446`, SHA-1 `be20229424ed81dcb24812a07da45fb3c8749372`): two programs one after the other, REX 1 and REX 2, each a BASIC, a screen and one code block, all standard ROM blocks; `Rex - Side 2.tzx` (47 725 bytes, md5 `6f997ab07c1e75b8dae06726210c28a0`, SHA-1 `13b5667223fbcf50ebff827aa2d8ee6ccf1647a8`): DEMO, the same three-block layout ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Profile

Each row from the documents.

| Row (AGENTS.md 4.0) | Rex |
| --- | --- |
| Genre | a flip-screen run-and-gun platform shooter for one player ([doc 1](docs/01-game-design.md)): Rex walks, jumps and shoots through rooms one screen each; REX 1 has 35 rooms (0-34) with one-way exits and three forks and ends with a 16-digit access code; REX 2, a separate load, asks for the code, takes Rex's state from it and climbs 26 rooms (0-25) to the boss; DEMO on side 2 plays four of REX 1's rooms by itself as a tutor ([doc 1, 1.1](docs/01-game-design.md#11-the-premise-and-the-three-parts), [1.4](docs/01-game-design.md#14-the-world)) |
| Weapons and pick-ups | the gun, then double fire, laser, multiple and spray from four stations (REX 1 rooms 1, 6, 23, 11), each with its weapon panel; power in levels 1-5 inside five ranks: the rank picks the best weapon held, the level the gun's and double fire's shots in the air and the spray's fan; pods: power, a smart bomb, the bonus roulette (SPEED UP, SHIELD LOSS, 1000 BONUS, ENERGY LOSS, 100 RAPID SHOTS); the shield and its rechargers; three smart bombs ([doc 10](docs/10-gameplay-logic.md)) |
| Enemies and bosses | REX 1's 17 kinds (the roll call names ten: STOMPER, SCANNER, SWING GUN, SHOOTERS, LAUNCHER, RAMMING POD, MINE LAYER, BLOB, ...; kind 2 never appears), the standing gunman, people counted as HUMANS KILLED, the combo score of a foot man shot in the front (up to 4500), the big gun; REX 2's boss, the big squidgy thing in room 25 ([doc 1, 1.6](docs/01-game-design.md#16-the-enemies), [doc 7](docs/07-objects.md)) |
| Rendering | flip-screen; the room drawn from a character map into a back buffer `$EB00-$FFFF` (BackBuffer, cleared by `PUSH` one byte low), sprites pre-shifted and drawn by DrawSprite and DrawMirrored, the animated scenery redrawn over them, the buffer copied to the screen once a pass, no wait for the beam ([doc 6](docs/06-rendering.md)) |
| Engine | no interrupts: a main loop of about 4.4 frames a pass, every timer counted in passes; three separate loads (REX 1 at `$6018`, REX 2 and DEMO at `$61A8`), no custom loader, protection or packer ([doc 2](docs/02-architecture.md), [doc 3](docs/03-build-and-load.md), [doc 4](docs/04-game-loop.md)) |
| Sound | 14 effects on the AY from descriptors of a 6-byte head and 3-byte steps, stepped twice a pass; the beeper crackle of the explosions; no tune ([doc 9](docs/09-sound.md)) |
| Controls | 1 DEFINE, 2 KEMPSTON, 3 CURSOR, 4 SINCLAIR through five self-modified readers; SPACE smart bomb, H pause, ENTER restart fixed; REX 2's code entry ([doc 5](docs/05-controls.md)) |

## Other releases and copies

Every copy the collection index lists (`index/zx-image-locations.tsv`, `grep -i "/Rex"`) of the standard tape was
looked up; the tapes of this game were copied unchanged into `work/candidates/<source>/` (ZXDB, TOSEC 2012, the RZX
archive, the POKE file) and compared block by block with the original (`tools/media_compare.py`,
`work/stage1/media-compare.txt`).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| ZXDB `Rex(Winner).tzx.zip` (`Rex - Side 1 (Winner).tzx`, `- Side 2 (Winner).tzx`); the same files are TOSEC's "(Winner)(Side A/B)[re-release]", and "(Martech Games)(Side A/B)[a]" in the 2005 set | the Winner re-release | every data block byte for byte; only the gaps differ (side 1 has other pauses and a "stop the tape" block between REX 1 and REX 2; side 2 other pauses) |
| TOSEC 2012 "(Martech Games)(Side A).tzx", "(Side B).tzx" | the original | the same files as `orig/` |
| TOSEC "(Side B)[a].tzx" (TOSEC 2005 "zzz-unk-Rex-Pt2") | REX 2 alone | the four blocks of REX 2 byte for byte, re-recorded with 1 s gaps |
| TOSEC "(Side A)[a].tzx" (TOSEC 2005 "zzz-unk-Rex-Pt1"), TOSEC TAP "(Side A).tap" | a re-save of REX 1 | a BASIC "REX" with code in it and four headerless blocks of 288, 20 000, 20 536 and 1704 bytes: none of the original's blocks |
| ZXDB `RexSideA.tap.zip` (`REX1.TAP`), `RexSideB.tap.zip` (`REX2.TAP`) | REX 1 and REX 2 as TAPs | the screen and code blocks byte for byte; the BASIC adds `PAUSE 0` before `RANDOMIZE USR` (REX 1 in line 60; REX 2 a line 55, the program named "REX-2") |
| TOSEC TAP "(Martech Games).tap", "(Side B).tap", "(Side B)[a].tap" | REX 2 alone; DEMO; DEMO again | the original's blocks byte for byte (the `[a]` header differs in 4 bytes) |
| ZXDB `RexDemo.tap.zip` (the Your Sinclair covertape demo) | the demo | its blocks are side 2's DEMO byte for byte |
| ZXDB `Rex.dsk.zip`, TOSEC Z80 snapshots, MDR cartridges, the TR-DOS conversions and hacks on zxart.ee; Rex Hard (ZXDB 4132) is another game | a +3 disk, snapshots and conversions | not studied (only the standard tape release) |
| RZX archive `rex.zip`: `rex1.rzx` (Spectaculator 0.52, 128K, 64 813 frames, from a snapshot at PC `$C8DE`), `rex2.rzx` (SPIN 0.5, 128K, 41 776 frames, from a snapshot at PC `$DB1A`) | someone else's runs of part 1 and part 2 | used as input scripts to reach late parts, said so where it is a witness ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| ZXDB POKE file `Rex (1988)(Martech Games).pok` | POKEs for both parts | infinite lives `40057,0` (part 1), `40303,0` (part 2), infinite time `43545,0`, and others |

## Sources and credits

- The game: Rex, The Light for Martech Games, 1988 (ZXDB 4129); ZXDB credits Neil Harris, John Anderson and Richard
  Allen (The Light), and Steinar Lund for the inlay art.
- The tape: ZXDB `pub/sinclair/games/r/Rex.tzx.zip`, the file in `orig/`.
- The RZX runs: the RZX archive's `rex.zip`, someone else's play, cut into input scripts: `rex1.rzx` (recorded with
  Spectaculator 0.52, 128K, 64 813 frames, part 1 to its code) and `rex2.rzx` (SPIN 0.5, 128K, 41 776 frames, part 2
  to the ending); the players are not named in the files.
- The instructions: ZXDB `pub/sinclair/games-info/r/Rex.txt` (spectrumcomputing.co.uk): the keys, the two parts and
  the access code, the weapons and the energy bubbles, the DEMO ("Tutor Mode") on side 2.
- A SkoolKit disassembly exists: `ultrabolido/skRex` on GitHub ("A disassembly of Rex, created using SkoolKit", side A
  and side B; found 2026-11-14). It is not used: every name and finding here is ours (`work/stage1/NOTES.md`).

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # build/side1.tzx and side2.tzx, compared with orig/Rex.tzx.zip byte for byte
```

The sources are `src/game/*.asm` (REX 1), `src/rex2/*.asm` (REX 2) and `src/demo/*.asm` (DEMO), written by
`kit/mkgame.py` from each part's `.ann` (the BASICs from `src/tape/basic.ann`, the loading screens from `src/screen/`);
the resources are `src/res/` (`src/res/README.md`; `python3 tools/res_formats.py check`: 43 editable files, 0 bad).
`python3 ../../kit/refdocs.py --case .` writes docs 11 and 12.
