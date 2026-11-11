# 11. Data reference

Every data entry of the game image `$8000`-`$E1A7`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/game`, local and not in the repository), and, marked
"(code)", the routines whose `LD` through `(nn)` reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## input

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$811B` | `InputHandlers` | 8 | The four readers by the control choice `$B8BD`. Read by ReadInput: `$811B`/`$811C` in every build, `$811D`/`$811E` in j1, `$811F`/`$8120` in m1 and j1, `$8121`/`$8122` in m1. | `ReadInput` | - |
| `$8254` | `KeyTable` | 40 | The 40 keys by half row, from the outer key in: the character each one stands for. Read by KeyDown (CPIR) and by the menu's key-name code. Characters: CAPS SHIFT = `$27`, ENTER = `$0D`, SPACE = `$20`, SYMBOL SHIFT = `$18`, else the key's capital letter or digit. The rows are the ports `$FEFE` (CAPS Z X C V), `$FDFE` (A S D F G), `$FBFE` (Q W E R T), `$F7FE` (1 2 3 4 5), `$EFFE` (0 9 8 7 6), `$DFFE` (P O I U Y), `$BFFE` (ENTER L K J H), `$7FFE` (SPACE SYMBOL M N B). Stage 1's signature candidate at `$8240` was this table. | `KeyDown` | - |
| `$827C` | `InputState` | 1 | The controls this interrupt: bit 0 right, 1 left, 2 up, 3 down, 4 fire, 5 BREAK. Written by ReadBreak (every pass of ReadInput), cleared by AimCursorReset `$85C8` and the editor (`$C504`). Read by SoundLoop (BREAK), AimPower `$8506` (fire), AimCursorMove `$8546`, the hall-of-fame entry (`$AEBF`...), the menu (`$B2A7`...) and the editor (`$C11E`...). | `AimCursorMove`, `AimPower`, `SoundLoop`, `WaitFramesOrKey`, `EditorFire` (code) +7 | `AimCursorReset`, `ReadBreak`, `EditorAimReset` (code) |
| `$827D` | `SoundRequest` | 1 | The sound SoundLoop plays: 0 none, 1 ball, 2 cushion, 3 pocket. Written by the physics (`$8993` = 1, `$8DC0` / `$8DF4` / `$8E28` = 2, `$8C17` = 3), cleared by GameRestart, SoundLoop, StopShotTasks, ShotReset and the editor (`$C467`). See SoundLoop. | `SoundDelay`, `SoundLoop` | `GameRestart`, `ReflectX`, `ReflectY`, `ShotReset`, `SoundLoop` +5 |

## shot

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$84AA` | `AimTasks` | 16 | The aim's tasks, period 0 each: power, power bar, cursor move, cursor draw, input. (period, routine) triples, `$FF` ends. Installed by StartAim, removed by AimPower when the shot is played. AimPower `$8506`, the power bar `$934D`, AimCursorMove `$8546`, AimCursorDraw `$85EB`, ReadInput `$8106`. | `InstallTasks`, `RemoveTasks` | - |
| `$84BA` | `MovingTasks` | 13 | The tasks of the balls in motion, period 0 each: redraw, physics, shot end, messages. Installed by AimPower (`$8532`), removed by StopShotTasks. BallRedraw `$827E`, the physics `$86C1`, ShotEnd `$8357`, the message task `$9CB7`. | `InstallTasks`, `RemoveTasks` | - |

## aim

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$869E` | `DrawList` | 35 | The draw list: 7 entries of 4 bytes, then the cursor and the power. Written by BuildDrawList, read by BallRedraw: the ball's number, its y (the integer byte, the sort key), the record's address (2 bytes). Stage 1's "5 bytes an entry" was wrong: 7 x 4 = 28 bytes, `$869E-$86B9`. | `AimCursorDraw`, `AimCursorMove`, `AimPower`, `AimPowerReset`, `AimShot` +11 | `AimCursorDraw`, `AimCursorMove`, `AimCursorReset`, `AimPower`, `AimPowerReset` +8 |
| `$86BA` | `CursorX` (`DrawList`+28) | 1 | the cursor's x on the cushion line, 3..252 (read with CursorY as a word) | `AimCursorDraw`, `AimCursorMove`, `AimShot`, `AimStackDy`, `DrawCursor` +3 | `AimCursorDraw`, `AimCursorReset`, `EditorAimReset` (code), `EditorFire` (code), `EditorStart` (code) |
| `$86BB` | `CursorY` (`DrawList`+29) | 1 | the cursor's y, 51..180 | `AimCursorDraw`, `AimCursorMove`, `AimStackDy`, `DrawCursor`, `EditorFire` (code) +2 | `AimCursorDraw`, `AimCursorReset`, `EditorAimReset` (code), `EditorFire` (code), `EditorStart` (code) |
| `$86BC` | `CursorSpeed` (`DrawList`+30) | 1 | the signed speed round the cushions, -6..6 (0 at rest) | `AimCursorDraw`, `AimCursorMove` | `AimCursorMove`, `AimCursorReset`, `EditorAimReset` (code) |
| `$86BD` | `CursorAccel` (`DrawList`+31) | 1 | the countdown to the next +1 of the speed (10) | `AimCursorMove` | `AimCursorMove` |
| `$86BE` | `CursorLastInput` (`DrawList`+32) | 1 | InputState at the cursor task's last change | `AimCursorMove`, `EditorFire` (code), `EditorStart` (code) | `AimCursorMove`, `AimCursorReset`, `EditorAimReset` (code), `EditorFire` (code), `EditorStart` (code) |
| `$86BF` | `Power` (`DrawList`+33) | 1 | the shot's power, 0..`$84` in steps of 2 (read with PowerHigh as the word HL) | `AimPower`, `AimPowerReset`, `PowerBarTask`, `ScaleByPower`, `EditorPower` (code) | `AimPower`, `AimPowerReset`, `NewGameScreen`, `PowerBarTask`, `EditorPlay` (code) +1 |
| `$86C0` | `PowerHigh` (`DrawList`+34) | 1 | 0: the high byte of the power word | `PowerBarTask` | `AimPowerReset`, `NewGameScreen`, `PowerBarTask`, `EditorPlay` (code) |

## physics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$89B5` | `ContactVars` | 15 | The ball-contact work variables. Written and read by BallContacts `$87EF` (w1 18 997 reads over the block). BallHitFlag `$89BB` is cleared at the shot's start (`$84C8`) and read by the end-of-shot task (`$83CD`) to tell whether any ball was hit. | `BallContacts`, `ShotEnd` | `BallContacts`, `ShotReset` |
| `$89B6` | `ContactSignsFound` (`ContactVars`+1) | 1 | the signs at the contact found | `BallContacts` (code) | `BallContacts` (code) |
| `$89B7` | `ContactRecordPtr` (`ContactVars`+2) | 1 | the low byte of the CollisionRecords pointer | `BallContacts` (code) | `BallContacts` (code) |
| `$89B8` | `ContactFound` (`ContactVars`+3) | 1 | the pointer's high byte (`$DE`), cleared before the scan: non-zero = a contact found | `BallContacts` | `BallContacts` |
| `$89B9` | `ContactOther` (`ContactVars`+4) | 2 | the other ball's record (IY), a word | `BallContacts` | `BallContacts` (code) |
| `$89BB` | `BallHitFlag` (`ContactVars`+6) | 1 | 1 = a ball was hit during this shot | `ShotEnd` | `ShotReset`, `BallContacts` (code) |
| `$89BC` | `ExchangeA` (`ContactVars`+7) | 2 | w0 dvx, 8.8 signed | `BallContacts` (code) | `BallContacts` (code) |
| `$89BE` | `ExchangeB` (`ContactVars`+9) | 2 | w2 dvy | `BallContacts` (code) | `BallContacts` (code) |
| `$89C0` | `ExchangeC` (`ContactVars`+11) | 2 | w2 dvx | `BallContacts` (code) | `BallContacts` (code) |
| `$89C2` | `ExchangeD` (`ContactVars`+13) | 2 | w1 dvy | `BallContacts` (code) | `BallContacts` (code) |

