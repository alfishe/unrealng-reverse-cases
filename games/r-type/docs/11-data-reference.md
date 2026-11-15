# 11. Data reference

Every data entry of the game image `$7000`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: The tape BASIC and the copy of the decryption chain, The
decryption chain and the SpeedLock 7 loader, The second stage, The second stage's table, The decipher block, The
second stage's end, The loader's tail: the move to the game and the jump to the entry, Level 1 (side 2), Level 2
(side 2), Level 3 (side 2), Level 4 (side 2), Level 5 (side 2), Level 6 (side 2), Level 7 (side 2), Level 8 (side
2)) follow the game, each under its own heading with its modules, its source, its annotations and its recordings.

## texts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7000` | `ShadowLine0` | 128 | The pixel shadow, third third, pixel line 0 (128 bytes). Written and read by the sprite drawers (DrawSprite and its three variants) and copied to the screen by ScrollRows. Zeros at the entry. | `l_8869`, `ScrollRows` (`stage1/rec/ending`) | `DrawSprite`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) |
| `$7080` | `KeyPromptText` | 16 of 44 | "PRESS A KEY FOR " and the six key names DefineKeys prints | `PrintTextA` | - |
| `$7090` | `KeyNameLeft` (`KeyPromptText`+16) | 4 | "LEFT" | `PrintTextA` | - |
| `$7094` | `KeyNameRight` (`KeyPromptText`+20) | 5 | "RIGHT" | `PrintTextA` | - |
| `$7099` | `KeyNameUp` (`KeyPromptText`+25) | 5 | "UP" | `PrintTextA` | - |
| `$709E` | `KeyNameDown` (`KeyPromptText`+30) | 4 | "DOWN" | `PrintTextA` | - |
| `$70A2` | `KeyNameFire` (`KeyPromptText`+34) | 4 | "FIRE" | `PrintTextA` | - |
| `$70A6` | `KeyNameDetach` (`KeyPromptText`+38) | 6 | "DETACH" | `PrintTextA` | - |
| `$70AC` | `PilotStandByText` | 17 | `PILOT STAND BY $`: printed after a life is lost | `PrintTextA` | - |
| `$70BD` | `MissionOverText` | 14 | `MISSION OVER $`: printed when the last life is gone | `PrintTextA` | - |
| `$70CB` | `ContinueText` | 15 | "C O N T I N U E" over the countdown | `PrintTextA` | - |
| `$70DA` | `BeamMeterFull` | 1 | '@': a full step of the BEAM meter | `PrintTextA`, `PrintTextNormal` (`docs/integrate/rec/force`) | - |
| `$70DB` | `BeamMeterStep` | 1 | '>': the step being filled | `PrintTextA`, `PrintTextNormal` (`docs/integrate/rec/force`) | - |
| `$70DC` | `ScoreAwards` | 20 | The score awards: 10 pairs (place, digit) AwardScore hands to AddScore. Indexed by the low nibble of an enemy kind's byte 2 less 1: place 3 with the digits 1-9, then place 4 with 1 (100-900 and 1000 points; known only from the code and the score in the level recordings). A kind whose score nibble is 11 or 12 reads past the 10 pairs: zeros, no points (AddScore returns at E = 0). | `AwardScore`, `PrintTextA` (`stage1/rec/hiscore`) | - |
| `$70F0` | `ShadowLine0Tail` | 16 | zeros up to the next shadow line | `AwardScore` (`stage1/rec/l1`), `PrintTextA` (`stage1/rec/hiscore`) | - |
| `$7100` | `ShadowLine1` | 128 | The pixel shadow, third third, pixel line 1 | `l_8869`, `PrintTextA` (`stage1/rec/hiscore`), `ScrollRows` (`stage1/rec/ending`) | `DrawSprite`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) |
| `$7180` | `HiScoreLabel` | 8 | "HI SCORE" on the HUD | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$7188` | `BeamLabel` | 5 | "BEAM-" on the HUD | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$718D` | `LifeChar` | 1 | '%': the ship icon DrawLives repeats once a life | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$718E` | `BlankChar` | 1 | a space: DrawLives' end | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$718F` | `LevelText` | 13 of 15 | "R TYPE LEVEL 0 ": the digit is the level LoadLevel searches for | `PrintTextA`, `LevelEnd` (`stage1/rec/l1`), `LoadLevel` (`stage1/rec/l1`), `LoadLevelStart` (`stage1/rec/l8`), `LoseLife` (`stage1/rec/gameover`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `LevelEnd` (`stage1/rec/l8`), `LoadLevel` (`stage1/rec/l1`) |
| `$719C` | `LevelDigit` (`LevelText`+13) | 2 | the level's ASCII digit | `PrintTextA`, `LevelEnd` (`stage1/rec/l1`), `LoadLevel` (`stage1/rec/l1`), `LoadLevelStart` (`stage1/rec/l8`), `LoseLife` (`stage1/rec/gameover`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `LevelEnd` (`stage1/rec/l8`), `LoadLevel` (`stage1/rec/l1`) |
| `$719E` | `LoadedOkText` | 9 | "LOADED OK" | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$71A7` | `StopTapeText` | 9 | "STOP TAPE" | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$71B0` | `StartTapeText` | 10 | "START TAPE" | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$71BA` | `LoadingText` | 7 | "LOADING" | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$71C1` | `CarrierFrames` | 8 | the eight characters of a pick-up carrier's animation (k l m n o n m l), NextCarrierFrame | `PrintTextA`, `NextCarrierFrame` (`stage1/rec/l1`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$71C9` | `ScoreText` | 7 | the score: six ASCII digits and the space that ends the text. AddScore adds into it digit by digit; PrintScore prints it; InsertHiScore compares it with the table. | `AddScore`, `PrintTextA`, `CheckExtraLife` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/gameover`), `InsertHiScore` (`stage1/rec/gameover`) +2 | `AddScore`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/gameover`) |
| `$71D0` | `ScoreDirty` | 1 of 48 | scratch flags of the score and the name entry | `MoveForceShots`, `StartPlay`, `CellFree` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l1`), `ForceShotA` (`stage1/rec/l1`) +2 | `AddScoreFlag`, `ClearHits`, `ProcessHitsNext`, `StartPlay`, `CellFree` (`stage1/rec/l4`) +8 |
| `$71D1` | `FirstPlay` (`ScoreDirty`+1) | 1 | 0 before the first play: StartPlay gives the fly-in once | `StartPlay`, `FillBlock` (`stage1/rec/gameover`) | `StartPlay`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/gameover`), `LoseLife` (`stage1/rec/gameover`) |
| `$71D2` | `NameLetter` (`ScoreDirty`+2) | 1 | the letter the name entry is on | `FillBlock` (`stage1/rec/gameover`), `InsertHiScore` (`stage1/rec/hiscore`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/gameover`), `InsertHiScore` (`stage1/rec/hiscore`) |
| `$71D3` | `NamePos` (`ScoreDirty`+3) | 1 | the place in the name being typed | `FillBlock` (`stage1/rec/gameover`), `InsertHiScore` (`stage1/rec/hiscore`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/gameover`), `InsertHiScore` (`stage1/rec/hiscore`) |
| `$71D4` | `ForceShotsA` (`ScoreDirty`+4) | 6 | the reflect laser's shot pairs, 3 bytes a shot (in ClearList: 12 bytes) | `MoveForceShots`, `FillBlock` (`stage1/rec/l1`), `ForceShotA` (`stage1/rec/l1`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `ForceShotA` (`stage1/rec/l1`), `MoveForceShots` (`stage1/rec/l1`) |
| `$71DA` | `ForceShotsB` (`ScoreDirty`+10) | 6 | the second pair | `MoveForceShots`, `FillBlock` (`stage1/rec/l1`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`) |
| `$71E0` | `HitCellCount` (`ScoreDirty`+16) | 1 | the soft cells (`$FA`) gathered this frame, the index into HitCells | `CellFree` (`stage1/rec/l4`), `ProcessHitsNext` (`stage1/rec/l4`) | `AddScoreFlag`, `ClearHits`, `ProcessHitsNext`, `CellFree` (`stage1/rec/l4`), `DrawSpriteBoth` (`stage1/rec/l1`) +2 |
| `$71E1` | `HitCells` (`ScoreDirty`+17) | 31 | the (column, row) of each soft cell gathered | `ProcessHitsNext` (`stage1/rec/l4`) | `CellFree` (`stage1/rec/l4`), `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$7200` | `ShadowLine2` | 128 | The pixel shadow, third third, pixel line 2 | `l_8869`, `ScrollRows` (`stage1/rec/ending`) | `DrawSprite`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) |
| `$7280` | `RewindSide2Text` | 32 | "REWIND SIDE 2 THEN PRESS ANY KEY" | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$72A0` | `SearchingText` | 14 | "SEARCHING FOR " (then LevelText) | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$72AE` | `ErrorInLoadingText` | 16 | "ERROR IN LOADING" | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$72BE` | `CreditText` | 13 of 15 | "C R E D I T  5 ": the credits left | `PrintTextA`, `LoseLife` (`stage1/rec/gameover`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `LoseLife` (`stage1/rec/gameover`) |
| `$72CB` | `CreditDigit` (`CreditText`+13) | 2 | '5' at the start; a continue spends one | `PrintTextA`, `LoseLife` (`stage1/rec/gameover`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `LoseLife` (`stage1/rec/gameover`) |
| `$72CD` | `PressFireText` | 17 | "PRESS FIRE BUTTON" | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$72DE` | `BeamMeterEmpty` | 10 | ten '<': the empty BEAM meter | `PrintTextA`, `PrintTextNormal` (`docs/integrate/rec/force`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$72E8` | `ContinueData` | 3 of 8 | the countdown's work bytes | `Continue` (`stage1/rec/gameover`), `SoundRepeat` (`stage1/rec/gameover`), `SoundStep` (`stage1/rec/gameover`) | `Continue` (`stage1/rec/gameover`), `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `SoundStep` (`stage1/rec/gameover`) |
| `$72EB` | `ContinueRow` (`ContinueData`+3) | 5 | the countdown's colour row, read and written by Continue | `Continue` (`stage1/rec/gameover`), `SoundStep` (`stage1/rec/gameover`) | `Continue` (`stage1/rec/gameover`), `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `SoundStep` (`stage1/rec/gameover`) |
| `$72F0` | `KeyBitTable` | 5 | the bit masks `$10`, 8, 4, 2, 1 ReadKey turns a half-row bit into | `ReadKey`, `ReadKeyNext` (`stage1/rec/l3`), `ReadKeyRow` (`stage1/rec/l5`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$72F5` | `CarrierColours` | 7 | bytes CarrierDraw reads by the carrier's kind | `ReadKey`, `CarrierDraw` (`stage1/rec/l2`), `MoveCarrierA` (`stage1/rec/l1`), `ReadKeyNext` (`stage1/rec/l3`), `ReadKeyRow` (`stage1/rec/l5`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$72FC` | `ShadowLine2Tail` | 4 | zeros | `CarrierDraw` (`stage1/rec/l4`), `MoveCarrierA` (`stage1/rec/l1`) | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$7300` | `ShadowLine3` | 128 | The pixel shadow, third third, pixel line 3 | `l_8869`, `ScrollRows` (`stage1/rec/ending`) | `DrawSprite`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) |
| `$7380` | `TitleStars` | 40 | the title's star states (2 bytes a star) the star task uses while the title runs | `StarCell`, `StarStep` | `StarStep`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$73A8` | `NoText` | 5 | "()*+ ": the font draws it as "No. " before each high-score line (PrintHiScores `$76B1`) | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$73AD` | `CollapseColumns` | 6 | six bytes TitleLogo reads | `PrintTextA`, `TitleLogo` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$73B3` | `DigitChars` | 9 | '1'-'9': the place digits of the high-score table | `PrintTextA` | `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |

## titlestate

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$73FE` | `ShadowLine4` | 130 | The pixel shadow, third third, pixel line 4 (from `$7400`) | `l_8869`, `ScrollRows` (`stage1/rec/ending`) | `DrawSprite`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) |
| `$7480` | `TitleTexts` | 99 | the title page's lines: BLAST OFF AND STRIKE / THE EVIL BYDO EMPIRE / PRESS FIRE TO PLAY / 'ENTER' SELECTS KEYS / (c) 1987 BY IREM CORP. | `PrintTextA` | `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$74E3` | `EnterNameText` | 23 | `ENTER YOUR NAME PILOT $` | `PrintTextA` | `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$74FA` | `ControlBits` | 1 of 4 | the last control read: bit 0 left, 1 right, 2 down, 3 up, 4 fire, 5 detach (1 = pressed) | `ClearPlayState`, `FireBeam`, `MoveShip`, `PrintTextA`, `ReadControls` +4 | `ClearPlayState`, `ReadDetach`, `SelectControl`, `DrawSpriteFlipped` (`stage1/rec/l1`), `ReadKeys` (`stage1/rec/l1`) |
| `$74FB` | `ControlMethod` (`ControlBits`+1) | 1 | 1 Interface 2, 2 keys, 3 Kempston, 4 Sinclair / cursor, as the title's fire picked it | `ClearPlayState`, `PrintTextA` | `SelectControl`, `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$74FC` | `ControlVector` (`ControlBits`+2) | 2 | the reader of the control method, taken from ControlVectors | `PrintTextA`, `ReadControls` | `ClearPlayState`, `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$74FE` | `ShadowLine4Tail` | 130 | zeros | `PrintTextA`, `l_8869`, `ScrollRows` (`stage1/rec/ending`) | `DrawSprite`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) |
| `$7580` | `BestPilotsText` | 19 | "TODAY'S BEST PILOTS" | `PrintTextA` | `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$7593` | `ForceShotTurns` | 36 | four tables of 9 bytes: the next direction of a reflected laser by the cells around it (BounceShot) | `BounceShot` (`stage1/rec/l1`) | `BounceShot` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$75B7` | `ClearList` | 38 | The blocks ClearPlayState zeroes at every start: address, length, ...; a zero word ends it. `$4000` 6144 (the screen), `$7E00` 640 (SolidMap), `$8100` 640, `$8501` 252 (EnemySlots), `$7AD7` 28 (HitList), `$5EB4` 332 (the shots, missiles and explosions), `$8386` 109 (EnemyShots and the ship's records), `$71D4` 12 (ForceShotsA/B), `$7DF9` 7 (LevelVars). | `ClearPlayState` | `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$75DD` | `ExplosionFrames` | 24 | the objects of each explosion kind and step, DrawExplosions | `DrawExplosions` | `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$75F5` | `ShadowLine5` | 139 | zeros, then the pixel shadow's line 5 from `$7600` | `DrawExplosions`, `l_8869`, `ScrollRows` (`stage1/rec/ending`) | `DrawSprite`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) |

## screen

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$76F5` | `RewindTapeText` | 11 | "REWIND TAPE" | `PrintTextA` (`stage1/rec/ending`) | `DrawSpriteFlipped` (`stage1/rec/l1`) |
| `$7700` | `ShadowLine6` | 128 | The pixel shadow, third third, pixel line 6 | `l_8869`, `ScrollRows` (`stage1/rec/ending`) | `DrawSprite`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) |
| `$7780` | `DefinedKeys` | 12 | Six keys as (half-row port high byte, bit mask), DefineKeys / ReadKeys. As loaded: `$FB`/1 Q, `$FB`/2 W, `$DF`/2 O, `$BF`/4 K, `$DF`/1 P, `$7F`/1 SPACE. | `DefineKey`, `TestKey` | `DefineKey` |
| `$778C` | `ControlVectors` | 8 | The four control readers by ControlMethod: ReadIf2, ReadKeys, ReadKempston, ReadSinclair | `ClearPlayState` | - |
| `$7794` | `DetachKey` | 2 | the joystick methods' detach key: port `$7F`, bit 0 (SPACE) | `TestKey` | - |
| `$77FF` | `Unused77FF` | 1 | a byte no recording reads (known only from the heatmap) | - | - |
| `$7800` | `PlayAttrs` | 640 | The play field's attribute shadow: 20 rows of 32 attributes. Written by the scroll and the sprite drawers. | `DrawFirstScreen`, `ScrollAttrRows`, `TitleLoop`, `l_8846`, `CommandWave` (`stage1/rec/l1`) +4 | `CellMark`, `Scroll`, `ScrollAttrRows`, `StarStep`, `ClearCells` (`stage1/rec/l1`) +2 |

## vars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7A80` | `GameVars` | 2 of 112 | The variables of play. Read and written in the play recordings; cleared in parts by ClearPlayState and ClearShipStuff. | `AwardScore`, `BossBlastOnce`, `CellFree`, `CellMark`, `CheckRestart` +80 | `AddScore`, `AddScoreFlag`, `AwardScore`, `CellFree`, `ClearHits` +77 |
| `$7A82` | `ScrollStep` (`GameVars`+2) | 1 | the step (0-7) in the 8-frame scroll cycle | `CellFree`, `RunWaves`, `Scroll`, `CarrierTimer` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l3`) +1 | `Scroll`, `DrawFirstScreen` (`stage1/rec/l2`), `FillBlock` (`stage1/rec/l1`) |
| `$7A83` | `MetaColumn` (`GameVars`+3) | 1 | the column (0-3) of the metatile the next column is cut from | `CutMetatile`, `RunWaves`, `Scroll`, `CutMetatileBoth` (`stage1/rec/l1`), `CutMetatileFlipped` (`stage1/rec/l1`) +3 | `Scroll`, `DrawFirstScreen` (`stage1/rec/l2`), `FillBlock` (`stage1/rec/l1`) |
| `$7A84` | `MapColumn` (`GameVars`+4) | 1 | the map block column the scroll has reached: the level's position | `CheckRestart`, `DrawFirstScreen`, `RunWaves`, `Scroll`, `FillBlock` (`stage1/rec/l3`) +1 | `RestartPoint`, `Scroll`, `StartPlayField`, `DrawFirstScreen` (`stage1/rec/l2`), `FillBlock` (`stage1/rec/l1`) |
| `$7A85` | `MapReadPtr` (`GameVars`+5) | 2 | the map byte the next metatile is read from | `Scroll`, `FillBlock` (`stage1/rec/l3`) | `Scroll`, `DrawFirstScreen` (`stage1/rec/l2`), `FillBlock` (`stage1/rec/l1`) |
| `$7A87` | `MapBlockPtr` (`GameVars`+7) | 2 | the first of the 5 map bytes of the current block column | `Scroll`, `FillBlock` (`stage1/rec/l3`) | `Scroll`, `DrawFirstScreen` (`stage1/rec/l2`), `FillBlock` (`stage1/rec/l1`) |
| `$7A89` | `FrameCounter` (`GameVars`+9) | 1 | counts the passes of the scroll (and the title colour's steps) | `CycleTitleColour`, `DrawBeam`, `MoveMissileSet`, `Scroll`, `ShipShield` +21 | `CycleTitleColour`, `Scroll`, `TitleLoop`, `Continue` (`stage1/rec/gameover`), `DrawFirstScreen` (`stage1/rec/l2`) +2 |
| `$7A8A` | `IntTicks` (`GameVars`+10) | 1 | counts interrupts; the main loop waits until it reaches 3 | `Interrupt`, `StartLife`, `FillBlock` (`stage1/rec/l3`), `MainLoop` (`stage1/rec/ending`), `MainLoopPatch` (`stage1/rec/l1`) | `Interrupt`, `StartLife`, `FillBlock` (`stage1/rec/l1`), `MainLoop` (`stage1/rec/l2`), `MainLoopPatch` (`stage1/rec/l1`) |
| `$7A8B` | `KempstonAbsent` (`GameVars`+11) | 1 | 0 when ProbeKempston found port `$1F` quiet: only then does the title take the Kempston's fire | `SelectControl`, `FillBlock` (`stage1/rec/l3`) | `ProbeKempston`, `FillBlock` (`stage1/rec/l1`) |
| `$7A8C` | `ExtraLives` (`GameVars`+12) | 1 | the extra lives given (CheckExtraLife) | `CheckExtraLife` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l3`), `PrintScore` (`stage1/rec/l2`) | `NewGameState`, `FillBlock` (`stage1/rec/l1`), `PrintScore` (`stage1/rec/l2`) |
| `$7A8D` | `DeathTimer` (`GameVars`+13) | 1 | set to 32 when the ship dies; LoseLife counts it down | `LoseLife`, `FillBlock` (`stage1/rec/l3`) | `LoseLife`, `ShipDies`, `FillBlock` (`stage1/rec/l1`) |
| `$7A8E` | `ScrollHalted` (`GameVars`+14) | 1 | non-zero while the scroll stands (a boss, wave command 1) | `Scroll`, `ScrollAttrs`, `l_8869`, `ExplodeSoftCell` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l3`) +1 | `ResumeWaves`, `StartPlayField`, `BossDestroyed` (`docs/integrate/rec/boss`), `CommandWave` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`) +1 |
| `$7A8F` | `WavesHalted` (`GameVars`+15) | 1 | non-zero once the level's end started | `MoveEnemies`, `RunWaves`, `FillBlock` (`stage1/rec/l3`) | `ResumeWaves`, `BossDestroyed` (`docs/integrate/rec/boss`), `CommandWave` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `LevelEnd` (`stage1/rec/l8`) +1 |
| `$7A90` | `WavePtr` (`GameVars`+16) | 4 | the next entry of the level's wave script | `RunWaves`, `FillBlock` (`stage1/rec/l3`), `RunWavesNext` (`stage1/rec/l1`) | `RestartPoint`, `RunWaves`, `StartPlayField`, `CommandWave` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`) +1 |
| `$7A94` | `TextHeight` (`GameVars`+20) | 1 | 0: PrintText draws double height; 1: normal | `PrintTextA`, `FillBlock` (`stage1/rec/l3`), `PrintTextNormal` (`docs/integrate/rec/force`) | `PrintTextA`, `FillBlock` (`stage1/rec/l1`), `PrintTextNormal` (`docs/integrate/rec/force`) |
| `$7A95` | `HitCount` (`GameVars`+21) | 1 | the tags gathered into HitList by the last drawing (14 at most) | `CellFree`, `MoveShip`, `CarrierDraw` (`stage1/rec/l2`), `FillBlock` (`stage1/rec/l3`), `ForceDraw` (`stage1/rec/l1`) +1 | `CellFree`, `ClearHits`, `ProcessHitsNext`, `AddScoreFlag` (`stage1/rec/ctl-kempston`), `CarrierDraw` (`stage1/rec/l2`) +2 |
| `$7A96` | `HitResult` (`GameVars`+22) | 1 | ProcessHits' result | `ProcessHitsNext`, `AddScoreFlag` (`stage1/rec/ctl-kempston`), `FillBlock` (`stage1/rec/l3`) | `AddScoreFlag`, `HitEnemy`, `FillBlock` (`stage1/rec/l1`), `HitCounted` (`stage1/rec/l4`), `ProcessHits` (`stage1/rec/l1`) |
| `$7A97` | `BeamMeter` (`GameVars`+23) | 1 | the BEAM meter's column | `FireBeam`, `FillBlock` (`stage1/rec/l3`) | `FireBeam`, `StartPlayField`, `FillBlock` (`stage1/rec/l1`) |
| `$7A98` | `ShieldTimer` (`GameVars`+24) | 1 | the passes the ship carries the shield (`$38` at the first start, `$20` at a later life, `$30` from the pick-up) | `ShipShield`, `FillBlock` (`stage1/rec/l3`), `MoveShip` (`stage1/rec/l2`) | `ClearPlayState`, `ShipShield`, `StartPlay`, `CarrierDraw` (`stage1/rec/l2`), `FillBlock` (`stage1/rec/l1`) +3 |
| `$7A99` | `ScoreChanged` (`GameVars`+25) | 1 | non-zero when AddScore changed the score: CheckExtraLife prints it | `CheckExtraLife` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l3`) | `AddScore`, `CheckExtraLife` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `PrintScore` (`stage1/rec/l2`) |
| `$7A9A` | `WaveOverride` (`GameVars`+26) | 1 | a wave command 3 value: the next wave's slot | `RunWaves`, `FillBlock` (`stage1/rec/l3`), `StartWave` (`stage1/rec/l1`) | `CommandWave` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `RunWaves` (`stage1/rec/l2`), `StartWave` (`stage1/rec/l1`) |
| `$7A9B` | `LevelEndTimer` (`GameVars`+27) | 1 | counts down after the level's end command | `LevelEnd`, `FillBlock` (`stage1/rec/l3`) | `BossBlastOnce` (`docs/integrate/rec/boss`), `CommandWave` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `LevelEnd` (`stage1/rec/l1`), `RunWaves` (`stage1/rec/l2`) |
| `$7A9C` | `DrawTag` (`GameVars`+28) | 1 | the tag DrawSprite writes into SolidMap for each cell | `CellMark`, `MoveEnemiesSlot`, `EnemyFire` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l3`), `l_912D` (code) | `GameObject`, `MoveEnemiesSlot`, `DrawFirstScreen` (`stage1/rec/l2`), `ExplodeSoftCell` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l1`) +2 |
| `$7A9D` | `StarFrame` (`GameVars`+29) | 1 | the star task's counter | `StarStep`, `StarTask`, `FillBlock` (`stage1/rec/l3`) | `StarTask`, `FillBlock` (`stage1/rec/l1`) |
| `$7A9E` | `ShooterLimit` (`GameVars`+30) | 1 | wave command 4: how many enemies may fire at once | `EnemyFire`, `FillBlock` (`stage1/rec/l3`) | `RunWaves`, `CommandWave` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`) |
| `$7A9F` | `Shooters` (`GameVars`+31) | 1 | the enemies firing now | `EnemyFire`, `FillBlock` (`stage1/rec/l3`), `MoveEnemyShots` (`stage1/rec/l1`) | `ClearPlayState`, `EnemyFire` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `MoveEnemyShots` (`stage1/rec/l1`) |
| `$7AA0` | `Lives` (`GameVars`+32) | 1 | the lives (5 at the start) | `DrawHud`, `LoseLife`, `ShipDies`, `FillBlock` (`stage1/rec/l3`), `PrintScore` (`stage1/rec/l2`) | `NewGameState`, `ShipDies`, `FillBlock` (`stage1/rec/l1`), `PrintScore` (`stage1/rec/l2`) |
| `$7AA1` | `ShipColumn` (`GameVars`+33) | 1 | the ship's column (1-28) | `FireBeam`, `MoveShip`, `ShipDies`, `ShipFlyIn`, `ShipShield` +12 | `MoveShip`, `ShipFlyIn`, `StartPlay`, `FillBlock` (`stage1/rec/l1`) |
| `$7AA2` | `ShipRow` (`GameVars`+34) | 1 | the ship's row (0-19) | `FireBeam`, `MoveShip`, `ShipDies`, `ShipFlyIn`, `ShipShield` +10 | `MoveShip`, `ShipFlyIn`, `StartPlay`, `FillBlock` (`stage1/rec/l1`) |
| `$7AA3` | `ForceAttached` (`GameVars`+35) | 1 | the Force: 0 free, 1 at the ship's nose, 2 at its tail | `FireBeam`, `FillBlock` (`stage1/rec/l3`), `ForceGround` (`stage1/rec/l3`), `ForceShotA` (`stage1/rec/l1`), `ForceShotFrom` (`stage1/rec/l7`) +1 | `FillBlock` (`stage1/rec/l1`), `ForceDraw` (`stage1/rec/l1`), `LevelEnd` (`stage1/rec/l2`), `ShipShield` (`docs/integrate/rec/force`) |
| `$7AA4` | `ShipFrame` (`GameVars`+36) | 1 | the ship's sprite: 3 level, 2 and 4 the tilts | `MoveShip`, `FillBlock` (`stage1/rec/l3`) | `MoveShip`, `ShipFlyIn`, `StartPlay`, `FillBlock` (`stage1/rec/l1`) |
| `$7AA5` | `BitUpperOn` (`GameVars`+37) | 1 | the upper bit device is fitted | `FireMissiles`, `MoveBitDevices`, `CarrierDraw` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l3`), `FireBits` (`stage1/rec/l1`) +2 | `CarrierDraw` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l1`) |
| `$7AA6` | `BitLowerOn` (`GameVars`+38) | 1 | the lower bit device is fitted | `FireMissiles`, `MoveBitDevices`, `FillBlock` (`stage1/rec/l3`), `FireBits` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l7`) +1 | `FillBlock` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l7`) |
| `$7AA7` | `MissilesOn` (`GameVars`+39) | 1 | the homing missiles are fitted | `FireMissiles`, `FillBlock` (`stage1/rec/l3`) | `FillBlock` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l1`), `l_993D` (code) |
| `$7AA8` | `ForceRecord` (`GameVars`+40) | 9 | the Force's records, 3 bytes each (state, column, row): `$7AA8`, `$7AAB`, `$7AAE` (ForceRecordOf) | `FireBeam`, `MoveForce`, `CarrierDraw` (`stage1/rec/l3`), `FillBlock` (`stage1/rec/l3`), `ForceDraw` (`stage1/rec/l1`) +4 | `CarrierDraw` (`stage1/rec/l3`), `FillBlock` (`stage1/rec/l1`), `ForceDraw` (`stage1/rec/l1`), `ForceStore` (`stage1/rec/l1`), `LevelEnd` (`stage1/rec/l2`) +4 |
| `$7AB1` | `BitPositions` (`GameVars`+49) | 12 | the bits' positions | `FireBeam`, `BitFrame` (`stage1/rec/l1`), `BitStep` (`stage1/rec/l3`), `BounceShot` (`stage1/rec/l1`), `DrawBitTrail` (`stage1/rec/l3`) +5 | `FireBeam`, `BitFrame` (`stage1/rec/l1`), `BitStep` (`stage1/rec/l3`), `BounceShot` (`stage1/rec/l1`), `DrawBitTrail` (`stage1/rec/l3`) +4 |
| `$7ABD` | `WeaponKind` (`GameVars`+61) | 1 | the Force's laser kind (the crystal's colour) | `FillBlock` (`stage1/rec/l3`), `FireBeam` (`stage1/rec/l1`), `ForceShotA` (`stage1/rec/l1`), `ForceShotFrom` (`stage1/rec/l7`) | `CarrierDraw` (`stage1/rec/l3`), `FillBlock` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l1`), `TakePickup` (code) |
| `$7ABE` | `ForceLevel` (`GameVars`+62) | 1 | the Force's level: 0 none, 1-3 | `CarrierDraw` (`stage1/rec/l3`), `FillBlock` (`stage1/rec/l3`), `LevelEnd` (`stage1/rec/l2`), `MoveCarrierA` (`stage1/rec/l1`), `ShipShield` (`docs/integrate/rec/force`) +2 | `FillBlock` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l1`), `TakePickup` (code) |
| `$7ABF` | `BeamCharge` (`GameVars`+63) | 1 | the beam's charge while fire is held, up to `$3E` (+2 a pass; `$9A66` CP `$40` keeps the old value at `$40`) | `FireBeam`, `ShipShield`, `FillBlock` (`stage1/rec/l3`), `MoveShip` (`stage1/rec/l2`) | `FireBeam`, `FillBlock` (`stage1/rec/l1`) |
| `$7AC0` | `BeamPower` (`GameVars`+64) | 1 | the beam's strength left | `HitEnemy`, `MoveBeam`, `FillBlock` (`stage1/rec/l3`) | `FireBeam`, `HitEnemy`, `MoveBeam`, `FillBlock` (`stage1/rec/l1`), `l_9ECD` (code) |
| `$7AC1` | `Carriers` (`GameVars`+65) | 8 | the two pick-up carriers' records | `MoveCarrierA`, `MoveCarrierB`, `CarrierDraw` (`stage1/rec/l2`), `CarrierTimer` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l3`) +1 | `CarrierDraw` (`stage1/rec/l2`), `CarrierTimer` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l1`), `MoveCarrierB` (`stage1/rec/l2`) +1 |
| `$7AC9` | `BossBlast` (`GameVars`+73) | 1 | non-zero while the boss explodes (BossDestroyed) | `BossBlastOnce`, `FillBlock` (`stage1/rec/l3`) | `BossBlastOnce` (`docs/integrate/rec/boss`), `BossDestroyed` (`docs/integrate/rec/boss`), `FillBlock` (`stage1/rec/l1`) |
| `$7ACA` | `BossBlastCount` (`GameVars`+74) | 1 | the random explosions left | `BossBlastOnce` (`docs/integrate/rec/boss`), `FillBlock` (`stage1/rec/l3`) | `BossBlastOnce` (`docs/integrate/rec/boss`), `BossDestroyed` (`docs/integrate/rec/boss`), `FillBlock` (`stage1/rec/l1`) |
| `$7ACB` | `BossBlastPos` (`GameVars`+75) | 2 | the sweep position after the random ones | `BossBlastOnce` (`docs/integrate/rec/boss`), `FillBlock` (`stage1/rec/l3`) | `BossBlastOnce` (`docs/integrate/rec/boss`), `BossDestroyed` (`docs/integrate/rec/boss`), `FillBlock` (`stage1/rec/l1`) |
| `$7ACD` | `RandomPtr` (`GameVars`+77) | 2 | the ROM pointer whose bytes are the random numbers (NextRandom) | `FillBlock` (`stage1/rec/l3`), `NextRandom` (`stage1/rec/l7`) | `BossDestroyed` (`docs/integrate/rec/boss`), `FillBlock` (`stage1/rec/l1`), `NextRandom` (`stage1/rec/l7`) |
| `$7ACF` | `Scratch` (`GameVars`+79) | 8 | scratch words of the shot and award routines | `AwardScore`, `AntiAirDown` (`stage1/rec/l1`), `DrawBitTrail` (`stage1/rec/l3`), `FillBlock` (`stage1/rec/l3`), `MoveForce` (`stage1/rec/l1`) +3 | `AddScoreFlag`, `AwardScore`, `EnemyHit`, `MoveAntiAirShot`, `AntiAirDown` (`stage1/rec/l1`) +7 |
| `$7AD7` | `HitList` (`GameVars`+87) | 16 | the tags the last drawing gathered (15 bytes) | `ProcessHitsNext`, `AddScoreFlag` (`stage1/rec/ctl-kempston`), `CarrierDraw` (`stage1/rec/l2`), `ClearBlock` (`docs/integrate/rec/force`), `FillBlock` (`stage1/rec/l1`) +2 | `CellFree`, `ProcessHitsNext`, `AddScoreFlag` (`stage1/rec/ctl-kempston`), `ClearBlock` (`docs/integrate/rec/force`), `FillBlock` (`stage1/rec/l1`) |
| `$7AE7` | `MissileLaunch` (`GameVars`+103) | 9 | the missiles' launch records, 6 bytes each (`$7AE7`, `$7AED`) | `MoveMissile`, `FillBlock` (`stage1/rec/l1`), `FireMissiles` (`stage1/rec/l1`) | `FillBlock` (`stage1/rec/l1`), `FireMissiles` (`stage1/rec/l1`), `MoveMissile` (`stage1/rec/l1`) |
| `$7AF0` | `Font` | 488 | The font: 8 bytes a character from '!' (the code - `$20` from `$7AE8`; a space draws character `$3B`). PrintText draws it double height, PrintTextNormal as it is. | `PrintHalf`, `PrintTextA`, `BigDigit` (`stage1/rec/gameover`), `DrawTrail` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`) +2 | `FillBlock` (`stage1/rec/l1`), `FireMissiles` (`stage1/rec/l1`), `MoveMissile` (`stage1/rec/l1`), `StartMissile` (`stage1/rec/l1`), `StartRecord` (`stage1/rec/l3`) |
| `$7CD8` | `HiScoreTable` | 153 | Nine entries of 17 bytes: name (10), score (6 ASCII digits), `$A0` (bit 7 ends the text). InsertHiScore inserts a new score, shifting the lower entries down; the names as loaded are the defaults. | `PrintTextA`, `FillBlock` (`stage1/rec/hiscore`), `InsertHiScore` (`stage1/rec/gameover`) | `FillBlock` (`stage1/rec/l5`), `InsertHiScore` (`stage1/rec/hiscore`) |
| `$7D71` | `HiScoreSpare` | 17 | the 17 bytes past the ninth entry the insertion shifts the last entry into (no recording reads them) | - | `FillBlock` (`stage1/rec/l5`), `InsertHiScore` (`stage1/rec/hiscore`) |
| `$7D82` | `MissileFrames` | 22 of 119 | The homing missile's frame lists: (sprite, step) pairs, `$FF` ends a list | `MoveMissile` (`stage1/rec/l1`), `ShotPathStep` (`stage1/rec/l1`) | `FillBlock` (`stage1/rec/l5`) |
| `$7D98` | `MissileTurns` (`MissileFrames`+22) | 25 | the lists by direction (`$7D98`, `$7D9B`, `$7D9F`, `$7DA6`, `$7DAA`) | `MoveMissile` (`stage1/rec/l1`) | `FillBlock` (`stage1/rec/l5`) |
| `$7DB1` | `AntiAirPathUp` (`MissileFrames`+47) | 37 | the upward anti-air shot's path: (row step, sprite) pairs, `$63` ends | - | `FillBlock` (`stage1/rec/l5`) |
| `$7DD6` | `AntiAirPathDown` (`MissileFrames`+84) | 35 | the downward path | `ShotPathStep` (`stage1/rec/l1`) | `FillBlock` (`stage1/rec/l5`) |
| `$7DF9` | `LevelVars` | 7 | seven bytes the levels' own code uses; cleared at each start | `FillBlock` (`stage1/rec/l1`) | `FillBlock` (`stage1/rec/l1`) |
| `$7E00` | `SolidMap` | 226 of 640 | The collision map: one byte a cell of the 20 x 32 play field, the tag of what is there. 0 empty; small values the ship and its shots; `$80` + slot an enemy; `$FA` an enemy's soft part; `$FB-$FF` hard scenery (from the metatile attribute's bit 7). GetCell reads it. | `CellFree`, `Entry`, `GetCell`, `MoveBeam`, `ScrollAttrRows` +11 | `CellMark`, `Scroll`, `ScrollAttrRows`, `l_8869`, `BossDestroyed` (`docs/integrate/rec/boss`) +5 |
| `$7EE2` | `EntryCopySource` (`SolidMap`+226) | 414 | the 414 bytes the entry copies to EntryCopy before SolidMap is first cleared | `CellFree`, `Entry`, `GetCell`, `MoveBeam`, `ScrollAttrRows` +11 | `CellMark`, `Scroll`, `ScrollAttrRows`, `l_8869`, `BossDestroyed` (`docs/integrate/rec/boss`) +5 |
| `$8080` | `RowTable` | 80 | The 20 play rows: (screen address, attribute address) of each row's right end. ScrollRows walks it; the star task starts at its second row. | `CellFree`, `Scroll`, `StarCell`, `StarTask`, `l_8846` +5 | `FillBlock` (`stage1/rec/l1`) |
| `$80D0` | `RowTableEnd` | 8 | zeros after the table | `StarTask`, `l_8846`, `FillBlock` (`stage1/rec/l1`), `GetCell` (`stage1/rec/l6`), `ScrollRows` (`stage1/rec/ending`) | `FillBlock` (`stage1/rec/l1`) |
| `$80D8` | `PlayStarStates` | 40 | the play's star states (2 bytes a star) for the star task | `StarCell`, `StarStep`, `AntiAirDown` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `GetCell` (`stage1/rec/l1`) | `StarStep`, `FillBlock` (`stage1/rec/l1`) |
| `$8100` | `DrawnMap` | 79 | 1 where a sprite cell is on the screen (set by ScrollRows' copy, cleared by its erase); the star task draws only where it is 0 (640 bytes cleared by ClearPlayState) | `StarStep`, `l_8869`, `FillBlock` (`stage1/rec/l1`), `GetCell` (`stage1/rec/l7`), `ScrollRows` (`stage1/rec/ending`) | `l_8869`, `ExplodeSoftCell` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l1`), `ScrollRows` (`stage1/rec/ending`) |

