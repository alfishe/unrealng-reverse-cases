# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a table jump or
by running on: L1 books its time to the routine it runs in) gives the runs of its first instruction, as its witness
line counts them.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: The tape's BASIC, The loading screen) follow the game, each under
its own heading with its modules, its source, its annotations and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`graphics`](11-data-reference.md#graphics) | `$61A8`-`$8C3B` | 0 of 28 |
| [`levels`](#levels) | `$8C3C`-`$A9FC`, `$BB05`-`$BB55`, `$CF2E`-`$D075`, `$E0C4`-`$E130`, `$E1C9`-`$E29F` | 8 of 15 |
| [`vars`](11-data-reference.md#vars) | `$A9FD`-`$AB7B` | 0 of 75 |
| [`setup`](#setup) | `$AB7C`-`$ACC7`, `$BB96`-`$BBCC` | 6 of 10 |
| [`mainloop`](#mainloop) | `$ACC8`-`$ADE5`, `$B6CB`-`$B6E3`, `$B6E4`-`$B6ED`, `$B747`-`$B754`, `$B7B8`-`$B7D0`, `$B873`-`$B881` | 13 of 26 |
| [`ball`](#ball) | `$ADE6`-`$B3B0`, `$B7E4`-`$B872`, `$B882`-`$B8C1`, `$B8D1`-`$B957`, `$C4E2`-`$C533`, `$C5CC`-`$C6F5`, `$C778`-`$CF0B`, `$E1C1`-`$E1C8` | 114 of 139 |
| [`menu`](#menu) | `$B3B1`-`$B470`, `$BB56`-`$BB95`, `$D25A`-`$D2B3`, `$E7F7`-`$EC3F`, `$EF33`-`$F182` | 28 of 45 |
| [`render`](#render) | `$B471`-`$B6CA`, `$B8C2`-`$B8D0`, `$BBCD`-`$BCB8`, `$BD73`-`$C4D4`, `$C534`-`$C5CB`, `$C71F`-`$C777`, `$CF0C`-`$CF2D`, `$D076`-`$D259`, `$D2B4`-`$E0C3`, `$E131`-`$E1C0` | 171 of 192 |
| [`hud`](#hud) | `$B6EE`-`$B746`, `$B7D1`-`$B7E3`, `$BA71`-`$BB04`, `$E58B`-`$E666` | 19 of 20 |
| [`hiscore`](#hiscore) | `$B755`-`$B7B7`, `$C4D5`-`$C4E1`, `$EC40`-`$EF32` | 13 of 18 |
| [`objects`](#objects) | `$B958`-`$BA70`, `$BCB9`-`$BD72`, `$C6F6`-`$C71E` | 11 of 13 |
| [`sprites`](#sprites) | `$E2A0`-`$E58A` | 7 of 8 |
| [`text`](#text) | `$E667`-`$E7F6`, `$F5C9`-`$F8D3` | 7 of 11 |
| [`sound`](#sound) | `$F183`-`$F5C8` | 36 of 54 |

## levels

`src/game/levels.asm`

### `CellScreenAddr` (`$BB05`)

**The screen address of the ball's cell: `$AB2D` = CellAddrs `$E131`[`$AA44`]**

A CPC screen address (the game draws in CPC coordinates, ScreenAddrToLine `$C71F` converts). Called by MainLoop (`$ACCC`) and the level builder.

Witness: L1 99879 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,941 calls, 502,108 t-states own (0.04 %) |
| Runs (the other recordings) | 95,938 calls (`stage1/menu` 6,096, `stage1/rzx/l46` 2,956, `stage1/rzx/l18` 2,186 and 116 more) |
| Called from | `MainLoop`, `DownStep4`, `BuildLevelCell`, `BuildLevelNextCell`, `DrawFlames`, `DrawBricks` |
| Reads | `$AA44` (`BallCell`); `$E131`-`$E178` (`CellAddresses`) |
| Writes | `$AB2D`-`$AB2E` (`CellScrAddr`) |

### `WallScreenAddr` (`$BB1D`)

**The screen address of wall A: `$AB2F` = WallAddrs `$E179`[A]**

Input A, a cell. Called by the wall handlers and the builder (`$C93E`, `$CB81`, `$D1D3-$D1F7`).

Witness: L1 675 (c1, fire, menu, rightspike, l x9, rzx x59).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 112 t-states own (0.00 %) |
| Runs (the other recordings) | 674 calls (`stage1/rzx/l68` 158, `stage1/rzx/l96` 90, `stage1/rzx/l56` 36 and 68 more) |
| Called from | `LeftStep5`, `RightStep5`, `WallDraw1`, `WallDraw2`, `WallDraw3`, `WallDraw4` |
| Reads | `$E179`-`$E1C0` (`WallAddresses`); `$E277`-`$E278` (`EditorFont+89`) |
| Writes | `$AB2F`-`$AB30` (`WallScrAddr`) |

### `ReadCell` (`$BB32`)

**The platform and object of the ball's cell: `$AB1C`, `$AB1D`**

`$AB1C` = PlatformCells `$AA6B`[`$AA44`], `$AB1D` = ObjectCells `$AA47`[`$AA44`]. Called by MainLoop (`$ACC9`) every frame and the handlers.

Witness: L1 98282 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,868 calls, 482,411 t-states own (0.04 %) |
| Runs (the other recordings) | 94,414 calls (`stage1/menu` 5,778, `stage1/rzx/l46` 3,056, `stage1/rzx/l18` 2,194 and 116 more) |
| Called from | `LifeStart`, `MainLoop`, `UpStep5`, `DownStep4` |
| Reads | `$AA44`-`$AA8E` (`BallCell`, `PrizesLeft`, `ExitCell`, `CellObjects` and 1 more) |
| Writes | `$AB1C`-`$AB1D` (`CellPlatform`, `CellObject`) |

### `ReadWallCell` (`$BB4A`)

**The wall of cell A: `$AB1E` = WallCells `$AA8F`[A]; never called**

Known only from the code: no caller, and nothing reads `$AB1E`.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BuildLevel` (`$CF2E`)

**Build and draw level Level: copy the record, split the cells, draw them and the ball**

The CPC inks of the level (LevelColours `$E119` row Level mod 7 + 1) go to `$B6DB`, a RET on the Spectrum. The work area `$AA20-$AAFA` (219 bytes) is cleared, the record at `$8C3C` + 75 x Level is copied to `$AA20` (byte 36, the start cell, also to `$AB1A`), and each of the 36 cells is split: the high nibble to the walls `$AA8F`, the low nibble to the platforms `$AA6B`. Then BuildLevelCell draws every cell. Last the ball: sprite `$67E8`, cell `$AA44` = the start cell, its screen address `$AA03` = the cell's + `$2F62`, drawn by XOR (10 lines of 4 bytes). Called by the main loop at `$AC7D`, `$AC86` and `$ACBF`: a life start out of the demo builds twice, before READY? (`$AC7D`) and after the key (`$ACBF`), the demo once (`$AC86`).

Witness: L1 102 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

[Animation: `BuildLevel` at work](img/routines/BuildLevel.gif)

[Animation: `BuildLevel` at work, record](img/routines/BuildLevel-record.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 calls, 38,162 t-states own (0.00 %) |
| Runs (the other recordings) | 100 calls (`stage1/gameover` 12, `stage2/rec/twoname` 12, `stage1/menu` 9 and 32 more) |
| Called from | `LifeStart` |
| Calls | `NoOp`, `BuildLevelCell` (falls into) |
| Reads | `$8C3C`-`$8C86` (`LevelRecords`); `$8F2A`-`$8F74` (`LevelRecords+750`); `$90A1`-`$9136` (`LevelRecords+1125`); `$91CD`-`$9217` (`LevelRecords+1425`); `$92AE`-`$92F8` (`LevelRecords+1650`); `$967D`-`$9712` (`LevelRecords+2625`); 15 more ranges |
| Writes | `$AA0B` (`CellByte`); `$AA20`-`$AAFA` (`LevelRecord`, `BallCell`, `PrizesLeft`, `ExitCell` and 5 more); `$AB1A` (`StartCell`) |

### `BuildLevelCell` (`$CFC8`)

**Draw cell 36 - B: its platform through PlatformDrawTable**

`$AA44` = the cell, `$AA07` = the cell as a word, `$AB2D` its screen address (`$BB05`), then a jump to PlatformDrawTable[platform].

Witness: L1 3651 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 72 calls, 17,408 t-states own (0.00 %) |
| Runs (the other recordings) | 3,579 calls (`stage2/rec/twoname` 432, `stage1/gameover` 432, `stage1/menu` 324 and 32 more) |
| Called from | `BuildLevel` (falls into), `BuildLevelNextCell` (tail) |
| Calls | `CellScreenAddr`, `PlatDrawNone`, `PlatDraw1`, `PlatDraw2`, `PlatDraw3`, `PlatDraw4`, `PlatDraw5`, `PlatDraw6`, `PlatDraw7`, `PlatDraw8`, `PlatDraw9`, `PlatDraw10`, `PlatDraw12` |
| Reads | `$AA6B`-`$AA8E` (`CellPlatforms`); `$C5A8`-`$C5C1` (`PlatformDrawTable`) |
| Writes | `$AA07`-`$AA08` (`CellIndex`); `$AA44` (`BallCell`) |

### `BuildLevelObject` (`$CFF4`)

**Draw the cell's object and its wall**

Object kind K = `$AA47`[cell]; if not 0 the sprite `$6CB0` + 56 K is drawn at `$AB2D` - `$9E` with ink ObjectInks[K] (14 lines of 4 bytes, `$E3E5`). Then a jump to WallDrawTable[`$AA8F`[cell]].

Witness: L1 3651 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 72 calls, 28,714 t-states own (0.00 %) |
| Runs (the other recordings) | 3,579 calls (`stage2/rec/twoname` 432, `stage1/gameover` 432, `stage1/menu` 324 and 32 more) |
| Called from | `PlatDrawNone` (tail), `PlatDraw1` (tail), `PlatDraw2` (tail), `PlatDraw3` (tail), `PlatDraw4` (tail), `PlatDraw5` (tail), `PlatDraw6` (tail), `PlatDraw7` (tail), `PlatDraw8` (tail), `PlatDraw9` (tail), `PlatDraw10` (tail), `PlatDraw12` (tail) |
| Calls | `WallDrawNone`, `WallDraw1`, `WallDraw2`, `WallDraw3`, `WallDraw4`, `XorSpriteColoured` |
| Reads | `$AA07`-`$AA08` (`CellIndex`); `$AA47`-`$AA6A` (`CellObjects`); `$AA8F`-`$AAB2` (`CellWalls`); `$AB2D`-`$AB2E` (`CellScrAddr`); `$C5C2`-`$C5CB` (`WallDrawTable`); `$C6F7`-`$C71D` (`ObjectInks+1`) |
| Writes | `$A9FE` (`SpriteWidth`); `$D01D` (`SeekObjectSprite+20`) |

### `BuildLevelNextCell` (`$D047`)

**The next cell, or the ball when all 36 are drawn**

Witness: L1 3650 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 72 calls, 2,338 t-states own (0.00 %) |
| Runs (the other recordings) | 3,578 calls (`stage2/rec/twoname` 432, `stage1/gameover` 432, `stage1/menu` 324 and 32 more) |
| Called from | `WallDrawNone` (tail), `WallDraw1` (tail), `WallDraw2` (tail), `WallDraw3` (tail), `WallDraw4` (tail) |
| Calls | `PlayerBallSprite`, `CellScreenAddr`, `BuildLevelCell` (tail), `XorSprite` |
| Reads | `$AB1A` (`StartCell`) |
| Writes | `$A9FE`-`$AA04` (`SpriteWidth`, `BallStep`, `BallState`, `BallSprite` and 1 more); `$AA44` (`BallCell`) |

## setup

`src/game/setup.asm`

### `GameStart` (`$AB7C`)

**The code block's entry (USR 43900): DI, then GameRestart**

The BASIC's RANDOMIZE USR 43900 lands here; it disables the interrupts for good (the game waits for frames with EI: HALT, WaitFrame `$B6E4`) and falls into GameRestart. Nothing jumps back here.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 1,436 t-states own (0.00 %) |
| Reads | `$AAFD`-`$AB0F` (`Water`, `Keys`, `Hammers`, `Level` and 8 more); `$ABA6` (`DemoFlag`); `$ADDB`-`$ADDE` (`CurrentPlayer`, `PlayerCount`, `CheatMode`, `SavedPlayer`); `$B3B1` (`MenuChoice`) |
| Writes | `$A9FD`-`$AA00` (`TakeoffDrawn`, `SpriteWidth`, `BallStep`, `BallState`); `$AA12`-`$AA1D` (`ExitOpen`, `SpringArmed`, `CrumblePending`, `CrumbleActive` and 6 more); `$AAFB`-`$AB08` (`Score`, `Water`, `Keys`, `Hammers` and 8 more); `$AB1C`-`$AB33` (`CellPlatform`, `CellObject`, `CellWall`, `Unused5` and 13 more); `$ABA6` (`DemoFlag`); `$ADDB`-`$ADDE` (`CurrentPlayer`, `PlayerCount`, `CheatMode`, `SavedPlayer`) |

### `GameRestart` (`$AB7D`)

**The menu, then a new game or the demo by the menu's choice `$B3B1`**

Calls Menu `$EF33`, then clears the demo flag `$ABA6` and the cheat-mode flag `$ADDD`. By `$B3B1`: 0 starts a one-player game (`$ADDC` = 1), 2 a two-player game (`$ADDC` = 2), 1 the demo (`$ABA6` = 1, the demo input pointer `$ABA4` = `$D25A`, one byte before the demo's moves at `$D25B`; the demo plays one player). Quitting a game (R in MainLoop, QuitToMenu `$B7B2`) and the end of the demo come back here.

Witness: L1 7 (c1, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6 calls (`stage1/menu` 4, `stage1/gameover` 1, `stage2/rec/twoname` 1) |
| Called from | `BackToMenu` (tail) |
| Calls | `Menu` |
| Reads | `$AAFD`-`$AB16` (`Water`, `Keys`, `Hammers`, `Level` and 9 more); `$ABA6` (`DemoFlag`); `$ADDB`-`$ADDE` (`CurrentPlayer`, `PlayerCount`, `CheatMode`, `SavedPlayer`); `$B3B1` (`MenuChoice`) |
| Writes | `$A9FD`-`$AA00` (`TakeoffDrawn`, `SpriteWidth`, `BallStep`, `BallState`); `$AA12`-`$AA1D` (`ExitOpen`, `SpringArmed`, `CrumblePending`, `CrumbleActive` and 6 more); `$AAFB`-`$AB08` (`Score`, `Water`, `Keys`, `Hammers` and 8 more); `$AB1C`-`$AB33` (`CellPlatform`, `CellObject`, `CellWall`, `Unused5` and 13 more); `$ABA4`-`$ABA6` (`DemoInputPtr`, `DemoFlag`); `$ADDB`-`$ADDE` (`CurrentPlayer`, `PlayerCount`, `CheatMode`, `SavedPlayer`) |

### `GameRestartChoice` (`$AB80`)

**Back from the menu: start what `$B3B1` chose**

GameRestart's tail, where Menu returns. It is an entry of its own because the recordings that start inside the menu (work/stage1/probe/load-fast-nokemp/end.szx: menu, gameover, twoname) reach it by Menu's RET with no CALL seen. Clears DemoFlag `$ABA6` and CheatMode `$ADDD` and branches on MenuChoice `$B3B1` as GameRestart says.

Witness: runs after every Menu call (GameRestart L1 7: c1, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 9 runs of its first instruction, entered by a jump (`stage1/menu` 5, `stage1/gameover` 2, `docs/integrate/rec/exitbelow` 1 and 1 more) |
| Reads | `$AAFD`-`$AB0F` (`Water`, `Keys`, `Hammers`, `Level` and 8 more); `$ABA6` (`DemoFlag`); `$ADDB`-`$ADDE` (`CurrentPlayer`, `PlayerCount`, `CheatMode`, `SavedPlayer`); `$B3B1` (`MenuChoice`) |
| Writes | `$A9FD`-`$AA00` (`TakeoffDrawn`, `SpriteWidth`, `BallStep`, `BallState`); `$AA12`-`$AA1D` (`ExitOpen`, `SpringArmed`, `CrumblePending`, `CrumbleActive` and 6 more); `$AAFB`-`$AB08` (`Score`, `Water`, `Keys`, `Hammers` and 8 more); `$AB1C`-`$AB33` (`CellPlatform`, `CellObject`, `CellWall`, `Unused5` and 13 more); `$ABA6` (`DemoFlag`); `$ADDB`-`$ADDE` (`CurrentPlayer`, `PlayerCount`, `CheatMode`, `SavedPlayer`) |

### `NewGameOnePlayer` (`$ABA8`)

**One player (`$ADDC` = 1); NewGame follows**

Witness: L1 8 (c1, exitbelow, gameover, menu).

NewGame: ClearAttrs `$B471` (ink 7, black border), DrawSides `$B488`, InitPlayers `$BB96` (both records zeroed, 2 lives each by `$BBA8`). Then the cheat: TestKey `$B6CB` for R (`$2B`), SPACE (`$00`) and V (`$3C`); all three held calls `$BB56` (99 water, keys, hammers and lives for player 1). The current player `$ADDB` = 1. Witness of the cheat test: `$ABCB` (V tested once R and SPACE are held) ran once, in the menu build.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7 runs of its first instruction, entered by a jump (`stage1/menu` 4, `stage1/gameover` 2, `docs/integrate/rec/exitbelow` 1) |
| Calls | `LifeStart` (falls into), `ClearAttrs`, `DrawSides`, `TestKey`, `CheatStock`, `InitPlayers` |

### `LifeStart` (`$ABD8`)

**The start of a level or of a new life: resets the ball, the timer and the player's working copy, builds the level, "ready?"**

Entered from NewGame, from the level end (LevelEnd `$B2C2` through `$B3AE`) and after a life lost (LoseLife `$BA93`). If the cheat mode `$ADDD` is on (never: its switch is gone, see CheatModeOn `$ADE0`) `$BB7D` refills the stores. ClearPlayArea `$B4CE`, then zeroes the ball state `$AA00`, BallStep `$A9FF`, SpringArmed `$AA13`, the animation flags `$AA12`, `$AB33`, `$AB2B`, `$AA15`, `$AA14`, `$AA1D`, the platform under the ball `$AB1C` and `$A9FD`; the timer `$AB04` = 1000 (`$03E8`: the passes the level allows).

The players: the current player `$ADDB` is kept in `$ADDE`. With two players (`$ADDC` = 2) the code copies player 2's record (`$AB10`) to the working copy `$AAFB` and sets `$ADDB` = 2, then player 1's (`$AB09`) and `$ADDB` = 1, each time testing lives = `$FA` (the mark of a player out) with a JR Z to the very next line: the test does nothing (known only from the code). Then `$ADDB` = `$ADDE` again and the record of the current player is copied to `$AAFB` (7 bytes: score word, water, keys, hammers, level, lives), with the text to show: ReadyText `$AD3B` (one player), Player1ReadyText `$AD48` or Player2ReadyText `$AD84`.

In a game: ClearPlayArea, BuildLevel `$CF2E`, PrintText `$E667` of that text; in the demo BuildLevel only. Then water, keys and hammers are kept in `$AB06-$AB08` (the stores at the level's start), `$BB32` reads the platform under the ball, and D (`$32`) calls CheatModeSwitch `$ADDF` (a RET). A game then draws the HUD (`$E58B`), waits for all keys up (WaitRelease `$B401`) and for a key (WaitPressHeld `$B6DD`), and the key sets the first move (DecideMove `$B7E4`). Last, in both: ClearPlayArea and BuildLevel again (the text goes), the HUD and WaitFrame `$B6E4`; MainLoop follows.

Witness: L1 62 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 55 calls (`stage2/rec/twoname` 6, `stage1/gameover` 6, `stage1/rzx/l51` 4 and 30 more) |
| Called from | `NewGameOnePlayer` (falls into), `LevelEnd` (tail), `LoseLifeWait` (tail) |
| Calls | `WaitRelease`, `ClearPlayArea`, `TestKey`, `WaitPressHeld`, `WaitFrame`, `ChooseNextState`, `ReadCell`, `BuildLevel`, `DrawHud`, `PrintText` |
| Reads | `$AAFD`-`$AB16` (`Water`, `Keys`, `Hammers`, `Level` and 9 more); `$ABA6` (`DemoFlag`); `$ADDB`-`$ADDE` (`CurrentPlayer`, `PlayerCount`, `CheatMode`, `SavedPlayer`) |
| Writes | `$A9FD`-`$AA00` (`TakeoffDrawn`, `SpriteWidth`, `BallStep`, `BallState`); `$AA12`-`$AA1D` (`ExitOpen`, `SpringArmed`, `CrumblePending`, `CrumbleActive` and 6 more); `$AAFB`-`$AB08` (`Score`, `Water`, `Keys`, `Hammers` and 8 more); `$AB1C`-`$AB33` (`CellPlatform`, `CellObject`, `CellWall`, `Unused5` and 13 more); `$ADDB`-`$ADDE` (`CurrentPlayer`, `PlayerCount`, `CheatMode`, `SavedPlayer`) |

### `InitPlayers` (`$BB96`)

**Clear both player records: 2 lives each; the demo gets level 10 and 2 of each tool**

Zeroes the 14 bytes `$AB09-$AB16`, lives 2 for both players. In the demo (`$ABA6` not 0) player 1 gets water, keys and hammers 2 and level 10. Called by GameStart (`$ABBA`).

Witness: L1 10 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 693 t-states own (0.00 %) |
| Runs (the other recordings) | 9 calls (`stage1/menu` 5, `stage1/gameover` 2, `docs/integrate/rec/exitbelow` 1 and 1 more) |
| Called from | `NewGameOnePlayer` |
| Reads | `$ABA6` (`DemoFlag`) |
| Writes | `$AB09`-`$AB16` (`Player1Record`, `Player2Record`) |

## mainloop

`src/game/mainloop.asm`

### `MainLoop` (`$ACC8`)

**One frame of the game: the animations, the timer, the keys, the frame wait, then the ball's state routine**

Each pass: `$BB32` (the platform under the ball to `$AB1C`), `$BB05` (the ball's cell address), the animations `$BE94` (`$AB33`), `$BFF3` (`$AB2B`), `$C19D` (`$AA15`), `$C43E` (`$AA1D`), `$BBCD` and `$BC30` (every fourth frame: the flames and the walls), `$BD21` (`$AA12`), the timer `$B7D1` (the timer `$AB04` minus one), the bottle's pause `$BA60`. Then the keys: R (`$2B`) held jumps to QuitToMenu `$B7B2`; D (`$32`) calls CheatModeSwitch `$ADDF` (a RET); in a game (not the demo) the pause key (slot `$F08A`) calls Pause `$B440`. Last WaitFrame (through `$B87E`) and the dispatch.

Witness: L1 93416 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,840 calls, 2,058,445 t-states own (0.16 %) |
| Runs (the other recordings) | 89,536 calls (`stage1/menu` 5,717, `stage1/rzx/l46` 2,776, `stage1/rzx/l18` 2,099 and 116 more) |
| Called from | `BallBounceMove` (tail), `BallLeftMove` (tail), `BallRightMove` (tail), `BallUpMove` (tail), `BallBumpCeiling` (tail), `BallDownMove` (tail), `LandingCheck` (tail), `BallBurstStart` (tail), `BallStopped` (tail), `BurstBall1` (tail), `BurstBall2` (tail), `BurstBall3` (tail), `BurstFrame1` (tail), `BurstFrame2` (tail), `BurstFrame3` (tail), `BurstFrame4` (tail), `BurstFrame5` (tail), `BurstFrame6` (tail), `LostStep1` (tail), `LostStep2` (tail), `LostStep3` (tail), `LostStep4` (tail), `UpStep4` (tail) |
| Calls | `BallBounce`, `BallLeft`, `BallRight`, `BallUp`, `BallDown`, `BallStopped`, `BallBurst`, `BallFallOut`, `LevelEnd`, `Pause`, `TestKey`, `BackToMenu` (tail), `TickTimer`, `WaitOneFrame`, `BottleFlashOff`, `CellScreenAddr`, `ReadCell`, `AnimateFires`, `AnimateWalls`, `AnimateExit`, `BrickStep`, `WaterStep`, `PlatformChangeStep`, `WallStep` |
| Reads | `$AA00` (`BallState`); `$ABA6` (`DemoFlag`); `$AD29`-`$AD3A` (`StateTable`); `$F08A` (`KeySlots+6`) |

### `CheatModeSwitch` (`$ADDF`)

**The D key's routine: a RET, put before the code that would switch the cheat mode on**

MainLoop and LifeStart call it when D (`$32`) is held. The RET makes the key do nothing; the next six bytes (CheatModeOn `$ADE0`) are the original body. Witness: called whenever D is held; no recording held D.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CheatModeOn` (`$ADE0`)

**LD A,1: LD (`$ADDD`),A: RET: the cut-off body of the D key (never runs)**

Would set CheatMode `$ADDD` = 1. CheatModeSwitch's RET in front of it keeps it from running; nothing else jumps here (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TestKey` (`$B6CB`)

**NZ (A = 1) when the key or stick code A is held, else Z (A = 0): ReadControls then TestKeyBit**

Witness: L1 428989 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 18,941 calls, 1,744,557 t-states own (0.14 %) |
| Runs (the other recordings) | 410,048 calls (`stage1/menu` 43,298, `stage1/rzx/l46` 11,566, `stage1/gameover` 10,092 and 116 more) |
| Called from | `NewGameOnePlayer`, `LifeStart`, `MainLoop`, `BallBounceMove`, `BallLeftMove`, `BallRightMove`, `BallUpMove`, `BallDownMove`, `BallStopped`, `TestLeft`, `TestRight`, `TestDown`, `TestUpOrFire`, `MenuWait` |
| Calls | `TestKeyBit`, `ReadControls` |

### `NoOp` (`$B6DB`)

**A RET the level builder calls three times (`$CF50`, `$CF5A`, `$CF64`)**

Witness: L1 306 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 6 calls, 72 t-states own (0.00 %) |
| Runs (the other recordings) | 300 calls (`stage1/gameover` 36, `stage2/rec/twoname` 36, `stage1/menu` 27 and 32 more) |
| Called from | `BuildLevel` |

### `WaitPressHeld` (`$B6DD`)

**Waits until a key or the stick is held (no wait for the release): the "ready?" prompt**

Witness: L1 349912 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, rzx x23).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 243,158 t-states own (0.02 %) |
| Runs (the other recordings) | 54 calls (`stage1/gameover` 6, `stage2/rec/twoname` 6, `stage1/menu` 4 and 27 more) |
| Called from | `LifeStart` |
| Calls | `AnyControl` |

### `WaitFrame` (`$B6E4`)

**Refresh the HUD's attributes and wait for the next frame interrupt**

Calls `$E58B` (the per-frame HUD refresh, which repaints the attributes with PaintHudAttrs `$B6EE`), then EI and HALT: the game runs at one pass of MainLoop `$ACC8` a frame. IX is preserved. Called by MainLoop (`$ACC5`) and WaitOneFrame `$B87E`.

Witness: L1 97266 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,864 calls, 119,249,345 t-states own (9.38 %) |
| Runs (the other recordings) | 93,403 calls (`stage1/menu` 5,753, `stage1/rzx/l46` 2,794, `stage1/rzx/l18` 2,118 and 116 more) |
| Called from | `LifeStart`, `WaitOneFrame` |
| Calls | `DrawHud` |
| Reads | `$B6EB` (`WaitFrame+7`) |
| Writes | `$AAFB`-`$AAFC` (`Score`) |

### `FirmwareStub` (`$B747`)

**A RET in place of an Amstrad CPC firmware call**

A lone RET. `$B744-$B754` is a row of 17 `$C9` bytes: the Spectrum port replaced the CPC firmware jump block entries the game called with RETs at the same kind of place. This one is called with B = C = 26 by TakeBottle `$BA1C` and with B = C = 0 by BottleFlashOff `$BA60`: on the CPC, B and C are two colours, which fits SCR SET BORDER (26 bright white, 0 black): a border flash for the extra life that the Spectrum drops (known only from the code).

Witness: L1 46 (menu, scoreloop, l10, l36, l45, l68, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 46 calls (`docs/integrate/rec/scoreloop` 6, `stage2/rec/l10` 2, `stage1/rzx/l06` 2 and 18 more) |
| Called from | `TakeBottle`, `BottleFlashOff` |

### `FirmwareStub3` (`$B750`)

**A RET stub, called by `$B387` at the end of a level**

A lone RET in the row of firmware stubs (`$B744-$B754`); called by the level-end code at `$B387`.

Witness: L1 20 (menu, l51, l59, l96, l98, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20 calls (`stage1/rzx/l41` 1, `stage1/rzx/l72` 1, `stage1/menu` 1 and 17 more) |
| Called from | `LevelEnd` |

### `FirmwareStub5` (`$B754`)

**A RET stub, called only by the disabled cheat routes `$B2C9` and `$BA80`**

A lone RET; both callers are never reached (CheatMode `$ADDD` is never set: `$ADDF` is a RET before its store), so it never runs; known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WaitKeyOrSecond` (`$B7B8`)

**Wait 50 frames or until a key is pressed**

Sets the counter `$EFED` to 50, then a frame at a time (EI, HALT) calls AnyKey `$B407` and returns as soon as it reports a key (NZ), else counts down to 0. Used between lives (LoseLife `$BA93`), after a level (`$B3AB`) and before the menu (BackToMenu).

Witness: L1 60 (fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x26).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 60 calls (`stage2/rec/twoname` 6, `stage1/gameover` 5, `stage1/menu` 4 and 33 more) |
| Called from | `LevelEnd`, `BackToMenu`, `LoseLifeWait` |
| Calls | `AnyControl` |
| Reads | `$B7C0` (`WaitKeyOrSecondLoop+2`); `$EFED`-`$EFEE` (`MenuTimer`) |
| Writes | `$EFED`-`$EFEE` (`MenuTimer`) |

### `Delay` (`$B873`)

**Busy wait: B times 50 empty loops**

Input B. About 650 T-states a unit. Used by the burst death (`$B144`), GameOverDelay `$C4D5` and NameEntry (`$EC4E`). BC preserved.

Witness: L1 37654 (gameover, menu, twoname, l x6, rzx x29).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,947 calls (`stage2/rec/twoname` 4,040, `stage1/gameover` 2,040, `stage1/rzx/l96` 108 and 35 more) |
| Called from | `BallStopped`, `GameOverDelay`, `EnterHallOfFame` |

### `WaitOneFrame` (`$B87E`)

**CALL WaitFrame: wait one frame**

Called where a frame passes without the main loop: the state handlers (`$AD0C`, `$B029`, `$B169`), the level end (`$B328`, `$B334`) and the pause between lives (LoseLife, 50 calls).

Witness: L1 97227 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,863 calls, 117,748 t-states own (0.01 %) |
| Runs (the other recordings) | 93,364 calls (`stage1/menu` 5,749, `stage1/rzx/l46` 2,794, `stage1/rzx/l18` 2,118 and 116 more) |
| Called from | `MainLoop`, `BallBumpCeiling`, `BallBurst`, `LevelEnd`, `LoseLifeWait` |
| Calls | `WaitFrame` |

## ball

`src/game/ball.asm`

### `PlayerBallSprite` (`$ADE6`)

**HL = the sprite at HL for the current player: + `$280` for player 2**

Input HL a ball sprite (player 1's); output HL unchanged when CurrentPlayer `$ADDB` = 1, else HL + `$280` (player 2's ball, a different pattern). Player 2's branch ran 763 times in twoname (player 2's turns).

Witness: L1 220591 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 8,088 calls, 252,122 t-states own (0.02 %) |
| Runs (the other recordings) | 212,503 calls (`stage1/menu` 12,002, `stage1/rzx/l46` 6,074, `stage1/rzx/l18` 4,340 and 116 more) |
| Called from | `DrawBallRound`, `DrawBallFrame`, `DrawBallRoundOld`, `DrawBurstBall`, `LostStep2`, `LevelEnd`, `DrawBallRight`, `DrawBallLeft`, `BuildLevelNextCell` |
| Reads | `$ADDB` (`CurrentPlayer`) |

### `DrawBallRound` (`$ADF1`)

**XOR the round ball (`$67E8`) at the ball's address `$AA03`**

Witness: L1 58039 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,500 calls, 221,865 t-states own (0.02 %) |
| Runs (the other recordings) | 54,539 calls (`stage1/menu` 5,194, `stage1/rzx/l46` 2,264, `stage1/rzx/l18` 1,970 and 116 more) |
| Called from | `BallBounceMove`, `BallUpMove`, `BallBumpCeiling`, `BallDownMove`, `LostStep1`, `LostStep2`, `UpStep4` |
| Calls | `PlayerBallSprite`, `DrawBallXor` (tail) |
| Reads | `$AA03`-`$AA04` (`BallScrAddr`) |

### `DrawBallFrame` (`$ADFE`)

**XOR the ball's sprite `$AA01` (a rolling frame) at `$AA03`**

Witness: L1 34487 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 362 calls, 25,169 t-states own (0.00 %) |
| Runs (the other recordings) | 34,125 calls (`stage1/rzx/l43` 838, `stage1/rzx/l00` 736, `stage1/rzx/l15` 634 and 116 more) |
| Called from | `BallLeftMove`, `BallRightMove` |
| Calls | `PlayerBallSprite`, `DrawBallXor` (tail) |
| Reads | `$AA01`-`$AA04` (`BallSprite`, `BallScrAddr`) |

### `DrawBallRoundOld` (`$AE0B`)

**XOR the round ball at the previous address `$AA05` (erases it)**

Witness: L1 206 (c1, gameover, menu, scoreloop, twoname, l10, l51, l68, l96, rzx x29).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 44 calls, 2,772 t-states own (0.00 %) |
| Runs (the other recordings) | 162 calls (`stage1/menu` 26, `stage1/rzx/l36` 18, `stage1/gameover` 12 and 34 more) |
| Called from | `BallBumpCeiling` |
| Calls | `PlayerBallSprite`, `DrawBallXor` (falls into) |
| Reads | `$AA05`-`$AA06` (`BallOldAddr`) |

### `DrawBallXor` (`$AE23`)

**XOR a ball sprite: HL the CPC address, DE the sprite; 10 lines, `$A9FE` = 4**

Sets `$A9FE` = 4, B = 10 (lines), C = 7, and calls the XOR sprite routine `$E3E5`. The sprite routines above load HL and DE and come here.

Witness: L1 185077 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 7,724 calls, 499,586 t-states own (0.04 %) |
| Runs (the other recordings) | 177,353 calls (`stage1/menu` 11,452, `stage1/rzx/l46` 5,552, `stage1/rzx/l18` 4,200 and 116 more) |
| Called from | `DrawBallRound` (tail), `DrawBallFrame` (tail), `DrawBallRoundOld` (falls into), `DrawBurstBall` |
| Calls | `XorSpriteColoured` |
| Writes | `$A9FE` (`SpriteWidth`) |

### `BallStepMove` (`$AE30`)

**Moves the ball one step: `$AA05` = `$AA03`, `$AA03` += IX[BallStep], erase at the old address**

Input IX the state's offset table (16 or 8 words). The new address is the old plus the step's offset (a CPC screen address delta: `$0800` a pixel line, `$0050` a character row); then EraseBallOld at `$AE18` removes the old picture. The caller draws the new one.

Witness: L1 92310 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,818 calls, 800,466 t-states own (0.06 %) |
| Runs (the other recordings) | 88,492 calls (`stage1/menu` 5,700, `stage1/rzx/l46` 2,776, `stage1/rzx/l18` 2,098 and 116 more) |
| Called from | `BallBounceMove`, `BallLeftMove`, `BallRightMove`, `BallUpMove`, `BallDownMove`, `LeftStep15`, `RightStep15`, `DownStep7` |
| Reads | `$A9FF`-`$AA06` (`BallStep`, `BallState`, `BallSprite`, `BallScrAddr` and 1 more); `$AEBB`-`$AEDA` (`BounceOffsets`); `$AF35`-`$AF54` (`LeftOffsets`); `$AFAF`-`$AFCE` (`RightOffsets`); `$B054`-`$B063` (`UpOffsets`); `$B10A`-`$B119` (`DownOffsets`) |
| Writes | `$AA03`-`$AA06` (`BallScrAddr`, `BallOldAddr`) |

### `StepDispatch` (`$AE4B`)

**Jumps to IX[BallStep]: the per-step check of the current move**

Input IX a state's handler table. Each check routine (`$C778-$CECC`) tests the cells, then goes on to the state's move routine (BallBounceMove `$AE65` and the others) or to a crash.

Witness: L1 92830 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,840 calls, 437,760 t-states own (0.03 %) |
| Runs (the other recordings) | 88,990 calls (`stage1/menu` 5,713, `stage1/rzx/l46` 2,832, `stage1/rzx/l18` 2,099 and 116 more) |
| Called from | `BallBounce` (tail), `BallLeft` (tail), `BallRight` (tail), `BallUp` (tail), `BallDown` (tail) |
| Calls | `BounceStep0`, `BounceStep1`, `BounceStepIdle`, `BounceStep9`, `BounceStep10`, `BounceStep11`, `BounceStep12`, `BounceStep13`, `BounceStep14`, `BounceStep15`, `LeftStep0`, `LeftStepIdle`, `LeftStep5`, `LeftStepIdle2`, `LeftStep8`, `LeftStep9`, `LeftStep10`, `LeftStep11`, `LeftStep12`, `LeftStep13`, `LeftStep14`, `LeftStep15`, `RightStep0`, `RightStepIdle`, `RightStep5`, `RightStepIdle2`, `RightStep8`, `RightStep9`, `RightStep10`, `RightStep11`, `RightStep12`, `RightStep13`, `RightStep14`, `RightStep15`, `UpStep0`, `UpStep1`, `UpStep2`, `UpStep3`, `UpStep4`, `UpStep5`, `UpStep6`, `UpStep7`, `DownStep0`, `DownStepIdle`, `DownStep3`, `DownStep4`, `DownStep5`, `DownStepIdle2`, `DownStep7` |
| Reads | `$A9FF` (`BallStep`); `$AE9B`-`$AEBA` (`BounceChecks`); `$AF15`-`$AF34` (`LeftChecks`); `$AF8F`-`$AFAE` (`RightChecks`); `$B044`-`$B053` (`UpChecks`); `$B0FA`-`$B109` (`DownChecks`) |

### `BallBounce` (`$AE5F`)

**State 0: the bounce in place, 16 steps (the checks in BounceChecks)**

Witness: L1 19355 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

[Animation: `BallBounce` at work](img/routines/BallBounce.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,248 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 84,448 t-states own (0.01 %) |
| Runs (the other recordings) | 16,107 runs of its first instruction, entered by a jump (`stage1/menu` 4,752, `stage1/rzx/l18` 1,216, `stage2/rec/twoname` 432 and 109 more) |
| Called from | `MainLoop` |
| Calls | `StepDispatch` (tail) |

### `BallBounceMove` (`$AE65`)

**State 0's step: round ball, the BounceOffsets step, S kills, after step 15 LandingCheck**

Sprite = the round ball `$67E8`. BallStepMove with BounceOffsets `$AEBB`; in a game, S (`$31`) jumps to Suicide `$BA71`; DrawBallRound; BallStep + 1 and back to MainLoop, or after step 15 BallStep = 0 and LandingCheck `$B09E`. The 16 offsets lift the ball 4, 8, 11, 14, 16, 17, 18, 18, 18, 17, 16, 14, 11, 8, 4 and 0 lines above its rest line (pixel line 6 or 7 of a character row).

Witness: L1 19355 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,045 calls, 629,868 t-states own (0.05 %) |
| Runs (the other recordings) | 15,498 calls (`stage1/menu` 4,453, `stage1/rzx/l18` 1,216, `stage2/rec/twoname` 405 and 109 more) |
| Called from | `BounceStep0`, `BounceCrumble2` (tail), `BounceCrumble3` (tail), `BounceCrumble4` (tail), `BounceStep1` (tail), `BounceStepIdle` (tail), `BounceStep10` (tail), `BounceStep12` (tail), `BounceStep13` (tail), `BounceStep14` (tail), `BounceStep15` (tail) |
| Calls | `MainLoop` (tail), `DrawBallRound`, `BallStepMove`, `LandingCheck` (tail), `TestKey`, `SelfDestruct` (tail) |
| Reads | `$A9FF` (`BallStep`); `$ABA6` (`DemoFlag`) |
| Writes | `$A9FF`-`$AA02` (`BallStep`, `BallState`, `BallSprite`) |

### `BallLeft` (`$AEDB`)

**State 1: the jump to the left, 16 steps (the checks in LeftChecks)**

Witness: L1 15441 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx00-rzx18, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 148 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,552 t-states own (0.00 %) |
| Runs (the other recordings) | 15,293 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 426, `stage1/rzx/l00` 368, `stage1/rzx/l15` 292 and 109 more) |
| Called from | `MainLoop` |
| Calls | `StepDispatch` (tail) |

### `BallLeftMove` (`$AEE2`)

**State 1's step: LeftOffsets, S kills, the rolling frame (`$B8A2`), after step 15 LandingCheck**

As BallBounceMove with LeftOffsets `$AF35` and the sprite picked by `$B8A2` (the left-rolling frames). The ball moves 10 CPC bytes left (5 Spectrum bytes, one cell) on the same arc.

Witness: L1 15494 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx00-rzx18, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 148 calls, 27,848 t-states own (0.00 %) |
| Runs (the other recordings) | 14,907 calls (`stage1/rzx/l43` 412, `stage1/rzx/l00` 366, `stage2/rec/l59` 288 and 109 more) |
| Called from | `LeftStep0`, `LeftTakeoff` (tail), `LeftStepIdle` (tail), `LeftStep5` (tail), `LeftStepIdle2` (tail), `LeftStep8` (tail), `LeftStep9` (tail), `LeftStep10` (tail), `LeftStep12` (tail), `LeftStep13` (tail), `LeftStep14` (tail), `LeftStep15` (tail), `RightStep5` (tail), `RightStep8` (tail) |
| Calls | `MainLoop` (tail), `DrawBallFrame`, `BallStepMove`, `LandingCheck` (tail), `TestKey`, `DrawBallLeft` |
| Reads | `$A9FF` (`BallStep`); `$ABA6` (`DemoFlag`) |
| Writes | `$A9FF` (`BallStep`) |

### `BallRight` (`$AF55`)

**State 2: the jump to the right, 16 steps (the checks in RightChecks)**

Witness: L1 19049 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

[Animation: `BallRight` at work](img/routines/BallRight.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 214 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 5,136 t-states own (0.00 %) |
| Runs (the other recordings) | 18,835 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 412, `stage1/rzx/l00` 368, `stage1/rzx/l15` 342 and 115 more) |
| Called from | `MainLoop` |
| Calls | `StepDispatch` (tail) |

### `BallRightMove` (`$AF5C`)

**State 2's step: RightOffsets, S kills, the rolling frame (`$B882`), after step 15 LandingCheck**

As BallLeftMove with RightOffsets `$AFAF` and the right-rolling frames (`$B882`).

Witness: L1 18993 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 212 calls, 39,989 t-states own (0.00 %) |
| Runs (the other recordings) | 18,165 calls (`stage1/rzx/l43` 416, `stage1/rzx/l00` 367, `stage1/rzx/l15` 331 and 115 more) |
| Called from | `LeftStep5` (tail), `LeftStep8` (tail), `RightStep0`, `RightTakeoff` (tail), `RightStepIdle` (tail), `RightStep5` (tail), `RightStepIdle2` (tail), `RightStep8` (tail), `RightStep9` (tail), `RightStep10` (tail), `RightStep12` (tail), `RightStep13` (tail), `RightStep14` (tail), `RightStep15` (tail) |
| Calls | `MainLoop` (tail), `DrawBallFrame`, `BallStepMove`, `LandingCheck` (tail), `TestKey`, `DrawBallRight` |
| Reads | `$A9FF` (`BallStep`); `$ABA6` (`DemoFlag`) |
| Writes | `$A9FF` (`BallStep`) |

### `BallUp` (`$AFCF`)

**State 3: the spring's jump up one cell, 8 steps (the checks in UpChecks)**

Witness: L1 19058 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 126 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,024 t-states own (0.00 %) |
| Runs (the other recordings) | 18,932 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 1,172, `stage1/rzx/l38` 732, `stage1/rzx/l15` 440 and 113 more) |
| Called from | `MainLoop` |
| Calls | `StepDispatch` (tail) |

### `BallUpMove` (`$AFD6`)

**State 3's step: 4 lines up, S kills; after step 7 DecideMove**

Round ball, UpOffsets `$B054` (8 x 4 lines = 32 lines, one cell row). After step 7, BallStep = 0 and DecideMove `$B7E4` picks the next state (the ball is on the platform above).

Witness: L1 18538 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 104 calls, 20,536 t-states own (0.00 %) |
| Runs (the other recordings) | 17,209 calls (`stage1/rzx/l46` 1,022, `stage1/rzx/l38` 639, `stage1/rzx/l15` 404 and 113 more) |
| Called from | `UpStep0`, `UpSpringRelease` (tail), `UpStep1` (tail), `UpStep2` (tail), `UpStep3` (tail), `UpStep4` (tail), `UpStep5` (tail), `UpStep6` (tail), `UpStep7` (tail) |
| Calls | `MainLoop` (tail), `DrawBallRound`, `BallStepMove`, `TestKey`, `ChooseNextState`, `SelfDestruct` (tail) |
| Reads | `$A9FF` (`BallStep`); `$ABA6` (`DemoFlag`) |
| Writes | `$A9FF`-`$AA02` (`BallStep`, `BallState`, `BallSprite`) |

### `BallBumpCeiling` (`$B00F`)

**The ball hits a platform from below: two lines up and back, then it falls (state 4)**

Jumped to by the up checks (`$CDAA`, `$CDC3`) when the cell above is closed. Moves the ball 2 lines up (`$F000` = minus `$1000`), redraws it, waits a frame (`$B87E`), moves it back (`$1000`) and sets BallState = 4 (down). 88 bumps in the recordings (its witness).

Witness: L1 103 (c1, gameover, menu, scoreloop, twoname, l10, l51, l68, l96, rzx x29).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 22 calls, 6,041 t-states own (0.00 %) |
| Runs (the other recordings) | 81 calls (`stage1/menu` 13, `stage1/rzx/l36` 9, `stage2/rec/twoname` 6 and 34 more) |
| Called from | `UpStep4` (tail) |
| Calls | `MainLoop` (tail), `DrawBallRound`, `DrawBallRoundOld`, `WaitOneFrame` |
| Reads | `$AA03`-`$AA04` (`BallScrAddr`) |
| Writes | `$AA00`-`$AA06` (`BallState`, `BallSprite`, `BallScrAddr`, `BallOldAddr`) |

### `BallDown` (`$B064`)

**State 4: the fall one cell down, 8 steps (the checks in DownChecks)**

Witness: L1 19927 (c1, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 104 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,496 t-states own (0.00 %) |
| Runs (the other recordings) | 409 calls (`stage1/rzx/l46` 56, `stage1/rzx/l38` 40, `stage1/rzx/l75` 32 and 28 more) |
| Called from | `MainLoop`, `UpStep0` (tail), `UpStep1` (tail), `UpStep2` (tail), `UpStep3` (tail), `UpStep4` (tail), `UpStep5` (tail), `UpStep6` (tail), `UpStep7` (tail) |
| Calls | `StepDispatch` (tail) |

### `BallDownMove` (`$B06B`)

**State 4's step: 4 lines down, S kills; after step 7 LandingCheck**

Witness: L1 19923 (c1, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 104 calls, 20,371 t-states own (0.00 %) |
| Runs (the other recordings) | 19,819 calls (`stage1/rzx/l46` 1,116, `stage1/rzx/l38` 692, `stage1/rzx/l15` 440 and 113 more) |
| Called from | `DownStep0` (tail), `DownStepIdle` (tail), `DownStep3` (tail), `DownStep4` (tail), `DownStepIdle2` (tail), `DownStep7` (tail) |
| Calls | `MainLoop` (tail), `DrawBallRound`, `BallStepMove`, `LandingCheck` (falls into), `TestKey`, `SelfDestruct` (tail) |
| Reads | `$A9FF` (`BallStep`); `$ABA6` (`DemoFlag`) |
| Writes | `$A9FF`-`$AA02` (`BallStep`, `BallState`, `BallSprite`) |

### `LandingCheck` (`$B09E`)

**The end of a move: on a platform DecideMove, in the air fall, off the bottom row lost**

`$AA44` is the ball's cell (0-35, six columns by six rows; 30-35 the bottom row) and `$AB1C` the platform in it. A platform: DecideMove `$B7E4`. No platform above the bottom row: BallState = 4 (fall one cell); if the cell below (CellPlatforms `$AA6B` + cell + 6) holds bricks (`$0A`) DecideMove runs at once. No platform on the bottom row: BallState = 7 (lost below), BallStep = 0. Witness: state 7 started 8 times in the recordings (`$B0E0`).

Witness: L1 6174 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 250 calls, 24,644 t-states own (0.00 %) |
| Runs (the other recordings) | 5,924 calls (`stage1/menu` 363, `stage1/rzx/l46` 201, `stage1/rzx/l38` 137 and 116 more) |
| Called from | `BallBounceMove` (tail), `BallLeftMove` (tail), `BallRightMove` (tail), `BallDownMove` (falls into) |
| Calls | `MainLoop` (tail), `ChooseNextState` |
| Reads | `$AA44` (`BallCell`); `$AA71`-`$AA8E` (`CellPlatforms+6`); `$AB1C` (`CellPlatform`) |
| Writes | `$A9FF`-`$AA00` (`BallStep`, `BallState`) |

### `BallBurstStart` (`$B0ED`)

**Starts the burst (state 6, step 0): the ball hit a deadly platform**

Jumped to by the platform checks when the ball lands on platform 12 from above (`$CA8A`, `$CF09`) or hits it from below (`$CCCD`); the fire death (a flame without water) goes through it too. 5 bursts in the recordings (rzx45, rzx56, rzx68).

Witness: L1 7 (fire, rightspike, rzx45, rzx56, rzx68).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage1/rzx/l56` 2, `stage1/rzx/l68` 2, `docs/integrate/rec/rightspike` 1 and 2 more) |
| Called from | `LeftStep15` (tail), `RightStep15` (tail), `DownStep7` (tail) |
| Calls | `MainLoop` (tail) |
| Writes | `$A9FF`-`$AA00` (`BallStep`, `BallState`) |

### `BallStopped` (`$B11A`)

**State 5: the ball sits on a stopper platform (5) until left or right is pressed**

In the demo the next state is the next byte of the demo input (`$ABA4` + 1, from `$D25B`). In a game S kills (Suicide `$BA71`), right sets state 2 (`$B855`), left state 1 (`$B84F`). Then a short busy wait (Delay `$B873`, B = 2) and MainLoop.

Witness: L1 827 (menu, l x6, rzx x29).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 827 runs of its first instruction, entered by a jump (`stage1/rzx/l96` 108, `stage1/rzx/l79` 98, `stage2/rec/l59` 90 and 33 more) |
| Called from | `MainLoop` |
| Calls | `MainLoop` (tail), `TestLeft`, `TestRight`, `TestKey`, `SetStateLeft`, `SetStateRight`, `Delay` |
| Reads | `$ABA4`-`$ABA6` (`DemoInputPtr`, `DemoFlag`); `$D261`-`$D264` (`DemoMoves+7`) |
| Writes | `$AA00` (`BallState`); `$ABA4`-`$ABA5` (`DemoInputPtr`) |

### `BallBurst` (`$B14A`)

**State 6: the burst, one frame of BurstSteps a pass (10 steps), then LoseLife**

Jumps to BurstSteps[BallStep] after BallStep + 1 and a frame wait (`$B87E`). The steps: the ball drawn at three places around the burst point `$AB2D` (BurstBall1-3), six burst pictures `$81F5-$830D` (56 bytes each, 14 lines), a blank (`$6708`), then LoseLife `$BA93`.

Witness: L1 126 (fire, rightspike, rzx x8).

[Animation: `BallBurst` at work](img/routines/BallBurst.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 126 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 27, `stage1/rzx/l68` 20, `stage1/rzx/l45` 17 and 7 more) |
| Called from | `MainLoop` |
| Calls | `BurstBall1`, `BurstBall2`, `BurstBall3`, `BurstFrame1`, `BurstFrame2`, `BurstFrame3`, `BurstFrame4`, `BurstFrame5`, `BurstFrame6`, `BurstEnd`, `WaitOneFrame` |
| Reads | `$A9FF` (`BallStep`); `$B1F6`-`$B209` (`BurstSteps`) |
| Writes | `$A9FF` (`BallStep`) |

### `BurstBall1` (`$B16E`)

**Burst step 0: the ball at `$AB2D` + `$FF62`**

Witness: L1 7 (fire, rightspike, rzx45, rzx56, rzx68).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 2, `stage1/rzx/l68` 2, `docs/integrate/rec/rightspike` 1 and 2 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstBall` |

### `BurstBall2` (`$B177`)

**Burst step 1: the ball at `$AB2D` + `$FF62` (off) and + `$2F12`**

Witness: L1 7 (fire, rightspike, rzx45, rzx56, rzx68).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 2, `stage1/rzx/l68` 2, `docs/integrate/rec/rightspike` 1 and 2 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstBall` |

### `BurstBall3` (`$B186`)

**Burst step 2: the ball at `$AB2D` + `$2F12` (off) and + `$2712`**

Witness: L1 7 (fire, rightspike, rzx45, rzx56, rzx68).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 2, `stage1/rzx/l68` 2, `docs/integrate/rec/rightspike` 1 and 2 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstBall` |

### `BurstFrame1` (`$B195`)

**Burst step 3: picture `$81F5`**

Witness: L1 15 (fire, rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 3, `stage1/rzx/l45` 2, `stage1/rzx/l68` 2 and 7 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstPicture` |

### `BurstFrame2` (`$B19E`)

**Burst step 4: picture `$822D`**

Witness: L1 15 (fire, rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 3, `stage1/rzx/l45` 2, `stage1/rzx/l68` 2 and 7 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstPicture` |

### `BurstFrame3` (`$B1A7`)

**Burst step 5: picture `$8265`**

Witness: L1 15 (fire, rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 3, `stage1/rzx/l45` 2, `stage1/rzx/l68` 2 and 7 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstPicture` |

### `BurstFrame4` (`$B1B0`)

**Burst step 6: picture `$829D`**

Witness: L1 15 (fire, rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 3, `stage1/rzx/l45` 2, `stage1/rzx/l68` 2 and 7 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstPicture` |

### `BurstFrame5` (`$B1B9`)

**Burst step 7: picture `$82D5`**

Witness: L1 15 (fire, rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 3, `stage1/rzx/l45` 2, `stage1/rzx/l68` 2 and 7 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstPicture` |

### `BurstFrame6` (`$B1C2`)

**Burst step 8: picture `$830D`**

Witness: L1 15 (fire, rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 3, `stage1/rzx/l45` 2, `stage1/rzx/l68` 2 and 7 more) |
| Called from | `BallBurst` |
| Calls | `MainLoop` (tail), `DrawBurstPicture` |

### `BurstEnd` (`$B1CB`)

**Burst step 9: the blank picture `$6708` over it, then LoseLife**

Witness: L1 15 (fire, rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 3, `stage1/rzx/l45` 2, `stage1/rzx/l68` 2 and 7 more) |
| Called from | `BallBurst` |
| Calls | `DrawBurstPicture`, `LoseLife` (tail) |

### `DrawBurstPicture` (`$B1D4`)

**Stores the picture at DE (14 lines, `$A9FE` = 4) at the burst point `$AB2D` + `$1712`**

Witness: L1 105 (fire, rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 105 calls (`stage1/rzx/l56` 21, `stage1/rzx/l45` 14, `stage1/rzx/l68` 14 and 7 more) |
| Called from | `BurstFrame1`, `BurstFrame2`, `BurstFrame3`, `BurstFrame4`, `BurstFrame5`, `BurstFrame6`, `BurstEnd` |
| Calls | `DrawSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `DrawBurstBall` (`$B1E7`)

**XOR the player's round ball at `$AB2D` + BC**

Witness: L1 35 (fire, rightspike, rzx45, rzx56, rzx68).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 35 calls (`stage1/rzx/l56` 10, `stage1/rzx/l68` 10, `stage1/rzx/l45` 5 and 2 more) |
| Called from | `BurstBall1`, `BurstBall2`, `BurstBall3` |
| Calls | `PlayerBallSprite`, `DrawBallXor` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |

### `BallFallOut` (`$B20A`)

**State 7: the ball sinks out through the bottom edge, one LostSteps routine a frame, then LoseLife**

Jumps to LostSteps[BallStep] after BallStep + 1, `$A9FE` = 4. Five steps: the ball moves down and is drawn with fewer lines (9, 5, 1), the last plays the sound `$F4CB` and calls LoseLife `$BA93`. Witness: 8 falls in the recordings.

Witness: L1 40 (rzx x6).

[Animation: `BallFallOut` at work](img/routines/BallFallOut.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 40 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 15, `stage1/rzx/l10` 5, `stage1/rzx/l36` 5 and 3 more) |
| Called from | `MainLoop` |
| Calls | `LostStep1`, `LostStep2`, `LostStep3`, `LostStep4`, `LostStep5` |
| Reads | `$A9FF` (`BallStep`); `$B2B8`-`$B2C1` (`LostSteps`) |
| Writes | `$A9FE`-`$A9FF` (`SpriteWidth`, `BallStep`) |

### `LostStep1` (`$B230`)

**Falling out, step 0: the round ball off, `$AA03` + `$E050`, on again**

Witness: L1 8 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 3, `stage1/rzx/l10` 1, `stage1/rzx/l36` 1 and 3 more) |
| Called from | `BallFallOut` |
| Calls | `MainLoop` (tail), `DrawBallRound` |
| Reads | `$AA03`-`$AA04` (`BallScrAddr`) |
| Writes | `$AA03`-`$AA04` (`BallScrAddr`) |

### `LostStep2` (`$B243`)

**Step 1: the ball off, the sprite kept in `$AA01`, `$AA03` + `$2000`, 9 lines of it on**

Witness: L1 8 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 3, `stage1/rzx/l10` 1, `stage1/rzx/l36` 1 and 3 more) |
| Called from | `BallFallOut` |
| Calls | `MainLoop` (tail), `PlayerBallSprite`, `DrawBallRound`, `XorSprite` |
| Reads | `$AA03`-`$AA04` (`BallScrAddr`) |
| Writes | `$AA01`-`$AA04` (`BallSprite`, `BallScrAddr`) |

### `LostStep3` (`$B262`)

**Step 2: 9 lines off, `$AA03` + `$E050`, 5 lines on**

Witness: L1 8 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 3, `stage1/rzx/l10` 1, `stage1/rzx/l36` 1 and 3 more) |
| Called from | `BallFallOut` |
| Calls | `MainLoop` (tail), `XorSprite` |
| Reads | `$AA01`-`$AA04` (`BallSprite`, `BallScrAddr`) |
| Writes | `$AA03`-`$AA04` (`BallScrAddr`) |

### `LostStep4` (`$B284`)

**Step 3: 5 lines off, `$AA03` + `$2000`, 1 line on**

Witness: L1 8 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 3, `stage1/rzx/l10` 1, `stage1/rzx/l36` 1 and 3 more) |
| Called from | `BallFallOut` |
| Calls | `MainLoop` (tail), `XorSprite` |
| Reads | `$AA01`-`$AA04` (`BallSprite`, `BallScrAddr`) |
| Writes | `$AA03`-`$AA04` (`BallScrAddr`) |

### `LostStep5` (`$B2A6`)

**Step 4: the last line off, the sound `$F4CB`, LoseLife**

Witness: L1 8 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 3, `stage1/rzx/l10` 1, `stage1/rzx/l36` 1 and 3 more) |
| Called from | `BallFallOut` |
| Calls | `LoseLife` (tail), `XorSprite`, `SfxLifeLost` |
| Reads | `$AA01`-`$AA04` (`BallSprite`, `BallScrAddr`) |

### `LevelEnd` (`$B2C2`)

**State 8: the ball sinks into the exit, the timer counts into the score, the next level**

Reached when the ball lands on the exit (platform `$0B`: DecideMove sets state 8). With CheatMode `$ADDD` the level would come from a routine's L (CALL `$B754`, a RET; then L reduced below 100 by steps of 97: known only from the code). Else NextLevel `$B2D5`.

Witness: L1 102 (exitbelow, menu, l x12, rzx x88).

NextLevel: level 99 is followed by level 0 (witness: one run of `$B2DE` in the RZX). Then 9 times: two bytes of the ball's top line cleared (`$C71F`, `$B515`), the ball one line lower (`$0800`; `$C050` more past a character row), the round ball stored there (`$E318`), a frame, the animations (`$BD21`, `$BBCD`, `$BC30`), a frame. Then the last line cleared, the sound `$F49A` and 15 HALTs. Then the rest of the timer `$AB04` goes into the score one point a tick: the tick sound `$F4F9`, score `$AAFB` + 1, the score printed (`$E60C`), until the timer is 0. The working copy goes back to the player's record (`$AB09`; `$AB10` for player 2), and the demo ends (`$B7A9`, back to the menu) or a game waits about a second (`$B7B8`) and starts the level at LifeStart.

[Animation: `LevelEnd` at work](img/routines/LevelEnd.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 102 runs of its first instruction, entered by a jump (`docs/integrate/rec/exitbelow` 1, `stage1/menu` 1, `stage1/rzx/l00` 1 and 99 more) |
| Called from | `MainLoop` |
| Calls | `LifeStart` (tail), `PlayerBallSprite`, `LineAddress`, `FirmwareStub3`, `GameOverPause` (tail), `WaitKeyOrSecond`, `WaitOneFrame`, `AnimateFires`, `AnimateWalls`, `AnimateExit`, `ScreenAddrToLine`, `DrawSprite`, `PrintNumber5`, `SfxLevelEnd`, `SfxTimerTick` |
| Reads | `$AA03`-`$AA04` (`BallScrAddr`); `$AAFB`-`$AB05` (`Score`, `Water`, `Keys`, `Hammers` and 5 more); `$ABA6` (`DemoFlag`); `$ADDB`-`$ADDD` (`CurrentPlayer`, `PlayerCount`, `CheatMode`); `$B35C` (`LevelEndPause+3`); `$B52C` (`SpectrumColumn`); 6 more ranges |
| Writes | `$4042`-`$407C` (screen); `$40C2`-`$40F7` (screen); `$4142`-`$417C` (screen); `$41C2`-`$41F7` (screen); `$4242`-`$425C` (screen); `$42C2`-`$42D7` (screen); 44 more ranges |

### `ChooseNextState` (`$B7E4`)

**At a landing, choose the ball's next state from the platform and the keys**

Called by the bounce handlers (`$ACB9`, `$B009`, `$B0AE`, `$B0CB`, `$B0DA`) when the ball lands on a cell. In play (`$ABA6` = 0), in this order: SpringArmed `$AA13` = 1 gives state 3 (up); the cell's platform (`$AB1C`) `$0B`, the open exit, gives 8 (level end); 7 gives 2 (right: conveyor); 6 gives 1 (left: conveyor); 5 gives 5 (stopped, waiting for left or right); `$0A` (bricks) keeps the state; the left key (KeySlots `$F086`, LeftKey `$B447`) gives 1; the right key (`$F087`, RightKey `$B44E`) gives 2; a ball going up (3) with the down key (`$F085`, DownKey `$B45C`) gives 0, and without it stays 3; anything else gives 0 (bounce in place).

In the demo (`$ABA6` not 0) the exit and the conveyors are checked first, then the next byte of the demo moves (the pointer `$ABA4` is advanced) becomes BallState `$AA00`, and SpringArmed still forces 3. Output: BallState `$AA00`. Witness: every play recording (rzx x100, menu demo).

Witness: L1 6229 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

[Animation: `ChooseNextState` at work](img/routines/ChooseNextState.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 251 calls, 61,102 t-states own (0.00 %) |
| Runs (the other recordings) | 5,978 calls (`stage1/menu` 365, `stage1/rzx/l46` 229, `stage1/rzx/l38` 158 and 116 more) |
| Called from | `LifeStart`, `BallUpMove`, `LandingCheck` |
| Calls | `TestLeft`, `TestRight`, `TestDown`, `SetStateLeft` (tail), `SetStateRight` (tail) |
| Reads | `$AA00` (`BallState`); `$AA13` (`SpringArmed`); `$AB1C` (`CellPlatform`); `$ABA4`-`$ABA6` (`DemoInputPtr`, `DemoFlag`); `$D25B`-`$D28A` (`DemoMoves+1`) |
| Writes | `$AA00` (`BallState`); `$ABA4`-`$ABA5` (`DemoInputPtr`) |

### `SetStateLeft` (`$B84F`)

**BallState = 1 (moving left)**

Also the target of the left conveyor and of the stopped ball's left key (`$B13F`).

Witness: L1 980 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx00-rzx17, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 314 calls (`stage2/rec/l96` 17, `stage2/rec/l59` 17, `stage2/rec/l51` 16 and 25 more) |
| Called from | `BallStopped`, `ChooseNextState` (tail) |
| Writes | `$AA00` (`BallState`) |

### `SetStateRight` (`$B855`)

**BallState = 2 (moving right)**

Also the target of the right conveyor and of the stopped ball's right key (`$B139`).

Witness: L1 1246 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 14 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 348 calls (`stage1/rzx/l96` 24, `stage1/rzx/l86` 21, `stage1/rzx/l58` 21 and 22 more) |
| Called from | `BallStopped`, `ChooseNextState` (tail) |
| Writes | `$AA00` (`BallState`) |

### `SetStateDown` (`$B861`)

**BallState = 4 (moving down): never called**

LD A,4: LD (`$AA00`),A: RET, like its neighbours, but no code jumps here (known only from the code: a leftover of ChooseNextState).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SetStateStopped` (`$B867`)

**BallState = 5 (stopped on a type 5 platform)**

Witness: L1 141 (l x6, rzx x26).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 141 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 25, `stage1/rzx/l96` 24, `stage2/rec/l96` 10 and 29 more) |

### `DrawBallRight` (`$B882`)

**Draw the ball's frame for a move to the right**

Sets the width `$A9FE` to 4 bytes, takes the frame address for the step BallStep `$A9FF` from BallFramesRight `$C4E2` into `$AA01` and calls DrawBall `$ADE6`. Called by the right-move handler (`$AF73`).

Witness: L1 18993 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 213 calls, 34,861 t-states own (0.00 %) |
| Runs (the other recordings) | 18,780 calls (`stage1/rzx/l43` 419, `stage1/rzx/l00` 368, `stage1/rzx/l15` 341 and 115 more) |
| Called from | `BallRightMove` |
| Calls | `PlayerBallSprite` |
| Reads | `$A9FF` (`BallStep`); `$C4E2`-`$C501` (`BallFramesRight`) |
| Writes | `$A9FE`-`$AA02` (`SpriteWidth`, `BallStep`, `BallState`, `BallSprite`) |

### `DrawBallLeft` (`$B8A2`)

**Draw the ball's frame for a move to the left**

As DrawBallRight with the table BallFramesLeft `$C502`. Called by the left-move handler (`$AEF9`).

Witness: L1 15494 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx00-rzx18, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 149 calls, 24,405 t-states own (0.00 %) |
| Runs (the other recordings) | 15,345 calls (`stage1/rzx/l43` 419, `stage1/rzx/l00` 368, `stage1/rzx/l15` 293 and 109 more) |
| Called from | `BallLeftMove` |
| Calls | `PlayerBallSprite` |
| Reads | `$A9FF` (`BallStep`); `$C502`-`$C521` (`BallFramesLeft`) |
| Writes | `$A9FE`-`$AA02` (`SpriteWidth`, `BallStep`, `BallState`, `BallSprite`) |

### `HitBrick` (`$B8D1`)

**The ball going up meets a brick: crumble a layer (a hammer for an intact brick) and send it down**

Called by the up-move handlers (`$CCE9-$CE15`) when the ball is under a brick cell. B = BrickContact `$E1C1`[BallStep]: the layer count a brick must have for the ball to touch it at this step (5, 4, 3, 2, 1, 8, 7, 6 for steps 0-7). HL = BrickLayers `$AAD7` + the cell `$AA44` (8 layers when the level is built, `$D180`); the address goes to `$AA07`, the count to `$AA0B`. No contact (count not B): return NZ.

Contact: the screen address of the layer (`$AA03` - `$2002`, wrapped into the CPC screen) goes to `$AB31`, BallState becomes 4 (down). At step 5 (an intact brick) a hammer is needed: Hammers `$AAFF` - 1 and the HUD (`$E5E6`); without one (`$B952`) BallStep becomes 3 and the brick is untouched. Else BallStep becomes 8 - step (the way down mirrors the way up), the crumble animation starts (`$AB33` = 1, step `$AB34` = 0, BrickStep `$BE94`), the layer count goes down by one and at 0 the cell's platform becomes 0 (the brick is gone). Witness: 369 contacts in the recordings, 47 at step 5 (each with a hammer), 46 bricks gone.

Witness: L1 1837 (l51, l59, l96, l98, rzx x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,837 calls (`stage1/rzx/l46` 252, `stage1/rzx/l38` 180, `stage1/rzx/l75` 144 and 28 more) |
| Called from | `UpStep0`, `UpStep1`, `UpStep2`, `UpStep3`, `UpStep4`, `UpStep5`, `UpStep6`, `UpStep7` |
| Calls | `HammersToHud` |
| Reads | `$A9FF`-`$AA0B` (`BallStep`, `BallState`, `BallSprite`, `BallScrAddr` and 4 more); `$AA44` (`BallCell`); `$AADD`-`$AAFF` (`BrickLayers+6`, `Score`, `Water`, `Keys` and 1 more); `$E1C1`-`$E1C8` (`BrickSteps`) |
| Writes | `$A9FF`-`$AA0B` (`BallStep`, `BallState`, `BallSprite`, `BallScrAddr` and 4 more); `$AA71`-`$AA88` (`CellPlatforms+6`); `$AADD`-`$AAFF` (`BrickLayers+6`, `Score`, `Water`, `Keys` and 1 more); `$AB31`-`$AB34` (`BrickLayerAddr`, `BrickActive`, `BrickAnimStep`) |

### `BounceStep0` (`$C778`)

**Bounce in place, step 0: the landing sound, then the handler of the platform type**

The first handler of BounceSteps `$AE9B`. If `$ABA7` is 4 (a fire was just put out) it is cleared and no sound plays; otherwise when the cell below holds bricks (`$0A`) or the ball's cell has a platform (`$AB1C` not 0), `$ABA7` = 1 and the bounce sound `$F3C8` plays. Then it jumps to BounceTypeTable[`$AB1C`] `$C82D`: types 2-4 start crumbling the platform, the others go to the state's tail `$AE65`.

Witness: L1 1222 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 203 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 64,554 t-states own (0.01 %) |
| Runs (the other recordings) | 1,019 runs of its first instruction, entered by a jump (`stage1/menu` 299, `stage1/rzx/l18` 76, `stage1/gameover` 30 and 109 more) |
| Called from | `StepDispatch` |
| Calls | `BallBounceMove`, `BounceCrumble2`, `BounceCrumble3`, `BounceCrumble4`, `SfxLand` |
| Reads | `$AA44` (`BallCell`); `$AA71`-`$AA94` (`CellPlatforms+6`, `CellWalls`); `$AB1C` (`CellPlatform`); `$ABA7` (`ObjectFlag`); `$C82D`-`$C836` (`BounceTypeTable`) |
| Writes | `$ABA7` (`ObjectFlag`) |

### `BounceCrumble2` (`$C7C1`)

**Bounce on a type-2 platform: it starts turning into type 3**

Calls `$C3D5` (CrumbleSteps2), then the tail `$AE65`.

Witness: L1 80 (l45, l56, l68, rzx x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 80 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 25, `stage1/rzx/l16` 5, `stage1/rzx/l68` 5 and 27 more) |
| Called from | `BounceStep0` |
| Calls | `BallBounceMove` (tail), `StartWearTo3` |

### `BounceCrumble3` (`$C7C7`)

**Bounce on a type-3 platform: it starts turning into type 4**

Calls `$C3F8` (CrumbleSteps3), then `$AE65`.

Witness: L1 105 (scoreloop, l36, l45, l56, l68, rzx x38).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 105 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 25, `stage1/rzx/l16` 6, `stage1/rzx/l79` 6 and 40 more) |
| Called from | `BounceStep0` |
| Calls | `BallBounceMove` (tail), `StartWearTo4` |

### `BounceCrumble4` (`$C7CD`)

**Bounce on a type-4 platform: it starts vanishing**

Calls `$C41B` (CrumbleSteps4), then `$AE65`.

Witness: L1 225 (scoreloop, l x6, rzx x55).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 225 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 26, `docs/integrate/rec/scoreloop` 15, `stage1/rzx/l87` 11 and 59 more) |
| Called from | `BounceStep0` |
| Calls | `BallBounceMove` (tail), `StartFallAway` |

### `BounceStep1` (`$C7D3`)

**Bounce, step 1: start the crumble animation if one is pending**

If `$AA14` is set (a crumble was started at step 0), `$AA15` = `$AA14`, which lets `$C19D` play it. Then `$AE65`.

Witness: L1 1220 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 203 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 6,090 t-states own (0.00 %) |
| Runs (the other recordings) | 1,017 runs of its first instruction, entered by a jump (`stage1/menu` 298, `stage1/rzx/l18` 76, `stage1/gameover` 30 and 109 more) |
| Called from | `StepDispatch` |
| Calls | `BallBounceMove` (tail), `BounceStepIdle` (falls into) |
| Reads | `$AA14` (`CrumblePending`) |
| Writes | `$AA15` (`CrumbleActive`) |

### `BounceStepIdle` (`$C7DE`)

**Bounce, steps 2-8: nothing but the tail**

Jumps to `$AE65`; also the end of BounceStep1.

Witness: L1 8889 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1,421 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 14,210 t-states own (0.00 %) |
| Runs (the other recordings) | 410 calls (`stage1/rzx/l18` 76, `docs/integrate/rec/scoreloop` 18, `stage1/rzx/l16` 17 and 70 more) |
| Called from | `StepDispatch`, `BounceStep1` (falls into) |
| Calls | `BallBounceMove` (tail) |

### `BounceStep9` (`$C7E1`)

**Bounce, step 9: arm the spring and draw its first frame**

In the demo (`$ABA6` not 0) the spring is armed when the next demo move (`$ABA4` + 1) is 9; in play when `$B463` finds up or fire pressed. Arming calls LoadSpring `$BD73`. If SpringArmed `$AA13`, `$BDA6` draws the first press frame. Then `$AE65`.

Witness: L1 1205 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 203 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 18,963 t-states own (0.00 %) |
| Runs (the other recordings) | 1,002 runs of its first instruction, entered by a jump (`stage1/menu` 296, `stage1/rzx/l18` 76, `stage2/rec/twoname` 27 and 109 more) |
| Called from | `StepDispatch` |
| Calls | `TestUpOrFire`, `LoadSpring`, `SpringStep1`, `BounceStep10` (falls into) |
| Reads | `$AA13` (`SpringArmed`); `$ABA4`-`$ABA6` (`DemoInputPtr`, `DemoFlag`); `$D25B`-`$D25F` (`DemoMoves+1`); `$D286`-`$D288` (`DemoMoves+44`) |

### `BounceStep10` (`$C803`)

**Bounce, step 10: nothing but the tail**

Witness: L1 2410 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 197 calls, 4,060 t-states own (0.00 %) |
| Runs (the other recordings) | 906 calls (`stage1/menu` 293, `stage1/rzx/l18` 75, `stage2/rec/twoname` 24 and 102 more) |
| Called from | `StepDispatch`, `BounceStep9` (falls into) |
| Calls | `BallBounceMove` (tail) |

### `BounceStep11` (`$C806`)

**Bounce, step 11: the second spring frame**

If SpringArmed, `$BDAE` draws it. Then `$AE65`.

Witness: L1 1205 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 203 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 6,132 t-states own (0.00 %) |
| Runs (the other recordings) | 1,002 runs of its first instruction, entered by a jump (`stage1/menu` 296, `stage1/rzx/l18` 76, `stage2/rec/twoname` 27 and 109 more) |
| Called from | `StepDispatch` |
| Calls | `SpringStep2`, `BounceStep12` (falls into) |
| Reads | `$AA13` (`SpringArmed`) |

### `BounceStep12` (`$C80E`)

**Bounce, step 12: nothing but the tail**

Witness: L1 2410 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 197 calls, 4,060 t-states own (0.00 %) |
| Runs (the other recordings) | 906 calls (`stage1/menu` 293, `stage1/rzx/l18` 75, `stage2/rec/twoname` 24 and 102 more) |
| Called from | `StepDispatch`, `BounceStep11` (falls into) |
| Calls | `BallBounceMove` (tail) |

### `BounceStep13` (`$C811`)

**Bounce, step 13: take the object in the cell**

Calls TakeObject `$B958`, then `$AE65`.

Witness: L1 1205 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 203 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 5,481 t-states own (0.00 %) |
| Runs (the other recordings) | 1,002 runs of its first instruction, entered by a jump (`stage1/menu` 296, `stage1/rzx/l18` 76, `stage2/rec/twoname` 27 and 109 more) |
| Called from | `StepDispatch` |
| Calls | `BallBounceMove` (tail), `TakeObject` |

### `BounceStep14` (`$C817`)

**Bounce, step 14: the third spring frame**

If SpringArmed, `$BDB6`. Then `$AE65`.

Witness: L1 1205 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 203 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,162 t-states own (0.00 %) |
| Runs (the other recordings) | 1,002 runs of its first instruction, entered by a jump (`stage1/menu` 296, `stage1/rzx/l18` 76, `stage2/rec/twoname` 27 and 109 more) |
| Called from | `StepDispatch` |
| Calls | `BallBounceMove` (tail), `SpringStep3` |
| Reads | `$AA13` (`SpringArmed`) |

### `BounceStep15` (`$C822`)

**Bounce, step 15: the last spring frame**

If SpringArmed, `$BDBE`. Then `$AE65`, whose end at step 15 calls ChooseNextState `$B7E4`.

Witness: L1 1204 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 203 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,162 t-states own (0.00 %) |
| Runs (the other recordings) | 1,001 runs of its first instruction, entered by a jump (`stage1/menu` 296, `stage1/rzx/l18` 76, `stage2/rec/twoname` 27 and 109 more) |
| Called from | `StepDispatch` |
| Calls | `BallBounceMove` (tail), `SpringStep4` |
| Reads | `$AA13` (`SpringArmed`) |

### `LeftStep0` (`$C847`)

**Move left, step 0: the sound, then the handler of the platform the ball leaves**

As BounceStep0 (the `$ABA7` and `$F3C8` sound rule), then it jumps to LeftTakeoffTable[`$AB1C`] `$C6A8`.

Witness: L1 993 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx00-rzx17, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,821 t-states own (0.00 %) |
| Runs (the other recordings) | 984 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 31, `stage1/rzx/l00` 23, `stage1/rzx/l15` 18 and 108 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove`, `LeftTakeoff`, `LeftCrumble2`, `LeftCrumble3`, `LeftCrumble4`, `SfxLand` |
| Reads | `$AA44` (`BallCell`); `$AA71`-`$AA94` (`CellPlatforms+6`, `CellWalls`); `$AB1C` (`CellPlatform`); `$ABA7` (`ObjectFlag`); `$C6A8`-`$C6B5` (`LeftTakeoffTable`) |
| Writes | `$ABA7` (`ObjectFlag`) |

### `LeftTakeoff` (`$C890`)

**Leave a platform of type 1-5 to the left: draw it tilted**

Copies TakeoffTable[`$AB1C` - 1]'s 18-byte record to `$AB4D`, draws picture 0 (`$BE43`) and picture 1 (`$BE5E`) by XOR, sets `$A9FD` = 1 (to be undone at step 5), then the left tail `$AEE2`.

Witness: L1 554 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx x85).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 8 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 4,504 t-states own (0.00 %) |
| Runs (the other recordings) | 216 calls (`stage1/rzx/l50` 9, `stage1/rzx/l48` 9, `stage2/rec/l59` 7 and 61 more) |
| Called from | `LeftStep0`, `LeftCrumble2` (tail), `LeftCrumble3` (tail), `LeftCrumble4` (tail) |
| Calls | `BallLeftMove` (tail), `TiltPart0`, `TiltPart1` |
| Reads | `$AB1C` (`CellPlatform`); `$C5CC`-`$C5D5` (`TakeoffTable`); `$C64E`-`$C6A7` (`TakeoffPics`, `TakeoffPics2`, `TakeoffPics3`, `TakeoffPics4` and 1 more) |
| Writes | `$A9FD` (`TakeoffDrawn`); `$AB4D`-`$AB5E` (`TakeoffRecord`) |

### `LeftCrumble2` (`$C8BC`)

**Leave a type-2 platform to the left: start its crumbling**

Unless a crumble is already playing (`$AA15`), calls `$C3D5`, then LeftTakeoff; else the tail.

Witness: L1 41 (menu, l10, l35, l51, l68, rzx x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 41 runs of its first instruction, entered by a jump (`stage1/rzx/l25` 5, `stage1/rzx/l50` 4, `stage1/rzx/l49` 3 and 22 more) |
| Called from | `LeftStep0` |
| Calls | `StartWearTo3`, `LeftTakeoff` (tail) |
| Reads | `$AA15` (`CrumbleActive`); `$AB1C` (`CellPlatform`); `$C5CE`-`$C5CF` (`TakeoffTable+2`); `$C660`-`$C671` (`TakeoffPics2`) |
| Writes | `$A9FD` (`TakeoffDrawn`); `$AB4D`-`$AB5E` (`TakeoffRecord`) |

### `LeftCrumble3` (`$C8CA`)

**Leave a type-3 platform to the left**

As LeftCrumble2 with `$C3F8`.

Witness: L1 84 (l x8, rzx x41).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 84 runs of its first instruction, entered by a jump (`stage2/rec/l59` 5, `stage1/rzx/l30` 4, `stage1/rzx/l59` 4 and 46 more) |
| Called from | `LeftStep0` |
| Calls | `StartWearTo4`, `LeftTakeoff` (tail) |
| Reads | `$AA15` (`CrumbleActive`); `$AB1C` (`CellPlatform`); `$C5D0`-`$C5D1` (`TakeoffTable+4`); `$C672`-`$C683` (`TakeoffPics3`) |
| Writes | `$A9FD` (`TakeoffDrawn`); `$AB4D`-`$AB5E` (`TakeoffRecord`) |

### `LeftCrumble4` (`$C8D8`)

**Leave a type-4 platform to the left**

As LeftCrumble2 with `$C41B`.

Witness: L1 142 (l x7, rzx x58).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 142 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 12, `stage1/rzx/l47` 9, `stage1/rzx/l48` 6 and 62 more) |
| Called from | `LeftStep0` |
| Calls | `StartFallAway`, `LeftTakeoff` (tail) |
| Reads | `$AA15` (`CrumbleActive`); `$AB1C` (`CellPlatform`); `$C5D2`-`$C5D3` (`TakeoffTable+6`); `$C684`-`$C695` (`TakeoffPics4`) |
| Writes | `$A9FD` (`TakeoffDrawn`); `$AB4D`-`$AB5E` (`TakeoffRecord`) |

### `LeftStepIdle` (`$C8E6`)

**Move left, steps 1-4: the tail only**

Witness: L1 3972 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx00-rzx17, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 36 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 360 t-states own (0.00 %) |
| Runs (the other recordings) | 3,936 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 124, `stage1/rzx/l00` 92, `stage1/rzx/l15` 72 and 108 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail) |

### `LeftStep5` (`$C8E9`)

**Move left, step 5: undo the take-off pictures and meet the wall on the left**

If `$A9FD`, picture 1 and 0 are XORed off and `$A9FD` = 0. A pending crumble starts (`$AA15` = `$AA14`). Then the screen byte left of the ball (`$AA03`, through ScreenAddrToLine and `$B515`, column (ByteColumn - 2) / 2) is read: 0 means no wall, the move goes on. The pattern `$7C` (wall type 4), or no key (Keys `$AAFE` = 0), or a wall type that is no lock: sound `$F43E` and the ball turns back (LeftBounceBack). A lock (wall `$AA8F`[`$AA44` - 1] of type 1-3) with a key: the lock becomes type - 1, its animation (LockOpenSteps1-3) starts at the wall's place (`$AB2D` + `$2EBE`), Keys - 1 (HUD `$E5D3`), and the ball turns back too.

Witness: L1 993 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx00-rzx17, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,729 t-states own (0.00 %) |
| Runs (the other recordings) | 984 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 31, `stage1/rzx/l00` 23, `stage1/rzx/l15` 18 and 108 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail), `BallRightMove` (tail), `LineAddress`, `WallScreenAddr`, `TiltPart0`, `TiltPart1`, `ScreenAddrToLine`, `LeftWallBlocked` (tail), `KeysToHud` |
| Reads | `$4000`-`$4019` (screen); `$4080`-`$4099` (screen); `$4800`-`$4819` (screen); `$4880`-`$4899` (screen); `$5000`-`$5019` (screen); `$5085`-`$5099` (screen); 13 more ranges |
| Writes | `$A9FD`-`$AA00` (`TakeoffDrawn`, `SpriteWidth`, `BallStep`, `BallState`); `$AA15`-`$AA1D` (`CrumbleActive`, `FireFrame`, `WallFrame`, `LockAnimAddr` and 3 more); `$AA8F`-`$AAB1` (`CellWalls`); `$AAFE` (`Keys`) |

### `LeftWallBlocked` (`$C9A2`)

**LeftWallBlocked**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9 calls (`stage2/rec/twoname` 9) |
| Called from | `LeftStep5` (tail) |
| Calls | `SfxWallBounce` |
| Writes | `$A9FF`-`$AA00` (`BallStep`, `BallState`) |

### `LeftStepIdle2` (`$C9A7`)

**Move left, steps 6 and 7: the tail only**

Witness: L1 1760 (c1, exitbelow, fire, gameover, menu, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 18 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 180 t-states own (0.00 %) |
| Runs (the other recordings) | 1,742 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 48, `stage1/rzx/l00` 46, `stage1/rzx/l15` 36 and 106 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail) |

### `LeftStep8` (`$C9AA`)

**Move left, step 8: enter the cell on the left, unless bricks fill it**

If the brick counter `$AAD7`[`$AA44` - 1] is not 0 the ball turns right (BallState 2) and stays in its cell; else `$AA44` - 1.

Witness: L1 880 (c1, exitbelow, fire, gameover, menu, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,116 t-states own (0.00 %) |
| Runs (the other recordings) | 871 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l15` 18 and 106 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail), `BallRightMove` (tail) |
| Reads | `$AA0B` (`CellByte`); `$AA44` (`BallCell`); `$AAD7`-`$AAF9` (`BrickLayers`) |
| Writes | `$AA00`-`$AA0B` (`BallState`, `BallSprite`, `BallScrAddr`, `BallOldAddr` and 3 more); `$AA44` (`BallCell`) |

### `LeftStep9` (`$C9CE`)

**Move left, step 9: arm the spring, put out a fire**

The spring as at BounceStep9 (demo move 9 or `$B463`, LoadSpring, `$BDA6`). If the platform `$AB1C` is on fire (8 or 9) and the ball holds a drop (Water `$AAFD`), Water - 1 (HUD `$E5C0`), `$ABA7` = 4 and FireOutLeft starts at the cell's screen address (from `$E131`). Then `$AEE2`.

Witness: L1 885 (c1, exitbelow, fire, gameover, menu, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,297 t-states own (0.00 %) |
| Runs (the other recordings) | 876 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l15` 18 and 106 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail), `TestUpOrFire`, `LoadSpring`, `SpringStep1`, `LeftStep10` (falls into), `WaterToHud` |
| Reads | `$AA13` (`SpringArmed`); `$AA44` (`BallCell`); `$AAFD` (`Water`); `$AB1C` (`CellPlatform`); `$ABA4`-`$ABA6` (`DemoInputPtr`, `DemoFlag`); `$D25E`-`$D284` (`DemoMoves+4`); 2 more ranges |
| Writes | `$AAFD` (`Water`); `$AB26`-`$AB2B` (`FireOutStep`, `FireOutSteps`, `FireOutAddr`, `FireOutActive`); `$ABA7` (`ObjectFlag`) |

### `LeftStep10` (`$CA38`)

**Move left, step 10: the tail only**

Witness: L1 897 (c1, exitbelow, fire, gameover, menu, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 90 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `StepDispatch`, `LeftStep9` (falls into) |
| Calls | `BallLeftMove` (tail) |

### `LeftStep11` (`$CA3B`)

**Move left, step 11: the second spring frame**

Witness: L1 885 (c1, exitbelow, fire, gameover, menu, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 284 t-states own (0.00 %) |
| Runs (the other recordings) | 876 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l15` 18 and 106 more) |
| Called from | `StepDispatch` |
| Calls | `SpringStep2`, `LeftStep12` (falls into) |
| Reads | `$AA13` (`SpringArmed`) |

### `LeftStep12` (`$CA43`)

**Move left, step 12: the tail only**

Witness: L1 1932 (c1, exitbelow, fire, gameover, menu, l x11, rzx00-rzx18, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 7 calls, 190 t-states own (0.00 %) |
| Runs (the other recordings) | 752 calls (`stage1/rzx/l43` 21, `stage1/rzx/l00` 21, `stage1/rzx/l15` 18 and 106 more) |
| Called from | `StepDispatch`, `LeftStep11` (falls into) |
| Calls | `BallLeftMove` (tail) |

### `LeftStep13` (`$CA46`)

**Move left, step 13: take the object**

Witness: L1 1047 (c1, exitbelow, fire, gameover, menu, l x11, rzx00-rzx18, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 10 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 270 t-states own (0.00 %) |
| Runs (the other recordings) | 1,037 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l96` 21 and 108 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail), `TakeObject` |

### `LeftStep14` (`$CA4C`)

**Move left, step 14: the third spring frame**

Witness: L1 1047 (c1, exitbelow, fire, gameover, menu, l x11, rzx00-rzx18, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 10 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 414 t-states own (0.00 %) |
| Runs (the other recordings) | 1,037 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l96` 21 and 108 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail), `SpringStep3` |
| Reads | `$AA13` (`SpringArmed`) |

### `LeftStep15` (`$CA57`)

**Move left, step 15: the last spring frame, then death on fire or spikes**

If SpringArmed, `$BDBE`. Landing on a platform of type 8 or 9 (still burning: no water was left at step 9) plays `$F483` and kills (stage2/rec/fire: level 38, Water POKEd to 0, left onto cell 31); type 12 (spikes) plays `$F4B4` and kills: the ball is drawn at the step offsets `$AF35` and the burst state begins (`$B0ED`). Otherwise the tail `$AEE2`. Witness: the spike death ran once (LeftSpikeDeath); the fire death once, in stage2/rec/fire (LeftFireDeath).

Witness: L1 1047 (c1, exitbelow, fire, gameover, menu, l x11, rzx00-rzx18, rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 10 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,114 t-states own (0.00 %) |
| Runs (the other recordings) | 1,037 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l96` 21 and 108 more) |
| Called from | `StepDispatch` |
| Calls | `BallStepMove`, `BallLeftMove` (tail), `BallBurstStart` (tail), `SpringStep4`, `SfxFireDeath`, `SfxSpikeDeath` |
| Reads | `$AA13` (`SpringArmed`); `$AB1C` (`CellPlatform`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `RightStep0` (`$CA8D`)

**Move right, step 0: the sound, then the handler of the platform the ball leaves**

The mirror of LeftStep0, through RightTakeoffTable `$C6C2`.

Witness: L1 1266 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 14 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 4,392 t-states own (0.00 %) |
| Runs (the other recordings) | 1,252 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l46` 24, `stage1/rzx/l96` 24 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallRightMove`, `RightTakeoff`, `RightCrumble2`, `RightCrumble3`, `RightCrumble4`, `SfxLand` |
| Reads | `$AA44` (`BallCell`); `$AA71`-`$AA94` (`CellPlatforms+6`, `CellWalls`); `$AB1C` (`CellPlatform`); `$ABA7` (`ObjectFlag`); `$C6C2`-`$C6D1` (`RightTakeoffTable`) |
| Writes | `$ABA7` (`ObjectFlag`) |

### `RightTakeoff` (`$CAD6`)

**Leave a platform of type 1-5 to the right: draw it tilted**

As LeftTakeoff with picture 2 (`$BE79`), then the right tail `$AF5C`.

Witness: L1 650 (c1, exitbelow, gameover, menu, rightspike, twoname, l x12, rzx x89).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 7,355 t-states own (0.00 %) |
| Runs (the other recordings) | 245 calls (`stage1/rzx/l47` 10, `stage1/rzx/l86` 9, `stage2/rec/l59` 9 and 60 more) |
| Called from | `RightStep0`, `RightCrumble2` (tail), `RightCrumble3` (tail), `RightCrumble4` (tail) |
| Calls | `BallRightMove` (tail), `TiltPart0`, `TiltPart2` |
| Reads | `$AB1C` (`CellPlatform`); `$C5CC`-`$C5D5` (`TakeoffTable`); `$C64E`-`$C6A7` (`TakeoffPics`, `TakeoffPics2`, `TakeoffPics3`, `TakeoffPics4` and 1 more) |
| Writes | `$A9FD` (`TakeoffDrawn`); `$AB4D`-`$AB5E` (`TakeoffRecord`) |

### `RightCrumble2` (`$CB02`)

**Leave a type-2 platform to the right**

Witness: L1 46 (l x5, rzx x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 46 runs of its first instruction, entered by a jump (`stage1/rzx/l16` 7, `stage1/rzx/l25` 4, `stage1/rzx/l30` 3 and 21 more) |
| Called from | `RightStep0` |
| Calls | `StartWearTo3`, `RightTakeoff` (tail) |
| Reads | `$AA15` (`CrumbleActive`) |

### `RightCrumble3` (`$CB10`)

**Leave a type-3 platform to the right**

Witness: L1 80 (menu, l x7, rzx x36).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 80 runs of its first instruction, entered by a jump (`stage1/rzx/l47` 9, `stage1/rzx/l50` 4, `stage1/rzx/l61` 4 and 41 more) |
| Called from | `RightStep0` |
| Calls | `StartWearTo4`, `RightTakeoff` (tail) |
| Reads | `$AA15` (`CrumbleActive`); `$AB1C` (`CellPlatform`); `$C5D0`-`$C5D1` (`TakeoffTable+4`); `$C672`-`$C683` (`TakeoffPics3`) |
| Writes | `$A9FD` (`TakeoffDrawn`); `$AB4D`-`$AB5E` (`TakeoffRecord`) |

### `RightCrumble4` (`$CB1E`)

**Leave a type-4 platform to the right**

Witness: L1 183 (l x7, rzx x61).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 183 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 12, `stage1/rzx/l05` 8, `stage1/rzx/l74` 8 and 65 more) |
| Called from | `RightStep0` |
| Calls | `StartFallAway`, `RightTakeoff` (tail) |
| Reads | `$AA15` (`CrumbleActive`); `$AB1C` (`CellPlatform`); `$C5D2`-`$C5D3` (`TakeoffTable+6`); `$C684`-`$C695` (`TakeoffPics4`) |
| Writes | `$A9FD` (`TakeoffDrawn`); `$AB4D`-`$AB5E` (`TakeoffRecord`) |

### `RightStepIdle` (`$CB2C`)

**Move right, steps 1-4: the tail only**

Witness: L1 5064 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 56 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 560 t-states own (0.00 %) |
| Runs (the other recordings) | 5,008 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 96, `stage1/rzx/l46` 96, `stage1/rzx/l96` 96 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallRightMove` (tail) |

### `RightStep5` (`$CB2F`)

**Move right, step 5: undo the take-off pictures and meet the wall on the right**

The mirror of LeftStep5: the screen byte at column (ByteColumn + 3) / 2, the pattern `$3E` for wall type 4, the wall `$AA8F`[`$AA44`], the animation at `$AB2D` + `$2EC8`; the ball turns back to the left (BallState 1, BallStep 11).

Witness: L1 1266 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 14 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 4,503 t-states own (0.00 %) |
| Runs (the other recordings) | 1,252 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l46` 24, `stage1/rzx/l96` 24 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail), `BallRightMove` (tail), `LineAddress`, `WallScreenAddr`, `TiltPart0`, `TiltPart2`, `ScreenAddrToLine`, `KeysToHud`, `SfxWallBounce` |
| Reads | `$4005`-`$401E` (screen); `$4085`-`$409E` (screen); `$4805`-`$481E` (screen); `$4885`-`$489E` (screen); `$5005`-`$501E` (screen); `$5085`-`$509E` (screen); 12 more ranges |
| Writes | `$A9FD`-`$AA00` (`TakeoffDrawn`, `SpriteWidth`, `BallStep`, `BallState`); `$AA15`-`$AA1D` (`CrumbleActive`, `FireFrame`, `WallFrame`, `LockAnimAddr` and 3 more); `$AA8F`-`$AAB0` (`CellWalls`); `$AAFE` (`Keys`) |

### `RightStepIdle2` (`$CBEA`)

**Move right, steps 6 and 7: the tail only**

Witness: L1 2208 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 26 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 260 t-states own (0.00 %) |
| Runs (the other recordings) | 2,182 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 48, `stage1/rzx/l00` 46, `stage1/rzx/l15` 42 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallRightMove` (tail) |

### `RightStep8` (`$CBED`)

**Move right, step 8: enter the cell on the right, unless bricks fill it**

Witness: L1 1104 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,612 t-states own (0.00 %) |
| Runs (the other recordings) | 1,091 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l15` 21 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallLeftMove` (tail), `BallRightMove` (tail) |
| Reads | `$AA0B` (`CellByte`); `$AA44` (`BallCell`); `$AAD8`-`$AAFA` (`BrickLayers+1`) |
| Writes | `$AA00`-`$AA0B` (`BallState`, `BallSprite`, `BallScrAddr`, `BallOldAddr` and 3 more); `$AA44` (`BallCell`) |

### `RightStep9` (`$CC11`)

**Move right, step 9: arm the spring, put out a fire**

As LeftStep9 with FireOutRight.

Witness: L1 1099 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,875 t-states own (0.00 %) |
| Runs (the other recordings) | 1,086 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l15` 21 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallRightMove` (tail), `TestUpOrFire`, `LoadSpring`, `SpringStep1`, `RightStep10` (falls into), `WaterToHud` |
| Reads | `$AA13` (`SpringArmed`); `$AA44` (`BallCell`); `$AAFD` (`Water`); `$AB1C` (`CellPlatform`); `$ABA4`-`$ABA6` (`DemoInputPtr`, `DemoFlag`); `$D25E`-`$D27C` (`DemoMoves+4`); 1 more ranges |
| Writes | `$AAFD` (`Water`); `$AB26`-`$AB2B` (`FireOutStep`, `FireOutSteps`, `FireOutAddr`, `FireOutActive`); `$ABA7` (`ObjectFlag`) |

### `RightStep10` (`$CC7B`)

**Move right, step 10: the tail only**

Witness: L1 1124 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 130 t-states own (0.00 %) |
| Runs (the other recordings) | 25 calls (`stage1/rzx/l79` 4, `stage2/rec/l59` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `StepDispatch`, `RightStep9` (falls into) |
| Calls | `BallRightMove` (tail) |

### `RightStep11` (`$CC7E`)

**Move right, step 11: the second spring frame**

Witness: L1 1099 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 411 t-states own (0.00 %) |
| Runs (the other recordings) | 1,086 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 24, `stage1/rzx/l00` 23, `stage1/rzx/l15` 21 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `SpringStep2`, `RightStep12` (falls into) |
| Reads | `$AA13` (`SpringArmed`) |

### `RightStep12` (`$CC86`)

**Move right, step 12: the tail only**

Witness: L1 2310 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 10 calls, 260 t-states own (0.00 %) |
| Runs (the other recordings) | 919 calls (`stage1/rzx/l43` 22, `stage1/rzx/l00` 21, `stage1/rzx/l15` 21 and 115 more) |
| Called from | `StepDispatch`, `RightStep11` (falls into) |
| Calls | `BallRightMove` (tail) |

### `RightStep13` (`$CC89`)

**Move right, step 13: take the object**

Witness: L1 1211 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 351 t-states own (0.00 %) |
| Runs (the other recordings) | 1,198 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 31, `stage1/rzx/l00` 23, `stage1/rzx/l15` 21 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallRightMove` (tail), `TakeObject` |

### `RightStep14` (`$CC8F`)

**Move right, step 14: the third spring frame**

Witness: L1 1211 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 541 t-states own (0.00 %) |
| Runs (the other recordings) | 1,198 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 31, `stage1/rzx/l00` 23, `stage1/rzx/l15` 21 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallRightMove` (tail), `SpringStep3` |
| Reads | `$AA13` (`SpringArmed`) |

### `RightStep15` (`$CC9A`)

**Move right, step 15: the last spring frame, then death on fire or spikes**

As LeftStep15 with the offsets `$AFAF`. The spike death ran once, in docs/integrate/rec/rightspike (level 75: right from cell 30 onto the spikes of cell 31); the fire death ran in no recording (known only from the code).

Witness: L1 1211 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,451 t-states own (0.00 %) |
| Runs (the other recordings) | 1,198 runs of its first instruction, entered by a jump (`stage1/rzx/l43` 31, `stage1/rzx/l00` 23, `stage1/rzx/l15` 21 and 115 more) |
| Called from | `StepDispatch` |
| Calls | `BallStepMove`, `BallRightMove` (tail), `BallBurstStart` (tail), `SpringStep4`, `SfxSpikeDeath` |
| Reads | `$AA13` (`SpringArmed`); `$AB1C` (`CellPlatform`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `UpStep0` (`$CCD0`)

**Jump, step 0: the jump sound, the bricks, then the handler of the platform left**

Unless `$ABA7` is 4 (cleared), the jump sound `$F3DF` plays when the platform `$AB1C` is neither 0 nor bricks (`$0A`). On bricks `$B8D1` counts a hit, which may turn the ball down: when BallState is no longer 3, the down handler `$B064` takes over. Then UpTakeoffTable[`$AB1C`] `$C6DC`.

Witness: L1 2605 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 7,264 t-states own (0.00 %) |
| Runs (the other recordings) | 2,581 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 171, `stage1/rzx/l38` 109, `stage1/rzx/l75` 66 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `BallUpMove`, `BallDown` (tail), `HitBrick`, `UpSpringRelease`, `UpCrumble2`, `UpCrumble3`, `UpCrumble4`, `SfxHit` |
| Reads | `$AA00` (`BallState`); `$AB1C` (`CellPlatform`); `$ABA7` (`ObjectFlag`); `$C6DC`-`$C6F1` (`UpTakeoffTable`) |
| Writes | `$ABA7` (`ObjectFlag`) |

### `UpSpringRelease` (`$CD18`)

**Jump from a platform of type 1-5: the spring's release frame**

If SpringArmed, `$BDC6`. Then the up tail `$AFD6`.

Witness: L1 1329 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,128 t-states own (0.00 %) |
| Runs (the other recordings) | 402 calls (`stage2/rec/l68` 16, `stage1/rzx/l63` 15, `stage1/rzx/l21` 12 and 82 more) |
| Called from | `UpStep0`, `UpCrumble2` (tail), `UpCrumble3` (tail), `UpCrumble4` (tail) |
| Calls | `BallUpMove` (tail), `SpringStep5` |
| Reads | `$AA13` (`SpringArmed`) |

### `UpCrumble2` (`$CD23`)

**Jump from a type-2 platform: it starts crumbling**

Witness: L1 83 (menu, l10, l68, l98, rzx x40).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 83 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 6, `stage2/rec/l68` 5, `stage1/rzx/l21` 4 and 41 more) |
| Called from | `UpStep0` |
| Calls | `StartWearTo3`, `UpSpringRelease` (tail) |
| Reads | `$AA13` (`SpringArmed`) |

### `UpCrumble3` (`$CD29`)

**Jump from a type-3 platform**

Witness: L1 125 (scoreloop, l x10, rzx x49).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 125 runs of its first instruction, entered by a jump (`stage1/rzx/l63` 7, `docs/integrate/rec/scoreloop` 6, `stage1/rzx/l87` 6 and 57 more) |
| Called from | `UpStep0` |
| Calls | `StartWearTo4`, `UpSpringRelease` (tail) |

### `UpCrumble4` (`$CD2F`)

**Jump from a type-4 platform**

Witness: L1 233 (scoreloop, l x10, rzx x71).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 233 runs of its first instruction, entered by a jump (`stage1/rzx/l73` 7, `stage1/rzx/l80` 7, `stage1/rzx/l89` 7 and 79 more) |
| Called from | `UpStep0` |
| Calls | `StartFallAway`, `UpSpringRelease` (tail) |
| Reads | `$AA13` (`SpringArmed`) |

### `UpStep1` (`$CD35`)

**Jump, step 1: the bricks check**

Every step of the jump calls `$B8D1` when the platform is bricks and leaves for `$B064` when that turned the ball down.

Witness: L1 2553 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,680 t-states own (0.00 %) |
| Runs (the other recordings) | 2,529 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 164, `stage1/rzx/l38` 104, `stage1/rzx/l75` 62 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `BallUpMove` (tail), `BallDown` (tail), `HitBrick` |
| Reads | `$AA00` (`BallState`); `$AB1C` (`CellPlatform`) |

### `UpStep2` (`$CD48`)

**Jump, step 2: the bricks check**

Witness: L1 2500 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,776 t-states own (0.00 %) |
| Runs (the other recordings) | 2,476 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 157, `stage1/rzx/l38` 99, `stage1/rzx/l75` 58 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `BallUpMove` (tail), `BallDown` (tail), `HitBrick` |
| Reads | `$AA00` (`BallState`); `$AB1C` (`CellPlatform`) |

### `UpStep3` (`$CD5C`)

**Jump, step 3: the spring frame, the bricks, start a pending crumble**

If SpringArmed, `$BDCE`; a pending crumble starts (`$AA15` = `$AA14`) and `$C19D` plays two of its steps.

Witness: L1 2449 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,144 t-states own (0.00 %) |
| Runs (the other recordings) | 2,425 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 150, `stage1/rzx/l38` 94, `stage1/rzx/l15` 55 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `BallUpMove` (tail), `BallDown` (tail), `HitBrick`, `SpringStep6`, `PlatformChangeStep` |
| Reads | `$AA00` (`BallState`); `$AA13`-`$AA14` (`SpringArmed`, `CrumblePending`); `$AB1C` (`CellPlatform`) |
| Writes | `$AA15` (`CrumbleActive`) |

### `UpStep4` (`$CD8A`)

**Jump, step 4: hit the platform above, or pass it**

On the top row (`$AA44` < 6) the ball turns down (`$B00F`). Above an empty cell or a cell with bricks or the exit (10, 11) it goes on. Spikes (12) above kill: sound `$F4B4`, the burst state 6 at step 3 (UpSpikeDeath, 8 deaths in the recordings). Any other platform (1-9) above stops the jump: `$B00F` turns the ball down. The open exit above lets the ball in: UpStep5 enters the cell and the landing gives state 8, the level end, as from the side (docs/integrate/rec/exitbelow, level 0's record POKEd so the exit opens above the start; the only exit taken from below).

Witness: L1 2398 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,474 t-states own (0.00 %) |
| Runs (the other recordings) | 2,374 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 143, `stage1/rzx/l38` 89, `stage1/rzx/l15` 55 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `MainLoop` (tail), `DrawBallRound`, `BallUpMove` (tail), `BallBumpCeiling` (tail), `BallDown` (tail), `HitBrick`, `PlatformChangeStep`, `SfxSpikeDeath` |
| Reads | `$AA00` (`BallState`); `$AA15` (`CrumbleActive`); `$AA44` (`BallCell`); `$AA6B`-`$AA88` (`CellPlatforms`); `$AB1C` (`CellPlatform`) |
| Writes | `$A9FF`-`$AA00` (`BallStep`, `BallState`) |

### `UpStep5` (`$CDD9`)

**Jump, step 5: the ball enters the cell above**

`$AA44` - 6, and `$BB32` reads the new cell's platform and object.

Witness: L1 2236 (c1, exitbelow, menu, scoreloop, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 256 t-states own (0.00 %) |
| Runs (the other recordings) | 2,234 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 136, `stage1/rzx/l38` 84, `stage1/rzx/l15` 55 and 111 more) |
| Called from | `StepDispatch` |
| Calls | `BallUpMove` (tail), `BallDown` (tail), `HitBrick`, `ReadCell` |
| Reads | `$AA00` (`BallState`); `$AA44` (`BallCell`); `$AB1C` (`CellPlatform`) |
| Writes | `$AA44` (`BallCell`) |

### `UpStep6` (`$CDF9`)

**Jump, step 6: take the object**

Witness: L1 2184 (c1, exitbelow, menu, scoreloop, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 182 t-states own (0.00 %) |
| Runs (the other recordings) | 2,182 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 129, `stage1/rzx/l38` 79, `stage1/rzx/l15` 55 and 111 more) |
| Called from | `StepDispatch` |
| Calls | `BallUpMove` (tail), `BallDown` (tail), `HitBrick`, `TakeObject` |
| Reads | `$AA00` (`BallState`); `$AB1C` (`CellPlatform`) |

### `UpStep7` (`$CE10`)

**Jump, step 7: the bricks check; the tail then calls ChooseNextState**

Witness: L1 2133 (c1, exitbelow, menu, scoreloop, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 148 t-states own (0.00 %) |
| Runs (the other recordings) | 2,131 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 122, `stage1/rzx/l38` 74, `stage1/rzx/l15` 55 and 111 more) |
| Called from | `StepDispatch` |
| Calls | `BallUpMove` (tail), `BallDown` (tail), `HitBrick` |
| Reads | `$AA00` (`BallState`); `$AB1C` (`CellPlatform`) |

### `DownStep0` (`$CE24`)

**Fall, step 0: put out a burning platform below with a water drop**

If the cell below (`$AA44` + 6) has a platform of type 8 or 9 and Water `$AAFD` is not 0: Water - 1, `$ABA7` = 4, FireOutDown starts at that cell. Then the down tail `$B06B`.

Witness: L1 2264 (c1, menu, scoreloop, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 218 t-states own (0.00 %) |
| Runs (the other recordings) | 2,262 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 115, `stage1/rzx/l38` 69, `stage1/rzx/l15` 55 and 111 more) |
| Called from | `StepDispatch` |
| Calls | `BallDownMove` (tail), `DownStepIdle` (falls into), `WaterToHud` |
| Reads | `$AA44` (`BallCell`); `$AA71`-`$AA8E` (`CellPlatforms+6`); `$AAFD` (`Water`); `$E14B`-`$E178` (`CellAddresses+26`) |
| Writes | `$AAFD` (`Water`); `$AB26`-`$AB2B` (`FireOutStep`, `FireOutSteps`, `FireOutAddr`, `FireOutActive`); `$ABA7` (`ObjectFlag`) |

### `DownStepIdle` (`$CE7C`)

**Fall, steps 1 and 2: the tail only**

Witness: L1 4693 (c1, menu, scoreloop, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 40 t-states own (0.00 %) |
| Runs (the other recordings) | 18 calls (`stage1/rzx/l44` 2, `stage1/rzx/l91` 2, `stage1/rzx/l28` 2 and 12 more) |
| Called from | `StepDispatch`, `DownStep0` (falls into) |
| Calls | `BallDownMove` (tail) |

### `DownStep3` (`$CE7F`)

**Fall, step 3: the ball enters the cell below**

`$AA44` + 6.

Witness: L1 2415 (c1, menu, scoreloop, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 86 t-states own (0.00 %) |
| Runs (the other recordings) | 2,413 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 136, `stage1/rzx/l38` 84, `stage1/rzx/l15` 55 and 111 more) |
| Called from | `StepDispatch` |
| Calls | `BallDownMove` (tail) |
| Reads | `$AA44` (`BallCell`) |
| Writes | `$AA44` (`BallCell`) |

### `DownStep4` (`$CE8A`)

**Fall, step 4: the crumble, the cell, the spring**

Plays a step of a pending crumble (`$C19D`), sets `$AB2D` and `$AB1C` for the new cell (`$BB05`, `$BB32`), arms the spring as at BounceStep9 and draws two press frames (`$BDA6`, `$BDAE`).

Witness: L1 2569 (c1, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 5,097 t-states own (0.00 %) |
| Runs (the other recordings) | 2,545 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 143, `stage1/rzx/l38` 89, `stage1/rzx/l15` 55 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `BallDownMove` (tail), `TestUpOrFire`, `CellScreenAddr`, `ReadCell`, `LoadSpring`, `SpringStep1`, `SpringStep2`, `PlatformChangeStep` |
| Reads | `$AA13`-`$AA15` (`SpringArmed`, `CrumblePending`, `CrumbleActive`); `$ABA4`-`$ABA6` (`DemoInputPtr`, `DemoFlag`); `$D25E`-`$D288` (`DemoMoves+4`) |

### `DownStep5` (`$CEC6`)

**Fall, step 5: take the object**

Witness: L1 2617 (c1, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 408 t-states own (0.00 %) |
| Runs (the other recordings) | 2,593 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 150, `stage1/rzx/l38` 94, `stage1/rzx/l15` 55 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `TakeObject` |

### `DownStepIdle2` (`$CEC9`)

**Fall, step 6: the tail only**

Witness: L1 5285 (c1, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 48 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 480 t-states own (0.00 %) |
| Runs (the other recordings) | 5,237 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 307, `stage1/rzx/l38` 193, `stage1/rzx/l75` 112 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `BallDownMove` (tail) |

### `DownStep7` (`$CECC`)

**Fall, step 7: the last spring frames, then death on fire or spikes**

`$BDB6` and `$BDBE` if SpringArmed. A platform of type 8 or 9 (no water left at step 0) kills with `$F483` (never run from here: the fire recording falls in from the side); type 12 kills with `$F4B4` (4 deaths): the ball drawn at `$B10A`, then the burst (`$B0ED`).

Witness: L1 2719 (c1, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,794 t-states own (0.00 %) |
| Runs (the other recordings) | 2,695 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 164, `stage1/rzx/l38` 104, `stage1/rzx/l75` 62 and 113 more) |
| Called from | `StepDispatch` |
| Calls | `BallStepMove`, `BallDownMove` (tail), `BallBurstStart` (tail), `SpringStep3`, `SpringStep4`, `SfxSpikeDeath` |
| Reads | `$AA13` (`SpringArmed`); `$AB1C` (`CellPlatform`) |
| Writes | `$A9FE` (`SpriteWidth`) |

## menu

`src/game/menu.asm`

### `ReadControlMask` (`$B3B2`)

**Builds a byte of the eight key slots held (bit 7 the last) into `$B3CE`: never called**

For the slots KeySlots `$F084-$F08B` in turn: E shifts right and bit 7 is set when TestKeyBit says the slot's key is held; the word DE goes to `$B3CE`. Nothing calls it and nothing reads `$B3CE` (known only from the code): a left-over of a control reader the game replaced by one TestKey call a slot.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadControlMaskKeepDE` (`$B3B5`)

**ReadControlMaskKeepDE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TestKeyBit` (`$B3D0`)

**Z when the key of code A is held: patches BIT b,(IX+d) at `$B3F3` with d = A >> 3 and b = A AND 7**

Input A a key code: row (A >> 3) 0-8 of KeyRows `$B436` and bit (A AND 7). Rows 0-7 are the half-rows `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` (so `$00` SPACE, `$2B` R, `$31` S, `$32` D, `$3C` V); row 8 is the Kempston stick (`$40` right, `$41` left, `$42` down, `$43` up, `$44` fire). Writes the displacement to `$B3F5` and the bit into the opcode byte `$B3F6` (self-modifying), then tests. Output Z when held (bit 0), NZ when not. Keeps IX.

Witness: L1 428989 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 18,941 calls, 3,797,514 t-states own (0.30 %) |
| Runs (the other recordings) | 410,048 calls (`stage1/menu` 43,298, `stage1/rzx/l46` 11,566, `stage1/gameover` 10,092 and 116 more) |
| Called from | `TestKey` |
| Calls | `TestKeyBitTest` (falls into) |
| Reads | `$B3F6` (`TestKeyBitTest+6`); `$B436`-`$B43E` (`KeyRows`) |
| Writes | `$B3F5`-`$B3F6` (`TestKeyBitTest+5`) |

### `TestKeyBitTest` (`$B3F0`)

**TestKeyBit's second half: stores the patched opcode (A) at `$B3F6` and runs BIT b,(IX+d)**

The walk makes it an entry of its own (the recordings count one run more here than at TestKeyBit: a recording that starts inside the routine). Nothing calls or jumps here (known only from the code); it is the tail of TestKeyBit.

Witness: L1 428990 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 18,941 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3,595 calls (`stage1/rzx/l25` 3,595) |
| Called from | `TestKeyBit` (falls into) |
| Reads | `$B437`-`$B43C` (`KeyRows+1`) |
| Writes | `$B3F6` (`TestKeyBitTest+6`) |

### `WaitPress` (`$B3FA`)

**Waits until a key or the stick is held, then until all are released**

Witness: L1 14595 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/menu` 3) |
| Called from | `Pause` |
| Calls | `WaitRelease` (falls into), `AnyControl` |

### `WaitRelease` (`$B401`)

**Waits until no key and no stick direction is held**

Witness: L1 152211 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 34 t-states own (0.00 %) |
| Runs (the other recordings) | 74 calls (`stage2/rec/twoname` 14, `stage1/menu` 10, `stage1/gameover` 7 and 32 more) |
| Called from | `LifeStart`, `WaitPress` (falls into), `Pause`, `EnterName` |
| Calls | `AnyControl` |

### `AnyControl` (`$B407`)

**ReadControls, then Z when nothing is held (the AND of the nine KeyRows bytes is `$FF`)**

Witness: L1 518862 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x26).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 7,619 calls, 2,226,877 t-states own (0.18 %) |
| Runs (the other recordings) | 511,243 calls (`stage1/gameover` 106,639, `stage2/rec/twoname` 95,574, `stage1/menu` 79,678 and 34 more) |
| Called from | `WaitPress`, `WaitRelease`, `WaitPressHeld`, `WaitKeyOrSecond`, `MenuShowHallOfFame` |
| Calls | `ReadControls` |
| Reads | `$B436`-`$B43E` (`KeyRows`) |

### `ReadControls` (`$B418`)

**Reads the 8 keyboard half-rows into KeyRows `$B436-$B43D` and the Kempston port `$DF` into `$B43E`**

DI, then IN (`$FE`) for each half-row, `$7FFE` first, each stored with bits 5-7 set (OR `$E0`). Then IN A,(`$DF`) (A, the high byte, holds the last row's value): the low five bits are the Kempston stick, 1 = pressed. When all five are 1 (no interface: the port floats at `$FF`) the routine returns with interrupts still off and `$B43E` unchanged; else it stores the complement (0 = pressed, like the keys) and EI. A Kempston mouse answering on port `$DF` would be read as a stick here (known only from the code).

Witness: L1 947851 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 26,560 calls, 13,581,261 t-states own (1.07 %) |
| Runs (the other recordings) | 921,291 calls (`stage1/menu` 122,976, `stage1/gameover` 116,731, `stage2/rec/twoname` 105,095 and 116 more) |
| Called from | `AnyControl`, `TestKey` |
| Writes | `$B436`-`$B43E` (`KeyRows`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFDF`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEDF`, `$FEFE`, `$FFDF` |

### `Pause` (`$B440`)

**The pause key: wait for its release, then for a key and its release**

Called by MainLoop when the pause key (slot `$F08A`) is held in a game. Witness: 3 pauses in the recordings.

Witness: L1 3 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/menu` 3) |
| Called from | `MainLoop` |
| Calls | `WaitPress`, `WaitRelease` |

### `TestLeft` (`$B447`)

**NZ when the left control (slot `$F086`) is held**

Witness: L1 5520 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 227 calls, 9,399 t-states own (0.00 %) |
| Runs (the other recordings) | 5,293 calls (`stage1/gameover` 429, `stage2/rec/twoname` 342, `stage1/menu` 303 and 115 more) |
| Called from | `BallStopped`, `ChooseNextState`, `EnterName` |
| Calls | `TestKey` |
| Reads | `$F086` (`KeySlots+2`) |

### `TestRight` (`$B44E`)

**NZ when the right control (slot `$F087`) is held**

Witness: L1 4730 (c1, exitbelow, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 218 calls, 8,901 t-states own (0.00 %) |
| Runs (the other recordings) | 4,512 calls (`stage1/gameover` 427, `stage2/rec/twoname` 349, `stage1/menu` 299 and 114 more) |
| Called from | `BallStopped`, `ChooseNextState`, `EnterName` |
| Calls | `TestKey` |
| Reads | `$F087` (`KeySlots+3`) |

### `TestFire` (`$B455`)

**NZ when the up control (slot 0, `$F084`) is held, despite its name: never called**

TestUpOrFire `$B463` tests slot 0 itself; nothing calls this one (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TestDown` (`$B45C`)

**NZ when the down control (slot `$F085`) is held**

Witness: L1 1017 (scoreloop, l x12, rzx x94).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,017 calls (`stage1/rzx/l46` 66, `stage1/rzx/l15` 36, `stage1/rzx/l14` 35 and 104 more) |
| Called from | `ChooseNextState` |
| Calls | `TestKey` |
| Reads | `$F085` (`KeySlots+1`) |

### `TestUpOrFire` (`$B463`)

**NZ when fire (slot 4, `$F088`) or up (slot 0, `$F084`) is held: the spring**

Witness: L1 6426 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 249 calls, 18,573 t-states own (0.00 %) |
| Runs (the other recordings) | 6,177 calls (`stage1/gameover` 430, `stage2/rec/twoname` 361, `stage1/menu` 313 and 116 more) |
| Called from | `BounceStep9`, `LeftStep9`, `RightStep9`, `DownStep4`, `EnterName` |
| Calls | `TestKey` |
| Reads | `$F084`-`$F088` (`KeySlots`) |

### `CheatStock` (`$BB56`)

**The cheat R+SPACE+V: 99 water, keys, hammers and lives for both players, level 0**

Both player records (`$AB09`, `$AB10`): water, keys, hammers and lives 99 (`$63`), level 0. Called at the start of a game (`$ABD0`) when the keys `$2B`, `$00` and `$3C` are all down. Witness: 1 run, in the menu recording (stage1/menu).

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `NewGameOnePlayer` |
| Writes | `$AB0B`-`$AB16` (`Player1Record+2`, `Player2Record`) |

### `PracticeStock` (`$BB7D`)

**Water, keys and hammers 3 for both players: never run**

Called at `$ABDD` each loop when `$ADDD` is not 0, which never happens (`$ADDF` is a RET before the store). Known only from the code: a disabled practice or cheat mode.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawLogo` (`$E7F7`)

**Draw the BUMPY logo at the top of the menu screen**

DrawSprite `$E318`: Logo `$E808`, CPC address `$C066` (character row 1, CPC byte 22: Spectrum line 1, column 11), width 18 CPC bytes (72 pixels), 60 lines. No attributes: the colours are the backdrop's (MenuBackdropText `$F0E8`).

Witness: L1 8 (c1, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 74 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/menu` 5, `stage1/gameover` 1, `stage2/rec/twoname` 1) |
| Called from | `Menu` |
| Calls | `DrawSprite` |
| Writes | `$A9FE` (`SpriteWidth`) |

### `Menu` (`$EF33`)

**The menu: draw it and wait for 0 (play), 1 (players), 2-4 (controls), or the time-out**

Border 0, ClearScreen, the backdrop (MenuBackdropText `$F0E8`), DrawLogo, then MenuPrint. Returns to GameStart with `$B3B1` = 0 (one player), 2 (two players) or 4 (the demo).

Witness: L1 8 (c1, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 34,673,972 t-states own (2.73 %) |
| Runs (the other recordings) | 7 calls (`stage1/menu` 5, `stage1/gameover` 1, `stage2/rec/twoname` 1) |
| Called from | `GameRestart`, `MenuShowHallOfFame` (tail) |
| Calls | `PrintText`, `DrawLogo`, `MenuPrint` (tail), `ClearScreen` |
| Reads | `$EF55` (`MenuWait+1`); `$EFED`-`$EFEE` (`MenuTimer`); `$F062`-`$F07D` (`Players`, `PlayersTexts`) |
| Writes | `$EFED`-`$EFEE` (`MenuTimer`); `$F005`-`$F035` (`MenuText+22`); `$F062` (`Players`); `$F083` (`ControlChoice`) |
| Ports out | `$00FE` |

### `MenuRedraw` (`$EF44`)

**After an option: the pick-up sound, then MenuPrint**

Witness: L1 12 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 8 calls (`stage1/menu` 4, `stage1/gameover` 2, `stage2/rec/twoname` 2) |
| Called from | `MenuTogglePlayers` (tail), `MenuSelectControls` (tail) |
| Calls | `SfxPickup` |

### `MenuPrint` (`$EF47`)

**Start the time-out (3000 frames) and print the options**

Witness: L1 20 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7 calls (`stage1/menu` 5, `stage2/rec/twoname` 1, `stage1/gameover` 1) |
| Called from | `Menu` (tail) |
| Calls | `PrintText` |
| Writes | `$EFED`-`$EFEE` (`MenuTimer`) |

### `MenuLoop` (`$EF53`)

**One frame of the menu: test the keys, count the time-out**

Each frame (HALT): key "0" (code `$18`) starts the game (LoadControls, SetPlayersMode); "1" (`$20`) MenuTogglePlayers; "2", "3", "4" (`$21-$23`) MenuSelectControls with 0, 1, 2. The time-out `$EFED` counts down; at 0 MenuDemoToggle flips: 1 returns with `$B3B1` = 4 (the demo), 0 shows the hall of fame (MenuShowHallOfFame).

Witness: L1 7058 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 534 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,470 calls (`stage1/menu` 4,148, `stage1/gameover` 1,235, `stage2/rec/twoname` 1,087) |
| Called from | `MenuWait` (tail) |
| Calls | `MenuWait` (falls into) |

### `MenuWait` (`$EF54`)

**MenuLoop's HALT**

Witness: L1 7062 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 534 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,485 calls (`stage1/menu` 4,157, `stage1/gameover` 1,238, `stage2/rec/twoname` 1,090) |
| Called from | `MenuLoop` (falls into) |
| Calls | `TestKey`, `MenuLoop` (tail), `LoadControls`, `SetPlayersMode`, `MenuShowHallOfFame` (tail) |
| Reads | `$EF55` (`MenuWait+1`); `$EFA2` (`MenuDemoToggle`); `$EFED`-`$EFEE` (`MenuTimer`); `$F062` (`Players`); `$F073`-`$F07D` (`PlayersTexts+16`) |
| Writes | `$B3B1` (`MenuChoice`); `$EFA2` (`MenuDemoToggle`); `$EFED`-`$EFEE` (`MenuTimer`); `$F005`-`$F035` (`MenuText+22`); `$F062` (`Players`); `$F083` (`ControlChoice`) |

### `MenuTogglePlayers` (`$EFA3`)

**Key 1: one player or two**

Players `$F062` = 1 - Players; the 11 bytes of PlayersTexts (+16 for two) are copied over the option's text at `$F005`; then MenuRedraw.

Witness: L1 4 (c1, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 runs of its first instruction, entered by a jump (`stage1/menu` 1, `stage2/rec/twoname` 1) |
| Calls | `MenuRedraw` (tail) |

### `MenuSelectControls` (`$EFC6`)

**Keys 2-4: choose the controls A (0 keyboard, 1 Sinclair, 2 Kempston)**

ControlChoice `$F083` = A; the three options' ink bytes (`$F015`, `$F025`, `$F035`) are set to 4 (green) and the chosen one to 7 (white); then MenuRedraw.

Witness: L1 8 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7 runs of its first instruction, entered by a jump (`stage1/menu` 3, `stage1/gameover` 2, `docs/integrate/rec/exitbelow` 1 and 1 more) |
| Calls | `MenuRedraw` (tail) |

### `LoadControls` (`$F0AA`)

**Copy the chosen control set into KeySlots**

Witness: L1 9 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 266 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/menu` 4, `stage1/gameover` 2, `docs/integrate/rec/exitbelow` 1 and 1 more) |
| Called from | `MenuWait` |
| Reads | `$F083`-`$F0A9` (`ControlChoice`, `KeySlots`, `ControlSets`, `KeyboardKeys`) |
| Writes | `$F084`-`$F08B` (`KeySlots`) |

### `SetPlayersMode` (`$F0C2`)

**`$B3B1` = 2 x Players (0 one player, 2 two players)**

Witness: L1 9 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 44 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/menu` 4, `stage1/gameover` 2, `docs/integrate/rec/exitbelow` 1 and 1 more) |
| Called from | `MenuWait` |
| Reads | `$F062` (`Players`) |
| Writes | `$B3B1` (`MenuChoice`) |

### `ClearScreen` (`$F0CB`)

**Clear the pixels and fill the attributes with TextVars' default (`$E712`)**

Witness: L1 12 (c1, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 188,266 t-states own (0.01 %) |
| Runs (the other recordings) | 11 calls (`stage1/menu` 6, `stage2/rec/twoname` 3, `stage1/gameover` 2) |
| Called from | `ShowHallOfFame`, `Menu` |
| Reads | `$4000`-`$5AFE` (screen); `$E712` (`TextVars`) |
| Writes | `$4000`-`$5AFF` (screen) |

### `MenuShowHallOfFame` (`$F165`)

**Show the hall of fame for 750 frames (15 s) or until a key, then the menu again**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `MenuWait` (tail) |
| Calls | `AnyControl`, `ShowHallOfFame`, `Menu` (tail) |
| Reads | `$EFED`-`$EFEE` (`MenuTimer`); `$F170` (`MenuShowHallOfFameLoop+2`) |
| Writes | `$EFED`-`$EFEE` (`MenuTimer`) |

## render

`src/game/render.asm`

### `ClearAttrs` (`$B471`)

**All attributes = A (7: white ink, black paper), the border = A >> 3 (black)**

Witness: L1 10 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 18,524 t-states own (0.00 %) |
| Runs (the other recordings) | 9 calls (`stage1/menu` 5, `stage1/gameover` 2, `docs/integrate/rec/exitbelow` 1 and 1 more) |
| Called from | `NewGameOnePlayer` |
| Reads | `$5800`-`$5AFE` (screen) |
| Writes | `$5800`-`$5AFF` (screen) |
| Ports out | `$00FE` |

### `DrawSides` (`$B488`)

**Draws the side panels: `$6398` at the CPC address `$F800` and `$6518` at `$F83C`, 192 lines each (`$E318`)**

Witness: L1 10 (c1, exitbelow, gameover, menu, twoname).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 132 t-states own (0.00 %) |
| Runs (the other recordings) | 9 calls (`stage1/menu` 5, `stage1/gameover` 2, `docs/integrate/rec/exitbelow` 1 and 1 more) |
| Called from | `NewGameOnePlayer` |
| Calls | `DrawSprite` |
| Writes | `$A9FE` (`SpriteWidth`) |

### `FillColumn` (`$B4A8`)

**Stores C into B lines of one byte column from the CPC address DE: never called**

Converts DE (`$C71F`, `$B515`) and stores C at each line's Spectrum address. No code calls it (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearPlayArea` (`$B4CE`)

**Clears columns 1-29 of the 200 lines (the blank `$6708`), then the play attributes (ink 7)**

Witness: L1 164 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3 calls, 533,112 t-states own (0.04 %) |
| Runs (the other recordings) | 161 calls (`stage2/rec/twoname` 18, `stage1/gameover` 18, `stage1/menu` 13 and 32 more) |
| Called from | `LifeStart` |
| Calls | `SetPlayAttrs` |
| Reads | `$6708`-`$6724` (`BlankPicture`); `$B52D`-`$B6BC` (`SpectrumLines`) |
| Writes | `$4001`-`$57FD` (screen); `$FCE1`-`$FCFD` (`work space $FCE1+`) |

### `SetPlayAttrs` (`$B4F8`)

**Each attribute row: column 0 and 30 yellow (6), columns 1-29 = A; column 31 untouched**

Witness: L1 162 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3 calls, 70,523 t-states own (0.01 %) |
| Runs (the other recordings) | 159 calls (`stage1/gameover` 18, `stage2/rec/twoname` 18, `stage1/menu` 13 and 32 more) |
| Called from | `ClearPlayArea` |
| Reads | `$5801`-`$5AFC` (screen) |
| Writes | `$5800`-`$5AFE` (screen) |

### `LineAddress` (`$B515`)

**IX = SpectrumLines + 2 x the line (`$C751`), `$B52C` = the CPC column (`$C750`) / 2**

Input the line `$C751` and column `$C750` from ScreenAddrToLine `$C71F`. Output IX points at the Spectrum line address; the caller ORs `$B52C` into its low byte.

Witness: L1 327885 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9,177 calls, 1,034,317 t-states own (0.08 %) |
| Runs (the other recordings) | 318,708 calls (`stage1/menu` 14,729, `stage1/rzx/l46` 8,906, `stage1/rzx/l38` 8,399 and 116 more) |
| Called from | `LevelEnd`, `BrickCrumble1`, `BrickCrumble2`, `BrickCrumble3`, `BrickCrumble4`, `LeftStep5`, `RightStep5`, `DrawSprite`, `XorSprite`, `XorBricks` |
| Reads | `$C750`-`$C751` (`ByteColumn`, `PixelLine`) |
| Writes | `$B52C` (`SpectrumColumn`) |

### `SetPlatformCell` (`$B8C2`)

**Write the new platform type of a platform-change animation into its cell**

PlatformCells `$AA6B`[`$AB1B`] = `$AB20` (the cell and the new type StartWearTo3 `$C3D5`, StartWearTo4 `$C3F8` or StartFallAway `$C41B` left there). Called by the first or last step of each change (`$C1C3`, `$C1FF`, `$C211`).

Witness: L1 1427 (menu, scoreloop, l x12, rzx x91).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,427 calls (`stage1/rzx/l18` 87, `stage2/rec/l68` 37, `stage1/rzx/l13` 36 and 102 more) |
| Called from | `WearTo3Step1`, `WearTo4Step4`, `FallAwayStep1` |
| Reads | `$AB1B`-`$AB20` (`CrumbleCell`, `CellPlatform`, `CellObject`, `CellWall` and 2 more) |
| Writes | `$AA6B`-`$AA8E` (`CellPlatforms`) |

### `AnimateFires` (`$BBCD`)

**Every 4 frames, the next flame frame on every burning platform**

`$AA0C` counts frames; at 4, NextFireFrame `$BC8B` steps the frame `$AA16` (1-3), and each of the 36 cells whose FireFlags `$AAB3` byte is set gets the flame frame `$814D` + 30 × (frame - 1) (6 bytes × 5 rows, colour `$C2`) stored at CellAddrs `$E131`[cell] + `$17B1` (DrawSpriteInk `$E2A0`). Called by MainLoop (`$ACDB`) and the level end (`$B32E`).

Witness: L1 94334 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 4,812,733 t-states own (0.38 %) |
| Runs (the other recordings) | 90,493 calls (`stage1/menu` 5,730, `stage1/rzx/l46` 2,785, `stage1/rzx/l18` 2,108 and 116 more) |
| Called from | `MainLoop`, `LevelEnd` |
| Calls | `NextFireFrame`, `DrawSpriteColoured` |
| Reads | `$AA0B`-`$AA16` (`CellByte`, `FireTick`, `WallTick`, `ExitTick` and 7 more); `$AAB3`-`$AAD6` (`CellBurning`); `$E135`-`$E178` (`CellAddresses+4`) |
| Writes | `$A9FE`-`$AA0C` (`SpriteWidth`, `BallStep`, `BallState`, `BallSprite` and 6 more) |

### `AnimateWalls` (`$BC30`)

**Every 4 frames, the next frame of every turning wall (type 4)**

`$AA0D` counts frames; at 4, NextWallFrame `$BCA2` steps `$AA17` (1-4), and each cell whose WallCells `$AA8F` byte is 4 gets the frame `$7E5C` + 48 × (frame - 1) (2 bytes × 24 rows) XORed at WallAddrs `$E179`[cell] (DrawSpriteXorInk, colour `$83`). Called by MainLoop (`$ACDE`) and the level end (`$B331`).

Witness: L1 94334 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 4,660,234 t-states own (0.37 %) |
| Runs (the other recordings) | 90,493 calls (`stage1/menu` 5,730, `stage1/rzx/l46` 2,785, `stage1/rzx/l18` 2,108 and 116 more) |
| Called from | `MainLoop`, `LevelEnd` |
| Calls | `NextWallFrame`, `DrawSpriteColoured` |
| Reads | `$AA0B`-`$AA17` (`CellByte`, `FireTick`, `WallTick`, `ExitTick` and 8 more); `$AA8F`-`$AAB2` (`CellWalls`); `$E179`-`$E1BE` (`WallAddresses`) |
| Writes | `$A9FE`-`$AA0D` (`SpriteWidth`, `BallStep`, `BallState`, `BallSprite` and 7 more) |

### `NextFireFrame` (`$BC8B`)

**`$AA0C` = 0; the flame frame `$AA16` steps 1, 2, 3, 1 ...**

Witness: L1 23584 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 960 calls, 74,114 t-states own (0.01 %) |
| Runs (the other recordings) | 22,624 calls (`stage1/menu` 1,432, `stage1/rzx/l46` 696, `stage1/rzx/l18` 527 and 116 more) |
| Called from | `AnimateFires` |
| Reads | `$AA16` (`FireFrame`) |
| Writes | `$AA0C`-`$AA16` (`FireTick`, `WallTick`, `ExitTick`, `ExitFrame` and 6 more) |

### `NextWallFrame` (`$BCA2`)

**`$AA0D` = 0; the wall frame `$AA17` steps 1, 2, 3, 4, 1 ...**

Witness: L1 23584 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 960 calls, 76,077 t-states own (0.01 %) |
| Runs (the other recordings) | 22,624 calls (`stage1/menu` 1,432, `stage1/rzx/l46` 696, `stage1/rzx/l18` 527 and 116 more) |
| Called from | `AnimateWalls` |
| Reads | `$AA17` (`WallFrame`) |
| Writes | `$AA0D`-`$AA17` (`WallTick`, `ExitTick`, `ExitFrame`, `ExitAnimAddr` and 6 more) |

### `LoadSpring` (`$BD73`)

**Arm the spring of the platform under the ball (types 1-5)**

When SpringArmed `$AA13` is 0 and the platform `$AB1C` is 1-5: copies the 24-byte spring record of the type (found through SpringCurves `$C52A`[type - 1]: SpringPics `$C5D6` + 24 x (type - 1)) to `$AB35` (4 offsets, 4 frame addresses, 4 widths, 4 row counts) and sets SpringArmed. Types 0 and 6 up (conveyors, fire, bricks, exit) have no spring. Called at step 9 of a bounce or a side move and at step 4 of a fall (DownStep4 `$CE8A`) when up or fire (TestUpOrFire `$B463`) is down, or the demo byte is 9.

Witness: L1 2308 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 17,160 t-states own (0.00 %) |
| Runs (the other recordings) | 2,284 calls (`stage1/rzx/l46` 142, `stage1/rzx/l38` 92, `stage1/rzx/l15` 71 and 113 more) |
| Called from | `BounceStep9`, `LeftStep9`, `RightStep9`, `DownStep4` |
| Reads | `$AA13` (`SpringArmed`); `$AB1C` (`CellPlatform`); `$C52A`-`$C533` (`SpringCurves`); `$C5D6`-`$C64D` (`SpringPics`, `SpringPics2`, `SpringPics3`, `SpringPics4` and 1 more) |
| Writes | `$AA13` (`SpringArmed`); `$AB35`-`$AB4C` (`SpringRecord`) |

### `SpringStep1` (`$BDA6`)

**Spring frame 0 off, 1 on (the platform squeezes)**

Each SpringStep XORs two of the 4 spring frames (SpringPart0-3): the one shown off, the next on. Steps 1-6 show frames 1, 2, 1, 0, 3, 0: down, further down, back, rest, up, rest. Called by the bounce handlers at fixed steps of the bounce (`$C800`, `$C80B`, `$C81C`, `$C827` and the like).

Witness: L1 1329 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 1,272 t-states own (0.00 %) |
| Runs (the other recordings) | 1,305 calls (`stage1/rzx/l46` 70, `stage1/rzx/l38` 51, `stage1/rzx/l75` 36 and 113 more) |
| Called from | `BounceStep9`, `LeftStep9`, `RightStep9`, `DownStep4` |
| Calls | `SpringPart0`, `SpringPart1` |

### `SpringStep2` (`$BDAE`)

**Spring frame 1 off, 2 on**

Witness: L1 1329 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 1,339 t-states own (0.00 %) |
| Runs (the other recordings) | 1,305 calls (`stage1/rzx/l46` 70, `stage1/rzx/l38` 51, `stage1/rzx/l75` 36 and 113 more) |
| Called from | `BounceStep11`, `LeftStep11`, `RightStep11`, `DownStep4` |
| Calls | `SpringPart1`, `SpringPart2` |

### `SpringStep3` (`$BDB6`)

**Spring frame 2 off, 1 on**

Witness: L1 1329 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 1,170 t-states own (0.00 %) |
| Runs (the other recordings) | 1,305 calls (`stage1/rzx/l46` 70, `stage1/rzx/l38` 51, `stage1/rzx/l75` 36 and 113 more) |
| Called from | `BounceStep14`, `LeftStep14`, `RightStep14`, `DownStep7` |
| Calls | `SpringPart1`, `SpringPart2` |

### `SpringStep4` (`$BDBE`)

**Spring frame 1 off, 0 on**

Witness: L1 1329 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 1,297 t-states own (0.00 %) |
| Runs (the other recordings) | 1,305 calls (`stage1/rzx/l46` 70, `stage1/rzx/l38` 51, `stage1/rzx/l75` 36 and 113 more) |
| Called from | `BounceStep15`, `LeftStep15`, `RightStep15`, `DownStep7` |
| Calls | `SpringPart0`, `SpringPart1` |

### `SpringStep5` (`$BDC6`)

**Spring frame 0 off, 3 on (the platform flexes up as the ball leaves)**

Called by the up-move handler (`$CD1D`).

Witness: L1 1329 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 1,296 t-states own (0.00 %) |
| Runs (the other recordings) | 1,305 calls (`stage1/rzx/l46` 70, `stage1/rzx/l38` 51, `stage1/rzx/l75` 36 and 113 more) |
| Called from | `UpSpringRelease` |
| Calls | `SpringPart0`, `SpringPart3` |

### `SpringStep6` (`$BDCE`)

**Spring frame 3 off, 0 on; the spring is done (SpringArmed = 0)**

Called by the up-move handler (`$CD62`).

Witness: L1 1326 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 1,632 t-states own (0.00 %) |
| Runs (the other recordings) | 1,302 calls (`stage1/rzx/l46` 70, `stage1/rzx/l38` 51, `stage1/rzx/l75` 36 and 113 more) |
| Called from | `UpStep3` |
| Calls | `SpringPart0`, `SpringPart3` |
| Writes | `$AA13` (`SpringArmed`) |

### `SpringPart0` (`$BDDB`)

**XOR spring frame 0 at the cell's address + its offset**

HL = `$AB2D` + the offset `$AB35`, DE = the frame `$AB3D`, width `$AB45`, rows `$AB49`, DrawSpriteXor `$E3EE`.

Witness: L1 5313 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 96 calls, 13,469 t-states own (0.00 %) |
| Runs (the other recordings) | 5,217 calls (`stage1/rzx/l46` 280, `stage1/rzx/l38` 204, `stage1/rzx/l75` 144 and 113 more) |
| Called from | `SpringStep1`, `SpringStep4`, `SpringStep5`, `SpringStep6` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB49` (`CellScrAddr`, `WallScrAddr`, `BrickLayerAddr`, `BrickActive` and 2 more) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `SpringPart1` (`$BDF5`)

**XOR spring frame 1 (offset `$AB37`, frame `$AB3F`, width `$AB46`, rows `$AB4A`)**

Witness: L1 5316 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 96 calls, 13,494 t-states own (0.00 %) |
| Runs (the other recordings) | 5,220 calls (`stage1/rzx/l46` 280, `stage1/rzx/l38` 204, `stage1/rzx/l75` 144 and 113 more) |
| Called from | `SpringStep1`, `SpringStep2`, `SpringStep3`, `SpringStep4` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB4A` (`CellScrAddr`, `WallScrAddr`, `BrickLayerAddr`, `BrickActive` and 2 more) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `SpringPart2` (`$BE0F`)

**XOR spring frame 2 (offset `$AB39`, frame `$AB41`, width `$AB47`, rows `$AB4B`)**

Witness: L1 2658 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 48 calls, 6,769 t-states own (0.00 %) |
| Runs (the other recordings) | 2,610 calls (`stage1/rzx/l46` 140, `stage1/rzx/l38` 102, `stage1/rzx/l75` 72 and 113 more) |
| Called from | `SpringStep2`, `SpringStep3` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB4B` (`CellScrAddr`, `WallScrAddr`, `BrickLayerAddr`, `BrickActive` and 2 more) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `SpringPart3` (`$BE29`)

**XOR spring frame 3 (offset `$AB3B`, frame `$AB43`, width `$AB48`, rows `$AB4C`)**

Witness: L1 2655 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 48 calls, 6,863 t-states own (0.00 %) |
| Runs (the other recordings) | 2,607 calls (`stage1/rzx/l46` 140, `stage1/rzx/l38` 102, `stage1/rzx/l75` 72 and 113 more) |
| Called from | `SpringStep5`, `SpringStep6` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB4C` (`CellScrAddr`, `WallScrAddr`, `BrickLayerAddr`, `BrickActive` and 2 more) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `TiltPart0` (`$BE43`)

**XOR the platform's rest frame of the tilt record (offset `$AB4D`, frame `$AB53`, width `$AB59`, rows `$AB5C`)**

The tilt record (18 bytes at `$AB4D`: 3 offsets, 3 frames, 3 widths, 3 row counts) is copied by the move handlers (`$C890`, `$CAD6`) from TiltRecords `$C5CC`[type - 1] when the ball rolls off a platform sideways: TiltPart0 + TiltPart1 tilt it left, TiltPart0 + TiltPart2 right, and the reverse pair sets it back. The AND C after the ADD only sets flags.

Witness: L1 2408 (c1, exitbelow, fire, gameover, menu, rightspike, twoname, l x12, rzx x90).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 42 calls, 6,246 t-states own (0.00 %) |
| Runs (the other recordings) | 2,366 calls (`stage1/rzx/l43` 90, `stage1/rzx/l00` 86, `stage1/rzx/l86` 60 and 105 more) |
| Called from | `LeftTakeoff`, `LeftStep5`, `RightTakeoff`, `RightStep5` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`); `$AB4D`-`$AB5C` (`TakeoffRecord`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `TiltPart1` (`$BE5E`)

**XOR the left-tilt frame (offset `$AB4F`, frame `$AB55`, width `$AB5A`, rows `$AB5D`)**

Witness: L1 1108 (c1, exitbelow, fire, gameover, menu, twoname, l x11, rzx x85).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 16 calls, 2,326 t-states own (0.00 %) |
| Runs (the other recordings) | 1,092 calls (`stage1/rzx/l43` 48, `stage1/rzx/l00` 42, `stage2/rec/l59` 26 and 98 more) |
| Called from | `LeftTakeoff`, `LeftStep5` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`); `$AB4F`-`$AB5D` (`TakeoffRecord+2`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `TiltPart2` (`$BE79`)

**XOR the right-tilt frame (offset `$AB51`, frame `$AB57`, width `$AB5B`, rows `$AB5E`)**

Witness: L1 1300 (c1, exitbelow, gameover, menu, rightspike, twoname, l x12, rzx x89).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 26 calls, 3,768 t-states own (0.00 %) |
| Runs (the other recordings) | 1,274 calls (`stage1/rzx/l00` 44, `stage1/rzx/l43` 42, `stage1/rzx/l79` 38 and 103 more) |
| Called from | `RightTakeoff`, `RightStep5` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`); `$AB51`-`$AB5E` (`TakeoffRecord+4`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `BrickStep` (`$BE94`)

**Run the next step of the brick crumble animation, if one is active**

When `$AB33` is set: jumps to BrickSteps `$C534`[`$AB34`] and advances `$AB34`. Steps BrickCrumble1-4 clear the hit layer at `$AB31` in four checkered passes. Called by MainLoop (`$ACCF`).

Witness: L1 93416 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

[Animation: `BrickStep` at work](img/routines/BrickStep.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 156,627 t-states own (0.01 %) |
| Runs (the other recordings) | 89,575 calls (`stage1/menu` 5,721, `stage1/rzx/l46` 2,776, `stage1/rzx/l18` 2,099 and 116 more) |
| Called from | `MainLoop` |
| Calls | `BrickCrumble1`, `BrickCrumble2`, `BrickCrumble3`, `BrickCrumble4` |
| Reads | `$AB33`-`$AB34` (`BrickActive`, `BrickAnimStep`); `$C534`-`$C53B` (`BrickBreakSteps`) |
| Writes | `$AB34` (`BrickAnimStep`) |

### `BrickCrumble1` (`$BEBB`)

**The brick sound and the first pass of the crumble**

The sound `$F4E2`, then with interrupts off: the layer's address `$AB31` to a pixel line (ScreenAddrToLine `$C71F`, LineAddr `$B515`) and 8 of the 16 bytes of its 4 lines × 4 bytes set to 0 in a checker (BrickNextLine `$BF06` between lines). Each crumble pass clears another pattern; the four leave the layer empty.

Witness: L1 409 (l51, l59, l96, l98, rzx x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 409 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 56, `stage1/rzx/l38` 40, `stage1/rzx/l75` 32 and 28 more) |
| Called from | `BrickStep` |
| Calls | `LineAddress`, `BrickNextLine`, `ScreenAddrToLine`, `SfxBrickCrumble` |
| Reads | `$AB31`-`$AB32` (`BrickLayerAddr`); `$B52C` (`SpectrumColumn`); `$B573`-`$B66C` (`SpectrumLines+70`) |
| Writes | `$4081`-`$40FC` (screen); `$4182`-`$41FD` (screen); `$4281`-`$42FC` (screen); `$4382`-`$43FD` (screen); `$4461`-`$44F7` (screen); `$4562`-`$45F8` (screen); 9 more ranges |

### `BrickNextLine` (`$BF06`)

**IY = the next screen line's address at the same column**

IX += 2 in the line table (`$B52D`), IY = the line's address with the column `$B52C` ORed in.

Witness: L1 4908 (l51, l59, l96, l98, rzx x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,908 calls (`stage1/rzx/l46` 672, `stage1/rzx/l38` 480, `stage1/rzx/l75` 384 and 28 more) |
| Called from | `BrickCrumble1`, `BrickCrumble2`, `BrickCrumble3`, `BrickCrumble4` |
| Reads | `$B52C` (`SpectrumColumn`); `$B575`-`$B672` (`SpectrumLines+72`) |

### `BrickCrumble2` (`$BF19`)

**The second pass of the crumble**

Witness: L1 409 (l51, l59, l96, l98, rzx x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 409 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 56, `stage1/rzx/l38` 40, `stage1/rzx/l75` 32 and 28 more) |
| Called from | `BrickStep` |
| Calls | `LineAddress`, `BrickNextLine`, `ScreenAddrToLine` |
| Reads | `$AB31`-`$AB32` (`BrickLayerAddr`); `$B52C` (`SpectrumColumn`); `$B573`-`$B66C` (`SpectrumLines+70`) |
| Writes | `$4082`-`$40FD` (screen); `$4181`-`$41FD` (screen); `$4282`-`$42FC` (screen); `$4382`-`$43FD` (screen); `$4462`-`$44F8` (screen); `$4561`-`$45F8` (screen); 9 more ranges |

### `BrickCrumble3` (`$BF60`)

**The third pass of the crumble**

Witness: L1 409 (l51, l59, l96, l98, rzx x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 409 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 56, `stage1/rzx/l38` 40, `stage1/rzx/l75` 32 and 28 more) |
| Called from | `BrickStep` |
| Calls | `LineAddress`, `BrickNextLine`, `ScreenAddrToLine` |
| Reads | `$AB31`-`$AB32` (`BrickLayerAddr`); `$B52C` (`SpectrumColumn`); `$B573`-`$B66C` (`SpectrumLines+70`) |
| Writes | `$4081`-`$40FC` (screen); `$4181`-`$41FC` (screen); `$4282`-`$42FD` (screen); `$4381`-`$43FC` (screen); `$4461`-`$44F7` (screen); `$4561`-`$45F7` (screen); 9 more ranges |

### `BrickCrumble4` (`$BFA7`)

**The last pass of the crumble; the animation ends (`$AB33` = 0)**

Witness: L1 409 (l51, l59, l96, l98, rzx x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 409 runs of its first instruction, entered by a jump (`stage1/rzx/l46` 56, `stage1/rzx/l38` 40, `stage1/rzx/l75` 32 and 28 more) |
| Called from | `BrickStep` |
| Calls | `LineAddress`, `BrickNextLine`, `ScreenAddrToLine` |
| Reads | `$AB31`-`$AB32` (`BrickLayerAddr`); `$B52C` (`SpectrumColumn`); `$B573`-`$B66C` (`SpectrumLines+70`) |
| Writes | `$4082`-`$40FD` (screen); `$4182`-`$41FC` (screen); `$4281`-`$42FD` (screen); `$4381`-`$43FC` (screen); `$4462`-`$44F8` (screen); `$4562`-`$45F7` (screen); 10 more ranges |

### `WaterStep` (`$BFF3`)

**Run the next step of the put-out-the-fire animation, if one is active**

When `$AB2B` is set: jumps to the step table at `$AB27` (WaterStepsA `$C55E`, B `$C56E` or C `$C57E`, chosen by the landing handler: `$CA30`, `$CC73`, `$CE74`), entry `$AB26`, and advances `$AB26`. Each sequence lets a drop fall (3 or 4 frames, the sprite WaterDrop `$C0FE` XORed at `$AB29` + an offset), puts out the fire (ExtinguishFire `$C10C`), then shows 4 frames of steam. Called by MainLoop (`$ACD2`).

Witness: L1 93416 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 149,139 t-states own (0.01 %) |
| Runs (the other recordings) | 89,575 calls (`stage1/menu` 5,721, `stage1/rzx/l46` 2,776, `stage1/rzx/l18` 2,099 and 116 more) |
| Called from | `MainLoop` |
| Calls | `WaterA1`, `WaterA2`, `WaterA3`, `WaterA4`, `WaterA5`, `WaterA6`, `WaterA7`, `WaterA8`, `WaterB1`, `WaterB2`, `WaterB3`, `WaterB4`, `WaterB5`, `WaterB6`, `WaterB7`, `WaterB8`, `WaterC1`, `WaterC2`, `WaterC3`, `WaterC4`, `WaterC5`, `WaterC6`, `WaterC7`, `WaterC8`, `WaterC9` |
| Reads | `$AB26`-`$AB2B` (`FireOutStep`, `FireOutSteps`, `FireOutAddr`, `FireOutActive`); `$C55E`-`$C58F` (`FireOutLeft`, `FireOutRight`, `FireOutDown`) |
| Writes | `$AB26` (`FireOutStep`) |

### `WaterA1` (`$C019`)

**Sequence A: the water sound `$F427`, drop frame A1 on**

Witness: L1 12 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 runs of its first instruction, entered by a jump (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `WaterStep` |
| Calls | `DropA1` (tail), `SfxWaterDrop` |

### `WaterA2` (`$C01F`)

**Drop A1 off, A2 on**

Witness: L1 12 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 runs of its first instruction, entered by a jump (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `WaterStep` |
| Calls | `DropA1`, `DropA2` (tail) |

### `WaterA3` (`$C025`)

**Drop A2 off, A3 on**

Witness: L1 12 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 runs of its first instruction, entered by a jump (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `WaterStep` |
| Calls | `DropA2`, `DropA3` (tail) |

### `WaterA4` (`$C02B`)

**Drop A3 off, the fire out (ExtinguishFire) and steam 1 on**

Witness: L1 12 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 runs of its first instruction, entered by a jump (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `WaterStep` |
| Calls | `DropA3`, `ExtinguishFire` (tail) |

### `WaterA5` (`$C031`)

**Steam 1 off, 2 on**

Witness: L1 12 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 runs of its first instruction, entered by a jump (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `WaterStep` |
| Calls | `Steam1`, `Steam2` (tail) |

### `WaterA6` (`$C037`)

**Steam 2 off, 3 on**

Witness: L1 12 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 runs of its first instruction, entered by a jump (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `WaterStep` |
| Calls | `Steam2`, `Steam3` (tail) |

### `WaterA7` (`$C03D`)

**Steam 3 off, 4 on**

Witness: L1 12 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 runs of its first instruction, entered by a jump (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `WaterStep` |
| Calls | `Steam3`, `Steam4` (tail) |

### `WaterA8` (`$C043`)

**Steam 4 off; the animation ends (`$AB2B` = 0)**

Witness: L1 12 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 runs of its first instruction, entered by a jump (`stage1/rzx/l08` 3, `stage1/rzx/l79` 2, `stage1/rzx/l00` 1 and 6 more) |
| Called from | `WaterStep` |
| Calls | `Steam4` |
| Writes | `$AB2B` (`FireOutActive`) |

### `WaterB1` (`$C04C`)

**Sequence B: the water sound, drop frame B1 on**

Witness: L1 25 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 4, `stage1/rzx/l21` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `WaterStep` |
| Calls | `DropB1` (tail), `SfxWaterDrop` |

### `WaterB2` (`$C052`)

**Drop B1 off, B2 on**

Witness: L1 25 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 4, `stage1/rzx/l21` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `WaterStep` |
| Calls | `DropB1`, `DropB2` (tail) |

### `WaterB3` (`$C058`)

**Drop B2 off, B3 on**

Witness: L1 25 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 4, `stage1/rzx/l21` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `WaterStep` |
| Calls | `DropB2`, `DropB3` (tail) |

### `WaterB4` (`$C05E`)

**Drop B3 off, the fire out and steam 1 on**

Witness: L1 25 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 4, `stage1/rzx/l21` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `WaterStep` |
| Calls | `DropB3`, `ExtinguishFire` (tail) |

### `WaterB5` (`$C064`)

**Steam 1 off, 2 on**

Witness: L1 25 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 4, `stage1/rzx/l21` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `WaterStep` |
| Calls | `Steam1`, `Steam2` (tail) |

### `WaterB6` (`$C06A`)

**Steam 2 off, 3 on**

Witness: L1 25 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 4, `stage1/rzx/l21` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `WaterStep` |
| Calls | `Steam2`, `Steam3` (tail) |

### `WaterB7` (`$C070`)

**Steam 3 off, 4 on**

Witness: L1 25 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 4, `stage1/rzx/l21` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `WaterStep` |
| Calls | `Steam3`, `Steam4` (tail) |

### `WaterB8` (`$C076`)

**Steam 4 off; the animation ends**

Witness: L1 25 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 4, `stage1/rzx/l21` 2, `stage1/rzx/l90` 2 and 16 more) |
| Called from | `WaterStep` |
| Calls | `Steam4` |
| Writes | `$AB2B` (`FireOutActive`) |

### `WaterC1` (`$C07F`)

**Sequence C: the water sound, drop frame C1 on**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `DropC1` (tail), `SfxWaterDrop` |

### `WaterC2` (`$C085`)

**Drop C1 off, C2 on**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `DropC1`, `DropC2` (tail) |

### `WaterC3` (`$C08B`)

**Drop C2 off, C3 on**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `DropC2`, `DropC3` (tail) |

### `WaterC4` (`$C091`)

**Drop C3 off, C4 on**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `DropC3`, `DropC4` (tail) |

### `WaterC5` (`$C097`)

**Drop C4 off, the fire out and steam 1 on**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `DropC4`, `ExtinguishFire` (tail) |

### `WaterC6` (`$C09D`)

**Steam 1 off, 2 on**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `Steam1`, `Steam2` (tail) |

### `WaterC7` (`$C0A3`)

**Steam 2 off, 3 on**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `Steam2`, `Steam3` (tail) |

### `WaterC8` (`$C0A9`)

**Steam 3 off, 4 on**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `Steam3`, `Steam4` (tail) |

### `WaterC9` (`$C0AF`)

**Steam 4 off; the animation ends**

Witness: L1 18 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage1/rzx/l28` 2, `stage1/rzx/l44` 2, `stage1/rzx/l91` 2 and 12 more) |
| Called from | `WaterStep` |
| Calls | `Steam4` |
| Writes | `$AB2B` (`FireOutActive`) |

### `DropA1` (`$C0B8`)

**XOR the drop at `$AB29` + `$1715`**

Each Drop entry loads its offset into BC and joins XorWaterDrop `$C0E8`.

Witness: L1 24 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24 calls (`stage1/rzx/l08` 6, `stage1/rzx/l79` 4, `stage1/rzx/l00` 2 and 6 more) |
| Called from | `WaterA1` (tail), `WaterA2` |
| Calls | `XorWaterDrop` (tail) |

### `DropA2` (`$C0BD`)

**XOR the drop at `$AB29` - `$089C` (`$F764`)**

Witness: L1 24 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24 calls (`stage1/rzx/l08` 6, `stage1/rzx/l79` 4, `stage1/rzx/l00` 2 and 6 more) |
| Called from | `WaterA2` (tail), `WaterA3` |
| Calls | `XorWaterDrop` (tail) |

### `DropA3` (`$C0C2`)

**XOR the drop at `$AB29` + `$1763`**

Witness: L1 24 (l59, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24 calls (`stage1/rzx/l08` 6, `stage1/rzx/l79` 4, `stage1/rzx/l00` 2 and 6 more) |
| Called from | `WaterA3` (tail), `WaterA4` |
| Calls | `XorWaterDrop` (tail) |

### `DropB1` (`$C0C7`)

**XOR the drop at `$AB29` + `$1711`**

Witness: L1 50 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 50 calls (`stage1/rzx/l79` 8, `stage1/rzx/l21` 4, `stage1/rzx/l90` 4 and 16 more) |
| Called from | `WaterB1` (tail), `WaterB2` |
| Calls | `XorWaterDrop` (tail) |

### `DropB2` (`$C0CC`)

**XOR the drop at `$AB29` - `$089E` (`$F762`)**

Witness: L1 50 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 50 calls (`stage1/rzx/l79` 8, `stage1/rzx/l21` 4, `stage1/rzx/l90` 4 and 16 more) |
| Called from | `WaterB2` (tail), `WaterB3` |
| Calls | `XorWaterDrop` (tail) |

### `DropB3` (`$C0D1`)

**XOR the drop at `$AB29` + `$1763`**

Witness: L1 50 (l36, l59, rzx x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 50 calls (`stage1/rzx/l79` 8, `stage1/rzx/l21` 4, `stage1/rzx/l90` 4 and 16 more) |
| Called from | `WaterB3` (tail), `WaterB4` |
| Calls | `XorWaterDrop` (tail) |

### `DropC1` (`$C0D6`)

**XOR the drop at `$AB29` + `$1EC3`**

Witness: L1 36 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rzx/l28` 4, `stage1/rzx/l44` 4, `stage1/rzx/l91` 4 and 12 more) |
| Called from | `WaterC1` (tail), `WaterC2` |
| Calls | `XorWaterDrop` (tail) |

### `DropC2` (`$C0DB`)

**XOR the drop at `$AB29` + `$0713`**

Witness: L1 36 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rzx/l28` 4, `stage1/rzx/l44` 4, `stage1/rzx/l91` 4 and 12 more) |
| Called from | `WaterC2` (tail), `WaterC3` |
| Calls | `XorWaterDrop` (tail) |

### `DropC3` (`$C0E0`)

**XOR the drop at `$AB29` + `$2F13`**

Witness: L1 36 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rzx/l28` 4, `stage1/rzx/l44` 4, `stage1/rzx/l91` 4 and 12 more) |
| Called from | `WaterC3` (tail), `WaterC4` |
| Calls | `XorWaterDrop` (tail) |

### `DropC4` (`$C0E5`)

**XOR the drop at `$AB29` + `$1763`**

Witness: L1 36 (menu, l10, l56, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rzx/l28` 4, `stage1/rzx/l44` 4, `stage1/rzx/l91` 4 and 12 more) |
| Called from | `WaterC4` (tail), `WaterC5` |
| Calls | `XorWaterDrop` (falls into) |

### `XorWaterDrop` (`$C0E8`)

**XOR WaterDrop (2 bytes × 7 rows, colour 5) at `$AB29` + BC**

DrawSpriteXorInk `$E3E5`. The offsets are CPC screen offsets (`$0800` a pixel line, 80 a character row).

Witness: L1 366 (menu, l10, l36, l56, l59, rzx x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 366 calls (`stage1/rzx/l79` 36, `stage1/rzx/l08` 24, `stage2/rec/l59` 18 and 30 more) |
| Called from | `DropA1` (tail), `DropA2` (tail), `DropA3` (tail), `DropB1` (tail), `DropB2` (tail), `DropB3` (tail), `DropC1` (tail), `DropC2` (tail), `DropC3` (tail), `DropC4` (falls into) |
| Calls | `XorSpriteColoured` |
| Reads | `$AB29`-`$AB2A` (`FireOutAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `ExtinguishFire` (`$C10C`)

**Put out the fire under the ball: platform 8 becomes 1, 9 becomes 5**

FireFlags `$AAB3`[`$AA44`] = 0; PlatformCells[`$AA44`] becomes 1 if it was 8, else 5; the blank `$6708` is stored over the flames at `$AB29` + `$0FB1` (6 bytes × 6 rows, colour `$C6`); then falls into Steam1. Witness: 49 fires put out (11 + 22 + 16 by sequence).

Witness: L1 55 (menu, l10, l36, l56, l59, rzx x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 55 calls (`stage1/rzx/l79` 6, `stage1/rzx/l08` 4, `stage2/rec/l59` 3 and 30 more) |
| Called from | `WaterA4` (tail), `WaterB4` (tail), `WaterC5` (tail) |
| Calls | `DrawSpriteColoured` |
| Reads | `$AA44` (`BallCell`); `$AA6D`-`$AA8E` (`CellPlatforms+2`); `$AB29`-`$AB2A` (`FireOutAddr`) |
| Writes | `$A9FE` (`SpriteWidth`); `$AA6D`-`$AA8E` (`CellPlatforms+2`); `$AAB5`-`$AAD6` (`CellBurning+2`) |

### `Steam1` (`$C13E`)

**XOR steam frame 1 (`$81A7`, 6 bytes × 6 rows) at `$AB29` + `$0FB1`**

Witness: L1 110 (menu, l10, l36, l56, l59, rzx x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 55 calls (`stage1/rzx/l79` 6, `stage1/rzx/l08` 4, `stage2/rec/l59` 3 and 30 more) |
| Called from | `WaterA5`, `WaterB5`, `WaterC6` |
| Calls | `XorSpriteColoured` |
| Reads | `$AB29`-`$AB2A` (`FireOutAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `Steam2` (`$C155`)

**XOR steam frame 2 (`$81CB`, 6 bytes × 3 rows) at `$AB29` + `$27B1`**

Witness: L1 110 (menu, l10, l36, l56, l59, rzx x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 110 calls (`stage1/rzx/l79` 12, `stage1/rzx/l08` 8, `stage2/rec/l59` 6 and 30 more) |
| Called from | `WaterA5` (tail), `WaterA6`, `WaterB5` (tail), `WaterB6`, `WaterC6` (tail), `WaterC7` |
| Calls | `XorSpriteColoured` |
| Reads | `$AB29`-`$AB2A` (`FireOutAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `Steam3` (`$C16D`)

**XOR steam frame 3 (`$81DD`, 6 bytes × 2 rows) at `$AB29` + `$2FB1`**

Witness: L1 110 (menu, l10, l36, l56, l59, rzx x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 110 calls (`stage1/rzx/l79` 12, `stage1/rzx/l08` 8, `stage2/rec/l59` 6 and 30 more) |
| Called from | `WaterA6` (tail), `WaterA7`, `WaterB6` (tail), `WaterB7`, `WaterC7` (tail), `WaterC8` |
| Calls | `XorSpriteColoured` |
| Reads | `$AB29`-`$AB2A` (`FireOutAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `Steam4` (`$C185`)

**XOR steam frame 4 (`$81E9`, 4 bytes × 3 rows) at `$AB29` + `$27B2`**

Witness: L1 110 (menu, l10, l36, l56, l59, rzx x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 110 calls (`stage1/rzx/l79` 12, `stage1/rzx/l08` 8, `stage2/rec/l59` 6 and 30 more) |
| Called from | `WaterA7` (tail), `WaterA8`, `WaterB7` (tail), `WaterB8`, `WaterC8` (tail), `WaterC9` |
| Calls | `XorSpriteColoured` |
| Reads | `$AB29`-`$AB2A` (`FireOutAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `PlatformChangeStep` (`$C19D`)

**Run the next step of a worn platform's animation, if one is active**

When `$AA15` is set (copied from `$AA14` by the landing handlers once the ball has left): jumps to the step table `$AB22` (WearTo3Steps `$C53C`, WearTo4Steps `$C544` or FallAwaySteps `$C54C`) entry `$AB21` and advances `$AB21`. The frames are XORed at `$AB24` (the cell's address when the change started). Called by MainLoop (`$ACD5`) and the move handlers (`$CD80`, `$CD83`, `$CDA0`, `$CE8F`).

Witness: L1 94743 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

[Animation: `PlatformChangeStep` at work](img/routines/PlatformChangeStep.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 135,984 t-states own (0.01 %) |
| Runs (the other recordings) | 90,902 calls (`stage1/menu` 5,724, `stage1/rzx/l46` 2,776, `stage1/rzx/l18` 2,132 and 116 more) |
| Called from | `MainLoop`, `UpStep3`, `UpStep4`, `DownStep4` |
| Calls | `WearTo3Step1`, `WearTo3Step2`, `WearTo3Step3`, `WearTo3Step4`, `WearTo4Step1`, `WearTo4Step2`, `WearTo4Step3`, `WearTo4Step4`, `FallAwayStep1`, `FallAwayStep2`, `FallAwayStep3`, `FallAwayStep4`, `FallAwayStep5`, `FallAwayStep6`, `FallAwayStep7`, `FallAwayStep8`, `FallAwayStep9` |
| Reads | `$AA15` (`CrumbleActive`); `$AB21`-`$AB23` (`CrumbleStep`, `CrumbleSteps`); `$C53C`-`$C55D` (`CrumbleSteps2`, `CrumbleSteps3`, `CrumbleSteps4`) |
| Writes | `$AB21` (`CrumbleStep`) |

### `WearTo3Step1` (`$C1C3`)

**Type 2 becomes 3: write the cell, platform 2 off, crack 2a on**

Witness: L1 250 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 250 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 31, `stage1/rzx/l16` 16, `stage2/rec/l68` 12 and 63 more) |
| Called from | `PlatformChangeStep` |
| Calls | `SetPlatformCell`, `XorPlatform2`, `XorCrack2a` |

### `WearTo3Step2` (`$C1CD`)

**Crack 2a off, 2b on**

Witness: L1 250 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 250 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 31, `stage1/rzx/l16` 16, `stage2/rec/l68` 12 and 63 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorCrack2a`, `XorCrack2b` |

### `WearTo3Step3` (`$C1D4`)

**Crack 2b off, 2c on**

Witness: L1 249 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 249 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 31, `stage1/rzx/l16` 16, `stage2/rec/l68` 12 and 63 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorCrack2b`, `XorCrack2c` |

### `WearTo3Step4` (`$C1DB`)

**Crack 2c off, platform 3 on; done (`$AA14` = `$AA15` = 0)**

Witness: L1 249 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 249 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 31, `stage1/rzx/l16` 16, `stage2/rec/l68` 12 and 63 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorCrack2c`, `XorPlatform3` |
| Writes | `$AA14`-`$AA15` (`CrumblePending`, `CrumbleActive`) |

### `WearTo4Step1` (`$C1EA`)

**Type 3 becomes 4: platform 3 off, crack 3a on**

Witness: L1 394 (menu, scoreloop, l x11, rzx x77).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 394 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 30, `stage1/rzx/l50` 12, `stage2/rec/l68` 12 and 87 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorPlatform3`, `XorCrack3a` |

### `WearTo4Step2` (`$C1F1`)

**Crack 3a off, 3b on**

Witness: L1 394 (menu, scoreloop, l x11, rzx x77).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 394 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 30, `stage1/rzx/l50` 12, `stage2/rec/l68` 12 and 87 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorCrack3a`, `XorCrack3b` |

### `WearTo4Step3` (`$C1F8`)

**Crack 3b off, 3c on**

Witness: L1 394 (menu, scoreloop, l x11, rzx x77).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 394 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 30, `stage1/rzx/l50` 12, `stage2/rec/l68` 12 and 87 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorCrack3b`, `XorCrack3c` |

### `WearTo4Step4` (`$C1FF`)

**Write the cell (4), crack 3c off, platform 4 on; done**

Witness: L1 394 (menu, scoreloop, l x11, rzx x77).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 394 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 30, `stage1/rzx/l50` 12, `stage2/rec/l68` 12 and 87 more) |
| Called from | `PlatformChangeStep` |
| Calls | `SetPlatformCell`, `XorCrack3c`, `XorPlatform4` |
| Writes | `$AA14`-`$AA15` (`CrumblePending`, `CrumbleActive`) |

### `FallAwayStep1` (`$C211`)

**Type 4 goes: write the cell (0), platform 4 off, fall frame 1 on**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `SetPlatformCell`, `XorPlatform4`, `XorFall1` |

### `FallAwayStep2` (`$C21B`)

**Fall frame 1 off, 2 on**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorFall1`, `XorFall2` |

### `FallAwayStep3` (`$C222`)

**Fall frame 2 off, 3 on**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorFall2`, `XorFall3` |

### `FallAwayStep4` (`$C229`)

**Fall frame 3 off, 4 on**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorFall3`, `XorFall4` |

### `FallAwayStep5` (`$C230`)

**Fall frame 4 off, 5 on**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorFall4`, `XorFall5` |

### `FallAwayStep6` (`$C237`)

**Fall frame 5 off, 6 on**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorFall5`, `XorFall6` |

### `FallAwayStep7` (`$C23E`)

**Fall frame 6 off, 7 on**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorFall6`, `XorFall7` |

### `FallAwayStep8` (`$C245`)

**Fall frame 7 off, 8 on**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorFall7`, `XorFall8` |

### `FallAwayStep9` (`$C24C`)

**Fall frame 8 off: the platform is gone; done**

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 runs of its first instruction, entered by a jump (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `PlatformChangeStep` |
| Calls | `XorFall8` |
| Writes | `$AA14`-`$AA15` (`CrumblePending`, `CrumbleActive`) |

### `XorPlatform2` (`$C258`)

**XOR the type 2 platform (`$7900`, 8 bytes × 4 rows) at `$AB24`**

Each of the frame routines `$C258-$C3BE` XORs one frame at `$AB24` plus a byte offset (DrawSpriteXor `$E3EE`): the platforms 2, 3 and 4 as the level shows them and the frames between.

Witness: L1 250 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 250 calls (`stage1/rzx/l18` 31, `stage1/rzx/l16` 16, `stage2/rec/l68` 12 and 63 more) |
| Called from | `WearTo3Step1` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorCrack2a` (`$C26A`)

**XOR `$7D84` (8 bytes × 4 rows) at `$AB24`**

Witness: L1 500 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 500 calls (`stage1/rzx/l18` 62, `stage1/rzx/l16` 32, `stage2/rec/l68` 24 and 63 more) |
| Called from | `WearTo3Step1`, `WearTo3Step2` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorCrack2b` (`$C27C`)

**XOR `$7DA4` (6 bytes × 4 rows) at `$AB24` + 1**

Witness: L1 499 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 499 calls (`stage1/rzx/l18` 62, `stage1/rzx/l16` 32, `stage2/rec/l68` 24 and 63 more) |
| Called from | `WearTo3Step2`, `WearTo3Step3` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorCrack2c` (`$C293`)

**XOR `$7DBC` (6 bytes × 4 rows) at `$AB24` + 1**

Witness: L1 498 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 498 calls (`stage1/rzx/l18` 62, `stage1/rzx/l16` 32, `stage2/rec/l68` 24 and 63 more) |
| Called from | `WearTo3Step3`, `WearTo3Step4` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorPlatform3` (`$C2AA`)

**XOR the type 3 platform (`$7A78`, 6 bytes × 4 rows) at `$AB24` + 1**

Witness: L1 643 (menu, scoreloop, l x11, rzx x78).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 643 calls (`stage1/rzx/l18` 61, `stage1/rzx/l16` 26, `stage2/rec/l68` 24 and 88 more) |
| Called from | `WearTo3Step4`, `WearTo4Step1` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorCrack3a` (`$C2C1`)

**XOR `$7DD4` (6 bytes × 4 rows) at `$AB24` + 1**

Witness: L1 788 (menu, scoreloop, l x11, rzx x77).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 788 calls (`stage1/rzx/l18` 60, `stage1/rzx/l50` 24, `stage2/rec/l68` 24 and 87 more) |
| Called from | `WearTo4Step1`, `WearTo4Step2` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorCrack3b` (`$C2D8`)

**XOR `$7DEC` (4 bytes × 4 rows) at `$AB24` + 2**

Witness: L1 788 (menu, scoreloop, l x11, rzx x77).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 788 calls (`stage1/rzx/l18` 60, `stage1/rzx/l50` 24, `stage2/rec/l68` 24 and 87 more) |
| Called from | `WearTo4Step2`, `WearTo4Step3` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorCrack3c` (`$C2EF`)

**XOR `$7DFC` (4 bytes × 4 rows) at `$AB24` + 2**

Witness: L1 788 (menu, scoreloop, l x11, rzx x77).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 788 calls (`stage1/rzx/l18` 60, `stage1/rzx/l50` 24, `stage2/rec/l68` 24 and 87 more) |
| Called from | `WearTo4Step3`, `WearTo4Step4` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorPlatform4` (`$C306`)

**XOR the type 4 platform (`$7B62`, 4 bytes × 4 rows) at `$AB24` + 2**

Witness: L1 1177 (menu, scoreloop, l x12, rzx x90).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,177 calls (`stage1/rzx/l18` 56, `stage1/rzx/l13` 36, `stage1/rzx/l50` 27 and 101 more) |
| Called from | `WearTo4Step4`, `FallAwayStep1` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorFall1` (`$C31D`)

**XOR `$7E0C` (4 bytes × 4 rows) at `$AB24` + 2**

Witness: L1 1566 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,566 calls (`stage1/rzx/l13` 72, `stage1/rzx/l18` 52, `stage1/rzx/l74` 48 and 96 more) |
| Called from | `FallAwayStep1`, `FallAwayStep2` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorFall2` (`$C334`)

**XOR `$7E1C` (2 bytes × 4 rows) at `$AB24` + 3**

Witness: L1 1566 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,566 calls (`stage1/rzx/l13` 72, `stage1/rzx/l18` 52, `stage1/rzx/l74` 48 and 96 more) |
| Called from | `FallAwayStep2`, `FallAwayStep3` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorFall3` (`$C34B`)

**XOR `$7E24` (2 bytes × 4 rows) at `$AB24` + 3**

Witness: L1 1566 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,566 calls (`stage1/rzx/l13` 72, `stage1/rzx/l18` 52, `stage1/rzx/l74` 48 and 96 more) |
| Called from | `FallAwayStep3`, `FallAwayStep4` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorFall4` (`$C362`)

**XOR `$7E2C` (2 bytes × 4 rows) at `$AB24` + 3**

Witness: L1 1566 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,566 calls (`stage1/rzx/l13` 72, `stage1/rzx/l18` 52, `stage1/rzx/l74` 48 and 96 more) |
| Called from | `FallAwayStep4`, `FallAwayStep5` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorFall5` (`$C379`)

**XOR `$7E34` (2 bytes × 5 rows) at `$AB24` + 3**

Witness: L1 1566 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,566 calls (`stage1/rzx/l13` 72, `stage1/rzx/l18` 52, `stage1/rzx/l74` 48 and 96 more) |
| Called from | `FallAwayStep5`, `FallAwayStep6` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorFall6` (`$C390`)

**XOR `$7E3E` (2 bytes × 5 rows) at `$AB24` + 3 - `$0800` (a pixel line higher)**

Witness: L1 1566 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,566 calls (`stage1/rzx/l13` 72, `stage1/rzx/l18` 52, `stage1/rzx/l74` 48 and 96 more) |
| Called from | `FallAwayStep6`, `FallAwayStep7` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorFall7` (`$C3A7`)

**XOR `$7E48` (2 bytes × 5 rows) at `$AB24` + 3 - `$0800`**

Witness: L1 1566 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,566 calls (`stage1/rzx/l13` 72, `stage1/rzx/l18` 52, `stage1/rzx/l74` 48 and 96 more) |
| Called from | `FallAwayStep7`, `FallAwayStep8` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `XorFall8` (`$C3BE`)

**XOR `$7E52` (2 bytes × 5 rows) at `$AB24` + 3 - `$0800`**

Witness: L1 1566 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,566 calls (`stage1/rzx/l13` 72, `stage1/rzx/l18` 52, `stage1/rzx/l74` 48 and 96 more) |
| Called from | `FallAwayStep8`, `FallAwayStep9` |
| Calls | `XorSprite` |
| Reads | `$AB24`-`$AB25` (`CrumbleAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `StartWearTo3` (`$C3D5`)

**The ball bounced on a type 2 platform: arm its change to 3**

`$AB24` = the cell's address `$AB2D`, `$AA14` = 1 (pending until the ball leaves), the steps WearTo3Steps `$C53C` from 0, the cell `$AB1B` = `$AA44`, the new type `$AB20` = 3. Called by the landing handlers (`$C7C1`, `$C8C4`, `$CB0A`, `$CD23`). Platforms 2, 3 and 4 wear: each bounce takes them one step towards nothing. Witness: 220 runs.

Witness: L1 250 (menu, l x9, rzx x56).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 250 calls (`stage1/rzx/l18` 31, `stage1/rzx/l16` 16, `stage2/rec/l68` 12 and 63 more) |
| Called from | `BounceCrumble2`, `LeftCrumble2`, `RightCrumble2`, `UpCrumble2` |
| Reads | `$AA44` (`BallCell`); `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$AA14` (`CrumblePending`); `$AB1B`-`$AB25` (`CrumbleCell`, `CellPlatform`, `CellObject`, `CellWall` and 5 more) |

### `StartWearTo4` (`$C3F8`)

**The ball bounced on a type 3 platform: arm its change to 4**

As StartWearTo3 with WearTo4Steps `$C544` and the new type 4. Witness: 328 runs.

Witness: L1 394 (menu, scoreloop, l x11, rzx x77).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 394 calls (`stage1/rzx/l18` 30, `stage2/rec/l68` 12, `stage1/rzx/l50` 12 and 87 more) |
| Called from | `BounceCrumble3`, `LeftCrumble3`, `RightCrumble3`, `UpCrumble3` |
| Reads | `$AA44` (`BallCell`); `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$AA14` (`CrumblePending`); `$AB1B`-`$AB25` (`CrumbleCell`, `CellPlatform`, `CellObject`, `CellWall` and 5 more) |

### `StartFallAway` (`$C41B`)

**The ball bounced on a type 4 platform: arm its fall (type 0, no platform)**

As StartWearTo3 with FallAwaySteps `$C54C` and the new type 0. Witness: 672 runs.

Witness: L1 783 (scoreloop, l x11, rzx x87).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 783 calls (`stage1/rzx/l13` 36, `stage1/rzx/l18` 26, `stage1/rzx/l74` 24 and 96 more) |
| Called from | `BounceCrumble4`, `LeftCrumble4`, `RightCrumble4`, `UpCrumble4` |
| Reads | `$AA44` (`BallCell`); `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$AA14` (`CrumblePending`); `$AB1B`-`$AB25` (`CrumbleCell`, `CellPlatform`, `CellObject`, `CellWall` and 5 more) |

### `WallStep` (`$C43E`)

**Run the next step of a lock's opening, if one is active**

When `$AA1D` is set: jumps to the step table `$AA1A` (set by the wall handlers `$C95D-$C971` and `$CBA0-$CBB4` from the lock's type: LockSteps `$C592` for 3, `$C596` for 2, `$C59A` for 1) entry `$AA1C` and advances it. A key turns lock 3 into 2, 2 into 1, and 1 into an open wall, each with its sound. Called by MainLoop (`$ACD8`).

Witness: L1 93416 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

[Animation: `WallStep` at work](img/routines/WallStep.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 141,939 t-states own (0.01 %) |
| Runs (the other recordings) | 89,575 calls (`stage1/menu` 5,721, `stage1/rzx/l46` 2,776, `stage1/rzx/l18` 2,099 and 116 more) |
| Called from | `MainLoop` |
| Calls | `Lock3Step1`, `Lock3Step2`, `Lock2Step1`, `Lock2Step2`, `Lock1Step1`, `Lock1Step2`, `Lock1Step3`, `Lock1Step4`, `Lock1Step5`, `Lock1Step6`, `Lock1Step7` |
| Reads | `$AA1A`-`$AA1D` (`LockAnimSteps`, `LockStep`, `LockActive`); `$C592`-`$C5A7` (`LockOpenSteps3`, `LockOpenSteps2`, `LockOpenSteps1`) |
| Writes | `$AA1C` (`LockStep`) |

### `Lock3Step1` (`$C464`)

**Lock 3: the sound `$F43E`, lock 3 frame off, the flash frame on**

XorLock3 `$D20A`, XorLockFlash `$D216`.

Witness: L1 24 (l36, l96, rzx x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24 runs of its first instruction, entered by a jump (`stage1/rzx/l16` 2, `stage1/rzx/l41` 2, `stage1/rzx/l43` 2 and 17 more) |
| Called from | `WallStep` |
| Calls | `DrawLock3Pic`, `DrawLockFlashPic`, `SfxWallBounce` |

### `Lock3Step2` (`$C46E`)

**Flash off, lock 2 frame on; done**

Witness: L1 24 (l36, l96, rzx x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24 runs of its first instruction, entered by a jump (`stage1/rzx/l16` 2, `stage1/rzx/l41` 2, `stage1/rzx/l43` 2 and 17 more) |
| Called from | `WallStep` |
| Calls | `WallStepEnd` (tail), `DrawLock2Pic`, `DrawLockFlashPic` |

### `Lock2Step1` (`$C476`)

**Lock 2: the sound `$F455`, lock 2 off, flash on**

Witness: L1 38 (l36, l59, l96, rzx x24).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 38 runs of its first instruction, entered by a jump (`stage1/rzx/l54` 4, `stage1/rzx/l12` 2, `stage1/rzx/l16` 2 and 24 more) |
| Called from | `WallStep` |
| Calls | `DrawLock2Pic`, `DrawLockFlashPic`, `SfxLockA` |

### `Lock2Step2` (`$C480`)

**Flash off, lock 1 frame on; done**

Witness: L1 38 (l36, l59, l96, rzx x24).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 38 runs of its first instruction, entered by a jump (`stage1/rzx/l54` 4, `stage1/rzx/l12` 2, `stage1/rzx/l16` 2 and 24 more) |
| Called from | `WallStep` |
| Calls | `WallStepEnd` (tail), `DrawLock1Pic`, `DrawLockFlashPic` |

### `Lock1Step1` (`$C488`)

**Lock 1: the sound `$F46C`, lock 1 off, flash on**

Witness: L1 117 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 117 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 15, `stage2/rec/l68` 10, `stage1/rzx/l68` 8 and 46 more) |
| Called from | `WallStep` |
| Calls | `DrawLock1Pic`, `DrawLockFlashPic`, `SfxLockB` |

### `Lock1Step2` (`$C492`)

**Flash off, the opening frame `$7FDC` stored**

Witness: L1 117 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 117 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 15, `stage2/rec/l68` 10, `stage1/rzx/l68` 8 and 46 more) |
| Called from | `WallStep` |
| Calls | `StoreWallFrame`, `DrawLockFlashPic` |

### `Lock1Step3` (`$C49C`)

**The opening frame `$800C`**

Witness: L1 117 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 117 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 15, `stage2/rec/l68` 10, `stage1/rzx/l68` 8 and 46 more) |
| Called from | `WallStep` |
| Calls | `StoreWallFrame` |

### `Lock1Step4` (`$C4A3`)

**The opening frame `$803C`**

Witness: L1 117 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 117 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 15, `stage2/rec/l68` 10, `stage1/rzx/l68` 8 and 46 more) |
| Called from | `WallStep` |
| Calls | `StoreWallFrame` |

### `Lock1Step5` (`$C4AA`)

**The opening frame `$806C`**

Witness: L1 117 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 117 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 15, `stage2/rec/l68` 10, `stage1/rzx/l68` 8 and 46 more) |
| Called from | `WallStep` |
| Calls | `StoreWallFrame` |

### `Lock1Step6` (`$C4B1`)

**The opening frame `$809C`**

Witness: L1 117 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 117 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 15, `stage2/rec/l68` 10, `stage1/rzx/l68` 8 and 46 more) |
| Called from | `WallStep` |
| Calls | `StoreWallFrame` |

### `Lock1Step7` (`$C4B8`)

**The blank `$6708`: the wall is gone; done**

Witness: L1 117 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 117 runs of its first instruction, entered by a jump (`stage1/rzx/l79` 15, `stage2/rec/l68` 10, `stage1/rzx/l68` 8 and 46 more) |
| Called from | `WallStep` |
| Calls | `StoreWallFrame` |
| Writes | `$AA1D` (`LockActive`) |

### `WallStepEnd` (`$C4BE`)

**`$AA1D` = 0: the lock's animation is over**

Witness: L1 179 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 62 calls (`stage1/rzx/l54` 4, `stage1/rzx/l43` 4, `stage1/rzx/l41` 4 and 24 more) |
| Called from | `Lock3Step2` (tail), `Lock2Step2` (tail) |
| Writes | `$AA1D` (`LockActive`) |

### `StoreWallFrame` (`$C4C4`)

**Store the wall frame HL (2 bytes × 24 rows) at `$AA18`**

DrawSprite `$E318` (a store, not an XOR).

Witness: L1 702 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 702 calls (`stage1/rzx/l79` 90, `stage2/rec/l68` 60, `stage1/rzx/l68` 48 and 46 more) |
| Called from | `Lock1Step2`, `Lock1Step3`, `Lock1Step4`, `Lock1Step5`, `Lock1Step6`, `Lock1Step7` |
| Calls | `DrawSprite` |
| Reads | `$AA18`-`$AA19` (`LockAnimAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `ScreenAddrToLine` (`$C71F`)

**Convert a CPC screen address to the character row, pixel line and byte column**

Input HL: an address in the CPC layout (`$C000` + line in the row x `$800` + row x 80 + byte). Output: ScanInRow `$C74E` = the line within the character row (0-7), CharRow `$C74F` = the row, ByteColumn `$C750` = the byte column (0-79), PixelLine `$C751` = row x 8 + line. Uses DivideHLbyBC `$C752` for the division by 80. BC, DE, HL changed. Every picture drawn goes through it (277 064 calls in the recordings).

Witness: L1 327885 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9,177 calls, 2,026,645 t-states own (0.16 %) |
| Runs (the other recordings) | 318,708 calls (`stage1/menu` 14,729, `stage1/rzx/l46` 8,906, `stage1/rzx/l38` 8,399 and 116 more) |
| Called from | `LevelEnd`, `BrickCrumble1`, `BrickCrumble2`, `BrickCrumble3`, `BrickCrumble4`, `LeftStep5`, `RightStep5`, `DrawSprite`, `XorSprite`, `XorBricks` |
| Calls | `DivideHLbyBC` |
| Writes | `$C74E`-`$C751` (`ScanInRow`, `CharRow`, `ByteColumn`, `PixelLine`) |

### `DivideHLbyBC` (`$C752`)

**Divide HL by BC: the quotient to DivQuotient, the remainder to DivRemainder**

A 16-step shift-and-subtract division. Input HL the dividend, BC the divisor. Output HL = DivQuotient `$C774`, DE = DivRemainder `$C776`. Only ScreenAddrToLine calls it (BC = 80).

Witness: L1 327885 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 9,177 calls, 13,042,510 t-states own (1.03 %) |
| Runs (the other recordings) | 318,708 calls (`stage1/menu` 14,729, `stage1/rzx/l46` 8,906, `stage1/rzx/l38` 8,399 and 116 more) |
| Called from | `ScreenAddrToLine` |
| Writes | `$C774`-`$C777` (`DivQuotient`, `DivRemainder`) |

### `DrawPanelA` (`$CF0C`)

**Draw the 72 x 200 picture PanelPicture at CPC `$C03E` (never called)**

Copies PanelPicture `$D2B4` (18 bytes a line, 200 lines) to the CPC address `$C03E` with the store routine `$E318`. No instruction calls it and no table holds its address: known only from the code. It reads like the Amstrad version's side panel (the Spectrum draws the sides from `$6398` and `$6518` with `$B488` instead).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawPanelB` (`$CF1D`)

**A second copy of DrawPanelA, never called**

Byte for byte the same code. Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UnusedRet` (`$D076`)

**A lone RET before DrawObjectXor**

Known only from the code: nothing calls it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawObjectXor` (`$D077`)

**XOR the picture at `$A9F6` over the current cell's object place (never called)**

The same place and size as BuildLevelObject's object (`$AB2D` - `$9E`, 14 lines of 4 bytes), the picture from the word `$A9F6`, drawn by XOR without ink. Nothing calls it: an earlier way to draw or wipe an object. Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawExitSign` (`$D08E`)

**XOR the EXIT sign `$6698` above the current cell (never called)**

Draws `$6698` (7 lines of 8 bytes) at `$AB2D` + `$F710`, one character row above the platform. Nothing calls it; OpenExit `$BCB9` would be its caller. Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlatDrawNone` (`$D0A4`)

**Platform types 0 and 11: nothing to draw**

Witness: L1 1118 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x23).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 12 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 120 t-states own (0.00 %) |
| Runs (the other recordings) | 1,106 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 120, `docs/integrate/rec/scoreloop` 90, `stage1/menu` 78 and 31 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail) |

### `PlatDraw1` (`$D0A7`)

**Platform type 1, the plain platform**

Witness: L1 1285 (c1, exitbelow, fire, gameover, menu, rightspike, twoname, l51, l98, rzx x13).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 58 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,654 t-states own (0.00 %) |
| Runs (the other recordings) | 1,227 runs of its first instruction, entered by a jump (`stage1/gameover` 348, `stage2/rec/twoname` 348, `stage1/menu` 219 and 18 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawPlatform1Pic` |

### `DrawPlatform1Pic` (`$D0AD`)

**XOR the plain platform `$7788` at the cell**

Witness: L1 1355 (c1, exitbelow, fire, gameover, menu, rightspike, twoname, l51, l98, rzx x13).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 60 calls, 5,816 t-states own (0.00 %) |
| Runs (the other recordings) | 1,295 calls (`stage2/rec/twoname` 360, `stage1/gameover` 360, `stage1/menu` 228 and 18 more) |
| Called from | `PlatDraw1`, `PlatDraw8` |
| Calls | `DrawPlatformPic` (tail) |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `PlatDraw2` (`$D0B2`)

**Platform type 2, the first crumbling stage**

Witness: L1 187 (fire, menu, l51, l96, l98, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 187 runs of its first instruction, entered by a jump (`stage1/rzx/l68` 70, `stage1/rzx/l15` 32, `stage1/rzx/l56` 15 and 17 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawPlatform2Pic` |

### `DrawPlatform2Pic` (`$D0B8`)

**XOR the picture `$7900` at the cell**

Witness: L1 187 (fire, menu, l51, l96, l98, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 187 calls (`stage1/rzx/l68` 70, `stage1/rzx/l15` 32, `stage1/rzx/l56` 15 and 17 more) |
| Called from | `PlatDraw2` |
| Calls | `DrawPlatformPic` (tail) |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `PlatDraw3` (`$D0BD`)

**Platform type 3, the second crumbling stage**

Witness: L1 196 (scoreloop, l51, l59, l96, l98, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 196 runs of its first instruction, entered by a jump (`docs/integrate/rec/scoreloop` 55, `stage1/rzx/l59` 32, `stage1/rzx/l96` 12 and 17 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawPlatform3Pic` |

### `DrawPlatform3Pic` (`$D0C3`)

**XOR the picture `$7A78` (6 bytes wide) one byte right of the cell**

Witness: L1 196 (scoreloop, l51, l59, l96, l98, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 196 calls (`docs/integrate/rec/scoreloop` 55, `stage1/rzx/l59` 32, `stage1/rzx/l96` 12 and 17 more) |
| Called from | `PlatDraw3` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `PlatDraw4` (`$D0D8`)

**Platform type 4, the last crumbling stage**

Witness: L1 266 (fire, rightspike, scoreloop, l51, l59, l96, l98, rzx x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 266 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 75, `docs/integrate/rec/scoreloop` 35, `stage1/rzx/l59` 24 and 18 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawPlatform4Pic` |

### `DrawPlatform4Pic` (`$D0DE`)

**XOR the picture `$7B62` (4 bytes wide) two bytes right of the cell**

Witness: L1 266 (fire, rightspike, scoreloop, l51, l59, l96, l98, rzx x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 266 calls (`stage1/rzx/l56` 75, `docs/integrate/rec/scoreloop` 35, `stage1/rzx/l59` 24 and 18 more) |
| Called from | `PlatDraw4` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `PlatDraw5` (`$D0F3`)

**Platform type 5, the stopping platform**

Witness: L1 66 (menu, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 66 runs of its first instruction, entered by a jump (`stage1/rzx/l96` 24, `stage1/rzx/l51` 16, `stage1/rzx/l98` 10 and 6 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawPlatform5Pic` |

### `DrawPlatform5Pic` (`$D0F9`)

**XOR the picture `$7BE2` at the cell**

Witness: L1 74 (fire, menu, rzx x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 74 calls (`stage1/rzx/l96` 24, `stage1/rzx/l51` 16, `stage1/rzx/l98` 10 and 8 more) |
| Called from | `PlatDraw5`, `PlatDraw9` |
| Calls | `DrawPlatformPic` (falls into) |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `DrawPlatformPic` (`$D0FE`)

**XOR the picture DE at the cell's address `$AB2D`: 8 bytes wide, 4 lines**

Witness: L1 1616 (c1, exitbelow, fire, gameover, menu, rightspike, twoname, l51, l96, l98, rzx x21).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 60 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 511 calls (`stage1/menu` 236, `stage1/rzx/l51` 48, `stage1/rzx/l56` 45 and 12 more) |
| Called from | `DrawPlatform1Pic` (tail), `DrawPlatform2Pic` (tail), `DrawPlatform5Pic` (falls into) |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `PlatDraw6` (`$D10C`)

**Platform type 6, the conveyor to the left**

Witness: L1 82 (menu, l51, l59, l98, rzx x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 82 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 32, `stage1/rzx/l75` 13, `stage1/rzx/l40` 6 and 12 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawConveyorLeftPic` |

### `DrawConveyorLeftPic` (`$D112`)

**XOR the picture `$77A8` (10 lines) at `$AB2D` + `$27B0`**

Witness: L1 82 (menu, l51, l59, l98, rzx x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 82 calls (`stage1/rzx/l51` 32, `stage1/rzx/l75` 13, `stage1/rzx/l40` 6 and 12 more) |
| Called from | `PlatDraw6` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `PlatDraw7` (`$D127`)

**Platform type 7, the conveyor to the right**

Witness: L1 89 (menu, l51, l59, l96, l98, rzx x13).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 89 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 40, `stage1/rzx/l75` 7, `stage1/rzx/l36` 6 and 15 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawConveyorRightPic` |

### `DrawConveyorRightPic` (`$D12D`)

**XOR the picture `$77F8` (10 lines) at `$AB2D` + `$27B0`**

Witness: L1 89 (menu, l51, l59, l96, l98, rzx x13).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 89 calls (`stage1/rzx/l51` 40, `stage1/rzx/l75` 7, `stage1/rzx/l36` 6 and 15 more) |
| Called from | `PlatDraw7` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `PlatDraw8` (`$D142`)

**Platform type 8: the plain platform on fire**

Draws the platform, then the flames.

Witness: L1 70 (c1, exitbelow, gameover, menu, twoname, rzx x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 88 t-states own (0.00 %) |
| Runs (the other recordings) | 68 runs of its first instruction, entered by a jump (`stage1/gameover` 12, `stage1/rzx/l59` 12, `stage2/rec/twoname` 12 and 9 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawPlatform1Pic`, `DrawFlames` |

### `DrawFlames` (`$D14B`)

**Mark the cell burning and draw the first flames**

`$AAB3`[`$AA44`] = 1 (AnimateFires `$BBCD` then animates the flames there), and `$814D` is drawn with ink `$C2` at `$AB2D` + `$17B1` (5 lines of 6 bytes).

Witness: L1 78 (c1, exitbelow, fire, gameover, menu, twoname, rzx x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 2 calls, 360 t-states own (0.00 %) |
| Runs (the other recordings) | 76 calls (`stage1/rzx/l59` 16, `stage2/rec/twoname` 12, `stage1/gameover` 12 and 10 more) |
| Called from | `PlatDraw8`, `PlatDraw9` |
| Calls | `CellScreenAddr`, `XorSpriteColoured` |
| Reads | `$AA44` (`BallCell`); `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`); `$AAB6`-`$AAD5` (`CellBurning+3`) |

### `PlatDraw9` (`$D171`)

**Platform type 9: the stopping platform on fire**

Witness: L1 8 (fire, rzx43, rzx59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 runs of its first instruction, entered by a jump (`stage1/rzx/l59` 4, `stage1/rzx/l43` 2, `stage2/rec/fire` 2) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawPlatform5Pic`, `DrawFlames` |

### `PlatDraw10` (`$D17A`)

**Platform type 10, bricks**

Witness: L1 64 (fire, rightspike, l98, rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 64 runs of its first instruction, entered by a jump (`stage1/rzx/l51` 16, `stage1/rzx/l59` 16, `docs/integrate/rec/rightspike` 13 and 6 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawBricks` |

### `DrawBricks` (`$D180`)

**Fill the cell with bricks: the counter 8 and four rows of the brick picture**

`$AAD7`[`$AA44`] = 8 (the brick counter: the moves left and right cannot enter the cell while it is not 0; `$B8D1` counts it down), then `$8345` four times, 8 lines each, `$50` bytes apart, through `$E4BB` with ink `$82`.

Witness: L1 64 (fire, rightspike, l98, rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 64 calls (`stage1/rzx/l51` 16, `stage1/rzx/l59` 16, `docs/integrate/rec/rightspike` 13 and 6 more) |
| Called from | `PlatDraw10` |
| Calls | `CellScreenAddr`, `XorBricksColoured` |
| Reads | `$AA44` (`BallCell`); `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`); `$AADD`-`$AAFA` (`BrickLayers+6`) |

### `PlatDraw12` (`$D1B2`)

**Platform type 12, spikes**

Witness: L1 220 (menu, rightspike, l51, l59, l96, l98, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 220 runs of its first instruction, entered by a jump (`stage1/rzx/l68` 35, `stage1/rzx/l56` 30, `stage1/rzx/l96` 24 and 18 more) |
| Called from | `BuildLevelCell` |
| Calls | `BuildLevelObject` (tail), `DrawSpikesPic` |

### `DrawSpikesPic` (`$D1B8`)

**XOR the spikes `$7D5A` (7 lines, 6 bytes) at `$AB2D` + `$2FB1`**

Witness: L1 220 (menu, rightspike, l51, l59, l96, l98, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 220 calls (`stage1/rzx/l68` 35, `stage1/rzx/l56` 30, `stage1/rzx/l96` 24 and 18 more) |
| Called from | `PlatDraw12` |
| Calls | `XorSprite` |
| Reads | `$AB2D`-`$AB2E` (`CellScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `WallDrawNone` (`$D1CD`)

**Wall type 0: nothing to draw**

Witness: L1 3241 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 72 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 720 t-states own (0.00 %) |
| Runs (the other recordings) | 3,169 runs of its first instruction, entered by a jump (`stage1/gameover` 432, `stage2/rec/twoname` 432, `stage1/menu` 312 and 32 more) |
| Called from | `BuildLevelObject` |
| Calls | `BuildLevelNextCell` (tail) |

### `WallDraw1` (`$D1D0`)

**Wall type 1, the lock that opens with one key**

`$BB1D` gives the wall's address `$AB2F`, then DrawLock1Pic.

Witness: L1 201 (menu, l59, l98, rzx x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 201 runs of its first instruction, entered by a jump (`stage1/rzx/l68` 140, `stage1/rzx/l96` 24, `stage1/rzx/l56` 10 and 10 more) |
| Called from | `BuildLevelObject` |
| Calls | `WallScreenAddr`, `BuildLevelNextCell` (tail), `DrawLock1Pic` |
| Reads | `$AA44` (`BallCell`) |

### `WallDraw2` (`$D1DC`)

**Wall type 2, the lock that takes two keys**

Witness: L1 10 (l98, rzx56, rzx59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 runs of its first instruction, entered by a jump (`stage1/rzx/l56` 5, `stage1/rzx/l59` 4, `stage2/rec/l98` 1) |
| Called from | `BuildLevelObject` |
| Calls | `WallScreenAddr`, `BuildLevelNextCell` (tail), `DrawLock2Pic` |
| Reads | `$AA44` (`BallCell`) |

### `WallDraw3` (`$D1E8`)

**Wall type 3, the lock that takes three keys**

Witness: L1 21 (rzx x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21 runs of its first instruction, entered by a jump (`stage1/rzx/l40` 6, `stage1/rzx/l96` 4, `stage1/rzx/l15` 3 and 4 more) |
| Called from | `BuildLevelObject` |
| Calls | `WallScreenAddr`, `BuildLevelNextCell` (tail), `DrawLock3Pic` |
| Reads | `$AA44` (`BallCell`) |

### `WallDraw4` (`$D1F4`)

**Wall type 4, the wall no key opens**

Witness: L1 178 (fire, menu, rightspike, l51, l59, l98, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 178 runs of its first instruction, entered by a jump (`stage1/rzx/l96` 36, `stage1/rzx/l56` 20, `stage1/rzx/l38` 14 and 15 more) |
| Called from | `BuildLevelObject` |
| Calls | `WallScreenAddr`, `BuildLevelNextCell` (tail), `DrawWall4Pic` |
| Reads | `$AA44` (`BallCell`) |

### `DrawLock1Pic` (`$D200`)

**XOR the lock picture `$7F7C` at the wall**

Witness: L1 356 (menu, l x7, rzx x45).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 356 calls (`stage1/rzx/l68` 148, `stage1/rzx/l96` 26, `stage1/rzx/l79` 15 and 50 more) |
| Called from | `Lock2Step2`, `Lock1Step1`, `WallDraw1` |
| Calls | `DrawWallPic` (tail) |
| Reads | `$AB2F`-`$AB30` (`WallScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `DrawLock2Pic` (`$D205`)

**XOR the lock picture `$7F4C` at the wall**

Witness: L1 72 (l36, l59, l96, l98, rzx x26).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 72 calls (`stage1/rzx/l56` 5, `stage1/rzx/l16` 4, `stage1/rzx/l41` 4 and 27 more) |
| Called from | `Lock3Step2`, `Lock2Step1`, `WallDraw2` |
| Calls | `DrawWallPic` (tail) |

### `DrawLock3Pic` (`$D20A`)

**XOR the lock picture `$7F1C` at the wall**

Witness: L1 45 (l36, l96, rzx x22).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 45 calls (`stage1/rzx/l40` 6, `stage1/rzx/l96` 5, `stage1/rzx/l43` 4 and 21 more) |
| Called from | `Lock3Step1`, `WallDraw3` |
| Calls | `DrawWallPic` (tail) |
| Reads | `$AB2F`-`$AB30` (`WallScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `DrawWall4Pic` (`$D20F`)

**Draw the wall `$7E5C` with ink `$83` at the wall**

Witness: L1 178 (fire, menu, rightspike, l51, l59, l98, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 178 calls (`stage1/rzx/l96` 36, `stage1/rzx/l56` 20, `stage1/rzx/l38` 14 and 15 more) |
| Called from | `WallDraw4` |
| Reads | `$AB2F`-`$AB30` (`WallScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `DrawLockFlashPic` (`$D216`)

**XOR the flash picture `$7FAC` at the wall (a lock opening)**

Witness: L1 358 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 358 calls (`stage1/rzx/l79` 30, `stage2/rec/l68` 20, `stage1/rzx/l54` 16 and 46 more) |
| Called from | `Lock3Step1`, `Lock3Step2`, `Lock2Step1`, `Lock2Step2`, `Lock1Step1`, `Lock1Step2` |
| Calls | `DrawWallPic` (falls into) |

### `DrawWallPic` (`$D21B`)

**XOR the picture DE at the wall's address `$AB2F`: 2 bytes wide, 24 lines**

Witness: L1 831 (menu, l x7, rzx x47).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 825 calls (`stage1/rzx/l68` 164, `stage1/rzx/l79` 45, `stage1/rzx/l96` 39 and 49 more) |
| Called from | `DrawLock1Pic` (tail), `DrawLock2Pic` (tail), `DrawLock3Pic` (tail), `DrawLockFlashPic` (falls into) |
| Calls | `XorSpriteColoured`, `XorSprite` |
| Reads | `$AB2F`-`$AB30` (`WallScrAddr`) |
| Writes | `$A9FE` (`SpriteWidth`) |

### `DrawWall4Frame0` (`$D237`)

**Store the wall-4 frame `$7E5C` at the wall (never called)**

With DrawWall4Frame1-3 an animation of the wall of type 4 drawn by store (`$E318`), not XOR: the frames `$7E5C`, `$7E8C`, `$7EBC`, `$7EEC` (48 bytes, 24 lines of 2 bytes). Nothing calls them; the game animates that wall with `$BC30`. Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawWall4Frame1` (`$D23C`)

**Store the frame `$7E8C` (never called)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawWall4Frame2` (`$D241`)

**Store the frame `$7EBC` (never called)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawWall4Frame3` (`$D246`)

**Store the frame `$7EEC` (never called)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StoreWallPic` (`$D24B`)

**Store the picture HL at the wall's address `$AB2F`, 2 bytes wide, 24 lines (never called)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

## hud

`src/game/hud.asm`

### `PaintHudAttrs` (`$B6EE`)

**Repaint the attributes of the HUD row and of column 30**

Copies the 20 bytes of HudRowAttrs `$B730` to the top attribute row from `$5803`, in groups of 5, 3, 3, 3, 3 and 3 with one or two cells skipped between them (the cells between the HUD's fields keep their colour), then writes 6 (yellow on black) down column 30 (`$581E`, 24 rows). Called by `$E58B` every frame, so whatever the CPC-style drawing leaves in those cells is put right once a frame.

Witness: L1 97366 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,866 calls, 4,890,178 t-states own (0.38 %) |
| Runs (the other recordings) | 93,500 calls (`stage1/menu` 5,761, `stage1/rzx/l46` 2,795, `stage1/rzx/l18` 2,119 and 116 more) |
| Called from | `DrawHud` |
| Reads | `$B730`-`$B743` (`HudRowAttrs`) |
| Writes | `$5803`-`$5A3E` (screen); `$5A5E` (screen); `$5A7E` (screen); `$5A9E` (screen); `$5ABE` (screen); `$5ADE` (screen); 1 more ranges |

### `TickTimer` (`$B7D1`)

**Count the level timer down by one pass of MainLoop, stopping at 0**

The level timer `$AB04` (a word, 1000 = `$03E8` at each level start, `$AC06`) goes down by one each pass of MainLoop (`$ACE4`) and stops at 0. Nothing here acts on 0: the timer only sets the bonus the level end (`$B35F`) adds to the score. A pass that takes two frames counts once, so 1000 is 1000 passes, 20 to 40 seconds.

Witness: L1 93414 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 270,313 t-states own (0.02 %) |
| Runs (the other recordings) | 89,573 calls (`stage1/menu` 5,721, `stage1/rzx/l46` 2,776, `stage1/rzx/l18` 2,099 and 116 more) |
| Called from | `MainLoop` |
| Reads | `$AB04`-`$AB05` (`Timer`) |
| Writes | `$AB04`-`$AB05` (`Timer`) |

### `SelfDestruct` (`$BA71`)

**The S key: burst the ball**

Jumped to from the state handlers (`$AE7F`, `$AEF6`, `$AF70`, `$AFF0`, `$B085`, `$B133`) when the key `$31` (S) is down. It also tests DemoFlag `$ABA6` and jumps back to MainLoop `$ACC8` when it is set, a test its callers have already made (each tests S only when `$ABA6` is 0): dead code. With `$ADDD` not 0 (never: `$ADDF` is a RET before the store that would set it) a disabled level select runs: FirmwareStub5 `$B754`, then Level = L reduced below 100 by steps of 97. Then the death sound `$F4CB` and LoseLife.

Witness: L1 15 (gameover, scoreloop, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 calls (`stage1/gameover` 6, `stage2/rec/twoname` 6, `docs/integrate/rec/scoreloop` 3) |
| Called from | `BallBounceMove` (tail), `BallUpMove` (tail), `BallDownMove` (tail) |
| Calls | `SfxLifeLost` |
| Reads | `$AAFB`-`$AB16` (`Score`, `Water`, `Keys`, `Hammers` and 10 more); `$ABA6` (`DemoFlag`); `$ADDB`-`$ADDD` (`CurrentPlayer`, `PlayerCount`, `CheatMode`) |
| Writes | `$AAFD`-`$AB16` (`Water`, `Keys`, `Hammers`, `Level` and 9 more); `$ADDB` (`CurrentPlayer`) |

### `LoseLife` (`$BA93`)

**The ball is lost: one life less, the level restarts (or game over, or the other player)**

Lives `$AB01` = 0: GameOver `$B755`. Else lives - 1; Water, Keys and Hammers go back to their values at the level start (`$AB06-$AB08`); the 7 bytes score, water, keys, hammers, level and lives (`$AAFB-$AB01`) are saved in the player's record (`$AB09` player 1, `$AB10` player 2, by `$ADDB`). With two players (`$ADDC` = 2) the turn passes to the other player unless his record's lives byte is `$FA` (out): `$ADDB` = 1 or 2. Then 50 frames (WaitOneFrame), WaitKeyOrSecond, and JP `$ABD8`, which starts the level of the player whose turn it is. Entered from the burst death (`$B1D1`), the fall below the screen (`$B2B5`) and SelfDestruct. The score is not touched and LifeStart rebuilds the level with all its prizes and its bottle, so the bottle, the prizes and S give points again for no life: docs/integrate/rec/scoreloop (level 87, three rounds of the RZX's first 330 passes and S: score + 90, lives 16 → 17 → 16 each round). The turn change ran in twoname. The rzx runs are replays that drift from the RZX; the RZX itself never loses a life (lives only rise, work/stage2/rzx-states.tsv).

Witness: L1 38 (fire, gameover, rightspike, scoreloop, twoname, rzx x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage1/rzx/l51` 4, `stage1/rzx/l56` 3, `stage1/rzx/l68` 3 and 10 more) |
| Called from | `BurstEnd` (tail), `LostStep5` (tail) |
| Calls | `GameOver` (tail), `SwitchToPlayer2` (falls into), `LoseLifeWait` (tail) |
| Reads | `$AAFB`-`$AB08` (`Score`, `Water`, `Keys`, `Hammers` and 8 more); `$ADDB`-`$ADDC` (`CurrentPlayer`, `PlayerCount`) |
| Writes | `$AAFD`-`$AB0F` (`Water`, `Keys`, `Hammers`, `Level` and 8 more) |

### `SwitchToPlayer2` (`$BAF1`)

**SwitchToPlayer2**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/twoname` 3) |
| Called from | `GameOver` (tail), `LoseLife` (falls into) |
| Calls | `LoseLifeWait` (falls into) |
| Writes | `$ADDB` (`CurrentPlayer`) |

### `LoseLifeWait` (`$BAF6`)

**LoseLifeWait**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage2/rec/twoname` 5) |
| Called from | `LoseLife` (tail), `SwitchToPlayer2` (falls into) |
| Calls | `LifeStart` (tail), `WaitKeyOrSecond`, `WaitOneFrame` |

### `DrawHud` (`$E58B`)

**Redraw the whole status line**

Calls `$B6EE`, then ScoreToHud, LivesToHud, HammersToHud, WaterToHud, KeysToHud and LevelToHud. Called from the main loop (`$ACB0`, `$ACC2`) and the frame wait (`$B6E6`).

Witness: L1 97366 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

[Animation: `DrawHud` at work](img/routines/DrawHud.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,866 calls, 627,161 t-states own (0.05 %) |
| Runs (the other recordings) | 93,500 calls (`stage1/menu` 5,761, `stage1/rzx/l46` 2,795, `stage1/rzx/l18` 2,119 and 116 more) |
| Called from | `LifeStart`, `WaitFrame` |
| Calls | `PaintHudAttrs`, `ScoreToHud`, `LivesToHud`, `WaterToHud`, `KeysToHud`, `HammersToHud`, `LevelToHud` |

### `ScoreToHud` (`$E5A1`)

**Print the score: five digits at column 3**

The score word `$AAFB` as five digits (PrintNumber5), columns 3-7.

Witness: L1 98075 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,867 calls, 272,312 t-states own (0.02 %) |
| Runs (the other recordings) | 94,208 calls (`stage1/menu` 5,765, `stage1/rzx/l46` 2,801, `stage1/rzx/l18` 2,124 and 116 more) |
| Called from | `AddScore`, `DrawHud` |
| Calls | `PrintNumber5` |
| Reads | `$AAFB`-`$AAFC` (`Score`) |
| Writes | `$AB18` (`HudColumn`) |

### `LivesToHud` (`$E5AD`)

**Print the lives: icon 123 and two digits at column 9**

Icon character `$7B` at column 9, then the low byte of `$AB01` as two digits (PrintNumber2).

Witness: L1 97389 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,866 calls, 403,293 t-states own (0.03 %) |
| Runs (the other recordings) | 93,523 calls (`stage1/menu` 5,762, `stage1/rzx/l46` 2,795, `stage1/rzx/l18` 2,119 and 116 more) |
| Called from | `TakeBottle` (tail), `DrawHud` |
| Calls | `PrintNumber2`, `PrintHudIcon` |
| Reads | `$AB01`-`$AB02` (`Lives`, `AfterLives`) |
| Writes | `$AB18` (`HudColumn`) |

### `WaterToHud` (`$E5C0`)

**Print the water drops: icon 124 and two digits at column 14**

Icon `$7C` at column 14, then the byte `$AAFD` as two digits.

Witness: L1 97487 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,867 calls, 391,024 t-states own (0.03 %) |
| Runs (the other recordings) | 93,620 calls (`stage1/menu` 5,765, `stage1/rzx/l46` 2,795, `stage1/rzx/l18` 2,119 and 116 more) |
| Called from | `TakeWater` (tail), `LeftStep9`, `RightStep9`, `DownStep0`, `DrawHud` |
| Calls | `PrintNumber2`, `PrintHudIcon` |
| Reads | `$AAFD`-`$AAFE` (`Water`, `Keys`) |
| Writes | `$AB18` (`HudColumn`) |

### `KeysToHud` (`$E5D3`)

**Print the keys: icon 125 and two digits at column 18**

Icon `$7D` at column 18, then the byte `$AAFE` as two digits.

Witness: L1 97749 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,867 calls, 393,729 t-states own (0.03 %) |
| Runs (the other recordings) | 93,882 calls (`stage1/menu` 5,764, `stage1/rzx/l46` 2,804, `stage1/rzx/l18` 2,132 and 116 more) |
| Called from | `TakeKey` (tail), `LeftStep5`, `RightStep5`, `DrawHud` |
| Calls | `PrintNumber2`, `PrintHudIcon` |
| Reads | `$AAFE`-`$AAFF` (`Keys`, `Hammers`) |
| Writes | `$AB18` (`HudColumn`) |

### `HammersToHud` (`$E5E6`)

**Print the hammers: icon 126 and two digits at column 22**

Icon `$7E` at column 22, then the byte `$AAFF` as two digits.

Witness: L1 97481 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,866 calls, 392,135 t-states own (0.03 %) |
| Runs (the other recordings) | 93,615 calls (`stage1/menu` 5,761, `stage1/rzx/l46` 2,805, `stage1/rzx/l18` 2,124 and 116 more) |
| Called from | `HitBrick`, `TakeHammer` (tail), `DrawHud` |
| Calls | `PrintNumber2`, `PrintHudIcon` |
| Reads | `$AAFF`-`$AB00` (`Hammers`, `Level`) |
| Writes | `$AB18` (`HudColumn`) |

### `LevelToHud` (`$E5F9`)

**Print the level: icon 127 and two digits at column 26**

Icon `$7F` at column 26, then Level `$AB00` as two digits: the number shown is the level's index 0-99 as stored.

Witness: L1 97368 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,866 calls, 394,626 t-states own (0.03 %) |
| Runs (the other recordings) | 93,502 calls (`stage1/menu` 5,761, `stage1/rzx/l46` 2,795, `stage1/rzx/l18` 2,119 and 116 more) |
| Called from | `DrawHud` |
| Calls | `PrintNumber2`, `PrintHudIcon` |
| Reads | `$AB00`-`$AB01` (`Level`, `Lives`) |
| Writes | `$AB18` (`HudColumn`) |

### `PrintNumber5` (`$E60C`)

**Print HL as five decimal digits**

PrintDigit for 10000, 1000 and 100, then falls into PrintNumber2. Also called by `$B37A` (the score while the timer is counted in).

Witness: L1 103615 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,867 calls, 340,941 t-states own (0.03 %) |
| Runs (the other recordings) | 99,748 calls (`stage1/menu` 5,980, `stage1/rzx/l46` 2,801, `stage1/rzx/l18` 2,124 and 116 more) |
| Called from | `LevelEnd`, `ScoreToHud` |
| Calls | `PrintDigit` |

### `PrintNumber2` (`$E61E`)

**Print HL's tens and units**

PrintDigit for 10 and 1. A value of 100 or more gives a tens "digit" past 9 (the glyph after "9"); the callers pass bytes below 100 (known only from the code).

Witness: L1 591091 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 19,332 calls, 1,722,870 t-states own (0.14 %) |
| Runs (the other recordings) | 468,144 calls (`stage1/menu` 28,813, `stage1/rzx/l46` 13,994, `stage1/rzx/l18` 10,613 and 116 more) |
| Called from | `LivesToHud`, `WaterToHud`, `KeysToHud`, `HammersToHud`, `LevelToHud` |
| Calls | `PrintDigit` |

### `PrintDigit` (`$E62B`)

**Print HL div DE as one digit and keep HL mod DE**

Input: HL the value, DE the power of ten. C counts the subtractions; HL is left with the remainder; the glyph is Font + 8 x (C + 16) (`$F649`, "0"), drawn by PrintHudGlyph.

Witness: L1 1493027 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 57,999 calls, 4,918,317 t-states own (0.39 %) |
| Runs (the other recordings) | 1,435,028 calls (`stage1/menu` 87,526, `stage1/rzx/l46` 41,993, `stage1/rzx/l18` 31,846 and 116 more) |
| Called from | `PrintNumber5`, `PrintNumber2` |
| Calls | `PrintHudGlyph` (falls into) |

### `PrintHudGlyph` (`$E639`)

**Draw glyph C of the table at DE on the status line**

HL = DE + 8 x C, then HudBlit. HL is kept.

Witness: L1 1980501 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 77,331 calls, 39,227,356 t-states own (3.09 %) |
| Runs (the other recordings) | 1,903,170 calls (`stage1/menu` 116,339, `stage1/rzx/l46` 55,987, `stage1/rzx/l18` 42,459 and 116 more) |
| Called from | `PrintDigit` (falls into), `PrintHudIcon` (tail) |
| Calls | `HudBlit` (falls into) |
| Reads | `$AB18` (`HudColumn`); `$B53D`-`$B53E` (`SpectrumLines+16`); `$F649`-`$F697` (`Font+128`); `$F8A1`-`$F8C7` (`Font+728`) |
| Writes | `$4103`-`$411C` (screen); `$4203`-`$421C` (screen); `$4303`-`$431C` (screen); `$4403`-`$441C` (screen); `$4503`-`$451C` (screen); `$4603`-`$461C` (screen); 2 more ranges |

### `HudBlit` (`$E644`)

**Copy glyph rows 0-6 at HL to the status line at column (`$AB18`), then advance the column**

Rows go to screen lines 1-7 (line-table entry 8, `$B53D`, then INC D for each line); glyph row 7 is not drawn. No attribute is written. `$AB18` + 1.

Witness: L1 1980503 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 77,331 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 30,603 calls (`stage1/rzx/l36` 15,915, `stage2/rec/l36` 14,688) |
| Called from | `PrintHudGlyph` (falls into) |
| Reads | `$AB18` (`HudColumn`); `$B53D`-`$B53E` (`SpectrumLines+16`); `$F649`-`$F697` (`Font+128`); `$F8A1`-`$F8C7` (`Font+728`) |
| Writes | `$4103`-`$411C` (screen); `$4203`-`$421C` (screen); `$4303`-`$431C` (screen); `$4403`-`$441C` (screen); `$4503`-`$451C` (screen); `$4603`-`$461C` (screen); 2 more ranges |

### `PrintHudIcon` (`$E661`)

**Draw character A of the font on the status line**

DE = `$F4C9` (Font - 256, so that 8 x A lands on the character), C = A, then PrintHudGlyph.

Witness: L1 487474 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 19,332 calls, 502,632 t-states own (0.04 %) |
| Runs (the other recordings) | 468,142 calls (`stage1/menu` 28,813, `stage1/rzx/l46` 13,994, `stage1/rzx/l18` 10,613 and 116 more) |
| Called from | `LivesToHud`, `WaterToHud`, `KeysToHud`, `HammersToHud`, `LevelToHud` |
| Calls | `PrintHudGlyph` (tail) |

## hiscore

`src/game/hiscore.asm`

### `GameOver` (`$B755`)

**A player has lost his last ball: hall of fame, mark him out, hand over or end the game**

Entered from LoseLife `$BA93` when the lives (`$AB01`) are 0. IX = the record of the player in play: `$AB09` for player 1 (`$ADDB` = 1), `$AB10` for player 2. When the score (`$AAFB`) is not below the lowest hall of fame score (the word at `$EF25`), NameEntry `$EC40` runs. Then the record's lives byte (IX+6) is set to `$FA`, the mark of a player out of the game.

One player (`$ADDC` = 1), or the other player already out (`$FA` in his record): GameOverPause `$B7A9` and back to the menu. Otherwise the game passes to the other player through LoseLife's hand-over (`$BADF` or `$BAF1`). Witness: the game-over recording (stage1/gameover) ends here; the RZX never loses its last life; the two-player branches ran in stage2/rec/twoname (both players to the end: player 1 out, the hand-over `$BADF`/`$BAF1` to player 2, then the menu).

Witness: L1 4 (gameover, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage2/rec/twoname` 2, `stage1/gameover` 2) |
| Called from | `LoseLife` (tail) |
| Calls | `SwitchToPlayer2` (tail), `EnterHallOfFame` |
| Reads | `$AAFB`-`$AAFC` (`Score`); `$AB0F`-`$AB16` (`Player1Record+6`, `Player2Record`); `$ADDB`-`$ADDC` (`CurrentPlayer`, `PlayerCount`); `$EF25`-`$EF26` (`HallOfFame+114`) |
| Writes | `$AB0F`-`$AB16` (`Player1Record+6`, `Player2Record`) |

### `GameOverPause` (`$B7A9`)

**Wait about 2.5 seconds, then back to the menu**

Twenty times GameOverDelay `$C4D5` (each about 40 000 delay loops and a frame), then BackToMenu `$B7B2`. Entered from GameOver `$B755` and from the end of the demo (`$B3A8`).

Witness: L1 3 (gameover, menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `LevelEnd` (tail) |
| Calls | `BackToMenu` (falls into), `GameOverDelay` |

### `BackToMenu` (`$B7B2`)

**Wait up to a second for a key, then restart at the menu**

WaitKeyOrSecond `$B7B8`, then JP `$AB7D` (the menu and a new game). Entered from GameOverPause and from MainLoop when the quit key (`$2B`, see `$ACEC`) is down.

Witness: L1 6 (gameover, menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/menu` 4) |
| Called from | `MainLoop` (tail), `GameOverPause` (falls into) |
| Calls | `GameRestart` (tail), `WaitKeyOrSecond` |

### `GameOverDelay` (`$C4D5`)

**Two Delay(200) and a frame: about 2 × 130 000 T-states**

Called 20 times by GameOverPause `$B7A9`.

Witness: L1 60 (gameover, menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 60 calls (`stage2/rec/twoname` 20, `stage1/gameover` 20, `stage1/menu` 20) |
| Called from | `GameOverPause` |
| Calls | `Delay` |
| Reads | `$C4E1` (`GameOverDelay+12`) |

### `EnterHallOfFame` (`$EC40`)

**Game over: flash the border, put the score in the hall of fame and enter the name**

Called by the game over `$B777`. 250 x 8 border colours 7..0 with a delay (`$B873`, B = 2) between them. Then the place: the score `$AAFB` is compared with the scores (+`$12`) of records 1-3 only; at the first lower one, the records from there down to the third move one down (LDDR `$EF12` to `$EF32`, `$60` - 32 x place bytes) and the score goes in its place. A score below all three goes to record 4 without a compare (GameOver called this routine only because the score is not below record 4's, `$EF25`). In the gameover recording the score went to record 4 and the move at `$EC8E` never ran.

The record gets the score, the name "..." (`$2E`), its digits (ScoreToDigits); then ShowHallOfFame and EnterName. Output: (`$ED93`) = the record.

Witness: L1 3 (gameover, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/twoname` 2, `stage1/gameover` 1) |
| Called from | `GameOver` |
| Calls | `Delay`, `EnterName`, `ShowHallOfFame`, `ScoreToDigits` |
| Reads | `$AAFB`-`$AAFC` (`Score`); `$EEC5`-`$EEC6` (`HallOfFame+18`); `$EEE5`-`$EEE6` (`HallOfFame+50`); `$EF05`-`$EF06` (`HallOfFame+82`) |
| Writes | `$ED93`-`$ED94` (`NewRecordPtr`); `$EF19`-`$EF26` (`HallOfFame+102`) |
| Ports out | `$00FE`, `$01FE`, `$02FE`, `$03FE`, `$04FE`, `$05FE`, `$06FE`, `$07FE` |

### `EnterName` (`$ECC0`)

**The name entry: three letters, chosen by left and right, each confirmed by fire or up**

Waits for all keys up (`$B401`). For each of the three letters at record +6: the letter starts at "@" (`$40`); right (`$F087`, `$B44E`) steps it up and left (`$F086`, `$B447`) down; right wraps from "Y" to "@" (INC, CP `$5A`, JR C), left from "@" to "Z", so "Z" is reached only by left; fire or up (`$F088` / `$F084`, `$B463`) waits for the keys up and goes to the next letter. The table is reprinted (PrintHallOfFame) after each test and 5 HALTs (0.1 s) pass. In the gameover recording no key was pressed: 394 rounds on the first letter. In stage2/rec/twoname both players typed their names (B U M by right, left and fire, then Z A P with Z by left from "@"): the polling once every 5 HALTs is why a 4-frame tap can be missed.

Witness: L1 3 (gameover, twoname).

[Animation: `EnterName` at work](img/routines/EnterName.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/twoname` 2, `stage1/gameover` 1) |
| Called from | `EnterHallOfFame` |
| Calls | `WaitRelease`, `TestLeft`, `TestRight`, `TestUpOrFire`, `PrintHallOfFame` |
| Reads | `$ED00`-`$ED19` (`EnterNameSkip4+5`, `NameLetterPtr`); `$ED93`-`$ED94` (`NewRecordPtr`); `$EF19`-`$EF1B` (`HallOfFame+102`) |
| Writes | `$ED18`-`$ED19` (`NameLetterPtr`); `$EF19`-`$EF1B` (`HallOfFame+102`) |

### `ShowHallOfFame` (`$ED1A`)

**Clear the screen and draw the hall of fame: the lines, the title and the four records**

Border 0, ClearScreen `$F0CB`, DrawHofLines, PrintText HofTitleText `$EDEF`, PrintHallOfFame.

Witness: L1 4 (gameover, menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage2/rec/twoname` 2, `stage1/gameover` 1, `stage1/menu` 1) |
| Called from | `EnterHallOfFame`, `MenuShowHallOfFame` |
| Calls | `PrintText`, `PrintHallOfFame`, `DrawHofLines`, `ClearScreen` |
| Ports out | `$00FE` |

### `PrintHallOfFame` (`$ED2D`)

**Print the four records at rows 7, 10, 13 and 16**

Each record's row byte (+1) is set (7, 10, 13, 16), then PrintText.

Witness: L1 714 (gameover, menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 714 calls (`stage1/gameover` 395, `stage2/rec/twoname` 318, `stage1/menu` 1) |
| Called from | `EnterName`, `ShowHallOfFame` |
| Calls | `PrintText` |
| Writes | `$EEB4` (`HallOfFame+1`); `$EED4` (`HallOfFame+33`); `$EEF4` (`HallOfFame+65`); `$EF14` (`HallOfFame+97`) |

### `ScoreToDigits` (`$ED4C`)

**Write the new record's score (+`$12`) as five ASCII digits at +`$0C-$10`**

The record from (`$ED93`).

Witness: L1 3 (gameover, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/twoname` 2, `stage1/gameover` 1) |
| Called from | `EnterHallOfFame` |
| Calls | `DigitOf` |
| Reads | `$ED93`-`$ED94` (`NewRecordPtr`); `$EF25`-`$EF26` (`HallOfFame+114`) |
| Writes | `$EF1F`-`$EF23` (`HallOfFame+108`) |

### `DigitOf` (`$ED84`)

**A = "0" + HL div DE; HL = HL mod DE**

Witness: L1 15 (gameover, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 calls (`stage2/rec/twoname` 10, `stage1/gameover` 5) |
| Called from | `ScoreToDigits` |

### `DrawHofLines` (`$ED95`)

**Draw the hall of fame's perspective lines at the top and the bottom of the screen**

For each row n of HofLineRows (to `$FF`): screen line n gets 31 bytes of `$88` (dotted) and line n + 1 of `$FF` (solid) from column 0; line 192 - n gets `$FF` and the next `$88`: the lines draw closer towards the middle of the screen.

Witness: L1 4 (gameover, menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage2/rec/twoname` 2, `stage1/gameover` 1, `stage1/menu` 1) |
| Called from | `ShowHallOfFame` |
| Calls | `DrawLinePair` |
| Reads | `$EDE1`-`$EDEE` (`HofLineRows`) |

### `DrawLinePair` (`$EDC9`)

**Fill the line at the table entry HL with C and the next line with B**

Witness: L1 104 (gameover, menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 104 calls (`stage2/rec/twoname` 52, `stage1/gameover` 26, `stage1/menu` 26) |
| Called from | `DrawHofLines` |
| Calls | `FillLine` (falls into) |

### `FillLine` (`$EDD4`)

**Fill 31 bytes of the screen line whose address is at (HL) with A**

Witness: L1 208 (gameover, menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 208 calls (`stage2/rec/twoname` 104, `stage1/gameover` 52, `stage1/menu` 52) |
| Called from | `DrawLinePair` (falls into) |
| Reads | `$4000`-`$431D` (screen); `$4420`-`$479D` (screen); `$4860`-`$4A3D` (screen); `$4AA0`-`$4ABD` (screen); `$4F40`-`$551D` (screen); `$55C0`-`$55DD` (screen); 10 more ranges |
| Writes | `$4000`-`$431E` (screen); `$4420`-`$479E` (screen); `$4860`-`$4ABE` (screen); `$4F40`-`$55DE` (screen); `$56E0`-`$57FE` (screen); `$FCE0`-`$FCFE` (`work space $FCE0+`) |

## objects

`src/game/objects.asm`

### `TakeObject` (`$B958`)

**Take the object in the ball's cell, if any**

Kind = `$AB1D` (ReadCell `$BB32`). 0: nothing. Else erases the object's sprite (ObjectSprites `$6CB0` + 56 × kind, 4 bytes × 14 rows, XOR at the cell's screen address `$AB2D` - `$9E`, DrawSpriteXorInk `$E3E5` with colour 7), clears ObjectCells `$AA47`[cell], and for kinds 1-4 jumps through ObjectHandlers `$BA3D`. Kinds 5 and up are prizes: the pick-up sound `$F3F6` (skipped once after a long sound, `$ABA7` = 4), then AddScore `$BA47` with 15. Called by the landing handlers (`$C811`, `$CA46`, `$CC89`, `$CDF9`, `$CEC6`). Witness: 936 objects taken in the recordings, 625 prizes.

Witness: L1 8264 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 252 calls, 13,150 t-states own (0.00 %) |
| Runs (the other recordings) | 8,012 calls (`stage1/menu` 382, `stage1/rzx/l46` 316, `stage1/rzx/l38` 206 and 116 more) |
| Called from | `BounceStep13`, `LeftStep13`, `RightStep13`, `UpStep6`, `DownStep5` |
| Calls | `TakeKey`, `TakeWater`, `TakeHammer`, `TakeBottle`, `AddScore` (tail), `XorSpriteColoured`, `SfxPickup` |
| Reads | `$AA44` (`BallCell`); `$AB1D`-`$AB2E` (`CellObject`, `CellWall`, `Unused5`, `CrumbleNewType` and 9 more); `$ABA7` (`ObjectFlag`); `$BA3F`-`$BA46` (`ObjectHandlers+2`) |
| Writes | `$A9FE` (`SpriteWidth`); `$AA47`-`$AA6A` (`CellObjects`) |

### `TakeNothing` (`$B9BE`)

**ObjectHandlers[0]: RET (kind 0 is no object, filtered out before)**

Never run: TakeObject returns on kind 0 before the jump.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TakeKey` (`$B9BF`)

**Kind 2, a key: Keys + 1 (at most 99) and the HUD**

The pick-up sound `$F3F6` unless `$ABA7` = 4 (then `$ABA7` = 0), Keys `$AAFE` + 1 unless 99, then JP `$E5D3` (print the keys). Witness: 183 keys.

Witness: L1 204 (c1, menu, l x9, rzx x60).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 100 t-states own (0.00 %) |
| Runs (the other recordings) | 203 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 8, `stage1/rzx/l99` 7, `stage1/rzx/l37` 6 and 67 more) |
| Called from | `TakeObject` |
| Calls | `KeysToHud` (tail), `SfxPickup` |
| Reads | `$AAFE` (`Keys`); `$ABA7` (`ObjectFlag`) |
| Writes | `$AAFE` (`Keys`) |

### `TakeWater` (`$B9DE`)

**Kind 3, a water drop: Water + 1 (at most 99) and the HUD**

As TakeKey with Water `$AAFD` and `$E5C0`. Witness: 54 drops.

Witness: L1 66 (c1, gameover, menu, twoname, l x5, rzx x29).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 100 t-states own (0.00 %) |
| Runs (the other recordings) | 65 runs of its first instruction, entered by a jump (`stage1/rzx/l78` 6, `stage1/rzx/l88` 4, `stage1/menu` 3 and 34 more) |
| Called from | `TakeObject` |
| Calls | `WaterToHud` (tail), `SfxPickup` |
| Reads | `$AAFD` (`Water`); `$ABA7` (`ObjectFlag`) |
| Writes | `$AAFD` (`Water`) |

### `TakeHammer` (`$B9FD`)

**Kind 1, a hammer: Hammers + 1 (at most 99) and the HUD**

As TakeKey with Hammers `$AAFF` and `$E5E6`. Witness: 58 hammers.

Witness: L1 63 (l x5, rzx x38).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 63 runs of its first instruction, entered by a jump (`stage1/rzx/l18` 5, `stage1/rzx/l02` 4, `stage1/rzx/l46` 3 and 40 more) |
| Called from | `TakeObject` |
| Calls | `HammersToHud` (tail), `SfxPickup` |
| Reads | `$AAFF` (`Hammers`); `$ABA7` (`ObjectFlag`) |
| Writes | `$AAFF` (`Hammers`) |

### `TakeBottle` (`$BA1C`)

**Kind 4, the bottle: an extra life**

`$ABA7` = 4 (the next pick-up is silent), the sound `$F40D`, FirmwareStub `$B747` with B = C = 26 (a dropped CPC border flash), `$AB17` = 1 (BottleFlashOff undoes it next frame), lives `$AB01` + 1 unless 99, then JP `$E5AD` (print the lives). The only way to gain a life: 15 bottles in the RZX and one in the menu recording's demo, each one life.

Witness: L1 23 (menu, scoreloop, l10, l36, l45, l68, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 runs of its first instruction, entered by a jump (`docs/integrate/rec/scoreloop` 3, `stage1/menu` 1, `stage1/rzx/l05` 1 and 18 more) |
| Called from | `TakeObject` |
| Calls | `FirmwareStub`, `LivesToHud` (tail), `SfxExtraLife` |
| Reads | `$AB01` (`Lives`) |
| Writes | `$AB01` (`Lives`); `$AB17` (`BorderFlash`); `$ABA7` (`ObjectFlag`) |

### `AddScore` (`$BA47`)

**Add BC to the score, print it, and count a prize off**

Score `$AAFB` += BC, PrintScore `$E5A1`, PrizesLeft `$AA45` - 1 and OpenExit `$BCB9` when it reaches 0. Only prizes come here (BC = 15).

Witness: L1 709 (c1, exitbelow, menu, scoreloop, l x12, rzx00-rzx44, rzx46-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 135 t-states own (0.00 %) |
| Runs (the other recordings) | 708 calls (`stage1/rzx/l23` 32, `stage1/rzx/l52` 18, `docs/integrate/rec/scoreloop` 18 and 111 more) |
| Called from | `TakeObject` (tail) |
| Calls | `OpenExit`, `ScoreToHud` |
| Reads | `$AA45` (`PrizesLeft`); `$AAFB`-`$AAFC` (`Score`) |
| Writes | `$AA45` (`PrizesLeft`); `$AAFB`-`$AAFC` (`Score`) |

### `BottleFlashOff` (`$BA60`)

**The frame after a bottle: undo the border flash**

When `$AB17` is set: clears it and calls FirmwareStub `$B747` with B = C = 0 (a CPC border back to black; a RET here). Called by MainLoop (`$ACE7`) every frame.

Witness: L1 93414 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 141,011 t-states own (0.01 %) |
| Runs (the other recordings) | 89,573 calls (`stage1/menu` 5,721, `stage1/rzx/l46` 2,776, `stage1/rzx/l18` 2,099 and 116 more) |
| Called from | `MainLoop` |
| Calls | `FirmwareStub` |
| Reads | `$AB17` (`BorderFlash`) |
| Writes | `$AB17` (`BorderFlash`) |

### `OpenExit` (`$BCB9`)

**The last prize is taken: the exit cell becomes platform `$0B` and is drawn open**

The exit cell is `$AA46` (from the level). PlatformCells[`$AA46`] = `$0B`; `$AB2D` = its screen address; the blank `$6708` is stored at +`$27B0` (8 bytes × 10 rows), the sprite `$80CC` at +`$2FB0` and +`$2FB7` (1 byte × 9 rows each, the two posts), then the exit animation is armed: `$AA10` = the address + 1, `$AA12` = 1 (AnimateExit). Called by AddScore `$BA47`. Witness: 92 exits opened in the recordings.

Witness: L1 105 (exitbelow, menu, l x12, rzx x91).

[Animation: `OpenExit` at work](img/routines/OpenExit.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 105 calls (`docs/integrate/rec/exitbelow` 1, `stage1/menu` 1, `stage1/rzx/l00` 1 and 102 more) |
| Called from | `AddScore` |
| Calls | `DrawSprite` |
| Reads | `$AA46` (`ExitCell`); `$AB2D`-`$AB2E` (`CellScrAddr`); `$E131`-`$E178` (`CellAddresses`) |
| Writes | `$A9FE` (`SpriteWidth`); `$AA10`-`$AA12` (`ExitAnimAddr`, `ExitOpen`); `$AA6B`-`$AA8E` (`CellPlatforms`); `$AB2D`-`$AB2E` (`CellScrAddr`) |

### `AnimateExit` (`$BD21`)

**Every 2 frames, the next frame of the open exit**

When `$AA12` is set: `$AA0E` counts frames, at 2 NextExitFrame `$BD5C` steps `$AA0F` (1-4) and the frame ExitFrameTable `$C522`[frame - 1] (6 bytes × 5 rows, colour `$5E`) is stored at `$AA10`. Called by MainLoop (`$ACE1`) and the level end (`$B32B`).

Witness: L1 94332 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 3,841 calls, 144,627 t-states own (0.01 %) |
| Runs (the other recordings) | 90,491 calls (`stage1/menu` 5,730, `stage1/rzx/l46` 2,785, `stage1/rzx/l18` 2,108 and 116 more) |
| Called from | `MainLoop`, `LevelEnd` |
| Calls | `NextExitFrame`, `DrawSpriteColoured` |
| Reads | `$AA0E`-`$AA12` (`ExitTick`, `ExitFrame`, `ExitAnimAddr`, `ExitOpen`); `$C522`-`$C529` (`ExitFrameTable`) |
| Writes | `$A9FE`-`$AA0E` (`SpriteWidth`, `BallStep`, `BallState`, `BallSprite` and 8 more) |

### `NextExitFrame` (`$BD5C`)

**`$AA0E` = 0; the exit frame `$AA0F` steps 1, 2, 3, 4, 1 ...**

Witness: L1 6714 (exitbelow, menu, l x12, rzx x91).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,714 calls (`stage1/rzx/l21` 222, `stage1/rzx/l00` 194, `stage1/rzx/l80` 179 and 102 more) |
| Called from | `AnimateExit` |
| Reads | `$AA0F` (`ExitFrame`) |
| Writes | `$AA0E`-`$AA0F` (`ExitTick`, `ExitFrame`) |

## sprites

`src/game/sprites.asm`

### `DrawSpriteColoured` (`$E2A0`)

**Draw a sprite (store) and colour the cells it covers**

DrawSprite `$E318` (DE the CPC screen address, HL the graphics, B the lines, (`$A9FE`) the width in CPC bytes), then PaintAttrs `$E2A3` with the attribute in C.

Witness: L1 89526 (c1, exitbelow, fire, gameover, menu, rightspike, twoname, l x12, rzx00-rzx34, rzx36-rzx44, rzx46-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 960 calls, 20,957 t-states own (0.00 %) |
| Runs (the other recordings) | 88,566 calls (`stage1/rzx/l38` 3,451, `stage2/rec/l96` 2,758, `stage1/menu` 2,379 and 113 more) |
| Called from | `AnimateFires`, `AnimateWalls`, `AnimateExit`, `ExtinguishFire` |
| Calls | `DrawSprite` |

### `PaintAttrs` (`$E2A3`)

**Colour the cells under the sprite just drawn with the attribute C**

Input: C the attribute (bit 7 set: the area is 8 lines taller), the place left by `$C71F` (`$C74F` the CPC character row, `$C750` the CPC byte column), the height in lines at SpriteHeight `$E3E4` and the width at `$A9FE`. Nothing is done when C's ink (bits 0-2) is 0.

The cells are rows (`$C74F` - 1) onwards (a sprite starting in CPC row 0, above the Spectrum screen, loses its first 8 lines), columns `$C750` / 2 onwards, ((width + column bit 0 + 1) / 2) cells wide and (height + 7) / 8 rows high; each gets C (bit 7 cleared), written into the operand of the LD (HL),n at `$E30E` before the loop. Output: the attributes; `$E3E4` and `$C74F` changed.

Witness: L1 278233 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 7,757 calls, 4,695,830 t-states own (0.37 %) |
| Runs (the other recordings) | 180,952 calls (`stage1/menu` 11,613, `stage1/rzx/l46` 5,567, `stage1/rzx/l18` 4,226 and 116 more) |
| Called from | `XorSpriteColoured`, `XorBricksColoured` |
| Reads | `$A9FE` (`SpriteWidth`); `$C74F`-`$C750` (`CharRow`, `ByteColumn`); `$E3E4` (`SpriteHeight`) |
| Writes | `$5801`-`$5AFD` (screen); `$C74F` (`CharRow`); `$E30F` (`PaintAttrsLoop2+1`); `$E3E4` (`SpriteHeight`) |

### `DrawSprite` (`$E318`)

**Draw a CPC sprite on the screen, storing its bytes**

Input: DE the CPC screen address, HL the graphics, B the lines, (`$A9FE`) the width in CPC bytes. B goes to SpriteHeight `$E3E4`. Each line: the Spectrum address from the line table, then width / 2 bytes, each (first byte << 4) | (second byte & `$0F`), and for an odd width a last half byte (first byte << 4). An odd CPC column (`$C750` bit 0) starts with the low nibble of one byte alone and ends with a high-nibble byte when the width is even. Output: carry clear, BC kept; IY kept; the screen bytes stored. Interrupts are off from `$E32A` and on again at the end.

Witness: L1 91594 (c1, exitbelow, fire, gameover, menu, rightspike, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 963 calls, 3,144,801 t-states own (0.25 %) |
| Runs (the other recordings) | 90,631 calls (`stage1/rzx/l38` 3,463, `stage2/rec/l96` 2,788, `stage1/menu` 2,412 and 115 more) |
| Called from | `DrawBurstPicture`, `LevelEnd`, `DrawSides`, `OpenExit`, `StoreWallFrame`, `DrawSpriteColoured`, `DrawLogo` |
| Calls | `LineAddress`, `ScreenAddrToLine` |
| Reads | `$6398`-`$6697` (`SidePanels`, `SidePanelRight`); `$6708`-`$6757` (`BlankPicture`); `$67E8`-`$680B` (`BallPictures`); `$7E5C`-`$7F1B` (`WallPictures`); `$7FDC`-`$81A6` (`WallOpening`, `ExitMark`, `ExitFrames`, `FirePictures`); `$81F5`-`$8344` (`BurstPictures`); 4 more ranges |
| Writes | `$4000`-`$57FE` (screen); `$E3E4` (`SpriteHeight`); `$FCE1`-`$FCFD` (`work space $FCE1+`) |

### `XorSpriteColoured` (`$E3E5`)

**XOR a sprite onto the screen and colour its cells**

XorSprite `$E3EE` (HL the CPC screen address, DE the graphics, B the lines), then PaintAttrs `$E2A3` with C.

Witness: L1 188454 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 7,757 calls, 539,286 t-states own (0.04 %) |
| Runs (the other recordings) | 180,697 calls (`stage1/menu` 11,613, `stage1/rzx/l46` 5,567, `stage1/rzx/l18` 4,226 and 116 more) |
| Called from | `DrawBallXor`, `TakeObject`, `XorWaterDrop`, `Steam1`, `Steam2`, `Steam3`, `Steam4`, `BuildLevelObject`, `DrawFlames`, `DrawWallPic` |
| Calls | `PaintAttrs`, `XorSprite` |

### `XorSprite` (`$E3EE`)

**XOR a CPC sprite onto the screen**

As DrawSprite `$E318`, but the screen address is in HL and the graphics in DE, and each byte is XORed into the screen: drawing twice removes the sprite. The last half byte of an odd width at an even column (`$E442`) never ran: no sprite of odd width is XORed there.

Witness: L1 231120 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 8,191 calls, 36,855,971 t-states own (2.90 %) |
| Runs (the other recordings) | 222,929 calls (`stage1/menu` 12,273, `stage1/rzx/l46` 6,503, `stage1/rzx/l18` 5,322 and 116 more) |
| Called from | `LostStep2`, `LostStep3`, `LostStep4`, `LostStep5`, `SpringPart0`, `SpringPart1`, `SpringPart2`, `SpringPart3`, `TiltPart0`, `TiltPart1`, `TiltPart2`, `XorPlatform2`, `XorCrack2a`, `XorCrack2b`, `XorCrack2c`, `XorPlatform3`, `XorCrack3a`, `XorCrack3b`, `XorCrack3c`, `XorPlatform4`, `XorFall1`, `XorFall2`, `XorFall3`, `XorFall4`, `XorFall5`, `XorFall6`, `XorFall7`, `XorFall8`, `BuildLevelNextCell`, `DrawPlatform3Pic`, `DrawPlatform4Pic`, `DrawPlatformPic`, `DrawConveyorLeftPic`, `DrawConveyorRightPic`, `DrawSpikesPic`, `DrawWallPic`, `XorSpriteColoured` |
| Calls | `LineAddress`, `ScreenAddrToLine` |
| Reads | `$4001`-`$57FD` (screen); `$67E8`-`$6A8F` (`BallPictures`, `BallPictures2`); `$6C20`-`$75A7` (`BallPictures2+440`, `ObjectPictures`); `$7788`-`$7FDB` (`Platform1Pictures`, `Platform2Pictures`, `Platform3Pictures`, `Platform4Pictures` and 8 more); `$814D`-`$81F4` (`FirePictures`, `SteamPictures`, `SteamSmall`); `$A9FE` (`SpriteWidth`); 4 more ranges |
| Writes | `$4001`-`$57FD` (screen); `$AAFB`-`$AAFC` (`Score`); `$E3E4` (`SpriteHeight`); `$FCE1`-`$FCFD` (`work space $FCE1+`) |

### `XorBricksColoured` (`$E4BB`)

**XOR a brick graphic and colour its cells**

XorBricks `$E4C4`, then PaintAttrs `$E2A3` with C. The only caller is the brick drawing at `$D1A6`.

Witness: L1 256 (fire, rightspike, l98, rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 256 calls (`stage1/rzx/l51` 64, `stage1/rzx/l59` 64, `docs/integrate/rec/rightspike` 52 and 6 more) |
| Called from | `DrawBricks` |
| Calls | `PaintAttrs`, `XorBricks` |

### `XorBricks` (`$E4C4`)

**XOR a CPC graphic onto the screen from its high nibbles**

As XorSprite `$E3EE`, but each Spectrum byte is (first byte & `$F0`) | (second byte >> 4): the other bit plane of the CPC graphic. The odd-column path `$E530-$E58A` never ran (the bricks lie at even columns).

Witness: L1 256 (fire, rightspike, l98, rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 256 calls (`stage1/rzx/l51` 64, `stage1/rzx/l59` 64, `docs/integrate/rec/rightspike` 52 and 6 more) |
| Called from | `XorBricksColoured` |
| Calls | `LineAddress`, `ScreenAddrToLine` |
| Reads | `$4081`-`$50DD` (screen); `$50FA`-`$51DD` (screen); `$51FA`-`$52DD` (screen); `$52FA`-`$53DD` (screen); `$53FA`-`$54DD` (screen); `$5501`-`$55DD` (screen); 7 more ranges |
| Writes | `$4081`-`$50DD` (screen); `$50FA`-`$51DD` (screen); `$51FA`-`$52DD` (screen); `$52FA`-`$53DD` (screen); `$53FA`-`$54DD` (screen); `$5501`-`$55DD` (screen); 3 more ranges |

## text

`src/game/text.asm`

### `PrintText` (`$E667`)

**Print the string at HL with its control codes**

Input: HL the string. Reads up to and including `$00`; at the end the attribute goes back to the default (`$E712` to `$E713`) and HL points after the `$00`. `$11` (paper) and `$12` (flash) never ran. `$12` and `$13` cannot set their bit: the ROTATE through carry (`$E6DB`, `$E6EE-$E6F0`) puts the carry left by the CP (always clear) into the bit, so FLASH and BRIGHT are always cleared (known only from the code; the menu's "`$13` 1" at `$F05A` has no effect).

Witness: L1 47004 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

[Animation: `PrintText` at work](img/routines/PrintText.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 6 calls, 81,815 t-states own (0.01 %) |
| Runs (the other recordings) | 2,942 calls (`stage1/gameover` 1,591, `stage2/rec/twoname` 1,284, `stage1/menu` 23 and 32 more) |
| Called from | `LifeStart`, `ShowHallOfFame`, `PrintHallOfFame`, `Menu`, `MenuPrint` |
| Calls | `PrintChar` |
| Reads | `$AD3B`-`$ADBF` (`ReadyText`, `Player1ReadyText`, `Player2ReadyText`, `BlankReadyText`); `$E712`-`$E713` (`TextVars`, `TextAttr`); `$EDEF`-`$EF24` (`HofTitleText`, `HallOfFame`); `$EFEF`-`$F061` (`MenuText`); `$F0E8`-`$F164` (`MenuBackdropText`) |
| Writes | `$E713`-`$E716` (`TextAttr`, `TextDouble`, `TextRow`, `TextColumn`) |

### `PrintChar` (`$E717`)

**Print character A, or act on `$0D` and `$09`**

`$0D`: NewLine; `$09`: NextColumn; codes below 32 or from 128: "?"; else DrawGlyph. HL kept.

Witness: L1 34549 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 377 calls, 41,833 t-states own (0.00 %) |
| Runs (the other recordings) | 34,172 calls (`stage1/gameover` 17,864, `stage2/rec/twoname` 14,719, `stage1/menu` 1,255 and 32 more) |
| Called from | `PrintText` |
| Calls | `DrawGlyph`, `NextColumn` |

### `DrawGlyph` (`$E73E`)

**Draw font character A at TextRow, TextColumn in TextAttr, and move on a column**

The glyph Font + 8 x (A - 32) goes to the 8 lines of the character row (line-table entry 8 x row + 7, `$B53B`); at double height each row is drawn twice, so the character covers the row and the next. Then the attribute TextAttr at the cell (and the cell below at double height), and NextColumn.

Witness: L1 34481 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 377 calls, 751,321 t-states own (0.06 %) |
| Runs (the other recordings) | 34,104 calls (`stage1/gameover` 17,847, `stage2/rec/twoname` 14,685, `stage1/menu` 1,238 and 32 more) |
| Called from | `PrintChar` |
| Calls | `NextColumn` (falls into) |
| Reads | `$B53B`-`$B66A` (`SpectrumLines+14`); `$B67B`-`$B69A` (`SpectrumLines+334`); `$B6AB`-`$B6BA` (`SpectrumLines+382`); `$E713`-`$E716` (`TextAttr`, `TextDouble`, `TextRow`, `TextColumn`); `$F5C9`-`$F5D0` (`Font`); `$F639`-`$F7A0` (`Font+112`); 3 more ranges |
| Writes | `$400B`-`$5A5F` (screen); `$5A84`-`$5ABA` (screen); `$5AE3`-`$5AFB` (screen); `$E716` (`TextColumn`) |

### `NextColumn` (`$E7A9`)

**TextColumn + 1; at 32 a new line**

Witness: L1 34549 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l51, l59, l96, l98, rzx x24).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 377 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 33,838 calls (`stage1/gameover` 17,864, `stage2/rec/twoname` 14,719, `stage1/menu` 1,255) |
| Called from | `PrintChar`, `DrawGlyph` (falls into) |
| Reads | `$E715`-`$E716` (`TextRow`, `TextColumn`) |
| Writes | `$E715`-`$E716` (`TextRow`, `TextColumn`) |

### `NewLine` (`$E7B3`)

**TextColumn 0, TextRow + 1 (24 wraps to 0)**

Witness: L1 49 (menu, twoname).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 49 runs of its first instruction, entered by a jump (`stage2/rec/twoname` 42, `stage1/menu` 7) |

### `PrintOnceUponATime` (`$E7C6`)

**Print the text "Erase Una Vez ..." (never called)**

LD HL,`$E7CD`: CALL PrintText: RET. Nothing in the image calls it and no recording ran it (known only from the code). The text starts with the Amstrad CPC firmware's LOCATE code `$1F` row col, which PrintText does not know: it would print "?" for `$1F` and `$0A`. A leftover of the CPC original or of the Spanish conversion (the menu says "VERSIONED BY J250 <SPAIN>").

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `XorLogo` (`$E7E6`)

**XOR the logo onto the menu screen (never called)**

XorSprite `$E3EE` with HL = `$C066`, DE = Logo, B = 60 lines, width 18: draws the logo of DrawLogo `$E7F7` a second time, removing it. Not called and not run (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

## sound

`src/game/sound.asm`

### `Random` (`$F183`)

**A = a random byte from R (never called)**

R twice XORed into an address in HL, then R XOR (that address). HL kept. Nothing calls it (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WriteAyRegisters` (`$F190`)

**Write AY registers 0-13 from the 14 bytes at HL (never called)**

For each register A = 0-13: C = (HL), WriteAyRegister. Nothing calls it (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WriteAyRegister` (`$F19F`)

**Write C to AY register A (128K ports `$FFFD`, `$BFFD`)**

Register 7 (the mixer) is masked with `$3F`, so the I/O ports stay inputs. OUT (`$FFFD`),A then OUT (`$BFFD`),C, interrupts off between. Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DelayAfterFrame` (`$F1C8`)

**HALT, then a loop of 512 (never called)**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BuildLineTable` (`$F1D5`)

**Write the 192 Spectrum line addresses at `$F206` (never called)**

For line 0-191: `$4000` + (line & `$C0`) x 32 + (line & 7) x 256 + (line & `$38`) x 4, stored as words from `$F206`: the table `$B52D` holds the same addresses ready made. Run, it would write `$F206-$F385` over this code and the IM 2 set-ups (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `InstallIm2Key` (`$F343`)

**Install IM 2 with handler Im2HandlerKey, then call `$B3B5` (never called)**

The vector table `$FDFF-$FEFF` is filled with `$FD`, a JP Im2HandlerKey put at `$FDFD`, I = `$FE`, IM 2, EI; BC = 0 and CALL `$B3B5` (inside the key slot reader at `$B3B1`: it reads the eight KeySlots into a bit mask at `$B3CE`). Nothing calls it (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Im2HandlerKey` (`$F36B`)

**The IM 2 handler of InstallIm2Key: save all, call Im2HookKey, RETI**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Im2HookKey` (`$F382`)

**RET: the place of a per-frame routine (music) the handler would call**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `InstallIm2Wait` (`$F388`)

**Install IM 2 with handler Im2HandlerWait, then wait for a key (never called)**

As InstallIm2Key, with Im2HandlerWait in the JP at `$FDFD` and CALL `$B3FA` (wait for a key down and up). Nothing calls it (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Im2HandlerWait` (`$F3B0`)

**The IM 2 handler of InstallIm2Wait: save all, call Im2HookWait, RETI**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Im2HookWait` (`$F3C7`)

**RET: the place of a per-frame routine the handler would call**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SfxLand` (`$F3C8`)

**Effect: the ball lands on a platform (the square tone)**

SquareTone `$F54C`. Called at `$C79E`, `$C86D`, `$CAB3` when the landing sets `$ABA7` = 1.

Witness: L1 2628 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 224 calls, 8,294 t-states own (0.00 %) |
| Runs (the other recordings) | 2,404 calls (`stage1/menu` 322, `stage1/rzx/l18` 76, `stage1/rzx/l43` 54 and 116 more) |
| Called from | `BounceStep0`, `LeftStep0`, `RightStep0` |
| Calls | `SquareTone` |

### `SfxHit` (`$F3DF`)

**Effect: the ball strikes a cell that is not empty and not bricks**

RomNoise `$F560` (its noise from the ROM at `$04E6`). Called at `$CCE2`.

Witness: L1 1324 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 1,032 t-states own (0.00 %) |
| Runs (the other recordings) | 1,300 calls (`stage1/rzx/l46` 70, `stage1/rzx/l38` 51, `stage1/rzx/l75` 36 and 113 more) |
| Called from | `UpStep0` |
| Calls | `RomNoise` |

### `SfxPickup` (`$F3F6`)

**Effect: an object picked up, a menu option chosen**

RandomNoise2 `$F534`. Called by the prize, key, water and hammer handlers (`$B9AE`, `$B9C6`, `$B9E5`, `$BA04`) and MenuRedraw.

Witness: L1 1054 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 6 calls, 242 t-states own (0.00 %) |
| Runs (the other recordings) | 1,048 calls (`stage1/rzx/l23` 33, `stage1/rzx/l53` 19, `stage1/rzx/l15` 19 and 114 more) |
| Called from | `TakeObject`, `TakeKey`, `TakeWater`, `TakeHammer`, `MenuRedraw` |
| Calls | `RandomNoise2` |

### `SfxExtraLife` (`$F40D`)

**Effect: the bottle, an extra life**

TripleSweep `$F579` twice. Called at `$BA21`.

Witness: L1 23 (menu, scoreloop, l10, l36, l45, l68, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`docs/integrate/rec/scoreloop` 3, `stage2/rec/l68` 1, `stage1/rzx/l06` 1 and 18 more) |
| Called from | `TakeBottle` |
| Calls | `TripleSweep` |

### `SfxWaterDrop` (`$F427`)

**Effect: a water drop falls on a fire (WaterA1 `$C019`, WaterB1 `$C04C`, WaterC1 `$C07F`)**

RumbleHigh `$F5AD`.

Witness: L1 55 (menu, l10, l36, l56, l59, rzx x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 55 calls (`stage1/rzx/l79` 6, `stage1/rzx/l08` 4, `stage2/rec/l59` 3 and 30 more) |
| Called from | `WaterA1`, `WaterB1`, `WaterC1` |
| Calls | `RumbleHigh` |

### `SfxWallBounce` (`$F43E`)

**Effect: the ball bounces back from a wall (a falling sweep)**

SweepDown `$F510`. Called at `$C464`, `$C9A2`, `$CBE5`.

Witness: L1 119 (c1, menu, twoname, l x5, rzx x39).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 37 t-states own (0.00 %) |
| Runs (the other recordings) | 118 calls (`stage1/rzx/l96` 24, `stage2/rec/twoname` 9, `stage1/rzx/l36` 9 and 43 more) |
| Called from | `Lock3Step1`, `LeftWallBlocked`, `RightStep5` |
| Calls | `SweepDown` |

### `SfxLockA` (`$F455`)

**Effect: a step of the lock animation at `$C476`**

RandomNoise1 `$F521`.

Witness: L1 38 (l36, l59, l96, rzx x24).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 38 calls (`stage1/rzx/l54` 4, `stage1/rzx/l41` 2, `stage1/rzx/l84` 2 and 24 more) |
| Called from | `Lock2Step1` |
| Calls | `RandomNoise1` |

### `SfxLockB` (`$F46C`)

**Effect: a step of the lock animation at `$C488`**

RandomNoise2 `$F534`.

Witness: L1 117 (menu, l x6, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 117 calls (`stage1/rzx/l79` 15, `stage2/rec/l68` 10, `stage1/rzx/l68` 8 and 46 more) |
| Called from | `Lock1Step1` |
| Calls | `RandomNoise2` |

### `SfxFireDeath` (`$F483`)

**Effect: the ball lands on fire without water (stage2/rec/fire)**

RumbleLow `$F58C`, as SfxSpikeDeath. Called at `$CA7A`, `$CCBD`, `$CEF9`, the landings on a burning platform with no water drop; stage2/rec/fire (Water POKEd to 0) is the only one.

Witness: L1 1 (fire).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/fire` 1) |
| Called from | `LeftStep15` |
| Calls | `RumbleLow` |

### `SfxLevelEnd` (`$F49A`)

**Effect: the level is finished**

TripleSweep `$F579` twice. Called at `$B354`.

Witness: L1 102 (exitbelow, menu, l x12, rzx x88).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 102 calls (`stage1/rzx/l00` 1, `stage1/rzx/l05` 1, `stage1/rzx/l22` 1 and 99 more) |
| Called from | `LevelEnd` |
| Calls | `TripleSweep` |

### `SfxSpikeDeath` (`$F4B4`)

**Effect: the ball dies on platform 12**

RumbleLow `$F58C`. Called at `$CA75`, `$CCB8`, `$CDC6`, `$CEF4`.

Witness: L1 14 (rightspike, rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14 calls (`stage1/rzx/l56` 3, `stage1/rzx/l45` 2, `stage1/rzx/l68` 2 and 6 more) |
| Called from | `LeftStep15`, `RightStep15`, `UpStep4`, `DownStep7` |
| Calls | `RumbleLow` |

### `SfxLifeLost` (`$F4CB`)

**Effect: a life is lost (the ball fell, or the S key)**

RumbleLow `$F58C`. Called at `$B2B2` (the fall below the screen) and `$BA90`.

Witness: L1 23 (gameover, scoreloop, twoname, rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage1/gameover` 6, `stage2/rec/twoname` 6, `docs/integrate/rec/scoreloop` 3 and 6 more) |
| Called from | `LostStep5`, `SelfDestruct` |
| Calls | `RumbleLow` |

### `SfxBrickCrumble` (`$F4E2`)

**Effect: a brick layer crumbles (BrickCrumble1 `$BEBB`)**

RumbleHigh `$F5AD`.

Witness: L1 409 (l51, l59, l96, l98, rzx x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 409 calls (`stage1/rzx/l46` 56, `stage1/rzx/l38` 40, `stage1/rzx/l75` 32 and 28 more) |
| Called from | `BrickCrumble1` |
| Calls | `RumbleHigh` |

### `SfxTimerTick` (`$F4F9`)

**Effect: a tick of the timer counted into the score at the level's end**

SweepDown `$F510`. Called at `$B36B`.

Witness: L1 5622 (exitbelow, menu, l x8, rzx x80).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,622 calls (`stage1/menu` 215, `stage1/rzx/l99` 203, `stage1/rzx/l06` 67 and 87 more) |
| Called from | `LevelEnd` |
| Calls | `SweepDown` |

### `SweepDown` (`$F510`)

**100 speaker toggles, each delay one shorter (E = 100 down to 1): a rising tone**

Interrupts off; EI at the end.

Witness: L1 5741 (c1, exitbelow, menu, twoname, l x11, rzx x94).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 call, 84,242 t-states own (0.01 %) |
| Runs (the other recordings) | 5,740 calls (`stage1/menu` 216, `stage1/rzx/l99` 203, `stage1/rzx/l06` 67 and 105 more) |
| Called from | `SfxWallBounce`, `SfxTimerTick` |
| Calls | `SweepFromE` (falls into) |
| Ports out | `$00FE`, `$10FE` |

### `SweepFromE` (`$F513`)

**As SweepDown from the delay in E**

Witness: L1 6491 (c1, exitbelow, menu, scoreloop, twoname, l x12, rzx00-rzx34, rzx36-rzx82, rzx84-rzx97, rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,434 calls (`stage1/menu` 228, `stage1/rzx/l99` 209, `stage1/rzx/l06` 79 and 103 more) |
| Called from | `SweepDown` (falls into), `TripleSweep` (tail) |
| Ports out | `$00FE`, `$10FE` |

### `RandomNoise1` (`$F521`)

**100 speaker pulses, each delay taken from R, the speaker bit from R**

Witness: L1 38 (l36, l59, l96, rzx x24).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 38 calls (`stage1/rzx/l54` 4, `stage1/rzx/l84` 2, `stage1/rzx/l46` 2 and 24 more) |
| Called from | `SfxLockA` |
| Ports out | `$00FE`, `$10FE` |

### `RandomNoise2` (`$F534`)

**100 pulses, the speaker bit from R, delay `$50` + (R & `$3F`)**

Witness: L1 1171 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 6 calls, 1,112,329 t-states own (0.09 %) |
| Runs (the other recordings) | 1,165 calls (`stage1/rzx/l23` 33, `stage1/rzx/l18` 23, `stage1/rzx/l79` 21 and 114 more) |
| Called from | `SfxPickup`, `SfxLockB` |
| Ports out | `$00FE`, `$10FE` |

### `SquareTone` (`$F54C`)

**100 half periods: on with a delay of 100, off at once**

Witness: L1 2628 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop, twoname, l x12, rzx00-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 224 calls, 18,937,972 t-states own (1.49 %) |
| Runs (the other recordings) | 2,404 calls (`stage1/menu` 322, `stage1/rzx/l18` 76, `stage1/rzx/l43` 54 and 116 more) |
| Called from | `SfxLand` |
| Ports out | `$00FE`, `$10FE` |

### `RomNoise` (`$F560`)

**100 pulses from ROM bytes `$0400` + L on: the speaker bit and the delay `$28` + (byte & `$3F`)**

L is the low byte of the effect's parameter address.

Witness: L1 1324 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12, rzx00-rzx77, rzx79-rzx99).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level 0) | 24 calls, 2,658,860 t-states own (0.21 %) |
| Runs (the other recordings) | 1,300 calls (`stage1/rzx/l46` 70, `stage1/rzx/l38` 51, `stage1/rzx/l75` 36 and 113 more) |
| Called from | `SfxHit` |
| Ports out | `$00FE`, `$10FE` |

### `TripleSweep` (`$F579`)

**Three sweeps from R-based delays (R set to `$3F` first, so the same each time)**

Witness: L1 250 (exitbelow, menu, scoreloop, l x12, rzx x91).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 250 calls (`docs/integrate/rec/scoreloop` 6, `stage2/rec/l10` 4, `stage1/menu` 4 and 103 more) |
| Called from | `SfxExtraLife`, `SfxLevelEnd` |
| Calls | `SweepFromE` (tail) |

### `RumbleLow` (`$F58C`)

**600 samples from ROM `$0000`: border bits and speaker from the byte, delay (byte & `$F0`) + 1**

Writes the mask `$F0` into the AND at `$F59F`; RomRumble does the rest.

Witness: L1 38 (fire, gameover, rightspike, scoreloop, twoname, rzx x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 38 calls (`stage2/rec/twoname` 6, `stage1/gameover` 6, `stage1/rzx/l51` 4 and 13 more) |
| Called from | `SfxFireDeath`, `SfxSpikeDeath`, `SfxLifeLost` |
| Calls | `RomRumble` (falls into) |
| Writes | `$F5A0` (`RomRumble+8`) |
| Ports out | `$00FE`, `$10FE`, `$18FE`, `$20FE`, `$28FE`, `$30FE`, `$40FE`, `$58FE`, `$70FE`, `$78FE`, `$A8FE`, `$C0FE`, `$C8FE`, `$D0FE`, `$F0FE`, `$F8FE` |

### `RomRumble` (`$F598`)

**The sample loop: HL the ROM, BC the count, the mask in the AND at `$F59F`**

Each byte: OUT (`$FE`),(byte & `$F8`) (border black, MIC and speaker bits from the ROM), then a delay of (byte & mask) + 1. EI at the end.

Witness: L1 440400 (fire, gameover, menu, rightspike, scoreloop, twoname, l x7, rzx x48).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 45 calls (`stage1/rzx/l59` 20, `stage1/rzx/l51` 12, `stage1/rzx/l98` 9 and 2 more) |
| Called from | `RumbleLow` (falls into), `RumbleHigh` (tail) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE`, `$20FE`, `$30FE`, `$48FE`, `$50FE`, `$78FE`, `$B0FE`, `$C0FE`, `$D0FE`, `$D8FE`, `$E0FE`, `$E8FE`, `$F0FE` |

### `RumbleHigh` (`$F5AD`)

**900 samples from ROM `$1770`, mask `$0E`**

Witness: L1 464 (menu, l x7, rzx x42).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 464 calls (`stage1/rzx/l46` 56, `stage1/rzx/l38` 40, `stage1/rzx/l75` 32 and 47 more) |
| Called from | `SfxWaterDrop`, `SfxBrickCrumble` |
| Calls | `RomRumble` (tail) |
| Writes | `$F5A0` (`RomRumble+8`) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE`, `$20FE`, `$30FE`, `$48FE`, `$50FE`, `$78FE`, `$B0FE`, `$C0FE`, `$D0FE`, `$D8FE`, `$E0FE`, `$E8FE`, `$F0FE` |

### `SfxUnused` (`$F5BB`)

**An effect nothing calls: 900 samples from ROM `$0BB8`, mask `$38`**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |


## The tape's BASIC (`src/tape/basic.json`)

Bumpy, Loriciels 1989: tape block 2, the BASIC program "BUMPY" (191 bytes at PROG `$5CCB`, LINE 10): hides the tape
messages, CLEAR 24999, `LOAD "" SCREEN$`, LOAD "" CODE 25000 and RANDOMIZE USR 43900. Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic.json`; the
recordings: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the 48K, the menu and play on level
0).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic`](11-data-reference.md#the-tapes-basic-basic) | `$5CCB`-`$5D89` | 0 of 1 |


## The loading screen (`src/screen/screen.json`)

Bumpy, Loriciels 1989: tape block 4, the loading screen BUMPY.SCR, loaded by the BASIC's `LOAD "" SCREEN$` at
`$4000`. Its entries are `src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part
src/screen/screen.json`; the recordings: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the 48K,
the menu and play on level 0).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`screen`](11-data-reference.md#the-loading-screen-screen) | `$4000`-`$5AFF` | 0 of 1 |
