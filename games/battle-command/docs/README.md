# Battle Command: the documents

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

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| pass | one run of the main loop |