## intro

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$81A9` | `ScrollerText` | 466 | `STOP THE TAPE $` and the credits: R TYPE, PROGRAMMED BY BOB PAPE, GRAPHICS, SOUND, IREM 1987, ELECTRIC DREAMS 1988 | `PrintTextA`, `ShowLoadingScreen`, `StarStep`, `l_8869`, `CellWindowRow` (`stage1/rec/l2`) +3 | `ShowLoadingScreen`, `l_8869`, `ExplodeSoftCell` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l1`), `ScrollRows` (`stage1/rec/ending`) |
| `$837B` | `ScrollerEnd` | 8 | eight zeros after the text | `PrintTextA`, `StarStep`, `l_8869`, `FillBlock` (`stage1/rec/l1`), `ScrollRows` (`stage1/rec/ending`) | `FillBlock` (`stage1/rec/l1`), `l_8869` (`stage1/rec/l3`) |
| `$8386` | `EnemyShots` | 84 of 631 | The enemy shots, 3 bytes each (direction and kind, column, row): MoveEnemyShots | `AwardScore`, `EnemyHit`, `HitEnemy`, `Im2Jump`, `MoveAntiAirShot` +24 | `ClearPlayState`, `EnemyHit`, `FireBeam`, `HitEnemy`, `MoveBeam` +25 |
| `$83DA` | `ShipTrail` (`EnemyShots`+84) | 8 | the ship's last positions for the bits (TrailPoint) | `PrintTextA`, `CarrierDraw` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l1`), `TrailPoint` (`stage1/rec/l1`) | `CarrierDraw` (`stage1/rec/l4`), `FillBlock` (`stage1/rec/l1`), `MoveCarrierA` (`stage1/rec/l1`), `TrailPoint` (`stage1/rec/l1`), `l_994B` (code) |
| `$83E2` | `BeamShot` (`EnemyShots`+92) | 3 | the beam shot: length, row, column | `MoveBeam`, `PrintTextA`, `FillBlock` (`stage1/rec/l1`) | `FireBeam`, `MoveBeam`, `FillBlock` (`stage1/rec/l1`), `l_9ECD` (code) |
| `$83E5` | `AntiAirShots` (`EnemyShots`+95) | 8 | the two anti-air shot records (`$83E5`, `$83E9`) | `MoveAntiAirShot`, `PrintTextA`, `FillBlock` (`stage1/rec/l1`), `FireBeam` (`stage1/rec/l1`), `ShotPathStep` (`stage1/rec/l1`) | `AntiAirDown` (`stage1/rec/l1`), `FillBlock` (`stage1/rec/l1`), `FireBeam` (`stage1/rec/l1`), `ShotEnd` (`stage1/rec/l1`), `ShotPathStep` (`stage1/rec/l1`) |
| `$83ED` | `MissileTimer` (`EnemyShots`+103) | 5 | frames before the missiles may fire again | `MoveMissiles`, `PrintTextA`, `BitHits` (`stage1/rec/l3`), `BitStep` (`stage1/rec/l3`), `FillBlock` (`stage1/rec/l1`) +1 | `ClearPlayState`, `MoveBitUnits`, `DrawBitTrail` (`stage1/rec/l3`), `FillBlock` (`stage1/rec/l1`), `FireMissiles` (`stage1/rec/l1`) +3 |
| `$83F2` | `ShipEntry` (`EnemyShots`+108) | 1 | the ship's fly-in: 1 flying in, 2 turning back, 0 done | `PrintTextA`, `ShipFlyIn` | `ShipFlyIn`, `StartPlay`, `FillBlock` (`stage1/rec/l1`) |
| `$83F3` | `BeamHudText` (`EnemyShots`+109) | 13 | the HUD text DrawHud prints after BEAM- | `PrintTextA` | `FillBlock` (`stage1/rec/l1`) |
| `$8400` | `Im2Table` (`EnemyShots`+122) | 257 | the IM 2 vector table: 257 bytes of `$83` | `Im2Jump` | `FillBlock` (`stage1/rec/l1`), `HitEnemy` (`stage1/rec/l3`) |
| `$8501` | `EnemySlots` (`EnemyShots`+379) | 252 | 28 enemy slots of 9 bytes: flags, position, script and kind pointers, movers | `AwardScore`, `EnemyHit`, `HitEnemy`, `MoveEnemiesSlot`, `MoveNext` +10 | `EnemyHit`, `HitEnemy`, `MoveScript`, `MoveStore`, `RunWaves` +6 |

