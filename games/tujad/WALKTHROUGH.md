# Tujad: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

Asked: which copy is the original Ariolasoft release, what is on it, and where does each block land?

ZXDB (the local `catalog-sources/zxdb/v1.0.242/zxdb.sqlite`, entry 5448) lists three downloads for the game: the TZX
33911 (release 0, source type "O", "Original release"), a TAP 33912 of the same release and the Dro Soft TZX 143623
(release 1), and an input recording, `tujad.rzx` (161527). All four are in the local ZXDB mirror and were copied
unchanged to `work/candidates/zxdb/`; every Tujad file of `software/zxart.ee-offline` went to
`work/candidates/zxart-offline/` and the TOSEC pack's 14 files to `work/candidates/tosec-knobchez-2026/`. The TZX
33911 is `orig/Tujad.tzx.zip`, still zipped.

```bash
. work/env.sh
md5 orig/Tujad.tzx.zip; shasum orig/Tujad.tzx.zip
unzip -o orig/Tujad.tzx.zip -d work/media/zxdb-Tujad.tzx
python3 tools/tzxblocks.py list work/media/zxdb-Tujad.tzx/Tujad.tzx            # archive info + 5 ROM blocks
for i in 1 2 3 4 5; do python3 tools/tzxblocks.py work/media/zxdb-Tujad.tzx/Tujad.tzx $i work/stage1/blocks/o-$i.raw; done
python3 tools/basic_list.py work/stage1/blocks/basic.bin                       # line 10
python3 tools/media_compare.py work/media/zxdb-Tujad.tzx/Tujad.tzx work/candidates --out work/stage1/media-compare.tsv
python3 tools/image.py work/mkgame/original.bin                                 # the image as loaded
z80dasm -a -t -g 0x60C0 work/stage1/game.bin > work/stage1/g.asm
python3 ../../kit/sig_scan.py work/mkgame/original.bin --base 0 --all --out work/stage1/sig-game.json   # no hit
```

Found:

- **The original is ZXDB download 33911.** ZXDB marks it the original release and its archive info says "Original".
  Every other copy is a conversion of its blocks, a translation (Dro Soft into Spanish, Sinclairsoft, Kis and Prospekt
  into Russian), a crack, a TR-DOS conversion or a snapshot of a game in progress; the README's table lists each with
  what differs, from `work/stage1/media-compare.tsv`.
- **The tape** ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)): a BASIC header "TUJAD" (LINE 10,
  88 bytes), a one-line BASIC (`CLEAR 24767 ... LOAD "" CODE 16384: RANDOMIZE USR 23296`), a CODE header "TUJAD"
  (6944 bytes, its start 32768 overridden), the CODE block (the loading screen and a stub at `$5B00`), and one
  headerless block of 40 256 bytes the stub loads with LD-BYTES to `$60C0-$FDFF`. The game is entered at `$6300`
  (`JP $68F3`). The signal lasts 262.85 s (13 163 frames).
- **A save routine in the stub** (`$5B10`: the same block with SA-BYTES `$04C2`), never reached: the mastering tool
  left on the tape.
- **No known module**: the signature scan finds nothing.
- **The image's text** (a strings scan of `$60C0-$FDFF`): the scrolling messages at `$63D3` on ("TUJAD FROM
  ORPHEUS", "EDS COMPLETED", "GEN 19 COLLECTED", "UCF REACTOR NO 14C DESTROYED"), the menu at `$8D38` ("1 KEYBOARD",
  "2 CURSOR JOYSTICK", "3 KEMPSTON JOYSTICK", "0 START GAME"), "1986 ORPHEUS LTD" at `$8D85`, "YOU HAVE COMPLETED %
  OF TUJAD" at `$9071`. And leftover assembler source text from the authors' editor in the variables area
  (`$6353-$686E`: "hl,(pos)", "lookup", "hl,alnmap", "scra1"), NOTES.md.

## 1. One recording from power-on

Asked: what runs from power-on to play, and how is play paced?

`c1` records from power-on: the 48K with zeroed RAM and muted sound, `LOAD ""` typed and the original TZX played
with the fast LD-BYTES trap and turbo tape off (`tools/rs_capture.py`), so every block loads from the signal at ROM
speed; 13 700 frames of load, then `tests/inputs/c1.txt`: the menu, 2 (cursor joystick), 3 (Kempston), 1
(keyboard), 0 (start), then play with the keyboard (right, Q up at the terminal, fire, left, down, SPACE weapon
select, ENTER pause and resume). 15 871 frames in all, `session.ttd` 6.0 MB, L1 1543 interrupts, 0 diverged.

