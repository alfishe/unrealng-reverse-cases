# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a table jump or
by running on: L1 books its time to the routine it runs in) gives the runs of its first instruction, as its witness
line counts them.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: The BASIC of REX 1, The BASIC of REX 2, The BASIC of DEMO, REX 1's
loading screen, REX 2's loading screen, DEMO's loading screen, Part 2 (REX 2), DEMO) follow the game, each under its
own heading with its modules, its source, its annotations and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`graphics`](11-data-reference.md#graphics) | `$6018`-`$9479` | 0 of 9 |
| [`entry`](#entry) | `$947A`-`$9582`, `$97C3`-`$97FC` | 4 of 4 |
| [`mainloop`](#mainloop) | `$9583`-`$967E` | 2 of 2 |
| [`rex`](#rex) | `$967F`-`$9748` | 3 of 3 |
| [`bomb`](#bomb) | `$9749`-`$97C2` | 4 of 4 |
| [`score`](#score) | `$97FD`-`$9AC4` | 13 of 15 |
| [`death`](#death) | `$9AC5`-`$9F5E` | 15 of 17 |
| [`cells`](#cells) | `$9F5F`-`$A011` | 3 of 3 |
| [`variables`](11-data-reference.md#variables) | `$A012`-`$A0C3` | 0 of 1 |
| [`hud`](#hud) | `$A0C4`-`$A469` | 22 of 27 |
| [`controls`](#controls) | `$A46A`-`$A502` | 12 of 12 |
| [`grid`](#grid) | `$A503`-`$A78A`, `$A7A9`-`$A7CD` | 10 of 12 |
| [`weapons`](#weapons) | `$A78B`-`$A7A8`, `$B372`-`$BA5B` | 45 of 47 |
| [`codepanel`](#codepanel) | `$A7CE`-`$A9AE` | 3 of 5 |
| [`tables`](11-data-reference.md#tables) | `$A9AF`-`$B204` | 0 of 11 |
| [`render`](#render) | `$B205`-`$B371` | 5 of 5 |
| [`objects`](#objects) | `$BA5C`-`$C744` | 55 of 62 |
| [`rooms`](#rooms) | `$C745`-`$CE7A` | 45 of 45 |
| [`panels`](#panels) | `$CE7B`-`$CFCB`, `$D858`-`$DABF` | 14 of 15 |
| [`rexmove`](#rexmove) | `$CFCC`-`$D1B8` | 14 of 16 |
| [`collisions`](#collisions) | `$D1B9`-`$D5AD` | 12 of 13 |
| [`sound`](#sound) | `$D5AE`-`$D857` | 9 of 11 |
| [`menu`](#menu) | `$DAC0`-`$FFF9` | 17 of 23 |

## entry

`src/game/entry.asm`

### `GameEntry` (`$947A`)

**The code block's entry (USR 38010): DI, the menu, the high score, then NewGame**

Clears ControlXor `$A0AE` (keys, not Kempston) and AttractFlag `$A0C2`, calls TitleMenu `$DAC0`, clears the attribute shadow `$E4FF-$E7FE` (the title screen's bytes, no longer needed) and sets HiScore `$A08B` = 10. Falls into NewGame.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 16,219 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage2/rec/p1-define`, `stage1/rec/rzx-p1-00000`, `stage2/rec/p1-kempston` and 1 more) |
| Calls | `NewGame` (falls into), `TitleMenu` |
| Reads | `$6758`-`$675F` (`AnimChar111`); `$6858`-`$685F` (`AnimChar143`); `$A017` (`PassToggle`); `$A040` (`RapidShotsOn`); `$A055` (`Dying`); `$A093` (`Temp1`); 2 more ranges |
| Writes | `$6758`-`$675F` (`AnimChar111`); `$6858`-`$685F` (`AnimChar143`); `$A012`-`$A01A` (`Variables`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 3 more); `$A030`-`$A0C2` (`SmartBombOn`, `SmartBombPtr`, `SpriteMirror`, `SpritePicture` and 96 more); `$ABA0` (`DoubleFireText`); `$ABB1`-`$ABCA` (`LaserText`, `MultipleText`, `SprayText`); 1 more ranges |
| Ports in | `$7FFE`, `$BFFE` |
| Ports out | `$00FE` |

### `NewGame` (`$9498`)

**A new game: every variable reset, the HUD, PHASE ONE and PRESS FIRE TO BEGIN, the wait for fire, Rex materialises**

Also the target of ENTER in the main loop (restart), of the game over and of the attract mode. InitDrones `$A628`; border black; Lives `$A063` = 4, Bombs `$A06C` = 3, ResetPower `$BA49`, ShieldEnergy `$A04D` = 99, the weapons held `$A050-$A053` = 0, the score, HumansKilled `$A089` and the extra life count 0, the random seeds `$A0A1` = `$0313`, `$A0A3` = `$11`; Rex at X `$A0`, Y `$60` in room 0 facing right, the restart point the same. Then ClearScreen `$A3AE`, DrawHud `$A1A5`, ShowLives `$99BB`, SaveAttrs `$CF8F`, the texts PhaseOneText `$AAAE` and PressFireText `$AB25` (PrintBoxed `$A13E`) each followed by WaitFireOrAttract `$97C3`; SoundReset `$D5AE` and Materialise `$9D1F`. Falls into MainLoop.

Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000, rzx-p1-64000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 2,118 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage2/rec/p1-cursor` 2, `stage2/rec/p1-code` 1, `stage1/rec/rzx-p1-64000` 1) |
| Called from | `GameEntry` (falls into), `MainLoop` (tail), `LifeLost` (tail), `CodePanel` (tail) |
| Calls | `WaitFireOrAttract`, `ShowLives`, `Materialise`, `PrintBoxed`, `DrawHud`, `ClearScreen`, `InitDrones`, `Attract` (tail), `ResetPower`, `SaveAttrs`, `SoundReset` |
| Reads | `$A093` (`Temp1`) |
| Writes | `$A018` (`PowerCount`); `$A030`-`$A0BD` (`SmartBombOn`, `SmartBombPtr`, `SpriteMirror`, `SpritePicture` and 94 more); `$ABA0` (`DoubleFireText`); `$ABB1`-`$ABCA` (`LaserText`, `MultipleText`, `SprayText`) |
| Ports out | `$00FE` |

### `WaitFireOrAttract` (`$97C3`)

**Wait up to 50000 polls for fire: Temp1 = 1 after a press and its release, 0 when the count runs out**

Temp1 = 0 and the sound silenced, then DE = 50000 counted down, a DJNZ delay of 30 before each poll of ReadFire `$A477`. A press: wait for its release (WaitFireRelease), SoundReset `$D5AE`, Temp1 = 1, RET. The count out: RET with Temp1 0 and the sound still off. NewGame's second call tests Temp1 and jumps to Attract `$A915` on 0; the weapon panel (WeaponPanel) ignores it.

Witness: L1 20 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x5).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 69,475,318 t-states own (4.79 %) |
| Runs (the other recordings) | 16 calls (`stage2/rec/p1-cursor` 4, `stage1/rec/rzx-p1-00000` 3, `stage2/rec/p1-kempston` 2 and 6 more) |
| Called from | `NewGame`, `WeaponPanel` |
| Calls | `ReadFire`, `SoundReset`, `SoundSilence` |
| Writes | `$A093` (`Temp1`) |

### `WaitFire` (`$97EA`)

**Wait for fire, then for its release (no timeout): after the game over and the CODE panel**

Witness: L1 3 (c1, p1-code, p1-gameover).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 5,485,864 t-states own (0.38 %) |
| Runs (the other recordings) | 2 calls (`stage2/rec/p1-gameover` 1, `stage2/rec/p1-code` 1) |
| Called from | `LifeLost`, `CodePanel` |
| Calls | `ReadFire`, `SoundReset`, `SoundSilence` |

## mainloop

`src/game/mainloop.asm`

### `MainLoop` (`$9583`)

**Build the room, then one pass of play a frame (MainPass)**

The room change (ChangeRoom `$C95A`) and the life lost jump back here. The keys are the readers `$A477-$A4DB`: down ShieldToggle `$967F`, fire FireWeapon `$B372`, right WalkRight `$CFDA`, left WalkLeft `$CFF6`, up StartJump `$D0C2`; ENTER (`$BFFE` bit 0) NewGame, H (`$BFFE` bit 4) Pause `$A4E7`, SPACE (`$7FFE` bit 0) SmartBomb `$9751`. ENTER, H and SPACE are fixed keys; the other five follow the menu's choice (DEFINE, Kempston, Cursor, Sinclair).

Witness: L1 79 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 1,043,987 t-states own (0.07 %) |
| Runs (the other recordings) | 68 calls (`stage1/rec/rzx-p1-02000` 4, `docs/integrate/rec/p1-speedup` 3, `stage1/rec/rzx-p1-44000` 3 and 36 more) |
| Called from | `LifeLost` (tail), `ChangeRoom` (tail) |
| Calls | `NewGame` (tail), `ShieldToggle`, `RexState`, `SmartBomb`, `SmartBombStep`, `KillFlashFade`, `FadeStep`, `SparkleUpdate`, `SparkleDraw`, `CellsUnderRex`, `HudSweep`, `BufferToScreen`, `ReadFire`, `ReadLeft`, `ReadRight`, `ReadUp`, `ReadDown`, `Pause`, `CellPointer`, `AnimateCells`, `UpdateDrones`, `RollCharUp`, `RollCharDown`, `BuildRoom`, `ClearBuffer`, `DrawAnimCells`, `FireWeapon`, `MoveEnemyBullets`, `MoveBullets`, `PowerBar`, `UpdateObjects`, `SpawnScripted`, `SpawnRandom`, `WalkRightKey`, `WalkLeftKey`, `RexWalk`, `StartJump`, `RexJump`, `RexFall`, `EnemyBulletsHitRex`, `SoundStep` |
| Reads | `$6758`-`$675F` (`AnimChar111`); `$6858`-`$685F` (`AnimChar143`); `$A017` (`PassToggle`); `$A040` (`RapidShotsOn`); `$A055` (`Dying`); `$A0B6`-`$A0BB` (`RexX`, `RexY`, `Room`, `RoomColumn` and 1 more) |
| Writes | `$6758`-`$675F` (`AnimChar111`); `$6858`-`$685F` (`AnimChar143`); `$A012`-`$A01A` (`Variables`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 3 more); `$A04C` (`ShieldKeyLatch`); `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |
| Ports in | `$7FFE`, `$BFFE` |

### `SoundOffReturn` (`$967B`)

**CALL SoundSilence: RET; no instruction reaches it (leftover)**

Four bytes between the main loop's JP and ShieldToggle. No jump or call names `$967B` (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

## rex

`src/game/rex.asm`

### `ShieldToggle` (`$967F`)

**The down key: switch the shield on or off (once a press, only with energy left)**

Called by MainPass when ReadDown `$A4DB` sees the key. ShieldKeyLatch `$A04C` keeps it to one toggle a press; the shield goes on only while ShieldEnergy `$A04D` is not 0 and Rex is not materialising (`$A060`).

Witness: L1 299 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-speedup, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 15 calls, 448 t-states own (0.00 %) |
| Runs (the other recordings) | 284 calls (`stage1/rec/rzx-p1-18000` 24, `stage1/rec/rzx-p1-38000` 16, `stage1/rec/rzx-p1-46000` 14 and 35 more) |
| Called from | `MainLoop` |
| Reads | `$A049`-`$A04D` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`); `$A060` (`SparkleMode`) |
| Writes | `$A049`-`$A04C` (`ShieldOn`, `ShieldKeyLatch`) |

### `RexState` (`$969B`)

**Rex's death animation while he is present and Dying `$A055` is set, else nothing**

Returns while Rex is not present (RexPresent `$A05D` 0: he is materialising); then, if Dying `$A055`, JP DeathAnimation `$9AC5`. Called every pass.

Witness: L1 18528 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 593 calls, 26,128 t-states own (0.00 %) |
| Runs (the other recordings) | 17,935 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 521 and 43 more) |
| Called from | `MainLoop` |
| Calls | `DrawRex` (falls into), `DeathAnimation` (tail) |
| Reads | `$A049`-`$A05D` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate` and 14 more); `$A07A` (`OnLift`); `$A0AF`-`$A0BD` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight` and 8 more); `$D83A` (`Channels+8`) |
| Writes | `$A033` (`SpriteMirror`); `$A0AF`-`$A0B2` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$D7A0`-`$D7A1` (`SfxShieldTone`) |

### `DrawRex` (`$96A7`)

**Draw Rex: his picture (walking or jumping); with the shield on, its hum, its drain and the bubble**

Sets SpriteX `$A0AF`, SpriteY `$A0B0`, the size 3 x 16 (`$A0B1`, `$A0B2`) and the mirror flag by RexFacing; the picture through ShiftFrames `$AE5D`: SpriteRexJump `$8F62` while jumping or falling (and not on a lift, OnLift `$A07A`), else SpriteRex `$80F2`. DrawSprite `$B258`. With ShieldOn `$A049`: the hum SfxShield (its period SfxShieldTone = `$04B0` + Random & `$1F`) started when channel 2 is free, ShieldDrain `$99D3` with L = 1, then the bubble SpriteShield `$88F2`, 4 x 21, through ShiftFrames2 `$AE65`, 4 pixels left of Rex (8 right of that facing left) and 2 lines up.

Witness: L1 17095 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 392 calls, 110,402 t-states own (0.01 %) |
| Runs (the other recordings) | 8,334 calls (`stage1/rec/rzx-p1-18000` 485, `stage1/rec/rzx-p1-34000` 430, `stage1/rec/rzx-p1-30000` 429 and 20 more) |
| Called from | `RexState` (falls into), `DeathAnimation` (tail) |
| Calls | `ShieldDrain`, `Random`, `DrawSprite`, `StartSfx` |
| Reads | `$A049` (`ShieldOn`); `$A07A` (`OnLift`); `$A0AF`-`$A0BD` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight` and 8 more); `$D83A` (`Channels+8`) |
| Writes | `$A033` (`SpriteMirror`); `$A0AF`-`$A0B2` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$D7A0`-`$D7A1` (`SfxShieldTone`) |

## bomb

`src/game/bomb.asm`

### `SmartBombFree` (`$9749`)

**A smart bomb that costs nothing (Rex's death): unless one is running, mark the room's objects**

Witness: L1 42 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-room24, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 160 t-states own (0.00 %) |
| Runs (the other recordings) | 37 calls (`stage1/rec/rzx-p1-40000` 3, `stage1/rec/rzx-p1-26000` 3, `stage1/rec/rzx-p1-02000` 3 and 21 more) |
| Called from | `RexDies` |
| Calls | `SmartBombMark` (tail) |
| Reads | `$5D28`-`$5E45` (system); `$A030` (`SmartBombOn`) |
| Writes | `$5D28`-`$5DFA` (system); `$A02F`-`$A032` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`) |

### `SmartBomb` (`$9751`)

**SPACE: one smart bomb from Bombs `$A06C` (none left, nothing), the HUD updated, the room's objects marked**

Witness: L1 15 (c1, p1-cursor, rzx-p1- x5).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 calls, 145 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/rec/rzx-p1-58000` 3, `stage1/rec/rzx-p1-12000` 2, `stage1/rec/rzx-p1-00000` 2 and 3 more) |
| Called from | `MainLoop` |
| Calls | `ShowBombs` |
| Reads | `$5D28`-`$5E45` (system); `$A030` (`SmartBombOn`); `$A06C` (`Bombs`) |
| Writes | `$5D28`-`$5DAF` (system); `$5DCD`-`$5DDC` (system); `$A02F`-`$A032` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`); `$A06C` (`Bombs`) |

### `SmartBombMark` (`$9763`)

**Start the smart bomb: SmartBombOn `$A030` = 1, 16 steps, SmartBombPtr `$5E66`; every enemy bullet stopped (the live byte +6 of the 20 records from `$5D22` set to 2)**

Writes the object pointers from ObjectTable `$5E66` (ObjectCount `$A092` records of 24 bytes) into the list at `$5D28`.

Witness: L1 50 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-room24, p1-room30, rzx-p1- x22).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 7,477 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/rzx-p1-60000` 1, `stage2/rec/p1-cursor` 1) |
| Called from | `SmartBombFree` (tail) |
| Reads | `$5D28`-`$5E45` (system) |
| Writes | `$5D28`-`$5DCD` (system); `$A02F`-`$A032` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`) |

### `SmartBombStep` (`$9786`)

**One step of a running smart bomb: KillObject on the next object record (not kinds `$FE`, `$FD`, `$FC`, `$90`; neither the alive byte nor kind `$FF` tested); CopyAttrs after the last step**

Every pass; returns at once while SmartBombOn `$A030` is 0. Each step KillObject `$981F` on the next record; after 16 steps the bomb ends with CopyAttrs `$C8BF`. A record that died in this room keeps its Y and kind, so it is killed and scored again (a spent explosion: KillScores[15], 200).

Witness: L1 18501 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 590 calls, 38,429 t-states own (0.00 %) |
| Runs (the other recordings) | 17,911 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop` |
| Calls | `KillObject`, `CopyAttrs` |
| Reads | `$5E6F`-`$5F2F` (system); `$5F47` (system); `$5F5F` (system); `$5F77` (system); `$5F8F` (system); `$5FA7` (system); 3 more ranges |
| Writes | `$A02F`-`$A032` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`) |

## score

`src/game/score.asm`

### `ShowPoints` (`$97FD`)

**Turn the object at IX into the points sign: picture SpritePoints `$81B2`, kind `$FF` (no collisions), at rest**

Witness: L1 5 (rzx-p1-24000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/rzx-p1-24000` 5) |
| Called from | `KillHuman` |
| Writes | `$5E80`-`$5EA5` (system); `$5EE0`-`$5F1D` (system) |

### `KillObject` (`$981F`)

**Kill the object at IX: its score, the kill flash in the HUD, the explosion sound; people add to HumansKilled**

The kill flash: KillFlashPtr `$A039` = the next cell of the HUD's combo row (`$5843` + 3 a hit, at rest `$E9FF`), timer `$A03C`. Kind 14 (the mine) scores nothing. Kind 5 also ends the scripted spawn (EndScriptSpawn `$9968`). Then KillHuman `$98A7` or ShowPoints `$97FD`.

Witness: L1 1016 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 96 calls, 21,650 t-states own (0.00 %) |
| Runs (the other recordings) | 920 calls (`stage1/rec/rzx-p1-02000` 48, `stage1/rec/rzx-p1-62000` 46, `stage1/rec/rzx-p1-26000` 46 and 38 more) |
| Called from | `SmartBombStep`, `DriftObject` (tail), `WalkOff` (tail), `ObjectJump` (tail), `ObjectFall` (tail), `ObjectHitsRex`, `BulletLoop`, `HitObject` (tail) |
| Calls | `KillHuman`, `EndScriptSpawn`, `AddScore`, `StartSfx` |
| Reads | `$5E66`-`$5FD7` (system); `$994E`-`$995D` (`KillScores`); `$A093`-`$A097` (`Temp1`, `Temp2`, `Temp3`) |
| Writes | `$5E67`-`$5F95` (system); `$5FB7`-`$5FC5` (system); `$A039`-`$A03D` (`KillFlashPtr`, `ComboCount`, `ComboTimer`); `$A092`-`$A097` (`ObjectCount`, `Temp1`, `Temp2`, `Temp3`) |

### `KillHuman` (`$98A7`)

**A person killed: HumansKilled `$A089` + 1, nothing else**

For kinds 0, 7, 6, 12, 4 and 5 (KillObject calls it for each). The big gun's KillScore `$98AF` follows it in memory.

Witness: L1 155 (c1, p1-speedup, p1-room24, p1-room30, rzx-p1- x27).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 48 t-states own (0.00 %) |
| Runs (the other recordings) | 154 calls (`stage1/rec/rzx-p1-58000` 13, `stage1/rec/rzx-p1-38000` 12, `stage1/rec/rzx-p1-46000` 10 and 27 more) |
| Called from | `KillObject` |
| Calls | `ShowPoints`, `AddScore`, `Random`, `KillHumanPicture`, `FindFreeObject` |
| Reads | `$A089`-`$A08A` (`HumansKilled`) |
| Writes | `$A089`-`$A08A` (`HumansKilled`) |

### `EndScriptSpawn` (`$9968`)

**Stop the scripted spawn (KillObject on a kind 5): the objects of kinds 3 and 4 lose their timer (`$9989`)**

Witness: L1 2 (rzx-p1-04000, rzx-p1-12000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/rzx-p1-04000` 1, `stage1/rec/rzx-p1-12000` 1) |
| Called from | `KillObject` |
| Calls | `StopObjectSpawn` |
| Reads | `$5E6F`-`$5EE7` (system); `$5EFF` (system); `$5F17` (system); `$5F2F` (system); `$5F47` (system); `$5F5F` (system); 3 more ranges |

### `StopObjectSpawn` (`$9989`)

**IY's object: timer (IY+`$10`) = 0, ScriptSpawnStep `$A045` = 0**

Witness: L1 10 (rzx-p1-04000, rzx-p1-12000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`stage1/rec/rzx-p1-04000` 5, `stage1/rec/rzx-p1-12000` 5) |
| Called from | `EndScriptSpawn` |
| Writes | `$5EBE` (system); `$5ED6` (system); `$5EEE` (system); `$5F06` (system); `$5F1E` (system); `$5F36` (system); 5 more ranges |

### `KillFlashFade` (`$9992`)

**Fade the HUD's kill flash one step (attribute row `$5840`, 30 cells), then mark the latest kill's two cells white**

Witness: L1 18613 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 calls, 1,042,745 t-states own (0.07 %) |
| Runs (the other recordings) | 17,911 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Reads | `$5840`-`$585D` (screen); `$A039`-`$A03A` (`KillFlashPtr`) |
| Writes | `$5843`-`$585C` (screen); `$E9FF`-`$EA0C` (`ObjectBufferOrigin`) |

### `ShowScore` (`$99AB`)

**Print Score `$A03E` in the HUD**

Witness: L1 306 (c1, p1-code, p1-shots, p1-speedup, p1-room30, rzx-p1- x31).

[Animation: `ShowScore` at work](img/routines/ShowScore.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 87 t-states own (0.00 %) |
| Runs (the other recordings) | 305 calls (`stage1/rec/rzx-p1-28000` 42, `stage1/rec/rzx-p1-58000` 26, `stage1/rec/rzx-p1-20000` 23 and 32 more) |
| Called from | `AddScore` (tail) |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$A03E`-`$A03F` (`Score`) |

### `ShowLives` (`$99BB`)

**Print Lives `$A063` in the HUD**

Witness: L1 53 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30, rzx-p1- x26).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 6 calls, 580 t-states own (0.00 %) |
| Runs (the other recordings) | 47 calls (`stage1/rec/rzx-p1-26000` 3, `stage1/rec/rzx-p1-16000` 3, `stage2/rec/p1-cursor` 3 and 29 more) |
| Called from | `NewGame`, `LifeLost`, `ExtraLife` |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$A063` (`Lives`) |

### `ShieldDrainFast` (`$99CE`)

**ShieldDrainRate `$A04E` - 1: a hit on the shield drains it faster (EnemyBulletsHitRex, ObjectHitsRex)**

Witness: L1 82 (p1-speedup, p1-room30, rzx-p1- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 82 calls (`stage1/rec/rzx-p1-54000` 15, `stage1/rec/rzx-p1-60000` 8, `stage1/rec/rzx-p1-52000` 7 and 20 more) |
| Called from | `EnemyBulletsHitRex`, `ObjectHitsRex` |
| Calls | `ShieldDrain` (falls into) |
| Writes | `$A04E` (`ShieldDrainRate`) |

### `ShieldDrain` (`$99D3`)

**With the shield on, count ShieldDrainRate down; at 0 one unit of ShieldEnergy `$A04D` goes; none left switches the shield off**

Witness: L1 2797 (p1-code, p1-cursor, p1-define, p1-kempston, p1-speedup, p1-room26, p1-room30, rzx-p1- x29).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,797 calls (`stage1/rec/rzx-p1-18000` 318, `stage1/rec/rzx-p1-46000` 170, `stage1/rec/rzx-p1-50000` 149 and 33 more) |
| Called from | `DrawRex`, `ShieldDrainFast` (falls into) |
| Calls | `ShowShield` |
| Reads | `$A04D`-`$A04E` (`ShieldEnergy`, `ShieldDrainRate`) |
| Writes | `$A049`-`$A04E` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate`) |

### `ShowShield` (`$99FA`)

**Print ShieldEnergy `$A04D` in the HUD and colour it: red when low, green otherwise (`$E513`, `$E514` in the attribute shadow)**

Witness: L1 1498 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 9 calls, 1,909 t-states own (0.00 %) |
| Runs (the other recordings) | 1,489 calls (`stage1/rec/rzx-p1-46000` 116, `stage1/rec/rzx-p1-32000` 112, `stage1/rec/rzx-p1-18000` 109 and 40 more) |
| Called from | `ShieldDrain`, `LifeLost`, `Recharge`, `BuildRoom` |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$A04D` (`ShieldEnergy`) |
| Writes | `$5814`-`$5815` (screen); `$E513`-`$E514` (`ShieldAttrs`) |

### `AddScore` (`$9A27`)

**Score `$A03E` + HL; every 100 points ExtraLifeCount `$A076` counts, at 100 an extra life (ExtraLife `$D5A0`)**

Not while Rex is dying. Jumps to ShowScore.

Witness: L1 449 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 16 calls, 597 t-states own (0.00 %) |
| Runs (the other recordings) | 433 calls (`stage1/rec/rzx-p1-28000` 42, `stage1/rec/rzx-p1-58000` 26, `stage1/rec/rzx-p1-20000` 23 and 38 more) |
| Called from | `KillObject`, `KillHuman`, `HitObject`, `HitObjectHard`, `BonusRoulette` |
| Calls | `ShowScore` (tail), `ExtraLife` |
| Reads | `$A03E`-`$A03F` (`Score`); `$A055` (`Dying`); `$A076`-`$A077` (`ExtraLifeCount`) |
| Writes | `$A03E`-`$A03F` (`Score`); `$A076`-`$A077` (`ExtraLifeCount`) |

### `FadeStep` (`$9A4C`)

**The HUD flash of a power pod (only TakePowerPod starts it): rows 0-1 (`$5800-$583F`) stepped through FadeSteps `$9AB3` by FadeStepIndex `$A042`**

Witness: L1 18613 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 calls, 23,129 t-states own (0.00 %) |
| Runs (the other recordings) | 17,911 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Reads | `$5800`-`$583F` (screen); `$9AB3`-`$9AC4` (`FadeSteps`); `$A042` (`FadeStepIndex`); `$A093` (`Temp1`); `$E4FF`-`$E53E` (`TitleScreen`, `ShieldAttrs`, `SweepAttrs`) |
| Writes | `$5800`-`$583F` (screen); `$A042` (`FadeStepIndex`); `$A093` (`Temp1`) |

## death

`src/game/death.asm`

### `DeathAnimation` (`$9AC5`)

**One pass of Rex's death: the shards, the death picture, the sound; at the end LifeLost**

The shards follow DeathShards `$9C05` (DeathShardPtr `$A057` moved by ShardNext `$9BC8` / ShardBack `$9BD1`); SpriteRexDeath `$816A`; the attribute fade SaveCellAttrs `$CF9B` / RestoreCellAttrs `$CF6E`. After DeathTimer `$A056` passes: JP LifeLost `$9C76`.

Witness: L1 758 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-room24, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 118 calls, 334,004 t-states own (0.02 %) |
| Runs (the other recordings) | 640 calls (`stage1/rec/rzx-p1-02000` 51, `stage1/rec/rzx-p1-26000` 51, `stage2/rec/p1-gameover` 50 and 21 more) |
| Called from | `RexState` (tail) |
| Calls | `DrawRex` (tail), `ShardNext`, `ShardBack`, `LifeLost` (tail), `Random`, `Random2`, `DrawSprite`, `Multiply`, `CopyCells3`, `FlashCells`, `StartSfx` |
| Reads | `$9C05`-`$9C3A` (`DeathShards`); `$A056`-`$A063` (`DeathTimer`, `DeathShardPtr`, `RestartX`, `RestartY` and 9 more); `$A093`-`$A096` (`Temp1`, `Temp2`); `$A0B6`-`$A0B7` (`RexX`, `RexY`) |
| Writes | `$9C0B`-`$9C3A` (`DeathShards+6`); `$A033`-`$A035` (`SpriteMirror`, `SpritePicture`); `$A056` (`DeathTimer`); `$A0AF`-`$A0B2` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$D790` (`SfxExplosion`) |

### `ShardNext` (`$9BC8`)

**DeathShardPtr `$A057` + 2**

Witness: L1 4 (c1, p1-gameover).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 118 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage2/rec/p1-gameover` 2) |
| Called from | `DeathAnimation` |
| Reads | `$A057`-`$A058` (`DeathShardPtr`) |
| Writes | `$A057`-`$A058` (`DeathShardPtr`) |

### `ShardBack` (`$9BD1`)

**DeathShardPtr `$A057` - 2: the shards step back**

Witness: L1 4 (c1, p1-gameover).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 108 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage2/rec/p1-gameover` 2) |
| Called from | `DeathAnimation` |
| Reads | `$A057`-`$A058` (`DeathShardPtr`) |
| Writes | `$A057`-`$A058` (`DeathShardPtr`) |

### `RexDies` (`$9BDA`)

**Rex is killed (unless Immune `$A071`): the sweep reset (ResetSweep), Dying, the timer 50, the free smart bomb, LosePower, ShieldEnergy refilled to 99, dematerialise (which switches the shield off)**

Called by the collisions (EnemyBulletsHitRex `$D1B9`, ObjectHitsRex `$D215`), the fall (RexFall `$D14D`) and the HUD sweep's end (HudSweep `$A0C4`). Resets the sweep (ResetSweep `$A133`).

Witness: L1 221 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-speedup, p1-room24, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 1,108 t-states own (0.00 %) |
| Runs (the other recordings) | 216 calls (`docs/integrate/rec/p1-speedup` 105, `docs/integrate/rec/p1-poke41241` 66, `docs/rxA/rec/p1-rooms238` 8 and 24 more) |
| Called from | `HudSweep` (tail), `RexFall`, `EnemyBulletsHitRex`, `ObjectHitsRex` |
| Calls | `SmartBombFree`, `Dematerialise`, `ResetSweep`, `LosePower` |
| Reads | `$A063`-`$A071` (`Lives`, `SweepPos`, `SweepCount`, `SweepDir` and 9 more) |
| Writes | `$A04D`-`$A058` (`ShieldEnergy`, `ShieldDrainRate`, `WeaponIcon`, `HasDoubleFire` and 7 more) |

### `SaveRestart` (`$9C3B`)

**A restart marker (cell `$07`) under Rex: save Rex's place, room and facing as the restart point, a chime**

Only when RexX & 7 = 2 (Rex centred on the marker) and the point differs from the saved one. The marker character is animated by AnimateRestart `$A5B7`.

Witness: L1 1199 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30, rzx-p1- x26).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 69 calls, 9,097 t-states own (0.00 %) |
| Runs (the other recordings) | 1,130 calls (`stage2/rec/p1-define` 138, `stage1/rec/rzx-p1-26000` 137, `stage2/rec/p1-cursor` 118 and 28 more) |
| Called from | `CellsUnderRex` (tail) |
| Calls | `AnimateRestart`, `StartSfx` |
| Reads | `$A0B6`-`$A0BB` (`RexX`, `RexY`, `Room`, `RoomColumn` and 1 more); `$D83A` (`Channels+8`); `$E2C7` (`RoomGridPlay+200`); `$E2E6`-`$E2E9` (`RoomGridPlay+231`); `$E343`-`$E352` (`ExplosionPicture+13`); `$E3A3`-`$E3B5` (`ExplosionPicture+109`); 2 more ranges |
| Writes | `$A059`-`$A05B` (`RestartX`, `RestartY`, `RestartRoom`) |

### `LifeLost` (`$9C76`)

**The end of a death: one life less; Rex back at the restart point, or the game over**

Lives `$A063` - 1; ShowLives; Rex at RestartX/Y `$A059`/`$A05A` in RestartRoom `$A05B`, the shield off, the motion cleared; Materialise `$9D1F` and JP MainLoop `$9583` (the room is built again). Lives at -1: GameOver `$9CBF`.

Witness: L1 36 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-room24, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 1,647 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/rec/rzx-p1-26000` 3, `stage1/rec/rzx-p1-02000` 3, `stage1/rec/rzx-p1-56000` 2 and 21 more) |
| Called from | `DeathAnimation` (tail), `SparkleDraw` (tail) |
| Calls | `NewGame` (tail), `MainLoop` (tail), `WaitFire`, `ShowLives`, `ShowShield`, `Materialise`, `PrintBoxed`, `PrintDigits`, `ToDigits` |
| Reads | `$A03E`-`$A03F` (`Score`); `$A059`-`$A063` (`RestartX`, `RestartY`, `RestartRoom`, `RestartFacing` and 7 more); `$A089`-`$A08C` (`HumansKilled`, `HiScore`); `$A0B8` (`Room`) |
| Writes | `$A049`-`$A063` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate` and 20 more); `$A08B`-`$A091` (`HiScore`, `RoomRight`, `RoomUp`, `RoomDown` and 2 more); `$A0B3`-`$A0BD` (`RexFrame`, `RexX`, `RexY`, `Room` and 4 more) |

### `RexAppears` (`$9D0F`)

**The materialise is over: RexPresent `$A05D` = 1 (Rex can move and fire), SparkleCount `$A05E` = 18**

Witness: L1 2042 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30, rzx-p1- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 232 calls, 7,099 t-states own (0.00 %) |
| Runs (the other recordings) | 1,810 calls (`stage1/rec/rzx-p1-02000` 163, `stage2/rec/p1-cursor` 144, `stage1/rec/rzx-p1-26000` 139 and 22 more) |
| Called from | `SparkleDraw` |
| Reads | `$A05D` (`RexPresent`) |
| Writes | `$A05D`-`$A05E` (`RexPresent`, `SparkleCount`) |

### `Materialise` (`$9D1F`)

**Rex appears: RexPresent 0, the sparkle in (SparkleOn `$A05F`, SparkleMode `$A060`), its dots cleared, the materialise sound `$D7AE`**

Witness: L1 40 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30, rzx-p1- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 6,978 t-states own (0.00 %) |
| Runs (the other recordings) | 35 calls (`stage1/rec/rzx-p1-26000` 3, `stage2/rec/p1-cursor` 3, `stage1/rec/rzx-p1-02000` 3 and 21 more) |
| Called from | `NewGame`, `LifeLost` |
| Calls | `StartSfx` |
| Reads | `$9F14`-`$9F4E` (`SparkleDots`) |
| Writes | `$9F14`-`$9F4F` (`SparkleDots`); `$A05D`-`$A062` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more) |

### `Dematerialise` (`$9D47`)

**Rex vanishes: the shield off, the sparkle out (Vanishing `$A062` = 1), the sound `$D7BA`**

Witness: L1 40 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 737 t-states own (0.00 %) |
| Runs (the other recordings) | 36 calls (`stage1/rec/rzx-p1-40000` 3, `stage1/rec/rzx-p1-26000` 3, `stage1/rec/rzx-p1-02000` 3 and 20 more) |
| Called from | `RexDies` |
| Calls | `StartSfx` |
| Reads | `$A05D` (`RexPresent`) |
| Writes | `$A049` (`ShieldOn`); `$A05D`-`$A062` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more) |

### `SparkleUpdate` (`$9D71`)

**One step of the sparkle in Rex's 3-byte box of the back buffer (SparkleBufferOrigin `$E89F`): SparkleCount lines cleared, the next 3 ANDed with random bytes; at the end the sparkle stops**

Witness: L1 18526 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `SparkleUpdate` at work](img/routines/SparkleUpdate.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 592 calls, 206,517 t-states own (0.01 %) |
| Runs (the other recordings) | 17,934 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop` |
| Calls | `FillCells3`, `Random` |
| Reads | `$A05D`-`$A062` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more); `$A0B6`-`$A0B7` (`RexX`, `RexY`); `$ECD3`-`$EE92` (`BackBuffer+467`); `$EEC8`-`$EF47` (`BackBuffer+968`); `$EF68`-`$EFAA` (`BackBuffer+1128`); `$EFC4`-`$F253` (`BackBuffer+1220`); 17 more ranges |
| Writes | `$A05D`-`$A061` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 1 more); `$ECD3`-`$EE92` (`BackBuffer+467`); `$EEC8`-`$EF47` (`BackBuffer+968`); `$EF68`-`$EFAA` (`BackBuffer+1128`); `$EFC4`-`$F253` (`BackBuffer+1220`); `$F266`-`$FA76` (`BackBuffer+1894`); 16 more ranges |

### `SparkleDeadCode` (`$9DC9`)

**LD A,100: LD (`$A061`),A after a JP: no instruction reaches it (leftover)**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SparkleOut` (`$9DCE`)

**Vanishing: SparkleCount `$A05E` + 1; at 18 Rex is gone (RexPresent 0) and the sparkle's timer is 30**

Witness: L1 658 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 68 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 590 runs of its first instruction, entered by a jump (`stage1/rec/rzx-p1-02000` 51, `stage1/rec/rzx-p1-26000` 51, `stage1/rec/rzx-p1-40000` 41 and 20 more) |

### `SparkleIfOn` (`$9DEE`)

**If SparkleOn `$A05F`, SparkleDraw: no instruction calls it (leftover)**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillCells3` (`$9DF6`)

**Write C into a 3 x 3 patch at HL (32-byte rows)**

Witness: L1 1381 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30, rzx-p1- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 158 calls, 86,416 t-states own (0.01 %) |
| Runs (the other recordings) | 1,223 calls (`stage1/rec/rzx-p1-26000` 105, `stage1/rec/rzx-p1-02000` 105, `stage1/rec/rzx-p1-40000` 77 and 23 more) |
| Called from | `SparkleUpdate` |
| Writes | `$EBB3`-`$FB37` (`BackBuffer+179`); `$FB4C`-`$FB97` (`BackBuffer+4172`); `$FBAC`-`$FBB7` (`BackBuffer+4268`); `$FBCC`-`$FBCE` (`BackBuffer+4300`); `$FBEC`-`$FBEE` (`BackBuffer+4332`); `$FC0C`-`$FC0E` (`BackBuffer+4364`); 6 more ranges |

### `SparkleDraw` (`$9E02`)

**Draw the sparkle's particles round Rex (SparkleMasks `$9F0C`, SparkleDots `$9F14`); at the end of a dematerialise LifeLost**

Witness: L1 18526 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 592 calls, 3,040,632 t-states own (0.21 %) |
| Runs (the other recordings) | 17,934 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop` |
| Calls | `LifeLost` (tail), `RexAppears`, `Random2` |
| Reads | `$9F0C`-`$9F4F` (`SparkleMasks`, `SparkleDots`); `$A055`-`$A062` (`Dying`, `DeathTimer`, `DeathShardPtr`, `RestartX` and 9 more); `$A093` (`Temp1`); `$A0B6`-`$A0B7` (`RexX`, `RexY`); `$EB01`-`$FFE9` (`BackBuffer+1`) |
| Writes | `$9F14`-`$9F4F` (`SparkleDots`); `$A05D`-`$A061` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 1 more); `$A093` (`Temp1`); `$A0B7` (`RexY`); `$EB01`-`$FFE9` (`BackBuffer+1`) |

## cells

`src/game/cells.asm`

### `CellsUnderRex` (`$9F5F`)

**Test the cells under Rex and act: lift, restart marker, recharger, weapon stations**

Witness: L1 16633 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 353 calls, 76,986 t-states own (0.01 %) |
| Runs (the other recordings) | 16,280 calls (`docs/integrate/rec/p1-speedup` 682, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 473 and 43 more) |
| Called from | `MainLoop` |
| Calls | `SaveRestart` (tail), `StationSpray` (tail), `Recharge` (tail), `GiveDoubleFire`, `GiveLaser`, `GiveMultiple`, `StartJump`, `Land`, `WeaponPanel` |
| Reads | `$A019`-`$A01A` (`RexCellPtr`); `$A049`-`$A04D` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`); `$A0B7` (`RexY`); `$D83A` (`Channels+8`); `$E229`-`$E4B1` (`RoomGridPlay+42`, `ExplosionPicture`); `$E4C3`-`$E4F8` (`ExplosionPicture+397`) |
| Writes | `$A04D` (`ShieldEnergy`); `$A07A` (`OnLift`); `$A091` (`RexSpeed`); `$A0BC` (`FallSpeed`) |

### `StationSpray` (`$9FDF`)

**The spray station (`$0C`): GiveSpray `$A79D` and the SPRAY panel (SprayText `$ABCA`)**

Witness: L1 69 (rzx-p1- x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 69 calls (`stage1/rec/rzx-p1-28000` 29, `stage1/rec/rzx-p1-34000` 14, `stage1/rec/rzx-p1-46000` 12 and 2 more) |
| Called from | `CellsUnderRex` (tail) |
| Calls | `GiveSpray`, `WeaponPanel` |
| Reads | `$E396`-`$E397` (`ExplosionPicture+96`) |

### `Recharge` (`$9FEE`)

**The recharger (`$08`): ShieldEnergy + 1 up to 99 while the shield is off, the recharge sound**

Witness: L1 990 (p1-speedup, rzx-p1- x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 478 calls (`stage1/rec/rzx-p1-14000` 88, `stage1/rec/rzx-p1-46000` 78, `stage1/rec/rzx-p1-08000` 71 and 8 more) |
| Called from | `CellsUnderRex` (tail) |
| Calls | `ShowShield`, `StartSfx` |
| Reads | `$A049`-`$A04D` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`); `$D83A` (`Channels+8`); `$E26B` (`RoomGridPlay+108`); `$E2C5`-`$E2CB` (`RoomGridPlay+198`); `$E32E` (`RoomGridPlay+303`); `$E354`-`$E355` (`ExplosionPicture+30`); 2 more ranges |
| Writes | `$A04D` (`ShieldEnergy`) |

## hud

`src/game/hud.asm`

### `HudSweep` (`$A0C4`)

**One step of the HUD sweep (none while FadeStepIndex is not `$FF`); every 5 round trips one narrower; the width dropping to 0 kills Rex**

Witness: L1 18614 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 calls, 149,908 t-states own (0.01 %) |
| Runs (the other recordings) | 17,912 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `RexDies` (tail) |
| Reads | `$582C`-`$5838` (screen); `$A042` (`FadeStepIndex`); `$A064`-`$A067` (`SweepPos`, `SweepCount`, `SweepDir`, `SweepWidth`) |
| Writes | `$582B`-`$5838` (screen); `$A064`-`$A067` (`SweepPos`, `SweepCount`, `SweepDir`, `SweepWidth`); `$E52C`-`$E536` (`SweepAttrs+1`) |

### `ResetSweep` (`$A133`)

**The sweep back to full width (BuildRoom, RexDies)**

Witness: L1 122 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 12 calls, 611 t-states own (0.00 %) |
| Runs (the other recordings) | 110 calls (`stage1/rec/rzx-p1-02000` 7, `stage1/rec/rzx-p1-16000` 5, `stage1/rec/rzx-p1-40000` 4 and 40 more) |
| Called from | `RexDies`, `BuildRoom` |
| Writes | `$A065`-`$A067` (`SweepCount`, `SweepDir`, `SweepWidth`) |

### `PrintBoxed` (`$A13E`)

**Print B text records from IX in a framed box (attribute A, box from the first record), the panel sound**

Witness: L1 52 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 14 calls, 38,235 t-states own (0.00 %) |
| Runs (the other recordings) | 38 calls (`docs/rxA/rec/menu-rollcall` 10, `stage2/rec/p1-cursor` 5, `stage2/rec/p1-define` 4 and 11 more) |
| Called from | `NewGame`, `LifeLost`, `CodePanel`, `BonusRoulette`, `WeaponPanel`, `TitleMenu`, `RollCallText`, `DefineKeys`, `Confirm` |
| Calls | `PrintTextHL`, `PanelBox` |
| Reads | `$A093`-`$A095` (`Temp1`, `Temp2`); `$A885`-`$A89C` (`CodeText+1`, `CodeDigits`); `$AAAF`-`$AB53` (`GameTexts+1`, `GameOverText`, `HiScoreText`, `HumansKilledText` and 2 more); `$ABA3`-`$ABD4` (`DoubleFireText+3`, `LaserText`, `MultipleText`, `SprayText`); `$DC27`-`$DD4C` (`RollCallTexts+1`); `$DF06`-`$DFD9` (`MenuTexts+1`, `ConfirmSinclairText`, `ConfirmCursorText`, `ConfirmKempstonText` and 2 more) |
| Writes | `$A093`-`$A095` (`Temp1`, `Temp2`) |

### `DrawHud` (`$A1A5`)

**Draw the HUD: its texts (HudTexts `$A24C`), the frame, the weapon icons and the bombs**

Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000, rzx-p1-64000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 315 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage2/rec/p1-cursor` 2, `stage1/rec/rzx-p1-64000` 1, `stage2/rec/p1-code` 1 and 3 more) |
| Called from | `NewGame` |
| Calls | `ShowWeaponIcons`, `PrintTextHL`, `FillAttrs` |
| Reads | `$A06C` (`Bombs`) |

### `ShowBombs` (`$A1C9`)

**Draw the bomb icons for Bombs `$A06C` (BombIcons `$A202`)**

Witness: L1 20 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 293 t-states own (0.00 %) |
| Runs (the other recordings) | 10 calls (`stage1/rec/rzx-p1-58000` 2, `stage1/rec/rzx-p1-52000` 2, `stage2/rec/p1-cursor` 1 and 5 more) |
| Called from | `SmartBomb`, `TakeBombPod` |
| Calls | `DrawBombIcons` |
| Reads | `$A06C` (`Bombs`) |

### `DrawBombIcons` (`$A1DB`)

**Three icons from HL: the column at `$A1F3` from 25**

Witness: L1 20 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 calls, 81 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage2/rec/p1-cursor` 3, `stage1/rec/rzx-p1-00000` 2, `stage1/rec/rzx-p1-52000` 2 and 9 more) |
| Called from | `ShowBombs` |
| Calls | `DrawHudIcon` (falls into) |
| Writes | `$A1F3` (`HudIconParams+2`) |

### `DrawHudIcon` (`$A1E2`)

**One HUD icon: SpriteHudIcons `$8C0A` + offset (HL), by DrawCharBlock `$D8C0` with the inline parameters**

Witness: L1 60 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 9 calls, 938 t-states own (0.00 %) |
| Runs (the other recordings) | 51 calls (`stage2/rec/p1-cursor` 9, `stage1/rec/rzx-p1-00000` 6, `stage1/rec/rzx-p1-52000` 6 and 9 more) |
| Called from | `DrawBombIcons` (falls into), `NextHudIcon` (tail) |
| Calls | `DrawCharBlock` |
| Reads | `$A202`-`$A210` (`BombIcons`) |
| Writes | `$A1F1`-`$A1F2` (`HudIconParams`) |

### `NextHudIcon` (`$A1F7`)

**The next icon two columns on**

Witness: L1 60 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 9 calls, 816 t-states own (0.00 %) |
| Runs (the other recordings) | 51 calls (`stage2/rec/p1-cursor` 9, `stage1/rec/rzx-p1-00000` 6, `stage1/rec/rzx-p1-52000` 6 and 9 more) |
| Called from | `DrawCharBlock` |
| Calls | `DrawHudIcon` (tail) |
| Reads | `$A1F3` (`HudIconParams+2`) |
| Writes | `$A1F3` (`HudIconParams+2`) |

### `ShowWeaponIcons` (`$A212`)

**Draw the weapon icons: WeaponIcon `$A04F` selects the lit one**

Witness: L1 104 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x9).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 94 t-states own (0.00 %) |
| Runs (the other recordings) | 102 calls (`stage1/rec/rzx-p1-10000` 31, `stage1/rec/rzx-p1-18000` 23, `stage1/rec/rzx-p1-00000` 12 and 10 more) |
| Called from | `DrawHud`, `GiveSpray` |
| Calls | `DrawWeaponIcon` (falls into) |
| Writes | `$A235` (`WeaponIconParams+2`) |

### `DrawWeaponIcon` (`$A21F`)

**One weapon icon: SpriteHudIcons2 `$8CAA` + offset, DrawCharBlock with the inline parameters**

Witness: L1 520 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x9).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 10 calls, 1,154 t-states own (0.00 %) |
| Runs (the other recordings) | 510 calls (`stage1/rec/rzx-p1-10000` 155, `stage1/rec/rzx-p1-18000` 115, `stage1/rec/rzx-p1-00000` 60 and 10 more) |
| Called from | `ShowWeaponIcons` (falls into), `NextWeaponIcon` (tail) |
| Calls | `DrawCharBlock` |
| Reads | `$A04F`-`$A053` (`WeaponIcon`, `HasDoubleFire`, `HasLaser`, `HasMultiple` and 1 more) |
| Writes | `$A233`-`$A234` (`WeaponIconParams`) |

### `NextWeaponIcon` (`$A239`)

**The next weapon icon two columns on**

Witness: L1 520 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x9).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 10 calls, 1,244 t-states own (0.00 %) |
| Runs (the other recordings) | 510 calls (`stage1/rec/rzx-p1-10000` 155, `stage1/rec/rzx-p1-18000` 115, `stage1/rec/rzx-p1-00000` 60 and 10 more) |
| Called from | `DrawCharBlock` |
| Calls | `DrawWeaponIcon` (tail) |
| Reads | `$A235` (`WeaponIconParams+2`) |
| Writes | `$A235` (`WeaponIconParams+2`) |

### `BufferToScreen` (`$A28A`)

**Copy the back buffer's 168 play lines to the screen through ScreenLines `$AC0D` (the stack as the pointer)**

Witness: L1 18698 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `BufferToScreen` at work](img/routines/BufferToScreen.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 710 calls, 69,334,164 t-states own (4.78 %) |
| Runs (the other recordings) | 17,988 calls (`docs/integrate/rec/p1-speedup` 688, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 523 and 43 more) |
| Called from | `MainLoop`, `BuildRoom`, `Attract`, `BonusRoulette`, `WeaponPanel` |
| Reads | `$A093`-`$A094` (`Temp1`); `$EB00`-`$FFFD` (`BackBuffer`, `work space $FFFA+`) |
| Writes | `$4061`-`$57FE` (screen); `$9C79` (`LifeLost+3`); `$A013` (`Weapon`); `$A053`-`$A071` (`HasSpray`, `EnemyShotKind`, `Dying`, `DeathTimer` and 24 more); `$A08D`-`$A094` (`RoomRight`, `RoomUp`, `RoomDown`, `RoomLeft` and 3 more); `$A0B6` (`RexX`) |

### `PrintTextHL` (`$A2DF`)

**Print the text record at HL (PrintText)**

Witness: L1 142 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 21 calls, 3,025 t-states own (0.00 %) |
| Runs (the other recordings) | 50 calls (`docs/rxA/rec/menu-rollcall` 10, `stage2/rec/p1-define` 10, `stage2/rec/p1-cursor` 7 and 11 more) |
| Called from | `PrintBoxed`, `DrawHud`, `DefineKeys` |
| Calls | `PrintText` |

### `PrintChar` (`$A2E9`)

**Print character A at column Temp2, line Temp3 (pixels) from Font `$60E0` through ScreenLineTable `$ABDD`**

Witness: L1 1949 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 500 calls, 93,487 t-states own (0.01 %) |
| Runs (the other recordings) | 1,449 calls (`stage2/rec/p1-cursor` 260, `docs/rxA/rec/menu-rollcall` 215, `stage2/rec/p1-define` 201 and 11 more) |
| Called from | `PrintText` |
| Reads | `$A097` (`Temp3`); `$A24F`-`$A288` (`HudTexts+3`); `$A887`-`$A89B` (`CodeText+3`, `CodeDigits`); `$AAB1`-`$ABD3` (`GameTexts+3`, `GameOverText`, `HiScoreText`, `HumansKilledText` and 10 more); `$DC29`-`$DD4B` (`RollCallTexts+3`); `$DF08`-`$E009` (`MenuTexts+3`, `ConfirmSinclairText`, `ConfirmCursorText`, `ConfirmKempstonText` and 7 more) |

### `PrintText` (`$A307`)

**Print a text record: [attribute][column][line] characters, 0 ends; the attributes set**

Witness: L1 152 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).

[Animation: `PrintText` at work](img/routines/PrintText.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 44 calls, 730,529 t-states own (0.05 %) |
| Runs (the other recordings) | 108 calls (`docs/rxA/rec/menu-rollcall` 20, `stage2/rec/p1-define` 20, `stage2/rec/p1-cursor` 17 and 11 more) |
| Called from | `PrintTextHL`, `BonusRoulette` |
| Calls | `PrintChar` |
| Reads | `$60E0`-`$611F` (`Font`); `$6150`-`$61B7` (`Font+112`); `$61E0`-`$62AF` (`Font+256`); `$62C0`-`$62DF` (`Font+480`); `$A093`-`$A097` (`Temp1`, `Temp2`, `Temp3`); `$A24C`-`$A289` (`HudTexts`); 8 more ranges |
| Writes | `$400C`-`$57DE` (screen); `$580C`-`$586D` (screen); `$58A3`-`$58BC` (screen); `$5905`-`$590D` (screen); `$5946`-`$5975` (screen); `$5987`-`$5999` (screen); 3 more ranges |

### `Random` (`$A375`)

**A = a random byte: the byte at RandomSeed `$A0A1` (walking `$0000-$3FFF`, the ROM) plus R**

Witness: L1 56999 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,565 calls, 260,929 t-states own (0.02 %) |
| Runs (the other recordings) | 54,434 calls (`docs/integrate/rec/p1-speedup` 3,570, `stage1/rec/rzx-p1-62000` 2,656, `stage1/rec/rzx-p1-32000` 2,386 and 43 more) |
| Called from | `DrawRex`, `KillHuman`, `DeathAnimation`, `SparkleUpdate`, `UpdateObject`, `BigGun`, `ShootForward`, `ShootBoth`, `ShootersFire`, `SwingGun`, `BlowUp`, `MineBurst`, `Climb`, `GroundWalker`, `MaybeJumpRight`, `MaybeJumpLeft`, `SetHop`, `MaybeJumper`, `SpawnRandom`, `SpawnFromLeft`, `SpawnFromRight`, `SpawnFromTop`, `BonusRoulette` |
| Reads | `$A0A1` (`RandomSeed`) |
| Writes | `$A0A1` (`RandomSeed`) |

### `Random2` (`$A388`)

**A = a random byte from RandomSeed2 `$A0A3` and R**

Witness: L1 14250 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x29).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,196 calls, 1,210,054 t-states own (0.08 %) |
| Runs (the other recordings) | 13,054 calls (`docs/integrate/rec/p1-poke41241` 2,010, `stage1/rec/rzx-p1-02000` 831, `stage1/rec/rzx-p1-16000` 725 and 38 more) |
| Called from | `DeathAnimation`, `SparkleDraw`, `LauncherFire`, `RandomSign`, `SpawnObject` |
| Reads | `$A093`-`$A0A3` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 3 more) |
| Writes | `$A093`-`$A0A3` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 3 more) |

### `ClearScreen` (`$A3AE`)

**Clear the screen's bitmap and attributes**

Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000, rzx-p1-64000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 407,260 t-states own (0.03 %) |
| Runs (the other recordings) | 7 calls (`stage2/rec/p1-cursor` 2, `stage1/rec/rzx-p1-64000` 1, `stage2/rec/p1-code` 1 and 3 more) |
| Called from | `NewGame` |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |

### `PrintDigits` (`$A3C8`)

**Print B digits of Digits `$A0A6` at HL on the screen**

Witness: L1 1861 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 18 calls, 10,078 t-states own (0.00 %) |
| Runs (the other recordings) | 1,843 calls (`stage1/rec/rzx-p1-46000` 130, `stage1/rec/rzx-p1-38000` 123, `stage1/rec/rzx-p1-32000` 121 and 43 more) |
| Called from | `ShowScore`, `ShowLives`, `ShowShield`, `LifeLost` |
| Calls | `ScreenDown` |
| Reads | `$A0A6`-`$A0AA` (`Digits`); `$ABDD`-`$ABDE` (`ScreenLineTable`); `$AC9D`-`$AC9E` (`ScreenLines+144`); `$ACDD`-`$ACDE` (`ScreenLines+208`) |

### `ScreenDown` (`$A3F9`)

**HL one pixel line down the screen**

Witness: L1 4599 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 39 calls, 12,424 t-states own (0.00 %) |
| Runs (the other recordings) | 4,560 calls (`stage1/rec/rzx-p1-28000` 315, `stage1/rec/rzx-p1-46000` 298, `stage1/rec/rzx-p1-38000` 288 and 43 more) |
| Called from | `PrintDigits` |
| Reads | `$6160`-`$61AF` (`Font+128`) |
| Writes | `$400C`-`$4717` (screen); `$4890`-`$4994` (screen); `$4A90`-`$4A94` (screen); `$4B90`-`$4B94` (screen); `$4C90`-`$4C94` (screen); `$4D90`-`$4D94` (screen); 2 more ranges |

### `ToDigits` (`$A402`)

**HL into five decimal digits at Digits `$A0A6` (units first)**

Witness: L1 1866 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 18 calls, 6,142 t-states own (0.00 %) |
| Runs (the other recordings) | 1,848 calls (`stage1/rec/rzx-p1-46000` 130, `stage1/rec/rzx-p1-38000` 123, `stage1/rec/rzx-p1-32000` 121 and 43 more) |
| Called from | `ShowScore`, `ShowLives`, `ShowShield`, `LifeLost`, `CodePanel` |
| Calls | `DigitOf` |
| Writes | `$A0A4`-`$A0AA` (`DigitTemp`, `Digits`) |

### `DigitOf` (`$A447`)

**One digit: count how many times DE goes into HL**

Witness: L1 9330 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 90 calls, 26,192 t-states own (0.00 %) |
| Runs (the other recordings) | 9,240 calls (`stage1/rec/rzx-p1-46000` 650, `stage1/rec/rzx-p1-38000` 615, `stage1/rec/rzx-p1-32000` 605 and 43 more) |
| Called from | `ToDigits` |
| Reads | `$A0A4`-`$A0A5` (`DigitTemp`) |
| Writes | `$A0A4`-`$A0A5` (`DigitTemp`) |

## controls

`src/game/controls.asm`

### `SetFire` (`$A46A`)

**Fire reads DefinePort `$A0AB`, bit DefineBit `$A0AD` (the operands at `$A478`, `$A481`)**

Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage2/rec/p1-kempston` 1, `stage1/rec/rzx-p1-00000` 1, `stage2/rec/p1-cursor` 1 and 1 more) |
| Called from | `DefineKeys`, `ChooseKempston`, `ChooseSinclair`, `ChooseCursor` |
| Reads | `$A0AB`-`$A0AD` (`DefinePort`, `DefineBit`) |
| Writes | `$A478`-`$A481` (`ReadFire+1`, `ReadFireBit`) |

### `ReadFire` (`$A477`)

**Z = fire pressed (default O, `$DFFE` bit 1)**

Witness: L1 3033772 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 383,671 calls, 22,674,536 t-states own (1.56 %) |
| Runs (the other recordings) | 2,650,102 calls (`stage2/rec/p1-gameover` 883,168, `stage2/rec/p1-code` 833,700, `stage1/rec/rzx-p1-64000` 598,969 and 44 more) |
| Called from | `MainLoop`, `WaitFireOrAttract`, `WaitFire`, `Pause`, `Attract`, `BonusRoulette` |
| Reads | `$A0AE` (`ControlXor`) |
| Ports in | `$001F`, `$7FFE`, `$DFFE`, `$EFFE` |

### `SetLeft` (`$A483`)

**Left reads DefinePort, DefineBit**

Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage2/rec/p1-kempston` 1, `stage1/rec/rzx-p1-00000` 1, `stage2/rec/p1-cursor` 1 and 1 more) |
| Called from | `DefineKeys`, `ChooseKempston`, `ChooseSinclair`, `ChooseCursor` |
| Reads | `$A0AB`-`$A0AD` (`DefinePort`, `DefineBit`) |
| Writes | `$A491`-`$A49A` (`ReadLeft+1`, `ReadLeftBit`) |

### `ReadLeft` (`$A490`)

**Z = left pressed (default Q)**

Witness: L1 16946 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 calls, 21,265 t-states own (0.00 %) |
| Runs (the other recordings) | 16,590 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-20000` 589 and 43 more) |
| Called from | `MainLoop`, `Scanner` |
| Reads | `$A0AE` (`ControlXor`) |
| Ports in | `$001F`, `$EFFE`, `$F7FE`, `$FBFE`, `$FEFE` |

### `SetRight` (`$A49C`)

**Right reads DefinePort, DefineBit**

Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage2/rec/p1-cursor` 1, `stage1/rec/rzx-p1-00000` 1, `stage2/rec/p1-define` 1 and 1 more) |
| Called from | `DefineKeys`, `ChooseKempston`, `ChooseSinclair`, `ChooseCursor` |
| Reads | `$A0AB`-`$A0AD` (`DefinePort`, `DefineBit`) |
| Writes | `$A4AA`-`$A4B3` (`ReadRight+1`, `ReadRightBit`) |

### `ReadRight` (`$A4A9`)

**Z = right pressed (default W)**

Witness: L1 16976 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 calls, 21,500 t-states own (0.00 %) |
| Runs (the other recordings) | 16,620 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-20000` 597 and 43 more) |
| Called from | `MainLoop`, `Scanner` |
| Reads | `$A0AE` (`ControlXor`) |
| Ports in | `$001F`, `$EFFE`, `$FBFE`, `$FEFE` |

### `SetUp` (`$A4B5`)

**Up reads DefinePort, DefineBit**

Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/rzx-p1-00000` 1, `stage2/rec/p1-cursor` 1, `stage2/rec/p1-define` 1 and 1 more) |
| Called from | `DefineKeys`, `ChooseKempston`, `ChooseSinclair`, `ChooseCursor` |
| Reads | `$A0AB`-`$A0AD` (`DefinePort`, `DefineBit`) |
| Writes | `$A4C3`-`$A4CC` (`ReadUp+1`, `ReadUpBit`) |

### `ReadUp` (`$A4C2`)

**Z = up (jump) pressed (default I)**

Witness: L1 16687 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 calls, 21,466 t-states own (0.00 %) |
| Runs (the other recordings) | 16,331 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 474 and 43 more) |
| Called from | `MainLoop` |
| Reads | `$A0AE` (`ControlXor`) |
| Ports in | `$001F`, `$DFFE`, `$EFFE` |

### `SetDown` (`$A4CE`)

**Down reads DefinePort, DefineBit**

Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage2/rec/p1-cursor` 1, `stage2/rec/p1-kempston` 1, `stage1/rec/rzx-p1-00000` 1 and 1 more) |
| Called from | `DefineKeys`, `ChooseKempston`, `ChooseSinclair`, `ChooseCursor` |
| Reads | `$A0AB`-`$A0AD` (`DefinePort`, `DefineBit`) |
| Writes | `$A4DC`-`$A4E5` (`ReadDown+1`, `ReadDownBit`) |

### `ReadDown` (`$A4DB`)

**Z = down (the shield) pressed (default J)**

Witness: L1 37004 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,180 calls, 70,442 t-states own (0.00 %) |
| Runs (the other recordings) | 35,824 calls (`docs/integrate/rec/p1-speedup` 1,370, `docs/integrate/rec/p1-poke41241` 1,340, `stage1/rec/rzx-p1-18000` 1,040 and 43 more) |
| Called from | `MainLoop` |
| Reads | `$A0AE` (`ControlXor`) |
| Ports in | `$001F`, `$BFFE`, `$EFFE` |

### `Pause` (`$A4E7`)

**H: silence; loop while fire is not pressed (ReadFire); the sound back**

Witness: L1 51872 (c1, p1-cursor).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 1,445,697 t-states own (0.10 %) |
| Runs (the other recordings) | 1 call (`stage2/rec/p1-cursor` 1) |
| Called from | `MainLoop` |
| Calls | `ReadFire`, `SoundReset`, `SoundSilence` |

### `OrChar` (`$A4F4`)

**OR the 8 bytes at DE into the buffer at HL (32-byte rows)**

Witness: L1 23346 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

[Animation: `OrChar` at work](img/routines/OrChar.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 768 calls, 541,056 t-states own (0.04 %) |
| Runs (the other recordings) | 22,578 calls (`stage1/rec/rzx-p1-62000` 1,536, `stage1/rec/rzx-p1-20000` 1,230, `stage1/rec/rzx-p1-58000` 1,200 and 39 more) |
| Called from | `DrawShard` |
| Reads | `$AA6E`-`$AAAD` (`ShardPictures`); `$EAFF`-`$EBDF` (`BufferPlayOrigin`, `BackBuffer`); `$EC00`-`$FFBF` (`BackBuffer+256`) |
| Writes | `$EAFF`-`$EBDF` (`BufferPlayOrigin`, `BackBuffer`); `$EC00`-`$FFBF` (`BackBuffer+256`) |

## grid

`src/game/grid.asm`

### `CellPointer` (`$A503`)

**HL = the grid cell of SpriteX/SpriteY (`$E19F` + 32 x (Y / 8) + X / 8; A = 1 the grid from `$E19E`)**

Witness: L1 233965 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3,839 calls, 1,013,863 t-states own (0.07 %) |
| Runs (the other recordings) | 230,126 calls (`docs/integrate/rec/p1-speedup` 9,344, `stage1/rec/rzx-p1-20000` 9,342, `stage1/rec/rzx-p1-46000` 8,855 and 43 more) |
| Called from | `MainLoop`, `StepShot`, `FlyBounce`, `ScannerTurn`, `ObjectJump`, `ObjectCell`, `SpawnFromTop`, `FindGround`, `RexFall` |
| Reads | `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |

### `BufferAddress` (`$A535`)

**HL = the back buffer address of SpriteX / SpriteY**

Witness: L1 4835 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 600 calls, 133,602 t-states own (0.01 %) |
| Runs (the other recordings) | 4,235 calls (`stage2/rec/p1-gameover` 508, `stage1/rec/rzx-p1-62000` 256, `stage1/rec/rzx-p1-20000` 205 and 39 more) |
| Called from | `FlashCells` |
| Reads | `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |

### `AnimateCells` (`$A55E`)

**Every other pass: the animated characters' next frames (AnimFramesA `$AE8D`, AnimFramesB `$AEAD`, the frame lists `$A60C`, `$A61A`)**

Witness: L1 18560 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 699 calls, 581,858 t-states own (0.04 %) |
| Runs (the other recordings) | 17,861 calls (`docs/integrate/rec/p1-speedup` 682, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 519 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `AnimateCells2`, `CopyFrame` (tail) |
| Reads | `$A017` (`PassToggle`); `$AE8D`-`$AECC` (`AnimFramesA`, `AnimFramesB`) |
| Writes | `$6BC0`-`$6BDF` (`AnimChar252`) |

### `AnimateCells2` (`$A5A7`)

**The frames of character 250 from FramesList2 `$A602`**

Witness: L1 18560 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 699 calls, 37,746 t-states own (0.00 %) |
| Runs (the other recordings) | 17,861 calls (`docs/integrate/rec/p1-speedup` 682, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 519 and 43 more) |
| Called from | `AnimateCells` |
| Calls | `CopyFrame` (tail) |

### `AnimateRestart` (`$A5B7`)

**The restart marker's frames (character 249, FramesList3 `$A5F4`)**

Witness: L1 833 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30, rzx-p1- x23).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 49 calls, 2,156 t-states own (0.00 %) |
| Runs (the other recordings) | 784 calls (`stage2/rec/p1-define` 134, `stage2/rec/p1-cursor` 109, `stage1/rec/rzx-p1-02000` 66 and 25 more) |
| Called from | `SaveRestart` |
| Calls | `CopyFrame` (falls into) |

### `CopyFrame` (`$A5C4`)

**Copy the frame at HL into the character at DE (8 bytes), from the list position Temp1**

Witness: L1 56514 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,146 calls, 1,127,658 t-states own (0.08 %) |
| Runs (the other recordings) | 54,368 calls (`docs/integrate/rec/p1-speedup` 2,046, `docs/integrate/rec/p1-poke41241` 2,010, `stage1/rec/rzx-p1-18000` 1,581 and 43 more) |
| Called from | `AnimateCells` (tail), `AnimateCells2` (tail), `AnimateRestart` (falls into) |
| Reads | `$8D2A`-`$8D89` (`SpriteBonusPod2+32`); `$9412`-`$9471` (`SpriteHuman+288`); `$A069`-`$A06B` (`AnimCount1`, `AnimCount2`, `AnimCount3`); `$A07C` (`AnimCount4`); `$A093`-`$A096` (`Temp1`, `Temp2`); `$A5F4`-`$A626` (`FramesList3`, `FramesList2`, `FramesList1`, `FramesList4`) |
| Writes | `$6600`-`$6607` (`AnimChar68`); `$67D8`-`$67DF` (`AnimChar127`); `$6BA8`-`$6BBF` (`AnimChar249`, `AnimChar250`); `$A069`-`$A06B` (`AnimCount1`, `AnimCount2`, `AnimCount3`); `$A07C` (`AnimCount4`); `$A093`-`$A096` (`Temp1`, `Temp2`) |

### `InitDrones` (`$A628`)

**The drones' table at `$5E50`: 8 records of 3 bytes, the angles 0, 8, 16, ... 56**

Witness: L1 42 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 832 t-states own (0.00 %) |
| Runs (the other recordings) | 40 calls (`stage1/rec/rzx-p1-34000` 4, `stage1/rec/rzx-p1-12000` 4, `stage1/rec/rzx-p1-00000` 3 and 20 more) |
| Called from | `NewGame`, `PowerGain` |
| Writes | `$5E50`-`$5E65` (system) |

### `UpdateDrones` (`$A639`)

**The multiple weapon (Weapon 3): the drones orbit Rex (DroneOrbit `$A6CB`) and are drawn (DronePicture `$A74B`), one per power level**

Witness: L1 18528 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `UpdateDrones` at work](img/routines/UpdateDrones.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 593 calls, 27,336 t-states own (0.00 %) |
| Runs (the other recordings) | 17,935 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 521 and 43 more) |
| Called from | `MainLoop` |
| Reads | `$5E4E`-`$5E65` (system); `$A013`-`$A014` (`Weapon`, `PowerLevel`); `$A055`-`$A060` (`Dying`, `DeathTimer`, `DeathShardPtr`, `RestartX` and 7 more); `$A0B6`-`$A0B7` (`RexX`, `RexY`); `$A6CB`-`$A78A` (`DroneOrbit`, `DronePicture`); `$EB48`-`$EB4A` (`BackBuffer+72`); 5 more ranges |
| Writes | `$5E4E`-`$5E65` (system); `$EB48`-`$EB4A` (`BackBuffer+72`); `$EB5C`-`$FE9E` (`BackBuffer+92`); `$FEB0`-`$FEB1` (`BackBuffer+5040`); `$FED0`-`$FF11` (`BackBuffer+5072`); `$FF2F`-`$FF31` (`BackBuffer+5167`); 1 more ranges |

### `RollCharUp` (`$A7A9`)

**Roll an 8-byte character at HL one line up (the first line goes last): the conveyor characters**

Witness: L1 18559 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 699 calls, 245,648 t-states own (0.02 %) |
| Runs (the other recordings) | 17,860 calls (`docs/integrate/rec/p1-speedup` 682, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 519 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Reads | `$6438`-`$643F` (`AnimChar11`) |
| Writes | `$6438`-`$643F` (`AnimChar11`) |

### `RollCharDown` (`$A7BA`)

**Roll an 8-byte character at HL one line down**

Witness: L1 37119 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,398 calls, 516,568 t-states own (0.04 %) |
| Runs (the other recordings) | 35,721 calls (`docs/integrate/rec/p1-speedup` 1,364, `docs/integrate/rec/p1-poke41241` 1,340, `stage1/rec/rzx-p1-18000` 1,038 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Reads | `$64B0`-`$64C7` (`AnimChar26`, `AnimChar28`) |
| Writes | `$64B0`-`$64C7` (`AnimChar26`, `AnimChar28`) |

## weapons

`src/game/weapons.asm`

### `GiveDoubleFire` (`$A78B`)

**The double fire station: HasDoubleFire `$A050` = 1, then GiveWeapon**

Witness: L1 11 (rzx-p1-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11 calls (`stage1/rec/rzx-p1-00000` 11) |
| Called from | `CellsUnderRex` |
| Writes | `$A050` (`HasDoubleFire`) |

### `GiveLaser` (`$A791`)

**The laser station: HasLaser `$A051` = 1**

Witness: L1 31 (rzx-p1-10000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 31 calls (`stage1/rec/rzx-p1-10000` 31) |
| Called from | `CellsUnderRex` |
| Writes | `$A051` (`HasLaser`) |

### `GiveMultiple` (`$A797`)

**The multiple station: HasMultiple `$A052` = 1**

Witness: L1 23 (rzx-p1-18000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage1/rec/rzx-p1-18000` 23) |
| Called from | `CellsUnderRex` |
| Writes | `$A052` (`HasMultiple`) |

### `GiveSpray` (`$A79D`)

**The spray station: HasSpray `$A053` = 1; GiveWeapon: the icons shown, the best weapon chosen (BestWeapon `$B9D7`)**

Witness: L1 30 (rzx-p1- x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 30 calls (`stage1/rec/rzx-p1-34000` 9, `stage1/rec/rzx-p1-28000` 8, `stage1/rec/rzx-p1-42000` 5 and 2 more) |
| Called from | `StationSpray` |
| Calls | `ShowWeaponIcons`, `BestWeapon` |
| Writes | `$A053` (`HasSpray`) |

### `FireWeapon` (`$B372`)

**Fire: a shot of the current weapon if a slot is free (once a press, only while Rex is present)**

Witness: L1 2704 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 45 calls, 2,790 t-states own (0.00 %) |
| Runs (the other recordings) | 2,659 calls (`stage1/rec/rzx-p1-06000` 145, `stage2/rec/p1-cursor` 125, `stage1/rec/rzx-p1-62000` 111 and 40 more) |
| Called from | `MainLoop` |
| Calls | `FireDouble` (tail), `FireLaser` (tail), `FireSpray` (tail), `FindShotSlot`, `RexShot`, `SetupShot`, `PowerDrain` |
| Reads | `$5B60`-`$5C14` (system); `$5C32`-`$5CB9` (system); `$5CD7`-`$5D04` (system); `$5E4E`-`$5E64` (system); `$A012`-`$A014` (`Variables`, `Weapon`, `PowerLevel`); `$A040`-`$A041` (`RapidShotsOn`, `RapidShotsLeft`); 2 more ranges |
| Writes | `$5B65`-`$5D12` (system); `$A012` (`Variables`); `$A041` (`RapidShotsLeft`); `$A093`-`$A099` (`Temp1`, `Temp2`, `Temp3`, `Temp4`) |

### `FireDouble` (`$B40C`)

**Double fire's second shot**

Witness: L1 67 (p1-room14, rzx-p1-04000, rzx-p1-10000, rzx-p1-12000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 67 calls (`stage1/rec/rzx-p1-10000` 34, `stage1/rec/rzx-p1-12000` 20, `stage1/rec/rzx-p1-04000` 8 and 1 more) |
| Called from | `FireWeapon` (tail) |
| Calls | `FindShotSlot`, `SetupShot` |
| Reads | `$A013` (`Weapon`) |
| Writes | `$A099` (`Temp4`) |

### `FireLaser` (`$B41D`)

**The laser's beam**

Witness: L1 183 (p1-shots, p1-room24, rzx-p1- x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 60 calls (`stage1/rec/rzx-p1-26000` 24, `stage1/rec/rzx-p1-16000` 15, `stage1/rec/rzx-p1-14000` 14 and 2 more) |
| Called from | `FireWeapon` (tail) |
| Calls | `RexShot` |
| Reads | `$5B60`-`$5BE7` (system); `$5C32` (system); `$5CAA`-`$5CB9` (system); `$A068` (`FireDelay`) |
| Writes | `$5B65`-`$5BF5` (system); `$5C37`-`$5C40` (system); `$5CAF`-`$5CC7` (system) |

### `FireSpray` (`$B456`)

**The spray: at power 1-3 a fan of 3, 5 or 7 shots ahead (SprayShot); at power 4 the four directions, at 5 all eight (SprayDirections)**

Witness: L1 1010 (p1-code, p1-shots, p1-speedup, p1-room30, rzx-p1- x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,010 calls (`stage1/rec/rzx-p1-62000` 95, `stage1/rec/rzx-p1-48000` 81, `stage1/rec/rzx-p1-42000` 78 and 18 more) |
| Called from | `FireWeapon` (tail) |
| Calls | `SetShotDirection`, `SetShotSpeed`, `FindShotSlot`, `RexShot` |
| Reads | `$A014` (`PowerLevel`) |
| Writes | `$5B65`-`$5C19` (system); `$5C37` (system); `$5C73` (system); `$5CA0` (system) |

### `SetShotDirection` (`$B4D3`)

**A shot's direction from the record at HL: dX word, dY, its picture**

Witness: L1 5524 (p1-code, p1-speedup, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,524 calls (`stage1/rec/rzx-p1-36000` 576, `stage1/rec/rzx-p1-62000` 544, `stage1/rec/rzx-p1-46000` 508 and 16 more) |
| Called from | `FireSpray`, `MineBurst` |
| Calls | `SetShotSpeed` |
| Reads | `$B436`-`$B455` (`SprayDirections`) |
| Writes | `$5B64`-`$5D0C` (system); `$5D26`-`$5D93` (system) |

### `SetShotSpeed` (`$B4EA`)

**A shot's speed A into its record (dY x 32 added to the grid step)**

Witness: L1 8801 (c1, p1-code, p1-cursor, p1-kempston, p1-shots, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x25).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 51 calls, 10,268 t-states own (0.00 %) |
| Runs (the other recordings) | 8,750 calls (`stage1/rec/rzx-p1-46000` 811, `stage1/rec/rzx-p1-60000` 683, `stage1/rec/rzx-p1-50000` 661 and 30 more) |
| Called from | `FireSpray`, `SetShotDirection`, `SwingShotSet` |
| Reads | `$5B67`-`$5D0C` (system); `$5D29`-`$5E38` (system) |
| Writes | `$5B65`-`$5D0C` (system); `$5D27`-`$5E38` (system) |

### `FindShotSlot` (`$B506`)

**IY = a free slot among Rex's bullets (as many as the power level allows for the gun and double fire); none: IY = `$03E8`**

Witness: L1 10408 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 510 t-states own (0.00 %) |
| Runs (the other recordings) | 10,403 calls (`stage1/rec/rzx-p1-36000` 676, `stage1/rec/rzx-p1-30000` 668, `stage1/rec/rzx-p1-62000` 651 and 40 more) |
| Called from | `FireWeapon`, `FireDouble`, `FireSpray`, `MoveSplitShot` |
| Calls | `FindSlot` (tail) |
| Reads | `$5B66`-`$5CBF` (system); `$A013`-`$A014` (`Weapon`, `PowerLevel`); `$A07B` (`ShotSide`) |
| Writes | `$A07B` (`ShotSide`) |

### `FindSlot` (`$B528`)

**Search E slots from IY for a free one; the shot's sound by weapon (gun `$D763`, laser `$D775`, spray `$D77E`; the enemies' `$D76C`)**

Witness: L1 15464 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 109 calls, 37,587 t-states own (0.00 %) |
| Runs (the other recordings) | 14,968 calls (`stage1/rec/rzx-p1-46000` 1,007, `stage1/rec/rzx-p1-60000` 868, `docs/integrate/rec/p1-speedup` 868 and 39 more) |
| Called from | `FindShotSlot` (tail), `FindEnemySlot` (tail) |
| Calls | `LaserSound`, `SpraySound`, `EnemyShotSound` (tail), `StartSfx` |
| Reads | `$5B66`-`$5D0A` (system); `$5D28`-`$5E36` (system); `$A013` (`Weapon`); `$A07B` (`ShotSide`); `$D842` (`Channels+16`) |

### `LaserSound` (`$B55A`)

**DE = the laser's sound `$D775`**

Witness: L1 997 (p1-shots, p1-room24, rzx-p1- x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 997 calls (`stage1/rec/rzx-p1-18000` 307, `stage1/rec/rzx-p1-24000` 260, `stage1/rec/rzx-p1-22000` 115 and 5 more) |
| Called from | `FindSlot` |

### `SpraySound` (`$B55E`)

**DE = the spray's sound `$D77E`**

Witness: L1 6966 (p1-code, p1-shots, p1-speedup, p1-room30, rzx-p1- x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,966 calls (`stage1/rec/rzx-p1-36000` 670, `stage1/rec/rzx-p1-62000` 634, `stage1/rec/rzx-p1-46000` 593 and 18 more) |
| Called from | `FindSlot` |

### `EnemyShotSound` (`$B562`)

**The enemies' shot sound `$D76C`, if channel C (the third, Channels+`$10`) is free**

Witness: L1 5050 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 104 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3,555 calls (`docs/integrate/rec/p1-speedup` 454, `stage1/rec/rzx-p1-60000` 425, `stage1/rec/rzx-p1-46000` 410 and 24 more) |
| Called from | `FindSlot` (tail) |
| Calls | `StartSfx` |
| Reads | `$D842` (`Channels+16`) |

### `FindEnemySlot` (`$B570`)

**IY = a free slot among the enemies' 20 bullets**

Witness: L1 5056 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 104 calls, 5,304 t-states own (0.00 %) |
| Runs (the other recordings) | 4,952 calls (`docs/integrate/rec/p1-speedup` 454, `stage1/rec/rzx-p1-60000` 425, `stage1/rec/rzx-p1-46000` 410 and 42 more) |
| Called from | `UpdateObject`, `BigGun`, `ShootForward`, `ShootBoth`, `LauncherFire`, `ShootersFire`, `SwingGun`, `MineBurst` |
| Calls | `FindSlot` (tail) |
| Reads | `$5D28`-`$5D91` (system); `$A07B` (`ShotSide`); `$D842` (`Channels+16`) |
| Writes | `$A07B` (`ShotSide`) |

### `EnemyShotFrom` (`$B57E`)

**An enemy shot from IX's X - 16**

Witness: L1 16 (rzx-p1-20000, rzx-p1-56000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 calls (`stage1/rec/rzx-p1-20000` 8, `stage1/rec/rzx-p1-56000` 8) |
| Called from | `MineBurst` |
| Reads | `$5E66`-`$5E68` (system); `$5EAE` (system); `$A054` (`EnemyShotKind`) |
| Writes | `$A093`-`$A099` (`Temp1`, `Temp2`, `Temp3`, `Temp4`) |

### `EnemyShotFromX` (`$B586`)

**LD A,(IX+0) then into EnemyShotA: no instruction reaches these 3 bytes (leftover)**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EnemyShotA` (`$B589`)

**An enemy shot at X A, its Y 15 below the object's**

Witness: L1 16 (rzx-p1-20000, rzx-p1-56000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 runs of its first instruction, entered by a jump (`stage1/rec/rzx-p1-20000` 8, `stage1/rec/rzx-p1-56000` 8) |
| Calls | `EnemyShot` (falls into) |

### `EnemyShot` (`$B58E`)

**An enemy shot from IX: X Temp1, Y IX+1 plus A (Temp4, the Y offset SetupShot adds), kind EnemyShotKind `$A054` (bit 7: an enemy's)**

Witness: L1 4018 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 98 calls, 10,622 t-states own (0.00 %) |
| Runs (the other recordings) | 3,912 calls (`stage1/rec/rzx-p1-46000` 317, `stage1/rec/rzx-p1-60000` 309, `docs/integrate/rec/p1-speedup` 290 and 41 more) |
| Called from | `EnemyShotA` (falls into), `UpdateObject`, `BigGun`, `ShootForward`, `ShootBoth`, `LauncherFire`, `SwingShotUpLeft`, `SwingShotLeft`, `SwingShotRight`, `SwingShotUpRight` |
| Calls | `SetupShot` (tail) |
| Reads | `$5D22`-`$5D8C` (system); `$5E67`-`$5E98` (system); `$5EAF`-`$5EB0` (system); `$5EC7`-`$5EC8` (system); `$5EDF`-`$5EE0` (system); `$5EF7`-`$5EF8` (system); 8 more ranges |
| Writes | `$5D22`-`$5D96` (system); `$A095`-`$A099` (`Temp2`, `Temp3`, `Temp4`) |

### `RexShot` (`$B5A5`)

**A shot from Rex: his X, Y + 17 (Temp4) and facing, type the weapon**

Witness: L1 7094 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 595 t-states own (0.00 %) |
| Runs (the other recordings) | 7,089 calls (`stage1/rec/rzx-p1-36000` 604, `stage1/rec/rzx-p1-62000` 558, `stage1/rec/rzx-p1-46000` 525 and 40 more) |
| Called from | `FireWeapon`, `FireLaser`, `FireSpray` |
| Calls | `SetupShot` (falls into) |
| Reads | `$5B60`-`$5CBA` (system); `$A013` (`Weapon`); `$A07B` (`ShotSide`); `$A093`-`$A099` (`Temp1`, `Temp2`, `Temp3`, `Temp4`); `$A0B6`-`$A0BB` (`RexX`, `RexY`, `Room`, `RoomColumn` and 1 more) |
| Writes | `$5B60`-`$5CC4` (system); `$A093`-`$A099` (`Temp1`, `Temp2`, `Temp3`, `Temp4`) |

### `SetupShot` (`$B5C1`)

**Fill the slot at IY: live, type A, Y Temp2 + Temp4, X Temp1 + 16, direction Temp3 (left: dX -1, -8 pixels), the grid pointer**

Witness: L1 13750 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 109 calls, 62,936 t-states own (0.00 %) |
| Runs (the other recordings) | 13,293 calls (`stage1/rec/rzx-p1-46000` 846, `docs/integrate/rec/p1-speedup` 756, `stage1/rec/rzx-p1-60000` 722 and 40 more) |
| Called from | `FireWeapon`, `FireDouble`, `EnemyShot` (tail), `RexShot` (falls into), `MoveSplitShot`, `ShootFromObject` |
| Reads | `$5B60`-`$5E31` (system); `$A07B` (`ShotSide`); `$A093`-`$A099` (`Temp1`, `Temp2`, `Temp3`, `Temp4`) |
| Writes | `$5B60`-`$5E3B` (system) |

### `MoveEnemyBullets` (`$B645`)

**Move the enemies' 20 bullets**

Witness: L1 18641 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 706 calls, 21,886 t-states own (0.00 %) |
| Runs (the other recordings) | 17,935 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 521 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `MoveShots` (tail) |

### `MoveBullets` (`$B64E`)

**Move Rex's 30 bullets (falls into MoveShots)**

Witness: L1 18529 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 593 calls, 12,453 t-states own (0.00 %) |
| Runs (the other recordings) | 17,936 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 521 and 43 more) |
| Called from | `MainLoop` |
| Calls | `MoveShots` (falls into) |

### `MoveShots` (`$B654`)

**Move B bullets from IX: by state (live, hit flash 2 and 3) and type (gun, beam, spray dot, enemy shot, bouncing, drone shot)**

Witness: L1 928663 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `MoveShots` at work](img/routines/MoveShots.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,299 calls, 3,456,572 t-states own (0.24 %) |
| Runs (the other recordings) | 833,777 calls (`docs/integrate/rec/p1-speedup` 34,250, `docs/integrate/rec/p1-poke41241` 33,500, `stage1/rec/rzx-p1-18000` 26,050 and 43 more) |
| Called from | `MoveEnemyBullets` (tail), `MoveBullets` (falls into), `NextShot` (tail) |
| Calls | `NextShot` (tail), `ShotFlash1` (tail), `ShotFlash2` (tail), `MoveBeam` (tail), `DrawShotDot` (tail), `DrawShotByte` (tail), `MoveSplitShot` (tail), `MoveSparkShot` (tail) |
| Reads | `$5B60`-`$5E45` (system); `$6C6A`-`$6C8C` (`CharAttrs+138`); `$8A42`-`$8A59` (`SpriteLaserA`); `$8F4A`-`$8F61` (`SpriteLaserB`); `$A013` (`Weapon`); `$A093`-`$A097` (`Temp1`, `Temp2`, `Temp3`); 14 more ranges |
| Writes | `$58CD`-`$58CE` (screen); `$58ED`-`$591E` (screen); `$5938`-`$5939` (screen); `$5956`-`$595B` (screen); `$5B60`-`$5BA2` (system); `$5D22`-`$5DAC` (system); 20 more ranges |

### `StepShot` (`$B692`)

**Move a bullet one step; off the play area it ends; a damaging cell (4, 5, 6) is hit; a solid cell stops it**

Witness: L1 93235 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,102 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 88,862 calls (`stage1/rec/rzx-p1-24000` 5,987, `stage1/rec/rzx-p1-46000` 4,801, `docs/integrate/rec/p1-speedup` 4,576 and 40 more) |
| Called from | `MoveBeam` (tail), `DrawShotDot` (tail), `DrawShotByte` (tail), `MoveSplitShot` (tail), `MoveSparkShot` (tail) |
| Calls | `CellPointer`, `NextShot` (falls into), `EndShot` (tail), `BulletHitsCell` (tail), `ShotStopped` (tail), `IsPassable` |
| Reads | `$5B60`-`$5D0F` (system); `$5D22`-`$5E3B` (system); `$E200`-`$E49B` (`RoomGridPlay+1`, `ExplosionPicture`) |
| Writes | `$5B60`-`$5D07` (system); `$5D22`-`$5E33` (system); `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |

### `NextShot` (`$B6F6`)

**The next bullet record (15 bytes on)**

Witness: L1 928662 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 31,910 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 831,152 calls (`docs/integrate/rec/p1-speedup` 34,250, `docs/integrate/rec/p1-poke41241` 33,500, `stage1/rec/rzx-p1-18000` 26,050 and 40 more) |
| Called from | `MoveShots` (tail), `StepShot` (falls into), `EndShot` (tail), `ShotStopped` (tail), `ShotFlash1` (tail), `ShotFlash2` (tail) |
| Calls | `MoveShots` (tail) |

### `EndShot` (`$B700`)

**The bullet ends (live = 0)**

Witness: L1 3045 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 38 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,907 calls (`stage1/rec/rzx-p1-46000` 233, `stage1/rec/rzx-p1-36000` 229, `stage1/rec/rzx-p1-20000` 185 and 38 more) |
| Called from | `StepShot` (tail) |
| Calls | `NextShot` (tail) |
| Writes | `$5B66`-`$5D0A` (system); `$5D28`-`$5E27` (system) |

### `BulletHitsCell` (`$B707`)

**A bullet hits a cell 4, 5 or 6: the cell's character goes one step on (its animated record in SceneryCellList), the room's look changes**

Witness: L1 290 (c1, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 206 calls (`stage1/rec/rzx-p1-22000` 78, `stage1/rec/rzx-p1-20000` 64, `stage1/rec/rzx-p1-06000` 63 and 1 more) |
| Called from | `StepShot` (tail) |
| Calls | `ShotStopped` (falls into) |
| Reads | `$5B6B`-`$5C6A` (system); `$5C97`-`$5CA6` (system); `$5CC4`-`$5CE2` (system); `$5D2D`-`$5DA5` (system); `$5DC3`-`$5DF0` (system); `$5E0E` (system); 15 more ranges |
| Writes | `$58CE`-`$58CF` (screen); `$58ED`-`$58FD` (screen); `$590E`-`$591E` (screen); `$5937` (screen); `$5950`-`$5956` (screen); `$5971`-`$597B` (screen); 26 more ranges |

### `ShotStopped` (`$B794`)

**A bullet meets a wall: a small flash (state 2) unless it is the laser, the hit sound `$D787`**

Witness: L1 8636 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 41 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 8,330 calls (`docs/integrate/rec/p1-speedup` 560, `stage1/rec/rzx-p1-46000` 547, `stage1/rec/rzx-p1-50000` 516 and 40 more) |
| Called from | `StepShot` (tail), `BulletHitsCell` (falls into) |
| Calls | `NextShot` (tail), `StartSfx` |
| Reads | `$5B62`-`$5D07` (system); `$5D24`-`$5E33` (system); `$A013` (`Weapon`); `$D842` (`Channels+16`) |
| Writes | `$5B66`-`$5D0A` (system); `$5D28`-`$5E36` (system); `$EB25`-`$FEAF` (`BackBuffer+37`); `$FF14`-`$FF94` (`BackBuffer+5140`); `$FFEA` (`BackBuffer+5354`) |

### `ShotFlash1` (`$B7BD`)

**The flash's first frame: a cross of three bytes in the buffer**

Witness: L1 9214 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x31).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 62 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 8,830 calls (`stage1/rec/rzx-p1-46000` 603, `docs/integrate/rec/p1-speedup` 588, `stage1/rec/rzx-p1-60000` 581 and 39 more) |
| Called from | `MoveShots` (tail) |
| Calls | `NextShot` (tail) |
| Reads | `$5B62`-`$5D07` (system); `$5D24`-`$5E33` (system) |
| Writes | `$5B66`-`$5D0A` (system); `$5D28`-`$5E36` (system); `$EAEB`-`$FECF` (`ObjectBufferOrigin+236`, `BufferPlayOrigin`, `BackBuffer`); `$FEF4`-`$FFB4` (`BackBuffer+5108`); `$FFCA` (`BackBuffer+5322`); `$FFEA` (`BackBuffer+5354`) |

### `ShotFlash2` (`$B7D8`)

**The flash's second frame, then the bullet ends**

Witness: L1 9196 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x31).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 62 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 8,812 calls (`stage1/rec/rzx-p1-46000` 601, `docs/integrate/rec/p1-speedup` 587, `stage1/rec/rzx-p1-60000` 583 and 39 more) |
| Called from | `MoveShots` (tail) |
| Calls | `NextShot` (tail) |
| Reads | `$5B62`-`$5D07` (system); `$5D24`-`$5E33` (system) |
| Writes | `$5B66`-`$5D0A` (system); `$5D28`-`$5E36` (system); `$EACB`-`$FFD4` (`ObjectBufferOrigin+204`, `BufferPlayOrigin`, `BackBuffer`); `$FFEA` (`BackBuffer+5354`) |

### `MoveBeam` (`$B7FC`)

**The long beam (type 7): its frames from BeamPath `$A9AF`**

Witness: L1 7517 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 369 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,299 calls (`docs/integrate/rec/p1-poke41241` 3,149, `docs/integrate/rec/p1-shots` 611, `docs/integrate/rec/p1-speedup` 308 and 21 more) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5D22`-`$5DD3` (system); `$5DE5`-`$5DF1` (system); `$5E21`-`$5E2D` (system); `$8A42`-`$8A59` (`SpriteLaserA`); `$8F4A`-`$8F61` (`SpriteLaserB`); `$A9AF`-`$A9CB` (`BeamPath`, `BeamEnd`) |
| Writes | `$5D24`-`$5DD3` (system); `$5DE7`-`$5DF1` (system); `$5E23`-`$5E2D` (system); `$EB2B`-`$F872` (`BackBuffer+43`); `$F8A4`-`$FB74` (`BackBuffer+3492`); `$FBA3`-`$FC28` (`BackBuffer+4259`); 1 more ranges |

### `DrawShotDot` (`$B867`)

**Draw a type 4 bullet: a 4-line dot (Rex's or an enemy's shape)**

Witness: L1 49181 (c1, p1-code, p1-cursor, p1-kempston, p1-shots, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x25).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 490 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 48,360 calls (`stage1/rec/rzx-p1-46000` 4,452, `stage1/rec/rzx-p1-62000` 4,040, `stage1/rec/rzx-p1-60000` 3,627 and 28 more) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5B6B`-`$5D0F` (system); `$5D2D`-`$5E3B` (system) |
| Writes | `$EAC1`-`$FFD8` (`ObjectBufferOrigin+194`, `BufferPlayOrigin`, `BackBuffer`) |

### `DrawShotByte` (`$B893`)

**Draw a gun bullet: one byte by direction and side**

Witness: L1 25458 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 243 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 23,124 calls (`stage1/rec/rzx-p1-30000` 4,004, `stage1/rec/rzx-p1-20000` 3,691, `stage1/rec/rzx-p1-22000` 2,489 and 39 more) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5B64`-`$5D0F` (system); `$5D26`-`$5E3B` (system) |
| Writes | `$E9CB`-`$E9D0` (`SpriteBufferOrigin+204`); `$EA10` (`ObjectBufferOrigin+17`); `$EA47`-`$EA56` (`ObjectBufferOrigin+72`); `$EB9E`-`$EBD4` (`BackBuffer+158`); `$EC06`-`$EC7C` (`BackBuffer+262`); `$ECC3`-`$ECDB` (`BackBuffer+451`); 5 more ranges |

### `MoveSplitShot` (`$B8BC`)

**A splitting shot (type 2): every few steps it fires a new shot from where it is**

Witness: L1 1573 (p1-shots, p1-room24, rzx-p1- x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,573 calls (`stage1/rec/rzx-p1-24000` 548, `stage1/rec/rzx-p1-18000` 544, `stage1/rec/rzx-p1-26000` 132 and 5 more) |
| Called from | `MoveShots` (tail) |
| Calls | `FindShotSlot`, `SetupShot`, `StepShot` (tail) |
| Reads | `$5B61`-`$5C22` (system); `$5C33`-`$5CC7` (system); `$5CD8`-`$5D12` (system); `$A068` (`FireDelay`); `$A093` (`Temp1`) |
| Writes | `$5B65`-`$5D12` (system); `$A093`-`$A099` (`Temp1`, `Temp2`, `Temp3`, `Temp4`) |

### `MoveSparkShot` (`$B920`)

**A spark (type 6): random dots by its count (SparkMasks `$B943`), it fades out**

Witness: L1 9506 (p1-shots, p1-room24, rzx-p1- x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,506 calls (`stage1/rec/rzx-p1-18000` 3,490, `stage1/rec/rzx-p1-24000` 3,236, `stage1/rec/rzx-p1-26000` 811 and 5 more) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5B6E`-`$5D12` (system); `$B944`-`$B95B` (`SparkMasks+1`) |
| Writes | `$5B66`-`$5D12` (system); `$F034`-`$F038` (`BackBuffer+1332`); `$F074`-`$F076` (`BackBuffer+1396`); `$F108` (`BackBuffer+1544`); `$F128`-`$F137` (`BackBuffer+1576`); `$F32A`-`$F43B` (`BackBuffer+2090`); 12 more ranges |

### `PowerBar` (`$B96B`)

**Draw the power bar: its end colour flashes by FadeStepIndex**

Witness: L1 18614 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 calls, 67,994 t-states own (0.00 %) |
| Runs (the other recordings) | 17,912 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `PowerBarColour` (falls into) |
| Reads | `$A015`-`$A016` (`PowerBarPtr`); `$A042` (`FadeStepIndex`) |

### `PowerBarColour` (`$B97E`)

**A = PowerLevel + 2 (the bar's colour)**

Witness: L1 32766 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,404 calls, 135,853 t-states own (0.01 %) |
| Runs (the other recordings) | 31,362 calls (`docs/integrate/rec/p1-poke41241` 1,318, `docs/integrate/rec/p1-speedup` 1,200, `stage1/rec/rzx-p1-02000` 952 and 43 more) |
| Called from | `PowerBar` (falls into) |
| Calls | `Fill2x2` (falls into) |
| Reads | `$A014` (`PowerLevel`) |
| Writes | `$5801`-`$580A` (screen); `$5821`-`$582A` (screen); `$E500`-`$E509` (`TitleScreen+1`); `$E520`-`$E529` (`ShieldAttrs+13`) |

### `Fill2x2` (`$B983`)

**Write A into a 2 x 2 patch at HL**

Witness: L1 32786 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,404 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7,726 calls (`stage1/rec/rzx-p1-40000` 900, `stage1/rec/rzx-p1-24000` 896, `stage1/rec/rzx-p1-22000` 878 and 7 more) |
| Called from | `PowerBarColour` (falls into), `PowerDrain` |
| Writes | `$5801`-`$580A` (screen); `$5821`-`$582A` (screen); `$E500`-`$E509` (`TitleScreen+1`); `$E520`-`$E529` (`ShieldAttrs+13`) |

### `PowerGain` (`$B98E`)

**A power pod: PowerCount `$A018` counts, every 120 the PowerLevel + 1 up to 5 (at 5 GainRank raises WeaponRank and sets the level back to 1; at rank 5 nothing), the fire faster**

Witness: L1 212 (p1-speedup, p1-room30, rzx-p1- x27).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 212 calls (`stage1/rec/rzx-p1-58000` 18, `stage1/rec/rzx-p1-34000` 15, `stage1/rec/rzx-p1-42000` 15 and 26 more) |
| Called from | `TakePowerPod` |
| Calls | `InitDrones`, `BestWeapon` (falls into) |
| Reads | `$A014`-`$A018` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`); `$A06E` (`WeaponRank`); `$A093` (`Temp1`) |
| Writes | `$A014`-`$A018` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`); `$A068`-`$A06E` (`FireDelay`, `AnimCount1`, `AnimCount2`, `AnimCount3` and 2 more); `$A093` (`Temp1`) |

### `BestWeapon` (`$B9D7`)

**Weapon = the best one held (WeaponRank `$A06E`), WeaponIcon updated**

Witness: L1 108 (p1-room24, rzx-p1- x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 101 calls (`stage1/rec/rzx-p1-10000` 32, `stage1/rec/rzx-p1-18000` 25, `stage1/rec/rzx-p1-00000` 11 and 6 more) |
| Called from | `GiveSpray`, `PowerGain` (falls into), `PowerDrain` (tail) |
| Reads | `$A04F`-`$A053` (`WeaponIcon`, `HasDoubleFire`, `HasLaser`, `HasMultiple` and 1 more); `$A06E` (`WeaponRank`) |
| Writes | `$A013` (`Weapon`) |

### `PowerDrain` (`$B9EF`)

**A shot of a special weapon: PowerCount down; at 0 the PowerLevel - 1, the bar redrawn; at 1 BestWeapon**

Witness: L1 2009 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 15 calls, 2,093 t-states own (0.00 %) |
| Runs (the other recordings) | 1,994 calls (`stage1/rec/rzx-p1-06000` 128, `stage1/rec/rzx-p1-62000` 99, `stage1/rec/rzx-p1-30000` 82 and 41 more) |
| Called from | `FireWeapon`, `LosePower` |
| Calls | `Fill2x2`, `BestWeapon` (tail) |
| Reads | `$A014`-`$A018` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`); `$A04F`-`$A052` (`WeaponIcon`, `HasDoubleFire`, `HasLaser`, `HasMultiple`); `$A06E` (`WeaponRank`); `$A093` (`Temp1`) |
| Writes | `$A013`-`$A018` (`Weapon`, `PowerLevel`, `PowerBarPtr`, `PassToggle` and 1 more); `$A06E` (`WeaponRank`); `$A093` (`Temp1`) |

### `LosePower` (`$BA3D`)

**A death or ENERGY LOSS: PowerDrain(50) twice; each drain that would go below 0 puts the count back and drops one level, so 0, 1 or 2 levels go**

Witness: L1 42 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-room24, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 736 t-states own (0.00 %) |
| Runs (the other recordings) | 37 calls (`stage1/rec/rzx-p1-40000` 3, `stage1/rec/rzx-p1-26000` 3, `stage1/rec/rzx-p1-02000` 3 and 21 more) |
| Called from | `RexDies` |
| Calls | `PowerDrain` |

### `ResetPower` (`$BA49`)

**Weapon 0, PowerLevel 1, the bar's pointer, WeaponRank 0**

Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000, rzx-p1-64000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 178 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage2/rec/p1-cursor` 2, `stage1/rec/rzx-p1-64000` 1, `stage2/rec/p1-code` 1 and 3 more) |
| Called from | `NewGame` |
| Writes | `$A013`-`$A016` (`Weapon`, `PowerLevel`, `PowerBarPtr`); `$A06E` (`WeaponRank`) |

## codepanel

`src/game/codepanel.asm`

### `CodePanel` (`$A7CE`)

**The end of part 1: the CODE panel with the access code, then a new game**

Reached only from ChangeRoom `$C95A` when the exit leads to room 99. The digits go into CodeText `$A884` at the places `$A88C-$A89B`. No stage 1 recording reached it; p1-code does (room 31's exit to 99, the panel shown, fire, a new game in room 0).

Witness: L1 1 (p1-code).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/p1-code` 1) |
| Called from | `ChangeRoom` (tail) |
| Calls | `NewGame` (tail), `WaitFire`, `PrintBoxed`, `ToDigits` |
| Reads | `$A03E`-`$A06C` (`Score`, `RapidShotsOn`, `RapidShotsLeft`, `FadeStepIndex` and 38 more); `$A0A6`-`$A0AA` (`Digits`); `$A88C`-`$A898` (`CodeDigits`) |
| Writes | `$A093`-`$A094` (`Temp1`); `$A88C`-`$A89B` (`CodeDigits`) |

### `BuildRoom` (`$A89D`)

**Build the room Room `$A0B8`: exits and objects, the map drawn, the buffer shown, the room's objects made, the scripted spawn**

ResetSweep `$A133`, RoomExits ReadExits `$C8EF`, DrawRoom `$C745`, ClearBuffer / DrawAnimCells / BufferToScreen, CopyAttrs `$C8BF`, MakeObjects `$CB52`; rooms 2, 3, 4, 6 and 20 start the scripted spawn (StartScriptSpawn `$C965`); ShowShield.

Witness: L1 80 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

[Animation: `BuildRoom` at work](img/routines/BuildRoom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 7 calls, 247,407 t-states own (0.02 %) |
| Runs (the other recordings) | 73 calls (`stage1/rec/rzx-p1-02000` 4, `docs/integrate/rec/p1-speedup` 3, `stage2/rec/p1-cursor` 3 and 37 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `ShowShield`, `ResetSweep`, `BufferToScreen`, `ClearBuffer`, `DrawAnimCells`, `DrawRoom`, `CopyAttrs`, `ReadExits`, `StartScriptSpawn`, `MakeObjects` |
| Reads | `$5860`-`$5AFE` (screen); `$5B60`-`$5E4C` (system); `$A0B8` (`Room`) |
| Writes | `$5860`-`$5AFF` (screen); `$5B60`-`$5E4D` (system); `$A017` (`PassToggle`); `$A039`-`$A045` (`KillFlashPtr`, `ComboCount`, `ComboTimer`, `Score` and 6 more); `$A05C` (`RestartFacing`); `$D790` (`SfxExplosion`) |

### `Attract` (`$A915`)

**The attract mode: each room of AttractRooms shown 199 passes (AttractTimer 200, decremented before the test) with its objects moving (no Rex); fire starts a game**

Entered from WaitFireOrAttract `$97C3`'s timeout. AttractFlag `$A0C2` = 1 while it runs.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 139,079 t-states own (0.01 %) |
| Called from | `NewGame` (tail) |
| Calls | `KillFlashFade`, `FadeStep`, `HudSweep`, `BufferToScreen`, `ReadFire`, `AnimateCells`, `RollCharUp`, `RollCharDown`, `BuildRoom`, `ClearBuffer`, `DrawAnimCells`, `MoveEnemyBullets`, `PowerBar`, `UpdateObjects`, `SpawnScripted`, `SpawnRandom`, `EnemyBulletsHitRex`, `SoundStep` |
| Reads | `$6758`-`$675F` (`AnimChar111`); `$6858`-`$685F` (`AnimChar143`); `$A017` (`PassToggle`); `$A0C2`-`$A0C3` (`AttractFlag`, `AttractTimer`); `$A90C` (`AttractRooms`) |
| Writes | `$6758`-`$675F` (`AnimChar111`); `$6858`-`$685F` (`AnimChar143`); `$A017` (`PassToggle`); `$A0B8`-`$A0C3` (`Room`, `RoomColumn`, `RexFacing`, `FallSpeed` and 4 more) |

## render

`src/game/render.asm`

### `ClearBuffer` (`$B205`)

**Clear the back buffer's play lines `$EB00-$FFFF` with PUSH (the stack from `$FFFF` down)**

Witness: L1 18688 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `ClearBuffer` at work](img/routines/ClearBuffer.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 709 calls, 21,403,667 t-states own (1.47 %) |
| Runs (the other recordings) | 17,979 calls (`docs/integrate/rec/p1-speedup` 688, `docs/integrate/rec/p1-poke41241` 669, `stage1/rec/rzx-p1-18000` 522 and 43 more) |
| Called from | `MainLoop`, `BuildRoom`, `Attract` |
| Reads | `$A093`-`$A094` (`Temp1`) |
| Writes | `$A093`-`$A094` (`Temp1`) |

### `DrawSprite` (`$B258`)

**OR a picture into the back buffer: HL its frame list, DE the picture, SpriteX/SpriteY, SpriteWidth/Height (written into the loop at `$B2AC`, `$B2B0`); A non-zero draws it mirrored**

Witness: L1 106778 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `DrawSprite` at work](img/routines/DrawSprite.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,995 calls, 14,632,595 t-states own (1.01 %) |
| Runs (the other recordings) | 103,783 calls (`docs/integrate/rec/p1-speedup` 5,110, `stage1/rec/rzx-p1-58000` 3,841, `stage1/rec/rzx-p1-20000` 3,748 and 43 more) |
| Called from | `DrawRex`, `DeathAnimation`, `DrawObject` |
| Calls | `DrawMirrored` (tail) |
| Reads | `$6018`-`$60D7` (`DevLinkStub`, `Unused607E`); `$7F72`-`$8C09` (`Sprites`, `SpriteStomper`, `SpriteRex`, `SpriteRexDeath` and 13 more); `$8CEA`-`$9411` (`SpriteBonusPod`, `SpriteBonusPod2`, `SpriteKind12`, `SpriteKind11` and 11 more); `$A033`-`$A035` (`SpriteMirror`, `SpritePicture`); `$A0AF`-`$A0B2` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$AD5D`-`$AE8C` (`MirrorTable`, `ShiftFrames`); 1 more ranges |
| Writes | `$A0AF` (`SpriteX`); `$B2AC`-`$B2B0` (`DrawSpriteRows+1`, `DrawSpriteRow`, `DrawSpriteBytes`); `$B318`-`$B31C` (`DrawMirroredRows+1`, `DrawMirroredRow`, `DrawMirroredBytes`); `$E904`-`$FFFF` (`SpriteBufferOrigin+5`, `work space $FFFA+`) |

### `DrawMirrored` (`$B2C1`)

**DrawSprite facing left: the picture's bytes right to left through MirrorTable `$AD5D`**

Witness: L1 30331 (c1, p1-code, p1-cursor, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `DrawMirrored` at work](img/routines/DrawMirrored.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 684 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,210 calls (`stage1/rec/rzx-p1-58000` 1,085, `stage1/rec/rzx-p1-56000` 734, `stage1/rec/rzx-p1-22000` 391) |
| Called from | `DrawSprite` (tail) |
| Reads | `$6018`-`$60D7` (`DevLinkStub`, `Unused607E`); `$7F72`-`$83F1` (`Sprites`, `SpriteStomper`, `SpriteRex`, `SpriteRexDeath` and 1 more); `$8632`-`$8A41` (`SpriteHitFlash`, `SpriteRamTurn`, `SpritePodA`, `SpritePodB` and 2 more); `$8CEA`-`$8D29` (`SpriteBonusPod`, `SpriteBonusPod2`); `$8E8A`-`$9021` (`SpriteKind6`, `SpriteSwingGun`, `SpriteLaserB`, `SpriteRexJump`); `$91B2`-`$91D1` (`SpriteJumper`); 10 more ranges |
| Writes | `$A0AF` (`SpriteX`); `$B318`-`$B31C` (`DrawMirroredRows+1`, `DrawMirroredRow`, `DrawMirroredBytes`); `$E907`-`$FE55` (`SpriteBufferOrigin+8`, `ObjectBufferOrigin`, `BufferPlayOrigin`, `BackBuffer`); `$FE68`-`$FE75` (`BackBuffer+4968`); `$FE88`-`$FE95` (`BackBuffer+5000`); `$FEA8`-`$FEB5` (`BackBuffer+5032`); 2 more ranges |

### `ReturnToStack` (`$B339`)

**LD SP,(Temp2): RET: DrawAnimCells' exit with the stack it saved**

Witness: L1 18691 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 710 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 912 calls (`stage1/rec/rzx-p1-28000` 457, `stage1/rec/rzx-p1-08000` 455) |
| Called from | `DrawAnimCells` (tail) |
| Reads | `$A095`-`$A096` (`Temp2`) |

### `DrawAnimCells` (`$B33E`)

**Draw every scenery cell of the room (SceneryCellList `$D962`) into the back buffer, the stack as the list pointer**

Witness: L1 18698 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `DrawAnimCells` at work](img/routines/DrawAnimCells.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 710 calls, 70,565,409 t-states own (4.86 %) |
| Runs (the other recordings) | 17,988 calls (`docs/integrate/rec/p1-speedup` 688, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 522 and 43 more) |
| Called from | `MainLoop`, `BuildRoom`, `Attract` |
| Calls | `ReturnToStack` (tail) |
| Reads | `$63F0`-`$6BDF` (`CharGraphics+16`, `AnimChar11`, `AnimChar26`, `AnimChar28` and 7 more); `$A095`-`$A096` (`Temp2`) |
| Writes | `$A095`-`$A096` (`Temp2`); `$EB00`-`$FFFD` (`BackBuffer`, `work space $FFFA+`) |

## objects

`src/game/objects.asm`

### `UpdateObjects` (`$BA5C`)

**Update every object of the room (falls into UpdateObject)**

Witness: L1 18619 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `UpdateObjects` at work](img/routines/UpdateObjects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 703 calls, 21,793 t-states own (0.00 %) |
| Runs (the other recordings) | 17,916 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `UpdateObject` (falls into) |
| Reads | `$A092` (`ObjectCount`) |

### `UpdateObject` (`$BA64`)

**One object at IX: skip a dead one; pick its picture (exploding: `$6018`); draw it; its behaviour**

Witness: L1 200524 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4,959 calls, 1,437,642 t-states own (0.10 %) |
| Runs (the other recordings) | 195,565 calls (`docs/integrate/rec/p1-speedup` 9,029, `stage1/rec/rzx-p1-18000` 7,419, `stage1/rec/rzx-p1-38000` 7,022 and 43 more) |
| Called from | `UpdateObjects` (falls into), `NextObject` (tail) |
| Calls | `Random`, `FindEnemySlot`, `EnemyShot`, `DrawObject` (tail), `NextObject` (tail) |
| Reads | `$5E66`-`$5FDA` (system) |
| Writes | `$5D27`-`$5D81` (system); `$5D9F`-`$5DF9` (system); `$5E17` (system); `$5E7C`-`$5EDD` (system); `$5EF4`-`$5EF5` (system); `$5F0C`-`$5F0D` (system); 11 more ranges |

### `DrawObject` (`$BAD0`)

**Draw the object at IX (SpriteX/Y, size, mirror, picture, frame list) and dispatch: exploding, ramming turn, shooting kinds**

Witness: L1 86025 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,131 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,999 calls (`docs/integrate/rec/p1-poke41241` 2,784, `stage1/rec/rzx-p1-08000` 2,029, `stage1/rec/rzx-p1-22000` 1,574 and 7 more) |
| Called from | `UpdateObject` (tail) |
| Calls | `DrawSprite`, `ObjectBehaviour` (falls into), `ShootForward` (tail), `ShootBoth` (tail), `RamTurn` (tail), `BlowUp` (tail), `MaybeJumper`, `JumperTimer` |
| Reads | `$5E66`-`$5F55` (system) |
| Writes | `$A033`-`$A035` (`SpriteMirror`, `SpritePicture`); `$A0AF`-`$A0B2` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`) |

### `ObjectBehaviour` (`$BB39`)

**By kind: the power pod's frames, the swing gun, the shooters, the launcher, the big gun; else walk, fall, jump, the grid cell and the walk kinds' moves**

Witness: L1 82133 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,003 calls, 304,363 t-states own (0.02 %) |
| Runs (the other recordings) | 55,796 calls (`docs/integrate/rec/p1-speedup` 4,275, `stage1/rec/rzx-p1-58000` 3,205, `stage1/rec/rzx-p1-20000` 3,040 and 23 more) |
| Called from | `DrawObject` (falls into), `ShootForward` (tail), `ShootBoth` (tail), `RamTurn` (tail) |
| Calls | `BigGun` (tail), `LauncherFire` (tail), `ShootersFire` (tail), `SwingGun` (tail), `AnimatePod`, `ObjectMove`, `ObjectJump`, `ObjectFall`, `ObjectCell` |
| Reads | `$5E6F`-`$5F17` (system); `$5F2F` (system); `$5F47` (system); `$5F5F` (system); `$5F77` (system); `$5F8F` (system); 2 more ranges |

### `ObjectCollide` (`$BB66`)

**ObjectHitsRex for the object at IX**

Witness: L1 82130 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,032 calls, 38,754 t-states own (0.00 %) |
| Runs (the other recordings) | 20,731 calls (`docs/integrate/rec/p1-speedup` 2,176, `docs/integrate/rec/p1-poke41241` 2,010, `stage1/rec/rzx-p1-08000` 1,296 and 39 more) |
| Called from | `BigGun` (tail), `LauncherFire` (tail), `ShootersFire` (tail), `SwingGun` (tail) |
| Calls | `ObjectHitsRex` |

### `NextObject` (`$BB69`)

**The next object record (24 bytes on), until all are done**

Witness: L1 200522 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,956 calls, 261,189 t-states own (0.02 %) |
| Runs (the other recordings) | 115,434 calls (`stage1/rec/rzx-p1-18000` 6,152, `stage1/rec/rzx-p1-38000` 4,987, `stage1/rec/rzx-p1-24000` 4,980 and 43 more) |
| Called from | `UpdateObject` (tail), `BlowUp` (tail) |
| Calls | `UpdateObject` (tail) |

### `BigGun` (`$BB74`)

**Kind 16 (`$90`): bobs between Y `$40` and `$78` by IX+`$12`; 1 pass in 16 (R AND 15 = 0) a volley, one shot per BigGunShots byte (the byte is the shot's Y offset); above Y `$90` at Random `$F0` and over a mine (DropMine `$C1F4`)**

Witness: L1 814 (rzx-p1-22000, rzx-p1-24000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 814 calls (`stage1/rec/rzx-p1-24000` 447, `stage1/rec/rzx-p1-22000` 367) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `Random`, `FindEnemySlot`, `EnemyShot`, `ObjectCollide` (tail), `DropMine` |
| Reads | `$5E66`-`$5E79` (system); `$BE53`-`$BE5A` (`BigGunShots`) |
| Writes | `$5D2D`-`$5E3B` (system); `$5E67`-`$5E77` (system); `$A093`-`$A095` (`Temp1`, `Temp2`) |

### `ShootForward` (`$BC0F`)

**A walker's random shot forward (1 in 16)**

Witness: L1 580 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-06000, rzx-p1-08000, rzx-p1-12000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 83 calls, 4,136 t-states own (0.00 %) |
| Runs (the other recordings) | 497 calls (`stage1/rec/rzx-p1-04000` 149, `stage1/rec/rzx-p1-08000` 117, `stage1/rec/rzx-p1-12000` 85 and 2 more) |
| Called from | `DrawObject` (tail) |
| Calls | `Random`, `FindEnemySlot`, `EnemyShot`, `ObjectBehaviour` (tail) |
| Reads | `$5E96` (system); `$5EAE` (system); `$5EF6` (system); `$5F0E` (system) |
| Writes | `$5D27`-`$5D72` (system); `$5D9F`-`$5DAE` (system); `$A054` (`EnemyShotKind`); `$A093` (`Temp1`) |

### `ShootBoth` (`$BC30`)

**A random pair of shots, one each way**

Witness: L1 445 (c1, p1-rooms238, rzx-p1- x5).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 43 calls, 3,010 t-states own (0.00 %) |
| Runs (the other recordings) | 402 calls (`stage1/rec/rzx-p1-04000` 120, `stage1/rec/rzx-p1-06000` 114, `stage1/rec/rzx-p1-08000` 93 and 3 more) |
| Called from | `DrawObject` (tail) |
| Calls | `Random`, `FindEnemySlot`, `EnemyShot`, `ObjectBehaviour` (tail) |
| Reads | `$5F0E` (system); `$5F26` (system); `$5F86` (system) |
| Writes | `$5D27`-`$5DAE` (system); `$5F10` (system); `$5F28` (system); `$5F88` (system); `$A054` (`EnemyShotKind`); `$A093` (`Temp1`) |

### `LauncherFire` (`$BC65`)

**Kind 11, the launcher: every few passes a shot that climbs (type `$87`)**

Witness: L1 5588 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 338 calls, 23,667 t-states own (0.00 %) |
| Runs (the other recordings) | 5,250 calls (`docs/integrate/rec/p1-poke41241` 2,010, `docs/integrate/rec/p1-shots` 381, `stage1/rec/rzx-p1-10000` 330 and 24 more) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `Random2`, `FindEnemySlot`, `EnemyShot`, `ObjectCollide` (tail) |
| Reads | `$5E66` (system); `$5E77`-`$5E7E` (system); `$5E8F`-`$5E96` (system); `$5EA7`-`$5EAE` (system); `$5EBF`-`$5EC6` (system); `$5ED7`-`$5ED8` (system) |
| Writes | `$5D2D`-`$5DD3` (system); `$5DF0`-`$5DF1` (system); `$5E2C`-`$5E2D` (system); `$5E77` (system); `$5E8F` (system); `$5EA7` (system); 3 more ranges |

### `ShootersFire` (`$BC92`)

**Kind 10, the shooters: every few passes two shots, right and left**

Witness: L1 5066 (c1, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x17).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 113 calls, 7,107 t-states own (0.00 %) |
| Runs (the other recordings) | 4,953 calls (`docs/integrate/rec/p1-speedup` 1,465, `stage1/rec/rzx-p1-52000` 895, `stage1/rec/rzx-p1-60000` 468 and 20 more) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `Random`, `FindEnemySlot`, `ObjectCollide` (tail), `ShootFromObject` |
| Reads | `$5E66` (system); `$5E77`-`$5E7E` (system); `$5E8F`-`$5E96` (system); `$5EA7`-`$5EAE` (system); `$5EBF`-`$5EC6` (system); `$5ED7`-`$5EDE` (system); 1 more ranges |
| Writes | `$5E77` (system); `$5E8F` (system); `$5EA7` (system); `$5EBF` (system); `$5ED7` (system); `$5EEF` (system); 1 more ranges |

### `ShootFromObject` (`$BCC6`)

**A shot from IX at X A, Y IX+1 + 15**

Witness: L1 288 (c1, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x13).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 6 calls, 701 t-states own (0.00 %) |
| Runs (the other recordings) | 282 calls (`docs/integrate/rec/p1-speedup` 98, `stage1/rec/rzx-p1-52000` 58, `stage1/rec/rzx-p1-60000` 24 and 16 more) |
| Called from | `ShootersFire` |
| Calls | `SetupShot` |
| Reads | `$5E67` (system); `$5E7F` (system); `$5E97` (system); `$5EAF` (system); `$5EC7` (system); `$5EDF` (system) |
| Writes | `$5D27`-`$5DAE` (system); `$5DCC`-`$5DDB` (system); `$5DF9`-`$5E08` (system); `$A093`-`$A099` (`Temp1`, `Temp2`, `Temp3`, `Temp4`) |

### `SwingGun` (`$BCDD`)

**Kind 9, the swing gun: its angle picture (SwingGunFrames `$BECB`), at random a shot in its angle's direction**

Witness: L1 10296 (c1, p1-cursor, p1-kempston, p1-rooms238, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x22).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 581 calls, 141,360 t-states own (0.01 %) |
| Runs (the other recordings) | 9,715 calls (`stage1/rec/rzx-p1-08000` 1,033, `stage2/rec/p1-room27` 900, `stage1/rec/rzx-p1-06000` 843 and 26 more) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `Random`, `FindEnemySlot`, `ObjectCollide` (tail), `SwingShotUpLeft`, `SwingShotLeft`, `SwingShotRight`, `SwingShotUpRight` |
| Reads | `$5E77`-`$5E78` (system); `$5E8F`-`$5E90` (system); `$5EA7`-`$5EA8` (system); `$5EBF`-`$5EC0` (system); `$5ED7`-`$5ED8` (system); `$5EEF`-`$5EF0` (system); 4 more ranges |
| Writes | `$5E6A`-`$5EFB` (system); `$5F12`-`$5F13` (system); `$5F2A`-`$5F2B` (system); `$A054` (`EnemyShotKind`) |

### `RamTurn` (`$BD44`)

**The hit foot man's turn (kind 6, from DrawObject): the turning picture at count +`$11` = 4, kind 7 at 0**

Witness: L1 394 (p1-speedup, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 394 calls (`stage1/rec/rzx-p1-28000` 61, `stage1/rec/rzx-p1-46000` 48, `stage1/rec/rzx-p1-38000` 46 and 17 more) |
| Called from | `DrawObject` (tail) |
| Calls | `ObjectBehaviour` (tail) |
| Reads | `$5E77` (system); `$5E8F` (system); `$5EA7` (system); `$5EBF` (system); `$5ED7` (system); `$5EEF` (system); 8 more ranges |
| Writes | `$5E6F`-`$5F85` (system); `$5FA7`-`$5FCD` (system) |

### `BlowUp` (`$BD6B`)

**An object explodes: the six shards drawn (DrawShard), the attribute flash; at the end it leaves a pod or the points**

Witness: L1 3891 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 128 calls, 60,841 t-states own (0.00 %) |
| Runs (the other recordings) | 3,763 calls (`stage1/rec/rzx-p1-62000` 256, `stage1/rec/rzx-p1-20000` 205, `stage1/rec/rzx-p1-58000` 200 and 39 more) |
| Called from | `DrawObject` (tail) |
| Calls | `Random`, `NextObject` (tail), `DrawShard`, `CopyCells3`, `FlashCells` |
| Reads | `$5E66`-`$5F9B` (system); `$5FB6`-`$5FCB` (system); `$A093`-`$A096` (`Temp1`, `Temp2`) |
| Writes | `$5E67`-`$5F99` (system); `$5FB7`-`$5FC9` (system); `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |

### `SwingShotUpLeft` (`$BE5B`)

**A swing gun shot up and left**

Witness: L1 557 (p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 557 calls (`stage1/rec/rzx-p1-46000` 65, `stage1/rec/rzx-p1-60000` 62, `stage1/rec/rzx-p1-50000` 55 and 18 more) |
| Called from | `SwingGun` |
| Calls | `EnemyShot`, `SwingShotSet` (tail) |
| Reads | `$5E66` (system); `$5E7E` (system); `$5E96` (system); `$5EAE` (system); `$5EC6` (system); `$5EDE` (system) |
| Writes | `$5D26`-`$5E16` (system); `$5E34` (system); `$A093` (`Temp1`) |

### `SwingShotLeft` (`$BE75`)

**A swing gun shot left**

Witness: L1 965 (c1, p1-cursor, p1-kempston, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 20 calls, 2,261 t-states own (0.00 %) |
| Runs (the other recordings) | 945 calls (`stage1/rec/rzx-p1-60000` 95, `stage1/rec/rzx-p1-46000` 90, `stage2/rec/p1-room27` 79 and 23 more) |
| Called from | `SwingGun` |
| Calls | `EnemyShot`, `SwingShotSet` (falls into) |
| Reads | `$5E66` (system); `$5E7E` (system); `$5E96` (system); `$5EAE` (system); `$5EC6` (system); `$5EDE` (system); 2 more ranges |
| Writes | `$5D26`-`$5E25` (system); `$A093` (`Temp1`) |

### `SwingShotSet` (`$BE8C`)

**The shot's dX (HL) and speed**

Witness: L1 2741 (c1, p1-cursor, p1-kempston, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x22).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 51 calls, 5,186 t-states own (0.00 %) |
| Runs (the other recordings) | 2,660 calls (`stage1/rec/rzx-p1-60000` 299, `stage1/rec/rzx-p1-46000` 289, `stage2/rec/p1-room27` 258 and 22 more) |
| Called from | `SwingShotUpLeft` (tail), `SwingShotLeft` (falls into), `SwingShotRight` (tail), `SwingShotUpRight` (tail) |
| Calls | `SetShotSpeed` |
| Writes | `$5D27`-`$5E38` (system) |

### `SwingShotRight` (`$BE9B`)

**A swing gun shot right**

Witness: L1 802 (c1, p1-cursor, p1-kempston, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 15 calls, 1,842 t-states own (0.00 %) |
| Runs (the other recordings) | 787 calls (`stage1/rec/rzx-p1-60000` 96, `stage1/rec/rzx-p1-46000` 89, `stage2/rec/p1-room27` 80 and 22 more) |
| Called from | `SwingGun` |
| Calls | `EnemyShot`, `SwingShotSet` (tail) |
| Reads | `$5E66` (system); `$5E7E` (system); `$5E96` (system); `$5EAE` (system); `$5EC6` (system); `$5EDE` (system); 2 more ranges |
| Writes | `$5D26`-`$5E25` (system); `$A093` (`Temp1`) |

### `SwingShotUpRight` (`$BEB3`)

**A swing gun shot up and right**

Witness: L1 417 (c1, p1-cursor, p1-kempston, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 16 calls, 1,978 t-states own (0.00 %) |
| Runs (the other recordings) | 401 calls (`stage2/rec/p1-room27` 50, `stage1/rec/rzx-p1-60000` 46, `stage1/rec/rzx-p1-46000` 45 and 19 more) |
| Called from | `SwingGun` |
| Calls | `EnemyShot`, `SwingShotSet` (tail) |
| Reads | `$5E66` (system); `$5E7E` (system); `$5E96` (system); `$5EAE` (system); `$5EC6` (system); `$5EDE` (system); 1 more ranges |
| Writes | `$5D26`-`$5DE9` (system); `$5E07`-`$5E16` (system); `$A093` (`Temp1`) |

### `AnimatePod` (`$BED3`)

**The power pod's frames (PodFrames `$BF5B`); a pod not taken in time goes**

Witness: L1 17476 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 571 calls, 187,334 t-states own (0.01 %) |
| Runs (the other recordings) | 16,905 calls (`stage1/rec/rzx-p1-58000` 1,704, `stage1/rec/rzx-p1-52000` 936, `stage1/rec/rzx-p1-56000` 760 and 37 more) |
| Called from | `ObjectBehaviour` |
| Reads | `$5E6C`-`$5F81` (system); `$5FBC`-`$5FC9` (system); `$BF5C`-`$BF65` (`PodFrames+1`) |
| Writes | `$5E6A`-`$5F7F` (system); `$5FBA`-`$5FC7` (system) |

### `DrawShard` (`$BF66`)

**One shard of an explosion along its path at HL: the border's speaker bit random (the explosion's crackle), the shard ORed into the buffer**

Witness: L1 23346 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 768 calls, 419,171 t-states own (0.03 %) |
| Runs (the other recordings) | 22,578 calls (`stage1/rec/rzx-p1-62000` 1,536, `stage1/rec/rzx-p1-20000` 1,230, `stage1/rec/rzx-p1-58000` 1,200 and 39 more) |
| Called from | `BlowUp` |
| Calls | `OrChar` |
| Reads | `$5E66`-`$5EF9` (system); `$5F0E`-`$5F11` (system); `$5F26`-`$5F29` (system); `$5F3E`-`$5F41` (system); `$5F56`-`$5F59` (system); `$5F6E`-`$5F71` (system); 5 more ranges |
| Writes | `$A093` (`Temp1`); `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE`, `$20FE`, `$28FE`, `$30FE`, `$38FE`, `$40FE`, `$48FE`, `$50FE`, `$58FE`, `$60FE`, `$68FE`, `$70FE`, `$78FE`, `$80FE`, `$88FE`, `$90FE`, `$98FE`, `$A0FE`, `$A8FE`, `$B0FE`, `$B8FE`, `$C0FE`, `$C8FE`, `$D0FE`, `$D8FE`, `$E0FE`, `$E8FE`, `$F0FE`, `$F8FE` |

### `ObjectMove` (`$BFEF`)

**The kinds' moves: pods none; 8 scanner, 12/13 the ground walkers, 14 the mine, 15 the blob, 2 the mine layer's burst; the others walk right or left**

Witness: L1 60370 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 971 calls, 111,893 t-states own (0.01 %) |
| Runs (the other recordings) | 59,399 calls (`stage1/rec/rzx-p1-20000` 3,040, `stage1/rec/rzx-p1-58000` 2,929, `stage1/rec/rzx-p1-04000` 2,875 and 43 more) |
| Called from | `ObjectBehaviour` |
| Calls | `BlobStart` (tail), `DriftObject` (tail), `GroundWalker` (tail), `Scanner` (tail), `WalkRight` (tail), `WalkLeft` (tail) |
| Reads | `$5E68`-`$5F17` (system); `$5F28`-`$5F2F` (system); `$5F40`-`$5F47` (system); `$5F58`-`$5F5F` (system); `$5F70`-`$5F77` (system); `$5F88`-`$5F8F` (system); 2 more ranges |

### `MineBurst` (`$C03A`)

**At random (1 in 7) a burst of 8 shots in the spray's directions**

Witness: L1 21 (rzx-p1-04000, rzx-p1-18000, rzx-p1-20000, rzx-p1-56000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21 calls (`stage1/rec/rzx-p1-20000` 10, `stage1/rec/rzx-p1-56000` 6, `stage1/rec/rzx-p1-04000` 4 and 1 more) |
| Called from | `Scanner` |
| Calls | `Random`, `SetShotDirection`, `FindEnemySlot`, `EnemyShotFrom` |
| Writes | `$A054` (`EnemyShotKind`) |

### `Climb` (`$C05A`)

**Kinds 12 and 13: rise by the speed until a solid cell above**

Witness: L1 4169 (p1-code, p1-gameover, p1-shots, p1-speedup, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,169 calls (`stage1/rec/rzx-p1-62000` 817, `stage2/rec/p1-code` 512, `stage1/rec/rzx-p1-16000` 455 and 18 more) |
| Called from | `ObjectJump` (tail) |
| Calls | `Random`, `ObjectCell`, `IsSolid` |
| Reads | `$5E67`-`$5F68` (system) |
| Writes | `$5E67`-`$5F0F` (system); `$5F20`-`$5F68` (system) |

### `FlyBounce` (`$C0E0`)

**A flyer's step: inside the play area move by its speed; at an edge turn**

Witness: L1 7803 (p1-rooms238, p1-room14, p1-room24, p1-room26, rzx-p1- x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,803 calls (`stage1/rec/rzx-p1-04000` 1,499, `stage1/rec/rzx-p1-20000` 1,405, `stage1/rec/rzx-p1-06000` 1,300 and 8 more) |
| Called from | `BlobStart` |
| Calls | `CellPointer` |
| Reads | `$5E66`-`$5E6B` (system); `$5E7E`-`$5E83` (system); `$5E96`-`$5E9B` (system); `$5EAE`-`$5EB3` (system); `$5EC6`-`$5ECB` (system); `$5EDE`-`$5EE3` (system); 9 more ranges |
| Writes | `$5E6A`-`$5F37` (system); `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |

### `RandomFlight` (`$C12E`)

**A random direction: dX and dY each +1 or -1**

Witness: L1 551 (p1-rooms238, p1-room14, p1-room24, p1-room26, rzx-p1- x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 551 calls (`stage1/rec/rzx-p1-20000` 105, `stage1/rec/rzx-p1-06000` 93, `stage2/rec/p1-room14` 91 and 8 more) |
| Called from | `DriftObject` (tail) |
| Calls | `RandomSign` |
| Writes | `$5E6A`-`$5E6B` (system); `$5E82`-`$5E83` (system); `$5E9A`-`$5E9B` (system); `$5EB2`-`$5EB3` (system); `$5ECA`-`$5ECB` (system); `$5EE2`-`$5EE3` (system); 3 more ranges |

### `RandomSign` (`$C13B`)

**A = +1 or -1 at random (Signs `$C149`)**

Witness: L1 1102 (p1-rooms238, p1-room14, p1-room24, p1-room26, rzx-p1- x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,102 calls (`stage1/rec/rzx-p1-20000` 210, `stage1/rec/rzx-p1-06000` 186, `stage2/rec/p1-room14` 182 and 8 more) |
| Called from | `RandomFlight` |
| Calls | `Random2` |
| Reads | `$C149`-`$C14A` (`Signs`) |

### `BlobStart` (`$C14D`)

**Kind 15, the blob: FlyBounce, then DriftObject**

Witness: L1 7803 (p1-rooms238, p1-room14, p1-room24, p1-room26, rzx-p1- x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,803 calls (`stage1/rec/rzx-p1-04000` 1,499, `stage1/rec/rzx-p1-20000` 1,405, `stage1/rec/rzx-p1-06000` 1,300 and 8 more) |
| Called from | `ObjectMove` (tail) |
| Calls | `FlyBounce` |
| Reads | `$5E66`-`$5F37` (system) |
| Writes | `$5E66`-`$5F37` (system) |

### `DriftObject` (`$C150`)

**Kinds 14 (the mine, entered here) and 15: drift by dX, dY; a solid cell turns it, or kills a mine**

Witness: L1 13169 (p1-code, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,366 calls (`stage1/rec/rzx-p1-62000` 952, `stage1/rec/rzx-p1-22000` 788, `stage2/rec/p1-code` 688 and 11 more) |
| Called from | `ObjectMove` (tail) |
| Calls | `KillObject` (tail), `RandomFlight` (tail), `IsSolid` |
| Reads | `$5E66`-`$5F98` (system); `$A01B`-`$A01C` (`ObjectCellPtr`); `$A0B6`-`$A0B7` (`RexX`, `RexY`) |
| Writes | `$5E66`-`$5F98` (system) |

### `GroundWalker` (`$C1CA`)

**Kinds 12 and 13: walk right or left; the mine layer drops a mine at random**

Witness: L1 4169 (p1-code, p1-gameover, p1-shots, p1-speedup, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,169 calls (`stage1/rec/rzx-p1-62000` 817, `stage2/rec/p1-code` 512, `stage1/rec/rzx-p1-16000` 455 and 18 more) |
| Called from | `ObjectMove` (tail) |
| Calls | `Random`, `WalkRight`, `WalkLeft` |
| Reads | `$5E66`-`$5EE7` (system); `$5EF8`-`$5EFF` (system); `$5F10`-`$5F17` (system); `$5F28`-`$5F2F` (system); `$5F40`-`$5F5F` (system); `$A093`-`$A095` (`Temp1`, `Temp2`) |
| Writes | `$5E66`-`$5F92` (system); `$A093`-`$A095` (`Temp1`, `Temp2`) |

### `DropMine` (`$C1F4`)

**Make a mine (kind 14) at Temp1, Temp2 in a free object record**

Witness: L1 164 (p1-code, p1-speedup, p1-room30, rzx-p1- x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`stage1/rec/rzx-p1-22000` 11, `stage1/rec/rzx-p1-24000` 6) |
| Called from | `BigGun` |
| Calls | `InitKind14`, `FindFreeObject` |
| Reads | `$A093`-`$A095` (`Temp1`, `Temp2`) |
| Writes | `$5E7E`-`$5F02` (system) |

### `ScannerUp` (`$C213`)

**Kind 8 moving up: its timer steps, then the turn**

Witness: L1 917 (p1-room30, rzx-p1- x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 917 calls (`stage1/rec/rzx-p1-20000` 331, `stage1/rec/rzx-p1-54000` 232, `stage1/rec/rzx-p1-56000` 198 and 3 more) |
| Called from | `ObjectJump` (tail) |
| Calls | `ScannerTurn` (tail) |
| Reads | `$5E67`-`$5E78` (system); `$5E8F` (system); `$5EA7`-`$5EC0` (system) |
| Writes | `$5E67`-`$5E78` (system); `$5EAF`-`$5EC0` (system) |

### `Scanner` (`$C27E`)

**Kind 8: stalks Rex, rising and sinking at his height; walks his way when he stands**

Witness: L1 917 (p1-room30, rzx-p1- x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 917 calls (`stage1/rec/rzx-p1-20000` 331, `stage1/rec/rzx-p1-54000` 232, `stage1/rec/rzx-p1-56000` 198 and 3 more) |
| Called from | `ObjectMove` (tail) |
| Calls | `ReadLeft`, `ReadRight`, `MineBurst`, `ScannerTurn` (tail), `ScannerReset`, `WalkRight`, `WalkLeft` |
| Reads | `$5E66`-`$5EC1` (system); `$A0B6`-`$A0BD` (`RexX`, `RexY`, `Room`, `RoomColumn` and 3 more); `$C25A`-`$C279` (`ScannerFrames`) |
| Writes | `$5E6A`-`$5E91` (system); `$5EA8`-`$5EC1` (system) |

### `ScannerDown` (`$C2FD`)

**Kind 8 moving down**

Witness: L1 917 (p1-room30, rzx-p1- x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 917 calls (`stage1/rec/rzx-p1-20000` 331, `stage1/rec/rzx-p1-54000` 232, `stage1/rec/rzx-p1-56000` 198 and 3 more) |
| Called from | `ObjectFall` (tail) |
| Calls | `ScannerTurn` (tail) |
| Reads | `$5E67`-`$5E78` (system); `$5E8F` (system); `$5EA7`-`$5EC0` (system) |
| Writes | `$5E67` (system); `$5E78` (system); `$5EAF` (system); `$5EC0` (system) |

### `ScannerTurn` (`$C313`)

**Kind 8 at a cell edge: its next direction from the grid round it**

Witness: L1 109 (p1-room30, rzx-p1- x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 109 calls (`stage1/rec/rzx-p1-20000` 42, `stage1/rec/rzx-p1-54000` 31, `stage1/rec/rzx-p1-56000` 26 and 3 more) |
| Called from | `ScannerUp` (tail), `Scanner` (tail), `ScannerDown` (tail) |
| Calls | `CellPointer`, `IsSolid` |
| Reads | `$5E66`-`$5E7E` (system); `$5E96` (system); `$5EAE`-`$5EBF` (system) |
| Writes | `$5E68`-`$5E78` (system); `$5E90` (system); `$5EA8`-`$5EC0` (system); `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |

### `ScannerReset` (`$C3BE`)

**Kind 8's start state**

Witness: L1 21 (rzx-p1-04000, rzx-p1-18000, rzx-p1-20000, rzx-p1-56000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21 calls (`stage1/rec/rzx-p1-20000` 10, `stage1/rec/rzx-p1-56000` 6, `stage1/rec/rzx-p1-04000` 4 and 1 more) |
| Called from | `Scanner` |
| Reads | `$5E6F` (system); `$5E87` (system); `$5EB7` (system) |
| Writes | `$5E68`-`$5E91` (system); `$5EB0`-`$5EC1` (system) |

### `WalkRight` (`$C3E0`)

**A walker's step right: a solid cell ahead turns it (or kills a person, or stops the jumper)**

Witness: L1 11394 (p1-code, p1-gameover, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x29).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11,394 calls (`stage1/rec/rzx-p1-14000` 739, `stage1/rec/rzx-p1-32000` 631, `stage1/rec/rzx-p1-56000` 522 and 37 more) |
| Called from | `ObjectMove` (tail), `GroundWalker`, `Scanner` |
| Calls | `BlockedRight` (tail), `EdgeLeft` (tail), `MaybeJumpRight`, `MaybeJumpLeft`, `StartFall` (tail), `IsSolid` |
| Reads | `$5E66`-`$5F7E` (system); `$5F9E`-`$5FC6` (system); `$A01B`-`$A01C` (`ObjectCellPtr`); `$E221`-`$E495` (`RoomGridPlay+34`, `ExplosionPicture`); `$E4AE`-`$E4B3` (`ExplosionPicture+376`) |
| Writes | `$5E66`-`$5E80` (system); `$5E96`-`$5E98` (system); `$5EAE`-`$5EB0` (system); `$5EC6`-`$5EC8` (system); `$5EDE`-`$5EE0` (system); `$5EF6`-`$5EF8` (system); 7 more ranges |

### `BlockedRight` (`$C469`)

**Blocked: kinds 6 and 7 stay, the others turn**

Witness: L1 290 (p1-code, p1-rooms238, p1-shots, p1-speedup, p1-room14, p1-room24, p1-room30, rzx-p1- x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/rzx-p1-08000` 1) |
| Called from | `WalkRight` (tail) |
| Calls | `TurnAround` (falls into) |
| Reads | `$5EB7` (system) |

### `TurnAround` (`$C472`)

**Direction ^ 1**

Witness: L1 295 (p1-code, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room14, p1-room24, p1-room30, rzx-p1- x28).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 198 calls (`stage1/rec/rzx-p1-32000` 26, `stage1/rec/rzx-p1-04000` 26, `stage1/rec/rzx-p1-48000` 18 and 17 more) |
| Called from | `BlockedRight` (falls into), `EdgeLeft` (tail) |
| Calls | `WalkOff` (falls into) |
| Reads | `$5E68` (system); `$5E80` (system); `$5E98` (system); `$5EB0` (system); `$5EC8` (system); `$5EE0` (system); 8 more ranges |
| Writes | `$5E68` (system); `$5E80` (system); `$5E98` (system); `$5EB0` (system); `$5EC8` (system); `$5EE0` (system); 8 more ranges |

### `WalkOff` (`$C47A`)

**Kinds 6 and 7 off the edge die (KillObject); 3, 4, 5 vanish (ObjectGone: alive 0, no score)**

Witness: L1 511 (p1-code, p1-gameover, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x29).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 507 calls (`stage1/rec/rzx-p1-14000` 49, `stage1/rec/rzx-p1-04000` 46, `stage1/rec/rzx-p1-32000` 33 and 32 more) |
| Called from | `TurnAround` (falls into), `WalkLeft` (tail) |
| Calls | `KillObject` (tail), `ObjectGone` (tail) |
| Reads | `$5E6F` (system); `$5E87` (system); `$5E9F` (system); `$5EB7` (system); `$5ECF` (system); `$5EE7` (system); 8 more ranges |
| Writes | `$5EBA` (system); `$5ED2` (system); `$5EEA` (system); `$5F1A` (system); `$5F32` (system); `$5F4A` (system); 3 more ranges |

### `ObjectGone` (`$C497`)

**The object is dead (alive = 0)**

Witness: L1 27 (rzx-p1- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/rzx-p1-10000` 4) |
| Called from | `WalkOff` (tail), `EdgeLeft` (tail) |
| Writes | `$5E72` (system); `$5F02` (system); `$5F1A` (system); `$5F32` (system) |

### `EdgeLeft` (`$C49C`)

**At the left edge: kind 0 dies, the others turn**

Witness: L1 83 (p1-code, p1-poke41241, p1-speedup, p1-room30, rzx-p1- x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 64 calls (`stage1/rec/rzx-p1-32000` 25, `stage1/rec/rzx-p1-62000` 7, `stage1/rec/rzx-p1-10000` 5 and 13 more) |
| Called from | `WalkRight` (tail), `WalkLeft` (tail) |
| Calls | `TurnAround` (tail), `ObjectGone` (tail) |
| Reads | `$5E6F` (system); `$5E87` (system); `$5E9F` (system); `$5EB7` (system); `$5ECF` (system); `$5EE7` (system); 5 more ranges |
| Writes | `$5E8A` (system); `$5EA2` (system); `$5ED2` (system); `$5EEA` (system); `$5F02` (system); `$5F1A` (system) |

### `WalkLeft` (`$C4A6`)

**A walker's step left**

Witness: L1 16822 (c1, p1-code, p1-gameover, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 400 calls, 148,576 t-states own (0.01 %) |
| Runs (the other recordings) | 16,422 calls (`stage1/rec/rzx-p1-32000` 1,200, `docs/integrate/rec/p1-speedup` 1,015, `stage1/rec/rzx-p1-04000` 964 and 37 more) |
| Called from | `ObjectMove` (tail), `GroundWalker`, `Scanner` |
| Calls | `WalkOff` (tail), `EdgeLeft` (tail), `MaybeJumpRight`, `MaybeJumpLeft`, `StartFallIfIdle` (tail), `IsSolid` |
| Reads | `$5E66`-`$5FC6` (system); `$A01B`-`$A01C` (`ObjectCellPtr`); `$E1E6`-`$E4A8` (`RoomGrid+71`, `RoomGridPlay`, `ExplosionPicture`) |
| Writes | `$5E66`-`$5EB0` (system); `$5EC6`-`$5EC8` (system); `$5EDE`-`$5EE0` (system); `$5EF6`-`$5EF8` (system); `$5F0E`-`$5F10` (system); `$5F26`-`$5F28` (system); 6 more ranges |

### `MaybeJumpRight` (`$C531`)

**At random a jump instead of the step**

Witness: L1 234 (p1-speedup, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 234 calls (`stage1/rec/rzx-p1-58000` 51, `stage1/rec/rzx-p1-14000` 45, `stage1/rec/rzx-p1-56000` 25 and 15 more) |
| Called from | `WalkRight`, `WalkLeft` |
| Calls | `Random`, `StartHop` (tail) |
| Reads | `$5E77`-`$5E8F` (system); `$5EB7`-`$5EBF` (system); `$5EE7`-`$5EEF` (system); `$5F07` (system); `$5F1F` (system) |
| Writes | `$5E77`-`$5E90` (system); `$5EA7`-`$5EC0` (system); `$5ED7`-`$5EF0` (system); `$5F07` (system); `$5F1F` (system); `$5F37` (system); 1 more ranges |

### `MaybeJumpLeft` (`$C540`)

**At random a jump**

Witness: L1 322 (p1-speedup, rzx-p1- x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 322 calls (`stage1/rec/rzx-p1-38000` 54, `stage1/rec/rzx-p1-32000` 52, `stage1/rec/rzx-p1-46000` 26 and 16 more) |
| Called from | `WalkRight`, `WalkLeft` |
| Calls | `Random`, `StartFallIfIdle` (tail) |
| Writes | `$5E77` (system); `$5E8F` (system); `$5EA7` (system); `$5EBF` (system); `$5ED7` (system); `$5EEF` (system); 3 more ranges |

### `StartHop` (`$C54D`)

**A hop: the jumper's picture `$8E8A`**

Witness: L1 118 (p1-speedup, p1-room30, rzx-p1- x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 87 calls (`stage1/rec/rzx-p1-58000` 26, `stage1/rec/rzx-p1-32000` 12, `stage1/rec/rzx-p1-56000` 11 and 10 more) |
| Called from | `MaybeJumpRight` (tail) |
| Calls | `SetHop` (falls into) |
| Reads | `$5E77`-`$5EBF` (system); `$5ED7` (system); `$5EEF` (system); `$5F07`-`$5F1F` (system); `$5F37` (system); `$5F4F` (system); 1 more ranges |
| Writes | `$5E9A`-`$5EC0` (system); `$5F12`-`$5F20` (system) |

### `SetHop` (`$C556`)

**The hop's state: picture HL, speed, timers, bit 7 of the kind**

Witness: L1 52 (p1-speedup, p1-room26, rzx-p1- x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 46 calls (`stage1/rec/rzx-p1-58000` 8, `stage1/rec/rzx-p1-14000` 6, `stage1/rec/rzx-p1-32000` 5 and 12 more) |
| Called from | `StartHop` (falls into), `MaybeJumper` |
| Calls | `Random` |
| Reads | `$5E6F` (system); `$5E87` (system); `$5E9F` (system); `$5EB7` (system); `$5ECF` (system); `$5EE7` (system); 5 more ranges |
| Writes | `$5E6A`-`$5F68` (system) |

### `MaybeJumper` (`$C577`)

**A kind 0 walker at random becomes a jumper (SpriteJumper `$91B2`)**

Witness: L1 86024 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,131 calls, 81,674 t-states own (0.01 %) |
| Runs (the other recordings) | 83,893 calls (`docs/integrate/rec/p1-speedup` 4,323, `stage1/rec/rzx-p1-58000` 3,405, `stage1/rec/rzx-p1-20000` 3,245 and 43 more) |
| Called from | `DrawObject` |
| Calls | `Random`, `SetHop` |
| Reads | `$5E66`-`$5F77` (system); `$5F8F`-`$5FBF` (system) |
| Writes | `$5E78` (system); `$5E90` (system); `$5EA8` (system); `$5ED8` (system); `$5EF0` (system); `$5F08` (system); 3 more ranges |

### `JumperTimer` (`$C5B6`)

**The jumper's timer; at its end it walks again**

Witness: L1 86024 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,131 calls, 98,123 t-states own (0.01 %) |
| Runs (the other recordings) | 83,893 calls (`docs/integrate/rec/p1-speedup` 4,323, `stage1/rec/rzx-p1-58000` 3,405, `stage1/rec/rzx-p1-20000` 3,245 and 43 more) |
| Called from | `DrawObject` |
| Reads | `$5E6F`-`$5F8F` (system); `$5FA7`-`$5FC8` (system) |
| Writes | `$5E6F`-`$5F20` (system); `$5F37` (system); `$5F4F`-`$5F68` (system) |

### `StartFallIfIdle` (`$C5FD`)

**If the timer is 0, StartFall**

Witness: L1 191 (p1-speedup, rzx-p1- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 191 calls (`stage1/rec/rzx-p1-38000` 31, `stage1/rec/rzx-p1-32000` 25, `stage1/rec/rzx-p1-50000` 17 and 18 more) |
| Called from | `WalkLeft` (tail), `MaybeJumpLeft` (tail) |
| Calls | `StartFall` (falls into) |
| Reads | `$5E67`-`$5E8F` (system); `$5EA7` (system); `$5EBF`-`$5ED7` (system); `$5EEF`-`$5F37` (system); `$5F4F` (system); `$5F67` (system); 1 more ranges |
| Writes | `$5E69`-`$5E6B` (system); `$5E81`-`$5E83` (system); `$5EC9`-`$5ECB` (system); `$5EF9`-`$5EFB` (system); `$5F11`-`$5F13` (system); `$5F29`-`$5F2B` (system); 1 more ranges |

### `StartFall` (`$C602`)

**An object not falling and below line 24 starts to fall (JumpSteps `$D0D8`)**

Witness: L1 163 (p1-speedup, p1-room30, rzx-p1- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 149 calls (`stage1/rec/rzx-p1-32000` 19, `stage1/rec/rzx-p1-38000` 19, `stage1/rec/rzx-p1-46000` 18 and 14 more) |
| Called from | `WalkRight` (tail), `StartFallIfIdle` (falls into), `HitObject` |
| Reads | `$5E67`-`$5E6C` (system); `$5E7F`-`$5E84` (system); `$5E97`-`$5E9C` (system); `$5EAF`-`$5EB4` (system); `$5EC7`-`$5ECC` (system); `$5EDF`-`$5EE4` (system); 6 more ranges |
| Writes | `$5E69`-`$5E6B` (system); `$5E81`-`$5E83` (system); `$5E99`-`$5E9B` (system); `$5EB1`-`$5EB3` (system); `$5EC9`-`$5ECB` (system); `$5EE1`-`$5EE3` (system); 6 more ranges |

### `ObjectJump` (`$C620`)

**The jump of a walker by its jump table; kinds 8 and 12/13 their own; a solid cell above ends it**

Witness: L1 60369 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 971 calls, 94,800 t-states own (0.01 %) |
| Runs (the other recordings) | 59,398 calls (`stage1/rec/rzx-p1-20000` 3,040, `stage1/rec/rzx-p1-58000` 2,929, `stage1/rec/rzx-p1-04000` 2,875 and 43 more) |
| Called from | `ObjectBehaviour` |
| Calls | `KillObject` (tail), `CellPointer`, `Climb` (tail), `ScannerUp` (tail), `IsSolid` |
| Reads | `$5E66`-`$5F77` (system); `$5F89`-`$5FA7` (system); `$5FB9`-`$5FBF` (system); `$D0D8`-`$D0E2` (`JumpSteps`) |
| Writes | `$5E67`-`$5E6C` (system); `$5E7F`-`$5E83` (system); `$5E97`-`$5E9C` (system); `$5EAF`-`$5EB3` (system); `$5EC7`-`$5ECC` (system); `$5EDF`-`$5EE4` (system); 8 more ranges |

### `ObjectFall` (`$C6C2`)

**The fall: by the fall speed until a solid cell; below line `$B8` the object dies (a person counts)**

Witness: L1 60369 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 971 calls, 327,397 t-states own (0.02 %) |
| Runs (the other recordings) | 59,398 calls (`stage1/rec/rzx-p1-20000` 3,040, `stage1/rec/rzx-p1-58000` 2,929, `stage1/rec/rzx-p1-04000` 2,875 and 43 more) |
| Called from | `ObjectBehaviour` |
| Calls | `KillObject` (tail), `ScannerDown` (tail), `ObjectCell`, `IsPassable` |
| Reads | `$5E67`-`$5FBF` (system); `$E205`-`$E4DD` (`RoomGridPlay+6`, `ExplosionPicture`) |
| Writes | `$5E67`-`$5F5C` (system); `$5F6F`-`$5F74` (system); `$5F87`-`$5F8C` (system); `$5F9F`-`$5FBC` (system); `$A039`-`$A03D` (`KillFlashPtr`, `ComboCount`, `ComboTimer`) |

### `ObjectCell` (`$C72B`)

**ObjectCellPtr `$A01B` = the grid cell of the object at IX**

Witness: L1 102599 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,898 calls, 292,908 t-states own (0.02 %) |
| Runs (the other recordings) | 100,701 calls (`stage1/rec/rzx-p1-58000` 5,613, `stage1/rec/rzx-p1-32000` 4,591, `stage1/rec/rzx-p1-04000` 4,137 and 43 more) |
| Called from | `ObjectBehaviour`, `Climb`, `ObjectFall` |
| Calls | `CellPointer` |
| Reads | `$5E66`-`$5F10` (system); `$5F26`-`$5F28` (system); `$5F3E`-`$5F40` (system); `$5F56`-`$5F58` (system); `$5F6E`-`$5F70` (system); `$5F86`-`$5F88` (system); 2 more ranges |
| Writes | `$A01B`-`$A01C` (`ObjectCellPtr`); `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |

## rooms

`src/game/rooms.asm`

### `DrawRoom` (`$C745`)

**Draw the room: silence, the map's 7 x 10 blocks into the grid, the attribute shadow and SceneryCellList (its pixel writes into the buffer are wiped by BuildRoom's ClearBuffer after it; the cell list redraws them)**

Witness: L1 80 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

[Animation: `DrawRoom` at work](img/routines/DrawRoom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 7 calls, 588,132 t-states own (0.04 %) |
| Runs (the other recordings) | 73 calls (`stage1/rec/rzx-p1-02000` 4, `stage2/rec/p1-cursor` 3, `stage1/rec/rzx-p1-44000` 3 and 37 more) |
| Called from | `BuildRoom` |
| Calls | `DrawBlockRow`, `Multiply`, `SoundReset`, `SoundSilence` |
| Reads | `$5860`-`$5AFF` (screen); `$75E0`-`$7DCD` (`RoomMaps`); `$7E14`-`$7E59` (`RoomMaps+2100`); `$7EA0`-`$7F71` (`RoomMaps+2240`); `$A05F` (`SparkleOn`); `$A0B8` (`Room`); 1 more ranges |
| Writes | `$5860`-`$5925` (screen); `$593B`-`$5945` (screen); `$595B`-`$5965` (screen); `$597B`-`$5985` (screen); `$599B`-`$59A2` (screen); `$59BB`-`$5AFF` (screen); 3 more ranges |

### `DrawBlockRow` (`$C7C5`)

**One row of 10 blocks**

Witness: L1 5655 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 490 calls, 478,303 t-states own (0.03 %) |
| Runs (the other recordings) | 5,165 calls (`stage1/rec/rzx-p1-02000` 280, `stage1/rec/rzx-p1-16000` 210, `docs/rxA/rec/p1-rooms238` 210 and 37 more) |
| Called from | `DrawRoom` |
| Calls | `DrawRoomCell` |
| Reads | `$6CE0`-`$75DF` (`BlockDefs`) |

### `DrawRoomCell` (`$C7E2`)

**One block: its 3 x 3 characters into the buffer, the attribute shadow and the grid; an animated character listed**

Witness: L1 50898 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4,410 calls, 6,006,167 t-states own (0.41 %) |
| Runs (the other recordings) | 46,488 calls (`stage1/rec/rzx-p1-02000` 2,520, `stage1/rec/rzx-p1-16000` 1,890, `stage2/rec/p1-cursor` 1,890 and 37 more) |
| Called from | `DrawBlockRow` |
| Calls | `NextCellPtr` (falls into), `DrawRoomChar` |
| Reads | `$62E0`-`$6CDF` (`CharFlags`, `CharGraphics`, `CharAttrs`); `$A01D`-`$A01F` (`RoomCellPtr`); `$A095` (`Temp2`); `$A0B9`-`$A0BA` (`RoomColumn`) |
| Writes | `$A01D`-`$A01F` (`RoomCellPtr`); `$A095` (`Temp2`); `$A0B9`-`$A0BA` (`RoomColumn`); `$D962`-`$E19D` (`SceneryCellList`, `TitleMenu`, `RollCallRestart`, `RollCallText` and 19 more); `$E200`-`$E49D` (`RoomGridPlay+1`, `ExplosionPicture`); `$E560`-`$E7FD` (`AttrShadowPlay+1`); 1 more ranges |

### `NextCellPtr` (`$C87F`)

**The grid pointer one character on**

Witness: L1 407192 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 35,280 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,129 calls (`stage1/rec/rzx-p1-18000` 1,129) |
| Called from | `DrawRoomCell` (falls into) |
| Reads | `$63E0`-`$64DF` (`CharGraphics`, `AnimChar11`, `AnimChar26`, `AnimChar28`); `$6550`-`$665F` (`AnimChar28+144`, `AnimChar68`); `$6790`-`$6797` (`AnimChar111+56`); `$67E0`-`$67F7` (`AnimChar127+8`); `$6840`-`$6847` (`AnimChar127+104`); `$68C0`-`$69EF` (`AnimChar143+104`); 3 more ranges |
| Writes | `$A01E`-`$A01F` (`RoomCellPtr+1`); `$EB00`-`$FFFD` (`BackBuffer`, `work space $FFFA+`) |

### `DrawRoomChar` (`$C893`)

**One character's 8 bytes into the back buffer**

Witness: L1 50898 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4,410 calls, 1,034,389 t-states own (0.07 %) |
| Runs (the other recordings) | 46,488 calls (`stage1/rec/rzx-p1-02000` 2,520, `docs/rxA/rec/p1-rooms238` 1,890, `stage1/rec/rzx-p1-54000` 1,890 and 37 more) |
| Called from | `DrawRoomCell` |
| Reads | `$A093` (`Temp1`) |
| Writes | `$A093` (`Temp1`) |

### `CopyAttrs` (`$C8BF`)

**The attribute shadow `$E55F` to the screen's play rows `$5860`; the side columns white**

Witness: L1 136 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 13 calls, 239,694 t-states own (0.02 %) |
| Runs (the other recordings) | 123 calls (`stage1/rec/rzx-p1-02000` 7, `stage1/rec/rzx-p1-16000` 5, `stage2/rec/p1-cursor` 5 and 40 more) |
| Called from | `SmartBombStep`, `BuildRoom`, `BonusRoulette`, `WeaponPanel` |
| Reads | `$E55F`-`$E7FE` (`AttrShadowPlay`) |
| Writes | `$5860`-`$5AFF` (screen) |

### `Delay` (`$C8DB`)

**Wait BC x 10 loops**

Witness: L1 3097216 (c1, menu-rollcall, p1-cursor, p1-define, p1-kempston, p1-speedup, rzx-p1- x6).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 364 calls, 132,495,924 t-states own (9.13 %) |
| Runs (the other recordings) | 2,219,226 calls (`docs/rxA/rec/menu-rollcall` 2,043,571, `stage1/rec/rzx-p1-00000` 55,274, `stage2/rec/p1-cursor` 40,124 and 8 more) |
| Called from | `BonusRoulette`, `WeaponPanel`, `TitleMenu` |

### `Multiply` (`$C8E8`)

**HL = DE x B**

Witness: L1 6865 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x31).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,040 calls, 190,808 t-states own (0.01 %) |
| Runs (the other recordings) | 5,825 calls (`stage2/rec/p1-gameover` 512, `stage1/rec/rzx-p1-02000` 288, `stage1/rec/rzx-p1-54000` 216 and 39 more) |
| Called from | `DeathAnimation`, `DrawRoom`, `ReadExits`, `KillHumanPicture` |

### `ReadExits` (`$C8EF`)

**The room's exits and object list from RoomExits; the list's header: count, spawn sides, timers, spawn kind**

Witness: L1 80 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 7 calls, 3,017 t-states own (0.00 %) |
| Runs (the other recordings) | 73 calls (`stage1/rec/rzx-p1-02000` 4, `docs/rxA/rec/p1-rooms238` 3, `docs/integrate/rec/p1-speedup` 3 and 37 more) |
| Called from | `BuildRoom` |
| Calls | `Multiply`, `SetSpawnTop`, `SetSpawnRight`, `SetSpawnLeft` |
| Reads | `$A0B8` (`Room`); `$AECD`-`$AEF0` (`RoomObjectLists`); `$AF04`-`$AF06` (`RoomObjectLists+55`); `$AF1D`-`$AF1F` (`RoomObjectLists+80`); `$AF3C`-`$AF4B` (`RoomObjectLists+111`); `$AF5F`-`$AF6B` (`RoomObjectLists+146`); 14 more ranges |
| Writes | `$A020`-`$A02E` (`ObjectListPtr`, `HumanPicture`, `BoxX`, `BoxY` and 5 more); `$A043`-`$A044` (`SpawnTimer`, `SpawnPeriod`); `$A088`-`$A092` (`SpawnKind`, `HumansKilled`, `HiScore`, `RoomRight` and 5 more) |

### `SetSpawnTop` (`$C948`)

**SpawnTop `$A02E` = `$FF`**

Witness: L1 44 (c1, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 30 t-states own (0.00 %) |
| Runs (the other recordings) | 43 calls (`docs/integrate/rec/p1-speedup` 3, `stage1/rec/rzx-p1-16000` 3, `stage1/rec/rzx-p1-44000` 3 and 24 more) |
| Called from | `ReadExits` |
| Writes | `$A02E` (`SpawnTop`) |

### `SetSpawnRight` (`$C94E`)

**SpawnRight `$A02D` = `$FF`**

Witness: L1 49 (c1, p1-cursor, p1-kempston, p1-rooms238, p1-speedup, p1-room14, p1-room26, p1-room27, p1-room30, rzx-p1- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 130 t-states own (0.00 %) |
| Runs (the other recordings) | 45 calls (`stage1/rec/rzx-p1-44000` 3, `stage1/rec/rzx-p1-58000` 2, `docs/integrate/rec/p1-speedup` 2 and 26 more) |
| Called from | `ReadExits` |
| Writes | `$A02D` (`SpawnRight`) |

### `SetSpawnLeft` (`$C954`)

**SpawnLeft `$A02C` = `$FF`**

Witness: L1 36 (p1-rooms238, p1-speedup, p1-room24, p1-room26, p1-room27, p1-room30, rzx-p1- x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rec/rzx-p1-54000` 3, `stage1/rec/rzx-p1-04000` 2, `stage2/rec/p1-room30` 2 and 22 more) |
| Called from | `ReadExits` |
| Writes | `$A02C` (`SpawnLeft`) |

### `ChangeRoom` (`$C95A`)

**Rex goes through an exit to room A: Room `$A0B8` = A, MainLoop; room 99 is the end of part 1 (CodePanel `$A7CE`)**

Witness: L1 54 (c1, p1-code, p1-cursor, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x27).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 calls, 120 t-states own (0.00 %) |
| Runs (the other recordings) | 51 calls (`docs/integrate/rec/p1-speedup` 3, `docs/rxA/rec/p1-rooms238` 3, `stage1/rec/rzx-p1-02000` 2 and 34 more) |
| Called from | `ExitLeft` (tail), `ExitRight` (tail), `ExitTop` (tail), `RexFall` (tail) |
| Calls | `MainLoop` (tail), `CodePanel` (tail) |
| Reads | `$A0B8` (`Room`) |

### `StartScriptSpawn` (`$C965`)

**The scripted spawn starts: step 1, timer, count 0**

Witness: L1 6 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-08000, rzx-p1-12000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 94 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`docs/rxA/rec/p1-rooms238` 2, `stage1/rec/rzx-p1-08000` 1, `stage1/rec/rzx-p1-04000` 1 and 1 more) |
| Called from | `BuildRoom` |
| Reads | `$A045` (`ScriptSpawnStep`); `$A9F4` (`ScriptSpawn`) |
| Writes | `$A045`-`$A048` (`ScriptSpawnStep`, `ScriptSpawnTimer`, `ScriptSpawnCount`) |

### `SpawnScripted` (`$C978`)

**The scripted spawn's step: every few passes the next record of ScriptSpawn into a free object**

Witness: L1 18613 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 calls, 28,150 t-states own (0.00 %) |
| Runs (the other recordings) | 17,911 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `MakeObjectIY` |
| Reads | `$5E72`-`$5EEA` (system); `$5F02` (system); `$5F1A` (system); `$5F32` (system); `$5F4A` (system); `$5F62` (system); 5 more ranges |
| Writes | `$A045`-`$A048` (`ScriptSpawnStep`, `ScriptSpawnTimer`, `ScriptSpawnCount`) |

### `SpawnRandom` (`$C9CA`)

**The random spawn: every SpawnPeriod passes, from a spawn side chosen at random**

Witness: L1 18613 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `SpawnRandom` at work](img/routines/SpawnRandom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 calls, 50,267 t-states own (0.00 %) |
| Runs (the other recordings) | 17,911 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `Random`, `SpawnFromLeft`, `SpawnFromRight`, `SpawnFromTop` |
| Reads | `$5E72`-`$5F1A` (system); `$5F32` (system); `$5F4A` (system); `$5F62` (system); `$5F7A` (system); `$5F92` (system); 4 more ranges |
| Writes | `$A043` (`SpawnTimer`) |

### `SpawnFromLeft` (`$CA13`)

**A spawn at the left edge, at a free height**

Witness: L1 181 (c1, p1-cursor, p1-kempston, p1-poke41241, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room27, p1-room30, rzx-p1- x31).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 28 t-states own (0.00 %) |
| Runs (the other recordings) | 180 calls (`docs/integrate/rec/p1-speedup` 12, `stage1/rec/rzx-p1-18000` 11, `stage1/rec/rzx-p1-20000` 11 and 37 more) |
| Called from | `SpawnRandom` |
| Calls | `Random`, `SpawnObject`, `FindGround` |
| Reads | `$A02C` (`SpawnLeft`); `$A0B6` (`RexX`) |
| Writes | `$5E68` (system); `$5E80` (system); `$5E98` (system); `$5EB0` (system); `$5EC8` (system); `$5EE0` (system); 6 more ranges |

### `SpawnObject` (`$CA49`)

**Make an object of SpawnKind at SpriteX/Y**

Witness: L1 253 (c1, p1-gameover, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 136 t-states own (0.00 %) |
| Runs (the other recordings) | 252 calls (`stage1/rec/rzx-p1-58000` 22, `docs/integrate/rec/p1-speedup` 14, `stage1/rec/rzx-p1-32000` 13 and 36 more) |
| Called from | `SpawnFromLeft`, `SpawnFromRight`, `SpawnFromTop` |
| Calls | `Random2`, `MakeObject` |
| Reads | `$A088` (`SpawnKind`); `$A0AF`-`$A0B0` (`SpriteX`, `SpriteY`) |
| Writes | `$5E66`-`$5EC7` (system); `$5EDE`-`$5EDF` (system); `$5EF6`-`$5EF7` (system); `$5F0E`-`$5F0F` (system); `$5F26`-`$5F27` (system); `$5F3E`-`$5F3F` (system); 3 more ranges |

### `SpawnFromRight` (`$CA71`)

**A spawn at the right edge**

Witness: L1 193 (c1, p1-cursor, p1-define, p1-kempston, p1-poke41241, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x28).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 2,524 t-states own (0.00 %) |
| Runs (the other recordings) | 189 calls (`stage1/rec/rzx-p1-18000` 17, `stage1/rec/rzx-p1-58000` 14, `stage1/rec/rzx-p1-24000` 12 and 36 more) |
| Called from | `SpawnRandom` |
| Calls | `Random`, `SpawnObject`, `FindGround` |
| Reads | `$A02D` (`SpawnRight`); `$A0B6` (`RexX`) |
| Writes | `$5E68`-`$5EB0` (system); `$5EC8` (system); `$5EE0` (system); `$5EF8` (system); `$5F10` (system); `$5F28` (system); 5 more ranges |

### `SpawnFromTop` (`$CAA7`)

**A spawn at the top, above Rex's column**

Witness: L1 196 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room24, p1-room26, p1-room27, p1-room30, rzx-p1- x31).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 8 calls, 239 t-states own (0.00 %) |
| Runs (the other recordings) | 188 calls (`stage1/rec/rzx-p1-58000` 13, `stage1/rec/rzx-p1-60000` 12, `stage1/rec/rzx-p1-18000` 12 and 40 more) |
| Called from | `SpawnRandom` |
| Calls | `Random`, `CellPointer`, `SpawnObject` |
| Reads | `$A02E` (`SpawnTop`); `$A0AF`-`$A0B7` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight` and 3 more); `$E203`-`$E238` (`RoomGridPlay+4`) |
| Writes | `$5E68` (system); `$5E80` (system); `$5E98` (system); `$5EB0` (system); `$5EC8` (system); `$5EE0` (system); 6 more ranges |

### `FindGround` (`$CB03`)

**Find a place with ground under it for a spawn**

Witness: L1 2529 (c1, p1-speedup, p1-room x5, rzx-p1- x27).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 16 calls, 2,623 t-states own (0.00 %) |
| Runs (the other recordings) | 2,513 calls (`stage1/rec/rzx-p1-58000` 356, `stage1/rec/rzx-p1-18000` 203, `stage1/rec/rzx-p1-46000` 186 and 30 more) |
| Called from | `SpawnFromLeft`, `SpawnFromRight` |
| Calls | `CellPointer`, `IsPassable` |
| Reads | `$A093`-`$A094` (`Temp1`); `$E25C`-`$E49C` (`RoomGridPlay+93`, `ExplosionPicture`) |
| Writes | `$A093`-`$A094` (`Temp1`) |

### `MakeObjects` (`$CB52`)

**Build the room's objects from its list (ObjectListPtr `$A020`): [kind][X][Y] each**

Witness: L1 81 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

[Animation: `MakeObjects` at work](img/routines/MakeObjects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 7 calls, 65,936 t-states own (0.00 %) |
| Runs (the other recordings) | 74 calls (`stage1/rec/rzx-p1-02000` 4, `stage2/rec/p1-room30` 3, `stage1/rec/rzx-p1-44000` 3 and 37 more) |
| Called from | `BuildRoom` |
| Calls | `MakeObjectIY` |
| Reads | `$5E66`-`$5FE4` (system); `$A020`-`$A021` (`ObjectListPtr`); `$AED0`-`$B0AE` (`RoomObjectLists+3`); `$B0C8`-`$B0D7` (`RoomObjectLists+507`); `$B0F1`-`$B132` (`RoomObjectLists+548`) |
| Writes | `$5E66`-`$5FE5` (system) |

### `MakeObjectIY` (`$CB88`)

**Make the object of the list record at IY (kind from IY+0)**

Witness: L1 385 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 24 calls, 456 t-states own (0.00 %) |
| Runs (the other recordings) | 361 calls (`docs/rxA/rec/p1-rooms238` 21, `stage1/rec/rzx-p1-04000` 18, `stage1/rec/rzx-p1-16000` 16 and 37 more) |
| Called from | `SpawnScripted`, `MakeObjects` |
| Calls | `MakeObject` (falls into) |
| Reads | `$A9F5`-`$AA09` (`ScriptSpawn+1`); `$AED0`-`$B0AB` (`RoomObjectLists+3`); `$B0C8`-`$B0D4` (`RoomObjectLists+507`); `$B0F1`-`$B12F` (`RoomObjectLists+548`) |
| Writes | `$5E66`-`$5EC5` (system) |

### `MakeObject` (`$CB8B`)

**Make an object of kind A at IX: the common sizes, then the kind's initialiser**

Witness: L1 638 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x31).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 25 calls, 20,893 t-states own (0.00 %) |
| Runs (the other recordings) | 600 calls (`stage1/rec/rzx-p1-58000` 34, `docs/integrate/rec/p1-speedup` 29, `stage1/rec/rzx-p1-54000` 26 and 36 more) |
| Called from | `SpawnObject`, `MakeObjectIY` (falls into) |
| Calls | `InitKind0`, `InitKind6`, `InitKind1`, `InitKind3`, `InitKind4`, `InitKind5`, `InitKind8`, `InitBonusPod`, `InitKind9`, `InitKind17`, `InitKind18`, `InitKind19`, `InitKind20`, `InitKind10`, `InitKind11`, `InitKind12`, `InitKind13`, `InitKind15`, `InitKind16` |
| Reads | `$5E4E`-`$5E50` (system); `$A9F5`-`$AA0B` (`ScriptSpawn+1`); `$AED0`-`$B0AD` (`RoomObjectLists+3`); `$B0C8`-`$B0D6` (`RoomObjectLists+507`); `$B0F1`-`$B131` (`RoomObjectLists+548`); `$D78D`-`$D79B` (`SfxHitWall+6`, `SfxExplosion`); 1 more ranges |
| Writes | `$5E66`-`$5F9D` (system); `$5FB6`-`$5FCD` (system) |

### `InitKind0` (`$CC48`)

**Foot man: SpriteFootMan `$7F72`, ShiftFrames**

Witness: L1 212 (c1, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x28).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 87 t-states own (0.00 %) |
| Runs (the other recordings) | 211 calls (`stage1/rec/rzx-p1-58000` 22, `stage1/rec/rzx-p1-38000` 13, `docs/integrate/rec/p1-speedup` 13 and 32 more) |
| Called from | `MakeObject` |
| Writes | `$5E77`-`$5EDA` (system); `$5EEF`-`$5EF2` (system); `$5F07`-`$5F0A` (system); `$5F1F`-`$5F22` (system); `$5F37`-`$5F3A` (system); `$5F4F`-`$5F52` (system); 3 more ranges |

### `InitKind6` (`$CC5B`)

**List kind 6: the standing gunman, kind `$80` (bit 7 kept: +`$11` = `$C8`, which JumperTimer never counts), the fixed picture SpriteKind6, hits 2; a front hit makes it kind 6**

Witness: L1 45 (p1-speedup, p1-room14, p1-room26, p1-room27, p1-room30, rzx-p1- x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 45 calls (`stage1/rec/rzx-p1-44000` 6, `stage1/rec/rzx-p1-36000` 4, `stage1/rec/rzx-p1-54000` 4 and 16 more) |
| Called from | `MakeObject` |
| Writes | `$5E6A`-`$5EC2` (system); `$5EFA`-`$5F0A` (system) |

### `InitKind1` (`$CC83`)

**Stomper**

Witness: L1 43 (p1-rooms238, p1-room24, p1-room30, rzx-p1- x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 43 calls (`stage1/rec/rzx-p1-16000` 6, `stage1/rec/rzx-p1-58000` 5, `stage1/rec/rzx-p1-48000` 4 and 14 more) |
| Called from | `MakeObject` |
| Writes | `$5E76`-`$5E7B` (system); `$5E8E`-`$5E93` (system); `$5EA6`-`$5EAB` (system); `$5EBE`-`$5EC3` (system); `$5ED6`-`$5EDB` (system); `$5EEE`-`$5EF3` (system); 1 more ranges |

### `InitKind3` (`$CC96`)

**Kind 3**

Witness: L1 27 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-08000, rzx-p1-12000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 226 t-states own (0.00 %) |
| Runs (the other recordings) | 23 calls (`docs/rxA/rec/p1-rooms238` 8, `stage1/rec/rzx-p1-04000` 7, `stage1/rec/rzx-p1-08000` 4 and 1 more) |
| Called from | `MakeObject` |
| Writes | `$5EC2` (system); `$5EDA` (system); `$5EF2` (system); `$5F0A` (system); `$5F22` (system); `$5F3A` (system); 3 more ranges |

### `InitKind4` (`$CCA1`)

**Kind 4**

Witness: L1 6 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-08000, rzx-p1-12000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`stage1/rec/rzx-p1-04000` 2, `docs/rxA/rec/p1-rooms238` 1, `stage1/rec/rzx-p1-08000` 1 and 1 more) |
| Called from | `MakeObject` |
| Writes | `$5F22`-`$5F23` (system); `$5F3A`-`$5F3B` (system); `$5F9A`-`$5F9B` (system) |

### `InitKind5` (`$CCB0`)

**Kind 5**

Witness: L1 6 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-08000, rzx-p1-12000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`docs/rxA/rec/p1-rooms238` 2, `stage1/rec/rzx-p1-04000` 1, `stage1/rec/rzx-p1-08000` 1 and 1 more) |
| Called from | `MakeObject` |
| Writes | `$5EAA`-`$5EAB` (system); `$5EC2`-`$5EC3` (system); `$5F0A`-`$5F0B` (system); `$5F22`-`$5F23` (system) |

### `InitKind8` (`$CCBF`)

**Scanner**

Witness: L1 8 (p1-room30, rzx-p1-04000, rzx-p1-18000, rzx-p1-20000, rzx-p1-54000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/rzx-p1-04000` 3, `stage1/rec/rzx-p1-54000` 2, `stage1/rec/rzx-p1-20000` 1 and 2 more) |
| Called from | `MakeObject` |
| Writes | `$5E6C`-`$5EC3` (system) |

### `InitBonusPod` (`$CCE6`)

**Kind `$7D`, the bonus pod**

Witness: L1 6 (p1-speedup, p1-room30, rzx-p1-52000, rzx-p1-54000, rzx-p1-56000, rzx-p1-60000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rec/rzx-p1-54000` 1, `stage2/rec/p1-room30` 1, `docs/integrate/rec/p1-speedup` 1 and 3 more) |
| Called from | `MakeObject` |
| Reads | `$5EFF` (system) |
| Writes | `$5EFA`-`$5F04` (system) |

### `InitKind9` (`$CCF8`)

**Swing gun; also kinds 17-20 (the swing gun at four start angles)**

Witness: L1 98 (c1, p1-cursor, p1-kempston, p1-rooms238, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 10 calls, 1,925 t-states own (0.00 %) |
| Runs (the other recordings) | 88 calls (`stage2/rec/p1-room27` 9, `stage1/rec/rzx-p1-58000` 7, `stage1/rec/rzx-p1-60000` 6 and 23 more) |
| Called from | `MakeObject`, `InitKind17`, `InitKind18`, `InitKind19`, `InitKind20` |
| Reads | `$5E6F` (system); `$5E87` (system); `$5E9F` (system); `$5EB7` (system); `$5ECF` (system); `$5EE7` (system); 3 more ranges |
| Writes | `$5E6A`-`$5F3B` (system) |

### `InitKind17` (`$CD1A`)

**Kind 17: a swing gun at angle 1**

Witness: L1 21 (p1-rooms238, p1-speedup, p1-room26, p1-room27, p1-room30, rzx-p1- x13).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21 calls (`stage1/rec/rzx-p1-60000` 2, `stage1/rec/rzx-p1-48000` 2, `stage1/rec/rzx-p1-62000` 2 and 15 more) |
| Called from | `MakeObject` |
| Calls | `InitKind9` |
| Writes | `$5E87`-`$5EF0` (system) |

### `InitKind18` (`$CD2A`)

**Kind 18: angle 2**

Witness: L1 23 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, p1-room30, rzx-p1- x11).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 353 t-states own (0.00 %) |
| Runs (the other recordings) | 19 calls (`stage1/rec/rzx-p1-02000` 2, `stage2/rec/p1-room27` 2, `stage1/rec/rzx-p1-06000` 2 and 13 more) |
| Called from | `MakeObject` |
| Calls | `InitKind9` |
| Writes | `$5E6F`-`$5EA8` (system); `$5ECF`-`$5F20` (system) |

### `InitKind19` (`$CD3A`)

**Kind 19: angle 3**

Witness: L1 13 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, p1-room30, rzx-p1-00000, rzx-p1-02000, rzx-p1-12000, rzx-p1-58000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 calls, 280 t-states own (0.00 %) |
| Runs (the other recordings) | 10 calls (`stage2/rec/p1-room27` 2, `stage1/rec/rzx-p1-00000` 1, `stage1/rec/rzx-p1-02000` 1 and 6 more) |
| Called from | `MakeObject` |
| Calls | `InitKind9` |
| Writes | `$5E6F`-`$5E90` (system); `$5EB7`-`$5EC0` (system); `$5EFF`-`$5F08` (system) |

### `InitKind20` (`$CD4A`)

**Kind 20: angle 4**

Witness: L1 16 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, rzx-p1- x6).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 calls, 269 t-states own (0.00 %) |
| Runs (the other recordings) | 13 calls (`stage1/rec/rzx-p1-60000` 2, `stage1/rec/rzx-p1-62000` 2, `stage2/rec/p1-room27` 2 and 7 more) |
| Called from | `MakeObject` |
| Calls | `InitKind9` |
| Writes | `$5E87`-`$5ED8` (system); `$5EFF`-`$5F08` (system); `$5F2F`-`$5F38` (system) |

### `InitKind10` (`$CD5A`)

**Shooters**

Witness: L1 54 (c1, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x15).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 206 t-states own (0.00 %) |
| Runs (the other recordings) | 53 calls (`docs/integrate/rec/p1-speedup` 7, `stage1/rec/rzx-p1-60000` 6, `stage1/rec/rzx-p1-54000` 5 and 18 more) |
| Called from | `MakeObject` |
| Reads | `$5E6F` (system); `$5E87` (system); `$5E9F` (system); `$5EB7` (system); `$5ECF` (system); `$5EE7` (system) |
| Writes | `$5E6A`-`$5EF3` (system) |

### `InitKind11` (`$CD7C`)

**Launcher**

Witness: L1 41 (c1, p1-cursor, p1-define, p1-kempston, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x14).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 7 calls, 1,438 t-states own (0.00 %) |
| Runs (the other recordings) | 34 calls (`stage1/rec/rzx-p1-02000` 4, `stage2/rec/p1-cursor` 3, `stage1/rec/rzx-p1-10000` 3 and 19 more) |
| Called from | `MakeObject` |
| Reads | `$5E6F` (system); `$5E87` (system); `$5E9F` (system); `$5EB7` (system); `$5ECF` (system) |
| Writes | `$5E6A`-`$5EDB` (system) |

### `InitKind12` (`$CDA2`)

**Ramming pod; also the human's body**

Witness: L1 30 (p1-gameover, p1-shots, p1-speedup, rzx-p1- x13).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 30 calls (`stage1/rec/rzx-p1-16000` 5, `stage1/rec/rzx-p1-14000` 3, `stage1/rec/rzx-p1-20000` 3 and 13 more) |
| Called from | `MakeObject` |
| Writes | `$5E6C`-`$5F22` (system); `$5F44`-`$5F52` (system) |

### `InitKind13` (`$CDB9`)

**Mine layer**

Witness: L1 12 (p1-room30, rzx-p1- x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 calls (`stage1/rec/rzx-p1-62000` 3, `stage1/rec/rzx-p1-18000` 3, `stage1/rec/rzx-p1-20000` 1 and 5 more) |
| Called from | `MakeObject` |
| Writes | `$5E6C`-`$5EAB` (system); `$5ECC`-`$5EF3` (system); `$5F2C`-`$5F3B` (system) |

### `InitKind14` (`$CDD8`)

**Mine**

Witness: L1 164 (p1-code, p1-speedup, p1-room30, rzx-p1- x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 164 calls (`stage1/rec/rzx-p1-62000` 44, `stage2/rec/p1-code` 33, `stage1/rec/rzx-p1-30000` 15 and 10 more) |
| Called from | `DropMine` |
| Writes | `$5E6A`-`$5F9D` (system) |

### `InitKind15` (`$CE13`)

**Blob**

Witness: L1 49 (p1-rooms238, p1-room14, p1-room24, p1-room26, rzx-p1- x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 49 calls (`stage1/rec/rzx-p1-04000` 6, `stage1/rec/rzx-p1-20000` 6, `stage1/rec/rzx-p1-06000` 6 and 7 more) |
| Called from | `MakeObject` |
| Writes | `$5E6A`-`$5F3B` (system) |

### `InitKind16` (`$CE3E`)

**The big gun: kind `$90` (bit 7 set), speed IX+`$12` = 2, 6 x 48, hits Weapon x 50 + 16**

Witness: L1 1 (rzx-p1-22000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/rzx-p1-22000` 1) |
| Called from | `MakeObject` |
| Calls | `KillHumanPicture` |
| Reads | `$5E6F` (system) |
| Writes | `$5E6A`-`$5E7B` (system) |

### `KillHumanPicture` (`$CE67`)

**The big gun's hits by the weapon held (Weapon x 50 + 16) into IX+`$14` and HumanPicture `$A022` (written, never read)**

Witness: L1 2 (rzx-p1-22000, rzx-p1-24000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/rzx-p1-22000` 1, `stage1/rec/rzx-p1-24000` 1) |
| Called from | `KillHuman`, `InitKind16` |
| Calls | `Multiply` |
| Reads | `$A013` (`Weapon`) |
| Writes | `$5E7A` (system); `$A022` (`HumanPicture`) |

## panels

`src/game/panels.asm`

### `PanelBox` (`$CE7B`)

**Draw a framed box: A attribute, D width, E height, H column, L line, C the frame's colour; the frame from the font's edge characters**

Witness: L1 52 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 14 calls, 12,241 t-states own (0.00 %) |
| Runs (the other recordings) | 38 calls (`docs/rxA/rec/menu-rollcall` 10, `stage2/rec/p1-cursor` 5, `stage2/rec/p1-define` 4 and 11 more) |
| Called from | `PrintBoxed` |
| Calls | `PanelRow`, `FillAttrs` |
| Reads | `$A028`-`$A02B` (`BoxX`, `BoxY`, `BoxWidth`, `BoxHeight`); `$A093`-`$A09F` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 1 more) |
| Writes | `$A028`-`$A02B` (`BoxX`, `BoxY`, `BoxWidth`, `BoxHeight`); `$A093`-`$A09F` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 1 more) |

### `PanelRow` (`$CF0A`)

**8 lines of a box row**

Witness: L1 209 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 61 calls, 64,331 t-states own (0.00 %) |
| Runs (the other recordings) | 148 calls (`docs/rxA/rec/menu-rollcall` 40, `stage2/rec/p1-cursor` 21, `stage2/rec/p1-define` 20 and 11 more) |
| Called from | `PanelBox` |
| Calls | `PanelLine` |
| Reads | `$A028` (`BoxX`); `$ABED`-`$AD5C` (`ScreenLineTable+16`, `ScreenLines`) |

### `PanelLine` (`$CF21`)

**One pixel line: the left edge, the middle B times, the right edge**

Witness: L1 1672 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 488 calls, 347,088 t-states own (0.02 %) |
| Runs (the other recordings) | 1,184 calls (`docs/rxA/rec/menu-rollcall` 320, `stage2/rec/p1-cursor` 168, `stage2/rec/p1-define` 160 and 11 more) |
| Called from | `PanelRow` |
| Reads | `$6120`-`$6147` (`Font+64`); `$6158`-`$615F` (`Font+120`); `$61B8`-`$61CF` (`Font+216`); `$A02A` (`BoxWidth`) |
| Writes | `$4022`-`$57FF` (screen) |

### `FillShadowRow3` (`$CF3D`)

**Three rows of three: the cells of value `$47` (white) take C**

Witness: L1 4835 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 600 calls, 43,551 t-states own (0.00 %) |
| Runs (the other recordings) | 4,235 calls (`stage2/rec/p1-gameover` 508, `stage1/rec/rzx-p1-62000` 256, `stage1/rec/rzx-p1-20000` 205 and 39 more) |
| Called from | `FlashCells` |
| Calls | `FillShadowCells` |

### `FillShadowCells` (`$CF47`)

**One row of three cells**

Witness: L1 14505 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,800 calls, 400,829 t-states own (0.03 %) |
| Runs (the other recordings) | 12,705 calls (`stage2/rec/p1-gameover` 1,524, `stage1/rec/rzx-p1-62000` 768, `stage1/rec/rzx-p1-20000` 615 and 39 more) |
| Called from | `FillShadowRow3` |
| Reads | `$E543`-`$E7F5` (`SweepAttrs+24`, `AttrShadowPlay`) |
| Writes | `$5864`-`$5AD0` (screen); `$5AE7`-`$5AF0` (screen) |

### `CopyCells3` (`$CF6E`)

**Copy a 3 x 3 patch from DE to HL (the shadow's 32-byte rows)**

Witness: L1 603 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 75 calls, 7,595 t-states own (0.00 %) |
| Runs (the other recordings) | 528 calls (`stage2/rec/p1-gameover` 64, `stage1/rec/rzx-p1-62000` 32, `stage1/rec/rzx-p1-20000` 26 and 39 more) |
| Called from | `DeathAnimation`, `BlowUp` |
| Calls | `CopyCells` |

### `CopyCells` (`$CF7D`)

**One row of three**

Witness: L1 1809 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 225 calls, 29,446 t-states own (0.00 %) |
| Runs (the other recordings) | 1,584 calls (`stage2/rec/p1-gameover` 192, `stage1/rec/rzx-p1-62000` 96, `stage1/rec/rzx-p1-20000` 78 and 39 more) |
| Called from | `CopyCells3` |
| Reads | `$E543`-`$E7F5` (`SweepAttrs+24`, `AttrShadowPlay`) |
| Writes | `$5844`-`$5AF6` (screen) |

### `SaveAttrs` (`$CF8F`)

**The screen's top 96 attributes (`$5800`) into the shadow at `$E4FF`**

Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000, rzx-p1-64000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 calls, 4,448 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage2/rec/p1-cursor` 2, `stage1/rec/rzx-p1-64000` 1, `stage2/rec/p1-code` 1 and 3 more) |
| Called from | `NewGame` |
| Reads | `$5800`-`$585F` (screen) |
| Writes | `$E4FF`-`$E55E` (`TitleScreen`, `ShieldAttrs`, `SweepAttrs`) |

### `FlashCells` (`$CF9B`)

**The explosion's attribute flash: the object's 3 x 3 cells in the shadow coloured from FlashAttrs `$BFE7` at random**

Witness: L1 4835 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 600 calls, 154,417 t-states own (0.01 %) |
| Runs (the other recordings) | 4,235 calls (`stage2/rec/p1-gameover` 508, `stage1/rec/rzx-p1-62000` 256, `stage1/rec/rzx-p1-20000` 205 and 39 more) |
| Called from | `DeathAnimation`, `BlowUp` |
| Calls | `BufferAddress`, `FillShadowRow3` |
| Reads | `$A093`-`$A096` (`Temp1`, `Temp2`); `$BFE7`-`$BFEE` (`FlashAttrs`) |
| Writes | `$A093`-`$A096` (`Temp1`, `Temp2`) |

### `FindFreeObject` (`$D858`)

**IX = the first dead object record; none: IX = `$03E8`**

Witness: L1 169 (p1-code, p1-speedup, p1-room30, rzx-p1- x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 169 calls (`stage1/rec/rzx-p1-62000` 44, `stage2/rec/p1-code` 33, `stage1/rec/rzx-p1-30000` 15 and 10 more) |
| Called from | `KillHuman`, `DropMine` |
| Reads | `$5E72`-`$5EEA` (system); `$5F02` (system); `$5F1A` (system); `$5F32` (system); `$5F4A` (system); `$5F62` (system); 3 more ranges |

### `WeaponPanel` (`$D871`)

**A weapon station's panel (HL: the flag then the text), once a game: the screen saved, the panel, wait for fire, the screen back**

Witness: L1 95 (rzx-p1- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 95 calls (`stage1/rec/rzx-p1-10000` 31, `stage1/rec/rzx-p1-18000` 23, `stage1/rec/rzx-p1-00000` 11 and 5 more) |
| Called from | `CellsUnderRex`, `StationSpray` |
| Calls | `WaitFireOrAttract`, `PrintBoxed`, `BufferToScreen`, `CopyAttrs`, `Delay`, `SoundReset`, `SoundSilence`, `SaveScreen` |
| Reads | `$ABA0`-`$ABCB` (`DoubleFireText`, `LaserText`, `MultipleText`, `SprayText`) |
| Writes | `$ABA0` (`DoubleFireText`); `$ABB1`-`$ABCA` (`LaserText`, `MultipleText`, `SprayText`) |

### `SaveScreen` (`$D8A3`)

**The screen's play lines into the back buffer (the panels draw over the screen; BufferToScreen puts it back)**

Witness: L1 7 (p1-speedup, rzx-p1- x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage1/rec/rzx-p1-26000` 1, `stage1/rec/rzx-p1-18000` 1, `stage1/rec/rzx-p1-00000` 1 and 4 more) |
| Called from | `BonusRoulette`, `WeaponPanel` |
| Reads | `$4060`-`$57FF` (screen); `$AC0D`-`$AD5C` (`ScreenLines`) |
| Writes | `$EAFF`-`$FFFE` (`BufferPlayOrigin`, `work space $FFFA+`) |

### `DrawCharBlock` (`$D8C0`)

**Draw a picture straight on the screen from the 6 bytes after the CALL: picture word, column, line, width, height; returns after them**

Witness: L1 1326 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30, rzx-p1- x14).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 183 calls, 649,968 t-states own (0.04 %) |
| Runs (the other recordings) | 1,143 calls (`docs/rxA/rec/menu-rollcall` 522, `stage1/rec/rzx-p1-10000` 155, `stage1/rec/rzx-p1-18000` 115 and 17 more) |
| Called from | `DrawHudIcon`, `DrawWeaponIcon`, `RollCallSprite` |
| Calls | `NextHudIcon`, `NextWeaponIcon`, `RollCallFrame` |
| Reads | `$8C0A`-`$8CE9` (`SpriteHudIcons`, `SpriteHudIcons2`); `$8E4A`-`$8E89` (`SpriteKind11`, `SpriteKind10`); `$8EAA`-`$8F49` (`SpriteSwingGun`); `$A093`-`$A096` (`Temp1`, `Temp2`); `$A1F1`-`$A1F6` (`HudIconParams`); `$A233`-`$A238` (`WeaponIconParams`); 4 more ranges |
| Writes | `$4001`-`$4064` (screen); `$4101`-`$4164` (screen); `$4201`-`$4264` (screen); `$4301`-`$4364` (screen); `$4401`-`$4464` (screen); `$4501`-`$4564` (screen); 3 more ranges |

### `FillAttrs` (`$D909`)

**Fill B rows of E attributes from HL with A**

Witness: L1 140 (c1, menu-rollcall, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 36 calls, 61,028 t-states own (0.00 %) |
| Runs (the other recordings) | 104 calls (`docs/rxA/rec/menu-rollcall` 30, `stage2/rec/p1-cursor` 15, `stage2/rec/p1-define` 11 and 11 more) |
| Called from | `DrawHud`, `PanelBox`, `ShowTitle` |
| Reads | `$A093`-`$A095` (`Temp1`, `Temp2`) |
| Writes | `$5800`-`$58EE` (screen); `$5904`-`$590E` (screen); `$5924`-`$5AFF` (screen); `$A093`-`$A095` (`Temp1`, `Temp2`) |

## rexmove

`src/game/rexmove.asm`

### `SpeedUpTick` (`$CFCC`)

**The SPEED UP bonus: count down; the speed back at the end**

SpeedUpPhase `$A073` starts at 200 (PrizeSpeedUp) and counts the walking passes; at 0 SpeedUp ends. Run by p1-speedup: the roulette stopped on SPEED UP by fire, SpeedUpPhase 200 at frame 1740 down to 0 at 2740, RexSpeed 4 / -4 meanwhile, 2 / -2 after.

Witness: L1 200 (p1-speedup).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 200 calls (`docs/integrate/rec/p1-speedup` 200) |
| Called from | `WalkRightKey`, `WalkLeftKey` |
| Reads | `$A073` (`SpeedUpPhase`) |
| Writes | `$A072`-`$A073` (`SpeedUp`, `SpeedUpPhase`) |

### `WalkRightKey` (`$CFDA`)

**Right: facing right, the speed set**

Witness: L1 4760 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 300 calls, 22,600 t-states own (0.00 %) |
| Runs (the other recordings) | 4,460 calls (`docs/integrate/rec/p1-speedup` 368, `stage1/rec/rzx-p1-12000` 291, `stage1/rec/rzx-p1-10000` 228 and 40 more) |
| Called from | `MainLoop` |
| Calls | `SpeedUpTick` |
| Reads | `$A072` (`SpeedUp`) |
| Writes | `$A091` (`RexSpeed`); `$A0BB` (`RexFacing`) |

### `WalkLeftKey` (`$CFF6`)

**Left: facing left, the speed set**

Witness: L1 4294 (c1, p1-code, p1-cursor, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 328 t-states own (0.00 %) |
| Runs (the other recordings) | 4,290 calls (`stage1/rec/rzx-p1-28000` 252, `stage1/rec/rzx-p1-48000` 246, `stage1/rec/rzx-p1-60000` 221 and 37 more) |
| Called from | `MainLoop` |
| Calls | `SpeedUpTick` |
| Reads | `$A072` (`SpeedUp`) |
| Writes | `$A091` (`RexSpeed`); `$A0BB` (`RexFacing`) |

### `RexWalk` (`$D013`)

**Move Rex by RexSpeed in his facing unless a solid cell; at the edges ExitLeft / ExitRight**

Witness: L1 16675 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 calls, 102,121 t-states own (0.01 %) |
| Runs (the other recordings) | 16,319 calls (`docs/integrate/rec/p1-speedup` 684, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 474 and 43 more) |
| Called from | `MainLoop` |
| Calls | `IsSolid`, `ExitLeft` (tail), `ExitRight` (tail) |
| Reads | `$A019`-`$A01A` (`RexCellPtr`); `$A091` (`RexSpeed`); `$A0B6`-`$A0BD` (`RexX`, `RexY`, `Room`, `RoomColumn` and 3 more) |
| Writes | `$A091` (`RexSpeed`); `$A0B6` (`RexX`) |

### `IsSolid` (`$D06C`)

**Z if the cell at HL is solid (SolidCells' first 4: 2, 4, 5, 6)**

Witness: L1 111966 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,572 calls, 78,748 t-states own (0.01 %) |
| Runs (the other recordings) | 110,394 calls (`stage1/rec/rzx-p1-62000` 5,470, `stage1/rec/rzx-p1-32000` 5,205, `docs/integrate/rec/p1-speedup` 5,029 and 43 more) |
| Called from | `Climb`, `DriftObject`, `ScannerTurn`, `WalkRight`, `WalkLeft`, `ObjectJump`, `RexWalk`, `RexJump` |
| Calls | `InList` (falls into) |
| Reads | `$E1C3`-`$E4DA` (`RoomGrid+36`, `RoomGridPlay`, `ExplosionPicture`) |

### `InList` (`$D074`)

**Z if A is one of B values at DE**

Witness: L1 262708 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3,925 calls, 781,112 t-states own (0.05 %) |
| Runs (the other recordings) | 258,783 calls (`docs/integrate/rec/p1-speedup` 11,902, `stage1/rec/rzx-p1-62000` 10,516, `stage1/rec/rzx-p1-46000` 9,901 and 43 more) |
| Called from | `IsSolid` (falls into), `IsPassable` (tail) |
| Reads | `$D096`-`$D09F` (`SolidCells`, `PassCells`) |

### `IsPassable` (`$D08B`)

**Z if the cell at HL lets a body or a bullet through: empty (0) or one of `$0E-$12` (PassCells `$D09A`)**

Witness: L1 150742 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,353 calls, 138,594 t-states own (0.01 %) |
| Runs (the other recordings) | 148,389 calls (`docs/integrate/rec/p1-speedup` 6,873, `stage1/rec/rzx-p1-46000` 6,784, `stage1/rec/rzx-p1-24000` 6,208 and 43 more) |
| Called from | `StepShot`, `ObjectFall`, `FindGround`, `RexFall` |
| Calls | `InList` (tail) |
| Reads | `$E200`-`$E4F9` (`RoomGridPlay+1`, `ExplosionPicture`) |

### `ExitLeft` (`$D0A0`)

**Rex at the left edge: to the room RoomLeft `$A090` at X `$E8`**

Witness: L1 161 (p1-speedup, p1-room14, p1-room26, p1-room27, rzx-p1- x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 161 calls (`docs/integrate/rec/p1-speedup` 79, `stage2/rec/p1-room14` 67, `stage1/rec/rzx-p1-48000` 2 and 13 more) |
| Called from | `RexWalk` (tail) |
| Calls | `ChangeRoom` (tail) |
| Reads | `$A090` (`RoomLeft`) |
| Writes | `$A0B6`-`$A0B8` (`RexX`, `RexY`, `Room`) |

### `ExitRight` (`$D0B1`)

**Rex at the right edge: to the room RoomRight `$A08D` at X `$08`**

Witness: L1 298 (c1, p1-cursor, p1-kempston, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room26, p1-room27, rzx-p1- x14).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 calls, 225 t-states own (0.00 %) |
| Runs (the other recordings) | 295 calls (`stage2/rec/p1-room27` 72, `stage2/rec/p1-room26` 66, `stage1/rec/rzx-p1-26000` 64 and 19 more) |
| Called from | `RexWalk` (tail) |
| Calls | `ChangeRoom` (tail) |
| Reads | `$A08D` (`RoomRight`) |
| Writes | `$A0B6`-`$A0B8` (`RexX`, `RexY`, `Room`) |

### `StartJump` (`$D0C2`)

**Up: a jump if Rex stands (not jumping or falling)**

Witness: L1 2080 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-speedup, p1-room14, p1-room26, p1-room27, p1-room30, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 28 calls, 1,538 t-states own (0.00 %) |
| Runs (the other recordings) | 2,052 calls (`stage1/rec/rzx-p1-28000` 116, `stage1/rec/rzx-p1-52000` 95, `stage1/rec/rzx-p1-30000` 92 and 38 more) |
| Called from | `MainLoop`, `CellsUnderRex` |
| Reads | `$A0BC`-`$A0BD` (`FallSpeed`, `Jumping`) |
| Writes | `$A0BD`-`$A0C1` (`Jumping`, `JumpPtr`) |

### `RexJump` (`$D0E4`)

**One step of the jump: up by JumpSteps unless a solid cell above; off the top ExitUp**

Witness: L1 16687 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 calls, 17,008 t-states own (0.00 %) |
| Runs (the other recordings) | 16,331 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 474 and 43 more) |
| Called from | `MainLoop` |
| Calls | `IsSolid`, `Land` (tail), `ExitTop` (tail) |
| Reads | `$A019`-`$A01A` (`RexCellPtr`); `$A08E` (`RoomUp`); `$A0B7`-`$A0C1` (`RexY`, `Room`, `RoomColumn`, `RexFacing` and 3 more); `$D0D8`-`$D0E2` (`JumpSteps`) |
| Writes | `$A0B7`-`$A0C1` (`RexY`, `Room`, `RoomColumn`, `RexFacing` and 3 more) |

### `Land` (`$D11A`)

**Stop the jump and the fall; Rex on the cell's top**

Witness: L1 150 (p1-code, p1-speedup, p1-room14, p1-room26, p1-room27, p1-room30, rzx-p1- x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 96 calls (`stage1/rec/rzx-p1-54000` 22, `stage2/rec/p1-room30` 14, `docs/integrate/rec/p1-speedup` 12 and 6 more) |
| Called from | `CellsUnderRex`, `RexJump` (tail) |
| Reads | `$A0B7` (`RexY`) |
| Writes | `$A0BC`-`$A0BD` (`FallSpeed`, `Jumping`) |

### `ExitTop` (`$D12F`)

**Rex off the top: to the room RoomUp `$A08E` at the bottom**

Witness: L1 17 (p1-code, p1-speedup, p1-room30, rzx-p1- x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 calls (`stage1/rec/rzx-p1-54000` 2, `stage2/rec/p1-room30` 2, `docs/integrate/rec/p1-speedup` 2 and 5 more) |
| Called from | `RexJump` (tail) |
| Calls | `ChangeRoom` (tail) |
| Reads | `$A08E` (`RoomUp`) |
| Writes | `$A0B7`-`$A0BD` (`RexY`, `Room`, `RoomColumn`, `RexFacing` and 2 more) |

### `RexFall` (`$D14D`)

**Rex falls when no floor is under him; off the bottom to RoomDown `$A08F`, or death with no exit**

Witness: L1 16675 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 calls, 82,062 t-states own (0.01 %) |
| Runs (the other recordings) | 16,319 calls (`docs/integrate/rec/p1-speedup` 684, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 474 and 43 more) |
| Called from | `MainLoop` |
| Calls | `RexDies`, `CellPointer`, `ChangeRoom` (tail), `IsPassable` |
| Reads | `$A08F` (`RoomDown`); `$A0B6`-`$A0BD` (`RexX`, `RexY`, `Room`, `RoomColumn` and 3 more); `$E22F`-`$E236` (`RoomGridPlay+48`); `$E24B`-`$E4F9` (`RoomGridPlay+76`, `ExplosionPicture`) |
| Writes | `$A0AF`-`$A0BD` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight` and 8 more) |

## collisions

`src/game/collisions.asm`

### `EnemyBulletsHitRex` (`$D1B9`)

**Each enemy bullet in Rex's box: the shield takes it (faster drain), else Rex dies**

Witness: L1 18613 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 calls, 742,204 t-states own (0.05 %) |
| Runs (the other recordings) | 17,911 calls (`docs/integrate/rec/p1-speedup` 685, `docs/integrate/rec/p1-poke41241` 670, `stage1/rec/rzx-p1-18000` 520 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `ShieldDrainFast`, `RexDies` |
| Reads | `$5D22`-`$6CFA` (`DevLinkStub`, `Unused607E`, `Font`, `CharFlags` and 3 more); `$A049`-`$A060` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate` and 17 more); `$A0B6`-`$A0B7` (`RexX`, `RexY`) |
| Writes | `$5D28`-`$5DAF` (system); `$5DCD` (system); `$5DFA`-`$5E09` (system) |

### `ObjectHitsRex` (`$D215`)

**The object at IX against Rex: its box (written into the compares at `$D28E`, `$D29E`, `$D299`, `$D310`, `$D321` by kind); the shield kills it, else Rex dies; pods are taken; then Rex's bullets against it**

Witness: L1 82130 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,003 calls, 545,695 t-states own (0.04 %) |
| Runs (the other recordings) | 80,127 calls (`docs/integrate/rec/p1-speedup` 4,275, `stage1/rec/rzx-p1-58000` 3,205, `stage1/rec/rzx-p1-20000` 3,040 and 43 more) |
| Called from | `ObjectCollide` |
| Calls | `KillObject`, `ShieldDrainFast`, `RexDies`, `BulletsHitObject` (tail), `TakePowerPod`, `TakeBombPod`, `BonusRoulette` |
| Reads | `$5B60`-`$6BDD` (`DevLinkStub`, `Unused607E`, `Font`, `CharFlags` and 1 more); `$A013` (`Weapon`); `$A049`-`$A060` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate` and 17 more); `$A0B6`-`$A0B7` (`RexX`, `RexY`); `$D842` (`Channels+16`) |
| Writes | `$5B66`-`$5D0A` (system); `$5D28` (system); `$5D55` (system); `$5DAF` (system); `$5E76`-`$5EC2` (system); `$5EDA`-`$5F22` (system); 10 more ranges |

### `BulletsHitObject` (`$D2F6`)

**Rex's 30 bullets against the object at IX: a hit object takes damage (HitObject, HitObjectHard) or is killed**

Witness: L1 76882 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,538 calls, 3,567,124 t-states own (0.25 %) |
| Runs (the other recordings) | 2,149 calls (`stage1/rec/rzx-p1-24000` 957, `stage2/rec/p1-cursor` 388, `stage2/rec/p1-room24` 344 and 2 more) |
| Called from | `ObjectHitsRex` (tail) |
| Calls | `BulletLoop` (falls into) |
| Reads | `$5B60`-`$6BCE` (`DevLinkStub`, `Unused607E`, `Font`, `CharFlags` and 1 more); `$A013` (`Weapon`); `$D842` (`Channels+16`) |
| Writes | `$5B66`-`$5D0A` (system); `$5E7A` (system); `$5E92` (system); `$5EAA` (system); `$5EC2` (system); `$5EDA` (system); 3 more ranges |

### `BulletLoop` (`$D2FC`)

**BulletLoop**

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 46,140 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 299,150 calls (`stage1/rec/rzx-p1-06000` 89,649, `stage2/rec/p1-room14` 44,790, `stage2/rec/p1-room26` 42,090 and 7 more) |
| Called from | `BulletsHitObject` (falls into), `NextBullet` (tail) |
| Calls | `KillObject`, `NextBullet` (tail), `HitNotLast` (tail), `HitObject`, `HitObjectHard`, `StartSfx` |
| Reads | `$5B60`-`$6ACF` (`DevLinkStub`, `Unused607E`, `Font`, `CharFlags` and 1 more); `$A013` (`Weapon`); `$D842` (`Channels+16`) |
| Writes | `$5B66`-`$5C47` (system); `$5E7A` (system); `$5E92` (system); `$5EAA` (system); `$5EC2` (system); `$5EDA` (system); 2 more ranges |

### `NextBullet` (`$D3A7`)

**The next bullet record**

Witness: L1 2344896 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 46,140 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 296,562 calls (`stage1/rec/rzx-p1-06000` 89,642, `stage2/rec/p1-room14` 44,790, `stage2/rec/p1-room26` 42,090 and 6 more) |
| Called from | `BulletLoop` (tail), `HitNotLast` (tail) |
| Calls | `BulletLoop` (tail) |

### `HitNotLast` (`$D3B1`)

**A hit that is not the object's last: a kind 8 pauses (its timer IX+`$10` = 4); then the next bullet**

Witness: L1 951 (c1, p1-code, p1-gameover, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 30 calls (`stage1/rec/rzx-p1-06000` 18, `stage1/rec/rzx-p1-40000` 12) |
| Called from | `BulletLoop` (tail) |
| Calls | `NextBullet` (tail) |
| Reads | `$5E6F` (system); `$5E87` (system); `$5E9F` (system); `$5EB7` (system); `$5ECF` (system); `$5EE7` (system); 1 more ranges |

### `HitObject` (`$D3C2`)

**A hit: the flash picture SpriteHitFlash `$8632`, the combo score (ComboCount `$A03B`; none for the spray, Weapon 4), the object killed after its hits (the laser, Weapon 2, kills at once)**

Witness: L1 76 (p1-speedup, p1-room30, rzx-p1- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 76 calls (`stage1/rec/rzx-p1-38000` 10, `stage1/rec/rzx-p1-46000` 8, `stage1/rec/rzx-p1-58000` 6 and 19 more) |
| Called from | `BulletLoop` |
| Calls | `KillObject` (tail), `AddScore`, `StartFall` |
| Reads | `$5E68` (system); `$5E80` (system); `$5E98` (system); `$5EB0` (system); `$5EC8` (system); `$5EE0` (system); 9 more ranges |
| Writes | `$5E68`-`$5F85` (system); `$5FA0`-`$5FCD` (system); `$A039`-`$A03D` (`KillFlashPtr`, `ComboCount`, `ComboTimer`) |

### `HitObjectHard` (`$D41F`)

**A bullet on a kind 6 (the hit foot man): the flash renewed, hits back to 2 (not with the spray); BulletLoop then skips it, so a kind 6 never loses hits**

Witness: L1 90 (p1-speedup, p1-room30, rzx-p1- x13).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 90 calls (`stage1/rec/rzx-p1-28000` 29, `stage1/rec/rzx-p1-32000` 22, `stage1/rec/rzx-p1-46000` 10 and 12 more) |
| Called from | `BulletLoop` |
| Calls | `AddScore` |
| Reads | `$A013` (`Weapon`); `$A039`-`$A03D` (`KillFlashPtr`, `ComboCount`, `ComboTimer`) |
| Writes | `$5E6F`-`$5EAD` (system); `$5ECF`-`$5EDD` (system); `$5FA7`-`$5FB5` (system); `$A039`-`$A03D` (`KillFlashPtr`, `ComboCount`, `ComboTimer`) |

### `TakePowerPod` (`$D46C`)

**The power pod (`$FE`): PowerGain twice if it is a big one, the pod sound**

Witness: L1 139 (p1-speedup, p1-room30, rzx-p1- x27).

[Animation: `TakePowerPod` at work](img/routines/TakePowerPod.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 139 calls (`stage1/rec/rzx-p1-58000` 10, `stage1/rec/rzx-p1-34000` 9, `stage1/rec/rzx-p1-42000` 9 and 26 more) |
| Called from | `ObjectHitsRex` |
| Calls | `PowerGain`, `StartSfx` |
| Reads | `$5E7B` (system); `$5E93` (system); `$5EAB` (system); `$5EC3` (system); `$5EDB` (system); `$5EF3` (system); 4 more ranges |
| Writes | `$5E72` (system); `$5E8A` (system); `$5EA2` (system); `$5EBA` (system); `$5ED2` (system); `$5EEA` (system); 5 more ranges |

### `TakeBombPod` (`$D494`)

**The bomb pod (`$FD`): Bombs + 1 up to 3, the HUD, the sound**

Witness: L1 3 (p1-room30, rzx-p1-52000, rzx-p1-54000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/rzx-p1-54000` 1, `stage2/rec/p1-room30` 1, `stage1/rec/rzx-p1-52000` 1) |
| Called from | `ObjectHitsRex` |
| Calls | `ShowBombs`, `StartSfx` |
| Reads | `$A06C` (`Bombs`) |
| Writes | `$5F02` (system); `$5F1A` (system); `$A06C` (`Bombs`) |

### `BonusRoulette` (`$D4B6`)

**The bonus pod (`$FC`): a panel cycles through the five prizes until fire (or it slows to a stop); the prize given**

SPEED UP (`$A072` = 1, 200 passes), SHIELD LOSS (drain 20), 1000 BONUS (AddScore 10), ENERGY LOSS (LosePower, the HUD), 100 RAPID SHOTS (`$A040` = 1, `$A041` = 100). The screen is saved first (SaveScreen `$D8A3`) and restored after.

Witness: L1 3 (p1-speedup, rzx-p1-50000, rzx-p1-56000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/rzx-p1-56000` 1, `docs/integrate/rec/p1-speedup` 1, `stage1/rec/rzx-p1-50000` 1) |
| Called from | `ObjectHitsRex` |
| Calls | `AddScore`, `PrintBoxed`, `BufferToScreen`, `PrintText`, `Random`, `ReadFire`, `CopyAttrs`, `Delay`, `SoundReset`, `SoundSilence`, `SaveScreen` |
| Reads | `$A06F`-`$A07E` (`BonusRoll`, `Immune`, `SpeedUp`, `SpeedUpPhase` and 5 more); `$D4B2`-`$D4B3` (`BonusTextTable+6`) |
| Writes | `$5EA2` (system); `$5F02` (system); `$A040`-`$A041` (`RapidShotsOn`, `RapidShotsLeft`); `$A06F`-`$A07E` (`BonusRoll`, `Immune`, `SpeedUp`, `SpeedUpPhase` and 5 more) |

### `ExtraLife` (`$D5A0`)

**Lives + 1 up to 9, ShowLives**

Witness: L1 10 (p1-code, rzx-p1- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`stage1/rec/rzx-p1-20000` 1, `stage1/rec/rzx-p1-28000` 1, `stage2/rec/p1-code` 1 and 7 more) |
| Called from | `AddScore` |
| Calls | `ShowLives` |
| Reads | `$A063` (`Lives`) |
| Writes | `$A063` (`Lives`) |

## sound

`src/game/sound.asm`

### `SoundReset` (`$D5AE`)

**The channels free, the mixer `$38` (tones on, noise off), silence**

Witness: L1 84 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 6 calls, 4,690 t-states own (0.00 %) |
| Runs (the other recordings) | 78 calls (`stage2/rec/p1-cursor` 8, `stage1/rec/rzx-p1-00000` 6, `docs/integrate/rec/p1-speedup` 4 and 38 more) |
| Called from | `NewGame`, `WaitFireOrAttract`, `WaitFire`, `Pause`, `DrawRoom`, `BonusRoulette`, `WeaponPanel` |
| Calls | `SoundSilence`, `WriteMixer` |
| Reads | `$D832`-`$D84E` (`Channels`) |
| Writes | `$D832`-`$D855` (`Channels`, `Mixer`) |

### `SoundSilence` (`$D5D7`)

**The three volumes (registers 8-10) to 0**

Witness: L1 52036 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 31,160 calls, 2,996,969 t-states own (0.21 %) |
| Runs (the other recordings) | 20,876 calls (`stage2/rec/p1-cursor` 20,738, `stage1/rec/rzx-p1-00000` 11, `docs/integrate/rec/p1-speedup` 8 and 39 more) |
| Called from | `WaitFireOrAttract`, `WaitFire`, `Pause`, `DrawRoom`, `BonusRoulette`, `SoundReset`, `WeaponPanel` |
| Calls | `SoundWrite` |

### `StartSfx` (`$D5E7`)

**Start the effect at DE (saves IX, IY, BC)**

Witness: L1 15747 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 189 calls, 28,192 t-states own (0.00 %) |
| Runs (the other recordings) | 15,558 calls (`stage1/rec/rzx-p1-46000` 798, `stage1/rec/rzx-p1-36000` 794, `stage1/rec/rzx-p1-62000` 764 and 43 more) |
| Called from | `DrawRex`, `KillObject`, `DeathAnimation`, `SaveRestart`, `Materialise`, `Dematerialise`, `Recharge`, `FindSlot`, `EnemyShotSound`, `ShotStopped`, `BulletLoop`, `TakePowerPod`, `TakeBombPod` |
| Calls | `StartSfxIY` |

### `StartSfxIY` (`$D5F8`)

**The descriptor at IY into its channel; the mixer bits for tone and noise**

Witness: L1 15747 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 189 calls, 107,666 t-states own (0.01 %) |
| Runs (the other recordings) | 15,558 calls (`stage1/rec/rzx-p1-46000` 798, `stage1/rec/rzx-p1-36000` 794, `stage1/rec/rzx-p1-62000` 764 and 43 more) |
| Called from | `StartSfx` |
| Calls | `WriteMixer` |
| Reads | `$D763`-`$D80B` (`SfxGun`, `SfxEnemyShot`, `SfxLaser`, `SfxSpray` and 10 more); `$D826`-`$D82C` (`SfxRecharge`); `$D855` (`Mixer`) |
| Writes | `$D832`-`$D855` (`Channels`, `Mixer`) |

### `WriteMixer` (`$D682`)

**Register 7 = the mixer `$D855`**

Witness: L1 15831 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 195 calls, 10,884 t-states own (0.00 %) |
| Runs (the other recordings) | 15,636 calls (`stage1/rec/rzx-p1-46000` 799, `stage1/rec/rzx-p1-36000` 795, `stage1/rec/rzx-p1-62000` 764 and 44 more) |
| Called from | `SoundReset`, `StartSfxIY` |
| Calls | `SoundWrite` |
| Reads | `$D855` (`Mixer`) |

### `SoundStep` (`$D68C`)

**Each of the 3 channels: ChannelStep, then its tone (registers 0-5) or noise period (6)**

Witness: L1 37230 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

[Animation: `SoundStep` at work](img/routines/SoundStep.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,405 calls, 1,111,852 t-states own (0.08 %) |
| Runs (the other recordings) | 35,825 calls (`docs/integrate/rec/p1-speedup` 1,370, `docs/integrate/rec/p1-poke41241` 1,340, `stage1/rec/rzx-p1-18000` 1,040 and 43 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `ChannelStep`, `SoundWrite` |
| Reads | `$D832`-`$D857` (`Channels`, `Mixer`, `ChannelNumber`) |
| Writes | `$D857` (`ChannelNumber`) |

### `ChannelStep` (`$D6DB`)

**One step of the channel at IX: the volume written, the tone and volume changed, the next step; at the end the channel silent and free**

Witness: L1 113930 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4,215 calls, 747,333 t-states own (0.05 %) |
| Runs (the other recordings) | 107,475 calls (`docs/integrate/rec/p1-speedup` 4,110, `docs/integrate/rec/p1-poke41241` 4,020, `stage1/rec/rzx-p1-18000` 3,120 and 43 more) |
| Called from | `SoundStep` |
| Calls | `WriteVolume`, `SoundWrite` |
| Reads | `$D76A`-`$D7A4` (`SfxGun+7`, `SfxEnemyShot`, `SfxLaser`, `SfxSpray` and 4 more); `$D7B5`-`$D857` (`SfxMaterialise+7`, `Channels`) |
| Writes | `$D832`-`$D849` (`Channels`) |

### `WriteVolume` (`$D744`)

**Register 8 + channel = the channel's volume / 16**

Witness: L1 48180 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,782 calls, 188,520 t-states own (0.01 %) |
| Runs (the other recordings) | 46,398 calls (`stage1/rec/rzx-p1-18000` 2,050, `stage1/rec/rzx-p1-46000` 1,600, `stage1/rec/rzx-p1-06000` 1,546 and 43 more) |
| Called from | `ChannelStep` |
| Calls | `SoundWrite` |
| Reads | `$D839`-`$D857` (`Channels+7`, `Mixer`, `ChannelNumber`) |

### `SoundWrite` (`$D759`)

**AY register D = E: OUT (`$FFFD`),D, OUT (`$BFFD`),E**

Witness: L1 328483 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 99,792 calls, 5,324,570 t-states own (0.37 %) |
| Runs (the other recordings) | 228,691 calls (`stage2/rec/p1-cursor` 64,914, `stage1/rec/rzx-p1-18000` 7,354, `stage1/rec/rzx-p1-46000` 6,117 and 44 more) |
| Called from | `SoundSilence`, `WriteMixer`, `SoundStep`, `ChannelStep`, `WriteVolume` |
| Ports out | `$BFFD`, `$FFFD` |

## menu

`src/game/menu.asm`

### `TitleMenu` (`$DAC0`)

**The title and menu: the title on, the menu text, the roll call, the keys 1-4**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 615,128 t-states own (0.04 %) |
| Runs (the other recordings) | run into, not called (`docs/rxA/rec/menu-rollcall`, `stage1/rec/rzx-p1-00000`, `stage2/rec/p1-define` and 2 more) |
| Called from | `GameEntry` |
| Calls | `PrintBoxed`, `Delay`, `DefineKeys` (tail), `ChooseKempston` (tail), `ChooseSinclair` (tail), `ChooseCursor` (tail), `RollCallSprite` |
| Reads | `$4000`-`$5AFF` (screen); `$A065` (`SweepCount`); `$A083`-`$A087` (`RollTextPtr`, `RollShow`, `RollTextNext`); `$DC44` (`RollCallTexts+30`); `$DC60` (`RollCallTexts+58`); `$DC7C` (`RollCallTexts+86`); 8 more ranges |
| Writes | `$4000`-`$5AFF` (screen); `$6018`-`$60D7` (`DevLinkStub`, `Unused607E`); `$A065` (`SweepCount`); `$A07F`-`$A087` (`RollFrame`, `RollPtr`, `RollTextPtr`, `RollShow` and 1 more); `$E4FF`-`$FFFE` (`TitleScreen`, `work space $FFFA+`) |
| Ports in | `$F7FE` |
| Ports out | `$00FE` |

### `RollCallRestart` (`$DB6E`)

**The roll call from its first sprite again (HL = RollCallSprites), then RollCallText**

TitleMenu's loop falls in here when the next sprite record is the list's `$FF`. Run by menu-rollcall (the menu left alone for 5310 frames, every enemy shown once). c1 also reads these bytes as data in play (frames 18550-20469; the reader is not identified).

Witness: L1 1 (menu-rollcall).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`docs/rxA/rec/menu-rollcall` 1) |

### `RollCallText` (`$DB71`)

**The next enemy's name and score (2 text records), the next record; at the list's end RollCallTextStart**

Witness: L1 14 (c1, menu-rollcall).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10 runs of its first instruction, entered by a jump (`docs/rxA/rec/menu-rollcall` 10) |
| Calls | `PrintBoxed` |

### `RollCallTextStart` (`$DB85`)

**The names from the first again (IX = RollCallTexts), then RollCallNext**

Reached at the list's end. Run by menu-rollcall (the menu left alone for 5310 frames).

Witness: L1 1 (menu-rollcall).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`docs/rxA/rec/menu-rollcall` 1) |

### `RollCallNext` (`$DB89`)

**Keep the text pointer, back to the menu loop**

Witness: L1 14 (c1, menu-rollcall).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10 runs of its first instruction, entered by a jump (`docs/rxA/rec/menu-rollcall` 10) |
| Calls | `ShowTitle` |

### `ShowTitle` (`$DB96`)

**The title screen (`$E4FF`) to the screen, the menu's attribute box**

Witness: L1 18 (c1, menu-rollcall, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 721,148 t-states own (0.05 %) |
| Runs (the other recordings) | 14 calls (`docs/rxA/rec/menu-rollcall` 10, `stage1/rec/rzx-p1-00000` 1, `stage2/rec/p1-kempston` 1 and 2 more) |
| Called from | `RollCallNext`, `DefineKeys`, `ChooseKempston`, `ChooseSinclair`, `ChooseCursor` |
| Calls | `FillAttrs` |
| Reads | `$E4FF`-`$FFFE` (`TitleScreen`, `work space $FFFA+`) |
| Writes | `$4000`-`$5AFF` (screen) |

### `ScanKey` (`$DBAE`)

**DEFINE: wait for a key not SPACE, not H and not taken; its port into DefinePort, its BIT opcode into DefineBit, its character in A**

Witness: L1 10 (c1, p1-define).

[Animation: `ScanKey` at work](img/routines/ScanKey.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 17,678,036 t-states own (1.22 %) |
| Runs (the other recordings) | 5 calls (`stage2/rec/p1-define` 5) |
| Called from | `DefineKeys` |
| Reads | `$A9CD`-`$A9E7` (`KeyNames+1`); `$DD4E`-`$DD52` (`DefineTaken`); `$E0E0`-`$E0EF` (`KeyPorts`) |
| Writes | `$A0AB`-`$A0AD` (`DefinePort`, `DefineBit`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `DefineKeys` (`$DD54`)

**1: DEFINE: PRESS a key for each of UP, DOWN, LEFT, RIGHT, FIRE (the setters `$A4B5`, `$A4CE`, `$A483`, `$A49C`, `$A46A`), then the confirm**

Witness: L1 2 (c1, p1-define).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 326,928 t-states own (0.02 %) |
| Runs (the other recordings) | 1 call (`stage2/rec/p1-define` 1) |
| Called from | `TitleMenu` (tail) |
| Calls | `PrintBoxed`, `PrintTextHL`, `SetFire`, `SetLeft`, `SetRight`, `SetUp`, `SetDown`, `ShowTitle`, `ScanKey`, `KeysConfirm` (tail), `FontChar`, `DrawChar` |
| Writes | `$DD4E`-`$DD53` (`DefineTaken`) |
| Ports in | `$F7FE` |

### `ChooseKempston` (`$DE20`)

**2, Kempston: the readers on port `$001F`, ControlXor `$FF`; fire bit 4, up 3, down 2, right 0, left 1; the confirm**

The same shape as ChooseSinclair: LD HL,`$001F`: LD (DefinePort),HL and for each control LD A,BIT opcode: LD (DefineBit),A: CALL the setter, then ControlXor = `$FF` and JP Confirm (with ConfirmKempstonText). Run by p1-kempston (menu key 2, then play on the stick: the readers' operands read back as port `$001F`, bits 4, 1, 0, 3, 2, ControlXor `$FF`).

Witness: L1 1 (p1-kempston)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/p1-kempston` 1) |
| Called from | `TitleMenu` (tail) |
| Calls | `SetFire`, `SetLeft`, `SetRight`, `SetUp`, `SetDown`, `ShowTitle`, `Confirm` (tail) |
| Writes | `$A0AB`-`$A0AE` (`DefinePort`, `DefineBit`, `ControlXor`) |

### `ChooseSinclair` (`$DE5D`)

**4: Sinclair (port `$EFFE`, keys 6-0): fire bit 0, up 1, down 2, right 3, left 4; the confirm**

Witness: L1 1 (rzx-p1-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/rzx-p1-00000` 1) |
| Called from | `TitleMenu` (tail) |
| Calls | `SetFire`, `SetLeft`, `SetRight`, `SetUp`, `SetDown`, `ShowTitle` |
| Writes | `$A0AB`-`$A0AE` (`DefinePort`, `DefineBit`, `ControlXor`) |
| Ports in | `$7FFE`, `$DFFE` |

### `KeysConfirm` (`$DE92`)

**ControlXor 0 (keys), then the confirm**

Witness: L1 4 (c1, p1-cursor, p1-define, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 4,197,265 t-states own (0.29 %) |
| Runs (the other recordings) | 1 call (`stage2/rec/p1-define` 1) |
| Called from | `DefineKeys` (tail) |
| Writes | `$A0AE` (`ControlXor`) |
| Ports in | `$7FFE`, `$DFFE` |

### `ChooseCursor` (`$DE99`)

**3, Cursor: port `$EFFE` fire bit 0 (key 0), right 2 (8), up 3 (7), down 4 (6); left `$F7FE` bit 4 (5); the confirm**

Built like ChooseSinclair, ending with KeysConfirm (ControlXor 0). From `$DE9F` on, after the menu, these bytes are also CellIndexMap: the room's animated cell index of each grid cell, written by DrawRoom and read by BulletHitsCell, which is why every play recording reads them. Run by p1-cursor (menu key 3, then play on 5-8 and 0: the readers' operands read back as above).

Witness: L1 1 (p1-cursor)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/p1-cursor` 1) |
| Called from | `TitleMenu` (tail) |
| Calls | `SetFire`, `SetLeft`, `SetRight`, `SetUp`, `SetDown`, `ShowTitle` |
| Writes | `$A0AB`-`$A0AE` (`DefinePort`, `DefineBit`, `ControlXor`) |
| Ports in | `$7FFE`, `$DFFE` |

### `Confirm` (`$DED2`)

**The confirm text; Y returns (the game starts), N goes back to the menu (MenuAgain)**

Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1 call (`stage2/rec/p1-kempston` 1) |
| Called from | `ChooseKempston` (tail) |
| Calls | `PrintBoxed` |
| Ports in | `$7FFE`, `$DFFE` |

### `FontChar` (`$DEF0`)

**DE = the font's character A (`$5FE0` + 8A)**

Witness: L1 10 (c1, p1-define).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 395 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`stage2/rec/p1-define` 5) |
| Called from | `DefineKeys` |

### `DrawChar` (`$DEFC`)

**8 bytes from DE down the screen at HL**

Witness: L1 10 (c1, p1-define).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 calls, 1,540 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`stage2/rec/p1-define` 5) |
| Called from | `DefineKeys` |
| Reads | `$6228`-`$626F` (`Font+328`); `$6298`-`$62B7` (`Font+440`) |
| Writes | `$488F`-`$500F` (screen); `$510F` (screen); `$520F` (screen); `$530F` (screen); `$540F` (screen); `$550F` (screen); 2 more ranges |

### `RollCallSprite` (`$E00B`)

**Draw the roll call's sprite (RollCallSprites record at HL) frame RollFrame by DrawCharBlock, its picture and column written into the inline parameters**

Witness: L1 1468 (c1, menu-rollcall, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 364 calls, 65,047 t-states own (0.00 %) |
| Runs (the other recordings) | 1,104 calls (`docs/rxA/rec/menu-rollcall` 1,022, `stage1/rec/rzx-p1-00000` 22, `stage2/rec/p1-cursor` 20 and 2 more) |
| Called from | `TitleMenu` |
| Calls | `DrawCharBlock` |
| Reads | `$A07F`-`$A085` (`RollFrame`, `RollPtr`, `RollTextPtr`, `RollShow`); `$E067`-`$E0DE` (`RollCallSprites`) |
| Writes | `$A081`-`$A082` (`RollPtr`); `$E049`-`$E04E` (`RollSpriteParams`) |

### `RollCallFrame` (`$E04F`)

**The next frame (8 a sprite), then the next record**

Witness: L1 746 (c1, menu-rollcall, p1-cursor, p1-define, p1-kempston).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 164 calls, 18,564 t-states own (0.00 %) |
| Runs (the other recordings) | 582 calls (`docs/rxA/rec/menu-rollcall` 522, `stage2/rec/p1-cursor` 20, `stage2/rec/p1-define` 20 and 1 more) |
| Called from | `DrawCharBlock` |
| Reads | `$A07F`-`$A082` (`RollFrame`, `RollPtr`) |
| Writes | `$A07F`-`$A082` (`RollFrame`, `RollPtr`) |


## The BASIC of REX 1 (`src/tape/basic-rex1.json`)

Rex, Martech Games 1988: tape side 1 block 2, the BASIC program "REX 1" (PROG `$5CCB`, LINE 1). Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic-rex1.json`; the
recordings: `work/stage1/c1` (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on
level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic-rex1`](11-data-reference.md#the-basic-of-rex-1-basic-rex1) | `$5CCB`-`$5D61` | 0 of 7 |


## The BASIC of REX 2 (`src/tape/basic-rex2.json`)

Rex, Martech Games 1988: tape side 1 block 8, the BASIC program "REX 2" (PROG `$5CCB`, LINE 1). Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic-rex2.json`; the
recordings: `work/stage1/c1` (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on
level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic-rex2`](11-data-reference.md#the-basic-of-rex-2-basic-rex2) | `$5CCB`-`$5D61` | 0 of 7 |


## The BASIC of DEMO (`src/tape/basic-demo.json`)

Rex, Martech Games 1988: tape side 2 block 2, the BASIC program "DEMO" (PROG `$5CCB`, LINE 1). Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic-demo.json`; the
recordings: `work/stage1/c1` (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on
level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic-demo`](11-data-reference.md#the-basic-of-demo-basic-demo) | `$5CCB`-`$5D60` | 0 of 7 |


## REX 1's loading screen (`src/screen/screen-rex1.json`)

Rex, Martech Games 1988: tape side 1 block 4, the loading screen of REX 1 (6912 bytes at `$4000`). Its entries are
`src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part src/screen/screen-
rex1.json`; the recordings: `work/stage1/c1` (c1: power-on, side 1 of the original at ROM speed on the 128K, the
menu and play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`screen-rex1`](11-data-reference.md#rex-1s-loading-screen-screen-rex1) | `$4000`-`$5AFF` | 0 of 1 |


## REX 2's loading screen (`src/screen/screen-rex2.json`)

Rex, Martech Games 1988: tape side 1 block 10, the loading screen of REX 2 (6912 bytes at `$4000`). Its entries are
`src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part src/screen/screen-
rex2.json`; the recordings: `work/stage1/c1` (c1: power-on, side 1 of the original at ROM speed on the 128K, the
menu and play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`screen-rex2`](11-data-reference.md#rex-2s-loading-screen-screen-rex2) | `$4000`-`$5AFF` | 0 of 1 |


## DEMO's loading screen (`src/screen/screen-demo.json`)

Rex, Martech Games 1988: tape side 2 block 4, the loading screen of DEMO (6912 bytes at `$4000`). Its entries are
`src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part src/screen/screen-
demo.json`; the recordings: `work/stage1/c1` (c1: power-on, side 1 of the original at ROM speed on the 128K, the
menu and play on level 1).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`screen-demo`](11-data-reference.md#demos-loading-screen-screen-demo) | `$4000`-`$5AFF` | 0 of 1 |


## Part 2 (REX 2) (`src/rex2/rex2.json`)

Rex, Martech Games 1988 (The Light): part 2 (REX 2), `$61A8-$FFF9` as the ROM loader leaves it (tools/parts.py: side
1 blocks 10 and 12 of orig/Rex.tzx.zip); entry `$9470`. Its entries are `src/rex2/<module>.asm`, written from
`src/rex2/rex2.ann` by `kit/mkgame.py --part src/rex2/rex2.json`; the recordings: `work/stage1/c1` (c1: power-on,
side 1 of the original at ROM speed on the 128K, the menu and play on level 1), and `work/stage1/c2`,
`work/stage1/rec/rzx-p2-00000`, `work/stage1/rec/rzx-p2-02000`, `work/stage1/rec/rzx-p2-04000`,
`work/stage1/rec/rzx-p2-06000`, `work/stage1/rec/rzx-p2-08000`, `work/stage1/rec/rzx-p2-10000`,
`work/stage1/rec/rzx-p2-12000`, `work/stage1/rec/rzx-p2-14000`, `work/stage1/rec/rzx-p2-16000`,
`work/stage1/rec/rzx-p2-18000`, `work/stage1/rec/rzx-p2-20000`, `work/stage1/rec/rzx-p2-22000`,
`work/stage1/rec/rzx-p2-24000`, `work/stage1/rec/rzx-p2-26000`, `work/stage1/rec/rzx-p2-28000`,
`work/stage1/rec/rzx-p2-30000`, `work/stage1/rec/rzx-p2-32000`, `work/stage1/rec/rzx-p2-34000`,
`work/stage1/rec/rzx-p2-36000`, `work/stage1/rec/rzx-p2-38000`, `work/stage1/rec/rzx-p2-40000`,
`work/stage2/rec/p2-room20`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`graphics`](11-data-reference.md#part-2-rex-2-graphics) | `$61A8`-`$946F` | 0 of 10 |
| [`entry`](#part-2-rex-2-entry) | `$9470`-`$9584`, `$97AB`-`$9806` | 5 of 5 |
| [`mainloop`](#part-2-rex-2-mainloop) | `$9585`-`$9666` | 2 of 2 |
| [`rex`](#part-2-rex-2-rex) | `$9667`-`$9730` | 3 of 3 |
| [`bomb`](#part-2-rex-2-bomb) | `$9731`-`$97AA` | 3 of 3 |
| [`score`](#part-2-rex-2-score) | `$9807`-`$9BA6` | 16 of 19 |
| [`death`](#part-2-rex-2-death) | `$9BA7`-`$A0F7` | 17 of 21 |
| [`cells`](#part-2-rex-2-cells) | `$A0F8`-`$A1AA` | 2 of 2 |
| [`variables`](11-data-reference.md#part-2-rex-2-variables) | `$A1AB`-`$A26B` | 0 of 1 |
| [`hud`](#part-2-rex-2-hud) | `$A26C`-`$A611` | 23 of 27 |
| [`controls`](#part-2-rex-2-controls) | `$A612`-`$A6AA` | 12 of 12 |
| [`grid`](#part-2-rex-2-grid) | `$A6AB`-`$A8F5` | 8 of 10 |
| [`weapons`](#part-2-rex-2-weapons) | `$A8F6`-`$A938`, `$B452`-`$BADB` | 47 of 50 |
| [`attract`](#part-2-rex-2-attract) | `$A939`-`$A9FF` | 2 of 3 |
| [`tables`](11-data-reference.md#part-2-rex-2-tables) | `$AA00`-`$B242` | 0 of 14 |
| [`render`](#part-2-rex-2-render) | `$B243`-`$B451` | 5 of 5 |
| [`panels`](#part-2-rex-2-panels) | `$BADC`-`$BC47`, `$D609`-`$DABF` | 13 of 14 |
| [`objects`](#part-2-rex-2-objects) | `$BC48`-`$C7AD` | 52 of 57 |
| [`rooms`](#part-2-rex-2-rooms) | `$C7AE`-`$CD43` | 30 of 30 |
| [`rexmove`](#part-2-rex-2-rexmove) | `$CD44`-`$CF58` | 14 of 16 |
| [`collisions`](#part-2-rex-2-collisions) | `$CF59`-`$D345` | 11 of 12 |
| [`sound`](#part-2-rex-2-sound) | `$D346`-`$D608` | 9 of 11 |
| [`menu`](#part-2-rex-2-menu) | `$DAC0`-`$FFF9` | 10 of 22 |

### Part 2 (REX 2): entry

`src/rex2/entry.asm`

#### `GameEntry` (`$9470`)

**The code block's entry (USR 38000, the BASIC's line 60): DI, the menu, the high score, then NewGame**

As REX 1's GameEntry `$947A` (src/game/entry.asm).

Witness: L1 1 (c2).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 16,219 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/c2` 1) |
| Calls | `NewGame` (falls into), `TitleMenu` |
| Reads | `$A1D7`-`$A1D8` (`Score`); `$A22C` (`Temp1`); `$A263`-`$A267` (`CodeScore`, `CodeShield`, `CodeBombs`, `CodeLives`); `$E4FF`-`$E7FD` (`TitleScreen`, `AttrShadowPlay`) |
| Writes | `$A08B`-`$A08C` (`SparkleDotStore+4`); `$A0AE` (`SparkleDots+1`); `$A0C2` (`SparkleDots+21`); `$A1B1` (`PowerCount`); `$A1C9`-`$A268` (`SmartBombOn`, `SmartBombPtr`, `SpriteMirror`, `SpritePicture` and 107 more); `$AC5D` (`DoubleFireText`); 2 more ranges |
| Ports out | `$00FE` |

#### `NewGame` (`$948E`)

**A new game: the variables reset, score, lives, bombs and shield from the code (`$A263`, `$A267`, `$A266`, `$A265`), StartWeapon, PHASE TWO:ENTER THE LIVING TOWER TO REACH ZENITH and PRESS FIRE TO BEGIN, the wait for fire, Rex materialises**

Changed from REX 1's NewGame `$9498` (src/game/entry.asm).

Witness: L1 5 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,046,105 t-states own (0.07 %) |
| Runs (the other recordings) | 2 calls (`stage1/c2` 2) |
| Called from | `GameEntry` (falls into), `ShardBack` (tail), `ExplosionAreas` (tail), `Attract` (tail), `ReadExits` (tail) |
| Calls | `WaitFireOrAttract`, `ShowScore`, `ShowLives`, `FadeStep`, `ExplosionAreas`, `Materialise`, `CellsUnderRex`, `Recharge`, `PrintBoxed`, `DrawHud`, `BombIcons`, `ClearScreen`, `ReadFire`, `InitDrones`, `DroneOrbit`, `RollCharUp` (tail), `Attract` (tail), `PowerGain`, `StartWeapon`, `SaveAttrs`, `EnemyBulletsHitRex`, `SoundReset`, `SfxGun` |
| Reads | `$6758`-`$675F` (`CharGraphics+338`); `$6858`-`$685F` (`AnimChar73+10`); `$A017` (`SparkleDots2+17`); `$A040` (`SparkleDir+29`); `$A055` (`SparkleMove+10`); `$A093` (`SparkleDotOut+6`); 6 more ranges |
| Writes | `$6758`-`$675F` (`CharGraphics+338`); `$6858`-`$685F` (`AnimChar73+10`); `$A012`-`$A01A` (`SparkleDots2+12`); `$A030`-`$A0BD` (`SparkleDir+13`, `SparkleMasks`); `$A1AB`-`$A1B3` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 3 more); `$A1C9`-`$A256` (`SmartBombOn`, `SmartBombPtr`, `SpriteMirror`, `SpritePicture` and 95 more); 5 more ranges |
| Ports in | `$7FFE`, `$BFFE` |
| Ports out | `$00FE` |

#### `WaitFireOrAttract` (`$97AB`)

**Wait up to 50000 polls for fire: Temp1 = 1 after a press and its release, 0 when the count runs out**

As REX 1's WaitFireOrAttract `$97C3` (src/game/entry.asm).

Witness: L1 10 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 69,475,318 t-states own (4.79 %) |
| Runs (the other recordings) | 10 calls (`stage1/c2` 8, `stage1/rec/rzx-p2-00000` 2) |
| Called from | `NewGame` |
| Calls | `ReadFire`, `DrawRoomCell`, `SoundReset`, `SoundSilence`, `Channels` |
| Writes | `$A093` (`SparkleDotOut+6`); `$A22C` (`Temp1`) |

#### `WaitFire` (`$97D2`)

**Wait for fire, then for its release (no timeout): after the game over and the CODE panel**

As REX 1's WaitFire `$97EA` (src/game/entry.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `BufferToScreen`, `SfxGun` |

#### `ShowPointsUnused` (`$97E5`)

**REX 1's ShowPoints (the points sign SpritePoints `$84D8`, kind `$FF`); KillObject does it inline, nothing calls this (leftover)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 5,485,864 t-states own (0.38 %) |
| Called from | `ExplosionAreas` |
| Calls | `BufferToScreen`, `SfxGun`, `Channels` |

### Part 2 (REX 2): mainloop

`src/rex2/mainloop.asm`

#### `MainLoop` (`$9585`)

**Build the room, then one pass of play a frame: the HUD, objects, bullets, the boss's explosion while BossDying `$A268`, the keys (ENTER restart, H pause, SPACE smart bomb), fire, Rex's moves (none while the boss dies) and the cells under him**

Changed from REX 1's MainLoop `$9583` (src/game/mainloop.asm).

Witness: L1 29 (c2, p2-room20, rzx-p2- x17).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 26 calls (`stage1/rec/rzx-p2-02000` 2, `stage1/rec/rzx-p2-26000` 2, `stage1/rec/rzx-p2-18000` 2 and 15 more) |
| Called from | `LifeLost` (tail), `ChangeRoom` (tail) |
| Calls | `ShieldToggle`, `RexState`, `DrawRex`, `SmartBomb`, `SmartBombStep`, `KillFlashFade`, `FadeStep`, `BossExplodes`, `LifeLost`, `SparkleUpdate`, `ObjectDissolve`, `SparkleDraw`, `SparkleMasks`, `CellsUnderRex`, `HudSweep`, `BufferToScreen`, `PrintTextHL`, `PrintChar`, `PrintText`, `ReadFire`, `ReadLeft`, `ReadRight`, `ReadUp`, `ReadDown`, `Pause`, `CellPointer`, `AnimateCells`, `UpdateDrones`, `BuildRoom`, `RoomExits`, `ClearBuffer`, `DrawSprite`, `DrawAnimCells`, `FireWeapon`, `SetupShot`, `MoveEnemyBullets`, `MoveBullets`, `MoveSplitShot`, `PowerBar`, `BestWeapon`, `UpdateObjects`, `ReadExits`, `SetSpawnLeft`, `SpawnScripted`, `SpawnRandom`, `WalkRightKey`, `WalkLeftKey`, `RexWalk`, `StartJump`, `RexJump`, `RexFall`, `EnemyBulletsHitRex`, `ObjectHitsRex`, `BulletLoop`, `NextBullet`, `HitObjectHard`, `SoundStep`, `DrawCharBlock` |
| Reads | `$A1B0` (`PassToggle`); `$A1D9` (`RapidShotsOn`); `$A1EE` (`Dying`); `$A24F`-`$A254` (`RexX`, `RexY`, `Room`, `RoomColumn` and 1 more); `$A268` (`BossDying`) |
| Writes | `$A1AB`-`$A1B3` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 3 more); `$A1E5` (`ShieldKeyLatch`); `$A248`-`$A249` (`SpriteX`, `SpriteY`) |
| Ports in | `$7FFE`, `$BFFE` |

#### `SoundOffReturn` (`$9663`)

**CALL SoundSilence: RET; no instruction reaches it (leftover, as in REX 1)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `UpdateDrones` |

### Part 2 (REX 2): rex

`src/rex2/rex.asm`

#### `ShieldToggle` (`$9667`)

**The down key: switch the shield on or off (once a press, only with energy left)**

As REX 1's ShieldToggle `$967F` (src/game/rex.asm).

Witness: L1 203 (c2, rzx-p2- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 587 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 448 t-states own (0.00 %) |
| Runs (the other recordings) | 203 calls (`stage1/c2` 94, `stage1/rec/rzx-p2-04000` 11, `stage1/rec/rzx-p2-12000` 9 and 17 more) |
| Called from | `MainLoop` |
| Calls | `ClearScreen`, `UpdateDrones` |
| Reads | `$A060` (`SparkleMove+21`); `$A1E2`-`$A1E6` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`); `$A1F9` (`SparkleMode`) |
| Writes | `$A1E2`-`$A1E5` (`ShieldOn`, `ShieldKeyLatch`) |

#### `RexState` (`$9683`)

**Rex's death animation while he is present and Dying `$A1EE` is set, else nothing**

As REX 1's RexState `$969B` (src/game/rex.asm).

Witness: L1 10440 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 15 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,440 calls (`stage1/rec/rzx-p2-16000` 519, `stage1/rec/rzx-p2-18000` 517, `stage1/rec/rzx-p2-14000` 511 and 20 more) |
| Called from | `MainLoop` |
| Calls | `DrawRex` (falls into), `DeathAnimation` (tail) |
| Reads | `$A1E2`-`$A1F6` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate` and 14 more); `$A213` (`OnLift`); `$A248`-`$A256` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight` and 8 more); `$D5D2` (`Channels+8`) |
| Writes | `$A1CC` (`SpriteMirror`); `$A248`-`$A24B` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$D538`-`$D539` (`SfxShieldTone`) |

#### `DrawRex` (`$968F`)

**Draw Rex: his picture (walking or jumping); with the shield on, its hum, its drain and the bubble**

As REX 1's DrawRex `$96A7` (src/game/rex.asm).

Witness: L1 9413 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 136,530 t-states own (0.01 %) |
| Runs (the other recordings) | 6,260 calls (`stage1/rec/rzx-p2-22000` 489, `stage1/rec/rzx-p2-08000` 477, `stage1/rec/rzx-p2-26000` 449 and 13 more) |
| Called from | `MainLoop`, `RexState` (falls into), `BossExplodes` (tail), `DeathAnimation` (tail) |
| Calls | `ShieldDrain`, `BossExplodes` (tail), `Random`, `ClearBuffer`, `DrawSprite`, `StartSfx` |
| Reads | `$A049`-`$A05D` (`SparkleDir+38`, `SparkleMove`); `$A07A` (`SparkleDotIn+10`); `$A0B6`-`$A0BD` (`SparkleDots+9`); `$A1E2` (`ShieldOn`); `$A213` (`OnLift`); `$A248`-`$A256` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight` and 8 more); 1 more ranges |
| Writes | `$A033` (`SparkleDir+16`); `$A0AF`-`$A0B2` (`SparkleDots+2`); `$A1CC` (`SpriteMirror`); `$A248`-`$A24B` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$D538`-`$D539` (`SfxShieldTone`) |

### Part 2 (REX 2): bomb

`src/rex2/bomb.asm`

#### `SmartBombFree` (`$9731`)

**A smart bomb that costs nothing (Rex's death): unless one is running, mark the room's objects**

As REX 1's SmartBombFree `$9749` (src/game/bomb.asm).

Witness: L1 36 (c2, p2-room20, rzx-p2- x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rec/rzx-p2-24000` 4, `stage1/rec/rzx-p2-18000` 4, `stage1/rec/rzx-p2-16000` 4 and 13 more) |
| Called from | `RexDies` |
| Reads | `$5D28`-`$5E45`; `$A1C9` (`SmartBombOn`) |
| Writes | `$5D28`-`$5DA0`; `$5DDC`; `$A1C8`-`$A1CB` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`) |

#### `SmartBomb` (`$9739`)

**SPACE: one smart bomb from Bombs `$A205` (none left, nothing): the HUD, SmartBombOn `$A1C9` = 1, 14 steps, and the 20 enemy bullets marked (state 2)**

Changed from REX 1's SmartBomb `$9751` (src/game/bomb.asm).

Witness: L1 2 (rzx-p2-28000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 7,782 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/rzx-p2-28000` 2) |
| Called from | `MainLoop`, `DeathAnimation` |
| Calls | `FireLatch`, `ShowBombs` |
| Reads | `$5D28`-`$5E45`; `$A030` (`SparkleDir+13`); `$A06C` (`SparkleMove+33`); `$A1C9` (`SmartBombOn`); `$A205` (`Bombs`) |
| Writes | `$5D28`-`$5D91`; `$A02F`-`$A032` (`SparkleDir+12`); `$A06C` (`SparkleMove+33`); `$A1C8`-`$A1CB` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`); `$A205` (`Bombs`) |

#### `SmartBombStep` (`$976E`)

**One step of a running smart bomb: KillObject on the next object record (not kinds `$FE`, `$FD`, `$FC`, `$90`; neither the alive byte nor kind `$FF` tested); CopyAttrs after the last of 14 steps; records of 27 bytes**

As REX 1's SmartBombStep `$9786` (src/game/bomb.asm).

Witness: L1 10426 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 38,429 t-states own (0.00 %) |
| Runs (the other recordings) | 10,426 calls (`stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516, `stage1/rec/rzx-p2-14000` 511 and 20 more) |
| Called from | `MainLoop` |
| Calls | `KillObject`, `CopyAttrs` |
| Reads | `$5E6F`-`$5F2F`; `$5F47`; `$5F5F`-`$5F62`; `$5F77`-`$5F7D`; `$5F8F`-`$5FD7`; `$A02F`-`$A032` (`SparkleDir+12`); 1 more ranges |
| Writes | `$A02F`-`$A032` (`SparkleDir+12`); `$A1C8`-`$A1CB` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`) |

### Part 2 (REX 2): score

`src/rex2/score.asm`

#### `KillObject` (`$9807`)

**Kill the object at IX: a kind 3 counts its ten hits (HitKind3); in the play area its points picture, BIO GROWTHS KILLED counts every kind but 0, the kind's score (KillScores), the explosion sound**

Changed from REX 1's KillObject `$981F` (src/game/score.asm).

Witness: L1 688 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 21,650 t-states own (0.00 %) |
| Runs (the other recordings) | 688 calls (`stage1/rec/rzx-p2-36000` 105, `stage1/rec/rzx-p2-16000` 52, `stage1/rec/rzx-p2-18000` 50 and 19 more) |
| Called from | `SmartBombStep`, `DriftObject` (tail), `WalkOff` (tail), `ObjectJump` (tail), `ObjectFall` (tail), `FallKill`, `ObjectHitsRex`, `BulletLoop`, `HitObject` (tail) |
| Calls | `CountKill`, `HitKind3`, `KillScores`, `AddScore`, `StartSfx` |
| Reads | `$5E67`-`$5FD7`; `$9896`-`$98A5` (`KillScores`); `$994E`-`$9959` (`AddScore+9`) |
| Writes | `$5E67`-`$5F9E`; `$A039`-`$A03D` (`SparkleDir+22`); `$A1D2`-`$A1D6` (`KillFlashPtr`, `ComboCount`, `ComboTimer`) |

#### `CountKill` (`$986E`)

**BioGrowthsKilled `$A222` + 1 (every kill but kind 0)**

Witness: L1 247 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 247 calls (`stage1/rec/rzx-p2-38000` 26, `stage1/rec/rzx-p2-26000` 22, `stage1/rec/rzx-p2-24000` 20 and 19 more) |
| Called from | `KillObject` |
| Reads | `$A222`-`$A223` (`GrowthsKilled`) |
| Writes | `$A222`-`$A223` (`GrowthsKilled`) |

#### `HitKind3` (`$9876`)

**Kind 3 takes ten hits: each one steps its picture a frame on; before the tenth it leaves KillObject (POP BC: RET), the object lives**

Witness: L1 189 (rzx-p2- x9).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 16 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 189 calls (`stage1/rec/rzx-p2-36000` 75, `stage1/rec/rzx-p2-08000` 22, `stage1/rec/rzx-p2-30000` 20 and 6 more) |
| Called from | `KillObject` |
| Calls | `BossExplodes`, `Channels` |
| Reads | `$5E6A`-`$5EFE` |
| Writes | `$5E6A`-`$5F01` |

#### `KillFlashFade` (`$98B0`)

**Fade the HUD's kill flash one step (attribute row `$5840`, 30 cells), then mark the latest kill's two cells white**

As REX 1's KillFlashFade `$9992` (src/game/score.asm).

Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,871 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516 and 20 more) |
| Called from | `MainLoop`, `Attract` |
| Reads | `$5840`-`$585D` (screen); `$A1D2`-`$A1D3` (`KillFlashPtr`) |
| Writes | `$5843`-`$585C` (screen); `$E9FF`-`$EA00` (`ObjectBufferOrigin`) |

#### `ShowScore` (`$98C9`)

**Print Score `$A1D7` in the HUD**

As REX 1's ShowScore `$99AB` (src/game/score.asm).

Witness: L1 97 (c2, rzx-p2- x18).

[Animation: `ShowScore` at work](img/routines/ShowScore.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 97 calls (`stage1/rec/rzx-p2-10000` 11, `stage1/rec/rzx-p2-14000` 9, `stage1/rec/rzx-p2-20000` 7 and 16 more) |
| Called from | `NewGame`, `AddScore` (tail) |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$A1D7`-`$A1D8` (`Score`) |

#### `ShowLives` (`$98D9`)

**Print Lives `$A1FC` in the HUD**

As REX 1's ShowLives `$99BB` (src/game/score.asm).

Witness: L1 35 (c2, p2-room20, rzx-p2- x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 35 calls (`stage1/c2` 5, `stage1/rec/rzx-p2-24000` 4, `stage1/rec/rzx-p2-18000` 4 and 11 more) |
| Called from | `NewGame`, `LifeLost`, `ExtraLife` |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$A1FC` (`Lives`) |

#### `ShieldDrainFast` (`$98EC`)

**ShieldDrainRate `$A1E7` - 1: a hit on the shield drains it faster (EnemyBulletsHitRex, ObjectHitsRex)**

As REX 1's ShieldDrainFast `$99CE` (src/game/score.asm).

Witness: L1 24 (rzx-p2- x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24 calls (`stage1/rec/rzx-p2-12000` 7, `stage1/rec/rzx-p2-04000` 4, `stage1/rec/rzx-p2-32000` 3 and 8 more) |
| Called from | `EnemyBulletsHitRex`, `ObjectHitsRex` |
| Calls | `ShieldDrain` (falls into) |
| Writes | `$A1E7` (`ShieldDrainRate`) |

#### `ShieldDrain` (`$98F1`)

**With the shield on, count ShieldDrainRate down; at 0 one unit of ShieldEnergy `$A1E6` goes; none left switches the shield off**

As REX 1's ShieldDrain `$99D3` (src/game/score.asm).

Witness: L1 754 (c2, rzx-p2- x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 754 calls (`stage1/rec/rzx-p2-38000` 121, `stage1/c2` 112, `stage1/rec/rzx-p2-32000` 107 and 13 more) |
| Called from | `DrawRex`, `ShieldDrainFast` (falls into) |
| Calls | `ShowShield` |
| Reads | `$A1E6`-`$A1E7` (`ShieldEnergy`, `ShieldDrainRate`) |
| Writes | `$A1E2`-`$A1E7` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate`) |

#### `ShowShield` (`$9918`)

**Print ShieldEnergy `$A1E6` in the HUD and colour it: red when low, green otherwise (`$E513`, `$E514` in the attribute shadow)**

As REX 1's ShowShield `$99FA` (src/game/score.asm).

Witness: L1 669 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 669 calls (`stage1/rec/rzx-p2-32000` 133, `stage1/rec/rzx-p2-04000` 130, `stage1/rec/rzx-p2-30000` 115 and 19 more) |
| Called from | `ShieldDrain`, `LifeLost`, `Recharge`, `BuildRoom` |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$A1E6` (`ShieldEnergy`) |
| Writes | `$5814`-`$5815` (screen); `$E513`-`$E514` (`TitleScreen+20`) |

#### `AddScore` (`$9945`)

**Score `$A1D7` + HL; every 100 points ExtraLifeCount `$A20F` counts, at 100 an extra life (ExtraLife `$D338`)**

As REX 1's AddScore `$9A27` (src/game/score.asm).

Witness: L1 198 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 198 calls (`stage1/rec/rzx-p2-10000` 19, `stage1/rec/rzx-p2-26000` 16, `stage1/rec/rzx-p2-30000` 14 and 19 more) |
| Called from | `KillObject`, `HitObject`, `HitObjectHard` |
| Calls | `ShowScore` (tail), `ExtraLife` |
| Reads | `$A1D7`-`$A1D8` (`Score`); `$A1EE` (`Dying`); `$A20F`-`$A210` (`ExtraLifeCount`) |
| Writes | `$A1D7`-`$A1D8` (`Score`); `$A20F`-`$A210` (`ExtraLifeCount`) |

#### `FadeStep` (`$996A`)

**The HUD flash of a power pod (only TakePowerPod starts it): rows 0-1 (`$5800-$583F`) stepped through FadeSteps `$99D1` by FadeStepIndex `$A1DB`**

As REX 1's FadeStep `$9A4C` (src/game/score.asm).

Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,043,412 t-states own (0.07 %) |
| Runs (the other recordings) | 10,871 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516 and 20 more) |
| Called from | `NewGame`, `MainLoop`, `BossExplodes` (tail), `DeathAnimation`, `BuildRoom`, `Attract` |
| Calls | `DrawWeaponIcon`, `HudTexts` |
| Reads | `$5800`-`$585D` (screen); `$99D1`-`$99E2` (`FadeSteps`); `$A039`-`$A03F` (`SparkleDir+22`); `$A063` (`SparkleMove+24`); `$A1DB` (`FadeStepIndex`); `$A22C` (`Temp1`); 1 more ranges |
| Writes | `$5800`-`$585C` (screen); `$A1DB` (`FadeStepIndex`); `$A22C` (`Temp1`); `$E9FF`-`$EA00` (`ObjectBufferOrigin`) |

#### `BossExplodes` (`$99E3`)

**One pass of the big squidgy thing's death: 16 pieces drawn and coloured at random places of its area; at timer `$82` the area shrinks, at `$64` the ending**

Runs while BossDying `$A268` is set (MainLoop). Each of the 16 records of BossPieces `$9CFD` ([frame][X][Y]) is a piece of Rex's death picture (`$8490` + 72 x frame) drawn by DrawPiece `$9AE5` and coloured by ColourPiece `$9B4D`; after frame 8 the piece is cleared (CopyCells3) and, past timer `$78` and 1 in 3 at random, comes back at a random place inside the area that BossAreaPtr `$A26A` points at, with a random explosion sound. BossTimer `$A269` counts down from 200: at `$82` ShrinkArea `$9CBC`, at `$64` the ending text (EndingText `$AB6E`: WITH THE BIG SQUIDGY THING DESTROYED REX CAN GO HOME AND HAVE A NICE CUP OF TEA AND PUT HIS FEET UP) in a box, then the game stops in an endless JP to itself (`$9ADE`).

Witness: L1 100 (rzx-p2-40000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 359,639 t-states own (0.02 %) |
| Runs (the other recordings) | 100 calls (`stage1/rec/rzx-p2-40000` 100) |
| Called from | `MainLoop`, `DrawRex` (tail), `HitKind3`, `ShardBack`, `GiveMultiple`, `BuildRoom` |
| Calls | `DrawRex` (tail), `FadeStep` (tail), `DrawPiece`, `ColourPiece`, `ShrinkArea`, `PrintBoxed`, `DrawWeaponIcon`, `HudTexts`, `Random`, `Random2`, `CopyCells3`, `DrawRoomCell`, `Multiply`, `StartSfx` |
| Reads | `$9C05`-`$9C3A` (`ShardLoop+81`, `ShardNextRecord`); `$9CF7`-`$9D2C` (`ExplosionAreas`); `$A03E`-`$A063` (`SparkleDir+27`, `SparkleMove`); `$A076`-`$A077` (`SparkleDotIn+6`); `$A093`-`$A096` (`SparkleDotOut+6`); `$A0B6`-`$A0B7` (`SparkleDots+9`); 2 more ranges |
| Writes | `$5814`-`$5815` (screen); `$9C0B`-`$9C3A` (`ShardLoop+87`, `ShardNextRecord`); `$9CFD`-`$9D2C` (`ExplosionAreas+6`); `$A033`-`$A03F` (`SparkleDir+16`); `$A056` (`SparkleMove+11`); `$A076`-`$A077` (`SparkleDotIn+6`); 7 more ranges |

#### `DrawPiece` (`$9AE5`)

**Copy a pre-shifted picture into the back buffer: HL the shift table (by SpriteX & 7), DE the picture, byte column SpriteX / 8, line SpriteY, SpriteWidth x SpriteHeight (written into `$9B3D`, `$9B39`); no mask**

Witness: L1 1064 (rzx-p2-40000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 536 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,064 calls (`stage1/rec/rzx-p2-40000` 1,064) |
| Called from | `BossExplodes` |
| Calls | `DeathAnimation`, `ClearBuffer`, `EnemyBulletsHitRex` |
| Reads | `$84D8`-`$8717` (`SpritePoints`); `$A1CC`-`$A1CE` (`SpriteMirror`, `SpritePicture`); `$A248`-`$A24B` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`) |
| Writes | `$9B39`-`$9B3D` (`DrawPieceStore+6`, `DrawPieceRow`); `$A248` (`SpriteX`); `$A25E`-`$A25F` (`SpriteSource`); `$F208`-`$F231` (`BufferPlayOrigin+1801`); `$F248`-`$F251` (`BufferPlayOrigin+1865`); `$F268`-`$F271` (`BufferPlayOrigin+1897`); 5 more ranges |

#### `ColourPiece` (`$9B4D`)

**A piece's 3 x 3 cells under SpriteX/SpriteY: a random ink of PieceInks `$C2DF` on the screen and in the attribute shadow**

Witness: L1 1064 (rzx-p2-40000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,064 calls (`stage1/rec/rzx-p2-40000` 1,064) |
| Called from | `BossExplodes` |
| Calls | `InkCells3`, `DeathAnimation` (tail), `ShowBombs`, `DrawBombIcons`, `BufferAddress` |
| Reads | `$A22C`-`$A22F` (`Temp1`, `Temp2`); `$C2DF`-`$C2E6` (`PieceInks`) |
| Writes | `$A22C`-`$A22F` (`Temp1`, `Temp2`) |

#### `InkCells3` (`$9B7E`)

**Three rows of InkRow3**

Witness: L1 1064 (rzx-p2-40000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,064 calls (`stage1/rec/rzx-p2-40000` 1,064) |
| Called from | `ColourPiece` |
| Calls | `InkRow3` |

#### `InkRow3` (`$9B88`)

**Three cells at HL take ink C (paper kept: AND `$38`), HL and DE one row on**

Witness: L1 3192 (rzx-p2-40000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 68 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3,192 calls (`stage1/rec/rzx-p2-40000` 3,192) |
| Called from | `InkCells3` |
| Calls | `DrawBombIcons` |
| Reads | `$5949`-`$5952` (screen); `$5969`-`$5972` (screen); `$5989`-`$5992` (screen); `$59A9`-`$59B2` (screen); `$59C9`-`$59D2` (screen); `$59E9`-`$59F2` (screen); 2 more ranges |
| Writes | `$5949`-`$5952` (screen); `$5969`-`$5972` (screen); `$5989`-`$5992` (screen); `$59A9`-`$59B2` (screen); `$59C9`-`$59D2` (screen); `$59E9`-`$59F2` (screen); 2 more ranges |

### Part 2 (REX 2): death

`src/rex2/death.asm`

#### `DeathAnimation` (`$9BA7`)

**One pass of Rex's death: the shards, the death picture, the sound; at the end LifeLost**

As REX 1's DeathAnimation `$9AC5` (src/game/death.asm).

Witness: L1 557 (c2, p2-room20, rzx-p2- x14).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 68 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 12,078 t-states own (0.00 %) |
| Runs (the other recordings) | 557 calls (`stage1/rec/rzx-p2-16000` 68, `stage1/rec/rzx-p2-18000` 68, `stage1/rec/rzx-p2-24000` 68 and 13 more) |
| Called from | `RexState` (tail), `DrawPiece`, `ColourPiece` (tail), `SparkleUpdate` (tail), `ObjectDissolve` (tail), `TakePowerPod` |
| Calls | `DrawRex` (tail), `SmartBomb`, `FadeStep`, `ExplosionAreas`, `SaveRestart`, `CellsUnderRex`, `ShowBombs`, `ToDigits`, `PowerGain`, `Channels` |
| Reads | `$A03E`-`$A03F` (`SparkleDir+27`); `$A057`-`$A071` (`SparkleMove+12`, `SparkleDotIn`); `$A089`-`$A08C` (`SparkleDotStore+2`); `$A0B6`-`$A0BB` (`SparkleDots+9`); `$A1FC` (`Lives`); `$D83A` (`DebugHook+372`); 1 more ranges |
| Writes | `$A049`-`$A063` (`SparkleDir+38`, `SparkleMove`); `$A091` (`SparkleDotOut+4`); `$A0B3`-`$A0BD` (`SparkleDots+6`) |

#### `ShardNext` (`$9CAA`)

**DeathShardPtr `$A1F0` + 2**

As REX 1's ShardNext `$9BC8` (src/game/death.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `ShardBack` (`$9CB3`)

**DeathShardPtr `$A1F0` - 2: the shards step back**

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `NewGame` (tail), `BossExplodes` |

#### `ShrinkArea` (`$9CBC`)

**BossAreaPtr `$A26A` - 2: the boss's explosion area the smaller one (BossExplodes at timer `$82`)**

Witness: L1 1 (rzx-p2-40000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/rzx-p2-40000` 1) |
| Called from | `BossExplodes` |
| Reads | `$A26A`-`$A26B` (`BossAreaPtr`) |
| Writes | `$A26A`-`$A26B` (`BossAreaPtr`) |

#### `RexDies` (`$9CC5`)

**Rex is killed (unless Immune): the sweep reset, Dying, the timer 50, the free smart bomb (none while the boss dies), LosePower, ShieldEnergy refilled to 99, dematerialise while lives are left (which switches the shield off)**

Changed from REX 1's RexDies `$9BDA` (src/game/death.asm).

Witness: L1 36 (c2, p2-room20, rzx-p2- x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rec/rzx-p2-16000` 4, `stage1/rec/rzx-p2-24000` 4, `stage1/rec/rzx-p2-18000` 4 and 13 more) |
| Called from | `RexWalk`, `RexJump`, `RexFall`, `EnemyBulletsHitRex`, `ObjectHitsRex` |
| Calls | `SmartBombFree`, `Dematerialise`, `CellsUnderRex`, `ResetSweep`, `HudTexts`, `LosePower` |
| Reads | `$A1FC`-`$A20A` (`Lives`, `SweepPos`, `SweepCount`, `SweepDir` and 9 more); `$A268` (`BossDying`) |
| Writes | `$A1E6`-`$A1F1` (`ShieldEnergy`, `ShieldDrainRate`, `WeaponIcon`, `HasDoubleFire` and 7 more) |

#### `SaveRestart` (`$9D2D`)

**A restart marker (cell `$07`) under Rex: save Rex's place, room and facing as the restart point, a chime**

As REX 1's SaveRestart `$9C3B` (src/game/death.asm).

Witness: L1 550 (c2, p2-room20, rzx-p2- x15).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 737 t-states own (0.00 %) |
| Runs (the other recordings) | 550 calls (`stage1/c2` 81, `stage1/rec/rzx-p2-08000` 62, `stage1/rec/rzx-p2-16000` 50 and 14 more) |
| Called from | `DeathAnimation`, `CellsUnderRex` (tail) |
| Calls | `AnimateRestart`, `StartSfx`, `Channels` |
| Reads | `$A05D` (`SparkleMove+18`); `$A24F`-`$A254` (`RexX`, `RexY`, `Room`, `RoomColumn` and 1 more); `$D5D2` (`Channels+8`); `$E286`-`$E287` (`RoomGridPlay+135`); `$E2E9`-`$E2EF` (`RoomGridPlay+234`); `$E34C`-`$E355` (`RoomGridPlay+333`); 1 more ranges |
| Writes | `$A049` (`SparkleDir+38`); `$A05D`-`$A062` (`SparkleMove+18`); `$A1F2`-`$A1F4` (`RestartX`, `RestartY`, `RestartRoom`) |

#### `LifeLost` (`$9D68`)

**The end of a death: BossDying 0, one life less; Rex back at the restart point, or the game over**

Witness: L1 29 (c2, p2-room20, rzx-p2- x12).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,333,565 t-states own (0.23 %) |
| Runs (the other recordings) | 29 calls (`stage1/rec/rzx-p2-24000` 4, `stage1/rec/rzx-p2-18000` 4, `stage1/rec/rzx-p2-16000` 4 and 11 more) |
| Called from | `MainLoop`, `SparkleDraw` (tail) |
| Calls | `MainLoop` (tail), `ShowLives`, `ShowShield`, `Materialise`, `ShowBombs` |
| Reads | `$9F0C`-`$9F4F` (`DissolveMasks+1`, `ObjectDissolve`); `$A055`-`$A062` (`SparkleMove+10`); `$A093` (`SparkleDotOut+6`); `$A0B6`-`$A0B7` (`SparkleDots+9`); `$A1F2`-`$A1FC` (`RestartX`, `RestartY`, `RestartRoom`, `RestartFacing` and 7 more); `$A251` (`Room`); 8 more ranges |
| Writes | `$9F14`-`$9F4F` (`DissolveMasks+9`, `ObjectDissolve`); `$A05D`-`$A061` (`SparkleMove+18`); `$A093` (`SparkleDotOut+6`); `$A0B7` (`SparkleDots+10`); `$A1E2`-`$A1FC` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate` and 20 more); `$A22A` (`RexSpeed`); 8 more ranges |

#### `RexAppears` (`$9E05`)

**The materialise is over: RexPresent `$A1F6` = 1 (Rex can move and fire), SparkleCount `$A1F7` = 18**

As REX 1's RexAppears `$9D0F` (src/game/death.asm).

Witness: L1 1899 (c2, p2-room20, rzx-p2- x12).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 592 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,899 calls (`stage1/rec/rzx-p2-24000` 225, `stage1/rec/rzx-p2-16000` 224, `stage1/rec/rzx-p2-18000` 217 and 11 more) |
| Called from | `SparkleDraw` |
| Reads | `$A1F6` (`RexPresent`) |
| Writes | `$A1F6`-`$A1F7` (`RexPresent`, `SparkleCount`) |

#### `Materialise` (`$9E15`)

**Rex appears: RexPresent 0, the sparkle in (SparkleOn `$A1F8`, SparkleMode `$A1F9`), its dots cleared, the materialise sound `$D546`**

As REX 1's Materialise `$9D1F` (src/game/death.asm).

Witness: L1 32 (c2, p2-room20, rzx-p2- x12).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4,529 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 32 calls (`stage1/rec/rzx-p2-18000` 4, `stage1/rec/rzx-p2-24000` 4, `stage1/rec/rzx-p2-16000` 4 and 11 more) |
| Called from | `NewGame`, `LifeLost` |
| Calls | `StartSfx` |
| Reads | `$A0AD`-`$A0E7` (`SparkleDots`) |
| Writes | `$A0AD`-`$A0E8` (`SparkleDots`); `$A1F6`-`$A1FB` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more) |

#### `Dematerialise` (`$9E3D`)

**Rex vanishes: the shield off, the sparkle out (Vanishing `$A1FB` = 1), the sound `$D552`**

As REX 1's Dematerialise `$9D47` (src/game/death.asm).

Witness: L1 36 (c2, p2-room20, rzx-p2- x14).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4,529 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 36 calls (`stage1/rec/rzx-p2-16000` 4, `stage1/rec/rzx-p2-18000` 4, `stage1/rec/rzx-p2-24000` 4 and 13 more) |
| Called from | `RexDies` |
| Calls | `StartSfx` |
| Reads | `$A1F6` (`RexPresent`) |
| Writes | `$A1E2` (`ShieldOn`); `$A1F6`-`$A1FB` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more) |

#### `SparkleUpdate` (`$9E67`)

**One step of the sparkle in Rex's 3-byte box of the back buffer (SparkleBufferOrigin `$E89F`): SparkleCount lines cleared, the next 3 ANDed with random bytes; at the end the sparkle stops**

As REX 1's SparkleUpdate `$9D71` (src/game/death.asm).

Witness: L1 10438 (c2, p2-room20, rzx-p2- x21).

[Animation: `SparkleUpdate` at work](img/routines/SparkleUpdate.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 184 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,438 calls (`stage1/rec/rzx-p2-16000` 519, `stage1/rec/rzx-p2-18000` 517, `stage1/rec/rzx-p2-14000` 511 and 20 more) |
| Called from | `MainLoop` |
| Calls | `DeathAnimation` (tail), `FillCells3`, `DrawBombIcons`, `Random` |
| Reads | `$A1F6`-`$A1FB` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more); `$A24F`-`$A250` (`RexX`, `RexY`); `$ECCD`-`$F68F` (`BufferPlayOrigin+462`); `$F6D2`-`$F717` (`BufferPlayOrigin+3027`); `$F7D3`-`$F815` (`BufferPlayOrigin+3284`); `$F8D3`-`$F8D5` (`BufferPlayOrigin+3540`); 6 more ranges |
| Writes | `$A1F6`-`$A1FA` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 1 more); `$ECCD`-`$F68F` (`BufferPlayOrigin+462`); `$F6D2`-`$F717` (`BufferPlayOrigin+3027`); `$F7D3`-`$F815` (`BufferPlayOrigin+3284`); `$F8D3`-`$F8D5` (`BufferPlayOrigin+3540`); `$F8F3`-`$F8F5` (`BufferPlayOrigin+3572`); 5 more ranges |

#### `SparkleOut` (`$9EC4`)

**Vanishing: SparkleCount `$A1F7` + 1; at 18 Rex is gone (RexPresent 0) and the sparkle's timer is 30**

As REX 1's SparkleOut `$9DCE` (src/game/death.asm).

Witness: L1 557 (c2, p2-room20, rzx-p2- x14).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 120 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 557 runs of its first instruction, entered by a jump (`stage1/rec/rzx-p2-16000` 68, `stage1/rec/rzx-p2-18000` 68, `stage1/rec/rzx-p2-24000` 68 and 13 more) |
| Calls | `DrawBombIcons` |

#### `ObjectFadeIn` (`$9EE4`)

**The object at IX materialises: dissolve on (IX+`$18`), step 0 (IX+`$19`), inwards (IX+`$1A`); ObjectDissolve counts it up to 10**

Witness: L1 136 (c2, p2-room20, rzx-p2- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 232 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 136 calls (`stage1/rec/rzx-p2-18000` 14, `stage1/rec/rzx-p2-38000` 13, `stage1/rec/rzx-p2-30000` 10 and 18 more) |
| Called from | `SpawnAnywhere` |
| Calls | `ExplosionAreas` |
| Writes | `$5E7E`-`$5E9B`; `$5EB4`-`$5EB6`; `$5ECF`-`$5ED1`; `$5EEA`-`$5EEC`; `$5F05`-`$5F07`; `$5F20`-`$5F22`; 5 more ranges |

#### `ObjectFadeOut` (`$9EF1`)

**Unless it dissolves already, the object at IX dissolves out from step 10; a kind 0 also becomes a jumper (MakeJumper)**

Witness: L1 8 (c2, rzx-p2-00000, rzx-p2-16000, rzx-p2-28000, rzx-p2-32000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,491 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 8 calls (`stage1/rec/rzx-p2-32000` 2, `stage1/rec/rzx-p2-00000` 2, `stage1/c2` 2 and 2 more) |
| Called from | `CellDissolve` |
| Calls | `MakeJumper` |
| Reads | `$5E6F`-`$5E99` |
| Writes | `$5E7E`-`$5E80`; `$5E99`-`$5E9B` |

#### `ObjectDissolve` (`$9F15`)

**A dissolving object: its bytes in the back buffer ANDed with a random byte and the step's mask; in: step + 1 to 10; out: step - 1, at 0 the object is gone**

Witness: L1 47643 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 76,986 t-states own (0.01 %) |
| Runs (the other recordings) | 47,643 calls (`stage1/c2` 4,800, `stage1/rec/rzx-p2-36000` 3,105, `stage1/rec/rzx-p2-20000` 3,056 and 19 more) |
| Called from | `MainLoop`, `DrawObject` |
| Calls | `DeathAnimation` (tail), `Random2` |
| Reads | `$5E66`-`$5FA9`; `$9F0B`-`$9F15` (`DissolveMasks`, `ObjectDissolve`); `$A019`-`$A01A` (`SparkleDots2+19`); `$E379`-`$E380` (`RoomGridPlay+378`); `$E392`-`$E3A0` (`RoomGridPlay+403`); `$E3B2`-`$E3C6` (`RoomGridPlay+435`); 6 more ranges |
| Writes | `$5E72`-`$5E9A`; `$5EB4`-`$5EB5`; `$5ECF`-`$5ED0`; `$5EEA`-`$5EEB`; `$5F05`-`$5F06`; `$5F20`-`$5F21`; 7 more ranges |

#### `FillCells3` (`$9F8F`)

**Write C into a 3 x 3 patch at HL (32-byte rows)**

As REX 1's FillCells3 `$9DF6` (src/game/death.asm).

Witness: L1 1097 (c2, p2-room20, rzx-p2- x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,097 calls (`stage1/rec/rzx-p2-24000` 140, `stage1/rec/rzx-p2-18000` 140, `stage1/rec/rzx-p2-16000` 136 and 13 more) |
| Called from | `SparkleUpdate` |
| Writes | `$EBA4`-`$FAA3` (`BufferPlayOrigin+165`); `$FDB2`-`$FF54` (`BufferPlayOrigin+4787`); `$FF72`-`$FF74` (`BufferPlayOrigin+5235`); `$FF92`-`$FF94` (`BufferPlayOrigin+5267`); `$FFB2`-`$FFB4` (`BufferPlayOrigin+5299`) |

#### `SparkleDraw` (`$9F9B`)

**Draw the sparkle's particles round Rex (SparkleMasks `$A0A5`, SparkleDots `$A0AD`); at the end of a dematerialise LifeLost**

As REX 1's SparkleDraw `$9E02` (src/game/death.asm).

Witness: L1 10437 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,437 calls (`stage1/rec/rzx-p2-16000` 519, `stage1/rec/rzx-p2-18000` 517, `stage1/rec/rzx-p2-14000` 511 and 20 more) |
| Called from | `MainLoop` |
| Calls | `LifeLost` (tail), `RexAppears`, `Random2` |
| Reads | `$A0A5`-`$A0E8` (`SparkleMasks`, `SparkleDots`); `$A1EE`-`$A1FB` (`Dying`, `DeathTimer`, `DeathShardPtr`, `RestartX` and 9 more); `$A22C` (`Temp1`); `$A24F`-`$A250` (`RexX`, `RexY`); `$EB00`-`$FFF3` (`BufferPlayOrigin+1`) |
| Writes | `$A0AD`-`$A0E8` (`SparkleDots`); `$A1F6`-`$A1FA` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 1 more); `$A22C` (`Temp1`); `$A250` (`RexY`); `$EB00`-`$FFF3` (`BufferPlayOrigin+1`) |

### Part 2 (REX 2): cells

`src/rex2/cells.asm`

#### `CellsUnderRex` (`$A0F8`)

**Test the cells under Rex and act: the lift (`$12`), the restart marker (7), the shield recharger (8, up to 99), the weapon stations (`$0A-$0D`)**

Changed from REX 1's CellsUnderRex `$9F5F` (src/game/cells.asm).

Witness: L1 8990 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 38,846 t-states own (0.00 %) |
| Runs (the other recordings) | 8,990 calls (`stage1/rec/rzx-p2-14000` 510, `stage1/rec/rzx-p2-04000` 504, `stage1/rec/rzx-p2-32000` 493 and 20 more) |
| Called from | `NewGame`, `MainLoop`, `DeathAnimation`, `RexDies`, `DroneOrbit`, `TitleMenu`, `EnterCode`, `ReadCode`, `DefineKeys` |
| Calls | `SaveRestart` (tail), `Recharge` (tail), `StartJump`, `Land` |
| Reads | `$A093`-`$A095` (`SparkleDotOut+6`); `$A1B2`-`$A1B3` (`RexCellPtr`); `$A1E2`-`$A1E6` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`); `$A250` (`RexY`); `$AAAF`-`$AB40` (`ShardPaths+88`, `ShardPictures`, `GameTexts`); `$D5D2` (`Channels+8`); 7 more ranges |
| Writes | `$A065`-`$A067` (`SparkleMove+26`); `$A093`-`$A095` (`SparkleDotOut+6`); `$A1E6` (`ShieldEnergy`); `$A213` (`OnLift`); `$A22A` (`RexSpeed`); `$A255` (`FallSpeed`) |

#### `Recharge` (`$A187`)

**The recharger (`$08`): ShieldEnergy + 1 up to 99 while the shield is off, the recharge sound**

As REX 1's Recharge `$9FEE` (src/game/cells.asm).

Witness: L1 516 (rzx-p2- x5).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 315 t-states own (0.00 %) |
| Runs (the other recordings) | 407 calls (`stage1/rec/rzx-p2-04000` 154, `stage1/rec/rzx-p2-32000` 146, `stage1/rec/rzx-p2-30000` 105 and 1 more) |
| Called from | `NewGame`, `CellsUnderRex` (tail) |
| Calls | `ShowShield`, `ResetSweep`, `RexJump`, `StartSfx` |
| Reads | `$A1E2`-`$A1E6` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`); `$D5D2` (`Channels+8`); `$E2DA`-`$E2F5` (`RoomGridPlay+219`); `$E3A9` (`RoomGridPlay+426`) |
| Writes | `$A1E6` (`ShieldEnergy`) |

### Part 2 (REX 2): hud

`src/rex2/hud.asm`

#### `HudSweep` (`$A26C`)

**One step of the HUD sweep (none while FadeStepIndex is not `$FF`); every 5 round trips one narrower; the width dropping to 0 kills Rex**

As REX 1's HudSweep `$A0C4` (src/game/hud.asm).

Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 69,334,164 t-states own (4.78 %) |
| Runs (the other recordings) | 10,871 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516 and 20 more) |
| Called from | `MainLoop`, `DroneOrbit`, `BuildRoom`, `Attract` |
| Reads | `$582C`-`$5838` (screen); `$A093`-`$A094` (`SparkleDotOut+6`); `$A1DB` (`FadeStepIndex`); `$A1FD`-`$A200` (`SweepPos`, `SweepCount`, `SweepDir`, `SweepWidth`); `$EB00`-`$FFFD` (`BufferPlayOrigin+1`, `work space $FFFA+`) |
| Writes | `$4061`-`$57FE` (screen); `$582B`-`$5838` (screen); `$A093`-`$A094` (`SparkleDotOut+6`); `$A1FD`-`$A200` (`SweepPos`, `SweepCount`, `SweepDir`, `SweepWidth`); `$E530`-`$E536` (`TitleScreen+49`) |

#### `ResetSweep` (`$A2DB`)

**The sweep back to full width (BuildRoom, RexDies)**

As REX 1's ResetSweep `$A133` (src/game/hud.asm).

Witness: L1 68 (c2, p2-room20, rzx-p2- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 3,025 t-states own (0.00 %) |
| Runs (the other recordings) | 68 calls (`stage1/c2` 7, `stage1/rec/rzx-p2-24000` 6, `stage1/rec/rzx-p2-18000` 6 and 17 more) |
| Called from | `RexDies`, `Recharge`, `FireLatch`, `BuildRoom`, `ReadCode`, `ScanKey` |
| Calls | `PrintBoxed` |
| Writes | `$A1FE`-`$A200` (`SweepCount`, `SweepDir`, `SweepWidth`) |

#### `PrintBoxed` (`$A2E6`)

**Print B text records from IX in a framed box (attribute A, box from the first record), the panel sound**

As REX 1's PrintBoxed `$A13E` (src/game/hud.asm).

Witness: L1 17 (c2, rzx-p2-00000, rzx-p2-40000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 44 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 824,016 t-states own (0.06 %) |
| Runs (the other recordings) | 17 calls (`stage1/c2` 13, `stage1/rec/rzx-p2-00000` 3, `stage1/rec/rzx-p2-40000` 1) |
| Called from | `NewGame`, `BossExplodes`, `ResetSweep`, `TitleMenu`, `EnterCode`, `ReadCode`, `Confirm` |
| Calls | `PrintTextHL`, `PanelBox` |
| Reads | `$60E0`-`$611F`; `$6150`-`$6197`; `$61A8`-`$61B7` (`DevLink`); `$61E0`-`$62AF` (`DevLink+56`); `$62C0`-`$62DF` (`DevLink+280`, `DevLinkGet`, `DevLinkPut`); `$A093`-`$A097` (`SparkleDotOut+6`); 10 more ranges |
| Writes | `$400C`-`$490D` (screen); `$4947`-`$4A0D` (screen); `$4A47`-`$4B0D` (screen); `$4B47`-`$4C0D` (screen); `$4C47`-`$4D0D` (screen); `$4D47`-`$4E0D` (screen); 10 more ranges |

#### `DrawHud` (`$A34D`)

**Draw the HUD: its texts (HudTexts `$A3F4`), the frame, the weapon icons and the bombs**

As REX 1's DrawHud `$A1A5` (src/game/hud.asm).

Witness: L1 5 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 419 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 5 calls (`stage1/c2` 4, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `NewGame` |
| Calls | `ShowWeaponIcons`, `PrintTextHL`, `FillAttrs` |
| Reads | `$A205` (`Bombs`) |

#### `ShowBombs` (`$A371`)

**Draw the bomb icons for Bombs `$A205` (BombIcons `$A3AA`)**

As REX 1's ShowBombs `$A1C9` (src/game/hud.asm).

Witness: L1 6 (c2, rzx-p2-00000, rzx-p2-28000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 260,929 t-states own (0.02 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/rzx-p2-28000` 1) |
| Called from | `SmartBomb`, `ColourPiece`, `DeathAnimation`, `LifeLost`, `PowerDrain`, `SaveAttrs`, `FlashCells`, `UpdateObject`, `DrawObject`, `Kind3Grow`, `WalkLeft`, `SpawnScripted`, `SpawnAnywhere` |
| Calls | `DrawBombIcons` |
| Reads | `$A0A1` (`SparkleDotStore2+2`); `$A205` (`Bombs`) |
| Writes | `$A0A1` (`SparkleDotStore2+2`) |

#### `DrawBombIcons` (`$A383`)

**Three icons from HL: the column at `$A1F3` from 25**

As REX 1's DrawBombIcons `$A1DB` (src/game/hud.asm).

Witness: L1 6 (c2, rzx-p2-00000, rzx-p2-28000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,565 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,210,054 t-states own (0.08 %) |
| Runs (the other recordings) | 6 calls (`stage1/c2` 4, `stage1/rec/rzx-p2-00000` 1, `stage1/rec/rzx-p2-28000` 1) |
| Called from | `ColourPiece`, `InkRow3`, `SparkleUpdate`, `SparkleOut`, `ShowBombs`, `UpdateObject` |
| Calls | `DrawHudIcon` (falls into) |
| Reads | `$A093`-`$A0A3` (`SparkleDotOut+6`, `SparkleDotStore2`) |
| Writes | `$A093`-`$A0A3` (`SparkleDotOut+6`, `SparkleDotStore2`); `$A39B` (`HudIconParams+2`) |

#### `DrawHudIcon` (`$A38A`)

**One HUD icon: SpriteHudIcons `$8AC0` + offset (HL), by DrawCharBlock `$D658` with the inline parameters**

As REX 1's DrawHudIcon `$A1E2` (src/game/hud.asm).

Witness: L1 18 (c2, rzx-p2-00000, rzx-p2-28000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/c2` 12, `stage1/rec/rzx-p2-28000` 3, `stage1/rec/rzx-p2-00000` 3) |
| Called from | `DrawBombIcons` (falls into), `NextHudIcon` (tail) |
| Calls | `DrawCharBlock` |
| Reads | `$A3AA`-`$A3AC` (`BombIcons`) |
| Writes | `$A399`-`$A39A` (`HudIconParams`) |

#### `NextHudIcon` (`$A39F`)

**The next icon two columns on**

As REX 1's NextHudIcon `$A1F7` (src/game/hud.asm).

Witness: L1 18 (c2, rzx-p2-00000, rzx-p2-28000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/c2` 12, `stage1/rec/rzx-p2-00000` 3, `stage1/rec/rzx-p2-28000` 3) |
| Called from | `DrawCharBlock` |
| Calls | `DrawHudIcon` (tail) |
| Reads | `$A39B` (`HudIconParams+2`) |
| Writes | `$A39B` (`HudIconParams+2`) |

#### `ShowWeaponIcons` (`$A3BA`)

**Draw the weapon icons: WeaponIcon `$A1E8` selects the lit one**

As REX 1's ShowWeaponIcons `$A212` (src/game/hud.asm).

Witness: L1 5 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/c2` 4, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `DrawHud` |
| Calls | `DrawWeaponIcon` (falls into) |
| Writes | `$A3DD` (`WeaponIconParams+2`) |

#### `DrawWeaponIcon` (`$A3C7`)

**One weapon icon: SpriteHudIcons2 `$8B60` + offset, DrawCharBlock with the inline parameters**

As REX 1's DrawWeaponIcon `$A21F` (src/game/hud.asm).

Witness: L1 25 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 10,078 t-states own (0.00 %) |
| Runs (the other recordings) | 25 calls (`stage1/c2` 20, `stage1/rec/rzx-p2-00000` 5) |
| Called from | `FadeStep`, `BossExplodes`, `ExplosionAreas`, `ShowWeaponIcons` (falls into), `NextWeaponIcon` (tail) |
| Calls | `DrawCharBlock` |
| Reads | `$A0A6`-`$A0AA` (`SparkleMasks+1`); `$A1E8`-`$A1EC` (`WeaponIcon`, `HasDoubleFire`, `HasLaser`, `HasMultiple` and 1 more); `$ABDD`-`$ABDE` (`EndingText+111`); `$AC9D`-`$AC9E` (`ScreenLineTable+3`); `$ACDD`-`$ACDE` (`ScreenLines+19`) |
| Writes | `$A3DB`-`$A3DC` (`WeaponIconParams`) |

#### `NextWeaponIcon` (`$A3E1`)

**The next weapon icon two columns on**

As REX 1's NextWeaponIcon `$A239` (src/game/hud.asm).

Witness: L1 25 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 calls (`stage1/c2` 20, `stage1/rec/rzx-p2-00000` 5) |
| Called from | `DrawCharBlock` |
| Calls | `DrawWeaponIcon` (tail), `HudTexts` |
| Reads | `$A3DD` (`WeaponIconParams+2`) |
| Writes | `$A3DD` (`WeaponIconParams+2`) |

#### `BufferToScreen` (`$A432`)

**Copy the back buffer's 168 play lines to the screen through ScreenLines `$ACCA` (the stack as the pointer)**

As REX 1's BufferToScreen `$A28A` (src/game/hud.asm).

Witness: L1 10900 (c2, p2-room20, rzx-p2- x21).

[Animation: `BufferToScreen` at work](img/routines/BufferToScreen.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 18 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 22,700,864 t-states own (1.56 %) |
| Runs (the other recordings) | 10,900 calls (`stage1/c2` 931, `stage1/rec/rzx-p2-16000` 519, `stage1/rec/rzx-p2-18000` 519 and 20 more) |
| Called from | `MainLoop`, `WaitFire`, `ShowPointsUnused`, `HudTexts`, `PrintText`, `BuildRoom`, `Attract`, `ScanKey`, `DefineTaken` |
| Reads | `$A0A4`-`$A0AE` (`SparkleDotStore2+5`, `SparkleMasks`); `$A22C`-`$A22D` (`Temp1`); `$EB00`-`$FFFD` (`BufferPlayOrigin+1`, `work space $FFFA+`) |
| Writes | `$4061`-`$57FE` (screen); `$A0A4`-`$A0A5` (`SparkleDotStore2+5`, `SparkleMasks`); `$A22C`-`$A22D` (`Temp1`); `$A478`-`$A49A` (`BufferLine+57`, `PrintTextHL`, `PrintChar`) |
| Ports in | `$DFFE` |

#### `PrintTextHL` (`$A487`)

**Print the text record at HL (PrintText)**

As REX 1's PrintTextHL `$A2DF` (src/game/hud.asm).

Witness: L1 92 (c2, rzx-p2-00000, rzx-p2-40000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 21,265 t-states own (0.00 %) |
| Runs (the other recordings) | 54 calls (`stage1/c2` 49, `stage1/rec/rzx-p2-00000` 4, `stage1/rec/rzx-p2-40000` 1) |
| Called from | `MainLoop`, `PrintBoxed`, `DrawHud`, `ReadCode` |
| Calls | `PrintText` |
| Reads | `$A0AE` (`SparkleDots+1`) |
| Ports in | `$FBFE` |

#### `PrintChar` (`$A491`)

**Print character A at column Temp2, line Temp3 (pixels) from Font `$6306` through ScreenLineTable `$AC9A`**

As REX 1's PrintChar `$A2E9` (src/game/hud.asm).

Witness: L1 1224 (c2, rzx-p2-00000, rzx-p2-40000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 21,568 t-states own (0.00 %) |
| Runs (the other recordings) | 1,224 calls (`stage1/c2` 992, `stage1/rec/rzx-p2-00000` 136, `stage1/rec/rzx-p2-40000` 96) |
| Called from | `MainLoop`, `PrintText`, `ScanKey` |
| Reads | `$A0AB`-`$A0AE` (`SparkleMasks+6`, `SparkleDots`); `$A230` (`Temp3`); `$A3F7`-`$A430` (`HudTexts+3`); `$AAFA`-`$AB2F` (`GameTexts+3`); `$AB71`-`$ABFC` (`EndingText+3`, `PressFireText`); `$DCAA`-`$DD06` (`CodeTexts+3`); 1 more ranges |
| Writes | `$A4AA`-`$A4B3` (`PrintChar+25`, `PrintText`) |
| Ports in | `$FBFE` |

#### `PrintText` (`$A4AF`)

**Print a text record: [attribute][column][line] characters, 0 ends; the attributes set**

As REX 1's PrintText `$A307` (src/game/hud.asm).

Witness: L1 92 (c2, rzx-p2-00000, rzx-p2-40000).

[Animation: `PrintText` at work](img/routines/PrintText.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 3,092,660 t-states own (0.21 %) |
| Runs (the other recordings) | 92 calls (`stage1/c2` 78, `stage1/rec/rzx-p2-00000` 9, `stage1/rec/rzx-p2-40000` 5) |
| Called from | `MainLoop`, `PrintTextHL`, `MoveShots`, `Kind9Fan`, `ObjectFall`, `FindGround`, `HitObject`, `CodeDone`, `ScanKey` |
| Calls | `BufferToScreen`, `PrintChar`, `SfxGun`, `Channels` |
| Reads | `$6306`-`$6345` (`Font`); `$6376`-`$63DD` (`Font+112`); `$63FE`-`$6505` (`Font+248`); `$A0AB`-`$A0B0` (`SparkleMasks+6`, `SparkleDots`); `$A22C`-`$A230` (`Temp1`, `Temp2`, `Temp3`); `$A3F4`-`$A431` (`HudTexts`); 16 more ranges |
| Writes | `$400C`-`$57DE` (screen); `$580C`-`$585C` (screen); `$5946`-`$5A1C` (screen); `$5A57`-`$5A5C` (screen); `$5A75`-`$5A7C` (screen); `$5A95`-`$5ABC` (screen); 11 more ranges |
| Ports in | `$BFFE`, `$DFFE` |

#### `UnusedRandom` (`$A510`)

**A = the byte at RandomSeed `$A23A`, the seed + 1 within `$0000-$3FFF`; nothing calls it (leftover)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3,839 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Random` (`$A51D`)

**A = a random byte: the byte at RandomSeed `$A23A` (walking `$0000-$3FFF`, the ROM) plus R**

As REX 1's Random `$A375` (src/game/hud.asm).

Witness: L1 24087 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24,087 calls (`stage1/c2` 2,350, `stage1/rec/rzx-p2-24000` 1,803, `stage1/rec/rzx-p2-12000` 1,579 and 20 more) |
| Called from | `DrawRex`, `BossExplodes`, `SparkleUpdate`, `UpdateObject`, `Kind4Crawl`, `Kind4MaybeStop`, `Kind5Burst`, `Kind5Rest`, `Kind9Rest`, `BlowUp`, `MaybeJumpRight`, `MaybeJumpLeft`, `MaybeDissolve`, `SetHop`, `MaybeJumper`, `SpawnAnywhere` |
| Reads | `$A23A` (`RandomSeed`) |
| Writes | `$A23A` (`RandomSeed`) |

#### `Random2` (`$A530`)

**A = a random byte from RandomSeed2 `$A23C` and R**

As REX 1's Random2 `$A388` (src/game/hud.asm).

Witness: L1 60211 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,912 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 133,602 t-states own (0.01 %) |
| Runs (the other recordings) | 60,211 calls (`stage1/rec/rzx-p2-18000` 4,768, `stage1/rec/rzx-p2-16000` 4,746, `stage1/rec/rzx-p2-30000` 3,765 and 20 more) |
| Called from | `BossExplodes`, `ObjectDissolve`, `SparkleDraw`, `Kind5Burst`, `SpawnAnywhere`, `InitKind2`, `EnemyBulletsHitRex` |
| Reads | `$A0AF`-`$A0B0` (`SparkleDots+2`); `$A22C`-`$A23C` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 4 more) |
| Writes | `$A22C`-`$A23C` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 4 more) |

#### `ClearScreen` (`$A556`)

**Clear the screen's bitmap and attributes**

As REX 1's ClearScreen `$A3AE` (src/game/hud.asm).

Witness: L1 5 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 600 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 581,858 t-states own (0.04 %) |
| Runs (the other recordings) | 5 calls (`stage1/c2` 4, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `NewGame`, `ShieldToggle`, `Attract` |
| Reads | `$4000`-`$5AFE` (screen); `$A017` (`SparkleDots2+17`); `$AE8D`-`$AECC` (`MirrorTable+59`) |
| Writes | `$4000`-`$5AFF` (screen); `$6BC0`-`$6BDF` (`AnimChar73+882`) |

#### `PrintDigits` (`$A570`)

**Print B digits of Digits `$A23F` at HL on the screen**

As REX 1's PrintDigits `$A3C8` (src/game/hud.asm).

Witness: L1 801 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 801 calls (`stage1/rec/rzx-p2-32000` 140, `stage1/rec/rzx-p2-04000` 133, `stage1/rec/rzx-p2-30000` 122 and 19 more) |
| Called from | `ShowScore`, `ShowLives`, `ShowShield` |
| Calls | `ScreenDown`, `ToDigits` |
| Reads | `$A23F`-`$A243` (`Digits`); `$AC9A`-`$AC9B` (`ScreenLineTable`) |

#### `ScreenDown` (`$A5A1`)

**HL one pixel line down the screen**

As REX 1's ScreenDown `$A3F9` (src/game/hud.asm).

Witness: L1 1858 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 699 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 37,746 t-states own (0.00 %) |
| Runs (the other recordings) | 1,858 calls (`stage1/rec/rzx-p2-32000` 301, `stage1/rec/rzx-p2-04000` 275, `stage1/rec/rzx-p2-30000` 257 and 19 more) |
| Called from | `PrintDigits` |
| Calls | `ToDigits` (tail) |
| Reads | `$6386`-`$63D5` (`Font+128`) |
| Writes | `$400C`-`$4017` (screen); `$410C`-`$4117` (screen); `$420C`-`$4217` (screen); `$430C`-`$4317` (screen); `$440C`-`$4417` (screen); `$450C`-`$4517` (screen); 2 more ranges |

#### `ToDigits` (`$A5AA`)

**HL into five decimal digits at Digits `$A23F` (units first)**

As REX 1's ToDigits `$A402` (src/game/hud.asm).

Witness: L1 801 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,129,814 t-states own (0.08 %) |
| Runs (the other recordings) | 801 calls (`stage1/rec/rzx-p2-32000` 140, `stage1/rec/rzx-p2-04000` 133, `stage1/rec/rzx-p2-30000` 122 and 19 more) |
| Called from | `ShowScore`, `ShowLives`, `ShowShield`, `DeathAnimation`, `PrintDigits`, `ScreenDown` (tail) |
| Calls | `DigitOf` |
| Reads | `$8D2A`-`$8D89` (`SpriteKind2+10`); `$9412`-`$9471` (`ExplosionPicture+658`, `GameEntry`); `$A069`-`$A06B` (`SparkleMove+30`); `$A07C` (`SparkleDotIn+12`); `$A093`-`$A096` (`SparkleDotOut+6`); `$A5F4`-`$A626` (`DigitOf+5`, `SetFire`, `ReadFire`) |
| Writes | `$6600`-`$6607` (`CharFlags+250`, `CharGraphics`); `$67D8`-`$67DF` (`CharGraphics+466`); `$6BA8`-`$6BBF` (`AnimChar73+858`); `$A069`-`$A06B` (`SparkleMove+30`); `$A07C` (`SparkleDotIn+12`); `$A093`-`$A096` (`SparkleDotOut+6`); 1 more ranges |

#### `DigitOf` (`$A5EF`)

**One digit: count how many times DE goes into HL**

As REX 1's DigitOf `$A447` (src/game/hud.asm).

Witness: L1 4005 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,005 calls (`stage1/rec/rzx-p2-32000` 700, `stage1/rec/rzx-p2-04000` 665, `stage1/rec/rzx-p2-30000` 610 and 19 more) |
| Called from | `ToDigits` |
| Reads | `$A23D`-`$A23E` (`DigitTemp`) |
| Writes | `$A23D`-`$A23E` (`DigitTemp`) |

### Part 2 (REX 2): controls

`src/rex2/controls.asm`

#### `SetFire` (`$A612`)

**Fire reads DefinePort `$A244`, bit DefineBit `$A246` (the operands at `$A620`, `$A629`)**

As REX 1's SetFire `$A46A` (src/game/controls.asm).

Witness: L1 2 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 1, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `ChooseSinclair` |
| Reads | `$A244`-`$A246` (`DefinePort`, `DefineBit`) |
| Writes | `$A620`-`$A629` (`ReadFire+1`) |

#### `ReadFire` (`$A61F`)

**Z = fire pressed (default O, `$DFFE` bit 1)**

As REX 1's ReadFire `$A477` (src/game/controls.asm).

Witness: L1 349448 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 832 t-states own (0.00 %) |
| Runs (the other recordings) | 349,448 calls (`stage1/c2` 275,433, `stage1/rec/rzx-p2-00000` 37,017, `stage2/rec/p2-room20` 20,510 and 20 more) |
| Called from | `NewGame`, `MainLoop`, `WaitFireOrAttract`, `Pause`, `Attract` |
| Reads | `$A247` (`ControlXor`) |
| Writes | `$5E50`-`$5E65` |
| Ports in | `$EFFE` |

#### `SetLeft` (`$A62B`)

**Left reads DefinePort, DefineBit**

As REX 1's SetLeft `$A483` (src/game/controls.asm).

Witness: L1 2 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 calls (`stage1/c2` 1, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `ChooseSinclair` |
| Reads | `$A244`-`$A246` (`DefinePort`, `DefineBit`) |
| Writes | `$A639`-`$A642` (`ReadLeft+1`, `ReadLeftBit`) |

#### `ReadLeft` (`$A638`)

**Z = left pressed (default Q)**

As REX 1's ReadLeft `$A490` (src/game/controls.asm).

Witness: L1 8904 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 27,336 t-states own (0.00 %) |
| Runs (the other recordings) | 8,904 calls (`stage1/rec/rzx-p2-14000` 511, `stage1/rec/rzx-p2-04000` 505, `stage1/rec/rzx-p2-32000` 493 and 20 more) |
| Called from | `MainLoop` |
| Reads | `$A013` (`SparkleDots2+13`); `$A055` (`SparkleMove+10`); `$A247` (`ControlXor`) |
| Ports in | `$EFFE` |

#### `SetRight` (`$A644`)

**Right reads DefinePort, DefineBit**

As REX 1's SetRight `$A49C` (src/game/controls.asm).

Witness: L1 2 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 1, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `ChooseSinclair` |
| Reads | `$A244`-`$A246` (`DefinePort`, `DefineBit`) |
| Writes | `$A652`-`$A65B` (`ReadRight+1`) |

#### `ReadRight` (`$A651`)

**Z = right pressed (default W)**

As REX 1's ReadRight `$A4A9` (src/game/controls.asm).

Witness: L1 8904 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,904 calls (`stage1/rec/rzx-p2-14000` 511, `stage1/rec/rzx-p2-04000` 505, `stage1/rec/rzx-p2-32000` 493 and 20 more) |
| Called from | `MainLoop` |
| Reads | `$A247` (`ControlXor`) |
| Ports in | `$EFFE` |

#### `SetUp` (`$A65D`)

**Up reads DefinePort, DefineBit**

As REX 1's SetUp `$A4B5` (src/game/controls.asm).

Witness: L1 2 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 1, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `ChooseSinclair` |
| Reads | `$A244`-`$A246` (`DefinePort`, `DefineBit`) |
| Writes | `$A66B`-`$A674` (`ReadUp+1`, `ReadUpBit`) |

#### `ReadUp` (`$A66A`)

**Z = up (jump) pressed (default I)**

As REX 1's ReadUp `$A4C2` (src/game/controls.asm).

Witness: L1 9003 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,003 calls (`stage1/rec/rzx-p2-14000` 511, `stage1/rec/rzx-p2-04000` 505, `stage1/rec/rzx-p2-32000` 493 and 20 more) |
| Called from | `MainLoop` |
| Reads | `$A247` (`ControlXor`) |
| Ports in | `$EFFE` |

#### `SetDown` (`$A676`)

**Down reads DefinePort, DefineBit**

As REX 1's SetDown `$A4CE` (src/game/controls.asm).

Witness: L1 2 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 1, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `ChooseSinclair` |
| Reads | `$A244`-`$A246` (`DefinePort`, `DefineBit`) |
| Writes | `$A684`-`$A68D` (`ReadDown+1`, `ReadDownBit`) |

#### `ReadDown` (`$A683`)

**Z = down (the shield) pressed (default J)**

As REX 1's ReadDown `$A4DB` (src/game/controls.asm).

Witness: L1 20852 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20,852 calls (`stage1/rec/rzx-p2-16000` 1,036, `stage1/rec/rzx-p2-18000` 1,032, `stage1/rec/rzx-p2-14000` 1,022 and 20 more) |
| Called from | `MainLoop` |
| Reads | `$A247` (`ControlXor`) |
| Ports in | `$EFFE` |

#### `Pause` (`$A68F`)

**H: silence; loop while fire is not pressed (ReadFire); the sound back**

As REX 1's Pause `$A4E7` (src/game/controls.asm).

Witness: L1 20392 (p2-room20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/p2-room20` 1) |
| Called from | `MainLoop` |
| Calls | `ReadFire`, `SoundReset`, `SoundSilence` |

#### `OrChar` (`$A69C`)

**OR the 8 bytes at DE into the buffer at HL (32-byte rows)**

As REX 1's OrChar `$A4F4` (src/game/controls.asm).

Witness: L1 12228 (c2, p2-room20, rzx-p2- x20).

[Animation: `OrChar` at work](img/routines/OrChar.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,228 calls (`stage1/rec/rzx-p2-38000` 1,248, `stage1/rec/rzx-p2-26000` 1,056, `stage1/rec/rzx-p2-24000` 960 and 19 more) |
| Called from | `DrawShard` |
| Reads | `$AAB7`-`$AAF6` (`ShardPictures`); `$EAFF`-`$EBDF` (`BufferPlayOrigin`); `$EC01`-`$FFBF` (`BufferPlayOrigin+258`) |
| Writes | `$EAFF`-`$EBDF` (`BufferPlayOrigin`); `$EC01`-`$FFBF` (`BufferPlayOrigin+258`) |

### Part 2 (REX 2): grid

`src/rex2/grid.asm`

#### `CellPointer` (`$A6AB`)

**HL = the grid cell of SpriteX/SpriteY (`$E19F` + 32 x (Y / 8) + X / 8; A = 1 the grid from `$E19E`)**

As REX 1's CellPointer `$A503` (src/game/grid.asm).

Witness: L1 115349 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 115,349 calls (`stage1/rec/rzx-p2-38000` 7,818, `stage1/rec/rzx-p2-36000` 7,804, `stage1/rec/rzx-p2-12000` 6,787 and 20 more) |
| Called from | `MainLoop`, `StepShot`, `ObjectJump`, `ObjectCell`, `FindGround`, `RexFall` |
| Reads | `$A248`-`$A249` (`SpriteX`, `SpriteY`) |

#### `BufferAddress` (`$A6DD`)

**HL = the back buffer address of SpriteX / SpriteY**

As REX 1's BufferAddress `$A535` (src/game/grid.asm).

Witness: L1 3102 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,102 calls (`stage1/rec/rzx-p2-40000` 1,064, `stage1/rec/rzx-p2-38000` 208, `stage1/rec/rzx-p2-26000` 176 and 20 more) |
| Called from | `ColourPiece`, `FlashCells` |
| Reads | `$A248`-`$A249` (`SpriteX`, `SpriteY`) |

#### `AnimateCells` (`$A706`)

**Each pass: characters 252-255 from AnimFramesA `$AF82` or AnimFramesB `$AFA2` (alternate passes, `$A1B0`), then the 16-byte animation at `$6DD6` by FramesList2 `$A789`**

Changed from REX 1's AnimateCells `$A55E` (src/game/grid.asm).

Witness: L1 10855 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,855 calls (`stage1/c2` 923, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 515 and 20 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `AnimateCells2` |
| Reads | `$A1B0` (`PassToggle`); `$AF82`-`$AFC1` (`AnimFramesA`, `AnimFramesB`) |
| Writes | `$6DE6`-`$6E05` (`AnimChar252`) |

#### `AnimateCells2` (`$A730`)

**The frames of characters 250-251 from FramesList2 `$A789`**

As REX 1's AnimateCells2 `$A5A7` (src/game/grid.asm).

Witness: L1 10855 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,855 calls (`stage1/c2` 923, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 515 and 20 more) |
| Called from | `AnimateCells` |
| Calls | `CopyFrame` (tail) |
| Reads | `$8A90`-`$8ABF` (`SpriteShield+376`); `$A203` (`AnimCount2`); `$A22C`-`$A22F` (`Temp1`, `Temp2`); `$A789`-`$A791` (`FramesList2`) |
| Writes | `$6DD6`-`$6DE5` (`AnimChar250`); `$A203` (`AnimCount2`); `$A22C`-`$A22F` (`Temp1`, `Temp2`) |

#### `AnimateRestart` (`$A740`)

**The restart marker's frames (character 249, FramesList3 `$A77D`)**

As REX 1's AnimateRestart `$A5B7` (src/game/grid.asm).

Witness: L1 375 (c2, p2-room20, rzx-p2- x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 375 calls (`stage1/rec/rzx-p2-08000` 61, `stage1/rec/rzx-p2-06000` 36, `stage1/rec/rzx-p2-10000` 36 and 14 more) |
| Called from | `SaveRestart` |
| Calls | `CopyFrame` (falls into) |

#### `CopyFrame` (`$A74D`)

**Copy the frame at HL into the character at DE (8 bytes), from the list position Temp1**

As REX 1's CopyFrame `$A5C4` (src/game/grid.asm).

Witness: L1 11230 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,604 calls (`stage1/c2` 958, `stage1/rec/rzx-p2-08000` 570, `stage1/rec/rzx-p2-16000` 545 and 14 more) |
| Called from | `AnimateCells2` (tail), `AnimateRestart` (falls into) |
| Reads | `$8A68`-`$8ABF` (`SpriteShield+336`); `$A202`-`$A203` (`AnimCount1`, `AnimCount2`); `$A22C`-`$A22F` (`Temp1`, `Temp2`); `$A77D`-`$A791` (`FramesList3`, `FramesList2`) |
| Writes | `$684E`-`$6855` (`AnimChar73`); `$6DD6`-`$6DE5` (`AnimChar250`); `$A202`-`$A203` (`AnimCount1`, `AnimCount2`); `$A22C`-`$A22F` (`Temp1`, `Temp2`) |

#### `InitDrones` (`$A793`)

**The drones' table at `$5E50`: 8 records of 3 bytes, the angles 0, 8, 16, ... 56**

As REX 1's InitDrones `$A628` (src/game/grid.asm).

Witness: L1 18 (c2, rzx-p2- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/c2` 4, `stage1/rec/rzx-p2-14000` 4, `stage1/rec/rzx-p2-28000` 2 and 7 more) |
| Called from | `NewGame`, `PowerGain` |
| Writes | `$5E50`-`$5E65` |

#### `UpdateDrones` (`$A7A4`)

**The multiple weapon (Weapon 3): the drones orbit Rex (DroneOrbit `$A836`) and are drawn (DronePicture `$A8B6`), one per power level**

As REX 1's UpdateDrones `$A639` (src/game/grid.asm).

Witness: L1 10440 (c2, p2-room20, rzx-p2- x21).

[Animation: `UpdateDrones` at work](img/routines/UpdateDrones.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 762,216 t-states own (0.05 %) |
| Runs (the other recordings) | 10,440 calls (`stage1/rec/rzx-p2-16000` 519, `stage1/rec/rzx-p2-18000` 517, `stage1/rec/rzx-p2-14000` 511 and 20 more) |
| Called from | `MainLoop`, `SoundOffReturn`, `ShieldToggle`, `Attract` |
| Reads | `$5E4E`-`$5E65`; `$6438`-`$643F` (`Font+306`); `$64B0`-`$64C7` (`Font+426`); `$A1AC`-`$A1AD` (`Weapon`, `PowerLevel`); `$A1EE`-`$A1F9` (`Dying`, `DeathTimer`, `DeathShardPtr`, `RestartX` and 7 more); `$A24F`-`$A250` (`RexX`, `RexY`); 8 more ranges |
| Writes | `$5E4E`-`$5E65`; `$6438`-`$643F` (`Font+306`); `$64B0`-`$64C7` (`Font+426`); `$EC46`-`$FCA3` (`BufferPlayOrigin+327`); `$FCB5`-`$FCC3` (`BufferPlayOrigin+4534`); `$FCD5`-`$FD22` (`BufferPlayOrigin+4566`); 4 more ranges |

### Part 2 (REX 2): weapons

`src/rex2/weapons.asm`

#### `GiveDoubleFire` (`$A8F6`)

**The double fire station: HasDoubleFire `$A1E9` = 1, then GiveWeapon**

As REX 1's GiveDoubleFire `$A78B` (src/game/weapons.asm).

Known only from the code: no room of REX 2 holds a weapon station. The characters whose CharFlags `$6506` type is `$0A-$0D` appear in no block of the 26 rooms' maps (the recharger `$08` does, in rooms 4, 9, 12, 15, 20, 21 and 22), so GiveDoubleFire, GiveLaser, GiveMultiple, GiveSpray and WeaponPanel `$D609` are REX 1's code kept; the weapons come from the access code (EnterCode `$DB27`).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GiveLaser` (`$A8FC`)

**The laser station: HasLaser `$A1EA` = 1**

As REX 1's GiveLaser `$A791` (src/game/weapons.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ReadExits` |

#### `GiveMultiple` (`$A902`)

**The multiple station: HasMultiple `$A1EB` = 1**

As REX 1's GiveMultiple `$A797` (src/game/weapons.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `BossExplodes` |

#### `GiveSpray` (`$A908`)

**The spray station: HasSpray `$A1EC` = 1; GiveWeapon: the icons shown, the best weapon chosen (BestWeapon `$BA52`)**

As REX 1's GiveSpray `$A79D` (src/game/weapons.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 7 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `RollCharUp` (`$A914`)

**Roll an 8-byte character at HL one line up (REX 1's conveyor roll; nothing calls it in part 2)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 139,079 t-states own (0.01 %) |
| Called from | `NewGame` (tail) |
| Reads | `$6758`-`$675F` (`CharGraphics+338`); `$6858`-`$685F` (`AnimChar73+10`); `$A017` (`SparkleDots2+17`); `$A0C2`-`$A0C3` (`SparkleDots+21`); `$A90C` (`GiveWeapon+1`) |
| Writes | `$6758`-`$675F` (`CharGraphics+338`); `$6858`-`$685F` (`AnimChar73+10`); `$A017` (`SparkleDots2+17`); `$A0B8`-`$A0C3` (`SparkleDots+11`) |

#### `RollCharDown` (`$A925`)

**Roll an 8-byte character at HL one line down (nothing calls it in part 2)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `FireDouble` (`$B452`)

**Double fire's second shot**

As REX 1's FireDouble `$B40C` (src/game/weapons.asm).

Witness: L1 2 (c2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 2) |
| Called from | `FireWeapon` (tail) |
| Calls | `FindShotSlot`, `SetupShot` |
| Reads | `$A1AC` (`Weapon`) |
| Writes | `$A232` (`Temp4`) |

#### `FireLaser` (`$B463`)

**The laser's beam**

As REX 1's FireLaser `$B41D` (src/game/weapons.asm).

Witness: L1 74 (c2, rzx-p2-00000, rzx-p2-02000, rzx-p2-04000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21 calls (`stage1/rec/rzx-p2-00000` 13, `stage1/c2` 8) |
| Called from | `FireWeapon` (tail) |
| Calls | `RexShot` |
| Reads | `$5B60`; `$5B7E`-`$5B9C`; `$5BBA`; `$5BD8`; `$5BF6`; `$A201` (`FireDelay`) |
| Writes | `$5B65`-`$5B6E`; `$5B83`-`$5BAA`; `$5BBF`-`$5BC8`; `$5BDD`-`$5BE6`; `$5BFB`-`$5C04` |

#### `FireSpray` (`$B49C`)

**The spray: at power 1-3 a fan of 3, 5 or 7 shots ahead (SprayShot); at power 4 the four directions, at 5 all eight (SprayDirections)**

As REX 1's FireSpray `$B456` (src/game/weapons.asm).

Witness: L1 623 (rzx-p2- x15).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 10,778 t-states own (0.00 %) |
| Runs (the other recordings) | 623 calls (`stage1/rec/rzx-p2-38000` 82, `stage1/rec/rzx-p2-36000` 72, `stage1/rec/rzx-p2-22000` 71 and 12 more) |
| Called from | `ReturnToStack`, `FireWeapon` (tail), `Kind4Crawl` |
| Calls | `SetShotDirection`, `SetShotSpeed`, `FindShotSlot`, `RexShot` |
| Reads | `$5D29`-`$5DA2`; `$A013`-`$A014` (`SparkleDots2+13`); `$A1AD` (`PowerLevel`) |
| Writes | `$5B65`-`$5C19`; `$5C37`; `$5C55`-`$5C64`; `$5C82`; `$5CA0`; `$5D09`; 2 more ranges |

#### `SetShotDirection` (`$B519`)

**A shot's direction from the record at HL: dX word, dY, its picture**

As REX 1's SetShotDirection `$B4D3` (src/game/weapons.asm).

Witness: L1 2716 (rzx-p2- x13).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 37,587 t-states own (0.00 %) |
| Runs (the other recordings) | 2,716 calls (`stage1/rec/rzx-p2-38000` 616, `stage1/rec/rzx-p2-32000` 368, `stage1/rec/rzx-p2-20000` 328 and 10 more) |
| Called from | `FireSpray`, `FindSlot` (tail) |
| Calls | `SetShotSpeed` |
| Reads | `$5B66`; `$5D28`-`$5DAF`; `$A013` (`SparkleDots2+13`); `$A07B` (`SparkleDotIn+11`); `$B47C`-`$B49B` (`SprayDirections`); `$D842` (`DebugHook+380`) |
| Writes | `$5B64`-`$5D0C` |

#### `SetShotSpeed` (`$B530`)

**A shot's speed A into its record (dY x 32 added to the grid step)**

As REX 1's SetShotSpeed `$B4EA` (src/game/weapons.asm).

Witness: L1 4181 (c2, rzx-p2- x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,181 calls (`stage1/rec/rzx-p2-38000` 616, `stage1/rec/rzx-p2-32000` 448, `stage1/rec/rzx-p2-36000` 356 and 17 more) |
| Called from | `FireSpray`, `SetShotDirection`, `SwingShotSet` |
| Reads | `$5B67`-`$5D0C`; `$5D29`-`$5E29` |
| Writes | `$5B65`-`$5D0C`; `$5D27`-`$5E29` |

#### `FindShotSlot` (`$B54C`)

**IY = a free slot among Rex's bullets (as many as the power level allows for the gun and double fire); none: IY = `$03E8`**

As REX 1's FindShotSlot `$B506` (src/game/weapons.asm).

Witness: L1 6432 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,432 calls (`stage1/rec/rzx-p2-38000` 698, `stage1/rec/rzx-p2-36000` 523, `stage1/rec/rzx-p2-12000` 494 and 20 more) |
| Called from | `FireWeapon`, `FireDouble`, `FireSpray`, `MoveSplitShot` |
| Calls | `FindSlot` (tail), `Channels` |
| Reads | `$5B66`-`$5D0A`; `$A1AC`-`$A1AD` (`Weapon`, `PowerLevel`); `$A214` (`ShotSide`) |
| Writes | `$A214` (`ShotSide`) |

#### `FindSlot` (`$B56E`)

**Search E slots from IY for a free one; the shot's sound by weapon (gun `$D4FB`, laser `$D50D`, spray `$D516`; the enemies' `$D504`)**

As REX 1's FindSlot `$B528` (src/game/weapons.asm).

Witness: L1 7579 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 15,926 t-states own (0.00 %) |
| Runs (the other recordings) | 7,092 calls (`stage1/rec/rzx-p2-38000` 803, `stage1/rec/rzx-p2-12000` 757, `stage1/rec/rzx-p2-36000` 529 and 18 more) |
| Called from | `FindShotSlot` (tail), `FindEnemySlot` (tail), `FlashCells`, `UpdateObjects`, `UpdateObject`, `DrawObject`, `Kind4Crawl`, `Kind4MaybeStop` |
| Calls | `SetShotDirection` (tail), `LaserSound`, `SpraySound`, `EnemyShotSound` (tail), `StartSfx` |
| Reads | `$5B66`-`$5D0A`; `$5D28`-`$5E36`; `$5E67`-`$5E68`; `$5E7F`-`$5E80`; `$5E97`-`$5E98`; `$5EAF`-`$5EB0`; 5 more ranges |
| Writes | `$A07B` (`SparkleDotIn+11`); `$A095`-`$A099` (`SparkleDotOut+8`) |

#### `LaserSound` (`$B5A0`)

**DE = the laser's sound `$D50D`**

As REX 1's LaserSound `$B55A` (src/game/weapons.asm).

Witness: L1 412 (c2, rzx-p2-00000, rzx-p2-02000, rzx-p2-04000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 98 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 412 calls (`stage1/rec/rzx-p2-02000` 216, `stage1/rec/rzx-p2-00000` 89, `stage1/rec/rzx-p2-04000` 58 and 1 more) |
| Called from | `FindSlot` |
| Calls | `FindEnemySlot` (tail) |

#### `SpraySound` (`$B5A4`)

**DE = the spray's sound `$D516`**

As REX 1's SpraySound `$B55E` (src/game/weapons.asm).

Witness: L1 3998 (rzx-p2- x15).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 595 t-states own (0.00 %) |
| Runs (the other recordings) | 3,998 calls (`stage1/rec/rzx-p2-38000` 602, `stage1/rec/rzx-p2-32000` 424, `stage1/rec/rzx-p2-36000` 410 and 12 more) |
| Called from | `DrawAnimCells`, `FindSlot` |
| Reads | `$A013` (`SparkleDots2+13`); `$A0B6`-`$A0BB` (`SparkleDots+9`) |
| Writes | `$A093`-`$A099` (`SparkleDotOut+6`) |

#### `EnemyShotSound` (`$B5A8`)

**The enemies' shot sound `$D504`, if channel C (the third, Channels+`$10`) is free**

As REX 1's EnemyShotSound `$B562` (src/game/weapons.asm).

Witness: L1 1121 (c2, p2-room20, rzx-p2- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 919 calls (`stage1/rec/rzx-p2-12000` 241, `stage1/rec/rzx-p2-26000` 140, `stage1/rec/rzx-p2-38000` 102 and 14 more) |
| Called from | `FindSlot` (tail) |
| Calls | `StartSfx` |
| Reads | `$D5DA` (`Channels+16`) |

#### `FindEnemySlot` (`$B5B6`)

**IY = a free slot among the enemies' 20 bullets**

As REX 1's FindEnemySlot `$B570` (src/game/weapons.asm).

Witness: L1 1147 (c2, p2-room20, rzx-p2- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 62,936 t-states own (0.00 %) |
| Runs (the other recordings) | 1,147 calls (`stage1/rec/rzx-p2-12000` 263, `stage1/rec/rzx-p2-26000` 141, `stage1/rec/rzx-p2-38000` 105 and 18 more) |
| Called from | `LaserSound` (tail), `UpdateObject`, `DrawObject`, `BurstShot`, `Kind9Fan` |
| Calls | `FindSlot` (tail) |
| Reads | `$5B60`-`$5B61`; `$5D22`-`$5DAA`; `$A07B` (`SparkleDotIn+11`); `$A093`-`$A099` (`SparkleDotOut+6`) |
| Writes | `$5B60`-`$5B6B`; `$5D22`-`$5DB4`; `$A214` (`ShotSide`) |

#### `EnemyShotFrom` (`$B5C4`)

**An enemy shot from IX's X - 16 (REX 1's; nothing calls it in part 2)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EnemyShotFromX` (`$B5CC`)

**LD A,(IX+0) then into EnemyShotA: no instruction reaches these 3 bytes (leftover)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EnemyShotA` (`$B5CF`)

**An enemy shot at X A, its Y 15 below the object's (nothing calls it in part 2)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 109 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `EnemyShot` (`$B5D4`)

**An enemy shot from IX: X Temp1, Y IX+1 plus A (Temp4, the Y offset SetupShot adds), kind EnemyShotKind `$A1ED` (bit 7: an enemy's)**

As REX 1's EnemyShot `$B58E` (src/game/weapons.asm).

Witness: L1 1147 (c2, p2-room20, rzx-p2- x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,147 calls (`stage1/rec/rzx-p2-12000` 263, `stage1/rec/rzx-p2-26000` 141, `stage1/rec/rzx-p2-38000` 105 and 18 more) |
| Called from | `UpdateObject`, `BurstShot`, `SwingShotUpLeft`, `SwingShotLeft`, `SwingShotStraight`, `SwingShotRight`, `SwingShotUpRight` |
| Calls | `SetupShot` (tail) |
| Reads | `$5E67`-`$5E68`; `$5E82`-`$5E83`; `$5E9D`-`$5E9E`; `$5EB8`-`$5EB9`; `$5ED3`-`$5ED4`; `$5EEE`-`$5EEF`; 3 more ranges |
| Writes | `$A22E`-`$A232` (`Temp2`, `Temp3`, `Temp4`) |

#### `RexShot` (`$B5EB`)

**A shot from Rex: his X, Y + 17 (Temp4) and facing, type the weapon**

As REX 1's RexShot `$B5A5` (src/game/weapons.asm).

Witness: L1 4167 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,167 calls (`stage1/rec/rzx-p2-38000` 616, `stage1/rec/rzx-p2-36000` 384, `stage1/rec/rzx-p2-32000` 368 and 20 more) |
| Called from | `FireWeapon`, `FireLaser`, `FireSpray` |
| Calls | `SetupShot` (falls into) |
| Reads | `$5B60`-`$5D05`; `$A1AC` (`Weapon`); `$A214` (`ShotSide`); `$A22C`-`$A232` (`Temp1`, `Temp2`, `Temp3`, `Temp4`); `$A24F`-`$A254` (`RexX`, `RexY`, `Room`, `RoomColumn` and 1 more) |
| Writes | `$5B60`-`$5D0F`; `$A22C`-`$A232` (`Temp1`, `Temp2`, `Temp3`, `Temp4`) |

#### `SetupShot` (`$B607`)

**Fill the slot at IY: live, type A, Y Temp2 + Temp4, X Temp1 + 16, direction Temp3 (left: dX -1, -8 pixels), the grid pointer**

As REX 1's SetupShot `$B5C1` (src/game/weapons.asm).

Witness: L1 7115 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 109 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,490,911 t-states own (0.24 %) |
| Runs (the other recordings) | 6,711 calls (`stage1/rec/rzx-p2-12000` 757, `stage1/rec/rzx-p2-38000` 721, `stage1/rec/rzx-p2-08000` 516 and 18 more) |
| Called from | `MainLoop`, `BuildRoom`, `FireWeapon`, `FireDouble`, `EnemyShot` (tail), `RexShot` (falls into), `MoveSplitShot` |
| Reads | `$5B60`-`$5E45`; `$6C6A`-`$6C6C` (`AnimChar73+1052`); `$8A42`-`$8A59` (`SpriteShield+298`); `$8F4A`-`$8F61` (`SpriteKind1+74`); `$A013` (`SparkleDots2+13`); `$A093`-`$A097` (`SparkleDotOut+6`); 12 more ranges |
| Writes | `$58EE` (screen); `$5B60`-`$5D0F`; `$5D22`-`$5E3B`; `$A093`-`$A097` (`SparkleDotOut+6`); `$A0AF`-`$A0B0` (`SparkleDots+2`); `$DA86`-`$DA89` (`SceneryCellList+292`); 9 more ranges |

#### `MoveEnemyBullets` (`$B68B`)

**Move the enemies' 20 bullets**

As REX 1's MoveEnemyBullets `$B645` (src/game/weapons.asm).

Witness: L1 10885 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,885 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 519, `stage1/rec/rzx-p2-18000` 517 and 20 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `MoveShots` (tail) |

#### `MoveBullets` (`$B694`)

**Move Rex's 30 bullets (falls into MoveShots)**

As REX 1's MoveBullets `$B64E` (src/game/weapons.asm).

Witness: L1 10440 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,440 calls (`stage1/rec/rzx-p2-16000` 519, `stage1/rec/rzx-p2-18000` 517, `stage1/rec/rzx-p2-14000` 511 and 20 more) |
| Called from | `MainLoop` |
| Calls | `MoveShots` (falls into) |

#### `MoveShots` (`$B69A`)

**Move B bullets from IX: by state (live, hit flash 2 and 3) and type (gun, beam, spray dot, enemy shot, bouncing, drone shot)**

As REX 1's MoveShots `$B654` (src/game/weapons.asm).

Witness: L1 530900 (c2, p2-room20, rzx-p2- x21).

[Animation: `MoveShots` at work](img/routines/MoveShots.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 530,900 calls (`stage1/c2` 32,950, `stage1/rec/rzx-p2-16000` 25,950, `stage1/rec/rzx-p2-18000` 25,850 and 20 more) |
| Called from | `MoveEnemyBullets` (tail), `MoveBullets` (falls into), `NextShot` (tail) |
| Calls | `PrintText`, `NextShot` (tail), `ShotFlash1` (tail), `ShotFlash2` (tail), `MoveLob` (tail), `DrawShotDot` (tail), `DrawShotByte` (tail), `MoveSplitShot` (tail), `MoveSparkShot` (tail), `BulletsHitObject` |
| Reads | `$5B62`-`$5E45` |

#### `StepShot` (`$B6D8`)

**Move a bullet one step; off the play area it ends; the big squidgy thing's cell (4) is hit (BossHit); a cell not passable stops it**

Changed from REX 1's StepShot `$B692` (src/game/weapons.asm).

Witness: L1 52308 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 52,308 calls (`stage1/rec/rzx-p2-12000` 5,283, `stage1/rec/rzx-p2-38000` 4,825, `stage1/rec/rzx-p2-08000` 4,525 and 20 more) |
| Called from | `MoveLob` (tail), `DrawShotDot` (tail), `DrawShotByte` (tail), `MoveSplitShot` (tail), `MoveSparkShot` (tail) |
| Calls | `CellPointer`, `StepShotType` (falls into), `EndShot` (tail), `BossHit` (tail), `ShotStopped` (tail), `IsPassable` |
| Reads | `$5B60`-`$5D0F`; `$5D22`-`$5E3B`; `$E203`-`$E49B` (`RoomGridPlay+4`) |
| Writes | `$5B60`-`$5D07`; `$5D22`-`$5E31`; `$A248`-`$A249` (`SpriteX`, `SpriteY`) |

#### `StepShotType` (`$B715`)

**A bullet's path by its type: type 7 keeps its own move, the others add their step to the path pointer**

Changed from REX 1's StepShotType `$B6D9` (src/game/weapons.asm).

Witness: L1 46518 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 597 calls (`stage1/rec/rzx-p2-40000` 597) |
| Called from | `StepShot` (falls into), `BossHit` (tail) |
| Calls | `NextShot` (falls into) |
| Reads | `$5B62`-`$5D0F` |
| Writes | `$5B62`-`$5D07` |

#### `NextShot` (`$B732`)

**The next bullet record (15 bytes on)**

As REX 1's NextShot `$B6F6` (src/game/weapons.asm).

Witness: L1 530900 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 530,900 calls (`stage1/c2` 32,950, `stage1/rec/rzx-p2-16000` 25,950, `stage1/rec/rzx-p2-18000` 25,850 and 20 more) |
| Called from | `MoveShots` (tail), `StepShotType` (falls into), `EndShot` (tail), `ShotStopped` (tail), `ShotFlash1` (tail), `ShotFlash2` (tail) |
| Calls | `MoveShots` (tail) |

#### `EndShot` (`$B73C`)

**The bullet ends (live = 0)**

As REX 1's EndShot `$B700` (src/game/weapons.asm).

Witness: L1 1073 (c2, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/rzx-p2-08000` 131, `stage1/rec/rzx-p2-06000` 125, `stage1/rec/rzx-p2-12000` 112 and 19 more) |
| Called from | `StepShot` (tail) |
| Calls | `NextShot` (tail) |
| Writes | `$5B66`-`$5D0A`; `$5D28`-`$5E36` |

#### `BossHit` (`$B743`)

**A bullet on a cell of type 4 (the big squidgy thing): unless it already dies, BossDying `$A268` = 1, BossTimer 200, BossAreaPtr `$9CF9`, its colours (3, `$43`, 6) cleared from the shadow; the bullet flies on**

Witness: L1 1 (rzx-p2-40000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1 call (`stage1/rec/rzx-p2-40000` 1) |
| Called from | `StepShot` (tail) |
| Calls | `StepShotType` (tail) |
| Reads | `$A268` (`BossDying`); `$E55F`-`$E7FE` (`AttrShadowPlay`) |
| Writes | `$A268`-`$A26B` (`BossDying`, `BossTimer`, `BossAreaPtr`); `$E64A`-`$E64E` (`AttrShadowPlay+235`); `$E66A`-`$E66E` (`AttrShadowPlay+267`); `$E68A`-`$E68E` (`AttrShadowPlay+299`); `$E6A9`-`$E6EE` (`AttrShadowPlay+330`); `$E70A`-`$E70E` (`AttrShadowPlay+427`); 3 more ranges |

#### `ShotStopped` (`$B810`)

**A bullet meets a wall: a small flash (state 2) unless it is the laser, the hit sound `$D51F`**

As REX 1's ShotStopped `$B794` (src/game/weapons.asm).

Witness: L1 4717 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,717 calls (`stage1/rec/rzx-p2-12000` 551, `stage1/rec/rzx-p2-38000` 530, `stage1/rec/rzx-p2-32000` 405 and 20 more) |
| Called from | `StepShot` (tail) |
| Calls | `NextShot` (tail), `StartSfx` |
| Reads | `$5B62`-`$5D07`; `$5D24`-`$5E33`; `$A1AC` (`Weapon`); `$D5DA` (`Channels+16`) |
| Writes | `$5B66`-`$5D0A`; `$5D28`-`$5E36`; `$EB10`-`$EB30` (`BufferPlayOrigin+17`); `$EB7A` (`BufferPlayOrigin+123`); `$EBDA`-`$FEAA` (`BufferPlayOrigin+219`); `$FED5`-`$FED6` (`BufferPlayOrigin+5078`) |

#### `ShotFlash1` (`$B839`)

**The flash's first frame: a cross of three bytes in the buffer**

As REX 1's ShotFlash1 `$B7BD` (src/game/weapons.asm).

Witness: L1 5244 (p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,244 calls (`stage1/rec/rzx-p2-12000` 619, `stage1/rec/rzx-p2-38000` 599, `stage1/rec/rzx-p2-36000` 436 and 19 more) |
| Called from | `MoveShots` (tail) |
| Calls | `NextShot` (tail) |
| Reads | `$5B62`-`$5D07`; `$5D24`-`$5E33` |
| Writes | `$5B66`-`$5D0A`; `$5D28`-`$5E36`; `$EAEE`-`$FED6` (`ObjectBufferOrigin+239`, `BufferPlayOrigin`); `$FEF5`-`$FEF6` (`BufferPlayOrigin+5110`) |

#### `ShotFlash2` (`$B854`)

**The flash's second frame, then the bullet ends**

As REX 1's ShotFlash2 `$B7D8` (src/game/weapons.asm).

Witness: L1 5247 (p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,476 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 5,247 calls (`stage1/rec/rzx-p2-12000` 619, `stage1/rec/rzx-p2-38000` 602, `stage1/rec/rzx-p2-36000` 437 and 19 more) |
| Called from | `MoveShots` (tail) |
| Calls | `NextShot` (tail) |
| Reads | `$5B62`-`$5D07`; `$5D24`-`$5E33` |
| Writes | `$5B66`-`$5D0A`; `$5D28`-`$5E36`; `$EACE`-`$FEF6` (`ObjectBufferOrigin+207`, `BufferPlayOrigin`); `$FF15`-`$FF16` (`BufferPlayOrigin+5142`) |

#### `MoveLob` (`$B878`)

**A type 7 shot: its Y step from its path (LobPathTable by IX+`$0E`; at the end the repeat step), the 4-line LobPicture, then StepShot**

Witness: L1 4745 (c2, rzx-p2- x13).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,745 calls (`stage1/rec/rzx-p2-12000` 1,607, `stage1/rec/rzx-p2-38000` 798, `stage1/rec/rzx-p2-08000` 351 and 11 more) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5D22`-`$5E3E`; `$A22C`-`$A22D` (`Temp1`); `$AA00`-`$AA56` (`LobPaths`, `LobPicture`, `LobPathTable`) |
| Writes | `$5D24`-`$5E3C`; `$A22C`-`$A22D` (`Temp1`); `$EB10`-`$EF1B` (`BufferPlayOrigin+17`); `$EF44`-`$FC93` (`BufferPlayOrigin+1093`); `$FCAB`-`$FD36` (`BufferPlayOrigin+4524`); `$FD53`-`$FD73` (`BufferPlayOrigin+4692`); 4 more ranges |

#### `DrawShotDot` (`$B8E2`)

**Draw a type 4 bullet: a 4-line dot (Rex's or an enemy's shape)**

As REX 1's DrawShotDot `$B867` (src/game/weapons.asm).

Witness: L1 28859 (c2, rzx-p2- x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 28,859 calls (`stage1/rec/rzx-p2-38000` 3,965, `stage1/rec/rzx-p2-36000` 2,594, `stage1/rec/rzx-p2-32000` 2,350 and 17 more) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5B6B`-`$5D0F`; `$5D2D`-`$5E2C` |
| Writes | `$EAC5`-`$FFEF` (`ObjectBufferOrigin+198`, `BufferPlayOrigin`) |

#### `DrawShotByte` (`$B90E`)

**Draw a gun bullet: one byte by direction and side**

As REX 1's DrawShotByte `$B893` (src/game/weapons.asm).

Witness: L1 14319 (c2, p2-room20, rzx-p2- x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14,319 calls (`stage1/rec/rzx-p2-08000` 4,174, `stage1/rec/rzx-p2-10000` 2,903, `stage1/rec/rzx-p2-06000` 2,043 and 16 more) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5B64`-`$5D0F`; `$5D26`-`$5DC3` |
| Writes | `$EBCE`-`$EBDA` (`BufferPlayOrigin+207`); `$EC0E`-`$EC1A` (`BufferPlayOrigin+271`); `$EC94`-`$F8E6` (`BufferPlayOrigin+405`); `$F903`-`$F9DA` (`BufferPlayOrigin+3588`); `$FA09`-`$FA1A` (`BufferPlayOrigin+3850`); `$FA48`-`$FA8B` (`BufferPlayOrigin+3913`); 11 more ranges |

#### `MoveSplitShot` (`$B937`)

**A splitting shot (type 2): every few steps it fires a new shot from where it is**

As REX 1's MoveSplitShot `$B8BC` (src/game/weapons.asm).

Witness: L1 590 (c2, rzx-p2-00000, rzx-p2-02000, rzx-p2-04000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 203,847 t-states own (0.01 %) |
| Runs (the other recordings) | 590 calls (`stage1/rec/rzx-p2-02000` 346, `stage1/rec/rzx-p2-04000` 112, `stage1/rec/rzx-p2-00000` 85 and 1 more) |
| Called from | `MainLoop`, `BuildRoom`, `MoveShots` (tail) |
| Calls | `FindShotSlot`, `SetupShot`, `StepShot` (tail) |
| Reads | `$5B61`-`$5BE6`; `$5BF7`-`$5C13`; `$5C33`-`$5C5E`; `$5C6F`-`$5C7C`; `$5C9C`-`$5CA9`; `$5CBA`-`$5CD6`; 5 more ranges |
| Writes | `$5801`-`$5802` (screen); `$5821`-`$5822` (screen); `$5B65`-`$5D12`; `$A22C`-`$A232` (`Temp1`, `Temp2`, `Temp3`, `Temp4`); `$E500`-`$E501` (`TitleScreen+1`); `$E520`-`$E521` (`TitleScreen+33`) |

#### `MoveSparkShot` (`$B99B`)

**A spark (type 6): random dots by its count (SparkMasks `$B9BE`), it fades out**

As REX 1's MoveSparkShot `$B920` (src/game/weapons.asm).

Witness: L1 3795 (c2, rzx-p2-00000, rzx-p2-02000, rzx-p2-04000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,795 calls (`stage1/rec/rzx-p2-02000` 2,101, `stage1/rec/rzx-p2-04000` 825, `stage1/rec/rzx-p2-00000` 568 and 1 more) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5B6E`-`$5D12`; `$B9BF`-`$B9D6` (`SparkMasks+1`) |
| Writes | `$5B66`-`$5D12`; `$EEA6`-`$EEAD` (`BufferPlayOrigin+935`); `$F103`-`$F192` (`BufferPlayOrigin+1540`); `$F20E`-`$F21A` (`BufferPlayOrigin+1807`); `$F28E`-`$F2B6` (`BufferPlayOrigin+1935`); `$F2E9`-`$F2F8` (`BufferPlayOrigin+2026`); 15 more ranges |

#### `PowerBar` (`$B9E6`)

**Draw the power bar: its end colour flashes by FadeStepIndex**

As REX 1's PowerBar `$B96B` (src/game/weapons.asm).

Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 2,093 t-states own (0.00 %) |
| Runs (the other recordings) | 10,871 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516 and 20 more) |
| Called from | `MainLoop`, `Attract`, `DrawAnimCells`, `PowerGain` |
| Calls | `PowerBarColour` (falls into) |
| Reads | `$A014`-`$A018` (`SparkleDots2+14`); `$A06E` (`SparkleMove+35`); `$A093` (`SparkleDotOut+6`); `$A1AE`-`$A1AF` (`PowerBarPtr`); `$A1DB` (`FadeStepIndex`) |
| Writes | `$A018` (`SparkleDots2+18`); `$A093` (`SparkleDotOut+6`) |

#### `PowerBarColour` (`$B9F9`)

**A = PowerLevel + 2 (the bar's colour)**

As REX 1's PowerBarColour `$B97E` (src/game/weapons.asm).

Witness: L1 20400 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20,400 calls (`stage1/c2` 1,852, `stage1/rec/rzx-p2-18000` 1,032, `stage1/rec/rzx-p2-08000` 1,018 and 20 more) |
| Called from | `PowerBar` (falls into) |
| Calls | `Fill2x2` (falls into) |
| Reads | `$A1AD` (`PowerLevel`) |
| Writes | `$5805`-`$580A` (screen); `$5825`-`$582A` (screen); `$E504`-`$E509` (`TitleScreen+5`); `$E524`-`$E529` (`TitleScreen+37`) |

#### `Fill2x2` (`$B9FE`)

**Write A into a 2 x 2 patch at HL**

As REX 1's Fill2x2 `$B983` (src/game/weapons.asm).

Witness: L1 20424 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,242 calls (`stage1/c2` 1,854, `stage1/rec/rzx-p2-18000` 1,034, `stage1/rec/rzx-p2-24000` 1,004 and 8 more) |
| Called from | `PowerBarColour` (falls into), `PowerDrain` |
| Writes | `$5803`-`$580A` (screen); `$5823`-`$582A` (screen); `$E502`-`$E509` (`TitleScreen+3`); `$E522`-`$E529` (`TitleScreen+35`) |

#### `PowerGain` (`$BA09`)

**A power pod: PowerCount `$A1B1` counts, every 120 the PowerLevel + 1 up to 5 (at 5 GainRank raises WeaponRank and sets the level back to 1; at rank 5 nothing), the fire faster**

As REX 1's PowerGain `$B98E` (src/game/weapons.asm).

Witness: L1 78 (rzx-p2- x14).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 10 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 914 t-states own (0.00 %) |
| Runs (the other recordings) | 78 calls (`stage1/rec/rzx-p2-02000` 12, `stage1/rec/rzx-p2-14000` 11, `stage1/rec/rzx-p2-32000` 10 and 11 more) |
| Called from | `NewGame`, `DeathAnimation`, `TakePowerPod` |
| Calls | `InitDrones`, `PowerBar`, `BestWeapon` (falls into) |
| Reads | `$A1AD`-`$A1B1` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`); `$A1E8`-`$A1EB` (`WeaponIcon`, `HasDoubleFire`, `HasLaser`, `HasMultiple`); `$A207` (`WeaponRank`); `$A22C` (`Temp1`) |
| Writes | `$A013`-`$A016` (`SparkleDots2+13`); `$A06E` (`SparkleMove+35`); `$A1AC`-`$A1B1` (`Weapon`, `PowerLevel`, `PowerBarPtr`, `PassToggle` and 1 more); `$A201`-`$A207` (`FireDelay`, `AnimCount1`, `AnimCount2`, `AnimCount3` and 2 more); `$A22C` (`Temp1`) |

#### `BestWeapon` (`$BA52`)

**Weapon = the best one held (WeaponRank `$A207`), WeaponIcon updated**

As REX 1's BestWeapon `$B9D7` (src/game/weapons.asm).

Witness: L1 52 (c2, p2-room20, rzx-p2- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,459,435 t-states own (0.10 %) |
| Runs (the other recordings) | 51 calls (`stage1/rec/rzx-p2-24000` 5, `stage1/rec/rzx-p2-18000` 5, `stage1/rec/rzx-p2-16000` 5 and 14 more) |
| Called from | `MainLoop`, `BuildRoom`, `PowerGain` (falls into), `PowerDrain` (tail), `LosePower` (tail), `PanelRow` (tail) |
| Calls | `PanelBox` (tail) |
| Reads | `$5E66`-`$5F4A`; `$A092` (`SparkleDotOut+5`); `$A1E8`-`$A1EC` (`WeaponIcon`, `HasDoubleFire`, `HasLaser`, `HasMultiple` and 1 more); `$A207` (`WeaponRank`) |
| Writes | `$5EDC`-`$5EDD`; `$A033`-`$A035` (`SparkleDir+16`); `$A0AF`-`$A0B2` (`SparkleDots+2`); `$A1AC` (`Weapon`) |

#### `PowerDrain` (`$BA6A`)

**A shot of a special weapon: PowerCount down; at 0 the PowerLevel - 1, the bar redrawn; at 1 BestWeapon**

As REX 1's PowerDrain `$B9EF` (src/game/weapons.asm).

Witness: L1 1038 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,038 calls (`stage1/rec/rzx-p2-36000` 96, `stage1/rec/rzx-p2-38000` 86, `stage1/rec/rzx-p2-22000` 73 and 20 more) |
| Called from | `FireWeapon`, `LosePower` |
| Calls | `ShowBombs`, `Fill2x2`, `BestWeapon` (tail) |
| Reads | `$A1AD`-`$A1B1` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`); `$A207` (`WeaponRank`); `$A22C` (`Temp1`) |
| Writes | `$A1AD`-`$A1B1` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`); `$A207` (`WeaponRank`); `$A22C` (`Temp1`) |

#### `LosePower` (`$BAB8`)

**A death or ENERGY LOSS: PowerDrain(50) twice; each drain that would go below 0 puts the count back and drops one level, so 0, 1 or 2 levels go**

Changed from REX 1's LosePower `$BA3D` (src/game/weapons.asm).

Witness: L1 36 (c2, p2-room20, rzx-p2- x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rec/rzx-p2-16000` 4, `stage1/rec/rzx-p2-18000` 4, `stage1/rec/rzx-p2-24000` 4 and 13 more) |
| Called from | `RexDies` |
| Calls | `BestWeapon` (tail), `PowerDrain` |

#### `StartWeapon` (`$BAC6`)

**A new game's weapon: Weapon 2 (the laser), PowerLevel 3, the bar's end `$5805`, WeaponRank 2**

Witness: L1 5 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/c2` 4, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `NewGame` |
| Writes | `$A1AC`-`$A1AF` (`Weapon`, `PowerLevel`, `PowerBarPtr`); `$A207` (`WeaponRank`) |

### Part 2 (REX 2): attract

`src/rex2/attract.asm`

#### `BuildRoom` (`$A939`)

**Build the room Room `$A251`: exits and objects, the map drawn, the buffer shown, the room's objects made (no scripted spawn in part 2)**

Changed from REX 1's BuildRoom `$A89D` (src/game/codepanel.asm).

Witness: L1 32 (c2, p2-room20, rzx-p2- x17).

[Animation: `BuildRoom` at work](img/routines/BuildRoom.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 32 calls (`stage1/c2` 5, `stage1/rec/rzx-p2-00000` 3, `stage1/rec/rzx-p2-26000` 2 and 16 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `ShowShield`, `FadeStep`, `BossExplodes`, `SparkleMasks`, `HudSweep`, `ResetSweep`, `BufferToScreen`, `DroneOrbit`, `RoomExits`, `ClearBuffer`, `DrawSprite`, `DrawAnimCells`, `SetupShot`, `MoveSplitShot`, `BestWeapon`, `DrawRoom`, `CopyAttrs`, `ReadExits`, `SetSpawnLeft`, `MakeObjects`, `HitObjectHard`, `DrawCharBlock` |
| Reads | `$5860`-`$5AFE` (screen); `$5B60`-`$5E4C` |
| Writes | `$5860`-`$5AFF` (screen); `$5B60`-`$5E4D`; `$A1B0` (`PassToggle`); `$A1D2`-`$A1DE` (`KillFlashPtr`, `ComboCount`, `ComboTimer`, `Score` and 6 more); `$A1F5` (`RestartFacing`); `$D528` (`SfxExplosion`) |

#### `Attract` (`$A98E`)

**The attract mode: each room of AttractRooms shown 199 passes (AttractTimer 200, decremented before the test) with its objects moving (no Rex, no conveyor rolls); fire starts a game**

Changed from REX 1's Attract `$A915` (src/game/codepanel.asm).

Witness: L1 3 (c2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/c2` 1) |
| Called from | `NewGame` (tail) |
| Calls | `NewGame` (tail), `KillFlashFade`, `FadeStep`, `HudSweep`, `BufferToScreen`, `ClearScreen`, `ReadFire`, `AnimateCells`, `UpdateDrones`, `BuildRoom`, `ClearBuffer`, `DrawAnimCells`, `MoveEnemyBullets`, `PowerBar`, `UpdateObjects`, `SpawnScripted`, `SpawnRandom`, `EnemyBulletsHitRex`, `SoundStep` |
| Reads | `$A1B0` (`PassToggle`); `$A25B`-`$A25C` (`AttractFlag`, `AttractTimer`); `$A986`-`$A988` (`AttractRooms`) |
| Writes | `$A1B0` (`PassToggle`); `$A251`-`$A25C` (`Room`, `RoomColumn`, `RexFacing`, `FallSpeed` and 4 more) |

### Part 2 (REX 2): render

`src/rex2/render.asm`

#### `ClearBuffer` (`$B243`)

**Clear the back buffer's play lines `$EB00-$FFFF` with PUSH (the stack from `$FFFF` down)**

As REX 1's ClearBuffer `$B205` (src/game/render.asm).

Witness: L1 10902 (c2, p2-room20, rzx-p2- x21).

[Animation: `ClearBuffer` at work](img/routines/ClearBuffer.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 29,778 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 14,632,595 t-states own (1.01 %) |
| Runs (the other recordings) | 10,902 calls (`stage1/c2` 931, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 518 and 20 more) |
| Called from | `MainLoop`, `DrawRex`, `DrawPiece`, `BuildRoom`, `Attract`, `PanelBox` |
| Reads | `$6018`-`$60D7`; `$7F72`-`$8031` (`RoomMaps+1900`); `$80F2`-`$8631` (`RoomMaps+2284`, `Sprites`); `$86F2`-`$8871` (`SpritePoints+538`, `SpritePodA`, `SpritePodB`); `$8E4A`-`$8E89` (`SpriteKind5+42`); `$8EAA`-`$8EE9` (`SpriteKind5+138`); 14 more ranges |
| Writes | `$A0AF` (`SparkleDots+2`); `$A22C`-`$A22D` (`Temp1`); `$B2AC`-`$B2B0` (`DrawSprite+22`); `$B318`-`$B31C` (`DrawMirrored+21`); `$EC0E`-`$EF30` (`BufferPlayOrigin+271`); `$EF4E`-`$EF50` (`BufferPlayOrigin+1103`); 6 more ranges |

#### `DrawSprite` (`$B296`)

**OR a picture into the back buffer: SpriteX/SpriteY, SpriteWidth/Height (written into the loop at `$B2EE`, `$B2F2` or `$B35E`, `$B362`), the object's own picture when bit 7 of `$A1CC`; A non-zero draws it mirrored through MirrorTable `$AE52`**

Changed from REX 1's DrawSprite `$B258` (src/game/render.asm).

Witness: L1 57786 (c2, p2-room20, rzx-p2- x21).

[Animation: `DrawSprite` at work](img/routines/DrawSprite.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 70,568,199 t-states own (4.86 %) |
| Runs (the other recordings) | 57,786 calls (`stage1/c2` 5,352, `stage1/rec/rzx-p2-20000` 3,524, `stage1/rec/rzx-p2-36000` 3,488 and 20 more) |
| Called from | `MainLoop`, `DrawRex`, `DroneOrbit`, `BuildRoom`, `DrawObject` |
| Reads | `$6450`-`$645F` (`Font+330`); `$64D0`-`$64DF` (`Font+458`); `$6568`-`$656F` (`CharFlags+98`); `$65A8`-`$6697` (`CharFlags+162`, `CharGraphics`); `$66E0`-`$6727` (`CharGraphics+218`); `$6760`-`$68FF` (`CharGraphics+346`, `AnimChar73`); 13 more ranges |
| Writes | `$5B65`; `$A012` (`SparkleDots2+12`); `$A095`-`$A096` (`SparkleDotOut+8`); `$A248` (`SpriteX`); `$A25E`-`$A25F` (`SpriteSource`); `$B2EE`-`$B2F2` (`DrawSpriteRows+1`, `DrawSpriteRow`, `DrawSpriteBytes`); 2 more ranges |

#### `ReturnToStack` (`$B37F`)

**LD SP,(Temp2): RET: DrawAnimCells' exit with the stack it saved**

As REX 1's ReturnToStack `$B339` (src/game/render.asm).

Witness: L1 10901 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,096 calls (`stage1/rec/rzx-p2-08000` 510, `stage1/rec/rzx-p2-26000` 494, `stage1/rec/rzx-p2-34000` 491 and 4 more) |
| Called from | `DrawAnimCells` (tail) |
| Calls | `FireSpray` |
| Reads | `$A22E`-`$A22F` (`Temp2`) |

#### `DrawAnimCells` (`$B384`)

**Draw every scenery cell of the room (SceneryCellList `$D962`) into the back buffer, the stack as the list pointer**

As REX 1's DrawAnimCells `$B33E` (src/game/render.asm).

Witness: L1 10902 (c2, p2-room20, rzx-p2- x21).

[Animation: `DrawAnimCells` at work](img/routines/DrawAnimCells.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,902 calls (`stage1/c2` 931, `stage1/rec/rzx-p2-16000` 519, `stage1/rec/rzx-p2-18000` 519 and 20 more) |
| Called from | `MainLoop`, `BuildRoom`, `Attract` |
| Calls | `ReturnToStack` (tail), `SpraySound`, `PowerBar` |
| Reads | `$6616`-`$6A8D` (`CharGraphics+16`, `AnimChar73`); `$6AA6`-`$6E05` (`AnimChar73+600`, `AnimChar250`, `AnimChar252`); `$A22E`-`$A22F` (`Temp2`) |
| Writes | `$A22E`-`$A22F` (`Temp2`); `$EB00`-`$FFFD` (`BufferPlayOrigin+1`, `work space $FFFA+`) |

#### `FireWeapon` (`$B3B8`)

**Fire: a shot of the current weapon if a slot is free (once a press, only while Rex is present)**

Witness: L1 1261 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,261 calls (`stage1/rec/rzx-p2-36000` 111, `stage1/rec/rzx-p2-38000` 93, `stage1/rec/rzx-p2-12000` 78 and 20 more) |
| Called from | `MainLoop` |
| Calls | `FireDouble` (tail), `FireLaser` (tail), `FireSpray` (tail), `FindShotSlot`, `RexShot`, `SetupShot`, `PowerDrain` |
| Reads | `$5B60`-`$5C05`; `$5C32`-`$5C50`; `$5C6E`; `$5C9B`; `$5CB9`-`$5CC8`; `$5CF5`; 5 more ranges |
| Writes | `$5B65`-`$5CA9`; `$5CBE`-`$5CD6`; `$5CFA`-`$5D03`; `$A1AB` (`FireLatch`); `$A22C`-`$A232` (`Temp1`, `Temp2`, `Temp3`, `Temp4`) |

### Part 2 (REX 2): panels

`src/rex2/panels.asm`

#### `PanelBox` (`$BADC`)

**Draw a framed box: A attribute, D width, E height, H column, L line, C the frame's colour; the frame from the font's edge characters**

As REX 1's PanelBox `$CE7B` (src/game/panels.asm).

Witness: L1 17 (c2, rzx-p2-00000, rzx-p2-40000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,131 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 604,306 t-states own (0.04 %) |
| Runs (the other recordings) | 17 calls (`stage1/c2` 13, `stage1/rec/rzx-p2-00000` 3, `stage1/rec/rzx-p2-40000` 1) |
| Called from | `PrintBoxed`, `BestWeapon` (tail), `SaveAttrs` (tail), `FlashCells` (tail), `UpdateObject` (tail), `ObjectBehaviour` (tail), `Kind2Drop` (tail), `Kind3Grow` (tail), `Kind4Crawl` (tail) |
| Calls | `ClearBuffer`, `PanelRow`, `SaveAttrs` (tail), `FlashCells` (tail), `UpdateObject` (tail), `DrawObject` (tail), `Kind2Drop` (tail), `Kind4Close`, `Kind9Fan`, `WalkLeft`, `MaybeDissolve`, `MakeJumper`, `ObjectJump`, `ObjectFall`, `TakePowerPod`, `FillAttrs` |
| Reads | `$5E6F`-`$5E87`; `$5E9F`; `$5EB7`; `$5ECF`; `$5EE7`; `$5EFF`; 4 more ranges |
| Writes | `$A1C1`-`$A1C4` (`BoxX`, `BoxY`, `BoxWidth`, `BoxHeight`); `$A22C`-`$A238` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 2 more) |

#### `PanelRow` (`$BB6B`)

**8 lines of a box row**

As REX 1's PanelRow `$CF0A` (src/game/panels.asm).

Witness: L1 79 (c2, rzx-p2-00000, rzx-p2-40000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 79 calls (`stage1/c2` 60, `stage1/rec/rzx-p2-00000` 12, `stage1/rec/rzx-p2-40000` 7) |
| Called from | `PanelBox` |
| Calls | `BestWeapon` (tail), `PanelLine` |
| Reads | `$A1C1` (`BoxX`); `$AD2A`-`$AE19` (`ScreenLines+96`) |

#### `PanelLine` (`$BB82`)

**One pixel line: the left edge, the middle B times, the right edge**

As REX 1's PanelLine `$CF21` (src/game/panels.asm).

Witness: L1 632 (c2, rzx-p2-00000, rzx-p2-40000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 632 calls (`stage1/c2` 480, `stage1/rec/rzx-p2-00000` 96, `stage1/rec/rzx-p2-40000` 56) |
| Called from | `PanelRow` |
| Reads | `$6346`-`$636D` (`Font+64`); `$637E`-`$6385` (`Font+120`); `$63DE`-`$63F5` (`Font+216`); `$A1C3` (`BoxWidth`) |
| Writes | `$4825`-`$57FF` (screen) |

#### `FillShadowRow3` (`$BB9E`)

**Three rows of three: the cells of value `$47` (white) take C**

As REX 1's FillShadowRow3 `$CF3D` (src/game/panels.asm).

Witness: L1 2038 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,038 calls (`stage1/rec/rzx-p2-38000` 208, `stage1/rec/rzx-p2-26000` 176, `stage1/rec/rzx-p2-24000` 160 and 19 more) |
| Called from | `FlashCells` |
| Calls | `InkRow3White` |

#### `InkRow3White` (`$BBA8`)

**Three cells: those whose shadow attribute is `$47` or `$0F` take ink C (paper kept)**

Witness: L1 6114 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,114 calls (`stage1/rec/rzx-p2-38000` 624, `stage1/rec/rzx-p2-26000` 528, `stage1/rec/rzx-p2-24000` 480 and 19 more) |
| Called from | `FillShadowRow3` |
| Reads | `$586B`-`$5AB9` (screen); `$5ACA`-`$5AD9` (screen); `$E559`-`$E7B8` (`TitleScreen+90`, `AttrShadowPlay`); `$E7C9`-`$E7D8` (`AttrShadowPlay+618`) |
| Writes | `$586B`-`$5AB9` (screen); `$5ACA`-`$5AD9` (screen) |

#### `CopyCells3` (`$BBEA`)

**Copy a 3 x 3 patch from DE to HL (the shadow's 32-byte rows)**

As REX 1's CopyCells3 `$CF6E` (src/game/panels.asm).

Witness: L1 386 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 386 calls (`stage1/rec/rzx-p2-40000` 133, `stage1/rec/rzx-p2-38000` 26, `stage1/rec/rzx-p2-26000` 22 and 20 more) |
| Called from | `BossExplodes`, `BlowUp` |
| Calls | `CopyCells` |

#### `CopyCells` (`$BBF9`)

**One row of three**

As REX 1's CopyCells `$CF7D` (src/game/panels.asm).

Witness: L1 1158 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,158 calls (`stage1/rec/rzx-p2-40000` 399, `stage1/rec/rzx-p2-38000` 78, `stage1/rec/rzx-p2-26000` 66 and 20 more) |
| Called from | `CopyCells3` |
| Reads | `$E559`-`$E7B8` (`TitleScreen+90`, `AttrShadowPlay`); `$E7C9`-`$E7D8` (`AttrShadowPlay+618`) |
| Writes | `$585A`-`$5AB9` (screen); `$5ACA`-`$5AD9` (screen) |

#### `SaveAttrs` (`$BC0B`)

**The screen's top 96 attributes (`$5800`) into the shadow at `$E4FF`**

As REX 1's SaveAttrs `$CF8F` (src/game/panels.asm).

Witness: L1 5 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 4,136 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`stage1/c2` 4, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `NewGame`, `PanelBox` (tail) |
| Calls | `ShowBombs`, `PanelBox` (tail) |
| Reads | `$5800`-`$585F` (screen); `$5EAE` |
| Writes | `$5D27`-`$5D72`; `$A054` (`SparkleMove+9`); `$A093` (`SparkleDotOut+6`); `$E4FF`-`$E55E` (`TitleScreen`) |

#### `FlashCells` (`$BC17`)

**The 3 x 3 cells under SpriteX/SpriteY: the white ones take a random ink of PieceInks `$C2DF`**

Witness: L1 2038 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 8 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,010 t-states own (0.00 %) |
| Runs (the other recordings) | 2,038 calls (`stage1/rec/rzx-p2-38000` 208, `stage1/rec/rzx-p2-26000` 176, `stage1/rec/rzx-p2-24000` 160 and 19 more) |
| Called from | `PanelBox` (tail), `BlowUp` |
| Calls | `ShowBombs`, `BufferAddress`, `FindSlot`, `PanelBox` (tail), `FillShadowRow3` |
| Reads | `$5F26`; `$A22C`-`$A22F` (`Temp1`, `Temp2`); `$C2DF`-`$C2E6` (`PieceInks`) |
| Writes | `$5D27`; `$5D45`-`$5D90`; `$5DAE`; `$5F28`; `$A054` (`SparkleMove+9`); `$A093` (`SparkleDotOut+6`); 1 more ranges |

#### `WeaponPanel` (`$D609`)

**A weapon station's panel (HL: the flag then the text), once a game: the screen saved, the panel, wait for fire, the screen back**

As REX 1's WeaponPanel `$D871` (src/game/panels.asm).

Known only from the code: REX 2 has no weapon station (GiveDoubleFire `$A8F6`).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 189 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `SaveScreen` (`$D63B`)

**The screen's play lines into the back buffer (the panels draw over the screen; BufferToScreen puts it back)**

As REX 1's SaveScreen `$D8A3` (src/game/panels.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 189 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Calls | `DrawCharBlock` (tail) |

#### `DrawCharBlock` (`$D658`)

**Draw a picture straight on the screen from the 6 bytes after the CALL: picture word, column, line, width, height; returns after them**

As REX 1's DrawCharBlock `$D8C0` (src/game/panels.asm).

Witness: L1 43 (c2, rzx-p2-00000, rzx-p2-28000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 180 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,122,736 t-states own (0.08 %) |
| Runs (the other recordings) | 43 calls (`stage1/c2` 32, `stage1/rec/rzx-p2-00000` 8, `stage1/rec/rzx-p2-28000` 3) |
| Called from | `MainLoop`, `DrawHudIcon`, `DrawWeaponIcon`, `BuildRoom`, `SfxGun`, `SaveScreen` (tail) |
| Calls | `NextHudIcon`, `NextWeaponIcon`, `DebugHook` |
| Reads | `$8AC0`-`$8B7F` (`SpriteHudIcons`, `SpriteHudIcons2`); `$A22C`-`$A22F` (`Temp1`, `Temp2`); `$A399`-`$A39E` (`HudIconParams`); `$A3DB`-`$A3E0` (`WeaponIconParams`); `$AC9A`-`$ACB9` (`ScreenLineTable`); `$D832`-`$D857` (`DebugHook+364`) |
| Writes | `$4001`-`$403E` (screen); `$4101`-`$413E` (screen); `$4201`-`$423E` (screen); `$4301`-`$433E` (screen); `$4401`-`$443E` (screen); `$4501`-`$453E` (screen); 4 more ranges |

#### `FillAttrs` (`$D6A1`)

**Fill B rows of E attributes from HL with A**

As REX 1's FillAttrs `$D909` (src/game/panels.asm).

Witness: L1 44 (c2, rzx-p2-00000, rzx-p2-40000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 44 calls (`stage1/c2` 34, `stage1/rec/rzx-p2-00000` 8, `stage1/rec/rzx-p2-40000` 2) |
| Called from | `DrawHud`, `PanelBox` |
| Calls | `DebugHook` |
| Reads | `$A22C`-`$A22E` (`Temp1`, `Temp2`) |
| Writes | `$5801`-`$583E` (screen); `$5925`-`$5A5F` (screen); `$5A74`-`$5A7F` (screen); `$5A94`-`$5A9F` (screen); `$5AB4`-`$5ABF` (screen); `$5AD4`-`$5ADF` (screen); 2 more ranges |

### Part 2 (REX 2): objects

`src/rex2/objects.asm`

#### `UpdateObjects` (`$BC48`)

**Update every object of the room (falls into UpdateObject)**

As REX 1's UpdateObjects `$BA5C` (src/game/objects.asm).

Witness: L1 10869 (c2, p2-room20, rzx-p2- x21).

[Animation: `UpdateObjects` at work](img/routines/UpdateObjects.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,869 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516 and 20 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `FindSlot`, `UpdateObject` (falls into) |
| Reads | `$A22B` (`ObjectCount`) |

#### `UpdateObject` (`$BC50`)

**One object at IX: skip a dead one; kind 0 picks the walker picture (falling or exploding: ExplosionPicture `$9180`); a walker or a hopper at random shoots two shots; draw it**

Changed from REX 1's UpdateObject `$BA64` (src/game/objects.asm).

Witness: L1 112141 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 31,475 t-states own (0.00 %) |
| Runs (the other recordings) | 112,141 calls (`stage1/c2` 9,318, `stage1/rec/rzx-p2-34000` 6,298, `stage1/rec/rzx-p2-28000` 6,240 and 20 more) |
| Called from | `PanelBox` (tail), `UpdateObjects` (falls into), `NextObject` (tail) |
| Calls | `ShowBombs`, `DrawBombIcons`, `Random`, `FindSlot`, `FindEnemySlot`, `EnemyShot`, `PanelBox` (tail), `DrawObject` (tail), `NextObject` (tail) |
| Reads | `$5E66`-`$5FB6`; `$5FD1`; `$5FEC` |
| Writes | `$5D27`-`$5DBD`; `$5E77`-`$5E7D`; `$5E97`-`$5EB3`; `$5ECD`-`$5ECE`; `$5EE8`-`$5EE9`; `$5F03`-`$5F04`; 8 more ranges |

#### `DrawObject` (`$BCCA`)

**Draw the object at IX (SpriteX/Y, size, mirror, picture, frame list), dissolve it, start a fall, maybe make a jumper, and dispatch: exploding, the hopper**

Changed from REX 1's DrawObject `$BAD0` (src/game/objects.asm).

Witness: L1 47643 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 141,360 t-states own (0.01 %) |
| Runs (the other recordings) | 5,078 calls (`stage1/rec/rzx-p2-12000` 2,493, `stage1/rec/rzx-p2-18000` 1,786, `stage1/rec/rzx-p2-08000` 799) |
| Called from | `PanelBox` (tail), `UpdateObject` (tail) |
| Calls | `ObjectDissolve`, `ShowBombs`, `DrawSprite`, `FindSlot`, `FindEnemySlot`, `ObjectBehaviour` (falls into), `Kind4Crawl`, `Kind4MaybeStop`, `RamTurn` (tail), `BlowUp` (tail), `MaybeJumper`, `JumperTimer` |
| Reads | `$5E66`-`$5F1F`; `$BECC`-`$BECF` (`Kind4Close+11`) |
| Writes | `$5E82`-`$5E83`; `$5E9A`-`$5E9B`; `$5EB2`-`$5EB3`; `$A054` (`SparkleMove+9`); `$A1CC`-`$A1CE` (`SpriteMirror`, `SpritePicture`); `$A248`-`$A24B` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`) |

#### `ObjectBehaviour` (`$BD27`)

**By kind: the pods' frames; kinds 9, 4, 3, 2, 5 their own behaviours; else jump, fall, the cell under it and the move; then against Rex**

Changed from REX 1's ObjectBehaviour `$BB39` (src/game/objects.asm).

Witness: L1 45603 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 51 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 16,356 calls (`stage1/rec/rzx-p2-20000` 2,960, `stage1/rec/rzx-p2-26000` 2,625, `stage1/rec/rzx-p2-34000` 2,272 and 5 more) |
| Called from | `DrawObject` (falls into), `RamTurn` (tail) |
| Calls | `PanelBox` (tail), `Kind2Drop` (tail), `Kind3Grow` (tail), `Kind4Crawl` (tail), `Kind5Burst` (tail), `Kind9Fan` (tail), `AnimatePod`, `ObjectMove`, `ObjectJump`, `ObjectFall`, `ObjectCell` |
| Reads | `$5E6F`-`$5EDB`; `$5EF6`; `$5F11`; `$5F2C`; `$5F47`; `$5F62`; 2 more ranges |

#### `ObjectCollide` (`$BD59`)

**ObjectHitsRex for the object at IX**

As REX 1's ObjectCollide `$BB66` (src/game/objects.asm).

Witness: L1 45603 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 26,077 calls (`stage1/c2` 3,496, `stage1/rec/rzx-p2-12000` 2,139, `stage1/rec/rzx-p2-04000` 1,970 and 19 more) |
| Called from | `Kind2Drop` (tail), `Kind2Wait` (tail), `Kind3Grow` (tail), `Kind4Crawl` (tail), `Kind4Close` (tail), `Kind4Wait` (tail), `Kind5Burst` (tail), `Kind5Close` (tail), `Kind5Rest` (tail), `Kind9Fan` (tail), `Kind9Close` (tail), `Kind9Rest` (tail) |
| Calls | `ObjectHitsRex` |

#### `NextObject` (`$BD5C`)

**The next object record (24 bytes on), until all are done**

As REX 1's NextObject `$BB69` (src/game/objects.asm).

Witness: L1 112141 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 66,536 calls (`stage1/rec/rzx-p2-28000` 4,959, `stage1/c2` 4,526, `stage1/rec/rzx-p2-34000` 4,026 and 20 more) |
| Called from | `UpdateObject` (tail), `BlowUp` (tail) |
| Calls | `UpdateObject` (tail) |

#### `Kind2Drop` (`$BD67`)

**Kind 2: waits, unfolds (3 frames), drops 8 lines a pass to the floor (off the bottom it dies), folds (4 frames)**

Witness: L1 7099 (c2, p2-room20, rzx-p2- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 60,841 t-states own (0.00 %) |
| Runs (the other recordings) | 7,099 calls (`stage1/c2` 1,534, `stage1/rec/rzx-p2-06000` 1,246, `stage1/rec/rzx-p2-04000` 967 and 15 more) |
| Called from | `PanelBox` (tail), `ObjectBehaviour` (tail) |
| Calls | `PanelBox` (tail), `ObjectCollide` (tail), `Kind2Wait` (tail), `BurstShot`, `ObjectCell`, `IsPassable`, `EnemyBulletsHitRex` |
| Reads | `$5E66`-`$5EFF`; `$A093`-`$A096` (`SparkleDotOut+6`); `$E2B5`-`$E376` (`RoomGridPlay+182`); `$E387`-`$E396` (`RoomGridPlay+392`); `$E3A7`-`$E424` (`RoomGridPlay+424`); `$E435`-`$E443` (`RoomGridPlay+566`); 1 more ranges |
| Writes | `$5E67`-`$5EFF`; `$A0AF`-`$A0B0` (`SparkleDots+2`) |

#### `Kind2Wait` (`$BDDA`)

**Kind 2 at rest: its timer, then it unfolds**

Witness: L1 4146 (c2, p2-room20, rzx-p2- x15).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,490 calls (`stage1/rec/rzx-p2-24000` 392, `stage1/rec/rzx-p2-20000` 188, `stage1/rec/rzx-p2-36000` 165 and 7 more) |
| Called from | `Kind2Drop` (tail) |
| Calls | `ObjectCollide` (tail) |
| Reads | `$5E78`; `$5E93`; `$5EAE`; `$5EC9`; `$5EE4` |
| Writes | `$5E78`; `$5E93`; `$5EAE`; `$5EC9`; `$5EE4` |

#### `Kind3Grow` (`$BDF2`)

**Kind 3: every 4 passes its picture one frame back, until the first**

Witness: L1 3447 (rzx-p2- x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,447 calls (`stage1/rec/rzx-p2-34000` 1,056, `stage1/rec/rzx-p2-16000` 664, `stage1/rec/rzx-p2-36000` 573 and 7 more) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `ShowBombs`, `PanelBox` (tail), `ObjectCollide` (tail) |
| Reads | `$5E6A`-`$5EFF` |
| Writes | `$5E6A`-`$5EFF` |

#### `Kind4Crawl` (`$BE22`)

**Kind 4: crawls up or down a line a pass; a solid cell or the area's edge turns it; at random it stops, opens and closes**

Witness: L1 8437 (c2, p2-room20, rzx-p2- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 9,289 t-states own (0.00 %) |
| Runs (the other recordings) | 8,437 calls (`stage1/c2` 1,440, `stage1/rec/rzx-p2-20000` 1,260, `stage1/rec/rzx-p2-22000` 1,163 and 15 more) |
| Called from | `DrawObject`, `ObjectBehaviour` (tail), `Kind4MaybeStop` (tail), `Kind4Close` (tail) |
| Calls | `Random`, `FireSpray`, `FindSlot`, `PanelBox` (tail), `ObjectCollide` (tail), `Kind4MaybeStop`, `Kind4Close` (tail), `Kind4Wait` (tail), `ObjectCell` |
| Reads | `$5E67`-`$5F51`; `$E202`-`$E472` (`RoomGridPlay+3`); `$E485`-`$E492` (`RoomGridPlay+646`) |
| Writes | `$5D26`-`$5DA2`; `$5E67`-`$5F51`; `$A093` (`SparkleDotOut+6`) |

#### `Kind4MaybeStop` (`$BEAD`)

**At random (1 in 13) a moving kind 4 stops and opens (state 2, 2 frames)**

Witness: L1 8407 (c2, p2-room20, rzx-p2- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,978 t-states own (0.00 %) |
| Runs (the other recordings) | 8,407 calls (`stage1/c2` 1,437, `stage1/rec/rzx-p2-20000` 1,252, `stage1/rec/rzx-p2-22000` 1,154 and 15 more) |
| Called from | `DrawObject`, `Kind4Crawl` |
| Calls | `Random`, `FindSlot`, `Kind4Crawl` (tail) |
| Reads | `$5E78`-`$5E7E`; `$5E93`; `$5EAE`; `$5EC9`; `$5EE4`; `$5EFF`; 3 more ranges |
| Writes | `$5D26`; `$5D44`-`$5D80`; `$5D9E`; `$5E78`-`$5E79`; `$5E93`-`$5E94`; `$5EAE`-`$5EAF`; 7 more ranges |

#### `Kind4Close` (`$BEC1`)

**Kind 4 closes, a frame a pass, then moves again**

Witness: L1 656 (c2, p2-room20, rzx-p2- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 187,334 t-states own (0.01 %) |
| Runs (the other recordings) | 656 calls (`stage1/c2` 108, `stage1/rec/rzx-p2-22000` 105, `stage1/rec/rzx-p2-20000` 96 and 15 more) |
| Called from | `PanelBox`, `Kind4Crawl` (tail) |
| Calls | `ObjectCollide` (tail), `Kind4Crawl` (tail) |
| Reads | `$5E6A`-`$5F51`; `$BF5C`-`$BF65` (`BurstShot+13`) |
| Writes | `$5E6A`-`$5F51` |

#### `Kind4Wait` (`$BEE0`)

**Kind 4 open: its timer, then it closes**

Witness: L1 2569 (c2, p2-room20, rzx-p2- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 571 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,569 calls (`stage1/c2` 443, `stage1/rec/rzx-p2-22000` 406, `stage1/rec/rzx-p2-20000` 354 and 15 more) |
| Called from | `Kind4Crawl` (tail) |
| Calls | `ObjectCollide` (tail) |
| Reads | `$5E79`; `$5E94`; `$5EAF`; `$5ECA`; `$5EE5`; `$5F00`; 3 more ranges |
| Writes | `$5E78`-`$5E79`; `$5E93`-`$5E94`; `$5EAE`-`$5EAF`; `$5EC9`-`$5ECA`; `$5EE4`-`$5EE5`; `$5EFF`-`$5F00`; 3 more ranges |

#### `Kind5Burst` (`$BEF1`)

**Kind 5: at rest, at random it opens (6 frames) and fires 1-8 climbing shots (type `$87`) in random directions, then closes**

Witness: L1 3601 (c2, rzx-p2- x13).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,601 calls (`stage1/rec/rzx-p2-38000` 941, `stage1/rec/rzx-p2-12000` 814, `stage1/rec/rzx-p2-14000` 398 and 11 more) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `Random`, `Random2`, `ObjectCollide` (tail), `BurstShot`, `Kind5Close` (tail), `Kind5Rest` (tail) |
| Reads | `$5E6A`-`$5EFF`; `$BF4B`-`$BF4E` (`BurstSpeeds`) |
| Writes | `$5E6A`-`$5EFF`; `$A1ED` (`EnemyShotKind`) |

#### `BurstShot` (`$BF4F`)

**One climbing shot from IX's X - 8: speed E, type `$87`, its rise A x 4**

Witness: L1 448 (c2, rzx-p2- x13).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 419,171 t-states own (0.03 %) |
| Runs (the other recordings) | 448 calls (`stage1/rec/rzx-p2-12000` 113, `stage1/rec/rzx-p2-38000` 99, `stage1/rec/rzx-p2-14000` 45 and 11 more) |
| Called from | `Kind2Drop`, `Kind5Burst` |
| Calls | `FindEnemySlot`, `EnemyShot` |
| Reads | `$5E66`-`$5E69`; `$5E7E`-`$5E81`; `$5E96`-`$5E9C`; `$5EAE`-`$5ED2`; `$5EED`; `$A093` (`SparkleDotOut+6`); 2 more ranges |
| Writes | `$5D26`-`$5E3E`; `$A093` (`SparkleDotOut+6`); `$A0AF`-`$A0B0` (`SparkleDots+2`); `$A22C` (`Temp1`) |
| Ports out | `$00FE`, `$10FE`, `$18FE`, `$30FE`, `$38FE`, `$48FE`, `$50FE`, `$68FE`, `$70FE`, `$88FE`, `$A8FE`, `$B8FE`, `$C0FE`, `$D8FE`, `$E0FE`, `$F8FE` |

#### `Kind5Close` (`$BF76`)

**Kind 5 closes, a frame a pass, then rests**

Witness: L1 570 (c2, rzx-p2- x13).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 768 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 570 calls (`stage1/rec/rzx-p2-12000` 155, `stage1/rec/rzx-p2-38000` 109, `stage1/rec/rzx-p2-26000` 43 and 11 more) |
| Called from | `Kind5Burst` (tail) |
| Calls | `ObjectCollide` (tail) |
| Reads | `$5E6A`-`$5EFF` |
| Writes | `$5E6A`-`$5EFF` |

#### `Kind5Rest` (`$BF95`)

**Kind 5 at rest: 1 in 25 it opens**

Witness: L1 2450 (c2, rzx-p2- x13).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 768 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,450 calls (`stage1/rec/rzx-p2-38000` 725, `stage1/rec/rzx-p2-12000` 509, `stage1/rec/rzx-p2-14000` 314 and 11 more) |
| Called from | `Kind5Burst` (tail) |
| Calls | `Random`, `ObjectCollide` (tail) |
| Writes | `$5E77`-`$5E78`; `$5E92`-`$5E93`; `$5EAD`-`$5EAE`; `$5EC8`-`$5EC9`; `$5EE3`-`$5EE4`; `$5EFE`-`$5EFF` |

#### `Kind9Fan` (`$BFA8`)

**Kind 9: at rest, at random it opens (5 frames) and fires a fan of five shots (up left, left, straight, right, up right), then closes**

Witness: L1 3493 (c2, rzx-p2- x9).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 768 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 111,893 t-states own (0.01 %) |
| Runs (the other recordings) | 3,493 calls (`stage1/rec/rzx-p2-12000` 1,074, `stage1/rec/rzx-p2-04000` 505, `stage1/rec/rzx-p2-32000` 492 and 7 more) |
| Called from | `PanelBox`, `ObjectBehaviour` (tail) |
| Calls | `PrintText`, `FindEnemySlot`, `ObjectCollide` (tail), `Kind9Close` (tail), `Kind9Rest` (tail), `SwingShotUpLeft`, `SwingShotLeft`, `SwingShotStraight`, `SwingShotRight`, `SwingShotUpRight` |
| Reads | `$5E6A`-`$5ECF`; `$5EE0`-`$5EE7`; `$5EF8`-`$5EFF`; `$5F10`-`$5F2F` |
| Writes | `$5E6A`-`$5EC9`; `$A1ED` (`EnemyShotKind`) |

#### `Kind9Close` (`$C000`)

**Kind 9 closes, a frame a pass, then rests**

Witness: L1 534 (c2, rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 534 calls (`stage1/rec/rzx-p2-12000` 150, `stage1/rec/rzx-p2-32000` 80, `stage1/rec/rzx-p2-04000` 75 and 6 more) |
| Called from | `Kind9Fan` (tail) |
| Calls | `ObjectCollide` (tail) |
| Reads | `$5E6A`-`$5EC9` |
| Writes | `$5E6A`-`$5EC9` |

#### `Kind9Rest` (`$C01F`)

**Kind 9 at rest: 1 in 25 it opens**

Witness: L1 2413 (c2, rzx-p2- x9).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 400 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,413 calls (`stage1/rec/rzx-p2-12000` 774, `stage1/rec/rzx-p2-04000` 353, `stage1/rec/rzx-p2-32000` 332 and 7 more) |
| Called from | `Kind9Fan` (tail) |
| Calls | `Random`, `ObjectCollide` (tail), `WalkRight` (tail) |
| Writes | `$5E77`-`$5E78`; `$5E92`-`$5E93`; `$5EAD`-`$5EAE`; `$5EC8`-`$5EC9` |

#### `RamTurn` (`$C032`)

**The hit foot man's turn (kind 6, from DrawObject): the turning picture at count +`$11` = 4, kind 7 at 0**

As REX 1's RamTurn `$BD44` (src/game/objects.asm).

Witness: L1 86 (rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 86 calls (`stage1/rec/rzx-p2-10000` 19, `stage1/rec/rzx-p2-26000` 12, `stage1/rec/rzx-p2-32000` 12 and 5 more) |
| Called from | `DrawObject` (tail) |
| Calls | `ObjectBehaviour` (tail) |
| Reads | `$5E77`; `$5E92`; `$5EAD`; `$5EC8`; `$5EE3`; `$5EFE` |
| Writes | `$5E6F`-`$5F04` |

#### `BlowUp` (`$C059`)

**An object explodes: the six shards drawn (DrawShard), the attribute flash; at the end it leaves a pod or the points**

As REX 1's BlowUp `$BD6B` (src/game/objects.asm).

Witness: L1 2038 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,038 calls (`stage1/rec/rzx-p2-38000` 208, `stage1/rec/rzx-p2-26000` 176, `stage1/rec/rzx-p2-24000` 160 and 19 more) |
| Called from | `DrawObject` (tail) |
| Calls | `Random`, `CopyCells3`, `FlashCells`, `NextObject` (tail), `DrawShard` |
| Reads | `$5E66`-`$5FA4`; `$A22C`-`$A22F` (`Temp1`, `Temp2`) |
| Writes | `$5E67`-`$5FA2`; `$A248`-`$A249` (`SpriteX`, `SpriteY`) |

#### `SwingShotUpLeft` (`$C141`)

**A swing gun shot up and left**

As REX 1's SwingShotUpLeft `$BE5B` (src/game/objects.asm).

Witness: L1 109 (c2, rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 109 calls (`stage1/rec/rzx-p2-12000` 30, `stage1/rec/rzx-p2-32000` 16, `stage1/rec/rzx-p2-04000` 15 and 6 more) |
| Called from | `Kind9Fan` |
| Calls | `EnemyShot`, `SwingShotSet` (tail) |
| Reads | `$5E66`; `$5E81`; `$5E9C`; `$5EB7` |
| Writes | `$5D26`-`$5DBC`; `$A22C` (`Temp1`) |

#### `SwingShotLeft` (`$C15B`)

**A swing gun shot left**

As REX 1's SwingShotLeft `$BE75` (src/game/objects.asm).

Witness: L1 109 (c2, rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 109 calls (`stage1/rec/rzx-p2-12000` 30, `stage1/rec/rzx-p2-32000` 16, `stage1/rec/rzx-p2-04000` 15 and 6 more) |
| Called from | `Kind9Fan` |
| Calls | `EnemyShot`, `SwingShotSet` (falls into) |
| Reads | `$5E66`; `$5E81`; `$5E9C`; `$5EB7` |
| Writes | `$5D35`-`$5DCB`; `$5DF8`; `$A22C` (`Temp1`) |

#### `SwingShotSet` (`$C172`)

**The shot's dX (HL) and speed**

As REX 1's SwingShotSet `$BE8C` (src/game/objects.asm).

Witness: L1 545 (c2, rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 545 calls (`stage1/rec/rzx-p2-12000` 150, `stage1/rec/rzx-p2-32000` 80, `stage1/rec/rzx-p2-04000` 75 and 6 more) |
| Called from | `SwingShotUpLeft` (tail), `SwingShotLeft` (falls into), `SwingShotStraight` (tail), `SwingShotRight` (tail), `SwingShotUpRight` (tail) |
| Calls | `SetShotSpeed` |
| Writes | `$5D27`-`$5E29` |

#### `SwingShotStraight` (`$C181`)

**A swing gun shot from X - 16 with no sideways step (dX 0)**

Witness: L1 109 (c2, rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 109 calls (`stage1/rec/rzx-p2-12000` 30, `stage1/rec/rzx-p2-32000` 16, `stage1/rec/rzx-p2-04000` 15 and 6 more) |
| Called from | `Kind9Fan` |
| Calls | `EnemyShot`, `SwingShotSet` (tail) |
| Reads | `$5E66`; `$5E81`; `$5E9C`; `$5EB7` |
| Writes | `$5D44`-`$5E07`; `$A22C` (`Temp1`) |

#### `SwingShotRight` (`$C19B`)

**A swing gun shot right**

As REX 1's SwingShotRight `$BE9B` (src/game/objects.asm).

Witness: L1 109 (c2, rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 109 calls (`stage1/rec/rzx-p2-12000` 30, `stage1/rec/rzx-p2-32000` 16, `stage1/rec/rzx-p2-04000` 15 and 6 more) |
| Called from | `Kind9Fan` |
| Calls | `EnemyShot`, `SwingShotSet` (tail) |
| Reads | `$5E66`; `$5E81`; `$5E9C`; `$5EB7` |
| Writes | `$5D53`-`$5DAD`; `$5DCB`-`$5DF8`; `$5E16`; `$A22C` (`Temp1`) |

#### `SwingShotUpRight` (`$C1B3`)

**A swing gun shot up and right**

As REX 1's SwingShotUpRight `$BEB3` (src/game/objects.asm).

Witness: L1 109 (c2, rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 109 calls (`stage1/rec/rzx-p2-12000` 30, `stage1/rec/rzx-p2-32000` 16, `stage1/rec/rzx-p2-04000` 15 and 6 more) |
| Called from | `Kind9Fan` |
| Calls | `EnemyShot`, `SwingShotSet` (tail) |
| Reads | `$5E66`; `$5E81`; `$5E9C`; `$5EB7` |
| Writes | `$5D62`-`$5E07`; `$5E25`; `$A22C` (`Temp1`) |

#### `AnimatePod` (`$C1CB`)

**The power pod's frames (PodFrames `$C253`); a pod not taken in time goes**

As REX 1's AnimatePod `$BED3` (src/game/objects.asm).

Witness: L1 9414 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,414 calls (`stage1/rec/rzx-p2-36000` 1,078, `stage1/rec/rzx-p2-30000` 1,049, `stage1/rec/rzx-p2-38000` 744 and 19 more) |
| Called from | `ObjectBehaviour` |
| Reads | `$5E6C`-`$5F51`; `$5F7A`-`$5F87`; `$C254`-`$C25D` (`PodFrames+1`) |
| Writes | `$5E6A`-`$5F4F`; `$5F78`-`$5F85` |

#### `DrawShard` (`$C25E`)

**One shard of an explosion along its path at HL: the border's speaker bit random (the explosion's crackle), the shard ORed into the buffer**

As REX 1's DrawShard `$BF66` (src/game/objects.asm).

Witness: L1 12228 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,228 calls (`stage1/rec/rzx-p2-38000` 1,248, `stage1/rec/rzx-p2-26000` 1,056, `stage1/rec/rzx-p2-24000` 960 and 19 more) |
| Called from | `BlowUp` |
| Calls | `OrChar` |
| Reads | `$5E66`-`$5ED5`; `$5EED`-`$5EF0`; `$5F08`-`$5F0B`; `$5F23`-`$5F26`; `$5F3E`-`$5F41`; `$5F59`-`$5F5C`; 5 more ranges |
| Writes | `$A22C` (`Temp1`); `$A248`-`$A249` (`SpriteX`, `SpriteY`) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE`, `$20FE`, `$28FE`, `$30FE`, `$38FE`, `$40FE`, `$48FE`, `$50FE`, `$58FE`, `$60FE`, `$68FE`, `$70FE`, `$78FE`, `$80FE`, `$88FE`, `$90FE`, `$98FE`, `$A0FE`, `$A8FE`, `$B0FE`, `$B8FE`, `$C0FE`, `$C8FE`, `$D0FE`, `$D8FE`, `$E0FE`, `$E8FE`, `$F0FE`, `$F8FE` |

#### `ObjectMove` (`$C2E7`)

**The kinds' moves: pods none, 14 drifts (Blob), the others walk right or left**

Changed from REX 1's ObjectMove `$BFEF` (src/game/objects.asm).

Witness: L1 19526 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 19,526 calls (`stage1/rec/rzx-p2-36000` 1,896, `stage1/rec/rzx-p2-30000` 1,608, `stage1/rec/rzx-p2-18000` 1,525 and 19 more) |
| Called from | `ObjectBehaviour` |
| Calls | `DriftObject` (tail), `WalkRight` (tail), `WalkLeft` (tail) |
| Reads | `$5E68`-`$5EDB`; `$5EEF`-`$5EF6`; `$5F0A`-`$5F11`; `$5F25`-`$5F2C`; `$5F40`-`$5F47`; `$5F62`; 2 more ranges |

#### `DriftObject` (`$C3C1`)

**Kind 14, the mine: drift by dX, dY; a solid cell above kills it; it rests and heads for Rex in turn, a few passes each**

Changed from REX 1's DriftObject `$C150` (src/game/objects.asm).

Witness: L1 3566 (c2, p2-room20, rzx-p2- x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,566 calls (`stage1/c2` 742, `stage1/rec/rzx-p2-18000` 660, `stage1/rec/rzx-p2-36000` 392 and 10 more) |
| Called from | `ObjectMove` (tail) |
| Calls | `KillObject` (tail), `IsSolid` |
| Reads | `$5E66`-`$5FA1`; `$A1B4`-`$A1B5` (`ObjectCellPtr`); `$A24F`-`$A250` (`RexX`, `RexY`) |
| Writes | `$5E66`-`$5FA1` |

#### `WalkRight` (`$C433`)

**A walker's step right: a solid cell ahead turns it; off the edge WalkOff; a kind 0 on a cell `$0F` falls, `$0E` hops, `$10` maybe jumps, `$15` or `$16` dissolves**

Changed from REX 1's WalkRight `$C3E0` (src/game/objects.asm).

Witness: L1 2953 (c2, p2-room20, rzx-p2- x17).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 148,576 t-states own (0.01 %) |
| Runs (the other recordings) | 2,953 calls (`stage1/rec/rzx-p2-14000` 441, `stage1/rec/rzx-p2-10000` 372, `stage1/rec/rzx-p2-32000` 366 and 16 more) |
| Called from | `Kind9Rest` (tail), `ObjectMove` (tail) |
| Calls | `BlockedRight` (tail), `EdgeLeft` (tail), `MaybeJumpRight`, `MaybeJumpLeft`, `MaybeDissolve`, `CellDissolve`, `StartFall` (tail), `IsSolid`, `ObjectHitsRex` |
| Reads | `$5E66`-`$5F4E`; `$A01B`-`$A01C` (`SparkleDots2+21`); `$A1B4`-`$A1B5` (`ObjectCellPtr`); `$E26A`-`$E273` (`RoomGridPlay+107`); `$E287`-`$E293` (`RoomGridPlay+136`); `$E2BA`-`$E2F9` (`RoomGridPlay+187`); 5 more ranges |
| Writes | `$5E66`-`$5E68`; `$5E81`-`$5E83`; `$5E9C`-`$5F10`; `$5F23`-`$5F28`; `$5F3E`-`$5F40` |

#### `BlockedRight` (`$C4C6`)

**Blocked: kinds 6 and 7 stay, the others turn**

As REX 1's BlockedRight `$C469` (src/game/objects.asm).

Witness: L1 67 (rzx-p2- x15).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 400 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1 call (`stage1/rec/rzx-p2-08000` 1) |
| Called from | `WalkRight` (tail) |
| Calls | `TurnAround` (falls into) |
| Reads | `$5EB9`-`$5EC0` |
| Writes | `$5EB9` |

#### `TurnAround` (`$C4CF`)

**Direction ^ 1**

As REX 1's TurnAround `$C472` (src/game/objects.asm).

Witness: L1 63 (rzx-p2- x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/rzx-p2-10000` 8) |
| Called from | `BlockedRight` (falls into), `EdgeLeft` (tail) |
| Calls | `WalkOff` (falls into) |
| Reads | `$5E68`; `$5E83`; `$5EB9`; `$5ED4` |
| Writes | `$5E68`; `$5E83`; `$5EB9`; `$5ED4` |

#### `WalkOff` (`$C4D7`)

**Kinds 6 and 7 off the edge die (KillObject); 3, 4, 5 vanish (ObjectGone: alive 0, no score)**

Changed from REX 1's WalkOff `$C47A` (src/game/objects.asm).

Witness: L1 114 (c2, rzx-p2- x16).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 400 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 108 calls (`stage1/rec/rzx-p2-34000` 23, `stage1/rec/rzx-p2-10000` 17, `stage1/rec/rzx-p2-32000` 15 and 9 more) |
| Called from | `TurnAround` (falls into), `WalkLeft` (tail) |
| Calls | `KillObject` (tail) |
| Reads | `$5E6F`; `$5E8A`; `$5EA5`; `$5EC0`; `$5EDB`; `$5EF6`; 2 more ranges |

#### `EdgeLeft` (`$C4F9`)

**At the left edge: kind 0 dies, the others turn**

As REX 1's EdgeLeft `$C49C` (src/game/objects.asm).

Witness: L1 7 (c2, rzx-p2-02000, rzx-p2-04000, rzx-p2-10000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 14 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 calls (`stage1/c2` 2) |
| Called from | `WalkRight` (tail) |
| Calls | `TurnAround` (tail) |
| Reads | `$5EA5`; `$5EC0` |
| Writes | `$5EA8`; `$5EC3` |

#### `WalkLeft` (`$C503`)

**A walker's step left (as WalkRight)**

Changed from REX 1's WalkLeft `$C4A6` (src/game/objects.asm).

Witness: L1 3105 (c2, p2-room20, rzx-p2- x18).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 81,674 t-states own (0.01 %) |
| Runs (the other recordings) | 3,105 calls (`stage1/rec/rzx-p2-34000` 362, `stage1/rec/rzx-p2-32000` 323, `stage1/c2` 264 and 17 more) |
| Called from | `PanelBox`, `ObjectMove` (tail) |
| Calls | `ShowBombs`, `WalkOff` (tail), `MaybeJumpRight`, `MaybeJumpLeft`, `CellDissolve`, `StartFallIfIdle` (tail), `IsSolid` |
| Reads | `$5E66`-`$5F4E`; `$A1B4`-`$A1B5` (`ObjectCellPtr`); `$E262`-`$E270` (`RoomGridPlay+99`); `$E282`-`$E292` (`RoomGridPlay+131`); `$E2B2`-`$E2F6` (`RoomGridPlay+179`); `$E307`-`$E30A` (`RoomGridPlay+264`); 8 more ranges |
| Writes | `$5E66`-`$5E68`; `$5E81`-`$5EB9`; `$5ED2`-`$5ED4`; `$5EED`-`$5F25`; `$5F3E`-`$5F40` |

#### `MaybeJumpRight` (`$C598`)

**At random a jump instead of the step**

As REX 1's MaybeJumpRight `$C531` (src/game/objects.asm).

Witness: L1 26 (rzx-p2-10000, rzx-p2-14000, rzx-p2-36000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 26 calls (`stage1/rec/rzx-p2-14000` 12, `stage1/rec/rzx-p2-10000` 10, `stage1/rec/rzx-p2-36000` 4) |
| Called from | `WalkRight`, `WalkLeft` |
| Calls | `Random` |
| Reads | `$5E92`; `$5EE3`; `$5F19` |
| Writes | `$5E77`; `$5E92`; `$5EE3` |

#### `MaybeJumpLeft` (`$C5A7`)

**At random a jump**

As REX 1's MaybeJumpLeft `$C540` (src/game/objects.asm).

Witness: L1 4 (c2, rzx-p2-20000, rzx-p2-30000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/c2` 2, `stage1/rec/rzx-p2-20000` 1, `stage1/rec/rzx-p2-30000` 1) |
| Called from | `WalkRight`, `WalkLeft` |
| Calls | `Random`, `StartFallIfIdle` (tail) |

#### `MaybeDissolve` (`$C5B4`)

**Walker on a cell `$15`: at random (1 in 2) it dissolves**

Witness: L1 8 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 98,123 t-states own (0.01 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/rzx-p2-00000` 4, `stage1/c2` 4) |
| Called from | `PanelBox`, `WalkRight` |
| Calls | `Random` |
| Reads | `$5E6F`-`$5E87`; `$5E9F`; `$5EB7`; `$5ECF`-`$5EE7`; `$5EFF`; `$5F17`; 1 more ranges |

#### `CellDissolve` (`$C5BA`)

**Walker on a cell `$16`: it dissolves (ObjectFadeOut)**

Witness: L1 8 (c2, rzx-p2-00000, rzx-p2-16000, rzx-p2-28000, rzx-p2-32000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/rzx-p2-32000` 2, `stage1/rec/rzx-p2-16000` 1, `stage1/rec/rzx-p2-28000` 1) |
| Called from | `WalkRight`, `WalkLeft` |
| Calls | `ObjectFadeOut`, `SetHop` (falls into) |

#### `SetHop` (`$C5C7`)

**The hop's state: picture HL, speed, timers, bit 7 of the kind**

As REX 1's SetHop `$C556` (src/game/objects.asm).

Witness: L1 70 (c2, rzx-p2- x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 70 calls (`stage1/rec/rzx-p2-34000` 8, `stage1/rec/rzx-p2-16000` 8, `stage1/rec/rzx-p2-32000` 7 and 13 more) |
| Called from | `CellDissolve` (falls into), `MakeJumper` |
| Calls | `Random` |
| Reads | `$5E6F`; `$5E8A`; `$5EA5`; `$5EC0`; `$5EDB`; `$5EF6`; 3 more ranges |
| Writes | `$5E6A`-`$5F50` |

#### `MaybeJumper` (`$C5E8`)

**A kind 0 walker at X & 7 = 2 or 4 becomes a jumper one time in 43 (MakeJumper)**

Changed from REX 1's MaybeJumper `$C577` (src/game/objects.asm).

Witness: L1 47642 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 47,642 calls (`stage1/c2` 4,800, `stage1/rec/rzx-p2-36000` 3,105, `stage1/rec/rzx-p2-20000` 3,056 and 19 more) |
| Called from | `DrawObject` |
| Calls | `Random`, `MakeJumper` (falls into) |
| Reads | `$5E66`-`$5EDB`; `$5EED`-`$5EF6`; `$5F08`-`$5F11`; `$5F23`-`$5F2C`; `$5F47`; `$5F62`; 2 more ranges |

#### `MakeJumper` (`$C60D`)

**A walker standing still becomes a jumper: SpriteJumper `$8338`, SetHop, timer 2**

Witness: L1 73 (c2, rzx-p2- x15).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 94,800 t-states own (0.01 %) |
| Runs (the other recordings) | 73 calls (`stage1/rec/rzx-p2-34000` 9, `stage1/rec/rzx-p2-16000` 8, `stage1/rec/rzx-p2-32000` 7 and 13 more) |
| Called from | `ObjectFadeOut`, `PanelBox`, `MaybeJumper` (falls into), `SpawnAnywhere` |
| Calls | `SetHop` |
| Reads | `$5E69`-`$5F4F` |
| Writes | `$5E78`; `$5E93`; `$5EAE`; `$5EC9`; `$5EE4`; `$5EFF`; 3 more ranges |

#### `JumperTimer` (`$C627`)

**The jumper's timer; at its end it walks again**

As REX 1's JumperTimer `$C5B6` (src/game/objects.asm).

Witness: L1 47642 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 47,642 calls (`stage1/c2` 4,800, `stage1/rec/rzx-p2-36000` 3,105, `stage1/rec/rzx-p2-20000` 3,056 and 19 more) |
| Called from | `DrawObject` |
| Reads | `$5E6F`-`$5EE4`; `$5EF6`-`$5EFF`; `$5F11`-`$5F1A`; `$5F2C`-`$5F35`; `$5F47`-`$5F50`; `$5F62`; 2 more ranges |
| Writes | `$5E6F`-`$5E78`; `$5E8A`-`$5E93`; `$5EA5`-`$5EAE`; `$5EC0`-`$5EC9`; `$5EDB`-`$5EE4`; `$5EF6`-`$5EFF`; 3 more ranges |

#### `StartFallIfIdle` (`$C66E`)

**If the timer is 0, StartFall**

As REX 1's StartFallIfIdle `$C5FD` (src/game/objects.asm).

Witness: L1 10 (c2, rzx-p2-10000, rzx-p2-16000, rzx-p2-20000, rzx-p2-30000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`stage1/rec/rzx-p2-20000` 3, `stage1/rec/rzx-p2-16000` 2, `stage1/c2` 2 and 2 more) |
| Called from | `WalkLeft` (tail), `MaybeJumpLeft` (tail) |
| Calls | `StartFall` (falls into) |
| Reads | `$5E77`; `$5E92`-`$5EE3`; `$5EFE`-`$5F19` |
| Writes | `$5E9F`-`$5EA1`; `$5EBA`-`$5EBC`; `$5ED5`-`$5ED7`; `$5F0B`-`$5F0D` |

#### `StartFall` (`$C673`)

**An object not falling and below line 24 starts to fall (JumpSteps `$CE68`)**

As REX 1's StartFall `$C602` (src/game/objects.asm).

Witness: L1 25 (c2, rzx-p2- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20 calls (`stage1/rec/rzx-p2-30000` 6, `stage1/rec/rzx-p2-20000` 6, `stage1/rec/rzx-p2-26000` 2 and 4 more) |
| Called from | `WalkRight` (tail), `StartFallIfIdle` (falls into), `HitObject` |
| Reads | `$5E67`-`$5E6C`; `$5E82`-`$5E87`; `$5E9D`-`$5EA2`; `$5EB8`-`$5EBD`; `$5ED3`-`$5ED8`; `$5EEE`-`$5EF3` |
| Writes | `$5E69`-`$5E6B`; `$5E84`-`$5E86`; `$5E9F`-`$5EA1`; `$5EBA`-`$5EBC`; `$5ED5`-`$5ED7`; `$5EF0`-`$5EF2` |

#### `ObjectJump` (`$C691`)

**The jump of an object by its jump table (pods and the mine none); a solid cell above ends it and kinds 6 and 7 die**

Changed from REX 1's ObjectJump `$C620` (src/game/objects.asm).

Witness: L1 19526 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 327,397 t-states own (0.02 %) |
| Runs (the other recordings) | 19,526 calls (`stage1/rec/rzx-p2-36000` 1,896, `stage1/rec/rzx-p2-30000` 1,608, `stage1/rec/rzx-p2-18000` 1,525 and 19 more) |
| Called from | `PanelBox`, `ObjectBehaviour` |
| Calls | `KillObject` (tail), `CellPointer`, `ObjectFall`, `IsSolid`, `BulletsHitObject` |
| Reads | `$5E66`-`$5F2F`; `$5F41`-`$5F47`; `$5F62`; `$5F7D`; `$5F98`; `$CE68`-`$CE72` (`JumpSteps`); 8 more ranges |
| Writes | `$5E67`-`$5E86`; `$5E97`-`$5F14`; `$5F27`-`$5F2C`; `$A248`-`$A249` (`SpriteX`, `SpriteY`) |

#### `ObjectFall` (`$C721`)

**The fall: by the fall speed until a solid cell; on a cell of type 3 the object dies; below line `$B8` it is gone**

Witness: L1 19526 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 881,040 t-states own (0.06 %) |
| Runs (the other recordings) | 19,526 calls (`stage1/rec/rzx-p2-36000` 1,896, `stage1/rec/rzx-p2-30000` 1,608, `stage1/rec/rzx-p2-18000` 1,525 and 19 more) |
| Called from | `DroneOrbit`, `PanelBox`, `ObjectBehaviour`, `ObjectJump` |
| Calls | `KillObject` (tail), `PrintText`, `FallKill`, `ObjectCell`, `DrawRoomCell`, `IsPassable`, `Channels` |
| Reads | `$5860`-`$5AFF` (screen); `$5E66`-`$5EF8`; `$5F09`-`$5F11`; `$5F24`-`$5F2C`; `$5F3F`-`$5F47`; `$5F62`; 8 more ranges |
| Writes | `$5860`-`$5925` (screen); `$593B`-`$5945` (screen); `$595B`-`$5965` (screen); `$597B`-`$5985` (screen); `$599B`-`$59A2` (screen); `$59BB`-`$5AFF` (screen); 6 more ranges |

#### `FallKill` (`$C78C`)

**The falling object dies on a cell of type 3: IX+`$15` = `$FF`, KillObject**

Witness: L1 13 (rzx-p2- x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13 calls (`stage1/rec/rzx-p2-08000` 6, `stage1/rec/rzx-p2-16000` 2, `stage1/rec/rzx-p2-30000` 2 and 3 more) |
| Called from | `ObjectFall` |
| Calls | `KillObject`, `DrawRoom` |
| Writes | `$5E7B`; `$5E96`; `$5EB1`; `$5ECC`; `$5EE7`; `$5F02` |

#### `ObjectCell` (`$C794`)

**ObjectCellPtr `$A1B4` = the grid cell of the object at IX**

As REX 1's ObjectCell `$C72B` (src/game/objects.asm).

Witness: L1 42807 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 490 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 42,807 calls (`stage1/rec/rzx-p2-36000` 3,636, `stage1/c2` 3,328, `stage1/rec/rzx-p2-20000` 3,116 and 19 more) |
| Called from | `ObjectBehaviour`, `Kind2Drop`, `Kind4Crawl`, `ObjectFall` |
| Calls | `CellPointer` |
| Reads | `$5E66`-`$5EEF`; `$5F08`-`$5F0A`; `$5F23`-`$5F25`; `$5F3E`-`$5F40`; `$5F59`-`$5F5B`; `$5F74`-`$5F76`; 1 more ranges |
| Writes | `$A1B4`-`$A1B5` (`ObjectCellPtr`); `$A248`-`$A249` (`SpriteX`, `SpriteY`) |

### Part 2 (REX 2): rooms

`src/rex2/rooms.asm`

#### `DrawRoom` (`$C7AE`)

**Draw the room: silence, the map's 7 x 10 blocks into the grid, the attribute shadow and SceneryCellList (its pixel writes into the buffer are wiped by BuildRoom's ClearBuffer after it; the cell list redraws them)**

As REX 1's DrawRoom `$C745` (src/game/rooms.asm).

Witness: L1 32 (c2, p2-room20, rzx-p2- x17).

[Animation: `DrawRoom` at work](img/routines/DrawRoom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4,704 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 6,484,470 t-states own (0.45 %) |
| Runs (the other recordings) | 32 calls (`stage1/c2` 5, `stage1/rec/rzx-p2-00000` 3, `stage1/rec/rzx-p2-24000` 2 and 16 more) |
| Called from | `BuildRoom`, `FallKill` |
| Calls | `DrawBlockRow`, `DrawRoomCell`, `Multiply`, `SoundReset`, `SoundSilence`, `SfxGun` |
| Reads | `$5860`-`$5AFF` (screen); `$62E0`-`$62FF` (`DevLinkPut+13`, `DevLinkState`, `Unused62FE`); `$6311`-`$63E7` (`Font+11`); `$6450`-`$6467` (`Font+330`); `$64D0`-`$64DF` (`Font+458`); `$6568`-`$656F` (`CharFlags+98`); 25 more ranges |
| Writes | `$5860`-`$5925` (screen); `$5938`-`$5945` (screen); `$5958`-`$5965` (screen); `$5978`-`$5985` (screen); `$5998`-`$59A2` (screen); `$59B8`-`$5AFF` (screen); 8 more ranges |

#### `DrawBlockRow` (`$C82E`)

**One row of 10 blocks**

As REX 1's DrawBlockRow `$C7C5` (src/game/rooms.asm).

Witness: L1 2240 (c2, p2-room20, rzx-p2- x17).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,247 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,240 calls (`stage1/c2` 350, `stage1/rec/rzx-p2-00000` 210, `stage1/rec/rzx-p2-20000` 140 and 16 more) |
| Called from | `DrawRoom` |
| Calls | `DrawRoomCell` |
| Reads | `$6F06`-`$6F44` (`BlockDefs`); `$6F84`-`$6F8C` (`BlockDefs+126`); `$6FA8`-`$7358` (`BlockDefs+162`); `$73B3`-`$75E9` (`BlockDefs+1197`); `$7644`-`$76B8` (`BlockDefs+1854`); `$7737`-`$7805` (`BlockDefs+2097`) |

#### `DrawRoomCell` (`$C84B`)

**One character A at IX into the buffer: its attribute (CharAttrs) in the shadow, its type (CharFlags) in the grid, its 8 bytes; all but characters 0, 1, `$10`, `$81`, `$95`, `$96`, `$C6`, `$D6` listed at `$A252` with their number in CellIndexMap `$DE9F`**

Changed from REX 1's DrawRoomCell `$C7E2` (src/game/rooms.asm).

Witness: L1 20160 (c2, p2-room20, rzx-p2- x17).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,234 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 133,963,832 t-states own (9.23 %) |
| Runs (the other recordings) | 20,160 calls (`stage1/c2` 3,150, `stage1/rec/rzx-p2-00000` 1,890, `stage1/rec/rzx-p2-02000` 1,260 and 16 more) |
| Called from | `WaitFireOrAttract`, `BossExplodes`, `DroneOrbit`, `ObjectFall`, `DrawRoom`, `DrawBlockRow`, `MenuCode` |
| Calls | `DrawRoomChar` |
| Reads | `$6506`-`$6F05` (`CharFlags`, `CharGraphics`, `CharAttrs`); `$A093` (`SparkleDotOut+6`); `$A0B8` (`SparkleDots+11`); `$A1B6`-`$A1B8` (`RoomCellPtr`); `$A22E` (`Temp2`); `$A252`-`$A253` (`RoomColumn`); 5 more ranges |
| Writes | `$5860`-`$5AFF` (screen); `$A020`-`$A02E` (`SparkleDots2+26`, `SparkleDir`); `$A043`-`$A044` (`SparkleDir+32`); `$A088`-`$A093` (`SparkleDotStore+1`, `SparkleDotOut`); `$A1B6`-`$A1B8` (`RoomCellPtr`); `$A22E` (`Temp2`); 6 more ranges |

#### `DrawRoomChar` (`$C906`)

**One character's 8 bytes into the back buffer**

As REX 1's DrawRoomChar `$C893` (src/game/rooms.asm).

Witness: L1 20160 (c2, p2-room20, rzx-p2- x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20,160 calls (`stage1/c2` 3,150, `stage1/rec/rzx-p2-00000` 1,890, `stage2/rec/p2-room20` 1,260 and 16 more) |
| Called from | `DrawRoomCell` |
| Calls | `CopyAttrs`, `Delay` |
| Reads | `$A22C` (`Temp1`) |
| Writes | `$A22C` (`Temp1`) |

#### `CopyAttrs` (`$C932`)

**The attribute shadow `$E55F` to the screen's play rows `$5860`; the side columns white**

As REX 1's CopyAttrs `$C8BF` (src/game/rooms.asm).

Witness: L1 65 (c2, p2-room20, rzx-p2- x19).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 7 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 30 t-states own (0.00 %) |
| Runs (the other recordings) | 65 calls (`stage1/c2` 6, `stage1/rec/rzx-p2-18000` 6, `stage1/rec/rzx-p2-24000` 6 and 18 more) |
| Called from | `SmartBombStep`, `BuildRoom`, `DrawRoomChar` |
| Reads | `$E55F`-`$E7FE` (`AttrShadowPlay`) |
| Writes | `$5860`-`$5AFF` (screen); `$A02E` (`SparkleDir+11`) |

#### `Delay` (`$C94E`)

**Wait BC x 10 loops**

As REX 1's Delay `$C8DB` (src/game/rooms.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 250 t-states own (0.00 %) |
| Called from | `DrawRoomChar`, `BulletLoop` (tail) |
| Reads | `$A0B8` (`SparkleDots+11`) |
| Writes | `$A02D` (`SparkleDir+10`) |

#### `Multiply` (`$C95B`)

**HL = DE x B**

As REX 1's Multiply `$C8E8` (src/game/rooms.asm).

Witness: L1 3403 (c2, p2-room20, rzx-p2- x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,403 calls (`stage1/rec/rzx-p2-40000` 1,099, `stage1/c2` 360, `stage1/rec/rzx-p2-00000` 216 and 17 more) |
| Called from | `BossExplodes`, `DrawRoom`, `ReadExits` |

#### `ReadExits` (`$C962`)

**The room's exits and object list from RoomExits; the list's header: count, spawn sides, timers, spawn kind**

As REX 1's ReadExits `$C8EF` (src/game/rooms.asm).

Witness: L1 32 (c2, p2-room20, rzx-p2- x17).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 28,244 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/c2` 5, `stage1/rec/rzx-p2-00000` 3, `stage1/rec/rzx-p2-18000` 2 and 16 more) |
| Called from | `MainLoop`, `GiveLaser`, `BuildRoom` |
| Calls | `NewGame` (tail), `Multiply`, `SetSpawnRight`, `MakeObject` |
| Reads | `$5E72`-`$5EA2`; `$5EBA`; `$5ED2`; `$5EEA`; `$5F02`; `$5F1A`; 19 more ranges |
| Writes | `$A045`-`$A048` (`SparkleDir+34`); `$A1B9`-`$A1C7` (`ObjectListPtr`, `HumanPicture`, `BoxX`, `BoxY` and 5 more); `$A1DC`-`$A1DD` (`SpawnTimer`, `SpawnPeriod`); `$A221`-`$A22B` (`SpawnKind`, `GrowthsKilled`, `HiScore`, `RoomRight` and 5 more) |

#### `SetSpawnTop` (`$C9BB`)

**SpawnTop `$A1C7` = `$FF`**

As REX 1's SetSpawnTop `$C948` (src/game/rooms.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 6 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `SetSpawnRight` (`$C9C1`)

**SpawnRight `$A1C6` = `$FF`**

As REX 1's SetSpawnRight `$C94E` (src/game/rooms.asm).

Witness: L1 8 (c2, rzx-p2-00000, rzx-p2-06000, rzx-p2-08000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/c2` 3, `stage1/rec/rzx-p2-00000` 3, `stage1/rec/rzx-p2-06000` 1 and 1 more) |
| Called from | `ReadExits` |
| Writes | `$A1C6` (`SpawnRight`) |

#### `SetSpawnLeft` (`$C9C7`)

**SpawnLeft `$A1C5` = `$FF`**

As REX 1's SetSpawnLeft `$C954` (src/game/rooms.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 50,267 t-states own (0.00 %) |
| Called from | `MainLoop`, `BuildRoom` |
| Reads | `$5E72`; `$5E8A`; `$5EA2`; `$5EBA`; `$5ED2`; `$A043`-`$A045` (`SparkleDir+32`); 1 more ranges |
| Writes | `$A043` (`SparkleDir+32`) |

#### `ChangeRoom` (`$C9CD`)

**JP MainLoop: the exits' way into the new room (part 2 has no end room)**

Witness: L1 13 (p2-room20, rzx-p2- x11).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 13 calls (`stage1/rec/rzx-p2-02000` 2, `stage1/rec/rzx-p2-00000` 1, `stage1/rec/rzx-p2-04000` 1 and 9 more) |
| Called from | `ExitLeft` (tail), `ExitRight` (tail), `ExitTop` (tail) |
| Calls | `MainLoop` (tail) |

#### `StartScriptSpawn` (`$C9D0`)

**The scripted spawn starts: step 1, timer, count 0 (as REX 1; nothing calls it in part 2)**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SpawnScripted` (`$C9E3`)

**The scripted spawn's step: every few passes the next record of ScriptSpawn into a free object**

As REX 1's SpawnScripted `$C978` (src/game/rooms.asm).

Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 28 t-states own (0.00 %) |
| Runs (the other recordings) | 10,871 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516 and 20 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `ShowBombs`, `SpawnAnywhere` |
| Reads | `$A02C` (`SparkleDir+9`); `$A1DE` (`ScriptSpawnStep`) |

#### `SpawnRandom` (`$CA35`)

**The random spawn: every SpawnPeriod passes, into the first free object record (SpawnAnywhere)**

Changed from REX 1's SpawnRandom `$C9CA` (src/game/rooms.asm).

Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).

[Animation: `SpawnRandom` at work](img/routines/SpawnRandom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 136 t-states own (0.00 %) |
| Runs (the other recordings) | 10,871 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516 and 20 more) |
| Called from | `MainLoop`, `Attract`, `SpawnAnywhere` |
| Calls | `SpawnAnywhere`, `MakeObject` |
| Reads | `$5E72`-`$5EDE`; `$5EF9`; `$5F14`; `$5F2F`; `$5F4A`; `$5F65`; 6 more ranges |
| Writes | `$5EC6`-`$5EC7`; `$A1DC` (`SpawnTimer`) |

#### `SpawnAnywhere` (`$CA69`)

**A spawn at a random place (X 24-`$DF`, Y 32-`$A7`) away from Rex with ground under it: SpawnKind (bit 7: half the time kind 0), random facing, it fades in; a kind 0 becomes a jumper**

Witness: L1 6278 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 2,763 t-states own (0.00 %) |
| Runs (the other recordings) | 5,003 calls (`stage1/rec/rzx-p2-28000` 480, `stage1/rec/rzx-p2-16000` 424, `stage1/rec/rzx-p2-08000` 413 and 19 more) |
| Called from | `SpawnScripted`, `SpawnRandom` |
| Calls | `ObjectFadeIn`, `ShowBombs`, `Random`, `Random2`, `MakeJumper`, `SpawnRandom`, `FindGround`, `MakeObject` |
| Reads | `$5E6F`-`$5E8A`; `$5EA5`; `$5EC0`; `$5EDB`; `$5EF6`; `$5F11`; 9 more ranges |
| Writes | `$5E66`-`$5F5B`; `$5F74`-`$5F76`; `$5F8F`-`$5F91`; `$A0AF`-`$A0B0` (`SparkleDots+2`); `$A248`-`$A249` (`SpriteX`, `SpriteY`) |

#### `FindGround` (`$CAF6`)

**Find a place with ground under it for a spawn**

As REX 1's FindGround `$CB03` (src/game/rooms.asm).

Witness: L1 4632 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 2,623 t-states own (0.00 %) |
| Runs (the other recordings) | 4,632 calls (`stage1/rec/rzx-p2-28000` 437, `stage1/rec/rzx-p2-16000` 397, `stage1/rec/rzx-p2-08000` 375 and 19 more) |
| Called from | `SpawnAnywhere` |
| Calls | `PrintText`, `CellPointer`, `IsPassable`, `BulletsHitObject` |
| Reads | `$A093`-`$A094` (`SparkleDotOut+6`); `$A22C`-`$A22D` (`Temp1`); `$E244`-`$E49A` (`RoomGridPlay+69`) |
| Writes | `$A093`-`$A094` (`SparkleDotOut+6`); `$A22C`-`$A22D` (`Temp1`) |

#### `MakeObjects` (`$CB41`)

**Build the room's objects from its list (ObjectListPtr `$A1B9`): [kind][X][Y] each**

As REX 1's MakeObjects `$CB52` (src/game/rooms.asm).

Witness: L1 32 (c2, p2-room20, rzx-p2- x17).

[Animation: `MakeObjects` at work](img/routines/MakeObjects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 65,936 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/c2` 5, `stage1/rec/rzx-p2-00000` 3, `stage1/rec/rzx-p2-20000` 2 and 16 more) |
| Called from | `DroneOrbit`, `BuildRoom` |
| Calls | `MakeObjectIY`, `MakeObject`, `BulletsHitObject` |
| Reads | `$5E66`-`$5FE4`; `$A020`-`$A021` (`SparkleDots2+26`); `$A1B9`-`$A1BA` (`ObjectListPtr`); `$AED0`-`$AEE3` (`MirrorTable+126`); `$AF3F`-`$AF48` (`MirrorTable+237`); `$AFC5`-`$AFD8` (`RoomObjectLists+3`); 6 more ranges |
| Writes | `$5E66`-`$5FE5` |

#### `MakeObjectIY` (`$CB77`)

**Make the object of the list record at IY (kind from IY+0)**

As REX 1's MakeObjectIY `$CB88` (src/game/rooms.asm).

Witness: L1 164 (c2, p2-room20, rzx-p2- x17).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 18 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 164 calls (`stage1/c2` 22, `stage1/rec/rzx-p2-26000` 15, `stage1/rec/rzx-p2-20000` 14 and 16 more) |
| Called from | `MakeObjects` |
| Calls | `MakeObject` (falls into) |
| Reads | `$AFC5`-`$AFD5` (`RoomObjectLists+3`); `$AFEF`-`$B024` (`RoomObjectLists+45`); `$B04E`-`$B06A` (`RoomObjectLists+140`); `$B087`-`$B0DC` (`RoomObjectLists+197`); `$B0F3`-`$B121` (`RoomObjectLists+305`); `$B138`-`$B144` (`RoomObjectLists+374`); 1 more ranges |
| Writes | `$5E66`-`$5E7D` |

#### `MakeObject` (`$CB7A`)

**Make an object of kind A at IX: the common sizes, the kind's initialiser (0, 1, 2, 3, 4, 5, 6, 9, 14 and the bonus pod `$7C`), its place from the list entry at IY**

Changed from REX 1's MakeObject `$CB8B` (src/game/rooms.asm).

Witness: L1 300 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 21,349 t-states own (0.00 %) |
| Runs (the other recordings) | 299 calls (`stage1/c2` 31, `stage1/rec/rzx-p2-20000` 23, `stage1/rec/rzx-p2-38000` 22 and 18 more) |
| Called from | `ReadExits`, `SpawnRandom`, `SpawnAnywhere`, `MakeObjects`, `MakeObjectIY` (falls into) |
| Calls | `InitKind0`, `InitKind6`, `InitKind1`, `InitKind3`, `InitKind2`, `InitKind4`, `InitBonusPod`, `InitKind9`, `InitKind5`, `InitKind14`, `SpeedUpTick`, `WalkRightKey`, `WalkLeftKey` |
| Reads | `$5E4E`-`$5E50`; `$9F11`-`$9F13` (`DissolveMasks+6`); `$A0E9`-`$A0EB` (`SparkleDots+60`); `$A203`-`$A205` (`AnimCount2`, `AnimCount3`, `Bombs`); `$A9F5`-`$AA0B` (`AttractPass+62`, `LobPaths`); `$AED0`-`$AEE2` (`MirrorTable+126`); 11 more ranges |
| Writes | `$5E66`-`$5FA6` |

#### `InitKind0` (`$CC05`)

**Foot man: SpriteFootMan `$8198`, ShiftFrames**

As REX 1's InitKind0 `$CC48` (src/game/rooms.asm).

Witness: L1 59 (c2, rzx-p2- x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 59 calls (`stage1/rec/rzx-p2-34000` 7, `stage1/rec/rzx-p2-16000` 7, `stage1/rec/rzx-p2-20000` 6 and 13 more) |
| Called from | `MakeObject` |
| Writes | `$5E77`-`$5E7A`; `$5E92`-`$5E95`; `$5EAD`-`$5EB0`; `$5EC8`-`$5ECB`; `$5EE3`-`$5EE6`; `$5EFE`-`$5F01`; 3 more ranges |

#### `InitKind6` (`$CC18`)

**Kind 6**

As REX 1's InitKind6 `$CC5B` (src/game/rooms.asm).

Witness: L1 14 (c2, p2-room20, rzx-p2- x6).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 25 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 14 calls (`stage2/rec/p2-room20` 4, `stage1/rec/rzx-p2-26000` 3, `stage1/rec/rzx-p2-10000` 2 and 5 more) |
| Called from | `MakeObject` |
| Writes | `$5E85`-`$5F01`; `$5F42`-`$5F52` |

#### `InitKind1` (`$CC40`)

**Kind 1: picture `$8F00`, ShiftFrames**

Witness: L1 11 (p2-room20, rzx-p2- x6).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 87 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/rec/rzx-p2-10000` 4, `stage1/rec/rzx-p2-14000` 2, `stage1/rec/rzx-p2-18000` 1 and 4 more) |
| Called from | `MakeObject` |
| Writes | `$5E76`-`$5E7B`; `$5E91`-`$5E96`; `$5EAC`-`$5EB1`; `$5EC7`-`$5EE7` |

#### `InitKind3` (`$CC53`)

**Kind 3: picture `$8BE0`, frame timer 5**

Witness: L1 10 (rzx-p2- x6).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10 calls (`stage1/rec/rzx-p2-34000` 3, `stage1/rec/rzx-p2-12000` 2, `stage1/rec/rzx-p2-16000` 2 and 3 more) |
| Called from | `MakeObject` |
| Reads | `$5E6F`; `$5E8A`; `$5EA5`; `$5EC0` |
| Writes | `$5E6A`-`$5ECC` |

#### `InitKind2` (`$CC75`)

**Kind 2: picture `$8D20`, a random wait 100-227, kind `$82`**

Witness: L1 45 (c2, p2-room20, rzx-p2- x11).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 226 t-states own (0.00 %) |
| Runs (the other recordings) | 45 calls (`stage1/c2` 10, `stage1/rec/rzx-p2-24000` 5, `stage1/rec/rzx-p2-04000` 4 and 10 more) |
| Called from | `MakeObject` |
| Calls | `Random2` |
| Writes | `$5E6A`-`$5F0A`; `$5F22` |

#### `InitKind4` (`$CC9D`)

**Kind 4: picture `$8FC0`**

Witness: L1 56 (c2, p2-room20, rzx-p2- x12).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 136 t-states own (0.00 %) |
| Runs (the other recordings) | 56 calls (`stage1/c2` 8, `stage1/rec/rzx-p2-20000` 7, `stage2/rec/p2-room20` 6 and 11 more) |
| Called from | `MakeObject` |
| Reads | `$5E6F`; `$5EA5`; `$5EC0`; `$5EDB`; `$5EF6`; `$5F11`; 2 more ranges |
| Writes | `$5E6A`-`$5E7B`; `$5EA0`-`$5F53` |

#### `InitBonusPod` (`$CCBF`)

**Kind `$7D`, the bonus pod**

As REX 1's InitBonusPod `$CCE6` (src/game/rooms.asm).

Witness: L1 1 (rzx-p2-30000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/rzx-p2-30000` 1) |
| Called from | `MakeObject` |
| Reads | `$5E6F` |
| Writes | `$5E6A`-`$5E74` |

#### `InitKind9` (`$CCD1`)

**Kind 9, the fan gun: picture `$9040`, five shots**

Changed from REX 1's InitKind9 `$CCF8` (src/game/rooms.asm).

Witness: L1 9 (c2, rzx-p2- x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9 calls (`stage1/rec/rzx-p2-10000` 3, `stage1/rec/rzx-p2-02000` 2, `stage1/rec/rzx-p2-04000` 1 and 3 more) |
| Called from | `MakeObject` |
| Reads | `$5E6F`; `$5E8A`; `$5EA5`; `$5EC0` |
| Writes | `$5E6A`-`$5ECC` |

#### `InitKind5` (`$CCF3`)

**Kind 5: picture `$8E20`, frame timer 5**

Witness: L1 19 (c2, rzx-p2- x10).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,925 t-states own (0.00 %) |
| Runs (the other recordings) | 19 calls (`stage1/rec/rzx-p2-02000` 2, `stage1/rec/rzx-p2-20000` 2, `stage1/rec/rzx-p2-00000` 2 and 8 more) |
| Called from | `MakeObject`, `InitKind14`, `SpeedUpTick` |
| Reads | `$5E6F`; `$5E87`-`$5E8A`; `$5E9F`-`$5EA5`; `$5EB7`; `$5EDB` |
| Writes | `$5E6A`-`$5EC3`; `$5ED6`-`$5EE7` |

#### `InitKind14` (`$CD15`)

**Kind 14, the mine: picture `$9100`, frames `$AF6A`**

Changed from REX 1's InitKind14 `$CDD8` (src/game/rooms.asm).

Witness: L1 77 (c2, p2-room20, rzx-p2- x11).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 10 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 633 t-states own (0.00 %) |
| Runs (the other recordings) | 77 calls (`stage1/rec/rzx-p2-38000` 13, `stage1/rec/rzx-p2-18000` 12, `stage1/rec/rzx-p2-24000` 8 and 10 more) |
| Called from | `MakeObject` |
| Calls | `InitKind5` |
| Writes | `$5E6A`-`$5FA4` |

### Part 2 (REX 2): rexmove

`src/rex2/rexmove.asm`

#### `SpeedUpTick` (`$CD44`)

**The SPEED UP bonus: count down; the speed back at the end**

As REX 1's SpeedUpTick `$CFCC` (src/game/rexmove.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 269 t-states own (0.00 %) |
| Called from | `MakeObject` |
| Calls | `InitKind5` |
| Writes | `$5EB7`-`$5EC0` |

#### `WalkRightKey` (`$CD52`)

**Right: facing right, the speed set**

As REX 1's WalkRightKey `$CFDA` (src/game/rexmove.asm).

Witness: L1 1507 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 206 t-states own (0.00 %) |
| Runs (the other recordings) | 1,507 calls (`stage1/rec/rzx-p2-00000` 124, `stage1/rec/rzx-p2-14000` 119, `stage1/c2` 117 and 20 more) |
| Called from | `MainLoop`, `MakeObject` |
| Reads | `$5E6F`; `$A20B` (`SpeedUp`) |
| Writes | `$5E6A`-`$5E7B`; `$A22A` (`RexSpeed`); `$A254` (`RexFacing`) |

#### `WalkLeftKey` (`$CD6E`)

**Left: facing left, the speed set**

As REX 1's WalkLeftKey `$CFF6` (src/game/rexmove.asm).

Witness: L1 1319 (c2, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,438 t-states own (0.00 %) |
| Runs (the other recordings) | 1,319 calls (`stage1/rec/rzx-p2-10000` 151, `stage1/rec/rzx-p2-02000` 134, `stage1/rec/rzx-p2-16000` 122 and 19 more) |
| Called from | `MainLoop`, `MakeObject` |
| Reads | `$5E6F`; `$5E9F`; `$A20B` (`SpeedUp`) |
| Writes | `$5E6A`-`$5E7B`; `$5E9A`-`$5EAB`; `$A22A` (`RexSpeed`); `$A254` (`RexFacing`) |

#### `RexWalk` (`$CD8B`)

**Move Rex by RexSpeed in his facing unless a solid cell (type 3 kills him); at the edges ExitLeft / ExitRight**

Changed from REX 1's RexWalk `$D013` (src/game/rexmove.asm).

Witness: L1 8996 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,996 calls (`stage1/rec/rzx-p2-14000` 510, `stage1/rec/rzx-p2-04000` 505, `stage1/rec/rzx-p2-32000` 493 and 20 more) |
| Called from | `MainLoop` |
| Calls | `RexDies`, `IsSolid`, `ExitLeft` (tail), `ExitRight` (tail) |
| Reads | `$A1B2`-`$A1B3` (`RexCellPtr`); `$A22A` (`RexSpeed`); `$A24F`-`$A25D` (`RexX`, `RexY`, `Room`, `RoomColumn` and 7 more) |
| Writes | `$A22A` (`RexSpeed`); `$A24F` (`RexX`) |

#### `IsSolid` (`$CDF5`)

**Z if the cell at HL is solid (SolidCells: 2, 4, 5, 6, 3); the type found in `$A25D`**

Changed from REX 1's IsSolid `$D06C` (src/game/rexmove.asm).

Witness: L1 37941 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 37,941 calls (`stage1/rec/rzx-p2-14000` 2,675, `stage1/rec/rzx-p2-32000` 2,635, `stage1/c2` 2,605 and 20 more) |
| Called from | `DriftObject`, `WalkRight`, `WalkLeft`, `ObjectJump`, `RexWalk`, `RexJump` |
| Calls | `InList` (falls into) |
| Reads | `$E1CC`-`$E4B3` (`RoomGrid+45`, `RoomGridPlay`); `$E4D3` (`RoomGridPlay+724`) |

#### `InList` (`$CDFD`)

**Z if A is one of B values at DE**

As REX 1's InList `$D074` (src/game/rexmove.asm).

Witness: L1 118632 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 118,632 calls (`stage1/rec/rzx-p2-36000` 7,480, `stage1/rec/rzx-p2-38000` 7,410, `stage1/rec/rzx-p2-10000` 7,335 and 20 more) |
| Called from | `IsSolid` (falls into), `IsPassable` (tail) |
| Reads | `$CE22`-`$CE2F` (`SolidCells`, `PassCells`) |
| Writes | `$A25D` (`CellFound`) |

#### `IsPassable` (`$CE17`)

**Z if the cell at HL lets a body or a bullet through (PassCells `$CE27`: 0, `$0E-$12`, 3, `$15`, `$16`); the type found in `$A25D`**

Changed from REX 1's IsPassable `$D08B` (src/game/rexmove.asm).

Witness: L1 80691 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 80,691 calls (`stage1/rec/rzx-p2-38000` 6,121, `stage1/rec/rzx-p2-12000` 5,946, `stage1/rec/rzx-p2-08000` 5,525 and 20 more) |
| Called from | `StepShot`, `Kind2Drop`, `ObjectFall`, `FindGround`, `RexFall` |
| Calls | `InList` (tail) |
| Reads | `$E203`-`$E4D8` (`RoomGridPlay+4`); `$E4F1`-`$E4F2` (`RoomGridPlay+754`) |

#### `ExitLeft` (`$CE30`)

**Rex at the left edge: to the room RoomLeft `$A229` at X `$E8`**

As REX 1's ExitLeft `$D0A0` (src/game/rexmove.asm).

Witness: L1 3 (rzx-p2-02000, rzx-p2-04000, rzx-p2-10000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/rzx-p2-10000` 1, `stage1/rec/rzx-p2-02000` 1, `stage1/rec/rzx-p2-04000` 1) |
| Called from | `RexWalk` (tail) |
| Calls | `ChangeRoom` (tail) |
| Reads | `$A229` (`RoomLeft`) |
| Writes | `$A24F`-`$A251` (`RexX`, `RexY`, `Room`) |

#### `ExitRight` (`$CE41`)

**Rex at the right edge: to the room RoomRight `$A226` at X `$08`**

As REX 1's ExitRight `$D0B1` (src/game/rexmove.asm).

Witness: L1 3 (p2-room20, rzx-p2-00000, rzx-p2-12000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/rzx-p2-12000` 1, `stage1/rec/rzx-p2-00000` 1, `stage2/rec/p2-room20` 1) |
| Called from | `RexWalk` (tail) |
| Calls | `ChangeRoom` (tail) |
| Reads | `$A226` (`RoomRight`) |
| Writes | `$A24F`-`$A251` (`RexX`, `RexY`, `Room`) |

#### `StartJump` (`$CE52`)

**Up: a jump if Rex stands (not jumping or falling)**

As REX 1's StartJump `$D0C2` (src/game/rexmove.asm).

Witness: L1 1172 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,172 calls (`stage1/rec/rzx-p2-34000` 101, `stage1/rec/rzx-p2-26000` 88, `stage1/rec/rzx-p2-08000` 86 and 20 more) |
| Called from | `MainLoop`, `CellsUnderRex` |
| Reads | `$A255`-`$A256` (`FallSpeed`, `Jumping`) |
| Writes | `$A256`-`$A25A` (`Jumping`, `JumpPtr`) |

#### `RexJump` (`$CE74`)

**One step of the jump: up by JumpSteps unless a solid cell above (type 3 kills him); off the top ExitUp**

Changed from REX 1's RexJump `$D0E4` (src/game/rexmove.asm).

Witness: L1 9003 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 12,241 t-states own (0.00 %) |
| Runs (the other recordings) | 9,003 calls (`stage1/rec/rzx-p2-14000` 511, `stage1/rec/rzx-p2-04000` 505, `stage1/rec/rzx-p2-32000` 493 and 20 more) |
| Called from | `MainLoop`, `Recharge` |
| Calls | `RexDies`, `IsSolid`, `ExitTop` (tail) |
| Reads | `$A028`-`$A02B` (`SparkleDir+5`); `$A093`-`$A09F` (`SparkleDotOut+6`, `SparkleDotStore2`); `$A1B2`-`$A1B3` (`RexCellPtr`); `$A227` (`RoomUp`); `$A250`-`$A25D` (`RexY`, `Room`, `RoomColumn`, `RexFacing` and 6 more); `$CE68`-`$CE72` (`JumpSteps`) |
| Writes | `$A028`-`$A02B` (`SparkleDir+5`); `$A093`-`$A09F` (`SparkleDotOut+6`, `SparkleDotStore2`); `$A250`-`$A25A` (`RexY`, `Room`, `RoomColumn`, `RexFacing` and 3 more) |

#### `Land` (`$CEB2`)

**Stop the jump and the fall; Rex on the cell's top**

As REX 1's Land `$D11A` (src/game/rexmove.asm).

Witness: L1 44 (c2, p2-room20, rzx-p2- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 40 calls (`stage1/rec/rzx-p2-02000` 15, `stage1/rec/rzx-p2-14000` 8, `stage1/rec/rzx-p2-20000` 6 and 4 more) |
| Called from | `CellsUnderRex` |
| Calls | `DebugHook` |
| Reads | `$A250` (`RexY`) |
| Writes | `$A255`-`$A256` (`FallSpeed`, `Jumping`) |

#### `ExitTop` (`$CEC7`)

**Rex off the top: to the room RoomUp `$A227` at the bottom**

As REX 1's ExitTop `$D12F` (src/game/rexmove.asm).

Witness: L1 7 (rzx-p2- x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/rzx-p2-02000` 1, `stage1/rec/rzx-p2-14000` 1, `stage1/rec/rzx-p2-20000` 1) |
| Called from | `RexJump` (tail) |
| Calls | `ChangeRoom` (tail), `DebugHook` |
| Reads | `$A227` (`RoomUp`) |
| Writes | `$A250`-`$A256` (`RexY`, `Room`, `RoomColumn`, `RexFacing` and 2 more) |

#### `RexFall` (`$CEE5`)

**Rex falls when no floor is under him (a passable cell 3 kills him); off the bottom to RoomDown `$A228`, or death with no exit**

Changed from REX 1's RexFall `$D14D` (src/game/rexmove.asm).

Witness: L1 8996 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 855,799 t-states own (0.06 %) |
| Runs (the other recordings) | 8,996 calls (`stage1/rec/rzx-p2-14000` 510, `stage1/rec/rzx-p2-04000` 505, `stage1/rec/rzx-p2-32000` 493 and 20 more) |
| Called from | `MainLoop`, `ObjectHitsRex` |
| Calls | `RexDies`, `CellPointer`, `IsPassable` |
| Reads | `$6120`-`$6147`; `$6158`-`$615F`; `$61B8`-`$61CF` (`DevLink+16`); `$A028`-`$A02A` (`SparkleDir+5`); `$A228` (`RoomDown`); `$A24F`-`$A25D` (`RexX`, `RexY`, `Room`, `RoomColumn` and 7 more); 13 more ranges |
| Writes | `$4022`-`$490E` (screen); `$4924`-`$4A0E` (screen); `$4A24`-`$4B0E` (screen); `$4B24`-`$4C0E` (screen); `$4C24`-`$4D0E` (screen); `$4D24`-`$4E0E` (screen); 9 more ranges |

### Part 2 (REX 2): collisions

`src/rex2/collisions.asm`

#### `EnemyBulletsHitRex` (`$CF59`)

**Each enemy bullet in Rex's box: the shield takes it (faster drain), else Rex dies**

As REX 1's EnemyBulletsHitRex `$D1B9` (src/game/collisions.asm).

Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,800 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 195,906 t-states own (0.01 %) |
| Runs (the other recordings) | 10,871 calls (`stage1/c2` 926, `stage1/rec/rzx-p2-16000` 518, `stage1/rec/rzx-p2-18000` 516 and 20 more) |
| Called from | `NewGame`, `MainLoop`, `DrawPiece`, `Attract`, `Kind2Drop` |
| Calls | `ShieldDrainFast`, `RexDies`, `Random2` |
| Reads | `$5800`-`$585F` (screen); `$5D22`-`$6CEB` (`DevLink`, `DevLinkState`, `Unused62FE`, `Font` and 2 more); `$A093`-`$A096` (`SparkleDotOut+6`); `$A1E2`-`$A1F9` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate` and 17 more); `$A24F`-`$A250` (`RexX`, `RexY`); `$BFE7`-`$BFEE` (`Kind9Open+43`); 8 more ranges |
| Writes | `$588F`-`$58D1` (screen); `$5901`-`$5943` (screen); `$597D`-`$59F5` (screen); `$5A06`-`$5A15` (screen); `$5A26`-`$5A35` (screen); `$5A46`-`$5AB0` (screen); 7 more ranges |

#### `ObjectHitsRex` (`$CFB5`)

**The object at IX against Rex: its box (written into the compares at `$D00F`, `$D01A`, `$D01F`, `$D0A8`, `$D0B9`; the mine smaller); the shield kills it, else Rex dies unless it dissolves; pods are taken; then Rex's bullets against it**

Changed from REX 1's ObjectHitsRex `$D215` (src/game/collisions.asm).

Witness: L1 45603 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 984,909 t-states own (0.07 %) |
| Runs (the other recordings) | 45,603 calls (`stage1/c2` 4,792, `stage1/rec/rzx-p2-20000` 2,960, `stage1/rec/rzx-p2-36000` 2,956 and 19 more) |
| Called from | `MainLoop`, `ObjectCollide`, `WalkRight`, `BulletsHitObject` (tail), `BulletLoop` |
| Calls | `KillObject`, `ShieldDrainFast`, `RexDies`, `RexFall`, `BulletsHitObject` (tail), `BulletLoop` (tail), `TakePowerPod` |
| Reads | `$5B60`-`$6BEC` (`DevLink`, `DevLinkState`, `Unused62FE`, `Font` and 2 more); `$A019`-`$A01A` (`SparkleDots2+19`); `$A072` (`SparkleDotIn+2`); `$A091` (`SparkleDotOut+4`); `$A0B6`-`$A0BD` (`SparkleDots+9`); `$A1AC` (`Weapon`); 8 more ranges |
| Writes | `$5B66`-`$5D0A`; `$5D37`; `$5E7A`; `$5E95`; `$5EB0`; `$5ECB`; 11 more ranges |

#### `BulletsHitObject` (`$D07E`)

**Rex's 30 bullets against the object at IX: kind `$82` is immune, kind `$84` only while open; a hit object takes damage or is killed**

Witness: L1 36506 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,768 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 138,594 t-states own (0.01 %) |
| Runs (the other recordings) | 5,002 calls (`stage1/rec/rzx-p2-26000` 2,336, `stage1/rec/rzx-p2-38000` 1,963, `stage1/rec/rzx-p2-08000` 703) |
| Called from | `MoveShots`, `ObjectJump`, `FindGround`, `MakeObjects`, `ObjectHitsRex` (tail), `HitObject` |
| Calls | `ObjectHitsRex` (tail), `BulletLoop` (falls into) |
| Reads | `$5B60`-`$6BCE` (`DevLink`, `DevLinkState`, `Unused62FE`, `Font` and 2 more); `$A1AC` (`Weapon`); `$D5DA` (`Channels+16`); `$E28E`-`$E29C` (`RoomGridPlay+143`); `$E2AE`-`$E2BC` (`RoomGridPlay+175`); `$E2CE`-`$E2DC` (`RoomGridPlay+207`); 3 more ranges |
| Writes | `$5B66`-`$5D0A`; `$5DCD`-`$5DDC`; `$5E7A`; `$5E95`; `$5EB0`; `$5ECB`; 3 more ranges |

#### `BulletLoop` (`$D094`)

**Rex's bullets against the object at IX: the laser goes through, the others flash; kind 6 HitObjectHard; each hit counts down its hits; the last on a kind 0 from the front turns it (HitObject), from behind or any other kind kills it**

Changed from REX 1's BulletLoop `$D2FC` (src/game/collisions.asm).

Witness: L1 846205 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 18,771 t-states own (0.00 %) |
| Runs (the other recordings) | 114,960 calls (`stage1/rec/rzx-p2-20000` 59,373, `stage1/rec/rzx-p2-24000` 29,610, `stage1/c2` 19,290 and 1 more) |
| Called from | `MainLoop`, `ObjectHitsRex` (tail), `BulletsHitObject` (falls into), `NextBullet` (tail) |
| Calls | `KillObject`, `Delay` (tail), `ObjectHitsRex`, `NextBullet` (tail), `HitObject`, `HitObjectHard`, `StartSfx` |
| Reads | `$5B60`-`$6B92` (`DevLink`, `DevLinkState`, `Unused62FE`, `Font` and 2 more); `$A019`-`$A01A` (`SparkleDots2+19`); `$A08D` (`SparkleDotOut`); `$A0B7`-`$A0C1` (`SparkleDots+10`); `$A1AC` (`Weapon`); `$D0D8`-`$D0E2` (`BulletBoxWidth+32`, `BulletHit`); 1 more ranges |
| Writes | `$5B66`-`$5BC0`; `$5BDE`-`$5C74`; `$5C92`-`$5CA1`; `$5CBF`; `$5CDD`-`$5CFB`; `$5EB0`; 8 more ranges |

#### `NextBullet` (`$D13F`)

**The next bullet record; a hit that is not the last pauses a kind 8 (timer 4)**

Changed from REX 1's NextBullet `$D3A7` (src/game/collisions.asm).

Witness: L1 846207 (c2, p2-room20, rzx-p2- x20).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 82,062 t-states own (0.01 %) |
| Runs (the other recordings) | 55,587 calls (`stage1/rec/rzx-p2-24000` 29,610, `stage1/c2` 19,290, `stage2/rec/p2-room20` 6,687) |
| Called from | `MainLoop`, `BulletLoop` (tail) |
| Calls | `BulletLoop` (tail) |
| Reads | `$A0B6`-`$A0BD` (`SparkleDots+9`); `$E37B`-`$E37C` (`RoomGridPlay+380`); `$E393`-`$E3A1` (`RoomGridPlay+404`); `$E3B3`-`$E3C6` (`RoomGridPlay+436`); `$E3D9`-`$E3E7` (`RoomGridPlay+474`); `$E3FC`-`$E407` (`RoomGridPlay+509`); 3 more ranges |
| Writes | `$A0AF`-`$A0BC` (`SparkleDots+2`) |

#### `HitObject` (`$D15A`)

**A hit: the flash picture SpriteHitFlash `$8258`, the combo score (ComboCount `$A1D4`; none for the spray), the object killed after its hits (the laser kills at once)**

As REX 1's HitObject `$D3C2` (src/game/collisions.asm).

Witness: L1 16 (rzx-p2- x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 calls (`stage1/rec/rzx-p2-10000` 2, `stage1/rec/rzx-p2-20000` 2, `stage1/rec/rzx-p2-28000` 2 and 7 more) |
| Called from | `BulletLoop` |
| Calls | `KillObject` (tail), `AddScore`, `PrintText`, `StartFall`, `BulletsHitObject` |
| Reads | `$5E68`; `$5E83`; `$5E9E`; `$5EB9`; `$5ED4`; `$5EEF`; 1 more ranges |
| Writes | `$5E68`-`$5F04`; `$A1D2`-`$A1D6` (`KillFlashPtr`, `ComboCount`, `ComboTimer`) |

#### `HitObjectHard` (`$D1B7`)

**A hit on an armoured object: the flash, more hits needed**

As REX 1's HitObjectHard `$D41F` (src/game/collisions.asm).

Witness: L1 14 (rzx-p2- x5).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 742,204 t-states own (0.05 %) |
| Runs (the other recordings) | 14 calls (`stage1/rec/rzx-p2-14000` 8, `stage1/rec/rzx-p2-10000` 2, `stage1/rec/rzx-p2-30000` 2 and 2 more) |
| Called from | `MainLoop`, `BuildRoom`, `BulletLoop` |
| Calls | `AddScore` |
| Reads | `$5D22`-`$6C46` (`DevLink`, `DevLinkState`, `Unused62FE`, `Font` and 2 more); `$A049`-`$A060` (`SparkleDir+38`, `SparkleMove`); `$A0B6`-`$A0B7` (`SparkleDots+9`); `$A1AC` (`Weapon`); `$A1D2`-`$A1D6` (`KillFlashPtr`, `ComboCount`, `ComboTimer`) |
| Writes | `$5D28`-`$5D37`; `$5D55`; `$5EDB`-`$5EE9`; `$A1D2`-`$A1D6` (`KillFlashPtr`, `ComboCount`, `ComboTimer`) |

#### `TakePowerPod` (`$D204`)

**The power pod (`$FE`): PowerGain twice if it is a big one, the pod sound**

As REX 1's TakePowerPod `$D46C` (src/game/collisions.asm).

Witness: L1 44 (rzx-p2- x14).

[Animation: `TakePowerPod` at work](img/routines/TakePowerPod.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 545,695 t-states own (0.04 %) |
| Runs (the other recordings) | 44 calls (`stage1/rec/rzx-p2-14000` 7, `stage1/rec/rzx-p2-02000` 6, `stage1/rec/rzx-p2-32000` 6 and 11 more) |
| Called from | `PanelBox`, `ObjectHitsRex` |
| Calls | `DeathAnimation`, `PowerGain`, `StartSfx` |
| Reads | `$5E66`-`$5F38`; `$5F53`; `$A055`-`$A060` (`SparkleMove+10`); `$A0B6`-`$A0B7` (`SparkleDots+9`) |
| Writes | `$5E72`; `$5E8D`; `$5EA8`; `$5EC3`; `$5EDE`; `$5EF9`; 7 more ranges |

#### `TakeBombPod` (`$D22C`)

**The bomb pod (`$FD`): Bombs + 1 up to 3, the HUD, the sound**

As REX 1's TakeBombPod `$D494` (src/game/collisions.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,538 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `BonusRoulette` (`$D24E`)

**The bonus pod (`$FC`): a panel cycles through the five prizes until fire (or it slows to a stop); the prize given**

As REX 1's BonusRoulette `$D4B6` (src/game/collisions.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,538 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,567,124 t-states own (0.25 %) |
| Reads | `$5B60`-`$5D19`; `$5E66`-`$5E7F`; `$5E97`; `$5EAF`; `$5EC6`-`$5EC7`; `$A013` (`SparkleDots2+13`); 1 more ranges |
| Writes | `$5B66`; `$5E7A` |

#### `ExtraLife` (`$D338`)

**Lives + 1 up to 9, ShowLives**

As REX 1's ExtraLife `$D5A0` (src/game/collisions.asm).

Witness: L1 1 (rzx-p2-10000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/rzx-p2-10000` 1) |
| Called from | `AddScore` |
| Calls | `ShowLives` |
| Reads | `$A1FC` (`Lives`) |
| Writes | `$A1FC` (`Lives`) |

### Part 2 (REX 2): sound

`src/rex2/sound.asm`

#### `SoundReset` (`$D346`)

**The channels free, the mixer `$38` (tones on, noise off), silence**

As REX 1's SoundReset `$D5AE` (src/game/sound.asm).

Witness: L1 22 (c2, p2-room20, rzx-p2- x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 22 calls (`stage1/c2` 6, `stage1/rec/rzx-p2-00000` 4, `stage1/rec/rzx-p2-02000` 2 and 10 more) |
| Called from | `NewGame`, `WaitFireOrAttract`, `Pause`, `DrawRoom` |
| Calls | `SoundSilence`, `WriteMixer` |
| Reads | `$D5CA`-`$D5E6` (`Channels`) |
| Writes | `$D5CA`-`$D5ED` (`Channels`, `Mixer`) |

#### `SoundSilence` (`$D36F`)

**The three volumes (registers 8-10) to 0**

As REX 1's SoundSilence `$D5D7` (src/game/sound.asm).

Witness: L1 20437 (c2, p2-room20, rzx-p2- x11).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 20,437 calls (`stage2/rec/p2-room20` 20,393, `stage1/c2` 15, `stage1/rec/rzx-p2-00000` 7 and 10 more) |
| Called from | `WaitFireOrAttract`, `Pause`, `DrawRoom`, `SoundReset` |
| Calls | `SoundWrite` |

#### `StartSfx` (`$D37F`)

**Start the effect at DE (saves IX, IY, BC)**

As REX 1's StartSfx `$D5E7` (src/game/sound.asm).

Witness: L1 8524 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,524 calls (`stage1/rec/rzx-p2-38000` 792, `stage1/rec/rzx-p2-36000` 687, `stage1/rec/rzx-p2-12000` 677 and 20 more) |
| Called from | `DrawRex`, `KillObject`, `BossExplodes`, `SaveRestart`, `Materialise`, `Dematerialise`, `Recharge`, `FindSlot`, `EnemyShotSound`, `ShotStopped`, `BulletLoop`, `TakePowerPod` |
| Calls | `StartSfxIY` |

#### `StartSfxIY` (`$D390`)

**The descriptor at IY into its channel; the mixer bits for tone and noise**

As REX 1's StartSfxIY `$D5F8` (src/game/sound.asm).

Witness: L1 8524 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,524 calls (`stage1/rec/rzx-p2-38000` 792, `stage1/rec/rzx-p2-36000` 687, `stage1/rec/rzx-p2-12000` 677 and 20 more) |
| Called from | `StartSfx` |
| Calls | `WriteMixer` (tail) |
| Reads | `$D4FB`-`$D579` (`SfxGun`, `SfxEnemyShot`, `SfxLaser`, `SfxSpray` and 8 more); `$D59D`-`$D5A3` (`SfxRestart`); `$D5BE`-`$D5C4` (`SfxRecharge`); `$D5ED` (`Mixer`) |
| Writes | `$D5CA`-`$D5ED` (`Channels`, `Mixer`) |

#### `WriteMixer` (`$D41A`)

**Register 7 = the mixer `$D5ED`**

As REX 1's WriteMixer `$D682` (src/game/sound.asm).

Witness: L1 8546 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,546 calls (`stage1/rec/rzx-p2-38000` 792, `stage1/rec/rzx-p2-36000` 687, `stage1/rec/rzx-p2-12000` 678 and 20 more) |
| Called from | `SoundReset`, `StartSfxIY` (tail) |
| Calls | `SoundWrite` |
| Reads | `$D5ED` (`Mixer`) |

#### `SoundStep` (`$D424`)

**Each of the 3 channels: ChannelStep, then its tone (registers 0-5) or noise period (6)**

As REX 1's SoundStep `$D68C` (src/game/sound.asm).

Witness: L1 21741 (c2, p2-room20, rzx-p2- x21).

[Animation: `SoundStep` at work](img/routines/SoundStep.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21,741 calls (`stage1/c2` 1,852, `stage1/rec/rzx-p2-16000` 1,036, `stage1/rec/rzx-p2-18000` 1,033 and 20 more) |
| Called from | `MainLoop`, `Attract` |
| Calls | `ChannelStep`, `SoundWrite` |
| Reads | `$D5CA`-`$D5EF` (`Channels`, `Mixer`, `ChannelNumber`) |
| Writes | `$D5EF` (`ChannelNumber`) |

#### `ChannelStep` (`$D473`)

**One step of the channel at IX: the volume written, the tone and volume changed, the next step; at the end the channel silent and free**

As REX 1's ChannelStep `$D6DB` (src/game/sound.asm).

Witness: L1 65887 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 65,223 calls (`stage1/c2` 5,556, `stage1/rec/rzx-p2-16000` 3,108, `stage1/rec/rzx-p2-18000` 3,099 and 20 more) |
| Called from | `SoundStep` |
| Calls | `WriteVolume`, `SoundWrite` |
| Reads | `$D502`-`$D53C` (`SfxGun+7`, `SfxEnemyShot`, `SfxLaser`, `SfxSpray` and 4 more); `$D54D`-`$D587` (`SfxMaterialise+7`, `SfxDematerialise`, `SfxBigPod`, `SfxPowerPod`); `$D5A4`-`$D5EF` (`SfxRestart+7`, `Channels`) |
| Writes | `$D5CA`-`$D5E1` (`Channels`) |

#### `WriteVolume` (`$D4DC`)

**Register 8 + channel = the channel's volume / 16**

As REX 1's WriteVolume `$D744` (src/game/sound.asm).

Witness: L1 23537 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23,537 calls (`stage1/c2` 1,551, `stage1/rec/rzx-p2-38000` 1,390, `stage1/rec/rzx-p2-10000` 1,361 and 20 more) |
| Called from | `ChannelStep` |
| Calls | `SoundWrite` |
| Reads | `$D5D1`-`$D5EF` (`Channels+7`, `Mixer`, `ChannelNumber`) |

#### `SoundWrite` (`$D4F1`)

**AY register D = E: OUT (`$FFFD`),D, OUT (`$BFFD`),E**

As REX 1's SoundWrite `$D759` (src/game/sound.asm).

Witness: L1 147591 (c2, p2-room20, rzx-p2- x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 147,591 calls (`stage2/rec/p2-room20` 62,610, `stage1/c2` 5,493, `stage1/rec/rzx-p2-38000` 5,397 and 20 more) |
| Called from | `SoundSilence`, `WriteMixer`, `SoundStep`, `ChannelStep`, `WriteVolume` |
| Ports out | `$BFFD`, `$FFFD` |

### Part 2 (REX 2): menu

`src/rex2/menu.asm`

#### `TitleMenu` (`$DAC0`)

**The title and menu: the title on, the five menu texts, then MenuCode (the code first, then the keys 1-4)**

Changed from REX 1's TitleMenu `$DAC0` (src/game/menu.asm).

Witness: L1 1 (c2).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 call, 615,128 t-states own (0.04 %) |
| Runs (the other recordings) | 1 call (`stage1/c2` 1) |
| Called from | `GameEntry` |
| Calls | `CellsUnderRex`, `PrintBoxed`, `MenuCode` (falls into) |
| Reads | `$4000`-`$5AFF` (screen); `$A065` (`SparkleMove+26`); `$A083`-`$A087` (`SparkleDotIn+19`, `SparkleDotStore`); `$DC44` (`CodeSumLoop+154`); `$DC60` (`CodeBad+7`); `$DC7C` (`DigitsLoop+14`); 4 more ranges |
| Writes | `$4000`-`$5AFF` (screen); `$6018`-`$60D7`; `$A065` (`SparkleMove+26`); `$A07F`-`$A087` (`SparkleDotIn+15`, `SparkleDotStore`); `$E4FF`-`$FFFE` (`TitleScreen`, `work space $FFFA+`) |
| Ports in | `$F7FE` |
| Ports out | `$00FE` |

#### `MenuCode` (`$DAE3`)

**The title on, the code (EnterCode), the title again; then the keys 1-4: DEFINE, KEMPSTON, CURSOR, SINCLAIR**

Witness: L1 2 (c2).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 calls (`stage1/c2` 2) |
| Called from | `TitleMenu` (falls into), `EnterCode` (tail) |
| Calls | `DrawRoomCell`, `EnterCode`, `ChooseSinclair` (tail), `MenuTexts` |
| Reads | `$E4FF`-`$FFFE` (`TitleScreen`, `work space $FFFA+`) |
| Writes | `$4000`-`$5AFF` (screen) |
| Ports in | `$F7FE` |

#### `EnterCode` (`$DB27`)

**INPUT YOUR CODE: the 13 characters unscrambled, each 9 - digit, the checksum; a good code sets the score, lives, weapons, shield and bombs of part 1's end; a bad one INVALID CODE, the menu**

Witness: L1 2 (c2).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 364 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 18,399,184 t-states own (1.27 %) |
| Runs (the other recordings) | 2 calls (`stage1/c2` 2) |
| Called from | `MenuCode`, `ReadCode`, `CodeDelete`, `ScanKey` |
| Calls | `CellsUnderRex`, `PrintBoxed`, `DebugHook`, `MenuCode` (tail), `DigitsValue`, `ReadCode`, `ScanKey` |
| Reads | `$A261`-`$A262` (`CodeSum`); `$A9D6`-`$A9E3` (`AttractPass+31`); `$DCF5`-`$DD1D` (`CodeTexts+78`); `$DD4E`-`$DD52` (`ReadCodeKey+2`); `$E0E0`-`$E0EF` (`MenuSpace+25`); `$E4FF`-`$FFFE` (`TitleScreen`, `work space $FFFA+`) |
| Writes | `$4000`-`$5AFF` (screen); `$A0AB`-`$A0AD` (`SparkleMasks+6`, `SparkleDots`); `$A1E9`-`$A1EC` (`HasDoubleFire`, `HasLaser`, `HasMultiple`, `HasSpray`); `$A22C`-`$A22D` (`Temp1`); `$A23F`-`$A243` (`Digits`); `$A261`-`$A267` (`CodeSum`, `CodeScore`, `CodeShield`, `CodeBombs` and 1 more); 1 more ranges |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

#### `DigitsValue` (`$DC69`)

**HL = the five ASCII digits at CodeDigits `$A23F` as a number**

Witness: L1 4 (c2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/c2` 4) |
| Called from | `EnterCode` |
| Calls | `AddDigit` |
| Reads | `$A23F`-`$A243` (`Digits`) |
| Writes | `$A23F`-`$A243` (`Digits`) |

#### `AddDigit` (`$DC9B`)

**HL + DE x the next digit**

Witness: L1 20 (c2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20 calls (`stage1/c2` 20) |
| Called from | `DigitsValue` |
| Reads | `$A23F`-`$A243` (`Digits`) |

#### `ReadCode` (`$DD1F`)

**Read the code: up to 16 keys echoed with a "?" cursor; CAPS ("-") deletes, ENTER ("+") ends**

Witness: L1 2 (c2).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 326,928 t-states own (0.02 %) |
| Runs (the other recordings) | 2 calls (`stage1/c2` 2) |
| Called from | `EnterCode` |
| Calls | `CellsUnderRex`, `ResetSweep`, `PrintBoxed`, `PrintTextHL`, `EnterCode`, `ScanKey` |
| Reads | `$A236`-`$A239` (`CodeKey`, `BoxAttr`); `$A260` (`CodeLength`); `$DCF4`-`$DD03` (`CodeTexts+77`) |
| Writes | `$A236`-`$A239` (`CodeKey`, `BoxAttr`); `$A260` (`CodeLength`); `$DCF4`-`$DD07` (`CodeTexts+77`); `$DD4E`-`$DD53` (`ReadCodeKey+2`) |
| Ports in | `$F7FE` |

#### `CodeDone` (`$DD9A`)

**ENTER: RET**

Witness: L1 2 (c2).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 runs of its first instruction, entered by a jump (`stage1/c2` 2) |
| Calls | `PrintText` |

#### `ScanKey` (`$DD9B`)

**DEFINE: wait for a key not SPACE, not H and not taken; its port into DefinePort, its BIT opcode into DefineBit, its character in A**

As REX 1's ScanKey `$DBAE` (src/game/menu.asm).

Witness: L1 35 (c2).

[Animation: `ScanKey` at work](img/routines/ScanKey.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 35 calls (`stage1/c2` 35) |
| Called from | `EnterCode`, `ReadCode` |
| Calls | `ResetSweep`, `BufferToScreen`, `PrintChar`, `PrintText`, `EnterCode`, `ChooseKempston` |
| Reads | `$AE1A`-`$AE29` (`KeyPorts`); `$AE3E`-`$AE4F` (`KeyNames+20`); `$DE13`-`$DE17` (`DefineTaken`) |
| Writes | `$A244`-`$A246` (`DefinePort`, `DefineBit`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

#### `ChooseSinclair` (`$DF20`)

**4: Sinclair (port `$EFFE`, keys 6-0): fire bit 0, up 1, down 2, right 3, left 4; the confirm**

Witness: L1 2 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 1, `stage1/rec/rzx-p2-00000` 1) |
| Called from | `MenuCode` (tail) |
| Calls | `SetFire`, `SetLeft`, `SetRight`, `SetUp`, `SetDown` |
| Writes | `$A244`-`$A247` (`DefinePort`, `DefineBit`, `ControlXor`) |
| Ports in | `$7FFE`, `$DFFE` |

#### `Confirm` (`$DF93`)

**The confirm text; Y returns (the game starts), N goes back to the menu (MenuAgain)**

As REX 1's Confirm `$DED2` (src/game/menu.asm).

Witness: L1 2 (c2, rzx-p2-00000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 runs of its first instruction, entered by a jump (`stage1/c2` 1, `stage1/rec/rzx-p2-00000` 1) |
| Calls | `PrintBoxed` |


## DEMO (`src/demo/demo.json`)

Rex, Martech Games 1988 (The Light): DEMO, the Tutor Mode, `$61A8-$FFF9` as the ROM loader leaves it
(tools/parts.py: side 2 blocks 4 and 6 of orig/Rex.tzx.zip); entry `$8A84`. Its entries are `src/demo/<module>.asm`,
written from `src/demo/demo.ann` by `kit/mkgame.py --part src/demo/demo.json`; the recordings: `work/stage1/c1` (c1:
power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1), and `work/stage1/d1`,
`work/stage2/rec/demo-cycle`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`graphics`](11-data-reference.md#demo-graphics) | `$61A8`-`$8A83` | 0 of 10 |
| [`entry`](#demo-entry) | `$8A84`-`$8CDF` | 4 of 4 |
| [`rex`](#demo-rex) | `$8CE0`-`$8DA0` | 4 of 4 |
| [`bomb`](#demo-bomb) | `$8DA1`-`$8F78` | 9 of 11 |
| [`score`](#demo-score) | `$8F79`-`$90EE` | 12 of 13 |
| [`death`](#demo-death) | `$90EF`-`$9544` | 15 of 17 |
| [`cells`](#demo-cells) | `$9545`-`$9604` | 1 of 1 |
| [`tutor`](#demo-tutor) | `$9605`-`$9BB8` | 31 of 31 |
| [`hud`](#demo-hud) | `$9BB9`-`$9F4F` | 22 of 26 |
| [`controls`](#demo-controls) | `$9F50`-`$9FD6` | 9 of 9 |
| [`grid`](#demo-grid) | `$9FD7`-`$A25E`, `$A27D`-`$A2A1` | 10 of 12 |
| [`weapons`](#demo-weapons) | `$A25F`-`$A27C`, `$BC31`-`$C310` | 42 of 43 |
| [`tables`](11-data-reference.md#demo-tables) | `$A2A2`-`$BAC2` | 0 of 15 |
| [`render`](#demo-render) | `$BAC3`-`$BC30` | 3 of 3 |
| [`objects`](#demo-objects) | `$C311`-`$CD11` | 38 of 43 |
| [`rooms`](#demo-rooms) | `$CD12`-`$D17E` | 29 of 29 |
| [`panels`](#demo-panels) | `$D17F`-`$D2CF`, `$DA75`-`$FFF9` | 15 of 16 |
| [`rexmove`](#demo-rexmove) | `$D2D0`-`$D48B` | 12 of 14 |
| [`collisions`](#demo-collisions) | `$D48C`-`$D7B1` | 7 of 8 |
| [`sound`](#demo-sound) | `$D7B2`-`$DA74` | 9 of 11 |

### DEMO: entry

`src/demo/entry.asm`

#### `GameEntry` (`$8A84`)

**The code block's entry (USR 35460): DI, keys (ControlXor 0), the tutor's room list from its start (TutorRooms `$A2A2`), the first room (NextTutorRoom), the tutor reset (TutorReset), then NewGame**

Changed from REX 1's GameEntry `$947A` (src/game/entry.asm).

Witness: L1 1 (d1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/d1` 1) |
| Calls | `TutorReset`, `NextTutorRoom` |
| Writes | `$5B7B` (`ControlXor`); `$6085`-`$6086` (`TutorRoomPtr`) |

#### `NewGame` (`$8A95`)

**A new demo game: the variables reset, 2 lives, 3 bombs, the gun, every weapon panel shown again; the HUD; no menu, no high score**

Changed from REX 1's NewGame `$9498` (src/game/entry.asm).

Witness: L1 7 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 1) |
| Called from | `TutorNextRoom` (tail) |
| Calls | `ShowLives`, `DrawHud`, `ClearScreen`, `InitDrones`, `StartWeapon`, `SaveAttrs`, `SoundReset` |
| Writes | `$5B6E`-`$5B8F` (`RandomSeed`, `RandomSeed2`, `DigitTemp`, `Digits` and 15 more); `$5EA1` (`PowerCount`); `$5EB9`-`$5EF5` (`SmartBombOn`, `SmartBombPtr`, `SpriteMirror`, `SpritePicture` and 47 more); `$606A`-`$6076` (`Immune`, `SpeedUp`, `SpeedUpPhase`, `ExtraLifeCount` and 5 more); `$A5E1` (`DoubleFireText`); `$A623` (`LaserText`); 2 more ranges |
| Ports out | `$00FE` |

#### `MainLoop` (`$8B6A`)

**Build the room (first the room's tutor: TutorRoom0, 1, 2 or 4), then one pass of play a frame: Rex's moves come from the tutor's input script (TutorStep), the tutor's panels at their frames (TutorPanels), the arrow in room 4 (TutorArrow), SPACE pauses (DemoPause)**

The key tests of part 1 (KeyFire, KeyLeft, ...) read TutorInput `$6079` here (TutorKeyFire to TutorKeyShield); no ENTER, H or smart bomb key. The seed is reset at every room (RandomSeed `$0313`, RandomSeed2 `$11`, R = 3), so the demo plays the same each time. Room 3 starts the scripted spawn (TutorSpawn3 `$A318`).

Witness: L1 12 (d1, demo-cycle).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage2/rec/demo-cycle` 4, `stage1/d1` 1) |
| Called from | `LifeLost` (tail), `ToMainLoop` (tail) |
| Calls | `ShieldToggle`, `RexState`, `SmartBombStep`, `TutorArrow`, `KillFlashFade`, `ShowShield`, `ShowHeat`, `HeatStep`, `FadeStep`, `SparkleUpdate`, `SparkleDraw`, `CellsUnderRex`, `TutorRoom0`, `TutorRoom1`, `TutorRoom2`, `TutorRoom4`, `TutorPanels`, `ClearPlayAttrs`, `HudSweep`, `ResetSweep`, `DrawHud`, `BufferToScreen`, `TutorKeyFire`, `TutorKeyLeft`, `TutorKeyRight`, `TutorKeyUp`, `TutorKeyShield`, `TutorStep`, `DemoPause`, `CellPointer`, `AnimateCells`, `UpdateDrones`, `RollCharUp`, `RollCharDown`, `ClearBuffer`, `DrawAnimCells`, `FireWeapon`, `MoveEnemyBullets`, `MoveBullets`, `PowerBar`, `UpdateObjects`, `DrawRoom`, `CopyAttrs`, `ReadExits`, `StartScriptSpawn`, `SpawnScripted`, `SpawnRandom`, `MakeObjects`, `WalkRightKey`, `WalkLeftKey`, `RexWalk`, `StartJump`, `RexJump`, `RexFall`, `EnemyBulletsHitRex`, `SoundStep` |
| Reads | `$5B83`-`$5E81` (`RexX`, `RexY`, `Room`, `RoomColumn` and 10 more); `$5EA0` (`PassToggle`); `$5EC9` (`RapidShotsOn`); `$5EDE` (`Dying`); `$69B0`-`$69B7` (`AnimChar111`); `$6AB0`-`$6AB7` (`AnimChar143`) |
| Writes | `$5B6E`-`$5B7D` (`RandomSeed`, `RandomSeed2`, `DigitTemp`, `Digits` and 3 more); `$5B95`-`$5E82`; `$5E9B`-`$5EA3` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 3 more); `$5EC2`-`$5EE5` (`KillFlashPtr`, `ComboCount`, `ComboTimer`, `Score` and 25 more); `$69B0`-`$69B7` (`AnimChar111`); `$6AB0`-`$6AB7` (`AnimChar143`); 1 more ranges |
| Ports in | `$7FFE` |

#### `MainLoopLeftover` (`$8CDC`)

**Leftover: CALL SoundSilence: RET after the main loop's JP; nothing reaches it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### DEMO: rex

`src/demo/rex.asm`

#### `ShieldToggle` (`$8CE0`)

**The shield key (input bit 2): unless the sparkle shows or the latch is held, ShieldFlip**

Changed from REX 1's ShieldToggle `$967F` (src/game/rex.asm).

Witness: L1 23 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage2/rec/demo-cycle` 16, `stage1/d1` 7) |
| Called from | `MainLoop` |
| Calls | `ShieldFlip` (falls into) |
| Reads | `$5ED5` (`ShieldKeyLatch`); `$5EE9` (`SparkleMode`) |

#### `ShieldFlip` (`$8CEA`)

**Switch the shield (with energy left): ShieldKeyLatch set, ShieldOn flipped; ShieldToggle falls in, the tutor's panels jump here (rooms 0 and 4)**

Witness: L1 31 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 31 calls (`stage2/rec/demo-cycle` 22, `stage1/d1` 9) |
| Called from | `ShieldToggle` (falls into), `TutorEvents1` (tail), `TutorEvents4` (tail) |
| Reads | `$5ED2`-`$5ED6` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`) |
| Writes | `$5ED2`-`$5ED5` (`ShieldOn`, `ShieldKeyLatch`) |

#### `RexState` (`$8CFC`)

**Rex's death animation while he is present and Dying `$5EDE` is set, else nothing**

As REX 1's RexState `$969B` (src/game/rex.asm).

Witness: L1 6753 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,753 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,533) |
| Called from | `MainLoop` |
| Calls | `DrawRex` (falls into), `DeathAnimation` (tail) |
| Reads | `$5EDE`-`$5EE6` (`Dying`, `DeathTimer`, `DeathShardPtr`, `RestartX` and 4 more) |

#### `DrawRex` (`$8D08`)

**Draw Rex: his picture by the frame lists RexFramesJump `$AF5E` (jumping or falling, off a lift) or RexFramesWalk `$AF6E`; with the shield on, its hum, its drain and the bubble (RexFrames `$AF1E`, 4 x 24)**

Changed from REX 1's DrawRex `$96A7` (src/game/rex.asm).

Witness: L1 6627 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,627 calls (`stage2/rec/demo-cycle` 5,110, `stage1/d1` 1,517) |
| Called from | `RexState` (falls into), `DeathAnimation` (tail) |
| Calls | `ShieldDrain`, `Random2`, `DrawSprite`, `StartSfx` |
| Reads | `$5B7C`-`$5B8A` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight` and 8 more); `$5ED2` (`ShieldOn`); `$6074` (`OnLift`); `$DA3E` (`Channels+8`) |
| Writes | `$5B7C`-`$5B7F` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$5EBC` (`SpriteMirror`); `$D9A4`-`$D9A5` (`SfxShieldTone`) |

### DEMO: bomb

`src/demo/bomb.asm`

#### `SmartBombFree` (`$8DA1`)

**A smart bomb that costs nothing (Rex's death): unless one is running, mark the room's objects**

As REX 1's SmartBombFree `$9749` (src/game/bomb.asm).

Witness: L1 6 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 1) |
| Called from | `RexDies` |
| Calls | `SmartBombMark` (tail) |
| Reads | `$5EB9` (`SmartBombOn`) |

#### `SmartBomb` (`$8DA9`)

**SPACE: one smart bomb from Bombs `$5EF5` (none left, nothing), the HUD updated, the room's objects marked**

As REX 1's SmartBomb `$9751` (src/game/bomb.asm).

Witness: L1 4 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage2/rec/demo-cycle` 3, `stage1/d1` 1) |
| Called from | `TutorEvents1` (tail), `TutorEvents4` (tail) |
| Calls | `ShowBombs` |
| Reads | `$5EB9` (`SmartBombOn`); `$5EF5` (`Bombs`) |
| Writes | `$5EF5` (`Bombs`) |

#### `SmartBombMark` (`$8DBB`)

**Start the smart bomb: SmartBombOn `$5EB9` = 1, 16 steps, the object pointer at the table's start; every enemy bullet stopped (live byte set to 2)**

As REX 1's SmartBombMark `$9763` (src/game/bomb.asm).

Witness: L1 10 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 1) |
| Called from | `SmartBombFree` (tail) |
| Reads | `$5D5D`-`$5E7A` |
| Writes | `$5D5D`-`$5DB7`; `$5DD5`; `$5DF3`; `$5EB8`-`$5EBB` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`) |

#### `SmartBombStep` (`$8DDE`)

**One step of a running smart bomb: KillObject on the next object record (not kinds `$FE`, `$FD`, `$FC`, `$90`; neither the alive byte nor kind `$FF` tested); CopyAttrs after the last step; records of 23 bytes**

As REX 1's SmartBombStep `$9786` (src/game/bomb.asm).

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop` |
| Calls | `ShowPoints`, `CopyAttrs` |
| Reads | `$5EB8`-`$5EBB` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`); `$5EFF`-`$5FB7`; `$5FCE`; `$5FE5`; `$5FFC`; `$6013`; 3 more ranges |
| Writes | `$5EB8`-`$5EBB` (`SmartBombSteps`, `SmartBombOn`, `SmartBombPtr`) |

#### `WaitQuiet` (`$8E1B`)

**The sound off, a count of 60000, the sound on: WeaponPanel's fixed wait (part 1 waits for fire)**

Witness: L1 7 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 2) |
| Called from | `WeaponPanel` |
| Calls | `SoundReset`, `SoundSilence` |

#### `PointsLeftover` (`$8E2B`)

**Leftover: REX 1's points sign set-up: picture SpritePoints, IX+`$0D` = 8, 3 x 24, kind `$FF`, at rest; no instruction reaches it**

LD HL,SpritePoints: the picture IX+4/5, IX+`$0D` = 8, the width IX+`$0E` = 3 bytes, IX+`$0F` = 24 lines, kind IX+9 = `$FF`, the speed IX+2/3 = 0, RET. DEMO's ShowPoints jumps to FindSlot after setting the picture and never reaches these bytes (known only from the code).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowPoints` (`$8E4D`)

**Turn the object at IX (in the play area) into the points sign SpritePoints: the kind's score (KillScores `$8EA8`), the explosion sound, kind `$FF`; the HUD kill flash reset**

ShowPoints is DEMO's KillObject: no combo, no people count.

Witness: L1 155 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 155 calls (`stage2/rec/demo-cycle` 127, `stage1/d1` 28) |
| Called from | `SmartBombStep`, `WalkOff` (tail), `ObjectFall` (tail), `ObjectHitsRex`, `HitObject` (tail) |
| Calls | `AddScore`, `StartSfx` |
| Reads | `$5EF7`-`$5F98`; `$5FAF`-`$5FC6`; `$5FDD`; `$5FF4`; `$600B`; `$6022`; 3 more ranges |
| Writes | `$5EC2`-`$5EC6` (`KillFlashPtr`, `ComboCount`, `ComboTimer`); `$5EF7`-`$5F8F` |

#### `TutorArrow` (`$8EB8`)

**Room 4 only, tutor frames 60-599: the arrow SpriteArrow `$88FC` drawn on its path ArrowPath `$8F32`, held at random; at frame 570 the path changes to ArrowPath2 (TutorArrowSwitch)**

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,752 calls (`stage2/rec/demo-cycle` 5,219, `stage1/d1` 1,533) |
| Called from | `MainLoop` |
| Calls | `TutorArrowSwitch`, `Random2`, `DrawSprite` |
| Reads | `$5B85` (`Room`); `$5EBF`-`$5EC1` (`ArrowPathPtr`, `ArrowMoving`); `$6083`-`$6084` (`TutorFrame`); `$8F32`-`$8F78` (`ArrowPath`) |
| Writes | `$5B7C`-`$5B7F` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$5EBC`-`$5EC1` (`SpriteMirror`, `SpritePicture`, `ArrowPathPtr`, `ArrowMoving`) |

#### `TutorArrowSwitch` (`$8F27`)

**The arrow's second path ArrowPath2 `$8F5A`, moving again**

Witness: L1 3 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/demo-cycle` 2, `stage1/d1` 1) |
| Called from | `TutorArrow` |
| Writes | `$5EBF`-`$5EC1` (`ArrowPathPtr`, `ArrowMoving`) |

### DEMO: score

`src/demo/score.asm`

#### `KillFlashFade` (`$8F79`)

**Fade the HUD's kill flash one step (attribute row `$5840`, 30 cells), then mark the latest kill's two cells white**

As REX 1's KillFlashFade `$9992` (src/game/score.asm).

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop` |
| Reads | `$5840`-`$585D` (screen); `$5EC2`-`$5EC3` (`KillFlashPtr`) |
| Writes | `$5843`-`$585C` (screen); `$E9FF`-`$EA00` (`ObjectBufferOrigin`) |

#### `ShowScore` (`$8F92`)

**Print Score `$5EC7` in the HUD**

As REX 1's ShowScore `$99AB` (src/game/score.asm).

Witness: L1 69 (d1, demo-cycle).

[Animation: `ShowScore` at work](img/routines/ShowScore.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 69 calls (`stage2/rec/demo-cycle` 57, `stage1/d1` 12) |
| Called from | `AddScore` (tail) |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$5EC7`-`$5EC8` (`Score`) |

#### `ShowLives` (`$8FA2`)

**Print Lives `$5EEC` in the HUD**

As REX 1's ShowLives `$99BB` (src/game/score.asm).

Witness: L1 8 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage2/rec/demo-cycle` 6, `stage1/d1` 2) |
| Called from | `NewGame`, `LifeLost` |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$5EEC` (`Lives`) |

#### `ShieldDrainFast` (`$8FB5`)

**ShieldDrainRate `$5ED7` - 1: a hit on the shield drains it faster (EnemyBulletsHitRex, ObjectHitsRex)**

As REX 1's ShieldDrainFast `$99CE` (src/game/score.asm).

Witness: L1 51 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 51 calls (`stage2/rec/demo-cycle` 36, `stage1/d1` 15) |
| Called from | `EnemyBulletsHitRex`, `ObjectHitsRex` |
| Calls | `ShieldDrain` (falls into) |
| Writes | `$5ED7` (`ShieldDrainRate`) |

#### `ShieldDrain` (`$8FBA`)

**With the shield on, count ShieldDrainRate down; at 0 one unit of ShieldEnergy `$5ED6` goes; none left switches the shield off**

As REX 1's ShieldDrain `$99D3` (src/game/score.asm).

Witness: L1 531 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 531 calls (`stage2/rec/demo-cycle` 392, `stage1/d1` 139) |
| Called from | `DrawRex`, `ShieldDrainFast` (falls into) |
| Calls | `ShowShield` |
| Reads | `$5ED6`-`$5ED7` (`ShieldEnergy`, `ShieldDrainRate`) |
| Writes | `$5ED2`-`$5ED7` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate`) |

#### `ShowShield` (`$8FE1`)

**Print ShieldEnergy `$5ED6` in the HUD and colour it: red when low, green otherwise (`$E513`, `$E514` in the attribute shadow)**

As REX 1's ShowShield `$99FA` (src/game/score.asm).

Witness: L1 475 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 475 calls (`stage2/rec/demo-cycle` 339, `stage1/d1` 136) |
| Called from | `MainLoop`, `ShieldDrain`, `CellsUnderRex` |
| Calls | `PrintDigits`, `ToDigits` |
| Reads | `$5ED6` (`ShieldEnergy`) |
| Writes | `$5814`-`$5815` (screen); `$E513`-`$E514` (`ShieldAttrs`) |

#### `ShowHeat` (`$900E`)

**The HUD cell `$5817` (and its shadow `$E516`) in the colour HeatColour `$6071`**

Witness: L1 12 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 calls (`stage2/rec/demo-cycle` 9, `stage1/d1` 3) |
| Called from | `MainLoop` |
| Reads | `$6071` (`HeatColour`) |
| Writes | `$5817` (screen); `$E516` (`HeatAttr`) |

#### `ShieldHitSound` (`$9018`)

**The sound of an enemy bullet on the shield (`$D9A9`)**

Witness: L1 3 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/demo-cycle` 2, `stage1/d1` 1) |
| Called from | `EnemyBulletsHitRex` |
| Calls | `StartSfx` |

#### `HeatLeftover` (`$901F`)

**Leftover: HeatColour - 1, the count 100, ShowHeat, and at colour 2 RexDies; nothing calls it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `HeatStep` (`$9036`)

**Every 100 passes HeatColour + 1 up to 7, ShowHeat (RexDies sets it back to 7, NewGame to 7)**

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop` |
| Reads | `$6071`-`$6073` (`HeatColour`, `HeatCount`) |
| Writes | `$6072`-`$6073` (`HeatCount`) |

#### `AddScore` (`$9054`)

**Score + DE (none while dying); ExtraLifeCount + DE, taken back by 200 when it reaches 200 (no extra life in the demo); ShowScore**

Changed from REX 1's AddScore `$9A27` (src/game/score.asm).

Witness: L1 69 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 69 calls (`stage2/rec/demo-cycle` 57, `stage1/d1` 12) |
| Called from | `ShowPoints`, `HitObject`, `HitObjectHard` |
| Calls | `ShowScore` (tail) |
| Reads | `$5EC7`-`$5EC8` (`Score`); `$5EDE` (`Dying`); `$606F`-`$6070` (`ExtraLifeCount`) |
| Writes | `$5EC7`-`$5EC8` (`Score`); `$606F`-`$6070` (`ExtraLifeCount`) |

#### `FadeStep` (`$9076`)

**The HUD flash of a power pod (only TakePowerPod starts it): rows 0-1 (`$5800-$583F`) stepped through FadeSteps `$90DD` by FadeStepIndex `$5ECB`**

As REX 1's FadeStep `$9A4C` (src/game/score.asm).

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop` |
| Reads | `$5800`-`$583F` (screen); `$5B60` (`Temp1`); `$5ECB` (`FadeStepIndex`); `$90DD`-`$90EE` (`FadeSteps`); `$E4FF`-`$E53E` (`AttrShadow`, `ShieldAttrs`, `HeatAttr`, `SweepAttrs`) |
| Writes | `$5800`-`$583F` (screen); `$5B60` (`Temp1`); `$5ECB` (`FadeStepIndex`) |

### DEMO: death

`src/demo/death.asm`

#### `DeathAnimation` (`$90EF`)

**One pass of Rex's death: the shards, the death picture, the sound; at the end LifeLost**

As REX 1's DeathAnimation `$9AC5` (src/game/death.asm).

Witness: L1 102 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 102 calls (`stage2/rec/demo-cycle` 85, `stage1/d1` 17) |
| Called from | `RexState` (tail) |
| Calls | `DrawRex` (tail) |
| Reads | `$5EEC` (`Lives`) |

#### `ShardNext` (`$91F2`)

**DeathShardPtr `$5EE0` + 2**

As REX 1's ShardNext `$9BC8` (src/game/death.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShardBack` (`$91FB`)

**DeathShardPtr `$5EE0` - 2: the shards step back**

As REX 1's ShardBack `$9BD1` (src/game/death.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RexDies` (`$9204`)

**Rex is killed (unless Immune): the sweep reset, Dying, the timer 50, the shards, the free smart bomb, the shield energy 99, HeatColour 7, dematerialise while lives are left**

Changed from REX 1's RexDies `$9BDA` (src/game/death.asm).

Witness: L1 6 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 1) |
| Called from | `TutorDie`, `RexFall` |
| Calls | `SmartBombFree`, `Dematerialise`, `ResetSweep` |
| Reads | `$5EEC` (`Lives`); `$606A` (`Immune`) |
| Writes | `$5ED6`-`$5EE1` (`ShieldEnergy`, `ShieldDrainRate`, `WeaponIcon`, `HasDoubleFire` and 7 more); `$6071`-`$6073` (`HeatColour`, `HeatCount`) |

#### `RestartMarker` (`$926D`)

**Rex on the restart marker (7): the save sound, the marker animated; at X & 7 = 0 the restart point (X, Y, room) kept; then (LifeLost `$92AE`) a death's end: a life less, Rex back at the point or a new demo game**

Witness: L1 276 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 276 calls (`stage2/rec/demo-cycle` 220, `stage1/d1` 56) |
| Called from | `CellsUnderRex` (tail) |
| Calls | `AnimateRestart`, `StartSfx` |
| Reads | `$5B83`-`$5B88` (`RexX`, `RexY`, `Room`, `RoomColumn` and 1 more); `$DA3E` (`Channels+8`); `$E2AF`-`$E2B0` (`RoomGridPlay+176`); `$E351`-`$E358` (`RoomGridPlay+338`); `$E3AE`-`$E3AF` (`RoomGridPlay+431`) |
| Writes | `$5EE2`-`$5EE4` (`RestartX`, `RestartY`, `RestartRoom`) |

#### `LifeLost` (`$92AE`)

**LifeLost**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `SparkleDraw` (tail) |
| Calls | `MainLoop` (tail), `ShowLives`, `Materialise` |
| Reads | `$5B85` (`Room`); `$5EE2`-`$5EEC` (`RestartX`, `RestartY`, `RestartRoom`, `RestartFacing` and 7 more) |
| Writes | `$5B80`-`$5B8F` (`RexFrame`, `RexX`, `RexY`, `Room` and 6 more); `$5ED2`-`$5EEC` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`, `ShieldDrainRate` and 20 more) |

#### `RexAppears` (`$92F9`)

**The materialise is over: RexPresent `$5EE6` = 1 (Rex can move and fire), SparkleCount `$5EE7` = 18**

As REX 1's RexAppears `$9D0F` (src/game/death.asm).

Witness: L1 339 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 339 calls (`stage2/rec/demo-cycle` 260, `stage1/d1` 79) |
| Called from | `SparkleDraw` |
| Reads | `$5EE6` (`RexPresent`) |
| Writes | `$5EE6`-`$5EE7` (`RexPresent`, `SparkleCount`) |

#### `Materialise` (`$9309`)

**Rex appears: RexPresent 0, the sparkle in (SparkleOn `$5EE8`, SparkleMode `$5EE9`), its dots cleared, the materialise sound `$D9B2`**

As REX 1's Materialise `$9D1F` (src/game/death.asm).

Witness: L1 5 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage2/rec/demo-cycle` 4, `stage1/d1` 1) |
| Called from | `LifeLost`, `TutorRoom0`, `TutorRoom1` |
| Calls | `StartSfx` |
| Reads | `$94FA`-`$9534` (`SparkleDots`) |
| Writes | `$5EE6`-`$5EEB` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more); `$94FA`-`$9535` (`SparkleDots`) |

#### `Dematerialise` (`$9331`)

**Rex vanishes: the shield off, the sparkle out (Vanishing `$5EEB` = 1), the sound `$D9BE`**

As REX 1's Dematerialise `$9D47` (src/game/death.asm).

Witness: L1 6 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 1) |
| Called from | `RexDies` |
| Calls | `StartSfx` |
| Reads | `$5EE6` (`RexPresent`) |
| Writes | `$5EE6`-`$5EEB` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more) |

#### `SparkleUpdate` (`$9357`)

**One step of the sparkle in Rex's 3-byte box of the back buffer (SparkleBufferOrigin `$E89F`): SparkleCount lines cleared, the next 3 ANDed with random bytes; at the end the sparkle stops**

As REX 1's SparkleUpdate `$9D71` (src/game/death.asm).

Witness: L1 6753 (d1, demo-cycle).

[Animation: `SparkleUpdate` at work](img/routines/SparkleUpdate.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,753 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,533) |
| Called from | `MainLoop` |
| Calls | `FillCells3`, `Random2` |
| Reads | `$5B83`-`$5B84` (`RexX`, `RexY`); `$5EE6`-`$5EEB` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 2 more); `$EDCC`-`$EFF0` (`BackBuffer+716`); `$F2CE`-`$F532` (`BackBuffer+1998`); `$F5CD`-`$F5CF` (`BackBuffer+2765`); `$F5ED`-`$F82F` (`BackBuffer+2797`); 3 more ranges |
| Writes | `$5EE6`-`$5EEA` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 1 more); `$EDCC`-`$EFF0` (`BackBuffer+716`); `$F2CE`-`$F532` (`BackBuffer+1998`); `$F5CD`-`$F5CF` (`BackBuffer+2765`); `$F5ED`-`$F82F` (`BackBuffer+2797`); `$FAC2`-`$FB04` (`BackBuffer+4034`); 2 more ranges |

#### `SparkleLeftover` (`$93AF`)

**Leftover: LD A,100: LD (SparkleTimer),A; nothing reaches it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SparkleOut` (`$93B4`)

**Vanishing: SparkleCount `$5EE7` + 1; at 18 Rex is gone (RexPresent 0) and the sparkle's timer is 30**

As REX 1's SparkleOut `$9DCE` (src/game/death.asm).

Witness: L1 102 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 102 runs of its first instruction, entered by a jump (`stage2/rec/demo-cycle` 85, `stage1/d1` 17) |

#### `SparkleIfOn` (`$93D4`)

**Leftover: if SparkleOn, SparkleDraw; nothing calls it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `FillCells3` (`$93DC`)

**Write C into a 3 x 3 patch at HL (32-byte rows)**

As REX 1's FillCells3 `$9DF6` (src/game/death.asm).

Witness: L1 192 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 192 calls (`stage2/rec/demo-cycle` 157, `stage1/d1` 35) |
| Called from | `SparkleUpdate` |
| Writes | `$EBAE`-`$EF90` (`BackBuffer+174`); `$F0B5`-`$F4D2` (`BackBuffer+1461`); `$F5AD`-`$F7CF` (`BackBuffer+2733`); `$F8A2`-`$FAA4` (`BackBuffer+3490`); `$FDB0`-`$FF52` (`BackBuffer+4784`); `$FF70`-`$FF72` (`BackBuffer+5232`); 2 more ranges |

#### `SparkleDraw` (`$93E8`)

**Draw the sparkle's particles round Rex (SparkleMasks `$94F2` by X & 7, SparkleDots `$94FA`); at the end of a dematerialise LifeLost**

Changed from REX 1's SparkleDraw `$9E02` (src/game/death.asm).

Witness: L1 6753 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 18,337 t-states own (0.00 %) |
| Runs (the other recordings) | 6,753 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,533) |
| Called from | `MainLoop`, `ShowWeaponIcons` (tail) |
| Calls | `LifeLost` (tail), `RexAppears`, `Random2`, `TutorTexts`, `DrawCharBlock` |
| Reads | `$5B60` (`Temp1`); `$5B83`-`$5B84` (`RexX`, `RexY`); `$5EDE`-`$5EEB` (`Dying`, `DeathTimer`, `DeathShardPtr`, `RestartX` and 9 more); `$94F2`-`$9535` (`SparkleMasks`, `SparkleDots`); `$A093` (`AnimateRestart+8`); `$E4FF`-`$E7FD` (`AttrShadow`, `ShieldAttrs`, `HeatAttr`, `SweepAttrs` and 1 more); 5 more ranges |
| Writes | `$5B60` (`Temp1`); `$5B84` (`RexY`); `$5EE6`-`$5EEA` (`RexPresent`, `SparkleCount`, `SparkleOn`, `SparkleMode` and 1 more); `$94FA`-`$9535` (`SparkleDots`); `$A018` (`BufferAddress+15`); `$A030`-`$A0C2` (`BufferAddress+39`, `AnimateCells`, `AnimateCells2`, `AnimateRestart` and 1 more); 8 more ranges |
| Ports out | `$00FE` |

### DEMO: cells

`src/demo/cells.asm`

#### `CellsUnderRex` (`$9545`)

**Test the cells under Rex and act: the lift (`$12`), the restart marker (7), the conveyor (9: Rex one pixel left), the recharger (8, up to 99), the weapon stations (`$0A-$0D`, each with its panel)**

Changed from REX 1's CellsUnderRex `$9F5F` (src/game/cells.asm).

Witness: L1 6536 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,043,987 t-states own (0.07 %) |
| Runs (the other recordings) | 6,536 calls (`stage2/rec/demo-cycle` 5,036, `stage1/d1` 1,500) |
| Called from | `MainLoop`, `DrawHud` (tail), `Scanner` (tail) |
| Calls | `ShowShield`, `RestartMarker` (tail), `TutorPanelPower`, `PanelLeftover`, `TutorRoom2`, `TutorRoom4`, `TutorEvents1`, `TutorEvents4`, `DrawWeaponIcon`, `HudTexts`, `PrintText`, `CopyFrame`, `UpdateDrones`, `DroneOrbit`, `GiveDoubleFire`, `GiveLaser`, `GiveMultiple`, `GiveSpray`, `RollCharUp`, `ShardPictures`, `TutorTexts`, `TutorScript0`, `Scanner`, `ScannerTurn`, `SpawnRandom`, `PanelBox`, `ObjectHitsRex`, `HitObjectHard`, `StartSfx`, `WeaponPanel` |
| Reads | `$5EA2`-`$5EA3` (`RexCellPtr`); `$5ED2`-`$5ED6` (`ShieldOn`, `ShieldKeyLatch`, `ShieldEnergy`); `$6758`-`$675F` (`AnimChar28+64`); `$6858`-`$685F` (`AnimChar68`); `$A017` (`BufferAddress+14`); `$A040` (`AnimFrameB+1`); 6 more ranges |
| Writes | `$5ED6` (`ShieldEnergy`); `$6074` (`OnLift`); `$6758`-`$675F` (`AnimChar28+64`); `$6858`-`$685F` (`AnimChar68`); `$A012`-`$A01A` (`BufferAddress+9`); `$A04C` (`l_A045+7`); 1 more ranges |
| Ports in | `$7FFE`, `$BFFE` |

### DEMO: tutor

`src/demo/tutor.asm`

#### `TutorPanel` (`$9605`)

**A tutor panel: the screen saved, the sound off, the B text records at IX boxed (PanelOpen), a count of 33000, the screen back (PanelClose)**

Witness: L1 10 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 590 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10 calls (`stage2/rec/demo-cycle` 10) |
| Called from | `TutorPanels` (tail), `TutorEvents1` (tail) |
| Calls | `PanelOpen`, `PanelClose` (tail) |

#### `TutorPanelLong` (`$960E`)

**A tutor panel with a count of 65000**

Witness: L1 3 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/demo-cycle` 2, `stage1/d1` 1) |
| Called from | `TutorEvents1` |
| Calls | `PanelOpen`, `PanelClose` (tail) |

#### `TutorPanelShort` (`$9617`)

**A tutor panel with a count of 20000**

Witness: L1 8 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 8 calls (`stage2/rec/demo-cycle` 8) |
| Called from | `TutorEvents1` |
| Calls | `PanelOpen`, `PanelClose` (tail), `TutorTexts`, `TutorScript0` |

#### `PanelOpen` (`$9620`)

**The screen saved (SaveScreen), the sound off, the records at IX boxed (PrintBoxed)**

Witness: L1 21 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 21 calls (`stage2/rec/demo-cycle` 20, `stage1/d1` 1) |
| Called from | `TutorPanel`, `TutorPanelLong`, `TutorPanelShort` |
| Calls | `PrintBoxed`, `TutorTexts`, `MakeObjects`, `SoundSilence`, `SaveScreen` |

#### `PanelClose` (`$9630`)

**The count BC (Delay), the buffer and attributes back on the screen, the sound on; from `$963D` a panel with the ammunition flash (FlashTwoCells)**

Witness: L1 21 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 356 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 21 calls (`stage2/rec/demo-cycle` 20, `stage1/d1` 1) |
| Called from | `TutorPanel` (tail), `TutorPanelLong` (tail), `TutorPanelShort` (tail) |
| Calls | `BufferToScreen`, `TutorTexts`, `CopyAttrs`, `Delay`, `MakeObjectIY`, `InitKind8`, `InitKind7C`, `InitKind11`, `SoundReset` |

#### `TutorPanelFlash` (`$963D`)

**TutorPanelFlash**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `TutorPanels` (tail) |
| Calls | `FlashTwoCells`, `PrintBoxed`, `BufferToScreen`, `TutorKeyLeft`, `TutorTexts`, `CopyAttrs`, `Delay`, `MakeObjectIY`, `SoundReset`, `SoundSilence`, `SaveScreen` |

#### `TutorPanelPower` (`$965F`)

**A tutor panel, the count 40000, then the power bar's colours shown (PowerColours)**

Witness: L1 3 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 448 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage2/rec/demo-cycle` 2, `stage1/d1` 1) |
| Called from | `CellsUnderRex`, `TutorEvents1` |
| Calls | `PowerColours`, `PrintBoxed`, `BufferToScreen`, `TutorTexts`, `CopyAttrs`, `Delay`, `SoundReset`, `SoundSilence`, `SaveScreen` |
| Reads | `$A060` (`l_A045+27`) |

#### `PanelLeftover` (`$9681`)

**Leftover: a panel, then five flashes of the HUD cell `$5817`; nothing calls it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 136,530 t-states own (0.01 %) |
| Called from | `CellsUnderRex`, `TutorPowerDrop` (tail) |
| Calls | `TutorPowerDrop` (tail) |
| Reads | `$A049`-`$A05D` (`l_A045+4`); `$A07A` (`l_A045+53`); `$A0B6`-`$A0BD` (`CopyFrameNext+17`, `CopyFrameDo`) |
| Writes | `$A033` (`AnimateCells+1`); `$A0AF`-`$A0B2` (`CopyFrameNext+10`) |

#### `TutorRoom0` (`$96B9`)

**Room 0's tutor: the panel YOU HAVE NOW SEEN THE HARDWARE (TutorText0), the scripted spawn TutorSpawn0 `$A2C4`, three weapons held, power 5, Rex at (136, 72), its input script TutorScript0 `$B057`, the spray panel shown, Rex appears, TutorReset**

Witness: L1 1 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `MainLoop` |
| Calls | `Materialise`, `TutorReset`, `PrintBoxed`, `TutorScript0`, `Delay`, `StartScriptSpawn` |
| Writes | `$5B83`-`$5B84` (`RexX`, `RexY`); `$5E9D` (`PowerLevel`); `$5ED9`-`$5EE3` (`HasDoubleFire`, `HasLaser`, `HasMultiple`, `HasSpray` and 6 more); `$6080`-`$6081` (`TutorScriptPtr`); `$A6E5` (`SprayText`) |

#### `TutorRoom1` (`$9702`)

**Room 1's tutor: NEXT AN EXPLANATION OF THE FIVE WEAPON SYSTEMS (TutorText1), Rex at (120, 32), power 4, TutorScript1 `$B1E7`**

Witness: L1 3 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/demo-cycle` 2, `stage1/d1` 1) |
| Called from | `MainLoop` |
| Calls | `Materialise`, `TutorReset`, `PrintBoxed`, `Delay` |
| Writes | `$5B83`-`$5B84` (`RexX`, `RexY`); `$5E9D` (`PowerLevel`); `$5EE2`-`$5EE3` (`RestartX`, `RestartY`); `$6080`-`$6081` (`TutorScriptPtr`) |

#### `TutorRoom2` (`$9735`)

**Room 2's tutor, once (TutorDone `$6087`): Rex at (8, 144), power 4, all four weapons, AND FINALLY A FEW GUIDELINES (TutorText2), the scripted spawn `$A2FE`, TutorScript2 `$B5C7`**

Witness: L1 2 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 46,211 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage2/rec/demo-cycle` 2) |
| Called from | `MainLoop`, `CellsUnderRex`, `HudSweep` |
| Calls | `TutorReset`, `PrintBoxed`, `DroneOrbit`, `Delay`, `StartScriptSpawn` |
| Reads | `$5D28`-`$5E45`; `$5E6F`-`$5F2F` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 66 more); `$5F47`; `$5F5F`; `$5F77`; `$5F8F`; 6 more ranges |
| Writes | `$5B83`-`$5B84` (`RexX`, `RexY`); `$5D28`-`$5D91`; `$5E9D` (`PowerLevel`); `$5ED9`-`$5EEB` (`HasDoubleFire`, `HasLaser`, `HasMultiple`, `HasSpray` and 14 more); `$6080`-`$6087` (`TutorScriptPtr`, `TutorCount`, `TutorFrame`, `TutorRoomPtr` and 1 more); `$A02F`-`$A032` (`BufferAddress+38`, `AnimateCells`); 1 more ranges |

#### `TutorRoom4` (`$979C`)

**Room 4's tutor, the demo's first room: YOU ARE ABOUT TO SEE A DEMO OF REX (TutorIntro), FIRST A SHORT PROLOGUE (TutorPrologue), Rex at (112, 176), power 4, TutorScript4 `$B833`**

Witness: L1 2 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 96 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 74,961,182 t-states own (5.16 %) |
| Runs (the other recordings) | 2 calls (`stage1/d1` 1, `stage2/rec/demo-cycle` 1) |
| Called from | `MainLoop`, `CellsUnderRex`, `ShowWeaponIcons` |
| Calls | `TutorPanels`, `TutorReset`, `PrintBoxed`, `TutorTexts`, `ScannerUp`, `Delay`, `ObjectHitsRex` |
| Writes | `$5B83`-`$5B84` (`RexX`, `RexY`); `$5E9D` (`PowerLevel`); `$5EE2`-`$5EEB` (`RestartX`, `RestartY`, `RestartRoom`, `RestartFacing` and 6 more); `$6080`-`$6081` (`TutorScriptPtr`); `$A093` (`AnimateRestart+8`) |

#### `AtFrame` (`$97ED`)

**Z if the tutor's frame TutorFrame `$6083` = DE**

Witness: L1 81240 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 138,469 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 81,240 calls (`stage2/rec/demo-cycle` 64,873, `stage1/d1` 16,367) |
| Called from | `TutorPanels`, `TutorEvents1`, `TutorEvents4` |
| Calls | `TutorTexts`, `ObjectHitsRex` |
| Reads | `$6083`-`$6084` (`TutorFrame`) |

#### `ShowFrameLeftover` (`$9800`)

**Leftover: the tutor frame printed as digits (a debugging aid); nothing calls it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TutorPanels` (`$9810`)

**Each pass: TutorFrame + 1, then the room's events at their frames: panels (TutorPanel*), power changes, the shield, a smart bomb, deaths (TutorDie) and the end (TutorNextRoom); room 0 here, room 1 TutorEvents1, rooms 2-3 TutorEvents2, rooms 4-5 TutorEvents4**

Room 0: REX MUST FIRST COLLECT WEAPONS at frame 25, AN EXTRA BONUS at 190, power drops at 250, 340, 430, THE LASER CAN at 345, power 3 and a drop at 600, a death at 710, the next room at 750.

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 21,650 t-states own (0.00 %) |
| Runs (the other recordings) | 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop`, `TutorRoom4` |
| Calls | `TutorPanel` (tail), `TutorPanelFlash` (tail), `AtFrame`, `TutorEvents1` (tail), `TutorEvents4` (tail), `TutorDie`, `TutorNextRoom` (tail), `TutorPower3`, `PowerDrain`, `ObjectHitsRex` |
| Reads | `$5B85` (`Room`); `$5E67`-`$5FD7` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 66 more); `$6083`-`$6084` (`TutorFrame`); `$994E`-`$9959` (`TutorEvents1+168`) |
| Writes | `$5E67`-`$5ED5` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 34 more); `$6083`-`$6084` (`TutorFrame`); `$A039`-`$A03D` (`AnimateCells+7`) |

#### `TutorEvents1` (`$98A6`)

**Room 1's events: REX STARTS WITH THE STANDARD ISSUE (34), EACH WEAPON HAS A POWER STATUS (15), the weapons one by one with their power stepped (TutorWeapon*), the spray panels 3, 5, 7 WAY, 4 DIRECTIONAL, FULL 8 WAY (743-1081), a death at 1310, the next room at 1340; from `$9979` rooms 2 and 3's: the shield, the bubbles, the beam pads, the recharger, the question marks, the walls, the exits, the scanners, falling, smart bombs**

Witness: L1 1948 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 16 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,045,966 t-states own (0.07 %) |
| Runs (the other recordings) | 472 calls (`stage1/d1` 472) |
| Called from | `CellsUnderRex`, `TutorPanels` (tail), `PrintBoxed`, `DrawHud`, `TutorTexts` |
| Calls | `ShieldFlip` (tail), `SmartBomb` (tail), `TutorPanel` (tail), `TutorPanelLong`, `TutorPanelShort`, `TutorPanelPower`, `AtFrame`, `TutorPowerDrop`, `TutorPowerUp`, `TutorPower5`, `TutorDie`, `TutorNextRoom` (tail), `PowerDrain`, `ShardPictures`, `BonusTexts` |
| Reads | `$5840`-`$585D` (screen); `$A039`-`$A063` (`AnimateCells+7`, `AnimFrameB`, `l_A045`); `$A076`-`$A077` (`l_A045+49`); `$A089`-`$A08A` (`AnimateCells2+14`) |
| Writes | `$5814`-`$5815` (screen); `$5843`-`$585C` (screen); `$A03E`-`$A03F` (`AnimateCells+12`, `AnimFrameB`); `$A076`-`$A077` (`l_A045+49`); `$A089`-`$A08A` (`AnimateCells2+14`); `$E513`-`$E514` (`ShieldAttrs`); 1 more ranges |

#### `TutorEvents4` (`$9A4C`)

**Rooms 4 and 5's events: the shield on and off (150, 172, 455, 470), a smart bomb at 930, a death at 1030, the next room at 1060; from `$9A8C` FlashPlay: the play area's attributes made bright five times (the smart bomb's flash)**

Witness: L1 3114 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 702 calls, 23,129 t-states own (0.00 %) |
| Runs (the other recordings) | 1,060 calls (`stage1/d1` 1,060) |
| Called from | `CellsUnderRex`, `TutorPanels` (tail), `TutorTexts` |
| Calls | `ShieldFlip` (tail), `SmartBomb` (tail), `AtFrame`, `BrightenAttr`, `TutorDie` (tail), `TutorNextRoom` (tail), `CopyAttrs`, `Delay` |
| Reads | `$A042` (`AnimFrameB+3`) |

#### `BrightenAttr` (`$9ABA`)

**The attribute at HL bright unless 0; HL + 1**

Changed from REX 1's SpawnFindFree `$C9E5` (src/game/rooms.asm).

Witness: L1 255 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 255 calls (`stage2/rec/demo-cycle` 255) |
| Called from | `TutorEvents4` |
| Reads | `$5874`-`$5A14` (screen); `$5A34` (screen); `$5A54` (screen); `$5A74` (screen); `$5A94` (screen); `$5AB4` (screen); 2 more ranges |
| Writes | `$5874`-`$5A14` (screen); `$5A34` (screen); `$5A54` (screen); `$5A74` (screen); `$5A94` (screen); `$5AB4` (screen); 2 more ranges |

#### `TutorPowerDrop` (`$9AC4`)

**The power drained (PowerDrain) and set to 1**

Witness: L1 2 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 334,004 t-states own (0.02 %) |
| Runs (the other recordings) | 2 calls (`stage2/rec/demo-cycle` 2) |
| Called from | `PanelLeftover` (tail), `TutorEvents1` |
| Calls | `PanelLeftover` (tail), `PowerDrain` |
| Reads | `$9C05`-`$9C3A` (`SweepRight+21`, `ResetSweep`, `PrintBoxed`); `$A056`-`$A063` (`l_A045+17`); `$A093`-`$A096` (`AnimateRestart+8`); `$A0B6`-`$A0B7` (`CopyFrameNext+17`) |
| Writes | `$5E9D` (`PowerLevel`); `$9C0B`-`$9C3A` (`AttractPass`, `ResetSweep`, `PrintBoxed`); `$A033`-`$A035` (`AnimateCells+1`); `$A056` (`l_A045+17`); `$A0AF`-`$A0B2` (`CopyFrameNext+10`); `$D790` (`RouletteEnd+1`) |

#### `TutorPowerUp` (`$9ACD`)

**Power + 1, the drones again (InitDrones)**

Witness: L1 4 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage2/rec/demo-cycle` 4) |
| Called from | `TutorEvents1` |
| Calls | `InitDrones` |
| Reads | `$5E9D` (`PowerLevel`) |
| Writes | `$5E9D` (`PowerLevel`) |

#### `TutorPower5` (`$9AD5`)

**Power 5, the drones again**

Witness: L1 1 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `TutorEvents1` |
| Calls | `InitDrones` |
| Writes | `$5E9D` (`PowerLevel`) |

#### `PowerColours` (`$9ADE`)

**The power bar's five colours shown in turn at `$5801` (Fill2x2)**

Witness: L1 3 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 536 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3 calls (`stage2/rec/demo-cycle` 2, `stage1/d1` 1) |
| Called from | `TutorPanelPower` |
| Calls | `Fill2x2`, `ScannerFrames`, `Delay` |

#### `FlashTwoCells` (`$9AF5`)

**The 2 x 2 cells at `$5809` flashed five times (white, blue)**

Witness: L1 1 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `TutorPanelFlash` |
| Calls | `Fill2x2`, `TutorScript0`, `Delay` |

#### `Fill2x2` (`$9B18`)

**A into the 2 x 2 attributes at HL**

Witness: L1 25 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 calls (`stage2/rec/demo-cycle` 20, `stage1/d1` 5) |
| Called from | `PowerColours`, `FlashTwoCells` |
| Calls | `SpawnRandom` |
| Writes | `$5801`-`$580A` (screen); `$5821`-`$582A` (screen) |

#### `TutorDie` (`$9B23`)

**Rex dies (RexDies), keeping A**

Witness: L1 5 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 472 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 5 calls (`stage2/rec/demo-cycle` 4, `stage1/d1` 1) |
| Called from | `TutorPanels`, `TutorEvents1`, `TutorEvents4` (tail) |
| Calls | `RexDies` |

#### `TutorNextRoom` (`$9B29`)

**The end of a room's script: after room 2 the credits ALL SOFTWARE SOUND AND VISION BY THE LIGHT (TutorCredits), then NextTutorRoom and a new demo game (NewGame)**

Witness: L1 6 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 472 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 1) |
| Called from | `TutorPanels` (tail), `TutorEvents1` (tail), `TutorEvents4` (tail) |
| Calls | `NewGame` (tail), `NextTutorRoom`, `ClearPlayAttrs`, `HudSweep`, `PrintBoxed`, `BufferToScreen`, `ClearBuffer`, `Delay`, `SpawnScripted`, `SoundSilence` |
| Reads | `$5B85` (`Room`) |

#### `TutorPower3` (`$9B59`)

**Power 3**

Witness: L1 1 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `TutorPanels` |
| Calls | `HudSweep`, `PrintBoxed` (tail) |
| Writes | `$5E9D` (`PowerLevel`) |

#### `PowerDrain` (`$9B5F`)

**Power 0, PowerCount 0, then 40 power gains of `$FF` (the bar runs up), power 5**

Witness: L1 11 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11 calls (`stage2/rec/demo-cycle` 9, `stage1/d1` 2) |
| Called from | `TutorPanels`, `TutorEvents1`, `TutorPowerDrop` |
| Calls | `ShardPaths`, `PowerGain` |
| Writes | `$5E9D`-`$5EA1` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`) |

#### `TutorReset` (`$9B77`)

**The tutor frame 0, the script's first count, TutorInput `$FF` (nothing pressed), TutorDone 0**

Witness: L1 8 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 3) |
| Called from | `GameEntry`, `TutorRoom0`, `TutorRoom1`, `TutorRoom2`, `TutorRoom4` |
| Calls | `ShardPaths` |
| Reads | `$6080`-`$6081` (`TutorScriptPtr`); `$B057` (`TutorScript0`); `$B1E7` (`TutorScript1`); `$B5C7` (`TutorScript2`); `$B833` (`TutorScript4`) |
| Writes | `$6079`-`$6087` (`TutorInput`, `TutorUnused`, `TutorScriptPtr`, `TutorCount` and 3 more) |

#### `NextTutorRoom` (`$9B91`)

**The next room of TutorRooms `$A2A2` into Room (`$FF`: the list again)**

Witness: L1 7 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 2) |
| Called from | `GameEntry`, `TutorNextRoom` |
| Calls | `ShardPaths` |
| Reads | `$6085`-`$6086` (`TutorRoomPtr`); `$A2A2`-`$A2A6` (`TutorRooms`) |
| Writes | `$5B85` (`Room`); `$6085`-`$6086` (`TutorRoomPtr`) |

#### `ClearPlayAttrs` (`$9BAB`)

**The play area's attributes (`$5860-$5AFF`) to 0**

Witness: L1 13 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13 calls (`stage2/rec/demo-cycle` 10, `stage1/d1` 3) |
| Called from | `MainLoop`, `TutorNextRoom` |
| Calls | `ShardPaths` |
| Reads | `$5860`-`$5AFE` (screen) |
| Writes | `$5860`-`$5AFF` (screen) |

### DEMO: hud

`src/demo/hud.asm`

#### `HudSweep` (`$9BB9`)

**One step of the HUD sweep (none while FadeStepIndex is not `$FF`); every 5 round trips one narrower; the width dropping to 0 kills Rex**

As REX 1's HudSweep `$A0C4` (src/game/hud.asm).

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 85 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,334 t-states own (0.00 %) |
| Runs (the other recordings) | 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop`, `TutorNextRoom`, `TutorPower3`, `PanelBox` |
| Calls | `TutorRoom2`, `HudTexts`, `UpdateDrones`, `TutorScript0`, `ObjectHitsRex` |
| Reads | `$582C`-`$5838` (screen); `$5ECB` (`FadeStepIndex`); `$5EED`-`$5EF0` (`SweepPos`, `SweepCount`, `SweepDir`, `SweepWidth`); `$A057`-`$A071` (`l_A045+18`) |
| Writes | `$582B`-`$5838` (screen); `$5EED`-`$5EF0` (`SweepPos`, `SweepCount`, `SweepDir`, `SweepWidth`); `$A04D`-`$A058` (`l_A045+8`); `$E535`-`$E536` (`SweepAttrs+10`) |

#### `ResetSweep` (`$9C28`)

**The HUD sweep's width 12 and count 20**

Changed from REX 1's ResetSweep `$A133` (src/game/hud.asm).

Witness: L1 18 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage2/rec/demo-cycle` 14, `stage1/d1` 4) |
| Called from | `MainLoop`, `RexDies` |
| Writes | `$5EEE`-`$5EF0` (`SweepCount`, `SweepDir`, `SweepWidth`) |

#### `PrintBoxed` (`$9C33`)

**Print B text records from IX in a framed box (attribute A, box from the first record), the panel sound**

As REX 1's PrintBoxed `$A13E` (src/game/hud.asm).

Witness: L1 43 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 10,744 t-states own (0.00 %) |
| Runs (the other recordings) | 43 calls (`stage2/rec/demo-cycle` 36, `stage1/d1` 7) |
| Called from | `PanelOpen`, `TutorPanelFlash`, `TutorPanelPower`, `TutorRoom0`, `TutorRoom1`, `TutorRoom2`, `TutorRoom4`, `TutorNextRoom`, `TutorPower3` (tail), `Random2` (tail), `TutorKeyShield` (tail), `BonusRoulette`, `WeaponPanel` |
| Calls | `TutorEvents1`, `PrintTextHL`, `TutorTexts`, `PanelBox` |
| Reads | `$5B60`-`$5B62` (`Temp1`, `Temp2`); `$A03E`-`$A03F` (`AnimateCells+12`, `AnimFrameB`); `$A059`-`$A063` (`l_A045+20`); `$A089`-`$A08C` (`AnimateCells2+14`, `AnimateRestart`); `$A0B6`-`$A0BB` (`CopyFrameNext+17`); `$A3D3`-`$AC85` (`BonusTexts+1`, `TutorTexts`); 2 more ranges |
| Writes | `$5B60`-`$5B62` (`Temp1`, `Temp2`); `$A049`-`$A063` (`l_A045+4`); `$A091` (`AnimateRestart+6`); `$A0B3`-`$A0BD` (`CopyFrameNext+14`, `CopyFrameDo`) |

#### `DrawHud` (`$9C9A`)

**Draw the HUD: its texts (HudTexts `$9D41`), the frame, the weapon icons and the bombs**

As REX 1's DrawHud `$A1A5` (src/game/hud.asm).

Witness: L1 19 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 19 calls (`stage2/rec/demo-cycle` 14, `stage1/d1` 5) |
| Called from | `NewGame`, `MainLoop` |
| Calls | `CellsUnderRex` (tail), `TutorEvents1`, `ShowWeaponIcons`, `DrawWeaponIcon`, `PrintTextHL`, `FillAttrs` |

#### `ShowBombs` (`$9CBE`)

**Draw the bomb icons for Bombs `$5EF5` (BombIcons `$9CF7`)**

As REX 1's ShowBombs `$A1C9` (src/game/hud.asm).

Witness: L1 26 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 2) |
| Called from | `SmartBomb`, `TakeBombPod` |
| Calls | `DrawBombIcons` |
| Reads | `$5EF5` (`Bombs`) |

#### `DrawBombIcons` (`$9CD0`)

**Three icons from HL: the column at `$9CE8` from 25, two a step**

Changed from REX 1's DrawBombIcons `$A1DB` (src/game/hud.asm).

Witness: L1 26 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 26 calls (`stage2/rec/demo-cycle` 19, `stage1/d1` 7) |
| Called from | `ShowBombs` |
| Calls | `DrawHudIcon` (falls into), `UpdateDrones` |
| Writes | `$9CE8` (`HudIconColumn`) |

#### `DrawHudIcon` (`$9CD7`)

**One HUD icon: SpriteHudIcons `$8464` + offset (HL), by DrawCharBlock `$DABE` with the inline parameters**

As REX 1's DrawHudIcon `$A1E2` (src/game/hud.asm).

Witness: L1 78 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 78 calls (`stage2/rec/demo-cycle` 57, `stage1/d1` 21) |
| Called from | `DrawBombIcons` (falls into), `NextHudIcon` (tail) |
| Calls | `UpdateDrones`, `DrawCharBlock` |
| Reads | `$9CFF`-`$9D05` (`BombIcons+8`) |
| Writes | `$9CE6`-`$9CE7` (`HudIconParams`) |

#### `NextHudIcon` (`$9CEC`)

**The next icon two columns on**

As REX 1's NextHudIcon `$A1F7` (src/game/hud.asm).

Witness: L1 78 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 78 calls (`stage2/rec/demo-cycle` 57, `stage1/d1` 21) |
| Called from | `DrawCharBlock` |
| Calls | `DrawHudIcon` (tail), `BonusTexts` |
| Reads | `$9CE8` (`HudIconColumn`) |
| Writes | `$9CE8` (`HudIconColumn`) |

#### `ShowWeaponIcons` (`$9D07`)

**Draw the weapon icons: WeaponIcon `$5ED8` selects the lit one**

As REX 1's ShowWeaponIcons `$A212` (src/game/hud.asm).

Witness: L1 263 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 7,099 t-states own (0.00 %) |
| Runs (the other recordings) | 263 calls (`stage2/rec/demo-cycle` 180, `stage1/d1` 83) |
| Called from | `DrawHud`, `ToDigits`, `GiveWeapon` |
| Calls | `SparkleDraw` (tail), `TutorRoom4`, `DrawWeaponIcon` (falls into) |
| Reads | `$A05D` (`l_A045+24`) |
| Writes | `$9D2A` (`WeaponIconParams+2`); `$A05D`-`$A05E` (`l_A045+24`) |

#### `DrawWeaponIcon` (`$9D14`)

**One weapon icon: SpriteHudIcons2 `$8504` + offset, DrawCharBlock with the inline parameters**

As REX 1's DrawWeaponIcon `$A21F` (src/game/hud.asm).

Witness: L1 1315 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 6,978 t-states own (0.00 %) |
| Runs (the other recordings) | 1,315 calls (`stage2/rec/demo-cycle` 900, `stage1/d1` 415) |
| Called from | `CellsUnderRex`, `DrawHud`, `ShowWeaponIcons` (falls into), `NextWeaponIcon` (tail) |
| Calls | `DrawCharBlock` |
| Reads | `$5ED8`-`$5EDC` (`WeaponIcon`, `HasDoubleFire`, `HasLaser`, `HasMultiple` and 1 more); `$9F14`-`$9F4E` (`ToDigits+44`, `DigitOf`) |
| Writes | `$9D28`-`$9D29` (`WeaponIconParams`); `$9F14`-`$9F4F` (`ToDigits+44`, `DigitOf`); `$A05D`-`$A062` (`l_A045+24`) |

#### `NextWeaponIcon` (`$9D2E`)

**The next weapon icon two columns on**

As REX 1's NextWeaponIcon `$A239` (src/game/hud.asm).

Witness: L1 1315 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,315 calls (`stage2/rec/demo-cycle` 900, `stage1/d1` 415) |
| Called from | `DrawCharBlock` |
| Calls | `DrawWeaponIcon` (tail) |
| Reads | `$9D2A` (`WeaponIconParams+2`) |
| Writes | `$9D2A` (`WeaponIconParams+2`) |

#### `BufferToScreen` (`$9D7F`)

**Copy the back buffer's 168 play lines to the screen through ScreenLines `$ACBE` (the stack as the pointer)**

As REX 1's BufferToScreen `$A28A` (src/game/hud.asm).

Witness: L1 6797 (d1, demo-cycle).

[Animation: `BufferToScreen` at work](img/routines/BufferToScreen.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 158 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,797 calls (`stage2/rec/demo-cycle` 5,258, `stage1/d1` 1,539) |
| Called from | `MainLoop`, `PanelClose`, `TutorPanelFlash`, `TutorPanelPower`, `TutorNextRoom`, `BonusRoulette`, `WeaponPanel` |
| Calls | `PrintChar`, `ShardPaths` |
| Reads | `$5B60`-`$5B61` (`Temp1`); `$EB00`-`$FFFD` (`BackBuffer`, `work space $FFFA+`) |
| Writes | `$4061`-`$57FE` (screen); `$5B60`-`$5B61` (`Temp1`) |

#### `PrintTextHL` (`$9DD4`)

**Print the text record at HL (PrintText)**

As REX 1's PrintTextHL `$A2DF` (src/game/hud.asm).

Witness: L1 220 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 62 calls (`stage2/rec/demo-cycle` 50, `stage1/d1` 12) |
| Called from | `PrintBoxed`, `DrawHud` |
| Calls | `PrintText` |

#### `PrintChar` (`$9DDE`)

**Print character A at column Temp2, line Temp3 (pixels) from Font `$6338` through ScreenLineTable `$AC8E`**

As REX 1's PrintChar `$A2E9` (src/game/hud.asm).

Witness: L1 3892 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 86,416 t-states own (0.01 %) |
| Runs (the other recordings) | 3,892 calls (`stage2/rec/demo-cycle` 3,087, `stage1/d1` 805) |
| Called from | `BufferToScreen`, `PrintText` |
| Reads | `$5B64` (`Temp3`); `$9D44`-`$9D7D` (`HudTexts+3`); `$A3D5`-`$AC84` (`BonusTexts+3`, `TutorTexts`) |
| Writes | `$F3B6`-`$F7D7` (`BackBuffer+2230`); `$F92B`-`$FB2E` (`BackBuffer+3627`); `$FB4C`-`$FB8E` (`BackBuffer+4172`); `$FBAC`-`$FBAE` (`BackBuffer+4268`); `$FBCC`-`$FBCE` (`BackBuffer+4300`); `$FBEC`-`$FBEE` (`BackBuffer+4332`); 2 more ranges |

#### `PrintText` (`$9DFC`)

**Print a text record: [attribute][column][line] characters, 0 ends; the attributes set**

As REX 1's PrintText `$A307` (src/game/hud.asm).

Witness: L1 244 (d1, demo-cycle).

[Animation: `PrintText` at work](img/routines/PrintText.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,467 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,040,632 t-states own (0.21 %) |
| Runs (the other recordings) | 244 calls (`stage2/rec/demo-cycle` 194, `stage1/d1` 50) |
| Called from | `CellsUnderRex`, `PrintTextHL`, `BonusRoulette` |
| Calls | `PrintChar` |
| Reads | `$5B60`-`$5B64` (`Temp1`, `Temp2`, `Temp3`); `$6338`-`$6377` (`Font`); `$63B8`-`$640F` (`Font+128`); `$6438`-`$6537` (`Font+256`); `$9D41`-`$9D7E` (`HudTexts`); `$9F0C`-`$9F4F` (`ToDigits+36`, `DigitOf`); 13 more ranges |
| Writes | `$400C`-`$51B5` (screen); `$5203`-`$52B5` (screen); `$5303`-`$53B5` (screen); `$5403`-`$54B5` (screen); `$5503`-`$55B5` (screen); `$5603`-`$56B5` (screen); 17 more ranges |

#### `RandomLeftover` (`$9E5D`)

**Leftover: part 1's Random (a byte from the ROM at RandomSeed, the seed + 1); nothing calls it here**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 419 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `Random2` (`$9E6A`)

**A = a random byte from RandomSeed2 `$5B70` and R**

As REX 1's Random2 `$A388` (src/game/hud.asm).

Witness: L1 13700 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 184 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 13,700 calls (`stage2/rec/demo-cycle` 9,379, `stage1/d1` 4,321) |
| Called from | `DrawRex`, `TutorArrow`, `SparkleUpdate`, `SparkleDraw`, `MoveSparkShot`, `Kind11Shoot`, `Kind10Shoot`, `BlowUp`, `MineBurst`, `Climb`, `ScannerTurn`, `SetHop`, `SpawnRandom`, `BonusRoulette` |
| Calls | `PrintBoxed` (tail) |
| Reads | `$5B60`-`$5B70` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 3 more) |
| Writes | `$5B60`-`$5B70` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 3 more) |

#### `ClearScreen` (`$9E94`)

**Clear the screen's bitmap and attributes**

As REX 1's ClearScreen `$A3AE` (src/game/hud.asm).

Witness: L1 7 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,977 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 2) |
| Called from | `NewGame` |
| Calls | `ShardPaths` |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |

#### `PrintDigits` (`$9EAE`)

**Print B digits of Digits `$5B73` at HL on the screen**

As REX 1's PrintDigits `$A3C8` (src/game/hud.asm).

Witness: L1 552 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 552 calls (`stage2/rec/demo-cycle` 402, `stage1/d1` 150) |
| Called from | `ShowScore`, `ShowLives`, `ShowShield` |
| Calls | `ScreenDown`, `ShardPaths` |
| Reads | `$5B73`-`$5B77` (`Digits`); `$AC8E`-`$AC8F` (`ScreenLineTable`) |

#### `ScreenDown` (`$9EDF`)

**HL one pixel line down the screen**

As REX 1's ScreenDown `$A3F9` (src/game/hud.asm).

Witness: L1 1303 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,303 calls (`stage2/rec/demo-cycle` 969, `stage1/d1` 334) |
| Called from | `PrintDigits` |
| Reads | `$63B8`-`$6407` (`Font+128`) |
| Writes | `$400C`-`$4017` (screen); `$410C`-`$4117` (screen); `$420C`-`$4217` (screen); `$430C`-`$4317` (screen); `$440C`-`$4417` (screen); `$450C`-`$4517` (screen); 2 more ranges |

#### `ToDigits` (`$9EE8`)

**HL into five decimal digits at Digits `$5B73` (units first)**

As REX 1's ToDigits `$A402` (src/game/hud.asm).

Witness: L1 552 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 232 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 552 calls (`stage2/rec/demo-cycle` 402, `stage1/d1` 150) |
| Called from | `ShowScore`, `ShowLives`, `ShowShield` |
| Calls | `ShowWeaponIcons`, `DigitOf` |
| Writes | `$5B71`-`$5B77` (`DigitTemp`, `Digits`) |

#### `DigitOf` (`$9F2D`)

**One digit: count how many times DE goes into HL**

As REX 1's DigitOf `$A447` (src/game/hud.asm).

Witness: L1 2760 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,760 calls (`stage2/rec/demo-cycle` 2,010, `stage1/d1` 750) |
| Called from | `ToDigits` |
| Reads | `$5B71`-`$5B72` (`DigitTemp`) |
| Writes | `$5B71`-`$5B72` (`DigitTemp`) |

### DEMO: controls

`src/demo/controls.asm`

#### `TutorKeyFire` (`$9F50`)

**NZ unless the script presses fire (TutorInput bit 0); part 1's KeyFire**

Witness: L1 13080 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13,080 calls (`stage2/rec/demo-cycle` 10,078, `stage1/d1` 3,002) |
| Called from | `MainLoop` |
| Calls | `TutorRead` |
| Reads | `$5B60` (`Temp1`) |

#### `TutorKeyLeft` (`$9F59`)

**The script's left (bit 4)**

Witness: L1 6559 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 76,986 t-states own (0.01 %) |
| Runs (the other recordings) | 6,559 calls (`stage2/rec/demo-cycle` 5,058, `stage1/d1` 1,501) |
| Called from | `MainLoop`, `TutorPanelFlash`, `Scanner` |
| Calls | `TutorRead` |
| Reads | `$5B60` (`Temp1`); `$A019`-`$A01A` (`BufferAddress+16`); `$E379`-`$E380` (`RoomGridPlay+378`); `$E392`-`$E3A0` (`RoomGridPlay+403`); `$E3B2`-`$E3C6` (`RoomGridPlay+435`); `$E3D8`-`$E3E6` (`RoomGridPlay+473`); 4 more ranges |
| Writes | `$A07A` (`l_A045+53`) |

#### `TutorKeyRight` (`$9F62`)

**The script's right (bit 3)**

Witness: L1 6562 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,562 calls (`stage2/rec/demo-cycle` 5,061, `stage1/d1` 1,501) |
| Called from | `MainLoop`, `Scanner` |
| Calls | `TutorRead` |
| Reads | `$5B60` (`Temp1`) |

#### `TutorKeyUp` (`$9F6B`)

**The script's up (bit 1): the jump**

Witness: L1 6540 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 353 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,540 calls (`stage2/rec/demo-cycle` 5,039, `stage1/d1` 1,501) |
| Called from | `MainLoop` |
| Calls | `TutorRead` |
| Reads | `$5B60` (`Temp1`) |

#### `TutorKeyShield` (`$9F74`)

**The script's down (bit 2): the shield**

Witness: L1 13492 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13,492 calls (`stage2/rec/demo-cycle` 10,430, `stage1/d1` 3,062) |
| Called from | `MainLoop` |
| Calls | `PrintBoxed` (tail), `TutorRead` |
| Reads | `$5B60` (`Temp1`) |

#### `TutorRead` (`$9F7D`)

**TutorInput `$6079` into Temp1 (the key tests read it there)**

Witness: L1 46233 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 46,233 calls (`stage2/rec/demo-cycle` 35,666, `stage1/d1` 10,567) |
| Called from | `TutorKeyFire`, `TutorKeyLeft`, `TutorKeyRight`, `TutorKeyUp`, `TutorKeyShield` |
| Reads | `$6079` (`TutorInput`) |
| Writes | `$5B60` (`Temp1`) |

#### `TutorStep` (`$9F82`)

**Each pass: the script's count down; at 0 the next [input][count] pair; between pairs TutorInput `$FF` (nothing)**

Witness: L1 6746 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,746 calls (`stage2/rec/demo-cycle` 5,215, `stage1/d1` 1,531) |
| Called from | `MainLoop` |
| Reads | `$6080`-`$6082` (`TutorScriptPtr`, `TutorCount`); `$B058`-`$BAC3` (`TutorScript0+1`, `ClearBuffer`) |
| Writes | `$6079`-`$6082` (`TutorInput`, `TutorUnused`, `TutorScriptPtr`, `TutorCount`) |

#### `DemoPause` (`$9FAD`)

**SPACE: the sound off; wait for SPACE up, then down again; the sound on**

Witness: L1 1 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `MainLoop` |
| Calls | `SoundSilence` |
| Ports in | `$7FFE` |

#### `OrChar` (`$9FC8`)

**OR the 8 bytes at DE into the buffer at HL (32-byte rows)**

As REX 1's OrChar `$A4F4` (src/game/controls.asm).

Witness: L1 3024 (d1, demo-cycle).

[Animation: `OrChar` at work](img/routines/OrChar.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,024 calls (`stage2/rec/demo-cycle` 2,448, `stage1/d1` 576) |
| Called from | `DrawShard` |
| Reads | `$A392`-`$A3D1` (`ShardPictures`); `$EAFF`-`$EBDF` (`BufferPlayOrigin`, `BackBuffer`); `$EC06`-`$FFBF` (`BackBuffer+262`) |
| Writes | `$EAFF`-`$EBDF` (`BufferPlayOrigin`, `BackBuffer`); `$EC06`-`$FFBF` (`BackBuffer+262`) |

### DEMO: grid

`src/demo/grid.asm`

#### `CellPointer` (`$9FD7`)

**HL = the grid cell of SpriteX/SpriteY (`$E19F` + 32 x (Y / 8) + X / 8; A = 1 the grid from `$E19E`)**

As REX 1's CellPointer `$A503` (src/game/grid.asm).

Witness: L1 68024 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 68,024 calls (`stage2/rec/demo-cycle` 49,893, `stage1/d1` 18,131) |
| Called from | `MainLoop`, `StepShot`, `ScannerTurn`, `ObjectJump`, `ObjectCell`, `RexFall` |
| Reads | `$5B7C`-`$5B7D` (`SpriteX`, `SpriteY`) |

#### `BufferAddress` (`$A009`)

**HL = the back buffer address of SpriteX / SpriteY**

As REX 1's BufferAddress `$A535` (src/game/grid.asm).

Witness: L1 504 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 504 calls (`stage2/rec/demo-cycle` 408, `stage1/d1` 96) |
| Called from | `FlashCells` |
| Reads | `$5B7C`-`$5B7D` (`SpriteX`, `SpriteY`) |

#### `AnimateCells` (`$A032`)

**Every other pass: characters 252-255 from AnimFramesA `$AFAE` or AnimFramesB `$AFCE`, then AnimateCells2 and the two lists FramesChar68 `$A0E0`, FramesChar127 `$A0EE`**

Changed from REX 1's AnimateCells `$A55E` (src/game/grid.asm).

Witness: L1 6741 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,741 calls (`stage2/rec/demo-cycle` 5,211, `stage1/d1` 1,530) |
| Called from | `MainLoop` |
| Calls | `AnimateCells2`, `CopyFrame` (tail) |
| Reads | `$5EA0` (`PassToggle`); `$AFAE`-`$AFED` (`AnimFramesA`, `AnimFramesB`) |
| Writes | `$6E18`-`$6E37` (`AnimChar252`) |

#### `AnimateCells2` (`$A07B`)

**The frames of character 250 from FramesList2 `$A0D6`**

As REX 1's AnimateCells2 `$A5A7` (src/game/grid.asm).

Witness: L1 6741 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,741 calls (`stage2/rec/demo-cycle` 5,211, `stage1/d1` 1,530) |
| Called from | `AnimateCells` |
| Calls | `CopyFrame` (tail) |

#### `AnimateRestart` (`$A08B`)

**The restart marker's frames (character 249, FramesList3 `$A0C8`)**

As REX 1's AnimateRestart `$A5B7` (src/game/grid.asm).

Witness: L1 240 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 240 calls (`stage2/rec/demo-cycle` 196, `stage1/d1` 44) |
| Called from | `RestartMarker` |
| Calls | `CopyFrame` (falls into) |

#### `CopyFrame` (`$A098`)

**Copy the frame at HL into the character at DE (8 bytes), from the list position Temp1**

As REX 1's CopyFrame `$A5C4` (src/game/grid.asm).

Witness: L1 20463 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 149,908 t-states own (0.01 %) |
| Runs (the other recordings) | 20,463 calls (`stage2/rec/demo-cycle` 15,829, `stage1/d1` 4,634) |
| Called from | `CellsUnderRex`, `AnimateCells` (tail), `AnimateCells2` (tail), `AnimateRestart` (falls into), `TutorTexts` |
| Reads | `$582C`-`$5838` (screen); `$5B60`-`$5B63` (`Temp1`, `Temp2`); `$5EF2`-`$5EF4` (`AnimCount1`, `AnimCount2`, `AnimCount3`); `$6076` (`AnimCount4`); `$8584`-`$85E3` (`SpriteBonusPod+32`); `$889C`-`$88FB` (`SpriteJumper+32`); 3 more ranges |
| Writes | `$582B`-`$5838` (screen); `$5B60`-`$5B63` (`Temp1`, `Temp2`); `$5EF2`-`$5EF4` (`AnimCount1`, `AnimCount2`, `AnimCount3`); `$6076` (`AnimCount4`); `$6858`-`$685F` (`AnimChar68`); `$6A30`-`$6A37` (`AnimChar127`); 3 more ranges |

#### `InitDrones` (`$A0FC`)

**The drones' table at `$5E50`: 8 records of 3 bytes, the angles 0, 8, 16, ... 56**

As REX 1's InitDrones `$A628` (src/game/grid.asm).

Witness: L1 87 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 87 calls (`stage2/rec/demo-cycle` 70, `stage1/d1` 17) |
| Called from | `NewGame`, `TutorPowerUp`, `TutorPower5`, `PowerGain` |
| Writes | `$5E85`-`$5E9A` |

#### `UpdateDrones` (`$A10D`)

**The multiple weapon (Weapon 3): the drones orbit Rex (DroneOrbit `$A19F`) and are drawn (their pictures at `$A21F`), one per power level**

Changed from REX 1's UpdateDrones `$A639` (src/game/grid.asm).

Witness: L1 6753 (d1, demo-cycle).

[Animation: `UpdateDrones` at work](img/routines/UpdateDrones.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 38,846 t-states own (0.00 %) |
| Runs (the other recordings) | 6,753 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,533) |
| Called from | `MainLoop`, `CellsUnderRex`, `HudSweep`, `DrawBombIcons`, `DrawHudIcon`, `HudIconParams`, `TutorTexts`, `DrawCharBlock`, `WorkSpace` |
| Calls | `DrawRoomChar` |
| Reads | `$5B83`-`$5B84` (`RexX`, `RexY`); `$5E83`-`$5E9D` (`FireLatch`, `Weapon`, `PowerLevel`); `$5EDE`-`$5EE9` (`Dying`, `DeathTimer`, `DeathShardPtr`, `RestartX` and 7 more); `$A093`-`$A095` (`AnimateRestart+8`); `$A19F`-`$A25E` (`DroneOrbit`, `DronePictures`); `$AAAF`-`$AB40` (`TutorIntro+37`, `TutorPrologue`); 11 more ranges |
| Writes | `$5E83`-`$5E9A`; `$A065`-`$A067` (`l_A045+32`); `$A093`-`$A095` (`AnimateRestart+8`); `$F145`-`$F148` (`BackBuffer+1605`); `$F165`-`$F168` (`BackBuffer+1637`); `$F184`-`$F1C9` (`BackBuffer+1668`); 5 more ranges |

#### `RollCharUp` (`$A27D`)

**Roll an 8-byte character at HL one line up (the first line goes last): the conveyor characters**

As REX 1's RollCharUp `$A7A9` (src/game/grid.asm).

Witness: L1 6741 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 69,334,164 t-states own (4.78 %) |
| Runs (the other recordings) | 6,741 calls (`stage2/rec/demo-cycle` 5,211, `stage1/d1` 1,530) |
| Called from | `MainLoop`, `CellsUnderRex`, `TutorTexts` |
| Reads | `$6690`-`$6697` (`AnimChar11`); `$A093`-`$A094` (`AnimateRestart+8`); `$EB00`-`$FFFD` (`BackBuffer`, `work space $FFFA+`) |
| Writes | `$4061`-`$57FE` (screen); `$6690`-`$6697` (`AnimChar11`); `$A093`-`$A094` (`AnimateRestart+8`) |

#### `RollCharDown` (`$A28E`)

**Roll an 8-byte character at HL one line down**

As REX 1's RollCharDown `$A7BA` (src/game/grid.asm).

Witness: L1 13482 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 710 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 13,482 calls (`stage2/rec/demo-cycle` 10,422, `stage1/d1` 3,060) |
| Called from | `MainLoop` |
| Reads | `$6708`-`$671F` (`AnimChar26`, `AnimChar28`) |
| Writes | `$6708`-`$671F` (`AnimChar26`, `AnimChar28`) |

### DEMO: weapons

`src/demo/weapons.asm`

#### `GiveDoubleFire` (`$A25F`)

**The double fire station: HasDoubleFire `$5ED9` = 1, then GiveWeapon**

As REX 1's GiveDoubleFire `$A78B` (src/game/weapons.asm).

Witness: L1 103 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 103 calls (`stage2/rec/demo-cycle` 58, `stage1/d1` 45) |
| Called from | `CellsUnderRex` |
| Calls | `GiveWeapon` (tail) |

#### `GiveLaser` (`$A265`)

**The laser station: HasLaser `$5EDA` = 1**

As REX 1's GiveLaser `$A791` (src/game/weapons.asm).

Witness: L1 76 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 76 calls (`stage2/rec/demo-cycle` 43, `stage1/d1` 33) |
| Called from | `CellsUnderRex` |
| Calls | `GiveWeapon` (tail) |

#### `GiveMultiple` (`$A26B`)

**The multiple station: HasMultiple `$5EDB` = 1**

As REX 1's GiveMultiple `$A797` (src/game/weapons.asm).

Witness: L1 30 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 30 calls (`stage2/rec/demo-cycle` 30) |
| Called from | `CellsUnderRex` |
| Calls | `GiveWeapon` (tail) |

#### `GiveSpray` (`$A271`)

**The spray station: HasSpray = 1, then GiveWeapon**

Changed from REX 1's GiveSpray `$A79D` (src/game/weapons.asm).

Witness: L1 35 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 35 calls (`stage2/rec/demo-cycle` 35) |
| Called from | `CellsUnderRex` |
| Calls | `GiveWeapon` (falls into) |

#### `GiveWeapon` (`$A274`)

**The weapon flag at HL = 1, the icons shown (ShowWeaponIcons), the best weapon chosen (BestWeapon)**

Changed from REX 1's GiveWeapon `$A7A0` (src/game/weapons.asm).

Witness: L1 244 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 244 calls (`stage2/rec/demo-cycle` 166, `stage1/d1` 78) |
| Called from | `GiveDoubleFire` (tail), `GiveLaser` (tail), `GiveMultiple` (tail), `GiveSpray` (falls into) |
| Calls | `ShowWeaponIcons`, `BestWeapon` |
| Writes | `$5ED9`-`$5EDC` (`HasDoubleFire`, `HasLaser`, `HasMultiple`, `HasSpray`) |

#### `FireWeapon` (`$BC31`)

**Fire: a shot of the current weapon if a slot is free (once a press, only while Rex is present)**

As REX 1's FireWeapon `$B372` (src/game/weapons.asm).

Witness: L1 575 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 30,774 t-states own (0.00 %) |
| Runs (the other recordings) | 575 calls (`stage2/rec/demo-cycle` 434, `stage1/d1` 141) |
| Called from | `MainLoop`, `DrawSprite` (tail) |
| Calls | `ShardPaths`, `TutorScript0`, `DrawSprite` (tail), `FireDouble` (tail), `FireLaser` (tail), `FindShotSlot`, `RexShot`, `SetupShot` |
| Reads | `$5B83`-`$5BB3` (`RexX`, `RexY`, `Room`, `RoomColumn` and 10 more); `$5BD1`; `$5BFE`; `$5C3A`-`$5C49`; `$5C94`-`$5CA3`; `$5CFD`; 5 more ranges |
| Writes | `$5B60`-`$5B66` (`Temp1`, `Temp2`, `Temp3`, `Temp4`); `$5B99`-`$5D79`; `$5E77`; `$5E9B`-`$5EA7` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 5 more); `$5ECA` (`RapidShotsLeft`); `$A093`-`$A097` (`AnimateRestart+8`) |

#### `FireDouble` (`$BCC4`)

**Double fire's second shot**

As REX 1's FireDouble `$B40C` (src/game/weapons.asm).

Witness: L1 76 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 701 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/d1` 12) |
| Called from | `FireWeapon` (tail) |
| Calls | `FindShotSlot`, `SetupShot` |
| Reads | `$5E67`; `$5E9C` (`Weapon`) |
| Writes | `$5B66` (`Temp4`); `$5D45`-`$5D54`; `$5D72`-`$5D90`; `$A093`-`$A099` (`AnimateRestart+8`, `CopyFrame`) |

#### `FireLaser` (`$BCD5`)

**The laser's beam**

As REX 1's FireLaser `$B41D` (src/game/weapons.asm).

Witness: L1 35 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 6 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 141,360 t-states own (0.01 %) |
| Runs (the other recordings) | 17 calls (`stage1/d1` 17) |
| Called from | `DrawSprite` (tail), `FireWeapon` (tail) |
| Calls | `TutorScript0`, `RexShot` |
| Reads | `$5B95`-`$5BB3`; `$5BD1`; `$5BFE`; `$5C3A`-`$5C49`; `$5C94`-`$5CA3`; `$5CFD`; 6 more ranges |
| Writes | `$5B9A`-`$5BC1`; `$5BD6`-`$5BDF`; `$5C03`-`$5C0C`; `$5C3F`-`$5C57`; `$5C99`-`$5CB1`; `$5D02`-`$5D0B`; 5 more ranges |

#### `FireSpray` (`$BCEE`)

**The spray: at power 1-3 a fan of 3, 5 or 7 shots ahead (from `$BDB3`); at power 4 the four directions, at 5-6 all eight**

Witness: L1 58 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 60,841 t-states own (0.00 %) |
| Runs (the other recordings) | 58 runs of its first instruction, entered by a jump (`stage2/rec/demo-cycle` 58) |
| Called from | `DrawSprite` (tail) |
| Calls | `ShardPaths`, `TutorScript0`, `DrawSprite` (tail), `SetShotSpeed`, `FindShotSlot`, `FindSlot`, `FindEnemySlot`, `EnemyShot`, `RexShot`, `MoveBullets`, `SpawnScripted`, `SpawnRandom` |
| Reads | `$5E66`-`$5EDB` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 40 more); `$A093`-`$A096` (`AnimateRestart+8`) |
| Writes | `$5E67`-`$5ED9` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 38 more); `$A0AF`-`$A0B0` (`CopyFrameNext+10`) |

#### `SetShotSpeed` (`$BE09`)

**A shot's speed A into its record (dY x 32 added to the grid step)**

As REX 1's SetShotSpeed `$B4EA` (src/game/weapons.asm).

Witness: L1 2318 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,318 calls (`stage2/rec/demo-cycle` 1,620, `stage1/d1` 698) |
| Called from | `FireSpray`, `SwingShotSet`, `MineBurst` |
| Calls | `DrawSprite` (tail) |
| Reads | `$5BAB`-`$5D41`; `$5D5E`-`$5E40` |
| Writes | `$5BA9`-`$5D41`; `$5D5C`-`$5E40` |

#### `FindShotSlot` (`$BE25`)

**IY = a free slot among Rex's bullets (as many as the power level allows for the gun and double fire); none: IY = `$03E8`**

As REX 1's FindShotSlot `$B506` (src/game/weapons.asm).

Witness: L1 1157 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,157 calls (`stage2/rec/demo-cycle` 953, `stage1/d1` 204) |
| Called from | `FireWeapon`, `FireDouble`, `FireSpray`, `MoveSplitShot` |
| Calls | `DrawSprite` (tail), `FindSlot` (falls into) |
| Reads | `$5E9C`-`$5E9D` (`Weapon`, `PowerLevel`) |
| Writes | `$6075` (`ShotSide`) |

#### `FindSlot` (`$BE47`)

**Search E slots from IY for a free one; the shot's sound by weapon (gun `$D967`, laser `$D979`, spray `$D982`; the enemies' `$D970`)**

As REX 1's FindSlot `$B528` (src/game/weapons.asm).

Witness: L1 4507 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 2,261 t-states own (0.00 %) |
| Runs (the other recordings) | 4,507 calls (`stage2/rec/demo-cycle` 3,173, `stage1/d1` 1,334) |
| Called from | `FireSpray`, `FindShotSlot` (falls into), `FindEnemySlot` (tail) |
| Calls | `LaserSound`, `SpraySound`, `EnemyShotSound` (tail), `StartSfx` |
| Reads | `$5B9B`-`$5D3F`; `$5D5D`-`$5E3E`; `$5E7E`; `$5E96`-`$5E9C` (`FireLatch`, `Weapon`); `$6075` (`ShotSide`) |
| Writes | `$5D26`-`$5D71`; `$5D8F`-`$5D9E`; `$A093` (`AnimateRestart+8`) |

#### `LaserSound` (`$BE79`)

**DE = the laser's sound `$D979`**

As REX 1's LaserSound `$B55A` (src/game/weapons.asm).

Witness: L1 142 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 20 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 142 calls (`stage2/rec/demo-cycle` 75, `stage1/d1` 67) |
| Called from | `FindSlot` |

#### `SpraySound` (`$BE7D`)

**DE = the spray's sound `$D982`**

As REX 1's SpraySound `$B55E` (src/game/weapons.asm).

Witness: L1 272 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 272 calls (`stage2/rec/demo-cycle` 272) |
| Called from | `FindSlot` |
| Calls | `TutorScript0` |

#### `EnemyShotSound` (`$BE81`)

**The enemies' shot sound `$D970`, if channel C (the third, Channels+`$10`) is free**

As REX 1's EnemyShotSound `$B562` (src/game/weapons.asm).

Witness: L1 3350 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 5,186 t-states own (0.00 %) |
| Runs (the other recordings) | 3,350 calls (`stage2/rec/demo-cycle` 2,220, `stage1/d1` 1,130) |
| Called from | `FindSlot` (tail), `EnemyShot` (tail), `RexShot` (tail) |
| Calls | `StartSfx` |
| Reads | `$DA46` (`Channels+16`) |
| Writes | `$5D27`-`$5DA2` |

#### `FindEnemySlot` (`$BE8F`)

**IY = a free slot among the enemies' 20 bullets**

As REX 1's FindEnemySlot `$B570` (src/game/weapons.asm).

Witness: L1 3350 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 51 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,842 t-states own (0.00 %) |
| Runs (the other recordings) | 3,350 calls (`stage2/rec/demo-cycle` 2,220, `stage1/d1` 1,130) |
| Called from | `FireSpray`, `Kind11Shoot`, `Kind10Shoot`, `SwingGun`, `MineBurst` |
| Calls | `TutorScript0`, `FindSlot` (tail) |
| Reads | `$5EAE` |
| Writes | `$5D26`-`$5D53`; `$5D8F`; `$6075` (`ShotSide`); `$A093` (`AnimateRestart+8`) |

#### `EnemyShotFrom` (`$BE9D`)

**An enemy shot from IX's X - 16**

As REX 1's EnemyShotFrom `$B57E` (src/game/weapons.asm).

Witness: L1 1069 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,069 calls (`stage2/rec/demo-cycle` 720, `stage1/d1` 349) |
| Called from | `SwingShotUpLeft`, `SwingShotLeft`, `MineBurst` |
| Calls | `TutorScript0`, `EnemyShotA` (tail) |
| Reads | `$5EF6` (`ObjectTable`); `$5F80` |

#### `EnemyShotFromX` (`$BEA5`)

**LD A,(IX+0) then into EnemyShotA: no instruction reaches these 3 bytes (leftover, as REX 1's `$B586`)**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EnemyShotA` (`$BEA8`)

**An enemy shot at X A, its Y 15 below the object's**

As REX 1's EnemyShotA `$B589` (src/game/weapons.asm).

Witness: L1 2092 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,092 calls (`stage2/rec/demo-cycle` 1,394, `stage1/d1` 698) |
| Called from | `EnemyShotFrom` (tail), `SwingShotRight`, `SwingShotUpRight` |
| Calls | `EnemyShot` (falls into) |
| Writes | `$5B60` (`Temp1`) |

#### `EnemyShot` (`$BEAD`)

**An enemy shot from IX: X Temp1, Y IX+1 plus A (Temp4, the Y offset SetupShot adds), kind EnemyShotKind `$5EDD` (bit 7: an enemy's)**

As REX 1's EnemyShot `$B58E` (src/game/weapons.asm).

Witness: L1 2420 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,978 t-states own (0.00 %) |
| Runs (the other recordings) | 2,420 calls (`stage2/rec/demo-cycle` 1,607, `stage1/d1` 813) |
| Called from | `FireSpray`, `EnemyShotA` (falls into), `Kind11Shoot` |
| Calls | `TutorScript0`, `EnemyShotSound` (tail), `SetupShot` (tail) |
| Reads | `$5E7E`; `$5EDD` (`EnemyShotKind`); `$5EF7`-`$5EF8`; `$5F0E`-`$5F0F`; `$5F53`-`$5F54`; `$5F6A`-`$5F6B`; 1 more ranges |
| Writes | `$5B62`-`$5B66` (`Temp2`, `Temp3`, `Temp4`); `$5D26`; `$5D44`-`$5D80`; `$5D9E`; `$A093` (`AnimateRestart+8`) |

#### `RexShot` (`$BEC4`)

**A shot from Rex: his X, Y + 17 (Temp4) and facing, type the weapon**

As REX 1's RexShot `$B5A5` (src/game/weapons.asm).

Witness: L1 718 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 187,334 t-states own (0.01 %) |
| Runs (the other recordings) | 718 calls (`stage2/rec/demo-cycle` 610, `stage1/d1` 108) |
| Called from | `DrawSprite`, `FireWeapon`, `FireLaser`, `FireSpray` |
| Calls | `EnemyShotSound` (tail), `SetupShot` (falls into) |
| Reads | `$5B83`-`$5B88` (`RexX`, `RexY`, `Room`, `RoomColumn` and 1 more); `$5E6C`-`$5EA9` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 6 more); `$5ECC`-`$5ED9` (`SpawnTimer`, `SpawnPeriod`, `ScriptSpawnStep`, `ScriptSpawnTimer` and 7 more); `$BF5C`-`$BF65` (`ShotPointer+33`, `MoveEnemyBullets`) |
| Writes | `$5B60`-`$5B66` (`Temp1`, `Temp2`, `Temp3`, `Temp4`); `$5E6A`-`$5EA7` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 5 more); `$5ECA`-`$5ED7` (`RapidShotsLeft`, `FadeStepIndex`, `SpawnTimer`, `SpawnPeriod` and 7 more) |

#### `SetupShot` (`$BEE0`)

**Fill the slot at IY: live, type A, Y Temp2 + Temp4, X Temp1 + 16, direction Temp3 (left: dX -1, -8 pixels), the grid pointer**

As REX 1's SetupShot `$B5C1` (src/game/weapons.asm).

Witness: L1 3825 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 571 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3,825 calls (`stage2/rec/demo-cycle` 2,724, `stage1/d1` 1,101) |
| Called from | `FireWeapon`, `FireDouble`, `EnemyShot` (tail), `RexShot` (falls into), `MoveSplitShot`, `Kind10Shot` |
| Reads | `$5B60`-`$5B66` (`Temp1`, `Temp2`, `Temp3`, `Temp4`); `$5B95`-`$5D3A`; `$5D57`-`$5E39` |
| Writes | `$5B95`-`$5D44`; `$5D57`-`$5E43` |

#### `MoveEnemyBullets` (`$BF5D`)

**Move the enemies' 20 bullets**

As REX 1's MoveEnemyBullets `$B645` (src/game/weapons.asm).

Witness: L1 6753 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,753 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,533) |
| Called from | `MainLoop` |
| Calls | `MoveShots` (tail) |

#### `MoveBullets` (`$BF66`)

**Move Rex's 30 bullets (falls into MoveShots)**

As REX 1's MoveBullets `$B64E` (src/game/weapons.asm).

Witness: L1 6753 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 768 calls, 419,171 t-states own (0.03 %) |
| Runs (the other recordings) | 6,753 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,533) |
| Called from | `MainLoop`, `FireSpray` |
| Calls | `MoveShots` (falls into) |
| Reads | `$5E66`-`$5E69`; `$5E7E`-`$5E81`; `$5E96`-`$5E99`; `$5EAE`-`$5EB1` (`BoxX`); `$5EC6`-`$5EC9` (`Score`, `RapidShotsOn`); `$A093` (`AnimateRestart+8`); 2 more ranges |
| Writes | `$A093` (`AnimateRestart+8`); `$A0AF`-`$A0B0` (`CopyFrameNext+10`) |
| Ports out | `$00FE`, `$10FE`, `$18FE`, `$30FE`, `$38FE`, `$48FE`, `$50FE`, `$68FE`, `$70FE`, `$88FE`, `$A8FE`, `$B8FE`, `$C0FE`, `$D8FE`, `$E0FE`, `$F8FE` |

#### `MoveShots` (`$BF6C`)

**Move B bullets from IX: by state (live, hit flash 2 and 3) and type (gun, beam, spray dot, enemy shot, bouncing, drone shot)**

As REX 1's MoveShots `$B654` (src/game/weapons.asm).

Witness: L1 337650 (d1, demo-cycle).

[Animation: `MoveShots` at work](img/routines/MoveShots.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 768 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 337,650 calls (`stage2/rec/demo-cycle` 261,000, `stage1/d1` 76,650) |
| Called from | `MoveEnemyBullets` (tail), `MoveBullets` (falls into), `NextShot` (tail) |
| Calls | `NextShot` (tail), `ShotFlash1` (tail), `ShotFlash2` (tail), `MoveBeam` (tail), `DrawShotDot` (tail), `DrawShotByte` (tail), `MoveSplitShot` (tail), `MoveSparkShot` (tail) |
| Reads | `$5B97`-`$5E7A` |

#### `StepShot` (`$BFAA`)

**Move a bullet one step; off the play area it ends; a damaging cell (4, 5, 6) is hit; a solid cell stops it**

As REX 1's StepShot `$B692` (src/game/weapons.asm).

Witness: L1 31589 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 768 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 111,893 t-states own (0.01 %) |
| Runs (the other recordings) | 31,589 calls (`stage2/rec/demo-cycle` 22,606, `stage1/d1` 8,983) |
| Called from | `DrawSprite`, `MoveBeam` (tail), `DrawShotDot` (tail), `DrawShotByte` (tail), `MoveSplitShot` (tail), `MoveSparkShot` (tail) |
| Calls | `CellPointer`, `TutorTexts`, `NextShot` (falls into), `EndShot` (tail), `BulletHitsCell` (tail), `ShotStopped` (tail), `IsPassable` |
| Reads | `$5B95`-`$5D44`; `$5D57`-`$5E43`; `$5E6F`-`$5E87`; `$5E9F` (`PowerBarPtr+1`); `$5EB0`-`$5EB7` (`BoxX`, `BoxY`, `BoxWidth`, `BoxHeight` and 3 more); `$5EC8`-`$5ECF` (`Score+1`, `RapidShotsOn`, `RapidShotsLeft`, `FadeStepIndex` and 4 more); 8 more ranges |
| Writes | `$5B7C`-`$5B7D` (`SpriteX`, `SpriteY`); `$5B95`-`$5D3C`; `$5D57`-`$5E3B` |

#### `NextShot` (`$C00E`)

**The next bullet record (15 bytes on)**

As REX 1's NextShot `$B6F6` (src/game/weapons.asm).

Witness: L1 337650 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 400 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 337,650 calls (`stage2/rec/demo-cycle` 261,000, `stage1/d1` 76,650) |
| Called from | `MoveShots` (tail), `StepShot` (falls into), `EndShot` (tail), `ShotStopped` (tail), `ShotFlash1` (tail), `ShotFlash2` (tail) |
| Calls | `MoveShots` (tail) |

#### `EndShot` (`$C018`)

**The bullet ends (live = 0)**

As REX 1's EndShot `$B700` (src/game/weapons.asm).

Witness: L1 617 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 400 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 617 calls (`stage2/rec/demo-cycle` 478, `stage1/d1` 139) |
| Called from | `StepShot` (tail) |
| Calls | `NextShot` (tail) |
| Writes | `$5B9B`-`$5CF4`; `$5D12`-`$5D3F`; `$5D5D`-`$5E20` |

#### `BulletHitsCell` (`$C01F`)

**A bullet hits a cell 4, 5 or 6: the cell's character one step on (its record in SceneryCellList), its attribute (`$47` for a 6), the cell emptied unless 4 or 5**

Witness: L1 37 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 400 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 37 calls (`stage2/rec/demo-cycle` 37) |
| Called from | `StepShot` (tail) |
| Calls | `ShotStopped` (falls into), `BlowUp` (tail) |
| Reads | `$5B60`-`$5B64` (`Temp1`, `Temp2`, `Temp3`); `$5BA0`-`$5C09`; `$6EC2`-`$6EE4` (`CharAttrs+138`); `$DEE4`-`$DF01` (`CellIndexMap+69`); `$DF44`-`$DF61` (`CellIndexMap+165`); `$E0D6`-`$E0DA` (`CellIndexMap+567`); 3 more ranges |
| Writes | `$5A37`-`$5A3B` (screen); `$5A59`-`$5A5A` (screen); `$5A79`-`$5A7B` (screen); `$5A99`-`$5A9B` (screen); `$5B60`-`$5B64` (`Temp1`, `Temp2`, `Temp3`); `$DEE2`-`$DF01` (`CellIndexMap+67`); 9 more ranges |

#### `ShotStopped` (`$C0AC`)

**A bullet meets a wall: a small flash (state 2) unless it is the laser, the hit sound `$D98B`**

As REX 1's ShotStopped `$B794` (src/game/weapons.asm).

Witness: L1 2620 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,620 calls (`stage2/rec/demo-cycle` 1,824, `stage1/d1` 796) |
| Called from | `StepShot` (tail), `BulletHitsCell` (falls into) |
| Calls | `NextShot` (tail), `StartSfx` |
| Reads | `$5B97`-`$5D3C`; `$5D59`-`$5E3B`; `$5E9C` (`Weapon`); `$DA46` (`Channels+16`) |
| Writes | `$5B9B`-`$5D3F`; `$5D5D`-`$5E3E`; `$ECD1` (`BackBuffer+465`); `$ED90` (`BackBuffer+656`); `$EEE3` (`BackBuffer+995`); `$F00B`-`$F299` (`BackBuffer+1291`); 4 more ranges |

#### `ShotFlash1` (`$C0D5`)

**The flash's first frame: a cross of three bytes in the buffer**

As REX 1's ShotFlash1 `$B7BD` (src/game/weapons.asm).

Witness: L1 2859 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,859 calls (`stage2/rec/demo-cycle` 1,996, `stage1/d1` 863) |
| Called from | `MoveShots` (tail) |
| Calls | `NextShot` (tail) |
| Reads | `$5B97`-`$5D3C`; `$5D59`-`$5E3B` |
| Writes | `$5B9B`-`$5D3F`; `$5D5D`-`$5E3E`; `$ECB1` (`BackBuffer+433`); `$ECD1` (`BackBuffer+465`); `$ECF1` (`BackBuffer+497`); `$ED70` (`BackBuffer+624`); 8 more ranges |

#### `ShotFlash2` (`$C0F0`)

**The flash's second frame, then the bullet ends**

As REX 1's ShotFlash2 `$B7D8` (src/game/weapons.asm).

Witness: L1 2848 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,848 calls (`stage2/rec/demo-cycle` 1,989, `stage1/d1` 859) |
| Called from | `MoveShots` (tail) |
| Calls | `NextShot` (tail) |
| Reads | `$5B97`-`$5D3C`; `$5D59`-`$5E3B` |
| Writes | `$5B9B`-`$5D3F`; `$5D5D`-`$5E3E`; `$EC91` (`BackBuffer+401`); `$ECB1` (`BackBuffer+433`); `$ECD1` (`BackBuffer+465`); `$ECF1` (`BackBuffer+497`); 7 more ranges |

#### `MoveBeam` (`$C114`)

**The long beam (type 7): its frames from BeamPath `$A2A7`**

As REX 1's MoveBeam `$B7FC` (src/game/weapons.asm).

Witness: L1 5735 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,735 calls (`stage2/rec/demo-cycle` 3,739, `stage1/d1` 1,996) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5D57`-`$5E26`; `$829C`-`$82B3` (`SpriteLaserA`); `$87A4`-`$87BB` (`SpriteLaserB`); `$A2A7`-`$A2C3` (`BeamPath`) |
| Writes | `$5D59`-`$5E26`; `$F307`-`$F751` (`BackBuffer+2055`); `$F790`-`$FB0E` (`BackBuffer+3216`); `$FB8D`-`$FBF6` (`BackBuffer+4237`); `$FC8C`-`$FCEC` (`BackBuffer+4492`); `$FD8B`-`$FDEB` (`BackBuffer+4747`); 2 more ranges |

#### `DrawShotDot` (`$C17F`)

**Draw a type 4 bullet: a 4-line dot (Rex's or an enemy's shape)**

As REX 1's DrawShotDot `$B867` (src/game/weapons.asm).

Witness: L1 14210 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14,210 calls (`stage2/rec/demo-cycle` 10,823, `stage1/d1` 3,387) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5BA0`-`$5D44`; `$5D62`-`$5E43` |
| Writes | `$EAD5`-`$FFB7` (`ObjectBufferOrigin+214`, `BufferPlayOrigin`, `BackBuffer`); `$FFD2`-`$FFD7` (`BackBuffer+5330`); `$FFF2`-`$FFF7` (`BackBuffer+5362`) |

#### `DrawShotByte` (`$C1AB`)

**Draw a gun bullet: one byte by direction and side**

As REX 1's DrawShotByte `$B893` (src/game/weapons.asm).

Witness: L1 8688 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,688 calls (`stage2/rec/demo-cycle` 6,501, `stage1/d1` 2,187) |
| Called from | `MoveShots` (tail) |
| Calls | `StepShot` (tail) |
| Reads | `$5B99`-`$5D44`; `$5D5B`-`$5E07` |
| Writes | `$EE2E`-`$F029` (`BackBuffer+814`); `$F04C`-`$F05D` (`BackBuffer+1356`); `$F08C`-`$F093` (`BackBuffer+1420`); `$F105`-`$F108` (`BackBuffer+1541`); `$F188`-`$FBCA` (`BackBuffer+1672`); `$FBF5`-`$FCB4` (`BackBuffer+4341`) |

#### `MoveSplitShot` (`$C1C8`)

**A splitting shot (type 2): every few steps it fires a new shot from where it is**

As REX 1's MoveSplitShot `$B8BC` (src/game/weapons.asm).

Witness: L1 532 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 532 calls (`stage2/rec/demo-cycle` 272, `stage1/d1` 260) |
| Called from | `MoveShots` (tail) |
| Calls | `FindShotSlot`, `SetupShot`, `StepShot` (tail) |
| Reads | `$5B60` (`Temp1`); `$5B96`-`$5BA3`; `$5BB4`-`$5BC1`; `$5BD2`-`$5BDF`; `$5BFF`-`$5C0C`; `$5C3B`-`$5C57`; 4 more ranges |
| Writes | `$5B60`-`$5B66` (`Temp1`, `Temp2`, `Temp3`, `Temp4`); `$5B9B`-`$5D47` |

#### `MoveSparkShot` (`$C22C`)

**A spark (type 6): random dots by its count (SparkMasks `$C250`), it fades out**

As REX 1's MoveSparkShot `$B920` (src/game/weapons.asm).

Witness: L1 2424 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,424 calls (`stage2/rec/demo-cycle` 1,271, `stage1/d1` 1,153) |
| Called from | `MoveShots` (tail) |
| Calls | `Random2`, `StepShot` (tail) |
| Reads | `$5BB2`-`$5D47`; `$C251`-`$C268` (`SparkMasks+1`) |
| Writes | `$5BAA`-`$5D47`; `$F01A`-`$F01D` (`BackBuffer+1306`); `$F204`-`$F21B` (`BackBuffer+1796`); `$F321`-`$F338` (`BackBuffer+2081`); `$F384`-`$F3B8` (`BackBuffer+2180`); `$F523`-`$F53A` (`BackBuffer+2595`); 2 more ranges |

#### `PowerBar` (`$C278`)

**Draw the power bar: its end colour flashes by FadeStepIndex**

As REX 1's PowerBar `$B96B` (src/game/weapons.asm).

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop` |
| Calls | `PowerBarColour` (falls into) |
| Reads | `$5E9E`-`$5E9F` (`PowerBarPtr`); `$5ECB` (`FadeStepIndex`) |

#### `PowerBarColour` (`$C28B`)

**The 2 x 2 cells at HL in the colour PowerLevel + 2**

Changed from REX 1's PowerBarColour `$B97E` (src/game/weapons.asm).

Witness: L1 12910 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,910 calls (`stage2/rec/demo-cycle` 9,990, `stage1/d1` 2,920) |
| Called from | `PowerBar` (falls into) |
| Reads | `$5E9D` (`PowerLevel`) |
| Writes | `$5801`-`$580A` (screen); `$5821`-`$582A` (screen); `$E500`-`$E509` (`AttrShadow+1`); `$E520`-`$E529` (`HeatAttr+10`) |

#### `PowerGain` (`$C29B`)

**A power pod: PowerCount `$5EA1` counts, every 120 the PowerLevel + 1 up to 5 (at 5 GainRank raises WeaponRank and sets the level back to 1; at rank 5 nothing), the fire faster**

As REX 1's PowerGain `$B98E` (src/game/weapons.asm).

Witness: L1 474 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 474 calls (`stage2/rec/demo-cycle` 386, `stage1/d1` 88) |
| Called from | `PowerDrain`, `TakePowerPod` |
| Calls | `InitDrones`, `BestWeapon` (falls into) |
| Reads | `$5B60` (`Temp1`); `$5E9D`-`$5EA1` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`); `$6067` (`WeaponRank`) |
| Writes | `$5B60` (`Temp1`); `$5E9D`-`$5EA1` (`PowerLevel`, `PowerBarPtr`, `PassToggle`, `PowerCount`); `$5EF1` (`FireDelay`); `$6067` (`WeaponRank`) |

#### `BestWeapon` (`$C2E4`)

**Weapon = the best one held (WeaponRank `$6067`), WeaponIcon updated**

As REX 1's BestWeapon `$B9D7` (src/game/weapons.asm).

Witness: L1 262 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 262 calls (`stage2/rec/demo-cycle` 180, `stage1/d1` 82) |
| Called from | `GiveWeapon`, `PowerGain` (falls into) |
| Reads | `$5ED8`-`$5EDC` (`WeaponIcon`, `HasDoubleFire`, `HasLaser`, `HasMultiple` and 1 more); `$6067` (`WeaponRank`) |
| Writes | `$5E9C` (`Weapon`) |

#### `StartWeapon` (`$C2FC`)

**The gun at power 1, the bar at `$5801`, WeaponRank 0**

Witness: L1 7 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 2) |
| Called from | `NewGame` |
| Writes | `$5E9C`-`$5E9F` (`Weapon`, `PowerLevel`, `PowerBarPtr`); `$6067` (`WeaponRank`) |

### DEMO: render

`src/demo/render.asm`

#### `ClearBuffer` (`$BAC3`)

**Clear the back buffer's play lines `$EB00-$FFFF` with PUSH (the stack from `$FFFF` down)**

As REX 1's ClearBuffer `$B205` (src/game/render.asm).

Witness: L1 6764 (d1, demo-cycle).

[Animation: `ClearBuffer` at work](img/routines/ClearBuffer.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,764 calls (`stage2/rec/demo-cycle` 5,229, `stage1/d1` 1,535) |
| Called from | `MainLoop`, `TutorNextRoom` |
| Reads | `$5B60`-`$5B61` (`Temp1`) |
| Writes | `$5B60`-`$5B61` (`Temp1`) |

#### `DrawSprite` (`$BB16`)

**OR a picture into the back buffer: SpriteX/Y, SpriteWidth/Height (written into the loop at `$BB6A`, `$BB6E`; mirrored `$BBD7`, `$BBDB`); the picture is the word of the frame list HL for X & 7, or SpritePicture when bit 7 of SpriteMirror; A non-zero draws it mirrored (DrawMirrored)**

Changed from REX 1's DrawSprite `$B258` (src/game/render.asm).

Witness: L1 30606 (d1, demo-cycle).

[Animation: `DrawSprite` at work](img/routines/DrawSprite.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 2,131 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 604,306 t-states own (0.04 %) |
| Runs (the other recordings) | 30,606 calls (`stage2/rec/demo-cycle` 22,039, `stage1/d1` 8,567) |
| Called from | `DrawRex`, `TutorArrow`, `TutorScript0` (tail), `DrawAnimCells` (tail), `FireWeapon` (tail), `FireSpray` (tail), `SetShotSpeed` (tail), `FindShotSlot` (tail), `UpdateObject` |
| Calls | `TutorScript0` (tail), `DrawAnimCells` (tail), `FireWeapon` (tail), `FireLaser` (tail), `FireSpray` (tail), `RexShot`, `StepShot`, `BlowUp`, `SwingShotSet`, `AnimatePod`, `DrawShard`, `ObjectMove`, `PanelRow` |
| Reads | `$5B7C`-`$5B7F` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$5E6F`-`$5E87`; `$5E9F` (`PowerBarPtr+1`); `$5EB7`-`$5EBE` (`SpawnTop`, `SmartBombSteps`, `SmartBombOn`, `SmartBombPtr` and 2 more); `$5ECF` (`ScriptSpawnTimer`); `$5EE7` (`SparkleCount`); 12 more ranges |
| Writes | `$5B7C` (`SpriteX`); `$BB6A`-`$BB6E` (`DrawSpriteRows+1`, `DrawSpriteRow`, `DrawSpriteBytes`); `$BBD7`-`$BBDB` (`DrawMirroredRows+1`, `DrawMirroredRow`, `DrawMirroredBytes`); `$EA04`-`$FFF4` (`ObjectBufferOrigin+5`, `BufferPlayOrigin`, `BackBuffer`) |

#### `DrawAnimCells` (`$BBFD`)

**Draw every scenery cell of the room (SceneryCellList `$DBF6`) into the back buffer, the stack as the list pointer**

As REX 1's DrawAnimCells `$B33E` (src/game/render.asm).

Witness: L1 6764 (d1, demo-cycle).

[Animation: `DrawAnimCells` at work](img/routines/DrawAnimCells.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 7,146 t-states own (0.00 %) |
| Runs (the other recordings) | 6,764 calls (`stage2/rec/demo-cycle` 5,228, `stage1/d1` 1,536) |
| Called from | `MainLoop`, `DrawSprite` (tail) |
| Calls | `ShardPaths`, `TutorScript0`, `DrawSprite` (tail) |
| Reads | `$5B62`-`$5B63` (`Temp2`); `$5EAE`; `$5F26`; `$6660`-`$6667` (`CharGraphics+40`); `$66A0`-`$66B7` (`AnimChar11+16`); `$6710`-`$677F` (`AnimChar26+8`, `AnimChar28`); 2 more ranges |
| Writes | `$5B62`-`$5B63` (`Temp2`); `$5D27`-`$5D90`; `$5DAE`; `$5F28`; `$A054` (`l_A045+15`); `$A093` (`AnimateRestart+8`); 1 more ranges |

### DEMO: objects

`src/demo/objects.asm`

#### `UpdateObjects` (`$C311`)

**Update every object of the room (falls into UpdateObject)**

As REX 1's UpdateObjects `$BA5C` (src/game/objects.asm).

Witness: L1 6752 (d1, demo-cycle).

[Animation: `UpdateObjects` at work](img/routines/UpdateObjects.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,752 calls (`stage2/rec/demo-cycle` 5,219, `stage1/d1` 1,533) |
| Called from | `MainLoop` |
| Calls | `UpdateObject` (falls into) |
| Reads | `$5B90` (`ObjectCount`) |

#### `UpdateObject` (`$C319`)

**One object at IX (records of 23 bytes): skip a dead one; draw it (kinds 1 and 8 never mirrored); exploding BlowUp, kind 6 its turn, the power pod's frames; kinds 9, 10, 11 shoot; else jump, fall, the cell under it and the move; then against Rex (ObjectHitsRex)**

Changed from REX 1's UpdateObject `$BA64` (src/game/objects.asm).

Witness: L1 49655 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 49,655 calls (`stage2/rec/demo-cycle` 38,582, `stage1/d1` 11,073) |
| Called from | `UpdateObjects` (falls into), `NextObject` (tail) |
| Calls | `DrawSprite`, `ObjectBehaviour` (falls into), `NextObject` (tail), `RamTurn` (tail), `BlowUp` (tail) |
| Reads | `$5EF6`-`$5FA6` (`ObjectTable`); `$5FBA`; `$5FD1` |
| Writes | `$5B7C`-`$5B7F` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight`); `$5EBC`-`$5EBE` (`SpriteMirror`, `SpritePicture`) |

#### `ObjectBehaviour` (`$C374`)

**ObjectBehaviour**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15,092 calls (`stage2/rec/demo-cycle` 15,092) |
| Called from | `UpdateObject` (falls into), `RamTurn` (tail) |
| Calls | `Kind11Shoot` (tail), `Kind10Shoot` (tail), `SwingGun` (tail), `AnimatePod`, `ObjectMove`, `ObjectJump`, `ObjectFall`, `ObjectCell` |
| Reads | `$5EFF`; `$5F16`; `$5F2D`; `$5F44`; `$5F5B`; `$5F72`; 2 more ranges |

#### `ObjectCollide` (`$C39C`)

**ObjectHitsRex for the object at IX**

As REX 1's ObjectCollide `$BB66` (src/game/objects.asm).

Witness: L1 21382 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,500 calls (`stage2/rec/demo-cycle` 5,555, `stage1/d1` 2,945) |
| Called from | `Kind11Shoot` (tail), `Kind10Shoot` (tail), `SwingGun` (tail) |
| Calls | `ObjectHitsRex` |

#### `NextObject` (`$C39F`)

**The next object record (24 bytes on), until all are done**

As REX 1's NextObject `$BB69` (src/game/objects.asm).

Witness: L1 49655 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 28,273 calls (`stage2/rec/demo-cycle` 23,490, `stage1/d1` 4,783) |
| Called from | `UpdateObject` (tail), `BlowUp` (tail) |
| Calls | `UpdateObject` (tail) |

#### `Kind11Shoot` (`$C3AA`)

**Kind 11 (launcher): at random its timer down; at 0 a long shot (type 7, `$87`) up from its X**

Witness: L1 3180 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,180 calls (`stage2/rec/demo-cycle` 2,053, `stage1/d1` 1,127) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `Random2`, `FindEnemySlot`, `EnemyShot`, `ObjectCollide` (tail) |
| Reads | `$5F0D`; `$5F1E`-`$5F1F`; `$5F52`; `$5F63`-`$5F69`; `$5F7A`-`$5F7B` |
| Writes | `$5B60` (`Temp1`); `$5D62`-`$5E26`; `$5F1E`; `$5F63`; `$5F7A` |

#### `Kind10Shoot` (`$C3D7`)

**Kind 10 (shooters): at random its timer down; at 0 two shots, left and right (Kind10Shot)**

Witness: L1 2594 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,594 calls (`stage2/rec/demo-cycle` 1,707, `stage1/d1` 887) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `Random2`, `FindEnemySlot`, `ObjectCollide` (tail), `Kind10Shot` |
| Reads | `$5EF6` (`ObjectTable`); `$5F07`-`$5F0D`; `$5F1E`-`$5F24`; `$5F35`-`$5F36` |
| Writes | `$5B64` (`Temp3`); `$5F07`; `$5F1E`; `$5F35` |

#### `Kind10Shot` (`$C40B`)

**One enemy shot from (A, IX+1), speed 16 (SetupShot)**

Witness: L1 248 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 248 calls (`stage2/rec/demo-cycle` 164, `stage1/d1` 84) |
| Called from | `Kind10Shoot` |
| Calls | `SetupShot` |
| Reads | `$5EF7`; `$5F0E`; `$5F25` |
| Writes | `$5B60`-`$5B66` (`Temp1`, `Temp2`, `Temp3`, `Temp4`); `$5D5C`-`$5E01` |

#### `SwingGun` (`$C422`)

**Kind 9, the swing gun: its picture by angle (SwingGunFrames), at angles 0, 1, 3, 4, 5, 7 a shot that way, the next angle of 8; from `$C473` kind 6's turn**

Changed from REX 1's SwingGun `$BCDD` (src/game/objects.asm).

Witness: L1 2726 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,726 calls (`stage2/rec/demo-cycle` 1,795, `stage1/d1` 931) |
| Called from | `ObjectBehaviour` (tail) |
| Calls | `FindEnemySlot`, `ObjectCollide` (tail), `SwingShotUpLeft`, `SwingShotLeft`, `SwingShotRight`, `SwingShotUpRight` |
| Reads | `$5F07`; `$5F91`; `$C5E7`-`$C5EE` (`SwingGunFrames`) |
| Writes | `$5EDD` (`EnemyShotKind`); `$5EFA`-`$5F07`; `$5F84`-`$5F91` |

#### `RamTurn` (`$C473`)

**RamTurn**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 65 calls (`stage2/rec/demo-cycle` 65) |
| Called from | `UpdateObject` (tail) |
| Calls | `ObjectBehaviour` (tail) |
| Reads | `$5F07`; `$5F1E`; `$5F35` |
| Writes | `$5EFF`-`$5F35` |

#### `BlowUp` (`$C49A`)

**An exploding object (kind `$FF`): the six shards (ShardPaths `$A332-$A382`, DrawShard), the flash, the picture stepped; at the end the cells back and maybe a pod: a power pod `$FE` (SpritePodPower; a big one SpritePodBig), a bomb pod `$FD` or the bonus pod `$FC`**

Witness: L1 504 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 230,250 t-states own (0.02 %) |
| Runs (the other recordings) | 504 calls (`stage2/rec/demo-cycle` 408, `stage1/d1` 96) |
| Called from | `DrawSprite`, `BulletHitsCell` (tail), `UpdateObject` (tail) |
| Calls | `Random2`, `NextObject` (tail), `DrawShard`, `InitKind0`, `CopyCells3`, `FlashCells` |
| Reads | `$5B60`-`$5B63` (`Temp1`, `Temp2`); `$5E6F`-`$5E87`; `$5E9F`-`$5F95` (`PowerBarPtr+1`, `PassToggle`, `PowerCount`, `RexCellPtr` and 63 more); `$A01B`-`$A01C` (`BufferAddress+18`); `$E3DB`-`$E3DD` (`RoomGridPlay+476`); `$E3FA`-`$E3FC` (`RoomGridPlay+507`); 1 more ranges |
| Writes | `$5B7C`-`$5B7D` (`SpriteX`, `SpriteY`); `$5EAE`-`$5EB0`; `$5EC6`-`$5EC8` (`Score`); `$5EDE`-`$5EE0` (`Dying`, `DeathTimer`, `DeathShardPtr`); `$5EF6`-`$5F93` (`ObjectTable`) |

#### `SwingShotUpLeft` (`$C591`)

**The swing gun's shot left and up**

Changed from REX 1's SwingShotUpLeft `$BE5B` (src/game/objects.asm).

Witness: L1 342 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 22 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 342 calls (`stage2/rec/demo-cycle` 225, `stage1/d1` 117) |
| Called from | `SwingGun` |
| Calls | `ShardPaths`, `EnemyShotFrom`, `SwingShotSet` (tail) |
| Writes | `$5D5B`-`$5E1E` |

#### `SwingShotLeft` (`$C5A1`)

**The swing gun's shot left: dX -8, speed 8**

Witness: L1 679 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 679 calls (`stage2/rec/demo-cycle` 447, `stage1/d1` 232) |
| Called from | `SwingGun` |
| Calls | `EnemyShotFrom`, `SwingShotSet` (falls into) |
| Writes | `$5D5B`-`$5E2D` |

#### `SwingShotSet` (`$C5AE`)

**The shot's dX (HL) and speed**

As REX 1's SwingShotSet `$BE8C` (src/game/objects.asm).

Witness: L1 2044 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 98,123 t-states own (0.01 %) |
| Runs (the other recordings) | 2,044 calls (`stage2/rec/demo-cycle` 1,346, `stage1/d1` 698) |
| Called from | `DrawSprite`, `SwingShotUpLeft` (tail), `SwingShotLeft` (falls into), `SwingShotRight` (tail), `SwingShotUpRight` (tail) |
| Calls | `SetShotSpeed` |
| Reads | `$5E6F`-`$5E87`; `$5E9F` (`PowerBarPtr+1`); `$5EB7` (`SpawnTop`); `$5ECF`-`$5EE7` (`ScriptSpawnTimer`, `ScriptSpawnCount`, `ShieldOn`, `ShieldKeyLatch` and 17 more); `$5EFF`; `$5F17`; 1 more ranges |
| Writes | `$5D5C`-`$5E31` |

#### `SwingShotRight` (`$C5BD`)

**The swing gun's shot right**

Changed from REX 1's SwingShotRight `$BE9B` (src/game/objects.asm).

Witness: L1 683 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 22 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 683 calls (`stage2/rec/demo-cycle` 450, `stage1/d1` 233) |
| Called from | `SwingGun` |
| Calls | `EnemyShotA`, `SwingShotSet` (tail) |
| Reads | `$5EF6` (`ObjectTable`); `$5F80` |
| Writes | `$5D5B`-`$5E1E` |

#### `SwingShotUpRight` (`$C5D2`)

**The swing gun's shot right and up**

Changed from REX 1's SwingShotUpRight `$BEB3` (src/game/objects.asm).

Witness: L1 340 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 340 calls (`stage2/rec/demo-cycle` 224, `stage1/d1` 116) |
| Called from | `SwingGun` |
| Calls | `EnemyShotA`, `SwingShotSet` (tail) |
| Reads | `$5EF6` (`ObjectTable`); `$5F80` |
| Writes | `$5D5B`-`$5DC4`; `$5DE2` |

#### `AnimatePod` (`$C5EF`)

**The power pod's frames (PodFrames `$C677`); a pod not taken in time goes**

As REX 1's AnimatePod `$BED3` (src/game/objects.asm).

Witness: L1 3330 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 22 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 94,800 t-states own (0.01 %) |
| Runs (the other recordings) | 3,330 calls (`stage2/rec/demo-cycle` 2,478, `stage1/d1` 852) |
| Called from | `DrawSprite`, `ObjectBehaviour` |
| Reads | `$5E6F`-`$5E87`; `$5E9F` (`PowerBarPtr+1`); `$5EB1`-`$5EB7` (`BoxX`, `BoxY`, `BoxWidth`, `BoxHeight` and 3 more); `$5EC9`-`$5ECF` (`RapidShotsOn`, `RapidShotsLeft`, `FadeStepIndex`, `SpawnTimer` and 3 more); `$5EE1`-`$5EE7` (`DeathShardPtr+1`, `RestartX`, `RestartY`, `RestartRoom` and 3 more); `$5EF9`-`$5F93`; 1 more ranges |
| Writes | `$5EFA`-`$5F91` |

#### `DrawShard` (`$C682`)

**One shard of an explosion: its path step (HL + 2 x IX+3) from the object's place, clipped to the play area, its 4-byte picture from ShardPictures `$A392` ORed into the buffer (OrChar)**

Witness: L1 3024 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 327,397 t-states own (0.02 %) |
| Runs (the other recordings) | 3,024 calls (`stage2/rec/demo-cycle` 2,448, `stage1/d1` 576) |
| Called from | `DrawSprite`, `BlowUp` |
| Calls | `OrChar`, `ObjectMove`, `InitKind6` |
| Reads | `$5B60` (`Temp1`); `$5B7C` (`SpriteX`); `$5E67`-`$5F3E` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 66 more); `$5F52`-`$5F55`; `$5F69`-`$5F6C`; `$5F80`-`$5F83`; 9 more ranges |
| Writes | `$5B60` (`Temp1`); `$5B7C`-`$5B7D` (`SpriteX`, `SpriteY`); `$5E67`-`$5E84`; `$5E97`-`$5E9C` (`FireLatch`, `Weapon`); `$5EAF`-`$5EB4` (`BoxX`, `BoxY`, `BoxWidth`, `BoxHeight`); `$5EC7`-`$5ECC` (`Score`, `RapidShotsOn`, `RapidShotsLeft`, `FadeStepIndex` and 1 more); 4 more ranges |

#### `ObjectMove` (`$C703`)

**The kinds' moves: pods none; 8 the scanner, 12/13 GroundWalker; 2 turns to face Rex; the others walk right or left**

Witness: L1 12882 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 292,908 t-states own (0.02 %) |
| Runs (the other recordings) | 12,882 calls (`stage2/rec/demo-cycle` 9,537, `stage1/d1` 3,345) |
| Called from | `DrawSprite`, `ObjectBehaviour`, `DrawShard` |
| Calls | `TutorTexts`, `GroundWalker` (tail), `Scanner` (tail), `WalkRight` (tail), `WalkLeft` (tail) |
| Reads | `$5E66`-`$5E80`; `$5E96`-`$5E98`; `$5EAE`-`$5EB0`; `$5EC6`-`$5EC8` (`Score`); `$5EDE`-`$5EE0` (`Dying`, `DeathTimer`, `DeathShardPtr`); `$5EF6`-`$5F89` (`ObjectTable`); 1 more ranges |
| Writes | `$A01B`-`$A01C` (`BufferAddress+18`); `$A0AF`-`$A0B0` (`CopyFrameNext+10`) |

#### `MineBurst` (`$C744`)

**At random (1 in 7) a burst of 8 shots in the spray's directions**

As REX 1's MineBurst `$C03A` (src/game/objects.asm).

Witness: L1 32 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,898 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 7,072,602 t-states own (0.49 %) |
| Runs (the other recordings) | 32 calls (`stage2/rec/demo-cycle` 32) |
| Called from | `TutorTexts`, `Scanner` |
| Calls | `Random2`, `SetShotSpeed`, `FindEnemySlot`, `EnemyShotFrom`, `GroundWalker`, `ScannerFrames`, `ObjectHitsRex` |
| Reads | `$5860`-`$5AFF` (screen); `$62E0`-`$62FF` (`DevLinkPut+13`, `DevLinkState`, `Unused62FE`); `$6311`-`$63E7` (`Unused62FE+19`, `Font`); `$6450`-`$6467` (`Font+280`); `$64D0`-`$64DF` (`Font+408`); `$6568`-`$656F` (`CharFlags+48`); 19 more ranges |
| Writes | `$5860`-`$5925` (screen); `$593B`-`$5945` (screen); `$595B`-`$5965` (screen); `$597B`-`$5985` (screen); `$599B`-`$59A2` (screen); `$59BB`-`$5AFF` (screen); 8 more ranges |

#### `Climb` (`$C809`)

**Kinds 12 and 13: rise by the speed until a solid cell above or the top; at random turn; then sink back**

Witness: L1 868 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 868 calls (`stage2/rec/demo-cycle` 868) |
| Called from | `ObjectJump` (tail) |
| Calls | `Random2`, `ObjectCell`, `IsSolid` |
| Reads | `$5F0E`-`$5F92` |
| Writes | `$5F0E`-`$5F92` |

#### `GroundWalker` (`$C88F`)

**Kinds 12 and 13 on the ground: walk right or left by direction**

Witness: L1 868 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,034,389 t-states own (0.07 %) |
| Runs (the other recordings) | 868 calls (`stage2/rec/demo-cycle` 868) |
| Called from | `ObjectMove` (tail), `MineBurst` |
| Calls | `WalkRight`, `WalkLeft` |
| Reads | `$5F0F`; `$5F26`; `$5F3D`; `$5F54`; `$5F6B`; `$5F82`; 1 more ranges |
| Writes | `$A093` (`AnimateRestart+8`) |

#### `ScannerUp` (`$C89E`)

**Kind 8 moving up: its timer steps, the picture stepped, then the turn**

Witness: L1 138 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4,410 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 239,694 t-states own (0.02 %) |
| Runs (the other recordings) | 138 calls (`stage2/rec/demo-cycle` 138) |
| Called from | `TutorRoom4`, `TutorTexts`, `ObjectJump` (tail) |
| Reads | `$5F07`; `$E55F`-`$E7FE` (`AttrShadowPlay`) |
| Writes | `$5860`-`$5AFF` (screen) |

#### `ScannerAnimate` (`$C8C4`)

**Kind 8: its timer down (at 0 ScannerTurn), its picture from ScannerFrames by its step**

Witness: L1 100 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 132,495,924 t-states own (9.13 %) |
| Runs (the other recordings) | 100 runs of its first instruction, entered by a jump (`stage2/rec/demo-cycle` 100) |
| Called from | `FillAttrs` |
| Calls | `ScannerTurn` (tail) |

#### `Scanner` (`$C909`)

**Kind 8, the scanner: when Rex moves (walks, jumps or falls) at its height or column it turns to stalk him (ScannerReset, MineBurst); then walks, rises or sinks by its state; at a cell edge ScannerTurn**

Changed from REX 1's Scanner `$C27E` (src/game/objects.asm).

Witness: L1 138 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 7 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 28,524 t-states own (0.00 %) |
| Runs (the other recordings) | 138 calls (`stage2/rec/demo-cycle` 138) |
| Called from | `CellsUnderRex`, `TutorTexts`, `ObjectMove` (tail), `InitKind8` (tail) |
| Calls | `CellsUnderRex` (tail), `TutorKeyLeft`, `TutorKeyRight`, `MineBurst`, `ScannerTurn` (tail), `ScannerReset`, `WalkRight`, `WalkLeft` |
| Reads | `$5B83`-`$5B8A` (`RexX`, `RexY`, `Room`, `RoomColumn` and 3 more); `$5E72`-`$5EA2` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 3 more); `$5EBA` (`SmartBombPtr`); `$5ED2` (`ShieldOn`); `$5EEA`-`$5F09` (`SparkleTimer`, `Vanishing`, `Lives`, `SweepPos` and 9 more); `$5F1A`; 7 more ranges |
| Writes | `$5EFA`-`$5F09`; `$A02D`-`$A02E` (`BufferAddress+36`); `$A045`-`$A048` (`l_A045`) |

#### `ScannerDown` (`$C988`)

**Kind 8 moving down**

Witness: L1 138 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 138 calls (`stage2/rec/demo-cycle` 138) |
| Called from | `ObjectFall` (tail) |
| Calls | `ScannerTurn` (tail) |
| Reads | `$5EF7`-`$5F08` |
| Writes | `$5EF7`; `$5F08` |

#### `ScannerTurn` (`$C99E`)

**Kind 8 at a cell edge: its next direction from the grid round it, at random among the free ones**

Witness: L1 6 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 50,431 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage2/rec/demo-cycle` 6) |
| Called from | `CellsUnderRex`, `TutorTexts`, `ScannerAnimate` (tail), `Scanner` (tail), `ScannerDown` (tail), `WalkRight` |
| Calls | `Random2`, `CellPointer`, `ShardPaths`, `ScannerReset` (tail), `WalkRight`, `SetHop`, `IsSolid` |
| Reads | `$5E72`; `$5E8A`; `$5EA2` (`RexCellPtr`); `$5EBA` (`SmartBombPtr`); `$5ED2` (`ShieldOn`); `$5EF6`-`$5F07` (`ObjectTable`); 4 more ranges |
| Writes | `$5B7C`-`$5B7D` (`SpriteX`, `SpriteY`); `$5EC6`-`$5EC7` (`Score`); `$5EF8`-`$5F08`; `$A043` (`AnimFrameB+4`) |

#### `ScannerReset` (`$CA4F`)

**Kind 8's start state**

As REX 1's ScannerReset `$C3BE` (src/game/objects.asm).

Witness: L1 35 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 35 calls (`stage2/rec/demo-cycle` 35) |
| Called from | `Scanner`, `ScannerTurn` (tail) |
| Calls | `SetHop` |
| Reads | `$5EFF` |
| Writes | `$5EF8`-`$5F09` |

#### `WalkRight` (`$CA71`)

**A walker's step right: a solid cell ahead turns it; off the edge WalkOff**

Changed from REX 1's WalkRight `$C3E0` (src/game/objects.asm).

Witness: L1 3549 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 calls, 2,763 t-states own (0.00 %) |
| Runs (the other recordings) | 3,549 calls (`stage2/rec/demo-cycle` 2,494, `stage1/d1` 1,055) |
| Called from | `ObjectMove` (tail), `GroundWalker`, `Scanner`, `ScannerTurn` |
| Calls | `ShardPaths`, `ScannerTurn`, `WalkOff` (falls into), `IsSolid` |
| Reads | `$5EA4`-`$5EA5` (`ObjectCellPtr`); `$5EF6`-`$5F90` (`ObjectTable`); `$A02D`-`$A02E` (`BufferAddress+36`); `$A0B6` (`CopyFrameNext+17`); `$E224`-`$E263` (`RoomGridPlay+37`); `$E275`-`$E327` (`RoomGridPlay+118`); 2 more ranges |
| Writes | `$5EC8` (`Score+1`); `$5EF6`-`$5EF8` (`ObjectTable`); `$5F0D`-`$5F0F`; `$5F24`-`$5F26`; `$5F3B`-`$5F3D`; `$5F52`-`$5F54`; 3 more ranges |

#### `WalkOff` (`$CAE3`)

**Kinds 6 and 7 off the edge die (KillObject); 3, 4, 5 vanish (ObjectGone: alive 0, no score)**

As REX 1's WalkOff `$C47A` (src/game/objects.asm).

Witness: L1 235 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 2,623 t-states own (0.00 %) |
| Runs (the other recordings) | 235 calls (`stage2/rec/demo-cycle` 184, `stage1/d1` 51) |
| Called from | `WalkRight` (falls into), `WalkLeft` (tail) |
| Calls | `ShowPoints` (tail), `TutorTexts` |
| Reads | `$5EFF`; `$5F16`; `$5F2D`; `$5F44`; `$5F5B`; `$5F72`; 14 more ranges |
| Writes | `$A093`-`$A094` (`AnimateRestart+8`) |

#### `WalkLeft` (`$CB05`)

**A walker's step left (as WalkRight)**

Changed from REX 1's WalkLeft `$C4A6` (src/game/objects.asm).

Witness: L1 4332 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 65,936 t-states own (0.00 %) |
| Runs (the other recordings) | 4,332 calls (`stage2/rec/demo-cycle` 3,260, `stage1/d1` 1,072) |
| Called from | `TutorTexts`, `ObjectMove` (tail), `GroundWalker`, `Scanner` |
| Calls | `WalkOff` (tail), `SetHop`, `MaybeJumper`, `InitKind6`, `IsSolid` |
| Reads | `$5E66`-`$5FE4` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 66 more); `$A020`-`$A021` (`BufferAddress+23`); `$AED0`-`$AEE3` (`MirrorTable+194`); `$AF3F`-`$AF48` (`FramesKind12+1`); `$E223`-`$E3FC` (`RoomGridPlay+36`); `$E414`-`$E41B` (`RoomGridPlay+533`); 1 more ranges |
| Writes | `$5E66`-`$5FE5` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 66 more) |

#### `SetHop` (`$CB78`)

**The hop's state: picture HL, speed, timers, bit 7 of the kind**

As REX 1's SetHop `$C556` (src/game/objects.asm).

Witness: L1 9 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 21,349 t-states own (0.00 %) |
| Runs (the other recordings) | 9 calls (`stage2/rec/demo-cycle` 9) |
| Called from | `ScannerTurn`, `ScannerReset`, `WalkLeft`, `MaybeJumper` |
| Calls | `Random2` |
| Reads | `$5E4E`-`$5E50`; `$5EFF`; `$5F16`; `$5F2D`; `$A9F5`-`$AA0B` (`TextTeleport+23`); `$AED0`-`$AEE2` (`MirrorTable+194`); 1 more ranges |
| Writes | `$5E66`-`$5F3D` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 66 more) |

#### `MaybeJumper` (`$CB99`)

**A kind 0 walker at X & 7 = 2 (right) or 4 (left), standing, becomes a jumper (SpriteJumper, SetHop)**

Changed from REX 1's MaybeJumper `$C577` (src/game/objects.asm).

Witness: L1 9 (demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9 calls (`stage2/rec/demo-cycle` 9) |
| Called from | `WalkLeft` |
| Calls | `SetHop`, `ObjectJump`, `ObjectFall`, `DrawRoom` |
| Reads | `$5EF6`-`$5F35` (`ObjectTable`) |
| Writes | `$5F07`-`$5F08`; `$5F1E`-`$5F1F`; `$5F35`-`$5F36` |

#### `MaybeJumperEnd` (`$CBD6`)

**Leftover: LD A,(IX+`$11`): OR A: RET NZ after MaybeJumper; nothing reaches it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 25 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `StartFall` (`$CBDB`)

**An object not falling, below line 32 and not on the floor starts to fall (JumpSteps `$D3C8`)**

Witness: L1 3 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 25 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3 calls (`stage2/rec/demo-cycle` 3) |
| Called from | `HitObject` |
| Calls | `DrawRoom` |
| Reads | `$5EF7`-`$5EFC`; `$5F0E`-`$5F13`; `$5F25`-`$5F2A` |
| Writes | `$5EF9`-`$5EFB`; `$5F10`-`$5F12`; `$5F27`-`$5F29` |

#### `ObjectJump` (`$CBF9`)

**The jump of an object by its jump table (pods, 14, 15 none; 8 and 12/13 their own); a solid cell above ends it and kinds 6 and 7 die**

Witness: L1 12882 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 25 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 313 t-states own (0.00 %) |
| Runs (the other recordings) | 12,882 calls (`stage2/rec/demo-cycle` 9,537, `stage1/d1` 3,345) |
| Called from | `ObjectBehaviour`, `MaybeJumper` |
| Calls | `CellPointer`, `Climb` (tail), `ScannerUp` (tail), `IsSolid` |
| Reads | `$5EF6`-`$5F2D` (`ObjectTable`); `$5F3E`-`$5F44`; `$5F55`-`$5F5B`; `$5F6C`-`$5F72`; `$5F83`-`$5F89`; `$5FA0`; 1 more ranges |
| Writes | `$5B7C`-`$5B7D` (`SpriteX`, `SpriteY`); `$5ED7`-`$5EDA` (`ShieldDrainRate`, `WeaponIcon`, `HasDoubleFire`, `HasLaser`); `$5EF2`-`$5F29` (`AnimCount1`, `AnimCount2`, `AnimCount3`, `Bombs` and 1 more) |

#### `ObjectFall` (`$CC9B`)

**The fall: by the fall speed until a solid cell; below line `$B8` the object dies (a person counts)**

As REX 1's ObjectFall `$C6C2` (src/game/objects.asm).

Witness: L1 12882 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 136 t-states own (0.00 %) |
| Runs (the other recordings) | 12,882 calls (`stage2/rec/demo-cycle` 9,537, `stage1/d1` 3,345) |
| Called from | `ObjectBehaviour`, `MaybeJumper` |
| Calls | `ShowPoints` (tail), `ScannerDown` (tail), `ObjectCell`, `IsPassable` |
| Reads | `$5EF7`-`$5FA0`; `$E257`-`$E258` (`RoomGridPlay+88`); `$E276`-`$E278` (`RoomGridPlay+119`); `$E290`-`$E45D` (`RoomGridPlay+145`); `$E473`-`$E474` (`RoomGridPlay+628`); `$E493`-`$E494` (`RoomGridPlay+660`); 2 more ranges |
| Writes | `$5EC2`-`$5EC3` (`KillFlashPtr`); `$5EF7`-`$5F13`; `$5F25`-`$5F41`; `$5F53`-`$5F58`; `$5F6A`-`$5F6F`; `$5F81`-`$5F86`; 1 more ranges |

#### `ObjectCell` (`$CCF8`)

**ObjectCellPtr `$5EA4` = the grid cell of the object at IX**

As REX 1's ObjectCell `$C72B` (src/game/objects.asm).

Witness: L1 25406 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 10 calls, 1,925 t-states own (0.00 %) |
| Runs (the other recordings) | 25,406 calls (`stage2/rec/demo-cycle` 18,737, `stage1/d1` 6,669) |
| Called from | `ObjectBehaviour`, `Climb`, `ObjectFall`, `DrawRoom` |
| Calls | `CellPointer` |
| Reads | `$5E87`; `$5E9F` (`PowerBarPtr+1`); `$5EB7` (`SpawnTop`); `$5EF6`-`$5EF8` (`ObjectTable`); `$5F0D`-`$5F0F`; `$5F24`-`$5F26`; 5 more ranges |
| Writes | `$5B7C`-`$5B7D` (`SpriteX`, `SpriteY`); `$5E82`-`$5EC3` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 21 more) |

### DEMO: rooms

`src/demo/rooms.asm`

#### `DrawRoom` (`$CD12`)

**Draw the room: silence, the map's 7 x 10 blocks into the grid, the attribute shadow and SceneryCellList (its pixel writes into the buffer are wiped by BuildRoom's ClearBuffer after it; the cell list redraws them)**

As REX 1's DrawRoom `$C745` (src/game/rooms.asm).

Witness: L1 12 (d1, demo-cycle).

[Animation: `DrawRoom` at work](img/routines/DrawRoom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 2,546 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage2/rec/demo-cycle` 9, `stage1/d1` 3) |
| Called from | `MainLoop`, `MaybeJumper`, `StartFall` |
| Calls | `ObjectCell`, `DrawBlockRow`, `Multiply`, `SoundReset`, `SoundSilence` |
| Reads | `$5860`-`$5AFF` (screen); `$5B85` (`Room`); `$5E6F`; `$5E9F` (`PowerBarPtr+1`); `$5EE8` (`SparkleOn`); `$7838`-`$79DB` (`RoomMaps`); 1 more ranges |
| Writes | `$5860`-`$5945` (screen); `$595B`-`$5965` (screen); `$597B`-`$5985` (screen); `$599B`-`$59A5` (screen); `$59BB`-`$59C5` (screen); `$59DB`-`$5AFF` (screen); 3 more ranges |

#### `DrawBlockRow` (`$CD92`)

**One row of 10 blocks**

As REX 1's DrawBlockRow `$C7C5` (src/game/rooms.asm).

Witness: L1 840 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 840 calls (`stage2/rec/demo-cycle` 630, `stage1/d1` 210) |
| Called from | `DrawRoom` |
| Calls | `DrawRoomCell` |
| Reads | `$6F38`-`$72FA` (`BlockDefs`); `$733A`-`$7381` (`BlockDefs+1026`); `$73B8`-`$75DC` (`BlockDefs+1152`); `$7640`-`$7756` (`BlockDefs+1800`); `$77B1`-`$77B9` (`BlockDefs+2169`); `$7802`-`$781C` (`BlockDefs+2250`) |

#### `DrawRoomCell` (`$CDAF`)

**One block: its 3 x 3 characters into the buffer, the attribute shadow and the grid; an animated character listed**

As REX 1's DrawRoomCell `$C7E2` (src/game/rooms.asm).

Witness: L1 7560 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,560 calls (`stage2/rec/demo-cycle` 5,670, `stage1/d1` 1,890) |
| Called from | `DrawBlockRow` |
| Calls | `DrawRoomChar` |
| Reads | `$5B62` (`Temp2`); `$5B86`-`$5B87` (`RoomColumn`); `$5EA6`-`$5EA8` (`RoomCellPtr`); `$6538`-`$663F` (`CharFlags`, `CharGraphics`); `$6660`-`$6667` (`CharGraphics+40`); `$66A0`-`$66B7` (`AnimChar11+16`); 3 more ranges |
| Writes | `$5B62` (`Temp2`); `$5B86`-`$5B87` (`RoomColumn`); `$5EA6`-`$5EA8` (`RoomCellPtr`); `$DBF6`-`$E19D` (`SceneryCellList`, `CellIndexMap`); `$E200`-`$E49D` (`RoomGridPlay+1`); `$E560`-`$E7FD` (`AttrShadowPlay+1`); 1 more ranges |

#### `DrawRoomChar` (`$CE60`)

**One character's 8 bytes into the back buffer**

As REX 1's DrawRoomChar `$C893` (src/game/rooms.asm).

Witness: L1 7560 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 12,241 t-states own (0.00 %) |
| Runs (the other recordings) | 7,560 calls (`stage2/rec/demo-cycle` 5,670, `stage1/d1` 1,890) |
| Called from | `UpdateDrones`, `DrawRoomCell` |
| Reads | `$5B60` (`Temp1`); `$A028`-`$A02B` (`BufferAddress+31`); `$A093`-`$A09F` (`AnimateRestart+8`, `CopyFrame`) |
| Writes | `$5B60` (`Temp1`); `$A028`-`$A02B` (`BufferAddress+31`); `$A093`-`$A09F` (`AnimateRestart+8`, `CopyFrame`) |

#### `CopyAttrs` (`$CE8C`)

**The attribute shadow `$E55F` to the screen's play rows `$5860`; the side columns white**

As REX 1's CopyAttrs `$C8BF` (src/game/rooms.asm).

Witness: L1 60 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 14 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 60 calls (`stage2/rec/demo-cycle` 51, `stage1/d1` 9) |
| Called from | `MainLoop`, `SmartBombStep`, `PanelClose`, `TutorPanelFlash`, `TutorPanelPower`, `TutorEvents4`, `BonusRoulette`, `WeaponPanel` |
| Reads | `$E55F`-`$E7FE` (`AttrShadowPlay`) |
| Writes | `$5860`-`$5AFF` (screen) |

#### `Delay` (`$CEA8`)

**Wait BC x 10 loops**

As REX 1's Delay `$C8DB` (src/game/rooms.asm).

Witness: L1 1970000 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 79 calls (`stage2/rec/demo-cycle` 67, `stage1/d1` 12) |
| Called from | `PanelClose`, `TutorPanelFlash`, `TutorPanelPower`, `TutorRoom0`, `TutorRoom1`, `TutorRoom2`, `TutorRoom4`, `TutorEvents4`, `PowerColours`, `FlashTwoCells`, `TutorNextRoom`, `BonusRoulette`, `WeaponPanel` |

#### `Multiply` (`$CEB5`)

**HL = DE x B**

As REX 1's Multiply `$C8E8` (src/game/rooms.asm).

Witness: L1 864 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 864 calls (`stage2/rec/demo-cycle` 648, `stage1/d1` 216) |
| Called from | `DrawRoom`, `ReadExits` |
| Calls | `ChannelStep` |

#### `ReadExits` (`$CEBC`)

**The room's exits and object list from RoomExits; the list's header: count, spawn sides, timers, spawn kind**

As REX 1's ReadExits `$C8EF` (src/game/rooms.asm).

Witness: L1 12 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 64,331 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage2/rec/demo-cycle` 9, `stage1/d1` 3) |
| Called from | `MainLoop` |
| Calls | `Multiply`, `ChannelStep` |
| Reads | `$5B85` (`Room`); `$A028` (`BufferAddress+31`); `$ABED`-`$AC2C` (`TutorText2+4`); `$AC4D`-`$AD5C` (`TutorCredits+11`, `PixelMasks`, `ScreenLineTable`); `$AFEE`-`$B001` (`RoomObjectLists`); `$B018`-`$B019` (`RoomObjectLists+42`); 1 more ranges |
| Writes | `$5B90`-`$5B94` (`ObjectCount`, `RoomRight`, `RoomUp`, `RoomDown` and 1 more); `$5EA9`-`$5EB7` (`ObjectListPtr`, `BoxX`, `BoxY`, `BoxWidth` and 4 more); `$5ECC`-`$5ECD` (`SpawnTimer`, `SpawnPeriod`) |

#### `SetSpawnTop` (`$CF10`)

**SpawnTop `$5EB7` = `$FF`**

As REX 1's SetSpawnTop `$C948` (src/game/rooms.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 488 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `SetSpawnRight` (`$CF16`)

**SpawnRight `$5EB6` = `$FF`**

As REX 1's SetSpawnRight `$C94E` (src/game/rooms.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 488 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Calls | `SetSpawnLeft` |

#### `SetSpawnLeft` (`$CF1C`)

**SpawnLeft `$5EB5` = `$FF`**

As REX 1's SetSpawnLeft `$C954` (src/game/rooms.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 347,088 t-states own (0.02 %) |
| Called from | `SetSpawnRight` |
| Reads | `$6120`-`$6147`; `$6158`-`$615F`; `$61B8`-`$61CF` (`DevLink+16`); `$A02A` (`BufferAddress+33`) |
| Writes | `$4022`-`$490E` (screen); `$4924`-`$4A0E` (screen); `$4A24`-`$4B0E` (screen); `$4B24`-`$4C0E` (screen); `$4C24`-`$4D0E` (screen); `$4D24`-`$4E0E` (screen); 2 more ranges |

#### `ToMainLoop` (`$CF22`)

**JP MainLoop: a new room (ExitRight, ExitTop)**

Witness: L1 4 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 488 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4 calls (`stage2/rec/demo-cycle` 3, `stage1/d1` 1) |
| Called from | `ExitRight` (tail) |
| Calls | `MainLoop` (tail) |

#### `StartScriptSpawn` (`$CF25`)

**The scripted spawn starts: step 1, timer, count 0**

As REX 1's StartScriptSpawn `$C965` (src/game/rooms.asm).

Witness: L1 3 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 488 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3 calls (`stage2/rec/demo-cycle` 3) |
| Called from | `MainLoop`, `TutorRoom0`, `TutorRoom2` |
| Reads | `$5ECE` (`ScriptSpawnStep`); `$A2C4` (`TutorSpawn0`); `$A2FE` (`TutorSpawn2`); `$A318` (`TutorSpawn3`) |
| Writes | `$5ECE`-`$5ED1` (`ScriptSpawnStep`, `ScriptSpawnTimer`, `ScriptSpawnCount`) |

#### `SpawnScripted` (`$CF38`)

**The scripted spawn's step: every few passes the next record of ScriptSpawn into a free object**

As REX 1's SpawnScripted `$C978` (src/game/rooms.asm).

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 488 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 481,421 t-states own (0.03 %) |
| Runs (the other recordings) | 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop`, `TutorNextRoom`, `FireSpray`, `MakeObjects` |
| Calls | `MakeObjectIY` |
| Reads | `$5B90` (`ObjectCount`); `$5ECE`-`$5ED1` (`ScriptSpawnStep`, `ScriptSpawnTimer`, `ScriptSpawnCount`); `$5F02`; `$5F19`; `$5F30`; `$5F47`; 13 more ranges |
| Writes | `$588F`-`$58D1` (screen); `$5901`-`$5943` (screen); `$597D`-`$5AB0` (screen); `$5AC7`-`$5AD0` (screen); `$5AE7`-`$5AF0` (screen); `$5ECE`-`$5ED1` (`ScriptSpawnStep`, `ScriptSpawnTimer`, `ScriptSpawnCount`) |

#### `SpawnRandom` (`$CF8A`)

**The random spawn's timer: every SpawnPeriod passes a random number and nothing more (the spawn is cut: SpawnLeftover)**

Changed from REX 1's SpawnRandom `$C9CA` (src/game/rooms.asm).

Witness: L1 6752 (d1, demo-cycle).

[Animation: `SpawnRandom` at work](img/routines/SpawnRandom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 158,865 t-states own (0.01 %) |
| Runs (the other recordings) | 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop`, `CellsUnderRex`, `Fill2x2`, `FireSpray` |
| Calls | `Random2`, `TutorTexts` |
| Reads | `$5800`-`$585F` (screen); `$5ECC`-`$5ECE` (`SpawnTimer`, `SpawnPeriod`, `ScriptSpawnStep`); `$A093`-`$A096` (`AnimateRestart+8`); `$BFE7`-`$BFEE` (`StepShot+61`) |
| Writes | `$5ECC` (`SpawnTimer`); `$A093`-`$A096` (`AnimateRestart+8`); `$E4FF`-`$E55E` (`AttrShadow`, `ShieldAttrs`, `HeatAttr`, `SweepAttrs`) |

#### `SpawnLeftover` (`$CFA2`)

**Leftover: LD HL,`$5F02` after SpawnRandom (part 1 went on to make the object); nothing reaches it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 600 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

#### `MakeObjects` (`$CFA5`)

**Build the room's objects from its list (ObjectListPtr `$5EA9`): [kind][X][Y] each**

As REX 1's MakeObjects `$CB52` (src/game/rooms.asm).

Witness: L1 12 (d1, demo-cycle).

[Animation: `MakeObjects` at work](img/routines/MakeObjects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 600 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 22,600 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage2/rec/demo-cycle` 9, `stage1/d1` 3) |
| Called from | `MainLoop`, `PanelOpen` |
| Calls | `SpawnScripted`, `MakeObjectIY` |
| Reads | `$5EA9`-`$5EAA` (`ObjectListPtr`); `$5EF6`-`$6064` (`ObjectTable`); `$A072` (`l_A045+45`); `$AFF0`-`$B032` (`RoomObjectLists+2`) |
| Writes | `$5EF6`-`$6065` (`ObjectTable`); `$A091` (`AnimateRestart+6`); `$A0BB` (`CopyFrameNext+22`) |

#### `MakeObjectIY` (`$CFDB`)

**Make the object of the list record at IY: the kind from IY+0; the common sizes; the kind's initialiser (0, 1, 2, 8, 9, 10, 11, 12, 6, `$7C`, `$7D`); its place from IY+1, IY+2, its direction from bit 7**

Changed from REX 1's MakeObjectIY `$CB88` (src/game/rooms.asm).

Witness: L1 67 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 102,449 t-states own (0.01 %) |
| Runs (the other recordings) | 67 calls (`stage2/rec/demo-cycle` 52, `stage1/d1` 15) |
| Called from | `PanelClose`, `TutorPanelFlash`, `SpawnScripted`, `MakeObjects` |
| Calls | `InitKind0`, `InitKind1`, `InitKind2` (tail), `InitKind8`, `InitKind7C`, `InitKind7D`, `InitKind9`, `InitKind10`, `InitKind11`, `InitKind12` |
| Reads | `$A019`-`$A01A` (`BufferAddress+16`); `$A072` (`l_A045+45`); `$A091` (`AnimateRestart+6`); `$A0B6`-`$A0BD` (`CopyFrameNext+17`, `CopyFrameDo`); `$A2C5`-`$A32F` (`TutorSpawn0+1`, `TutorSpawn2`, `TutorSpawn3`); `$AFF6`-`$B031` (`RoomObjectLists+8`) |
| Writes | `$5EF6`-`$5FAC` (`ObjectTable`); `$A091` (`AnimateRestart+6`); `$A0B6`-`$A0BB` (`CopyFrameNext+17`) |

#### `InitKind0` (`$D068`)

**Kind 0, the foot man: frames ShiftFrames, 2 hits**

Changed from REX 1's InitKind0 `$CC48` (src/game/rooms.asm).

Witness: L1 14 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 859,860 t-states own (0.06 %) |
| Runs (the other recordings) | 14 calls (`stage2/rec/demo-cycle` 14) |
| Called from | `BlowUp`, `MakeObjectIY`, `InitKind6` (tail), `InitKind7C`, `InitKind7D` |
| Reads | `$D096`-`$D09F` (`InitKind6+26`); `$E33A`-`$E342` (`RoomGridPlay+315`); `$E355`-`$E362` (`RoomGridPlay+342`); `$E375`-`$E43C` (`RoomGridPlay+374`); `$E44E` (`RoomGridPlay+591`) |
| Writes | `$5F07`-`$5F0B`; `$5F1E`-`$5F22`; `$5F35`-`$5F39`; `$5F4C`-`$5F50`; `$5F63`-`$5F67`; `$5F7A`-`$5F7E` |

#### `InitKind6` (`$D07C`)

**Kind 6: SpriteKind6, 2 hits, the turn timer 200**

Changed from REX 1's InitKind6 `$CC5B` (src/game/rooms.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 138,594 t-states own (0.01 %) |
| Called from | `TutorScript0`, `DrawShard`, `FlashAttrs`, `WalkLeft`, `InitKind12`, `PanelBox` |
| Calls | `InitKind0` (tail) |
| Reads | `$E28E`-`$E29C` (`RoomGridPlay+143`); `$E2AE`-`$E2BC` (`RoomGridPlay+175`); `$E2CE`-`$E2DC` (`RoomGridPlay+207`); `$E2EE`-`$E2FC` (`RoomGridPlay+239`); `$E30E`-`$E47C` (`RoomGridPlay+271`); `$E48E` (`RoomGridPlay+655`) |

#### `InitKind1` (`$D0A1`)

**Kind 1, the stomper: speed 2, 8 hits, frames `$AF2E`**

Changed from REX 1's InitKind1 `$CC83` (src/game/rooms.asm).

Witness: L1 16 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 calls (`stage2/rec/demo-cycle` 10, `stage1/d1` 6) |
| Called from | `MakeObjectIY` |
| Writes | `$5F34`-`$5F39`; `$5F4B`-`$5F50`; `$5F62`-`$5F67`; `$5F79`-`$5F7E`; `$5F90`-`$5F95` |

#### `InitKind2` (`$D0B1`)

**Kind 2: speed 0, no hits, frames `$AF2E` (it turns to face Rex: ObjectMove)**

Changed from REX 1's InitKind3 `$CC96` (src/game/rooms.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 3 calls, 225 t-states own (0.00 %) |
| Called from | `MakeObjectIY` (tail) |
| Reads | `$A08D` (`AnimateRestart+2`) |
| Writes | `$A0B6`-`$A0B8` (`CopyFrameNext+17`) |

#### `InitKind8` (`$D0BD`)

**Scanner: 7 hits, frames `$AF4E`**

Witness: L1 1 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 1,538 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `PanelClose`, `MakeObjectIY` |
| Calls | `Scanner` (tail) |
| Reads | `$A0BC`-`$A0BD` (`CopyFrameNext+23`, `CopyFrameDo`) |
| Writes | `$5EFC`-`$5F0B`; `$A0BD`-`$A0C1` (`CopyFrameDo`) |

#### `InitKind7C` (`$D0E1`)

**Kind `$7C`: the bonus pod SpriteBonusPod**

Witness: L1 2 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 17,008 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage2/rec/demo-cycle` 2) |
| Called from | `PanelClose`, `MakeObjectIY` |
| Calls | `InitKind0` |
| Reads | `$5EFF`; `$A019`-`$A01A` (`BufferAddress+16`); `$A0B7`-`$A0C1` (`CopyFrameNext+18`, `CopyFrameDo`); `$D0D8`-`$D0E2` (`InitKind8+27`, `InitKind7C`) |
| Writes | `$5EFA`-`$5F04`; `$A0B7`-`$A0C1` (`CopyFrameNext+18`, `CopyFrameDo`) |

#### `InitKind7D` (`$D0F3`)

**Kind `$7D`: the bomb pod SpriteBombPod**

Witness: L1 3 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 30 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3 calls (`stage2/rec/demo-cycle` 2, `stage1/d1` 1) |
| Called from | `MakeObjectIY` |
| Calls | `InitKind0` |
| Reads | `$5FA0` |
| Writes | `$5F9B`-`$5FA5` |

#### `InitKind9` (`$D105`)

**Kind 9, the swing gun: SpriteSwingGun, 12 hits**

Changed from REX 1's InitBonusPod `$CCE6` (src/game/rooms.asm).

Witness: L1 5 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 30 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 5 calls (`stage2/rec/demo-cycle` 3, `stage1/d1` 2) |
| Called from | `MakeObjectIY` |
| Reads | `$5EFF`; `$5F89` |
| Writes | `$5EFA`-`$5F0B`; `$5F84`-`$5F95` |

#### `InitKind10` (`$D123`)

**Kind 10, the shooters: SpriteKind10, 10 hits, the shot timer 20 / 12**

Changed from REX 1's InitKind9 `$CCF8` (src/game/rooms.asm).

Witness: L1 8 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 3) |
| Called from | `MakeObjectIY` |
| Reads | `$5EFF`; `$5F16`; `$5F2D` |
| Writes | `$5EFA`-`$5F39` |

#### `InitKind11` (`$D145`)

**Kind 11, the launcher: SpriteKind11, 8 hits, the shot timer 10 / 6**

Changed from REX 1's InitKind11 `$CD7C` (src/game/rooms.asm).

Witness: L1 6 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 82,062 t-states own (0.01 %) |
| Runs (the other recordings) | 6 calls (`stage1/d1` 3, `stage2/rec/demo-cycle` 3) |
| Called from | `PanelClose`, `MakeObjectIY` |
| Reads | `$5F16`; `$5F5B`; `$5F72`; `$A0B6`-`$A0BD` (`CopyFrameNext+17`, `CopyFrameDo`); `$E37B`-`$E37C` (`RoomGridPlay+380`); `$E393`-`$E3A1` (`RoomGridPlay+404`); 6 more ranges |
| Writes | `$5F11`-`$5F22`; `$5F56`-`$5F7E`; `$A0AF`-`$A0BC` (`CopyFrameNext+10`) |

#### `InitKind12` (`$D16B`)

**Kind 12, the ground walker: 3 hits, frames `$AF3E`**

Changed from REX 1's InitKind12 `$CDA2` (src/game/rooms.asm).

Witness: L1 12 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 271 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 12 calls (`stage2/rec/demo-cycle` 12) |
| Called from | `MakeObjectIY` |
| Calls | `TutorTexts`, `InitKind6` |
| Writes | `$5F13`-`$5F94` |

### DEMO: panels

`src/demo/panels.asm`

#### `PanelBox` (`$D17F`)

**Draw a framed box: A attribute, D width, E height, H column, L line, C the frame's colour; the frame from the font's edge characters**

As REX 1's PanelBox `$CE7B` (src/game/panels.asm).

Witness: L1 43 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 271 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 742,204 t-states own (0.05 %) |
| Runs (the other recordings) | 43 calls (`stage2/rec/demo-cycle` 36, `stage1/d1` 7) |
| Called from | `CellsUnderRex`, `PrintBoxed`, `TutorTexts` |
| Calls | `HudSweep`, `InitKind6`, `PanelRow`, `FillAttrs` |
| Reads | `$5B60`-`$5B6C` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 1 more); `$5D22`-`$6C46` (`DevLink`, `DevLinkState`, `Unused62FE`, `Font` and 2 more); `$A049`-`$A060` (`l_A045+4`); `$A0B6`-`$A0B7` (`CopyFrameNext+17`) |
| Writes | `$5B60`-`$5B6C` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 1 more); `$5D28`-`$5D37`; `$5D55`; `$5EB1`-`$5EB4` (`BoxX`, `BoxY`, `BoxWidth`, `BoxHeight`) |

#### `PanelRow` (`$D20E`)

**8 lines of a box row**

As REX 1's PanelRow `$CF0A` (src/game/panels.asm).

Witness: L1 249 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 8,206 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 545,695 t-states own (0.04 %) |
| Runs (the other recordings) | 249 calls (`stage2/rec/demo-cycle` 200, `stage1/d1` 49) |
| Called from | `DrawSprite`, `PanelBox` |
| Calls | `PanelLine` |
| Reads | `$5E66`-`$5F2F` (`FireLatch`, `Weapon`, `PowerLevel`, `PowerBarPtr` and 66 more); `$A055`-`$A060` (`l_A045+16`); `$A0B6`-`$A0B7` (`CopyFrameNext+17`); `$ACCE`-`$ADFD` (`ScreenLines+16`) |
| Writes | `$D28E`-`$D29E` (`CopyCells+13`, `SaveAttrs`); `$D310` (`WalkLeftNormal+4`); `$D321` (`RexWalkStep`) |

#### `PanelLine` (`$D225`)

**One pixel line: the left edge, the middle B times, the right edge**

As REX 1's PanelLine `$CF21` (src/game/panels.asm).

Witness: L1 1992 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,992 calls (`stage2/rec/demo-cycle` 1,600, `stage1/d1` 392) |
| Called from | `PanelRow` |
| Reads | `$5EB3` (`BoxWidth`); `$6378`-`$639F` (`Font+64`); `$63B0`-`$63B7` (`Font+120`); `$6410`-`$6427` (`Font+216`) |
| Writes | `$4082`-`$57DD` (screen) |

#### `FillShadowRow3` (`$D241`)

**Three rows of three: the cells of value `$47` (white) take C**

As REX 1's FillShadowRow3 `$CF3D` (src/game/panels.asm).

Witness: L1 504 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 504 calls (`stage2/rec/demo-cycle` 408, `stage1/d1` 96) |
| Called from | `FlashCells` |
| Calls | `FillShadowCells` |

#### `FillShadowCells` (`$D24B`)

**One row of three cells**

As REX 1's FillShadowCells `$CF47` (src/game/panels.asm).

Witness: L1 1512 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,512 calls (`stage2/rec/demo-cycle` 1,224, `stage1/d1` 288) |
| Called from | `FillShadowRow3` |
| Reads | `$E557`-`$E559` (`SweepAttrs+44`); `$E576`-`$E579` (`AttrShadowPlay+23`); `$E590`-`$E59A` (`AttrShadowPlay+49`); `$E5AC`-`$E61C` (`AttrShadowPlay+77`); `$E63A`-`$E63D` (`AttrShadowPlay+219`); `$E656`-`$E6A8` (`AttrShadowPlay+247`); 1 more ranges |
| Writes | `$5877`-`$587A` (screen); `$5892`-`$591D` (screen); `$593B`-`$593D` (screen); `$5957`-`$59A9` (screen); `$59BC`-`$5A9E` (screen) |

#### `CopyCells3` (`$D272`)

**Copy a 3 x 3 patch from DE to HL (the shadow's 32-byte rows)**

As REX 1's CopyCells3 `$CF6E` (src/game/panels.asm).

Witness: L1 63 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 63 calls (`stage2/rec/demo-cycle` 51, `stage1/d1` 12) |
| Called from | `BlowUp` |
| Calls | `CopyCells`, `WalkRightKey` (tail) |

#### `CopyCells` (`$D281`)

**One row of three**

As REX 1's CopyCells `$CF7D` (src/game/panels.asm).

Witness: L1 189 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 189 calls (`stage2/rec/demo-cycle` 153, `stage1/d1` 36) |
| Called from | `CopyCells3` |
| Calls | `WalkRightKey` (tail) |
| Reads | `$E557`-`$E559` (`SweepAttrs+44`); `$E576`-`$E579` (`AttrShadowPlay+23`); `$E590`-`$E59A` (`AttrShadowPlay+49`); `$E5AC`-`$E61C` (`AttrShadowPlay+77`); `$E63A`-`$E63D` (`AttrShadowPlay+219`); `$E656`-`$E6A8` (`AttrShadowPlay+247`); 1 more ranges |
| Writes | `$5858`-`$585A` (screen); `$5877`-`$587A` (screen); `$5891`-`$589B` (screen); `$58AD`-`$591D` (screen); `$593B`-`$593E` (screen); `$5957`-`$59A9` (screen); 1 more ranges |

#### `SaveAttrs` (`$D293`)

**The screen's top 96 attributes (`$5800`) into the shadow at `$E4FF`**

As REX 1's SaveAttrs `$CF8F` (src/game/panels.asm).

Witness: L1 7 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage2/rec/demo-cycle` 5, `stage1/d1` 2) |
| Called from | `NewGame` |
| Calls | `WalkRightKey` (tail) |
| Reads | `$5800`-`$585F` (screen) |
| Writes | `$E4FF`-`$E55E` (`AttrShadow`, `ShieldAttrs`, `HeatAttr`, `SweepAttrs`) |

#### `FlashCells` (`$D29F`)

**The explosion's attribute flash: the object's 3 x 3 cells in the shadow coloured from FlashAttrs `$C6FB` at random**

As REX 1's FlashCells `$CF9B` (src/game/panels.asm).

Witness: L1 504 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 76 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 504 calls (`stage2/rec/demo-cycle` 408, `stage1/d1` 96) |
| Called from | `BlowUp` |
| Calls | `BufferAddress`, `FillShadowRow3`, `WalkRightKey` (tail) |
| Reads | `$5B60`-`$5B63` (`Temp1`, `Temp2`); `$C6FB`-`$C702` (`FlashAttrs`) |
| Writes | `$5B60`-`$5B63` (`Temp1`, `Temp2`) |

#### `WeaponPanel` (`$DA75`)

**A weapon station's panel (HL: the flag then the text), once a game: the screen saved, the panel, wait for fire, the screen back**

As REX 1's WeaponPanel `$D871` (src/game/panels.asm).

Witness: L1 244 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 244 calls (`stage2/rec/demo-cycle` 166, `stage1/d1` 78) |
| Called from | `CellsUnderRex` |
| Calls | `WaitQuiet`, `PrintBoxed`, `BufferToScreen`, `CopyAttrs`, `Delay`, `SaveScreen` |
| Reads | `$A5E1`-`$A5E2` (`DoubleFireText`); `$A623`-`$A624` (`LaserText`); `$A682`-`$A683` (`MultipleText`); `$A6E5`-`$A6E6` (`SprayText`) |
| Writes | `$A5E1` (`DoubleFireText`); `$A623` (`LaserText`); `$A682` (`MultipleText`); `$A6E5` (`SprayText`) |

#### `SaveScreen` (`$DAA1`)

**The screen's play lines into the back buffer (the panels draw over the screen; BufferToScreen puts it back)**

As REX 1's SaveScreen `$D8A3` (src/game/panels.asm).

Witness: L1 33 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33 calls (`stage2/rec/demo-cycle` 29, `stage1/d1` 4) |
| Called from | `PanelOpen`, `TutorPanelFlash`, `TutorPanelPower`, `BonusRoulette`, `WeaponPanel` |
| Reads | `$4060`-`$57FF` (screen); `$ACBE`-`$AE0D` (`ScreenLines`) |
| Writes | `$EAFF`-`$FFFE` (`BufferPlayOrigin`, `work space $FFFA+`) |

#### `DrawCharBlock` (`$DABE`)

**Draw a picture straight on the screen from the 6 bytes after the CALL: picture word, column, line, width, height; returns after them**

As REX 1's DrawCharBlock `$D8C0` (src/game/panels.asm).

Witness: L1 1393 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 615,128 t-states own (0.04 %) |
| Runs (the other recordings) | 1,393 calls (`stage2/rec/demo-cycle` 957, `stage1/d1` 436) |
| Called from | `SparkleDraw`, `DrawHudIcon`, `DrawWeaponIcon` |
| Calls | `NextHudIcon`, `NextWeaponIcon`, `UpdateDrones` |
| Reads | `$4000`-`$5AFF` (screen); `$5B60`-`$5B63` (`Temp1`, `Temp2`); `$8464`-`$8543` (`SpriteHudIcons`, `SpriteHudIcons2`); `$9CE6`-`$9CEB` (`HudIconParams`, `HudIconColumn`); `$9D28`-`$9D2D` (`WeaponIconParams`); `$A065` (`l_A045+32`); 9 more ranges |
| Writes | `$4000`-`$5AFF` (screen); `$5B60`-`$5B63` (`Temp1`, `Temp2`); `$6018`-`$60D7` (`WeaponRank`, `BonusRoll`, `Immune`, `SpeedUp` and 15 more); `$A065` (`l_A045+32`); `$A07F`-`$A087` (`AnimateCells2+4`); `$E4FF`-`$FFFE` (`AttrShadow`, `work space $FFFA+`) |
| Ports in | `$F7FE` |
| Ports out | `$00FE` |

#### `FillAttrs` (`$DB07`)

**Fill B rows of E attributes from HL with A**

As REX 1's FillAttrs `$D909` (src/game/panels.asm).

Witness: L1 124 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 124 calls (`stage2/rec/demo-cycle` 100, `stage1/d1` 24) |
| Called from | `DrawHud`, `PanelBox` |
| Calls | `ScannerAnimate`, `WorkSpace` |
| Reads | `$5B60`-`$5B62` (`Temp1`, `Temp2`) |
| Writes | `$5801`-`$583E` (screen); `$5882`-`$5ADD` (screen); `$5B60`-`$5B62` (`Temp1`, `Temp2`) |

#### `CentreText` (`$DB2C`)

**Leftover: the column that centres the text record at IX ((32 - length) / 2 into IX+1); nothing calls it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 364 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Calls | `WorkSpace` (tail) |

#### `DevLinkReturn` (`$DB4B`)

**Leftover: POP BC: RET, the return address of the development link's command `$B5` (`$62BE`); nothing in the demo reaches it**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### DEMO: rexmove

`src/demo/rexmove.asm`

#### `SpeedUpTick` (`$D2D0`)

**The SPEED UP bonus: count down; the speed back at the end**

As REX 1's SpeedUpTick `$CFCC` (src/game/rexmove.asm).

Known only from the code: no recording runs it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `WalkRightKey` (`$D2DE`)

**Right: facing right, the speed set**

As REX 1's WalkRightKey `$CFDA` (src/game/rexmove.asm).

Witness: L1 969 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 3,567,124 t-states own (0.25 %) |
| Runs (the other recordings) | 969 calls (`stage2/rec/demo-cycle` 728, `stage1/d1` 241) |
| Called from | `MainLoop`, `CopyCells3` (tail), `CopyCells` (tail), `SaveAttrs` (tail), `FlashCells` (tail) |
| Reads | `$5B60`-`$5D19` (`Temp1`, `Temp2`, `Temp3`, `Temp4` and 25 more); `$5E66`-`$5E7F`; `$5E97`; `$5EAF`; `$5EC6`-`$5EC7` (`Score`); `$606B` (`SpeedUp`); 2 more ranges |
| Writes | `$5B66` (`Temp4`); `$5B88`-`$5B8F` (`RexFacing`, `FallSpeed`, `Jumping`, `JumpPtr` and 1 more); `$5E7A` |

#### `WalkLeftKey` (`$D2FA`)

**Left: facing left, the speed set**

As REX 1's WalkLeftKey `$CFF6` (src/game/rexmove.asm).

Witness: L1 658 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1,538 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 658 calls (`stage2/rec/demo-cycle` 503, `stage1/d1` 155) |
| Called from | `MainLoop` |
| Reads | `$606B` (`SpeedUp`) |
| Writes | `$5B88`-`$5B8F` (`RexFacing`, `FallSpeed`, `Jumping`, `JumpPtr` and 1 more) |

#### `RexWalk` (`$D317`)

**Move Rex by RexSpeed in his facing unless a solid cell; at the edges ExitLeft / ExitRight**

As REX 1's RexWalk `$D013` (src/game/rexmove.asm).

Witness: L1 6540 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 20 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,540 calls (`stage2/rec/demo-cycle` 5,039, `stage1/d1` 1,501) |
| Called from | `MainLoop` |
| Calls | `IsSolid`, `ExitRight` (tail) |
| Reads | `$5B83`-`$5B8F` (`RexX`, `RexY`, `Room`, `RoomColumn` and 5 more); `$5EA2`-`$5EA3` (`RexCellPtr`) |
| Writes | `$5B83`-`$5B8F` (`RexX`, `RexY`, `Room`, `RoomColumn` and 5 more) |

#### `IsSolid` (`$D36B`)

**Z if the cell at HL is solid (SolidCells: 2, 4, 5, 6, 9); the type found in A**

Changed from REX 1's IsSolid `$D06C` (src/game/rexmove.asm).

Witness: L1 32693 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 32,693 calls (`stage2/rec/demo-cycle` 24,941, `stage1/d1` 7,752) |
| Called from | `Climb`, `ScannerTurn`, `WalkRight`, `WalkLeft`, `ObjectJump`, `RexWalk`, `RexJump` |
| Calls | `InList` (falls into) |
| Reads | `$E1E2`-`$E1E9` (`RoomGrid+67`); `$E1FC`-`$E459` (`RoomGrid+93`, `RoomGridPlay`); `$E46D`-`$E472` (`RoomGridPlay+622`); `$E48D`-`$E491` (`RoomGridPlay+654`); `$E4AD`-`$E4B1` (`RoomGridPlay+686`); `$E4CF`-`$E4D0` (`RoomGridPlay+720`) |

#### `InList` (`$D373`)

**Z if A is one of B values at DE**

As REX 1's InList `$D074` (src/game/rexmove.asm).

Witness: L1 81499 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 81,499 calls (`stage2/rec/demo-cycle` 60,263, `stage1/d1` 21,236) |
| Called from | `IsSolid` (falls into), `IsPassable` (tail) |
| Reads | `$D395`-`$D3A0` (`SolidCells`, `PassCells`) |

#### `IsPassable` (`$D38A`)

**Z if the cell at HL lets a body or a bullet through (PassCells `$D39A`: 0, `$0E-$12`, `$14`)**

Changed from REX 1's IsPassable `$D08B` (src/game/rexmove.asm).

Witness: L1 48806 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 48,806 calls (`stage2/rec/demo-cycle` 35,322, `stage1/d1` 13,484) |
| Called from | `StepShot`, `ObjectFall`, `RexFall` |
| Calls | `InList` (tail) |
| Reads | `$E20F`-`$E21B` (`RoomGridPlay+16`); `$E22F`-`$E23B` (`RoomGridPlay+48`); `$E250`-`$E497` (`RoomGridPlay+81`); `$E4B2`-`$E4B4` (`RoomGridPlay+691`); `$E4CD`-`$E4F2` (`RoomGridPlay+718`) |

#### `ExitRight` (`$D3A1`)

**Rex at the right edge: to the room RoomRight `$5B91` at X `$08`**

As REX 1's ExitRight `$D0B1` (src/game/rexmove.asm).

Witness: L1 4 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage2/rec/demo-cycle` 3, `stage1/d1` 1) |
| Called from | `RexWalk` (tail) |
| Calls | `ToMainLoop` (tail) |
| Reads | `$5B91` (`RoomRight`) |
| Writes | `$5B83`-`$5B85` (`RexX`, `RexY`, `Room`) |

#### `StartJump` (`$D3B2`)

**Up: a jump if Rex stands (not jumping or falling)**

As REX 1's StartJump `$D0C2` (src/game/rexmove.asm).

Witness: L1 368 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 368 calls (`stage2/rec/demo-cycle` 292, `stage1/d1` 76) |
| Called from | `MainLoop` |
| Reads | `$5B89`-`$5B8A` (`FallSpeed`, `Jumping`) |
| Writes | `$5B8A`-`$5B8E` (`Jumping`, `JumpPtr`) |

#### `RexJump` (`$D3D4`)

**One step of the jump: up by JumpSteps unless a solid cell above; off the top ExitUp**

As REX 1's RexJump `$D0E4` (src/game/rexmove.asm).

Witness: L1 6540 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,540 calls (`stage2/rec/demo-cycle` 5,039, `stage1/d1` 1,501) |
| Called from | `MainLoop` |
| Calls | `IsSolid` |
| Reads | `$5B84`-`$5B8E` (`RexY`, `Room`, `RoomColumn`, `RexFacing` and 3 more); `$5EA2`-`$5EA3` (`RexCellPtr`); `$D3C8`-`$D3D2` (`JumpSteps`) |
| Writes | `$5B84`-`$5B8E` (`RexY`, `Room`, `RoomColumn`, `RexFacing` and 3 more) |

#### `Land` (`$D405`)

**Stop the jump and the fall; Rex on the cell's top**

As REX 1's Land `$D11A` (src/game/rexmove.asm).

Witness: L1 18 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 runs of its first instruction, entered by a jump (`stage2/rec/demo-cycle` 12, `stage1/d1` 6) |

#### `RexFall` (`$D41A`)

**Rex falls when no floor is under him; off the bottom to RoomDown `$5B93`, or death with no exit**

As REX 1's RexFall `$D14D` (src/game/rexmove.asm).

Witness: L1 6540 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,540 calls (`stage2/rec/demo-cycle` 5,039, `stage1/d1` 1,501) |
| Called from | `MainLoop` |
| Calls | `RexDies`, `CellPointer`, `IsPassable` |
| Reads | `$5B83`-`$5B93` (`RexX`, `RexY`, `Room`, `RoomColumn` and 9 more); `$E26B`-`$E45C` (`RoomGridPlay+108`); `$E473`-`$E474` (`RoomGridPlay+628`); `$E48E`-`$E494` (`RoomGridPlay+655`); `$E4B2`-`$E4B3` (`RoomGridPlay+691`); `$E4CD`-`$E4D3` (`RoomGridPlay+718`); 1 more ranges |
| Writes | `$5B7C`-`$5B8A` (`SpriteX`, `SpriteY`, `SpriteWidth`, `SpriteHeight` and 8 more) |

### DEMO: collisions

`src/demo/collisions.asm`

#### `EnemyBulletsHitRex` (`$D48C`)

**Each enemy bullet in Rex's box: the shield takes it (faster drain), else Rex dies**

As REX 1's EnemyBulletsHitRex `$D1B9` (src/game/collisions.asm).

Witness: L1 6752 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,752 calls (`stage2/rec/demo-cycle` 5,220, `stage1/d1` 1,532) |
| Called from | `MainLoop` |
| Calls | `ShieldDrainFast`, `ShieldHitSound` |
| Reads | `$5B83`-`$5B84` (`RexX`, `RexY`); `$5D57`-`$6CC6` (`DevLink`, `DevLinkState`, `Unused62FE`, `Font` and 2 more) |
| Writes | `$5D5D`-`$5DB7`; `$5DD5` |

#### `ObjectHitsRex` (`$D4E8`)

**The object at IX against Rex: its box; with the shield on it dies (points, the shield drained), else Rex dies unless a pod; pods are taken; then Rex's 30 bullets against it (as part 1's BulletsHitObject); the last hit on a kind 0 from behind turns it**

Witness: L1 21382 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 3,137,517 t-states own (0.22 %) |
| Runs (the other recordings) | 21,382 calls (`stage2/rec/demo-cycle` 15,092, `stage1/d1` 6,290) |
| Called from | `CellsUnderRex`, `TutorRoom4`, `AtFrame`, `TutorPanels`, `HudSweep`, `HudTexts`, `TutorTexts`, `TutorScript0`, `ObjectCollide`, `MineBurst` |
| Calls | `ShowPoints`, `ShieldDrainFast`, `HitObject`, `HitObjectHard`, `TakePowerPod`, `TakeBombPod`, `BonusRoulette`, `StartSfx` |
| Reads | `$5B83`-`$5B84` (`RexX`, `RexY`); `$5B95`-`$6B04` (`DevLink`, `DevLinkState`, `Unused62FE`, `Font` and 2 more); `$D763`-`$D772` (`l_D756+13`); `$D787`-`$D796` (`l_D787`, `RouletteEnd`); `$D7AE`-`$D7C0` (`PrizeRapidShots+12`, `SoundReset`); `$D832`-`$D855` (`StartSfxIY+54`, `SfxMixer`, `SfxMixerBits`); 1 more ranges |
| Writes | `$5B9B`-`$5C13`; `$5DA8`; `$5F06`-`$5F0A`; `$5F21`; `$5F38`; `$5F4F`; 4 more ranges |

#### `HitObject` (`$D634`)

**A hit: the flash picture, the object turned and paused; no combo score**

Changed from REX 1's HitObject `$D3C2` (src/game/collisions.asm).

Witness: L1 14 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 10,884 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage2/rec/demo-cycle` 14) |
| Called from | `ObjectHitsRex` |
| Calls | `ShowPoints` (tail), `AddScore`, `StartFall` |
| Reads | `$5E9C` (`Weapon`); `$5EF8`; `$5F0F`; `$5F26`; `$D855` (`SfxMixerBits`) |
| Writes | `$5EC2`-`$5EC6` (`KillFlashPtr`, `ComboCount`, `ComboTimer`); `$5EF8`-`$5F38` |

#### `HitObjectHard` (`$D688`)

**A bullet on a kind 6 (the hit foot man): the flash renewed, more hits needed**

Changed from REX 1's HitObjectHard `$D41F` (src/game/collisions.asm).

Witness: L1 10 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | 195 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,111,852 t-states own (0.08 %) |
| Runs (the other recordings) | 10 calls (`stage2/rec/demo-cycle` 10) |
| Called from | `CellsUnderRex`, `TutorTexts`, `ObjectHitsRex` |
| Calls | `AddScore`, `TakePowerPod`, `BonusRoulette` |
| Reads | `$5E9C` (`Weapon`); `$5EC2`-`$5EC6` (`KillFlashPtr`, `ComboCount`, `ComboTimer`); `$D832`-`$D857` (`StartSfxIY+54`, `SfxMixer`, `SfxMixerBits`) |
| Writes | `$5EC2`-`$5EC6` (`KillFlashPtr`, `ComboCount`, `ComboTimer`); `$5EFF`-`$5F21`; `$D857` (`SfxMixerBits+2`) |

#### `TakePowerPod` (`$D6CC`)

**The power pod (`$FE`): PowerGain, twice for a big one, the pod sound**

Changed from REX 1's TakePowerPod `$D46C` (src/game/collisions.asm).

Witness: L1 22 (d1, demo-cycle).

[Animation: `TakePowerPod` at work](img/routines/TakePowerPod.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 747,333 t-states own (0.05 %) |
| Runs (the other recordings) | 22 calls (`stage2/rec/demo-cycle` 18, `stage1/d1` 4) |
| Called from | `ObjectHitsRex`, `HitObjectHard` |
| Calls | `PowerGain`, `BonusRoulette`, `StartSfx` |
| Reads | `$5F0B`; `$5F22`; `$5F39`; `$5F50`; `$5F67`; `$5F7E`; 5 more ranges |
| Writes | `$5ECB` (`FadeStepIndex`); `$5F02`; `$5F19`; `$5F30`; `$5F47`; `$5F5E`; 3 more ranges |

#### `TakeBombPod` (`$D6F4`)

**The bomb pod (`$FD`): Bombs + 1 up to 3, the HUD, the sound**

As REX 1's TakeBombPod `$D494` (src/game/collisions.asm).

Witness: L1 3 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage2/rec/demo-cycle` 2, `stage1/d1` 1) |
| Called from | `ObjectHitsRex` |
| Calls | `ShowBombs`, `StartSfx` |
| Reads | `$5EF5` (`Bombs`) |
| Writes | `$5EF5` (`Bombs`); `$5FA3` |

#### `BonusRoulette` (`$D716`)

**The bonus pod (`$FC`): the panel spins by itself and slows to a stop (no fire key); only 100 RAPID SHOTS gives anything, the other prizes show and pass**

Changed from REX 1's BonusRoulette `$D4B6` (src/game/collisions.asm).

Witness: L1 1 (demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 5,513,090 t-states own (0.38 %) |
| Runs (the other recordings) | 1 call (`stage2/rec/demo-cycle` 1) |
| Called from | `ObjectHitsRex`, `HitObjectHard`, `TakePowerPod` |
| Calls | `PrintBoxed`, `BufferToScreen`, `PrintText`, `Random2`, `CopyAttrs`, `Delay`, `SoundReset`, `SoundSilence`, `SaveScreen` |
| Reads | `$6068`-`$6078` (`BonusRoll`, `Immune`, `SpeedUp`, `SpeedUpPhase` and 7 more); `$D70E`-`$D70F` (`BonusTextTable+2`); `$D839`-`$D857` (`StartSfxIY+61`, `SfxMixer`, `SfxMixerBits`) |
| Writes | `$5EC9`-`$5ECA` (`RapidShotsOn`, `RapidShotsLeft`); `$5F02`; `$6068`-`$6078` (`BonusRoll`, `Immune`, `SpeedUp`, `SpeedUpPhase` and 7 more) |
| Ports out | `$BFFD`, `$FFFD` |

### DEMO: sound

`src/demo/sound.asm`

#### `SoundReset` (`$D7B2`)

**The channels free, the mixer `$38` (tones on, noise off), silence**

As REX 1's SoundReset `$D5AE` (src/game/sound.asm).

Witness: L1 47 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 47 calls (`stage2/rec/demo-cycle` 39, `stage1/d1` 8) |
| Called from | `NewGame`, `WaitQuiet`, `PanelClose`, `TutorPanelFlash`, `TutorPanelPower`, `DrawRoom`, `BonusRoulette` |
| Calls | `SoundSilence`, `WriteMixer` |
| Reads | `$DA36`-`$DA52` (`Channels`) |
| Writes | `$DA36`-`$DA59` (`Channels`, `Mixer`) |

#### `SoundSilence` (`$D7DB`)

**The three volumes (registers 8-10) to 0**

As REX 1's SoundSilence `$D5D7` (src/game/sound.asm).

Witness: L1 89 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 89 calls (`stage2/rec/demo-cycle` 75, `stage1/d1` 14) |
| Called from | `WaitQuiet`, `PanelOpen`, `TutorPanelFlash`, `TutorPanelPower`, `TutorNextRoom`, `DemoPause`, `DrawRoom`, `BonusRoulette`, `SoundReset` |
| Calls | `SoundWrite` |

#### `StartSfx` (`$D7EB`)

**Start the effect at DE (saves IX, IY, BC)**

As REX 1's StartSfx `$D5E7` (src/game/sound.asm).

Witness: L1 3103 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,103 calls (`stage2/rec/demo-cycle` 2,304, `stage1/d1` 799) |
| Called from | `DrawRex`, `ShowPoints`, `ShieldHitSound`, `RestartMarker`, `Materialise`, `Dematerialise`, `CellsUnderRex`, `FindSlot`, `EnemyShotSound`, `ShotStopped`, `ObjectHitsRex`, `TakePowerPod`, `TakeBombPod` |
| Calls | `StartSfxIY` |

#### `StartSfxIY` (`$D7FC`)

**The descriptor at IY into its channel; the mixer bits for tone and noise**

As REX 1's StartSfxIY `$D5F8` (src/game/sound.asm).

Witness: L1 3103 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,103 calls (`stage2/rec/demo-cycle` 2,304, `stage1/d1` 799) |
| Called from | `StartSfx` |
| Calls | `WriteMixer` (tail) |
| Reads | `$D967`-`$DA0F` (`SfxGun`, `SfxEnemyShot`, `SfxLaser`, `SfxSpray` and 11 more); `$DA2A`-`$DA30` (`SfxRecharge`); `$DA59` (`Mixer`) |
| Writes | `$DA36`-`$DA59` (`Channels`, `Mixer`) |

#### `WriteMixer` (`$D886`)

**Register 7 = the mixer `$D855`**

As REX 1's WriteMixer `$D682` (src/game/sound.asm).

Witness: L1 3150 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,150 calls (`stage2/rec/demo-cycle` 2,343, `stage1/d1` 807) |
| Called from | `SoundReset`, `StartSfxIY` (tail) |
| Calls | `SoundWrite` |
| Reads | `$DA59` (`Mixer`) |

#### `SoundStep` (`$D890`)

**Each of the 3 channels: ChannelStep, then its tone (registers 0-5) or noise period (6)**

As REX 1's SoundStep `$D68C` (src/game/sound.asm).

Witness: L1 13504 (d1, demo-cycle).

[Animation: `SoundStep` at work](img/routines/SoundStep.gif)

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 649,968 t-states own (0.04 %) |
| Runs (the other recordings) | 13,504 calls (`stage2/rec/demo-cycle` 10,439, `stage1/d1` 3,065) |
| Called from | `MainLoop`, `DroneOrbit`, `WorkSpace` |
| Calls | `ChannelStep`, `SoundWrite` |
| Reads | `$8C0A`-`$8C29` (`l_8BEF+27`); `$8CAA`-`$8CE9` (`MainAnimate+4`, `MainLoopLeftover`, `ShieldToggle`); `$A093`-`$A096` (`AnimateRestart+8`); `$A1F1`-`$A1F6` (`DroneOrbit+82`); `$A233`-`$A238` (`DronePictures+20`); `$ABDD`-`$AC1C` (`TutorText0+63`, `TutorText2`); 3 more ranges |
| Writes | `$4001`-`$4064` (screen); `$4101`-`$4164` (screen); `$4201`-`$4264` (screen); `$4301`-`$4364` (screen); `$4401`-`$4464` (screen); `$4501`-`$4564` (screen); 4 more ranges |

#### `ChannelStep` (`$D8DF`)

**One step of the channel at IX: the volume written, the tone and volume changed, the next step; at the end the channel silent and free**

As REX 1's ChannelStep `$D6DB` (src/game/sound.asm).

Witness: L1 41533 (d1, demo-cycle).

| | |
| --- | --- |
| Runs (c1: power-on, side 1 of the original at ROM speed on the 128K, the menu and play on level 1) | run into, not called, 61,028 t-states own (0.00 %) |
| Runs (the other recordings) | 40,512 calls (`stage2/rec/demo-cycle` 31,317, `stage1/d1` 9,195) |
| Called from | `DroneOrbit`, `Multiply`, `ReadExits`, `SoundStep`, `WorkSpace` |
| Calls | `DroneOrbit`, `WriteVolume`, `SoundWrite`, `WorkSpace` |
| Reads | `$A093`-`$A095` (`AnimateRestart+8`); `$D96E`-`$DA5B` (`SfxGun+7`, `Channels`) |
| Writes | `$5800`-`$5891` (screen); `$58E4`-`$58EE` (screen); `$5904`-`$590E` (screen); `$5924`-`$5AFF` (screen); `$A093`-`$A095` (`AnimateRestart+8`); `$DA36`-`$DA4D` (`Channels`) |

#### `WriteVolume` (`$D948`)

**Register 8 + channel = the channel's volume / 16**

As REX 1's WriteVolume `$D744` (src/game/sound.asm).

Witness: L1 12728 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,728 calls (`stage2/rec/demo-cycle` 9,253, `stage1/d1` 3,475) |
| Called from | `ChannelStep` |
| Calls | `SoundWrite` |
| Reads | `$DA3D`-`$DA5B` (`Channels+7`, `Mixer`, `ChannelNumber`) |

#### `SoundWrite` (`$D95D`)

**AY register D = E: OUT (`$FFFD`),D, OUT (`$BFFD`),E**

As REX 1's SoundWrite `$D759` (src/game/sound.asm).

Witness: L1 43117 (d1, demo-cycle).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 43,117 calls (`stage2/rec/demo-cycle` 31,564, `stage1/d1` 11,553) |
| Called from | `SoundSilence`, `WriteMixer`, `SoundStep`, `ChannelStep`, `WriteVolume` |
| Ports out | `$BFFD`, `$FFFD` |
