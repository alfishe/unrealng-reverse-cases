# R-Type: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The case starts from ZXDB 4256 (R-Type, Electric Dreams Software (Activision), 1988; Bob Pape, Mark A. Jones,
Robert L. Hylands). The original is `orig/R-Type.tzx.zip`, the World of Spectrum `games/r/R-Type.tzx.zip` (TZXed by
Andrew Barker, "Speedlock 7", "Original Release"; hashes in the [README](README.md)). It is a 48K game that also
loads on the 128K (the [README](README.md) Machine row): the same tape, level by level, the beeper only.

The release check (`tools/media_compare.py --min 3`, `work/stage1/media-compare.txt`; the level bodies per copy in
`work/stage1/media-levels.txt`): every tape of the standard release that the collection index lists was copied
unchanged into `work/candidates/<source>/` (`wos`, `tosec-2023`, `zxdb`, `nas-rzx`). TOSEC "[a3].tzx" is `orig/`
itself; TOSEC "(Electric Dreams).tzx" and "[a2].tzx" hold every data block byte for byte; The Hit Squad tape holds
the same 14 loader and game blocks and no levels; the MCM re-release is a standard-block re-save whose code differs
only in the level loader's edge loops; the TAP re-saves and hacks keep all eight levels or levels 1-7; the Torasoft
128K crack holds none whole. The full table is in the README. The snapshots, the TR-DOS conversions and the other
platforms are not studied.

