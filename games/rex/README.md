# Rex (Martech Games, 1988)

State: in progress (stage 1, 2026-11-14: the medium, the release check, the recordings).

| | |
| --- | --- |
| Machine | 48K and 128K from one tape (ZXDB machine type "ZX-Spectrum 48K/128K"). Each part's code holds AY writes (`OUT ($FFFD)` at `$D759` in REX 1, at `$D4F1` in REX 2: `work/stage1/zdis.py` on the tape blocks) besides the beeper; how the program picks the device is stage 2's. This case runs the 128K (both RZX runs of the archive were made on a 128K) |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 4129: Neil Harris, John Anderson, Richard Allen (The Light); inlay art Steinar Lund |
| Release | ZXDB 4129: Rex (aka Zenith), Martech Games Ltd, 1988, £8.99; re-releases EDOS, Erbe Software S.A. (Spain, 1988), Winner (1988). Genre in ZXDB "Arcade Game: Shoot-em-up" |
| Original | `orig/Rex.tzx.zip` (80 296 bytes, md5 `b963f200cafcfe50904c51650ecb0612`, SHA-1 `dd2a79e594f5694f5d8a41892194a9cec18bf990`; ZXDB `pub/sinclair/games/r/Rex.tzx.zip`, release 0, Martech; "Created with Ramsoft MakeTZX"): `Rex - Side 1.tzx` (95 812 bytes, md5 `f06f195b520230fc99d89686c9524446`, SHA-1 `be20229424ed81dcb24812a07da45fb3c8749372`): two programs one after the other, REX 1 and REX 2, each a BASIC, a screen and one code block, all standard ROM blocks; `Rex - Side 2.tzx` (47 725 bytes, md5 `6f997ab07c1e75b8dae06726210c28a0`, SHA-1 `13b5667223fbcf50ebff827aa2d8ee6ccf1647a8`): DEMO, the same three-block layout ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Profile

Picked in phase 0 from the tape, the instructions (ZXDB `Rex.txt`) and the first recordings; each row is confirmed
from play in stage 1 and its items go into the writers' briefs.

| Row (AGENTS.md 4.0) | Rex |
| --- | --- |
| Genre | "Arcade, platform, flip-screen" and "Scrolling arcade or shooter" (to be confirmed from play): a run-and-gun platform shooter for one player. Rex, an armoured dinosaur mercenary, walks, jumps and shoots through caves to the heart of the Great Tower of Zenith. Two levels, one a part of the tape: REX 1 (level 1) and REX 2 (level 2), which asks for the access code level 1 gives at its end (the instructions; the POKE file's "Access code always right" for part 2). The map of each level, its rooms and its route come from the level data |
| Weapons and pick-ups | Rex starts with one weapon; four more are in weapon pods; the energy bubbles the enemies leave raise the weapon energy through pink, green, cyan, yellow and white, and past white the next weapon held; a smart bomb (SPACE), a shield (J); the pods' effects whose texts the code holds (SPEED UP, SHIELD LOSS, 1000 BONUS, ENERGY LOSS, 100 RAPID SHOTS: strings in the DEMO block) |
| Enemies and bosses | each with a name and a score on the menu's roll call (recording `c1`: STOMPER 200, LAUNCHER 800, BLOB 200, ...); the bosses as the recordings reach them |
| Rendering | "Flip-screen" or "Scrolling" as play shows it, "Sprites over a background" |
| Engine | "Multi-load, 128K paging": two parts loaded apart (REX 1 at `$6018`, REX 2 at `$61A8`) and a DEMO on side 2; each part a stage of its own |
| Sound | the beeper and the AY (the `$FFFD` writes): which plays on which machine, the tunes and effects |
| Controls | keyboard Q W (left, right), I (jump), J (shield), O (fire), SPACE (smart bomb), H (pause), redefinable except SPACE and H (the instructions); Kempston, cursor and Sinclair from the menu (SELECT 1 DEFINE, 2 KEMPSTON, 3 CURSOR, 4 SINCLAIR: recording `c1`) |

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
- The RZX runs: the RZX archive's `rex.zip` (`rex1.rzx`, `rex2.rzx`), someone else's play, cut into input scripts.
- The instructions: ZXDB `pub/sinclair/games-info/r/Rex.txt` (spectrumcomputing.co.uk): the keys, the two parts and
  the access code, the weapons and the energy bubbles, the DEMO ("Tutor Mode") on side 2.
- A SkoolKit disassembly exists: `ultrabolido/skRex` on GitHub ("A disassembly of Rex, created using SkoolKit", side A
  and side B; found 2026-11-14). It is not used: every name and finding here is ours (`work/stage1/NOTES.md`).

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds the tape and compares it with orig/Rex.tzx.zip byte for byte (stage 4)
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
