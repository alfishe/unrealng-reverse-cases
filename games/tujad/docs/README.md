# Tujad: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the game as a player meets it: the story, the screens and modes, the play screen, the controls, the cast, the world of 102 rooms, the rules (energy, lives, hazards, weapons), the pickups and the ED pieces, the key moments, the win and the game over |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map and heatmap, the three images (as loaded, at the entry, in play), the stages from the tape to play, the 25 modules, a first sprite sheet, where the CPU's time goes, the frame and the main loop's call graph, the authors' leftover source |
| [3. Build and load](03-build-and-load.md) | the tape block by block and as a picture, the BASIC line, the 32-byte stub at `$5B00`, the load in `c1` frame by frame, what loads is what runs, the source build; no turbo loader, no packer |
| [4. Game loop](04-game-loop.md) | the state machine, one pass of the main loop `$6911` with its two waits, WaitFrame and the sprite list, the IM 2 handler `$95D0`, interrupts on and off (the pause), 2 or 3 interrupts a pass (never 1), a light and the heaviest pass against the beam, the delays between scenes |
| [5. Controls](05-controls.md) | the one reader ReadControls in the interrupt (keyboard, cursor, Kempston), the Controls byte, the ROM KEYBOARD call, the menu, the key-to-droid path, fire and KeyLatches, the probe, the shield, the pause with interrupts off |
| [6. Rendering](06-rendering.md) | the screen layout, DrawRoom (dim, wipe, layout triples, clip, cell table from the colours), the XOR sprite list `$FF01` with its collision flag, the enemy buffers and graphics shifted in place, BitReverse and the turn, the exhaust, the scroller's move, the sprite sheets, code against the screen, flicker measured against the beam |
| [7. Objects](07-objects.md) | the alien map `$DB53` byte by byte, the per-room save (DrawRoom, SaveRoomObjects), the cell table `$60C0`, the step routines and the FoundItem stall, the enemy, object, patroller and droid records with their state machines, the spawn lattice, the start positions, the collisions and their order, Random |
| [8. HUD and text](08-hud-and-text.md) | the HUD panel and its fields, the font, Print8 / Blit16 / PrintText, PrintBcd, DrawHud, the weapon field, the ten messages and their priorities, the scroller and its queue, the menu texts, the progress screen, the win and the game over |
| [9. Sound](09-sound.md) | the beeper only, no tune: PassTick, the digit click, HazardFlash, PickupTone, RiseSweep and FallSweep, DeathEffect, the teleport's beams and flash; their timing, contention, cost, lost interrupts, rendered WAVs |
| [10. Gameplay logic](10-gameplay-logic.md) | movement and the hovering droid, exits and teleporters, the shield, the energy clock (EnergyTimer `$6366`), weapons, every way to die, lives and the game over, pickups and ED pieces, the deal (ScrambleRooms rotation), the goal (50 pieces, then room 84), the opponents, Random and the RZX drift, pause (no drain), notable features |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| act | one call of a mover that does something; an enemy or an object acts on every second call (about every fourth frame), the droid on every second pass (every pass in the air) |
| alien record | a room's record in AlienMap `$DB53`: two items, a teleporter, the enemy mask, up to two objects ([doc 7.2](07-objects.md#72-the-alien-map-db53-byte-by-byte)) |
| BeamScreen | `$63C5`, the teleport beam's delay a line (x 26 T) and tone switch: 5000 plays, 1 is silent (doc 9.9) |
| BitReverse | `$9A4C`: 256 bytes with their bits reversed, used by the turn's mirror ([doc 6.6](06-rendering.md#66-bitreverse-9a4c-and-the-turn)) |
| BorderSound | `$6375`, the next value written to port `$FE` by PassTick, HazardFlash and the beams; 0 or `$10`, the border stays black (doc 9.1) |
| cell table | CellTable `$60C0`, 576 cells; DrawRoom sets 1 where the attribute is not 0, the movers XOR their marks in ([doc 6.3](06-rendering.md#the-cell-table-from-the-colours), [doc 7.4](07-objects.md#74-the-cell-table-60c0)) |
| contended | a fetch from `$4000-$7FFF` while the ULA reads the screen waits; the sound loops there run about a third slower in the display (doc 9.2) |
| Controls | the byte `$63C2` ReadControls builds each interrupt: method bits 7-6, pause bit 5, fire and directions bits 4-0 ([doc 5.2](05-controls.md#52-the-controls-byte)) |
| deal | NewGame's 1-31 calls of ScrambleRooms `$7BA0`, always an odd number (`OR $01` before `AND $1F`), each rotating the 64 non-weapon item kinds by one slot along the room order: 16 possible deals for the first game after loading (doc 10.9) |
| EnemyBuffers | `$6708-$6887`: two 48-byte buffers per enemy, A for the old image (erase) and B for the new one (draw) |
| exhaust | the XOR flicker under the droid, drawn from the main loop ([doc 6.7](06-rendering.md#67-the-exhaust)) |
| flag pointer | word +2 of a sprite-list entry: the byte whose bit 7 the interrupt sets when the image met ink; `$0000` for erases and objects (the write goes to ROM, never flagged). FlagPointer `$637E` is the droid's: DroidFlags normally, `$0000` under the shield |
| frame | one 50 Hz frame of the 48K: 69 888 T, from the emulator's frame T 0; one INT a frame ([doc 4](04-game-loop.md)) |
| frame:T | a time as the emulator's frame number and the T-state in that frame (doc 4) |
| handler 1, handler 2 | the interrupt at a pass's first WaitFrame (it draws the movers' list) and at its second (the droid's list) |
| INT | the 48K's maskable interrupt; in unreal-ng it comes at frame T 1812 (intstart 1811), and the handler `$95D0` starts at T 1841-1844 ([doc 4](04-game-loop.md)) |
| KeyLatches | `$6369`: edge latches for SPACE, ENTER and fire; bit 6 set means fire must be released before the next shot ([doc 5.7](05-controls.md#57-fire-the-key-latches-and-the-weapon-select)) |
| kill mark | byte +8 of an object record, the weapon mark that kills it |
| layout triple | (column, row, tile) in RoomLayouts `$BD06`; a column byte with bit 7 ends a room ([doc 6.3](06-rendering.md#63-the-layout-triples-the-tiles-and-the-clip)) |
| lost INT | an INT that falls while the main loop runs with interrupts off; it is not held, and the next HALT waits for the one after |
| mark | the bit a mover XORs into the cell table under it: 2 an enemy, 4 an object, 8 a patroller; a shot ORs `$41`, `$21` or `$11` into an object's cells |
| pass | one run of the main loop `$6911-$698F`, from `$6911` to the next; it waits for the interrupt twice (WaitFrame `$795D`, called at `$6911` and `$6929`), so a pass holds 2 interrupts, or 3 when its work crosses an INT with interrupts off; never 1 ([doc 4.7](04-game-loop.md#47-passes-and-interrupts-a-frame)) |
| pass tick | PassTick's 4206 T low pulse, once a main-loop pass: the 25 Hz background tick ([doc 9.3](09-sound.md#93-passtick-the-tick-of-every-pass)) |
| priority | a message's first byte (1-20); QueueMessage `$6ACD` takes a message only if its priority is above ScrollPriority `$63CB` (doc 8.7, 8.8) |
| row boundary | the scroller step that makes ScrollLine 0, every 50 interrupts; a text row ends there and a waiting message is taken there (doc 8.8) |
| scroll wipe | DrawRoom's exit transition: 8 steps of SRL on even lines and SLA on odd lines over the play area ([doc 6.2](06-rendering.md#62-the-room-renderer-drawroom-6b22)) |
| ScrollLine | `$63CC`, the pixel line (1-7, then 0) the scroller draws next; line 0 draws the byte before the glyph (doc 8.2, 8.8) |
| shield | down held alone while standing: DroidFlags bit 4, FlagPointer `$0000` (no touch), EnergyReload `$0A` (one energy step every 10 interrupts instead of 250), HazardFlash ([doc 5.9](05-controls.md#59-the-shield-down-alone), doc 10.3) |
| shift in place | ShiftGraphic3 / ShiftGraphic4 shift a stored frame to x AND 7 and keep the offset in its first byte ([doc 6.5](06-rendering.md#65-the-enemy-buffers-and-the-graphics-shifted-in-place)) |
| sprite list | the 8-byte entries from `$FF01` that the interrupt XORs onto the screen at each interrupt ([doc 6.4](06-rendering.md#64-the-sprite-list-ff01-and-interruptsprite-95db)) |
| tick | an energy tick: EnergyTick `$7AB6` counts EnergyTimer `$6366` down one each interrupt taken; at 0 the energy drops by one (every 250 interrupts, 5 s; every 10 under the shield or while an enemy touches the droid, and 50 interrupts after). It counts interrupts, not frames, so lost INTs slow it ([doc 10.4](10-gameplay-logic.md#104-energy-and-its-clock)); the sound's tick is the pass tick |
