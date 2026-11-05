# Zynaps 2 in 1: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the way in (the intro's three pictures and its options, animated), the play screen (annotated), the game menu's pages, the controls in short, the ship, weapons and pods, scoring and lives, the 12 levels with a screenshot each and the level table (`r3`'s order 0 1 2 3 7 5 4 8 6 9 10 11), a level's end and a guardian (GIFs), difficulty (the weapon rating), the sound in short, what no recording reached |
| [2. Architecture](02-architecture.md) | the machine budget of the 128 K, the eight pages stage by stage (a figure), the 64 K in play, the memory heatmap of `r3`, the stages from the disk to play, where the CPU time goes (per routine, `r3`), the frame with the glue and the hooks, the call graph, the module map, the stack |
| [3. Build and load](03-build-and-load.md) | the disk, the REM loader and its paging test, Hrust 1 (both unpacks animated), the intro block, the game block with its set-up and glue, where the game image comes from, the load timeline from the 128 menu to the game menu, which machine gets which path, the runs on other models, the source build, `boot.B` |
| [4. Game loop](04-game-loop.md) | the state machine (a diagram), the main loop of jobs, the play interrupt's two-frame pass and its four phases with the engine's two steps, the counts of `c1` and `r3`, the nested pass, the pass against the beam, the pause and a round's end |
| [5. Controls](05-controls.md) | the keys (a figure), ReadControls, the start test that picks the device, the K-MOUSE Kempston mouse driver against the ship (a recording, and the unreal-ng button note), the title keys, the selections and the key definition, the intro's options, the pause, the initials, the pods |
| [6. Rendering](06-rendering.md) | the screens, the span chains (DrawPlayfield animated), the glyph cache in four shifts, the scroll and BuildColumn (animated), DrawPlayfield against the beam, the writers of one pass, sprites in paper colour (StripDraw animated), the stars and the silent row toggle, the intro's pictures (animated), the banner raster against the beam, the cost of drawing |
| [7. Objects](07-objects.md) | the 16 records and their fixed roles, the 44-byte record as a data sheet, kinds and handlers, RunObjects (a routine animation), the path bytecode, the collision grid, the wave launcher and the sprite cache, an enemy's life: explosion and pod, the big enemy's sprite, the bytes that stay unexplained |
| [8. HUD and text](08-hud-and-text.md) | the panel part by part and its writers (code against screen), PanelFrame's attribute work, the gauges, the pod icon, the spinners, score and lives, the print codes, the two fonts, the 28 messages and their pages; links to [texts/](texts/) |
| [9. Sound](09-sound.md) | two players: the STarKos intro tune `SK10` (9.92 semitones high on a 128K) and the CPC Zynaps's engine in page 4 (2.08 semitones low), the hook stubs and which event starts which effect, the engine's data, the pitch against the CPC proved from its rip and register dump, every effect rendered, when the engine steps (the port timeline: twice a pass), what stays open |
| [10. Gameplay logic](10-gameplay-logic.md) | the player record, pods and the selector, the five weapons recorded (`w1`), the homing missile's lock and kill, the fuel, score and extra lives, the level scripts and the twelve levels, the weapon rating and enemy fire, lockable and big enemies, the level end, death and INF.LIVES (`d1`), what no recording reached |
| [11. Data reference](11-data-reference.md) | every data entry of the game (generated: `python3 ../../kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its runs and figures (generated, as 11) |
| [13. Differences from Zynaps (48K)](13-differences-from-zynaps-48k.md) | the game image against the 48K's byte by byte (99.61 % the same, 11 places, the set-up's 241 bytes at load), the load (tape against disk), the 2 in 1's own code, memory and pages, the Pentagon retiming and the game's speed on three machines, the sound (beeper against AY, the CPU it costs), the controls, INF.LIVES against `$FFD7`, the bugs kept and added, the screens side by side |
| [Texts](texts/) | every text on screen as UTF-8 Markdown with a translation: [boot](texts/boot.md), [intro](texts/intro.md), [game](texts/game.md); [the differences from the 48K](texts/differences.md) with the side-by-side screenshots of `img/compare/` |

## Recordings

All run on unreal-ng's Pentagon 128 with the TRD unless the row says otherwise, and are kept in `work/` (git-ignored;
the instances muted). Frame numbers in the documents are frames of the named recording, counted from its own start.
The long runs start from the game menu's snapshot `work/stage2/stubs/title-inf-ffd7.szx`: INF.LIVES on and the
developer switch `$FFD7` poked to 1 (no ship lost), or `title-inf.szx` with `$FFD7` = 0.

| Name | Made by | Frames | What it holds | Used in |
| --- | --- | ---: | --- | --- |
| `c1` | stage 1: `re_session.py capture --record-load` from power-on (`work/stage1/c1`), reopened read-only as `work/z128A/c1` | 13 702 | the 128 menu, `boot.B`, the load (RUN at 1772, the game's `JP $8000` at 3313), the intro and its options, the game menu, random play from 3902: six short games; access traces of the pass (12200-12210) and the raster (3950) | 01-06, 08, 09, 13 |
| `r1`, `r2` | stage 2: `tools/play_live.py` and the Kempston bot from `title-inf-ffd7.szx` (`work/stage2/stubs/r1`); `r2` from `r1`'s frame 4400 with homing missiles | 7701, 1001 | the five hook stubs `c1` never reached; every AY write of `r1` 0-1200 (`work/z128B/ports-r1.json`) | 09 |
| `r3` | z128A: `re_session.py capture --snapshot title-inf-ffd7.szx --inputs work/z128A/inputs/r3.txt --ranges 5B00-FFFF` | 76 001 (L1: 76 003) | a whole game: all 12 levels and the wrap to level 0, guardians, extra lives; L1 (the budget, the heatmap, the counts), a snapshot every 250 frames | 01, 02, 04, 06, 10, 13 |
| `r3o` | z128A: `r3` reopened (`work/z128A/r3o`; z128B's `work/z128B/r3open`) | | the nested pass, the counts, the extra lives, no beeper write in frames 500-76 000 | 04, 09, 10 |
| `o3` | z128A: `re_session.py capture --disk --record-load --inputs work/z128A/inputs/o3.txt` from power-on | 2301 + the load | the intro's options toggled (INF.LIVES, K-MOUSE) | 01, 05 |
| `m1` | z128A: `tools/rec_mouse.py` (K-MOUSE on, mouse moves and buttons scripted) | 792 from the menu | one life played with the Kempston mouse | 05 |
| `w0` | z128B: `tools/weapons_bot.py --plan 0,1,2,2,4,3` from `title-inf-ffd7.szx` | 9000 | the speed pod three times, an extra life | 10 |
| `w1` | z128B: the same bot with `--lock --park 17,10` | 9700 | every weapon taken in play (laser 1010, plasma 1422, double 1742, seeker 2529, homing 2985), a lock (4529), missiles (4531, 4691), the kill (4741), an extra life (8597), the level 0 end (6905); every AY write (`ports-w1.json`); per-frame memory (`w1-frames.npz`) | 07, 08, 09, 10 |
| `d1` | z128B: the same bot with `--plan 1` from `title-inf.szx` (`$FFD7` = 0) | 3700 | three ships lost (1713, 2522, 3311) with INF.LIVES: the lives stay at 2 | 09, 10, 13 |
| `k128` | stage 2: `re_session.py capture` from power-on, inputs `work/stage2/compare/inputs/k128.txt` | | the keyboard definition, the defaults typed | 04, 05, 13 |
| `r48` | stage 2: the 48K tape `work/ref48/ZYNAPS.TAP` on unreal-ng's 48K model, from power-on, inputs `r48.txt` (`work/stage2/compare/r48`) | | the 48K original's screens at the same moments as `c1`'s, for `img/compare/` | texts, 13 |
| model runs | stage 1: the TRD on each model (`work/stage1/models`) | | which models load and play (3.9) | 03 |
| renders | `tools/sound_render.py` (both players simulated from their bytes), `work/stage1/audio` | | the intro tune, the game's music and every effect as WAV; never played aloud | 09 |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| frame, TV frame | one screen frame of the machine: 71 680 T on the Pentagon (48.83 Hz), one interrupt pulse. The recordings count frames from their own start |
| T, T-state | one Z80 clock cycle at 3.5 MHz |
| pass | one run of the game's work, started by one play interrupt (PlayInterrupt `$A9ED`): the engine step, the stars, the panel, the playfield, the play logic, one chain step, the engine step again. It takes two TV frames, because the next frame's interrupt is lost under DI: 24.41 passes a second on the Pentagon ([4.3](04-game-loop.md#43-the-play-interrupt-one-pass-four-phases)). In the beeper tune's player a "pass" of the tone loop is 81 T, a different thing |
| phase | PassPhase `$7F65`, 1-4: which part of the four-pass cycle a pass is. Phase 1 scrolls a column, phases 2-4 test the hit grid |
| chain step | the `CALL BuildColumn; DI; RET` a pass ends with (or ChainEnd in phase 4): BuildColumn runs with interrupts on, between the passes |
| nested pass | a pass whose interrupt arrived inside the previous pass's chain step (PassDepth `$7F64` = 2) ([4.5](04-game-loop.md#45-the-nested-pass)) |
| job | a main-loop task posted as a bit of EventRequests `$81C5` and run by EventDispatch `$AC07`: sprite build, pod icon, score, effect |
| handler | the routine the IM 2 jump `$FDFD` names: TitleInterrupt `$A9E4`, MenuRasterInterrupt `$A512` or PlayInterrupt `$A9ED` |
| banner raster | MenuRasterInterrupt's per-line attribute colours of the banners and the menu pages, timed to the beam ([6.10](06-rendering.md#610-the-banner-raster-one-colour-per-scan-line)) |
| span node | an 8-byte node of NodePool `$F800`: handler, first glyph, gap, next; a playfield row is a chain of them ([6.2](06-rendering.md#62-the-playfield-span-chains)) |
| glyph cache, shift page | `$C000`-`$DFFF`: the scenery glyphs in four copies shifted 0, 2, 4, 6 pixels; ShiftPage `$7F6A` names the one in use (`$C0`, `$C8`, `$D8`, `$D0`) ([6.3](06-rendering.md#63-the-glyph-cache-four-shifts)) |
| map ring | `$B700`-`$BFFF`: the map columns the scenery coroutine writes and the rows read |
| scroll start | the level record's ScrollCount start (`$10`-`$40`): the map columns ReplayScroll builds at a level's start, not a speed |
| strip, paper colour | one character row of an object's sprite, drawn by StripDraw `$8603` after the scenery. Sprites are negative (a clear bit is a pixel) and show in the cell's paper colour |
| slot, object record | one of the 16 records of 44 bytes at `$F36C` + 44 n, each with a fixed role ([7.1](07-objects.md#71-sixteen-records-fixed-roles)) |
| kind | the record's `+7`, the index into KindHandlers `$80FA` ([7.3](07-objects.md#73-kinds-and-handlers)) |
| wave, level script, count | a group of enemies LaunchWave starts from one script step; the level script is the byte program WaveScriptStep runs, waiting in counts (one count = once in four passes) ([10.6](10-gameplay-logic.md#106-waves-and-the-level-scripts)) |
| path | an enemy's movement bytecode, run by RunPath one command a pass ([7.5](07-objects.md#75-the-path-bytecode)) |
| hit grid | the bitmap `$FC00`-`$FD8F` of the enemies' boxes, marked and tested by the friendly records ([7.6](07-objects.md#76-the-collision-grid)) |
| pod, selector | the weapon pick-up a destroyed wave leaves; touched, the selector (the player record's `+7`, the lit panel icon) steps on; touched with fire held 8 passes, the selected action runs ([5.9](05-controls.md#59-the-weapon-pods-touch-to-select-hold-fire-to-take)) |
| side weapon | the player record's `+8`: 0 none, 2 plasma, 3 homing missiles, 4 seeker |
| level counter, LevelOrder | the player record's `+6`, 0-11; LevelOrder `$8003` maps it to a level, levels 3-8 shuffled for every game |
| fuel, FuelOut | Fuel `$80E6`, one step down on one pass in 8; at 0 FuelOut takes a laser level and a speed step and refills to `$5A` |
| weapon rating | `$80E7`-`$80E9`, from the ship's arms: `$80E8` the enemies' fire chance, `$80E9` the waves' colour set ([10.6](10-gameplay-logic.md#the-weapon-rating-and-the-enemy-fire)) |
| lock | the homing sight's capture of a guardian: `$80E0` the record, `$80E2` its bit |
| big enemy, guardian | a kind 12 object, built by BuildBigSprite `$8F0C`; the scroll waits for it |
| split bold | PrintChar's form of a ROM character: line 1 blank, the left nibble emboldened |
| message | one of the 28 `$FF`-ended strings from `$82EE` |
| set-up | block 2's code at `$6000`: moves the game to `$6800`-`$FFFF`, installs the glue and the stubs on a 128K, applies the options ([3.5](03-build-and-load.md#35-block-2-the-game-and-its-glue)) |
| glue | the 128K code at `$5B00`-`$5BE2` the set-up installs: FramePlay, the music switches, the entries patched into the three interrupt handlers |
| FramePlay | `$5B00`: page 4 in, one engine step (`CALL $C96E`), page 0 back |
| engine, engine step | the CPC Zynaps's sound driver in page 4 (`$C968`-`$CD22`, data `$DE48`-`$FE6F`); one step sends the 14 AY registers and advances the channels. Twice a pass in play (one a TV frame on average), once an interrupt at the menus ([9.8](09-sound.md#98-when-the-engine-steps-the-port-timeline)) |
| hook stub | one of the 15 routines at `$B32F`-`$B39C` a patched call site enters: the site's own instruction, then an engine entry through HookSound `$B30D` ([9.2](09-sound.md#92-which-event-starts-which-effect)) |
| explosion noise | the 48K's three speaker toggles in the pass (per row, strip, slot), opened for 16 passes by an explosion or a guardian's hit. Here the three `OUT`s are `NOP NOP`; the AY's sound `$1D` replaces it |
| STarKos, `SK10` | the CPC tracker's player at `$8000` and the intro's song ([9.3](09-sound.md#93-the-starkos-player)) |
| INF.LIVES | the intro's option 1 (`$5D40`): TakeLife's `DEC (IX+4)` becomes `OR (IX+4)`; ships are lost, lives are not ([10.9](10-gameplay-logic.md#109-death-and-inflives)) |
| K-MOUSE | the intro's option 2 (`$5D41`): the Kempston mouse driver at `$FE00` in place of the Kempston stick ([5.4](05-controls.md#54-k-mouse-the-kempston-mouse-driver)) |
| `$FFD7` | Invulnerable, the 48K's developer switch: not 0 = no ship lost. 0 in the game; the bot recordings poke it |
| Hrust 1 | the packer of both blocks ([3.3](03-build-and-load.md#33-the-packer-hrust-1)) |
| load timeline | the sectors of `ZYNAPS.B` in memory per frame of `c1` ([3.7](03-build-and-load.md#37-the-stages-in-c1)) |
| 48K | the 48K Zynaps (Hewson 1987), the case [`../zynaps`](../../zynaps/README.md); doc 13 compares the two |
| L1 | the per-recording analysis build (`l1.json`): every routine, call, loop and byte access with counts and T-states |
| TTD | time-travel debugging: seeking a recording to any frame and reading its memory (`memory_at`), its port writes (`port_events`) and the last write or run of an address (`find_last`) |
| access trace | a `.uatr` file of every instruction and memory access over a window of a recording, read by `kit/routine_anim.py`, `kit/beam_timeline.py` and the case's `fig_*.py` |
