# MASK III: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the premise and the goal, the controls, every screen, the play panel, the 16 rooms in four zones and the way through, the rules (energy, masks, pods, password doors, score, high score), the enemies with their templates, the key moments |
| [2. Architecture](02-architecture.md) | the images, the memory map (a figure) with the parked zone sets, the heatmap, the state variables, the rooms as data, the module map and call graph, the frame budget, the stack, 48K against 128K, the leftovers |
| [3. Build and load](03-build-and-load.md) | the tape as a picture, the BASIC, Gremlin's loader and its 128K test, the saved stack in its block, the load animation, the build from source, build A against build B, the hacks, the POKEs, the JUDGE DREDD cheat |
| [4. Game loop](04-game-loop.md) | the state machine, the IM 2 vector trick (`$FF` table, `JR` at `$FFFF`), the handler and its cost, the free-running main loop and one pass against the beam, the room change under `DI`, every delay and timer |
| [5. Controls](05-controls.md) | the four control methods and their ports, the key codes and the self-patching KeyPressed, the menu keys, DEFINE KEYS, ReadControls (right over left, down over up), the path into Matt, the mask keys 1-4, BREAK, the password entry, the JUDGE DREDD cheat, H and Q (named, not there), what an emulator must decode |
| [6. Rendering](06-rendering.md) | the buffers at `$E000-$FDFF`, a room from 40 map bytes through the blocks, the zone sets, FlushDirty and the dirty map (erase one pass late), the sprite frames, DrawObject's fresh characters, the mask, mirror and shift tables, the pick-up icons, Dissolve, the animated characters, who writes which screen byte, six placeholder objects that cost 40 % of a pass |
| [7. Objects](07-objects.md) | the game variables, the world as data (16 rooms x 6 screens, the room table), a room decoded byte by byte from its map row to the characters, the exits (edges, pods, the arrival byte), what the map holds (pick-ups, turrets, block items, spawn points, the lift), the object table and its 38-byte record, the 20 enemy templates, the spawner, RunObjects with the shot and touch tests, every object kind and its state machine |
| [8. HUD and text](08-hud-and-text.md) | the play panel and its four live fields, the 5-line font and PrintChar, the score and the energy bar, the mask slots and the blink, the interrupt's scroller, every string with its address, the room messages and passwords, the menu screen, game over and the high score, the ending |
| [9. Sound](09-sound.md) | the two paths (AY on the 128K, beeper on the 48K) and their cost, the effect record, PlayEffect and the effect slots, the AY player in RAM 4, the three tunes (MP3) and when each plays, the 18 effects one by one (WAV), the beeper, 48K against 128K |
| [10. Gameplay logic](10-gameplay-logic.md) | one pass of the rules, Matt's twelve states, walking, steps and edges, the jump and the fall (earth and moon), pods and the materialisation, energy and every source of damage, the ten masks (slots, charges, pick-ups, keys), PENETRATOR, JACKRABBIT, LIFTER and the shots, HEALER, death, game over and the new game, enemies and hazards as rules, collisions and the score, the passwords and the door warp, the JUDGE DREDD cheat, the ending, bugs, notable features |
| [11. Data reference](11-data-reference.md) | every data entry of the game image `$6000-$FDFF` by module, with its readers and writers in the recordings (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its callers, runs and figures (generated, as 11) |

## Terms

Each term once, here; the documents use these names and no others.

| Term | Meaning |
| --- | --- |
| blink | the slot in use drawn as the blank EMPTY icon (32 zero bytes) while PassCounter bit 3 is set (DrawIcon `$B024`) |
| block | 4 x 4 character codes at Blocks `$8500` + 16 x n; a room screen is 8 x 5 blocks |
| block item | a `$1B` block in the map: touching it costs 25 energy and turns it into block `$47` (TakeBlockItem `$B33D`) |
| build A, build B | the two builds of the code: Gremlin's original (this case), and the IBSA / Erbe re-release |
| character map | CharMap `$F080-$F2FF`, 32 x 20 character codes; rows 2-19 are the play window's screen rows 0-17 (`$F0C0`) |
| charge | one unit of a slot's BCD stock, 99 when a mask is taken; UseCharge `$B210` takes them (a LIFTER shot 8) |
| CheatOn | `$BB77`: `$FF` while the password buffer holds JUDGE DREDD (CheatCheck `$BB4C`); masks keep their charges, floors do not kill |
| deadly floor | character `$EA` (`$ED` in zone 3) under Matt's feet; on the moon `$FE` / `$FF` |
| DeathFlag | `$B2F8`: set by the deadly floors, the moon floor and the fall out of the play area; MainLoop jumps to Death |
| dirty map | DirtyMap `$F3C0-$F5FF`, one byte a shown cell (a dirty mark): 1 draw the zone character, 2 draw the sprite character; FlushDirty `$A1F0` scans it from `$F5FF` down and writes back one less |
| Dissolve | a frame copied through a random AND mask to `$DF80` (`$A3A5`): the energy-out death, the warp, the materialisation, PENETRATOR |
| door warp | down on a lit password door in room 0, screen 5: state 10, then the room of WarpRooms `$BA1D` |
| foreground character | a zone character `$EA-$FF`; DrawObject never covers it, so objects pass behind it |
| IM 2 vector trick | the `$FF` table at `$FE00`, the `JR` at `$FFFF` that reads its offset from ROM `$0000`, and the `JP $9226` at `$FFF4` |
| LavaDrain | `$BA93`: 2 energy per head bump in zone 1 |
| level | a slot's byte +3: the power of its shot, from MaskLevels `$AF3B` |
| LIFTER | mask 6: a shot that lifts in one hit the kinds that test +`$22` (faller, flyer, walker, riser, wave, the shots), the guard after ten hits, never the turret, the chaser or the boss (kind 10), 8 charges a shot; door 3 gives one (WarpBonus `$BA21`) |
| live zone | the zone set at ZoneChars `$E000` / ZoneAttrs `$EF00` that the renderer reads |
| long jump | state 7, the JACKRABBIT's flight: up rises 4 a pass, a charge each 5 passes |
| MachineFlag | `$FFFE`, 0 on a 128K: the loader's answer, read by the interrupt |
| mask (sprite) | the frame grown by a pixel each way (MakeMask `$A777`, into MaskBuffer `$F000`); it clears the background around the picture |
| materialisation | states 11 and 12 at a new game: effect 9, then 50 passes of the dissolve |
| message line | row 23, columns 1-11, scrolled one pixel an interrupt by the Scroller `$AF82` |
| parked zone | a zone set waiting at `$5B00`, `$6400` or `$6D00`; SwapZone `$A198` exchanges it with the live one |
| pass | one run of the main loop `$CC03-$CC59`; 2.4 to 5.4 frames in the recordings |
| password door | one of four doors in room 0, screen 5, lit by a password typed at the menu |
| PENETRATOR | mask 1: held, Matt walks through walls and nothing touches him; ending it inside a wall kills (Explosion `$BB78`) |
| pod | the booth at a room's end that sends Matt to another room (Teleport `$B6B3`) |
| shift tables | ShiftTables `$F800-$FDFF`, three page pairs giving each byte shifted 2, 4 or 6 pixels and the bits pushed out |
| slot | one of Matt's four mask records at MaskSlots `$AF2B`: the HUD place, the kind, the BCD charges, the level |
| SlowPrint | `$BB13`: text typed one character every 4 frames with a flashing cursor (game over, the ending) |
| sprite character | one of the characters at `$E800` (attributes `$EE00`) DrawObject builds each pass from a cell's background and an object's frame |
| state | Matt's record byte +0 (`$A43F`), 1-12: walk, step up, step down, crouch, jump, fall, long jump, stand, no energy, door warp, materialise, its dissolve |
| touch pays | a bursting enemy's touch both hurts Matt and adds its score |
| v | Matt's vertical speed, record byte +`$11`: -9 at a jump's start, up to 8 in a fall |
| WarpRooms | `$BA1D`: `0B 03 07 07`, the room behind each password door |
| x unit | the unit of an object's x: 2 pixels; x AND 3 picks the shift (0, 2, 4 or 6 pixels) |
| zone | one of four character sets and colour schemes: 0 the surface, 1 the caverns, 2 the moon, 3 the base |
