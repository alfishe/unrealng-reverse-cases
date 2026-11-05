# 12. Routine reference

Every code entry of the game in play, in address order by module (`src/game/<module>.asm`): the image of banks 5, 2
and 0 at `$6731`-`$D7D7` as the CPU sees it once the game block is unpacked. The name, the title and the description
are the source's (`src/game/game.ann`). The rest is what the recordings saw:

- `work/docL/deep`: the bot's game, 36009 frames from the game menu (robots built, orders given, factories captured,
  fights; [10.13](10-gameplay-logic.md#1013-what-the-deep-recording-showed));
- `work/game-r2`: stage 3's recording `r2` from the game's entry: a save and two loads through the disk module;
- `work/game`: stage 1's first game of the SCL, the menu and play to frame 11601.

They are local, not in the repository; the WALKTHROUGH's commands rebuild them.

- **Runs** count the calls of the entry itself. The time is its own t-states (callees excluded) and its share of the
  recording.
- **Called from / Calls** are the calls the recordings made, by entry; "(tail)" is a jump into another entry. The
  interrupt is left out: L1 counts the IM 2 jump (`ImJump`) and the vector read (`ImTable` `$68FF`-`$6900`) to
  whatever routine it falls in.
- **Reads / Writes** name the entries the ranges cover; past the image (`$D7D3` on) they are the variables of
  `src/game/game.ann`'s `@equ` lines (the robots, the map, the variables page).
- **Ports** are as L1 saw them: `$7FFD` pages, `$FE` the border and the beeper, `$FFFD` / `$BFFD` the AY.
- An entry no recording reached says so; such code is read, not seen.

Where a routine's rules are explained with figures, the chapter is named here:

| Routines | Explained in |
| --- | --- |
| `GameEntry`, `Restart`, `NewGameSetup`, `EnterPlay`, `PlayLoop` | [10.1 The start of a game](10-gameplay-logic.md#101-the-start-of-a-game) |
| `GameTurn`, `TurnPace`, `DailyProduction`, `ProduceSide`, `AddCapped` | [10.2](10-gameplay-logic.md#102-the-game-turn-and-the-clock), [10.3](10-gameplay-logic.md#103-production-and-resources) |
| `ConstructionMenu`, `ConstructionMenuLoop`, `RefundPart`, `StartRobot` | [10.4 Construction](10-gameplay-logic.md#104-construction) |
| `WorldTurn`, `UpdateRobot`, `RobotStep`, `SteerByOrder`, `RobotAim`, `SpotEnemies`, `SetStepDelay` | [7.2](07-objects.md#72-the-world-turn), [10.5](10-gameplay-logic.md#105-a-robots-turn-and-its-orders) |
| `FireShot`, `UpdateShot`, `MoveShot`, `ShotGone` | [7.5](07-objects.md#75-shots), [10.6](10-gameplay-logic.md#106-shooting-and-damage) |
| `GameTurnEnd`, `GiveFactory`, `GiveWarbase`, `SetBaseOwner`, `CountBases` | [10.7 Capture](10-gameplay-logic.md#107-capture) |
| `EnemyCommander`, `EnemyReplan`, `EnemyChooseOrder` | [10.8 The enemy commander](10-gameplay-logic.md#108-the-enemy-commander) |
| `NuclearBlast`, `BlastArea`, `NuclearFlash`, `NuclearRumble` | [10.9 The nuclear blast](10-gameplay-logic.md#109-the-nuclear-blast) |
| `GameLoad`, `LoadReturn`, `SaveGameStage`, `GameSave`, `SaveReturn`, `CheckGameEnd`, `GameWon` | [10.10](10-gameplay-logic.md#1010-load-save-and-the-end-of-a-game) |
| the bugs | [10.11 Bugs](10-gameplay-logic.md#1011-bugs) |

Written by `python3 tools/fig_routines.py` (through `kit/refdocs.py`); edit `src/game/game.ann` and run it again.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`viewtail`](#viewtail) | `$6731`-`$677F` | 0 of 1 |
| [`music`](#music) | `$6780`-`$67FF` | 4 of 6 |
| [`im2`](#im2) | `$6800`-`$697F` | 2 of 7 |
| [`sprites`](#sprites) | `$6980`-`$A569` | 0 of 178 |
| [`disk`](#disk) | `$A56A`-`$A5D9` | 2 of 3 |
| [`start`](#start) | `$A5DA`-`$A71F` | 6 of 6 |
| [`robotmenu`](#robotmenu) | `$A720`-`$AD61` | 26 of 48 |
| [`gameturn`](#gameturn) | `$AD62`-`$AE6A` | 6 of 7 |
| [`endings`](#endings) | `$AE6B`-`$AF10` | 5 of 9 |
| [`ship`](#ship) | `$AF11`-`$B0C9` | 12 of 13 |
| [`world`](#world) | `$B0CA`-`$B7F3` | 34 of 36 |
| [`enemy`](#enemy) | `$B7F4`-`$BB08` | 4 of 4 |
| [`bases`](#bases) | `$BB09`-`$BDA8` | 17 of 17 |
| [`level`](#level) | `$BDA9`-`$C0FF` | 0 of 17 |
| [`mainmenu`](#mainmenu) | `$C100`-`$C4A7` | 44 of 69 |
| [`font`](#font) | `$C4A8`-`$C848` | 0 of 3 |
| [`construction`](#construction) | `$C849`-`$CCBC` | 18 of 26 |
| [`view`](#view) | `$CCBD`-`$D0B8` | 20 of 22 |
| [`screen`](#screen) | `$D0B9`-`$D37B` | 20 of 28 |
| [`controls`](#controls) | `$D37C`-`$D3E4` | 2 of 4 |
| [`print`](#print) | `$D3E5`-`$D565` | 13 of 13 |
| [`interrupts`](#interrupts) | `$D566`-`$D6A7` | 9 of 9 |
| [`tables`](#tables) | `$D6A8`-`$D7D2` | 0 of 6 |

## music

`src/game/music.asm`

### `MusicInterrupt` (`$6780`)

**The interrupt handler outside play: one frame of the tune**

Installed in ImHandler by Restart (`$A614`) for the main menu and by ConstructionMenu (`$C85E`) while the construction menu is open (and by the unused SaveGame and GameStop). Keeps every register, the alternate set and IX, IY too, since the player in bank 1 uses them all: pages bank 1 (`$11`), calls PlayerFrame, pages back the bank in GameBank. No frame count, no radar: the world stands while it is in place.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,399 calls, 477,224 t-states own (0.02 %) |
| Runs (`work/game-r2`, save and load) | 2,833 calls, 966,053 t-states own (0.22 %) |
| Runs (`work/game`, the first game) | 830 calls, 283,030 t-states own (0.10 %) |
| Reads | `$67D9` (`GameBank`) |
| Ports out | `$7FFD` |

### `PlayMusic` (`$67B1`)

**The music in play: PlayInterrupt's radar call, then one frame of the tune**

PlayInterrupt jumps here at `$D582` in place of its CALL ShowRadar: ShowRadar runs as before, then bank 1's player plays a frame (the main registers and IX, IY kept), the bank in GameBank goes back, and the JP returns to PlayInterrupt after its call (`$D585`: the sound effect step, the exit).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 34,609 calls, 8,652,250 t-states own (0.34 %) |
| Runs (`work/game-r2`, save and load) | 1,871 calls, 467,750 t-states own (0.11 %) |
| Runs (`work/game`, the first game) | 2,973 calls, 743,250 t-states own (0.25 %) |
| Called from | `PlayInterrupt` (tail) |
| Calls | `InterruptSound` (tail), `ShowRadar` |
| Reads | `$67D9` (`GameBank`) |
| Ports out | `$7FFD` |

### `SetGameBank` (`$67DA`)

**Page the bank in A (`$7FFD`) and keep it in GameBank**

BC kept. Called by MenuPicture: bank 3 (`$13`) for the picture, bank 0 (`$10`) after it.

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 6 calls, 396 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 2 calls, 132 t-states own (0.00 %) |
| Called from | `MenuPicture` |
| Writes | `$67D9` (`GameBank`) |
| Ports out | `$7FFD` |

### `MenuPicture` (`$67E5`)

**The main menu's picture: bank 3's code draws it**

Called by MainMenuTitle (`$C103`). Bank 3 lies over `$C000-$FFFF`, the game's stack with it, so the picture code runs on GlueStack (SP = `$A5ED`); the old SP is kept in the operand of the LD SP at `$67F9`. Bank 3's MenuPictureCode (`$E73B`) unpacks the picture onto the screen; then bank 0 again.

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 3 calls, 345 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 115 t-states own (0.00 %) |
| Called from | `MainMenu` |
| Calls | `SetGameBank` |
| Writes | `$67FA`-`$67FB` (`MenuPicture`) |

## im2

`src/game/im2.asm`

### `GameSave` (`$6905`)

**Save the game through the disk module in bank 4, then back to play**

Reached by SaveGameStage's JP (`$C2E5`) once the shots and the buildings are staged with the game state at `$D92B-$FDFB`, interrupts off. Keeps SP in SaveReturn's operand, takes GlueStack, sets IX = DiskSave (`$4033`, the module's save entry; GameLoad passes DiskLoad), HALTs once for a frame's start, pages bank 4 (`$14`) and sets the ROM's keyboard variables as the module reads them: FLAGS (`$5C3B`) = `$CC`, LAST_K (`$5C08`) = ENTER, CAPS LOCK off (FLAGS2 bit 3). Then JP DiskModule (`$C000` in bank 4).

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 1 call, 54,915 t-states own (0.01 %) |
| Called from | `SaveGameStage` (tail) |
| Reads | `$5C6A` (system); `$6914` (`GameSave`) |
| Writes | `$5C08` (system); `$5C3B` (system); `$5C6A` (system); `$692C`-`$692D` (`SaveReturn`); `$A5EB`-`$A5EC` (`GameEntry`) |
| Ports out | `$7FFD` |

### `SaveReturn` (`$692B`)

**SaveReturn**

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | run into, not called, 59,419 t-states own (0.01 %) |
| Calls | `PlayRedraw` (tail) |
| Reads | `$6936` (`SaveReturn`) |
| Writes | `$FFFE`-`$FFFF` (work space) |

## disk

`src/game/disk.asm`

### `GameLoad` (`$A56A`)

**Load a saved game through the disk module in bank 4**

Reached by LoadGame's JP (`$C1FD`, key 5 of the main menu). The same steps as GameSave with IX = DiskLoad (`$4000`): SP into LoadReturn's operand, GlueStack, a HALT for a frame's start, bank 4, the ROM's keyboard variables (FLAGS `$CC`, LAST_K ENTER, CAPS LOCK off), JP DiskModule.

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 2 calls, 138,442 t-states own (0.03 %) |
| Called from | `MenuOptionsEnd` (tail) |
| Reads | `$5C6A` (system); `$A579` (`GameLoad`) |
| Writes | `$5C08` (system); `$5C3B` (system); `$5C6A` (system); `$A591`-`$A592` (`LoadReturn`); `$A5EB`-`$A5EC` (`GameEntry`) |
| Ports out | `$7FFD` |

### `LoadReturn` (`$A590`)

**LoadReturn**

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | run into, not called, 117,506 t-states own (0.03 %) |
| Calls | `NewGameSetup` (tail) |
| Reads | `$A59B` (`LoadReturn`) |
| Writes | `$5B00`-`$5B01` (system); `$FFFC`-`$FFFD` (work space) |

## start

`src/game/start.asm`

### `GameEntry` (`$A5DA`)

**The game block's entry: bank 1's start-up, then Restart**

The block's depacker ends with JP `$A5DA`. Interrupts off, SP = 0; pages bank 1 (`$11`) and calls MusicStart (`$D8E1`, bank 1's own start-up code), pages bank 0 (`$10`) and falls into Restart. Runs once: GlueStack grows over these bytes later.

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 1 call, 89 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 33,820 t-states own (0.01 %) |
| Calls | `Restart`, `PlayLoop`, `BuildMap`, `MainMenu`, `DrawViewBackground`, `DrawPlayScreen` |
| Reads | `$D7D3`-`$D7FE` (`Shots`); `$DA00`-`$DCFE` (`Robots`, `EnemyRobots`); `$FD04`-`$FDFB` (`PrintAddr`, `MapView`, `SavedSP`, `ViewX` and 33 more); `$FF01`-`$FFC8` (`Buildings`) |
| Writes | `$6800`-`$6900` (`ImTable`); `$6969`-`$696B` (`ImJump`, `ImHandler`); `$D7D3`-`$D7FF` (`Shots`); `$DA00`-`$DCFF` (`Robots`, `EnemyRobots`); `$FD00`-`$FDFC` (`RandomSeed`, `PrintAddr`, `MapView`, `SavedSP` and 34 more); `$FF01`-`$FFC9` (`Buildings`) |
| Ports out | `$7FFD` |

### `Restart` (`$A5EF`)

**Every restart: the tune from its start, the IM 2 table, the random seed, the main menu**

Entered from GameEntry and by JP from the abort key in play (`$A712`); the dead paths jump here too (LoadError `$C28A`, GameOverWait `$AEFD`, UnusedTapeCode's return address at `$AE30`). Interrupts off, SP = 0, bank 1's PlayerInit (`$C000`) restarts the tune, bank 0 again. Then ImTable: 257 bytes of `$69` at `$6800-$6900` (B = 0 runs the loop 256 times, the last byte after it), ImJump = `$C3` (JP), ImHandler = MusicInterrupt, I = `$68`, IM 2, EI. RandomSeed = `$39`,`$30`,`$39`,`$30`. MainMenu returns Z for a new game and NewGameSetup follows; a load does not return here: LoadReturn jumps to NewGameSetup with NZ.

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 3 calls, 20,700 t-states own (0.00 %) |
| Called from | `GameEntry`, `PlayLoop` (tail) |
| Calls | `MainMenu` |
| Writes | `$6800`-`$6900` (`ImTable`); `$6969`-`$696B` (`ImJump`, `ImHandler`); `$FD00`-`$FD03` (`RandomSeed`) |
| Ports out | `$7FFD` |

### `NewGameSetup` (`$A62D`)

**New game: clear the robots, variables, buildings and shots, place the ship, build the map**

Two ways in, told apart by the zero flag: Restart falls in with Z after MainMenu (option 0, СТАРТ ИГРЫ (start game)), and LoadReturn jumps here with NZ after the disk module loaded a saved game (the robots, the map, the buildings, the shots and the variables), which skips straight to EnterPlay. Z sets a new game up.

Zeroes the robot records `$DA00-$DCFF` (48 x 16), the variables `$FD04-$FDFC` (everything past the random seed), the building table `$FF01-$FFC9` and the five shot records `$D7D3-$D7FF` (5 x 9). Then: MapView = `$DD00`, ViewX = 0, ShipX = `$11`, ShipY = 10, Altitude = 0, the auto-climb counter `$FD30` = 3 (the ship rises to 6 on its own at the start), the general resource of both sides = 20 (Resources and `$FD4A`). BuildMap then clears the map `$DD00-$FCFF` and the radar buffer `$D800` and builds the landscape, the warbases and the factories. Falls into EnterPlay.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | run into, not called, 656,332 t-states own (0.03 %) |
| Runs (`work/game-r2`, save and load) | 2 calls, 26,795 t-states own (0.01 %) |
| Called from | `LoadReturn` (tail) |
| Calls | `EnterPlay` (tail), `RobotMenu`, `GameTurn`, `MoveShip`, `WorldTurn`, `CountRobots`, `BuildMap`, `ConstructionMenu`, `ShipCell`, `DrawView`, `FindRobot`, `FindBuilding`, `DrawViewBackground`, `DrawPlayScreen`, `UpdateStatusPanel`, `WaitKey` |
| Reads | `$D7D3`-`$D7FE` (`Shots`); `$DA00`-`$DCFE` (`Robots`, `EnemyRobots`); `$E714`-`$E716` (`Map`); `$E914`-`$EB18` (`Map`); `$ED12`-`$ED18` (`Map`); 7 more ranges |
| Writes | `$696A`-`$696B` (`ImHandler`); `$D7D3`-`$D7FF` (`Shots`); `$DA00`-`$DCFF` (`Robots`, `EnemyRobots`); `$FD04`-`$FDFC` (`PrintAddr`, `MapView`, `SavedSP`, `ViewX` and 33 more); `$FF01`-`$FFC9` (`Buildings`); `$FFFE`-`$FFFF` (work space) |

### `EnterPlay` (`$A68E`)

**Draw the play screen and switch to the play interrupt**

DrawViewBackground and DrawPlayScreen build the play screen (the view, its frame, the radar, the status panel); then ImHandler = PlayInterrupt, which counts the frames in `$FD34` and draws the radar each frame. Falls into PlayLoop. Entered from NewGameSetup (a new game, or a loaded one on NZ) and from PlayRedraw (`$A71D`) after a game save (key 5).

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 3 calls, 240 t-states own (0.00 %) |
| Called from | `NewGameSetup` (tail), `PlayRedraw` (tail) |
| Calls | `PlayLoop`, `DrawViewBackground`, `DrawPlayScreen` |
| Writes | `$696A`-`$696B` (`ImHandler`) |

### `PlayLoop` (`$A69A`)

**The play loop: one game turn a pass (at least 10 frames)**

One pass: WaitKey (the controls into Input; key 1 pauses here), MoveShip, WorldTurn (every robot record and the five shots), DrawView (draw the view), GameTurn (the random step, the clock, captures, the end of the game; waits until 10 frames have passed since the previous turn).

Then it looks under the ship (ShipCell: HL = the ship's map cell). Map bit 6 means something stands there. A robot of ours (FindRobot, B = 48 - slot >= 25) with the ship resting exactly on its top (Altitude = +`$09` + +`$0D`) opens RobotMenu. Otherwise a building of type 0 (the pad of our warbase) with Altitude = 15 (the pad's top, the ship cannot sink below it) opens ConstructionMenu, but only when the warbase's door cell 4 rows below the pad and the three cells below the door (row +5, columns -1, 0, +1) are free of bit 6: the new robot is placed on the door (ShipY + 4, `$CB6A`). After the menu the new record gets +`$05` = 4, +`$06` = 5, +`$0B` = 0 (stop), +`$0C` = 100 (strength), +`$0F` = 1 (moves at once); CountRobots recounts the robots and UpdateStatusPanel reprints the panel.

ConstructionMenu returns at once when all 24 of our slots are taken, with IY left on `$DB80`, the enemy's slot 24. The writes at `$A6F3` then hit that enemy robot: its strength goes back to 100 and its order to 0, every turn the ship sits on the pad.

Last, the game keys: Input bit 6 (key I in the default KeyTable) abandons the game (JP Restart), bit 5 (key 5) saves the game to disk (JP SaveGameStage; the disk module comes back through SaveReturn to PlayRedraw, which redraws the play screen with EnterPlay).

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 4 calls, 32,067 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 1 call, 52,043 t-states own (0.02 %) |
| Called from | `GameEntry`, `EnterPlay` |
| Calls | `Restart` (tail), `GameTurn`, `MoveShip`, `WorldTurn`, `SaveGameStage` (tail), `ShipCell`, `DrawView`, `WaitKey` |
| Reads | `$F111` (`Map`); `$F2EE` (`Map`); `$FD0C` (`Input`) |

### `PlayRedraw` (`$A71D`)

**PlayRedraw**

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 1 call, 10 t-states own (0.00 %) |
| Called from | `SaveReturn` (tail) |
| Calls | `EnterPlay` (tail) |

## robotmenu

`src/game/robotmenu.asm`

### `RobotMenu` (`$A720`)

**landing on a robot of ours: ПРЯМОЕ УПРАВЛ. (direct control), ОТДАТЬ ПРИКАЗ (give orders), БОЕВОИ РЕЖИМ (combat mode), ОСТАВИТЬ РОБОТА (leave the robot); the order to +`$0B`**

IX = IY (the record), +`$0A` = 1 (the robot stands: UpdateRobot returns at once for +`$0A` = 1), MenuCursor = 4 (ОСТАВИТЬ РОБОТА (leave the robot) first), PanelBusy = 1. Falls into RobotMenuShow. Called by PlayLoop when the ship rests exactly on the top of a robot of ours.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7 calls, 616 t-states own (0.00 %) |
| Called from | `NewGameSetup` |
| Calls | `RobotMenuShow` |
| Writes | `$DA0A`-`$DA5A` (`Robots`); `$FD1F` (`MenuCursor`); `$FD39` (`PanelBusy`) |

### `RobotMenuShow` (`$A732`)

**Robot menu: draw the four items, the current order and the strength, then choose**

Clears the side panel (ClearPanel) and prints ПРЯМОЕ УПРАВЛ. (direct control), ОТДАТЬ ПРИКАЗ (give orders), БОЕВОИ РЕЖИМ (combat mode), ОСТАВИТЬ РОБОТА (leave the robot) at (4,23), every 3 rows, attribute `$4D`, and the title -ORDERS- at (17,23). Falls into ShowOrder, ShowOrderMiles and RobotMenuChoose. Every submenu comes back here when it is done (`$A93E`, `$AA09`, `$AACC`, `$ABFD`, the combat menu at `$AC8B`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 14 calls, 476 t-states own (0.00 %) |
| Called from | `RobotMenu`, `SetOrder` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

### `ShowOrder` (`$A795`)

**Robot menu: print the name of the robot's order**

Copies the 27-byte name of order +`$0B` from OrderNames (`$A848` + 27 x order) into OrderLine, the string printed right after the CALL at `$A7AA`: three lines at (18,23), attribute `$45`.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 14 calls, 10,094 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintInline` |
| Reads | `$A848`-`$A862` (`OrderNames`); `$A899`-`$A8B3` (`OrderName3`); `$A8EA`-`$A91F` (`OrderName6`, `OrderName7`); `$DA0B`-`$DA5B` (`Robots`) |
| Writes | `$A7B2`-`$A7CC` (`OrderLine`) |

### `ShowOrderMiles` (`$A7CD`)

**Robot menu: for ADVANCE and RETREAT, the miles under the order's name**

Orders 1 and 2 only: prints at (19,25) the distance +`$0E` / 2 with two digits (PrintNumber2), into the blank middle line of the order's name (" ВПЕРЕД ", "nn", " МИЛЬ   "). Other orders jump straight to RobotMenuChoose. IX = the robot record.

The printing tail after the inline position is ShowMilesCode (`$A7DC`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 14 calls, 3,204 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `OrdersMenu` (tail), `ListMenu`, `Beep`, `ShowStatusPanel`, `ClearPanel` |
| Reads | `$DA0B`-`$DA5B` (`Robots`); `$FD1F` (`MenuCursor`) |
| Writes | `$DA06`-`$DA5A` (`Robots`); `$FD1F` (`MenuCursor`); `$FD30`-`$FD39` (`ClimbTurns`, `PrintColumn`, `PrintRow`, `TurnFrames` and 2 more) |

### `ShowMilesCode` (`$A7DC`)

**LD A,(IX+`$0E`); SRL A; CALL `$D3E5`**

The tail of ShowOrderMiles after its inline position: A = +`$0E` / 2 (the miles, stored doubled), printed with two digits and a leading space by PrintNumber2. Falls into RobotMenuChoose.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RobotMenuChoose` (`$A7E4`)

**Robot menu: choose an item and run it; ОСТАВИТЬ РОБОТА (leave the robot) closes the menu**

Prints the strength, runs ListMenu on the four items (HL = `$5837`, the attribute of row 1 column 23, E = 5, A = MenuCursor) and keeps the choice in MenuCursor, so the menu reopens on it. 1 ПРЯМОЕ УПРАВЛ. (direct control) (`$A93B`), 2 ОТДАТЬ ПРИКАЗ (give orders) (OrdersMenu), 3 БОЕВОИ РЕЖИМ (combat mode) (CombatMenu `$AC00`), 4 ОСТАВИТЬ РОБОТА (leave the robot): a beep, +`$06` = 0, +`$0A` = 0 (the robot carries on with its order), the auto-climb `$FD30` = 5 turns so the ship rises off the robot and the menu does not reopen, then CloseRobotMenu.

CloseRobotMenu (`$A812`) clears the panel, sets `$FD39` = 0 and redraws the status panel (ShowStatusPanel); ListMenu also jumps there when the robot is destroyed while its menu is open (seen: freeing +`$01` under the open menu closed it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowStrength` (`$A81D`)

**Robot menus: print STRENGTH and the robot's strength in %**

Prints "СИЛА" (strength) at (22,23) and the value of +`$0C` at (23,25), three digits with leading spaces and "%" (a robot is born with 100). Called once a turn by every robot menu loop. IX = the robot record.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 111 calls, 1,887 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose`, `ListMenu` |
| Calls | `PrintInline` |

### `ShowStrengthValue` (`$A833`)

**Print the strength +`$0C` as "nnn%"**

The tail of ShowStrength after its inline string: a negative strength is shown as 0; PrintNumber3 prints HL with three digits, E = `$20` makes the leading zeros spaces; the "%" goes out through PrintCharKeep.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 111 calls, 9,435 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber3`, `PrintCharKeep` (tail) |
| Reads | `$DA0C`-`$DA5C` (`Robots`) |

### `DirectControlItem` (`$A93B`)

**Robot menu item 1: direct control, then the robot menu again**

Calls DirectControl (drive the robot until fire, or until it is destroyed) and redraws the robot menu with RobotMenuShow. MenuCursor still holds 1, so the menu reopens on ПРЯМОЕ УПРАВЛ. (direct control). A robot destroyed while driven: DirectControl returns, RobotMenuShow redraws, and ListMenu then sees +`$01` = 0 and closes the menu.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DirectControl` (`$A941`)

**Drive the robot with the controls until fire**

+`$0A` = 2 and +`$05` = 0, then a loop of game turns without the ship's own move: WorldTurn moves the robot from Input (`$B184` -> `$B450`) and calls MoveShip from there (`$B4A8`), so the ship travels on the robot; DrawView draws the view, MenuRadarTick blinks the ship on the radar, GameTurn, ShowStrength. Fire gives the robot back (+`$0A` = 1, a beep) and returns. Returns at once (Z) when the robot is destroyed (+`$01` = 0).

Used by the robot menu (item 1) and by the combat menu (ДВИЖЕНИЕ (move), `$AC93`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OrdersMenu` (`$A971`)

**ОТДАТЬ ПРИКАЗ (give orders): the five orders**

Clears the panel and prints SELECT ORDERS at (4,24) and the five items from (7,23): СТОЯТЬ И ДЕРЖАТЬ ОБОРОНУ (stop and defend), ADVANCE ?? MILES, RETREAT ?? MILES, ПОИСК И ЛИКВИД. (search and destroy), ПОИСК И ЗАХВАТ (search and capture). Falls into OrdersMenuChoose.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7 calls, 238 t-states own (0.00 %) |
| Called from | `ShowOrderMiles` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

### `OrdersMenuChoose` (`$A9EC`)

**ОТДАТЬ ПРИКАЗ (give orders): choose; stop at once, advance / retreat ask the miles, search asks the target**

ListMenu at HL = `$5897` (row 4: item 1 at row 7), E = 6, A = 1. Item 1 sets order 0 (stop and defend) and returns to the robot menu. Items 2 and 3 set order 1 (advance) or 2 (retreat) and go on to the distance menu (DistanceMenu, `$AA19` on). Items 4 and 5 go to TargetMenu with the flags of CP 3 (Z = ПОИСК И ЛИКВИД. (search and destroy)).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7 calls, 903 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `TargetMenu` (tail), `ListMenu`, `WaitRelease` |

### `AdvanceJump` (`$AA2D`)

**JR `$AA40`, past the RETREAT title**

The last instruction of the ADVANCE branch of OrdersMenuChoose: after the ВПЕРЕД (advance) title it jumps over RetreatTitle into DistanceMenu, the part both orders share.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RetreatTitle` (`$AA2F`)

**ОТДАТЬ ПРИКАЗ (give orders), RETREAT: the title of the distance menu**

The RETREAT branch of OrdersMenuChoose: prints НАЗАД (retreat) at (5,23), attribute `$20`, then falls into DistanceMenu. The order (+`$0B` = 2) is already stored.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DistanceMenu` (`$AA40`)

**CALL PrintInline, the distance menu's texts**

The distance menu of ADVANCE and RETREAT, shared by both: its texts ?? МИЛЬ (the next line under the title), ВЫБОР ДИСТАН. (select the distance) at (9,23), 0 МИЛЬ at (13,24); then falls into DistanceSelect.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DistanceSelect` (`$AA6E`)

**DistanceSelect**

D = the miles, from 0. Each pass of DistanceLoop is one game turn (ShowStrength, WorldTurn, DrawView, MenuRadarTick, GameTurn); a destroyed robot (+`$01` = 0) closes the whole menu (JP CloseRobotMenu). Then WaitKey: fire goes to DistanceFire; up adds 5, down takes 5 (up wins when both are held); a value out of 0-50 (CP `$33`, a negative one wraps above it) is refused. A change is printed at (13,23), attribute `$46`, by DistanceShow with the click `$14`. No release wait: a held key steps once a game turn.

DistanceFire: +`$0E` = miles x 2; 0 miles turns the order back into 0 (stop and defend); the beep `$78`, WaitRelease, back to the robot menu.

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

**ПОИСК И ЛИКВИД. (search and destroy) or ПОИСК И ЗАХВАТ (search and capture): the three targets**

Z (the destroy item): clears the panel and prints ПОИСК И ЛИКВИД. (search and destroy), ВЫБОР ЦЕЛИ (select the target) and ENEMY ROBOTS / ENEMY FACTORYS / ENEMY WARBASES; NZ goes to CaptureMenu.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7 calls, 172 t-states own (0.00 %) |
| Called from | `OrdersMenuChoose` (tail) |
| Calls | `CaptureMenu` (tail), `ClearPanel`, `PrintInline` |

### `DestroyMenuChoose` (`$AB3D`)

**ПОИСК И ЛИКВИД. (search and destroy): choose the target, orders 3-5**

ListMenu at HL = `$5937` (item 1 at row 12), E = 4, A = 1; the item + 2 is the order (3 robots, 4 factories, 5 warbases) for SetOrder.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3 calls, 231 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `SetOrder` (tail), `ListMenu` |

### `CaptureMenu` (`$AB4E`)

**ПОИСК И ЗАХВАТ (search and capture): the three targets**

Prints ПОИСК И ЗАХВАТ (search and capture), ВЫБОР ЦЕЛИ (select the target) and NEUTRAL FACTORYS / ENEMY FACTORYS / ENEMY WARBASES.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 4 calls, 136 t-states own (0.00 %) |
| Called from | `TargetMenu` (tail) |
| Calls | `ClearPanel`, `PrintInline` |

### `CaptureMenuChoose` (`$ABB9`)

**ПОИСК И ЗАХВАТ (search and capture): choose the target, orders 6-8**

The same list as DestroyMenuChoose; the item + 5 is the order (6 neutral factories, 7 enemy factories, 8 enemy warbases).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 4 calls, 260 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ShowStrength`, `SetOrder`, `ListMenu` |

### `SetOrder` (`$ABC8`)

**Store a search order, look for its first target, or fall back to stop**

A = the order (3-8) into +`$0B`. Orders 4 and 5 (destroy factories, warbases) need the nuclear bomb (+`$07` bit 6); without it the order becomes 0. Otherwise `$FD51` = 0 (our side), +`$0E` = `$FF` and FindTargetBuilding looks for a target of the order from the robot's X (+`$02`/+`$03`): D, the index it found, goes to +`$0E`; no target (Z) makes the order 0. A beep, WaitRelease, back to the robot menu.

CombatMenu (`$AC00`) follows in the same block: the robot menu's item 3.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7 calls, 1,680 t-states own (0.00 %) |
| Called from | `DestroyMenuChoose` (tail), `CaptureMenuChoose` |
| Calls | `RobotMenuShow` (tail), `WaitRelease`, `FindTargetBuilding`, `Beep` |
| Reads | `$DA02`-`$DA53` (`Robots`) |
| Writes | `$DA0B`-`$DA5E` (`Robots`); `$FD51` (`Side`) |

### `CombatMenuCode` (`$AC7C`)

**CombatMenuCode**

The code after CombatMenuText: the strength, then ListMenu on the six items (HL = `$5837`, E = 7), ВЫХОД ИЗ МЕНЮ (leave the menu) highlighted first. Each choice comes back to CombatMenuLoop with A = the item, so the menu reopens on it.

6 ВЫХОД ИЗ МЕНЮ (leave the menu): back to the robot menu. 5 ДВИЖЕНИЕ (move): DirectControl, then the menu again. 1-4 need the weapon: +`$07` rotated left item + 1 times leaves in carry bit 6 (nuclear), 5 (phasers), 4 (missiles) or 3 (cannon); without it the low buzz (`$FA`) and the menu again.

1 АТОМНАЯ БОМБА (nuclear bomb): IY = IX, NuclearBlast, then the menu closes (JP CloseRobotMenu): the bomb destroys the robot carrying it. 2-4: shot record 0 at `$D7D3` (Shots); if it is free (+`$01` = 0), A = 5 - item (3 phasers, 2 missiles, 1 cannon) and FireShot launches it from the robot along its facing (+`$08`), then DrawView and GameTurn; a shot of record 0 still flying buzzes.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ListMenu` (`$ACD7`)

**a list menu: HL the attribute of item 0 (an item every 3 rows), E the items + 1, A the first highlighted; down / up move, fire returns A**

Each pass is one game turn (WorldTurn, DrawView, MenuRadarTick, GameTurn, ShowStrength): the game goes on while a menu waits. A destroyed robot (+`$01` = 0) drops ListMenu's return address and closes the robot menu (CloseRobotMenu). Up / down move by one item (items 1 to E - 1) with a click `$14`; fire paints the item `$4F`, beeps `$64` and returns A. Attributes: `$4D` normal, `$4E` highlighted, `$4F` chosen. Needs IX = a robot record.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 28 calls, 36,032 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose` |
| Calls | `ShowStrength`, `PaintMenuItem`, `WaitRelease`, `GameTurn`, `MenuRadarTick`, `WorldTurn`, `Beep`, `DrawView`, `WaitKey` |
| Reads | `$DA01`-`$DA51` (`Robots`); `$FD0C` (`Input`) |

### `PaintMenuItem` (`$AD3C`)

**Colour list item A: 2 rows of 8 attributes with C**

HL = the attribute of item 0; item A starts `$60` bytes (3 rows) further per item. Fills 8 attributes, moves down a row (`$18` more) and fills 8 more with C (`$4D` normal, `$4E` highlighted, `$4F` chosen). A must be 1 or more. Keeps DE and HL.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 166 calls, 32,974 t-states own (0.00 %) |
| Called from | `ListMenu` |
| Calls | `FillAttributes`, `AddAToHL` |

### `WaitRelease` (`$AD57`)

**wait until no control is held**

Calls WaitKey until Input is 0: every control up. Used by every menu before it reads a new press, so the fire that chose an item does not choose again. Keeps BC and HL; A = 0 on return. Uses WaitKey, so key 1 still pauses.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 42 calls, 3,360 t-states own (0.00 %) |
| Called from | `OrdersMenuChoose`, `SetOrder`, `ListMenu` |
| Calls | `WaitKey` |

## gameturn

`src/game/gameturn.asm`

### `GameTurn` (`$AD62`)

**One game turn: the random step, the clock, the daily production, the clock print**

Random steps the random generator `$FD00-$FD03`. Clock (`$FD35` minutes, `$FD36` hours, `$FD37-$FD38` days) gains 5 minutes a turn: 60 minutes make an hour, 24 hours a day, and a new day runs DailyProduction. Then the clock print: days at (0,27), five digits with leading spaces; "HH.MM" on the next line. Goes on in GameTurnEnd.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,415 calls, 301,152 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 183 calls, 16,111 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 297 calls, 26,160 t-states own (0.01 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu` |
| Calls | `DailyProduction`, `Random`, `PrintInline` |
| Reads | `$FD35`-`$FD38` (`Clock`) |
| Writes | `$FD35`-`$FD38` (`Clock`); `$FFFA`-`$FFFB` (work space) |

### `GameTurnEnd` (`$AD90`)

**Game turn, second half: the clock print, the game end, captures, the frame pacing**

The second half of GameTurn, reached after the PrintInline of ClockPos (setting the print position (0,27) and attribute `$57`). Prints the days (PrintNumber5, five digits with leading spaces) and, a line down (PrintNewline), the hours "." the minutes (PrintNumber2Zero, two digits with zeros). Then CheckGameEnd: a side with no warbase ends the game here.

Captures: the 28 capture points at `$FD70` (5 bytes each: X 2 bytes, Y, owner and type, count; points 0-3 the warbases, 4-27 the factories) are checked each turn. While map bit 6 is set on a point's door cell (an anchor stands there) its count +4 goes up; at 144 (`$90`) FindRobot takes the robot there and its side (+`$0A` bit 7) captures the building: GiveWarbase for a warbase, GiveFactory (point - 4) for a factory. A door anchor that is no robot (probably a flying shot) captures nothing; the count still starts again. An empty door resets the count. Any robot captures, whatever its order. After a capture CountBases recounts the buildings and UpdateStatusPanel reprints the status.

Last, the pacing (TurnPace): waits until PlayInterrupt has counted 10 frames in TurnFrames (`$FD34`) since the last turn, then clears it. A turn is at least 10 frames: an hour 120, a game day 2880 (about 58 s). Keeps IY (pushed around the loop); A, BC, DE, HL lost.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,414 calls, 209,327,863 t-states own (8.11 %) |
| Runs (`work/game-r2`, save and load) | 183 calls, 14,017,896 t-states own (3.23 %) |
| Runs (`work/game`, the first game) | 297 calls, 30,637,289 t-states own (10.30 %) |
| Called from | `PrintInline` |
| Calls | `CheckGameEnd`, `CountBases`, `GiveFactory`, `MapCell`, `FindRobot`, `UpdateStatusPanel`, `PrintNumber2Zero`, `PrintNumber5`, `PrintCharKeep`, `PrintNewline` |
| Reads | `$DA0A`-`$DA1A` (`Robots`); `$DA7A` (`Robots`); `$DB9A` (`EnemyRobots`); `$DBBA` (`EnemyRobots`); `$DBDA` (`EnemyRobots`); 11 more ranges |
| Writes | `$FD34` (`TurnFrames`); `$FD74`-`$FDFB` (`Warbases`, `Factories`); `$FFF2`-`$FFFD` (work space) |

### `UnusedTapeCode` (`$AE29`)

**Unreferenced code: keys 6 and 7 together jump into the tape ROM**

15 bytes of code nothing calls or jumps to: LD A,`$EF`; IN A,(`$FE`); AND `$18`; RET NZ (unless 6 and 7 are both held); LD HL,Restart; PUSH HL; DI; JP `$04B0`. `$04B0` is inside an instruction of the 48K ROM's SAVE code; with Restart as the return address it looks like a debugging leftover (a memory dump to tape). Never runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DailyProduction` (`$AE38`)

**A new day: each side's buildings add to its resources**

Our side from `$FD3A` into Resources, the enemy from `$FD42` into `$FD4A` (ProduceSide), then the panel reprint (UpdateStatusPanel).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 11 calls, 1,111 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 101 t-states own (0.00 %) |
| Called from | `GameTurn` |
| Calls | `ProduceSide`, `UpdateStatusPanel` |

### `ProduceSide` (`$AE4E`)

**One side's production: 5 general a warbase, 2 a factory of each kind**

DE = the side's building counts (warbases, then the factories of electronics, nuclear, phasers, missiles, cannon, chassis), HL = its 7 resources (general first, then the same order). General += 5 x warbases; each other resource += 2 x the factories of its kind; every resource stops at 99.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 22 calls, 8,140 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 2 calls, 740 t-states own (0.00 %) |
| Called from | `DailyProduction` |
| Calls | `AddCapped` |
| Reads | `$FD3A`-`$FD48` (`PlayerBuildings`, `PlayerRobotCount`, `EnemyBuildings`) |

### `AddCapped` (`$AE62`)

**(HL) += A, at most 99**

(HL) += A, at most 99: the resource store of ProduceSide. HL is kept, so ProduceSide walks the 7 resources with INC HL. A = the new value. Used only by ProduceSide.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 154 calls, 6,622 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 14 calls, 602 t-states own (0.00 %) |
| Called from | `ProduceSide` |
| Reads | `$FD22`-`$FD28` (`Resources`); `$FD4A`-`$FD50` (`EnemyResources`) |
| Writes | `$FD22`-`$FD28` (`Resources`); `$FD4A`-`$FD50` (`EnemyResources`) |

## endings

`src/game/endings.asm`

### `CheckGameEnd` (`$AE6B`)

**The end of the game: the enemy has no warbase (won) or we have none (lost)**

Called once a game turn by GameTurn. EnemyBuildings+0 = 0 (no enemy warbase): GameWon. Else PlayerBuildings+0 not 0: back to the turn. Else the game is lost: Silence, I = `$3F`, IM 1, EI, bank 3 (`$13`) and JP DeadEnd (`$D2EF` in bank 3). The lost path takes the CALL first only to empty the AY; nothing comes back.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,415 calls, 177,637 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 183 calls, 9,535 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 297 calls, 15,444 t-states own (0.01 %) |
| Called from | `GameTurnEnd` |
| Reads | `$FD3A`-`$FD42` (`PlayerBuildings`, `PlayerRobotCount`, `EnemyBuildings`) |
| Writes | `$FFFA`-`$FFFB` (work space) |

### `Silence` (`$AE94`)

**The AY's registers 0-14 to zero: no tone, no noise, volume 0 on all three channels**

Waits for one interrupt first (HALT), so the music handler has played its last frame, then turns interrupts off for good: the endings set their own. A counts the registers; each is selected at `$FFFD` and written 0 at `$BFFD`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GameWon` (`$AEB1`)

**The enemy has no warbase left: the Final Cut block from bank 6 to `$6060`, and run**

Silence, I = `$3F`, IM 1, EI, bank 6 (`$16`), `$3637` bytes from FinalCutBlock (`$C000` in bank 6) copied to FinalCut (`$6060`, over the view buffer, the sprites and the code past it), bank 0 again and JP FinalCut: the block unpacks and plays the ending and never returns.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GameOverWait` (`$AEEA`)

**Code nothing reaches: the old end of a game, a beep, a pause, a key, Restart**

Both ends of a game leave the game now, so no path comes here. The code: the beep with A = `$FA`, 100 frames of HALT, WaitRelease, then WaitKey until a control is held and JP Restart.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GameStop` (`$AF00`)

**Code nothing calls: give the panel back to the status, the menu handler**

PanelBusy = 0, ClearPanel, ShowStatusPanel, then LD HL,MusicInterrupt and LD (`$6D6A`),HL: a typo for ImHandler (`$696A`). Run, it would write the handler's address into the sprites (`$6D6A`) and leave the interrupt as it was. No CALL GameStop is left in the game.

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
| Runs (`work/docL/deep`, the bot's game) | 3,333 calls, 1,199,580 t-states own (0.05 %) |
| Runs (`work/game-r2`, save and load) | 184 calls, 56,892 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 298 calls, 87,258 t-states own (0.03 %) |
| Called from | `NewGameSetup`, `PlayLoop` |
| Calls | `ScrollRadar`, `LiftShipFromMap`, `PutShipOnMap`, `CheckShipMove` |
| Reads | `$FD0A`-`$FD1E` (`ViewX`, `Input`, `ShipY`, `ShipX` and 10 more); `$FD30` (`ClimbTurns`) |
| Writes | `$FD06`-`$FD1E` (`MapView`, `SavedSP`, `ViewX`, `Input` and 12 more); `$FD30` (`ClimbTurns`) |

### `ScrollRadar` (`$AFE6`)

**Move the radar window by 64 columns when the ship nears its edge**

The radar shows 128 map columns: from column `$FD1B` x 8 (`$FD1C` = the same as a column, 16 bits). With A = ShipX / 8 - `$FD1B`: below 2 (the ship within 16 columns of the left edge) the window moves 8 units left, unless it is at 0; 14 and more moves it 8 units right, at most to `$30` (columns 384-511). A move sets `$FD52` = 1: the radar bitmap is rebuilt from the map by BuildRadar at the ship's next mark (`$B029`). Called by MoveShip every turn (3332 times).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,333 calls, 356,631 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 184 calls, 19,688 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 298 calls, 31,886 t-states own (0.01 %) |
| Called from | `MoveShip` |
| Reads | `$FD0E`-`$FD1B` (`ShipX`, `Altitude`, `ShipDrawPos`, `PrintAttr` and 5 more) |

### `LiftShipFromMap` (`$B01D`)

**clear the ship's occupant bit in its map cell, toggle its radar dot**

Called by MoveShip first thing each game turn, before the ship moves: the cell under the ship (ShipCell: `$DD00` + `$200` * ShipY + ShipX) loses bit 7, the occupant bit robots test (FreeDirections) when the ship hangs lower than their top, and the ship's dot on the radar is toggled off when it is on (BlinkShipDot). PutShipOnMap undoes both after the move.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,333 calls, 146,652 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 184 calls, 8,096 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 298 calls, 13,112 t-states own (0.00 %) |
| Called from | `MoveShip` |
| Calls | `BlinkShipDot` (tail), `ShipCell` |
| Reads | `$E714`-`$E716` (`Map`); `$E914`-`$EB18` (`Map`); `$ED12`-`$ED18` (`Map`); `$EF12`-`$F118` (`Map`); `$F2EE` (`Map`); `$F316`-`$F318` (`Map`); 3 more ranges |
| Writes | `$E714`-`$E716` (`Map`); `$E914`-`$EB18` (`Map`); `$ED12`-`$ED18` (`Map`); `$EF12`-`$F118` (`Map`); `$F2EE` (`Map`); `$F316`-`$F318` (`Map`); 3 more ranges |

### `PutShipOnMap` (`$B024`)

**set the ship's occupant bit in its new map cell, rebuild the radar if the window moved, toggle the ship's dot**

Called at the end of MoveShip (and by BuildMap). Sets bit 7 of the ship's cell, then goes on into RefreshRadar.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,334 calls, 106,688 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 185 calls, 11,401 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 299 calls, 18,268 t-states own (0.01 %) |
| Called from | `MoveShip`, `BuildMap` |
| Calls | `RefreshRadar`, `BlinkShipDot`, `ShipCell`, `BuildRadar` |
| Reads | `$E714`-`$E716` (`Map`); `$E914`-`$EB18` (`Map`); `$ED12`-`$ED18` (`Map`); `$EF12`-`$F118` (`Map`); `$F2EE` (`Map`); `$F316`-`$F318` (`Map`); 4 more ranges |
| Writes | `$E714`-`$E716` (`Map`); `$E914`-`$EB18` (`Map`); `$ED12`-`$ED18` (`Map`); `$EF12`-`$F118` (`Map`); `$F2EE` (`Map`); `$F316`-`$F318` (`Map`); 4 more ranges |

### `RefreshRadar` (`$B029`)

**rebuild the radar when RadarDirty is set, then blink the ship's dot**

RadarDirty (`$FD52`) is set when the window moved (`$B017`) and by other code that changes the map (the start, a loaded game). BuildRadar then redraws both radar layers `$D800` / `$D900` from the map (a pixel for every cell of type `$0F` or more, the high ground) and plots every live robot's dot; the flag is cleared. Falls into BlinkShipDot. Also reached from MenuRadarTick.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,417 calls, 99,122 t-states own (0.00 %) |
| Called from | `PutShipOnMap`, `MenuRadarTick` (tail) |
| Calls | `BlinkShipDot`, `BuildRadar` |
| Reads | `$FD52` (`RadarDirty`) |
| Writes | `$FD52` (`RadarDirty`) |

### `BlinkShipDot` (`$B036`)

**on odd ticks toggle the ship's 2x2 dot on the radar's player layer**

RadarBlink (`$FD1E`) counts the game turns (MoveShip increments it between LiftShipFromMap and PutShipOnMap, MenuRadarTick in the menus). When it is odd, ToggleRadarDot XORs a 2x2 dot at (ShipX, ShipY) into the layer B = 0 (`$D800`, shown with attribute `$4D` by PlayInterrupt in alternate frames). Off-window positions draw nothing (RadarDotAddress). The pairs of toggles around each move leave the dot on every other turn: the ship's dot blinks.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 6,833 calls, 362,165 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 369 calls, 19,535 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 597 calls, 31,619 t-states own (0.01 %) |
| Called from | `LiftShipFromMap` (tail), `PutShipOnMap`, `RefreshRadar`, `MenuRadarTick` |
| Calls | `ToggleRadarDot` (tail) |
| Reads | `$FD0D`-`$FD1E` (`ShipY`, `ShipX`, `Altitude`, `ShipDrawPos` and 8 more) |
| Writes | `$FFF2`-`$FFF5` (work space) |

### `MenuRadarTick` (`$B048`)

**one blink step of the ship's dot while a menu is open**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 83 calls, 4,003 t-states own (0.00 %) |
| Called from | `ListMenu` |
| Calls | `RefreshRadar` (tail), `BlinkShipDot` |
| Reads | `$FD1E` (`RadarBlink`) |
| Writes | `$FD1E` (`RadarBlink`); `$FFF4`-`$FFF5` (work space) |

### `CheckShipMove` (`$B052`)

**carry: the ship may not stand at HL (X), A (Y)**

Tests a place for the ship: HL = the column X, A = the row Y. C = the highest top under the ship's 2 x 2 footprint (X, Y), (X+1, Y), (X, Y-1), (X+1, Y-1): the terrain height of each cell and the top of any robot (+`$09` + +`$0D`) or building (BuildingTops) anchored there (CellTop); then ObjectTop alone on (X-1, Y-1), (X-1, Y) and, inside the map, the row Y+1 (X-1 to X+1), whose anchored objects reach into the footprint.

Out: carry set when Altitude < C (the ship would be inside something there), C = the top, HL = X kept; B kept (ObjectTop saves BC), DE and A lost, IY may point at the robot or building found. Called by MoveShip for the X move (MoveShipX), the Y move (ShipCheckY) and, with the ship's own place, by Sink to get the floor under the ship.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 2,370 calls, 713,389 t-states own (0.03 %) |
| Runs (`work/game-r2`, save and load) | 42 calls, 12,642 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 6 calls, 1,806 t-states own (0.00 %) |
| Called from | `MoveShip` |
| Calls | `CellTop`, `ObjectTop`, `MapCell` |
| Reads | `$FD10` (`Altitude`) |

### `TerrainTop` (`$B08A`)

**C = max(C, the ground height of the terrain type at DE)**

DE a map cell. The cell's type (bits 0-4) indexes the ground height table TerrainHeights `$D7BC` (00 00 02 02 02 02 03 03 06 06 06 06 00 00 00 07 0F 07 0F ...: types 2-5 height 2, 6-7 (the wreck a destroyed robot leaves) 3, 8-`$0B` 6, `$0F`/`$11` 7, `$10`/`$12` 15). Keeps the higher of it and C (KeepHigher).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 41,204 calls, 2,472,620 t-states own (0.10 %) |
| Runs (`work/game-r2`, save and load) | 292 calls, 24,839 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 276 calls, 23,460 t-states own (0.01 %) |
| Called from | `CellTop`, `GroundUnderFootprint` |
| Calls | `KeepHigher` (tail), `AddAToHL` |
| Reads | `$D7BC`-`$D7CE` (`TerrainHeights`); `$DD3D`-`$DE67` (`Map`); `$DEAA`-`$DEBB` (`Map`); `$DF3A`-`$E067` (`Map`); `$E0A4`-`$E0BB` (`Map`); 1 more ranges |
| Writes | `$FFEE`-`$FFF3` (work space) |

### `CellTop` (`$B096`)

**C = max(C, the ground and the object on cell DE)**

TerrainTop, then falls into ObjectTop: the highest point of a cell, used for the 2x2 footprint in CheckShipMove.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 9,480 calls, 161,160 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 168 calls, 2,856 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 24 calls, 408 t-states own (0.00 %) |
| Called from | `CheckShipMove` |
| Calls | `TerrainTop` |

### `ObjectTop` (`$B099`)

**C = max(C, the top of a robot or a building anchored at cell DE)**

When the cell has bit 6 (an object anchored there): a robot (FindRobot) counts with its body height +`$09` plus the ground under it +`$0D`; else a building (FindBuilding) with its height from BuildingTops by type. A cell with bit 6 that is neither (a shot) counts nothing. B and C are kept.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 11,850 calls, 697,738 t-states own (0.03 %) |
| Runs (`work/game-r2`, save and load) | 210 calls, 11,718 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 30 calls, 1,674 t-states own (0.00 %) |
| Called from | `CheckShipMove` |
| Calls | `KeepHigher`, `FindRobot`, `FindBuilding`, `AddAToHL` |
| Reads | `$B0C1`-`$B0C8` (`BuildingTops`); `$DA09`-`$DA5D` (`Robots`); `$E513`-`$E517` (`Map`); `$E712`-`$E919` (`Map`); `$EB11`-`$EB19` (`Map`); `$ED11`-`$F319` (`Map`); 6 more ranges |

### `KeepHigher` (`$B0AB`)

**C = max(C, A)**

The common tail of TerrainTop and ObjectTop.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 41,554 calls, 1,039,970 t-states own (0.04 %) |
| Called from | `TerrainTop` (tail), `ObjectTop` |
| Writes | `$FFEE`-`$FFEF` (work space) |

## world

`src/game/world.asm`

### `WorldTurn` (`$B0CA`)

**one game turn of the world: the enemy commander, every robot, every shot**

First EnemyCommander (one enemy slot built or re-ordered), then UpdateRobot for each of the 48 robot records `$DA00` whose +`$01` is not 0, then UpdateShot for each of the 5 shot records of 9 bytes at `$D7D3` whose +`$01` is not 0. Robots and shots are taken in slot order, the player's slots 0-23 first. Shot record 0 (`$D7D3`) is the one the player fires from the robot menu's БОЕВОИ РЕЖИМ (combat mode) (DirectControl -> FireShot); the robots use records 1-4 (FindFreeShot).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,416 calls, 17,224,780 t-states own (0.67 %) |
| Runs (`work/game-r2`, save and load) | 184 calls, 912,053 t-states own (0.21 %) |
| Runs (`work/game`, the first game) | 298 calls, 1,474,802 t-states own (0.50 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu` |
| Calls | `UpdateRobot`, `UpdateShot`, `EnemyCommander` |
| Reads | `$D7D4`-`$D7F8` (`Shots`); `$DA01`-`$DCF1` (`Robots`, `EnemyRobots`) |
| Writes | `$FFF2`-`$FFFD` (work space) |

### `UpdateRobot` (`$B0FA`)

**one robot's game turn: dying, destroyed or a step of its AI**

IY = the robot record.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 52,106 calls, 11,983,286 t-states own (0.46 %) |
| Runs (`work/game-r2`, save and load) | 557 calls, 22,280 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 596 calls, 23,840 t-states own (0.01 %) |
| Called from | `WorldTurn` |
| Calls | `RobotStep` (tail), `SteerByOrder`, `TurnOrStep`, `CountDirections`, `FreeDirections`, `SetStepDelay`, `SpotEnemies`, `FindFreeShot`, `FireShot`, `CountRobots`, `PutBlock`, `PlaceRobot` (tail), `UpdateStatusPanel`, `Random`, `ToggleRadarDot` |
| Reads | `$DA00`-`$DA5F` (`Robots`); `$DA7C` (`Robots`); `$DB80`-`$DC4F` (`EnemyRobots`); `$DC70`-`$DC8F` (`EnemyRobots`); `$DCA0`-`$DCBF` (`EnemyRobots`); 6 more ranges |
| Writes | `$DA01`-`$DA5F` (`Robots`); `$DB81`-`$DC4F` (`EnemyRobots`); `$DC75`-`$DC8F` (`EnemyRobots`); `$DCA5`-`$DCBF` (`EnemyRobots`); `$DCD1`-`$DCFF` (`EnemyRobots`); `$DF3D`-`$E0BA` (`Map`); 6 more ranges |

### `RobotStep` (`$B154`)

**a live robot: wait for its step delay, then look, fire, steer and move one step**

Entered from UpdateRobot with strength > 0 (JP P). A robot the player sits on (+`$0A` = 1, the robot menu is open) does nothing. Side (`$FD51`) = 0 ours / 1 the enemy's (+`$0A` bit 7), read by the target searches. The step delay +`$0F` counts the turns down; at 0 the robot leaves its cell (bit 6 cleared, radar dot erased) and FreeDirections gives C, the directions it can step to (bit 0 right, 1 left, 2 down, 3 up, the Input order).

Direct control (+`$0A` = 2): the stick decides (RobotDirectControl). Otherwise SpotEnemies gives E, the directions with a live opponent in sight. An opponent ahead (E AND the facing +`$08`): the robot moves on if it can and fires when a shot record of its side is free and its weapons allow (FindFreeShot, FireShot; a shot stops it for this step). An opponent to a side: it turns to it (+`$05` = that direction, one picked at random among several, +`$06` = 2). No opponent: it keeps its direction +`$05` for +`$06` more steps while that direction stays free, else it takes a new course for 3-6 steps from SteerByOrder (RobotNewCourse). RobotMove then turns or steps, reloads the delay (SetStepDelay) and puts the robot back on the map (PlaceRobot: the record's x/y/cell, bit 6, the dot).

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 557 calls, 138,987 t-states own (0.03 %) |
| Runs (`work/game`, the first game) | 596 calls, 105,609 t-states own (0.04 %) |
| Called from | `UpdateRobot` (tail) |
| Calls | `SteerByOrder`, `TurnOrStep`, `CountDirections`, `FreeDirections`, `SetStepDelay`, `SpotEnemies`, `PlaceRobot` (tail), `Random`, `ToggleRadarDot` |
| Reads | `$DA00`-`$DA5F` (`Robots`); `$DA70`-`$DA7F` (`Robots`); `$DB80`-`$DB8F` (`EnemyRobots`); `$DC40`-`$DC4F` (`EnemyRobots`); `$DCB0`-`$DCBF` (`EnemyRobots`); 13 more ranges |
| Writes | `$DA05`-`$DA5F` (`Robots`); `$DA75`-`$DA7F` (`Robots`); `$DB85`-`$DB8F` (`EnemyRobots`); `$DC45`-`$DC4F` (`EnemyRobots`); `$DCB5`-`$DCBF` (`EnemyRobots`); `$E3F1` (`Map`); 14 more ranges |

### `SteerByOrder` (`$B222`)

**C = the direction the robot's order wants, chosen among the free ones in C**

IY the robot, C the free directions (FreeDirections); out C a single direction bit, or 0 to stand. B keeps the free set. By the order +`$0B`:

0 stop: C = 0. 1 advance / 2 retreat: right / left (RobotLeanTo, a 3/4 chance to take that direction when free, else a random free one other than the opposite); RobotStepPos counts the distance +`$0E`.

3 destroy robots: the target is the opponent robot of index +`$0E` (TargetRobotRecord). It is kept while it lives and is less than 50 columns away; else the nearest live opponent by column distance is taken (FindNearestOpponent), none: a random free direction.

4-8 the building orders: the target is record +`$0E` of the factory table `$FD84` or the warbase table `$FD70` (TargetBuildingTable). It is kept while its owner bits are still the ones the order looks for; else the nearest such building nobody of the side is already after is taken (FindTargetBuilding). None: the robot stands, and an enemy robot falls back to destroy robots.

The aim (RobotAim): D = the directions toward the target, horizontal from the sign of the column difference, vertical from the row difference; for a building, while the columns differ, the row aimed at is 3 below the building's row. More than 7 columns away the robot leans horizontally like an advance (RobotLeanTo); closer, one of the free wanted directions at random, a horizontal one kept for |dx| - 1 steps (+`$06`). On the target (D = 0): the destroy orders 4-5 go to the nuclear charge at NuclearBlast (outside this range); the others turn the robot to face down and stand.

FindTargetBuilding leaves HL past the table, not on the new target, so the step right after a new building target aims at the three bytes below `$FE00` (`$FDFD-$FDFF`, past the work space, never written by the game and zero in play: row 0, column 0): one step of a wrong course, corrected on the next decision.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 2,400 calls, 1,427,969 t-states own (0.06 %) |
| Runs (`work/game-r2`, save and load) | 107 calls, 34,025 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 40 calls, 11,898 t-states own (0.00 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `FindTargetBuilding`, `ColumnDistance`, `TargetBuildingTable`, `TargetRobotRecord`, `FindNearestOpponent`, `CountDirections`, `AddAToHL`, `Random` |
| Reads | `$DA01`-`$DA5E` (`Robots`); `$DA72`-`$DA7E` (`Robots`); `$DB81`-`$DC4E` (`EnemyRobots`); `$DC72`-`$DC8E` (`EnemyRobots`); `$DCA2`-`$DCBE` (`EnemyRobots`); 3 more ranges |
| Writes | `$DA06`-`$DA4E` (`Robots`); `$DB86`-`$DBBE` (`EnemyRobots`); `$DBD6`-`$DBDE` (`EnemyRobots`); `$DC06`-`$DC4E` (`EnemyRobots`); `$DC86`-`$DC8E` (`EnemyRobots`); `$DCAE`-`$DCBE` (`EnemyRobots`); 2 more ranges |

### `PickOneDirection` (`$B33E`)

**C = one direction bit picked at random from the set in B**

Masks C with random bytes until exactly one bit is left (CountDirections); when nothing is left it starts again from B. B must not be 0. The common exit of SteerByOrder's branches and used by RobotTurnToEnemy for several opponents.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FindTargetBuilding` (`$B34D`)

**D = the nearest building the order wants and no teammate is after; Z when none**

A = the order (3 goes to FindNearestOpponent), HL = the robot's column, IY the robot, Side set. The order picks the table and owner (TargetBuildingTable); every record with those owner bits is offered to ConsiderBuilding, which skips it when a robot of our side with the same order already has it as its +`$0E`, and keeps the nearest by column distance (KeepNearest). Out D = the record's index (or `$FF`), A = D + 1 (Z: none). HL is left past the table: the cause of the bug noted at SteerByOrder.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 120 calls, 127,591 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 63 calls, 95,580 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 3 calls, 3,730 t-states own (0.00 %) |
| Called from | `SetOrder`, `SteerByOrder`, `EnemyCommander` |
| Calls | `ConsiderBuilding`, `TargetBuildingTable`, `InitNearestSearch`, `FindNearestOpponent` (tail) |
| Reads | `$FD73`-`$FDFA` (`Warbases`, `Factories`) |
| Writes | `$FFF0`-`$FFF9` (work space) |

### `ConsiderBuilding` (`$B36C`)

**offer building C to KeepNearest unless a teammate with the same order already targets it**

HL = the record's owner byte (+`$03`), C its index, A' the order. Scans the 24 records of our side (`$DA00` ours, `$DB80` the enemy's by Side) for a live robot whose order +`$0B` is A' and whose target +`$0E` is C. None: the record's column (+`$00`/+`$01`) goes to KeepNearest. The robot that asks is in the list too; its +`$0E` holds its old target (or `$FF`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 887 calls, 2,115,016 t-states own (0.08 %) |
| Runs (`work/game-r2`, save and load) | 62 calls, 83,456 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 49 calls, 125,426 t-states own (0.04 %) |
| Called from | `FindTargetBuilding` |
| Calls | `KeepNearest` |
| Reads | `$DA01`-`$DCFE` (`Robots`, `EnemyRobots`); `$FD51` (`Side`); `$FD70`-`$FD71` (`Warbases`); `$FD84`-`$FDF8` (`Factories`) |
| Writes | `$FFE6`-`$FFF3` (work space) |

### `KeepNearest` (`$B3B3`)

**keep candidate C when the column HL is nearer to DE' than the best BC'**

The comparison step of the nearest searches (InitNearestSearch sets it up): HL' = |HL - DE'|, and when it is below BC' it becomes the best and D = C. Only the column distance counts; rows are ignored. A and HL' are lost; the main BC, E, HL and IY are kept. Called by ConsiderBuilding and FindNearestOpponent.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,779 calls, 363,922 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 25 calls, 2,507 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 49 calls, 4,926 t-states own (0.00 %) |
| Called from | `ConsiderBuilding`, `FindNearestOpponent` |
| Calls | `ColumnDistance` |
| Writes | `$FFEC`-`$FFED` (work space) |

### `ColumnDistance` (`$B3CA`)

**HL = |HL - DE|**

HL, DE two columns (0-511). A 16-bit absolute difference: SBC HL,DE and, when the result's sign is set, 0 - HL. DE is kept; A = 0 on the positive path, the high byte's negation on the other. Used by KeepNearest and by SteerByOrder's 50-column test of a robot target.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 4,420 calls, 213,954 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 25 calls, 1,101 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 49 calls, 2,145 t-states own (0.00 %) |
| Called from | `SteerByOrder`, `KeepNearest` |
| Writes | `$FFEC`-`$FFF5` (work space) |

### `TargetBuildingTable` (`$B3D5`)

**HL, B, E = the building table, its size and the owner a building order wants**

A = the order. Orders 5 and 8 (destroy / capture warbases): HL = `$FD73`, the owner byte of the first of the 4 warbase records (Warbases `$FD70`, 5 bytes each), B = 4; the others: HL = `$FD87`, the owner byte of the first of 24 factory records (Factories `$FD84`), B = 24. E = the owner bits sought: `$20` (the computer's) for our robots, `$40` (ours) for the enemy's (Side = 1), 0 (neutral) for order 6, capture neutral factories.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,764 calls, 239,482 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 20,396 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 25 calls, 3,482 t-states own (0.00 %) |
| Called from | `SteerByOrder`, `FindTargetBuilding`, `EnemyCommander` |
| Reads | `$FD51` (`Side`) |
| Writes | `$FFEC`-`$FFF5` (work space) |

### `TargetRobotRecord` (`$B3F9`)

**HL = the opponent robot record of index +`$0E`**

HL = `$DB80` + 16 * (+`$0E`) for our robots, `$DA00` + 16 * (+`$0E`) for the enemy's (Side). Used by SteerByOrder's destroy-robots branch.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,352 calls, 154,525 t-states own (0.01 %) |
| Called from | `SteerByOrder` |
| Reads | `$DA2E`-`$DA4E` (`Robots`); `$DB8E`-`$DB9E` (`EnemyRobots`); `$DBDE` (`EnemyRobots`); `$DC0E`-`$DC2E` (`EnemyRobots`); `$DC4E` (`EnemyRobots`); 4 more ranges |
| Writes | `$FFF4`-`$FFF5` (work space) |

### `InitNearestSearch` (`$B411`)

**start a nearest-by-column search from column HL**

DE' = HL (our column), BC' = `$2000` (no candidate yet), C = 0 (the first index), D = `$FF` (the result: none). Used by FindTargetBuilding and FindNearestOpponent with KeepNearest.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 641 calls, 40,383 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 66 calls, 4,158 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 3 calls, 189 t-states own (0.00 %) |
| Called from | `FindTargetBuilding`, `FindNearestOpponent` |

### `FindNearestOpponent` (`$B41D`)

**D = the index of the nearest live opponent robot by column; Z when none**

HL = our column, IY the robot, Side set. Runs KeepNearest over the 24 opponent records (`$DB80` the enemy's for us, `$DA00` ours for the enemy) whose +`$01` is not 0 (a dying robot counts). Out D = the slot within the side (or `$FF`), A = D + 1 (Z: none); IY is kept, B ends 0 and C 24 (the callers keep BC), DE' / BC' / HL' are the search's.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 524 calls, 1,445,113 t-states own (0.06 %) |
| Runs (`work/game-r2`, save and load) | 3 calls, 7,410 t-states own (0.00 %) |
| Called from | `SteerByOrder`, `FindTargetBuilding` (tail) |
| Calls | `KeepNearest`, `InitNearestSearch` |
| Reads | `$DA01`-`$DCF3` (`Robots`, `EnemyRobots`); `$FD51` (`Side`) |
| Writes | `$FFEE`-`$FFF1` (work space) |

### `RobotDirectControl` (`$B450`)

**direct control: the stick steers the robot**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TurnOrStep` (`$B471`)

**turn the robot toward direction A, or step one cell when it faces it**

IY the robot, HL its column, B its row, A a direction bit (0: nothing). Facing +`$08` not A: the robot turns, never by 180 degrees in one go (right <-> left goes through down / up, down <-> up through right / left), and +`$06` is incremented so the turn does not shorten the course. Facing A: StepPosition moves HL/B, GroundUnderFootprint sets +`$0D`, and under direct control (+`$0A` = 2) MoveShip moves the ship by the same Input and the ship sits on the robot's top (Altitude = +`$09` + +`$0D`).

(direct control) on a new bipod + cannon robot at (22,14)): holding right the robot turned from facing down (4) to right (1) in one step and moved one column a step (6 turns, about 60 frames); after the release it went on one more step in the same direction; the ship moved with it and Altitude stayed 17 (bipod 11 + cannon 6, ground 0).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,304 calls, 1,257,772 t-states own (0.05 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 6,858 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 101 calls, 10,378 t-states own (0.00 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `StepPosition`, `GroundUnderFootprint` |
| Reads | `$DA06`-`$DA5A` (`Robots`); `$DB86`-`$DC4A` (`EnemyRobots`); `$DC76`-`$DC8A` (`EnemyRobots`); `$DCA6`-`$DCBA` (`EnemyRobots`); `$DCD6`-`$DCFA` (`EnemyRobots`) |
| Writes | `$DA06`-`$DA5D` (`Robots`); `$DB86`-`$DC4D` (`EnemyRobots`); `$DC76`-`$DC8D` (`EnemyRobots`); `$DCA6`-`$DCBD` (`EnemyRobots`); `$DCD6`-`$DCFD` (`EnemyRobots`); `$FFF6`-`$FFF7` (work space) |

### `StepPosition` (`$B4B9`)

**move HL (column) / B (row) one cell in direction A; advance / retreat count their distance**

A bit 0 right (HL+1), 1 left (HL-1), 2 down (B+1), 3 up (B-1). For the orders 1 advance and 2 retreat (not under direct control) +`$0E` is the distance still to go: a column in the order's direction (right for advance, left for retreat) takes one off and at 0 the order becomes 0 stop (+`$06` = 0); a column the other way adds one, up to `$63`.

ADVANCE with 5 MILES (the robot menu stores miles * 2 into +`$0E` = 10): the robot went 4 columns right (+`$0E` 10 -> 6), 5 rows up round an obstacle (+`$0E` unchanged), 6 more columns right and then stood with order 0 and +`$0E` = 0.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7,579 calls, 555,756 t-states own (0.02 %) |
| Runs (`work/game-r2`, save and load) | 31 calls, 2,201 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 63 calls, 4,718 t-states own (0.00 %) |
| Called from | `TurnOrStep` |
| Reads | `$DA0B`-`$DA5B` (`Robots`); `$DB8B`-`$DBDB` (`EnemyRobots`); `$DBFB`-`$DC4B` (`EnemyRobots`); `$DC7B`-`$DC8B` (`EnemyRobots`); `$DCAB`-`$DCBB` (`EnemyRobots`); 1 more ranges |
| Writes | `$FFF4`-`$FFF5` (work space) |

### `CountDirections` (`$B505`)

**flags of (the number of set bits in C's low nibble) - 1**

Z: exactly one direction; carry: none; neither: two or more. Counts bits 0-3 of C, keeps BC.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 5,009 calls, 781,499 t-states own (0.03 %) |
| Runs (`work/game-r2`, save and load) | 157 calls, 24,492 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 93 calls, 14,508 t-states own (0.00 %) |
| Called from | `UpdateRobot`, `RobotStep`, `SteerByOrder`, `EnemyCommander` |
| Writes | `$FFF2`-`$FFF5` (work space) |

### `FreeDirections` (`$B513`)

**C = the directions the robot at cell HL may step to**

IY the robot, HL its anchor cell. A robot covers 2x2 cells: its anchor (X, Y) carries the object bit 6, plus (X+1, Y), (X, Y-1), (X+1, Y-1). D = the first terrain type it cannot enter, by its locomotion: bipod 8 (types 0-7, ground heights 0-3), tracks `$0C` (also 8-`$0B`, height 6), anti-grav `$0F` (also `$0C-$0E`, height 0 in TerrainHeights); the types from `$0F` (heights 7 and 15) stop all. E = the bits that block: 6 (objects) always, 7 (the ship's cell) when the ship hangs lower than the robot's top.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,304 calls, 3,584,980 t-states own (0.14 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 54,456 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 101 calls, 34,154 t-states own (0.01 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `CanMoveRight`, `CanMoveLeft`, `CanMoveDown`, `CanMoveUp` |
| Reads | `$DA07`-`$DA5D` (`Robots`); `$DA77`-`$DA7D` (`Robots`); `$DB87`-`$DC4D` (`EnemyRobots`); `$DC77`-`$DC8D` (`EnemyRobots`); `$DCA7`-`$DCBD` (`EnemyRobots`); 2 more ranges |
| Writes | `$FFEE`-`$FFF7` (work space) |

### `CanMoveRight` (`$B557`)

**Z when the robot at HL can step right**

Terrain and objects at the column it enters, (X+2, Y-1) and (X+2, Y); an object anchored at (X+2, Y+1) (its footprint would overlap) when that row exists.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,304 calls, 1,073,516 t-states own (0.04 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 10,784 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 101 calls, 10,872 t-states own (0.00 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `TestCell` |
| Reads | `$E145`-`$E14C` (`Map`); `$E16A`-`$E2BB` (`Map`); `$E33C`-`$E345` (`Map`); `$E36A`-`$E4BA` (`Map`); `$E53B`-`$E547` (`Map`); 3 more ranges |
| Writes | `$FFF2`-`$FFF3` (work space) |

### `CanMoveLeft` (`$B56F`)

**Z when the robot at HL can step left**

Terrain and objects at (X-1, Y-1) and (X-1, Y); objects anchored at (X-2, Y-1), (X-2, Y) and (X-2, Y+1).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,304 calls, 1,399,356 t-states own (0.05 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 12,248 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 101 calls, 13,488 t-states own (0.00 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `TestCell` |
| Reads | `$DD3B`-`$DD49` (`Map`); `$DD66`-`$DE64` (`Map`); `$DEA8`-`$DEB8` (`Map`); `$DF38`-`$DF49` (`Map`); `$DF66`-`$E0B8` (`Map`); 1 more ranges |
| Writes | `$FFF2`-`$FFF3` (work space) |

### `CanMoveDown` (`$B58F`)

**Z when the robot at HL can step down**

Blocked at the bottom row; terrain and objects at (X, Y+1) and (X+1, Y+1); objects anchored at (X+1, Y+2), (X, Y+2) and (X-1, Y+2) when that row exists.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,304 calls, 1,399,389 t-states own (0.05 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 24,582 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 101 calls, 14,843 t-states own (0.00 %) |
| Called from | `FreeDirections` |
| Calls | `CellOffMapFree` (tail), `CellBlocked` (tail), `TestCell` |
| Reads | `$E33C`-`$E3EE` (`Map`); `$E422`-`$E4BB` (`Map`); `$E539`-`$E5EE` (`Map`); `$E622`-`$E6BB` (`Map`); `$E734`-`$FCEF` (`Map`) |
| Writes | `$FFF0`-`$FFF3` (work space) |

### `CanMoveUp` (`$B5B1`)

**Z when the robot at HL can step up**

Blocked when Y-2 is above the map (the footprint already covers Y-1); an object anchored at (X-1, Y-2), terrain and objects at (X, Y-2) and (X+1, Y-2).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,304 calls, 1,110,563 t-states own (0.04 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 15,336 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 101 calls, 11,493 t-states own (0.00 %) |
| Called from | `FreeDirections` |
| Calls | `CellBlocked` (tail), `TestCell` |
| Reads | `$DD39`-`$DDEC` (`Map`); `$DE22`-`$DE65` (`Map`); `$DEA3`-`$DEB9` (`Map`); `$DF34`-`$E183` (`Map`); `$E194`-`$F8ED` (`Map`) |
| Writes | `$FFF2`-`$FFF3` (work space) |

### `CellOffMapFree` (`$B5C8`)

**Z: a probe that runs past the bottom row finds the way free**

The shared exit of the probes for rows below the map.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 2,653 calls, 37,180 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 17 calls, 238 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 28 calls, 392 t-states own (0.00 %) |
| Called from | `CanMoveRight` (tail), `CanMoveLeft` (tail), `CanMoveDown` (tail) |

### `CellBlocked` (`$B5CA`)

**NZ: the way is blocked**

The shared exit for an unpassable terrain type or a map edge.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 8,765 calls, 149,043 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 331 calls, 5,627 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 62 calls, 1,054 t-states own (0.00 %) |
| Called from | `CanMoveDown` (tail), `CanMoveUp` (tail), `TestCell` (tail) |
| Writes | `$FFF2`-`$FFF3` (work space) |

### `TestCell` (`$B5CD`)

**Z when cell HL is passable: type below D and none of the bits E**

HL a map cell, D the first terrain type the locomotion cannot enter (FreeDirections), E the blocking bits (`$40` objects, plus `$80` the ship's cell when the ship hangs lower than the robot's top). NZ through CellBlocked when the type (bits 0-4) is D or more; else A = the cell AND E (Z: free). HL kept.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 72,154 calls, 3,208,104 t-states own (0.12 %) |
| Runs (`work/game-r2`, save and load) | 910 calls, 36,695 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 732 calls, 32,904 t-states own (0.01 %) |
| Called from | `CanMoveRight`, `CanMoveLeft`, `CanMoveDown`, `CanMoveUp` |
| Calls | `CellBlocked` (tail) |
| Reads | `$DD3A`-`$DEBC` (`Map`); `$DF35`-`$FCF0` (`Map`) |
| Writes | `$FFE8`-`$FFF1` (work space) |

### `GroundUnderFootprint` (`$B5D6`)

**A = the highest ground under the 2x2 footprint anchored at (HL, B)**

HL a column, B a row. TerrainTop over (X, Y), (X+1, Y), (X+1, Y-1), (X, Y-1), the highest kept in C; HL and BC are kept, DE is lost (the last cell). The robots' +`$0D` (the ground they stand on: SetStepDelay's row, the drawing height, the ship's seat under direct control) and the shots' wall test (MoveShot against +`$08` = `$0A`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7,931 calls, 1,395,989 t-states own (0.05 %) |
| Runs (`work/game-r2`, save and load) | 31 calls, 5,475 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 63 calls, 11,088 t-states own (0.00 %) |
| Called from | `TurnOrStep`, `MoveShot` |
| Calls | `TerrainTop`, `MapCell` |
| Writes | `$FFF0`-`$FFF1` (work space) |

### `SetStepDelay` (`$B5F3`)

**+`$0F` = the turns until the robot's next step, by the ground and its locomotion**

The ground class from +`$0D`: 0 flat, 1-3 low, 4 and more high; the column from the lowest set part bit of +`$07`: 0 bipod, 1 tracks, 2 anti-grav. StepDelays gives the turns. The recorded records agree (robot 0, a bipod on flat ground, counts 6 down).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,304 calls, 2,195,660 t-states own (0.09 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 35,496 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 101 calls, 19,796 t-states own (0.01 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `AddAToHL` |
| Reads | `$B61D`-`$B625` (`StepDelays`); `$DA07`-`$DA5D` (`Robots`); `$DA77`-`$DA7D` (`Robots`); `$DB87`-`$DC4D` (`EnemyRobots`); `$DC77`-`$DC8D` (`EnemyRobots`); 2 more ranges |
| Writes | `$DA0F`-`$DA5F` (`Robots`); `$DA7F` (`Robots`); `$DB8F`-`$DC4F` (`EnemyRobots`); `$DC7F`-`$DC8F` (`EnemyRobots`); `$DCAF`-`$DCBF` (`EnemyRobots`); `$DCDF`-`$DCFF` (`EnemyRobots`); 1 more ranges |

### `SpotEnemies` (`$B626`)

**E = the directions in which a live opponent robot is in sight**

IY the robot. For each direction (up, down, left, right:

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,304 calls, 6,666,876 t-states own (0.26 %) |
| Runs (`work/game-r2`, save and load) | 156 calls, 101,232 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 101 calls, 65,394 t-states own (0.02 %) |
| Called from | `UpdateRobot`, `RobotStep` |
| Calls | `ScanLane` |
| Reads | `$DA00`-`$DA58` (`Robots`); `$DA70`-`$DA78` (`Robots`); `$DB80`-`$DC48` (`EnemyRobots`); `$DC70`-`$DC88` (`EnemyRobots`); `$DCA0`-`$DCB8` (`EnemyRobots`); 1 more ranges |
| Writes | `$FFEC`-`$FFF5` (work space) |

### `ScanLane` (`$B66E`)

**set E bit 0 when a live opponent's anchor lies within B cells from HL in direction D**

The step comes from LaneSteps by D's bit. The scan stops at the map's top or bottom edge and at the first cell with an object (bit 6): only a robot of the other side (+`$0A` bit 7 differs) with strength above 0 sets the bit. Buildings, shots and friends block the view. HL, DE are kept apart from E's bit 0.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 61,824 calls, 44,050,255 t-states own (1.71 %) |
| Runs (`work/game-r2`, save and load) | 936 calls, 630,503 t-states own (0.15 %) |
| Runs (`work/game`, the first game) | 606 calls, 420,290 t-states own (0.14 %) |
| Called from | `SpotEnemies` |
| Calls | `FindRobot` |
| Reads | `$B6B0`-`$B6B7` (`LaneSteps`); `$DA0A`-`$DA5C` (`Robots`); `$DB8A`-`$DBBC` (`EnemyRobots`); `$DBDA`-`$DC4C` (`EnemyRobots`); `$DC7A`-`$DCBC` (`EnemyRobots`); 1 more ranges |
| Writes | `$FFE4`-`$FFEF` (work space) |

### `FindFreeShot` (`$B6B8`)

**IY = a free shot record of the shooter IX's side; Z when one is free**

Each side has two shot records of 9 bytes: ours `$D7DC` and `$D7E5`, the enemy's `$D7EE` and `$D7F7` (by IX +`$0A` bit 7). Z with IY on the first one whose +`$01` is 0; NZ when both fly.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 378 calls, 33,800 t-states own (0.00 %) |
| Called from | `UpdateRobot` |
| Reads | `$D7DD` (`Shots`); `$D7EF` (`Shots`); `$DA0A` (`Robots`); `$DA2A` (`Robots`); `$DA4A`-`$DA5A` (`Robots`); `$DB8A`-`$DB9A` (`EnemyRobots`); 3 more ranges |

### `FireShot` (`$B6D6`)

**launch shot IY of weapon A from robot IX in its facing direction**

Called by RobotStep and by БОЕВОИ РЕЖИМ (combat mode) in the robot menu (DirectControl, IX = IY = the robot, record 0). Shot record (9 bytes): +`$00`/+`$01` the map cell, +`$02`/+`$03` the column, +`$04` the row, +`$05` the direction, +`$06` the steps left, +`$07` the weapon (1 cannon, 2 missiles, 3 phasers), +`$08` the ground height that stops it (`$0A`). The range is 5 steps (7 for missiles), one more with electronics; each step goes 2 cells. The first step is taken at once (MoveShot), from the shooter's anchor: in RobotStep the shooter is already off the map (bit 6 cleared), so it cannot hit itself.

When the shot survives the first step SoundFx (`$FD53`) = 1, the firing sound; when it ends at once, MoveShot's sound (`$FC`, `$FA` or `$C8`) stays.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 294 calls, 80,667 t-states own (0.00 %) |
| Called from | `UpdateRobot` |
| Calls | `MoveShot` |
| Reads | `$D7DD` (`Shots`); `$D7EF` (`Shots`); `$DA02`-`$DA08` (`Robots`); `$DA22`-`$DA28` (`Robots`); `$DA42`-`$DA58` (`Robots`); `$DB82`-`$DB98` (`EnemyRobots`); 3 more ranges |
| Writes | `$D7E1`-`$D7F6` (`Shots`); `$FD53` (`SoundFx`) |

### `UpdateShot` (`$B70D`)

**one game turn of shot IY: off its cell, count its range, a step**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 58 calls, 8,294 t-states own (0.00 %) |
| Called from | `WorldTurn` |
| Calls | `MoveShot` |
| Reads | `$D7DC`-`$D7F4` (`Shots`); `$E963`-`$E969` (`Map`); `$ED77` (`Map`); `$EF75`-`$EF7B` (`Map`); `$F17B`-`$F17C` (`Map`); `$F37B` (`Map`); 2 more ranges |
| Writes | `$D7E2` (`Shots`); `$D7F4` (`Shots`); `$E963`-`$E969` (`Map`); `$ED77` (`Map`); `$EF75`-`$EF7B` (`Map`); `$F17B`-`$F17C` (`Map`); 3 more ranges |

### `MoveShot` (`$B724`)

**move shot IY 2 cells, then hit a wall, an object or fly on**

IY the shot record, HL its column, B its row. One step: 2 cells in +`$05`. Off the rows 0-15 (only tested for down / up; the columns are not range-checked), or ground of height +`$08` (`$0A`) or more under its 2x2 footprint (only the types `$10` / `$12`, height 15; heights up to 7 let it pass): gone (ShotGone, SoundFx `$FC`). The new position and cell go into +`$00`-+`$04`.

Then the 3x3 cells around the new cell are tested for an object (bit 6), row Y-1 and Y+1 only inside the map; none: the shot marks its own cell with bit 6 and flies on. An object that is a live robot (either side: friendly fire is possible) takes damage ((60 - its top) / 4) * (weapon + 1), the top being +`$09` + +`$0D`, so tall robots on high ground take less: strength 0 or below makes it `$FC` (dying, UpdateRobot) with SoundFx `$C8`, else SoundFx `$FA`. Any other object (a building, another shot, a dying robot) just ends the shot (SoundFx `$FC`). Either way the record is freed (+`$01` = 0, the other bytes stay).

The recorded hits agree: a missile (2) into a 19 high robot takes 10 * 3 = 30, a cannon shell 10 * 2 = 20. Entered from UpdateShot (falling through) and FireShot.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 352 calls, 116,022 t-states own (0.00 %) |
| Called from | `FireShot`, `UpdateShot` |
| Calls | `GroundUnderFootprint`, `MapCell`, `FindRobot` |
| Reads | `$D7E1`-`$D7F6` (`Shots`); `$DA09`-`$DA0D` (`Robots`); `$DA29`-`$DA2D` (`Robots`); `$DB89`-`$DB8D` (`EnemyRobots`); `$DBF9`-`$DC0D` (`EnemyRobots`); 11 more ranges |
| Writes | `$D7DC`-`$D7F2` (`Shots`); `$DA0C` (`Robots`); `$DA2C` (`Robots`); `$DB8C` (`EnemyRobots`); `$DBFC`-`$DC0C` (`EnemyRobots`); `$DC4C` (`EnemyRobots`); 10 more ranges |

### `ShotGone` (`$B7EA`)

**out of range or off the map: the shot is gone with the short sound**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## enemy

`src/game/enemy.asm`

### `EnemyCommander` (`$B7F4`)

**once a game turn the computer looks at one of its 24 robot slots: builds a robot in a free one or re-thinks a robot's order**

Called first by WorldTurn. A random number 0-31 picks the slot; 24-31 (a quarter of the turns) do nothing. Side = 1. The slot's record is `$DB80` + 16 * n.

A live robot goes to EnemyReplan: one with order 0 at once, any other with a 1/32 chance a turn, gets a new order (EnemyChooseOrder: a nuclear robot destroy factories or warbases, the others one of the capture orders; destroy robots when the order finds no target). Orders 4-8 are kept only while the target has changed owner and the robot stands on its door: the capture under way.

A free slot tries a build at a random enemy warbase (owner `$20` in the Warbases table) whose door and the three cells below it are free of bit 6: random parts (exactly one locomotion, at least one and not all four of the weapon / nuclear parts, at least 1, 2 or 3 of those parts while the computer has 0-7, 8-15 or 16-23 robots, EnemyRobotCount `$FD49`), paid from EnemyResources (`$FD4A`, through MenuResources and PartCosts like the player's), the shortfall of the other resources taken from the general one, at most half of it (at least 11). A refused design is not retried: the slot waits for another turn.

The robot is set up facing down, 3 steps, order 0, strength `$64`, +`$0A` = `$80`, +`$0E` = `$FF`, +`$0F` = 1, height +`$09` the sum of the part heights `$D7B4` (bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7); then CountRobots and UpdateStatusPanel. IY is left on the slot's record;

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,416 calls, 1,530,226 t-states own (0.06 %) |
| Runs (`work/game-r2`, save and load) | 184 calls, 102,655 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 298 calls, 178,053 t-states own (0.06 %) |
| Called from | `WorldTurn` |
| Calls | `FindTargetBuilding`, `TargetBuildingTable`, `CountDirections`, `CountRobots`, `PlaceRobot`, `MapCell`, `UpdateStatusPanel`, `AddAToHL`, `Random` |
| Reads | `$CAF0`-`$CAFF` (`PartCosts`); `$D7B4`-`$D7BB` (`PartHeights`); `$DB81`-`$DCFB` (`EnemyRobots`); `$EE05` (`Map`); `$EE71` (`Map`); 9 more ranges |
| Writes | `$DB85`-`$DCFF` (`EnemyRobots`); `$FD29`-`$FD2F` (`MenuResources`); `$FD4A`-`$FD51` (`EnemyResources`, `Side`); `$FFF2`-`$FFF3` (work space) |

### `NuclearBlast` (`$B99F`)

**NuclearBlast**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NuclearFlash` (`$BA87`)

**The nuclear blast's flash: the view's paper flickers through random colours with a fading rumble**

Called only by the blast (`$BA76`). Saves the 20 x 20 attributes of the view (from `$5821`, row 1 column 1) to `$5B00-$5C8F`, then 61 times: a burst of noise (`$BAEE`, 244 samples first, 4 fewer and a longer delay each time) and a new random paper colour (2-7, never the previous one) on every attribute of the view whose paper is not black. Restores the saved attributes at the end.

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

Called after every change of owner (the capture tick `$AE17`), after the blast (`$BA81`), and by the map builder (`$BCCA`). A, B, DE, HL lost.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 18 calls, 65,809 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 2 calls, 7,140 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 3,460 t-states own (0.00 %) |
| Called from | `GameTurnEnd`, `BuildMap` |
| Calls | `AddAToHL` |
| Reads | `$FD3A`-`$FD48` (`PlayerBuildings`, `PlayerRobotCount`, `EnemyBuildings`); `$FD73`-`$FDFA` (`Warbases`, `Factories`) |
| Writes | `$FD3A`-`$FD48` (`PlayerBuildings`, `PlayerRobotCount`, `EnemyBuildings`); `$FFFA`-`$FFFB` (work space) |

### `CountRobots` (`$BB40`)

**PlayerRobots (`$FD41`) and EnemyRobots (`$FD49`): the live records of each side**

Counts the robot records whose +1 (the map cell's high byte) is not 0: slots 0-23 into PlayerRobots, slots 24-47 into EnemyRobots. The status panel shows them (the ROBOTS line); the enemy's factory (`$B86F`) builds better-armed robots as its count grows. Called after each birth and death of a robot.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 35 calls, 2,800 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 2 calls, 160 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 3 calls, 240 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `UpdateRobot`, `EnemyCommander` |
| Calls | `CountLiveRobots` |
| Writes | `$FD41`-`$FD49` (`PlayerRobotCount`, `EnemyBuildings`, `EnemyRobotCount`) |

### `CountLiveRobots` (`$BB50`)

**A = the live records among 24 robot records from HL (+1 not 0); HL moves past them**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 70 calls, 80,746 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 4 calls, 4,641 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 6 calls, 6,960 t-states own (0.00 %) |
| Called from | `CountRobots` |
| Reads | `$DA01`-`$DCF1` (`Robots`, `EnemyRobots`) |

### `GiveFactory` (`$BB61`)

**Factory A (0-23) changes hands: to the player (B = 0) or the enemy (B = 1); its flag moves**

Sets the factory's owner bits (`$BBB9`), removes the flag buildings at both sides of its roof (the cells x-2 and x+2 of row y-2) and puts the new owner's flag: type 7 (the player's) at x-2, type 8 (the enemy's) at x+2. The factory's own building (type 1-6 at x, y-2) stays.

Called by the capture tick (`$AE01`) when a robot has stood on the factory's door for 144 ticks.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 17 calls, 3,135 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 1 call, 171 t-states own (0.00 %) |
| Called from | `GameTurnEnd` |
| Calls | `SetBaseOwner`, `AddBuilding`, `RemoveBuilding` |

### `GiveWarbase` (`$BB86`)

**Warbase A (0-3) changes hands: to the player (B = 0) or the enemy (B = 1)**

Sets the owner bits (`$BBB9`) and rebuilds the warbase's buildings on its pad row y-4: removes those at x-4, x and x+4, then for the player puts the landing pad (type 0, x) and the player's flag (type 7, x-4); for the enemy only its flag (type 8, x+4). So a captured warbase gives the player a second pad where the construction menu opens.

Called by the map builder (`$BCB3-$BCC7`: warbase 0 the player's, 1-3 the enemy's) and by the capture tick (`$ADF9`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 4 calls, 666 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 4 calls, 666 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 4 calls, 666 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `SetBaseOwner`, `AddBuilding` (tail), `RemoveBuilding` |

### `SetBaseOwner` (`$BBB9`)

**Base record A (HL = the table's +3 bytes): owner = the player (B = 0) or the enemy; HL = its door cell**

HL is `$FD73` (warbases) or `$FD87` (factories). Replaces bits 5-7 of the base's +3 with `$40` (the player) or `$20` (the enemy), which also clears the destroyed bit 7. Falls into BaseCell: HL = the map cell of the base's (x, y), its door.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 21 calls, 3,051 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 5 calls, 727 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 4 calls, 581 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` |
| Calls | `MapCell` (tail), `AddAToHL` |
| Reads | `$FD70`-`$FDEB` (`Warbases`, `Factories`) |
| Writes | `$FD73`-`$FDEB` (`Warbases`, `Factories`) |

### `DestroyFactory` (`$BBD8`)

**Factory A (0-23) destroyed by a nuclear blast: buildings removed, blocks turned to debris**

Marks the factory destroyed (`$BC1C`), removes its three buildings on the roof row y-2 (the flags at x+2 and x-2 and the factory at x) and draws the factory's shape (ShapeFactory) again in debris: every block a random tile 6 or 7.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DestroyWarbase` (`$BBF9`)

**Warbase A (0-3) destroyed by a nuclear blast: buildings removed, blocks turned to debris**

Marks the warbase destroyed (`$BC1C`), removes the buildings at x-4, x and x+4 of its pad row y-4 and redraws ShapeWarbase in debris (tiles 6 / 7).

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
| Runs (`work/docL/deep`, the bot's game) | 46 calls, 55,924 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 30 calls, 25,263 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 29 calls, 23,199 t-states own (0.01 %) |
| Called from | `GiveFactory`, `GiveWarbase` (tail), `PlaceBases` |
| Reads | `$DF33`-`$E0D2` (`Map`); `$E3A0`-`$E675` (`Map`); `$E6F2`-`$E716` (`Map`); `$E837`-`$E893` (`Map`); `$EBE3` (`Map`); 4 more ranges |
| Writes | `$DF33`-`$E0D2` (`Map`); `$E3A0`-`$E675` (`Map`); `$E6F2`-`$E716` (`Map`); `$E837`-`$E893` (`Map`); `$EBE3` (`Map`); `$ED3C`-`$ED3E` (`Map`); 4 more ranges |

### `RemoveBuilding` (`$BC5D`)

**Remove the building on map cell HL, if any: its record freed, bit 6 of the cell cleared**

Keeps IY and BC. Uses FindBuilding.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 46 calls, 4,113 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 14 calls, 1,275 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 12 calls, 1,068 t-states own (0.00 %) |
| Called from | `GiveFactory`, `GiveWarbase` |
| Calls | `FindBuilding` |
| Reads | `$E4B6` (`Map`) |
| Writes | `$E4B6` (`Map`); `$FF7D` (`Buildings`) |

### `BuildMap` (`$BC6F`)

**A new game's map: clear it, place the scenery and the 28 bases, give the warbases their owners**

Called once by the new game set-up (`$A68B`). Clears the map `$DD00-$FCFF` and the radar bitmap `$D800-$D8FF`, places the scenery lists SceneryWest (columns 0-255) and SceneryEast (256-511), then the bases BaseListWest and BaseListEast (records into `$FD70`: 4 warbases, 24 factories, all neutral), gives warbase 0 to the player and warbases 1-3 to the enemy, counts the bases, marks the radar for a rebuild and puts the ship on the map (`$B024`).

The resulting map: the player's warbase at (22,9), the enemy's at (261,8), (369,8), (494,8); 24 factories, four of each type; read back from the live instance after a new game.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1 call, 177,825 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 1 call, 177,844 t-states own (0.04 %) |
| Runs (`work/game`, the first game) | 1 call, 177,825 t-states own (0.06 %) |
| Called from | `GameEntry`, `NewGameSetup` |
| Calls | `PutShipOnMap`, `CountBases`, `GiveWarbase`, `PlaceScenery`, `PlaceBases` |
| Reads | `$D800`-`$D8FE` (`RadarOwn`); `$DD00`-`$FCFE` (`Map`) |
| Writes | `$D800`-`$D8FF` (`RadarOwn`); `$DD00`-`$FCFF` (`Map`); `$FD52` (`RadarDirty`); `$FFFC`-`$FFFD` (work space) |

### `PlaceScenery` (`$BCD6`)

**Place a scenery list at HL (3-byte records: tile or shape, x low, y; 0 ends), D = x high byte**

A record with bit 7 clear is one 2 x 2 block of that tile (`$BD91`), with bit 7 set the shape of that index (`$BD61`). The cell is `$DD00` + `$200` * y + D * 256 + x.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 2 calls, 24,782 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 2 calls, 24,782 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 2 calls, 24,782 t-states own (0.01 %) |
| Called from | `BuildMap` |
| Calls | `DrawShape`, `PutBlock` |
| Reads | `$BDA9`-`$BF45` (`SceneryWest`, `SceneryEast`) |

### `PlaceBases` (`$BCF9`)

**Place a bases list at HL (3-byte records: type, x low, y; `$FF` ends), D = x high byte**

Type 0: a warbase. Its record goes to IX (the warbases' table) and ShapeWarbase is drawn from the cell. Type 1-6: a factory of that type. Its record goes to IY (the factories' table), ShapeFactory is drawn and the factory's building (that type) is added two rows up, at (x, y-2). A record: +0/+1 x, +2 y, +3 the type (the owner bits come later), +4 0 (the capture counter).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 2 calls, 11,020 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 2 calls, 11,020 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 2 calls, 11,020 t-states own (0.00 %) |
| Called from | `BuildMap` |
| Calls | `AddBuilding`, `DrawShape` |
| Reads | `$BF46`-`$BF9B` (`BaseListWest`, `BaseListEast`) |
| Writes | `$FD70`-`$FDFB` (`Warbases`, `Factories`) |

### `DrawShape` (`$BD61`)

**Draw shape A (bit 7 ignored, the index into ShapeTable) from map cell HL**

A shape is a list of 3-byte steps: a tile (0 = none) drawn as a 2 x 2 block at the current cell, then the move to the next cell: columns (signed), rows (signed); a move of (0,0) ends after its tile. DrawRuins (`$BC27`) walks the same lists with debris tiles.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 90 calls, 63,146 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 90 calls, 63,165 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 90 calls, 63,146 t-states own (0.02 %) |
| Called from | `PlaceScenery`, `PlaceBases` |
| Calls | `StepCell`, `PutBlock`, `TableWord` |
| Reads | `$BFB2`-`$C08C` (`ShapeWarbase`, `ShapeFactory`, `ShapeLowTiles`, `ShapeMidTiles` and 7 more) |

### `StepCell` (`$BD7F`)

**HL += C columns (signed) and B rows (signed: H += 2 * B); DE kept**

HL a map cell, C the columns (signed), B the rows (signed). HL += C sign-extended, then H += 2 * B (a map row is `$200` bytes). DE kept, A lost. The move of one shape step for DrawShape and DrawRuins.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 477 calls, 41,924 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 477 calls, 41,905 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 477 calls, 41,924 t-states own (0.01 %) |
| Called from | `DrawShape` |
| Writes | `$FFF0`-`$FFF1` (work space) |

### `PutBlock` (`$BD91`)

**A 2 x 2 block of tile A with its bottom left at map cell HL**

Writes the cells (x, y), (x+1, y), (x, y-1), (x+1, y-1): the first with the tile as it is, the other three with bit 5 set (the other parts of a block; the drawing and the blast take only the cell with bit 5 clear). Keeps HL and DE; BC is lost. Used by the map builder, the ruins, the blast and a dead robot's wreck (`$B133`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 621 calls, 198,156 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 614 calls, 195,942 t-states own (0.05 %) |
| Runs (`work/game`, the first game) | 614 calls, 195,923 t-states own (0.07 %) |
| Called from | `UpdateRobot`, `PlaceScenery`, `DrawShape` |
| Writes | `$DD0C`-`$F0DF` (`Map`); `$F0F7`-`$F2E1` (`Map`); `$F2F7`-`$F4E1` (`Map`); `$F4F7`-`$F8F8` (`Map`); `$F90C`-`$FAF8` (`Map`); `$FB0C`-`$FC92` (`Map`); 2 more ranges |

## mainmenu

`src/game/mainmenu.asm`

### `MainMenu` (`$C100`)

**The main menu: clear the screen, the title, the options; Z = start a new game, NZ = a game was loaded**

Called by Restart (`$A62A`), which falls into NewGameSetup with Z when it returns; a loaded game never returns here (LoadReturn goes on to NewGameSetup with NZ). Clears the screen, draws the menu picture (MenuPicture: bank 3's code) and the options 0-5; the current controls (Controls, `$D3E4`) show in cyan, the others in yellow (`$C336`). Then MainMenuKeys. Keys 1-3 choose the controls and redraw the options, 4 redefines the keys and redraws the whole menu, 5 loads a saved game, 0 starts.

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 3 calls, 153 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 51 t-states own (0.00 %) |
| Called from | `GameEntry`, `Restart` |
| Calls | `MenuPicture`, `ClearScreen`, `PrintInline` |

### `MainMenuTitle` (`$C103`)

**The main menu without the clearing: the picture, then the options**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MainMenuOptions` (`$C106`)

**The main menu's options (re-entered after keys 1-3)**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1 call, 17 t-states own (0.00 %) |
| Called from | `MenuOptionsEnd` (tail) |
| Calls | `PrintInline` |

### `MenuKeyboardOption` (`$C120`)

**Option 1, KEYBOARD, in the colour of Controls 1**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1 call, 41 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 3 calls, 123 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

### `MenuKempstonOption` (`$C137`)

**Option 2, KEMPSTON J/S, in the colour of Controls 2**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1 call, 41 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 3 calls, 123 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

### `MenuInterface2Option` (`$C151`)

**Option 3, INTERFACE 2, in the colour of Controls 3; then options 4 and 5**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1 call, 41 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 3 calls, 123 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 41 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ControlsOptionAttr`, `PrintInline` |

### `MenuOptionsEnd` (`$C18B`)

**The options' last step after their text: one frame, then MainMenuKeys**

PrintInline returns here past the 0 of MenuMoreText: a HALT and 6 NOPs (zero bytes where a longer text ended), on into MainMenuKeys.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1 call, 1,447,005 t-states own (0.06 %) |
| Runs (`work/game-r2`, save and load) | 3 calls, 186,411,046 t-states own (43.00 %) |
| Runs (`work/game`, the first game) | 1 call, 54,167,808 t-states own (18.22 %) |
| Called from | `PrintInline` |
| Calls | `GameLoad` (tail), `MainMenuOptions` (tail) |
| Reads | `$C18C` (`MenuOptionsEnd`); `$C1A2` (`MainMenuKeys`) |
| Writes | `$D3E4` (`Controls`); `$FFFC`-`$FFFD` (work space) |

### `MainMenuKeys` (`$C192`)

**The main menu's keys: wait for all keys up, then a key 0-5**

Waits until no key is held (KEY-SCAN `$028E`), then reads a key every frame (one HALT a pass; the tune plays from MusicInterrupt meanwhile) and takes its character from the ROM's key table (`$0205`): 0 returns Z, 1-3 set Controls and redraw the options, 4 RedefineKeys then the whole menu, 5 LoadGame. Any other key is ignored. The NOPs are 4 + 3 + 3 zero bytes where calls stood: the wait loops have nothing else to do.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintTitle` (`$C1E3`)

**Code nothing calls: 25 NOPs and a RET**

25 zero bytes and the RET, where a title print stood; the menu's title is in MenuPicture's picture.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadGame` (`$C1FD`)

**Key 5: load a saved game from the disk (GameLoad)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadTapePrompt` (`$C200`)

**Code nothing reaches: the PlayTapeText prompt, then on into LoadGameBlocks**

Left behind the JP of LoadGame. It prints its inline text and would fall into the tape load LoadGameBlocks.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadGameBlocks` (`$C21E`)

**Code nothing reaches: the tape load of a saved game, its checksum test gone**

The tape load, left in the image: red border, two headerless blocks (flag `$00`) through the ROM's LD-BYTES past its border set-up (`$0562`): 2 bytes to `$5B00`, then `$24D1` bytes to `$D92B-$FDFB`; then SaveChecksum, and 10 NOPs where the comparison with the loaded sum stood, so the load would count as good: the first 45 bytes back to Shots, the next 168 to Buildings, NZ. LoadGame jumps to the disk load instead; nothing comes here.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadBad` (`$C269`)

**Code nothing reaches: ОШИБКА ВВОДА (load error), its text inline, then LoadError**

The tape load's error branch; the test that jumped here is gone (LoadGameBlocks' NOPs).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadError` (`$C282`)

**Code nothing reaches: after the load error, a beep, a key, then Restart**

Beep with A = `$FA`, WaitAnyKey, then JP Restart. Reached only from LoadBad.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveGame` (`$C28D`)

**Code nothing reaches: the menu handler, the tape prompt, then SaveGameBlocks**

The tape save's start, left in the image: ImHandler = MusicInterrupt, the inline RecordText prompt at row 22, and on into SaveGameBlocks' key wait. PlayLoop's save key jumps past all of it to SaveGameStage.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveGameBlocks` (`$C2C9`)

**Save the game: a key (the unused part), the staging, then GameSave on the disk**

SaveGameBlocks itself (the key wait for the tape) is reached only from SaveGame, which nothing runs. PlayLoop's save key enters at SaveGameStage (`$C2CC`): RadarDirty = 1 (the staging overwrites the radar picture past RadarEnemy), the 45 bytes of Shots to SaveShots (`$D92B`) and the 168 of Buildings to SaveBuildings (`$D958`), so `$D92B-$FDFB` holds the whole game; interrupts off and JP GameSave, which comes back to PlayLoop's JP EnterPlay.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveGameStage` (`$C2CC`)

**SaveGameStage**

| | |
| --- | --- |
| Runs (`work/game-r2`, save and load) | 1 call, 4,547 t-states own (0.00 %) |
| Called from | `PlayLoop` (tail) |
| Calls | `GameSave` (tail) |
| Reads | `$D7D3`-`$D7FF` (`Shots`); `$FF01`-`$FFA8` (`Buildings`) |
| Writes | `$D92B`-`$D9FF` (`SaveShots`, `SaveBuildings`); `$FD52` (`RadarDirty`) |

### `SaveTapeBlocks` (`$C2F6`)

**Code nothing reaches: the rest of the old tape save, two ROM SA-BYTES calls**

XOR A; SCF; CALL `$04D0` (the first block, its set-up gone with the zero bytes before it), then `$24D1` bytes from SaveShots with flag `$00`, border black, EI. Nothing jumps here.

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

Reads all eight half rows at once (IN with A = 0: every address line A8-A15 low), bits 0-4 inverted: a key held. First waits for all keys up, then for any key down; returns with the key still held. No joystick, no debounce. Called only by dead code: SaveGameBlocks (start the tape) and LoadError.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ControlsOptionAttr` (`$C336`)

**The attribute for menu option C: cyan (`$45`) when it is the current Controls, else yellow (`$46`)**

C = the option's Controls value (1-3). Prints an inline attribute code: `$45` (cyan, bright) when Controls (`$D3E4`) is C, else `$46` (yellow, bright); the option text printed next takes it. Called by the three option entries before their text; A and the flags are lost.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3 calls, 128 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 9 calls, 384 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 3 calls, 128 t-states own (0.00 %) |
| Called from | `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option` |
| Calls | `PrintInline` |
| Reads | `$D3E4` (`Controls`) |

### `ControlsOptionPlain` (`$C342`)

**ControlsOptionAttr's return, the option not chosen**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 2 calls, 20 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 6 calls, 60 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 2 calls, 20 t-states own (0.00 %) |
| Called from | `PrintInline` |

### `ControlsOptionChosen` (`$C349`)

**ControlsOptionAttr's return, the option chosen**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1 call, 10 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 3 calls, 30 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 10 t-states own (0.00 %) |
| Called from | `PrintInline` |

### `RedefineKeys` (`$C34A`)

**Redefine the eight keys: UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE**

Key 4 of the main menu. Clears the screen, prints ЗАДАТЬ КЛАВ. (define keys), waits until no key is held, clears KeyTable and asks for each key in turn: PrintKeyPrompt prints "НАЖМ. КЛАВИШУ (press the key for) " and the name that follows the CALL, DefineKey waits for a key not yet taken and fills the KeyTable record whose third byte HL points at (the port's high byte, the bit mask, the key code) and prints the key. KeyTable's records 0-7 are PAUSE, ABORT, SAVE, FIRE, UP, DOWN, LEFT, RIGHT: Input bits 7 to 0. Waits for the last key's release and about 0.5 s, then back to the menu.

PAUSE with each key's letter, and the menu came back.

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

**"НАЖМ. КЛАВИШУ (press the key for) " and then the key's name that follows the caller's CALL**

Called by the redefine-keys screen (`$C37F`, `$C38E`, ... `$C3EB`) once for each of the eight keys, with the key's name (UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE) as an inline string after the CALL. It prints its own inline text (two new lines, attribute `$46`, "НАЖМ. КЛАВИШУ (press the key for) ", attribute `$45`), then jumps (not calls) to PrintInline at `$C424`: the return address on the stack is then the caller's, so PrintInline prints the caller's name string and returns past it. One prompt takes two screen rows.

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

### `KeySpaceDone` (`$C4A7`)

**The end of DefineKey's SPACE branch: RET after its name string**

The SPACE name is one letter longer than the room it had, so its 0 ends on `$C4A6` and its RET is this byte.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## construction

`src/game/construction.asm`

### `ConstructionMenu` (`$C849`)

**landing on the warbase pad at altitude 15: choose the parts (MenuCursor, MenuParts), ВЫПУСК (start the robot) or ВЫХОД (exit)**

Called by PlayLoop when the ship rests on the pad of our warbase (Altitude 15) and the door below is free. First looks for a free record among our slots 0-23 (`$DA00` + 16 x n, +`$01` = 0); with none it returns at once (IY = `$DB80`, enemy slot 24: the bug of PlayLoop's writes).

Otherwise IY = the free slot: the preview robot, and on ВЫПУСК (start the robot) the new one. ImHandler = MusicInterrupt (the tune plays), so neither the frame count nor the radar runs; the menu loop runs no game turns, so the world stands still while the menu is open. ClearScreen, then the eight part pictures in column 16 from the bottom (bipod) to the top (electronics), each the second facing of the part's sprite cut to 24 lines and drawn upwards by DrawMaskedUp; the preview's frame attributes (`$46`, 4 x 9 cells from row 15, column 0); the texts (title, part names, EXIT / START, costs, the resource labels). Falls into ConstructionMenuSetup.

Returns (after LeaveConstructionMenu) with IY = the slot; PlayLoop then writes the start state. On ВЫХОД (exit) the slot stays free (+`$01` = 0, PlaceRobot not called), so those writes do no harm.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7 calls, 28,307 t-states own (0.00 %) |
| Called from | `NewGameSetup` |
| Calls | `ClearScreen`, `DrawMaskedUp`, `TableWord`, `AddAToHL`, `PrintInline` |
| Reads | `$6A24`-`$6A25` (`SprTracksXOdd`); `$6D40`-`$6D41` (`SprBipodXOdd`); `$7058`-`$7059` (`SprAntiGravOdd`); `$7354`-`$7355` (`SprCannonXmOdd`); `$77F4`-`$77F5` (`SprMissilesXOdd`); `$7C96`-`$7C97` (`SprPhasersXmOdd`); 4 more ranges |
| Writes | `$59E0`-`$5A03` (screen); `$5A20`-`$5A23` (screen); `$5A40`-`$5A43` (screen); `$5A60`-`$5A63` (screen); `$5A80`-`$5A83` (screen); `$5AA0`-`$5AA3` (screen); 3 more ranges |

### `ConstructionMenuSetup` (`$C9E7`)

**reset the preview robot, copy the resources, cursor on BIPOD, nothing chosen**

Continues ConstructionMenu after its text. Resources are copied to MenuResources, which the menu spends; MenuCursor = column 2 (the parts), row 0 (bipod); MenuParts = 0; ShowRobotDesign paints the part pictures (white when chosen) and draws the preview robot; the cursor is painted.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7 calls, 2,177 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PaintMenuCursor`, `PrintMenuResources`, `ShowRobotDesign` |
| Reads | `$FD22`-`$FD28` (`Resources`) |
| Writes | `$DA08`-`$DA5D` (`Robots`); `$FD1F`-`$FD2F` (`MenuCursor`, `MenuParts`, `Resources`, `MenuResources`) |

### `ConstructionMenuLoop` (`$CA0F`)

**wait for a control; fire acts on the cursor's item, a direction moves the cursor**

WaitKey until one of Input bits 0-4. Without fire: MoveMenuCursor (`$CB00`). With fire: column 0 ВЫХОД (exit) (`$CB8E`), column 1 ВЫПУСК (start the robot) (`$CB52`), column 2 toggles the part under the cursor.

Choosing a part: a part already chosen is taken back (RefundPart) and cleared. A chassis (bipod, tracks, anti-grav: rows 0-2) replaces the chassis already chosen, which is refunded first. A fourth weapon is refused: of cannon, missiles, phasers and nuclear at most three (`$78` never all set). The cost is paid from the part's own resource (PartCosts + 8) and what it lacks from the general resource; if the general one cannot pay the rest the part is refused (a replaced chassis stays refunded: the robot is left without one). Accepted: beep `$64`; refused or taken back: beep `$78`. Then it waits for fire up and pauses 10 frames.

With 99 of everything: missiles, phasers, then nuclear refused (MenuParts `$38`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 64 calls, 250,028 t-states own (0.01 %) |
| Called from | `MenuPause` (tail) |
| Calls | `MoveMenuCursor` (tail), `MenuPause` (tail), `StartRobot` (tail), `PrintMenuResources`, `ShowRobotDesign`, `Beep`, `AddAToHL`, `WaitKey` |
| Reads | `$CAF0`-`$CAFF` (`PartCosts`); `$FD0C` (`Input`); `$FD1F`-`$FD2F` (`MenuCursor`, `MenuParts`, `Resources`, `MenuResources`) |
| Writes | `$FD21`-`$FD2F` (`MenuParts`, `Resources`, `MenuResources`); `$FFFC`-`$FFFD` (work space) |

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
| Runs (`work/docL/deep`, the bot's game) | 42 calls, 10,052 t-states own (0.00 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `PaintMenuCursor`, `Beep` |
| Reads | `$FD0C` (`Input`) |
| Writes | `$FD1F`-`$FD20` (`MenuCursor`) |

### `MenuPause` (`$CB4A`)

**10 frames, then back to ConstructionMenuLoop**

The pause after every press (moves too); a shorter press falls into it and is lost, WALKTHROUGH 6.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 22 calls, 42,679,064 t-states own (1.65 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `ConstructionMenuLoop` (tail) |
| Reads | `$CB4D` (`MenuPause`) |
| Writes | `$FFFC`-`$FFFD` (work space) |

### `StartRobot` (`$CB52`)

**ВЫПУСК (start the robot): needs a chassis and a weapon; spend the resources, place the robot at the warbase's door, leave**

Refused (back to the menu after the pause) without a chassis (MenuParts bits 0-2) or without a weapon (bits 3-6); electronics alone count as neither. Otherwise MenuResources become Resources, the free slot becomes a robot of ours (+`$0A` = 0) at column ShipX, row ShipY + 4 (PlaceRobot writes +0 to +4 and marks the map cell), +7 = MenuParts, and a rising chirp plays (Beep with `$50` down to `$14` by 5). Then LeaveConstructionMenu.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7 calls, 8,323 t-states own (0.00 %) |
| Called from | `ConstructionMenuLoop` (tail) |
| Calls | `PlaceRobot`, `Beep`, `ClearViewBuffer`, `DrawPlayScreen` |
| Reads | `$FD0D`-`$FD0F` (`ShipY`, `ShipX`); `$FD21`-`$FD2F` (`MenuParts`, `Resources`, `MenuResources`) |
| Writes | `$696A`-`$696B` (`ImHandler`); `$DA07`-`$DA5A` (`Robots`); `$FD22`-`$FD30` (`Resources`, `MenuResources`, `ClimbTurns`) |

### `PaintMenuCursor` (`$CBA9`)

**paint the item under MenuCursor with attribute C (`$46` the cursor, `$45` the rest)**

Column 0 / 1: two rows of 5 cells, ВЫХОД (exit) at rows 21-22 columns 4-8, ВЫПУСК (start the robot) columns 10-14. Column 2: the part's name, 11 cells from column 21 of row 22 - 3 * row (BIPOD row 22 up to ELECTRONICS row 1). Called by ConstructionMenuSetup and MoveMenuCursor.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 91 calls, 12,530 t-states own (0.00 %) |
| Called from | `ConstructionMenuSetup`, `MoveMenuCursor` |
| Calls | `FillAttributes` |
| Reads | `$FD1F`-`$FD20` (`MenuCursor`) |

### `FillAttributes` (`$CBDB`)

**write C into B bytes from HL**

Also used by PaintMenuItem.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 430 calls, 97,107 t-states own (0.00 %) |
| Called from | `PaintMenuItem`, `PaintMenuCursor` |
| Writes | `$5835`-`$583F` (screen); `$5895`-`$589F` (screen); `$58F5`-`$591E` (screen); `$5955`-`$59FE` (screen); `$5A15`-`$5A3E` (screen); `$5A75`-`$5AAE` (screen); 2 more ranges |

### `PrintMenuResources` (`$CBE0`)

**print MenuResources (two digits each) and their total**

The seven values at column 13: ОБЩИЕ (general) row 9, ЭЛЕКТРОНИКА-ШАССИ (electronics-chassis) rows 11-16 (PrintMenuResource, two digits: a value above 99 prints a wrong tens digit, e.g. 200 shows "D0"); the sum (HL) at row 18, column 12, three digits by PrintNumber3 (the tail `$CC03`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 29 calls, 20,387 t-states own (0.00 %) |
| Called from | `ConstructionMenuSetup`, `ConstructionMenuLoop` |
| Calls | `PrintMenuResource`, `AddAToHL`, `PrintInline` |
| Reads | `$FD29`-`$FD2F` (`MenuResources`) |

### `PrintMenuTotal` (`$CC03`)

**Construction menu: print the total of the costs (the tail of `$CBE0`)**

The tail of PrintMenuResources after the inline position (18,12):

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 29 calls, 493 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber3` (tail) |

### `PrintMenuResource` (`$CC08`)

**Construction menu: print one resource value A at row C, column 13**

Called by `$CBE0` for each of the seven MenuResources (rows 9, 11-16). Patches the row byte of the position string after the CALL (`$CC11`), prints the position, then PrintMenuResourceValue prints A as two digits.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 203 calls, 9,135 t-states own (0.00 %) |
| Called from | `PrintMenuResources` |
| Calls | `PrintInline` |
| Writes | `$CC11` (`MenuResourcePos`) |

### `PrintMenuResourceValue` (`$CC14`)

**Construction menu: print A as two digits, registers kept (the tail of `$CC08`)**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 203 calls, 20,300 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2` |

### `ShowRobotDesign` (`$CC1F`)

**Construction menu: highlight the chosen parts and draw the robot preview**

IY = the robot record being designed. Paints the attributes of the parts list (columns 16-19, three rows a part, 24 rows from the top): `$47` (bright white) for a part chosen in MenuParts, `$06` (yellow) otherwise, bit 7 (electronics) at the top. Then clears the view buffer, writes MenuParts to +`$07`, draws the robot stack into the buffer at map position row 10, column 7 (DrawRobot, base height +`$0D` = 0) and stores the stack's total height (the sum of the part heights `$D7B4`) in +`$09`: the height the ship lands on. Finally copies 4 bytes x 72 lines of the buffer from `$6168` (buffer row 82, column 0) to the screen at `$48E0` (character row 15, column 0). Called from `$C9E7` (7) and `$CA0F` (22) after each change of the parts.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 29 calls, 666,666 t-states own (0.03 %) |
| Called from | `ConstructionMenuSetup`, `ConstructionMenuLoop` |
| Calls | `DrawRobot`, `ClearViewBuffer`, `NextScreenLine`, `AddAToHL` |
| Reads | `$6168`-`$667F` (system); `$6690`-`$6693` (system); `$66A4`-`$66A7` (system); `$66B8`-`$66BB` (system); `$66CC`-`$66CF` (system); `$66E0`-`$66E3` (system); 4 more ranges |
| Writes | `$48E0`-`$54E3` (screen); `$5500`-`$55C3` (screen); `$55E0`-`$55E3` (screen); `$5600`-`$56C3` (screen); `$56E0`-`$56E3` (screen); `$5700`-`$57C3` (screen); 11 more ranges |

### `PlaceRobot` (`$CC7C`)

**Put robot IY at map column HL, row B: record, map bit 6, radar dot**

Writes +`$02`/+`$03` = HL (x), +`$04` = B (y), +`$00`/+`$01` = the map cell (MapCell) and sets the cell's bit 6 (an object to draw). Then toggles the robot's radar dot (ToggleRadarDot, side = bit 7 of +`$0A`: 0 the player's buffer `$D800`, 1 the enemy's `$D900`). The caller clears the old cell and toggles the old dot.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,332 calls, 2,221,722 t-states own (0.09 %) |
| Runs (`work/game-r2`, save and load) | 158 calls, 33,970 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 104 calls, 22,360 t-states own (0.01 %) |
| Called from | `UpdateRobot` (tail), `RobotStep` (tail), `EnemyCommander`, `StartRobot` |
| Calls | `MapCell`, `ToggleRadarDot` (tail) |
| Reads | `$DA04`-`$DA5A` (`Robots`); `$DA74`-`$DA7A` (`Robots`); `$DB84`-`$DC4A` (`EnemyRobots`); `$DC74`-`$DC8A` (`EnemyRobots`); `$DCA4`-`$DCBA` (`EnemyRobots`); 6 more ranges |
| Writes | `$DA00`-`$DA54` (`Robots`); `$DA70`-`$DA74` (`Robots`); `$DB80`-`$DC44` (`EnemyRobots`); `$DC70`-`$DC84` (`EnemyRobots`); `$DCA0`-`$DCB4` (`EnemyRobots`); `$DCD0`-`$DCF4` (`EnemyRobots`); 6 more ranges |

### `ShipCell` (`$CCA0`)

**HL = the map cell under the ship (ShipX, ShipY)**

Falls into MapCell. Used by `$A62D`, `$B01D` (clear the ship's bit 7) and `$B024` (set it).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 9,999 calls, 289,971 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 552 calls, 16,008 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 894 calls, 25,926 t-states own (0.01 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `LiftShipFromMap`, `PutShipOnMap` |
| Calls | `MapCell` |
| Reads | `$FD0D`-`$FD0F` (`ShipY`, `ShipX`) |

### `MapCell` (`$CCA6`)

**HL = the map cell of column HL, row A: `$DD00` + `$200`*A + HL**

H += 2*A + `$DD`.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 128,844 calls, 3,737,521 t-states own (0.14 %) |
| Runs (`work/game-r2`, save and load) | 6,057 calls, 175,672 t-states own (0.04 %) |
| Runs (`work/game`, the first game) | 9,548 calls, 276,892 t-states own (0.09 %) |
| Called from | `GameTurnEnd`, `CheckShipMove`, `GroundUnderFootprint`, `MoveShot`, `EnemyCommander`, `SetBaseOwner` (tail), `PlaceRobot`, `ShipCell`, `DrawCellObject` |
| Writes | `$FFEE`-`$FFF9` (work space) |

### `Beep` (`$CCAC`)

**Beeper tone: 256 half-periods, A = the half-period delay (bigger is lower)**

B = A is the DJNZ delay of each half-period, C = 0 counts 256 speaker toggles (bit 4 of port `$FE`, border black). BC is kept. Used for menu clicks and confirmations: ListMenu (83), `$CB52` (98), `$CB00` (42), `$CA0F` (22), the robot menu `$A7CD`, `$ABC8`.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 259 calls, 51,829,031 t-states own (2.01 %) |
| Called from | `ShowOrderMiles`, `SetOrder`, `ListMenu`, `ConstructionMenuLoop`, `MoveMenuCursor`, `StartRobot` |
| Writes | `$FFF4`-`$FFF9` (work space) |
| Ports out | `$00FE`, `$10FE` |

## view

`src/game/view.asm`

### `DrawView` (`$CCBD`)

**Draw the isometric view: background, objects, copy to the screen**

DrawViewBackground clears the buffer `$5B00` and paints the corners outside the map, DrawMapObjects draws every block, building, robot, shot and the ship, CopyViewToScreen puts the 160x160 buffer on the screen. About 578000 T-states a call, 8.3 frames: the reason a turn is 10 frames.

Called by PlayLoop, the menu loops that keep the game going (ListMenu's turn `$AD1F`, DirectControlLoop, DistanceLoop, CombatFireShot), the nuclear blast (`$BA6D`) and DrawPlayScreen. No HALT before the copy: the screen may tear for a frame.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,424 calls, 150,684 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 188 calls, 8,262 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 299 calls, 13,146 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu`, `DrawPlayScreen` |
| Calls | `DrawMapObjects`, `DrawViewBackground`, `CopyViewToScreen` (tail) |

### `DrawMapObjects` (`$CCC6`)

**Draw the 32 x 16 cells of the view back to front into the view buffer**

Clears the deferred ship position `$FD11` and draws the ship's shadow (sprite 1, height 0) at the ship's view column (ShipX - ViewX) and row ShipY. Then walks the visible part of the map along diagonals: the diagonal x - y = 31 first down to x - y = -15, each from row 0 (x, y) to (x+15, y+15) or the right edge; cells left of the view (x < 0) and cells that are 0 are skipped, every other cell goes to DrawCell with HL = the cell, D = row, E = view column. The order is the painter's order of the projection (DrawSprite): a later cell is nearer the viewer.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,424 calls, 225,329,603 t-states own (8.73 %) |
| Runs (`work/game-r2`, save and load) | 188 calls, 12,361,073 t-states own (2.85 %) |
| Runs (`work/game`, the first game) | 299 calls, 19,613,908 t-states own (6.60 %) |
| Called from | `DrawView` |
| Calls | `DrawCell`, `DrawSprite`, `AddAToHL` |
| Reads | `$DD00`-`$F122` (`Map`); `$F2DB`-`$F322` (`Map`); `$F4DB`-`$F522` (`Map`); `$F6DB`-`$F722` (`Map`); `$F8DB`-`$F922` (`Map`); 2 more ranges |
| Writes | `$CF3F` (`DrawSprite`); `$FD11`-`$FD12` (`ShipDrawPos`); `$FFEE`-`$FFFB` (work space) |

### `DrawCell` (`$CD18`)

**Draw map cell HL (A = its byte) at view row D, column E**

Cell bits: 0-4 the block type, 5 the right half of a two-cell block (nothing drawn), 6 an object (building, robot or shot, or a robot / shot deferred to this cell), 7 the ship, or the ship deferred to this cell. A block (bit 5 clear, type not 0) is drawn as sprite = type at height 0. Bit 7 handles the ship: on the first bit-7 cell (`$FD11` = 0, the ship's own cell, set by `$B024`) it looks for the cell drawn last among the neighbouring blocks (FindLatestBlock) and the neighbouring objects (CheckObjectNeighbour at (x-1,y-1), (x-1,y), (x-1,y+1), (x,y+1), (x+1,y+1)). If that is the ship's cell the ship is drawn at once, otherwise bit 7 is set on that later cell and the ship's view position is kept in `$FD11`; when the walk reaches it, bit 7 is cleared again and the ship (sprite 0) is drawn at the kept position, at height Altitude. So the ship is never painted over by a neighbour.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 375,954 calls, 53,969,921 t-states own (2.09 %) |
| Runs (`work/game-r2`, save and load) | 23,904 calls, 3,383,875 t-states own (0.78 %) |
| Runs (`work/game`, the first game) | 28,958 calls, 4,131,449 t-states own (1.39 %) |
| Called from | `DrawMapObjects` |
| Calls | `CheckObjectNeighbour`, `FindLatestBlock`, `DrawCellObject`, `DrawSprite` |
| Reads | `$DD0C`-`$EF22` (`Map`); `$F0DB`-`$F322` (`Map`); `$F4DC`-`$F522` (`Map`); `$F6DE`-`$F722` (`Map`); `$F8DE`-`$F922` (`Map`); 3 more ranges |
| Writes | `$CF3F` (`DrawSprite`); `$E914` (`Map`); `$EB16` (`Map`); `$ED14`-`$ED18` (`Map`); `$F716` (`Map`); `$F916`-`$F918` (`Map`); 3 more ranges |

### `CheckObjectNeighbour` (`$CD90`)

**Ship: an object at HL counts, and so do the blocks around it**

Used for the ship's neighbours: if HL has bit 6 (a robot, a building or a shot stands there, or one was deferred there) it competes (KeepLaterCell), and then the code falls into FindLatestBlock for the blocks around that object, because the ship flies above objects and their own neighbours can cover it too. In: HL the cell, DE the latest cell so far. Out: DE the latest. HL kept.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 17,120 calls, 394,252 t-states own (0.02 %) |
| Runs (`work/game-r2`, save and load) | 940 calls, 21,620 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1,490 calls, 34,270 t-states own (0.01 %) |
| Called from | `DrawCell` |
| Calls | `KeepLaterCell` |
| Reads | `$E513`-`$E515` (`Map`); `$E713`-`$E716` (`Map`); `$E911`-`$F319` (`Map`); `$F4ED`-`$F4EF` (`Map`); `$F515`-`$F519` (`Map`); 3 more ranges |
| Writes | `$FFEE`-`$FFEF` (work space) |

### `FindLatestBlock` (`$CD96`)

**DE = the cell drawn last among DE and the blocks next to HL**

Checks the blocks (bit 5 clear, type not 0) at (x-1,y+1), (x,y+1) (both only when y+1 < 16), (x-1,y) and (x+1,y+1) (y+1 < 16) of cell HL with CheckBlockNeighbour; (x+1,y) is passed over (HL only goes through it). Those are the cells whose sprites can overlap a robot, a shot or the ship standing at HL. HL is kept. Used by DrawCell (the ship) and DrawMover (robots, shots).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 4,772 calls, 868,337 t-states own (0.03 %) |
| Runs (`work/game-r2`, save and load) | 242 calls, 44,044 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 298 calls, 54,236 t-states own (0.02 %) |
| Called from | `DrawCell`, `DrawCellObject` |
| Calls | `CheckBlockNeighbour` |
| Writes | `$FFEC`-`$FFEF` (work space) |

### `CheckBlockNeighbour` (`$CDB8`)

**A block at HL competes for the latest cell**

Bit 5 set (the right half of a block) or type 0 (empty): nothing. Otherwise falls into KeepLaterCell.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 18,878 calls, 646,165 t-states own (0.03 %) |
| Runs (`work/game-r2`, save and load) | 968 calls, 40,656 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 1,192 calls, 50,064 t-states own (0.02 %) |
| Called from | `FindLatestBlock` |
| Calls | `KeepLaterCell` |
| Reads | `$E51B`-`$E51D` (`Map`); `$E713`-`$E71F` (`Map`); `$E913`-`$F323` (`Map`); `$F4ED`-`$F4EF` (`Map`); `$F515`-`$F522` (`Map`); 2 more ranges |
| Writes | `$FFEA`-`$FFED` (work space) |

### `KeepLaterCell` (`$CDBF`)

**DE = HL if map cell HL is drawn after cell DE**

The drawing order of DrawMapObjects: diagonals by falling x - y, along a diagonal by rising x. A = (yHL - yDE) + (xDE - xHL) (columns by the low bytes, rows from the high bytes: (H - `$DD`) / 2). A > 0: HL's diagonal is later; A = 0: same diagonal, later when xHL > xDE.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 2,857 calls, 277,070 t-states own (0.01 %) |
| Called from | `CheckObjectNeighbour`, `CheckBlockNeighbour` |
| Writes | `$FFEC`-`$FFED` (work space) |

### `FindRobot` (`$CDD8`)

**Z: IY the robot record standing on map cell HL, B = 48 - its slot (slots 0-23 the player's)**

Walks the 48 records of Robots (16 bytes: slots 0-23 the player's, 24-47 the enemy's) comparing the draw cell +`$00`/+`$01` with HL; a free slot has +`$01` = 0 and never matches a map address. Out: Z, IY = the record, B = 48 - slot; NZ when none. DE is kept. A robot deferred by DrawMover is found at the deferred cell, as the walk needs it. Called by DrawCellObject, PlayLoop (the robot under the ship), the captures, the shot hits, the blast and ObjectTop.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 12,891 calls, 47,025,281 t-states own (1.82 %) |
| Runs (`work/game-r2`, save and load) | 466 calls, 1,901,374 t-states own (0.44 %) |
| Runs (`work/game`, the first game) | 611 calls, 2,777,640 t-states own (0.93 %) |
| Called from | `NewGameSetup`, `GameTurnEnd`, `ObjectTop`, `ScanLane`, `MoveShot`, `DrawCellObject` |
| Reads | `$DA00`-`$DCF1` (`Robots`, `EnemyRobots`) |
| Writes | `$FFE2`-`$FFFD` (work space) |

### `FindBuilding` (`$CDF5`)

**Z: IY the building record (Buildings) on map cell HL**

Walks the 56 records of Buildings (3 bytes: the map cell address, the type) comparing the cell with HL. Out: Z, IY = the record; NZ when none. DE is kept. Called by DrawCellObject, CheckWarbasePad (the construction menu's pad), ObjectTopBuilding and RemoveBuilding.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7,308 calls, 17,570,431 t-states own (0.68 %) |
| Runs (`work/game-r2`, save and load) | 336 calls, 859,643 t-states own (0.20 %) |
| Runs (`work/game`, the first game) | 609 calls, 1,489,803 t-states own (0.50 %) |
| Called from | `NewGameSetup`, `ObjectTop`, `RemoveBuilding`, `DrawCellObject` |
| Reads | `$FF01`-`$FFA6` (`Buildings`) |
| Writes | `$FFE6`-`$FFF3` (work space) |

### `DrawCellObject` (`$CE12`)

**Draw the object of map cell HL (bit 6): a robot, a building or a shot**

A robot whose +`$00`/+`$01` is HL goes to DrawMover. A building record goes to its sprite: BuildingSprites[type] at height BuildingHeights[type]. Otherwise the five shot records at `$D7D3` (9 bytes: +`$00`/+`$01` cell, +`$02`/+`$03` x, +`$04` y, +`$05` direction, +`$06` range, +`$07` weapon 1-3, +`$08` height) are searched; a match goes to DrawMover.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 8,196 calls, 1,916,660 t-states own (0.07 %) |
| Runs (`work/game-r2`, save and load) | 376 calls, 110,011 t-states own (0.03 %) |
| Runs (`work/game`, the first game) | 597 calls, 137,348 t-states own (0.05 %) |
| Called from | `DrawCell` |
| Calls | `MapCell`, `FindLatestBlock`, `FindRobot`, `FindBuilding`, `DrawMoverSprite` (tail), `DrawRobotPart`, `DrawSprite`, `AddAToHL` |
| Reads | `$CE56`-`$CE67` (`BuildingSprites`, `BuildingHeights`); `$DA02`-`$DA5D` (`Robots`); `$F520` (`Map`); `$F922` (`Map`); `$FF4B`-`$FF57` (`Buildings`) |
| Writes | `$CF3F` (`DrawSprite`); `$DA20`-`$DA21` (`Robots`); `$F520` (`Map`); `$F922` (`Map`); `$FFE6`-`$FFF3` (work space) |

### `DrawMover` (`$CE68`)

**Draw robot or shot IY found at cell HL (view row D, column E), after the blocks that overlap it**

Robots and shots keep their real position in +`$02`/+`$03` (x) and +`$04` (y) and in +`$00`/+`$01` the cell the walk draws them at. At the real cell FindLatestBlock looks for a later neighbouring block; if there is one, the object is moved there (bit 6 set on it, +`$00`/+`$01` = it) and nothing is drawn yet. When the walk reaches the deferred cell, +`$00`/+`$01` is set back to the real cell, the deferred cell's bit 6 is cleared and the view position is walked back from the deferred cell to the real one (x first, then y), and DrawMoverSprite draws the object there. So a robot is drawn after (over) every block whose sprite overlaps it. No shot reached here: see DrawCellObject.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawMoverSprite` (`$CEC3`)

**Draw IY: a robot record (`$DA00` up) as a stack of parts, a shot as one sprite**

Records at `$D800` and up are robots: DrawRobot. A shot (records at `$D7D3`) is sprite `$2B` + 2 * weapon (+`$07`: 1 cannon, 2 missiles, 3 phasers) + 1 when it flies down or up (+`$05` = 4 or 8), at height +`$08`: `$2D`/`$2E` a cannon shell, `$2F`/`$30` a missile trail, `$31`/`$32` a phaser beam (the sprite pictures in start.bin).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,330 calls, 61,180 t-states own (0.00 %) |
| Called from | `DrawCellObject` (tail) |
| Calls | `DrawRobot` (tail) |

### `DrawRobot` (`$CEE8`)

**Draw robot IY at view row D, column E: its parts bottom up**

Height starts at +`$0D` (the ground under the robot, 0 in the construction menu); for each bit of the parts mask +`$07` from bit 0 (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics) DrawRobotPart draws the part and raises the height. Called by DrawMoverSprite and ShowRobotDesign.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,359 calls, 478,669 t-states own (0.02 %) |
| Called from | `ShowRobotDesign`, `DrawMoverSprite` (tail) |
| Calls | `DrawRobotPart` |
| Reads | `$DA07`-`$DA5D` (`Robots`) |
| Writes | `$CF3F` (`DrawSprite`); `$FFF0`-`$FFF1` (work space) |

### `DrawRobotPart` (`$CEFD`)

**Draw part 8 - B of robot IY facing +`$08`, then raise the height**

Sprite = `$16` + the parts table `$D6C8`[4 * part + direction], direction = the number of the lowest set bit of +`$08` (0 right, 1 left, 2 down, 3 up, the Input bits). After drawing, the height (`$CF3F`) grows by the part's height `$D7B4`[part]: bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,915 calls, 1,120,374 t-states own (0.04 %) |
| Runs (`work/game-r2`, save and load) | 270 calls, 89,427 t-states own (0.02 %) |
| Called from | `DrawCellObject`, `DrawRobot` |
| Calls | `DrawSprite`, `AddAToHL` |
| Reads | `$CF3F` (`DrawSprite`); `$D6C8`-`$D6E7` (`PartSpriteTable`); `$D7B4`-`$D7BB` (`PartHeights`); `$DA08`-`$DA58` (`Robots`) |
| Writes | `$CF3F` (`DrawSprite`); `$FFE2`-`$FFEF` (work space) |

### `DrawSprite` (`$CF2D`)

**Draw sprite A at view row D, column E, height (`$CF3F`) into the view buffer**

The isometric projection: the half-byte column L = 2E + D - 24, the pixel row of the sprite's bottom line H = 8D + 100 - 4E - height. So a step along x moves 8 pixels right and 4 up, a step along y 4 right and 8 down. The sprite table `$D6E8` holds two words a sprite (A*2 + 1 for an odd half-byte column: the image shifted by 4 pixels). A sprite: rows, width in bytes, then for each row bottom up (mask, pixels) byte pairs; drawn by AND mask, OR pixels into the 20-byte rows of the buffer `$5B00`, upwards.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 116,282 calls, 955,619,180 t-states own (37.02 %) |
| Runs (`work/game-r2`, save and load) | 6,804 calls, 56,122,387 t-states own (12.95 %) |
| Runs (`work/game`, the first game) | 8,358 calls, 82,534,229 t-states own (27.76 %) |
| Called from | `DrawMapObjects`, `DrawCell`, `DrawCellObject`, `DrawRobotPart` |
| Calls | `TableWord`, `AddAToHL` |
| Reads | `$5B09`-`$6777` (`ViewBufferTail`); `$68FF`-`$7BE5` (`ImTable`, `GameSave`, `SaveReturn`, `Im2Spare` and 51 more); `$7D80`-`$8087` (`SprPhasersYp`, `SprPhasersYpRows`, `SprPhasersYpOdd`, `SprPhasersYpOddRows` and 4 more); `$8224`-`$88E1` (`SprElectronicsXp`, `SprElectronicsXpRows`, `SprElectronicsXpOdd`, `SprElectronicsXpOddRows` and 24 more); `$8E3A`-`$92F9` (`SprShip`, `SprShipRows`, `SprShipOdd`, `SprShipOddRows` and 11 more); `$9914`-`$9F8D` (`SprBlockLow`, `SprBlockLowRows`, `SprBlockLowOdd`, `SprBlockLowOddRows` and 10 more); 1 more ranges |
| Writes | `$5B09`-`$6777` (`ViewBufferTail`); `$CFAF` (`DrawSprite`); `$FFDA`-`$FFF9` (work space) |

### `DrawViewBackground` (`$CFD7`)

**Clear the view buffer and paint the corners outside the map**

ClearViewBuffer, FillViewCorner (the solid top left corner), then the diagonal edge strips from `$D6A8`: 6 strips down and left from buffer row 0, column 10 (the top left edge), 3 from row 136, column 18 and 4 of the other diagonal (`$D6B8`) from row 128, column 18 (the bottom right corner, the blue area that DrawPlayScreen colours `$41` / `$71`). Called by DrawView and once by `$A62D`.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,425 calls, 544,727 t-states own (0.02 %) |
| Runs (`work/game-r2`, save and load) | 192 calls, 30,528 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 300 calls, 47,700 t-states own (0.02 %) |
| Called from | `GameEntry`, `NewGameSetup`, `EnterPlay`, `DrawView` |
| Calls | `ClearViewBuffer`, `FillViewCorner`, `DrawEdgeStrips` (tail) |
| Writes | `$FFFA`-`$FFFB` (work space) |

### `ClearViewBuffer` (`$CFFE`)

**Zero the view buffer `$5B00-$677F` (20 bytes x 160 rows)**

Pushes HL = 0 with SP at `$6780` (198 x 16 bytes, SP kept in `$FD08`), then clears the first 32 bytes with LDIR. Called by DrawViewBackground, ShowRobotDesign and `$CB52`.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,461 calls, 71,859,791 t-states own (2.78 %) |
| Runs (`work/game-r2`, save and load) | 192 calls, 3,985,551 t-states own (0.92 %) |
| Runs (`work/game`, the first game) | 300 calls, 6,226,857 t-states own (2.09 %) |
| Called from | `StartRobot`, `ShowRobotDesign`, `DrawViewBackground` |
| Reads | `$5B00`-`$5B1E` (system); `$FD08`-`$FD09` (`SavedSP`) |
| Writes | `$5B00`-`$5F3F` (system); `$5F8E`-`$607F` (system); `$60EE`-`$614F` (system); `$618E`-`$64BF` (system); `$64DE`-`$64DF` (system); `$64FE`-`$65FF` (system); 5 more ranges |

### `FillViewCorner` (`$D026`)

**Fill the top left corner of the view buffer: a staircase of 5 bands**

5 bands of 8 rows; the first fills 10 bytes of each row, each next band 2 fewer (10, 8, 6, 4, 2). The fill and skip counts are the operands `$D038` and `$D041`, reset to 10 at the start and moved by 2 after each band.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,425 calls, 32,822,634 t-states own (1.27 %) |
| Runs (`work/game-r2`, save and load) | 192 calls, 1,839,550 t-states own (0.42 %) |
| Runs (`work/game`, the first game) | 300 calls, 2,874,000 t-states own (0.97 %) |
| Called from | `DrawViewBackground` |
| Calls | `AddAToHL` |
| Reads | `$D038`-`$D041` (`FillViewCorner`) |
| Writes | `$5B00`-`$5D95` (system); `$5DA8`-`$5DA9` (system); `$5DBC`-`$5DBD` (system); `$5DD0`-`$5DD1` (system); `$5DE4`-`$5DE5` (system); `$5DF8`-`$5DF9` (system); 3 more ranges |

### `DrawEdgeStrips` (`$D057`)

**Copy B strips of 8 rows x 2 bytes (pattern HL) into the buffer, each 8 rows down and 2 bytes left**

The diagonal edge of the map in the view. The patterns are at `$D6A8` (ink on the left: `$FFFF`, `$FFFC`, ..., `$C000`) and `$D6B8` (ink on the right).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,275 calls, 29,981,903 t-states own (1.16 %) |
| Runs (`work/game-r2`, save and load) | 576 calls, 1,680,325 t-states own (0.39 %) |
| Runs (`work/game`, the first game) | 900 calls, 2,625,680 t-states own (0.88 %) |
| Called from | `DrawViewBackground` (tail) |
| Reads | `$D6A8`-`$D6C7` (`ViewEdgeA`, `ViewEdgeB`) |
| Writes | `$5B0A`-`$5EAD` (system); `$6512`-`$672B` (system); `$673C`-`$673F` (`ViewBufferTail`); `$6750`-`$6753` (`ViewBufferTail`); `$6764`-`$6767` (`ViewBufferTail`); `$6778`-`$677B` (`ViewBufferTail`); 1 more ranges |

### `CopyViewToScreen` (`$D071`)

**Copy the view buffer to the screen at character row 1, column 1 (20 x 20 characters)**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,423 calls, 211,323,734 t-states own (8.19 %) |
| Runs (`work/game-r2`, save and load) | 187 calls, 11,544,689 t-states own (2.66 %) |
| Runs (`work/game`, the first game) | 298 calls, 18,397,366 t-states own (6.19 %) |
| Called from | `DrawView` (tail) |
| Reads | `$5B00`-`$677F` (`ViewBufferTail`); `$68FF`-`$6900` (`ImTable`) |
| Writes | `$4021`-`$5194` (screen); `$5201`-`$5294` (screen); `$5301`-`$5394` (screen); `$5401`-`$5494` (screen); `$5501`-`$5594` (screen); `$5601`-`$5694` (screen); 2 more ranges |

## screen

`src/game/screen.asm`

### `ClearScreen` (`$D0B9`)

**Clear the screen (pixels and attributes to 0) and make the border black**

Clears the 6912 bytes of pixels and attributes from `$4000` and sets the border black (and the speaker off) with OUT (`$FE`),0. Called by DrawPlayScreen, MainMenu `$C100`, RedefineKeys `$C34A` and OpenConstructionMenu `$C865`. Changes A, BC, DE, HL.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 15 calls, 2,178,473 t-states own (0.08 %) |
| Runs (`work/game-r2`, save and load) | 7 calls, 1,016,641 t-states own (0.23 %) |
| Runs (`work/game`, the first game) | 2 calls, 290,496 t-states own (0.10 %) |
| Called from | `MainMenu`, `ConstructionMenu`, `DrawPlayScreen` |
| Reads | `$4000`-`$5AFE` (screen); `$68FF`-`$6900` (`ImTable`) |
| Writes | `$4000`-`$5AFF` (screen); `$FFF6`-`$FFFB` (work space) |
| Ports out | `$00FE` |

### `ClearScreenFill` (`$D0C7`)

**ClearScreen's LDIR**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawPlayScreen` (`$D0CA`)

**Draw the whole play screen: the view, its frame, the colours, DAY / TIME / RADAR**

ClearScreen and DrawView, then the frame of the view (22 x 22 characters from (0,0): double lines at the top and bottom, `$81` lines at the sides), the attributes: `$07` everywhere, `$78` on the frame, `$70` (yellow paper) in the view, `$71` and `$41` (blue) in its bottom right corner, the area past the map's edge. Prints PlayScreenText. Called at the start of play (`$A68E`) and after the construction menu (`$CB52`).

PlayScreenText ends the code: PrintInline returns into ShowStatusPanel, so the panel's labels come with every play screen; the numbers come with the next UpdateStatusPanel. The radar appears at the next frame's PlayInterrupt.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 8 calls, 381,478 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 4 calls, 190,796 t-states own (0.04 %) |
| Runs (`work/game`, the first game) | 1 call, 47,699 t-states own (0.02 %) |
| Called from | `GameEntry`, `NewGameSetup`, `EnterPlay`, `StartRobot` |
| Calls | `DrawView`, `ClearScreen`, `NextScreenLine`, `AddAToHL`, `PrintInline` |
| Reads | `$4000`-`$4014` (screen); `$4701`-`$4713` (screen); `$50A1`-`$50B3` (screen); `$57A0`-`$57B4` (screen); `$5800`-`$5AFE` (screen); `$68FF`-`$6900` (`ImTable`) |
| Writes | `$4000`-`$50B5` (screen); `$5100`-`$51A0` (screen); `$51B5` (screen); `$5200`-`$52A0` (screen); `$52B5` (screen); `$5300`-`$53A0` (screen); 10 more ranges |

### `ShowStatusPanel` (`$D1E5`)

**Clear the right panel and print the status labels**

ClearPanel, then StatusPanelText. Called when the robot menu ends (CloseRobotMenu `$A819`) and at the game's end (GameStop `$AF07`). DrawPlayScreen falls into it after its own string, so every play screen gets the labels. The numbers come from UpdateStatusPanel.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 15 calls, 510 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 4 calls, 136 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 34 t-states own (0.00 %) |
| Called from | `ShowOrderMiles`, `PrintInline` |
| Calls | `ClearPanel`, `PrintInline` |

### `UpdateStatusPanel` (`$D293`)

**Print the panel's numbers: resources, then both sides' buildings and robots**

Skipped while PanelBusy (`$FD39`) is not 0 (the robot menu owns the panel). Prints the seven Resources at (17-23, 30) as two digits, attribute `$4E`; the enemy's building counts EnemyBuildings `$FD42` (by type 0-6) at (6-12, 22) and robots EnemyRobotCount `$FD49` at (13,22); the player's counts PlayerBuildings `$FD3A` at (6-12, 31) and robots PlayerRobotCount `$FD41` at (13,30), attribute `$47`. Called after the counts change (a capture `$AE1A`, the day's production `$AE4A`, a robot removed `$B150`, an enemy robot built `$B91C`, the blast `$BA84`) and from CheckWarbasePad (`$A70A`) after a robot is built.

The four parts are each a CALL PrintInline with a position string and the code after it (the entries below). PrintNewline comes before each resource, so the first lands on row 17.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 78 calls, 3,042 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 7 calls, 273 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 5 calls, 195 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `GameTurnEnd`, `DailyProduction`, `UpdateRobot`, `EnemyCommander`, `PrintInline` |
| Calls | `PrintInline` |
| Reads | `$FD39` (`PanelBusy`) |

### `PrintResourceValues` (`$D2A3`)

**The seven resource values, each on the next line (the tail of `$D293`)**

Seven lines from Resources (`$FD22`: general, electronics, nuclear, phasers, missiles, cannon, chassis), each PrintNewline then PrintNumber2: rows 17-23, column 30, blank leading zero. Falls into the next position string.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 78 calls, 69,439 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 7 calls, 6,230 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 5 calls, 4,450 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2`, `PrintInline`, `PrintNewline` |
| Reads | `$FD22`-`$FD28` (`Resources`) |

### `PrintInsgCounts` (`$D2C1`)

**The enemy's building counts and its robots (the tail of `$D293`)**

The enemy's seven building counts EnemyBuildings (`$FD42`: warbases, then the six factory kinds) as single digits down column 22, rows 6-12; then its robots EnemyRobotCount (`$FD49`, the byte after them) at (13,22) with a leading zero, over the space before ROBOTS. Falls into the player's position string.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 78 calls, 5,342 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 7 calls, 476 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 5 calls, 340 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintDigitColumn`, `PrintNumber2Zero`, `PrintInline` |
| Reads | `$FD49` (`EnemyRobotCount`) |

### `PrintHumnCounts` (`$D2D2`)

**The player's building counts (the tail of `$D293`)**

The player's seven building counts PlayerBuildings (`$FD3A`) down column 31, rows 6-12. HL ends at PlayerRobotCount. Falls into the next position string.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 78 calls, 3,432 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 7 calls, 308 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 5 calls, 220 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintDigitColumn`, `PrintInline` |

### `PrintHumnRobots` (`$D2DF`)

**The player's robots `$FD41`, two digits (the tail of `$D293`)**

PlayerRobotCount (`$FD41`, HL from PrintHumnCounts) as two digits with a leading zero; the JP returns from UpdateStatusPanel.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 78 calls, 1,326 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 7 calls, 119 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 5 calls, 85 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintNumber2Zero` (tail) |
| Reads | `$FD41` (`PlayerRobotCount`) |

### `PrintDigitColumn` (`$D2E3`)

**Print seven bytes from HL as single digits, one under the other**

Each byte as "0" + n (a count of 10 or more would print ":" and the characters after it; never seen, a side has at most 4 warbases), then PrintNewline: the same column one row down. HL ends past the seventh byte (the robot count that follows). Used by PrintInsgCounts and PrintHumnCounts.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 156 calls, 120,919 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 14 calls, 10,850 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 10 calls, 7,750 t-states own (0.00 %) |
| Called from | `PrintInsgCounts`, `PrintHumnCounts` |
| Calls | `PrintCharKeep`, `PrintNewline` |
| Reads | `$FD3A`-`$FD48` (`PlayerBuildings`, `PlayerRobotCount`, `EnemyBuildings`) |
| Writes | `$FFF2`-`$FFF3` (work space) |

### `ClearPanel` (`$D2F6`)

**Blank the right panel: 22 lines of 10 spaces from (2,22) in attribute 0**

Called by ShowStatusPanel and by the robot menus (RobotMenuShow `$A732`, CloseRobotMenu `$A812`, OrdersMenu `$A971`, OrderMove `$AA15`, TargetMenu `$AAD2`, CaptureMenu `$AB4E`, CombatMenu `$AC00`) and GameStop (`$AF04`) before they print. Attribute 0 (black on black) hides the area at once; rows 22-23 of the panel (STRENGTH) are cleared too.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 50 calls, 850 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 4 calls, 68 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 17 t-states own (0.00 %) |
| Called from | `RobotMenuShow`, `ShowOrderMiles`, `OrdersMenu`, `TargetMenu`, `CaptureMenu`, `ShowStatusPanel` |
| Calls | `PrintInline` |

### `ClearPanelLines` (`$D301`)

**22 lines (the tail of ClearPanel)**

B = 22: rows 2-23. B survives each PrintInline: it works in the alternate registers.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 50 calls, 350 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 4 calls, 28 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 1 call, 7 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ClearPanelLine` |

### `ClearPanelLine` (`$D303`)

**Print 10 spaces and a newline**

One CALL PrintInline with PanelBlankLine; the code goes on at ClearPanelNext.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,100 calls, 18,719 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 88 calls, 1,496 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 22 calls, 374 t-states own (0.00 %) |
| Called from | `ClearPanelLines`, `ClearPanelNext` (tail) |
| Calls | `PrintInline` |

### `ClearPanelNext` (`$D312`)

**The next of the 22 lines**

DJNZ back to ClearPanelLine for the 22 rows, then the return from ClearPanel.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,100 calls, 14,550 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 88 calls, 1,164 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 22 calls, 291 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `ClearPanelLine` (tail) |

### `DrawMaskedUp` (`$D315`)

**Draw a masked image on the screen: C lines of B (mask, pixel) pairs from HL to DE, going up**

Each line ANDs the mask and ORs the pixels; DE moves one screen line up (PrevScreenLine) after each. Out: HL past the picture. No clipping.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 56 calls, 393,367 t-states own (0.02 %) |
| Called from | `ConstructionMenu` |
| Calls | `PrevScreenLine` |
| Reads | `$4030`-`$4112` (screen); `$4130`-`$4212` (screen); `$4230`-`$4312` (screen); `$4330`-`$4412` (screen); `$4430`-`$4512` (screen); `$4530`-`$4612` (screen); 10 more ranges |
| Writes | `$4030`-`$4212` (screen); `$4230`-`$4312` (screen); `$4330`-`$4412` (screen); `$4430`-`$4512` (screen); `$4530`-`$4612` (screen); `$4630`-`$4712` (screen); 2 more ranges |

### `NextScreenLine` (`$D32A`)

**HL = the screen address one pixel line down**

The Spectrum's screen order: the line inside a character row is bits 0-2 of H, the character row bits 5-7 of L, the third bits 3-4 of H. Keeps everything but A and the flags. Used by ShowRadar, the frame of DrawPlayScreen, the big characters of PrintBigChar and ShowRobotDesign's copy (`$CC74`).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 561,304 calls, 16,670,574 t-states own (0.65 %) |
| Runs (`work/game-r2`, save and load) | 32,240 calls, 959,354 t-states own (0.22 %) |
| Runs (`work/game`, the first game) | 48,196 calls, 1,431,452 t-states own (0.48 %) |
| Called from | `ShowRobotDesign`, `DrawPlayScreen`, `PrintBigChar`, `ShowRadar` |
| Writes | `$FFF6`-`$FFF7` (work space) |

### `PrevScreenLine` (`$D339`)

**DE = the screen address one pixel line up**

The reverse of NextScreenLine on DE: used only by DrawMaskedUp, which draws from the bottom line up. Keeps everything but A and the flags.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,323 calls, 40,157 t-states own (0.00 %) |
| Called from | `DrawMaskedUp` |

### `TableWord` (`$D348`)

**HL = the word at HL + 2*A**

The sprite table lookup of DrawSprite, also ConstructionMenu (PartIconLoop `$C881`) and DrawShape (`$BD67`). A is an index 0-127 (A*2 must fit a byte). Changes A.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 116,428 calls, 6,405,687 t-states own (0.25 %) |
| Runs (`work/game-r2`, save and load) | 6,894 calls, 379,322 t-states own (0.09 %) |
| Runs (`work/game`, the first game) | 8,448 calls, 464,811 t-states own (0.16 %) |
| Called from | `DrawShape`, `ConstructionMenu`, `DrawSprite` |
| Calls | `AddAToHL` |
| Reads | `$BF9C`-`$BFB1` (`ShapeTable`); `$D6E8`-`$D705` (`SpriteTable`); `$D724`-`$D79B` (`SpriteTable`) |
| Writes | `$FFE0`-`$FFF5` (work space) |

### `AddAToHL` (`$D351`)

**HL += A**

A changed to the new H; BC, DE kept. Used everywhere a table is indexed by a byte (about 50 call sites).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 434,490 calls, 14,343,015 t-states own (0.56 %) |
| Runs (`work/game-r2`, save and load) | 23,119 calls, 763,136 t-states own (0.18 %) |
| Runs (`work/game`, the first game) | 31,577 calls, 1,042,421 t-states own (0.35 %) |
| Called from | `PaintMenuItem`, `TerrainTop`, `ObjectTop`, `SteerByOrder`, `SetStepDelay`, `EnemyCommander`, `CountBases`, `SetBaseOwner`, `ConstructionMenu`, `ConstructionMenuLoop`, `PrintMenuResources`, `ShowRobotDesign`, `DrawMapObjects`, `DrawCellObject`, `DrawRobotPart`, `DrawSprite`, `FillViewCorner`, `DrawPlayScreen`, `TableWord`, `PrintBigChar` |
| Writes | `$FFDE`-`$FFF9` (work space) |

### `Random` (`$D358`)

**A = a pseudo-random byte**

A 32-bit shift register at RandomSeed `$FD00-$FD03` (big end first, seeded `$39`,`$30`,`$39`,`$30` by Restart): shifted left once, the new bit = bit 3 XOR bit 6 of `$FD00`. Then the byte at the index the previous call used (kept in the operand `$D371`) gives, by its low 2 bits, the new index, and A = the byte there. HL is kept;

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 54,815 calls, 10,634,528 t-states own (0.41 %) |
| Runs (`work/game-r2`, save and load) | 1,021 calls, 198,131 t-states own (0.05 %) |
| Runs (`work/game`, the first game) | 1,511 calls, 293,134 t-states own (0.10 %) |
| Called from | `GameTurn`, `UpdateRobot`, `RobotStep`, `SteerByOrder`, `EnemyCommander`, `SoundEffect` |
| Reads | `$FD00`-`$FD03` (`RandomSeed`) |
| Writes | `$D371` (`Random`); `$FD00`-`$FD03` (`RandomSeed`); `$FFEE`-`$FFF9` (work space) |

## controls

`src/game/controls.asm`

### `WaitKey` (`$D37C`)

**ReadControls; while key 1 (Input bit 7) is held, the pause: wait for another key**

In: nothing. Out: A = Input (also in Input `$FD0C`); the flags of the last OR A. When the pause key (bit 7) is held it loops in PauseLoop until some other control is pressed with the pause key up, then falls into ReadControls again: the control that ended the pause is this turn's input. Changes A, BC, HL. Called once a turn by PlayLoop, DirectControlLoop, DistanceLoop, ListMenu, WaitRelease, GameOverKey, RobotDirectControl and ConstructionMenuLoop.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,056 calls, 321,849 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 184 calls, 5,888 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 298 calls, 9,536 t-states own (0.00 %) |
| Called from | `NewGameSetup`, `PlayLoop`, `ListMenu`, `WaitRelease`, `ConstructionMenuLoop` |
| Calls | `ReadControls` |

### `ReadControls` (`$D38A`)

**Input from the redefinable keys (KeyTable) or the joystick the menu chose (Controls)**

The eight keys of KeyTable are rotated into C one by one (RL C, starting from C = 1: after the eighth the 1 drops into the carry and ends the loop), entry 0 ending in bit 7. Then the joystick by Controls (`$D3E4`): 2 Kempston (port `$1F`, bits 0-4 already right, left, down, up, fire), 3 Interface 2 (port `$EFFE`, keys 6-0, inverted and reordered), else none. Out: A = Input = joystick OR keys.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 10,056 calls, 7,090,829 t-states own (0.27 %) |
| Runs (`work/game-r2`, save and load) | 184 calls, 128,061 t-states own (0.03 %) |
| Runs (`work/game`, the first game) | 298 calls, 207,408 t-states own (0.07 %) |
| Called from | `WaitKey` |
| Reads | `$D3CC`-`$D3E4` (`KeyTable`, `Controls`) |
| Writes | `$FD0C` (`Input`); `$FFF8`-`$FFFB` (work space) |
| Ports in | `$001F`, `$7FFE`, `$DFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

## print

`src/game/print.asm`

### `PrintNumber2` (`$D3E5`)

**Print A (0-99) as two digits, a leading zero blank**

In: A. HL = A, E = `$20`, then PrintTensUnits: a space for a leading zero. Used for the resources (PrintResourceValues), the construction menu values and the miles of ADVANCE / RETREAT. A value of 100 or more would print a tens "digit" above 9 (":" and on); the game caps every resource at 99.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 749 calls, 22,489 t-states own (0.00 %) |
| Runs (`work/game-r2`, save and load) | 49 calls, 1,470 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 35 calls, 1,050 t-states own (0.00 %) |
| Called from | `PrintMenuResourceValue`, `PrintResourceValues` |
| Calls | `PrintTensUnits` (tail) |
| Writes | `$FFF0`-`$FFF1` (work space) |

### `PrintNumber2Zero` (`$D3EC`)

**Print A (0-99) as two digits with a leading zero**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 6,986 calls, 209,675 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 380 calls, 11,400 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 604 calls, 18,120 t-states own (0.01 %) |
| Called from | `GameTurnEnd`, `PrintInsgCounts`, `PrintHumnRobots` (tail) |
| Calls | `PrintTensUnits` (tail) |
| Writes | `$FFF8`-`$FFFB` (work space) |

### `PrintNumber5` (`$D3F3`)

**Print HL as five digits, leading zeros blank**

Used by `$AD90` for the day number (the ДЕНЬ: line). Falls into PrintNumber3.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 3,415 calls, 208,391 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 183 calls, 16,104 t-states own (0.00 %) |
| Runs (`work/game`, the first game) | 297 calls, 26,136 t-states own (0.01 %) |
| Called from | `GameTurnEnd` |
| Calls | `PrintDigit` |
| Writes | `$FFFA`-`$FFFB` (work space) |

### `PrintNumber3` (`$D401`)

**Print HL as three digits (E = `$20`: leading zeros blank, else printed)**

The operand `$FF9C` is -100 (the source writes it so with @isub; as a label it would read Buildings+155, a false symbol). Used by PrintMenuTotal and `$A833`.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 140 calls, 96,042 t-states own (0.00 %) |
| Called from | `ShowStrengthValue`, `PrintMenuTotal` (tail) |
| Calls | `PrintDigit` |
| Writes | `$FFFA`-`$FFFB` (work space) |

### `PrintTensUnits` (`$D407`)

**Print the tens and the units of HL**

HL = the value (0-99, else the tens "digit" runs past 9: 200 prints as "D0"), E = the leading-zero flag. The tens by PrintDigit, the units always printed. The tail of PrintNumber2, PrintNumber2Zero, PrintNumber3 and PrintNumber5.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 7,735 calls, 542,015 t-states own (0.02 %) |
| Runs (`work/game-r2`, save and load) | 429 calls, 29,376 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 639 calls, 44,928 t-states own (0.02 %) |
| Called from | `PrintNumber2` (tail), `PrintNumber2Zero` (tail) |
| Calls | `PrintDigit`, `PrintCharKeep` (tail) |
| Writes | `$FFF0`-`$FFFB` (work space) |

### `PrintDigit` (`$D413`)

**Print the digit of HL for the power -BC; HL keeps the rest**

Counts how often BC (a negative power of 10) can be added. A zero while E = `$20` prints a space and keeps E; any printed digit increments E, so later zeros print as 0.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 21,675 calls, 1,907,171 t-states own (0.07 %) |
| Runs (`work/game-r2`, save and load) | 1,161 calls, 105,016 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 1,827 calls, 160,168 t-states own (0.05 %) |
| Called from | `PrintNumber5`, `PrintNumber3`, `PrintTensUnits` |
| Calls | `PrintCharKeep` |
| Writes | `$FFF0`-`$FFF9` (work space) |

### `PrintCharKeep` (`$D427`)

**PrintChar A with BC, DE, HL kept (EXX around)**

PrintChar in the alternate registers: the caller's BC, DE, HL are kept (the number printers keep HL, E and the loop counters in them). A and the flags change.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 37,583 calls, 1,315,671 t-states own (0.05 %) |
| Runs (`work/game-r2`, save and load) | 2,054 calls, 71,947 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 3,130 calls, 109,569 t-states own (0.04 %) |
| Called from | `ShowStrengthValue` (tail), `GameTurnEnd`, `PrintDigitColumn`, `PrintTensUnits` (tail), `PrintDigit` |
| Calls | `PrintChar` |
| Writes | `$FFF6`-`$FFFB` (work space) |

### `PrintInline` (`$D42D`)

**print the text after the CALL: 0 ends, 1 Y X a position, 2 A an attribute, 3 the next line, 4 N a setting, else a character**

In: the string after the CALL. Pops the return address, takes a byte, pushes the address one byte on, until a 0: the RET then lands after the string. Each byte goes to PrintControl (codes 1-4 and characters). Works in the alternate set (EXX at both ends), so the caller's BC, DE, HL are kept; A and the flags change. Callers also end in it with JP (PrintKeyPrompt `$C40C`), so the bytes after their own CALL are the string. About 60 call sites: every screen and panel text.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 5,299 calls, 2,719,895 t-states own (0.11 %) |
| Runs (`work/game-r2`, save and load) | 332 calls, 214,682 t-states own (0.05 %) |
| Runs (`work/game`, the first game) | 349 calls, 131,032 t-states own (0.04 %) |
| Called from | `RobotMenuShow`, `ShowOrder`, `ShowStrength`, `OrdersMenu`, `TargetMenu`, `CaptureMenu`, `GameTurn`, `MainMenu`, `MainMenuOptions`, `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option`, `ControlsOptionAttr`, `ConstructionMenu`, `PrintMenuResources`, `PrintMenuResource`, `DrawPlayScreen`, `ShowStatusPanel`, `UpdateStatusPanel`, `PrintResourceValues`, `PrintInsgCounts`, `PrintHumnCounts`, `ClearPanel`, `ClearPanelLine` |
| Calls | `ShowOrder`, `ShowOrderMiles`, `ShowStrengthValue`, `OrdersMenuChoose`, `DestroyMenuChoose`, `CaptureMenuChoose`, `GameTurnEnd`, `MenuKeyboardOption`, `MenuKempstonOption`, `MenuInterface2Option`, `MenuOptionsEnd`, `ControlsOptionPlain`, `ControlsOptionChosen`, `ConstructionMenuSetup`, `PrintMenuTotal`, `PrintMenuResourceValue`, `ShowStatusPanel`, `UpdateStatusPanel`, `PrintResourceValues`, `PrintInsgCounts`, `PrintHumnCounts`, `PrintHumnRobots`, `ClearPanelLines`, `ClearPanelNext`, `PrintControl` |
| Reads | `$A738`-`$ABB8` (`RobotMenuText`, `ShowOrder`, `OrderLineHead`, `OrderLine` and 35 more); `$AD88`-`$AD8F` (`ClockPos`); `$C109`-`$C18A` (`MenuStartText`, `MenuKeyboardOption`, `MenuKeyboardText`, `MenuKempstonOption` and 3 more); `$C33F`-`$C348` (`OptionAttrPlain`, `ControlsOptionPlain`, `OptionAttrChosen`); `$C8BE`-`$C9E6` (`ConstructionTitleText`, `PartNamesText`, `ExitStartText`, `PartCostsText` and 1 more); 2 more ranges |
| Writes | `$FFF2`-`$FFFD` (work space) |

### `PrintControl` (`$D43C`)

**PrintInline's byte A: control codes 1-4 or a character**

1 Y X: the position (row Y, column X, kept in `$FD32`/`$FD31`). 2 A: the attribute `$FD13`. 3: newline (the next row, the same column). 4 N: the size, high nibble the height in character rows (`$FD16`), low nibble the width in bytes (`$FD17`); 0 = normal. A character goes to PrintChar for size 0, else to PrintBigChar. The operands are read through the caller's return address on the stack, two levels up.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 31,877 calls, 3,417,937 t-states own (0.13 %) |
| Runs (`work/game-r2`, save and load) | 2,595 calls, 263,278 t-states own (0.06 %) |
| Runs (`work/game`, the first game) | 1,450 calls, 176,113 t-states own (0.06 %) |
| Called from | `PrintInline` |
| Calls | `PrintNewline` (tail), `SetPrintPos` (tail), `PrintChar` (tail), `PrintBigChar` (tail) |
| Reads | `$A739`-`$A98D` (`RobotMenuText`, `ShowOrder`, `OrderLineHead`, `OrderLine` and 20 more); `$AAD9`-`$AB80` (`DestroyMenuText`, `DestroyMenuChoose`, `CaptureMenu`, `CaptureMenuText`); `$AD89`-`$AD8E` (`ClockPos`); `$C10A`-`$C16C` (`MenuStartText`, `MenuKeyboardOption`, `MenuKeyboardText`, `MenuKempstonOption` and 3 more); `$C340`-`$C347` (`OptionAttrPlain`, `ControlsOptionPlain`, `OptionAttrChosen`); 4 more ranges |
| Writes | `$FD13`-`$FD17` (`PrintAttr`, `PrintAttrAddr`, `PrintHeight`, `PrintWidth`); `$FD31`-`$FD32` (`PrintColumn`, `PrintRow`); `$FFF0`-`$FFFD` (work space) |

### `PrintNewline` (`$D470`)

**The next print row, the same column**

PrintRow + 1, then SetPrintPos. Reached by code 3 inside PrintInline and called directly by the number printers' callers (GameTurnEnd `$AD96`, ResourceValueLoop, PrintDigitColumn, ReadFireKey `$C3CA`). Changes A, BC, HL.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 6,762 calls, 365,205 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 519 calls, 28,026 t-states own (0.01 %) |
| Runs (`work/game`, the first game) | 452 calls, 24,408 t-states own (0.01 %) |
| Called from | `GameTurnEnd`, `PrintResourceValues`, `PrintDigitColumn`, `PrintControl` (tail) |
| Calls | `SetPrintPos` (tail) |
| Reads | `$FD31`-`$FD32` (`PrintColumn`, `PrintRow`) |
| Writes | `$FD31`-`$FD32` (`PrintColumn`, `PrintRow`); `$FFF0`-`$FFFB` (work space) |

### `SetPrintPos` (`$D493`)

**Print position: B = row, C = column -> `$FD04` the screen address, `$FD14` the attribute address**

In: B = row 0-23, C = column 0-31. PrintAddr = `$4000` + (B AND `$18`) * 256 + (B AND 7) * 32 + C, the top line of the character cell; PrintAttrAddr = `$5800` + 32 * B + C. Changes A, HL. Used by SetPosition and PrintNewline.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 11,321 calls, 1,460,694 t-states own (0.06 %) |
| Runs (`work/game-r2`, save and load) | 757 calls, 97,710 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 776 calls, 100,123 t-states own (0.03 %) |
| Called from | `PrintControl` (tail), `PrintNewline` (tail) |
| Writes | `$FD04`-`$FD15` (`PrintAddr`, `MapView`, `SavedSP`, `ViewX` and 7 more); `$FFEE`-`$FFFB` (work space) |

### `PrintChar` (`$D4B1`)

**Print character A at the print position in the print attribute, advance one column**

The glyph is at GameFont - `$100` + 8 x code (`$C400` + 8 x code: `$C500` for the space, the first glyph of GameFont). 8 lines into (`$FD04`), the attribute (`$FD13`) into (`$FD14`), both advanced.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 55,387 calls, 27,590,516 t-states own (1.07 %) |
| Runs (`work/game-r2`, save and load) | 3,711 calls, 1,848,610 t-states own (0.43 %) |
| Runs (`work/game`, the first game) | 3,561 calls, 1,773,511 t-states own (0.60 %) |
| Called from | `PrintCharKeep`, `PrintControl` (tail) |
| Reads | `$C500`-`$C507` (`GameFont`); `$C518`-`$C52F` (`GameFont`); `$C568`-`$C5D7` (`GameFont`); `$C5F8`-`$C6DF` (`GameFont`); `$FD04`-`$FD15` (`PrintAddr`, `MapView`, `SavedSP`, `ViewX` and 7 more) |
| Writes | `$4016`-`$483F` (screen); `$4855`-`$57DF` (screen); `$57F6`-`$57FF` (screen); `$5816`-`$581F` (screen); `$5835`-`$583F` (screen); `$5856`-`$5A7F` (screen); 4 more ranges |

### `PrintBigChar` (`$D4DA`)

**Print character A scaled: each line repeated `$FD16` times, width 1 or 2 bytes (`$FD17`)**

Width 1: each glyph line written `$FD16` times (2: a character two rows high, the panel's РАДАР:). Width 2: each glyph byte doubled to 16 bits.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 180 calls, 441,378 t-states own (0.02 %) |
| Runs (`work/game-r2`, save and load) | 63 calls, 94,412 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 19 calls, 28,462 t-states own (0.01 %) |
| Called from | `PrintControl` (tail) |
| Calls | `NextScreenLine`, `AddAToHL` |
| Reads | `$C500`-`$C507` (`GameFont`); `$C570`-`$C587` (`GameFont`); `$C5D0`-`$C5D7` (`GameFont`); `$C608`-`$C64F` (`GameFont`); `$C678`-`$C68F` (`GameFont`); 3 more ranges |
| Writes | `$4003`-`$402C` (screen); `$4042`-`$416D` (screen); `$4203`-`$422C` (screen); `$4242`-`$426D` (screen); `$4303`-`$432C` (screen); `$4342`-`$436D` (screen); 19 more ranges |

## interrupts

`src/game/interrupts.asm`

### `PlayInterrupt` (`$D566`)

**the interrupt handler of play, one a frame**

Installed in ImHandler by EnterPlay (`$A694`) and by StartRobot when the construction menu ends (`$CBA2`). Keeps AF, BC, DE, HL (not IX, IY, the alternate set: the routines it calls do not use them). TurnFrames + 1 (TurnPace `$AE1D` waits for 10, then zeroes it); RadarPhase toggled, ShowRadar with RadarOwn / `$4D` on phase 0, RadarEnemy / `$4E` on phase 1; SoundFx not 0: counted on (a tone ends at `$80`, a noise when it wraps to 0) and SoundEffect plays this frame's step. Ends in PlayInterruptEnd's EI;

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 34,610 calls, 4,949,104 t-states own (0.19 %) |
| Runs (`work/game-r2`, save and load) | 1,872 calls, 267,570 t-states own (0.06 %) |
| Runs (`work/game`, the first game) | 2,974 calls, 425,167 t-states own (0.14 %) |
| Calls | `PlayMusic` (tail) |
| Reads | `$FD1A` (`RadarPhase`); `$FD34` (`TurnFrames`) |
| Writes | `$FD1A` (`RadarPhase`); `$FD34` (`TurnFrames`) |

### `InterruptSound` (`$D585`)

**InterruptSound**

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 34,609 calls, 2,952,416 t-states own (0.11 %) |
| Runs (`work/game-r2`, save and load) | 1,871 calls, 155,293 t-states own (0.04 %) |
| Runs (`work/game`, the first game) | 2,973 calls, 246,759 t-states own (0.08 %) |
| Called from | `PlayMusic` (tail) |
| Calls | `SoundEffect` |
| Reads | `$FD53` (`SoundFx`) |
| Writes | `$FD53` (`SoundFx`) |

### `PlayInterruptEnd` (`$D59C`)

**PlayInterrupt's last two bytes: EI, RET**

Reached only by falling out of PlayInterrupt (and from PlayMusic's return through it). Nothing puts its address in ImHandler: outside play the handler is MusicInterrupt.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowRadar` (`$D59E`)

**Show radar picture HL (16 lines x 16 bytes) at (22,6) in attribute C**

The interrupt alternates the two pictures `$D800` (terrain + the player's robots, attribute `$4D`) and `$D900` (terrain + the enemy's robots, `$4E`) every frame, so the terrain stays and each side's robots blink in their colour. The attributes are rows 22 and 23, columns 6-21.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 34,609 calls, 235,445,027 t-states own (9.12 %) |
| Runs (`work/game-r2`, save and load) | 1,871 calls, 12,728,413 t-states own (2.94 %) |
| Runs (`work/game`, the first game) | 2,973 calls, 20,225,319 t-states own (6.80 %) |
| Called from | `PlayMusic` |
| Calls | `NextScreenLine`, `FillAttr16` |
| Reads | `$D800`-`$D9FF` (`RadarOwn`, `RadarEnemy`, `SaveShots`, `SaveBuildings`) |
| Writes | `$50C6`-`$50F5` (screen); `$51C6`-`$51F5` (screen); `$52C6`-`$52F5` (screen); `$53C6`-`$53F5` (screen); `$54C6`-`$54F5` (screen); `$55C6`-`$55F5` (screen); 2 more ranges |

### `FillAttr16` (`$D5BD`)

**Write C into 16 bytes from HL**

In: HL, C. Out: HL past the 16 bytes, B = 0. The tail of ShowRadar (rows 22 and 23 of the radar).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 69,218 calls, 29,625,304 t-states own (1.15 %) |
| Runs (`work/game-r2`, save and load) | 3,742 calls, 1,601,576 t-states own (0.37 %) |
| Runs (`work/game`, the first game) | 5,946 calls, 2,544,888 t-states own (0.86 %) |
| Called from | `ShowRadar` |
| Writes | `$5AC6`-`$5AD5` (screen); `$5AE6`-`$5AF5` (screen) |

### `SoundEffect` (`$D5C4`)

**The interrupt's sound: A = `$FD53` (1-`$7F` a falling tone, `$C8-$FF` noise)**

Called by PlayInterrupt with A = SoundFx after its step, the flags of A set (never 0 here). A positive (2-`$7F`, a shot fired: SoundFx 1 counted on): C = 500 / (A+2) + 1 pulses, B = A the delay between them; each pulse's level is bit 4 of the next ROM byte from `$0000` (a rough noise), so the bursts get sparser and lower as A counts up each frame: a falling sweep over 126 frames, 3.2 ms at A = 2, about 2 ms from A = 40. A negative (`$C8-$FF`): 30 random speaker levels (Random): the crackle of a hit.

The shot code sets 1 when a shot is fired (`$B709`), `$FC` a miss (3 frames), `$FA` a hit (5 frames), `$C8` a robot destroyed (55 frames, the explosion). Changes A, BC, DE, HL. The border stays black (bits 0-2 of the OUT are 0).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1,317 calls, 3,632,359 t-states own (0.14 %) |
| Called from | `InterruptSound` |
| Calls | `Random` |
| Ports out | `$00FE`, `$10FE` |

### `BuildRadar` (`$D5F8`)

**Build both radar pictures for the 128 columns from `$FD1C`**

Each map cell of the window is one pixel: set when its block type is `$0F` or more (the tall blocks). Copies the terrain picture to `$D900`, then puts the dot of every robot in play (+`$01` not 0, except the one under direct control, +`$0A` = 2) into its side's picture (ToggleRadarDot).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 1 call, 142,587 t-states own (0.01 %) |
| Runs (`work/game-r2`, save and load) | 4 calls, 571,767 t-states own (0.13 %) |
| Runs (`work/game`, the first game) | 1 call, 142,587 t-states own (0.05 %) |
| Called from | `PutShipOnMap`, `RefreshRadar` |
| Calls | `ToggleRadarDot` |
| Reads | `$D800`-`$D8FF` (`RadarOwn`); `$DA01`-`$EF7F` (`Robots`, `EnemyRobots`, `Map`); `$F080`-`$F17F` (`Map`); `$F280`-`$F37F` (`Map`); `$F480`-`$F57F` (`Map`); 5 more ranges |
| Writes | `$D800`-`$D9FF` (`RadarOwn`, `RadarEnemy`, `SaveShots`, `SaveBuildings`); `$FFF0`-`$FFF3` (work space) |

### `ToggleRadarDot` (`$D65A`)

**XOR a 2x2 dot at map column HL, row C into radar picture B (0 player, 1 enemy)**

The dot covers (x, y), (x+1, y) and the line above. Nothing outside the window (RadarDotAddress returns past this routine). XOR: the same call removes the dot again, so the robot code toggles the old position before PlaceRobot toggles the new one.

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 24,059 calls, 2,156,730 t-states own (0.08 %) |
| Runs (`work/game-r2`, save and load) | 509 calls, 70,423 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 503 calls, 59,211 t-states own (0.02 %) |
| Called from | `BlinkShipDot` (tail), `UpdateRobot`, `RobotStep`, `PlaceRobot` (tail), `BuildRadar` |
| Calls | `RadarDotAddress` |
| Reads | `$D807`-`$D8FF` (`RadarOwn`); `$D92F`-`$D9FF` (`SaveShots`, `SaveBuildings`) |
| Writes | `$D807`-`$D8FF` (`RadarOwn`); `$D92F`-`$D9FF` (`SaveShots`, `SaveBuildings`); `$FFEA`-`$FFF9` (work space) |

### `RadarDotAddress` (`$D67D`)

**HL = the radar byte of column HL, row C in picture B, A = the pixel mask**

Column x - `$FD1C` must be 0-126, else it pops the return address and returns from ToggleRadarDot. Address = `$D800` + `$100`*B + 16*y + (x-`$FD1C`)/8, mask = `$80` >> ((x-`$FD1C`) AND 7).

| | |
| --- | --- |
| Runs (`work/docL/deep`, the bot's game) | 24,059 calls, 3,548,239 t-states own (0.14 %) |
| Runs (`work/game-r2`, save and load) | 509 calls, 94,034 t-states own (0.02 %) |
| Runs (`work/game`, the first game) | 503 calls, 74,653 t-states own (0.03 %) |
| Called from | `ToggleRadarDot` |
| Reads | `$FD1C`-`$FD1D` (`RadarColumn`) |
| Writes | `$FFF2`-`$FFF7` (work space) |

## The other banks

The game calls into four other banks at `$C000`. Their code is not part of the game image; each has its own source
and its own chapter. The entries the game uses:

| Bank | Address | Name | What the game does with it |
| --- | --- | --- | --- |
| 1 | `$C000` | `PlayerInit` | `Restart` calls it: the tune from its beginning |
| 1 | `$C005` | `PlayerFrame` | `MusicInterrupt` and `PlayMusic` call it once a frame: one 50 Hz step of the tune |
| 1 | `$D8E1` | `MusicStart` | `GameEntry` calls it once: bank 1's start-up code, the title cards (`src/music/title-cards.asm`) |
| 3 | `$E73B` | `MenuPictureCode` | `MenuPicture` calls it: the game menu's picture onto the screen |
| 3 | `$D2EF` | `DeadEnd` | `CheckGameEnd` jumps to it when we have no warbase: the lost game's ending |
| 4 | `$C000` | `DiskModule` | `GameLoad` and `GameSave` jump to it with IX = `$4000` (load) or `$4033` (save) |
| 6 | `$C000` | `FinalCutBlock` | `GameWon` copies its first `$3637` bytes to `FinalCut` `$6060` and jumps there: the won game's ending |

The tunes and their player are built from `src/music/`, the disk module from `src/disk/`, the endings from
`src/endings/` ([3. Build and load](03-build-and-load.md)); the endings' screens are in
[5.10](05-controls.md#510-the-intro-and-the-endings).

## The other parts of the game

Every code label of the parts outside the game image, as `tools/build.sh` assembles them (the listings in
`build/`): the address where it runs, its name and the first line of its comment in the source. A source
file that two parts include (a player) is listed once, at the address of its first build. The behaviour of
these parts is in [2. Architecture](02-architecture.md) and [3. Build and load](03-build-and-load.md); this
section only names them.

### The boot BASIC and UltraXOR (`src/boot/`)

`a-nether.asm` (`build/boot.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$5D3F` | `TrapEntry` | `$5D3F`, where RANDOMIZE USR 23871 (the usual start of code in a line 0) would enter: a trap. It clears `$4000`-`$5BFF` |
| `$5D85` | `ClearScreen` | `$5D85`, called by the entry: the border black and the screen cleared, from `$5AFF` down until a byte reads back |
| `$5D97` | `Entry` | `$5D97`: the entry (line 1's USR Eternity). The jumps over bytes and the ED NOPs are there to confuse a reader |
| `$7705` | `CopyTo` | - |
| `$7721` | `Layer0` | The first loop, plain in the file: from here on the interrupts are off and R starts at `$2A`, so every R value |
| `$7FCA` | `Layer77` | Layer 77, `$7FCA`, the last: `$7FE9`-`$813A` (338 bytes), from its own JR NZ displacement to the end of the |
| `$8000` | `MoveReader` | - |
| `$5D3F` | `Reader` | - |
| `$5DF7` | `ReadSectors` | B sectors to HL, from the disk's next logical sector (TR-DOS's `$5CF4`: E the sector 0-15, D the logical track, |
| `$5E3B` | `OutSystem` | A to the Beta interface's system register (`$FF`) |
| `$5E3F` | `RomCall` | IX in the TR-DOS ROM, as a call: its RET at `$3D2F` pages the ROM in and returns to IX, and IX's RET back here |
| `$5E44` | `ResetFdc` | The controller reset (system register 0, then `$3C`), a FORCE INTERRUPT, two frames, and the track register set |
| `$5E66` | `SetPage` | A to `$7FFD` |

`ultraxor-layers.asm` (`build/boot.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$7758` | `Layer1` | UltraXOR v1.2: the decrypting loops 1-76, `$7758`-`$7FC9`, in their plain form (included by a-nether.asm). |
| `$7767` | `Layer2` | Layer 2, `$7767`: decrypts `$7786`-`$7793` (14 bytes) |
| `$7787` | `Layer3` | Layer 3, `$7787`: decrypts `$7794`-`$77A1` (14 bytes) |
| `$7795` | `Layer4` | Layer 4, `$7795`: decrypts `$77A2`-`$77B8` (23 bytes) |
| `$77A3` | `Layer5` | Layer 5, `$77A3`: decrypts `$77B9`-`$77D5` (29 bytes) |
| `$77BA` | `Layer6` | Layer 6, `$77BA`: decrypts `$77D6`-`$77FA` (37 bytes) |
| `$77D7` | `Layer7` | Layer 7, `$77D7`: decrypts `$77FB`-`$780F` (21 bytes) |
| `$77FC` | `Layer8` | Layer 8, `$77FC`: decrypts `$7810`-`$7828` (25 bytes) |
| `$7811` | `Layer9` | Layer 9, `$7811`: decrypts `$7829`-`$7850` (40 bytes) |
| `$782A` | `Layer10` | Layer 10, `$782A`: decrypts `$7851`-`$7876` (38 bytes) |
| `$7852` | `Layer11` | Layer 11, `$7852`: decrypts `$7877`-`$7884` (14 bytes) |
| `$7878` | `Layer12` | Layer 12, `$7878`: decrypts `$7885`-`$78A9` (37 bytes) |
| `$7886` | `Layer13` | Layer 13, `$7886`: decrypts `$78AA`-`$78BD` (20 bytes) |
| `$78AB` | `Layer14` | Layer 14, `$78AB`: decrypts `$78BE`-`$78D4` (23 bytes) |
| `$78BF` | `Layer15` | Layer 15, `$78BF`: decrypts `$78D5`-`$78F0` (28 bytes) |
| `$78D6` | `Layer16` | Layer 16, `$78D6`: decrypts `$78F1`-`$78FE` (14 bytes) |
| `$78F2` | `Layer17` | Layer 17, `$78F2`: decrypts `$78FF`-`$7919` (27 bytes) |
| `$7900` | `Layer18` | Layer 18, `$7900`: decrypts `$791A`-`$7937` (30 bytes) |
| `$791B` | `Layer19` | Layer 19, `$791B`: decrypts `$7938`-`$7957` (32 bytes) |
| `$7939` | `Layer20` | Layer 20, `$7939`: decrypts `$7958`-`$7978` (33 bytes) |
| `$7959` | `Layer21` | Layer 21, `$7959`: decrypts `$7979`-`$7990` (24 bytes) |
| `$797A` | `Layer22` | Layer 22, `$797A`: decrypts `$7991`-`$79A2` (18 bytes) |
| `$7992` | `Layer23` | Layer 23, `$7992`: decrypts `$79A3`-`$79C8` (38 bytes) |
| `$79A4` | `Layer24` | Layer 24, `$79A4`: decrypts `$79C9`-`$79ED` (37 bytes) |
| `$79CA` | `Layer25` | Layer 25, `$79CA`: decrypts `$79EE`-`$7A0C` (31 bytes) |
| `$79EF` | `Layer26` | Layer 26, `$79EF`: decrypts `$7A0D`-`$7A37` (43 bytes) |
| `$7A0E` | `Layer27` | Layer 27, `$7A0E`: decrypts `$7A38`-`$7A62` (43 bytes) |
| `$7A39` | `Layer28` | Layer 28, `$7A39`: decrypts `$7A63`-`$7A75` (19 bytes) |
| `$7A64` | `Layer29` | Layer 29, `$7A64`: decrypts `$7A76`-`$7A8C` (23 bytes) |
| `$7A77` | `Layer30` | Layer 30, `$7A77`: decrypts `$7A8D`-`$7AB1` (37 bytes) |
| `$7A8E` | `Layer31` | Layer 31, `$7A8E`: decrypts `$7AB2`-`$7AC4` (19 bytes) |
| `$7AB3` | `Layer32` | Layer 32, `$7AB3`: decrypts `$7AC5`-`$7AD3` (15 bytes) |
| `$7AC6` | `Layer33` | Layer 33, `$7AC6`: decrypts `$7AD4`-`$7AFE` (43 bytes) |
| `$7AD5` | `Layer34` | Layer 34, `$7AD5`: decrypts `$7AFF`-`$7B1D` (31 bytes) |
| `$7B00` | `Layer35` | Layer 35, `$7B00`: decrypts `$7B1E`-`$7B2B` (14 bytes) |
| `$7B1F` | `Layer36` | Layer 36, `$7B1F`: decrypts `$7B2C`-`$7B40` (21 bytes) |
| `$7B2D` | `Layer37` | Layer 37, `$7B2D`: decrypts `$7B41`-`$7B58` (24 bytes) |
| `$7B42` | `Layer38` | Layer 38, `$7B42`: decrypts `$7B59`-`$7B7C` (36 bytes) |
| `$7B5A` | `Layer39` | Layer 39, `$7B5A`: decrypts `$7B7D`-`$7B97` (27 bytes) |
| `$7B7E` | `Layer40` | Layer 40, `$7B7E`: decrypts `$7B98`-`$7BB3` (28 bytes) |
| `$7B99` | `Layer41` | Layer 41, `$7B99`: decrypts `$7BB4`-`$7BD2` (31 bytes) |
| `$7BB5` | `Layer42` | Layer 42, `$7BB5`: decrypts `$7BD3`-`$7BFA` (40 bytes) |
| `$7BD4` | `Layer43` | Layer 43, `$7BD4`: decrypts `$7BFB`-`$7C08` (14 bytes) |
| `$7BFC` | `Layer44` | Layer 44, `$7BFC`: decrypts `$7C09`-`$7C29` (33 bytes) |
| `$7C0A` | `Layer45` | Layer 45, `$7C0A`: decrypts `$7C2A`-`$7C3A` (17 bytes) |
| `$7C2B` | `Layer46` | Layer 46, `$7C2B`: decrypts `$7C3B`-`$7C5C` (34 bytes) |
| `$7C3C` | `Layer47` | Layer 47, `$7C3C`: decrypts `$7C5D`-`$7C75` (25 bytes) |
| `$7C5E` | `Layer48` | Layer 48, `$7C5E`: decrypts `$7C76`-`$7C8D` (24 bytes) |
| `$7C77` | `Layer49` | Layer 49, `$7C77`: decrypts `$7C8E`-`$7CA9` (28 bytes) |
| `$7C8F` | `Layer50` | Layer 50, `$7C8F`: decrypts `$7CAA`-`$7CC2` (25 bytes) |
| `$7CAB` | `Layer51` | Layer 51, `$7CAB`: decrypts `$7CC3`-`$7CEF` (45 bytes) |
| `$7CC4` | `Layer52` | Layer 52, `$7CC4`: decrypts `$7CF0`-`$7D12` (35 bytes) |
| `$7CF1` | `Layer53` | Layer 53, `$7CF1`: decrypts `$7D13`-`$7D3A` (40 bytes) |
| `$7D14` | `Layer54` | Layer 54, `$7D14`: decrypts `$7D3B`-`$7D4A` (16 bytes) |
| `$7D3C` | `Layer55` | Layer 55, `$7D3C`: decrypts `$7D4B`-`$7D65` (27 bytes) |
| `$7D4C` | `Layer56` | Layer 56, `$7D4C`: decrypts `$7D66`-`$7D85` (32 bytes) |
| `$7D67` | `Layer57` | Layer 57, `$7D67`: decrypts `$7D86`-`$7DAD` (40 bytes) |
| `$7D87` | `Layer58` | Layer 58, `$7D87`: decrypts `$7DAE`-`$7DC1` (20 bytes) |
| `$7DAF` | `Layer59` | Layer 59, `$7DAF`: decrypts `$7DC2`-`$7DDB` (26 bytes) |
| `$7DC3` | `Layer60` | Layer 60, `$7DC3`: decrypts `$7DDC`-`$7DF4` (25 bytes) |
| `$7DDD` | `Layer61` | Layer 61, `$7DDD`: decrypts `$7DF5`-`$7E1B` (39 bytes) |
| `$7DF6` | `Layer62` | Layer 62, `$7DF6`: decrypts `$7E1C`-`$7E2A` (15 bytes) |
| `$7E1D` | `Layer63` | Layer 63, `$7E1D`: decrypts `$7E2B`-`$7E40` (22 bytes) |
| `$7E2C` | `Layer64` | Layer 64, `$7E2C`: decrypts `$7E41`-`$7E4F` (15 bytes) |
| `$7E42` | `Layer65` | Layer 65, `$7E42`: decrypts `$7E50`-`$7E6B` (28 bytes) |
| `$7E51` | `Layer66` | Layer 66, `$7E51`: decrypts `$7E6C`-`$7E85` (26 bytes) |
| `$7E6D` | `Layer67` | Layer 67, `$7E6D`: decrypts `$7E86`-`$7EAC` (39 bytes) |
| `$7E87` | `Layer68` | Layer 68, `$7E87`: decrypts `$7EAD`-`$7ECD` (33 bytes) |
| `$7EAE` | `Layer69` | Layer 69, `$7EAE`: decrypts `$7ECE`-`$7EE9` (28 bytes) |
| `$7ECF` | `Layer70` | Layer 70, `$7ECF`: decrypts `$7EEA`-`$7F08` (31 bytes) |
| `$7EEB` | `Layer71` | Layer 71, `$7EEB`: decrypts `$7F09`-`$7F31` (41 bytes) |
| `$7F0A` | `Layer72` | Layer 72, `$7F0A`: decrypts `$7F32`-`$7F5E` (45 bytes) |
| `$7F33` | `Layer73` | Layer 73, `$7F33`: decrypts `$7F5F`-`$7F8A` (44 bytes) |
| `$7F60` | `Layer74` | Layer 74, `$7F60`: decrypts `$7F8B`-`$7FA0` (22 bytes) |
| `$7F8C` | `Layer75` | Layer 75, `$7F8C`: decrypts `$7FA1`-`$7FC8` (40 bytes) |
| `$7FA2` | `Layer76` | Layer 76, `$7FA2`: decrypts `$7FC9`-`$7FE9` (33 bytes) |

### The loader (`src/loader.asm`)

`loader.asm` (`build/loader.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$6161` | `LoaderInterrupt` | The music of the boot, one call a frame (IM 2). Saves everything, pages bank 6 (the player) with the screen bank |
| `$6200` | `WaitFrames` | Wait BC frames |
| `$6207` | `SetPage` | Page A at `$C000` (`$7FFD`), BANKM kept up to date |
| `$6210` | `WhiteScreen` | The 768 attributes at HL white on white (`$3F`), the border white: the flash between the boot's pictures |
| `$6221` | `LoaderMain` | The boot: the intro, the logo program, the boot menu (docs/03-build-and-load.md 3) |
| `$62A6` | `LoaderEnd` | The end of the boot, also SPACE in LoaderInterrupt: IM 1, the player silenced, the BASIC's registers back, a |

### The HRUM 3.5 depackers of the blocks (`src/sfx/`)

`blocks.asm` (`build/blocks.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$0000` | `IntroScreen` | - |
| `$0000` | `IntroScreenEnd` | - |
| `$0000` | `Part9C40` | - |
| `$0000` | `Part9C40End` | - |
| `$6600` | `Intro` | - |
| `$6600` | `Block02` | - |
| `$6600` | `Block03` | - |
| `$C000` | `Block04` | - |
| `$6060` | `Block05` | - |
| `$C000` | `BootBank7` | - |
| `$C000` | `Music` | - |
| `$C000` | `DeadEnd` | - |
| `$C000` | `DiskIo` | - |
| `$6731` | `Game` | - |
| `$6060` | `FinalCut` | - |

### The intro (`src/intro/`)

`intromain.asm` (`build/intro/intro.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$6600` | `Intro` | -------------------------------------------------------------------------------------------------------------------- |
| `$666D` | `IntroEnvelopeLoop` | - |
| `$6692` | `IntroWhite` | the attributes at HL white on white, the border white |
| `$66A4` | `IntroAyEnvelope` | meant to give channel A's volume 15 to the envelope; writes `$7FFD` instead (bug) |
| `$66B6` | `IntroDeadFill` | never run: the tail of a white-screen fill |
| `$66C1` | `LogoPicture` | the decorated Eternity Industry picture unpacked to screen 5 (`$4000`) |
| `$66C5` | `LogoBase` | - |
| `$66F5` | `LogoNextToken` | - |
| `$670F` | `LogoCopy` | - |
| `$6729` | `l_6729` | - |
| `$672A` | `LogoCopyCall` | - |
| `$6734` | `LogoBlock` | - |
| `$673D` | `LogoLiteral` | - |
| `$673E` | `l_673E` | - |
| `$673F` | `LogoLiteralCall` | - |
| `$6747` | `LogoRun` | - |
| `$674D` | `LogoRunCall` | - |
| `$6755` | `LogoDone` | - |
| `$675C` | `LogoPutByte` | write A to the screen at HL' and step HL' in the stream's order |
| `$677B` | `l_677B` | - |
| `$677C` | `l_677C` | - |
| `$677E` | `l_677E` | - |
| `$6780` | `l_6780` | - |

`presentsmain.asm` (`build/intro/presents.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$6600` | `Presents` | -------------------------------------------------------------------------------------------------------------------- |
| `$6606` | `PresentsLoop` | - |
| `$6609` | `PresentsFramePtr` | - |
| `$661E` | `PresentsShowFrame` | - |
| `$662E` | `PresentsClear` | screen 5 cleared: pixels 0, attributes `$44` |
| `$6642` | `PresentsBuildShow` | write PresentsShowLines: 80 lines of 11 POP HL / LD (nn),HL |
| `$664A` | `PresentsBuildLine` | - |
| `$664E` | `PresentsBuildWord` | - |
| `$666C` | `PresentsLineDown` | DE one pixel line down the screen |
| `$D49D` | `PresentsShow` | copy one frame (HL) to the screen |

`star.asm` (`build/intro/scroller.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$6600` | `ScrollerStart` | -------------------------------------------------------------------------------------------------------------------- |
| `$6636` | `StarStep` | - |
| `$6644` | `StarStepStore` | - |
| `$6647` | `StarPathPointer` | - |
| `$66B3` | `HeatDirection` | - |
| `$66C8` | `HeatFall` | - |
| `$66D7` | `HeatTurn` | - |
| `$66DE` | `StarNext` | - |
| `$66E1` | `ScrollerUnusedShow` | never called: shows bank 7's screen (left over from another part) |
| `$6713` | `StarShow` | StarBuffer to the screen in dither patterns |
| `$6727` | `StarShowRow` | - |
| `$68B1` | `StarShowSP` | - |
| `$68BD` | `StarShowRowLow` | - |
| `$6A47` | `StarShowSP2` | - |
| `$6A4C` | `StarBurn` | the flames: every cell the mean of the four below it, the heat rising |
| `$6A58` | `StarBurnRow` | - |
| `$6C96` | `StarLine` | a line of heat StarHeat in StarBuffer from cell (L, H) to cell (E, D) |
| `$6CA1` | `StarLineDy` | - |
| `$6CAA` | `StarLineLonger` | - |
| `$6CBC` | `StarLineX` | - |
| `$6CC1` | `StarLineXStep` | - |
| `$6CD6` | `StarLineXError` | - |
| `$6CDC` | `StarLineXCount` | - |
| `$6CE9` | `StarLineSteep` | - |
| `$6CF6` | `StarLineY` | - |
| `$6CFB` | `StarLineYStep` | - |
| `$6D10` | `StarLineYError` | - |
| `$6D16` | `StarLineYCount` | - |

`text.asm` (`build/intro/scroller.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$6D24` | `TextInterrupt` | -------------------------------------------------------------------------------------------------------------------- |
| `$6D27` | `TextStages` | - |
| `$6D2D` | `TypeOn` | - |
| `$6D33` | `HoldOn` | HoldOn |
| `$6D39` | `WipeOn` | WipeOn |
| `$6D3F` | `TextStagesDone` | TextStagesDone |
| `$6D42` | `TextFinale` | This entry point is used by the routine at TextInterrupt. |
| `$6D50` | `TextFinaleType` | - |
| `$6D61` | `TextStop` | - |
| `$6D67` | `TextDone` | - |
| `$6D68` | `ScrollerSetPage` | never called: page A at `$C000` (BANKM kept) |
| `$76D4` | `WipeColumn` | one column of the text black, from the right; after 10 (and a frame), typing |
| `$76EC` | `WipeNext` | - |
| `$76EF` | `WipeAddress` | - |
| `$772B` | `HoldText` | the typed screen held 200 frames, then the wipe |
| `$773A` | `HoldStore` | - |
| `$7744` | `TypeChar` | one character of the text, a frame; after 240 the hold |
| `$775C` | `TypeRow` | - |
| `$775F` | `RowCount` | - |
| `$7772` | `RowStore` | - |
| `$7775` | `RowPointer` | - |
| `$777F` | `TextColumn` | - |
| `$7782` | `TextPointer` | - |
| `$778E` | `TypeGlyph` | - |
| `$77CD` | `TextHook` | RET: a hook HoldText and TypeChar call, left empty |

`init.asm` (`build/intro/scroller.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$C000` | `ScrollerInit` | -------------------------------------------------------------------------------------------------------------------- |
| `$C00C` | `ScrollerInitB` | - |
| `$C012` | `ScrollerInitPair` | - |
| `$C024` | `ScrollerInitLine` | - |
| `$C051` | `ScrollerInitIndex` | - |
| `$C055` | `ScrollerInitIndexByte` | - |
| `$C066` | `ScrollerInitStarRow` | - |
| `$C06C` | `ScrollerInitStarLines` | - |
| `$C07C` | `ScrollerInitTextRow` | - |
| `$C082` | `ScrollerInitTextLines` | - |
| `$C08B` | `NextLine` | DE one pixel line down the screen |

`titlepic.asm` (`build/intro/title.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$9C40` | `TitlePicture` | -------------------------------------------------------------------------------------------------------------------- |
| `$9C44` | `TitleBase` | - |
| `$9C74` | `TitleNextToken` | - |
| `$9C8E` | `TitleCopy` | - |
| `$9CA8` | `l_9CA8` | - |
| `$9CA9` | `TitleCopyCall` | - |
| `$9CB3` | `TitleBlock` | - |
| `$9CBC` | `TitleLiteral` | - |
| `$9CBD` | `l_9CBD` | - |
| `$9CBE` | `TitleLiteralCall` | - |
| `$9CC6` | `TitleRun` | - |
| `$9CCC` | `TitleRunCall` | - |
| `$9CD4` | `TitleDone` | - |
| `$9CDB` | `TitlePutByte` | write A to the screen at HL' and step HL' in the stream's order |
| `$9CFA` | `l_9CFA` | - |
| `$9CFB` | `l_9CFB` | - |
| `$9CFD` | `l_9CFD` | - |
| `$9CFF` | `l_9CFF` | - |

### The boot menu and the help (`src/bootmenu/`)

`boot.asm` (`build/bootmenu/bootmenu.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$6060` | `BootInterrupt` | -------------------------------------------------------------------------------------------------------------------- |
| `$61A8` | `Start` | the entry: the tune's init, bank 7's image unpacked, the boot menu |
| `$61C4` | `StartGame` | key 1: the game starter, the game's blocks put together and unpacked, the |
| `$61E2` | `l_61E2` | - |
| `$6249` | `SetPage` | `$7FFD` = A |
| `$6251` | `CopyBank` | copy BC bytes from (HL) in page IXL to (DE) in page IXH |
| `$6267` | `ClearScreen` | zero `$5AFF` down to the first byte that will not take a zero, then wait for a |
| `$626B` | `l_626B` | - |
| `$6273` | `PlaySample` | boot menu key 3 ("NOT used"): 12790 samples from bank 7 through the AY's |
| `$6282` | `l_6282` | - |
| `$62AA` | `l_62AA` | - |
| `$62BC` | `SilenceAy` | the AY's volumes 8-10 to 0, its mixer (register 7) to `$FF` |
| `$62C0` | `l_62C0` | - |

`depack.asm` (`build/bootmenu/bootmenu.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$68C5` | `ScreenDepack` | -------------------------------------------------------------------------------------------------------------------- |
| `$68C8` | `DepackHere` | - |
| `$68DA` | `PatchCalls` | - |
| `$68F3` | `Literal` | - |
| `$68FC` | `NextToken` | - |
| `$6918` | `LengthCode` | - |
| `$6921` | `l_6921` | - |
| `$6934` | `l_6934` | - |
| `$693E` | `ShortDistance` | - |
| `$693F` | `CopyMatch` | - |
| `$6950` | `WordLength` | - |
| `$695C` | `l_695C` | - |
| `$6962` | `l_6962` | - |
| `$6964` | `SetLength` | - |
| `$6965` | `ReadDistance` | - |
| `$696F` | `HighBits` | - |
| `$697A` | `SetHigh` | - |
| `$697E` | `l_697E` | - |
| `$6988` | `l_6988` | - |
| `$6993` | `l_6993` | - |
| `$699A` | `GetBit` | the next bit into A's bit 0 (and the carry out of A's bit 7) |
| `$69A9` | `l_69A9` | - |

`menus.asm` (`build/bootmenu/bootmenu.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$AA69` | `BootMenu` | -------------------------------------------------------------------------------------------------------------------- |
| `$AA8B` | `ShowBootMenu` | the boot menu's picture, the pointer's start, the key loop |
| `$AA9E` | `BootMenuKeys` | - |
| `$AAB1` | `HelpMenu` | the help menu: its picture, the items printed into the bars, the pointer loop |
| `$AB35` | `HelpLoop` | - |
| `$AB51` | `HelpFire` | - |
| `$AB59` | `FindItem` | the item under the pointer: A = 1-7, or `$FF` (CurrentItem then counts 8) |
| `$AB74` | `FindItemNext` | - |
| `$AB92` | `FindItemSkip` | - |
| `$ABA0` | `HighlightItem` | light the bar of item A (or none, `$FF`), the old one put back |
| `$ABB3` | `InvertLit` | This entry point is used by the routine at InvertItem. |
| `$ABB9` | `InvertItem` | swap ink and paper over item A's bar |
| `$ABD2` | `FirstLit` | This entry point is used by the routine at HighlightItem. |
| `$ABD8` | `InvertCells` | swap ink and paper of (IX + 2) cells from column H, row L |
| `$ABFA` | `InvertCellsNext` | - |
| `$ABFF` | `RunItem` | fire: jump to the lit item's routine, dropping the caller (nothing lit: |
| `$AC3A` | `WaitFrames` | ten HALTs: no code calls it |
| `$AC3C` | `WaitFramesNext` | - |
| `$AC40` | `ResetPointerSpeed` | Speed = SpeedStart: the pointer at 1 pixel a frame again |
| `$AC4C` | `MovePointer` | move the pointer by the controls: x first, then y, Speed pixels, clamped |
| `$AC75` | `PointerAcceleration` | A = the controls: speed up while the same controls are held |
| `$AC94` | `StepAxis` | move one coordinate (DE) by Speed's step: C bit 0 set adds, clear subtracts; |
| `$ACA5` | `StepUp` | - |
| `$ACAC` | `ClampAxis` | - |
| `$ACAF` | `DrawPointer` | save the 16 x 2 bytes under the pointer and draw it (mask and image) at |
| `$ACB8` | `l_ACB8` | - |
| `$ACBD` | `l_ACBD` | - |
| `$ACE0` | `SaveUnder` | - |
| `$ACF5` | `l_ACF5` | - |
| `$ACFF` | `DrawLine` | - |
| `$AD0A` | `ShiftLine` | - |
| `$AD22` | `DrawLineNext` | - |
| `$AD32` | `ErasePointer` | put back the bytes DrawPointer saved; PointerAddress then points past the |
| `$AD3A` | `RestoreLine` | - |
| `$AD51` | `NextLineDown` | HL = the screen address one pixel line down |
| `$ADB3` | `ReadControls` | Controls = Q A O P SPACE with 6 7 8 9 0, or with the cursor keys 5 6 7 8 0 |
| `$ADBF` | `MergeControls` | - |
| `$ADC6` | `StoreControls` | This entry point is used by the routine at ReadQaop. |
| `$ADCC` | `CursorControls` | - |
| `$ADD1` | `ReadQaop` | SPACE, Q, A, O, P into C's low five bits (fire, up, down, left, right) |
| `$ADEA` | `LeftRight` | This entry point is used by the routine at ReadSinclairJoystick. |
| `$ADF0` | `LastBit` | This entry point is used by the routine at ReadCursorKeys. |
| `$ADF6` | `ReadCursorKeys` | with CAPS SHIFT: 0 fire, 7 up, 6 down, 5 left, 8 right |
| `$AE13` | `ReadSinclairJoystick` | 0 fire, 9 up, 8 down, 6 left, 7 right (the Sinclair joystick on the keys 6-0) |
| `$AE19` | `SinclairNext` | - |

`help.asm` (`build/bootmenu/bootmenu.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$AE21` | `HelpCredits` | -------------------------------------------------------------------------------------------------------------------- |
| `$AE67` | `HelpFeatures` | help item 5 "Особенности игры": FeaturesPicture, 5 pages |
| `$AED5` | `ShowPage` | type the string at HL, then wait for ENTER / 0 (back) or SPACE (the help |
| `$AEDB` | `HelpDescription` | help item 1 "Описание игры": DescriptionPicture, 5 pages |
| `$AF44` | `HelpProduction` | help item 2 "Производство роботов": ProductionPicture, 4 pages |
| `$AF9A` | `HelpProgramming` | help item 4 "Программирование роботов": ProgrammingPicture, 3 pages |
| `$AFDD` | `HelpComponents` | help item 3 "Характеристика компонентов": a part a page, its picture each |

`print.asm` (`build/bootmenu/bootmenu.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$B086` | `UseLatin` | -------------------------------------------------------------------------------------------------------------------- |
| `$B091` | `UseCyrillic` | code 2: the Cyrillic font from here; A = the next byte, HL on it |
| `$B09C` | `PrintGlyph` | print glyph A at PrintAt, then PrintAt on one column |
| `$B0A0` | `GlyphFont` | - |
| `$B0AC` | `GlyphColumn` | - |
| `$B0BC` | `GlyphHere` | - |
| `$B0C9` | `l_B0C9` | - |
| `$B10D` | `RightHalf` | - |
| `$B13A` | `PrintString` | print the 0-terminated string at HL: codes 1 / 2 the fonts, with TypeAtOnce 0 |
| `$B15D` | `TypeDelay` | - |
| `$B162` | `PrintSkip` | - |
| `$B166` | `PrintEnd` | - |
| `$B168` | `LeaveForGame` | boot menu key 1: the tune from its start, the screen cleared, IM 1, StartGame |
| `$B183` | `WaitPageKey` | ENTER or 0: return (the next page); SPACE: the help menu |

### The game starter and the disk module (`src/disk/`)

`starter.asm` (`build/disk/starter.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$9C40` | `StartPicture` | -------------------------------------------------------------------------------------------------------------------- |
| `$9C47` | `l_9C47` | - |
| `$9C5C` | `l_9C5C` | - |
| `$9C73` | `FillColour` | Every attribute and the border from the colour at HL; two frames |

`setup.asm` (`build/disk/diskio.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$C000` | `Setup` | -------------------------------------------------------------------------------------------------------------------- |
| `$C023` | `SetRomState` | The ROM's interrupt state and registers, a silent AY, the text colours, the |
| `$C037` | `SilenceAy` | - |

`diskmod.asm` (`build/disk/diskio.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$4000` | `LoadEntry` | -------------------------------------------------------------------------------------------------------------------- |
| `$401B` | `LoadLeave` | - |
| `$402D` | `LoadExit` | - |
| `$4033` | `SaveEntry` | Save the game: the save screen, the name, `$D92B`-`$FFFF` to the file "name.N", |
| `$404E` | `SaveLeave` | - |
| `$4060` | `SaveExit` | - |
| `$4066` | `PrintLoadScreen` | The load screen's three lines, the name prompt and the rule (rows 17-21) |
| `$4085` | `PrintSaveScreen` | The save screen's three lines, the name prompt and the rule (rows 17-21) |
| `$425C` | `GetKey` | Wait for a new key from the ROM's IM 1 scan: A = LAST_K |
| `$4261` | `GetKeyWait` | - |
| `$426D` | `InputName` | Read the file name: up to 8 characters at column 32 of row 20; ENTER ends, |
| `$42B3` | `NameCancel` | - |
| `$42BD` | `BlankName` | - |
| `$42CC` | `NameEnter` | NameEnter |
| `$42EC` | `NameDelete` | This entry point is used by the routine at InputName. |
| `$4316` | `NameBack` | - |
| `$4319` | `NameRubOut` | - |
| `$4337` | `ClearRow` | Clear C bytes of a character row from HL (8 pixel lines) |
| `$433A` | `ClearRowLine` | - |
| `$434C` | `NextPixelLine` | HL one pixel line down the screen |
| `$435B` | `Load` | "Loading...", the file, then "Loading...OK" or "Loading had errors !!!" |
| `$4379` | `LoadOk` | - |
| `$4387` | `SetOk` | SetOk |
| `$438D` | `FindFile` | Read the catalogue and find "name.N": its 16-byte entry into File |
| `$43B7` | `FindCount` | - |
| `$43B9` | `FindEntry` | - |
| `$43C2` | `FindCompare` | - |
| `$43D7` | `FindNext` | - |
| `$43F6` | `SectorCount` | File's sector count from HL: the length rounded up to whole sectors |
| `$4400` | `SectorCountLoop` | - |
| `$4407` | `SectorCountDone` | - |
| `$440B` | `LoadFile` | Load the file: the disk, the catalogue, the sectors into the file's start |
| `$4416` | `LoadDiskThere` | - |
| `$4434` | `DiskDone` | DiskDone |
| `$443F` | `CheckDisk` | Is a disk spinning? NZ (and A = the status bits) when it is, else "No disk !" |
| `$4455` | `CheckDiskLoop` | - |
| `$4479` | `ReadStatus` | A = the WD1793's status AND `$42` (write protect, index), through TR-DOS's |
| `$448F` | `DiskThere` | This entry point is used by the routine at CheckDisk. |
| `$4493` | `ReadSectors` | Read B sectors from logical track D, sector E (0-15) to HL |
| `$449B` | `OutCommand` | A to the WD1793's command register (`$1F`) |
| `$449D` | `OutPort` | OutPort |
| `$44A1` | `RomCall` | RomCall |
| `$44A6` | `ReadSector` | This entry point is used by the routines at ReadSectors and ReadSectorEnd. |
| `$44C3` | `ReadSectorEnd` | ReadSectorEnd |
| `$44CB` | `ReadTries` | - |
| `$44EF` | `LoadErrorKey` | - |
| `$450D` | `LoadRetry` | - |
| `$4529` | `LoadAbort` | - |
| `$4531` | `NextSector` | - |
| `$4537` | `NextSectorOn` | - |
| `$454E` | `Seek` | The head to logical track A: physical track A / 2, side from D bit 0 |
| `$4560` | `SeekSide` | - |
| `$4574` | `Restore` | Reset the WD1793 and give the track register back its track |
| `$457C` | `RestoreReset` | - |
| `$4598` | `WaitKey` | Wait until a key is held (any half row) |
| `$45B2` | `PrintText` | Print the record at HL: a column (0-63), a row (0-23), characters to `$FF` |
| `$45C2` | `PrintTextLoop` | - |
| `$45CF` | `PrintTextEnd` | - |
| `$45D6` | `PrintChar` | Print the character A at Column, Row in the module's half-width font; Column |
| `$45E6` | `PrintCharPlace` | - |
| `$45F5` | `PrintCharNext` | - |
| `$4602` | `PrintCharRow` | - |
| `$464C` | `PrintRight` | - |
| `$47A4` | `Save` | "Saving...", the file, then "Saving...OK" or "Saving had errors !!!" |
| `$47C8` | `SaveOk` | - |
| `$47D9` | `SaveFile` | Save the file: the disk, write protect, then WriteFile |
| `$47E8` | `SaveDiskThere` | - |
| `$4803` | `SaveWritable` | - |
| `$480C` | `WriteFile` | Write the file's sectors at the disk's first free sector and its catalogue |
| `$4842` | `CatRoom` | - |
| `$486C` | `DiskRoom` | - |
| `$48BD` | `EntryPlaceLoop` | - |
| `$48C4` | `EntryPlace` | - |
| `$4902` | `WriteSectors` | Write B sectors from HL to logical track D, sector E (0-15) |
| `$4908` | `WriteSector` | This entry point is used by the routine at WriteSectorEnd. |
| `$4930` | `WriteSectorEnd` | WriteSectorEnd |
| `$4938` | `WriteTries` | - |
| `$495C` | `SaveErrorKey` | - |
| `$497A` | `SaveRetry` | - |
| `$4995` | `SaveAbort` | - |
| `$499D` | `NextWriteSector` | - |
| `$49A3` | `NextWriteSectorOn` | - |
| `$49B5` | `WaitFrames` | 29 frames with interrupts on |
| `$49B8` | `WaitFramesLoop` | - |
| `$49BF` | `SetPage` | A to port `$7FFD` (keeps BC) |

### The music: players, tunes, title cards (`src/music/`)

`stp-player.asm` (`build/music/music-bank1.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$C000` | `Init` | ===================================================================================================================== |
| `$C005` | `Play` | - |
| `$C008` | `InitAt` | InitAt: start the module at HL (compiled: its sample, ornament and channel pointers absolute, the pattern table |
| `$C05E` | `InitClearRegs` | - |
| `$C069` | `InitClearState` | - |
| `$C0A4` | `InitSetOut` | - |
| `$C0AB` | `NextPosition` | NextPosition: step to the next entry of the position list (after its end marker `$FF`: the loop position). |
| `$C0AF` | `PositionPtr` | - |
| `$C0B6` | `LoopPosition` | - |
| `$C0BB` | `NextPositionTake` | - |
| `$C0C5` | `PatternTable` | - |
| `$C0D4` | `NextPositionSp` | - |
| `$C0D8` | `ChannelTone` | ChannelTone: one tick of a channel's sample and ornament. In: HL = the sample's data, E = the sample position, |
| `$C0E5` | `ChannelToneMask` | - |
| `$C0FD` | `ChannelToneOffset` | - |
| `$C109` | `OrnamentData` | - |
| `$C121` | `ChannelToneAdd` | - |
| `$C123` | `ChAOff` | ----------------------------------------------------------------------------------------------------------------- |
| `$C128` | `ChAPos` | - |
| `$C12B` | `ChASample` | - |
| `$C12E` | `ChAOrnament` | - |
| `$C138` | `ChAOrnamentNext` | - |
| `$C148` | `ChASampleNext` | - |
| `$C14C` | `ChANote` | - |
| `$C14F` | `ChANoise` | - |
| `$C154` | `ChASlide` | - |
| `$C15C` | `ChASlideMode` | - |
| `$C166` | `ChAPortaLeft` | - |
| `$C170` | `ChAPortaStep` | - |
| `$C177` | `ChAPortaNote` | - |
| `$C187` | `ChAPortaGo` | - |
| `$C18B` | `ChASlideSign` | - |
| `$C191` | `ChAMix` | - |
| `$C198` | `ChAVolume` | - |
| `$C19D` | `ChAEnvelope` | - |
| `$C19F` | `ChAVolumeSet` | - |
| `$C1A2` | `ChBOff` | channel B's tick |
| `$C1A7` | `ChBPos` | - |
| `$C1AA` | `ChBSample` | - |
| `$C1AD` | `ChBOrnament` | - |
| `$C1B7` | `ChBOrnamentNext` | - |
| `$C1C7` | `ChBSampleNext` | - |
| `$C1CB` | `ChBNote` | - |
| `$C1CE` | `ChBNoise` | - |
| `$C1D3` | `ChBSlide` | - |
| `$C1DB` | `ChBSlideMode` | - |
| `$C1E5` | `ChBPortaLeft` | - |
| `$C1EF` | `ChBPortaStep` | - |
| `$C1F6` | `ChBPortaNote` | - |
| `$C206` | `ChBPortaGo` | - |
| `$C20A` | `ChBSlideSign` | - |
| `$C210` | `ChBMix` | - |
| `$C21A` | `ChBVolume` | - |
| `$C21F` | `ChBEnvelope` | - |
| `$C221` | `ChBVolumeSet` | - |
| `$C224` | `ChCOff` | channel C's tick |
| `$C229` | `ChCPos` | - |
| `$C22C` | `ChCSample` | - |
| `$C22F` | `ChCOrnament` | - |
| `$C239` | `ChCOrnamentNext` | - |
| `$C249` | `ChCSampleNext` | - |
| `$C24D` | `ChCNote` | - |
| `$C250` | `ChCNoise` | - |
| `$C255` | `ChCSlide` | - |
| `$C25D` | `ChCSlideMode` | - |
| `$C267` | `ChCPortaLeft` | - |
| `$C271` | `ChCPortaStep` | - |
| `$C277` | `ChCPortaNote` | - |
| `$C288` | `ChCPortaGo` | - |
| `$C28C` | `ChCSlideSign` | - |
| `$C292` | `ChCMix` | - |
| `$C29D` | `ChCVolume` | - |
| `$C2A2` | `ChCEnvelope` | - |
| `$C2A4` | `ChCVolumeSet` | - |
| `$C2A7` | `WriteAy` | WriteAy: the copies to the AY, from AyEnvShape down when a shape was set this row (AyEnvShape not 0), else |
| `$C2B3` | `AyOutVector` | - |
| `$C2B6` | `PlayFrame` | PlayFrame: the rows are read in turns: on tick 3 of a row channel A's, tick 2 channel B's, tick 1 channel C's |
| `$C2B9` | `TickCount` | - |
| `$C2CF` | `ChARowReload` | - |
| `$C2D1` | `ChAPattern` | - |
| `$C2E6` | `PlayRowB` | - |
| `$C2ED` | `ChBRowReload` | - |
| `$C2EF` | `ChBPattern` | - |
| `$C2FF` | `PlayRowC` | - |
| `$C306` | `ChCRowReload` | - |
| `$C308` | `ChCPattern` | - |
| `$C312` | `ApplyPending` | ApplyPending: channels A and B's rows, read two and one ticks ago, take effect now. Each change is gated by an |
| `$C313` | `ChANewNote` | - |
| `$C324` | `ChANewOff` | - |
| `$C328` | `ChANextNote` | - |
| `$C32D` | `ChANextSample` | - |
| `$C334` | `ChANewParams` | - |
| `$C33A` | `ChANextEnvelope` | - |
| `$C33F` | `ChANextNoise` | - |
| `$C344` | `ChANextVolume` | - |
| `$C34B` | `ChANewOrnament` | - |
| `$C354` | `ChANextOrnament` | - |
| `$C35B` | `ChANewSlide` | - |
| `$C361` | `ChANextPortaNote` | - |
| `$C366` | `ChANextPortaLeft` | - |
| `$C36C` | `ChANextSlideSign` | - |
| `$C371` | `ChANextSlideMode` | - |
| `$C378` | `ChBNewNote` | - |
| `$C389` | `ChBNewOff` | - |
| `$C38D` | `ChBNextNote` | - |
| `$C392` | `ChBNextSample` | - |
| `$C399` | `ChBNewParams` | - |
| `$C39F` | `ChBNextEnvelope` | - |
| `$C3A4` | `ChBNextNoise` | - |
| `$C3A9` | `ChBNextVolume` | - |
| `$C3B0` | `ChBNewOrnament` | - |
| `$C3B9` | `ChBNextOrnament` | - |
| `$C3C0` | `ChBNewSlide` | - |
| `$C3C6` | `ChBNextPortaLeft` | - |
| `$C3CC` | `ChBNextPortaNote` | - |
| `$C3D1` | `ChBNextSlideSign` | - |
| `$C3D6` | `ChBNextSlideMode` | - |
| `$C3DC` | `NextEnvShape` | - |
| `$C3E1` | `NextEnvPeriod` | - |
| `$C3E7` | `Speed` | - |
| `$C3F3` | `ChANotePorta` | ChANotePorta: a note after a glissando (`$0E`) or portamento (`$0D`) command. Glissando: the note plays and slides. |
| `$C401` | `ChANotePortaSet` | - |
| `$C40A` | `ChASetNote` | ChASetNote (`$80`-`$DF`, note 0-95): the row's note; A' (parameters changed) goes to ChANewParams. Out: A = `$37` |
| `$C423` | `ChASetVolume` | ChASetVolume (`$10`-`$1F`): the channel volume's row of VolumeTable |
| `$C435` | `ChAGliss` | ChAGliss (`$0E`, step): glissando, the tone slides by the step every tick |
| `$C448` | `ChAGlissSign` | - |
| `$C44E` | `ChAPortamento` | ChAPortamento (`$0D`, step, distance word): portamento to the next note |
| `$C45C` | `ChAPortaSign` | - |
| `$C46B` | `ChASetNoise` | ChASetNoise (`$01`-`$0B`, value): the noise base |
| `$C475` | `ChASkip` | ChASkip (`$20`-`$5F`): the rows to skip after each row of this channel, 0-63 |
| `$C47B` | `ChADecode` | ----------------------------------------------------------------------------------------------------------------- |
| `$C4AC` | `ChASampleOrOff` | - |
| `$C4AE` | `ChASampleTable` | - |
| `$C4BE` | `ChAOrnamentTable` | - |
| `$C4D3` | `ChANoteOff` | ChANoteOff (`$E0`) |
| `$C4DF` | `ChAEmptyRow` | ChAEmptyRow (`$70`): no note this row; A = `$A7` (AND A) for ChANewNote |
| `$C4E6` | `ChAEnvelopeOff` | ChAEnvelopeOff (`$7F`) |
| `$C4F0` | `ChAEnvelopeOn` | ChAEnvelopeOn (`$71`-`$7E`, period word): the envelope shape and period, the channel's volume on the envelope |
| `$C50E` | `ChASpeed` | ChASpeed (`$0F`, delay) |
| `$C516` | `ChBNotePorta` | channel B's commands: the same as channel A's, with its own operands |
| `$C525` | `ChBNotePortaSet` | - |
| `$C52E` | `ChBSetNote` | - |
| `$C547` | `ChBSetVolume` | - |
| `$C559` | `ChBGliss` | - |
| `$C56C` | `ChBGlissSign` | - |
| `$C572` | `ChBPortamento` | - |
| `$C580` | `ChBPortaSign` | - |
| `$C58F` | `ChBSetNoise` | - |
| `$C599` | `ChBSkip` | - |
| `$C59F` | `ChBDecode` | - |
| `$C5D0` | `ChBSampleOrOff` | - |
| `$C5D2` | `ChBSampleTable` | - |
| `$C5E2` | `ChBOrnamentTable` | - |
| `$C5F7` | `ChBNoteOff` | - |
| `$C603` | `ChBEmptyRow` | - |
| `$C60A` | `ChBEnvelopeOff` | - |
| `$C614` | `ChBEnvelopeOn` | - |
| `$C632` | `ChBSpeed` | - |
| `$C63A` | `ChCSetNote` | channel C's commands: read on the apply tick, so they set the tick's operands at once (no pending copies) |
| `$C64D` | `ChCNotePorta` | - |
| `$C65C` | `ChCNoteStart` | - |
| `$C668` | `ChCGliss` | - |
| `$C676` | `ChCGlissSign` | - |
| `$C67C` | `ChCPortamento` | - |
| `$C68A` | `ChCPortaSign` | - |
| `$C699` | `ChCSetNoise` | - |
| `$C6A0` | `ChCSkip` | - |
| `$C6A6` | `ChCDecode` | - |
| `$C6D2` | `ChCSampleOrOff` | - |
| `$C6D4` | `ChCSampleTable` | - |
| `$C6E4` | `ChCOrnamentTable` | - |
| `$C6F8` | `ChCNoteOff` | - |
| `$C6FE` | `ChCEnvelopeOn` | - |
| `$C718` | `ChCEnvelopeOff` | - |
| `$C71F` | `ChCSpeed` | - |
| `$C727` | `ChCSetVolume` | - |
| `$C736` | `AyOut` | AyOut: the AY copies to the AY, R13 (the envelope shape) down to R0 when NZ, else R10 down to R0 (the shape |
| `$C741` | `AyOutFrom13` | - |
| `$C756` | `AyOutFrom10` | - |
| `$C795` | `AyOutLast2` | - |
| `$C7A9` | `AyOutSwapBC` | AyOutSwapBC: the same with channels B and C swapped (ACB): volumes, tones and the mixer bits; not used here |
| `$C7B1` | `AyOutSwapFrom13` | - |
| `$C7C6` | `AyOutSwapFrom10` | - |

`title-cards.asm` (`build/music/music-bank1.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$D8E1` | `TitleCards` | ===================================================================================================================== |
| `$D8F2` | `TitleCardsClear` | the first byte that does not keep 0 (the ROM's last byte, `$3FFF`) |
| `$D952` | `ClearPixels` | ClearPixels: the screen's pixels (`$4000`-`$57FF`) to 0 |
| `$D95F` | `Wait80` | Wait80: 80 frames |
| `$D961` | `Wait80Loop` | - |
| `$D965` | `DrawBitmap` | DrawBitmap: HL = the bitmap (its pixel lines in order), DE = the screen address of its top left, B = the lines, |
| `$D973` | `NextLine` | NextLine: DE = the screen address one pixel line down |
| `$D982` | `FadeAttributes` | FadeAttributes: HL = 8 attribute values; each in turn fills the whole attribute area (`$5800`-`$5AFF`), two frames |
| `$D984` | `FadeAttributesStep` | - |

`boot-music.asm` (`build/music/boot-music.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$C000` | `BootMusic` | - |

`pt3-player.asm` (`build/music/boot-music.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$C02C` | `InitModule` | --------------------------------------------------------------------------------------------------------------------- |
| `$C047` | `InitPositions` | - |
| `$C05E` | `InitPatterns` | - |
| `$C06A` | `InitPointerLoop` | - |
| `$C06B` | `InitPointerBase` | - |
| `$C078` | `InitSp` | - |
| `$C30E` | `InitState` | --------------------------------------------------------------------------------------------------------------------- |
| `$C340` | `Pt3Stop` | --------------------------------------------------------------------------------------------------------------------- |
| `$C358` | `Pt3Play` | --------------------------------------------------------------------------------------------------------------------- |
| `$C35B` | `NoiseMixer` | - |
| `$C363` | `ChAMute` | --------------------------------------------------------------------------------------------------------------------- |
| `$C36A` | `ChASamplePtr` | - |
| `$C36E` | `ChASamplePos` | - |
| `$C376` | `ChASampleStep` | - |
| `$C39A` | `ChAVolSlideUp` | - |
| `$C3A0` | `ChAVolSlideSet` | - |
| `$C3A3` | `ChAVolSlide` | - |
| `$C3AD` | `ChALevelHigh` | - |
| `$C3B3` | `ChAVolume` | - |
| `$C3BF` | `ChAEnvMask` | - |
| `$C3C8` | `ChANoiseAcc` | - |
| `$C3D2` | `ChANoiseSet` | - |
| `$C3D8` | `ChAEnvOffset` | - |
| `$C3E2` | `ChAEnvOffsetAcc` | - |
| `$C3EB` | `ChAEnvOffsetAdd` | - |
| `$C3F0` | `ChAMixer` | - |
| `$C3F9` | `ChAToneAcc` | - |
| `$C404` | `ChAOrnament` | - |
| `$C405` | `ChAOrnamentPtr` | - |
| `$C409` | `ChAOrnamentPos` | - |
| `$C411` | `ChAOrnamentStep` | - |
| `$C41A` | `ChANote` | - |
| `$C422` | `ChAToneSlide` | - |
| `$C429` | `ChAGlissCount` | - |
| `$C431` | `ChAGlissStep` | - |
| `$C438` | `ChAPortaJr` | - |
| `$C43B` | `ChAPortaDistance` | - |
| `$C444` | `ChAPortaSub` | - |
| `$C446` | `ChAPortaTest` | - |
| `$C449` | `ChAPortaNote` | - |
| `$C459` | `ChAGlissReload` | - |
| `$C45B` | `ChAGlissStore` | - |
| `$C45E` | `ChATickEnd` | - |
| `$C45F` | `ChAStoreVolume` | - |
| `$C462` | `ChAOnOffCount` | - |
| `$C475` | `ChAOffTime` | - |
| `$C47A` | `ChAOnTime` | - |
| `$C47C` | `ChAOnOffStore` | - |
| `$C47F` | `ChBMute` | --------------------------------------------------------------------------------------------------------------------- |
| `$C486` | `ChBSamplePtr` | - |
| `$C48A` | `ChBSamplePos` | - |
| `$C492` | `ChBSampleStep` | - |
| `$C4B6` | `ChBVolSlideUp` | - |
| `$C4BC` | `ChBVolSlideSet` | - |
| `$C4BF` | `ChBVolSlide` | - |
| `$C4C9` | `ChBLevelHigh` | - |
| `$C4CF` | `ChBVolume` | - |
| `$C4DB` | `ChBEnvMask` | - |
| `$C4E4` | `ChBNoiseAcc` | - |
| `$C4EE` | `ChBNoiseSet` | - |
| `$C4F4` | `ChBEnvOffset` | - |
| `$C4FE` | `ChBEnvOffsetAcc` | - |
| `$C507` | `ChBEnvOffsetAdd` | - |
| `$C50C` | `ChBMixer` | - |
| `$C518` | `ChBToneAcc` | - |
| `$C523` | `ChBOrnament` | - |
| `$C524` | `ChBOrnamentPtr` | - |
| `$C528` | `ChBOrnamentPos` | - |
| `$C530` | `ChBOrnamentStep` | - |
| `$C539` | `ChBNote` | - |
| `$C541` | `ChBToneSlide` | - |
| `$C548` | `ChBGlissCount` | - |
| `$C550` | `ChBGlissStep` | - |
| `$C557` | `ChBPortaJr` | - |
| `$C55A` | `ChBPortaDistance` | - |
| `$C563` | `ChBPortaSub` | - |
| `$C565` | `ChBPortaTest` | - |
| `$C568` | `ChBPortaNote` | - |
| `$C578` | `ChBGlissReload` | - |
| `$C57A` | `ChBGlissStore` | - |
| `$C57D` | `ChBTickEnd` | - |
| `$C57E` | `ChBStoreVolume` | - |
| `$C581` | `ChBOnOffCount` | - |
| `$C594` | `ChBOffTime` | - |
| `$C599` | `ChBOnTime` | - |
| `$C59B` | `ChBOnOffStore` | - |
| `$C59E` | `ChCMute` | --------------------------------------------------------------------------------------------------------------------- |
| `$C5A5` | `ChCSamplePtr` | - |
| `$C5A9` | `ChCSamplePos` | - |
| `$C5B1` | `ChCSampleStep` | - |
| `$C5D5` | `ChCVolSlideUp` | - |
| `$C5DB` | `ChCVolSlideSet` | - |
| `$C5DE` | `ChCVolSlide` | - |
| `$C5E8` | `ChCLevelHigh` | - |
| `$C5EE` | `ChCVolume` | - |
| `$C5FA` | `ChCEnvMask` | - |
| `$C603` | `ChCNoiseAcc` | - |
| `$C60D` | `ChCNoiseSet` | - |
| `$C613` | `ChCEnvOffset` | - |
| `$C61D` | `ChCEnvOffsetAcc` | - |
| `$C626` | `ChCEnvOffsetAdd` | - |
| `$C62B` | `ChCMixer` | - |
| `$C636` | `ChCToneAcc` | - |
| `$C641` | `ChCOrnament` | - |
| `$C642` | `ChCOrnamentPtr` | - |
| `$C646` | `ChCOrnamentPos` | - |
| `$C64E` | `ChCOrnamentStep` | - |
| `$C657` | `ChCNote` | - |
| `$C65F` | `ChCToneSlide` | - |
| `$C666` | `ChCGlissCount` | - |
| `$C66E` | `ChCGlissStep` | - |
| `$C675` | `ChCPortaJr` | - |
| `$C678` | `ChCPortaDistance` | - |
| `$C682` | `ChCPortaAdd` | - |
| `$C683` | `ChCPortaTest` | - |
| `$C686` | `ChCPortaNote` | - |
| `$C696` | `ChCGlissReload` | - |
| `$C698` | `ChCGlissStore` | - |
| `$C69B` | `ChCTickEnd` | - |
| `$C69C` | `ChCStoreVolume` | - |
| `$C69F` | `ChCOnOffCount` | - |
| `$C6B2` | `ChCOffTime` | - |
| `$C6B7` | `ChCOnTime` | - |
| `$C6B9` | `ChCOnOffStore` | - |
| `$C6BC` | `EnvSlideAcc` | --------------------------------------------------------------------------------------------------------------------- |
| `$C6BF` | `EnvPeriod` | - |
| `$C6CA` | `EnvSlideCount` | - |
| `$C6D2` | `EnvSlideStep` | - |
| `$C6D9` | `EnvSlideReload` | - |
| `$C6DB` | `EnvSlideStore` | - |
| `$C6DE` | `PlaySp` | - |
| `$C6E1` | `WriteAy` | --------------------------------------------------------------------------------------------------------------------- |
| `$C715` | `NoiseBase` | - |
| `$C742` | `EnvType` | - |
| `$C751` | `RestoreIy` | --------------------------------------------------------------------------------------------------------------------- |
| `$C754` | `RowFrame` | - |
| `$C763` | `ChARowSkip` | --------------------------------------------------------------------------------------------------------------------- |
| `$C783` | `ChAPatternPtr` | - |
| `$C78E` | `PositionPtr` | - |
| `$C795` | `LoopPositionPtr` | - |
| `$C79A` | `PositionStep` | - |
| `$C7A4` | `PatternTable` | - |
| `$C7AA` | `ModuleAddr` | - |
| `$C7B9` | `PositionSp` | - |
| `$C7BC` | `ChAReadRow` | - |
| `$C7C3` | `ChARowSkipLen` | - |
| `$C7DA` | `ChADecode` | --------------------------------------------------------------------------------------------------------------------- |
| `$C7DC` | `ChADecodeLimits` | - |
| `$C7DF` | `ChADecodeByte` | - |
| `$C814` | `ChAEffGliss` | --------------------------------------------------------------------------------------------------------------------- |
| `$C82C` | `ChAEffPorta` | - |
| `$C855` | `ChAEffSampleOffset` | - |
| `$C860` | `ChAEffOrnOffset` | - |
| `$C86B` | `ChAEffOnOff` | - |
| `$C87B` | `EffEnvSlide` | - |
| `$C88F` | `EffDelay` | - |
| `$C895` | `ChAOrnSampleCmd` | --------------------------------------------------------------------------------------------------------------------- |
| `$C8B6` | `ChASampleCmd` | - |
| `$C8C6` | `ChARowEnd` | - |
| `$C8C7` | `ChASoundOff` | - |
| `$C8D0` | `ChAEnvOff` | - |
| `$C8D9` | `ChASkipCmd` | - |
| `$C8E1` | `ChAVolumeCmd` | - |
| `$C8F0` | `ChAEnvCmd` | - |
| `$C90C` | `ChANoteCmd` | - |
| `$C917` | `ChAOrnamentCmd` | - |
| `$C927` | `ChAEnvOffSample` | - |
| `$C92F` | `ChAEnvSampleCmd` | - |
| `$C943` | `ChAEnvSampleSet` | - |
| `$C954` | `ChBRowSkip` | --------------------------------------------------------------------------------------------------------------------- |
| `$C974` | `ChBPatternPtr` | - |
| `$C97E` | `ChBRowSkipLen` | - |
| `$C995` | `ChBDecode` | --------------------------------------------------------------------------------------------------------------------- |
| `$C997` | `ChBDecodeLimits` | - |
| `$C99A` | `ChBDecodeByte` | - |
| `$C9D2` | `ChBEffGliss` | --------------------------------------------------------------------------------------------------------------------- |
| `$C9EA` | `ChBEffPorta` | - |
| `$CA13` | `ChBEffSampleOffset` | - |
| `$CA1E` | `ChBEffOrnOffset` | - |
| `$CA29` | `ChBEffOnOff` | - |
| `$CA39` | `ChBNoiseCmd` | --------------------------------------------------------------------------------------------------------------------- |
| `$CA3F` | `ChBOrnSampleCmd` | - |
| `$CA60` | `ChBSampleCmd` | - |
| `$CA70` | `ChBRowEnd` | - |
| `$CA71` | `ChBSoundOff` | - |
| `$CA7A` | `ChBEnvOff` | - |
| `$CA83` | `ChBSkipCmd` | - |
| `$CA8B` | `ChBVolumeCmd` | - |
| `$CA9A` | `ChBEnvCmd` | - |
| `$CAB6` | `ChBNoteCmd` | - |
| `$CAC1` | `ChBOrnamentCmd` | - |
| `$CAD1` | `ChBEnvOffSample` | - |
| `$CAD9` | `ChBEnvSampleCmd` | - |
| `$CAED` | `ChBEnvSampleSet` | - |
| `$CAFE` | `ChCRowSkip` | --------------------------------------------------------------------------------------------------------------------- |
| `$CB07` | `ChCPatternPtr` | - |
| `$CB11` | `ChCRowSkipLen` | - |
| `$CB16` | `ChANewNoteJr` | --------------------------------------------------------------------------------------------------------------------- |
| `$CB36` | `ChANoteOnOp` | - |
| `$CB3A` | `ChANewNote` | - |
| `$CB3F` | `ChANewSample` | - |
| `$CB45` | `ChAVolumeJr` | - |
| `$CB47` | `ChANewVolume` | - |
| `$CB4C` | `ChAOrnEnvJr` | - |
| `$CB5A` | `ChANewOrnament` | - |
| `$CB60` | `ChANewEnvMask` | - |
| `$CB65` | `ChAGlissJr` | - |
| `$CB67` | `ChANewPortaNote` | - |
| `$CB6C` | `ChANewGlissDelay` | - |
| `$CB74` | `ChANewPortaDistance` | - |
| `$CB7A` | `ChANewGlissStep` | - |
| `$CB80` | `ChANewPortaJr` | - |
| `$CB89` | `ChAOnOffJp` | - |
| `$CB8C` | `ChAOnOffApply` | - |
| `$CB9A` | `ChANewOnTime` | - |
| `$CBA2` | `ChANewOffTime` | - |
| `$CBA7` | `ChBNewNoteJr` | --------------------------------------------------------------------------------------------------------------------- |
| `$CBC7` | `ChBNoteOnOp` | - |
| `$CBCB` | `ChBNewNote` | - |
| `$CBD0` | `ChBNewSample` | - |
| `$CBD6` | `ChBVolumeJr` | - |
| `$CBD8` | `ChBNewVolume` | - |
| `$CBDD` | `ChBOrnEnvJr` | - |
| `$CBEB` | `ChBNewOrnament` | - |
| `$CBF1` | `ChBNewEnvMask` | - |
| `$CBF6` | `ChBGlissJr` | - |
| `$CBF8` | `ChBNewPortaNote` | - |
| `$CBFD` | `ChBNewGlissDelay` | - |
| `$CC05` | `ChBNewPortaDistance` | - |
| `$CC0B` | `ChBNewGlissStep` | - |
| `$CC11` | `ChBNewPortaJr` | - |
| `$CC1A` | `ChBOnOffJp` | - |
| `$CC1D` | `ChBNewOnTime` | - |
| `$CC25` | `ChBNewOffTime` | - |
| `$CC38` | `EnvSlideJr` | --------------------------------------------------------------------------------------------------------------------- |
| `$CC3A` | `NewEnvSlideStep` | - |
| `$CC40` | `NewEnvSlideDelay` | - |
| `$CC4D` | `ChASampleOffJp` | - |
| `$CC50` | `ChANewSamplePos` | - |
| `$CC5A` | `ChAOrnOffJp` | - |
| `$CC5D` | `ChANewOrnamentPos` | - |
| `$CC67` | `ChBSampleOffJp` | - |
| `$CC6A` | `ChBNewSamplePos` | - |
| `$CC74` | `ChBOrnOffJp` | - |
| `$CC77` | `ChBNewOrnamentPos` | - |
| `$CC81` | `NewEnvType` | - |
| `$CC89` | `NewEnvPeriod` | - |
| `$CC93` | `Delay` | - |
| `$CC98` | `NewNoiseBase` | - |
| `$CC9D` | `RowCounter` | - |
| `$CCA5` | `ChCDecode` | --------------------------------------------------------------------------------------------------------------------- |
| `$CCA7` | `ChCDecodeLimits` | - |
| `$CCAA` | `ChCDecodeByte` | - |
| `$CCDF` | `ChCEffGliss` | --------------------------------------------------------------------------------------------------------------------- |
| `$CCFB` | `ChCEffPorta` | - |
| `$CD29` | `ChCEffSampleOffset` | - |
| `$CD2F` | `ChCEffOrnOffset` | - |
| `$CD35` | `ChCEffOnOff` | - |
| `$CD4C` | `ChCOrnSampleCmd` | --------------------------------------------------------------------------------------------------------------------- |
| `$CD6F` | `ChCSampleCmd` | - |
| `$CD7F` | `ChCRowEnd` | - |
| `$CD80` | `ChCSoundOff` | - |
| `$CD89` | `ChCEnvOff` | - |
| `$CD91` | `ChCSkipCmd` | - |
| `$CD99` | `ChCVolumeCmd` | - |
| `$CDA5` | `ChCEnvCmd` | - |
| `$CDBF` | `ChCNoteCmd` | - |
| `$CDE4` | `ChCOrnamentCmd` | - |
| `$CDF6` | `ChCEnvOffSample` | - |
| `$CDFE` | `ChCEnvSampleCmd` | - |
| `$CE12` | `ChCEnvSampleSet` | - |

### The endings (`src/endings/`)

`deadend.asm` (`build/endings/deadend.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$D2EF` | `DeadEnd` | -------------------------------------------------------------------------------------------------------------------- |
| `$D311` | `DeadEndKey` | - |
| `$D323` | `DeadEndStars` | - |
| `$D348` | `ClearScreen` | clear the screen (pixels and attributes) to 0 |
| `$D34C` | `ClearScreenLoop` | - |
| `$D352` | `StarsSave` | save the screen byte under each of the 120 stars |
| `$D360` | `StarsSaveLoop` | - |
| `$D3BF` | `StarsRestore` | put the saved bytes back under the 120 stars |
| `$D3CD` | `StarsRestoreLoop` | - |
| `$D42C` | `StarsDraw` | OR each layer's pixel into its 30 stars |
| `$D456` | `StarsMove` | move the four layers: 1, 2, 4 and 8 pixels right a frame |
| `$D463` | `StarsMask2` | - |
| `$D471` | `StarsMask3` | - |
| `$D484` | `StarsMask4` | - |
| `$D48D` | `StarsStep` | move the 30 stars at HL one byte right |
| `$D493` | `StarsStepLoop` | - |
| `$D4F1` | `StarsRet` | restore SP and return |
| `$D4F5` | `StarsPlot` | OR the mask A into the 30 screen bytes whose addresses are at HL |
| `$D4FF` | `StarsPlotLoop` | - |

`lzscreen.asm` (`build/endings/deadend.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$D723` | `LzScreen` | -------------------------------------------------------------------------------------------------------------------- |
| `$D727` | `LzHere` | - |
| `$D757` | `LzToken` | - |
| `$D771` | `LzMatchByte` | - |
| `$D78B` | `LzMatchRead` | - |
| `$D78C` | `LzMatchCall` | - |
| `$D796` | `LzNotMatch` | - |
| `$D7A0` | `LzLiteralByte` | - |
| `$D7A1` | `LzLiteralCall` | - |
| `$D7A9` | `LzRun` | - |
| `$D7AF` | `LzRunCall` | - |
| `$D7B7` | `LzEnd` | - |
| `$D7BE` | `LzPutByte` | the byte A to the screen in the depacker's order |
| `$D7DD` | `LzPutAttr` | - |
| `$D7DE` | `LzPutCells` | - |
| `$D7E0` | `LzPutLines` | - |
| `$D7E2` | `LzPutDone` | - |

`gameover.asm` (`build/endings/deadend.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$E4A7` | `HrustScreen` | -------------------------------------------------------------------------------------------------------------------- |
| `$E4AA` | `HrustHere` | - |
| `$E4BD` | `HrustPatchCalls` | - |
| `$E4D6` | `HrustLiteral` | - |
| `$E4DF` | `HrustNextToken` | - |
| `$E4FB` | `HrustLengthCode` | - |
| `$E504` | `HrustNotTwo` | - |
| `$E517` | `HrustByteLength` | - |
| `$E521` | `HrustCopyFar` | - |
| `$E522` | `HrustCopyMatch` | - |
| `$E533` | `HrustWordLength` | - |
| `$E53F` | `HrustLongCode` | - |
| `$E545` | `HrustCodeShort` | - |
| `$E547` | `HrustSetLength` | - |
| `$E548` | `HrustReadDistance` | - |
| `$E552` | `HrustHighBits` | - |
| `$E55D` | `HrustSetHigh` | - |
| `$E561` | `HrustHigh3` | - |
| `$E56B` | `HrustHigh7` | - |
| `$E576` | `HrustHigh14` | - |
| `$E57D` | `HrustGetBit` | the next bit into A's bit 0 (and the carry out of A's bit 7) |
| `$E58C` | `HrustGetBitDone` | - |

`menupicture.asm` (`build/endings/deadend.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$E73B` | `MenuPicture` | -------------------------------------------------------------------------------------------------------------------- |
| `$E73F` | `MenuHere` | - |
| `$E76F` | `MenuToken` | - |
| `$E789` | `MenuMatchByte` | - |
| `$E7A3` | `MenuMatchRead` | - |
| `$E7A4` | `MenuMatchCall` | - |
| `$E7AE` | `MenuNotMatch` | - |
| `$E7B8` | `MenuLiteralByte` | - |
| `$E7B9` | `MenuLiteralCall` | - |
| `$E7C1` | `MenuRun` | - |
| `$E7C7` | `MenuRunCall` | - |
| `$E7CF` | `MenuEnd` | - |
| `$E7D6` | `MenuPutByte` | the byte A to the screen in the depacker's order (LzPutByte's copy) |
| `$E7F5` | `MenuPutAttr` | - |
| `$E7F6` | `MenuPutCells` | - |
| `$E7F8` | `MenuPutLines` | - |
| `$E7FA` | `MenuPutDone` | - |

`im2.asm` (`build/endings/deadend.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$FDFD` | `Im2Handler` | the interrupt: one frame of the tune |

`fcmain.asm` (`build/endings/finalcut.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$6060` | `FcInterrupt` | -------------------------------------------------------------------------------------------------------------------- |
| `$61A8` | `FinalCut` | Final Cut: the caption, the alien and the scroll |
| `$61E7` | `FcCaptionWait` | - |
| `$6208` | `FcLineTableLoop` | - |
| `$6215` | `FcScrollFrame` | - |
| `$6217` | `FcDrawPage` | - |
| `$6224` | `FcShowPage` | - |
| `$6238` | `FcEnd` | the end: loop forever (the tune plays on from the interrupt) |
| `$623A` | `FcScroll` | scroll the left half (16 bytes) of the screen at `$C000` up a pixel line, and |
| `$6244` | `FcScrollLoop` | - |
| `$62AD` | `FcScrollSp` | - |
| `$62B0` | `FcRow` | - |
| `$62C5` | `FcTextPtr` | - |
| `$62F8` | `FcDrawRow` | draw pixel row A of the 8 characters at HL into the bottom line of the `$C000` |
| `$63D5` | `FcNextLine` | DE = the screen address of the pixel line below DE |
| `$63E4` | `FcPage` | A to the paging port `$7FFD` (BC kept) |
| `$63EC` | `FcTextEnd` | the text is done: flicker the two screens, then the Victory screen |
| `$63F0` | `FcFlickerLoop` | - |
| `$6407` | `FcBlack` | black: the border and every attribute |
| `$6419` | `FcVictory` | clear the screen, fade it to white, then the Victory screen |
| `$6420` | `FcClearLoop` | - |
| `$642A` | `FcFadeLoop` | - |
| `$6440` | `FcFadeStep` | every attribute and the border to the colour at HL, then 2 frames |

`fcbank7.asm` (`build/endings/finalcut.lst`)

| Address | Routine | What |
| --- | --- | --- |
| `$C000` | `AlienGreenScreen` | -------------------------------------------------------------------------------------------------------------------- |