```bash
. work/env.sh
python3 tools/rs_capture.py --work work/stage1/c1 --media orig/Tujad.tzx.zip --model 48K --record-load \
    --load-frames 13700 --inputs tests/inputs/c1.txt --ranges 4000-FFFF --port-base 36910 --binary $BIN
python3 work/stage1/tt.py 37110 '{"action":"probe_frames","probes":[{"probe":"exec","address":"0x6300"}]}'  # 13580
python3 $RS open --work work/stage1/entry --ttd work/stage1/c1/session.ttd --port-base 36900
python3 $RS build --work work/stage1/entry --from-frame 13580 --to-frame 13581 --into work/stage1/entry/f13580
python3 tools/passes.py --port-base 36900 --passes 400 --out work/stage1/passes.json \
    work/stage1/rec/menu-cursor/end.szx work/stage1/rzx/at0{1,3,5,7}0000.szx
```

| Stage | Entered | Frame of `c1` (ROM-speed load) | What runs |
| --- | --- | --- | --- |
| 0 | `$5B00` | 2908, T 8352 | the stub: LD-BYTES of the headerless block to `$60C0` |
| 1 | `$6300` | 13580 | `JP $68F3`: the setup, then the menu `$8854` (the RNG loop `$7DD5` from 13586) |
| 2 | `$95D0` | 14297 (the first interrupt taken) | play: the main loop `$6911` and the IM 2 handler |

The keys of the script land at frames 13900 (2), 14010 (3), 14120 (1) and 14230 (0); the rooms change at 14932,
15433 and 15493; no life is lost.

Found, interrupts and the frame (first look; stage 2 reads the routines):

- **IM 2 through `$5B5B`**: `$9584` fills `$FE00-$FF00` with 257 bytes of `$5B`, `$95B2-$95B7` writes `JP $95D0`
  at `$5B5B`, `$95BA-$95BE` sets I = `$FE` and IM 2. `$95C1-$95CF` (I = `$3F`, IM 1, `EI`, the ROM's CLS `$0D6B`,
  a white border) would go back to BASIC; it never runs in any recording.
- **The handler `$95D0`** does the frame's drawing and input: the controls (`$7161` into `$63C2`), every sprite of
  the list at `$FF01` drawn with XOR (`$95DB-$963F`), the message scroller (`$9640`), `$96CB`, the weapon select
  (`$7976`, CAPS SHIFT or SPACE on port `$7EFE` bit 0), `$7AB6`, `$7906` and the ROM's KEYBOARD (`$02BF`, which
  keeps `$5C04-$5C08`), then `EI; RETI` at `$96FB`. It runs 54 825 times over the 70 builds (`$96FB`).
- **DI / EI**: the setup starts with `DI` (`$68F3`) and `LD SP,$60C0`, and enables at `$6910`. The game runs with
  interrupts off: the main wait `$795D` is `EI; NOP; HALT` (`$796B-$796D`), `DI` (`$796E`). Ten other `EI`s run in
  the recordings (L1 counts over the 70 builds): `$6B2D` (279, the room setup `$6B22`, followed by `DI` at `$6E0B`),
  `$7F5B` (210) and `$7F6B` (649) after the two sweeps, `$7816` and `$7825` (13 each), `$777E` (8, with a HALT at
  `$777F`), `$8F5E` (36), `$6AA2` (1, with a HALT at `$6AA3`), `$6910` (4). `$6A22`, `$6F15`, `$6F17`, `$8D25`,
  `$8D2A` and `$95C7` never run. Other HALTs: `$6A26` (990, a wait loop entered with interrupts on) and `$6AA3`
  (512). The menu (`$8854`) runs with interrupts off, polling the keys while it calls the random-number step `$7DC9`
  (`$893B`), so the seed `$63A4-$63A7` depends on how long the player waits.
