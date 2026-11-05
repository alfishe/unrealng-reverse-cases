# Zynaps: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the play screen (annotated), the title pages, controls in short, the ship, weapons and pods, scoring and lives, the 12 levels with a screenshot each (`r1`'s order 0 1 2 7 6 5 4 8 3 9 10 11), a level end and a guardian (GIFs), difficulty (the weapon rating), what no recording reached |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map at three stages (a figure), the stages from the tape to play, the play pass and the main loop, the state, the objects, where the CPU time goes (per routine, `r1`), the memory heatmap of `r1`, the call graph of a pass |
| [3. Build and load](03-build-and-load.md) | the TZX block by block (tape timeline), the BASIC, the Countdown II loader (the XOR chain and the countdown animated), the `picy` loading screen (the unpack animated), the stages and the load film, the start-up at `$B6FF`, the 1993 TAP, the checks against `c1`, the source build |
| [4. Game loop](04-game-loop.md) | the state machine (a diagram), the main loop of jobs, the play interrupt's four phases and drawing chain, a pass on the frame timeline (one INT, the next lost under DI), the pass counts of `r1`, the nested pass and the 28 interrupt returns L1 took for entries, the pass against the beam, pause and the end of a round |
| [5. Controls](05-controls.md) | the keys (a figure), ReadControls (keys, Kempston, cursor, Sinclair), the title keys, the selections and the key definition (a recording), pause, the high-score initials, the pods: select or take (an experiment, six runs) |
| [6. Rendering](06-rendering.md) | the screen areas, span chains drawn by a RET chain (DrawPlayfield animated), the glyph cache in four shifts, the scroll and BuildColumn (animated), DrawPlayfield against the beam, sprites in paper colour (StripDraw animated), the stars and the row toggle, the cost of drawing |
| [7. Objects](07-objects.md) | the 16 object records and their fixed roles, the 44-byte record as a data sheet, kinds and handlers, RunObjects (a routine animation), the path bytecode, the collision grid (code against screen), the wave launcher and the sprite cache, explosion and pod, the big enemy's sprite |
| [8. HUD and text](08-hud-and-text.md) | the panel part by part (code against screen), PanelFrame's attribute work, the gauges, the pod icon, the spinners, score and lives, the print codes, the split-bold ROM font and the 54 glyphs, the 28 messages and their pages |
| [9. Sound](09-sound.md) | the two-voice title tune (format, player, the pitch formula corrected by a capture), the six effects (table, priority, scheduling, model against capture), who drives the speaker in a frame, the explosion noise channels; the tune and the effects as MP3 files (`docs/audio/`) |
| [10. Gameplay logic](10-gameplay-logic.md) | the player record, pods and the selector, the five weapons recorded (`w1`, `w2`), the fuel, score and extra lives, the level scripts and waves, the weapon rating and enemy fire, lockable and big enemies, the twelve levels of `r1`, level end, the loop after the last level, death |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `python3 tools/refdocs_zy.py`, the kit's refdocs with `w1` and `w2` added) |
| [12. Routine reference](12-routine-reference.md) | every routine with its runs and figures (generated, as 11) |

## Recordings

All run on unreal-ng's 48K model and are kept in `work/` (git-ignored). Frame numbers in the documents are frames
of the named recording, counted from its own start. `play-imm.szx` (`work/run/`) is play on level 0 with
`Invulnerable` `$FFD7` set to 1 (WALKTHROUGH 5); the long runs start from it.