## shotsetup

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8A1A` | `AimCalcDx` | 5 | RST `$28` literals: dx and dx*dx. Read by the ROM's calculator after the RST `$28` at `$8A19` (5 bytes, game 20 reads = 4 shots). Stack in: cursor x, cue x. Out: dx, dx*dx. | - | - |
| `$8A2D` | `AimCalcDyOverR` | 16 | RST `$28` literals: dy, r = SQR (dx*dx + dy*dy), dy / r. 16 bytes read once a shot (game 64 reads). Stack in: dx, dx*dx, cursor y, cue y. Out: dx, r, dy / r. Memory 0 of the calculator holds dy. | - | - |
| `$8A45` | `AimCalcDxOverR` | 2 | RST `$28` literals: `$05` division (dx / r), `$38` end-calc | - | - |
| `$8A7A` | `ScaleByPowerCalc` | 11 | RST `$28` literals: multiply, and add 65536 to a value that is not positive. 11 bytes; the jump-true skips the stk-data and the addition for a positive product. A negative x + 65536 is its 16-bit two's complement, which FP-TO-BC returns in BC. A product of exactly 0 (the cursor on the cue ball's row or column) also gets 65536 added; FP-TO-BC then reads the float's bytes as an integer, BC = 0 with the carry set, so the component is 0 after all (known only from the ROM's code, see the notes). | - | - |

## balls

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8A88` | `BallRecords` | 98 | The seven ball records of the player at the table: cue ball, balls 1-6. 14 bytes a ball: +0/+1 x and +2/+3 y, 8.8 fixed point in screen pixels, fraction first, the centre of the ball; +4/+5 vx and +6/+7 vy, 8.8 two's complement in pixels a tick; +8 / +9 the friction steps x / y, signed bytes in 1/256 pixel a tick (FrictionSteps `$90F5`, negated by the bounces `$8DCB` / `$8DFF`, swapped by `$8D7D`); +10/+11 the screen x / y of the sprite as last drawn (x - 7, y - 7: the corner of the 16 x 16 ball); +12 the pocket the ball fell into (1 top left, 2 top middle, 3 top right, 4 bottom right, 5 bottom middle, 6 bottom left, written by PocketStore `$8BE3`, 0 = none, cleared at each shot by `$84C7`); +13 flags. +13: bit 7 on the table, bit 6 moving, bit 5 potted (fallen, waiting for the redraw `$8297` to move it to the row of potted balls and clear the byte), bit 4 to be redrawn. `$80` at rest, `$D0` rolling (moving and redrawn), `$90` = on the table and to be redrawn. Positions from `$9D5D` by `$9D2C`. Read by every build; the cue ball's x pixel `$8A89` most (w1 28 930 reads). +12 of balls 1-6 read 29-42 times in w1 (the end-of-shot test `$83DC` and the wrong-pocket test `$8C37`), +12 of the cue ball once in p2 (the turn swap). | `AimShot`, `AimStackDy`, `AimStoreVx`, `BallContacts`, `BuildDrawList` +20 | `AimStoreVx`, `AimStoreVy`, `ClearBallMotion`, `FrictionSteps`, `MoveBall` +9 |
| `$8A96` | `BallOne` (`BallRecords`+14) | 14 | ball 1 | `BallContacts`, `BuildDrawList`, `DrawAllBalls`, `DrawPottedRow`, `EraseBallsUnderBanner` +10 | `ClearBallMotion`, `ParkBalls`, `RackBalls`, `RackStep`, `ResetBallPositions` +1 |
| `$8AA4` | `BallTwo` (`BallRecords`+28) | 14 | ball 2 | `BallContacts`, `BuildDrawList`, `DrawAllBalls`, `DrawPottedRow`, `EraseBallsUnderBanner` +10 | `ClearBallMotion`, `ParkBalls`, `RackBalls`, `RackStep`, `ResetBallPositions` +1 |
| `$8AB2` | `BallThree` (`BallRecords`+42) | 14 | ball 3 | `BallContacts`, `BuildDrawList`, `DrawAllBalls`, `DrawPottedRow`, `EraseBallsUnderBanner` +10 | `ClearBallMotion`, `ParkBalls`, `RackBalls`, `RackStep`, `ResetBallPositions` +1 |
| `$8AC0` | `BallFour` (`BallRecords`+56) | 14 | ball 4 | `BallContacts`, `BuildDrawList`, `DrawAllBalls`, `DrawPottedRow`, `EraseBallsUnderBanner` +10 | `ClearBallMotion`, `ParkBalls`, `RackBalls`, `RackStep`, `ResetBallPositions` +1 |
| `$8ACE` | `BallFive` (`BallRecords`+70) | 14 | ball 5 | `BallContacts`, `BuildDrawList`, `DrawAllBalls`, `DrawPottedRow`, `EraseBallsUnderBanner` +10 | `ClearBallMotion`, `ParkBalls`, `RackBalls`, `RackStep`, `ResetBallPositions` +1 |
| `$8ADC` | `BallSix` (`BallRecords`+84) | 14 | ball 6 | `BallContacts`, `BuildDrawList`, `DrawAllBalls`, `DrawPottedRow`, `EraseBallsUnderBanner` +10 | `ClearBallMotion`, `ParkBalls`, `RackBalls`, `RackStep`, `ResetBallPositions` +1 |
| `$8AEA` | `OtherPlayerBalls` | 98 | The other player's seven ball records, same format, swapped with BallRecords on the turn change. Zero in the image. Every byte read once in p2 only (the swap `$9C0F` at frame 1738, two players), and +13 of each of the seven read once in every build (game, w1, f1, p2, v1, m1; reader not identified, see the notes). At w1 frame 1060 balls 1-6 here have +10 = 0, 24, ... 120 and +11 = 20: the sprite corners of the row of potted balls (`$82CC` puts a potted ball at x 24 (n - 1) + 7, y 27). Stage 1 read this as the potted row itself: it is the second player's set. | `ParkBalls` | `ParkBalls` |
| `$8B4C` | `FrictionTurn` | 1 | The ball whose friction steps are recomputed this tick, 0..6. Advanced mod 7 by PhysicsTask `$86C1`, compared by MoveBall `$8701` with B - 1 (6 - the ball number), cleared at the shot's start (`$84C7`). Read game 576, w1 8504. | `MoveBall`, `PhysicsTask` | `PhysicsTask`, `ShotReset` |
| `$8B4D` | `EventCount` | 1 | Bounces and contacts in this pass of PhysicsTask: cushion +1, ball +2; 7 or more repeats the pass. Cleared by PhysicsTask `$86C1`, raised by ReflectDiagonal `$8D7D`, ReflectX `$8DCB`, ReflectY `$8DFF` (+1) and BallContacts `$87EF` (+2). Never reached 7 in a recording (the repeat at `$86FB` not taken). | `PhysicsTask`, `ReflectX`, `ReflectY`, `BallContacts` (code), `ReflectDiagonal` (code) | `PhysicsTask`, `ReflectX`, `ReflectY`, `BallContacts` (code), `ReflectDiagonal` (code) |

## cushions

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8E80` | `FoulCode` | 1 | The shot's foul from the variations: 0 none, 2 wrong order, 3 wrong pocket. Written by PocketOrCushion `$8B4E` (`$8C47` = 3, `$8C68` = 2: v1 only), cleared at the shot's start (`$84CB`); read by the end-of-shot code (`$8375`, `$83BD`, `$83F1`, `$83FA`, `$8478`) and `$8C1D`: game 310, w1 2929 reads. | `MessagesTask`, `ShotEnd`, `WaitMessagesLoop`, `PocketOrCushion` (code) | `ShotEnd`, `ShotReset`, `PocketOrCushion` (code) |

## scheduler

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$91DF` | `TaskSlots` | 100 | 25 task slots: the routine (0 high byte = free), the period, the countdown. Written by AddTask, RemoveTask, ClearTasks; read by RunTasks every interrupt. | `AddTask`, `ClearTasks`, `RemoveTask`, `RunTasks` | `AddTask`, `ClearTasks`, `RemoveTask`, `RunTasks` |

