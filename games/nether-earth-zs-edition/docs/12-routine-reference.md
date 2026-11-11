# 12. Routine reference

Every code entry of every annotated part of both releases, part by part, in address order by module. The name, the
title and the description are the source's (the part's `.ann`); the rest is what that part's recordings saw:

- **Runs** count the calls of the entry itself; the time is its own t-states (callees excluded) and its share of the
  recording.
- **Called from / Calls** are the calls the recordings made; "(tail)" is a jump into another entry.
- **Reads / Writes** name the entries the ranges cover; past the part's bytes they are the work space (the robots
  `$DA00`, the map `$DD00`, the variables `$FD00`).
- **Ports** as L1 saw them: `$FE` the border and the beeper, `$7FFD` the pages, `$FFFD` / `$BFFD` the AY, `$1F` the
  Kempston stick, `$xxFE` keyboard half rows.
- An entry no recording reached says so; such code is read, not seen (the '99's tape and one-page pieces).

The recordings are local (`work/`), not in the repository; [the WALKTHROUGH](../WALKTHROUGH.md) and
`work/docs/zsB-NOTES.md` give the commands. The routines with an animation link it
(`docs/img/routines/<Label>.gif`, the '99 game only); where a routine's rules are explained with figures:

| Routines | Explained in |
| --- | --- |
| `WorldTurn`, `UpdateRobot`, `RobotStep`, `TurnOrStep`, `PlaceRobot`, `FireShot`, `MoveShot`, `BuildMap` | [7. Objects](07-objects.md) |
| `DrawPlayScreen`, `PrintInline`, `PrintChar`, `PrintBigChar`, `UpdateStatusPanel`, the start-up menu's viewer | [8. HUD and text](08-hud-and-text.md) |
| `SoundEffect`, `Beep`, `PlayInterrupt`, the PT3 and Sound Tracker players | [9. Sound](09-sound.md) |
| `GameTurn`, `DailyProduction`, `EnemyCommander`, `UpgradeEnemyRobots`, `FillEnemyResources`, `GameTurnEnd`, `CheckGameEnd` | [10. Gameplay logic](10-gameplay-logic.md) |

Written by `python3 tools/zsB_refdocs.py` (through `kit/refdocs.py`); edit the part's `.ann`, run
`kit/mkgame.py --part` on its part file (all: `tools/regen.sh`), then this script.

The parts:

- The '99 game (`src/game99`)
- The '98 game (`src/game98`)
- The '98 intro (`src/intro98`)
- The '99 stage 2: the intro (`src/stage2`)
- The '99 pictures block (`src/pictures99`)
- The '99 music block (`src/music99`)
- The '99 stage 3: System checking (`src/stage3`)
- The '99 start-up menu (`src/menu99`)
- The '99 patches block: `diskread` (`src/patches99`)
- The '99 patches block: `diskmap` (`src/patches99`)
- The '99 patches block: `paging128` (`src/patches99`)
- The '99 patches block: `menu128` (`src/patches99`)
- The '99 patches block: `taperead` (`src/patches99`)
- The '99 patches block: `tapemap` (`src/patches99`)
- The '99 patches block: `textload48` (`src/patches99`)
- The '99 patches block: `menu48` (`src/patches99`)

## The '99 game (`src/game99`)

Recordings: `work/zsB/deep` (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)), `work/zsB/deep-map0` (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)), `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/crit-play` (CRITICAL with every upgrade, several game days), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `font` | `$6780`-`$697F` | 0 of 1 |
| `sprites` | `$6980`-`$A569` | 0 of 178 |
| `difficulty` | `$A56A`-`$A5FF` | 2 of 5 |
| `start` | `$A600`-`$A71F` | 5 of 6 |
| `robotmenu` | `$A720`-`$AD61` | 26 of 48 |
| `gameturn` | `$AD62`-`$AF10` | 11 of 14 |
| `ship` | `$AF11`-`$B0C9` | 12 of 13 |
| `world` | `$B0CA`-`$B7F3` | 34 of 36 |
| `enemy` | `$B7F4`-`$BB08` | 4 of 4 |
| `bases` | `$BB09`-`$BDA8` | 17 of 17 |
| `level` | `$BDA9`-`$C0FF` | 0 of 18 |
| `mainmenu` | `$C100`-`$C4A6` | 23 of 44 |
| `music` | `$C4A7`-`$C848` | 32 of 50 |
| `construction` | `$C849`-`$CCBC` | 18 of 26 |
| `view` | `$CCBD`-`$D0B8` | 20 of 22 |
| `screen` | `$D0B9`-`$D37B` | 20 of 29 |
| `controls` | `$D37C`-`$D3E4` | 2 of 4 |
| `print` | `$D3E5`-`$D565` | 13 of 13 |
| `interrupts` | `$D566`-`$D6A7` | 8 of 8 |
| `tables` | `$D6A8`-`$D7D2` | 0 of 6 |

### difficulty

`src/game99/difficulty.asm`

#### `UpgradeEnemyRobots` (`$A5D6`)

**Every enemy robot's parts: (parts AND [`$A5E5`]) OR [`$A5E7`]; HARD and up, once a game day**

Called from DailyProduction (`$AE41`) when the start-up menu has written the call there (HARD, CRITICAL). For the 24 enemy slots (`$DB80`, 16 bytes each, alive or not): +`$07` = (+`$07` AND mask) OR parts. The image's mask `$78` keeps the four weapons (cannon, missiles, phasers, nuclear) and drops electronics and the chassis; the parts `$84` add electronics and anti-grav. CRITICAL makes the mask 0 and the parts `$FC`: every enemy robot becomes anti-grav with all four weapons and electronics. UPGRADING in the start-up menu sets the parts' bits 7-2 one by one and the mask to `$F8` (anti-grav chosen: the old chassis bits 0-1 dropped) or `$FF` (all kept).

Only +`$07` changes: the height +`$09` its build computed from the parts stays as it was. The view draws a robot from its part bits (DrawRobot), so the new parts show at once, and the weapons code reads the same bits. A free slot gets parts too, but a new robot's record is written whole by its build. B = 24; IY kept.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 13,895 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 7 calls, 13,895 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 3 calls, 5,955 t-states own (0.00 %) |
| Called from | `DailyProduction` |
| Reads | `$DB87`-`$DCF7` (`work space $DB87+`) |
| Writes | `$DB87`-`$DCF7` (`work space $DB87+`) |

#### `FillEnemyResources` (`$A5F2`)

**The enemy's resources = 99 each; HL = `$FD4A`**

Writes `$63` (99) into the 8 bytes `$FD4A-$FD51`: the enemy's seven resources (EnemyResources: general, electronics, nuclear, phasers, missiles, cannon, chassis) and Side, which the side's searches read only as zero or not (the enemy's 1 becomes 99, same meaning). Returns HL = `$FD4A`, so that a CALL to it can replace LD HL,`$FD4A`: called by NewGameSetup (`$A688`) for every level and, MEDIUM and up, by the enemy's build (`$B87E`), so the enemy never runs short.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 16 calls, 4,224 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 26 calls, 6,864 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 1,056 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 14 calls, 3,696 t-states own (0.00 %) |
| Called from | `StartGame`, `EnemyCommander` |
| Writes | `$FD4A`-`$FD51` (`work space $FD4A+`) |

### start

`src/game99/start.asm`

#### `Start` (`$A600`)

**the entry: the start-up menu, then StartGame**

CALL `$C100`: the start-up menu, which stage 3 has placed there (the patches block's menu128 or menu48 piece: on 128 K it copies the menu from page 1 to `$D800` in page 0 and runs it there). The piece keeps SP for the menu, so the menu's START returns through this CALL to StartGame at `$A603`, after the level's routine (`$DA8E`) has written the level's code and operands into this block.

The block's own bytes of the menu at `$C100` are zeros (mainmenu.asm); without stage 3 the CALL would run them as NOPs into whatever follows.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 34 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 1 call, 17 t-states own (0.00 %) |
| Called from | `LoadMapRoom` (tail) |
| Calls | `MenuPieceRoom` |

#### `StartGame` (`$A603`)

**After START: the IM 2 table, Handler = StartInterrupt, the random seed, then a new game**

Reached when the start-up menu returns (START). DI, SP = 0; the IM 2 table `$FE00-$FF00` (257 x `$FD`), JP at `$FDFD`, Handler = StartInterrupt, I = `$FE`, IM 2, EI; the random seed `$FD00-$FD03` = `$39`,`$30`,`$39`,`$30`. Falls into NewGameSetup: every game is a new one.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | run into, not called, 33,644 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | run into, not called, 33,644 t-states own (0.00 %) |
| Calls | `FillEnemyResources`, `PlayLoop`, `BuildMap`, `DrawViewBackground`, `DrawPlayScreen` |
| Reads | `$D7D3`-`$D7FE` (`work space $D7D3+`); `$DA00`-`$DCFE` (`work space $DA00+`); `$FD04`-`$FDFB` (`work space $FD04+`); `$FF01`-`$FFC8` (`work space $FF01+`) |
| Writes | `$D7D3`-`$D7FF` (`work space $D7D3+`); `$DA00`-`$DCFF` (`work space $DA00+`); `$FD00`-`$FFC9` (`work space $FD00+`) |

#### `NewGameSetup` (`$A62D`)

**New game: clear the robots, variables, buildings and shots, place the ship, the resources, build the map**

Entered from StartGame. The two NOPs at `$A62D` take the place of NE's skip for a loaded game: here every game is a new one.

Zeroes the robot records `$DA00-$DCFF` (48 x 16), the variables `$FD04-$FDFC` (everything past the random seed, below the JP of the IM 2 vector), the building table `$FF01-$FFC9` and the five shot records `$D7D3-$D7FF` (5 x 9). Then: MapView = `$DD00`, ViewX = 0, ShipX = `$11`, ShipY = 14, Altitude = 0, ClimbTurns = 3 (the ship rises to 6 on its own at the start).

The resources: our general resource = 99, the operand at `$A684` (LOAD MAP writes a map's own value there, the NELEV file's last byte; every one of the 12 maps keeps 99), the others 0. FillEnemyResources then gives the enemy 99 of all seven resources (it also writes `$63` into Side, which BuildMap does not read). BuildMap then clears the map `$DD00-$FCFF` and the radar buffer `$D800` and builds the landscape, the warbases and the factories from the level's lists (the built-in one or a loaded map). Falls into EnterPlay.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EnterPlay` (`$A68E`)

**Draw the play screen and switch to the play interrupt**

DrawViewBackground and DrawPlayScreen build the play screen (the view, its frame, the radar, the status panel; then Handler = PlayInterrupt, which counts the frames in `$FD34` and draws the radar each frame. Falls into PlayLoop. Entered from NewGameSetup, from a loaded game, and again after a game save (key 5, SaveGame) at `$A71D`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PlayLoop` (`$A69A`)

**The play loop: one game turn a pass (at least 10 frames)**

One pass: WaitKey (the controls into Input; key 1 pauses here), MoveShip, WorldTurn (every robot record and the five shots), DrawView (draw the view), GameTurn (the random step, the clock, captures, the end of the game; waits until 10 frames have passed since the previous turn).5 frames a turn, 5 turns a second.

Then it looks under the ship (ShipCell: HL = the ship's map cell). Map bit 6 means something stands there. A robot of ours (FindRobot, B = 48 - slot >= 25) with the ship resting exactly on its top (Altitude = +`$09` + +`$0D`) opens RobotMenu. Otherwise a building of type 0 (the pad of our warbase) with Altitude = 15 (the pad's top, the ship cannot sink below it) opens ConstructionMenu, but only when the warbase's door cell 4 rows below the pad and the three cells below the door (row +5, columns -1, 0, +1) are free of bit 6: the new robot is placed on the door (ShipY + 4, `$CB6A`). After the menu the new record gets +`$05` = 4, +`$06` = 5, +`$0B` = 0 (stop), +`$0C` = 100 (strength), +`$0F` = 1 (moves at once; CountRobots recounts the robots and UpdateStatusPanel reprints the panel.

The writes at `$A6F3` then hit that enemy robot: its strength goes back to 100 and its order to 0, every turn the ship sits on the pad.

Last, the abort key: Input bit 6 (key I in the default KeyTable) abandons the game (JP Start: the start-up menu again). NE's save key (bit 5, key 5: SaveGame, then EnterPlay) is gone: `$A715` jumps straight back to the loop's head and the eight bytes after it, `$A718-$A71F`, are NOPs that never run.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | run into, not called, 569,581 t-states own (0.03 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | run into, not called, 421,116 t-states own (0.02 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 6,414 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1 call, 153,281 t-states own (0.02 %) |
| Called from | `StartGame` |
| Calls | `RobotMenu`, `GameTurn`, `MoveShip`, `WorldTurn`, `CountRobots`, `ConstructionMenu`, `ShipCell`, `DrawView`, `FindRobot`, `FindBuilding`, `UpdateStatusPanel`, `WaitKey` |
| Reads | `$DA09`-`$DA9D` (`work space $DA09+`); `$E512`-`$E917` (`work space $E512+`); `$EB12`-`$EB18` (`work space $EB12+`); `$ED12`-`$ED18` (`work space $ED12+`); `$EF11`-`$F318` (`work space $EF11+`); `$F512`-`$F518` (`work space $F512+`); 4 more ranges |
| Writes | `$DA05`-`$DA9F` (`work space $DA05+`) |

### robotmenu

`src/game99/robotmenu.asm`

#### `RobotMenu` (`$A720`)

**landing on a robot of ours: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT; the order to +`$0B`**

IX = IY (the record), +`$0A` = 1 (the robot stands: UpdateRobot returns at once for +`$0A` = 1), MenuCursor = 4 (LEAVE ROBOT first), PanelBusy = 1. Falls into RobotMenuShow. Called by PlayLoop when the ship rests exactly on the top of a robot of ours.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 616 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 1,144 t-states own (0.00 %) |
| Called from | `PlayLoop` |
| Calls | `RobotMenuShow` |
| Writes | `$DA0A`-`$DA9A` (`work space $DA0A+`); `$FD1F` (`work space $FD1F+`); `$FD39` (`work space $FD39+`) |

#### `RobotMenuShow` (`$A732`)

**Robot menu: draw the four items, the current order and the strength, then choose**

Clears the side panel (ClearPanel) and prints DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT at (4,23), every 3 rows, attribute `$4D`, and the title -ORDERS- at (17,23). Falls into ShowOrder, ShowOrderMiles and RobotMenuChoose. Every submenu comes back here when it is done (`$A93E`, `$AA09`, `$AACC`, `$ABFD`, the combat menu at `$AC8B`).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 14 calls, 476 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 26 calls, 884 t-states own (0.00 %) |
| Called from | `RobotMenu`, `SetOrder` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

#### `ShowOrder` (`$A795`)

**Robot menu: print the name of the robot's order**

Copies the 27-byte name of order +`$0B` from OrderNames (`$A848` + 27 x order) into OrderLine, the string printed right after the CALL at `$A7AA`: three lines at (18,23), attribute `$45`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 14 calls, 9,758 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 26 calls, 18,818 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintInline` |
| Reads | `$A848`-`$A862` (`OrderNames`); `$A899`-`$A8B3` (`OrderName3`); `$A8EA`-`$A93A` (`OrderName6`, `OrderName7`, `OrderName8`); `$DA0B`-`$DA9B` (`work space $DA0B+`) |
| Writes | `$A7B2`-`$A7CC` (`OrderLine`) |

#### `ShowOrderMiles` (`$A7CD`)

**Robot menu: for ADVANCE and RETREAT, the miles under the order's name**

Orders 1 and 2 only: prints at (19,25) the distance +`$0E` / 2 with two digits (PrintNumber2), into the blank middle line of the order's name ("ADVANCE", "nn", "MILES"). Other orders jump straight to RobotMenuChoose. IX = the robot record.

The printing tail after the inline position is ShowMilesCode (`$A7DC`).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 14 calls, 3,204 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 26 calls, 4,981 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `RobotMenuChoose`, `ShowStrength`, `OrdersMenu` (tail), `ListMenu`, `Beep`, `ShowStatusPanel`, `ClearPanel` |
| Reads | `$DA0B`-`$DA9B` (`work space $DA0B+`); `$FD1F` (`work space $FD1F+`) |
| Writes | `$DA06`-`$DA9A` (`work space $DA06+`); `$FD1F` (`work space $FD1F+`); `$FD30`-`$FD39` (`work space $FD30+`) |

#### `ShowMilesCode` (`$A7DC`)

**LD A,(IX+`$0E`); SRL A; CALL `$D3E5`**

The tail of ShowOrderMiles after its inline position: A = +`$0E` / 2 (the miles, stored doubled), printed with two digits and a leading space by PrintNumber2. Falls into RobotMenuChoose.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RobotMenuChoose` (`$A7E4`)

**Robot menu: choose an item and run it; LEAVE ROBOT closes the menu**

Prints the strength, runs ListMenu on the four items (HL = `$5837`, the attribute of row 1 column 23, E = 5, A = MenuCursor) and keeps the choice in MenuCursor, so the menu reopens on it. 1 DIRECT CONTROL (`$A93B`), 2 GIVE ORDERS (OrdersMenu), 3 COMBAT MODE (CombatMenu `$AC00`), 4 LEAVE ROBOT: a beep, +`$06` = 0, +`$0A` = 0 (the robot carries on with its order), the auto-climb `$FD30` = 5 turns so the ship rises off the robot and the menu does not reopen, then CloseRobotMenu.

CloseRobotMenu (`$A812`) clears the panel, sets `$FD39` = 0 and redraws the status panel (ShowStatusPanel; ListMenu also jumps there when the robot is destroyed while its menu is open (seen: freeing +`$01` under the open menu closed it).

| | |
| --- | --- |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | run into, not called, 793 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `ListMenu` (tail) |
| Calls | `ShowStatusPanel`, `ClearPanel` |
| Writes | `$FD39` (`work space $FD39+`) |

#### `ShowStrength` (`$A81D`)

**Robot menus: print STRENGTH and the robot's strength in %**

Prints "STRENGTH" at (22,23) and the value of +`$0C` at (23,25), three digits with leading spaces and "%" (a robot is born with 100). A negative +`$0C` (a dying robot, UpdateRobot counts it up) shows as 0 % (poked `$80`: "0%"). Called once a turn by every robot menu loop. IX = the robot record.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 110 calls, 1,870 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 207 calls, 3,519 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose`, `ListMenu` |
| Calls | `PrintInline` |

#### `ShowStrengthValue` (`$A833`)

**Print the strength +`$0C` as "nnn%"**

The tail of ShowStrength after its inline string: a negative strength is shown as 0; PrintNumber3 prints HL with three digits, E = `$20` makes the leading zeros spaces; the "%" goes out through PrintCharKeep.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 110 calls, 9,350 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 207 calls, 17,619 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber3`, `PrintCharKeep` (tail) |
| Reads | `$DA0C`-`$DA9C` (`work space $DA0C+`) |

#### `DirectControlItem` (`$A93B`)

**Robot menu item 1: direct control, then the robot menu again**

Calls DirectControl (drive the robot until fire, or until it is destroyed) and redraws the robot menu with RobotMenuShow. MenuCursor still holds 1, so the menu reopens on DIRECT CONTROL. A robot destroyed while driven: DirectControl returns, RobotMenuShow redraws, and ListMenu then sees +`$01` = 0 and closes the menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DirectControl` (`$A941`)

**Drive the robot with the controls until fire**

+`$0A` = 2 and +`$05` = 0, then a loop of game turns without the ship's own move: WorldTurn moves the robot from Input (`$B184` -> `$B450`) and calls MoveShip from there (`$B4A8`), so the ship travels on the robot; DrawView draws the view, MenuRadarTick blinks the ship on the radar, GameTurn, ShowStrength. Fire gives the robot back (+`$0A` = 1, a beep) and returns. Returns at once (Z) when the robot is destroyed (+`$01` = 0).

Used by the robot menu (item 1) and by the combat menu (MOVE ROBOT, `$AC93`). fire set +`$0A` back to 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `OrdersMenu` (`$A971`)

**GIVE ORDERS: the five orders**

Clears the panel and prints SELECT ORDERS at (4,24) and the five items from (7,23): STOP AND DEFEND, ADVANCE ?? MILES, RETREAT ?? MILES, SEARCH & DESTROY, SEARCH & CAPTURE. Falls into OrdersMenuChoose.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 238 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 442 t-states own (0.00 %) |
| Called from | `ShowOrderMiles` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

#### `OrdersMenuChoose` (`$A9EC`)

**GIVE ORDERS: choose; stop at once, advance / retreat ask the miles, search asks the target**

ListMenu at HL = `$5897` (row 4: item 1 at row 7), E = 6, A = 1. Item 1 sets order 0 (stop and defend) and returns to the robot menu. Items 2 and 3 set order 1 (advance) or 2 (retreat) and go on to the distance menu (DistanceMenu, `$AA19` on). Items 4 and 5 go to TargetMenu with the flags of CP 3 (Z = SEARCH & DESTROY).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 903 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 1,677 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `TargetMenu` (tail), `ListMenu`, `WaitRelease` |

#### `AdvanceJump` (`$AA2D`)

**JR `$AA40`, past the RETREAT title**

The last instruction of the ADVANCE branch of OrdersMenuChoose: after the "ADVANCE " title it jumps over RetreatTitle into DistanceMenu, the part both orders share.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RetreatTitle` (`$AA2F`)

**GIVE ORDERS, RETREAT: the title of the distance menu**

The RETREAT branch of OrdersMenuChoose: prints "RETREAT " at (5,23), attribute `$4F`, then falls into DistanceMenu. The order (+`$0B` = 2) is already stored.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DistanceMenu` (`$AA40`)

**CALL PrintInline, the distance menu's texts**

The distance menu of ADVANCE and RETREAT, shared by both: its texts "?? MILES" (the next line under the title), SELECT DISTANCE at (9,23), "0 MILES" at (13,24; then falls into DistanceSelect.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DistanceSelect` (`$AA6E`)

**choose the miles, 0-50 by 5**

D = the miles, from 0. Each pass of DistanceLoop is one game turn (ShowStrength, WorldTurn, DrawView, MenuRadarTick, GameTurn; a destroyed robot (+`$01` = 0) closes the whole menu (JP CloseRobotMenu). Then WaitKey: fire goes to DistanceFire; up adds 5, down takes 5 (up wins when both are held; a value out of 0-50 (CP `$33`, a negative one wraps above it) is refused. A change is printed at (13,23), attribute `$46`, by DistanceShow with the click `$14`. No release wait: a held key steps once a game turn.

DistanceFire: +`$0E` = miles x 2; 0 miles turns the order back into 0 (stop and defend; the beep `$78`, WaitRelease, back to the robot menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DistanceShow` (`$AAAD`)

**the miles in D printed (PrintNumber2), a click, back to the distance loop**

The tail of DistanceSelect after the inline position (13,23): prints D, the miles, with two digits (PrintNumber2), clicks (Beep `$14`) and goes back to DistanceLoop for the next game turn. DistanceFire (`$AAB8`) follows: the end of the distance menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TargetMenu` (`$AACF`)

**SEARCH & DESTROY or SEARCH & CAPTURE: the three targets**

Z (the destroy item): clears the panel and prints SEARCH & DESTROY, SELECT TARGET and ENEMY ROBOTS / ENEMY FACTORYS / ENEMY WARBASES; NZ goes to CaptureMenu.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 172 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 300 t-states own (0.00 %) |
| Called from | `OrdersMenuChoose` (tail) |
| Calls | `CaptureMenu` (tail), `ClearPanel`, `PrintInline` |

#### `DestroyMenuChoose` (`$AB3D`)

**SEARCH & DESTROY: choose the target, orders 3-5**

ListMenu at HL = `$5937` (item 1 at row 12), E = 4, A = 1; the item + 2 is the order (3 robots, 4 factories, 5 warbases) for SetOrder.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 3 calls, 231 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 5 calls, 385 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `SetOrder` (tail), `ListMenu` |

#### `CaptureMenu` (`$AB4E`)

**SEARCH & CAPTURE: the three targets**

Prints SEARCH & CAPTURE, SELECT TARGET and NEUTRAL FACTORYS / ENEMY FACTORYS / ENEMY WARBASES.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 4 calls, 136 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 8 calls, 272 t-states own (0.00 %) |
| Called from | `TargetMenu` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

#### `CaptureMenuChoose` (`$ABB9`)

**SEARCH & CAPTURE: choose the target, orders 6-8**

The same list as DestroyMenuChoose; the item + 5 is the order (6 neutral factories, 7 enemy factories, 8 enemy warbases).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 4 calls, 260 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 8 calls, 520 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `SetOrder`, `ListMenu` |

#### `SetOrder` (`$ABC8`)

**Store a search order, look for its first target, or fall back to stop**

A = the order (3-8) into +`$0B`. Orders 4 and 5 (destroy factories, warbases) need the nuclear bomb (+`$07` bit 6; without it the order becomes 0. Otherwise `$FD51` = 0 (our side), +`$0E` = `$FF` and FindTargetBuilding looks for a target of the order from the robot's X (+`$02`/+`$03`): D, the index it found, goes to +`$0E`; no target (Z) makes the order 0. A beep, WaitRelease, back to the robot menu.

CombatMenu (`$AC00`) follows in the same block: the robot menu's item 3.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 1,708 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 3,128 t-states own (0.00 %) |
| Called from | `DestroyMenuChoose` (tail), `CaptureMenuChoose` |
| Calls | `RobotMenuShow` (tail), `WaitRelease`, `FindTargetBuilding`, `Beep` |
| Reads | `$DA02`-`$DA93` (`work space $DA02+`) |
| Writes | `$DA0B`-`$DA9E` (`work space $DA0B+`); `$FD51` (`work space $FD51+`) |

#### `CombatMenuCode` (`$AC7C`)

**the combat menu**

The code after CombatMenuText: the strength, then ListMenu on the six items (HL = `$5837`, E = 7), STOP COMBAT highlighted first. Each choice comes back to CombatMenuLoop with A = the item, so the menu reopens on it.

6 STOP COMBAT: back to the robot menu. 5 MOVE ROBOT: DirectControl, then the menu again. 1-4 need the weapon: +`$07` rotated left item + 1 times leaves in carry bit 6 (nuclear), 5 (phasers), 4 (missiles) or 3 (cannon; without it the low buzz (`$FA`) and the menu again.

1 NUCLEAR BOMB: IY = IX, NuclearBlast, then the menu closes (JP CloseRobotMenu): the bomb destroys the robot carrying it. 2-4: shot record 0 at `$D7D3` (Shots; if it is free (+`$01` = 0), A = 5 - item (3 phasers, 2 missiles, 1 cannon) and FireShot launches it from the robot along its facing (+`$08`), then DrawView and GameTurn; a shot of record 0 still flying buzzes.

FIRE MISSILES without missiles changed nothing.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ListMenu` (`$ACD7`)

**a list menu: HL the attribute of item 0 (an item every 3 rows), E the items + 1, A the first highlighted; down / up move, fire returns A**

Each pass is one game turn (WorldTurn, DrawView, MenuRadarTick, GameTurn, ShowStrength): the game goes on while a menu waits. A destroyed robot (+`$01` = 0) drops ListMenu's return address and closes the robot menu (CloseRobotMenu). Up / down move by one item (items 1 to E - 1) with a click `$14`; fire paints the item `$4F`, beeps `$64` and returns A. Attributes: `$4D` normal, `$4E` highlighted, `$4F` chosen. Needs IX = a robot record.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 28 calls, 35,784 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 52 calls, 67,149 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose` |
| Calls | `RobotMenuChoose` (tail), `ShowStrength`, `PaintMenuItem`, `WaitRelease`, `GameTurn`, `MenuRadarTick`, `WorldTurn`, `Beep`, `DrawView`, `WaitKey` |
| Reads | `$DA01`-`$DA91` (`work space $DA01+`); `$FD0C` (`work space $FD0C+`) |

#### `PaintMenuItem` (`$AD3C`)

**Colour list item A: 2 rows of 8 attributes with C**

HL = the attribute of item 0; item A starts `$60` bytes (3 rows) further per item. Fills 8 attributes, moves down a row (`$18` more) and fills 8 more with C (`$4D` normal, `$4E` highlighted, `$4F` chosen). A must be 1 or more. Keeps DE and HL.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 166 calls, 32,993 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 309 calls, 61,377 t-states own (0.00 %) |
| Called from | `ListMenu` |
| Calls | `FillAttributes`, `AddAToHL` |

#### `WaitRelease` (`$AD57`)

**wait until no control is held**

Calls WaitKey until Input is 0: every control up. Used by every menu before it reads a new press, so the fire that chose an item does not choose again. Keeps BC and HL; A = 0 on return. Uses WaitKey, so key 1 still pauses.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 42 calls, 3,360 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 78 calls, 6,240 t-states own (0.00 %) |
| Called from | `OrdersMenuChoose`, `SetOrder`, `ListMenu` |
| Calls | `WaitKey` |

### gameturn

`src/game99/gameturn.asm`

#### `GameTurn` (`$AD62`)

**One game turn: the random step, the clock, the daily production, the clock print**

Random steps the random generator `$FD00-$FD03`. Clock (`$FD35` minutes, `$FD36` hours, `$FD37-$FD38` days) gains 5 minutes a turn: 60 minutes make an hour, 24 hours a day, and a new day runs DailyProduction. Then the clock print: days at (0,27), five digits with leading spaces; "HH.MM" on the next line. Goes on in GameTurnEnd.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,224 calls, 196,211 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,094 calls, 184,687 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 38 calls, 3,336 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 80,959 t-states own (0.01 %) |
| Called from | `PlayLoop`, `ListMenu` |
| Calls | `DailyProduction`, `Random`, `PrintInline` |
| Reads | `$FD35`-`$FD38` (`work space $FD35+`) |
| Writes | `$FD35`-`$FD38` (`work space $FD35+`) |

#### `GameTurnEnd` (`$AD90`)

**Game turn, second half: the clock print, the game end, captures, the frame pacing**

The second half of GameTurn, reached after the PrintInline of ClockPos (setting the print position (0,27) and attribute `$57`). Prints the days (PrintNumber5, five digits with leading spaces) and, a line down (PrintNewline), the hours "." the minutes (PrintNumber2Zero, two digits with zeros). Then CheckGameEnd: a side with no warbase ends the game here.

Captures: the capture points at `$FD70` (5 bytes each: X 2 bytes, Y, owner and type, count) are checked each turn, as many as the operand at `$ADB4` says: 2 in the image (the built-in level's two warbases), the NELEV file's byte `$1F3` after LOAD MAP (28 in eleven maps, 27 in NELEV_08). While map bit 6 is set on a point's door cell (an anchor stands there) its count +4 goes up; at 144 (`$90`) FindRobot takes the robot there and its side (+`$0A` bit 7) captures the building: GiveWarbase for index 0-3, GiveFactory (index - 4) for 4-27. A door anchor that is no robot (probably a flying shot) captures nothing; the count still starts again. An empty door resets the count. Any robot captures, whatever its order. After a capture CountBases recounts the buildings and UpdateStatusPanel reprints the status.

The index is 28 - B (`$ADF1`), B the loop counter that starts at the count. It is the record's own index only when the count is 28: with a count N < 28 the record k is handed over as index k + 28 - N, another record. In the built-in level (N = 2) a capture at the enemy's warbase (record 1) calls GiveFactory 23, which marks the cleared record 27 and writes its flags around map cell (0, 0) minus two rows, below the map (in the radar buffers at `$D800-$D9FF`); the enemy keeps its warbase. In NELEV_08 (N = 27) each capture moves the owner of the next record. Also the split at index 4 is NE's: in the maps with more than four warbases (NELEV_05, 06, 07, 10, 11) a warbase of index 4 or more is handed over by GiveFactory, which sets its owner (CountBases counts it right, by its type bits) but moves factory flags (row y-2, x-2 / x+2) instead of building a pad: the player can never build robots at such a warbase.

Last, the pacing (TurnPace): waits until PlayInterrupt has counted 10 frames in TurnFrames (`$FD34`) since the last turn, then clears it. A turn is at least 10 frames: an hour 120, a game day 2880 (about 58 s). Keeps IY (pushed around the loop; A, BC, DE, HL lost.

[Animation: `GameTurnEnd` at work](img/routines/GameTurnEnd.gif)

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,223 calls, 6,996,737 t-states own (0.32 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,094 calls, 67,475,310 t-states own (3.86 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 38 calls, 4,838,763 t-states own (1.73 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 40,031,592 t-states own (5.92 %) |
| Called from | `PrintInline` |
| Calls | `CheckGameEnd`, `CountBases`, `GiveFactory`, `MapCell`, `FindRobot`, `UpdateStatusPanel`, `PrintNumber2Zero`, `PrintNumber5`, `PrintCharKeep`, `PrintNewline` |
| Reads | `$DA0A` (`work space $DA0A+`); `$DA6A` (`work space $DA6A+`); `$DBAA` (`work space $DBAA+`); `$DC0A` (`work space $DC0A+`); `$DC2A`-`$DC4A` (`work space $DC2A+`); `$DCAA` (`work space $DCAA+`); 11 more ranges |
| Writes | `$FD34` (`work space $FD34+`); `$FD74`-`$FDFB` (`work space $FD74+`) |

#### `UnusedTapeCode` (`$AE29`)

**Unreferenced code: keys 6 and 7 together jump into the tape ROM**

15 bytes of code nothing calls or jumps to: LD A,`$EF`; IN A,(`$FE`; AND `$18`; RET NZ (unless 6 and 7 are both held; LD HL,`$A600`; PUSH HL; DI; JP `$04B0`. `$04B0` is inside an instruction of the 48K ROM's SAVE code; with Start as the return address it looks like a debugging leftover (a memory dump to tape). Never runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DailyProduction` (`$AE38`)

**A new day: each side's buildings add to its resources**

Our side from `$FD3A` into Resources, the enemy from `$FD42` into `$FD4A` (ProduceSide), then the panel reprint (UpdateStatusPanel).

[Animation: `DailyProduction` at work](img/routines/DailyProduction.gif)

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 735 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 7 calls, 735 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 3 calls, 315 t-states own (0.00 %) |
| Called from | `GameTurn` |
| Calls | `UpgradeEnemyRobots`, `ProduceSide`, `UpdateStatusPanel` |

#### `ProduceSide` (`$AE4E`)

**One side's production: 5 general a warbase, 2 a factory of each kind**

DE = the side's building counts (warbases, then the factories of electronics, nuclear, phasers, missiles, cannon, chassis), HL = its 7 resources (general first, then the same order). General += 5 x warbases; each other resource += 2 x the factories of its kind; every resource stops at 99.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 2,590 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 7 calls, 2,590 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 3 calls, 1,110 t-states own (0.00 %) |
| Called from | `DailyProduction` |
| Calls | `AddCapped` |
| Reads | `$FD3A`-`$FD40` (`work space $FD3A+`) |

#### `AddCapped` (`$AE62`)

**(HL) += A, at most 99**

(HL) += A, at most 99: the resource store of ProduceSide. HL is kept, so ProduceSide walks the 7 resources with INC HL. A = the new value. Used only by ProduceSide.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 49 calls, 2,107 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 49 calls, 2,107 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 21 calls, 909 t-states own (0.00 %) |
| Called from | `ProduceSide` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`) |
| Writes | `$FD22`-`$FD28` (`work space $FD22+`) |

#### `CheckGameEnd` (`$AE6B`)

**The end of the game: the enemy has no warbase (won) or we have none (lost)**

`$FD42` (the enemy's warbases) = 0: GameWon. Else `$FD3A` (ours) = 0: GameStop, "YOU HAVE NO BASES LEFT / BETTER LUCK NEXT TIME!" at (22,0), then the common end at `$AEEA`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,224 calls, 115,648 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,094 calls, 108,926 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 38 calls, 1,976 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 47,774 t-states own (0.01 %) |
| Called from | `GameTurnEnd` |
| Reads | `$FD3A`-`$FD42` (`work space $FD3A+`) |

#### `LostJump` (`$AEAF`)

**JR `$AEEA`, the common end**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GameWon` (`$AEB1`)

**The enemy has no warbase left: "INSIGNIANS DESTROYED / YOU HAVE WON !"**

Stops play (GameStop), prints the message at (22,0) and falls into the common end at `$AEEA`: a low buzz, 100 frames, WaitRelease, then the first control (Input not 0, the chosen keys or stick only) goes back to Start and the title menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GameOverWait` (`$AEEA`)

**the end of a won or lost game**

LD A,`$FA`; CALL `$CCAC` (the buzz; LD B,100; HALT; DJNZ (2 s; CALL WaitRelease; CALL WaitKey until a control is held; JP Start.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GameStop` (`$AF00`)

**Stop play: give the panel back to the status and switch to the idle interrupt**

`$FD39` = 0, clears the panel, prints the status panel (ShowStatusPanel), Handler = StartInterrupt (no frame count, no radar). Used by both ends of the game.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### ship

`src/game99/ship.asm`

#### `MoveShip` (`$AF11`)

**the ship's move from Input: X by right / left, Y by down / up, each refused by CheckShipMove**

Also the auto-climb (ClimbTurns), the altitude (fire +2 up to `$30`, else -1 down to what stands under the ship), the view follow (ViewX moves when the ship is at view column 13 or 22), the radar window (ScrollRadar) and the ship's mark: map bit 7 cleared on the old cell (`$B01D`) and set on the new one (`$B024`), the radar blip XORed. Called by PlayLoop, and by UpdateRobot (`$B4A8`) while a robot is under direct control.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,142 calls, 823,305 t-states own (0.04 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,939 calls, 722,728 t-states own (0.04 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 13,941 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 267,678 t-states own (0.04 %) |
| Called from | `PlayLoop` |
| Calls | `ScrollRadar`, `LiftShipFromMap`, `PutShipOnMap`, `CheckShipMove` |
| Reads | `$FD0A`-`$FD1E` (`work space $FD0A+`); `$FD30` (`work space $FD30+`) |
| Writes | `$FD06`-`$FD1E` (`work space $FD06+`); `$FD30` (`work space $FD30+`) |

#### `ScrollRadar` (`$AFE6`)

**Move the radar window by 64 columns when the ship nears its edge**

The radar shows 128 map columns: from column `$FD1B` x 8 (`$FD1C` = the same as a column, 16 bits). With A = ShipX / 8 - `$FD1B`: below 2 (the ship within 16 columns of the left edge) the window moves 8 units left, unless it is at 0; 14 and more moves it 8 units right, at most to `$30` (columns 384-511). A move sets `$FD52` = 1: the radar bitmap is rebuilt from the map by BuildRadar at the ship's next mark (`$B029`). Called by MoveShip every turn (3332 times).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,142 calls, 229,213 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,939 calls, 207,492 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 4,173 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 98,226 t-states own (0.01 %) |
| Called from | `MoveShip` |
| Reads | `$FD0E`-`$FD1B` (`work space $FD0E+`) |

#### `LiftShipFromMap` (`$B01D`)

**clear the ship's occupant bit in its map cell, toggle its radar dot**

Called by MoveShip first thing each game turn, before the ship moves: the cell under the ship (ShipCell: `$DD00` + `$200` * ShipY + ShipX) loses bit 7, the occupant bit robots test (FreeDirections) when the ship hangs lower than their top, and the ship's dot on the radar is toggled off when it is on (BlinkShipDot). PutShipOnMap undoes both after the move.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,142 calls, 94,286 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,939 calls, 85,316 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 1,716 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 40,392 t-states own (0.01 %) |
| Called from | `MoveShip` |
| Calls | `BlinkShipDot` (tail), `ShipCell` |
| Reads | `$E512`-`$E917` (`work space $E512+`); `$EB12`-`$EB18` (`work space $EB12+`); `$ED12`-`$ED18` (`work space $ED12+`); `$EF12`-`$F318` (`work space $EF12+`); `$F512`-`$F518` (`work space $F512+`); `$F712`-`$F916` (`work space $F712+`) |
| Writes | `$E512`-`$E917` (`work space $E512+`); `$EB12`-`$EB18` (`work space $EB12+`); `$ED12`-`$ED18` (`work space $ED12+`); `$EF12`-`$F318` (`work space $EF12+`); `$F512`-`$F518` (`work space $F512+`); `$F712`-`$F916` (`work space $F712+`) |

#### `PutShipOnMap` (`$B024`)

**set the ship's occupant bit in its new map cell, rebuild the radar if the window moved, toggle the ship's dot**

Called at the end of MoveShip (and by BuildMap). Sets bit 7 of the ship's cell, then goes on into RefreshRadar.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,142 calls, 68,544 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,939 calls, 62,048 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 40 calls, 2,469 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 919 calls, 56,088 t-states own (0.01 %) |
| Called from | `MoveShip`, `BuildMap` |
| Calls | `RefreshRadar`, `BlinkShipDot`, `ShipCell`, `BuildRadar` |
| Reads | `$E512`-`$E917` (`work space $E512+`); `$EB12`-`$EB18` (`work space $EB12+`); `$ED12`-`$ED18` (`work space $ED12+`); `$EF12`-`$F118` (`work space $EF12+`); `$F312`-`$F318` (`work space $F312+`); `$F512`-`$F717` (`work space $F512+`); 2 more ranges |
| Writes | `$E512`-`$E917` (`work space $E512+`); `$EB12`-`$EB18` (`work space $EB12+`); `$ED12`-`$ED18` (`work space $ED12+`); `$EF12`-`$F118` (`work space $EF12+`); `$F312`-`$F318` (`work space $F312+`); `$F512`-`$F717` (`work space $F512+`); 2 more ranges |

#### `RefreshRadar` (`$B029`)

**rebuild the radar when RadarDirty is set, then blink the ship's dot**

RadarDirty (`$FD52`) is set when the window moved (`$B017`) and by other code that changes the map (the start, a loaded game). BuildRadar then redraws both radar layers `$D800` / `$D900` from the map (a pixel for every cell of type `$0F` or more, the high ground) and plots every live robot's dot; the flag is cleared. Falls into BlinkShipDot. Also reached from MenuRadarTick.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,224 calls, 64,534 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,094 calls, 60,745 t-states own (0.00 %) |
| Called from | `PutShipOnMap`, `MenuRadarTick` (tail) |
| Calls | `BlinkShipDot` (tail) |
| Reads | `$FD52` (`work space $FD52+`) |

#### `BlinkShipDot` (`$B036`)

**on odd ticks toggle the ship's 2x2 dot on the radar's player layer**

RadarBlink (`$FD1E`) counts the game turns (MoveShip increments it between LiftShipFromMap and PutShipOnMap, MenuRadarTick in the menus). When it is odd, ToggleRadarDot XORs a 2x2 dot at (ShipX, ShipY) into the layer B = 0 (`$D800`, shown with attribute `$4D` by PlayInterrupt in alternate frames). Off-window positions draw nothing (RadarDotAddress). The pairs of toggles around each move leave the dot on every other turn: the ship's dot blinks.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 4,448 calls, 235,801 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 4,188 calls, 222,021 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 79 calls, 4,165 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,837 calls, 97,339 t-states own (0.01 %) |
| Called from | `LiftShipFromMap` (tail), `PutShipOnMap`, `RefreshRadar` (tail), `MenuRadarTick` |
| Calls | `ToggleRadarDot` (tail) |
| Reads | `$FD0D`-`$FD1E` (`work space $FD0D+`) |

#### `MenuRadarTick` (`$B048`)

**one blink step of the ship's dot while a menu is open**

Called by the robot menu loop (DirectControl) and ListMenu each pass, so the world goes on and the ship's dot keeps blinking while the player sits in a menu: toggles the dot (BlinkShipDot), advances RadarBlink, rebuilds the radar if needed and toggles again on the new tick (RefreshRadar).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 82 calls, 3,936 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 155 calls, 7,459 t-states own (0.00 %) |
| Called from | `ListMenu` |
| Calls | `RefreshRadar` (tail), `BlinkShipDot` |
| Reads | `$FD1E` (`work space $FD1E+`) |
| Writes | `$FD1E` (`work space $FD1E+`) |

#### `CheckShipMove` (`$B052`)

**carry: the ship may not stand at HL (X), A (Y)**

Tests a place for the ship: HL = the column X, A = the row Y. C = the highest top under the ship's 2 x 2 footprint (X, Y), (X+1, Y), (X, Y-1), (X+1, Y-1): the terrain height of each cell and the top of any robot (+`$09` + +`$0D`) or building (BuildingTops) anchored there (CellTop; then ObjectTop alone on (X-1, Y-1), (X-1, Y) and, inside the map, the row Y+1 (X-1 to X+1), whose anchored objects reach into the footprint.

Out: carry set when Altitude < C (the ship would be inside something there), C = the top, HL = X kept; B kept (ObjectTop saves BC), DE and A lost, IY may point at the robot or building found. Called by MoveShip for the X move (MoveShipX), the Y move (ShipCheckY) and, with the ship's own place, by Sink to get the floor under the ship.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 1,772 calls, 533,505 t-states own (0.02 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,544 calls, 464,763 t-states own (0.03 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 36 calls, 10,836 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 6 calls, 1,806 t-states own (0.00 %) |
| Called from | `MoveShip` |
| Calls | `CellTop`, `ObjectTop`, `MapCell` |
| Reads | `$FD10` (`work space $FD10+`) |

#### `TerrainTop` (`$B08A`)

**C = max(C, the ground height of the terrain type at DE)**

DE a map cell. The cell's type (bits 0-4) indexes the ground height table TerrainHeights `$D7BC` (00 00 02 02 02 02 03 03 06 06 06 06 00 00 00 07 0F 07 0F...: types 2-5 height 2, 6-7 (the wreck a destroyed robot leaves) 3, 8-`$0B` 6, `$0F`/`$11` 7, `$10`/`$12` 15). Keeps the higher of it and C (KeepHigher). Used by CheckShipMove (through CellTop) and GroundUnderFootprint; 39396 calls.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 25,396 calls, 1,524,216 t-states own (0.07 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 52,680 calls, 3,161,522 t-states own (0.18 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 180 calls, 15,372 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 5,296 calls, 450,293 t-states own (0.07 %) |
| Called from | `CellTop`, `GroundUnderFootprint` |
| Calls | `KeepHigher` (tail), `AddAToHL` |
| Reads | `$D7BC`-`$D7CD` (`TerrainHeights`); `$DD1D`-`$DE68` (`work space $DD1D+`); `$DE8C`-`$DE9D` (`work space $DE8C+`); `$DECC`-`$DEE9` (`work space $DECC+`); `$DF1D`-`$DF4C` (`work space $DF1D+`); `$DF65`-`$E068` (`work space $DF65+`); 2 more ranges |

#### `CellTop` (`$B096`)

**C = max(C, the ground and the object on cell DE)**

TerrainTop, then falls into ObjectTop: the highest point of a cell, used for the 2x2 footprint in CheckShipMove.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7,088 calls, 120,572 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 6,176 calls, 104,992 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 144 calls, 2,448 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 24 calls, 408 t-states own (0.00 %) |
| Called from | `CheckShipMove` |
| Calls | `TerrainTop` |

#### `ObjectTop` (`$B099`)

**C = max(C, the top of a robot or a building anchored at cell DE)**

When the cell has bit 6 (an object anchored there): a robot (FindRobot) counts with its body height +`$09` plus the ground under it +`$0D`; else a building (FindBuilding) with its height from BuildingTops by type. A cell with bit 6 that is neither (a shot) counts nothing. B and C are kept.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 8,860 calls, 665,812 t-states own (0.03 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 7,720 calls, 506,332 t-states own (0.03 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 180 calls, 10,044 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 30 calls, 1,674 t-states own (0.00 %) |
| Called from | `CheckShipMove` |
| Calls | `KeepHigher`, `FindRobot`, `FindBuilding`, `AddAToHL` |
| Reads | `$B0C1` (`BuildingTops`); `$DA09`-`$DA9D` (`work space $DA09+`); `$E311`-`$F719` (`work space $E311+`); `$F910`-`$F919` (`work space $F910+`); `$FB10`-`$FB18` (`work space $FB10+`); `$FF03` (`work space $FF03+`); 1 more ranges |

#### `KeepHigher` (`$B0AB`)

**C = max(C, A)**

The common tail of TerrainTop and ObjectTop.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 26,767 calls, 670,146 t-states own (0.03 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 53,387 calls, 1,337,210 t-states own (0.08 %) |
| Called from | `TerrainTop` (tail), `ObjectTop` |

### world

`src/game99/world.asm`

#### `WorldTurn` (`$B0CA`)

**one game turn of the world: the enemy commander, every robot, every shot**

Called once a game turn by the play loop (PlayLoop) and by the menus (DirectControl, ListMenu), so robots fight and walk on while the player chooses: 3415 calls in 36046 frames, a turn is about 10 frames. First EnemyCommander (one enemy slot built or re-ordered), then UpdateRobot for each of the 48 robot records `$DA00` whose +`$01` is not 0, then UpdateShot for each of the 5 shot records of 9 bytes at `$D7D3` whose +`$01` is not 0. Robots and shots are taken in slot order, the player's slots 0-23 first. Shot record 0 (`$D7D3`) is the one the player fires from the robot menu's COMBAT MODE (DirectControl -> FireShot; the robots use records 1-4 (FindFreeShot).

[Animation: `WorldTurn` at work](img/routines/WorldTurn.gif)

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,224 calls, 11,266,060 t-states own (0.51 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,094 calls, 10,702,365 t-states own (0.61 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 193,053 t-states own (0.07 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 4,584,672 t-states own (0.68 %) |
| Called from | `PlayLoop`, `ListMenu` |
| Calls | `UpdateRobot`, `UpdateShot`, `EnemyCommander` |
| Reads | `$D7D4`-`$D7F8` (`work space $D7D4+`); `$DA01`-`$DCF1` (`work space $DA01+`) |

#### `UpdateRobot` (`$B0FA`)

**one robot's game turn: dying, destroyed or a step of its AI**

IY = the robot record. Strength +`$0C` decides: positive, the robot acts (RobotStep; negative, the robot is dying: +`$0C` counts up from `$FC` (set by MoveShot's hit) and the object bit 6 of its cell is toggled each turn (cleared on even values, set on odd), so for four turns other robots and shots see it only every other turn; 0, the robot is destroyed (RobotDestroyed). 49165 calls.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 41,053 calls, 1,642,500 t-states own (0.07 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 52,244 calls, 14,321,228 t-states own (0.82 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 84 calls, 3,360 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 7,717 calls, 308,699 t-states own (0.05 %) |
| Called from | `WorldTurn` |
| Calls | `RobotStep` (tail), `SteerByOrder`, `TurnOrStep`, `CountDirections`, `FreeDirections`, `SetStepDelay`, `SpotEnemies`, `FindFreeShot`, `FireShot`, `CountRobots`, `PutBlock`, `PlaceRobot` (tail), `UpdateStatusPanel`, `Random`, `ToggleRadarDot` |
| Reads | `$DA00`-`$DA9F` (`work space $DA00+`); `$DB80`-`$DCFF` (`work space $DB80+`); `$DF1D`-`$E067` (`work space $DF1D+`); `$E08C`-`$E09C` (`work space $E08C+`); `$E0CC`-`$E0E8` (`work space $E0CC+`); `$E122`-`$E149` (`work space $E122+`); 3 more ranges |
| Writes | `$DA01`-`$DA9F` (`work space $DA01+`); `$DB81`-`$DCFF` (`work space $DB81+`); `$DF1D`-`$E067` (`work space $DF1D+`); `$E08C`-`$E09C` (`work space $E08C+`); `$E0CC`-`$E0E8` (`work space $E0CC+`); `$E122`-`$E149` (`work space $E122+`); 4 more ranges |

#### `RobotStep` (`$B154`)

**a live robot: wait for its step delay, then look, fire, steer and move one step**

Entered from UpdateRobot with strength > 0 (JP P). A robot the player sits on (+`$0A` = 1, the robot menu is open) does nothing. Side (`$FD51`) = 0 ours / 1 the enemy's (+`$0A` bit 7), read by the target searches. The step delay +`$0F` counts the turns down; at 0 the robot leaves its cell (bit 6 cleared, radar dot erased) and FreeDirections gives C, the directions it can step to (bit 0 right, 1 left, 2 down, 3 up, the Input order).

Direct control (+`$0A` = 2): the stick decides (RobotDirectControl). Otherwise SpotEnemies gives E, the directions with a live opponent in sight. An opponent ahead (E AND the facing +`$08`): the robot moves on if it can and fires when a shot record of its side is free and its weapons allow (FindFreeShot, FireShot; a shot stops it for this step). An opponent to a side: it turns to it (+`$05` = that direction, one picked at random among several, +`$06` = 2). No opponent: it keeps its direction +`$05` for +`$06` more steps while that direction stays free, else it takes a new course for 3-6 steps from SteerByOrder (RobotNewCourse). RobotMove then turns or steps, reloads the delay (SetStepDelay) and puts the robot back on the map (PlaceRobot: the record's x/y/cell, bit 6, the dot).

the shot records and strengths at frames 18680-18850 match FireShot and MoveShot (robot 2 hit twice by an enemy missile, 100 -> 70 -> 40; robot 25 hit by our cannon, 100 -> 80 -> 60 -> 40).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 41,053 calls, 9,964,970 t-states own (0.45 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 84 calls, 21,174 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 7,717 calls, 1,932,451 t-states own (0.29 %) |
| Called from | `UpdateRobot` (tail) |
| Calls | `SteerByOrder`, `TurnOrStep`, `CountDirections`, `FreeDirections`, `SetStepDelay`, `SpotEnemies`, `PlaceRobot` (tail), `Random`, `ToggleRadarDot` |
| Reads | `$DA00`-`$DA6F` (`work space $DA00+`); `$DB80`-`$DBAF` (`work space $DB80+`); `$DBC0`-`$DC7F` (`work space $DBC0+`); `$DC90`-`$DCAF` (`work space $DC90+`); `$DCC0`-`$DCFF` (`work space $DCC0+`); `$E90E`-`$EB16` (`work space $E90E+`); 6 more ranges |
| Writes | `$DA05`-`$DA6F` (`work space $DA05+`); `$DB85`-`$DC7F` (`work space $DB85+`); `$DC95`-`$DCAF` (`work space $DC95+`); `$DCC5`-`$DCFF` (`work space $DCC5+`); `$E90E`-`$EB16` (`work space $E90E+`); `$ECED`-`$F316` (`work space $ECED+`); 6 more ranges |

#### `SteerByOrder` (`$B222`)

**C = the direction the robot's order wants, chosen among the free ones in C**

IY the robot, C the free directions (FreeDirections; out C a single direction bit, or 0 to stand. B keeps the free set. By the order +`$0B`:

0 stop: C = 0. 1 advance / 2 retreat: right / left (RobotLeanTo). When that direction is free: two random bits for it, else a random free one other than the opposite, which may be it again (0.835 with all four free, 0.88 with up or down blocked, 1.0 in a corridor; docs/13 13.3.2). When it is blocked: any free one, the opposite included. RobotStepPos counts the distance +`$0E`.

3 destroy robots: the target is the opponent robot of index +`$0E` (TargetRobotRecord). It is kept while it lives and is less than 50 columns away; else the nearest live opponent by column distance is taken (FindNearestOpponent), none: a random free direction.

4-8 the building orders: the target is record +`$0E` of the factory table `$FD84` or the warbase table `$FD70` (TargetBuildingTable). It is kept while its owner bits are still the ones the order looks for; else the nearest such building nobody of the side is already after is taken (FindTargetBuilding). None: the robot stands, and an enemy robot falls back to destroy robots.

The aim (RobotAim): D = the directions toward the target, horizontal from the sign of the column difference, vertical from the row difference; for a building, while the columns differ, the row aimed at is 3 below the building's row. More than 7 columns away (the low byte of the column difference only) the robot leans horizontally like an advance (RobotLeanTo): the target's row is ignored. Closer, one of the free wanted directions at random (none free: any free one; when a horizontal one is among them, +`$06` = |dx| - 1 for whichever is picked, a vertical one too. On the target (D = 0): the destroy orders 4-5 go to the nuclear charge at NuclearBlast (outside this range; the others turn the robot to face down and stand.

the warbase orders read factory 0's door). The wrong decision lasts a whole course of 3-6 steps: right from column 256 on; a random free direction on columns 14-255, rows 1-8; on columns 14-255, rows 9-15 the aim is "on the target": the robot faces down and stands, and a nuclear robot with order 4 blows up where it stands (NuclearBlast;3.6). The next decision aims right.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 3,900 calls, 2,222,256 t-states own (0.10 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 3,634 calls, 2,180,602 t-states own (0.12 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 14 calls, 2,327 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 685 calls, 351,892 t-states own (0.05 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `FindTargetBuilding`, `ColumnDistance`, `TargetBuildingTable`, `TargetRobotRecord`, `FindNearestOpponent`, `CountDirections`, `AddAToHL`, `Random` |
| Reads | `$DA01`-`$DA9E` (`work space $DA01+`); `$DB81`-`$DCFE` (`work space $DB81+`); `$FD70`-`$FDFE` (`work space $FD70+`) |
| Writes | `$DA06`-`$DA6E` (`work space $DA06+`); `$DB86`-`$DCFE` (`work space $DB86+`) |

#### `PickOneDirection` (`$B33E`)

**C = one direction bit picked at random from the set in B**

Masks C with random bytes until exactly one bit is left (CountDirections; when nothing is left it starts again from B. B must not be 0. The common exit of SteerByOrder's branches and used by RobotTurnToEnemy for several opponents.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `FindTargetBuilding` (`$B34D`)

**D = the nearest building the order wants and no teammate is after; Z when none**

A = the order (3 goes to FindNearestOpponent), HL = the robot's column, IY the robot, Side set. The order picks the table and owner (TargetBuildingTable; every record with those owner bits is offered to ConsiderBuilding, which skips it when a robot of our side with the same order already has it as its +`$0E`, and keeps the nearest by column distance (KeepNearest). Out D = the record's index (or `$FF`), A = D + 1 (Z: none). HL is left past the table: the cause of the bug noted at SteerByOrder.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 59 calls, 49,702 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 102 calls, 104,965 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 2,052 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 23 calls, 20,685 t-states own (0.00 %) |
| Called from | `SetOrder`, `SteerByOrder`, `EnemyCommander` |
| Calls | `ConsiderBuilding`, `TargetBuildingTable`, `InitNearestSearch`, `FindNearestOpponent` (tail) |
| Reads | `$FD73`-`$FDFA` (`work space $FD73+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |

#### `ConsiderBuilding` (`$B36C`)

**offer building C to KeepNearest unless a teammate with the same order already targets it**

HL = the record's owner byte (+`$03`), C its index, A' the order. Scans the 24 records of our side (`$DA00` ours, `$DB80` the enemy's by Side) for a live robot whose order +`$0B` is A' and whose target +`$0E` is C. None: the record's column (+`$00`/+`$01`) goes to KeepNearest. The robot that asks is in the list too; its +`$0E` holds its old target (or `$FF`).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 344 calls, 871,929 t-states own (0.04 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 647 calls, 1,645,537 t-states own (0.09 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 64,770 t-states own (0.02 %) |
| Runs (CRITICAL with every upgrade, several game days) | 157 calls, 384,649 t-states own (0.06 %) |
| Called from | `FindTargetBuilding` |
| Calls | `KeepNearest` |
| Reads | `$DA01`-`$DCFB` (`work space $DA01+`); `$FD51` (`work space $FD51+`); `$FD70`-`$FDF8` (`work space $FD70+`) |

#### `KeepNearest` (`$B3B3`)

**keep candidate C when the column HL is nearer to DE' than the best BC'**

The comparison step of the nearest searches (InitNearestSearch sets it up): HL' = |HL - DE'|, and when it is below BC' it becomes the best and D = C. Only the column distance counts; rows are ignored. A and HL' are lost; the main BC, E, HL and IY are kept. Called by ConsiderBuilding and FindNearestOpponent.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 12,291 calls, 1,205,979 t-states own (0.05 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 9,293 calls, 894,151 t-states own (0.05 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 2,507 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 132 calls, 12,865 t-states own (0.00 %) |
| Called from | `ConsiderBuilding`, `FindNearestOpponent` |
| Calls | `ColumnDistance` |

#### `ColumnDistance` (`$B3CA`)

**HL = |HL - DE|**

HL, DE two columns (0-511). A 16-bit absolute difference: SBC HL,DE and, when the result's sign is set, 0 - HL. DE is kept; A = 0 on the positive path, the high byte's negation on the other. Used by KeepNearest and by SteerByOrder's 50-column test of a robot target.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 13,891 calls, 727,504 t-states own (0.03 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 10,573 calls, 552,182 t-states own (0.03 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 1,101 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 132 calls, 7,524 t-states own (0.00 %) |
| Called from | `SteerByOrder`, `KeepNearest` |

#### `TargetBuildingTable` (`$B3D5`)

**HL, B, E = the building table, its size and the owner a building order wants**

A = the order. Orders 5 and 8 (destroy / capture warbases): HL = `$FD73`, the owner byte of the first of the 4 warbase records (Warbases `$FD70`, 5 bytes each), B = 4; the others: HL = `$FD87`, the owner byte of the first of 24 factory records (Factories `$FD84`), B = 24. E = the owner bits sought: `$20` (the computer's) for our robots, `$40` (ours) for the enemy's (Side = 1), 0 (neutral) for order 6, capture neutral factories.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 1,411 calls, 192,968 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,047 calls, 279,999 t-states own (0.02 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 5 calls, 663 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 495 calls, 68,144 t-states own (0.01 %) |
| Called from | `SteerByOrder`, `FindTargetBuilding`, `EnemyCommander` |
| Reads | `$FD51` (`work space $FD51+`) |

#### `TargetRobotRecord` (`$B3F9`)

**HL = the opponent robot record of index +`$0E`**

HL = `$DB80` + 16 * (+`$0E`) for our robots, `$DA00` + 16 * (+`$0E`) for the enemy's (Side). Used by SteerByOrder's destroy-robots branch.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 3,232 calls, 366,893 t-states own (0.02 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,830 calls, 321,016 t-states own (0.02 %) |
| Called from | `SteerByOrder` |
| Reads | `$DA2E`-`$DA6E` (`work space $DA2E+`); `$DB8E`-`$DBFE` (`work space $DB8E+`); `$DC1E` (`work space $DC1E+`); `$DC3E` (`work space $DC3E+`); `$DC5E` (`work space $DC5E+`); `$DC7E`-`$DCAE` (`work space $DC7E+`); 2 more ranges |

#### `InitNearestSearch` (`$B411`)

**start a nearest-by-column search from column HL**

DE' = HL (our column), BC' = `$2000` (no candidate yet), C = 0 (the first index), D = `$FF` (the result: none). Used by FindTargetBuilding and FindNearestOpponent with KeepNearest.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 1,691 calls, 106,552 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,376 calls, 86,726 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 126 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 191 calls, 12,033 t-states own (0.00 %) |
| Called from | `FindTargetBuilding`, `FindNearestOpponent` |

#### `FindNearestOpponent` (`$B41D`)

**D = the index of the nearest live opponent robot by column; Z when none**

HL = our column, IY the robot, Side set. Runs KeepNearest over the 24 opponent records (`$DB80` the enemy's for us, `$DA00` ours for the enemy) whose +`$01` is not 0 (a dying robot counts). Out D = the slot within the side (or `$FF`), A = D + 1 (Z: none; IY is kept, B ends 0 and C 24 (the callers keep BC), DE' / BC' / HL' are the search's. Called by SteerByOrder (order 3) and, through FindTargetBuilding with A = 3, by EnemyFindTarget and SetOrder. 426 calls.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 1,635 calls, 4,626,626 t-states own (0.21 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,279 calls, 3,591,107 t-states own (0.21 %) |
| Runs (CRITICAL with every upgrade, several game days) | 168 calls, 413,524 t-states own (0.06 %) |
| Called from | `SteerByOrder`, `FindTargetBuilding` (tail) |
| Calls | `KeepNearest`, `InitNearestSearch` |
| Reads | `$DA01`-`$DCF3` (`work space $DA01+`); `$FD51` (`work space $FD51+`) |

#### `RobotDirectControl` (`$B450`)

**direct control: the stick steers the robot**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TurnOrStep` (`$B471`)

**turn the robot toward direction A, or step one cell when it faces it**

IY the robot, HL its column, B its row, A a direction bit (0: nothing). Facing +`$08` not A: the robot turns, never by 180 degrees in one go (right <-> left goes through down / up, down <-> up through right / left), and +`$06` is incremented so the turn does not shorten the course. Facing A: StepPosition moves HL/B, GroundUnderFootprint sets +`$0D`, and under direct control (+`$0A` = 2) MoveShip moves the ship by the same Input and the ship sits on the robot's top (Altitude = +`$09` + +`$0D`).

Experiment (DIRECT CONTROL on a new bipod + cannon robot at (22,14)): holding right the robot turned from facing down (4) to right (1) in one step and moved one column a step (6 turns, about 60 frames; after the release it went on one more step in the same direction; the ship moved with it and Altitude stayed 17 (bipod 11 + cannon 6, ground 0).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,784 calls, 1,297,250 t-states own (0.06 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,039 calls, 1,875,118 t-states own (0.11 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 1,964 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,418 calls, 316,733 t-states own (0.05 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `StepPosition`, `GroundUnderFootprint` |
| Reads | `$DA06`-`$DA9A` (`work space $DA06+`); `$DB86`-`$DCFA` (`work space $DB86+`) |
| Writes | `$DA06`-`$DA9D` (`work space $DA06+`); `$DB86`-`$DCFD` (`work space $DB86+`) |

#### `StepPosition` (`$B4B9`)

**move HL (column) / B (row) one cell in direction A; advance / retreat count their distance**

A bit 0 right (HL+1), 1 left (HL-1), 2 down (B+1), 3 up (B-1). For the orders 1 advance and 2 retreat (not under direct control) +`$0E` is the distance still to go: a column in the order's direction (right for advance, left for retreat) takes one off and at 0 the order becomes 0 stop (+`$06` = 0; a column the other way adds one, up to `$63`.

Experiment: ADVANCE with 5 MILES (the robot menu stores miles * 2 into +`$0E` = 10): the robot went 4 columns right (+`$0E` 10 -> 6), 5 rows up round an obstacle (+`$0E` unchanged), 6 more columns right and then stood with order 0 and +`$0E` = 0.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 4,577 calls, 319,056 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 11,437 calls, 861,399 t-states own (0.05 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 9 calls, 527 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,318 calls, 90,791 t-states own (0.01 %) |
| Called from | `TurnOrStep` |
| Reads | `$DA0B`-`$DA9B` (`work space $DA0B+`); `$DB8B`-`$DCFB` (`work space $DB8B+`) |

#### `CountDirections` (`$B505`)

**flags of (the number of set bits in C's low nibble) - 1**

Z: exactly one direction; carry: none; neither: two or more. Counts bits 0-3 of C, keeps BC.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 10,667 calls, 1,664,394 t-states own (0.08 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 6,787 calls, 1,058,981 t-states own (0.06 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 22 calls, 3,432 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,954 calls, 304,862 t-states own (0.05 %) |
| Called from | `UpdateRobot`, `RobotStep`, `SteerByOrder`, `EnemyCommander` |

#### `FreeDirections` (`$B513`)

**C = the directions the robot at cell HL may step to**

IY the robot, HL its anchor cell. A robot covers 2x2 cells: its anchor (X, Y) carries the object bit 6, plus (X+1, Y), (X, Y-1), (X+1, Y-1). D = the first terrain type it cannot enter, by its locomotion: bipod 8 (types 0-7, ground heights 0-3), tracks `$0C` (also 8-`$0B`, height 6), anti-grav `$0F` (also `$0C-$0E`, height 0 in TerrainHeights; the types from `$0F` (heights 7 and 15) stop all. E = the bits that block: 6 (objects) always, 7 (the ship's cell) when the ship hangs lower than the robot's top. One probe a direction (CanMoveRight, CanMoveLeft, CanMoveDown, CanMoveUp; bit 0 right, 1 left, 2 down, 3 up. 9652 calls.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,784 calls, 4,123,533 t-states own (0.19 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,039 calls, 5,351,852 t-states own (0.31 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 8,882 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,418 calls, 853,551 t-states own (0.13 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `CanMoveRight`, `CanMoveLeft`, `CanMoveDown`, `CanMoveUp` |
| Reads | `$DA07`-`$DA9D` (`work space $DA07+`); `$DB87`-`$DCFD` (`work space $DB87+`); `$FD10` (`work space $FD10+`) |

#### `CanMoveRight` (`$B557`)

**Z when the robot at HL can step right**

Terrain and objects at the column it enters, (X+2, Y-1) and (X+2, Y; an object anchored at (X+2, Y+1) (its footprint would overlap) when that row exists.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,784 calls, 973,610 t-states own (0.04 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,039 calls, 1,627,278 t-states own (0.09 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 2,478 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,418 calls, 210,918 t-states own (0.03 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `TestCell` |
| Reads | `$E11F`-`$E269` (`work space $E11F+`); `$E28E`-`$E29D` (`work space $E28E+`); `$E2CE`-`$E467` (`work space $E2CE+`); `$E48E`-`$E4AC` (`work space $E48E+`); `$E4CE`-`$E66B` (`work space $E4CE+`); `$E68E`-`$E6AC` (`work space $E68E+`); 1 more ranges |

#### `CanMoveLeft` (`$B56F`)

**Z when the robot at HL can step left**

Terrain and objects at (X-1, Y-1) and (X-1, Y; objects anchored at (X-2, Y-1), (X-2, Y) and (X-2, Y+1).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,784 calls, 1,157,327 t-states own (0.05 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,039 calls, 2,063,288 t-states own (0.12 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 3,228 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,418 calls, 250,637 t-states own (0.04 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `TestCell` |
| Reads | `$DD1B`-`$DE9A` (`work space $DD1B+`); `$DECA`-`$E2A8` (`work space $DECA+`); `$E2CA`-`$FCF3` (`work space $E2CA+`) |

#### `CanMoveDown` (`$B58F`)

**Z when the robot at HL can step down**

Blocked at the bottom row; terrain and objects at (X, Y+1) and (X+1, Y+1; objects anchored at (X+1, Y+2), (X, Y+2) and (X-1, Y+2) when that row exists.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,784 calls, 1,536,390 t-states own (0.07 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,039 calls, 2,051,236 t-states own (0.12 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 4,091 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,418 calls, 319,441 t-states own (0.05 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `CellBlocked` (tail), `TestCell` |
| Reads | `$E31C`-`$E468` (`work space $E31C+`); `$E48B`-`$E49D` (`work space $E48B+`); `$E4CB`-`$E4E9` (`work space $E4CB+`); `$E521`-`$E54A` (`work space $E521+`); `$E564`-`$E666` (`work space $E564+`); `$E68B`-`$E6AB` (`work space $E68B+`); 1 more ranges |

#### `CanMoveUp` (`$B5B1`)

**Z when the robot at HL can step up**

Blocked when Y-2 is above the map (the footprint already covers Y-1; an object anchored at (X-1, Y-2), terrain and objects at (X, Y-2) and (X+1, Y-2).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,784 calls, 1,175,287 t-states own (0.05 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,039 calls, 1,609,695 t-states own (0.09 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 2,601 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,418 calls, 254,104 t-states own (0.04 %) |
| Called from | `FreeDirections` |
| Calls | `CellBlocked` (tail), `TestCell` |
| Reads | `$DD21`-`$DD48` (`work space $DD21+`); `$DD64`-`$DE64` (`work space $DD64+`); `$DE8B`-`$DEA9` (`work space $DE8B+`); `$DECB`-`$DEE7` (`work space $DECB+`); `$DF21`-`$DF48` (`work space $DF21+`); `$DF60`-`$E148` (`work space $DF60+`); 1 more ranges |

#### `CellOffMapFree` (`$B5C8`)

**Z: a probe that runs past the bottom row finds the way free**

The shared exit of the probes for rows below the map.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,617 calls, 36,676 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 4,647 calls, 65,077 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 634 calls, 8,876 t-states own (0.00 %) |
| Called from | `CanMoveRight` (tail), `CanMoveLeft` (tail), `CanMoveDown` (tail) |

#### `CellBlocked` (`$B5CA`)

**NZ: the way is blocked**

The shared exit for an unpassable terrain type or a map edge.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 12,007 calls, 204,176 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 11,182 calls, 190,132 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,307 calls, 39,219 t-states own (0.01 %) |
| Called from | `CanMoveDown` (tail), `CanMoveUp` (tail), `TestCell` (tail) |

#### `TestCell` (`$B5CD`)

**Z when cell HL is passable: type below D and none of the bits E**

HL a map cell, D the first terrain type the locomotion cannot enter (FreeDirections), E the blocking bits (`$40` objects, plus `$80` the ship's cell when the ship hangs lower than the robot's top). NZ through CellBlocked when the type (bits 0-4) is D or more; else A = the cell AND E (Z: free). HL kept. Used by the four CanMove probes for the cells the footprint enters; the cells only checked for anchors use AND E directly. 67380 calls.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 70,773 calls, 3,098,495 t-states own (0.14 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 105,709 calls, 4,736,757 t-states own (0.27 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 174 calls, 8,025 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 15,249 calls, 671,662 t-states own (0.10 %) |
| Called from | `CanMoveRight`, `CanMoveLeft`, `CanMoveDown`, `CanMoveUp` |
| Calls | `CellBlocked` (tail) |
| Reads | `$DD1C`-`$DE69` (`work space $DD1C+`); `$DE8B`-`$DEAB` (`work space $DE8B+`); `$DECB`-`$DF4C` (`work space $DECB+`); `$DF61`-`$E06A` (`work space $DF61+`); `$E08B`-`$FCF6` (`work space $E08B+`) |

#### `GroundUnderFootprint` (`$B5D6`)

**A = the highest ground under the 2x2 footprint anchored at (HL, B)**

HL a column, B a row. TerrainTop over (X, Y), (X+1, Y), (X+1, Y-1), (X, Y-1), the highest kept in C; HL and BC are kept, DE is lost (the last cell). The robots' +`$0D` (the ground they stand on: SetStepDelay's row, the drawing height, the ship's seat under direct control) and the shots' wall test (MoveShot against +`$08` = `$0A`).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 4,577 calls, 805,780 t-states own (0.04 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 11,626 calls, 2,046,822 t-states own (0.12 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 9 calls, 1,584 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,318 calls, 232,006 t-states own (0.03 %) |
| Called from | `TurnOrStep`, `MoveShot` |
| Calls | `TerrainTop`, `MapCell` |

#### `SetStepDelay` (`$B5F3`)

**+`$0F` = the turns until the robot's next step, by the ground and its locomotion**

The ground class from +`$0D`: 0 flat, 1-3 low, 4 and more high; the column from the lowest set part bit of +`$07`: 0 bipod, 1 tracks, 2 anti-grav. StepDelays gives the turns. The recorded records agree (robot 0, a bipod on flat ground, counts 6 down).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,784 calls, 2,698,392 t-states own (0.12 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,039 calls, 3,548,402 t-states own (0.20 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 5,620 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,418 calls, 563,022 t-states own (0.08 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `AddAToHL` |
| Reads | `$B61D`-`$B625` (`StepDelays`); `$DA07`-`$DA9D` (`work space $DA07+`); `$DB87`-`$DCFD` (`work space $DB87+`) |
| Writes | `$DA0F`-`$DA9F` (`work space $DA0F+`); `$DB8F`-`$DCFF` (`work space $DB8F+`) |

#### `SpotEnemies` (`$B626`)

**E = the directions in which a live opponent robot is in sight**

IY the robot. For each direction (up, down, left, right: E's bits 3, 2, 1, 0 as in Input) ScanLane looks from the robot's anchor up to 8 cells; in the facing direction +`$08` the range is 10, 12 with electronics (+`$07` bit 7), and three parallel lanes are scanned (the columns X-1, X, X+1 for up / down, the rows Y-1, Y, Y+1 for left / right). 9652 calls.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,784 calls, 7,641,109 t-states own (0.35 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,039 calls, 9,749,929 t-states own (0.56 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25 calls, 16,189 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,418 calls, 1,567,715 t-states own (0.23 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `ScanLane` |
| Reads | `$DA00`-`$DA98` (`work space $DA00+`); `$DB80`-`$DCF8` (`work space $DB80+`) |

#### `ScanLane` (`$B66E`)

**set E bit 0 when a live opponent's anchor lies within B cells from HL in direction D**

The step comes from LaneSteps by D's bit. The scan stops at the map's top or bottom edge and at the first cell with an object (bit 6): only a robot of the other side (+`$0A` bit 7 differs) with strength above 0 sets the bit. Buildings, shots and friends block the view. HL, DE are kept apart from E's bit 0.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 70,704 calls, 44,076,553 t-states own (2.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 90,234 calls, 66,235,825 t-states own (3.78 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 150 calls, 96,429 t-states own (0.03 %) |
| Runs (CRITICAL with every upgrade, several game days) | 14,508 calls, 9,454,708 t-states own (1.40 %) |
| Called from | `SpotEnemies` |
| Calls | `FindRobot` |
| Reads | `$B6B0`-`$B6B7` (`LaneSteps`); `$DA0A`-`$DA9C` (`work space $DA0A+`); `$DB8A`-`$FCFF` (`work space $DB8A+`) |

#### `FindFreeShot` (`$B6B8`)

**IY = a free shot record of the shooter IX's side; Z when one is free**

Each side has two shot records of 9 bytes: ours `$D7DC` and `$D7E5`, the enemy's `$D7EE` and `$D7F7` (by IX +`$0A` bit 7). Z with IY on the first one whose +`$01` is 0; NZ when both fly.

| | |
| --- | --- |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 105 calls, 10,079 t-states own (0.00 %) |
| Called from | `UpdateRobot` |
| Reads | `$D7DD` (`work space $D7DD+`); `$D7EF`-`$D7F8` (`work space $D7EF+`); `$DA0A` (`work space $DA0A+`); `$DA2A`-`$DA3A` (`work space $DA2A+`); `$DA6A`-`$DA9A` (`work space $DA6A+`); `$DB8A` (`work space $DB8A+`); 4 more ranges |

#### `FireShot` (`$B6D6`)

**launch shot IY of weapon A from robot IX in its facing direction**

Called by RobotStep and by COMBAT MODE in the robot menu (DirectControl, IX = IY = the robot, record 0). Shot record (9 bytes): +`$00`/+`$01` the map cell, +`$02`/+`$03` the column, +`$04` the row, +`$05` the direction, +`$06` the steps left, +`$07` the weapon (1 cannon, 2 missiles, 3 phasers), +`$08` the ground height that stops it (`$0A`). The range is 5 steps (7 for missiles), one more with electronics; each step goes 2 cells. The first step is taken at once (MoveShot), from the shooter's anchor: in RobotStep the shooter is already off the map (bit 6 cleared), so it cannot hit itself.

When the shot survives the first step SoundFx (`$FD53`) = 1, the firing sound; when it ends at once, MoveShot's sound (`$FC`, `$FA` or `$C8`) stays.

| | |
| --- | --- |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 76 calls, 21,339 t-states own (0.00 %) |
| Called from | `UpdateRobot` |
| Calls | `MoveShot` |
| Reads | `$D7DD` (`work space $D7DD+`); `$D7EF`-`$D7F8` (`work space $D7EF+`); `$DA02`-`$DA38` (`work space $DA02+`); `$DA62`-`$DA68` (`work space $DA62+`); `$DA82`-`$DA98` (`work space $DA82+`); `$DB82`-`$DB88` (`work space $DB82+`); 4 more ranges |
| Writes | `$D7E1`-`$D7FF` (`work space $D7E1+`); `$FD53` (`work space $FD53+`) |

#### `UpdateShot` (`$B70D`)

**one game turn of shot IY: off its cell, count its range, a step**

Clears the object bit of the shot's cell, counts +`$06` down (0: the shot is gone, ShotGone) and goes on into MoveShot from its column / row.

| | |
| --- | --- |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 113 calls, 16,159 t-states own (0.00 %) |
| Called from | `WorldTurn` |
| Calls | `MoveShot` |
| Reads | `$D7DC`-`$D7FD` (`work space $D7DC+`); `$E936`-`$E954` (`work space $E936+`); `$E977`-`$E979` (`work space $E977+`); `$EB45`-`$EB48` (`work space $EB45+`); `$ED2A`-`$ED4F` (`work space $ED2A+`); `$EF29`-`$EF72` (`work space $EF29+`); 3 more ranges |
| Writes | `$D7E2` (`work space $D7E2+`); `$D7F4`-`$D7FD` (`work space $D7F4+`); `$E936`-`$E954` (`work space $E936+`); `$E977`-`$E979` (`work space $E977+`); `$EB45`-`$EB48` (`work space $EB45+`); `$ED2A`-`$ED4F` (`work space $ED2A+`); 4 more ranges |

#### `MoveShot` (`$B724`)

**move shot IY 2 cells, then hit a wall, an object or fly on**

IY the shot record, HL its column, B its row. One step: 2 cells in +`$05`. Off the rows 0-15 (only tested for down / up; the columns are not range-checked), or ground of height +`$08` (`$0A`) or more under its 2x2 footprint (only the types `$10` / `$12`, height 15; heights up to 7 let it pass): gone (ShotGone, SoundFx `$FC`). The new position and cell go into +`$00`-+`$04`.

Then the 3x3 cells around the new cell are tested for an object (bit 6), row Y-1 and Y+1 only inside the map; none: the shot marks its own cell with bit 6 and flies on. An object that is a live robot (either side: friendly fire is possible) takes damage ((60 - its top) / 4) * (weapon + 1), the top being +`$09` + +`$0D`, so tall robots on high ground take less: strength 0 or below makes it `$FC` (dying, UpdateRobot) with SoundFx `$C8`, else SoundFx `$FA`. Any other object (a building, another shot, a dying robot) just ends the shot (SoundFx `$FC`). Either way the record is freed (+`$01` = 0, the other bytes stay).

The recorded hits agree: a missile (2) into a 19 high robot takes 10 * 3 = 30, a cannon shell 10 * 2 = 20. Entered from UpdateShot (falling through) and FireShot.

| | |
| --- | --- |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 189 calls, 122,664 t-states own (0.01 %) |
| Called from | `FireShot`, `UpdateShot` |
| Calls | `GroundUnderFootprint`, `MapCell`, `FindRobot` |
| Reads | `$D7E1`-`$D7FF` (`work space $D7E1+`); `$DA09`-`$DA9D` (`work space $DA09+`); `$DB89`-`$DB8D` (`work space $DB89+`); `$DBD9`-`$DBDD` (`work space $DBD9+`); `$DBF9`-`$DBFD` (`work space $DBF9+`); `$DC59`-`$DC5D` (`work space $DC59+`); 12 more ranges |
| Writes | `$D7DC`-`$D7FB` (`work space $D7DC+`); `$DA0C`-`$DA9C` (`work space $DA0C+`); `$DB8C` (`work space $DB8C+`); `$DBDC` (`work space $DBDC+`); `$DBFC` (`work space $DBFC+`); `$DC5C` (`work space $DC5C+`); 10 more ranges |

#### `ShotGone` (`$B7EA`)

**out of range or off the map: the shot is gone with the short sound**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### enemy

`src/game99/enemy.asm`

#### `EnemyCommander` (`$B7F4`)

**once a game turn the computer looks at one of its 24 robot slots: builds a robot in a free one or re-thinks a robot's order**

Called first by WorldTurn. A random number 0-31 picks the slot; 24-31 (a quarter of the turns) do nothing. Side = 1. The slot's record is `$DB80` + 16 * n.

A live robot goes to EnemyReplan: one with order 0 at once, any other with a 1/32 chance a turn, gets a new order (EnemyChooseOrder: a nuclear robot destroy factories or warbases, the others one of the capture orders; destroy robots when the order finds no target). Orders 4-8 are kept only while the target has changed owner and the robot stands on its door: the capture under way.

A free slot tries a build at a random enemy warbase (owner `$20` in the Warbases table) whose door and the three cells below it are free of bit 6: random parts (exactly one locomotion, at least one and not all four of the weapon / nuclear parts, at least 1, 2 or 3 of those parts while the computer has 0-7, 8-15 or 16-23 robots, EnemyRobotCount `$FD49`), paid from EnemyResources (`$FD4A`, through MenuResources and PartCosts like the player's), the shortfall of the other resources taken from the general one, at most half of it (at least 11). A refused design is not retried: the slot waits for another turn.

The robot is set up facing down, 3 steps, order 0, strength `$64`, +`$0A` = `$80`, +`$0E` = `$FF`, +`$0F` = 1, height +`$09` the sum of the part heights `$D7B4` (bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7; then CountRobots and UpdateStatusPanel. IY is left on the slot's record; A, BC, DE, HL and the alternate HL', B' lost.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,224 calls, 688,345 t-states own (0.03 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,094 calls, 571,771 t-states own (0.03 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 20,382 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 332,303 t-states own (0.05 %) |
| Called from | `WorldTurn` |
| Calls | `FillEnemyResources`, `FindTargetBuilding`, `TargetBuildingTable`, `CountDirections`, `CountRobots`, `PlaceRobot`, `MapCell`, `UpdateStatusPanel`, `AddAToHL`, `Random` |
| Reads | `$CAF0`-`$CAFF` (`PartCosts`); `$D7B4`-`$D7BB` (`PartHeights`); `$DB81`-`$DCFB` (`work space $DB81+`); `$EE05` (`work space $EE05+`); `$EE71` (`work space $EE71+`); `$EEEE`-`$EEF1` (`work space $EEEE+`); 8 more ranges |
| Writes | `$DB85`-`$DCFF` (`work space $DB85+`); `$FD29`-`$FD2F` (`work space $FD29+`); `$FD4A`-`$FD51` (`work space $FD4A+`) |

#### `NuclearBlast` (`$B99F`)

**NuclearBlast**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `NuclearFlash` (`$BA87`)

**The nuclear blast's flash: the view's paper flickers through random colours with a fading rumble**

Called only by the blast (`$BA76`). Saves the 20 x 20 attributes of the view (from `$5821`, row 1 column 1) to `$5B00-$5C8F`, then 61 times: a burst of noise (`$BAEE`, 244 samples first, 4 fewer and a longer delay each time) and a new random paper colour (2-7, never the previous one) on every attribute of the view whose paper is not black. Restores the saved attributes at the end. The flash lasts 216 frames (4.3 s, measured; the game stands still meanwhile.

`$5B00` is free scratch at that time (the printer buffer and above, also the save checksum of `$C2E8`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `NuclearRumble` (`$BAEE`)

**One burst of the blast's noise: B samples of ROM bytes to the speaker, C the delay between**

Plays B samples: bit 4 (the speaker) of the ROM bytes from `$0090` on, the border black, with a delay loop of C x 24 T-states after each. Returns B - 3 and C + 3, so the next burst of NuclearFlash is shorter and lower: a dying rumble. Only NuclearFlash calls it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### bases

`src/game99/bases.asm`

#### `CountBases` (`$BB09`)

**Count each side's bases: warbases and the factories of each type**

Clears PlayerBuildings (`$FD3A`, 7 counts) and EnemyBuildings (`$FD42`, 7) and goes through the 28 base records (`$FD70`, 5 bytes, read at +3): a base whose +3 has bit 6 counts for the player, bit 5 for the enemy, at index +3 bits 0-2 (0 warbases, 1-6 the factories of type 1-6: electronics, nuclear, phasers, missiles, cannon, chassis, the resource each makes; neutral and destroyed (bit 7) bases do not count. PlayerRobotCount (`$FD41`) between the two count blocks is skipped. The status panel shows these counts (`$D2C1`; the daily production (`$AE38`) adds 5 general per warbase and 2 per factory to its resource; a side with no warbase loses (`$AE6B`).

Called after every change of owner (the capture tick `$AE17`), after the blast (`$BA81`), and by the map builder (`$BCCA`). A, B, DE, HL lost.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11 calls, 7,656 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 19 calls, 70,940 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 3,460 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1 call, 696 t-states own (0.00 %) |
| Called from | `GameTurnEnd`, `BuildMap` |
| Calls | `AddAToHL` |
| Reads | `$FD3A`-`$FD48` (`work space $FD3A+`); `$FD73`-`$FDFA` (`work space $FD73+`) |
| Writes | `$FD3A`-`$FD48` (`work space $FD3A+`) |

#### `CountRobots` (`$BB40`)

**PlayerRobots (`$FD41`) and EnemyRobots (`$FD49`): the live records of each side**

Counts the robot records whose +1 (the map cell's high byte) is not 0: slots 0-23 into PlayerRobots, slots 24-47 into EnemyRobots. The status panel shows them (the ROBOTS line; the enemy's factory (`$B86F`) builds better-armed robots as its count grows. Called after each birth and death of a robot.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 23 calls, 1,840 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 56 calls, 4,480 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 3 calls, 240 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 13 calls, 1,040 t-states own (0.00 %) |
| Called from | `PlayLoop`, `UpdateRobot`, `EnemyCommander` |
| Calls | `CountLiveRobots` |
| Writes | `$FD41`-`$FD49` (`work space $FD41+`) |

#### `CountLiveRobots` (`$BB50`)

**A = the live records among 24 robot records from HL (+1 not 0); HL moves past them**

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 46 calls, 53,130 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 112 calls, 128,869 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 6 calls, 6,960 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 26 calls, 30,095 t-states own (0.00 %) |
| Called from | `CountRobots` |
| Reads | `$DA01`-`$DCF1` (`work space $DA01+`) |

#### `GiveFactory` (`$BB61`)

**Factory A (0-23) changes hands: to the player (B = 0) or the enemy (B = 1); its flag moves**

Sets the factory's owner bits (`$BBB9`), removes the flag buildings at both sides of its roof (the cells x-2 and x+2 of row y-2) and puts the new owner's flag: type 7 (the player's) at x-2, type 8 (the enemy's) at x+2. The factory's own building (type 1-6 at x, y-2) stays.

Called by the capture tick (`$AE01`) when a robot has stood on the factory's door for 144 ticks.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11 calls, 1,881 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 19 calls, 3,572 t-states own (0.00 %) |
| Called from | `GameTurnEnd` |
| Calls | `SetBaseOwner`, `AddBuilding`, `RemoveBuilding` |

#### `GiveWarbase` (`$BB86`)

**Warbase A (0-3) changes hands: to the player (B = 0) or the enemy (B = 1)**

Sets the owner bits (`$BBB9`) and rebuilds the warbase's buildings on its pad row y-4: removes those at x-4, x and x+4, then for the player puts the landing pad (type 0, x) and the player's flag (type 7, x-4; for the enemy only its flag (type 8, x+4). So a captured warbase gives the player a second pad where the construction menu opens.

Called by the map builder (`$BCB3-$BCC7`: warbase 0 the player's, 1-3 the enemy's) and by the capture tick (`$ADF9`).

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 666 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2 calls, 368 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `SetBaseOwner`, `AddBuilding` (tail), `RemoveBuilding` |

#### `SetBaseOwner` (`$BBB9`)

**Base record A (HL = the table's +3 bytes): owner = the player (B = 0) or the enemy; HL = its door cell**

HL is `$FD73` (warbases) or `$FD87` (factories). Replaces bits 5-7 of the base's +3 with `$40` (the player) or `$20` (the enemy), which also clears the destroyed bit 7. Falls into BaseCell: HL = the map cell of the base's (x, y), its door.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11 calls, 1,606 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 19 calls, 2,757 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 581 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2 calls, 291 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` |
| Calls | `MapCell` (tail), `AddAToHL` |
| Reads | `$FD70`-`$FDFA` (`work space $FD70+`) |
| Writes | `$FD73`-`$FDFA` (`work space $FD73+`) |

#### `DestroyFactory` (`$BBD8`)

**Factory A (0-23) destroyed by a nuclear blast: buildings removed, blocks turned to debris**

Marks the factory destroyed (`$BC1C`), removes its three buildings on the roof row y-2 (the flags at x+2 and x-2 and the factory at x) and draws the factory's shape (ShapeFactory) again in debris: every block a random tile 6 or 7.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DestroyWarbase` (`$BBF9`)

**Warbase A (0-3) destroyed by a nuclear blast: buildings removed, blocks turned to debris**

Marks the warbase destroyed (`$BC1C`), removes the buildings at x-4, x and x+4 of its pad row y-4 and redraws ShapeWarbase in debris (tiles 6 / 7).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MarkBaseDestroyed` (`$BC1C`)

**Base A of the table HL (+3 bytes): +3 = `$80` (destroyed, no owner); HL = its door cell**

A = the base's index in its table, HL = the table's +3 bytes (Warbases+3 or Factories+3). Writes `$80` to the base's +3: destroyed, no owner, type bits 0; CountBases does not count it and no order's owner bits match it, so no order targets it again. The capture tick (CaptureLoop) does not test bit 7, though: from the code, a robot standing 144 turns on the door would give it an owner again (SetBaseOwner clears bit 7) with type 0, a warbase; never seen. Goes on into BaseCell: HL = the base's door cell, A = its row. Used by DestroyFactory and DestroyWarbase.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `AddBuilding` (`$BC43`)

**Add a building: map cell HL, type C (0 pad, 1-6 factory, 7 the player's flag, 8 the enemy's flag)**

Takes the first free record of Buildings (56 x 3 bytes: the cell, the type; a high byte 0 = free), writes the cell and the type, and sets bit 6 of the map cell. With all 56 records taken it does nothing. The buildings are what the ship stands on (their heights by type at `$B0C1`: pad 15, factories 21-22, flags 25) and where landing opens the construction menu (type 0).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11 calls, 2,849 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 19 calls, 37,506 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 29 calls, 23,142 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 3 calls, 483 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` (tail), `PlaceBases` |
| Reads | `$D8FE` (`work space $D8FE+`); `$DF35`-`$E0D4` (`work space $DF35+`); `$E3A0`-`$E527` (`work space $E3A0+`); `$E609`-`$E716` (`work space $E609+`); `$E837`-`$E891` (`work space $E837+`); `$EBE3`-`$EBE5` (`work space $EBE3+`); 4 more ranges |
| Writes | `$D8FE` (`work space $D8FE+`); `$DF35`-`$E0D4` (`work space $DF35+`); `$E3A0`-`$E527` (`work space $E3A0+`); `$E609`-`$E716` (`work space $E609+`); `$E837`-`$E891` (`work space $E837+`); `$EBE3`-`$EBE5` (`work space $EBE3+`); 4 more ranges |

#### `RemoveBuilding` (`$BC5D`)

**Remove the building on map cell HL, if any: its record freed, bit 6 of the cell cleared**

Keeps IY and BC. Uses FindBuilding.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 22 calls, 2,248 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 38 calls, 3,382 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 12 calls, 1,068 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 6 calls, 534 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` |
| Calls | `FindBuilding` |
| Reads | `$D8FE` (`work space $D8FE+`) |
| Writes | `$D8FE` (`work space $D8FE+`); `$FF0B` (`work space $FF0B+`) |

#### `BuildMap` (`$BC6F`)

**A new game's map: clear it, place the scenery and the bases of the level, give the warbases their owners**

Called once by the new game set-up (`$A68B`). Clears the map `$DD00-$FCFF` and the radar bitmap `$D800-$D8FF`, places the scenery lists (columns 0-255, then 256-511), then the two base lists (their records into `$FD70`: the warbases from `$FD70`, the factories from the address in IY), gives warbase 0 to the player and the next ones to the enemy, counts the bases, marks the radar for a rebuild and puts the ship on the map (`$B024`).

Five operands here are the level's: the four list addresses (`$BC8A`, `$BC92`, `$BCA2`, `$BCAA`) and the first factory record (`$BC9B`), with the enemy's warbase count at `$BCB7`. The image holds the built-in level's (SceneryWest `$BDA9`, SceneryEast `$BE4F`, BaseListWest `$BE5C`, BaseListEast `$BE60`, the factories from `$FD7A` after 2 warbases, 1 enemy warbase); LOAD MAP writes a NELEV file's tail over them (src/res/maps/README.md). The enemy's warbases are given by a DJNZ loop, warbase B for B = the count down to 1, where NE gave warbases 1-3 one by one; the 8 NOPs after it fill the rest of NE's code.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 177,974 t-states own (0.06 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1 call, 177,850 t-states own (0.03 %) |
| Called from | `StartGame` |
| Calls | `PutShipOnMap`, `CountBases`, `GiveWarbase`, `PlaceScenery`, `PlaceBases` |
| Reads | `$D800`-`$D8FE` (`work space $D800+`); `$DD00`-`$FCFE` (`work space $DD00+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$D800`-`$D8FF` (`work space $D800+`); `$DD00`-`$FCFF` (`work space $DD00+`); `$FD52` (`work space $FD52+`) |

#### `PlaceScenery` (`$BCD6`)

**Place a scenery list at HL (3-byte records: tile or shape, x low, y; 0 ends), D = x high byte**

A record with bit 7 clear is one 2 x 2 block of that tile (`$BD91`), with bit 7 set the shape of that index (`$BD61`). The cell is `$DD00` + `$200` * y + D * 256 + x.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 24,782 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2 calls, 10,826 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `DrawShape`, `PutBlock` |
| Reads | `$BDA9`-`$BF45` (`SceneryWest`, `SceneryEast`, `BaseListWest`, `BaseListEast` and 1 more) |

#### `PlaceBases` (`$BCF9`)

**Place a bases list at HL (3-byte records: type, x low, y; `$FF` ends), D = x high byte**

Type 0: a warbase. Its record goes to IX (the warbases' table) and ShapeWarbase is drawn from the cell. Type 1-6: a factory of that type. Its record goes to IY (the factories' table), ShapeFactory is drawn and the factory's building (that type) is added two rows up, at (x, y-2). A record: +0/+1 x, +2 y, +3 the type (the owner bits come later), +4 0 (the capture counter).

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 11,020 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2 calls, 708 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `AddBuilding`, `DrawShape` |
| Reads | `$BE5C`-`$BE63` (`BaseListWest`, `BaseListEast`); `$BF46`-`$BF9B` (`LevelSpare+226`) |
| Writes | `$FD70`-`$FDFB` (`work space $FD70+`) |

#### `DrawShape` (`$BD61`)

**Draw shape A (bit 7 ignored, the index into ShapeTable) from map cell HL**

A shape is a list of 3-byte steps: a tile (0 = none) drawn as a 2 x 2 block at the current cell, then the move to the next cell: columns (signed), rows (signed; a move of (0,0) ends after its tile. DrawRuins (`$BC27`) walks the same lists with debris tiles.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 90 calls, 63,165 t-states own (0.02 %) |
| Runs (CRITICAL with every upgrade, several game days) | 18 calls, 10,810 t-states own (0.00 %) |
| Called from | `PlaceScenery`, `PlaceBases` |
| Calls | `StepCell`, `PutBlock`, `TableWord` |
| Reads | `$BFB2`-`$C08C` (`ShapeWarbase`, `ShapeFactory`, `ShapeLowTiles`, `ShapeMidTiles` and 7 more) |

#### `StepCell` (`$BD7F`)

**HL += C columns (signed) and B rows (signed: H += 2 * B); DE kept**

HL a map cell, C the columns (signed), B the rows (signed). HL += C sign-extended, then H += 2 * B (a map row is `$200` bytes). DE kept, A lost. The move of one shape step for DrawShape and DrawRuins.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 477 calls, 41,905 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 78 calls, 6,800 t-states own (0.00 %) |
| Called from | `DrawShape` |

#### `PutBlock` (`$BD91`)

**A 2 x 2 block of tile A with its bottom left at map cell HL**

Writes the cells (x, y), (x+1, y), (x, y-1), (x+1, y-1): the first with the tile as it is, the other three with bit 5 set (the other parts of a block; the drawing and the blast take only the cell with bit 5 clear). Keeps HL and DE; BC is lost. Used by the map builder, the ruins, the blast and a dead robot's wreck (`$B133`).

| | |
| --- | --- |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 11 calls, 3,509 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 614 calls, 195,942 t-states own (0.07 %) |
| Runs (CRITICAL with every upgrade, several game days) | 137 calls, 43,703 t-states own (0.01 %) |
| Called from | `UpdateRobot`, `PlaceScenery`, `DrawShape` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$DD0C`-`$FC92` (`work space $DD0C+`); `$FCE0`-`$FCF8` (`work space $FCE0+`) |

### mainmenu

`src/game99/mainmenu.asm`

#### `ControlsOptionAttr` (`$C336`)

**The attribute for menu option C: cyan (`$45`) when it is the current Controls, else yellow (`$46`)**

C = the option's Controls value (1-3). Prints an inline attribute code: `$45` (cyan, bright) when Controls (`$D3E4`) is C, else `$46` (yellow, bright; the option text printed next takes it. Called by the three option entries before their text; A and the flags are lost.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ControlsOptionPlain` (`$C342`)

**ControlsOptionAttr's return, the option not chosen**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ControlsOptionChosen` (`$C349`)

**ControlsOptionAttr's return, the option chosen**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RedefineKeys` (`$C34A`)

**Redefine the eight keys: UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE**

Key 4 of the main menu. Clears the screen, prints REDEFINE KEYS, waits until no key is held, clears KeyTable and asks for each key in turn: PrintKeyPrompt prints "PRESS KEY FOR " and the name that follows the CALL, DefineKey waits for a key not yet taken and fills the KeyTable record whose third byte HL points at (the port's high byte, the bit mask, the key code) and prints the key. KeyTable's records 0-7 are PAUSE, ABORT, SAVE, FIRE, UP, DOWN, LEFT, RIGHT: Input bits 7 to 0. Waits for the last key's release and about 0.5 s, then back to the menu.

. PAUSE with each key's letter, and the menu came back.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RedefineKeysBody` (`$C36A`)

**Wait for no key, clear KeyTable, ask for UP**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadUpKey` (`$C388`)

**The key for UP (KeyTable record 4), then ask for DOWN**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadDownKey` (`$C397`)

**The key for DOWN (record 5), then ask for LEFT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadLeftKey` (`$C3A6`)

**The key for LEFT (record 6), then ask for RIGHT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadRightKey` (`$C3B5`)

**The key for RIGHT (record 7), then ask for FIRE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadFireKey` (`$C3C4`)

**The key for FIRE (record 3), a blank line, then ask for PAUSE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadPauseKey` (`$C3D6`)

**The key for PAUSE (record 0), then ask for ABORT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadAbortKey` (`$C3E5`)

**The key for ABORT (record 1), then the fixed SAVE record, back to the caller of RedefineKeys**

The last key the screen asks. Then KeyTable record 2 (Input bit 5, NE's SAVE) is written as `$BF`, `$01`, `$0D`: half row `$BFFE`, bit 0, ENTER; nothing reads Input bit 5 in play any more (PlayLoop `$A715`). Returns to the start-up menu (`$DA7A`) at once: no wait for the key's release, no pause.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintKeyPrompt` (`$C40C`)

**"PRESS KEY FOR " and then the key's name that follows the caller's CALL**

Called by the redefine-keys screen (`$C37F`, `$C38E`,... `$C3EB`) once for each of the eight keys, with the key's name (UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE) as an inline string after the CALL. It prints its own inline text (two new lines, attribute `$46`, "PRESS KEY FOR ", attribute `$45`), then jumps (not calls) to PrintInline at `$C424`: the return address on the stack is then the caller's, so PrintInline prints the caller's name string and returns past it. One prompt takes two screen rows.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintKeyPromptName` (`$C424`)

**print the caller's inline key name and return past it**

The tail of PrintKeyPrompt: a JP to PrintInline with the caller's return address on top of the stack, so the bytes after the caller's CALL `$C40C` (the name of the key to press) are printed and skipped.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DefineKey` (`$C427`)

**wait for a free key, store its port, mask and code into a KeyTable entry, print its name**

HL = the code byte (the third byte) of a KeyTable entry; the redefine screen passes the entries in the order UP (+`$0E`), DOWN (+`$11`), LEFT (+`$14`), RIGHT (+`$17`), FIRE (+`$0B`), PAUSE (+`$02`), ABORT (+`$05`), SAVE (+`$08`), so the entries map to the Input bits 3, 2, 1, 0, 4, 7, 6, 5 (ReadControls shifts entry 0 into bit 7). The screen cleared the whole table before the first key, so only keys already defined in this pass count as taken.

It prints two spaces and sets attribute `$46`, then waits with the ROM KEY-SCAN (`$028E`) for a key; the key value E (0-39, row index 0-7 in bits 0-2, bit position from bit 4 down in bits 3-5) is turned into a code through the ROM key table `$0205` (CAPS SHIFT gives `$E3`, the first byte past the table). A key whose code is already in one of the eight entries is refused and the wait goes on. Then it writes the code, the bit mask `$20` >> (E/8 + 1) and the port high byte (`$7F` for row 0 down to `$FE` for row 7) backwards into the entry, and prints the key's name: SYM SH, ENTER, CAPS SH, SPACE, or the code as a character.

Experiment: key 4 at the menu, then Q, Q, A, O, P, SPACE, ENTER, CAPS SHIFT, SYMBOL SHIFT left KeyTable = FB 01 51 / FD 01 41 / DF 02 4F / DF 01 50 for UP / DOWN / LEFT / RIGHT, 7F 01 20 for FIRE, BF 01 0D, FE 01 E3, 7F 02 0E for PAUSE / ABORT / SAVE; the second Q was refused.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DefineKeyScan` (`$C430`)

**wait for a key that no entry holds yet**

Continues DefineKey after its inline text. On exit the entry is filled and the name printed (the RET is the one after each name string, or the one in PrintCharKeep's path for a plain character).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `KeyNameSymShiftEnd` (`$C479`)

**a RET (`$C9`): PrintInline returns here and the routine ends**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CheckEnterKey` (`$C47A`)

**DefineKey: is the new key ENTER?**

Part of DefineKey (`$C427`): code `$0D` prints "ENTER" and returns through the RET placed after the string.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `KeyNameEnterEnd` (`$C487`)

**a RET (`$C9`) after the string**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CheckCapsShiftKey` (`$C488`)

**DefineKey: is the new key CAPS SHIFT?**

Part of DefineKey (`$C427`): code `$E3` (the byte after the ROM's key table, what CAPS SHIFT alone looks up) prints "CAPS SH".

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `KeyNameCapsShiftEnd` (`$C497`)

**a RET (`$C9`) after the string**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CheckSpaceKey` (`$C498`)

**DefineKey: SPACE prints its name, any other key prints its own character**

Part of DefineKey (`$C427`). A code other than `$20` goes to PrintCharKeep (print the character A) and returns from there.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DefineKeyDone` (`$C4A6`)

**RET: the end of DefineKey; also the target of the music's command 0**

The RET after the SPACE name. The two command tables of the menu music (`$C553`, `$C572`) point their command 0 here; command 0 never occurs in the tune, and it would not work: the dispatch leaves the voice pointer pushed, so this RET would return into the tune data.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### music

`src/game99/music.asm`

#### `MenuMusic` (`$C4A7`)

**play the menu tune until a number key is pressed**

Called once by the main menu (`$C19E`) after all keys are up. Saves SP in `$FD08`, installs MenuInterrupt as Handler and sets the music state: the bass voice reads the track `$C678` through HL' (frames left C'), the lead voice the track `$C702` through DE' (frames left B'), the drum the track `$C665` through HL (frames left C; C' = B' = C = 1, so the first interrupt reads the first event of each. Then it runs the tone loop for ever: the main set's D and E count each voice's period down.

The tone loop never returns: MenuInterrupt ends it by loading SP from `$FD08` when a number key is down, so the RET of the interrupt returns from MenuMusic to the menu (`$C1A1`), which then reads the key. The tune is 5120 frames (102.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassIdlePad` (`$C4C3`)

**tone loop: the time of a bass step without an edge**

The tone loop runs LeadStep and BassStep in turn, about 122 T a turn. A step whose counter has not run out takes this pad (PUSH AF, read Input and write it back unchanged, POP AF: 61 T with the DEC / JP) so both paths take about the same time, the pitch stays steady whatever the other voice does.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadStep` (`$C4CB`)

**tone loop: count the lead period down, at 0 a pulse**

D counts the lead voice's period in loop turns. At 0 it reloads D with the note's period (the operand `$C4D0`), sets the beeper (EAR and MIC, `$18`, or 0 when the voice is off: the operand `$C4D2`) for a pulse of 14 * width T (the operand `$C4D6` = period / 4, at most 63), then clears it. The voice's pitch is about 3.5 MHz / (122 + 3.5) / period: period `$7C` about 225 Hz, `$29` about 680 Hz.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadIdlePadTail` (`$C4E4`)

**the rest of the lead pad**

Write Input back and POP AF, then fall into BassStep.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassStep` (`$C4E8`)

**tone loop: count the bass period down, at 0 a pulse**

The bass voice's twin of LeadStep: E is its counter, the operands `$C4ED` (period), `$C4EF` (on / off) and `$C4F3` (pulse width) are written by BassNextEvent, BassOn and BassOff.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MenuInterrupt` (`$C4FD`)

**the interrupt handler of the menu**

The drum, the bass and lead note readers, the title colours; a number key ends MenuMusic. It returns to the tone loop of MenuMusic, or, with SP from SavedSP, to the menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassNextEvent` (`$C528`)

**read the bass voice's next event: a note, or a command**

HL' = the bass track position. A byte of 9 or more is a note: the byte is the period (written into `$C4ED`, and period / 4 into the pulse width `$C4F3`) and the next byte its length in frames (C'). A byte below 9 is a command (BassCommand). Called by MenuInterrupt when C' runs out, and jumped to again by every command handler, so commands take no time.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadNextEvent` (`$C53B`)

**read the lead voice's next event: a note, or a command**

The lead twin of BassNextEvent: DE' = the position, the note goes into `$C4D0` / `$C4D6` and its frames into B'.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassCmd2` (`$C559`)

**bass command 2 (entry): JP BassCall**

A table entry of BassCommandTable: command 2 calls a pattern.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassCmd3` (`$C55C`)

**bass command 3 (entry): JP SetDrumTrack**

A table entry: command 3 starts another drum track.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassCmd4` (`$C55F`)

**bass command 4 (entry): JP BassOn**

A table entry: command 4 turns the bass voice on.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassCmd5` (`$C562`)

**bass command 5 (entry): JP BassOff**

A table entry: command 5 turns the bass voice off (its notes keep their time, silent).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassCmd6` (`$C565`)

**bass command 6 (entry): JP BassReturn**

A table entry: command 6 ends a pattern.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadCommand` (`$C56E`)

**command A of the lead track: jump to entry A of the table after the CALL**

The lead twin of BassCommand. HL' (the bass position) is pushed so the handlers can pop it back.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadCmd2` (`$C578`)

**lead command 2 (entry): JP LeadCall**

A table entry of LeadCommandTable: command 2 calls a pattern.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadCmd4` (`$C57E`)

**lead command 4 (entry): JP LeadOn**

A table entry: command 4 turns the lead voice on.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadCmd5` (`$C581`)

**lead command 5 (entry): JP LeadOff**

A table entry: command 5 turns the lead voice off.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadCmd6` (`$C584`)

**lead command 6 (entry): JP LeadReturn**

A table entry: command 6 ends a pattern.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassCall` (`$C58D`)

**bass command 2 aa: play the pattern at aa, then go on after the command**

One level only: the return position (the address operand's high byte) is kept in `$FD54`; BassReturn resumes one byte past it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadCall` (`$C599`)

**lead command 2 aa: play the pattern at aa, then go on after the command**

The return position is kept in `$FD56`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassGoto` (`$C5A7`)

**bass command 1 aa: continue the track at aa (code: POP HL, read the word, JP BassNextEvent)**

POP HL; INC HL; LD A,(HL; INC HL; LD H,(HL; LD L,A; JP `$C528`. The bass track ends with 1 `$C678`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadGoto` (`$C5B0`)

**lead command 1 aa: continue the track at aa (code, run only when the tune loops)**

POP HL; EX DE,HL; INC HL; LD A,(HL; INC HL; LD H,(HL; LD L,A; EX DE,HL; JP `$C53B`. The lead track ends with 1 `$C702`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassReturn` (`$C5BB`)

**bass command 6: back from the pattern to the bass track**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadReturn` (`$C5C3`)

**lead command 6: back from the pattern to the lead track**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SetDrumTrack` (`$C5CC`)

**bass command 3 aa: the drum plays the track at aa from its next record**

Writes aa into the main set's HL, the drum position (the frames left of the current drum record are kept). Read through the bass voice's HL', so only the bass track may use it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrumStep` (`$C5DB`)

**play the next drum record (a short noise or sweep inside the interrupt)**

HL = the drum position, called by MenuInterrupt when the drum's frames (C) run out. A record is the frames until the next one and a kind: 0 a hiss meant as 96 bytes of ROM from `$08`xx sent to the beeper, about 1 ms (but DrumHissLoop never steps HL: one ROM byte, `$08` L, 96 times; The byte 1 in place of the frames is a goto: 1 aa. The tone loop stands still while a drum plays.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassOn` (`$C635`)

**bass command 4: the bass pulses sound again**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassOff` (`$C63F`)

**bass command 5: the bass pulses go silent (the notes still take their time)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadOn` (`$C648`)

**lead command 4: the lead pulses sound again**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadOff` (`$C652`)

**lead command 5: the lead pulses go silent**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MusicDispatch` (`$C65B`)

**jump to entry A of the 3-byte JP table that follows the caller's CALL**

Called with A = the command (below 9) from BassCommand / LeadCommand; it pops its own return address (the table) and jumps to table + 3 * A, so the handler returns to nobody: each jumps back to the voice's reader.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TitleColourCycle` (`$C820`)

**cycle the ink of the start-up menu's title rows 0-6, one colour every 2 frames**

Counts `$FD33` 0-15 each call; on even counts it paints the attributes of rows 0-6, columns 0-30 (`$5800-$58DE`, the column 31 of each row skipped) with BRIGHT, black paper and ink count / 2, so the ink runs through all 8 colours every 16 frames. The start-up menu calls it (`$D9A3`, `$DC39`) for its seven title rows; MenuInterrupt (`$C50B`) still holds a call that never runs.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 11,990 calls, 37,936,241 t-states own (13.54 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,074 calls, 3,398,054 t-states own (0.50 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 48,663 calls, 153,970,237 t-states own (22.05 %) |
| Calls | `AddAToHL` |
| Reads | `$FD33` (`work space $FD33+`) |
| Writes | `$5800`-`$58DE` (screen); `$FD33` (`work space $FD33+`) |

### construction

`src/game99/construction.asm`

#### `ConstructionMenu` (`$C849`)

**landing on the warbase pad at altitude 15: choose the parts (MenuCursor, MenuParts), START ROBOT or EXIT MENU**

Called by PlayLoop when the ship rests on the pad of our warbase (Altitude 15) and the door below is free. First looks for a free record among our slots 0-23 (`$DA00` + 16 x n, +`$01` = 0; with none it returns at once (IY = `$DB80`, enemy slot 24: the bug of PlayLoop's writes.

Otherwise IY = the free slot: the preview robot, and on START ROBOT the new one. Handler = StartInterrupt, so neither the frame count nor the radar runs; the menu loop runs no game turns, so the world stands still while the menu is open. ClearScreen, then the eight part pictures in column 16 from the bottom (bipod) to the top (electronics), each the second facing of the part's sprite cut to 24 lines and drawn upwards by DrawMaskedUp; the preview's frame attributes (`$46`, 4 x 9 cells from row 15, column 0; the texts (title, part names, EXIT / START, costs, the resource labels). Falls into ConstructionMenuSetup.

Returns (after LeaveConstructionMenu) with IY = the slot; PlayLoop then writes the start state. On EXIT MENU the slot stays free (+`$01` = 0, PlaceRobot not called), so those writes do no harm.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 28,539 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 53,523 t-states own (0.00 %) |
| Called from | `PlayLoop` |
| Calls | `ClearScreen`, `DrawMaskedUp`, `TableWord`, `AddAToHL`, `PrintInline` |
| Reads | `$6A24`-`$6A25` (`SprTracksXOdd`); `$6D40`-`$6D41` (`SprBipodXOdd`); `$7058`-`$7059` (`SprAntiGravOdd`); `$7354`-`$7355` (`SprCannonXmOdd`); `$77F4`-`$77F5` (`SprMissilesXOdd`); `$7C96`-`$7C97` (`SprPhasersXmOdd`); 4 more ranges |
| Writes | `$59E0`-`$5A03` (screen); `$5A20`-`$5A23` (screen); `$5A40`-`$5A43` (screen); `$5A60`-`$5A63` (screen); `$5A80`-`$5A83` (screen); `$5AA0`-`$5AA3` (screen); 3 more ranges |

#### `ConstructionMenuSetup` (`$C9E7`)

**reset the preview robot, copy the resources, cursor on BIPOD, nothing chosen**

Continues ConstructionMenu after its text...). Resources are copied to MenuResources, which the menu spends; MenuCursor = column 2 (the parts), row 0 (bipod; MenuParts = 0; ShowRobotDesign paints the part pictures (white when chosen) and draws the preview robot; the cursor is painted.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 2,177 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 4,043 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PaintMenuCursor`, `PrintMenuResources`, `ShowRobotDesign` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`) |
| Writes | `$DA08`-`$DA9D` (`work space $DA08+`); `$FD1F`-`$FD2F` (`work space $FD1F+`) |

#### `ConstructionMenuLoop` (`$CA0F`)

**wait for a control; fire acts on the cursor's item, a direction moves the cursor**

WaitKey until one of Input bits 0-4. Without fire: MoveMenuCursor (`$CB00`). With fire: column 0 EXIT MENU (`$CB8E`), column 1 START ROBOT (`$CB52`), column 2 toggles the part under the cursor.

Choosing a part: a part already chosen is taken back (RefundPart) and cleared. A chassis (bipod, tracks, anti-grav: rows 0-2) replaces the chassis already chosen, which is refunded first. A fourth weapon is refused: of cannon, missiles, phasers and nuclear at most three (`$78` never all set). The cost is paid from the part's own resource (PartCosts + 8) and what it lacks from the general resource; if the general one cannot pay the rest the part is refused (a replaced chassis stays refunded: the robot is left without one). Accepted: beep `$64`; refused or taken back: beep `$78`. Then it waits for fire up and pauses 10 frames.

Experiment (general 10, electronics 1, chassis 2): bipod 3 -> chassis 0, general 9; tracks 5 -> bipod refunded, chassis 0, general 7; cannon 2 -> general 5; tracks again -> taken back, chassis 2, general 8. With 99 of everything: missiles, phasers, then nuclear refused (MenuParts `$38`).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 64 calls, 258,199 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 115 calls, 466,819 t-states own (0.03 %) |
| Called from | `MenuPause` (tail) |
| Calls | `MoveMenuCursor` (tail), `MenuPause` (tail), `StartRobot` (tail), `PrintMenuResources`, `ShowRobotDesign`, `Beep`, `AddAToHL`, `WaitKey` |
| Reads | `$CAF0`-`$CAFF` (`PartCosts`); `$FD0C` (`work space $FD0C+`); `$FD1F`-`$FD2F` (`work space $FD1F+`) |
| Writes | `$FD21`-`$FD2F` (`work space $FD21+`) |

#### `RefundPart` (`$CAC1`)

**give back the cost of part E to MenuResources, the overflow to the general resource**

E = the part row. The cost goes back to the part's own resource; whatever lifts it above its value when the menu opened (Resources, 7 bytes below MenuResources) is what the general resource paid, so it is returned to the general one instead. Exact because each own resource has only one part in the menu at a time (one chassis, one of each weapon, electronics). Called by ConstructionMenuLoop (`$CA4C`, `$CAA4`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MoveMenuCursor` (`$CB00`)

**right / left change the column (0-2), down / up the part row (0-7) in column 2**

HL = MenuCursor (L the column, H the row), Input as WaitKey left it. Right adds 1 to the column, left subtracts 1; out of 0-2 nothing moves. Only without right / left: in the parts column up adds 1 to the row (towards ELECTRONICS, up the screen), down subtracts 1; out of 0-7 nothing moves. A move repaints the old item in `$45`, the new one in `$46` and clicks (beep `$14`; every press ends in the 10-frame pause (MenuPause).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 42 calls, 10,052 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 76 calls, 18,178 t-states own (0.00 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `PaintMenuCursor`, `Beep` |
| Reads | `$FD0C` (`work space $FD0C+`) |
| Writes | `$FD1F`-`$FD20` (`work space $FD1F+`) |

#### `MenuPause` (`$CB4A`)

**10 frames, then back to ConstructionMenuLoop**

The pause after every press (moves too; a shorter press falls into it and is lost, WALKTHROUGH 6.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 22 calls, 44,508,300 t-states own (2.03 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 39 calls, 79,984,604 t-states own (4.57 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `ConstructionMenuLoop` (tail) |
| Reads | `$CB4D` (`MenuPauseLoop+1`) |

#### `StartRobot` (`$CB52`)

**START ROBOT: needs a chassis and a weapon; spend the resources, place the robot at the warbase's door, leave**

Refused (back to the menu after the pause) without a chassis (MenuParts bits 0-2) or without a weapon (bits 3-6; electronics alone count as neither. Otherwise MenuResources become Resources, the free slot becomes a robot of ours (+`$0A` = 0) at column ShipX, row ShipY + 4 (PlaceRobot writes +0 to +4 and marks the map cell), +7 = MenuParts, and a rising chirp plays (Beep with `$50` down to `$14` by 5). Then LeaveConstructionMenu.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 8,323 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 15,457 t-states own (0.00 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `PlaceRobot`, `Beep`, `ClearViewBuffer`, `DrawPlayScreen` |
| Reads | `$FD0D`-`$FD0F` (`work space $FD0D+`); `$FD21`-`$FD2F` (`work space $FD21+`) |
| Writes | `$DA07`-`$DA9A` (`work space $DA07+`); `$FD22`-`$FD30` (`work space $FD22+`); `$FDFE`-`$FDFF` (`work space $FDFE+`) |

#### `PaintMenuCursor` (`$CBA9`)

**paint the item under MenuCursor with attribute C (`$46` the cursor, `$45` the rest)**

Column 0 / 1: two rows of 5 cells, EXIT MENU at rows 21-22 columns 4-8, START ROBOT columns 10-14. Column 2: the part's name, 11 cells from column 21 of row 22 - 3 * row (BIPOD row 22 up to ELECTRONICS row 1). Called by ConstructionMenuSetup and MoveMenuCursor.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 91 calls, 12,530 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 165 calls, 22,714 t-states own (0.00 %) |
| Called from | `ConstructionMenuSetup`, `MoveMenuCursor` |
| Calls | `FillAttributes` |
| Reads | `$FD1F`-`$FD20` (`work space $FD1F+`) |

#### `FillAttributes` (`$CBDB`)

**write C into B bytes from HL**

Also used by PaintMenuItem.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 430 calls, 97,050 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 796 calls, 179,433 t-states own (0.01 %) |
| Called from | `PaintMenuItem`, `PaintMenuCursor` |
| Writes | `$5835`-`$583F` (screen); `$5895`-`$589F` (screen); `$58F5`-`$591E` (screen); `$5955`-`$59DE` (screen); `$59F7`-`$5A3E` (screen); `$5A57`-`$5A5E` (screen); 2 more ranges |

#### `PrintMenuResources` (`$CBE0`)

**print MenuResources (two digits each) and their total**

The seven values at column 13: GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16 (PrintMenuResource, two digits: a value above 99 prints a wrong tens digit, e.g. 200 shows "D0"; the sum (HL) at row 18, column 12, three digits by PrintNumber3 (the tail `$CC03`).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 29 calls, 20,406 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 52 calls, 36,556 t-states own (0.00 %) |
| Called from | `ConstructionMenuSetup`, `ConstructionMenuLoop` |
| Calls | `PrintMenuResource`, `AddAToHL`, `PrintInline` |
| Reads | `$FD29`-`$FD2F` (`work space $FD29+`) |

#### `PrintMenuTotal` (`$CC03`)

**Construction menu: print the total of the costs (the tail of `$CBE0`)**

The tail of PrintMenuResources after the inline position (18,12): E = `$20` (blank leading zeros) and PrintNumber3 prints HL, the sum of the seven MenuResources (the TOTAL line, not the costs).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 29 calls, 493 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 52 calls, 884 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber3` (tail) |

#### `PrintMenuResource` (`$CC08`)

**Construction menu: print one resource value A at row C, column 13**

Called by `$CBE0` for each of the seven MenuResources (rows 9, 11-16). Patches the row byte of the position string after the CALL (`$CC11`), prints the position, then PrintMenuResourceValue prints A as two digits.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 203 calls, 9,135 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 364 calls, 16,399 t-states own (0.00 %) |
| Called from | `PrintMenuResources` |
| Calls | `PrintInline` |
| Writes | `$CC11` (`MenuResourcePos+1`) |

#### `PrintMenuResourceValue` (`$CC14`)

**Construction menu: print A as two digits, registers kept (the tail of `$CC08`)**

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 203 calls, 20,300 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 364 calls, 36,457 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2` |

#### `ShowRobotDesign` (`$CC1F`)

**Construction menu: highlight the chosen parts and draw the robot preview**

IY = the robot record being designed. Paints the attributes of the parts list (columns 16-19, three rows a part, 24 rows from the top): `$47` (bright white) for a part chosen in MenuParts, `$06` (yellow) otherwise, bit 7 (electronics) at the top. Then clears the view buffer, writes MenuParts to +`$07`, draws the robot stack into the buffer at map position row 10, column 7 (DrawRobot, base height +`$0D` = 0) and stores the stack's total height (the sum of the part heights `$D7B4`) in +`$09`: the height the ship lands on. Finally copies 4 bytes x 72 lines of the buffer from `$6168` (buffer row 82, column 0) to the screen at `$48E0` (character row 15, column 0). Called from `$C9E7` (7) and `$CA0F` (22) after each change of the parts.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 29 calls, 666,362 t-states own (0.03 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 52 calls, 1,194,824 t-states own (0.07 %) |
| Called from | `ConstructionMenuSetup`, `ConstructionMenuLoop` |
| Calls | `DrawRobot`, `ClearViewBuffer`, `NextScreenLine`, `AddAToHL` |
| Reads | `$6168`-`$667F` (system); `$6690`-`$6693` (system); `$66A4`-`$66A7` (system); `$66B8`-`$66BB` (system); `$66CC`-`$66CF` (system); `$66E0`-`$66E3` (system); 3 more ranges |
| Writes | `$48E0`-`$54E3` (screen); `$5500`-`$55C3` (screen); `$55E0`-`$55E3` (screen); `$5600`-`$56C3` (screen); `$56E0`-`$56E3` (screen); `$5700`-`$57C3` (screen); 10 more ranges |

#### `PlaceRobot` (`$CC7C`)

**Put robot IY at map column HL, row B: record, map bit 6, radar dot**

Writes +`$02`/+`$03` = HL (x), +`$04` = B (y), +`$00`/+`$01` = the map cell (MapCell) and sets the cell's bit 6 (an object to draw). Then toggles the robot's radar dot (ToggleRadarDot, side = bit 7 of +`$0A`: 0 the player's buffer `$D800`, 1 the enemy's `$D900`). The caller clears the old cell and toggles the old dot.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,807 calls, 2,539,246 t-states own (0.12 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 15,078 calls, 3,242,625 t-states own (0.19 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 28 calls, 6,020 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,431 calls, 522,722 t-states own (0.08 %) |
| Called from | `UpdateRobot` (tail), `RobotStep` (tail), `EnemyCommander`, `StartRobot` |
| Calls | `MapCell`, `ToggleRadarDot` (tail) |
| Reads | `$DA04`-`$DA9A` (`work space $DA04+`); `$DB84`-`$DCFA` (`work space $DB84+`); `$DF1D`-`$E067` (`work space $DF1D+`); `$E08C`-`$E09C` (`work space $E08C+`); `$E0CC`-`$E0E8` (`work space $E0CC+`); `$E122`-`$E149` (`work space $E122+`); 3 more ranges |
| Writes | `$DA00`-`$DA94` (`work space $DA00+`); `$DB80`-`$DCF4` (`work space $DB80+`); `$DF1D`-`$E067` (`work space $DF1D+`); `$E08C`-`$E09C` (`work space $E08C+`); `$E0CC`-`$E0E8` (`work space $E0CC+`); `$E122`-`$E149` (`work space $E122+`); 3 more ranges |

#### `ShipCell` (`$CCA0`)

**HL = the map cell under the ship (ShipX, ShipY)**

Falls into MapCell. Used by `$A62D`, `$B01D` (clear the ship's bit 7) and `$B024` (set it).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 6,426 calls, 186,373 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 5,817 calls, 168,712 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 117 calls, 3,393 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,754 calls, 79,866 t-states own (0.01 %) |
| Called from | `PlayLoop`, `LiftShipFromMap`, `PutShipOnMap` |
| Calls | `MapCell` |
| Reads | `$FD0D`-`$FD0F` (`work space $FD0D+`) |

#### `MapCell` (`$CCA6`)

**HL = the map cell of column HL, row A: `$DD00` + `$200`*A + HL**

H += 2*A + `$DD`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 42,879 calls, 1,243,852 t-states own (0.06 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 96,192 calls, 2,790,290 t-states own (0.16 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1,277 calls, 37,071 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 8,575 calls, 248,694 t-states own (0.04 %) |
| Called from | `GameTurnEnd`, `CheckShipMove`, `GroundUnderFootprint`, `MoveShot`, `EnemyCommander`, `SetBaseOwner` (tail), `PlaceRobot`, `ShipCell`, `DrawCellObject` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |

#### `Beep` (`$CCAC`)

**Beeper tone: 256 half-periods, A = the half-period delay (bigger is lower)**

B = A is the DJNZ delay of each half-period, C = 0 counts 256 speaker toggles (bit 4 of port `$FE`, border black). BC is kept. Used for menu clicks and confirmations: ListMenu (83), `$CB52` (98), `$CB00` (42), `$CA0F` (22), the robot menu `$A7CD`, `$ABC8`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 259 calls, 51,827,948 t-states own (2.36 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 476 calls, 94,761,140 t-states own (5.41 %) |
| Called from | `ShowOrderMiles`, `SetOrder`, `ListMenu`, `ConstructionMenuLoop`, `MoveMenuCursor`, `StartRobot` |
| Ports out | `$00FE`, `$10FE` |

### view

`src/game99/view.asm`

#### `DrawView` (`$CCBD`)

**Draw the isometric view: background, objects, copy to the screen**

DrawViewBackground clears the buffer `$5B00` and paints the corners outside the map, DrawMapObjects draws every block, building, robot, shot and the ship, CopyViewToScreen puts the 160x160 buffer on the screen. About 578000 T-states a call, 8.3 frames: the reason a turn is 10 frames.

Called by PlayLoop, the menu loops that keep the game going (ListMenu's turn `$AD1F`, DirectControlLoop, DistanceLoop, CombatFireShot), the nuclear blast (`$BA6D`) and DrawPlayScreen. No HALT before the copy: the screen may tear for a frame.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,231 calls, 98,257 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,107 calls, 92,763 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 40 calls, 1,750 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 919 calls, 40,436 t-states own (0.01 %) |
| Called from | `PlayLoop`, `ListMenu`, `DrawPlayScreen` |
| Calls | `DrawMapObjects`, `DrawViewBackground`, `CopyViewToScreen` (tail) |

#### `DrawMapObjects` (`$CCC6`)

**Draw the 32 x 16 cells of the view back to front into the view buffer**

Clears the deferred ship position `$FD11` and draws the ship's shadow (sprite 1, height 0) at the ship's view column (ShipX - ViewX) and row ShipY. Then walks the visible part of the map along diagonals: the diagonal x - y = 31 first down to x - y = -15, each from row 0 (x, y) to (x+15, y+15) or the right edge; cells left of the view (x < 0) and cells that are 0 are skipped, every other cell goes to DrawCell with HL = the cell, D = row, E = view column. The order is the painter's order of the projection (DrawSprite): a later cell is nearer the viewer.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,232 calls, 147,300,003 t-states own (6.72 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,108 calls, 138,801,704 t-states own (7.93 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 40 calls, 2,563,012 t-states own (0.91 %) |
| Runs (CRITICAL with every upgrade, several game days) | 919 calls, 60,637,869 t-states own (8.96 %) |
| Called from | `DrawView` |
| Calls | `DrawCell`, `DrawSprite`, `AddAToHL` |
| Reads | `$DD00`-`$EF23` (`work space $DD00+`); `$F100`-`$F123` (`work space $F100+`); `$F300`-`$F323` (`work space $F300+`); `$F500`-`$F523` (`work space $F500+`); `$F700`-`$F723` (`work space $F700+`); `$F900`-`$F923` (`work space $F900+`); 3 more ranges |
| Writes | `$CF3F` (`DrawSprite+18`); `$FD11`-`$FD12` (`work space $FD11+`) |

#### `DrawCell` (`$CD18`)

**Draw map cell HL (A = its byte) at view row D, column E**

Cell bits: 0-4 the block type, 5 the right half of a two-cell block (nothing drawn), 6 an object (building, robot or shot, or a robot / shot deferred to this cell), 7 the ship, or the ship deferred to this cell. A block (bit 5 clear, type not 0) is drawn as sprite = type at height 0. Bit 6 calls DrawCellObject. Bit 7 handles the ship: on the first bit-7 cell (`$FD11` = 0, the ship's own cell, set by `$B024`) it looks for the cell drawn last among the neighbouring blocks (FindLatestBlock) and the neighbouring objects (CheckObjectNeighbour at (x-1,y-1), (x-1,y), (x-1,y+1), (x,y+1), (x+1,y+1)). If that is the ship's cell the ship is drawn at once, otherwise bit 7 is set on that later cell and the ship's view position is kept in `$FD11`; when the walk reaches it, bit 7 is cleared again and the ship (sprite 0) is drawn at the kept position, at height Altitude. So the ship is never painted over by a neighbour.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 308,048 calls, 43,732,180 t-states own (1.99 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 245,013 calls, 34,912,170 t-states own (1.99 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 3,744 calls, 538,644 t-states own (0.19 %) |
| Runs (CRITICAL with every upgrade, several game days) | 122,227 calls, 17,300,589 t-states own (2.56 %) |
| Called from | `DrawMapObjects` |
| Calls | `CheckObjectNeighbour`, `FindLatestBlock`, `DrawCellObject`, `DrawSprite` |
| Reads | `$DD0C`-`$EF23` (`work space $DD0C+`); `$F10C`-`$F523` (`work space $F10C+`); `$F70C`-`$F923` (`work space $F70C+`); `$FB0C`-`$FB23` (`work space $FB0C+`); `$FD10`-`$FD12` (`work space $FD10+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CF3F` (`DrawSprite+18`); `$E512` (`work space $E512+`); `$E714`-`$EB16` (`work space $E714+`); `$ED12`-`$EF16` (`work space $ED12+`); `$F112`-`$F116` (`work space $F112+`); `$F312` (`work space $F312+`); 4 more ranges |

#### `CheckObjectNeighbour` (`$CD90`)

**Ship: an object at HL counts, and so do the blocks around it**

Used for the ship's neighbours: if HL has bit 6 (a robot, a building or a shot stands there, or one was deferred there) it competes (KeepLaterCell), and then the code falls into FindLatestBlock for the blocks around that object, because the ship flies above objects and their own neighbours can cover it too. In: HL the cell, DE the latest cell so far. Out: DE the latest. HL kept.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 11,160 calls, 257,745 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 10,530 calls, 242,878 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 195 calls, 4,485 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 4,595 calls, 105,685 t-states own (0.02 %) |
| Called from | `DrawCell` |
| Calls | `KeepLaterCell` |
| Reads | `$E311`-`$E314` (`work space $E311+`); `$E511`-`$E518` (`work space $E511+`); `$E711`-`$ED19` (`work space $E711+`); `$EF11`-`$FB17` (`work space $EF11+`) |

#### `FindLatestBlock` (`$CD96`)

**DE = the cell drawn last among DE and the blocks next to HL**

Checks the blocks (bit 5 clear, type not 0) at (x-1,y+1), (x,y+1) (both only when y+1 < 16), (x-1,y) and (x+1,y+1) (y+1 < 16) of cell HL with CheckBlockNeighbour; (x+1,y) is passed over (HL only goes through it). Those are the cells whose sprites can overlap a robot, a shot or the ship standing at HL. HL is kept. Used by DrawCell (the ship) and DrawMover (robots, shots).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 15,674 calls, 2,776,592 t-states own (0.13 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 5,550 calls, 1,000,363 t-states own (0.06 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 7,098 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 919 calls, 167,334 t-states own (0.02 %) |
| Called from | `DrawCell`, `DrawCellObject` |
| Calls | `CheckBlockNeighbour` |

#### `CheckBlockNeighbour` (`$CDB8`)

**A block at HL competes for the latest cell**

Bit 5 set (the right half of a block) or type 0 (empty): nothing. Otherwise falls into KeepLaterCell.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 57,265 calls, 2,164,889 t-states own (0.10 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 21,227 calls, 774,867 t-states own (0.04 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 156 calls, 10,101 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 3,676 calls, 154,430 t-states own (0.02 %) |
| Called from | `FindLatestBlock` |
| Calls | `KeepLaterCell` |
| Reads | `$DF1C`-`$DF22` (`work space $DF1C+`); `$E11C`-`$E124` (`work space $E11C+`); `$E321`-`$E323` (`work space $E321+`); `$E511`-`$E723` (`work space $E511+`); `$E90D`-`$FB24` (`work space $E90D+`) |

#### `KeepLaterCell` (`$CDBF`)

**DE = HL if map cell HL is drawn after cell DE**

The drawing order of DrawMapObjects: diagonals by falling x - y, along a diagonal by rising x. A = (yHL - yDE) + (xDE - xHL) (columns by the low bytes, rows from the high bytes: (H - `$DD`) / 2). A > 0: HL's diagonal is later; A = 0: same diagonal, later when xHL > xDE.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 543 calls, 50,915 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,470 calls, 140,087 t-states own (0.01 %) |
| Called from | `CheckObjectNeighbour`, `CheckBlockNeighbour` |

#### `FindRobot` (`$CDD8`)

**Z: IY the robot record standing on map cell HL, B = 48 - its slot (slots 0-23 the player's)**

Walks the 48 records of Robots (16 bytes: slots 0-23 the player's, 24-47 the enemy's) comparing the draw cell +`$00`/+`$01` with HL; a free slot has +`$01` = 0 and never matches a map address. Out: Z, IY = the record, B = 48 - slot; NZ when none. DE is kept. A robot deferred by DrawMover is found at the deferred cell, as the walk needs it. Called by DrawCellObject, PlayLoop (the robot under the ship), the captures, the shot hits, the blast and ObjectTop.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 47,236 calls, 117,931,419 t-states own (5.38 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 16,520 calls, 51,224,155 t-states own (2.93 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 95 calls, 401,997 t-states own (0.14 %) |
| Runs (CRITICAL with every upgrade, several game days) | 6,284 calls, 22,989,905 t-states own (3.40 %) |
| Called from | `PlayLoop`, `GameTurnEnd`, `ObjectTop`, `ScanLane`, `MoveShot`, `DrawCellObject` |
| Reads | `$DA00`-`$DCF1` (`work space $DA00+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |

#### `FindBuilding` (`$CDF5`)

**Z: IY the building record (Buildings) on map cell HL**

Walks the 56 records of Buildings (3 bytes: the map cell address, the type) comparing the cell with HL. Out: Z, IY = the record; NZ when none. DE is kept. Called by DrawCellObject, CheckWarbasePad (the construction menu's pad), ObjectTopBuilding and RemoveBuilding.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7,190 calls, 886,361 t-states own (0.04 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 5,167 calls, 12,433,155 t-states own (0.71 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 90 calls, 249,889 t-states own (0.09 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,844 calls, 274,474 t-states own (0.04 %) |
| Called from | `PlayLoop`, `ObjectTop`, `RemoveBuilding`, `DrawCellObject` |
| Reads | `$FEFF`-`$FFA6` (`work space $FEFF+`) |

#### `DrawCellObject` (`$CE12`)

**Draw the object of map cell HL (bit 6): a robot, a building or a shot**

A robot whose +`$00`/+`$01` is HL goes to DrawMover. A building record goes to its sprite: BuildingSprites[type] at height BuildingHeights[type]. Otherwise the five shot records at `$D7D3` (9 bytes: +`$00`/+`$01` cell, +`$02`/+`$03` x, +`$04` y, +`$05` direction, +`$06` range, +`$07` weapon 1-3, +`$08` height) are searched; a match goes to DrawMover. Nothing found: nothing drawn. the shot path is read from the code and from the shot records at frame 20000).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 17,904 calls, 5,020,035 t-states own (0.23 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 7,659 calls, 1,901,459 t-states own (0.11 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 78 calls, 17,940 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,838 calls, 422,778 t-states own (0.06 %) |
| Called from | `DrawCell` |
| Calls | `MapCell`, `FindLatestBlock`, `FindRobot`, `FindBuilding`, `DrawMoverSprite` (tail), `DrawRobot` (tail), `DrawSprite`, `AddAToHL` |
| Reads | `$CE56`-`$CE66` (`BuildingSprites`, `BuildingHeights`); `$D7D3`-`$D7F2` (`work space $D7D3+`); `$DA02`-`$DA94` (`work space $DA02+`); `$DBD2`-`$DBD4` (`work space $DBD2+`); `$DCE2`-`$DCE4` (`work space $DCE2+`); `$F122` (`work space $F122+`); 4 more ranges |
| Writes | `$CF3F` (`DrawSprite+18`); `$DA00`-`$DA01` (`work space $DA00+`); `$DA30`-`$DA91` (`work space $DA30+`); `$F122` (`work space $F122+`); `$F520`-`$F522` (`work space $F520+`); `$F922` (`work space $F922+`) |

#### `DrawMover` (`$CE68`)

**Draw robot or shot IY found at cell HL (view row D, column E), after the blocks that overlap it**

Robots and shots keep their real position in +`$02`/+`$03` (x) and +`$04` (y) and in +`$00`/+`$01` the cell the walk draws them at. At the real cell FindLatestBlock looks for a later neighbouring block; if there is one, the object is moved there (bit 6 set on it, +`$00`/+`$01` = it) and nothing is drawn yet. When the walk reaches the deferred cell, +`$00`/+`$01` is set back to the real cell, the deferred cell's bit 6 is cleared and the view position is walked back from the deferred cell to the real one (x first, then y), and DrawMoverSprite draws the object there. So a robot is drawn after (over) every block whose sprite overlaps it. 18 were deferred (each drawn later at the walked-back position), 1449 drawn at once. No shot reached here: see DrawCellObject.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawMoverSprite` (`$CEC3`)

**Draw IY: a robot record (`$DA00` up) as a stack of parts, a shot as one sprite**

Records at `$D800` and up are robots: DrawRobot. A shot (records at `$D7D3`) is sprite `$2B` + 2 * weapon (+`$07`: 1 cannon, 2 missiles, 3 phasers) + 1 when it flies down or up (+`$05` = 4 or 8), at height +`$08`: `$2D`/`$2E` a cannon shell, `$2F`/`$30` a missile trail, `$31`/`$32` a phaser beam (the sprite pictures in start.bin).

| | |
| --- | --- |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 3,058 calls, 142,096 t-states own (0.01 %) |
| Called from | `DrawCellObject` (tail) |
| Calls | `DrawRobot` (tail), `DrawSprite` |
| Reads | `$D7F3`-`$D7F6` (`work space $D7F3+`) |
| Writes | `$CF3F` (`DrawSprite+18`) |

#### `DrawRobot` (`$CEE8`)

**Draw robot IY at view row D, column E: its parts bottom up**

Height starts at +`$0D` (the ground under the robot, 0 in the construction menu; for each bit of the parts mask +`$07` from bit 0 (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics) DrawRobotPart draws the part and raises the height. Called by DrawMoverSprite and ShowRobotDesign.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 13,471 calls, 4,761,261 t-states own (0.22 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 3,102 calls, 1,094,658 t-states own (0.06 %) |
| Called from | `ShowRobotDesign`, `DrawCellObject` (tail), `DrawMoverSprite` (tail) |
| Calls | `DrawRobotPart` |
| Reads | `$DA07`-`$DA9D` (`work space $DA07+`); `$DBD7`-`$DBDD` (`work space $DBD7+`); `$DCE7`-`$DCED` (`work space $DCE7+`) |
| Writes | `$CF3F` (`DrawSprite+18`) |

#### `DrawRobotPart` (`$CEFD`)

**Draw part 8 - B of robot IY facing +`$08`, then raise the height**

Sprite = `$16` + the parts table `$D6C8`[4 * part + direction], direction = the number of the lowest set bit of +`$08` (0 right, 1 left, 2 down, 3 up, the Input bits). After drawing, the height (`$CF3F`) grows by the part's height `$D7B4`[part]: bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 41,088 calls, 12,431,147 t-states own (0.57 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 9,221 calls, 2,667,894 t-states own (0.15 %) |
| Called from | `DrawRobot` |
| Calls | `DrawSprite`, `AddAToHL` |
| Reads | `$CF3F` (`DrawSprite+18`); `$D6C8`-`$D6E7` (`PartSpriteTable`); `$D7B4`-`$D7BB` (`PartHeights`); `$DA08`-`$DA98` (`work space $DA08+`); `$DBD8` (`work space $DBD8+`); `$DCE8` (`work space $DCE8+`) |
| Writes | `$CF3F` (`DrawSprite+18`) |

#### `DrawSprite` (`$CF2D`)

**Draw sprite A at view row D, column E, height (`$CF3F`) into the view buffer**

The isometric projection: the half-byte column L = 2E + D - 24, the pixel row of the sprite's bottom line H = 8D + 100 - 4E - height. So a step along x moves 8 pixels right and 4 up, a step along y 4 right and 8 down. The sprite table `$D6E8` holds two words a sprite (A*2 + 1 for an odd half-byte column: the image shifted by 4 pixels). A sprite: rows, width in bytes, then for each row bottom up (mask, pixels) byte pairs; drawn by AND mask, OR pixels into the 20-byte rows of the buffer `$5B00`, upwards. Clipping: right of column 19 or a bottom line past row `$E1`: nothing; bottom lines `$A0-$E1` skip the rows below the buffer; a negative column skips the left bytes of each row (`$CFAF`), a sprite past column 19 the right bytes; the top stops at `$5B00`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 123,647 calls, 1,093,600,748 t-states own (49.86 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 78,338 calls, 610,930,215 t-states own (34.91 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1,093 calls, 10,786,226 t-states own (3.85 %) |
| Runs (CRITICAL with every upgrade, several game days) | 34,003 calls, 305,565,307 t-states own (45.15 %) |
| Called from | `DrawMapObjects`, `DrawCell`, `DrawCellObject`, `DrawMoverSprite`, `DrawRobotPart` |
| Calls | `TableWord`, `AddAToHL` |
| Reads | `$5B08`-`$6779` (system); `$6980`-`$8965` (`SprTracksX`, `SprTracksXRows`, `SprTracksXOdd`, `SprTracksXOddRows` and 92 more); `$8CDE`-`$8D45` (`SprShotPhaserXOdd`, `SprShotPhaserXOddRows`); `$8E3A`-`$92F9` (`SprShip`, `SprShipRows`, `SprShipOdd`, `SprShipOddRows` and 11 more); `$9914`-`$9D9B` (`SprBlockLow`, `SprBlockLowRows`, `SprBlockLowOdd`, `SprBlockLowOddRows` and 4 more); `$9EF6`-`$9F8D` (`SprBouldersB`, `SprBouldersBRows`); 2 more ranges |
| Writes | `$5B08`-`$5FC7` (system); `$5FDA`-`$6169` (system); `$6190`-`$66FC` (system); `$670E`-`$6724` (system); `$6736`-`$6738` (system); `$674B`-`$674C` (system); 1 more ranges |

#### `DrawViewBackground` (`$CFD7`)

**Clear the view buffer and paint the corners outside the map**

ClearViewBuffer, FillViewCorner (the solid top left corner), then the diagonal edge strips from `$D6A8`: 6 strips down and left from buffer row 0, column 10 (the top left edge), 3 from row 136, column 18 and 4 of the other diagonal (`$D6B8`) from row 128, column 18 (the bottom right corner, the blue area that DrawPlayScreen colours `$41` / `$71`). Called by DrawView and once by `$A62D`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,231 calls, 354,947 t-states own (0.02 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,107 calls, 335,271 t-states own (0.02 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 41 calls, 6,519 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 920 calls, 146,318 t-states own (0.02 %) |
| Called from | `StartGame`, `DrawView` |
| Calls | `ClearViewBuffer`, `FillViewCorner`, `DrawEdgeStrips` (tail) |

#### `ClearViewBuffer` (`$CFFE`)

**Zero the view buffer `$5B00-$677F` (20 bytes x 160 rows)**

Pushes HL = 0 with SP at `$6780` (198 x 16 bytes, SP kept in `$FD08`), then clears the first 32 bytes with LDIR. Called by DrawViewBackground, ShowRobotDesign and `$CB52`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,267 calls, 47,080,565 t-states own (2.15 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,172 calls, 45,095,218 t-states own (2.58 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 41 calls, 851,072 t-states own (0.30 %) |
| Runs (CRITICAL with every upgrade, several game days) | 920 calls, 19,100,973 t-states own (2.82 %) |
| Called from | `StartRobot`, `ShowRobotDesign`, `DrawViewBackground` |
| Reads | `$5B00`-`$5B1E` (system); `$FD08`-`$FD09` (`work space $FD08+`) |
| Writes | `$5B00`-`$5B1F` (system); `$5B3C`-`$5B3D` (system); `$5B70`-`$5B8B` (system); `$5BA4`-`$5BB9` (system); `$5BCC`-`$5BDD` (system); `$5BF0`-`$5C13` (system); 30 more ranges |

#### `FillViewCorner` (`$D026`)

**Fill the top left corner of the view buffer: a staircase of 5 bands**

5 bands of 8 rows; the first fills 10 bytes of each row, each next band 2 fewer (10, 8, 6, 4, 2). The fill and skip counts are the operands `$D038` and `$D041`, reset to 10 at the start and moved by 2 after each band.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,232 calls, 21,388,621 t-states own (0.98 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,107 calls, 20,198,039 t-states own (1.15 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 41 calls, 392,818 t-states own (0.14 %) |
| Runs (CRITICAL with every upgrade, several game days) | 920 calls, 8,817,001 t-states own (1.30 %) |
| Called from | `DrawViewBackground` |
| Calls | `AddAToHL` |
| Reads | `$D038`-`$D041` (`CornerRowLoop+2`, `CornerByteLoop`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$5B00`-`$5D95` (system); `$5DA8`-`$5DA9` (system); `$5DBC`-`$5DBD` (system); `$5DD0`-`$5DD1` (system); `$5DE4`-`$5DE5` (system); `$5DF8`-`$5DF9` (system); 2 more ranges |

#### `DrawEdgeStrips` (`$D057`)

**Copy B strips of 8 rows x 2 bytes (pattern HL) into the buffer, each 8 rows down and 2 bytes left**

The diagonal edge of the map in the view. The patterns are at `$D6A8` (ink on the left: `$FFFF`, `$FFFC`,..., `$C000`) and `$D6B8` (ink on the right).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 6,696 calls, 19,538,312 t-states own (0.89 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 6,324 calls, 18,453,093 t-states own (1.05 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 123 calls, 358,848 t-states own (0.13 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,760 calls, 8,052,478 t-states own (1.19 %) |
| Called from | `DrawViewBackground` (tail) |
| Reads | `$D6A8`-`$D6C7` (`ViewEdgeA`, `ViewEdgeB`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$5B0A`-`$5EAD` (system); `$6512`-`$6717` (system); `$6728`-`$672B` (system); `$673C`-`$673F` (system); `$6750`-`$6753` (system) |

#### `CopyViewToScreen` (`$D071`)

**Copy the view buffer to the screen at character row 1, column 1 (20 x 20 characters)**

160 lines of 20 bytes with unrolled LDI, the destination stepped through the screen's thirds.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,231 calls, 137,731,781 t-states own (6.28 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,107 calls, 130,077,410 t-states own (7.43 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 2,407,704 t-states own (0.86 %) |
| Runs (CRITICAL with every upgrade, several game days) | 919 calls, 56,734,985 t-states own (8.38 %) |
| Called from | `DrawView` (tail) |
| Reads | `$5B00`-`$677F` (system); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4021`-`$5194` (screen); `$5201`-`$5294` (screen); `$5301`-`$5394` (screen); `$5401`-`$5494` (screen); `$5501`-`$5594` (screen); `$5601`-`$5694` (screen); 1 more ranges |

### screen

`src/game99/screen.asm`

#### `ClearScreen` (`$D0B9`)

**Clear the screen (pixels and attributes to 0) and make the border black**

Clears the 6912 bytes of pixels and attributes from `$4000` and sets the border black (and the speaker off) with OUT (`$FE`),0. Called by DrawPlayScreen, MainMenu `$C100`, RedefineKeys `$C34A` and OpenConstructionMenu `$C865`. Changes A, BC, DE, HL.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 14 calls, 2,033,206 t-states own (0.09 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 26 calls, 3,775,954 t-states own (0.22 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 16 calls, 2,323,380 t-states own (0.83 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2 calls, 290,446 t-states own (0.04 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 3 calls, 435,651 t-states own (0.06 %) |
| Called from | `PieceRoomA56A`, `LoadMapRoom`, `ConstructionMenu`, `DrawPlayScreen` |
| Reads | `$4000`-`$5AFE` (screen); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4000`-`$5AFF` (screen) |
| Ports out | `$00FE` |

#### `ClearScreenFill` (`$D0C7`)

**ClearScreen's LDIR**

no code jumps here.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawPlayScreen` (`$D0CA`)

**Draw the whole play screen: the view, its frame, the colours, DAY / TIME / RADAR**

ClearScreen and DrawView, then the frame of the view (22 x 22 characters from (0,0): double lines at the top and bottom, `$81` lines at the sides), the attributes: `$07` everywhere, `$3D` (cyan on white) on the frame, `$30` (yellow paper) in the view, `$31` and `$01` (blue) in its bottom right corner, the area past the map's edge. None of them is BRIGHT; the status texts too have lost their BRIGHT bit (`$D1C6`, `$D1DD`, `$D1EF`, `$D207`, `$D24E`, `$D25B`). Prints PlayScreenText. Called at the start of play (`$A68E`) and after the construction menu (`$CB52`).

PlayScreenText ends the code: PrintInline returns into ShowStatusPanel, so the panel's labels come with every play screen; the numbers come with the next UpdateStatusPanel. The radar appears at the next frame's PlayInterrupt.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 7 calls, 333,817 t-states own (0.02 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 13 calls, 620,011 t-states own (0.04 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 47,699 t-states own (0.02 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1 call, 47,699 t-states own (0.01 %) |
| Called from | `StartGame`, `StartRobot` |
| Calls | `DrawView`, `ClearScreen`, `NextScreenLine`, `AddAToHL`, `PrintInline` |
| Reads | `$4000`-`$4014` (screen); `$4701`-`$4713` (screen); `$50A1`-`$50B3` (screen); `$57A0`-`$57B4` (screen); `$5800`-`$5AFE` (screen); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4000`-`$50B5` (screen); `$5100`-`$51A0` (screen); `$51B5` (screen); `$5200`-`$52A0` (screen); `$52B5` (screen); `$5300`-`$53A0` (screen); 9 more ranges |

#### `ShowStatusPanel` (`$D1E5`)

**Clear the right panel and print the status labels**

ClearPanel, then StatusPanelText. Called when the robot menu ends (CloseRobotMenu `$A819`) and at the game's end (GameStop `$AF07`). DrawPlayScreen falls into it after its own string, so every play screen gets the labels. The numbers come from UpdateStatusPanel.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 14 calls, 476 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 26 calls, 884 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 34 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1 call, 34 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `RobotMenuChoose`, `PrintInline` |
| Calls | `ClearPanel`, `PrintInline` |

#### `UpdateStatusPanel` (`$D293`)

**Print the panel's numbers: resources, then both sides' buildings and robots**

Skipped while PanelBusy (`$FD39`) is not 0 (the robot menu owns the panel). Prints the seven Resources at (17-23, 30) as two digits, attribute `$4E`; the enemy's building counts EnemyBuildings `$FD42` (by type 0-6) at (6-12, 22) and robots EnemyRobotCount `$FD49` at (13,22; the player's counts PlayerBuildings `$FD3A` at (6-12, 31) and robots PlayerRobotCount `$FD41` at (13,30), attribute `$47`. Called after the counts change (a capture `$AE1A`, the day's production `$AE4A`, a robot removed `$B150`, an enemy robot built `$B91C`, the blast `$BA84`) and from CheckWarbasePad (`$A70A`) after a robot is built.

The four parts are each a CALL PrintInline with a position string and the code after it (the entries below). PrintNewline comes before each resource, so the first lands on row 17.

[Animation: `UpdateStatusPanel` at work](img/routines/UpdateStatusPanel.gif)

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 55 calls, 2,123 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 108 calls, 4,168 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 156 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 17 calls, 663 t-states own (0.00 %) |
| Called from | `PlayLoop`, `GameTurnEnd`, `DailyProduction`, `UpdateRobot`, `EnemyCommander`, `PrintInline` |
| Calls | `PrintInline` |
| Reads | `$FD39` (`work space $FD39+`) |

#### `PrintResourceValues` (`$D2A3`)

**The seven resource values, each on the next line (the tail of `$D293`)**

Seven lines from Resources (`$FD22`: general, electronics, nuclear, phasers, missiles, cannon, chassis), each PrintNewline then PrintNumber2: rows 17-23, column 30, blank leading zero. Falls into the next position string.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 53 calls, 47,227 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 104 calls, 92,579 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 3,560 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 17 calls, 15,130 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2`, `PrintInline`, `PrintNewline` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`) |

#### `PrintInsgCounts` (`$D2C1`)

**The enemy's building counts and its robots (the tail of `$D293`)**

The enemy's seven building counts EnemyBuildings (`$FD42`: warbases, then the six factory kinds) as single digits down column 22, rows 6-12; then its robots EnemyRobotCount (`$FD49`, the byte after them) at (13,22) with a leading zero, over the space before ROBOTS. Falls into the player's position string.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 53 calls, 2,915 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 104 calls, 5,720 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 220 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 17 calls, 935 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintDigitColumn`, `PrintInline` |
| Reads | `$FD49` (`work space $FD49+`) |

#### `PrintHumnCounts` (`$D2D2`)

**The player's building counts (the tail of `$D293`)**

The player's seven building counts PlayerBuildings (`$FD3A`) down column 31, rows 6-12. HL ends at PlayerRobotCount. Falls into the next position string.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 53 calls, 2,332 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 104 calls, 4,576 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 176 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 17 calls, 748 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintDigitColumn`, `PrintInline` |

#### `PrintHumnRobots` (`$D2DF`)

**The player's robots `$FD41`, two digits (the tail of `$D293`)**

PlayerRobotCount (`$FD41`, HL from PrintHumnCounts) as two digits with a leading zero; the JP returns from UpdateStatusPanel.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 53 calls, 901 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 104 calls, 1,768 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 68 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 17 calls, 289 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2Zero` (tail) |
| Reads | `$FD41` (`work space $FD41+`) |

#### `PrintDigitColumn` (`$D2E3`)

**Print seven bytes from HL as single digits, one under the other**

Each byte as "0" + n (a count of 10 or more would print ":" and the characters after it; never seen, a side has at most 4 warbases), then PrintNewline: the same column one row down. HL ends past the seventh byte (the robot count that follows). Used by PrintInsgCounts and PrintHumnCounts.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 106 calls, 82,169 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 208 calls, 161,257 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 8 calls, 6,200 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 34 calls, 26,350 t-states own (0.00 %) |
| Called from | `PrintInsgCounts`, `PrintHumnCounts` |
| Calls | `PrintCharKeep`, `PrintNewline` |
| Reads | `$FD3A`-`$FD48` (`work space $FD3A+`) |

#### `ClearPanel` (`$D2F6`)

**Blank the right panel: 22 lines of 10 spaces from (2,22) in attribute 0**

Called by ShowStatusPanel and by the robot menus (RobotMenuShow `$A732`, CloseRobotMenu `$A812`, OrdersMenu `$A971`, OrderMove `$AA15`, TargetMenu `$AAD2`, CaptureMenu `$AB4E`, CombatMenu `$AC00`) and GameStop (`$AF04`) before they print. Attribute 0 (black on black) hides the area at once; rows 22-23 of the panel (STRENGTH) are cleared too.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 49 calls, 833 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 91 calls, 1,547 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 17 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1 call, 17 t-states own (0.00 %) |
| Called from | `RobotMenuShow`, `ShowOrderMiles`, `RobotMenuChoose`, `OrdersMenu`, `TargetMenu`, `CaptureMenu`, `ShowStatusPanel` |
| Calls | `PrintInline` |

#### `ClearPanelLines` (`$D301`)

**22 lines (the tail of ClearPanel)**

B = 22: rows 2-23. B survives each PrintInline: it works in the alternate registers.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 49 calls, 343 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 91 calls, 637 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 7 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1 call, 7 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ClearPanelLine` |

#### `ClearPanelLine` (`$D303`)

**Print 10 spaces and a newline**

One CALL PrintInline with PanelBlankLine; the code goes on at ClearPanelNext.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 1,078 calls, 18,326 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,002 calls, 34,034 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 22 calls, 374 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 22 calls, 374 t-states own (0.00 %) |
| Called from | `ClearPanelLines`, `ClearPanelNext` (tail) |
| Calls | `PrintInline` |

#### `ClearPanelNext` (`$D312`)

**The next of the 22 lines**

DJNZ back to ClearPanelLine for the 22 rows, then the return from ClearPanel.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 1,077 calls, 14,259 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,000 calls, 26,500 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 22 calls, 291 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 22 calls, 291 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ClearPanelLine` (tail) |

#### `DrawMaskedUp` (`$D315`)

**Draw a masked image on the screen: C lines of B (mask, pixel) pairs from HL to DE, going up**

Each line ANDs the mask and ORs the pixels; DE moves one screen line up (PrevScreenLine) after each. The sprite format of DrawSprite without its header: the caller (PartIconDraw `$C895`, the construction menu's part pictures, 56 calls) passes B = bytes a line, C = lines, HL = the first pair of the bottom line, DE = the screen address of the bottom line. Out: HL past the picture. No clipping.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 56 calls, 393,386 t-states own (0.02 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 104 calls, 730,574 t-states own (0.04 %) |
| Called from | `ConstructionMenu` |
| Calls | `PrevScreenLine` |
| Reads | `$4030`-`$4112` (screen); `$4130`-`$4212` (screen); `$4230`-`$4312` (screen); `$4330`-`$4412` (screen); `$4430`-`$4512` (screen); `$4530`-`$4712` (screen); 8 more ranges |
| Writes | `$4030`-`$4212` (screen); `$4230`-`$4312` (screen); `$4330`-`$4412` (screen); `$4430`-`$4512` (screen); `$4530`-`$4612` (screen); `$4630`-`$4712` (screen); 1 more ranges |

#### `NextScreenLine` (`$D32A`)

**HL = the screen address one pixel line down**

The Spectrum's screen order: the line inside a character row is bits 0-2 of H, the character row bits 5-7 of L, the third bits 3-4 of H. Keeps everything but A and the flags. Used by ShowRadar, the frame of DrawPlayScreen, the big characters of PrintBigChar and ShowRobotDesign's copy (`$CC74`).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 475,330 calls, 14,117,633 t-states own (0.64 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 365,233 calls, 10,854,385 t-states own (0.62 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 25,628 calls, 782,916 t-states own (0.28 %) |
| Runs (CRITICAL with every upgrade, several game days) | 150,004 calls, 4,456,677 t-states own (0.66 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 6,208 calls, 191,331 t-states own (0.03 %) |
| Called from | `ShowRobotDesign`, `DrawPlayScreen`, `PrintControl`, `PrintBigChar`, `ShowRadar` |

#### `PrevScreenLine` (`$D339`)

**DE = the screen address one pixel line up**

The reverse of NextScreenLine on DE: used only by DrawMaskedUp, which draws from the bottom line up. Keeps everything but A and the flags.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 1,323 calls, 40,138 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,457 calls, 74,542 t-states own (0.00 %) |
| Called from | `DrawMaskedUp` |

#### `TableWord` (`$D348`)

**HL = the word at HL + 2*A**

The sprite table lookup of DrawSprite, also ConstructionMenu (PartIconLoop `$C881`) and DrawShape (`$BD67`). A is an index 0-127 (A*2 must fit a byte). Changes A.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 123,703 calls, 6,805,964 t-states own (0.31 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 78,442 calls, 4,315,469 t-states own (0.25 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1,183 calls, 65,065 t-states own (0.02 %) |
| Runs (CRITICAL with every upgrade, several game days) | 34,021 calls, 1,871,820 t-states own (0.28 %) |
| Called from | `DrawShape`, `ConstructionMenu`, `DrawSprite` |
| Calls | `AddAToHL` |
| Reads | `$BF9C`-`$BFB1` (`ShapeTable`); `$D6E8`-`$D705` (`SpriteTable`); `$D724`-`$D7AF` (`SpriteTable+60`) |

#### `AddAToHL` (`$D351`)

**HL += A**

A changed to the new H; BC, DE kept. Used everywhere a table is indexed by a byte (about 50 call sites).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 471,849 calls, 15,575,900 t-states own (0.71 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 327,353 calls, 10,806,278 t-states own (0.62 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 49,380 calls, 1,629,819 t-states own (0.58 %) |
| Runs (CRITICAL with every upgrade, several game days) | 122,213 calls, 4,034,392 t-states own (0.60 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 171,365 calls, 5,656,098 t-states own (0.81 %) |
| Called from | `PaintMenuItem`, `TerrainTop`, `ObjectTop`, `SteerByOrder`, `SetStepDelay`, `EnemyCommander`, `CountBases`, `SetBaseOwner`, `TitleColourCycle`, `ConstructionMenu`, `ConstructionMenuLoop`, `PrintMenuResources`, `ShowRobotDesign`, `DrawMapObjects`, `DrawCellObject`, `DrawRobotPart`, `DrawSprite`, `FillViewCorner`, `DrawPlayScreen`, `TableWord`, `PrintControl`, `PrintBigChar` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |

#### `Random` (`$D358`)

**A = a pseudo-random byte**

A 32-bit shift register at RandomSeed `$FD00-$FD03` (big end first, seeded `$39`,`$30`,`$39`,`$30` by Start): shifted left once, the new bit = bit 3 XOR bit 6 of `$FD00`. Then the byte at the index the previous call used (kept in the operand `$D371`) gives, by its low 2 bits, the new index, and A = the byte there. HL is kept; A and the flags change. The image holds 3 in that operand (the value it had when the block was saved) and Start does not reset it, so the first call after the start reads `$FD03`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 19,764 calls, 3,835,451 t-states own (0.17 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 50,711 calls, 9,838,732 t-states own (0.56 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 172 calls, 33,368 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 5,715 calls, 1,108,824 t-states own (0.16 %) |
| Called from | `GameTurn`, `UpdateRobot`, `RobotStep`, `SteerByOrder`, `EnemyCommander`, `SoundEffect` |
| Reads | `$FD00`-`$FD03` (`work space $FD00+`) |
| Writes | `$D371` (`Random+25`); `$FD00`-`$FD03` (`work space $FD00+`) |

### controls

`src/game99/controls.asm`

#### `WaitKey` (`$D37C`)

**ReadControls; while key 1 (Input bit 7) is held, the pause: wait for another key**

In: nothing. Out: A = Input (also in Input `$FD0C`; the flags of the last OR A. When the pause key (bit 7) is held it loops in PauseLoop until some other control is pressed with the pause key up, then falls into ReadControls again: the control that ended the pause is this turn's input. Changes A, BC, HL. Called once a turn by PlayLoop, DirectControlLoop, DistanceLoop, ListMenu, WaitRelease, GameOverKey, RobotDirectControl and ConstructionMenuLoop.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 9,079 calls, 290,604 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 14,509 calls, 464,440 t-states own (0.03 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 1,248 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 29,376 t-states own (0.00 %) |
| Called from | `PlayLoop`, `ListMenu`, `WaitRelease`, `ConstructionMenuLoop` |
| Calls | `ReadControls` |

#### `ReadControls` (`$D38A`)

**Input from the redefinable keys (KeyTable) or the joystick the menu chose (Controls)**

The eight keys of KeyTable are rotated into C one by one (RL C, starting from C = 1: after the eighth the 1 drops into the carry and ends the loop), entry 0 ending in bit 7. Then the joystick by Controls (`$D3E4`): 2 Kempston (port `$1F`, bits 0-4 already right, left, down, up, fire), 3 Interface 2 (port `$EFFE`, keys 6-0, inverted and reordered), else none. Out: A = Input = joystick OR keys. Changes B, C, HL.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 9,079 calls, 6,402,329 t-states own (0.29 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 14,509 calls, 10,231,144 t-states own (0.58 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 39 calls, 27,144 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 638,928 t-states own (0.09 %) |
| Called from | `WaitKey` |
| Reads | `$D3CC`-`$D3E4` (`KeyTable`, `Controls`) |
| Writes | `$FD0C` (`work space $FD0C+`) |
| Ports in | `$001F`, `$7FFE`, `$DFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### print

`src/game99/print.asm`

#### `PrintNumber2` (`$D3E5`)

**Print A (0-99) as two digits, a leading zero blank**

In: A. HL = A, E = `$20`, then PrintTensUnits: a space for a leading zero. Used for the resources (PrintResourceValues), the construction menu values and the miles of ADVANCE / RETREAT. A value of 100 or more would print a tens "digit" above 9 (":" and on; the game caps every resource at 99.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 574 calls, 17,239 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,092 calls, 32,760 t-states own (0.00 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 28 calls, 840 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 119 calls, 3,570 t-states own (0.00 %) |
| Called from | `PrintMenuResourceValue`, `PrintResourceValues` |
| Calls | `PrintTensUnits` (tail) |

#### `PrintNumber2Zero` (`$D3EC`)

**Print A (0-99) as two digits with a leading zero**

The clock (`$AD90`, 6828 calls: "20.20") and the robot counts of the panel.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 4,501 calls, 135,049 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 4,292 calls, 128,817 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 80 calls, 2,400 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,853 calls, 55,590 t-states own (0.01 %) |
| Called from | `GameTurnEnd`, `PrintHumnRobots` (tail) |
| Calls | `PrintTensUnits` (tail) |

#### `PrintNumber5` (`$D3F3`)

**Print HL as five digits, leading zeros blank**

Used by `$AD90` for the day number ("DAY: 4"). Falls into PrintNumber3.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 2,224 calls, 135,702 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 2,094 calls, 127,734 t-states own (0.01 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 38 calls, 3,344 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 918 calls, 80,803 t-states own (0.01 %) |
| Called from | `GameTurnEnd` |
| Calls | `PrintDigit` |

#### `PrintNumber3` (`$D401`)

**Print HL as three digits (E = `$20`: leading zeros blank, else printed)**

The operand `$FF9C` is -100 (the source writes it so with @isub; as a label it would read Buildings+155, a false symbol). Used by PrintMenuTotal and `$A833`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 139 calls, 63,820 t-states own (0.00 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 259 calls, 63,531 t-states own (0.00 %) |
| Called from | `ShowStrengthValue`, `PrintMenuTotal` (tail) |
| Calls | `PrintDigit` |

#### `PrintTensUnits` (`$D407`)

**Print the tens and the units of HL**

HL = the value (0-99, else the tens "digit" runs past 9: 200 prints as "D0"), E = the leading-zero flag. The tens by PrintDigit, the units always printed. The tail of PrintNumber2, PrintNumber2Zero, PrintNumber3 and PrintNumber5.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 5,075 calls, 357,119 t-states own (0.02 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 5,384 calls, 371,547 t-states own (0.02 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 108 calls, 7,008 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,972 calls, 138,758 t-states own (0.02 %) |
| Called from | `PrintNumber2` (tail), `PrintNumber2Zero` (tail) |
| Calls | `PrintDigit`, `PrintCharKeep` (tail) |

#### `PrintDigit` (`$D413`)

**Print the digit of HL for the power -BC; HL keeps the rest**

Counts how often BC (a negative power of 10) can be added. A zero while E = `$20` prints a space and keeps E; any printed digit increments E, so later zeros print as 0.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 14,249 calls, 1,260,521 t-states own (0.06 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 14,278 calls, 1,257,180 t-states own (0.07 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 260 calls, 22,969 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 5,644 calls, 497,924 t-states own (0.07 %) |
| Called from | `PrintNumber5`, `PrintNumber3`, `PrintTensUnits` |
| Calls | `PrintCharKeep` |

#### `PrintCharKeep` (`$D427`)

**PrintChar A with BC, DE, HL kept (EXX around)**

PrintChar in the alternate registers: the caller's BC, DE, HL are kept (the number printers keep HL, E and the loop counters in them). A and the flags change.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 24,763 calls, 867,009 t-states own (0.04 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 25,772 calls, 902,324 t-states own (0.05 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 500 calls, 17,500 t-states own (0.01 %) |
| Runs (CRITICAL with every upgrade, several game days) | 9,690 calls, 339,245 t-states own (0.05 %) |
| Called from | `ShowStrengthValue` (tail), `GameTurnEnd`, `PrintDigitColumn`, `PrintTensUnits` (tail), `PrintDigit` |
| Calls | `PrintChar` |

#### `PrintInline` (`$D42D`)

**print the text after the CALL: 0 ends, 1 Y X a position, 2 A an attribute, 3 the next line, 4 N a setting, else a character**

In: the string after the CALL. Pops the return address, takes a byte, pushes the address one byte on, until a 0: the RET then lands after the string. Each byte goes to PrintControl (codes 1-4 and characters). Works in the alternate set (EXX at both ends), so the caller's BC, DE, HL are kept; A and the flags change. Callers also end in it with JP (PrintKeyPrompt `$C40C`), so the bytes after their own CALL are the string. About 60 call sites: every screen and panel text.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 3,975 calls, 2,320,634 t-states own (0.11 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 5,356 calls, 3,724,853 t-states own (0.21 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 108 calls, 174,381 t-states own (0.06 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,013 calls, 333,806 t-states own (0.05 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 17 calls, 45,051 t-states own (0.01 %) |
| Called from | `RobotMenuShow`, `ShowOrder`, `ShowStrength`, `OrdersMenu`, `TargetMenu`, `CaptureMenu`, `GameTurn`, `LoadMapRoom`, `ConstructionMenu`, `PrintMenuResources`, `PrintMenuResource`, `DrawPlayScreen`, `ShowStatusPanel`, `UpdateStatusPanel`, `PrintResourceValues`, `PrintInsgCounts`, `PrintHumnCounts`, `ClearPanel`, `ClearPanelLine` |
| Calls | `ShowOrder`, `ShowOrderMiles`, `ShowStrengthValue`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose`, `GameTurnEnd`, `LoadMapRoom`, `ConstructionMenuSetup`, `PrintMenuTotal`, `PrintMenuResourceValue`, `ShowStatusPanel`, `UpdateStatusPanel`, `PrintResourceValues`, `PrintInsgCounts`, `PrintHumnCounts`, `PrintHumnRobots`, `ClearPanelLines`, `ClearPanelNext`, `PrintControl` |
| Reads | `$A738`-`$A832` (`RobotMenuText`, `ShowOrder`, `OrderLineHead`, `OrderLine` and 6 more); `$A977`-`$A9EB` (`OrdersMenuText`); `$AAD8`-`$ABB8` (`DestroyMenuText`, `DestroyMenuChoose`, `CaptureMenu`, `CaptureMenuText`); `$AD88`-`$AD8F` (`ClockPos`); `$C216`-`$C21D` (`LoadMapRoom+25`); `$C8BE`-`$C9E6` (`ConstructionTitleText`, `PartNamesText`, `ExitStartText`, `PartCostsText` and 1 more); 6 more ranges |

#### `PrintControl` (`$D43C`)

**PrintInline's byte A: control codes 1-4 or a character**

1 Y X: the position (row Y, column X, kept in `$FD32`/`$FD31`). 2 A: the attribute `$FD13`. 3: newline (the next row, the same column). 4 N: the size, high nibble the height in character rows (`$FD16`), low nibble the width in bytes (`$FD17`; 0 = normal. A character goes to PrintChar for size 0, else to PrintBigChar. The operands are read through the caller's return address on the stack, two levels up.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 27,699 calls, 2,859,456 t-states own (0.13 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 45,400 calls, 4,466,223 t-states own (0.26 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2,257 calls, 228,917 t-states own (0.08 %) |
| Runs (CRITICAL with every upgrade, several game days) | 3,579 calls, 465,304 t-states own (0.07 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 593 calls, 726,100 t-states own (0.10 %) |
| Called from | `PrintInline` |
| Calls | `NextScreenLine`, `AddAToHL`, `PrintNewline` (tail), `SetPrintPos` (tail), `PrintChar` (tail), `PrintBigChar` (tail) |
| Reads | `$6780`-`$6787` (`Font`); `$67B8`-`$67BF` (`Font+56`); `$67E8`-`$67EF` (`Font+104`); `$6800`-`$6857` (`Font+128`); `$6888`-`$6937` (`Font+264`); `$6948`-`$6957` (`Font+456`); 13 more ranges |
| Writes | `$4000`-`$50DC` (screen); `$5121`-`$51DC` (screen); `$5221`-`$52DC` (screen); `$5321`-`$53DC` (screen); `$5421`-`$54DC` (screen); `$5521`-`$55DC` (screen); 11 more ranges |

#### `PrintNewline` (`$D470`)

**The next print row, the same column**

PrintRow + 1, then SetPrintPos. Reached by code 3 inside PrintInline and called directly by the number printers' callers (GameTurnEnd `$AD96`, ResourceValueLoop, PrintDigitColumn, ReadFireKey `$C3CA`). Changes A, BC, HL.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 4,996 calls, 269,879 t-states own (0.01 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 7,359 calls, 397,443 t-states own (0.02 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 161 calls, 8,694 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1,314 calls, 70,994 t-states own (0.01 %) |
| Called from | `GameTurnEnd`, `PrintResourceValues`, `PrintDigitColumn`, `PrintControl` (tail) |
| Calls | `SetPrintPos` (tail) |
| Reads | `$FD31`-`$FD32` (`work space $FD31+`) |
| Writes | `$FD31`-`$FD32` (`work space $FD31+`) |

#### `SetPrintPos` (`$D493`)

**Print position: B = row, C = column -> `$FD04` the screen address, `$FD14` the attribute address**

In: B = row 0-23, C = column 0-31. PrintAddr = `$4000` + (B AND `$18`) * 256 + (B AND 7) * 32 + C, the top line of the character cell; PrintAttrAddr = `$5800` + 32 * B + C. Changes A, HL. Used by SetPosition and PrintNewline.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 8,255 calls, 1,065,218 t-states own (0.05 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 11,388 calls, 1,469,451 t-states own (0.08 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 380 calls, 49,020 t-states own (0.02 %) |
| Runs (CRITICAL with every upgrade, several game days) | 2,331 calls, 300,756 t-states own (0.04 %) |
| Called from | `PrintControl` (tail), `PrintNewline` (tail) |
| Writes | `$FD04`-`$FD15` (`work space $FD04+`) |

#### `PrintChar` (`$D4B1`)

**Print character A at the print position in the print attribute, advance one column**

The font is at `$6680` + 8*code (`$6780` for the space, right after the view buffer). 8 lines into (`$FD04`), the attribute (`$FD13`) into (`$FD14`), both advanced.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 42,234 calls, 21,038,650 t-states own (0.96 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 58,251 calls, 29,017,054 t-states own (1.66 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 872 calls, 434,332 t-states own (0.16 %) |
| Runs (CRITICAL with every upgrade, several game days) | 10,088 calls, 5,025,249 t-states own (0.74 %) |
| Called from | `PrintCharKeep`, `PrintControl` (tail) |
| Reads | `$6780`-`$6787` (`Font`); `$67A8`-`$67BF` (`Font+40`); `$67E8`-`$6857` (`Font+104`); `$6878`-`$694F` (`Font+248`); `$FD04`-`$FD15` (`work space $FD04+`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4016`-`$57FF` (screen); `$5816`-`$5AFF` (screen); `$FD04`-`$FD15` (`work space $FD04+`) |

#### `PrintBigChar` (`$D4DA`)

**Print character A scaled: each line repeated `$FD16` times, width 1 or 2 bytes (`$FD17`)**

Width 1: each glyph line written `$FD16` times (2: a character two rows high, "RADAR:"). Width 2: each glyph byte doubled to 16 bits. Then the screen address moves on by the width and a block of width x height attribute cells gets `$FD13`.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 161 calls, 412,840 t-states own (0.02 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 299 calls, 766,787 t-states own (0.04 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1,471 calls, 2,379,796 t-states own (0.85 %) |
| Runs (CRITICAL with every upgrade, several game days) | 220 calls, 289,031 t-states own (0.04 %) |
| Called from | `PrintControl` (tail) |
| Calls | `NextScreenLine`, `AddAToHL` |
| Reads | `$6780`-`$6787` (`Font`); `$67B8`-`$67BF` (`Font+56`); `$67E8`-`$67EF` (`Font+104`); `$6800`-`$6857` (`Font+128`); `$6888`-`$6937` (`Font+264`); `$6948`-`$6957` (`Font+456`); 2 more ranges |
| Writes | `$4000`-`$52E5` (screen); `$5321`-`$53E5` (screen); `$5421`-`$54E5` (screen); `$5521`-`$55E5` (screen); `$5621`-`$56E5` (screen); `$5721`-`$57E5` (screen); 7 more ranges |

### interrupts

`src/game99/interrupts.asm`

#### `PlayInterrupt` (`$D566`)

**the interrupt handler of play, one a frame**

Installed by EnterPlay (`$A694`) and when the construction menu ends (`$CBA2`). Keeps AF, BC, DE, HL (not IX, IY, the alternate set: the routines it calls do not use them). TurnFrames + 1 (TurnPace `$AE1D` waits for 10, then zeroes it; RadarPhase toggled, ShowRadar with RadarOwn / `$4D` on phase 0, RadarEnemy / `$4E` on phase 1; SoundFx not 0: counted on (a tone ends at `$80`, a noise when it wraps to 0) and SoundEffect plays this frame's step. Ends in StartInterrupt's EI; RET.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 29,275 calls, 6,411,086 t-states own (0.29 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 22,031 calls, 4,917,556 t-states own (0.28 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 381 calls, 83,242 t-states own (0.03 %) |
| Runs (CRITICAL with every upgrade, several game days) | 9,180 calls, 2,010,218 t-states own (0.30 %) |
| Calls | `StartInterrupt`, `ShowRadar`, `SoundEffect` |
| Reads | `$FD1A` (`work space $FD1A+`); `$FD34` (`work space $FD34+`); `$FD53` (`work space $FD53+`) |
| Writes | `$FD1A` (`work space $FD1A+`); `$FD34` (`work space $FD34+`); `$FD53` (`work space $FD53+`) |

#### `StartInterrupt` (`$D59C`)

**the interrupt handler while the start-up runs**

Also the end of PlayInterrupt. Installed alone by Start (FillVectorTable `$A614`), GameStop (`$AF0A`), SaveGame (`$C28D`), the end of MenuMusic (`$C520`) and OpenConstructionMenu (`$C85E`): no frame counting, no radar, so the world stands while it is in place.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 30,602 calls, 428,428 t-states own (0.02 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 24,416 calls, 341,824 t-states own (0.02 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 405 calls, 5,670 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 9,200 calls, 128,800 t-states own (0.02 %) |
| Called from | `PlayInterrupt` |

#### `ShowRadar` (`$D59E`)

**Show radar picture HL (16 lines x 16 bytes) at (22,6) in attribute C**

The interrupt alternates the two pictures `$D800` (terrain + the player's robots, attribute `$4D`) and `$D900` (terrain + the enemy's robots, `$4E`) every frame, so the terrain stays and each side's robots blink in their colour. The attributes are rows 22 and 23, columns 6-21.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 29,274 calls, 199,156,734 t-states own (9.08 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 22,030 calls, 149,875,507 t-states own (8.56 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 380 calls, 2,585,140 t-states own (0.92 %) |
| Runs (CRITICAL with every upgrade, several game days) | 9,179 calls, 62,444,737 t-states own (9.23 %) |
| Called from | `PlayInterrupt` |
| Calls | `NextScreenLine`, `FillAttr16` |
| Reads | `$D800`-`$D9FF` (`work space $D800+`) |
| Writes | `$50C6`-`$50F5` (screen); `$51C6`-`$51F5` (screen); `$52C6`-`$52F5` (screen); `$53C6`-`$53F5` (screen); `$54C6`-`$54F5` (screen); `$55C6`-`$55F5` (screen); 2 more ranges |

#### `FillAttr16` (`$D5BD`)

**Write C into 16 bytes from HL**

In: HL, C. Out: HL past the 16 bytes, B = 0. The tail of ShowRadar (rows 22 and 23 of the radar).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 58,550 calls, 25,059,400 t-states own (1.14 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 44,062 calls, 18,858,536 t-states own (1.08 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 760 calls, 325,280 t-states own (0.12 %) |
| Runs (CRITICAL with every upgrade, several game days) | 18,358 calls, 7,857,224 t-states own (1.16 %) |
| Called from | `ShowRadar` |
| Writes | `$5AC6`-`$5AD5` (screen); `$5AE6`-`$5AF5` (screen) |

#### `SoundEffect` (`$D5C4`)

**The interrupt's sound: A = `$FD53` (1-`$7F` a falling tone, `$C8-$FF` noise)**

Called by PlayInterrupt with A = SoundFx after its step, the flags of A set (never 0 here). A positive (2-`$7F`, a shot fired: SoundFx 1 counted on): C = 500 / (A+2) + 1 pulses, B = A the delay between them; each pulse's level is bit 4 of the next ROM byte from `$0000` (a rough noise), so the bursts get sparser and lower as A counts up each frame: a falling sweep over 126 frames, 3.2 ms at A = 2, about 2 ms from A = 40. A negative (`$C8-$FF`): 30 random speaker levels (Random): the crackle of a hit.

The shot code sets 1 when a shot is fired (`$B709`), `$FC` a miss (3 frames), `$FA` a hit (5 frames), `$C8` a robot destroyed (55 frames, the explosion)... `$16`, then `$FA-$FF`. Changes A, BC, DE, HL. The border stays black (bits 0-2 of the OUT are 0).

| | |
| --- | --- |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 1,725 calls, 7,233,850 t-states own (0.41 %) |
| Called from | `PlayInterrupt` |
| Calls | `Random` |
| Ports out | `$00FE`, `$10FE` |

#### `BuildRadar` (`$D5F8`)

**Build both radar pictures for the 128 columns from `$FD1C`**

Each map cell of the window is one pixel: set when its block type is `$0F` or more (the tall blocks). Copies the terrain picture to `$D900`, then puts the dot of every robot in play (+`$01` not 0, except the one under direct control, +`$0A` = 2) into its side's picture (ToggleRadarDot). Called by `$B029` when the ship moves the window (`$FD52`;

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 142,587 t-states own (0.05 %) |
| Runs (CRITICAL with every upgrade, several game days) | 1 call, 142,587 t-states own (0.02 %) |
| Called from | `PutShipOnMap` |
| Reads | `$D800`-`$D8FF` (`work space $D800+`); `$DA01`-`$EF7F` (`work space $DA01+`); `$F100`-`$F17F` (`work space $F100+`); `$F300`-`$F37F` (`work space $F300+`); `$F500`-`$F57F` (`work space $F500+`); `$F700`-`$F77F` (`work space $F700+`); 4 more ranges |
| Writes | `$D800`-`$D9FF` (`work space $D800+`) |

#### `ToggleRadarDot` (`$D65A`)

**XOR a 2x2 dot at map column HL, row C into radar picture B (0 player, 1 enemy)**

The dot covers (x, y), (x+1, y) and the line above. Nothing outside the window (RadarDotAddress returns past this routine). XOR: the same call removes the dot again, so the robot code toggles the old position before PlaceRobot toggles the new one.

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 25,815 calls, 1,773,365 t-states own (0.08 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 32,228 calls, 2,105,723 t-states own (0.12 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 92 calls, 8,194 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 5,767 calls, 254,137 t-states own (0.04 %) |
| Called from | `BlinkShipDot` (tail), `UpdateRobot`, `RobotStep`, `PlaceRobot` (tail) |
| Calls | `RadarDotAddress` |
| Reads | `$D804`-`$D9FF` (`work space $D804+`) |
| Writes | `$D804`-`$D9FF` (`work space $D804+`) |

#### `RadarDotAddress` (`$D67D`)

**HL = the radar byte of column HL, row C in picture B, A = the pixel mask**

Column x - `$FD1C` must be 0-126, else it pops the return address and returns from ToggleRadarDot. Address = `$D800` + `$100`*B + 16*y + (x-`$FD1C`)/8, mask = `$80` >> ((x-`$FD1C`) AND 7).

| | |
| --- | --- |
| Runs (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)) | 25,815 calls, 3,218,329 t-states own (0.15 %) |
| Runs (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)) | 32,228 calls, 4,182,262 t-states own (0.24 %) |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 92 calls, 11,675 t-states own (0.00 %) |
| Runs (CRITICAL with every upgrade, several game days) | 5,767 calls, 559,441 t-states own (0.08 %) |
| Called from | `ToggleRadarDot` |
| Reads | `$FD1C`-`$FD1D` (`work space $FD1C+`) |

## The '98 game (`src/game98`)

Recordings: `work/stage2/game98/deep` (the bot's '98 game, 30284 frames, 9 game days), `work/stage2/game98/play` (r98 4500-5903: the menu, START GAME, play), `work/stage2/game98/key5menu` (the menu, LOAD NEW LEVEL, the menu again, START).

| Module | Entries | Code entries |
| --- | --- | --- |
| `font` | `$6780`-`$697F` | 0 of 1 |
| `sprites` | `$6980`-`$A5D5` | 0 of 179 |
| `zsenemy` | `$A5D6`-`$A5FF` | 2 of 2 |
| `start` | `$A600`-`$A71F` | 4 of 4 |
| `robotmenu` | `$A720`-`$AD61` | 26 of 48 |
| `gameturn` | `$AD62`-`$AF10` | 11 of 14 |
| `ship` | `$AF11`-`$B0C9` | 12 of 13 |
| `world` | `$B0CA`-`$B7F3` | 34 of 36 |
| `enemy` | `$B7F4`-`$BB08` | 4 of 4 |
| `bases` | `$BB09`-`$BDA8` | 17 of 17 |
| `level` | `$BDA9`-`$C0FF` | 0 of 17 |
| `mainmenu` | `$C100`-`$C4A6` | 36 of 60 |
| `music` | `$C4A7`-`$C848` | 32 of 50 |
| `construction` | `$C849`-`$CCBC` | 18 of 26 |
| `view` | `$CCBD`-`$D0B8` | 20 of 22 |
| `screen` | `$D0B9`-`$D37B` | 20 of 28 |
| `controls` | `$D37C`-`$D3E4` | 2 of 4 |
| `print` | `$D3E5`-`$D565` | 13 of 13 |
| `interrupts` | `$D566`-`$D6A7` | 8 of 8 |
| `tables` | `$D6A8`-`$D7D2` | 0 of 6 |
| `worldstate` | `$D7D3`-`$D87F` | 0 of 2 |

### zsenemy

`src/game98/zsenemy.asm`

#### `UpgradeEnemyRobots` (`$A5D6`)

**every enemy record: +`$07` = (+`$07` AND `$78`) OR `$84`: anti-grav and electronics on, bipod and tracks off**

All 24 enemy slots, live or free (free slots have +`$01` = 0 and are not checked): the weapons (bits 3-6) are kept, the chassis becomes anti-grav (bit 2; bits 0 and 1 cleared) and electronics (bit 7) are added. The step delay's column is the lowest part bit (SetStepDelay), so every enemy robot then steps like an anti-grav one (StepDelays: 3, 3, 4 turns on flat, low, high ground, against a bipod's 6, 8, 9), and electronics give it the longer sight in its facing direction (12 cells, SpotEnemies) and one more shot step. A free slot's +`$07` is overwritten anyway when EnemyCommander builds a robot there, so a robot built during the day keeps its own parts until the next midnight. IY is kept (PUSH / POP). Called by DailyProduction (`$AE44`), once a game day: 9 runs (216 records) over the 9 midnights of this part's deep recording; at its end (day 9, 08:25) all 24 enemy records were live and each had bits 2 and 7 set, none a bipod or tracks.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9 calls, 17,884 t-states own (0.00 %) |
| Called from | `DailyProduction` |
| Reads | `$DB87`-`$DCF7` (`work space $DB87+`) |
| Writes | `$DB87`-`$DCF7` (`work space $DB87+`) |

#### `FillEnemyResources` (`$A5F2`)

**EnemyResources (`$FD4A-$FD50`) = 99 each, and Side (`$FD51`) = 99 too**

(HL) = `$63` at `$FD4A`, then LDIR with BC = 7 copies it forward byte by byte to `$FD4B-$FD51`: eight bytes, one more than the seven resources, so Side (`$FD51`) is also set to 99. That is harmless: Side is written before it is read again (RobotStep at `$B154` for each robot step, EnemyCommander at `$B7F4` for the enemy's turn, the robot menu's search). With all seven at 99 every day, the enemy can always pay for any robot (PartCosts: all eight parts together cost 51), so its building counts no longer matter. Called by NewGameSetup (`$A688`, a new game) and DailyProduction (`$AE47`, each midnight): 10 runs in the deep recording (the new game and 9 midnights), and at its end EnemyResources read 99 in all seven, with the enemy at 24 robots and 3 warbases against the player's 4 robots and 1 warbase.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 10 calls, 1,920 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 192 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 192 t-states own (0.00 %) |
| Called from | `Start`, `NewGameSetup`, `DailyProduction` |
| Reads | `$FD4A`-`$FD50` (`work space $FD4A+`) |
| Writes | `$FD4A`-`$FD51` (`work space $FD4A+`) |

### start

`src/game98/start.asm`

#### `Start` (`$A600`)

**the entry from the REM loader: the IM 2 table, the start-up, the menu**

The IM 2 table `$FE00-$FF00` (257 x `$FD`), JP at `$FDFD`, Handler = StartInterrupt, I = `$FE`, IM 2; the random seed `$FD00-$FD03` = `$39`,`$30`,`$39`,`$30`; then MainMenu (Z: start a new game; NZ, NE's loaded game, no longer happens). Entered from the REM loader (`$5D94`) and reached again at the end of a game (`$AEFD`), by key I in play (`$A712`) and by LOAD NEW LEVEL (`$C267`, after the copy of the level).

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 33,660 t-states own (0.03 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 33,600 t-states own (0.11 %) |
| Called from | `MainMenuKeys` (tail) |
| Calls | `FillEnemyResources`, `PlayLoop`, `BuildMap`, `MainMenu`, `DrawViewBackground`, `DrawPlayScreen` |
| Reads | `$D7D3`-`$D7FE` (`Shots`); `$DA00`-`$DCFE` (`work space $DA00+`); `$FD04`-`$FDFB` (`work space $FD04+`); `$FF01`-`$FFC8` (`work space $FF01+`) |
| Writes | `$D7D3`-`$D7FF` (`Shots`); `$DA00`-`$DCFF` (`work space $DA00+`); `$FD00`-`$FFC9` (`work space $FD00+`) |

#### `NewGameSetup` (`$A62D`)

**New game: clear the robots, variables, buildings and shots, place the ship, 99 general, the enemy's 99s, build the map**

Entered from Start with the flags of the title menu MainMenu: Z (option 0, START GAME) sets a new game up; the JR NZ to EnterPlay is NE's path for a game loaded from tape, dead in the '98 (MainMenu returns only Z).

Zeroes the robot records `$DA00-$DCFF` (48 x 16), the variables `$FD04-$FDFC` (everything past the random seed, below the JP of the IM 2 vector), the building table `$FF01-$FFC9` and the five shot records `$D7D3-$D7FF` (5 x 9). Then: MapView = `$DD00`, ViewX = 0, ShipX = `$11`, ShipY = 14 (NE: 10; the '98 map has the player's warbase at (22,14)), Altitude = 0, the auto-climb counter `$FD30` = 3 (the ship rises to 6 on its own at the start), the player's general resource = 99 (NE: 20), then FillEnemyResources: all seven enemy resources = 99 (NE: the enemy's general = 20, the rest 0). BuildMap then clears the map `$DD00-$FCFF` and the radar buffer `$D800` and builds the landscape, the warbases and the factories. Falls into EnterPlay.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | run into, not called, 781,772 t-states own (0.04 %) |
| Calls | `FillEnemyResources`, `RobotMenu`, `GameTurn`, `MoveShip`, `WorldTurn`, `CountRobots`, `BuildMap`, `ConstructionMenu`, `ShipCell`, `DrawView`, `FindRobot`, `FindBuilding`, `DrawViewBackground`, `DrawPlayScreen`, `UpdateStatusPanel`, `WaitKey` |
| Reads | `$D7D3`-`$D7FE` (`Shots`); `$DA00`-`$DCFE` (`work space $DA00+`); `$F114`-`$F119` (`work space $F114+`); `$F314`-`$F316` (`work space $F314+`); `$F512`-`$F516` (`work space $F512+`); `$F712`-`$F716` (`work space $F712+`); 4 more ranges |
| Writes | `$D7D3`-`$D7FF` (`Shots`); `$DA00`-`$DCFF` (`work space $DA00+`); `$FD04`-`$FDFF` (`work space $FD04+`); `$FF01`-`$FFC9` (`work space $FF01+`) |

#### `EnterPlay` (`$A68E`)

**Draw the play screen and switch to the play interrupt**

DrawViewBackground and DrawPlayScreen build the play screen (the view, its frame, the radar, the status panel); then Handler = PlayInterrupt, which counts the frames in `$FD34` and draws the radar each frame. Falls into PlayLoop. Entered from NewGameSetup and again after the SAVE key (key 5, SaveGame: a bare RET in the '98) at `$A71D`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PlayLoop` (`$A69A`)

**The play loop: one game turn a pass (at least 10 frames)**

One pass: WaitKey (the controls into Input; key 1 pauses here), MoveShip, WorldTurn (every robot record and the five shots), DrawView (draw the view), GameTurn (the random step, the clock, captures, the end of the game; waits until 10 frames have passed since the previous turn). NE's recording ran it 3332 times in 36046 frames: about 10.5 frames a turn, 5 turns a second.

Then it looks under the ship (ShipCell: HL = the ship's map cell). Map bit 6 means something stands there. A robot of ours (FindRobot, B = 48 - slot >= 25) with the ship resting exactly on its top (Altitude = +`$09` + +`$0D`) opens RobotMenu. Otherwise a building of type 0 (the pad of our warbase) with Altitude = 15 (the pad's top, the ship cannot sink below it) opens ConstructionMenu, but only when the warbase's door cell 4 rows below the pad and the three cells below the door (row +5, columns -1, 0, +1) are free of bit 6: the new robot is placed on the door (ShipY + 4, `$CB6A`). After the menu the new record gets +`$05` = 4, +`$06` = 5, +`$0B` = 0 (stop), +`$0C` = 100 (strength), +`$0F` = 1 (moves at once); CountRobots recounts the robots and UpdateStatusPanel reprints the panel.

Bug (seen on NE's own instance): ConstructionMenu returns at once when all 24 of our slots are taken, with IY left on `$DB80`, the enemy's slot 24. The writes at `$A6F3` then hit that enemy robot: its strength goes back to 100 and its order to 0, every turn the ship sits on the pad.

Last, the game keys: Input bit 6 (key I in the default KeyTable) abandons the game (JP Start), bit 5 (key 5) calls SaveGame, which in the '98 only returns, and redraws the play screen (EnterPlay).

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 17,043 t-states own (0.02 %) |
| Called from | `Start` |
| Calls | `GameTurn`, `MoveShip`, `WorldTurn`, `ShipCell`, `DrawView`, `WaitKey` |
| Reads | `$F911` (`work space $F911+`); `$FD0C` (`work space $FD0C+`) |

### robotmenu

`src/game98/robotmenu.asm`

#### `RobotMenu` (`$A720`)

**landing on a robot of ours: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT; the order to +`$0B`**

IX = IY (the record), +`$0A` = 1 (the robot stands: UpdateRobot returns at once for +`$0A` = 1), MenuCursor = 4 (LEAVE ROBOT first), PanelBusy = 1. Falls into RobotMenuShow. Called by PlayLoop when the ship rests exactly on the top of a robot of ours.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 352 t-states own (0.00 %) |
| Called from | `NewGameSetup` |
| Calls | `RobotMenuShow` |
| Writes | `$DA0A`-`$DA3A` (`work space $DA0A+`); `$FD1F` (`work space $FD1F+`); `$FD39` (`work space $FD39+`) |

#### `RobotMenuShow` (`$A732`)

**Robot menu: draw the four items, the current order and the strength, then choose**

Clears the side panel (ClearPanel) and prints DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT at (4,23), every 3 rows, attribute `$4D`, and the title -ORDERS- at (17,23). Falls into ShowOrder, ShowOrderMiles and RobotMenuChoose. Every submenu comes back here when it is done (`$A93E`, `$AA09`, `$AACC`, `$ABFD`, the combat menu at `$AC8B`).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 8 calls, 272 t-states own (0.00 %) |
| Called from | `RobotMenu`, `SetOrder` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

#### `ShowOrder` (`$A795`)

**Robot menu: print the name of the robot's order**

Copies the 27-byte name of order +`$0B` from OrderNames (`$A848` + 27 x order) into OrderLine, the string printed right after the CALL at `$A7AA`: three lines at (18,23), attribute `$45`.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 8 calls, 5,648 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintInline` |
| Reads | `$A848`-`$A862` (`OrderNames`); `$A899`-`$A8B3` (`OrderName3`); `$A8EA`-`$A904` (`OrderName6`); `$DA0B`-`$DA3B` (`work space $DA0B+`) |
| Writes | `$A7B2`-`$A7CC` (`OrderLine`) |

#### `ShowOrderMiles` (`$A7CD`)

**Robot menu: for ADVANCE and RETREAT, the miles under the order's name**

Orders 1 and 2 only: prints at (19,25) the distance +`$0E` / 2 with two digits (PrintNumber2), into the blank middle line of the order's name ("ADVANCE", "nn", "MILES"). Other orders jump straight to RobotMenuChoose. IX = the robot record.

The printing tail after the inline position is ShowMilesCode (`$A7DC`). No recording of NE's gave these orders; checked on NE's own instance: an ADVANCE of 10 miles showed "10" there. In this part's deep recording ShowOrderMiles ran 8 times and its tail never (no robot had either order).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 8 calls, 1,820 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `OrdersMenu` (tail), `ListMenu`, `Beep`, `ShowStatusPanel`, `ClearPanel` |
| Reads | `$DA0B`-`$DA3B` (`work space $DA0B+`); `$FD1F` (`work space $FD1F+`) |
| Writes | `$DA06`-`$DA3A` (`work space $DA06+`); `$FD1F` (`work space $FD1F+`); `$FD30`-`$FD39` (`work space $FD30+`) |

#### `ShowMilesCode` (`$A7DC`)

**Code neither NE's recordings nor this part's ran: LD A,(IX+`$0E`); SRL A; CALL `$D3E5`**

The tail of ShowOrderMiles after its inline position: A = +`$0E` / 2 (the miles, stored doubled), printed with two digits and a leading space by PrintNumber2. Falls into RobotMenuChoose. Run for orders 1 and 2 (seen on NE's own instance; no recording of NE's got here).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RobotMenuChoose` (`$A7E4`)

**Robot menu: choose an item and run it; LEAVE ROBOT closes the menu**

Prints the strength, runs ListMenu on the four items (HL = `$5837`, the attribute of row 1 column 23, E = 5, A = MenuCursor) and keeps the choice in MenuCursor, so the menu reopens on it. 1 DIRECT CONTROL (`$A93B`), 2 GIVE ORDERS (OrdersMenu), 3 COMBAT MODE (CombatMenu `$AC00`), 4 LEAVE ROBOT: a beep, +`$06` = 0, +`$0A` = 0 (the robot carries on with its order), the auto-climb `$FD30` = 5 turns so the ship rises off the robot and the menu does not reopen, then CloseRobotMenu.

CloseRobotMenu (`$A812`) clears the panel, sets `$FD39` = 0 and redraws the status panel (ShowStatusPanel); ListMenu also jumps there when the robot is destroyed while its menu is open (seen: freeing +`$01` under the open menu closed it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowStrength` (`$A81D`)

**Robot menus: print STRENGTH and the robot's strength in %**

Prints "STRENGTH" at (22,23) and the value of +`$0C` at (23,25), three digits with leading spaces and "%" (a robot is born with 100). A negative +`$0C` (a dying robot, UpdateRobot counts it up) shows as 0 % (poked `$80`: "0%"). Called once a turn by every robot menu loop. IX = the robot record.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 64 calls, 1,088 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose`, `ListMenu` |
| Calls | `PrintInline` |

#### `ShowStrengthValue` (`$A833`)

**Print the strength +`$0C` as "nnn%"**

The tail of ShowStrength after its inline string: a negative strength is shown as 0; PrintNumber3 prints HL with three digits, E = `$20` makes the leading zeros spaces; the "%" goes out through PrintCharKeep.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 64 calls, 5,440 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber3`, `PrintCharKeep` (tail) |
| Reads | `$DA0C`-`$DA3C` (`work space $DA0C+`) |

#### `DirectControlItem` (`$A93B`)

**Robot menu item 1: direct control, then the robot menu again**

Calls DirectControl (drive the robot until fire, or until it is destroyed) and redraws the robot menu with RobotMenuShow. MenuCursor still holds 1, so the menu reopens on DIRECT CONTROL. A robot destroyed while driven: DirectControl returns, RobotMenuShow redraws, and ListMenu then sees +`$01` = 0 and closes the menu. Not run in NE's recordings; run on NE's own instance.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DirectControl` (`$A941`)

**Drive the robot with the controls until fire**

+`$0A` = 2 and +`$05` = 0, then a loop of game turns without the ship's own move: WorldTurn moves the robot from Input (`$B184` -> `$B450`) and calls MoveShip from there (`$B4A8`), so the ship travels on the robot; DrawView draws the view, MenuRadarTick blinks the ship on the radar, GameTurn, ShowStrength. Fire gives the robot back (+`$0A` = 1, a beep) and returns. Returns at once (Z) when the robot is destroyed (+`$01` = 0).

Used by the robot menu (item 1) and by the combat menu (MOVE ROBOT, `$AC93`). Not run in NE's recordings. On NE's own instance: +`$0A` went to 2, holding right turned the robot (+`$08` 4 -> 1) and moved it one column, the ship's ShipX followed (22 -> 23); fire set +`$0A` back to 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `OrdersMenu` (`$A971`)

**GIVE ORDERS: the five orders**

Clears the panel and prints SELECT ORDERS at (4,24) and the five items from (7,23): STOP AND DEFEND, ADVANCE ?? MILES, RETREAT ?? MILES, SEARCH & DESTROY, SEARCH & CAPTURE. Falls into OrdersMenuChoose.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 136 t-states own (0.00 %) |
| Called from | `ShowOrderMiles` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

#### `OrdersMenuChoose` (`$A9EC`)

**GIVE ORDERS: choose; stop at once, advance / retreat ask the miles, search asks the target**

ListMenu at HL = `$5897` (row 4: item 1 at row 7), E = 6, A = 1. Item 1 sets order 0 (stop and defend) and returns to the robot menu. Items 2 and 3 set order 1 (advance) or 2 (retreat) and go on to the distance menu (DistanceMenu, `$AA19` on). Items 4 and 5 go to TargetMenu with the flags of CP 3 (Z = SEARCH & DESTROY).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 516 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `TargetMenu` (tail), `ListMenu`, `WaitRelease` |

#### `AdvanceJump` (`$AA2D`)

**Code neither NE's recordings nor this part's ran: JR `$AA40`, past the RETREAT title**

The last instruction of the ADVANCE branch of OrdersMenuChoose: after the "ADVANCE " title it jumps over RetreatTitle into DistanceMenu, the part both orders share. Not run in NE's recordings; seen on NE's own instance.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RetreatTitle` (`$AA2F`)

**GIVE ORDERS, RETREAT: the title of the distance menu**

The RETREAT branch of OrdersMenuChoose: prints "RETREAT " at (5,23), attribute `$4F`, then falls into DistanceMenu. The order (+`$0B` = 2) is already stored.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DistanceMenu` (`$AA40`)

**Code neither NE's recordings nor this part's ran: CALL PrintInline, the distance menu's texts**

The distance menu of ADVANCE and RETREAT, shared by both: its texts "?? MILES" (the next line under the title), SELECT DISTANCE at (9,23), "0 MILES" at (13,24); then falls into DistanceSelect. Not run in NE's recordings; on NE's own instance: up 3 times, down once, fire = 10 miles, +`$0E` = 20, +`$0B` = 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DistanceSelect` (`$AA6E`)

**Code neither NE's recordings nor this part's ran: choose the miles, 0-50 by 5**

D = the miles, from 0. Each pass of DistanceLoop is one game turn (ShowStrength, WorldTurn, DrawView, MenuRadarTick, GameTurn); a destroyed robot (+`$01` = 0) closes the whole menu (JP CloseRobotMenu). Then WaitKey: fire goes to DistanceFire; up adds 5, down takes 5 (up wins when both are held); a value out of 0-50 (CP `$33`, a negative one wraps above it) is refused. A change is printed at (13,23), attribute `$46`, by DistanceShow with the click `$14`. No release wait: a held key steps once a game turn.

DistanceFire: +`$0E` = miles x 2; 0 miles turns the order back into 0 (stop and defend); the beep `$78`, WaitRelease, back to the robot menu. Not run in NE's recordings; run on NE's own instance.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DistanceShow` (`$AAAD`)

**the miles in D printed (PrintNumber2), a click, back to the distance loop**

The tail of DistanceSelect after the inline position (13,23): prints D, the miles, with two digits (PrintNumber2), clicks (Beep `$14`) and goes back to DistanceLoop for the next game turn. DistanceFire (`$AAB8`) follows: the end of the distance menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TargetMenu` (`$AACF`)

**SEARCH & DESTROY or SEARCH & CAPTURE: the three targets**

Z (the destroy item): clears the panel and prints SEARCH & DESTROY, SELECT TARGET and ENEMY ROBOTS / ENEMY FACTORYS / ENEMY WARBASES; NZ goes to CaptureMenu.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 74 t-states own (0.00 %) |
| Called from | `OrdersMenuChoose` (tail) |
| Calls | `CaptureMenu` (tail), `ClearPanel`, `PrintInline` |

#### `DestroyMenuChoose` (`$AB3D`)

**SEARCH & DESTROY: choose the target, orders 3-5**

ListMenu at HL = `$5937` (item 1 at row 12), E = 4, A = 1; the item + 2 is the order (3 robots, 4 factories, 5 warbases) for SetOrder.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 77 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `SetOrder` (tail), `ListMenu` |

#### `CaptureMenu` (`$AB4E`)

**SEARCH & CAPTURE: the three targets**

Prints SEARCH & CAPTURE, SELECT TARGET and NEUTRAL FACTORYS / ENEMY FACTORYS / ENEMY WARBASES.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 3 calls, 102 t-states own (0.00 %) |
| Called from | `TargetMenu` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

#### `CaptureMenuChoose` (`$ABB9`)

**SEARCH & CAPTURE: choose the target, orders 6-8**

The same list as DestroyMenuChoose; the item + 5 is the order (6 neutral factories, 7 enemy factories, 8 enemy warbases).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 3 calls, 195 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `SetOrder`, `ListMenu` |

#### `SetOrder` (`$ABC8`)

**Store a search order, look for its first target, or fall back to stop**

A = the order (3-8) into +`$0B`. Orders 4 and 5 (destroy factories, warbases) need the nuclear bomb (+`$07` bit 6); without it the order becomes 0. Otherwise `$FD51` = 0 (our side), +`$0E` = `$FF` and FindTargetBuilding looks for a target of the order from the robot's X (+`$02`/+`$03`): D, the index it found, goes to +`$0E`; no target (Z) makes the order 0. A beep, WaitRelease, back to the robot menu. Ran 7 times in NE's recording (destroy robots, capture neutral and enemy factories).

CombatMenu (`$AC00`) follows in the same block: the robot menu's item 3.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 984 t-states own (0.00 %) |
| Called from | `DestroyMenuChoose` (tail), `CaptureMenuChoose` |
| Calls | `RobotMenuShow` (tail), `WaitRelease`, `FindTargetBuilding`, `Beep` |
| Reads | `$DA02`-`$DA33` (`work space $DA02+`) |
| Writes | `$DA0B`-`$DA3E` (`work space $DA0B+`); `$FD51` (`work space $FD51+`) |

#### `CombatMenuCode` (`$AC7C`)

**Code neither NE's recordings nor this part's ran: the combat menu**

The code after CombatMenuText: the strength, then ListMenu on the six items (HL = `$5837`, E = 7), STOP COMBAT highlighted first. Each choice comes back to CombatMenuLoop with A = the item, so the menu reopens on it.

6 STOP COMBAT: back to the robot menu. 5 MOVE ROBOT: DirectControl, then the menu again. 1-4 need the weapon: +`$07` rotated left item + 1 times leaves in carry bit 6 (nuclear), 5 (phasers), 4 (missiles) or 3 (cannon); without it the low buzz (`$FA`) and the menu again.

1 NUCLEAR BOMB: IY = IX, NuclearBlast, then the menu closes (JP CloseRobotMenu): the bomb destroys the robot carrying it. 2-4: shot record 0 at `$D7D3` (Shots); if it is free (+`$01` = 0), A = 5 - item (3 phasers, 2 missiles, 1 cannon) and FireShot launches it from the robot along its facing (+`$08`), then DrawView and GameTurn; a shot of record 0 still flying buzzes.

No recording of NE's entered COMBAT MODE. Seen on NE's own instance: FIRE CANNON on a bipod + cannon robot wrote +`$05` = 4 (the robot's facing), +`$06` = 5, +`$07` = 1, +`$08` = `$0A` into `$D7D3`; FIRE MISSILES without missiles changed nothing.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ListMenu` (`$ACD7`)

**a list menu: HL the attribute of item 0 (an item every 3 rows), E the items + 1, A the first highlighted; down / up move, fire returns A**

Each pass is one game turn (WorldTurn, DrawView, MenuRadarTick, GameTurn, ShowStrength): the game goes on while a menu waits. A destroyed robot (+`$01` = 0) drops ListMenu's return address and closes the robot menu (CloseRobotMenu). Up / down move by one item (items 1 to E - 1) with a click `$14`; fire paints the item `$4F`, beeps `$64` and returns A. Attributes: `$4D` normal, `$4E` highlighted, `$4F` chosen. Needs IX = a robot record.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 16 calls, 20,816 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose` |
| Calls | `ShowStrength`, `PaintMenuItem`, `WaitRelease`, `GameTurn`, `MenuRadarTick`, `WorldTurn`, `Beep`, `DrawView`, `WaitKey` |
| Reads | `$DA01`-`$DA31` (`work space $DA01+`); `$FD0C` (`work space $FD0C+`) |

#### `PaintMenuItem` (`$AD3C`)

**Colour list item A: 2 rows of 8 attributes with C**

HL = the attribute of item 0; item A starts `$60` bytes (3 rows) further per item. Fills 8 attributes, moves down a row (`$18` more) and fills 8 more with C (`$4D` normal, `$4E` highlighted, `$4F` chosen). A must be 1 or more. Keeps DE and HL.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 96 calls, 19,152 t-states own (0.00 %) |
| Called from | `ListMenu` |
| Calls | `FillAttributes`, `AddAToHL` |

#### `WaitRelease` (`$AD57`)

**wait until no control is held**

Calls WaitKey until Input is 0: every control up. Used by every menu before it reads a new press, so the fire that chose an item does not choose again. Keeps BC and HL; A = 0 on return. Uses WaitKey, so key 1 still pauses.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 24 calls, 1,920 t-states own (0.00 %) |
| Called from | `OrdersMenuChoose`, `SetOrder`, `ListMenu` |
| Calls | `WaitKey` |

### gameturn

`src/game98/gameturn.asm`

#### `GameTurn` (`$AD62`)

**One game turn: the random step, the clock, the daily production, the clock print**

Called once a pass by PlayLoop and by every robot menu loop (3414 times in NE's recording). Random steps the random generator `$FD00-$FD03`. Clock (`$FD35` minutes, `$FD36` hours, `$FD37-$FD38` days) gains 5 minutes a turn: 60 minutes make an hour, 24 hours a day, and a new day runs DailyProduction. Then the clock print: days at (0,27), five digits with leading spaces; "HH.MM" on the next line. Goes on in GameTurnEnd.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,693 calls, 237,561 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 97 calls, 8,532 t-states own (0.01 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu` |
| Calls | `DailyProduction`, `Random`, `PrintInline` |
| Reads | `$FD35`-`$FD38` (`work space $FD35+`) |
| Writes | `$FD35`-`$FD38` (`work space $FD35+`) |

#### `GameTurnEnd` (`$AD90`)

**Game turn, second half: the clock print, the game end, captures, the frame pacing**

The second half of GameTurn, reached after the PrintInline of ClockPos (setting the print position (0,27) and attribute `$57`). Prints the days (PrintNumber5, five digits with leading spaces) and, a line down (PrintNewline), the hours "." the minutes (PrintNumber2Zero, two digits with zeros). Then CheckGameEnd: a side with no warbase ends the game here.

Captures: the 28 capture points at `$FD70` (5 bytes each: X 2 bytes, Y, owner and type, count; points 0-3 the warbases, 4-27 the factories) are checked each turn. While map bit 6 is set on a point's door cell (an anchor stands there) its count +4 goes up; at 144 (`$90`) FindRobot takes the robot there and its side (+`$0A` bit 7) captures the building: GiveWarbase for a warbase, GiveFactory (point - 4) for a factory. A door anchor that is no robot (probably a flying shot) captures nothing; the count still starts again. An empty door resets the count. NE's recording shows every capture after a count of 121-143 at the 250-frame samples. Any robot captures, whatever its order. After a capture CountBases recounts the buildings and UpdateStatusPanel reprints the status.

Last, the pacing (TurnPace): waits until PlayInterrupt has counted 10 frames in TurnFrames (`$FD34`) since the last turn, then clears it. A turn is at least 10 frames: an hour 120, a game day 2880 (about 58 s). Keeps IY (pushed around the loop); A, BC, DE, HL lost.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,693 calls, 29,268,876 t-states own (1.35 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 97 calls, 12,435,073 t-states own (12.36 %) |
| Called from | `PrintInline` |
| Calls | `CheckGameEnd`, `CountBases`, `GiveFactory`, `MapCell`, `FindRobot`, `UpdateStatusPanel`, `PrintNumber2Zero`, `PrintNumber5`, `PrintCharKeep`, `PrintNewline` |
| Reads | `$DC1A` (`work space $DC1A+`); `$DC5A` (`work space $DC5A+`); `$E3A7`-`$E4C6` (`work space $E3A7+`); `$E726`-`$E7F7` (`work space $E726+`); `$EF32`-`$F07C` (`work space $EF32+`); `$F21D`-`$F2E8` (`work space $F21D+`); 5 more ranges |
| Writes | `$FD34` (`work space $FD34+`); `$FD74`-`$FDFB` (`work space $FD74+`) |

#### `UnusedTapeCode` (`$AE29`)

**Unreferenced code: keys 6 and 7 together jump into the tape ROM**

15 bytes of code nothing calls or jumps to: LD A,`$EF`; IN A,(`$FE`); AND `$18`; RET NZ (unless 6 and 7 are both held); LD HL,`$A600`; PUSH HL; DI; JP `$04B0`. `$04B0` is inside an instruction of the 48K ROM's SAVE code; with Start as the return address it looks like a debugging leftover (a memory dump to tape). Never runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DailyProduction` (`$AE38`)

**A new day: our buildings add to our resources; every enemy robot upgraded, the enemy's resources back to 99**

Our side from `$FD3A` into Resources (ProduceSide). In NE the same call follows for the enemy (`$FD42` into `$FD4A`); the '98 has three NOPs at `$AE41` (the LD HL,`$FD4A` cleared) and the next two CALLs (NE's LD DE,`$FD42` / CALL ProduceSide bytes) go to ZS's routines in the sprites' spare space: UpgradeEnemyRobots (each of the 24 enemy records gets anti-grav and electronics, its locomotion replaced) and FillEnemyResources (all seven enemy resources = 99). Then the panel reprint (UpdateStatusPanel). Called by GameTurn once a game day (midnight).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9 calls, 990 t-states own (0.00 %) |
| Called from | `GameTurn` |
| Calls | `UpgradeEnemyRobots`, `FillEnemyResources`, `ProduceSide`, `UpdateStatusPanel` |

#### `ProduceSide` (`$AE4E`)

**The player's production: 8 general a warbase, 2 a factory of each kind**

DE = the building counts (warbases, then the factories of electronics, nuclear, phasers, missiles, cannon, chassis), HL = the 7 resources (general first, then the same order). General += 8 x warbases (NE: 5: LD C,A / ADD A,A / ADD A,A / ADD A,C, the '98 ADD A,A three times and a NOP); each other resource += 2 x the factories of its kind; every resource stops at 99. Only the player's side calls it in the '98 (DailyProduction).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9 calls, 3,330 t-states own (0.00 %) |
| Called from | `DailyProduction` |
| Calls | `AddCapped` |
| Reads | `$FD3A`-`$FD40` (`work space $FD3A+`) |

#### `AddCapped` (`$AE62`)

**(HL) += A, at most 99**

(HL) += A, at most 99: the resource store of ProduceSide. HL is kept, so ProduceSide walks the 7 resources with INC HL. A = the new value. Used only by ProduceSide.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 63 calls, 2,721 t-states own (0.00 %) |
| Called from | `ProduceSide` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`) |
| Writes | `$FD22`-`$FD28` (`work space $FD22+`) |

#### `CheckGameEnd` (`$AE6B`)

**The end of the game: the enemy has no warbase (won) or we have none (lost)**

`$FD42` (the enemy's warbases) = 0: GameWon. Else `$FD3A` (ours) = 0: GameStop, "YOU HAVE NO BASES LEFT / BETTER LUCK NEXT TIME!" at (22,0), then the common end at `$AEEA`. Both tested by poking the counts on NE's own instance (the messages showed, the handler became StartInterrupt, fire went back to the title menu).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,693 calls, 140,055 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 97 calls, 5,044 t-states own (0.01 %) |
| Called from | `GameTurnEnd` |
| Reads | `$FD3A`-`$FD42` (`work space $FD3A+`) |

#### `LostJump` (`$AEAF`)

**Code neither NE's recordings nor this part's ran: JR `$AEEA`, the common end**

Code neither NE's recordings nor this part's ran: the lost path goes on here after PrintInline has printed LostText: JR GameOverWait, the end shared with GameWon.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GameWon` (`$AEB1`)

**The enemy has no warbase left: "WELL DONE! WAIT FOR / NEW LEVELS FROM ZS!"**

Stops play (GameStop), prints the message at (22,0) and falls into the common end at `$AEEA`: a low buzz, 100 frames, WaitRelease, then the first control (Input not 0, the chosen keys or stick only) goes back to Start and the title menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GameOverWait` (`$AEEA`)

**Code neither NE's recordings nor this part's ran: the end of a won or lost game**

LD A,`$FA`; CALL `$CCAC` (the buzz); LD B,100; HALT; DJNZ (2 s); CALL WaitRelease; CALL WaitKey until a control is held; JP Start.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GameStop` (`$AF00`)

**Stop play: give the panel back to the status and switch to the idle interrupt**

`$FD39` = 0, clears the panel, prints the status panel (ShowStatusPanel), Handler = StartInterrupt (no frame count, no radar). Used by both ends of the game.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### ship

`src/game98/ship.asm`

#### `MoveShip` (`$AF11`)

**the ship's move from Input: X by right / left, Y by down / up, each refused by CheckShipMove**

Also the auto-climb (ClimbTurns), the altitude (fire +2 up to `$30`, else -1 down to what stands under the ship), the view follow (ViewX moves when the ship is at view column 13 or 22), the radar window (ScrollRadar) and the ship's mark: map bit 7 cleared on the old cell (`$B01D`) and set on the new one (`$B024`), the radar blip XORed. Called by PlayLoop, and by UpdateRobot (`$B4A8`) while a robot is under direct control.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,646 calls, 1,008,442 t-states own (0.05 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 29,058 t-states own (0.03 %) |
| Called from | `NewGameSetup`, `PlayLoop` |
| Calls | `ScrollRadar`, `LiftShipFromMap`, `PutShipOnMap`, `CheckShipMove` |
| Reads | `$FD0A`-`$FD1E` (`work space $FD0A+`); `$FD30` (`work space $FD30+`) |
| Writes | `$FD06`-`$FD1E` (`work space $FD06+`); `$FD30` (`work space $FD30+`) |

#### `ScrollRadar` (`$AFE6`)

**Move the radar window by 64 columns when the ship nears its edge**

The radar shows 128 map columns: from column `$FD1B` x 8 (`$FD1C` = the same as a column, 16 bits). With A = ShipX / 8 - `$FD1B`: below 2 (the ship within 16 columns of the left edge) the window moves 8 units left, unless it is at 0; 14 and more moves it 8 units right, at most to `$30` (columns 384-511). A move sets `$FD52` = 1: the radar bitmap is rebuilt from the map by BuildRadar at the ship's next mark (`$B029`). Called by MoveShip every turn (3332 times).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,645 calls, 283,091 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 10,486 t-states own (0.01 %) |
| Called from | `MoveShip` |
| Reads | `$FD0E`-`$FD1B` (`work space $FD0E+`) |

#### `LiftShipFromMap` (`$B01D`)

**clear the ship's occupant bit in its map cell, toggle its radar dot**

Called by MoveShip first thing each game turn, before the ship moves: the cell under the ship (ShipCell: `$DD00` + `$200` * ShipY + ShipX) loses bit 7, the occupant bit robots test (FreeDirections) when the ship hangs lower than their top, and the ship's dot on the radar is toggled off when it is on (BlinkShipDot). PutShipOnMap undoes both after the move.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,646 calls, 116,424 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 4,312 t-states own (0.00 %) |
| Called from | `MoveShip` |
| Calls | `BlinkShipDot` (tail), `ShipCell` |
| Reads | `$F114`-`$F119` (`work space $F114+`); `$F314`-`$F316` (`work space $F314+`); `$F512`-`$F516` (`work space $F512+`); `$F712`-`$F716` (`work space $F712+`); `$F911`-`$F916` (`work space $F911+`); `$FB16` (`work space $FB16+`) |
| Writes | `$F114`-`$F119` (`work space $F114+`); `$F314`-`$F316` (`work space $F314+`); `$F512`-`$F516` (`work space $F512+`); `$F712`-`$F716` (`work space $F712+`); `$F911`-`$F916` (`work space $F911+`); `$FB16` (`work space $FB16+`) |

#### `PutShipOnMap` (`$B024`)

**set the ship's occupant bit in its new map cell, rebuild the radar if the window moved, toggle the ship's dot**

Called at the end of MoveShip (and by BuildMap). Sets bit 7 of the ship's cell, then goes on into RefreshRadar. Recording: 3333 calls, once a game turn.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,646 calls, 84,672 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 99 calls, 6,068 t-states own (0.01 %) |
| Called from | `MoveShip`, `BuildMap` |
| Calls | `RefreshRadar`, `BlinkShipDot`, `ShipCell`, `BuildRadar` |
| Reads | `$F114`-`$F119` (`work space $F114+`); `$F314`-`$F316` (`work space $F314+`); `$F512`-`$F516` (`work space $F512+`); `$F712`-`$F716` (`work space $F712+`); `$F911`-`$F916` (`work space $F911+`); `$FB16` (`work space $FB16+`); 1 more ranges |
| Writes | `$F114`-`$F119` (`work space $F114+`); `$F314`-`$F316` (`work space $F314+`); `$F512`-`$F516` (`work space $F512+`); `$F712`-`$F716` (`work space $F712+`); `$F911`-`$F916` (`work space $F911+`); `$FB16` (`work space $FB16+`); 1 more ranges |

#### `RefreshRadar` (`$B029`)

**rebuild the radar when RadarDirty is set, then blink the ship's dot**

RadarDirty (`$FD52`) is set when the window moved (`$B017`) and by other code that changes the map (the start, a loaded game). BuildRadar then redraws both radar layers `$D800` / `$D900` from the map (a pixel for every cell of type `$0F` or more, the high ground) and plots every live robot's dot; the flag is cleared. Falls into BlinkShipDot. Also reached from MenuRadarTick.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,694 calls, 78,174 t-states own (0.00 %) |
| Called from | `PutShipOnMap`, `MenuRadarTick` (tail) |
| Calls | `BlinkShipDot`, `BuildRadar` |
| Reads | `$FD52` (`work space $FD52+`) |
| Writes | `$FD52` (`work space $FD52+`) |

#### `BlinkShipDot` (`$B036`)

**on odd ticks toggle the ship's 2x2 dot on the radar's player layer**

RadarBlink (`$FD1E`) counts the game turns (MoveShip increments it between LiftShipFromMap and PutShipOnMap, MenuRadarTick in the menus). When it is odd, ToggleRadarDot XORs a 2x2 dot at (ShipX, ShipY) into the layer B = 0 (`$D800`, shown with attribute `$4D` by PlayInterrupt in alternate frames). Off-window positions draw nothing (RadarDotAddress). The pairs of toggles around each move leave the dot on every other turn: the ship's dot blinks.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 5,388 calls, 285,659 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 197 calls, 10,419 t-states own (0.01 %) |
| Called from | `LiftShipFromMap` (tail), `PutShipOnMap`, `RefreshRadar`, `MenuRadarTick` |
| Calls | `ToggleRadarDot` (tail) |
| Reads | `$FD0D`-`$FD1E` (`work space $FD0D+`) |

#### `MenuRadarTick` (`$B048`)

**one blink step of the ship's dot while a menu is open**

Called by the robot menu loop (DirectControl) and ListMenu each pass, so the world goes on and the ship's dot keeps blinking while the player sits in a menu: toggles the dot (BlinkShipDot), advances RadarBlink, rebuilds the radar if needed and toggles again on the new tick (RefreshRadar). 83 calls in NE's deep recording.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 48 calls, 2,304 t-states own (0.00 %) |
| Called from | `ListMenu` |
| Calls | `RefreshRadar` (tail), `BlinkShipDot` |
| Reads | `$FD1E` (`work space $FD1E+`) |
| Writes | `$FD1E` (`work space $FD1E+`) |

#### `CheckShipMove` (`$B052`)

**carry: the ship may not stand at HL (X), A (Y)**

Tests a place for the ship: HL = the column X, A = the row Y. C = the highest top under the ship's 2 x 2 footprint (X, Y), (X+1, Y), (X, Y-1), (X+1, Y-1): the terrain height of each cell and the top of any robot (+`$09` + +`$0D`) or building (BuildingTops) anchored there (CellTop); then ObjectTop alone on (X-1, Y-1), (X-1, Y) and, inside the map, the row Y+1 (X-1 to X+1), whose anchored objects reach into the footprint.

Out: carry set when Altitude < C (the ship would be inside something there), C = the top, HL = X kept; B kept (ObjectTop saves BC), DE and A lost, IY may point at the robot or building found. Called by MoveShip for the X move (MoveShipX), the Y move (ShipCheckY) and, with the ship's own place, by Sink to get the floor under the ship.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,205 calls, 658,621 t-states own (0.03 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 6 calls, 1,806 t-states own (0.00 %) |
| Called from | `MoveShip` |
| Calls | `CellTop`, `ObjectTop`, `MapCell` |
| Reads | `$FD10` (`work space $FD10+`) |

#### `TerrainTop` (`$B08A`)

**C = max(C, the ground height of the terrain type at DE)**

DE a map cell. The cell's type (bits 0-4) indexes the ground height table TerrainHeights `$D7BC` (00 00 02 02 02 02 03 03 06 06 06 06 00 00 00 07 0F 07 0F ...: types 2-5 height 2, 6-7 (the wreck a destroyed robot leaves) 3, 8-`$0B` 6, `$0F`/`$11` 7, `$10`/`$12` 15). Keeps the higher of it and C (KeepHigher). Used by CheckShipMove (through CellTop) and GroundUnderFootprint; 39396 calls.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 65,252 calls, 3,916,184 t-states own (0.18 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 296 calls, 25,163 t-states own (0.03 %) |
| Called from | `CellTop`, `GroundUnderFootprint` |
| Calls | `KeepHigher` (tail), `AddAToHL` |
| Reads | `$D7BC`-`$D7CC` (`TerrainHeights`); `$DD22`-`$DD3D` (`work space $DD22+`); `$DD67`-`$E33D` (`work space $DD67+`); `$E365`-`$E73D` (`work space $E365+`); `$E763`-`$E93D` (`work space $E763+`); `$E963`-`$EB3D` (`work space $E963+`); 2 more ranges |

#### `CellTop` (`$B096`)

**C = max(C, the ground and the object on cell DE)**

TerrainTop, then falls into ObjectTop: the highest point of a cell, used for the 2x2 footprint in CheckShipMove.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 8,820 calls, 149,978 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 24 calls, 408 t-states own (0.00 %) |
| Called from | `CheckShipMove` |
| Calls | `TerrainTop` |

#### `ObjectTop` (`$B099`)

**C = max(C, the top of a robot or a building anchored at cell DE)**

When the cell has bit 6 (an object anchored there): a robot (FindRobot) counts with its body height +`$09` plus the ground under it +`$0D`; else a building (FindBuilding) with its height from BuildingTops by type. A cell with bit 6 that is neither (a shot) counts nothing. B and C are kept.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 10,757 calls, 821,428 t-states own (0.04 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 30 calls, 1,674 t-states own (0.00 %) |
| Called from | `CheckShipMove` |
| Calls | `KeepHigher`, `FindRobot`, `FindBuilding`, `AddAToHL` |
| Reads | `$B0C1`-`$B0C8` (`BuildingTops`); `$DA09`-`$DA3D` (`work space $DA09+`); `$EF13`-`$EF1A` (`work space $EF13+`); `$F111`-`$F11A` (`work space $F111+`); `$F311`-`$F31A` (`work space $F311+`); `$F511`-`$F517` (`work space $F511+`); 4 more ranges |

#### `KeepHigher` (`$B0AB`)

**C = max(C, A)**

The common tail of TerrainTop and ObjectTop.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 66,930 calls, 1,675,034 t-states own (0.08 %) |
| Called from | `TerrainTop` (tail), `ObjectTop` |

### world

`src/game98/world.asm`

#### `WorldTurn` (`$B0CA`)

**one game turn of the world: the enemy commander, every robot, every shot**

Called once a game turn by the play loop (PlayLoop) and by the menus (DirectControl, ListMenu), so robots fight and walk on while the player chooses: 3415 calls in 36046 frames, a turn is about 10 frames. First EnemyCommander (one enemy slot built or re-ordered), then UpdateRobot for each of the 48 robot records `$DA00` whose +`$01` is not 0, then UpdateShot for each of the 5 shot records of 9 bytes at `$D7D3` whose +`$01` is not 0. Robots and shots are taken in slot order, the player's slots 0-23 first. Shot record 0 (`$D7D3`) is the one the player fires from the robot menu's COMBAT MODE (DirectControl -> FireShot); the robots use records 1-4 (FindFreeShot).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,693 calls, 13,764,596 t-states own (0.63 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 486,689 t-states own (0.48 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu` |
| Calls | `UpdateRobot`, `UpdateShot`, `EnemyCommander` |
| Reads | `$D7D4`-`$D7F8` (`Shots+1`); `$DA01`-`$DCF1` (`work space $DA01+`) |

#### `UpdateRobot` (`$B0FA`)

**one robot's game turn: dying, destroyed or a step of its AI**

IY = the robot record. Strength +`$0C` decides: positive, the robot acts (RobotStep); negative, the robot is dying: +`$0C` counts up from `$FC` (set by MoveShot's hit) and the object bit 6 of its cell is toggled each turn (cleared on even values, set on odd), so for four turns other robots and shots see it only every other turn; 0, the robot is destroyed (RobotDestroyed). 49165 calls.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 67,216 calls, 2,689,172 t-states own (0.12 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 437 calls, 17,480 t-states own (0.02 %) |
| Called from | `WorldTurn` |
| Calls | `RobotStep` (tail) |
| Reads | `$DA0C`-`$DA3C` (`work space $DA0C+`); `$DB8C`-`$DCFC` (`work space $DB8C+`) |

#### `RobotStep` (`$B154`)

**a live robot: wait for its step delay, then look, fire, steer and move one step**

Entered from UpdateRobot with strength > 0 (JP P). A robot the player sits on (+`$0A` = 1, the robot menu is open) does nothing. Side (`$FD51`) = 0 ours / 1 the enemy's (+`$0A` bit 7), read by the target searches. The step delay +`$0F` counts the turns down; at 0 the robot leaves its cell (bit 6 cleared, radar dot erased) and FreeDirections gives C, the directions it can step to (bit 0 right, 1 left, 2 down, 3 up, the Input order).

Direct control (+`$0A` = 2): the stick decides (RobotDirectControl). Otherwise SpotEnemies gives E, the directions with a live opponent in sight. An opponent ahead (E AND the facing +`$08`): the robot moves on if it can and fires when a shot record of its side is free and its weapons allow (FindFreeShot, FireShot; a shot stops it for this step). An opponent to a side: it turns to it (+`$05` = that direction, one picked at random among several, +`$06` = 2). No opponent: it keeps its direction +`$05` for +`$06` more steps while that direction stays free, else it takes a new course for 3-6 steps from SteerByOrder (RobotNewCourse). RobotMove then turns or steps, reloads the delay (SetStepDelay) and puts the robot back on the map (PlaceRobot: the record's x/y/cell, bit 6, the dot).

Recording: 9652 steps; the shot records and strengths at frames 18680-18850 match FireShot and MoveShot (robot 2 hit twice by an enemy missile, 100 -> 70 -> 40; robot 25 hit by our cannon, 100 -> 80 -> 60 -> 40).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 67,216 calls, 16,089,072 t-states own (0.74 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 437 calls, 97,991 t-states own (0.10 %) |
| Called from | `UpdateRobot` (tail) |
| Calls | `SteerByOrder`, `TurnOrStep`, `CountDirections`, `FreeDirections`, `SetStepDelay`, `SpotEnemies`, `FindFreeShot`, `FireShot`, `PlaceRobot` (tail), `Random`, `ToggleRadarDot` |
| Reads | `$DA00`-`$DA3F` (`work space $DA00+`); `$DB80`-`$DCFF` (`work space $DB80+`); `$DF22`-`$DF3C` (`work space $DF22+`); `$DF67`-`$E53C` (`work space $DF67+`); `$E565`-`$E93C` (`work space $E565+`); `$E963`-`$EB3C` (`work space $E963+`); 3 more ranges |
| Writes | `$DA05`-`$DA3F` (`work space $DA05+`); `$DB85`-`$DCFF` (`work space $DB85+`); `$DF22`-`$DF3C` (`work space $DF22+`); `$DF67`-`$E53C` (`work space $DF67+`); `$E565`-`$E93C` (`work space $E565+`); `$E963`-`$EB3C` (`work space $E963+`); 4 more ranges |

#### `SteerByOrder` (`$B222`)

**C = the direction the robot's order wants, chosen among the free ones in C**

IY the robot, C the free directions (FreeDirections); out C a single direction bit, or 0 to stand. B keeps the free set. By the order +`$0B`:

0 stop: C = 0. 1 advance / 2 retreat: right / left (RobotLeanTo). When that direction is free: two random bits for it, else a random free one other than the opposite, which may be it again (0.835 with all four free, 0.88 with up or down blocked, 1.0 in a corridor; docs/13 13.3.2). When it is blocked: any free one, the opposite included. RobotStepPos counts the distance +`$0E`.

3 destroy robots: the target is the opponent robot of index +`$0E` (TargetRobotRecord). It is kept while it lives and is less than 50 columns away; else the nearest live opponent by column distance is taken (FindNearestOpponent), none: a random free direction.

4-8 the building orders: the target is record +`$0E` of the factory table `$FD84` or the warbase table `$FD70` (TargetBuildingTable). It is kept while its owner bits are still the ones the order looks for; else the nearest such building nobody of the side is already after is taken (FindTargetBuilding). None: the robot stands, and an enemy robot falls back to destroy robots.

The aim (RobotAim): D = the directions toward the target, horizontal from the sign of the column difference, vertical from the row difference; for a building, while the columns differ, the row aimed at is 3 below the building's row. More than 7 columns away (the low byte of the column difference only) the robot leans horizontally like an advance (RobotLeanTo): the target's row is ignored. Closer, one of the free wanted directions at random (none free: any free one); when a horizontal one is among them, +`$06` = |dx| - 1 for whichever is picked, a vertical one too. On the target (D = 0): the destroy orders 4-5 go to the nuclear charge at NuclearBlast (outside this range); the others turn the robot to face down and stand.

Bug (experiment, breakpoint at `$B2B8` after poking the target factory's owner): FindTargetBuilding leaves HL past the table, not on the new target, so the step right after a new building target aims at the bytes below `$FDFF` (the JP at `$FDFD` and Handler: row `$66`, column `$C300`; the warbase orders read factory 0's door). The wrong decision lasts a whole course of 3-6 steps: right from column 256 on; a random free direction on columns 14-255, rows 1-8; on columns 14-255, rows 9-15 the aim is "on the target": the robot faces down and stands, and a nuclear robot with order 4 blows up where it stands (NuclearBlast; experiment in docs/13 13.3.6). The next decision aims right.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4,619 calls, 2,969,527 t-states own (0.14 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 44 calls, 10,346 t-states own (0.01 %) |
| Called from | `RobotStep` |
| Calls | `FindTargetBuilding`, `ColumnDistance`, `TargetBuildingTable`, `TargetRobotRecord`, `FindNearestOpponent`, `CountDirections`, `AddAToHL`, `Random` |
| Reads | `$DA01`-`$DA3B` (`work space $DA01+`); `$DB82`-`$DCFE` (`work space $DB82+`); `$FD70`-`$FD73` (`work space $FD70+`); `$FD84`-`$FD8C` (`work space $FD84+`); `$FDAC`-`$FDFE` (`work space $FDAC+`) |
| Writes | `$DA2E` (`work space $DA2E+`); `$DB86`-`$DCFE` (`work space $DB86+`) |

#### `PickOneDirection` (`$B33E`)

**C = one direction bit picked at random from the set in B**

Masks C with random bytes until exactly one bit is left (CountDirections); when nothing is left it starts again from B. B must not be 0. The common exit of SteerByOrder's branches and used by RobotTurnToEnemy for several opponents.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `FindTargetBuilding` (`$B34D`)

**D = the nearest building the order wants and no teammate is after; Z when none**

A = the order (3 goes to FindNearestOpponent), HL = the robot's column, IY the robot, Side set. The order picks the table and owner (TargetBuildingTable); every record with those owner bits is offered to ConsiderBuilding, which skips it when a robot of our side with the same order already has it as its +`$0E`, and keeps the nearest by column distance (KeepNearest). Out D = the record's index (or `$FF`), A = D + 1 (Z: none). HL is left past the table: the cause of the bug noted at SteerByOrder. Recording: 112 calls (also from the enemy's order choice at `$B989` and SetOrder).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 108 calls, 94,289 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 6 calls, 5,931 t-states own (0.01 %) |
| Called from | `SetOrder`, `SteerByOrder`, `EnemyCommander` |
| Calls | `ConsiderBuilding`, `TargetBuildingTable`, `InitNearestSearch`, `FindNearestOpponent` (tail) |
| Reads | `$FD73`-`$FDFA` (`work space $FD73+`) |

#### `ConsiderBuilding` (`$B36C`)

**offer building C to KeepNearest unless a teammate with the same order already targets it**

HL = the record's owner byte (+`$03`), C its index, A' the order. Scans the 24 records of our side (`$DA00` ours, `$DB80` the enemy's by Side) for a live robot whose order +`$0B` is A' and whose target +`$0E` is C. None: the record's column (+`$00`/+`$01`) goes to KeepNearest. The robot that asks is in the list too; its +`$0E` holds its old target (or `$FF`).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 550 calls, 1,502,697 t-states own (0.07 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 51 calls, 131,694 t-states own (0.13 %) |
| Called from | `FindTargetBuilding` |
| Calls | `KeepNearest` |
| Reads | `$DA01`-`$DCFB` (`work space $DA01+`); `$FD51` (`work space $FD51+`); `$FD70`-`$FD71` (`work space $FD70+`); `$FD84`-`$FDF8` (`work space $FD84+`) |

#### `KeepNearest` (`$B3B3`)

**keep candidate C when the column HL is nearer to DE' than the best BC'**

The comparison step of the nearest searches (InitNearestSearch sets it up): HL' = |HL - DE'|, and when it is below BC' it becomes the best and D = C. Only the column distance counts; rows are ignored. A and HL' are lost; the main BC, E, HL and IY are kept. Called by ConsiderBuilding and FindNearestOpponent.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 12,068 calls, 1,154,233 t-states own (0.05 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 49 calls, 4,907 t-states own (0.00 %) |
| Called from | `ConsiderBuilding`, `FindNearestOpponent` |
| Calls | `ColumnDistance` |

#### `ColumnDistance` (`$B3CA`)

**HL = |HL - DE|**

HL, DE two columns (0-511). A 16-bit absolute difference: SBC HL,DE and, when the result's sign is set, 0 - HL. DE is kept; A = 0 on the positive path, the high byte's negation on the other. Used by KeepNearest and by SteerByOrder's 50-column test of a robot target.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 14,668 calls, 786,625 t-states own (0.04 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 49 calls, 2,172 t-states own (0.00 %) |
| Called from | `SteerByOrder`, `KeepNearest` |

#### `TargetBuildingTable` (`$B3D5`)

**HL, B, E = the building table, its size and the owner a building order wants**

A = the order. Orders 5 and 8 (destroy / capture warbases): HL = `$FD73`, the owner byte of the first of the 4 warbase records (Warbases `$FD70`, 5 bytes each), B = 4; the others: HL = `$FD87`, the owner byte of the first of 24 factory records (Factories `$FD84`), B = 24. E = the owner bits sought: `$20` (the computer's) for our robots, `$40` (ours) for the enemy's (Side = 1), 0 (neutral) for order 6, capture neutral factories.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1,440 calls, 197,835 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 16 calls, 2,167 t-states own (0.00 %) |
| Called from | `SteerByOrder`, `FindTargetBuilding`, `EnemyCommander` |
| Reads | `$FD51` (`work space $FD51+`) |

#### `TargetRobotRecord` (`$B3F9`)

**HL = the opponent robot record of index +`$0E`**

HL = `$DB80` + 16 * (+`$0E`) for our robots, `$DA00` + 16 * (+`$0E`) for the enemy's (Side). Used by SteerByOrder's destroy-robots branch.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 5,275 calls, 597,118 t-states own (0.03 %) |
| Called from | `SteerByOrder` |
| Reads | `$DA2E` (`work space $DA2E+`); `$DB8E`-`$DBEE` (`work space $DB8E+`); `$DC0E` (`work space $DC0E+`); `$DC3E`-`$DCBE` (`work space $DC3E+`); `$DCDE`-`$DCFE` (`work space $DCDE+`); `$FD51` (`work space $FD51+`) |

#### `InitNearestSearch` (`$B411`)

**start a nearest-by-column search from column HL**

DE' = HL (our column), BC' = `$2000` (no candidate yet), C = 0 (the first index), D = `$FF` (the result: none). Used by FindTargetBuilding and FindNearestOpponent with KeepNearest.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,699 calls, 170,075 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 14 calls, 882 t-states own (0.00 %) |
| Called from | `FindTargetBuilding`, `FindNearestOpponent` |

#### `FindNearestOpponent` (`$B41D`)

**D = the index of the nearest live opponent robot by column; Z when none**

HL = our column, IY the robot, Side set. Runs KeepNearest over the 24 opponent records (`$DB80` the enemy's for us, `$DA00` ours for the enemy) whose +`$01` is not 0 (a dying robot counts). Out D = the slot within the side (or `$FF`), A = D + 1 (Z: none); IY is kept, B ends 0 and C 24 (the callers keep BC), DE' / BC' / HL' are the search's. Called by SteerByOrder (order 3) and, through FindTargetBuilding with A = 3, by EnemyFindTarget and SetOrder. 426 calls.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,592 calls, 6,963,188 t-states own (0.32 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 8 calls, 19,688 t-states own (0.02 %) |
| Called from | `SteerByOrder`, `FindTargetBuilding` (tail) |
| Calls | `KeepNearest`, `InitNearestSearch` |
| Reads | `$DA01`-`$DCF3` (`work space $DA01+`); `$FD51` (`work space $FD51+`) |

#### `RobotDirectControl` (`$B450`)

**direct control: the stick steers the robot**

Reached from RobotStep for +`$0A` = 2 (not run in NE's deep recording nor in this part's; experiment below).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TurnOrStep` (`$B471`)

**turn the robot toward direction A, or step one cell when it faces it**

IY the robot, HL its column, B its row, A a direction bit (0: nothing). Facing +`$08` not A: the robot turns, never by 180 degrees in one go (right <-> left goes through down / up, down <-> up through right / left), and +`$06` is incremented so the turn does not shorten the course. Facing A: StepPosition moves HL/B, GroundUnderFootprint sets +`$0D`, and under direct control (+`$0A` = 2) MoveShip moves the ship by the same Input and the ship sits on the robot's top (Altitude = +`$09` + +`$0D`).

Experiment (DIRECT CONTROL on a new bipod + cannon robot at (22,14)): holding right the robot turned from facing down (4) to right (1) in one step and moved one column a step (6 turns, about 60 frames); after the release it went on one more step in the same direction; the ship moved with it and Altitude stayed 17 (bipod 11 + cannon 6, ground 0).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,050 calls, 2,545,389 t-states own (0.12 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 113 calls, 11,975 t-states own (0.01 %) |
| Called from | `RobotStep` |
| Calls | `StepPosition`, `GroundUnderFootprint` |
| Reads | `$DA06`-`$DA3A` (`work space $DA06+`); `$DB86`-`$DCFA` (`work space $DB86+`) |
| Writes | `$DA06`-`$DA3D` (`work space $DA06+`); `$DB86`-`$DCFD` (`work space $DB86+`) |

#### `StepPosition` (`$B4B9`)

**move HL (column) / B (row) one cell in direction A; advance / retreat count their distance**

A bit 0 right (HL+1), 1 left (HL-1), 2 down (B+1), 3 up (B-1). For the orders 1 advance and 2 retreat (not under direct control) +`$0E` is the distance still to go: a column in the order's direction (right for advance, left for retreat) takes one off and at 0 the order becomes 0 stop (+`$06` = 0); a column the other way adds one, up to `$63`.

Experiment: ADVANCE with 5 MILES (the robot menu stores miles * 2 into +`$0E` = 10): the robot went 4 columns right (+`$0E` 10 -> 6), 5 rows up round an obstacle (+`$0E` unchanged), 6 more columns right and then stood with order 0 and +`$0E` = 0.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 14,033 calls, 1,044,533 t-states own (0.05 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 68 calls, 4,699 t-states own (0.00 %) |
| Called from | `TurnOrStep` |
| Reads | `$DA0B`-`$DA2B` (`work space $DA0B+`); `$DB8B`-`$DCFB` (`work space $DB8B+`) |

#### `CountDirections` (`$B505`)

**flags of (the number of set bits in C's low nibble) - 1**

Z: exactly one direction; carry: none; neither: two or more. Counts bits 0-3 of C, keeps BC.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9,987 calls, 1,558,428 t-states own (0.07 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 85 calls, 13,260 t-states own (0.01 %) |
| Called from | `RobotStep`, `SteerByOrder`, `EnemyCommander` |

#### `FreeDirections` (`$B513`)

**C = the directions the robot at cell HL may step to**

IY the robot, HL its anchor cell. A robot covers 2x2 cells: its anchor (X, Y) carries the object bit 6, plus (X+1, Y), (X, Y-1), (X+1, Y-1). D = the first terrain type it cannot enter, by its locomotion: bipod 8 (types 0-7, ground heights 0-3), tracks `$0C` (also 8-`$0B`, height 6), anti-grav `$0F` (also `$0C-$0E`, height 0 in TerrainHeights); the types from `$0F` (heights 7 and 15) stop all. E = the bits that block: 6 (objects) always, 7 (the ship's cell) when the ship hangs lower than the robot's top. One probe a direction (CanMoveRight, CanMoveLeft, CanMoveDown, CanMoveUp); bit 0 right, 1 left, 2 down, 3 up. 9652 calls.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,050 calls, 7,105,241 t-states own (0.33 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 113 calls, 39,959 t-states own (0.04 %) |
| Called from | `RobotStep` |
| Calls | `CanMoveRight`, `CanMoveLeft`, `CanMoveDown`, `CanMoveUp` |
| Reads | `$DA07`-`$DA3D` (`work space $DA07+`); `$DB87`-`$DCFD` (`work space $DB87+`); `$FD10` (`work space $FD10+`) |

#### `CanMoveRight` (`$B557`)

**Z when the robot at HL can step right**

Terrain and objects at the column it enters, (X+2, Y-1) and (X+2, Y); an object anchored at (X+2, Y+1) (its footprint would overlap) when that row exists.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,050 calls, 2,084,392 t-states own (0.10 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 113 calls, 11,540 t-states own (0.01 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `TestCell` |
| Reads | `$E124`-`$E323` (`work space $E124+`); `$E369`-`$E712` (`work space $E369+`); `$E767`-`$E912` (`work space $E767+`); `$E967`-`$EB23` (`work space $E967+`); `$EB65`-`$ECB3` (`work space $EB65+`); `$ED65`-`$EF11` (`work space $ED65+`); 2 more ranges |

#### `CanMoveLeft` (`$B56F`)

**Z when the robot at HL can step left**

Terrain and objects at (X-1, Y-1) and (X-1, Y); objects anchored at (X-2, Y-1), (X-2, Y) and (X-2, Y+1).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,050 calls, 2,651,261 t-states own (0.12 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 113 calls, 15,914 t-states own (0.02 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `TestCell` |
| Reads | `$DD20`-`$DD3A` (`work space $DD20+`); `$DD65`-`$E13A` (`work space $DD65+`); `$E182`-`$E33A` (`work space $E182+`); `$E364`-`$F13A` (`work space $E364+`); `$F156`-`$FCEC` (`work space $F156+`) |

#### `CanMoveDown` (`$B58F`)

**Z when the robot at HL can step down**

Blocked at the bottom row; terrain and objects at (X, Y+1) and (X+1, Y+1); objects anchored at (X+1, Y+2), (X, Y+2) and (X-1, Y+2) when that row exists.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,050 calls, 2,131,117 t-states own (0.10 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 113 calls, 14,353 t-states own (0.01 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `CellBlocked` (tail), `TestCell` |
| Reads | `$E321`-`$E33D` (`work space $E321+`); `$E366`-`$E93D` (`work space $E366+`); `$E964`-`$ED3D` (`work space $E964+`); `$ED62`-`$EF3D` (`work space $ED62+`); `$EF62`-`$F13D` (`work space $EF62+`); `$F157`-`$F33B` (`work space $F157+`); 1 more ranges |

#### `CanMoveUp` (`$B5B1`)

**Z when the robot at HL can step up**

Blocked when Y-2 is above the map (the footprint already covers Y-1); an object anchored at (X-1, Y-2), terrain and objects at (X, Y-2) and (X+1, Y-2).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,050 calls, 1,952,043 t-states own (0.09 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 113 calls, 12,274 t-states own (0.01 %) |
| Called from | `FreeDirections` |
| Calls | `CellBlocked` (tail), `TestCell` |
| Reads | `$DD0F`-`$DD3B` (`work space $DD0F+`); `$DD66`-`$DF3B` (`work space $DD66+`); `$DF66`-`$E13B` (`work space $DF66+`); `$E164`-`$E53B` (`work space $E164+`); `$E562`-`$E73B` (`work space $E562+`); `$E762`-`$E93B` (`work space $E762+`); 1 more ranges |

#### `CellOffMapFree` (`$B5C8`)

**Z: a probe that runs past the bottom row finds the way free**

The shared exit of the probes for rows below the map.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9,610 calls, 134,578 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 63 calls, 882 t-states own (0.00 %) |
| Called from | `CanMoveRight` (tail), `CanMoveLeft` (tail), `CanMoveDown` (tail) |

#### `CellBlocked` (`$B5CA`)

**NZ: the way is blocked**

The shared exit for an unpassable terrain type or a map edge.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 23,694 calls, 402,855 t-states own (0.02 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 91 calls, 1,547 t-states own (0.00 %) |
| Called from | `CanMoveDown` (tail), `CanMoveUp` (tail), `TestCell` (tail) |

#### `TestCell` (`$B5CD`)

**Z when cell HL is passable: type below D and none of the bits E**

HL a map cell, D the first terrain type the locomotion cannot enter (FreeDirections), E the blocking bits (`$40` objects, plus `$80` the ship's cell when the ship hangs lower than the robot's top). NZ through CellBlocked when the type (bits 0-4) is D or more; else A = the cell AND E (Z: free). HL kept. Used by the four CanMove probes for the cells the footprint enters; the cells only checked for anchors use AND E directly. 67380 calls.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 126,649 calls, 5,590,994 t-states own (0.26 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 775 calls, 34,642 t-states own (0.03 %) |
| Called from | `CanMoveRight`, `CanMoveLeft`, `CanMoveDown`, `CanMoveUp` |
| Calls | `CellBlocked` (tail) |
| Reads | `$DD10`-`$DD3E` (`work space $DD10+`); `$DD66`-`$E33E` (`work space $DD66+`); `$E364`-`$E53E` (`work space $E364+`); `$E563`-`$E73E` (`work space $E563+`); `$E762`-`$E93E` (`work space $E762+`); `$E958`-`$EB3E` (`work space $E958+`); 1 more ranges |

#### `GroundUnderFootprint` (`$B5D6`)

**A = the highest ground under the 2x2 footprint anchored at (HL, B)**

HL a column, B a row. TerrainTop over (X, Y), (X+1, Y), (X+1, Y-1), (X, Y-1), the highest kept in C; HL and BC are kept, DE is lost (the last cell). The robots' +`$0D` (the ground they stand on: SetStepDelay's row, the drawing height, the ship's seat under direct control) and the shots' wall test (MoveShot against +`$08` = `$0A`).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 14,108 calls, 2,483,977 t-states own (0.11 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 68 calls, 11,968 t-states own (0.01 %) |
| Called from | `TurnOrStep`, `MoveShot` |
| Calls | `TerrainTop`, `MapCell` |

#### `SetStepDelay` (`$B5F3`)

**+`$0F` = the turns until the robot's next step, by the ground and its locomotion**

The ground class from +`$0D`: 0 flat, 1-3 low, 4 and more high; the column from the lowest set part bit of +`$07`: 0 bipod, 1 tracks, 2 anti-grav. StepDelays gives the turns. The recorded records agree (robot 0, a bipod on flat ground, counts 6 down).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,050 calls, 4,693,475 t-states own (0.22 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 113 calls, 25,495 t-states own (0.03 %) |
| Called from | `RobotStep` |
| Calls | `AddAToHL` |
| Reads | `$B61D`-`$B625` (`StepDelays`); `$DA07`-`$DA3D` (`work space $DA07+`); `$DB87`-`$DCFD` (`work space $DB87+`) |
| Writes | `$DA0F`-`$DA3F` (`work space $DA0F+`); `$DB8F`-`$DCFF` (`work space $DB8F+`) |

#### `SpotEnemies` (`$B626`)

**E = the directions in which a live opponent robot is in sight**

IY the robot. For each direction (up, down, left, right: E's bits 3, 2, 1, 0 as in Input) ScanLane looks from the robot's anchor up to 8 cells; in the facing direction +`$08` the range is 10, 12 with electronics (+`$07` bit 7), and three parallel lanes are scanned (the columns X-1, X, X+1 for up / down, the rows Y-1, Y, Y+1 for left / right). 9652 calls.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,050 calls, 12,999,115 t-states own (0.60 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 113 calls, 73,159 t-states own (0.07 %) |
| Called from | `RobotStep` |
| Calls | `ScanLane` |
| Reads | `$DA00`-`$DA38` (`work space $DA00+`); `$DB80`-`$DCF8` (`work space $DB80+`) |

#### `ScanLane` (`$B66E`)

**set E bit 0 when a live opponent's anchor lies within B cells from HL in direction D**

The step comes from LaneSteps by D's bit. The scan stops at the map's top or bottom edge and at the first cell with an object (bit 6): only a robot of the other side (+`$0A` bit 7 differs) with strength above 0 sets the bit. Buildings, shots and friends block the view. HL, DE are kept apart from E's bit 0.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 120,300 calls, 83,016,050 t-states own (3.82 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 678 calls, 430,485 t-states own (0.43 %) |
| Called from | `SpotEnemies` |
| Calls | `FindRobot` |
| Reads | `$B6B0`-`$B6B7` (`LaneSteps`); `$DA0A`-`$DA3C` (`work space $DA0A+`); `$DB8A`-`$DD46` (`work space $DB8A+`); `$DD58`-`$DF46` (`work space $DD58+`); `$DF58`-`$FCFA` (`work space $DF58+`) |

#### `FindFreeShot` (`$B6B8`)

**IY = a free shot record of the shooter IX's side; Z when one is free**

Each side has two shot records of 9 bytes: ours `$D7DC` and `$D7E5`, the enemy's `$D7EE` and `$D7F7` (by IX +`$0A` bit 7). Z with IY on the first one whose +`$01` is 0; NZ when both fly. Record 0 (`$D7D3`) is not handed out here: it is the player's COMBAT MODE shot, launched from the robot menu (DirectControl, not in NE's recording).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 61 calls, 5,560 t-states own (0.00 %) |
| Called from | `RobotStep` |
| Reads | `$D7DD` (`Shots+10`); `$D7EF` (`Shots+28`); `$DA2A` (`work space $DA2A+`); `$DB9A` (`work space $DB9A+`) |

#### `FireShot` (`$B6D6`)

**launch shot IY of weapon A from robot IX in its facing direction**

Called by RobotStep and by COMBAT MODE in the robot menu (DirectControl, IX = IY = the robot, record 0). Shot record (9 bytes): +`$00`/+`$01` the map cell, +`$02`/+`$03` the column, +`$04` the row, +`$05` the direction, +`$06` the steps left, +`$07` the weapon (1 cannon, 2 missiles, 3 phasers), +`$08` the ground height that stops it (`$0A`). The range is 5 steps (7 for missiles), one more with electronics; each step goes 2 cells. The first step is taken at once (MoveShot), from the shooter's anchor: in RobotStep the shooter is already off the map (bit 6 cleared), so it cannot hit itself.

When the shot survives the first step SoundFx (`$FD53`) = 1, the firing sound; when it ends at once, MoveShot's sound (`$FC`, `$FA` or `$C8`) stays. Recording: an enemy missile at frame 18680, D7EE: 7B F3 7B 00 0B 08 06 02 0A (column `$7B`, row 11, up, 6 steps left after the first turn, missiles).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 47 calls, 13,216 t-states own (0.00 %) |
| Called from | `RobotStep` |
| Calls | `MoveShot` |
| Reads | `$D7DD` (`Shots+10`); `$D7EF` (`Shots+28`); `$DA22`-`$DA28` (`work space $DA22+`); `$DB92`-`$DB98` (`work space $DB92+`) |
| Writes | `$D7E1`-`$D7F6` (`Shots+14`); `$FD53` (`work space $FD53+`) |

#### `UpdateShot` (`$B70D`)

**one game turn of shot IY: off its cell, count its range, a step**

Clears the object bit of the shot's cell, counts +`$06` down (0: the shot is gone, ShotGone) and goes on into MoveShot from its column / row. 90 calls in NE's deep recording.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 28 calls, 4,023 t-states own (0.00 %) |
| Called from | `WorldTurn` |
| Calls | `MoveShot` |
| Reads | `$D7EE`-`$D7F4` (`Shots+27`); `$F73C` (`work space $F73C+`) |
| Writes | `$D7F4` (`Shots+33`); `$F73C` (`work space $F73C+`) |

#### `MoveShot` (`$B724`)

**move shot IY 2 cells, then hit a wall, an object or fly on**

IY the shot record, HL its column, B its row. One step: 2 cells in +`$05`. Off the rows 0-15 (only tested for down / up; the columns are not range-checked), or ground of height +`$08` (`$0A`) or more under its 2x2 footprint (only the types `$10` / `$12`, height 15; heights up to 7 let it pass): gone (ShotGone, SoundFx `$FC`). The new position and cell go into +`$00`-+`$04`.

Then the 3x3 cells around the new cell are tested for an object (bit 6), row Y-1 and Y+1 only inside the map; none: the shot marks its own cell with bit 6 and flies on. An object that is a live robot (either side: friendly fire is possible) takes damage ((60 - its top) / 4) * (weapon + 1), the top being +`$09` + +`$0D`, so tall robots on high ground take less: strength 0 or below makes it `$FC` (dying, UpdateRobot) with SoundFx `$C8`, else SoundFx `$FA`. Any other object (a building, another shot, a dying robot) just ends the shot (SoundFx `$FC`). Either way the record is freed (+`$01` = 0, the other bytes stay).

The recorded hits agree: a missile (2) into a 19 high robot takes 10 * 3 = 30, a cannon shell 10 * 2 = 20. Entered from UpdateShot (falling through) and FireShot.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 75 calls, 26,930 t-states own (0.00 %) |
| Called from | `FireShot`, `UpdateShot` |
| Calls | `GroundUnderFootprint`, `ShotGone` (tail), `MapCell` |
| Reads | `$D7E1`-`$D7F6` (`Shots+14`); `$F53B`-`$F53D` (`work space $F53B+`); `$F73B`-`$F73D` (`work space $F73B+`); `$F93B`-`$F93D` (`work space $F93B+`) |
| Writes | `$D7DE`-`$D7F2` (`Shots+11`); `$F73C` (`work space $F73C+`) |

#### `ShotGone` (`$B7EA`)

**out of range or off the map: the shot is gone with the short sound**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 47 calls, 2,303 t-states own (0.00 %) |
| Called from | `MoveShot` (tail) |
| Writes | `$D7DD` (`Shots+10`); `$D7EF` (`Shots+28`); `$FD53` (`work space $FD53+`) |

### enemy

`src/game98/enemy.asm`

#### `EnemyCommander` (`$B7F4`)

**once a game turn the computer looks at one of its 24 robot slots: builds a robot in a free one or re-thinks a robot's order**

Called first by WorldTurn. A random number 0-31 picks the slot; 24-31 (a quarter of the turns) do nothing. Side = 1. The slot's record is `$DB80` + 16 * n.

A live robot goes to EnemyReplan: one with order 0 at once, any other with a 1/32 chance a turn, gets a new order (EnemyChooseOrder: a nuclear robot destroy factories or warbases, the others one of the capture orders; destroy robots when the order finds no target). Orders 4-8 are kept only while the target has changed owner and the robot stands on its door: the capture under way.

A free slot tries a build at a random enemy warbase (owner `$20` in the Warbases table) whose door and the three cells below it are free of bit 6: random parts (exactly one locomotion, at least one and not all four of the weapon / nuclear parts, at least 1, 2 or 3 of those parts while the computer has 0-7, 8-15 or 16-23 robots, EnemyRobotCount `$FD49`), paid from EnemyResources (`$FD4A`, through MenuResources and PartCosts like the player's), the shortfall of the other resources taken from the general one, at most half of it (at least 11). A refused design is not retried: the slot waits for another turn.

The robot is set up facing down, 3 steps, order 0, strength `$64`, +`$0A` = `$80`, +`$0E` = `$FF`, +`$0F` = 1, height +`$09` the sum of the part heights `$D7B4` (bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7); then CountRobots and UpdateStatusPanel. IY is left on the slot's record; A, BC, DE, HL and the alternate HL', B' lost. 3415 calls in NE's deep recording.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,693 calls, 652,722 t-states own (0.03 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 51,267 t-states own (0.05 %) |
| Called from | `WorldTurn` |
| Calls | `FindTargetBuilding`, `TargetBuildingTable`, `CountDirections`, `CountRobots`, `PlaceRobot`, `MapCell`, `UpdateStatusPanel`, `AddAToHL`, `Random` |
| Reads | `$CAF0`-`$CAFF` (`PartCosts`); `$D7B4`-`$D7BB` (`PartHeights`); `$DB81`-`$DCFB` (`work space $DB81+`); `$F21D` (`work space $F21D+`); `$F2E8` (`work space $F2E8+`); `$F41C`-`$F41E` (`work space $F41C+`); 7 more ranges |
| Writes | `$DB85`-`$DCFF` (`work space $DB85+`); `$FD29`-`$FD2F` (`work space $FD29+`); `$FD4A`-`$FD51` (`work space $FD4A+`) |

#### `NuclearBlast` (`$B99F`)

**NuclearBlast**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `NuclearFlash` (`$BA87`)

**The nuclear blast's flash: the view's paper flickers through random colours with a fading rumble**

Called only by the blast (`$BA76`). Saves the 20 x 20 attributes of the view (from `$5821`, row 1 column 1) to `$5B00-$5C8F`, then 61 times: a burst of noise (`$BAEE`, 244 samples first, 4 fewer and a longer delay each time) and a new random paper colour (2-7, never the previous one) on every attribute of the view whose paper is not black. Restores the saved attributes at the end. The flash lasts 216 frames (4.3 s, measured; NE's docs/10-gameplay-logic.md 10.9); the game stands still meanwhile.

Verified by an experiment (own instance, PC set to `$B99F` with a poked nuclear robot): the run passes here after the bases and robots are hit. `$5B00` is free scratch at that time (the printer buffer and above, also the save checksum of `$C2E8`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `NuclearRumble` (`$BAEE`)

**One burst of the blast's noise: B samples of ROM bytes to the speaker, C the delay between**

Plays B samples: bit 4 (the speaker) of the ROM bytes from `$0090` on, the border black, with a delay loop of C x 24 T-states after each. Returns B - 3 and C + 3, so the next burst of NuclearFlash is shorter and lower: a dying rumble. Only NuclearFlash calls it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### bases

`src/game98/bases.asm`

#### `CountBases` (`$BB09`)

**Count each side's bases: warbases and the factories of each type**

Clears PlayerBuildings (`$FD3A`, 7 counts) and EnemyBuildings (`$FD42`, 7) and goes through the 28 base records (`$FD70`, 5 bytes, read at +3): a base whose +3 has bit 6 counts for the player, bit 5 for the enemy, at index +3 bits 0-2 (0 warbases, 1-6 the factories of type 1-6: electronics, nuclear, phasers, missiles, cannon, chassis, the resource each makes); neutral and destroyed (bit 7) bases do not count. PlayerRobotCount (`$FD41`) between the two count blocks is skipped. The status panel shows these counts (`$D2C1`); the daily production (`$AE38`) adds 5 general per warbase and 2 per factory to its resource; a side with no warbase loses (`$AE6B`).

Called after every change of owner (the capture tick `$AE17`), after the blast (`$BA81`), and by the map builder (`$BCCA`). Ran 18 times in NE's deep recording. A, B, DE, HL lost.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9 calls, 32,220 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 3,460 t-states own (0.00 %) |
| Called from | `GameTurnEnd`, `BuildMap` |
| Calls | `AddAToHL` |
| Reads | `$FD3A`-`$FD48` (`work space $FD3A+`); `$FD73`-`$FDFA` (`work space $FD73+`) |
| Writes | `$FD3A`-`$FD48` (`work space $FD3A+`) |

#### `CountRobots` (`$BB40`)

**PlayerRobots (`$FD41`) and EnemyRobots (`$FD49`): the live records of each side**

Counts the robot records whose +1 (the map cell's high byte) is not 0: slots 0-23 into PlayerRobots, slots 24-47 into EnemyRobots. The status panel shows them (the ROBOTS line); the enemy's factory (`$B86F`) builds better-armed robots as its count grows. Called after each birth and death of a robot.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 28 calls, 2,240 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 7 calls, 560 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `EnemyCommander` |
| Calls | `CountLiveRobots` |
| Writes | `$FD41`-`$FD49` (`work space $FD41+`) |

#### `CountLiveRobots` (`$BB50`)

**A = the live records among 24 robot records from HL (+1 not 0); HL moves past them**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 56 calls, 64,648 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 14 calls, 16,226 t-states own (0.02 %) |
| Called from | `CountRobots` |
| Reads | `$DA01`-`$DCF1` (`work space $DA01+`) |

#### `GiveFactory` (`$BB61`)

**Factory A (0-23) changes hands: to the player (B = 0) or the enemy (B = 1); its flag moves**

Sets the factory's owner bits (`$BBB9`), removes the flag buildings at both sides of its roof (the cells x-2 and x+2 of row y-2) and puts the new owner's flag: type 7 (the player's) at x-2, type 8 (the enemy's) at x+2. The factory's own building (type 1-6 at x, y-2) stays.

Called by the capture tick (`$AE01`) when a robot has stood on the factory's door for 144 ticks. Ran 17 times in NE's deep recording (captures by both sides).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 8 calls, 1,520 t-states own (0.00 %) |
| Called from | `GameTurnEnd` |
| Calls | `SetBaseOwner`, `AddBuilding`, `RemoveBuilding` |

#### `GiveWarbase` (`$BB86`)

**Warbase A (0-3) changes hands: to the player (B = 0) or the enemy (B = 1)**

Sets the owner bits (`$BBB9`) and rebuilds the warbase's buildings on its pad row y-4: removes those at x-4, x and x+4, then for the player puts the landing pad (type 0, x) and the player's flag (type 7, x-4); for the enemy only its flag (type 8, x+4). So a captured warbase gives the player a second pad where the construction menu opens.

Called by the map builder (`$BCB3-$BCC7`: warbase 0 the player's, 1-3 the enemy's) and by the capture tick (`$ADF9`). In NE's deep recording only the four set-up calls ran.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 666 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 4 calls, 666 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `SetBaseOwner`, `AddBuilding` (tail), `RemoveBuilding` |

#### `SetBaseOwner` (`$BBB9`)

**Base record A (HL = the table's +3 bytes): owner = the player (B = 0) or the enemy; HL = its door cell**

HL is `$FD73` (warbases) or `$FD87` (factories). Replaces bits 5-7 of the base's +3 with `$40` (the player) or `$20` (the enemy), which also clears the destroyed bit 7. Falls into BaseCell: HL = the map cell of the base's (x, y), its door.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 12 calls, 1,741 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 4 calls, 581 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` |
| Calls | `MapCell` (tail), `AddAToHL` |
| Reads | `$FD70`-`$FD82` (`work space $FD70+`); `$FDC5`-`$FDEB` (`work space $FDC5+`) |
| Writes | `$FD73`-`$FD82` (`work space $FD73+`); `$FDC8`-`$FDEB` (`work space $FDC8+`) |

#### `DestroyFactory` (`$BBD8`)

**Factory A (0-23) destroyed by a nuclear blast: buildings removed, blocks turned to debris**

Marks the factory destroyed (`$BC1C`), removes its three buildings on the roof row y-2 (the flags at x+2 and x-2 and the factory at x) and draws the factory's shape (ShapeFactory) again in debris: every block a random tile 6 or 7. Verified by an experiment: factory 0 at (39,6) became `$80`, its building at (39,4) went and its blocks became tiles 6 / 7.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DestroyWarbase` (`$BBF9`)

**Warbase A (0-3) destroyed by a nuclear blast: buildings removed, blocks turned to debris**

Marks the warbase destroyed (`$BC1C`), removes the buildings at x-4, x and x+4 of its pad row y-4 and redraws ShapeWarbase in debris (tiles 6 / 7). Verified by an experiment: warbase 1 at (261,8) became `$80`, its flag building at (265,4) went, the enemy's warbase count fell from 3 to 2 and its walls became debris.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MarkBaseDestroyed` (`$BC1C`)

**Base A of the table HL (+3 bytes): +3 = `$80` (destroyed, no owner); HL = its door cell**

A = the base's index in its table, HL = the table's +3 bytes (Warbases+3 or Factories+3). Writes `$80` to the base's +3: destroyed, no owner, type bits 0; CountBases does not count it and no order's owner bits match it, so no order targets it again. The capture tick (CaptureLoop) does not test bit 7, though: from the code, a robot standing 144 turns on the door would give it an owner again (SetBaseOwner clears bit 7) with type 0, a warbase; never seen. Goes on into BaseCell: HL = the base's door cell, A = its row. Used by DestroyFactory and DestroyWarbase.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `AddBuilding` (`$BC43`)

**Add a building: map cell HL, type C (0 pad, 1-6 factory, 7 the player's flag, 8 the enemy's flag)**

Takes the first free record of Buildings (56 x 3 bytes: the cell, the type; a high byte 0 = free), writes the cell and the type, and sets bit 6 of the map cell. With all 56 records taken it does nothing. The buildings are what the ship stands on (their heights by type at `$B0C1`: pad 15, factories 21-22, flags 25) and where landing opens the construction menu (type 0).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 37 calls, 36,778 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 29 calls, 23,142 t-states own (0.02 %) |
| Called from | `GiveFactory`, `GiveWarbase` (tail), `PlaceBases` |
| Reads | `$DFA7`-`$E0C6` (`work space $DFA7+`); `$E326`-`$E3F7` (`work space $E326+`); `$EA21` (`work space $EA21+`); `$EAEC`-`$EB9B` (`work space $EAEC+`); `$EC70`-`$EC7E` (`work space $EC70+`); `$F06A`-`$F116` (`work space $F06A+`); 3 more ranges |
| Writes | `$DFA7`-`$E0C6` (`work space $DFA7+`); `$E326`-`$E3F7` (`work space $E326+`); `$EA21` (`work space $EA21+`); `$EAEC`-`$EB9B` (`work space $EAEC+`); `$EC70`-`$EC7E` (`work space $EC70+`); `$F06A`-`$F116` (`work space $F06A+`); 3 more ranges |

#### `RemoveBuilding` (`$BC5D`)

**Remove the building on map cell HL, if any: its record freed, bit 6 of the cell cleared**

Keeps IY and BC. Uses FindBuilding.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 28 calls, 2,492 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 12 calls, 1,068 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` |
| Calls | `FindBuilding` |

#### `BuildMap` (`$BC6F`)

**A new game's map: clear it, place the scenery and the 28 bases, give the warbases their owners**

Called once by the new game set-up (`$A68B`). Clears the map `$DD00-$FCFF` and the radar bitmap `$D800-$D8FF`, places the scenery lists SceneryWest (columns 0-255) and SceneryEast (256-511), then the bases BaseListWest and BaseListEast (records into `$FD70`: 4 warbases, 24 factories, all neutral), gives warbase 0 to the player and warbases 1-3 to the enemy, counts the bases, marks the radar for a rebuild and puts the ship on the map (`$B024`).

The resulting '98 map: the player's warbase at (22,14), the enemy's at (285,10), (412,14), (488,10); 24 factories: 2 nuclear, 5 chassis, 5 phasers, 4 each of electronics, missiles and cannon (NE: the warbases at (22,9), (261,8), (369,8), (494,8), four factories of each type). The terrain types of the deep recording's live map after 9 game days are the ones these lists give, cell for cell (work/stage2/game98/mapreach.py rebuilds the map from the level bytes).

LoadNewLevel (`$C23B`) writes the operands of the four list loads here, `$BC8A`, `$BC92`, `$BCA2` and `$BCAA`, with the words it finds at `$DEF4-$DEFB`; in the '98 nothing has read a level there, so a following new game builds its map from whatever those words point at (mainmenu, LoadNewLevel).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 177,825 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 177,825 t-states own (0.18 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 177,516 t-states own (0.60 %) |
| Called from | `Start`, `NewGameSetup` |
| Calls | `PutShipOnMap`, `CountBases`, `GiveWarbase`, `PlaceScenery`, `PlaceBases` |
| Reads | `$D800`-`$D8FE` (`RadarOwn`, `work space $D880+`); `$DD00`-`$FCFE` (`work space $DD00+`) |
| Writes | `$D800`-`$D8FF` (`RadarOwn`, `work space $D880+`); `$DD00`-`$FCFF` (`work space $DD00+`); `$FD52` (`work space $FD52+`) |

#### `PlaceScenery` (`$BCD6`)

**Place a scenery list at HL (3-byte records: tile or shape, x low, y; 0 ends), D = x high byte**

A record with bit 7 clear is one 2 x 2 block of that tile (`$BD91`), with bit 7 set the shape of that index (`$BD61`). The cell is `$DD00` + `$200` * y + D * 256 + x.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2 calls, 24,224 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 2 calls, 24,224 t-states own (0.02 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 4,446 t-states own (0.01 %) |
| Called from | `BuildMap` |
| Calls | `DrawShape`, `PutBlock` |
| Reads | `$BDA9`-`$BF45` (`SceneryWest`, `SceneryEast`) |

#### `PlaceBases` (`$BCF9`)

**Place a bases list at HL (3-byte records: type, x low, y; `$FF` ends), D = x high byte**

Type 0: a warbase. Its record goes to IX (the warbases' table) and ShapeWarbase is drawn from the cell. Type 1-6: a factory of that type. Its record goes to IY (the factories' table), ShapeFactory is drawn and the factory's building (that type) is added two rows up, at (x, y-2). A record: +0/+1 x, +2 y, +3 the type (the owner bits come later), +4 0 (the capture counter).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2 calls, 11,020 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 2 calls, 11,020 t-states own (0.01 %) |
| Called from | `BuildMap` |
| Calls | `AddBuilding`, `DrawShape` |
| Reads | `$BF46`-`$BF9B` (`BaseListWest`, `BaseListEast`) |
| Writes | `$FD70`-`$FDFB` (`work space $FD70+`) |

#### `DrawShape` (`$BD61`)

**Draw shape A (bit 7 ignored, the index into ShapeTable) from map cell HL**

A shape is a list of 3-byte steps: a tile (0 = none) drawn as a 2 x 2 block at the current cell, then the move to the next cell: columns (signed), rows (signed); a move of (0,0) ends after its tile. DrawRuins (`$BC27`) walks the same lists with debris tiles.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 90 calls, 65,796 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 90 calls, 65,796 t-states own (0.07 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 2 calls, 160,790 t-states own (0.54 %) |
| Called from | `PlaceScenery`, `PlaceBases` |
| Calls | `StepCell`, `PutBlock`, `TableWord` |
| Reads | `$BFB2`-`$C083` (`ShapeWarbase`, `ShapeFactory`, `ShapeLowTiles`, `ShapeMidTiles` and 6 more) |

#### `StepCell` (`$BD7F`)

**HL += C columns (signed) and B rows (signed: H += 2 * B); DE kept**

HL a map cell, C the columns (signed), B the rows (signed). HL += C sign-extended, then H += 2 * B (a map row is `$200` bytes). DE kept, A lost. The move of one shape step for DrawShape and DrawRuins.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 502 calls, 44,108 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 502 calls, 44,108 t-states own (0.04 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1,529 calls, 137,282 t-states own (0.46 %) |
| Called from | `DrawShape` |

#### `PutBlock` (`$BD91`)

**A 2 x 2 block of tile A with its bottom left at map cell HL**

Writes the cells (x, y), (x+1, y), (x, y-1), (x+1, y-1): the first with the tile as it is, the other three with bit 5 set (the other parts of a block; the drawing and the blast take only the cell with bit 5 clear). Keeps HL and DE; BC is lost. Used by the map builder, the ruins, the blast and a dead robot's wreck (`$B133`).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 636 calls, 202,998 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 636 calls, 202,998 t-states own (0.20 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1,532 calls, 488,888 t-states own (1.64 %) |
| Called from | `PlaceScenery`, `DrawShape` |
| Writes | `$4030`-`$4C3B` (screen); `$4C6F`-`$4F54` (screen); `$4FAF`-`$4FDA` (screen); `$5054`-`$506B` (screen); `$50C1`-`$7FF9` (`Font`, `SprTracksX`, `SprTracksXRows`, `SprTracksXOdd` and 57 more); `$8022`-`$BFF6` (`SprPhasersYmOddRows+104`, `SprNuclear`, `SprNuclearRows`, `SprNuclearOdd` and 262 more); 1 more ranges |

### mainmenu

`src/game98/mainmenu.asm`

#### `MainMenu` (`$C100`)

**The main menu: clear the screen, the title, the options; Z = start a new game**

Called by Start (`$A62A`); Start goes on to the new game set-up on Z (`$A62D`; the NZ path to play, NE's loaded game, is never taken: no key returns NZ). Prints the title (PrintTitle) and the options 0-5; the current controls (Controls, `$D3E4`) show in cyan, the others in yellow (`$C336`). Then MainMenuKeys. Keys 1-3 choose the controls and redraw the options, 4 redefines the keys and redraws the whole menu, 5 runs LoadNewLevel (which ends in JP Start, not back here), 0 starts.

Witness: r98 frame 4800 (work/stage2/game98/menu4800.png): ZS EDITION'98, 0..START GAME, 1..KEYBOARD (cyan), 2..KEMPSTON J/S, 3..INTERFACE 2, 4..REDEFINE KEYS, 5..LOAD NEW LEVEL!; game98/play ran it once (frame 4500), game98/key5menu twice (the second after LoadNewLevel's JP Start).

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 51 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 51 t-states own (0.00 %) |
| Called from | `Start` |
| Calls | `PrintTitle`, `ClearScreen`, `PrintInline` |

#### `MainMenuTitle` (`$C103`)

**The main menu without the clearing: the title, then the options**

The entry of MainMenu after ClearScreen; nothing jumps here (MainMenuKeys key 4 jumps to MainMenu itself). Falls into MainMenuOptions.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MainMenuOptions` (`$C106`)

**The main menu's options (re-entered after keys 1-3)**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 17 t-states own (0.00 %) |
| Called from | `MainMenuKeys` (tail) |
| Calls | `PrintInline` |

#### `MenuKeyboardOption` (`$C120`)

**Option 1, KEYBOARD, in the colour of Controls 1**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 41 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 41 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

#### `MenuKempstonOption` (`$C137`)

**Option 2, KEMPSTON J/S, in the colour of Controls 2**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 41 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 41 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

#### `MenuInterface2Option` (`$C151`)

**Option 3, INTERFACE 2, in the colour of Controls 3; then options 4 and 5**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 41 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 41 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

#### `MainMenuKeys` (`$C192`)

**The main menu's keys: the title music until a key, then 0-5**

Waits until no key is held (each frame cycling the title's colours, `$C820`), plays the title music until a key (`$C4A7`), waits for a key (KEY-SCAN `$028E`, the character from the ROM's key table `$0205`): 0 returns Z, 1-3 set Controls and redraw the options, 4 RedefineKeys then the whole menu, 5 LoadNewLevel (JR Z at `$C1B5` to `$C1FD`, NE's LoadGame address). Any other key is ignored.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 324,356 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 74,667 t-states own (0.07 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 217,531 t-states own (0.73 %) |
| Called from | `PrintInline` |
| Calls | `Start` (tail), `MainMenuOptions` (tail), `MenuMusic`, `TitleColourCycle` |
| Reads | `$C193`-`$C1A2` (`MainMenuKeys+1`, `MenuWaitKey`); `$DD00`-`$DEFB` (`work space $DD00+`) |
| Writes | `$BC8A`-`$BCAB` (`BuildMap+27`); `$BDA9`-`$BF9C` (`SceneryWest`, `SceneryEast`, `BaseListWest`, `BaseListEast` and 1 more); `$D3E4` (`Controls`) |

#### `PrintTitle` (`$C1E3`)

**"ZS EDITION'98" in big white letters at the top**

Prints the inline TitleText: ZS EDITION'98 and a space at row 1, column 2, white (`$47`), each glyph 3 rows high and 2 bytes wide (rows 1-3, columns 2-29). The attributes of rows 0-6, columns 0-30 are recoloured every 2 frames by TitleColourCycle while the menu waits. Called by MainMenuTitle only (NE's LoadGame, its other caller, is gone).

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 17 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 17 t-states own (0.00 %) |
| Called from | `MainMenu` |
| Calls | `PrintInline` |

#### `PrintTitleEnd` (`$C1FC`)

**PrintTitle's return**

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 10 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 10 t-states own (0.00 %) |
| Called from | `PrintInline` |

#### `LoadNewLevel` (`$C1FD`)

**Menu key 5, LOAD NEW LEVEL!: 62 NOPs, then 500 bytes from `$DD00` become the level and the game restarts**

Reached by MainMenuKeys' JR Z at `$C1B5` (key 5), NE's jump to its tape load at this address. `$C1FD-$C23A` are 62 zero bytes: NE's LoadGame and LoadGameBlocks (the title again, PRESS PLAY ON TAPE, LD-BYTES of the two blocks) cleared, run as NOPs. Then LoadLevelCopy: LDIR of 500 (`$1F4`) bytes `$DD00` -> `$BDA9` (SceneryWest .. BaseListEast and the first byte of ShapeTable, `$BF9C`); the words at `$DEF4`, `$DEF6`, `$DEF8`, `$DEFA` (offset `$1F4-$1FB` of the 512 bytes at `$DD00`) into the operands of BuildMap's four LD HL,list (`$BC8A`, `$BC92`, `$BCA2`, `$BCAA`); POP BC drops Start's return address (`$A62D`, from CALL MainMenu); JP Start. Start shows the menu again; the next START GAME builds the map from the patched list addresses.

The layout it expects is the '99's NELEV_xx.N file (512 bytes: the lists from 0, the four list addresses at `$1F4`; the '99 copies 499 bytes and also takes `$1F3` and `$1FC-$1FF`), so ZS meant a disk read of such a file to `$DD00` to come before the copy, in the 62 bytes he had cleared. It is not there: nothing reads the disk. What `$DD00` holds is the copy's input: after the load the '98 intro's scroller text (the intro block is read to `$C000-$E9FF` and the game, read to `$6780-$D87F`, does not reach it), after a game the map (cleared by BuildMap at every START GAME).

Witness game98/key5 (the menu snapshot of r98 frame 4800, key 5 at frame 50, key 0 at 400): the 62 NOPs and the copy ran once (frame 50); the words at `$DEF4-$DEFB` were `$20` `$20` ... (scroller spaces), so all four list addresses became `$2020`, inside the ROM; the menu came back; START GAME (frame 400) ran NewGameSetup and BuildMap, whose PlaceScenery read 3-byte records from the ROM at `$2020` (`$D7` `$78` `$D7`, ...): rows like `$D7` put cells at `$DD00` + `$200` * row, wrapping round the 64 K into the game, and the 2 x 2 blocks wrote over code (by frame 416 the CALL at `$BD67` read CALL `$ED48`); the CPU then ran through the map and the overwritten code and reached `$0000` at frame 462 (the ROM's reset: the 48 BASIC copyright screen from frame 500 on, work/stage2/game98/key5-sheet.png).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SaveGame` (`$C28D`)

**The SAVE key in play: three NOPs and RET (NE's tape save cleared)**

Called by PlayLoop's CheckGameKeys (`$A71A`) when Input bit 5 (the SAVE key of KeyTable) is set; PlayLoop then jumps to EnterPlay (`$A68E`), which redraws the play screen: in the '98 the SAVE key only redraws the screen. NE has LD HL,StartInterrupt / LD (Handler),HL / CALL PrintInline ... here (its tape save); ZS cleared it to zero and wrote a RET at `$C290`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `WaitAnyKey` (`$C325`)

**Wait until no key is held, then until one is (all half rows of port `$FE`)**

Reads all eight half rows at once (IN with A = 0: every address line A8-A15 low), bits 0-4 inverted: a key held. First waits for all keys up, then for any key down; returns with the key still held. No joystick, no debounce. Called by SaveGameBlocks (start the tape) and LoadError.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ControlsOptionAttr` (`$C336`)

**The attribute for menu option C: cyan (`$45`) when it is the current Controls, else yellow (`$46`)**

C = the option's Controls value (1-3). Prints an inline attribute code: `$45` (cyan, bright) when Controls (`$D3E4`) is C, else `$46` (yellow, bright); the option text printed next takes it. Called by the three option entries before their text; A and the flags are lost.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 3 calls, 128 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 3 calls, 128 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 3 calls, 128 t-states own (0.00 %) |
| Called from | `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option` |
| Calls | `PrintInline` |
| Reads | `$D3E4` (`Controls`) |

#### `ControlsOptionPlain` (`$C342`)

**ControlsOptionAttr's return, the option not chosen**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2 calls, 20 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 2 calls, 20 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 2 calls, 20 t-states own (0.00 %) |
| Called from | `PrintInline` |

#### `ControlsOptionChosen` (`$C349`)

**ControlsOptionAttr's return, the option chosen**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 10 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 10 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 10 t-states own (0.00 %) |
| Called from | `PrintInline` |

#### `RedefineKeys` (`$C34A`)

**Redefine the eight keys: UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE**

Key 4 of the main menu. Clears the screen, prints REDEFINE KEYS, waits until no key is held, clears KeyTable and asks for each key in turn: PrintKeyPrompt prints "PRESS KEY FOR " and the name that follows the CALL, DefineKey waits for a key not yet taken and fills the KeyTable record whose third byte HL points at (the port's high byte, the bit mask, the key code) and prints the key. KeyTable's records 0-7 are PAUSE, ABORT, SAVE, FIRE, UP, DOWN, LEFT, RIGHT: Input bits 7 to 0. Waits for the last key's release and about 0.5 s, then back to the menu.

Verified on NE's own instance: keys Q A O P M H B S gave KeyTable bf 10 48 / 7f 10 42 / fd 02 53 / 7f 04 4d / fb 01 51 / fd 01 41 / df 02 4f / df 01 50, the screen showed PRESS KEY FOR UP .. PAUSE with each key's letter, and the menu came back.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RedefineKeysBody` (`$C36A`)

**Wait for no key, clear KeyTable, ask for UP**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadUpKey` (`$C388`)

**The key for UP (KeyTable record 4), then ask for DOWN**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadDownKey` (`$C397`)

**The key for DOWN (record 5), then ask for LEFT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadLeftKey` (`$C3A6`)

**The key for LEFT (record 6), then ask for RIGHT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadRightKey` (`$C3B5`)

**The key for RIGHT (record 7), then ask for FIRE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadFireKey` (`$C3C4`)

**The key for FIRE (record 3), a blank line, then ask for PAUSE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadPauseKey` (`$C3D6`)

**The key for PAUSE (record 0), then ask for ABORT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadAbortKey` (`$C3E5`)

**The key for ABORT (record 1), then ask for SAVE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadSaveKey` (`$C3F4`)

**The key for SAVE (record 2), wait for its release and a pause, back to the menu**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintKeyPrompt` (`$C40C`)

**"PRESS KEY FOR " and then the key's name that follows the caller's CALL**

Called by the redefine-keys screen (`$C37F`, `$C38E`, ... `$C3EB`) once for each of the eight keys, with the key's name (UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE) as an inline string after the CALL. It prints its own inline text (two new lines, attribute `$46`, "PRESS KEY FOR ", attribute `$45`), then jumps (not calls) to PrintInline at `$C424`: the return address on the stack is then the caller's, so PrintInline prints the caller's name string and returns past it. One prompt takes two screen rows.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintKeyPromptName` (`$C424`)

**print the caller's inline key name and return past it**

The tail of PrintKeyPrompt: a JP to PrintInline with the caller's return address on top of the stack, so the bytes after the caller's CALL `$C40C` (the name of the key to press) are printed and skipped.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DefineKey` (`$C427`)

**wait for a free key, store its port, mask and code into a KeyTable entry, print its name**

HL = the code byte (the third byte) of a KeyTable entry; the redefine screen passes the entries in the order UP (+`$0E`), DOWN (+`$11`), LEFT (+`$14`), RIGHT (+`$17`), FIRE (+`$0B`), PAUSE (+`$02`), ABORT (+`$05`), SAVE (+`$08`), so the entries map to the Input bits 3, 2, 1, 0, 4, 7, 6, 5 (ReadControls shifts entry 0 into bit 7). The screen cleared the whole table before the first key, so only keys already defined in this pass count as taken.

It prints two spaces and sets attribute `$46`, then waits with the ROM KEY-SCAN (`$028E`) for a key; the key value E (0-39, row index 0-7 in bits 0-2, bit position from bit 4 down in bits 3-5) is turned into a code through the ROM key table `$0205` (CAPS SHIFT gives `$E3`, the first byte past the table). A key whose code is already in one of the eight entries is refused and the wait goes on. Then it writes the code, the bit mask `$20` >> (E/8 + 1) and the port high byte (`$7F` for row 0 down to `$FE` for row 7) backwards into the entry, and prints the key's name: SYM SH, ENTER, CAPS SH, SPACE, or the code as a character.

Experiment: key 4 at the menu, then Q, Q, A, O, P, SPACE, ENTER, CAPS SHIFT, SYMBOL SHIFT left KeyTable = FB 01 51 / FD 01 41 / DF 02 4F / DF 01 50 for UP / DOWN / LEFT / RIGHT, 7F 01 20 for FIRE, BF 01 0D, FE 01 E3, 7F 02 0E for PAUSE / ABORT / SAVE; the second Q was refused.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DefineKeyScan` (`$C430`)

**wait for a key that no entry holds yet**

Continues DefineKey after its inline text. On exit the entry is filled and the name printed (the RET is the one after each name string, or the one in PrintCharKeep's path for a plain character).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `KeyNameSymShiftEnd` (`$C479`)

**a RET (`$C9`): PrintInline returns here and the routine ends**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CheckEnterKey` (`$C47A`)

**DefineKey: is the new key ENTER?**

Part of DefineKey (`$C427`): code `$0D` prints "ENTER" and returns through the RET placed after the string.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `KeyNameEnterEnd` (`$C487`)

**a RET (`$C9`) after the string**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CheckCapsShiftKey` (`$C488`)

**DefineKey: is the new key CAPS SHIFT?**

Part of DefineKey (`$C427`): code `$E3` (the byte after the ROM's key table, what CAPS SHIFT alone looks up) prints "CAPS SH".

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `KeyNameCapsShiftEnd` (`$C497`)

**a RET (`$C9`) after the string**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CheckSpaceKey` (`$C498`)

**DefineKey: SPACE prints its name, any other key prints its own character**

Part of DefineKey (`$C427`). A code other than `$20` goes to PrintCharKeep (print the character A) and returns from there.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DefineKeyDone` (`$C4A6`)

**RET: the end of DefineKey; also the target of the music's command 0**

The RET after the SPACE name. The two command tables of the menu music (`$C553`, `$C572`) point their command 0 here; command 0 never occurs in the tune, and it would not work: the dispatch leaves the voice pointer pushed, so this RET would return into the tune data.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### music

`src/game98/music.asm`

#### `MenuMusic` (`$C4A7`)

**play the menu tune until a number key is pressed**

Called once by the main menu (`$C19E`) after all keys are up. Saves SP in `$FD08`, installs MenuInterrupt as Handler and sets the music state: the bass voice reads the track `$C678` through HL' (frames left C'), the lead voice the track `$C702` through DE' (frames left B'), the drum the track `$C665` through HL (frames left C); C' = B' = C = 1, so the first interrupt reads the first event of each. Then it runs the tone loop for ever: the main set's D and E count each voice's period down.

The tone loop never returns: MenuInterrupt ends it by loading SP from `$FD08` when a number key is down, so the RET of the interrupt returns from MenuMusic to the menu (`$C1A1`), which then reads the key. Ran 144 frames in NE's work/play; in this part's recordings it runs from the menu until a key (play: once, from r98 frame 4500 to START GAME). The tune is 5120 frames (102.4 s) long in each voice and loops (experiment: both voices jumped back at frame 5099 of a menu left alone); docs: r4.md.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 1,359,580 t-states own (0.06 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 27,173,718 t-states own (27.02 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 26,762,157 t-states own (89.97 %) |
| Called from | `MainMenuKeys` |
| Reads | `$C4C3` (`BassIdlePad`); `$FD0C` (`work space $FD0C+`) |
| Writes | `$FD08`-`$FD0C` (`work space $FD08+`); `$FDFE`-`$FDFF` (`work space $FDFE+`) |
| Ports out | `$00FE`, `$18FE` |

#### `BassIdlePad` (`$C4C3`)

**tone loop: the time of a bass step without an edge**

The tone loop runs LeadStep and BassStep in turn, about 122 T a turn. A step whose counter has not run out takes this pad (PUSH AF, read Input and write it back unchanged, POP AF: 61 T with the DEC / JP) so both paths take about the same time, the pitch stays steady whatever the other voice does.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadStep` (`$C4CB`)

**tone loop: count the lead period down, at 0 a pulse**

D counts the lead voice's period in loop turns. At 0 it reloads D with the note's period (the operand `$C4D0`), sets the beeper (EAR and MIC, `$18`, or 0 when the voice is off: the operand `$C4D2`) for a pulse of 14 * width T (the operand `$C4D6` = period / 4, at most 63), then clears it. The voice's pitch is about 3.5 MHz / (122 + 3.5) / period: period `$7C` about 225 Hz, `$29` about 680 Hz.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadIdlePadTail` (`$C4E4`)

**the rest of the lead pad (an entry kept from NE's annotation: NE's work/deep starts its recording here)**

Write Input back and POP AF, then fall into BassStep. NE's recording of NE's work/deep began inside the tone loop at this instruction, so its L1 lists the address as a root.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassStep` (`$C4E8`)

**tone loop: count the bass period down, at 0 a pulse**

The bass voice's twin of LeadStep: E is its counter, the operands `$C4ED` (period), `$C4EF` (on / off) and `$C4F3` (pulse width) are written by BassNextEvent, BassOn and BassOff. The '98 file holds the period `$7C` and the width `$1F` there (NE's tape: 0 and 0), with the lead's `$37` / `$0D`: the '98 game file is the memory after the tune had played, so the four operands differ from NE's though the code is the same; each voice's first event, read at the first interrupt (B' = C' = 1), writes them again.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MenuInterrupt` (`$C4FD`)

**the interrupt handler of the menu**

The drum, the bass and lead note readers, the title colours; a number key ends MenuMusic. It returns to the tone loop of MenuMusic, or, with SP from SavedSP, to the menu.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20 calls, 3,004 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 399 calls, 55,607 t-states own (0.06 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 393 calls, 54,940 t-states own (0.18 %) |
| Calls | `BassNextEvent`, `LeadNextEvent`, `DrumStep`, `TitleColourCycle` |
| Reads | `$FD08`-`$FD09` (`work space $FD08+`) |
| Writes | `$FDFE`-`$FDFF` (`work space $FDFE+`) |
| Ports in | `$E7FE` |

#### `BassNextEvent` (`$C528`)

**read the bass voice's next event: a note, or a command**

HL' = the bass track position. A byte of 9 or more is a note: the byte is the period (written into `$C4ED`, and period / 4 into the pulse width `$C4F3`) and the next byte its length in frames (C'). A byte below 9 is a command (BassCommand). Called by MenuInterrupt when C' runs out, and jumped to again by every command handler, so commands take no time.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 5 calls, 344 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 36 calls, 2,536 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 33 calls, 2,337 t-states own (0.01 %) |
| Called from | `MenuInterrupt`, `BassCall` (tail), `BassReturn` (tail), `SetDrumTrack` (tail), `BassOn` (tail), `BassOff` (tail) |
| Calls | `MusicDispatch` |
| Reads | `$C678`-`$C684` (`BassTrack`); `$C6BD`-`$C6CB` (`BassRiff`) |
| Writes | `$C4ED`-`$C4F3` (`BassStep+5`) |

#### `LeadNextEvent` (`$C53B`)

**read the lead voice's next event: a note, or a command**

The lead twin of BassNextEvent: DE' = the position, the note goes into `$C4D0` / `$C4D6` and its frames into B'.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 298 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 62 calls, 5,111 t-states own (0.01 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 63 calls, 5,206 t-states own (0.02 %) |
| Called from | `MenuInterrupt`, `LeadCall` (tail), `LeadReturn` (tail), `LeadOn` (tail), `LeadOff` (tail) |
| Calls | `MusicDispatch` |
| Reads | `$C702`-`$C70B` (`LeadTrack`); `$C789`-`$C7A9` (`LeadRiff`) |
| Writes | `$C4D0`-`$C4D6` (`LeadStep+5`) |

#### `BassCmd2` (`$C559`)

**bass command 2 (entry): JP BassCall**

A table entry of BassCommandTable: command 2 calls a pattern.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | run into, not called, 10 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 40 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 30 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `BassCall` (tail) |

#### `BassCmd3` (`$C55C`)

**bass command 3 (entry): JP SetDrumTrack**

A table entry: command 3 starts another drum track.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | run into, not called, 10 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 10 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 10 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `SetDrumTrack` (tail) |

#### `BassCmd4` (`$C55F`)

**bass command 4 (entry): JP BassOn**

A table entry: command 4 turns the bass voice on.

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 60 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 50 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `BassOn` (tail) |

#### `BassCmd5` (`$C562`)

**bass command 5 (entry): JP BassOff**

A table entry: command 5 turns the bass voice off (its notes keep their time, silent).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | run into, not called, 10 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 60 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 70 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `BassOff` (tail) |

#### `BassCmd6` (`$C565`)

**bass command 6 (entry): JP BassReturn**

A table entry: command 6 ends a pattern.

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 30 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 20 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `BassReturn` (tail) |

#### `LeadCommand` (`$C56E`)

**command A of the lead track: jump to entry A of the table after the CALL**

The lead twin of BassCommand. HL' (the bass position) is pushed so the handlers can pop it back.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadCmd2` (`$C578`)

**lead command 2 (entry): JP LeadCall**

A table entry of LeadCommandTable: command 2 calls a pattern.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | run into, not called, 10 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 40 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 30 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `LeadCall` (tail) |

#### `LeadCmd4` (`$C57E`)

**lead command 4 (entry): JP LeadOn**

A table entry: command 4 turns the lead voice on.

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 60 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 70 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `LeadOn` (tail) |

#### `LeadCmd5` (`$C581`)

**lead command 5 (entry): JP LeadOff**

A table entry: command 5 turns the lead voice off.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | run into, not called, 10 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 60 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 70 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `LeadOff` (tail) |

#### `LeadCmd6` (`$C584`)

**lead command 6 (entry): JP LeadReturn**

A table entry: command 6 ends a pattern.

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | run into, not called, 30 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | run into, not called, 20 t-states own (0.00 %) |
| Called from | `MusicDispatch` |
| Calls | `LeadReturn` (tail) |

#### `BassCall` (`$C58D`)

**bass command 2 aa: play the pattern at aa, then go on after the command**

One level only: the return position (the address operand's high byte) is kept in `$FD54`; BassReturn resumes one byte past it.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 66 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 4 calls, 264 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 3 calls, 198 t-states own (0.00 %) |
| Called from | `BassCmd2` (tail) |
| Calls | `BassNextEvent` (tail) |
| Reads | `$C67C`-`$C686` (`BassTrack+4`) |
| Writes | `$FD54`-`$FD55` (`work space $FD54+`) |

#### `LeadCall` (`$C599`)

**lead command 2 aa: play the pattern at aa, then go on after the command**

The return position is kept in `$FD56`.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 74 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 4 calls, 296 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 3 calls, 222 t-states own (0.00 %) |
| Called from | `LeadCmd2` (tail) |
| Calls | `LeadNextEvent` (tail) |
| Reads | `$C703`-`$C70D` (`LeadTrack+1`) |
| Writes | `$FD56`-`$FD57` (`work space $FD56+`) |

#### `BassGoto` (`$C5A7`)

**bass command 1 aa: continue the track at aa (code: POP HL, read the word, JP BassNextEvent)**

Code that runs when the tune loops (frame 5099 of a menu left alone): NE's recordings never stayed in the menu that long, so the cut keeps it as data. POP HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; JP `$C528`. The bass track ends with 1 `$C678`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LeadGoto` (`$C5B0`)

**lead command 1 aa: continue the track at aa (code, run only when the tune loops)**

POP HL; EX DE,HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; EX DE,HL; JP `$C53B`. The lead track ends with 1 `$C702`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BassReturn` (`$C5BB`)

**bass command 6: back from the pattern to the bass track**

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 3 calls, 126 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 2 calls, 84 t-states own (0.00 %) |
| Called from | `BassCmd6` (tail) |
| Calls | `BassNextEvent` (tail) |
| Reads | `$FD54`-`$FD55` (`work space $FD54+`) |

#### `LeadReturn` (`$C5C3`)

**lead command 6: back from the pattern to the lead track**

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 3 calls, 138 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 2 calls, 92 t-states own (0.00 %) |
| Called from | `LeadCmd6` (tail) |
| Calls | `LeadNextEvent` (tail) |
| Reads | `$FD56`-`$FD57` (`work space $FD56+`) |

#### `SetDrumTrack` (`$C5CC`)

**bass command 3 aa: the drum plays the track at aa from its next record**

Writes aa into the main set's HL, the drum position (the frames left of the current drum record are kept). Read through the bass voice's HL', so only the bass track may use it.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 76 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 76 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 76 t-states own (0.00 %) |
| Called from | `BassCmd3` (tail) |
| Calls | `BassNextEvent` (tail) |
| Reads | `$C679`-`$C67A` (`BassTrack+1`) |

#### `DrumStep` (`$C5DB`)

**play the next drum record (a short noise or sweep inside the interrupt)**

HL = the drum position, called by MenuInterrupt when the drum's frames (C) run out. A record is the frames until the next one and a kind: 0 a hiss meant as 96 bytes of ROM from `$08`xx sent to the beeper, about 1 ms (but DrumHissLoop never steps HL: one ROM byte, `$08` L, 96 times; in NE's recordings it is `$23`, EAR / MIC 0, so the hiss is silent: NE's docs/09-sound.md), 2 p a falling tone (48 cycles: the low half starts at p - 1 and shortens by 1, the high half starts at p / 2 and lengthens by 4), any other kind a rasp (80 ROM bytes from `$00`xx with a gap that mostly grows). The byte 1 in place of the frames is a goto: 1 aa. The tone loop stands still while a drum plays. In the 5300-frame experiment kinds 1 and 2 ran 72 times each.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 3,762 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 13 calls, 49,632 t-states own (0.05 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 12 calls, 45,804 t-states own (0.15 %) |
| Called from | `MenuInterrupt` |
| Reads | `$C665`-`$C669` (`DrumTrackSteady`) |
| Ports out | `$00FE` |

#### `BassOn` (`$C635`)

**bass command 4: the bass pulses sound again**

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 6 calls, 276 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 5 calls, 230 t-states own (0.00 %) |
| Called from | `BassCmd4` (tail) |
| Calls | `BassNextEvent` (tail) |
| Writes | `$C4EF` (`BassStep+7`) |

#### `BassOff` (`$C63F`)

**bass command 5: the bass pulses go silent (the notes still take their time)**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 43 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 6 calls, 258 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 7 calls, 301 t-states own (0.00 %) |
| Called from | `BassCmd5` (tail) |
| Calls | `BassNextEvent` (tail) |
| Writes | `$C4EF` (`BassStep+7`) |

#### `LeadOn` (`$C648`)

**lead command 4: the lead pulses sound again**

| | |
| --- | --- |
| Runs (r98 4500-5903: the menu, START GAME, play) | 6 calls, 276 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 7 calls, 322 t-states own (0.00 %) |
| Called from | `LeadCmd4` (tail) |
| Calls | `LeadNextEvent` (tail) |
| Writes | `$C4D2` (`LeadStep+7`) |

#### `LeadOff` (`$C652`)

**lead command 5: the lead pulses go silent**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 43 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 6 calls, 258 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 7 calls, 301 t-states own (0.00 %) |
| Called from | `LeadCmd5` (tail) |
| Calls | `LeadNextEvent` (tail) |
| Writes | `$C4D2` (`LeadStep+7`) |

#### `MusicDispatch` (`$C65B`)

**jump to entry A of the 3-byte JP table that follows the caller's CALL**

Called with A = the command (below 9) from BassCommand / LeadCommand; it pops its own return address (the table) and jumps to table + 3 * A, so the handler returns to nobody: each jumps back to the voice's reader.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 5 calls, 230 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 39 calls, 1,794 t-states own (0.00 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 37 calls, 1,702 t-states own (0.01 %) |
| Called from | `BassNextEvent`, `LeadNextEvent` |
| Calls | `BassCmd2`, `BassCmd3`, `BassCmd4`, `BassCmd5`, `BassCmd6`, `LeadCmd2`, `LeadCmd4`, `LeadCmd5`, `LeadCmd6` |

#### `TitleColourCycle` (`$C820`)

**cycle the ink of the top seven rows (ZS's title), one colour every 2 frames**

Counts `$FD33` 0-15 each call; on even counts it paints the attributes of rows 0-6, columns 0-30 (`$5800-$58DE`: 31 cells a row, then a step of 1 to the next row) with BRIGHT, black paper and ink count / 2, so the ink runs through all 8 colours every 16 frames. ZS changed three operands for the wider title: the start `$5800` (`$C823`, NE `$582A`: row 1, column 10), the row width 31 (`$C835`, NE 12) and the step 1 (`$C83D`, NE 20), so the cycle covers ZS EDITION'98 (rows 1-3, columns 2-29, PrintTitle `$C1E3`) and the rows around it; column 31 keeps its colour. Called every frame by the main menu's HALT loops (`$C193`, `$C1A2`) and by MenuInterrupt while the tune plays (401 calls in this part's play recording, 397 in key5menu).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 26 calls, 82,251 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 401 calls, 1,265,515 t-states own (1.26 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 397 calls, 1,258,958 t-states own (4.23 %) |
| Called from | `MainMenuKeys`, `MenuInterrupt` |
| Calls | `AddAToHL` |
| Reads | `$FD33` (`work space $FD33+`) |
| Writes | `$5800`-`$58DE` (screen); `$FD33` (`work space $FD33+`) |

### construction

`src/game98/construction.asm`

#### `ConstructionMenu` (`$C849`)

**landing on the warbase pad at altitude 15: choose the parts (MenuCursor, MenuParts), START ROBOT or EXIT MENU**

Called by PlayLoop when the ship rests on the pad of our warbase (Altitude 15) and the door below is free. First looks for a free record among our slots 0-23 (`$DA00` + 16 x n, +`$01` = 0); with none it returns at once (IY = `$DB80`, enemy slot 24: the bug of PlayLoop's writes, NE's docs/10-gameplay-logic.md 10.12).

Otherwise IY = the free slot: the preview robot, and on START ROBOT the new one. Handler = StartInterrupt, so neither the frame count nor the radar runs; the menu loop runs no game turns, so the world stands still while the menu is open. ClearScreen, then the eight part pictures in column 16 from the bottom (bipod) to the top (electronics), each the second facing of the part's sprite cut to 24 lines and drawn upwards by DrawMaskedUp; the preview's frame attributes (`$46`, 4 x 9 cells from row 15, column 0); the texts (title, part names, EXIT / START, costs, the resource labels). Falls into ConstructionMenuSetup.

Returns (after LeaveConstructionMenu) with IY = the slot; PlayLoop then writes the start state. On EXIT MENU the slot stays free (+`$01` = 0, PlaceRobot not called), so those writes do no harm.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 15,960 t-states own (0.00 %) |
| Called from | `NewGameSetup` |
| Calls | `ClearScreen`, `DrawMaskedUp`, `TableWord`, `AddAToHL`, `PrintInline` |
| Reads | `$6A24`-`$6A25` (`SprTracksXOdd`); `$6D40`-`$6D41` (`SprBipodXOdd`); `$7058`-`$7059` (`SprAntiGravOdd`); `$7354`-`$7355` (`SprCannonXmOdd`); `$77F4`-`$77F5` (`SprMissilesXOdd`); `$7C96`-`$7C97` (`SprPhasersXmOdd`); 4 more ranges |
| Writes | `$59E0`-`$5A03` (screen); `$5A20`-`$5A23` (screen); `$5A40`-`$5A43` (screen); `$5A60`-`$5A63` (screen); `$5A80`-`$5A83` (screen); `$5AA0`-`$5AA3` (screen); 3 more ranges |

#### `ConstructionMenuSetup` (`$C9E7`)

**reset the preview robot, copy the resources, cursor on BIPOD, nothing chosen**

Continues ConstructionMenu after its text. The free slot's +8 is set to 4 and +`$0D` to 0 (the built robot keeps +8 = 4: NE's work/deep frame 360, slot 0 = 16 EF 16 00 09 00 00 09 04 11 ...). Resources are copied to MenuResources, which the menu spends; MenuCursor = column 2 (the parts), row 0 (bipod); MenuParts = 0; ShowRobotDesign paints the part pictures (white when chosen) and draws the preview robot; the cursor is painted.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 1,244 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PaintMenuCursor`, `PrintMenuResources`, `ShowRobotDesign` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`) |
| Writes | `$DA08`-`$DA3D` (`work space $DA08+`); `$FD1F`-`$FD2F` (`work space $FD1F+`) |

#### `ConstructionMenuLoop` (`$CA0F`)

**wait for a control; fire acts on the cursor's item, a direction moves the cursor**

WaitKey until one of Input bits 0-4. Without fire: MoveMenuCursor (`$CB00`). With fire: column 0 EXIT MENU (`$CB8E`), column 1 START ROBOT (`$CB52`), column 2 toggles the part under the cursor.

Choosing a part: a part already chosen is taken back (RefundPart) and cleared. A chassis (bipod, tracks, anti-grav: rows 0-2) replaces the chassis already chosen, which is refunded first. A fourth weapon is refused: of cannon, missiles, phasers and nuclear at most three (`$78` never all set). The cost is paid from the part's own resource (PartCosts + 8) and what it lacks from the general resource; if the general one cannot pay the rest the part is refused (a replaced chassis stays refunded: the robot is left without one). Accepted: beep `$64`; refused or taken back: beep `$78`. Then it waits for fire up and pauses 10 frames.

Experiment (general 10, electronics 1, chassis 2): bipod 3 -> chassis 0, general 9; tracks 5 -> bipod refunded, chassis 0, general 7; cannon 2 -> general 5; tracks again -> taken back, chassis 2, general 8. With 99 of everything: missiles, phasers, then nuclear refused (MenuParts `$38`).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 31 calls, 145,498 t-states own (0.01 %) |
| Called from | `MenuPause` (tail) |
| Calls | `MoveMenuCursor` (tail), `MenuPause` (tail), `StartRobot` (tail), `PrintMenuResources`, `ShowRobotDesign`, `Beep`, `AddAToHL`, `WaitKey` |
| Reads | `$CAF0`-`$CAFF` (`PartCosts`); `$FD0C` (`work space $FD0C+`); `$FD1F`-`$FD2F` (`work space $FD1F+`) |
| Writes | `$FD21`-`$FD2F` (`work space $FD21+`) |

#### `RefundPart` (`$CAC1`)

**give back the cost of part E to MenuResources, the overflow to the general resource**

E = the part row. The cost goes back to the part's own resource; whatever lifts it above its value when the menu opened (Resources, 7 bytes below MenuResources) is what the general resource paid, so it is returned to the general one instead. Exact because each own resource has only one part in the menu at a time (one chassis, one of each weapon, electronics). Called by ConstructionMenuLoop (`$CA4C`, `$CAA4`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MoveMenuCursor` (`$CB00`)

**right / left change the column (0-2), down / up the part row (0-7) in column 2**

HL = MenuCursor (L the column, H the row), Input as WaitKey left it. Right adds 1 to the column, left subtracts 1; out of 0-2 nothing moves. Only without right / left: in the parts column up adds 1 to the row (towards ELECTRONICS, up the screen), down subtracts 1; out of 0-7 nothing moves. A move repaints the old item in `$45`, the new one in `$46` and clicks (beep `$14`); every press ends in the 10-frame pause (MenuPause).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 21 calls, 5,009 t-states own (0.00 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `PaintMenuCursor`, `Beep` |
| Reads | `$FD0C` (`work space $FD0C+`) |
| Writes | `$FD1F`-`$FD20` (`work space $FD1F+`) |

#### `MenuPause` (`$CB4A`)

**10 frames, then back to ConstructionMenuLoop**

The pause after every press (moves too); a shorter press falls into it and is lost, WALKTHROUGH 6.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 10 calls, 21,517,688 t-states own (0.99 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `ConstructionMenuLoop` (tail) |
| Reads | `$CB4D` (`MenuPauseLoop+1`) |

#### `StartRobot` (`$CB52`)

**START ROBOT: needs a chassis and a weapon; spend the resources, place the robot at the warbase's door, leave**

Refused (back to the menu after the pause) without a chassis (MenuParts bits 0-2) or without a weapon (bits 3-6); electronics alone count as neither. Otherwise MenuResources become Resources, the free slot becomes a robot of ours (+`$0A` = 0) at column ShipX, row ShipY + 4 (PlaceRobot writes +0 to +4 and marks the map cell), +7 = MenuParts, and a rising chirp plays (Beep with `$50` down to `$14` by 5). Then LeaveConstructionMenu. In NE's work/deep the robot built at frame 356 sits at (22, 9): the pad at (22, 5) plus 4 rows. The '98's warbase door is (22,14), its pad (22,10).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4 calls, 4,756 t-states own (0.00 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `PlaceRobot`, `Beep`, `ClearViewBuffer`, `DrawPlayScreen` |
| Reads | `$FD0D`-`$FD0F` (`work space $FD0D+`); `$FD21`-`$FD2F` (`work space $FD21+`) |
| Writes | `$DA07`-`$DA3A` (`work space $DA07+`); `$FD22`-`$FD30` (`work space $FD22+`); `$FDFE`-`$FDFF` (`work space $FDFE+`) |

#### `PaintMenuCursor` (`$CBA9`)

**paint the item under MenuCursor with attribute C (`$46` the cursor, `$45` the rest)**

Column 0 / 1: two rows of 5 cells, EXIT MENU at rows 21-22 columns 4-8, START ROBOT columns 10-14. Column 2: the part's name, 11 cells from column 21 of row 22 - 3 * row (BIPOD row 22 up to ELECTRONICS row 1). Called by ConstructionMenuSetup and MoveMenuCursor.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 46 calls, 6,326 t-states own (0.00 %) |
| Called from | `ConstructionMenuSetup`, `MoveMenuCursor` |
| Calls | `FillAttributes` |
| Reads | `$FD1F`-`$FD20` (`work space $FD1F+`) |

#### `FillAttributes` (`$CBDB`)

**write C into B bytes from HL**

Also used by PaintMenuItem.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 242 calls, 54,198 t-states own (0.00 %) |
| Called from | `PaintMenuItem`, `PaintMenuCursor` |
| Writes | `$5835`-`$583F` (screen); `$5895`-`$589F` (screen); `$58F5`-`$591E` (screen); `$5955`-`$59DE` (screen); `$59F7`-`$59FE` (screen); `$5A15`-`$5A3E` (screen); 2 more ranges |

#### `PrintMenuResources` (`$CBE0`)

**print MenuResources (two digits each) and their total**

The seven values at column 13: GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16 (PrintMenuResource, two digits: a value above 99 prints a wrong tens digit, e.g. 200 shows "D0"); the sum (HL) at row 18, column 12, three digits by PrintNumber3 (the tail `$CC03`).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 14 calls, 9,861 t-states own (0.00 %) |
| Called from | `ConstructionMenuSetup`, `ConstructionMenuLoop` |
| Calls | `PrintMenuResource`, `AddAToHL`, `PrintInline` |
| Reads | `$FD29`-`$FD2F` (`work space $FD29+`) |

#### `PrintMenuTotal` (`$CC03`)

**Construction menu: print the total of the costs (the tail of `$CBE0`)**

The tail of PrintMenuResources after the inline position (18,12): E = `$20` (blank leading zeros) and PrintNumber3 prints HL, the sum of the seven MenuResources (the TOTAL line, not the costs). 29 runs in NE's deep recording, one per reprint of the resources.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 14 calls, 238 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber3` (tail) |

#### `PrintMenuResource` (`$CC08`)

**Construction menu: print one resource value A at row C, column 13**

Called by `$CBE0` for each of the seven MenuResources (rows 9, 11-16). Patches the row byte of the position string after the CALL (`$CC11`), prints the position, then PrintMenuResourceValue prints A as two digits. Preserves BC, DE, HL (203 calls in NE's deep recording).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 98 calls, 4,410 t-states own (0.00 %) |
| Called from | `PrintMenuResources` |
| Calls | `PrintInline` |
| Writes | `$CC11` (`MenuResourcePos+1`) |

#### `PrintMenuResourceValue` (`$CC14`)

**Construction menu: print A as two digits, registers kept (the tail of `$CC08`)**

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 98 calls, 9,819 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2` |

#### `ShowRobotDesign` (`$CC1F`)

**Construction menu: highlight the chosen parts and draw the robot preview**

IY = the robot record being designed. Paints the attributes of the parts list (columns 16-19, three rows a part, 24 rows from the top): `$47` (bright white) for a part chosen in MenuParts, `$06` (yellow) otherwise, bit 7 (electronics) at the top. Then clears the view buffer, writes MenuParts to +`$07`, draws the robot stack into the buffer at map position row 10, column 7 (DrawRobot, base height +`$0D` = 0) and stores the stack's total height (the sum of the part heights `$D7B4`) in +`$09`: the height the ship lands on. Finally copies 4 bytes x 72 lines of the buffer from `$6168` (buffer row 82, column 0) to the screen at `$48E0` (character row 15, column 0). Called from `$C9E7` (7) and `$CA0F` (22) after each change of the parts.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 14 calls, 321,663 t-states own (0.01 %) |
| Called from | `ConstructionMenuSetup`, `ConstructionMenuLoop` |
| Calls | `DrawRobot`, `ClearViewBuffer`, `NextScreenLine`, `AddAToHL` |
| Reads | `$6168`-`$666B` (system); `$667C`-`$667F` (system); `$6690`-`$6693` (system); `$66A4`-`$66A7` (system); `$66B8`-`$66BB` (system); `$66CC`-`$66CF` (system); 4 more ranges |
| Writes | `$48E0`-`$54C3` (screen); `$54E0`-`$54E3` (screen); `$5500`-`$55C3` (screen); `$55E0`-`$55E3` (screen); `$5600`-`$56C3` (screen); `$56E0`-`$56E3` (screen); 11 more ranges |

#### `PlaceRobot` (`$CC7C`)

**Put robot IY at map column HL, row B: record, map bit 6, radar dot**

Writes +`$02`/+`$03` = HL (x), +`$04` = B (y), +`$00`/+`$01` = the map cell (MapCell) and sets the cell's bit 6 (an object to draw). Then toggles the robot's radar dot (ToggleRadarDot, side = bit 7 of +`$0A`: 0 the player's buffer `$D800`, 1 the enemy's `$D900`). The caller clears the old cell and toggles the old dot. Called by the robot step `$B0FA` (9652 times in NE's deep recording), the enemy spawn `$B7F4` (22) and START ROBOT in `$CB52` (7).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,078 calls, 4,318,005 t-states own (0.20 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 120 calls, 25,800 t-states own (0.03 %) |
| Called from | `RobotStep` (tail), `EnemyCommander`, `StartRobot` |
| Calls | `MapCell`, `ToggleRadarDot` (tail) |
| Reads | `$DA04`-`$DA3A` (`work space $DA04+`); `$DB84`-`$DCFA` (`work space $DB84+`); `$DF22`-`$DF3C` (`work space $DF22+`); `$DF67`-`$E53C` (`work space $DF67+`); `$E565`-`$E93C` (`work space $E565+`); `$E963`-`$EB3C` (`work space $E963+`); 3 more ranges |
| Writes | `$DA00`-`$DA34` (`work space $DA00+`); `$DB80`-`$DCF4` (`work space $DB80+`); `$DF22`-`$DF3C` (`work space $DF22+`); `$DF67`-`$E53C` (`work space $DF67+`); `$E565`-`$E93C` (`work space $E565+`); `$E963`-`$EB3C` (`work space $E963+`); 3 more ranges |

#### `ShipCell` (`$CCA0`)

**HL = the map cell under the ship (ShipX, ShipY)**

Falls into MapCell. Used by `$A62D`, `$B01D` (clear the ship's bit 7) and `$B024` (set it).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 7,937 calls, 230,230 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 294 calls, 8,526 t-states own (0.01 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `LiftShipFromMap`, `PutShipOnMap` |
| Calls | `MapCell` |
| Reads | `$FD0D`-`$FD0F` (`work space $FD0D+`) |

#### `MapCell` (`$CCA6`)

**HL = the map cell of column HL, row A: `$DD00` + `$200`*A + HL**

H += 2*A + `$DD`. The map lookup of the whole game (127962 calls in NE's deep recording: the main loop `$AD90`, CheckShipMove, the robot code, PlaceRobot, DrawMover).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 129,330 calls, 3,752,090 t-states own (0.17 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 3,255 calls, 94,509 t-states own (0.09 %) |
| Called from | `GameTurnEnd`, `CheckShipMove`, `GroundUnderFootprint`, `MoveShot`, `EnemyCommander`, `SetBaseOwner` (tail), `PlaceRobot`, `ShipCell`, `DrawCellObject` |

#### `Beep` (`$CCAC`)

**Beeper tone: 256 half-periods, A = the half-period delay (bigger is lower)**

B = A is the DJNZ delay of each half-period, C = 0 counts 256 speaker toggles (bit 4 of port `$FE`, border black). BC is kept. Used for menu clicks and confirmations: ListMenu (83), `$CB52` (98), `$CB00` (42), `$CA0F` (22), the robot menu `$A7CD`, `$ABC8`.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 143 calls, 28,534,184 t-states own (1.31 %) |
| Called from | `ShowOrderMiles`, `SetOrder`, `ListMenu`, `ConstructionMenuLoop`, `MoveMenuCursor`, `StartRobot` |
| Ports out | `$00FE`, `$10FE` |

### view

`src/game98/view.asm`

#### `DrawView` (`$CCBD`)

**Draw the isometric view: background, objects, copy to the screen**

DrawViewBackground clears the buffer `$5B00` and paints the corners outside the map, DrawMapObjects draws every block, building, robot, shot and the ship, CopyViewToScreen puts the 160x160 buffer on the screen. Once per game turn: 3423 times in the 36046 frames of NE's deep recording (the play loop waits for 10 frames a turn, `$AE1D`). About 578000 T-states a call, 8.3 frames: the reason a turn is 10 frames.

Called by PlayLoop, the menu loops that keep the game going (ListMenu's turn `$AD1F`, DirectControlLoop, DistanceLoop, CombatFireShot), the nuclear blast (`$BA6D`) and DrawPlayScreen. No HALT before the copy: the screen may tear for a frame.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,698 calls, 118,731 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 99 calls, 4,346 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu`, `DrawPlayScreen` |
| Calls | `DrawMapObjects`, `DrawViewBackground`, `CopyViewToScreen` (tail) |

#### `DrawMapObjects` (`$CCC6`)

**Draw the 32 x 16 cells of the view back to front into the view buffer**

Clears the deferred ship position `$FD11` and draws the ship's shadow (sprite 1, height 0) at the ship's view column (ShipX - ViewX) and row ShipY. Then walks the visible part of the map along diagonals: the diagonal x - y = 31 first down to x - y = -15, each from row 0 (x, y) to (x+15, y+15) or the right edge; cells left of the view (x < 0) and cells that are 0 are skipped, every other cell goes to DrawCell with HL = the cell, D = row, E = view column. The order is the painter's order of the projection (DrawSprite): a later cell is nearer the viewer. About 442000 T-states a call with the sprites it draws (1512 M in NE's deep recording), the heaviest part of the play.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,698 calls, 177,707,768 t-states own (8.19 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 99 calls, 6,469,604 t-states own (6.43 %) |
| Called from | `DrawView` |
| Calls | `DrawCell`, `DrawSprite`, `AddAToHL` |
| Reads | `$DD00`-`$EF23` (`work space $DD00+`); `$F100`-`$F123` (`work space $F100+`); `$F300`-`$F323` (`work space $F300+`); `$F500`-`$F523` (`work space $F500+`); `$F700`-`$F723` (`work space $F700+`); `$F900`-`$F923` (`work space $F900+`); 2 more ranges |
| Writes | `$CF3F` (`DrawSprite+18`); `$FD11`-`$FD12` (`work space $FD11+`) |

#### `DrawCell` (`$CD18`)

**Draw map cell HL (A = its byte) at view row D, column E**

Cell bits: 0-4 the block type, 5 the right half of a two-cell block (nothing drawn), 6 an object (building, robot or shot, or a robot / shot deferred to this cell), 7 the ship, or the ship deferred to this cell. A block (bit 5 clear, type not 0) is drawn as sprite = type at height 0. Bit 6 calls DrawCellObject. Bit 7 handles the ship: on the first bit-7 cell (`$FD11` = 0, the ship's own cell, set by `$B024`) it looks for the cell drawn last among the neighbouring blocks (FindLatestBlock) and the neighbouring objects (CheckObjectNeighbour at (x-1,y-1), (x-1,y), (x-1,y+1), (x,y+1), (x+1,y+1)). If that is the ship's cell the ship is drawn at once, otherwise bit 7 is set on that later cell and the ship's view position is kept in `$FD11`; when the walk reaches it, bit 7 is cleared again and the ship (sprite 0) is drawn at the kept position, at height Altitude. So the ship is never painted over by a neighbour. In NE's deep recording the ship was deferred in 2828 of the 3423 view draws.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 314,519 calls, 44,936,162 t-states own (2.07 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 10,731 calls, 1,525,640 t-states own (1.52 %) |
| Called from | `DrawMapObjects` |
| Calls | `CheckObjectNeighbour`, `FindLatestBlock`, `DrawCellObject`, `DrawSprite` |
| Reads | `$DD0C`-`$DD0D` (`work space $DD0C+`); `$DF0C`-`$DF23` (`work space $DF0C+`); `$E10C`-`$E122` (`work space $E10C+`); `$E30C`-`$E322` (`work space $E30C+`); `$E50C`-`$E522` (`work space $E50C+`); `$E70C`-`$E722` (`work space $E70C+`); 2 more ranges |
| Writes | `$CF3F` (`DrawSprite+18`); `$F116` (`work space $F116+`); `$F314`-`$F318` (`work space $F314+`); `$F516` (`work space $F516+`); `$F714` (`work space $F714+`); `$FB16`-`$FB17` (`work space $FB16+`); 1 more ranges |

#### `CheckObjectNeighbour` (`$CD90`)

**Ship: an object at HL counts, and so do the blocks around it**

Used for the ship's neighbours: if HL has bit 6 (a robot, a building or a shot stands there, or one was deferred there) it competes (KeepLaterCell), and then the code falls into FindLatestBlock for the blocks around that object, because the ship flies above objects and their own neighbours can cover it too. In: HL the cell, DE the latest cell so far. Out: DE the latest. HL kept.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 12,965 calls, 299,203 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 490 calls, 11,270 t-states own (0.01 %) |
| Called from | `DrawCell` |
| Calls | `KeepLaterCell` |
| Reads | `$EF13`-`$EF18` (`work space $EF13+`); `$F113`-`$F118` (`work space $F113+`); `$F311`-`$F31A` (`work space $F311+`); `$F511`-`$F517` (`work space $F511+`); `$F710`-`$F717` (`work space $F710+`); `$F910`-`$F917` (`work space $F910+`); 1 more ranges |

#### `FindLatestBlock` (`$CD96`)

**DE = the cell drawn last among DE and the blocks next to HL**

Checks the blocks (bit 5 clear, type not 0) at (x-1,y+1), (x,y+1) (both only when y+1 < 16), (x-1,y) and (x+1,y+1) (y+1 < 16) of cell HL with CheckBlockNeighbour; (x+1,y) is passed over (HL only goes through it). Those are the cells whose sprites can overlap a robot, a shot or the ship standing at HL. HL is kept. Used by DrawCell (the ship) and DrawMover (robots, shots).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 12,139 calls, 1,908,548 t-states own (0.09 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 17,836 t-states own (0.02 %) |
| Called from | `DrawCell`, `DrawCellObject` |
| Calls | `CheckBlockNeighbour` |

#### `CheckBlockNeighbour` (`$CDB8`)

**A block at HL competes for the latest cell**

Bit 5 set (the right half of a block) or type 0 (empty): nothing. Otherwise falls into KeepLaterCell.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 29,109 calls, 971,455 t-states own (0.04 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 392 calls, 16,464 t-states own (0.02 %) |
| Called from | `FindLatestBlock` |
| Calls | `KeepLaterCell` |
| Reads | `$DF21`-`$DF22` (`work space $DF21+`); `$E10F`-`$E124` (`work space $E10F+`); `$E30F`-`$E523` (`work space $E30F+`); `$E70F`-`$E723` (`work space $E70F+`); `$E90F`-`$E923` (`work space $E90F+`); `$EB0F`-`$EF11` (`work space $EB0F+`); 1 more ranges |

#### `KeepLaterCell` (`$CDBF`)

**DE = HL if map cell HL is drawn after cell DE**

The drawing order of DrawMapObjects: diagonals by falling x - y, along a diagonal by rising x. A = (yHL - yDE) + (xDE - xHL) (columns by the low bytes, rows from the high bytes: (H - `$DD`) / 2). A > 0: HL's diagonal is later; A = 0: same diagonal, later when xHL > xDE.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 767 calls, 72,948 t-states own (0.00 %) |
| Called from | `CheckObjectNeighbour`, `CheckBlockNeighbour` |

#### `FindRobot` (`$CDD8`)

**Z: IY the robot record standing on map cell HL, B = 48 - its slot (slots 0-23 the player's)**

Walks the 48 records of Robots (16 bytes: slots 0-23 the player's, 24-47 the enemy's) comparing the draw cell +`$00`/+`$01` with HL; a free slot has +`$01` = 0 and never matches a map address. Out: Z, IY = the record, B = 48 - slot; NZ when none. DE is kept. A robot deferred by DrawMover is found at the deferred cell, as the walk needs it. Called by DrawCellObject, PlayLoop (the robot under the ship), the captures, the shot hits, the blast and ObjectTop.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 33,253 calls, 92,483,072 t-states own (4.26 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 221 calls, 960,594 t-states own (0.96 %) |
| Called from | `NewGameSetup`, `GameTurnEnd`, `ObjectTop`, `ScanLane`, `DrawCellObject` |
| Reads | `$DA00`-`$DCF1` (`work space $DA00+`) |

#### `FindBuilding` (`$CDF5`)

**Z: IY the building record (Buildings) on map cell HL**

Walks the 56 records of Buildings (3 bytes: the map cell address, the type) comparing the cell with HL. Out: Z, IY = the record; NZ when none. DE is kept. Called by DrawCellObject, CheckWarbasePad (the construction menu's pad), ObjectTopBuilding and RemoveBuilding.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 8,942 calls, 21,276,440 t-states own (0.98 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 208 calls, 531,707 t-states own (0.53 %) |
| Called from | `NewGameSetup`, `ObjectTop`, `RemoveBuilding`, `DrawCellObject` |
| Reads | `$FF01`-`$FFA6` (`work space $FF01+`) |

#### `DrawCellObject` (`$CE12`)

**Draw the object of map cell HL (bit 6): a robot, a building or a shot**

A robot whose +`$00`/+`$01` is HL goes to DrawMover. A building record goes to its sprite: BuildingSprites[type] at height BuildingHeights[type]. Otherwise the five shot records at `$D7D3` (9 bytes: +`$00`/+`$01` cell, +`$02`/+`$03` x, +`$04` y, +`$05` direction, +`$06` range, +`$07` weapon 1-3, +`$08` height) are searched; a match goes to DrawMover. Nothing found: nothing drawn. 8330 calls in NE's deep recording: 1485 robots, 6845 buildings, the shot search never ran (no shot stood in the view while it was drawn; the shot path is read from the code and from the shot records at frame 20000).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 14,837 calls, 3,620,050 t-states own (0.17 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 196 calls, 45,099 t-states own (0.04 %) |
| Called from | `DrawCell` |
| Calls | `MapCell`, `FindLatestBlock`, `FindRobot`, `FindBuilding`, `DrawMoverSprite` (tail), `DrawSprite`, `AddAToHL` |
| Reads | `$CE56`-`$CE66` (`BuildingSprites`, `BuildingHeights`); `$DA02`-`$DA34` (`work space $DA02+`); `$EB23` (`work space $EB23+`); `$FF4B`-`$FF4E` (`work space $FF4B+`) |
| Writes | `$CF3F` (`DrawSprite+18`); `$DA20`-`$DA21` (`work space $DA20+`); `$EB23` (`work space $EB23+`) |

#### `DrawMover` (`$CE68`)

**Draw robot or shot IY found at cell HL (view row D, column E), after the blocks that overlap it**

Robots and shots keep their real position in +`$02`/+`$03` (x) and +`$04` (y) and in +`$00`/+`$01` the cell the walk draws them at. At the real cell FindLatestBlock looks for a later neighbouring block; if there is one, the object is moved there (bit 6 set on it, +`$00`/+`$01` = it) and nothing is drawn yet. When the walk reaches the deferred cell, +`$00`/+`$01` is set back to the real cell, the deferred cell's bit 6 is cleared and the view position is walked back from the deferred cell to the real one (x first, then y), and DrawMoverSprite draws the object there. So a robot is drawn after (over) every block whose sprite overlaps it. In NE's deep recording 1485 robot draws reached here; 18 were deferred (each drawn later at the walked-back position), 1449 drawn at once. No shot reached here: see DrawCellObject.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawMoverSprite` (`$CEC3`)

**Draw IY: a robot record (`$DA00` up) as a stack of parts, a shot as one sprite**

Records at `$D800` and up are robots: DrawRobot. A shot (records at `$D7D3`) is sprite `$2B` + 2 * weapon (+`$07`: 1 cannon, 2 missiles, 3 phasers) + 1 when it flies down or up (+`$05` = 4 or 8), at height +`$08`: `$2D`/`$2E` a cannon shell, `$2F`/`$30` a missile trail, `$31`/`$32` a phaser beam (the sprite pictures in start.bin). The shot branch did not run in NE's recordings.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9,371 calls, 431,218 t-states own (0.02 %) |
| Called from | `DrawCellObject` (tail) |
| Calls | `DrawRobot` (tail) |

#### `DrawRobot` (`$CEE8`)

**Draw robot IY at view row D, column E: its parts bottom up**

Height starts at +`$0D` (the ground under the robot, 0 in the construction menu); for each bit of the parts mask +`$07` from bit 0 (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics) DrawRobotPart draws the part and raises the height. Called by DrawMoverSprite and ShowRobotDesign.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9,385 calls, 3,276,805 t-states own (0.15 %) |
| Called from | `ShowRobotDesign`, `DrawMoverSprite` (tail) |
| Calls | `DrawRobotPart` |
| Reads | `$DA07`-`$DA3D` (`work space $DA07+`) |
| Writes | `$CF3F` (`DrawSprite+18`) |

#### `DrawRobotPart` (`$CEFD`)

**Draw part 8 - B of robot IY facing +`$08`, then raise the height**

Sprite = `$16` + the parts table `$D6C8`[4 * part + direction], direction = the number of the lowest set bit of +`$08` (0 right, 1 left, 2 down, 3 up, the Input bits). After drawing, the height (`$CF3F`) grows by the part's height `$D7B4`[part]: bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 22,873 calls, 6,752,407 t-states own (0.31 %) |
| Called from | `DrawRobot` |
| Calls | `DrawSprite`, `AddAToHL` |
| Reads | `$CF3F` (`DrawSprite+18`); `$D6C8`-`$D6E6` (`PartSpriteTable`); `$D7B4`-`$D7BB` (`PartHeights`); `$DA08`-`$DA38` (`work space $DA08+`) |
| Writes | `$CF3F` (`DrawSprite+18`) |

#### `DrawSprite` (`$CF2D`)

**Draw sprite A at view row D, column E, height (`$CF3F`) into the view buffer**

The isometric projection: the half-byte column L = 2E + D - 24, the pixel row of the sprite's bottom line H = 8D + 100 - 4E - height. So a step along x moves 8 pixels right and 4 up, a step along y 4 right and 8 down. The sprite table `$D6E8` holds two words a sprite (A*2 + 1 for an odd half-byte column: the image shifted by 4 pixels). A sprite: rows, width in bytes, then for each row bottom up (mask, pixels) byte pairs; drawn by AND mask, OR pixels into the 20-byte rows of the buffer `$5B00`, upwards. Clipping: right of column 19 or a bottom line past row `$E1`: nothing; bottom lines `$A0-$E1` skip the rows below the buffer; a negative column skips the left bytes of each row (`$CFAF`), a sprite past column 19 the right bytes; the top stops at `$5B00`. 116709 calls, 978 M T-states in NE's deep recording.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 113,372 calls, 947,348,526 t-states own (43.64 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 3,050 calls, 26,737,897 t-states own (26.59 %) |
| Called from | `DrawMapObjects`, `DrawCell`, `DrawCellObject`, `DrawRobotPart` |
| Calls | `TableWord`, `AddAToHL` |
| Reads | `$5B09`-`$6779` (system); `$6980`-`$7A59` (`SprTracksX`, `SprTracksXRows`, `SprTracksXOdd`, `SprTracksXOddRows` and 40 more); `$846C`-`$8857` (`SprElectronicsYp`, `SprElectronicsYpRows`, `SprElectronicsYpOdd`, `SprElectronicsYpOddRows` and 14 more); `$8E3A`-`$9171` (`SprShip`, `SprShipRows`, `SprShipOdd`, `SprShipOddRows` and 4 more); `$9372`-`$9D9B` (`SprRocksA`, `SprRocksARows`, `SprRocksB`, `SprRocksBRows` and 24 more); `$A050`-`$A0E1` (`SprPost`, `SprPostRows`) |
| Writes | `$5B09`-`$5B13` (system); `$5CB3`-`$5DE5` (system); `$5DF8`-`$5E83` (system); `$5E9E`-`$5F7F` (system); `$5F92`-`$604D` (system); `$6060`-`$63AB` (system); 8 more ranges |

#### `DrawViewBackground` (`$CFD7`)

**Clear the view buffer and paint the corners outside the map**

ClearViewBuffer, FillViewCorner (the solid top left corner), then the diagonal edge strips from `$D6A8`: 6 strips down and left from buffer row 0, column 10 (the top left edge), 3 from row 136, column 18 and 4 of the other diagonal (`$D6B8`) from row 128, column 18 (the bottom right corner, the blue area that DrawPlayScreen colours `$41` / `$71`). Called by DrawView and once by `$A62D`.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,699 calls, 429,217 t-states own (0.02 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 100 calls, 15,900 t-states own (0.02 %) |
| Called from | `Start`, `NewGameSetup`, `DrawView` |
| Calls | `ClearViewBuffer`, `FillViewCorner`, `DrawEdgeStrips` (tail) |

#### `ClearViewBuffer` (`$CFFE`)

**Zero the view buffer `$5B00-$677F` (20 bytes x 160 rows)**

Pushes HL = 0 with SP at `$6780` (198 x 16 bytes, SP kept in `$FD08`), then clears the first 32 bytes with LDIR. Called by DrawViewBackground, ShowRobotDesign and `$CB52`.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,717 calls, 56,411,190 t-states own (2.60 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 100 calls, 2,075,771 t-states own (2.06 %) |
| Called from | `StartRobot`, `ShowRobotDesign`, `DrawViewBackground` |
| Reads | `$5B00`-`$5B1E` (system); `$FD08`-`$FD09` (`work space $FD08+`) |
| Writes | `$5B00`-`$5B1F` (system); `$5FCE`-`$5FD1` (system); `$5FF0`-`$5FF1` (system); `$6060`-`$6061` (system); `$6282`-`$628D` (system); `$64E0`-`$64E5` (system); 2 more ranges |

#### `FillViewCorner` (`$D026`)

**Fill the top left corner of the view buffer: a staircase of 5 bands**

5 bands of 8 rows; the first fills 10 bytes of each row, each next band 2 fewer (10, 8, 6, 4, 2). The fill and skip counts are the operands `$D038` and `$D041`, reset to 10 at the start and moved by 2 after each band. The '98 file holds 0 and `$14` there (NE's tape 10 and 10): the counts after the fifth band of the last call before ZS saved the memory; the start of each call writes 10 into both again, so the code is NE's. Ran 100 times in this part's play recording, 2699 in deep.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,699 calls, 25,864,134 t-states own (1.19 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 100 calls, 958,095 t-states own (0.95 %) |
| Called from | `DrawViewBackground` |
| Calls | `AddAToHL` |
| Reads | `$D038`-`$D041` (`CornerRowLoop+2`, `CornerByteLoop`) |
| Writes | `$5B00`-`$5D81` (system); `$5D94`-`$5D95` (system); `$5DA8`-`$5DA9` (system); `$5DBC`-`$5DBD` (system); `$5DD0`-`$5DD1` (system); `$5DE4`-`$5DE5` (system); 3 more ranges |

#### `DrawEdgeStrips` (`$D057`)

**Copy B strips of 8 rows x 2 bytes (pattern HL) into the buffer, each 8 rows down and 2 bytes left**

The diagonal edge of the map in the view. The patterns are at `$D6A8` (ink on the left: `$FFFF`, `$FFFC`, ..., `$C000`) and `$D6B8` (ink on the right).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 8,097 calls, 23,625,732 t-states own (1.09 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 300 calls, 875,480 t-states own (0.87 %) |
| Called from | `DrawViewBackground` (tail) |
| Reads | `$D6A8`-`$D6C7` (`ViewEdgeA`, `ViewEdgeB`) |
| Writes | `$5B0A`-`$5DE5` (system); `$5DF8`-`$5E83` (system); `$5E9E`-`$5EAD` (system); `$6512`-`$6717` (system); `$6728`-`$672B` (system); `$673C`-`$673F` (system); 2 more ranges |

#### `CopyViewToScreen` (`$D071`)

**Copy the view buffer to the screen at character row 1, column 1 (20 x 20 characters)**

160 lines of 20 bytes with unrolled LDI, the destination stepped through the screen's thirds. 256 M T-states in NE's deep recording.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,698 calls, 166,562,531 t-states own (7.67 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 6,050,128 t-states own (6.02 %) |
| Called from | `DrawView` (tail) |
| Reads | `$5B00`-`$677F` (system) |
| Writes | `$4021`-`$5194` (screen); `$5201`-`$5294` (screen); `$5301`-`$5394` (screen); `$5401`-`$5494` (screen); `$5501`-`$5594` (screen); `$5601`-`$5694` (screen); 1 more ranges |

### screen

`src/game98/screen.asm`

#### `ClearScreen` (`$D0B9`)

**Clear the screen (pixels and attributes to 0) and make the border black**

Clears the 6912 bytes of pixels and attributes from `$4000` and sets the border black (and the speaker off) with OUT (`$FE`),0. Called by DrawPlayScreen, MainMenu `$C100`, RedefineKeys `$C34A` and OpenConstructionMenu `$C865`. Changes A, BC, DE, HL.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9 calls, 1,307,061 t-states own (0.06 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 2 calls, 290,458 t-states own (0.29 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1 call, 145,229 t-states own (0.49 %) |
| Called from | `MainMenu`, `ConstructionMenu`, `DrawPlayScreen` |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |
| Ports out | `$00FE` |

#### `ClearScreenFill` (`$D0C7`)

**ClearScreen's LDIR**

An entry only because NE's recording work/game started inside this LDIR; no code jumps here.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawPlayScreen` (`$D0CA`)

**Draw the whole play screen: the view, its frame, the colours, DAY / TIME / RADAR**

ClearScreen and DrawView, then the frame of the view (22 x 22 characters from (0,0): double lines at the top and bottom, `$81` lines at the sides), the attributes: `$07` everywhere, `$3D` (cyan ink on white) on the frame, `$30` (yellow paper) in the view, `$31` and `$01` (blue) in its bottom right corner, the area past the map's edge. ZS took BRIGHT off every colour the routine writes and turned the frame's ink from black to cyan (NE: `$78`, `$70`, `$71`, `$41`, eleven operands from `$D15B` to `$D1BE`). Prints PlayScreenText. Called at the start of play (`$A68E`) and after the construction menu (`$CB52`).

PlayScreenText ends the code: PrintInline returns into ShowStatusPanel, so the panel's labels come with every play screen; the numbers come with the next UpdateStatusPanel. The radar appears at the next frame's PlayInterrupt.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 5 calls, 238,495 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 47,699 t-states own (0.05 %) |
| Called from | `Start`, `NewGameSetup`, `StartRobot` |
| Calls | `DrawView`, `ClearScreen`, `NextScreenLine`, `AddAToHL`, `PrintInline` |
| Reads | `$4000`-`$4014` (screen); `$4701`-`$4713` (screen); `$50A1`-`$50B3` (screen); `$57A0`-`$57B4` (screen); `$5800`-`$5AFE` (screen) |
| Writes | `$4000`-`$50B5` (screen); `$5100`-`$51A0` (screen); `$51B5` (screen); `$5200`-`$52A0` (screen); `$52B5` (screen); `$5300`-`$53A0` (screen); 9 more ranges |

#### `ShowStatusPanel` (`$D1E5`)

**Clear the right panel and print the status labels**

ClearPanel, then StatusPanelText. Called when the robot menu ends (CloseRobotMenu `$A819`) and at the game's end (GameStop `$AF07`). DrawPlayScreen falls into it after its own string, so every play screen gets the labels. The numbers come from UpdateStatusPanel.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 9 calls, 306 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 34 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `PrintInline` |
| Calls | `ClearPanel`, `PrintInline` |

#### `UpdateStatusPanel` (`$D293`)

**Print the panel's numbers: resources, both sides' buildings, our robots (not the enemy's)**

Skipped while PanelBusy (`$FD39`) is not 0 (the robot menu owns the panel). Prints the seven Resources at (17-23, 30) as two digits, attribute `$4E`; the enemy's building counts EnemyBuildings `$FD42` (by type 0-6) at (6-12, 22) (NE also printed EnemyRobotCount `$FD49` at (13,22); the '98 does not, see PrintInsgCounts); the player's counts PlayerBuildings `$FD3A` at (6-12, 31) and robots PlayerRobotCount `$FD41` at (13,30), attribute `$47`. Called after the counts change (a capture `$AE1A`, the day's production `$AE4A`, a robot removed `$B150`, an enemy robot built `$B91C`, the blast `$BA84`) and from CheckWarbasePad (`$A70A`) after a robot is built.

The four parts are each a CALL PrintInline with a position string and the code after it (the entries below). PrintNewline comes before each resource, so the first lands on row 17.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 54 calls, 2,084 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 8 calls, 312 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `GameTurnEnd`, `DailyProduction`, `EnemyCommander`, `PrintInline` |
| Calls | `PrintInline` |
| Reads | `$FD39` (`work space $FD39+`) |

#### `PrintResourceValues` (`$D2A3`)

**The seven resource values, each on the next line (the tail of `$D293`)**

Seven lines from Resources (`$FD22`: general, electronics, nuclear, phasers, missiles, cannon, chassis), each PrintNewline then PrintNumber2: rows 17-23, column 30, blank leading zero. Falls into the next position string.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 52 calls, 46,280 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 8 calls, 7,120 t-states own (0.01 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2`, `PrintInline`, `PrintNewline` |
| Reads | `$FD22`-`$FD28` (`work space $FD22+`) |

#### `PrintInsgCounts` (`$D2C1`)

**The enemy's building counts; its robot count is no longer printed (the tail of `$D293`)**

The enemy's seven building counts EnemyBuildings (`$FD42`: warbases, then the six factory kinds) as single digits down column 22, rows 6-12. Then A = EnemyRobotCount (`$FD49`, the byte after them) is loaded but not printed: ZS replaced NE's CALL PrintNumber2Zero (`$D3EC`) at `$D2C8` with three NOPs, so the INSG column's ROBOTS row (13,22) stays as ClearPanel left it, blank. The player never sees how many robots the enemy has (the counter itself is kept: EnemyCommander reads it). Falls into the player's position string. Ran 8 times in the play recording, 52 in deep.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 52 calls, 3,276 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 8 calls, 504 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintDigitColumn`, `PrintInline` |
| Reads | `$FD49` (`work space $FD49+`) |

#### `PrintHumnCounts` (`$D2D2`)

**The player's building counts (the tail of `$D293`)**

The player's seven building counts PlayerBuildings (`$FD3A`) down column 31, rows 6-12. HL ends at PlayerRobotCount. Falls into the next position string.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 52 calls, 2,288 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 8 calls, 352 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintDigitColumn`, `PrintInline` |

#### `PrintHumnRobots` (`$D2DF`)

**The player's robots `$FD41`, two digits (the tail of `$D293`)**

PlayerRobotCount (`$FD41`, HL from PrintHumnCounts) as two digits with a leading zero; the JP returns from UpdateStatusPanel.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 52 calls, 884 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 8 calls, 136 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2Zero` (tail) |
| Reads | `$FD41` (`work space $FD41+`) |

#### `PrintDigitColumn` (`$D2E3`)

**Print seven bytes from HL as single digits, one under the other**

Each byte as "0" + n (a count of 10 or more would print ":" and the characters after it; never seen, a side has at most 4 warbases), then PrintNewline: the same column one row down. HL ends past the seventh byte (the robot count that follows). Used by PrintInsgCounts and PrintHumnCounts.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 104 calls, 80,600 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 16 calls, 12,400 t-states own (0.01 %) |
| Called from | `PrintInsgCounts`, `PrintHumnCounts` |
| Calls | `PrintCharKeep`, `PrintNewline` |
| Reads | `$FD3A`-`$FD48` (`work space $FD3A+`) |

#### `ClearPanel` (`$D2F6`)

**Blank the right panel: 22 lines of 10 spaces from (2,22) in attribute 0**

Called by ShowStatusPanel and by the robot menus (RobotMenuShow `$A732`, CloseRobotMenu `$A812`, OrdersMenu `$A971`, OrderMove `$AA15`, TargetMenu `$AAD2`, CaptureMenu `$AB4E`, CombatMenu `$AC00`) and GameStop (`$AF04`) before they print. Attribute 0 (black on black) hides the area at once; rows 22-23 of the panel (STRENGTH) are cleared too.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 29 calls, 493 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 17 t-states own (0.00 %) |
| Called from | `RobotMenuShow`, `ShowOrderMiles`, `OrdersMenu`, `TargetMenu`, `CaptureMenu`, `ShowStatusPanel` |
| Calls | `PrintInline` |

#### `ClearPanelLines` (`$D301`)

**22 lines (the tail of ClearPanel)**

B = 22: rows 2-23. B survives each PrintInline: it works in the alternate registers.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 29 calls, 203 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 7 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ClearPanelLine` |

#### `ClearPanelLine` (`$D303`)

**Print 10 spaces and a newline**

One CALL PrintInline with PanelBlankLine; the code goes on at ClearPanelNext.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 638 calls, 10,865 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 22 calls, 374 t-states own (0.00 %) |
| Called from | `ClearPanelLines`, `ClearPanelNext` (tail) |
| Calls | `PrintInline` |

#### `ClearPanelNext` (`$D312`)

**The next of the 22 lines**

DJNZ back to ClearPanelLine for the 22 rows, then the return from ClearPanel.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 638 calls, 8,439 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 22 calls, 291 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ClearPanelLine` (tail) |

#### `DrawMaskedUp` (`$D315`)

**Draw a masked image on the screen: C lines of B (mask, pixel) pairs from HL to DE, going up**

Each line ANDs the mask and ORs the pixels; DE moves one screen line up (PrevScreenLine) after each. The sprite format of DrawSprite without its header: the caller (PartIconDraw `$C895`, the construction menu's part pictures, 56 calls) passes B = bytes a line, C = lines, HL = the first pair of the bottom line, DE = the screen address of the bottom line. Out: HL past the picture. No clipping.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 32 calls, 224,792 t-states own (0.01 %) |
| Called from | `ConstructionMenu` |
| Calls | `PrevScreenLine` |
| Reads | `$4030`-`$4112` (screen); `$4130`-`$4212` (screen); `$4230`-`$4312` (screen); `$4330`-`$4412` (screen); `$4430`-`$4512` (screen); `$4530`-`$4612` (screen); 10 more ranges |
| Writes | `$4030`-`$4212` (screen); `$4230`-`$4312` (screen); `$4330`-`$4412` (screen); `$4430`-`$4512` (screen); `$4530`-`$4612` (screen); `$4630`-`$4712` (screen); 1 more ranges |

#### `NextScreenLine` (`$D32A`)

**HL = the screen address one pixel line down**

The Spectrum's screen order: the line inside a character row is bits 0-2 of H, the character row bits 5-7 of L, the third bits 3-4 of H. Keeps everything but A and the flags. Used by ShowRadar, the frame of DrawPlayScreen, the big characters of PrintBigChar and ShowRobotDesign's copy (`$CC74`).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 477,284 calls, 14,173,428 t-states own (0.65 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 16,516 calls, 491,332 t-states own (0.49 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 544 calls, 16,796 t-states own (0.06 %) |
| Called from | `ShowRobotDesign`, `DrawPlayScreen`, `PrintControl`, `PrintBigChar`, `ShowRadar` |

#### `PrevScreenLine` (`$D339`)

**DE = the screen address one pixel line up**

The reverse of NextScreenLine on DE: used only by DrawMaskedUp, which draws from the bottom line up. Keeps everything but A and the flags.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 756 calls, 22,936 t-states own (0.00 %) |
| Called from | `DrawMaskedUp` |

#### `TableWord` (`$D348`)

**HL = the word at HL + 2*A**

The sprite table lookup of DrawSprite, also ConstructionMenu (PartIconLoop `$C881`) and DrawShape (`$BD67`). A is an index 0-127 (A*2 must fit a byte). Changes A.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 113,494 calls, 6,244,089 t-states own (0.29 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 3,140 calls, 172,738 t-states own (0.17 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 2 calls, 110 t-states own (0.00 %) |
| Called from | `DrawShape`, `ConstructionMenu`, `DrawSprite` |
| Calls | `AddAToHL` |
| Reads | `$BF9C`-`$BFAF` (`ShapeTable`); `$C02E`-`$C02F` (`ShapeMidTiles+22`); `$C04A`-`$C04B` (`ShapeTallWallH+2`); `$D6E8`-`$D6EF` (`SpriteTable`); `$D70A`-`$D72B` (`SpriteTable+34`); `$D73E`-`$D799` (`SpriteTable+86`) |

#### `AddAToHL` (`$D351`)

**HL += A**

A changed to the new H; BC, DE kept. Used everywhere a table is indexed by a byte (about 50 call sites).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 468,598 calls, 15,468,655 t-states own (0.71 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 12,438 calls, 410,549 t-states own (0.41 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 1,449 calls, 47,817 t-states own (0.16 %) |
| Called from | `PaintMenuItem`, `TerrainTop`, `ObjectTop`, `SteerByOrder`, `SetStepDelay`, `EnemyCommander`, `CountBases`, `SetBaseOwner`, `TitleColourCycle`, `ConstructionMenu`, `ConstructionMenuLoop`, `PrintMenuResources`, `ShowRobotDesign`, `DrawMapObjects`, `DrawCellObject`, `DrawRobotPart`, `DrawSprite`, `FillViewCorner`, `DrawPlayScreen`, `TableWord`, `PrintControl`, `PrintBigChar` |

#### `Random` (`$D358`)

**A = a pseudo-random byte**

A 32-bit shift register at RandomSeed `$FD00-$FD03` (big end first, seeded `$39`,`$30`,`$39`,`$30` by Start): shifted left once, the new bit = bit 3 XOR bit 6 of `$FD00`. Then the byte at the index the previous call used (kept in the operand `$D371`) gives, by its low 2 bits, the new index, and A = the byte there. HL is kept; A and the flags change. 43256 calls in NE's deep recording: the robot AI (`$B1AB`, `$B1F5`, `$B331`), the enemy commander `$B7F4` and its spawns, the blast's scenery, GameTurn (`$AD62`) and the noise of SoundEffect.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 24,502 calls, 4,754,300 t-states own (0.22 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 477 calls, 92,538 t-states own (0.09 %) |
| Called from | `GameTurn`, `RobotStep`, `SteerByOrder`, `EnemyCommander`, `SoundEffect` |
| Reads | `$FD00`-`$FD03` (`work space $FD00+`) |
| Writes | `$D371` (`Random+25`); `$FD00`-`$FD03` (`work space $FD00+`) |

### controls

`src/game98/controls.asm`

#### `WaitKey` (`$D37C`)

**ReadControls; while key 1 (Input bit 7) is held, the pause: wait for another key**

In: nothing. Out: A = Input (also in Input `$FD0C`); the flags of the last OR A. When the pause key (bit 7) is held it loops in PauseLoop until some other control is pressed with the pause key up, then falls into ReadControls again: the control that ended the pause is this turn's input. Changes A, BC, HL. Called once a turn by PlayLoop, DirectControlLoop, DistanceLoop, ListMenu, WaitRelease, GameOverKey, RobotDirectControl and ConstructionMenuLoop.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 6,600 calls, 211,276 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 3,136 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu`, `WaitRelease`, `ConstructionMenuLoop` |
| Calls | `ReadControls` |

#### `ReadControls` (`$D38A`)

**Input from the redefinable keys (KeyTable) or the joystick the menu chose (Controls)**

The eight keys of KeyTable are rotated into C one by one (RL C, starting from C = 1: after the eighth the 1 drops into the carry and ends the loop), entry 0 ending in bit 7. Then the joystick by Controls (`$D3E4`): 2 Kempston (port `$1F`, bits 0-4 already right, left, down, up, fire), 3 Interface 2 (port `$EFFE`, keys 6-0, inverted and reordered), else none. Out: A = Input = joystick OR keys. Changes B, C, HL. 9814 calls in NE's deep recording.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 6,600 calls, 4,654,292 t-states own (0.21 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 98 calls, 68,208 t-states own (0.07 %) |
| Called from | `WaitKey` |
| Reads | `$D3CC`-`$D3E4` (`KeyTable`, `Controls`) |
| Writes | `$FD0C` (`work space $FD0C+`) |
| Ports in | `$001F`, `$7FFE`, `$DFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### print

`src/game98/print.asm`

#### `PrintNumber2` (`$D3E5`)

**Print A (0-99) as two digits, a leading zero blank**

In: A. HL = A, E = `$20`, then PrintTensUnits: a space for a leading zero. Used for the resources (PrintResourceValues), the construction menu values and the miles of ADVANCE / RETREAT. A value of 100 or more would print a tens "digit" above 9 (":" and on); the game caps every resource at 99.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 462 calls, 13,860 t-states own (0.00 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 56 calls, 1,680 t-states own (0.00 %) |
| Called from | `PrintMenuResourceValue`, `PrintResourceValues` |
| Calls | `PrintTensUnits` (tail) |

#### `PrintNumber2Zero` (`$D3EC`)

**Print A (0-99) as two digits with a leading zero**

The clock (`$AD90`, 6828 calls: "20.20") and the robot counts of the panel.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 5,438 calls, 163,159 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 202 calls, 6,060 t-states own (0.01 %) |
| Called from | `GameTurnEnd`, `PrintHumnRobots` (tail) |
| Calls | `PrintTensUnits` (tail) |

#### `PrintNumber5` (`$D3F3`)

**Print HL as five digits, leading zeros blank**

Used by `$AD90` for the day number ("DAY:    4"). Falls into PrintNumber3.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 2,693 calls, 164,311 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 97 calls, 8,536 t-states own (0.01 %) |
| Called from | `GameTurnEnd` |
| Calls | `PrintDigit` |

#### `PrintNumber3` (`$D401`)

**Print HL as three digits (E = `$20`: leading zeros blank, else printed)**

The operand `$FF9C` is -100 (the source writes it so with @isub; as a label it would read Buildings+155, a false symbol). Used by PrintMenuTotal and `$A833`.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 78 calls, 74,855 t-states own (0.00 %) |
| Called from | `ShowStrengthValue`, `PrintMenuTotal` (tail) |
| Calls | `PrintDigit` |

#### `PrintTensUnits` (`$D407`)

**Print the tens and the units of HL**

HL = the value (0-99, else the tens "digit" runs past 9: 200 prints as "D0"), E = the leading-zero flag. The tens by PrintDigit, the units always printed. The tail of PrintNumber2, PrintNumber2Zero, PrintNumber3 and PrintNumber5.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 5,900 calls, 416,303 t-states own (0.02 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 258 calls, 17,059 t-states own (0.02 %) |
| Called from | `PrintNumber2` (tail), `PrintNumber2Zero` (tail) |
| Calls | `PrintDigit`, `PrintCharKeep` (tail) |

#### `PrintDigit` (`$D413`)

**Print the digit of HL for the power -BC; HL keeps the rest**

Counts how often BC (a negative power of 10) can be added. A zero while E = `$20` prints a space and keeps E; any printed digit increments E, so later zeros print as 0.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 16,828 calls, 1,489,331 t-states own (0.07 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 646 calls, 56,972 t-states own (0.06 %) |
| Called from | `PrintNumber5`, `PrintNumber3`, `PrintTensUnits` |
| Calls | `PrintCharKeep` |

#### `PrintCharKeep` (`$D427`)

**PrintChar A with BC, DE, HL kept (EXX around)**

PrintChar in the alternate registers: the caller's BC, DE, HL are kept (the number printers keep HL, E and the loop counters in them). A and the flags change.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 28,984 calls, 1,014,687 t-states own (0.05 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1,210 calls, 42,350 t-states own (0.04 %) |
| Called from | `ShowStrengthValue` (tail), `GameTurnEnd`, `PrintDigitColumn`, `PrintTensUnits` (tail), `PrintDigit` |
| Calls | `PrintChar` |

#### `PrintInline` (`$D42D`)

**print the text after the CALL: 0 ends, 1 Y X a position, 2 A an attribute, 3 the next line, 4 N a setting, else a character**

In: the string after the CALL. Pops the return address, takes a byte, pushes the address one byte on, until a 0: the RET then lands after the string. Each byte goes to PrintControl (codes 1-4 and characters). Works in the alternate set (EXX at both ends), so the caller's BC, DE, HL are kept; A and the flags change. Callers also end in it with JP (PrintKeyPrompt `$C40C`), so the bytes after their own CALL are the string. About 60 call sites: every screen and panel text.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 3,793 calls, 1,791,167 t-states own (0.08 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 162 calls, 77,265 t-states own (0.08 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 8 calls, 9,646 t-states own (0.03 %) |
| Called from | `RobotMenuShow`, `ShowOrder`, `ShowStrength`, `OrdersMenu`, `TargetMenu`, `CaptureMenu`, `GameTurn`, `MainMenu`, `MainMenuOptions`, `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option`, `PrintTitle`, `ControlsOptionAttr`, `ConstructionMenu`, `PrintMenuResources`, `PrintMenuResource`, `DrawPlayScreen`, `ShowStatusPanel`, `UpdateStatusPanel`, `PrintResourceValues`, `PrintInsgCounts`, `PrintHumnCounts`, `ClearPanel`, `ClearPanelLine` |
| Calls | `ShowOrder`, `ShowOrderMiles`, `ShowStrengthValue`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose`, `GameTurnEnd`, `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option`, `MainMenuKeys`, `PrintTitleEnd`, `ControlsOptionPlain`, `ControlsOptionChosen`, `ConstructionMenuSetup`, `PrintMenuTotal`, `PrintMenuResourceValue`, `ShowStatusPanel`, `UpdateStatusPanel`, `PrintResourceValues`, `PrintInsgCounts`, `PrintHumnCounts`, `PrintHumnRobots`, `ClearPanelLines`, `ClearPanelNext`, `PrintControl` |
| Reads | `$A738`-`$ABB8` (`RobotMenuText`, `ShowOrder`, `OrderLineHead`, `OrderLine` and 35 more); `$AD88`-`$AD8F` (`ClockPos`); `$C109`-`$C191` (`MenuStartText`, `MenuKeyboardOption`, `MenuKeyboardText`, `MenuKempstonOption` and 3 more); `$C1E6`-`$C1FB` (`TitleText`); `$C33F`-`$C348` (`OptionAttrPlain`, `ControlsOptionPlain`, `OptionAttrChosen`); `$C8BE`-`$C9E6` (`ConstructionTitleText`, `PartNamesText`, `ExitStartText`, `PartCostsText` and 1 more); 2 more ranges |

#### `PrintControl` (`$D43C`)

**PrintInline's byte A: control codes 1-4 or a character**

1 Y X: the position (row Y, column X, kept in `$FD32`/`$FD31`). 2 A: the attribute `$FD13`. 3: newline (the next row, the same column). 4 N: the size, high nibble the height in character rows (`$FD16`), low nibble the width in bytes (`$FD17`); 0 = normal. A character goes to PrintChar for size 0, else to PrintBigChar. The operands are read through the caller's return address on the stack, two levels up.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 20,710 calls, 2,289,018 t-states own (0.11 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 895 calls, 97,442 t-states own (0.10 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 123 calls, 167,497 t-states own (0.56 %) |
| Called from | `PrintInline` |
| Calls | `NextScreenLine`, `AddAToHL`, `PrintNewline` (tail), `SetPrintPos` (tail), `PrintChar` (tail), `PrintBigChar` (tail) |
| Reads | `$6780`-`$678F` (`Font`); `$67B8`-`$67BF` (`Font+56`); `$67F0`-`$682F` (`Font+112`); `$6840`-`$684F` (`Font+192`); `$6888`-`$6957` (`Font+264`); `$A739`-`$A831` (`RobotMenuText+1`, `ShowOrder`, `OrderLineHead`, `OrderLine` and 6 more); 11 more ranges |
| Writes | `$4022`-`$407D` (screen); `$4122`-`$417D` (screen); `$4222`-`$427D` (screen); `$4322`-`$437D` (screen); `$4422`-`$447D` (screen); `$4522`-`$457D` (screen); 21 more ranges |

#### `PrintNewline` (`$D470`)

**The next print row, the same column**

PrintRow + 1, then SetPrintPos. Reached by code 3 inside PrintInline and called directly by the number printers' callers (GameTurnEnd `$AD96`, ResourceValueLoop, PrintDigitColumn, ReadFireKey `$C3CA`). Changes A, BC, HL.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 4,783 calls, 258,339 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 315 calls, 17,010 t-states own (0.02 %) |
| Called from | `GameTurnEnd`, `PrintResourceValues`, `PrintDigitColumn`, `PrintControl` (tail) |
| Calls | `SetPrintPos` (tail) |
| Reads | `$FD31`-`$FD32` (`work space $FD31+`) |
| Writes | `$FD31`-`$FD32` (`work space $FD31+`) |

#### `SetPrintPos` (`$D493`)

**Print position: B = row, C = column -> `$FD04` the screen address, `$FD14` the attribute address**

In: B = row 0-23, C = column 0-31. PrintAddr = `$4000` + (B AND `$18`) * 256 + (B AND 7) * 32 + C, the top line of the character cell; PrintAttrAddr = `$5800` + 32 * B + C. Changes A, HL. Used by SetPosition and PrintNewline.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 8,143 calls, 1,050,713 t-states own (0.05 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 452 calls, 58,327 t-states own (0.06 %) |
| Called from | `PrintControl` (tail), `PrintNewline` (tail) |
| Writes | `$FD04`-`$FD15` (`work space $FD04+`) |

#### `PrintChar` (`$D4B1`)

**Print character A at the print position in the print attribute, advance one column**

The font is at `$6680` + 8*code (`$6780` for the space, right after the view buffer). 8 lines into (`$FD04`), the attribute (`$FD13`) into (`$FD14`), both advanced.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 39,354 calls, 19,604,068 t-states own (0.90 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1,648 calls, 820,951 t-states own (0.82 %) |
| Called from | `PrintCharKeep`, `PrintControl` (tail) |
| Reads | `$6780`-`$678F` (`Font`); `$67A8`-`$67BF` (`Font+40`); `$67E8`-`$6857` (`Font+104`); `$6878`-`$694F` (`Font+248`); `$FD04`-`$FD15` (`work space $FD04+`) |
| Writes | `$4016`-`$483F` (screen); `$4855`-`$57DF` (screen); `$57F6`-`$57FF` (screen); `$5816`-`$581F` (screen); `$5835`-`$583F` (screen); `$5856`-`$5A1F` (screen); 4 more ranges |

#### `PrintBigChar` (`$D4DA`)

**Print character A scaled: each line repeated `$FD16` times, width 1 or 2 bytes (`$FD17`)**

Width 1: each glyph line written `$FD16` times (2: a character two rows high, "RADAR:"). Width 2: each glyph byte doubled to 16 bits. Then the screen address moves on by the width and a block of width x height attribute cells gets `$FD13`. 180 calls in NE's deep recording.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 111 calls, 264,395 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 33 calls, 125,828 t-states own (0.13 %) |
| Called from | `PrintControl` (tail) |
| Calls | `NextScreenLine`, `AddAToHL` |
| Reads | `$6780`-`$6787` (`Font`); `$67B8`-`$67BF` (`Font+56`); `$67F0`-`$6807` (`Font+112`); `$6840`-`$6857` (`Font+192`); `$6888`-`$68CF` (`Font+264`); `$68E8`-`$68FF` (`Font+360`); 3 more ranges |
| Writes | `$4003`-`$427D` (screen); `$4303`-`$437D` (screen); `$4403`-`$447D` (screen); `$4503`-`$457D` (screen); `$4603`-`$467D` (screen); `$4703`-`$477D` (screen); 9 more ranges |

### interrupts

`src/game98/interrupts.asm`

#### `PlayInterrupt` (`$D566`)

**the interrupt handler of play, one a frame**

Installed by EnterPlay (`$A694`) and when the construction menu ends (`$CBA2`). Keeps AF, BC, DE, HL (not IX, IY, the alternate set: the routines it calls do not use them). TurnFrames + 1 (TurnPace `$AE1D` waits for 10, then zeroes it); RadarPhase toggled, ShowRadar with RadarOwn / `$4D` on phase 0, RadarEnemy / `$4E` on phase 1; SoundFx not 0: counted on (a tone ends at `$80`, a noise when it wraps to 0) and SoundEffect plays this frame's step. Ends in StartInterrupt's EI; RET. 34645 entries in NE's deep recording, one a frame of play.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 29,556 calls, 6,483,850 t-states own (0.30 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 973 calls, 212,890 t-states own (0.21 %) |
| Calls | `StartInterrupt`, `ShowRadar`, `SoundEffect` |
| Reads | `$FD1A` (`work space $FD1A+`); `$FD34` (`work space $FD34+`); `$FD53` (`work space $FD53+`) |
| Writes | `$FD1A` (`work space $FD1A+`); `$FD34` (`work space $FD34+`); `$FD53` (`work space $FD53+`) |

#### `StartInterrupt` (`$D59C`)

**the interrupt handler while the start-up runs**

Also the end of PlayInterrupt. Installed alone by Start (FillVectorTable `$A614`), GameStop (`$AF0A`), the end of MenuMusic (`$C520`) and OpenConstructionMenu (`$C85E`): no frame counting, no radar, so the world stands while it is in place.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 30,263 calls, 423,682 t-states own (0.02 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1,003 calls, 14,042 t-states own (0.01 %) |
| Runs (the menu, LOAD NEW LEVEL, the menu again, START) | 22 calls, 308 t-states own (0.00 %) |
| Called from | `PlayInterrupt` |

#### `ShowRadar` (`$D59E`)

**Show radar picture HL (16 lines x 16 bytes) at (22,6) in attribute C**

The interrupt alternates the two pictures `$D800` (terrain + the player's robots, attribute `$4D`) and `$D900` (terrain + the enemy's robots, `$4E`) every frame, so the terrain stays and each side's robots blink in their colour. The attributes are rows 22 and 23, columns 6-21.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 29,555 calls, 201,062,665 t-states own (9.26 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 972 calls, 6,612,516 t-states own (6.58 %) |
| Called from | `PlayInterrupt` |
| Calls | `NextScreenLine`, `FillAttr16` |
| Reads | `$D800`-`$D9FF` (`RadarOwn`, `work space $D880+`) |
| Writes | `$50C6`-`$50F5` (screen); `$51C6`-`$51F5` (screen); `$52C6`-`$52F5` (screen); `$53C6`-`$53F5` (screen); `$54C6`-`$54F5` (screen); `$55C6`-`$55F5` (screen); 2 more ranges |

#### `FillAttr16` (`$D5BD`)

**Write C into 16 bytes from HL**

In: HL, C. Out: HL past the 16 bytes, B = 0. The tail of ShowRadar (rows 22 and 23 of the radar).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 59,110 calls, 25,299,080 t-states own (1.17 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1,944 calls, 832,032 t-states own (0.83 %) |
| Called from | `ShowRadar` |
| Writes | `$5AC6`-`$5AD5` (screen); `$5AE6`-`$5AF5` (screen) |

#### `SoundEffect` (`$D5C4`)

**The interrupt's sound: A = `$FD53` (1-`$7F` a falling tone, `$C8-$FF` noise)**

Called by PlayInterrupt with A = SoundFx after its step, the flags of A set (never 0 here). A positive (2-`$7F`, a shot fired: SoundFx 1 counted on): C = 500 / (A+2) + 1 pulses, B = A the delay between them; each pulse's level is bit 4 of the next ROM byte from `$0000` (a rough noise), so the bursts get sparser and lower as A counts up each frame: a falling sweep over 126 frames, 3.2 ms at A = 2, about 2 ms from A = 40. A negative (`$C8-$FF`): 30 random speaker levels (Random): the crackle of a hit.

The shot code sets 1 when a shot is fired (`$B709`), `$FC` a miss (3 frames), `$FA` a hit (5 frames), `$C8` a robot destroyed (55 frames, the explosion). Seen in NE's deep recording at frames 18680-18712: 1, 2, ... `$16`, then `$FA-$FF`. Changes A, BC, DE, HL. The border stays black (bits 0-2 of the OUT are 0).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 179 calls, 875,284 t-states own (0.04 %) |
| Called from | `PlayInterrupt` |
| Calls | `Random` |
| Ports out | `$00FE`, `$10FE` |

#### `BuildRadar` (`$D5F8`)

**Build both radar pictures for the 128 columns from `$FD1C`**

Each map cell of the window is one pixel: set when its block type is `$0F` or more (the tall blocks). Copies the terrain picture to `$D900`, then puts the dot of every robot in play (+`$01` not 0, except the one under direct control, +`$0A` = 2) into its side's picture (ToggleRadarDot). Called by `$B029` when the ship moves the window (`$FD52`); once in NE's deep recording, at frame 35.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 1 call, 142,587 t-states own (0.01 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 1 call, 142,587 t-states own (0.14 %) |
| Called from | `PutShipOnMap`, `RefreshRadar` |
| Reads | `$D800`-`$D8FF` (`RadarOwn`, `work space $D880+`); `$DA01`-`$ED7F` (`work space $DA01+`); `$EF00`-`$EF7F` (`work space $EF00+`); `$F100`-`$F17F` (`work space $F100+`); `$F300`-`$F37F` (`work space $F300+`); `$F500`-`$F57F` (`work space $F500+`); 4 more ranges |
| Writes | `$D800`-`$D9FF` (`RadarOwn`, `work space $D880+`) |

#### `ToggleRadarDot` (`$D65A`)

**XOR a 2x2 dot at map column HL, row C into radar picture B (0 player, 1 enemy)**

The dot covers (x, y), (x+1, y) and the line above. Nothing outside the window (RadarDotAddress returns past this routine). XOR: the same call removes the dot again, so the robot code toggles the old position before PlaceRobot toggles the new one.

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 42,822 calls, 2,000,166 t-states own (0.09 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 331 calls, 22,287 t-states own (0.02 %) |
| Called from | `BlinkShipDot` (tail), `RobotStep`, `PlaceRobot` (tail) |
| Calls | `RadarDotAddress` |
| Reads | `$D804`-`$D8F3` (`RadarOwn+4`, `work space $D880+`); `$D90C`-`$D9FD` (`work space $D90C+`) |
| Writes | `$D804`-`$D8F3` (`RadarOwn+4`, `work space $D880+`); `$D90C`-`$D9FD` (`work space $D90C+`) |

#### `RadarDotAddress` (`$D67D`)

**HL = the radar byte of column HL, row C in picture B, A = the pixel mask**

Column x - `$FD1C` must be 0-126, else it pops the return address and returns from ToggleRadarDot. Address = `$D800` + `$100`*B + 16*y + (x-`$FD1C`)/8, mask = `$80` >> ((x-`$FD1C`) AND 7).

| | |
| --- | --- |
| Runs (the bot's '98 game, 30284 frames, 9 game days) | 42,822 calls, 4,974,462 t-states own (0.23 %) |
| Runs (r98 4500-5903: the menu, START GAME, play) | 331 calls, 37,223 t-states own (0.04 %) |
| Called from | `ToggleRadarDot` |
| Reads | `$FD1C`-`$FD1D` (`work space $FD1C+`) |

## The '98 intro (`src/intro98`)

Recordings: `work/stage2/intro98/w-intro` (r98's intro window).

| Module | Entries | Code entries |
| --- | --- | --- |
| `pt3player` | `$C000`-`$CE20` | 80 of 88 |
| `pt3tune` | `$CE21`-`$D88E` | 0 of 1 |
| `intromain` | `$D88F`-`$DAC1` | 10 of 10 |
| `introtext` | `$DAC2`-`$E3B8` | 0 of 1 |
| `intrologo` | `$E3B9`-`$E3FD` | 0 of 2 |
| `robot` | `$E3FE`-`$E6CB` | 2 of 3 |
| `introfont` | `$E6CC`-`$E9FF` | 0 of 2 |

### pt3player

`src/intro98/pt3player.asm`

#### `Pt3Init` (`$C000`)

**the module set up: LD HL,Pt3Module, into InitModule**

Entry +0 of the compiled player. HL = Pt3Module (`$CE21`, the tune right after the player), then InitModule: the pointers, the delay, every channel muted and the AY written silent (through InitState into Pt3Stop). Returns with interrupts off (InitModule's DI). Called once by IntroMain (r98 frame 2048).

| | |
| --- | --- |
| Runs (r98's intro window) | 1 call, 4,426 t-states own (0.00 %) |
| Called from | `IntroMain` |
| Calls | `InitState` (tail) |
| Reads | `$C0A0`-`$C0A1` (`SamplePtrs`); `$C0E0`-`$C0E1` (`OrnamentPtrs`); `$CE85`-`$CE89` (`Pt3Module+100`) |
| Writes | `$C048`-`$C049` (`InitPositions+1`); `$C05F`-`$C07A` (`InitPatterns+1`, `InitPointerLoop`, `InitPointerBase`, `InitSp`); `$C0A0`-`$C0FF` (`SamplePtrs`, `OrnamentPtrs`); `$C3B4` (`ChAVolume+1`); `$C406`-`$C407` (`ChAOrnamentPtr+1`); `$C4D0` (`ChBVolume+1`); 7 more ranges |

#### `Pt3PlayEntry` (`$C005`)

**entry +5: JP Pt3Play, one frame of the tune**

Called by IntroInterrupt every frame (2155 times, r98 frames 2049-4203), with interrupts off.

| | |
| --- | --- |
| Runs (r98's intro window) | 2,155 calls, 21,550 t-states own (0.01 %) |
| Called from | `IntroInterrupt` |
| Calls | `Pt3Play` (tail) |

#### `Pt3StopEntry` (`$C008`)

**entry +8: JP Pt3Stop, the AY silent**

Called once by IntroEnd (frame 4203) when a key ended the intro.

| | |
| --- | --- |
| Runs (r98's intro window) | 1 call, 10 t-states own (0.00 %) |
| Called from | `IntroMain` |
| Calls | `Pt3Stop` (tail) |

#### `InitModule` (`$C02C`)

**HL = the module**

HL = the module. The module address into every reader's operand, the delay, the position pointers (the start and the loop), the pattern table, the 48 sample and ornament pointers (offsets + the address) copied to SamplePtrs / OrnamentPtrs; then InitState.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `InitState` (`$C30E`)

**the channels' start values: RowFrame 3, every row skip counter 1 (decode on the first frame), the ...**

the channels' start values: RowFrame 3, every row skip counter 1 (decode on the first frame), the channels muted, the envelope masks off, RowCounter -1, channel A's pattern pointer at a 0 byte (VolumeTable's first) so that the first frame reads position 0. Falls into Pt3Stop.

| | |
| --- | --- |
| Runs (r98's intro window) | 1 call, 217 t-states own (0.00 %) |
| Called from | `Pt3Init` (tail) |
| Calls | `Pt3Stop` |
| Writes | `$C364` (`ChAMute+1`); `$C3C0` (`ChAEnvMask+1`); `$C480` (`ChBMute+1`); `$C4DC` (`ChBEnvMask+1`); `$C59F`-`$C5A7` (`ChCMute+1`, `ChCSamplePtr`); `$C5FB` (`ChCEnvMask+1`); 5 more ranges |

#### `Pt3Stop` (`$C340`)

**the three volumes 0, then WriteAy with RestoreIy patched to RET (only the AY write)**

the three volumes 0, then WriteAy with RestoreIy patched to RET (only the AY write).

| | |
| --- | --- |
| Runs (r98's intro window) | 2 calls, 220 t-states own (0.00 %) |
| Called from | `Pt3StopEntry` (tail), `InitState` |
| Calls | `WriteAy` |
| Writes | `$C308`-`$C30A` (`AyVolumeA`, `AyVolumeB`, `AyVolumeC`); `$C751` (`RestoreIy`) |

#### `Pt3Play` (`$C358`)

**one frame**

one frame. IYL = 0 (the envelope offset of the samples), IX = the noise of the last frame (IXH) and the mixer 0 (IXL); SP saved in PlaySp (the ticks read with POP). NoiseMixer+3 = IXH: the noise is kept from frame to frame.

| | |
| --- | --- |
| Runs (r98's intro window) | 2,155 calls, 4,783,820 t-states own (2.72 %) |
| Called from | `Pt3PlayEntry` (tail) |
| Calls | `WriteAy` |
| Reads | `$C1CD`-`$C1CF` (`VolumeTable+205`); `$C1F7`-`$C1FF` (`VolumeTable+247`); `$D792`-`$D799` (`Pt3Module+2417`); `$D7B7`-`$D7F8` (`Pt3Module+2454`); `$D81D`-`$D873` (`Pt3Module+2556`) |
| Writes | `$C300`-`$C30C` (`AyToneA`, `AyToneB`, `AyToneC`, `AyUnused` and 4 more); `$C36F` (`ChASamplePos+1`); `$C40A` (`ChAOrnamentPos+1`); `$C41B`-`$C42A` (`ChANote+1`, `ChAToneSlide`, `ChAGlissCount`); `$C48B` (`ChBSamplePos+1`); `$C529` (`ChBOrnamentPos+1`); 3 more ranges |

#### `ChAMute` (`$C363`)

**Channel A, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the ...**

Channel A, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the ornament, the tone and its slide. Runs every frame; the channel's state lives in the operands of these instructions (each label names the value its operand holds). Out: the tone in the AY block, the volume in AyVolumeA (0 when muted), the mixer bits ORed into IXL, the noise into IXH, the envelope offset added to IYL.

ChAMute: 0 while the channel sounds, `$FF` when it is off (`$C0`, before the first note, or the on-off effect's off phase).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBMute` (`$C47F`)

**Channel B, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the ...**

Channel B, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the ornament, the tone and its slide. Runs every frame; the channel's state lives in the operands of these instructions (each label names the value its operand holds). Out: the tone in the AY block, the volume in AyVolumeB (0 when muted), the mixer bits ORed into IXL, the noise into IXH, the envelope offset added to IYL.

ChBMute: 0 while the channel sounds, `$FF` when it is off (`$C0`, before the first note, or the on-off effect's off phase).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBPortaRun` (`$C559`)

**channel B's portamento step (ChBPortaJr cleared)**

Reached when the row's portamento effect cleared ChBPortaJr's displacement: the slide so far against ChBPortaDistance; once the tone has covered the distance, ChBPortaNote becomes the note and the slide ends. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBGlissReload` (`$C578`)

**channel B's gliss counter reloaded**

The gliss / portamento delay back into ChBGlissCount (its operand set by the row's effect), then the tick's end. A jump target of ChBPortaJr and ChBPortaTest. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCMute` (`$C59E`)

**Channel C, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the ...**

Channel C, one tick: the sample line, the volume, the noise or envelope offset, the mixer bits, the ornament, the tone and its slide. Runs every frame; the channel's state lives in the operands of these instructions (each label names the value its operand holds). Out: the tone in the AY block, the volume in AyVolumeC (0 when muted), the mixer bits ORed into IXL, the noise into IXH, the envelope offset added to IYL.

ChCMute: 0 while the channel sounds, `$FF` when it is off (`$C0`, before the first note, or the on-off effect's off phase).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCPortaRun` (`$C677`)

**channel C's portamento step (ChCPortaJr cleared)**

As ChBPortaRun, for channel C. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCGlissReload` (`$C696`)

**channel C's gliss counter reloaded**

As ChBGlissReload, for channel C. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EnvSlideAcc` (`$C6BC`)

**The envelope: EnvPeriod (set by the row) + the samples' offsets (IYL, low byte only) + the slide ...**

The envelope: EnvPeriod (set by the row) + the samples' offsets (IYL, low byte only) + the slide (EnvSlideAcc, stepped by EnvSlideStep every EnvSlideReload frames: effect 8) into AyEnvPeriod.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `WriteAy` (`$C6E1`)

**the AY registers 0-12 from the block AyToneA at a page start (L = the register number; B = `$FF` ...**

the AY registers 0-12 from the block AyToneA at a page start (L = the register number; B = `$FF` selects, B = `$BF` writes): tones, noise (IXH + NoiseBase), mixer (IXL), volumes, envelope period; register 13 only when EnvType holds a new type (then cleared).

| | |
| --- | --- |
| Runs (r98's intro window) | 2,157 calls, 1,430,511 t-states own (0.81 %) |
| Called from | `Pt3Stop`, `Pt3Play` |
| Calls | `ChADecode`, `ChBRowSkip` (tail), `ChCRowSkip` (tail) |
| Reads | `$C100` (`VolumeTable`); `$C300`-`$C30C` (`AyToneA`, `AyToneB`, `AyToneC`, `AyUnused` and 4 more); `$CEEA`-`$CEF0` (`Pt3Module+201`); `$CF36`-`$CF64` (`Pt3Module+277`); `$CFB6`-`$D020` (`Pt3Module+405`); `$D0AA`-`$D193` (`Pt3Module+649`) |
| Writes | `$C35E` (`NoiseMixer+3`); `$C755`-`$C764` (`RowFrame+1`, `ChARowSkip`); `$C784`-`$C790` (`ChAPatternPtr+1`, `PositionPtr`); `$C7BA`-`$C7BB` (`PositionSp+1`); `$C975`-`$C976` (`ChBPatternPtr+1`); `$CB08`-`$CB17` (`ChCPatternPtr+1`, `ChANewNoteJr`); 3 more ranges |
| Ports out | `$BEFD`, `$BFFD`, `$FFFD` |

#### `RestoreIy` (`$C751`)

**IY = `$5C3A` for the ROM's interrupt (Pt3Stop patches this opcode to RET)**

IY = `$5C3A` for the ROM's interrupt (Pt3Stop patches this opcode to RET). Then the row scheduler: RowFrame counts down from the delay: 2 -> channel A's row, 1 -> B's, 0 -> C's (and the staged A and B applied, RowFrame reloaded); above 2 nothing.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChARowSkip` (`$C763`)

**Channel A's row (two frames before the row)**

Channel A's row (two frames before the row). First every staging JR / JP of A is set to skip (H, L, E, A: the displacements); unless ChARowSkip ran out, done. Else the skips go to the alternate set (EXX / EX AF,AF'), B' = 0: each decoded command clears its block's skip (H' note, L' volume, A' ornament / envelope, E' gliss / portamento), C' = the old note (portamento). A 0 at the row's start: the next position (PositionPtr, `$FF` -> LoopPositionPtr), its pattern's three channel pointers (+ the module address) into ChAPatternPtr, ChBPatternPtr, ChCPatternPtr, the noise base 0.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChADecode` (`$C7DA`)

**DE = channel A's bytes; decodes one row (the ranges in the module header above) into the staging operands; ...**

DE = channel A's bytes; decodes one row (the ranges in the module header above) into the staging operands; ends on a note, `$D0` or `$C0` (RET runs the pushed effect routines, which read their parameters from DE). Out: DE = the next row.

| | |
| --- | --- |
| Runs (r98's intro window) | 249 calls, 1,743 t-states own (0.00 %) |
| Called from | `WriteAy` |
| Calls | `ChADecodeLimits` |

#### `ChADecodeLimits` (`$C7DC`)

**B = `$10`, C = `$20`, then the next byte**

Re-entered by the commands that change the H register (sample, ornament): the range steps reloaded (331 entries in the window).

| | |
| --- | --- |
| Runs (r98's intro window) | 331 calls, 3,310 t-states own (0.00 %) |
| Called from | `ChADecode`, `ChAOrnSampleCmd` (tail), `ChASampleCmd` (tail), `ChAOrnamentCmd` (tail) |
| Calls | `ChADecodeByte` |

#### `ChADecodeByte` (`$C7DF`)

**the next byte of channel A's row through the ranges**

One byte of the row: ADD steps through the ranges (module header above) and jumps to its command; an effect number pushes its routine from ChAEffects (526 entries).

| | |
| --- | --- |
| Runs (r98's intro window) | 524 calls, 37,687 t-states own (0.02 %) |
| Called from | `ChADecodeLimits`, `ChAVolumeCmd` (tail), `ChAEnvCmd` (tail) |
| Calls | `ChAOrnSampleCmd` (tail), `ChASampleCmd` (tail), `ChAVolumeCmd` (tail), `ChAEnvCmd` (tail), `ChANoteCmd` (tail), `ChAOrnamentCmd` (tail) |
| Reads | `$C2C2`-`$C2C3` (`ChAEffects+2`); `$C41B` (`ChANote+1`); `$CF30`-`$CF63` (`Pt3Module+271`); `$CFB0`-`$D01A` (`Pt3Module+399`); `$D0A4`-`$D195` (`Pt3Module+643`) |

#### `ChAEffGliss` (`$C814`)

**Channel A's effects (ChAEffects), run after the row's note, DE at their parameters: ChAEffGliss ...**

Channel A's effects (ChAEffects), run after the row's note, DE at their parameters: ChAEffGliss (1): delay, step word; ChAEffPorta (2): delay, distance word, step word (the note stays the old one until the slide has covered the distance, then ChANewPortaNote); ChAEffSampleOffset (3), ChAEffOrnOffset (4): the start position; ChAEffOnOff (5): off frames, on frames. EffEnvSlide (8): delay, step word; EffDelay (9): the delay (shared by the channels).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChAEffPorta` (`$C82C`)

**effect 2 on channel A: portamento**

DE at delay, distance word, step word: staged into ChANewGlissDelay, ChANewPortaDistance, ChANewGlissStep; ChANewPortaJr cleared (the tick runs ChAPortaRun); the new note kept in ChANewPortaNote and the old one (C') played until the slide arrives. Ran twice in the window (COOL WINTER uses portamento on channel A).

| | |
| --- | --- |
| Runs (r98's intro window) | 2 calls, 416 t-states own (0.00 %) |
| Called from | `ChANoteCmd` |
| Reads | `$CB3B` (`ChANewNote+1`); `$D01B`-`$D01F` (`Pt3Module+506`) |
| Writes | `$CB3B` (`ChANewNote+1`); `$CB68`-`$CB81` (`ChANewPortaNote+1`, `ChANewGlissDelay`, `ChANewPortaDistance`, `ChANewGlissStep` and 1 more) |

#### `ChAEffSampleOffset` (`$C855`)

**effect 3 on channel A: the sample's start position**

The position byte into ChANewSamplePos; ChASampleOffJp retargeted to it, so the once-only block runs on the row's frame. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChAEffOrnOffset` (`$C860`)

**effect 4 on channel A: the ornament's start position**

The position byte into ChANewOrnamentPos; ChAOrnOffJp retargeted to it, so the once-only block runs on the row's frame. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChAEffOnOff` (`$C86B`)

**effect 5 on channel A: on-off**

DE at off frames, on frames: staged into ChANewOffTime / ChANewOnTime; ChAOnOffJp retargeted to ChAOnOffApply. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EffEnvSlide` (`$C87B`)

**effect 8 (any channel): the envelope slide**

DE at delay, step word: into NewEnvSlideDelay / NewEnvSlideStep; EnvSlideJr cleared so NewEnvSlideStep runs once on the row's frame. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EffDelay` (`$C88F`)

**effect 9 (any channel): the tune's delay**

The byte at DE into Delay, the frames per row from the next row on. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChAOrnSampleCmd` (`$C895`)

**Channel A's commands (the jumps of ChADecodeByte; A = the byte less the range's start): the sample ...**

Channel A's commands (the jumps of ChADecodeByte; A = the byte less the range's start): the sample and ornament numbers index SamplePtrs / OrnamentPtrs by the low byte (H = HIGH SamplePtrs).

| | |
| --- | --- |
| Runs (r98's intro window) | 10 calls, 1,530 t-states own (0.00 %) |
| Called from | `ChADecodeByte` (tail) |
| Calls | `ChADecodeLimits` (tail) |
| Reads | `$C0AC`-`$C0B9` (`SamplePtrs+12`); `$C0E0`-`$C0FF` (`OrnamentPtrs`); `$CF31` (`Pt3Module+272`); `$CFB1` (`Pt3Module+400`); `$D014` (`Pt3Module+499`); `$D0A5` (`Pt3Module+644`); 3 more ranges |
| Writes | `$CB40`-`$CB41` (`ChANewSample+1`); `$CB5B`-`$CB61` (`ChANewOrnament+1`, `ChANewEnvMask`) |

#### `ChASampleCmd` (`$C8B6`)

**`$D0-$EF` on channel A: the row's end (`$D0`) or a sample**

Z (`$D0`): the row ends with nothing new (ChARowEnd); else the sample's pointer from SamplePtrs into ChANewSample, then ChADecodeLimits (54 entries).

| | |
| --- | --- |
| Runs (r98's intro window) | 54 calls, 3,684 t-states own (0.00 %) |
| Called from | `ChADecodeByte` (tail) |
| Calls | `ChADecodeLimits` (tail) |
| Reads | `$C0AC`-`$C0AF` (`SamplePtrs+12`) |
| Writes | `$CB40`-`$CB41` (`ChANewSample+1`) |

#### `ChAVolumeCmd` (`$C8E1`)

**`$C0-$CF` on channel A: sound off or the channel volume**

Z (`$C0`): ChASoundOff; else volume * 16 into ChANewVolume (a row of VolumeTable), L' = 0 clears the volume block's skip (127 entries).

| | |
| --- | --- |
| Runs (r98's intro window) | 127 calls, 7,366 t-states own (0.00 %) |
| Called from | `ChADecodeByte` (tail) |
| Calls | `ChADecodeByte` (tail) |
| Writes | `$CB48` (`ChANewVolume+1`) |

#### `ChAEnvCmd` (`$C8F0`)

**`$B0-$BF` on channel A: envelope off, row skip, or an envelope**

`$B0`: ChAEnvOff; `$B1`: ChASkipCmd; else the envelope type and its period (2 bytes, high first) into NewEnvType / NewEnvPeriod, the envelope mask on (66 entries).

| | |
| --- | --- |
| Runs (r98's intro window) | 66 calls, 3,894 t-states own (0.00 %) |
| Called from | `ChADecodeByte` (tail) |
| Calls | `ChADecodeByte` (tail) |
| Reads | `$CF34`-`$CF62` (`Pt3Module+275`); `$CFB4` (`Pt3Module+403`); `$D017` (`Pt3Module+502`); `$D0A8`-`$D0B6` (`Pt3Module+647`); `$D0D4`-`$D138` (`Pt3Module+691`); `$D14A`-`$D169` (`Pt3Module+809`); 1 more ranges |
| Writes | `$C7C4` (`ChARowSkipLen+1`) |

#### `ChANoteCmd` (`$C90C`)

**`$50-$AF` on channel A: a note, the row ends**

The note into ChANewNote, ChANoteOnOp = NOP (sounds), H' = 0 clears the note block's skip; RET runs any pushed effect (247 entries).

| | |
| --- | --- |
| Runs (r98's intro window) | 247 calls, 12,844 t-states own (0.01 %) |
| Called from | `ChADecodeByte` (tail) |
| Calls | `ChAEffPorta` |
| Writes | `$CB36`-`$CB3B` (`ChANoteOnOp`, `ChANewNote`) |

#### `ChAOrnamentCmd` (`$C917`)

**`$40-$4F` on channel A: an ornament**

The ornament's pointer from OrnamentPtrs into ChANewOrnament, A' = 0 (the ornament block runs), then ChADecodeLimits (20 entries).

| | |
| --- | --- |
| Runs (r98's intro window) | 20 calls, 1,420 t-states own (0.00 %) |
| Called from | `ChADecodeByte` (tail) |
| Calls | `ChADecodeLimits` (tail) |
| Reads | `$C0E2`-`$C0FF` (`OrnamentPtrs+2`) |
| Writes | `$CB5B`-`$CB5C` (`ChANewOrnament+1`) |

#### `ChBRowSkip` (`$C954`)

**Channel B's row (one frame before the row): as channel A's (ChARowSkip), without the positions**

Channel B's row (one frame before the row): as channel A's (ChARowSkip), without the positions.

| | |
| --- | --- |
| Runs (r98's intro window) | 431 calls, 62,891 t-states own (0.04 %) |
| Called from | `WriteAy` (tail) |
| Calls | `ChBDecode` |
| Writes | `$C955` (`ChBRowSkip+1`); `$C975`-`$C976` (`ChBPatternPtr+1`); `$CBA8` (`ChBNewNoteJr+1`); `$CBD7`-`$CBDE` (`ChBVolumeJr+1`, `ChBNewVolume`, `ChBOrnEnvJr`); `$CBF7` (`ChBGlissJr+1`) |

#### `ChBDecode` (`$C995`)

**as ChADecode; channel B also takes `$20-$3F`, the noise base (ChBNoiseCmd)**

as ChADecode; channel B also takes `$20-$3F`, the noise base (ChBNoiseCmd).

| | |
| --- | --- |
| Runs (r98's intro window) | 54 calls, 378 t-states own (0.00 %) |
| Called from | `ChBRowSkip` |
| Calls | `ChBDecodeLimits` |

#### `ChBDecodeLimits` (`$C997`)

**as ChADecodeLimits, for channel B**

87 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 87 calls, 870 t-states own (0.00 %) |
| Called from | `ChBDecode`, `ChBOrnSampleCmd` (tail), `ChBOrnamentCmd` (tail) |
| Calls | `ChBDecodeByte` |

#### `ChBDecodeByte` (`$C99A`)

**as ChADecodeByte, for channel B**

101 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 101 calls, 8,301 t-states own (0.00 %) |
| Called from | `ChBDecodeLimits`, `ChBVolumeCmd` (tail), `ChBEnvCmd` (tail) |
| Calls | `ChBOrnSampleCmd` (tail), `ChBVolumeCmd` (tail), `ChBEnvCmd` (tail), `ChBNoteCmd` (tail), `ChBOrnamentCmd` (tail) |
| Reads | `$CF65`-`$CF75` (`Pt3Module+324`) |

#### `ChBEffGliss` (`$C9D2`)

**Channel B's effects (ChBEffects): as channel A's**

Channel B's effects (ChBEffects): as channel A's. ChBEffOnOff's jump is wrong (the known bug in the module header).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBEffPorta` (`$C9EA`)

**effect 2 on channel B: portamento**

As ChAEffPorta, into channel B's staging. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBEffSampleOffset` (`$CA13`)

**effect 3 on channel B: the sample's start position**

As ChAEffSampleOffset, through ChBSampleOffJp to ChBNewSamplePos. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBEffOrnOffset` (`$CA1E`)

**effect 4 on channel B: the ornament's start position**

As ChAEffOrnOffset, through ChBOrnOffJp to ChBNewOrnamentPos. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBEffOnOff` (`$CA29`)

**effect 5 on channel B: on-off (with the known bug)**

As ChAEffOnOff, but the byte written into ChBOnOffJp is LOW ChBOnOffJp (`$1A`), not LOW ChBNewOnTime (`$1D`): the staged JP would jump to itself and the player would hang (the bug in the module header). Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBNoiseCmd` (`$CA39`)

**Channel B's commands: as channel A's; ChBNoiseCmd: the noise base for the row**

Channel B's commands: as channel A's; ChBNoiseCmd: the noise base for the row.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBOrnSampleCmd` (`$CA3F`)

**as ChAOrnSampleCmd, for channel B**

7 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 7 calls, 1,071 t-states own (0.00 %) |
| Called from | `ChBDecodeByte` (tail) |
| Calls | `ChBDecodeLimits` (tail) |
| Reads | `$C0AA`-`$C0AB` (`SamplePtrs+10`); `$C0E6`-`$C0E7` (`OrnamentPtrs+6`); `$CF66` (`Pt3Module+325`) |
| Writes | `$CBD1`-`$CBD2` (`ChBNewSample+1`); `$CBEC`-`$CBF2` (`ChBNewOrnament+1`, `ChBNewEnvMask`) |

#### `ChBVolumeCmd` (`$CA8B`)

**as ChAVolumeCmd, for channel B**

7 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 7 calls, 406 t-states own (0.00 %) |
| Called from | `ChBDecodeByte` (tail) |
| Calls | `ChBDecodeByte` (tail) |
| Writes | `$CBD9` (`ChBNewVolume+1`) |

#### `ChBEnvCmd` (`$CA9A`)

**as ChAEnvCmd, for channel B**

7 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 7 calls, 413 t-states own (0.00 %) |
| Called from | `ChBDecodeByte` (tail) |
| Calls | `ChBDecodeByte` (tail) |
| Reads | `$CF69` (`Pt3Module+328`) |
| Writes | `$C97F` (`ChBRowSkipLen+1`) |

#### `ChBNoteCmd` (`$CAB6`)

**as ChANoteCmd, for channel B**

54 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 54 calls, 2,808 t-states own (0.00 %) |
| Called from | `ChBDecodeByte` (tail) |
| Writes | `$CBC7`-`$CBCC` (`ChBNoteOnOp`, `ChBNewNote`) |

#### `ChBOrnamentCmd` (`$CAC1`)

**as ChAOrnamentCmd, for channel B**

26 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 26 calls, 1,846 t-states own (0.00 %) |
| Called from | `ChBDecodeByte` (tail) |
| Calls | `ChBDecodeLimits` (tail) |
| Reads | `$C0E4`-`$C0E7` (`OrnamentPtrs+4`) |
| Writes | `$CBEC`-`$CBED` (`ChBNewOrnament+1`) |

#### `ChCRowSkip` (`$CAFE`)

**Channel C's row (on the row's frame): decoded straight into the tick's operands (ChCDecode), then ...**

Channel C's row (on the row's frame): decoded straight into the tick's operands (ChCDecode), then the staged rows of A and B applied (from ChANewNoteJr), the envelope, the delay.

| | |
| --- | --- |
| Runs (r98's intro window) | 431 calls, 233,046 t-states own (0.13 %) |
| Called from | `WriteAy` (tail) |
| Calls | `ChCDecode` |
| Writes | `$C364`-`$C36F` (`ChAMute+1`, `ChASamplePtr`, `ChASamplePos`); `$C3A4`-`$C3C9` (`ChAVolSlide+1`, `ChALevelHigh`, `ChAVolume`, `ChAEnvMask` and 1 more); `$C3E3` (`ChAEnvOffsetAcc+1`); `$C3FA`-`$C40A` (`ChAToneAcc+1`, `ChAOrnament`, `ChAOrnamentPtr`, `ChAOrnamentPos`); `$C41B`-`$C463` (`ChANote+1`, `ChAToneSlide`, `ChAGlissCount`, `ChAGlissStep` and 10 more); `$C480`-`$C48B` (`ChBMute+1`, `ChBSamplePtr`, `ChBSamplePos`); 11 more ranges |

#### `ChANewNoteJr` (`$CB16`)

**The staged row of channel A, applied after channel C's decode**

The staged row of channel A, applied after channel C's decode. Each block is skipped by its JR unless the decoder cleared the displacement: ChANewNoteJr: a note or sound off: the tick's state cleared (slides, positions, accumulators), ChANoteOnOp (NOP: the note sounds, CPL: muted), ChANewNote, ChANewSample; ChAVolumeJr: the channel volume (ChANewVolume = volume * 16, a row of VolumeTable); ChAOrnEnvJr: ornament or envelope: the ornament from its start, the envelope slide cleared, ChANewOrnament, ChANewEnvMask; ChAGlissJr: gliss / portamento (delay, distance, step, the JR of the tick's test); ChAOnOffJp: the on-off effect (JP to ChAOnOffApply, which sets the JP back to skip).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChAOnOffApply` (`$CB8C`)

**channel A's on-off effect applied once**

Entered through ChAOnOffJp when ChAEffOnOff set it: the gliss and the slide cleared, ChAOnOffJp set back to skip, the on and off times (ChANewOnTime, ChANewOffTime) into the tick, the counter at the on time. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBNewNoteJr` (`$CBA7`)

**The staged row of channel B: as channel A's**

The staged row of channel B: as channel A's.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBNewPortaNote` (`$CBF8`)

**channel B's staged gliss / portamento block**

Run when ChBGlissJr's displacement was cleared by a gliss or portamento row: the porta note, delay, distance, step and the JR of the tick's test (ChBNewPortaJr) into channel B's tick. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBOnOffJp` (`$CC1A`)

**channel B's on-off jump: JP EnvSlideJr unless set**

Its low byte is the target: EnvSlideJr normally (431 entries, every row of the window); ChBEffOnOff writes LOW ChBOnOffJp (`$1A`) here instead of LOW ChBNewOnTime, so the JP would jump to itself (the known bug in the module header).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBNewOnTime` (`$CC1D`)

**channel B's on-off effect applied once (never reached, see ChBOnOffJp)**

As ChAOnOffApply for channel B; ChBEffOnOff's bug means no row can reach it. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EnvSlideJr` (`$CC38`)

**Once-only blocks, entered when a row set them (their JR / JP retargeted, the block retargets it ...**

Once-only blocks, entered when a row set them (their JR / JP retargeted, the block retargets it back): the envelope slide (EnvSlideJr), the sample and ornament offsets of A and B (ChASampleOffJp ...). Then the row's envelope (NewEnvType: 0 = none, NewEnvPeriod), RowFrame reloaded with Delay, the noise base, RowCounter + 1 (the rows played, from 0).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `NewEnvSlideStep` (`$CC3A`)

**the envelope slide set up once (effect 8)**

Entered when EffEnvSlide cleared EnvSlideJr: the step and the delay into EnvSlideStep, EnvSlideCount, EnvSlideReload, EnvSlideJr set back to skip. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChASampleOffJp` (`$CC4D`)

**the once-only jumps: channel A's sample offset unless set**

JP ChAOrnOffJp normally (431 entries); ChAEffSampleOffset retargets it to ChANewSamplePos.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChANewSamplePos` (`$CC50`)

**channel A's sample position set once (effect 3)**

The position into ChASamplePos, ChASampleOffJp set back to skip. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChAOrnOffJp` (`$CC5A`)

**channel A's ornament offset unless set**

JP ChBSampleOffJp normally (431 entries); ChAEffOrnOffset retargets it to ChANewOrnamentPos.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChANewOrnamentPos` (`$CC5D`)

**channel A's ornament position set once (effect 4)**

The position into ChAOrnamentPos, ChAOrnOffJp set back to skip. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBSampleOffJp` (`$CC67`)

**channel B's sample offset unless set**

JP ChBOrnOffJp normally (431 entries); ChBEffSampleOffset retargets it to ChBNewSamplePos.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBNewSamplePos` (`$CC6A`)

**channel B's sample position set once (effect 3)**

As ChANewSamplePos, for channel B. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBOrnOffJp` (`$CC74`)

**channel B's ornament offset unless set**

JP NewEnvType normally (431 entries); ChBEffOrnOffset retargets it to ChBNewOrnamentPos.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChBNewOrnamentPos` (`$CC77`)

**channel B's ornament position set once (effect 4)**

As ChANewOrnamentPos, for channel B. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `NewEnvType` (`$CC81`)

**the row's end: envelope, delay, noise base, row counter**

The envelope type the row set (0 = none) into EnvType and, if any, NewEnvPeriod into EnvPeriod; RowFrame reloaded from Delay, the noise base, RowCounter + 1 (431 entries: the rows of the window).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCDecode` (`$CCA5`)

**as ChADecode, but into channel C's tick at once (no staging)**

as ChADecode, but into channel C's tick at once (no staging).

| | |
| --- | --- |
| Runs (r98's intro window) | 392 calls, 2,744 t-states own (0.00 %) |
| Called from | `ChCRowSkip` |
| Calls | `ChCDecodeLimits` |

#### `ChCDecodeLimits` (`$CCA7`)

**as ChADecodeLimits, for channel C**

578 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 578 calls, 5,780 t-states own (0.00 %) |
| Called from | `ChCDecode`, `ChCOrnSampleCmd` (tail), `ChCSampleCmd` (tail) |
| Calls | `ChCDecodeByte` |

#### `ChCDecodeByte` (`$CCAA`)

**as ChADecodeByte, for channel C**

598 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 598 calls, 40,097 t-states own (0.02 %) |
| Called from | `ChCDecodeLimits`, `ChCEnvCmd` (tail) |
| Calls | `ChCOrnSampleCmd` (tail), `ChCSampleCmd` (tail), `ChCVolumeCmd` (tail), `ChCEnvCmd` (tail), `ChCNoteCmd` (tail) |
| Reads | `$CF77`-`$CFAE` (`Pt3Module+342`); `$D021`-`$D0A2` (`Pt3Module+512`) |

#### `ChCEffGliss` (`$CCDF`)

**Channel C's effects (ChCEffects): as channel A's, applied at once**

Channel C's effects (ChCEffects): as channel A's, applied at once.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCEffPorta` (`$CCFB`)

**effect 2 on channel C: portamento, applied at once**

As ChAEffPorta, but straight into channel C's tick (ChCGlissCount, ChCGlissReload, ChCPortaDistance, ...). Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCEffSampleOffset` (`$CD29`)

**effect 3 on channel C: the sample's start position, at once**

The position byte straight into ChCSamplePos (channel C has no staging). Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCEffOrnOffset` (`$CD2F`)

**effect 4 on channel C: the ornament's start position, at once**

The position byte straight into ChCOrnamentPos. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCEffOnOff` (`$CD35`)

**effect 5 on channel C: on-off, at once**

Off and on frames straight into ChCOffTime / ChCOnTime, the counter at the on time, the gliss and the slide cleared. Not run in the window: known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChCOrnSampleCmd` (`$CD4C`)

**Channel C's commands: as channel A's, applied at once (ChCNoteCmd clears the tick's state)**

Channel C's commands: as channel A's, applied at once (ChCNoteCmd clears the tick's state).

| | |
| --- | --- |
| Runs (r98's intro window) | 185 calls, 29,970 t-states own (0.02 %) |
| Called from | `ChCDecodeByte` (tail) |
| Calls | `ChCDecodeLimits` (tail) |
| Reads | `$C0A2`-`$C0AF` (`SamplePtrs+2`); `$C0E0`-`$C0E3` (`OrnamentPtrs`); `$CF7B` (`Pt3Module+346`); `$D022`-`$D09F` (`Pt3Module+513`) |
| Writes | `$C5A6`-`$C5A7` (`ChCSamplePtr+1`); `$C5FB` (`ChCEnvMask+1`); `$C643`-`$C647` (`ChCOrnamentPtr+1`, `ChCOrnamentPos`) |

#### `ChCSampleCmd` (`$CD6F`)

**as ChASampleCmd, applied to channel C at once**

1 entry in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 1 call, 70 t-states own (0.00 %) |
| Called from | `ChCDecodeByte` (tail) |
| Calls | `ChCDecodeLimits` (tail) |
| Reads | `$C0A8`-`$C0A9` (`SamplePtrs+8`) |
| Writes | `$C5A6`-`$C5A7` (`ChCSamplePtr+1`) |

#### `ChCVolumeCmd` (`$CD99`)

**as ChAVolumeCmd, applied to channel C at once**

1 entry in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 1 call, 55 t-states own (0.00 %) |
| Called from | `ChCDecodeByte` (tail) |
| Writes | `$C59F` (`ChCMute+1`); `$C6A0` (`ChCOnOffCount+1`) |

#### `ChCEnvCmd` (`$CDA5`)

**as ChAEnvCmd, applied to channel C at once**

20 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 20 calls, 1,180 t-states own (0.00 %) |
| Called from | `ChCDecodeByte` (tail) |
| Calls | `ChCDecodeByte` (tail) |
| Reads | `$CF78`-`$CFA9` (`Pt3Module+343`); `$D024` (`Pt3Module+515`) |
| Writes | `$CB12` (`ChCRowSkipLen+1`) |

#### `ChCNoteCmd` (`$CDBF`)

**as ChANoteCmd: the note into channel C's tick, its state cleared**

391 entries in the window.

| | |
| --- | --- |
| Runs (r98's intro window) | 391 calls, 66,861 t-states own (0.04 %) |
| Called from | `ChCDecodeByte` (tail) |
| Writes | `$C59F`-`$C5AA` (`ChCMute+1`, `ChCSamplePtr`, `ChCSamplePos`); `$C5DF` (`ChCVolSlide+1`); `$C604` (`ChCNoiseAcc+1`); `$C61E` (`ChCEnvOffsetAcc+1`); `$C637`-`$C647` (`ChCToneAcc+1`, `ChCOrnament`, `ChCOrnamentPtr`, `ChCOrnamentPos`); `$C658`-`$C667` (`ChCNote+1`, `ChCToneSlide`, `ChCGlissCount`); 1 more ranges |

### intromain

`src/intro98/intromain.asm`

#### `IntroMain` (`$D88F`)

**the intro: set up, the frame loop until a key, then IntroEnd**

Entered from the REM loader with interrupts on, IM 1, the 48 K BASIC ROM paged and page 0 at `$C000`. Sets up the player (Pt3Init), the IM 2 table and vector, pages `$7FFD` = `$10`, fades the loader's title out (AttrWipe), clears the screen (ClearScreen), colours the bottom third and the bars' cells, then loops once a frame (IntroLoop) until LAST_K (`$5C08`) is not 0 (the ROM's handler, run from IntroInterrupt, sets it when a key is pressed). Then IntroEnd. Out: interrupts on, IM 0 (behaves as IM 1 here), the AY silent, the attributes black. Uses AF BC DE HL; the IM 2 table at `$8080-$8200` is left in memory (the game load overwrites it).

| | |
| --- | --- |
| Runs (r98's intro window) | 1 call, 69,802,934 t-states own (39.72 %) |
| Calls | `Pt3Init`, `Pt3StopEntry`, `LogoColour`, `AyBars`, `ClearScreen`, `AttrWipe`, `RobotFrame` |
| Reads | `$5C08` (system); `$5C78` (system); `$8100`-`$8200` (system); `$D8ED` (`IntroLoop+7`) |
| Writes | `$5920`-`$593F` (screen); `$5A00`-`$5AFF` (screen); `$5C08` (system); `$8080`-`$8082` (system); `$8100`-`$8200` (system) |
| Ports in | `$FFFD` |
| Ports out | `$7FFD`, `$FFFD` |

#### `LogoColour` (`$D95F`)

**the ZS logo's cells in paper colour A (0-7)**

A = the colour (IntroLoop passes FRAMES & 7, so it changes every frame and goes black every eighth). Writes the attribute A * 8 (paper A, ink 0) to every cell of the 8 x 8 block at column 12, row 0 (`$580C`) whose byte in LogoMask is not 0; the other cells are left as they are. The colour goes into the LD (HL),n below (self-modified). Entered 2008 times (frames 2180-4203). Uses AF BC DE HL.

| | |
| --- | --- |
| Runs (r98's intro window) | 2,008 calls, 14,180,743 t-states own (8.07 %) |
| Called from | `IntroMain` |
| Reads | `$81FF`-`$8200` (system); `$E3B9`-`$E3F8` (`LogoMask`) |
| Writes | `$5810`-`$5812` (screen); `$582F`-`$5833` (screen); `$5851`-`$5852` (screen); `$586D`-`$5873` (screen); `$588C`-`$5893` (screen); `$58AC`-`$58B2` (screen); 3 more ranges |

#### `ScrollStep` (`$D982`)

**the scroller: one pixel further, a new glyph column at the right**

From IntroInterrupt every frame (2155 times, frames 2049-4203). ScrollPtr's operand is the text pointer, ScrollColumn's the column counter (0-7, one up a frame). On counter 0 the byte at the pointer is taken and the pointer moves on: `$00` ends the text (the pointer = the word after it: ScrollTextLoop) and `$01` LO HI switches the font (ScrollFont's operand = HI LO), both giving a space; on 1-7 the byte at the pointer is used without moving. The byte's glyph is ScrollFont - 256 + code * 8 (codes below `$20`: ScrollFont itself, a space), and one pixel column of it, chosen by the counter (counter 2-7: columns 0-5, counter 0: column 6, counter 1: column 7 of the byte after: the pointer has moved on; no glyph of either font has a pixel in column 7), is ORed into the right-hand byte of row 11 (`$487F`) on its 8 lines. Then the 8 lines of row 11 (`$4860-$487F`) shift left one pixel. Uses AF BC DE HL.

| | |
| --- | --- |
| Runs (r98's intro window) | 2,155 calls, 24,612,429 t-states own (14.00 %) |
| Called from | `IntroInterrupt` |
| Reads | `$4860`-`$487F` (screen); `$4960`-`$497F` (screen); `$4A60`-`$4A7F` (screen); `$4B60`-`$4B7F` (screen); `$4C60`-`$4C7F` (screen); `$4D60`-`$4D7F` (screen); 10 more ranges |
| Writes | `$4860`-`$487F` (screen); `$4960`-`$497F` (screen); `$4A60`-`$4A7F` (screen); `$4B60`-`$4B7F` (screen); `$4C60`-`$4C7F` (screen); `$4D60`-`$4D7F` (screen); 4 more ranges |

#### `AyBars` (`$D9F4`)

**the three AY volume bars**

AyBar for register 8 (channel A's volume) at column 0, 9 (B) at column 1, 10 (C) at column 2, each from the bottom line of row 23 up. IntroLoop calls it five times a frame (10040 entries in 2008 frames). Uses AF BC DE HL.

| | |
| --- | --- |
| Runs (r98's intro window) | 10,040 calls, 1,124,480 t-states own (0.64 %) |
| Called from | `IntroMain` |
| Calls | `AyBar` |

#### `IntroInterrupt` (`$DA0D`)

**the IM 2 handler: a frame of the tune and of the scroller, then the ROM's**

Reached through the vector `$8080` (a JP here) on every interrupt from IntroMain's IM 2 on (2155 times, frames 2048-4202). Saves every register (AF' too: the player uses it), CALLs Pt3PlayEntry and ScrollStep, restores them and jumps to `$0038`, the 48 K ROM's IM 1 handler: FRAMES + 1 and the keyboard scan into LAST_K, then EI and RET.

| | |
| --- | --- |
| Runs (r98's intro window) | 2,155 calls, 463,325 t-states own (0.26 %) |
| Calls | `Pt3PlayEntry`, `ScrollStep` |

#### `AyBar` (`$DA2A`)

**one volume bar: AY register A, its column from HL up**

A = the AY register (8-10: the channel volumes), HL = the bar's bottom byte (`$57E0` + column). Reads the register; its low 4 bits v (the envelope bit dropped) are the bar's height in pixel lines: v lines of `$7E` from the bottom up, then 15 - v lines of 0 above them; past the top line of row 23 (`$50`xx) it goes on at the bottom line of row 22 (`$57C0` + column). Entered 30120 times. Uses AF BC E HL.

| | |
| --- | --- |
| Runs (r98's intro window) | 30,120 calls, 26,037,720 t-states own (14.81 %) |
| Called from | `AyBars` |
| Reads | `$81FF`-`$8200` (system) |
| Writes | `$50E0`-`$50E2` (screen); `$51C0`-`$51E2` (screen); `$52C0`-`$52E2` (screen); `$53C0`-`$53E2` (screen); `$54C0`-`$54E2` (screen); `$55C0`-`$55E2` (screen); 2 more ranges |
| Ports in | `$FFFD` |
| Ports out | `$FFFD` |

#### `ClearScreen` (`$DA65`)

**the screen cleared: white on black, the border black**

ATTR_P (`$5C8D`) = 7, BORDER 0 (ROM `$229B` with A = 0), CLS (ROM `$0D6B`), channel 2 (the upper screen) opened (ROM `$1601`). The same steps as the REM loader's start. Entered once (frame 2176). Uses all.

| | |
| --- | --- |
| Runs (r98's intro window) | 1 call, 92 t-states own (0.00 %) |
| Called from | `IntroMain` |
| Writes | `$5C8D` (system) |

#### `AttrWipe` (`$DA77`)

**the diagonal fade: 128 frames of AttrDiagonal**

E from `$F8` to `$77`: AttrDiagonal(E), then HALT. Each frame the band of eight diagonals moves one cell right: whatever the attributes held is overwritten, first white ink (the band's front, `$47`) then darker inks down to black (`$40`), so the screen's contents fade out from left to right; at the end every cell is `$40` (bright, black on black). Run twice: on IntroMain's start (frames 2048-2176, over the REM loader's title) and in IntroEnd (frames 4203-4331, over the intro). Uses AF BC DE HL.

| | |
| --- | --- |
| Runs (r98's intro window) | 2 calls, 10,161,500 t-states own (5.78 %) |
| Called from | `IntroMain` |
| Calls | `AttrDiagonal` |
| Reads | `$81FF`-`$8200` (system); `$DA7D` (`AttrWipeFrame+4`) |

#### `AttrDiagonal` (`$DA84`)

**the band of 8 attribute diagonals at column E of row 0**

For each row D = 0-23, eight cells leftwards from column E - D: the attributes `$47`, `$46` ... `$40` (bright, ink 7 down to 0, black paper), through AttrCell (cells off the screen skipped). Keeps DE and AF; uses BC HL.

| | |
| --- | --- |
| Runs (r98's intro window) | 256 calls, 2,508,288 t-states own (1.43 %) |
| Called from | `AttrWipe` |
| Calls | `AttrCell` |

#### `AttrCell` (`$DA9F`)

**attribute A at row D, column E (if on the screen)**

D = the row, E = the column, A = the attribute; nothing when E >= 32 or D >= 24. HL = `$5800` + D * 32 + E. Keeps AF DE.

| | |
| --- | --- |
| Runs (r98's intro window) | 49,152 calls, 3,416,064 t-states own (1.94 %) |
| Called from | `AttrDiagonal` |
| Writes | `$5800`-`$5AFF` (screen) |

### robot

`src/intro98/robot.asm`

#### `RobotFrame` (`$E3FE`)

**the robot's next animation frame from RobotStream**

No input. Finds its own address (the ROM's `$1FC6`: POP HL, RET Z not taken, JP (HL): HL = RobotSelf), takes the stream position from RobotPos (the first time `$FFFF`, and after the last frame a position past the stream's end: both restart at RobotStream), decodes one frame into the screen (RobotNext ... RobotFrameEnd) and stores the position after its `$C0` in RobotPos. Self-modifying (RobotPos). Uses all registers and the alternate set (BC' DE' HL', AF').

| | |
| --- | --- |
| Runs (r98's intro window) | 63 calls, 1,575 t-states own (0.00 %) |
| Called from | `IntroMain` |

#### `RobotSelf` (`$E403`)

**where RobotFrame goes on: the ROM's JP (HL) at `$1FC8` lands here with HL = RobotSelf**

The second half of RobotFrame, an entry of its own because it is reached from the ROM (the get-PC trick: RobotFrame CALLs `$1FC6`, whose POP HL takes the return address, RET Z is not taken with A = 1, and JP (HL) comes back here). Entered 63 times in the window (one per robot frame). All addresses of the robot (RobotStream, its end) are HL-relative from here, so the block could run at any address.

| | |
| --- | --- |
| Runs (r98's intro window) | run into, not called, 1,278,658 t-states own (0.73 %) |
| Reads | `$50B1` (screen); `$51B1` (screen); `$5691` (screen); `$5791` (screen); `$E4B3`-`$E6CB` (`RobotStream`) |
| Writes | `$502D`-`$50F2` (screen); `$512D`-`$54F2` (screen); `$550D`-`$55D2` (screen); `$55ED`-`$55F2` (screen); `$560D`-`$56D2` (screen); `$56ED`-`$56F2` (screen); 3 more ranges |

## The '99 stage 2: the intro (`src/stage2`)

Recordings: `work/stage2/front99/intro` (r99's intro window).

| Module | Entries | Code entries |
| --- | --- | --- |
| `loader` | `$61A8`-`$628A` | 4 of 4 |
| `effects` | `$628B`-`$6445` | 14 of 15 |
| `print` | `$6446`-`$6524` | 7 of 9 |
| `interrupt` | `$6525`-`$6546` | 1 of 1 |
| `texts` | `$6547`-`$7D86` | 0 of 4 |

### loader

`src/stage2/loader.asm`

#### `Stage2Start` (`$61A8`)

**Read the pictures block: 13 sectors to `$7D87`**

Entered by the depacker's jump (r99 frame 227). TR-DOS reads (C = 5) 13 sectors from DosNextSector, where the BASIC's read stopped: sectors 19-31 of NEZSEd99.B. Falls through to ReadMusic.

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 57 t-states own (0.00 %) |
| Reads | `$5CF4`-`$5CF5` (system) |

#### `ReadMusic` (`$61B5`)

**Read the music block: the next 13 sectors to `$C000`**

Sectors 32-44 of NEZSEd99.B. Falls through to IntroMain.

| | |
| --- | --- |
| Runs (r99's intro window) | run into, not called, 57 t-states own (0.00 %) |
| Reads | `$5CF4`-`$5CF5` (system) |

#### `IntroMain` (`$61C2`)

**The intro from the music's start to stage 3's read**

Sets IM 2 (table `$B000` of `$B1`, I = `$B0`, JP IM2Handler at `$B1B1`), initialises the tune (MusicInit, A = `$80`) and enables interrupts: from now on the tune plays each frame. Dissolves the screen (DissolveScreen), border black, the attributes to white ink on black in a spiral (SpiralAttrs, A = 7), patches the pictures block's two targets to PictureBuffer and PictureBufferAttrs, decodes the picture (DecodeScreen at `$7D87`) and rolls it in (RollInPicture). The border flashes yellow / black ten times (20 frames). The bottom row of the scroller window (`$5AD0-$5ADF`) is made black on black, the print font set to Font64, and the scroller runs (ScrollerLoop) until SPACE; then OutroAndLoad.

| | |
| --- | --- |
| Runs (r99's intro window) | run into, not called, 31,204,527 t-states own (22.30 %) |
| Calls | `CycleBottomRow`, `CycleLogoColours`, `PrintLine`, `RollInPicture`, `PushOutScreen`, `DissolveScreen`, `SpiralAttrs`, `ScrollWindowUp` |
| Reads | `$5CF4`-`$5CF5` (system); `$620E`-`$6213` (`BorderFlash+5`); `$6244`-`$624F` (`ScrollerPause+7`); `$B000`-`$B0FE` (`work space $B000+`) |
| Writes | `$5AD0`-`$5ADF` (screen); `$6523`-`$6524` (`PrintFont`); `$7D99`-`$7D9A` (`work space $7D99+`); `$7DD7`-`$7DD8` (`work space $7DD7+`); `$B000`-`$B100` (`work space $B000+`); `$B1B1`-`$B1B3` (`work space $B1B1+`) |
| Ports in | `$7FFE`, `$BFFE` |
| Ports out | `$00FE`, `$06FE`, `$07FE` |

#### `ScrollerLoop` (`$6225`)

**The scroller: a line printed in the window's bottom row, then eight one-pixel scrolls**

From ScrollText: PrintLine prints AT 32,22 and a line up to its CR, INC DE skips the LF, then 8 one-pixel scrolls of the window (ScrollWindowUp), each scroll two frames with the logo (CycleLogoColours) and the bottom line (CycleBottomRow) recoloured. The first line is printed before the loop without the skip, so the first pass prints its LF (the print row 23, below the window) and the empty second line. 156 passes print lines 2-157; then it starts again from the first. ENTER held stops the scroller (the colours keep cycling); SPACE ends it (OutroAndLoad). Ran r99 frames 746-1310 (23 lines, 184 scrolls).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### effects

`src/stage2/effects.asm`

#### `CycleBottomRow` (`$628B`)

**Recolour the bottom text row (row 23): each cell the next ink 1-7**

Attributes `$5AE0-$5AFF`: each cell takes the previous cell's colour + 1 (mod 8, 0 skipped), from the first cell's own colour + 1: a rainbow of inks over "You wanted new levels? Take its!" that moves each call. Called twice a scroll (r99 frames 747-1310, 368 calls). A, B, HL changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 368 calls, 649,934 t-states own (0.46 %) |
| Called from | `IntroMain` |
| Reads | `$5AE0` (screen) |
| Writes | `$5AE0`-`$5AFF` (screen) |

#### `CycleLogoColours` (`$629C`)

**Recolour the logo's box: 15 rows of 14 cells, each row the next ink 1-7**

Attributes from `$5831` (row 1, column 17): row by row each takes the next colour (mod 8, 0 skipped) after the box's first cell's: the stripes of the logo move up each call. Called once a scroll (184 calls). A, C, DE, HL changed; BC kept.

| | |
| --- | --- |
| Runs (r99's intro window) | 184 calls, 1,345,864 t-states own (0.96 %) |
| Called from | `IntroMain` |
| Reads | `$5831` (screen) |
| Writes | `$5831`-`$591E` (screen); `$5931`-`$593E` (screen); `$5951`-`$595E` (screen); `$5971`-`$597E` (screen); `$5991`-`$599E` (screen); `$59B1`-`$59BE` (screen); 2 more ranges |

#### `PrintLine` (`$62B9`)

**Print the line at DE at the scroller's bottom row, up to its CR**

Prints ScrollText's first three bytes (AT 32,22: column 32 of 64, row 22) through PrintChars, then the bytes at DE through PrintChar until a CR (`$0D`). Output: DE past the CR. 24 calls in the window (r99 frames 746-1287).

| | |
| --- | --- |
| Runs (r99's intro window) | 24 calls, 28,920 t-states own (0.02 %) |
| Called from | `IntroMain` |
| Calls | `PrintChars`, `PrintChar` |
| Reads | `$654C`-`$6769` (`ScrollText`) |

#### `PrintLineFont` (`$62CE`)

**Not reached: CHARS = `$7487` (a ROM-layout font at `$7587`), then PrintLine's character loop**

Code no recording reached and no instruction of the block jumps to: sets the ROM's CHARS (`$5C36`) to `$7487` (or, from PrintLineRom, to the ROM's font `$3C00`) and continues in PrintLine's character loop. A leftover of a version that printed through the ROM (the bytes at `$7587` are not in the ROM's font layout, see Font64). Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintLineRom` (`$62D6`)

**Not reached: CHARS = `$3C00` (the ROM's font), then as PrintLineFont**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RollInPicture` (`$62DB`)

**Show the picture at HL: line y of it fills screen lines 0-y, y from 191 down to 0, then its attributes**

Input: HL = the picture (screen layout: 6144 pixel bytes, 768 attributes). For y = 191 down to 0 the picture's line y is copied into every screen line from 0 to y: the picture rolls down from the top, its lower lines first stretched over the screen above them. Then the 768 attributes to `$5800`. The pixel lines through the ROM's PIXEL-ADD. Ran once, r99 frames 472-726. A, BC, DE, HL changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 14,853,197 t-states own (10.62 %) |
| Called from | `IntroMain` |
| Reads | `$631F`-`$6320` (`RollInSource`); `$8A87`-`$A586` (`work space $8A87+`) |
| Writes | `$4000`-`$5AFF` (screen); `$631F`-`$6320` (`RollInSource`) |

#### `PushOutScreen` (`$6321`)

**Push the screen out: each half shifted one pixel outwards, more lines each step**

The left half (bytes 0-15 of a line) is shifted left and the right half (16-31) right, one pixel a pass (ShiftLinesApart): lines 0..n-1 for n = 1 to 191 (the opening runs down the screen), then lines 64-191 128 times more. Ran once after SPACE, r99 frames 1312-1953. A, BC, DE, HL changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 26,572 t-states own (0.02 %) |
| Called from | `IntroMain` |
| Calls | `ShiftLinesApart` |

#### `ShiftLinesApart` (`$6344`)

**Shift B screen lines from the one at HL+1 apart by one pixel**

Input: HL = the 16th byte of the first line (its left half's last), B = the number of lines. Each line: RL through bytes 15 down to 0 (the left half one pixel left), RR through bytes 16 to 31 (the right half one pixel right); the next line through NextLineDown.

| | |
| --- | --- |
| Runs (r99's intro window) | 319 calls, 41,642,788 t-states own (29.76 %) |
| Called from | `PushOutScreen` |
| Calls | `NextLineDown` |
| Reads | `$4000`-`$57FF` (screen) |
| Writes | `$4000`-`$57FF` (screen) |

#### `NextLineDown` (`$6361`)

**HL = the screen address one pixel line down**

The usual INC H, then across a character row or a third.

| | |
| --- | --- |
| Runs (r99's intro window) | 34,720 calls, 1,060,458 t-states own (0.76 %) |
| Called from | `ShiftLinesApart` |

#### `DissolveScreen` (`$6370`)

**Clear the screen's pixels bit by bit: 250 passes over every 29th byte**

HL steps through `$4000-$57FF` by 29 (wrapping back by `$1800`); each byte is ANDed with C, a mask whose clear bit moves one place each pass (`$FE`, `$FD`, ...): 250 passes, so every bit of every byte is reached and the old screen's pixels fade to nothing in a scattered order. Ran once, r99 frames 261-303. A, BC, DE, HL changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 2,761,819 t-states own (1.97 %) |
| Called from | `IntroMain` |
| Reads | `$4000`-`$57FF` (screen) |
| Writes | `$4000`-`$57FF` (screen) |

#### `SpiralAttrs` (`$638B`)

**Fill the attributes with A in a spiral from the outside in, one cell a delay**

Input: A = the attribute. 12 rings from the corner (0,0): the top row to the right, the right column down, the bottom row to the left, the left column up, each next ring one cell further in; a Delay500 after each cell. Ran r99 frames 303-472 (A = 7) and 1953-2114 (A = `$38`). A', BC, DE, HL changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 2 calls, 95,418 t-states own (0.07 %) |
| Called from | `IntroMain` |
| Calls | `Delay500` |
| Writes | `$5800`-`$5AFF` (screen) |

#### `Delay500` (`$63D6`)

**A delay loop of 500 counts (BC, AF kept)**

| | |
| --- | --- |
| Runs (r99's intro window) | 1,632 calls, 21,315,104 t-states own (15.23 %) |
| Called from | `SpiralAttrs` |

#### `WindowAttrAddr` (`$63E3`)

**Not reached: HL = the attribute address of the window at IX, C = its width, B = its height**

IX as ScrollWindow (column, row, width, height). No instruction of the block calls it and no recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ScrollWindowUp` (`$63FE`)

**Scroll the window at IX up by one pixel line; its last line cleared**

IX = the window: +0 column, +1 row, +2 width (bytes), +3 height (character rows). For each of its height x 8 - 1 lines the next line's bytes are copied up (LDIR, addresses through the ROM's PIXEL-ADD), then the last line is cleared. 184 calls (r99 frames 746-1309), always ScrollWindow. A, BC, DE, HL changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 184 calls, 4,212,908 t-states own (3.01 %) |
| Called from | `IntroMain` |
| Reads | `$5050`-`$51DF` (screen); `$5230`-`$52DF` (screen); `$5330`-`$53DF` (screen); `$5430`-`$54DF` (screen); `$5530`-`$55DF` (screen); `$5630`-`$56DF` (screen); 2 more ranges |
| Writes | `$5030`-`$51DF` (screen); `$5230`-`$52DF` (screen); `$5330`-`$53DF` (screen); `$5430`-`$54DF` (screen); `$5530`-`$55DF` (screen); `$5630`-`$56DF` (screen); 2 more ranges |

### print

`src/stage2/print.asm`

#### `PrintChars` (`$6446`)

**Print BC bytes from DE**

Input: DE = the bytes, BC = their count. Each through PrintChar. Output: DE past them, BC = `$FFFF`.

| | |
| --- | --- |
| Runs (r99's intro window) | 24 calls, 4,992 t-states own (0.00 %) |
| Called from | `PrintLine` |
| Calls | `PrintChar` |
| Reads | `$654C`-`$654E` (`ScrollText`) |

#### `PrintChar` (`$6451`)

**Print the character or control code A at PrintCol, PrintRow**

Codes: `$20-$FF` a glyph from PrintFont (the bits under PrintMask of the 8 glyph rows replace the screen's; then the next column, past 63 the next row's column 0); `$0A` the next row; `$0D` column 0; `$09` the next column that is a multiple of 8; `$08` one column back (meant to stop at 0, but DEC A sets no carry, so the RET C never returns and column 0 becomes 255; the text has no `$08`); `$16` col row: AT (two bytes follow: the column, then the row); `$17` lo hi: the font address (the two bytes into PrintFont); others ignored. A row of 24 or more is counted but not drawn. 568 calls (r99 frames 746-1287). A, F, the alternate set (glyphs) changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 568 calls, 537,951 t-states own (0.38 %) |
| Called from | `PrintLine`, `PrintChars` |
| Calls | `PrintNewRow` |
| Reads | `$50D0`-`$50DF` (screen); `$51D0`-`$51DF` (screen); `$52D0`-`$52DF` (screen); `$53D0`-`$53DF` (screen); `$54D0`-`$54DF` (screen); `$55D0`-`$55DF` (screen); 11 more ranges |
| Writes | `$50D0`-`$50DF` (screen); `$51D0`-`$51DF` (screen); `$52D0`-`$52DF` (screen); `$53D0`-`$53DF` (screen); `$54D0`-`$54DF` (screen); `$55D0`-`$55DF` (screen); 3 more ranges |

#### `PrintFontArgument` (`$64CF`)

**`$17`'s bytes: low into PrintFont, high into PrintFont+1 (not reached: the text has no `$17`)**

HL = PrintFont + 2, back into PrintArgument's store: the first byte (2 left) goes to PrintFont, the second to PrintFont+1. Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintArgumentDone` (`$64D4`)

**One argument byte less to come**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintControl` (`$64DC`)

**A control code below `$20`: LF here, the others in PrintControlRest**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintNewRow` (`$64E0`)

**LF: the next print row (also after column 63)**

| | |
| --- | --- |
| Runs (r99's intro window) | 14 calls, 560 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Reads | `$651E` (`PrintRow`) |
| Writes | `$651E` (`PrintRow`) |

#### `PrintControlRest` (`$64E8`)

**CR, AT, TAB, back, `$17`; any other code is ignored**

Part of PrintChar's control codes (PrintControl falls here past LF); each sets PrintCol, the argument count or returns.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### interrupt

`src/stage2/interrupt.asm`

#### `IM2Handler` (`$6525`)

**The IM 2 handler: the tune's frame (MusicPlay), then the ROM's IM 1 handler**

Saves every register (main and alternate, IX, IY), calls MusicPlay, restores them and jumps to the ROM's `$0038` (which scans the keyboard, counts FRAMES and returns with EI). Entered through `$B1B1` 1845 times (r99 frames 261-2114).

| | |
| --- | --- |
| Runs (r99's intro window) | 1,845 calls, 496,305 t-states own (0.35 %) |

## The '99 pictures block (`src/pictures99`)

Recordings: `work/stage2/front99/intro` (r99's intro window).

| Module | Entries | Code entries |
| --- | --- | --- |
| `decoder` | `$7D87`-`$7DF9` | 1 of 1 |
| `picture` | `$7DFA`-`$8A86` | 0 of 2 |

### decoder

`src/pictures99/decoder.asm`

#### `DecodeScreen` (`$7D87`)

**Decode the RLE screen that follows the routine into the targets at DecodePixels+1 and DecodeAttrs+1**

No inputs: the stream is found from the routine's own address (CALL RomRet, then the return address read back from below SP, + `$6F` = PackedScreen). The 6144 pixel bytes are written column by column, each column top to bottom, at the target as a screen layout; the 768 attributes in order. DI on entry, EI on return. Outputs: the screen (or the patched buffer); A, BC, DE, HL and the alternate BC, DE changed. Ran once (r99 frames 464-472, called from stage 2's IntroMain at `$61FE`).

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 561,492 t-states own (0.40 %) |
| Reads | `$7DFA`-`$8A35` (`PackedScreen`) |
| Writes | `$8A87`-`$A586` (`work space $8A87+`) |

## The '99 music block (`src/music99`)

Recordings: `work/stage2/front99/intro` (r99's intro window).

| Module | Entries | Code entries |
| --- | --- | --- |
| `player` | `$C000`-`$CCFF` | 26 of 42 |

### player

`src/music99/player.asm`

#### `Init` (`$C00B`)

**Entry: set the module at Module up for playing from its first position**

JR to InitEntry (HL = Module). Called once by stage 2 at `$61E3` (r99 frame 261) with A = `$80`, which the player ignores. Interrupts are disabled while it runs and enabled again on return.

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 32 t-states own (0.00 %) |
| Calls | `InitModule` (tail) |

#### `Play` (`$C00E`)

**Entry: one frame of the tune (called once an interrupt)**

JR to PlayEntry. Called by stage 2's interrupt handler (`$6525`) every frame from r99 frame 262 to 2114.

| | |
| --- | --- |
| Runs (r99's intro window) | 1,845 calls, 40,590 t-states own (0.03 %) |
| Calls | `PlayFrame` (tail) |

#### `Mute` (`$C011`)

**Entry: silence the AY**

JR to MuteAY. Called once by stage 2 (`$6278`) after SPACE (r99 frame 2114).

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 62 t-states own (0.00 %) |
| Calls | `MuteLoop` (tail) |
| Ports out | `$FFFD` |

#### `MuteAY` (`$C04C`)

**Silence the AY: register 12 stepped through 0-255, the mixer (register 7) set to `$FF`**

Selects AY register 12 and writes A = 0, 1, ... 255 to it (MuteLoop, ending when A wraps to 0), then register 7 = `$FF`: every tone and noise channel off. A, BC changed. Ports `$FFFD` / `$BFFD`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `InitEntry` (`$C059`)

**Init's jump: HL = the module**

HL = Module, on to InitModule.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PlayEntry` (`$C05F`)

**Play's jump: on to PlayFrame**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `InitModule` (`$C062`)

**Set the player's variables up for the STC module at HL**

Input: HL = the module. Reads the tempo, patches ModuleOffset with the module address (the module's offsets become addresses), takes the positions list (its first byte + 1 = the count), the ornaments, the patterns and the samples (module + 27) addresses; points channel A's pattern stream at PatternEnd (`$FF`, so that the first Play fetches position 0), zeroes ChannelState..AYEnvShape, sets every channel's ornament to ornament 0 and its sample counter to `$FF` (silent), the delay counter to 1, and writes the AY registers once (WriteAY). DI on entry, EI on return. Outputs: every variable of the player; A, BC, DE, HL changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 1,416 t-states own (0.00 %) |
| Called from | `Init` (tail) |
| Calls | `FindNumbered`, `ReadOffset`, `ModuleOffset`, `WriteAY` |
| Reads | `$C0DB`-`$C106` (`ChannelState`, `PositionIndex`, `AYTone`, `AYNoise`); `$C4A8` (`Module`); `$C715` (`Module+621`) |
| Writes | `$C0C9`-`$C115` (`PositionsAddr`, `Tempo`, `PatternPtrA`, `PatternEnd` and 7 more) |

#### `FindNumbered` (`$C108`)

**Find the record whose first byte is A**

Inputs: A = the number, HL = the first record, BC = the record size. Steps HL by BC until (HL) = A. Output: HL = the record (no end check: the number must be there).

| | |
| --- | --- |
| Runs (r99's intro window) | 339 calls, 19,929 t-states own (0.01 %) |
| Called from | `InitModule`, `NextPosition`, `ReadRow`, `SetOrnament` |
| Reads | `$C4C3` (`Module+27`); `$C526` (`Module+126`); `$C589` (`Module+225`); `$C5EC` (`Module+324`); `$C64F` (`Module+423`); `$C6B2` (`Module+522`); 2 more ranges |

#### `ReadOffset` (`$C10E`)

**Read a module offset at HL and make it an address**

Input: HL = a word in the module. Output: DE = the word + the module address (through ModuleOffset), HL past the word. BC changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 18 calls, 540 t-states own (0.00 %) |
| Called from | `InitModule`, `NextPosition` |
| Calls | `ModuleOffset` |
| Reads | `$C4A9`-`$C4AE` (`Module+1`); `$C801`-`$C822` (`Module+857`) |

#### `ModuleOffset` (`$C113`)

**DE = HL + the module address (the operand patched by InitModule)**

ModuleOffset+1 holds the module address once Init has run (on the disk the compiler's `$EE43`). Input HL, output DE = HL + module; BC changed. InitModule calls it directly for the samples (HL = 27).

| | |
| --- | --- |
| Runs (r99's intro window) | 19 calls, 665 t-states own (0.00 %) |
| Called from | `InitModule`, `ReadOffset` |

#### `SampleLine` (`$C119`)

**Decode one line of a sample**

Inputs: IX = the sample's address (IX+3/4 of a channel), A = the line (0-31). Outputs: L = the volume (0-15), H = the noise period, DE = the tone shift (12 bits, bit 4 of D set when it is added), C = `$10` when the tone is masked off, B = `$02` when the noise is masked off; IX moved to the line. Called three times a frame from PlayFrameOut.

| | |
| --- | --- |
| Runs (r99's intro window) | 5,520 calls, 1,400,796 t-states own (1.00 %) |
| Called from | `PlayFrameOut` |
| Reads | `$C4C4`-`$C54A` (`Module+28`); `$C58A`-`$C5AD` (`Module+226`); `$C5ED`-`$C610` (`Module+325`); `$C650`-`$C70F` (`Module+424`) |

#### `NextPosition` (`$C151`)

**Move to the next position: the three pattern streams and the transposition**

Takes PositionIndex (back to 0 after the last), reads the position's pattern number and transposition (the transposition patched into NoteTransposition), finds the pattern in the pattern table and points PatternPtrA/B/C at its three streams. Called from PlayFrame when channel A's stream reaches `$FF` (5 times in the window, frames 262-1806). A, BC, DE, HL changed.

| | |
| --- | --- |
| Runs (r99's intro window) | 5 calls, 1,605 t-states own (0.00 %) |
| Called from | `PlayFrame` |
| Calls | `FindNumbered`, `ReadOffset` |
| Reads | `$C0C9`-`$C0D3` (`PositionsAddr`, `Tempo`); `$C0F9` (`PositionIndex`); `$C716`-`$C71F` (`Module+622`) |
| Writes | `$C0D4`-`$C0D9` (`PatternPtrA`, `PatternPtrB`, `PatternPtrC`); `$C0F9` (`PositionIndex`); `$C39D` (`NoteTransposition+1`) |

#### `RowCountdown` (`$C192`)

**Count a channel's rows down**

IX = the channel. DEC (IX+2); when it goes below zero the reload (IX-1) is put back and the sign flag is set (M): the caller reads the channel's next row.

| | |
| --- | --- |
| Runs (r99's intro window) | 924 calls, 51,828 t-states own (0.04 %) |
| Called from | `PlayFrame` |
| Reads | `$C0DC`-`$C0F3` (`ChannelState+1`, `ChannelA`, `ChannelStateB`, `ChannelB` and 2 more) |
| Writes | `$C0DF`-`$C0F3` (`ChannelA+2`, `ChannelStateB`, `ChannelB`, `ChannelStateC` and 1 more) |

#### `PlayFrame` (`$C19D`)

**One frame of the tune: every Tempo frames a row of each channel, then the sound**

DelayCounter counted down; at zero it is reloaded from Tempo and each channel whose row counter ran out reads its stream (ReadRow; channel A first fetches the next position when its stream is at `$FF`). Then PlayFrameOut works out and writes the registers. Called through Play from the interrupt handler.

| | |
| --- | --- |
| Runs (r99's intro window) | 1,845 calls, 154,239 t-states own (0.11 %) |
| Called from | `Play` (tail) |
| Calls | `NextPosition`, `RowCountdown`, `ReadRow`, `PlayFrameOut` (tail) |
| Reads | `$C0D1`-`$C0DA` (`Tempo`, `PatternPtrA`, `PatternEnd`); `$C836`-`$C8B6` (`Module+910`); `$C91A`-`$C977` (`Module+1138`); `$CB30`-`$CB94` (`Module+1672`) |
| Writes | `$C0D2`-`$C0D9` (`DelayCounter`, `PatternPtrA`) |

#### `ReadRow` (`$C1F1`)

**Read a channel's pattern stream up to its next note or rest**

Inputs: HL = the stream, IX = the channel. Bytes: `$00-$5F` a note (IX+1; the sample restarts: line 0, 32 lines); `$60-$6F` the sample (number - `$60`); `$70-$7F` the ornament (number - `$70`, the envelope off); `$80` a rest (the channel silent); `$81` an empty row; `$82` ornament 0, the envelope off; `$83-$8E` the envelope shape (- `$80`) with the next byte its period (low), ornament 0; `$A1` and above the row length (- `$A1`). Commands loop until a note, a rest or an empty row. Output: HL past the row.

| | |
| --- | --- |
| Runs (r99's intro window) | 651 calls, 107,388 t-states own (0.08 %) |
| Called from | `PlayFrame`, `SetOrnament` (tail) |
| Calls | `FindNumbered`, `SetOrnament` (tail) |
| Reads | `$C0CF`-`$C0D0` (`SamplesAddr`); `$C832`-`$C9BB` (`Module+906`); `$CB2C`-`$CB94` (`Module+1668`); `$CBB0`-`$CBEC` (`Module+1800`) |
| Writes | `$C0DC`-`$C0F8` (`ChannelState+1`, `ChannelA`, `ChannelStateB`, `ChannelB` and 2 more) |

#### `ChannelOff` (`$C245`)

**The channel's sample counter to `$FF`: the channel is silent**

| | |
| --- | --- |
| Runs (r99's intro window) | 3 calls, 87 t-states own (0.00 %) |
| Called from | `SampleStep` (tail) |
| Writes | `$C0F8` (`ChannelC+7`) |

#### `OrnamentZero` (`$C24A`)

**Row byte `$82`: ornament 0, the envelope off**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SetOrnament` (`$C24D`)

**Row byte `$70-$7F`: point the channel at ornament A - `$70`, the envelope off**

Inputs: A = the row byte, HL = the stream, IX = the channel. Back into ReadRow with HL past the byte.

| | |
| --- | --- |
| Runs (r99's intro window) | 165 calls, 24,750 t-states own (0.02 %) |
| Called from | `ReadRow` (tail) |
| Calls | `FindNumbered`, `ReadRow` (tail) |
| Reads | `$C0CB`-`$C0CC` (`OrnamentsAddr`) |
| Writes | `$C0DB`-`$C0F7` (`ChannelState`, `ChannelA`, `ChannelStateB`, `ChannelB` and 2 more) |

#### `SetEnvelope` (`$C269`)

**Row bytes `$83-$8E`, period: the envelope shape and period, ornament 0**

AYEnvShape = A - `$80`, AYEnvPeriod = the next byte, the channel's envelope state 1, ornament 0; back into ReadRow.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SampleStep` (`$C28E`)

**Advance a channel's sample by one line**

IX = the channel. When the channel is silent (`$FF`) returns at once (Z). Else the line counter IX+7 is decreased and the line IX+0 advanced (mod 32); C = the line to play. When the counter runs out the sample's loop (its byte `$60`: start + 1, `$61`: length) restarts it, or (no loop) the channel goes silent.

| | |
| --- | --- |
| Runs (r99's intro window) | 5,535 calls, 802,648 t-states own (0.57 %) |
| Called from | `PlayFrameOut` |
| Calls | `ChannelOff` (tail) |
| Reads | `$C0DD`-`$C0F8` (`ChannelA`, `ChannelStateB`, `ChannelB`, `ChannelStateC` and 1 more); `$C524` (`Module+124`); `$C6B0`-`$C6B1` (`Module+520`); `$C713`-`$C714` (`Module+619`) |
| Writes | `$C0DD`-`$C0F8` (`ChannelA`, `ChannelStateB`, `ChannelB`, `ChannelStateC` and 1 more) |

#### `NoiseFromSample` (`$C2C2`)

**Register 6 = H when the noise is on (C = 0)**

| | |
| --- | --- |
| Runs (r99's intro window) | 5,520 calls, 118,677 t-states own (0.08 %) |
| Called from | `PlayFrameOut` |
| Writes | `$C100` (`AYNoise`) |

#### `EnvelopeFlag` (`$C2CA`)

**Set bit 4 of the volume at HL while the channel uses the envelope**

IX = the channel, HL = its volume register in AYVolume. On the first frame after an envelope command (IX-2 = 1) the state becomes 2; on the next ones (2) AYEnvShape is cleared, so the shape register is written once. The volume's bit 4 (the envelope) is set while the state is non-zero.

| | |
| --- | --- |
| Runs (r99's intro window) | 5,535 calls, 342,750 t-states own (0.24 %) |
| Called from | `PlayFrameOut` |
| Reads | `$C0DB`-`$C0F8` (`ChannelState`, `ChannelA`, `ChannelStateB`, `ChannelB` and 2 more) |

#### `PlayFrameOut` (`$C2E7`)

**The frame's sound of the three channels into AYTone..AYVolume, then WriteAY**

For each channel: SampleStep; SampleLine of the line; the mixer bits; the tone period (TonePeriod); the volume; the envelope state. AYMixer is built from the three channels' tone and noise masks. Ends in WriteAY.

| | |
| --- | --- |
| Runs (r99's intro window) | 1,845 calls, 1,412,595 t-states own (1.01 %) |
| Called from | `PlayFrame` (tail) |
| Calls | `SampleLine`, `SampleStep`, `NoiseFromSample`, `EnvelopeFlag`, `TonePeriod`, `WriteAY` (tail) |
| Reads | `$C0E0`-`$C101` (`ChannelA+3`, `PositionIndex`, `AYTone`, `AYNoise`) |
| Writes | `$C0FA`-`$C104` (`AYTone`, `AYNoise`); `$C395` (`OrnamentLine+1`) |

#### `TonePeriod` (`$C38B`)

**The tone period of a channel's note, ornament and sample shift**

Inputs: IX = the channel, DE = the sample's shift (bit 4 of D: add), L = the volume (kept). The note (IX+1) + the ornament's offset at the line (OrnamentLine's operand, patched with the line) + the position's transposition (NoteTransposition's operand) indexes NoteTable; the shift is added or subtracted. Output: HL = the period, A = the volume.

| | |
| --- | --- |
| Runs (r99's intro window) | 5,520 calls, 1,355,605 t-states own (0.97 %) |
| Called from | `PlayFrameOut` |
| Reads | `$C0DE`-`$C0F7` (`ChannelA+1`, `ChannelStateB`, `ChannelB`, `ChannelStateC` and 1 more); `$C3C6`-`$C445` (`NoteTable+14`); `$C73B`-`$C746` (`Module+659`); `$C75C`-`$C767` (`Module+692`); `$C77D`-`$C788` (`Module+725`); `$C7BF`-`$C7FE` (`Module+791`) |

#### `WriteAY` (`$C478`)

**Write the AY registers from AYTone..AYEnvShape**

When AYEnvShape is non-zero registers 13 down to 0 are written, else 10 down to 0 (the envelope shape is written only when a row set it: writing register 13 restarts the envelope). OUTD from the top register's byte downwards. A, BC, HL changed. Ports `$FFFD` / `$BFFD`.

| | |
| --- | --- |
| Runs (r99's intro window) | 1,846 calls, 1,279,278 t-states own (0.91 %) |
| Called from | `InitModule`, `PlayFrameOut` (tail) |
| Reads | `$C0FA`-`$C107` (`AYTone`, `AYNoise`) |
| Ports out | `$BEFD`, `$FFFD` |

#### `MuteLoop` (`$C495`)

**MuteAY's loop: register 12 = A, A + 1, ... until A wraps to 0; then register 7 = `$FF`**

| | |
| --- | --- |
| Runs (r99's intro window) | 1 call, 7,228 t-states own (0.01 %) |
| Called from | `Mute` (tail) |
| Ports out | `$BFFD`, `$FFFD` |

## The '99 stage 3: System checking (`src/stage3`)

Recordings: `work/stage2/menu99/r99-s3a` (r99 2194-2300), `work/stage2/menu99/r99-s3b` (r99 2299-2662), `work/stage2/menu99/s99-s3` (the Scorpion), `work/stage2/menu99/r48-s3` (the 48 K path).

| Module | Entries | Code entries |
| --- | --- | --- |
| `s3main` | `$61A8`-`$6420` | 10 of 10 |
| `s3util` | `$6421`-`$647A` | 7 of 7 |
| `s3memtest` | `$647B`-`$6632` | 5 of 5 |
| `s3data` | `$6633`-`$67EB` | 0 of 15 |

### s3main

`src/stage3/s3main.asm`

#### `Stage3Entry` (`$61A8`)

**Fade the screen out, clear it, print the title, test the memory, print what was found**

Entered from stage 2 (r99 frame 2194). Eight steps (B = 8..1): border B-1, every attribute (B-1) * 8 (the paper colour), two HALTs; then the pixels and attributes `$4000-$5BFF` to 0, stream 2 open (RomChanOpen), SysDfSz = 0 (the whole screen for printing), the title (TitleText). Then MemoryTest and the line "Computer <name>": the name is NameDefault ("Spectrum") when the scheme (`$5CB0`) is 0, else the string for its highest set bit (FirstSetBit, SkipStrings over MachineNames).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `FadeStep` (`$61AA`)

**One fade step (B = 8..1): border B-1, all attributes paper B-1**

Part of Stage3Entry; an entry because the recording window r99-s3a starts inside the fade (frame 2194).

| | |
| --- | --- |
| Runs (r99 2194-2300) | run into, not called, 1,211,838 t-states own (15.95 %) |
| Runs (the 48 K path) | run into, not called, 1,282,502 t-states own (3.84 %) |
| Calls | `ReadTrdosVersion`, `ReadSectors`, `SkipStrings`, `FirstSetBit`, `PrintFF`, `MemoryTest` |
| Reads | `$4000`-`$5BFF` (screen); `$5C53`-`$5C54` (system); `$5CB0`-`$5CB1` (system); `$61BF`-`$61C0` (`FadeWait+1`) |
| Writes | `$4000`-`$5C00` (screen); `$5C6B` (system); `$67FC` (`work space $67FC+`) |
| Ports out | `$00FE`, `$01FE`, `$02FE`, `$03FE`, `$04FE`, `$05FE`, `$06FE` |

#### `FadeWait` (`$61BE`)

**Two frames a step, the next step; then the clear, the title, MemoryTest, the machine name**

| | |
| --- | --- |
| Runs (the Scorpion) | run into, not called, 1,206,965 t-states own (2.32 %) |
| Calls | `ReadTrdosVersion`, `ReadSectors`, `SkipStrings`, `FirstSetBit`, `PrintFF`, `MemoryTest` |
| Reads | `$4000`-`$5BFF` (screen); `$5C53`-`$5C54` (system); `$5CB0`-`$5CB1` (system); `$61BF`-`$61C0` (`FadeWait+1`) |
| Writes | `$4000`-`$5C00` (screen); `$5C6B` (system); `$67FC` (`work space $67FC+`) |
| Ports out | `$00FE`, `$01FE`, `$02FE`, `$03FE`, `$04FE`, `$05FE`, `$06FE` |

#### `RunGameBlock` (`$6250`)

**CALL the game block: it unpacks itself in place (game99's part); then the patches block**

An entry because the recording window r99-s3b starts here (frame 2299).

| | |
| --- | --- |
| Runs (r99 2194-2300) | run into, not called, 17 t-states own (0.00 %) |
| Runs (r99 2299-2662) | run into, not called, 78 t-states own (0.00 %) |
| Runs (the Scorpion) | run into, not called, 106 t-states own (0.00 %) |
| Runs (the 48 K path) | run into, not called, 78 t-states own (0.00 %) |
| Calls | `ReadSectors`, `PrintFF`, `BattleText` |

#### `InstallPatches` (`$6261`)

**Unpack the patches block, copy the disk reader and LOAD MAP, set the one-page table, branch by the count**

| | |
| --- | --- |
| Runs (r99 2299-2662) | run into, not called, 8,636 t-states own (0.03 %) |
| Runs (the Scorpion) | run into, not called, 10,804 t-states own (0.02 %) |
| Runs (the 48 K path) | run into, not called, 8,636 t-states own (0.03 %) |
| Calls | `InstallOnePage`, `InstallPaged`, `AdvanceSectors`, `ReadSectors`, `PrintFF` |
| Reads | `$5CB1` (system); `$5CF4`-`$5CF5` (system); `$D800`-`$D973` (`work space $D800+`) |
| Writes | `$A598`-`$A5D5` (`work space $A598+`); `$C116`-`$C14A` (`work space $C116+`); `$C1FD`-`$C332` (`work space $C1FD+`) |

#### `Stage3Paged` (`$62E7`)

**Page 0 back, the paged jump table's text addresses and lengths, into the game**

The end of both 128 K routes (disk, and the tape path's JP). Page 0 at `$C000` (PagedSelect), then the four LD DE / LD BC operands of the paged MainMenu table (`$C124-$C150`, patches `$DA68`): about `$C000` + `$0EB3` bytes, description `$CF00` + `$155D`, greets `$E500` + `$0139`, advices `$E700` + `$15C4`, all in page 3; then JP Start. Run in r99 (frame about 2660) and s99. On a machine with one 16 K page at `$C000` (the Pentagon locked in 48 K mode, r99-48; the lead's 48K-BETA128 run) PagedSelect changes nothing: the menu block was read to `$E800` and unpacked to `$D800`, the 64 "RAM-Disk" sectors to `$C000-$FFFF` over the game's `$C000-$D7D2` (MainMenu, the patched jump table) and over the menu; Start CALLs MainMenu at `$C100` (r99-48 frame 5647), which now holds the about text's bytes `$100` on (CP866 Russian text): they run as code (CALL PE,`$A0AD`, then `$EF` = RST `$28` into the ROM calculator, frames 5647-5664), the calculator's literal stream ends in USR-NO (`$34B3`, frame 5664), which jumps to `$0001`: the ROM's NEW from `$11CB`, and the copyright message (r99-48 frame 5760). The "0 OK" later in r99-48 (frame 7200) is after a key in the BASIC editor, not this run's end.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `InstallOnePage` (`$631E`)

**Copy the one-page TextLoader (`$A56A`) and MainMenu jump table (`$C100`) from the patches block**

PatchOneLoader (46 bytes) to TextLoader and PatchOneMenu (91 bytes) to MainMenu. Called on both paths (disk `$627A`, tape `$63A5`): the 128 K route then overwrites both (InstallPaged).

| | |
| --- | --- |
| Runs (r99 2299-2662) | 1 call, 2,937 t-states own (0.01 %) |
| Runs (the Scorpion) | 1 call, 3,652 t-states own (0.01 %) |
| Runs (the 48 K path) | 1 call, 2,937 t-states own (0.01 %) |
| Called from | `InstallPatches` |
| Reads | `$DAE7`-`$DB6F` (`work space $DAE7+`) |
| Writes | `$A56A`-`$A597` (`work space $A56A+`); `$C100`-`$C15A` (`work space $C100+`) |

#### `InstallPaged` (`$6335`)

**Copy the 128 K TextLoader (`$A56A`) and MainMenu jump table (`$C100`) from the patches block**

PatchPagedLoader (41 bytes, ends with PagedSelect at `$A58A`) and PatchPagedMenu (127 bytes). Called when the count is not 1 (r99 frame about 2300, r99-48, s99).

| | |
| --- | --- |
| Runs (r99 2299-2662) | 1 call, 3,588 t-states own (0.01 %) |
| Runs (the Scorpion) | 1 call, 4,444 t-states own (0.01 %) |
| Runs (the 48 K path) | 1 call, 3,588 t-states own (0.01 %) |
| Called from | `InstallPatches` |
| Reads | `$DA3F`-`$DAE6` (`work space $DA3F+`) |
| Writes | `$A56A`-`$A592` (`work space $A56A+`); `$C100`-`$C17E` (`work space $C100+`) |

#### `AdvanceSectors` (`$634C`)

**HL = the TR-DOS track/sector HL advanced by A sectors (16 a track)**

HL = track (H) / sector (L) as in TrdosNextSector, A = sectors (below 16 + 240). Out: HL the position A sectors on (L kept below 16, the overflow added to H). BC is changed.

| | |
| --- | --- |
| Runs (r99 2299-2662) | 4 calls, 338 t-states own (0.00 %) |
| Runs (the Scorpion) | 4 calls, 472 t-states own (0.00 %) |
| Runs (the 48 K path) | 4 calls, 338 t-states own (0.00 %) |
| Called from | `InstallPatches` |

#### `TapePath` (`$6362`)

**The tape version of the loads (PROG below `$5D3B`): game, patches, menu, texts from tape blocks**

Known only from the code: no recording ran it (every recording booted the disk, PROG = `$5D3B`). "TAPE RECORDER", then the blocks through LoadBlock (flag in A, IX the address, DE the length): game `$FF` (`$440E` bytes to `$6780`), patches `$FE` (`$033B` to `$DC00`), the tape BlockReader / LoadMap pieces, InstallOnePage, then the one-page lengths into the table; on more than one page the menu (flag 0, `$095F` bytes to `$E800` in page 1) and the four texts into page 3 (flags `$FD-$FA`), then Stage3Paged. Bugs: (1) the description, greets and advices loads set BC, not DE: LoadBlock gets DE as it is after the previous load (LD-BYTES counts it down to 0 on success); (2) the one-page lengths go to AboutPos (the about loader's LD DE) for the about text but to the LD BC operands for the other three, while the tape BlockReader (`$D974`) takes the length from BC.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### s3util

`src/stage3/s3util.asm`

#### `ReadTrdosVersion` (`$6421`)

**Copy the TR-DOS ROM's version text (`$0365`, 16 bytes) to TrdosVersion**

Through TrdosRet into TrdosLdir. Out: DE = TrdosVersion + 16, where Stage3Entry puts the `$FF`. Run in r99, r99-48 and s99 ("Using TR-DOS Ver 5.03", r99 frame 2300).

| | |
| --- | --- |
| Runs (r99 2194-2300) | 1 call, 69 t-states own (0.00 %) |
| Runs (the Scorpion) | 1 call, 96 t-states own (0.00 %) |
| Runs (the 48 K path) | 1 call, 69 t-states own (0.00 %) |
| Called from | `FadeStep`, `FadeWait` |

#### `ReadSectors` (`$6433`)

**Read B sectors from TrdosNextSector to HL, then print "O.k."**

TR-DOS command 5 (TrdosCommand) from the disk position after the last file read; the position moves on. Then LoadOk.

| | |
| --- | --- |
| Runs (r99 2194-2300) | 1 call, 44 t-states own (0.00 %) |
| Runs (r99 2299-2662) | 3 calls, 228 t-states own (0.00 %) |
| Runs (the Scorpion) | 4 calls, 240 t-states own (0.00 %) |
| Runs (the 48 K path) | 4 calls, 176 t-states own (0.00 %) |
| Called from | `FadeStep`, `FadeWait`, `RunGameBlock`, `InstallPatches` |
| Calls | `PrintFF` (tail) |
| Reads | `$5CF4`-`$5CF5` (system) |

#### `LoadOk` (`$643C`)

**Interrupts off again (TR-DOS turns them on) and print "O.k." (OkText)**

| | |
| --- | --- |
| Runs (r99 2194-2300) | run into, not called, 24 t-states own (0.00 %) |
| Runs (the Scorpion) | run into, not called, 148 t-states own (0.00 %) |
| Runs (the 48 K path) | run into, not called, 96 t-states own (0.00 %) |
| Calls | `PrintFF` (tail) |

#### `LoadBlock` (`$6443`)

**Load a tape block: A = the flag, IX = the address, DE = the length; retry, or halt on an error**

LD-BYTES' own set-up (carry = load, the flag into A'), border 1, then RomLdBytesIn; NZ: again; NC: "Tape Error. System Halted." and DI, HALT. Known only from the code (the tape path).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SkipStrings` (`$645C`)

**DE past B strings that end in `$FF`**

| | |
| --- | --- |
| Runs (r99 2194-2300) | 1 call, 1,701 t-states own (0.02 %) |
| Runs (the Scorpion) | 1 call, 70 t-states own (0.00 %) |
| Called from | `FadeStep`, `FadeWait` |
| Reads | `$67B0`-`$67E2` (`MachineNames`, `NameScorpion`) |

#### `FirstSetBit` (`$6465`)

**B = the position of A's highest set bit, from the top (bit 7 gives 1)**

A must not be 0. A is shifted.

| | |
| --- | --- |
| Runs (r99 2194-2300) | 1 call, 172 t-states own (0.00 %) |
| Runs (the Scorpion) | 1 call, 56 t-states own (0.00 %) |
| Called from | `FadeStep`, `FadeWait` |

#### `PrintFF` (`$646C`)

**Print the string at DE up to its `$FF` (not printed) through the ROM's PR-STRING**

BC = the length, DE the start, into RomPrString (which RETs to the caller).

| | |
| --- | --- |
| Runs (r99 2194-2300) | 7 calls, 6,522 t-states own (0.09 %) |
| Runs (r99 2299-2662) | 7 calls, 3,102 t-states own (0.01 %) |
| Runs (the Scorpion) | 13 calls, 14,613 t-states own (0.03 %) |
| Runs (the 48 K path) | 13 calls, 9,208 t-states own (0.03 %) |
| Called from | `FadeStep`, `FadeWait`, `RunGameBlock`, `InstallPatches`, `ReadSectors` (tail), `LoadOk` (tail) |
| Reads | `$66B3`-`$676E` (`TitleText`, `MemoryText`, `KbText`, `TapeRecorderText` and 5 more); `$67B1`-`$67B9` (`NameScorpion`); `$67E3`-`$67FC` (`NameDefault`, `work space $67EC+`) |

### s3memtest

`src/stage3/s3memtest.asm`

#### `MemoryTest` (`$647B`)

**Find the paging scheme (`$5CB0`) and the page count (`$5CB1`); ends with page 0 at `$C000`, interrupts on**

Out: `$5CB0` (IY+`$76`) the scheme bits (7 Scorpion ROM, 3 ATM Turbo 2+, 2 Profi, 1 KAY / Scorpion `$1FFD`, 4 ATM Turbo 1, 0 `$7FFD`, 5 more than 128 K on `$7FFD` alone), `$5CB1` (IY+`$77`) the count. The bytes at `$C000` of every page are put back (CountPages). Called once by Stage3Entry (r99 frame about 2200).

| | |
| --- | --- |
| Runs (r99 2194-2300) | 1 call, 836 t-states own (0.01 %) |
| Runs (the Scorpion) | 1 call, 1,070 t-states own (0.00 %) |
| Runs (the 48 K path) | 1 call, 818 t-states own (0.00 %) |
| Called from | `FadeStep`, `FadeWait` |
| Calls | `CountPages`, `SelectPage`, `TrdosPortOut` |
| Reads | `$0080` (system); `$5CB0`-`$5CB1` (system); `$C457`-`$C458` (`work space $C457+`); `$FFFF` (`work space $FFFF+`) |
| Writes | `$0080` (system); `$5CB0`-`$5CB1` (system); `$FFFF` (`work space $FFFF+`) |
| Ports out | `$1FFD`, `$7FFD`, `$DFFD`, `$FDFD` |

#### `CountPages` (`$654B`)

**Count the distinct pages: mark `$C000` of pages 63..0, drop the aliases from PageList, restore the bytes**

Pages 63 down to 0 (SelectPage): the byte at `$C000` is saved (PageSave, from `$66B2` down) and replaced by the page number. Then each page of PageList is selected: if `$C000` does not hold its number the page is an alias of a later one (or absent) and is removed from the list (the rest moved down, the count less 1). The count starts at 61 (`$3D`, the 62 entries minus 1). Then the 64 saved bytes go back. Out: `$5CB1` = the count, PageList = the distinct pages (r99 frame about 2200 writes `$663A-$6671`: the list compacted to 0 1 3 4 6 7).

| | |
| --- | --- |
| Runs (r99 2194-2300) | 1 call, 88,301 t-states own (1.16 %) |
| Runs (the Scorpion) | 1 call, 94,410 t-states own (0.18 %) |
| Runs (the 48 K path) | 1 call, 101,171 t-states own (0.30 %) |
| Called from | `MemoryTest` |
| Calls | `SelectPage` |
| Reads | `$5CB1` (system); `$6634`-`$66B2` (`PageList`, `PageSave`); `$C000` (`work space $C000+`) |
| Writes | `$5CB1` (system); `$6635`-`$66B2` (`PageList+1`, `PageSave`); `$C000` (`work space $C000+`) |

#### `ListPage` (`$65A3`)

**Select the page PageList holds at index A (falls into SelectPage)**

Known only from the code: nothing in stage 3, the game, the patches or the menu block CALLs `$65A3` (a byte search of work/media/99 for the address finds none).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SelectPage` (`$65AF`)

**Page A (0-63) in at `$C000` by the scheme found; with no scheme bit nothing happens**

A = the page. Interrupts off. One extended register by priority (bit 1 `$1FFD`, bit 2 `$DFFD`, bit 3 the ATM Turbo 2+ register, bit 4 `$FDFD`), then `$7FFD` = page bits 0-2, bits 3-4 into `$7FFD` bits 6-7, bit 4 set (ROM 1); bits 0 and 7 alone use only `$7FFD`. AF, BC, HL kept.

| | |
| --- | --- |
| Runs (r99 2194-2300) | 191 calls, 55,772 t-states own (0.73 %) |
| Runs (the Scorpion) | 191 calls, 79,524 t-states own (0.15 %) |
| Runs (the 48 K path) | 191 calls, 47,941 t-states own (0.14 %) |
| Called from | `MemoryTest`, `CountPages` |
| Reads | `$5CB0` (system) |
| Ports out | `$1FFD`, `$7FFD` |

#### `TrdosPortOut` (`$662A`)

**OUT (C),A with the TR-DOS ROM paged (TrdosRet into TrdosOut): the ATM decodes its xFF7 ports only then**

IX is changed.

| | |
| --- | --- |
| Runs (r99 2194-2300) | 2 calls, 78 t-states own (0.00 %) |
| Runs (the Scorpion) | 2 calls, 108 t-states own (0.00 %) |
| Runs (the 48 K path) | 2 calls, 78 t-states own (0.00 %) |
| Called from | `MemoryTest` |

## The '99 start-up menu (`src/menu99`)

Recordings: `work/stage2/menu99/r99-menu` (r99 2661-6462), `work/stage2/menu99/m99-menu1` (every item), `work/stage2/menu99/m99-menu4` (REDEFINE).

| Module | Entries | Code entries |
| --- | --- | --- |
| `menumain` | `$D800`-`$DBE1` | 12 of 19 |
| `menuviewer` | `$DBE2`-`$DD61` | 4 of 12 |
| `menupointer` | `$DD62`-`$E6F3` | 6 of 11 |

### menumain

`src/menu99/menumain.asm`

#### `MenuEntry` (`$D800`)

**IM 0 with I = `$3F`, the stack at `$677E`, then the menu screen**

Entered from the stub at `$6700` (page 0, m99 frame 2660). The return address (into Start, `$A603`) is moved onto the new stack at `$677E` (under stage 3's strings, which the stub overwrote). MenuHook = MenuRedraw: a dead store (no window reads `$C1E1`).

| | |
| --- | --- |
| Runs (r99 2661-6462) | 1 call, 178 t-states own (0.00 %) |
| Runs (every item) | 1 call, 178 t-states own (0.00 %) |
| Runs (REDEFINE) | run into, not called, 89 t-states own (0.00 %) |
| Calls | `MenuScreen` |
| Writes | `$C1E1`-`$C1E2` (system) |

#### `MenuScreen` (`$D813`)

**Clear the screen, attributes 7, print the menu (MenuText)**

Also the return after REDEFINE and after a text was shown (TextShow).

| | |
| --- | --- |
| Runs (r99 2661-6462) | 6 calls, 97,069 t-states own (0.04 %) |
| Runs (every item) | 3 calls, 48,541 t-states own (0.02 %) |
| Runs (REDEFINE) | 2 calls, 32,352 t-states own (0.05 %) |
| Called from | `MenuEntry`, `MenuRedraw` (tail), `DescView` (tail), `TextShow` (tail) |
| Reads | `$5800`-`$5AFE` (screen) |
| Writes | `$5800`-`$5AFF` (screen) |

#### `MenuBottom` (`$D912`)

**Save the attributes of rows 10-15, print START .. ABOUT ZS NE (MenuBottomText)**

SavedAttrs: the colours of the items without the marks; MenuRedraw restores them before it marks again.

| | |
| --- | --- |
| Runs (r99 2661-6462) | 6 calls, 24,444 t-states own (0.01 %) |
| Runs (every item) | 3 calls, 12,222 t-states own (0.00 %) |
| Runs (REDEFINE) | 2 calls, 8,148 t-states own (0.01 %) |
| Reads | `$5940`-`$59FF` (screen) |
| Writes | `$DE31`-`$DEF0` (`SavedAttrs`) |

#### `MenuRedraw` (`$D967`)

**Restore rows 10-15, mark the control, the level and the parts on; then the pointer loop**

After a HALT, SavedAttrs back to `$5940`; PaintBar at column 23 for Controls, column 0 for the level (the operand of LD A at LevelLd), column 11 for each bit 7..2 of EnemyUpgrade (rows 10-15). PaintBar paints 10 cells, so the CONTROL bar from column 23 runs into columns 0-0 of the next row (2 cells, black on the empty left of the row).

| | |
| --- | --- |
| Runs (r99 2661-6462) | 6 calls, 118,034,999 t-states own (43.32 %) |
| Runs (every item) | 3 calls, 132,642,484 t-states own (48.79 %) |
| Runs (REDEFINE) | 2 calls, 23,027,118 t-states own (35.34 %) |
| Calls | `MenuScreen` (tail), `ShowAbout` (tail), `ShowAdvices` (tail), `ShowGreets` (tail), `PaintBar`, `DrawPointer`, `SavePointerBg`, `RestorePointerBg`, `ReadMenuKeys` |
| Reads | `$5942`-`$59B9` (screen); `$59CC` (screen); `$59EC` (screen); `$5A21`-`$5A33` (screen); `$5AC1`-`$5AD2` (screen); `$A5E7` (system); 7 more ranges |
| Writes | `$5940`-`$59FF` (screen); `$A5E5`-`$A5E7` (system); `$AE41`-`$AE49` (system); `$B87E`-`$B880` (system); `$D2C8`-`$D2CD` (system); `$D3E4` (system); 2 more ranges |

#### `BottomColumn` (`$DB0A`)

**Row 17 past START: LOAD MAP (columns 8-17) or DESCRIPTION; row 21: ADVICES, GREETS, ABOUT**

LOAD MAP: JP LoadMap (the patches block's catalogue, m99 frames 5600-5960).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DescView` (`$DB4D`)

**to TextShow**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 1 call, 12 t-states own (0.00 %) |
| Runs (every item) | 1 call, 65 t-states own (0.00 %) |
| Calls | `MenuScreen` (tail), `TextShow` (tail), `TextViewer` |
| Writes | `$DC0E`-`$DC0F` (`ViewerTopLd+1`) |

#### `ShowAbout` (`$DB4F`)

**The about text into TextBuffer (LoadAbout), the screen, its title, TextShow**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 1 call, 61 t-states own (0.00 %) |
| Called from | `MenuRedraw` (tail) |

#### `TextShow` (`$DB7F`)

**The viewer from the start of TextBuffer, then the menu again**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 4 calls, 212 t-states own (0.00 %) |
| Called from | `DescView` (tail), `AdvicesView` (tail), `GreetsView` (tail) |
| Calls | `MenuScreen` (tail), `TextViewer` |
| Writes | `$DC0E`-`$DC0F` (`ViewerTopLd+1`) |

#### `ShowAdvices` (`$DB8B`)

**The advices text into TextBuffer (LoadAdvices), the screen, its title, TextShow**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 1 call, 61 t-states own (0.00 %) |
| Called from | `MenuRedraw` (tail) |

#### `AdvicesView` (`$DBB5`)

**to TextShow**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 1 call, 12 t-states own (0.00 %) |
| Calls | `TextShow` (tail) |

#### `ShowGreets` (`$DBB7`)

**The greets text into TextBuffer (LoadGreets), the screen, its title, TextShow**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 1 call, 61 t-states own (0.00 %) |
| Called from | `MenuRedraw` (tail) |

#### `GreetsView` (`$DBE0`)

**to TextShow**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 1 call, 12 t-states own (0.00 %) |
| Calls | `TextShow` (tail) |

### menuviewer

`src/menu99/menuviewer.asm`

#### `TextViewer` (`$DBE2`)

**Print the header (row 8, the font), fade rows 8-23 out, clear them, print a page, fade in, keys**

The top line is the operand of LD HL at ViewerTopLd (TextShow sets it to TextBuffer). Prints until row 24 or a 0 byte. Returns on SPACE.

| | |
| --- | --- |
| Runs (r99 2661-6462) | 4 calls, 44,493,022 t-states own (16.33 %) |
| Runs (every item) | 1 call, 18,705,816 t-states own (6.88 %) |
| Called from | `DescView`, `TextShow` |
| Calls | `PrintCount`, `ViewerPutChar`, `ReadMenuKeys` |
| Reads | `$4800`-`$57FE` (screen); `$5900`-`$5AFF` (screen); `$DBFD` (`FadeOutStep+16`); `$DC0E`-`$DC0F` (`ViewerTopLd+1`); `$DC36`-`$DC3D` (`FadeInStep+17`, `ViewerKeys`); `$DD5B` (`ViewerRow`); 1 more ranges |
| Writes | `$4800`-`$57FF` (screen); `$5900`-`$5B00` (screen); `$DC0E`-`$DC0F` (`ViewerTopLd+1`) |

#### `PrintCount` (`$DC83`)

**Print BC bytes from DE through ViewerPutChar**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 6 calls, 2,346 t-states own (0.00 %) |
| Runs (every item) | 5 calls, 1,955 t-states own (0.00 %) |
| Called from | `TextViewer` |
| Calls | `ViewerPutChar` |
| Reads | `$DC7D`-`$DC82` (`ViewerHeader`) |

#### `ViewerPutChar` (`$DC8E`)

**One byte to the 64-column screen: a control, a parameter or a character**

A = the byte. Keeps BC, DE, HL (the character's work in the alternate set). Columns 0-63, rows 0-23; a character in row 24 or more is not drawn; column 64 is the next row.

| | |
| --- | --- |
| Runs (r99 2661-6462) | 4,015 calls, 4,039,500 t-states own (1.48 %) |
| Runs (every item) | 3,761 calls, 3,828,623 t-states own (1.41 %) |
| Called from | `TextViewer`, `PrintCount` |
| Reads | `$4800`-`$57FF` (screen); `$DD5A`-`$DD61` (`ViewerCol`, `ViewerRow`, `ViewerParams`, `ViewerCode` and 3 more); `$DF11`-`$DFE0` (`ViewerFont+32`); `$E011`-`$E0E0` (`ViewerFont+288`); `$E111`-`$E1E0` (`ViewerFont+544`); `$E211`-`$E2E0` (`ViewerFont+800`); 4 more ranges |
| Writes | `$4800`-`$57FF` (screen); `$DD5A`-`$DD61` (`ViewerCol`, `ViewerRow`, `ViewerParams`, `ViewerCode` and 3 more) |

#### `ViewerNewLine` (`$DD1D`)

**The next row (the column is not changed)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### menupointer

`src/menu99/menupointer.asm`

#### `PaintBar` (`$DD62`)

**Attribute `$47` in 10 cells of row A + 9 from HL (`$5800` + the column)**

A = 1-6 (the item's row - 9). HL: `$5800` + the column. The 10 cells may run into the next row.

| | |
| --- | --- |
| Runs (r99 2661-6462) | 49 calls, 29,118 t-states own (0.01 %) |
| Runs (every item) | 185 calls, 111,198 t-states own (0.04 %) |
| Runs (REDEFINE) | 16 calls, 9,648 t-states own (0.01 %) |
| Called from | `MenuRedraw` |
| Writes | `$5940`-`$59B4` (screen); `$59CB`-`$59D4` (screen); `$59EB`-`$59F4` (screen) |

#### `DrawPointer` (`$DD73`)

**Draw the pointer sprite at the position (this LD BC's operand), shifted by x AND 7**

The mask and the pixels shifted right by x AND 7 (the mask filled with 1s), screen = screen AND mask OR pixels over two bytes, eight lines down.

| | |
| --- | --- |
| Runs (r99 2661-6462) | 774 calls, 2,874,342 t-states own (1.05 %) |
| Runs (every item) | 5,541 calls, 16,888,502 t-states own (6.21 %) |
| Runs (REDEFINE) | 321 calls, 1,029,064 t-states own (1.58 %) |
| Called from | `MenuRedraw` |
| Reads | `$4000`-`$51D3` (screen); `$5200`-`$52D3` (screen); `$5300`-`$53D3` (screen); `$5400`-`$54D3` (screen); `$5500`-`$55D3` (screen); `$5600`-`$56D3` (screen); 3 more ranges |
| Writes | `$4000`-`$51D3` (screen); `$5200`-`$52D3` (screen); `$5300`-`$53D3` (screen); `$5400`-`$54D3` (screen); `$5500`-`$55D3` (screen); `$5600`-`$56D3` (screen); 1 more ranges |

#### `SavePointerBg` (`$DDD7`)

**The background under the pointer into PointerBg (NOPs into the copy loop)**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 774 calls, 3,096 t-states own (0.00 %) |
| Runs (every item) | 5,541 calls, 22,190 t-states own (0.01 %) |
| Runs (REDEFINE) | 321 calls, 1,284 t-states own (0.00 %) |
| Called from | `MenuRedraw` |
| Calls | `SetPointerBgWay` |

#### `SetPointerBgWay` (`$DDD8`)

**A into BgSwap1 and BgSwap2, then PointerBgCopy**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 1,548 calls, 1,895,350 t-states own (0.70 %) |
| Runs (every item) | 11,082 calls, 13,567,072 t-states own (4.99 %) |
| Runs (REDEFINE) | 641 calls, 784,779 t-states own (1.20 %) |
| Called from | `SavePointerBg`, `RestorePointerBg` (tail) |
| Reads | `$4000`-`$51D3` (screen); `$5200`-`$52D3` (screen); `$5300`-`$53D3` (screen); `$5400`-`$54D3` (screen); `$5500`-`$55D3` (screen); `$5600`-`$56D3` (screen); 3 more ranges |
| Writes | `$4000`-`$52D3` (screen); `$5300`-`$53D3` (screen); `$5400`-`$54D3` (screen); `$5500`-`$55D3` (screen); `$5600`-`$56D3` (screen); `$5700`-`$57D3` (screen); 2 more ranges |

#### `RestorePointerBg` (`$DDE0`)

**PointerBg back to the screen (EX DE,HL into the copy loop)**

| | |
| --- | --- |
| Runs (r99 2661-6462) | 774 calls, 14,706 t-states own (0.01 %) |
| Runs (every item) | 5,541 calls, 105,331 t-states own (0.04 %) |
| Runs (REDEFINE) | 320 calls, 6,080 t-states own (0.01 %) |
| Called from | `MenuRedraw` |
| Calls | `SetPointerBgWay` (tail) |

#### `ReadMenuKeys` (`$DDE4`)

**E (and A) = the menu keys, 0 = pressed: bit 0 P, 1 O, 2 Q, 3 A, 4 SPACE**

The four half-rows `$DFFE` (P, O), `$FBFE` (Q), `$FDFE` (A), `$7FFE` (SPACE). Used by the menu and the viewer.

| | |
| --- | --- |
| Runs (r99 2661-6462) | 11,997 calls, 2,279,846 t-states own (0.84 %) |
| Runs (every item) | 12,760 calls, 2,424,894 t-states own (0.89 %) |
| Runs (REDEFINE) | 2,244 calls, 426,425 t-states own (0.65 %) |
| Called from | `MenuRedraw`, `TextViewer` |
| Ports in | `$7FFE`, `$DFFE`, `$FBFE`, `$FDFE` |

## The '99 patches block: `diskread` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `diskread` | `$A598`-`$A5D5` | 2 of 2 |

### diskread

`src/patches99/diskread.asm`

#### `DiskRead` (`$A598`)

**Read B sectors from logical track D, sector E (0-15) to HL, through the TR-DOS ROM**

In: HL the destination, D the logical track (the physical track D / 2, the side D bit 0: odd tracks are side 1), E the first sector, B the count; C is not used. A RESTORE first (the head to track 0), then a seek at the start and at each new logical track, and per sector a read of 256 bytes to HL, HL one page on each. After sector 15, sector 0 of the next logical track. No error check: what the ROM routines do on a bad sector is all.

Out: HL past the data, D, E past the last sector. A, BC, IX lost.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 1,428 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 2 calls, 1,435 t-states own (0.00 %) |
| Calls | `DiskRomCall` |

#### `DiskRomCall` (`$A5D1`)

**Run the TR-DOS ROM routine at IX: PUSH IX; JP `$3D2F` (the RET there takes IX)**

The TR-DOS ROM is paged in by the fetch at `$3D2F` and stays in while the routine runs; its RET returns here through the same window, with the 48 ROM back. The ROM routines keep BC, DE and HL as they leave them.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 14 calls, 350 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 14 calls, 350 t-states own (0.00 %) |
| Called from | `DiskRead` |

## The '99 patches block: `diskmap` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `diskmap` | `$C1FD`-`$C332` | 3 of 4 |

### diskmap

`src/patches99/diskmap.asm`

#### `DiskLoadMap` (`$C1FD`)

**LOAD MAP from disk: list the catalogue's N files, Q / A / SPACE to choose and load one**

No interrupts while it runs (DI; I = `$3F`, IM 0: the play interrupt is off, I points at the ROM); EI comes before the key loop for the HALTs, with IM 0 and I = `$3F` (an interrupt executes the bus's `$FF`: RST `$38`, the 48 ROM's handler).

The catalogue: 8 sectors of track 0 to LoadBuffer. Then the print position (0,0), attribute `$01`, setting `$11` (single size) for the names.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 109 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 1 call, 109 t-states own (0.00 %) |

#### `DiskListFiles` (`$C21E`)

**Copy each live N entry of the catalogue to FileList and print its name**

128 entries from `$F000` (IX), 16 bytes each (bytes 0-7 the name, 8 the type, 9-10 the start, 11-12 the length, 13 the sectors, 14 the first sector, 15 the first track). A first byte 0 ends the catalogue; below `$20` (1: deleted) the entry is skipped; a type other than N too.

A live N entry is copied to the list (DE), then patched in its place to print its own name: CALL PrintInline into the 3 bytes before it (ix-3, the end of the entry before, already copied), 0 after the name (+8, the type) and RET (+9). The CALL at `$C25D`, whose operand gets the patched entry's address - 3, prints the name and returns at the entry's +9 to `$C260`.

The print address: when it has run into `$41`xx (the first screen third full after 32 names, PrintAddr's high byte from `$40` to `$41`) it is set to `$48`xx, the second third. The jump from the second third to the third is not fixed.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 14,615,094 t-states own (5.22 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 1 call, 14,125,188 t-states own (2.02 %) |
| Reads | `$C27F` (`MapCursor+1`); `$C293`-`$C295` (`DiskMapKeys+1`); `$F000`-`$F1FF` (`work space $F000+`); `$F80E`-`$F80F` (`work space $F80E+`); `$F85E`-`$F85F` (`work space $F85E+`); `$FD05` (`work space $FD05+`) |
| Writes | `$5800`-`$582F` (screen); `$A684` (system); `$ADB4` (system); `$B3E6` (system); `$B817` (system); `$BB1F` (system); 6 more ranges |

#### `DiskApplyLevel` (`$C2EB`)

**The map file into the game: 499 bytes to the level area, the tail into the game's operands**

The file's bytes `$000-$1F2` go to `$BDA9-$BF9B` (SceneryWest on: the scenery lists, the base lists, spare). The tail: the four list addresses (+`$1F4`, +`$1F6`, +`$1F8`, +`$1FA`) into BuildMap's LD HL operands; the first factory record (+`$1FC`) into BuildMap's LD IX; the capture points (+`$1F3`) into the capture tick and CountBuildings; the enemy's warbases (+`$1FE`) into BuildMap and, + 1 (all the warbases), into the target table and the enemy's build; the player's general resource at the start (+`$1FF`) into NewGameSetup. Then JP Start.

The tail stays in the game until the next LOAD MAP: a later START plays the same map. The built-in level's values come back only with a new load of the game.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## The '99 patches block: `paging128` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `paging128` | `$A56A`-`$A597` | 2 of 2 |

### paging128

`src/patches99/paging128.asm`

#### `PagedText` (`$A56A`)

**128 K: copy BC bytes of a text from page 3 at DE to HL, through the screen**

In: DE the text in page 3, BC its length, HL the destination in page 0 or 2; A is not used (menu128's text entries load it with the text's number for the one-page reader). The screen is cleared first (ClearScreen: the attributes 0, black on black), the text copied with page 3 in to `$4000` (pixels only: the texts are shorter than `$1800` bytes, so nothing shows), then with page 0 back from `$4000` to HL. Page 0 stays in and interrupts off (SetPage's DI).

The menu's texts: menu128's entries at `$C124-$C14F` with the operands stage 3 writes: 1 NEdescri at page 3 `$CF00` (`$155D` bytes), 2 NEadvice `$E700` (`$15C4`), 3 NEgreets `$E500` (`$0139`), 4 NEabout `$C000` (`$0EB3`).

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 635,590 t-states own (0.23 %) |
| Calls | `SetPage` |
| Reads | `$4000`-`$55C3` (screen) |
| Writes | `$4000`-`$55C3` (screen); `$E6F4`-`$FCB7` (`work space $E6F4+`) |

#### `SetPage` (`$A58A`)

**Page A (0-7) in at `$C000`, the 48 ROM in (port `$7FFD` = A OR `$10`); interrupts off**

No copy goes to BANKM (`$5B5C`): nothing else here reads it. DI first, never undone: the callers run with interrupts off.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 14 calls, 602 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 2 calls, 86 t-states own (0.00 %) |
| Called from | `PagedText` |
| Ports out | `$7FFD` |

## The '99 patches block: `menu128` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `menu128` | `$C100`-`$C17E` | 12 of 14 |

### menu128

`src/patches99/menu128.asm`

#### `MenuTable128` (`$C100`)

**The menu's jump table: `$C100` the menu, `$C103-$C10C` the four texts, `$C10F` LOAD MAP**

The menu99 code calls these addresses; on one page menu48 holds the same table.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 20 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 1 call, 81 t-states own (0.00 %) |
| Calls | `ShowMenu128` (tail) |
| Writes | `$C179`-`$C17A` (`MenuStub+33`) |

#### `MenuText1Jump` (`$C103`)

**MenuText1Jump**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 10 t-states own (0.00 %) |
| Calls | `PageText1` (tail) |

#### `MenuText2Jump` (`$C106`)

**MenuText2Jump**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 10 t-states own (0.00 %) |
| Calls | `PageText2` (tail) |

#### `MenuText3Jump` (`$C109`)

**MenuText3Jump**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 10 t-states own (0.00 %) |
| Calls | `PageText3` (tail) |

#### `MenuText4Jump` (`$C10C`)

**MenuText4Jump**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 10 t-states own (0.00 %) |
| Calls | `PageText4` (tail) |

#### `MenuLoadMapJump` (`$C10F`)

**JP LoadMapLauncher: LOAD MAP (page 0 first)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowMenu128` (`$C112`)

**Copy the start-up menu from page 1 into page 0 and run it, with the caller's stack**

The stack pointer goes into MenuStub's LD SP operand; MenuStub (40 bytes) is copied to `$6700` and the copy's own RET (ROM LDIR; RET at `$33C3`, with `$6700` pushed) runs it. The menu's code RETs at the end to the return address on that stack.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 142 t-states own (0.00 %) |
| Called from | `MenuTable128` (tail) |
| Writes | `$C179`-`$C17A` (`MenuStub+33`) |

#### `PageText1` (`$C124`)

**Text 1 (NEdescri): DE, BC from stage 3 (`$CF00` in page 3, `$155D` bytes), to the caller's HL**

Stage 3 writes the operands (`$62F7`, `$62FD` on 128 K). A = the text's number, used by the one-page reader only.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 37 t-states own (0.00 %) |
| Called from | `MenuText1Jump` (tail) |

#### `PageText2` (`$C12F`)

**Text 2 (NEadvice): stage 3's operands `$E700` in page 3, `$15C4` bytes**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 37 t-states own (0.00 %) |
| Called from | `MenuText2Jump` (tail) |

#### `PageText3` (`$C13A`)

**Text 3 (NEgreets): stage 3's operands `$E500` in page 3, `$0139` bytes**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 37 t-states own (0.00 %) |
| Called from | `MenuText3Jump` (tail) |

#### `PageText4` (`$C145`)

**Text 4 (NEabout): stage 3's operands `$C000` in page 3, `$0EB3` bytes**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 37 t-states own (0.00 %) |
| Called from | `MenuText4Jump` (tail) |

#### `LoadMapLauncher` (`$C150`)

**LOAD MAP: page 0 in, then (by SetPage's RET) LoadMap at `$C1FD`**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## The '99 patches block: `taperead` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `taperead` | `$A598`-`$A5D5` | 2 of 4 |

### taperead

`src/patches99/taperead.asm`

#### `TapeRead` (`$A598`)

**Load a tape block of BC bytes with flag A to HL; on an error print "ERROR! LOAD AGAIN..." and wait for it again**

In: HL the destination, BC the length, A the flag byte. It sets up what LD-BYTES (`$0556`) would (IX the address, DE the length, the carry set for a load, A and the flags into AF') with the border black instead of the ROM's, and enters the ROM past its set-up at `$0562`, so the ROM's SA/LD-RET (the BREAK test and its error report) is not pushed: the ROM returns here with the carry set for a good block, clear for an error, the BREAK key (SPACE) included. Interrupts stay off.

On an error: "ERROR! LOAD AGAIN... " at (11,5), attribute `$42` (bright red on black), double height, then the next try from the set-up with IX, DE and AF' as the ROM left them; a break before the block's data (no block, a wrong flag, SPACE) tries again in full, a break inside the data goes on from where it stopped with the flag the ROM had swapped back.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 1,428 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 2 calls, 1,435 t-states own (0.00 %) |
| Calls | `TapeReadSpare` |

#### `TapeRetry` (`$A5C9`)

**Try the load again: AF' back, then the set-up**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## The '99 patches block: `tapemap` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `tapemap` | `$C1FD`-`$C332` | 3 of 5 |

### tapemap

`src/patches99/tapemap.asm`

#### `TapeLoadMap` (`$C1FD`)

**LOAD MAP from tape: "WAITING FOR LEVELFILE", then a 512-byte block with flag N**

A tape map file is a headerless block of 512 bytes with the flag byte `$4E`: the 499 level bytes and the 13-byte tail of a NELEV file.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 109 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 1 call, 109 t-states own (0.00 %) |

#### `TapeLoadLevel` (`$C227`)

**The map block: 512 bytes, flag N, to LoadBuffer**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TapeApplyLevel` (`$C248`)

**The map block into the game: as DiskApplyLevel, then JP `$D800`**

The bytes `$000-$1F2` to `$BDA9-$BF9B`, the tail `$1F3-$1FF` into the game's operands (DiskApplyLevel tells them), then the start-up menu's code at `$D800`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## The '99 patches block: `textload48` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `textload48` | `$A56A`-`$A597` | 2 of 3 |

### textload48

`src/patches99/textload48.asm`

#### `LoadText` (`$A56A`)

**"WAITING FILE n", then ReadBlock with the caller's HL, DE, BC and the flag n**

In: A the file's number (its low 4 bits: menu48's text entries 1-4; the menu file takes what A holds at Start), HL the destination, DE the disk position (track, sector), BC the length (B the sectors on disk, BC the bytes on tape). The screen is cleared (QuietScreen), "WAITING FILE n" printed at (11,8), attribute `$06`, double height, then ReadBlock: on disk DiskRead (DE, B; A not used), on tape TapeRead (BC, the flag byte n: the tape blocks carry their file number as the flag).

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 4 calls, 635,590 t-states own (0.23 %) |
| Calls | `WaitFileText` |
| Reads | `$4000`-`$55C3` (screen) |
| Writes | `$4000`-`$55C3` (screen); `$E6F4`-`$FCB7` (`work space $E6F4+`) |

#### `LoadTextRead` (`$A591`)

**The registers back, then ReadBlock**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## The '99 patches block: `menu48` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

| Module | Entries | Code entries |
| --- | --- | --- |
| `menu48` | `$C100`-`$C17E` | 12 of 12 |

### menu48

`src/patches99/menu48.asm`

#### `MenuTable48` (`$C100`)

**The menu's jump table: `$C100` the menu, `$C103-$C10C` the four texts, `$C10F` LOAD MAP**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 20 t-states own (0.00 %) |
| Runs (LOAD MAP: the catalogue and a map loaded) | 1 call, 81 t-states own (0.00 %) |
| Calls | `ShowMenu48` (tail) |
| Writes | `$C179`-`$C17A` (`QuietScreen+41`) |

#### `LoadText1Jump` (`$C103`)

**JP LoadText1: text 1 (NEdescri)**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 10 t-states own (0.00 %) |
| Calls | `LoadText1` (tail) |

#### `LoadText2Jump` (`$C106`)

**JP LoadText2: text 2 (NEadvice)**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 10 t-states own (0.00 %) |
| Calls | `LoadText2` (tail) |

#### `LoadText3Jump` (`$C109`)

**JP LoadText3: text 3 (NEgreets)**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 10 t-states own (0.00 %) |
| Calls | `LoadText3` (tail) |

#### `LoadText4Jump` (`$C10C`)

**JP LoadText4: text 4 (NEabout)**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 10 t-states own (0.00 %) |
| Calls | `LoadText4` (tail) |

#### `LoadMapJump48` (`$C10F`)

**JP LoadMap: LOAD MAP at once (nothing to page)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowMenu48` (`$C112`)

**Read the menu's packed file to `$E800`, unpack it to `$D800` and run it**

The file's position and length are stage 3's operands; A (the tape flag, the digit shown) is what Start's caller left. The menu's last RET (START) goes to `$A603` behind the CALL at Start; LOAD MAP from tape ends with JP `$D800`, into the menu without a new read.

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 2 calls, 142 t-states own (0.00 %) |
| Called from | `MenuTable48` (tail) |
| Writes | `$C179`-`$C17A` (`QuietScreen+41`) |

#### `LoadText1` (`$C124`)

**Text 1 (NEdescri): DE, BC from stage 3 (disk: the position, 22 sectors; tape: `$155D` bytes)**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 37 t-states own (0.00 %) |
| Called from | `LoadText1Jump` (tail) |

#### `LoadText2` (`$C12F`)

**Text 2 (NEadvice): disk 22 sectors, written into C (B stays 0); tape `$15C4` bytes**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 37 t-states own (0.00 %) |
| Called from | `LoadText2Jump` (tail) |

#### `LoadText3` (`$C13A`)

**Text 3 (NEgreets): disk 2 sectors; tape `$0139` bytes**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 37 t-states own (0.00 %) |
| Called from | `LoadText3Jump` (tail) |

#### `LoadText4` (`$C145`)

**Text 4 (NEabout): disk 15 sectors; tape: `$0EB3` lands in DE, the length stays 0**

| | |
| --- | --- |
| Runs (the start-up menu, LOAD MAP, HARD + PHASERS, play) | 1 call, 37 t-states own (0.00 %) |
| Called from | `LoadText4Jump` (tail) |

#### `QuietScreen` (`$C150`)

**Clear the screen, interrupts off, I = `$3F`, IM 0**

| | |
| --- | --- |
| Runs | not reached in the recordings |
