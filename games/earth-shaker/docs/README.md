# Earth Shaker: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | every screen with its recording and frame, the controls and the hidden keys F, H, G, the sixteen objects, the rules (gems and exit, 1024 passes of time, lives, the score table, the 50-record password check), the 32 caves with their parameters, speed and time limit, the unused test cave at `$F9A6`, what no recording reached |
| [2. Architecture](02-architecture.md) | the 48K budget, the stages to play, the memory map from the source and the heatmap, the cells and their graphics, the 14 modules (map and table), the budget by module and routine, the call graph, the stack (`$6959` at a pass, lowest `$6939`), the 1990 patches and the leftovers |
| [3. Build and load](03-build-and-load.md) | the covertape side and blocks 10-13 to scale, the BASIC line byte by byte, the ROM's LD-BYTES, the load from power-on frame by frame (predicted from the bits and measured), every copy and how it differs (the no-timer hack, EARTHOLD's graphics), the build |
| [4. Game loop](04-game-loop.md) | the states as a CALL nest and the abort's four POPs, the IM 1 handler (882 T) and the DI sites, the cave start and the unpacker `$82B6`, one pass step by step and against the beam, the mean pass in every cave and why the speed varies, the time limit in passes, the waits |
| [5. Controls](05-controls.md) | the nine self-modified key sites, the keyboard and Kempston copies swapped by menu keys 3 and 4 (and the save that loses a redefinition), RedefineKeys and WaitKey (no release wait), the menu keys, the key to the move (priority left-right-up-down, the POP AF refusals), fire without moving, G (four POPs), H, F, text entry, when a key counts |
| [6. Rendering](06-rendering.md) | the 16 x 11 window of 16 x 16 cells and the HUD rows, the cell graphics table `$8000 + 2 x code`, the 36-byte graphic in drawing order, DrawCell and DrawWindow (all 176 cells every pass, 59 % of a pass), WindowOrigin and the scroll, the per-cave slots (CaveSetup) for the 32 caves, the per-pass animations, the sheets, the map screen and its overlapped code, code against the screen and the beam |
| [7. Objects](07-objects.md) | every cell code and its states, the 314-byte cave record byte by byte with a worked decode of cave 1 (and an animation of UnpackCave filling the grid), the parameters `$FD9A-$FDA7`, the game variables, the object kinds and their collisions |
| [8. HUD and text](08-hud-and-text.md) | PrintGlyph and the font (codes `$68-$7F` too), PrintText and its cost, the decimal digits, the panel line and its writers, the gem counter, the anti-gravity counter, the time bar with its refill and bonus, the cave intro, every string, the high-score table and the name entry, the menu scroller |
| [9. Sound](09-sound.md) | the one-bit speaker, the ROM BEEPER as a T-state model, PlayTune's two voices and drums, the note periods, the 13 tunes and the tune per cave, the lost interrupts, every effect decoded with its cost and DI state, 31 WAV renders |
| [10. Gameplay logic](10-gameplay-logic.md) | a pass and its order, the bottom-up gravity scan and why it opens gaps in falling columns, falling and crushing (step down from under a boulder and die), rolling, pushing, fire with the dissolve and the burst, the switch chain, every special cell (the potion returns through the ROM at `$0038`), death, the timer of 1024 passes, gems, the exit, the win, the passwords (the cave names) and the caves from first to last |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |

## Terms

Each term once, here; the documents link to it. Alphabetical.