## balldraw

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$95D8` | `SpritePos` | 2 | The sprite's screen position for DrawBall `$9548`: +0 x, +1 y of the top left (the ball's centre minus 7). Written before every DrawBall (from a record's +10/+11, from `$9F36`, or computed for the potted row and the lives); read by DrawBall at `$9555` / `$956A` / `$957F` / `$958E` and by DrawLives `$9AFA`. | `DrawBall`, `DrawLives` | `DrawAllBalls`, `DrawLives`, `LoseLife`, `RackBalls`, `RedrawBall` +6 |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$969D` | `HudTexts` | 73 | The HUD's text records (PrintText format: row, column, attribute, length, text). All read: NewGameScreen prints `$969D`, `$96AB`, `$96B9`, `$96BF`, `$96D4`, `$96DD`; UpBlinkTask `$96E6` alternates `$969D` / `$96A4` and `$96AB` / `$96B2`; ShotsBlinkTask `$970E` reprints `$96DD`. | `PrintText` | - |
| `$96A4` | `HudOneUpBlank` (`HudTexts`+7) | 7 | row 0, col 0, attr `$39`, 3: "   " | `PrintText` | - |
| `$96AB` | `HudTwoUp` (`HudTexts`+14) | 7 | row 0, col 23, attr `$38`, 3: "2up" | `PrintText` | - |
| `$96B2` | `HudTwoUpBlank` (`HudTexts`+21) | 7 | row 0, col 23, attr `$39`, 3: "   " | `PrintText` | - |
| `$96B9` | `HudHi` (`HudTexts`+28) | 6 | row 0, col 12, attr `$38`, 2: "hi" | `PrintText` | - |
| `$96BF` | `HudRowOneBlank` (`HudTexts`+34) | 21 | 17 spaces at (1, 0), attr `$39`: the power box | `PrintText` | - |
| `$96D4` | `HudFrame` (`HudTexts`+55) | 9 | row 1, col 17, attr `$38`, 5: "frame" | `PrintText` | - |
| `$96DD` | `HudShots` (`HudTexts`+64) | 9 | row 1, col 26, attr `$38`, 5: "shots" | `PrintText` | - |
| `$9740` | `HudLastShot` | 20 | The two halves of the "last shot" blink (PrintText records at row 1, col 26, attr `$38`, 6 characters). Printed by ShotsBlinkTask `$970E`; both read in game, w1, f1. | - | - |
| `$974A` | `HudShot` (`HudLastShot`+10) | 10 | row 1, col 26, attr `$38`, 6: "  shot" | - | - |

## gameover

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9890` | `GameOverTexts` | 37 | GAME OVER and the losing player (PrintText records, double width, attr `$60`). GameOverText read by game, w1, f1; the two player lines are not read in any build (the recordings' games over were one-player or ended by BREAK). | `PrintText` | - |
| `$989D` | `GameOverPlayer1` (`GameOverTexts`+13) | 12 | row 11, col 8, attr `$E0`, 8: "PLAYER 1" | - | - |
| `$98A9` | `GameOverPlayer2` (`GameOverTexts`+25) | 12 | row 11, col 8, attr `$E0`, 8: "PLAYER 2" | - | - |

## tally

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9B2A` | `ScoreVars` | 12 | The tally's and the turns' variables. Readers and writers: the tally routines; CurrentPlayer by the game start `$8052`, TurnSwap `$9C34` and the hall of fame `$A79C` / `$A7C2` / `$AD1C`; UpBlink by StartAim `$8432` / `$8483`; LastShotBlink `$843E` / `$849F`. | `UpBlinkTask`, `AddScoreStep` (code), `AddTerm` (code), `GameOver` (code), `MultiplyTerm` (code) +8 | `GameRestart`, `NewGameScreen`, `ScoreTally`, `StartAim`, `StopShotTasks` +8 |
| `$9B2C` | `ShotScore` (`ScoreVars`+2) | 2 | word: the shot's score (without the x 10), counted down into the player's score | `AddTerm` (code), `ScoreTally` (code), `TallyTermTotal` (code) | `ScoreTally`, `AddTerm` (code) |
| `$9B2E` | `PotMultiplier` (`ScoreVars`+4) | 1 | the pending term's pocket multiplier 1-6 | `AddTerm` (code), `PrintTerm` (code) | `ScoreTally` (code) |
| `$9B2F` | `PotBall` (`ScoreVars`+5) | 1 | the pending term's ball number 1-6 | `AddTerm` (code), `PrintTerm` (code) | `ScoreTally` (code) |
| `$9B30` | `CurrentPlayer` (`ScoreVars`+6) | 1 | 1 or 2 | `UpBlinkTask`, `AddScoreStep` (code), `GameOver` (code), `NameEntryPage` (code), `PlayerBanner` (code) +2 | `GameRestart`, `GameOverHallOfFame` (code), `TurnSwap` (code) |
| `$9B31` | `UpBlink` (`ScoreVars`+7) | 1 | 0 = print the 1up / 2up blank next, else the word | `UpBlinkTask` | `StartAim`, `StopShotTasks`, `UpBlinkTask` |
| `$9B32` | `LastShotBlink` (`ScoreVars`+8) | 1 | 0 "last", 1 "shot", `$FF` restore "shots" | `ShotsBlinkTask` (code) | `StartAim`, `StopShotTasks`, `ShotsBlinkTask` (code) |
| `$9B33` | `Player2Racked` (`ScoreVars`+9) | 1 | 0 until the second player's set was racked once (two players) | `NextTurn` (code) | `NewGameScreen`, `NextTurn` (code) |
| `$9B34` | `TallyPitch` (`ScoreVars`+10) | 2 | word: the count-up beep's BEEPER period, 1200 down by 10 a step | `AddScoreStep` (code) | `AddScoreStep` (code), `ScoreTally` (code) |

## turns

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9B8E` | `FrameBanner` | 42 | The FRAME banner and the blank line that wipes it (PrintText records; the row and column bytes are patched). Written by ShowFrameBanner (`$9B51`, `$9B5E`, `$9B7A`, `$9B85`) and NextTurn (`$9808`); read by PrintText. In the image `$9B8E` = row 11, col 9. | `PrintText` | `ShowFrameBanner`, `NextTurn` (code) |
| `$9B98` | `FrameBannerBlank` (`FrameBanner`+10) | 32 | row (patched 9 / 11), col 2, attr `$60`, 28 spaces | `PrintText` | `ShowFrameBanner`, `NextTurn` (code) |
| `$9C06` | `ShotsPerFrame` | 9 | The shots of frames 1-9: 5, 5, 4, 4, 4, 3, 3, 3, 3. Read by ShotsForFrame `$9BE6` (index frame - 1). Frames 1-4 read (w1 reached frame 4); `$9C0A-$9C0E` (frames 5-9) read by no build. | `ShotsForFrame` | - |
| `$9C8F` | `PlayerBannerTexts` | 24 | PLAYER 1 / PLAYER 2 (PrintText records). Read by PlayerBanner (p2). Wiped by ShowFrameBanner's blank of row 9. | - | - |
| `$9C9B` | `PlayerBanner2` (`PlayerBannerTexts`+12) | 12 | row 9, col 8, attr `$E0`, 8: "PLAYER 2" | - | - |
| `$9CFD` | `FoulTexts` | 47 | The three foul messages (PrintText records, double width, attr `$38`, row 3, centred). Read by MessagesTask `$9CB7` step 2. | `PrintText` | - |
| `$9D0B` | `WrongOrderText` (`FoulTexts`+14) | 16 | row 3, col 4, attr `$B8`, 12: "WRONG ORDER!" | - | - |
| `$9D1B` | `WrongPocketText` (`FoulTexts`+30) | 17 | row 3, col 3, attr `$B8`, 13: "WRONG POCKET!" | - | - |
| `$9D5D` | `StartPositions` | 14 | The rack: x, y of the cue ball and balls 1-6. (40, 115), (190, 115), (205, 106), (205, 124), (221, 98), (221, 115), (221, 132): a triangle of six with its point at ball 1. Read by ResetBallPositions; the rack scripts end on the same points (RackScripts0). | `ResetBallPositions` | - |

## printing

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9F2E` | `CopyrightGlyph` | 8 | The glyph of character `$7F`, the copyright sign (a C in a ring). Read by PrintChar's `$7F` branch (`$9E96`: game 2, m1 4; the menu's copyright line). | `PrintChar` | - |