## tapeload

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8FBB` | `Unused8FBB` | 16 | bytes no recording reads (known only from the heatmap) | - | - |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A5F7` | `GraphicsHead` | 13 | bytes before the first sprite (no recording reads them; known only from the heatmap) | - | - |
| `$A604` | `Sprites` | 5731 | The game's sprites: cells of 9 bytes (attribute, 8 pixel bytes) drawn through GameObjects. The ship, its shield, the Force in its levels, the bits, the shots, the beam, the missiles, the explosions, the carriers, the logo letters. Read in every play recording. | `CellMark`, `DrawSprite`, `DrawSpriteFlipped`, `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteMirrored` (`stage1/rec/l1`) | - |
| `$BC67` | `GameObjects` | 444 | 111 objects of 4 bytes: width, height, the cells' address (GameObject) | `ObjectEntry`, `GameObject` (`docs/rtB/rec/pause`) | - |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BE60` | `TaskTable` | 25 | The 5 interrupt tasks: address, switch, counter, reload. Task 0 StarTask (off at the entry); tasks 1-3 the sound channels SoundTask1-3, every third tick; task 4 CycleTitleColour (off). | `Interrupt` | `ClearPlayState`, `Interrupt`, `ShowHiScores`, `StarsSet`, `CheckHiScore` (`stage1/rec/hiscore`) +2 |