- **The main loop syncs twice a pass**: `CALL $795D` at `$6911` and at `$6929`. So a pass is at least two frames.
- **Frames per pass** (`tools/passes.py`, a muted instance on base 36900 through the WebAPI: skip_until `$6911`,
  the beam's frame and T-state; 200 whole passes from each state, no key held; `work/stage1/passes.json`):

  | State | Room | Frames a pass (count of 200) | Mean | Median T | Heaviest T |
  | --- | --- | --- | --- | --- | --- |
  | `rec/menu-cursor/end.szx` | 84 | 2: 200 | 2.00 | 141 273 | 192 312 |
  | `rzx/at010000.szx` | 73 | 1: 9, 2: 180, 3: 11 | 2.01 | 139 776 | 178 740 |
  | `rzx/at030000.szx` | 51 | 1: 15, 2: 162, 3: 23 | 2.04 | 140 489 | 209 713 |
  | `rzx/at050000.szx` | 102 | 1: 11, 2: 159, 3: 30 | 2.095 | 144 561 | 210 142 |
  | `rzx/at070000.szx` | 34 | 1: 9, 2: 176, 3: 15 | 2.03 | 139 840 | 207 799 |

  The median, 139 776 T in room 73, is exactly two frames (2 x 69 888). The 1-frame passes (9-15 of 200) are a
  question for stage 2: with two waits a pass, one of the waits did not wait for a new frame. In play with keys, `energy-out`'s L1 has `$6911` 2434 times in
  5001 frames: 2.05 frames a pass. The half pass (one wait to the next, 400 from each state) has a median work of
  13 483-26 612 T and at most 35 278 T (room 51); the handler runs about 36 000 T in the median and 63 013 T at most
  (room 73), so most of a frame is the handler's sprite drawing.
- **The heaviest pass**: 210 142 T (3 frames), from the RZX state after 50 000 frames (room 102), no key held.
  The heaviest half pass with its handler: 97 122 T (room 51), more than a frame.

## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

Stage 1 builds nothing in unreal-ng; these gaps were found and worked around.

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |
| A TTD recording cannot hold an RZX playback: `/rzx/play` loads the RZX's snapshot, which ends the TTD session; a TTD started during the playback stays at "frames 0..1", and the L1 build then fails ("the recording is shorter than one frame"; `work/stage1/lab/rzxttd.py`) | worked around: the RZX's keys were logged frame by frame (`tools/rzx_keys.py log`: the variables `$6300-$63FF` after each of 81 000 frames and a saved state every 1000) and replayed as input scripts from the saved states, which the TTD records | not fixed |
| The fast LD-BYTES trap stays on while TTD records, so a capture loads the tape in 700 frames, not at its real length (`work/stage1/c1-trap`) | `tools/rs_capture.py` sets `fast_tape` and `turbo_tape` off before the load | not fixed |
| An RZX's keys replayed from a saved state do not keep to the RZX for long: the game is timing-bound (the interrupt counter `$6366` and the random number `$63A4-$63A7`, stepped by the menu and by play, part within hundreds of frames, after which a key lands in another state) | `tools/rzx_align.py` checks every frame against the RZX's log and ends a chunk at the first frame that matches no sample: 59 chunks, 42 952 frames, each a recording | not a fault of unreal-ng: the RZX's own playback (`/rzx/play`, tolerant) runs all 80 680 frames to the win |

## 6. The game

### 6.0 The recordings

Asked: which recordings reach every part of the game, and how was each made?

Every recording keeps its `session.ttd`, `l1.json`, `states.json` (the room `$6363`, the lives `$636D`, the energy
`$636E` and the controls `$63C2` every 25-60 frames) and its screenshots, in `work/stage1/rec/<name>/` (`c1` in
`work/stage1/c1/`). All but `c1` start from a saved state and are made by `tools/record.py` (a fresh muted instance on
base 36910, the state loaded, the TTD started, the script played one run call a segment, L1 built):

```bash
python3 tools/record.py --start work/stage1/menu.szx --inputs tests/inputs/menu-cursor.txt --work work/stage1/rec/menu-cursor --shot 50
python3 tools/record.py --start work/stage1/menu.szx --inputs tests/inputs/game-over.txt --work work/stage1/rec/game-over \
    --poke 200,0x636D,0 --poke 200,0x636E,1 --shot 25
python3 tools/record.py --start work/stage1/rec/menu-cursor/end.szx --inputs tests/inputs/room-tour.txt \
    --pokes tests/inputs/room-tour.pokes --work work/stage1/rec/room-tour --shot 60
python3 tools/rzx_keys.py log --rzx work/candidates/zxdb/tujad.rzx --out work/stage1/rzx       # 81 000 samples
python3 tools/rzx_align.py --log work/stage1/rzx --from 1000 --out work/stage1/rzx-chunks     # 59 scripts
for f in tests/inputs/rzx/rzx-*.txt; do n=$(basename $f .txt); \
  python3 tools/record.py --start work/stage1/rzx/at0${n#rzx-0}.szx --inputs $f --work work/stage1/rec/$n --shot 50; done
```

`work/stage1/menu.szx` is `c1`'s `start.szx`: the menu at `c1` frame 13700. The `at<N>.szx` states are the RZX
playback's, saved after N of its frames (`/rzx/play`, tolerant; [WALKTHROUGH 5](#5-tool-gaps-found-and-fixed-in-unreal-ng)).

| Recording | Start | How | Frames | What it reached |
| --- | --- | --- | ---: | --- |
| `c1` | power-on | the tape at ROM speed, then `c1.txt` (menu 2, 3, 1, 0; keyboard play) | 15 871 | the load, the menu with every option, play in room 84 and three more rooms, the progress screen (Q at the terminal), the pause (ENTER) |
| `menu-cursor` | `menu.szx` | `menu-cursor.txt`: 2, 0, play with the cursor keys | 1201 | the cursor-joystick method (`$63C2` = `$41` with right held: bit 6 the method) |
| `menu-kempston` | `menu.szx` | `menu-kempston.txt`: 3, 0, play with the Kempston stick | 1201 | the Kempston method (`$63C2` bits 6 and 7 clear) |
| `energy-out` | `rzx/at047000.szx` (room 76, energy 18, lives 5) | no key | 5001 | the energy run down by the enemies to 0 and a life lost between frames 1550 and 1600 (lives 5 to 4, the energy back to 99) |
| `game-over` | `menu.szx` | `game-over.txt`: 1, 0, no key; **POKE** `$636D` = 0 and `$636E` = 1 at frame 200 | 3121 | the last life lost (lives `$99` by frame 400), "YOU HAVE COMPLETED 0% OF TUJAD" from about 450 to 950 with the game-over message scrolling in the panel (shot at 700), the menu from about 975 |
| `win` | `rzx/at080000.szx` (every ED complete, room 84) | no key | 1501 | "CONGRATULATIONS TUJAD HAS NOW RESUMED NORMAL FUNCTIONS WELL DONE" over the circuit-board picture (25-475), then the menu (550) |
| `room-tour` | `rec/menu-cursor/end.szx` | 8 (right) held; **POKEs** (`room-tour.pokes`): every 60 frames the room `$6363` = r - 1, x `$6359` = `$1C`, lives `$636D` = 9, energy `$636E` = `$99`, so the game's own room change (`$7403`) draws room r | 7681 | the game moved into 65 rooms: 53 of the 102 rooms (11 of them shot nowhere else: the world map's starred cells) and 12 of the 26 empty slots, drawn empty |
| `room-23` | `rzx/at005000.szx` (the RZX in room 23) | no key | 100 | room 23 |
| `rzx-free-29000`, `-31000`, `-32000` | `rzx/at029000.szx`, `at031000`, `at032000` | the RZX's keys for 1000 frames, unchecked (they part from the RZX) | 1001 each | rooms 43, 106 and 91, which the checked chunks end before |
| `rzx-001000` ... `rzx-080000` (59) | `rzx/at<N>.szx` | the RZX's keys, checked frame by frame (`tests/inputs/rzx/`) | 42 952 in all (2-3706) | 90 rooms; the hazard death in `rzx-035000` (room 109 to 117, lives 5 to 4 between frames 200 and 250) |

