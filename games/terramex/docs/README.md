# Terramex: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the game as a player meets it: the story, every screen, the five explorers, the controls, the panel, lives, the 30-day countdown, the score, the items and the six wishes, the 72 rooms, the RZX run's walkthrough, the two endings |
| [2. Architecture](02-architecture.md) | the machine budget (RAM 1 the selector, RAM 6 the music), the memory map, the module map, the stages from power-on to play, the frame budget, the call graph, the heatmap and the stack, the leftovers, 48K against 128K, the SkoolKit comparison |
| [3. Build and load](03-build-and-load.md) | the five tape blocks, the BASIC loader hidden in `l$`, the 128K set-up and the selector's relocation (an animation), the 48K path, the load in `c1` (an animation), the copies, the build |
| [4. Game loop](04-game-loop.md) | the program's states (diagrams), one pass of the main loop step by step with its cost, frames per pass and the beam, the hero's statuses, the death and the respawn, the countdown and the space scene, the interrupt, the timers |
| [5. Controls](05-controls.md) | the three devices and every port read, the device menu, ReadDevice and the readers, opposite directions, the cursor readers no path reaches, the selector's input (Kempston probe, cursor, boxes, Help), the input to the hero (walk, jump, climb, hover), T, S, 1 and 2, the abort and the freeze |
| [6. Rendering](06-rendering.md) | the play window and its back buffer, the two tile sets, the room build from back-tiles and DrawRoom, the flames, beams, capsules and the well, the sprite space and its outline mask and mirror, RenderPass step by step with its cost, the floor items, the panel's column blits, the selector's hand cursor, code against the screen and the beam |
| [7. Objects](07-objects.md) | the five object slots and the game variables; the room as ten tables (room `$31` decoded); the creature record and its 10-byte working copy; the eight creature types as state machines; Near and HitExplorer; Random; ItemPlaces and the item slots; the pickup, HeldItem and the 27 bearers; the crystal; the 21 room scripts; the course of the RZX run |
| [8. HUD and text](08-hud-and-text.md) | the ROM font and PrintChar, PrintString and the device menu, PrintPage and Help, every text, the panel and its column blitter, the portrait and the lives, the bearer row, the score (four cells, ':' past 9999, no sign), the high score, the telescope's countdown |
| [9. Sound](09-sound.md) | Ben Daglish's AY player in RAM 6 (order lists, patterns, instruments, WriteAY), tune 0 and its 9698-frame loop, tunes 1-3 never played, the model checked against c1, the seven beeper sounds measured on the machine, the audio files |
| [10. Gameplay logic](10-gameplay-logic.md) | the world and its exits; the 34 statuses; walk, climb, jump, fall, refusal and umbrella; the rides (bounce, hover, lift, balloon, barrels, basket, float, teleport); deaths, lives and the restart; creatures and hazards; items and puzzles, the explorer rooms; the professor, the telescope and the ending; the countdown; the score; notable features; what no recording reached |
| [11. Data reference](11-data-reference.md) | every data entry of the game image `$7200-$FFFF`, then of the BASIC loader, the selector, the music player, the explorer sets and the loading screen (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine of the game image, the BASIC loader, the selector and the music player, with its callers, runs and figures (generated) |

## By subject

| Subject | Where |
| --- | --- |
| the story, the goal, every screen | [1.1](01-game-design.md#11-the-game-in-one-page), [1.2](01-game-design.md#12-the-screens) |
| the five explorers, their own rooms | [1.3](01-game-design.md#13-the-five-explorers), [10.9](10-gameplay-logic.md#109-items-and-puzzles) |
| the items and the six wishes | [1.7](01-game-design.md#17-the-items-and-the-professors-six-wishes), [7.8](07-objects.md#78-the-items-itemplaces-the-item-slots-and-the-sprites), [7.9](07-objects.md#79-picking-up-helditem-and-the-27-bearers) |
| the map, every room | [1.8](01-game-design.md#18-the-map), [10.1](10-gameplay-logic.md#101-the-world-and-its-exits) |
| the RZX run's walkthrough | [1.11](01-game-design.md#111-a-walkthrough-the-rzx-run), [7.12](07-objects.md#712-the-course-of-the-rzx-run) |
| the 128K pages, the memory map, the module map | [2.1](02-architecture.md#21-the-machine-budget), [2.2](02-architecture.md#22-the-memory-map), [2.3](02-architecture.md#23-the-module-map) |
| the frame budget, the call graph, the heatmap | [2.5](02-architecture.md#25-the-frame-budget), [2.6](02-architecture.md#26-the-main-loops-call-graph), [2.7](02-architecture.md#27-the-heatmap-and-the-stack) |
| the SkoolKit disassembly | [2.10](02-architecture.md#210-what-the-skoolkit-disassembly-covers-and-where-this-case-differs) |
| the tape, the loader, the set-up, the 48K path | [3.1](03-build-and-load.md#31-the-tape-block-by-block) - [3.4](03-build-and-load.md#34-the-48k-path-and-the-2a-stop-block) |
| the build | [3.7](03-build-and-load.md#37-the-build) |
| one pass of the main loop, frames per pass | [4.3](04-game-loop.md#43-one-pass-of-the-main-loop), [4.4](04-game-loop.md#44-frames-per-pass-and-the-pass-against-the-beam) |
| the statuses, death, respawn | [4.5](04-game-loop.md#45-the-heros-status-machine-5c06), [10.2](10-gameplay-logic.md#102-the-statuses), [10.7](10-gameplay-logic.md#107-deaths-lives-and-the-restart) |
| the countdown, the space scene | [4.6](04-game-loop.md#46-the-countdown-935d-and-the-lost-game-9372), [10.10](10-gameplay-logic.md#1010-the-professor-the-telescope-and-the-ending), [10.11](10-gameplay-logic.md#1011-the-countdown) |
| every port and key read | [5.1](05-controls.md#51-the-devices-and-the-ports), [5.3](05-controls.md#53-readdevice-b894-and-the-three-readers) |
| the abort and the freeze | [5.9](05-controls.md#59-the-abort-and-the-freeze) |
| tiles, back-tiles, DrawRoom | [6.2](06-rendering.md#62-the-tiles-and-the-alternate-set) - [6.4](06-rendering.md#64-drawroom-the-whole-play-window-once-a-room) |
| sprites, RenderPass, the mirror | [6.6](06-rendering.md#66-the-sprite-format-and-the-sprite-space) - [6.9](06-rendering.md#69-drawspriterow-the-outline-mask-and-the-mirror) |
| the creatures and the collisions | [7.3](07-objects.md#73-the-creature-record-and-decoderoomcreatures) - [7.6](07-objects.md#76-collision-near-the-hit-frame-and-hitexplorer), [10.8](10-gameplay-logic.md#108-creatures-and-hazards) |
| the room scripts and the puzzles | [7.11](07-objects.md#711-the-room-scripts), [10.9](10-gameplay-logic.md#109-items-and-puzzles) |
| every text, the panel, the score | [8.4](08-hud-and-text.md#84-the-texts), [8.5](08-hud-and-text.md#85-the-panel), [8.8](08-hud-and-text.md#88-the-score), [10.12](10-gameplay-logic.md#1012-the-score) |
| the AY music, tune 0 | [9.3](09-sound.md#93-the-players-frame-musicframe-and-updatetune) - [9.8](09-sound.md#98-tune-0-the-loop-and-the-tunes-never-played) |
| the beeper sounds, the audio files | [9.10](09-sound.md#910-the-beeper-playsound-and-soundeffects), [9.14](09-sound.md#914-the-audio-files) |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning | Doc |
| --- | --- | --- |
| ActorRects | `$5B44`: per object slot, the buffer address of its 4 x 24 rectangle and its row plotter; copied to PrevActorRects `$5B24` each pass | 06 |
| alternate set | the second pictures for tiles `$80-$FF` (AltTilePixels `$FA00`, AltTileAttrs `$C580`), swapped in for the 15 rooms of AltTilesetRooms `$9AC6` | 06 |
| AYWrite | `$CD56` (RAM 6): the only routine that touches the AY: register at `$FFFD`, value at `$BFFD` | 09 |
| back buffer | `$E000-$EFFF`: the play window's twin in the screen's layout (screen address OR `$A000`); between passes it holds the room without the actors | 06 |
| back-tile | a block of 4 x 4 tiles at `$C600 + 16 x index`; a room is 8 x 4 back-tiles | 06 |
| bearer | one of 27 invisible carriers of the items not in the hand, BearerLoads `$5B7C` (`$FF` free); a pickup moves the held item to the first free one; the panel's bearer row draws four from BearerIndex `$5C23`, nine of their twelve columns show: three whole bearers at rest, parts of four while keys 1 and 2 scroll the row | 07, 08 |
| BearerIndex | `$5C23`: the first of the 27 bearers shown in the bearer row | 08 |
| BearerPhase | `$5C22`: 0-3, the columns of the bearer row skipped; the row's one-column scroll step | 08 |
| BearerScrollDir | `$5C21`: 1 after key 1, the bearers move right (BearerPhase counts down from 4); 0 after key 2, they move left (the phase counts up to 4) | 08 |
| BlitColumns | `$9F86`: copies 24-byte sprite columns from PanelColumns `$5BD6` to the panel | 08 |
| cell | a character cell of the screen, 8 x 8 pixels with one attribute; the play window is 32 x 16 cells, one tile each | 06 |
| checkpoint room | one of the 44 rooms of CheckpointRooms `$9AF5`; entered without falling, it saves the respawn point (SaveRespawnPoint `$9AA1`) | 04, 10 |
| CollisionText | `$B07C`: the telescope's "TIME REMAINING TO COLLISION" text | 08 |
| countdown | days, hours, minutes at `$5BFB-$5BFD`, plain binary, from 30/23/59; one minute a main-loop pass; at 0 the game is lost (LoseGame `$9372`) | 04, 10 |
| creature record | 4 bytes a creature in RoomCreatures `$C152` (three a room, 12 bytes); unpacked into a 10-byte working record at CreatureRecords `$BE24` on each room entry | 07 |
| day | a day of the countdown: 24 x 60 = 1440 passes, about 4090 frames (82 s) at the RZX run's 2.84 frames a pass | 01, 04 |
| DigitShown | `$5C20`: PrintNumber's leading-zero switch | 08 |
| explorer set | one explorer's 64 sprite frames, `$1200` bytes; on the 128K in RAM 4 (sets 0-2) or RAM 3 (sets 3-4), copied to ExplorerSet `$6000` for play | 02, 03 |
| frame | 1/50 s of the 128K, 70 908 T (69 888 T on the 48K); a recording's frames count from its start, 0 the first | 04 |
| GameWon | `$5BFE`: set by the sixth gift; it places the deflector in the space scene | 10 |
| HeldItem | `$5B98`: the item in the hero's hand, `$FF` none; the only item that works | 07 |
| hit frame | a creature's frame index (0-3) from which it can hit when its hit flag is set; 4 or more means every frame; a clear hit flag never hits, the drop always tests | 07 |
| InputBits | `$B87C`: the reader's result in the Kempston order, bit 0 right, 1 left, 2 down, 3 up, 4 fire | 05 |
| item slot | `$5C0E` and `$5C13`: the two floor items of the room (X, Y, item, record address) | 07 |
| ItemPlaces | `$B99D`: 31 three-byte records that place the items; bit 7 of byte 0 marks an item taken | 07 |
| MusicFrame | `$C000` (RAM 6): the AY player's entry, one call per interrupt on a 128K | 09 |
| NoteEndFlag | `$C14D` (RAM 6): up when a note ends this frame; that frame has no AY write and no effects | 09 |
| object slot | one of the five 4-byte records at `$5B04-$5B17` (X, Y, frame, flags) that RenderPass draws, also called an actor slot; slot 0 is the hero; flags bit 7 mirrors the sprite (the stored graphics face left, so bit 7 set faces right) | 06, 07 |
| order list | a channel's list of patterns and commands (transpose, repeat, detune, slot, end) | 09 |
| own room | the room left of room `$29` that only one explorer reaches (ExplorerRooms `$A66C`: `$2D`, `$2E`, `$2F`, `$46`, `$47`), where he gets the Formula | 01, 10 |
| pass | one turn of the main loop, from MainLoop `$9018` to its `JP MainLoop`; no HALT, so a pass takes 2.4 to 3.3 frames (2.84 on average over the RZX run); PassCount `$5C02` counts them | 04 |
| play window | the screen's top two thirds, `$4000-$4FFF`, 256 x 128 pixels, where the rooms are drawn | 06 |
| PlaySound | `$C4B2`: the beeper sounds 0-6 through SoundDispatch `$C4BC` and SoundEffects `$C55B` | 09 |
| PrintChar | `$90C6`: one ROM-font character, no attribute | 08 |
| PrintNumber | `$BD78`: the four-cell decimal printer of the score and the high score | 08 |
| PrintPage | `$C574` (RAM 1): the selector's page printer for Help (`$16` c r, `$0D`, `$01` pause, `$00` wait) | 08 |
| PrintString | `$94F9`: text with `$0D` line ends, attribute in A' | 08 |
| relocation table | the 67 words found through RelocTableOffset `$C003` (base + 3), which holds `$2A0F`: each names an address in the selector stored as an offset from its first byte; the relocation adds the run address, `$C000` on a 128K | 03 |
| respawn | the restart after a lost life, at the last checkpoint room's entry state (Respawn `$9090`) | 04 |
| room | one screen of the play window, 32 x 16 cells; its number is level x 12 + column (`$00-$47`, 72 rooms: six levels of 12, the last two only explorers' own rooms); Room `$5C01` | 01, 06 |
| room script | the per-room routine of RoomScripts `$B7EC`, run every pass before the hero moves | 07 |
| RZX frame | a frame counted from the start of the RZX archive's run (51 148 frames); the RZX dump samples the variables every 25 (`tools/rzx_dump.py`, `work/docs/tmA/rzx25`) | 01, 04 |
| rzxNNNNN | a segment of the RZX run replayed on our instance from the RZX state at frame NNNNN; its frames count from 0 | 04 |
| selector | the 128K's explorer choice screen in RAM 1, relocated to `$C000` by the set-up `$7200`; on a 48K it runs in place | 03, 05 |
| space scene | room `$28`'s script SpaceScene `$B0B6`, the end of every game: the asteroid falls on the Earth; with GameWon the deflector sends it back | 04, 10 |
| sprite space | `$6000-$8CFF`: 160 frames of 72 bytes, frame F at `$6000 + 72 x F`; explorer `$00-$3F`, creatures `$40-$7E`, blank `$7F`, items `$80 + n` | 06 |
| status | `$5C06`, 0-33: the hero's mode; 0 is free movement, each of 1-33 runs its handler of StatusHandlers `$A72E` (word N - 1 for status N) through StatusDispatch `$A6CC` | 04, 10 |
| tile | 8 x 8 pixels at TilePixels `$F000 + 8 x T`, attribute at `$DF00 + T`; tiles `$80-$FF` have a second set (the alternate set) | 06 |
| tile map | `$F800-$F9FF`: the current room as 512 tile numbers, built by BuildTileMap; the background and the collision map | 06 |
| tune 0 | the only tune played: 9696 frames of notes, a loop of 9698 frames (194 s) | 09 |
| wish | one entry of WantedItems `$B6BB`: the item the professor wants next (WantedItem `$5C3C`, 0 until he first asks) | 01, 07 |