## util

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C49A` | `PausedText` | 12 | "GAME  PAUSED" | `PrintTextA` (`docs/rtB/rec/pause`) | - |
| `$C4A6` | `PausedPad` | 8 | eight zeros before the level space (no recording reads them) | - | - |

## levelspace

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `LevelSpace` | 1 of 150 | The level header and body (zeros at the entry) | `CheckRestart`, `DrawFirstScreen`, `LevelObject`, `MetatileAddress`, `MoveEnemiesSlot` +12 | `LoadBytes`, `RestartPoint`, `CheckRestart` (`stage1/rec/l1`) |
| `$C4AF` | `LevelRestartWave` (`LevelSpace`+1) | 2 | the wave script entry a life restarts at | `StartPlayField` | `LoadBytes`, `RestartPoint`, `CheckRestart` (`stage1/rec/l1`) |
| `$C4B1` | `LevelChecks` (`LevelSpace`+3) | 3 | three checkpoint columns | `CheckRestart`, `RestartPoint` | `LoadBytes` |
| `$C4B4` | `LevelWaves` (`LevelSpace`+6) | 6 | the wave script's start and the checkpoints' entries | `RestartPoint`, `CheckRestart` (`stage1/rec/l1`) | `LoadBytes` |
| `$C4BA` | `LevelObjects` (`LevelSpace`+12) | 2 | the level's object table (LevelObject) | `LevelObject` | `LoadBytes` |
| `$C4BC` | `LevelMetatiles` (`LevelSpace`+14) | 2 | the map, the metatiles below it (MetatileAddress) | `DrawFirstScreen`, `MetatileAddress` | `LoadBytes` |
| `$C4BE` | `LevelKinds` (`LevelSpace`+16) | 2 | the enemy kinds (StartWave) | `RunWaves`, `StartWave` (`stage1/rec/l1`) | `LoadBytes` |
| `$C4C0` | `LevelMoves` (`LevelSpace`+18) | 2 | the first movers (MoveEnemies) | `MoveEnemiesSlot`, `l_9159` (code) | `LoadBytes` |
| `$C4C2` | `LevelMoves2` (`LevelSpace`+20) | 130 | the second movers | `MoveNext`, `CellMark` (`stage1/rec/l1`), `DrawSprite` (`stage1/rec/l1`), `DrawSpriteBoth` (`stage1/rec/l1`), `DrawSpriteFlipped` (`stage1/rec/l1`) +2 | `LoadBytes` |
| `$C544` | `LoaderLeftover` | 6100 | bytes the loader's last moves left, never read before a level overwrites them | `CellMark`, `DrawSprite`, `DrawSpriteFlipped`, `ObjectEntry`, `AwardScore` (`stage1/rec/l5`) +13 | `LoadBytes` |
| `$DD18` | `TitleScreen` | 6912 | The title picture (a `SCREEN$`) ShowLoadingScreen copies to the screen | `AwardScore`, `CellMark`, `CutMetatile`, `DrawFirstScreen`, `DrawSprite` +19 | `LoadBytes`, `FillBlock` (`stage1/rec/l3`) |
| `$F818` | `LevelSpaceTail` | 90 | the bytes after the picture up to the sound's stack: level 1 loads over `$F818-$F859`; no play recording reads the rest | - | `LoadBytes` |
| `$F872` | `SoundStack` | 10 | ten bytes the tone commands use as a stack (LD SP,`$F87A`: the four voice periods pushed, TonePlayer reads them from `$F872`); read in every play recording | `ChordPlay1C` (`stage1/rec/ending`), `TonePlayer` (`stage1/rec/l1`) | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F8F5` | `SoundTask1Tail` | 3 | bytes after the task | - | - |
| `$F905` | `SoundTask2Tail` | 3 | bytes after the task | - | - |
| `$F9C7` | `SoundCommandSpare` | 13 | bytes of an unused command (known only from the code) | - | - |
| `$FABF` | `ChordPlay2` | 11 of 16 | ChordPlay2 | - | - |
| `$FACA` | `ChordPlay2B` (`ChordPlay2`+11) | 3 | second half | - | - |
| `$FACD` | `ChordPlay2C` (`ChordPlay2`+14) | 2 | to the player | - | - |
| `$FADF` | `ChordPlay4` | 11 of 16 | ChordPlay4 | - | - |
| `$FAEA` | `ChordPlay4B` (`ChordPlay4`+11) | 3 | second half | - | - |
| `$FAED` | `ChordPlay4C` (`ChordPlay4`+14) | 2 | to the player | - | - |
| `$FB0F` | `SoundCommandsSpare` | 32 | bytes no recording reads (known only from the code) | - | - |
| `$FB66` | `SoundData` | 310 | The sound data: note periods, the channel slots, the command table (`$FBEB`), the script table (`$FC0B`). The script table at `$FC0B` holds 35 words, sounds `$00-$22`. By the code that starts them (the run counts of the starting instruction over all recordings): `$00` silence (Silence, CommandWave); `$01` shot (ShotSound, 3940 runs); `$02` beam charging (FireBeam, 90); `$03` a level 8 wave sound (wave command 6 at columns 35, 41, 48); `$04` enemy hit (EnemyHit, 2492); `$05` beam released (BeamRelease, 143); `$06` missiles (FireMissiles, 482); `$08` small explosion, `$0A` middle explosion, `$09` big explosion (AwardScore by the enemy's size with bits `$82`, the first free channel, TimbreHigh: size `$10` to `$08`, `$40` to `$0A`, `$20` and `$30` to `$09`;, 1377/848/747; BossDestroyed's `$09` or `$0A` never ran); `$09` also the ship hit (ShipDies, 38); `$0A` also a life lost (LoseLife, 37) and the level 7 wave sound (columns 73-74, 94); `$0B` a key defined (DefineKeys, DefineKey: never ran); `$0C` the best pilots table entered (InsertHiScore, 10); `$0D` pick-up (TakePickup, 20); `$0E` extra life (ExtraLifeSound, 6); `$0F` a soft cell hit (ProcessHitsNext, 717); `$10-$13` the level 2 wave sounds (columns 31-90: the boss's beat); `$14` the Force docks (ForceDraw 1; ShieldControls never ran); `$15` the level's end tune (LevelEnd, 8); `$16` the name entered (InsertHiScore, 1); `$18` a shot bounced off the scenery (BounceShot, 1576: one Chord1 step at about 1900 Hz, bits `$41`; it shares its script `$5BD0` with the unused `$17`); `$19`, `$1D`, `$1E` the control method chosen (SelectControl, 3 each); `$1A`, `$1B` mission over (MissionOver, 4 each); `$1C` the Force on the ground (ForceGround, 507); `$22` the CONTINUE count (Continue, 21). Sounds `$07`, `$17` (the same script as `$18`) and `$1F-$21` are started by no code and no wave script: known only from the table. `$15-$1E` have their scripts at `$5B64-$5CFF`, `$1F-$21` at `$F168-$F35C` inside the level space (whatever the loaded level holds there), `$22` at `$72E8`. The command table at `$FBEB`: 16 words: 0 End, 1 Rest (SoundNop), 2 Mark, 3 Back, 4 Repeat, 5 Loop, 6 spare bytes `$F9C7`, 7 Noise, 8-13 Chord1-6, 14-15 spare chord variants `$FB0F`/`$FB1F` (no script uses them). | `ChordPlay1C` (`stage1/rec/ending`), `NoiseBurst` (`stage1/rec/l1`), `NotePeriod` (`stage1/rec/l1`), `SoundLoop` (`stage1/rec/l1`), `SoundPush` (`stage1/rec/l1`) +6 | `ChordPlay1` (`stage1/rec/l1`), `ChordPlay1C` (`stage1/rec/ending`), `ChordPlay3` (`stage1/rec/l1`), `ChordPlay5` (`stage1/rec/l1`), `ChordPlay6` (`stage1/rec/l1`) +8 |
| `$FC9C` | `SoundScripts` | 259 | the sound scripts | `SoundRepeat` (`stage1/rec/l3`), `SoundStep` (`stage1/rec/l1`) | `SoundStep` (`stage1/rec/l1`) |
| `$FD9F` | `SoundScriptsEnd` | 6 | bytes no recording reads | `SoundStep` (`docs/integrate/rec/force`) | `SoundStep` (`docs/integrate/rec/force`) |

## tail

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FE02` | `SpareFE02` | 1 | a byte between the routines | - | - |
| `$FF94` | `StackArea` | 108 | Loader leftovers (`$FF94-$FFC7`, no play recording reads them) and the stack (SP = `$FFFE`) | - | `Im2Jump` |


## The tape BASIC and the copy of the decryption chain (`src/tape/basic.json`)

R-Type, Electric Dreams Software 1988: tape block 2, the BASIC program "R-TYPE" (4933 bytes at PROG `$5CCB`, LINE
0). Its entries are `src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part
src/tape/basic.json`; the readers and writers from `work/stage1/c1`.

### The tape BASIC and the copy of the decryption chain: basic

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine0` | 2 of 59 | Line 0: INK 0 PAPER 0 RANDOMIZE USR ((PEEK 23635+256*PEEK 23636)+10), the 10 hiding 59. The ROM's line format: the line number high byte first, the length (55) low byte first, the tokens, `$0D`. Each number in the line is its digits followed by `$0E` and the five bytes the interpreter really uses: the digits 23635, 256 and 23636 carry their own numbers, the digits 10 carry 59. Read by the ROM's interpreter in c1; no machine code reads it. | - | - |
| `$5CCD` | `BasicLineLength` (`BasicLine0`+2) | 50 | the line's length after these four bytes, low byte first: 55 | - | - |
| `$5CFF` | `BasicHiddenNumber` (`BasicLine0`+52) | 7 | the five-byte number the interpreter adds: 59 (the shown digits say 10) | - | - |
| `$5D27` | `ChainTape` | 4840 | The decryption chain as the tape holds it (4840 bytes, copied to `$EC00`). The bytes of `$EC00-$FEE7` before any layer ran. src/loader/chain.asm is their plain view (each byte after the last layer that rewrites it); tools/speedlock7.py tape turns the plain view back into these bytes, and tools/build.sh checks the whole tape against the original. Read by CopyChain's LDIR in c1. | `CopyChain` | - |
| `$700F` | `BasicEnd` | 1 | The block's last byte, past the copy: `$54` no code reads. CopyChain copies 4840 bytes, `$5D27-$700E`; the block's 4933 bytes end one byte later. Nothing reads it after the ROM's load (c1: CopyChain's LDIR stops at `$700E`): a byte of the BASIC block left over past the chain. | - | - |


