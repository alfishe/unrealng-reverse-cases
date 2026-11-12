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
| 1963 | the BASIC's code runs at `$5D06` (stage 0); 31 layers decrypt `$EDE4-$FF25` up to frame 2189 |
| 2387 | the Speedlock loader `$FF26` reads the protected blocks |
| 5166 | the resident code is copied to `$E000-$FFFF` and entered at `$F040`; IM 2 is set (SetIm2 `$F635`) |
| 5167-7734 | the turbo loader `$FF02` loads the main block to `$6C3F-$A83E`; the tape stops on the stop block |
| 7826 | the main block is entered at `$7800`: the logo over a starfield ([logo](docs/img/play/logo.png)) |
| 7938 | SPACE: the credits cycle ([credits](docs/img/play/credits.png)) |
| 8310 | SPACE: the menu "PRESS SPACE TO SELECT", START GAME, DEFINE KEYS, SELECT JOYSTICK; the highlight moves by itself about every 95 frames and SPACE takes the highlighted line ([menu](docs/img/play/menu.png)) |
| 8524 | SPACE on START GAME (the line blinks) |
| 8726 | "PRESS PLAY ON TAPE" ([press play](docs/img/play/press-play.png)); PLAY; stage 1 loads from frame 8626 |
| 14976 | the tape stops after stage 1: "STOP THE TAPE / STAGE ONE / THE ROAD TO HELL" (frame 15026, [stage title](docs/img/play/stage1-title.png)); the first room is drawn about 400 frames later |
| 15476 | stage 1 in play ([first room](docs/img/play/stage1-start.png)): right, left, a jump, fire in each direction, the item window (SPACE), pause (H), a walk to the next room at 16531 |

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
  (the next room is unpacked, built and drawn); the other heavy one is the first pass after the stage starts, 1 318 737
  T = 18.87 frames at 15570:3606. A frame is never idle in play: the CPU runs the pass from one end of the frame to the
  other.

## 6. The game

### 6.0 The recordings

Every recording keeps its `session.ttd` in its folder under `work/stage1/`. None uses a POKE and none patches the
image. No recording uses the LD-BYTES trap. The stage recordings start from the RZX run's snapshots
(`work/candidates/rzxarchive/myth.rzx`, 100 151 frames, 6 blocks, 0 desyncs). Each snapshot was taken right after its
stage block loaded, at signal speed, by the player of that run.

