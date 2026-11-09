# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/game` (the first recording's game window). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the entries they cover. An entry no recording reached says so.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`main`](#main) | `$8000`-`$8105` | 10 of 10 |
| [`input`](#input) | `$8106`-`$827D` | 7 of 11 |
| [`shot`](#shot) | `$827E`-`$8505` | 9 of 11 |
| [`aim`](#aim) | `$8506`-`$86C0` | 5 of 6 |
| [`physics`](#physics) | `$86C1`-`$8A01` | 5 of 6 |
| [`shotsetup`](#shotsetup) | `$8A02`-`$8A87` | 6 of 10 |
| [`balls`](11-data-reference.md#balls) | `$8A88`-`$8B4D` | 0 of 4 |
| [`cushions`](#cushions) | `$8B4E`-`$90F4` | 10 of 11 |
| [`friction`](#friction) | `$90F5`-`$9154` | 2 of 2 |
| [`scheduler`](#scheduler) | `$9155`-`$9242` | 5 of 6 |
| [`tabledraw`](#tabledraw) | `$9243`-`$93FE` | 6 of 6 |
| [`balldraw`](#balldraw) | `$93FF`-`$95D9` | 8 of 9 |
| [`hud`](#hud) | `$95DA`-`$9753` | 4 of 6 |
| [`gameover`](#gameover) | `$9754`-`$98F8` | 10 of 11 |
| [`tally`](#tally) | `$98F9`-`$9B35` | 12 of 13 |
| [`turns`](#turns) | `$9B36`-`$9D6A` | 9 of 14 |
| [`printing`](#printing) | `$9D6B`-`$9F35` | 11 of 12 |
| [`racking`](#racking) | `$9F36`-`$A161` | 5 of 9 |
| [`rackscripts`](11-data-reference.md#rackscripts) | `$A162`-`$A701` | 0 of 10 |
| [`halloffame`](#halloffame) | `$A702`-`$ACEE` | 21 of 26 |
| [`nameentry`](#nameentry) | `$ACEF`-`$B22D` | 10 of 17 |
| [`menu`](#menu) | `$B22E`-`$B8C4` | 10 of 17 |
| [`presents`](#presents) | `$B8C5`-`$BB12` | 9 of 11 |
| [`attract`](#attract) | `$BB13`-`$BD0B` | 4 of 8 |
| [`signature`](#signature) | `$BD0C`-`$C041` | 17 of 24 |
| [`editor`](#editor) | `$C042`-`$C5FF` | 19 of 23 |
| [`workspace`](11-data-reference.md#workspace) | `$C600`-`$CFFF` | 0 of 2 |
| [`sprites`](11-data-reference.md#sprites) | `$D000`-`$DA7F` | 0 of 1 |
| [`penscript`](11-data-reference.md#penscript) | `$DA80`-`$DBF9` | 0 of 1 |
| [`physicstables`](11-data-reference.md#physicstables) | `$DBFA`-`$DEF3` | 0 of 4 |
| [`font`](11-data-reference.md#font) | `$DEF4`-`$E013` | 0 of 1 |
| [`devleftover`](#devleftover) | `$E014`-`$E1A7` | 6 of 9 |

## main

`src/game/main.asm`

### `GameStart` (`$8000`)

**The game's entry: the stack, the ball records, the presents page**

Entered once by the turbo loader's JP `$8000` (every build: game frame 5556, each play recording at its start). LD SP,`$D000` (the stack below BallSprites), `$9D2C` resets the ball records, EI (still IM 1, the ROM's handler), `$BD0B` = 0, the presents page and attract sequence `$B8C5` (returns on a key), `$BD0B` = `$FF` (so a later attract run is shorter), then falls into GameRestart.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 85 t-states own (0.00 %) |
| Calls | `GameRestart`, `ResetBallPositions`, `PresentsPage` |
| Writes | `$BD0B` (`PresentsSP`) |

### `GameRestart` (`$8013`)

**IM 2 on, the menu, a new game, the first aim; falls into SoundLoop**

Entered from GameStart and from BreakRestart (game 2 entries at frames 6060 and 9091; w1 2; m1 3). DI, I = `$FE`, IM 2; fills Im2Table `$FE00-$FF00` with `$FC` and writes EI, JP Im2Handler at Im2Jump `$FCFC`, so every interrupt runs Im2Handler whatever the data bus holds (c1 stage 6, frame 6061). EI, then the menu `$B22E` (returns when "begin" is chosen), the table `$95DA`, A = 4 / 3 for `$9DC3`, the shots left `$9F4D` from `$9BE6`, `$9D6B`, `$9B30` = 1, `$9520`, `$9AD9`, `$9C7B`, the racking `$9F69` and the first aim StartAim. Then SoundRequest = 0 and EI, into SoundLoop.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 11,302 t-states own (0.00 %) |
| Called from | `GameStart`, `BreakRestart` (tail) |
| Calls | `SoundLoop`, `StartAim`, `DrawAllBalls`, `NewGameScreen`, `DrawLives`, `ShotsForFrame`, `PlayerBanner`, `DrawPocketMarks`, `PrintHudNumber`, `Rack`, `MainMenu` |
| Reads | `$FE00`-`$FEFF` (`work space $FE00+`) |
| Writes | `$827D` (`SoundRequest`); `$9B30` (`ScoreVars`); `$9F4D` (`PlayerVars`); `$FCFC`-`$FCFF` (`work space $FCFC+`); `$FE00`-`$FF00` (`work space $FE00+`) |

### `SoundLoop` (`$8069`)

**The foreground: wait for BREAK or a sound request, play it on the beeper**

The whole foreground of play (w1 6 290 430 passes, frames 877-11 615). Loops reading InputState `$827C` (bit 5 BREAK: BreakRestart) and SoundRequest `$827D` (0: none). A request 1, 2 or 3 picks B = the half period in passes of SoundDelay (37 T a pass) and C = the number of cycles: 1 = 20 / 20 (a ball against a ball, written at `$8993`), 2 = 30 / 12 (a cushion, `$8DC0` / `$8DF4` / `$8E28`), 3 = 250 / 6 (a pocket, `$8C17`). Each cycle is OUT (`$FE`) `$17` (speaker bit 4 on, border 7), the delay, OUT `$07` (off), the delay. At the end it clears SoundRequest itself.

The tone stops at once when a task sets SoundRequest to 0 while it plays (SoundAbort: border back to 7): StopShotTasks `$8483` and ShotReset `$84C7` clear it. A new non-zero request during a tone does not restart it; the tone runs on and its final clear drops the new request. The interrupt stays on while it plays, so each half period also holds the time of any task run in it. w1: 1962 cycles played; SoundAbort taken 4 times.

A request written while a tone plays is lost (SoundDelay tests only for zero; the tone's end clears it); of two writes in one tick the last wins. w1: 178 requests, 141 tones, 21 lost, 16 replaced (docs 9.3).

[Animation: `SoundLoop` at work](img/routines/SoundLoop.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,731,083 calls, 102,169,034 t-states own (34.37 %) |
| Called from | `GameRestart`, `Im2Handler` |
| Calls | `SoundDelay` |
| Reads | `$827C`-`$827D` (`InputState`, `SoundRequest`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$827D` (`SoundRequest`); `$CFFE`-`$CFFF` (`StackSpace`) |
| Ports out | `$07FE`, `$17FE` |

### `SoundDelay` (`$809D`)

**Half a period: B passes of 37 T, aborted when the request goes to 0**

Input B (saved). Each pass reads SoundRequest; at 0 it drops its own return address and SoundLoop's (POP BC twice), sets the border/speaker to `$07` and jumps back to SoundLoop. w1: 3922 calls (two per cycle).

| | |
| --- | --- |
| Runs (the first recording's game window) | 48 calls, 54,528 t-states own (0.02 %) |
| Called from | `SoundLoop` |
| Reads | `$827D` (`SoundRequest`) |

### `BreakRestart` (`$80B0`)

**BREAK: clear the tasks, reset the stack, back to the menu**

Jumped to from SoundLoop when InputState bit 5 is set (game frame 9091, w1 14 233, f1 5196, p2 4239, v1 2133; m1 at 6830 and 7998). ClearTasks `$91CF`, SP = `$D000`, JP GameRestart.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 37 t-states own (0.00 %) |
| Called from | `GameOver` (tail) |
| Calls | `GameRestart` (tail), `ClearTasks` |

### `InstallTasks` (`$80B9`)

**Add every task of a list: (period, routine) triples, `$FF` ends**

DE = the list (AimTasks `$84AA`, MovingTasks `$84BA`, the editor's `$C518`). For each triple: C = the period, HL = the routine, AddTask `$9188`. Returns at the `$FF`. w1: 42 lists installed (231 triples read).

| | |
| --- | --- |
| Runs (the first recording's game window) | 8 calls, 4,268 t-states own (0.00 %) |
| Called from | `StartAim`, `AimPower` |
| Calls | `AddTask` |
| Reads | `$84AA`-`$84C6` (`AimTasks`, `MovingTasks`) |

### `RemoveTasks` (`$80CC`)

**Remove every task of a list by its routine's address**

DE = the list as for InstallTasks; RemoveTask `$91AD` for each routine (the period is skipped). w1: 42 lists removed.

| | |
| --- | --- |
| Runs (the first recording's game window) | 8 calls, 4,124 t-states own (0.00 %) |
| Called from | `StopShotTasks`, `AimPower` |
| Calls | `RemoveTask` |
| Reads | `$84AA`-`$84C6` (`AimTasks`, `MovingTasks`) |

### `WaitFrameNoTasks` (`$80DE`)

**Run HL with the tasks stopped, then wait for one interrupt**

Writes RET (`$C9`) over the JP at Im2Jump+1 (`$FCFD`): the interrupt is then EI; RET, so the scheduler does not run. EI, calls the routine in HL (WaitFrameCall), HALTs for the next interrupt, DI and puts the JP (`$C3`) back. Callers: the shot end WaitMessages `$8451` and `$9C0F`, the racking `$9F69` (w1 58 calls). The routine may HALT by itself (WaitMessagesLoop does, once a frame): every interrupt it waits for is a plain EI; RET. That is why Im2Jump ran 3503 times in c1 against 2577 for Im2Handler (stage 1).

| | |
| --- | --- |
| Runs (the first recording's game window) | 21 calls, 1,305,178 t-states own (0.44 %) |
| Called from | `WaitMessages` (tail), `FoulJingle` (tail), `GameOver`, `ScoreShot` (tail), `TurnSwapStart` (tail), `Rack` (tail) |
| Calls | `WaitFrameCall` |
| Reads | `$80E8` (`WaitFrameNoTasks`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CFE4`-`$CFE7` (`StackSpace`); `$CFFC`-`$CFFD` (`StackSpace`); `$FCFD` (`work space $FCFD+`) |

### `WaitFrameCall` (`$80EF`)

**JP (HL)**

The CALL target of WaitFrameNoTasks: jumps to the routine in HL, which returns to `$80E7`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 21 calls, 84 t-states own (0.00 %) |
| Called from | `WaitFrameNoTasks` |
| Calls | `WaitMessagesLoop`, `FoulJingleNotes`, `GameOverWait`, `ScoreTally`, `TurnSwap`, `RackBalls` |

### `Im2Handler` (`$80F0`)

**The interrupt: save every register, run the scheduler**

Reached through Im2Jump `$FCFC` (EI; JP Im2Handler) on every interrupt while the JP is in place (w1 9536 entries, frames 501-16 377). DI, pushes AF, BC, DE, HL, IX, IY, calls the scheduler `$9155`, pops them, EI, RET. The alternate registers are not saved: no task uses them.

[Animation: `Im2Handler` at work](img/routines/Im2Handler.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,577 calls, 456,047 t-states own (0.15 %) |
| Called from | `RunTasks` |
| Calls | `SoundLoop`, `RunTasks` |

## input

`src/game/input.asm`

### `ReadInput` (`$8106`)

**The input task: A = the directions and fire of the chosen control, into InputState**

Pushes ReadBreak as the return, then jumps through InputHandlers by the control choice `$B8BD` (0-3). Output: InputState `$827C` (bits 0 right, 1 left, 2 up, 3 down, 4 fire, 5 BREAK). Witness: w1 6407 calls (keyboard only), m1 927 (keyboard 317, Kempston 51 at frames 4922-4980, cursor 559 at frames 6272-6830), j1 (Kempston 1087 at frames 622-2185, Interface 2 836 at frames 2503-3540, a shot played with each).

| | |
| --- | --- |
| Runs (the first recording's game window) | 279 calls, 165,600 t-states own (0.06 %) |
| Called from | `CallTask`, `WaitFramesOrKey` |
| Calls | `ReadKeyboard` |
| Reads | `$811B`-`$811C` (`InputHandlers`); `$B8BD` (`Players`) |

### `ReadKeyboard` (`$8123`)

**The keyboard: the three defined keys, left, right, fire**

The keys are the characters at `$B8BE` (left), `$B8BF` (right) and `$B8C0` (fire), set by "reconfigure keys" (default m, symbol shift, space: the menu's last line). KeyDown for each: left gives bit 1, right bit 0, fire bit 4; there is no up and down on the keyboard (the cursor runs round the cushions with left and right alone, AimCursorMove `$8546`). w1: 6407 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 308,355 t-states own (0.10 %) |
| Called from | `ReadInput` |
| Calls | `ReadBreak`, `KeyDown` |
| Reads | `$B8BE`-`$B8C0` (`Players`) |

### `ReadInterface2` (`$8151`)

**Interface 2: both joysticks, keys 6-0 and 1-5**

j1 (menu I): 836 calls at frames 2503-3540; key 6 held 40 frames from 2565 moved the cursor, key 0 held 30 frames from 2610 played the shot at 2640. Reads port `$EFFE` (keys 6-0, Interface 2's joystick 1: 6 left, 7 right, 8 down, 9 up, 0 fire) and port `$F7FE` (keys 1-5, joystick 2: 1 left, 2 right, 3 down, 4 up, 5 fire), each inverted with CPL, and ORs both into the result bits (fire `$10`, right `$01`, left `$02`, up `$04`, down `$08`), so either joystick works.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadKempston` (`$81A0`)

**Kempston: IN (`$1F`), active high**

IN A,(`$1F`): bit 0 right, 1 left, 2 down, 3 up, 4 fire, moved to the game's bits (down to bit 3, up to bit 2). m1: 51 calls at frames 4922-4980 (option j on the menu, no stick held); j1 (menu J): 1087 calls at frames 622-2185, the stick left 40 frames from 1000 moved the cursor, fire 30 frames from 1045 played the shot at 1075.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadCursorKeys` (`$81C4`)

**The cursor joystick: 8 right, 5 left, 7 up, 6 down, any other key fire**

KeyDown for '8', '5', '6', '7'; when none is down, the ROM's KEY_SCAN and K_TEST: any other key (not 5-8) gives fire (`$10`). m1: 559 calls at frames 6272-6830, 328 with no key (`$8213`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadBreak` (`$8216`)

**BREAK into bit 5, then the result into InputState**

The return of every reader (pushed by ReadInput). CAPS SHIFT (port `$FEFE` bit 0) and SPACE (port `$7FFE` bit 0) both down add bit 5 (`$20`). Stores A into InputState. Taken (bit 5 set): p2 1, v1 1, m1 2 (the BREAKs of those recordings).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,725 calls, 112,151 t-states own (0.04 %) |
| Called from | `ReadKeyboard` |
| Writes | `$827C` (`InputState`) |
| Ports in | `$FEFE` |

### `KeyDown` (`$822E`)

**Is the key with character A down? Z = down**

Looks A up in KeyTable with CPIR (40 bytes), turns the position into the half row's port high byte (B = `$FE`, `$FD`, ... `$7F`) and the bit (D = `$10` down to `$01`: KeyTable runs from the outer key inwards), reads the port and ANDs the bit: Z when the key is down (the port bit is 0). NZ when the character is not in the table. w1: 19 221 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 5,175 calls, 5,087,159 t-states own (1.71 %) |
| Called from | `ReadKeyboard` |
| Reads | `$8254`-`$8279` (`KeyTable`) |
| Ports in | `$7FFE` |

## shot

`src/game/shot.asm`

### `BallRedraw` (`$827E`)

**The redraw task: each ball of DrawList, top to bottom, erased and drawn again where it moved**

Task of MovingTasks (period 0; w1 2839 runs, frames 1086-11 615). For the 7 entries of DrawList `$869E` (sorted by y by BuildDrawList): A = the ball's number (0 = the cue ball), IX = its record, RedrawBall.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 290,576 t-states own (0.10 %) |
| Called from | `CallTask` |
| Calls | `RedrawBall` |
| Reads | `$869E`-`$86B9` (`DrawList`) |

### `RedrawBall` (`$8297`)

**Erase and redraw one ball if it moved; a potted ball goes to the row at the top**

IX = the ball record (`$8A88` + 14n), A = n. Only for a ball with record +13 bit 7 (on the table) and bit 4 (moved): erases the sprite at its old screen position (+10/+11 into `$95D8`, XOR draw `$9548`), then, unless bit 5 (potted) is set, computes the new sprite position from x and y (`$9F36`), stores it in +10/+11 and `$95D8`, clears bit 4 and draws it again (`$9548` XOR). w1 19 873 calls.

A potted ball (bit 5; RedrawPotted, w1 18 times): +13 = 0 (off the table); the cue ball (n = 0) stays off; ball n >= 1 is put at x = 24(n-1) + 7, y = 27 (integer bytes, fractions 0: the row of potted balls above the table) and drawn there when the message counter `$9F50` is 0 or `$50`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,002 calls, 182,468 t-states own (0.06 %) |
| Called from | `BallRedraw` |
| Calls | `DrawBall` (tail), `SpriteFromBall` |
| Reads | `$8A92`-`$8AE9` (`BallRecords`) |
| Writes | `$8A92`-`$8A95` (`BallRecords`); `$95D8`-`$95D9` (`SpritePos`) |

### `BuildDrawList` (`$8304`)

**DrawList from the ball records, sorted by y**

Writes the 7 entries of DrawList: the ball's number, its y (record +3, the integer byte), the record's address; then an exchange sort by y: pass k (6 passes) compares entry k with each later entry and swaps the two when entry k's y is not smaller (`$8334` CP (HL), `$8337` JR C), so after pass k the k-th smallest y is in place (equal y swap too); BallRedraw draws the balls from the top of the screen down. Called by ShotReset (w1 3451 calls also from the physics, frames 706-11 615).

| | |
| --- | --- |
| Runs (the first recording's game window) | 464 calls, 3,154,965 t-states own (1.06 %) |
| Called from | `ShotReset`, `PhysicsTask`, `RackBalls` |
| Reads | `$869E`-`$86B9` (`DrawList`); `$8A8B`-`$8ADF` (`BallRecords`) |
| Writes | `$869E`-`$86B9` (`DrawList`) |

### `ShotEnd` (`$8357`)

**The end-of-shot task: frame cleared, or all balls still: foul, shots, next aim**

Task of MovingTasks (w1 2860 runs). If no object ball is on the table (record +13 bit 7 clear for balls 1-6): StopShotTasks, WaitMessages, the score `$98F9`, `$9754` when the foul flag `$8E80` is set or the cue ball is off; erase the cue ball; `$9BB8`, the racking `$9F69` and StartAim (the next frame; witness w1 frames 1-3 won).

Otherwise (ShotEndStill) it returns while any ball has a bit of `$70` in +13 (moving, moved or potted). When all are still: StopShotTasks and WaitMessages; then, if no foul and the cue ball is on the table: no ball touched (`$89BB` = 0) is a foul (`$8E80` = 1, ShotFoul); a ball touched but none potted (record +12 = 0 for all six) costs a shot (`$9F4D` - 1; at 0 the same foul flag). Then the score `$98F9`, the foul / life code `$9754` if `$8E80` or the cue ball is off, `$93FF` (put the cue ball back) when the cue ball is off and lives `$9F4E` are left, `$9DC3` with A = 3, and StartAim.

ScoreTally runs before LoseLife, so a foul pot still scores: v1 frames 3045-3375, ball 5 into pocket 3 in variation 2, 150 paid, then a life lost (docs 10.9).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 42,082 t-states own (0.01 %) |
| Called from | `CallTask` |
| Calls | `StartAim`, `WaitMessages`, `StopShotTasks`, `LoseLife`, `ScoreShot`, `PrintHudNumber` |
| Reads | `$89BB` (`ContactVars`); `$8A95`-`$8AE9` (`BallRecords`); `$8E80` (`FoulCode`) |
| Writes | `$8E80` (`FoulCode`) |

### `StartAim` (`$8425`)

**The aim: cursor and power reset, AimTasks in, the three periodic HUD tasks**

AimCursorReset, AimPowerReset, InstallTasks AimTasks, then AddTask `$96E6` period 20, `$970E` period 25 and `$9CA7` period 25 (with `$9B31` / `$9B32` = 0). Called at the game's start, after each shot and each frame (w1 21 times, frames 877-11 386).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 760 t-states own (0.00 %) |
| Called from | `GameRestart`, `ShotEnd` |
| Calls | `InstallTasks`, `AimPowerReset`, `AimCursorReset`, `AddTask` (tail) |
| Writes | `$9B31`-`$9B32` (`ScoreVars`) |

### `WaitMessages` (`$8451`)

**Wait with the tasks stopped until the message on show is done**

WaitFrameNoTasks with WaitMessagesLoop. Called by ShotEnd twice and ShotFoul (w1 25 calls).

| | |
| --- | --- |
| Runs (the first recording's game window) | 8 calls, 160 t-states own (0.00 %) |
| Called from | `ShotEnd` |
| Calls | `WaitFrameNoTasks` (tail) |

### `WaitMessagesLoop` (`$8457`)

**Run the message task once a frame until the message counter allows play**

With the tasks stopped (WaitFrameNoTasks): while the message counter `$9F50` is 1-`$4E`, or is `$4F` and no ball was potted, or is 0 with the foul flag `$8E80` set: HALT, the message task `$9CB7`, again. Returns when `$9F50` >= `$50`, or 0 with no foul. w1: 345 passes (320 HALTs).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 22,027,624 t-states own (7.41 %) |
| Called from | `WaitFrameCall` |
| Calls | `MessagesTask` |
| Reads | `$847E` (`WaitMessagesLoop`); `$8AA2`-`$8AE8` (`BallRecords`); `$8E80` (`FoulCode`); `$9F50` (`PlayerVars`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CFE4`-`$CFE5` (`StackSpace`) |

### `StopShotTasks` (`$8483`)

**Remove MovingTasks and the two HUD tasks, silence the sound**

RemoveTasks MovingTasks; RemoveTask `$96E6` and `$970E`, each run once more with `$9B31` / `$9B32` = `$FF` (their final state); SoundRequest = 0. w1 21 calls.

The clear (`$84A6`): 4 of its 21 clears in w1 come while a pocket tone plays (frames 2917, 3895, 6745, 10068): the tone is frozen with the foreground until the end-of-shot sequence returns, then aborted (`$80A8`; docs 9.3).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 728 t-states own (0.00 %) |
| Called from | `ShotEnd` |
| Calls | `RemoveTasks`, `RemoveTask`, `UpBlinkTask`, `ShotsBlinkTask` |
| Writes | `$827D` (`SoundRequest`); `$9B31`-`$9B32` (`ScoreVars`) |

### `ShotReset` (`$84C7`)

**Before a shot: clear the shot's flags, the velocities and friction steps of the 7 balls**

Called by AimPower on the release of fire (w1 21). Clears `$89BB` (a ball was touched), the foul flag `$8E80`, the message counter `$9F50`, SoundRequest and `$8B4C`; for each ball record +4..+9 (velocities and friction steps) and +12, and +13 down to bit 7; then BuildDrawList.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 6,268 t-states own (0.00 %) |
| Called from | `AimPower` |
| Calls | `BuildDrawList` |
| Reads | `$8A95`-`$8AE9` (`BallRecords`) |
| Writes | `$827D` (`SoundRequest`); `$89BB` (`ContactVars`); `$8A8C`-`$8AE9` (`BallRecords`); `$8B4C` (`FrictionTurn`); `$8E80` (`FoulCode`); `$9F50` (`PlayerVars`) |

## aim

`src/game/aim.asm`

### `AimPower` (`$8506`)

**The power task: +2 a tick while fire is held; on the release, play the shot**

Task of AimTasks (w1 4425 runs). Fire held (InputState bit 4): Power + 2, back to 0 when it reaches `$86` (the bar fills and starts again). Fire up with Power 0: nothing. Fire up with Power > 0 (AimShoot): erase the cursor (`$9371`), RemoveTasks AimTasks, RemoveTask `$9CA7`, ShotReset, the shot's velocity from the cursor and the power (`$8A02`, the ROM calculator) and InstallTasks MovingTasks. w1: 21 shots.

[Animation: `AimPower` at work](img/routines/AimPower.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 90,611 t-states own (0.03 %) |
| Called from | `FrictionSteps`, `CallTask` |
| Calls | `InstallTasks`, `RemoveTasks`, `ShotReset`, `AimShot`, `RunTasks`, `RemoveTask`, `DrawCursor` |
| Reads | `$827C` (`InputState`); `$86BF` (`DrawList`) |
| Writes | `$86BF` (`DrawList`) |

### `AimPowerReset` (`$8539`)

**Power = 0 and the bar erased**

B = the old Power for `$935C` (the bar), Power and PowerHigh = 0. Called by StartAim (w1 27).

| | |
| --- | --- |
| Runs (the first recording's game window) | 7 calls, 371 t-states own (0.00 %) |
| Called from | `StartAim`, `TurnSwap` |
| Calls | `DrawPowerBar` (tail) |
| Reads | `$86BF` (`DrawList`) |
| Writes | `$86BF`-`$86C0` (`DrawList`) |

### `AimCursorMove` (`$8546`)

**The cursor task: the direction and speed from the controls**

Task of AimTasks and of the editor (w1 4404 runs). When InputState changed since CursorLastInput: right (bit 0) gives +1 on the upper half (CursorY < `$72`) and -1 on the lower; left the opposite; up (bit 2) +1 on the left half (CursorX < `$80`), down +1 on the right half; no direction: speed 0. A new direction against the current sign restarts at +-1; the same one keeps accelerating (AimCursorAccel): every 10 counts of CursorAccel, |speed| + 1 up to 6.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 147,961 t-states own (0.05 %) |
| Called from | `CallTask` |
| Reads | `$827C` (`InputState`); `$86BA`-`$86BE` (`DrawList`) |
| Writes | `$86BC`-`$86BE` (`DrawList`) |

### `AimCursorReset` (`$85C8`)

**The cursor back to the right cushion, a little at random, and drawn**

InputState and CursorLastInput = 0; CursorX = 252, CursorY = 115, or 114 / 116 by bits 6 and 0 of the R register; speed 0; draws the cursor (`$9371` XOR). Called by StartAim (w1 21).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 498 t-states own (0.00 %) |
| Called from | `StartAim` |
| Calls | `DrawCursor` (tail) |
| Writes | `$827C` (`InputState`); `$86BA`-`$86BE` (`DrawList`) |

### `AimCursorDraw` (`$85EB`)

**The cursor draw task: move the cursor round the cushions by its speed**

Task of AimTasks and the editor (w1 4424 runs). Speed 0: nothing. Else erases the cursor (`$9371`), turns (CursorX, CursorY) into the perimeter coordinate HL, adds the signed speed modulo 756 (`$2F4`) and turns HL back; the return goes to `$9371`, which draws it at the new place.

[Animation: `AimCursorDraw` at work](img/routines/AimCursorDraw.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 131,154 t-states own (0.04 %) |
| Called from | `CallTask` |
| Calls | `DrawCursor` |
| Reads | `$86BA`-`$86BC` (`DrawList`) |
| Writes | `$86BA`-`$86BB` (`DrawList`) |

## physics

`src/game/physics.asm`

### `PhysicsTask` (`$86C1`)

**The physics task: move every rolling ball one tick**

A task of the list `$84BA` (the balls moving, period 0) and of the editor's list `$C518`, reached through the scheduler's JP (HL), so no CALL counts it: the first instruction ran game 290, w1 2860, f1 742, p2 1180, v1 822, m1 313 times (frames game 6447-8658, w1 1085-11615).

Clears EventCount `$8B4D`, then for each of the seven records (IX from BallRecords `$8A88`, 14 bytes a step, B = 7..1) calls MoveBall `$8701` when +13 has bit 7 (on the table) and bit 6 (moving) set and bit 5 (potted) clear: 2030 records looked at and 286 moves in game, 20020 / 5644 in w1.

Then advances FrictionTurn `$8B4C` (0..6, wrapping: `$86F2` ran 41 of 290 times in game, 398 of 2860 in w1), so each ball gets its friction steps recomputed once in seven ticks. If EventCount reached 7 the whole pass runs again (`$86FB`); no recording took that jump (the counts of `$86C1` and `$86FD` are equal in every build). Ends with CALL `$8304`.

In w1 the break has 159 physics ticks in the 168 video frames 1085-1252: tick 1 runs at the end of the shot set-up's interrupt (entered at 1079, ends in 1085); nine interrupts are lost, video frames 1155, 1157, ..., 1171, while all seven balls roll (ticks 70-78): each such pass runs past the next INT (work/docs/vpD/w1-sound.json irq; docs 10.1). The samples 1156, 1158, ..., 1172 repeat the one before (tools/physics_model.py).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 248,181 t-states own (0.08 %) |
| Called from | `CallTask` |
| Calls | `BuildDrawList`, `MoveBall` |
| Reads | `$8A95`-`$8AE9` (`BallRecords`); `$8B4C`-`$8B4D` (`FrictionTurn`, `EventCount`) |
| Writes | `$8B4C`-`$8B4D` (`FrictionTurn`, `EventCount`) |

### `MoveBall` (`$8701`)

**One tick of one ball: move, collide, pocket or bounce, friction, redraw flag**

Input IX = the ball's record, B = 7 - the ball number (0 cue, 1-6); called by PhysicsTask `$86C1` (and from the editor `$C20B`, a path m1 never took). Runs game 286, w1 5644, f1 1574, p2 3850, v1 2299, m1 970 times.

1. When FrictionTurn `$8B4C` = B - 1 the friction steps are recomputed first (FrictionSteps `$90F5`): one ball a tick in turn.

2. x += vx, y += vy (16-bit 8.8 adds). x is clamped to `$0700`..`$F800` (7.0..248.0) with the carry of the add caught (a wrap past 0 or `$FFFF` goes to the limit); y to `$3700`..`$B000` (55.0..176.0), the low side without the carry test. The clamps fired w1 7 / 9, f1 1 / 2, p2 2 / 0, v1 2 / 2 times (`$8738` / `$8768`); the limits lie past the pocket line, so a clamped ball is potted in the same move.

3. Clears +13 bit 4, then BallContacts `$87EF` (ball against ball) and PocketOrCushion `$8B4E` (A = the ball number).

4. Friction: vx += the sign-extended +8, vy += +9; if the sum crosses zero the component becomes 0 (`$8795`: w1 61, `$87B9`: w1 58 times). Both components 0: +13 bit 6 cleared, the ball stops (`$87D2`: game 4, w1 53).

5. Redraw flag: +13 bit 4 is set unless the pixel x, y equal +10, +11. Those hold the sprite's corner (x - 7, y - 7), so the test can only match after a 7-pixel jump; in every build `$87EA` (set) ran exactly as often as `$87DB` (the test reached), so every moving ball is redrawn every tick.

[Animation: `MoveBall` at work](img/routines/MoveBall.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 286 calls, 294,928 t-states own (0.10 %) |
| Called from | `PhysicsTask` |
| Calls | `BallContacts`, `PocketOrCushion`, `FrictionSteps` |
| Reads | `$8A88`-`$8A95` (`BallRecords`); `$8B4C` (`FrictionTurn`) |
| Writes | `$8A88`-`$8A95` (`BallRecords`) |

### `BallContacts` (`$87EF`)

**Ball against ball: find a touching ball, step back onto the contact ring, exchange velocities**

Input IX = the moving ball. Runs as often as MoveBall (game 286, w1 5644). For every record IY on the table (7 looked at, the ball itself included; it and any ball on the same pixel are skipped by dx = dy = 0): whole-pixel |dx|, |dy| (the +1, +3 bytes) both below 16, then ContactTable `$DBFA`[16 |dy| + |dx|]. A negative entry (`$80`) means overlap (w1 201, f1 55, p2 124, v1 80, m1 47 times, `$8833`); 0 (apart) and a ring entry without overlap are no contact (RET P).

On overlap: StepBack `$8E33` moves IX back along its own velocity by less than a pixel and the table is read again until the entry is no longer negative; ContactSigns `$89B5` = 2 (dx < 0) + (dy < 0) with dx = IX - IY. The entry n (1..31) selects CollisionRecords `$DE3A` + 6 (n - 1), kept in ContactRecordPtr `$89B7` with IY in ContactOther `$89B9`; the loop goes on, so the last touching ball wins. The ring entry was found w1 71, f1 28, p2 49, v1 32, m1 17 times; game (c1, a game of fouls) never had a ball hit.

The exchange (`$889C`) runs if the ball moves towards the other in x or y (sign of dx against the sign of vx, the same for y); it always did when a contact was found (the JP P to `$89AA` never taken). With dv = v(IY) - v(IX) and the record's w0 = nx^2, w1 = ny^2, w2 = |nx ny|: A = w0 dvx, B = w2 dvy, C = w2 dvx, D = w1 dvy (ScaleVelocity `$89C4`, 4 calls a contact). The sign s of nx ny is + when dx and dy have the same sign (ContactSigns 0 or 3), - otherwise. IX.v += (A + sB, D + sC); IY.v -= the same. The other ball is set moving (+13 bit 6), BallHitFlag `$89BB` = 1, the sound request `$827D` = 1, EventCount += 2, and both balls get new friction steps (FrictionSteps `$90F5` twice).

Finally the moving ball's fractions are set to `$80` (the centre of its pixel), also when it was moving away.

[Animation: `BallContacts` at work](img/routines/BallContacts.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 286 calls, 411,554 t-states own (0.14 %) |
| Called from | `MoveBall` |
| Reads | `$89B8`-`$89BA` (`ContactVars`); `$8A89`-`$8AE9` (`BallRecords`) |
| Writes | `$89B8` (`ContactVars`) |

### `ScaleVelocity` (`$89C4`)

**HL = DE x the coefficient HL (0.8 fixed point, `$0100` = 1.0), signed**

Input HL = a coefficient of a collision record (H = 1: exactly 1.0, else 0 and L the fraction), DE = a signed 8.8 velocity; output HL = the product, 8.8 signed; uses A, BC, DE. Coefficient 1.0 returns DE at once (`$89C7`: 24 of 284 calls in w1). Otherwise |DE| is formed, the fraction times the low byte (MulByte `$89F5`) rounded to its high byte, plus the fraction times the high byte, and the sign put back. Runs only on contacts: w1 284, f1 112, p2 196, v1 124, m1 68 calls (4 a contact), never in game.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MulByte` (`$89F5`)

**HL += A x DE, 8 bits of A from bit 0**

Shift-and-add: eight steps, A rotated right, DE added when the bit is set, DE doubled each step. Called twice by ScaleVelocity `$89C4` (w1 520 calls).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## shotsetup

`src/game/shotsetup.asm`

### `AimShot` (`$8A02`)

**The shot: the cue ball's velocity from the cursor, the cue ball and the power**

Called by the power task `$8506` when the shot is played: game 4, w1 21, f1 9, p2 6, v1 4, m1 1 times (one a shot; frames game 6441-8491, w1 1079-11557). IY = `$5C3A`, I = `$3F`, SET-MIN clears the calculator stack. Stacks the cursor x CursorX `$86BA` and the cue ball's pixel x `$8A89` (STACK-A, whole pixels: the fractions are not used) and runs AimCalcDx `$8A1A`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 472 t-states own (0.00 %) |
| Called from | `AimPower` |
| Reads | `$86BA` (`DrawList`); `$8A89` (`BallRecords`) |

### `AimStackDy` (`$8A1F`)

**Stack the cursor y and the cue ball's y, then r and dy / r**

The calculator returns here. Stacks CursorY `$86BB` and the cue ball's pixel y `$8A8B`, runs AimCalcDyOverR `$8A2D`.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 312 t-states own (0.00 %) |
| Reads | `$86BA`-`$86BB` (`DrawList`); `$8A8B` (`BallRecords`) |

### `AimStoreVy` (`$8A3D`)

**vy = ScaleByPower (dy / r), then dx / r**

Stores BC from ScaleByPower `$8A5D` in the cue ball's vy `$8A8E`, then runs AimCalcDxOverR `$8A45`.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 192 t-states own (0.00 %) |
| Calls | `ScaleByPower` |
| Writes | `$8A8E`-`$8A8F` (`BallRecords`) |

### `AimStoreVx` (`$8A47`)

**vx = ScaleByPower (dx / r); the cue ball moves**

Stores BC in the cue ball's vx `$8A8C`, sets its +13 bit 6 (moving), I = `$FE` (the game's IM 2 table again), and jumps to FrictionSteps `$90F5` with IX = the cue ball.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 400 t-states own (0.00 %) |
| Calls | `ScaleByPower`, `FrictionSteps` (tail) |
| Reads | `$8A95` (`BallRecords`) |
| Writes | `$8A8C`-`$8A95` (`BallRecords`) |

### `ScaleByPower` (`$8A5D`)

**BC = 16 P x the top of the calculator stack, as a 16-bit two's complement 8.8**

P = Power `$86BF`, values of `$80` and more taken as `$7E` (the power only grows in steps of 2, so at most 126); BC = 16 P (2 P shifted 3 times) stacked by STACK-BC, then ScaleByPowerCalc `$8A7A`, then FP-TO-BC through ScaleToBC `$8A85`. Runs twice a shot (game 8, w1 42).

| | |
| --- | --- |
| Runs (the first recording's game window) | 8 calls, 984 t-states own (0.00 %) |
| Called from | `AimStoreVy`, `AimStoreVx` |
| Reads | `$86BF` (`DrawList`) |

### `ScaleToBC` (`$8A85`)

**JP FP-TO-BC: the value off the calculator stack into BC**

Jumps to the ROM's FP-TO-BC `$2DA2`, which returns to AimStoreVy `$8A3D` or AimStoreVx `$8A47`.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 80 t-states own (0.00 %) |

## cushions

`src/game/cushions.asm`

### `PocketOrCushion` (`$8B4E`)

**Pot a ball that left the playing area, else the cushion tests for the pocket size**

Input IX = the ball, A = the ball number (0 cue, 1-6); runs once a move (game 286, w1 5644). Restores DiagonalJaw's shallow exit (`$8C92` = RET C, NOP). Inside x 8..247, y 56..175 (`$08` <= x < `$F8`, `$38` <= y < `$B0`): CushionsBySize `$8C74`.

Outside, the ball is potted (`$8B71`: w1 18, f1 3, p2 2, v1 5, never in game or m1): x and y are clamped into the pocket's box, by the column (x < 64, < 192, else) and the row (y < 115 top, else bottom): large boxes x 8-15, 122-133, 240-247 and y 56-63, 168-175; small x 8-11, 125-130, 244-247 and y 56-59, 172-175; fractions 0. +12 = the pocket number (columns 1-3 on the top row, 7 minus that on the bottom: 4 right, 5 middle, 6 left), +13 bits 5 and 4 set and 6 cleared, the sound request `$827D` = 3.

Fouls of the variations (an object ball, FoulCode `$8E80` still 0, the cue ball on the table, variation `$B8C3` not 0): variation 1 (`$8C4B`) sets FoulCode = 2 if a lower-numbered ball is still on the table (v1, 2 times); variation 2 sets FoulCode = 3 unless the pocket + `$9F43` (mod 6, 1-6) is the ball's number (`$8C43`, v1 2 times).

[Animation: `PocketOrCushion` at work](img/routines/PocketOrCushion.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 286 calls, 41,470 t-states own (0.01 %) |
| Called from | `MoveBall` |
| Calls | `CushionsBySize` (tail) |
| Reads | `$8A89`-`$8A8B` (`BallRecords`) |
| Writes | `$8C92`-`$8C93` (`DiagonalJaw`) |

### `CushionsBySize` (`$8C74`)

**The cushion tests of the pocket size: `$B8BC` = 0 small, else large**

Runs on every move inside the playing area: CushionsLarge `$8FBB` in game 286, w1 5626, f1 1571, p2 3848, v1 2294 (the image's `$B8BC` = 1); CushionsSmall `$8E81` only in m1 (970, the small-pockets option).

| | |
| --- | --- |
| Runs (the first recording's game window) | 286 calls, 7,722 t-states own (0.00 %) |
| Called from | `PocketOrCushion` (tail) |
| Calls | `CushionsLarge` (tail) |
| Reads | `$B8BC` (`Players`) |

### `DiagonalJaw` (`$8C7E`)

**A corner pocket's 45-degree jaw: A = the offset from the diagonal (carry = negative), BC = the wall's normal signs**

Entered by JP from the corner tests of CushionsSmall `$8E81` / CushionsLarge `$8FBB` with A = the signed offset of the ball from the pocket's diagonal (carry set when negative), C / B = `$00` or `$FF` for the x / y sign of the wall's normal, HL = the test to repeat. A negative offset is negated and B, C complemented. Offset 2-3 (small) or 6-7 (large): JawContact. Less: inside the channel, no bounce (RET C at `$8C92`). More: the ball went too deep: `$8C92` is patched to JR C,JawContact and StepBack `$8E33` runs with HL pushed as its return, so the test repeats from the cushion test until the offset is within the band. Entered w1 43, f1 46, p2 20, v1 31 times; the deep case `$8C94` w1 7, f1 4, v1 6.

JawContact: if the ball moves into the wall in x and in y (`$8CE4`), or in the one axis whose speed is the larger (|vx| against |vy|, `$8CB5`), the fractions are set to C, B and ReflectDiagonal `$8D7D` swaps the components; else (`$8CED`) the fractions are set to the complements and no bounce.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PointJaw` (`$8CF8`)

**A middle pocket's jaw point (C, B): the radius test of Table8x8, step back, bounce**

Input IX, C / B = the jaw point's x / y (`$73` or `$76`, `$8C` or `$89`; `$3A` or `$AD`); entered from the middle-cushion tests. |dx| < 8 and |dy| < 8, and not |dx| = |dy| >= 5, else no contact; then Table8x8 `$DCFA`[8 |dy| + |dx|]: 0 apart, `$80` overlap (StepBack `$8E33` and look again, `$8D26`: w1 1, v1 9), 1 touching. Entered w1 7, v1 3, m1 8 times.

The bounce uses bit 7 of the point's coordinates in place of the normal's signs (C xor vx, B xor vy, as DiagonalJaw does with its signs): moving into the point in both axes, the fractions set from the position's sign and ReflectDiagonal `$8D7D`; in x only, ReflectX `$8DCB`; in y only, ReflectY `$8DFF`; moving away, nothing.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReflectDiagonal` (`$8D7D`)

**The bounce off a 45-degree wall: swap vx and vy (and the friction steps), negated when B xor C is positive**

Ran w1 10, f1 7, p2 1, v1 5, m1 2 times. (vx, vy, step x, step y) become (vy, vx, step y, step x), all four negated when the normal's signs B and C are equal (`$8D95`: w1 4, v1 5, m1 1). Sound request `$827D` = 2, EventCount `$8B4D` + 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReflectX` (`$8DCB`)

**The bounce off a side cushion: vx and the x friction step negated**

vx = -vx (NEG / CPL with the carry: a 16-bit negate), +8 negated, the x fraction set to `$00` or `$FF` by the sign of the x pixel byte (bit 7: right half `$FF`); sound request `$827D` = 2, EventCount `$8B4D` + 1. Ran game 1, w1 31, f1 11, p2 24, v1 14, m1 7 times.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 264 t-states own (0.00 %) |
| Called from | `CushionsLarge` (tail) |
| Reads | `$8A89`-`$8A90` (`BallRecords`); `$8B4D` (`EventCount`) |
| Writes | `$827D` (`SoundRequest`); `$8A88`-`$8A90` (`BallRecords`); `$8B4D` (`EventCount`) |

### `ReflectY` (`$8DFF`)

**The bounce off a top or bottom cushion: vy and the y friction step negated**

As ReflectX `$8DCB` for y: vy, +9 negated, the y fraction `$00` or `$FF` by bit 7 of the y pixel; sound 2, EventCount + 1. Ran game 1, w1 48, f1 9, p2 39, v1 19, m1 8 times.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 264 t-states own (0.00 %) |
| Called from | `CushionsLarge` (tail) |
| Reads | `$8A8B`-`$8A91` (`BallRecords`); `$8B4D` (`EventCount`) |
| Writes | `$827D` (`SoundRequest`); `$8A8A`-`$8A91` (`BallRecords`); `$8B4D` (`EventCount`) |

### `StepBack` (`$8E33`)

**Move the ball back along its velocity by less than one pixel**

Input IX. Copies vx, vy, halves both (arithmetic shifts) until each lies in -255..255 / 256 (high byte 0, or `$FF` with a non-zero low byte), then subtracts them from x and y. Called by BallContacts `$87EF`, DiagonalJaw `$8C7E`, PointJaw `$8CF8` and the cushion tests: game 2, w1 401, f1 106, p2 281, v1 173, m1 79 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 892 t-states own (0.00 %) |
| Called from | `CushionsLarge` |
| Reads | `$8A88`-`$8A8F` (`BallRecords`) |
| Writes | `$8A88`-`$8A8B` (`BallRecords`) |

### `CushionsSmall` (`$8E81`)

**The cushions and the pocket mouths for small pockets**

Patches DiagonalJaw's depth band to 2-3 (`$8C8B` = 2, `$8C8F` = 3), then by x: x >= 239 the right end, x < 17 the left end, else the long cushions. Ends: the straight cushion (y 67..163) reflects vx once x is back within 17..238; above y 67 / below y 164 a corner pocket: DiagonalJaw on y - x = 48 / x + y = 183 (left) or x + y = 303 / x - y = 72 (right). Long cushions: y < 65 the top, y >= 167 the bottom, else free. On those: x < 19 or x >= 236 back to the ends; x 125..130 the pocket channel (no test); x 118..124 and 131..137 the jaw zone: PointJaw at (118 or 137, 58 / 173) until the ball is past the face, then x = 125.0 / 130.996 and ReflectX (the channel walls); elsewhere the straight cushion: step back to y = 65 / 166 and ReflectY. Only m1 (small pockets) ran it: 970 times, frames 7430-7745.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CushionsLarge` (`$8FBB`)

**The cushions and the pocket mouths for large pockets (the default)**

As CushionsSmall `$8E81` with the large geometry: the band 6-7 (`$8C8B` = 6, `$8C8F` = 7), the corner zones above y 71 and below y 160, the long cushions' ends at x 23 / 232, the middle channel x 122..133 with the walls 122.0 / 133.996, the jaw zones x 115..121 and 134..140 with the jaw points (115 or 140, 58 / 173). The same cushion lines x 17 / 238, y 65 / 166. Ran game 286, w1 5626, f1 1571, p2 3848, v1 2294 times; the straight-cushion bounces are the bulk of ReflectX / ReflectY.

| | |
| --- | --- |
| Runs (the first recording's game window) | 286 calls, 40,890 t-states own (0.01 %) |
| Called from | `CushionsBySize` (tail) |
| Calls | `ReflectX` (tail), `ReflectY` (tail), `StepBack` |
| Reads | `$8A89`-`$8A8B` (`BallRecords`) |
| Writes | `$8C8B`-`$8C8F` (`DiagonalJaw`) |

## friction

`src/game/friction.asm`

### `FrictionSteps` (`$90F5`)

**The friction steps +8 / +9 of the ball IX from the direction of its velocity**

|vx| and |vy| (AbsHL `$914A`) are shifted left together, at most 8 times, until bit 3 of either high byte is set: two 4-bit numbers in the ratio of the components (high nibbles of the 8.8 values after normalising; small speeds use the shifted-up low bytes). FrictionTable `$DD3A`[16 ny + nx]: the low nibble is the x step, the high nibble the y step, each negated when its velocity component is positive, so the step opposes the motion (0 for a zero component). Speeds over 15 pixels a tick would lose their top bits; the shot gives at most 7.9.

Called by MoveBall `$8701` (one ball a tick in turn), BallContacts `$87EF` (both balls after a contact) and AimStoreVx `$8A47` (the shot): game 42, w1 960, f1 284, p2 655, v1 392, m1 174 calls, frames game 6447-8651.

| | |
| --- | --- |
| Runs (the first recording's game window) | 42 calls, 27,710 t-states own (0.01 %) |
| Called from | `MoveBall`, `AimStoreVx` (tail) |
| Calls | `AimPower`, `AbsHL` |
| Reads | `$8A8C`-`$8A8F` (`BallRecords`); `$DD42` (`FrictionTable`); `$DD62` (`FrictionTable`); `$DD73`-`$DE09` (`FrictionTable`); `$DE1D` (`FrictionTable`) |
| Writes | `$8A90`-`$8A91` (`BallRecords`) |

### `AbsHL` (`$914A`)

**HL = |HL|**

Two's complement negate when bit 7 of H is set. Called twice by FrictionSteps `$90F5` (game 84, w1 1920).

| | |
| --- | --- |
| Runs (the first recording's game window) | 84 calls, 2,310 t-states own (0.00 %) |
| Called from | `FrictionSteps` |

## scheduler

`src/game/scheduler.asm`

### `RunTasks` (`$9155`)

**The scheduler: count each slot down, call the routines whose time has come**

Called by Im2Handler on every interrupt (w1 9536 entries). Each of the 25 slots of TaskSlots: skip if free; count +3 down; at -1 call the routine (CallTask, JP (HL)) and reload +3 from +2. Tasks run in slot order (the order they were added). w1: 34 301 task calls.

[Animation: `RunTasks` at work](img/routines/RunTasks.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,577 calls, 7,334,323 t-states own (2.47 %) |
| Called from | `Im2Handler`, `AimPower` |
| Calls | `Im2Handler`, `CallTask` |
| Reads | `$91DF`-`$9240` (`TaskSlots`) |
| Writes | `$91E2`-`$91FE` (`TaskSlots`) |

### `CallTask` (`$9187`)

**JP (HL)**

| | |
| --- | --- |
| Runs (the first recording's game window) | 8,587 calls, 34,348 t-states own (0.01 %) |
| Called from | `RunTasks` |
| Calls | `ReadInput`, `BallRedraw`, `ShotEnd`, `AimPower`, `AimCursorMove`, `AimCursorDraw`, `PhysicsTask`, `PowerBarTask`, `UpBlinkTask`, `ShotsBlinkTask`, `LastShotBeepTask`, `MessagesTask` |

### `AddTask` (`$9188`)

**Put routine HL with period C into the first free slot**

Countdown 0, so it first runs at the scheduler's next visit of its slot: in the same tick when the slot comes after the caller's (the release: MovingTasks in slots 1-3 run in AimPower's tick), otherwise at the next tick. No free slot: nothing (25 are never all used). w1: 252 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 48 calls, 18,104 t-states own (0.01 %) |
| Called from | `InstallTasks`, `StartAim` (tail) |
| Reads | `$91E0`-`$91FC` (`TaskSlots`) |
| Writes | `$91DF`-`$91FE` (`TaskSlots`) |

### `RemoveTask` (`$91AD`)

**Free the slot of routine HL**

The first slot whose address is HL gets high byte 0. w1: 252 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 48 calls, 17,368 t-states own (0.01 %) |
| Called from | `RemoveTasks`, `StopShotTasks`, `AimPower` |
| Reads | `$91DF`-`$91FC` (`TaskSlots`) |
| Writes | `$91E0`-`$91FC` (`TaskSlots`) |

### `ClearTasks` (`$91CF`)

**Free all 25 slots (DI while it clears)**

Called by BreakRestart (one a BREAK) and by the editor. Zeros the 100 bytes of TaskSlots.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 2,132 t-states own (0.00 %) |
| Called from | `BreakRestart` |
| Reads | `$91DF`-`$9241` (`TaskSlots`) |
| Writes | `$91DF`-`$9242` (`TaskSlots`) |

## tabledraw

`src/game/tabledraw.asm`

### `DrawTable` (`$9243`)

**Draw the table: the outer frame and the six cushions, with gaps for the six pockets**

Called by NewGameScreen `$95DA` and the editor `$C042`, once each (game 1 at frame 6186, w1 1 at 626, v1 2, m1 2). Every run is a call of XorLine `$93B3` with D = y, E = x, B = length.

The frame: the top line y 48 and the bottom line y 183, x 0-255 (two runs of 128 each); the left edge x 0 and the right edge x 255, y 49-182 (134 one-pixel runs each).

The four long cushions, 9 lines each, sloped at 45 degrees on their pocket side: top left y 49-57 from x 15+i to 117, top right from x 138 to 240-i (i = 0..8 the line); bottom left and bottom right the same mirrored, y 182 up to 174. The two side cushions: x 1-9 at the left and x 246-254 at the right, a 9-line slope in (y 63-71, run 1..9), 88 straight lines (y 72-159), a 9-line slope out (y 160-168).

Large pockets (`$B8BC` <> 0, the menu's L key; the default in the image): the long cushions start 4 pixels later and run 96 pixels (x 19+i..114, 141..236-i), the side cushions start at y 67 and run 80 straight lines. Small pockets (`$B8BC` = 0, the S key, m1 frame 7110): the numbers above. The gaps left are the pockets: the four corners and the middle of the top and bottom (x 118-137 small, 115-140 large).

[Animation: `DrawTable` at work](img/routines/DrawTable.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 19,520 t-states own (0.01 %) |
| Called from | `NewGameScreen` |
| Calls | `XorLine` |
| Reads | `$B8BC` (`Players`) |

### `PowerBarTask` (`$934D`)

**The aim list's power bar task: erase the bar drawn last frame, draw the bar for the power now**

A task of the aim list `$84AA`, period 0 (every interrupt while aiming): game 1443 runs, w1 4404, f1 2035, p2 1369, v1 846, m1 316 (also the editor's list `$C518`). `$86BF` is the power (grown by `$8506` while fire is held), `$86C0` the length drawn last time: DrawPowerBar `$935C` with B = `$86C0` (XOR: erases), then with B = `$86BF` (draws), then `$86C0` = `$86BF`. A power of 0 draws nothing (XorLine returns on B = 0).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 111,111 t-states own (0.04 %) |
| Called from | `CallTask` |
| Calls | `DrawPowerBar` |
| Reads | `$86BF`-`$86C0` (`DrawList`) |
| Writes | `$86BF`-`$86C0` (`DrawList`) |

### `DrawPowerBar` (`$935C`)

**XOR the power bar: 4 lines of B pixels (capped at 126) from x 4, y 10-13**

Input B = the length. Lengths of 128 and more are drawn as 126 (the power runs 0..`$84`, so the last three steps `$80`, `$82`, `$84` look full). The bar lies inside PowerBox `$9395` (x 2-131, y 8-15). Called by PowerBarTask `$934D` twice a frame (game 2893) and by `$8539`, which erases the bar and zeroes the power at each new aim.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,893 calls, 569,933 t-states own (0.19 %) |
| Called from | `AimPowerReset` (tail), `PowerBarTask` |
| Calls | `XorLine` |

### `DrawCursor` (`$9371`)

**XOR the aiming cursor at (`$86BA` x, `$86BB` y): a cross of four 2-pixel arms, the centre left clear**

Pixels: (x+1, x+2 at y), (x-2, x-1 at y), (x at y-2, y-1, y+1, y+2); the centre (x, y) is never set, so the point aimed at stays visible. Drawn twice it erases: the cursor tasks `$85EB` (draw, move, draw), `$8506` (erase on the shot), `$85C8` (first draw at a new aim, x 252, y 114-116 at random) and the editor (`$C042`, `$C116`, `$C20B`, `$C414`, `$C502`, `$C532`). Counts: game 388, w1 1930, f1 122, p2 43, v1 46, m1 244.

| | |
| --- | --- |
| Runs (the first recording's game window) | 388 calls, 68,288 t-states own (0.02 %) |
| Called from | `AimPower`, `AimCursorReset` (tail), `AimCursorDraw` |
| Calls | `XorLine` (tail) |
| Reads | `$86BA`-`$86BB` (`DrawList`) |

### `DrawPowerBox` (`$9395`)

**Draw the power bar's box: a rectangle x 2-131, y 8-15**

The top y 8 and the bottom y 15, 130 pixels from x 2; the sides one pixel at x 2 and x 131 for y 9-14. Once a game (NewGameScreen `$95DA`, game 1 at frame 6185) and in the editor (`$C414`, v1 2).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 464 t-states own (0.00 %) |
| Called from | `NewGameScreen` |
| Calls | `XorLine` |

### `XorLine` (`$93B3`)

**XOR a horizontal run of B pixels starting at (x E, y D) onto the screen; B = 0 draws nothing**

Inputs D = y, E = x, B = length in pixels (up to 255). Keeps BC, DE; HL and A spoiled. The address: ScreenCell `$95B3` of (y, x) plus y AND 7 in the high byte. The first byte's mask: B ones from bit 7 (or `$FF` when B >= 8), shifted right by x AND 7, the bits shifted out counted back into B; then whole bytes XOR `$FF` while 8 or more remain, then a last mask of the remaining B bits from the left. The run must not cross a byte column 31 boundary (INC HL).

The busiest drawing routine: game 14976 calls, w1 57235, f1 17840, p2 12040, v1 8432, m1 28297; callers also outside this range (`$A95A`, `$A990`, `$AB7B` hall of fame, `$B047`, `$B101`, `$B89C` menu, `$BC11` attract, `$C1BE` editor).

| | |
| --- | --- |
| Runs (the first recording's game window) | 14,976 calls, 2,105,292 t-states own (0.71 %) |
| Called from | `DrawTable`, `DrawPowerBar`, `DrawCursor` (tail), `DrawPowerBox`, `XorTick`, `FlipEdge` |
| Calls | `ScreenCell` |
| Reads | `$4020`-`$50A0` (screen); `$50BF`-`$52A0` (screen); `$52BF`-`$57DF` (screen); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4020`-`$50A0` (screen); `$50BF`-`$57DF` (screen); `$CFE8`-`$CFF9` (`StackSpace`) |

## balldraw

`src/game/balldraw.asm`

### `RespotCueBall` (`$93FF`)

**Put the cue ball back at (40, 115), or right of it until no ball is within 16 pixels, and draw it**

Called by the end-of-shot task `$8357` when the cue ball was potted, by NextTurn `$97CD` (`$981F`) and by the editor `$C042`. f1 ran it once (frame 1173, after the cue ball went down). Zeroes the cue ball's velocity and friction steps (+4..+9), flags +13 = `$80` (on the table), x = 40 / y = 115 with zero fractions. For each object ball on the table with |dx| < 16 and |dy| < 16 it moves x one pixel right and starts again, up to x 200. Then SpritePos = (x-7, y-7) (also +10/+11) and DrawBall ball 0.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearTableForTurn` (`$947D`)

**Before the turn passes: XOR off every ball outside the middle of the table, then clear the middle (x 16-239, y 64-167)**

Called by TurnSwap `$9C15` (p2 once, frame 1778). Ball 0..6: a ball whose sprite lies inside x 16-223, y 64-150 (+10, +11) is left (the block clear wipes it); every other ball is XOR-erased at its +10/+11: the balls near the cushions and the potted row (bit 7 of +13 clear). The cue ball is skipped when it is off the table (it has no image then). Then 13 character rows x 28 bytes from (y 64, x 16) are zeroed (pixels only; the attributes stay).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearMessageRows` (`$94EB`)

**Clear character rows 2-4 (y 16-39): pixels zero, attributes `$39`**

The message area under the HUD: the foul texts and the score tally print at row 3, and the potted row (balls at y 20-34) lies here too, so the caller redraws it after (DrawPottedRow `$9AB5`). Called by MessagesTask `$9CB7` (steps 1 and `$4E`) and ScoreTally `$98FF`: game 8, w1 43, f1 9, p2 6, v1 15.

| | |
| --- | --- |
| Runs (the first recording's game window) | 8 calls, 184,985 t-states own (0.06 %) |
| Called from | `MessagesTask` (tail) |
| Calls | `ScreenCell`, `AttrFromScreen`, `MessagesTask` |
| Reads | `$4040`-`$409E` (screen); `$4140`-`$419E` (screen); `$4240`-`$429E` (screen); `$4340`-`$439E` (screen); `$4440`-`$449E` (screen); `$4540`-`$459E` (screen); 3 more ranges |
| Writes | `$4040`-`$409F` (screen); `$4140`-`$419F` (screen); `$4240`-`$429F` (screen); `$4340`-`$439F` (screen); `$4440`-`$449F` (screen); `$4540`-`$459F` (screen); 3 more ranges |

### `DrawAllBalls` (`$9520`)

**XOR every numbered ball at its +10/+11 and the cue ball when it is on the table**

Balls 1-6 are drawn whatever their flags (on the table, or in the potted row); the cue ball only with bit 7 of +13 set. Called at a new game (`$8013`), by NextTurn `$97CD` and the editor (`$C042`, `$C532`): game 1 at frame 6190, p2 2 (690, 1780).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 1,117 t-states own (0.00 %) |
| Called from | `GameRestart` |
| Calls | `DrawBall` |
| Reads | `$8A95`-`$8AE7` (`BallRecords`) |
| Writes | `$95D8`-`$95D9` (`SpritePos`) |

### `DrawBall` (`$9548`)

**XOR ball A's sprite (0 cue, 1-6) at SpritePos `$95D8` (x, y of the sprite's top left)**

Input A = the ball 0-6, SpritePos = (x, y). Source = BallSprites `$D000` + 48 x (7 x (x AND 7) + A): BC = 48A, HL = 336 (x AND 7), the sum plus `$D000` into DE. Target: ScreenCell `$95B3` of (y, x) plus y AND 7 lines. A screen character row holds 8 lines, so the 16 lines go in three parts through XorSpriteLines `$959F`: 8 - (y AND 7) lines, then 8 lines from the next character row (y + 8), then (y AND 7) - 1 lines from the row after (y + 16): 16 lines when y AND 7 = 0, else 15; the 16th line of every sprite is zero, so nothing is lost and a second draw always erases exactly.

1827 calls in game, w1 15290, f1 4407, p2 10210, v1 7119, m1 3193; callers: the ball redraw task `$8297`, `$8357`, RespotCueBall `$93FF`, ClearTableForTurn `$947D`, DrawAllBalls `$9520`, LoseLife `$9754`, EraseBallsUnderBanner `$98B5`, DrawPottedRow `$9AB5`, DrawLives `$9AD9`, Rack `$9F6F`, the editor `$C20B`.

[Animation: `DrawBall` at work](img/routines/DrawBall.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,827 calls, 740,491 t-states own (0.25 %) |
| Called from | `RedrawBall` (tail), `DrawAllBalls`, `LoseLife`, `DrawLives`, `RackBalls` |
| Calls | `XorSpriteLines`, `ScreenCell` |
| Reads | `$95D8`-`$95D9` (`SpritePos`) |

### `XorSpriteLines` (`$959F`)

**XOR B lines of 3 bytes from DE onto the screen at HL (INC H a line: within one character row)**

DE advances 3 bytes a line (the sprite is stored line by line, 3 bytes each); L goes +1, +1, -2, H + 1. 27602 calls in game (5230 DrawBall calls), w1 230986.

| | |
| --- | --- |
| Runs (the first recording's game window) | 5,230 calls, 3,209,942 t-states own (1.08 %) |
| Called from | `DrawBall` |
| Reads | `$4060`-`$51C2` (screen); `$5204`-`$52C2` (screen); `$5304`-`$53C2` (screen); `$5404`-`$54C2` (screen); `$5504`-`$55C2` (screen); `$5604`-`$56C2` (screen); 5 more ranges |
| Writes | `$4060`-`$51C2` (screen); `$5204`-`$52C2` (screen); `$5304`-`$53C2` (screen); `$5404`-`$54C2` (screen); `$5504`-`$55C2` (screen); `$5604`-`$56C2` (screen); 1 more ranges |

### `ScreenCell` (`$95B3`)

**HL = the display address of the character cell holding pixel (x L, y H): line 0 of that cell**

H = `$40` + 8 x (y / 64), L = 32 x ((y / 8) AND 7) + x / 8. The caller adds y AND 7 to H for the exact line. Used by XorLine, DrawBall, ClearTableForTurn, ClearMessageRows and the hall of fame (`$A9CC`, `$AA74`, `$AABD`, `$AB7B`, `$ABC3`) and `$B118`: game 9793 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 9,793 calls, 1,047,883 t-states own (0.35 %) |
| Called from | `XorLine`, `ClearMessageRows`, `DrawBall` |
| Reads | `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CFEC`-`$CFF5` (`StackSpace`) |

### `AttrFromScreen` (`$95CD`)

**HL = the attribute address of the display cell address HL (line 0 of the cell)**

H = `$58` + (H - `$40`) / 8. Used by ClearMessageRows `$94EB` only (game 24 calls).

| | |
| --- | --- |
| Runs (the first recording's game window) | 24 calls, 1,200 t-states own (0.00 %) |
| Called from | `ClearMessageRows` |

## hud

`src/game/hud.asm`

### `NewGameScreen` (`$95DA`)

**Start a game: clear the screen, colours, HUD, scores, frames, lives, the table, the power box; park all balls**

Called once by the game start `$8013` (game frame 6182, w1 622, v1 twice: 772, 2603). Clears the display, border 7 (white; BORDCR `$38`), attributes: rows 0-4 `$39` (the HUD and message rows), row 5 `$38` (the top pocket marks), rows 6-22 `$60` (the table: bright green paper, black ink), row 23 `$38` (the bottom pocket marks).

Prints the HUD words (HudTexts `$969D` "1up" ... HudShots), zeroes the scores (`$9F45`, `$9F47`) and the pocket turns (PlayerVars `$9F43` / `$9F44`), frames `$9F4B` / `$9F4C` = 1, lives `$9F4E` / `$9F4F` = 3, Player2Racked `$9B33` = 0; prints the three scores (PrintHudNumber 0, 1, 2), the power box, power `$86BF` / `$86C0` = 0, the table; ParkBalls `$967B` for both ball sets (`$8A88` and `$8AEA`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 183,709 t-states own (0.06 %) |
| Called from | `GameRestart` |
| Calls | `DrawTable`, `DrawPowerBox`, `ParkBalls`, `PrintHudNumber`, `PrintText` |
| Reads | `$4000`-`$5AFE` (screen); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4000`-`$5AFF` (screen); `$5C48` (system); `$86BF`-`$86C0` (`DrawList`); `$9B33` (`ScoreVars`); `$9F43`-`$9F4F` (`PlayerVars`); `$CFFC`-`$CFFD` (`StackSpace`) |
| Ports out | `$07FE` |

### `ParkBalls` (`$967B`)

**Take the set at IX off the table: cue ball and balls 1-6 bit 7 of +13 clear, balls 1-6 to the potted row (x 0, 24, ... 120; y 20)**

Input IX = a set of 7 records (14 bytes each). Only +10/+11 (the sprite's place) and bit 7 of +13 are set; nothing is drawn. Called twice by NewGameScreen (game 2, frame 6190): `$8A88` the current player's set, `$8AEA` the other player's (the set TurnSwap `$9C15` exchanges).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 1,450 t-states own (0.00 %) |
| Called from | `NewGameScreen` |
| Reads | `$8A95`-`$8B4B` (`BallRecords`, `OtherPlayerBalls`) |
| Writes | `$8A95`-`$8B4B` (`BallRecords`, `OtherPlayerBalls`) |

### `UpBlinkTask` (`$96E6`)

**Blink the current player's "1up" / "2up": print it or its blank by UpBlink `$9B31`, then flip UpBlink**

A task added by StartAim `$8425` with period 20 (every 21 interrupts) and removed by `$8483` when the shot starts, which first prints it with UpBlink = `$FF` (shown). CurrentPlayer `$9B30` = 1 picks HudTexts ("1up", `$969D`) / HudOneUpBlank, 2 HudTwoUp / HudTwoUpBlank; UpBlink 0 prints the blank. game 88 runs, w1 377, p2 130.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 11,831 t-states own (0.00 %) |
| Called from | `StopShotTasks`, `CallTask` |
| Calls | `PrintText` |
| Reads | `$9B30`-`$9B31` (`ScoreVars`) |
| Writes | `$9B31` (`ScoreVars`) |

### `ShotsBlinkTask` (`$970E`)

**With one shot left: alternate "last  " / "  shot" in place of "shots"; at the shot's end (StopShotTasks, LastShotBlink = `$FF`) put "shots" and the count back**

A task added by StartAim `$8425` with period 25, removed by `$8483`, which calls it once with LastShotBlink `$9B32` = `$FF`. Returns at once unless ShotsLeft `$9F4D` = 1. LastShotBlink 0 prints HudLast `$9740`, 1 HudShot `$974A`, then flips 0 / 1; `$FF` prints HudShots and the count (PrintHudNumber 3) and sets 0. game 72 runs, w1 308; the `$FF` branch only in f1 (once).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 2,016 t-states own (0.00 %) |
| Called from | `StopShotTasks`, `CallTask` |
| Reads | `$9F4D` (`PlayerVars`) |

## gameover

`src/game/gameover.asm`

### `LoseLife` (`$9754`)

**A foul or no ball potted with the last shot: the foul jingle, one life less, erase one life ball; at none left GAME OVER**

Called by the end-of-shot task `$8357` when the foul code `$8E80` is set or the cue ball is off the table (game 4 at frames 6543-8811, w1 4, f1 4, p2 1, v1 3). With InfiniteLives `$B8C4` <> 0 (the four-key cheat, flipped at `$B3A1` in WaitNoKeyHeld) it goes straight to NextTurn `$97CD`: no jingle, no life lost. No recording of the case set it; the experiment f1c (f1 with CAPS SHIFT + SPACE + 1 + 0 held at frame 500, docs/10-gameplay-logic.md 10.10) flips it at frame 510 and keeps 3 lives through two fouls.

Lives `$9F4E` - 1; negative: GameOver `$97A2`. Else the leftmost life ball is XORed off: a cue ball sprite at x = `$E8` - 24 n (n = the lives before the loss: 3 -> x 160), y 20; then NextTurn.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 639 t-states own (0.00 %) |
| Called from | `ShotEnd` |
| Calls | `DrawBall`, `FoulJingle`, `GameOver` (tail), `NextTurn` (tail) |
| Reads | `$9F4E` (`PlayerVars`); `$B8C4` (`Players`) |
| Writes | `$95D8`-`$95D9` (`SpritePos`); `$9F4E` (`PlayerVars`) |

### `FoulJingle` (`$9780`)

**Play the foul jingle with the tasks stopped (WaitFrame `$80DE` with FoulJingleNotes)**

LoseLife `$9754` only (game 4, w1 4, f1 4, p2 1 at frame 1668, v1 3).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 80 t-states own (0.00 %) |
| Called from | `LoseLife` |
| Calls | `WaitFrameNoTasks` (tail) |

### `FoulJingleNotes` (`$9786`)

**Wait 10 frames, BEEPER HL `$209E` DE 26, wait 5 frames, BEEPER HL `$29FE` DE 23**

Two low notes: the ROM's BEEPER pitch 437500 / (HL + 30.125): about 52 Hz for DE 26, 27 cycles (0.51 s), then about 41 Hz for DE 23, 24 cycles (0.58 s). Run by FoulJingle through `$80DE` (game 4).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 4,073,572 t-states own (1.37 %) |
| Called from | `WaitFrameCall` |
| Reads | `$9789`-`$9797` (`FoulJingleNotes`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CFE2`-`$CFE3` (`StackSpace`) |

### `GameOver` (`$97A2`)

**No life left: erase the balls under the banner, print GAME OVER (and PLAYER n), then the other player's turn or the end**

From LoseLife `$9754` (game 1 at frame 8811, w1 11768, f1 4445). EraseBallsUnderBanner `$98B5`, GameOverText at row 9. One player: GameOverEnd `$9825`. Two players: "PLAYER 1" / "PLAYER 2" at row 11 by CurrentPlayer; the other player's lives (`$9F4F`) negative too: GameOverEnd; else wait 125 frames (WaitFramesB `$988C` through `$9886`) and NextTurn `$97CD` (known only from the code: p2 never ran out of lives).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 268 t-states own (0.00 %) |
| Called from | `LoseLife` (tail) |
| Calls | `BreakRestart` (tail), `WaitFrameNoTasks`, `EraseBallsUnderBanner`, `PrintHudNumber`, `PrintText` |
| Reads | `$9F45`-`$9F4A` (`PlayerVars`); `$B8BB` (`Players`) |

### `NextTurn` (`$97CD`)

**After a life lost: the turn swap; with two players, rack or go on for the new player**

From LoseLife and GameOver (game 3, w1 3, f1 3, p2 1 at frame 1738, v1 3). TurnSwapStart `$9C0F`; one player: RET (back to `$8357`, which racks or aims). Two players: drops the return; when the player now at the table (the other one after a swap, the same one when TurnSwap found the other out of lives, `$9C2B`) has no object ball on the table (his set never racked): DrawAllBalls `$9520` (XOR: erases the parked row), DrawLives `$9AD9`, NextFrame `$9BB8` if Player2Racked `$9B33` is set, Player2Racked = 1, Rack `$9F69`, StartAim `$8425` (p2 frame 1780).

Else (NextTurnResume `$9801`, known only from the code): wait 100 frames, blank row 9 (FrameBannerBlank), DrawAllBalls, DrawLives, RespotCueBall if the cue ball is off, StartAim.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 135 t-states own (0.00 %) |
| Called from | `LoseLife` (tail) |
| Calls | `TurnSwapStart` |
| Reads | `$B8BB` (`Players`) |

### `GameOverWait` (`$9857`)

**Wait 250 frames or a key, the hall of fame `$A702`, wait 500 frames or a key**

Run through WaitFrame `$80DE` by GameOverEnd (game 1 at frame 8811-9061, w1 11768-14232, f1 4445-5195). The second wait is the tail call into WaitFramesOrKey from `$9860`.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 66 t-states own (0.00 %) |
| Called from | `WaitFrameCall` |
| Calls | `WaitFramesOrKey`, `GameOverHallOfFame` |

### `WaitFramesOrKey` (`$9865`)

**Wait up to BC frames; stop early on fire (`$827C` bit 4 after `$8106`) or any key (KEY_SCAN, K_TEST)**

game 279 frames over 2 calls (8811-9090), w1 750, f1 750.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 18,398,913 t-states own (6.19 %) |
| Called from | `GameOverWait` |
| Calls | `ReadInput` |
| Reads | `$827C` (`InputState`); `$9866` (`WaitFramesOrKey`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CFE0`-`$CFE3` (`StackSpace`) |

### `WaitFramesBStopped` (`$9886`)

**Wait B frames with the tasks stopped: WaitFrame `$80DE` with WaitFramesB**

From GameOver `$97CA` (B 125) and NextTurnResume `$9801` (B 100): not executed in any build.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WaitFramesB` (`$988C`)

**HALT B times**

Code inside the text block (bytes `$76` `$10` `$FD` `$C9`). Not executed in any build (no two-player game over with the other player alive, no turn change to a racked set).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EraseBallsUnderBanner` (`$98B5`)

**Erase the balls on the table that the GAME OVER banner covers and take them off the table**

GameOver `$97A2` (game, w1, f1 once each). A ball with bit 7 of +13 set and its sprite at x 41-199, y 57 up to 88 (one player) or 104 (two) is XORed off and its bit 7 cleared. The erase branch ran in no build (no ball sat there at the game overs).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 1,423 t-states own (0.00 %) |
| Called from | `GameOver` |
| Reads | `$8A92`-`$8AE9` (`BallRecords`); `$B8BB` (`Players`) |

## tally

`src/game/tally.asm`

### `ScoreShot` (`$98F9`)

**Run ScoreTally with the tasks stopped (WaitFrame `$80DE`)**

From the end-of-shot task `$8357` twice per shot end (game 4, w1 21, f1 9, p2 6, v1 4, m1 1).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 80 t-states own (0.00 %) |
| Called from | `ShotEnd` |
| Calls | `WaitFrameNoTasks` (tail) |

### `ScoreTally` (`$98FF`)

**Score the balls potted in the last shot (+12 <> 0): print each term, the total, count it into the score, refill the shots**

ShotScore `$9B2C` = 0. Ball 1-6 with a pocket number in +12: the first sets PotBall `$9B2F` and PotMultiplier `$9B2E` (the pocket turn (PlayerVars `$9F43`) + pocket, 7..12 minus 6), waits 15 frames and clears the message rows (unless MessageStep is `$4F`); every further one first prints the pending term with "+" (TallyTermPlus `$9A01`), waits, clears, takes its own ball and multiplier. The last term is printed with "=" and the total (TallyTermTotal `$9A1A`).

The count: TallyPitch `$9B34` = 1200, step DE = round(ShotScore / 128) + 1 (the high byte of 2 x ShotScore, plus bit 6 as the carry, plus 1); one step a frame moves DE from ShotScore into the player's score (AddScoreStep `$99C1`, printed with a beep) while at least DE is left (at most 127 steps; B = 45 is only counted down, never tested in the loop), then the remainder in one go (a beep even for 0), then the rest of the 45 frames waited if any; past 45 steps (ShotScore 46 or more, in no recording) JP M skips the wait (w1's longest: 36 steps and the remainder, 37 beeps, frames 8456-8493). Then ClearMessageRows, DrawPottedRow `$9AB5`, ShotsLeft = ShotsForFrame `$9BE6`, wait 5 frames.

Returns at once when nothing was potted. Witness: AddScoreStep w1 287 calls (frames 1329-10175), p2 38, v1 72; TallyTermPlus (a double pot) w1, f1, v1 once each.

[Animation: `ScoreTally` at work](img/routines/ScoreTally.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 2,584 t-states own (0.00 %) |
| Called from | `WaitFrameCall` |
| Reads | `$8AA2`-`$8AE8` (`BallRecords`) |
| Writes | `$9B2C`-`$9B2D` (`ScoreVars`) |

### `AddScoreStep` (`$99C1`)

**Add DE to the current player's score, print it, beep at TallyPitch and lower the pitch by 10**

CurrentPlayer 1: ScorePlayer1 `$9F45`, 2: ScorePlayer2 `$9F47`; PrintHudNumber 0 / 1. The beep: BEEPER with HL = TallyPitch, DE = 6000 / TallyPitch (1200: about 356 Hz, DE 5, so 6 cycles, 15.5 ms), a tick that rises in pitch step by step; TallyPitch - 10 unless it would go below zero. w1 287 runs.

DE = 6000 / TallyPitch (by subtraction) and BEEPER plays DE + 1 cycles, so every tick lasts 13.1-15.5 ms whatever its pitch. A tick after the frame's HALT ends before the next interrupt; the first tick of a count-up of 100 points or more comes straight after the printed total (T 19 296-19 781) and runs past the next interrupt, which is lost (w1 12 of 17 count-ups, f1 1 of 1; docs 9.4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TallyTermPlus` (`$9A01`)

**Add the pending term to ShotScore and print "FxBxMx10+" at row 3 (col 6, 7 for a one-digit frame)**

Double-width text, attr `$38` (C = `$B8`). w1, f1, v1 once each (the double pots).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TallyTermTotal` (`$9A1A`)

**Add the last term and print "FxBxMx10=" and ShotScore x 10, centred on row 3**

The column starts at 1, plus one each for a frame < 10 and a total < 1000, < 100, < 10. Each term waits 15 frames (TallyPause `$9B07`) before its "x". w1 17, f1 1, p2 2, v1 4.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddTerm` (`$9A67`)

**ShotScore += frame x PotBall x PotMultiplier (ScoreTerm `$9B2A` as the product)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintTerm` (`$9A87`)

**Print frame, "x", ball, "x", multiplier, "x", "10" at DE (double width, attr `$38`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintTermFactor` (`$9AA2`)

**Print HL as a number at DE, wait 15 frames, then "x"; DE past it**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawPottedRow` (`$9AB5`)

**XOR the potted balls (bit 7 of +13 clear) at their place in the potted row, then the lives**

After ClearMessageRows wiped rows 2-4: ScoreTally and MessagesTask step `$4F`. game 4, w1 21, f1 4, p2 3, v1 7. Falls into DrawLives.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 1,984 t-states own (0.00 %) |
| Called from | `MessagesTask` (tail) |
| Calls | `DrawLives` |
| Reads | `$8AA3`-`$8AE9` (`BallRecords`) |

### `DrawLives` (`$9AD9`)

**XOR one cue ball per life (LivesLeft `$9F4E`, 1-3) in the potted row at x 160, 184, 208 (right-aligned to 208), y 20**

The first x = `$88` + 24 (4 - lives). Lives 0 or negative: nothing. Called by DrawPottedRow, NextTurn, TurnSwap and the game start `$8013`: game 5, w1 22, p2 6.

| | |
| --- | --- |
| Runs (the first recording's game window) | 5 calls, 1,564 t-states own (0.00 %) |
| Called from | `GameRestart`, `DrawPottedRow` |
| Calls | `DrawBall`, `MessagesTask` |
| Reads | `$95D8`-`$95D9` (`SpritePos`); `$9F4E` (`PlayerVars`) |
| Writes | `$95D8`-`$95D9` (`SpritePos`) |

### `TallyPause` (`$9B07`)

**Wait 15 frames (HALT)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MultiplyTerm` (`$9B0D`)

**ScoreTerm `$9B2A` = ScoreTerm x A (16 x 8 bits, shift and add)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## turns

`src/game/turns.asm`

### `ShowFrameBanner` (`$9B36`)

**Print "FRAME n" double width at row 9 (row 11 under a PLAYER n banner), wait 75 frames, blank rows 9 and 11**

Called by Rack `$9F6F` at each rack (game 1 at frame 6190, w1 4, p2 2). Two players: the cell row 9, col 8 is tested for pixels (PlayerBanner printed): then row 11. The column: 9, 8 for a frame >= 10. FrameBanner `$9B8E` is patched (row, column), printed, the number after it (PrintNumber `$9E13`, attr `$E0`); then FrameBannerBlank `$9B98` printed at row 9 and row 11 (its row byte patched).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 5,224,560 t-states own (1.76 %) |
| Called from | `RackBalls` |
| Calls | `PrintNumber`, `PrintText` (tail) |
| Reads | `$9B76` (`ShowFrameBanner`); `$9F4B`-`$9F4C` (`PlayerVars`); `$B8BB` (`Players`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$9B8E`-`$9B98` (`FrameBanner`); `$CFF8`-`$CFF9` (`StackSpace`) |

### `NextFrame` (`$9BB8`)

**Frame cleared: frame + 1 (up to 99), the pocket multipliers turn one place, the shots refilled, power reset**

From the end-of-shot task `$8357` and NextTurn `$97CD`: w1 3 times (frames 4023-10196, frames 2, 3 and 4). Frame `$9F4B` + 1, printed (PrintHudNumber 4); the pocket turn (PlayerVars `$9F43`) - 1 (0 wraps to 5), the marks redrawn (DrawPocketMarks `$9D6B`); ShotsLeft = ShotsForFrame, printed (PrintHudNumber 3); tail call `$8539` (erase the power bar, power 0).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShotsForFrame` (`$9BE6`)

**A = the shots for this frame: ShotsPerFrame[frame], 2 from frame 10; plus variation + 1 in a variation**

Frame `$9F4B`; the variation `$B8C3` (0 standard, 1 numeric order, 2 own pockets; the menu). Standard: frames 1-2 five shots, 3-5 four, 6-9 three, then two. Variation 2 on frame 1: 5 + 3 = 8 (v1, WALKTHROUGH 6.0). game 4, w1 24.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 404 t-states own (0.00 %) |
| Called from | `GameRestart`, `TurnSwap` |
| Reads | `$9C06` (`ShotsPerFrame`); `$9F4B` (`PlayerVars`); `$B8C3` (`Players`) |

### `TurnSwapStart` (`$9C0F`)

**Run TurnSwap with the tasks stopped (WaitFrame `$80DE`)**

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 60 t-states own (0.00 %) |
| Called from | `NextTurn` |
| Calls | `WaitFrameNoTasks` (tail) |

### `TurnSwap` (`$9C15`)

**After a life lost: with two players and the other still alive, swap everything to the other player; then the frame, shots, pocket marks, PLAYER n**

Run by TurnSwapStart (game 3, w1 3, f1 3, p2 1 at frame 1738, v1 3). Two players (p2 only): wait 40 frames, ClearTableForTurn `$947D`, DrawLives (XOR: erases the lives), then unless the other's lives `$9F4F` are negative: CurrentPlayer 1 <-> 2, and the pairs pocket turn (PlayerVars `$9F43`) / `$9F44`, LivesLeft `$9F4E` / `$9F4F`, FrameNumber `$9F4B` / `$9F4C` swapped, the 98-byte ball sets `$8A88` / `$8AEA` exchanged byte by byte.

Then for one and two players: `$8539` (power 0), PrintHudNumber 4 (frame), ShotsLeft = ShotsForFrame, PrintHudNumber 3, DrawPocketMarks, and falls into PlayerBanner.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 423 t-states own (0.00 %) |
| Called from | `WaitFrameCall` |
| Calls | `AimPowerReset`, `ShotsForFrame`, `DrawPocketMarks`, `PrintHudNumber` |
| Reads | `$B8BB` (`Players`) |
| Writes | `$9F4D` (`PlayerVars`) |

### `PlayerBanner` (`$9C7B`)

**Two players: print "PLAYER 1" / "PLAYER 2" double width at row 9, col 8**

From TurnSwap and the game start `$8013`. Returns at once with one player (`$B8BB` = 1). p2 2, v1 5 (entries).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 112 t-states own (0.00 %) |
| Called from | `GameRestart` |
| Reads | `$B8BB` (`Players`) |

### `LastShotBeepTask` (`$9CA7`)

**With one shot left: a short beep (BEEPER HL 500, DE 10, so 11 cycles: 825 Hz, 12.7 ms; f1 measured 825.7 Hz, 13 beeps, docs/09-sound.md 9.4), then DI (it runs in the interrupt)**

A task added by StartAim `$8425` with period 25, removed by `$8506` at the shot. 58 runs in game, w1 179 (none beeped: no aim of w1 had one shot left), f1 13 beeps. BEEPER ends with EI; the DI keeps the interrupt handler closed.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 1,624 t-states own (0.00 %) |
| Called from | `CallTask` |
| Reads | `$9F4D` (`PlayerVars`) |

### `MessagesTask` (`$9CB7`)

**Step through the foul message: clear, print, hold about 75 steps, clear, redraw the potted row**

MessageStep `$9F50`: 0: start (step 1) only when the foul code `$8E80` is set; 1: ClearMessageRows; 2: the text by `$8E80` (1 FOUL SHOT!, 2 WRONG ORDER!, 3 WRONG POCKET!); 3-`$4D`: wait; `$4E`: ClearMessageRows; `$4F`: DrawPottedRow; `$50`: stays. Each step but the last adds 1 (MessageNextStep pushed as the return address). A task of the balls-moving list `$84BA` (period 0) and called by `$8457` once a frame after the balls stop until step `$50`. game 606 runs (320 steps); the texts: game 4, w1 4, f1 3, p2 1, v1 3 (WRONG ORDER / WRONG POCKET in v1 at frames 1471 / 3100).

| | |
| --- | --- |
| Runs (the first recording's game window) | 320 calls, 60,714 t-states own (0.02 %) |
| Called from | `WaitMessagesLoop`, `CallTask`, `ClearMessageRows`, `DrawLives`, `PrintText` |
| Calls | `ClearMessageRows` (tail), `DrawPottedRow` (tail), `PrintText` (tail) |
| Reads | `$8E80` (`FoulCode`); `$9F50` (`PlayerVars`) |
| Writes | `$9F50` (`PlayerVars`) |

### `ResetBallPositions` (`$9D2C`)

**Put the seven balls of the current set at their rack positions (StartPositions), on the table**

x / y whole parts from StartPositions, fractions 0, +10/+11 = x - 7 / y - 7, flags +13 = `$80`; velocities untouched; nothing drawn. Called by the entry `$8000` (every build, frame 0 / 5556) and the editor (`$C042`, `$C532`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 1,453 t-states own (0.00 %) |
| Called from | `GameStart` |
| Reads | `$9D5D`-`$9D6A` (`StartPositions`) |
| Writes | `$8A88`-`$8AE9` (`BallRecords`) |

## printing

`src/game/printing.asm`

### `DrawPocketMarks` (`$9D6B`)

**Print "xN" at the six pockets, clockwise from the top left, N = 1-6 turned by the pocket turn (PlayerVars `$9F43`)**

Cells: top row 5 (y 40) cols 0, 15, 30 then bottom row 23 (y 184) cols 30, 15, 0, each a ROM "x" and a digit. The k-th mark (k = 0..5) shows ((PocketTurn + k) mod 6) + 1; PocketTurn ends where it started (six increments). The scoring and the own-pocket rule use PocketTurn + the pocket number the same way (`$9923`, `$8C37`), so pocket 1 is the top left mark (known only from the code). game 4 (frame 6190 on), w1 7, v1 5.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 580 t-states own (0.00 %) |
| Called from | `GameRestart`, `TurnSwap` |
| Calls | `PrintPocketMark` |

### `PrintPocketMark` (`$9D8C`)

**At screen address HL: the ROM's "x" glyph, then the digit PocketTurn + 1; PocketTurn + 1 mod 6**

| | |
| --- | --- |
| Runs (the first recording's game window) | 24 calls, 4,484 t-states own (0.00 %) |
| Called from | `DrawPocketMarks` |
| Calls | `CopyGlyph` |
| Reads | `$9F43` (`PlayerVars`) |
| Writes | `$9F43` (`PlayerVars`) |

### `CopyGlyph` (`$9DB4`)

**Copy 8 bytes from DE down the cell at HL; in the bottom two thirds one byte earlier (the glyph one pixel lower)**

| | |
| --- | --- |
| Runs (the first recording's game window) | 48 calls, 16,172 t-states own (0.01 %) |
| Called from | `PrintPocketMark` |
| Reads | `$DFCC`-`$DFFA` (`Font`) |
| Writes | `$40A0`-`$47BF` (screen); `$50E0`-`$51FF` (screen); `$52E0`-`$52FF` (screen); `$53E0`-`$53FF` (screen); `$54E0`-`$54FF` (screen); `$55E0`-`$55FF` (screen); 2 more ranges |

### `PrintHudNumber` (`$9DC3`)

**Print HUD number A: 0 score 1, 1 score 2, 2 hi score (five digits and a "0"), 3 shots left, 4 frame (and a space)**

Positions (row, column): score 1 (0, 3), score 2 (0, 26), hi (0, 14), shots (1, 31), frame (1, 22); attr `$3A`. The scores print with leading zeros (B = `$80`), shots and frame without. game 15, w1 322, v1 92.

| | |
| --- | --- |
| Runs (the first recording's game window) | 15 calls, 2,022 t-states own (0.00 %) |
| Called from | `GameRestart`, `ShotEnd`, `NewGameScreen`, `GameOver`, `TurnSwap` |
| Calls | `PrintNumber` (tail), `PrintChar` (tail) |
| Reads | `$9F45`-`$9F4E` (`PlayerVars`) |

### `PrintNumber` (`$9E13`)

**Print HL (0-65535) in decimal at row D, column E, attr C; B bit 7 = keep leading zeros. DE out: past the number**

Five digits by subtraction (10000, 1000, 100, 10, 1, PrintDigit `$9E40`); without B bit 7 the zeros before the first other digit are skipped and 0 prints as "0". Callers: the HUD, the tally, the FRAME banner, the hall of fame `$AA23`. game 16, w1 420.

| | |
| --- | --- |
| Runs (the first recording's game window) | 16 calls, 3,156 t-states own (0.00 %) |
| Called from | `ShowFrameBanner`, `PrintHudNumber` (tail) |
| Calls | `PrintDigit` |

### `PrintDigit` (`$9E40`)

**One digit: A = HL / DE (repeated subtraction), print it at the position kept on the stack, step the column**

Swaps its return address and the position kept on the stack by the caller (EX (SP),HL) so the five calls share the position.

| | |
| --- | --- |
| Runs (the first recording's game window) | 80 calls, 15,743 t-states own (0.01 %) |
| Called from | `PrintNumber` |
| Calls | `PrintChar` |

### `PrintText` (`$9E65`)

**Print the text record at HL: row, column, attribute (bit 7 double width), length N, then N characters**

No end marker: the length byte counts. Out: HL = row (H), column (L) after the text (callers print a number there); DE past the record. game 138 calls, w1 449; callers in the HUD, the tally, the hall of fame (`$AA4B`, `$ACEF`), the menu (`$B22E`, `$B3F3`, `$B605`, `$B67E`), the presents page `$B8C5` and the editor (`$C042`, `$C414`).

[Animation: `PrintText` at work](img/routines/PrintText.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 138 calls, 79,000 t-states own (0.03 %) |
| Called from | `NewGameScreen`, `UpBlinkTask`, `GameOver`, `ShowFrameBanner` (tail), `MessagesTask` (tail), `MainMenu`, `ShowKeys` (tail), `PresentsPage` |
| Calls | `MessagesTask`, `PrintChar` |
| Reads | `$969D`-`$96E5` (`HudTexts`); `$9890`-`$989C` (`GameOverTexts`); `$9B8E`-`$9BB7` (`FrameBanner`); `$9CFD`-`$9D0A` (`FoulTexts`); `$B484`-`$B5E2` (`MenuTitle`); `$B65F`-`$B67D` (`KeysLine`); 1 more ranges |

### `PrintChar` (`$9E7C`)

**Print character A at row H (0-23), column L (0-31), attribute C (bit 7: double width); keeps all registers**

Writes the attribute first (one or two cells), then the glyph (see the module text). game 1094 calls, w1 4388, m1 2143.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,094 calls, 705,524 t-states own (0.24 %) |
| Called from | `PrintHudNumber` (tail), `PrintDigit`, `PrintText` |
| Calls | `PrintCharWide`, `CellAddress`, `CellAttr` |
| Reads | `$9F2E`-`$9F35` (`CopyrightGlyph`); `$DEF4`-`$DFF3` (`Font`); `$E004`-`$E013` (`Font`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4000`-`$4AB3` (screen); `$4AE2`-`$4BB3` (screen); `$4BE2`-`$4CB3` (screen); `$4CE2`-`$4DB3` (screen); `$4DE2`-`$4EB3` (screen); `$4EE2`-`$4FB3` (screen); 9 more ranges |

### `PrintCharWide` (`$9EDE`)

**Copy glyph DE to cells HL and HL+1 with every pixel doubled across (16 pixels a line)**

Each glyph byte's low four bits go, doubled, to the right byte, the high four to the left. game 56, w1 285.

| | |
| --- | --- |
| Runs (the first recording's game window) | 56 calls, 107,218 t-states own (0.04 %) |
| Called from | `PrintChar` |
| Reads | `$DFCC`-`$DFD3` (`Font`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4066`-`$4079` (screen); `$4166`-`$4179` (screen); `$4266`-`$4279` (screen); `$4366`-`$4379` (screen); `$4466`-`$4479` (screen); `$4566`-`$4579` (screen); 3 more ranges |

### `CellAddress` (`$9F14`)

**HL = the display address of row H (0-23), column L (0-31), line 0**

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,094 calls, 68,922 t-states own (0.02 %) |
| Called from | `PrintChar` |

### `CellAttr` (`$9F23`)

**HL = the attribute address of the display cell address HL**

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,094 calls, 54,700 t-states own (0.02 %) |
| Called from | `PrintChar` |

## racking

`src/game/racking.asm`

### `SpriteFromBall` (`$9F36`)

**HL = the sprite place of record IX: L = x - 7, H = y - 7 (whole parts +1, +3)**

Called by the ball redraw task `$8297` and Rack `$9F6F`: game 905, w1 7580.

| | |
| --- | --- |
| Runs (the first recording's game window) | 905 calls, 63,350 t-states own (0.02 %) |
| Called from | `RedrawBall`, `RackBalls` |
| Reads | `$8A89`-`$8ADF` (`BallRecords`) |

### `Rack` (`$9F69`)

**Rack the balls with the tasks stopped (WaitFrame `$80DE` with RackBalls)**

From the game start `$8013`, the end-of-shot task `$8357` and NextTurn `$97CD`: game 1 (frame 6190), w1 4 (frames 630-10196), p2 2.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 20 t-states own (0.00 %) |
| Called from | `GameRestart` |
| Calls | `WaitFrameNoTasks` (tail) |

### `RackBalls` (`$9F6F`)

**FRAME banner, then roll balls 1-6 into the triangle by their scripts, one step a frame; then the cue ball to (40, 115)**

ShowFrameBanner `$9B36`; the rack set = RackSets[((frame - 1) / 2) mod 6] (frames 1-2 set 0, 3-4 set 1, ...); each ball's RackScriptState = (its script, 0, 0) and its record cleared (ClearBallMotion `$A040`).

Each step: RackStep `$A05E` for balls 1-6 (B counts the scripts ended), the draw list `$869E` rebuilt (`$8304`), HALT, and every ball of the list with bit 4 of +13 set (it moved) erased at +10/+11, placed at SpriteFromBall, drawn, bit 4 cleared (the list's cue entry, ball 0, is skipped). Until all six scripts ended: game 170 steps (frames 6266-6435).

The cue ball: ClearBallMotion, x 40 / y 115 with a random fraction (R x 2 into both), drawn (no erase before it).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 7,276,975 t-states own (2.45 %) |
| Called from | `WaitFrameCall` |
| Calls | `BuildDrawList`, `DrawBall`, `ShowFrameBanner`, `SpriteFromBall`, `ClearBallMotion`, `RackStep` |
| Reads | `$869E`-`$86B9` (`DrawList`); `$8AA0`-`$8AE9` (`BallRecords`); `$9F4B` (`PlayerVars`); `$9FD3` (`RackBalls`); `$A0C4`-`$A0DB` (`RackSets`, `RackScripts0`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$8A88`-`$8AE9` (`BallRecords`); `$95D8`-`$95D9` (`SpritePos`); `$9F51`-`$9F68` (`PlayerVars`); `$CFF8`-`$CFF9` (`StackSpace`) |

### `ClearBallMotion` (`$A040`)

**Zero record IX's fractions (+0, +2), velocities (+4..+7), friction steps (+8, +9); flags +13 = `$80`**

| | |
| --- | --- |
| Runs (the first recording's game window) | 7 calls, 1,295 t-states own (0.00 %) |
| Called from | `RackBalls` |
| Writes | `$8A88`-`$8AE9` (`BallRecords`) |

### `RackStep` (`$A05E`)

**One frame of the rack script of ball IX, state at HL: a wait, a repeated move, or the next command**

State: +0/+1 the script pointer, +2 the wait, +3 the moves left. A wait above 0: one less, return. Moves left: x + dx, y + dy (the pair at the pointer, whole pixels), bit 4 of +13 set; the pointer passes the pair when the count ends. Else the next command: 0 end (B + 1, the pointer stays: every later step ends again), 1 x y (put the ball at x, y), 2 n dx dy (move n times by dx, dy, one a frame; starts at once), 3 n (wait n frames).

game 1040 calls (frames 6266-6435); command 1: 12, command 2: 20, command 3: 6.

[Animation: `RackStep` at work](img/routines/RackStep.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,020 calls, 178,229 t-states own (0.06 %) |
| Called from | `RackBalls` |
| Reads | `$8A97`-`$8AE9` (`BallRecords`); `$9F51`-`$9F68` (`PlayerVars`); `$A0DC`-`$A161` (`RackScript0Ball1`) |
| Writes | `$8A97`-`$8AE9` (`BallRecords`); `$9F51`-`$9F68` (`PlayerVars`) |

## halloffame

`src/game/halloffame.asm`

### `GameOverHallOfFame` (`$A702`)

**At GAME OVER: enter the hall of fame if the score qualifies**

Called once by `$985D` (the GAME OVER path `$9857`). Clears the "moves" flag (+`$0E`) of the three slots. One player (Players `$B8BB` = 1): copies the score `$9F45` to NewEntry1 `$ACDD`, counts the slots it beats (CountBeaten `$A7EB`) and returns if none; else runs the name page and entry (NameEntryPage `$ACEF`), copies NameBuffer `$B227` to NewEntryName1 `$ACDF`, then ShowAndSlideDown `$A86D`, InsertEntry `$A817` for NewEntry1 and SlideFlagsUp `$A8C7` (a jump: its RET returns to `$9860`).

Witness: game 1 (frame 9061) and f1 1 (frame 4695) returned at `$A72A` (score below every slot); w1 1 (frame 12018) went on to the name entry; `$A72E` w1 1, frames 13368-13553.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 187 t-states own (0.00 %) |
| Called from | `GameOverWait` |
| Calls | `CountBeaten` |
| Reads | `$9F45`-`$9F46` (`PlayerVars`); `$B8BB` (`Players`) |
| Writes | `$AC16` (`HofTable`); `$AC5D` (`HofTable`); `$ACA4` (`HofTable`); `$ACDD`-`$ACDE` (`NewEntry1`) |

### `CountBeaten` (`$A7EB`)

**A = how many hall-of-fame slots the score HL beats, flagging them**

Input HL: the score. Tests slot 3, slot 2, slot 1 in that order with TestSlot `$A802`; each slot whose score is below HL (strictly) gets +`$0E` = 1 (its flag will move) and adds 1 to A; the first slot not beaten ends the count (TestSlot drops CountBeaten's frame and returns to the caller). Output A = 0-3, Z when 0.

Witness: game 1, f1 1 (both A = 0), w1 2 (frames 12018 and 13553, from `$A702` and InsertEntry).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 35 t-states own (0.00 %) |
| Called from | `GameOverHallOfFame` |
| Calls | `TestSlot` |

### `TestSlot` (`$A802`)

**Beaten-slot test for CountBeaten: score HL against slot IX**

IX: the slot. If HL > the slot's score (+0/+1): A + 1, +`$0E` = 1, return to CountBeaten. Else POP the return address and RET to CountBeaten's caller with the count so far. Witness: game 1, w1 6, f1 1; `$A811` (beaten) w1 4.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 105 t-states own (0.00 %) |
| Called from | `CountBeaten` |
| Reads | `$AC96`-`$AC97` (`HofTable`) |

### `InsertEntry` (`$A817`)

**Insert the 9-byte record at DE (score, name) into the table and render the three names again**

DE: a new-entry record (NewEntry1 `$ACDD` or NewEntry2 `$ACE6`). A zero score returns at once (a player who did not qualify). Ranks the score with CountBeaten (which flags the slots that will change), moves slot 2 to slot 3 (rank 2 or 3) and slot 1 to slot 2 (rank 3), 9 bytes each, copies the record into the freed slot, then RenderName `$AADF` for all three slots.

Witness: w1 1 at frame 13553 ("vp", 270, into slot 2: james stays first, francis moves to slot 3, bill drops out; screen w1 frame 14000).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowAndSlideDown` (`$A86D`)

**Show the hall of fame, then slide the flags that lose their place down off the screen**

ShowHallOfFame `$A8FD`, 50 frames' pause (HALTs), BlankScore `$AA4B` over each flagged slot's score, then one pixel a frame SlideFlagDown `$A95A` on each slot until no slot has +`$0E` bit 0 set (each clears it when its flag has left the screen at y `$C0`).

Witness: w1 1, frames 13368-13553 (`$A896` 129 frames).

[Animation: `ShowAndSlideDown` at work](img/routines/ShowAndSlideDown.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlideFlagsUp` (`$A8C7`)

**After the insert: slide the flagged flags up to their poles, then print their scores**

50 frames' pause, then one pixel a frame SlideFlagUp `$A990` on each slot until no flag moves. Returns to GameOverHallOfFame's caller. Witness: w1 1, frames 13553-13732 (`$A8CC` 129 frames).

[Animation: `SlideFlagsUp` at work](img/routines/SlideFlagsUp.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowHallOfFame` (`$A8FD`)

**Draw the hall of fame: blue screen, three poles, the flags with their names, the scores**

Clears the pixels, attributes `$0F` (white on blue), border 1 (blue). Then a frame each: DrawPole `$ABC3`, DrawFlag `$AB7B` and PrintScore `$AA23` for slots 1, 2, 3. Called by ShowAndSlideDown and by the attract sequence (`$B906`).

Witness: w1 1, frames 13368-13374. The attract call: no recording ran `$B906` (l1sum.py B906) (known only from the code).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlideFlagDown` (`$A95A`)

**Move slot IX's flag one pixel down (if it is flagged and still on the screen)**

Returns at once unless +`$0E` bit 0. At y (+`$0A`) >= `$C0` clears the flag. Else XORs the flag's top line off and a line under it on (XorLine `$93B3`, 48 pixels), fills the line the name leaves (RestoreFlagLine `$AABD`, A = 8), moves the tail (DrawFlagTail `$A9CC` at y and y + 1) and draws the name one line lower (DrawNameBitmap `$AA74`).

Witness: w1 387 calls, 216 moves, frames 13425-13553.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlideFlagUp` (`$A990`)

**Move slot IX's flag one pixel up until it is back at its pole**

Returns unless +`$0E` bit 0. When y - 2 < the pole's y (+`$0C`) clears the flag and prints the score (PrintScore `$AA23`, a jump). Else the mirror of SlideFlagDown (RestoreFlagLine with A = `$0F`). Witness: w1 387 calls, 216 moves, frames 13604-13732.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawFlagTail` (`$A9CC`)

**XOR the flag's ragged tail (FlagTail `$AB41`, 29 lines) at x + 48 of slot IX's flag**

From the flag position (+9 x, +`$0A` y); nothing when y >= `$C0`. Draws the lines of the first character row, then whole rows of 8 (clipped at the screen's bottom), through XorTailLines `$AA12`. Witness: w1 867 calls, frames 13372-13731.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `XorTailLines` (`$AA12`)

**XOR B lines of the tail (2 bytes a line, the right byte first) at HL; C counts the lines left**

DE: the tail data, HL: the screen. Called by DrawFlagTail and fallen into from `$AA0E`. Witness: w1 3372 entries, 21779 lines.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintScore` (`$AA23`)

**Print slot IX's score x 10 above its pole: five digits with leading zeros and a "0"**

At character column x/8 (+`$0B`) and row y/8 - 1 (+`$0C`), attribute `$0F`: `$9E13` with B = `$80` (leading zeros printed), then the character "0" through `$9E7C`. The 003000 / 002700 of w1 frame 14000. Witness: w1 5, frames 13374-13732.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BlankScore` (`$AA4B`)

**Print six spaces over slot IX's score (before its flag slides away)**

Patches the row and column of the text record ScoreBlank `$AA6A` and prints it (`$9E65`). Witness: w1 2 (the two flagged slots), frame 13424.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawNameBitmap` (`$AA74`)

**Copy slot IX's name bitmap (+`$0F`, 7 bytes x 8 lines) to the flag at (x, y + 8)**

Clipped at y `$C0`, split over two character rows when y + 8 is not a multiple of 8, through CopyNameLines `$AAAF`. Reached by a jump from SlideFlagDown, SlideFlagUp and DrawFlag. Witness: w1 435, frames 13372-13731.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CopyNameLines` (`$AAAF`)

**Copy A lines of 7 bytes from DE to the screen at HL (down one pixel line each)**

Witness: w1 1107 entries, 3480 lines (from DrawNameBitmap and RestoreFlagLine).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RestoreFlagLine` (`$AABD`)

**Copy one solid line (SolidLine `$AAD8`) at slot IX's flag x, line y + A**

A = 8 (sliding down: the line above the name) or `$0F` (sliding up: the line under it). Nothing at y + A >= `$C0`. Witness: w1 432, frames 13425-13731.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RenderName` (`$AADF`)

**Render slot IX's name (+2, 7 characters) into its bitmap (+`$0F`), inverted**

RenderChar `$AB04` for each character, into the bitmap with a stride of 7. Called by InsertEntry (the three slots) and DrawFlag. Witness: w1 6, frames 13372-13553.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RenderChar` (`$AB04`)

**One character A as 8 inverted bytes, every 7th byte from HL**

Digits from Font+`$D0` (`$DFC4`), a-z from Font `$DEF4`, anything else from CHAR_SET `$3D00` (space). Same lookup as the print routine `$9E7C`. Witness: w1 42 (6 names x 7), `$AB23` (the ROM's glyphs, spaces) 12.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawFlag` (`$AB7B`)

**Draw slot IX's flag at its pole: attributes, the solid field, the tail, the name**

Sets the flag position to (x + 8, y + 1) of the pole, renders the name (RenderName), fills 9 attribute cells a row with +`$0D` from the flag's row to the bottom of the screen, XORs a 48 x 24 solid field (XorLine `$93B3`), the tail (DrawFlagTail) and the name (DrawNameBitmap). Witness: w1 3, frames 13372-13373.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawPole` (`$ABC3`)

**Draw slot IX's pole from (x, y) to the bottom of the screen**

At the pole's top line + 7: the cap (`$FF` `$E0`, 11 pixels) with attribute `$0F` on its two cells; then each character row down to the bottom: attribute `$0F` and 8 lines of `$1F` (a 5-pixel pole). Witness: w1 3, frame 13371.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AttrOfScreen` (`$ABFD`)

**HL = the attribute address of the screen address HL (H's character row)**

Witness: w1 99, frames 13371-13373 (DrawPole, DrawFlag).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## nameentry

`src/game/nameentry.asm`

### `NameEntryPage` (`$ACEF`)

**The "congratulations" page, then the name entry**

Clears the pixels, attributes `$30` (black on yellow), border 6 and BORDCR `$30`. The title: HofTitle `$AD4F` when Players `$B8BB` = 1, else HofTitleP1 `$AD63` or HofTitleP2 `$AD81` by `$9B30`; then each text record of HofTextList `$AD3D` (`$9E65`), then a jump to NameEntry `$AE92` (its RET goes back to GameOverHallOfFame).

Witness: w1 1, frames 12018-12023 (the title HofTitle; HofTitleP1/P2 read by no recording, l1sum.py --reads AD63-AD9E).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NameEntry` (`$AE92`)

**Draw the grid and the empty name, then move the cursor and pick characters until "end"**

DrawCharacterGrid `$B0C7`, NameBuffer `$B227` = seven "_" (`$5F`), the cursor at row 0 column 0 (D, E; XorCursorBox `$B047`), RepeatDelay `$B226` = `$70`, HL = the name cursor = NameBuffer, DrawName `$B0A8`. Then the loop NameEntryLoop `$AEB3`, a frame each: HALT, `$8106`, with `$AEB3` pushed as the return address of every branch. Nothing held: RepeatDelay = `$70`. Fire: PickCell. A direction: auto-repeat, click, NameCursorForward `$AFFE` or NameCursorBack `$B023`.

Witness: w1 1 (frame 12023); NameEntryLoop 1230 frames, 12025-13368; 51 cursor steps (`$AF00`), 3 picks (`$AF26`: v, p, end).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PickCell` (`$AF4E`)

**Fire on the cell at row D column E: store the character, rub out, or end**

The cell's byte is CharacterGrid[14 D + E]. A character: stored at HL (at the 7th position the last character is overwritten), HL + 1, DrawName (a jump). `$0C` "rub": HL - 1 (not before the start), "_" there, DrawName. `$0D` "end": drops the two return addresses (NameEntryFire's and `$AEB3`) so its RET leaves the name entry; turns "_" into spaces, counts the leading (D) and trailing (E) spaces and shifts the name by (D - E) / 2 to centre it.

Witness: w1 3 (frames 13102-13368): two characters (`$AF76` 2), one "end" (`$AF8C` 1, shifted right: `$AFDE`). Rub (`$AF7B`) and the left shift (`$AFD1`) were not run.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NameCursorForward` (`$AFFE`)

**Move the cursor box one cell forward (row 2: column 10 "rub" to 12 "end", 12 back to the start)**

XorCursorBox off, the next cell (column 14 wraps to the next row), XorCursorBox on (a jump). Columns 11 and 13 of row 2 are never reached (the rub and end cells are two wide). Witness: w1 45, frames 12933-13359.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NameCursorBack` (`$B023`)

**Move the cursor box one cell back (row 2: 12 to 10; before row 0 column 0: "end")**

Witness: w1 6, frames 13114-13154.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `XorCursorBox` (`$B047`)

**XOR the cursor box round the cell at row D, column E**

Cell (D, E) at pixel x = 16 E + `$14`, y = 16 D + `$70`; a box 12 pixels wide (28 for rub and end: row 2, column >= 10), its corners drawn as XorLine `$93B3` lines. Drawing twice erases. Witness: w1 103, frames 12024-13359.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawName` (`$B0A8`)

**Draw NameBuffer's 7 characters at y `$B0`, x `$48` + 16 n**

DrawCharAt `$B118` for each. Witness: w1 3, frames 12024-13163.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawCharacterGrid` (`$B0C7`)

**Draw the 42 cells of CharacterGrid (3 rows of 14 at x `$10` + 16 n, y `$70` + 16 row), then "rub" and "end"**

The `$0C` / `$0D` cells print as spaces; the words "rub" and "end" are drawn as line lists (DrawLineList `$B101` with RubLines `$B191` at x `$B7`, y `$90` and EndLines `$B1DA` at x `$D7`, y `$90`). Witness: w1 1, frame 12023.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawLineList` (`$B101`)

**XOR a list of horizontal lines (dx, dy, length; `$FF` ends) from the origin E = x, D = y**

Witness: w1 2 entries (rub, end), 51 lines.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawCharAt` (`$B118`)

**Draw character A at pixel (L, H) with a 4-pixel offset (two half bytes a line)**

Below `$20`: a space. a-z from Font, digits from Font+`$D0`, others from CHAR_SET. Writes (not XOR) the glyph's left and right nibbles into two bytes, so a cell 16 pixels wide shows the glyph centred. Witness: w1 63, frames 12023-13163.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## menu

`src/game/menu.asm`

### `MainMenu` (`$B22E`)

**The main menu: draw the page, then take keys until B (or joystick fire) begins the game**

Clears the pixels, attributes `$0F`, border 1, BORDCR `$08`. Prints the records of MenuTexts `$B464`, the variation line (VariationStandard `$B5D0` / Variation1Line `$B5E3` / Variation2Line `$B5F4` by Variation `$B8C3`), the key line (ShowKeys `$B605`), and XorTick `$B89C` at rows Players + 3, Pockets + 7 and Control + 10. Then MenuKeys `$B293`.

Callers: `$8037` (every restart from `$8013`), the ends of the timeout (`$B2C3`, `$B6D4`) and M on the variations page (`$B6F7`). Returns (to `$803A`, the game) on B, or on fire. Witness: game 2 (frames 6060, 9809), w1 2, f1 2, p2 2, v1 2, m1 4.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 50,575,185 t-states own (17.01 %) |
| Called from | `GameRestart` |
| Calls | `PrintText`, `WaitNoKey`, `ShowKeys`, `XorTick` |
| Reads | `$4000`-`$5AFE` (screen); `$B29D` (`MainMenu`); `$B464`-`$B483` (`MenuTexts`); `$B8BB`-`$B8C3` (`Players`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$4000`-`$5AFF` (screen); `$5C48` (system); `$B8C1`-`$B8C2` (`Players`); `$CFFC`-`$CFFD` (`StackSpace`) |
| Ports out | `$01FE` |

### `WaitNoKey` (`$B38E`)

**Wait until no key is held; flip InfiniteLives if CAPS SHIFT, SPACE, 1 and 0 are held**

A frame each: KEY-SCAN, K-TEST; returns when no key. While a key is held TestCheatKeys `$B3B8` is asked: all four held complements InfiniteLives `$B8C4` and waits for the release (`$B3A8`).

Witness: game 73, w1 14, f1 14, p2 24, v1 36, m1 202 calls; `$B3B8` asked game 70, m1 176 times; the flip (`$B3A1`) never in the case's recordings; in the experiment f1c at frame 510 (docs 10.10).

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 4,831,390 t-states own (1.63 %) |
| Called from | `MainMenu` |
| Calls | `TestCheatKeys` |
| Reads | `$B38F` (`WaitNoKey`); `$FEFF`-`$FF00` (`work space $FEFF+`) |
| Writes | `$CFFA`-`$CFFB` (`StackSpace`) |

### `TestCheatKeys` (`$B3B8`)

**Z when CAPS SHIFT, SPACE, 1 and 0 are all held**

ORs bit 0 of the half-rows `$FEFE` (CAPS SHIFT), `$7FFE` (SPACE), `$F7FE` (1) and `$EFFE` (0) through IN A,(C): an IN from port `$FE` (see also `$8216` and `$822E`; doc 2.1 lists the reads). Witness: game 70, w1 12, f1 12, p2 21, v1 30, m1 176.

| | |
| --- | --- |
| Runs (the first recording's game window) | 70 calls, 8,260 t-states own (0.00 %) |
| Called from | `WaitNoKey` |
| Ports in | `$7FFE`, `$EFFE`, `$F7FE`, `$FEFE` |

### `RedefineKeys` (`$B3D2`)

**"R": ask for the left, right and fire keys, store their K-TEST codes**

RedefinePrompt `$B3F3` with PromptLeft `$B407`, PromptRight `$B426`, PromptFire `$B445` into LeftKey `$B8BE`, RightKey `$B8BF`, FireKey `$B8C0`; ShowKeys; back to MenuKeys. Witness: m1 2 (frames 5462-5860, Q W P, then M, SYMBOL SHIFT, SPACE again; screens m1 frames 5550, 5860).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RedefinePrompt` (`$B3F3`)

**Print the prompt at HL, wait for no key, then for a key: A = its K-TEST code**

Any key is taken, CAPS SHIFT alone (`$27`) and SYMBOL SHIFT alone (`$18`) too. Witness: m1 6, frames 5462-6090.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowKeys` (`$B605`)

**Fill the key names into KeysLine and print it**

KeyName `$B626` for LeftKey to `$B668`, RightKey to `$B672`, FireKey to `$B67B`, then KeysLine `$B65F` through `$9E65` (a jump). The default line: "left='m' right=s/s fire=' '". Witness: game 2, w1 2, f1 2, p2 2, v1 2, m1 6 (frames 4506-8004).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 280 t-states own (0.00 %) |
| Called from | `MainMenu` |
| Calls | `PrintText` (tail), `KeyName` |
| Reads | `$B8BE`-`$B8C0` (`Players`) |

### `KeyName` (`$B626`)

**Three characters at HL naming the K-TEST code A**

`$0D` "ent", `$18` "s/s" (SYMBOL SHIFT), `$27` "c/s" (CAPS SHIFT), else the character in quotes, letters lower-cased (+`$20`). Witness: game 6 (`$B63C` 4 quoted, `$B64D` 2 s/s); m1 18; "ent" and "c/s" by no recording.

| | |
| --- | --- |
| Runs (the first recording's game window) | 6 calls, 642 t-states own (0.00 %) |
| Called from | `ShowKeys` |
| Writes | `$B668`-`$B67D` (`KeysLine`) |

### `VariationsPage` (`$B67E`)

**"V": the variations page; S / 1 / 2 choose, B begins, M back to the menu**

Clears the pixels (the attributes stay), prints VariationTexts `$B731`, ticks the variation (TickVariation `$B71E`), then like MenuKeys: MenuTimeout 1500, Kempston fire polled, a key a frame: S Variation 0, 1 variation 1, 2 variation 2 (ticks moved), B returns (the game begins), M MainMenu; another key with a joystick asks `$8106` for fire. Note `$B6BC` loops while KEY-SCAN reports more than two keys.

Witness: v1 2 (frames 622-2595), m1 1 (5102-5372); screens m1 frame 5190, v1 frame 700.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TickVariation` (`$B71E`)

**XorTick at the row of Variation: 4 (standard), 7 (1), 11 (2)**

Witness: v1 6, m1 7.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `XorTick` (`$B89C`)

**XOR a tick at the left of text row A (x 5, y 8 A + 4)**

Two one-pixel steps down-right, then seven up-right (XorLine `$93B3`, length 1). Drawing twice erases: the menus move a tick by drawing it at the old row and the new. Witness: game 6, w1 6, f1 6, p2 8, v1 12, m1 39.

| | |
| --- | --- |
| Runs (the first recording's game window) | 6 calls, 2,520 t-states own (0.00 %) |
| Called from | `MainMenu` |
| Calls | `XorLine` |

## presents

`src/game/presents.asm`

### `PresentsPage` (`$B8C5`)

**The presents page and the attract loop: banner, "presents", OCP to POOL, "video", the signature, "press any key"**

Saves SP in PresentsSP `$BD09` (the abort target of PresentsFrame `$B91B`), draws the banner (BannerRollIn `$B96C`), prints "presents" (PresentsTexts `$B936`, row 16 column 12) for 75 frames, blanks it, flips the letters (LogoFlip `$BB13`), slides in "video" (VideoSlideIn `$BC9E`), waits 50 frames, runs the pen (SignatureWrite `$BD0C`), waits 25 frames, prints "press any key to continue." (row 23) and waits 500 frames (PresentsLongWait `$B90F`). Then, if PresentsDone `$BD0B` is zero (the first call, from GameStart `$8000`, which sets it to `$FF` only after the return), it starts again at once; otherwise it calls `$A8FD`, waits 500 frames more and starts again.

Called by GameStart `$8000` (`$800B`) and by the menu (`$B293` after its timeout, `$B67E`). Returns only through a key (PresentsAbort `$B931`). Witness (l1sum.py B8C5): entered in every build; game 5556-6051 (a key on "presents" at 6051), f1 / p2 / v1 0-494, w1 twice (0-494 and the attract after the menu's timeout at 16 160-16 377), m1 0-4129 with two complete loops (the 500-frame wait PresentsLongWait ran at 1237 and 3474, then JP back, since PresentsDone was 0); the `$A8FD` branch (`$B906`) ran in no build.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 2,360 t-states own (0.00 %) |
| Called from | `GameStart` |
| Calls | `PrintText`, `PresentsFrame`, `BannerRollIn`, `LogoFlip` |
| Writes | `$BD09`-`$BD0A` (`PresentsSP`) |

### `PresentsLongWait` (`$B90F`)

**Wait 500 frames, a key aborts**

500 calls of PresentsFrame `$B91B` (BC = 500). m1 ran it twice (frames 1237 and 3474, 1000 loop passes); no other build reached the end of the sequence.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PresentsFrame` (`$B91B`)

**Wait one frame (HALT); a key returns from PresentsPage to its caller**

HALT, then the ROM's KEY-SCAN `$028E` and K-TEST `$031E`: no key (Z and K-TEST `$FF`) returns with all registers kept; a key (or more than two keys, NZ from KEY-SCAN) reloads SP from PresentsSP `$BD09` and RETs, which returns from PresentsPage `$B8C5` to the caller that saved it. Used by every wait of the attract sequence (BannerRollIn, LogoFlip, VideoSlideIn and the pen's steps in SignatureCommand `$BD23`).

Witness: game 499 calls 5559-6060, w1 1084, m1 4353 (2-4500); the abort PresentsAbort ran once in every build (game 6051 / 6060, w1, f1, p2, v1 at 494-500, m1 at 4500, the SPACE of tests/inputs/m1.txt).

| | |
| --- | --- |
| Runs (the first recording's game window) | 499 calls, 25,191,067 t-states own (8.47 %) |
| Called from | `PresentsPage`, `BannerRollIn`, `LogoFlip` |
| Reads | `$B91C` (`PresentsFrame`); `$BD09`-`$BD0A` (`PresentsSP`) |
| Writes | `$CFF8`-`$CFFB` (`StackSpace`) |

### `BannerRollIn` (`$B96C`)

**Clear the screen and roll the magenta OCP banner in from the left, row by row (417 frames)**

Clears the display file, border white (OUT `$07`), attributes `$38` (black on white), rows 4-12 `$3B` (magenta ink). Then the banner: HL is the x of the moving row as a signed 16-bit number, starting at -240 off the left edge; B is the pixel line of the top moving row (from 32), DE the run-length row of BannerData `$BA86`. Each frame (PresentsFrame `$B91B`) it calls BannerDrawRows `$B9E0` and moves x 4 pixels right; when the top row reaches x 8 its line is done: B goes one line down, every second line DE moves to the next data row (each data row is two pixel lines), and x goes back 20 pixels for the row below. It ends at line 104 (`$68`), 72 lines (36 data rows), and sets the attribute `$7B` (bright) on rows 4-12, columns 1-30.

Witness (l1sum.py B96C B9E0): 1 call per presents page, game 5556-5976; BannerDrawRows 417 calls each (game 5560-5976). WALKTHROUGH 6.1 m1 frame 300 shows the staircase of rows half way in.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 269,092 t-states own (0.09 %) |
| Called from | `PresentsPage` |
| Calls | `PresentsFrame`, `BannerDrawRows` |
| Reads | `$4000`-`$5AFE` (screen); `$BA86`-`$BB11` (`BannerData`) |
| Writes | `$4000`-`$5AFF` (screen); `$CFFA`-`$CFFB` (`StackSpace`) |
| Ports out | `$07FE` |

### `BannerDrawRows` (`$B9E0`)

**Move every row from line B downwards that is on screen: 4 pixels right**

For the line B and each line below (x 20 pixels further left each, DE advancing every second line as in BannerRollIn `$B96C`): BannerRowEdges `$BA0A`, while the row's x is within -256..255 (H = 0 or `$FF`) and the line is above 104. Registers kept. game 417 calls, 4748 rows (BannerRowEdges).

| | |
| --- | --- |
| Runs (the first recording's game window) | 417 calls, 885,472 t-states own (0.30 %) |
| Called from | `BannerRollIn` |
| Calls | `BannerRowEdges` |

### `BannerRowEdges` (`$BA0A`)

**One banner row 4 pixels right: XOR a block at the start and one at the end of each ink run**

DE = the row's runs in BannerData `$BA86`, HL = x, B = the line. For each run byte (bit 7 = ink, bits 0-6 = half the length): an ink run gets BannerEdgeBlock `$BA31` at x and at x + length, which clears the 4 pixels the run leaves and sets the 4 it enters (the row was drawn 4 pixels to the left on the frame before). Runs until the lengths add up to 240 pixels (C counts down from `$F0`). game 4748 calls, 18 476 runs.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4,748 calls, 2,749,652 t-states own (0.92 %) |
| Called from | `BannerDrawRows` |
| Calls | `BannerEdgeBlock` |
| Reads | `$BA86`-`$BB12` (`BannerData`) |

### `BannerEdgeBlock` (`$BA31`)

**XOR the 4-pixel block at x (HL signed) on line B, if x is on screen**

HL = x (signed), B = the line. x 0-255: BannerXorBlock `$BA54` at x; x -4..-1: the block is drawn as far as it reaches onto the screen (x + 4 with B = that count). Registers kept. game 21 112 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 21,112 calls, 2,885,510 t-states own (0.97 %) |
| Called from | `BannerRowEdges` |
| Calls | `BannerXorBlock` |

### `BannerXorBlock` (`$BA54`)

**XOR 4 pixels (a nibble) at x E, line D: B = 0 draws nothing**

The screen byte from PresentsPixelAddress `$BA6C`, XORed with `$F0` when x AND 7 is 0 and `$0F` otherwise (the banner's x is always a multiple of 4). game 10 127 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 10,127 calls, 1,097,387 t-states own (0.37 %) |
| Called from | `BannerEdgeBlock` |
| Calls | `PresentsPixelAddress` |
| Reads | `$4080`-`$409E` (screen); `$4180`-`$46FE` (screen); `$4900`-`$4A9E` (screen); `$4B00`-`$4B9E` (screen); `$4C00`-`$4C9E` (screen); `$4D00`-`$4D9E` (screen); 2 more ranges |
| Writes | `$4080`-`$409E` (screen); `$4180`-`$46FE` (screen); `$4900`-`$4A9E` (screen); `$4B00`-`$4B9E` (screen); `$4C00`-`$4C9E` (screen); `$4D00`-`$4D9E` (screen); 2 more ranges |

### `PresentsPixelAddress` (`$BA6C`)

**HL = the display-file address of pixel line H, x L (the byte; the caller adds the line within the cell)**

H = y, L = x in: L = (y AND `$38`) * 4 + x / 8, H = `$40` + (y AND `$C0`) / 8. The caller adds y AND 7 to H. Used by BannerXorBlock `$BA54` and VideoSlideIn `$BC9E`. game 9808 calls; the same code as PenPixelAddress `$BFB2`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 9,808 calls, 1,049,456 t-states own (0.35 %) |
| Called from | `BannerXorBlock` |

## attract

`src/game/attract.asm`

### `LogoFlip` (`$BB13`)

**Turn the banner's OCP into POOL: 20 steps narrowing O, C, P, then 20 steps widening P, O, O, L**

Step C 0-19 with B = 0: FlipLetter `$BB74` for O at x 63, C at x 127, P at x 191 (line 47, DE = `$2F3F` / `$2F7F` / `$2FBF`), one frame each (PresentsFrame `$B91B`). Then C 20 down to 1 with B = 1 (widening): P at x 41, O at 101, O at 161, L at 221.

Witness (l1sum.py BB13 BB17 BB42): once per presents page; game 6051-6059 (7 narrowing steps, then the key), w1 2 runs (494- and 16 323), m1 3 runs of 20 + 20 steps (494-4055). WALKTHROUGH 6.1: m1 frame 300 shows OCP, frame 900 POOL.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 1,033 t-states own (0.00 %) |
| Called from | `PresentsPage` |
| Calls | `PresentsFrame`, `FlipLetter` |

### `FlipLetter` (`$BB74`)

**One step of one letter: FlipEdge for each edge record of the list at IX, relative to D (line), E (x centre)**

IX = a letter's list of 3-byte records (dx, dy, kind) ending `$FF`; B = the phase (0 narrowing, 1 widening), C = the step. For each record: E + dx, D + dy and kind + phase go to FlipEdge `$BC11`. Registers kept but IX. game 210 records, m1 4800.

| | |
| --- | --- |
| Runs (the first recording's game window) | 18 calls, 41,562 t-states own (0.01 %) |
| Called from | `LogoFlip` |
| Calls | `FlipEdge` |
| Reads | `$BB98`-`$BBFA` (`FlipLetterO`) |

### `FlipEdge` (`$BC11`)

**XOR the strip an edge moves by between step C and the next on four lines (D-2, D-1, D+2, D+3)**

E = the letter's centre x, D = the stripe line, B = kind + phase, C = the step. Bit 3 of B: both widths (FlipEdge again with bit 2 set, then clear). Otherwise the width w = FlipWidths16 `$BC74` [C] (or FlipWidths24 `$BC89` with bit 2), compared with the entry after it (phase 0) or before it (phase 1); no change, nothing drawn. The strip of |difference| pixels is placed left (bit 1 clear) or right of the centre at the edge's position and XORed by the span routine `$93B3` (B = length) on the lines D-2, D-1, D+2 and D+3: the two two-line stripes of one letter row.

Witness: game 432 calls, w1 3628, m1 10 020 (6052-4055).

| | |
| --- | --- |
| Runs (the first recording's game window) | 432 calls, 83,158 t-states own (0.03 %) |
| Called from | `FlipLetter` |
| Calls | `XorLine` |
| Reads | `$BC74`-`$BC8F` (`FlipWidths16`) |

### `VideoSlideIn` (`$BC9E`)

**Print "video" above the banner, letters 16 pixels wide sliding into their cells 2 pixels a step**

Eight steps C = 7..0, three frames each (PresentsFrame `$B91B`). Each step prints the five letters of VideoText `$BD04` at line 24 (`$18`), x 8 + 24 i: each font row (Font `$DEF4`, letter - 'a') doubled to 16 bits, shifted left by 2 C bits, written as two screen bytes over the old ones (no XOR), so each letter enters its cell from the right.

Witness (l1sum.py BC9E BCA0): w1 once (16 323-16 347), m1 three times (581-4079); in game, f1, p2, v1 a key came first.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## signature

`src/game/signature.asm`

### `SignatureWrite` (`$BD0C`)

**Run the pen script SignatureScript: "written by" and James Hutchby's signature, one pen step a frame**

Pen up (PenIsDown `$C03F` = 0), PenBand `$C03E` = 0, IX = SignatureScript `$DA80`, the pen at x 16, y 128 (DE = `$8010`), PenDraw `$BE2F`, then SignatureCommand `$BD23` until the end command, which drops this loop's return address and leaves through PenErase `$BE40` back to PresentsPage `$B8C5`.

Witness (l1sum.py BD0C BD23 BE05): m1 only, 3 runs (655-4498), 828 commands and 1484 steps: two whole scripts (312 commands, 557 steps each, by the decoder in 05-editor-notes.md) and a third cut by the SPACE at 4500. WALKTHROUGH 6.1: m1 frame 900 (the pen after "written by"), 1500 (the signature done).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SignatureCommand` (`$BD23`)

**One command of the pen script at IX: end, pen up, pen down, dot, or a move of n steps**

Byte b at IX. High nibble zero, a command (IX + 1): 0 end (pops the caller's return, JP PenErase `$BE40`), 1 pen up (PenIsDown `$C03F` = 0), 2 pen down (= 1), 3 dot: the next two bytes dx, dy (signed) are added to the pen point for one PenPlot `$BF59` (the dot of an i, a full stop), the point does not move; 4-15 do nothing (SigCmdOther, never run). High nibble not zero, a move (IX + 1): bits 7-6 dy, bits 5-4 dx (each 0, +1, -2, -1 by sign extension; the script uses 0, +1, -1), bits 3-0 n steps. Each step: one frame (PresentsFrame `$B91B`, a key aborts), PenErase, PenStep `$BE05` (plot at (x, y - 1) if the pen is down, then x + dx, y + dy), PenDraw.

The band test: with the pen's y at 96 or more (the whole script keeps the pen at y 121-147) the step is plain. For y below 96 other paths slow the pen down: y 40-95 (`$28-$5F`) through PenDraw, PenDelay `$BE24` and PenErase, y below 40 through SigBandSlow (PenDelay) and PenBand `$C03E` records the pen leaving the band (1 above, 2 below) for a pause (SigBandExitAbove, a 300-loop wait) on the next move: no build ran any of them (SigBandBelow .. SigBandSlow, l1sum.py: not executed); known only from the code.

Witness: m1 828 calls (655-4499) = two whole scripts of 312 commands (218 moves, 30 pen up, 30 pen down, 33 dots, the end) and 204 of the third, cut by a key; 582 moves (SigMove), 1485 step frames.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenStep` (`$BE05`)

**One step of the pen: plot (E, D - 1) if the pen is down, then D + H, E + L; C - 1**

C = the steps left, H / L = dy / dx. With PenIsDown `$C03F` set, PenPlot `$BF59` at (x, y - 1), the pixel just above the nib's tip. B = 1: one step per call. m1 1484 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenDelay` (`$BE24`)

**A busy wait of 900 loops (the band's slow step; never run)**

Called from SigBandSlow `$BDF4` only; no build ran it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenDraw` (`$BE2F`)

**Draw the pen at (E, D): spans OR, shaft copied**

Writes JR 0 at PenShaftBlock `$BEDC` (copy path) and OR (HL) (`$B6`) into PenSpanOp1-3 (`$BF93`, `$BFA1`, `$BFAE`), then PenRender `$BE50`. m1 1487 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenErase` (`$BE40`)

**Erase the pen at (E, D): spans XOR, shaft cleared**

Writes JR `$63` at PenShaftBlock `$BEDC` (to PenShaftClear `$BF41`) and XOR (HL) (`$AE`) into PenSpanOp1-3, then PenRender: PenShape `$BE5A` with HL, BC, DE kept. m1 1486 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenShape` (`$BE5A`)

**The pen's three parts at (E, D): nib spans, shaft from (E + 5, D + 10), cap spans**

PenSpans `$BE79` with PenNib `$BFCC`; returns at once if x + 5 passes 255 or y + 10 reaches 192; PenShaftPos `$C040` = (x + 5, y + 10), PenShaft `$BE9F`; then PenSpans with PenCap `$BFEB`. m1 2973 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenSpans` (`$BE79`)

**Draw the span list at HL relative to (E, D): records dx, dy, length, `$FF` end; clipped right and bottom**

Each record: the span at (x + dx, y + dy) of the given length by PenSpan `$BF66` (OR or XOR as set), the length cut at the right edge; a span past the bottom (y 192) or past x 255 ends the list. m1 5946 calls, 40 732 spans.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenShaft` (`$BE9F`)

**The pen's shaft: 44 lines down-right from PenShaftPos, in blocks that end on character-cell lines**

From PenShaftPos `$C040`: blocks of up to 8 lines (the first to the end of its character row), each by PenShaftBlock `$BEDC`; x and y both advance by the block's lines (45 degrees); stops at the bottom of the screen or when x wraps. 44 lines in all (`$2C`). m1 2973 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenShaftBlock` (`$BEDC`)

**B lines of the shaft at PenShaftPos: copy from PenShaftImage (draw) or zero them (erase), self-modified**

The JR at `$BEDC` is the switch: displacement 0 (PenDraw) runs the copy, `$63` (PenErase) jumps to PenShaftClear `$BF41`. Copy: HL = PenShaftImage `$BFFE` + 4 (x AND 7), DE the screen; the bytes to copy are 1-4 (fewer at columns 29-31: the bytes left to the right edge, at most 3, plus one), written as 16 times (that count - 1) into the displacement of the JR at PenShaftJump `$BF01`, which lands on PenShaftCopy1-4 (`$BF03`, `$BF13`, `$BF23`, `$BF33`). Each line takes the next 4-byte row of the image (the shaft moves one pixel right a line). m1 18 215 calls; only PenShaftCopy4 ran (the pen never came near the right edge).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenShaftCopy2` (`$BF13`)

**The shaft copy, two bytes a line (a target of PenShaftJump; never run)**

LDI twice, DE back, the next screen line, the next image row; DJNZ. No build ran it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenShaftCopy3` (`$BF23`)

**The shaft copy, three bytes a line (never run)**

As PenShaftCopy2 `$BF13` with three LDIs. No build ran it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenShaftCopy4` (`$BF33`)

**The shaft copy, four bytes a line**

PUSH DE, four LDIs, POP DE, INC D; DJNZ. m1 64 168 lines.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenShaftClear` (`$BF41`)

**Erase B lines of the shaft: zero the bytes up to the right edge (1-4)**

The target of PenShaftBlock's JR `$63` when PenErase set it. m1 9105 calls, 64 128 lines.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenPlot` (`$BF59`)

**Plot one pixel at (E, D) with OR (sets PenSpan's mode to OR, B = 1)**

Writes OR (HL) into PenSpanOp1-3 and falls into PenSpan `$BF66` with one pixel. Called by PenStep `$BE05` and the dot command SigCmdDot `$BD4C`; m1 1105 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenSpan` (`$BF66`)

**A horizontal span of B pixels at (E, D), ORed or XORed by the self-modified PenSpanOp1-3**

Builds the left partial byte, the full bytes and the right partial byte; the NOPs at PenSpanOp1 `$BF93`, PenSpanOp2 `$BFA1` and PenSpanOp3 `$BFAE` hold OR (HL) or XOR (HL) (PenDraw / PenErase / PenPlot). m1 41 837 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PenPixelAddress` (`$BFB2`)

**HL = the display-file address of line H, x L (the same code as PresentsPixelAddress `$BA6C`)**

m1 60 112 calls (PenShaft, PenSpan).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## editor

`src/game/editor.asm`

### `EditorStart` (`$C042`)

**The editor's screen and its cursor loop: move the cursor, fire on a ball or a button**

Entered from the menu (`$B293`, through a JP after a CALL: the POP HL drops that return). Keeps the input mode `$B8BD` in EditorSavedMode `$C590` and sets mode 3 (cursor keys) when it was 0 (keyboard). Clears the screen (border white, BORDCR `$38`; attributes `$39` on rows 0-5 and 23, `$60` on rows 6-22), draws the table (`$9243`), blanks rows 2-5 columns 18-31, prints "- editor -", "play", "reset" (EditorTexts `$C54E`) and boxes the two buttons (EditorBox `$C1BE`: x 148-187 and 204-251, lines 20-35). With no object ball on the table the balls are racked (`$9D2C`); the balls are drawn (`$9520`); with the cue ball off the table it is respotted (`$9F4E` = `$FFFF`, `$93FF`). The cursor goes to (128, 115) (EditorCursorHome) and is drawn (`$9371`).

The loop (EditorLoop, one HALT a pass): ReadInput `$8106`; fire with BREAK leaves (EditorExit `$C414`); fire goes to EditorFire `$C20B`; a direction moves the cursor by the speed in EditorCursorSpeed `$C58D` (EditorCursorLeft / Right / Up / Down: x 3..252, y 18..180). The speed: 1 pixel a frame for 15 frames, then one more every 16 frames up to 5; it starts again at 1 when the input changes, is released or the cursor does not move.

Witness (l1sum.py C042 C116 C196 C20B C414): m1 only: entered at 6262, the loop 6271-6830, 30 passes each of left (6600-6629), down (6640-6669), up (6680-6709), right (6720-6749), fire 110 passes (6420-6769, no ball in reach), BREAK at 6830 (EditorExit).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorCursorLeft` (`$C196`)

**Cursor x - speed, not under 3**

L = x, B = the speed. m1 30 calls (6600-6629).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorCursorRight` (`$C1A1`)

**Cursor x + speed, not over 252**

m1 30 calls (6720-6749).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorCursorUp` (`$C1AC`)

**Cursor y - speed, not under 18 (the buttons' line is reachable, the cushion is at 51)**

m1 30 calls (6680-6709).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorCursorDown` (`$C1B5`)

**Cursor y + speed, not over 180**

m1 30 calls (6640-6669).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorBox` (`$C1BE`)

**XOR a rectangle's outline: E, D = left, top; L, H = right, bottom**

Four span calls (`$93B3`). EditorStart draws the button frames with it: play x 148-187, lines 20-35; reset x 204-251. m1 2 calls (6270).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorInBox` (`$C1F1`)

**Z if the cursor is strictly inside the box E, D - L, H (E < x < L, D < y < H)**

The cursor: x `$86BA`, y `$86BB`. Play box: x 149-186, y 21-34; reset box: x 205-250, y 21-34. m1 220 calls (two per fire pass), never inside.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorFire` (`$C20B`)

**Fire: "play" or "reset" when the cursor is on them, else pick up the ball under the cursor and move it**

Play box (EditorPlay `$C41D`), reset box (EditorReset `$C532`), else the first ball record in order cue, 1-6 (data at `$8A88`, 14 bytes each) with |x - cursor x| < 5 and |y - cursor y| < 5 on the whole-pixel bytes +1 / +3, on the table or not (a potted ball sits at y 27, x 7 + 24 n: in the cursor's reach). No ball: back to the loop.

EditorPickBall: EditorPickedBall `$C58F` = the ball, a beep (BEEPER 1000, 20), the cursor erased. A ball off the table is erased from the potted row, put at (128, 115) and shifted sideways (129, 126, 131, 124 ...) while a ball on the table is closer than 16 pixels in x and in y, then flagged on the table (+13 = `$80`) and drawn. EditorWaitRelease `$C401` waits for fire to go up.

EditorBallLoop (one HALT a pass): fire puts the ball down (EditorDropBall: a beep, the cursor at the ball, wait for fire up, back to the cursor loop); a direction sets the ball's velocity high bytes (+5 x, +7 y) to +/- the speed in EditorBallSpeed `$C58E` (the same acceleration as the cursor), fractions and the other velocity zero, and runs one physics step `$8701` for it (B holds the speed there, not the ball counter of the physics loop), clears `$9F50`, keeps the cue ball out of the potted path (+13 bit 5 cleared), moves the cursor with it and redraws it (`$8297`). When the step took the ball off the table (potted): a beep and back to the cursor loop.

Witness: m1 110 calls (6420-6769), every one without a ball in reach. e1 (stage 2, the editor recording): 2 calls (frames 700 and 840); at 700 EditorPickBall picks ball 1 of the rack (EditorFindBall twice: the cue ball, then ball 1), EditorHoldBall `$C2F4` entered at 702, EditorBallLoop 57 passes, EditorBallMove 20 (frames 720-739), EditorDropBall once; at 840 the play box. The off-table placement EditorPlaceBall `$C288` and EditorOverlapLoop ran in no build (known only from the code).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorBallLeft` (`$C3EB`)

**Ball x velocity -speed (+5)**

e1: 20 runs, frames 720-739 (key 5 held 20 frames: ball 1 from x 190 to 170).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorBallRight` (`$C3F2`)

**Ball x velocity +speed**

No build runs it (known only from the code, the twin of EditorBallLeft).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorBallUp` (`$C3F6`)

**Ball y velocity -speed (+7)**

No build runs it (known only from the code).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorBallDown` (`$C3FD`)

**Ball y velocity +speed**

No build runs it (known only from the code).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorWaitRelease` (`$C401`)

**Wait until fire is up (ReadInput in a loop); BREAK leaves the editor**

BREAK (bit 5 of InputState `$827C`) drops the return and goes to EditorExit `$C414`. e1: 3 entries (frames 702-844), 60 passes; its BREAK exit ran in no build.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorExit` (`$C414`)

**Leave the editor: the saved input mode back, restart at the menu (`$80B0`)**

`$B8BD` = EditorSavedMode `$C590`, JP `$80B0` (BreakRestart). m1 once, frame 6830 (CAPS SHIFT + SPACE).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorPlay` (`$C41D`)

**"play": blank the editor's texts, restore the input mode, start the aim on the edited table**

A beep, DI, the cursor erased, "- editor -" blanked (EditorTitleBlank `$C56D`), rows 2-4 columns 18-31 blanked, wait for fire up; `$B8BD` = EditorSavedMode; `$9395`, the power word `$86BF` = 0, EditorAimReset `$C502`, `$8539`; installs EditorAimTasks `$C518`, SoundRequest `$827D` = 0, EI and JP `$8069` (the foreground sound loop): the editor's game runs on tasks from here. e1: once, frame 840 (the screen at 878: texts gone, power box, cursor at (252, 115)).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorShotEnd` (`$C46E`)

**Task of the rolling list: all object balls down = back to the menu; all balls stopped = aim again**

With no object ball on the table: ClearTasks `$91CF`, then up to 150 frames (HALT, ReadInput) until fire or any key, then `$80B0` (the menu). Otherwise, when no ball moves (+13 AND `$70` zero for all seven): removes EditorRollTasks `$C528`, respots the cue ball when it is off the table (`$93FF`), EditorAimReset `$C502`, `$8539`, installs EditorAimTasks `$C518`. e1: 140 runs, frames 915-1054; the balls stopped at 1054 and the aim came back (EditorAimReset's second entry); the all-potted way to the menu (EditorShotEndWait `$C488`) ran in no build (known only from the code; its address is in EditorRollTasks).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorPower` (`$C4D6`)

**Task of the aim list: fire held grows the power by 2 (wrap at `$86`); released with power: shoot**

Power `$86BF` + 2 per frame while fire is held, back to 0 at `$86` (as AimPower `$8506`). Released with power not 0: the cursor erased, EditorAimTasks removed, `$84C7`, the aim `$8A02` (the shot's velocity), EditorRollTasks installed. e1: 378 runs, frames 845-1367 (the shot released at 908, a second aim from 1054).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorAimReset` (`$C502`)

**Input state 0, the cursor at (252, 115) and drawn**

`$827C` and `$86BE` = 0, CursorX/Y `$86BA` = (252, 115), `$86BC` = 0, JP `$9371`. e1: 2 entries, frames 844 and 1054.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditorReset` (`$C532`)

**"reset": rack the balls (the start positions `$9D5D`) and put the cursor home**

A beep, the cursor erased, HALT, the balls erased (`$9520`), racked (`$9D2C`), drawn (`$9520`), wait for fire up, JP EditorCursorHome `$C102`. No build runs it (known only from the code: e1 hit play, not reset).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## devleftover

`src/game/devleftover.asm`

### `DevFreeCount` (`$E014`)

**Development leftover: count the zero bits of the bitmap at `$5100` (`$51CC` + 35 bytes), store (n + 2) / 4**

Starts mid-routine (BIT 5,(IY+4), POP BC without a PUSH). DE = the number of 0 bits in (`$51CC`) + 35 bytes from `$5100` (SCF / RRA until `$FF`); then CALL `$44C1` and the count + 2, divided by 4, stored at (HL). Never executed or read in any build (l1sum.py --reads E014-E1A7).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DevCompareChar` (`$E056`)

**Development leftover: compare A with (HL), letters case-folded (RES 5 from "A" up)**

Never executed.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DevResultC` (`$E05E`)

**Development leftover: A = C with Z set (LD A,0; OR A; LD A,C)**

Never executed.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DevIsAlnum` (`$E063`)

**Development leftover: carry clear for 0-9, A-Z (the `$50A4` of the second piece)**

Never executed.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DevLookup` (`$E071`)

**Development leftover: find the name at DE in the table at BC (8-byte entries, 0 end); C = index, DE = the word at +6**

Compares the first character, then DevMatchName `$E088` for five more (a name ends at CR, `$03` or a non-alphanumeric character, padded with spaces). Never executed.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DevMatchName` (`$E088`)

**Development leftover: the rest of a table name (5 characters); found: DE = the entry's word, Z**

Never executed.

| | |
| --- | --- |
| Runs | not reached in the recordings |