## The decryption chain and the SpeedLock 7 loader (`src/loader/chain.json`)

R-Type, Electric Dreams Software 1988: the BASIC's enciphered tail in its plain view, `$EC00-$FEE7`: the layers of
the decryption chain as each one runs, then the SpeedLock 7 reader as the last layer leaves it. tools/speedlock7.py
masters these bytes back into the tape's (src/tape/basic.asm INCBINs the result). Its entries are
`src/loader/<module>.asm`, written from `src/loader/chain.ann` by `kit/mkgame.py --part src/loader/chain.json`; the
readers and writers from `work/stage1/c1`.

### The decryption chain and the SpeedLock 7 loader: chain

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$EC6F` | `LayerExit01` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart` | `ChainStart` |
| `$ECDC` | `LayerExit03` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart` | `ChainStart` |
| `$EDAD` | `LayerExit06` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `LayerKeyed06` | `ChainStart`, `LayerKeyed06` |
| `$EE1D` | `LayerExit07` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06` | `ChainStart`, `Layer08`, `LayerKeyed06` |
| `$EEC5` | `LayerExit08` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06` | `ChainStart`, `Layer08`, `LayerKeyed06` |
| `$EF10` | `LayerExit10` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06` | `ChainStart`, `Layer08`, `LayerKeyed06` |
| `$EF4A` | `LayerExit11` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06` | `ChainStart`, `Layer08`, `LayerKeyed06` |
| `$F08A` | `LayerExit15` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06` | `ChainStart`, `Layer08`, `LayerKeyed06` |
| `$F106` | `LayerExit16` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06` | `ChainStart`, `Layer08`, `LayerKeyed06` |
| `$F132` | `LayerExit17` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06` | `ChainStart`, `Layer08`, `LayerKeyed06` |
| `$F31F` | `LayerExit22` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` |
| `$F3BE` | `LayerExit24` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` |
| `$F43C` | `LayerExit26` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` |
| `$F518` | `LayerExit29` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` |
| `$F586` | `LayerExit31` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `LayerKeyed06`, `LayerKeyed22` |
| `$F753` | `LayerExit33` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` |
| `$F8CB` | `LayerExit37` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` |
| `$F94D` | `LayerExit38` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` |
| `$F99A` | `LayerExit39` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` |
| `$FA36` | `LayerExit42` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` |
| `$FB2B` | `LayerExit44` | 2 | `$DD`,`$E9`: the JP (IX) the keyed layer leaves through, as the next layer leaves it (deciphered after it ran) | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` |
| `$FCD1` | `SL7Bytes` | 4 | four bytes `$90`, `$98`, `$80`, `$90` between the routines | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` +1 | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` +1 |
| `$FDB3` | `SL7StoreHook` | 20 | The byte store stage 2 points the reader at (`$FDB1` = `$FDB3`): LD A,`$C1` / XOR L / ADD A,`$11` / LD (IX+0),A ...; bytes in this view (known only from the code) | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` |
| `$FEB3` | `SL7Pattern` | 15 | The flag byte (non-zero: a failed check, the reader wipes memory) and the 7 sync pulse limits (pairs) | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` +1 | `ChainStart`, `Layer08`, `Layer32`, `LayerKeyed06`, `LayerKeyed22` +2 |


