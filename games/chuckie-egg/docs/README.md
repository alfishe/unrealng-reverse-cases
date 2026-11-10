# Chuckie Egg: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the screens and modes, the play screen, the controls, the cast, the eight maps, the rules, the scoring with a worked tally, the extra life, the cycle of repeats (levels 9-16, 17+, 25+, 33+), players and turns, the key moments |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map and heatmap, the three images, the stages from the tape to play, the 22 modules and who calls whom, where the CPU's time goes, the main loop's call graph, the sprites |
| [3. Build and load](03-build-and-load.md) | the tape as a picture, line 10 and the array `a$`, the loader and its picture (drawn black on black), ERR_SP and the main loop's check, the load frame by frame, the source build |
| [4. Game loop](04-game-loop.md) | the free-running main loop, the state machine, one pass, the slow tick and its countdowns, IM 2 for speech and IM 1 for the name entry, passes and ticks a frame, the beam, the delays |
| [5. Controls](05-controls.md) | the keyboard on port `$FE` (22 IN sites, no Kempston), the three key sets `$8250` and KeyTable, the menus, redefine and KeyUsed, HOLD and ABORT, the path from a key to Harry's step, the name entry under IM 1 |
| [6. Rendering](06-rendering.md) | the layout and the three bottom-up coordinate systems, the colours per object, the character set and PrintChar, SetupLevel, the sprite sheets, DrawSprite and its buffers, the erase strategy, the hens, PaintCells, the lifts, the HUD digits, code vs screen and the beam, the flicker measured |
| [7. Objects](07-objects.md) | the object block `$72D8` byte by byte, the hen records and their state machine, HenEatGrain, the duck, the lifts, the live maps `$61A8` and their cell codes, the eight level maps with their objects, the spawner (HenTable `$945B`, LiftTable `$9787`), collisions and their order, chance from the ROM |
| [8. HUD and text](08-hud-and-text.md) | PrintChar and its 204 codes, the texts and their files, the HUD panel, AddScore and the extra life, CountDown (bonus and time), the level-end bonus count-down, the scrolled messages, the menus and pages, the high score table and the name entry under IM 1, a data sheet of every text |
| [9. Sound](09-sound.md) | the three paths (Beep, the ROM's BEEP, the Orator's speech), the Beep loop to the T-state, every effect decoded, the two tunes, the Fuller Orator and its SP0256-AL2, the 33 phrases and what they say, the cost and the lost interrupts, the data sheet, twelve WAV renders |
| [10. Gameplay logic](10-gameplay-logic.md) | the pass and the slow tick; Harry's walk, climb, jump arc (a model in passes against the recording), fall, push off an edge and jump off a ladder; landing and bouncing; the egg test and eggs in holes; the hens' AI and the HenEatGrain bug; the duck's homing; the lifts and the lift-top trick; every way to die; time, bonus, scoring, the extra life; the difficulty cycle to level 81 and the Level wrap at 256 |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| allophone | one speech sound of the SP0256-AL2, a byte 0-63 written to port `$9F`; PA1-PA5 are pauses |
| allophone hold | the interrupts PhraseInterrupt `$9CC2` waits before the next allophone: count x 20 ms |
| Beep | the game's tone loop `$9CA4`: L cycles of half period H, 26 H + 47 T a cycle |
| bonus step | one pass of PlayLevelBonus `$A675`: bonus - 10, score + 10, a beep; the step past 000 still pays, so a bonus of N is paid as N + 10 |
| cell address | `LiveMap + x / 8 + 32 x (y / 8) = LiveMap + x / 8 + 4 x (y AND $F8)`, row 0 at the bottom (MapCellAt `$9E34`) |
| CellAttributes | `$984F`: the attribute of map codes 0-8 (codes 9 and up take 6) |
| CellBuffer | `$72DD`: 24 lines of 3 bytes, the glyphs of the 3 x 3 map cells under a sprite |
| code | a byte of a text: the glyph number of PrintChar, CharacterSet `$84F0` + 8 x code; 204 codes, `$00-$CB` |
| countdown | a counter of slow ticks that starts a task when it reaches 0 and is then reloaded: LiftDelay 2, HenDelay 3 (2 from level 33), TimeDelay 10, DuckDelay 12, BonusDelay 50 |
| drift | JumpState 1, the four slow ticks of sideways push before a fall off an edge (FallOffEdge `$B34C`) |
| duck box | DuckX in HarryX - 7 .. HarryX + 8 and DuckY in HarryY - 8 .. HarryY + 9 (DrawSprite `$9B9E`); the test runs also while the duck is caged |
| egg test point | (HarryX + 8, HarryY - 8), the middle of Harry's lower half (TakeEggOrGrain `$99DF`, once a slow tick) |
| feet row | standing on map row p, Harry has HarryY = 8p + 23; his feet are on row p, his body in rows p + 1 and p + 2. The feet cell is MapCellAt - `$3F` = (x / 8 + 1, y / 8 - 2) |
| frame | 69 888 T of the 48K, from one INT to the next. The game does not count frames (it counts passes and slow ticks); the case measures in frames because the recordings do ([4.1](04-game-loop.md#41-the-shape-of-the-program)) |
| Fuller Orator | the 1983 speech unit with the SP0256-AL2 on port `$9F` (159) that the game speaks through; unreal-ng does not model it |
| HenEatGrain reset | a left peck that touches Harry makes the kill return into ROM `$0100` / `$0101`; the Spectrum resets ([10.8](10-gameplay-logic.md#108-the-hens-ai-and-the-heneatgrain-bug)) |
| hen box | HarryX in x - 7 .. x + 5 and HarryY in y + 1 .. y + 28 of a hen record (DrawHen `$929C`, HenTouches `$9E66`) |
| HUD digit | codes `$9E-$A7`, the digits 0-9 of the HUD (HudCharacters `$89E0`); AddScore uses the font's digits at `$8670` instead |
| jump click | one cycle per slow tick in a jump, H = HarryY XOR `$FF`: the pitch follows Harry's height |
| KeyTable | `$732E`: the six (mask, port row) pairs the game reads in play (up, down, left, right, jump, jump); SetupLevel copies KeySets `$8250`, `$825C` or `$8268` into it by KeyType |
| lift-top trick | repeated catches by a rising platform while jumping, which survive because the lift death test runs only after a lift step with OnLift 1 ([10.10](10-gameplay-logic.md#1010-the-lifts-catchlift-and-the-lift-top-trick)) |
| light pass | a pass that is not a slow tick and makes no jump step: the ERR_SP check, the pickup sound check, PassCounter (149 T in the border) |
| LiveMap | `$61A8`: the 32 x 21 map of the level in play, one cell code a byte, row 0 the bottom row |
| pass | one run of MainLoop `$9858` to its `JP MainLoop` at `$99DC`; a light pass takes 149-168 T. Measured: 161.8 passes a frame on level 1 with the bot playing and 162.9 on level 4 with Harry standing ([4.6](04-game-loop.md#46-passes-and-ticks-a-frame)), 122 in a jump ([10.1](10-gameplay-logic.md#101-two-clocks-the-pass-and-the-slow-tick)). The jump is timed in passes |
| phrase | a list of (count, allophone) pairs in PhraseTable `$C8C8`, ended by `$FF`; 33 of them |
| PhraseTimer | `$7373`, the interrupts to the next pair; `$FF` when no phrase plays, and StartPhrase drops a request while one does |
| pickup sweep | the 63 two-cycle beeps after an egg or grain, a saw of H 33 down to 9, eight times |
| read blank | a screen line the beam reads after a sprite's erase wrote it and before its redraw did ([6.10](06-rendering.md#610-flicker-measured)) |
| row from the bottom | PrintChar's H: 0 is screen row 23, 23 is row 0 |
| sample of frame N | the memory at the start of frame N (TTD `memory_at`). A trace shows an instruction in the frame where it ran, so a change done in frame N appears in the sample of frame N + 1 |
| slow tick | the pass in which PassCounter `$72DC` reaches 0 (reloaded with `$82`), once in 130 passes; every task but the jump runs there: Harry's walk and climb, the hens, the duck, the lifts, the egg test, the time and the bonus ([4.4](04-game-loop.md#44-the-slow-tick-and-its-countdowns)) |
| SpriteBuffer | `$72A0`: 16 rows of 3 bytes, a DrawSprite frame shifted to the pixel and ORed with the background |
| stale JumpDelay | the drift does not set JumpDelay, so the first fall step waits for what the last jump left there |
| ticks a frame | slow ticks per frame, the game's real speed, lower the more there is to draw: 1.25 on level 1 over 200 frames ([4.6](04-game-loop.md#46-passes-and-ticks-a-frame)); 1.32 in a hen's walk on level 1 and 1.05 in a lift cycle on level 3 ([10.1](10-gameplay-logic.md#101-two-clocks-the-pass-and-the-slow-tick)) |
| under-run | CountDown taking 000 to `$FF 9 9`: the bonus stops, the time ends the life |
