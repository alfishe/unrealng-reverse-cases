# Moon Patrol: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the game as a player meets it: two courses of 25 points (A-Z without O), sectors, enemies and hazards, scoring and the bonus, the menus; screens, enemies, course map and key moments |
| [2. Architecture](02-architecture.md) | the 48K budget, the memory map, the three images, the states and the two interrupt modes, the 19 modules and where the time goes, the main loop's call graph |
| [3. Build and load](03-build-and-load.md) | the four tape blocks, the BASIC loader and its two RAMTOPs, power-on to `$8000`, no packer, the byte-for-byte source build, the hi-score tape and its ERR_SP trap |
| [4. Game loop](04-game-loop.md) | the state machine, the stack resets, the IM 2 handler (FRAMES, TunePlayer, Im2Clock), the bonus screen's lost interrupts, the main loop's 20 calls, frames per pass, the course script delays |
| [5. Controls](05-controls.md) | the six input handlers and their bit maps, keyboard and joystick figures, hold and abort, the menu keys, the hi-score name entry |
| [6. Rendering](06-rendering.md) | one screen in six bands, the pixel and line tables, the sprite table and its ten drawers, XOR erase, the scrollers and their feeds, the road and the craters, scenery colours, shots and wheels, the pass against time |
| [7. Objects](07-objects.md) | the object list run by the course interpreter, the record layout, the rock as the handler pattern, BoxOverlap and the jump score, craters and mines, UFOs and bombs, the Champion objects, every score site |
| [8. HUD and text](08-hud-and-text.md) | the HUD's eleven fields, the BCD score, the print code and its control codes, the three fonts, the point letters, every string, the menu pages, the hi-score tables |
| [9. Sound](09-sound.md) | the ROM BEEPER from the IM 2 handler, the tune format and player, its cost, the T key, the bonus screen's tune, fanfares and blip; rendered sound files |
| [10. Gameplay logic](10-gameplay-logic.md) | the buggy's states, speed and the three jump arcs, the eight kill sites, lives and respawn, points, sectors and the course loop, bonuses, difficulty, bugs |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| pass | one run of the main loop (MainLoop `$9696`, the 20 calls once); no frame sync; 6 to 8 frames in play, 7.05 on average (`i1` frames 300-4700, the buggy held forward; 8.4 over the whole of `i1` with the bonus screens held inside single passes); PassCount `$B23B` counts them |
| frame | one 50 Hz television frame of the 48K, 69 888 T; the unit of every recording |
| segment | one piece of a course script, from one End word `$9760` to the next; it waits SegmentWait `$B23C` passes |
| point | one of the 25 course checkpoints A-Z without O, set by the Point command `$9775`; the restart place after a death |
| sector | five points (A-E, F-J, K-P, Q-U, V-Z) ended by the sector-end record (SectorBonus `$A4EE`, `SectorEnd` in the course text) and the bonus screen |
| BasicStack | `$B25D`, the SP the BASIC's USR gave the game (`$C338`); every menu page reloads it |
| LoopStack | the SP saved at each main loop start; the bonus screen and the course switch jump back through it |
| ERR_SP trap | the tape code puts its handler `$82F3` at ERR_SP so a BREAK returns to the menu, not to BASIC |
| band | one of the six horizontal strips of the screen (HUD, sky, far, middle, near, road), whole character rows |
| strip | a scenery picture of 34 columns of 32 bytes that a scroller rolls in (`$EBC0`, `$E340`, `$E780`) |
| feed | the column of bytes a scroller shifts in at the right edge (`$5B00`, `$5B20`, `$5B40`) |
| slot | one of the 4 or 8 pre-shifted copies of a sprite frame; x AND 6 (or 7) picks it |
| drawer | one of the ten DrawSprite routines, each for one sprite size |
| record | an entry of the object list `$BEF8`: handler word, delay, fields |
| skip code | the tail of a handler that only steps HL; a finished record's handler word points there |
| box | four bytes y, x, height, width that BoxOverlap `$A7FE` compares |
| probe | BuggyUpdate's test of five pixels of line 162 under the buggy: a set one is a crater wall or a mine |
| immune clone | a recording with BuggyKill patched to `RET` (`i1`, `i2`), for coverage only |
| tune word | one 16-bit entry of Tune `$B4E6`: the BEEPER period itself (HL), 0 a rest, `$FFFF` the loop |
