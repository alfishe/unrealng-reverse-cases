# R-Type: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the premise and the goal, the four control methods, every screen from the load to the wrap (two contact sheets, the title cycle), the eight levels with their maps, the rules: lives, the restart points, continues, the beam, the Force and the pick-ups, the score and the extra lives, the high scores |
| [2. Architecture](02-architecture.md) | the 48K and the stages to play, the memory map at three moments (a figure and a table), the code's self-modified bytes, BitReverse's lost byte, the eight levels in the level space, the heatmap and the stack, the leftovers, the frame budget, the module map, the call graph, the 48K and the 128K |
| [3. Build and load](03-build-and-load.md) | the tape block by block, the BASIC and its hidden USR, the 119 rewrite loops of the SpeedLock 7 chain, SL7Start, the reader and its keys, the timing check, the countdown, Decipher and the Tail's `$7FFD` lock, the game's level loader and the wound-back tape, the failures, the releases, the build with the re-encryption, the POKEs |
| [4. Game loop](04-game-loop.md) | the state machine, IM 2 through `$8383` and the task table `$BE60`, the pass of `$8649` and its 3-interrupt wait, where the interrupts are off, the measured pass (4.68 frames), the pass against the beam, the 12-frame pass (three explosions' noise bursts in the interrupt), the level start (55 s, all but 2 s tape), every delay and timer |
| [5. Controls](05-controls.md) | the four methods and ControlBits `$74FA`, the four readers and what an emulator must decode, the Kempston probe, the title's control choice, DEFINE, from the bits to the ship, the fire and the beam charge, the detach key, the pause, the name entry |
| [6. Rendering](06-rendering.md) | the screen and its buffers (the pixel shadow `$6000`, PlayAttrs, SolidMap, DrawnMap, RowTable, ColumnBuffer, BitReverse), the map and the metatiles in four variants, the 8-pass scroll, ScrollRows and the unrolled ShiftRun chain, DrawSprite and the cell rules (drawing is collision), the first screen, the stars, the draw order and the free erase, the code against a real frame, the scroll against the beam, the attribute grid with no clash |
| [7. Objects and levels](07-objects.md) | the game variables over a level, the level block byte by byte (header, wave script, objects, map, kinds, movers), the wave script and its commands, every level's waves on its map, the kind record, the scripts and their paths, the 28 slots and MoveEnemies, the level movers, collision (SolidMap, tags, hits), the random numbers and the boss blast, level 1 decoded against its recording, what differs between the 8 levels |
| [8. HUD and text](08-hud-and-text.md) | the printer `$C081` and its two heights, the font and its special glyphs (the meter, the life, "No.", TM, the copyright), every string and where it is printed, the HUD and DrawHud, the ASCII score and the extra lives (50 000, then every 100 000), the meter and the lives, the messages, the high-score table, the closing text that never shows |
| [9. Sound](09-sound.md) | the three channels in the interrupt, PlaySound's channel and timbre, the script language (16 commands), TonePlayer and the chords, NoiseBurst from the ROM, the 35 sounds decoded with the event that plays each and a WAV or MP3 render, the unused ones, the cost (the 12-frame pass is three explosions), Silence's bug, 48K against 128K |
| [10. Gameplay logic](10-gameplay-logic.md) | the ship and its limits, the weapon bytes over a level, fire, charge and detach, the shot and the three beams, the Force's states and docking, the pick-ups, the bits, the missiles, the shield that does not protect, the enemies and bosses per level, the three death paths, lives and continues, the score and the extra lives, the level end and the wrap, the patched bytes of play |
| [11. Data reference](11-data-reference.md) | every data entry of the game image and the level parts, with its readers and writers in the recordings (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its callers, runs and figures (generated, as 11) |

## Terms

Each term once, here; the documents use these names and no others.

| Term | Meaning |
| --- | --- |
| BeamCharge | `$7ABF`: + 2 a pass while fire is held, up to `$3E` (`$40` is never stored); the beam's strength on release |
| bit | a satellite above (BitUpperOn) or below (BitLowerOn) the ship's trail |
| block column | 32 pixels of map: 5 bytes, each a metatile of 4 x 4 cells |
| channel | one of the three sound scripts, a pointer at `$FBCD`/`$FBCF`/`$FBD1`; 0 is free |
| credit | CreditDigit `$72CB`, `'5'` at the start: 4 continues |
| double height | PrintText `$C081` (TextHeight 0): each glyph line on two screen lines, the text over two rows |
| DrawnMap | `$8100`, 640 bytes: 1 where a sprite cell is on the screen and must be erased if not redrawn; the star task draws only where it is 0 |
| Force | the detachable pod: one of three records (ForceRecord `$7AA8`, +3, +6) by ForceLevel; states 1-7 |
| IntTicks | `$7A8A`: the interrupts counted since the pass began; MainWait waits for 3 (FrameCounter `$7A89` counts the scroll's passes) |
| kind | an enemy type of a level: its record (hits, score byte, script, mover) in the level block at `$C4BE` |
| level space | `$C4AE-$F871`: where LoadLevel loads each level's body; SoundStack `$F872-$F87B` above it |
| LevelEndTimer | `$7A9B`: set by wave command 5 (`$41`) or a boss blast's end (`$3F`); LevelEnd acts on it |
| metatile | 4 x 4 cells, 144 bytes (attribute + 8 lines per cell), below the map; a map byte = metatile (bits 0-5) + drawer (bits 6-7) |
| mover | a level's own routine for a kind (A0-A15, B0-B15), called from MoveEnemies |
| pass | one run of the main loop `$8649`: at least 3 interrupts, 4.68 frames on average in level 2 |
| pixel shadow | `$6000-$77FF`: the play field's sprites drawn off screen, laid out like the screen `$2000` higher (the scenery is not in it); PlayAttrs `$7800` its attributes |
| PlayAttrs | `$7800`, 640 bytes: the playfield's attributes, copied to the screen by ScrollRows |
| restart point | the block column and wave entry a life starts from (LevelRestartColumn `$C4AE`, LevelRestartWave `$C4AF`); CheckRestart sets it to a checkpoint column - 8 when MapColumn reaches it |
| ScrollStep | `$7A82`: FrameCounter AND 7; step 0 a new column 31, 2-6 cut one metatile column each, 7 the attributes move |
| shift run | a run of scenery cells and the cell left of it, shifted one pixel by the unrolled `RL (HL)` chain ShiftRun `$8914` |
| slot | one of the 28 enemy records at EnemySlots `$8501`, 9 bytes each |
| soft cells | SoftCellsOn `$C3E5`: DrawSprite writes to the screen (`$8EBE` = `$40`) and ignores the scenery-to-the-right rule (`$8F10` = `RET C`) |
| SolidMap | `$7E00`, 640 bytes: one tag per playfield cell |
| staging column | column 31: black on black, where each new column of scenery is written and shifted into view |
| tag | a cell's SolidMap byte: 0 empty, `$DC`-`$FF` scenery, `$FA` a soft cell, other values the object drawn there in this pass (below 6 the ship); a draw over a tagged cell is a hit |
| task table | TaskTable `$BE60`: the interrupt's 5 entries (address, switch, counter, reload): the stars, the three sound channels, the title colour |
| tick | one step of a channel's script, played by its interrupt task every third frame |
| timbre | TimbreHigh / Mid / Low: patched operands that set note length and noise bursts (PlaySound bits `$80`/`$40`/`$20`) |
| wave | a 5-byte entry of a level's wave script: when (column, cell, step) and which kind starts in which slot |
| the wrap | level 8's second end loads level 1 with the score and lives kept |
