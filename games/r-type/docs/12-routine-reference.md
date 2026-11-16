# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a table jump or
by running on: L1 books its time to the routine it runs in) gives the runs of its first instruction, as its witness
line counts them.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: The tape BASIC and the copy of the decryption chain, The
decryption chain and the SpeedLock 7 loader, The second stage, The second stage's table, The decipher block, The
second stage's end, The loader's tail: the move to the game and the jump to the entry, Level 1 (side 2), Level 2
(side 2), Level 3 (side 2), Level 4 (side 2), Level 5 (side 2), Level 6 (side 2), Level 7 (side 2), Level 8 (side
2)) follow the game, each under its own heading with its modules, its source, its annotations and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`texts`](11-data-reference.md#texts) | `$7000`-`$73BB` | 0 of 38 |
| [`titlestate`](#titlestate) | `$73BC`-`$767F` | 6 of 16 |
| [`screen`](#screen) | `$7680`-`$7A7F` | 5 of 12 |
| [`vars`](11-data-reference.md#vars) | `$7A80`-`$814E` | 0 of 11 |
| [`intro`](#intro) | `$814F`-`$85FC` | 3 of 6 |
| [`main`](#main) | `$85FD`-`$8740` | 9 of 9 |
| [`scroll`](#scroll) | `$8741`-`$8CFC` | 65 of 65 |
| [`sprites`](#sprites) | `$8CFD`-`$8F1E` | 9 of 9 |
| [`tapeload`](#tapeload) | `$8F1F`-`$8FCA` | 3 of 4 |
| [`waves`](#waves) | `$8FCB`-`$93CF` | 27 of 27 |
| [`ship`](#ship) | `$93D0`-`$A5F6` | 80 of 80 |
| [`graphics`](11-data-reference.md#graphics) | `$A5F7`-`$BE22` | 0 of 3 |
| [`interrupt`](#interrupt) | `$BE23`-`$C05C` | 12 of 13 |
| [`util`](#util) | `$C05D`-`$C4AD` | 29 of 31 |
| [`levelspace`](11-data-reference.md#levelspace) | `$C4AE`-`$F87B` | 0 of 5 |
| [`sound`](#sound) | `$F87C`-`$FDA4` | 38 of 47 |
| [`tail`](#tail) | `$FDA5`-`$FFFF` | 12 of 14 |

## titlestate

`src/game/titlestate.asm`

### `StarsOn` (`$73BC`)

**Switch the star task on (task 0 of TaskTable)**

A = 1, then StarsSet writes it to the task's switch byte (TaskTable + 2).

Witness: L1 47 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l2-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 44 t-states own (0.00 %) |
| Runs (the other recordings) | 43 calls (`stage2/rec/deaths-l7` 8, `stage1/rec/continue` 7, `stage1/rec/hiscore` 5 and 13 more) |
| Called from | `StartPlayField` |
| Calls | `StarsSet` (falls into) |
| Writes | `$BE62` (`TaskTable+2`) |

### `StarsSet` (`$73BE`)

**StarsSet**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 10 calls, 258 t-states own (0.00 %) |
| Runs (the other recordings) | 99 calls (`stage2/rec/deaths-l7` 15, `stage1/rec/continue` 14, `stage1/rec/gameover` 14 and 12 more) |
| Called from | `StarsOn` (falls into), `StarsOff` (tail) |
| Writes | `$BE62` (`TaskTable+2`) |

### `StarsOff` (`$73C2`)

**Switch the star task off**

Witness: L1 68 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, gameover, hiscore, hiscore-typed, restart, l1-l7).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 6 calls, 127 t-states own (0.00 %) |
| Runs (the other recordings) | 62 calls (`stage1/rec/gameover` 10, `stage2/rec/deaths-l7` 7, `stage1/rec/continue` 7 and 15 more) |
| Called from | `TitleLoop`, `LoseLife`, `LevelEnd`, `LoadLevel` |
| Calls | `StarsSet` (tail) |
| Writes | `$BE62` (`TaskTable+2`) |

### `PlayStars` (`$73C5`)

**Point the star task at the play's star states**

Writes 0 into the star phase operand, patches the star step to LD A,2 and points the star task's state pointer at `$7380`.

Witness: L1 17 (c1, ending, gameover, hiscore, l1-l7).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3 calls, 297 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/rec/gameover` 5, `stage1/rec/ending` 1, `stage1/rec/hiscore` 1 and 7 more) |
| Called from | `TitleLogo` |
| Writes | `$BE7E`-`$BE7F` (`StarTask+5`); `$BECB` (`l_BECA+1`); `$BF24`-`$BF25` (`l_BF11+19`) |

### `TitleStarsOn` (`$73D8`)

**Point the star task at the title's star states**

Writes `$3C` into the star phase operand, patches the star step to LD A,8 / LD (HL),A and points the state pointer at `$80D8`.

Witness: L1 47 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l2-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 368 t-states own (0.00 %) |
| Runs (the other recordings) | 43 calls (`stage2/rec/deaths-l7` 8, `stage1/rec/continue` 7, `stage1/rec/hiscore` 5 and 13 more) |
| Called from | `StartLife` |
| Writes | `$BE7E`-`$BE7F` (`StarTask+5`); `$BECB` (`l_BECA+1`); `$BF24`-`$BF25` (`l_BF11+19`) |

### `ProbeKempston` (`$73EC`)

**Look for a Kempston joystick: read port `$1F` up to 255 times**

Stores the low four bits of the first non-zero read in KempstonAbsent, or 0 when all 255 reads were 0 (a Kempston at rest). The 48K's floating bus reads non-zero, so 0 means "a Kempston is there". Called once from the entry.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 call, 15,434 t-states own (0.00 %) |
| Called from | `Entry` |
| Writes | `$7A8B` (`KempstonAbsent`) |
| Ports in | `$001F` |

## screen

`src/game/screen.asm`

### `ClearSides` (`$7680`)

**Paint column 0 and column 31 of the 24 attribute rows with C (0: black)**

Witness: L1 66 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 5 calls, 6,724 t-states own (0.00 %) |
| Runs (the other recordings) | 61 calls (`stage2/rec/deaths-l7` 8, `stage1/rec/hiscore` 8, `stage1/rec/gameover` 8 and 15 more) |
| Called from | `ShowHiScores`, `StartPlayField`, `CommandWave` |
| Writes | `$5800`-`$5A40` (screen); `$5A5F`-`$5A60` (screen); `$5A7F`-`$5A80` (screen); `$5A9F`-`$5AA0` (screen); `$5ABF`-`$5AC0` (screen); `$5ADF`-`$5AE0` (screen); 1 more ranges |

### `ShowHiScores` (`$7690`)

**Clear the screen and show the high-score table**

ClearScreen, the black sides, the title colour task (task 4) on, then PrintHiScores.

Witness: L1 9 (c1, gameover, hiscore, hiscore-typed).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 call, 2,218 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/gameover` 4, `stage1/rec/hiscore` 3, `stage1/rec/hiscore-typed` 1) |
| Called from | `TitleLoop`, `CheckHiScore`, `InsertHiScore` |
| Calls | `ClearSides`, `PrintHiScores` (falls into), `ClearScreen` |
| Writes | `$BE76` (`TaskTable+22`) |

### `PrintHiScores` (`$769B`)

**Print "TODAY'S BEST PILOTS" and the nine entries of HiScoreTable**

Each entry: its place digit (DigitChars), the name and the score, double height, from row 3 down.

Witness: L1 1309 (c1, gameover, hiscore, hiscore-typed).

[Animation: `PrintHiScores` at work](img/routines/PrintHiScores.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,304 calls (`stage1/rec/hiscore-typed` 923, `stage1/rec/hiscore` 381) |
| Called from | `ShowHiScores` (falls into), `InsertHiScore` |
| Calls | `PrintText` |

### `CycleTitleColour` (`$76CB`)

**Interrupt task 4: step the screen's colours through the INKs on a black paper**

Paints the top attribute rows with the next colour and copies them down the screen: the whole screen follows.

Witness: L1 807 (c1, ctl-if2, ctl-kempston, ctl-sinclair, ending, gameover, hiscore, hiscore-typed, l1-l7).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3 calls, 977,886 t-states own (0.07 %) |
| Runs (the other recordings) | 14 calls (`stage1/rec/gameover` 5, `stage1/rec/hiscore` 1, `stage1/rec/ending` 1 and 7 more) |
| Called from | `TitleLoop`, `RunTask`, `LoadLevel` |
| Calls | `FillBlock` |
| Reads | `$5800`-`$5ABF` (screen); `$7A89` (`FrameCounter`) |
| Writes | `$5840`-`$5AFF` (screen); `$7A89` (`FrameCounter`) |

### `TitleLoop` (`$7796`)

**The title: logo, texts and the high-score table in turn until a fire picks the control method**

Stars off, the play state cleared, TitleLogo, the title lines; DefineKeys while the title waits (ENTER defines keys); then the high-score table, polling SelectControl; round again. SelectControl leaves the loop through the stack with the method chosen.

The two waits take C from the code before them: `$0400` = 1024 turns (C = 0 from FillBlock), then `$5404` = 21 508 SelectControl polls (C = 4 from ShowHiScores).

Witness: L1 8 (c1, gameover, hiscore).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 call, 25,488,500 t-states own (1.83 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/gameover` 1, `stage1/rec/hiscore` 1) |
| Called from | `NewGame` |
| Calls | `StarsOff`, `ShowHiScores`, `CycleTitleColour`, `ClearPlayState`, `TitleLogo`, `StarTask`, `DefineKeys`, `SelectControl`, `PrintTextNormal`, `FillBlock` |
| Reads | `$7800`-`$7A7F` (`PlayAttrs`) |
| Writes | `$5800`-`$5A7F` (screen); `$7A89` (`FrameCounter`) |

## intro

`src/game/intro.asm`

### `ShowLoadingScreen` (`$814F`)

**Show the title picture and scroll the credits along the bottom**

Copies TitleScreen (6912 bytes) to the screen; then each character of ScrollerText in turn is printed at the right of the bottom rows and the rows scrolled left (ScrollRowLeft) with a HALT a step, until the text's last character; then a wait.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 call, 58,455,164 t-states own (4.21 %) |
| Called from | `Entry` |
| Calls | `ScrollRowLeft`, `PrintText` |
| Reads | `$8189` (`l_816F+26`); `$81A9`-`$837A` (`ScrollerText`); `$DD18`-`$F817` (`TitleScreen`) |
| Writes | `$4000`-`$5AFF` (screen); `$81A9`-`$8379` (`ScrollerText`) |
| Ports out | `$00FE` |

### `ScrollRowLeft` (`$8198`)

**Scroll 32 bytes of pixel lines left by one pixel (RL (HL) from the right end)**

Witness: L1 7440 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 7,440 calls, 69,602,485 t-states own (5.01 %) |
| Called from | `ShowLoadingScreen` |
| Reads | `$50C1`-`$50FF` (screen); `$51C1`-`$51FF` (screen); `$52C1`-`$52FF` (screen); `$53C1`-`$53FF` (screen); `$54C1`-`$54FF` (screen); `$55C1`-`$55FF` (screen); 2 more ranges |
| Writes | `$50C1`-`$50FF` (screen); `$51C1`-`$51FF` (screen); `$52C1`-`$52FF` (screen); `$53C1`-`$53FF` (screen); `$54C1`-`$54FF` (screen); `$55C1`-`$55FF` (screen); 2 more ranges |

### `Im2Jump` (`$8383`)

**The IM 2 target: JP Interrupt (every vector of Im2Table is `$83`, so the CPU jumps to `$8383`)**

Witness: L1 159333 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 5,441 calls, 54,410 t-states own (0.00 %) |
| Runs (the other recordings) | 153,892 calls (`stage1/rec/l3` 15,045, `stage1/rec/l1` 14,920, `docs/integrate/rec/boss` 13,177 and 18 more) |
| Entered by | the interrupt, 158,839 times in 200 routines |
| Calls | `Interrupt` (tail) |
| Reads | `$84FF`-`$8500` (`Im2Table+255`) |
| Writes | `$FFE0`-`$FFFD` (`StackArea+76`) |

## main

`src/game/main.asm`

### `Entry` (`$85FD`)

**The game's entry from the loader's tail: build the tables, show the title picture, load level 1, run the title**

Interrupts off; SP = `$FFFE`; builds BitReverse; copies EntryCopySource to EntryCopy; IM 2 through Im2Table; ProbeKempston; ShowLoadingScreen; LoadLevel loads level 1. Then NewGame, StartLife, MainLoop.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 call, 85,624 t-states own (0.01 %) |
| Calls | `ProbeKempston`, `ShowLoadingScreen` |
| Reads | `$7EE2`-`$807F` (`EntryCopySource`) |
| Writes | `$5B64`-`$5DFF` (`EntryCopy`, `BitReverse`) |

### `NewGame` (`$8634`)

**NewGame**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 calls (`stage1/rec/gameover` 1, `stage1/rec/hiscore` 1) |
| Called from | `LoseLife` (tail) |
| Calls | `TitleLoop`, `RestartPoint`, `NewGameState` |

### `StartLife` (`$863D`)

**StartLife**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3 calls, 3,332,586 t-states own (0.24 %) |
| Runs (the other recordings) | 40 calls (`stage2/rec/deaths-l7` 8, `stage1/rec/continue` 7, `stage1/rec/hiscore` 5 and 13 more) |
| Called from | `LoseLife` (tail), `LevelEnd` (tail) |
| Calls | `TitleStarsOn`, `ClearPlayState`, `StartPlayField`, `StartPlay` |
| Reads | `$7A8A` (`IntTicks`) |
| Writes | `$7A8A` (`IntTicks`) |

### `MainLoop` (`$8649`)

**MainLoop**

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 422 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 12,830 calls (`stage1/rec/l7` 2,815, `stage1/rec/l4` 2,767, `stage1/rec/l2` 2,687 and 3 more) |
| Called from | `MainLoopPatch` (tail) |
| Calls | `Scroll`, `CheckPause`, `LoseLife` |
| Reads | `$7A8A` (`IntTicks`) |
| Writes | `$7A8A` (`IntTicks`) |

### `MainLoopPatch` (`$8656`)

**MainLoopPatch**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 32,903 runs of its first instruction, entered by a jump (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `Scroll` |
| Calls | `MainLoop` (tail), `ReadControls`, `ShipFlyIn`, `RunWaves`, `MoveEnemies`, `MoveMissiles`, `MoveShip`, `MoveForce`, `MoveShipShots`, `MoveForceShots`, `MoveBeam`, `MoveMissileSet`, `BossBlastStep`, `LevelEnd`, `CheckRestart`, `MoveEnemyShots`, `DrawExplosions`, `CheckExtraLife` |
| Reads | `$7A8A` (`IntTicks`) |
| Writes | `$7A8A` (`IntTicks`) |

### `RestartPoint` (`$8696`)

**Copy the level's first restart column and wave entry into the live ones**

Witness: L1 11 (c1, deaths-l7, gameover, hiscore, l2-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 call, 97 t-states own (0.00 %) |
| Runs (the other recordings) | 10 calls (`stage1/rec/l3` 1, `stage1/rec/l6` 1, `stage1/rec/l5` 1 and 7 more) |
| Called from | `NewGame`, `LevelEnd` |
| Reads | `$C4B1`-`$C4B5` (`LevelChecks`, `LevelWaves`) |
| Writes | `$7A84`-`$7A91` (`MapColumn`, `MapReadPtr`, `MapBlockPtr`, `FrameCounter` and 7 more); `$C4AE`-`$C4B0` (`LevelSpace`, `LevelRestartWave`) |

### `NewGameState` (`$86A9`)

**Lives = 5, ExtraLives = 0, the sound silenced, the score set to "000000"**

Witness: L1 4 (c1, continue, gameover, hiscore).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1 call, 116 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/continue` 1, `stage1/rec/gameover` 1, `stage1/rec/hiscore` 1) |
| Called from | `NewGame`, `LoseLife` |
| Calls | `Silence`, `FillBlock` |
| Writes | `$7A8C` (`ExtraLives`); `$7AA0` (`Lives`) |

### `ClearPlayState` (`$86C3`)

**Zero the ClearList blocks, set the colours and the control reader**

Zeroes every ClearList block; attributes and PlayAttrs `$47`; border black; clears ShieldTimer, the title colour task, the controls patch at ShieldControls, Shooters, MissileTimer and the death patch at ShipDies + 3; ControlVector from ControlVectors by ControlMethod; ResumeWaves.

Witness: L1 64 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 7 calls, 12,057 t-states own (0.00 %) |
| Runs (the other recordings) | 57 calls (`stage1/rec/gameover` 9, `stage2/rec/deaths-l7` 8, `stage1/rec/continue` 7 and 15 more) |
| Called from | `TitleLoop`, `StartLife`, `LoadLevel` |
| Calls | `ResumeWaves`, `ClearBlock`, `FillBlock` |
| Reads | `$74FB` (`ControlMethod`); `$75B7`-`$75DC` (`ClearList`); `$778C`-`$7793` (`ControlVectors`) |
| Writes | `$74FC`-`$74FD` (`ControlVector`); `$7A98`-`$7A9F` (`ShieldTimer`, `ScoreChanged`, `WaveOverride`, `LevelEndTimer` and 4 more); `$83ED` (`MissileTimer`); `$91F5` (`ShipDies+3`); `$95A5` (`ShieldControls`); `$BE76` (`TaskTable+22`) |
| Ports out | `$00FE` |

### `StartPlayField` (`$8721`)

**Start the play field at the level's restart column**

Clears ScrollHalted and the BEAM meter, takes MapColumn and WavePtr from the restart point, DrawFirstScreen, stars on, DrawHud, the black sides.

Witness: L1 47 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l2-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 724 t-states own (0.00 %) |
| Runs (the other recordings) | 43 calls (`stage2/rec/deaths-l7` 8, `stage1/rec/continue` 7, `stage1/rec/hiscore` 5 and 13 more) |
| Called from | `StartLife` |
| Calls | `StarsOn`, `ClearSides`, `DrawHud`, `DrawFirstScreen` |
| Reads | `$C4AE`-`$C4B0` (`LevelSpace`, `LevelRestartWave`) |
| Writes | `$7A84`-`$7A97` (`MapColumn`, `MapReadPtr`, `MapBlockPtr`, `FrameCounter` and 11 more) |

## scroll

`src/game/scroll.asm`

### `CutMetatile` (`$8741`)

**Cut the next cells of a column from a metatile as stored**

A = the metatile: MetatileAddress; the column MetaColumn's 4 cells (9 bytes each) to ColumnPtr.

Witness: L1 14196 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 264 calls, 267,697 t-states own (0.02 %) |
| Runs (the other recordings) | 13,932 calls (`docs/integrate/rec/boss` 1,504, `stage1/rec/l1` 1,504, `stage1/rec/l4` 1,124 and 17 more) |
| Called from | `Scroll` |
| Calls | `MetatileAddress` |
| Reads | `$7A80`-`$7A83` (`GameVars`, `ScrollStep`, `MetaColumn`); `$CCB7`-`$CD46` (`LoaderLeftover+1907`); `$CE67`-`$E761` (`LoaderLeftover+2339`, `TitleScreen`) |
| Writes | `$5E00`-`$5EB3` (`ColumnBuffer`); `$7A80`-`$7A81` (`GameVars`) |

### `CutMetatileMirrored` (`$8778`)

**Cut a column from a metatile mirrored left to right (the bytes through BitReverse)**

Witness: L1 420 (boss, force, hiscore, hiscore-typed, restart, l1-l4, l6, l7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 420 calls (`stage1/rec/l4` 108, `docs/integrate/rec/boss` 84, `stage1/rec/l1` 84 and 8 more) |
| Called from | `Scroll` |
| Calls | `MirrorCell`, `MetatileAddress` |
| Reads | `$7A80`-`$7A83` (`GameVars`, `ScrollStep`, `MetaColumn`) |
| Writes | `$7A80`-`$7A81` (`GameVars`) |

### `MirrorCell` (`$879E`)

**Copy one cell's 8 pixel bytes through BitReverse, then its attribute**

Witness: L1 1680 (boss, force, hiscore, hiscore-typed, restart, l1-l4, l6, l7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,680 calls (`stage1/rec/l4` 432, `docs/integrate/rec/boss` 336, `stage1/rec/l1` 336 and 8 more) |
| Called from | `CutMetatileMirrored` |
| Reads | `$5D00`-`$5DFF` (`BitReverse`); `$CD47`-`$CE66` (`LoaderLeftover+2051`); `$D562`-`$D6A7` (`LoaderLeftover+4126`); `$D8C2`-`$D9E1` (`LoaderLeftover+4990`); `$DB92`-`$DC47` (`LoaderLeftover+5710`); `$DD01`-`$DE20` (`LoaderLeftover+6077`, `TitleScreen`); 2 more ranges |
| Writes | `$5E00`-`$5EB3` (`ColumnBuffer`) |

### `CutMetatileFlipped` (`$87B8`)

**Cut a column from a metatile upside down**

Witness: L1 2071 (boss, deaths-l7, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,071 calls (`stage1/rec/l7` 352, `stage2/rec/deaths-l7` 295, `stage1/rec/l6` 280 and 8 more) |
| Called from | `Scroll` |
| Calls | `MetatileAddress` |
| Reads | `$7A80`-`$7A83` (`GameVars`, `ScrollStep`, `MetaColumn`); `$CCB7`-`$CD46` (`LoaderLeftover+1907`); `$CF87`-`$D0A6` (`LoaderLeftover+2627`); `$D137`-`$E715` (`LoaderLeftover+3059`, `TitleScreen`) |
| Writes | `$5E00`-`$5EB3` (`ColumnBuffer`); `$7A80`-`$7A81` (`GameVars`) |

### `CutMetatileBoth` (`$87F2`)

**Cut a column from a metatile mirrored and upside down**

Witness: L1 220 (boss, l x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 220 calls (`stage1/rec/l3` 56, `docs/integrate/rec/boss` 48, `stage1/rec/l1` 48 and 3 more) |
| Called from | `Scroll` |
| Calls | `MetatileAddress` |
| Reads | `$5D00`-`$5DFF` (`BitReverse`); `$7A80`-`$7A83` (`GameVars`, `ScrollStep`, `MetaColumn`); `$D1C7`-`$D256` (`LoaderLeftover+3203`); `$D618`-`$D6D6` (`LoaderLeftover+4308`); `$D767`-`$D7F6` (`LoaderLeftover+4643`); `$DBB8`-`$DC47` (`LoaderLeftover+5748`); 4 more ranges |
| Writes | `$5E00`-`$5E47` (`ColumnBuffer`); `$5E6C`-`$5EB3` (`ColumnBuffer+108`); `$7A80`-`$7A81` (`GameVars`) |

### `MetatileAddress` (`$882D`)

**HL = the metatile A's data below the level's map (LevelMetatiles - (A + 1) x 144)**

Witness: L1 18787 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 424 calls, 65,720 t-states own (0.00 %) |
| Runs (the other recordings) | 18,363 calls (`docs/integrate/rec/boss` 1,856, `stage1/rec/l1` 1,856, `stage1/rec/l4` 1,360 and 17 more) |
| Called from | `CutMetatile`, `CutMetatileMirrored`, `CutMetatileFlipped`, `CutMetatileBoth`, `DrawFirstScreen` |
| Reads | `$C4BC`-`$C4BD` (`LevelMetatiles`) |

### `ScrollRows` (`$8842`)

**Put the 20 play rows on the screen: attributes copied, scenery shifted one pixel left, changed sprite cells copied**

For each row of RowTable: the row's attributes copied from PlayAttrs to the screen (LDDR, columns 1-30); the row walked from the right by its SolidMap tags, scenery cells shifted on the screen (RowTable holds the screen pages, `$40`xx), other cells copied from the pixel shadow to the screen. While the map moves (ScrollHalted `$7A8E` = 0) the runs of scenery cells are shifted one pixel left through the unrolled chain ShiftRun; while it stands they are skipped. Sprite cells (tag 1 to `$DB`) are copied from the pixel shadow and DrawnMap set; untagged cells with DrawnMap 1 are cleared; every tag but `$9C` is cleared, `$9C` only when FrameCounter AND 7 = 7 (`$88CD`).

Witness: L1 33972 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

[Animation: `ScrollRows` at work](img/routines/ScrollRows.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 539 calls, 7,546 t-states own (0.00 %) |
| Runs (the other recordings) | 33,433 calls (`stage1/rec/l1` 3,519, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 3,013 and 18 more) |
| Called from | `Scroll`, `TitleLogo`, `LogoRow`, `LevelEnd` |
| Calls | `l_8846` (falls into) |
| Reads | `$6012` (system); `$6025`-`$6032` (system); `$6051`-`$60FE` (system); `$6112` (system); `$6125`-`$61FE` (system); `$6212` (system); 46 more ranges |
| Writes | `$4012` (screen); `$4025`-`$40FE` (screen); `$4112` (screen); `$4125`-`$41FE` (screen); `$4212` (screen); `$4225`-`$42FE` (screen); 49 more ranges |

### `l_8846` (`$8846`)

**l_8846**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 11,317 calls, 10,659,473 t-states own (0.77 %) |
| Runs (the other recordings) | 694,024 calls (`stage1/rec/l1` 73,915, `docs/integrate/rec/boss` 66,103, `stage1/rec/l3` 63,273 and 17 more) |
| Called from | `ScrollRows` (falls into), `l_8869` (tail) |
| Calls | `l_8869` (falls into) |
| Reads | `$7801`-`$7A7E` (`PlayAttrs+1`); `$8081`-`$80D3` (`RowTable+1`, `RowTableEnd`) |
| Writes | `$5801`-`$5A7E` (screen); `$850A` (`EnemySlots+9`) |

### `l_8869` (`$8869`)

**l_8869**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 15,489 calls, 59,035,696 t-states own (4.25 %) |
| Runs (the other recordings) | 1,095,054 calls (`stage1/rec/l1` 127,368, `docs/integrate/rec/boss` 119,928, `stage1/rec/l4` 102,548 and 17 more) |
| Called from | `l_8846` (falls into), `ShiftRunDone` (tail) |
| Calls | `l_8846` (tail), `ShiftRun`, `ShiftRun30`, `ShiftRun29`, `ShiftRun28`, `ShiftRun27`, `ShiftRun26`, `ShiftRun25`, `ShiftRun24`, `ShiftRun23`, `ShiftRun22`, `ShiftRun21`, `ShiftRun20`, `ShiftRun19`, `ShiftRun18`, `ShiftRun17`, `ShiftRun16`, `ShiftRun15`, `ShiftRun14`, `ShiftRun13`, `ShiftRun12`, `ShiftRun11`, `ShiftRun10`, `ShiftRun9`, `ShiftRun8`, `ShiftRun7`, `ShiftRun6`, `ShiftRun5`, `ShiftRun4`, `ShiftRun3`, `ShiftRun2`, `ShiftRun1` |
| Reads | `$6001`-`$707E` (`ShadowLine0`); `$7101`-`$717E` (`ShadowLine1+1`); `$7201`-`$727E` (`ShadowLine2+1`); `$7301`-`$737E` (`ShadowLine3+1`); `$7401`-`$747E` (`ShadowLine4+3`); `$7501`-`$757E` (`ShadowLine4Tail+3`); 5 more ranges |
| Writes | `$4001`-`$507E` (screen); `$5101`-`$517E` (screen); `$5201`-`$527E` (screen); `$5301`-`$537E` (screen); `$5401`-`$547E` (screen); `$5501`-`$557E` (screen); 4 more ranges |

### `ShiftRun` (`$8914`)

**The unrolled RL (HL) / DEC L chain, entered 3 bytes a cell from its end to shift a run of cells one pixel left**

Witness: L1 255048 (boss, deaths-l7, force, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 255,048 calls (`stage1/rec/l5` 89,472, `stage1/rec/l7` 32,256, `stage1/rec/l8` 32,128 and 9 more) |
| Called from | `l_8869`, `ShiftRun1` |
| Calls | `ShiftRun30` (falls into) |
| Reads | `$401F`-`$475F` (screen); `$48BF`-`$4AFF` (screen); `$4BBF`-`$4BFF` (screen); `$4CBF`-`$4CFF` (screen); `$4DBF`-`$4DFF` (screen); `$4EBF`-`$4EFF` (screen); 1 more ranges |
| Writes | `$401F`-`$475F` (screen); `$48BF`-`$4AFF` (screen); `$4BBF`-`$4BFF` (screen); `$4CBF`-`$4CFF` (screen); `$4DBF`-`$4DFF` (screen); `$4EBF`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun30` (`$8917`)

**the chain from 30 cells**

Witness: L1 265656 (boss, deaths-l7, force, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 265,656 calls (`stage1/rec/l5` 89,856, `stage1/rec/l7` 33,792, `stage1/rec/l8` 32,512 and 9 more) |
| Called from | `l_8869`, `ShiftRun` (falls into), `ShiftRun1` |
| Calls | `ShiftRun29` (falls into) |
| Reads | `$401E`-`$475F` (screen); `$48BE`-`$4AFF` (screen); `$4BBE`-`$4BFF` (screen); `$4CBE`-`$4CFF` (screen); `$4DBE`-`$4DFF` (screen); `$4EBE`-`$4EFF` (screen); 1 more ranges |
| Writes | `$401E`-`$475F` (screen); `$48BE`-`$4AFF` (screen); `$4BBE`-`$4BFF` (screen); `$4CBE`-`$4CFF` (screen); `$4DBE`-`$4DFF` (screen); `$4EBE`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun29` (`$891A`)

**the chain from 29 cells**

Witness: L1 276704 (boss, deaths-l7, force, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 276,704 calls (`stage1/rec/l5` 90,240, `stage1/rec/l7` 35,328, `stage1/rec/l8` 32,896 and 9 more) |
| Called from | `l_8869`, `ShiftRun30` (falls into), `ShiftRun1` |
| Calls | `ShiftRun28` (falls into) |
| Reads | `$401D`-`$475F` (screen); `$48BD`-`$4AFF` (screen); `$4BBD`-`$4BFF` (screen); `$4CBD`-`$4CFF` (screen); `$4DBD`-`$4DFF` (screen); `$4EBD`-`$4EFF` (screen); 1 more ranges |
| Writes | `$401D`-`$475F` (screen); `$48BD`-`$4AFF` (screen); `$4BBD`-`$4BFF` (screen); `$4CBD`-`$4CFF` (screen); `$4DBD`-`$4DFF` (screen); `$4EBD`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun28` (`$891D`)

**the chain from 28 cells**

Witness: L1 288496 (boss, deaths-l7, force, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 288,496 calls (`stage1/rec/l5` 90,624, `stage1/rec/l7` 36,864, `stage1/rec/l8` 33,280 and 9 more) |
| Called from | `l_8869`, `ShiftRun29` (falls into), `ShiftRun1` |
| Calls | `ShiftRun27` (falls into) |
| Reads | `$401C`-`$475F` (screen); `$48BC`-`$4AFF` (screen); `$4BBC`-`$4BFF` (screen); `$4CBC`-`$4CFF` (screen); `$4DBC`-`$4DFF` (screen); `$4EBC`-`$4EFF` (screen); 1 more ranges |
| Writes | `$401C`-`$475F` (screen); `$48BC`-`$4AFF` (screen); `$4BBC`-`$4BFF` (screen); `$4CBC`-`$4CFF` (screen); `$4DBC`-`$4DFF` (screen); `$4EBC`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun27` (`$8920`)

**the chain from 27 cells**

Witness: L1 300088 (boss, deaths-l7, force, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 300,088 calls (`stage1/rec/l5` 91,008, `stage1/rec/l7` 38,400, `stage1/rec/l2` 34,752 and 9 more) |
| Called from | `l_8869`, `ShiftRun28` (falls into), `ShiftRun1` |
| Calls | `ShiftRun26` (falls into) |
| Reads | `$401B`-`$475F` (screen); `$48BB`-`$4AFF` (screen); `$4BBB`-`$4BFF` (screen); `$4CBB`-`$4CFF` (screen); `$4DBB`-`$4DFF` (screen); `$4EBB`-`$4EFF` (screen); 1 more ranges |
| Writes | `$401B`-`$475F` (screen); `$48BB`-`$4AFF` (screen); `$4BBB`-`$4BFF` (screen); `$4CBB`-`$4CFF` (screen); `$4DBB`-`$4DFF` (screen); `$4EBB`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun26` (`$8923`)

**the chain from 26 cells**

Witness: L1 311440 (boss, deaths-l7, force, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 311,440 calls (`stage1/rec/l5` 91,392, `stage1/rec/l7` 39,936, `stage1/rec/l2` 36,288 and 9 more) |
| Called from | `l_8869`, `ShiftRun27` (falls into), `ShiftRun1` |
| Calls | `ShiftRun25` (falls into) |
| Reads | `$401A`-`$475F` (screen); `$48BA`-`$4AFF` (screen); `$4BBA`-`$4BFF` (screen); `$4CBA`-`$4CFF` (screen); `$4DBA`-`$4DFF` (screen); `$4EBA`-`$4EFF` (screen); 1 more ranges |
| Writes | `$401A`-`$475F` (screen); `$48BA`-`$4AFF` (screen); `$4BBA`-`$4BFF` (screen); `$4CBA`-`$4CFF` (screen); `$4DBA`-`$4DFF` (screen); `$4EBA`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun25` (`$8926`)

**the chain from 25 cells**

Witness: L1 349464 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 752 calls, 15,871 t-states own (0.00 %) |
| Runs (the other recordings) | 348,712 calls (`stage1/rec/l5` 91,776, `stage1/rec/l7` 41,728, `stage1/rec/l2` 38,528 and 16 more) |
| Called from | `l_8869`, `ShiftRun26` (falls into), `ShiftRun1` |
| Calls | `ShiftRun24` (falls into) |
| Reads | `$4019`-`$479F` (screen); `$48B9`-`$4AFF` (screen); `$4BB9`-`$4BFF` (screen); `$4CB9`-`$4CFF` (screen); `$4DB9`-`$4DFF` (screen); `$4EB9`-`$4EFF` (screen); 1 more ranges |
| Writes | `$4019`-`$479F` (screen); `$48B9`-`$4AFF` (screen); `$4BB9`-`$4BFF` (screen); `$4CB9`-`$4CFF` (screen); `$4DB9`-`$4DFF` (screen); `$4EB9`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun24` (`$8929`)

**the chain from 24 cells**

Witness: L1 374656 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,008 calls, 20,628 t-states own (0.00 %) |
| Runs (the other recordings) | 373,648 calls (`stage1/rec/l5` 92,160, `stage1/rec/l7` 43,968, `stage1/rec/l2` 41,280 and 16 more) |
| Called from | `l_8869`, `ShiftRun25` (falls into), `ShiftRun1` |
| Calls | `ShiftRun23` (falls into) |
| Reads | `$4018`-`$47BF` (screen); `$489F`-`$4AFF` (screen); `$4B9F`-`$4BFF` (screen); `$4C9F`-`$4CFF` (screen); `$4D9F`-`$4DFF` (screen); `$4E9F`-`$4EFF` (screen); 1 more ranges |
| Writes | `$4018`-`$47BF` (screen); `$489F`-`$4AFF` (screen); `$4B9F`-`$4BFF` (screen); `$4C9F`-`$4CFF` (screen); `$4D9F`-`$4DFF` (screen); `$4E9F`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun23` (`$892C`)

**the chain from 23 cells**

Witness: L1 397144 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,264 calls, 25,891 t-states own (0.00 %) |
| Runs (the other recordings) | 395,880 calls (`stage1/rec/l5` 92,544, `stage1/rec/l7` 45,568, `stage1/rec/l2` 43,264 and 16 more) |
| Called from | `l_8869`, `ShiftRun24` (falls into), `ShiftRun1` |
| Calls | `ShiftRun22` (falls into) |
| Reads | `$4017`-`$47BF` (screen); `$489E`-`$4AFF` (screen); `$4B9E`-`$4BFF` (screen); `$4C9E`-`$4CFF` (screen); `$4D9E`-`$4DFF` (screen); `$4E9E`-`$4EFF` (screen); 1 more ranges |
| Writes | `$4017`-`$47BF` (screen); `$489E`-`$4AFF` (screen); `$4B9E`-`$4BFF` (screen); `$4C9E`-`$4CFF` (screen); `$4D9E`-`$4DFF` (screen); `$4E9E`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun22` (`$892F`)

**the chain from 22 cells**

Witness: L1 420184 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,520 calls, 31,246 t-states own (0.00 %) |
| Runs (the other recordings) | 418,664 calls (`stage1/rec/l5` 92,928, `stage1/rec/l7` 47,168, `stage1/rec/l2` 45,888 and 16 more) |
| Called from | `l_8869`, `ShiftRun23` (falls into), `ShiftRun1` |
| Calls | `ShiftRun21` (falls into) |
| Reads | `$4016`-`$47FF` (screen); `$489D`-`$4AFF` (screen); `$4B9D`-`$4BFF` (screen); `$4C9D`-`$4CFF` (screen); `$4D9D`-`$4DFF` (screen); `$4E9D`-`$4EFF` (screen); 1 more ranges |
| Writes | `$4016`-`$47FF` (screen); `$489D`-`$4AFF` (screen); `$4B9D`-`$4BFF` (screen); `$4C9D`-`$4CFF` (screen); `$4D9D`-`$4DFF` (screen); `$4E9D`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun21` (`$8932`)

**the chain from 21 cells**

Witness: L1 443376 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,776 calls, 36,737 t-states own (0.00 %) |
| Runs (the other recordings) | 441,600 calls (`stage1/rec/l5` 93,312, `stage1/rec/l7` 48,768, `stage1/rec/l2` 48,384 and 16 more) |
| Called from | `l_8869`, `ShiftRun22` (falls into), `ShiftRun1` |
| Calls | `ShiftRun20` (falls into) |
| Reads | `$4015`-`$47FF` (screen); `$489C`-`$4AFF` (screen); `$4B9C`-`$4BFF` (screen); `$4C9C`-`$4CFF` (screen); `$4D9C`-`$4DFF` (screen); `$4E9C`-`$4EFF` (screen); 1 more ranges |
| Writes | `$4015`-`$47FF` (screen); `$489C`-`$4AFF` (screen); `$4B9C`-`$4BFF` (screen); `$4C9C`-`$4CFF` (screen); `$4D9C`-`$4DFF` (screen); `$4E9C`-`$4EFF` (screen); 1 more ranges |

### `ShiftRun20` (`$8935`)

**the chain from 20 cells**

Witness: L1 478448 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 2,032 calls, 41,989 t-states own (0.00 %) |
| Runs (the other recordings) | 476,416 calls (`stage1/rec/l5` 93,696, `stage1/rec/l7` 51,904, `stage1/rec/l2` 51,328 and 16 more) |
| Called from | `l_8869`, `ShiftRun21` (falls into), `ShiftRun1` |
| Calls | `ShiftRun19` (falls into) |
| Reads | `$4014`-`$481F` (screen); `$4894`-`$4B1F` (screen); `$4B94`-`$4C1F` (screen); `$4C94`-`$4D1F` (screen); `$4D94`-`$4E1F` (screen); `$4E94`-`$4F1F` (screen); 1 more ranges |
| Writes | `$4014`-`$481F` (screen); `$4894`-`$4B1F` (screen); `$4B94`-`$4C1F` (screen); `$4C94`-`$4D1F` (screen); `$4D94`-`$4E1F` (screen); `$4E94`-`$4F1F` (screen); 1 more ranges |

### `ShiftRun19` (`$8938`)

**the chain from 19 cells**

Witness: L1 503472 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 2,288 calls, 47,131 t-states own (0.00 %) |
| Runs (the other recordings) | 501,184 calls (`stage1/rec/l5` 94,080, `stage1/rec/l7` 53,760, `stage1/rec/l2` 53,632 and 16 more) |
| Called from | `l_8869`, `ShiftRun20` (falls into), `ShiftRun1` |
| Calls | `ShiftRun18` (falls into) |
| Reads | `$4013`-`$4B3F` (screen); `$4B93`-`$4C3F` (screen); `$4C93`-`$4D3F` (screen); `$4D93`-`$4E3F` (screen); `$4E93`-`$4F3F` (screen); `$4F93`-`$577F` (screen) |
| Writes | `$4013`-`$4B3F` (screen); `$4B93`-`$4C3F` (screen); `$4C93`-`$4D3F` (screen); `$4D93`-`$4E3F` (screen); `$4E93`-`$4F3F` (screen); `$4F93`-`$577F` (screen) |

### `ShiftRun18` (`$893B`)

**the chain from 18 cells**

Witness: L1 532976 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 2,632 calls, 54,395 t-states own (0.00 %) |
| Runs (the other recordings) | 530,344 calls (`stage1/rec/l5` 94,464, `stage1/rec/l4` 58,184, `stage1/rec/l2` 55,936 and 16 more) |
| Called from | `l_8869`, `ShiftRun19` (falls into), `ShiftRun1` |
| Calls | `ShiftRun17` (falls into) |
| Reads | `$4012`-`$4B5F` (screen); `$4B7F`-`$4C5F` (screen); `$4C7F`-`$4D5F` (screen); `$4D7F`-`$4E5F` (screen); `$4E7F`-`$4F5F` (screen); `$4F7F`-`$577F` (screen) |
| Writes | `$4012`-`$4B5F` (screen); `$4B7F`-`$4C5F` (screen); `$4C7F`-`$4D5F` (screen); `$4D7F`-`$4E5F` (screen); `$4E7F`-`$4F5F` (screen); `$4F7F`-`$577F` (screen) |

### `ShiftRun17` (`$893E`)

**the chain from 17 cells**

Witness: L1 580696 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3,016 calls, 62,187 t-states own (0.00 %) |
| Runs (the other recordings) | 577,680 calls (`stage1/rec/l5` 94,848, `stage1/rec/l4` 67,824, `stage1/rec/l2` 59,776 and 16 more) |
| Called from | `l_8869`, `ShiftRun18` (falls into), `ShiftRun1` |
| Calls | `ShiftRun16` (falls into) |
| Reads | `$400E`-`$577F` (screen) |
| Writes | `$400E`-`$577F` (screen) |

### `ShiftRun16` (`$8941`)

**the chain from 16 cells**

Witness: L1 629912 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3,400 calls, 69,555 t-states own (0.01 %) |
| Runs (the other recordings) | 589,264 calls (`stage1/rec/l5` 95,232, `stage1/rec/l4` 72,304, `stage1/rec/l1` 65,920 and 15 more) |
| Called from | `l_8869`, `ShiftRun17` (falls into), `ShiftRun1` |
| Calls | `ShiftRun15` (falls into) |
| Reads | `$4010`-`$577F` (screen) |
| Writes | `$4010`-`$577F` (screen) |

### `ShiftRun15` (`$8944`)

**the chain from 15 cells**

Witness: L1 718528 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4,296 calls, 88,399 t-states own (0.01 %) |
| Runs (the other recordings) | 676,858 calls (`stage1/rec/l5` 128,704, `stage1/rec/l4` 81,640, `stage1/rec/l1` 74,146 and 16 more) |
| Called from | `l_8869`, `ShiftRun16` (falls into), `ShiftRun1` |
| Calls | `ShiftRun14` (falls into) |
| Reads | `$400F`-`$577F` (screen) |
| Writes | `$400F`-`$577F` (screen) |

### `ShiftRun14` (`$8947`)

**the chain from 14 cells**

Witness: L1 759776 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 5,192 calls, 106,571 t-states own (0.01 %) |
| Runs (the other recordings) | 717,336 calls (`stage1/rec/l5` 132,992, `stage1/rec/l4` 86,536, `docs/integrate/rec/boss` 78,640 and 16 more) |
| Called from | `l_8869`, `ShiftRun15` (falls into), `ShiftRun1` |
| Calls | `ShiftRun13` (falls into) |
| Reads | `$400E`-`$4EFF` (screen); `$4F19`-`$577F` (screen) |
| Writes | `$400E`-`$4EFF` (screen); `$4F19`-`$577F` (screen) |

### `ShiftRun13` (`$894A`)

**the chain from 13 cells**

Witness: L1 818984 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 6,184 calls, 127,052 t-states own (0.01 %) |
| Runs (the other recordings) | 812,800 calls (`stage1/rec/l5` 137,280, `stage1/rec/l4` 96,928, `docs/integrate/rec/boss` 83,120 and 17 more) |
| Called from | `l_8869`, `ShiftRun14` (falls into), `ShiftRun1` |
| Calls | `ShiftRun12` (falls into) |
| Reads | `$400D`-`$577F` (screen) |
| Writes | `$400D`-`$577F` (screen) |

### `ShiftRun12` (`$894D`)

**the chain from 12 cells**

Witness: L1 869872 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 7,208 calls, 148,423 t-states own (0.01 %) |
| Runs (the other recordings) | 862,664 calls (`stage1/rec/l5` 141,568, `stage1/rec/l4` 103,048, `docs/integrate/rec/boss` 87,600 and 17 more) |
| Called from | `l_8869`, `ShiftRun13` (falls into), `ShiftRun1` |
| Calls | `ShiftRun11` (falls into) |
| Reads | `$400C`-`$4EFF` (screen); `$4F17`-`$577F` (screen) |
| Writes | `$400C`-`$4EFF` (screen); `$4F17`-`$577F` (screen) |

### `ShiftRun11` (`$8950`)

**the chain from 11 cells**

Witness: L1 947552 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 8,200 calls, 168,493 t-states own (0.01 %) |
| Runs (the other recordings) | 939,352 calls (`stage1/rec/l5` 145,856, `stage1/rec/l4` 113,000, `stage1/rec/l1` 102,720 and 17 more) |
| Called from | `l_8869`, `ShiftRun12` (falls into), `ShiftRun1` |
| Calls | `ShiftRun10` (falls into) |
| Reads | `$400B`-`$4EFF` (screen); `$4F15`-`$577F` (screen) |
| Writes | `$400B`-`$4EFF` (screen); `$4F15`-`$577F` (screen) |

### `ShiftRun10` (`$8953`)

**the chain from 10 cells**

Witness: L1 1014688 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 9,096 calls, 186,597 t-states own (0.01 %) |
| Runs (the other recordings) | 1,005,592 calls (`stage1/rec/l5` 150,144, `stage1/rec/l4` 126,984, `docs/integrate/rec/boss` 113,728 and 17 more) |
| Called from | `l_8869`, `ShiftRun11` (falls into), `ShiftRun1` |
| Calls | `ShiftRun9` (falls into) |
| Reads | `$400A`-`$577F` (screen) |
| Writes | `$400A`-`$577F` (screen) |

### `ShiftRun9` (`$8956`)

**the chain from 9 cells**

Witness: L1 1212288 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 11,640 calls, 240,808 t-states own (0.02 %) |
| Runs (the other recordings) | 1,200,459 calls (`stage1/rec/l7` 155,840, `stage1/rec/l5` 154,432, `stage1/rec/l4` 141,528 and 17 more) |
| Called from | `l_8869`, `ShiftRun10` (falls into), `ShiftRun1` |
| Calls | `ShiftRun8` (falls into) |
| Reads | `$4009`-`$577F` (screen) |
| Writes | `$4009`-`$577F` (screen) |

### `ShiftRun8` (`$8959`)

**the chain from 8 cells**

Witness: L1 1527280 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 15,192 calls, 314,681 t-states own (0.02 %) |
| Runs (the other recordings) | 1,512,025 calls (`stage1/rec/l2` 188,096, `stage1/rec/l7` 186,112, `stage1/rec/l1` 173,465 and 17 more) |
| Called from | `l_8869`, `ShiftRun9` (falls into), `ShiftRun1` |
| Calls | `ShiftRun7` (falls into) |
| Reads | `$4008`-`$577F` (screen) |
| Writes | `$4008`-`$577F` (screen) |

### `ShiftRun7` (`$895C`)

**the chain from 7 cells**

Witness: L1 2032696 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 30,296 calls, 638,734 t-states own (0.05 %) |
| Runs (the other recordings) | 2,002,022 calls (`stage1/rec/l1` 254,726, `docs/integrate/rec/boss` 254,726, `stage1/rec/l7` 211,136 and 17 more) |
| Called from | `l_8869`, `ShiftRun8` (falls into), `ShiftRun1` |
| Calls | `ShiftRun6` (falls into) |
| Reads | `$4007`-`$577F` (screen) |
| Writes | `$4007`-`$577F` (screen) |

### `ShiftRun6` (`$895F`)

**the chain from 6 cells**

Witness: L1 2289541 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 31,717 calls, 655,439 t-states own (0.05 %) |
| Runs (the other recordings) | 2,253,504 calls (`stage1/rec/l1` 276,912, `docs/integrate/rec/boss` 276,912, `stage1/rec/l7` 248,384 and 16 more) |
| Called from | `l_8869`, `ShiftRun7` (falls into), `ShiftRun1` |
| Calls | `ShiftRun5` (falls into) |
| Reads | `$4006`-`$577F` (screen) |
| Writes | `$4006`-`$577F` (screen); `$91F2` (`ShipDies`) |

### `ShiftRun5` (`$8962`)

**the chain from 5 cells**

Witness: L1 2427765 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 33,013 calls, 682,654 t-states own (0.05 %) |
| Runs (the other recordings) | 2,390,432 calls (`stage1/rec/l1` 296,368, `docs/integrate/rec/boss` 296,368, `stage1/rec/l7` 267,584 and 16 more) |
| Called from | `l_8869`, `ShiftRun6` (falls into), `ShiftRun1` |
| Calls | `ShiftRun4` (falls into) |
| Reads | `$4005`-`$577F` (screen) |
| Writes | `$4005`-`$577F` (screen) |

### `ShiftRun4` (`$8965`)

**the chain from 4 cells**

Witness: L1 2679349 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 34,293 calls, 707,493 t-states own (0.05 %) |
| Runs (the other recordings) | 2,640,736 calls (`stage1/rec/l1` 326,960, `docs/integrate/rec/boss` 326,960, `stage1/rec/l7` 293,696 and 16 more) |
| Called from | `l_8869`, `ShiftRun5` (falls into), `ShiftRun1` |
| Calls | `ShiftRun3` (falls into) |
| Reads | `$4004`-`$577F` (screen) |
| Writes | `$4004`-`$577F` (screen) |

### `ShiftRun3` (`$8968`)

**the chain from 3 cells**

Witness: L1 3179797 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 35,573 calls, 735,738 t-states own (0.05 %) |
| Runs (the other recordings) | 3,139,904 calls (`docs/integrate/rec/boss` 422,080, `stage1/rec/l1` 422,080, `stage1/rec/l6` 329,472 and 16 more) |
| Called from | `l_8869`, `ShiftRun4` (falls into), `ShiftRun1` |
| Calls | `ShiftRun2` (falls into) |
| Reads | `$4003`-`$577F` (screen) |
| Writes | `$4003`-`$577F` (screen) |

### `ShiftRun2` (`$896B`)

**the chain from 2 cells**

Witness: L1 3432452 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 36,820 calls, 758,268 t-states own (0.05 %) |
| Runs (the other recordings) | 3,391,312 calls (`docs/integrate/rec/boss` 444,896, `stage1/rec/l1` 444,896, `stage1/rec/l4` 361,568 and 16 more) |
| Called from | `l_8869`, `ShiftRun3` (falls into), `ShiftRun1` |
| Calls | `ShiftRun1` (falls into) |
| Reads | `$4001`-`$577F` (screen) |
| Writes | `$4001`-`$577F` (screen) |

### `ShiftRun1` (`$896E`)

**the last cell, then the next pixel line**

Witness: L1 3510244 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 37,684 calls, 1,453,899 t-states own (0.10 %) |
| Runs (the other recordings) | 3,415,376 calls (`docs/integrate/rec/boss` 455,776, `stage1/rec/l1` 455,776, `stage1/rec/l4` 371,584 and 15 more) |
| Called from | `l_8869`, `ShiftRun2` (falls into) |
| Calls | `ShiftRun`, `ShiftRun30`, `ShiftRun29`, `ShiftRun28`, `ShiftRun27`, `ShiftRun26`, `ShiftRun25`, `ShiftRun24`, `ShiftRun23`, `ShiftRun22`, `ShiftRun21`, `ShiftRun20`, `ShiftRun19`, `ShiftRun18`, `ShiftRun17`, `ShiftRun16`, `ShiftRun15`, `ShiftRun14`, `ShiftRun13`, `ShiftRun12`, `ShiftRun11`, `ShiftRun10`, `ShiftRun9`, `ShiftRun8`, `ShiftRun7`, `ShiftRun6`, `ShiftRun5`, `ShiftRun4`, `ShiftRun3`, `ShiftRun2`, `ShiftRunDone` |
| Reads | `$4001`-`$577E` (screen) |
| Writes | `$4001`-`$577E` (screen) |

### `ShiftRunDone` (`$8974`)

**Where the chain returns: back into ScrollRows**

Witness: L1 438780 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4,710 calls, 84,894 t-states own (0.01 %) |
| Runs (the other recordings) | 433,962 calls (`stage1/rec/l1` 56,960, `docs/integrate/rec/boss` 56,960, `stage1/rec/l4` 46,448 and 17 more) |
| Called from | `ShiftRun1` |
| Calls | `l_8869` (tail) |

### `Scroll` (`$8979`)

**The scroll's step for this pass**

ScrollRows; FrameCounter + 1, ScrollStep = its low 3 bits. Step 0: the next metatile column (every 4th a new block column: MapColumn + 1), the column buffer flushed into column 31; the other steps cut one metatile of the block column each (CutNextMetatile).

Witness: L1 33318 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 419 calls, 464,968 t-states own (0.03 %) |
| Runs (the other recordings) | 32,899 calls (`stage1/rec/l1` 3,482, `docs/integrate/rec/boss` 3,146, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoop` |
| Calls | `MainLoopPatch`, `CutMetatile`, `CutMetatileMirrored`, `CutMetatileFlipped`, `CutMetatileBoth`, `ScrollRows`, `ScrollAttrs` |
| Reads | `$5E00`-`$5EB3` (`ColumnBuffer`); `$7A82`-`$7A8E` (`ScrollStep`, `MetaColumn`, `MapColumn`, `MapReadPtr` and 7 more); `$8080`-`$80CF` (`RowTable`); `$D4E2`-`$D62B` (`LoaderLeftover+3998`); `$D9CF`-`$DADC` (`LoaderLeftover+5259`); `$E37C`-`$E3F8` (`TitleScreen+1636`); 1 more ranges |
| Writes | `$401F`-`$40FF` (screen); `$411F`-`$41FF` (screen); `$421F`-`$42FF` (screen); `$431F`-`$43FF` (screen); `$441F`-`$44FF` (screen); `$451F`-`$45FF` (screen); 64 more ranges |

### `SetDrawLimit` (`$8A3F`)

**Write B into the four sprite drawers' column limit**

Witness: L1 94 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l2-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 8 calls, 528 t-states own (0.00 %) |
| Runs (the other recordings) | 86 calls (`stage2/rec/deaths-l7` 16, `stage1/rec/continue` 14, `stage1/rec/hiscore` 10 and 13 more) |
| Called from | `DrawFirstScreen` |
| Calls | `SetDrawLimitA` (falls into) |
| Writes | `$8D19` (`l_8D09+16`); `$8D83` (`l_8D75+14`); `$8DEF` (`l_8DE1+14`); `$8E49` (`l_8E3B+14`) |

### `SetDrawLimitA` (`$8A40`)

**SetDrawLimitA**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 8 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 11,370 calls (`docs/integrate/rec/boss` 5,603, `stage1/rec/l1` 5,603, `stage1/rec/l4` 164) |
| Called from | `SetDrawLimit` (falls into), `TitleScreen` |
| Writes | `$8D19` (`l_8D09+16`); `$8D83` (`l_8D75+14`); `$8DEF` (`l_8DE1+14`); `$8E49` (`l_8E3B+14`) |

### `TitleLogo` (`$8A4D`)

**Draw the R-TYPE logo: the letters fly in and settle, with the stars and the scroll running**

Witness: L1 17 (c1, ending, gameover, hiscore, l1-l7).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3 calls, 68,085 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/rec/gameover` 5, `stage1/rec/hiscore` 1, `stage1/rec/l6` 1 and 7 more) |
| Called from | `TitleLoop`, `LoadLevel` |
| Calls | `PlayStars`, `ScrollRows`, `LogoRow`, `DrawGame`, `StarTask`, `WaitFrames`, `FillBlock` |
| Reads | `$73AD`-`$73B2` (`CollapseColumns`) |

### `LogoRow` (`$8AE7`)

**Draw the logo letters along a row, run the stars and the scroll once**

Witness: L1 170 (c1, ending, gameover, hiscore, l1-l7).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 36 calls, 25,056 t-states own (0.00 %) |
| Runs (the other recordings) | 134 calls (`stage1/rec/gameover` 56, `stage1/rec/hiscore` 14, `stage1/rec/ending` 8 and 7 more) |
| Called from | `TitleLogo` |
| Calls | `ScrollRows`, `DrawGame`, `StarTask`, `ClearHits` |

### `ReadControls` (`$8B06`)

**Call the control method's reader through ControlVector**

Witness: L1 36240 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

[Animation: `ReadControls` at work](img/routines/ReadControls.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 9,802 t-states own (0.00 %) |
| Runs (the other recordings) | 35,822 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch`, `Continue`, `InsertHiScore` |
| Calls | `ReadIf2`, `ReadKeys`, `ReadKempston`, `ReadSinclair` |
| Reads | `$74FC`-`$74FD` (`ControlVector`) |

### `ReadIf2` (`$8B0A`)

**Read Interface 2 (half-row `$F7FE`, keys 1-5: XOR `$BF`, AND `$1F`, no table)**

Witness: L1 123263 (c1, ctl-if2, ctl-kempston, ctl-sinclair, gameover, hiscore).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 22,862 calls, 1,025,531 t-states own (0.07 %) |
| Runs (the other recordings) | 100,235 calls (`stage1/rec/gameover` 90,128, `stage1/rec/hiscore` 2,685, `stage1/rec/ctl-if2` 2,474 and 2 more) |
| Called from | `ReadControls`, `SelectControl` |
| Calls | `ControlDetach` (tail) |
| Ports in | `$F7FE` |

### `ReadKeys` (`$8B14`)

**Read the six DefinedKeys into the control bits**

Witness: L1 158840 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 22,863 calls, 4,054,017 t-states own (0.29 %) |
| Runs (the other recordings) | 100,235 calls (`stage1/rec/gameover` 90,128, `stage1/rec/hiscore` 2,685, `stage1/rec/ctl-if2` 2,474 and 2 more) |
| Called from | `ReadControls`, `SelectControl` |
| Writes | `$74FA` (`ControlBits`) |

### `ReadKempston` (`$8B19`)

**Read the Kempston port `$1F` into the control bits**

Witness: L1 123262 (c1, ctl-if2, ctl-kempston, ctl-sinclair, gameover, hiscore).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 22,862 calls, 686,031 t-states own (0.05 %) |
| Runs (the other recordings) | 100,234 calls (`stage1/rec/gameover` 90,128, `stage1/rec/hiscore` 2,685, `stage1/rec/ctl-kempston` 2,474 and 2 more) |
| Called from | `ReadControls`, `SelectControl` |
| Calls | `ControlDetach` (tail) |
| Ports in | `$001F`, `$011F`, `$021F`, `$031F`, `$041F`, `$051F`, `$061F`, `$0E1F`, `$0F1F`, `$101F`, `$111F` |

### `ControlDetach` (`$8B27`)

**ControlDetach**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 68,586 calls, 1,784,414 t-states own (0.13 %) |
| Runs (the other recordings) | 301,202 calls (`stage1/rec/gameover` 270,384, `stage1/rec/hiscore` 8,054, `stage1/rec/ctl-sinclair` 7,589 and 2 more) |
| Called from | `ReadIf2` (tail), `ReadKempston` (tail), `ReadSinclair` (tail) |
| Calls | `ReadDetach` (tail) |

### `ReadSinclair` (`$8B2D`)

**Read the Sinclair joystick (half-row `$EFFE`, keys 6-0, through BitReverse)**

Witness: L1 123264 (c1, ctl-if2, ctl-kempston, ctl-sinclair, gameover, hiscore).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 22,862 calls, 1,734,448 t-states own (0.12 %) |
| Runs (the other recordings) | 100,236 calls (`stage1/rec/gameover` 90,128, `stage1/rec/hiscore` 2,685, `stage1/rec/ctl-sinclair` 2,475 and 2 more) |
| Called from | `ReadControls`, `SelectControl` |
| Calls | `ControlDetach` (tail), `ReadDetach` (falls into), `TestKey` |
| Reads | `$5DAF`-`$5DBF` (`BitReverse+175`); `$5DEF`-`$5DFF` (`BitReverse+239`) |
| Ports in | `$EFFE` |

### `ReadDetach` (`$8B63`)

**ReadDetach**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 91,867 calls, 5,533,991 t-states own (0.40 %) |
| Runs (the other recordings) | 405,666 calls (`stage1/rec/gameover` 362,337, `stage1/rec/hiscore` 13,143, `stage1/rec/ctl-sinclair` 10,063 and 2 more) |
| Called from | `ControlDetach` (tail), `ReadSinclair` (falls into) |
| Calls | `TestKey` |
| Writes | `$74FA` (`ControlBits`) |

### `TestKey` (`$8B70`)

**Read the key (port, mask) at HL: Z when pressed; HL past the pair**

Witness: L1 1322831 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 208,272 calls, 10,573,366 t-states own (0.76 %) |
| Runs (the other recordings) | 1,114,559 calls (`stage1/rec/gameover` 822,102, `stage1/rec/hiscore` 38,588, `stage1/rec/ctl-sinclair` 22,434 and 18 more) |
| Called from | `ReadSinclair`, `ReadDetach` |
| Reads | `$7780`-`$7795` (`DefinedKeys`, `ControlVectors`, `DetachKey`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$FBFE`, `$FDFE` |

### `CheckPause` (`$8B77`)

**Pause: CAPS SHIFT + 1 pauses, CAPS SHIFT + 2 goes on**

Returns at once unless half-row `$FEFE` reads CAPS SHIFT alone (of its low 4 keys) and half-row `$F7FE` key 1 alone. Paused: interrupts off (the sound and stars stop), "GAME PAUSED" printed over and over until CAPS SHIFT and key 2 alone are down; then the text row cleared, interrupts on, DrawHud. There is no abort key: the game only ends when the lives and credits run out.

Witness: L1 33318 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 419 calls, 11,732 t-states own (0.00 %) |
| Runs (the other recordings) | 32,899 calls (`stage1/rec/l1` 3,482, `docs/integrate/rec/boss` 3,146, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoop` |
| Calls | `ReadRow1`, `ReadRow0`, `PrintRow22`, `ClearTextRow`, `DrawHud` (tail) |

### `ReadRow1` (`$8BA0`)

**A = keys 1-4 of half-row `$F7FE` as bits (pressed = 1); Z when key 1 alone**

Witness: L1 68 (pause).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 68 calls (`docs/rtB/rec/pause` 68) |
| Called from | `CheckPause` |
| Calls | `l_8BA6` (tail) |

### `ReadRow0` (`$8BA4`)

**A = CAPS SHIFT, Z, X, C of half-row `$FEFE`; Z when CAPS SHIFT alone**

Witness: L1 34503 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 419 calls, 19,674 t-states own (0.00 %) |
| Runs (the other recordings) | 34,084 calls (`stage1/rec/l1` 3,482, `docs/integrate/rec/boss` 3,146, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `CheckPause` |
| Calls | `l_8BA6` (falls into) |
| Ports in | `$FEFE` |

### `l_8BA6` (`$8BA6`)

**l_8BA6**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 419 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,298 calls (`docs/rtB/rec/pause` 1,298) |
| Called from | `ReadRow1` (tail), `ReadRow0` (falls into) |
| Ports in | `$F7FE`, `$FEFE` |

### `StartPlay` (`$8BAE`)

**Set the ship up for a life**

The first play (FirstPlay 0): ShieldTimer `$38` and the fly-in from the left (ShipEntry 1); later lives: ShieldTimer `$20` at the set place.

Witness: L1 47 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l2-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 570 t-states own (0.00 %) |
| Runs (the other recordings) | 43 calls (`stage2/rec/deaths-l7` 8, `stage1/rec/continue` 7, `stage1/rec/hiscore` 5 and 13 more) |
| Called from | `StartLife` |
| Reads | `$71D1` (`FirstPlay`) |
| Writes | `$71D1` (`FirstPlay`); `$7A98`-`$7AA4` (`ShieldTimer`, `ScoreChanged`, `WaveOverride`, `LevelEndTimer` and 9 more); `$83F2` (`ShipEntry`); `$95A5` (`ShieldControls`) |

### `Continue` (`$8BE8`)

**The CONTINUE screen: count down while fire may be pressed**

Witness: L1 3 (continue, gameover, hiscore).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/hiscore` 1, `stage1/rec/gameover` 1, `stage1/rec/continue` 1) |
| Called from | `LoseLife` |
| Calls | `ReadControls`, `BigDigit`, `PrintTextNormal`, `PlaySound`, `WaitFrames`, `FillBlock`, `ClearScreen` |
| Reads | `$72EB` (`ContinueRow`); `$7A89` (`FrameCounter`) |
| Writes | `$5A60` (screen); `$72EB` (`ContinueRow`); `$7A89` (`FrameCounter`) |

### `BigDigit` (`$8C5C`)

**Draw the countdown digit as block characters**

Witness: L1 21 (continue, gameover, hiscore).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21 calls (`stage1/rec/hiscore` 10, `stage1/rec/gameover` 10, `stage1/rec/continue` 1) |
| Called from | `Continue` |
| Calls | `PrintTextNormal` |
| Reads | `$7B68`-`$7BB7` (`Font+120`) |

### `ShipFlyIn` (`$8C8B`)

**Move the ship in at the first start (ShipEntry 1, then 2), then hand it to the controls**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 18,665 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `ShipShield`, `DrawGame` |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$83F2` (`ShipEntry`) |
| Writes | `$7AA1`-`$7AA4` (`ShipColumn`, `ShipRow`, `ForceAttached`, `ShipFrame`); `$83F2` (`ShipEntry`); `$95A5` (`ShieldControls`) |

### `Silence` (`$8CC5`)

**Meant to stop the three channels; frees channel 3 only (bits `$82` and `$81` mean the first free channel, which is channel 3 again)**

Witness: L1 46 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 484 t-states own (0.00 %) |
| Runs (the other recordings) | 42 calls (`stage1/rec/continue` 8, `stage1/rec/hiscore` 7, `stage2/rec/deaths-l7` 7 and 6 more) |
| Called from | `NewGameState`, `LoseLife` |
| Calls | `PlaySound` |

### `ScrollAttrs` (`$8CD8`)

**Scroll the attribute shadow and the solid map one cell left (unless ScrollHalted)**

Witness: L1 4150 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 50 calls, 4,693 t-states own (0.00 %) |
| Runs (the other recordings) | 4,100 calls (`stage1/rec/l1` 436, `docs/integrate/rec/boss` 394, `stage1/rec/l3` 372 and 18 more) |
| Called from | `Scroll` |
| Calls | `ScrollAttrRows` (falls into) |
| Reads | `$7A8E` (`ScrollHalted`) |

### `ScrollAttrRows` (`$8CF0`)

**LDIR a run of each of A rows of 32**

Witness: L1 134640 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 100 calls, 1,718,803 t-states own (0.12 %) |
| Runs (the other recordings) | 6,632 calls (`docs/integrate/rec/boss` 744, `stage1/rec/l1` 744, `stage1/rec/l4` 528 and 17 more) |
| Called from | `ScrollAttrs` (falls into) |
| Reads | `$7802`-`$7A7F` (`PlayAttrs+2`); `$7E02`-`$807F` (`SolidMap+2`, `EntryCopySource`) |
| Writes | `$7801`-`$7A7E` (`PlayAttrs+1`); `$7E01`-`$807E` (`SolidMap+1`, `EntryCopySource`) |

## sprites

`src/game/sprites.asm`

### `DrawSprite` (`$8CFD`)

**Draw an object (D, E its size, HL its cells) at row B column C into the shadows and SolidMap**

Each cell is 9 bytes (attribute, 8 pixel lines). A cell off the play field is skipped. CellFree decides whether it may be drawn over what is there; CellMark writes DrawTag into SolidMap and the attribute into PlayAttrs; the pixel bytes go to the pixel shadow. While DrawPrepare has the hits on, what was there is gathered into HitList.

Witness: L1 503586 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

[Animation: `DrawSprite` at work](img/routines/DrawSprite.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 2,226 calls, 7,301,261 t-states own (0.53 %) |
| Runs (the other recordings) | 501,360 calls (`stage1/rec/l3` 72,819, `stage1/rec/l4` 62,644, `stage1/rec/l2` 55,765 and 18 more) |
| Called from | `MoveDrawA`, `ShipShield`, `DrawGame`, `FireBeam`, `DrawCellBlast`, `MoveEnemyShots`, `DrawExplosions`, `TitleScreen`, `DrawFirstScreen` |
| Calls | `CellMark`, `CellFree` |
| Reads | `$A604`-`$BC5D` (`Sprites`); `$C4E0`-`$DD84` (`LevelMoves2+30`, `LoaderLeftover`, `TitleScreen`); `$DDD2`-`$E761` (`TitleScreen+186`) |
| Writes | `$4001`-`$507F` (screen); `$5101`-`$517F` (screen); `$5201`-`$527F` (screen); `$5301`-`$537F` (screen); `$5401`-`$547F` (screen); `$5501`-`$557F` (screen); 10 more ranges |

### `DrawSpriteMirrored` (`$8D65`)

**Draw an object mirrored left to right**

Witness: L1 31638 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 8 calls, 53,326 t-states own (0.00 %) |
| Runs (the other recordings) | 31,630 calls (`stage1/rec/l1` 4,884, `stage1/rec/l2` 4,375, `docs/integrate/rec/boss` 4,348 and 17 more) |
| Called from | `MoveDrawA`, `DrawGameMirrored`, `TitleScreen`, `DrawFirstScreen` |
| Calls | `CellMark`, `CellFree` |
| Reads | `$5D00`-`$5DFF` (`BitReverse`); `$A7EB`-`$A988` (`Sprites+487`); `$B091`-`$B32D` (`Sprites+2701`); `$C4E9`-`$CEE0` (`LevelMoves2+39`, `LoaderLeftover`); `$CF89`-`$D0DF` (`LoaderLeftover+2629`); `$D12F`-`$D17F` (`LoaderLeftover+3051`); 5 more ranges |
| Writes | `$4814`-`$4877` (screen); `$488C`-`$4896` (screen); `$48AC`-`$48AF` (screen); `$48C3`-`$48CF` (screen); `$48E3`-`$48FA` (screen); `$4914`-`$4977` (screen); 49 more ranges |

### `DrawSpriteFlipped` (`$8DD3`)

**Draw an object upside down**

Witness: L1 31842 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 184 calls, 515,899 t-states own (0.04 %) |
| Runs (the other recordings) | 31,658 calls (`stage1/rec/l3` 5,933, `stage1/rec/l1` 5,238, `docs/integrate/rec/boss` 4,546 and 18 more) |
| Called from | `MoveDrawA`, `ShipShield`, `DrawGameFlipped`, `TitleScreen`, `DrawFirstScreen` |
| Calls | `CellMark`, `CellFree` |
| Reads | `$AACD`-`$ACEA` (`Sprites+1225`); `$B24C`-`$B2F5` (`Sprites+3144`); `$B94E`-`$B95F` (`Sprites+4938`); `$C4E9`-`$C89E` (`LevelMoves2+39`, `LoaderLeftover`); `$C8EE`-`$CDEC` (`LoaderLeftover+938`); `$CEC5`-`$CF88` (`LoaderLeftover+2433`); 6 more ranges |
| Writes | `$4001`-`$47FF` (screen); `$4810`-`$487F` (screen); `$489C`-`$48FF` (screen); `$4910`-`$4FFF` (screen); `$6004`-`$707C` (`ShadowLine0`); `$7101`-`$777C` (`ShadowLine1+1`, `HiScoreLabel`, `BeamLabel`, `LifeChar` and 47 more) |

### `DrawSpriteBoth` (`$8E29`)

**Draw an object mirrored and upside down**

Witness: L1 16125 (boss, deaths-l7, ending, force, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16,125 calls (`stage1/rec/l1` 3,552, `stage1/rec/l3` 2,785, `stage1/rec/l5` 2,475 and 10 more) |
| Called from | `MoveDrawA`, `DrawGameBoth`, `TitleScreen`, `DrawFirstScreen` |
| Calls | `CellMark`, `CellFree` |
| Reads | `$5D00`-`$5DFF` (`BitReverse`); `$B091`-`$B32D` (`Sprites+2701`); `$BB86`-`$BC27` (`Sprites+5506`); `$C4FD`-`$C55C` (`LevelMoves2+59`, `LoaderLeftover`); `$C645`-`$C6B0` (`LoaderLeftover+257`); `$C80B`-`$C89E` (`LoaderLeftover+711`); 9 more ranges |
| Writes | `$4010`-`$40E4` (screen); `$4110`-`$47E4` (screen); `$6001`-`$7078` (`ShadowLine0`); `$7101`-`$7478` (`ShadowLine1+1`, `HiScoreLabel`, `BeamLabel`, `LifeChar` and 32 more); `$7501`-`$7578` (`ShadowLine4Tail+3`); `$7601`-`$7678` (`ShadowLine5+12`); 1 more ranges |

### `LevelObject` (`$8E85`)

**D, E, HL = the size and cells of the level's object A (LevelObjects)**

Witness: L1 233581 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 457 calls, 13,710 t-states own (0.00 %) |
| Runs (the other recordings) | 233,124 calls (`stage1/rec/l3` 58,884, `stage1/rec/l1` 37,808, `docs/integrate/rec/boss` 27,284 and 17 more) |
| Called from | `MoveDrawA`, `DrawPrepare`, `DrawCellBlast`, `MoveEnemyShots`, `TitleScreen` |
| Calls | `ObjectEntry` (tail) |
| Reads | `$C4BA`-`$C4BB` (`LevelObjects`) |

### `GameObject` (`$8E8C`)

**D, E, HL = the size and cells of the game's object A (GameObjects)**

Witness: L1 347730 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,801 calls, 43,100 t-states own (0.00 %) |
| Runs (the other recordings) | 345,929 calls (`stage1/rec/l4` 56,626, `stage1/rec/l2` 46,922, `stage1/rec/l5` 46,262 and 18 more) |
| Called from | `ShipShield`, `DrawPrepare`, `FireBeam`, `DrawExplosions` |
| Calls | `ObjectEntry` (falls into) |
| Reads | `$BC6F`-`$BC76` (`GameObjects+8`); `$BDEB`-`$BDEE` (`GameObjects+388`) |
| Writes | `$7A9C` (`DrawTag`) |

### `ObjectEntry` (`$8E92`)

**ObjectEntry**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 2,258 calls, 243,921 t-states own (0.02 %) |
| Runs (the other recordings) | 578,963 calls (`stage1/rec/l3` 84,661, `stage1/rec/l2` 65,712, `stage1/rec/l4` 64,185 and 17 more) |
| Called from | `LevelObject` (tail), `GameObject` (falls into) |
| Reads | `$BC6B`-`$BE22` (`GameObjects+4`); `$CC33`-`$CCB6` (`LoaderLeftover+1775`); `$D14E`-`$D227` (`LoaderLeftover+3082`); `$D372`-`$D389` (`LoaderLeftover+3630`); `$D3AE`-`$D441` (`LoaderLeftover+3690`); `$D7F9`-`$D910` (`LoaderLeftover+4789`); 4 more ranges |

### `CellMark` (`$8EA2`)

**Write DrawTag into the SolidMap cell and the attribute into PlayAttrs**

Witness: L1 1798477 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 15,836 calls, 2,084,078 t-states own (0.15 %) |
| Runs (the other recordings) | 1,782,641 calls (`stage1/rec/l3` 216,110, `stage1/rec/l4` 201,721, `stage1/rec/l1` 200,223 and 18 more) |
| Called from | `DrawSprite`, `DrawSpriteMirrored`, `DrawSpriteFlipped`, `DrawSpriteBoth` |
| Reads | `$7A9C` (`DrawTag`); `$8EB1` (`CellMark+15`); `$A604`-`$BB56` (`Sprites`); `$C4E0`-`$DD7C` (`LevelMoves2+30`, `LoaderLeftover`, `TitleScreen`); `$DDD2`-`$E759` (`TitleScreen+186`) |
| Writes | `$7801`-`$7A7F` (`PlayAttrs+1`); `$7E01`-`$807F` (`SolidMap+1`, `EntryCopySource`) |

### `CellFree` (`$8EC2`)

**Carry when the cell at row B column C may be drawn on; a taken cell may be gathered as a hit**

Reads SolidMap (`$7E00` + row x 32 + column). A taken cell returns at the RET here unless DrawPrepare made it a NOP: then the tag goes into HitList (14 at most) and a soft cell's (`$FA`) position into HitCells.

Witness: L1 2335443 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 20,295 calls, 3,163,928 t-states own (0.23 %) |
| Runs (the other recordings) | 2,315,148 calls (`stage1/rec/l3` 288,027, `stage1/rec/l2` 255,834, `stage1/rec/l1` 252,190 and 18 more) |
| Called from | `DrawSprite`, `DrawSpriteMirrored`, `DrawSpriteFlipped`, `DrawSpriteBoth` |
| Reads | `$71E0` (`HitCellCount`); `$7A82` (`ScrollStep`); `$7A95` (`HitCount`); `$7E00`-`$8080` (`SolidMap`, `RowTable`) |
| Writes | `$71E0`-`$71EC` (`HitCellCount`, `HitCells`); `$7A95` (`HitCount`); `$7AD8`-`$7AE5` (`HitList+1`) |

## tapeload

`src/game/tapeload.asm`

### `LoadBytes` (`$8F1F`)

**Load DE bytes to IX from tape at the game's turbo speed**

Interrupts off; pushes LoadDone so that every return enables interrupts again; waits for the pilot and the sync, then reads the flag and the bytes with the border stripes; carry set when the check byte is right.

Witness: L1 32 (c1, deaths-l7, ending, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 2 calls, 8,103,351 t-states own (0.58 %) |
| Runs (the other recordings) | 30 calls (`stage1/rec/l3` 4, `stage1/rec/l4` 4, `stage1/rec/l2` 4 and 7 more) |
| Called from | `LoadLevelStart` |
| Calls | `EdgePair`, `EdgeOne`, `LoadDone` |
| Writes | `$6000`-`$6011` (system); `$8FB4` (`EdgeLoop+17`); `$C4AE`-`$F859` (`LevelSpace`, `LoaderLeftover`, `TitleScreen`, `LevelSpaceTail`) |
| Ports in | `$0FFE` |
| Ports out | `$0FFE` |

### `EdgePair` (`$8F9E`)

**Wait for two edges**

Witness: L1 893818 (c1, deaths-l7, ending, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 108,988 calls, 2,412,592 t-states own (0.17 %) |
| Runs (the other recordings) | 784,830 calls (`stage1/rec/l3` 107,964, `stage1/rec/l7` 107,896, `stage1/rec/l4` 107,356 and 7 more) |
| Called from | `LoadBytes` |
| Calls | `EdgeOne` (falls into) |

### `EdgeOne` (`$8FA2`)

**Wait for one edge on the EAR bit, counting B; carry when found**

Each edge flips the border: AND (patched at `$8FB4`: `$02` pilot and sync, `$01` data) OR `$08`: red/black, then blue/black.

Witness: L1 1866762 (c1, deaths-l7, ending, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 220,902 calls, 179,374,974 t-states own (12.91 %) |
| Runs (the other recordings) | 1,645,860 calls (`stage1/rec/l7` 224,767, `stage1/rec/l3` 224,434, `stage1/rec/l4` 223,214 and 7 more) |
| Called from | `LoadBytes`, `EdgePair` (falls into) |
| Ports in | `$7FFE` |
| Ports out | `$08FE`, `$09FE`, `$0AFE` |

## waves

`src/game/waves.asm`

### `SlotFlags` (`$8FCB`)

**The enemy slot's hits left**

Witness: L1 65244 (boss, c1, continue, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 9 calls, 693 t-states own (0.00 %) |
| Runs (the other recordings) | 65,235 calls (`stage1/rec/l3` 28,176, `stage1/rec/l7` 6,256, `stage1/rec/l4` 5,657 and 14 more) |
| Called from | `StartWave`, `DrawTrail`, `SolidTest`, `HitEnemy`, `MoveEnemyShots`, `TitleScreen` |
| Reads | `$8501`-`$85FE` (`EnemySlots`, `Entry`) |

### `RunWaves` (`$8FDD`)

**Start the waves the script has reached**

Unless WavesHalted: while the entry at WavePtr matches the scroll's position, takes its kind (a command when `$63`: CommandWave) and script and starts it (StartWave).

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 71,230 t-states own (0.01 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `RunWavesNext` (falls into) |
| Reads | `$7800`-`$7A9A` (`PlayAttrs`, `GameVars`); `$8501`-`$85C7` (`EnemySlots`); `$C4BE`-`$C4BF` (`LevelKinds`); `$DADD`-`$DEC3` (`LoaderLeftover+5529`, `TitleScreen`); `$DEFF`-`$DF39` (`TitleScreen+487`); `$DF50`-`$DFA1` (`TitleScreen+568`); 15 more ranges |
| Writes | `$5800`-`$5A7F` (screen); `$7A8E`-`$7A9E` (`ScrollHalted`, `WavesHalted`, `WavePtr`, `TextHeight` and 10 more); `$8501`-`$85EA` (`EnemySlots`); `$8F0B`-`$8F0C` (`CellFreeEmpty`) |

### `RunWavesNext` (`$8FE2`)

**RunWavesNext**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 447 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 23,987 calls (`stage1/rec/l1` 3,744, `docs/integrate/rec/boss` 3,255, `stage1/rec/l3` 3,071 and 8 more) |
| Called from | `RunWaves` (falls into), `StartWaveDone` (tail) |
| Calls | `StartWave` (falls into), `CommandWave` (tail) |
| Reads | `$7A82`-`$7A91` (`ScrollStep`, `MetaColumn`, `MapColumn`, `MapReadPtr` and 9 more); `$D62C`-`$DA5A` (`LoaderLeftover+4328`); `$E693`-`$ED01` (`TitleScreen+2427`) |
| Writes | `$7A90`-`$7A91` (`WavePtr`) |

### `StartWave` (`$9013`)

**Put enemy kind A with its movement script into a free slot**

The kind's record from LevelKinds; WaveOverride picks the slot; no free slot: the wave is dropped.

Witness: L1 3151 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

[Animation: `StartWave` at work](img/routines/StartWave.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 26 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,347 calls (`stage1/rec/l7` 478, `stage1/rec/l1` 364, `docs/integrate/rec/boss` 314 and 8 more) |
| Called from | `RunWavesNext` (falls into), `StartWaveAt` |
| Calls | `SlotFlags`, `StartWaveDone` (falls into) |
| Reads | `$7A9A` (`WaveOverride`); `$8501`-`$85D0` (`EnemySlots`); `$C4BE`-`$C4BF` (`LevelKinds`); `$DA5F`-`$DB11` (`LoaderLeftover+5403`); `$DB42`-`$DB46` (`LoaderLeftover+5630`); `$DB77`-`$DBA6` (`LoaderLeftover+5683`); 16 more ranges |
| Writes | `$7A9A` (`WaveOverride`); `$8501`-`$85FC` (`EnemySlots`) |

### `StartWaveDone` (`$908F`)

**StartWaveDone**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 29 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,540 calls (`stage1/rec/l7` 500, `stage1/rec/l1` 398, `docs/integrate/rec/boss` 346 and 8 more) |
| Called from | `StartWave` (falls into), `CommandWave` (tail) |
| Calls | `RunWavesNext` (tail) |

### `CommandWave` (`$9093`)

**A wave command: 1 halt the scroll (a boss), 2 resume, 3 next slot, 4 shooter limit, 5 the level's end, 6 a sound**

Witness: L1 271 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 193 calls (`stage1/rec/l3` 45, `stage1/rec/l1` 34, `docs/integrate/rec/boss` 32 and 8 more) |
| Called from | `RunWavesNext` (tail) |
| Calls | `ClearSides`, `StartWaveDone` (tail), `PlaySound` |
| Reads | `$7800`-`$7A7F` (`PlayAttrs`); `$D62F`-`$D630` (`LoaderLeftover+4331`); `$D814`-`$D824` (`LoaderLeftover+4816`); `$D841`-`$D842` (`LoaderLeftover+4861`); `$D9D1`-`$D9D7` (`LoaderLeftover+5261`); `$DA58` (`LoaderLeftover+5396`); 16 more ranges |
| Writes | `$5800`-`$5A7F` (screen); `$7A8E`-`$7A9E` (`ScrollHalted`, `WavesHalted`, `WavePtr`, `TextHeight` and 10 more); `$8F0B`-`$8F0C` (`CellFreeEmpty`) |

### `ResumeWaves` (`$90F7`)

**Clear ScrollHalted and WavesHalted and restore CellFreeEmpty's code**

Witness: L1 64 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 7 calls, 569 t-states own (0.00 %) |
| Runs (the other recordings) | 57 calls (`stage1/rec/gameover` 9, `stage2/rec/deaths-l7` 8, `stage1/rec/continue` 7 and 15 more) |
| Called from | `ClearPlayState` |
| Writes | `$7A8E`-`$7A8F` (`ScrollHalted`, `WavesHalted`); `$8F0B`-`$8F0C` (`CellFreeEmpty`) |

### `MoveEnemies` (`$9109`)

**Move every live enemy slot by its kind's movers**

For each slot: DrawTag = `$80` + slot; the script's step; then the kind's first mover from LevelMoves and its second from LevelMoves2: the levels' own code, which comes back to MoveStore, MoveDraw, MoveDrawA, MoveNext or MoveDone.

Witness: L1 33321 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

[Animation: `MoveEnemies` at work](img/routines/MoveEnemies.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 18,484 t-states own (0.00 %) |
| Runs (the other recordings) | 32,903 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `MoveEnemiesSlot` (falls into) |
| Reads | `$7A8F` (`WavesHalted`); `$8501`-`$85FC` (`EnemySlots`) |

### `MoveEnemiesSlot` (`$9114`)

**MoveEnemiesSlot**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 11,704 calls, 851,750 t-states own (0.06 %) |
| Runs (the other recordings) | 917,016 calls (`stage1/rec/l1` 97,524, `docs/integrate/rec/boss` 85,092, `stage1/rec/l3` 83,328 and 17 more) |
| Called from | `MoveEnemies` (falls into), `MoveEnemiesNext` (tail) |
| Calls | `MoveEnemiesNext` (falls into) |
| Reads | `$7A9C` (`DrawTag`); `$8501`-`$85FC` (`EnemySlots`); `$C4C0`-`$C4C1` (`LevelMoves`); `$DF3C`-`$DFCB` (`TitleScreen+548`); `$DFFC`-`$E1AB` (`TitleScreen+740`); `$E3D4`-`$E495` (`TitleScreen+1724`); 4 more ranges |
| Writes | `$7A9C` (`DrawTag`) |

### `MoveEnemiesNext` (`$9121`)

**MoveEnemiesNext**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 11,704 calls, 610,755 t-states own (0.04 %) |
| Runs (the other recordings) | 917,017 calls (`stage1/rec/l1` 97,524, `docs/integrate/rec/boss` 85,092, `stage1/rec/l3` 83,328 and 17 more) |
| Called from | `MoveEnemiesSlot` (falls into), `MoveSlotEnd` (tail) |
| Calls | `MoveEnemiesSlot` (tail), `TableEntry`, `EnemyHit`, `EnemyFire`, `MoveByBits`, `TitleScreen` |

### `MoveStore` (`$9168`)

**MoveStore**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 434 calls, 16,511 t-states own (0.00 %) |
| Runs (the other recordings) | 143,440 calls (`stage1/rec/l3` 42,659, `stage1/rec/l1` 16,523, `stage1/rec/l2` 15,709 and 17 more) |
| Called from | `TitleScreen` (tail) |
| Calls | `MoveDraw` (falls into) |
| Writes | `$8504`-`$85EF` (`EnemySlots+3`) |

### `MoveDraw` (`$916E`)

**MoveDraw**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 457 calls, 53,731 t-states own (0.00 %) |
| Runs (the other recordings) | 173,867 calls (`stage1/rec/l3` 44,289, `stage1/rec/l1` 23,567, `docs/integrate/rec/boss` 19,336 and 17 more) |
| Called from | `MoveStore` (falls into), `TitleScreen` (tail) |
| Calls | `MoveDrawA` (falls into) |
| Reads | `$8506`-`$852A` (`EnemySlots+5`); `$C4C2`-`$C4C3` (`LevelMoves2`); `$DF3D`-`$DFCB` (`TitleScreen+549`); `$DFFD`-`$E07B` (`TitleScreen+741`); `$E3D5`-`$E495` (`TitleScreen+1725`); `$E4B1`-`$E609` (`TitleScreen+1945`); 3 more ranges |

### `MoveDrawA` (`$916F`)

**MoveDrawA**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 457 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 61,887 calls (`stage1/rec/l1` 24,193, `docs/integrate/rec/boss` 19,962, `stage1/rec/l2` 17,732) |
| Called from | `MoveDraw` (falls into), `TitleScreen` (tail) |
| Calls | `DrawSprite`, `DrawSpriteMirrored`, `DrawSpriteFlipped`, `DrawSpriteBoth`, `LevelObject`, `MoveNext` (falls into) |

### `MoveNext` (`$9195`)

**MoveNext**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 461 calls, 36,419 t-states own (0.00 %) |
| Runs (the other recordings) | 185,478 calls (`stage1/rec/l3` 44,303, `stage1/rec/l1` 28,627, `docs/integrate/rec/boss` 24,396 and 14 more) |
| Called from | `MoveDrawA` (falls into), `TitleScreen` (tail) |
| Calls | `TableEntry`, `TitleScreen` |
| Reads | `$8501`-`$85F0` (`EnemySlots`); `$C4C2`-`$C4C3` (`LevelMoves2`) |

### `MoveScript` (`$91A5`)

**MoveScript**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 438 calls, 36,075 t-states own (0.00 %) |
| Runs (the other recordings) | 161,076 calls (`stage1/rec/l3` 45,153, `stage1/rec/l1` 21,358, `docs/integrate/rec/boss` 17,677 and 17 more) |
| Called from | `TitleScreen` (tail) |
| Calls | `MoveDone` (falls into) |
| Reads | `$8501`-`$85FC` (`EnemySlots`); `$DA64`-`$DA98` (`LoaderLeftover+5408`); `$DAC1`-`$DB60` (`LoaderLeftover+5501`); `$DB81`-`$DBA1` (`LoaderLeftover+5693`); `$DC1E`-`$DC48` (`LoaderLeftover+5850`); `$DC7E`-`$DCD9` (`LoaderLeftover+5946`); 13 more ranges |
| Writes | `$8501`-`$85FC` (`EnemySlots`) |

### `MoveDone` (`$91B1`)

**MoveDone**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 412 calls, 4,944 t-states own (0.00 %) |
| Runs (the other recordings) | 166,516 calls (`stage1/rec/l3` 47,614, `stage1/rec/l1` 23,678, `docs/integrate/rec/boss` 21,057 and 17 more) |
| Called from | `MoveScript` (falls into), `TitleScreen` (tail) |
| Calls | `MoveSlotEnd` (tail) |

### `MoveSlotEnd` (`$91DC`)

**MoveSlotEnd**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 461 calls, 9,220 t-states own (0.00 %) |
| Runs (the other recordings) | 201,245 calls (`stage1/rec/l3` 49,735, `stage1/rec/l1` 30,040, `docs/integrate/rec/boss` 24,969 and 17 more) |
| Called from | `MoveDone` (tail) |
| Calls | `MoveEnemiesNext` (tail) |

### `TableEntry` (`$91E6`)

**HL = the word at HL + 2 x A**

Witness: L1 388175 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 922 calls, 56,261 t-states own (0.00 %) |
| Runs (the other recordings) | 387,253 calls (`stage1/rec/l3` 94,038, `stage1/rec/l1` 58,667, `docs/integrate/rec/boss` 49,365 and 17 more) |
| Called from | `MoveEnemiesNext`, `MoveNext` |
| Reads | `$E1AC`-`$E1CD` (`TitleScreen+1172`); `$E1DE`-`$E1E7` (`TitleScreen+1222`); `$E612`-`$E621` (`TitleScreen+2298`); `$E636`-`$E63F` (`TitleScreen+2334`); `$EEAE`-`$EEE9` (`TitleScreen+4502`); `$F0A6`-`$F0E1` (`TitleScreen+5006`); 3 more ranges |

### `ShipDies` (`$91F2`)

**The ship is hit: a life off, the explosion, DeathTimer 32**

Three ways in: JP NC at `$956D` (scenery ahead of the ship, GetCell), JP NZ at `$9574` (an enemy's cell), JP at `$C3CE` (an enemy shot, MoveEnemyShots). Without the immortality POKE: gameover, continue and hiscore (level 1) (and c1) take `$9574` 2-6 times and `$956D` 0-1 times, `$C3CE` never; deaths-l7 (level 7, the stage 1 POKE undone, 8390 frames) takes `$956D` 4 times, `$9574` once and runs `$C3CE` 3 times: 8 lives, 8 runs of ShipDies.

`$91F5` is a NOP in play; a RET there makes the ship immortal (BossDestroyed and the end of level 8 put it there, ClearPlayState `$8707` puts the NOP back at every level load and life; the immortality POKE of the stage 1 recordings writes `$C9` at `$91F2`).

Witness: L1 7575 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

[Animation: `ShipDies` at work](img/routines/ShipDies.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3 calls, 560 t-states own (0.00 %) |
| Runs (the other recordings) | 7,572 calls (`stage1/rec/l3` 1,687, `stage1/rec/l2` 1,378, `stage1/rec/l1` 880 and 17 more) |
| Called from | `MoveShip` (tail), `MoveEnemyShots` (tail) |
| Calls | `ClearShipStuff` (falls into), `ClearHits`, `PlaySound` |
| Reads | `$7AA0`-`$7AA2` (`Lives`, `ShipColumn`, `ShipRow`) |
| Writes | `$5FC1`-`$5FC3` (`Explosions`); `$7A8D` (`DeathTimer`); `$7AA0` (`Lives`) |

### `ClearShipStuff` (`$9218`)

**Clear the ship's, the shots' and the enemy shots' state**

Witness: L1 85 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 6 calls, 726 t-states own (0.00 %) |
| Runs (the other recordings) | 79 calls (`stage2/rec/deaths-l7` 15, `stage1/rec/continue` 14, `stage1/rec/hiscore` 12 and 6 more) |
| Called from | `ShipDies` (falls into), `LoseLife` |
| Calls | `ClearBlock` |

### `DrawLives` (`$9234`)

**Print LifeChar A times from column C leftwards, then a blank**

Witness: L1 335 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, pause, restart, l2-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 7 calls, 2,133 t-states own (0.00 %) |
| Runs (the other recordings) | 89 calls (`stage2/rec/deaths-l7` 15, `stage1/rec/continue` 14, `stage1/rec/hiscore` 12 and 14 more) |
| Called from | `DrawHud` |
| Calls | `PrintTextNormal` |

### `LoseLife` (`$924B`)

**Count the death down: the explosion, PILOT STAND BY or MISSION OVER, CONTINUE, the next life**

Witness: L1 33360 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 422 calls, 16,346 t-states own (0.00 %) |
| Runs (the other recordings) | 32,938 calls (`stage1/rec/l1` 3,482, `docs/integrate/rec/boss` 3,146, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoop` |
| Calls | `StarsOff`, `NewGame` (tail), `StartLife` (tail), `NewGameState`, `Continue`, `Silence`, `ClearShipStuff`, `PilotStandBy`, `MissionOver`, `CheckHiScore`, `ClearTextRow`, `DrawHud`, `PlaySound`, `WaitFrames` |
| Reads | `$5FC2`-`$5FC3` (`Explosions+1`); `$719C` (`LevelDigit`); `$72CB` (`CreditDigit`); `$7A8D` (`DeathTimer`); `$7AA0` (`Lives`) |
| Writes | `$5FC1`-`$5FC3` (`Explosions`); `$71D1` (`FirstPlay`); `$72CB` (`CreditDigit`); `$7A8D` (`DeathTimer`) |

### `PilotStandBy` (`$92C5`)

**Print `PILOT STAND BY $` and wait**

Witness: L1 38 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3 calls, 249 t-states own (0.00 %) |
| Runs (the other recordings) | 35 calls (`stage2/rec/deaths-l7` 7, `stage1/rec/continue` 6, `stage1/rec/hiscore` 5 and 6 more) |
| Called from | `LoseLife` |
| Calls | `PrintAndWait` (tail) |

### `MissionOver` (`$92CD`)

**Sounds, `MISSION OVER $` and a wait**

Witness: L1 4 (continue, gameover, hiscore, hiscore-typed).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/continue` 1, `stage1/rec/gameover` 1, `stage1/rec/hiscore` 1 and 1 more) |
| Called from | `LoseLife` |
| Calls | `PrintAndWait` (falls into), `PlaySound` |

### `PrintAndWait` (`$92DF`)

**PrintAndWait**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 24 calls (`stage1/rec/continue` 7, `stage1/rec/hiscore` 6, `stage1/rec/hiscore-typed` 6 and 1 more) |
| Called from | `PilotStandBy` (tail), `MissionOver` (falls into) |
| Calls | `PrintText`, `WaitFrames` |

### `CheckHiScore` (`$92E8`)

**Enter the score into the table when high enough, then show the table**

Witness: L1 4 (continue, gameover, hiscore, hiscore-typed).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/hiscore` 1, `stage1/rec/continue` 1, `stage1/rec/gameover` 1 and 1 more) |
| Called from | `LoseLife` |
| Calls | `ShowHiScores`, `InsertHiScore`, `Wait256` |
| Writes | `$BE76` (`TaskTable+22`) |

### `InsertHiScore` (`$92FA`)

**Find the score's place, shift the lower entries, take the name typed with up, down and fire**

Witness: L1 4 (continue, gameover, hiscore, hiscore-typed).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/hiscore-typed` 1, `stage1/rec/hiscore` 1, `stage1/rec/continue` 1 and 1 more) |
| Called from | `CheckHiScore` |
| Calls | `ShowHiScores`, `PrintHiScores`, `ReadControls`, `PrintRow22`, `PlaySound`, `WaitFrames`, `FillBlock` |
| Reads | `$71C9`-`$71D3` (`ScoreText`, `ScoreDirty`); `$7CE2` (`HiScoreTable+10`); `$7CF3`-`$7D70` (`HiScoreTable+27`) |
| Writes | `$71D2`-`$71D3` (`NameLetter`, `NamePos`); `$7D1C`-`$7D81` (`HiScoreTable+68`, `HiScoreSpare`) |

## ship

`src/game/ship.asm`

### `MoveMissiles` (`$93D0`)

**Move the homing missiles, count MissileTimer down**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 49,362 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `MoveMissile` |
| Reads | `$83ED` (`MissileTimer`) |
| Writes | `$83ED` (`MissileTimer`) |

### `MoveMissile` (`$93F0`)

**Move one missile along its frame lists, turning toward a target**

At each list's end MissileTurn: in state 1 the first live slot one or two columns ahead (not the other missile's target) is the target; above or below the missile's row it turns once, diagonally, then climbs or dives for good. The missile ends on scenery, a hit, column 31 or more, or row 21 or more (l1 11550: missile A takes slot 3 and turns up).

Witness: L1 76378 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 836 calls, 29,642 t-states own (0.00 %) |
| Runs (the other recordings) | 65,808 calls (`stage1/rec/l1` 6,966, `docs/integrate/rec/boss` 6,294, `stage1/rec/l3` 5,952 and 18 more) |
| Called from | `MoveMissiles` |
| Calls | `DrawGame`, `DrawGameFlipped`, `DrawGameMirrored`, `DrawGameBoth`, `SolidAny`, `ProcessHits`, `GetCell`, `MoveByBits` |
| Reads | `$7A89` (`FrameCounter`); `$7AE7`-`$7AF2` (`MissileLaunch`, `Font`); `$7D82`-`$7DB0` (`MissileFrames`, `MissileTurns`); `$8501`-`$85F7` (`EnemySlots`) |
| Writes | `$7AE7`-`$7AF2` (`MissileLaunch`, `Font`); `$9461`-`$9462` (`MissileDrawer+12`) |

### `MoveShip` (`$94F1`)

**Move the ship by the controls, tilt it while it climbs or dives, test what it touches**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

[Animation: `MoveShip` at work](img/routines/MoveShip.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 87,602 t-states own (0.01 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `ShipDies` (tail), `ShipShield` (falls into), `DrawGame`, `GetCell` |
| Reads | `$74FA` (`ControlBits`); `$7A89`-`$7AA4` (`FrameCounter`, `IntTicks`, `KempstonAbsent`, `ExtraLives` and 21 more); `$7ABF` (`BeamCharge`) |
| Writes | `$7A98`-`$7AA4` (`ShieldTimer`, `ScoreChanged`, `WaveOverride`, `LevelEndTimer` and 9 more); `$8EB1` (`CellMark+15`) |

### `ShipShield` (`$9577`)

**While ShieldTimer runs: the shield; then the fire and detach controls**

No test reads ShieldTimer but this one: the shield is drawn and does not protect (deaths-l7 8376: a shot death with ShieldTimer 45).

Witness: L1 24884 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 322 calls, 56,466 t-states own (0.00 %) |
| Runs (the other recordings) | 11,095 calls (`stage1/rec/l1` 2,732, `docs/integrate/rec/boss` 2,621, `stage1/rec/continue` 1,210 and 9 more) |
| Called from | `ShipFlyIn`, `MoveShip` (falls into) |
| Calls | `DrawSprite`, `DrawSpriteFlipped`, `GameObject`, `ForceRecordOf`, `FireBeam`, `ClearColourOverride`, `PlaySound` |
| Reads | `$74FA` (`ControlBits`); `$7A89`-`$7AA8` (`FrameCounter`, `IntTicks`, `KempstonAbsent`, `ExtraLives` and 25 more); `$7ABE`-`$7ABF` (`ForceLevel`, `BeamCharge`) |
| Writes | `$7A98`-`$7AA8` (`ShieldTimer`, `ScoreChanged`, `WaveOverride`, `LevelEndTimer` and 13 more); `$8EB1` (`CellMark+15`) |

### `MoveForce` (`$95F6`)

**Move the Force by its state, draw it, dock it at the ship**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 36,909 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `ForceSeek`, `ForceStore` (tail), `ForceDraw` (tail), `MoveCarriers` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$7AA1`-`$7AAE` (`ShipColumn`, `ShipRow`, `ForceAttached`, `ShipFrame` and 4 more); `$7ACF`-`$7AD6` (`Scratch`) |
| Writes | `$7AA8`-`$7AB0` (`ForceRecord`); `$9788` (`ForceSeekEnd`) |

### `ForceTarget` (`$96A4`)

**Patch the Force's seek and return the ship's column + 1**

Witness: L1 12 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 calls (`docs/integrate/rec/boss` 4, `docs/integrate/rec/force` 4, `stage1/rec/l1` 4) |
| Calls | `ForceSeek` (falls into), `ForceDraw` (tail), `SolidHard`, `GetCell` |
| Reads | `$7AA1` (`ShipColumn`) |
| Writes | `$7ACF`-`$7AD0` (`Scratch`); `$9788` (`ForceSeekEnd`) |

### `ForceSeek` (`$9731`)

**Step the Force toward its target, testing the cells it would enter**

Witness: L1 17 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`docs/integrate/rec/force` 9, `docs/integrate/rec/boss` 4, `stage1/rec/l1` 4) |
| Called from | `MoveForce`, `ForceTarget` (falls into) |
| Calls | `ForceStore` (falls into), `ForceProbe`, `DirUp`, `DirDown`, `DirLeft`, `DirRight`, `ForceTry` |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`) |

### `ForceStore` (`$9789`)

**ForceStore**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`docs/integrate/rec/force` 9, `docs/integrate/rec/boss` 4, `stage1/rec/l1` 4) |
| Called from | `MoveForce` (tail), `ForceSeek` (falls into) |
| Calls | `ForceDraw` (tail) |
| Writes | `$7AA9`-`$7AAA` (`ForceRecord+1`) |

### `ForceProbe` (`$978E`)

**Test the cell in direction A; carry when it is free**

Witness: L1 68 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 68 calls (`docs/integrate/rec/force` 36, `docs/integrate/rec/boss` 16, `stage1/rec/l1` 16) |
| Called from | `ForceSeek` |
| Calls | `SolidHard`, `GetCell` |
| Writes | `$9796`-`$979F` (`ForceProbe+8`) |

### `DirUp` (`$97A1`)

**The up probe and its opposite**

Witness: L1 29 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 29 calls (`docs/integrate/rec/force` 13, `docs/integrate/rec/boss` 8, `stage1/rec/l1` 8) |
| Called from | `ForceSeek` |

### `DirDown` (`$97A6`)

**The down probe and its opposite**

Witness: L1 17 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`docs/integrate/rec/force` 9, `docs/integrate/rec/boss` 4, `stage1/rec/l1` 4) |
| Called from | `ForceSeek` |

### `DirLeft` (`$97AB`)

**The left probe and its opposite**

Witness: L1 22 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 22 calls (`docs/integrate/rec/force` 14, `docs/integrate/rec/boss` 4, `stage1/rec/l1` 4) |
| Called from | `ForceSeek` |

### `DirRight` (`$97B0`)

**The right probe and its opposite**

Witness: L1 17 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`docs/integrate/rec/force` 9, `docs/integrate/rec/boss` 4, `stage1/rec/l1` 4) |
| Called from | `ForceSeek` |

### `ForceTry` (`$97B5`)

**Patch the probe operands and test the cell**

Witness: L1 17 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`docs/integrate/rec/force` 9, `docs/integrate/rec/boss` 4, `stage1/rec/l1` 4) |
| Called from | `ForceSeek` |
| Calls | `SolidHard`, `GetCell` |
| Writes | `$97C4`-`$97D9` (`ForceTry+15`, `l_97D2`) |

### `ForceDraw` (`$97DC`)

**ForceDraw**

[Animation: `ForceDraw` at work](img/routines/ForceDraw.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23,492 calls (`stage1/rec/l3` 2,976, `stage1/rec/l1` 2,873, `stage1/rec/l7` 2,816 and 9 more) |
| Called from | `MoveForce` (tail), `ForceTarget` (tail), `ForceStore` (tail) |
| Calls | `DrawGame`, `DrawGameMirrored`, `AddScoreFlag`, `PlaySound` |
| Reads | `$7A95`-`$7AB7` (`HitCount`, `HitResult`, `BeamMeter`, `ShieldTimer` and 17 more); `$7AD8`-`$7AE3` (`HitList+1`) |
| Writes | `$7AA3`-`$7AB7` (`ForceAttached`, `ShipFrame`, `BitUpperOn`, `BitLowerOn` and 3 more) |

### `MoveCarriers` (`$982A`)

**MoveCarriers**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 39,710 t-states own (0.00 %) |
| Runs (the other recordings) | 9,412 calls (`stage1/rec/continue` 1,434, `stage1/rec/hiscore` 1,226, `stage1/rec/hiscore-typed` 1,226 and 10 more) |
| Called from | `MoveForce` (tail) |
| Calls | `MoveCarrierA`, `MoveCarrierB`, `MoveBitDevices` (tail), `ClearHits` |

### `MoveCarrierA` (`$983C`)

**Move carrier A and draw it; touching the ship takes its pick-up**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 12,072 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MoveCarriers` |
| Calls | `CarrierDraw` (falls into), `NextCarrierFrame`, `CarrierTimer` |
| Reads | `$72F7`-`$72FC` (`CarrierColours+2`, `ShadowLine2Tail`); `$7A89`-`$7AAD` (`FrameCounter`, `IntTicks`, `KempstonAbsent`, `ExtraLives` and 25 more); `$7ABE`-`$7AC4` (`ForceLevel`, `BeamCharge`, `BeamPower`, `Carriers`); `$7AD8`-`$7ADD` (`HitList+1`); `$83DA`-`$83DF` (`ShipTrail`) |
| Writes | `$7A95`-`$7AC1` (`HitCount`, `HitResult`, `BeamMeter`, `ShieldTimer` and 22 more); `$83DA`-`$83E1` (`ShipTrail`); `$8EB1` (`CellMark+15`) |

### `CarrierDraw` (`$9856`)

**CarrierDraw**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,398 calls (`stage1/rec/l4` 1,363, `stage1/rec/l5` 1,331, `stage1/rec/l2` 749 and 2 more) |
| Called from | `MoveCarrierA` (falls into), `MoveCarrierB` (tail) |
| Calls | `DrawGame`, `DrawGameBoth` |
| Reads | `$72F7`-`$72FC` (`CarrierColours+2`, `ShadowLine2Tail`); `$7A89`-`$7AC5` (`FrameCounter`, `IntTicks`, `KempstonAbsent`, `ExtraLives` and 31 more); `$7AD8`-`$7ADD` (`HitList+1`); `$83DA`-`$83DF` (`ShipTrail`) |
| Writes | `$7A95`-`$7AC5` (`HitCount`, `HitResult`, `BeamMeter`, `ShieldTimer` and 22 more); `$83DA`-`$83E1` (`ShipTrail`); `$8EB1` (`CellMark+15`) |

### `MoveCarrierB` (`$98A1`)

**Move carrier B**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 11,856 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MoveCarriers` |
| Calls | `CarrierDraw` (tail), `ForceRecordOf`, `NextCarrierFrame`, `CarrierTimer`, `AddScore`, `PlaySound` |
| Reads | `$7AC5`-`$7AC8` (`Carriers+4`) |
| Writes | `$7AC5` (`Carriers+4`) |

### `ForceRecordOf` (`$9921`)

**DE = the Force record of level A**

Witness: L1 33 (boss, deaths-l7, force, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33 calls (`docs/integrate/rec/force` 7, `docs/integrate/rec/boss` 5, `stage1/rec/l1` 5 and 8 more) |
| Called from | `ShipShield`, `MoveCarrierB`, `LevelEnd` |
| Calls | `AddScore` |

### `MoveBitDevices` (`$9969`)

**MoveBitDevices**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 24,735 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MoveCarriers` (tail) |
| Calls | `BitFrame`, `TrailPoint`, `DrawGame`, `DrawGameFlipped`, `AddScoreFlag` |
| Reads | `$7AA5`-`$7AB4` (`BitUpperOn`, `BitLowerOn`, `MissilesOn`, `ForceRecord` and 1 more) |
| Writes | `$7AB1`-`$7AB4` (`BitPositions`) |

### `BitFrame` (`$99AE`)

**Step a bit's animation counter; A = its sprite**

Witness: L1 14669 (boss, deaths-l7, ending, l1, l4-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14,669 calls (`stage1/rec/l7` 3,839, `stage1/rec/l5` 2,368, `stage1/rec/l6` 2,176 and 6 more) |
| Called from | `MoveBitDevices` |
| Reads | `$7AB8`-`$7AB9` (`BitPositions+7`) |
| Writes | `$7AB8`-`$7AB9` (`BitPositions+7`) |

### `NextCarrierFrame` (`$99BC`)

**Step a carrier's animation; A = its character from CarrierFrames**

Witness: L1 7243 (boss, deaths-l7, force, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,243 calls (`stage1/rec/l4` 1,363, `stage1/rec/l5` 1,331, `stage1/rec/l2` 749 and 8 more) |
| Called from | `MoveCarrierA`, `MoveCarrierB` |
| Reads | `$71C1`-`$71C8` (`CarrierFrames`); `$7AC2`-`$7AC6` (`Carriers+1`) |
| Writes | `$7AC2`-`$7AC6` (`Carriers+1`) |

### `CarrierTimer` (`$99CD`)

**Count a carrier's timer down; Z when it ran out**

Witness: L1 7266 (boss, deaths-l7, force, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,266 calls (`stage1/rec/l4` 1,368, `stage1/rec/l5` 1,337, `stage1/rec/l2` 752 and 8 more) |
| Called from | `MoveCarrierA`, `MoveCarrierB` |
| Reads | `$7A82` (`ScrollStep`); `$7AC3`-`$7AC7` (`Carriers+2`) |
| Writes | `$7AC3`-`$7AC7` (`Carriers+2`) |

### `TrailPoint` (`$99DA`)

**Store the ship's position in the trail ring**

Witness: L1 14669 (boss, deaths-l7, ending, l1, l4-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14,669 calls (`stage1/rec/l7` 3,839, `stage1/rec/l5` 2,368, `stage1/rec/l6` 2,176 and 6 more) |
| Called from | `MoveBitDevices` |
| Reads | `$7A89` (`FrameCounter`); `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$83DA`-`$83E1` (`ShipTrail`) |
| Writes | `$83DA`-`$83E1` (`ShipTrail`) |

### `DrawGame` (`$99FE`)

**Draw game object A at BC as stored, with the hits gathered**

Witness: L1 305434 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,395 calls, 64,208 t-states own (0.00 %) |
| Runs (the other recordings) | 304,039 calls (`stage1/rec/l4` 53,664, `stage1/rec/l2` 45,043, `stage1/rec/l5` 43,336 and 18 more) |
| Called from | `TitleLogo`, `LogoRow`, `ShipFlyIn`, `MoveMissile`, `MoveShip`, `ForceDraw`, `CarrierDraw`, `MoveBitDevices`, `MoveShipShots`, `DrawBeam`, `AntiAirDown`, `DrawTrail`, `DrawBitTrail`, `TitleScreen` |
| Calls | `DrawSprite`, `DrawPrepare`, `DrawFinish` (tail) |
| Writes | `$8EDA` (`CellFree+24`) |

### `DrawGameFlipped` (`$9A06`)

**Draw game object A upside down**

Witness: L1 4144 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 66 calls, 3,036 t-states own (0.00 %) |
| Runs (the other recordings) | 4,078 calls (`stage1/rec/l7` 1,503, `stage1/rec/l1` 538, `stage1/rec/l8` 456 and 16 more) |
| Called from | `MoveMissile`, `MoveBitDevices`, `DrawBeam`, `AntiAirDown`, `TitleScreen` |
| Calls | `DrawSpriteFlipped`, `DrawPrepare`, `DrawFinish` (tail) |

### `DrawGameMirrored` (`$9A0E`)

**Draw game object A mirrored**

Witness: L1 3673 (boss, deaths-l7, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,673 calls (`stage1/rec/l1` 1,968, `docs/integrate/rec/boss` 1,559, `stage1/rec/l4` 57 and 7 more) |
| Called from | `MoveMissile`, `ForceDraw`, `MoveForceShots`, `AntiAirDown`, `TitleScreen` |
| Calls | `DrawSpriteMirrored`, `DrawPrepare`, `DrawFinish` (tail) |

### `DrawGameBoth` (`$9A16`)

**Draw game object A mirrored and upside down**

Witness: L1 4906 (boss, deaths-l7, force, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,906 calls (`stage1/rec/l1` 1,396, `docs/integrate/rec/boss` 999, `stage1/rec/l4` 568 and 8 more) |
| Called from | `MoveMissile`, `CarrierDraw`, `MoveForceShots`, `AntiAirDown`, `TitleScreen` |
| Calls | `DrawSpriteBoth`, `DrawPrepare`, `DrawFinish` (tail) |

### `DrawPrepare` (`$9A1E`)

**GameObject A and the hit gathering on (CellFree's RET made a NOP)**

Witness: L1 318157 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,461 calls, 64,303 t-states own (0.00 %) |
| Runs (the other recordings) | 316,696 calls (`stage1/rec/l4` 54,477, `stage1/rec/l2` 45,396, `stage1/rec/l5` 44,132 and 18 more) |
| Called from | `DrawGame`, `DrawGameFlipped`, `DrawGameMirrored`, `DrawGameBoth` |
| Calls | `LevelObject`, `GameObject` |
| Writes | `$8EDA` (`CellFree+24`) |

### `DrawFinish` (`$9A26`)

**DrawFinish**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,461 calls, 43,830 t-states own (0.00 %) |
| Runs (the other recordings) | 315,374 calls (`stage1/rec/l4` 54,477, `stage1/rec/l2` 45,396, `stage1/rec/l5` 44,132 and 16 more) |
| Called from | `DrawGame` (tail), `DrawGameFlipped` (tail), `DrawGameMirrored` (tail), `DrawGameBoth` (tail) |
| Writes | `$8EDA` (`CellFree+24`) |

### `FireBeam` (`$9A2C`)

**Fire: charge the beam while fire is held, release a beam or a shot**

Held: BeamCharge grows and the BEAM meter with it. Released: a short charge fires a plain shot and the Force's lasers by WeaponKind; a longer one a beam by the charge.

BeamCharge + 2 a pass while held, kept below `$40` (stops at `$3E`); on release below `$0C` a plain shot, else BeamRelease: `$0C-$13` power 10, `$14-$23` power 20, `$24` up power 30.

Witness: L1 17968 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 167 calls, 75,226 t-states own (0.01 %) |
| Runs (the other recordings) | 17,801 calls (`stage1/rec/l1` 1,797, `stage1/rec/l4` 1,671, `docs/integrate/rec/boss` 1,659 and 16 more) |
| Called from | `ShipShield` |
| Calls | `DrawSprite`, `GameObject`, `StartMissile`, `ForceGround` (tail), `FireMissiles` (tail), `FireBits` (tail), `ShotFire`, `PrintTextNormal`, `PlaySound` |
| Reads | `$74FA` (`ControlBits`); `$7A97`-`$7ABF` (`BeamMeter`, `ShieldTimer`, `ScoreChanged`, `WaveOverride` and 18 more); `$83E5`-`$83E9` (`AntiAirShots`) |
| Writes | `$7A97` (`BeamMeter`); `$7ABA`-`$7AC0` (`BitPositions+9`, `WeaponKind`, `ForceLevel`, `BeamCharge` and 1 more); `$83E2`-`$83EC` (`BeamShot`, `AntiAirShots`); `$A161` (`l_A157+10`); `$A174` (`BounceEnd+5`); `$A1C6` (`l_A1C4+2`) |

### `StartMissile` (`$9C2C`)

**Start a missile record HL if free**

Witness: L1 3225 (boss, l1-l5, l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,225 calls (`stage1/rec/l2` 834, `stage1/rec/l4` 780, `docs/integrate/rec/boss` 375 and 4 more) |
| Called from | `FireBeam` |
| Calls | `StartRecord` (falls into) |
| Reads | `$5F00` (`MissileA`); `$5F34` (`MissileB`); `$5F68` (`MissileC`); `$7A89` (`FrameCounter`) |
| Writes | `$5F00`-`$5F03` (`MissileA`); `$5F34`-`$5F37` (`MissileB`); `$5F68`-`$5F6B` (`MissileC`); `$7AF3`-`$7AF5` (`Font+3`) |

### `StartRecord` (`$9C31`)

**Write a record at HL**

Witness: L1 2401 (boss, deaths-l7, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,424 calls (`stage1/rec/l4` 350, `stage1/rec/l5` 290, `stage1/rec/l7` 236 and 4 more) |
| Called from | `StartMissile` (falls into), `ForceGround` |
| Reads | `$7A89` (`FrameCounter`) |
| Writes | `$5EE4`-`$5EE7` (system); `$5F00`-`$5F03` (`MissileA`); `$5F34`-`$5F37` (`MissileB`); `$5F68`-`$5F6B` (`MissileC`); `$5FA5`-`$5FA8` (system); `$7AF3`-`$7AF5` (`Font+3`) |

### `ForceGround` (`$9C40`)

**ForceGround**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,751 calls (`stage1/rec/l7` 465, `stage1/rec/l5` 347, `stage1/rec/l4` 262 and 4 more) |
| Called from | `FireBeam` (tail) |
| Calls | `StartRecord`, `FireMissiles` (tail), `PlaySound` |
| Reads | `$5EE4` (system); `$5FA5` (system); `$7AA1`-`$7AA3` (`ShipColumn`, `ShipRow`, `ForceAttached`) |
| Writes | `$83EE`-`$83F0` (`MissileTimer+1`); `$A277` (`BitStep+47`); `$A2A1`-`$A2AE` (`l_A29A+7`, `l_A2A6`); `$A3B6` (`l_A3AC+10`); `$A3CA`-`$A3D7` (`BitEnd+5`, `DrawBitTrail`) |

### `FireMissiles` (`$9C99`)

**FireMissiles**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 167 calls, 15,161 t-states own (0.00 %) |
| Runs (the other recordings) | 16,699 calls (`stage1/rec/l4` 1,590, `stage1/rec/l1` 1,511, `stage1/rec/l5` 1,382 and 16 more) |
| Called from | `FireBeam` (tail), `ForceGround` (tail) |
| Calls | `FireBits` (tail), `PlaySound` |
| Reads | `$74FA` (`ControlBits`); `$7AA1`-`$7AA7` (`ShipColumn`, `ShipRow`, `ForceAttached`, `ShipFrame` and 3 more); `$7AE7`-`$7AED` (`MissileLaunch`); `$83ED` (`MissileTimer`) |
| Writes | `$7AE7`-`$7AF2` (`MissileLaunch`, `Font`); `$83ED` (`MissileTimer`); `$9D3F` (`l_9D33+12`) |

### `FireBits` (`$9CF2`)

**FireBits**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 167 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3,804 calls (`stage1/rec/l1` 1,766, `docs/integrate/rec/boss` 1,639, `docs/integrate/rec/force` 399) |
| Called from | `FireBeam` (tail), `FireMissiles` (tail) |
| Calls | `ForceShotA` |
| Reads | `$74FA` (`ControlBits`); `$7AA5`-`$7AA6` (`BitUpperOn`, `BitLowerOn`) |
| Writes | `$9D3F` (`l_9D33+12`) |

### `ForceShotA` (`$9D0E`)

**Fire a reflect-laser pair from ForceShotsA**

Witness: L1 2140 (boss, deaths-l7, l1, l4-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,140 calls (`stage1/rec/l5` 467, `stage1/rec/l7` 465, `stage1/rec/l4` 321 and 5 more) |
| Called from | `FireBits` |
| Calls | `ForceShotFrom` (tail) |
| Reads | `$71D4`-`$71D7` (`ForceShotsA`); `$7AA3`-`$7ABD` (`ForceAttached`, `ShipFrame`, `BitUpperOn`, `BitLowerOn` and 4 more) |
| Writes | `$71D4`-`$71D9` (`ForceShotsA`) |

### `ForceShotB` (`$9D13`)

**Fire a reflect-laser pair from ForceShotsB**

Witness: L1 205 (l7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 205 calls (`stage1/rec/l7` 205) |
| Called from | `ForceShotFrom` |
| Calls | `ForceShotFrom` (falls into) |

### `ForceShotFrom` (`$9D16`)

**ForceShotFrom**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 670 calls (`stage1/rec/l7` 670) |
| Called from | `ForceShotA` (tail), `ForceShotB` (falls into) |
| Calls | `ForceShotB` |
| Reads | `$7AA3`-`$7ABD` (`ForceAttached`, `ShipFrame`, `BitUpperOn`, `BitLowerOn` and 4 more) |

### `ShotFire` (`$9D5C`)

**Start a plain ship shot**

Witness: L1 4642 (boss, c1, continue, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 27 calls, 2,458 t-states own (0.00 %) |
| Runs (the other recordings) | 4,615 calls (`stage1/rec/l1` 532, `stage1/rec/l4` 519, `docs/integrate/rec/boss` 475 and 13 more) |
| Called from | `FireBeam` |
| Calls | `FreeShot`, `PlaySound` |
| Writes | `$5EB4`-`$5EBF` (`ShipShots`) |

### `ShotFireTriple` (`$9D6C`)

**Start the three-way shot**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShotFireDouble` (`$9D6F`)

**Start the two-cell shot**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShotFireDiagonal` (`$9D81`)

**Start the diagonal pair**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShotStore` (`$9D90`)

**Write the shot A at E, D into the record HL**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FreeShot` (`$9D96`)

**HL = a free ship shot record; none: return to the caller's caller**

Witness: L1 4642 (boss, c1, continue, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 27 calls, 1,534 t-states own (0.00 %) |
| Runs (the other recordings) | 4,615 calls (`stage1/rec/l1` 532, `stage1/rec/l4` 519, `docs/integrate/rec/boss` 475 and 13 more) |
| Called from | `ShotFire` |
| Reads | `$5EB4`-`$5EBD` (`ShipShots`) |

### `MoveShipShots` (`$9DA5`)

**Move the ship's shots and draw them; a shot leaving the field or hitting scenery ends**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 517,576 t-states own (0.04 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `DrawGame`, `AddScoreFlag`, `GetCell`, `MoveByBits` |
| Reads | `$5EB4`-`$5EE1` (`ShipShots`) |
| Writes | `$5EB4`-`$5EBF` (`ShipShots`) |

### `MoveForceShots` (`$9DFA`)

**Move the reflect-laser pairs, bouncing off the scenery**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 116,782 t-states own (0.01 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `DrawGameMirrored`, `DrawGameBoth`, `SolidAny`, `AddScoreFlag`, `GetCell` |
| Reads | `$71D4`-`$71DD` (`ForceShotsA`, `ForceShotsB`); `$7A89` (`FrameCounter`); `$7EA4`-`$7EAA` (`SolidMap+164`); `$7EC4`-`$7ECB` (`SolidMap+196`); `$7EE4`-`$7EED` (`EntryCopySource+2`); `$7F04`-`$7F0D` (`EntryCopySource+34`); 4 more ranges |
| Writes | `$71D4`-`$71D9` (`ForceShotsA`); `$9E59`-`$9E5A` (`l_9E53+6`) |

### `MoveBeam` (`$9E6B`)

**Move the beam shot, ending it at scenery**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 35,367 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `DrawBeam`, `GetCell` |
| Reads | `$7AC0` (`BeamPower`); `$7E68`-`$8021` (`SolidMap+104`, `EntryCopySource`); `$803A`-`$803C` (`EntryCopySource+344`); `$8075` (`EntryCopySource+403`); `$83E2`-`$83E4` (`BeamShot`) |
| Writes | `$7AC0` (`BeamPower`); `$83E2`-`$83E4` (`BeamShot`) |

### `DrawBeam` (`$9EB6`)

**Draw the beam's segment**

Witness: L1 2466 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 126 calls, 9,885 t-states own (0.00 %) |
| Runs (the other recordings) | 2,340 calls (`stage1/rec/l8` 533, `stage1/rec/continue` 230, `docs/integrate/rec/restart` 201 and 16 more) |
| Called from | `MoveBeam` |
| Calls | `DrawGame`, `DrawGameFlipped`, `AddScoreFlag` |
| Reads | `$7A89` (`FrameCounter`) |

### `MoveAntiAir` (`$9ED5`)

**MoveAntiAir**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 26,771 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MoveBitUnits` (tail) |
| Calls | `MoveAntiAirShot`, `ClearColourOverride` (tail) |

### `MoveAntiAirShot` (`$9EE4`)

**Move an anti-air shot along AntiAirPathUp or AntiAirPathDown**

Witness: L1 66602 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 836 calls, 33,740 t-states own (0.00 %) |
| Runs (the other recordings) | 65,766 calls (`stage1/rec/l1` 6,945, `docs/integrate/rec/boss` 6,273, `stage1/rec/l3` 5,952 and 18 more) |
| Called from | `MoveAntiAir` |
| Calls | `AntiAirDown` (tail) |
| Reads | `$83E5`-`$83E9` (`AntiAirShots`) |
| Writes | `$7AD3`-`$7AD4` (`Scratch+4`) |

### `ShotPathStep` (`$9F6E`)

**Step a shot along its path table; `$63` ends it**

Witness: L1 2480 (boss, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,480 calls (`stage1/rec/l1` 1,473, `docs/integrate/rec/boss` 1,007) |
| Called from | `AntiAirDown` |
| Calls | `ShotEnd` (falls into), `ClearColourOverride` (tail) |
| Reads | `$7DD6`-`$7DF8` (`AntiAirPathDown`); `$83E5`-`$83EC` (`AntiAirShots`) |
| Writes | `$83E5`-`$83EB` (`AntiAirShots`) |

### `ShotEnd` (`$9F89`)

**ShotEnd**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 96 calls (`stage1/rec/l1` 49, `docs/integrate/rec/boss` 47) |
| Called from | `ShotPathStep` (falls into), `AntiAirDown` (tail) |
| Calls | `ClearColourOverride` (tail) |
| Writes | `$83E5`-`$83EA` (`AntiAirShots`) |

### `AntiAirDown` (`$9F99`)

**AntiAirDown**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,480 calls (`stage1/rec/l1` 1,473, `docs/integrate/rec/boss` 1,007) |
| Called from | `MoveAntiAirShot` (tail) |
| Calls | `DrawGame`, `DrawGameFlipped`, `DrawGameMirrored`, `DrawGameBoth`, `ShotPathStep`, `ShotEnd` (tail), `AddScoreFlag`, `GetCell` |
| Reads | `$7A89` (`FrameCounter`); `$7ACF`-`$7AD5` (`Scratch`); `$7F03`-`$7FED` (`EntryCopySource+33`); `$8000`-`$802A` (`EntryCopySource+286`); `$80E3`-`$80FF` (`PlayStarStates+11`) |
| Writes | `$7ACF`-`$7AD2` (`Scratch`); `$83E5`-`$83E9` (`AntiAirShots`); `$8EB1` (`CellMark+15`) |

### `MoveMissileSet` (`$A01F`)

**Move the three missile records, then the bit units**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 74,755 t-states own (0.01 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `MoveMissileRec`, `MoveBitUnits` (tail), `ClearColourOverride` |
| Reads | `$7A89` (`FrameCounter`) |
| Writes | `$8EB1` (`CellMark+15`) |

### `MoveMissileRec` (`$A04A`)

**Move one missile record and draw its trail**

Witness: L1 99966 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,254 calls, 28,780 t-states own (0.00 %) |
| Runs (the other recordings) | 98,712 calls (`stage1/rec/l1` 10,449, `docs/integrate/rec/boss` 9,441, `stage1/rec/l3` 8,928 and 18 more) |
| Called from | `MoveMissileSet` |
| Calls | `BounceShot`, `DrawTrail` |
| Reads | `$5F00` (`MissileA`); `$5F34` (`MissileB`); `$5F68` (`MissileC`) |
| Writes | `$7AD3` (`Scratch+4`) |

### `BounceShot` (`$A060`)

**One step of a reflected shot: the next direction by the cells around it (ForceShotTurns)**

Witness: L1 24990 (boss, l1-l5, l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24,990 calls (`stage1/rec/l2` 8,072, `stage1/rec/l4` 6,642, `stage1/rec/l8` 4,088 and 4 more) |
| Called from | `MoveMissileRec` |
| Calls | `GetCellWindow`, `SolidAny`, `PlaySound` |
| Reads | `$5F00`-`$5F03` (`MissileA`); `$5F34`-`$5F37` (`MissileB`); `$5F68`-`$5F6B` (`MissileC`); `$5F9C`-`$5FA4` (system); `$7594`-`$75B6` (`ForceShotTurns+1`); `$7ABB` (`BitPositions+10`) |
| Writes | `$5F00`-`$5F9B` (`MissileA`, `MissileB`, `MissileC`); `$7593`-`$75B1` (`ForceShotTurns`); `$7ABB` (`BitPositions+10`) |

### `GetCellWindow` (`$A17F`)

**Copy the 3 x 3 cells around BC**

Witness: L1 13537 (boss, l1-l5, l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13,537 calls (`stage1/rec/l2` 4,654, `stage1/rec/l4` 3,582, `stage1/rec/l8` 2,497 and 4 more) |
| Called from | `BounceShot` |
| Calls | `CellWindowRow`, `GetCell` |

### `CellWindowRow` (`$A196`)

**One row of 3 cells**

Witness: L1 40611 (boss, l1-l5, l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 40,611 calls (`stage1/rec/l2` 13,962, `stage1/rec/l4` 10,746, `stage1/rec/l8` 7,491 and 4 more) |
| Called from | `GetCellWindow` |
| Reads | `$7E01`-`$8079` (`SolidMap+1`, `EntryCopySource`); `$8200`-`$823D` (`ScrollerText+87`) |
| Writes | `$5F9C`-`$5FA4` (system); `$609C`-`$60A2` (system); `$619C`-`$61A2` (system); `$629C`-`$62A1` (system) |

### `DrawTrail` (`$A1B5`)

**Draw a missile's trail**

Witness: L1 12495 (boss, l1-l5, l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,495 calls (`stage1/rec/l2` 4,036, `stage1/rec/l4` 3,321, `stage1/rec/l8` 2,044 and 4 more) |
| Called from | `MoveMissileRec` |
| Calls | `SlotFlags`, `DrawGame`, `ProcessHits`, `GetCell`, `ClearBlock` |
| Reads | `$5F04`-`$5F9B` (`MissileA+4`, `MissileB`, `MissileC`); `$7A89` (`FrameCounter`); `$7ABB` (`BitPositions+10`); `$7AF3`-`$7AF5` (`Font+3`) |
| Writes | `$5F00`-`$5F99` (`MissileA`, `MissileB`, `MissileC`); `$7ABB` (`BitPositions+10`) |

### `MoveBitUnits` (`$A216`)

**MoveBitUnits**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 42,218 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MoveMissileSet` (tail) |
| Calls | `MoveAntiAir` (tail), `MoveBitUnit` |
| Writes | `$83F1` (`MissileTimer+4`) |

### `MoveBitUnit` (`$A22E`)

**Move one bit unit and draw it**

Witness: L1 66644 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 836 calls, 19,253 t-states own (0.00 %) |
| Runs (the other recordings) | 65,808 calls (`stage1/rec/l1` 6,966, `docs/integrate/rec/boss` 6,294, `stage1/rec/l3` 5,952 and 18 more) |
| Called from | `MoveBitUnits` |
| Calls | `BitStep`, `DrawBitTrail` |
| Reads | `$5EE4` (system); `$5FA5` (system) |
| Writes | `$83EE` (`MissileTimer+1`) |

### `BitStep` (`$A248`)

**One step of a bit unit by the cells around it**

Witness: L1 25142 (deaths-l7, l3-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25,142 calls (`stage1/rec/l7` 6,436, `stage1/rec/l5` 4,672, `stage1/rec/l6` 4,358 and 4 more) |
| Called from | `MoveBitUnit` |
| Calls | `ReadCellWindow`, `SolidAny` |
| Reads | `$5EE4`-`$5EE7` (system); `$5F9D`-`$5FA8` (system); `$7A89` (`FrameCounter`); `$7ABC` (`BitPositions+11`); `$83EE` (`MissileTimer+1`) |
| Writes | `$5EE4`-`$5EFF` (system); `$5FA5`-`$5FC0` (system); `$7ABC` (`BitPositions+11`) |

### `DrawBitTrail` (`$A3D5`)

**Draw a bit unit's trail**

Witness: L1 12571 (deaths-l7, l3-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,571 calls (`stage1/rec/l7` 3,218, `stage1/rec/l5` 2,336, `stage1/rec/l6` 2,179 and 4 more) |
| Called from | `MoveBitUnit` |
| Calls | `DrawGame`, `BitHits`, `ProcessHits` |
| Reads | `$5EE8`-`$5EFE` (system); `$5FA9`-`$5FBF` (system); `$7ABC` (`BitPositions+11`); `$7AD5` (`Scratch+6`) |
| Writes | `$5EE4`-`$5EFD` (system); `$5FA5`-`$5FBE` (system); `$7ABC` (`BitPositions+11`); `$83EF`-`$83F0` (`MissileTimer+2`) |

### `ReadCellWindow` (`$A431`)

**Read the cells around BC**

Witness: L1 19592 (deaths-l7, l3-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 19,592 calls (`stage1/rec/l7` 5,273, `stage1/rec/l5` 3,800, `stage1/rec/l6` 3,428 and 4 more) |
| Called from | `BitStep` |
| Calls | `GetCell` |
| Reads | `$7E00`-`$809F` (`SolidMap`, `RowTable`) |
| Writes | `$5F9D`-`$5FA4` (system) |

### `SolidHard` (`$A46B`)

**Test A for hard scenery**

Witness: L1 93 (boss, force, l1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 93 calls (`docs/integrate/rec/force` 51, `docs/integrate/rec/boss` 21, `stage1/rec/l1` 21) |
| Called from | `ForceTarget`, `ForceProbe`, `ForceTry` |
| Calls | `SolidTest` (tail) |

### `SolidAny` (`$A470`)

**Test A for any blocking cell**

Witness: L1 80846 (boss, deaths-l7, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 80,846 calls (`stage1/rec/l4` 14,577, `stage1/rec/l5` 13,969, `stage1/rec/l7` 13,909 and 7 more) |
| Called from | `MoveMissile`, `MoveForceShots`, `BounceShot`, `BitStep` |
| Calls | `SolidTest` (falls into) |

### `SolidTest` (`$A473`)

**SolidTest**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,586 calls (`stage1/rec/l1` 1,514, `docs/integrate/rec/boss` 1,072) |
| Called from | `SolidHard` (tail), `SolidAny` (falls into) |
| Calls | `SlotFlags` |

### `BitHits` (`$A486`)

**DE = the hit counter of the current bit unit**

Witness: L1 147777 (deaths-l7, l3-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 147,777 calls (`stage1/rec/l7` 39,701, `stage1/rec/l5` 27,960, `stage1/rec/l6` 26,526 and 4 more) |
| Called from | `DrawBitTrail` |
| Reads | `$83EF`-`$83F1` (`MissileTimer+2`) |

### `AddScoreFlag` (`$A490`)

**Mark the score, then ProcessHits**

Witness: L1 82749 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 380 calls, 31,730 t-states own (0.00 %) |
| Runs (the other recordings) | 82,369 calls (`stage1/rec/l1` 11,219, `stage1/rec/l7` 10,348, `docs/integrate/rec/boss` 9,307 and 17 more) |
| Called from | `ForceDraw`, `MoveBitDevices`, `MoveShipShots`, `MoveForceShots`, `DrawBeam`, `AntiAirDown` |
| Calls | `ProcessHits` (falls into) |
| Reads | `$7A96` (`HitResult`); `$7AD8`-`$7AE2` (`HitList+1`) |
| Writes | `$71D0`-`$71E0` (`ScoreDirty`, `FirstPlay`, `NameLetter`, `NamePos` and 3 more); `$7A95`-`$7A96` (`HitCount`, `HitResult`); `$7AD5`-`$7AE1` (`Scratch+6`, `HitList`) |

### `ProcessHits` (`$A495`)

**Process HitList: enemy slots lose a hit, soft cells explode**

Witness: L1 274857 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 380 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 263,404 calls (`stage1/rec/l4` 50,122, `stage1/rec/l2` 41,735, `stage1/rec/l5` 40,209 and 7 more) |
| Called from | `MoveMissile`, `DrawTrail`, `DrawBitTrail`, `AddScoreFlag` (falls into), `TitleScreen` |
| Calls | `ProcessHitsNext` (falls into) |
| Writes | `$71E0` (`HitCellCount`); `$7A96` (`HitResult`); `$7AD5` (`Scratch+6`) |

### `ProcessHitsNext` (`$A4A4`)

**ProcessHitsNext**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 389 calls, 71,830 t-states own (0.01 %) |
| Runs (the other recordings) | 371,312 calls (`stage1/rec/l2` 61,556, `stage1/rec/l4` 56,060, `stage1/rec/l7` 46,775 and 14 more) |
| Called from | `ProcessHits` (falls into), `HitEnemy` (tail), `HitCounted` (tail) |
| Calls | `ExplodeSoftCell`, `HitEnemy` (tail), `HitCounted` (tail), `PlaySound` |
| Reads | `$71E0`-`$71EC` (`HitCellCount`, `HitCells`); `$7A96` (`HitResult`); `$7AD8`-`$7AE4` (`HitList+1`) |
| Writes | `$71D0`-`$71E0` (`ScoreDirty`, `FirstPlay`, `NameLetter`, `NamePos` and 3 more); `$7A95` (`HitCount`); `$7AD7`-`$7AE3` (`HitList`) |

### `ExplodeSoftCell` (`$A4E5`)

**Clear the soft cell at BC and its neighbours, draw the explosion**

Witness: L1 717 (l4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 717 calls (`stage1/rec/l4` 717) |
| Called from | `ProcessHitsNext` |
| Calls | `DrawCellBlast`, `GetCell`, `SoftCellsOn`, `SoftCellsOff` |
| Reads | `$7A89`-`$7A8E` (`FrameCounter`, `IntTicks`, `KempstonAbsent`, `ExtraLives` and 2 more); `$7E11`-`$7E1A` (`SolidMap+17`); `$7E33`-`$804F` (`SolidMap+51`, `EntryCopySource`); `$806B`-`$806F` (`EntryCopySource+393`) |
| Writes | `$7A9C` (`DrawTag`); `$7E11`-`$7E19` (`SolidMap+17`); `$7E33`-`$804E` (`SolidMap+51`, `EntryCopySource`); `$806B`-`$806E` (`EntryCopySource+393`); `$8111`-`$8119` (`DrawnMap+17`); `$8133`-`$834E` (`DrawnMap+51`, `ShowLoadingScreen`, `ScrollRowLeft`, `ScrollerText`); 1 more ranges |

### `DrawCellBlast` (`$A53A`)

**Draw level object A at the cell left of BC and clear the cells there**

Witness: L1 879 (l4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 879 calls (`stage1/rec/l4` 879) |
| Called from | `ExplodeSoftCell` |
| Calls | `DrawSprite`, `LevelObject`, `ClearCellsTag` |

### `HitEnemy` (`$A551`)

**HitEnemy**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 9 calls, 1,626 t-states own (0.00 %) |
| Runs (the other recordings) | 96,178 calls (`stage1/rec/l2` 19,821, `stage1/rec/l3` 18,064, `stage1/rec/l7` 14,099 and 14 more) |
| Called from | `ProcessHitsNext` (tail) |
| Calls | `SlotFlags`, `ProcessHitsNext` (tail), `HitCounted` (tail), `ClearHits` |
| Reads | `$7AC0` (`BeamPower`); `$8501`-`$85F8` (`EnemySlots`) |
| Writes | `$7A96` (`HitResult`); `$7AC0` (`BeamPower`); `$7AD5` (`Scratch+6`); `$8500`-`$85F8` (`Im2Table+256`, `EnemySlots`) |

### `HitCounted` (`$A592`)

**HitCounted**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 9 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,901 calls (`stage1/rec/l4` 4,901) |
| Called from | `ProcessHitsNext` (tail), `HitEnemy` (tail) |
| Calls | `ProcessHitsNext` (tail) |
| Writes | `$7A96` (`HitResult`) |

### `EnemyDies` (`$A599`)

**An enemy is destroyed: an explosion and the score award**

With no free explosion record AwardScore is skipped and AddScore gets the caller's DE (a stale value).

Witness: L1 1580 (boss, c1, continue, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 272 t-states own (0.00 %) |
| Runs (the other recordings) | 1,576 calls (`stage1/rec/l7` 325, `stage1/rec/l1` 161, `docs/integrate/rec/boss` 153 and 14 more) |
| Called from | `EnemyHit`, `TitleScreen` |
| Calls | `FreeExplosion`, `AwardScore`, `AddScore` |

### `FreeExplosion` (`$A5A5`)

**HL = a free explosion record**

Witness: L1 1740 (boss, c1, continue, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 162 t-states own (0.00 %) |
| Runs (the other recordings) | 1,736 calls (`stage1/rec/l7` 325, `docs/integrate/rec/boss` 309, `stage1/rec/l1` 165 and 14 more) |
| Called from | `EnemyDies`, `BossBlastOnce`, `TitleScreen` |
| Reads | `$5FC1`-`$5FF4` (`Explosions`) |

### `AwardScore` (`$A5B4`)

**Start the explosion by the kind's size and return DE = the award (ScoreAwards)**

The kind's byte 2: high nibble the explosion size (`$10` sound 8, `$40` sound `$0A`, else 9), low nibble the award.

Witness: L1 1584 (boss, c1, continue, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 1,277 t-states own (0.00 %) |
| Runs (the other recordings) | 1,580 calls (`stage1/rec/l7` 325, `stage1/rec/l1` 165, `docs/integrate/rec/boss` 153 and 14 more) |
| Called from | `EnemyDies`, `TitleScreen` |
| Calls | `PlaySound` |
| Reads | `$70DC`-`$70FB` (`ScoreAwards`, `ShadowLine0Tail`); `$7ACF`-`$7AD0` (`Scratch`); `$8501`-`$85F2` (`EnemySlots`); `$DA61`-`$DB44` (`LoaderLeftover+5405`); `$DB7E`-`$DB91` (`LoaderLeftover+5690`); `$DC1B`-`$DC32` (`LoaderLeftover+5847`); 29 more ranges |
| Writes | `$5FC1`-`$5FF6` (`Explosions`); `$7AD1`-`$7AD2` (`Scratch+2`) |

## interrupt

`src/game/interrupt.asm`

### `Interrupt` (`$BE23`)

**The IM 2 handler: count IntTicks, run the due tasks of TaskTable**

For each of the 5 entries (address, switch, counter, reload): when the switch's bit 0 is set the counter counts down, and at 0 is reloaded and the task called.

Witness: L1 159333 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 5,441 calls, 4,084,144 t-states own (0.29 %) |
| Runs (the other recordings) | 153,892 calls (`stage1/rec/l3` 15,045, `stage1/rec/l1` 14,920, `docs/integrate/rec/boss` 13,177 and 18 more) |
| Called from | `Im2Jump` (tail) |
| Calls | `RunTask` |
| Reads | `$7A8A` (`IntTicks`); `$BE60`-`$BE78` (`TaskTable`) |
| Writes | `$7A8A` (`IntTicks`); `$BE63`-`$BE77` (`TaskTable+3`) |

### `RunTask` (`$BE5E`)

**JP (DE)**

Witness: L1 205616 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 5,931 calls, 47,448 t-states own (0.00 %) |
| Runs (the other recordings) | 199,685 calls (`stage1/rec/l3` 19,891, `stage1/rec/l1` 19,769, `docs/integrate/rec/boss` 17,497 and 18 more) |
| Called from | `Interrupt` |
| Calls | `CycleTitleColour`, `StarTask`, `SoundTask1`, `SoundTask2`, `SoundTask3` |

### `StarTask` (`$BE79`)

**Interrupt task 0: move the background stars in the empty cells**

Witness: L1 52613 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,475 calls, 3,965,810 t-states own (0.29 %) |
| Runs (the other recordings) | 5,645 calls (`stage1/rec/gameover` 4,291, `stage1/rec/hiscore` 1,066, `stage1/rec/l1` 36 and 7 more) |
| Called from | `TitleLoop`, `TitleLogo`, `LogoRow`, `RunTask` |
| Calls | `StarStep` |
| Reads | `$7A9D` (`StarFrame`); `$8084`-`$80D0` (`RowTable+4`, `RowTableEnd`) |
| Writes | `$7A9D` (`StarFrame`) |

### `StarStep` (`$BE97`)

**Move one star; skip cells with something in them**

Witness: L1 999647 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 36,271 calls, 16,694,944 t-states own (1.20 %) |
| Runs (the other recordings) | 963,376 calls (`stage1/rec/gameover` 102,600, `stage1/rec/l1` 92,815, `stage1/rec/l3` 92,758 and 18 more) |
| Called from | `StarTask` |
| Calls | `StarCell` |
| Reads | `$4020`-`$40FD` (screen); `$4800`-`$48FD` (screen); `$5000`-`$507D` (screen); `$7380`-`$73A5` (`TitleStars`); `$7A9D` (`StarFrame`); `$7E00` (`SolidMap`); 3 more ranges |
| Writes | `$4020`-`$40FE` (screen); `$4120`-`$41FE` (screen); `$4800`-`$49FE` (screen); `$5000`-`$507E` (screen); `$5100`-`$517E` (screen); `$7381`-`$73A5` (`TitleStars+1`); 2 more ranges |

### `StarCell` (`$BF45`)

**The star's screen byte and its SolidMap cell**

Witness: L1 979947 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 36,083 calls, 3,096,602 t-states own (0.22 %) |
| Runs (the other recordings) | 943,864 calls (`stage1/rec/gameover` 102,123, `stage1/rec/l1` 90,717, `stage1/rec/l3` 90,658 and 18 more) |
| Called from | `StarStep` |
| Reads | `$7381`-`$73A5` (`TitleStars+1`); `$8087`-`$80FD` (`RowTable+7`, `RowTableEnd`, `PlayStarStates`) |

### `ReadKey` (`$BF55`)

**Scan the keyboard: the key's half-row and bit when exactly one key is down**

Witness: L1 52569 (c1, deaths-l7, ending, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 31,108 calls, 18,724,977 t-states own (1.35 %) |
| Runs (the other recordings) | 21,461 calls (`stage1/rec/l3` 3,698, `stage1/rec/l2` 3,425, `stage1/rec/ending` 3,414 and 7 more) |
| Called from | `WaitKey`, `DefineKey` |
| Calls | `ReadKeyRow` (falls into) |
| Reads | `$72F1`-`$72F7` (`KeyBitTable+1`, `CarrierColours`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `ReadKeyRow` (`$BF5B`)

**ReadKeyRow**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 248,864 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 57,333 calls (`stage1/rec/l3` 29,587, `stage1/rec/l4` 19,665, `stage1/rec/l5` 6,847 and 1 more) |
| Called from | `ReadKey` (falls into), `ReadKeyNext` (tail) |
| Calls | `ReadKeyNext` (falls into) |
| Reads | `$72F2`-`$72F7` (`KeyBitTable+2`, `CarrierColours`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `ReadKeyNext` (`$BF6F`)

**ReadKeyNext**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 248,864 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 19,429 calls (`stage1/rec/l4` 18,194, `stage1/rec/l6` 1,235) |
| Called from | `ReadKeyRow` (falls into) |
| Calls | `ReadKeyRow` (tail) |
| Reads | `$72F2`-`$72F7` (`KeyBitTable+2`, `CarrierColours`) |

### `WaitKey` (`$BF87`)

**Wait for exactly one key**

Witness: L1 49338 (c1, deaths-l7, ending, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 9 calls, 1,310,701 t-states own (0.09 %) |
| Runs (the other recordings) | 3,441 calls (`stage1/rec/l2` 3,425, `stage1/rec/ending` 3, `stage1/rec/l3` 2 and 7 more) |
| Called from | `DefineKey`, `LoadLevel`, `LoadLevelStart`, `LoadError` |
| Calls | `ReadKey` |

### `DefineKeys` (`$BF92`)

**ENTER held: define the six keys by prompts**

Witness: L1 6476 (c1, gameover, hiscore).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,356 calls, 47,800 t-states own (0.00 %) |
| Runs (the other recordings) | 5,120 calls (`stage1/rec/gameover` 4,096, `stage1/rec/hiscore` 1,024) |
| Called from | `TitleLoop` |
| Calls | `DefineKey`, `SelectControl` (tail), `ClearTextRow` |
| Ports in | `$BFFE` |

### `DefineKey` (`$BFD4`)

**Prompt for one key and store it**

Witness: L1 6 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 6 calls, 132,112 t-states own (0.01 %) |
| Called from | `DefineKeys` |
| Calls | `ReadKey`, `WaitKey`, `PrintRow22`, `PrintText` |
| Reads | `$7780`-`$778A` (`DefinedKeys`) |
| Writes | `$7780`-`$778B` (`DefinedKeys`) |

### `SelectControl` (`$C011`)

**Pick the control method by the fire that is pressed**

Keys 2, Interface 2 1, Kempston 3 (only when KempstonAbsent is 0), Sinclair 4: ControlMethod, and out of the title through the stack.

Witness: L1 123098 (c1, ctl-if2, ctl-kempston, ctl-sinclair, gameover, hiscore).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 22,863 calls, 3,951,131 t-states own (0.28 %) |
| Runs (the other recordings) | 100,235 calls (`stage1/rec/gameover` 90,128, `stage1/rec/hiscore` 2,685, `stage1/rec/ctl-sinclair` 2,474 and 2 more) |
| Called from | `TitleLoop`, `DefineKeys` (tail) |
| Calls | `ReadIf2`, `ReadKeys`, `ReadKempston`, `ReadSinclair`, `PlaySound`, `WaitFrames` |
| Reads | `$7A8B` (`KempstonAbsent`) |
| Writes | `$74FB` (`ControlMethod`) |

## util

`src/game/util.asm`

### `NextRandom` (`$C05D`)

**A = the next ROM byte at RandomPtr**

Witness: L1 2364 (boss, ending, l7, l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,231 calls (`docs/integrate/rec/boss` 1,854, `stage1/rec/l7` 183, `stage1/rec/l8` 152 and 1 more) |
| Called from | `BossBlastOnce`, `TitleScreen` |
| Reads | `$7ACD`-`$7ACE` (`RandomPtr`) |
| Writes | `$7ACD`-`$7ACE` (`RandomPtr`) |

### `ClearHits` (`$C06A`)

**HitCount and HitCellCount = 0, HitList cleared**

Witness: L1 100195 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,293 calls, 79,931 t-states own (0.01 %) |
| Runs (the other recordings) | 98,902 calls (`stage1/rec/l1` 10,458, `docs/integrate/rec/boss` 9,442, `stage1/rec/l3` 8,938 and 18 more) |
| Called from | `LogoRow`, `ShipDies`, `MoveCarriers`, `HitEnemy` |
| Calls | `ClearBlock` (tail) |
| Writes | `$71E0` (`HitCellCount`); `$7A95` (`HitCount`) |

### `ClearColourOverride` (`$C07A`)

**The drawers' colour override off**

Witness: L1 69052 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 962 calls, 25,974 t-states own (0.00 %) |
| Runs (the other recordings) | 68,090 calls (`stage1/rec/l1` 7,158, `docs/integrate/rec/boss` 6,462, `stage1/rec/l3` 5,984 and 18 more) |
| Called from | `ShipShield`, `MoveAntiAir` (tail), `ShotPathStep` (tail), `ShotEnd` (tail), `MoveMissileSet` |
| Writes | `$8EB1` (`CellMark+15`) |

### `PrintRow22` (`$C07F`)

**Print the text HL double height on the text row, column C**

Witness: L1 1256 (c1, deaths-l7, ending, hiscore, hiscore-typed, pause, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 12 calls, 84 t-states own (0.00 %) |
| Runs (the other recordings) | 1,244 calls (`docs/rtB/rec/pause` 1,184, `stage1/rec/ending` 7, `stage1/rec/l2` 7 and 10 more) |
| Called from | `CheckPause`, `InsertHiScore`, `DefineKey`, `LoadLevel`, `LoadLevelStart`, `LoadError` |
| Calls | `PrintText` (falls into) |

### `PrintText` (`$C081`)

**Print the text HL double height at row B column C**

Witness: L1 41361 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 775 calls, 12,400 t-states own (0.00 %) |
| Runs (the other recordings) | 40,586 calls (`stage1/rec/hiscore-typed` 26,043, `stage1/rec/hiscore` 10,867, `docs/rtB/rec/pause` 1,248 and 16 more) |
| Called from | `PrintHiScores`, `ShowLoadingScreen`, `PrintAndWait`, `DefineKey`, `PrintRow22` (falls into), `ClearTextRow`, `LoadLevel`, `LoadLevelStart`, `LoadError` |
| Calls | `PrintTextA` (tail) |

### `PrintTextNormal` (`$C084`)

**Print the text HL at row B column C**

Witness: L1 21566 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 237 calls, 1,659 t-states own (0.00 %) |
| Runs (the other recordings) | 21,329 calls (`stage1/rec/l1` 1,884, `stage1/rec/l4` 1,811, `stage1/rec/l7` 1,795 and 18 more) |
| Called from | `TitleLoop`, `Continue`, `BigDigit`, `DrawLives`, `FireBeam`, `DrawHud`, `PrintScore` |
| Calls | `PrintTextA` (falls into) |
| Reads | `$70DA`-`$70DB` (`BeamMeterFull`, `BeamMeterStep`); `$71C9`-`$71CF` (`ScoreText`); `$72DE`-`$72E7` (`BeamMeterEmpty`); `$7A94` (`TextHeight`); `$7B68`-`$7BB7` (`Font+120`); `$7BC8`-`$7BEF` (`Font+216`); 1 more ranges |
| Writes | `$508B`-`$51A7` (screen); `$528B`-`$52A7` (screen); `$538B`-`$53A7` (screen); `$548B`-`$54A7` (screen); `$558B`-`$55A7` (screen); `$568B`-`$56A7` (screen); 2 more ranges |

### `PrintTextA` (`$C086`)

**PrintTextA**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 1,012 calls, 1,037,266 t-states own (0.07 %) |
| Runs (the other recordings) | 59,747 calls (`stage1/rec/hiscore-typed` 27,173, `stage1/rec/hiscore` 12,645, `stage1/rec/l4` 1,985 and 16 more) |
| Called from | `PrintText` (tail), `PrintTextNormal` (falls into) |
| Calls | `PrintHalf` |
| Reads | `$7080`-`$71CF` (`KeyPromptText`, `PilotStandByText`, `MissionOverText`, `ContinueText` and 16 more); `$7280`-`$72E7` (`RewindSide2Text`, `SearchingText`, `ErrorInLoadingText`, `CreditText` and 2 more); `$73A8`-`$73BB` (`NoText`, `CollapseColumns`, `DigitChars`); `$7480`-`$7592` (`TitleTexts`, `EnterNameText`, `ControlBits`, `ShadowLine4Tail` and 1 more); `$76F5`-`$76FF` (`RewindTapeText`); `$7A94` (`TextHeight`); 6 more ranges |
| Writes | `$4068`-`$4FF2` (screen); `$5067`-`$57F7` (screen); `$7A94` (`TextHeight`) |

### `PrintHalf` (`$C0D9`)

**Pixel lines of a character, each doubled**

Witness: L1 631829 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 2,572 calls, 539,817 t-states own (0.04 %) |
| Runs (the other recordings) | 629,257 calls (`stage1/rec/hiscore-typed` 417,793, `stage1/rec/hiscore` 172,840, `docs/rtB/rec/pause` 28,544 and 16 more) |
| Called from | `PrintTextA` |
| Reads | `$7B00`-`$7BB7` (`Font+16`); `$7BE0`-`$7CC7` (`Font+240`) |
| Writes | `$4006`-`$57FF` (screen) |

### `GetCell` (`$C0E4`)

**A = the SolidMap cell at row B column C**

Witness: L1 267495 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 589 calls, 52,858 t-states own (0.00 %) |
| Runs (the other recordings) | 266,906 calls (`stage1/rec/l2` 48,234, `stage1/rec/l4` 48,172, `stage1/rec/l5` 30,197 and 17 more) |
| Called from | `MoveMissile`, `MoveShip`, `ForceTarget`, `ForceProbe`, `ForceTry`, `MoveShipShots`, `MoveForceShots`, `MoveBeam`, `AntiAirDown`, `GetCellWindow`, `DrawTrail`, `ReadCellWindow`, `ExplodeSoftCell`, `BossBlastOnce`, `ClearCells`, `MoveEnemyShots`, `TitleScreen` |
| Reads | `$7811`-`$7A4D` (`PlayAttrs+17`); `$7A6B`-`$7A6D` (`PlayAttrs+619`); `$7E00`-`$80B6` (`SolidMap`, `RowTable`); `$80CA`-`$8108` (`RowTable+74`, `RowTableEnd`, `PlayStarStates`, `DrawnMap`); `$812B`-`$81A7` (`DrawnMap+43`, `ShowLoadingScreen`, `ScrollRowLeft`); `$81C6` (`ScrollerText+29`); 1 more ranges |

### `BossBlastStep` (`$C0F9`)

**Run the boss explosion twice a pass**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 7,106 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `BossBlastOnce` (falls into) |

### `BossBlastOnce` (`$C0FC`)

**One step of the boss explosion: random explosions over the boss, then the sweep**

Witness: L1 66644 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 836 calls, 24,578 t-states own (0.00 %) |
| Runs (the other recordings) | 65,808 calls (`stage1/rec/l1` 6,966, `docs/integrate/rec/boss` 6,294, `stage1/rec/l3` 5,952 and 18 more) |
| Called from | `BossBlastStep` (falls into) |
| Calls | `FreeExplosion`, `NextRandom`, `GetCell`, `l_C1DF`, `ClearCells`, `PlaySound` |
| Reads | `$7A89` (`FrameCounter`); `$7AC9`-`$7ACC` (`BossBlast`, `BossBlastCount`, `BossBlastPos`); `$7E40`-`$807E` (`SolidMap+64`, `EntryCopySource`) |
| Writes | `$5FC1`-`$5FF6` (`Explosions`); `$7A9B` (`LevelEndTimer`); `$7AC9`-`$7ACC` (`BossBlast`, `BossBlastCount`, `BossBlastPos`); `$C138`-`$C139` (`l_C134+4`) |

### `BossDestroyed` (`$C19C`)

**Start the boss explosion (called by the levels' boss code)**

Sets ScrollHalted, BossBlast and WavesHalted; puts a RET into ShipDies + 3 (immortal) and ShieldControls (the controls off); RandomPtr and BossBlastPos = 0; the explosions cleared; the solid cells marked. Run only in the boss recording, where a POKE frees the slot the level code waits for (no boss was killed by hits).

Witness: L1 1 (boss).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`docs/integrate/rec/boss` 1) |
| Called from | `TitleScreen` |
| Calls | `l_C1DF` (falls into), `ClearBlock` |
| Reads | `$7E00`-`$807F` (`SolidMap`, `EntryCopySource`) |
| Writes | `$7A8E`-`$7A8F` (`ScrollHalted`, `WavesHalted`); `$7AC9`-`$7ACE` (`BossBlast`, `BossBlastCount`, `BossBlastPos`, `RandomPtr`); `$7E0E`-`$7E15` (`SolidMap+14`); `$7E2D`-`$7E36` (`SolidMap+45`); `$7E4D`-`$7E57` (`SolidMap+77`); `$7E6F`-`$7EDB` (`SolidMap+111`); 7 more ranges |

### `l_C1DF` (`$C1DF`)

**l_C1DF**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 78 calls (`docs/integrate/rec/boss` 78) |
| Called from | `BossBlastOnce`, `BossDestroyed` (falls into) |

### `EnemyHit` (`$C1E0`)

**The slot was hit: a sound while it has hits left, else EnemyDies**

Witness: L1 201705 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 461 calls, 14,988 t-states own (0.00 %) |
| Runs (the other recordings) | 201,244 calls (`stage1/rec/l3` 49,735, `stage1/rec/l1` 30,040, `docs/integrate/rec/boss` 24,969 and 17 more) |
| Called from | `MoveEnemiesNext` |
| Calls | `EnemyDies`, `PlaySound` |
| Reads | `$8501`-`$85FC` (`EnemySlots`) |
| Writes | `$7ACF`-`$7AD0` (`Scratch`); `$8509`-`$85F3` (`EnemySlots+8`) |

### `ClearCells` (`$C20B`)

**Clear D rows of E cells of SolidMap from BC**

Witness: L1 4341 (boss, l x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,341 calls (`docs/integrate/rec/boss` 1,345, `stage1/rec/l1` 1,266, `stage1/rec/l4` 960 and 3 more) |
| Called from | `BossBlastOnce`, `ClearCellsTag`, `TitleScreen` |
| Calls | `GetCell` |
| Writes | `$7811`-`$7A7E` (`PlayAttrs+17`); `$7E00`-`$807B` (`SolidMap`, `EntryCopySource`) |

### `StartWaveAt` (`$C225`)

**Start a wave from a record at HL, for the levels' code**

Witness: L1 1030 (boss, deaths-l7, ending, force, restart, l1, l3-l5, l7, l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,030 calls (`stage1/rec/l7` 265, `stage1/rec/l8` 160, `stage1/rec/l3` 140 and 8 more) |
| Called from | `TitleScreen` |
| Calls | `StartWave` |
| Reads | `$E317`-`$E319` (`TitleScreen+1535`); `$EF8F`-`$EF91` (`TitleScreen+4727`); `$EFC2`-`$EFC4` (`TitleScreen+4778`); `$F4EA`-`$F4EC` (`TitleScreen+6098`); `$F526`-`$F528` (`TitleScreen+6158`); `$F56D`-`$F56F` (`TitleScreen+6229`); 4 more ranges |
| Writes | `$908F` (`StartWaveDone`) |

### `AddScore` (`$C23F`)

**Add D to the score digit E, carrying**

Witness: L1 1635 (boss, c1, continue, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 452 t-states own (0.00 %) |
| Runs (the other recordings) | 1,631 calls (`stage1/rec/l7` 329, `stage1/rec/l1` 168, `docs/integrate/rec/boss` 161 and 14 more) |
| Called from | `MoveCarrierB`, `ForceRecordOf`, `EnemyDies`, `TitleScreen` |
| Reads | `$71C9`-`$71CC` (`ScoreText`) |
| Writes | `$71C9`-`$71CC` (`ScoreText`); `$7A99` (`ScoreChanged`) |

### `LevelEnd` (`$C25E`)

**The level's end: at each step of LevelEndTimer the next part, then the next level**

Acts when (LevelEndTimer - 1) AND `$1F` = 0. LevelDigit '8': '9', the waves on, ShipDies+3 = RET (immortal), ShieldControls left RET (unarmed) until ClearPlayState, play goes on; '9': '0', then the normal end, so LoadLevel loads level 1 (the wrap).

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 12,151 t-states own (0.00 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `StarsOff`, `StartLife` (tail), `RestartPoint`, `ScrollRows`, `ForceRecordOf`, `PlaySound`, `Wait256`, `LoadLevel` |
| Reads | `$719C` (`LevelDigit`); `$7A9B` (`LevelEndTimer`); `$7ABE` (`ForceLevel`) |
| Writes | `$719C` (`LevelDigit`); `$7A8F`-`$7AB0` (`WavesHalted`, `WavePtr`, `TextHeight`, `HitCount` and 19 more); `$91F5` (`ShipDies+3`); `$95A5` (`ShieldControls`) |

### `ClearTextRow` (`$C2C5`)

**Clear the text row**

Witness: L1 90 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 8 calls, 16,579 t-states own (0.00 %) |
| Runs (the other recordings) | 82 calls (`stage2/rec/deaths-l7` 9, `stage1/rec/continue` 7, `stage1/rec/hiscore` 6 and 16 more) |
| Called from | `CheckPause`, `LoseLife`, `DefineKeys`, `LoadLevel`, `LoadLevelStart`, `LoadError` |
| Calls | `PrintText` |

### `CheckRestart` (`$C2D6`)

**At a checkpoint column, set the restart column and wave**

Witness: L1 33313 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 43,488 t-states own (0.00 %) |
| Runs (the other recordings) | 32,895 calls (`stage1/rec/l1` 3,482, `docs/integrate/rec/boss` 3,146, `stage1/rec/l3` 2,975 and 18 more) |
| Called from | `MainLoopPatch` |
| Reads | `$7A84` (`MapColumn`); `$C4B1`-`$C4B9` (`LevelChecks`, `LevelWaves`) |
| Writes | `$C4AE`-`$C4B0` (`LevelSpace`, `LevelRestartWave`) |

### `EnemyFire` (`$C2FB`)

**An enemy fires at the ship while Shooters is below ShooterLimit**

Witness: L1 43995 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1, l3-l7).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 457 calls, 21,355 t-states own (0.00 %) |
| Runs (the other recordings) | 43,538 calls (`docs/integrate/rec/boss` 8,292, `stage1/rec/l1` 8,292, `stage1/rec/l3` 6,675 and 14 more) |
| Called from | `MoveEnemiesNext` |
| Reads | `$7A9C`-`$7AA2` (`DrawTag`, `StarFrame`, `ShooterLimit`, `Shooters` and 3 more); `$8501`-`$85D0` (`EnemySlots`); `$85E2` (`EnemySlots+225`) |
| Writes | `$7A9F` (`Shooters`); `$8386`-`$83D3` (`EnemyShots`); `$8501`-`$85D0` (`EnemySlots`); `$85E2` (`EnemySlots+225`) |

### `MoveEnemyShots` (`$C348`)

**Move the enemy shots; one that reaches the ship kills it**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 874,342 t-states own (0.06 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `DrawSprite`, `LevelObject`, `SlotFlags`, `ShipDies` (tail), `GetCell`, `MoveByBits` |
| Reads | `$7A89` (`FrameCounter`); `$7A9F` (`Shooters`); `$8386`-`$83D7` (`EnemyShots`); `$8501`-`$85D0` (`EnemySlots`); `$85E2` (`EnemySlots+225`) |
| Writes | `$7A9C`-`$7A9F` (`DrawTag`, `StarFrame`, `ShooterLimit`, `Shooters`); `$8386`-`$83D3` (`EnemyShots`); `$8501`-`$85D0` (`EnemySlots`); `$85E2` (`EnemySlots+225`) |

### `MoveByBits` (`$C3D1`)

**Step BC by the direction bits of A: bit 0 up, 1 down, 2 left, 3 right**

Witness: L1 306115 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 735 calls, 59,566 t-states own (0.00 %) |
| Runs (the other recordings) | 305,380 calls (`stage1/rec/l3` 63,343, `stage1/rec/l1` 49,140, `docs/integrate/rec/boss` 37,454 and 17 more) |
| Called from | `MoveEnemiesNext`, `MoveMissile`, `MoveShipShots`, `MoveEnemyShots`, `TitleScreen` |

### `SoftCellsOn` (`$C3E5`)

**Patch the drawers for the soft cells**

Witness: L1 3284 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 156 t-states own (0.00 %) |
| Runs (the other recordings) | 3,280 calls (`stage1/rec/l4` 1,238, `docs/integrate/rec/boss` 626, `stage1/rec/l1` 626 and 15 more) |
| Called from | `ExplodeSoftCell`, `TitleScreen`, `DrawFirstScreen` |
| Calls | `SoftCellsSet` (tail) |
| Writes | `$8EBF` (`l_8EB7+8`) |

### `SoftCellsOff` (`$C3EE`)

**Restore them**

Witness: L1 12266 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 108 t-states own (0.00 %) |
| Runs (the other recordings) | 12,262 calls (`docs/integrate/rec/boss` 4,977, `stage1/rec/l1` 4,977, `stage1/rec/l4` 1,238 and 15 more) |
| Called from | `ExplodeSoftCell`, `TitleScreen`, `DrawFirstScreen` |
| Calls | `SoftCellsSet` (falls into) |
| Writes | `$8EBF` (`l_8EB7+8`) |

### `SoftCellsSet` (`$C3F5`)

**SoftCellsSet**

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 8 calls, 184 t-states own (0.00 %) |
| Runs (the other recordings) | 15,542 calls (`docs/integrate/rec/boss` 5,603, `stage1/rec/l1` 5,603, `stage1/rec/l4` 2,476 and 15 more) |
| Called from | `SoftCellsOn` (tail), `SoftCellsOff` (falls into) |
| Writes | `$8F10` (`CellFreeEmpty+5`) |

### `ClearCellsTag` (`$C3F9`)

**ClearCells through the attribute shadow**

Witness: L1 2220 (boss, l1, l2, l4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,220 calls (`stage1/rec/l4` 960, `docs/integrate/rec/boss` 626, `stage1/rec/l1` 626 and 1 more) |
| Called from | `DrawCellBlast`, `TitleScreen` |
| Calls | `ClearCells` |
| Writes | `$C0EB` (`GetCell+7`); `$C214` (`l_C213+1`) |

### `DrawExplosions` (`$C40E`)

**Step and draw the explosions**

Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 418 calls, 446,705 t-states own (0.03 %) |
| Runs (the other recordings) | 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `DrawSprite`, `GameObject` |
| Reads | `$5FC1`-`$5FFA` (`Explosions`); `$75DD`-`$75FC` (`ExplosionFrames`, `ShadowLine5`) |
| Writes | `$5FC1`-`$5FF4` (`Explosions`) |

### `DrawHud` (`$C44B`)

**Paint and print the HUD: BEAM, the meter, HI SCORE, the lives and the score**

Witness: L1 96 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, pause, restart, l2-l8).

[Animation: `DrawHud` at work](img/routines/DrawHud.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 7 calls, 2,435 t-states own (0.00 %) |
| Runs (the other recordings) | 89 calls (`stage2/rec/deaths-l7` 15, `stage1/rec/continue` 14, `stage1/rec/hiscore` 12 and 14 more) |
| Called from | `StartPlayField`, `CheckPause` (tail), `LoseLife`, `PrintScore` |
| Calls | `DrawLives`, `PrintTextNormal`, `PrintScore`, `FillBlock` |
| Reads | `$7AA0` (`Lives`) |

## sound

`src/game/sound.asm`

### `PlaySound` (`$F87C`)

**Start sound H with the channel bits L (the priority and the timbre)**

Witness: L1 13762 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13,762 calls (`stage1/rec/l2` 1,934, `stage1/rec/l4` 1,798, `stage1/rec/l5` 1,732 and 17 more) |
| Called from | `Continue`, `Silence`, `CommandWave`, `ShipDies`, `LoseLife`, `MissionOver`, `InsertHiScore`, `ShipShield`, `ForceDraw`, `MoveCarrierB`, `FireBeam`, `ForceGround`, `FireMissiles`, `ShotFire`, `BounceShot`, `ProcessHitsNext`, `AwardScore`, `SelectControl`, `BossBlastOnce`, `EnemyHit`, `LevelEnd`, `TitleScreen`, `PrintScore` |
| Calls | `SoundStart` |

### `SoundStart` (`$F894`)

**Find a channel at the priority, set its timbre and its script**

Witness: L1 13762 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13,762 calls (`stage1/rec/l2` 1,934, `stage1/rec/l4` 1,798, `stage1/rec/l5` 1,732 and 17 more) |
| Called from | `PlaySound` |
| Calls | `SoundSetScript` (tail) |
| Reads | `$FBCE`-`$FBD2` (`SoundData+104`) |
| Writes | `$F8DE`-`$F8DF` (`SoundTimbre+1`); `$F8F1`-`$F912` (`SoundTask1+9`, `SoundTask1Tail`, `SoundTask2`, `SoundTask2Tail` and 1 more) |

### `SoundTask1` (`$F8E8`)

**Interrupt task 1: run channel 1's script**

Witness: L1 51349 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 51,349 runs of its first instruction, entered by a jump (`stage1/rec/l3` 5,015, `stage1/rec/l1` 4,973, `docs/integrate/rec/boss` 4,392 and 18 more) |
| Called from | `RunTask`, `SoundReturn`, `SoundRepeat`, `SoundLoop` |
| Calls | `SoundStep` (tail), `TimbreHigh`, `TimbreMid`, `TimbreLow` |

### `SoundTask2` (`$F8F8`)

**Interrupt task 2: run channel 2's script**

Witness: L1 51953 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 51,953 runs of its first instruction, entered by a jump (`stage1/rec/l3` 5,015, `stage1/rec/l1` 5,007, `docs/integrate/rec/boss` 4,426 and 18 more) |
| Called from | `RunTask`, `SoundReturn`, `SoundRepeat`, `SoundLoop` |
| Calls | `SoundStep` (tail), `TimbreHigh`, `TimbreMid`, `TimbreLow` |

### `SoundTask3` (`$F908`)

**Interrupt task 3: run channel 3's script**

Witness: L1 53982 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

[Animation: `SoundTask3` at work](img/routines/SoundTask3.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`stage1/rec/l2` 17) |
| Called from | `RunTask`, `SoundNop`, `SoundReturn`, `SoundRepeat`, `SoundLoop` |
| Calls | `TimbreHigh`, `TimbreMid`, `TimbreLow` |

### `SoundStep` (`$F913`)

**One step of a channel's script: a command byte and its routine (the table at `$FBEB`)**

Witness: L1 157284 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 103,302 calls (`stage1/rec/l3` 10,030, `stage1/rec/l1` 9,980, `docs/integrate/rec/boss` 8,818 and 18 more) |
| Called from | `SoundTask1` (tail), `SoundTask2` (tail) |
| Calls | `SoundEnd`, `SoundCall`, `SoundNop`, `SoundReturn`, `SoundRepeat`, `SoundLoop`, `NoiseBurst`, `ChordPlay1`, `ChordPlay3`, `ChordPlay5`, `ChordPlay6` |
| Reads | `$5B64`-`$5D01` (`EntryCopy`, `BitReverse`); `$72E8`-`$72EF` (`ContinueData`, `ContinueRow`); `$FBCD`-`$FBD2` (`SoundData+103`); `$FBEB`-`$FC06` (`SoundData+133`); `$FC51`-`$FDA4` (`SoundData+235`, `SoundScripts`, `SoundScriptsEnd`) |
| Writes | `$5B64`-`$5D00` (`EntryCopy`, `BitReverse`); `$72E8`-`$72EE` (`ContinueData`, `ContinueRow`); `$91F2` (`ShipDies`); `$FBCD`-`$FBD2` (`SoundData+103`); `$FC51`-`$FDA3` (`SoundData+235`, `SoundScripts`, `SoundScriptsEnd`) |

### `SoundEnd` (`$F948`)

**SoundEnd**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11,566 runs of its first instruction, entered by a jump (`stage1/rec/l5` 1,526, `stage1/rec/l4` 1,460, `stage1/rec/l8` 1,281 and 17 more) |
| Called from | `SoundStep` |
| Writes | `$FBCD`-`$FBD2` (`SoundData+103`) |

### `TimbreHigh` (`$F952`)

**Timbre for PlaySound bits `$80`: note length shift 2, mask 3, noise bursts high byte >> 2**

Witness: L1 78715 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 78,715 calls (`stage1/rec/l3` 8,693, `stage1/rec/gameover` 7,257, `stage1/rec/l7` 5,879 and 18 more) |
| Called from | `SoundTask1`, `SoundTask2`, `SoundTask3` |
| Writes | `$F9E8`-`$F9FE` (`NotePeriod+1`, `l_F9EB`, `l_F9F7`); `$FA84` (`l_FA83+1`) |

### `TimbreMid` (`$F963`)

**Timbre for bits `$40`: shift 3, mask 7**

Witness: L1 27852 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27,852 calls (`stage1/rec/l2` 6,535, `stage1/rec/l3` 3,323, `stage1/rec/l1` 3,316 and 16 more) |
| Called from | `SoundTask1`, `SoundTask2`, `SoundTask3` |
| Writes | `$F9E8`-`$F9FE` (`NotePeriod+1`, `l_F9EB`, `l_F9F7`); `$FA84` (`l_FA83+1`) |

### `TimbreLow` (`$F975`)

**Timbre for bits `$20` (any other non-zero): shift 4, mask 15**

Witness: L1 50717 (boss, continue, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 50,717 calls (`stage1/rec/l1` 6,280, `stage1/rec/l4` 5,968, `docs/integrate/rec/boss` 5,632 and 13 more) |
| Called from | `SoundTask1`, `SoundTask2`, `SoundTask3` |
| Writes | `$F9E8`-`$F9FE` (`NotePeriod+1`, `l_F9EB`, `l_F9F7`); `$FA84` (`l_FA83+1`) |

### `SoundCall` (`$F985`)

**SoundCall**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 runs of its first instruction, entered by a jump (`stage1/rec/l2` 17) |
| Called from | `SoundStep` |
| Calls | `SoundPush` (falls into) |

### `SoundPush` (`$F987`)

**Keep the script pointer**

Witness: L1 290 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 290 calls (`stage1/rec/l2` 33, `stage1/rec/l3` 27, `stage1/rec/l1` 24 and 16 more) |
| Called from | `SoundCall` (falls into), `SoundRepeat` |
| Calls | `SoundNop` (falls into) |
| Reads | `$FBCD`-`$FBD2` (`SoundData+103`) |
| Writes | `$FBD3`-`$FBDC` (`SoundData+109`) |

### `SoundNop` (`$F994`)

**SoundNop**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 150 calls (`stage1/rec/l1` 24, `docs/integrate/rec/boss` 23, `stage1/rec/gameover` 21 and 9 more) |
| Called from | `SoundStep`, `SoundPush` (falls into) |
| Calls | `SoundTask3` |

### `SoundReturn` (`$F996`)

**SoundReturn**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 68 calls (`stage1/rec/l2` 68) |
| Called from | `SoundStep`, `SoundLoop` (tail) |
| Calls | `SoundTask1`, `SoundTask2`, `SoundTask3` |
| Reads | `$FBD3`-`$FBDC` (`SoundData+109`) |
| Writes | `$FBD1`-`$FBD2` (`SoundData+107`) |

### `SoundRepeat` (`$F9A5`)

**SoundRepeat**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 273 runs of its first instruction, entered by a jump (`stage1/rec/l3` 27, `stage1/rec/l1` 24, `docs/integrate/rec/boss` 23 and 16 more) |
| Called from | `SoundStep` |
| Calls | `SoundTask1`, `SoundTask2`, `SoundTask3`, `SoundPush` |
| Reads | `$5B65`-`$5BBF` (`EntryCopy+1`); `$5BD5` (`EntryCopy+113`); `$5C17`-`$5C6B` (`EntryCopy+179`); `$5CA3`-`$5CA9` (`EntryCopy+319`); `$5CBB`-`$5CC7` (`EntryCopy+343`); `$5CF5`-`$5CFB` (`EntryCopy+401`); 3 more ranges |
| Writes | `$FBE3`-`$FBE6` (`SoundData+125`) |

### `SoundLoop` (`$F9BA`)

**SoundLoop**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,180 runs of its first instruction, entered by a jump (`stage1/rec/gameover` 230, `stage1/rec/hiscore` 230, `stage1/rec/l1` 184 and 16 more) |
| Called from | `SoundStep` |
| Calls | `SoundTask1`, `SoundTask2`, `SoundTask3`, `SoundReturn` (tail) |
| Reads | `$FBD3`-`$FBE6` (`SoundData+109`) |
| Writes | `$FBCD`-`$FBD2` (`SoundData+103`); `$FBE3`-`$FBE6` (`SoundData+125`) |

### `SoundSetScript` (`$F9D4`)

**SoundSetScript**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11,970 calls (`stage1/rec/l5` 1,530, `stage1/rec/l4` 1,463, `stage1/rec/l8` 1,364 and 17 more) |
| Called from | `SoundStart` (tail) |
| Reads | `$FC0B`-`$FC50` (`SoundData+165`) |
| Writes | `$FBCD`-`$FBD2` (`SoundData+103`) |

### `NotePeriod` (`$F9E7`)

**DE = the period of a note**

Witness: L1 48828 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 48,828 calls (`stage1/rec/l2` 7,832, `stage1/rec/l4` 6,104, `stage1/rec/l1` 4,652 and 18 more) |
| Called from | `TonePair12`, `TonePair34`, `ToneDown12`, `ToneDown34`, `ToneUp12`, `ToneUp34` |
| Reads | `$FB66`-`$FBC7` (`SoundData`) |
| Writes | `$FA02` (`l_F9F7+11`) |

### `TonePair12` (`$FA08`)

**Voices 1 and 2**

Witness: L1 3112 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,112 calls (`stage1/rec/l4` 724, `stage1/rec/l2` 675, `stage1/rec/l5` 169 and 17 more) |
| Called from | `ChordPlay1` |
| Calls | `NotePeriod`, `ChordPlay1B` |

### `TonePair34` (`$FA18`)

**Voices 3 and 4**

Witness: L1 976 (boss, l1, l2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 976 calls (`stage1/rec/l2` 948, `stage1/rec/l1` 16, `docs/integrate/rec/boss` 12) |
| Called from | `ChordPlay3B` |
| Calls | `NotePeriod`, `ChordPlay3C` |

### `ToneDown12` (`$FA28`)

**Voices 1 and 2 sliding down**

Witness: L1 1965 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,965 calls (`stage1/rec/l7` 306, `stage1/rec/l5` 248, `stage1/rec/l1` 237 and 16 more) |
| Called from | `ChordPlay5` |
| Calls | `NotePeriod`, `ChordPlay5B` |

### `ToneDown34` (`$FA3A`)

**Voices 3 and 4 sliding down**

Witness: L1 5077 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,077 calls (`stage1/rec/l4` 935, `stage1/rec/l2` 693, `stage1/rec/l5` 417 and 18 more) |
| Called from | `ChordPlay1B`, `ChordPlay5B` |
| Calls | `NotePeriod`, `ChordPlay1C`, `ChordPlay5C` |

### `ToneUp12` (`$FA4E`)

**Voices 1 and 2 sliding up**

Witness: L1 7130 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,130 calls (`stage1/rec/l2` 1,265, `stage1/rec/l1` 772, `docs/integrate/rec/boss` 690 and 16 more) |
| Called from | `ChordPlay3`, `ChordPlay6` |
| Calls | `NotePeriod`, `ChordPlay3B`, `ChordPlay6C` |

### `ToneUp34` (`$FA5F`)

**Voices 3 and 4 sliding up**

Witness: L1 6154 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,154 calls (`stage1/rec/l1` 756, `docs/integrate/rec/boss` 678, `stage1/rec/l7` 608 and 16 more) |
| Called from | `ChordPlay6C` |
| Calls | `NotePeriod`, `ChordPlay6D` |

### `NoiseBurst` (`$FA71`)

**NoiseBurst**

[Animation: `NoiseBurst` at work](img/routines/NoiseBurst.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25,740 runs of its first instruction, entered by a jump (`stage1/rec/l7` 3,157, `docs/integrate/rec/boss` 2,647, `stage1/rec/l1` 2,646 and 18 more) |
| Called from | `SoundStep` |
| Reads | `$FB66`-`$FBC8` (`SoundData`) |
| Writes | `$850A` (`EnemySlots+9`); `$FA9B`-`$FA9C` (`l_FA83+24`); `$FAAD` (`l_FAA8+5`) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE`, `$20FE`, `$30FE`, `$50FE`, `$78FE`, `$88FE`, `$98FE`, `$C0FE`, `$C8FE`, `$D0FE`, `$D8FE`, `$E0FE`, `$F8FE` |

### `ChordPlay1` (`$FAAF`)

**ChordPlay1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,112 runs of its first instruction, entered by a jump (`stage1/rec/l4` 724, `stage1/rec/l2` 675, `stage1/rec/l5` 169 and 17 more) |
| Called from | `SoundStep` |
| Calls | `TonePair12` |
| Writes | `$FBC9`-`$FBCA` (`SoundData+99`) |

### `ChordPlay1B` (`$FABA`)

**ChordPlay1B**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,112 runs of its first instruction, entered by a jump (`stage1/rec/l4` 724, `stage1/rec/l2` 675, `stage1/rec/l5` 169 and 17 more) |
| Called from | `TonePair12` |
| Calls | `ToneDown34` |

### `ChordPlay1C` (`$FABD`)

**ChordPlay1C**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,112 runs of its first instruction, entered by a jump (`stage1/rec/l4` 724, `stage1/rec/l2` 675, `stage1/rec/l5` 169 and 17 more) |
| Called from | `ToneDown34` |
| Calls | `TonePlayer` (tail) |
| Reads | `$F872`-`$F87B` (`SoundStack`); `$FBC8`-`$FBCA` (`SoundData+98`) |
| Writes | `$FBC8` (`SoundData+98`) |
| Ports out | `$08FE`, `$18FE` |

### `ChordPlay3` (`$FACF`)

**ChordPlay3**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 976 runs of its first instruction, entered by a jump (`stage1/rec/l2` 948, `stage1/rec/l1` 16, `docs/integrate/rec/boss` 12) |
| Called from | `SoundStep` |
| Calls | `ToneUp12` |
| Writes | `$FBC9`-`$FBCA` (`SoundData+99`) |

### `ChordPlay3B` (`$FADA`)

**ChordPlay3B**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 976 runs of its first instruction, entered by a jump (`stage1/rec/l2` 948, `stage1/rec/l1` 16, `docs/integrate/rec/boss` 12) |
| Called from | `ToneUp12` |
| Calls | `TonePair34` |

### `ChordPlay3C` (`$FADD`)

**ChordPlay3C**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 976 runs of its first instruction, entered by a jump (`stage1/rec/l2` 948, `stage1/rec/l1` 16, `docs/integrate/rec/boss` 12) |
| Called from | `TonePair34` |
| Calls | `TonePlayer` (tail) |

### `ChordPlay5` (`$FAEF`)

**ChordPlay5**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,965 runs of its first instruction, entered by a jump (`stage1/rec/l7` 306, `stage1/rec/l5` 248, `stage1/rec/l1` 237 and 16 more) |
| Called from | `SoundStep` |
| Calls | `ToneDown12` |
| Writes | `$FBC9`-`$FBCA` (`SoundData+99`) |

### `ChordPlay5B` (`$FAFA`)

**ChordPlay5B**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,965 runs of its first instruction, entered by a jump (`stage1/rec/l7` 306, `stage1/rec/l5` 248, `stage1/rec/l1` 237 and 16 more) |
| Called from | `ToneDown12` |
| Calls | `ToneDown34` |

### `ChordPlay5C` (`$FAFD`)

**ChordPlay5C**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,965 runs of its first instruction, entered by a jump (`stage1/rec/l7` 306, `stage1/rec/l5` 248, `stage1/rec/l1` 237 and 16 more) |
| Called from | `ToneDown34` |
| Calls | `TonePlayer` (tail) |

### `ChordPlay6` (`$FAFF`)

**ChordPlay6**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,154 runs of its first instruction, entered by a jump (`stage1/rec/l1` 756, `docs/integrate/rec/boss` 678, `stage1/rec/l7` 608 and 16 more) |
| Called from | `SoundStep` |
| Calls | `ToneUp12` |
| Writes | `$FBC9`-`$FBCA` (`SoundData+99`) |

### `ChordPlay6C` (`$FB0A`)

**ChordPlay6C**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,154 runs of its first instruction, entered by a jump (`stage1/rec/l1` 756, `docs/integrate/rec/boss` 678, `stage1/rec/l7` 608 and 16 more) |
| Called from | `ToneUp12` |
| Calls | `ToneUp34` |

### `ChordPlay6D` (`$FB0D`)

**ChordPlay6D**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,154 runs of its first instruction, entered by a jump (`stage1/rec/l1` 756, `docs/integrate/rec/boss` 678, `stage1/rec/l7` 608 and 16 more) |
| Called from | `ToneUp34` |
| Calls | `TonePlayer` (tail) |

### `TonePlayer` (`$FB2F`)

**TonePlayer**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,110 calls (`stage1/rec/l2` 1,958, `stage1/rec/l4` 1,526, `stage1/rec/l1` 1,163 and 16 more) |
| Called from | `ChordPlay1C` (tail), `ChordPlay3C` (tail), `ChordPlay5C` (tail), `ChordPlay6D` (tail) |
| Reads | `$F872`-`$F87B` (`SoundStack`); `$FBC8`-`$FBCA` (`SoundData+98`) |
| Writes | `$FBC8` (`SoundData+98`) |
| Ports out | `$08FE`, `$18FE` |

## tail

`src/game/tail.asm`

### `CheckExtraLife` (`$FDA5`)

**When the score changed: print it and give an extra life at 50 000 and at each 100 000**

Witness: L1 32904 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 32,904 calls (`stage1/rec/l1` 3,483, `docs/integrate/rec/boss` 3,147, `stage1/rec/l3` 2,976 and 18 more) |
| Called from | `MainLoopPatch` |
| Calls | `PrintScore` (falls into) |
| Reads | `$71C9`-`$71CA` (`ScoreText`); `$7A8C`-`$7A99` (`ExtraLives`, `DeathTimer`, `ScrollHalted`, `WavesHalted` and 7 more) |
| Writes | `$7A99` (`ScoreChanged`) |

### `PrintScore` (`$FDAA`)

**Print the score and check the extra life (DrawHud calls it here)**

LD HL,Lives; the next instruction starts in its last byte (`$7A`, LD A,D) where nothing jumps. The score printed; an extra life when the second digit is 5 and none was given, or when the first digit equals ExtraLives: ExtraLives + 1, Lives + 1, DrawHud, sound `$0E`.

Witness: L1 1357 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,150 calls (`stage1/rec/l7` 284, `stage1/rec/l8` 127, `stage1/rec/l5` 118 and 14 more) |
| Called from | `DrawHud`, `CheckExtraLife` (falls into) |
| Calls | `PrintTextNormal`, `DrawHud`, `PlaySound` |
| Reads | `$71C9`-`$71CA` (`ScoreText`); `$7A8C` (`ExtraLives`); `$7AA0` (`Lives`) |
| Writes | `$7A8C`-`$7AA0` (`ExtraLives`, `DeathTimer`, `ScrollHalted`, `WavesHalted` and 14 more) |

### `Wait256` (`$FDE9`)

**Wait 256 frames**

Witness: L1 10 (boss, ending, hiscore, l1-l7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`docs/integrate/rec/boss` 1, `stage1/rec/ending` 1, `stage1/rec/hiscore` 1 and 7 more) |
| Called from | `CheckHiScore`, `LevelEnd` |
| Calls | `WaitFrames` (falls into) |
| Reads | `$FDEC` (`WaitFrames+1`) |

### `WaitFrames` (`$FDEB`)

**HALT B times**

Witness: L1 8495 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, gameover, hiscore, hiscore-typed, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,708 calls (`stage1/rec/hiscore` 819, `stage1/rec/gameover` 810, `stage1/rec/continue` 27 and 15 more) |
| Called from | `TitleLogo`, `Continue`, `LoseLife`, `PrintAndWait`, `InsertHiScore`, `SelectControl`, `Wait256` (falls into), `LoadLevelStart`, `LoadError` |
| Reads | `$FDEC` (`WaitFrames+1`) |

### `ClearBlock` (`$FDEF`)

**Zero BC bytes from HL**

Witness: L1 99924 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 99,924 calls (`stage1/rec/l1` 10,467, `docs/integrate/rec/boss` 9,443, `stage1/rec/l3` 9,150 and 18 more) |
| Called from | `ClearPlayState`, `ClearShipStuff`, `DrawTrail`, `ClearHits` (tail), `BossDestroyed`, `TitleScreen`, `ClearScreen`, `DrawFirstScreen` |
| Calls | `FillBlock` (falls into) |
| Reads | `$5FC1`-`$5FFB` (`Explosions`); `$7AD8`-`$7AE5` (`HitList+1`) |
| Writes | `$5FC1`-`$5FFC` (`Explosions`); `$7AD8`-`$7AE6` (`HitList+1`) |

### `FillBlock` (`$FDF0`)

**Fill BC bytes from HL with A**

HL ends at the last byte filled, not after it: a FillBlock that follows another starts one byte early (DrawHud's `$44` fill covers row 20 column 31 and row 21 columns 0-6).

Witness: L1 103437 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 91,953 calls (`stage1/rec/l1` 10,471, `stage1/rec/l3` 9,162, `stage1/rec/l7` 8,484 and 16 more) |
| Called from | `CycleTitleColour`, `TitleLoop`, `NewGameState`, `ClearPlayState`, `TitleLogo`, `Continue`, `InsertHiScore`, `DrawHud`, `ClearBlock` (falls into) |
| Reads | `$4000`-`$5AFE` (screen); `$5EB4`-`$5FFE` (`ShipShots`, `MissileA`, `MissileB`, `MissileC` and 1 more); `$71C9`-`$71DE` (`ScoreText`, `ScoreDirty`); `$7800`-`$7AF4` (`PlayAttrs`, `GameVars`, `Font`); `$7D1C`-`$7D29` (`HiScoreTable+68`); `$7DF9`-`$83F1` (`LevelVars`, `SolidMap`, `RowTable`, `RowTableEnd` and 8 more); 3 more ranges |
| Writes | `$4000`-`$5AFF` (screen); `$5EB4`-`$5FFF` (`ShipShots`, `MissileA`, `MissileB`, `MissileC` and 1 more); `$71C9`-`$71DF` (`ScoreText`, `ScoreDirty`); `$7800`-`$85FC` (`PlayAttrs`, `GameVars`, `Font`, `HiScoreTable` and 14 more); `$E641`-`$E688` (`TitleScreen+2345`); `$F716`-`$F75A` (`TitleScreen+6654`) |

### `ClearScreen` (`$FDF8`)

**Zero the bitmap `$4000-$57FF`**

Witness: L1 11 (continue, gameover, hiscore, hiscore-typed).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11 calls (`stage1/rec/gameover` 5, `stage1/rec/hiscore` 4, `stage1/rec/continue` 1 and 1 more) |
| Called from | `ShowHiScores`, `Continue` |
| Calls | `ClearBlock` |

### `LoadLevel` (`$FE03`)

**Load the next level from tape**

The digit + 1; SEARCHING FOR R TYPE LEVEL N; START TAPE; headers read and skipped until the level's; LOADING, the body to `$C4AE`; STOP TAPE, LOADED OK, a key. A load error: ERROR IN LOADING, REWIND TAPE, a key, again. After the last level ('0'): REWIND TAPE first.

Witness: L1 8 (ending, l1-l7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/l5` 1, `stage1/rec/l6` 1, `stage1/rec/l4` 1 and 5 more) |
| Called from | `LevelEnd` |
| Calls | `StarsOff`, `CycleTitleColour`, `ClearPlayState`, `TitleLogo`, `WaitKey`, `PrintRow22`, `PrintText`, `ClearTextRow` |
| Reads | `$600D`-`$6011` (system); `$719C` (`LevelDigit`) |
| Writes | `$719C` (`LevelDigit`); `$7A89` (`FrameCounter`); `$8ABF` (`l_8AA2+29`) |
| Ports out | `$00FE` |

### `LoadLevelStart` (`$FE4A`)

**LoadLevelStart**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/ending` 1) |
| Calls | `LoadBytes`, `WaitKey`, `PrintRow22`, `PrintText`, `ClearTextRow`, `WaitFrames` |
| Reads | `$600D`-`$6011` (system); `$719C` (`LevelDigit`) |
| Ports out | `$00FE` |

### `LoadDone` (`$FEC0`)

**Every LoadBytes return: EI; RET C; an error falls into LoadError**

Witness: L1 25 (deaths-l7, ending, l1-l8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage1/rec/l2` 3, `stage1/rec/l3` 3, `stage1/rec/l4` 3 and 7 more) |
| Called from | `LoadBytes` |

### `LoadError` (`$FEC2`)

**ERROR IN LOADING, REWIND TAPE, a key, retry**

Witness: L1 2 (ending).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 runs of its first instruction, entered by a jump (`stage1/rec/ending` 2) |
| Calls | `WaitKey`, `PrintRow22`, `PrintText`, `ClearTextRow`, `WaitFrames` |

### `DrawFirstScreen` (`$FEEB`)

**Draw the 8 block columns from the restart column into the shadow, then the scenery marks**

Soft cells on; the drawers' limit `$20`; each map byte drawn with its drawer (a patched CALL); MapReadPtr / MapBlockPtr set; every attribute with bit 7 marks its SolidMap cell `$FF` and loses bit 7; the limit back; soft cells off.

Witness: L1 47 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7, gameover, hiscore, hiscore-typed, restart, l2-l8).

[Animation: `DrawFirstScreen` at work](img/routines/DrawFirstScreen.gif)

| | |
| --- | --- |
| Runs (c1: power-on, orig/R-Type.tzx.zip at ROM speed on the 48K, SpeedLock 7, level 1 from side 2, the menu, define keys, play on level 1) | 4 calls, 251,642 t-states own (0.02 %) |
| Runs (the other recordings) | 43 calls (`stage2/rec/deaths-l7` 8, `stage1/rec/continue` 7, `stage1/rec/hiscore` 5 and 13 more) |
| Called from | `StartPlayField` |
| Calls | `MetatileAddress`, `SetDrawLimit`, `DrawSprite`, `DrawSpriteMirrored`, `DrawSpriteFlipped`, `DrawSpriteBoth`, `SoftCellsOn`, `SoftCellsOff`, `ClearBlock` |
| Reads | `$7800`-`$7A84` (`PlayAttrs`, `GameVars`); `$C4BC`-`$C4BD` (`LevelMetatiles`); `$D4BA`-`$D4E1` (`LoaderLeftover+3958`); `$D9A7`-`$D9CE` (`LoaderLeftover+5219`); `$E354`-`$E37B` (`TitleScreen+1596`); `$E521`-`$E548` (`TitleScreen+2057`); 5 more ranges |
| Writes | `$7800`-`$7A89` (`PlayAttrs`, `GameVars`); `$7A9C` (`DrawTag`); `$7E01`-`$7EFF` (`SolidMap+1`, `EntryCopySource`); `$7F11`-`$7F1F` (`EntryCopySource+47`); `$7F31`-`$7F3F` (`EntryCopySource+79`); `$7F51`-`$7F5F` (`EntryCopySource+111`); 5 more ranges |
| Ports out | `$00FE` |


## The tape BASIC and the copy of the decryption chain (`src/tape/basic.json`)

R-Type, Electric Dreams Software 1988: tape block 2, the BASIC program "R-TYPE" (4933 bytes at PROG `$5CCB`, LINE
0). Its entries are `src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part
src/tape/basic.json`; the recordings: `work/stage1/c1` (c1: a 48K from power-on, the whole load at signal speed
(SpeedLock 7, level 1), the menu, play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic`](#the-tape-basic-and-the-copy-of-the-decryption-chain-basic) | `$5CCB`-`$700F` | 1 of 4 |

### The tape BASIC and the copy of the decryption chain: basic

`src/tape/basic-module.asm`

#### `CopyChain` (`$5D06`)

**Blacken the attributes, copy the chain to `$EC00-$FEE7` and return into it**

Entered by line 0's USR (PROG+59). Interrupts off; fills `$5800-$5BFF` with zero: the 768 attribute bytes (INK 0 on PAPER 0: the screen goes black, the bitmap stays) and the printer buffer `$5B00-$5BFF`, border black. HL = PROG + `$5C` (ChainTape, found from the system variable PROG at 23635 rather than assumed); DE = `$EC00`, BC = 4840; `$EC00` pushed, then LDIR and RET: the RET enters the chain's first layer at `$EC00`. SP stays where the ROM's USR left it.

c1: the LDIR wrote `$EC00-$FEE7` in work/stage2/c1/chain.

Witness: L1 1 (stage2/c1/chain).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 call, 139,380 t-states own (0.01 %) |
| Reads | `$5800`-`$5BFE` (screen); `$5C53`-`$5C54`; `$5D27`-`$700E` (`ChainTape`) |
| Writes | `$5800`-`$5BFF` (screen) |
| Ports out | `$00FE` |


## The decryption chain and the SpeedLock 7 loader (`src/loader/chain.json`)

R-Type, Electric Dreams Software 1988: the BASIC's enciphered tail in its plain view, `$EC00-$FEE7`: the layers of
the decryption chain as each one runs, then the SpeedLock 7 reader as the last layer leaves it. tools/speedlock7.py
masters these bytes back into the tape's (src/tape/basic.asm INCBINs the result). Its entries are
`src/loader/<module>.asm`, written from `src/loader/chain.ann` by `kit/mkgame.py --part src/loader/chain.json`; the
recordings: `work/stage1/c1` (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the
menu, play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`chain`](#the-decryption-chain-and-the-speedlock-7-loader-chain) | `$EC00`-`$FEE7` | 59 of 83 |

### The decryption chain and the SpeedLock 7 loader: chain

`src/loader/chain-module.asm`

#### `ChainStart` (`$EC00`)

**The first layer: R = `$45`, wipe behind, decipher `$12B4` bytes keyed by the CALL's return address**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 call, 3,485,844 t-states own (0.25 %) |
| Reads | `$EBA1`-`$FEE7` (`ChainStart`, `LayerKeyed01`, `LayerExit01`, `Layer02` and 79 more) |
| Writes | `$EBA0`-`$FEE7` (`ChainStart`, `LayerKeyed01`, `LayerExit01`, `Layer02` and 79 more) |

#### `LayerKeyed01` (`$EC18`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer02` (`$EC71`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed03` (`$ECA7`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer04` (`$ECDE`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed05` (`$ED13`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed06` (`$ED54`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,662,379 t-states own (0.12 %) |
| Reads | `$ED4F`-`$FEE7` (`l_ED40+15`, `LayerKeyed06`, `LayerExit06`, `Layer07` and 72 more) |
| Writes | `$ED4E`-`$FEE7` (`l_ED40+14`, `LayerKeyed06`, `LayerExit06`, `Layer07` and 72 more) |

#### `Layer07` (`$EDAF`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer08` (`$EE1F`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,443,590 t-states own (0.61 %) |
| Reads | `$EE06`-`$FEE7` (`l_EE04+2`, `LayerExit07`, `Layer08`, `LayerExit08` and 69 more) |
| Writes | `$EE05`-`$FEE7` (`l_EE04+1`, `LayerExit07`, `Layer08`, `LayerExit08` and 69 more) |

#### `Layer09` (`$EEC7`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed10` (`$EEDB`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer11` (`$EF12`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer12` (`$EF4C`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed13` (`$EF60`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed14` (`$EFB3`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed15` (`$F004`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer16` (`$F08C`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer17` (`$F108`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer18` (`$F134`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed19` (`$F148`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed20` (`$F19A`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed21` (`$F1EC`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed22` (`$F270`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,077,739 t-states own (0.08 %) |
| Reads | `$F2D2`-`$FEE7` (`l_F2D1+1`, `LayerExit22`, `Layer23`, `LayerKeyed24` and 47 more) |
| Writes | `$F2D1`-`$FEE7` (`l_F2D1`, `LayerExit22`, `Layer23`, `LayerKeyed24` and 47 more) |

#### `Layer23` (`$F321`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed24` (`$F367`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer25` (`$F3C0`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed26` (`$F3F6`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer27` (`$F43E`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed28` (`$F473`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed29` (`$F4E3`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer30` (`$F51A`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed31` (`$F551`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer32` (`$F588`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,393,153 t-states own (0.10 %) |
| Reads | `$F590`-`$FEE7` (`Layer32+8`, `LayerKeyed33`, `LayerExit33`, `Layer34` and 32 more) |
| Writes | `$F58F`-`$FEE7` (`Layer32+7`, `LayerKeyed33`, `LayerExit33`, `Layer34` and 32 more) |

#### `LayerKeyed33` (`$F6CF`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Layer34` (`$F755`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed35` (`$F7CF`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed36` (`$F820`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,125 t-states own (0.00 %) |
| Reads | `$F80E`-`$F871` (`l_F80C+2`, `LayerKeyed36`) |
| Writes | `$F80D`-`$F870` (`l_F80C+1`, `LayerKeyed36`) |

#### `LayerKeyed37` (`$F885`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | run into, not called, 27,319 t-states own (0.00 %) |

#### `Layer38` (`$F8CD`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 42,081 t-states own (0.00 %) |

#### `Layer39` (`$F94F`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 38,888 t-states own (0.00 %) |

#### `Layer40` (`$F99C`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed41` (`$F9B0`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LayerKeyed42` (`$FA01`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | run into, not called, 10 t-states own (0.00 %) |

#### `Layer43` (`$FA38`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | run into, not called, 20,273 t-states own (0.00 %) |

#### `LayerKeyed44` (`$FAD4`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 17,272 t-states own (0.00 %) |

#### `Layer45` (`$FB2D`)

**The next layers: wipe the 100 bytes behind, decipher the rest with R and a running byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `LayerKeyed46` (`$FB62`)

**A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR IXH) - byte) XOR IXL**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SL7WipeTrap` (`$FBCB`)

**Zero memory upward from `$FBD7` for ever: the end of a failed check**

No recording ran it: known only from the code (the load passed every check).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SL7Reveal` (`$FBD7`)

**The per-bit hook: while `$82FF` is set, LDI 12 bytes from `$8000` to the attributes a step (the screen revealed as it loads)**

Witness: L1 57161 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 57,161 calls, 70,522,229 t-states own (5.07 %) |
| Called from | `SL7LoadBlock` |
| Calls | `SL7EdgeDelay` (tail) |
| Reads | `$8000`-`$82FF`; `$FCD1`-`$FCD4` (`SL7Bytes`); `$FF80`-`$FFCF` |
| Writes | `$50E0`-`$50E5` (screen); `$51E0`-`$51E5` (screen); `$52E0`-`$52E5` (screen); `$53E0`-`$53E5` (screen); `$54E0`-`$54E5` (screen); `$55E0`-`$55E5` (screen); 6 more ranges |

#### `SL7Edge2` (`$FCD5`)

**Wait for two edges**

Witness: L1 282 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 282 calls, 7,422 t-states own (0.00 %) |
| Called from | `SL7LoadBlock` |
| Calls | `SL7Edge1` (falls into) |

#### `SL7Edge1` (`$FCD9`)

**Wait for one edge after the standard delay**

Witness: L1 3292 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 3,292 calls, 23,044 t-states own (0.00 %) |
| Called from | `SL7Edge2` (falls into), `SL7LoadBlock` |
| Calls | `SL7EdgeDelay` (falls into) |

#### `SL7EdgeDelay` (`$FCDB`)

**Delay A, then wait for an edge on EAR counting B; carry when found, the border striped**

Witness: L1 2521777 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 307,274 calls, 538,331,974 t-states own (38.74 %) |
| Called from | `SL7Reveal` (tail), `SL7Edge1` (falls into), `SL7LoadBlock`, `SL7ReadBit` |
| Ports in | `$7FFE` |
| Ports out | `$08FE`, `$09FE`, `$0AFE` |

#### `SL7LoadBlock` (`$FCF6`)

**Load DE bytes to IX: the pilot, the sync and the 7-pulse pattern of SL7Pattern, then the bytes through the store hook**

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 2 calls, 28,437,119 t-states own (2.05 %) |
| Calls | `SL7Reveal`, `SL7Edge2`, `SL7Edge1`, `SL7EdgeDelay` |
| Reads | `$FEB4`-`$FEC1` (`SL7Pattern+1`) |
| Writes | `$FCEF` (`l_FCDF+16`) |
| Ports in | `$0AFE` |
| Ports out | `$0AFE` |

#### `SL7Blocks` (`$FDC7`)

**Walk the block table at IY: 5-byte records (address, length, the `$7FFD` bank or 0), each block loaded with SL7LoadBlock's bit loop**

Witness: L1 7 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 11 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,540 t-states own (0.00 %) |
| Calls | `SL7ReadBit` (falls into) |

#### `SL7ReadBit` (`$FE2A`)

**Read one bit into L (the edge time against `$DB`)**

Witness: L1 147 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 231 calls, 5,775 t-states own (0.00 %) |
| Called from | `SL7Blocks` (falls into) |
| Calls | `SL7EdgeDelay` |

#### `SL7LoadStage2` (`$FE40`)

**Load the next stage, then sample the EAR line 255 times into `$9000` and check it unless `$006D` holds `$28`**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | run into, not called, 2,805 t-states own (0.00 %) |

#### `SL7CountEdges` (`$FE5B`)

**Count the EAR changes in 255 loops into E**

Witness: L1 255 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SL7CheckSamples` (`$FE77`)

**Sum two runs of 50 samples; a bad pair sets SL7Pattern's flag byte**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 call, 927 t-states own (0.00 %) |
| Reads | `$9032`-`$9063` |

#### `SL7BlockEnd` (`$FEC2`)

**After a block: border black; a bad block wipes memory (SL7WipeTrap)**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 2 calls, 207,361 t-states own (0.01 %) |
| Writes | `$4000`-`$5AFF` (screen); `$82FF`; `$FDB1`-`$FDB2` (`l_FD95+28`) |
| Ports out | `$00FE` |


## The second stage (`src/loader/stage2.json`)

R-Type, Electric Dreams Software 1988: the SpeedLock reader's second stage at `$FEE8-$FFCF`, tape block 7. Its
entries are `src/loader/<module>.asm`, written from `src/loader/stage2.ann` by `kit/mkgame.py --part
src/loader/stage2.json`; the recordings: `work/stage1/c1` (c1: a 48K from power-on, the whole load at signal speed
(SpeedLock 7, level 1), the menu, play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`stage2`](#the-second-stage-stage2) | `$FEE8`-`$FFCF` | 1 of 2 |

### The second stage: stage2

`src/loader/stage2-module.asm`

#### `Stage2Start` (`$FEE8`)

**Load the screen with the store hook, check the flag; the IM 2, SP = `$752F`, JP `$7530` after the CALL never runs (Stage2End is loaded over `$FEFC` by block 31)**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |


## The second stage's table (`src/loader/table2.json`)

R-Type, Electric Dreams Software 1988: the reader's second table over `$FF49`, tape block 23 (55 bytes). Its entries
are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/table2.json`; the recordings: `work/stage1/c1` (c1: a 48K from power-on, the whole load at signal speed
(SpeedLock 7, level 1), the menu, play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`table2`](11-data-reference.md#the-second-stages-table-table2) | `$FF49`-`$FF7F` | 0 of 1 |


## The decipher block (`src/loader/decipher.json`)

R-Type, Electric Dreams Software 1988: Decipher at `$FE40` and the bytes after it, tape block 29 (115 bytes). Its
entries are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/decipher.json`; the recordings: `work/stage1/c1` (c1: a 48K from power-on, the whole load at signal speed
(SpeedLock 7, level 1), the menu, play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`decipher`](#the-decipher-block-decipher) | `$FE40`-`$FEB2` | 1 of 2 |

### The decipher block: decipher

`src/loader/decipher-module.asm`

#### `Decipher` (`$FE40`)

**XOR `$92` over `$7000-$C4AD` (21678 bytes), then JP Tail**

Witness: L1 1 (c1).

[Animation: `Decipher` at work](img/routines/Decipher.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 2 calls, 404,003 t-states own (0.03 %) |
| Reads | `$7000`-`$C4AD` (`GameEntry`) |
| Writes | `$7000`-`$C4AD` (`GameEntry`) |


## The second stage's end (`src/loader/stage2end.json`)

R-Type, Electric Dreams Software 1988: the second stage's new end at `$FEFC`, tape block 31 (49 bytes). Its entries
are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/stage2end.json`; the recordings: `work/stage1/c1` (c1: a 48K from power-on, the whole load at signal
speed (SpeedLock 7, level 1), the menu, play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`stage2end`](#the-second-stages-end-stage2end) | `$FEFC`-`$FF2C` | 1 of 1 |

### The second stage's end: stage2end

`src/loader/stage2end-module.asm`

#### `Stage2End` (`$FEFC`)

**Wipe memory if a check failed; IY = `$5C3A`, IM 1, HL' = `$2758`, border 0, R = 0, I = `$3F`, SP = `$6FFD`, JP Decipher**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |


## The loader's tail: the move to the game and the jump to the entry (`src/loader/tail.json`)

R-Type, Electric Dreams Software 1988: the tail at `$61A8` (blocks 33 and 35), tape block 33 (47 bytes). Its entries
are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part src/loader/tail.json`;
the recordings: `work/stage1/c1` (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1),
the menu, play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`tail`](#the-loaders-tail-the-move-to-the-game-and-the-jump-to-the-entry-tail) | `$61A8`-`$61D6` | 1 of 2 |

### The loader's tail: the move to the game and the jump to the entry: tail

`src/loader/tail-module.asm`

#### `Tail` (`$61A8`)

**HL' = `$2758`, SP = `$6FFE`, IY = `$5C3A`; LDDR `$C53C-$E7CD` to `$DD10-$FFA1`; OUT (`$7FFD`),`$30` (128K paging locked, the 48K ROM); JP GameEntry**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the whole load at signal speed (SpeedLock 7, level 1), the menu, play on level 1) | 1 call, 198,055 t-states own (0.01 %) |
| Reads | `$C53C`-`$E7CD` |
| Writes | `$DD10`-`$FFA1` (`SL7WipeTrap`, `SL7Pattern`) |
| Ports out | `$7FFD` |


## Level 1 (side 2) (`src/level1/level1.json`)

R-Type, Electric Dreams Software 1988: level 1, 13228 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
40). Its entries are `src/level1/<module>.asm`, written from `src/level1/level1.ann` by `kit/mkgame.py --part
src/level1/level1.json`; the recordings: `work/stage1/rec/l1` (l1: level 1 played from its load to the next search
(the immortality POKE `$91F2`)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`level1data`](#level-1-side-2-level1data) | `$C4AE`-`$F859` | 33 of 48 |

### Level 1 (side 2): level1data

`src/level1/level1data.asm`

#### `L1MoverA0` (`$F3A5`)

**Mover A0**

Witness: L1 0 (none).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 4,029 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 79,950 t-states own (0.01 %) |

#### `L1MoverA1` (`$F3AB`)

**Mover A1**

Witness: L1 4033 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, force, gameover, hiscore, hiscore-typed, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 1,288 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 524,180 t-states own (0.05 %) |
| Called from | `L1MoverA2` (tail), `L1MoverA5` (tail), `L1MoverA12` (tail), `L1MoverA13` (tail), `L1MoverA14` (tail), `L1MoverA15` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L1MoverA2` (`$F3B9`)

**Mover A2**

Witness: L1 558 (boss, force, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 231 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,807 t-states own (0.00 %) |
| Calls | `L1MoverA1` (tail) |

#### `L1MoverA3` (`$F3BE`)

**Mover A3**

Witness: L1 3598 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 2,205 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 105,859 t-states own (0.01 %) |
| Calls | `L1DriftLeft` |

#### `L1MoverA4` (`$F3E3`)

**Mover A4**

Witness: L1 958 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 479 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 28,278 t-states own (0.00 %) |
| Calls | `L1MoverA5` (falls into) |
| Reads | `$7AD1`-`$7AD2` (`Scratch+2`); `$7DF9` (`LevelVars`); `$8555` (`EnemySlots+84`); `$85AF` (`EnemySlots+174`) |
| Writes | `$5FC1`; `$85AC` (`EnemySlots+171`) |

#### `L1MoverA5` (`$F408`)

**Mover A5**

Witness: L1 16286 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 479 calls, 855,075 t-states own (0.08 %) |
| Called from | `L1MoverA4` (falls into) |
| Calls | `L1MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$7DF9` (`LevelVars`); `$85D8` (`EnemySlots+215`) |

#### `L1BossHit` (`$F42D`)

**Mover A4's end: LevelVars = `$1A`, the slot indestructible (`$3F`), the explosions drawn first (L1ExplosionsFirst), points (AddScore with `$0104` and `$0503`)**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L1MoverA6` (`$F468`)

**Mover A6**

Witness: L1 9982 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 4,991 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 571,441 t-states own (0.05 %) |
| Reads | `$5FC2`-`$5FC8`; `$7A89` (`FrameCounter`); `$7A9C`-`$7AA1` (`DrawTag`, `ShipColumn`); `$7AD1`-`$7AD2` (`Scratch+2`); `$8504`-`$854C` (`EnemySlots+3`); `$855E`-`$8567` (`EnemySlots+93`); 2 more ranges |
| Writes | `$5FC2`-`$5FC8`; `$7A9C` (`DrawTag`); `$8501`-`$8568` (`EnemySlots`); `$85D3`-`$85E6` (`EnemySlots+210`) |

#### `L1MoverA7` (`$F4D8`)

**Mover A7**

Witness: L1 1448 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 1,188 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 46,008 t-states own (0.00 %) |
| Reads | `$851B`-`$852D` (`EnemySlots+26`); `$8551`-`$8563` (`EnemySlots+80`) |
| Writes | `$851B`-`$852D` (`EnemySlots+26`); `$8551`-`$8563` (`EnemySlots+80`) |

#### `L1MoverA8` (`$F4EC`)

**Mover A8**

Witness: L1 1028 (boss, l1).

[Animation: `L1MoverA8` at work](img/routines/L1MoverA8.gif)

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 736 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 93,445 t-states own (0.01 %) |
| Calls | `L1BlastRecord`, `L1DriftLeft` |
| Reads | `$7A84`-`$7A89` (`MapColumn`, `FrameCounter`); `$850D` (`EnemySlots+12`) |
| Writes | `$7A9C` (`DrawTag`); `$850D` (`EnemySlots+12`) |

#### `L1BlastRecord` (`$F53B`)

**Free the record at HL: zero it, take its position less one column, start an explosion there (FreeExplosion, its Z flag ignored) and its sound (AwardScore); AwardScore's DE is dropped, so no points**

Witness: L1 4 (l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 4 calls, 660 t-states own (0.00 %) |
| Called from | `L1MoverA8` |
| Reads | `$85AC`-`$85CB` (`EnemySlots+171`) |
| Writes | `$7ACF`-`$7AD0` (`Scratch`); `$85AC`-`$85C7` (`EnemySlots+171`) |

#### `L1MoverA9` (`$F559`)

**Mover A9**

Witness: L1 1028 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 736 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,964,728 t-states own (0.18 %) |
| Calls | `L1DriftLeft` |
| Reads | `$7A89` (`FrameCounter`); `$850A` (`EnemySlots+9`); `$85DC` (`EnemySlots+219`); `$F7EA`-`$F859` (`L1ShapeFrames`) |
| Writes | `$7A9C` (`DrawTag`) |

#### `L1MoverA10` (`$F5AD`)

**Mover A10**

Witness: L1 2375 (boss, force, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 925 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 83,604 t-states own (0.01 %) |
| Reads | `$7AA2` (`ShipRow`); `$8512` (`EnemySlots+17`) |
| Writes | `$F5E7` (`L1SpawnA+2`) |

#### `L1MoverA11` (`$F5E8`)

**Mover A11**

Witness: L1 1568 (boss, force, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 616 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,624 t-states own (0.00 %) |

#### `L1MoverA12` (`$F5EC`)

**Mover A12**

Witness: L1 3558 (boss, l1).

[Animation: `L1MoverA12` at work](img/routines/L1MoverA12.gif)

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 1,779 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 297,069 t-states own (0.03 %) |
| Calls | `L1MoverA1` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$8509` (`EnemySlots+8`); `$851B`-`$8551` (`EnemySlots+26`); `$8563` (`EnemySlots+98`); `$F1E6`-`$F1F4` (`L1Kinds+491`) |
| Writes | `$F1E6`-`$F1F4` (`L1Kinds+491`) |

#### `L1MoverA13` (`$F63D`)

**Mover A13**

Witness: L1 721 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 391 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 146,547 t-states own (0.01 %) |
| Calls | `L1MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$83D1`-`$83D3` (`EnemyShots+75`); `$850E`-`$8512` (`EnemySlots+13`); `$85D4`-`$85D8` (`EnemySlots+211`); `$F258`-`$F25E` (`L1Kinds+605`); 1 more ranges |
| Writes | `$83D1`-`$83D3` (`EnemyShots+75`); `$F258`-`$F25E` (`L1Kinds+605`); `$F272`-`$F29E` (`L1Kinds+631`); `$F66B` (`l_F656+21`); `$F6DA`-`$F6E9` (`l_F6C9+17`, `L1SpawnB`) |

#### `L1MoverA14` (`$F6EA`)

**Mover A14**

Witness: L1 1578 (boss, force, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 633 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 33,559 t-states own (0.00 %) |
| Calls | `L1MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$F2CA`-`$F2DE` (`L1Kinds+719`); `$F726` (`L1SpawnC+1`) |
| Writes | `$F725`-`$F727` (`L1SpawnC`) |

#### `L1MoverA15` (`$F728`)

**Mover A15**

Witness: L1 3692 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 2,149 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 134,365 t-states own (0.01 %) |
| Calls | `L1MoverA1` (tail) |
| Writes | `$7ACF`-`$7AD0` (`Scratch`); `$8513`-`$855B` (`EnemySlots+18`); `$856D` (`EnemySlots+108`) |

#### `L1MoverB0` (`$F742`)

**Mover B0**

Witness: L1 38451 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, force, gameover, hiscore, hiscore-typed, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 4,977 calls, 140,339 t-states own (0.01 %) |
| Called from | `L1MoverB6` (tail) |

#### `L1MoverB1` (`$F745`)

**Mover B1**

Witness: L1 32322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, force, gameover, hiscore, hiscore-typed, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 224 calls, 526,773 t-states own (0.05 %) |
| Called from | `L1SlotBusy` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L1MoverB2` (`$F750`)

**Mover B2, B3, B4, B5**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L1MoverB6` (`$F755`)

**Mover B6**

Witness: L1 9954 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 4,977 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 263,895 t-states own (0.02 %) |
| Calls | `L1MoverB0` (tail) |

#### `L1MoverB7` (`$F75F`)

**Mover B7**

Witness: L1 52 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 26 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 494 t-states own (0.00 %) |
| Calls | `L1MoverB15` (tail) |

#### `L1MoverB8` (`$F763`)

**Mover B8**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L1MoverB10` (`$F767`)

**Mover B10, B11**

Witness: L1 116 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 58 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,102 t-states own (0.00 %) |
| Calls | `L1MoverB15` (tail) |

#### `L1MoverB9` (`$F76B`)

**Mover B9, B12**

Witness: L1 130 (boss, force, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 17 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 323 t-states own (0.00 %) |
| Calls | `L1MoverB15` (tail) |

#### `L1MoverB13` (`$F76F`)

**Mover B13**

Witness: L1 42 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 21 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 399 t-states own (0.00 %) |
| Calls | `L1MoverB15` (tail) |

#### `L1MoverB14` (`$F773`)

**Mover B14**

Witness: L1 100 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 50 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 950 t-states own (0.00 %) |
| Calls | `L1MoverB15` (tail) |

#### `L1MoverB15` (`$F777`)

**Mover B15**

Witness: L1 118 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 59 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 5,173 t-states own (0.00 %) |
| Called from | `L1MoverB7` (tail), `L1MoverB10` (tail), `L1MoverB9` (tail), `L1MoverB13` (tail), `L1MoverB14` (tail) |
| Calls | `L1SlotBusy` |
| Reads | `$7A89` (`FrameCounter`); `$7AC1` (`Carriers`) |
| Writes | `$7AC1`-`$7AC4` (`Carriers`) |

#### `L1ExplosionsFirst` (`$F7AA`)

**Move the CALL DrawExplosions from `$866B` to MainLoopPatch (`$8656`): the explosions drawn before the enemies**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L1ExplosionsLast` (`$F7B3`)

**Move the CALL DrawExplosions back from MainLoopPatch to `$866B`**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L1DriftLeft` (`$F7CA`)

**Unless MapColumn is `$6B-$73`: every 8th pass move the slot one column left (column - 1 into IY+3)**

Witness: L1 5654 (boss, l1).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 3,677 calls, 224,501 t-states own (0.02 %) |
| Called from | `L1MoverA3`, `L1MoverA8`, `L1MoverA9` |
| Reads | `$7A84`-`$7A89` (`MapColumn`, `FrameCounter`) |
| Writes | `$8504`-`$850D` (`EnemySlots+3`); `$85AF`-`$85CA` (`EnemySlots+174`); `$85DC` (`EnemySlots+219`) |

#### `L1SlotBusy` (`$F7DF`)

**Return while the slot is free; else drop the return and go on at Mover B1 (Mover B15 calls it)**

Witness: L1 558 (boss, force, l1, restart).

| | |
| --- | --- |
| Runs (l1: level 1 played from its load to the next search (the immortality POKE `$91F2`)) | 231 calls, 12,600 t-states own (0.00 %) |
| Called from | `L1MoverB15` |
| Calls | `L1MoverB1` (tail) |
| Reads | `$8501` (`EnemySlots`); `$8513`-`$851C` (`EnemySlots+18`); `$852E`-`$8537` (`EnemySlots+45`); `$8549`-`$8552` (`EnemySlots+72`) |


## Level 2 (side 2) (`src/level2/level2.json`)

R-Type, Electric Dreams Software 1988: level 2, 12856 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
44). Its entries are `src/level2/<module>.asm`, written from `src/level2/level2.ann` by `kit/mkgame.py --part
src/level2/level2.json`; the recordings: `work/stage1/rec/l2` (l2: level 2 played from its load to the next search
(the immortality POKE `$91F2`)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`level2data`](#level-2-side-2-level2data) | `$C4AE`-`$F6E5` | 24 of 34 |

### Level 2 (side 2): level2data

`src/level2/level2data.asm`

#### `L2MoverA0` (`$F4F3`)

**Mover A0**

Witness: L1 0 (none).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 2,994 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 59,509 t-states own (0.01 %) |

#### `L2MoverA1` (`$F4F9`)

**Mover A1**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | run into, not called, 76,508 t-states own (0.01 %) |
| Called from | `L2MoverA2` (tail), `L2MoverA3` (tail), `L2MoverA7` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L2MoverA2` (`$F507`)

**Mover A2**

Witness: L1 36 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 36 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 452 t-states own (0.00 %) |
| Calls | `L2MoverA1` (tail) |

#### `L2MoverA3` (`$F50C`)

**Mover A3**

Witness: L1 1239 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 1,239 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 38,721 t-states own (0.00 %) |
| Calls | `L2MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`) |
| Writes | `$7DFA` (`LevelVars+1`); `$8EB1` (`CellMark+15`) |

#### `L2MoverA4` (`$F524`)

**Mover A4**

Witness: L1 795 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 795 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 19,894 t-states own (0.00 %) |

#### `L2MoverA5` (`$F52B`)

**Mover A5**

Witness: L1 10335 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 10,335 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,050,047 t-states own (0.09 %) |
| Calls | `L2ShotBurst` |
| Reads | `$7A89` (`FrameCounter`); `$851C`-`$8591` |
| Writes | `$851C`-`$8591` |

#### `L2MoverA6` (`$F54F`)

**Mover A6**

Witness: L1 795 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 795 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 84,289 t-states own (0.01 %) |
| Reads | `$F2C4`-`$F30A` (`L2Kinds+301`); `$F34C`-`$F392` (`L2Kinds+437`) |
| Writes | `$859D`-`$859E` |

#### `L2MoverA7` (`$F566`)

**Mover A7**

Witness: L1 1056 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 1,056 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 58,639 t-states own (0.01 %) |
| Calls | `L2MoverA1` (tail) |
| Reads | `$8509` |
| Writes | `$8509` |

#### `L2MoverA8` (`$F5BC`)

**Mover A8**

Witness: L1 288 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 288 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 42,110 t-states own (0.00 %) |
| Reads | `$8512`; `$8524`; `$F47E` (`L2Kinds+743`); `$F49E` (`L2Kinds+775`) |
| Writes | `$7A9C` (`DrawTag`); `$850D`-`$8524` |

#### `L2MoverA9` (`$F611`)

**Mover A9**

Witness: L1 544 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 544 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 40,911 t-states own (0.00 %) |
| Writes | `$7A9C` (`DrawTag`) |

#### `L2MoverB0` (`$F622`)

**Mover B0**

Witness: L1 14919 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 14,919 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 149,247 t-states own (0.01 %) |

#### `L2MoverB1` (`$F625`)

**Mover B1**

Witness: L1 2164 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 2,164 calls, 76,975 t-states own (0.01 %) |
| Called from | `L2MoverB2` (tail), `L2MoverB3` (tail), `L2MoverB15` (tail), `L2SlotBusy` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L2MoverB2` (`$F630`)

**Mover B2**

Witness: L1 1056 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 1,056 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 30,662 t-states own (0.00 %) |
| Calls | `L2MoverB1` (tail) |
| Writes | `$8EB1` (`CellMark+15`) |

#### `L2MoverB3` (`$F636`)

**Mover B3**

Witness: L1 1239 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 1,239 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 42,998 t-states own (0.00 %) |
| Calls | `L2MoverB1` (tail) |
| Reads | `$7DFA` (`LevelVars+1`) |
| Writes | `$7DFA` (`LevelVars+1`); `$8EB1` (`CellMark+15`) |

#### `L2MoverB4` (`$F646`)

**Mover B4**

Witness: L1 832 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 832 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 22,464 t-states own (0.00 %) |

#### `L2MoverB5` (`$F64C`)

**Mover B5, B6, B7**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L2MoverB8` (`$F650`)

**Mover B8**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L2MoverB10` (`$F654`)

**Mover B10, B11**

Witness: L1 17 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 17 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 342 t-states own (0.00 %) |
| Calls | `L2MoverB15` (tail) |

#### `L2MoverB9` (`$F658`)

**Mover B9, B12**

Witness: L1 12 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 12 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 228 t-states own (0.00 %) |
| Calls | `L2MoverB15` (tail) |

#### `L2MoverB13` (`$F65C`)

**Mover B13**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L2MoverB14` (`$F660`)

**Mover B14**

Witness: L1 7 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 7 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 133 t-states own (0.00 %) |
| Calls | `L2MoverB15` (tail) |

#### `L2MoverB15` (`$F664`)

**Mover B15**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | run into, not called, 1,079 t-states own (0.00 %) |
| Called from | `L2MoverB10` (tail), `L2MoverB9` (tail), `L2MoverB14` (tail) |
| Calls | `L2MoverB1` (tail), `L2SlotBusy` |
| Reads | `$7A89` (`FrameCounter`); `$7AC1` (`Carriers`) |
| Writes | `$7AC1`-`$7AC8` (`Carriers`) |

#### `L2ShotBurst` (`$F697`)

**Fire eight enemy shots from the slot's position, kinds `$21`, `$22`, `$24`, `$28`, `$25`, `$26`, `$29`, `$2A` (the eight directions)**

Witness: L1 228 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 228 calls, 210,273 t-states own (0.02 %) |
| Called from | `L2MoverA5` |
| Writes | `$8386`-`$839D` (`EnemyShots`) |

#### `L2SlotBusy` (`$F6DB`)

**Return while the slot is free; else drop the return and go on at Mover B1 (Mover B15 calls it)**

Witness: L1 36 (l2).

| | |
| --- | --- |
| Runs (l2: level 2 played from its load to the next search (the immortality POKE `$91F2`)) | 36 calls, 1,920 t-states own (0.00 %) |
| Called from | `L2MoverB15` |
| Calls | `L2MoverB1` (tail) |
| Reads | `$850A`-`$8513`; `$8525`; `$8537` |


## Level 3 (side 2) (`src/level3/level3.json`)

R-Type, Electric Dreams Software 1988: level 3, 13074 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
48). Its entries are `src/level3/<module>.asm`, written from `src/level3/level3.ann` by `kit/mkgame.py --part
src/level3/level3.json`; the recordings: `work/stage1/rec/l3` (l3: level 3 played from its load to the next search
(the immortality POKE `$91F2`)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`level3data`](#level-3-side-2-level3data) | `$C4AE`-`$F7BF` | 30 of 41 |

### Level 3 (side 2): level3data

`src/level3/level3data.asm`

#### `L3MoverA0` (`$F0E6`)

**Mover A0**

Witness: L1 0 (none).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 160 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,200 t-states own (0.00 %) |

#### `L3MoverA1` (`$F0EC`)

**Mover A1**

Witness: L1 840 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 840 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 130,214 t-states own (0.01 %) |
| Called from | `L3MoverA2` (tail), `L3MoverA12` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L3MoverA2` (`$F0FA`)

**Mover A2**

Witness: L1 230 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 230 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,770 t-states own (0.00 %) |
| Calls | `L3MoverA1` (tail) |

#### `L3MoverA3` (`$F0FF`)

**Mover A3**

Witness: L1 2832 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 2,832 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,865,207 t-states own (0.15 %) |
| Reads | `$7A89` (`FrameCounter`); `$EDB3`-`$EF73` (`L3Kinds+99`) |
| Writes | `$7A9C` (`DrawTag`); `$EDB3`-`$EF73` (`L3Kinds+99`) |

#### `L3MoverA4` (`$F13A`)

**Mover A4**

Witness: L1 1509 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 1,509 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,821,819 t-states own (0.14 %) |
| Called from | `L3MoverA5` (tail), `L3MoverA6` (tail), `L3MoverA7` (tail), `L3MoverA8` (tail), `L3MoverA9` (tail), `L3MoverA10` (tail), `L3MoverA11` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$EDA5`-`$EF73` (`L3Kinds+85`) |
| Writes | `$EDA5`-`$EF73` (`L3Kinds+85`) |

#### `L3MoverA5` (`$F15D`)

**Mover A5**

Witness: L1 2332 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 2,332 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 184,612 t-states own (0.01 %) |
| Calls | `L3MoverA4` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`) |

#### `L3MoverA6` (`$F187`)

**Mover A6**

Witness: L1 5545 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 5,545 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 456,381 t-states own (0.04 %) |
| Calls | `L3MoverA4` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`) |

#### `L3MoverA7` (`$F1A8`)

**Mover A7**

Witness: L1 7371 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 7,371 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,364,281 t-states own (0.11 %) |
| Calls | `L3MoverA4` (tail), `L3SecondMoverLess2` |
| Reads | `$7A83`-`$7A89` (`MetaColumn`, `MapColumn`, `FrameCounter`); `$7A9C`-`$7AA2` (`DrawTag`, `ShipColumn`, `ShipRow`); `$7AD1`-`$7AD2` (`Scratch+2`); `$7DF9`-`$7DFF` (`LevelVars`); `$8501`; `$855B`; 4 more ranges |
| Writes | `$5FC1`-`$5FC4`; `$7A9C` (`DrawTag`); `$7ACF`-`$7AD0` (`Scratch`); `$7DF9`-`$7DFF` (`LevelVars`); `$855B`; `$8EB1` (`CellMark+15`); 2 more ranges |

#### `L3MoverA8` (`$F379`)

**Mover A8**

Witness: L1 3332 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 3,332 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,697,598 t-states own (0.13 %) |
| Calls | `L3MoverA4` (tail), `L3SecondMoverLess2` |
| Reads | `$8536`; `$855A`; `$85B4`; `$85F3`; `$F702`-`$F75E` (`L3Tail+21`) |
| Writes | `$F716`-`$F75E` (`L3Tail+41`) |

#### `L3MoverA9` (`$F3F4`)

**Mover A9**

Witness: L1 11328 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 11,328 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,496,563 t-states own (0.12 %) |
| Calls | `L3MoverA4` (tail) |
| Reads | `$7A84`-`$7A89` (`MapColumn`, `FrameCounter`); `$7A9C` (`DrawTag`); `$F797`-`$F7AA` (`L3Tail+170`) |
| Writes | `$7A9C` (`DrawTag`); `$F466`-`$F467` (`l_F455+17`) |

#### `L3MoverA10` (`$F47B`)

**Mover A10**

Witness: L1 1968 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 1,968 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,012,159 t-states own (0.08 %) |
| Calls | `L3MoverA4` (tail) |
| Reads | `$7A83`-`$7A89` (`MetaColumn`, `MapColumn`, `FrameCounter`); `$7A9C` (`DrawTag`); `$7DFE` (`LevelVars+5`); `$85E2`; `$F7AE`-`$F7BF` (`L3Tail+193`) |
| Writes | `$7A9C` (`DrawTag`); `$7DFE` (`LevelVars+5`); `$85E2`; `$F7AB`-`$F7AF` (`L3Tail+190`) |

#### `L3MoverA11` (`$F55A`)

**Mover A11**

Witness: L1 7026 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 7,026 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,874,223 t-states own (0.15 %) |
| Calls | `L3MoverA4` (tail), `L3SecondMoverLess2` |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$7DFD` (`LevelVars+4`) |
| Writes | `$7DFD` (`LevelVars+4`); `$F7AB`-`$F7AD` (`L3Tail+190`) |

#### `L3MoverA12` (`$F5EF`)

**Mover A12, A13, A14**

Witness: L1 2358 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 2,358 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 116,590 t-states own (0.01 %) |
| Calls | `L3MoverA1` (tail) |
| Writes | `$7ACF`-`$7AD0` (`Scratch`); `$8501`; `$8513`-`$8549` |

#### `L3MoverA15` (`$F60B`)

**Mover A15**

Witness: L1 2904 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 2,904 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 6,123,075 t-states own (0.49 %) |
| Reads | `$F716`-`$F75A` (`L3Tail+41`) |
| Writes | `$7A9C` (`DrawTag`); `$F716`-`$F75A` (`L3Tail+41`) |

#### `L3MoverB0` (`$F66E`)

**Mover B0**

Witness: L1 13422 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 13,422 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 134,239 t-states own (0.01 %) |

#### `L3MoverB1` (`$F671`)

**Mover B1**

Witness: L1 3393 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 230 calls, 122,976 t-states own (0.01 %) |
| Called from | `L3MoverB15` (tail), `L3SlotBusy` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L3MoverB2` (`$F67C`)

**Mover B2**

Witness: L1 27488 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 20,163 calls, 742,328 t-states own (0.06 %) |
| Called from | `L3MoverB3` (tail), `L3MoverB4` (tail), `L3MoverB5` (tail), `L3MoverB6` (tail) |
| Writes | `$8EB1` (`CellMark+15`) |

#### `L3MoverB3` (`$F683`)

**Mover B3**

Witness: L1 10898 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 10,898 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 130,833 t-states own (0.01 %) |
| Calls | `L3MoverB2` (tail) |

#### `L3MoverB4` (`$F685`)

**Mover B4**

Witness: L1 2000 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 2,000 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 24,019 t-states own (0.00 %) |
| Calls | `L3MoverB2` (tail) |

#### `L3MoverB5` (`$F687`)

**Mover B5**

Witness: L1 2988 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 2,988 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 35,875 t-states own (0.00 %) |
| Calls | `L3MoverB2` (tail) |

#### `L3MoverB6` (`$F689`)

**Mover B6**

Witness: L1 4277 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 4,277 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 51,343 t-states own (0.00 %) |
| Calls | `L3MoverB2` (tail) |

#### `L3MoverB7` (`$F68B`)

**Mover B7**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L3MoverB8` (`$F68F`)

**Mover B8**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L3MoverB10` (`$F693`)

**Mover B10, B11**

Witness: L1 144 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 144 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,736 t-states own (0.00 %) |
| Calls | `L3MoverB15` (tail) |

#### `L3MoverB9` (`$F697`)

**Mover B9, B12**

Witness: L1 19 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 19 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 361 t-states own (0.00 %) |
| Calls | `L3MoverB15` (tail) |

#### `L3MoverB13` (`$F69B`)

**Mover B13**

Witness: L1 67 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 67 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,273 t-states own (0.00 %) |
| Calls | `L3MoverB15` (tail) |

#### `L3MoverB14` (`$F69F`)

**Mover B14**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L3MoverB15` (`$F6A3`)

**Mover B15**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | run into, not called, 4,140 t-states own (0.00 %) |
| Called from | `L3MoverB10` (tail), `L3MoverB9` (tail), `L3MoverB13` (tail) |
| Calls | `L3MoverB1` (tail), `L3SlotBusy` |
| Reads | `$7A89` (`FrameCounter`); `$7AC1` (`Carriers`) |
| Writes | `$7AC1`-`$7AC8` (`Carriers`) |

#### `L3SecondMoverLess2` (`$F6D6`)

**A = the slot's second mover number (high nibble of IY+5) less 2**

Witness: L1 17721 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 17,721 calls, 1,063,507 t-states own (0.08 %) |
| Called from | `L3MoverA7`, `L3MoverA8`, `L3MoverA11` |
| Reads | `$8501`-`$850F`; `$8533`-`$853C`; `$8557`-`$8572`; `$858D`; `$85A8`-`$85B1`; `$85F0` |

#### `L3SlotBusy` (`$F6E2`)

**Return while the slot is free; else drop the return and go on at Mover B1 (Mover B15 calls it)**

Witness: L1 230 (l3).

| | |
| --- | --- |
| Runs (l3: level 3 played from its load to the next search (the immortality POKE `$91F2`)) | 230 calls, 12,620 t-states own (0.00 %) |
| Called from | `L3MoverB15` |
| Calls | `L3MoverB1` (tail) |
| Reads | `$8501`; `$8537`; `$85EB` |


## Level 4 (side 2) (`src/level4/level4.json`)

R-Type, Electric Dreams Software 1988: level 4, 12998 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
52). Its entries are `src/level4/<module>.asm`, written from `src/level4/level4.ann` by `kit/mkgame.py --part
src/level4/level4.json`; the recordings: `work/stage1/rec/l4` (l4: level 4 played from its load to the next search
(the immortality POKE `$91F2`)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`level4data`](#level-4-side-2-level4data) | `$C4AE`-`$F773` | 32 of 44 |

### Level 4 (side 2): level4data

`src/level4/level4data.asm`

#### `L4MoverA0` (`$F2EE`)

**Mover A0**

Witness: L1 0 (none).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 161 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,040 t-states own (0.00 %) |

#### `L4MoverA1` (`$F2F4`)

**Mover A1**

Witness: L1 273 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 273 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 156,457 t-states own (0.01 %) |
| Called from | `L4MoverA2` (tail), `L4MoverA9` (tail), `L4MoverA11` (tail), `L4MoverA12` (tail), `L4MoverA14` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L4MoverA2` (`$F302`)

**Mover A2**

Witness: L1 558 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 558 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 6,736 t-states own (0.00 %) |
| Calls | `L4MoverA1` (tail) |

#### `L4MoverA3` (`$F307`)

**Mover A3**

Witness: L1 59 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 59 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 9,884 t-states own (0.00 %) |
| Called from | `L4MoverA4` (tail) |
| Writes | `$7A9C` (`DrawTag`) |

#### `L4MoverA4` (`$F325`)

**Mover A4**

Witness: L1 22 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 22 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 484 t-states own (0.00 %) |
| Calls | `L4MoverA3` (tail) |

#### `L4MoverA5` (`$F32A`)

**Mover A5**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L4MoverA6` (`$F32F`)

**Mover A6**

Witness: L1 369 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 369 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 82,797 t-states own (0.01 %) |
| Called from | `L4OnField` (tail), `L4ClearPair` (tail), `L4MoverA7` (tail), `L4SoftDraw`, `L4MoverA8` (tail) |
| Calls | `L4OnField`, `L4ClearPair`, `L4SoftDraw` |
| Reads | `$7A89` (`FrameCounter`); `$7E06`-`$8019`; `$8030`-`$8039`; `$8050`-`$8059`; `$8070`-`$8079`; `$F01D`-`$F08B` (`L4Kinds+147`) |
| Writes | `$7A9C` (`DrawTag`); `$7E0A`-`$7F59`; `$7F75`-`$7F79`; `$7F8A`-`$7FB4`; `$7FC8`-`$7FE8`; `$8003`-`$8031`; 2 more ranges |

#### `L4OnField` (`$F393`)

**Return while row B < 20 and column C is 1-30; else drop the return and go to the slot's end**

Witness: L1 439 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 439 calls, 23,785 t-states own (0.00 %) |
| Called from | `L4MoverA6`, `L4ClearPair` |
| Calls | `L4MoverA6` (tail) |

#### `L4ClearPair` (`$F3A3`)

**Zero the bytes at DE + `$300` and DE + `$2FF` (the cell and its left neighbour, three pages up)**

Witness: L1 302 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 302 calls, 101,709 t-states own (0.01 %) |
| Called from | `L4MoverA6` |
| Calls | `L4MoverA6` (tail), `L4OnField` |
| Reads | `$7A89` (`FrameCounter`); `$7E36`-`$7E9F`; `$7ED4`-`$7EFF`; `$7F18`-`$7F3F`; `$7F58`-`$7F5F`; `$7F8B`-`$7F8F`; 2 more ranges |
| Writes | `$7E36`-`$7E9E`; `$7ED4`-`$7F3E`; `$7F58`-`$7F5E`; `$7F8B`-`$7F8F`; `$7FAC`-`$7FD1`; `$8004`-`$801B`; 6 more ranges |

#### `L4MoverA7` (`$F45D`)

**Mover A7**

Witness: L1 40 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 40 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,560 t-states own (0.00 %) |
| Called from | `L4SoftDraw` |
| Calls | `L4MoverA6` (tail), `L4SoftDraw` |

#### `L4SoftDraw` (`$F466`)

**Keep DrawTag, AF', DE and BC on the stack, DrawTag 0, SoftCellsOn, then back to the caller**

Witness: L1 439 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 439 calls, 56,359 t-states own (0.01 %) |
| Called from | `L4MoverA6`, `L4MoverA7`, `L4MoverA8` |
| Calls | `L4MoverA6`, `L4MoverA7`, `L4MoverA8` |
| Reads | `$7A9C` (`DrawTag`) |
| Writes | `$7A9C` (`DrawTag`) |

#### `L4MoverA8` (`$F478`)

**Mover A8**

Witness: L1 30 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 30 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,290 t-states own (0.00 %) |
| Called from | `L4SoftDraw` |
| Calls | `L4MoverA6` (tail), `L4SoftDraw` |

#### `L4MoverA9` (`$F482`)

**Mover A9, A10**

Witness: L1 1161 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 1,161 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 198,460 t-states own (0.02 %) |
| Calls | `L4MoverA1` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$7DF9`-`$7DFC` (`LevelVars`); `$8506`-`$8518` (`EnemySlots+5`) |
| Writes | `$7DF9`-`$7DFC` (`LevelVars`); `$8EB1` (`CellMark+15`); `$F4EB`-`$F4EC` (`L4SpawnA+1`) |

#### `L4MoverA11` (`$F4ED`)

**Mover A11**

Witness: L1 1161 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 1,161 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 270,703 t-states own (0.02 %) |
| Calls | `L4MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$7AD1`-`$7AD2` (`Scratch+2`); `$8501`-`$8521` (`EnemySlots`); `$853C` (`EnemySlots+59`); `$8557` (`EnemySlots+86`) |
| Writes | `$5FC1`; `$7A84` (`MapColumn`); `$7ACF`-`$7AD0` (`Scratch`); `$7DF9`-`$7DFB` (`LevelVars`); `$8501`-`$8564` (`EnemySlots`); `$8EB1` (`CellMark+15`) |

#### `L4MoverA12` (`$F5BB`)

**Mover A12**

Witness: L1 1313 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 1,313 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 217,927 t-states own (0.02 %) |
| Calls | `L4MoverA1` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$8509`-`$8524` (`EnemySlots+8`); `$8536` (`EnemySlots+53`); `$F185`-`$F193` (`L4Kinds+507`) |
| Writes | `$F185`-`$F193` (`L4Kinds+507`) |

#### `L4MoverA13` (`$F60C`)

**Mover A13**

Witness: L1 216 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 216 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 92,727 t-states own (0.01 %) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$F09D`-`$F0B7` (`L4Kinds+275`) |
| Writes | `$71D0` (`ScoreDirty`); `$8504`-`$8520` (`EnemySlots+3`); `$853A`-`$856B` (`EnemySlots+57`); `$9A1F`-`$9A20` (`DrawPrepare+1`) |

#### `L4MoverA14` (`$F6A7`)

**Mover A14**

Witness: L1 182 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 182 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 10,621 t-states own (0.00 %) |
| Calls | `L4MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$F1BD`-`$F1D1` (`L4Kinds+563`); `$F6E3` (`L4SpawnB+1`) |
| Writes | `$F6E2`-`$F6E4` (`L4SpawnB`) |

#### `L4MoverA15` (`$F6E5`)

**Mover A15**

Witness: L1 130 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 130 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 6,240 t-states own (0.00 %) |

#### `L4MoverB0` (`$F6FB`)

**Mover B0**

Witness: L1 730 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 730 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 7,338 t-states own (0.00 %) |

#### `L4MoverB1` (`$F6FE`)

**Mover B1**

Witness: L1 4645 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 2,877 calls, 167,894 t-states own (0.02 %) |
| Called from | `L4MoverB3` (tail), `L4MoverB15` (tail), `L4SlotBusy` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L4MoverB2` (`$F709`)

**Mover B2**

Witness: L1 81 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 81 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 4,150 t-states own (0.00 %) |

#### `L4MoverB3` (`$F714`)

**Mover B3**

Witness: L1 2319 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 1,832 calls, 67,289 t-states own (0.01 %) |
| Called from | `L4MoverB4` (tail), `L4MoverB5` (tail) |
| Calls | `L4MoverB1` (tail) |
| Writes | `$8EB1` (`CellMark+15`) |

#### `L4MoverB4` (`$F71A`)

**Mover B4**

Witness: L1 689 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 689 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,268 t-states own (0.00 %) |
| Calls | `L4MoverB3` (tail) |

#### `L4MoverB5` (`$F71C`)

**Mover B5**

Witness: L1 1143 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 1,143 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 13,716 t-states own (0.00 %) |
| Calls | `L4MoverB3` (tail) |

#### `L4MoverB6` (`$F71E`)

**Mover B6, B7**

Witness: L1 5 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 95 t-states own (0.00 %) |
| Calls | `L4MoverB15` (tail) |

#### `L4MoverB8` (`$F722`)

**Mover B8**

Witness: L1 39 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 39 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 741 t-states own (0.00 %) |
| Calls | `L4MoverB15` (tail) |

#### `L4MoverB10` (`$F726`)

**Mover B10, B11**

Witness: L1 284 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 5,415 t-states own (0.00 %) |
| Calls | `L4MoverB15` (tail) |

#### `L4MoverB9` (`$F72A`)

**Mover B9, B12**

Witness: L1 17 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 17 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 323 t-states own (0.00 %) |
| Calls | `L4MoverB15` (tail) |

#### `L4MoverB13` (`$F72E`)

**Mover B13**

Witness: L1 194 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 194 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,686 t-states own (0.00 %) |
| Calls | `L4MoverB15` (tail) |

#### `L4MoverB14` (`$F732`)

**Mover B14**

Witness: L1 12 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 12 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 228 t-states own (0.00 %) |
| Calls | `L4MoverB15` (tail) |

#### `L4MoverB15` (`$F736`)

**Mover B15**

Witness: L1 7 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 7 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 10,475 t-states own (0.00 %) |
| Called from | `L4MoverB6` (tail), `L4MoverB8` (tail), `L4MoverB10` (tail), `L4MoverB9` (tail), `L4MoverB13` (tail), `L4MoverB14` (tail) |
| Calls | `L4MoverB1` (tail), `L4SlotBusy` |
| Reads | `$7A89` (`FrameCounter`); `$7AC1` (`Carriers`) |
| Writes | `$7AC1`-`$7AC8` (`Carriers`) |

#### `L4SlotBusy` (`$F769`)

**Return while the slot is free; else drop the return and go on at Mover B1 (Mover B15 calls it)**

Witness: L1 558 (l4).

| | |
| --- | --- |
| Runs (l4: level 4 played from its load to the next search (the immortality POKE `$91F2`)) | 558 calls, 30,570 t-states own (0.00 %) |
| Called from | `L4MoverB15` |
| Calls | `L4MoverB1` (tail) |
| Reads | `$8501`-`$850A` (`EnemySlots`); `$851C`-`$8525` (`EnemySlots+27`); `$8537` (`EnemySlots+54`) |


## Level 5 (side 2) (`src/level5/level5.json`)

R-Type, Electric Dreams Software 1988: level 5, 8904 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
56). Its entries are `src/level5/<module>.asm`, written from `src/level5/level5.ann` by `kit/mkgame.py --part
src/level5/level5.json`; the recordings: `work/stage1/rec/l5` (l5: level 5 played from its load to the next search
(the immortality POKE `$91F2`)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`level5data`](#level-5-side-2-level5data) | `$C4AE`-`$E775` | 27 of 40 |

### Level 5 (side 2): level5data

`src/level5/level5data.asm`

#### `L5MoverA0` (`$E1E8`)

**Mover A0**

Witness: L1 0 (none).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 1,904 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 38,080 t-states own (0.00 %) |

#### `L5MoverA1` (`$E1EE`)

**Mover A1**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | run into, not called, 228,559 t-states own (0.02 %) |
| Called from | `L5MoverA2` (tail), `L5MoverA6` (tail), `L5MoverA7` (tail), `L5MoverA8` (tail), `L5MoverA9` (tail), `L5MoverA10` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L5MoverA2` (`$E1FC`)

**Mover A2**

Witness: L1 101 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 101 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,247 t-states own (0.00 %) |
| Calls | `L5MoverA1` (tail) |

#### `L5MoverA3` (`$E201`)

**Mover A3**

Witness: L1 453 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 453 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 42,360 t-states own (0.00 %) |
| Calls | `L5SlotBusy` (tail) |
| Reads | `$8501`-`$85F9` (`EnemySlots`) |
| Writes | `$8507`-`$85CF` (`EnemySlots+6`) |

#### `L5MoverA4` (`$E249`)

**Mover A4**

Witness: L1 4378 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 4,378 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 253,191 t-states own (0.03 %) |
| Calls | `L5SlotBusy` (tail) |
| Reads | `$8501`-`$85F4` (`EnemySlots`) |
| Writes | `$8506`-`$8533` (`EnemySlots+5`); `$854E`-`$8557` (`EnemySlots+77`); `$8572` (`EnemySlots+113`); `$858D` (`EnemySlots+140`) |

#### `L5MoverA5` (`$E29D`)

**Mover A5**

Witness: L1 616 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 616 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 15,400 t-states own (0.00 %) |
| Calls | `L5SlotBusy` (tail) |

#### `L5MoverA6` (`$E2A4`)

**Mover A6**

Witness: L1 39 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 39 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 6,518 t-states own (0.00 %) |
| Calls | `L5MoverA1` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$8509` (`EnemySlots+8`); `$851B`-`$8524` (`EnemySlots+26`); `$E04D`-`$E05B` (`L5Kinds+393`) |
| Writes | `$E04D`-`$E05B` (`L5Kinds+393`) |

#### `L5MoverA7` (`$E2F5`)

**Mover A7**

Witness: L1 320 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 320 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 16,083 t-states own (0.00 %) |
| Calls | `L5MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$8504`-`$850E` (`EnemySlots+3`); `$854C`-`$8556` (`EnemySlots+75`); `$8594`-`$8595` (`EnemySlots+147`); `$85DC`-`$85DD` (`EnemySlots+219`); `$85EE`-`$85EF` (`EnemySlots+237`) |
| Writes | `$E318`-`$E319` (`L5SpawnA+1`) |

#### `L5MoverA8` (`$E31A`)

**Mover A8**

Witness: L1 1836 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 1,836 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 80,590 t-states own (0.01 %) |
| Calls | `L5MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$8504`-`$8517` (`EnemySlots+3`); `$8528`-`$853B` (`EnemySlots+39`); `$8555`-`$8556` (`EnemySlots+84`) |
| Writes | `$E318`-`$E319` (`L5SpawnA+1`) |

#### `L5MoverA9` (`$E341`)

**Mover A9**

Witness: L1 4030 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 4,030 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 947,530 t-states own (0.10 %) |
| Calls | `L5MoverA1` (tail), `L5SlotDir`, `L5StepDir` |
| Reads | `$7A89` (`FrameCounter`); `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$7DF9`-`$7DFA` (`LevelVars`); `$8509`-`$85D8` (`EnemySlots+8`); `$85EE`-`$85EF` (`EnemySlots+237`); `$DF3D`-`$DFCB` (`L5Kinds+121`); 2 more ranges |
| Writes | `$7DFA` (`LevelVars+1`); `$8EB1` (`CellMark+15`); `$DF3D`-`$DFCB` (`L5Kinds+121`); `$DFFD`-`$E00B` (`L5Kinds+313`); `$E641`-`$E67C` (`L5SlotDirs`) |

#### `L5MoverA10` (`$E421`)

**Mover A10**

Witness: L1 212 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 212 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 32,908 t-states own (0.00 %) |
| Calls | `L5MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$7AD1`-`$7AD2` (`Scratch+2`); `$7DFB` (`LevelVars+2`); `$8501`-`$85F4` (`EnemySlots`); `$DF3D`-`$DFCB` (`L5Kinds+121`); `$DFFD`-`$E00B` (`L5Kinds+313`) |
| Writes | `$5FC1`-`$5FC7`; `$7A84` (`MapColumn`); `$7ACF`-`$7AD0` (`Scratch`); `$7DFA`-`$7DFB` (`LevelVars+1`); `$8513` (`EnemySlots+18`); `$8525` (`EnemySlots+36`); 8 more ranges |

#### `L5MoverA11` (`$E4FD`)

**Mover A11**

Witness: L1 29 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 29 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 290 t-states own (0.00 %) |
| Calls | `L5SlotBusy` (tail) |

#### `L5MoverA12` (`$E500`)

**Mover A12**

Witness: L1 328 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 328 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,219 t-states own (0.00 %) |
| Calls | `L5SlotBusy` (tail) |

#### `L5MoverA13` (`$E507`)

**Mover A13**

Witness: L1 568 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 568 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 38,198 t-states own (0.00 %) |
| Calls | `L5SlotBusy` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$8506`-`$8524` (`EnemySlots+5`); `$853C`-`$8551` (`EnemySlots+59`); `$856C` (`EnemySlots+107`); `$85CC`-`$85D8` (`EnemySlots+203`) |
| Writes | `$8501`-`$8524` (`EnemySlots`); `$8538`-`$8551` (`EnemySlots+55`); `$85C8`-`$85CF` (`EnemySlots+199`) |

#### `L5MoverB0` (`$E5E2`)

**Mover B0**

Witness: L1 1904 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 1,904 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 19,040 t-states own (0.00 %) |

#### `L5MoverB1` (`$E5E5`)

**Mover B1**

Witness: L1 6505 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 4,329 calls, 231,709 t-states own (0.02 %) |
| Called from | `L5MoverB2` (tail), `L5MoverB15` (tail), `L5SlotBusy` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L5MoverB2` (`$E5F0`)

**Mover B2**

Witness: L1 4228 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 4,228 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 122,650 t-states own (0.01 %) |
| Calls | `L5MoverB1` (tail) |
| Writes | `$8EB1` (`CellMark+15`) |

#### `L5MoverB3` (`$E5F6`)

**Mover B3, B4, B5, B6, B7**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L5MoverB8` (`$E5FA`)

**Mover B8**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L5MoverB10` (`$E5FE`)

**Mover B10, B11**

Witness: L1 25 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 25 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 475 t-states own (0.00 %) |
| Calls | `L5MoverB15` (tail) |

#### `L5MoverB9` (`$E602`)

**Mover B9, B12**

Witness: L1 4 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 76 t-states own (0.00 %) |
| Calls | `L5MoverB15` (tail) |

#### `L5MoverB13` (`$E606`)

**Mover B13**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L5MoverB14` (`$E60A`)

**Mover B14**

Witness: L1 33 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 33 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 627 t-states own (0.00 %) |
| Calls | `L5MoverB15` (tail) |

#### `L5MoverB15` (`$E60E`)

**Mover B15**

Witness: L1 39 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 39 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,793 t-states own (0.00 %) |
| Called from | `L5MoverB10` (tail), `L5MoverB9` (tail), `L5MoverB14` (tail) |
| Calls | `L5MoverB1` (tail), `L5SlotBusy` |
| Reads | `$7A89` (`FrameCounter`); `$7AC1` (`Carriers`) |
| Writes | `$7AC1`-`$7AC8` (`Carriers`) |

#### `L5SlotDir` (`$E693`)

**A = the first byte of the slot's L5SlotDirs record (slot = DrawTag & `$7F` - 1)**

Witness: L1 3609 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 3,609 calls, 420,425 t-states own (0.04 %) |
| Called from | `L5MoverA9` |
| Reads | `$7A9C` (`DrawTag`); `$E641`-`$E686` (`L5SlotDirs`) |

#### `L5StepDir` (`$E6A6`)

**Step the slot by A: 1 row - 1, 2 row + 1, 3 column - 1, 4 column + 1 ...**

Witness: L1 116 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 116 calls, 22,285 t-states own (0.00 %) |
| Called from | `L5MoverA9` |
| Reads | `$8504`-`$8520` (`EnemySlots+3`); `$8531`-`$8532` (`EnemySlots+48`); `$8543`-`$8556` (`EnemySlots+66`); `$8570`-`$8571` (`EnemySlots+111`); `$8582`-`$8583` (`EnemySlots+129`); `$8594`-`$859E` (`EnemySlots+147`); 1 more ranges |
| Writes | `$8504`-`$8520` (`EnemySlots+3`); `$8531`-`$8532` (`EnemySlots+48`); `$8543`-`$8556` (`EnemySlots+66`); `$8570`-`$8571` (`EnemySlots+111`); `$8582`-`$8583` (`EnemySlots+129`); `$8594`-`$859D` (`EnemySlots+147`); 1 more ranges |

#### `L5SlotBusy` (`$E6FB`)

**Return while the slot is free; else drop the return and go on at Mover B1 (Mover B15 calls it)**

Witness: L1 101 (l5).

| | |
| --- | --- |
| Runs (l5: level 5 played from its load to the next search (the immortality POKE `$91F2`)) | 101 calls, 1,398,260 t-states own (0.15 %) |
| Called from | `L5MoverA3` (tail), `L5MoverA4` (tail), `L5MoverA5` (tail), `L5MoverA11` (tail), `L5MoverA12` (tail), `L5MoverA13` (tail), `L5MoverB15` |
| Calls | `L5MoverB1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$8501`-`$850A` (`EnemySlots`); `$851C`-`$8525` (`EnemySlots+27`); `$E089`-`$E1AB` (`L5Kinds+453`) |
| Writes | `$8504`-`$85D4` (`EnemySlots+3`) |


## Level 6 (side 2) (`src/level6/level6.json`)

R-Type, Electric Dreams Software 1988: level 6, 8849 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
60). Its entries are `src/level6/<module>.asm`, written from `src/level6/level6.ann` by `kit/mkgame.py --part
src/level6/level6.json`; the recordings: `work/stage1/rec/l6` (l6: level 6 played from its load to the next search
(the immortality POKE `$91F2`)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`level6data`](#level-6-side-2-level6data) | `$C4AE`-`$E73E` | 18 of 28 |

### Level 6 (side 2): level6data

`src/level6/level6data.asm`

#### `L6MoverA0` (`$E640`)

**Mover A0**

Witness: L1 0 (none).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 5,812 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 140,228 t-states own (0.02 %) |
| Called from | `L6MoverA3` (tail), `L6MoverA4` (tail) |

#### `L6MoverA1` (`$E646`)

**Mover A1**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L6MoverA2` (`$E654`)

**Mover A2**

Witness: L1 195 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 195 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 9,443 t-states own (0.00 %) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L6MoverA3` (`$E659`)

**Mover A3**

Witness: L1 2292 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 2,292 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 526,028 t-states own (0.07 %) |
| Calls | `L6MoverA0` (tail) |
| Reads | `$5FC2`-`$5FC8`; `$7A9C` (`DrawTag`); `$7AD1`-`$7AD2` (`Scratch+2`); `$E4B3`-`$E4F1` (`L6Kinds+337`) |
| Writes | `$5FC2`-`$5FC8`; `$7A9C` (`DrawTag`); `$E4B3`-`$E4F1` (`L6Kinds+337`) |

#### `L6MoverA4` (`$E689`)

**Mover A4**

Witness: L1 161 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 161 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 38,269 t-states own (0.00 %) |
| Calls | `L6MoverA0` (tail) |
| Reads | `$7A9C` (`DrawTag`); `$E4B3`-`$E4F1` (`L6Kinds+337`) |
| Writes | `$7A9C` (`DrawTag`); `$E4B3`-`$E4F1` (`L6Kinds+337`) |

#### `L6MoverA5` (`$E6B2`)

**Mover A5**

Witness: L1 1 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 75 t-states own (0.00 %) |
| Reads | `$85E1` (`EnemySlots+224`) |
| Writes | `$8501` (`EnemySlots`) |

#### `L6MoverA6` (`$E6CB`)

**Mover A6**

Witness: L1 733 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 733 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 7,586 t-states own (0.00 %) |
| Reads | `$5FC3`-`$5FC6`; `$7AD1`-`$7AD2` (`Scratch+2`) |
| Writes | `$5FC3`-`$5FC6` |

#### `L6MoverB0` (`$E6D9`)

**Mover B0**

Witness: L1 8998 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 8,998 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 89,999 t-states own (0.01 %) |

#### `L6MoverB1` (`$E6DC`)

**Mover B1**

Witness: L1 195 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 195 calls, 6,984 t-states own (0.00 %) |
| Called from | `L6MoverB15` (tail), `L6SlotBusy` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L6MoverB2` (`$E6E7`)

**Mover B2, B3**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L6MoverB4` (`$E6E9`)

**Mover B4, B5, B6, B7**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L6MoverB8` (`$E6ED`)

**Mover B8**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L6MoverB10` (`$E6F1`)

**Mover B10, B11**

Witness: L1 97 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 97 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,843 t-states own (0.00 %) |
| Calls | `L6MoverB15` (tail) |

#### `L6MoverB9` (`$E6F5`)

**Mover B9, B12**

Witness: L1 87 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 87 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,672 t-states own (0.00 %) |
| Calls | `L6MoverB15` (tail) |

#### `L6MoverB13` (`$E6F9`)

**Mover B13**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L6MoverB14` (`$E6FD`)

**Mover B14**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L6MoverB15` (`$E701`)

**Mover B15**

Witness: L1 11 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 11 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,622 t-states own (0.00 %) |
| Called from | `L6MoverB10` (tail), `L6MoverB9` (tail) |
| Calls | `L6MoverB1` (tail), `L6SlotBusy` |
| Reads | `$7A89` (`FrameCounter`); `$7AC1` (`Carriers`) |
| Writes | `$7AC1`-`$7AC4` (`Carriers`) |

#### `L6SlotBusy` (`$E734`)

**Return while the slot is free; else drop the return and go on at Mover B1 (Mover B15 calls it)**

Witness: L1 195 (l6).

| | |
| --- | --- |
| Runs (l6: level 6 played from its load to the next search (the immortality POKE `$91F2`)) | 195 calls, 10,695 t-states own (0.00 %) |
| Called from | `L6MoverB15` |
| Calls | `L6MoverB1` (tail) |
| Reads | `$850A`-`$8513` (`EnemySlots+9`); `$8525` (`EnemySlots+36`); `$85D9` (`EnemySlots+216`) |


## Level 7 (side 2) (`src/level7/level7.json`)

R-Type, Electric Dreams Software 1988: level 7, 12997 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
64). Its entries are `src/level7/<module>.asm`, written from `src/level7/level7.ann` by `kit/mkgame.py --part
src/level7/level7.json`; the recordings: `work/stage1/rec/l7` (l7: level 7 played from its load to the next search
(the immortality POKE `$91F2`)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`level7data`](#level-7-side-2-level7data) | `$C4AE`-`$F772` | 24 of 37 |

### Level 7 (side 2): level7data

`src/level7/level7data.asm`

#### `L7MoverA0` (`$F4EF`)

**Mover A0**

Witness: L1 0 (none).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 3,827 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 75,528 t-states own (0.01 %) |

#### `L7MoverA1` (`$F4F5`)

**Mover A1**

Witness: L1 1741 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 1,719 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 292,030 t-states own (0.03 %) |
| Called from | `L7MoverA2` (tail), `L7MoverA3` (tail), `L7MoverA5` (tail), `L7MoverA7` (tail), `L7MoverA10` (tail), `L7MoverA13` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L7MoverA2` (`$F503`)

**Mover A2**

Witness: L1 304 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 245 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,965 t-states own (0.00 %) |
| Calls | `L7MoverA1` (tail) |

#### `L7MoverA3` (`$F508`)

**Mover A3**

Witness: L1 158 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 158 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 7,696 t-states own (0.00 %) |
| Calls | `L7MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$8528`-`$8529`; `$8543`-`$8544` |
| Writes | `$F527`-`$F528` (`L7SpawnA+1`) |

#### `L7MoverA4` (`$F529`)

**Mover A4**

Witness: L1 2011 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 2,011 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 132,371 t-states own (0.01 %) |
| Reads | `$7A84` (`MapColumn`); `$850D`-`$8517`; `$8528`-`$854D` |
| Writes | `$850A`-`$8513`; `$8525`-`$8549`; `$F56D`-`$F56F` (`L7SpawnB`) |

#### `L7MoverA5` (`$F570`)

**Mover A5**

Witness: L1 351 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 351 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 53,203 t-states own (0.00 %) |
| Calls | `L7MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`) |
| Writes | `$8EB1` (`CellMark+15`) |

#### `L7MoverA6` (`$F5D0`)

**Mover A6**

Witness: L1 378 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 378 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 31,611 t-states own (0.00 %) |
| Reads | `$7AA1` (`ShipColumn`); `$F3D2`-`$F400` (`L7Kinds+639`) |
| Writes | `$7ACF`-`$7AD0` (`Scratch`); `$F3D2`-`$F400` (`L7Kinds+639`) |

#### `L7MoverA7` (`$F5FA`)

**Mover A7**

Witness: L1 840 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 840 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 127,822 t-states own (0.01 %) |
| Calls | `L7MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$7AD1`-`$7AD2` (`Scratch+2`); `$7DF9` (`LevelVars`) |
| Writes | `$5FC1`; `$7DF9` (`LevelVars`); `$8501`; `$8EB1` (`CellMark+15`) |

#### `L7MoverA8` (`$F65C`)

**Mover A8, A9**

Witness: L1 196 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 196 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 14,632 t-states own (0.00 %) |
| Writes | `$7A9C` (`DrawTag`) |

#### `L7MoverA10` (`$F66D`)

**Mover A10, A11, A12**

Witness: L1 4867 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 4,788 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 794,703 t-states own (0.07 %) |
| Calls | `L7MoverA1` (tail) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$8509`-`$856C`; `$F392`-`$F3A0` (`L7Kinds+575`) |
| Writes | `$F392`-`$F3A0` (`L7Kinds+575`) |

#### `L7MoverA13` (`$F6BE`)

**Mover A13, A14**

Witness: L1 1052 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 796 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 44,661 t-states own (0.00 %) |
| Calls | `L7MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$F44C`-`$F462` (`L7Kinds+761`); `$F6FA` (`L7SpawnC+1`) |
| Writes | `$F6F9`-`$F6FB` (`L7SpawnC`) |

#### `L7MoverB0` (`$F6FC`)

**Mover B0**

Witness: L1 5322 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 4,198 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 41,999 t-states own (0.00 %) |

#### `L7MoverB1` (`$F6FF`)

**Mover B1**

Witness: L1 9299 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 1,431 calls, 320,974 t-states own (0.03 %) |
| Called from | `L7MoverB2` (tail), `L7SlotBusy` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L7MoverB2` (`$F70A`)

**Mover B2, B3**

Witness: L1 1191 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 1,191 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 34,539 t-states own (0.00 %) |
| Calls | `L7MoverB1` (tail) |
| Writes | `$8EB1` (`CellMark+15`) |

#### `L7MoverB4` (`$F710`)

**Mover B4, B5**

Witness: L1 196 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 196 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 5,292 t-states own (0.00 %) |

#### `L7MoverB6` (`$F716`)

**Mover B6**

Witness: L1 2011 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 2,011 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 54,297 t-states own (0.00 %) |
| Writes | `$8EB1` (`CellMark+15`) |

#### `L7MoverB7` (`$F71D`)

**Mover B7**

Witness: L1 32 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 32 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 608 t-states own (0.00 %) |
| Calls | `L7MoverB15` (tail) |

#### `L7MoverB8` (`$F721`)

**Mover B8**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L7MoverB10` (`$F725`)

**Mover B10, B11**

Witness: L1 86 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 86 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,634 t-states own (0.00 %) |
| Calls | `L7MoverB15` (tail) |

#### `L7MoverB9` (`$F729`)

**Mover B9, B12**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L7MoverB13` (`$F72D`)

**Mover B13**

Witness: L1 67 (l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 67 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,273 t-states own (0.00 %) |
| Calls | `L7MoverB15` (tail) |

#### `L7MoverB14` (`$F731`)

**Mover B14**

Witness: L1 113 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 57 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,083 t-states own (0.00 %) |
| Calls | `L7MoverB15` (tail) |

#### `L7MoverB15` (`$F735`)

**Mover B15**

Witness: L1 6 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 4,750 t-states own (0.00 %) |
| Called from | `L7MoverB7` (tail), `L7MoverB10` (tail), `L7MoverB13` (tail), `L7MoverB14` (tail) |
| Calls | `L7SlotBusy` |
| Reads | `$7A89` (`FrameCounter`); `$7AC1` (`Carriers`) |
| Writes | `$7AC1`-`$7AC4` (`Carriers`) |

#### `L7SlotBusy` (`$F768`)

**Return while the slot is free; else drop the return and go on at Mover B1 (Mover B15 calls it)**

Witness: L1 304 (deaths-l7, l7).

| | |
| --- | --- |
| Runs (l7: level 7 played from its load to the next search (the immortality POKE `$91F2`)) | 245 calls, 13,419 t-states own (0.00 %) |
| Called from | `L7MoverB15` |
| Calls | `L7MoverB1` (tail) |
| Reads | `$8501`-`$8513`; `$8540`; `$85D9` |


## Level 8 (side 2) (`src/level8/level8.json`)

R-Type, Electric Dreams Software 1988: level 8, 11980 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
68). Its entries are `src/level8/<module>.asm`, written from `src/level8/level8.ann` by `kit/mkgame.py --part
src/level8/level8.json`; the recordings: `work/stage1/rec/l8` (l8: level 8 played from its load to the next search
(the immortality POKE `$91F2`)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`level8data`](#level-8-side-2-level8data) | `$C4AE`-`$F379` | 25 of 38 |

### Level 8 (side 2): level8data

`src/level8/level8data.asm`

#### `L8MoverA0` (`$EEEC`)

**Mover A0**

Witness: L1 0 (none).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L8MoverA1` (`$EEF2`)

**Mover A1**

Witness: L1 2059 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 2,059 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 181,383 t-states own (0.03 %) |
| Called from | `L8MoverA2` (tail), `L8MoverA7` (tail), `L8MoverA8` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L8MoverA2` (`$EF00`)

**Mover A2**

Witness: L1 158 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 158 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,921 t-states own (0.00 %) |
| Calls | `L8MoverA1` (tail) |

#### `L8MoverA3` (`$EF05`)

**Mover A3**

Witness: L1 2445 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 2,445 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 208,698 t-states own (0.03 %) |
| Calls | `L8Random` |
| Reads | `$7A82`-`$7A89` (`ScrollStep`, `MetaColumn`, `MapColumn`, `FrameCounter`); `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`); `$85AF`-`$85CB` (`EnemySlots+174`); `$EF8E`-`$EF8F` (`L8Vars`) |
| Writes | `$85AC`-`$85C7` (`EnemySlots+171`); `$EF8E`-`$EF91` (`L8Vars`); `$EFC3`-`$EFC4` (`L8SpawnA+1`) |

#### `L8BossBurst` (`$EF92`)

**Mover A3's end: free four slots from EnemySlots + 171 and start a wave (L8SpawnA) at each one's position**

Witness: L1 2 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `L8MoverA4` (`$EFC5`)

**Mover A4**

Witness: L1 1120 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 1,120 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 90,507 t-states own (0.01 %) |
| Reads | `$7AA1`-`$7AA2` (`ShipColumn`, `ShipRow`) |

#### `L8MoverA5` (`$EFE0`)

**Mover A5, A11, A12, A13, A14, A15**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L8MoverA6` (`$EFF5`)

**Mover A6**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L8MoverA7` (`$F029`)

**Mover A7**

Witness: L1 1670 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 1,670 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 52,692 t-states own (0.01 %) |
| Calls | `L8MoverA1` (tail) |
| Reads | `$7A82`-`$7A84` (`ScrollStep`, `MetaColumn`, `MapColumn`) |

#### `L8MoverA8` (`$F04A`)

**Mover A8**

Witness: L1 752 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 752 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 118,341 t-states own (0.02 %) |
| Calls | `L8MoverA1` (tail) |
| Reads | `$7A89` (`FrameCounter`); `$7DF9` (`LevelVars`) |
| Writes | `$7DF9` (`LevelVars`); `$857F` (`EnemySlots+126`); `$8EB1` (`CellMark+15`) |

#### `L8MoverA9` (`$F07F`)

**Mover A9**

Witness: L1 835 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 835 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 25,366 t-states own (0.00 %) |
| Calls | `L8MoverB1` (tail) |
| Reads | `$7DF9` (`LevelVars`) |

#### `L8MoverA10` (`$F0AD`)

**Mover A10**

Witness: L1 2697 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 2,697 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 78,232 t-states own (0.01 %) |
| Writes | `$85AC`-`$85C7` (`EnemySlots+171`) |

#### `L8MoverB0` (`$F0B4`)

**Mover B0**

Witness: L1 6262 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 6,262 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 62,677 t-states own (0.01 %) |

#### `L8MoverB1` (`$F0B7`)

**Mover B1**

Witness: L1 5474 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 1,745 calls, 197,796 t-states own (0.03 %) |
| Called from | `L8MoverA9` (tail), `L8MoverB3` (tail), `L8MoverB15` (tail), `L8SlotBusy` (tail) |
| Reads | `$7A89` (`FrameCounter`) |

#### `L8MoverB2` (`$F0C2`)

**Mover B2**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L8MoverB3` (`$F0C9`)

**Mover B3**

Witness: L1 752 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 752 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 21,808 t-states own (0.00 %) |
| Calls | `L8MoverB1` (tail) |
| Writes | `$8EB1` (`CellMark+15`) |

#### `L8MoverB4` (`$F0CF`)

**Mover B4, B5, B6, B7**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L8MoverB8` (`$F0D3`)

**Mover B8**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `L8MoverB10` (`$F0D7`)

**Mover B10, B11**

Witness: L1 34 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 34 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 646 t-states own (0.00 %) |
| Calls | `L8MoverB15` (tail) |

#### `L8MoverB9` (`$F0DB`)

**Mover B9, B12**

Witness: L1 13 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 247 t-states own (0.00 %) |
| Calls | `L8MoverB15` (tail) |

#### `L8MoverB13` (`$F0DF`)

**Mover B13**

Witness: L1 51 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 51 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 969 t-states own (0.00 %) |
| Calls | `L8MoverB15` (tail) |

#### `L8MoverB14` (`$F0E3`)

**Mover B14**

Witness: L1 60 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 60 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,140 t-states own (0.00 %) |
| Calls | `L8MoverB15` (tail) |

#### `L8MoverB15` (`$F0E7`)

**Mover B15**

No recording ran it: known only from the code.

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | run into, not called, 3,253 t-states own (0.00 %) |
| Called from | `L8MoverB10` (tail), `L8MoverB9` (tail), `L8MoverB13` (tail), `L8MoverB14` (tail) |
| Calls | `L8MoverB1` (tail), `L8SlotBusy` |
| Reads | `$7A89` (`FrameCounter`); `$7AC1` (`Carriers`) |
| Writes | `$7AC1`-`$7AC8` (`Carriers`) |

#### `L8Random` (`$F11A`)

**RandomPtr + 1; A = the ROM byte there**

Witness: L1 152 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 152 calls, 9,180 t-states own (0.00 %) |
| Called from | `L8MoverA3` |
| Reads | `$7ACD`-`$7ACE` (`RandomPtr`) |
| Writes | `$7ACD`-`$7ACE` (`RandomPtr`) |

#### `L8SlotBusy` (`$F123`)

**Return while the slot is free; else drop the return and go on at Mover B1 (Mover B15 calls it)**

Witness: L1 158 (l8).

| | |
| --- | --- |
| Runs (l8: level 8 played from its load to the next search (the immortality POKE `$91F2`)) | 158 calls, 8,615 t-states own (0.00 %) |
| Called from | `L8MoverB15` |
| Calls | `L8MoverB1` (tail) |
| Reads | `$850A`-`$851C` (`EnemySlots+9`) |
