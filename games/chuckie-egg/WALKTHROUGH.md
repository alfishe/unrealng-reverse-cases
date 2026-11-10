# Chuckie Egg: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

Asked: which of the candidate media is the original A'n'F release, what is on it, and where does each block land?

The candidates were copied unchanged from the local collection into `work/candidates/<zxart id>/` (a TAP, the Pick &
Choose TZX, four zipped SCLs, three TAPs). ZXDB (the local `catalog-sources/zxdb/v1.0.242/zxdb.sqlite`, entry 958)
names a third tape that was not among them: download 6194, `/pub/sinclair/games/c/ChuckieEgg.tzx.zip`, release 0
(A'n'F Software, 1983), source type "O", "Original release". It is in the local ZXDB mirror
(`software/zxdb/files/pub/sinclair/games/c/`) and was copied to `work/candidates/zxdb-6194/` and `orig/`.

```bash
. work/env.sh
md5 orig/*; shasum orig/*; md5 work/candidates/*/*
unzip -o orig/ChuckieEgg.tzx.zip -d work/media/tzx6194                      # and each candidate into work/media/
python3 tools/tzxblocks.py list "work/media/tzx6194/Chuckie Egg.tzx"         # a text block + 4 ROM blocks
python3 ../../kit/tapblocks.py list "work/media/tap96200/Chuckie Egg.tap"     # and the three zxart TAPs
for i in 1 2 3 4; do python3 tools/tzxblocks.py "work/media/tzx6194/Chuckie Egg.tzx" $i work/stage1/blocks/o-$i.raw; done
cmp work/stage1/blocks/o-3.d work/stage1/blocks/z96201-3.d                    # (flag and checksum cut) no output
z80dasm -a -t -g 0x5EF3 work/stage1/blocks/bas-code.bin                       # the loader in the variables area
python3 tools/image.py work/mkgame/original.bin                               # the image; = c1's memory at the entry
python3 ../../kit/sig_scan.py work/mkgame/original.bin --base 0 --all --out work/stage1/sig-game.json   # no hit
```

Found:

- **The original is ZXDB download 6194.** ZXDB marks it "Original release"; its four data blocks are those of the
  Pick & Choose re-release (release 1, 1984) byte for byte, so both carry the same game. Every other candidate is a
  conversion, a crack or a translation; the README lists each with what differs. The TAP of the same entry (download
  6195) adds a wait for a key to the loader.
