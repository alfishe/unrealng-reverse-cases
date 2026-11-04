# Advanced Nether Earth vs Nether Earth: the gameplay logic, routine by routine

What this answers: which of Nether Earth's (NE, Argus 1987) gameplay routines and tables Advanced Nether Earth
(ANE, Eternity Industry 1998) keeps byte for byte, changes or replaces, and whether the "some bugs were fixed" of
the authors' own text ([12](12-claims.md)) shows in the code.

## The evidence

| What | Where |
| --- | --- |
| ANE's game image in play | recording `work/stage1/s2/session.ttd` (the TOSEC SCL, Pentagon 128, TR-DOS, input script `inputs/scl-play.txt`: `RUN "A_NETHER"`, the intro, SPACE, boot menu `1`, game menu `0`, idle play), frame 11500: `work/images/scl-play-cpu.bin` (the Z80 view: bank 5 at `$4000`, bank 2 at `$8000`, bank 0 at `$C000`) and `scl-play-bank0..7.bin` |
| NE's image | `games/nether-earth/work/mkgame/original.bin` (the loader's image), entries from `games/nether-earth/src/game/game.ann` (563 entries), instruction boundaries from `games/nether-earth/build/game.lst` |
| the per-entry match | `python3 tools/ne_match.py --image work/images/scl-play-cpu.bin@0000:play --image work/images/scl-play-bank{1,3,4,6,7}.bin@C000:bN --out work/stage1/match.tsv --summary` |
| the instruction diffs | `python3 tools/entry_diff.py --ane work/images/scl-play-cpu.bin NAME ...` (`*` a different instruction, `~` the same instruction with another 16-bit operand) |
| a cross-check | the same match on a live instance at the same point (`work/stage1/explore/play-cpu.bin`, not a recording) gives the same statuses except `DrawSprite` (below) |

The image is taken in play, after ANE's start-up: it is the code that runs, whatever ANE patched at load time.

## The answer in one line

**ANE's gameplay logic is NE's, byte for byte, at NE's own addresses.** Every routine and table of the robots, shots,
damage, capture, production, the enemy commander, the nuclear bomb, the construction rules and the game turn is
unchanged; every NE bug of NE doc 10.12 is still there. No claimed bug fix is in the gameplay code. What ANE changed
is around the game: the interrupt (AY music in play), the save and load (disk instead of tape), the end of the game
(the "Dead End" and "Final Cut" screens loaded from disk), the main menu, the font and every text (Russian).

## 1. Every byte that differs in NE's code range

