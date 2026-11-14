# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, the tape at ROM speed, the menu and keyboard play), `work/stage1/rec/energy-out` (energy-out: 5001 frames of play from the RZX state after 47 000 frames), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a table jump or
by running on: L1 books its time to the routine it runs in) gives the runs of its first instruction, as its witness
line counts them.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`cells`](11-data-reference.md#cells) | `$60C0`-`$62FF` | 0 of 1 |
| [`start`](#start) | `$6300`-`$63D1` | 1 of 7 |
| [`messages`](11-data-reference.md#messages) | `$63D2`-`$65AD` | 0 of 1 |
| [`buffers`](11-data-reference.md#buffers) | `$65AE`-`$6887` | 0 of 11 |
| [`droidtables`](11-data-reference.md#droidtables) | `$6888`-`$68F2` | 0 of 9 |
| [`main`](#main) | `$68F3`-`$6ADB` | 10 of 10 |
| [`rooms`](#rooms) | `$6ADC`-`$7160` | 4 of 5 |
| [`input`](#input) | `$7161`-`$7207` | 1 of 1 |
| [`droid`](#droid) | `$7208`-`$7905` | 8 of 8 |
| [`hud`](#hud) | `$7906`-`$7B8E` | 12 of 12 |
| [`world`](#world) | `$7B8F`-`$7C57` | 4 of 4 |
| [`cellmath`](#cellmath) | `$7C58`-`$7DD9` | 13 of 13 |
| [`steps`](#steps) | `$7DDA`-`$7F4C` | 6 of 6 |
| [`sound`](#sound) | `$7F4D`-`$809C` | 6 of 6 |
| [`objects`](#objects) | `$809D`-`$8297` | 1 of 1 |
| [`weapons`](#weapons) | `$8298`-`$8853` | 4 of 5 |
| [`menu`](#menu) | `$8854`-`$8DD1` | 7 of 15 |
| [`exhaust`](#exhaust) | `$8DD2`-`$8F52` | 6 of 6 |
| [`progress`](#progress) | `$8F53`-`$90C7` | 3 of 4 |
| [`enemies`](#enemies) | `$90C8`-`$93A5` | 2 of 2 |
| [`patrollers`](#patrollers) | `$93A6`-`$9583` | 3 of 4 |
| [`interrupt`](#interrupt) | `$9584`-`$96FD` | 2 of 3 |
| [`bitreverse`](11-data-reference.md#bitreverse) | `$96FE`-`$9C3F` | 0 of 3 |
| [`sprites`](11-data-reference.md#sprites) | `$9C40`-`$BD05` | 0 of 10 |
| [`roomdata`](11-data-reference.md#roomdata) | `$BD06`-`$FDFF` | 0 of 8 |

## start

`src/game/start.asm`

### `Start` (`$6300`)

**The game's entry: JP Setup**

The stub at `$5B00` jumps here after the load (c1: L1 1).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 24 t-states own (0.00 %) |
| Calls | `Setup` (tail) |

## main

`src/game/main.asm`

### `Setup` (`$68F3`)

**Power-on setup: the stack, the keyboard, the IM 2 handler**

DI; SP = `$60C0` (the stack grows down under the cell table, in the BASIC area); Controls = `$80` (the keyboard); SetupIM2 `$9584`. Runs once (c1 L1 1).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 446,094 t-states own (0.04 %) |
| Called from | `Start` (tail) |
| Calls | `SetupIM2` |
| Writes | `$63C2` (`Controls`); `$6704`-`$6707` (`EnemyBufferPtrs`) |

### `Restart` (`$6900`)

**The menu, then a new game**

ClearScreen `$7A9F`, Menu `$8854` (1, 2, 3 choose the controls, 0 starts), NewGame `$7A2F`, the message TUJAD FROM ORPHEUS, EI, then MainLoop. Entered at the start and after a win (`$6A2D`) or a game over (`$6AAA`). L1 4 (c1 and the menu builds).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3 calls (`stage1/rec/game-over` 1, `stage1/rec/rzx-080000` 1, `stage1/rec/win` 1) |
| Called from | `WinTest` (tail), `LoseLife` (tail) |
| Calls | `QueueMessage`, `NewGame`, `ClearScreen`, `Menu` |
| Writes | `$6704`-`$6707` (`EnemyBufferPtrs`) |

### `MainLoop` (`$6911`)

**One pass of the game: two interrupts (three when the work overruns)**

WaitFrame (the sprites of the last half pass are drawn), PassTick `$7F6D` (a sound tick), DroidExhaust `$8DD2` (erase), MoveDroid `$7208`, ExhaustStep `$8E7E`, DroidExhaust (draw), HazardFlash `$699B`, MoveShot `$8298`; WaitFrame; MoveObject `$809D` for both objects; MoveEnemy `$90E7` for the four enemies, each with its pair of EnemyBuffers; MovePatrollers `$6AAD`; MoveShot again; Pause `$793A` (ENTER); EnergyOut `$6A30`; WinTest `$69E3`; again.

Witness: L1 18 585 passes. Most passes hold exactly two interrupts (the two HALTs); a pass whose work between the HALTs runs past the next interrupt misses it (the work runs with interrupts off) and waits for the one after, so it holds three. Counted by the interrupts inside it, a pass holds 2 (183 of 200 from rzx/at050000.szx) or 3 (17: one INT lost while the work ran with interrupts off); never 1. The "1-frame" passes of a count by frame number are passes that start before T 1812, where unreal-ng's 48K INT falls (doc 4.7).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 536 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,104,052 t-states own (0.60 %) |
| Runs (the other recordings) | 15,615 runs of its first instruction, entered by a jump (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Calls | `HazardFlash`, `WinTest`, `EnergyOut`, `MovePatrollers`, `MoveDroid`, `Pause`, `WaitFrame`, `PassTick`, `MoveObject`, `MoveShot`, `DroidExhaust`, `ExhaustStep`, `MoveEnemy` |
| Writes | `$6704`-`$6707` (`EnemyBufferPtrs`) |

### `HazardDeath` (`$6992`)

**A touched hazard: the life ends unless the droid is turning round**

Reached from MoveDroid's touch test (`$75E1`) when a cell under the droid has a mark other than an enemy's (a patroller or an object: bits 2-6). DroidFlags bit 1 (turning) protects; otherwise LoseLife. L1 53.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/rec/energy-out`; in the other recordings 53 calls (`stage1/rec/room-tour` 52, `stage1/rec/rzx-035000` 1) |
| Called from | `MoveDroid` (tail) |
| Calls | `LoseLife` (tail) |
| Reads | `$635B` (`DroidFlags`) |

### `HazardFlash` (`$699B`)

**While the shield is up: flash the droid's attributes and click the beeper**

Only while DroidFlags bit 4 (the shield, down held alone; the energy drains fast, EnergyReload 10) is set: fills the droid's 5 attribute rows with DeathColour (2-7, cycling) + BRIGHT (OR `$40`), toggling the beeper bit (port `$FE`) each row. L1 18 574 calls, 104 flashes.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 20,921 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 112,029 t-states own (0.03 %) |
| Runs (the other recordings) | 15,605 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MainLoop` |
| Calls | `ScreenAddr` |
| Reads | `$6359`-`$635D` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 1 more); `$6370`-`$6375` (`DeathColour`, `PatrollerTurn`, `EnergyReload`, `BorderSound`) |
| Writes | `$590F`-`$5911` (screen); `$592B`-`$5931` (screen); `$594B`-`$5951` (screen); `$596B`-`$5971` (screen); `$598B`-`$5991` (screen); `$59AB`-`$59D0` (screen); 9 more ranges |
| Ports out | `$00FE`, `$10FE` |

### `WinTest` (`$69E3`)

**Every ED piece taken: EDS COMPLETED; back in room `$54`: the end**

All ten EdFlags bytes `$1F` (L1 18 581 tests): the eleventh byte (EdFlagsEnd) is set to `$1F` once and the message EDS COMPLETED queued. Then in room `$54` (the control room, where the game starts): the attributes `$5885-$5889` (row 4, columns 5-9) set to 0, which hides the lives and energy digits, CONGRATULATIONS queued, EnergyTimer and ScrollPriority zeroed, a delay (WinDelay, BC = `$FDE8`), ProgressScreen with A = 0 (the whole picture), 512 HALTs (WinWait: B = 0, C = 2; about 10 s) and Restart. Witness: the RZX log (work/stage1/rzx/frames.bin) queues EDS COMPLETED at RZX frame 71 845 in room 28 (ScrollNext `$63E8`, priority 10), enters room 84 at 79 916 and runs WinTestRoom at 79 947 (ScrollNext `$64C7`, priority 20, EnergyTimer 0); the win recording starts inside WinWait (`$6A26`: 495 HALTs, then Restart, Menu at its frame 497). `$69FF-$6A25` ran only in the RZX playback, which no L1 build holds.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 33,776 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 225,795 t-states own (0.06 %) |
| Runs (the other recordings) | 15,612 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MainLoop` |
| Calls | `Restart` (tail), `QueueMessage` |
| Reads | `$6363` (`Room`); `$6681`-`$668B` (`EdFlags`, `EdFlagsEnd`); `$6A27` (`WinWait+1`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$668B` (`EdFlagsEnd`) |

### `EnergyOut` (`$6A30`)

**Energy 0 and not turning: a life lost**

L1 18 582 tests, 2 with energy 0 (energy-out).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 23,790 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 118,505 t-states own (0.03 %) |
| Runs (the other recordings) | 15,613 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MainLoop` |
| Reads | `$635B` (`DroidFlags`); `$636D`-`$636E` (`Lives`, `Energy`); `$6AA4` (`GameOverWait+1`) |
| Writes | `$5885`-`$5889` (screen); `$635B`-`$637F` (`DroidFlags`, `DroidFrame`, `DroidWidth`, `Shot` and 22 more); `$63CB` (`ScrollPriority`) |

### `LoseLife` (`$6A3C`)

**A life ends: the death effect, the droid placed again, or the game over**

Energy back to 99 and the timers to `$FA`; Lives - 1 (BCD); GEN 19 DESTROYED; DeathEffect `$7ADF`; SaveRoomObjects; PlaceDroid `$7A6D`; the shield down (DroidFlags bit 4 cleared) and the touch test back on (FlagPointer = DroidFlags); then, with lives left, the HUD's lives and energy printed (PrintBcd) and DrawRoom with A = `$FF` (a clear, no scroll). With Lives = `$99` (0 - 1 in BCD): the game over at LoseLifeGameOver. L1 55 lives lost (energy-out 2, game-over).

[Animation: `LoseLife` at work](img/routines/LoseLife.gif)

| | |
| --- | --- |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 53 calls (`stage1/rec/room-tour` 52, `stage1/rec/rzx-035000` 1) |
| Called from | `HazardDeath` (tail) |
| Calls | `Restart` (tail), `QueueMessage`, `SaveRoomObjects`, `DrawRoom`, `PlaceDroid`, `DeathEffect`, `PrintBcd`, `ProgressScreen` |
| Reads | `$635B` (`DroidFlags`); `$636D` (`Lives`) |
| Writes | `$635B`-`$637F` (`DroidFlags`, `DroidFrame`, `DroidWidth`, `Shot` and 22 more) |

### `MovePatrollers` (`$6AAD`)

**Move one of the three patrollers a pass**

PatrollerTurn cycles 0-2; PatrollerPtr = PatrollerPtrs[turn]; MovePatroller `$93A6`. L1 18 583.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 110,731 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 494,349 t-states own (0.14 %) |
| Runs (the other recordings) | 15,614 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MainLoop` |
| Calls | `MovePatroller` |
| Reads | `$6353`-`$6358` (`PatrollerPtrs`); `$6373` (`PatrollerTurn`) |
| Writes | `$6373` (`PatrollerTurn`); `$63A8`-`$63A9` (`PatrollerPtr`) |

### `QueueMessage` (`$6ACD`)

**Queue the message at HL when its priority is above the one shown**

In: HL a message (Messages). When (HL) > ScrollPriority: ScrollPriority = (HL), ScrollNext = HL + 1. L1 86 calls, 79 taken.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 78 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2 calls, 156 t-states own (0.00 %) |
| Runs (the other recordings) | 83 calls (`stage1/rec/room-tour` 54, `stage1/rec/rzx-052000` 4, `stage1/rec/game-over` 3 and 19 more) |
| Called from | `Restart`, `WinTest`, `LoseLife`, `MoveDroid`, `Teleport`, `EnergyTick` |
| Reads | `$63CB`-`$63D2` (`ScrollPriority`, `Messages`); `$63E7` (`MsgEdsCompleted`); `$6422` (`MsgEnergyLow`); `$6437` (`MsgEnergyAbsorbed`); `$645F` (`MsgTransporting`); `$6474` (`MsgWeaponStored`); 3 more ranges |
| Writes | `$63C9`-`$63CB` (`ScrollNext`, `ScrollPriority`) |

## rooms

`src/game/rooms.asm`

### `SaveRoomObjects` (`$6ADC`)

**Write the room's two object records back into its alien record**

Walks the room's record past the item and teleporter bytes (each 1 or 2 bytes, 0 = none) and the enemy mask, and copies Objects / Object2 (10 bytes each, Object1Flags bit 6 set) over the record's object fields when they are present. Called on every exit and teleport and on a life lost: L1 276.

[Animation: `SaveRoomObjects` at work](img/routines/SaveRoomObjects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 4 calls, 1,457 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1 call, 304 t-states own (0.00 %) |
| Runs (the other recordings) | 271 calls (`stage1/rec/room-tour` 117, `stage1/rec/rzx-065000` 12, `stage1/rec/rzx-074000` 11 and 44 more) |
| Called from | `LoseLife`, `MoveDroid`, `EdPickup`, `Teleport` |
| Reads | `$6327`-`$633A` (`Objects`, `Object1Flags`, `Object2`, `Object2Flags`); `$6363` (`Room`); `$DB53`-`$DFFF` (`AlienMap`, `AlienRecords`) |
| Writes | `$6328`-`$6332` (`Object1Flags`, `Object2`, `Object2Flags`); `$DC78`-`$DCC4` (`AlienRecords+37`); `$DD0F`-`$DD62` (`AlienRecords+188`); `$DD85`-`$DD8E` (`AlienRecords+306`); `$DDCF`-`$DDFF` (`AlienRecords+380`); `$DE37`-`$DE40` (`AlienRecords+484`); 4 more ranges |

### `DrawRoom` (`$6B22`)

**Enter the room: reset the movers, read the alien record, wipe and draw the room, build the cells**

In: A = 0 a scroll wipe (an exit), A not 0 a clear (a life lost, a teleport, a new game); Room. The sprite list is emptied; the patrollers marked not drawn; the four enemy records and the two objects zeroed. From the room's alien record (AlienMap + the word at AlienMap + 2 x Room): Item1Pos / Item1Kind, Item2Pos / Item2Kind, TeleportPos / TeleportRoom; the enemy mask (bit k: enemy k waits to spawn, timer 1 or 2, state `$40`, BlankGraphic); the two object records copied into Objects. The play area's attributes keep BRIGHT and INK (AND `$47`: paper and FLASH cleared); then the wipe: DrawRoomScroll shifts every line of the play area one pixel out, odd lines left and even lines right, eight times with a delay (L1 171 scrolls), or ClearPlayArea `$7917` (110). The attributes are zeroed, then the layout (RoomLayouts + RoomLayouts[2 x Room]) is drawn tile by tile: (column, row, tile) triples until a column byte with bit 7. Each tile's pixels come from TileGraphics[tile] (width, height, rows) and its colours from TileAttrs[tile] (a fill byte with bit 7, or one attribute a cell), all clipped to the play area. Then the cell table (1 where the attribute is not 0), the items (ItemCell `$6E88`, DrawItem `$6E0D` for a kind with bit 7) and the teleporter (`$FF` `$FF`, TeleportColumn / TeleportRow). Shot = 0; DI.

Witness: L1 279 rooms drawn; 6 458 tiles; the attributes' loop 161 103 cells.

[Animation: `DrawRoom` at work](img/routines/DrawRoom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 5 calls, 6,911,417 t-states own (0.62 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1 call, 565,606 t-states own (0.16 %) |
| Runs (the other recordings) | 273 calls (`stage1/rec/room-tour` 117, `stage1/rec/rzx-065000` 12, `stage1/rec/rzx-074000` 11 and 44 more) |
| Called from | `LoseLife`, `MoveDroid`, `EdPickup`, `Teleport`, `NewGame` |
| Calls | `DrawItem`, `ItemCell`, `ClearPlayArea` |
| Reads | `$40C0`-`$57FF` (screen); `$58C0`-`$5AFF` (screen); `$633B`-`$634B` (`Patrollers`, `Patroller2`, `Patroller3`); `$6363` (`Room`); `$639C`-`$63A0` (`RoomVars`, `Item2Pos`, `Item1Kind`, `Item2Kind` and 1 more); `$63B1`-`$63B7` (`DrawMode`, `RoomRecordPtr`, `RoomEnemyPtr`, `TileAttrPtr`); 11 more ranges |
| Writes | `$40C0`-`$57FF` (screen); `$58C0`-`$5AFF` (screen); `$60C0`-`$635E` (`CellTable`, `Start`, `Enemies`, `Objects` and 2 more); `$639C`-`$63B7` (`RoomVars`, `Item2Pos`, `Item1Kind`, `Item2Kind` and 12 more); `$63D0`-`$63D1` (`SpriteListEnd`); `$FF01`-`$FF02` (`work space $FF01+`) |

### `DrawItem` (`$6E0D`)

**Put an item on its 2 x 2 cells and draw it**

In: HL its cell (ItemCell), A its kind. The kind goes into the four cells; the graphic and attribute by the kind: `$80` GEN 19 (`$8CD5`, `$45`), `$81` an energy source (`$8D15`, `$42`), `$C1-$C3` a weapon (HudIcons + 32 x n, WeaponColours), `$82-$B3` an ED piece (piece n = kind - `$81` is the EdPieces tile at column (n - 1) / 5, row (n - 1) % 5 of the 10 x 5 picture: DrawItemEdColumn adds 32 for each 5 in n, DrawItemEdRow 320 for the rest; colour `$67`); Blit16 `$8A93` draws the 16 x 16 pixels; the four attributes. L1 141.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 896 t-states own (0.00 %) |
| Runs (the other recordings) | 140 calls (`stage1/rec/room-tour` 76, `stage1/rec/rzx-052000` 7, `stage1/rec/rzx-065000` 5 and 26 more) |
| Called from | `DrawRoom` |
| Calls | `Blit16` |
| Reads | `$65DA`-`$65DC` (`WeaponColours`) |
| Writes | `$5964`-`$5A15` (screen); `$5A2A`-`$5A35` (screen); `$5A4E`-`$5A4F` (screen); `$5A6A`-`$5AC9` (screen); `$6164`-`$6215` (`CellTable+164`); `$622A`-`$6235` (`CellTable+362`); 2 more ranges |

### `ItemCell` (`$6E88`)

**The cell of a position byte: HL + 32 x (A AND `$0F`) + 2 x (A >> 4)**

In: HL the base (CellTable, or CellTable + 64 for the teleporter), A the position byte (low nibble the row, high nibble the column / 2). Out: HL. L1 321.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 4 calls, 2,696 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1 call, 495 t-states own (0.00 %) |
| Runs (the other recordings) | 316 calls (`stage1/rec/room-tour` 93, `stage1/rec/rzx-052000` 14, `stage1/rec/rzx-037000` 14 and 44 more) |
| Called from | `DrawRoom`, `MoveDroid` |

## input

`src/game/input.asm`

### `ReadControls` (`$7161`)

**Read the keyboard, the cursor keys or the Kempston joystick into Controls**

Called by the interrupt handler every frame (L1 54 811). Clears bits 0-4 of Controls and sets them from the method in bits 7-6: Kempston (0): IN (`$1F`) AND `$1F` (L1 47 334); the keyboard (`$80`): on the bottom row Z C M B left and X V N SYMBOL SHIFT right (every other key), A-G and H-L down, Q-T and Y-P up, 1-5 and 6-0 fire (2 138); the cursor keys (`$40`): 5 left, 6 down, 7 up, 8 right, 0 fire (5 339). Bit 0 right, 1 left, 2 down, 3 up, 4 fire.

[Animation: `ReadControls` at work](img/routines/ReadControls.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,371 calls, 597,371 t-states own (0.05 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,880 calls, 517,280 t-states own (0.15 %) |
| Runs (the other recordings) | 48,560 calls (`stage1/rec/room-tour` 4,265, `stage1/rec/rzx-065000` 3,491, `stage1/rec/rzx-070000` 2,690 and 65 more) |
| Called from | `Interrupt` |
| Reads | `$63C2` (`Controls`) |
| Writes | `$63C2` (`Controls`) |
| Ports in | `$001F`, `$7FFE`, `$BFFE`, `$DBFE`, `$E7FE`, `$EFFE`, `$F7FE`, `$FDFE`, `$FEFE` |

## droid

`src/game/droid.asm`

### `MoveDroid` (`$7208`)

**One step of the droid: the teleporter, the fall, the controls, the exits, the sprites, the touch test, the pickups**

On the floor it acts every second pass (MoveDelay reloads 2); in the air (DroidFlags bit 2: no wall under the feet; the droid hovers and moves vertically only with up or down) every pass (L1 6 522 waits). A droid on a teleporter's `$FF` `$FF` cells with TeleportLatch 0 teleports (MoveDroidTeleport: L1 8 teleports). The cell under its feet (the cell 5 rows below, `$A0` on) decides a fall: when it and the next one or two are not walls the droid is in the air (bit 2), else it stands (L1 15 289). The old image goes to the sprite list (DroidSave, flag pointer 0). Then, unless it is turning round (bit 1: TurnRound `$7866`), fire calls Fire `$861C`, and the directions move it: right (bit 0) and left (bit 1) a column a few frames apart through the walk frames 0-7 (DroidFrame 3, 4, 7, 8 step the x; StepBlockedLeft `$76A1` / StepBlockedRight `$76D1` undo a step into a wall); up and down two pixel rows (bit 3 up, bit 2 down, CellBlockedRow `$7CF2` tests the wall). A direction against the facing starts the turn-round (frame 8). Down held alone while standing raises the shield (DroidFlags bit 4, FlagPointer `$0000` so the touch test sees nothing, EnergyReload and EnergyTimer `$0A`); no control or another one lowers it (FlagPointer = DroidFlags again, the reload 250). The exits: x = `$1D` east (Room + 1, x = 0: L1 87), x = 0 west (Room - 1, x = `$1D`: 32), y = `$98` south (Room + 8, y = `$32`: 26), y = `$30` north (Room - 8, y = `$96`: 26); each saves the objects and calls DrawRoom with A = 0. Then the new frame (DroidFrames, DroidWidths) goes to the sprite list with FlagPointer, and the attributes under it are set to `$45` where the cell is not a wall and holds no item. The touch test: when the interrupt found the droid's sprite on ink (bit 7 of DroidFlags), the cells under it are ORed (OrCells `$7DAE` into TouchBits): an enemy (bit 1) starts the fast drain (EnergyReload `$0A`, TouchTimer 50: L1 222); any other mark kills (HazardDeath: 309 tests reach it). Last the item test (FoundItem).

Witness: L1 18 557 calls.

[Animation: `MoveDroid` at work](img/routines/MoveDroid.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 3,624,607 t-states own (0.33 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 12,670,604 t-states own (3.63 %) |
| Runs (the other recordings) | 15,588 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MainLoop`, `TurnRound` (tail) |
| Calls | `HazardDeath` (tail), `QueueMessage`, `SaveRoomObjects`, `DrawRoom`, `ItemCell`, `StepBlockedLeft`, `StepBlockedRight`, `EdPickup` (tail), `Teleport` (tail), `PickupErase`, `TurnRound` (tail), `ShowWeapon`, `PrintBcd`, `CellToScreen`, `ScreenAddr`, `CellAddr`, `CellBlockedRow`, `OrCells`, `Fire` |
| Reads | `$6000`-`$600B` (system); `$601C`-`$602B` (system); `$603C`-`$604B` (system); `$605C`-`$606B` (system); `$607C`-`$608B` (system); `$609C`-`$62FC` (`CellTable`); 29 more ranges |
| Writes | `$5800`-`$580B` (screen); `$581C`-`$582B` (screen); `$583C`-`$584B` (screen); `$585C`-`$586B` (screen); `$587C`-`$588B` (screen); `$589D` (screen); 31 more ranges |

### `StepBlockedLeft` (`$76A1`)

**Undo a step left into a wall**

In: HL DroidX after the step. When the column left of the droid holds a wall over its 5 rows (CellBlockedColumn `$7CBB`), x goes back and the frame back one (L1 1 426 tests, 246 undone).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 19 calls, 5,214 t-states own (0.00 %) |
| Runs (the other recordings) | 1,407 calls (`stage1/rec/rzx-074000` 239, `stage1/rec/rzx-065000` 191, `stage1/rec/rzx-070000` 184 and 35 more) |
| Called from | `MoveDroid` |
| Calls | `CellAddr`, `CellBlockedColumn` |
| Reads | `$6359`-`$635C` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame`) |
| Writes | `$6359`-`$635C` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame`) |

### `StepBlockedRight` (`$76D1`)

**Undo a step right into a wall**

The same on the right, the column x + 2 (L1 1 742 tests, 373 undone).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 56 calls, 18,098 t-states own (0.00 %) |
| Runs (the other recordings) | 1,686 calls (`stage1/rec/room-tour` 312, `stage1/rec/rzx-063000` 93, `stage1/rec/menu-cursor` 87 and 41 more) |
| Called from | `MoveDroid` |
| Calls | `CellAddr`, `CellBlockedColumn` |
| Reads | `$6359`-`$635C` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame`) |
| Writes | `$6359`-`$635C` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame`) |

### `EdPickup` (`$7703`)

**An ED piece taken: the progress screen, then the room again**

In: A the item's kind (`$82-$B3`). ProgressScreen `$8F53` with A = the piece number (it sets the piece's EdFlags bit and shows the picture), DroidGraphic = BlankGraphic, SaveRoomObjects, DrawRoom with A = `$FF`. L1 35 pieces (the win recording holds the last).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 157 t-states own (0.00 %) |
| Runs (the other recordings) | 34 calls (`stage1/rec/rzx-065000` 4, `stage1/rec/rzx-037000` 3, `stage1/rec/rzx-010000` 2 and 19 more) |
| Called from | `MoveDroid` (tail) |
| Calls | `SaveRoomObjects`, `DrawRoom`, `ProgressScreen` |
| Writes | `$6378`-`$6379` (`DroidGraphic`) |

### `Teleport` (`$7719`)

**Through the teleporter: the beam, TRANSPORTING, the target room**

The droid's image is replaced by the beam frame (`$A0A0`, frame 10) in the sprite list, one HALT; TRANSPORTING; BeamDown `$7F9C` (a falling tone), TeleportFlash `$8051`; SaveRoomObjects; Room = TeleportRoom; DrawRoom; BeamDown with a rising start; the droid placed at TeleportColumn + 1, TeleportRow, the beam frame with attribute `$45`; BeamUp `$8005`; TeleportLatch = `$FF` so it does not teleport straight back. L1 8.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/rec/energy-out`; in the other recordings 8 calls (`stage1/rec/rzx-052000` 1, `stage1/rec/rzx-030000` 1, `stage1/rec/rzx-041000` 1 and 5 more) |
| Called from | `MoveDroid` (tail) |
| Calls | `QueueMessage`, `SaveRoomObjects`, `DrawRoom`, `ScreenAddr`, `FillAttr`, `BeamDown`, `BeamUp`, `TeleportFlash` |
| Reads | `$6359`-`$635D` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 1 more); `$6378`-`$6379` (`DroidGraphic`); `$63A1`-`$63A3` (`TeleportRoom`, `TeleportColumn`, `TeleportRow`); `$63D0`-`$63D1` (`SpriteListEnd`); `$7780` (`Teleport+103`); `$7819` (`TeleportArrive+12`) |
| Writes | `$6359`-`$6363` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 5 more); `$6376`-`$6379` (`TeleportLatch`, `TouchTimer`, `DroidGraphic`); `$63C5`-`$63D1` (`BeamScreen`, `ScrollText`, `ScrollNext`, `ScrollPriority` and 4 more); `$FF01`-`$FF12` (`work space $FF01+`) |

### `PickupErase` (`$7837`)

**Erase a taken item: the tone, then its 16 pixel rows**

In: DE the item's screen address. PickupTone, then 16 rows of two zero bytes. L1 50.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 1,185 t-states own (0.00 %) |
| Runs (the other recordings) | 49 calls (`stage1/rec/rzx-065000` 4, `stage1/rec/rzx-052000` 4, `stage1/rec/rzx-002000` 4 and 24 more) |
| Called from | `MoveDroid` |
| Calls | `PickupTone` |
| Writes | `$4864`-`$57C9` (screen) |

### `PickupTone` (`$7856`)

**The pickup's tone: 256 beeper toggles `$21` loops apart**

L1 50 (12 859 toggles counted: one build stopped mid-tone).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 154,882 t-states own (0.01 %) |
| Runs (the other recordings) | 49 calls (`stage1/rec/rzx-065000` 4, `stage1/rec/rzx-052000` 4, `stage1/rec/rzx-002000` 4 and 24 more) |
| Called from | `PickupErase` |
| Writes | `$6359`-`$6363` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 5 more) |
| Ports out | `$00FE`, `$10FE` |

### `TurnRound` (`$7866`)

**One step of the turn-round: the next frame, and part of the droid's graphics mirrored in place**

TurnStep walks TurnSequence (8, 9, 10, 9, 8). At frame 10 (the droid seen from the front) the 2-byte front frames (`$9C40` on, TurnGraphic) are mirrored 80 rows a step (TurnMirror2); at the other steps the 3-byte frames 160 rows a step (TurnMirror3): each row's bytes are swapped and bit-reversed through BitReverse `$9A4C`, so after the turn every walk frame faces the other way. At the `$FF` end the facing bit flips, the turn bit clears, and the frame is 8 (moving) or 11 (falling). L1 538 steps, 90 turns.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 18 calls, 517,159 t-states own (0.05 %) |
| Runs (the other recordings) | 520 calls (`stage1/rec/rzx-065000` 54, `stage1/rec/rzx-019000` 36, `stage1/rec/rzx-048000` 30 and 35 more) |
| Called from | `MoveDroid` (tail) |
| Calls | `MoveDroid` (tail) |
| Reads | `$635B` (`DroidFlags`); `$637A`-`$637D` (`TurnGraphic`, `TurnStep`); `$68B2`-`$68B7` (`TurnSequence`); `$9A4C`-`$9B4A` (`BitReverse`); `$9C40`-`$A09F` (`DroidGraphics`, `DroidWalk1`, `DroidWalk2`, `DroidWalk3` and 6 more); `$A0F0`-`$A4AF` (`DroidFly1`, `DroidMirrorSpare`) |
| Writes | `$635B`-`$635C` (`DroidFlags`, `DroidFrame`); `$637A`-`$637D` (`TurnGraphic`, `TurnStep`); `$9C40`-`$A09F` (`DroidGraphics`, `DroidWalk1`, `DroidWalk2`, `DroidWalk3` and 6 more); `$A0F0`-`$A4AF` (`DroidFly1`, `DroidMirrorSpare`) |

## hud

`src/game/hud.asm`

### `DrainTimer` (`$7906`)

**Count down the fast drain after an enemy's touch**

Every interrupt: while TouchTimer is not 0 it counts down; at 0 EnergyReload and EnergyTimer go back to `$FA` (one energy step every 250 interrupts, 5 s). L1 54 825 calls, 49 ends.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,371 calls, 57,689 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,880 calls, 180,671 t-states own (0.05 %) |
| Runs (the other recordings) | 48,574 calls (`stage1/rec/room-tour` 4,265, `stage1/rec/rzx-065000` 3,491, `stage1/rec/rzx-070000` 2,690 and 65 more) |
| Called from | `Interrupt` |
| Reads | `$6377` (`TouchTimer`) |
| Writes | `$6366`-`$6377` (`EnergyTimer`, `EnemyKindTurn`, `Weapons`, `KeyLatches` and 10 more) |

### `ClearPlayArea` (`$7917`)

**Clear the play area's pixels (screen rows 6-23)**

`$90` lines of 32 bytes from `$40C0`. Callers: DrawRoom with A not 0, the menu, ProgressScreen. L1 146.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 3 calls, 518,068 t-states own (0.05 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1 call, 177,446 t-states own (0.05 %) |
| Runs (the other recordings) | 142 calls (`stage1/rec/room-tour` 52, `stage1/rec/rzx-065000` 8, `stage1/rec/rzx-037000` 7 and 31 more) |
| Called from | `DrawRoom`, `ProgressScreen` |
| Writes | `$40C0`-`$57FF` (screen) |

### `Pause` (`$793A`)

**ENTER pauses and resumes**

ENTER pressed after a release (KeyLatches bit 1) toggles Controls bit 5; the routine loops while bit 5 is set. MainLoop calls it after WaitFrame's DI and PauseLoop never enables interrupts, so while paused no interrupt is taken: no sprite is drawn, the scroller stops and EnergyTick does not count. Witness: c1, ENTER held at 15240-15250 and 15350-15360 (exec `$7949`); no exec of Interrupt `$95D0` or EnergyTick `$7AB6` in 15241-15359; EnergyTimer `$64` and Energy `$97` at the start of 15241, 15300 and 15359. L1 18 582 calls, 2 toggles (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 8,409,969 t-states own (0.76 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 314,170 t-states own (0.09 %) |
| Runs (the other recordings) | 15,613 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MainLoop` |
| Reads | `$6369` (`KeyLatches`); `$63C2` (`Controls`) |
| Writes | `$6369` (`KeyLatches`); `$63C2` (`Controls`) |
| Ports in | `$BFFE` |

### `WaitFrame` (`$795D`)

**End the sprite list, wait for the interrupt to draw it, start a new list**

Writes the zero word at SpriteListEnd, sets SpriteListEnd = SpriteList, EI, NOP, HALT; the interrupt XORs every queued sprite; DI; SpriteListEnd = SpriteList. MainLoop calls it twice a pass (L1 37 159 calls).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,071 calls, 34,132,217 t-states own (3.08 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,868 calls, 183,553,794 t-states own (52.53 %) |
| Runs (the other recordings) | 31,220 calls (`stage1/rec/rzx-065000` 2,450, `stage1/rec/rzx-070000` 2,268, `stage1/rec/rzx-074000` 1,814 and 63 more) |
| Called from | `MainLoop` |
| Reads | `$63D0`-`$63D1` (`SpriteListEnd`); `$796E` (`WaitFrame+17`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$6359`-`$636E` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 13 more); `$63D0`-`$63D1` (`SpriteListEnd`); `$FF01`-`$FF42` (`work space $FF01+`) |

### `WeaponSelect` (`$7976`)

**SPACE: the next weapon with ammunition**

Every interrupt while no shot is in flight. SPACE (`$7EFE` bit 0) pressed after a release (KeyLatches bit 0): Weapons shifts right to the next weapon whose Ammo is not 0, past weapon 3 back to weapon 0 (`$80`), and ShowWeapon. L1 54 824 calls, 47 changes.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,371 calls, 175,640 t-states own (0.02 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,880 calls, 552,589 t-states own (0.16 %) |
| Runs (the other recordings) | 48,573 calls (`stage1/rec/room-tour` 4,265, `stage1/rec/rzx-065000` 3,491, `stage1/rec/rzx-070000` 2,690 and 65 more) |
| Called from | `Interrupt` |
| Calls | `ShowWeapon` |
| Reads | `$635E`-`$636C` (`Shot`, `ShotPos`, `ShotGraphic`, `Room` and 6 more) |
| Writes | `$6368`-`$6369` (`Weapons`, `KeyLatches`) |
| Ports in | `$7EFE` |

### `ShowWeapon` (`$79C2`)

**The weapon's icon and ammunition on the HUD**

The 16 x 16 icon (HudIcons + 32 x weapon, Blit16 at `$4422`) with its colour (`$47`, `$43`, `$44`, `$46`) on 2 x 4 cells, then the ammunition at `$4082` (PrintBcd) or, for weapon 0, two blank characters. L1 58.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 468 t-states own (0.00 %) |
| Runs (the other recordings) | 57 calls (`stage1/rec/rzx-070000` 13, `stage1/rec/rzx-065000` 9, `stage1/rec/rzx-052000` 7 and 15 more) |
| Called from | `MoveDroid`, `WeaponSelect` |
| Calls | `PrintBcd`, `Print8`, `Blit16` |
| Reads | `$6368`-`$636C` (`Weapons`, `KeyLatches`, `Ammo`) |
| Writes | `$5822`-`$5823` (screen); `$5842`-`$5843` (screen); `$5862`-`$5863` (screen); `$5882`-`$5883` (screen) |

### `NewGame` (`$7A2F`)

**A new game: the rooms dealt, the work space reset, room `$54`**

ClearScreen; InitRooms `$7BCC` (every item present, the objects reset); ScrambleRooms an odd number of times, 1 to 31 (Random OR 1 AND `$1F`: 16 possible counts; each call rotates the 64 non-weapon item kinds one slot along the rooms: 16 possible deals for the first game after loading; InitRooms does not undo the rotation, so a later game rotates on); ExhaustRows to EdFlagsEnd zeroed; Room = `$54` (the control room); PlaceDroid; InitialVars copied; DrawHud `$8AE8`; DrawRoom with A = `$FF`. L1 4 new games, 34 scrambles.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 6,835 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/game-over` 1, `stage1/rec/menu-cursor` 1, `stage1/rec/menu-kempston` 1) |
| Called from | `Restart` |
| Calls | `DrawRoom`, `PlaceDroid`, `ClearScreen`, `ScrambleRooms`, `InitRooms`, `Random`, `DrawHud` |
| Reads | `$6380`-`$639B` (`InitialVars`); `$65E5`-`$668A` (`ExhaustRows`, `BlankGraphic`, `EdFlags`) |
| Writes | `$6363`-`$637F` (`Room`, `ControlsLatch`, `EnergyTimer`, `EnemyKindTurn` and 16 more); `$65E5`-`$668B` (`ExhaustRows`, `BlankGraphic`, `EdFlags`) |

### `PlaceDroid` (`$7A6D`)

**Put the droid at the room's start position**

DroidFlags `$40` (facing right) or `$41` when the droid graphics are mirrored (byte 4 of DroidGraphics is not `$70`); x and y from StartPositions + 2 x Room; frame 8, width 2; Shot = 0. L1 59 (4 new games, 55 lives).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 367 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1 call, 335 t-states own (0.00 %) |
| Runs (the other recordings) | 57 calls (`stage1/rec/room-tour` 52, `stage1/rec/game-over` 2, `stage1/rec/rzx-035000` 1 and 2 more) |
| Called from | `LoseLife`, `NewGame` |
| Reads | `$6363` (`Room`); `$9484`-`$9579` (`StartPositions`); `$9C44` (`DroidGraphics+4`) |
| Writes | `$6359`-`$635E` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 2 more) |

### `ClearScreen` (`$7A9F`)

**Clear the pixels, the attributes to 7 (white ink on black)**

L1 8.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 2 calls, 371,813 t-states own (0.03 %) |
| Runs (the other recordings) | 6 calls (`stage1/rec/game-over` 2, `stage1/rec/rzx-080000` 1, `stage1/rec/win` 1 and 2 more) |
| Called from | `Restart`, `NewGame` |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |

### `EnergyTick` (`$7AB6`)

**Count the energy down one every EnergyTimer interrupts**

Every interrupt (L1 54 825). When EnergyTimer reaches 0 it reloads from EnergyReload (`$FA`: 5 s a step; `$0A` under the shield, 0.2 s; after an enemy's touch each touching pass sets EnergyTimer back to 10, so the 5 fast steps come 10-50 interrupts after the last touch), Energy - 1 (BCD) printed at `$4088`; at 11 the message WARNING ENERGY LOW. EnergyTimer 0 stops it (the win and the game over set it to 0). L1 378 steps.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,371 calls, 88,719 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,880 calls, 325,834 t-states own (0.09 %) |
| Runs (the other recordings) | 48,574 calls (`stage1/rec/room-tour` 4,265, `stage1/rec/rzx-065000` 3,491, `stage1/rec/rzx-070000` 2,690 and 65 more) |
| Called from | `Interrupt` |
| Calls | `QueueMessage`, `PrintBcd` |
| Reads | `$6366`-`$6374` (`EnergyTimer`, `EnemyKindTurn`, `Weapons`, `KeyLatches` and 7 more) |
| Writes | `$6366`-`$636E` (`EnergyTimer`, `EnemyKindTurn`, `Weapons`, `KeyLatches` and 3 more) |

### `DeathEffect` (`$7ADF`)

**The droid shaken apart: its image shifted out a pixel a line, eight times, with a falling sweep**

KeyLatches bit 7 (no fire) while it runs. The droid's image lines are shifted right and left alternately (as DrawRoom's wipe) 8 times, each with FallSweep `$7F5D`. DroidGraphic = BlankGraphic. L1 55.

| | |
| --- | --- |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1 call, 84,522 t-states own (0.02 %) |
| Runs (the other recordings) | 54 calls (`stage1/rec/room-tour` 52, `stage1/rec/rzx-035000` 1, `stage1/rec/game-over` 1) |
| Called from | `LoseLife` |
| Calls | `ScreenAddr`, `FallSweep` |
| Reads | `$401C`-`$40E7` (screen); `$40FA`-`$40FD` (screen); `$411C`-`$41E7` (screen); `$41FA`-`$41FD` (screen); `$421C`-`$42FD` (screen); `$431C`-`$43FD` (screen); 9 more ranges |
| Writes | `$401C`-`$40E7` (screen); `$40FA`-`$40FD` (screen); `$411C`-`$41E7` (screen); `$41FA`-`$41FD` (screen); `$421C`-`$42FD` (screen); `$431C`-`$43FD` (screen); 9 more ranges |

### `PrintBcd` (`$7B3F`)

**Print a BCD byte as two digits, after one click**

In: A the byte, HL the screen address. A leading 0 is a space (ROM font `$3D00`); the digits come from Font (Font - `$100` + 8 x code). Before the first digit only, a click of 50 passes (OUT, XOR `$10`, OUT: 50 speaker edges 42 T apart, 41.7 kHz, 2100 T); the second digit has none. Print8 `$8A79` prints. L1 549.

[Animation: `PrintBcd` at work](img/routines/PrintBcd.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 8 calls, 25,937 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 58 calls, 163,321 t-states own (0.05 %) |
| Runs (the other recordings) | 483 calls (`stage1/rec/room-tour` 112, `stage1/rec/rzx-070000` 43, `stage1/rec/rzx-074000` 38 and 46 more) |
| Called from | `LoseLife`, `MoveDroid`, `ShowWeapon`, `EnergyTick`, `Fire`, `DrawHud` |
| Calls | `Print8` |
| Ports out | `$00FE`, `$10FE` |

## world

`src/game/world.asm`

### `RoomRecord` (`$7B8F`)

**HL = the alien record of room C**

AlienMap + the word at AlienMap + 2 x C (the authors' lookup). L1 4 746.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 749 calls, 81,165 t-states own (0.01 %) |
| Runs (the other recordings) | 3,997 calls (`stage1/rec/menu-cursor` 2,499, `stage1/rec/game-over` 1,249, `stage1/rec/menu-kempston` 249) |
| Called from | `ScrambleRooms`, `InitRooms` |
| Reads | `$DB53`-`$DC4A` (`AlienMap`) |

### `ScrambleRooms` (`$7BA0`)

**Move the non-weapon items one step round the rooms**

B = the item of room `$7B`; then for rooms 0-`$7B` in turn, each present item whose kind has bit 6 clear (GEN 19, energy, an ED piece; not a weapon) swaps with B. Each call moves every such item to the next room that holds one: NewGame calls it an odd number of times, 1-31 (Random OR 1 AND `$1F`), so the pieces' rooms change from game to game. Room 123 has only item 1, the last non-weapon slot, so each call rotates the 64 non-weapon kinds by exactly one slot; the 16 odd counts give 16 possible deals for the first game after loading. InitRooms does not undo the rotation, so a later game turns on from the last deal. The RZX game: 27 (at001000.szx against the image). The authors' scram. L1 34 calls.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 5 calls, 91,515 t-states own (0.01 %) |
| Runs (the other recordings) | 29 calls (`stage1/rec/menu-cursor` 19, `stage1/rec/game-over` 9, `stage1/rec/menu-kempston` 1) |
| Called from | `NewGame` |
| Calls | `RoomRecord` |
| Reads | `$DC53`-`$DECE` (`AlienRecords`); `$DEE5`-`$DFFB` (`AlienRecords+658`, `EmptyAlienRecord`) |
| Writes | `$DC5B`-`$DCEF` (`AlienRecords+8`); `$DD1B`-`$DD22` (`AlienRecords+200`); `$DD3F`-`$DD46` (`AlienRecords+236`); `$DD6B`-`$DE09` (`AlienRecords+280`); `$DE33`-`$DEBE` (`AlienRecords+480`); `$DEE6`-`$DEF4` (`AlienRecords+659`); 2 more ranges |

### `InitRooms` (`$7BCC`)

**Every item present again, every object reset**

Rooms 0-`$7B`: bit 7 set on both item kinds; for each object record: the direction kept (AND 3) and bit 6 set, the graphic, width and kill mark from ObjectKind, the frame 0. L1 4.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 29,883 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/game-over` 1, `stage1/rec/menu-kempston` 1, `stage1/rec/menu-cursor` 1) |
| Called from | `NewGame` |
| Calls | `RoomRecord`, `ObjectKind` |
| Reads | `$DC53`-`$DFFE` (`AlienRecords`, `EmptyAlienRecord`) |
| Writes | `$DC54`-`$DCC3` (`AlienRecords+1`); `$DCD4`-`$DCFD` (`AlienRecords+129`); `$DD10`-`$DEF4` (`AlienRecords+189`); `$DF0C`-`$DFF4` (`AlienRecords+697`) |

### `ObjectKind` (`$7C28`)

**An object's graphic, width and the weapon mark it dies to, by its kind bits**

In: B the kind (the record's first byte, bits 4-7). Bit 4: `$B049`, 3 frames, `$40` (it dies to weapon 1's mark); bit 5: `$B16C`, 4 frames, `$20` (weapon 2); bit 6: `$B2F0`, 3, `$10` (weapon 3); bit 7: `$B413`, 4, `$20`; none: `$B597`, 3, `$10`. Out: DE the graphic (frames of 97 bytes: the shift byte, 24 rows of 4), C the frames, A the mark. L1 100.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 25 calls, 3,526 t-states own (0.00 %) |
| Runs (the other recordings) | 75 calls (`stage1/rec/menu-cursor` 25, `stage1/rec/game-over` 25, `stage1/rec/menu-kempston` 25) |
| Called from | `InitRooms` |

## cellmath

`src/game/cellmath.asm`

### `CellToScreen` (`$7C58`)

**The screen address of a cell: DE from HL in the cell table**

L1 50.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 61 t-states own (0.00 %) |
| Runs (the other recordings) | 49 calls (`stage1/rec/rzx-065000` 4, `stage1/rec/rzx-052000` 4, `stage1/rec/rzx-002000` 4 and 24 more) |
| Called from | `MoveDroid` |

### `ScreenAddrXY` (`$7C66`)

**The screen address of pixel (C, B): DE**

In: B the pixel row, C the pixel x (C / 8 the column). L1 34 302.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 676 calls, 84,286 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,579 calls, 290,562 t-states own (0.08 %) |
| Runs (the other recordings) | 31,047 calls (`stage1/rec/rzx-065000` 3,076, `stage1/rec/rzx-070000` 2,970, `stage1/rec/rzx-074000` 2,348 and 61 more) |
| Called from | `MoveObject`, `MoveShot`, `MoveShotStraight`, `MoveShot0`, `MoveEnemy` |

### `ScreenAddr` (`$7C7E`)

**The screen address of pixel row B, column C: DE**

L1 68 943.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,952 calls, 230,840 t-states own (0.02 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 8,071 calls, 968,267 t-states own (0.28 %) |
| Runs (the other recordings) | 58,920 calls (`stage1/rec/rzx-065000` 4,662, `stage1/rec/rzx-070000` 4,248, `stage1/rec/rzx-074000` 3,510 and 63 more) |
| Called from | `HazardFlash`, `MoveDroid`, `Teleport`, `DeathEffect`, `BeamDown`, `BeamUp`, `TeleportFlash`, `DroidExhaust`, `DrawPatroller` |

### `CellAddrXY` (`$7C94`)

**The cell of pixel row B, pixel x C: HL**

L1 36 761.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 805 calls, 98,244 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 3,316 calls, 346,270 t-states own (0.10 %) |
| Runs (the other recordings) | 32,640 calls (`stage1/rec/rzx-070000` 3,519, `stage1/rec/rzx-065000` 3,375, `stage1/rec/rzx-074000` 2,062 and 61 more) |
| Called from | `StepRight`, `StepDown`, `StepLeft`, `StepUp`, `MoveObject`, `MoveShot`, `MoveShotStraight`, `Fire`, `MoveShot0`, `MoveEnemy` |

### `CellAddr` (`$7CAA`)

**The cell of pixel row B, column C: HL**

CellTable rows from `$6000`: `$6000` + 32 x (B / 8) + C. L1 35 926.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 963 calls, 85,728 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 3,202 calls, 277,598 t-states own (0.08 %) |
| Runs (the other recordings) | 31,761 calls (`stage1/rec/rzx-065000` 2,541, `stage1/rec/rzx-070000` 2,308, `stage1/rec/rzx-074000` 2,001 and 63 more) |
| Called from | `MoveDroid`, `StepBlockedLeft`, `StepBlockedRight`, `DrawPatroller` |

### `CellBlockedColumn` (`$7CBB`)

**Is there a wall in a column of A cells? A = 1 yes, 0 no; an item is noted in FoundItem**

In: HL the top cell, A the cells, DE the y (when y AND 7 is not 0 one more cell counts, unless it is below the play area). An item cell (bit 7) goes to FoundItem and is no wall. L1 5 573.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 118 calls, 38,905 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 335 calls, 98,463 t-states own (0.03 %) |
| Runs (the other recordings) | 5,120 calls (`stage1/rec/rzx-070000` 627, `stage1/rec/rzx-065000` 490, `stage1/rec/rzx-074000` 332 and 61 more) |
| Called from | `StepBlockedLeft`, `StepBlockedRight`, `StepRight`, `StepLeft` |
| Reads | `$6003`-`$600B` (system); `$6023`-`$602B` (system); `$6043`-`$604B` (system); `$6063`-`$606B` (system); `$6083`-`$608B` (system); `$60C2`-`$632A` (`CellTable+2`, `Start`, `Enemies`, `Objects`); 1 more ranges |
| Writes | `$63AA`-`$63AB` (`FoundItem`) |

### `CellBlockedRow` (`$7CF2`)

**Is there a wall in a row of A cells? A = 1 yes, 0 no**

As CellBlockedColumn along a row (DE the x). L1 8 094.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 79 calls, 26,739 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 322 calls, 86,339 t-states own (0.02 %) |
| Runs (the other recordings) | 3,651 calls (`stage1/rec/rzx-070000` 512, `stage1/rec/rzx-065000` 403, `stage1/rec/rzx-048000` 206 and 59 more) |
| Called from | `MoveDroid`, `StepDown`, `StepUp` |
| Reads | `$60C3`-`$6333` (`CellTable+3`, `Start`, `Enemies`, `Objects`) |
| Writes | `$63AA`-`$63AB` (`FoundItem`) |

### `CellSolidColumn` (`$7D24`)

**Is there a wall or an item in a column of A cells? (weapon 3's steering)**

Called only by the steering of weapon 3's shot (MoveShot3 `$832C`, `$8351`), which no build ran (L1 -): the same test, but an item counts as a wall.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CellSolidRow` (`$7D50`)

**Is there a wall or an item in a row of A cells? (weapon 3's steering)**

Called only by the steering of weapon 3's shot (`$837B`, `$83A7`; L1 -).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillAttr` (`$7D77`)

**Fill a block of attributes (or cells): B rows of C bytes with A**

In: HL the top left, B rows, C columns, A the value. L1 12 535.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 340 calls, 211,876 t-states own (0.02 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1,270 calls, 563,460 t-states own (0.16 %) |
| Runs (the other recordings) | 10,925 calls (`stage1/rec/rzx-070000` 1,117, `stage1/rec/rzx-065000` 1,049, `stage1/rec/room-tour` 654 and 59 more) |
| Called from | `Teleport`, `MoveObject`, `MoveShot`, `MoveShotStraight`, `MoveEnemy`, `DrawPatroller` |
| Writes | `$58C3`-`$5AFC` (screen) |

### `XorCells` (`$7D87`)

**XOR A into a block of cells, or zero it when A = 0**

In: HL the top left cell, B rows, C columns, A the mark (2 an enemy, 4 an object, 8 a patroller). A mover XORs its mark out of its old cells and into the new ones. L1 25 553 (25 zeroings).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 684 calls, 698,311 t-states own (0.06 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,643 calls, 1,866,828 t-states own (0.53 %) |
| Runs (the other recordings) | 22,226 calls (`stage1/rec/rzx-070000` 2,320, `stage1/rec/rzx-065000` 2,243, `stage1/rec/room-tour` 1,340 and 58 more) |
| Called from | `MoveObject`, `MoveShot`, `MoveShotStraight`, `MoveEnemy`, `DrawPatroller` |
| Reads | `$60C3`-`$62FC` (`CellTable+3`) |
| Writes | `$60C3`-`$62FC` (`CellTable+3`); `$6359`-`$6363` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 5 more) |

### `OrCells` (`$7DAE`)

**OR the cells of a block (not the item cells) into (DE)**

In: HL the top left, B rows, C columns, DE the byte that collects (TouchBits, ObjectBits). L1 9 176.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 231 calls, 312,289 t-states own (0.03 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 76 calls, 140,032 t-states own (0.04 %) |
| Runs (the other recordings) | 1,958 calls (`stage1/rec/rzx-070000` 236, `stage1/rec/rzx-065000` 194, `stage1/rec/rzx-074000` 181 and 37 more) |
| Called from | `MoveDroid`, `MoveObject` |
| Reads | `$6000`-`$604B` (system); `$605C`-`$606B` (system); `$607C`-`$608B` (system); `$609C`-`$609E` (system); `$60C4`-`$62BE` (`CellTable+4`); `$62D1`-`$62DE` (`CellTable+529`); 2 more ranges |
| Writes | `$63C3`-`$63C4` (`TouchBits`, `ObjectBits`) |

### `Random` (`$7DC9`)

**The next random number: A**

RandomSeed's four bytes as an add-with-carry chain: C = `$29`, then for each byte (A = C, C = byte, byte = A + byte + carry). Out: A = the new fourth byte. No R register, no timer: the sequence depends only on how many times it has been called. Menu `$893B` calls it in its wait loop, so the number at the start of a game is set by how many frames the player took at the menu (L1 710 553 calls).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 114,897 calls, 29,303,534 t-states own (2.64 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 1,142 calls, 332,056 t-states own (0.10 %) |
| Runs (the other recordings) | 594,514 calls (`stage1/rec/game-over` 382,245, `stage1/rec/win` 168,469, `stage1/rec/menu-cursor` 17,440 and 64 more) |
| Called from | `NewGame`, `Menu`, `ExhaustPick`, `MoveEnemy` |
| Reads | `$63A4`-`$63A7` (`RandomSeed`) |
| Writes | `$63A4`-`$63A7` (`RandomSeed`) |

## steps

`src/game/steps.asm`

### `StepRight` (`$7DDA`)

**Step a mover 2 pixels right**

L1 3 912.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 144 calls, 23,352 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 584 calls, 88,709 t-states own (0.03 %) |
| Runs (the other recordings) | 3,184 calls (`stage1/rec/rzx-065000` 301, `stage1/rec/rzx-070000` 263, `stage1/rec/rzx-048000` 202 and 49 more) |
| Called from | `MoveObject`, `MoveEnemy` |
| Calls | `CellAddrXY`, `CellBlockedColumn` |
| Reads | `$6305`-`$632A` (`Enemies+2`, `Objects`); `$63AA`-`$63AB` (`FoundItem`); `$63BC`-`$63BE` (`StepX`, `StepY`, `StepWidth`) |
| Writes | `$6305`-`$6329` (`Enemies+2`, `Objects`); `$63AA`-`$63AB` (`FoundItem`) |

### `StepDown` (`$7E13`)

**Step a mover 2 pixels down**

L1 4 688.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 119 calls, 22,050 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 579 calls, 98,581 t-states own (0.03 %) |
| Runs (the other recordings) | 3,990 calls (`stage1/rec/rzx-065000` 447, `stage1/rec/rzx-070000` 409, `stage1/rec/rzx-048000` 231 and 52 more) |
| Called from | `MoveObject`, `MoveEnemy` |
| Calls | `CellAddrXY`, `CellBlockedRow` |
| Reads | `$6305`-`$6334` (`Enemies+2`, `Objects`); `$63AA`-`$63AB` (`FoundItem`); `$63BD`-`$63BF` (`StepY`, `StepWidth`, `StepHeight`) |
| Writes | `$6306`-`$6334` (`Enemies+3`, `Objects`); `$63AA`-`$63AB` (`FoundItem`) |

### `StepLeft` (`$7E52`)

**Step a mover 2 pixels left**

L1 4 138.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 24 calls, 3,488 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 622 calls, 79,047 t-states own (0.02 %) |
| Runs (the other recordings) | 3,492 calls (`stage1/rec/rzx-070000` 560, `stage1/rec/rzx-065000` 428, `stage1/rec/rzx-048000` 232 and 48 more) |
| Called from | `MoveObject`, `MoveEnemy` |
| Calls | `CellAddrXY`, `CellBlockedColumn` |
| Reads | `$6305`-`$632A` (`Enemies+2`, `Objects`); `$63AA`-`$63AB` (`FoundItem`); `$63BC` (`StepX`) |
| Writes | `$6305`-`$6329` (`Enemies+2`, `Objects`); `$63AA`-`$63AB` (`FoundItem`) |

### `StepUp` (`$7E83`)

**Step a mover 2 pixels up (to y `$30`)**

L1 4 455.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 134 calls, 23,319 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 627 calls, 102,504 t-states own (0.03 %) |
| Runs (the other recordings) | 3,694 calls (`stage1/rec/rzx-070000` 583, `stage1/rec/rzx-065000` 426, `stage1/rec/rzx-048000` 203 and 51 more) |
| Called from | `MoveObject`, `MoveEnemy` |
| Calls | `CellAddrXY`, `CellBlockedRow` |
| Reads | `$6305`-`$6334` (`Enemies+2`, `Objects`); `$63AA`-`$63AB` (`FoundItem`); `$63BD` (`StepY`) |
| Writes | `$6306`-`$6334` (`Enemies+3`, `Objects`); `$63AA`-`$63AB` (`FoundItem`) |

### `ShiftGraphic3` (`$7EBB`)

**Shift a 3-byte-wide, 16-row graphic in place to the pixel offset A**

In: HL the graphic's first byte (its current offset 0-7), A the offset wanted. The 48 bytes after it are shifted right or left by the difference, and the byte is set: the enemy graphics (`$A74E-$AEC4`) are kept pre-shifted this way rather than shifted at each draw. L1 20 289 calls, 2 330 shifts.

[Animation: `ShiftGraphic3` at work](img/routines/ShiftGraphic3.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 211 calls, 475,013 t-states own (0.04 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,665 calls, 1,317,180 t-states own (0.38 %) |
| Runs (the other recordings) | 17,413 calls (`stage1/rec/rzx-070000` 1,867, `stage1/rec/rzx-065000` 1,838, `stage1/rec/rzx-048000` 1,042 and 58 more) |
| Called from | `MoveShot`, `MoveEnemy` |
| Reads | `$6609` (`BlankGraphic`); `$A74E`-`$AF54` (`EnemyGraphicsData`, `MaterialiseGraphics`); `$AFB6` (`Probe2`); `$AFE7` (`Probe3`); `$B83E`-`$B8D1` (`ProbeExplosion`, `ProbeExplosion2`, `ProbeExplosion3`, `ProbeExplosion4`) |
| Writes | `$A74E`-`$AEC4` (`EnemyGraphicsData`, `EnemyKind2`, `EnemyKind3`, `EnemyKind4` and 9 more) |

### `ShiftGraphic4` (`$7EFE`)

**Shift a 4-byte-wide, 24-row graphic in place to the pixel offset A**

As ShiftGraphic3 for the objects of width 4 (`$B413-$B6B9` and the others). L1 1 765 calls, 299 shifts.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 234 calls, 839,637 t-states own (0.08 %) |
| Runs (the other recordings) | 1,531 calls (`stage1/rec/rzx-070000` 209, `stage1/rec/rzx-065000` 182, `stage1/rec/rzx-024000` 125 and 22 more) |
| Called from | `MoveObject` |
| Reads | `$B049`-`$B2F0` (`ObjectGraphics`, `ObjectKind5`, `ObjectKind6`); `$B351` (`ObjectKind6+97`); `$B3B2` (`ObjectKind6+194`); `$B413`-`$B6B9` (`ObjectKind7`, `ObjectKindNone`); `$B71B`-`$B83D` (`ObjectDeath2`, `ObjectDeath3`, `ObjectDeath4`) |
| Writes | `$B049`-`$B2EF` (`ObjectGraphics`, `ObjectKind5`); `$B413`-`$B6B9` (`ObjectKind7`, `ObjectKindNone`); `$B71B`-`$B83D` (`ObjectDeath2`, `ObjectDeath3`, `ObjectDeath4`) |

## sound

`src/game/sound.asm`

### `RiseSweep` (`$7F4D`)

**A rising sweep: `$DC` toggles, each shorter**

DI; the beeper bit toggled with delays `$DC` down to 1; EI. L1 209.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/rec/energy-out`; in the other recordings 209 calls (`stage1/rec/rzx-052000` 36, `stage1/rec/rzx-037000` 18, `stage1/rec/rzx-046000` 18 and 8 more) |
| Called from | `TeleportFlash` |
| Ports out | `$00FE`, `$10FE` |

### `FallSweep` (`$7F5D`)

**A falling sweep: 256 toggles, each longer**

DI; delays 0, 1, ... 255; EI. DeathEffect (8 a death) and TeleportFlash. L1 649.

[Animation: `FallSweep` at work](img/routines/FallSweep.gif)

| | |
| --- | --- |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 8 calls, 4,412,247 t-states own (1.26 %) |
| Runs (the other recordings) | 641 calls (`stage1/rec/room-tour` 416, `stage1/rec/rzx-052000` 36, `stage1/rec/rzx-002000` 18 and 11 more) |
| Called from | `DeathEffect`, `TeleportFlash` |
| Writes | `$6359`-`$636D` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 12 more) |
| Ports out | `$00FE`, `$10FE` |

### `PassTick` (`$7F6D`)

**The pass tick: two beeper writes each pass, a 4206 T low pulse**

Called by MainLoop once a pass (L1 18 554). BorderSound = 0, then two writes: 0, and `$10` 4206 T later; the speaker stays high to the next pass, so each pass (2 frames) gives one 1.2 ms low pulse, a 25 Hz tick. The delay is worked out from H, but LD H,`$00` at the entry resets H every call, so it is always `$FD` (then 8): a constant.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 3,181,322 t-states own (0.29 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 14,180,070 t-states own (4.06 %) |
| Runs (the other recordings) | 15,585 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MainLoop` |
| Reads | `$6375` (`BorderSound`) |
| Writes | `$6375` (`BorderSound`) |
| Ports out | `$00FE`, `$10FE` |

### `BeamDown` (`$7F9C`)

**The teleport beam fills the droid's place top down, with a tone**

The attributes of columns +0 and +3 of the teleporter's 5 rows (10 cells) turn `$42`; 40 lines get `$A0` / `$05` bytes (the beam's edges), each after BeamScreen counts and, while it is not 1, a tone of 30 toggles. L1 21.

[Animation: `BeamDown` at work](img/routines/BeamDown.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/rec/energy-out`; in the other recordings 21 calls (`stage1/rec/rzx-052000` 3, `stage1/rec/rzx-007000` 2, `stage1/rec/rzx-037000` 2 and 9 more) |
| Called from | `Teleport` |
| Calls | `ScreenAddr` |
| Reads | `$6375` (`BorderSound`); `$63A2`-`$63A3` (`TeleportColumn`, `TeleportRow`); `$63C5`-`$63C6` (`BeamScreen`) |
| Writes | `$4844`-`$48DB` (screen); `$4944`-`$49DB` (screen); `$4A44`-`$4ADB` (screen); `$4B44`-`$57C7` (screen); `$5944`-`$5987` (screen); `$5998`-`$59A7` (screen); 5 more ranges |
| Ports out | `$00FE`, `$10FE` |

### `BeamUp` (`$8005`)

**The beam erased bottom up, with a tone**

L1 13.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/rec/energy-out`; in the other recordings 13 calls (`stage1/rec/rzx-052000` 2, `stage1/rec/rzx-063000` 1, `stage1/rec/rzx-044000` 1 and 9 more) |
| Called from | `Teleport` |
| Calls | `ScreenAddr` |
| Reads | `$6375` (`BorderSound`); `$63A2`-`$63A3` (`TeleportColumn`, `TeleportRow`); `$63C5`-`$63C6` (`BeamScreen`) |
| Writes | `$4844`-`$48DB` (screen); `$4944`-`$49DB` (screen); `$4A44`-`$4ADB` (screen); `$4B44`-`$4BDB` (screen); `$4C44`-`$4CDB` (screen); `$4D44`-`$4DDB` (screen); 11 more ranges |
| Ports out | `$00FE`, `$10FE` |

### `TeleportFlash` (`$8051`)

**The play area's attributes `$41`, the teleporter's cells flashing through the colours**

The play area's 18 attribute rows become `$41` (blue ink on black, bright); then the 5 x 2 cells of the teleporter take the attributes 7 down to 2, six steps, three times, each step with FallSweep and RiseSweep. L1 11.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/rec/energy-out`; in the other recordings 11 calls (`stage1/rec/rzx-052000` 2, `stage1/rec/rzx-058000` 1, `stage1/rec/rzx-041000` 1 and 7 more) |
| Called from | `Teleport` |
| Calls | `ScreenAddr`, `RiseSweep`, `FallSweep` |
| Reads | `$63A2`-`$63A3` (`TeleportColumn`, `TeleportRow`) |
| Writes | `$58C0`-`$5AFF` (screen) |

## objects

`src/game/objects.asm`

### `MoveObject` (`$809D`)

**Move and draw one object; a shot of the right weapon kills it**

In: HL the record (Objects or Object2). Every other call (the timer in bits 0-1 of +0) the object moves: on its first pass in the room (state bit 6) it is only drawn; otherwise the old image goes to the sprite list (graphic + 1, 4 bytes x 3 character rows), its mark 4 is XORed out of its cells and the cells under it are ORed into ObjectBits. A shot's mark there (bit 0): the cells zeroed; the weapon from AND `$70`, JP PO: one bit or all three kept as they are (three never match a kill mark: stopped), two bits ANDed with `$60`, 0 becomes `$10`; the object's mark (+8) equal: it dies (state bit 7); else it stops (bit 5). A live object steps in its direction (StepRight, StepDown, StepLeft, StepUp: 3 x 3 cells, x up to `$E8`, y up to `$A8`) and reverses at a wall: state AND `$FC` + 2 after right (left), + 3 after down (up), + 0 after left (right), + 1 after up (down). The next frame (97 bytes on, back to the first after the last) is shifted to x AND 7 (ShiftGraphic4) and queued, the mark 4 XORed in, the attributes set. A dying object steps through ObjectDeathFrames, one death frame an act (the state steps by 4), then it is gone (BlankGraphic).

Witness: L1 37 158 calls (2 for each of 18 579 passes), 1 777 moves, 13 hits, 11 kills.

[Animation: `MoveObject` at work](img/routines/MoveObject.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,070 calls, 442,245 t-states own (0.04 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,868 calls, 168,531 t-states own (0.05 %) |
| Runs (the other recordings) | 31,220 calls (`stage1/rec/rzx-065000` 2,450, `stage1/rec/rzx-070000` 2,268, `stage1/rec/rzx-074000` 1,814 and 63 more) |
| Called from | `MainLoop` |
| Calls | `ScreenAddrXY`, `CellAddrXY`, `FillAttr`, `XorCells`, `OrCells`, `StepRight`, `StepDown`, `StepLeft`, `StepUp`, `ShiftGraphic4` |
| Reads | `$6327`-`$633A` (`Objects`, `Object1Flags`, `Object2`, `Object2Flags`); `$63B1`-`$63D1` (`DrawMode`, `RoomRecordPtr`, `RoomEnemyPtr`, `TileAttrPtr` and 18 more); `$68E5`-`$68EA` (`ObjectDeathFrames+2`); `$FF03`-`$FF08` (`work space $FF03+`) |
| Writes | `$6327`-`$6337` (`Objects`, `Object1Flags`, `Object2`, `Object2Flags`); `$63B1`-`$63D1` (`DrawMode`, `RoomRecordPtr`, `RoomEnemyPtr`, `TileAttrPtr` and 18 more); `$FF01`-`$FF10` (`work space $FF01+`) |

## weapons

`src/game/weapons.asm`

### `MoveShot` (`$8298`)

**Move the shot of the weapon in use**

By Weapons: bit 7 MoveShot0 `$877E`; bits 6 and 5 MoveShotStraight `$84CC`; bit 4 (weapon 3) the probe here. MainLoop calls it twice a pass (L1 37 157). Weapon 3's shot (graphic Weapon3Graphics `$AF85`, 3 bytes x 2 rows, attribute `$46`, mark `$10`): erased and its mark XORed out, then while fire is held it is steered by the directions (MoveShot3Steer, CellSolidColumn / CellSolidRow: no RZX build steered one; the probe-shield recording steered it 71 times, doc 5.8), else it explodes over four passes (Weapon3Frames) and marks the cells of an object under it with `$11`.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,070 calls, 50,872 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,868 calls, 169,864 t-states own (0.05 %) |
| Runs (the other recordings) | 31,219 calls (`stage1/rec/rzx-065000` 2,450, `stage1/rec/rzx-070000` 2,268, `stage1/rec/rzx-074000` 1,814 and 63 more) |
| Called from | `MainLoop` |
| Calls | `ScreenAddrXY`, `CellAddrXY`, `FillAttr`, `XorCells`, `ShiftGraphic3`, `MoveShotStraight` (tail), `MoveShot0` (tail) |
| Reads | `$6149`-`$614D` (`CellTable+137`); `$6269` (`CellTable+425`); `$635E`-`$6369` (`Shot`, `ShotPos`, `ShotGraphic`, `Room` and 5 more); `$63D0`-`$63D1` (`SpriteListEnd`); `$68EB`-`$68F2` (`Weapon3Frames`); `$FF03`-`$FF28` (`work space $FF03+`) |
| Writes | `$6149`-`$614D` (`CellTable+137`); `$6269` (`CellTable+425`); `$635E`-`$6369` (`Shot`, `ShotPos`, `ShotGraphic`, `Room` and 5 more); `$63D0`-`$63D1` (`SpriteListEnd`); `$FF01`-`$FF30` (`work space $FF01+`) |

### `MoveShotStraight` (`$84CC`)

**Weapons 1 and 2: a 2 x 1 bolt 4 pixels a call (8 a pass: MoveShot runs twice) to a wall or the edge**

The old image erased and its ShotMark XORed out; x - 4 or + 4 (to 0 or `$F8`); a wall or item cell under the new place ends it (KeyLatches bit 6 set: fire must be released); an object under it (cell bit 2) gets the mark ORed in with bit 0 and the shot ends; else the next frame (graphic +/- 16) is drawn with ShotScratch's attribute and the mark XORed in. L1 4 647 calls, 55 with a shot.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 621 calls, 25,599 t-states own (0.00 %) |
| Runs (the other recordings) | 4,026 calls (`stage1/rec/room-tour` 1,634, `stage1/rec/rzx-065000` 528, `stage1/rec/menu-kempston` 361 and 10 more) |
| Called from | `MoveShot` (tail) |
| Calls | `ScreenAddrXY`, `CellAddrXY`, `FillAttr`, `XorCells` |
| Reads | `$614E` (`CellTable+142`); `$6172`-`$6196` (`CellTable+178`); `$61C4`-`$61D8` (`CellTable+260`); `$61E9`-`$61F8` (`CellTable+297`); `$623A`-`$623C` (`CellTable+378`); `$625B`-`$625C` (`CellTable+411`); 2 more ranges |
| Writes | `$614E` (`CellTable+142`); `$6172` (`CellTable+178`); `$6187`-`$6196` (`CellTable+199`); `$61C6`-`$61D7` (`CellTable+262`); `$635E`-`$6369` (`Shot`, `ShotPos`, `ShotGraphic`, `Room` and 5 more); `$63D0`-`$63D1` (`SpriteListEnd`); 1 more ranges |

### `Fire` (`$861C`)

**Fire the weapon in use: a new shot beside the droid**

Not while a shot is new (Shot bit 6) or fire has not been released (KeyLatches bit 6). Shot = `$60`; x = the droid's column + 3 (right) or - 2 (left, bit 0), not past column `$1B` / 2; y = the droid's y + 16. Weapon 0: the dash at ShotGraphic0 (FireBasic); weapon 1: `$8824`, attribute `$43`, mark `$40`; weapon 2: `$8844`, `$44`, `$20`; weapon 3: `$AF85` on 2 x 2 cells, `$46`... each refused on a wall cell and when its Ammo is 0, which then goes down one (BCD) and is printed. L1 1 844 calls, 779 shots fired.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 9 calls, 2,611 t-states own (0.00 %) |
| Runs (the other recordings) | 1,835 calls (`stage1/rec/rzx-074000` 207, `stage1/rec/rzx-065000` 184, `stage1/rec/rzx-070000` 123 and 51 more) |
| Called from | `MoveDroid` |
| Calls | `PrintBcd`, `CellAddrXY` |
| Reads | `$6102`-`$629C` (`CellTable+66`); `$6359`-`$636C` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 11 more) |
| Writes | `$635E`-`$636C` (`Shot`, `ShotPos`, `ShotGraphic`, `Room` and 6 more); `$63C0`-`$63C1` (`ShotScratch`, `ShotMark`) |

### `MoveShot0` (`$877E`)

**Weapon 0: the dash 8 pixels a call (16 a pass) until it hits ink, a wall or the edge**

The old image erased; when the interrupt found ink under it (Shot bit 7) it ends; else x - 8 or + 8 (to 0 or `$F8`), and a wall or item cell ends it. A new dash (bit 5) is only drawn. Attribute `$47`. L1 32 027 calls, 5 855 moves.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 449 calls, 16,154 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,868 calls, 174,660 t-states own (0.05 %) |
| Runs (the other recordings) | 26,710 calls (`stage1/rec/rzx-070000` 1,888, `stage1/rec/rzx-065000` 1,861, `stage1/rec/rzx-074000` 1,814 and 61 more) |
| Called from | `MoveShot` (tail) |
| Calls | `ScreenAddrXY`, `CellAddrXY` |
| Reads | `$6100`-`$629F` (`CellTable+64`); `$635E`-`$6362` (`Shot`, `ShotPos`, `ShotGraphic`); `$63D0`-`$63D1` (`SpriteListEnd`) |
| Writes | `$5900`-`$5A9F` (screen); `$635E`-`$635F` (`Shot`, `ShotPos`); `$63D0`-`$63D1` (`SpriteListEnd`); `$FF01`-`$FF40` (`work space $FF01+`) |

## menu

`src/game/menu.asm`

### `Menu` (`$8854`)

**The menu: the frame, the logo, the texts, the control choice; 0 starts**

A frame of 16 x 16 blocks (MenuFrameTopEdge `$BC02-$BD01`) round the screen, the attributes `$47`, the border black, the two TUJAD logos (MenuLogo at `$4064` and `$4078`), the texts (MenuTexts: TUJAD, 1 KEYBOARD, 2 CURSOR JOYSTICK, 3 KEMPSTON JOYSTICK, 0 START GAME; the copyright line after them is never printed). Then MenuPoll: Random, keys 1, 2 and 3 set Controls to `$80`, `$40` or 0 and light their line (MenuLight*), 0 returns. L1 4 menus; MenuPoll 699 777 loops in c1 and the menu builds.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 19,961,908 t-states own (1.80 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/game-over` 1, `stage1/rec/win` 1, `stage1/rec/rzx-080000` 1) |
| Called from | `Restart` |
| Calls | `Random`, `MenuLogo`, `Blit16`, `PrintText` |
| Reads | `$5800`-`$5AFE` (screen); `$63C2` (`Controls`) |
| Writes | `$5800`-`$5AFF` (screen); `$63C2` (`Controls`); `$8D35`-`$8D36` (`MenuLogoAt`) |
| Ports in | `$EFFE`, `$F7FE` |
| Ports out | `$00FE` |

### `MenuLogo` (`$89E5`)

**The TUJAD logo at (MenuLogoAt): five 16-pixel blocks and its colours**

MenuLogoGraphic as three 16-row and two 8-row pieces, then MenuLogoAttrs (7 rows of 4). L1 8 (two a menu).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 2 calls, 4,139 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/rec/game-over` 2, `stage1/rec/rzx-080000` 2, `stage1/rec/win` 2) |
| Called from | `Menu` |
| Calls | `Blit2` |
| Reads | `$8D35`-`$8D36` (`MenuLogoAt`); `$8D96`-`$8DB1` (`MenuLogoAttrs`) |
| Writes | `$5864`-`$5867` (screen); `$5878`-`$5887` (screen); `$5898`-`$58A7` (screen); `$58B8`-`$58C7` (screen); `$58D8`-`$58E7` (screen); `$58F8`-`$5907` (screen); 2 more ranges |

### `Blit2` (`$8A5E`)

**Copy B rows of 2 bytes from DE to the screen at HL**

L1 40.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 10 calls, 11,853 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/rec/game-over` 10, `stage1/rec/rzx-080000` 10, `stage1/rec/win` 10) |
| Called from | `MenuLogo` |
| Reads | `$8DB2`-`$8DD1` (`MenuLogoGraphic`, `MenuLogoLowerHalf`) |
| Writes | `$4065`-`$483B` (screen); `$4924`-`$493B` (screen); `$4A24`-`$4A3B` (screen); `$4B24`-`$4B3B` (screen); `$4C24`-`$4C3B` (screen); `$4D24`-`$4D3B` (screen); 2 more ranges |

### `Print8` (`$8A79`)

**Copy an 8 x 8 character from DE to the screen at HL**

L1 1 758 (PrintBcd, PrintText, DrawHud, ShowWeapon).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 165 calls, 91,812 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 116 calls, 64,481 t-states own (0.02 %) |
| Runs (the other recordings) | 1,477 calls (`stage1/rec/room-tour` 224, `stage1/rec/game-over` 190, `stage1/rec/menu-cursor` 96 and 47 more) |
| Called from | `ShowWeapon`, `PrintBcd`, `PrintText`, `DrawHud` |
| Reads | `$6609`-`$6618` (`BlankGraphic`); `$8BFD`-`$8C54` (`HudGraphics`, `HudBottomEdge`, `HudLeftEdge`, `HudRightEdge` and 7 more); `$E002`-`$E009` (`Font`); `$E02A`-`$E031` (`Font+40`); `$E082`-`$E0D1` (`Font+128`); `$E10A`-`$E1D1` (`Font+264`) |
| Writes | `$4000`-`$5173` (screen); `$5206`-`$5273` (screen); `$5306`-`$5373` (screen); `$5406`-`$5473` (screen); `$5506`-`$5573` (screen); `$5606`-`$5673` (screen); 1 more ranges |

### `Blit16` (`$8A93`)

**Copy a 16 x 16 block (32 bytes) from DE to the screen at HL**

L1 1 214 (the items, the HUD icons, the menu frame, the ED pieces).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 58 calls, 160,240 t-states own (0.01 %) |
| Runs (the other recordings) | 1,156 calls (`stage1/rec/rzx-065000` 196, `stage1/rec/rzx-037000` 91, `stage1/rec/room-tour` 77 and 34 more) |
| Called from | `DrawItem`, `ShowWeapon`, `Menu`, `DrawHud`, `ProgressScreen` |
| Reads | `$8C55`-`$8D34` (`HudIcons`, `IconWeapon1`, `IconWeapon2`, `IconWeapon3` and 3 more); `$BC02`-`$BD01` (`MenuFrameTopEdge`, `MenuFrameBottomEdge`, `MenuFrameLeftEdge`, `MenuFrameRightEdge` and 4 more); `$E1E2`-`$E821` (`EdPieces`) |
| Writes | `$4000`-`$57FF` (screen); `$6359` (`DroidVars`) |

### `PrintText` (`$8AB4`)

**Print text at HL to the screen at DE in the colour A, up to '.'**

Font characters (Font - `$100` + 8 x code: LD BC,Font - 256) through Print8, each cell's attribute PrintAttr. L1 21 texts, 302 characters.

[Animation: `PrintText` at work](img/routines/PrintText.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 5 calls, 18,078 t-states own (0.00 %) |
| Runs (the other recordings) | 16 calls (`stage1/rec/game-over` 6, `stage1/rec/win` 5, `stage1/rec/rzx-080000` 5) |
| Called from | `Menu`, `ProgressPercent` |
| Calls | `Print8` |
| Reads | `$8D37`-`$8D83` (`PrintAttr`, `MenuTexts`); `$9072`-`$9091` (`ProgressText`) |
| Writes | `$58CD`-`$58D1` (screen); `$5900`-`$591E` (screen); `$5986`-`$5991` (screen); `$59C6`-`$59D8` (screen); `$5A06`-`$5A1A` (screen); `$5A66`-`$5A73` (screen); 1 more ranges |

### `DrawHud` (`$8AE8`)

**The HUD: the frame of the top five rows, the dividers, the colours, the icons, the lives and the energy**

Corners, edges and the divider from HudGraphics, the attributes (`$43`, then HudAttrs on rows 1-4 at column 2, 7 at the edges), the icons of weapon 0, GEN 19 (the lives) and the energy, Lives at `$4085` and Energy at `$4088` (PrintBcd). L1 4 (NewGame).

[Animation: `DrawHud` at work](img/routines/DrawHud.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 13,795 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/menu-cursor` 1, `stage1/rec/menu-kempston` 1, `stage1/rec/game-over` 1) |
| Called from | `NewGame` |
| Calls | `PrintBcd`, `Print8`, `Blit16` |
| Reads | `$5800`-`$58BE` (screen); `$636D`-`$636E` (`Lives`, `Energy`); `$8BF5`-`$8BFC` (`HudAttrs`) |
| Writes | `$5800`-`$58BF` (screen) |

## exhaust

`src/game/exhaust.asm`

### `DroidExhaust` (`$8DD2`)

**XOR the exhaust rows under the droid (8 pixel rows of 3 bytes)**

Five character rows under the droid's top (one column on when it faces left and walks); not below the screen. Each byte goes where the cell is no wall and holds no item, and the cell's attribute becomes `$45`. MainLoop calls it before and after MoveDroid, so the old flicker is erased and the new one drawn (L1 37 128).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,070 calls, 4,966,082 t-states own (0.45 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,868 calls, 18,730,421 t-states own (5.36 %) |
| Runs (the other recordings) | 31,190 calls (`stage1/rec/rzx-065000` 2,450, `stage1/rec/rzx-070000` 2,268, `stage1/rec/rzx-074000` 1,814 and 63 more) |
| Called from | `MainLoop` |
| Calls | `ScreenAddr` |
| Reads | `$40A1`-`$41BE` (screen); `$42A1`-`$42BE` (screen); `$43A1`-`$43BE` (screen); `$44A1`-`$44BE` (screen); `$45A1`-`$45BE` (screen); `$46A1`-`$46BE` (screen); 10 more ranges |
| Writes | `$40A1`-`$41BE` (screen); `$42A1`-`$42BE` (screen); `$43A1`-`$43BE` (screen); `$44A1`-`$44BE` (screen); `$45A1`-`$45BE` (screen); `$46A1`-`$46BE` (screen); 9 more ranges |

### `ExhaustStep` (`$8E7E`)

**Rotate the four exhaust rows' patterns and mask them**

ExhaustRow for rows 1 and 3, ExhaustRowLeft for rows 2 and 4 (the patterns run apart), then ExhaustMask. L1 18 571.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 153,476 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 694,397 t-states own (0.20 %) |
| Runs (the other recordings) | 15,602 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MainLoop` |
| Calls | `ExhaustRow`, `ExhaustRowLeft`, `ExhaustMask` |
| Reads | `$65AE`-`$65B5` (`ExhaustPtrs`) |
| Writes | `$63AE`-`$63AF` (`MoverScratch`); `$65AE`-`$65B5` (`ExhaustPtrs`) |

### `ExhaustPick` (`$8EAC`)

**A random free pattern record for a row whose counter ran out**

L1 5 012 tries, 3 134 picks: Random AND `$1C` picks one of the eight ExhaustPatterns until its counter is 0, which becomes 8-39.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 92 calls, 17,328 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 412 calls, 76,705 t-states own (0.02 %) |
| Runs (the other recordings) | 2,630 calls (`stage1/rec/rzx-065000` 205, `stage1/rec/rzx-070000` 203, `stage1/rec/rzx-074000` 149 and 62 more) |
| Called from | `ExhaustRow`, `ExhaustRowLeft` |
| Calls | `Random` |
| Reads | `$65B6`-`$65D2` (`ExhaustPatterns`) |
| Writes | `$65B6`-`$65D2` (`ExhaustPatterns`) |

### `ExhaustRow` (`$8EC7`)

**Rotate a pattern one pixel right into the next ExhaustRaw row**

L1 37 142.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,070 calls, 410,469 t-states own (0.04 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,868 calls, 1,863,754 t-states own (0.53 %) |
| Runs (the other recordings) | 31,204 calls (`stage1/rec/rzx-065000` 2,450, `stage1/rec/rzx-070000` 2,268, `stage1/rec/rzx-074000` 1,814 and 63 more) |
| Called from | `ExhaustStep` |
| Calls | `ExhaustPick` |
| Reads | `$63AE`-`$63AF` (`MoverScratch`); `$65B6`-`$65D5` (`ExhaustPatterns`); `$65FD`-`$6605` (`ExhaustRaw`) |
| Writes | `$63AE`-`$63AF` (`MoverScratch`); `$65B6`-`$65D5` (`ExhaustPatterns`); `$65FD`-`$6605` (`ExhaustRaw`) |

### `ExhaustRowLeft` (`$8EEB`)

**Rotate a pattern one pixel left into the next ExhaustRaw row**

L1 37 142.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,070 calls, 480,860 t-states own (0.04 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,868 calls, 2,183,517 t-states own (0.62 %) |
| Runs (the other recordings) | 31,204 calls (`stage1/rec/rzx-065000` 2,450, `stage1/rec/rzx-070000` 2,268, `stage1/rec/rzx-074000` 1,814 and 63 more) |
| Called from | `ExhaustStep` |
| Calls | `ExhaustPick` |
| Reads | `$63AE`-`$63AF` (`MoverScratch`); `$65B6`-`$65D5` (`ExhaustPatterns`); `$6600`-`$6608` (`ExhaustRaw+3`) |
| Writes | `$63AE`-`$63AF` (`MoverScratch`); `$65B6`-`$65D5` (`ExhaustPatterns`); `$6600`-`$6608` (`ExhaustRaw+3`) |

### `ExhaustMask` (`$8F1B`)

**ExhaustRaw's four rows into ExhaustRows, masked by the droid's frame**

Frame 12 (DroidFly2, in the air) takes ExhaustMasks + 2 (`$0F`, `$F0`), every other frame `$65D6`. L1 18 572.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 473,588 t-states own (0.04 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 2,161,478 t-states own (0.62 %) |
| Runs (the other recordings) | 15,603 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `ExhaustStep` |
| Reads | `$635C` (`DroidFrame`); `$65D6`-`$65D9` (`ExhaustMasks`); `$65FD`-`$6608` (`ExhaustRaw`) |
| Writes | `$6359`-`$6363` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 5 more); `$65E8`-`$65FC` (`ExhaustRows+3`) |

## progress

`src/game/progress.asm`

### `ProgressScreen` (`$8F53`)

**Show the ED circuit picture of the pieces taken; with A = `$FF` the percentage**

In: A the piece just taken (1-50), 0 (the win) or `$FF` (the game over). The sprite list is emptied and the energy timer stopped; a piece's bit is set in EdFlags (byte (n - 1) / 5, bit (n - 1) mod 5). The play area is cleared and coloured `$31`; the 10 x 5 picture is drawn at `$4886` from EdPieces (a piece taken: its 16 x 16 tile, colour `$67`, 2 % each; not taken: colour `$28`, no pixels); the new piece's cells flash `$67` / `$64` nine times with long delays; with A = `$FF` the text YOU HAVE COMPLETED nn % OF TUJAD. Then the energy timer is restarted and Shot cleared. L1 36 (35 pieces, 1 game over).

The delay loop at ProgressDelay (LD BC,`$C350`, 50 000 rounds) is the longest wait in the game: 9 x 50 000 x 26 T, about 3.3 s at 3.5 MHz.

[Animation: `ProgressScreen` at work](img/routines/ProgressScreen.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 11,737,595 t-states own (1.06 %) |
| Runs (the other recordings) | 35 calls (`stage1/rec/rzx-065000` 4, `stage1/rec/rzx-037000` 3, `stage1/rec/rzx-010000` 2 and 20 more) |
| Called from | `LoseLife`, `EdPickup` |
| Calls | `ClearPlayArea`, `Blit16`, `ProgressPercent`, `ProgressCell` |
| Reads | `$58C0`-`$5AFE` (screen); `$6374` (`EnergyReload`); `$63B1`-`$63B3` (`DrawMode`, `RoomRecordPtr`); `$6681`-`$668A` (`EdFlags`); `$9092` (`ProgressPercentBcd`) |
| Writes | `$58C0`-`$5AFF` (screen); `$635E`-`$6366` (`Shot`, `ShotPos`, `ShotGraphic`, `Room` and 2 more); `$63B1`-`$63B3` (`DrawMode`, `RoomRecordPtr`); `$63D0`-`$63D1` (`SpriteListEnd`); `$6681`-`$668A` (`EdFlags`); `$9092` (`ProgressPercentBcd`); 1 more ranges |

### `ProgressPercent` (`$9046`)

**Print YOU HAVE COMPLETED nn % OF TUJAD. with the BCD percentage**

The two digits go into ProgressText + 19 and + 20 (`$9085`, `$9086`; a leading 0 a space). L1 1 (game-over).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/rec/energy-out`; in the other recordings 1 call (`stage1/rec/game-over` 1) |
| Called from | `ProgressScreen` |
| Calls | `PrintText` |
| Reads | `$9092` (`ProgressPercentBcd`) |
| Writes | `$9085`-`$9086` (`ProgressText+19`) |

### `ProgressCell` (`$9093`)

**Colour a piece's 2 x 2 cells C and step to the next place of the picture**

L1 1 800.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 50 calls, 11,506 t-states own (0.00 %) |
| Runs (the other recordings) | 1,750 calls (`stage1/rec/rzx-065000` 200, `stage1/rec/rzx-037000` 150, `stage1/rec/rzx-010000` 100 and 20 more) |
| Called from | `ProgressScreen` |
| Reads | `$63B2`-`$63B3` (`RoomRecordPtr`) |
| Writes | `$5986`-`$5AB9` (screen); `$63B2`-`$63B3` (`RoomRecordPtr`) |

## enemies

`src/game/enemies.asm`

### `EnemyKind` (`$90C8`)

**The next of the nine enemy kinds: its frame count and graphics**

EnemyKindTurn cycles 1-9; DrawMode (`$63B1`) = EnemyFrameCounts[kind], HL = the kind's EnemyGraphics word. L1 403.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 2 calls, 308 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 18 calls, 2,682 t-states own (0.00 %) |
| Runs (the other recordings) | 383 calls (`stage1/rec/room-tour` 38, `stage1/rec/rzx-065000` 35, `stage1/rec/rzx-074000` 28 and 44 more) |
| Called from | `MoveEnemy` |
| Reads | `$6367` (`EnemyKindTurn`); `$68B8`-`$68C0` (`EnemyFrameCounts`) |
| Writes | `$6367` (`EnemyKindTurn`); `$63B1` (`DrawMode`) |

### `MoveEnemy` (`$90E7`)

**One step of an enemy: spawn, materialise, fly, explode**

In: HL the record, EnemyBufferPtrs. A record with timer 0 is empty. The timer counts down; at 0 it is 2 again and the enemy acts (L1 11 212 of 74 324 calls). Spawn (state `$40`): x and y from the 13 x 4 lattice (x Random OR `$20` AND `$F8`, `$E0-$F8` clamped to `$D0`; y Random OR `$50` AND `$78`) until the 2 x 2 cells are 0 (720 tries, 581 spawns), the attribute Random AND 7 OR `$42` (`$42`, `$43`, `$46` or `$47`). Each act: the old frame (the draw buffer) is queued to erase and the mark 2 XORed out. Hit (state bit 7): ExplosionFrames, one explosion frame an act (the state steps by 4); the mark is not XORed back, so the cells hold 2 only after the 2nd and 4th act; then state `$40` and the timer random OR `$29` (202 explosions end). Materialising (bit 6): MaterialiseFrames, the mark XORed again (2 x 2), so the cells stay clean; then a random direction and the next kind (EnemyKind: 403). Flying: state 0 right and down, 1 left and down, 2 left and up, 3 right and up; a blocked step flips that half of the direction (StepRight / StepLeft and StepDown / StepUp, 2 x 2 cells, x up to `$F0`, y up to `$B0`). The next frame (49 bytes on) is shifted to x AND 7 in place (ShiftGraphic3), copied to the erase buffer and queued with the state as its flag byte, the mark 2 XORed in and the attributes set.

Witness: L1 74 324 calls, 7 790 flights, 1 071 explosion steps, 2 352 materialise steps.

[Animation: `MoveEnemy` at work](img/routines/MoveEnemy.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 2,140 calls, 550,740 t-states own (0.05 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 9,736 calls, 5,945,297 t-states own (1.70 %) |
| Runs (the other recordings) | 62,448 calls (`stage1/rec/rzx-065000` 4,900, `stage1/rec/rzx-070000` 4,536, `stage1/rec/rzx-074000` 3,628 and 63 more) |
| Called from | `MainLoop` |
| Calls | `ScreenAddrXY`, `CellAddrXY`, `FillAttr`, `XorCells`, `Random`, `StepRight`, `StepDown`, `StepLeft`, `StepUp`, `ShiftGraphic3`, `EnemyKind` |
| Reads | `$6144`-`$619B` (`CellTable+132`); `$61C4`-`$621B` (`CellTable+260`); `$6303`-`$6326` (`Enemies`, `Enemy2`, `Enemy3`, `Enemy4`); `$63B1` (`DrawMode`); `$63D0`-`$63D1` (`SpriteListEnd`); `$660A`-`$6639` (`BlankGraphic+1`); 4 more ranges |
| Writes | `$6303`-`$6326` (`Enemies`, `Enemy2`, `Enemy3`, `Enemy4`); `$6359`-`$6363` (`DroidVars`, `DroidY`, `DroidFlags`, `DroidFrame` and 5 more); `$63AA`-`$63BF` (`FoundItem`, `MoverScratch`, `DrawMode`, `RoomRecordPtr` and 7 more); `$63D0`-`$63D1` (`SpriteListEnd`); `$6708`-`$6887` (`EnemyBuffers`, `EnemyBuffer1B`, `EnemyBuffer2A`, `EnemyBuffer2B` and 4 more); `$FF01`-`$FF30` (`work space $FF01+`) |

## patrollers

`src/game/patrollers.asm`

### `MovePatroller` (`$93A6`)

**One turn of the patroller at PatrollerPtr: erase, step, draw**

Erase it (DrawPatroller) when it was drawn and is in the room; clear bit 7; PatrollerStep; draw it when it is in the room. L1 18 583 turns, 495 erased, 507 drawn.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 128,468 t-states own (0.01 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 576,714 t-states own (0.17 %) |
| Runs (the other recordings) | 15,614 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MovePatrollers` |
| Calls | `PatrollerStep`, `DrawPatroller` |
| Reads | `$633B`-`$634E` (`Patrollers`, `Patroller2`, `Patroller3`); `$6363` (`Room`); `$63A8`-`$63A9` (`PatrollerPtr`) |
| Writes | `$633B`-`$634B` (`Patrollers`, `Patroller2`, `Patroller3`); `$63B1` (`DrawMode`) |

### `PatrollerStep` (`$93E0`)

**Advance the frame; every fourth a column, round the ends**

+0 the frame 0-3; at 4: a column right (y bit 0 clear) or left; past column `$1C` (or below 0) into the next room (+3 + 1 or - 1) at column 0 (or `$1C`); at the right end (room +4, column +5) or the left end (+6, +7) it turns (bit 0 of y flips) and steps back. L1 18 583, 4 630 steps, 102 + 72 room changes, 28 + 28 turns.

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 535 calls, 38,493 t-states own (0.00 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 2,434 calls, 180,561 t-states own (0.05 %) |
| Runs (the other recordings) | 15,614 calls (`stage1/rec/rzx-065000` 1,225, `stage1/rec/rzx-070000` 1,134, `stage1/rec/rzx-074000` 907 and 63 more) |
| Called from | `MovePatroller` |
| Reads | `$633B`-`$6352` (`Patrollers`, `Patroller2`, `Patroller3`) |
| Writes | `$633B`-`$634E` (`Patrollers`, `Patroller2`, `Patroller3`) |

### `DrawPatroller` (`$942D`)

**XOR a patroller into the sprite list and its mark into the cells**

The frame from `$B902` (walking right) or `$BA82` (left), 96 bytes a frame (4 bytes x 24 rows: Patrol graphics); 4 x 3 character cells, the mark DrawMode (8), the attribute `$42`. L1 1 002.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/rec/energy-out`; in the other recordings 1,002 calls (`stage1/rec/rzx-041000` 278, `stage1/rec/rzx-019000` 203, `stage1/rec/rzx-036000` 157 and 6 more) |
| Called from | `MovePatroller` |
| Calls | `ScreenAddr`, `CellAddr`, `FillAttr`, `XorCells` |
| Reads | `$633B`-`$634D` (`Patrollers`, `Patroller2`, `Patroller3`); `$63B1` (`DrawMode`); `$63D0`-`$63D1` (`SpriteListEnd`) |
| Writes | `$63D0`-`$63D1` (`SpriteListEnd`); `$FF01`-`$FF30` (`work space $FF01+`) |

## interrupt

`src/game/interrupt.asm`

### `SetupIM2` (`$9584`)

**The IM 2 table, the empty sprite list, the scroller reset, the handler installed**

257 bytes of `$5B` at Im2Table (`$FE00-$FF00`), so the vector is `$5B5B` whatever the bus holds; JP Interrupt at `$5B5B`; I = `$FE`; IM 2. L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1 call, 6,924 t-states own (0.00 %) |
| Called from | `Setup` |
| Writes | `$5B5B`-`$5B5D` (`ImJump`); `$63C7`-`$63D1` (`ScrollText`, `ScrollNext`, `ScrollPriority`, `ScrollLine` and 3 more); `$FE00`-`$FF02` (`work space $FE00+`) |

### `Interrupt` (`$95D0`)

**Every frame: read the controls, XOR the sprite list, scroll the message, the timers, the ROM keyboard**

Saves the registers; ReadControls; then each sprite list record from SpriteListEnd (graphic, flag pointer, width, rows / 8, screen address): its rows are XORed onto the screen and, when a byte of the sprite falls on ink already there ((screen AND sprite) is not 0), bit 7 of the flag byte is set (InterruptCollide: L1 35 639 of 68 835 sprites). Then the scroller, every ScrollDelay frames (5; 15 after a whole text row): the 19-byte window at `$402C` (31 pixel lines) moves up one pixel line and the next pixel row of 19 characters comes in at the bottom (ScrollScreen): row ScrollLine - 1 of each glyph, Font - 1 + 8 x code + ScrollLine. After 8 lines the text moves on 19 characters; at a '.' the queued message (ScrollNext) starts, or none. Then WeaponSelect, EnergyTick, DrainTimer, the ROM's KEYBOARD (FRAMES and LAST_K), the registers back, EI, RETI.

Witness: L1 54 811 interrupts; 123 658 list reads; the scroller 8 773 steps.

[Animation: `Interrupt` at work](img/routines/Interrupt.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the tape at ROM speed, the menu and keyboard play) | 1,371 calls, 27,056,627 t-states own (2.44 %) |
| Runs (energy-out: 5001 frames of play from the RZX state after 47 000 frames) | 4,880 calls, 85,437,598 t-states own (24.45 %) |
| Runs (the other recordings) | 48,560 calls (`stage1/rec/room-tour` 4,265, `stage1/rec/rzx-065000` 3,491, `stage1/rec/rzx-070000` 2,690 and 65 more) |
| Calls | `ReadControls`, `DrainTimer`, `WeaponSelect`, `EnergyTick` |
| Reads | `$4000`-`$57FD` (screen); `$6304`-`$631F` (`Enemies+1`, `Enemy2`, `Enemy3`, `Enemy4`); `$635B`-`$635E` (`DroidFlags`, `DroidFrame`, `DroidWidth`, `Shot`); `$63AE` (`MoverScratch`); `$63C7`-`$65AD` (`ScrollText`, `Messages`); `$65DD`-`$6887` (`ShotGraphic0`, `ExhaustRows`, `BlankGraphic`, `EdFlags` and 3 more); 11 more ranges |
| Writes | `$4000`-`$57FD` (screen); `$6304`-`$631F` (`Enemies+1`, `Enemy2`, `Enemy3`, `Enemy4`); `$635B`-`$635E` (`DroidFlags`, `DroidFrame`, `DroidWidth`, `Shot`); `$63AE` (`MoverScratch`); `$63C7`-`$63D1` (`ScrollText`, `ScrollNext`, `ScrollPriority`, `ScrollLine` and 3 more) |
