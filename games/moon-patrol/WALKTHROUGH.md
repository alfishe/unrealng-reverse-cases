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
  assembler: `20:15 29/10/84` at `$90BD`, `02:45 29/10/84` at `$B2C7`, `03:35 30/10/84` at `$7F05`, `03:40
  30/10/84` at `$A187`. A default hi-score name is `SPIKE NOTWELL` (`$88AD`).
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

## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

## 7. Review