## The second stage (`src/loader/stage2.json`)

R-Type, Electric Dreams Software 1988: the SpeedLock reader's second stage at `$FEE8-$FFCF`, tape block 7. Its
entries are `src/loader/<module>.asm`, written from `src/loader/stage2.ann` by `kit/mkgame.py --part
src/loader/stage2.json`; the readers and writers from `work/stage1/c1`.

### The second stage: stage2

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FF17` | `Stage2Data` | 185 | Zeros, the first block table at `$FF49` (5-byte records: address, length, the `$7FFD` bank) and the countdown digits 0-9 (8 bytes each from `$FF80`) | - | - |


## The second stage's table (`src/loader/table2.json`)

R-Type, Electric Dreams Software 1988: the reader's second table over `$FF49`, tape block 23 (55 bytes). Its entries
are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/table2.json`; the readers and writers from `work/stage1/c1`.

### The second stage's table: table2

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FF49` | `BlockTable2` | 55 | The block table SL7Blocks walks for the game: 5-byte records (address, length, the `$7FFD` bank or 0) | - | - |


## The decipher block (`src/loader/decipher.json`)

R-Type, Electric Dreams Software 1988: Decipher at `$FE40` and the bytes after it, tape block 29 (115 bytes). Its
entries are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/decipher.json`; the readers and writers from `work/stage1/c1`.

### The decipher block: decipher

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FE53` | `DecipherLeftover` | 96 | The rest of the block: an older copy of the second stage's code (the store hook setup, the stack and IM settings), never run | - | - |


## The second stage's end (`src/loader/stage2end.json`)

R-Type, Electric Dreams Software 1988: the second stage's new end at `$FEFC`, tape block 31 (49 bytes). Its entries
are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/stage2end.json`; the readers and writers from `work/stage1/c1`.


## The loader's tail: the move to the game and the jump to the entry (`src/loader/tail.json`)

R-Type, Electric Dreams Software 1988: the tail at `$61A8` (blocks 33 and 35), tape block 33 (47 bytes). Its entries
are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part src/loader/tail.json`;
the readers and writers from `work/stage1/c1`.

### The loader's tail: the move to the game and the jump to the entry: tail

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$61C9` | `TailLeftover` | 14 | Bytes after the tail (the start of the second stage's code: XOR A / LD (`$82FF`),A / LD IX,`$4000` ...), never run | - | - |


## Level 1 (side 2) (`src/level1/level1.json`)

R-Type, Electric Dreams Software 1988: level 1, 13228 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
40). Its entries are `src/level1/<module>.asm`, written from `src/level1/level1.ann` by `kit/mkgame.py --part
src/level1/level1.json`; the readers and writers from `work/stage1/rec/l1`.

### Level 1 (side 2): level1data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `L1Header` | 1 of 22 | The level header: restart point, checkpoints and the pointers the game reads. Restart column `$00`, restart wave `$0000`; checkpoint columns `$06`, `$25`, `$4B` with wave entries `$E788`, `$E8AF`, `$EA44`; objects `$D7F9`, map `$E571`, kinds `$EFFB`, movers `$F365` and `$F385`. | - | - |
| `$C4AF` | `L1RestartWave` (`L1Header`+1) | 2 | the wave entry a life restarts at (the game keeps its live copy here) | - | - |
| `$C4B1` | `L1Checks` (`L1Header`+3) | 3 | three checkpoint columns (CheckRestart) | - | - |
| `$C4B4` | `L1WaveStarts` (`L1Header`+6) | 6 | the wave entries of the start and the checkpoints | - | - |
| `$C4BA` | `L1Pointers` (`L1Header`+12) | 10 | objects, map, kinds, movers 1, movers 2 | - | - |
| `$C4C4` | `L1Spare` | 28 | zeros up to the sprites | - | - |
| `$C4E0` | `L1Sprites` | 4889 | The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object table points at | - | - |
| `$D7F9` | `L1Objects` | 280 | The level's object table: width, height, the cells' address (LevelObject) | - | - |
| `$D911` | `L1Metatiles` | 3168 | The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from the map: metatile n at `$E571` - 144 x (n + 1) (MetatileAddress); 22 of them | - | - |
| `$E571` | `L1Map` | 535 | The map: 5 bytes a block column (107 columns), each byte a metatile (bits 0-5) and its drawer (bits 6-7) | - | - |
| `$E788` | `L1Waves` | 2163 | The wave script: entries (scroll position, kind, script) RunWaves starts; then the enemies' movement scripts | - | - |
| `$EFFB` | `L1Kinds` | 874 | The enemy kinds StartWave reads (LevelKinds) | `L1MoverA12`, `L1MoverA13`, `L1MoverA14`, `L1MoverA6` | `L1MoverA12`, `L1MoverA13` |
| `$F365` | `L1MoversA` | 32 | The first mover of each kind (16 words, LevelMoves) | - | - |
| `$F385` | `L1MoversB` | 32 | The second mover of each kind (16 words, LevelMoves2) | - | - |
| `$F42B` | `L1Gap` | 2 | two bytes between the movers (`$30`, `$C9`): no recording reads or runs them (known only from the code) | - | - |
| `$F5E5` | `L1SpawnA` | 3 | A wave record (kind `$0D`, then the position the movers write) passed to StartWaveAt | - | `L1MoverA10` |
| `$F6E4` | `L1SpawnB` | 6 | Two wave records (kinds `$2A` and `$26`) the movers fill and pass to StartWaveAt | - | `L1MoverA13` |
| `$F725` | `L1SpawnC` | 3 | A wave record the movers fill and pass to StartWaveAt | `L1MoverA14` | `L1MoverA14` |
| `$F7EA` | `L1ShapeFrames` | 112 | 16 frames of 7 bytes, a nibble a row (14 rows): the column offsets Mover A9 draws a shape of tag `$80` from, a frame by FrameCounter | `L1MoverA9` | - |