- **The tape** (doc 3, 3.1): a BASIC header "CHUCKIE" (LINE 10, an 18-byte program), the BASIC block (1624 bytes:
  line 10 `RANDOMIZE USR 24307` and a variables area holding the loading picture's graphics, a 297-byte loader at
  `$5EF3` and the picture's text), then two headerless blocks the loader reads with the ROM's LD-BYTES: `01 00` into
  ERR_SP `$5C3D`, and 18 900 bytes to `$8214-$CBE7`. The game is entered at `$A410`. The signal lasts 115.29 s
  (5774 frames).
- **ERR_SP as a protection**: the main loop reads ERR_SP on every pass (`$9858`) and hangs in a two-byte loop unless it
  holds `$0001` ([doc 3.4](docs/03-build-and-load.md#34-err_sp-block-3-and-the-main-loops-check)). The zxart TAPs 433872 and 433874 keep this block but longer (88 and 67 bytes, `01 00
  FE ...`, `FE` the parity byte of a two-byte load).
- **No known module**: the signature scan finds nothing.
- **The image's text** (a strings scan of `$8214-$CBE7`): the menu (`$AC7E-$AD2A`: "press S to start game", "press R
  to redefine keys", "press I for instructions", "press 1,2 or 3 to select key type", "1,2,3 or 4 players ?"), the
  HUD words and "game over player 1 level" (`$AD3F`), "OUT OF TIME !" (`$AD5A`), the hi-score congratulation and the
  name prompt (`$AD87-$AE0A`), "high score table" and the redefine prompts (`$ABF2`), the key-name table
  (`$AC5A`), the instructions (`$8336-$84E5`, the three key types), the title's "n.alderton", "players", "skill",
  "presents", "SOFTWARE" (`$9650-$975C`). And leftover assembler source text from the author's editor at `$B167-$B3A9`
  ("JR C,C10", "LD DE,22849", "C8 JP SCRL2", "INITG", "CALL 40000", "C15 LD HL,18529", "CALL SCROL") and `$C8B0`
  ("ALL CONV1"), in the slot before the first level map and after the last one (NOTES.md).
- **The level maps**: eight maps of 672 bytes (32 x 21 cells) at `$B3B0 + 672 x n` (`$B3B0-$C8AF`), selected by
  `$A6E1-$A6F4` (level AND 7, plus one, times `$2A0` from `$B110`); cell codes 0 empty, 1 and 2 a ladder's two
  columns, 3 an egg, 4 grain, 5 a platform, `$A8-$B5` the duck's cage; 12 eggs on every level (WALKTHROUGH 6).

## 1. One recording from power-on

Asked: what runs from power-on to play, and how is play paced?

`c1` records from power-on: the 48K with zeroed RAM and muted sound, `LOAD ""` typed and the original TZX played
(the BASIC header and block through the fast LD-BYTES trap, the two headerless blocks at signal speed, because the
loader calls LD-BYTES at `$0556` itself), then `tests/inputs/c1.txt` from frame 5700: the title, I (the instructions
page), 3, S, 1 (one player) and a short play on level 1 until a life is lost and the game waits.

```bash
. work/env.sh
python3 $RS capture --work work/stage1/c1 --media orig/ChuckieEgg.tzx.zip --model 48K --record-load --load-frames 12000 \
    --inputs tests/inputs/c1.txt --ranges 4000-FFFF --port-base 36200 --binary $BIN       # 8916 frames, session.ttd
python3 $RS stages --work work/stage1/c1                    # the code arrivals
python3 $RS build --work work/stage1/c1 --stage 2 --into work/game     # the game alone: frames 5292-8916
python3 $RS interrupts --work work/game
python3 tools/l1map.py work/game/l1.json --from 4000 --gap 32           # the memory map's source (doc 2)
```

| Stage | Arrival | Frame (load) | What runs |
| --- | --- | --- | --- |
| 0 | `$5EF3` | 246, T 30 897 (the BASIC block by the trap) | the loader in the BASIC variables area (`USR 24307`) |
| 1 | `$5FAB` | 361 | the loader's own tail, after the picture is drawn: the two `CALL $0556` |
| 2 | `$A410` | 5292, T 39 044 (the game block at signal speed, written by the ROM's `$05AE`) | the game |

Found, interrupts and the frame (first look; stage 2 reads the routines):

- **IM 2, a vector table of `$9C`**: the entry `$A410` sets I = `$B2` and IM 2 (`$A41A-$A41E`); `$B200-$B300` holds
  257 bytes of `$9C` in the image, so every interrupt goes to `$9C9C`, a `JP $9CC2`. The game sets IM 2 again at
  `$A66C` (after a player's turn) and at `$A8E9` (after the name entry, which runs under IM 1, NOTES).
- **The handler only plays phrases on port `$9F`** (`$9CC2-$9CE9`): if the countdown `$7373` is not `$FF` it counts
  it down, and at zero it takes the next pair from the pointer `$7374`: a new countdown and a byte for `OUT ($9F),A`.
  `$9CEB` starts a phrase from the table at `$C8C6` + 2 x n. It does nothing for the game's timing: no counter, no
  keyboard, no sound on the beeper. `re_session.py interrupts`: 3104 entries in 3624 frames of `work/game` (0.86 a
  frame), 106 T an entry, 0.1 % of the CPU.
- **DI / EI**: the game has no DI; its only EI is the handler's (`$9CE7`). Interrupts are lost while the ROM's BEEPER
  (`$03B5`, DI inside) plays the death tune and the like, which is why `c1` has fewer entries than frames.
- **No HALT in play, no frame sync**: the main loop `$9858-$99DC` runs as fast as the CPU goes. Each pass checks
  ERR_SP (`$9858`, [doc 3.4](docs/03-build-and-load.md#34-err_sp-block-3-and-the-main-loops-check)), plays a step of a sound while `$7370` is not zero (`$9CA4`), runs `$A21C` and tests the
  hens against Harry (`$9E66`) while the flag `$7325` is set, then counts `$72DC` down; every `$82` = 130 passes (`$98BE`) it runs the slow work: the CAPS SHIFT + H / A keys, then a row of
  down-counters, each calling its task when it reaches zero (`$7345` reloaded with `$32`, `$734C` with `$0C`, `$733C`
  with 2, `$7346` with `$0A`, `$736B` with 3), the eggs and grain under Harry (`$99DF`), Harry's keys (`$9955-$99BF`)
  and drawing. The only HALT in the game is in the name entry (`$A8B0`).
- **Passes and ticks a frame** (L1 of `tour-type2`, 6.0: play from frame 850-900 to 8001, about 7120 frames, one
  life, no death): `$9858` ran 1 120 211 times and the slow work `$98BE` 8618 times (130 passes each, the ratio is
  exact), so about 157 passes and 1.21 slow ticks a frame: Harry, the hens and the timer move once every 0.83 frames
  on average, not once a frame. `idle-1p` (30 001 frames, five deaths and the title between) gives the same ratio:
  2 027 615 passes, 15 602 ticks.
- **The heaviest pass** (`tools/heavypass.py`, a second muted instance through the WebAPI: `skip_until` `$98BE`, then
  `skip_until` `$9858`, the beam's frame and T-state before and after; 300 slow ticks from each of three states with
  no key held: level 1 at the start of play, `work/stage1/bot/t4/base.szx`; level 3, `t10/base.szx`; level 4,
  `rec/levels-1-3/end.szx`; `work/stage1/heavypass.json`): the 130 light passes before a tick take 20 531-20 659 T
  (median; about 158 T a pass, 24 815 T at most); the pass with the slow work takes 29 999-31 426 T (median),
  27 334 T at least and 81 809 / 82 392 / 83 985 T at most, more than a frame (69 888 T). A tick is then about
  51 000 T in the median, 1.37 a frame with Harry standing; the recordings' 1.21 a frame is play with Harry moving, eggs taken and sounds (stage 2 splits the slow work by task).

```bash
python3 tools/heavypass.py --port-base 36210 --ticks 300 --out work/stage1/heavypass.json \
    work/stage1/bot/t4/base.szx work/stage1/bot/t10/base.szx work/stage1/rec/levels-1-3/end.szx
```

## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

### 6.0 The recordings

Asked: which recordings reach every part of the game, and how was each made?

Every recording after `c1` starts from `work/stage1/lab/x0/loaded.szx`: the original tape loaded on a fresh 48K the
way `c1` loads it (`tools/lab.py`, `Lab.load_tape`, which is `re_session.py`'s `corpus.load`), saved on the title
page 5700 frames after power-on. Its input script (in `tests/inputs/`) counts frames from that state.

The levels are played by a bot (`tools/bot.py search`): a best-first search over emulator states on one muted
instance. A node is a state reached by a list of (keys, frames) segments; its children hold one of twelve key sets
for 8 frames (right, left, up, down, jump, jump with right or left, nothing, and right or left with up or down,
because the game grabs a ladder only where Harry's x is a multiple of 8, `$9E98`, and the up or down key must be held
as he walks past). A child dies when the program leaves for the ROM (the death tune) or the lives at `$6EF0` drop;
it wins when the eggs left (`$6EE6`) drop. The heuristic is the distance in cells from Harry to the nearest egg over
the live map (`$61A8`: walk, ladders, falls, jumps of up to 4 cells across and 1 up); the closed set is Harry's
x / 6, y / 4, direction, lives and the time / 48 frames (so waiting for a hen to pass is a move). An egg that leaves
no way out alive over the next 48 frames is not taken, and when an egg cannot be reached the bot backs up one egg.
No POKE is used by the bot: every level it reports was played with the game's five lives.

The bot's findings about the game, each from its probes (`work/stage1/lab/phys.py`, `ladder.py`):

- Harry walks about 2 pixels a frame, a jump rises 11 pixels and lands about 37 pixels on (20 frames), a fall of 5
  rows (40 pixels) does not kill him;
- he takes a ladder only where x AND 7 = 0 with the up or down key held (`$9E98-$9ED7`).
- a fall is straight down and starts with a push off the edge: walking right off a platform at x 184 he falls at
  x 189 (`work/stage1/lab/egg3b.py`); a jump cannot be started in a fall, and a jump pressed on a ladder while he
  falls down it does nothing;
- he can jump sideways off a ladder while climbing: up 4 frames then right and jump took him from the ladder at
  x 120 to the platform at x 157 (level 3);
- a jump that crosses an egg's cell in the air does not take it: the jump right from x 157 on level 3 passed over the
  last egg and fell; the same jump from x 139 (9 frames left first) landed on the egg's platform and took it.

The last egg of level 3 (row 10, column 23, on a two-cell platform with a one-cell gap on its left and a platform
right above it) defeated the search: every approach from the right ends in the push off an edge, one column too far
right. A search for a cell (`bot.py search --target 16,10`: Harry standing on the ladder at columns 15-16 at the
egg's height) found the way to the left ladder, and the take-off was swept by hand (`egg3b.py`, one frame at a
time): up 4 frames, right and jump, left 9 frames, right and jump. `work/stage1/bot/t19.txt` is levels 1-3 with that
ending and the wait for level 4 (frame 7022).

Levels 4-9 (`tests/inputs/levels-1-9.txt`, built as `work/stage1/bot/t19.txt` -> `t64.txt`, each step a search
or a hand segment appended with `work/stage1/lab/append.py`) needed these changes to the bot and these findings:

- **The bot**: `--air` values a cell in the air by the cells a jump from it may land on, not by its straight fall
  (the level 4 stall); a vertical jump grabs a ladder that starts 1-2 cells above (a graph edge, level 5's broken
  ladder at columns 11-12); `--skip C,R` hides an egg from the heuristic and `--noskip` forbids taking it while others
  are left (eggs over long drops are kept for last); a `--target` state must survive the next 48 frames; the wait
  after a level is 150 frames, because the next level is drawn for about 80 frames after its eggs come back and a
  search started earlier sees every child "die"; the start node's key is not put in the closed set (a start in mid
  air gave every child the same key and an empty heap).
- **The egg pickup** (`$99DF`, on every slow tick, called at `$991F`): the point (x + 8, y - 8) goes through `$9E34`; an egg
  is taken when that point is in its cell, walking, falling or landing. Eggs hanging in the air (level 6 (26,1),
  level 7 (28,1)) and eggs in platform gaps (level 8 (8,4), (23,4), (12,16)) are taken by a fall through the cell;
  a jump from the egg's own height lifts the point over it.
- Harry stands on platform row p at y = 8p + 23 and takes a ladder at x = 8 x its left column; he steps off a ladder
  only where there is floor, and jumps off it sideways anywhere.
- **Level 8** (three hens on two ladders) was played by hand: sweeps of a wait before each climb
  (`work/stage1/lab/sweep.py`, `hens.py` for the hens' cycle) and `--target` searches for the legs between the
  platforms. One life is lost there on purpose: the jump that takes (20,12) falls onto row 4 under hen 2 (frame
  about 21 500), and the last egg (12,16) is taken from the next life by climbing the upper middle ladder while its
  hen walks row 12 (`work/stage1/bot/t60.txt`, `p23.txt`) and walking left off column 13.
- **Level 9 is level 1's map without hens** (`$AF81`: levels 9-16 have none) **and with the duck free**: it is in
  the cage on the first frame, then flies after Harry (6.1); standing still at the start Harry lost a life about 250
  frames into the level (`work/stage1/bot/t63.txt`, a probe, not in the recording). The bot took the twelve eggs in
  1504 frames, no life lost.
- **An extra life every 10 000 points**: lives 6 at 10 000, then one more at each 10 000 to 10 at 60 000 (level 10's
  start, 61 800 points). The bonus shown at a level's start is about 1000 x the level number and counts down while
  the level is played (5990 on level 6, 7980 on level 8); levels 9 and 10 both show 8990, so it stops at 9000.
- **The recording must replay the script in the search's run calls**: the game's speed is the CPU's, and splitting a
  segment into 50-frame `run_frames` calls changed the outcome (Harry fell into a gap on level 6 at frame 13 250, then
  lost all his lives); `bot.py record --exact` runs one call a segment and takes a screenshot after each segment that
  crosses a multiple of 50 frames. The 50-frame replay without recording (`work/stage1/lab/chunkcmp.py`) matched the
  bad recording, so the split, not the recording, is the cause.

Each recording is made with one command (the instance is started, muted, and stopped by it). `loaded.szx` is
`work/stage1/lab/x0/loaded.szx`. Command A, the stage 1 recordings:

```bash
. work/env.sh
python3 tools/bot.py record --start work/stage1/lab/x0/loaded.szx --inputs tests/inputs/<name>.txt \
    --work work/stage1/rec/<name>       # session.ttd, l1.json, states.json, end.szx, screens/ every 50 frames
```

Commands B1-B3, the three recordings made for doc 5 (port base 36240, `--exact`, TTD on):

```bash
python3 tools/bot.py record --start work/stage1/lab/x0/loaded.szx --inputs work/docs/ceB/hold-abort.txt \
    --work work/docs/ceB/rec/hold-abort --exact --shot 10 --port-base 36240                      # B1
python3 tools/bot.py record --start work/docs/ceB/name-39520.szx --inputs work/docs/ceB/name-delete.txt \
    --work work/docs/ceB/rec/name-delete --exact --shot 5 --port-base 36240                      # B2
python3 tools/bot.py record --start work/stage1/lab/x0/loaded.szx --inputs work/docs/ceB/redefine-odd.txt \
    --work work/docs/ceB/rec/redefine-odd --exact --shot 50 --port-base 36240                    # B3
```

| Recording | Start | Input script | Command | Frames | What it reaches | session.ttd | POKE |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `c1` | power-on | `tests/inputs/c1.txt` | `re_session.py capture` (section 1) | 8916 | the load, the title, the instructions, key type 3, one player, level 1 until a life is lost (section 1) | `work/stage1/c1/session.ttd` | none |
| `idle-1p` | `loaded.szx` | `tests/inputs/idle-1p.txt` | A | 30 001 | S, one player, no key: five lives lost to the hens on level 1 (deaths at frames 5150, 7550, 9900, 12 200, 14 600 by `states.json`), GAME OVER, the title and the high score table again | `work/stage1/rec/idle-1p/session.ttd` | none |
| `tour-type2` | `loaded.szx` | `tests/inputs/tour-type2.txt` | A | 8001 | the title with the high score table and the scroller, I (the instructions page), key type 2 (the cursor keys and joystick), S, two players, Harry walked with 8 and 5, a jump with 4 | `work/stage1/rec/tour-type2/session.ttd` | none |
| `tour-redefine` | `loaded.szx` | `tests/inputs/tour-redefine.txt` | A | 12 001 | I, R (the redefine page: Q A O P M), S, four players, Harry walked with P and O, a jump with M; then a death by the timer (TIME 000, "OUT OF TIME !" at frame 8750) and the turn passing to player 2 | `work/stage1/rec/tour-redefine/session.ttd` | none |
| `levels-1-3` | `loaded.szx` | `tests/inputs/levels-1-3.txt` (`work/stage1/bot/t19.txt`) | A | 7023 | levels 1, 2 and 3 by the bot with the last egg of level 3 by hand (6.0 above), the bonus counted after each level, level 4 starting at frame 7022; no life lost | `work/stage1/rec/levels-1-3/session.ttd` | none |
| `fall-death` | `loaded.szx` | `tests/inputs/fall-death.txt` | A | 3601 | levels 1 and 2 as `levels-1-3` to frame 2350, then Harry walks left into the gap of level 2's bottom floor (columns 6-7, no hen near): he sinks 7 pixels (y 23 to 16) and dies at frame 2710; the next life | `work/stage1/rec/fall-death/session.ttd` | none |
| `gameover-name` | `loaded.szx` | `tests/inputs/gameover-name.txt` | A | 41 201 | levels 1-3 as `levels-1-3`, then no key on level 4: the five lives are taken by the hens (Harry stands still; HenKill `$92BC` runs 5 times, the time never runs out: OUT OF TIME `$A725` 0, `tools/l1count.py 92BC A1CE A725`), GAME OVER, "WELL DONE! YOU HAVE BEATEN ONE OF TODAYS HIGHEST SCORES" and the name prompt under IM 1 (frame 39 483), C E 1 typed, ENTER, the title with "CE1" first in the table | `work/stage1/rec/gameover-name/session.ttd` | none |
| `levels-1-9` | `loaded.szx` | `tests/inputs/levels-1-9.txt` (`work/stage1/bot/t64.txt`) | A with `--exact` | 25 491 | levels 1-9: level 4 at frame 7022, 5 at 9894, 6 at 11 988, 7 at 14 204, 8 at 17 253, 9 (level 1's map, no hens, the duck free) at 23 546, level 10 at 25 490 with 10 lives and 61 800 points; one life lost on level 8 (above) | `work/stage1/rec/levels-1-9/session.ttd` | none |
| `hold-abort` | `loaded.szx` | `work/docs/ceB/hold-abort.txt` | B1 | 1801 | S, one player, walk right with 0; HOLD (CAPS SHIFT + H) at frame 1100 (entered T 54 699), S at 1300, ABORT (CAPS SHIFT + A) at 1400: back to Start `$A410` (doc 5.6) | `work/docs/ceB/rec/hold-abort/session.ttd` | none |
| `name-delete` | `work/docs/ceB/name-39520.szx` (`gameover-name` seeked to frame 39 520 and saved: the name prompt before any key) | `work/docs/ceB/name-delete.txt` | B2 | 401 | C, E, DELETE (CAPS SHIFT + 0, frame 63), 1, ENTER (doc 5.8) | `work/docs/ceB/rec/name-delete/session.ttd` | none |
| `redefine-odd` | `loaded.szx` | `work/docs/ceB/redefine-odd.txt` | B3 | 1501 | R, then 9 (refused at frame 112: KeyUsed compares KeySet2's jump keys), Q, W + E, 1 + Q, O, P, M; a game on the new keys (doc 5.5) | `work/docs/ceB/rec/redefine-odd/session.ttd` | none |

### 6.1 The screens

Each screen is a recording's screenshot at the end of the named frame, doubled, in `docs/img/play/`: the stage 1
screens are `work/stage1/rec/<recording>/screens/<frame>.png`; the ones marked * were made for the documents with
`kit/screen_shot.py` over the same recording (doc 1, 1.9-1.12).

| Screen | Recording, frame | Image |
| --- | --- | --- |
| The title with the high score table (ten entries of "A+F CHUCKIE EGG 001000") | `tour-type2`, 200 | ![The title](docs/img/play/title.png) |
| The instructions page with the three key types | `tour-type2`, 300 | ![The instructions](docs/img/play/instructions.png) |
| The redefine page, Q A O P M given | `tour-redefine`, 450 | ![The redefine page](docs/img/play/redefine.png) |
| "1,2,3 OR 4 PLAYERS ?" | `tour-type2`, 500 | ![The players prompt](docs/img/play/players-prompt.png) |
| "PLAYER 1" before a turn | `tour-type2`, 700 | ![Player 1's turn](docs/img/play/player-turn.png) |
| Level 1, two players (two score fields) | `tour-type2`, 900 | ![Level 1, two players](docs/img/play/level1-two-players.png) |
| Level 1, four players | `tour-redefine`, 1150 | ![Level 1, four players](docs/img/play/level1-four-players.png) |
| A death by a hen: the screen holds while the tune plays, Harry is gone (Harry never moved and TIME is 652, so neither a fall nor the timer) | `idle-1p`, 7250 | ![A death by a hen](docs/img/play/hen-death.png) |
| TIME 000 | `tour-redefine`, 8600 | ![TIME 000](docs/img/play/time-zero.png) |
| "OUT OF TIME !" | `tour-redefine`, 8750 | ![Out of time](docs/img/play/out-of-time.png) |
| Player 2's turn after player 1's life | `tour-redefine`, 9050 | ![Player 2's turn](docs/img/play/player2-turn.png) |
| GAME OVER | `idle-1p`, 14 600 | ![Game over](docs/img/play/game-over.png) |
| A death by falling into a floor gap (level 2) | `fall-death`, 2710 | ![A death by falling](docs/img/play/fall-death.png) |
| The congratulation and the name prompt (IM 1, the ROM's keyboard) | `gameover-name`, 39 450 | ![The name prompt](docs/img/play/name-prompt.png) |
| The name typed: "CE1" | `gameover-name`, 39 600 | ![The name typed](docs/img/play/name-typed.png) |
| The title with the new entry first in the table | `gameover-name`, 39 700 | ![The new entry](docs/img/play/title-new-entry.png) |
| Level 1 | `levels-1-3`, 500 | ![Level 1](docs/img/play/level1.png) |
| Level 2 (gaps in the bottom floor) | `levels-1-3`, 2400 | ![Level 2](docs/img/play/level2.png) |
| Level 3 (a lift at columns 8-9) | `levels-1-3`, 4000 | ![Level 3](docs/img/play/level3.png) |
| Level 4 (a lift at columns 18-19) | `levels-1-3`, 7000 | ![Level 4](docs/img/play/level4.png) |
| Level 5 (a lift at the right) | `levels-1-9`, 9894 | ![Level 5](docs/img/play/level5.png) |
| Level 6 (a lift in the middle, eggs hanging in the air) | `levels-1-9`, 11 988 | ![Level 6](docs/img/play/level6.png) |
| Level 7 (a lift at the right edge) | `levels-1-9`, 14 204 | ![Level 7](docs/img/play/level7.png) |
| Level 8 (three hens, eggs in the platform gaps) | `levels-1-9`, 17 253 | ![Level 8](docs/img/play/level8.png) |
| Level 9: level 1's map, no hens, the duck still in the cage | `levels-1-9`, 23 546 | ![Level 9](docs/img/play/level9.png) |
| Level 10: level 2's map, the duck out of the cage | `levels-1-9`, 25 490 | ![Level 10](docs/img/play/level10.png) |
| Level 1: the first egg taken, 100 points * | `levels-1-9`, 574 | ![The first egg](docs/img/play/first-egg.png) |
| Level 1: a jump to the right * | `levels-1-9`, 610 | ![A jump](docs/img/play/jump.png) |
| Level 1: up a ladder * | `levels-1-9`, 712 | ![Up a ladder](docs/img/play/climb.png) |
| Level end: the bonus counted into the score * | `levels-1-9`, 2016 | ![The bonus](docs/img/play/level-end-bonus.png) |
| Level end: the attribute boxes close in (BoxZoom) * | `levels-1-9`, 2080 | ![The boxes](docs/img/play/level-end-boxes.png) |
| Level end: "LEVEL 2" scrolled in * | `levels-1-9`, 2170 | ![LEVEL 2](docs/img/play/level-message.png) |
| Level 2 just drawn, no hens on the map yet * | `levels-1-9`, 2300 | ![Level 2 drawn](docs/img/play/level-drawn.png) |
| Level 3: a lift ride * | `levels-1-9`, 5800 | ![A lift ride](docs/img/play/lift-ride.png) |
| Level 4: 9 900 points, 5 lives * | `levels-1-9`, 7980 | ![Before the extra life](docs/img/play/extra-life-before.png) |
| Level 4: 10 000 points, 6 lives (the extra life) * | `levels-1-9`, 7990 | ![The extra life](docs/img/play/extra-life.png) |
| Level 9: the duck out of its cage * | `levels-1-9`, 23 700 | ![The duck out](docs/img/play/duck-out.png) |
| Level 9: the duck closes in * | `levels-1-9`, 24 300 | ![The duck free](docs/img/play/duck-free.png) |

### 6.2 The animations

Every animation in `docs/img/`, 37 in all. `play/` holds the screen as the player sees it
(`kit/screen_anim.py`, one picture a frame unless noted); `routines/` a routine at work from an access trace
(`kit/routine_anim.py`: the memory, the view and the listing). `Loader.gif` and `tape-block4.gif` are memory over time
(`kit/memanim.py`). Frames are the recording's; `F T t` is a T-state in
frame F. Each document's caption gives the command.

| Animation | Document | Recording | Frames |
| --- | --- | --- | --- |
| [`play/tape-block4.gif`](docs/img/play/tape-block4.gif) | [3](docs/03-build-and-load.md) | `c1` | 361-5300, a picture every 80 frames |
| [`routines/Loader.gif`](docs/img/routines/Loader.gif) | [3](docs/03-build-and-load.md) | `c1` | 246 T 30 000 - 262 T 40 000 |
| [`routines/MainLoop.gif`](docs/img/routines/MainLoop.gif) | [4](docs/04-game-loop.md) | `levels-1-9` | 456 T 0 - 460 T 40 000 |
| [`routines/MainLoopTick.gif`](docs/img/routines/MainLoopTick.gif) | [4](docs/04-game-loop.md) | `gameover-name` | 7467 T 4000 - 7468 T 17 200 |
| [`routines/RedefineOne.gif`](docs/img/routines/RedefineOne.gif) | [5](docs/05-controls.md) | `tour-redefine` | 215-216 |
| [`routines/WalkHarry.gif`](docs/img/routines/WalkHarry.gif) | [5](docs/05-controls.md), [10](docs/10-gameplay-logic.md) | `tour-type2` | 1000-1002 |
| [`routines/EnterHiScore.gif`](docs/img/routines/EnterHiScore.gif) | [5](docs/05-controls.md), [8](docs/08-hud-and-text.md) | `name-delete` | 63-64 |
| [`play/name-entry.gif`](docs/img/play/name-entry.gif) | [5](docs/05-controls.md), [1](docs/01-game-design.md) | `name-delete` | 0-116 |
| [`routines/SetupLevel.gif`](docs/img/routines/SetupLevel.gif) | [6](docs/06-rendering.md) | `levels-1-3` | 283-293 |
| [`routines/DrawSprite.gif`](docs/img/routines/DrawSprite.gif) | [6](docs/06-rendering.md) | `levels-1-3` | 606 T 31 000 - 606 T 57 500 |
| [`routines/DrawHen.gif`](docs/img/routines/DrawHen.gif) | [6](docs/06-rendering.md) | `levels-1-3` | 604 T 20 400 - 604 T 30 200 |
| [`routines/PaintCells.gif`](docs/img/routines/PaintCells.gif) | [6](docs/06-rendering.md) | `levels-1-3` | 609 T 46 000 - 609 T 68 000 |
| [`routines/DrawLift.gif`](docs/img/routines/DrawLift.gif) | [6](docs/06-rendering.md) | `levels-1-3` | 4101 T 34 500 - 4101 T 37 200 |
| [`routines/MoveHen.gif`](docs/img/routines/MoveHen.gif) | [7](docs/07-objects.md) | `levels-1-9` | 425-489 |
| [`routines/MoveLifts.gif`](docs/img/routines/MoveLifts.gif) | [7](docs/07-objects.md) | `levels-1-9` | 4217-4221 |
| [`play/lift-cycle.gif`](docs/img/play/lift-cycle.gif) | [7](docs/07-objects.md) | `levels-1-9` | 4219-4531, every 4th frame |
| [`routines/SetupLevel-spawn.gif`](docs/img/routines/SetupLevel-spawn.gif) | [7](docs/07-objects.md) | `levels-1-9` | 2213 |
| [`routines/DrawHen-kill.gif`](docs/img/routines/DrawHen-kill.gif) | [7](docs/07-objects.md) | `idle-1p` | 4763 |
| [`routines/PrintChar.gif`](docs/img/routines/PrintChar.gif) | [8](docs/08-hud-and-text.md) | `levels-1-3` | 290 T 34 000 - 291 T 12 000 |
| [`routines/AddScore.gif`](docs/img/routines/AddScore.gif) | [8](docs/08-hud-and-text.md) | `levels-1-3` | 568 T 58 000 - 569 T 12 000 |
| [`routines/CountDown.gif`](docs/img/routines/CountDown.gif) | [8](docs/08-hud-and-text.md) | `levels-1-3` | 2007 T 10 000 - 2016 T 60 000 |
| [`routines/Beep.gif`](docs/img/routines/Beep.gif) | [9](docs/09-sound.md) | `levels-1-3` | 578 T 56 500 - 578 T 63 500 |
| [`play/climb.gif`](docs/img/play/climb.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 1288-1354 |
| [`routines/ClimbLadder.gif`](docs/img/routines/ClimbLadder.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 1300-1302 |
| [`play/jump.gif`](docs/img/play/jump.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 1884-1932 |
| [`routines/JumpFall.gif`](docs/img/routines/JumpFall.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 1905-1910 |
| [`play/fall-off-edge.gif`](docs/img/play/fall-off-edge.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 910-964 |
| [`routines/FallOffEdge.gif`](docs/img/routines/FallOffEdge.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 916-921 |
| [`play/egg-taken.gif`](docs/img/play/egg-taken.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 556-580 |
| [`routines/TakeEggOrGrain.gif`](docs/img/routines/TakeEggOrGrain.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 567-569 |
| [`play/egg-in-hole.gif`](docs/img/play/egg-in-hole.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 8452-8522 |
| [`play/duck-homing.gif`](docs/img/play/duck-homing.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 23 340-24 340, every 10th frame |
| [`routines/MoveDuck.gif`](docs/img/routines/MoveDuck.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 23 600-23 611 |
| [`routines/CatchLift.gif`](docs/img/routines/CatchLift.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 4250-4252 |
| [`play/lift-top.gif`](docs/img/play/lift-top.gif) | [10](docs/10-gameplay-logic.md) | `levels-1-9` | 5905-5995 |
| [`play/hen-kill.gif`](docs/img/play/hen-kill.gif) | [10](docs/10-gameplay-logic.md) | `idle-1p` | 4736-4790 |
| [`play/fall-death.gif`](docs/img/play/fall-death.gif) | [10](docs/10-gameplay-logic.md) | `fall-death` | 2684-2730 |

## 7. Review