| Recording | How (load) | Frames | L1 | What it reaches |
| --- | --- | ---: | --- | --- |
| c1 | 48K from power-on, `tests/inputs/c1.txt`, the original tape at signal speed | 16 658 | yes (`c1`, play window `c1o`) | the whole load, the logo, the credits, the menu, the stage 1 load and title, stage 1 play: two rooms ([section 1](#1-one-recording-from-power-on)) |
| menu | c1's menu state (`c1/menu.szx`), `tests/inputs/menu.txt` | 1 880 | yes | DEFINE KEYS: every prompt, UP to FIRE ([define keys](docs/img/play/define-keys.png)) and the keys taken; the SELECT JOYSTICK taps landed on START GAME instead (PRESS PLAY ON TAPE) |
| deaths | c1's stage 1 state (`c1/stage1.szx`), `tests/inputs/deaths.txt` | 3 000 | yes | contact damage: energy `$FE3F` 46, 42, 38, 34, 30, 10, 2, then a life lost at frame 2775 (lives `$FE61` 5 to 4, energy refilled; [life lost](docs/img/play/stage1-life-lost.png)) |
| s1-idle | snap1 (stage 1 as loaded, 128K), `tests/inputs/idle.txt` (no key) | 20 000 | yes | stage 1's first room left alone: the enemies' patterns, no death |
| s1-right | snap1, `tests/inputs/sj-walk-right.txt` (the run's Sinclair joystick keys) | 7 940 | yes | the graveyard over the caves ([graveyard](docs/img/play/stage1-graveyard.png)), the cave, every life lost, the HUD's GAME OVER ([HUD](docs/img/play/hud-game-over.png)), the game-over screen |
| s2-right | snap2 (stage 2 as loaded) | 7 940 | yes | the Greek temple ([temple](docs/img/play/stage2-temple.png)), the harpy ([harpy](docs/img/play/stage2-harpy.png)), the Medusa statue room, game over |
| s3-right | snap3 | 7 940 | yes | the Viking longship with the lightning ([longship](docs/img/play/stage3-longship.png)), its prow over the sea ([prow](docs/img/play/stage3-prow.png)), game over |
| s4-right | snap4 | 7 940 | yes | Egypt: the pyramid's steps ([pyramid](docs/img/play/stage4-pyramid.png)), game over and its screen ([game over](docs/img/play/game-over.png)) |
| s5-right | snap5 | 7 940 | yes | stage 5's text "HURTLING ACROSS THE VOID OF SPACE..." ([void](docs/img/play/stage5-void.png)) and Dameron's head cycling its colours ([Dameron](docs/img/play/stage5-dameron.png)); no game over in the window |
| rzx-s1 to rzx-s5 | the RZX run cut by stage: RZX frames 0, 32 896, 52 068, 69 522, 93 926 | 32 896, 19 172, 17 454, 24 404, 6 225 | no: the analysis instance cannot load a session with the RZX playback device | the player's run through stages 1-4: the graveyard, the caves, the winged demon, the green dragon; the temple, the harpy, Medusa, the hydra; the longship, the swamp, the castle tower; the palm beach, the tombs, the mummy. Stage 5 play falls after rzx-s5's window |

Each recording is under 100 000 frames. The walks press right in bursts, with fire and jumps (`sj-walk-right.txt`); the
hero dies on the way, so each walk ends in a game over, apart from stage 5.

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
| [HUD GAME OVER](docs/img/play/hud-game-over.png), [game-over screen](docs/img/play/game-over.png) | s1-right 4000, s4-right 4000 |

The game-over screen offers RESTART THIS STAGE, RESTART FROM STAGE ONE, GAME CREDITS 3 and the score.

### 6.2 Levels, objects and state

**The levels.** There are five stages. Each is one 33 792-byte block at `$6C3F-$F03E`, loaded over the last one by
the resident stage loader. Each holds its own code (run from `$7800`), map, graphics and enemies. Only stage 1's map
format is read so far ([doc 2, 2.3](docs/02-architecture.md#23-the-map-of-stage-1)): a packed block at `$B4B2`,
unpacked to `$5B00` at every room change, with three grids of 2 x 2-tile blocks. A room is a 14 x 9-block window.

**The state variables.** Witnesses are the deaths and walk recordings and the code at the named addresses.

| What | Where | Witness |
| --- | --- | --- |
| lives | `$FE61` (stage), set from H at the entry `$7800`, `DEC` at `$7ED4` | deaths: 5 to 4 at frame 2775 |
| energy | `$FE3F`, 0 to `$2E`; pending change `$FE4E` (`$80` and up drains, under `$80` refills) | deaths: 46 down to 2, refilled after the life |
| game over | `$FE5B` = 1 when the lives reach 0; the main loop `$7839` ends when `$FE61` and `$74EA` are 0 | s1-right to s4-right |
| room | column `$FE21`, row `$FE22`, grid record `$FE23` (`$9B6F` at the start) | c1's room change at 16531 |
| score | `$F9FB`, a word in the resident part, so it carries from stage to stage; printed by `$8BE3` through the table `$F9BF` | the HUD: 0, 18019, 27919, 44018 at the starts of stages 1-4 in the run |
| amount | `$F9FD`, printed by `$8C15` | |
| carried objects | the HUD's five item boxes; the item window (SPACE) | c1 15982 (a variable not yet located) |
| keys | the readers `$FC90-$FCDA`: a port and a bit for each, written by DEFINE KEYS | menu; the RZX run's Sinclair joystick reads port `$EFFE` |

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

**Not reached.** The following were not reached:
- **The ending.** The RZX run stops in stage 5 and no walk survives the duel.
- **The SELECT JOYSTICK screens.** The menu's highlight moves by itself, and the taps landed on START GAME.
- **The bosses of stages 2-5,** in recordings that have an L1. The RZX windows show the hydra and the mummy, but
  with no L1.
- **A stage reached by seeking the tape.** Seeking to a later stage block after START GAME left the game waiting on
  STAGE ONE's title for 19 000 frames (the stage loader seems to wait for its own stage's block; to check in stage 2). The recordings went
  to `work/stage1/old/`.
- **The sound.** The AY effects (PlaySound `$F69B`, the table `$F6BB`) are known only from the code. Nothing was
  played.
