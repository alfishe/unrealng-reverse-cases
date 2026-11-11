# Battle Command: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number. Every
recording of this case loads at signal speed (fast and turbo tape off); all but c1 start from
`work/stage1/explore/loaded.szx`, the title after side 1 loaded at signal speed (`work/stage1/explore1.py`).

## 0. The medium

### 0.1 The files

`orig/BattleCommand.tzx.zip` is ZXDB download 3059, copied unchanged; its hashes and the two sides' hashes are in
the [README](README.md). The sides are unpacked in `work/stage1/media/side1.tzx` and `side2.tzx`; the other copies
sit in `work/candidates/<source>/`, unpacked in `work/stage1/media/`.

### 0.2 The release check

Each copy's blocks were listed with `python3 tools/tzxblocks.py list FILE` and compared byte for byte with the
Ocean blocks and with the eight banks of the game image (`work/stage1/findblocks.py IMAGE TAPE`: where each block's
bytes sit in the banks).

- **Ocean, side 1**: no data block is found in memory as it is on the tape: SpeedLock 7 deciphers while it loads
  ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)).
- **Erbe, side 1**: six of its seven ROM-speed blocks are byte for byte banks 5 (`$5B00-$7FFF`), 0, 3, 4, 6 and 7
  of c1 at the entry (frame 23974): the same program without the protection.
- **Side 2**: Erbe, the TAP crack and the TOSEC TZX carry the catalogue and the ten missions byte for byte as the
  Ocean side 2, except Missile Battery (mission 2): the Ocean block holds 6384 data bytes where its own header says
  `$1906` = 6406; the first 3488 bytes agree.
- **What the game does with the Ocean mission 2**: the m2ocean recording winds the Ocean side 2 to mission 2's
  header; SEARCH lights Missile Battery (frame 4767), SELECT reads the block, and the game stays on the catalogue
  screen with the tape read past it: frames 7322 to 13 322 show the same screen and no stores screen
  ([mission-tape.png](docs/img/play/mission-tape.png), the "still" tiles). The m2erbe recording does the same with
  the Erbe side 2: mission 2 loads (in play at frame 7201) and its map screen (frame 7386) shows the roads and rivers
  of the mission 2 briefing map (menu frame 7090, [briefing-maps.png](docs/img/play/briefing-maps.png)). The Ocean
  tape in ZXDB 3059 thus has a short mission 2 block (a bad dump of that block, or a mastering fault); the Erbe block
  is the one the game accepts.
- **`BATTLECO.Z80`** (NVG snaps, 128K): `work/stage1/z80cmp.py` compares its eight pages with the image at the entry
  and in play: only scattered 256-byte runs agree, the layout differs (another build or a relocated crack). It is
  not used as a witness.
- **The demos** (`btcom128`, `BCTANK.Z80`) are other programs (README).

The original is the Ocean tape (README).

### 0.3 The load

c1 loads side 1 with the 128K menu's Tape Loader at signal speed: the tape is played at frame 208, the BASIC loads
by frame 1999, the SpeedLock loader runs from frame 2484 and jumps into the game at frame 23974 (stage 23, `JP $68F4`
at `$8043`); the title is on screen at frame 24508. Doc 3 has the blocks, the stages and the bootstrap
([3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)).

### 0.4 The machine: 128K only

`work/stage1/try48.py` loads side 1 on a 48K at signal speed and logs the PC every 2000 frames
(`work/stage1/try48.log`): the loader runs (PC in `$B1BD-$BDB9`) to frame 24232, and at frame 26232 the PC is
`$10AC` in the 48K ROM: the machine restarted to the Sinclair copyright screen after the load. The loader pages
banks through `$7FFD` (doc 3), which a 48K ignores, so the code it jumps to is not there. ZXDB and the
instructions ("Spectrum Tape +2/+3") agree: 128K only.

## 1. Interrupts and timing

**The mode.** The entry at `$68F4` runs `DI`, `LD SP,$81FF`, fills `$8200-$8300` with `$83` (`LDIR` at `$6903`),
sets `I` = `$82`, `IM 2`, `EI`: every vector reads `$8383`, the handler (doc 2, bank 2). No `HALT` is executed in
any recording (none in the L1 instruction lists).

