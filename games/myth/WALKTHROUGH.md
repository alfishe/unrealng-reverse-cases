# Myth: History in the Making: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number. Here no
recording uses the trap: c1 loads the whole tape at signal speed (`fast_tape` and `turbo_tape` off), and the stage
recordings start from the RZX run's snapshots, taken by its player right after each stage block was loaded.

## 0. The medium

1. **The original.** ZXDB 3354 lists download 20803, `Myth-HistoryInTheMaking.tzx.zip`, as "Original release (O)";
   it is in `orig/` unchanged (hashes in the [README](README.md)). Its TZX's archive info: System 3 Software Ltd,
   Concept Animations: Neil Dodwell, Dave Dew, 1989, £9.99, "Speedlock 7", "Original", "TZXed by Andrew Barker".
2. **The other copies.** Every copy in the collection and its sources went unchanged into `work/candidates/<source>/`
   and `tools/copy_compare.py orig.tzx work/candidates --out work/stage1/copy-compare.tsv` compared each TAP and TZX
   block by block (`=oN` the same block, `~oN:K` the same length with K bytes different, `run` a run of an original
   block inside another). Findings, in the README's table: the main block and the five stage blocks are plain on the
   tape (flag `$56`, no cipher) and every copy carries them; the Kixx re-release and two other TZX dumps hold every data
   block byte for byte; the TAP re-saves, the trainer and the hacks put their own loaders in front; the Russian
   translations change 1058-1068 bytes of the main block and 277 of stage 5. The hackersanon POKE file and the TOSEC
   "(Rainbird)(+3)" tapes are filed under the wrong "Myth" (ZXDB 11949, Magnetic Scrolls' text adventure).
3. **The blocks.** `tools/tzxblocks.py list` gives 53 TZX blocks, 815.9 s with the pauses:
   [doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block). A BASIC "MYTH" with one hidden-number line,
   two Speedlock 7 groups (171 bytes; then 6144, 768, 1150 and smaller pieces each behind a 3-byte `$07` piece), the
   15 360-byte main block and five 33 792-byte stage blocks, each followed by a stop block (ID `$20`, pause 0) and
   named by a text block. The main block and every stage block load at `$6C3F`: proved by comparing each block with the
   RZX run's snapshots (`snap0` = the menu holds the main block at `$6C3F`, `snap1-5` each hold their stage block
   there, all bytes equal).
4. **The machine.** The tape is 48K/128K. The 128K snapshots of the RZX run have RAM 1, 3, 4 and 6 empty; the game
   writes the AY ports from the interrupt (AyFrame `$F78A`, `OUT ($FFFD)` at `$F857`, `OUT ($BFFD)` at `$F85B`, 88 and
   89 runs in c1) and never `OUT ($FE)` in play, so the 128K adds the sound effects and nothing else.
5. **The tape model.** unreal-ng's tape follows the loader: it pauses when nothing reads the EAR port for a while
   and plays on when a loader listens (`core/src/emulator/io/tape/tape.cpp`, `TAPE_BLOCK_HOLD_FRAMES`); a stop block
   leaves the cursor on it. Pressing PLAY again during the Speedlock load broke it (the first c1 attempt hung at
   `$FD11` in the edge loop); PLAY is pressed once, after `LOAD ""`, and once more at "PRESS PLAY ON TAPE" for a stage.

## 1. One recording from power-on

**c1** (`work/stage1/c1`, `python3 tools/record.py c1 --work work/stage1/c1`; script `tests/inputs/c1.txt`): a 48K
from power-on, `LOAD ""` typed (J, SYMBOL SHIFT+P twice, ENTER), PLAY at frame 234, the original tape at signal
speed by its own loader; 16 658 frames, L1 built (148 773 035 instructions, 2516 interrupts, 667 checkpoints checked,
0 diverged).

