# GAME: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the game as a player meets it: premise, controls, objects, rules, scoring, modes, difficulty |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map (a figure), stages from the medium to play, the frame, the main loop's call graph, the module map |
| [3. Build and load](03-build-and-load.md) | the medium block by block, loaders, packers and their formats, the unpack animations, the source build |
| [4. Game loop](04-game-loop.md) | the state machine (a diagram), the frame schedule, the order of work inside a pass, timing |
| [5. Controls](05-controls.md) | devices, ports, decoding, menus, hidden keys |
| [6. Rendering](06-rendering.md) | the screen and how it is drawn: buffers, blits, scrolls, sprites, the raster timing |
| [7. Objects](07-objects.md) | records, slots, kinds, movers, collisions |
| [8. HUD and text](08-hud-and-text.md) | panels, fonts, the print routine, every string |
| [9. Sound](09-sound.md) | the engines, music and effects formats, the players, timing |
| [10. Gameplay logic](10-gameplay-logic.md) | the rules as code: the player, enemies and their behaviour, levels, scoring, what the recordings showed |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |
| [13. Path finding](13-path-finding.md) | how robots walk to a target: the decision from the code, what it is not, its odds, obstacles, traps, the door approach, the target bug, the ship; checked byte for byte against the game |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| pass | one run of a loop. A pass of `PlayLoop` `$A69A` is one game turn ([4.3](04-game-loop.md#43-the-turn)) |
| game turn, turn | one call of `GameTurn` `$AD62`: 5 minutes of game time, at least 10 frames (`TurnPace` `$AE1D`). It runs once a pass of `PlayLoop`, of the robot menu's `ListMenu` `$ACD7` and of `DirectControl` `$A941` ([4.5](04-game-loop.md#45-time)) |
| frame | one 50 Hz screen frame of the 48K: 69 888 T, one interrupt. The recordings count frames from their own start |
| T, T-state | one Z80 clock cycle at 3.5 MHz |
| game day | 288 game turns, 24 game hours, about 58 s at 10 frames a turn; production is paid at its end ([1.10](01-game-design.md#110-time-and-production)) |
| HUMN, INSG | the two sides as the status panel names them: the player (humans) and the computer (the Insignians) |
| warbase | a base where robots are built (pad) and that yields 5 general resource a day; 4 of them, capture points 0-3 (`Warbases` `$FD70`) |
| factory | a base that yields 2 of one resource a day; 24 of them, 4 of each kind, capture points 4-27 (`Factories` `$FD84`) |
| capture point | the 5-byte record of a base: its door cell, owner and type, and the turns a robot has stood on the door; 144 turns capture it ([7.6](07-objects.md#76-buildings-and-capture-points)) |
| pad | building type 0, on top of a warbase the player holds; landing on it at height 15 opens the construction menu |
| building | a 3-byte record in `Buildings` `$FF01`: a pad, a factory roof or a flag, the things drawn on the bases |
| robot record | 16 bytes in `Robots` `$DA00`: slots 0-23 the player's, 24-47 the enemy's from `$DB80` ([7.2](07-objects.md#72-robots)) |
| part | one of the eight things a robot is built from: bipod, tracks, anti-grav (chassis), cannon, missiles, phasers, nuclear (weapons), electronics; a bit of the record's `+$07` |
| resources | general, electronics, nuclear, phasers, missiles, cannon, chassis: 7 bytes, `Resources` `$FD22` (the player) and `EnemyResources` `$FD4A` |
| order | a robot's task, `+$0B`, 0-8 ([1.7](01-game-design.md#17-the-robot-menu-and-orders)) |
| shot | a 9-byte record in `Shots` `$D7D3`, 5 of them |
| map, cell | `Map` `$DD00`: 16 rows of 512 cells; a cell byte holds the terrain type (bits 0-4) and the marks bit 5 (covered part of a block), 6 (an object) and 7 (the ship) |
| view | the 32 x 16 cells round the ship, drawn isometric into `ViewBuffer` `$5B00` and copied to the screen once a turn |
| radar | the strip under the view: two 16 x 16-byte pictures, `$D800` ours and `$D900` the enemy's, shown on alternate frames |
| handler | the routine the IM 2 jump at `$FDFD` names (`Handler` `$FDFE`): `StartInterrupt`, `MenuInterrupt` or `PlayInterrupt` ([2.4](02-architecture.md#24-time-frames-and-interrupts)) |
| N1 | the 180-byte loader on the tape, at `$FCDA`: the ROM's LD-BYTES in RAM ([3.5](03-build-and-load.md#35-n1-the-loader-block-3-fcda)) |
| image | memory `$4000-$FCE8` as N1 leaves it, the game block; `src/game` assembles `$5B00-$FCE8` of it |
| recording | a TTD recording of an unreal-ng run, kept in `work/<name>` (git-ignored) |
| `load` | the first recording from power-on; kept for the load only (its play hit a LOADING ERROR!) |
| `play` | power-on, the tape (blocks 0-3 fast, N1's block at signal speed), the menu, 3 673 frames of random play on Kempston; 16 514 frames |
| `game` | the L1 build of `play` from the game's entry, frame 12661 |
| `deep` | the bot's game (`tools/bot.py`) from the menu snapshot of `play`, 36 046 frames, 11 game days, robots and fights |
| L1 | the per-recording analysis build (`l1.json`): every routine, call, loop and byte access with counts and T-states |
| TTD | time-travel debugging: seeking a recording to any frame and reading its memory (`memory_at`) |
| access trace | a `.uatr` file of every instruction and memory access over a window of a recording (`analysis trace`), read by `kit/beam_timeline.py` and `tools/turn_profile.py` |
| signal speed | a block read at the speed the tape plays, as opposed to the emulator's fast-load trap of the ROM's LD-BYTES |
