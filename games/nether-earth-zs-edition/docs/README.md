# Nether Earth ZS Edition: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the two releases ('98 `NEZSED98`, '99 `NEZSED`), the start-up of each (picture, scroller, music), the '99 start-up menu and its four levels (CRITICAL measured over a game: a figure), the '98 menu, the maps (a figure of all 12 `NELEV` maps), the owner's memory of a mouse pre-menu checked, play, time, the author's claims against the code (1.11) |
| [2. Architecture](02-architecture.md) | the machine, the memory at each stage (a figure, access regions and a play heat map, where the time goes for each release), the stages from the disk to play, frames and interrupt handlers, the main loop with its phase costs, the module map, the self-modifying code, third-party pieces |
| [3. Build and load](03-build-and-load.md) | the two disks (a figure), the '98 load, the '99 load from the disk to the menu (a timeline and the depacking animation), the backward-LZ packer and `tools/zspack.py` (a stream figure), the map files and LOAD MAP, the '98's LOAD NEW LEVEL, machines and ROMs (the 48 K reset, the hang from the Pentagon menu's TR-DOS item), the source build |
| [4. Game loop](04-game-loop.md) | the state machines of both releases, the menu copy on each entry (a figure), the menu loops, one game turn (a figure), the turn against the beam and the tear band (figures), the clock and the random generator |
| [5. Controls](05-controls.md) | the keys of the intros and menus, the '99 pointer (an animation) and where SPACE acts (a figure), REDEFINE, the text pages and LOAD MAP, no mouse (a live run with a Kempston mouse: a figure), the controls in play |
| [6. Rendering](06-rendering.md) | the '98 title wipe and intro (an animation, a writers map), the '99 picture decoder, roll-in, scroller and push-out (animations, a writers map), System checking, the menus, the text viewer (an animation), the play view: buffer, painter's walk, projection, clipping, copy and radar (a routine animation, a writers map), the side-by-side screens |
| [7. Objects](07-objects.md) | the world turn (an animation), the 16-byte robot records (a figure of all 48), a robot's step and its delays, the shot records and the damage formula (the first fight of a `NELEV_00` game), the map's cell bits, the built-in level's fenced boxes (both map ends), the building and capture-point records, the robots over a whole game |
| [8. HUD and text](08-hud-and-text.md) | the long texts and their readable copies with translations ([texts/](texts/README.md)), `PrintInline` and its codes and sizes, the four fonts (a figure), every string of both game blocks and the start-up menu, the status panel (a figure and an animation), the clock, the number printers, the radar (a figure with the capture bug's stray pixel), the title colour cycle, the end messages |
| [9. Sound](09-sound.md) | what sounds where (the '99 start-up menu is silent); the '98 intro's Pro Tracker 3 tune and the '99 intro's Sound Tracker tune (piano rolls), the players' cost per frame, `SoundEffect` and `Beep` with their pitches (spectrograms), the '98 menu's beeper tune; renders in [audio/](audio/README.md) |
| [10. Gameplay logic](10-gameplay-logic.md) | the turn and the clock, production in both releases, the four difficulty levels as code patches, the enemy's daily upgrade (a figure), captures and the capture-index bug (a figure and an animation), a whole war on `NELEV_00` (a figure), the blocked pad, the bugs checked in both releases |
| [11. Data reference](11-data-reference.md) | every data entry of every annotated part (generated: `python3 tools/zsB_refdocs.py`) |
| [12. Routine reference](12-routine-reference.md) | every routine of every annotated part with its L1 counts and animations (generated: `python3 tools/zsB_refdocs.py`) |
| [13. Differences from Nether Earth](13-differences-from-nether-earth.md) | both editions against Nether Earth (1987) and against each other: the game images byte by byte (a heat map, a per-module figure, the changed regions with both sides' names), the disk and the load, the memory, the menus, the difficulty levels as code patches, the enemy's resources, production and upgrade, the maps cell by cell (a figure), one bot in all three games (a figure, one new EASY run), NE's bugs kept and the new ones, sound, texts, rendering (font and sprites figure), the author's claims resolved |
| [audio/](audio/README.md) | the tunes and effects rendered by unreal-ng to MP3, never played aloud |

## Texts

The long texts of both releases as readable Markdown, the Russian original and a full English translation
([texts/README.md](texts/README.md)):

| Text | What |
| --- | --- |
| [NEabout.W](texts/NEabout.md) | about the edition (ZS, 29.01.1999) |
| [NEdescri.W](texts/NEdescri.md) | the description, the author's notes, a bug warning |
| [NEgreets.W](texts/NEgreets.md) | greetings |
| [NEadvice.W](texts/NEadvice.md) | "Advices of Expert" (Timofey Anisimov) |
| [NEZSEd99.W](texts/NEZSEd99.md) | the '99 readme |
| [the '98 scroller](texts/scroller98.md) | the '98 intro: greeting, story, the '98 changes |
| [the '99 scroller](texts/scroller99.md) | the '99 intro: keys, greeting, machines, story |

## Recordings

All are unreal-ng TTD recordings or audio captures, muted, on Pentagon 128 + TR-DOS 5.04T unless the row says
otherwise. Frames count from each recording's own start.

| Name | What |
| --- | --- |
| `r98`, `r99` | stage 1, from power-on (`work/stage1/`). `r98`: `RUN "NEZSEd"` to play, frames 103-5903, frame = script + 1603. `r99`: the disk's autostart through every menu page, LOAD MAP, HARD, PHASERS, START and play, frames 2-6462 |
| `r99-48` | stage 1, the '99 from "48 BASIC" with paging locked (`USR 15616`): "Memory 56Kb", then the reset at frames 5647-5664 (`work/stage1/r99-48`) |
| `x99p` | stage 1, the '99 started from the Pentagon menu's TR-DOS item: the hang in the intro (`work/stage1/x99p`, [3.6](03-build-and-load.md#36-machines-and-the-rom)) |
| `x98`, `x99` | the texts agent's tours of every screen (`work/stage2/texts/`). `x98`: LOAD NEW LEVEL, then START. `x99`: REDEFINE, LOAD MAP `NELEV_06`, START, ABORT |
| `s98`, `s99`, `e98s`, `e99s` | both releases on the Scorpion ZS-256 model (`work/stage2/scorpion/`) |
| `play`, `deep`, `key5menu` | the '98 game: play; 30 284 frames played by NE's bot (`tools/bot.py`), 9 game days; LOAD NEW LEVEL from `menu98.szx` (`work/stage2/game98/`) |
| `r-critical` | the '99 on CRITICAL: START on the built-in map at frame 2899, then 9 200 frames with the ship parked, three game days (`work/stage2/game99/r-critical`, script `inputs/critical.txt`) |
| `r99-play`, `crit-play`, `loadmap-menu` | the '99 game (`work/stage2/game99/`): HARD + PHASERS; the L1 build of `r-critical` from the start-up menu on (frames 2661-12102); LOAD MAP |
| `m99`, `r48-*` | the start-up menu over every item; the 48K paths (`work/stage2/menu99/`) |
| `work/docs/zsA/r98`, `r99`, `rc` | the documents' instances over `r98`, `r99` and `r-critical`, with their access traces (`traces/*.uatr`: `r99` frames 3740-3750, `r-critical` 8000-8026 and 8026-8326) |
| `mouse99` | the '99 live from power-on with a Kempston mouse fitted: the mouse moved and clicked in the menu, in LOAD MAP and in play (`work/docs/zsA/mouse99`, [5.6](05-controls.md#56-no-mouse)) |
| `menu-hard`, `menu-map0` | the '99 driven through the start-up menu by `tools/zsB_play99.py menu`: HARD; HARD with LOAD MAP `NELEV_00` (`work/zsB/`) |
| `work/zsB/deep` | the '99 on HARD on the built-in level, played by NE's bot as a library: 30 602 frames, 2 224 turns, 7.7 game days |
| `deep-map0` | the '99 on HARD with `NELEV_00`, the same bot: 24 416 frames, 2 094 turns, 76 shots, 17 robots destroyed (`work/zsB/deep-map0`) |
| `intro98`, `intro99`, `sfx99`, `pokes99` | the audio captures of `tools/zsB_render_audio.py` (`work/zsB/audio/`): the two intro tunes and the '98 menu tune, the menu beeps of the bot's game, the play effects with `SoundFx` written by hand ([audio/](audio/README.md)) |
| `work/diff/deep-easy-map0` | the '99 on EASY with `NELEV_00`, the same bot: 24 500 frames, made for doc 13 (`work/diff/menu-easy-map0` is its start-up menu run; [13.8](13-differences-from-nether-earth.md#138-one-bot-in-the-three-games)) |
| `ne-play` | Nether Earth's own recording, used only in the side-by-side figures of `img/compare` |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| '98, '99 | the two ZS releases: ZS Edition'98 on `NEZSED98.SCL` (one BASIC monoblock), ZS Edition'99 on `NEZSED.SCL` (packed blocks, texts, maps) ([1.1](01-game-design.md#11-two-releases)) |
| ZS | Sergey Zotov, the author of both releases |
| NE, ANE | Nether Earth (Argus Press Software, 1987), the game both releases edit, and Advanced Nether Earth (Eternity Industry, 1998). Named here only for the side-by-side figures and for the tools borrowed from their cases |
| frame | one 50 Hz screen frame of the Pentagon: 71 680 T, one interrupt, 20.48 ms. The recordings count frames from their own start |
| T, T-state | one Z80 clock cycle at 3.5 MHz |
| recording | a TTD recording of an unreal-ng run, kept in `work/` (git-ignored) |
| L1 | the per-recording analysis build (`l1.json`): every routine, call, loop and byte access with counts and T-states |
| access trace | a `.uatr` file of every instruction and bus access over a window of a recording |
| writers map | a figure that colours each screen byte by the routine that wrote it last in a window of a recording (the kit's `writers_map.py`) ([6.1](06-rendering.md#61-the-98-title-and-intro)) |
| game image | the game's code and data at `$6780-$D7D2`, the same place in both releases ([2.2](02-architecture.md#22-the-memory-map)) |
| page | a 16K bank of the 128K at `$C000` (`$7FFD`). The one-page route is the '99's path for a count of exactly one page ([3.6](03-build-and-load.md#36-machines-and-the-rom)) |
| stage 2 | the '99 intro at `$61A8-$7D86`: the picture, the scroller, the tune, then the read of stage 3 ([3.3](03-build-and-load.md#33-the-99-load)) |
| stage 3 | the '99 loader at `$61A8` after the intro: System checking, the game, the patches, the menu, the texts ([3.3](03-build-and-load.md#33-the-99-load)) |
| block | a '99 self-extracting packed block: 22 bytes of set-up, the depacker copied to `$5B00`, the backward LZ stream ([3.4](03-build-and-load.md#34-the-99-packer)) |
| backward LZ | the '99's packer: streams unpacked from the top down over their own packed copy; `tools/zspack.py` rebuilds them byte for byte ([3.4](03-build-and-load.md#34-the-99-packer)) |
| slack | the bytes of a file's last sector after its length; no program reads them |
| start-up menu | the '99 menu at `$D800` (LEVEL, UPGRADING, CONTROL and six actions), kept in page 1 and copied in by the stub `$6700` on each entry. It is silent ([4.2](04-game-loop.md#42-entering-the-start-up-menu-99)) |
| pointer | the '99 menu's 8 x 8 arrow, moved one pixel a pass with Q A O P; SPACE acts on the cell under its top-left corner ([5.3](05-controls.md#53-the-99-start-up-menu)) |
| no mouse | no block of either release reads a `$xxDF` port; the live run with a Kempston mouse fitted left the pointer and LOAD MAP unmoved ([5.6](05-controls.md#56-no-mouse)) |
| patches | the '99 block at `$DC00` copied over the game: the disk and 128 K pieces (`TextEntry` `$A56A`, `DiskRead` `$A598`, `ShowMenu128` `$C112`, `DiskLoadMap` `$C1FD`, ...) ([3.3](03-build-and-load.md#33-the-99-load)) |
| level patches | the bytes START writes into the game by the level, at the start-up menu's `SpawnResources` `$B87E`, `InsgRobotCount` `$D2C8`, `EnemyProduce` `$AE41` and `$A5E5-$A5E7` ([1.6](01-game-design.md#16-difficulty-and-upgrades-99), [10.3](10-gameplay-logic.md#103-the-difficulty-levels)) |
| upgrade | `UpgradeEnemyRobots` `$A5D6`: the enemy's parts rewritten at midnight on HARD and CRITICAL, and every midnight in the '98 ([10.4](10-gameplay-logic.md#104-the-enemys-upgrade)) |
| map, `NELEV_xx` | a map file of the '99 disk (type `N`, 512 bytes): four record lists in 499 bytes of level area (`$BDA9-$BF9B`) and a 13-byte tail that `DiskApplyLevel` `$C2EB` writes into the game's operands. LOAD MAP reads `NELEV_00`-`NELEV_11` ([3.5](03-build-and-load.md#35-the-maps-nelev_xxn-and-load-map)) |
| built-in level | the '99's level in the game block, used without LOAD MAP: two warbases in fenced boxes, no factories, ЗАГРУЗИСЬ ("load up") on the radar ([7.5](07-objects.md#75-the-map)) |
| game turn, turn | one call of `GameTurn` `$AD62`: 5 minutes of game time, at least 10 frames (`TurnPace` `$AE1D`) ([10.1](10-gameplay-logic.md#101-the-turn-and-the-clock)) |
| game day | 288 game turns; production is paid at its midnight by `DailyProduction` `$AE38` ([10.2](10-gameplay-logic.md#102-production-and-resources)) |
| HUMN, INSG | the two sides as the status panel names them: the player and the computer (the Insignians) ([8.5](08-hud-and-text.md#85-the-play-screen-and-the-status-panel)) |
| slot | one of the 48 robot records at `$DA00`: 0-23 the player's, 24-47 the enemy's ([7.2](07-objects.md#72-robots)) |
| anchor | the one cell of a 2 x 2 robot (or a building, a shot) that carries map bit 6; `FindRobot` / `FindBuilding` look records up by it ([7.5](07-objects.md#75-the-map)) |
| capture point | one of 28 five-byte records at `$FD70` (warbases 0-3, factories 4-27): a door cell, an owner byte and a turn count ([7.6](07-objects.md#76-buildings-and-capture-points)) |
| door | the cell of a capture point a robot must stand on for 144 turns to capture it; for our warbase also where a new robot appears |
| pad | building type 0, 4 rows above our warbase's door: landing the ship on it opens the construction menu ([10.7](10-gameplay-logic.md#107-the-blocked-pad)) |
| capture-index bug | `CaptureLoop` hands record k over as index k + 28 - N when the level has N < 28 points ([10.5](10-gameplay-logic.md#105-capture-and-the-capture-index-bug)) |
| phantom flag | the building record at `$D8FE` the capture-index bug creates on the built-in level, a pixel in the radar picture ([8.8](08-hud-and-text.md#88-the-radar)) |
| `ViewBuffer` | the 160 x 160 pixel play view at `$5B00-$677F`, redrawn every turn and copied to the screen at (1,1) ([6.6](06-rendering.md#66-the-play-screen)) |
| `PrintInline` string | a string inline after `CALL PrintInline` `$D42D`, with codes 0 end, 1 position, 2 attribute, 3 next row, 4 size ([8.2](08-hud-and-text.md#82-the-print-routine-printinline-d42d)) |
| `SoundFx` | `$FD53`: the play effect the interrupt sounds each frame: 1 the shot's sweep, `$FC` / `$FA` / `$C8` the noises ([9.5](09-sound.md#95-effects-in-play-soundeffect-d5c4)) |
| deep game | the recordings `work/zsB/deep` (built-in level) and `work/zsB/deep-map0` (`NELEV_00`): the '99 on HARD played by NE's bot through `tools/zsB_play99.py` |