**The handler** (`work/stage1/dis.sh work/mkgame/original.bin 8383 8443`):

```
$8383 DI / EX (SP),HL / LD ($842B),SP / LD SP,$7C49   ; its own stack in bank 5
$838C PUSH IY, IX, AF, AF', HL, DE, BC, HL', DE', BC'
$839B CALL $7E6E, $72D2, $7DFB, $8836, $8459, $8475, $848F, $7D80, $87D6
$83B9 LD A,0 / INC A / JR NZ,$8404     ; the operand at $83BA is a flag written by other code
$83BE LD A,0 / AND A / JP Z,$83DF      ; the operand at $83BF is a second flag
$83C4 CALL $8431, $D251, $897E, $D0CA, $83F1, $D142, $D27C, $D1BE, $843A
$83DF CALL $885F, $88CF, $8999, $72D2, $8AEC / JP $841C
$841C POP the registers, SP back from $842B, return
```

`python3 $RS interrupts --work work/stage1/rec/NAME` over each recording's L1:

| Recording | Handler entries | A frame | T an entry | CPU share |
| --- | --- | --- | --- | --- |
| c1 | 4124 in 33 299 frames (the load runs under `DI`) | | | 2.3 % |
| menu | | 0.69 | | 12.5 % |
| play | 5510 in 10 967 frames | 0.50 | 14 073 | 10.0 % |

In play the nine calls at `$839B` run on every entry (5510 times each), the block at `$83C4` on 3423 entries, the
block at `$83DF` on 706. Half the interrupts of play are not taken: the code runs long stretches under `DI` (the
back-buffer clear `$96F1`, which points `SP` at the buffer for its `PUSH` loop, and `$9941-$99C0`), and an interrupt
that arrives under `DI` is lost.

**The paging.** One routine pages: `$7270-$7287` in bank 5 (`OUT (C),A` at `$727F`, 54 858 times in c1), with
entries for banks 4, 7, 6 and 0 (doc 2). The other `OUT`s are `$D7E4` / `$D7EB` in bank 0 (10 907 times in c1, the
AY candidates) and `$C16F` in bank 4.

**The 3D frame.** A pass of the 3D view clears the back buffer once (`$96F1`) and runs `$C7BC` once, so the count
of `$96F1` in a window of the playx build (play, `re_session.py build --from-frame/--to-frame`) is the passes in it:

| play frames | On screen | Frames a pass |
| --- | --- | --- |
| 8370-8970 | the normal view, three windows of 200 frames | 7.7, 7.4, 7.1 |
| 9115-9315 | the Dragonfly's view | 8.0 |
| 9805-9995 | binoculars and zoom | 6.8 |
| 10 065-10 125 | the rear view | 12 (the heaviest measured) |
| 10 520-10 620 | the console after the map | 11.1 |

Over play frames 8400-9400: 128 passes in 1000 frames, 7.8 frames a pass (6.4 passes a second). The main loop is
not tied to the interrupt (no `HALT`); the pass takes as long as the scene needs.

## 2. Static pass over the medium

Stage 2.

## 3. The stages and the packers