## Level 2 (side 2) (`src/level2/level2.json`)

R-Type, Electric Dreams Software 1988: level 2, 12856 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
44). Its entries are `src/level2/<module>.asm`, written from `src/level2/level2.ann` by `kit/mkgame.py --part
src/level2/level2.json`; the readers and writers from `work/stage1/rec/l2`.

### Level 2 (side 2): level2data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `L2Header` | 1 of 22 | The level header: restart point, checkpoints and the pointers the game reads. Restart column `$00`, restart wave `$0000`; checkpoint columns `$06`, `$2B`, `$FF` with wave entries `$E8B1`, `$EA55`, `$EE60`; objects `$D372`, map `$E762`, kinds `$F197`, movers `$F4BF` and `$F4D3`. | - | - |
| `$C4AF` | `L2RestartWave` (`L2Header`+1) | 2 | the wave entry a life restarts at (the game keeps its live copy here) | - | - |
| `$C4B1` | `L2Checks` (`L2Header`+3) | 3 | three checkpoint columns (CheckRestart) | - | - |
| `$C4B4` | `L2WaveStarts` (`L2Header`+6) | 6 | the wave entries of the start and the checkpoints | - | - |
| `$C4BA` | `L2Pointers` (`L2Header`+12) | 10 | objects, map, kinds, movers 1, movers 2 | - | - |
| `$C4C4` | `L2Spare` | 28 | zeros up to the sprites | - | - |
| `$C4E0` | `L2Sprites` | 3730 | The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object table points at | - | - |
| `$D372` | `L2Objects` | 208 | The level's object table: width, height, the cells' address (LevelObject) | - | - |
| `$D442` | `L2Metatiles` | 4896 | The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from the map: metatile n at `$E762` - 144 x (n + 1) (MetatileAddress); 34 of them | - | - |
| `$E762` | `L2Map` | 335 | The map: 5 bytes a block column (67 columns), each byte a metatile (bits 0-5) and its drawer (bits 6-7) | - | - |
| `$E8B1` | `L2Waves` | 2278 | The wave script: entries (scroll position, kind, script) RunWaves starts; then the enemies' movement scripts | - | - |
| `$F197` | `L2Kinds` | 808 | The enemy kinds StartWave reads (LevelKinds) | `L2MoverA6`, `L2MoverA8` | - |
| `$F4BF` | `L2MoversA` | 20 | The first mover of each kind (10 words, LevelMoves) | - | - |
| `$F4D3` | `L2MoversB` | 32 | The second mover of each kind (16 words, LevelMoves2) | - | - |


## Level 3 (side 2) (`src/level3/level3.json`)

R-Type, Electric Dreams Software 1988: level 3, 13074 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
48). Its entries are `src/level3/<module>.asm`, written from `src/level3/level3.ann` by `kit/mkgame.py --part
src/level3/level3.json`; the readers and writers from `work/stage1/rec/l3`.

### Level 3 (side 2): level3data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `L3Header` | 1 of 22 | The level header: restart point, checkpoints and the pointers the game reads. Restart column `$00`, restart wave `$0000`; checkpoint columns `$00`, `$FF`, `$FF` with wave entries `$E856`, `$EA31`, `$EA31`; objects `$DD8E`, map `$E716`, kinds `$ED50`, movers `$F0A6` and `$F0C6`. | - | - |
| `$C4AF` | `L3RestartWave` (`L3Header`+1) | 2 | the wave entry a life restarts at (the game keeps its live copy here) | - | - |
| `$C4B1` | `L3Checks` (`L3Header`+3) | 3 | three checkpoint columns (CheckRestart) | - | - |
| `$C4B4` | `L3WaveStarts` (`L3Header`+6) | 6 | the wave entries of the start and the checkpoints | - | - |
| `$C4BA` | `L3Pointers` (`L3Header`+12) | 10 | objects, map, kinds, movers 1, movers 2 | - | - |
| `$C4C4` | `L3Spare` | 28 | zeros up to the sprites | - | - |
| `$C4E0` | `L3Sprites` | 6318 | The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object table points at | - | - |
| `$DD8E` | `L3Objects` | 424 | The level's object table: width, height, the cells' address (LevelObject) | - | - |
| `$DF36` | `L3Metatiles` | 2016 | The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from the map: metatile n at `$E716` - 144 x (n + 1) (MetatileAddress); 14 of them | - | - |
| `$E716` | `L3Map` | 320 | The map: 5 bytes a block column (64 columns), each byte a metatile (bits 0-5) and its drawer (bits 6-7) | - | - |
| `$E856` | `L3Waves` | 1274 | The wave script: entries (scroll position, kind, script) RunWaves starts; then the enemies' movement scripts | - | - |
| `$ED50` | `L3Kinds` | 854 | The enemy kinds StartWave reads (LevelKinds) | `L3MoverA3`, `L3MoverA4` | `L3MoverA3`, `L3MoverA4` |
| `$F0A6` | `L3MoversA` | 32 | The first mover of each kind (16 words, LevelMoves) | - | - |
| `$F0C6` | `L3MoversB` | 32 | The second mover of each kind (16 words, LevelMoves2) | - | - |
| `$F6ED` | `L3Tail` | 211 | Bytes after the movers: mover code no recording ran (JR Z / JP `$F3AE` ...) and the records the movers use at `$F752-$F760` (read in the level 3 recording) | `L3MoverA10`, `L3MoverA15`, `L3MoverA7`, `L3MoverA8`, `L3MoverA9` | `L3MoverA10`, `L3MoverA11`, `L3MoverA15`, `L3MoverA7`, `L3MoverA8` |


## Level 4 (side 2) (`src/level4/level4.json`)

R-Type, Electric Dreams Software 1988: level 4, 12998 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
52). Its entries are `src/level4/<module>.asm`, written from `src/level4/level4.ann` by `kit/mkgame.py --part
src/level4/level4.json`; the readers and writers from `work/stage1/rec/l4`.

### Level 4 (side 2): level4data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `L4Header` | 1 of 22 | The level header: restart point, checkpoints and the pointers the game reads. Restart column `$00`, restart wave `$0000`; checkpoint columns `$00`, `$29`, `$FF` with wave entries `$E693`, `$E80F`, `$EABC`; objects `$DB15`, map `$E521`, kinds `$EF8A`, movers `$F2AE` and `$F2CE`. | - | - |
| `$C4AF` | `L4RestartWave` (`L4Header`+1) | 2 | the wave entry a life restarts at (the game keeps its live copy here) | - | - |
| `$C4B1` | `L4Checks` (`L4Header`+3) | 3 | three checkpoint columns (CheckRestart) | - | - |
| `$C4B4` | `L4WaveStarts` (`L4Header`+6) | 6 | the wave entries of the start and the checkpoints | - | - |
| `$C4BA` | `L4Pointers` (`L4Header`+12) | 10 | objects, map, kinds, movers 1, movers 2 | - | - |
| `$C4C4` | `L4Spare` | 28 | zeros up to the sprites | - | - |
| `$C4E0` | `L4Sprites` | 5685 | The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object table points at | - | - |
| `$DB15` | `L4Objects` | 412 | The level's object table: width, height, the cells' address (LevelObject) | - | - |
| `$DCB1` | `L4Metatiles` | 2160 | The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from the map: metatile n at `$E521` - 144 x (n + 1) (MetatileAddress); 15 of them | - | - |
| `$E521` | `L4Map` | 370 | The map: 5 bytes a block column (74 columns), each byte a metatile (bits 0-5) and its drawer (bits 6-7) | - | - |
| `$E693` | `L4Waves` | 2295 | The wave script: entries (scroll position, kind, script) RunWaves starts; then the enemies' movement scripts | - | - |
| `$EF8A` | `L4Kinds` | 804 | The enemy kinds StartWave reads (LevelKinds) | `L4MoverA12`, `L4MoverA13`, `L4MoverA14`, `L4MoverA6` | `L4MoverA12` |
| `$F2AE` | `L4MoversA` | 32 | The first mover of each kind (16 words, LevelMoves) | - | - |
| `$F2CE` | `L4MoversB` | 32 | The second mover of each kind (16 words, LevelMoves2) | - | - |
| `$F4EA` | `L4SpawnA` | 3 | A wave record (kind `$1E`) the movers fill and pass to StartWaveAt | - | `L4MoverA9` |
| `$F6E2` | `L4SpawnB` | 3 | A wave record the movers fill and pass to StartWaveAt | `L4MoverA14` | `L4MoverA14` |


## Level 5 (side 2) (`src/level5/level5.json`)

R-Type, Electric Dreams Software 1988: level 5, 8904 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
56). Its entries are `src/level5/<module>.asm`, written from `src/level5/level5.ann` by `kit/mkgame.py --part
src/level5/level5.json`; the readers and writers from `work/stage1/rec/l5`.

