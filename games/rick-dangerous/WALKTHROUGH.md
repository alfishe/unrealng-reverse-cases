# Rick Dangerous: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The original is ZXDB's `RickDangerous.tzx.zip` (release 0, Firebird, scheme "Firebird BleepLoad"). Its hashes, and
the release check against ZXDB entry 4135, are in the [README](README.md). The release data came from the
spectrumcomputing.co.uk entry page (`work/stage1/sc-4135.html`) while the ZXInfo API returned 502. The search for other
copies:
- `tools/fetch_copies.py` fetched every copy in the collection index into `work/candidates/`;
- `tools/copy_blocks.py` compared the tapes block by block;
- a search for the game image's 562 pieces of 64 bytes went through every copy (`work/stage1/copy-image.txt`).

The results are in the README's copies table. The disk release holds 558 of the 562 pieces. The MCM and Erbe
re-releases and TOSEC `[a2]` are a later build: code moved +8 from `$A13B`, +26 from `$E2D1`, down to +19 at `$F88C`
(397 of the 562 pieces found; ZXDB's IBSA file calls itself MCM). The Kixx copy is packed and was not compared.

`tools/tzxblocks.py list` lists the tape: a BASIC loader, the 512-byte first stage "Rick1" at `$CD00`, then three
groups of Bleepload turbo blocks (48 + 140 + 6). [Doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)
has the table. The turbo payload is enciphered: none of its 37 376 bytes equals the image byte at its destination.
So the game image is not cut from the tape. SkoolKit's `tap2sna.py` instead simulates the whole load on a 128K up to
the entry `$AB4D` (`python3 tools/image.py work/mkgame/original.bin`, `case.json` `image_cmd`). Its image matches the
emulator's at the entry in `c1` except 39 bytes (`$5B89`, `$5BC7-$5BD2`, `$5BD7-$5BE9`, `$5BEB-$5BEC`, `$5BFB`, `$5C06`, `$5C78`,
`$FFFE-$FFFF`), which the game overwrites before it uses them
([doc 2, 2.3](docs/02-architecture.md#23-the-images-loaded-at-the-entry-in-play)).

The SAM Coupe port's source disk (zxart, ZXDB 38305): not used (only the standard Spectrum releases).

## 1. One recording from power-on

`c1`: power-on on the 128K, the 128 menu's Tape Loader, the original TZX at ROM speed (`re_session.py capture
--record-load`, `--load-frames 30000`), then the input script `tests/inputs/c1.txt` from frame 30 000. That is
33 400 frames.

| Frame (`c1`, ROM speed) | What |
| --- | --- |
| 0 | power-on |
| 0-19 010 | BASIC, "Rick1", then the turbo groups 1, 2 and 3; the interrupts are disabled through the turbo load |
| 19 010 | the entry `$AB4D` (DI, `LD SP,0`, `CALL $A043`); DetectPaging's test write at T-state 70 589; the RAM 1 copy starts at 70 632 and ends in frame 19 012 |
| 30 250 | the menu ([menu](docs/img/play/menu.png)) |
| 30 500 | the intro text of level 1 |
| 31 000 | level 1 in play |
| 33 250 | Q quits: GAME OVER |

**Interrupt mode.** IM 2 with `I` = `$83`. The table `$8300-$8400` holds 257 bytes of `$FE`, so whatever the bus
holds, the vector is `$FEFE`. The handler at `$FEFE-$FF1D` does the following:
- DI, then pushes the registers;
- adds 1 to `$A237`;
- calls `$E49B`;
- on the 128K, calls the music tick `CALL $A030` (patched in at `$FF11` at the entry);
- pops the registers, then EI and RET.

The handler runs once per interrupt. In `c1` the L1 counts 14 301 executions of `$FEFE` in 33 400 frames, and the
same count for `$A030`: one a frame from the entry on. The turbo load runs with the interrupts off.

**The main loop and the frame.** The main loop at `$E3C9` waits at the HALT at `$E40F`, and `$E411` then clears
FrameTicks `$A237`; WaitFrames (`$A22A`, `$A233`) waits for one more interrupt and clears it again. So `$A237` is
cleared twice in a pass. Stage 1's `work/stage1/pass_frames.py` read `$A237` at the end of every frame with
`time_travel memory_at` and took the run of frames from one 0 to the next as a pass:

| Recording | Window | Runs | Frames per run | Mean |
| --- | --- | --- | --- | --- |
| `level1` | frames 100-3 100 | 2 774 | 1: 2 720; 2: 5; 4: 21; 5: 9; 6: 9; 7: 9; 8: 1 | 1.08 |
| `level2` | frames 100-3 100 | 2 847 | 1, with a few of 4-7 | 1.04 |

These runs are the halves of a pass, not passes: stage 1's "1.08 frames a pass" was wrong. A pass in play takes 2
frames (one HALT, then WaitFrames for one more tick), 25 a second, measured from the hits of `$E410` and `$E3C9` in
`c1`: 983 passes of 2 frames, 63 of 3 (a lost interrupt), 5 of 9 (a zone change or a restart), 14 of
14-19 and 1 of 161: 1 066 in all
([doc 4, 4.1 and 4.4](docs/04-game-loop.md#41-the-shape)). The long runs are still the screen changes: they come in
threes as the view scrolls (`level1` frames 325, 329, 335 and 434, 438, 443; `$EAAE`, Rick's map position, steps from
`$8C` to `$8F` across the second three), and the longest is at `level1` frame 2 807, where `$EAAE` jumps from `$FC` to
`$8B` and a whole new view is drawn.

**The stack** is under `SP` = `$0000` (set at Start `$AB4E`); the deepest use the memory images show is `$FFE4`,
so it takes at least `$FFE4-$FFFF` (28 bytes)
([doc 2, 2.2](docs/02-architecture.md#22-the-memory-map)).

## 2. Static pass over the medium

`tools/tzxblocks.py` lists the TZX's blocks (a BASIC "Rick", Rick1 at `$CD00`, three groups of 48, 140 and 6 turbo
blocks); `tools/bleepload.py` decodes the block formats and both ciphers from the medium alone, and the result was
checked against `c1`'s memory at the entry ([doc 3, 3.4](docs/03-build-and-load.md#34-the-block-formats-byte-by-byte),
[3.10](docs/03-build-and-load.md#310-the-static-decode-against-the-recording)).

## 3. The stages and the packers

There is no packer: the turbo blocks are enciphered. Group 1 is XORed with a key built from a key page and the bytes of
Rick1 itself, groups 2 and 3 each byte with its destination page; the last block of the tape is a decoy
([doc 3, 3.5](docs/03-build-and-load.md#35-the-key-and-group-1s-cipher),
[3.6](docs/03-build-and-load.md#36-the-decoy-last-block),
[3.7](docs/03-build-and-load.md#37-loadgroup-and-the-page-cipher-of-groups-2-and-3)).

## 4. The medium from source

`tools/build.sh` assembles the BASIC, Rick1, the second stage, LoadGroup, the AY player and the game, enciphers the
blocks again and writes the whole TZX from `src/tape/tape.txt`; it is identical to the original
([doc 3, 3.13](docs/03-build-and-load.md#313-the-source-build); `work/stage2/NOTES.md`).

## 5. Tool gaps found and fixed in unreal-ng

None: the case needed no unreal-ng change. The kit gaps it found are rows of `TODO.md` "Kit gaps".

## 6. The game

### 6.0 The recordings

All are captured on the 128K with `re_session.py capture --model 128K --ranges 4000-FFFF --port-base 37490`, with
input scripts from `tests/inputs/`. `work/stage1/capture_all.sh` makes all but `c1`. Each keeps its `session.ttd`, its
`l1.json` and its screens in `work/stage1/<name>/`. The states they start from:
- `probe/after128.szx`: the menu after the ROM-speed 128K load of the original, keyboard selected, no POKE;
- `probe/menu-cursor.szx`: the same, with cursor keys selected.

**The level warp, a patch on a clone, said so in each recording it starts.** From `menu-cursor.szx`:
- copy the 11-byte record N of the level table `$E4AE` over record 0;
- set `$E3F4` = 0 (ZXDB's infinite-lives POKE 58356);
- ENTER;
- at the intro, set `$E4AD` = N.

The states are in `work/stage1/warp/`. No patched byte goes into the image.

The keys of `level1`-`level4` and part of `c1` come from someone else's run: the RZX archive's `rick1.rzx`, on a
re-release build, turned into input scripts by `tools/rzx_script.py`. That run is a witness only where said. It stays
in step with our original only for a while (bitmap diff of the screens against the RZX's own):
- level 1 from the menu: about 2 250 frames;
- level 2: from the RZX's frame 8 590 to about 11 850;
- level 3: from 25 378 to about 26 100;
- level 4: about 700 frames from 43 107.

| Recording | Starts from | Frames | Inputs | Reached |
| --- | --- | --- | --- | --- |
| `c1` | power-on, the TZX at ROM speed | 33 400 | `c1.txt`: the control menu 2, 4, 1, 3; the RZX's keys of its frames 0-2 400 from frame 400; P, P (pause); Q | the whole load, the entry (frame 19 010), the menu, every control choice, the intro music, level 1's zones 1 to 3 (L1Z3 and back to L1Z2; score 4 170 at the quit), pause, quit, GAME OVER, the menu |
| `controls` | `after128.szx`, no POKE | 2 500 | `controls.txt` | each control method in turn (keyboard, Sinclair, Kempston, cursor), each game quit with Q; the Kempston bug: Rick walks right on his own |
| `gameover` | `after128.szx`, no POKE | 3 000 | `gameover.txt`: ENTER, ENTER, X held | the boulder of the first screen kills Rick six times; GAME OVER and its tune; back to the menu |
| `level1` | `menu-cursor.szx`, no POKE | 6 000 | `level1.txt`: the RZX's frames 1-6 000 | level 1 zones 1 to 3 (L1Z3 and back to L1Z2), deaths, a natural GAME OVER and a new game |
| `level2` | `warp/level2c.szx`, the level warp | 6 000 | `level2.txt`: the RZX's frames 8 581-14 580 | Egypt's intro and first screens; when the RZX falls out of step, Rick stands at the start |
| `level3` | `warp/level3c.szx`, the level warp | 6 000 | `level3.txt`: the RZX's frames 25 371-31 370 | the castle's intro and its first two screens |
| `level4` | `warp/level4c.szx`, the level warp | 6 000 | `level4.txt`: the RZX's frames 43 101-49 100 | the missile base's intro and first screens |
| `ending` | `warp/ending.szx`, a warp | 1 500 | `ending.txt`: ENTER at 300 and 1 200 | the last level's end: the closing text, ClearPlayArea `$AF56` clearing the play area, `$E440` = `$FF`, GAME OVER, the menu |

`warp/ending.szx` is level 4 in play after the level warp, then a second patch at the main loop's HALT: `$E4AD` = 3,
the return address `$E406` pushed (SP = `$FFFE`), PC = `$ABD8`, the path the game takes when Rick leaves a level by
its last exit (`PUT /registers/SP`, `/registers/PC`).

**Stage 2's recordings** (`work/stage2/NOTES.md` "Recordings of stage 2"; all are `witness_builds`, counted in the
witness lines only, because a snapshot start puts an entry at its PC). Each keeps its `session.ttd` and `l1.json` in
its folder:

| Recording | Starts from | Frames | Command | Reached |
| --- | --- | --- | --- | --- |
| `stage2/c1g` | `c1` from the entry `$AB4D` (frame 19 010, T 70 483) | the rest of `c1` | `$RS build --from-frame 19010 --from-tinframe 70483 --into work/stage2/c1g` (a build of `c1`'s `session.ttd`, no capture) | the code build of `c1` (`witness_names` c1) |
| `stage2/zones/<zone>` x 34 | `work/stage2/warp/<zone>.szx`, the zone warp (`work/stage2/zonewarp.py`, a patch on a clone) | 2 000 each | `sh work/stage2/capture_zones.sh <zone> ...` (port base 37490), keys `tests/inputs/zone-<zone>.txt` | every zone of levels 1-4 with our own keys; effect 8 in `L1Z4`, the spring in `L2Z4` |
| `stage2/spots/<zone>-<kind>` x 6 | `work/stage2/warp/spot-*.szx`, the spot warp (`work/stage2/spotwarp.py`) | 400 each | `sh work/stage2/capture_spots.sh`, keys `tests/inputs/spot-*.txt` | kinds 34, 35, 43, 44, 47, 51, 69 spawned and run |
| `stage2/ending2` | `work/stage2/warp/ending.szx`, the ending warp (`work/stage2/endingwarp.py`: the door opened, said so) | 2 000 | `$RS capture --work work/stage2/ending2 --snapshot work/stage2/warp/ending.szx --model 128K --inputs tests/inputs/ending2.txt --frames 2000 --ranges 4000-FFFF --port-base 37495` | level 4's end exit, tune 4, the bonus, London, GAME OVER, the menu |
| `stage2/beeper48` | `work/stage1/probe/orig48.szx` (the original loaded on a 48K, the menu; no POKE) | 1 600 | as `ending2`, `--snapshot work/stage1/probe/orig48.szx --model 48K --inputs tests/inputs/beeper48.txt --frames 1600` | the 48K path: level 1 played, 98 beeper effects, all six branches |

**The integration recordings** (`sh work/docs/integrate/capture.sh`, port base 37420, each instance stopped after;
`witness_builds`). Each keeps `session.ttd` and `l1.json` in `work/docs/integrate/<name>/`; the input script's header
says the patch:

| Recording | Starts from | Frames | Inputs | Reached |
| --- | --- | --- | --- | --- |
| `docs/integrate/emptygun` | `work/stage2/warp/L1Z1.szx`, the zone warp (a patch on a clone) | 700 | `emptygun.txt`: fire + up, fire alone, release, eight times | six shots (FireShoot `$FA4B` from frame 20 to 420), then two with no bullets: effect 1 from `$FA45` / `$FA47` at frames 500 and 580; MaskHudCells takes its Bullets = 0 jump 139 of its 350 runs from the sixth shot on |
| `docs/integrate/l1z1left` | `work/stage2/warp/L1Z1.szx` | 400 | `l1z1left.txt`: left held from frame 10 to 300 | L1Z1's left exit (to `$FFFF`) is walled: Rick stops at x 4, ExitLeft `$FBCF` never runs |
| `docs/integrate/l1end` | `work/docs/integrate/warp/l1end.szx` (`python3 work/docs/integrate/warps.py`: the L1Z6 zone warp beside its right exit, then ZoneChange `$FD61` = `$FF` and ExitSide `$FD62` = 1, a patch on a clone) | 2 500 | `l1end.txt`: no keys | the end of level 1: LevelEnd `$ABD8` at frame 1, StartTune with tune 1 at frame 9 (T 33 543), Egypt's intro text |

The writers reopened these with `$RS open --work work/docs/rdA/<name> --ttd <recording>/session.ttd` (`c1`, `lv1` for
`level1`, `z11` for `stage2/zones/L1Z1`, `controls` under `work/docs/rdB/`); the animations below name those folders.

**Sound.** Execution counts from the L1 witness the music and the effects. The music entry `$A016` takes the tune
in A:
- 0, the intro (`$E324`): `c1`, `controls`, `gameover`, `level1`;
- 1-4, a level's end (`$AC20`): tune 1 in `docs/integrate/l1end`, tune 4 in `ending` and `stage2/ending2`; tunes 2 and 3 in no recording;
- 5, the menu (`$E220`): `c1`, `controls`, `gameover`, `ending`, `level1`;
- 6, GAME OVER (`$E386`): `c1`, `controls`, `gameover`, `ending`, `level1`;
- 7 (`$F531`): `c1`, `level1`.

The effects (`$9FED`, IDs 0-11) are called from 15 sites in `$EC93-$FD44`; IDs 5 and 7 have no call site
([doc 9](docs/09-sound.md)). Every site runs: ID 8 (`$ED76`) in `stage2/zones/L1Z4`, ID 1 from the empty gun
(`$FA47`) in `docs/integrate/emptygun`, the others in stage 1's recordings.
The counts are in `work/stage1/NOTES.md`.

**Not reached, and why:**
- the whole of levels 2-4 with the RZX's keys: they fall out of step with the original after 700-3 300 frames; every
  zone was then played with our own keys from the zone warp (`stage2/zones`), and the maps are drawn from the data
  ([doc 2, 2.5](docs/02-architecture.md#25-levels-zones-and-maps));
- the ends of levels 2 and 3 (tunes 2 and 3) and the first zones' `$FFFF` exits of levels 2-4: no recording;
  known only from the code (`work/review/open-from-writers.md`);
- Set48K `$A05F`: it runs before `beeper48`'s start state; known from the code and that state.

### 6.1 Screenshots

Taken from the recordings' screens (`screens/NNNNNN.scr`, named by the input script's frame; `c1`'s script starts at
recording frame 30 000) and, for the intros, from the warp recordings' start states.

| Screenshot | Recording, frame |
| --- | --- |
| [menu](docs/img/play/menu.png) | `c1` 30 250 |
| [intro-level1](docs/img/play/intro-level1.png) | `c1` 30 500 |
| [level1-start](docs/img/play/level1-start.png) | `c1` 31 000 |
| [level1-ladders](docs/img/play/level1-ladders.png) | `c1` 31 750 |
| [quit-game-over](docs/img/play/quit-game-over.png) | `c1` 33 250 |
| [menu-sinclair](docs/img/play/menu-sinclair.png) | `controls` 1 250 |
| [menu-kempston](docs/img/play/menu-kempston.png) | `controls` 1 750 |
| [kempston-walks-right](docs/img/play/kempston-walks-right.png) | `controls` 2 000 |
| [game-over](docs/img/play/game-over.png) | `gameover` 2 500 |
| [intro-level2](docs/img/play/intro-level2.png) | `level2` 0 (the warp state) |
| [level2](docs/img/play/level2.png) | `level2` 500 |
| [intro-level3](docs/img/play/intro-level3.png) | `level3` 0 (the warp state) |
| [level3](docs/img/play/level3.png) | `level3` 500 |
| [intro-level4](docs/img/play/intro-level4.png) | `level4` 0 (the warp state) |
| [level4](docs/img/play/level4.png) | `level4` 250 |
| [ending-text](docs/img/play/ending-text.png) | `ending` 250 |
| [ending-game-over](docs/img/play/ending-game-over.png) | `ending` 500 |
| [c1-30700](docs/img/text/c1-30700.png) (and its HUD row, [hud](docs/img/text/hud.png)) | `c1` 30 700 |
| [c1-31329](docs/img/text/c1-31329.png) | `c1` 31 329:30 000 |
| [c1-31330](docs/img/text/c1-31330.png) | `c1` 31 330 |

Not screenshots but drawn from the recordings or the build: [course-level1](docs/img/play/course-level1.png) (`level1`
frames 0-5 980), [jump-arc](docs/img/play/jump-arc.png) and [props](docs/img/play/props.png) (`build/game.bin`), all in
doc 10.

![The menu, c1 frame 30 250](docs/img/play/menu.png)

![Level 1 in play, c1 frame 31 000](docs/img/play/level1-start.png)

![The closing text, ending frame 250](docs/img/play/ending-text.png)

### 6.2 Animations

Every animation of the documents (23 GIFs), with the recording and frames it shows; the command is in each caption.
`rdA/c1` is `c1` reopened, `rdA/lv1` `level1`, `rdA/z11` `stage2/zones/L1Z1`, `rdB/controls` `controls`.

| File | Document | Recording | Frames |
| --- | --- | --- | --- |
| [load-memory.gif](docs/img/load/load-memory.gif) | [3](docs/03-build-and-load.md) | `c1` | 0-19 020, one picture every 200 frames |
| [DecipherGroup1.gif](docs/img/routines/DecipherGroup1.gif) | [3](docs/03-build-and-load.md) | `c1` | 5 558:56 000 - 5 567:27 000 |
| [LoadGroup.gif](docs/img/routines/LoadGroup.gif) | [3](docs/03-build-and-load.md) | `c1` | 5 571:32 000 - 5 750:0 |
| [MainLoop.gif](docs/img/routines/MainLoop.gif) | [4](docs/04-game-loop.md) | `c1` | 31 097:6 400 - 31 099:7 100 (one pass) |
| [ScrollViewDown.gif](docs/img/routines/ScrollViewDown.gif) | [4](docs/04-game-loop.md) | `c1` | 30 721:38 000 - 30 741:8 000 |
| [LoadScreen.gif](docs/img/routines/LoadScreen.gif) | [4](docs/04-game-loop.md), [6](docs/06-rendering.md) | `c1` | 31 171:6 600 - 31 181:7 000 |
| [ReadInput.gif](docs/img/routines/ReadInput.gif) | [5](docs/05-controls.md) | `controls` | 201:34 321 - 201:38 671 |
| [menu-keys.gif](docs/img/play/menu-keys.gif) | [5](docs/05-controls.md) | `controls` | 620-700 |
| [kempston-bug.gif](docs/img/play/kempston-bug.gif) | [5](docs/05-controls.md) | `controls` | 1 384-1 540 |
| [rick-keys.gif](docs/img/play/rick-keys.gif) | [1](docs/01-game-design.md) | `controls` | 150-320 |
| [BuildScreenMap.gif](docs/img/routines/BuildScreenMap.gif) | [6](docs/06-rendering.md) | `c1` | 31 172:41 000 - 31 173:27 000 |
| [ComposeObject.gif](docs/img/routines/ComposeObject.gif) | [6](docs/06-rendering.md) | `c1` | 30 708:1 800 - 30 708:24 000 |
| [RestartScreen.gif](docs/img/routines/RestartScreen.gif) | [7](docs/07-objects.md) | `stage2/zones/L1Z1` | 134:28 000 - 135:31 271 |
| [SpawnObjects.gif](docs/img/routines/SpawnObjects.gif) | [7](docs/07-objects.md) | `c1` | 31 173:27 000 - 31 173:42 000 |
| [TrapObj.gif](docs/img/routines/TrapObj.gif) | [7](docs/07-objects.md) | `c1` | 30 532-30 560 |
| [PrintText.gif](docs/img/routines/PrintText.gif) | [8](docs/08-hud-and-text.md) | `c1` | 30 469:70 000 - 30 471:56 000 |
| [UpdateHud.gif](docs/img/routines/UpdateHud.gif) | [8](docs/08-hud-and-text.md) | `c1` | 31 329:30 000 - 31 329:50 000 |
| [AyTick.gif](docs/img/routines/AyTick.gif) | [9](docs/09-sound.md) | none: the built player in the simulator (`tools/fig_sound.py anim 0`) | the first 150 interrupts of tune 0 |
| [jump.gif](docs/img/play/jump.gif) | [10](docs/10-gameplay-logic.md) | `c1` | 30 984-31 000 |
| [FireShoot.gif](docs/img/routines/FireShoot.gif) | [10](docs/10-gameplay-logic.md) | `c1` | 31 326-31 340 |
| [DynamiteObj.gif](docs/img/routines/DynamiteObj.gif) | [10](docs/10-gameplay-logic.md) | `stage2/zones/L1Z1` | 9-100 |
| [KillRickNow.gif](docs/img/routines/KillRickNow.gif) | [10](docs/10-gameplay-logic.md) | `c1` | 32 634-32 718 |
| [BonusCollect.gif](docs/img/routines/BonusCollect.gif) | [10](docs/10-gameplay-logic.md) | `level1` | 750-757 |

## 7. Review

The writers' open questions for the reviewers: [work/review/open-from-writers.md](work/review/open-from-writers.md).