| Term | Meaning |
| --- | --- |
| BEEPER | the ROM routine `$03B5`: DE + 1 square-wave cycles with half periods set by HL, interrupts off inside (its EI at the end turns them on again) |
| burst | cell codes `$10-$14`: fire put out by a bubble; five passes, then empty (doc 10.6) |
| cave | one of the 32 levels: a cave record unpacked into CaveGrid and played pass by pass until the exit is entered, the player is killed, H is pressed or the 1024 passes of the time bar run out |
| cave record | 314 bytes in CaveData `$C000`: 300 bytes of cells, two a byte (left in the low nibble), then 14 parameter bytes (`$FD9A-$FDA7` once copied) |
| CaveGrid | the current cave at `$FDA8-$FFFF`, 30 x 20 cells, one byte each, row by row |
| cell | one place of the 30 x 20 cave: one byte of CaveGrid (its cell code); on the screen 16 x 16 pixels, 2 x 2 characters with 4 attributes |
| cell code | the byte of a cell, `$00-$1F` (doc 07.1), plus the vacated mark `$20` |
| cell graphic | 36 bytes: 4 attributes (top left, top right, bottom right, bottom left), 32 pixel bytes in drawing order |
| digit string | a number kept as one byte per decimal digit (0-9), printed with the digit glyphs at `$BD80` |
| dissolve | cell codes `$15-$1B`: a boulder burning on fire; seven passes, then empty (doc 10.6) |
| falling-earth caves | 13, 17, 22, 24 and 26, whose earth graphic is GfxFallingEarth `$A450`: their earth falls and rolls but never kills (doc 07.3, doc 10.8) |
| frame | 69 888 T on the 48K, one ULA interrupt; recordings are counted in frames, but the game does not sync to them |
| glyph | 8 bytes, one per pixel row, printed by PrintGlyph `$8040` into a character cell |
| key site | one of the nine 9-byte fragments (TryLeft `$83C3` ... FireDown `$8849`) that read a key or the stick; rewritten whole by menu keys 3 and 4, two bytes by RedefineKeys |
| lost interrupt | a frame whose interrupt pulse fell while interrupts were off (a sound, a tune, the wipe), so the IM 1 handler did not run; nothing in the game depends on it |
| modelled | computed from the code by a T-state model (`tools/tune_model.py`, `tools/fig_sound.py`), not traced |
| pass | one turn of PlayCave's loop PassLoop `$888D`: the player's step, the scan, the animations, the window redraw, the sound, the timer. Its length is its work: the mean pass of a cave is 5.5-9.4 frames in the RZX play (doc 4), one traced cave 13 pass 10.6; a cave's time is 1024 passes |
| patch chain | the 1990 version's hooks: a CALL put first in an old routine (AbortKey -> AnimateCellCodes -> SwitchClear -> AntiGravPass -> ScanCells) |
| position `frame:T` | a moment in a recording: the frame and the T-state inside it |
| scan | ScanCells `$8075`, once a pass: CaveGrid from row 18, column 29 back to row 0, column 0 (each row right to left, the rows upward); every falling object moves at most one cell a pass, so a falling column opens one-cell gaps. With anti-gravity on, AntiGravScan `$A655` runs instead, upward |
| speaker write | an `OUT ($FE)` that sets bit 4 (the speaker) high or low |
| switch chain | an object landing on a switch box clears every switch box and force field of the cave at the next pass (doc 10.7) |
| table word | the word of CellGraphicsTable `$8000` for a cell code: the address of its graphic |
| test cave | the unused cave record at `$F9A6` in the leftovers, every special object (most of them twice) on its top row |
| time bar | the 256-pixel bar at `$52C0` (row 22): one pixel per four passes; a jelly bean adds 32 pixels (128 passes), a push into a force field takes 3 |
| unison note | a note with N1 = N2: voice 1's period is one turn shorter, so the pulse width sweeps |
| vacated mark | bit 5 (`$20`) of a cell: written into a cell an object (or a vertical move of the player) just left, and under the new place of a rolled object; nothing falls or rolls into it for the rest of the pass, and ClearVacated `$81AC` clears it before the draw (doc 10.2) |
| ViewOrigin | `$FD70`: the cave index of the window's top-left cell |
| voice | one of PlayTune's two down-counters; voice 1 sets the speaker high at its end, voice 2 sets it low |
| window | the 16 x 11 cells drawn in character rows 0-21 |