## racking

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9F43` | `PlayerVars` | 38 | The players' scores, frames, shots, lives, the message step and the six rack script states. The pairs "current, other" (`$9F43` / `$9F44`, `$9F4B` / `$9F4C`, `$9F4E` / `$9F4F`) are swapped by TurnSwap `$9C15`; the scores stay by player. Set by NewGameScreen `$95DA`; the hi score is 300 (shown 3000) in the image, kept across games. | `DrawLives`, `GameOver`, `GameOverHallOfFame`, `LastShotBeepTask`, `LoseLife` +21 | `GameRestart`, `LoseLife`, `MessagesTask`, `NewGameScreen`, `PrintPocketMark` +11 |
| `$9F44` | `PocketTurnOther` (`PlayerVars`+1) | 1 | the other player's | `TurnSwap` (code) | `NewGameScreen`, `TurnSwap` (code) |
| `$9F45` | `ScorePlayer1` (`PlayerVars`+2) | 2 | word, score / 10 | `GameOver`, `GameOverHallOfFame`, `PrintHudNumber`, `AddScoreStep` (code), `NextTurn` (code) | `NewGameScreen`, `AddScoreStep` (code) |
| `$9F47` | `ScorePlayer2` (`PlayerVars`+4) | 2 | word | `GameOver`, `PrintHudNumber`, `AddScoreStep` (code), `GameOverHallOfFame` (code), `NextTurn` (code) | `NewGameScreen`, `AddScoreStep` (code) |
| `$9F49` | `HiScore` (`PlayerVars`+6) | 2 | word, 300 in the image | `GameOver`, `PrintHudNumber`, `NextTurn` (code) | `NextTurn` (code) |
| `$9F4B` | `FrameNumber` (`PlayerVars`+8) | 1 | the current player's frame 1-99 | `PrintHudNumber`, `RackBalls`, `ShotsForFrame`, `ShowFrameBanner`, `AddTerm` (code) +5 | `NewGameScreen`, `NextFrame` (code), `TurnSwap` (code) |
| `$9F4C` | `FrameOther` (`PlayerVars`+9) | 1 | the other player's frame | `PrintHudNumber`, `ShowFrameBanner`, `AddTerm` (code), `PrintTerm` (code), `TurnSwap` (code) | `NewGameScreen`, `TurnSwap` (code) |
| `$9F4D` | `ShotsLeft` (`PlayerVars`+10) | 1 | set by ShotsForFrame; lowered by the end-of-shot task `$83EA` | `LastShotBeepTask`, `PrintHudNumber`, `ShotsBlinkTask`, `ShotEnd` (code) | `GameRestart`, `TurnSwap`, `NextFrame` (code), `ScoreTally` (code), `ShotEnd` (code) |
| `$9F4E` | `LivesLeft` (`PlayerVars`+11) | 1 | 3 at the start; negative = out | `DrawLives`, `LoseLife`, `PrintHudNumber`, `GameOver` (code), `ShotEnd` (code) +1 | `LoseLife`, `NewGameScreen`, `EditorStart` (code), `TurnSwap` (code) |
| `$9F4F` | `LivesOther` (`PlayerVars`+12) | 1 | the other player's lives | `GameOver` (code), `TurnSwap` (code) | `NewGameScreen`, `EditorStart` (code), `TurnSwap` (code) |
| `$9F50` | `MessageStep` (`PlayerVars`+13) | 1 | MessagesTask step 0-`$50` (zeroed at each shot by `$84CE`) | `MessagesTask`, `WaitMessagesLoop`, `RedrawBall` (code), `ScoreTally` (code) | `MessagesTask`, `ShotReset`, `EditorFire` (code) |
| `$9F51` | `RackScriptState` (`PlayerVars`+14) | 24 | 6 x 4 bytes, balls 1-6: script pointer (word), wait count, move count | `RackStep` | `RackBalls`, `RackStep` |
| `$A0C4` | `RackSets` | 12 | The six rack sets: pointers to six script pointers each (balls 1-6). Read by RackBalls (`$9F83`): sets 0 and 1 read; `$A0C8-$A0CF` (sets 2-5, frames 5-12) read by no build. Set 1 `$A162` and sets 2-5 (`$A1E4`, `$A29C`, `$A38E`, `$A4F8`) are past this fragment. | `RackBalls` | - |
| `$A0D0` | `RackScripts0` | 12 | Set 0 (frames 1-2): the scripts of balls 1-6 | `RackBalls` | - |
| `$A0DC` | `RackScript0Ball1` | 134 | Ball 1: wait 75; at (7, 175); 30 x (+2, -2); 61 x (+2, 0); at (190, 115); end. The scripts of set 0 all start at a left corner pocket, (7, 175) or (7, 55), run diagonally to y 115, along the middle line, turn into their place and end exactly on StartPositions. Waits 75, 60, 45, 30, 15, 0: ball 6 rolls first. | `RackStep` | - |
| `$A0ED` | `RackScript0Ball2` (`RackScript0Ball1`+17) | 25 | ball 2: set0.ball2 | `RackStep` | - |
| `$A106` | `RackScript0Ball3` (`RackScript0Ball1`+42) | 25 | ball 3: set0.ball3 | `RackStep` | - |
| `$A11F` | `RackScript0Ball4` (`RackScript0Ball1`+67) | 25 | ball 4: set0.ball4 | `RackStep` | - |
| `$A138` | `RackScript0Ball5` (`RackScript0Ball1`+92) | 17 | ball 5: set0.ball5 | `RackStep` | - |
| `$A149` | `RackScript0Ball6` (`RackScript0Ball1`+109) | 25 | ball 6: set0.ball6 | `RackStep` | - |

## rackscripts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A162` | `RackSet1` | 12 | Rack-in set 1: the script of each object ball 1-6, the frames 3-4 rack (stage-1 w1 racked frames 3 and 4 with it). Read through the set table at `$A0C4` by the racking `$9F6F` (index ((frame - 1) / 2) mod 6, the frame from `$9F4B`): w1 read every byte of this set twice (frames 3 and 4 of its game; l1sum.py --reads A162-A1E3: w1 only, 1562 reads). No other recording reached frame 3. | - | - |
| `$A16E` | `Rack1Ball1` | 118 | The scripts of rack-in set 1, ball 1 first. The six scripts of set 1 (commands: 0 end, 1 x y place, 2 n dx dy move n frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking step `$A05E`. | - | - |
| `$A17F` | `Rack1Ball2` (`Rack1Ball1`+17) | 21 | ball 2: wait 62 frames | - | - |
| `$A194` | `Rack1Ball3` (`Rack1Ball1`+38) | 21 | ball 3: wait 62 frames | - | - |
| `$A1A9` | `Rack1Ball4` (`Rack1Ball1`+59) | 21 | ball 4: wait 90 frames | - | - |
| `$A1BE` | `Rack1Ball5` (`Rack1Ball1`+80) | 17 | ball 5: wait 0 frames | - | - |
| `$A1CF` | `Rack1Ball6` (`Rack1Ball1`+97) | 21 | ball 6: wait 90 frames | - | - |
| `$A1E4` | `RackSet2` | 12 | Rack-in set 2: the script of each object ball 1-6, the frames 5-6 rack. Reached only through the set table `$A0C4` (the word at `$A0C8`) when the racking `$9F6F` racks frame 5 or 6 (or 17-18 after the wrap). No recording read a byte (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the longest game, reached frame 4). Known only from the code; every script decodes cleanly and ends on its ball's rack position (`$9D5D`) (work/stage2/ann/04-scratch/racks.py). | - | - |
| `$A1F0` | `Rack2Ball1` | 172 | The scripts of rack-in set 2, ball 1 first. The six scripts of set 2 (commands: 0 end, 1 x y place, 2 n dx dy move n frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking step `$A05E`. | - | - |
| `$A20A` | `Rack2Ball2` (`Rack2Ball1`+26) | 30 | ball 2: wait 111 frames | - | - |
| `$A228` | `Rack2Ball3` (`Rack2Ball1`+56) | 30 | ball 3: wait 46 frames | - | - |
| `$A246` | `Rack2Ball4` (`Rack2Ball1`+86) | 30 | ball 4: wait 0 frames | - | - |
| `$A264` | `Rack2Ball5` (`Rack2Ball1`+116) | 30 | ball 5: wait 65 frames | - | - |
| `$A282` | `Rack2Ball6` (`Rack2Ball1`+146) | 26 | ball 6: wait 130 frames | - | - |
| `$A29C` | `RackSet3` | 12 | Rack-in set 3: the script of each object ball 1-6, the frames 7-8 rack. Reached only through the set table `$A0C4` (the word at `$A0CA`) when the racking `$9F6F` racks frame 7 or 8 (or 19-20 after the wrap). No recording read a byte (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the longest game, reached frame 4). Known only from the code; every script decodes cleanly and ends on its ball's rack position (`$9D5D`) (work/stage2/ann/04-scratch/racks.py). | - | - |
| `$A2A8` | `Rack3Ball6` | 230 | The scripts of rack-in set 3, ball 6 first. The six scripts of set 3 (commands: 0 end, 1 x y place, 2 n dx dy move n frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking step `$A05E`. | - | - |
| `$A2D1` | `Rack3Ball4` (`Rack3Ball6`+41) | 41 | ball 4: wait 22 frames | - | - |
| `$A2FA` | `Rack3Ball2` (`Rack3Ball6`+82) | 41 | ball 2: wait 44 frames | - | - |
| `$A323` | `Rack3Ball5` (`Rack3Ball6`+123) | 33 | ball 5: wait 11 frames | - | - |
| `$A344` | `Rack3Ball3` (`Rack3Ball6`+156) | 41 | ball 3: wait 33 frames | - | - |
| `$A36D` | `Rack3Ball1` (`Rack3Ball6`+197) | 33 | ball 1: wait 55 frames | - | - |
| `$A38E` | `RackSet4` | 12 | Rack-in set 4: the script of each object ball 1-6, the frames 9-10 rack. Reached only through the set table `$A0C4` (the word at `$A0CC`) when the racking `$9F6F` racks frame 9 or 10 (or 21-22 after the wrap). No recording read a byte (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the longest game, reached frame 4). Known only from the code; every script decodes cleanly and ends on its ball's rack position (`$9D5D`) (work/stage2/ann/04-scratch/racks.py). | - | - |
| `$A39A` | `Rack4Ball5` | 350 | The scripts of rack-in set 4, ball 5 first. The six scripts of set 4 (commands: 0 end, 1 x y place, 2 n dx dy move n frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking step `$A05E`. | - | - |
| `$A3D1` | `Rack4Ball2` (`Rack4Ball5`+55) | 57 | ball 2: wait 18 frames | - | - |
| `$A40A` | `Rack4Ball1` (`Rack4Ball5`+112) | 49 | ball 1: wait 36 frames | - | - |
| `$A43B` | `Rack4Ball3` (`Rack4Ball5`+161) | 63 | ball 3: wait 0 frames | - | - |
| `$A47A` | `Rack4Ball6` (`Rack4Ball5`+224) | 65 | ball 6: wait 18 frames | - | - |
| `$A4BB` | `Rack4Ball4` (`Rack4Ball5`+289) | 61 | ball 4: wait 36 frames | - | - |
| `$A4F8` | `RackSet5` | 12 | Rack-in set 5: the script of each object ball 1-6, the frames 11-12 rack. Reached only through the set table `$A0C4` (the word at `$A0CE`) when the racking `$9F6F` racks frame 11 or 12 (or 23-24 after the wrap). No recording read a byte (l1sum.py --reads A1E4-A701: game, w1, f1, p2, v1, m1 all zero; w1, the longest game, reached frame 4). Known only from the code; every script decodes cleanly and ends on its ball's rack position (`$9D5D`) (work/stage2/ann/04-scratch/racks.py). | - | - |
| `$A504` | `Rack5Ball1` | 510 | The scripts of rack-in set 5, ball 1 first. The six scripts of set 5 (commands: 0 end, 1 x y place, 2 n dx dy move n frames by dx,dy, 3 n wait n frames; see RackSet1). Interpreted by the racking step `$A05E`. | - | - |
| `$A553` | `Rack5Ball2` (`Rack5Ball1`+79) | 87 | ball 2: wait 44 frames | - | - |
| `$A5AA` | `Rack5Ball3` (`Rack5Ball1`+166) | 87 | ball 3: wait 33 frames | - | - |
| `$A601` | `Rack5Ball4` (`Rack5Ball1`+253) | 87 | ball 4: wait 22 frames | - | - |
| `$A658` | `Rack5Ball5` (`Rack5Ball1`+340) | 83 | ball 5: wait 11 frames | - | - |
| `$A6AB` | `Rack5Ball6` (`Rack5Ball1`+423) | 87 | ball 6: wait 0 frames | - | - |

## halloffame

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AA6A` | `ScoreBlank` | 10 | A text record: row, column (both patched by BlankScore), attribute `$0F`, 6 spaces. Read by `$9E65` from BlankScore only (w1 20 reads). The text record format: see MenuTexts `$B464`. | - | `BlankScore` (code) |
| `$AAD8` | `SolidLine` | 7 | Seven `$FF` bytes: a solid 56-pixel line of a flag. Read by RestoreFlagLine through CopyNameLines (w1 2688 reads). | - | - |
| `$AB41` | `FlagTail` | 58 | The flag's ragged tail: 29 lines of 2 bytes (right byte, left byte), XORed at x + 48. Read by XorTailLines (w1 43558 reads). Lines 0-4: right `$00`, left `$FF` (the flag goes on 8 pixels); lines 5-23: left `$FF`, right `$7F` `$7E` `$7C` `$78` `$78` `$7C` `$7E` `$7F` repeating (the ragged edge, two notches and a part); lines 24-28 (`$AB71-$AB7A`): the curled bottom corner below the 24-line field. | - | - |
| `$AC08` | `HofTable` | 213 | The hall of fame: 3 slots of 71 bytes; slot 1 centre top (james 300), slot 2 left (francis 200), slot 3 right (bill 100). Read by CountBeaten (the scores: game and f1 read only slot 3's score), InsertEntry, ShowHallOfFame and the slide routines; written by InsertEntry, RenderName (the bitmaps) and the slide routines (+9/+`$0A`, +`$0E`). In the image: +0/+1 score, +2..+8 the name (padded with spaces), +9/+`$0A` the flag's x / y (set by DrawFlag), +`$0B`/+`$0C` the pole's x / y in pixels, +`$0D` the flag's attribute, +`$0E` bit 0 = the flag moves, +`$0F`..+`$46` the name bitmap (56 bytes, rendered at the first draw). w1 wrote "vp" with 270 into slot 2 (screen w1 frame 14000: james 003000 centre, vp 002700 left, francis 002000 right). | `TestSlot` | `GameOverHallOfFame` |
| `$AC4F` | `HofSlot2` (`HofTable`+71) | 71 | slot 2: score 200, "francis" | - | `GameOverHallOfFame` |
| `$AC96` | `HofSlot3` (`HofTable`+142) | 71 | slot 3: score 100, " bill  " | `TestSlot` | `GameOverHallOfFame` |
| `$ACDD` | `NewEntry1` | 18 | The new entries: player 1's score and name, then player 2's (9 bytes each, the format of a slot's first 9). Written by GameOverHallOfFame (the score from `$9F45` / `$9F47`, the name from NameBuffer `$B227`), read by InsertEntry. w1 wrote and read NewEntry1 (11 reads); NewEntry2 is read and written only on the two-player path, which no recording ran. | - | `GameOverHallOfFame` |
| `$ACDF` | `NewEntryName1` (`NewEntry1`+2) | 7 | player 1's name | - | - |
| `$ACE6` | `NewEntry2` (`NewEntry1`+9) | 2 | player 2's score | - | `GameOverHallOfFame` (code) |
| `$ACE8` | `NewEntryName2` (`NewEntry1`+11) | 7 | player 2's name | - | - |

## nameentry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AD3D` | `HofTextList` | 18 | The eight text records of the name page, then a zero word. Read by NameEntryPage (w1 18 reads). | - | - |
| `$AD4F` | `HofTitle` | 323 | "congratulations!" (row 0, column 8, attribute `$30`, 16 characters). The text records of the page (format: MenuTexts `$B464`), all attribute `$30`, read by NameEntryPage in w1 (the "player" titles by none). | - | - |
| `$AD63` | `HofTitleP1` (`HofTitle`+20) | 30 | at (0, 3), 26 chars | - | - |
| `$AD81` | `HofTitleP2` (`HofTitle`+50) | 30 | at (0, 3), 26 chars | - | - |
| `$AD9F` | `HofText1` (`HofTitle`+80) | 36 | at (2, 0), 32 chars | - | - |
| `$ADC3` | `HofText2` (`HofTitle`+116) | 34 | at (3, 0), 30 chars | - | - |
| `$ADE5` | `HofText3` (`HofTitle`+150) | 9 | at (4, 0), 5 chars | - | - |
| `$ADEE` | `HofText4` (`HofTitle`+159) | 36 | at (6, 0), 32 chars | - | - |
| `$AE12` | `HofText5` (`HofTitle`+195) | 35 | at (7, 0), 31 chars | - | - |
| `$AE35` | `HofText6` (`HofTitle`+230) | 35 | at (8, 0), 31 chars | - | - |
| `$AE58` | `HofText7` (`HofTitle`+265) | 33 | at (9, 0), 29 chars | - | - |
| `$AE79` | `HofText8` (`HofTitle`+298) | 25 | at (10, 0), 21 chars | - | - |
| `$B167` | `CharacterGrid` | 42 | The name-entry grid: 3 rows of 14 cells. Read by DrawCharacterGrid and PickCell (w1 45 reads). Row 0 a-n, row 1 o-z, space, "."; row 2 0-9, `$0C` `$0C` ("rub", two cells), `$0D` `$0D` ("end"). | - | - |
| `$B191` | `RubLines` | 73 | The word "rub": lines (dx, dy, length) from (x `$B7`, y `$90`), `$FF` ends. Read by DrawLineList (w1 97 reads). | - | - |
| `$B1DA` | `EndLines` | 76 | The word "end": lines (dx, dy, length) from (x `$D7`, y `$90`), `$FF` ends. Read by DrawLineList (w1 102 reads). | - | - |
| `$B226` | `RepeatDelay` | 1 | The name entry's auto-repeat counter: two nibbles, high = the delay, low = the countdown (`$70` at rest). Written and read by NameEntry (w1 103 reads). | `NameEntry` (code) | `NameEntry` (code) |
| `$B227` | `NameBuffer` | 7 | The name being typed: 7 characters ("_" = empty). Written by NameEntry and PickCell, read by DrawName and copied to NewEntryName1 / NewEntryName2 by GameOverHallOfFame (w1 53 reads). | - | - |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B407` | `PromptLeft` | 93 | "select key for left ?" (row 21, column 2, attribute `$0F`, 27 characters, space-padded). The three prompts, read by RedefinePrompt (m1 186 reads); each covers the key line at row 21. | - | - |
| `$B426` | `PromptRight` (`PromptLeft`+31) | 31 | "select key for right ?" | - | - |
| `$B445` | `PromptFire` (`PromptLeft`+62) | 31 | "select key for fire ?" | - | - |
| `$B464` | `MenuTexts` | 32 | The menu page's 15 text records, then a zero word. Read by MainMenu (every recording, m1 128 reads). | `MainMenu` | - |
| `$B484` | `MenuTitle` | 385 | row 0 column 9, 14: "- video pool -". The records of MenuTexts, all attribute `$0F` (screen m1 frame 4620); read by MainMenu in every recording. | `PrintText` | - |
| `$B496` | `MenuSelect` (`MenuTitle`+18) | 20 | at (2, 0), 16 chars | `PrintText` | - |
| `$B4AA` | `MenuOnePlayer` (`MenuTitle`+38) | 22 | at (4, 2), 18 chars | `PrintText` | - |
| `$B4C0` | `MenuTwoPlayers` (`MenuTitle`+60) | 22 | at (5, 2), 18 chars | `PrintText` | - |
| `$B4D6` | `MenuSmallPockets` (`MenuTitle`+82) | 20 | at (7, 2), 16 chars | `PrintText` | - |
| `$B4EA` | `MenuLargePockets` (`MenuTitle`+102) | 20 | at (8, 2), 16 chars | `PrintText` | - |
| `$B4FE` | `MenuKeyboard` (`MenuTitle`+122) | 15 | at (10, 2), 11 chars | `PrintText` | - |
| `$B50D` | `MenuInterface2` (`MenuTitle`+137) | 29 | at (11, 2), 25 chars | `PrintText` | - |
| `$B52A` | `MenuKempston` (`MenuTitle`+166) | 24 | at (12, 2), 20 chars | `PrintText` | - |
| `$B542` | `MenuCursor` (`MenuTitle`+190) | 22 | at (13, 2), 18 chars | `PrintText` | - |
| `$B558` | `MenuBegin` (`MenuTitle`+212) | 17 | at (15, 2), 13 chars | `PrintText` | - |
| `$B569` | `MenuVariations` (`MenuTitle`+229) | 22 | at (17, 2), 18 chars | `PrintText` | - |
| `$B57F` | `MenuEdit` (`MenuTitle`+251) | 17 | at (18, 2), 13 chars | `PrintText` | - |
| `$B590` | `MenuRedefine` (`MenuTitle`+268) | 28 | at (19, 2), 24 chars | `PrintText` | - |
| `$B5AC` | `MenuCopyright` (`MenuTitle`+296) | 36 | (23, 0), 32 | `PrintText` | - |
| `$B5D0` | `VariationStandard` (`MenuTitle`+332) | 19 | (15, 16), 15 | `PrintText` | - |
| `$B5E3` | `Variation1Line` (`MenuTitle`+351) | 17 | (15, 16), 13 | - | - |
| `$B5F4` | `Variation2Line` (`MenuTitle`+368) | 17 | (15, 16), 13; no build reads it | - | - |
| `$B65F` | `KeysLine` | 31 | "left=    right=    fire=   " (row 21, column 2, attribute `$0F`, 27 characters); the names filled in. Written by ShowKeys, read by `$9E65` (every recording). | `PrintText` | `KeyName` |
| `$B668` | `KeysLineLeft` (`KeysLine`+9) | 10 | the left key's name (3 characters) | `PrintText` | `KeyName` |
| `$B672` | `KeysLineRight` (`KeysLine`+19) | 9 | the right key's name | `PrintText` | `KeyName` |
| `$B67B` | `KeysLineFire` (`KeysLine`+28) | 3 | the fire key's name | `PrintText` | `KeyName` |
| `$B731` | `VariationTexts` | 28 | The variations page's 13 text records, then a zero word. Read by VariationsPage (v1 56, m1 28 reads). | - | - |
| `$B74D` | `VariationsTitle` | 335 | row 0 column 6, 19: "- game variations -". The records of VariationTexts, attribute `$0F`, read by VariationsPage in v1 and m1. | - | - |
| `$B764` | `VariationsSelect` (`VariationsTitle`+23) | 20 | at (2, 0), 16 chars | - | - |
| `$B778` | `VariationsS1` (`VariationsTitle`+43) | 33 | at (4, 2), 29 chars | - | - |
| `$B799` | `VariationsS2` (`VariationsTitle`+76) | 26 | at (5, 5), 22 chars | - | - |
| `$B7B3` | `Variations11` (`VariationsTitle`+102) | 31 | at (7, 2), 27 chars | - | - |
| `$B7D2` | `Variations12` (`VariationsTitle`+133) | 30 | at (8, 5), 26 chars | - | - |
| `$B7F0` | `Variations13` (`VariationsTitle`+163) | 26 | at (9, 5), 22 chars | - | - |
| `$B80A` | `Variations21` (`VariationsTitle`+189) | 29 | at (11, 2), 25 chars | - | - |
| `$B827` | `Variations22` (`VariationsTitle`+218) | 29 | at (12, 5), 25 chars | - | - |
| `$B844` | `Variations23` (`VariationsTitle`+247) | 28 | at (13, 5), 24 chars | - | - |
| `$B860` | `Variations24` (`VariationsTitle`+275) | 27 | at (14, 5), 23 chars | - | - |
| `$B87B` | `VariationsBegin` (`VariationsTitle`+302) | 17 | at (17, 2), 13 chars | - | - |
| `$B88C` | `VariationsMenu` (`VariationsTitle`+319) | 16 | at (19, 2), 12 chars | - | - |
| `$B8BB` | `Players` | 10 | The menu's settings: first the players, 1 or 2 (keys 1 / 2), then pockets, control, the three keys, the timeout, the variation, the cheat. One byte each (MenuTimeout a word). Readers and writers in the comments. The defaults in the image: one player, large pockets, keyboard, keys M / SYMBOL SHIFT / SPACE, standard game. Players is read by GameOverHallOfFame, NameEntryPage and the play code (`$97AB`, `$97D0`, `$98D5`, `$9B36`, `$9C15`, `$9C7B`) | `CushionsBySize`, `DrawTable`, `EraseBallsUnderBanner`, `GameOver`, `GameOverHallOfFame` +16 | `MainMenu`, `EditorExit` (code), `EditorPlay` (code), `EditorStart` (code), `RedefineKeys` (code) +2 |
| `$B8BC` | `Pockets` (`Players`+1) | 1 | 0 small, 1 large (keys S / L); read by the table drawing and the pocket tests (`$8B71`, `$8C74`, `$9256-$9330`) | `CushionsBySize`, `DrawTable`, `MainMenu`, `PocketOrCushion` (code) | `MainMenu` (code) |
| `$B8BD` | `Control` (`Players`+2) | 1 | 0 keyboard, 1 Interface 2, 2 Kempston, 3 cursor (keys K / I / J / C); the handler index of `$8106`; the editor sets 3 while it runs if it is 0 (`$C042`, `$C417`, `$C44E`) | `MainMenu`, `ReadInput`, `EditorStart` (code), `VariationsPage` (code) | `EditorExit` (code), `EditorPlay` (code), `EditorStart` (code), `MainMenu` (code) |
| `$B8BE` | `LeftKey` (`Players`+3) | 1 | K-TEST codes of the keyboard control's keys, read by `$8123`; set by RedefineKeys | `ReadKeyboard`, `ShowKeys` | `RedefineKeys` (code) |
| `$B8BF` | `RightKey` (`Players`+4) | 1 | - | `ReadKeyboard`, `ShowKeys` | `RedefineKeys` (code) |
| `$B8C0` | `FireKey` (`Players`+5) | 1 | - | `ReadKeyboard`, `ShowKeys` | `RedefineKeys` (code) |
| `$B8C1` | `MenuTimeout` (`Players`+6) | 2 | frames left before the attract sequence (1500 at each key) | `MainMenu`, `VariationsPage` (code) | `MainMenu`, `VariationsPage` (code) |
| `$B8C3` | `Variation` (`Players`+8) | 1 | 0 standard, 1 numeric order, 2 own pockets; read by `$8C2F`, `$9BFA`, `$9C00` | `MainMenu`, `ShotsForFrame`, `PocketOrCushion` (code), `TickVariation` (code), `VariationsPage` (code) | `VariationsPage` (code) |
| `$B8C4` | `InfiniteLives` (`Players`+9) | 1 | non-zero: no life is lost (`$9754`); flipped by WaitNoKey | `LoseLife`, `WaitNoKey` (code) | `WaitNoKey` (code) |

## presents

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B936` | `PresentsTexts` | 54 | The page's texts in the print format of `$9E65`: row, column, attribute, length, characters. Three records for the print routine `$9E65` (row, column, attribute, length, then the characters): "presents" (row 16, column 12, attribute `$38`), eight spaces over it, and "press any key to continue." (row 23, column 3, attribute `$38`, 26 characters). Read by PresentsPage `$B8C5`; the first 24 bytes in every build, the last record only in m1 (the only build that reached the end of the sequence). | `PrintText` | - |
| `$B942` | `PresentsBlank` (`PresentsTexts`+12) | 12 | eight spaces | `PrintText` | - |
| `$B94E` | `PressAnyKey` (`PresentsTexts`+24) | 30 | "press any key to continue." | - | - |
| `$BA86` | `BannerData` | 141 | The OCP banner: 37 rows of run lengths, 240 pixels each (bit 7 ink, bits 0-6 half the length). One byte a run: bit 7 set = magenta ink, clear = paper; bits 0-6 = half the run's length in pixels. A row ends when its runs add up to 240 pixels: `$F8` alone is a full ink row, `$78` a full paper row. The letters O, C and P are the paper gaps in the ink stripes (WALKTHROUGH 6.1, m1 frame 300). Read by BannerRowEdges `$BA0A` (and BannerRollIn `$B96C`, BannerDrawRows `$B9E0` to skip rows); all 141 bytes in every build. | `BannerRollIn`, `BannerRowEdges` | - |

## attract

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BB98` | `FlipLetterO` | 121 | The letter O: 12 edge records (dx, dy, kind), `$FF`. Each letter: per stripe row (dy 0, 8, ... 40, the six stripe pairs) a record for the left edge (dx 0) and one for the right edge (dx 1, kind bit 1 set). Kind: bit 1 = the right edge, bit 2 = the 24-pixel width table, bit 3 = both tables (two edges drawn, 16 and 24); bit 0 is the phase LogoFlip adds. Read by FlipLetter `$BB74`: all 121 bytes in w1 and m1 (game, f1, p2, v1 stop at the key during the narrowing, so the L is never read there). | `FlipLetter` | - |
| `$BBBD` | `FlipLetterC` (`FlipLetterO`+37) | 31 | The letter C: 10 records, `$FF` | `FlipLetter` | - |
| `$BBDC` | `FlipLetterP` (`FlipLetterO`+68) | 31 | The letter P: 10 records, `$FF` | `FlipLetter` | - |
| `$BBFB` | `FlipLetterL` (`FlipLetterO`+99) | 22 | The letter L: 7 records, `$FF` | - | - |
| `$BC74` | `FlipWidths16` | 42 | Half-widths of a turning letter: 16 cos(4.5 k) for k = 0..20 (16 ... 1, 0). 21 bytes 16, 16, 16, 16, 15, 15, 14, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 1, 0: the projected half-width of a 16-pixel half letter turned by 4.5 degrees a step (16 cos 45 = 11.3, entry 10 = 11). Read by FlipEdge `$BC11`; all in w1 and m1. | `FlipEdge` | - |
| `$BC89` | `FlipWidths24` (`FlipWidths16`+21) | 21 | the same for 24 pixels: 24 cos(4.5 k), 24 ... 2, 0 | `FlipEdge` | - |
| `$BD04` | `VideoText` | 5 | "video", the five letters of VideoSlideIn. Read by VideoSlideIn `$BC9E` (w1, m1). | - | - |
| `$BD09` | `PresentsSP` | 3 | SP at PresentsPage's entry: PresentsAbort `$B931` reloads it (written and read once in every build) | `PresentsFrame`, `PresentsPage` (code) | `GameStart`, `PresentsPage` |
| `$BD0B` | `PresentsDone` (`PresentsSP`+2) | 1 | 0 while GameStart `$8000`'s first presents page runs (`$8006`), `$FF` after it (`$800E`): PresentsPage then also calls `$A8FD` (read twice in m1, both 0) | `PresentsPage` (code) | `GameStart` |

## signature

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BF0D` | `PenShaftPad1` | 6 | Six zero bytes that align PenShaftCopy2 at PenShaftCopy1 + 16. Never read or executed (l1sum.py --reads BF0D-BF32: no build). | - | - |
| `$BF1F` | `PenShaftPad2` | 4 | Four zero bytes of alignment | - | - |
| `$BF31` | `PenShaftPad3` | 2 | Two zero bytes of alignment | - | - |
| `$BFCC` | `PenNib` | 31 | The pen's nib: ten spans (dx, dy, length) from the pen point down-right, `$FF`. (0,0,2) (0,1,4) (1,2,5) (1,3,7) (2,4,8) (2,5,10) (3,6,10) (3,7,11) (4,8,11) (4,9,12): a wedge 10 lines high. Read by PenSpans `$BE79` (m1, all 31 bytes). | - | - |
| `$BFEB` | `PenCap` | 19 | The pen's end cap: six spans at (49..54, 54..59), lengths 11 down to 1, `$FF`. Read by PenSpans `$BE79` after the shaft (m1, all 19 bytes). | - | - |
| `$BFFE` | `PenShaftImage` | 64 | The shaft: 16 rows of 4 bytes, a 12-pixel bar moving one pixel right a row. Row r = the bar's 12 pixels starting at pixel r of the 32: PenShaftBlock `$BEDC` starts at row x AND 7 and takes one row a line. Read by PenShaftCopy4 `$BF33` (m1, 60 of 64 bytes: rows 15's last bytes never). | - | - |
| `$C03E` | `PenBand` | 4 | The pen's state: the band flag (0; 1 / 2 only on the band paths, never run), pen down, the shaft position. PenBand `$C03E`: zeroed by SignatureWrite `$BD0C`, read by SigMove `$BD65` (m1 582 reads, always 0). | `PenShaft` (code), `PenShaftBlock` (code), `PenStep` (code), `SignatureCommand` (code) | `PenShaft` (code), `PenShape` (code), `SignatureCommand` (code), `SignatureWrite` (code) |
| `$C03F` | `PenIsDown` (`PenBand`+1) | 1 | 0 pen up, 1 pen down (SignatureCommand commands 1 / 2; read by PenStep, m1 1484 reads) | `PenStep` (code) | `SignatureCommand` (code), `SignatureWrite` (code) |
| `$C040` | `PenShaftPos` (`PenBand`+2) | 2 | the shaft's start: x (+0), y (+1) (PenShape, PenShaft) | `PenShaft` (code), `PenShaftBlock` (code) | `PenShaft` (code), `PenShape` (code) |

## editor

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C518` | `EditorAimTasks` | 26 | The editor's aim task list (period, address): EditorPower, `$934D`, `$8546`, `$85EB`, ReadInput, `$FF`. Installed by EditorPlay `$C41D` and EditorShotEnd `$C46E`, removed by EditorPower `$C4D6`. All periods 0. Read in e1 (each byte 3 times, frames 844-1054). | - | - |
| `$C528` | `EditorRollTasks` (`EditorAimTasks`+16) | 10 | the rolling list: `$827E` (ball redraw), `$86C1` (physics), EditorShotEnd, `$FF` | - | - |
| `$C54E` | `EditorTexts` | 63 | The editor's texts for `$9E65` (row, column, attribute, length, characters). "- editor -" (row 0, column 11), "play" (row 3, column 19, attribute `$39`), "reset" (row 3, column 26), then two blanks: 10 spaces over the title and 14 spaces at column 18 whose row byte EditorStart / EditorPlay patch to 2, 3, 4 (and 5). The first three read once in m1 (6262); EditorButtonsBlank 4 times; EditorTitleBlank once, in e1 (EditorPlay, frame 840). | - | - |
| `$C55C` | `EditorPlayText` (`EditorTexts`+14) | 8 | "play" | - | - |
| `$C564` | `EditorResetText` (`EditorTexts`+22) | 9 | "reset" | - | - |
| `$C56D` | `EditorTitleBlank` (`EditorTexts`+31) | 14 | ten spaces over "- editor -" | - | - |
| `$C57B` | `EditorButtonsBlank` (`EditorTexts`+45) | 18 | row patched: 14 spaces at column 18 | - | - |
| `$C58D` | `EditorCursorSpeed` | 4 | The cursor's step counter: high nibble frames left, low nibble the speed (1-5), `$F1` at a start. Read and written by EditorStart's loop (m1 240 reads). | `EditorExit` (code), `EditorFire` (code), `EditorPlay` (code), `EditorStart` (code) | `EditorFire` (code), `EditorStart` (code) |
| `$C58E` | `EditorBallSpeed` (`EditorCursorSpeed`+1) | 1 | the same for the moved ball (never used in a recording) | `EditorFire` (code) | `EditorFire` (code) |
| `$C58F` | `EditorPickedBall` (`EditorCursorSpeed`+2) | 1 | the picked ball, 0 cue .. 6 | `EditorFire` (code) | `EditorFire` (code) |
| `$C590` | `EditorSavedMode` (`EditorCursorSpeed`+3) | 1 | the input mode `$B8BD` at entry (m1: written at 6262, read at 6830) | `EditorExit` (code), `EditorPlay` (code) | `EditorStart` (code) |
| `$C591` | `EditorStaleCopy` | 111 | 111 bytes equal to `$C34C-$C3BA` (inside EditorBallMove): a stale copy, never read. Byte for byte the code from the middle of LD (IX+4),A at `$C34A` (`$C34C`) to the opcode of the JP at `$C3BA`: the copy is cut by the block's end at `$C600` before the JP's operand. A leftover of an earlier assembly in which this code sat higher. No build reads it (l1sum.py --reads C591-C5FF). | - | - |

## workspace

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C600` | `FreeSpace` | 2496 | Zeros up to the stack: never read or written in any recording. 2496 bytes of zeros. tools/l1sum.py --reads C600-CFBF: no read in game, w1, f1, p2, v1, m1, j1. The loader's sum covers them (they are on the tape), nothing else touches them. | - | - |
| `$CFC0` | `StackSpace` | 64 | The machine stack, 64 bytes below `$D000`. The stack pointer is set to StackTop (`$D000`) by GameStart and BreakRestart. The loaded bytes here are zeros; no recording reads a byte before writing it (l1sum.py --reads CFC0-CFFF: none), the lowest byte w1 uses is `$CFC4`. | - | - |

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D000` | `BallSprites` | 2688 | The 56 ball sprites: 3 bytes x 16 lines, 7 balls x 8 shifts. Read by DrawBall `$9548` (through the XOR drawer): every byte read in game, w1, f1, p2, v1, m1, j1 (l1sum.py --reads D000-DA7F: 2688 of 2688 bytes). | `XorSpriteLines` | - |

## penscript

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DA80` | `SignatureScript` | 378 | The pen script of "written by" (x 16-64) and "James Hutchby" (x 75-184), y 120-146. Read only by SignatureCommand `$BD23` (m1, all 378 bytes, 1830 reads: two whole runs and one cut by a key). Stage 1 called it the logo's data; it is the pen's path. `$DBF9` is the end command. | - | - |

## physicstables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DBFA` | `ContactTable` | 256 | Ball against ball by \|dx\| (column) and \|dy\| (row), whole pixels: `$80` overlap, 1-31 the contact ring, 0 apart. Read by BallContacts `$87EF` at 16 \|dy\| + \|dx\| (\|dx\|, \|dy\| < 16): 157 of 256 bytes read (w1, f1, p2, v1, m1; never in game). `$80` for every cell with dx*dx + dy*dy <= 212, a record number 1-31 for the 31 cells with 218..250 (d from 14.8 to 15.8: two balls of 15 pixels touching), 0 for 260 and more. The ring numbers run by angle from the x axis: 1 = (15, 0), 16 = (11, 11), 31 = (0, 15); the cell (dx, dy) and (dy, dx) have n and 32 - n. | - | - |
| `$DCFA` | `Table8x8` | 64 | Ball against a jaw point by \|dx\| (column) and \|dy\| (row): `$80` overlap, 1 touching, 0 apart. Read by PointJaw `$8CF8` at 8 \|dy\| + \|dx\| (twice: `$8D1C` and the back-off loop `$8D41`): 16 of 64 bytes read (w1, v1, m1). `$80` for dx*dx + dy*dy <= 37, 1 for 40..53 (d 6.3 to 7.3: the ball's radius about 7), 0 for 58 and more. PointJaw also rejects \|dx\| = \|dy\| >= 5 before the read, so the cell (5, 5) = 1 is never used. | - | - |
| `$DD3A` | `FrictionTable` | 256 | Friction steps by the direction: row = \|vy\| nibble, column = \|vx\| nibble; high nibble y step, low nibble x step. Read by FrictionSteps `$90F5` at 16 ny + nx: 211 of 256 bytes read in all builds (the unread are mostly small-speed cells; (0, 0), a stopped ball, never). Every entry but (0, 0) = `$44` is (round (5 ny / n), round (5 nx / n)) with n = SQR (nx*nx + ny*ny) within 0.5 (row 0: `$05`, column 0: `$50`, the diagonal `$44`): a deceleration of 4.5 to 5.7, about 5, in 1/256 pixel a tick per tick, along the motion. | `FrictionSteps` | - |
| `$DE3A` | `CollisionRecords` | 186 | 31 records of three words: nx^2, ny^2, \|nx ny\| for one contact-ring cell (0.8, `$0100` = 1.0). Record n is ContactTable's ring cell n (dx, dy): w0 = 256 dx*dx / 225, w1 = 256 dy*dy / 225, w2 = 256 dx dy / 225, truncated (29 of 31; records 8 and 24 have 41 for 40.96): the line of centres taken as if the distance were always 15. So w0 + w1 is 1.0 on the axes and 1.075 at 45 degrees (record 16: `$89`, `$89`, `$89`): a diagonal hit gives back up to 7.5 % more than an exact projection. Read by BallContacts `$87EF` through ContactRecordPtr `$89B7` (ScaleVelocity `$89C4`): 27 of the 31 read (w1, f1, p2, v1, m1); 6, 16, 18, 26 not hit in any recording. | - | - |

## font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DEF4` | `Font` | 288 | The font: 26 letters a-z, then 10 digits 0-9, 8 bytes each. Read by PrintChar `$9E7C` and the hall of fame's name printers: every byte read in w1 (l1sum.py --reads DEF4-E013: 288 of 288 bytes; game, f1, p2, v1, m1, j1 read the glyphs of their texts). | `CopyGlyph`, `PrintChar`, `PrintCharWide` | - |
| `$DFC4` | `FontDigits` (`Font`+208) | 80 | the digits 0-9 (Font+208) | `CopyGlyph`, `PrintChar`, `PrintCharWide` | - |

## devleftover

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E053` | `DevFragment` | 3 | Three bytes (`$50`, `$13`, `$18`) and an endless JR -2 (`$FE`): no routine start found | - | - |
| `$E0B8` | `DevParseList` | 72 | Development leftover, kept as bytes: skip spaces; "(" name [, name] ")" with each name looked up (`$50B2`) in the table at DE. Code, never executed, kept as bytes because its last instruction (XOR A at `$E0FF`) runs on into the zeros at `$E100` and a branch (JR Z at `$E0E7`) jumps to `$E101`: the piece is cut off there. Disassembled: `$E0B8` INC HL; LD A,(HL); CP `$0D`; RET Z; CP " "; JR Z,`$E0B8`; CP "("; JR NZ,`$E0FF`. `$E0C5` PUSH DE; LD B,6; LD DE,`$4200`; INC HL; CALL `$506B` (read a name of up to six characters into `$4200`); DEC HL; POP DE; RET NZ; CP `$0D`; JR NZ,`$E0D7`; INC HL. `$E0D7` PUSH DE; LD B,D; LD C,E; LD DE,`$4200`; CALL `$50B2` (DevLookup's address in the piece's own layout); JR Z,`$E0E4`; POP DE; RET. `$E0E4` LD A,(HL); CP "="; JR Z,`$E101`; LD BC,`$FFFF`; LD (DE),C; INC DE; LD (DE),B (stored through DE as two LD (DE),A); POP DE; LD A,(HL); CP ","; JR Z,`$E0C5`; CP `$0D`; JR Z,`$E0FF`; CP ")"; RET NZ; INC HL. `$E0FF` XOR A, then the zeros. | - | - |
| `$E100` | `DevZeros` | 168 | Zeros to the end of the loaded block (`$E1A7`) | - | - |