### Level 5 (side 2): level5data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `L5Header` | 1 of 22 | The level header: restart point, checkpoints and the pointers the game reads. Restart column `$00`, restart wave `$0000`; checkpoint columns `$00`, `$23`, `$FF` with wave entries `$D62C`, `$D8E8`, `$DA5A`; objects `$D14E`, map `$D4BA`, kinds `$DEC4`, movers `$E1AC` and `$E1C8`. | - | - |
| `$C4AF` | `L5RestartWave` (`L5Header`+1) | 2 | the wave entry a life restarts at (the game keeps its live copy here) | - | - |
| `$C4B1` | `L5Checks` (`L5Header`+3) | 3 | three checkpoint columns (CheckRestart) | - | - |
| `$C4B4` | `L5WaveStarts` (`L5Header`+6) | 6 | the wave entries of the start and the checkpoints | - | - |
| `$C4BA` | `L5Pointers` (`L5Header`+12) | 10 | objects, map, kinds, movers 1, movers 2 | - | - |
| `$C4C4` | `L5Spare` | 28 | zeros up to the sprites | - | - |
| `$C4E0` | `L5Sprites` | 3182 | The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object table points at | - | - |
| `$D14E` | `L5Objects` | 156 | The level's object table: width, height, the cells' address (LevelObject) | - | - |
| `$D1EA` | `L5Metatiles` | 720 | The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from the map: metatile n at `$D4BA` - 144 x (n + 1) (MetatileAddress); 5 of them | - | - |
| `$D4BA` | `L5Map` | 370 | The map: 5 bytes a block column (74 columns), each byte a metatile (bits 0-5) and its drawer (bits 6-7) | - | - |
| `$D62C` | `L5Waves` | 2200 | The wave script: entries (scroll position, kind, script) RunWaves starts; then the enemies' movement scripts | - | - |
| `$DEC4` | `L5Kinds` | 744 | The enemy kinds StartWave reads (LevelKinds) | `L5MoverA10`, `L5MoverA6`, `L5MoverA9`, `L5SlotBusy` | `L5MoverA10`, `L5MoverA6`, `L5MoverA9` |
| `$E1AC` | `L5MoversA` | 28 | The first mover of each kind (14 words, LevelMoves) | - | - |
| `$E1C8` | `L5MoversB` | 32 | The second mover of each kind (16 words, LevelMoves2) | - | - |
| `$E317` | `L5SpawnA` | 3 | A wave record (kind `$0A`) the movers fill and pass to StartWaveAt | - | `L5MoverA7`, `L5MoverA8` |
| `$E33E` | `L5SpawnB` | 3 | A wave record (kind `$0A`): nothing in the level names it (known only from the code) | - | - |
| `$E641` | `L5SlotDirs` | 82 | Three bytes a slot (by DrawTag): the direction L5SlotDir returns for Mover A9 | `L5MoverA9`, `L5SlotDir` | `L5MoverA9` |


## Level 6 (side 2) (`src/level6/level6.json`)

R-Type, Electric Dreams Software 1988: level 6, 8849 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
60). Its entries are `src/level6/<module>.asm`, written from `src/level6/level6.ann` by `kit/mkgame.py --part
src/level6/level6.json`; the readers and writers from `work/stage1/rec/l6`.

### Level 6 (side 2): level6data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `L6Header` | 1 of 22 | The level header: restart point, checkpoints and the pointers the game reads. Restart column `$00`, restart wave `$DADD`; checkpoint columns `$00`, `$27`, `$FF` with wave entries `$DADD`, `$DBFA`, `$DD26`; objects `$CC33`, map `$D9A7`, kinds `$E362`, movers `$E612` and `$E620`. | - | - |
| `$C4AF` | `L6RestartWave` (`L6Header`+1) | 2 | the wave entry a life restarts at (the game keeps its live copy here) | - | - |
| `$C4B1` | `L6Checks` (`L6Header`+3) | 3 | three checkpoint columns (CheckRestart) | - | - |
| `$C4B4` | `L6WaveStarts` (`L6Header`+6) | 6 | the wave entries of the start and the checkpoints | - | - |
| `$C4BA` | `L6Pointers` (`L6Header`+12) | 10 | objects, map, kinds, movers 1, movers 2 | - | - |
| `$C4C4` | `L6Spare` | 28 | zeros up to the sprites | - | - |
| `$C4E0` | `L6Sprites` | 1875 | The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object table points at | - | - |
| `$CC33` | `L6Objects` | 132 | The level's object table: width, height, the cells' address (LevelObject) | - | - |
| `$CCB7` | `L6Metatiles` | 3312 | The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from the map: metatile n at `$D9A7` - 144 x (n + 1) (MetatileAddress); 23 of them | - | - |
| `$D9A7` | `L6Map` | 310 | The map: 5 bytes a block column (62 columns), each byte a metatile (bits 0-5) and its drawer (bits 6-7) | - | - |
| `$DADD` | `L6Waves` | 2181 | The wave script: entries (scroll position, kind, script) RunWaves starts; then the enemies' movement scripts | - | - |
| `$E362` | `L6Kinds` | 688 | The enemy kinds StartWave reads (LevelKinds) | `L6MoverA3`, `L6MoverA4` | `L6MoverA3`, `L6MoverA4` |
| `$E612` | `L6MoversA` | 14 | The first mover of each kind (7 words, LevelMoves) | - | - |
| `$E620` | `L6MoversB` | 32 | The second mover of each kind (16 words, LevelMoves2) | - | - |


## Level 7 (side 2) (`src/level7/level7.json`)

R-Type, Electric Dreams Software 1988: level 7, 12997 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
64). Its entries are `src/level7/<module>.asm`, written from `src/level7/level7.ann` by `kit/mkgame.py --part
src/level7/level7.json`; the readers and writers from `work/stage1/rec/l7`.

### Level 7 (side 2): level7data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `L7Header` | 1 of 22 | The level header: restart point, checkpoints and the pointers the game reads. Restart column `$00`, restart wave `$0000`; checkpoint columns `$00`, `$2D`, `$FF` with wave entries `$E86A`, `$E9DC`, `$ED01`; objects `$D150`, map `$E6F8`, kinds `$F153`, movers `$F4B1` and `$F4CF`. | - | - |
| `$C4AF` | `L7RestartWave` (`L7Header`+1) | 2 | the wave entry a life restarts at (the game keeps its live copy here) | - | - |
| `$C4B1` | `L7Checks` (`L7Header`+3) | 3 | three checkpoint columns (CheckRestart) | - | - |
| `$C4B4` | `L7WaveStarts` (`L7Header`+6) | 6 | the wave entries of the start and the checkpoints | - | - |
| `$C4BA` | `L7Pointers` (`L7Header`+12) | 10 | objects, map, kinds, movers 1, movers 2 | - | - |
| `$C4C4` | `L7Spare` | 28 | zeros up to the sprites | - | - |
| `$C4E0` | `L7Sprites` | 3184 | The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object table points at | - | - |
| `$D150` | `L7Objects` | 216 | The level's object table: width, height, the cells' address (LevelObject) | - | - |
| `$D228` | `L7Metatiles` | 5328 | The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from the map: metatile n at `$E6F8` - 144 x (n + 1) (MetatileAddress); 37 of them | - | - |
| `$E6F8` | `L7Map` | 370 | The map: 5 bytes a block column (74 columns), each byte a metatile (bits 0-5) and its drawer (bits 6-7) | - | - |
| `$E86A` | `L7Waves` | 2281 | The wave script: entries (scroll position, kind, script) RunWaves starts; then the enemies' movement scripts. The entry at `$EC16` has command `$5D`: no handler, it falls through CommandWave and does nothing (a data slip). | - | - |
| `$F153` | `L7Kinds` | 862 | The enemy kinds StartWave reads (LevelKinds) | `L7MoverA10`, `L7MoverA13`, `L7MoverA6` | `L7MoverA10`, `L7MoverA6` |
| `$F4B1` | `L7MoversA` | 30 | The first mover of each kind (15 words, LevelMoves) | - | - |
| `$F4CF` | `L7MoversB` | 32 | The second mover of each kind (16 words, LevelMoves2) | - | - |
| `$F526` | `L7SpawnA` | 3 | A wave record (kind `$24`) the movers fill and pass to StartWaveAt | - | `L7MoverA3` |
| `$F56D` | `L7SpawnB` | 3 | A wave record the movers fill and pass to StartWaveAt | - | `L7MoverA4` |
| `$F6F9` | `L7SpawnC` | 3 | A wave record the movers fill and pass to StartWaveAt | `L7MoverA13` | `L7MoverA13` |


## Level 8 (side 2) (`src/level8/level8.json`)

R-Type, Electric Dreams Software 1988: level 8, 11980 bytes loaded at `$C4AE` by LoadLevel `$FE03` (tape TZX block
68). Its entries are `src/level8/<module>.asm`, written from `src/level8/level8.ann` by `kit/mkgame.py --part
src/level8/level8.json`; the readers and writers from `work/stage1/rec/l8`.

### Level 8 (side 2): level8data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4AE` | `L8Header` | 1 of 22 | The level header: restart point, checkpoints and the pointers the game reads. Restart column `$00`, restart wave `$0000`; checkpoint columns `$00`, `$FF`, `$FF` with wave entries `$E6EC`, `$E8EF`, `$E8EF`; objects `$D99C`, map `$E354`, kinds `$EBCA`, movers `$EEAC` and `$EECC`. | - | - |
| `$C4AF` | `L8RestartWave` (`L8Header`+1) | 2 | the wave entry a life restarts at (the game keeps its live copy here) | - | - |
| `$C4B1` | `L8Checks` (`L8Header`+3) | 3 | three checkpoint columns (CheckRestart) | - | - |
| `$C4B4` | `L8WaveStarts` (`L8Header`+6) | 6 | the wave entries of the start and the checkpoints | - | - |
| `$C4BA` | `L8Pointers` (`L8Header`+12) | 10 | objects, map, kinds, movers 1, movers 2 | - | - |
| `$C4C4` | `L8Spare` | 28 | zeros up to the sprites | - | - |
| `$C4E0` | `L8Sprites` | 5308 | The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object table points at | - | - |
| `$D99C` | `L8Objects` | 184 | The level's object table: width, height, the cells' address (LevelObject) | - | - |
| `$DA54` | `L8Metatiles` | 2304 | The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from the map: metatile n at `$E354` - 144 x (n + 1) (MetatileAddress); 16 of them | - | - |
| `$E354` | `L8Map` | 920 | The map: 5 bytes a block column (184 columns), each byte a metatile (bits 0-5) and its drawer (bits 6-7) | - | - |
| `$E6EC` | `L8Waves` | 1246 | The wave script: entries (scroll position, kind, script) RunWaves starts; then the enemies' movement scripts | - | - |
| `$EBCA` | `L8Kinds` | 738 | The enemy kinds StartWave reads (LevelKinds) | - | - |
| `$EEAC` | `L8MoversA` | 32 | The first mover of each kind (16 words, LevelMoves) | - | - |
| `$EECC` | `L8MoversB` | 32 | The second mover of each kind (16 words, LevelMoves2) | - | - |
| `$EF8E` | `L8Vars` | 4 | Four bytes Mover A3's code keeps | `L8MoverA3` | `L8MoverA3` |
| `$EFC2` | `L8SpawnA` | 3 | A wave record (kind `$1B`) filled with a slot's position and passed to StartWaveAt | - | `L8MoverA3`, `l_EF9A` (code) |
| `$F12E` | `L8Tail` | 588 | Bytes after the code (words `$F457`, `$F423` ..., `$ED06` ...): no code of the level names them, no level 8 recording reads them | - | - |
