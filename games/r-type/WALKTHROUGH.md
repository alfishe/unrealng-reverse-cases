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
([doc 3, 3.9](docs/03-build-and-load.md#39-the-games-level-loader)). ZXDB says the first tapes had level 7 twice and no
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
BASIC's code `$5D06` at frame 2081, the decryption chain at `$EC00-$FB7E` (26 code arrivals, 119 rewrite loops, [doc 3, 3.3](docs/03-build-and-load.md#33-the-decryption-chain-119-rewrite-loops)) in frames 2083-2398, the edge loader
`$FEE8` at frame 2599, the tail `$61A8` and the game's entry `$85FD` at frame 11 700 T 1379. Then REWIND SIDE 2 THEN
PRESS ANY KEY (frame 13 784, SPACE), SEARCHING FOR R TYPE LEVEL 1 and the level 1 load (frames 13 858-16 528), R TYPE
LEVEL 1 LOADED OK, the title cycle (16 828-17 578: the title, TODAY'S BEST PILOTS), ENTER and the keys defined
(17 858-18 134: O P Q A M N), play from 18 302 (moves, fire, a charged beam; a life lost between frames 18 620 and 18 660, so the CAPS SHIFT+1
pressed during PILOT STAND BY ! paused nothing; another life lost at 19 269). The Force never came: c1 takes no
pick-up, and the detach `$95BC` never runs (the pause and the detach have their own recordings, 6.0).

The interrupts and the timing, a first look:

- **IM mode and handler.** IM 2. The entry `$85FD` runs `DI`, sets `SP` to `$FFFE`, and at `$8624-$862A` sets
  `I` = `$84`, `IM 2` and `EI`; the table `$8400-$8500` is all `$83`, so every interrupt goes to `$8383`, which holds
  `JP $BE23`. The handler `$BE23` saves the registers, adds 1 to IntTicks `$7A8A` and walks the task table
  at `$BE60`: 5 entries of 5 bytes (address, mask, counter, reload). The tasks are `$BE79`, `$F8E8`, `$F8F8` and
  `$F908` (mask 1, reload 3: each runs every third interrupt) and `$76CB` (mask 0: off in play). c1's L1 counts 5584
  interrupts: 143 in the ROM's `$0038` before the entry and 5441 entries of `$8383` (`$RS interrupts`), 4237 T an
  entry on average (1.7 % of the CPU).
- **DI and EI.** `DI` at `$85FD` (the entry) and `EI` at `$862A`; the level loader `$8F1F` starts with `DI` and
  pushes `$FEC0`, where `EI` follows its return ([doc 3, 3.9](docs/03-build-and-load.md#39-the-games-level-loader)): the
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
  enemies, the bouncing laser's lines and the Force on screen at once. What makes the pass long: three small
  explosions (sound `$08`) hold all three sound channels and their noise bursts run inside the interrupt, about
  30 000 T a frame ([doc 4, 4.6](docs/04-game-loop.md#46-what-a-pass-costs-against-the-beam),
  [doc 9, 9.8](docs/09-sound.md#98-the-cost-the-12-frame-pass)).

## 2. Static pass over the medium

`tools/tzxblocks.py`, `tools/tape_table.py` (the block table of [doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)),
`tools/basic_list.py` (the BASIC and its hidden number, 3.2), `tools/speedlock7.py layers` (the 119 rewrite loops of
the decryption chain, 3.3), `tools/media_compare.py` (the copies, 0).

## 3. The stages and the packers

No packer. The stages: power-on, the BASIC's code `$5D06`, the decryption chain at `$EC00`, SL7Start and the reader
`$FB7E`, the second stage `$FEE8` with the loading screen and the countdown, Stage2End, Decipher `$FE40`, the Tail
`$61A8` and the game's entry `$85FD` (c1 frame 11 700); each level then by the game's LoadLevel `$FE03`
([doc 3](docs/03-build-and-load.md), 3.4-3.9).

## 4. The medium from source

Stage 2 (`work/stage2/NOTES.md`): every part written by `kit/mkgame.py` from its `.ann` (the BASIC, the chain, the
second stage, the game, the eight levels), 70 resources in `src/res`, `tools/build.sh` builds the tape with the
re-encryption and compares it with the original byte for byte ([doc 3, 3.13](docs/03-build-and-load.md#313-the-build)).

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
| `c1` | `work/stage1/c1` | power-on, `LOAD ""`, the tape at signal speed ([1](#1-one-recording-from-power-on)) | none | 19 884 | SpeedLock 7, the entry at 11 700, REWIND SIDE 2, level 1's load (13 858-16 528), the title and TODAY'S BEST PILOTS, define keys (O P Q A M N), play on level 1: moves, fire, a charged beam, a life lost near 18 640 (CAPS SHIFT+1 pressed during PILOT STAND BY: no pause), another at 19 269; no Force (no detach) |
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
| `hiscore` | `work/stage1/rec/hiscore` | `c1/play.szx` | the score `$71C9` = "045000" | 7459 | game over with 052600, ENTER YOUR NAME PILOT at 5247: left and right change the letter, fire enters it; "AABAAAAAA" 052600 at No. 5 of TODAY'S BEST PILOTS |
| `hiscore-typed` | `work/stage1/rec/hiscore-typed` | `c1/play.szx` | the score `$71C9` = "045000" | 7083 | the same, the name typed with letter keys (A G E N T ENTER): the letter keys change nothing |

Stage 2 and the documents added these (the stage 2 recordings in `work/stage2/rec/`, rtB's `pause` in
`work/docs/rtB/rec/`, the integration's in `work/docs/integrate/rec/`; each with its `session.ttd`, `l1.json`,
`record.json`, `screens/` and `tests/inputs/NAME.txt`):

| Name | Folder | Start | POKE | Frames | What it reached |
| --- | --- | --- | --- | ---: | --- |
| `deaths-l7` | `work/stage2/rec/deaths-l7` | `rec/l6/next.szx` (the digit `'7'`), tape at block 50 | `$91F2` = `$CD`: the start state's RET undone | 8390 | level 7 without the immortality: 8 lives lost, every death path (`$956D` 4, `$9574` 1, `$C3CE` 3), a death under the shield at 8376 |
| `m128` | `work/stage2/rec/m128` | power-on on the 128K, the menu's Tape Loader | none | 18 754 | the same load on a 128K: the tail's `OUT ($7FFD)` once, the 48K ROM paged at the title and in play, level 1 as on the 48K |
| `pause` | `work/docs/rtB/rec/pause` | `c1/play.szx` | none | 310 | CAPS SHIFT+1 at 60: GAME PAUSED (`DI` at `$8B7F`, `$8B8F` once each), 150 frames still, CAPS SHIFT+2 at 220, play again |
| `force` | `work/docs/integrate/rec/force` | `c1/play.szx`, tape at block 35, `l1`'s keys to 2100 | `$91F2` (as `l1`) | 2356 | the Force taken as in `l1` (one TakePickup) and docked at the tail by 2126; N at 2144: the detach `$95DF` (2156, state 5), the Force waits (state 3, 2166), N again: the recall `$95F3` (2180, state 6), docked again (2250) |
| `boss` | `work/docs/integrate/rec/boss` | `c1/play.szx`, tape at block 35, `l1`'s keys until the boss tail is out (10 856) | `$91F2`; slot 2's hits `$850A` = 1 at 10 856, then `$850A` = 0 at 12 374 | 13 214 | level 1's boss: the shots did not reach slot 2, the POKE freed it, mover A9 called BossDestroyed `$C19C` at 12 375; BossBlastOnce's explosions (sounds `$09`/`$0A`) and sweep to 12 995 |
| `restart` | `work/docs/integrate/rec/restart` | `c1/play.szx` | `$91F2` = `$C9` from 0 to 2640, then `$CD` | 3167 | MapColumn 39 at 2640, LevelRestartColumn `$C4AE` = 29 (the checkpoint 37 - 8); a life lost to an enemy shot (`$C3CE`) at 2667; the next life at 2858 with MapColumn 37: its first screen from column 29 |

The commands (from the case folder, `source work/env.sh`; port base 37780, one instance at a time, each stopped
when its plan ends):

```bash
python3 tools/record.py deaths --work work/stage2/rec/deaths-l7 --port-base 37780 --start work/stage1/rec/l6/next.szx
python3 tools/record.py m128 --model 128k --work work/stage2/rec/m128 --port-base 37785
python3 work/docs/rtB/tools/rec_pause.py pause --work work/docs/rtB/rec/pause --port-base 37787 \
    --start work/stage1/c1/play.szx          # the same plan is tools/record.py pause
python3 tools/record.py force --work work/docs/integrate/rec/force --port-base 37780 --start work/stage1/c1/play.szx
python3 tools/record.py boss --work work/docs/integrate/rec/boss --port-base 37780 --start work/stage1/c1/play.szx
python3 tools/record.py restart --work work/docs/integrate/rec/restart --port-base 37780 --start work/stage1/c1/play.szx
```

`force` and `boss` replay `l1`'s keys (`tests/inputs/l1.txt`, the function `replay` of `tools/record.py`) from the
same start, so they follow `l1` frame for frame until their own keys or POKEs begin. Every recording reopens with
`python3 ../../kit/rs.py open --work DIR --ttd DIR/session.ttd --model 48K --port-base 37780 --binary $BIN`
(`--model 128K` for m128).

What no recording reached, and why:

- **The closing text.** Level 8's object 32 at `$CAFF` draws THANKS TO YOUR BRAVE FIGHTING ... THE PROGRAMMER.;
  level 8's wave script ends the game at column 66, before the kinds that would draw it (columns 67-73), so no
  recording reads those bytes ([doc 8, 8.9](docs/08-hud-and-text.md#89-the-closing-text-that-never-shows)).
- **A boss killed by hits.** No recording's shots destroyed a boss part that ends a level; `boss` reaches
  BossDestroyed `$C19C` only through a POKE (above). L1BossHit `$F42D` and mover A3's kill count `$F3C6` never ran.
- **Sounds `$07`, `$0B`, `$17`, `$1F`-`$21`**: no code or wave started them; doc 9 renders them from the table.
- **The other items known only from the code** are listed at the end of each document (1.7, 3.15, 9.11, 10.16 and
  the rest).
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
| `c1` 18 778 | [PILOT STAND BY ! after the life lost near 18 640 (CAPS SHIFT+1 pressed here paused nothing)](docs/img/play/c1-018778-pause.png) |
| `ctl-kempston` 296 | [play on the Kempston](docs/img/play/ctl-kempston-000296-moved.png) |
| `l1` 7009, 14 016 | [level 1](docs/img/play/l1-007009-level1.png), [its boss](docs/img/play/l1-014016-level1-boss.png) |
| `l2` 7523, 14 504 | [level 2](docs/img/play/l2-007523-level2.png), [its boss](docs/img/play/l2-014504-level2-boss.png); the same frame against its buffers: [frame-l2-7523](docs/img/render/frame-l2-7523.png) (doc 6, 6.8) |
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

Two contact sheets of these screens (`tools/fig_screens.py`, doc 1):
[the screens around play](docs/img/play/screens-around.png) and [the eight levels](docs/img/play/screens-levels.png).
The level maps drawn from the data are in [doc 1, 1.4](docs/01-game-design.md#14-the-eight-levels), the levels in
memory in [doc 2, 2.3](docs/02-architecture.md#23-the-levels-in-memory).

### 6.2 The animations

Every GIF the documents link, with the recording and the frames it was cut from (`frame:T` for a window inside a
frame). The writers' work folders (`work/docs/rtA`, `rtB`, `rtC`) hold the windows and traces cut from these
recordings; the command of each is in its caption.

| File (`docs/img/`) | Document | Recording | Frames |
| --- | --- | --- | --- |
| `play/title-cycle.gif` | doc 1 | `c1` | 16 540-17 900, every 20th |
| `play/life-lost.gif` | docs 1, 10 | `c1` | 19 230-19 884, every 8th |
| `play/load-chain.gif` | doc 3 | `c1` | 2078-2400, every 7th (memory) |
| `play/load-screen.gif` | doc 3 | `c1` | 2600-4500, every 40th (memory) |
| `play/load-countdown.gif` | doc 3 | `c1` | 4300-11 800, every 150th |
| `play/load-level1.gif` | doc 3 | `c1` | 13 780-16 560, every 60th (memory) |
| `routines/Decipher.gif` | doc 3 | `c1` | 11 680:0-11 700:1500 |
| `routines/MainLoop.gif` | doc 4 | `l2` | 8961-8966 |
| `play/level-start-l2.gif` | doc 4 | `l2` | 0-2780, every 60th (memory) |
| `play/level-start-l2-screen.gif` | doc 4 | `l2` | 2640-2800, every 2nd |
| `routines/ReadControls.gif` | doc 5 | `c1` | 18 819:25 700-18 819:26 400 |
| `play/ship-keys.gif` | doc 5 | `c1` | 18 812-19 072, every 3rd |
| `routines/MoveShip.gif` | docs 5, 10 | `c1` | 18 819:26 380-18 819:33 000 |
| `play/beam-charge.gif` | docs 5, 8, 10 | `c1` | 18 474-18 630, every 2nd |
| `play/pause.gif` | doc 5 | `pause` | 40-310, every 3rd |
| `play/name-entry.gif` | doc 5 | `hiscore` | 5236-5800, every 4th |
| `play/scroll-edge.gif` | doc 6 | `l2` | 7500-7660, one a pass |
| `routines/ScrollNewColumn.gif` | doc 6 | `l2` | 7529:27 400-7530:3100 |
| `routines/ScrollRows.gif` | doc 6 | `l2` | 7535:19 300-7538:46 300 |
| `routines/DrawSprite.gif` | doc 6 | `l2` | 7538:48 400-7539:46 000 |
| `routines/DrawFirstScreen.gif` | doc 6 | `l2` | 2750:64 000-2757:52 000 |
| `play/l1-waves-slots.gif` | doc 7 | `l1` | 190-1400, every 20th (memory) |
| `routines/MoveEnemies.gif` | doc 7 | `l1` | 202:11 000-202:14 210 |
| `routines/StartWave.gif` | doc 7 | `l1` | 202:14 100-202:15 460 |
| `routines/L1MoverA12.gif` | doc 7 | `l1` | 3270:21 800-3270:23 600 |
| `routines/L1MoverA8.gif` | docs 7, 10 | `l1` | 13 518:19 900-13 518:24 600 |
| `play/l1-boss-blast.gif` | docs 7, 10 | `l1` | 13 500-13 600, every 4th |
| `play/hud-extra-life.gif` | docs 8, 10 | `l2` | 11 990-12 130, every 2nd |
| `routines/DrawHud.gif` | doc 8 | `l2` | 12 088:54 300-12 090:14 500 |
| `routines/PrintHiScores.gif` | doc 8 | `hiscore` | 5461:15 900-5464:5480 |
| `routines/SoundTask3.gif` | doc 9 | `l1` | 2058:2300-2058:66 000 |
| `routines/NoiseBurst.gif` | doc 9 | `l2` | 8982:2100-8982:33 500 |
| `play/l1-pickup-force.gif` | doc 10 | `l1` | 2040-2100, every 2nd |
| `routines/TakePickup.gif` | doc 10 | `l1` | 2056:38 700-2056:47 000 |
| `routines/ForceDraw.gif` | doc 10 | `l1` | 2083:16 000-2083:19 600 |
| `routines/BeamRelease.gif` | doc 10 | `l1` | 5452:22 000-5452:66 000 |
| `play/l1-bits.gif` | doc 10 | `l1` | 8430-8478, every 2nd |
| `play/l1-missiles.gif` | doc 10 | `l1` | 9320-9380, every 2nd |
| `play/l1-level-end.gif` | doc 10 | `l1` | 14 560-14 860, every 6th |
| `play/d7-death-wall.gif` | doc 10 | `deaths-l7` | 3814-3874, every 2nd |
| `routines/ShipDies.gif` | doc 10 | `deaths-l7` | 3824:16 900-3824:32 100 |
| `play/d7-death-shot.gif` | doc 10 | `deaths-l7` | 4340-4372, every frame |
| `play/d7-shield-death.gif` | doc 10 | `deaths-l7` | 8350-8384, every frame |

## 7. Review
