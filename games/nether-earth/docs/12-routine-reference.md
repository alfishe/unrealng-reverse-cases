# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/game` (the first recording's game window), `work/deep` (the bot's game: robots built, orders given, factories captured, fights). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the entries they cover. An entry no recording reached says so.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`viewbuffer`](11-data-reference.md#viewbuffer) | `$5B00`-`$677F` | 0 of 1 |
| [`font`](11-data-reference.md#font) | `$6780`-`$697F` | 0 of 1 |
| [`sprites`](11-data-reference.md#sprites) | `$6980`-`$A5FF` | 0 of 179 |
| [`start`](#start) | `$A600`-`$A71F` | 4 of 4 |
| [`robotmenu`](#robotmenu) | `$A720`-`$AD61` | 26 of 48 |
| [`gameturn`](#gameturn) | `$AD62`-`$AF10` | 11 of 14 |
| [`ship`](#ship) | `$AF11`-`$B0C9` | 12 of 13 |
| [`world`](#world) | `$B0CA`-`$B7F3` | 34 of 36 |
| [`enemy`](#enemy) | `$B7F4`-`$BB08` | 4 of 4 |
| [`bases`](#bases) | `$BB09`-`$BDA8` | 17 of 17 |
| [`level`](11-data-reference.md#level) | `$BDA9`-`$C0FF` | 0 of 17 |
| [`mainmenu`](#mainmenu) | `$C100`-`$C4A6` | 39 of 64 |
| [`music`](#music) | `$C4A7`-`$C848` | 32 of 50 |
| [`construction`](#construction) | `$C849`-`$CCBC` | 18 of 26 |
| [`view`](#view) | `$CCBD`-`$D0B8` | 20 of 22 |
| [`screen`](#screen) | `$D0B9`-`$D37B` | 20 of 28 |
| [`controls`](#controls) | `$D37C`-`$D3E4` | 2 of 4 |
| [`print`](#print) | `$D3E5`-`$D565` | 13 of 13 |
| [`interrupts`](#interrupts) | `$D566`-`$D6A7` | 8 of 8 |
| [`tables`](11-data-reference.md#tables) | `$D6A8`-`$D7D2` | 0 of 6 |
| [`worldstate`](11-data-reference.md#worldstate) | `$D7D3`-`$DCFF` | 0 of 7 |
| [`map`](11-data-reference.md#map) | `$DD00`-`$FCE8` | 0 of 2 |

## start

`src/game/start.asm`

### `Start` (`$A600`)

**the entry from N1: the IM 2 table, the start-up, the menu**

The IM 2 table `$FE00-$FF00` (257 x `$FD`), JP at `$FDFD`, Handler = StartInterrupt, I = `$FE`, IM 2; the random seed `$FD00-$FD03` = `$39`,`$30`,`$39`,`$30`; then MainMenu (Z: start a new game, NZ: a saved game was loaded). Reached again at the end of a game (`$AEFD`), by key I in play (`$A712`) and after a tape loading error (`$C28A`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NewGameSetup` (`$A62D`)

**New game: clear the robots, variables, buildings and shots, place the ship, build the map**

Entered from Start with the flags of the title menu MainMenu: NZ (option 5 loaded a saved game, which brings the robots, the map, the buildings, the shots and `$FD00-$FDFB` from tape) skips straight to EnterPlay; Z (option 0, START GAME) sets a new game up.

Zeroes the robot records `$DA00-$DCFF` (48 x 16), the variables `$FD04-$FDFC` (everything past the random seed, below the JP of the IM 2 vector), the building table `$FF01-$FFC9` and the five shot records `$D7D3-$D7FF` (5 x 9). Then: MapView = `$DD00`, ViewX = 0, ShipX = `$11`, ShipY = 10, Altitude = 0, the auto-climb counter `$FD30` = 3 (the ship rises to 6 on its own at the start), the general resource of both sides = 20 (Resources and `$FD4A`). BuildMap then clears the map `$DD00-$FCFF` and the radar buffer `$D800` and builds the landscape, the warbases and the factories. Falls into EnterPlay.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 26,831 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | run into, not called, 656,157 t-states own (0.03 %) |
| Calls | `PlayLoop`, `RobotMenu`, `GameTurn`, `MoveShip`, `WorldTurn`, `CountRobots`, `BuildMap`, `ConstructionMenu`, `ShipCell`, `DrawView`, `FindRobot`, `FindBuilding`, `DrawViewBackground`, `DrawPlayScreen`, `UpdateStatusPanel`, `WaitKey` |
| Reads | `$D7D3`-`$D7FE` (`Shots`); `$DA00`-`$DCFE` (`Robots`, `EnemyRobots`); `$E714`-`$E716` (`Map`); `$E914`-`$EB18` (`Map`); `$ED12`-`$ED18` (`Map`); `$EF12`-`$F118` (`Map`); 6 more ranges |
| Writes | `$D7D3`-`$D7FF` (`Shots`); `$DA00`-`$DCFF` (`Robots`, `EnemyRobots`); `$FD04`-`$FDFF` (`work space $FD04+`); `$FF01`-`$FFC9` (`work space $FF01+`); `$FFFE`-`$FFFF` (`work space $FFFE+`) |

### `EnterPlay` (`$A68E`)

**Draw the play screen and switch to the play interrupt**

DrawViewBackground and DrawPlayScreen build the play screen (the view, its frame, the radar, the status panel); then Handler = PlayInterrupt, which counts the frames in `$FD34` and draws the radar each frame. Falls into PlayLoop. Entered from NewGameSetup, from a loaded game, and again after a game save (key 5, SaveGame) at `$A71D`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlayLoop` (`$A69A`)

**The play loop: one game turn a pass (at least 10 frames)**

One pass: WaitKey (the controls into Input; key 1 pauses here), MoveShip, WorldTurn (every robot record and the five shots), DrawView (draw the view), GameTurn (the random step, the clock, captures, the end of the game; waits until 10 frames have passed since the previous turn). The recording ran it 3332 times in 36046 frames: about 10.5 frames a turn, 5 turns a second.

Then it looks under the ship (ShipCell: HL = the ship's map cell). Map bit 6 means something stands there. A robot of ours (FindRobot, B = 48 - slot >= 25) with the ship resting exactly on its top (Altitude = +`$09` + +`$0D`) opens RobotMenu. Otherwise a building of type 0 (the pad of our warbase) with Altitude = 15 (the pad's top, the ship cannot sink below it) opens ConstructionMenu, but only when the warbase's door cell 4 rows below the pad and the three cells below the door (row +5, columns -1, 0, +1) are free of bit 6: the new robot is placed on the door (ShipY + 4, `$CB6A`). After the menu the new record gets +`$05` = 4, +`$06` = 5, +`$0B` = 0 (stop), +`$0C` = 100 (strength), +`$0F` = 1 (moves at once); CountRobots recounts the robots and UpdateStatusPanel reprints the panel.

Bug (seen on the own instance): ConstructionMenu returns at once when all 24 of our slots are taken, with IY left on `$DB80`, the enemy's slot 24. The writes at `$A6F3` then hit that enemy robot: its strength goes back to 100 and its order to 0, every turn the ship sits on the pad.

Last, the game keys: Input bit 6 (key I in the default KeyTable) abandons the game (JP Start), bit 5 (key 5) saves the game to tape (SaveGame) and redraws the play screen (EnterPlay).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 64,293 t-states own (0.02 %) |
| Called from | `NewGameSetup` |
| Calls | `GameTurn`, `MoveShip`, `WorldTurn`, `ShipCell`, `DrawView`, `WaitKey` |
| Reads | `$DF0E`-`$E110` (`Map`); `$E30E`-`$E710` (`Map`); `$E90E`-`$E910` (`Map`); `$EB0E`-`$EB12` (`Map`); `$ED0E`-`$ED12` (`Map`); `$EF0E`-`$F31A` (`Map`); 3 more ranges |

## robotmenu

`src/game/robotmenu.asm`

### `RobotMenu` (`$A720`)

**landing on a robot of ours: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT; the order to +`$0B`**

IX = IY (the record), +`$0A` = 1 (the robot stands: UpdateRobot returns at once for +`$0A` = 1), MenuCursor = 4 (LEAVE ROBOT first), PanelBusy = 1. Falls into RobotMenuShow. Called by PlayLoop when the ship rests exactly on the top of a robot of ours.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7 calls, 616 t-states own (0.00 %) |
| Called from | `NewGameSetup` |
| Calls | `RobotMenuShow` |
| Writes | `$DA0A`-`$DA5A` (`Robots`); `$FD1F` (`work space $FD1F+`); `$FD39` (`work space $FD39+`) |

### `RobotMenuShow` (`$A732`)

**Robot menu: draw the four items, the current order and the strength, then choose**

Clears the side panel (ClearPanel) and prints DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT at (4,23), every 3 rows, attribute `$4D`, and the title -ORDERS- at (17,23). Falls into ShowOrder, ShowOrderMiles and RobotMenuChoose. Every submenu comes back here when it is done (`$A93E`, `$AA09`, `$AACC`, `$ABFD`, the combat menu at `$AC8B`).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 14 calls, 476 t-states own (0.00 %) |
| Called from | `RobotMenu`, `SetOrder` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

### `ShowOrder` (`$A795`)

**Robot menu: print the name of the robot's order**

Copies the 27-byte name of order +`$0B` from OrderNames (`$A848` + 27 x order) into OrderLine, the string printed right after the CALL at `$A7AA`: three lines at (18,23), attribute `$45`.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 14 calls, 10,094 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintInline` |
| Reads | `$A848`-`$A862` (`OrderNames`); `$A899`-`$A8B3` (`OrderName3`); `$A8EA`-`$A91F` (`OrderName6`, `OrderName7`); `$DA0B`-`$DA5B` (`Robots`) |
| Writes | `$A7B2`-`$A7CC` (`OrderLine`) |

### `ShowOrderMiles` (`$A7CD`)

**Robot menu: for ADVANCE and RETREAT, the miles under the order's name**

Orders 1 and 2 only: prints at (19,25) the distance +`$0E` / 2 with two digits (PrintNumber2), into the blank middle line of the order's name ("ADVANCE", "nn", "MILES"). Other orders jump straight to RobotMenuChoose. IX = the robot record.

The printing tail after the inline position is ShowMilesCode (`$A7DC`). No recording gave these orders; checked on the own instance: an ADVANCE of 10 miles showed "10" there.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 14 calls, 3,185 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `OrdersMenu` (tail), `ListMenu`, `Beep`, `ShowStatusPanel`, `ClearPanel` |
| Reads | `$DA0B`-`$DA5B` (`Robots`); `$FD1F` (`work space $FD1F+`) |
| Writes | `$DA06`-`$DA5A` (`Robots`); `$FD1F` (`work space $FD1F+`); `$FD30`-`$FD39` (`work space $FD30+`) |

### `ShowMilesCode` (`$A7DC`)

**Code the recordings never ran: LD A,(IX+`$0E`); SRL A; CALL `$D3E5`**

The tail of ShowOrderMiles after its inline position: A = +`$0E` / 2 (the miles, stored doubled), printed with two digits and a leading space by PrintNumber2. Falls into RobotMenuChoose. Run for orders 1 and 2 (seen on the own instance; no recording got here).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RobotMenuChoose` (`$A7E4`)

**Robot menu: choose an item and run it; LEAVE ROBOT closes the menu**

Prints the strength, runs ListMenu on the four items (HL = `$5837`, the attribute of row 1 column 23, E = 5, A = MenuCursor) and keeps the choice in MenuCursor, so the menu reopens on it. 1 DIRECT CONTROL (`$A93B`), 2 GIVE ORDERS (OrdersMenu), 3 COMBAT MODE (CombatMenu `$AC00`), 4 LEAVE ROBOT: a beep, +`$06` = 0, +`$0A` = 0 (the robot carries on with its order), the auto-climb `$FD30` = 5 turns so the ship rises off the robot and the menu does not reopen, then CloseRobotMenu.

CloseRobotMenu (`$A812`) clears the panel, sets `$FD39` = 0 and redraws the status panel (ShowStatusPanel); ListMenu also jumps there when the robot is destroyed while its menu is open (seen: freeing +`$01` under the open menu closed it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowStrength` (`$A81D`)

**Robot menus: print STRENGTH and the robot's strength in %**

Prints "STRENGTH" at (22,23) and the value of +`$0C` at (23,25), three digits with leading spaces and "%" (a robot is born with 100). A negative +`$0C` (a dying robot, UpdateRobot counts it up) shows as 0 % (poked `$80`: "0%"). Called once a turn by every robot menu loop. IX = the robot record.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 111 calls, 1,887 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose`, `ListMenu` |
| Calls | `PrintInline` |

### `ShowStrengthValue` (`$A833`)

**Print the strength +`$0C` as "nnn%"**

The tail of ShowStrength after its inline string: a negative strength is shown as 0; PrintNumber3 prints HL with three digits, E = `$20` makes the leading zeros spaces; the "%" goes out through PrintCharKeep.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 111 calls, 9,435 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber3`, `PrintCharKeep` (tail) |
| Reads | `$DA0C`-`$DA5C` (`Robots`) |

### `DirectControlItem` (`$A93B`)

**Robot menu item 1: direct control, then the robot menu again**

Calls DirectControl (drive the robot until fire, or until it is destroyed) and redraws the robot menu with RobotMenuShow. MenuCursor still holds 1, so the menu reopens on DIRECT CONTROL. A robot destroyed while driven: DirectControl returns, RobotMenuShow redraws, and ListMenu then sees +`$01` = 0 and closes the menu. Not run in the recordings; run on the own instance.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DirectControl` (`$A941`)

**Drive the robot with the controls until fire**

+`$0A` = 2 and +`$05` = 0, then a loop of game turns without the ship's own move: WorldTurn moves the robot from Input (`$B184` -> `$B450`) and calls MoveShip from there (`$B4A8`), so the ship travels on the robot; DrawView draws the view, MenuRadarTick blinks the ship on the radar, GameTurn, ShowStrength. Fire gives the robot back (+`$0A` = 1, a beep) and returns. Returns at once (Z) when the robot is destroyed (+`$01` = 0).

Used by the robot menu (item 1) and by the combat menu (MOVE ROBOT, `$AC93`). Not run in the recordings. On the own instance: +`$0A` went to 2, holding right turned the robot (+`$08` 4 -> 1) and moved it one column, the ship's ShipX followed (22 -> 23); fire set +`$0A` back to 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OrdersMenu` (`$A971`)

**GIVE ORDERS: the five orders**

Clears the panel and prints SELECT ORDERS at (4,24) and the five items from (7,23): STOP AND DEFEND, ADVANCE ?? MILES, RETREAT ?? MILES, SEARCH & DESTROY, SEARCH & CAPTURE. Falls into OrdersMenuChoose.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7 calls, 238 t-states own (0.00 %) |
| Called from | `ShowOrderMiles` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

### `OrdersMenuChoose` (`$A9EC`)

**GIVE ORDERS: choose; stop at once, advance / retreat ask the miles, search asks the target**

ListMenu at HL = `$5897` (row 4: item 1 at row 7), E = 6, A = 1. Item 1 sets order 0 (stop and defend) and returns to the robot menu. Items 2 and 3 set order 1 (advance) or 2 (retreat) and go on to the distance menu (DistanceMenu, `$AA19` on). Items 4 and 5 go to TargetMenu with the flags of CP 3 (Z = SEARCH & DESTROY).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7 calls, 903 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `TargetMenu` (tail), `ListMenu`, `WaitRelease` |

### `AdvanceJump` (`$AA2D`)

**Code the recordings never ran: JR `$AA40`, past the RETREAT title**

The last instruction of the ADVANCE branch of OrdersMenuChoose: after the "ADVANCE " title it jumps over RetreatTitle into DistanceMenu, the part both orders share. Not run in the recordings; seen on the own instance.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RetreatTitle` (`$AA2F`)

**GIVE ORDERS, RETREAT: the title of the distance menu**

The RETREAT branch of OrdersMenuChoose: prints "RETREAT " at (5,23), attribute `$4F`, then falls into DistanceMenu. The order (+`$0B` = 2) is already stored.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DistanceMenu` (`$AA40`)

**Code the recordings never ran: CALL PrintInline, the distance menu's texts**

The distance menu of ADVANCE and RETREAT, shared by both: its texts "?? MILES" (the next line under the title), SELECT DISTANCE at (9,23), "0 MILES" at (13,24); then falls into DistanceSelect. Not run in the recordings; on the own instance: up 3 times, down once, fire = 10 miles, +`$0E` = 20, +`$0B` = 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DistanceSelect` (`$AA6E`)

**Code the recordings never ran: choose the miles, 0-50 by 5**

D = the miles, from 0. Each pass of DistanceLoop is one game turn (ShowStrength, WorldTurn, DrawView, MenuRadarTick, GameTurn); a destroyed robot (+`$01` = 0) closes the whole menu (JP CloseRobotMenu). Then WaitKey: fire goes to DistanceFire; up adds 5, down takes 5 (up wins when both are held); a value out of 0-50 (CP `$33`, a negative one wraps above it) is refused. A change is printed at (13,23), attribute `$46`, by DistanceShow with the click `$14`. No release wait: a held key steps once a game turn.

DistanceFire: +`$0E` = miles x 2; 0 miles turns the order back into 0 (stop and defend); the beep `$78`, WaitRelease, back to the robot menu. Not run in the recordings; run on the own instance.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DistanceShow` (`$AAAD`)

**the miles in D printed (PrintNumber2), a click, back to the distance loop**

The tail of DistanceSelect after the inline position (13,23): prints D, the miles, with two digits (PrintNumber2), clicks (Beep `$14`) and goes back to DistanceLoop for the next game turn. DistanceFire (`$AAB8`) follows: the end of the distance menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TargetMenu` (`$AACF`)

**SEARCH & DESTROY or SEARCH & CAPTURE: the three targets**

Z (the destroy item): clears the panel and prints SEARCH & DESTROY, SELECT TARGET and ENEMY ROBOTS / ENEMY FACTORYS / ENEMY WARBASES; NZ goes to CaptureMenu.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7 calls, 191 t-states own (0.00 %) |
| Called from | `OrdersMenuChoose` (tail) |
| Calls | `CaptureMenu` (tail), `ClearPanel`, `PrintInline` |

### `DestroyMenuChoose` (`$AB3D`)

**SEARCH & DESTROY: choose the target, orders 3-5**

ListMenu at HL = `$5937` (item 1 at row 12), E = 4, A = 1; the item + 2 is the order (3 robots, 4 factories, 5 warbases) for SetOrder.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3 calls, 231 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `SetOrder` (tail), `ListMenu` |

### `CaptureMenu` (`$AB4E`)

**SEARCH & CAPTURE: the three targets**

Prints SEARCH & CAPTURE, SELECT TARGET and NEUTRAL FACTORYS / ENEMY FACTORYS / ENEMY WARBASES.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 4 calls, 136 t-states own (0.00 %) |
| Called from | `TargetMenu` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

### `CaptureMenuChoose` (`$ABB9`)

**SEARCH & CAPTURE: choose the target, orders 6-8**

The same list as DestroyMenuChoose; the item + 5 is the order (6 neutral factories, 7 enemy factories, 8 enemy warbases).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 4 calls, 260 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `SetOrder`, `ListMenu` |

### `SetOrder` (`$ABC8`)

**Store a search order, look for its first target, or fall back to stop**

A = the order (3-8) into +`$0B`. Orders 4 and 5 (destroy factories, warbases) need the nuclear bomb (+`$07` bit 6); without it the order becomes 0. Otherwise `$FD51` = 0 (our side), +`$0E` = `$FF` and FindTargetBuilding looks for a target of the order from the robot's X (+`$02`/+`$03`): D, the index it found, goes to +`$0E`; no target (Z) makes the order 0. A beep, WaitRelease, back to the robot menu. Ran 7 times in the recording (destroy robots, capture neutral and enemy factories).

CombatMenu (`$AC00`) follows in the same block: the robot menu's item 3.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7 calls, 1,680 t-states own (0.00 %) |
| Called from | `DestroyMenuChoose` (tail), `CaptureMenuChoose` |
| Calls | `RobotMenuShow` (tail), `WaitRelease`, `FindTargetBuilding`, `Beep` |
| Reads | `$DA02`-`$DA53` (`Robots`) |
| Writes | `$DA0B`-`$DA5E` (`Robots`); `$FD51` (`work space $FD51+`) |

### `CombatMenuCode` (`$AC7C`)

**Code the recordings never ran: the combat menu**

The code after CombatMenuText: the strength, then ListMenu on the six items (HL = `$5837`, E = 7), STOP COMBAT highlighted first. Each choice comes back to CombatMenuLoop with A = the item, so the menu reopens on it.

6 STOP COMBAT: back to the robot menu. 5 MOVE ROBOT: DirectControl, then the menu again. 1-4 need the weapon: +`$07` rotated left item + 1 times leaves in carry bit 6 (nuclear), 5 (phasers), 4 (missiles) or 3 (cannon); without it the low buzz (`$FA`) and the menu again.

1 NUCLEAR BOMB: IY = IX, NuclearBlast, then the menu closes (JP CloseRobotMenu): the bomb destroys the robot carrying it. 2-4: shot record 0 at `$D7D3` (Shots); if it is free (+`$01` = 0), A = 5 - item (3 phasers, 2 missiles, 1 cannon) and FireShot launches it from the robot along its facing (+`$08`), then DrawView and GameTurn; a shot of record 0 still flying buzzes.

No recording entered COMBAT MODE. Seen on the own instance: FIRE CANNON on a bipod + cannon robot wrote +`$05` = 4 (the robot's facing), +`$06` = 5, +`$07` = 1, +`$08` = `$0A` into `$D7D3`; FIRE MISSILES without missiles changed nothing.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ListMenu` (`$ACD7`)

**a list menu: HL the attribute of item 0 (an item every 3 rows), E the items + 1, A the first highlighted; down / up move, fire returns A**

Each pass is one game turn (WorldTurn, DrawView, MenuRadarTick, GameTurn, ShowStrength): the game goes on while a menu waits. A destroyed robot (+`$01` = 0) drops ListMenu's return address and closes the robot menu (CloseRobotMenu). Up / down move by one item (items 1 to E - 1) with a click `$14`; fire paints the item `$4F`, beeps `$64` and returns A. Attributes: `$4D` normal, `$4E` highlighted, `$4F` chosen. Needs IX = a robot record.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 28 calls, 36,032 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose` |
| Calls | `ShowStrength`, `PaintMenuItem`, `WaitRelease`, `GameTurn`, `MenuRadarTick`, `WorldTurn`, `Beep`, `DrawView`, `WaitKey` |
| Reads | `$DA01`-`$DA51` (`Robots`); `$FD0C` (`work space $FD0C+`) |

### `PaintMenuItem` (`$AD3C`)

**Colour list item A: 2 rows of 8 attributes with C**

HL = the attribute of item 0; item A starts `$60` bytes (3 rows) further per item. Fills 8 attributes, moves down a row (`$18` more) and fills 8 more with C (`$4D` normal, `$4E` highlighted, `$4F` chosen). A must be 1 or more. Keeps DE and HL.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 166 calls, 32,974 t-states own (0.00 %) |
| Called from | `ListMenu` |
| Calls | `FillAttributes`, `AddAToHL` |

### `WaitRelease` (`$AD57`)

**wait until no control is held**

Calls WaitKey until Input is 0: every control up. Used by every menu before it reads a new press, so the fire that chose an item does not choose again. Keeps BC and HL; A = 0 on return. Uses WaitKey, so key 1 still pauses.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 42 calls, 3,360 t-states own (0.00 %) |
| Called from | `OrdersMenuChoose`, `SetOrder`, `ListMenu` |
| Calls | `WaitKey` |

## gameturn

`src/game/gameturn.asm`

### `GameTurn` (`$AD62`)

**One game turn: the random step, the clock, the daily production, the clock print**

Called once a pass by PlayLoop and by every robot menu loop (3414 times in the recording). Random steps the random generator `$FD00-$FD03`. Clock (`$FD35` minutes, `$FD36` hours, `$FD37-$FD38` days) gains 5 minutes a turn: 60 minutes make an hour, 24 hours a day, and a new day runs DailyProduction. Then the clock print: days at (0,27), five digits with leading spaces; "HH.MM" on the next line. Goes on in GameTurnEnd.

| | |
| --- | --- |
| Runs (the first recording's game window) | 367 calls, 32,328 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,414 calls, 301,068 t-states own (0.01 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu` |
| Calls | `DailyProduction`, `Random`, `PrintInline` |
| Reads | `$FD35`-`$FD38` (`work space $FD35+`) |
| Writes | `$FD35`-`$FD38` (`work space $FD35+`) |

### `GameTurnEnd` (`$AD90`)

**Game turn, second half: the clock print, the game end, captures, the frame pacing**

The second half of GameTurn, reached after the PrintInline of ClockPos (setting the print position (0,27) and attribute `$57`). Prints the days (PrintNumber5, five digits with leading spaces) and, a line down (PrintNewline), the hours "." the minutes (PrintNumber2Zero, two digits with zeros). Then CheckGameEnd: a side with no warbase ends the game here.

Captures: the 28 capture points at `$FD70` (5 bytes each: X 2 bytes, Y, owner and type, count; points 0-3 the warbases, 4-27 the factories) are checked each turn. While map bit 6 is set on a point's door cell (an anchor stands there) its count +4 goes up; at 144 (`$90`) FindRobot takes the robot there and its side (+`$0A` bit 7) captures the building: GiveWarbase for a warbase, GiveFactory (point - 4) for a factory. A door anchor that is no robot (probably a flying shot) captures nothing; the count still starts again. An empty door resets the count. The recording shows every capture after a count of 121-143 at the 250-frame samples. Any robot captures, whatever its order. After a capture CountBases recounts the buildings and UpdateStatusPanel reprints the status.

Last, the pacing (TurnPace): waits until PlayInterrupt has counted 10 frames in TurnFrames (`$FD34`) since the last turn, then clears it. A turn is at least 10 frames: an hour 120, a game day 2880 (about 58 s). Keeps IY (pushed around the loop); A, BC, DE, HL lost.

| | |
| --- | --- |
| Runs (the first recording's game window) | 367 calls, 32,603,387 t-states own (12.11 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,413 calls, 188,090,433 t-states own (7.47 %) |
| Called from | `PrintInline` |
| Calls | `CheckGameEnd`, `CountBases`, `GiveFactory`, `MapCell`, `FindRobot`, `UpdateStatusPanel`, `PrintNumber2Zero`, `PrintNumber5`, `PrintCharKeep`, `PrintNewline` |
| Reads | `$DA0A` (`Robots`); `$DBAA` (`EnemyRobots`); `$DC1A` (`EnemyRobots`); `$DC3A` (`EnemyRobots`); `$DC9A` (`EnemyRobots`); `$DCBA` (`EnemyRobots`); 11 more ranges |
| Writes | `$FD34` (`work space $FD34+`); `$FD74`-`$FDFB` (`work space $FD74+`); `$FFF2`-`$FFFD` (`work space $FFF2+`) |

### `UnusedTapeCode` (`$AE29`)

**Unreferenced code: keys 6 and 7 together jump into the tape ROM**

15 bytes of code nothing calls or jumps to: LD A,`$EF`; IN A,(`$FE`); AND `$18`; RET NZ (unless 6 and 7 are both held); LD HL,`$A600`; PUSH HL; DI; JP `$04B0`. `$04B0` is inside an instruction of the 48K ROM's SAVE code; with Start as the return address it looks like a debugging leftover (a memory dump to tape). Never runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DailyProduction` (`$AE38`)

**A new day: each side's buildings add to its resources**

Our side from `$FD3A` into Resources, the enemy from `$FD42` into `$FD4A` (ProduceSide), then the panel reprint (UpdateStatusPanel). Ran 11 times in the recording, once a game day.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 101 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 11 calls, 1,111 t-states own (0.00 %) |
| Called from | `GameTurn` |
| Calls | `ProduceSide`, `UpdateStatusPanel` |

### `ProduceSide` (`$AE4E`)

**One side's production: 5 general a warbase, 2 a factory of each kind**

DE = the side's building counts (warbases, then the factories of electronics, nuclear, phasers, missiles, cannon, chassis), HL = its 7 resources (general first, then the same order). General += 5 x warbases; each other resource += 2 x the factories of its kind; every resource stops at 99. In the recording the general resource grew by 5 a day with one warbase, electronics by 2 with one factory.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 740 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 22 calls, 8,140 t-states own (0.00 %) |
| Called from | `DailyProduction` |
| Calls | `AddCapped` |
| Reads | `$FD3A`-`$FD48` (`work space $FD3A+`) |

### `AddCapped` (`$AE62`)

**(HL) += A, at most 99**

(HL) += A, at most 99: the resource store of ProduceSide. HL is kept, so ProduceSide walks the 7 resources with INC HL. A = the new value. Used only by ProduceSide.

| | |
| --- | --- |
| Runs (the first recording's game window) | 14 calls, 602 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 154 calls, 6,622 t-states own (0.00 %) |
| Called from | `ProduceSide` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`); `$FD4A`-`$FD50` (`work space $FD4A+`) |
| Writes | `$FD22`-`$FD28` (`work space $FD22+`); `$FD4A`-`$FD50` (`work space $FD4A+`) |

### `CheckGameEnd` (`$AE6B`)

**The end of the game: the enemy has no warbase (won) or we have none (lost)**

`$FD42` (the enemy's warbases) = 0: GameWon. Else `$FD3A` (ours) = 0: GameStop, "YOU HAVE NO BASES LEFT / BETTER LUCK NEXT TIME!" at (22,0), then the common end at `$AEEA`. Both tested by poking the counts on the own instance (the messages showed, the handler became StartInterrupt, fire went back to the title menu).

| | |
| --- | --- |
| Runs (the first recording's game window) | 367 calls, 19,084 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,414 calls, 177,623 t-states own (0.01 %) |
| Called from | `GameTurnEnd` |
| Reads | `$FD3A`-`$FD42` (`work space $FD3A+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF2`-`$FFFB` (`work space $FFF2+`) |

### `LostJump` (`$AEAF`)

**Code the recordings never ran: JR `$AEEA`, the common end**

Code the recordings never ran: the lost path goes on here after PrintInline has printed LostText: JR GameOverWait, the end shared with GameWon.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GameWon` (`$AEB1`)

**The enemy has no warbase left: "INSIGNIANS DESTROYED / YOU HAVE WON !"**

Stops play (GameStop), prints the message at (22,0) and falls into the common end at `$AEEA`: a low buzz, 100 frames, WaitRelease, then the first control (Input not 0, the chosen keys or stick only) goes back to Start and the title menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GameOverWait` (`$AEEA`)

**Code the recordings never ran: the end of a won or lost game**

LD A,`$FA`; CALL `$CCAC` (the buzz); LD B,100; HALT; DJNZ (2 s); CALL WaitRelease; CALL WaitKey until a control is held; JP Start.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GameStop` (`$AF00`)

**Stop play: give the panel back to the status and switch to the idle interrupt**

`$FD39` = 0, clears the panel, prints the status panel (ShowStatusPanel), Handler = StartInterrupt (no frame count, no radar). Used by both ends of the game.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## ship

`src/game/ship.asm`

### `MoveShip` (`$AF11`)

**the ship's move from Input: X by right / left, Y by down / up, each refused by CheckShipMove**

Also the auto-climb (ClimbTurns), the altitude (fire +2 up to `$30`, else -1 down to what stands under the ship), the view follow (ViewX moves when the ship is at view column 13 or 22), the radar window (ScrollRadar) and the ship's mark: map bit 7 cleared on the old cell (`$B01D`) and set on the new one (`$B024`), the radar blip XORed. Called by PlayLoop, and by UpdateRobot (`$B4A8`) while a robot is under direct control.

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 187,699 t-states own (0.07 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,332 calls, 1,199,402 t-states own (0.05 %) |
| Called from | `NewGameSetup`, `PlayLoop` |
| Calls | `ScrollRadar`, `LiftShipFromMap`, `PutShipOnMap`, `CheckShipMove` |
| Reads | `$FD0A`-`$FD1E` (`work space $FD0A+`); `$FD30` (`work space $FD30+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD06`-`$FD1E` (`work space $FD06+`); `$FD30` (`work space $FD30+`); `$FFFC`-`$FFFD` (`work space $FFFC+`) |

### `ScrollRadar` (`$AFE6`)

**Move the radar window by 64 columns when the ship nears its edge**

The radar shows 128 map columns: from column `$FD1B` x 8 (`$FD1C` = the same as a column, 16 bits). With A = ShipX / 8 - `$FD1B`: below 2 (the ship within 16 columns of the left edge) the window moves 8 units left, unless it is at 0; 14 and more moves it 8 units right, at most to `$30` (columns 384-511). A move sets `$FD52` = 1: the radar bitmap is rebuilt from the map by BuildRadar at the ship's next mark (`$B029`). Called by MoveShip every turn (3332 times).

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 39,940 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,332 calls, 356,524 t-states own (0.01 %) |
| Called from | `MoveShip` |
| Reads | `$FD0E`-`$FD1B` (`work space $FD0E+`) |

### `LiftShipFromMap` (`$B01D`)

**clear the ship's occupant bit in its map cell, toggle its radar dot**

Called by MoveShip first thing each game turn, before the ship moves: the cell under the ship (ShipCell: `$DD00` + `$200` * ShipY + ShipX) loses bit 7, the occupant bit robots test (FreeDirections) when the ship hangs lower than their top, and the ship's dot on the radar is toggled off when it is on (BlinkShipDot). PutShipOnMap undoes both after the move.

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 16,192 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,332 calls, 146,608 t-states own (0.01 %) |
| Called from | `MoveShip` |
| Calls | `BlinkShipDot` (tail), `ShipCell` |
| Reads | `$DF0E`-`$E110` (`Map`); `$E30E`-`$E716` (`Map`); `$E90E`-`$EB18` (`Map`); `$ED0E`-`$ED18` (`Map`); `$EF0E`-`$F31A` (`Map`); `$F50E`-`$F519` (`Map`); 2 more ranges |
| Writes | `$DF0E`-`$E110` (`Map`); `$E30E`-`$E716` (`Map`); `$E90E`-`$EB18` (`Map`); `$ED0E`-`$ED18` (`Map`); `$EF0E`-`$F31A` (`Map`); `$F50E`-`$F519` (`Map`); 2 more ranges |

### `PutShipOnMap` (`$B024`)

**set the ship's occupant bit in its new map cell, rebuild the radar if the window moved, toggle the ship's dot**

Called at the end of MoveShip (and by BuildMap). Sets bit 7 of the ship's cell, then goes on into RefreshRadar. Recording: 3333 calls, once a game turn.

| | |
| --- | --- |
| Runs (the first recording's game window) | 369 calls, 22,538 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,333 calls, 106,656 t-states own (0.00 %) |
| Called from | `MoveShip`, `BuildMap` |
| Calls | `RefreshRadar`, `BlinkShipDot`, `ShipCell`, `BuildRadar` |
| Reads | `$DF0E`-`$E110` (`Map`); `$E30E`-`$E716` (`Map`); `$E90E`-`$EB18` (`Map`); `$ED0E`-`$ED18` (`Map`); `$EF0E`-`$F31A` (`Map`); `$F50E`-`$F519` (`Map`); 3 more ranges |
| Writes | `$DF0E`-`$E110` (`Map`); `$E30E`-`$E716` (`Map`); `$E90E`-`$EB18` (`Map`); `$ED0E`-`$ED18` (`Map`); `$EF0E`-`$F31A` (`Map`); `$F50E`-`$F519` (`Map`); 3 more ranges |

### `RefreshRadar` (`$B029`)

**rebuild the radar when RadarDirty is set, then blink the ship's dot**

RadarDirty (`$FD52`) is set when the window moved (`$B017`) and by other code that changes the map (the start, a loaded game). BuildRadar then redraws both radar layers `$D800` / `$D900` from the map (a pixel for every cell of type `$0F` or more, the high ground) and plots every live robot's dot; the flag is cleared. Falls into BlinkShipDot. Also reached from MenuRadarTick.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,416 calls, 99,093 t-states own (0.00 %) |
| Called from | `PutShipOnMap`, `MenuRadarTick` (tail) |
| Calls | `BlinkShipDot`, `BuildRadar` |
| Reads | `$FD52` (`work space $FD52+`) |
| Writes | `$FD52` (`work space $FD52+`) |

### `BlinkShipDot` (`$B036`)

**on odd ticks toggle the ship's 2x2 dot on the radar's player layer**

RadarBlink (`$FD1E`) counts the game turns (MoveShip increments it between LiftShipFromMap and PutShipOnMap, MenuRadarTick in the menus). When it is odd, ToggleRadarDot XORs a 2x2 dot at (ShipX, ShipY) into the layer B = 0 (`$D800`, shown with attribute `$4D` by PlayInterrupt in alternate frames). Off-window positions draw nothing (RadarDotAddress). The pairs of toggles around each move leave the dot on every other turn: the ship's dot blinks.

| | |
| --- | --- |
| Runs (the first recording's game window) | 737 calls, 39,039 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 6,831 calls, 362,040 t-states own (0.01 %) |
| Called from | `LiftShipFromMap` (tail), `PutShipOnMap`, `RefreshRadar`, `MenuRadarTick` |
| Calls | `ToggleRadarDot` (tail) |
| Reads | `$FD0D`-`$FD1E` (`work space $FD0D+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF2`-`$FFF3` (`work space $FFF2+`) |

### `MenuRadarTick` (`$B048`)

**one blink step of the ship's dot while a menu is open**

Called by the robot menu loop (DirectControl) and ListMenu each pass, so the world goes on and the ship's dot keeps blinking while the player sits in a menu: toggles the dot (BlinkShipDot), advances RadarBlink, rebuilds the radar if needed and toggles again on the new tick (RefreshRadar). 83 calls in the deep recording.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 83 calls, 3,984 t-states own (0.00 %) |
| Called from | `ListMenu` |
| Calls | `RefreshRadar` (tail), `BlinkShipDot` |
| Reads | `$FD1E` (`work space $FD1E+`) |
| Writes | `$FD1E` (`work space $FD1E+`) |

### `CheckShipMove` (`$B052`)

**carry: the ship may not stand at HL (X), A (Y)**

Tests a place for the ship: HL = the column X, A = the row Y. C = the highest top under the ship's 2 x 2 footprint (X, Y), (X+1, Y), (X, Y-1), (X+1, Y-1): the terrain height of each cell and the top of any robot (+`$09` + +`$0D`) or building (BuildingTops) anchored there (CellTop); then ObjectTop alone on (X-1, Y-1), (X-1, Y) and, inside the map, the row Y+1 (X-1 to X+1), whose anchored objects reach into the footprint.

Out: carry set when Altitude < C (the ship would be inside something there), C = the top, HL = X kept; B kept (ObjectTop saves BC), DE and A lost, IY may point at the robot or building found. Called by MoveShip for the X move (MoveShipX), the Y move (ShipCheckY) and, with the ship's own place, by Sink to get the floor under the ship.

| | |
| --- | --- |
| Runs (the first recording's game window) | 377 calls, 113,477 t-states own (0.04 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 2,372 calls, 713,972 t-states own (0.03 %) |
| Called from | `MoveShip` |
| Calls | `CellTop`, `ObjectTop`, `MapCell` |
| Reads | `$FD10` (`work space $FD10+`) |

### `TerrainTop` (`$B08A`)

**C = max(C, the ground height of the terrain type at DE)**

DE a map cell. The cell's type (bits 0-4) indexes the ground height table TerrainHeights `$D7BC` (00 00 02 02 02 02 03 03 06 06 06 06 00 00 00 07 0F 07 0F ...: types 2-5 height 2, 6-7 (the wreck a destroyed robot leaves) 3, 8-`$0B` 6, `$0F`/`$11` 7, `$10`/`$12` 15). Keeps the higher of it and C (KeepHigher). Used by CheckShipMove (through CellTop) and GroundUnderFootprint; 39396 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,848 calls, 110,880 t-states own (0.04 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 39,396 calls, 2,364,045 t-states own (0.09 %) |
| Called from | `CellTop`, `GroundUnderFootprint` |
| Calls | `KeepHigher` (tail), `AddAToHL` |
| Reads | `$D7BC`-`$D7CD` (`TerrainHeights`); `$DD0E`-`$DD14` (`Map`); `$DD67`-`$DE66` (`Map`); `$DE8C`-`$DECD` (`Map`); `$DF0E`-`$FCE8` (`Map`, `MapTail`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFE6`-`$FFEF` (`work space $FFE6+`) |

### `CellTop` (`$B096`)

**C = max(C, the ground and the object on cell DE)**

TerrainTop, then falls into ObjectTop: the highest point of a cell, used for the 2x2 footprint in CheckShipMove.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,508 calls, 25,636 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,488 calls, 161,296 t-states own (0.01 %) |
| Called from | `CheckShipMove` |
| Calls | `TerrainTop` |

### `ObjectTop` (`$B099`)

**C = max(C, the top of a robot or a building anchored at cell DE)**

When the cell has bit 6 (an object anchored there): a robot (FindRobot) counts with its body height +`$09` plus the ground under it +`$0D`; else a building (FindBuilding) with its height from BuildingTops by type. A cell with bit 6 that is neither (a shot) counts nothing. B and C are kept.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,885 calls, 106,362 t-states own (0.04 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 11,860 calls, 698,111 t-states own (0.03 %) |
| Called from | `CheckShipMove` |
| Calls | `KeepHigher`, `FindRobot`, `FindBuilding`, `AddAToHL` |
| Reads | `$B0C1`-`$B0C8` (`BuildingTops`); `$DA09`-`$DA5D` (`Robots`); `$DD0D`-`$DD14` (`Map`); `$DF0D`-`$DF14` (`Map`); `$E10D`-`$E919` (`Map`); `$EB0D`-`$EB19` (`Map`); 5 more ranges |

### `KeepHigher` (`$B0AB`)

**C = max(C, A)**

The common tail of TerrainTop and ObjectTop.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,857 calls, 46,517 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 39,745 calls, 994,692 t-states own (0.04 %) |
| Called from | `TerrainTop` (tail), `ObjectTop` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFEE`-`$FFEF` (`work space $FFEE+`) |

## world

`src/game/world.asm`

### `WorldTurn` (`$B0CA`)

**one game turn of the world: the enemy commander, every robot, every shot**

Called once a game turn by the play loop (PlayLoop) and by the menus (DirectControl, ListMenu), so robots fight and walk on while the player chooses: 3415 calls in 36046 frames, a turn is about 10 frames. First EnemyCommander (one enemy slot built or re-ordered), then UpdateRobot for each of the 48 robot records `$DA00` whose +`$01` is not 0, then UpdateShot for each of the 5 shot records of 9 bytes at `$D7D3` whose +`$01` is not 0. Robots and shots are taken in slot order, the player's slots 0-23 first. Shot record 0 (`$D7D3`) is the one the player fires from the robot menu's COMBAT MODE (DirectControl -> FireShot); the robots use records 1-4 (FindFreeShot).

[Animation: `WorldTurn` at work](img/routines/WorldTurn.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 1,822,026 t-states own (0.68 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,415 calls, 17,199,406 t-states own (0.68 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu` |
| Calls | `UpdateRobot`, `UpdateShot`, `EnemyCommander` |
| Reads | `$D7D4`-`$D7F8` (`Shots`); `$DA01`-`$DCF1` (`Robots`, `EnemyRobots`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF2`-`$FFFD` (`work space $FFF2+`) |

### `UpdateRobot` (`$B0FA`)

**one robot's game turn: dying, destroyed or a step of its AI**

IY = the robot record. Strength +`$0C` decides: positive, the robot acts (RobotStep); negative, the robot is dying: +`$0C` counts up from `$FC` (set by MoveShot's hit) and the object bit 6 of its cell is toggled each turn (cleared on even values, set on odd), so for four turns other robots and shots see it only every other turn; 0, the robot is destroyed (RobotDestroyed). 49165 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 844 calls, 33,760 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 49,165 calls, 11,200,217 t-states own (0.44 %) |
| Called from | `WorldTurn` |
| Calls | `RobotStep` (tail), `SteerByOrder`, `TurnOrStep`, `CountDirections`, `FreeDirections`, `SetStepDelay`, `SpotEnemies`, `FindFreeShot`, `FireShot`, `CountRobots`, `PutBlock`, `PlaceRobot` (tail), `UpdateStatusPanel`, `Random`, `ToggleRadarDot` |
| Reads | `$DA00`-`$DA5F` (`Robots`); `$DB80`-`$DBEF` (`EnemyRobots`); `$DC00`-`$DC5F` (`EnemyRobots`); `$DC70`-`$DCCF` (`EnemyRobots`); `$DCE0`-`$DCFF` (`EnemyRobots`); `$DD97`-`$DD99` (`Map`); 7 more ranges |
| Writes | `$DA01`-`$DA5F` (`Robots`); `$DB81`-`$DBAF` (`EnemyRobots`); `$DBC5`-`$DBEF` (`EnemyRobots`); `$DC05`-`$DC5F` (`EnemyRobots`); `$DC71`-`$DCCF` (`EnemyRobots`); `$DCE5`-`$DCFF` (`EnemyRobots`); 8 more ranges |

### `RobotStep` (`$B154`)

**a live robot: wait for its step delay, then look, fire, steer and move one step**

Entered from UpdateRobot with strength > 0 (JP P). A robot the player sits on (+`$0A` = 1, the robot menu is open) does nothing. Side (`$FD51`) = 0 ours / 1 the enemy's (+`$0A` bit 7), read by the target searches. The step delay +`$0F` counts the turns down; at 0 the robot leaves its cell (bit 6 cleared, radar dot erased) and FreeDirections gives C, the directions it can step to (bit 0 right, 1 left, 2 down, 3 up, the Input order).

Direct control (+`$0A` = 2): the stick decides (RobotDirectControl). Otherwise SpotEnemies gives E, the directions with a live opponent in sight. An opponent ahead (E AND the facing +`$08`): the robot moves on if it can and fires when a shot record of its side is free and its weapons allow (FindFreeShot, FireShot; a shot stops it for this step). An opponent to a side: it turns to it (+`$05` = that direction, one picked at random among several, +`$06` = 2). No opponent: it keeps its direction +`$05` for +`$06` more steps while that direction stays free, else it takes a new course for 3-6 steps from SteerByOrder (RobotNewCourse). RobotMove then turns or steps, reloads the delay (SetStepDelay) and puts the robot back on the map (PlaceRobot: the record's x/y/cell, bit 6, the dot).

Recording: 9652 steps; the shot records and strengths at frames 18680-18850 match FireShot and MoveShot (robot 2 hit twice by an enemy missile, 100 -> 70 -> 40; robot 25 hit by our cannon, 100 -> 80 -> 60 -> 40).

[Animation: `RobotStep` at work](img/routines/RobotStep.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 844 calls, 151,768 t-states own (0.06 %) |
| Called from | `UpdateRobot` (tail) |
| Calls | `SteerByOrder`, `TurnOrStep`, `CountDirections`, `FreeDirections`, `SetStepDelay`, `SpotEnemies`, `PlaceRobot` (tail), `Random`, `ToggleRadarDot` |
| Reads | `$DB80`-`$DB8F` (`EnemyRobots`); `$DC40`-`$DC4F` (`EnemyRobots`); `$DC90`-`$DC9F` (`EnemyRobots`); `$DCB0`-`$DCBF` (`EnemyRobots`); `$E3F1` (`Map`); `$E5F1` (`Map`); 6 more ranges |
| Writes | `$DB85`-`$DB8F` (`EnemyRobots`); `$DC45`-`$DC4F` (`EnemyRobots`); `$DC95`-`$DC9F` (`EnemyRobots`); `$DCB5`-`$DCBF` (`EnemyRobots`); `$E3F1` (`Map`); `$E5F1` (`Map`); 7 more ranges |

### `SteerByOrder` (`$B222`)

**C = the direction the robot's order wants, chosen among the free ones in C**

IY the robot, C the free directions (FreeDirections); out C a single direction bit, or 0 to stand. B keeps the free set. By the order +`$0B`:

0 stop: C = 0. 1 advance / 2 retreat: right / left (RobotLeanTo). When that direction is free: two random bits for it, else a random free one other than the opposite, which may be it again (0.835 with all four free, 0.88 with up or down blocked, 1.0 in a corridor; docs/13 13.3.2). When it is blocked: any free one, the opposite included. RobotStepPos counts the distance +`$0E`.

3 destroy robots: the target is the opponent robot of index +`$0E` (TargetRobotRecord). It is kept while it lives and is less than 50 columns away; else the nearest live opponent by column distance is taken (FindNearestOpponent), none: a random free direction.

4-8 the building orders: the target is record +`$0E` of the factory table `$FD84` or the warbase table `$FD70` (TargetBuildingTable). It is kept while its owner bits are still the ones the order looks for; else the nearest such building nobody of the side is already after is taken (FindTargetBuilding). None: the robot stands, and an enemy robot falls back to destroy robots.

The aim (RobotAim): D = the directions toward the target, horizontal from the sign of the column difference, vertical from the row difference; for a building, while the columns differ, the row aimed at is 3 below the building's row. More than 7 columns away (the low byte of the column difference only) the robot leans horizontally like an advance (RobotLeanTo): the target's row is ignored. Closer, one of the free wanted directions at random (none free: any free one); when a horizontal one is among them, +`$06` = |dx| - 1 for whichever is picked, a vertical one too. On the target (D = 0): the destroy orders 4-5 go to the nuclear charge at NuclearBlast (outside this range); the others turn the robot to face down and stand.

Bug (experiment, breakpoint at `$B2B8` after poking the target factory's owner): FindTargetBuilding leaves HL past the table, not on the new target, so the step right after a new building target aims at the bytes below `$FDFF` (the JP at `$FDFD` and Handler: row `$66`, column `$C300`; the warbase orders read factory 0's door). The wrong decision lasts a whole course of 3-6 steps: right from column 256 on; a random free direction on columns 14-255, rows 1-8; on columns 14-255, rows 9-15 the aim is "on the target": the robot faces down and stands, and a nuclear robot with order 4 blows up where it stands (NuclearBlast; experiment in docs/13 13.3.6). The next decision aims right.

| | |
| --- | --- |
| Runs (the first recording's game window) | 62 calls, 19,223 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 2,275 calls, 1,321,359 t-states own (0.05 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `FindTargetBuilding`, `ColumnDistance`, `TargetBuildingTable`, `TargetRobotRecord`, `FindNearestOpponent`, `CountDirections`, `AddAToHL`, `Random` |
| Reads | `$DA01`-`$DA5E` (`Robots`); `$DAF1`-`$DB01` (`Robots`); `$DB81`-`$DBAE` (`EnemyRobots`); `$DBC2`-`$DC5E` (`EnemyRobots`); `$DC71`-`$DCCE` (`EnemyRobots`); `$DCE2`-`$DCFE` (`EnemyRobots`); 3 more ranges |
| Writes | `$DA06`-`$DA4E` (`Robots`); `$DB86`-`$DBAE` (`EnemyRobots`); `$DBEE` (`EnemyRobots`); `$DC06`-`$DC1E` (`EnemyRobots`); `$DC36`-`$DC5E` (`EnemyRobots`); `$DC76`-`$DCBE` (`EnemyRobots`); 2 more ranges |

### `PickOneDirection` (`$B33E`)

**C = one direction bit picked at random from the set in B**

Masks C with random bytes until exactly one bit is left (CountDirections); when nothing is left it starts again from B. B must not be 0. The common exit of SteerByOrder's branches and used by RobotTurnToEnemy for several opponents.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FindTargetBuilding` (`$B34D`)

**D = the nearest building the order wants and no teammate is after; Z when none**

A = the order (3 goes to FindNearestOpponent), HL = the robot's column, IY the robot, Side set. The order picks the table and owner (TargetBuildingTable); every record with those owner bits is offered to ConsiderBuilding, which skips it when a robot of our side with the same order already has it as its +`$0E`, and keeps the nearest by column distance (KeepNearest). Out D = the record's index (or `$FF`), A = D + 1 (Z: none). HL is left past the table: the cause of the bug noted at SteerByOrder. Recording: 112 calls (also from the enemy's order choice at `$B989` and SetOrder).

| | |
| --- | --- |
| Runs (the first recording's game window) | 7 calls, 6,435 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 112 calls, 129,789 t-states own (0.01 %) |
| Called from | `SetOrder`, `SteerByOrder`, `EnemyCommander` |
| Calls | `ConsiderBuilding`, `TargetBuildingTable`, `InitNearestSearch`, `FindNearestOpponent` (tail) |
| Reads | `$FD73`-`$FDFA` (`work space $FD73+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF2`-`$FFF3` (`work space $FFF2+`) |

### `ConsiderBuilding` (`$B36C`)

**offer building C to KeepNearest unless a teammate with the same order already targets it**

HL = the record's owner byte (+`$03`), C its index, A' the order. Scans the 24 records of our side (`$DA00` ours, `$DB80` the enemy's by Side) for a live robot whose order +`$0B` is A' and whose target +`$0E` is C. None: the record's column (+`$00`/+`$01`) goes to KeepNearest. The robot that asks is in the list too; its +`$0E` holds its old target (or `$FF`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 76 calls, 192,439 t-states own (0.07 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 894 calls, 2,137,588 t-states own (0.08 %) |
| Called from | `FindTargetBuilding` |
| Calls | `KeepNearest` |
| Reads | `$DA01`-`$DCFE` (`Robots`, `EnemyRobots`); `$FD51` (`work space $FD51+`); `$FD70`-`$FD71` (`work space $FD70+`); `$FD84`-`$FDF8` (`work space $FD84+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFE8`-`$FFF3` (`work space $FFE8+`) |

### `KeepNearest` (`$B3B3`)

**keep candidate C when the column HL is nearer to DE' than the best BC'**

The comparison step of the nearest searches (InitNearestSearch sets it up): HL' = |HL - DE'|, and when it is below BC' it becomes the best and D = C. Only the column distance counts; rows are ignored. A and HL' are lost; the main BC, E, HL and IY are kept. Called by ConsiderBuilding and FindNearestOpponent.

| | |
| --- | --- |
| Runs (the first recording's game window) | 72 calls, 7,285 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,506 calls, 330,841 t-states own (0.01 %) |
| Called from | `ConsiderBuilding`, `FindNearestOpponent` |
| Calls | `ColumnDistance` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF2`-`$FFF3` (`work space $FFF2+`) |

### `ColumnDistance` (`$B3CA`)

**HL = |HL - DE|**

HL, DE two columns (0-511). A 16-bit absolute difference: SBC HL,DE and, when the result's sign is set, 0 - HL. DE is kept; A = 0 on the positive path, the high byte's negation on the other. Used by KeepNearest and by SteerByOrder's 50-column test of a robot target.

| | |
| --- | --- |
| Runs (the first recording's game window) | 72 calls, 3,132 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 4,007 calls, 175,992 t-states own (0.01 %) |
| Called from | `SteerByOrder`, `KeepNearest` |

### `TargetBuildingTable` (`$B3D5`)

**HL, B, E = the building table, its size and the owner a building order wants**

A = the order. Orders 5 and 8 (destroy / capture warbases): HL = `$FD73`, the owner byte of the first of the 4 warbase records (Warbases `$FD70`, 5 bytes each), B = 4; the others: HL = `$FD87`, the owner byte of the first of 24 factory records (Factories `$FD84`), B = 24. E = the owner bits sought: `$20` (the computer's) for our robots, `$40` (ours) for the enemy's (Side = 1), 0 (neutral) for order 6, capture neutral factories.

| | |
| --- | --- |
| Runs (the first recording's game window) | 42 calls, 5,849 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1,731 calls, 235,279 t-states own (0.01 %) |
| Called from | `SteerByOrder`, `FindTargetBuilding`, `EnemyCommander` |
| Reads | `$FD51` (`work space $FD51+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF4`-`$FFF5` (`work space $FFF4+`) |

### `TargetRobotRecord` (`$B3F9`)

**HL = the opponent robot record of index +`$0E`**

HL = `$DB80` + 16 * (+`$0E`) for our robots, `$DA00` + 16 * (+`$0E`) for the enemy's (Side). Used by SteerByOrder's destroy-robots branch.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1,072 calls, 123,156 t-states own (0.00 %) |
| Called from | `SteerByOrder` |
| Reads | `$DA2E`-`$DA4E` (`Robots`); `$DB8E`-`$DB9E` (`EnemyRobots`); `$DBEE` (`EnemyRobots`); `$DC0E` (`EnemyRobots`); `$DC3E`-`$DC5E` (`EnemyRobots`); `$DC7E`-`$DC8E` (`EnemyRobots`); 3 more ranges |

### `InitNearestSearch` (`$B411`)

**start a nearest-by-column search from column HL**

DE' = HL (our column), BC' = `$2000` (no candidate yet), C = 0 (the first index), D = `$FF` (the result: none). Used by FindTargetBuilding and FindNearestOpponent with KeepNearest.

| | |
| --- | --- |
| Runs (the first recording's game window) | 9 calls, 567 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 535 calls, 33,705 t-states own (0.00 %) |
| Called from | `FindTargetBuilding`, `FindNearestOpponent` |

### `FindNearestOpponent` (`$B41D`)

**D = the index of the nearest live opponent robot by column; Z when none**

HL = our column, IY the robot, Side set. Runs KeepNearest over the 24 opponent records (`$DB80` the enemy's for us, `$DA00` ours for the enemy) whose +`$01` is not 0 (a dying robot counts). Out D = the slot within the side (or `$FF`), A = D + 1 (Z: none); IY is kept, B ends 0 and C 24 (the callers keep BC), DE' / BC' / HL' are the search's. Called by SteerByOrder (order 3) and, through FindTargetBuilding with A = 3, by EnemyFindTarget and SetOrder. 426 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 4,922 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 426 calls, 1,194,459 t-states own (0.05 %) |
| Called from | `SteerByOrder`, `FindTargetBuilding` (tail) |
| Calls | `KeepNearest`, `InitNearestSearch` |
| Reads | `$DA01`-`$DCF3` (`Robots`, `EnemyRobots`); `$FD51` (`work space $FD51+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFEE`-`$FFF1` (`work space $FFEE+`) |

### `RobotDirectControl` (`$B450`)

**direct control: the stick steers the robot**

Reached from RobotStep for +`$0A` = 2 (not run in the deep recording; experiment below).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TurnOrStep` (`$B471`)

**turn the robot toward direction A, or step one cell when it faces it**

IY the robot, HL its column, B its row, A a direction bit (0: nothing). Facing +`$08` not A: the robot turns, never by 180 degrees in one go (right <-> left goes through down / up, down <-> up through right / left), and +`$06` is incremented so the turn does not shorten the course. Facing A: StepPosition moves HL/B, GroundUnderFootprint sets +`$0D`, and under direct control (+`$0A` = 2) MoveShip moves the ship by the same Input and the ship sits on the robot's top (Altitude = +`$09` + +`$0D`).

Experiment (DIRECT CONTROL on a new bipod + cannon robot at (22,14)): holding right the robot turned from facing down (4) to right (1) in one step and moved one column a step (6 turns, about 60 frames); after the release it went on one more step in the same direction; the ship moved with it and Altitude stayed 17 (bipod 11 + cannon 6, ground 0).

| | |
| --- | --- |
| Runs (the first recording's game window) | 146 calls, 14,673 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,652 calls, 1,217,275 t-states own (0.05 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `StepPosition`, `GroundUnderFootprint` |
| Reads | `$DA06`-`$DA5A` (`Robots`); `$DB86`-`$DBAA` (`EnemyRobots`); `$DBC6`-`$DBEA` (`EnemyRobots`); `$DC06`-`$DC5A` (`EnemyRobots`); `$DC76`-`$DCCA` (`EnemyRobots`); `$DCE6`-`$DCFA` (`EnemyRobots`); 1 more ranges |
| Writes | `$DA06`-`$DA5D` (`Robots`); `$DB86`-`$DBAD` (`EnemyRobots`); `$DBC6`-`$DBED` (`EnemyRobots`); `$DC06`-`$DC5D` (`EnemyRobots`); `$DC76`-`$DCCD` (`EnemyRobots`); `$DCE6`-`$DCFD` (`EnemyRobots`); 1 more ranges |

### `StepPosition` (`$B4B9`)

**move HL (column) / B (row) one cell in direction A; advance / retreat count their distance**

A bit 0 right (HL+1), 1 left (HL-1), 2 down (B+1), 3 up (B-1). For the orders 1 advance and 2 retreat (not under direct control) +`$0E` is the distance still to go: a column in the order's direction (right for advance, left for retreat) takes one off and at 0 the order becomes 0 stop (+`$06` = 0); a column the other way adds one, up to `$63`.

Experiment: ADVANCE with 5 MILES (the robot menu stores miles * 2 into +`$0E` = 10): the robot went 4 columns right (+`$0E` 10 -> 6), 5 rows up round an obstacle (+`$0E` unchanged), 6 more columns right and then stood with order 0 and +`$0E` = 0.

| | |
| --- | --- |
| Runs (the first recording's game window) | 85 calls, 6,127 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7,337 calls, 534,494 t-states own (0.02 %) |
| Called from | `TurnOrStep` |
| Reads | `$DA0B`-`$DA5B` (`Robots`); `$DB8B`-`$DBAB` (`EnemyRobots`); `$DBCB`-`$DBEB` (`EnemyRobots`); `$DC0B`-`$DC5B` (`EnemyRobots`); `$DC7B`-`$DCCB` (`EnemyRobots`); `$DCEB`-`$DCFB` (`EnemyRobots`); 1 more ranges |
| Writes | `$FFF4`-`$FFF5` (`work space $FFF4+`) |

### `CountDirections` (`$B505`)

**flags of (the number of set bits in C's low nibble) - 1**

Z: exactly one direction; carry: none; neither: two or more. Counts bits 0-3 of C, keeps BC.

| | |
| --- | --- |
| Runs (the first recording's game window) | 137 calls, 21,372 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 4,938 calls, 770,442 t-states own (0.03 %) |
| Called from | `UpdateRobot`, `RobotStep`, `SteerByOrder`, `EnemyCommander` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF2`-`$FFF5` (`work space $FFF2+`) |

### `FreeDirections` (`$B513`)

**C = the directions the robot at cell HL may step to**

IY the robot, HL its anchor cell. A robot covers 2x2 cells: its anchor (X, Y) carries the object bit 6, plus (X+1, Y), (X, Y-1), (X+1, Y-1). D = the first terrain type it cannot enter, by its locomotion: bipod 8 (types 0-7, ground heights 0-3), tracks `$0C` (also 8-`$0B`, height 6), anti-grav `$0F` (also `$0C-$0E`, height 0 in TerrainHeights); the types from `$0F` (heights 7 and 15) stop all. E = the bits that block: 6 (objects) always, 7 (the ship's cell) when the ship hangs lower than the robot's top. One probe a direction (CanMoveRight, CanMoveLeft, CanMoveDown, CanMoveUp); bit 0 right, 1 left, 2 down, 3 up. 9652 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 146 calls, 49,457 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,652 calls, 3,349,343 t-states own (0.13 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `CanMoveRight`, `CanMoveLeft`, `CanMoveDown`, `CanMoveUp` |
| Reads | `$DA07`-`$DA5D` (`Robots`); `$DB87`-`$DBAD` (`EnemyRobots`); `$DBC7`-`$DBED` (`EnemyRobots`); `$DC07`-`$DC5D` (`EnemyRobots`); `$DC77`-`$DCCD` (`EnemyRobots`); `$DCE7`-`$DCFD` (`EnemyRobots`); 2 more ranges |
| Writes | `$FFF6`-`$FFF7` (`work space $FFF6+`) |

### `CanMoveRight` (`$B557`)

**Z when the robot at HL can step right**

Terrain and objects at the column it enters, (X+2, Y-1) and (X+2, Y); an object anchored at (X+2, Y+1) (its footprint would overlap) when that row exists.

| | |
| --- | --- |
| Runs (the first recording's game window) | 146 calls, 15,245 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,652 calls, 1,009,703 t-states own (0.04 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `TestCell` |
| Reads | `$E169`-`$E267` (`Map`); `$E28E`-`$E2CE` (`Map`); `$E368`-`$E467` (`Map`); `$E47B` (`Map`); `$E48E`-`$E4CE` (`Map`); `$E568`-`$E667` (`Map`); 3 more ranges |
| Writes | `$FFF2`-`$FFF3` (`work space $FFF2+`) |

### `CanMoveLeft` (`$B56F`)

**Z when the robot at HL can step left**

Terrain and objects at (X-1, Y-1) and (X-1, Y); objects anchored at (X-2, Y-1), (X-2, Y) and (X-2, Y+1).

| | |
| --- | --- |
| Runs (the first recording's game window) | 146 calls, 17,985 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,652 calls, 1,305,050 t-states own (0.05 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `TestCell` |
| Reads | `$DD65`-`$DE63` (`Map`); `$DE8B`-`$DECA` (`Map`); `$DF64`-`$E077` (`Map`); `$E08B`-`$E0CA` (`Map`); `$E144`-`$E2CA` (`Map`); `$E31B`-`$FCE5` (`Map`, `MapTail`); 1 more ranges |
| Writes | `$FFEA`-`$FFF3` (`work space $FFEA+`) |

### `CanMoveDown` (`$B58F`)

**Z when the robot at HL can step down**

Blocked at the bottom row; terrain and objects at (X, Y+1) and (X+1, Y+1); objects anchored at (X+1, Y+2), (X, Y+2) and (X-1, Y+2) when that row exists.

| | |
| --- | --- |
| Runs (the first recording's game window) | 146 calls, 21,349 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,652 calls, 1,289,615 t-states own (0.05 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `CellBlocked` (tail), `TestCell` |
| Reads | `$E366`-`$E466` (`Map`); `$E48B`-`$E4CD` (`Map`); `$E565`-`$E666` (`Map`); `$E678`-`$E67A` (`Map`); `$E68B`-`$E6CD` (`Map`); `$E745`-`$FCE8` (`Map`, `MapTail`); 1 more ranges |
| Writes | `$FFF2`-`$FFF3` (`work space $FFF2+`) |

### `CanMoveUp` (`$B5B1`)

**Z when the robot at HL can step up**

Blocked when Y-2 is above the map (the footprint already covers Y-1); an object anchored at (X-1, Y-2), terrain and objects at (X, Y-2) and (X+1, Y-2).

| | |
| --- | --- |
| Runs (the first recording's game window) | 146 calls, 16,515 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,652 calls, 1,044,460 t-states own (0.04 %) |
| Called from | `FreeDirections` |
| Calls | `CellBlocked` (tail), `TestCell` |
| Reads | `$DD65`-`$DDBB` (`Map`); `$DDDC`-`$DE3A` (`Map`); `$DE5F`-`$DE64` (`Map`); `$DE78` (`Map`); `$DE8B`-`$DECB` (`Map`); `$DF45`-`$F8E6` (`Map`); 1 more ranges |
| Writes | `$FFEA`-`$FFF3` (`work space $FFEA+`) |

### `CellOffMapFree` (`$B5C8`)

**Z: a probe that runs past the bottom row finds the way free**

The shared exit of the probes for rows below the map.

| | |
| --- | --- |
| Runs (the first recording's game window) | 33 calls, 462 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,104 calls, 43,475 t-states own (0.00 %) |
| Called from | `CanMoveRight` (tail), `CanMoveLeft` (tail), `CanMoveDown` (tail) |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF2`-`$FFF3` (`work space $FFF2+`) |

### `CellBlocked` (`$B5CA`)

**NZ: the way is blocked**

The shared exit for an unpassable terrain type or a map edge.

| | |
| --- | --- |
| Runs (the first recording's game window) | 114 calls, 1,938 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 8,059 calls, 137,022 t-states own (0.01 %) |
| Called from | `CanMoveDown` (tail), `CanMoveUp` (tail), `TestCell` (tail) |

### `TestCell` (`$B5CD`)

**Z when cell HL is passable: type below D and none of the bits E**

HL a map cell, D the first terrain type the locomotion cannot enter (FreeDirections), E the blocking bits (`$40` objects, plus `$80` the ship's cell when the ship hangs lower than the robot's top). NZ through CellBlocked when the type (bits 0-4) is D or more; else A = the cell AND E (Z: free). HL kept. Used by the four CanMove probes for the cells the footprint enters; the cells only checked for anchors use AND E directly. 67380 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,039 calls, 46,242 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 67,380 calls, 3,003,173 t-states own (0.12 %) |
| Called from | `CanMoveRight`, `CanMoveLeft`, `CanMoveDown`, `CanMoveUp` |
| Calls | `CellBlocked` (tail) |
| Reads | `$DD66`-`$DE3D` (`Map`); `$DE5F`-`$DE67` (`Map`); `$DE79`-`$DE7A` (`Map`); `$DE8B`-`$DECE` (`Map`); `$DF46`-`$FCE9` (`Map`, `MapTail`, `work space $FCE9+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF0`-`$FFF1` (`work space $FFF0+`) |

### `GroundUnderFootprint` (`$B5D6`)

**A = the highest ground under the 2x2 footprint anchored at (HL, B)**

HL a column, B a row. TerrainTop over (X, Y), (X+1, Y), (X+1, Y-1), (X, Y-1), the highest kept in C; HL and BC are kept, DE is lost (the last cell). The robots' +`$0D` (the ground they stand on: SetStepDelay's row, the drawing height, the ship's seat under direct control) and the shots' wall test (MoveShot against +`$08` = `$0A`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 85 calls, 14,960 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7,477 calls, 1,316,123 t-states own (0.05 %) |
| Called from | `TurnOrStep`, `MoveShot` |
| Calls | `TerrainTop`, `MapCell` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF0`-`$FFF3` (`work space $FFF0+`) |

### `SetStepDelay` (`$B5F3`)

**+`$0F` = the turns until the robot's next step, by the ground and its locomotion**

The ground class from +`$0D`: 0 flat, 1-3 low, 4 and more high; the column from the lowest set part bit of +`$07`: 0 bipod, 1 tracks, 2 anti-grav. StepDelays gives the turns. The recorded records agree (robot 0, a bipod on flat ground, counts 6 down).

| | |
| --- | --- |
| Runs (the first recording's game window) | 146 calls, 28,816 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,652 calls, 2,060,673 t-states own (0.08 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `AddAToHL` |
| Reads | `$B61D`-`$B625` (`StepDelays`); `$DA07`-`$DA5D` (`Robots`); `$DB87`-`$DBED` (`EnemyRobots`); `$DC07`-`$DC5D` (`EnemyRobots`); `$DC77`-`$DCCD` (`EnemyRobots`); `$DCE7`-`$DCFD` (`EnemyRobots`); 1 more ranges |
| Writes | `$DA0F`-`$DA5F` (`Robots`); `$DB8F`-`$DBAF` (`EnemyRobots`); `$DBCF`-`$DBEF` (`EnemyRobots`); `$DC0F`-`$DC5F` (`EnemyRobots`); `$DC7F`-`$DCCF` (`EnemyRobots`); `$DCEF`-`$DCFF` (`EnemyRobots`); 1 more ranges |

### `SpotEnemies` (`$B626`)

**E = the directions in which a live opponent robot is in sight**

IY the robot. For each direction (up, down, left, right: E's bits 3, 2, 1, 0 as in Input) ScanLane looks from the robot's anchor up to 8 cells; in the facing direction +`$08` the range is 10, 12 with electronics (+`$07` bit 7), and three parallel lanes are scanned (the columns X-1, X, X+1 for up / down, the rows Y-1, Y, Y+1 for left / right). 9652 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 146 calls, 94,523 t-states own (0.04 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,652 calls, 6,246,532 t-states own (0.25 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `ScanLane` |
| Reads | `$DA00`-`$DA58` (`Robots`); `$DB80`-`$DBE8` (`EnemyRobots`); `$DC00`-`$DC58` (`EnemyRobots`); `$DC70`-`$DCC8` (`EnemyRobots`); `$DCE0`-`$DCF8` (`EnemyRobots`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFEC`-`$FFF5` (`work space $FFEC+`) |

### `ScanLane` (`$B66E`)

**set E bit 0 when a live opponent's anchor lies within B cells from HL in direction D**

The step comes from LaneSteps by D's bit. The scan stops at the map's top or bottom edge and at the first cell with an object (bit 6): only a robot of the other side (+`$0A` bit 7 differs) with strength above 0 sets the bit. Buildings, shots and friends block the view. HL, DE are kept apart from E's bit 0.

| | |
| --- | --- |
| Runs (the first recording's game window) | 876 calls, 604,970 t-states own (0.22 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 57,912 calls, 40,996,886 t-states own (1.63 %) |
| Called from | `SpotEnemies` |
| Calls | `FindRobot` |
| Reads | `$B6B0`-`$B6B7` (`LaneSteps`); `$DA0A`-`$DA5C` (`Robots`); `$DB8A`-`$DBEC` (`EnemyRobots`); `$DC0A`-`$DC5C` (`EnemyRobots`); `$DC7A`-`$DCCC` (`EnemyRobots`); `$DCEA`-`$FCEF` (`EnemyRobots`, `Map`, `MapTail`, `work space $FCE9+`); 1 more ranges |
| Writes | `$FFE4`-`$FFEF` (`work space $FFE4+`) |

### `FindFreeShot` (`$B6B8`)

**IY = a free shot record of the shooter IX's side; Z when one is free**

Each side has two shot records of 9 bytes: ours `$D7DC` and `$D7E5`, the enemy's `$D7EE` and `$D7F7` (by IX +`$0A` bit 7). Z with IY on the first one whose +`$01` is 0; NZ when both fly. Record 0 (`$D7D3`) is not handed out here: it is the player's COMBAT MODE shot, launched from the robot menu (DirectControl, not in the recording).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 77 calls, 6,820 t-states own (0.00 %) |
| Called from | `UpdateRobot` |
| Reads | `$D7DD` (`Shots`); `$D7EF` (`Shots`); `$DA0A` (`Robots`); `$DA2A`-`$DA3A` (`Robots`); `$DA5A` (`Robots`); `$DB8A`-`$DB9A` (`EnemyRobots`); 4 more ranges |

### `FireShot` (`$B6D6`)

**launch shot IY of weapon A from robot IX in its facing direction**

Called by RobotStep and by COMBAT MODE in the robot menu (DirectControl, IX = IY = the robot, record 0). Shot record (9 bytes): +`$00`/+`$01` the map cell, +`$02`/+`$03` the column, +`$04` the row, +`$05` the direction, +`$06` the steps left, +`$07` the weapon (1 cannon, 2 missiles, 3 phasers), +`$08` the ground height that stops it (`$0A`). The range is 5 steps (7 for missiles), one more with electronics; each step goes 2 cells. The first step is taken at once (MoveShot), from the shooter's anchor: in RobotStep the shooter is already off the map (bit 6 cleared), so it cannot hit itself.

When the shot survives the first step SoundFx (`$FD53`) = 1, the firing sound; when it ends at once, MoveShot's sound (`$FC`, `$FA` or `$C8`) stays. Recording: an enemy missile at frame 18680, D7EE: 7B F3 7B 00 0B 08 06 02 0A (column `$7B`, row 11, up, 6 steps left after the first turn, missiles).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 51 calls, 14,464 t-states own (0.00 %) |
| Called from | `UpdateRobot` |
| Calls | `MoveShot` |
| Reads | `$D7DD` (`Shots`); `$D7EF` (`Shots`); `$DA02`-`$DA08` (`Robots`); `$DA22`-`$DA38` (`Robots`); `$DB92`-`$DB98` (`EnemyRobots`); `$DBD2`-`$DBD8` (`EnemyRobots`); 4 more ranges |
| Writes | `$D7E1`-`$D7F6` (`Shots`); `$FD53` (`work space $FD53+`); `$FFF2`-`$FFF3` (`work space $FFF2+`) |

### `UpdateShot` (`$B70D`)

**one game turn of shot IY: off its cell, count its range, a step**

Clears the object bit of the shot's cell, counts +`$06` down (0: the shot is gone, ShotGone) and goes on into MoveShot from its column / row. 90 calls in the deep recording.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 90 calls, 12,813 t-states own (0.00 %) |
| Called from | `WorldTurn` |
| Calls | `MoveShot`, `ShotGone` (tail) |
| Reads | `$D7DC`-`$D7F4` (`Shots`); `$DF8F`-`$DF99` (`Map`); `$E3AB` (`Map`); `$E77E`-`$E7AB` (`Map`); `$E9AD`-`$ED82` (`Map`); `$EF7B` (`Map`); 3 more ranges |
| Writes | `$D7E2` (`Shots`); `$D7F4` (`Shots`); `$DF8F`-`$DF99` (`Map`); `$E3AB` (`Map`); `$E77E`-`$E7AB` (`Map`); `$E9AD`-`$ED82` (`Map`); 4 more ranges |

### `MoveShot` (`$B724`)

**move shot IY 2 cells, then hit a wall, an object or fly on**

IY the shot record, HL its column, B its row. One step: 2 cells in +`$05`. Off the rows 0-15 (only tested for down / up; the columns are not range-checked), or ground of height +`$08` (`$0A`) or more under its 2x2 footprint (only the types `$10` / `$12`, height 15; heights up to 7 let it pass): gone (ShotGone, SoundFx `$FC`). The new position and cell go into +`$00`-+`$04`.

Then the 3x3 cells around the new cell are tested for an object (bit 6), row Y-1 and Y+1 only inside the map; none: the shot marks its own cell with bit 6 and flies on. An object that is a live robot (either side: friendly fire is possible) takes damage ((60 - its top) / 4) * (weapon + 1), the top being +`$09` + +`$0D`, so tall robots on high ground take less: strength 0 or below makes it `$FC` (dying, UpdateRobot) with SoundFx `$C8`, else SoundFx `$FA`. Any other object (a building, another shot, a dying robot) just ends the shot (SoundFx `$FC`). Either way the record is freed (+`$01` = 0, the other bytes stay).

The recorded hits agree: a missile (2) into a 19 high robot takes 10 * 3 = 30, a cannon shell 10 * 2 = 20. Entered from UpdateShot (falling through) and FireShot.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 140 calls, 90,584 t-states own (0.00 %) |
| Called from | `FireShot`, `UpdateShot` |
| Calls | `GroundUnderFootprint`, `MapCell`, `FindRobot` |
| Reads | `$D7E1`-`$D7F6` (`Shots`); `$DA09`-`$DA3D` (`Robots`); `$DA59`-`$DA5D` (`Robots`); `$DB89`-`$DB9D` (`EnemyRobots`); `$DBD9`-`$DBDD` (`EnemyRobots`); `$DC49`-`$DC4D` (`EnemyRobots`); 8 more ranges |
| Writes | `$D7DC`-`$D7F2` (`Shots`); `$DA0C`-`$DA3C` (`Robots`); `$DA5C` (`Robots`); `$DB8C`-`$DB9C` (`EnemyRobots`); `$DBDC` (`EnemyRobots`); `$DC4C` (`EnemyRobots`); 13 more ranges |

### `ShotGone` (`$B7EA`)

**out of range or off the map: the shot is gone with the short sound**

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 49 t-states own (0.00 %) |
| Called from | `UpdateShot` (tail) |
| Writes | `$D7EF` (`Shots`); `$FD53` (`work space $FD53+`) |

## enemy

`src/game/enemy.asm`

### `EnemyCommander` (`$B7F4`)

**once a game turn the computer looks at one of its 24 robot slots: builds a robot in a free one or re-thinks a robot's order**

Called first by WorldTurn. A random number 0-31 picks the slot; 24-31 (a quarter of the turns) do nothing. Side = 1. The slot's record is `$DB80` + 16 * n.

A live robot goes to EnemyReplan: one with order 0 at once, any other with a 1/32 chance a turn, gets a new order (EnemyChooseOrder: a nuclear robot destroy factories or warbases, the others one of the capture orders; destroy robots when the order finds no target). Orders 4-8 are kept only while the target has changed owner and the robot stands on its door: the capture under way.

A free slot tries a build at a random enemy warbase (owner `$20` in the Warbases table) whose door and the three cells below it are free of bit 6: random parts (exactly one locomotion, at least one and not all four of the weapon / nuclear parts, at least 1, 2 or 3 of those parts while the computer has 0-7, 8-15 or 16-23 robots, EnemyRobotCount `$FD49`), paid from EnemyResources (`$FD4A`, through MenuResources and PartCosts like the player's), the shortfall of the other resources taken from the general one, at most half of it (at least 11). A refused design is not retried: the slot waits for another turn.

The robot is set up facing down, 3 steps, order 0, strength `$64`, +`$0A` = `$80`, +`$0E` = `$FF`, +`$0F` = 1, height +`$09` the sum of the part heights `$D7B4` (bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7); then CountRobots and UpdateStatusPanel. IY is left on the slot's record; A, BC, DE, HL and the alternate HL', B' lost. 3415 calls in the deep recording.

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 216,172 t-states own (0.08 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,415 calls, 1,599,757 t-states own (0.06 %) |
| Called from | `WorldTurn` |
| Calls | `FindTargetBuilding`, `TargetBuildingTable`, `CountDirections`, `CountRobots`, `PlaceRobot`, `MapCell`, `UpdateStatusPanel`, `AddAToHL`, `Random` |
| Reads | `$CAF0`-`$CAFF` (`PartCosts`); `$D7B4`-`$D7BB` (`PartHeights`); `$DB81`-`$DCFB` (`EnemyRobots`); `$EE05` (`Map`); `$EE71` (`Map`); `$EEEE` (`Map`); 8 more ranges |
| Writes | `$DB85`-`$DCFF` (`EnemyRobots`); `$FD29`-`$FD2F` (`work space $FD29+`); `$FD4A`-`$FD51` (`work space $FD4A+`); `$FFF2`-`$FFFB` (`work space $FFF2+`) |

### `NuclearBlast` (`$B99F`)

**NuclearBlast**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NuclearFlash` (`$BA87`)

**The nuclear blast's flash: the view's paper flickers through random colours with a fading rumble**

Called only by the blast (`$BA76`). Saves the 20 x 20 attributes of the view (from `$5821`, row 1 column 1) to `$5B00-$5C8F`, then 61 times: a burst of noise (`$BAEE`, 244 samples first, 4 fewer and a longer delay each time) and a new random paper colour (2-7, never the previous one) on every attribute of the view whose paper is not black. Restores the saved attributes at the end. The flash lasts 216 frames (4.3 s, measured; docs/10-gameplay-logic.md 10.9); the game stands still meanwhile.

Verified by an experiment (own instance, PC set to `$B99F` with a poked nuclear robot): the run passes here after the bases and robots are hit. `$5B00` is free scratch at that time (the printer buffer and above, also the save checksum of `$C2E8`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NuclearRumble` (`$BAEE`)

**One burst of the blast's noise: B samples of ROM bytes to the speaker, C the delay between**

Plays B samples: bit 4 (the speaker) of the ROM bytes from `$0090` on, the border black, with a delay loop of C x 24 T-states after each. Returns B - 3 and C + 3, so the next burst of NuclearFlash is shorter and lower: a dying rumble. Only NuclearFlash calls it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## bases

`src/game/bases.asm`

### `CountBases` (`$BB09`)

**Count each side's bases: warbases and the factories of each type**

Clears PlayerBuildings (`$FD3A`, 7 counts) and EnemyBuildings (`$FD42`, 7) and goes through the 28 base records (`$FD70`, 5 bytes, read at +3): a base whose +3 has bit 6 counts for the player, bit 5 for the enemy, at index +3 bits 0-2 (0 warbases, 1-6 the factories of type 1-6: electronics, nuclear, phasers, missiles, cannon, chassis, the resource each makes); neutral and destroyed (bit 7) bases do not count. PlayerRobotCount (`$FD41`) between the two count blocks is skipped. The status panel shows these counts (`$D2C1`); the daily production (`$AE38`) adds 5 general per warbase and 2 per factory to its resource; a side with no warbase loses (`$AE6B`).

Called after every change of owner (the capture tick `$AE17`), after the blast (`$BA81`), and by the map builder (`$BCCA`). Ran 18 times in the deep recording. A, B, DE, HL lost.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 3,460 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 18 calls, 65,949 t-states own (0.00 %) |
| Called from | `GameTurnEnd`, `BuildMap` |
| Calls | `AddAToHL` |
| Reads | `$FD3A`-`$FD48` (`work space $FD3A+`); `$FD73`-`$FDFA` (`work space $FD73+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD3A`-`$FD48` (`work space $FD3A+`); `$FFFA`-`$FFFB` (`work space $FFFA+`) |

### `CountRobots` (`$BB40`)

**PlayerRobots (`$FD41`) and EnemyRobots (`$FD49`): the live records of each side**

Counts the robot records whose +1 (the map cell's high byte) is not 0: slots 0-23 into PlayerRobots, slots 24-47 into EnemyRobots. The status panel shows them (the ROBOTS line); the enemy's factory (`$B86F`) builds better-armed robots as its count grows. Called after each birth and death of a robot.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 320 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 40 calls, 3,200 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `UpdateRobot`, `EnemyCommander` |
| Calls | `CountLiveRobots` |
| Writes | `$FD41`-`$FD49` (`work space $FD41+`) |

### `CountLiveRobots` (`$BB50`)

**A = the live records among 24 robot records from HL (+1 not 0); HL moves past them**

| | |
| --- | --- |
| Runs (the first recording's game window) | 8 calls, 9,278 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 80 calls, 92,334 t-states own (0.00 %) |
| Called from | `CountRobots` |
| Reads | `$DA01`-`$DCF1` (`Robots`, `EnemyRobots`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF4`-`$FFF5` (`work space $FFF4+`) |

### `GiveFactory` (`$BB61`)

**Factory A (0-23) changes hands: to the player (B = 0) or the enemy (B = 1); its flag moves**

Sets the factory's owner bits (`$BBB9`), removes the flag buildings at both sides of its roof (the cells x-2 and x+2 of row y-2) and puts the new owner's flag: type 7 (the player's) at x-2, type 8 (the enemy's) at x+2. The factory's own building (type 1-6 at x, y-2) stays.

Called by the capture tick (`$AE01`) when a robot has stood on the factory's door for 144 ticks. Ran 17 times in the deep recording (captures by both sides).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 17 calls, 3,154 t-states own (0.00 %) |
| Called from | `GameTurnEnd` |
| Calls | `SetBaseOwner`, `AddBuilding`, `RemoveBuilding` |

### `GiveWarbase` (`$BB86`)

**Warbase A (0-3) changes hands: to the player (B = 0) or the enemy (B = 1)**

Sets the owner bits (`$BBB9`) and rebuilds the warbase's buildings on its pad row y-4: removes those at x-4, x and x+4, then for the player puts the landing pad (type 0, x) and the player's flag (type 7, x-4); for the enemy only its flag (type 8, x+4). So a captured warbase gives the player a second pad where the construction menu opens.

Called by the map builder (`$BCB3-$BCC7`: warbase 0 the player's, 1-3 the enemy's) and by the capture tick (`$ADF9`). In the deep recording only the four set-up calls ran.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 666 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 4 calls, 666 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `SetBaseOwner`, `AddBuilding` (tail), `RemoveBuilding` |

### `SetBaseOwner` (`$BBB9`)

**Base record A (HL = the table's +3 bytes): owner = the player (B = 0) or the enemy; HL = its door cell**

HL is `$FD73` (warbases) or `$FD87` (factories). Replaces bits 5-7 of the base's +3 with `$40` (the player) or `$20` (the enemy), which also clears the destroyed bit 7. Falls into BaseCell: HL = the map cell of the base's (x, y), its door.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 581 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 21 calls, 3,050 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` |
| Calls | `MapCell` (tail), `AddAToHL` |
| Reads | `$FD70`-`$FD9B` (`work space $FD70+`); `$FDB1`-`$FDFA` (`work space $FDB1+`) |
| Writes | `$FD73`-`$FD9B` (`work space $FD73+`); `$FDB4`-`$FDFA` (`work space $FDB4+`) |

### `DestroyFactory` (`$BBD8`)

**Factory A (0-23) destroyed by a nuclear blast: buildings removed, blocks turned to debris**

Marks the factory destroyed (`$BC1C`), removes its three buildings on the roof row y-2 (the flags at x+2 and x-2 and the factory at x) and draws the factory's shape (ShapeFactory) again in debris: every block a random tile 6 or 7. Verified by an experiment: factory 0 at (39,6) became `$80`, its building at (39,4) went and its blocks became tiles 6 / 7.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DestroyWarbase` (`$BBF9`)

**Warbase A (0-3) destroyed by a nuclear blast: buildings removed, blocks turned to debris**

Marks the warbase destroyed (`$BC1C`), removes the buildings at x-4, x and x+4 of its pad row y-4 and redraws ShapeWarbase in debris (tiles 6 / 7). Verified by an experiment: warbase 1 at (261,8) became `$80`, its flag building at (265,4) went, the enemy's warbase count fell from 3 to 2 and its walls became debris.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MarkBaseDestroyed` (`$BC1C`)

**Base A of the table HL (+3 bytes): +3 = `$80` (destroyed, no owner); HL = its door cell**

A = the base's index in its table, HL = the table's +3 bytes (Warbases+3 or Factories+3). Writes `$80` to the base's +3: destroyed, no owner, type bits 0; CountBases does not count it and no order's owner bits match it, so no order targets it again. The capture tick (CaptureLoop) does not test bit 7, though: from the code, a robot standing 144 turns on the door would give it an owner again (SetBaseOwner clears bit 7) with type 0, a warbase; never seen. Goes on into BaseCell: HL = the base's door cell, A = its row. Used by DestroyFactory and DestroyWarbase.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddBuilding` (`$BC43`)

**Add a building: map cell HL, type C (0 pad, 1-6 factory, 7 the player's flag, 8 the enemy's flag)**

Takes the first free record of Buildings (56 x 3 bytes: the cell, the type; a high byte 0 = free), writes the cell and the type, and sets bit 6 of the map cell. With all 56 records taken it does nothing. The buildings are what the ship stands on (their heights by type at `$B0C1`: pad 15, factories 21-22, flags 25) and where landing opens the construction menu (type 0).

| | |
| --- | --- |
| Runs (the first recording's game window) | 29 calls, 23,142 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 46 calls, 55,867 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` (tail), `PlaceBases` |
| Reads | `$DF35`-`$E0D4` (`Map`); `$E3A0`-`$E675` (`Map`); `$E6F2`-`$E716` (`Map`); `$E837`-`$E893` (`Map`); `$EBE3`-`$EBE5` (`Map`); `$ED3C`-`$ED3E` (`Map`); 3 more ranges |
| Writes | `$DF35`-`$E0D4` (`Map`); `$E3A0`-`$E675` (`Map`); `$E6F2`-`$E716` (`Map`); `$E837`-`$E893` (`Map`); `$EBE3`-`$EBE5` (`Map`); `$ED3C`-`$ED3E` (`Map`); 3 more ranges |

### `RemoveBuilding` (`$BC5D`)

**Remove the building on map cell HL, if any: its record freed, bit 6 of the cell cleared**

Keeps IY and BC. Uses FindBuilding.

| | |
| --- | --- |
| Runs (the first recording's game window) | 12 calls, 1,068 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 46 calls, 4,094 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` |
| Calls | `FindBuilding` |

### `BuildMap` (`$BC6F`)

**A new game's map: clear it, place the scenery and the 28 bases, give the warbases their owners**

Called once by the new game set-up (`$A68B`). Clears the map `$DD00-$FCFF` and the radar bitmap `$D800-$D8FF`, places the scenery lists SceneryWest (columns 0-255) and SceneryEast (256-511), then the bases BaseListWest and BaseListEast (records into `$FD70`: 4 warbases, 24 factories, all neutral), gives warbase 0 to the player and warbases 1-3 to the enemy, counts the bases, marks the radar for a rebuild and puts the ship on the map (`$B024`).

The resulting map: the player's warbase at (22,9), the enemy's at (261,8), (369,8), (494,8); 24 factories, four of each type; read back from the live instance after a new game.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 177,825 t-states own (0.07 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 177,825 t-states own (0.01 %) |
| Called from | `NewGameSetup` |
| Calls | `PutShipOnMap`, `CountBases`, `GiveWarbase`, `PlaceScenery`, `PlaceBases` |
| Reads | `$D800`-`$D8FE` (`RadarOwn`); `$DD00`-`$FCFE` (`Map`, `MapTail`, `work space $FCE9+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$D800`-`$D8FF` (`RadarOwn`); `$DD00`-`$FCFF` (`Map`, `MapTail`, `work space $FCE9+`); `$FD52` (`work space $FD52+`); `$FFFC`-`$FFFD` (`work space $FFFC+`) |

### `PlaceScenery` (`$BCD6`)

**Place a scenery list at HL (3-byte records: tile or shape, x low, y; 0 ends), D = x high byte**

A record with bit 7 clear is one 2 x 2 block of that tile (`$BD91`), with bit 7 set the shape of that index (`$BD61`). The cell is `$DD00` + `$200` * y + D * 256 + x.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 24,782 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 2 calls, 24,782 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `DrawShape`, `PutBlock` |
| Reads | `$BDA9`-`$BF45` (`SceneryWest`, `SceneryEast`) |

### `PlaceBases` (`$BCF9`)

**Place a bases list at HL (3-byte records: type, x low, y; `$FF` ends), D = x high byte**

Type 0: a warbase. Its record goes to IX (the warbases' table) and ShapeWarbase is drawn from the cell. Type 1-6: a factory of that type. Its record goes to IY (the factories' table), ShapeFactory is drawn and the factory's building (that type) is added two rows up, at (x, y-2). A record: +0/+1 x, +2 y, +3 the type (the owner bits come later), +4 0 (the capture counter).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 11,020 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 2 calls, 11,020 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `AddBuilding`, `DrawShape` |
| Reads | `$BF46`-`$BF9B` (`BaseListWest`, `BaseListEast`) |
| Writes | `$FD70`-`$FDFB` (`work space $FD70+`) |

### `DrawShape` (`$BD61`)

**Draw shape A (bit 7 ignored, the index into ShapeTable) from map cell HL**

A shape is a list of 3-byte steps: a tile (0 = none) drawn as a 2 x 2 block at the current cell, then the move to the next cell: columns (signed), rows (signed); a move of (0,0) ends after its tile. DrawRuins (`$BC27`) walks the same lists with debris tiles.

| | |
| --- | --- |
| Runs (the first recording's game window) | 90 calls, 63,184 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 90 calls, 63,184 t-states own (0.00 %) |
| Called from | `PlaceScenery`, `PlaceBases` |
| Calls | `StepCell`, `PutBlock`, `TableWord` |
| Reads | `$BFB2`-`$C08C` (`ShapeWarbase`, `ShapeFactory`, `ShapeLowTiles`, `ShapeMidTiles` and 7 more); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF0`-`$FFF5` (`work space $FFF0+`) |

### `StepCell` (`$BD7F`)

**HL += C columns (signed) and B rows (signed: H += 2 * B); DE kept**

HL a map cell, C the columns (signed), B the rows (signed). HL += C sign-extended, then H += 2 * B (a map row is `$200` bytes). DE kept, A lost. The move of one shape step for DrawShape and DrawRuins.

| | |
| --- | --- |
| Runs (the first recording's game window) | 477 calls, 41,924 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 477 calls, 41,905 t-states own (0.00 %) |
| Called from | `DrawShape` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF0`-`$FFF1` (`work space $FFF0+`) |

### `PutBlock` (`$BD91`)

**A 2 x 2 block of tile A with its bottom left at map cell HL**

Writes the cells (x, y), (x+1, y), (x, y-1), (x+1, y-1): the first with the tile as it is, the other three with bit 5 set (the other parts of a block; the drawing and the blast take only the cell with bit 5 clear). Keeps HL and DE; BC is lost. Used by the map builder, the ruins, the blast and a dead robot's wreck (`$B133`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 614 calls, 195,904 t-states own (0.07 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 620 calls, 197,856 t-states own (0.01 %) |
| Called from | `UpdateRobot`, `PlaceScenery`, `DrawShape` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$DD0C`-`$EEDF` (`Map`); `$EEF7`-`$F0DF` (`Map`); `$F0F7`-`$F2E1` (`Map`); `$F2F7`-`$F4E1` (`Map`); `$F4F7`-`$F8F8` (`Map`); `$F90C`-`$FAF8` (`Map`); 3 more ranges |

## mainmenu

`src/game/mainmenu.asm`

### `MainMenu` (`$C100`)

**The main menu: clear the screen, the title, the options; Z = start a new game, NZ = a game was loaded**

Called by Start (`$A62A`); Start goes on to the new game set-up on Z and straight to play on NZ (`$A62D`). Prints the title (PrintTitle) and the options 0-5; the current controls (Controls, `$D3E4`) show in cyan, the others in yellow (`$C336`). Then MainMenuKeys. Keys 1-3 choose the controls and redraw the options, 4 redefines the keys and redraws the whole menu, 5 loads a saved game, 0 starts.

Verified on the own instance: the menu reads 0..START GAME, 1..KEYBOARD (cyan), 2..KEMPSTON J/S, 3..INTERFACE 2, 4..REDEFINE KEYS, 5..LOAD SAVED GAME.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MainMenuTitle` (`$C103`)

**The main menu without the clearing: the title, then the options**

The entry of MainMenu after ClearScreen; nothing jumps here (MainMenuKeys key 4 jumps to MainMenu itself). Falls into MainMenuOptions.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 17 t-states own (0.00 %) |
| Calls | `PrintTitle` |

### `MainMenuOptions` (`$C106`)

**The main menu's options (re-entered after keys 1-3)**

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 34 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 17 t-states own (0.00 %) |
| Called from | `MainMenuKeys` (tail) |
| Calls | `PrintInline` |

### `MenuKeyboardOption` (`$C120`)

**Option 1, KEYBOARD, in the colour of Controls 1**

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 82 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

### `MenuKempstonOption` (`$C137`)

**Option 2, KEMPSTON J/S, in the colour of Controls 2**

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 82 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

### `MenuInterface2Option` (`$C151`)

**Option 3, INTERFACE 2, in the colour of Controls 3; then options 4 and 5**

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 82 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

### `MainMenuKeys` (`$C192`)

**The main menu's keys: the title music until a key, then 0-5**

Waits until no key is held (each frame cycling the title's colours, `$C820`), plays the title music until a key (`$C4A7`), waits for a key (KEY-SCAN `$028E`, the character from the ROM's key table `$0205`): 0 returns Z, 1-3 set Controls and redraw the options, 4 RedefineKeys then the whole menu, 5 the load. Any other key is ignored.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 288,465 t-states own (0.11 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 326,132 t-states own (0.01 %) |
| Called from | `PrintInline` |
| Calls | `MainMenuOptions` (tail), `MenuMusic`, `TitleColourCycle` |
| Reads | `$C193`-`$C1A2` (`MainMenuKeys`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$D3E4` (`Controls`); `$FFFC`-`$FFFD` (`work space $FFFC+`) |

### `PrintTitle` (`$C1E3`)

**"NETHER" and "EARTH" in big white letters at the top**

Prints the inline TitleText: NETHER at row 1 column 10 and EARTH at row 5 column 11, white (`$47`), each glyph 3 rows high and 2 bytes wide. The attributes of rows 1-7, columns 10-21 are recoloured every 2 frames by TitleColourCycle while the menu waits. Called by MainMenuTitle and by LoadGame (which reprints it before PRESS PLAY ON TAPE).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 17 t-states own (0.00 %) |
| Called from | `MainMenuTitle` |
| Calls | `PrintInline` |

### `PrintTitleEnd` (`$C1FC`)

**PrintTitle's return; then the load option**

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 10 t-states own (0.00 %) |
| Called from | `PrintInline` |

### `LoadGameBlocks` (`$C21E`)

**Load a saved game: the checksum block, the game block; NZ when it is good**

Red border. Loads two headerless blocks (flag `$00`) through the ROM's LD-BYTES past its border set-up (`$0562`, the INC D / EX AF,AF' / DEC D / DI before it done here): 2 bytes to `$5B00` (the checksum), then `$24D1` bytes to `$D92B-$FDFB`. If SaveChecksum of the block matches, the first 45 bytes go back to `$D7D3` (the 5 records of 9 bytes `$B0E3` walks) and the next 168 to Buildings; returns NZ (MainMenu's caller skips the new game set-up). A mismatch prints LOADING ERROR!, beeps, waits for a key and restarts (Start).

Not run in any recording; read from the code and the ROM's entry points. The block holds the robots (`$DA00`), the map (`$DD00-$FCFF`) and the variables `$FD00-$FDFB` (resources, clock, bases), so a load restores the whole game.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadError` (`$C282`)

**After LOADING ERROR!: a beep, a key, then the start again (Start)**

Beep with A = `$FA` (about 530 Hz for 0.24 s, the game standing still), WaitAnyKey, then JP Start: the whole start-up again (IM 2 table, seed, the menu). The tables LoadGameBlocks has half loaded are not cleaned up: NewGameSetup rebuilds everything at the next 0.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveGame` (`$C28D`)

**Save the game to tape: the prompt, a key, the checksum block and the game block**

Called from the game loop when the SAVE key (Input bit 5, KeyTable record 2) is held (`$A71A`); the loop then redraws the screen and returns to play (`$A68E`). Installs StartInterrupt as the handler, prints PRESS RECORD AND PLAY / THEN ANY KEY at row 22, waits for a key, copies the 45 bytes at `$D7D3` and Buildings to `$D92B-$D9FF` so that `$D92B-$FDFB` is one block, sums it into `$5B00` and saves the 2 bytes and the block (flag `$00`) through the ROM's SA-BYTES past its pilot choice (`$04D0`) with a short pilot (HL = `$0900`).

Not run in any recording; read from the code and the ROM's entry points. LoadGameBlocks reads the same two blocks.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveGameBlocks` (`$C2C9`)

**After the prompt: a key, the staging, the checksum, the two blocks**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveChecksum` (`$C30F`)

**DE = the 16-bit sum of the `$24D1` bytes at `$D92B` (the saved game block)**

Out: DE = the plain 16-bit sum of the `$24D1` (9425) bytes `$D92B-$FDFB`, HL = `$FDFC`, BC = 0, A = 0. Keeps IX. Called by SaveGameBlocks (the sum is saved first, at `$5B00`) and by LoadGameBlocks (compared with the loaded one).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WaitAnyKey` (`$C325`)

**Wait until no key is held, then until one is (all half rows of port `$FE`)**

Reads all eight half rows at once (IN with A = 0: every address line A8-A15 low), bits 0-4 inverted: a key held. First waits for all keys up, then for any key down; returns with the key still held. No joystick, no debounce. Called by SaveGameBlocks (start the tape) and LoadError.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ControlsOptionAttr` (`$C336`)

**The attribute for menu option C: cyan (`$45`) when it is the current Controls, else yellow (`$46`)**

C = the option's Controls value (1-3). Prints an inline attribute code: `$45` (cyan, bright) when Controls (`$D3E4`) is C, else `$46` (yellow, bright); the option text printed next takes it. Called by the three option entries before their text; A and the flags are lost.

| | |
| --- | --- |
| Runs (the first recording's game window) | 6 calls, 256 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3 calls, 128 t-states own (0.00 %) |
| Called from | `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option` |
| Calls | `PrintInline` |
| Reads | `$D3E4` (`Controls`) |

### `ControlsOptionPlain` (`$C342`)

**ControlsOptionAttr's return, the option not chosen**

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 40 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 2 calls, 20 t-states own (0.00 %) |
| Called from | `PrintInline` |

### `ControlsOptionChosen` (`$C349`)

**ControlsOptionAttr's return, the option chosen**

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 20 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 10 t-states own (0.00 %) |
| Called from | `PrintInline` |

### `RedefineKeys` (`$C34A`)

**Redefine the eight keys: UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE**

Key 4 of the main menu. Clears the screen, prints REDEFINE KEYS, waits until no key is held, clears KeyTable and asks for each key in turn: PrintKeyPrompt prints "PRESS KEY FOR " and the name that follows the CALL, DefineKey waits for a key not yet taken and fills the KeyTable record whose third byte HL points at (the port's high byte, the bit mask, the key code) and prints the key. KeyTable's records 0-7 are PAUSE, ABORT, SAVE, FIRE, UP, DOWN, LEFT, RIGHT: Input bits 7 to 0. Waits for the last key's release and about 0.5 s, then back to the menu.

Verified on the own instance: keys Q A O P M H B S gave KeyTable bf 10 48 / 7f 10 42 / fd 02 53 / 7f 04 4d / fb 01 51 / fd 01 41 / df 02 4f / df 01 50, the screen showed PRESS KEY FOR UP .. PAUSE with each key's letter, and the menu came back.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RedefineKeysBody` (`$C36A`)

**Wait for no key, clear KeyTable, ask for UP**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadUpKey` (`$C388`)

**The key for UP (KeyTable record 4), then ask for DOWN**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadDownKey` (`$C397`)

**The key for DOWN (record 5), then ask for LEFT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadLeftKey` (`$C3A6`)

**The key for LEFT (record 6), then ask for RIGHT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadRightKey` (`$C3B5`)

**The key for RIGHT (record 7), then ask for FIRE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadFireKey` (`$C3C4`)

**The key for FIRE (record 3), a blank line, then ask for PAUSE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadPauseKey` (`$C3D6`)

**The key for PAUSE (record 0), then ask for ABORT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadAbortKey` (`$C3E5`)

**The key for ABORT (record 1), then ask for SAVE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadSaveKey` (`$C3F4`)

**The key for SAVE (record 2), wait for its release and a pause, back to the menu**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintKeyPrompt` (`$C40C`)

**"PRESS KEY FOR " and then the key's name that follows the caller's CALL**

Called by the redefine-keys screen (`$C37F`, `$C38E`, ... `$C3EB`) once for each of the eight keys, with the key's name (UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE) as an inline string after the CALL. It prints its own inline text (two new lines, attribute `$46`, "PRESS KEY FOR ", attribute `$45`), then jumps (not calls) to PrintInline at `$C424`: the return address on the stack is then the caller's, so PrintInline prints the caller's name string and returns past it. One prompt takes two screen rows.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintKeyPromptName` (`$C424`)

**print the caller's inline key name and return past it**

The tail of PrintKeyPrompt: a JP to PrintInline with the caller's return address on top of the stack, so the bytes after the caller's CALL `$C40C` (the name of the key to press) are printed and skipped.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DefineKey` (`$C427`)

**wait for a free key, store its port, mask and code into a KeyTable entry, print its name**

HL = the code byte (the third byte) of a KeyTable entry; the redefine screen passes the entries in the order UP (+`$0E`), DOWN (+`$11`), LEFT (+`$14`), RIGHT (+`$17`), FIRE (+`$0B`), PAUSE (+`$02`), ABORT (+`$05`), SAVE (+`$08`), so the entries map to the Input bits 3, 2, 1, 0, 4, 7, 6, 5 (ReadControls shifts entry 0 into bit 7). The screen cleared the whole table before the first key, so only keys already defined in this pass count as taken.

It prints two spaces and sets attribute `$46`, then waits with the ROM KEY-SCAN (`$028E`) for a key; the key value E (0-39, row index 0-7 in bits 0-2, bit position from bit 4 down in bits 3-5) is turned into a code through the ROM key table `$0205` (CAPS SHIFT gives `$E3`, the first byte past the table). A key whose code is already in one of the eight entries is refused and the wait goes on. Then it writes the code, the bit mask `$20` >> (E/8 + 1) and the port high byte (`$7F` for row 0 down to `$FE` for row 7) backwards into the entry, and prints the key's name: SYM SH, ENTER, CAPS SH, SPACE, or the code as a character.

Experiment: key 4 at the menu, then Q, Q, A, O, P, SPACE, ENTER, CAPS SHIFT, SYMBOL SHIFT left KeyTable = FB 01 51 / FD 01 41 / DF 02 4F / DF 01 50 for UP / DOWN / LEFT / RIGHT, 7F 01 20 for FIRE, BF 01 0D, FE 01 E3, 7F 02 0E for PAUSE / ABORT / SAVE; the second Q was refused.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DefineKeyScan` (`$C430`)

**wait for a key that no entry holds yet**

Continues DefineKey after its inline text. On exit the entry is filled and the name printed (the RET is the one after each name string, or the one in PrintCharKeep's path for a plain character).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `KeyNameSymShiftEnd` (`$C479`)

**a RET (`$C9`): PrintInline returns here and the routine ends**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CheckEnterKey` (`$C47A`)

**DefineKey: is the new key ENTER?**

Part of DefineKey (`$C427`): code `$0D` prints "ENTER" and returns through the RET placed after the string.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `KeyNameEnterEnd` (`$C487`)

**a RET (`$C9`) after the string**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CheckCapsShiftKey` (`$C488`)

**DefineKey: is the new key CAPS SHIFT?**

Part of DefineKey (`$C427`): code `$E3` (the byte after the ROM's key table, what CAPS SHIFT alone looks up) prints "CAPS SH".

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `KeyNameCapsShiftEnd` (`$C497`)

**a RET (`$C9`) after the string**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CheckSpaceKey` (`$C498`)

**DefineKey: SPACE prints its name, any other key prints its own character**

Part of DefineKey (`$C427`). A code other than `$20` goes to PrintCharKeep (print the character A) and returns from there.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DefineKeyDone` (`$C4A6`)

**RET: the end of DefineKey; also the target of the music's command 0**

The RET after the SPACE name. The two command tables of the menu music (`$C553`, `$C572`) point their command 0 here; command 0 never occurs in the tune, and it would not work: the dispatch leaves the voice pointer pushed, so this RET would return into the tune data.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## music

`src/game/music.asm`

### `MenuMusic` (`$C4A7`)

**play the menu tune until a number key is pressed**

Called once by the main menu (`$C19E`) after all keys are up. Saves SP in `$FD08`, installs MenuInterrupt as Handler and sets the music state: the bass voice reads the track `$C678` through HL' (frames left C'), the lead voice the track `$C702` through DE' (frames left B'), the drum the track `$C665` through HL (frames left C); C' = B' = C = 1, so the first interrupt reads the first event of each. Then it runs the tone loop for ever: the main set's D and E count each voice's period down.

The tone loop never returns: MenuInterrupt ends it by loading SP from `$FD08` when a number key is down, so the RET of the interrupt returns from MenuMusic to the menu (`$C1A1`), which then reads the key. Ran 144 frames in work/play (12666-12814). The tune is 5120 frames (102.4 s) long in each voice and loops (experiment: both voices jumped back at frame 5099 of a menu left alone); docs: r4.md.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 9,797,658 t-states own (3.64 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 69,168 t-states own (0.00 %) |
| Called from | `MainMenuKeys` |
| Calls | `BassIdlePad` |
| Reads | `$C4C3` (`BassIdlePad`); `$FD0C` (`work space $FD0C+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD08`-`$FD0C` (`work space $FD08+`); `$FDFE`-`$FDFF` (`work space $FDFE+`); `$FFF8`-`$FFFB` (`work space $FFF8+`) |
| Ports out | `$00FE`, `$18FE` |

### `BassIdlePad` (`$C4C3`)

**tone loop: the time of a bass step without an edge**

The tone loop runs LeadStep and BassStep in turn, about 122 T a turn. A step whose counter has not run out takes this pad (PUSH AF, read Input and write it back unchanged, POP AF: 61 T with the DEC / JP) so both paths take about the same time, the pitch stays steady whatever the other voice does.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,929 calls, 466,798 t-states own (0.02 %) |
| Called from | `MenuMusic`, `BassStep` (tail) |
| Calls | `LeadStep` |
| Reads | `$FD0C` (`work space $FD0C+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD0C` (`work space $FD0C+`); `$FFF8`-`$FFF9` (`work space $FFF8+`) |

### `LeadStep` (`$C4CB`)

**tone loop: count the lead period down, at 0 a pulse**

D counts the lead voice's period in loop turns. At 0 it reloads D with the note's period (the operand `$C4D0`), sets the beeper (EAR and MIC, `$18`, or 0 when the voice is off: the operand `$C4D2`) for a pulse of 14 * width T (the operand `$C4D6` = period / 4, at most 63), then clears it. The voice's pitch is about 3.5 MHz / (122 + 3.5) / period: period `$7C` about 225 Hz, `$29` about 680 Hz.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 10,007 calls, 419,098 t-states own (0.02 %) |
| Called from | `BassIdlePad`, `BassStep` (tail) |
| Calls | `LeadIdlePadTail`, `BassStep` (tail) |
| Reads | `$FD0C` (`work space $FD0C+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF8`-`$FFFB` (`work space $FFF8+`) |
| Ports out | `$00FE`, `$18FE` |

### `LeadIdlePadTail` (`$C4E4`)

**the rest of the lead pad (an entry only because work/deep starts its recording here)**

Write Input back and POP AF, then fall into BassStep. The recording of work/deep began inside the tone loop at this instruction, so its L1 lists the address as a root.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,824 calls, 226,032 t-states own (0.01 %) |
| Called from | `LeadStep` |
| Calls | `BassStep` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD0C` (`work space $FD0C+`); `$FFF8`-`$FFF9` (`work space $FFF8+`) |

### `BassStep` (`$C4E8`)

**tone loop: count the bass period down, at 0 a pulse**

The bass voice's twin of LeadStep: E is its counter, the operands `$C4ED` (period), `$C4EF` (on / off) and `$C4F3` (pulse width) are written by BassNextEvent, BassOn and BassOff.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 10,007 calls, 178,735 t-states own (0.01 %) |
| Called from | `LeadStep` (tail), `LeadIdlePadTail` |
| Calls | `BassIdlePad` (tail), `LeadStep` (tail) |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFFA`-`$FFFB` (`work space $FFFA+`) |
| Ports out | `$00FE` |

### `MenuInterrupt` (`$C4FD`)

**the interrupt handler of the menu**

The drum, the bass and lead note readers, the title colours; a number key ends MenuMusic. It returns to the tone loop of MenuMusic, or, with SP from SavedSP, to the menu.

[Animation: `MenuInterrupt` at work](img/routines/MenuInterrupt.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 144 calls, 20,157 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 21 calls, 3,015 t-states own (0.00 %) |
| Calls | `BassNextEvent`, `LeadNextEvent`, `DrumStep`, `TitleColourCycle` |
| Reads | `$FD08`-`$FD09` (`work space $FD08+`) |
| Writes | `$FDFE`-`$FDFF` (`work space $FDFE+`) |
| Ports in | `$E7FE` |

### `BassNextEvent` (`$C528`)

**read the bass voice's next event: a note, or a command**

HL' = the bass track position. A byte of 9 or more is a note: the byte is the period (written into `$C4ED`, and period / 4 into the pulse width `$C4F3`) and the next byte its length in frames (C'). A byte below 9 is a command (BassCommand). Called by MenuInterrupt when C' runs out, and jumped to again by every command handler, so commands take no time.

| | |
| --- | --- |
| Runs (the first recording's game window) | 17 calls, 1,214 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 5 calls, 344 t-states own (0.00 %) |
| Called from | `MenuInterrupt`, `BassCall` (tail), `SetDrumTrack` (tail), `BassOn` (tail), `BassOff` (tail) |
| Calls | `MusicDispatch` |
| Reads | `$C678`-`$C67B` (`BassTrack`); `$C6BD`-`$C6C9` (`BassRiff`) |
| Writes | `$C4ED`-`$C4F3` (`BassStep`) |

### `LeadNextEvent` (`$C53B`)

**read the lead voice's next event: a note, or a command**

The lead twin of BassNextEvent: DE' = the position, the note goes into `$C4D0` / `$C4D6` and its frames into B'.

| | |
| --- | --- |
| Runs (the first recording's game window) | 24 calls, 1,952 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 4 calls, 298 t-states own (0.00 %) |
| Called from | `MenuInterrupt`, `LeadCall` (tail), `LeadOn` (tail), `LeadOff` (tail) |
| Calls | `MusicDispatch` |
| Reads | `$C702` (`LeadTrack`); `$C789`-`$C7A6` (`LeadRiff`) |
| Writes | `$C4D0`-`$C4D6` (`LeadStep`) |

### `BassCmd2` (`$C559`)

**bass command 2 (entry): JP BassCall**

A table entry of BassCommandTable: command 2 calls a pattern.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 20 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | run into, not called, 10 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `BassCall` (tail) |

### `BassCmd3` (`$C55C`)

**bass command 3 (entry): JP SetDrumTrack**

A table entry: command 3 starts another drum track.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 20 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | run into, not called, 10 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `SetDrumTrack` (tail) |

### `BassCmd4` (`$C55F`)

**bass command 4 (entry): JP BassOn**

A table entry: command 4 turns the bass voice on.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 20 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `BassOn` (tail) |

### `BassCmd5` (`$C562`)

**bass command 5 (entry): JP BassOff**

A table entry: command 5 turns the bass voice off (its notes keep their time, silent).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 30 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | run into, not called, 10 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `BassOff` (tail) |

### `BassCmd6` (`$C565`)

**bass command 6 (entry): JP BassReturn**

A table entry: command 6 ends a pattern.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LeadCommand` (`$C56E`)

**command A of the lead track: jump to entry A of the table after the CALL**

The lead twin of BassCommand. HL' (the bass position) is pushed so the handlers can pop it back.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LeadCmd2` (`$C578`)

**lead command 2 (entry): JP LeadCall**

A table entry of LeadCommandTable: command 2 calls a pattern.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 20 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | run into, not called, 10 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `LeadCall` (tail) |

### `LeadCmd4` (`$C57E`)

**lead command 4 (entry): JP LeadOn**

A table entry: command 4 turns the lead voice on.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 30 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `LeadOn` (tail) |

### `LeadCmd5` (`$C581`)

**lead command 5 (entry): JP LeadOff**

A table entry: command 5 turns the lead voice off.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 30 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | run into, not called, 10 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `LeadOff` (tail) |

### `LeadCmd6` (`$C584`)

**lead command 6 (entry): JP LeadReturn**

A table entry: command 6 ends a pattern.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BassCall` (`$C58D`)

**bass command 2 aa: play the pattern at aa, then go on after the command**

One level only: the return position (the address operand's high byte) is kept in `$FD54`; BassReturn resumes one byte past it.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 132 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 66 t-states own (0.00 %) |
| Called from | `BassCmd2` (tail) |
| Calls | `BassNextEvent` (tail) |
| Reads | `$C67C`-`$C67D` (`BassTrack`) |
| Writes | `$FD54`-`$FD55` (`work space $FD54+`) |

### `LeadCall` (`$C599`)

**lead command 2 aa: play the pattern at aa, then go on after the command**

The return position is kept in `$FD56`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 148 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 74 t-states own (0.00 %) |
| Called from | `LeadCmd2` (tail) |
| Calls | `LeadNextEvent` (tail) |
| Reads | `$C703`-`$C704` (`LeadTrack`) |
| Writes | `$FD56`-`$FD57` (`work space $FD56+`) |

### `BassGoto` (`$C5A7`)

**bass command 1 aa: continue the track at aa (code: POP HL, read the word, JP BassNextEvent)**

Code that runs when the tune loops (frame 5099 of a menu left alone): the recordings never stayed in the menu that long, so the cut keeps it as data. POP HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; JP `$C528`. The bass track ends with 1 `$C678`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LeadGoto` (`$C5B0`)

**lead command 1 aa: continue the track at aa (code, run only when the tune loops)**

POP HL; EX DE,HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; EX DE,HL; JP `$C53B`. The lead track ends with 1 `$C702`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BassReturn` (`$C5BB`)

**bass command 6: back from the pattern to the bass track**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LeadReturn` (`$C5C3`)

**lead command 6: back from the pattern to the lead track**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SetDrumTrack` (`$C5CC`)

**bass command 3 aa: the drum plays the track at aa from its next record**

Writes aa into the main set's HL, the drum position (the frames left of the current drum record are kept). Read through the bass voice's HL', so only the bass track may use it.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 152 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 76 t-states own (0.00 %) |
| Called from | `BassCmd3` (tail) |
| Calls | `BassNextEvent` (tail) |
| Reads | `$C679`-`$C67A` (`BassTrack`) |

### `DrumStep` (`$C5DB`)

**play the next drum record (a short noise or sweep inside the interrupt)**

HL = the drum position, called by MenuInterrupt when the drum's frames (C) run out. A record is the frames until the next one and a kind: 0 a hiss meant as 96 bytes of ROM from `$08`xx sent to the beeper, about 1 ms (but DrumHissLoop never steps HL: one ROM byte, `$08` L, 96 times; in the recordings it is `$23`, EAR / MIC 0, so the hiss is silent: docs/09-sound.md), 2 p a falling tone (48 cycles: the low half starts at p - 1 and shortens by 1, the high half starts at p / 2 and lengthens by 4), any other kind a rasp (80 ROM bytes from `$00`xx with a gap that mostly grows). The byte 1 in place of the frames is a goto: 1 aa. The tone loop stands still while a drum plays. In the 5300-frame experiment kinds 1 and 2 ran 72 times each.

| | |
| --- | --- |
| Runs (the first recording's game window) | 5 calls, 18,942 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 3,762 t-states own (0.00 %) |
| Called from | `MenuInterrupt` |
| Reads | `$C665`-`$C669` (`DrumTrackSteady`) |
| Ports out | `$00FE` |

### `BassOn` (`$C635`)

**bass command 4: the bass pulses sound again**

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 92 t-states own (0.00 %) |
| Called from | `BassCmd4` (tail) |
| Calls | `BassNextEvent` (tail) |
| Writes | `$C4EF` (`BassStep`) |

### `BassOff` (`$C63F`)

**bass command 5: the bass pulses go silent (the notes still take their time)**

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 129 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 43 t-states own (0.00 %) |
| Called from | `BassCmd5` (tail) |
| Calls | `BassNextEvent` (tail) |
| Writes | `$C4EF` (`BassStep`) |

### `LeadOn` (`$C648`)

**lead command 4: the lead pulses sound again**

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 138 t-states own (0.00 %) |
| Called from | `LeadCmd4` (tail) |
| Calls | `LeadNextEvent` (tail) |
| Writes | `$C4D2` (`LeadStep`) |

### `LeadOff` (`$C652`)

**lead command 5: the lead pulses go silent**

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 129 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 43 t-states own (0.00 %) |
| Called from | `LeadCmd5` (tail) |
| Calls | `LeadNextEvent` (tail) |
| Writes | `$C4D2` (`LeadStep`) |

### `MusicDispatch` (`$C65B`)

**jump to entry A of the 3-byte JP table that follows the caller's CALL**

Called with A = the command (below 9) from BassCommand / LeadCommand; it pops its own return address (the table) and jumps to table + 3 * A, so the handler returns to nobody: each jumps back to the voice's reader.

| | |
| --- | --- |
| Runs (the first recording's game window) | 17 calls, 782 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 5 calls, 230 t-states own (0.00 %) |
| Called from | `BassNextEvent`, `LeadNextEvent` |
| Calls | `BassCmd2`, `BassCmd3`, `BassCmd4`, `BassCmd5`, `LeadCmd2`, `LeadCmd4`, `LeadCmd5` |

### `TitleColourCycle` (`$C820`)

**cycle the ink of the NETHER EARTH title, one colour every 2 frames**

Counts `$FD33` 0-15 each call; on even counts it paints the attributes of rows 1-7, columns 10-21 (the big title printed by `$C1E3`) with BRIGHT, black paper and ink count / 2, so the ink runs through all 8 colours every 16 frames. Called every frame by the main menu's HALT loops (`$C193`, `$C1A2`) and by MenuInterrupt while the tune plays (26 calls over frames 0-26 of work/deep; it writes `$582A-$58F5`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 149 calls, 212,421 t-states own (0.08 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 26 calls, 37,297 t-states own (0.00 %) |
| Called from | `MainMenuKeys`, `MenuInterrupt` |
| Calls | `AddAToHL` |
| Reads | `$FD33` (`work space $FD33+`) |
| Writes | `$582A`-`$5835` (screen); `$584A`-`$5855` (screen); `$586A`-`$5875` (screen); `$588A`-`$5895` (screen); `$58AA`-`$58B5` (screen); `$58CA`-`$58D5` (screen); 2 more ranges |

## construction

`src/game/construction.asm`

### `ConstructionMenu` (`$C849`)

**landing on the warbase pad at altitude 15: choose the parts (MenuCursor, MenuParts), START ROBOT or EXIT MENU**

Called by PlayLoop when the ship rests on the pad of our warbase (Altitude 15) and the door below is free. First looks for a free record among our slots 0-23 (`$DA00` + 16 x n, +`$01` = 0); with none it returns at once (IY = `$DB80`, enemy slot 24: the bug of PlayLoop's writes, docs/10-gameplay-logic.md 10.12).

Otherwise IY = the free slot: the preview robot, and on START ROBOT the new one. Handler = StartInterrupt, so neither the frame count nor the radar runs; the menu loop runs no game turns, so the world stands still while the menu is open. ClearScreen, then the eight part pictures in column 16 from the bottom (bipod) to the top (electronics), each the second facing of the part's sprite cut to 24 lines and drawn upwards by DrawMaskedUp; the preview's frame attributes (`$46`, 4 x 9 cells from row 15, column 0); the texts (title, part names, EXIT / START, costs, the resource labels). Falls into ConstructionMenuSetup.

Returns (after LeaveConstructionMenu) with IY = the slot; PlayLoop then writes the start state. On EXIT MENU the slot stays free (+`$01` = 0, PlaceRobot not called), so those writes do no harm.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7 calls, 28,361 t-states own (0.00 %) |
| Called from | `NewGameSetup` |
| Calls | `ClearScreen`, `DrawMaskedUp`, `TableWord`, `AddAToHL`, `PrintInline` |
| Reads | `$6A24`-`$6A25` (`SprTracksXOdd`); `$6D40`-`$6D41` (`SprBipodXOdd`); `$7058`-`$7059` (`SprAntiGravOdd`); `$7354`-`$7355` (`SprCannonXmOdd`); `$77F4`-`$77F5` (`SprMissilesXOdd`); `$7C96`-`$7C97` (`SprPhasersXmOdd`); 4 more ranges |
| Writes | `$59E0`-`$5A03` (screen); `$5A20`-`$5A23` (screen); `$5A40`-`$5A43` (screen); `$5A60`-`$5A63` (screen); `$5A80`-`$5A83` (screen); `$5AA0`-`$5AA3` (screen); 3 more ranges |

### `ConstructionMenuSetup` (`$C9E7`)

**reset the preview robot, copy the resources, cursor on BIPOD, nothing chosen**

Continues ConstructionMenu after its text. The free slot's +8 is set to 4 and +`$0D` to 0 (the built robot keeps +8 = 4: work/deep frame 360, slot 0 = 16 EF 16 00 09 00 00 09 04 11 ...). Resources are copied to MenuResources, which the menu spends; MenuCursor = column 2 (the parts), row 0 (bipod); MenuParts = 0; ShowRobotDesign paints the part pictures (white when chosen) and draws the preview robot; the cursor is painted.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7 calls, 2,177 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PaintMenuCursor`, `PrintMenuResources`, `ShowRobotDesign` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`) |
| Writes | `$DA08`-`$DA5D` (`Robots`); `$FD1F`-`$FD2F` (`work space $FD1F+`) |

### `ConstructionMenuLoop` (`$CA0F`)

**wait for a control; fire acts on the cursor's item, a direction moves the cursor**

WaitKey until one of Input bits 0-4. Without fire: MoveMenuCursor (`$CB00`). With fire: column 0 EXIT MENU (`$CB8E`), column 1 START ROBOT (`$CB52`), column 2 toggles the part under the cursor.

Choosing a part: a part already chosen is taken back (RefundPart) and cleared. A chassis (bipod, tracks, anti-grav: rows 0-2) replaces the chassis already chosen, which is refunded first. A fourth weapon is refused: of cannon, missiles, phasers and nuclear at most three (`$78` never all set). The cost is paid from the part's own resource (PartCosts + 8) and what it lacks from the general resource; if the general one cannot pay the rest the part is refused (a replaced chassis stays refunded: the robot is left without one). Accepted: beep `$64`; refused or taken back: beep `$78`. Then it waits for fire up and pauses 10 frames.

Experiment (general 10, electronics 1, chassis 2): bipod 3 -> chassis 0, general 9; tracks 5 -> bipod refunded, chassis 0, general 7; cannon 2 -> general 5; tracks again -> taken back, chassis 2, general 8. With 99 of everything: missiles, phasers, then nuclear refused (MenuParts `$38`).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 64 calls, 241,390 t-states own (0.01 %) |
| Called from | `MenuPause` (tail) |
| Calls | `MoveMenuCursor` (tail), `MenuPause` (tail), `StartRobot` (tail), `PrintMenuResources`, `ShowRobotDesign`, `Beep`, `AddAToHL`, `WaitKey` |
| Reads | `$CAF0`-`$CAFF` (`PartCosts`); `$FD0C` (`work space $FD0C+`); `$FD1F`-`$FD2F` (`work space $FD1F+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD21`-`$FD2F` (`work space $FD21+`); `$FFFC`-`$FFFD` (`work space $FFFC+`) |

### `RefundPart` (`$CAC1`)

**give back the cost of part E to MenuResources, the overflow to the general resource**

E = the part row. The cost goes back to the part's own resource; whatever lifts it above its value when the menu opened (Resources, 7 bytes below MenuResources) is what the general resource paid, so it is returned to the general one instead. Exact because each own resource has only one part in the menu at a time (one chassis, one of each weapon, electronics). Called by ConstructionMenuLoop (`$CA4C`, `$CAA4`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MoveMenuCursor` (`$CB00`)

**right / left change the column (0-2), down / up the part row (0-7) in column 2**

HL = MenuCursor (L the column, H the row), Input as WaitKey left it. Right adds 1 to the column, left subtracts 1; out of 0-2 nothing moves. Only without right / left: in the parts column up adds 1 to the row (towards ELECTRONICS, up the screen), down subtracts 1; out of 0-7 nothing moves. A move repaints the old item in `$45`, the new one in `$46` and clicks (beep `$14`); every press ends in the 10-frame pause (MenuPause).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 42 calls, 10,052 t-states own (0.00 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `PaintMenuCursor`, `Beep` |
| Reads | `$FD0C` (`work space $FD0C+`) |
| Writes | `$FD1F`-`$FD20` (`work space $FD1F+`) |

### `MenuPause` (`$CB4A`)

**10 frames, then back to ConstructionMenuLoop**

The pause after every press (moves too); a shorter press falls into it and is lost, WALKTHROUGH 6.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 22 calls, 43,839,916 t-states own (1.74 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `ConstructionMenuLoop` (tail) |
| Reads | `$CB4D` (`MenuPause`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFFC`-`$FFFD` (`work space $FFFC+`) |

### `StartRobot` (`$CB52`)

**START ROBOT: needs a chassis and a weapon; spend the resources, place the robot at the warbase's door, leave**

Refused (back to the menu after the pause) without a chassis (MenuParts bits 0-2) or without a weapon (bits 3-6); electronics alone count as neither. Otherwise MenuResources become Resources, the free slot becomes a robot of ours (+`$0A` = 0) at column ShipX, row ShipY + 4 (PlaceRobot writes +0 to +4 and marks the map cell), +7 = MenuParts, and a rising chirp plays (Beep with `$50` down to `$14` by 5). Then LeaveConstructionMenu. In work/deep the robot built at frame 356 sits at (22, 9): the pad at (22, 5) plus 4 rows.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7 calls, 8,323 t-states own (0.00 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `PlaceRobot`, `Beep`, `ClearViewBuffer`, `DrawPlayScreen` |
| Reads | `$FD0D`-`$FD0F` (`work space $FD0D+`); `$FD21`-`$FD2F` (`work space $FD21+`) |
| Writes | `$DA07`-`$DA5A` (`Robots`); `$FD22`-`$FD30` (`work space $FD22+`); `$FDFE`-`$FDFF` (`work space $FDFE+`) |

### `PaintMenuCursor` (`$CBA9`)

**paint the item under MenuCursor with attribute C (`$46` the cursor, `$45` the rest)**

Column 0 / 1: two rows of 5 cells, EXIT MENU at rows 21-22 columns 4-8, START ROBOT columns 10-14. Column 2: the part's name, 11 cells from column 21 of row 22 - 3 * row (BIPOD row 22 up to ELECTRONICS row 1). Called by ConstructionMenuSetup and MoveMenuCursor.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 91 calls, 12,530 t-states own (0.00 %) |
| Called from | `ConstructionMenuSetup`, `MoveMenuCursor` |
| Calls | `FillAttributes` |
| Reads | `$FD1F`-`$FD20` (`work space $FD1F+`) |

### `FillAttributes` (`$CBDB`)

**write C into B bytes from HL**

Also used by PaintMenuItem.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 430 calls, 102,481 t-states own (0.00 %) |
| Called from | `PaintMenuItem`, `PaintMenuCursor` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$5835`-`$583F` (screen); `$5895`-`$589F` (screen); `$58F5`-`$591E` (screen); `$5955`-`$59DE` (screen); `$59F7`-`$59FE` (screen); `$5A15`-`$5A3E` (screen); 3 more ranges |

### `PrintMenuResources` (`$CBE0`)

**print MenuResources (two digits each) and their total**

The seven values at column 13: GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16 (PrintMenuResource, two digits: a value above 99 prints a wrong tens digit, e.g. 200 shows "D0"); the sum (HL) at row 18, column 12, three digits by PrintNumber3 (the tail `$CC03`).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 29 calls, 20,387 t-states own (0.00 %) |
| Called from | `ConstructionMenuSetup`, `ConstructionMenuLoop` |
| Calls | `PrintMenuResource`, `AddAToHL`, `PrintInline` |
| Reads | `$FD29`-`$FD2F` (`work space $FD29+`) |

### `PrintMenuTotal` (`$CC03`)

**Construction menu: print the total of the costs (the tail of `$CBE0`)**

The tail of PrintMenuResources after the inline position (18,12): E = `$20` (blank leading zeros) and PrintNumber3 prints HL, the sum of the seven MenuResources (the TOTAL line, not the costs). 29 runs in the deep recording, one per reprint of the resources.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 29 calls, 493 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber3` (tail) |

### `PrintMenuResource` (`$CC08`)

**Construction menu: print one resource value A at row C, column 13**

Called by `$CBE0` for each of the seven MenuResources (rows 9, 11-16). Patches the row byte of the position string after the CALL (`$CC11`), prints the position, then PrintMenuResourceValue prints A as two digits. Preserves BC, DE, HL (203 calls in the deep recording).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 203 calls, 9,135 t-states own (0.00 %) |
| Called from | `PrintMenuResources` |
| Calls | `PrintInline` |
| Writes | `$CC11` (`MenuResourcePos`) |

### `PrintMenuResourceValue` (`$CC14`)

**Construction menu: print A as two digits, registers kept (the tail of `$CC08`)**

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 203 calls, 20,338 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2` |

### `ShowRobotDesign` (`$CC1F`)

**Construction menu: highlight the chosen parts and draw the robot preview**

IY = the robot record being designed. Paints the attributes of the parts list (columns 16-19, three rows a part, 24 rows from the top): `$47` (bright white) for a part chosen in MenuParts, `$06` (yellow) otherwise, bit 7 (electronics) at the top. Then clears the view buffer, writes MenuParts to +`$07`, draws the robot stack into the buffer at map position row 10, column 7 (DrawRobot, base height +`$0D` = 0) and stores the stack's total height (the sum of the part heights `$D7B4`) in +`$09`: the height the ship lands on. Finally copies 4 bytes x 72 lines of the buffer from `$6168` (buffer row 82, column 0) to the screen at `$48E0` (character row 15, column 0). Called from `$C9E7` (7) and `$CA0F` (22) after each change of the parts.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 29 calls, 672,957 t-states own (0.03 %) |
| Called from | `ConstructionMenuSetup`, `ConstructionMenuLoop` |
| Calls | `DrawRobot`, `ClearViewBuffer`, `NextScreenLine`, `AddAToHL` |
| Reads | `$6168`-`$666B` (`ViewBuffer`); `$667C`-`$667F` (`ViewBuffer`); `$6690`-`$6693` (`ViewBuffer`); `$66A4`-`$66A7` (`ViewBuffer`); `$66B8`-`$66BB` (`ViewBuffer`); `$66CC`-`$66CF` (`ViewBuffer`); 5 more ranges |
| Writes | `$48E0`-`$54E3` (screen); `$5500`-`$55C3` (screen); `$55E0`-`$55E3` (screen); `$5600`-`$56C3` (screen); `$56E0`-`$56E3` (screen); `$5700`-`$57C3` (screen); 10 more ranges |

### `PlaceRobot` (`$CC7C`)

**Put robot IY at map column HL, row B: record, map bit 6, radar dot**

Writes +`$02`/+`$03` = HL (x), +`$04` = B (y), +`$00`/+`$01` = the map cell (MapCell) and sets the cell's bit 6 (an object to draw). Then toggles the robot's radar dot (ToggleRadarDot, side = bit 7 of +`$0A`: 0 the player's buffer `$D800`, 1 the enemy's `$D900`). The caller clears the old cell and toggles the old dot. Called by the robot step `$B0FA` (9652 times in the deep recording), the enemy spawn `$B7F4` (22) and START ROBOT in `$CB52` (7).

| | |
| --- | --- |
| Runs (the first recording's game window) | 150 calls, 32,250 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,681 calls, 2,081,662 t-states own (0.08 %) |
| Called from | `UpdateRobot` (tail), `RobotStep` (tail), `EnemyCommander`, `StartRobot` |
| Calls | `MapCell`, `ToggleRadarDot` (tail) |
| Reads | `$DA04`-`$DA5A` (`Robots`); `$DB84`-`$DBAA` (`EnemyRobots`); `$DBC4`-`$DBEA` (`EnemyRobots`); `$DC04`-`$DC5A` (`EnemyRobots`); `$DC74`-`$DCCA` (`EnemyRobots`); `$DCE4`-`$DCFA` (`EnemyRobots`); 7 more ranges |
| Writes | `$DA00`-`$DA54` (`Robots`); `$DB80`-`$DBE4` (`EnemyRobots`); `$DC00`-`$DC54` (`EnemyRobots`); `$DC70`-`$DCC4` (`EnemyRobots`); `$DCE0`-`$DCF4` (`EnemyRobots`); `$DF67`-`$E065` (`Map`); 6 more ranges |

### `ShipCell` (`$CCA0`)

**HL = the map cell under the ship (ShipX, ShipY)**

Falls into MapCell. Used by `$A62D`, `$B01D` (clear the ship's bit 7) and `$B024` (set it).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,104 calls, 32,016 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,996 calls, 289,903 t-states own (0.01 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `LiftShipFromMap`, `PutShipOnMap` |
| Calls | `MapCell` |
| Reads | `$FD0D`-`$FD0F` (`work space $FD0D+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF8`-`$FFF9` (`work space $FFF8+`) |

### `MapCell` (`$CCA6`)

**HL = the map cell of column HL, row A: `$DD00` + `$200`*A + HL**

H += 2*A + `$DD`. The map lookup of the whole game (127962 calls in the deep recording: the main loop `$AD90`, CheckShipMove, the robot code, PlaceRobot, DrawMover).

| | |
| --- | --- |
| Runs (the first recording's game window) | 12,184 calls, 353,336 t-states own (0.13 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 127,962 calls, 3,712,513 t-states own (0.15 %) |
| Called from | `GameTurnEnd`, `CheckShipMove`, `GroundUnderFootprint`, `MoveShot`, `EnemyCommander`, `SetBaseOwner` (tail), `PlaceRobot`, `ShipCell`, `DrawCellObject` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFE6`-`$FFE7` (`work space $FFE6+`); `$FFF8`-`$FFF9` (`work space $FFF8+`) |

### `Beep` (`$CCAC`)

**Beeper tone: 256 half-periods, A = the half-period delay (bigger is lower)**

B = A is the DJNZ delay of each half-period, C = 0 counts 256 speaker toggles (bit 4 of port `$FE`, border black). BC is kept. Used for menu clicks and confirmations: ListMenu (83), `$CB52` (98), `$CB00` (42), `$CA0F` (22), the robot menu `$A7CD`, `$ABC8`.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 259 calls, 51,902,621 t-states own (2.06 %) |
| Called from | `ShowOrderMiles`, `SetOrder`, `ListMenu`, `ConstructionMenuLoop`, `MoveMenuCursor`, `StartRobot` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF4`-`$FFF9` (`work space $FFF4+`) |
| Ports out | `$00FE`, `$10FE` |

## view

`src/game/view.asm`

### `DrawView` (`$CCBD`)

**Draw the isometric view: background, objects, copy to the screen**

DrawViewBackground clears the buffer `$5B00` and paints the corners outside the map, DrawMapObjects draws every block, building, robot, shot and the ship, CopyViewToScreen puts the 160x160 buffer on the screen. Once per game turn: 3423 times in the 36046 frames of the deep recording (the play loop waits for 10 frames a turn, `$AE1D`). About 578000 T-states a call, 8.3 frames: the reason a turn is 10 frames.

Called by PlayLoop, the menu loops that keep the game going (ListMenu's turn `$AD1F`, DirectControlLoop, DistanceLoop, CombatFireShot), the nuclear blast (`$BA6D`) and DrawPlayScreen. No HALT before the copy: the screen may tear for a frame.

[Animation: `DrawView` at work](img/routines/DrawView.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 369 calls, 16,226 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,423 calls, 150,602 t-states own (0.01 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu`, `DrawPlayScreen` |
| Calls | `DrawMapObjects`, `DrawViewBackground`, `CopyViewToScreen` (tail) |

### `DrawMapObjects` (`$CCC6`)

**Draw the 32 x 16 cells of the view back to front into the view buffer**

Clears the deferred ship position `$FD11` and draws the ship's shadow (sprite 1, height 0) at the ship's view column (ShipX - ViewX) and row ShipY. Then walks the visible part of the map along diagonals: the diagonal x - y = 31 first down to x - y = -15, each from row 0 (x, y) to (x+15, y+15) or the right edge; cells left of the view (x < 0) and cells that are 0 are skipped, every other cell goes to DrawCell with HL = the cell, D = row, E = view column. The order is the painter's order of the projection (DrawSprite): a later cell is nearer the viewer. About 442000 T-states a call with the sprites it draws (1512 M in the deep recording), the heaviest part of the play.

| | |
| --- | --- |
| Runs (the first recording's game window) | 369 calls, 24,207,729 t-states own (8.99 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,423 calls, 225,259,431 t-states own (8.94 %) |
| Called from | `DrawView` |
| Calls | `DrawCell`, `DrawSprite`, `AddAToHL` |
| Reads | `$DD00`-`$EF24` (`Map`); `$F100`-`$F124` (`Map`); `$F300`-`$F324` (`Map`); `$F500`-`$F524` (`Map`); `$F700`-`$F724` (`Map`); `$F900`-`$F924` (`Map`); 3 more ranges |
| Writes | `$CF3F` (`DrawSprite`); `$FD11`-`$FD12` (`work space $FD11+`); `$FFEE`-`$FFFB` (`work space $FFEE+`) |

### `DrawCell` (`$CD18`)

**Draw map cell HL (A = its byte) at view row D, column E**

Cell bits: 0-4 the block type, 5 the right half of a two-cell block (nothing drawn), 6 an object (building, robot or shot, or a robot / shot deferred to this cell), 7 the ship, or the ship deferred to this cell. A block (bit 5 clear, type not 0) is drawn as sprite = type at height 0. Bit 6 calls DrawCellObject. Bit 7 handles the ship: on the first bit-7 cell (`$FD11` = 0, the ship's own cell, set by `$B024`) it looks for the cell drawn last among the neighbouring blocks (FindLatestBlock) and the neighbouring objects (CheckObjectNeighbour at (x-1,y-1), (x-1,y), (x-1,y+1), (x,y+1), (x+1,y+1)). If that is the ship's cell the ship is drawn at once, otherwise bit 7 is set on that later cell and the ship's view position is kept in `$FD11`; when the walk reaches it, bit 7 is cleared again and the ship (sprite 0) is drawn at the kept position, at height Altitude. So the ship is never painted over by a neighbour. In the deep recording the ship was deferred in 2828 of the 3423 view draws.

| | |
| --- | --- |
| Runs (the first recording's game window) | 36,283 calls, 5,174,074 t-states own (1.92 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 375,924 calls, 53,966,061 t-states own (2.14 %) |
| Called from | `DrawMapObjects` |
| Calls | `CheckObjectNeighbour`, `FindLatestBlock`, `DrawCellObject`, `DrawSprite` |
| Reads | `$DD0C`-`$DD0D` (`Map`); `$DF0C`-`$EF24` (`Map`); `$F10C`-`$F524` (`Map`); `$F70C`-`$F724` (`Map`); `$F90C`-`$F924` (`Map`); `$FB0C`-`$FB22` (`Map`); 2 more ranges |
| Writes | `$CF3F` (`DrawSprite`); `$E914` (`Map`); `$EB16` (`Map`); `$ED14`-`$ED18` (`Map`); `$F716` (`Map`); `$F916`-`$F918` (`Map`); 2 more ranges |

### `CheckObjectNeighbour` (`$CD90`)

**Ship: an object at HL counts, and so do the blocks around it**

Used for the ship's neighbours: if HL has bit 6 (a robot, a building or a shot stands there, or one was deferred there) it competes (KeepLaterCell), and then the code falls into FindLatestBlock for the blocks around that object, because the ship flies above objects and their own neighbours can cover it too. In: HL the cell, DE the latest cell so far. Out: DE the latest. HL kept.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,840 calls, 42,320 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 17,115 calls, 394,126 t-states own (0.02 %) |
| Called from | `DrawCell` |
| Calls | `KeepLaterCell` |
| Reads | `$DD0D`-`$DD11` (`Map`); `$DF0D`-`$DF11` (`Map`); `$E10D`-`$F51B` (`Map`); `$F70D`-`$F71A` (`Map`); `$F90D`-`$F918` (`Map`); `$FB15`-`$FB17` (`Map`); 1 more ranges |
| Writes | `$FFEE`-`$FFEF` (`work space $FFEE+`) |

### `FindLatestBlock` (`$CD96`)

**DE = the cell drawn last among DE and the blocks next to HL**

Checks the blocks (bit 5 clear, type not 0) at (x-1,y+1), (x,y+1) (both only when y+1 < 16), (x-1,y) and (x+1,y+1) (y+1 < 16) of cell HL with CheckBlockNeighbour; (x+1,y) is passed over (HL only goes through it). Those are the cells whose sprites can overlap a robot, a shot or the ship standing at HL. HL is kept. Used by DrawCell (the ship) and DrawMover (robots, shots).

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 67,052 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 4,908 calls, 892,321 t-states own (0.04 %) |
| Called from | `DrawCell`, `DrawCellObject` |
| Calls | `CheckBlockNeighbour` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFE6`-`$FFEF` (`work space $FFE6+`) |

### `CheckBlockNeighbour` (`$CDB8`)

**A block at HL competes for the latest cell**

Bit 5 set (the right half of a block) or type 0 (empty): nothing. Otherwise falls into KeepLaterCell.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,472 calls, 55,136 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 19,379 calls, 666,365 t-states own (0.03 %) |
| Called from | `FindLatestBlock` |
| Calls | `KeepLaterCell` |
| Reads | `$DF0D`-`$F522` (`Map`); `$F70D`-`$F722` (`Map`); `$F90D`-`$F922` (`Map`); `$FB15`-`$FB23` (`Map`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFEA`-`$FFED` (`work space $FFEA+`) |

### `KeepLaterCell` (`$CDBF`)

**DE = HL if map cell HL is drawn after cell DE**

The drawing order of DrawMapObjects: diagonals by falling x - y, along a diagonal by rising x. A = (yHL - yDE) + (xDE - xHL) (columns by the low bytes, rows from the high bytes: (H - `$DD`) / 2). A > 0: HL's diagonal is later; A = 0: same diagonal, later when xHL > xDE.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 2,857 calls, 276,937 t-states own (0.01 %) |
| Called from | `CheckObjectNeighbour`, `CheckBlockNeighbour` |

### `FindRobot` (`$CDD8`)

**Z: IY the robot record standing on map cell HL, B = 48 - its slot (slots 0-23 the player's)**

Walks the 48 records of Robots (16 bytes: slots 0-23 the player's, 24-47 the enemy's) comparing the draw cell +`$00`/+`$01` with HL; a free slot has +`$01` = 0 and never matches a map address. Out: Z, IY = the record, B = 48 - slot; NZ when none. DE is kept. A robot deferred by DrawMover is found at the deferred cell, as the walk needs it. Called by DrawCellObject, PlayLoop (the robot under the ship), the captures, the shot hits, the blast and ObjectTop.

| | |
| --- | --- |
| Runs (the first recording's game window) | 773 calls, 3,514,210 t-states own (1.31 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 12,724 calls, 46,728,007 t-states own (1.85 %) |
| Called from | `NewGameSetup`, `GameTurnEnd`, `ObjectTop`, `ScanLane`, `MoveShot`, `DrawCellObject` |
| Reads | `$DA00`-`$DCF1` (`Robots`, `EnemyRobots`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFE0`-`$FFF1` (`work space $FFE0+`) |

### `FindBuilding` (`$CDF5`)

**Z: IY the building record (Buildings) on map cell HL**

Walks the 56 records of Buildings (3 bytes: the map cell address, the type) comparing the cell with HL. Out: Z, IY = the record; NZ when none. DE is kept. Called by DrawCellObject, CheckWarbasePad (the construction menu's pad), ObjectTopBuilding and RemoveBuilding.

| | |
| --- | --- |
| Runs (the first recording's game window) | 757 calls, 1,843,393 t-states own (0.68 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7,301 calls, 17,552,864 t-states own (0.70 %) |
| Called from | `NewGameSetup`, `ObjectTop`, `RemoveBuilding`, `DrawCellObject` |
| Reads | `$FEFF`-`$FFA6` (`work space $FEFF+`) |
| Writes | `$FFE6`-`$FFF3` (`work space $FFE6+`) |

### `DrawCellObject` (`$CE12`)

**Draw the object of map cell HL (bit 6): a robot, a building or a shot**

A robot whose +`$00`/+`$01` is HL goes to DrawMover. A building record goes to its sprite: BuildingSprites[type] at height BuildingHeights[type]. Otherwise the five shot records at `$D7D3` (9 bytes: +`$00`/+`$01` cell, +`$02`/+`$03` x, +`$04` y, +`$05` direction, +`$06` range, +`$07` weapon 1-3, +`$08` height) are searched; a match goes to DrawMover. Nothing found: nothing drawn. 8330 calls in the deep recording: 1485 robots, 6845 buildings, the shot search never ran (no shot stood in the view while it was drawn; the shot path is read from the code and from the shot records at frame 20000).

| | |
| --- | --- |
| Runs (the first recording's game window) | 736 calls, 169,413 t-states own (0.06 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 8,330 calls, 1,950,566 t-states own (0.08 %) |
| Called from | `DrawCell` |
| Calls | `MapCell`, `FindLatestBlock`, `FindRobot`, `FindBuilding`, `DrawMoverSprite` (tail), `DrawSprite`, `AddAToHL` |
| Reads | `$CE56`-`$CE66` (`BuildingSprites`, `BuildingHeights`); `$DA02`-`$DA54` (`Robots`); `$F520` (`Map`); `$F922` (`Map`); `$FEFF`-`$FF00` (`work space $FEFF+`); `$FF4B`-`$FF4E` (`work space $FF4B+`) |
| Writes | `$CF3F` (`DrawSprite`); `$DA20`-`$DA21` (`Robots`); `$F520` (`Map`); `$F922` (`Map`); `$FFE8`-`$FFF3` (`work space $FFE8+`) |

### `DrawMover` (`$CE68`)

**Draw robot or shot IY found at cell HL (view row D, column E), after the blocks that overlap it**

Robots and shots keep their real position in +`$02`/+`$03` (x) and +`$04` (y) and in +`$00`/+`$01` the cell the walk draws them at. At the real cell FindLatestBlock looks for a later neighbouring block; if there is one, the object is moved there (bit 6 set on it, +`$00`/+`$01` = it) and nothing is drawn yet. When the walk reaches the deferred cell, +`$00`/+`$01` is set back to the real cell, the deferred cell's bit 6 is cleared and the view position is walked back from the deferred cell to the real one (x first, then y), and DrawMoverSprite draws the object there. So a robot is drawn after (over) every block whose sprite overlaps it. In the deep recording 1485 robot draws reached here; 18 were deferred (each drawn later at the walked-back position), 1449 drawn at once. No shot reached here: see DrawCellObject.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawMoverSprite` (`$CEC3`)

**Draw IY: a robot record (`$DA00` up) as a stack of parts, a shot as one sprite**

Records at `$D800` and up are robots: DrawRobot. A shot (records at `$D7D3`) is sprite `$2B` + 2 * weapon (+`$07`: 1 cannon, 2 missiles, 3 phasers) + 1 when it flies down or up (+`$05` = 4 or 8), at height +`$08`: `$2D`/`$2E` a cannon shell, `$2F`/`$30` a missile trail, `$31`/`$32` a phaser beam (the sprite pictures in start.bin). The shot branch did not run in the recordings.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1,467 calls, 67,501 t-states own (0.00 %) |
| Called from | `DrawCellObject` (tail) |
| Calls | `DrawRobot` (tail) |

### `DrawRobot` (`$CEE8`)

**Draw robot IY at view row D, column E: its parts bottom up**

Height starts at +`$0D` (the ground under the robot, 0 in the construction menu); for each bit of the parts mask +`$07` from bit 0 (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics) DrawRobotPart draws the part and raises the height. Called by DrawMoverSprite and ShowRobotDesign.

[Animation: `DrawRobot` at work](img/routines/DrawRobot.gif)

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1,496 calls, 527,522 t-states own (0.02 %) |
| Called from | `ShowRobotDesign`, `DrawMoverSprite` (tail) |
| Calls | `DrawRobotPart` |
| Reads | `$DA07`-`$DA5D` (`Robots`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CF3F` (`DrawSprite`); `$FFE8`-`$FFF1` (`work space $FFE8+`) |

### `DrawRobotPart` (`$CEFD`)

**Draw part 8 - B of robot IY facing +`$08`, then raise the height**

Sprite = `$16` + the parts table `$D6C8`[4 * part + direction], direction = the number of the lowest set bit of +`$08` (0 right, 1 left, 2 down, 3 up, the Input bits). After drawing, the height (`$CF3F`) grows by the part's height `$D7B4`[part]: bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 4,380 calls, 1,254,224 t-states own (0.05 %) |
| Called from | `DrawRobot` |
| Calls | `DrawSprite`, `AddAToHL` |
| Reads | `$CF3F` (`DrawSprite`); `$D6C8`-`$D6E7` (`PartSpriteTable`); `$D7B4`-`$D7BB` (`PartHeights`); `$DA08`-`$DA58` (`Robots`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CF3F` (`DrawSprite`); `$FFE6`-`$FFEF` (`work space $FFE6+`) |

### `DrawSprite` (`$CF2D`)

**Draw sprite A at view row D, column E, height (`$CF3F`) into the view buffer**

The isometric projection: the half-byte column L = 2E + D - 24, the pixel row of the sprite's bottom line H = 8D + 100 - 4E - height. So a step along x moves 8 pixels right and 4 up, a step along y 4 right and 8 down. The sprite table `$D6E8` holds two words a sprite (A*2 + 1 for an odd half-byte column: the image shifted by 4 pixels). A sprite: rows, width in bytes, then for each row bottom up (mask, pixels) byte pairs; drawn by AND mask, OR pixels into the 20-byte rows of the buffer `$5B00`, upwards. Clipping: right of column 19 or a bottom line past row `$E1`: nothing; bottom lines `$A0-$E1` skip the rows below the buffer; a negative column skips the left bytes of each row (`$CFAF`), a sprite past column 19 the right bytes; the top stops at `$5B00`. 116709 calls, 978 M T-states in the deep recording.

| | |
| --- | --- |
| Runs (the first recording's game window) | 10,475 calls, 104,152,964 t-states own (38.68 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 116,709 calls, 977,827,468 t-states own (38.82 %) |
| Called from | `DrawMapObjects`, `DrawCell`, `DrawCellObject`, `DrawRobotPart` |
| Calls | `TableWord`, `AddAToHL` |
| Reads | `$5B09`-`$6777` (`ViewBuffer`); `$6980`-`$7C95` (`SprTracksX`, `SprTracksXRows`, `SprTracksXOdd`, `SprTracksXOddRows` and 46 more); `$7D80`-`$8089` (`SprPhasersYp`, `SprPhasersYpRows`, `SprPhasersYpOdd`, `SprPhasersYpOddRows` and 4 more); `$8224`-`$88E1` (`SprElectronicsXp`, `SprElectronicsXpRows`, `SprElectronicsXpOdd`, `SprElectronicsXpOddRows` and 24 more); `$8E3A`-`$92F9` (`SprShip`, `SprShipRows`, `SprShipOdd`, `SprShipOddRows` and 11 more); `$9914`-`$9D9B` (`SprBlockLow`, `SprBlockLowRows`, `SprBlockLowOdd`, `SprBlockLowOddRows` and 4 more); 2 more ranges |
| Writes | `$5B09`-`$6777` (`ViewBuffer`); `$CFAF` (`DrawSprite`); `$FFDA`-`$FFF9` (`work space $FFDA+`) |

### `DrawViewBackground` (`$CFD7`)

**Clear the view buffer and paint the corners outside the map**

ClearViewBuffer, FillViewCorner (the solid top left corner), then the diagonal edge strips from `$D6A8`: 6 strips down and left from buffer row 0, column 10 (the top left edge), 3 from row 136, column 18 and 4 of the other diagonal (`$D6B8`) from row 128, column 18 (the bottom right corner, the blue area that DrawPlayScreen colours `$41` / `$71`). Called by DrawView and once by `$A62D`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 370 calls, 58,849 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,424 calls, 544,492 t-states own (0.02 %) |
| Called from | `NewGameSetup`, `DrawView` |
| Calls | `ClearViewBuffer`, `FillViewCorner`, `DrawEdgeStrips` (tail) |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFFA`-`$FFFB` (`work space $FFFA+`) |

### `ClearViewBuffer` (`$CFFE`)

**Zero the view buffer `$5B00-$677F` (20 bytes x 160 rows)**

Pushes HL = 0 with SP at `$6780` (198 x 16 bytes, SP kept in `$FD08`), then clears the first 32 bytes with LDIR. Called by DrawViewBackground, ShowRobotDesign and `$CB52`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 370 calls, 9,494,990 t-states own (3.53 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,460 calls, 83,090,606 t-states own (3.30 %) |
| Called from | `StartRobot`, `ShowRobotDesign`, `DrawViewBackground` |
| Reads | `$5B00`-`$5B1E` (`ViewBuffer`); `$FD08`-`$FD09` (`work space $FD08+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$5B00`-`$609F` (`ViewBuffer`); `$60EE`-`$613F` (`ViewBuffer`); `$61BE`-`$621F` (`ViewBuffer`); `$627E`-`$63CF` (`ViewBuffer`); `$63EE`-`$647F` (`ViewBuffer`); `$64EE`-`$660F` (`ViewBuffer`); 4 more ranges |

### `FillViewCorner` (`$D026`)

**Fill the top left corner of the view buffer: a staircase of 5 bands**

5 bands of 8 rows; the first fills 10 bytes of each row, each next band 2 fewer (10, 8, 6, 4, 2). The fill and skip counts are the operands `$D038` and `$D041`, reset to 10 at the start and moved by 2 after each band.

| | |
| --- | --- |
| Runs (the first recording's game window) | 370 calls, 3,732,862 t-states own (1.39 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,424 calls, 34,191,334 t-states own (1.36 %) |
| Called from | `DrawViewBackground` |
| Calls | `AddAToHL` |
| Reads | `$D038`-`$D041` (`FillViewCorner`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$5B00`-`$5D95` (`ViewBuffer`); `$5DA8`-`$5DA9` (`ViewBuffer`); `$5DBC`-`$5DBD` (`ViewBuffer`); `$5DD0`-`$5DD1` (`ViewBuffer`); `$5DE4`-`$5DE5` (`ViewBuffer`); `$5DF8`-`$5DF9` (`ViewBuffer`); 3 more ranges |

### `DrawEdgeStrips` (`$D057`)

**Copy B strips of 8 rows x 2 bytes (pattern HL) into the buffer, each 8 rows down and 2 bytes left**

The diagonal edge of the map in the view. The patterns are at `$D6A8` (ink on the left: `$FFFF`, `$FFFC`, ..., `$C000`) and `$D6B8` (ink on the right).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,110 calls, 3,276,415 t-states own (1.22 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 10,272 calls, 31,691,777 t-states own (1.26 %) |
| Called from | `DrawViewBackground` (tail) |
| Reads | `$D6A8`-`$D6C7` (`ViewEdgeA`, `ViewEdgeB`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$5B0A`-`$5EAD` (`ViewBuffer`); `$6512`-`$6717` (`ViewBuffer`); `$6728`-`$672B` (`ViewBuffer`); `$673C`-`$673F` (`ViewBuffer`); `$6750`-`$6753` (`ViewBuffer`); `$6764`-`$6767` (`ViewBuffer`); 2 more ranges |

### `CopyViewToScreen` (`$D071`)

**Copy the view buffer to the screen at character row 1, column 1 (20 x 20 characters)**

160 lines of 20 bytes with unrolled LDI, the destination stepped through the screen's thirds. 256 M T-states in the deep recording.

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 27,846,162 t-states own (10.34 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,422 calls, 256,270,000 t-states own (10.17 %) |
| Called from | `DrawView` (tail) |
| Reads | `$5B00`-`$677F` (`ViewBuffer`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4021`-`$5194` (screen); `$5201`-`$5294` (screen); `$5301`-`$5394` (screen); `$5401`-`$5494` (screen); `$5501`-`$5594` (screen); `$5601`-`$5694` (screen); 2 more ranges |

## screen

`src/game/screen.asm`

### `ClearScreen` (`$D0B9`)

**Clear the screen (pixels and attributes to 0) and make the border black**

Clears the 6912 bytes of pixels and attributes from `$4000` and sets the border black (and the speaker off) with OUT (`$FE`),0. Called by DrawPlayScreen, MainMenu `$C100`, RedefineKeys `$C34A` and OpenConstructionMenu `$C865`. Changes A, BC, DE, HL.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 55 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 15 calls, 2,779,035 t-states own (0.11 %) |
| Called from | `ConstructionMenu`, `DrawPlayScreen` |
| Calls | `ClearScreenFill` |
| Reads | `$4000`-`$5AFE` (screen); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4000`-`$5AFF` (screen); `$FFF6`-`$FFFB` (`work space $FFF6+`) |
| Ports out | `$00FE` |

### `ClearScreenFill` (`$D0C7`)

**ClearScreen's LDIR**

An entry only because the recording work/game started inside this LDIR; no code jumps here.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 324,839 t-states own (0.12 %) |
| Called from | `ClearScreen` |
| Reads | `$4000`-`$5AFE` (screen); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4001`-`$5AFF` (screen); `$FFFA`-`$FFFB` (`work space $FFFA+`) |

### `DrawPlayScreen` (`$D0CA`)

**Draw the whole play screen: the view, its frame, the colours, DAY / TIME / RADAR**

ClearScreen and DrawView, then the frame of the view (22 x 22 characters from (0,0): double lines at the top and bottom, `$81` lines at the sides), the attributes: `$07` everywhere, `$78` on the frame, `$70` (yellow paper) in the view, `$71` and `$41` (blue) in its bottom right corner, the area past the map's edge. Prints PlayScreenText. Called at the start of play (`$A68E`) and after the construction menu (`$CB52`).

PlayScreenText ends the code: PrintInline returns into ShowStatusPanel, so the panel's labels come with every play screen; the numbers come with the next UpdateStatusPanel. The radar appears at the next frame's PlayInterrupt.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 52,237 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 8 calls, 444,044 t-states own (0.02 %) |
| Called from | `NewGameSetup`, `StartRobot` |
| Calls | `DrawView`, `ClearScreen`, `NextScreenLine`, `AddAToHL`, `PrintInline` |
| Reads | `$4000`-`$4014` (screen); `$4701`-`$4713` (screen); `$50A1`-`$50B3` (screen); `$57A0`-`$57B4` (screen); `$5800`-`$5AFE` (screen); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4000`-`$50B5` (screen); `$5100`-`$51A0` (screen); `$51B5` (screen); `$5200`-`$52A0` (screen); `$52B5` (screen); `$5300`-`$53A0` (screen); 10 more ranges |

### `ShowStatusPanel` (`$D1E5`)

**Clear the right panel and print the status labels**

ClearPanel, then StatusPanelText. Called when the robot menu ends (CloseRobotMenu `$A819`) and at the game's end (GameStop `$AF07`). DrawPlayScreen falls into it after its own string, so every play screen gets the labels. The numbers come from UpdateStatusPanel.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 34 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 15 calls, 510 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `PrintInline` |
| Calls | `ClearPanel`, `PrintInline` |

### `UpdateStatusPanel` (`$D293`)

**Print the panel's numbers: resources, then both sides' buildings and robots**

Skipped while PanelBusy (`$FD39`) is not 0 (the robot menu owns the panel). Prints the seven Resources at (17-23, 30) as two digits, attribute `$4E`; the enemy's building counts EnemyBuildings `$FD42` (by type 0-6) at (6-12, 22) and robots EnemyRobotCount `$FD49` at (13,22); the player's counts PlayerBuildings `$FD3A` at (6-12, 31) and robots PlayerRobotCount `$FD41` at (13,30), attribute `$47`. Called after the counts change (a capture `$AE1A`, the day's production `$AE4A`, a robot removed `$B150`, an enemy robot built `$B91C`, the blast `$BA84`) and from CheckWarbasePad (`$A70A`) after a robot is built.

The four parts are each a CALL PrintInline with a position string and the code after it (the entries below). PrintNewline comes before each resource, so the first lands on row 17.

| | |
| --- | --- |
| Runs (the first recording's game window) | 6 calls, 234 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 83 calls, 3,226 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `GameTurnEnd`, `DailyProduction`, `UpdateRobot`, `EnemyCommander`, `PrintInline` |
| Calls | `PrintInline` |
| Reads | `$FD39` (`work space $FD39+`) |

### `PrintResourceValues` (`$D2A3`)

**The seven resource values, each on the next line (the tail of `$D293`)**

Seven lines from Resources (`$FD22`: general, electronics, nuclear, phasers, missiles, cannon, chassis), each PrintNewline then PrintNumber2: rows 17-23, column 30, blank leading zero. Falls into the next position string.

| | |
| --- | --- |
| Runs (the first recording's game window) | 6 calls, 5,340 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 82 calls, 73,018 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2`, `PrintInline`, `PrintNewline` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFFA`-`$FFFB` (`work space $FFFA+`) |

### `PrintInsgCounts` (`$D2C1`)

**The enemy's building counts and its robots (the tail of `$D293`)**

The enemy's seven building counts EnemyBuildings (`$FD42`: warbases, then the six factory kinds) as single digits down column 22, rows 6-12; then its robots EnemyRobotCount (`$FD49`, the byte after them) at (13,22) with a leading zero, over the space before ROBOTS. Falls into the player's position string.

| | |
| --- | --- |
| Runs (the first recording's game window) | 6 calls, 408 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 82 calls, 5,576 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintDigitColumn`, `PrintNumber2Zero`, `PrintInline` |
| Reads | `$FD49` (`work space $FD49+`) |

### `PrintHumnCounts` (`$D2D2`)

**The player's building counts (the tail of `$D293`)**

The player's seven building counts PlayerBuildings (`$FD3A`) down column 31, rows 6-12. HL ends at PlayerRobotCount. Falls into the next position string.

| | |
| --- | --- |
| Runs (the first recording's game window) | 6 calls, 264 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 82 calls, 3,608 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintDigitColumn`, `PrintInline` |

### `PrintHumnRobots` (`$D2DF`)

**The player's robots `$FD41`, two digits (the tail of `$D293`)**

PlayerRobotCount (`$FD41`, HL from PrintHumnCounts) as two digits with a leading zero; the JP returns from UpdateStatusPanel.

| | |
| --- | --- |
| Runs (the first recording's game window) | 6 calls, 102 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 82 calls, 1,394 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2Zero` (tail) |
| Reads | `$FD41` (`work space $FD41+`) |

### `PrintDigitColumn` (`$D2E3`)

**Print seven bytes from HL as single digits, one under the other**

Each byte as "0" + n (a count of 10 or more would print ":" and the characters after it; never seen, a side has at most 4 warbases), then PrintNewline: the same column one row down. HL ends past the seventh byte (the robot count that follows). Used by PrintInsgCounts and PrintHumnCounts.

| | |
| --- | --- |
| Runs (the first recording's game window) | 12 calls, 9,300 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 164 calls, 127,157 t-states own (0.01 %) |
| Called from | `PrintInsgCounts`, `PrintHumnCounts` |
| Calls | `PrintCharKeep`, `PrintNewline` |
| Reads | `$FD3A`-`$FD48` (`work space $FD3A+`) |

### `ClearPanel` (`$D2F6`)

**Blank the right panel: 22 lines of 10 spaces from (2,22) in attribute 0**

Called by ShowStatusPanel and by the robot menus (RobotMenuShow `$A732`, CloseRobotMenu `$A812`, OrdersMenu `$A971`, OrderMove `$AA15`, TargetMenu `$AAD2`, CaptureMenu `$AB4E`, CombatMenu `$AC00`) and GameStop (`$AF04`) before they print. Attribute 0 (black on black) hides the area at once; rows 22-23 of the panel (STRENGTH) are cleared too.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 17 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 50 calls, 850 t-states own (0.00 %) |
| Called from | `RobotMenuShow`, `ShowOrderMiles`, `OrdersMenu`, `TargetMenu`, `CaptureMenu`, `ShowStatusPanel` |
| Calls | `PrintInline` |

### `ClearPanelLines` (`$D301`)

**22 lines (the tail of ClearPanel)**

B = 22: rows 2-23. B survives each PrintInline: it works in the alternate registers.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 7 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 50 calls, 350 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ClearPanelLine` |

### `ClearPanelLine` (`$D303`)

**Print 10 spaces and a newline**

One CALL PrintInline with PanelBlankLine; the code goes on at ClearPanelNext.

| | |
| --- | --- |
| Runs (the first recording's game window) | 22 calls, 374 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1,100 calls, 18,700 t-states own (0.00 %) |
| Called from | `ClearPanelLines`, `ClearPanelNext` (tail) |
| Calls | `PrintInline` |

### `ClearPanelNext` (`$D312`)

**The next of the 22 lines**

DJNZ back to ClearPanelLine for the 22 rows, then the return from ClearPanel.

| | |
| --- | --- |
| Runs (the first recording's game window) | 22 calls, 291 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1,100 calls, 14,550 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ClearPanelLine` (tail) |

### `DrawMaskedUp` (`$D315`)

**Draw a masked image on the screen: C lines of B (mask, pixel) pairs from HL to DE, going up**

Each line ANDs the mask and ORs the pixels; DE moves one screen line up (PrevScreenLine) after each. The sprite format of DrawSprite without its header: the caller (PartIconDraw `$C895`, the construction menu's part pictures, 56 calls) passes B = bytes a line, C = lines, HL = the first pair of the bottom line, DE = the screen address of the bottom line. Out: HL past the picture. No clipping.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 56 calls, 403,599 t-states own (0.02 %) |
| Called from | `ConstructionMenu` |
| Calls | `PrevScreenLine` |
| Reads | `$4030`-`$4212` (screen); `$4230`-`$4312` (screen); `$4330`-`$4412` (screen); `$4430`-`$4512` (screen); `$4530`-`$4612` (screen); `$4630`-`$4712` (screen); 9 more ranges |
| Writes | `$4030`-`$4212` (screen); `$4230`-`$4312` (screen); `$4330`-`$4412` (screen); `$4430`-`$4512` (screen); `$4530`-`$4612` (screen); `$4630`-`$4712` (screen); 2 more ranges |

### `NextScreenLine` (`$D32A`)

**HL = the screen address one pixel line down**

The Spectrum's screen order: the line inside a character row is bits 0-2 of H, the character row bits 5-7 of L, the third bits 3-4 of H. Keeps everything but A and the flags. Used by ShowRadar, the frame of DrawPlayScreen, the big characters of PrintBigChar and ShowRobotDesign's copy (`$CC74`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 59,852 calls, 1,777,936 t-states own (0.66 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 561,880 calls, 16,687,712 t-states own (0.66 %) |
| Called from | `ShowRobotDesign`, `DrawPlayScreen`, `PrintBigChar`, `ShowRadar` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF6`-`$FFF7` (`work space $FFF6+`) |

### `PrevScreenLine` (`$D339`)

**DE = the screen address one pixel line up**

The reverse of NextScreenLine on DE: used only by DrawMaskedUp, which draws from the bottom line up. Keeps everything but A and the flags.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1,323 calls, 40,157 t-states own (0.00 %) |
| Called from | `DrawMaskedUp` |

### `TableWord` (`$D348`)

**HL = the word at HL + 2*A**

The sprite table lookup of DrawSprite, also ConstructionMenu (PartIconLoop `$C881`) and DrawShape (`$BD67`). A is an index 0-127 (A*2 must fit a byte). Changes A.

| | |
| --- | --- |
| Runs (the first recording's game window) | 10,565 calls, 581,379 t-states own (0.22 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 116,855 calls, 6,429,419 t-states own (0.26 %) |
| Called from | `DrawShape`, `ConstructionMenu`, `DrawSprite` |
| Calls | `AddAToHL` |
| Reads | `$BF9C`-`$BFB1` (`ShapeTable`); `$D6E8`-`$D6FD` (`SpriteTable`); `$D724`-`$D79B` (`SpriteTable`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFE2`-`$FFF5` (`work space $FFE2+`) |

### `AddAToHL` (`$D351`)

**HL += A**

A changed to the new H; BC, DE kept. Used everywhere a table is indexed by a byte (about 50 call sites).

| | |
| --- | --- |
| Runs (the first recording's game window) | 41,123 calls, 1,357,173 t-states own (0.50 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 434,037 calls, 14,328,446 t-states own (0.57 %) |
| Called from | `PaintMenuItem`, `TerrainTop`, `ObjectTop`, `SteerByOrder`, `SetStepDelay`, `EnemyCommander`, `CountBases`, `SetBaseOwner`, `TitleColourCycle`, `ConstructionMenu`, `ConstructionMenuLoop`, `PrintMenuResources`, `ShowRobotDesign`, `DrawMapObjects`, `DrawCellObject`, `DrawRobotPart`, `DrawSprite`, `FillViewCorner`, `DrawPlayScreen`, `TableWord`, `PrintBigChar` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFDE`-`$FFF5` (`work space $FFDE+`) |

### `Random` (`$D358`)

**A = a pseudo-random byte**

A 32-bit shift register at RandomSeed `$FD00-$FD03` (big end first, seeded `$39`,`$30`,`$39`,`$30` by Start): shifted left once, the new bit = bit 3 XOR bit 6 of `$FD00`. Then the byte at the index the previous call used (kept in the operand `$D371`) gives, by its low 2 bits, the new index, and A = the byte there. HL is kept; A and the flags change. 43256 calls in the deep recording: the robot AI (`$B1AB`, `$B1F5`, `$B331`), the enemy commander `$B7F4` and its spawns, the blast's scenery, GameTurn (`$AD62`) and the noise of SoundEffect.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,877 calls, 364,138 t-states own (0.14 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 43,256 calls, 8,393,927 t-states own (0.33 %) |
| Called from | `GameTurn`, `UpdateRobot`, `RobotStep`, `SteerByOrder`, `EnemyCommander`, `SoundEffect` |
| Reads | `$FD00`-`$FD03` (`work space $FD00+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$D371` (`Random`); `$FD00`-`$FD03` (`work space $FD00+`); `$FFF2`-`$FFF9` (`work space $FFF2+`) |

## controls

`src/game/controls.asm`

### `WaitKey` (`$D37C`)

**ReadControls; while key 1 (Input bit 7) is held, the pause: wait for another key**

In: nothing. Out: A = Input (also in Input `$FD0C`); the flags of the last OR A. When the pause key (bit 7) is held it loops in PauseLoop until some other control is pressed with the pause key up, then falls into ReadControls again: the control that ended the pause is this turn's input. Changes A, BC, HL. Called once a turn by PlayLoop, DirectControlLoop, DistanceLoop, ListMenu, WaitRelease, GameOverKey, RobotDirectControl and ConstructionMenuLoop.

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 11,776 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,814 calls, 314,181 t-states own (0.01 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu`, `WaitRelease`, `ConstructionMenuLoop` |
| Calls | `ReadControls` |

### `ReadControls` (`$D38A`)

**Input from the redefinable keys (KeyTable) or the joystick the menu chose (Controls)**

The eight keys of KeyTable are rotated into C one by one (RL C, starting from C = 1: after the eighth the 1 drops into the carry and ends the loop), entry 0 ending in bit 7. Then the joystick by Controls (`$D3E4`): 2 Kempston (port `$1F`, bits 0-4 already right, left, down, up, fire), 3 Interface 2 (port `$EFFE`, keys 6-0, inverted and reordered), else none. Out: A = Input = joystick OR keys. Changes B, C, HL. 9814 calls in the deep recording.

| | |
| --- | --- |
| Runs (the first recording's game window) | 368 calls, 259,440 t-states own (0.10 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 9,814 calls, 6,969,784 t-states own (0.28 %) |
| Called from | `WaitKey` |
| Reads | `$D3CC`-`$D3E4` (`KeyTable`, `Controls`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD0C` (`work space $FD0C+`); `$FFF0`-`$FFFB` (`work space $FFF0+`) |
| Ports in | `$001F`, `$7FFE`, `$DFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

## print

`src/game/print.asm`

### `PrintNumber2` (`$D3E5`)

**Print A (0-99) as two digits, a leading zero blank**

In: A. HL = A, E = `$20`, then PrintTensUnits: a space for a leading zero. Used for the resources (PrintResourceValues), the construction menu values and the miles of ADVANCE / RETREAT. A value of 100 or more would print a tens "digit" above 9 (":" and on); the game caps every resource at 99.

| | |
| --- | --- |
| Runs (the first recording's game window) | 42 calls, 1,260 t-states own (0.00 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 777 calls, 23,310 t-states own (0.00 %) |
| Called from | `PrintMenuResourceValue`, `PrintResourceValues` |
| Calls | `PrintTensUnits` (tail) |

### `PrintNumber2Zero` (`$D3EC`)

**Print A (0-99) as two digits with a leading zero**

The clock (`$AD90`, 6828 calls: "20.20") and the robot counts of the panel.

| | |
| --- | --- |
| Runs (the first recording's game window) | 746 calls, 22,380 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 6,992 calls, 209,779 t-states own (0.01 %) |
| Called from | `GameTurnEnd`, `PrintInsgCounts`, `PrintHumnRobots` (tail) |
| Calls | `PrintTensUnits` (tail) |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFFA`-`$FFFB` (`work space $FFFA+`) |

### `PrintNumber5` (`$D3F3`)

**Print HL as five digits, leading zeros blank**

Used by `$AD90` for the day number ("DAY:    4"). Falls into PrintNumber3.

| | |
| --- | --- |
| Runs (the first recording's game window) | 367 calls, 32,296 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 3,414 calls, 208,311 t-states own (0.01 %) |
| Called from | `GameTurnEnd` |
| Calls | `PrintDigit` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFFA`-`$FFFB` (`work space $FFFA+`) |

### `PrintNumber3` (`$D401`)

**Print HL as three digits (E = `$20`: leading zeros blank, else printed)**

The operand `$FF9C` is -100 (the source writes it so with @isub; as a label it would read Buildings+155, a false symbol). Used by PrintMenuTotal and `$A833`.

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 140 calls, 95,977 t-states own (0.00 %) |
| Called from | `ShowStrengthValue`, `PrintMenuTotal` (tail) |
| Calls | `PrintDigit` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFFA`-`$FFFB` (`work space $FFFA+`) |

### `PrintTensUnits` (`$D407`)

**Print the tens and the units of HL**

HL = the value (0-99, else the tens "digit" runs past 9: 200 prints as "D0"), E = the leading-zero flag. The tens by PrintDigit, the units always printed. The tail of PrintNumber2, PrintNumber2Zero, PrintNumber3 and PrintNumber5.

| | |
| --- | --- |
| Runs (the first recording's game window) | 788 calls, 55,459 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 7,769 calls, 543,580 t-states own (0.02 %) |
| Called from | `PrintNumber2` (tail), `PrintNumber2Zero` (tail) |
| Calls | `PrintDigit`, `PrintCharKeep` (tail) |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF4`-`$FFFB` (`work space $FFF4+`) |

### `PrintDigit` (`$D413`)

**Print the digit of HL for the power -BC; HL keeps the rest**

Counts how often BC (a negative power of 10) can be added. A zero while E = `$20` prints a space and keeps E; any printed digit increments E, so later zeros print as 0.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,256 calls, 197,148 t-states own (0.07 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 21,705 calls, 1,909,905 t-states own (0.08 %) |
| Called from | `PrintNumber5`, `PrintNumber3`, `PrintTensUnits` |
| Calls | `PrintCharKeep` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF0`-`$FFF9` (`work space $FFF0+`) |

### `PrintCharKeep` (`$D427`)

**PrintChar A with BC, DE, HL kept (EXX around)**

PrintChar in the alternate registers: the caller's BC, DE, HL are kept (the number printers keep HL, E and the loop counters in them). A and the flags change.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,862 calls, 135,170 t-states own (0.05 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 37,701 calls, 1,319,915 t-states own (0.05 %) |
| Called from | `ShowStrengthValue` (tail), `GameTurnEnd`, `PrintDigitColumn`, `PrintTensUnits` (tail), `PrintDigit` |
| Calls | `PrintChar` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF8`-`$FFF9` (`work space $FFF8+`) |

### `PrintInline` (`$D42D`)

**print the text after the CALL: 0 ends, 1 Y X a position, 2 A an attribute, 3 the next line, 4 N a setting, else a character**

In: the string after the CALL. Pops the return address, takes a byte, pushes the address one byte on, until a 0: the RET then lands after the string. Each byte goes to PrintControl (codes 1-4 and characters). Works in the alternate set (EXX at both ends), so the caller's BC, DE, HL are kept; A and the flags change. Callers also end in it with JP (PrintKeyPrompt `$C40C`), so the bytes after their own CALL are the string. About 60 call sites: every screen and panel text.

| | |
| --- | --- |
| Runs (the first recording's game window) | 431 calls, 162,138 t-states own (0.06 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 5,314 calls, 2,723,226 t-states own (0.11 %) |
| Called from | `RobotMenuShow`, `ShowOrder`, `ShowStrength`, `OrdersMenu`, `TargetMenu`, `CaptureMenu`, `GameTurn`, `MainMenuOptions`, `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option`, `PrintTitle`, `ControlsOptionAttr`, `ConstructionMenu`, `PrintMenuResources`, `PrintMenuResource`, `DrawPlayScreen`, `ShowStatusPanel`, `UpdateStatusPanel`, `PrintResourceValues`, `PrintInsgCounts`, `PrintHumnCounts`, `ClearPanel`, `ClearPanelLine` |
| Calls | `ShowOrder`, `ShowOrderMiles`, `ShowStrengthValue`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose`, `GameTurnEnd`, `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option`, `MainMenuKeys`, `PrintTitleEnd`, `ControlsOptionPlain`, `ControlsOptionChosen`, `ConstructionMenuSetup`, `PrintMenuTotal`, `PrintMenuResourceValue`, `ShowStatusPanel`, `UpdateStatusPanel`, `PrintResourceValues`, `PrintInsgCounts`, `PrintHumnCounts`, `PrintHumnRobots`, `ClearPanelLines`, `ClearPanelNext`, `PrintControl` |
| Reads | `$A738`-`$ABB8` (`RobotMenuText`, `ShowOrder`, `OrderLineHead`, `OrderLine` and 35 more); `$AD88`-`$AD8F` (`ClockPos`); `$C109`-`$C191` (`MenuStartText`, `MenuKeyboardOption`, `MenuKeyboardText`, `MenuKempstonOption` and 3 more); `$C1E6`-`$C1FB` (`TitleText`); `$C33F`-`$C348` (`OptionAttrPlain`, `ControlsOptionPlain`, `OptionAttrChosen`); `$C8BE`-`$C9E6` (`ConstructionTitleText`, `PartNamesText`, `ExitStartText`, `PartCostsText` and 1 more); 3 more ranges |
| Writes | `$FFF4`-`$FFFD` (`work space $FFF4+`) |

### `PrintControl` (`$D43C`)

**PrintInline's byte A: control codes 1-4 or a character**

1 Y X: the position (row Y, column X, kept in `$FD32`/`$FD31`). 2 A: the attribute `$FD13`. 3: newline (the next row, the same column). 4 N: the size, high nibble the height in character rows (`$FD16`), low nibble the width in bytes (`$FD17`); 0 = normal. A character goes to PrintChar for size 0, else to PrintBigChar. The operands are read through the caller's return address on the stack, two levels up.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,795 calls, 218,071 t-states own (0.08 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 31,909 calls, 3,421,937 t-states own (0.14 %) |
| Called from | `PrintInline` |
| Calls | `PrintNewline` (tail), `SetPrintPos` (tail), `PrintChar` (tail), `PrintBigChar` (tail) |
| Reads | `$A739`-`$A831` (`RobotMenuText`, `ShowOrder`, `OrderLineHead`, `OrderLine` and 6 more); `$A978`-`$A98D` (`OrdersMenuText`); `$AAD9`-`$AB80` (`DestroyMenuText`, `DestroyMenuChoose`, `CaptureMenu`, `CaptureMenuText`); `$AD89`-`$AD8E` (`ClockPos`); `$C10A`-`$C16C` (`MenuStartText`, `MenuKeyboardOption`, `MenuKeyboardText`, `MenuKempstonOption` and 3 more); `$C1E7`-`$C1F5` (`TitleText`); 6 more ranges |
| Writes | `$FD13`-`$FD17` (`work space $FD13+`); `$FD31`-`$FD32` (`work space $FD31+`); `$FFF0`-`$FFF9` (`work space $FFF0+`) |

### `PrintNewline` (`$D470`)

**The next print row, the same column**

PrintRow + 1, then SetPrintPos. Reached by code 3 inside PrintInline and called directly by the number printers' callers (GameTurnEnd `$AD96`, ResourceValueLoop, PrintDigitColumn, ReadFireKey `$C3CA`). Changes A, BC, HL.

| | |
| --- | --- |
| Runs (the first recording's game window) | 554 calls, 29,916 t-states own (0.01 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 6,845 calls, 369,706 t-states own (0.01 %) |
| Called from | `GameTurnEnd`, `PrintResourceValues`, `PrintDigitColumn`, `PrintControl` (tail) |
| Calls | `SetPrintPos` (tail) |
| Reads | `$FD31`-`$FD32` (`work space $FD31+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD31`-`$FD32` (`work space $FD31+`); `$FFF2`-`$FFFB` (`work space $FFF2+`) |

### `SetPrintPos` (`$D493`)

**Print position: B = row, C = column -> `$FD04` the screen address, `$FD14` the attribute address**

In: B = row 0-23, C = column 0-31. PrintAddr = `$4000` + (B AND `$18`) * 256 + (B AND 7) * 32 + C, the top line of the character cell; PrintAttrAddr = `$5800` + 32 * B + C. Changes A, HL. Used by SetPosition and PrintNewline.

| | |
| --- | --- |
| Runs (the first recording's game window) | 955 calls, 123,195 t-states own (0.05 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 11,419 calls, 1,473,697 t-states own (0.06 %) |
| Called from | `PrintControl` (tail), `PrintNewline` (tail) |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FD04`-`$FD15` (`work space $FD04+`); `$FFF0`-`$FFFB` (`work space $FFF0+`) |

### `PrintChar` (`$D4B1`)

**Print character A at the print position in the print attribute, advance one column**

The font is at `$6680` + 8*code (`$6780` for the space, right after the view buffer). 8 lines into (`$FD04`), the attribute (`$FD13`) into (`$FD14`), both advanced.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4,374 calls, 2,238,956 t-states own (0.83 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 55,512 calls, 28,159,096 t-states own (1.12 %) |
| Called from | `PrintCharKeep`, `PrintControl` (tail) |
| Reads | `$6780`-`$6787` (`Font`); `$67A8`-`$67BF` (`Font`); `$67E8`-`$6857` (`Font`); `$6878`-`$694F` (`Font`); `$FD04`-`$FD15` (`work space $FD04+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4016`-`$483F` (screen); `$4855`-`$57DF` (screen); `$57F6`-`$57FF` (screen); `$5816`-`$583F` (screen); `$5856`-`$5A1F` (screen); `$5A36`-`$5A5F` (screen); 4 more ranges |

### `PrintBigChar` (`$D4DA`)

**Print character A scaled: each line repeated `$FD16` times, width 1 or 2 bytes (`$FD17`)**

Width 1: each glyph line written `$FD16` times (2: a character two rows high, "RADAR:"). Width 2: each glyph byte doubled to 16 bits. Then the screen address moves on by the width and a block of width x height attribute cells gets `$FD13`. 180 calls in the deep recording.

| | |
| --- | --- |
| Runs (the first recording's game window) | 43 calls, 125,706 t-states own (0.05 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 180 calls, 444,730 t-states own (0.02 %) |
| Called from | `PrintControl` (tail) |
| Calls | `NextScreenLine`, `AddAToHL` |
| Reads | `$6780`-`$6787` (`Font`); `$67F0`-`$6807` (`Font`); `$6850`-`$6857` (`Font`); `$6888`-`$68CF` (`Font`); `$68E8`-`$68FF` (`Font`); `$6910`-`$692F` (`Font`); 2 more ranges |
| Writes | `$4003`-`$47F4` (screen); `$4868`-`$4F94` (screen); `$50C0`-`$57E5` (screen); `$5803`-`$580C` (screen); `$5823`-`$5875` (screen); `$58AB`-`$58B4` (screen); 7 more ranges |

## interrupts

`src/game/interrupts.asm`

### `PlayInterrupt` (`$D566`)

**the interrupt handler of play, one a frame**

Installed by EnterPlay (`$A694`) and when the construction menu ends (`$CBA2`). Keeps AF, BC, DE, HL (not IX, IY, the alternate set: the routines it calls do not use them). TurnFrames + 1 (TurnPace `$AE1D` waits for 10, then zeroes it); RadarPhase toggled, ShowRadar with RadarOwn / `$4D` on phase 0, RadarEnemy / `$4E` on phase 1; SoundFx not 0: counted on (a tone ends at `$80`, a noise when it wraps to 0) and SoundEffect plays this frame's step. Ends in StartInterrupt's EI; RET. 34645 entries in the deep recording, one a frame of play.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,672 calls, 804,168 t-states own (0.30 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 34,645 calls, 7,661,186 t-states own (0.30 %) |
| Calls | `StartInterrupt`, `ShowRadar`, `SoundEffect` |
| Reads | `$FD1A` (`work space $FD1A+`); `$FD34` (`work space $FD34+`); `$FD53` (`work space $FD53+`) |
| Writes | `$FD1A` (`work space $FD1A+`); `$FD34` (`work space $FD34+`); `$FD53` (`work space $FD53+`) |

### `StartInterrupt` (`$D59C`)

**the interrupt handler while the start-up runs**

Also the end of PlayInterrupt. Installed alone by Start (FillVectorTable `$A614`), GameStop (`$AF0A`), SaveGame (`$C28D`), the end of MenuMusic (`$C520`) and OpenConstructionMenu (`$C85E`): no frame counting, no radar, so the world stands while it is in place.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,709 calls, 51,926 t-states own (0.02 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 36,025 calls, 504,390 t-states own (0.02 %) |
| Called from | `PlayInterrupt` |

### `ShowRadar` (`$D59E`)

**Show radar picture HL (16 lines x 16 bytes) at (22,6) in attribute C**

The interrupt alternates the two pictures `$D800` (terrain + the player's robots, attribute `$4D`) and `$D900` (terrain + the enemy's robots, `$4E`) every frame, so the terrain stays and each side's robots blink in their colour. The attributes are rows 22 and 23, columns 6-21.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,672 calls, 24,980,616 t-states own (9.28 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 34,645 calls, 235,689,935 t-states own (9.36 %) |
| Called from | `PlayInterrupt` |
| Calls | `NextScreenLine`, `FillAttr16` |
| Reads | `$D800`-`$D9FF` (`RadarOwn`, `RadarEnemy`, `SaveShots`, `SaveBuildings`) |
| Writes | `$50C6`-`$50F5` (screen); `$51C6`-`$51F5` (screen); `$52C6`-`$52F5` (screen); `$53C6`-`$53F5` (screen); `$54C6`-`$54F5` (screen); `$55C6`-`$55F5` (screen); 2 more ranges |

### `FillAttr16` (`$D5BD`)

**Write C into 16 bytes from HL**

In: HL, C. Out: HL past the 16 bytes, B = 0. The tail of ShowRadar (rows 22 and 23 of the radar).

| | |
| --- | --- |
| Runs (the first recording's game window) | 7,344 calls, 3,143,232 t-states own (1.17 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 69,290 calls, 29,656,120 t-states own (1.18 %) |
| Called from | `ShowRadar` |
| Writes | `$5AC6`-`$5AD5` (screen); `$5AE6`-`$5AF5` (screen) |

### `SoundEffect` (`$D5C4`)

**The interrupt's sound: A = `$FD53` (1-`$7F` a falling tone, `$C8-$FF` noise)**

Called by PlayInterrupt with A = SoundFx after its step, the flags of A set (never 0 here). A positive (2-`$7F`, a shot fired: SoundFx 1 counted on): C = 500 / (A+2) + 1 pulses, B = A the delay between them; each pulse's level is bit 4 of the next ROM byte from `$0000` (a rough noise), so the bursts get sparser and lower as A counts up each frame: a falling sweep over 126 frames, 3.2 ms at A = 2, about 2 ms from A = 40. A negative (`$C8-$FF`): 30 random speaker levels (Random): the crackle of a hit.

The shot code sets 1 when a shot is fired (`$B709`), `$FC` a miss (3 frames), `$FA` a hit (5 frames), `$C8` a robot destroyed (55 frames, the explosion). Seen in the deep recording at frames 18680-18712: 1, 2, ... `$16`, then `$FA-$FF`. Changes A, BC, DE, HL. The border stays black (bits 0-2 of the OUT are 0).

| | |
| --- | --- |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1,356 calls, 6,957,113 t-states own (0.28 %) |
| Called from | `PlayInterrupt` |
| Calls | `Random` |
| Ports out | `$00FE`, `$10FE` |

### `BuildRadar` (`$D5F8`)

**Build both radar pictures for the 128 columns from `$FD1C`**

Each map cell of the window is one pixel: set when its block type is `$0F` or more (the tall blocks). Copies the terrain picture to `$D900`, then puts the dot of every robot in play (+`$01` not 0, except the one under direct control, +`$0A` = 2) into its side's picture (ToggleRadarDot). Called by `$B029` when the ship moves the window (`$FD52`); once in the deep recording, at frame 35.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 142,587 t-states own (0.05 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 1 call, 142,587 t-states own (0.01 %) |
| Called from | `PutShipOnMap`, `RefreshRadar` |
| Reads | `$D800`-`$D8FF` (`RadarOwn`); `$DA01`-`$ED7F` (`Robots`, `EnemyRobots`, `Map`); `$EF00`-`$EF7F` (`Map`); `$F100`-`$F17F` (`Map`); `$F300`-`$F37F` (`Map`); `$F500`-`$F57F` (`Map`); 5 more ranges |
| Writes | `$D800`-`$D9FF` (`RadarOwn`, `RadarEnemy`, `SaveShots`, `SaveBuildings`); `$FFF2`-`$FFF3` (`work space $FFF2+`) |

### `ToggleRadarDot` (`$D65A`)

**XOR a 2x2 dot at map column HL, row C into radar picture B (0 player, 1 enemy)**

The dot covers (x, y), (x+1, y) and the line above. Nothing outside the window (RadarDotAddress returns past this routine). XOR: the same call removes the dot again, so the robot code toggles the old position before PlaceRobot toggles the new one.

| | |
| --- | --- |
| Runs (the first recording's game window) | 664 calls, 73,960 t-states own (0.03 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 22,759 calls, 1,798,165 t-states own (0.07 %) |
| Called from | `BlinkShipDot` (tail), `UpdateRobot`, `RobotStep`, `PlaceRobot` (tail) |
| Calls | `RadarDotAddress` |
| Reads | `$D801`-`$D8FF` (`RadarOwn`); `$D98F`-`$D9FF` (`SaveBuildings`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$D801`-`$D8FF` (`RadarOwn`); `$D98F`-`$D9FF` (`SaveBuildings`); `$FFF8`-`$FFF9` (`work space $FFF8+`) |

### `RadarDotAddress` (`$D67D`)

**HL = the radar byte of column HL, row C in picture B, A = the pixel mask**

Column x - `$FD1C` must be 0-126, else it pops the return address and returns from ToggleRadarDot. Address = `$D800` + `$100`*B + 16*y + (x-`$FD1C`)/8, mask = `$80` >> ((x-`$FD1C`) AND 7).

| | |
| --- | --- |
| Runs (the first recording's game window) | 664 calls, 113,904 t-states own (0.04 %) |
| Runs (the bot's game: robots built, orders given, factories captured, fights) | 22,759 calls, 3,053,599 t-states own (0.12 %) |
| Called from | `ToggleRadarDot` |
| Reads | `$FD1C`-`$FD1D` (`work space $FD1C+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$FFF0`-`$FFF7` (`work space $FFF0+`) |