| Name | Made by | Frames | What it holds | Used in |
| --- | --- | ---: | --- | --- |
| `c1` | `re_session.py capture --record-load`: power-on, the TZX (the BASIC and the loader fast, the Hewson blocks at signal speed), then 4000 frames | the load + 4000 | the load and its stages, the game's start at 12323, the title pages with no input (credits at 12600, high scores at 14730) | 02, 03, 04, 08 |
| `c2` | `tools/bot.py` from the menu's `play-start.szx`, level 0 played honestly | 1500 | one death; the access traces of a pass (frames 300-310) | 04, 06, 08, 10 |
| `r1` | `re_session.py capture --snapshot work/run/play-imm.szx --inputs work/run/all75k.txt --ranges 5B00-FFFF`: the bot's run replayed | 75 001 captured, L1 counts 75 003 | all 12 levels, 11 level ends, 6 big enemies, 5 extra lives, no death; L1, TTD, a snapshot every 250 frames | 01, 02, 04, 06, 07, 10 |
| `run` | `tools/bot.py` (Kempston, reads the ship's record and the screen) live from `play-imm.szx`: `work/run/all.txt` (inputs), `all.tsv` (log), `shots/`; no TTD | 100 000 | the wrap from level 11 back to level 0 at frame 73 600 (100 300 points) | 01, 10 |
| `w1` | zyB: `tools/podbot.py --plan 0,1,2,2,3,4 --record work/zyB/w1` from `play-imm.szx` | 5986 | every pod action taken (speed, laser, plasma, double plasma, homing, seeker), 23 pods, a selector wrap, two FuelOuts (3996, 5436) | 07, 08, 10 |
| `w2` | zyB: `tools/podbot.py --plan 3 --record work/zyB/w2`, same snapshot | 7600 | homing missiles from 547, a lock (3859) and a launch (3861), the level 0 end (6192), level 1, an extra life (7264); traces 701-706 and 6355-6460 | 07, 08, 09, 10 |
| `menu` | zyA: `re_session.py capture --work work/zyA/menu --snapshot work/zyA/exp/c1-12600.szx --inputs work/zyA/exp/menu.txt` | 1420 | the title keys, the selections, key 3's key definition, Kempston fire to play at 1180 | 04, 05 |
| `pods` | zyA: `tools/exp_pods.py --state work/zyA/exp/r1-200.szx` (an experiment on its own instance, no TTD) | 6 runs | one pod born at `r1` frame 225: `select` (no fire) and `take-0` to `take-4` (fire held), FireHeld and the record logged every frame | 05 |
| `rig` | zyB: `tools/render_audio.py --work work/zyB/rig` (unreal-ng's beeper capture to WAV) | 3000; 50 per effect | the title tune left alone from `work/explore/title.szx`; the six effects requested by hand from `play-imm.szx` | 09 |
| stage 2 experiments | `work/f4/pause.py`, `work/f4/invuln.py`, `work/f4/vmwalk.py` | | the pause, the checkpoints and `Invulnerable`, a walk of all 12 level scripts | 04, 05, 10 |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| frame, TV frame | one 50 Hz screen frame of the 48K: 69 888 T, one interrupt pulse. The recordings count frames from their own start |
| T, T-state | one Z80 clock cycle at 3.5 MHz |
| pass | one run of the game's work, started by one play interrupt (PlayInterrupt `$A9ED`): the stars, the panel, the playfield, the play logic and one chain step. It takes two frames, because the next frame's interrupt is lost under DI: play runs at 25 passes a second ([4.3](04-game-loop.md#43-the-play-interrupt-one-pass-four-phases)). The main loop in play only runs jobs. Some comments of `src/game` say "frame" (or "game frame") for a pass. In the tune player (9.2) a "pass" of the tone loop is 81 T, a different thing |
| phase | PassPhase `$7F65`, 1-4: which part of the four-pass cycle a pass is. Phase 1 scrolls a column, phases 2-4 test the hit grid; ChainEnd sets 0 |
| chain step | the `CALL BuildColumn; DI; RET` a pass ends with (ChainBuildColumn1-3), or ChainEnd in phase 4 |
| nested pass | a pass whose interrupt arrived inside the previous pass's chain step (PassDepth `$7F64` = 2); it NOPs the step's `DI; RET` so the steps run back to back ([4.5](04-game-loop.md#45-the-nested-pass)). Six in `r1` |
| job | a main-loop task posted as a bit of EventRequests `$81C5` and run by EventDispatch `$AC07`: sprite build, pod icon, score, effect |
| handler | the routine the IM 2 jump InterruptJump `$FDFD` names: TitleInterrupt `$A9E4`, MenuRasterInterrupt `$A512` or PlayInterrupt `$A9ED` ([4.1](04-game-loop.md#41-the-state-machine)) |
| span node | an 8-byte node of NodePool `$F800`: handler, first glyph, gap, next; a playfield row is a chain of them ([6.2](06-rendering.md#62-the-playfield-span-chains)) |
| row record | 32 bytes at RowRecords `$F12C` + 32 x row: map pointer, attribute and screen addresses, head node, strips, star |
| glyph cache | `$C000-$DFFF`: 256 scenery glyphs in four copies shifted 0, 2, 4, 6 pixels; line k of glyph n at page + 256 k + n ([6.3](06-rendering.md#63-the-glyph-cache-four-shifts)) |
| shift page | ShiftPage `$7F6A`, the high byte of the glyph cache page for the current fine scroll: `$C0`, `$C8`, `$D8`, `$D0` |
| map ring | `$B700-$BFFF`: the map columns (tile codes and attributes) the scenery coroutine writes and the rows read |
| scroll start | the level record's ScrollCount start (`$10`-`$40`): the map columns ReplayScroll `$AF6B` builds at the level start, not a speed ([6.4](06-rendering.md#64-the-scroll-a-new-column-every-four-passes)) |
| strip | one character row of an object's sprite, linked to the row record and drawn by StripDraw `$8603` after the scenery ([6.6](06-rendering.md#66-the-sprites-strips-in-paper-colour)) |
| paper colour | how sprites show: the images are negative in play (a clear bit is a pixel) and the object's colour is set as the cell's paper |
| object record | one of the 16 records of 44 bytes at `$F36C-$F62B`; the slot number is its index ([7.1](07-objects.md#71-sixteen-records-fixed-roles)) |
| kind | the record's `+7`: the index into KindHandlers `$80FA`, 0-12 ([7.3](07-objects.md#73-kinds-and-handlers)) |
| enemy kind | an entry of the kinds table `$6A65` (8 bytes), copied into the wave template; its byte 5 is the handler kind |
| wave | a group of enemies LaunchWave `$91EC` starts from one script step; a wave record at `$8075` counts it down |
| level script | the byte program a level runs (WaveScriptStep `$AD66`, in phase 2): waits in counts, and commands ([10.6](10-gameplay-logic.md#106-waves-and-the-level-scripts)) |
| count | one run of WaveScriptStep, counted by ScriptWaitCount `$81E1`: once in four passes, 8 frames |
| path | an enemy's movement bytecode, run by RunPath `$94CB` one command a pass ([7.5](07-objects.md#75-the-path-bytecode)) |
| hit grid | the bitmap `$FC00-$FD8F` of the enemy records' boxes, marked in phases 1 and 3, tested and cleared in phases 2-4 ([7.6](07-objects.md#76-the-collision-grid)) |
| pod | the weapon pick-up (kind 4) the last explosion of a wave destroyed whole leaves. Touched: the selector steps on; touched with fire held 8 passes: the selected action runs ([5.6](05-controls.md#56-the-weapon-pods-touch-to-select-hold-fire-to-take)) |
| selector | the player record's `+7`, 0-4: the lit icon of the five on the panel, the action a pod taken with fire held runs |
| side weapon | the player record's `+8`: 0 none, 2 plasma, 3 homing missiles, 4 seeker |
| level counter | the player record's `+6`, 0-11; LevelOrder `$8003` maps it to a level. Levels are numbered 0-11, as in the level table |
| fuel | Fuel `$80E6`, one step down every 8 passes (16 frames); at 0 FuelOut `$9C03` takes a laser level and a speed step |
| weapon rating | `$80E7-$80E9`, from the laser, the side weapon and the speed: when and how often enemies fire, and the waves' colour set ([10.6](10-gameplay-logic.md#the-weapon-rating-and-the-enemy-fire)) |
| lock | the homing sight's capture of a lockable enemy: `$80E0` the record, `$80E2` its bit |
| big enemy, guardian | a kind 12 object, 72 x 56 pixels, 48 hit points, built by BuildBigSprite `$8F0C`; 01 calls it a guardian |
| effect | one of the six beeper sounds of EffectTable `$7E5A`, played by EffectPlay `$B30C` in the main loop; its number is its priority |
| tick | one step of an effect: one pass, 2 frames |
| explosion noise | the three speaker toggles (per row, per object strip, per slot) whose masks SoundPattern1-3 open for 16 passes after an explosion or a big enemy's hit; silent otherwise. Not an engine hum ([9.5](09-sound.md#the-explosion-noise)) |
| split bold | PrintChar's form of a ROM character: line 1 blank, the left nibble emboldened |
| message | one of the 28 `$FF`-ended strings from `$82EE`; `$1B` n prints message n inside another |
| Countdown II | the Hewson loader at `$FC00`: an XOR-chain encrypted copy of LD-BYTES with a four-digit counter of 32-byte units still to load |
| picy | the packed loading screen block at `$8000`: literal, mask and flag streams, unpacked in screen order |
| signal speed | a block read at the speed the tape plays, as opposed to the emulator's fast-load trap of the ROM's LD-BYTES |
| L1 | the per-recording analysis build (`l1.json`): every routine, call, loop and byte access with counts and T-states |
| TTD | time-travel debugging: seeking a recording to any frame and reading its memory (`memory_at`) |
| access trace | a `.uatr` file of every instruction and memory access over a window of a recording, read by `kit/routine_anim.py`, `kit/beam_timeline.py` and the case's `fig_*.py` |
