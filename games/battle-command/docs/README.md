# Battle Command: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the premise, every screen and how they connect, the ten missions and the Grand Finale's lock, the stores and the 1000 kg payload, the play keys and views, the failure texts, the entry string |
| [2. Architecture](02-architecture.md) | the 128K banks, the module map, the paging block `$7225-$72F3`, the memory map per bank, heatmaps, the stacks, leftovers, where the time goes |
| [3. Build and load](03-build-and-load.md) | both tape sides, the BASIC's hidden number, the 103-layer R-keyed chain, the SpeedLock 7 loader and store cipher, the BlockTable, the bootstrap, side 2's mission blocks, Ocean's broken mission 2, the Erbe release, the re-protecting build |
| [4. Game loop](04-game-loop.md) | the program's states, the IM 2 handler, interrupts off and lost, one 3D pass, the pass against the beam, frames per pass, delays and timers |
| [5. Controls](05-controls.md) | the five readers (Sinclair, cursor, keyboard, Kempston joystick, Kempston mouse), DecodeDirections, the pointer and its zones, the keyboard scan and KeyRepeat, the menus as a state machine, the options, driving, the play keys |
| [6. Rendering](06-rendering.md) | the back buffer and the three blits, one pass of the 3D view, the camera, the projection by logarithms, the clips, the polygon fill and its patterns, lines and ground dots, the copy against the beam, the views, the bank 7 pictures (format, unpack, pack) and the black shadow screen, the HUD, the frame rate against the load |
| [7. Objects](07-objects.md) | world units, the mission block byte by byte (header, vertices, segments, the 8-byte object list, the 30-byte templates) with worked decodes, the models and BoxRect16 (half angle, radius x 64, height), the 60-byte object record, ActivateMissionObjects and its self-modified operands, the object kinds as state machines (scenery, spawner, unit, shell), CollisionPass and its timers, the player's state, the weapon slots, Random |
| [8. HUD and text](08-hud-and-text.md) | PrintString and its 14 control codes, the 8 x 8 and 6-pixel fonts, the four small-font shifts, the numbers, the cockpit panel field by field with its writers and costs, the hit messages and their timer, the catalogue, briefing, status and end screens, the load / save code editor and its alphabet, the data sheet of every text |
| [9. Sound](09-sound.md) | two AY drivers on one chip, the effect driver's shadow and gates, the engine as an envelope, 14 effects decoded with WAVs, the bank 4 tracker player and its format, the title tune with its leaking transpose, pitch, costs, witnesses |
| [10. Gameplay logic](10-gameplay-logic.md) | a pass in order, PlayerStep and fuel (the fuel failure), the boundary (AWOL, desertion), the enemies and their shared gun timer, PlayerHit with the armour and subsystems (a death by armour, POKE recording), kills and the score, all 13 stores and the 1000 kg payload, debris, the ten goal hooks, the Helicarrier and the pickup, every failure cause, the Grand Finale gate, the save code, the two completed missions, notable features |
| [11. Data reference](11-data-reference.md) | every data entry of the game image `$5B00-$FFFF` (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine of the game image with its callers, runs and figures (generated) |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning | Doc |
| --- | --- | --- |
| AWOL state | `$7578`: 0 inside the world, 1 beyond the extent (GOING AWOL), 2 more than 4 coarse units beyond (desertion) | 10 |
| AY shadow | `$D674-$D681`: R0-R13 as SoundFrame builds them, written by WriteAY `$D7DC` | 09 |
| back buffer | `$8AF1-$96F0`, 32 x 96 bytes, linear rows; the 3D view is drawn there and copied by a blit | 06 |
| bank | one 16 KB RAM page of the 128K, eight of them: banks 5 and 2 always at `$4000` and `$8000`, one of the others at `$C000` through the paging block; the game image `$5B00-$FFFF` is banks 5, 2 and 0, and banks 3, 4, 6 and 7 are paged in for the raster, the music, the menus and the pictures | 02 |
| blit | one of ViewBlitFront `$8999`, ViewBlitWide `$8A41`, ViewBlitNarrow `$8A98` (BlitMapView `$DBBD` in bank 6): the copy of the back buffer to the screen that the interrupt runs while the blit request is set | 06 |
| blit request | `$83BA`: `$FF` set by RequestViewBlit `$988D`, makes the next interrupt copy the back buffer to the screen | 04 |
| BlockTable | `$BF30`, the list of blocks of side 1: address, length, bank | 03 |
| channel record | one of the three 39-byte records of the music player at `$C05A` | 09 |
| coarse unit | 1024 world units; the unit of the list records' spawn test and of BoundaryCheck | 07 |
| collision timer | the per-pair countdown in `$C648` that CollisionPass sets from the distance and the speeds | 07 |
| control code | a byte below `$20` in a PrintString string: a routine of ControlCodes `$6F8F` with its operands after it | 08 |
| effect counter | one byte of `$D682-$D68E`: a trigger sets it, SoundFrame counts it down and shapes the voice from it | 09 |
| entry string | the ten-character progress code, alphabet bank 6 `$CF5F`; zero progress is `9999999999` | 01 |
| failure cause | `$7BF9`: the address of the failure text shown by MissionFailedScreen | 10 |
| frame | one interrupt period of the 128K, 70 908 T; positions are written `frame:T` from the start of a recording; the game never halts, and an interrupt that comes while interrupts are off is lost (4 % of them in the normal view) | 04 |
| goal hook | the mission's routine (header word `$DBE1`) called from `$6A66` each pass; it sets the goal flag `$68E8` when the goal is met | 10 |
| layer | one of the chain's 103 decryption loops (69 add, 22 dec, 12 sub), keyed by R | 03 |
| light value | `$757A`; 0 makes every face solid ink (silhouettes) | 06 |
| list record | one 8-byte entry of the mission's object list (`$DBDA`): flags (b7 alive, b6 spawned, b1 destroyed), template, heading, X, Y | 07 |
| mark | a 3 x 7-bit timing group between blocks; a bad second group sets TimeFailed `$BED0` = `$7F` | 03 |
| message timer | MessageTimer `$87D6`'s operand `$87D7`: 100 interrupts, then the blank message | 08 |
| mission | one of the ten worlds of side 2: a mission block with its own goal hook, code and models; missions 1-9 in any order, each completed once (its flag set, LoadMissionIfAllowed refuses it), the tenth only after all nine | 01 |
| mission block | the side 2 block loaded to bank 0 `$DBC5` (up to `$FB3E` for mission 1) by LoadMissionBlock `$855B` | 03 |
| object record | 60 bytes at `$75F0` + 60 n, 24 of them; record 0 is the tank | 07 |
| order list | a channel's list of pattern numbers and commands (`$FF` transpose, `$FE` repeat, `$FD` restart, `$FC` jump) | 09 |
| paging block | PageBankA `$727D`, PageOut `$7280`, SaveBank `$7288`, RestoreBank `$729B`, in bank 5 `$7225-$72F3` | 02 |
| pass | one run of PlayLoop `$6A0C` from StartViewPass `$9882`: one picture of the 3D view built in the back buffer; 7.5 frames in the normal view of mission 1, 6.8 with the binoculars, 12 in the rear view | 04 |
| payload | the summed weight of the fitted stores, limit 1000 kg: 1001 kg or more is refused (check `$C1B6-$C1C9`) | 10 |
| picture block | a packed screen of bank 7 (header, 16-byte table, LSB-first token stream: LIT, TAB, COPY, RUN) | 06 |
| pixel line | the line operand of codes 1, 2, 6 and 7: an index into ScreenRowTable `$6500`, one word per screen line | 08 |
| raw printer | PrintRawString bank 6 `$C6FC`: 8 x 8 glyphs straight to a screen address, 0-terminated, no codes; the code editor's | 08 |
| reader | the input routine DeviceReaders `$9723` selects (ReadSinclair, ReadCursor, ReadKeys, ReadKempston, ReadMouse) | 05 |
| resident type | the types `$80-$8C` kept in the game code: the player's projectiles, the Dragonfly, the Helicarrier | 07 |
| save code | ten characters from EncodePassword `$CE2E`: the 32-bit score, ten mission flags, a 5-bit checksum (recorded: `C5989999PB` after mission 1, `H59K9999PK` after mission 4) | 10 |
| screen node | one state of the menu/play graph of doc 01 section 1.2 | 01 |
| shadow screen | bank 7's screen, shown (bit 3 of `$7FFD`) while a bank 7 picture unpacks on bank 5; black, as its attributes lie in the zero area Bank7Free | 06 |
| shift routine | one of the four small-font glyph routines of ShiftRoutines `$6E9F`, picked by the cell's pixel offset 0, 2, 4 or 6 | 08 |
| small font | SmallFont `$7C59`: 44 glyphs `0`-`[` in 6-pixel cells, stored inverted; `:` is the blank, `[` the full stop | 08 |
| spawner | an invisible mission object whose step makes enemy units around the camera and keeps three alive | 07 |
| store cipher | StoreByte's `(L XOR k) + a`, k rewritten by blocks 17 and 19 | 03 |
| template | 30 bytes of a mission object type, copied into a record by ObjectSetType | 07 |
| view | what the 3D window shows and the blit that copies it: the front view, the rear view, the binoculars and the zoom (ViewBlitNarrow), the Dragonfly's view, the night sight, the console's map; each has its own frames a pass (doc 04 section 4.6) | 06 |
| wreck | a destroyed list object: record kept, +2 b6 set, drawn with the wreck model (+8) | 07 |