The POKEs never reach the image: `tools/image.py` builds it from the tape alone, and every POKE recording is named
here. The poked bytes are variables (`$6359`, `$6363`, `$636D`, `$636E`); they garble the panel's digits in the tours.

Coverage:

- **The menu and every control method**: the menu has four entries, 1 keyboard, 2 cursor joystick, 3 Kempston
  joystick, 0 start (`$8D38`); `c1` presses all four, and each method is played (`c1` keyboard, `menu-cursor`,
  `menu-kempston`). The pause (ENTER, `$793A`) and the weapon select (SPACE) are in `c1`.
- **Every room and the world map**: the room table at `$DB53` has 128 entries; 26 point at one empty record
  (`$DFFA`, all zero), and the RZX's complete game (80 680 frames, the win) never enters those 26. The other 102
  rooms are all shot by the recordings: 91 in recordings without a POKE, 11 in `room-tour` only
  ([the world map](#61-the-screens)).
- **Objects, enemies and pickups**: the sprite lists of all saved states hold 28 graphics (the player's five, the
  enemies' pre-shifted buffers, the objects at `$B16D-$BAE2`; [doc 2.6](docs/02-architecture.md#26-the-sprites-first-look)).
  What each one is (enemy, ED, weapon, generator) is stage 2's work; the RZX chunks cover the whole game, so every
  kind the game uses appears in them.
- **Every way to lose a life**: the energy running out (`$6A30`; `energy-out`) and a hazard, which takes the life at
  once (`$75C8`, `JP NZ` at `$75E1` to `$6992`; `rzx-035000`). Game over: `game-over`. The win: `win` and the RZX.
- **The hi-score table and the name entry**: the game has none. The image holds no score text ("SCORE", "HIGH",
  "NAME", "BEST", "TABLE": no hit), and the game over goes straight to the progress screen and the menu
  (`game-over`).
- **Every sound**: the game's sounds are its `OUT ($FE),A` sites; L1 counts of each over the recordings:

  | Site | Routine | What it plays | Reached in |
  | --- | --- | --- | --- |
  | `$7F79` | `$7F6D`, called from the main loop at `$6914` | two edges a pass: a tick | every play recording |
  | `$7B68`, `$7B6C` | `$7B65` | 50 cycles while a digit is printed | every play recording |
  | `$785A` | `$7856` (called from `$7837`) | a tone of 256 edges | `c1`, `menu-cursor`, `menu-kempston`, `room-tour`, RZX chunks |
  | `$7F61` | `$7F5D` (called at `$7B2B`, `$808E`) | a rising sweep, interrupts off | `energy-out`, `game-over`, `room-tour`, RZX chunks |
  | `$7F51` | `$7F4D` (called at `$8091`) | a falling sweep, interrupts off | RZX chunks |
  | `$7FD0` | `$7F9C` | 30 edges per row of a column drawn with attribute `$42`/`$A0` | RZX chunks |
  | `$801A` | `$8005` (called at `$782D`) | the same per row | RZX chunks |
  | `$69D5` | `$69C3-$69E2` | an edge per row of a five-row fill | `menu-cursor`, `menu-kempston`, RZX chunks |

  `$88E2` (`OUT` 0 when the menu screen is set up) and `$95CD` (the white border of the exit to BASIC, never run) are
  the border only. Every sound site runs in at least one recording.

### 6.1 The screens

Asked: what does each screen look like, at which frame?

Each figure is the screen at the named frame of the named recording (`c1`'s frames count from power-on, the ROM-speed
load included).

| Screen | Figure | Recording, frame |
| --- | --- | --- |
| the loading screen | [loading.png](docs/img/play/loading.png) | the CODE block's first 6912 bytes (`work/stage1/blocks/b4.bin`), on the screen from `c1` frame 2908 |
| the menu | [menu.png](docs/img/play/menu.png) | `c1` 13950 |
| the start room (84), the TUJAD terminal, "TUJAD FROM ORPHEUS" | [start-room.png](docs/img/play/start-room.png) | `c1` 14450 |
| the progress screen (Q at the terminal) | [progress.png](docs/img/play/progress.png) | `c1` 14700 |
| a room with enemies | [room-enemies.png](docs/img/play/room-enemies.png) | `c1` 14950 |
| a room being drawn | [room-drawing.png](docs/img/play/room-drawing.png) | `c1` 15450 |
| a room with the domes | [room-domes.png](docs/img/play/room-domes.png) | `c1` 15700 |
| the energy at 1 | [energy-low.png](docs/img/play/energy-low.png) | `energy-out` 1550 |
| the life lost to the energy | [energy-out-after.png](docs/img/play/energy-out-after.png) | `energy-out` 1600 |
| before the hazard (room 109) | [hazard-before.png](docs/img/play/hazard-before.png) | `rzx-035000` 200 |
| after the hazard (room 117, a life lost) | [hazard-after.png](docs/img/play/hazard-after.png) | `rzx-035000` 250 |
| the game-over message over the 0% screen | [game-over-message.png](docs/img/play/game-over-message.png) | `game-over` 700 |
| "YOU HAVE COMPLETED 0% OF TUJAD" | [game-over-progress.png](docs/img/play/game-over-progress.png) | `game-over` 900 |
| the win: "CONGRATULATIONS" | [win-congratulations.png](docs/img/play/win-congratulations.png) | `win` 100 |
| the win: "WELL DONE" | [win-well-done.png](docs/img/play/win-well-done.png) | `win` 475 |
| the world map | [world-map.png](docs/img/play/world-map.png) | below |

![The 128 room slots: 102 rooms and 26 empty entries](docs/img/play/world-map.png)

*The world map (`tools/fig_worldmap.py work/stage1/rec docs/img/play/world-map.png --json work/stage1/world-map.json`):
the room numbers run 8 to a row (+1 east, +8 south, the room changes at `$7403`, `$7477`, `$74BE`, `$750F`); each
cell is the play area of a shot in that room (the source of each in `work/stage1/world-map.json`). The starred cells are from `room-tour`.*

## 7. Review
