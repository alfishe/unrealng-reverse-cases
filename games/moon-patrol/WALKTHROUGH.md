# Moon Patrol: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The release: ZXDB 3266, Moon Patrol by Atarisoft (UK), 1984, "Never released - recovered". The other ZXDB entries
of the name are a 2003 BASIC game (14864), an MCoder II game (17508) and modern remakes; the owner's "Moon Patrol"
is the Atarisoft port of the arcade game. ZXDB's own host gave empty replies to the downloads; the same files came
from the worldofspectrum.net mirror (same lengths as ZXDB's `Content-Length`). The `.pok` file of the entry was a
404 there and is not kept.

```bash
unzip -o orig/MoonPatrol.tap.zip -d work/media/tap; unzip -o orig/MoonPatrol.tzx.zip -d work/media/tzx
python3 ../../kit/tapblocks.py list "work/media/tap/Moon Patrol.tap"          # 4 standard blocks, 227.3 s
python3 ../exolon/tools/tzxblocks.py list "work/media/tzx/Moon Patrol.tzx"    # the same + a text block, pauses
python3 ../../kit/tapblocks.py "work/media/tap/Moon Patrol.tap" 1 work/media/basic.bin
python3 ../exolon/tools/basic_list.py work/media/basic.bin                    # CLEAR 24823, LOAD "" CODE, USR 32768
python3 ../../kit/sig_scan.py work/mkgame/original.bin --base 60F8 --all --out work/stage1/sig-game.json
```

- The TZX's code block is the TAP's byte for byte. The game is one block, `$60F8-$FFFF`, entered at `$8000`.
- The signature scan finds no known module (one one-anchor candidate at `$6BC1`, thousands of bytes different).
- The image's text (a strings scan): Atari's copyright, the menu (one or two players, Beginner or Champion course,
  six control choices including the "Old-type Fuller Box"), a hi-score table saved, loaded and verified on tape,
  with a warning against loading "an Atarisoft Robotron hi-score table" (the code is shared with Atarisoft's
  Robotron), the bonus texts (sector bonus, time bonus, best sector time), and four build dates left by the
  assembler: `20:15 29/10/84` at `$90BD`, `02:45 29/10/84` at `$B2C7`, `03:35 30/10/84` at `$7F05`,
  `03:40 30/10/84` at `$A187`. A default hi-score name is `SPIKE NOTWELL` (`$88AD`).
- Lead for section 1: `CLEAR 49999` after the load puts the ROM's stack at `$C34F`, inside the loaded image; what
  the BASIC's last steps write there is to be read in `c1`.

## 1. One recording from power-on

Asked: what runs from power-on to play, and is there anything between the ROM's load and the game?

Used: `re_session.py capture --record-load` on the 48K (`c1`: the ROM blocks through the fast LD-BYTES trap, then
16 000 frames of seeded random play), then `re_session.py stages --work work/c1`.

```bash
. work/env.sh
python3 $RS stages --work work/c1
```

| Stage | Entered at | Frame, T (`c1`, fast load) | Written by | Entered from |
| --- | --- | --- | --- | --- |
| 0 | `$8000` | 256, 58 497 | `$0802` (the ROM's LD-BYTES) | `$34BB` (`USR`, BASIC line 10) |
| 1 | `$9041` | 1453, 3 016 | `$0802` | `$0052` (the ROM's interrupt `RET`) |
| 2 | `$7F8D` | 1562, 52 277 | `$0802` | `$03F7` (the ROM's BEEPER returning) |

Produced:

- One load, no second stage: all three entries are bytes the ROM's loader wrote, first executed at different times.
  Stage 1 is `HALT` / `DJNZ` at `$9040` (a wait of B frames, `$903D`: `EI`, `LD B,$64`), resumed by the frame
  interrupt's `RET`; stage 2 is the `DI` after a `CALL $03B5` (the ROM's BEEPER) at `$7F8A`. The game runs with
  interrupts on (IM 1, the ROM's handler) at least in these waits.
- `$8000` is the game's entry: it saves SP at `$B25D`, sets `$F0A2` = 8, clears the screen (`$9044`: `$4000-$57FF`
  to 0), and prints the menu.
- The recording reached the menu ("SELECT OPTIONS": one or two players, Beginner or Champion course, six control
  choices, the tune toggle) and play on the Beginner course (the buggy, the craters, the rocks, the HUD with the
  hi-score 50000, time, and the course points E, J, P, U, Z).

Interrupts and timing, a first look. Used: `tools/irq_sites.py` (executed `HALT` / `DI` / `EI` / `IM` / `LD I,A`
sites and their counts over the L1 builds of the stage-1 recordings, 6.0) and `re_session.py interrupts` on `i1`.

```bash
python3 tools/irq_sites.py work/runs/{a1,g1,t1,p2,i1,i2,h1,h2}/l1.json
python3 $RS interrupts --work work/runs/i1
```

- **IM 1 in the menus, IM 2 in play.** SetIm2 `$A7D4`: `DI`, `I` = `$3A`, `IM 2`, `EI`, run 27 times in all the
  recordings, called from the life start (`$9132`) and the end of the hold (`$AF0E`). SetIm1 `$A7CB`: `DI`, `IM 1`,
  `I` = `$3F`, `EI`, run 56 times, called from the menu code (`$81CD`, `$823D`, `$8250`, `$8328`), the death
  (`$96DF`), the sector bonus (`$A50E`), the abort (`$AACD`) and the hold (`$AEE0`).
- **The vector.** The bus reads `$FF` in IM 2, so the vector is the word at `$3AFF` in the ROM: `$FF $FF`. At `$FFFF`
  the image holds `$18` (`JR`), and the ROM's first byte `$F3` makes it `JR $FFF4`; `$FFF4` is `JP $7F14`. Witness:
  `i1`, 25 747 entries of `$7F14` from `$FFFF` in 30 440 frames.
- **The handler `$7F14`**: `DI`, pushes every register, FRAMES `$5C78` + 1, calls the tune player `$7F47` (every third
  interrupt the next note from `$B23E`, the tune at `$B4E6`, played through the ROM's BEEPER `$03B5`, then `DI` at
  `$7F8D`; silent when `$B288` bit 7 is set), calls the clock `$7F98` (`$B287` counts 50 interrupts, then the BCD
  seconds `$B285`/`$B286` go up), pops, `EI`, `RET`. In `i1` it costs 16 615 T an entry, 20.1 % of the CPU; 0.85
  entries a frame, because a note longer than a frame lets interrupts go by.
- **`DI` / `EI` sites**: the handler's pair `$7F14` / `$7F45` (39 439 times), `$7F8D` after BEEPER (11 624), the two
  set-ups above, the "PLAYER n" wait `$903D` (`EI`, 51 times), and the sector bonus `$A5E5` / `$A610`.
- **No frame sync in play.** The main loop `$9696-$96F8` has no `HALT`; one pass of its call list `$96FA` takes as
  long as its work: 3601 passes in about 30 175 play frames of `i1` (8.4 frames a pass), 493 in `g1` (7.5). The
  `HALT`s are in waits only: `$9040` (100 frames of "PLAYER n", 5100 times), the hold `$AEEC` / `$AF0B`, and the bonus
  screen (`$A581`, `$A5AF`, `$A613`, `$A699`).
- **The stack's low point is in the handler.** Below `$C312` the stack holds the handler's words: `$7F37` (its call of
  the tune player), `$7F8D` (the tune player's call of BEEPER) and `$5C3A` (the IY it pushes), down to `$C2FC` (`i1`
  frame 10000, `memory_at`; doc 2, 2.3). BEEPER ends with `EI`, so an interrupt may nest at `$7F8D` before its `DI`;
  open for stage 2.

## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

### 6.0 Recordings that reach every part of the game

Asked: which recordings reach the menus, both courses, every point, the deaths, GAME OVER, the hi-scores, the tape,
two players, the tune toggle, the hold, the abort and every enemy?

Used: `re_session.py capture --snapshot` from the game's entry, one input script each (`tests/inputs/`, written by
`tools/inputs.py all`), one instance at a time (`tools/runs.sh`), then `re_session.py build` for the L1 of each. Where
skill was needed, clones of the entry snapshot (`tools/warp_snapshot.py`, `tools/moment_snapshot.py`).

```bash
python3 tools/entry_snapshot.py --work work/c1 --out work/snaps/entry.z80          # c1 at 256, T 58 497, PC $8000
python3 tools/warp_snapshot.py --immune --out work/snaps/immune.z80                # the kill entry $A7DD set to RET
python3 tools/moment_snapshot.py --work work/runs/g1 --at 3700:0 --poke B272=00 --poke B273=06 --poke B274=00 \
    --poke B275=00 --out work/snaps/g1-3700-score60000.z80                       # g1 at 3700, score 60000
python3 tools/inputs.py all
tools/runs.sh a1:entry:a1-menus-abort g1:entry:g1-game-over t1:entry:t1-tape p2:entry:p2-two-players \
    h1:entry:h1-heroes-entry i1:immune:i1-immune-beginner i2:immune:i2-immune-champion \
    h2:g1-3700-score60000:h2-all-time-entry
python3 tools/timeline.py --work work/runs/i1           # the player record over time
python3 tools/segframes.py --work work/runs/i1          # the frame each course point is entered
```

| Name | From | Frames | Reached |
| --- | --- | ---: | --- |
| `a1` | entry | 21 614 | the title, H the heroes table (153), the options page (414) and its keys, S start (1314), the hold (2060-2220), the tune off (2540-2740), CAPS+SPACE abort (3174), the score advance table (~19 800), the demo (~20 800) |
| `g1` | entry | 10 760 | deaths and restarts, GAME OVER (~3950), the heroes initials entry `$8B8F` (4144) |
| `t1` | entry | 3490 | J: SA-BYTES `$04C2` (153-479); L and G: LD-BYTES `$0556` (1077-2650); SPACE: report D into `$82F3`; back to the menu |
| `p2` | entry | 24 020 | two players, swapped by `$9022` 30 times, PLAYER 2 (1150), GAME OVER PLAYER `$8FD2`, the heroes entry of player 1 (7830) |
| `h1` | entry | 7584 | initials MPA entered: heroes #1 and all-time #40 (`$8C58`), the table `$81D0` (4524-6060) |
| `i1` | immune | 30 440 | the whole Beginner course, A (280) to Z (27 180), the five bonus screens, then `$BB07` to Champion A (29 680) |
| `i2` | immune, Champion | ~33 800 | the whole Champion course, A (460) to Z (28 220), then `$BED4` back to Beginner A (30 700) |
| `h2` | `g1` 3700, score 60000 | 4200 | the all-time "THE GREATEST" entry `$8E4E` (513-1141), a 20-letter name typed |

Produced:

- Every part the brief lists, except a successful tape load (no tape) and the joystick paths in play (keyboard only).
  The details, the frames of every point and the enemies: `work/stage1/NOTES.md`.
- Each course has 31 segments (the start, 25 points, 5 sector ends); the scripts are `$B7E8` and `$BB24`, read by
  `$9751` (`tools/course.py`).
- The enemies, named by the game's own SCORE ADVANCE TABLE (`a1` frame 19 800): UFO saucers, the spinner UFO, UFO
  bombs, rocks, craters, mines, tanks and their shells, the low flyer from behind, boulders of three sizes, the green
  plant. Champion only: the low flyer, the boulders, the plant. Screens of each: `docs/img/play/`.

### 6.1 Screens of each recording

Each screenshot was taken with `../../kit/screen_shot.py` at the start of the named frame of its recording.

| Recording | Screen and frame |
| --- | --- |
| `a1` | [title](docs/img/play/a1-title.png) 100, [heroes-table](docs/img/play/a1-heroes-table.png) 300, [options](docs/img/play/a1-options.png) 700, [player1](docs/img/play/a1-player1.png) 1330, [play-beginner](docs/img/play/a1-play-beginner.png) 1700, [hold](docs/img/play/a1-hold.png) 2100, [abort-title](docs/img/play/a1-abort-title.png) 3200, [score-advance-table](docs/img/play/a1-score-advance-table.png) 19 800, [demo](docs/img/play/a1-demo.png) 20 800 |
| `g1` | [game-over](docs/img/play/g1-game-over.png) 3950, [heroes-entry](docs/img/play/g1-heroes-entry.png) 4300 |
| `t1` | [title-during-save](docs/img/play/t1-title-during-save.png) 300 |
| `p2` | [two-player-hud](docs/img/play/p2-two-player-hud.png) 1050, [player2](docs/img/play/p2-player2.png) 1150, [game-over-player2](docs/img/play/p2-game-over-player2.png) 7700, [heroes-entry](docs/img/play/p2-heroes-entry.png) 7900 |
| `h1` | [initials](docs/img/play/h1-initials.png) 4500, [heroes-after-entry](docs/img/play/h1-heroes-after-entry.png) 4700 |
| `h2` | [greatest-name](docs/img/play/h2-greatest-name.png) 700, [greatest-initials](docs/img/play/h2-greatest-initials.png) 1200 |
| `i1` | [crater](docs/img/play/i1-crater.png) 450, [rock-point-a](docs/img/play/i1-rock-point-a.png) 1200, [ufos](docs/img/play/i1-ufos.png) 1800, [bonus-e](docs/img/play/i1-bonus-e.png) 5400, [sector-f-city](docs/img/play/i1-sector-f-city.png) 6600, [ufo-spinner](docs/img/play/i1-ufo-spinner.png) 9600, [tanks-point-y](docs/img/play/i1-tanks-point-y.png) 28 400, [bonus-z](docs/img/play/i1-bonus-z.png) 29 000, [champion-begins](docs/img/play/i1-champion-begins.png) 29 800 |
| `i2` | [champion-ufos](docs/img/play/i2-champion-ufos.png) 1480, [tank](docs/img/play/i2-tank.png) 2400, [boulders](docs/img/play/i2-boulders.png) 3300, [green-plant](docs/img/play/i2-green-plant.png) 4200, [mines](docs/img/play/i2-mines.png) 12 950, [low-flyer](docs/img/play/i2-low-flyer.png) 29 300, [bonus-z](docs/img/play/i2-bonus-z.png) 30 000, [loop-to-beginner](docs/img/play/i2-loop-to-beginner.png) 31 000 |

## 7. Review