The stages of c1 are in [doc 3](docs/03-build-and-load.md#the-stages); the 19-layer decryption chain and the
SpeedLock loader are stage 2's.

## 4. The medium from source

Stage 2 and later.

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

None fixed in stage 1. Open: with the Kempston mouse chosen, the game resets when the mouse moves (6.0, controls);
whether the game or the emulator's mouse is at fault is not yet known.

## 6. The game

### 6.0 The recordings

Every recording is made by `python3 tools/record.py PLAN --work work/stage1/rec/NAME --port-base 37310 [--start
work/stage1/explore/loaded.szx]` (the plan's docstring is its description) and keeps `session.ttd`, `l1.json`,
`record.json` (tape actions, POKEs, moments) and its input script `tests/inputs/NAME.txt`. All load at signal speed.
The tape is wound with `POST /tape/seek` to a mission's header, as a player winds it: SEARCH reads up to the next
mission header on the tape, whichever it is (the search recording), so the first runs that only pressed SEARCH loaded
the wrong missions and were thrown away. In play the game reads the keys once a pass, so the scripts hold a key 25
frames.

| Name | Frames | Start | POKEs | What it reaches |
| --- | --- | --- | --- | --- |
| c1 | 33 299 | power-on | none | side 1 by its own loader, the title, OPTIONS, START GAME, the mission tape's catalogue, Blast Em Mission searched and loaded, the Turret fitted, a short drive with the cannon |
| menu | 10 997 | title | none | OPTIONS with control systems 1 (Sinclair), 2 (cursor) and 5 (keyboard), the pointer moved with each; LOAD GAME with a code; the catalogue; the briefing text and map of all ten missions; STATUS; a save code |
| controls | 406 | title | none | OPTIONS 4 (Kempston joystick): up, down, left and right each move the pointer (frames 152-194), and it reaches OPTIONS (221); OPTIONS 3 (Kempston mouse): the pointer does not follow the mouse, the pointer variables read 23 296, 72 at frame 335, and the machine resets to the 128K menu (frames 363, 406) |
| missions | 35 998 | title | none | missions 1 and 3-10 wound to, searched, selected: 1 and 3-9 load, start, drive, map screen, quit; mission 10 goes back to the status screen (35 336) |
| m2ocean | 13 322 | title | none | Ocean mission 2 found (4767), selected: the block does not load, no stores screen in 6000 frames |
| m2erbe | 7809 | title | none | the Erbe side 2's mission 2: loads, played (7201), its map (7386), quit |
| m10 | 9029 | title | none | Grand Finale found (4717), SELECT: the status screen again (8349), no load |
| search | 7196 | title | none | three SEARCHes after the catalogue: Blast Em, then Missile Battery, then Hostage Rescue light in turn |
| play | 10 967 | title | `$C1C6`, `$C875` (bank 6) | Blast Em Mission with Banshee RRSS, K-40 Mortar, Dragonfly, Phantasm, each fired, the Dragonfly flown; the views N, B, Z, R, H, D, C, M and the map's briefing; pause; quit |
| play2 | 23 666 | title | as play, three times | the other nine stores (Turret, Banshee IRSS, Phoenix RRSA, Sleeper mine; Phoenix IRSA, K-90 Cluster, Spectre, Skeet bomb; SLAM Laser), each fired |
| death | 20 039 | title | none | Blast Em Mission with the Turret driven and fired for 12 000 frames: TANK HIT messages, no death |

The POKEs come from the release's `.pok` (6.3) and are written into bank 6 of the recording's machine at the
stores screen and at the mission start (frames in `record.json`); the image of the case is cut from c1, never from
these.

Grand Finale refuses SELECT in m10 and in missions: the status screen reads MISSIONS COMPLETED 000, so the last
mission is likely locked until the others are done. Not reached by any recording: a mission completed, a death,
game over, the score and rank, Grand Finale in play.

### 6.1 Screens

Drawn by `python3 tools/fig_shots.py OUT.png COLS rec:glob ...` from the recordings' named screens; each tile is
labelled with its recording and frame.

![The menus](docs/img/play/menus.png)

*The menus: the 128K menu, the load, the title, OPTIONS, LOAD GAME, the mission tape, the catalogue, SEARCH, STATUS
and the save code, the stores screen, pause and quit.*

![The controls](docs/img/play/controls.png)

*The controls recording: the Kempston joystick moves the pointer; with the Kempston mouse the pointer stays and the
machine resets (frames 363, 406).*

![The ten briefings](docs/img/play/briefings.png)

*The briefing text of the ten missions (menu).*

![The ten briefing maps](docs/img/play/briefing-maps.png)

*The briefing map of the ten missions (menu): roads, rivers, P, T and X marks. These are the game's own maps; a map
drawn from the mission data is stage 2's.*

![The mission tape](docs/img/play/mission-tape.png)

*m2ocean: Ocean mission 2 found, then the same catalogue screen for 6000 frames; m10: Grand Finale found, then the
status screen.*

![The missions in play](docs/img/play/missions.png)

*missions and m2erbe: the start of missions 1-9 and the map screen of each; mission 10 refused. Night Moves
(mission 5) has a dark blue sky.*

![The weapons](docs/img/play/weapons.png)

*play and play2: each of the 13 stores fired, the Dragonfly launched, flown and back.*

![The views](docs/img/play/views.png)

*play: night sight, binoculars and zoom, rear view, the Helicarrier, the damage screen, the console, the map and its
briefing.*

### 6.2 The images

The eight banks were dumped with `time_travel memory_at` (`tools/image.py` for the entry; `work/stage1/img/`) at c1
frames 23974 (the entry), 24508 (the title), 28827 (the catalogue loaded), 31954 (mission 1 loaded), 32999 (play)
and death frames 7939 and 13 939 (play, 6000 frames apart); `work/stage1/diffimg.py A B` counts the bytes that
differ per bank:

| From, to | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| entry, title | 1 | 0 | 650 | 343 | 95 | 3736 | 30 | 13 |
| title, catalogue | 0 | 0 | 1919 | 303 | 6542 (`$CB64-$E737`) | 6265 | 50 | 8 |
| catalogue, mission 1 | 7068 (`$DBC5-$FB3E`) | 0 | 1892 | 7105 (`$DCBC-$FB3E`) | 4 | 5600 | 469 | 8 |
| mission 1, play | 306 | 0 | 831 | 132 | 4 | 6161 | 67 | 6 |
| play, play + 6000 frames | 286 | 0 | 313 | 140 | 4 | 978 | 4 | 0 |

Bank 1 never changes after the entry; bank 7 hardly (read-only data); bank 4 takes the catalogue; a mission writes
bank 0 (the block) and bank 3 (a work area of nearly the same span). In play the changes are the screen, the back
buffer and the variables: bank 5 `$75F7-$7B8F` (the 24 records of 60 bytes at `$75F0`), bank 2 `$8199-$81FE` (the
stack), `$83BF-$845B` (the handler's flag and its variables) and `$8CB1-$9692` (the back buffer), and the rows
`$FC00-$FF53` of banks 0 and 3. The world and the 3D models are not yet located (bank 7 is the lead).

### 6.3 The state variables and the POKEs

| Variable | Address | Witness |
| --- | --- | --- |
| slot 1's ammunition | `$836D` (bank 2) | death: 79 at frame 7939, 69 at 9939, 59 at 11 939, 49 at 13 939 (one cannon round every 200 frames); read by `$B550 LD HL,$836D / LD A,(HL) / DEC A` |
| the pointer | X `$7C51`, Y `$7C53` (bank 5) | `tools/bcbot.py` reads them and its moves land where it aims (menu) |
| the mission clock | the 0-59 counter stored at `$7E11` | the infinite time POKE (below) |
| position, heading, damage | not found | |

The release's `.pok` (`work/candidates/docs/Battle Command (1990)(Ocean Software).pok`), each checked against the
code at the moment it applies (`Z 8` = whatever bank is paged at `$C000`):

| Cheat | POKE | At that address | Result |
| --- | --- | --- | --- |
| Infinite Ammo | 46420 (`$B554`) = 0 | `DEC A` after `LD HL,$836D / LD A,(HL)` | the slot's ammunition is not decremented |
| Infinite Time | 32273 (`$7E11`) = 0 | `LD (HL),A` in the 0-59 counter | the clock is not stored |
| Immunity | 51317 (`$C875`) = 58 | `LD B,255` in bank 6 becomes `LD A,(nn)` | applied in play and play2; no damage seen |
| No Weight Limit | bank 6 49606 (`$C1C6`) = 58 | the stores screen's weight check | applied in play: a 1150 kg payload accepted |
| Infinite Missiles, Fuel, Damage, Payload Weight, Ammo Number | 50161, 43352, 51912 / 51944 / 51992, bank 6 49593, 49582 | not the instruction a cheat would patch at the moments dumped | not checked yet (likely in a bank or a mission block not paged then) |

## 7. Review