| Frame | What happens (c1) |
| ---: | --- |
| 234 | PLAY; the ROM loads the header and the BASIC |
| 1963 | the BASIC's code runs at `$5D06` (stage 0); the chain's 103 layers decrypt `$EDE4-$FF25` up to frame 2189 (stage 1 counted 31 from the L1's arrivals; [doc 3, 3.3](docs/03-build-and-load.md)) |
| 2387 | the Speedlock loader `$FF26` reads the protected blocks |
| 5166 | the resident code is copied to `$E000-$FFFF` and entered at `$F040`; IM 2 is set (SetIm2 `$F635`) |
| 5167-7734 | the turbo loader TurboLoad `$FE90` (`$FE90-$FF53`, called by LoadBlock `$FF54`) loads the main block to `$6C3F-$A83E`; the tape stops on the stop block |
| 7826 | the main block is entered at `$7800`: the logo over a starfield drawn into the picture (static) ([logo](docs/img/play/logo.png)) |
| 7938 | SPACE: the credits cycle ([credits](docs/img/play/credits.png)) |
| 8310 | SPACE: the menu "PRESS SPACE TO SELECT", START GAME, DEFINE KEYS, SELECT JOYSTICK; the highlight moves by itself every 96 frames and SPACE takes the highlighted line ([menu](docs/img/play/menu.png)) |
| 8524 | SPACE on START GAME (the line blinks) |
| 8726 | "PRESS PLAY ON TAPE" ([press play](docs/img/play/press-play.png)); PLAY; stage 1 loads from frame 8626 |
| 14976 | the tape stops after stage 1: "STOP THE TAPE / STAGE ONE / THE ROAD TO HELL" (frame 15026, [stage title](docs/img/play/stage1-title.png)); the first room is drawn about 400 frames later |
| 15476 | stage 1 in play ([first room](docs/img/play/stage1-start.png)) in room 2: right, left, a jump, fire in each direction; room 2 to 8 at 15570 |
| 15890 | a life lost (lives `$FE61` 5 to 4 between 15880 and 15900; LoseLife at 15886). The SPACE presses at 15948 and 15951 fall in the respawn (hero state `$0F`), so no item window opens; the script's H pauses nothing (CheckPause `$79B1` reads ENTER, port `$BFFE` bit 0) |
| 16531 | room 8 to 7 |

### 1.1 Interrupts

- **IM 2.** SetIm2 `$F635` (`DI`, `JP HL` written at `$FEFE`, `I = $FD`, `IM 2`, `EI`; 3 runs in c1). The table
  `$FD00-$FE00` is 257 bytes of `$FE`, so every vector reads `$FEFE`. The Speedlock loader uses the same vector for
  its own handler while it loads (`$FEFE` tail `$FF16`, 49 152 of the 51 527 entries in c1: `rs.py interrupts`).
- **The game's handler** `$F9B3`: `EXX`, `EX AF,AF'`, CALL AyFrame `$F78A`, `EX AF,AF'`, `EXX`, `EI`, `RETI`. AyFrame
  steps three sound channels (8 bytes each at `$F85E`) and writes the AY registers through `$F854` (`OUT ($FFFD),D`,
  `OUT ($BFFD),E`). The handler does nothing else: no frame counter, no key reading. 2373 entries in c1.
- **DI / EI.** Play disables interrupts twice a pass: ClearBuffer `$9AB5` (`DI` ... `EI`, 381 runs in the play window)
  fills `$5B00-$6CFF` with zeros by `PUSH HL` with `SP = $6D00`, and CopyBuffer `$9ADA` (`DI` ... `EI` at `$9B6D`, 378
  runs) copies the buffer to the screen with `SP = $76A0` as a pointer table and an unrolled `LDI` chain whose end it
  patches (a `JP $9B45` written into the chain at `$9AF9`). An interrupt that falls in those windows is lost: 656
  interrupts in the 1182 play frames of c1 (15476-16658), 0.55 a frame.

### 1.2 The main loop and the frame

- **The main loop** of stage 1 is `$7839-$788E` (one instance of the loop in L1, 379 runs of `$7839` in the play
  window): 21 calls from `$795D` to `$8A54`, then CAPS SHIFT (port `$FEFE` bit 0) jumps to `$789C`, and the loop goes
  on while the lives `$FE61` or `$74EA` are not zero. The entry `$7800` stores the lives from H, builds the stage
  (`$9DA1`, `$97AC`, `$921E`, `$922F`), sets the room pointers `$FE23` = `$9B6F` and `$FE25` = `$9BA0` and falls into
  the loop.
- **No frame sync.** No `HALT` runs in the play window of c1 (the `HALT`s at `$7947`, `$F356`, `$F544`, `$F5FA` are the
  menu's and the stage loader's), and the handler keeps no counter: a pass takes as long as its work. A delay loop
  `$79AB` (`DEC BC` to zero, BC = `$0640` from `$79A8` or `$03E8` from `$7996`) pads some passes.
- **Frames per pass** (`python3 tools/passes.py --work work/stage1/c1o --window 15476-16658`, an access trace of c1's
  play kept in `work/stage1/c1o/traces/`; 168 passes until the trace's cap at frame 15995): median 207 960 T = 2.98
  frames a pass (about 17 passes a second), minimum 182 282 T (2.61 frames). Over 16158-16658 (a walk with one room
  change, 160 passes): median 208 992 T = 2.99 frames.
- **The heaviest pass** is the room change: 1 288 461 T = 18.44 frames, starting at 16531:33882, 17 interrupts in it
  (room 8 to 7: the next room is unpacked, built and drawn); the other heavy one is the first room change, room 2 to
  8, 1 318 737 T = 18.87 frames at 15570:3606. A frame is never idle in play: the CPU runs the pass from one end of the frame to the
  other.

## 6. The game

### 6.0 The recordings

Every recording keeps its `session.ttd` (the TTD session the analysis instance opens) and its `l1.json` in its folder:
`work/stage1/` (c1, c1o), `work/stage1/rec/` (stage 1's), `work/stage2/rec/` (stage 2's). None patches an image the
case is cut from. POKEs, all on the recording's own machine and listed in its record.json "pokes": the rzx-r seeds,
`stageload`'s 19 loader bytes and `ending`'s hit counts. No recording uses the LD-BYTES trap. Every command runs from
the case folder after `. work/env.sh`, on a muted instance with its own port base (`--port-base`).

| Recording | Command | Start (load) | Frames | L1 | What it reaches |
| --- | --- | --- | ---: | --- | --- |
| c1 | `python3 tools/record.py c1 --work work/stage1/c1` (`tests/inputs/c1.txt`) | 48K power-on, the original tape at signal speed | 16 658 | yes (`c1`; the play window `work/stage1/c1o` 15476-16658 with an access trace; the count windows `load`, `unxor`, `run`, `front` by `sh tools/c1_windows.sh`) | the whole load, the logo, the credits, the menu, the stage 1 load and title, stage 1 play: three rooms and a life lost ([section 1](#1-one-recording-from-power-on)) |
| menu | `python3 tools/record.py menu --work work/stage1/rec/menu --start work/stage1/c1/menu.szx` | c1's menu state | 1 880 | yes | DEFINE KEYS: UP X, DOWN K, LEFT L, RIGHT P, FIRE SPACE ([define keys](docs/img/play/define-keys.png)); the SELECT JOYSTICK taps landed on START GAME |
| deaths | `python3 tools/record.py deaths --work work/stage1/rec/deaths --start work/stage1/c1/stage1.szx` | c1's stage 1 state (48K) | 3 000 | yes | contact damage: energy `$FE3F` 46, 42, 38, 34, 30, 10, 2, then a life lost at frame 2775 (lives 5 to 4, energy refilled) |
| s1-idle | `python3 ../../kit/rs.py capture --work work/stage1/rec/s1-idle --snapshot work/stage1/rzx/snap1.z80 --model 128K --inputs tests/inputs/idle.txt --frames 20000 --ranges 4000-FFFF` | snap1 (stage 1 as loaded) | 20 000 | yes | stage 1's first room left alone: the enemies' patterns, no death |
| s1-right ... s5-right | the same with `--snapshot work/stage1/rzx/snapN.z80 --inputs tests/inputs/sj-walk-right.txt --frames 7940` | snap1-snap5 | 7 940 each | yes | walks to the right with fire and jumps, each to a game over (stage 5: none in the window) |
| rzx-s1 ... rzx-s5 | `python3 tools/rec_rzx.py --work work/stage1/rec/rzx-sN --from F --frames N` | the RZX run, cut by stage | 32 896, 19 172, 17 454, 24 404, 6 225 | no (the analysis instance cannot load a session with the RZX playback device) | superseded by rzx-r0 ... rzx-r5 |
| rzx-r0 ... rzx-r5 | `python3 tools/rzx_replay.py FROM TO --work work/stage2/rec/rzx-rN --port-base PB` | snap0-snap5 (128K), the RZX's keys by pass (`tests/inputs/rzx-rN.txt`), its random seeds written to `$FE0A` (record.json) | 2 063, 30 834, 19 175, 17 455, 24 405, 6 225 | yes | the RZX run replayed pass by pass with 0 divergences: the menu, the five stages, every boss beaten, the ending (rzx-r5 WELL DONE at 5663-6037) |
| joystick | `python3 tools/record.py joystick --work work/stage2/rec/joystick --start work/stage1/c1/menu.szx` | c1's menu state (48K, a Kempston card) | 9 706 | yes (window `front` 0-8899) | SELECT JOYSTICK: CURSOR, SINCLAIR, LEAVE, KEMPSTON in turn |
| stageload | `python3 tools/record.py stageload --work work/stage2/rec/stageload --start work/stage2/rzx/snap-032880.z80 --model 128K` | the RZX run's state at its frame 32 880 (STAGE TWO's title), a POKE writing back the original's loader bytes `$FEBB-$FECD` over the RZX release's patch | 7 392 | yes | stage 2 loaded from tape block 36 (the emulator's numbering; 34, 36, 38, 40, 42 for stages 1-5) by the resident loader, then played |
| ending | `python3 tools/record.py ending --work work/stage2/rec/ending --start work/stage1/rzx/snap5.z80 --model 128K` | snap5; POKEs at 2420, 3020, 3620, 4220: `$FE44` = 19, `$FE41` = 1 (the 20th hit of each phase pending) | 10 820 | yes | Dameron's four forms beaten and the ending text |

The RZX run is `work/candidates/rzxarchive/myth.rzx` (SPIN 0.5, 128K, 100 151 frames, six input blocks, each block a Z80
snapshot taken by its player after a stage block loaded), someone else's game: used, and said so, for the stages no
keyed play of ours reached. The writers' analysis folders open these sessions again: `work/docs/myA/c1` (c1) and
`work/docs/myA/r1` (rzx-r1), each by `python3 ../../kit/rs.py open --work W --ttd SESSION.ttd`.

Every recording is under 100 000 frames. The walks press right in bursts (`sj-walk-right.txt`: the run's keys 9 8 6 7
0, which its player defined with DEFINE KEYS); the hero dies on the way, so each walk ends in a game over, apart from
stage 5.

### 6.1 The screens

| Screen | Where |
| --- | --- |
| [logo](docs/img/play/logo.png), [credits](docs/img/play/credits.png), [menu](docs/img/play/menu.png) | c1 frames 7834, 7938, 8310 |
| [define keys](docs/img/play/define-keys.png) | menu frame 146 |
| [press play](docs/img/play/press-play.png), [stage title](docs/img/play/stage1-title.png) | c1 frames 8726, 15026 |
| [stage 1, first room](docs/img/play/stage1-start.png), [cave](docs/img/play/stage1-cave.png), [graveyard](docs/img/play/stage1-graveyard.png), [life lost](docs/img/play/stage1-life-lost.png) | c1 15476, c1 16558, s1-right 1000, deaths 2775 |
| [stage 2 temple](docs/img/play/stage2-temple.png), [harpy](docs/img/play/stage2-harpy.png) | s2-right 1000, 2000 |
| [stage 3 longship](docs/img/play/stage3-longship.png), [prow](docs/img/play/stage3-prow.png) | s3-right 500, 2000 |
| [stage 4 pyramid](docs/img/play/stage4-pyramid.png) | s4-right 500 |
| [stage 5 text](docs/img/play/stage5-void.png), [Dameron](docs/img/play/stage5-dameron.png) | s5-right 1000, 2000 |
| [the countdown](docs/img/play/c1-04400-countdown.png), [the loading screen](docs/img/play/c1-05000-loading.png) | c1 4400, 5000 |
| [a low strike](docs/img/play/c1-16005-strike.png) | c1 16005 |
| [the demon](docs/img/play/rzx-r1-15300-demon.png), [the demon's burst](docs/img/play/rzx-r1-15400-demon-burst.png), [the teleport](docs/img/play/rzx-r1-30200-teleport.png) | rzx-r1 15300, 15400, 30200 |
| [HUD GAME OVER](docs/img/play/hud-game-over.png), [game-over screen](docs/img/play/game-over.png) | s1-right 4000, s4-right 4000 |

The figures drawn from recordings (not screens) say their recording and frames in their captions: [energy and
death](docs/img/play/energy-death.png) c1 15700-16300, [the jump's path](docs/img/play/jump-path.png) rzx-r1 3576-3632,
[a light pass](docs/img/play/pass-beam-light.png) and [the room change](docs/img/play/pass-beam-roomchange.png) against the
beam, c1 16200-16203 and 16538-16540.

The game-over screen offers RESTART THIS STAGE, RESTART FROM STAGE ONE, GAME CREDITS 3 and the score.

### 6.2 Levels, objects and state

**The levels.** There are five stages. Each is one 33 792-byte block at `$6C3F-$F03E`, loaded over the last one by
the resident stage loader. Each holds its own code (run from `$7800`), map, graphics and enemies. Stage 1's map
format: [doc 7, 7.1](docs/07-objects.md#71-the-stages-data-tiles-blocks-and-a-map): a packed block at `$B4B2`,
unpacked to `$5B00` at every room change, with three grids of 2 x 2-tile blocks. A room is a 14 x 9-block window;
the other stages: doc 7, 7.9.

**The state variables.** Witnesses are the deaths and walk recordings and the code at the named addresses.

| What | Where | Witness |
| --- | --- | --- |
| lives | `$FE61` (stage), set from H at the entry `$7800`, `DEC` at `$7ED4` | deaths: 5 to 4 at frame 2775 |
| energy | `$FE3F`, 0 (a life lost) to `$2E` (full); pending change `$FE4E` (`$80` and up drains, under `$80` refills) | deaths: 46 down to 2, refilled after the life |
| game over | `$FE5B` = 1 when the lives reach 0; the main loop `$7839` ends when `$FE61` and `$74EA` are 0 | s1-right to s4-right |
| room | column `$FE21`, row `$FE22`, grid record `$FE23` (`$9B6F` at the start) | c1's room change at 16531 |
| score | `$F9FB`, a word in the resident part, so it carries from stage to stage; printed by `$8BE3` through the table `$F9BF` | the HUD: 0, 18019, 27919, 44018 at the starts of stages 1-4 in the run |
| score, high part | ScoreHigh `$F9FD` (ten thousands), printed by ByteToDigits `$8C15` | rzx-r1 passes 10 000 at frame 9484 |
| carried objects | CarriedItems `$7F17` (12 kinds), CarriedCounts `$7F23`, ItemSelected `$FE17`; the item strip and the item window (SPACE) | rzx-r1: the shield taken at 712 (ItemLast `$FE18` 6 to 7) |
| keys | the readers `$FC90-$FCDA`: a port and a bit for each, written by DEFINE KEYS | menu (X K L P SPACE); the RZX run's keys 9 8 6 7 0, defined with DEFINE KEYS, read port `$EFFE` |

**The images and what changes.** These are the image as loaded, the image at the entry, and the image in play.
- **As loaded:** `tools/image.py` cuts `stage1.bin` to `stage5.bin` from the TZX. Each one is byte for byte the RZX
  snapshot of its stage over `$6C3F-$F03E`. `case.json` builds stage 1's image.
- **At the entry and in play:** stage 1's image against c1's memory at frame 15476 (just in play) and at its end
  (16658) differs in 2446 and 2554 bytes. These fall in two places:
  - the variables and tables `$6D00-$7759`;
  - the self-modified bytes `$79E5-$79F6`, `$98D3`, `$98F1`, `$9A1C`, the copy chain's patch `$9B46-$9B51`, Unrle's
    escape `$A42F` and `$A438`, `$A5D4`, `$A6E0`, `$A779`, `$9F2F-$9F3B`, `$9F85-$9F91` and `$B30D`.
- **Per stage, in its walk,** the writes inside the block are:
  - stage 1: 2939 bytes, one long run `$6D00-$779B`;
  - stage 2: 2983 bytes, `$6D00-$77B9`;
  - stage 3: 2806 bytes, `$6D00-$777B`;
  - stage 4: 3013 bytes, `$6C3F-$771D` and `$9DAB-$9E1A`;
  - stage 5: 1155 bytes, `$6D00-$707F`, `$75E0-$766F` and `$BA86-$BAC5`.

  Everything else in each block is read-only code and data.

**Reached in stage 2.** What stage 1 left unreached: the ending (rzx-r5 and `ending`), the SELECT JOYSTICK screens
(`joystick`), the bosses with an L1 (rzx-r1 to rzx-r5), a stage loaded from the tape (`stageload`: LoadBlock `$FF54`
compares the block's byte `$BB80` with StageCheck `$FF7F` + stage - 1 and loads again on a mismatch; START GAME always
asks for stage 1, which is why the stage 1 seek waited on STAGE ONE). The sound: the AY effects are decoded from the
data and rendered to files ([doc 9](docs/09-sound.md)); nothing was played.

### 6.3 The animations

| File | Document | Recording | Frames |
| --- | --- | --- | --- |
| [load-chain.gif](docs/img/play/load-chain.gif) | [doc 3](docs/03-build-and-load.md) | c1 | 1966-2390 |
| [load-screen.gif](docs/img/play/load-screen.gif) | doc 3 | c1 | 2380-4300 |
| [load-countdown.gif](docs/img/play/load-countdown.gif) | doc 3 | c1 | 2380-5170 |
| [Unxor.gif](docs/img/routines/Unxor.gif) | doc 3 | c1 | 5164-5167 |
| [load-front.gif](docs/img/play/load-front.gif) | doc 3 | c1 | 5167-7830 |
| [load-stage1.gif](docs/img/play/load-stage1.gif) | doc 3 | c1 | 8600-15080 |
| [MainLoop.gif](docs/img/routines/MainLoop.gif) | [doc 4](docs/04-game-loop.md) | c1 | 16200-16203 |
| [keys-hero.gif](docs/img/play/keys-hero.gif) | [doc 5](docs/05-controls.md) | c1 | 15590-15890 |
| [ItemWindow.gif](docs/img/routines/ItemWindow.gif) | doc 5 | rzx-r1 | 965-1179 |
| [ClearBuffer.gif](docs/img/routines/ClearBuffer.gif) | [doc 6](docs/06-rendering.md) | c1 | 16202 |
| [DrawActors.gif](docs/img/routines/DrawActors.gif) | doc 6 | c1 | 16202-16203 |
| [CopyBuffer.gif](docs/img/routines/CopyBuffer.gif) | doc 6 | c1 | 16204-16205 |
| [RoomChange.gif](docs/img/routines/RoomChange.gif) | doc 6 | c1 | 16533-16546 |
| [warrior-walk.gif](docs/img/play/warrior-walk.gif) | [doc 7](docs/07-objects.md) | c1 | 16196-16262 |
| [urn-strike.gif](docs/img/play/urn-strike.gif) | doc 7 | rzx-r1 | 624-672 |
| [RunActorHandlers.gif](docs/img/routines/RunActorHandlers.gif) | doc 7 | c1 | 16202-16211 |
| [RoomCells.gif](docs/img/routines/RoomCells.gif) | doc 7 | c1 | 16536-16538 |
| [WarriorActor.gif](docs/img/routines/WarriorActor.gif) | doc 7, doc 10 | c1 | 16240 |
| [hud-start.gif](docs/img/play/hud-start.gif) | [doc 8](docs/08-hud-and-text.md) | rzx-r1 | 60-340 |
| [RevealStrip.gif](docs/img/routines/RevealStrip.gif) | doc 8 | c1 | 8007-8023 |
| [RevealText.gif](docs/img/routines/RevealText.gif) | doc 8 | c1 | 8560-8579 |
| [ShowScore.gif](docs/img/routines/ShowScore.gif) | doc 8 | rzx-r1 | 663 |
| [ay-registers.gif](docs/img/play/ay-registers.gif) | [doc 9](docs/09-sound.md) | rzx-r1 | 632-729 |
| [AyFrame.gif](docs/img/routines/AyFrame.gif) | doc 9 | rzx-r1 | 712 |
| [jump.gif](docs/img/play/jump.gif) | [doc 10](docs/10-gameplay-logic.md) | rzx-r1 | 3576-3632 |
| [shot.gif](docs/img/play/shot.gif) | doc 10 | rzx-r1 | 2310-2390 |
| [demon.gif](docs/img/play/demon.gif) | doc 10 | rzx-r1 | 15200-15540 |
| [teleport.gif](docs/img/play/teleport.gif) | doc 10 | rzx-r1 | 29590-29880 |
| [death.gif](docs/img/play/death.gif) | doc 10 | c1 | 15860-16240 |
| [HeroDeath.gif](docs/img/routines/HeroDeath.gif) | doc 10 | c1 | 15886 |

Each caption gives the command that made it (`kit/screen_anim.py`, `kit/memanim.py`, `kit/routine_anim.py`,
`tools/anim_keys.py`, `tools/fig_sound.py regs`); `W` in doc 3 is an analysis folder opened on c1's session.