The tape ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)): a ROM-speed BASIC with code in it, the
SpeedLock 7 part (pure-data blocks, two of them encrypted code), a stop block, then eight levels, each a turbo header
and a turbo body behind its own stop block, read by the game's own LoadLevel `$FE03`
([doc 3, 3.2](docs/03-build-and-load.md#32-the-level-loader)). ZXDB says the first tapes had level 7 twice and no
level 8; this TZX holds a level 8 of its own (header digit `'8'`, 11 980 bytes), played by recording l8.

Other sources: the RZX archive's `rtype.zip` (kept in `work/candidates/nas-rzx/`, not used: every part was reached by
input scripts), the ZXDB POKE file (its absolute invincibility `37362,201` = `$91F2` `RET` drives the level
recordings, each says so) and the instructions. GitHub was searched once for a disassembly (`work/stage1/github-search.txt`):
none exists; the hits are articles (RetroReversing, the code198x vault) and this repository's TODO row.

## 1. One recording from power-on

`c1`: the 48K from power-on, `LOAD ""` typed (J, SYMBOL SHIFT+P twice, ENTER at frames 200-224), the original tape
at signal speed (no LD-BYTES trap; the tape started at frame 234), SpeedLock 7 and then the game's own level loader
for level 1 (`tools/record.py c1 --model 48K`, port base 37785, `tests/inputs/c1.txt`). 19 884 frames. The stages
(`$RS stages --work work/stage1/open-c1`, [doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)): the
BASIC's code `$5D06` at frame 2081, 26 decryption layers at `$EC00-$FB7E` in frames 2083-2398, the edge loader
`$FEE8` at frame 2599, the tail `$61A8` and the game's entry `$85FD` at frame 11 700 T 1379. Then REWIND SIDE 2 THEN
PRESS ANY KEY (frame 13 784, SPACE), SEARCHING FOR R TYPE LEVEL 1 and the level 1 load (frames 13 858-16 528), R TYPE
LEVEL 1 LOADED OK, the title cycle (16 828-17 578: the title, TODAY'S BEST PILOTS), ENTER and the keys defined
(17 858-18 134: O P Q A M N), play from 18 302 (moves, fire, a charged beam, the Force detached and called back,
PILOT STAND BY ! on CAPS SHIFT+1 and play again on CAPS SHIFT+2), a life lost at 19 269.

The interrupts and the timing, a first look:

- **IM mode and handler.** IM 2. The entry `$85FD` runs `DI`, sets `SP` to `$FFFE`, and at `$8624-$862A` sets
  `I` = `$84`, `IM 2` and `EI`; the table `$8400-$8500` is all `$83`, so every interrupt goes to `$8383`, which holds
  `JP $BE23`. The handler `$BE23` saves the registers, adds 1 to the frame counter `$7A8A` and walks the task table
  at `$BE60`: 5 entries of 5 bytes (address, mask, counter, reload). The tasks are `$BE79`, `$F8E8`, `$F8F8` and
  `$F908` (mask 1, reload 3: each runs every third interrupt) and `$76CB` (mask 0: off in play). c1's L1 counts 5584
  interrupts: 143 in the ROM's `$0038` before the entry and 5441 entries of `$8383` (`$RS interrupts`), 4237 T an
  entry on average (1.7 % of the CPU).
- **DI and EI.** `DI` at `$85FD` (the entry) and `EI` at `$862A`; the level loader `$8F1F` starts with `DI` and
  pushes `$FEC0`, where `EI` follows its return ([doc 3, 3.2](docs/03-build-and-load.md#32-the-level-loader)): the
  interrupts stop for each level load (c1: `$8F1F` and `$FEC0` twice each, the header and the body). The SpeedLock
  part runs with interrupts off too (no interrupt between the BASIC's `USR` and the entry). The pause `$8B77`
  (CAPS SHIFT+1, read at `$8BA4`) runs `DI` at `$8B7F` and waits on the keyboard until 2 (`$8BA0`), then `EI` at
  `$8B92`.
- **The main loop.** `$8649`: `XOR A: LD ($7A8A),A`, then the pass calls `$924B`, `$8B77`, `$8979` (the scroll),
  `$9109`, `$8FDD` (the attack-wave script), `$8B06` (the controls through the vector `$74FC`), `$94F1`, `$8C8B`,
  `$95F6`, `$C40E`, `$9E6B`, `$A01F`, `$9DFA`, `$93D0`, `$9DA5`, `$C348`, `$C0F9`, `$FDA5`, `$C25E` (the level end),
  `$C2D6`, and waits at `$868C` until `$7A8A` is 3 or more; `JP $8649`. A pass takes 3 frames at the least.
- **Frames per pass.** Measured on recording l2 over frames 3500-15 500 (`tools/pass_frames.py`: `$7A8A` read at the
  start of every frame through `time_travel memory_at`, `work/stage1/pass-frames-l2.txt`): 2512 whole passes, 2
  frames once, 3: 501, 4: 768, 5: 647, 6: 386, 7: 106, 8: 64, 9: 31, 10: 5, 11: 2, 12: 1; 4.68 frames a pass on
  average. The game runs at 50/3 passes a second only when little is on screen.
- **The heaviest frame.** The longest pass is 12 frames, from l2 frame 8982 (then 11 from 11 721 and 11 732): the
  middle of level 2, 31 frames before [the screen at 9013](docs/img/play/l2-009013-near-heaviest-pass.png): a dozen
  enemies, the reflecting laser's lines and the Force on screen at once. What makes the pass long is stage 2.

## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

R-Type as it plays (seen in the recordings below): the R-9 flies right through eight horizontally scrolling levels,
each loaded from tape when reached and each ending with a boss. Fire shoots; holding fire charges the beam (the BEAM
gauge on the HUD); the Force pod is detached and called back with DETACH. Five lives at the start (the HUD's ship
icons); MISSION OVER ends a game, then CONTINUE counts 9 to 0 with PRESS FIRE BUTTON and the credits (5 at the
start); a score good enough asks ENTER YOUR NAME PILOT for TODAY'S BEST PILOTS. The title: PRESS FIRE TO PLAY,
'ENTER' SELECTS KEYS; the fire pressed picks the control method (`$C011`): keys 1-5 (method 1), the defined keys (2),
Kempston (3, only when the probe `$73EC` leaves `$7A8B` = 0), keys 6-0 (4).

### 6.0 The recordings

All on unreal-ng's 48K, muted, port bases 37780 and 37785, made by `tools/record.py` (a plan per kind); each keeps
its `session.ttd`, `l1.json`, `record.json` and `screens/` in its folder, its input script in
`tests/inputs/NAME.txt` (the start state, `TAPE` and `POKE` lines included), and replays with no divergence (each
L1's `replay.diverged` = 0). Frames are the recording's own. The level recordings poke `$91F2` = `$C9` (37362,201:
`RET` at the start of the life-lost path, the POKE file's absolute invincibility) into the recording's machine only;
the image never sees it.

How the levels were reached: a probe without TTD (`work/stage1/probe/chain.py a3-end.szx 110000 1000 ch 91F2=C9`,
`chain.log`) ran an autopilot (fire in bursts, weaving) from a level 1 state of earlier probes through the whole
tape and saved a state at each step of the level digit and the tape (`work/stage1/probe/ch-*-L<n>-*.szx`): level 2 at
its frame 3045, 3 at 17 964, 4 at 28 960, 5 at 45 801, 6 at 58 853, 7 at 70 170, 8 at 85 560, `'9'` at 94 961, `'0'`
at 96 416, `'1'` at 96 794. Each level recording starts from the state where its digit was set, the tape wound to
that level's stop block.

| Name | Folder | Start | POKE | Frames | What it reached |
| --- | --- | --- | --- | ---: | --- |
| `c1` | `work/stage1/c1` | power-on, `LOAD ""`, the tape at signal speed ([1](#1-one-recording-from-power-on)) | none | 19 884 | SpeedLock 7, the entry at 11 700, REWIND SIDE 2, level 1's load (13 858-16 528), the title and TODAY'S BEST PILOTS, define keys (O P Q A M N), play on level 1: moves, fire, a charged beam, the Force detached and back, the pause, a life lost at 19 269 |
| `l1` | `work/stage1/rec/l1` | `c1/play.szx` (play start, level 1 in memory), tape at block 35 | `$91F2` | 15 260 | level 1 to its boss ([screen](docs/img/play/l1-014016-level1-boss.png)), the boss dead, the level 2 search at 14 960 |
| `l2` | `work/stage1/rec/l2` | `probe/ch-003045-L2-idle.szx`, tape at block 35 | `$91F2` | 15 932 | level 2's load and the level to its boss, the level 3 search at 15 631 |
| `l3` | `work/stage1/rec/l3` | `probe/ch-017964-L3-paused.szx`, block 38 | `$91F2` | 18 027 | level 3's load, the level and its end, the level 4 search at 17 726 |
| `l4` | `work/stage1/rec/l4` | `probe/ch-028960-L4-paused.szx`, block 41 | `$91F2` | 15 732 | level 4's load, the level and its boss, the level 5 search at 15 431 |
| `l5` | `work/stage1/rec/l5` | `probe/ch-045801-L5-paused.szx`, block 44 | `$91F2` | 13 694 | level 5's load, the level and its end, the level 6 search at 13 394 |
| `l6` | `work/stage1/rec/l6` | `probe/ch-058853-L6-paused.szx`, block 47 | `$91F2` | 11 107 | level 6's load, the level and its end, the level 7 search at 10 807 |
| `l7` | `work/stage1/rec/l7` | `probe/ch-070170-L7-playing.szx`, block 50 | `$91F2` | 15 581 | level 7's load, the level and its end, the level 8 search at 15 280 |
| `l8` | `work/stage1/rec/l8` | `probe/ch-085560-L8-paused.szx`, block 53 | `$91F2` | 10 200 | level 8's load, the level to its boss; the digit steps to `'9'` at 9900 with the boss still on screen |
| `ending` | `work/stage1/rec/ending` | `rec/l8/next.szx` (digit `'9'`) | `$91F2` | 2215 | level 8's boss gone (screens from 570), the digit `'0'` (`$C28B`), the title logo, REWIND SIDE 2 passed by the autopilot's keys, the digit `'1'` and SEARCHING FOR R TYPE LEVEL 1 at 1708 (the tape at its end); no closing text |
| `ctl-kempston` | `work/stage1/rec/ctl-kempston` | `c1/menu.szx` (the title) | none | 758 | Kempston fire on the title: method `$74FB` = 3; each direction, fire, a charged beam, SPACE (detach) |
| `ctl-if2` | `work/stage1/rec/ctl-if2` | `c1/menu.szx` | none | 758 | key 5 (fire) on the title: method 1; the keys 1-5 |
| `ctl-sinclair` | `work/stage1/rec/ctl-sinclair` | `c1/menu.szx` | none | 758 | key 0 (fire) on the title: method 4; the keys 6-0; a life lost at about 492 |
| `gameover` | `work/stage1/rec/gameover` | `c1/play.szx` | none | 8959 | every life lost on level 1 (the last at 3615), MISSION OVER, CONTINUE 9 to 0 with no key, the score 006600 too low for the table, the title again |
| `continue` | `work/stage1/rec/continue` | `c1/play.szx` | none | 5413 | MISSION OVER, FIRE at CONTINUE: CREDIT 5 to 4 (`$72CB`), play again on level 1 with the score from 0 |
| `hiscore` | `work/stage1/rec/hiscore` | `c1/play.szx` | the score `$71C9` = "045000" | 7459 | game over with 052600, ENTER YOUR NAME PILOT at 5247: up and down change the letter, fire enters it; "AABAAAAAA" 052600 at No. 5 of TODAY'S BEST PILOTS |
| `hiscore-typed` | `work/stage1/rec/hiscore-typed` | `c1/play.szx` | the score `$71C9` = "045000" | 7083 | the same, the name typed with letter keys (A G E N T ENTER): the letter keys change nothing |

What no recording reached, and why:

- **The closing text.** Level 8's object table holds THANKS TO YOUR BRAVE FIGHTING ... THE PROGRAMMER. at `$CAFF`;
  after level 8 the game goes to the title and asks for level 1 ([doc 3, 3.2](docs/03-build-and-load.md#32-the-level-loader)),
  and no recording reads those bytes. What shows the text (perhaps play without the POKE, or a condition in level
  8's own code) is open for stage 2.
- **Every enemy, hazard and way to die, named.** The level recordings fly with the invincibility POKE, so deaths are
  seen only on level 1 (c1, gameover, continue, hiscore, ctl-sinclair: the collision path `$956D` and the `$7A95`
  path `$9574` both taken). The enemies are on the screens and in the object sheets but are not yet named object by
  object; the pick-ups (the jewels' weapons) are seen on screens (the reflecting laser in l2, l4, l8) but not listed
  per kind.
- **Every sound, named.** The beeper `OUT`s that run in play are `$FAA2` and `$FB52` (all 16 recordings; also
  `$86F6`, the border), driven by the tasks `$F8E8-$F908`; `$8FB7` is the level loader's border
  (`work/stage1/sound-outs.txt`). Which effect is which is stage 2.
- **The level 1 start of the probe chain** is not a TTD recording; the level recordings that follow from it are.

### 6.1 The screens

Every screen the documents link, from the recordings' `screens/` (the recording's frame in the name):

| Recording, frame | Screen |
| --- | --- |
| `c1` 1984 | [the BASIC loader](docs/img/play/c1-001984-basic-loader.png) |
| `c1` 11 784 | [the loading screen with STOP THE TAPE !](docs/img/play/c1-011784-loading-screen.png) |
| `c1` 13 784 | [REWIND SIDE 2 THEN PRESS ANY KEY](docs/img/play/c1-013784-rewind-side2.png) |
| `c1` 13 858 | [SEARCHING FOR R TYPE LEVEL 1](docs/img/play/c1-013858-searching-level1.png) |
| `c1` 16 528 | [R TYPE LEVEL 1 LOADED OK](docs/img/play/c1-016528-level1-loaded.png) |
| `c1` 16 828 | [the title](docs/img/play/c1-016828-title.png) |
| `c1` 17 278 | [TODAY'S BEST PILOTS](docs/img/play/c1-017278-best-pilots.png) |
| `c1` 17 858 | [define keys: PRESS A KEY FOR LEFT](docs/img/play/c1-017858-define-keys.png) |
| `c1` 18 302 | [level 1, the start](docs/img/play/c1-018302-level1-start.png) |
| `c1` 18 630 | [the charged beam fired](docs/img/play/c1-018630-beam-fired.png) |
| `c1` 18 778 | [the pause: PILOT STAND BY !](docs/img/play/c1-018778-pause.png) |
| `ctl-kempston` 296 | [play on the Kempston](docs/img/play/ctl-kempston-000296-moved.png) |
| `l1` 7009, 14 016 | [level 1](docs/img/play/l1-007009-level1.png), [its boss](docs/img/play/l1-014016-level1-boss.png) |
| `l2` 7523, 14 504 | [level 2](docs/img/play/l2-007523-level2.png), [its boss](docs/img/play/l2-014504-level2-boss.png) |
| `l2` 9013 | [31 frames after the longest pass](docs/img/play/l2-009013-near-heaviest-pass.png) |
| `l3` 8505, 16 513 | [level 3](docs/img/play/l3-008505-level3.png), [its end](docs/img/play/l3-016513-level3-end.png) |
| `l4` 7523, 14 018 | [level 4](docs/img/play/l4-007523-level4.png), [its boss](docs/img/play/l4-014018-level4-boss.png) |
| `l5` 6504, 12 007 | [level 5](docs/img/play/l5-006504-level5.png), [its end](docs/img/play/l5-012007-level5-end.png) |
| `l6` 5004, 9520 | [level 6](docs/img/play/l6-005004-level6.png), [its end](docs/img/play/l6-009520-level6-end.png) |
| `l7` 7515, 14 010 | [level 7](docs/img/play/l7-007515-level7.png), [its end](docs/img/play/l7-014010-level7-end.png) |
| `l8` 4506, 8505 | [level 8](docs/img/play/l8-004506-level8.png), [its boss](docs/img/play/l8-008505-level8-boss.png) |
| `ending` 1808 | [after level 8: SEARCHING FOR R TYPE LEVEL 1](docs/img/play/ending-001808-searching-level1.png) |
| `continue` 3796 | [MISSION OVER !](docs/img/play/continue-003796-mission-over.png) |
| `gameover` 4165 | [CONTINUE counting down](docs/img/play/gameover-004165-continue-countdown.png) |
| `continue` 3913 | [CONTINUE, PRESS FIRE BUTTON, CREDIT 4](docs/img/play/continue-003913-press-fire.png) |
| `hiscore` 5247 | [ENTER YOUR NAME PILOT !](docs/img/play/hiscore-005247-enter-name.png) |
| `hiscore` 5959 | [the table with the new name](docs/img/play/hiscore-005959-table.png) |

The level maps and object sheets drawn from the data are in [doc 2, 2.4](docs/02-architecture.md#24-the-levels-from-their-data).

## 7. Review
