# H.A.T.E. — documentation

Written as the documents of a new ZX Spectrum 48K game developed in 2026: what the game is, how it is built, and how
every part works, down to each routine. Every statement is backed by the code (an address in `src/`) and by what
the emulator saw the game do (a recording, a counter, an experiment); the evidence is named where it is not obvious.

| Document | Contents | State |
| --- | --- | --- |
| [1. Game design](01-game-design.md) | the game as a player meets it: premise, controls, vehicles, the course, enemies, scoring, lives, modes (demo, pause, abort), difficulty | not started |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map, the stages from tape to play, the frame, the main loop and its state machine, module map | written: budget, map, stages, the title player and its IM 2 handler, timing, the main loop's call graph; module names follow docs 4-10 |
| [3. Build and load](03-build-and-load.md) | the tape, the BASIC loader, the loader in the REM, the packed block and its format, the depacker, the source build | written: the tape, the loaders, the packers, the source build, the unpacker animation |
| [4. Game loop](04-game-loop.md) | the frame schedule, the interrupt, the state machine, the order of work inside a frame, timing | written: state machine, game and round start, the round table, the pass, losing a life and falling back; pass-length distribution pending |
| [5. Controls](05-controls.md) | the input devices the game reads: ports, decoding, the menu, any hidden keys | written: menu, control byte, four readers, Q/A swap, AUTO start, pause and abort keys |
| [6. Rendering](06-rendering.md) | the playfield and how it is drawn: the strip buffer, the skewing blit, the phases of the scroll, the course map | written |
| [7. Objects and sprites](07-objects.md) | the objects, their records, projection, size classes and shapes, drawing into the playfield | not started |
| [8. HUD and text](08-hud-and-text.md) | the panel, gauges, score, the font, windows and their texts | written: the print routine and its format, the font (strings in unused glyphs), every string, the panel, ASCII score, MAX/HIGH |
| [9. Sound and music](09-sound.md) | the beeper engine, the title music, the effects: formats, players, timing | written: the title engine (song, pattern, voices, drums, the interrupt as clock), the effects and their requests |
| [10. Gameplay logic](10-gameplay-logic.md) | the player's vehicle, physics, collisions, enemies and their behaviour, the course, scoring and the high score | not started |
| [11. Data reference](11-data-reference.md) | every table, buffer and variable: address, format, who reads and writes it | not started |
| [12. Routine reference](12-routine-reference.md) | every routine: purpose, inputs, outputs, registers, memory, timing, callers, callees | not started |

Figures are in `img/`: memory access maps, routine timelines, stage maps, graphics sheets, rendered from the
recordings.