`$A600-$D7D2` (NE's code, texts and tables), NE's image against ANE's in play, runs of differing bytes grouped by
the NE entry that holds them (a script over the two images; nothing else differs in this range):

| NE entry | Bytes | What it is |
| --- | --- | --- |
| `Start` `$A600` | 17 | the IM 2 table moved: see 2.1 |
| `EnterPlay` `$A698`, `ConstructionMenu` `$C85F`, `StartRobot` `$CBA6`, `GameStop` `$AF0B` | 2-5 each | the operand `Handler` (`$FDFE` -> `$696A`) |
| `PlayLoop` `$A713`, `$A71A` | 4 | the restart address (`$A600` -> `$A5EF`) and the save key: 2.3 |
| `UnusedTapeCode` `$AE31`, `GameOverWait` `$AEFE`, `LoadError` `$C28B` | 2 each | the restart address `$A600` -> `$A5EF` |
| `CheckGameEnd` .. `GameWon` `$AE77-$AEE2` | 108 | the end of the game: 2.4 |
| `PlayInterrupt` `$D582` | 3 | `CALL ShowRadar` -> `JP $67B1`: AY music, 2.2 |
| `PrintChar` `$D4B8`, `PrintBigChar` `$D4E1` | 2 each | the font base `$6680` -> `$C400` (the Cyrillic font at `$C500`) |
| `MainMenuKeys` `$C19E`, `LoadGameBlocks` `$C248`, `SaveGameBlocks` `$C2E5`, the menu tune and `TitleColourCycle` `$C4A0-$C848` | 7 + 10 + 16 + 937 | the menu and the tape code replaced: 2.3 |
| `DrawSprite` `$CF3F`, `FillViewCorner` `$D038`, `$D041` | 1 + 2 | **not a change**: self-modified operands (NE game.ann: "the height of the next sprite at `$CF3F`", "the corner fill and skip counts at `$D038` / `$D041`"), whatever the last call wrote |
| 27 text entries (`RobotMenuText`, `OrderName1-8`, `OrdersMenuText`, `DestroyMenuText`, `CaptureMenuText`, `CombatMenuText`, `StatusPanelText`, `PartNamesText`, `ResourceNamesText`, the menu and key names, ...) | 8-131 each | the texts in Russian (Latin letters that the Cyrillic font draws), same lengths and places |

## 2. What the changed code does

### 2.1 The IM 2 table and `Handler` moved out of `$C000-$FFFF`

```text
NE  A600 DI / LD SP,0 / LD HL,$FE00 / LD BC,$00FD ... LD ($FDFD),A / LD HL,$D59C / LD ($FDFE),HL / LD A,$FE
ANE A5EF DI / LD SP,0 / LD A,$11 / LD BC,$7FFD / OUT (C),A / CALL $C000 / ...      (a new start in front)
ANE A604 LD HL,$6800 / LD BC,$0069 ... LD ($6969),A / LD HL,$6780 / LD ($696A),HL / LD A,$68
```

The vector table is `$6800-$6900` (257 x `$69`), the `JP` at `$6969`, `Handler` at `$696A`, `I` = `$68`. NE kept them
at `$FDFD-$FF00`, in the bank that ANE now pages out while the music plays. `$6780-$697F` was NE's font, which moved
to bank 0 `$C500`. Every `LD (Handler),HL` of NE follows (`EnterPlay`, `ConstructionMenu`, `StartRobot`, `GameStop`).
The handlers themselves (`StartInterrupt` `$D59C`, `PlayInterrupt` `$D566`) are unchanged but for 2.2.

### 2.2 `PlayInterrupt`: AY music in play

```text
NE  D582 CALL $D59E        ; ShowRadar
ANE D582 JP $67B1          ; 67B1 CALL $D59E (ShowRadar), page bank 1 (OUT $7FFD,$11), CALL $C005 (the PT3 player,
                           ;      "PT 3 Player v1.0 by Nick of GDC", bank 1), page back, JP $D585
```

The radar, `TurnFrames` and the shot sounds run as in NE; a PT3 tune plays on the AY every frame (bank 1 holds the
player and "ProTracker 3.1 compilation of 08.12.96 ... X-MAN-MUSIC"). Not gameplay.

### 2.3 Save and load: disk instead of tape

```text
NE  A71A CALL $C28D        ; SaveGame (key 5 in play): the tape
ANE A71A JP $C2CC          ; C2CC: RadarDirty = 1, copy Shots ($D7D3, 45) and Buildings ($FF01, 168) after
                           ;       SaveShots ($D92B), DI, JP $6905 (the disk code)
NE  C2E5 CALL $C30F / LD ($5B00),DE / LD HL,$0900 ...   ; SaveGameBlocks: checksum, header, SA-BYTES
ANE C2E5 JP $6905 / NOP x 15
NE  C248 LD HL,($5B00) / AND A / SBC HL,DE / LD A,H / OR L / JR NZ,LoadError   ; LoadGameBlocks: checksum test
ANE C248 NOP x 10
NE  C192 HALT / CALL TitleColourCycle ... CALL MenuMusic ... CALL TitleColourCycle   ; MainMenuKeys
ANE C192 NOP ...           ; no title colours, no beeper tune in the menu (ANE's own menu and AY tune instead)
```

The record saved is NE's (the same blocks); the checksum test of the load is gone. The disk code at `$6905` and the
load path from ANE's menu item `5` ("ЗАГРУЗКА") are stage-2 work (not traced yet).

### 2.4 The end of the game

```text
NE  AE6B LD A,(EnemyBuildings) / OR A / JR Z,GameWon / LD A,(PlayerBuildings) / OR A / RET NZ
         CALL GameStop / CALL PrintInline "...lost..." ...
ANE AE6B (the same tests, the same bytes)
         CALL $AE94 (silence the AY: registers 0-14 = 0) / LD A,$3F / LD I,A / IM 1 / EI
         OUT ($7FFD),$13 / JP $D2EF   (bank 3: the "Dead End" screen)
NE  AEB1 CALL GameStop / CALL PrintInline "...won..."
ANE AEB1 CALL $AE94 / LD A,$3F / LD I,A / IM 1 / EI / OUT ($7FFD),$16 ...   (bank 6: the "Final Cut")
```

The win and loss conditions are NE's: the enemy has no warbase left (`$FD42` = 0) -> won; we have none (`$FD3A` = 0)
-> lost. Only what follows is new. (The 2017 `ANE_FC.TRD` is this Final Cut alone: see [12](12-claims.md).)

## 3. The gameplay routines, one by one

Status from `work/stage1/match.tsv` (`same` = all of the entry's bytes at NE's address in ANE's image).

| NE routine / table | NE doc | ANE |
| --- | --- | --- |
| `RobotStep` `$B154`, `UpdateRobot` `$B0FA`, `WorldTurn` `$B0CA` | 10.4 | same |
| `SteerByOrder` `$B222`, `FindTargetBuilding` `$B34D`, `ConsiderBuilding` `$B36C`, `FindNearestOpponent` `$B41D`, `TargetBuildingTable` `$B3D5` | 10.5 | same |
| `SpotEnemies` `$B626`, `ScanLane` `$B66E`, `LaneSteps` `$B6B0` | 10.4 | same |
| `FireShot` `$B6D6`, `UpdateShot` `$B70D`, `MoveShot` `$B724` (the damage formula), `ShotGone` `$B7EA`, `FindFreeShot` `$B6B8` | 10.6 | same |
| `FreeDirections` `$B513`, `CanMove*` `$B557-$B5B1`, `TestCell` `$B5CD`, `TurnOrStep` `$B471`, `StepPosition` `$B4B9`, `GroundUnderFootprint` `$B5D6` | 10.4 | same |
| `SetStepDelay` `$B5F3`, `StepDelays` `$B61D` | 10.4 | same |
| `GameTurn` `$AD62`, `GameTurnEnd` `$AD90` (the capture count) | 10.1, 10.7 | same |
| `DailyProduction` `$AE38`, `ProduceSide` `$AE4E`, `AddCapped` `$AE62` | 10.2 | same |
| `GiveFactory` `$BB61`, `GiveWarbase` `$BB86`, `SetBaseOwner` `$BBB9`, `CountBases` `$BB09`, `CountLiveRobots` `$BB50` | 10.7 | same |
| `DestroyFactory` `$BBD8`, `DestroyWarbase` `$BBF9`, `MarkBaseDestroyed` `$BC1C` | 10.9 | same |
| `EnemyCommander` `$B7F4` (659 bytes) | 10.8 | same |
| `NuclearFlash` `$BA87`, `NuclearRumble` `$BAEE` | 10.9 | same |
| `ConstructionMenuLoop` `$CA0F`, `RefundPart` `$CAC1`, `PartCosts` `$CAF0` | 10.3 | same |
| `StartRobot` `$CB52` | 10.3 | same but `Handler`'s address (2.1) |
| `ConstructionMenu` `$C849` | 10.3 | same but `Handler`'s address |
| `NewGameSetup` `$A62D` (the start resources, the map) | 10.1 | same |
| `BuildMap` `$BC6F`, `PlaceBases` `$BCF9`, the level data `$BDA9-$C08C` | 10.1 | same |
| `RobotMenuChoose` `$A7E4`, `OrdersMenuChoose` `$A9EC`, `SetOrder` `$ABC8`, `DirectControl` `$A941`, `CombatMenuCode` `$AC7C` | 10.5 | same (their texts translated) |
| `CheckGameEnd` `$AE6B` | 10.10 | the tests same; the ending replaced (2.4) |
| `MoveShip` `$AF11`, `CheckShipMove` `$B052`, `ReadControls` `$D38A`, `KeyTable` `$D3CC` | 05 | same |
| `DrawRobotPart` `$CEFD`, `DrawView` `$CCBD` and the whole view module | 06 | same (`DrawSprite`, `FillViewCorner`: self-modified operands only) |

### 3.1 The tables, value by value

| Table | NE | ANE |
| --- | --- | --- |
| `PartCosts` `$CAF0` (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics; then the resource each pays from) | 3 5 10 2 4 4 20 3 / 6 6 6 5 4 3 2 1 | equal |
| `PartHeights` `$D7B4` | 11 7 8 6 6 7 7 7 | equal |
| `TerrainHeights` `$D7BC` | 0 0 2 2 2 2 3 3 6 6 6 6 0 0 0 7 15 7 15 0 0 99 0 | equal |
| `BuildingHeights` `$CE5F` | 19 15 15 15 15 15 15 26 26 | equal |
| `BuildingTops` `$B0C1` | 15 22 21 21 22 22 22 25 25 | equal |
| `StepDelays` `$B61D` | 6 4 3 8 6 3 9 7 4 | equal |
| `LaneSteps` `$B6B0` | 1 0 -1 -1 0 2 0 -2 | equal |
| `BuildingSprites` `$CE56` | 44 40 37 35 32 29 23 42 43 | equal |
| `KeyTable` `$D3CC` (the default keys) | NE's 24 bytes | equal |

The damage (`MoveShot`: ((60 - (height + ground)) / 4) x (weapon + 1)), the ranges (5 steps, 7 for missiles, +1 with
electronics) and the capture count (144 turns) are inside routines that are the same bytes.

### 3.2 NE's known bugs (NE doc 10.12)

| Bug | NE routine | ANE |
| --- | --- | --- |
| the 24th-robot pad bug (a full table writes the new robot's values over enemy slot 24) | `ConstructionMenu` `$C849`, `PlayLoop` `$A6F3` | kept: `ConstructionMenu` differs only in `Handler`'s address, `PlayLoop` `$A69A-$A711` is the same bytes |
| the building target pointer past its table | `SteerByOrder` `$B2B8` | kept (same) |
| values over 99 print a wrong tens digit ("D0") | `PrintTensUnits` `$D407` | kept (same) |
| a refused chassis swap leaves the robot without a chassis | `ConstructionMenuLoop` `$CA0F` | kept (same) |
| a restarted menu tune keeps a voice's state | `MenuMusic` `$C4A7` | gone with the beeper tune (replaced) |
| `PrintDigitColumn` past 9 | `PrintDigitColumn` `$D2E3` | kept (same) |
| a destroyed base recaptured as a live warbase | `GameTurnEnd` `$AD90`, `SetBaseOwner` `$BBB9` | kept (same) |
| `DrawRobotPart` at facing 0 | `DrawRobotPart` `$CEFD` | kept (same) |
| `MoveShot` with no map-edge check | `MoveShot` `$B724` | kept (same) |
| never-run `UnusedTapeCode` (keys 6 + 7) | `$AE29` | kept, its return address now `$A5EF` |

## 4. The claims against the code

| Claim ([12](12-claims.md)) | In the code |
| --- | --- |
| "Исправлены некоторые баги" (some bugs found while working on the game were fixed), NETHER+.W | **not found in the gameplay code**: no gameplay byte differs from NE (section 1). Read with the same text's history, the bugs are most likely those of the cracked disk versions it complains about (state loads replaced by `RET`, saves that did not work), fixed by going back to a tape original and adding a working disk save / load (2.3) |
| "Сделаны НОРМАЛЬНЫЕ load/save процедуры" (proper load / save, Paracels' turbo WG93 driver) | confirmed in part: the save key jumps to new disk code `$6905` (2.3); the driver itself is stage-2 work |
| AY music in the game, title, Final Cut and Dead End screens, new menu and intro | confirmed: 2.2, 2.4, the screenshots |
| help "Цена" (prices): bipod 5 | not so in the code: `PartCosts` gives bipod 3 (NE's); the other prices in the help (tracks 5, anti-grav 10, cannon 2, missiles 4, phasers 4, A-bomb 20, electronics 3) agree with the table |
| help: missiles at more than 50 % damage fire one missile, half the power | not in the code: `MoveShot`'s damage depends on the weapon and the target's height only (NE 10.6), same bytes |
| help: electronics raise the speed of the defensive reaction | the code has NE's rules only (same bytes): electronics lengthen the sight ahead from 10 to 12 cells (`SpotEnemies` / `ScanLane`) and a shot's range by one step (`FireShot`); NE doc 07 7.4, 12 |
| help: three robots destroyed in one place make a pile even anti-gravs cannot cross | NE's rule: a wreck is a 2 x 2 patch of terrain type 6 / 7, height 3 (`RobotDestroyed` `$B116`, NE 10.6); no stacking in the code |
| help: "up to 50 robots on each side" | not so: 24 slots a side (`$DA00` / `$DB80`, NE 10.3), same code |
| help: an order takes a limited number of robots ("usually not more than four") | no such limit found in `SetOrder` `$ABC8` (same as NE; NE 10.5 has none) |
| help: capture by standing about 45 s in the yard | NE's 144 turns of 10 frames = 28.8 s at 50 Hz on the turn clock alone; the turns stretch with the work, so 45 s is plausible as a player's measure |
| help: shots do not pass through buildings and rubble, yet two robots may fire at each other through a wall | NE's behaviour, same code: `SpotEnemies` stops only at objects (map bit 6), so a wall of terrain does not hide an opponent, while `UpdateShot` / `MoveShot` end a shot over ground of height 10 or more and at any object (NE doc 10.4, 10.6) |

The help, the intro and NETHER+.W texts in full: [12](12-claims.md), [help-text.md](../src/res/text/help-text.md),
[nether-plus-w.txt](../src/res/text/nether-plus-w.txt).
