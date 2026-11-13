# 11. Data reference

Every data entry of the main program's image `$6C3F`-`$F03E`, in address order by module (`src/stage1/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/stage1/stage1.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1o`, `work/stage2/rec/rzx-r1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`), The front
(TZX block 37), Stage 2 (TZX block 43), Stage 3 (TZX block 46), Stage 4 (TZX block 49), Stage 5 (TZX block 52), The
tape BASIC (TZX block 2), The decryption chain and the SpeedLock loader, The second stage (TZX block 7), Unxor (TZX
block 29), Sl1End (TZX block 31), Boot (TZX blocks 33 and 35)) follow the main program, each under its own heading
with its modules, its source, its annotations and its recordings.

## variables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6C3F` | `PlayBufferTail` | 193 | The last 193 bytes of the play buffer PlayBuffer `$5B00-$6CFF` (character row 17's last lines). ClearBuffer `$9AB5` clears the play buffer to `$6CFF` with PUSH HL (SP from `$6D00`); RoomChange `$988B` unpacks the stage's tiles and map into it from `$5B00` (4295 bytes, to `$6BC6`); the actors are drawn into it every pass. Zero as loaded. Read in all four stage-1 builds (c1o, deaths, s1-idle, s1-right: CopyBuffer `$9ADA`). | `CopyBuffer`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored` +4 | `DrawActorSprite`, `DrawSprite`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` +6 |
| `$6D00` | `ShadowAttributes` | 192 of 768 | The shadow of the screen's 768 attributes, the screen's layout; the play area from `$6DC2` (row 6, column 2). The HUD's colours are copied into rows 0-5 at the stage's set-up (StageSetUp `$97AC`); RoomChange `$988B` writes each cell's attribute into rows 6-23, the actors' colours are painted over them every pass, and UpdateAttributes `$8CAA` copies the open cells to `$5800` (ShowShadowAttributes `$8C9D` the whole of it). FillShadowAttributes `$8C6D` paints rectangles into it with five bytes after its CALL. Zero as loaded. | `ClearShadowAttributes`, `DrawRoomPicture`, `FadeInStep`, `PlotRow3Mirrored`, `SavePlayAttrs` +3 | `ClearShadowAttributes`, `ColourActor`, `ColourSprite`, `ColourSpriteMirrored`, `DrawArenaPicture` +11 |
| `$6DC0` | `PlayAttributes` (`ShadowAttributes`+192) | 2 | row 6: the first row of the play area (the room's 18 rows) | `ClearShadowAttributes`, `DrawRoomPicture`, `PlotRow3Mirrored`, `SavePlayAttrs`, `ShowShadowAttributes` | `ClearShadowAttributes`, `DrawRoomPicture`, `PlotRow3Mirrored`, `SaveAttributes` |
| `$6DC2` | `PlayAttributesCell` (`ShadowAttributes`+194) | 574 | row 6, column 2: the room's first cell | `ClearShadowAttributes`, `DrawRoomPicture`, `FadeInStep`, `PlotRow3Mirrored`, `SavePlayAttrs` +2 | `ClearShadowAttributes`, `ColourActor`, `ColourSprite`, `ColourSpriteMirrored`, `DrawArenaPicture` +7 |
| `$7000` | `HudPicture` | 64 of 1728 | The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their colours at `$7600` (6 rows of 32). DissolveHud `$8AB1` dissolves the 48 lines onto the screen's lines 0-47 and StageSetUp `$97AC` copies the 192 colours into the shadow rows 0-5, once, at the stage's start. EndStage `$789E` saves the screen's lines 0-47 back here (CopyScreenToBlock, called at `$790D`) and the attributes `$5800-$58BF` to `$7600` (`$78B2`), so the next stage's block shows the HUD as the player left it. Between the two the bytes are the records labelled inside (RoomAttributes, Cells, HeroRecord, Actors, Missiles, DigitBuffer, SpanTable). The picture: the frame of the HUD, the energy bar's box, the score box, the item strip's box, the lives and pieces boxes (docs/img). Read in all four stage-1 builds. | `AddMissileFrom`, `AddMissileHigh`, `ArenaHeadActor`, `AttrShadowAddress`, `AttrShadowAddressA` +133 | `AddMissileFrom`, `AddMissileHigh`, `AddSpan`, `ArenaHeadActor`, `BossBodySprite` +86 |
| `$7040` | `RoomAttributes` (`HudPicture`+64) | 2 | `$7040-$727F`: the old room's play colours (SavePlayAttrs `$9FA5`: 576 bytes, rows 6-23) and the cells' twins (`$7042` + row x 32 + column: PutBlock writes 0, UpdateAttributes reads the solid cells' colours); also the burst's particles (StartBurst `$A1F3`, 4 bytes each) | `AttrShadowAddressA`, `DissolveHud`, `UpdateBurst` | `CopyScreenToBlock`, `SavePlayAttrs`, `StartBurst`, `UpdateBurst` |
| `$7042` | `RoomAttributesCell` (`HudPicture`+66) | 574 | the twin of the cell `$7282` (576 bytes lower) | `AttrShadowAddressA`, `DissolveHud`, `UpdateAttributes`, `UpdateBurst` | `ColourActor`, `CopyScreenToBlock`, `PutBlock`, `SavePlayAttrs`, `StartBurst` +1 |
| `$7280` | `Cells` (`HudPicture`+640) | 2 | the room's cells: 19 rows of 32 (tile numbers, then their kinds after BuildSpans `$99E9`; bit 1 solid, bit 3 deadly, kind 7 a bridge slab) | `DissolveHud`, `StartGrid` | `CopyScreenToBlock`, `StartGrid` |
| `$7282` | `CellsPlay` (`HudPicture`+642) | 574 | row 0, column 2: the room's first cell (RoomCells `$9928` writes 28 x 18) | `BuildSpans`, `CellAt`, `CellUnderFeet`, `DissolveHud`, `RoomChange` +2 | `BridgeSlabActor`, `BuildSpans`, `CopyScreenToBlock`, `PutBlock`, `StartGrid` |
| `$74C0` | `CellsFloor` (`HudPicture`+1216) | 32 | row 18 below the room: 32 bytes of `$FF` (StartGrid `$A444`), a floor no actor falls through | `CellAt`, `DissolveHud`, `StartGrid`, `CellUnderFeet` (`stage1/rec/s1-right`) | `CopyScreenToBlock`, `StartGrid` |
| `$74E0` | `HeroRecord` (`HudPicture`+1248) | 1 | the hero's actor record (18 bytes; +0 X) | `BufferAddressDE`, `CellUnderFeet`, `CheckGridPassages`, `CheckItemGate`, `CheckLeftGate` +29 | `CopyScreenToBlock`, `HeroDeath`, `SetActorFrame`, `ShiftRoomColumns`, `SpawnActor` |
| `$74E1` | `HeroY` (`HudPicture`+1249) | 7 | +1 the hero's line | `BufferAddressDE`, `CellUnderFeet`, `CheckRoomExits`, `CheckStageExit`, `ClipActor` +21 | `CopyScreenToBlock`, `HeroDeath`, `SetActorFrame`, `ShiftRoomRows`, `SpawnActor` |
| `$74E8` | `HeroFrame` (`HudPicture`+1256) | 1 | +8 the frame number of the hero's set | `BufferAddressDE`, `CheckHeroFooting`, `ClipActor`, `ColourActor`, `DissolveHud` +18 | `CheckHeroFooting`, `CopyScreenToBlock`, `HeroFall`, `HeroFireHeld`, `HeroJump` +15 |
| `$74E9` | `HeroFlags` (`HudPicture`+1257) | 1 | +9 bit 7: facing left | `BufferAddressDE`, `CellUnderFeet`, `CheckGridPassages`, `CheckItemGate`, `CheckLeftGate` +22 | `CopyScreenToBlock`, `HeroStand`, `HeroTurn`, `RespawnCountdown`, `SetActorFrame` +1 |
| `$74EA` | `HeroState` (`HudPicture`+1258) | 2 | +`$0A` 0 stand, 1 walk, 2 jump, 3 fall, 4 leap back, 5-7 strikes, 9 leap up, `$0B` recoil, `$0F` dying (HeroUpdate `$AC3D`) | `BufferAddressDE`, `CheckGridPassages`, `CheckHeroFooting`, `CheckRoomExits`, `ClipActor` +18 | `CopyScreenToBlock`, `HeroDeath`, `HeroFall`, `HeroFireHeld`, `HeroJump` +15 |
| `$74EC` | `HeroAttribute` (`HudPicture`+1260) | 1 | +`$0C` the hero's attribute | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +4 | `CopyScreenToBlock`, `HeroColour`, `HeroDeath`, `SetActorFrame`, `SpawnActor` |
| `$74ED` | `HeroBaseX` (`HudPicture`+1261) | 1 | +`$0D` the base column | `BufferAddressDE`, `CheckRightGate`, `ClipActor`, `ColourActor`, `DissolveHud` +9 | `CopyScreenToBlock`, `HeroDeath`, `MoveBaseX`, `RespawnCountdown`, `SetActorFrame` +4 |
| `$74EE` | `HeroBaseY` (`HudPicture`+1262) | 2 | +`$0E` the base line | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +8 | `CopyScreenToBlock`, `HeroDeath`, `HeroFall`, `MoveActorY`, `RespawnCountdown` +3 |
| `$74F0` | `HeroCounter` (`HudPicture`+1264) | 2 | +`$10` the pause after a death (HeroDeath `$B22B`) | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +8 | `CopyScreenToBlock`, `HeroDeath`, `HeroFireHeld`, `HeroStrikeMid`, `RespawnCountdown` +2 |
| `$74F2` | `Actors` (`HudPicture`+1266) | 216 | the 13 other actor records, 18 bytes each (`$74F2-$75DB`); +0 = `$FF` a free record | `ArenaHeadActor`, `BossBodySprite`, `BossBurst`, `BossFall`, `BossHead` +58 | `ArenaHeadActor`, `BossBodySprite`, `BossColour`, `BossFall`, `BossFlees` +39 |
| `$75CA` | `LastActor` (`HudPicture`+1482) | 18 | the 13th record | `BufferAddressDE`, `ClearActors`, `ClipActor`, `ColourActor`, `DissolveHud` +28 | `ClearActors`, `CopyScreenToBlock`, `FirePitActor`, `FlameJetActor`, `HangingActor` +8 |
| `$75DC` | `ActorsEnd` (`HudPicture`+1500) | 4 | 4 bytes past the records: only the HUD picture's (DissolveHud, EndStage's save) bytes | `DissolveHud` | `CopyScreenToBlock` |
| `$75E0` | `Missiles` (`HudPicture`+1504) | 32 | the 16 missile records, 6 bytes each (`$75E0-$763F`): +0 the column (`$FF` free), +1 the line, +2 the kind (MissileHandlers `$B31A`), +3 to +5 the kind's own | `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL`, `CheckArcLanding` +13 | `AddMissileFrom`, `CheckArcLanding`, `CheckBounceFloor`, `ClearShots`, `CopyScreenToBlock` +6 |
| `$7600` | `HudColours` (`HudPicture`+1536) | 16 | the HUD's 192 colours as loaded (rows 0-5); in play the missile records 4-15 lie over them | `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL`, `CheckArcLanding` +13 | `AddMissileFrom`, `CheckArcLanding`, `CheckBounceFloor`, `ClearShots`, `EndStageSave` +6 |
| `$7610` | `MissilesHigh` (`HudPicture`+1552) | 48 | missile records 8-15 (AddMissileHigh `$B296`: the hero's death sparks) | `AddMissileFrom`, `AddMissileHigh`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL` +7 | `AddMissileFrom`, `AddMissileHigh`, `ClearShots`, `EndStageSave`, `HeroDeath` +3 |
| `$7640` | `DigitBuffer` (`HudPicture`+1600) | 96 | in play: the score's digit picture (6 + 2 columns x 8 lines, RenderScore `$7B73`, RevealScore `$985D`) and a sprite's shifted copy (PreShiftSprite `$7F4D`) | `CopyToScreen`, `PlotRow2`, `PlotRow2Mirrored`, `ShiftLine1`, `ShiftLine4` +1 | `ClearShots`, `EndStageSave`, `PreShiftSprite`, `RenderDigits`, `ShiftLine1` +1 |
| `$76A0` | `SpanTable` (`HudPicture`+1696) | 32 | in play: the open spans CopyBuffer copies, 6 bytes each (the length, 0, the buffer address, the screen address; SpanCount spans), on to `$779B` | `BuildSpans`, `StageSetUp` | `AddSpan`, `BuildSpans`, `EndStageSave` |
| `$76C0` | `SpanTableRest` | 220 | The span table's room past the HUD's colours: spans 6-42 (`$76C0-$779B`). BuildSpans `$99E9` and AddSpan `$9A6E` write the spans from `$76A0` on; a room of many short runs reaches into this space. Zero as loaded. In the stage-1 builds 34 of its bytes are read. | `BuildSpans` | `AddSpan`, `BuildSpans` |
| `$779C` | `Unused779C` | 100 | 100 bytes no code reads or writes (the four stage-1 builds); zero as loaded | - | - |

## entry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$97D5` | `HudBox1` | 5 | FillShadowAttributes' data: column, line, width, height, colour | `FillShadowAttributes` | - |
| `$97DD` | `HudBox2` | 5 | the item strip (column 10, line 24, 12 x 2): bright blue on black | `FillShadowAttributes` | - |
| `$97E5` | `HudBox3` | 5 | the item box | `FillShadowAttributes` | - |
| `$97ED` | `HudBox4` | 5 | the play area: black | `FillShadowAttributes` | - |

## mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$78A5` | `EndPiecesBox` | 5 | `$8C3D`'s inline record: column 25, line 24, 6 x 2 cells, attribute 1 (the pieces boxes hidden) | `FillAttributes` | - |
| `$78AD` | `EndLivesBox` | 5 | `$8C3D`'s inline record: column 1, line 24, 6 x 2 cells, attribute 1 (the lives boxes hidden) | `FillAttributes` | - |

## render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7F90` | `ShiftRoutines` | 16 | The shift routine for 1-7 pixels (entry 0 unused) | `PreShiftSprite` | - |
| `$8910` | `RowPlotters` | 32 | The row plotter of each sprite width: word 2 x width + 1 when mirrored. Read by the sprite drawer at `$A6CA` (LD BC,RowPlotters): index 2 x width + (facing left). Width 0 and the mirrored width 7 hold `$876C` (a hang loop: border flicker and KeyHook forever), never reached with a valid frame. | `DrawActorSprite` | - |
| `$A799` | `ItemInks` | 4 | CycleItemInk's four attributes | - | - |
| `$B3B9` | `MissileColours` | 4 | bright red, bright magenta, bright red, magenta | `MissileColour` | - |
| `$B3D2` | `CycleColours` | 8 | the colour cycle | `CycleColour`, `FlashPieces` | - |
| `$B3EA` | `ImageDescriptors` | 16 | Four image descriptors: the image address, the width in bytes, the height in lines. `$EBEC`, `$EC13`, `$EC3A` and `$EC61`, each 3 x 13. Read through HL from `$83DF` and `$84B2`. | `ColourSprite`, `ColourSpriteMirrored`, `DrawDriftShot`, `DrawSprite`, `UpdatePathFlyer` | - |
| `$B3FA` | `SpeedSteps` | 16 | 16 signed steps -4 .. 4, two each: no reader found (known only from the code) | - | - |

## util

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8BA3` | `BlankIcon` | 32 | 32 zero bytes: the blank icon (item kind 4) and the source of every clear done by copying with stride 0. ItemIcons' kind 4 points here (DrawItemIcon `$7E19` reads all 32 bytes); CopyToScreen `$79CC` copies its first bytes with stride 0 to clear the play area (StageEntry), the HUD fields (EndStage) and the item strip (GameOverStep); the templates' frame word (`$9D3B` and others) points here until SetActorFrame sets a frame. Read in the stage-1 builds (DrawItemIcon, `$79CC`). | `CopyToScreen`, `DrawItemIcon` | - |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7ABA` | `StarPixels` | 32 | The two pixel lines of a star, by speed (rows 1-4) and pixel (pairs 0-3) | `MoveStar` | - |
| `$7C1E` | `ScoreDigits` | 2 of 9 | The score as text: two unused bytes, ScoreHigh's two digits, Score's four digits, 0 | `RenderDigits`, `ShowScore` | `ByteToDigits`, `NumberToDigits` |
| `$7C20` | `ScoreDigitsHigh` (`ScoreDigits`+2) | 2 | ScoreHigh's two digits (`$8C15`); EndStage returns this address in BC | `RenderDigits`, `ShowScore` | `ByteToDigits` |
| `$7C22` | `ScoreDigitsLow` (`ScoreDigits`+4) | 4 | Score's four digits (`$8BE3`) | `RenderDigits`, `ShowScore` | `NumberToDigits` |
| `$7C26` | `ScoreDigitsEnd` (`ScoreDigits`+8) | 1 | 0: the end mark | `RenderDigits`, `ShowScore` | - |
| `$83A3` | `GameOverBox` | 5 | `$8C3D`'s inline record: column 12, line 24, 8 x 2 cells, the colour (patched) | `FillAttributes` (`stage1/rec/s1-right`) | `GameOverStep` (`stage1/rec/s1-right`) |
| `$A41C` | `BarMasks` | 8 | The left-aligned masks of 0-7 pixels for the bar's last byte | `DrawEnergyBar`, `UpdateBurst` | - |

## hero

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7C7B` | `SelectedBoxRecord` | 5 | `$8C3D`'s inline record: column 15, line 24, 2 x 2 cells, the colour (patched) | `FillAttributes` | `FlashSelectedBoxFrame` |
| `$7D16` | `WindowFrameColours` | 16 | The frame's 16 inks: 1 to 7 and back | `CycleWindowFrame` | - |
| `$7DC8` | `ItemCountText` | 5 | The count as text for RenderDigits: two unused bytes, two digits, 0 | `RenderDigits`, `ShowItemCount` | `FormatItemCount` |
| `$7F17` | `CarriedItems` | 12 | The item kind of each of the 12 slots (slots 0-3 hold 4, the blank icon; the first item at slot 6) | `AddItem`, `CheckItemGate`, `DrawItemStrip`, `GetSelectedItem` | `AddItem`, `InitStageState` |
| `$7F23` | `CarriedCounts` | 12 | The amount of each slot's item (shown by ShowItemCount; AddItem adds) | `AddItem`, `DrainItemCharge`, `DrawItemStrip`, `FormatItemCount`, `GetSelectedItem` +4 | `AddItem`, `DrainItemCharge`, `ThrowAmmo`, `ThrowItem` |
| `$7F2F` | `StartItems` | 12 | The carried items at the stage's start, copied to CarriedItems by `$9DA1`: slot 6 holds item 3 | `FormatItemCount`, `InitStageState` | `AddItem` |
| `$7F3B` | `ItemIcons` | 18 | The 16 x 16 icon of each item kind 0-8 (32 bytes each; kind 4 points to the blank `$8BA3`) | `DrawItemIcon` | - |
| `$874C` | `RecoilSteps` | 7 | The hop's y change at steps 0-6 | - | - |
| `$929D` | `RespawnPoints` | 36 of 44 | Column, line of each room: grid 0 (18 rooms), grid 1 (3) at `$92C1`, grid 2 (1) at `$92C7` | `RespawnPoint` | - |
| `$92C1` | `RespawnPointsShaft` (`RespawnPoints`+36) | 6 | grid 1 | - | - |
| `$92C7` | `RespawnPointsArena` (`RespawnPoints`+42) | 2 | grid 2 | - | - |
| `$ADE5` | `HeroStandSet` | 4 | SetActorFrame's parameters: the walk frame table, its graphics | `SetActorFrame` | - |
| `$AE82` | `HeroStrikeLowSet` | 4 | the strike frame table, its graphics | `SetActorFrame` | - |
| `$AE86` | `HeroStrikeLowFrames` | 8 | the strike set's frame for each pass of the low strike | `HeroStrikeLow`, `SetActorFrame` | - |
| `$AEC6` | `HeroStrikeMidSet` | 4 | the strike frame table, its graphics | `SetActorFrame` | - |
| `$AECA` | `HeroStrikeMidFrames` | 10 | the strike set's frame (less 6) for each pass of the middle strike | `HeroStrikeMid`, `SetActorFrame` | - |
| `$AF0C` | `HeroStrikeHighSet` | 4 | the strike frame table, its graphics | `SetActorFrame` | - |
| `$AF10` | `HeroStrikeHighFrames` | 11 | the strike set's frame for each pair of passes of the high strike | `HeroStrikeHigh`, `SetActorFrame` | - |
| `$AFD7` | `HeroWalkSet` | 4 | the walk frame table (`$0D` frames; `$0C` stands), its graphics | `SetActorFrame` | - |
| `$B0AF` | `HeroJumpSet` | 4 | the jump frame table (`$13` frames), its graphics | `SetActorFrame` | - |
| `$B0EC` | `HeroLeapSet` | 4 | the leap frame table (`$0E` frames), its graphics | `SetActorFrame` | - |
| `$B106` | `TurnSteps` | 12 | the base-column move of a turn at each walk frame | `HeroTurn` | - |

## missiles

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8079` | `ArcSteps` | 23 | The arc's y change at each step 0-22 | `UpdateThrownArc` | - |
| `$8090` | `ArcFrame` | 4 | The thrown object's frame record: a word (0, the graphics come in HL), 2 bytes wide, 6 lines | `ColourSprite`, `DrawSprite` | - |
| `$813D` | `ShotFrames` | 20 | Frame records: graphics address, width, lines (`$C783` 2x5, `$C78D` 1x15, `$C79C` 1x15, `$C7AB` 2x13, `$C7C5` 2x13) | `ColourSprite`, `ColourSpriteMirrored`, `DrawSprite`, `DrawSpriteMirrored`, `UpdateHeroShot` | - |
| `$8151` | `ShotDirections` | 32 | The 8 directions: dx, dy, the frame's offset in ShotFrames, 1 mirrored | - | - |
| `$84EE` | `PathSteps` | 118 | The flyer's path: dx (half columns), dy a step; `$64` `$64` ends | `UpdatePathFlyer` | - |
| `$85C4` | `FlatShotFrame` | 4 | Frame record: graphics `$D986`, 2 bytes wide, 8 lines | `ColourSprite`, `DrawSprite`, `UpdateFlatShot` | - |
| `$863D` | `BounceFrames` | 8 | Two frame records: `$D996` and `$D9B0`, 2 bytes x 13 lines | `ColourSprite`, `DrawSprite`, `UpdateBouncer` | - |
| `$8645` | `BounceSteps` | 51 | The bouncer's y change at steps 1-44; the last 6 bytes (`$8672-$8677`) are never read (the step stops at 45) | `UpdateBouncer` | - |

## enemies

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8275` | `PieceFrames` | 4 | `$AA02`'s inline operands: the frame table `$E154` and the graphics base `$E06C` | `SetActorFrame` | - |
| `$82AE` | `RiseSteps` | 30 | The rising piece's y change at each step 0-29 | `UpdatePieceActor` | - |
| `$8997` | `EyeFlashColours` | 10 | The eye colours of one flash, read backwards: black, then bright blue to cyan and back | `DrawRoomPicture` | - |
| `$8DC6` | `FirePitFrames` | 4 | SetFrame's data: the frame records `$C36D`, the sprite bytes `$C2D1` (4 frames of flames) | `SetActorFrame` | - |
| `$8DCA` | `FirePitColours` | 2 | The pit's two colours, bright red and bright magenta on black | `FirePitActor`, `SetActorFrame` | - |
| `$8E3D` | `FlameJetFrames` | 4 | SetFrame's data: the frame records `$C4E5`, the sprite bytes `$C391` | `SetActorFrame` | - |
| `$8E41` | `FlameJetLong` | 13 | The long jet's frames | `FlameJetActor` | - |
| `$8E4E` | `FlameJetShort` | 8 | The short jet's frames | `FlameJetActor` | - |
| `$8F6D` | `BossHeadFrames` | 26 | The head's sprite at each attack step 5-17 (open and close the mouth) | `BossPart` | - |
| `$8FE8` | `BossFallSteps` | 11 | The lines the falling body drops by, from rising (-4) to falling fast (5) | `BossFall` | - |
| `$901D` | `BossColours` | 8 | The boss's colours over 8 passes (ink 7 down to 3 and back) | `BossColour` | - |
| `$9025` | `BossHoverPath` | 64 | The line steps of the hover, 64 bytes (+8 & `$3F`); `$80` ends the hover | `BossPart` | - |
| `$911F` | `ArenaHeadFrames` | 4 | SetFrame's data: the frame records `$D0CC`, the sprite bytes `$CED2` | `SetActorFrame` | - |
| `$9123` | `ArenaHeadMouth` | 8 | The frame at each count 0-7 (1: the mouth open) | `ArenaHeadActor`, `SetActorFrame` | - |
| `$917C` | `StatueFrames` | 4 | SetFrame's data: the frame records `$DB1A`, the sprite bytes `$DA00` | `SetActorFrame` | - |
| `$9180` | `StatueFrameSeq` | 6 | The frames of one spit | `StatueActor` | - |
| `$93AF` | `SpawnRooms` | 18 | Per room: bits 0-3 the 4 spawn places allowed, bit 4 the lower line | `SpawnRandomEnemy` | - |
| `$9436` | `WarriorHeadSteps` | 17 | The head's frames while it comes down | `WarriorHeadActor` | - |
| `$947C` | `WarriorHeadArc` | 32 | The head's line steps of the flight (32 bytes) | `WarriorHeadActor` | - |
| `$9500` | `UnusedRet` | 1 | A RET no code reaches | - | - |
| `$960F` | `WarriorWalkFrames` | 18 | The walk's frames (14-17) | `WarriorWalk` | - |
| `$96B9` | `UnusedRet2` | 1 | A RET no code reaches | - | - |
| `$9719` | `WarriorCollapseFrames` | 4 | SetFrame's data: the frame records `$DD95`, the sprite bytes `$DB2C` | `SetActorFrame` | - |
| `$975F` | `WarriorStrikeFrames` | 4 | The swing's frames | `SetActorFrame`, `WarriorStrike` | - |
| `$9769` | `WarriorFrames` | 4 | SetFrame's data: the frame records `$CE14`, the sprite bytes `$C7DF` (21 frames) | `SetActorFrame` | - |
| `$A7FF` | `StrikeableActorSet` | 4 | SetActorFrame's parameters: the frame table, the graphics base | `SetActorFrame` | - |
| `$A9CA` | `FragmentArc0` | 28 of 56 | The line change of each step of a fragment's arc 0 (28 signed bytes). Read by FragmentActor `$A891` (+`$0B` the step): up 8, 6, 4, 2, 1 lines, then down 1, 2, 4, 6, 8, a short second hop and the rest. Known only from the code (FragmentActor never ran in a recording with an L1). | `FragmentActor` | - |
| `$A9E6` | `FragmentArc1` (`FragmentArc0`+28) | 28 | the arcs 1-3 (doubled for 2 and 3): a lower hop | `FragmentActor` | - |

## actors

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$909F` | `GateFrames` | 4 | SetFrame's data: the frame records `$D9FA`, the sprite bytes `$D9CA` | `SetActorFrame` | - |
| `$9C8A` | `ActorKinds` | 153 | The 17 placement kinds, 9 bytes each: the Y offset, the handler, 5 bytes for the record's +8 to +`$0C`, the record's +`$0F`. LoadRoomActors `$A4CC` builds an actor from a placement with its kind's row: +1 Y = the placement's Y x 8 + the offset, +6/+7 the handler, +8 to +`$0C` (the counter, the flags, the state, the item, the attribute), +`$0F` (bit 0 shootable: ShotHitsActor; bit 1 kept over a room change: LoadRoomActors). Stage 1's kinds: 0 and 1 a hanging body (HangingActor `$9186`; 1 faces the other way), 2 a flame jet (FlameJetActor `$8DCC`), 3-6 urns and chests that break when struck (StrikeableActor `$A7C4`; +`$0B` the item inside), 7 a fire pit (FirePitActor `$8D6D`), 8-11 the winged demon's left wing, right wing, body and head (BossWingLeft `$8E60` to BossHead `$8E86`), 12 and 14 a statue head (StatueActor `$912B`), 13 the gate (GateActor `$9065`), 15 the dragon's head (ArenaHeadActor `$90E7`), 16 the bridge slab (BridgeSlabActor `$90A3`). Read in all four stage-1 builds (81 of its bytes: the kinds of the rooms the recordings visit). | `LoadRoomActors` | - |
| `$9D23` | `ActorTemplates` | 18 of 126 | Seven whole actor records (18 bytes each, the first the bridge slab's) that SpawnActor `$A4B1` copies for the actors no placement makes. The handler at +6/+7 and the frame at +4/+5 as for a placed actor; the rest as an actor record (HeroRecord `$74E0`). Read in all four stage-1 builds. | `SpawnActor` | - |
| `$9D35` | `HeroTemplate` (`ActorTemplates`+18) | 18 | the hero (PlaceHeroAtStart `$A47D`): handler `$AA3E` | `SpawnActor` | - |
| `$9D47` | `ItemTemplate` (`ActorTemplates`+36) | 18 | an item lying on the floor (SpawnItem `$A098`): 2 x 16, handler `$A0E9` | `SpawnActor` | - |
| `$9D59` | `PieceTemplate` (`ActorTemplates`+54) | 18 | a piece of the stage's artefact (handler `$8233`) | `SpawnActor` | - |
| `$9D6B` | `FragmentTemplate` (`ActorTemplates`+72) | 18 | a fragment of a broken urn (3 x 11, handler `$A891`) | `SpawnActor` | - |
| `$9D7D` | `WarriorTemplate` (`ActorTemplates`+90) | 18 | the warrior that rises from the ground (SpawnRandomEnemy `$9353`): handler WarriorActor | `SpawnActor` | - |
| `$9D8F` | `WarriorHeadTemplate` (`ActorTemplates`+108) | 18 | its head, in the next record: handler WarriorHeadActor | `SpawnActor` | - |
| `$A392` | `BurstLeftover` | 1 | An unreached RET byte after UpdateBurst's loop. No code jumps here (the loop above ends with JP UpdateBurstLoop). | - | - |
| `$A399` | `ParticleInks` | 4 | The burst's four particle attributes, written by StartBurst. ink C, bright ink C, ink B, bright ink B; the particle's byte 3 (0-3) picks one. As loaded: 2, `$42`, `$43`, 3. | `UpdateBurst` | `StartBurst` |
| `$A39D` | `BurstSteps` | 40 | 20 (dx, dy) steps: 10 for the left-byte particles, 10 for the right-byte ones | `UpdateBurst` | - |
| `$B31A` | `MissileHandlers` | 24 | The handler of each missile kind 0-11. 0 `$876C`, 1 `$80DF` UpdateAimedShot, 2 and 3 `$8006` UpdateThrownArc (the thrown items, left and right), 4 `$83A9` UpdateDriftRight, 5 `$8403` UpdateDriftLeft, 6 `$8564` UpdateFlatShot (the bolt), 7 and 8 `$842C` UpdatePathFlyer (HeroDeath's 8 flyers), 9 `$8171` UpdateHeroShot, `$0A` and `$0B` `$85C8` UpdateBouncer. | `UpdateMissiles` | - |

## rooms

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9B6F` | `Grid0` | 9 of 283 | Grid 0's record (stage 1: the surface and the caves): 69 x 21 blocks, the start window at block column 22, row 0, the room table Grid0Rooms, map offset 0, 6 rooms a grid row. A grid record, 9 bytes: +0 the width and +1 the height in blocks, +2/+3 the start window's block column and row (where StartGrid `$A444` puts the window; the grid passages rewrite them, `$ABBA-$AC30`), +4/+5 the room table, +6/+7 the grid's offset in the map section of the unpacked graphics, +8 the rooms a grid row of rooms. A room is a window of 14 x 9 blocks; the windows step 11 block columns and 6 block rows, so neighbouring rooms share 3 columns or 3 rows of blocks. RoomGrid (`$FE23`) points at the record of the hero's grid; RoomCells `$9928` reads +0, +6/+7; RoomNumber counts the windows a grid row after another. The room table, one byte a room: the exits, bit 0 right, bit 1 left, bit 2 up, bit 3 down (read by the edge checks `$AADA`). Item kind 7 writes 5 into room 12's byte `$9B84` (right and up: the gate to the right opens). Read in all four stage-1 builds (RoomCells, StartGrid, the edge checks). The file rooms.txt holds the three records, their room tables and the placement lists; tools/fig_rooms.py draws the map and every room from it (docs/img/maps/). LoadRoomActors `$A4CC` puts each placement not done that lies in the room's window (X in 2 x RoomColumn to + 29, Y in 2 x RoomRow to + 17) into a free actor record, with the kind's row of ActorKinds; MarkPlacementDone sets bit 7 when the actor is beaten or taken, so it does not come back; ResetObjectLists `$922F` clears the bits at the stage's start. Grid 0: kinds 0 and 1 (hanging bodies) 7 each, 2 (flame jets) 15, 3-6 (urns and chests) 16, 7 (fire pits) 13, 8-11 (the winged demon's parts) 1 each, 12 and 14 (statue heads) 1 each, 13 (the gate) 1, 16 (the bridge slab) 1. | `CheckRoomExits`, `ClearTakenFlags`, `HeroActor`, `LeaveRoomDown`, `LeaveRoomUp` +5 | `AddItem`, `BossPart`, `CheckGridPassages`, `ClearTakenFlags`, `MarkPlacementDone` +3 |
| `$9B78` | `Grid0Rooms` (`Grid0`+9) | 18 | 18 rooms, 6 a row: the exits of each | `CheckRoomExits` | `AddItem`, `BossPart` |
| `$9B8A` | `Grid1` (`Grid0`+27) | 9 | Grid 1 (stage 1: the shaft): 14 x 21 blocks, start 0, 0, map offset `$05A9`, 1 room a row (3 rooms) | `HeroActor`, `LeaveRoomDown`, `RoomCells`, `StartGrid` | - |
| `$9B93` | `Grid1Rooms` (`Grid0`+36) | 3 | - | `CheckRoomExits` | - |
| `$9B96` | `Grid2` (`Grid0`+39) | 9 | Grid 2 (stage 1: the dragon's arena): 14 x 9 blocks, one room, map offset `$06CF` | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9B9F` | `Grid2Rooms` (`Grid0`+48) | 1 | - | `CheckRoomExits` | - |
| `$9BA0` | `Grid0Placements` (`Grid0`+49) | 201 | grid 0's 66 placements: the kind (bit 7: done), X and Y in cells over the whole grid; `$FF` `$FF` `$FF` ends | `ClearTakenFlags`, `LoadRoomActors`, `MarkPlacementDone`, `ReviveAllPlacements` | `ClearTakenFlags`, `MarkPlacementDone`, `ReviveAllPlacements` |
| `$9C69` | `Grid1Placements` (`Grid0`+250) | 15 | grid 1's 4: statue heads (kinds 12, 14) | `ClearTakenFlags`, `LoadRoomActors` | `ClearTakenFlags` |
| `$9C78` | `Grid2Placements` (`Grid0`+265) | 18 | grid 2's 5: four fire pits and the dragon's head (kind 15) | `ClearTakenFlags`, `LoadRoomActors` | `ClearTakenFlags` |
| `$B4B2` | `StageGraphics` | 3583 | The stage's tiles, blocks and map, RLE-packed (3583 bytes; 4295 unpacked: 196 tiles, 114 blocks, the three grids' map). RoomChange `$988B` unpacks it with Unrle `$A424` into the play buffer at `$5B00` at every room change (the buffer is cleared again before the actors are drawn). Unrle: the first byte is the escape (`$C7` here); a byte other than the escape is itself, ESC n v is n copies of v (n = 0: 256), ESC ESC ends. Unpacked: five words, the offsets from `$5B0A` of the tile kinds (1 byte a tile: 0 open, else solid; bit 1 solid, bit 3 deadly), the tile pixels (8 bytes a tile), the tile attributes (1 a tile), the blocks (4 tile numbers a block: top left, top right, bottom left, bottom right) and the map (a block number a byte, the grids one after another, each its width x height; Grid0 +6 gives its offset). RoomCells `$9928` turns the room's 14 x 9 blocks into 28 x 18 tile numbers in Cells. The packer that made it is greedy: every run of 4 to 255 equal bytes is ESC n v, except one stretch of 8 zero bytes left as they are (unpacked offset 1366: a blank tile's pixels). With that one exception tools/res_stage.py packs the block again bit for bit, so the resource is editable: graphics.txt (the blocks and the map grids as text) and tiles.png (the tiles' pixels and colours). The same holds for the stages 2-4 (docs/img/maps/ has every grid and room). Read in all four stage-1 builds, every byte (Unrle). | `Unrle` | - |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C2B1` | `BridgeSlabSprite` | 32 | The bridge slab: 4 bytes x 8 lines (BridgeSlabTemplate's frame; the demon's beaten wing lays it, BridgeSlabActor `$90A3`). Not read in the stage-1 recordings (none reaches the demon); known only from the code (`$9D27`, the template's +4). | `DrawActorSprite` | - |
| `$C2D1` | `FirePitSprites` | 156 of 192 | The fire pit's flames: 6 frames of 2 bytes x 12-14 lines (FirePitActor `$8D6D` shows 0-3). Not read in the stage-1 recordings; known only from the code (FirePitFrames `$8DC6`). | `DrawActorSprite`, `PlotRow1`, `SetActorFrame` | - |
| `$C36D` | `FirePitFrameTable` (`FirePitSprites`+156) | 36 | 6 records | `PlotRow1`, `SetActorFrame` | - |
| `$C391` | `FlameJetSprites` | 340 of 418 | The flame jet: 13 frames of 2 bytes x 3-22 lines, from a flicker to a column of flame and back (FlameJetActor `$8DCC`). Read in all four stage-1 builds (FlameJetFrames `$8E3D`). | `PlotRow1`, `PlotRow2`, `SetActorFrame` | - |
| `$C4E5` | `FlameJetFrameTable` (`FlameJetSprites`+340) | 78 | 13 records | `PlotRow1`, `PlotRow2`, `SetActorFrame` | - |
| `$C533` | `HangingSprites` | 592 | The hanging body: 8 frames of 2 bytes x 37 lines, the rope above (HangingActor `$9186` points +4/+5 into it itself, `$91CB` and `$91E4`). Read in all four stage-1 builds. | `PlotRow1`, `PlotRow2`, `PlotRow2Mirrored` | - |
| `$C783` | `ShotSmall` | 10 | A shot: 2 bytes x 5 lines (ShotFrames `$813D`'s first record). The shots' pictures, ShotFrames `$813D`: this one, two of 1 x 15 and two of 2 x 13, by direction (ShotDirections `$8151`). Not read in the stage-1 recordings; known only from the code. | `DrawSprite`, `DrawSpriteMirrored` | - |
| `$C78D` | `ShotUpright` | 30 | Two shots of 1 byte x 15 lines (the ones flying up and down) | - | - |
| `$C7AB` | `ShotSlanted` | 52 | Two shots of 2 bytes x 13 lines (the slanted ones) | - | - |
| `$C7DF` | `WarriorSprites` | 1589 of 1715 | The warrior (stage 1: a skeleton with a sword and a shield): 21 frames (rise, stand, walk, block, strike). WarriorSetFrame `$9766` (WarriorFrames `$9769`). Read in all four stage-1 builds (1628 of its bytes; the frames not shown are the rising ones' tops). | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` +5 | - |
| `$CE14` | `WarriorFrameTable` (`WarriorSprites`+1589) | 126 | 21 records | `SetActorFrame` | - |
| `$CE92` | `GameOverPicture` | 64 | GAME OVER: 8 bytes x 8 lines, drawn in the HUD's item strip (GameOverStep `$836D`). Read in the stage-1 builds (all 64 bytes: the game over of the deaths recording). | `SetActorFrame`, `CopyToScreen` (`stage1/rec/s1-right`) | - |
| `$CED2` | `ArenaHeadSprites` | 506 of 518 | The dragon's head: 2 frames, the mouth closed (6 bytes x 40 lines) and open (7 x 38) (ArenaHeadActor `$90E7`). Not read in the stage-1 recordings (none reaches the arena); known only from the code (ArenaHeadFrames `$911F`). | `PlotRow6`, `PlotRow7`, `SetActorFrame` | - |
| `$D0CC` | `ArenaHeadFrameTable` (`ArenaHeadSprites`+506) | 12 | 2 records | `SetActorFrame` | - |
| `$D0D8` | `ArenaPicture` | 1078 | The dragon's body: a row-packed picture of 92 lines (each a byte LEN x 16 + SKIP, then LEN bytes), drawn from buffer row 4, column 14. DrawArenaPicture `$89BB` draws it into the play buffer every pass with DrawRowPicture `$8B03` while the dragon lives (ArenaBossBeaten), then its colours ArenaAttributes. Not read in the stage-1 recordings; known only from the code. | `DrawRowPicture` | - |
| `$D50E` | `ArenaPictureEnd` | 7 | 7 bytes past the picture's 92nd line that no code reads (known only from the code: DrawArenaPicture draws 92 lines) | - | - |
| `$D515` | `ArenaAttributes` | 192 | The dragon's colours: 12 rows of 16 attributes (0: leave the cell), copied into the shadow at `$6E4E`. DrawArenaPicture `$89BB`, or painted red where non-zero while ArenaFlash. Known only from the code. | `DrawArenaPicture` | - |
| `$D5D5` | `RoomPicture` | 843 | The demon's face over its lair (room 12): a row-packed picture of 53 lines, drawn from buffer column 9. DrawRoomPicture `$8930` draws it every pass in room 12, its two eyes flashing (EyeFlashColours). Not read in the stage-1 recordings; known only from the code. | `DrawRowPicture` | - |
| `$D920` | `RoomPictureEnd` | 6 | 6 bytes past the picture's 53rd line that no code reads (known only from the code) | - | - |
| `$D926` | `ThrownSprites` | 96 | A thrown object: 8 frames of 2 bytes x 6 lines (stage 1: a turning skull), drawn by the missile kinds 2 and 3 (ArcFrame `$8090`: frame x 12). Not read in the stage-1 recordings; known only from the code. | `DrawSprite` | - |
| `$D986` | `FlatShotSprite` | 16 | A flat shot: 2 bytes x 8 lines (FlatShotFrame `$85C4`). Not read in the stage-1 recordings; known only from the code. | `DrawSprite` | - |
| `$D996` | `BounceSprites` | 52 | The bouncing shot: 2 frames of 2 bytes x 13 lines (BounceFrames `$863D`). Read in all four stage-1 builds (DrawSprite `$B42B`). | `DrawSprite` | - |
| `$D9CA` | `GateSprites` | 48 of 54 | The gate: 1 frame of 2 bytes x 24 lines (GateActor `$9065`). Read in all four stage-1 builds (GateFrames `$909F`). | `DrawActorSprite`, `PlotRow1`, `SetActorFrame` | - |
| `$D9FA` | `GateFrameTable` (`GateSprites`+48) | 6 | 1 record | `SetActorFrame` | - |
| `$DA00` | `StatueSprites` | 282 of 300 | The statue head: 3 frames of 3 bytes x 31-32 lines (StatueActor `$912B`). Read in all four stage-1 builds (StatueFrames `$917C`). | `DrawActorSprite`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$DB1A` | `StatueFrameTable` (`StatueSprites`+282) | 18 | 3 records | `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$DB2C` | `WarriorCollapseSprites` | 617 of 701 | The warrior falling apart: 14 frames, from the body to a few sparks (WarriorCollapse `$9705`). Not read in the stage-1 recordings (WarriorCollapseFrames `$9719`); known only from the code. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow3`, `PlotRow3Mirrored`, `PlotRow4` +4 | - |
| `$DD95` | `WarriorCollapseFrameTable` (`WarriorCollapseSprites`+617) | 84 | 14 records | `PlotRow1`, `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$DDE9` | `BossWingSprite` | 99 | The winged demon's wing: 3 bytes x 33 lines (BossWingLeft `$8E60`, mirrored for the right). Not read in the stage-1 recordings (none reaches room 12); known only from the code. | `PlotRow3`, `PlotRow3Mirrored` | - |
| `$DE4C` | `BossBodySprites` | 192 of 384 | The demon's body: 2 frames of 6 bytes x 32 lines (BossBodySprite `$8FF3`: `$DE4C` from the attack's step 10). Known only from the code. | `PlotRow6` | - |
| `$DF0C` | `BossBodyStill` (`BossBodySprites`+192) | 192 | the body under step 10 | `PlotRow6` | - |
| `$DFCC` | `BossHeadSprites` | 40 of 160 | The demon's head: 4 frames of 2 bytes x 20 lines, the mouth closed to open (BossHeadFrames `$8F6D`). Known only from the code. | `PlotRow2` | - |
| `$DFF4` | `BossHead1` (`BossHeadSprites`+40) | 40 | - | `PlotRow2` | - |
| `$E01C` | `BossHead2` (`BossHeadSprites`+80) | 40 | - | `PlotRow2` | - |
| `$E044` | `BossHead3` (`BossHeadSprites`+120) | 40 | - | `PlotRow2` | - |
| `$E06C` | `PieceSprites` | 28 of 292 | A piece of the stage's artefact: 10 frames (UpdatePieceActor `$8233`); the first two (2 x 14) are also the HUD's piece pictures. ShowPieceTaken copies `$E06C` (the first piece) or `$E088` (the others) to the HUD. Read in all four stage-1 builds (PieceFrames `$8275`). | `CopyToScreen`, `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$E088` | `PieceSprite1` (`PieceSprites`+28) | 204 | the second frame, the HUD's picture of a later piece | `CopyToScreen`, `PlotRow2`, `PlotRow3` | - |
| `$E154` | `PieceFrameTable` (`PieceSprites`+232) | 60 | 10 records | `PlotRow2`, `SetActorFrame` | - |
| `$E190` | `StrikeableSprites` | 202 of 250 | The urns and chests: 8 frames, two of each (whole, cracked) for the kinds 3-6 (StrikeableActor `$A7C4`). Read in all four stage-1 builds (StrikeableActorSet `$A7FF`). | `DrawActorSprite`, `PlotRow1`, `PlotRow2`, `SetActorFrame` | - |
| `$E25A` | `StrikeableFrameTable` (`StrikeableSprites`+202) | 48 | 8 records | `PlotRow1`, `PlotRow2`, `SetActorFrame` | - |
| `$E28A` | `HeroStrikeSprites` | 381 of 435 | The hero's strikes: 9 frames (low, middle, high). HeroStrikeLowSet `$AE82`, HeroStrikeMidSet `$AEC6`, HeroStrikeHighSet `$AF0C`. Read in all four stage-1 builds. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` +2 | - |
| `$E407` | `HeroStrikeFrameTable` (`HeroStrikeSprites`+381) | 54 | 9 records | `PlotRow1`, `SetActorFrame` | - |
| `$E43D` | `EnergyBarPattern` | 6 | The energy bar's pattern: 6 bytes, one pixel line (DrawEnergyBar `$A3C5` draws Energy / 8 of them on 6 lines). Read in all four stage-1 builds. | `DrawEnergyBar`, `PlotRow1` | - |
| `$E443` | `HeroJumpSprites` | 685 of 799 | The hero's jump: 19 frames (HeroJumpSet `$B0AF`). Read in all four stage-1 builds. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` +2 | - |
| `$E6F0` | `HeroJumpFrameTable` (`HeroJumpSprites`+685) | 114 | 19 records | `PlotRow1`, `SetActorFrame` | - |
| `$E762` | `HeroWalkSprites` | 564 of 642 | The hero walking and standing: 13 frames (HeroWalkSet `$AFD7`, HeroStandSet `$ADE5`; frame 12 stands). Read in all four stage-1 builds. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` +2 | - |
| `$E996` | `HeroWalkFrameTable` (`HeroWalkSprites`+564) | 78 | 13 records | `PlotRow1`, `PlotRow3`, `SetActorFrame` | - |
| `$E9E4` | `FragmentSprites` | 264 | A fragment of a broken urn: 8 copies of 3 bytes x 11 lines, shifted 0-7 pixels (FragmentActor `$A891`: `$E9E4` + 33 x shift). Not read in the stage-1 recordings (no urn breaks in them); known only from the code. | `PlotRow1`, `PlotRow3`, `PlotRow3Mirrored` | - |
| `$EAEC` | `ItemIconSprites` | 32 of 256 | The item icons: 8 of 2 bytes x 16 lines (the first item kind 2's), for the HUD's strip and the items on the floor (ItemIcons `$7F3B`). DrawItemIcon `$7E19` and the item actors (SpawnItem `$A098` sets the icon as the frame). The stage-1 recordings read two (the kinds 3 and 0 the strip shows). | `DrawActorSprite`, `DrawItemIcon`, `PlotRow1` | - |
| `$EB0C` | `ItemIconKind6` (`ItemIconSprites`+32) | 32 | - | `DrawActorSprite`, `DrawItemIcon`, `PlotRow1` | - |
| `$EB2C` | `ItemIconKind5` (`ItemIconSprites`+64) | 32 | - | `DrawActorSprite`, `DrawItemIcon`, `PlotRow1` | - |
| `$EB4C` | `ItemIconKind3` (`ItemIconSprites`+96) | 32 | - | `DrawItemIcon`, `PlotRow1` | - |
| `$EB6C` | `ItemIconKind8` (`ItemIconSprites`+128) | 32 | - | `DrawActorSprite`, `DrawItemIcon`, `PlotRow1` | - |
| `$EB8C` | `ItemIconKind1` (`ItemIconSprites`+160) | 32 | - | `DrawActorSprite`, `DrawItemIcon`, `PlotRow1` | - |
| `$EBAC` | `ItemIconKind7` (`ItemIconSprites`+192) | 32 | - | `DrawActorSprite`, `DrawItemIcon`, `PlotRow1` | - |
| `$EBCC` | `ItemIconKind0` (`ItemIconSprites`+224) | 32 | an empty box | `DrawItemIcon`, `PlotRow1` | - |
| `$EBEC` | `DriftShotSprites` | 39 of 156 | The drifting shots: 4 frames of 3 bytes x 13 lines (ImageDescriptors `$B3EA`, DrawDriftShot `$83D4`). Read in all four stage-1 builds. | `DrawSprite`, `PlotRow1`, `UpdatePathFlyer` | - |
| `$EC13` | `DriftShot1` (`DriftShotSprites`+39) | 39 | - | `DrawSprite`, `PlotRow1`, `UpdatePathFlyer` | - |
| `$EC3A` | `DriftShot2` (`DriftShotSprites`+78) | 39 | - | `DrawSprite`, `PlotRow1` | - |
| `$EC61` | `DriftShot3` (`DriftShotSprites`+117) | 39 | - | `DrawSprite`, `PlotRow1` | - |
| `$EC88` | `HeroLeapSprites` | 394 of 478 | The hero's leaps (back and up): 14 frames (HeroLeapSet `$B0EC`). Read in all four stage-1 builds. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `SetActorFrame` | - |
| `$EE12` | `HeroLeapFrameTable` (`HeroLeapSprites`+394) | 84 | 14 records | `SetActorFrame` | - |
| `$EE66` | `ParticleGlyphs` | 32 | The burst's 4 particle glyphs, 1 byte x 8 lines each (UpdateBurst: BurstGlyphs[...] x 8 + `$EE66`). Not read in the stage-1 recordings (no burst in them); known only from the code. | `UpdateBurst` | - |
| `$EE86` | `BurstGlyphs` | 35 | The glyph (0-3) of each burst step, indexed by the step + a random 0-3. Known only from the code (UpdateBurst `$A2B1`). | `UpdateBurst` | - |
| `$EEA9` | `BurstDirections` | 192 | 6 rows of 32 indices into BurstSteps `$A39D`: each particle direction's step at each burst step. Known only from the code. | `UpdateBurst` | - |
| `$EF69` | `BurstShapes` | 28 of 120 | The shapes a burst breaks up: 5 frames of 2 bytes x 12 lines (StartBurst `$A1F3` reads 24 bytes from the shape's address). The shapes are read from `$EF69` (ScoreBurst20 `$A065`, BurstAtActor `$A129`), `$EF85` (ScoreBurst160 `$A1CF`: 4 bytes into the second frame, so its last 4 bytes are the third frame's first), `$EF99` (BossFlees `$A182`), `$EFB1` (ScoreBurst64 `$A19B`) and `$EFC9` (ArenaBossHit `$A14A`). Known only from the code. | `StartBurst` | - |
| `$EF85` | `BurstShapeHanging` (`BurstShapes`+28) | 20 | ScoreBurst160's shape (the hanging body) | `StartBurst` | - |
| `$EF99` | `BurstShapeBoss` (`BurstShapes`+48) | 24 | BossFlees' shape | `StartBurst` | - |
| `$EFB1` | `BurstShapeStatue` (`BurstShapes`+72) | 24 | ScoreBurst64's shape (the statue head) | `StartBurst` | - |
| `$EFC9` | `BurstShapeBossHit` (`BurstShapes`+96) | 24 | ArenaBossHit's shape (the demon's last hit) | `StartBurst` | - |
| `$EFE1` | `BlockEnd` | 94 | 94 zero bytes to the block's end (`$F03E`) that no code reads (the four stage-1 builds; known only from the code) | - | - |


## The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`) (`src/resident/resident.json`)

Myth: History in the Making, System 3 Software 1989: the resident part `$F000-$FFFF`, as Boot `$5B00` copies it
there; the stage blocks load over `$F000-$F03E`, the rest stays from the load to the end. Its entries are
`src/resident/<module>.asm`, written from `src/resident/resident.ann` by `kit/mkgame.py --part
src/resident/resident.json`; the readers and writers from `work/stage1/c1`.

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): init

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F019` | `ResidentInitPad` | 39 | Zeros up to ResidentEntry, overwritten by every stage block. No code reads them: the stage blocks load `$6C3F-$F03E` over them (their last bytes, the stages' own). Known only from the code and tape.txt. | `ResidentEntry`, `ResidentInit`, `TurboLoad` | `ResidentEntry`, `ResidentInit`, `TurboLoad` |
| `$F04E` | `TextRewind` | 19 | The text: column byte 9, bit 3, row 36, REWIND THE TAPE | `ResidentInit`, `ShowFront`, `TurboLoad` | `ResidentInit`, `ShowFront`, `TurboLoad` |
| `$F064` | `TextPressPlayAgain` | 23 | The text: column byte 7, bit 5, row 52, AND THEN PRESS PLAY | `ResidentInit`, `ShowFront`, `TurboLoad` | `ResidentInit`, `ShowFront`, `TurboLoad` |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): game

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F0EA` | `StageTable` | 39 of 224 | The five stages: the load parameters, then the two title lines as Print data. A record: D, E (not read by the resident: LoadStage keeps B, H, L; known only from the code), C the stage number (StageLoaded, StageCheck), H, L and B (the length: 2 x (9B + H + L) pages of 256 bytes, 132 = 33 792 bytes for every stage), then two Print strings (column byte, bit, row, text, 0): STAGE N and its title. Read by PlayStage (c1: stage 1; sN-right: stages 2-5). | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +3 | `LoadFront`, `NewGame`, `PlayStage`, `ResidentInit`, `ShowFront` +1 |
| `$F111` | `StageRecord2` (`StageTable`+39) | 45 | - | `LoadFront`, `NewGame`, `ResidentInit`, `ShowFront`, `TurboLoad` | `LoadFront`, `NewGame`, `ResidentInit`, `ShowFront`, `TurboLoad` |
| `$F13E` | `StageRecord3` (`StageTable`+84) | 52 | - | `LoadFront`, `NewGame`, `ResidentInit`, `ShowFront`, `TurboLoad` | `LoadFront`, `NewGame`, `ResidentInit`, `ShowFront`, `TurboLoad` |
| `$F172` | `StageRecord4` (`StageTable`+136) | 47 | - | `LoadFront`, `NewGame`, `ResidentInit`, `ShowFront`, `TurboLoad` | `LoadFront`, `NewGame`, `ResidentInit`, `ShowFront`, `TurboLoad` |
| `$F1A1` | `StageRecord5` (`StageTable`+183) | 41 | - | `LoadFront`, `NewGame`, `PlayStage`, `ResidentInit`, `ShowFront` +1 | `LoadFront`, `NewGame`, `PlayStage`, `ResidentInit`, `ShowFront` +1 |
| `$F1DF` | `TextPressPlay` | 22 | The text: column byte 8, bit 2, row 52, PRESS PLAY ON TAPE | `LoadFront`, `NewGame`, `PlayStage`, `ResidentInit`, `ShowFront` +2 | `LoadFront`, `NewGame`, `PlayStage`, `ResidentInit`, `ShowFront` +1 |
| `$F1FB` | `TextClearLine` | 5 | The text: column byte 8, bit 2, row 52, a space (clears the line: TextToBuffer clears the buffer) | `LoadFront`, `NewGame`, `PlayStage`, `ResidentInit`, `ShowFront` +2 | `LoadFront`, `NewGame`, `PlayStage`, `ResidentInit`, `ShowFront` +1 |
| `$F26C` | `TextGameOver` | 13 | The text: column byte 12, bit 0, row 40, GAME OVER | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 |
| `$F27C` | `TextPressSpace` | 25 | The text: column byte 7, bit 0, row 52, PRESS SPACE TO SELECT | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 |
| `$F2D3` | `HighlightBox` | 1 of 5 | AttrBox data: column 0, row (10 + 2 x option, written at `$F2CA`), 32 wide, 1 high, attribute `$43` | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +3 |
| `$F2D4` | `HighlightRow` (`HighlightBox`+1) | 4 | the row, written by GameOver | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +3 |
| `$F2FA` | `TextRestartStage` | 22 | The text: column byte 8, bit 5, row 84, RESTART THIS STAGE | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 |
| `$F313` | `TextRestartFromOne` | 26 | The text: column byte 6, bit 3, row 100, RESTART FROM STAGE ONE | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 | `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles`, `ResidentInit` +2 |
| `$F330` | `TextCreditsScore` | 16 of 37 | The text: column byte 1, bit 6, row 148, GAME CREDITS n   SCORE nnnnnn (n written by GameOver) | `CycleColours`, `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles` +3 | `CycleColours`, `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles` +4 |
| `$F340` | `CreditsDigit` (`TextCreditsScore`+16) | 14 | the credits digit, written by GameOver | `CycleColours`, `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles` +3 | `CycleColours`, `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles` +4 |
| `$F34E` | `ScoreDigits` (`TextCreditsScore`+30) | 7 | the six score digits, copied by GameOver | `CycleColours`, `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles` +3 | `CycleColours`, `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles` +3 |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): print

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F36E` | `CycleBox` | 4 of 5 | AttrBox data: column 6, row 4, 20 wide, 4 high, the attribute written by CycleColours | `AttrBox`, `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles` +3 | `AttrBox`, `CycleColours`, `LoadFront`, `NewGame`, `PlayStage` +4 |
| `$F372` | `CycleBoxAttr` (`CycleBox`+4) | 1 | the attribute | `AttrBox`, `LoadFront`, `NewGame`, `PlayStage`, `PlayStageTitles` +3 | `AttrBox`, `CycleColours`, `LoadFront`, `NewGame`, `PlayStage` +4 |
| `$F374` | `ColourCycle` | 8 | The box's colours, one a frame: bright red, magenta, green, cyan, yellow and back. Read by CycleColours (c1). | `AttrBox`, `CycleColours`, `LoadFront`, `NewGame`, `PlayStage` +4 | `AttrBox`, `CycleColours`, `LoadFront`, `NewGame`, `PlayStage` +4 |
| `$F4EF` | `ClearBox` | 5 | AttrBox data: the whole screen, attribute 0 | `Advance`, `AttrBox`, `ClearScreen2`, `CycleColours`, `LoadFront` +8 | `AttrBox`, `ClearScreen2`, `CycleColours`, `LoadFront`, `NewGame` +7 |
| `$F504` | `BandRow18` | 5 | AttrBox data: row 18, attribute `$42` | `Advance`, `AttrBox`, `ClearScreen4`, `CycleColours`, `LoadFront` +8 | `AttrBox`, `ClearScreen4`, `CycleColours`, `LoadFront`, `NewGame` +7 |
| `$F50C` | `BandRow19` | 5 | AttrBox data: row 19, attribute `$03` | `Advance`, `AttrBox`, `ClearScreen4`, `CycleColours`, `LoadFront` +8 | `AttrBox`, `ClearScreen3`, `ClearScreen4`, `CycleColours`, `LoadFront` +8 |
| `$F514` | `BandRow21` | 5 | AttrBox data: row 21, attribute `$42` | `Advance`, `AttrBox`, `ClearScreen4`, `CycleColours`, `LoadFront` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +7 |
| `$F51C` | `BandRow22` | 5 | AttrBox data: row 22, attribute `$03` | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +7 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +7 |
| `$F524` | `BandRows10` | 5 | AttrBox data: rows 10-17, attribute `$44` | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F52C` | `BandRow11` | 5 | AttrBox data: row 11, attribute `$05` | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F534` | `BandRow13` | 5 | AttrBox data: row 13, attribute `$05` | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F53C` | `BandRow15` | 5 | AttrBox data: row 15, attribute `$05` | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F9CB` | `DissolveMasks` | 48 | Six sets of 8 masks, each growing to `$FF`: RevealText and the front's reveals pick a set by a ROM byte. Read by RevealText and the front (front notes). The sets at `$F9EB` are not picked by RevealText (A AND `$18` gives 0-3). | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): ay

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F54D` | `EffectData` | 9 of 138 | The 13 effects: channel, noise flag (0 a tone), segments, volume x 16, period, then the segments. With the noise flag set the channel's tone is off, its noise on, and AyFrame writes the period's low byte to the noise period (register 6). A segment: duration in frames, period change a frame (signed), volume change a frame (signed, x 16). Read by StartEffect and ChannelStep (every stage recording). | `Advance`, `AttrBox`, `ChannelStep`, `CycleColours`, `LoadFront` +11 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `LoadStage` +9 |
| `$F556` | `Effect1` (`EffectData`+9) | 9 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F55F` | `Effect2` (`EffectData`+18) | 9 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F568` | `Effect3` (`EffectData`+27) | 9 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F571` | `Effect4` (`EffectData`+36) | 9 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F57A` | `Effect5` (`EffectData`+45) | 21 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F58F` | `Effect6` (`EffectData`+66) | 12 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F59B` | `Effect7` (`EffectData`+78) | 9 | - | `Advance`, `AttrBox`, `ChannelStep`, `CycleColours`, `LoadFront` +10 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F5A4` | `Effect8` (`EffectData`+87) | 9 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F5AD` | `Effect9` (`EffectData`+96) | 12 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F5B9` | `Effect10` (`EffectData`+108) | 12 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `NewGame` +8 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `NewGame` +8 |
| `$F5C5` | `Effect11` (`EffectData`+120) | 9 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `LoadStage` +9 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `LoadStage` +9 |
| `$F5CE` | `Effect12` (`EffectData`+129) | 9 | - | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `LoadStage` +9 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `LoadStage` +9 |
| `$F5D7` | `EffectLeftover` | 2 | Two bytes after the last effect that no code reads: `$06` `$04`, like the start of a second segment. Effect 12 has one segment, so ChannelStep stops before them (known only from the code: the count at `$F5D0` is 1). A leftover of the effect's editing. | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `LoadStage` +9 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `LoadStage` +9 |
| `$F6BB` | `EffectTable` | 26 | The addresses of the 13 effects. Read by PlaySound (every stage recording). | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `LoadStage` +13 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `LoadStage` +13 |
| `$F85E` | `Channels` | 8 of 24 | The three channels, 8 bytes each. +0 segments left (`$FF` idle), +1 frames left in the segment, +2 the segment's address, +4 the period, +6 the noise flag (0 a tone), +7 the volume x 16. Read and written by StartEffect, AyFrame and ChannelStep. | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F866` | `Channel2` (`Channels`+8) | 8 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F86E` | `Channel3` (`Channels`+16) | 8 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F876` | `Mixer` | 1 | The AY mixer value (register 7) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F877` | `MixerSpare` | 1 | A byte no code reads (known only from the code: no operand names it) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F878` | `ChannelNumber` | 1 | The channel AyFrame is on, 1-3 | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F879` | `LoadLength` | 1 of 3 | LoadStage's H, L and B: TurboLoad's length is 2 x (9B + H + L) pages | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F87A` | `LoadLengthL` (`LoadLength`+1) | 1 | L | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F87B` | `LoadLengthB` (`LoadLength`+2) | 1 | B | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F87C` | `LoadLengthPad` | 4 | Zeros no code reads (known only from the code) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): stageload

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F602` | `TextClearTop` | 5 | The text: column 0, bit 0, row 36, a space | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `LoadStage` +9 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `LoadStage` +9 |
| `$F60A` | `TextStopTape` | 17 | The text: column byte 10, bit 3, row 52, STOP THE TAPE | `Advance`, `AttrBox`, `CycleColours`, `LoadFront`, `LoadStage` +10 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `LoadStage` +10 |
| `$FF7E` | `StageCheckFront` | 1 | Unused slot 0 of StageCheck (the front is not checked) | - | - |
| `$FF7F` | `StageCheck` | 5 | The byte at StageCheckByte of stages 1-5: `$16`, `$4B`, `$FA`, `$E0`, `$80`. Read by LoadBlock (c1: stage 1; sN-right: stages 2-5). Each value is the stage block's byte at `$BB80` (work/mkgame/stageN.bin). | `LoadBlock` | - |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): im2

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F66C` | `SavedLoaderBytes` | 3 | TurboLoad's three bytes at Im2Jump while the IM 2 jump is there. Written by SaveLoaderBytes, read back by LoadBlock (c1). | `Advance`, `AttrBox`, `CycleColours`, `LoadBlock`, `LoadFront` +12 | `AttrBox`, `ClearScreen3`, `CycleColours`, `LoadFront`, `LoadStage` +12 |
| `$FD00` | `Im2Table` | 257 | 257 bytes of `$FE`: whatever the bus holds, the vector is `$FEFE` (Im2Jump). Read by the Z80 at every interrupt (I = `$FD`), c1 and every recording. | `Advance`, `AyFrame`, `AyWrite`, `ChannelStep`, `CycleColours` +15 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +19 |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F880` | `PrintFont` | 296 | 37 glyphs, 8 bytes each: the width mask, then 7 rows; A-Z, the space, 0-9. Read by TextToBuffer (every title screen). The mask's lowest set bit marks the glyph's width (Advance). | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$FF84` | `RomFontLeftover` | 124 | A copy of the ROM font `$3E34-$3EAF` (the end of F to U) and `$27`: no code reads it. A leftover of the mastering: no operand names `$FF84-$FFFF` and the tape's image holds the ROM's bytes. The stack (SP = `$FFFF`) writes over its end in play. Known only from the code. | - | - |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): vars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F9A8` | `BitShift` | 1 | TextToBuffer's bit within the column byte (also a scratch word with TextRow for RevealText and the stages) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +19 |
| `$F9A9` | `TextRow` | 1 | Print's pixel row | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +20 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$F9AA` | `CharMask` | 1 | The current glyph's width mask | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$F9AB` | `RowPointer` | 2 | RevealText's place in ScreenLineTable | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$F9AD` | `Credits` | 1 | The game's credits: 4 at NewGame, one less a game over | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +20 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +19 |
| `$F9AE` | `StageLoaded` | 1 | The stage in memory (0 the front, `$FF` none) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +19 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$F9AF` | `Lives` | 1 | The lives, passed to each stage in H and back | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$F9C9` | `DecimalTablePad` | 2 | Zeros no code reads (known only from the code) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$F9FE` | `ResidentVarsPad` | 2 | Zeros (known only from the code) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$FE01` | `WorkSpace` | 3 of 143 | The work space of the front and the stages (zeros in the tape's image). The front: SavedIm2Jump, SavedStack, SavedReturn, ShimmerCount, ReaderBitOp, ReaderPort (src/front). The stages: `$FE08-$FE6F` (src/stageN). The resident's own: GameOverOption and FrameCounter. | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +21 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +20 |
| `$FE04` | `SavedStack` (`WorkSpace`+3) | 2 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FE06` | `SavedReturn` (`WorkSpace`+5) | 2 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FE08` | `StageVars` (`WorkSpace`+7) | 21 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FE1D` | `ShimmerCount` (`WorkSpace`+28) | 1 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FE1E` | `GameOverOption` (`WorkSpace`+29) | 1 | GameOver's highlighted line, 0 or 1 | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +19 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +19 |
| `$FE1F` | `StageVars2` (`WorkSpace`+30) | 18 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FE31` | `FrameCounter` (`WorkSpace`+48) | 1 | CycleColours' frame count | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$FE32` | `StageVars3` (`WorkSpace`+49) | 26 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FE4C` | `ReaderBitOp` (`WorkSpace`+75) | 1 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FE4D` | `ReaderPort` (`WorkSpace`+76) | 2 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FE4F` | `StageVars4` (`WorkSpace`+78) | 65 | - | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): score

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F9BF` | `DecimalTable` | 10 | 10000, 1000, 100, 10, 1: the stages' decimal print. Read by the stages' score print (every stage recording). | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$F9FB` | `Score` | 2 | The score, a word (0 at NewGame; the stages add to it) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$F9FD` | `ScoreHigh` | 1 | The score's high two digits (ten thousands, 0-99), above Score: 0 at NewGame; the stages' AddScore carries into it (src/stage1 AddScore) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FA00` | `BitReverse` | 256 | Byte n is n with its bits in reverse order (the stages' mirrored sprites). Read in c1 and in the stage recordings (deaths, s1-s3). | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$FB00` | `ScreenLineTable` | 384 | The screen address of each of the 192 pixel lines. Read by RevealText, the front and the stages. | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +18 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +18 |
| `$FC80` | `ScreenLineTablePad` | 16 | Zeros no code reads (known only from the code) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |

### The resident (TZX blocks 25, 17, 27 at `$F000-$FFFF`): keys

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FCFA` | `KeyXorMask` | 1 | 0 for keys (active low), `$FF` for a Kempston (active high), written by the front | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +22 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |
| `$FCFB` | `KeyXorMaskPad` | 5 | Zeros no code reads (known only from the code) | `Advance`, `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep` +17 | `AttrBox`, `AyFrame`, `AyWrite`, `ChannelStep`, `ClearScreen3` +17 |


## The front (TZX block 37) (`src/front/front.json`)

Myth: History in the Making, System 3 Software 1989: the main block (TZX block 37), 15 360 bytes at `$6C3F`: the
logo, the credits, the menu. Its entries are `src/front/<module>.asm`, written from `src/front/front.ann` by
`kit/mkgame.py --part src/front/front.json`; the readers and writers from `work/stage1/c1`.

### The front (TZX block 37): workspace

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6C3F` | `FrontLowSpace` | 2497 | Zeros: no code of the front reads or writes `$6C3F-$75FF`. Zeros on the tape. The menu recording reads and writes none of it; the front's code names no address there (known only from the code, every operand of the part checked). | - | - |
| `$7600` | `GlyphRows` | 14 | PrintText's glyph: 7 rows of two bytes (the glyph's row, shifted right by PixelShift into the second byte). Written and read by PrintText `$9D72` for every character (menu: all 14 bytes read and written). | `PrintText` | - |
| `$760E` | `FrontMidSpace` | 498 | Zeros up to the code at `$7800`. Zeros on the tape; no access in the menu recording. | - | - |
| `$A1C1` | `FrontHighSpace` | 1662 | Zeros to the block's end (`$A1C1-$A83E`). Zeros on the tape; the front's code names no address there and the menu recording reads none of it. | - | - |

### The front (TZX block 37): logo

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$78E2` | `ShimmerColours` | 96 | The frame shimmer's attributes: a 32-byte pattern of yellow (`$06`) and bright yellow (`$46`), three times. ShimmerFrame `$79AE` copies 20 bytes from ShimmerColours + phase + row to each of the 10 attribute rows 7-16 (columns 6-25), phase 0-31, so it reads `$78E2-$791D` (the menu recording reads exactly these 60 bytes). The last 36 bytes (`$791E-$7941`) repeat the pattern and are never read (menu; known only from the code: the largest offset is 31 + 9 + 19 = 59). | `ShimmerFrame` | - |
| `$79DB` | `LogoScreen` | 6144 of 6912 | The logo screen: the MYTH logo in its box, HISTORY IN THE MAKING, over a starfield (6144 bitmap bytes, 768 attributes). Copied to the screen by ShowLogo `$785A` (c1 frame 7828; the attributes at 7848). The box is 20 x 10 cells (columns 6-25, rows 7-16); its inside (pixel lines 64-127, columns 7-24) is wiped by DissolveLogoBox `$7889` and reused for the credits and the menu. The blue dots of the starfield are drawn in the bitmap: nothing animates them. | - | - |
| `$91DB` | `LogoAttributes` (`LogoScreen`+6144) | 768 | the 768 attributes, copied at `$787D` | - | - |
| `$9718` | `DissolveLinePtr` | 2 | DissolveLogoBox's pointer into ScreenLineTable (the next line's entry). Written at `$788C` (ScreenLineTable+128) and read and stepped by DissolveLogoBox `$7889` for each of its 64 lines (c1, the front's bytes: `$789A` 8 runs). Zero on the tape. | `DissolveStep` (code) | `DissolveLogoBox` (code) |

### The front (TZX block 37): leftovers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9D1B` | `OldBarVars` | 14 | Zeros: OldBouncingBars's variables (+2, +3: rows; +4 to +13: five columns and steps). Read and written only by OldBouncingBars `$9A94` (never executed). Zeros on the tape. | `OldBarsPaint` (code), `OldBarsStep` (code), `OldBouncingBars` (code) | `OldBouncingBars` (code) |
| `$A124` | `OldDefineKeysTexts` | 66 | The texts of an earlier DEFINE KEYS: PRESS KEY FOR, UP, DOW\N (sic), LEFT, RIGHT, FIRE, each after two bytes, each ended by 0. Nothing reads them (c1, menu; no operand names `$A124-$A165`): the final DefineKeys prints TextPressTheKeyFor and KeyNames. The two bytes before each text (5, 0 and 8, 0) are an older print routine's parameters. | - | - |

### The front (TZX block 37): credits

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9512` | `TextProgrammedBy` | 18 | PrintText: small font, byte 11, line 84: PROGRAMMED BY | `PrintText` | - |
| `$9527` | `TextNeilDodwell` | 17 | PrintText: large font, byte 11, shift 2, line 100: NEIL DODWELL | `PrintText` | - |
| `$9551` | `TextGraphicsBy` | 16 | PrintText: small font, byte 11, shift 7, line 84: GRAPHICS BY | - | - |
| `$9564` | `TextConceptAnimations` | 23 | PrintText: large font, byte 8, line 100: CONCEPT ANIMATIONS | - | - |
| `$9594` | `TextProducedBy` | 16 | PrintText: small font, byte 11, shift 7, line 84: PRODUCED BY | - | - |
| `$95A7` | `TextSystemThree` | 17 | PrintText: large font, byte 11, line 100: SYSTEM THREE | - | - |
| `$95D1` | `TextOriginalGameDesign` | 25 | PrintText: small font, byte 8, shift 5, line 84: ORIGINAL GAME DESIGN | - | - |
| `$95ED` | `TextMarkCale` | 14 | PrintText: large font, byte 12, line 100: MARK CALE | - | - |
| `$9614` | `TextSoundEffectsBy` | 21 | PrintText: small font, byte 10, line 84: SOUND EFFECTS BY | - | - |
| `$962C` | `TextNeilDodwellSound` | 17 | PrintText: large font, byte 11, shift 2, line 100: NEIL DODWELL (the same bytes as TextNeilDodwell) | - | - |
| `$9656` | `TextDeveloped` | 14 | PrintText: small font, byte 12, shift 5, line 68: DEVELOPED | - | - |
| `$9667` | `TextInAssociationWith` | 24 | PrintText: small font, byte 8, shift 7, line 84: IN ASSOCIATION WITH | - | - |
| `$9682` | `TextMarjacqMicro` | 18 | PrintText: large font, byte 10, shift 1, line 116: MARJACQ MICRO | - | - |
| `$96B2` | `TextCopyright1989` | 19 | PrintText: small font, byte 10, shift 6, line 68: COPYRIGHT 1989 | - | - |
| `$96C8` | `TextSystem3Software` | 22 | PrintText: small font, byte 9, shift 2, line 84: SYSTEM 3 SOFTWARE | - | - |
| `$96E1` | `TextPressSpaceToStart` | 25 | PrintText: small font, byte 8, shift 3, line 116: PRESS SPACE TO START | - | - |

### The front (TZX block 37): definekeys

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9720` | `TextPressTheKeyFor` | 22 | PrintText: small font, byte 9, shift 5, line 84: PRESS THE KEY FOR | - | - |
| `$97A8` | `KeyNameText` | 4 of 12 | PrintText: large font, byte 13, line 100: a 7-byte slot for the name ("RIGHT  " on the tape) whose last byte gets the key | - | `DefineKeyScan` (code) |
| `$97AC` | `KeyNameSlot` (`KeyNameText`+4) | 6 | the 7 bytes: the name from KeyNames, the key's character at +6 | - | - |
| `$97B2` | `KeyNameChar` (`KeyNameText`+10) | 2 | the key's character (written at `$9758`) | - | `DefineKeyScan` (code) |
| `$97B5` | `KeyNames` | 35 | The five names, 7 bytes each, no end mark: UP, DOWN, LEFT, RIGHT, FIRE (the order of the readers KeyUp to KeyFire). Read 7 bytes at a time by DefineKeysLoop `$9736` (LDIR to KeyNameSlot `$97AC`). menu: all 35 bytes read. | - | - |
| `$996D` | `ScanBit` | 1 | The bit (0-4) of the key ScanKeyboard found. Written at `$9957`, read by DefineKeysLoop at `$9766` (menu: 5 each). | `DefineKeyPatch` (code) | `ScanFound` (code) |
| `$996E` | `ScanPort` | 2 | The port of the key's half row. Written at `$9960`, read at `$9774` (menu: 5 each). | `DefineKeyPatch` (code) | `ScanFound` (code) |
| `$9970` | `KeyRowPorts` | 16 | The 8 half rows ScanKeyboard reads, in its order: `$FEFE`, `$FDFE`, `$FBFE`, `$DFFE`, `$BFFE`, `$7FFE`, `$EFFE`, `$F7FE`. Read by ScanKeyboard `$9916` (LD C,(IX); LD B,(IX+1)). menu: all 16 bytes read. | - | - |
| `$9980` | `KeyRowChars` | 40 | The character of each key, 5 a half row, bit 0 first: "-" CAPS SHIFT, "+" ENTER, "/" SPACE, "." SYMBOL SHIFT. Read by ScanKeyboard (A = (IY + bit)). menu: the characters of the five keys found read (X, K, L, P, "/"). PrintText has no glyph for "-", "+", "/" or ".": its mapping (byte - `$30` + `$5C` for a byte under "A" that is not a space) shows them as the glyphs of Y, W, the space and Z; the digits become glyphs 27-36, which the large font that KeyNameText uses does not have (it ends with the space, glyph 26): a digit key would show the bytes of PixelShift and the code after them. Known only from the code (the recording took no digit and showed "/" as a space). | - | - |

### The front (TZX block 37): joystick

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9A8C` | `JoystickBarColours` | 8 | The joystick bar's 8 colours: the same as MenuBarColours. Read by JoystickHighlight `$9A3B` (index D AND 7). Not read in any recording. | - | - |
| `$A0DC` | `TextKempston` | 13 | PrintText: large font, byte 12, shift 2, line 68: KEMPSTON | - | - |
| `$A0EC` | `TextCursorKeys` | 16 | PrintText: large font, byte 11, shift 1, line 84: CURSOR KEYS | - | - |
| `$A0FF` | `TextSinclair` | 13 | PrintText: large font, byte 12, shift 6, line 100: SINCLAIR | - | - |
| `$A10F` | `TextLeaveThisMenu` | 20 | PrintText: large font, byte 9, shift 6, line 116: LEAVE THIS MENU | - | - |

### The front (TZX block 37): menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9A33` | `MenuBarColours` | 8 | The menu bar's 8 colours, one a pass: `$42` `$43` `$44` `$45` `$46` `$45` `$44` `$43` (bright red, magenta, green, cyan, yellow on black). Read by MenuHighlight `$99E2` (index D AND 7). menu: all 8 read. | - | - |
| `$A169` | `TextPressSpaceToSelect` | 26 | PrintText: small font, byte 8, shift 2, line 68: PRESS SPACE TO SELECT | `PrintText` | - |
| `$A187` | `TextStartGame` | 15 | PrintText: large font, byte 11, shift 5, line 84: START GAME | `PrintText` | - |
| `$A199` | `TextDefineKeys` | 16 | PrintText: large font, byte 11, shift 4, line 100: DEFINE KEYS | `PrintText` | - |
| `$A1AC` | `TextSelectJoystick` | 20 | PrintText: large font, byte 9, shift 7, line 116: SELECT JOYSTICK | `PrintText` | - |

### The front (TZX block 37): print

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9D6B` | `BlankLineText` | 3 of 6 | PrintText: small font, byte 0, line patched by ClearTextLine: one space | `PrintText` | `ClearTextLine` |
| `$9D6E` | `BlankLineLine` (`BlankLineText`+3) | 3 | the screen line, written at `$9D65` | `PrintText` | `ClearTextLine` |

### The front (TZX block 37): data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9ED2` | `FontSmall` | 296 | The small font: 37 glyphs of 8 bytes (width mask, 7 rows): A-Z, space, 0-9. Read by PrintText `$9D72` (FontBase for font 0). menu: the glyphs of its small-font texts read. | - | - |
| `$9FFA` | `FontLarge` | 216 | The large font: 27 glyphs of 8 bytes: A-Z, space. Read by PrintText `$9D72` (FontBase for font 1). Glyphs 27-36 (the digits) would be read from PixelShift `$A0D2` on: the large font has none. | - | - |
| `$A0D2` | `PixelShift` | 1 of 7 | PrintText: the pen's pixel offset in its byte (0-7); the low byte of the ROM pointer of the dissolves. PrintText `$9D72` and AdvanceColumn `$9E24` keep the pen's bit offset here. RevealStrip `$9E4D` and DissolveLogoBox `$7889` use PixelShift and TextLine as one word: 0 at the start of each dissolve, then + 1 a byte, the address of the ROM byte that picks the mask (LD BC,(`$A0D2`)). menu: read and written. | `AdvanceColumn` (code), `AdvancePen` (code), `DissolveByte` (code), `PrintGlyphNumber` (code), `PrintShiftGlyph` (code) +3 | `PrintText`, `AdvanceStore` (code), `DissolveByte` (code), `DissolveStep` (code), `RevealByte` (code) +2 |
| `$A0D3` | `TextLine` (`PixelShift`+1) | 1 | PrintText: the screen line of the text (the high byte of the ROM pointer word) | `DissolveByte` (code), `PrintTextDone` (code), `RevealByte` (code) | `PrintText`, `DissolveByte` (code), `DissolveStep` (code), `RevealByte` (code), `RevealStep` (code) |
| `$A0D4` | `GlyphMask` (`PixelShift`+2) | 1 | PrintText: the current glyph's width mask | `AdvanceColumn` (code) | `PrintGlyphNumber` (code) |
| `$A0D5` | `RevealLines` (`PixelShift`+3) | 2 | RevealStrip: ScreenLineTable + 2 x the line (a word) | `RevealStep` (code) | `RevealStrip` (code) |
| `$A0D7` | `FontBase` (`PixelShift`+5) | 2 | PrintText: FontSmall or FontLarge (a word) | `PrintGlyphNumber` (code) | `PrintText` |


## Stage 2 (TZX block 43) (`src/stage2/stage2.json`)

Myth: History in the Making, System 3 Software 1989: stage 2 (TZX block 43), 33 792 bytes loaded at `$6C3F` by the
resident stage loader over `$6C3F-$F03E` (tools/image.py). Its entries are `src/stage2/<module>.asm`, written from
`src/stage2/stage2.ann` by `kit/mkgame.py --part src/stage2/stage2.json`; the readers and writers from
`work/stage1/rec/s2-right`, `work/stage2/rec/rzx-r2`, `work/stage2/rec/stageload`.

### Stage 2 (TZX block 43): variables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6C3F` | `PlayBufferTail` | 193 | The last 193 bytes of the play buffer PlayBuffer `$5B00-$6CFF` (character row 17's last lines). ClearBuffer `$9484` clears the play buffer to `$6CFF` with PUSH HL (SP from `$6D00`); RoomChange `$9257` unpacks the stage's tiles and map into it from `$5B00` (3852 bytes, to `$6A0B`); the actors are drawn into it every pass. Zero as loaded. Read and written in s2-right and rzx-r2 (CopyBuffer `$94A9` copies it out). | `CopyBuffer`, `OrNeckSegment`, `PlotRow1`, `PlotRow2`, `PlotRow3` +3 | `DrawActorSprite`, `DrawRowPicture`, `DrawSpriteMirrored`, `OrNeckSegment`, `PlotRow1` +6 |
| `$6D00` | `ShadowAttributes` | 192 of 768 | The shadow of the screen's 768 attributes, the screen's layout; the play area from `$6DC2` (row 6, column 2). The HUD's colours are copied into rows 0-5 at the stage's set-up (StageSetUp `$9177`); RoomChange `$9257` writes each cell's attribute into rows 6-23, the actors' colours are painted over them every pass, and UpdateAttributes `$8CD0` copies the open cells to `$5800` (ShowShadowAttributes `$8CC3` the whole of it). FillShadowAttributes `$8C93` paints rectangles into it with five bytes after its CALL. Zero as loaded. | `ClearShadowAttributes`, `FadeInStep`, `OrNeckSegment`, `PlotRow3Mirrored`, `SavePlayAttrs` +3 | `ClearShadowAttributes`, `ColourActor`, `ColourHydra`, `ColourSprite`, `ColourSpriteMirrored` +10 |
| `$6DC0` | `PlayAttributes` (`ShadowAttributes`+192) | 2 | row 6: the first row of the play area (the room's 18 rows) | `ClearShadowAttributes`, `OrNeckSegment`, `PlotRow3Mirrored`, `SavePlayAttrs`, `ShowShadowAttributes` | `ClearShadowAttributes`, `ColourSprite`, `OrNeckSegment`, `PlotRow3Mirrored`, `SaveAttributes` |
| `$6DC2` | `PlayAttributesCell` (`ShadowAttributes`+194) | 574 | row 6, column 2: the room's first cell | `ClearShadowAttributes`, `FadeInStep`, `OrNeckSegment`, `PlotRow3Mirrored`, `SavePlayAttrs` +2 | `ClearShadowAttributes`, `ColourActor`, `ColourHydra`, `ColourSprite`, `ColourSpriteMirrored` +7 |
| `$7000` | `HudPicture` | 64 of 1728 | The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their colours at `$7600` (6 rows of 32). DissolveHud `$8AD6` dissolves the 48 lines onto the screen's lines 0-47 and StageSetUp `$9177` copies the 192 colours into the shadow rows 0-5, once, at the stage's start. EndStage `$789D` saves the screen's lines 0-47 back here and the attributes `$5800-$58BF` to `$7600` when the stage ends, so the next stage's block shows the HUD as the player left it. The same 1728 bytes as stage 1's HudPicture (src/res/stage2/picture-hud-32x48.png). | `AddMissile`, `AddMissileFrom`, `AimedShot`, `ApplyEnergyChange`, `AttrShadowAddress` +135 | `AddMissile`, `AddMissileFrom`, `AddSpan`, `BuildSpans`, `CheckHeroFooting` +84 |
| `$7040` | `RoomAttributes` (`HudPicture`+64) | 2 | `$7040-$727F`: the old room's play colours (SavePlayAttrs `$99C2`: 576 bytes, rows 6-23) and the cells' twins; also the burst's particles (StartBurst `$9BFA`, 4 bytes each, read by UpdateBurst `$9C92`) | `AttrShadowAddressA`, `DissolveHud`, `UpdateBurst` | `CopyScreenToBlock`, `SavePlayAttrs`, `StartBurst`, `UpdateBurst` |
| `$7042` | `RoomAttributesCell` (`HudPicture`+66) | 574 | the twin of the cell `$7282` (576 bytes lower) | `AttrShadowAddressA`, `DissolveHud`, `UpdateAttributes`, `UpdateBurst` | `ColourActor`, `CopyScreenToBlock`, `PutBlock`, `SavePlayAttrs`, `StartBurst` +1 |
| `$7280` | `Cells` (`HudPicture`+640) | 2 | the room's cells: 19 rows of 32 (tile numbers, then their kinds after BuildSpans `$93B5`; bit 1 solid, bit 3 deadly) | `DissolveHud`, `StartGrid` | `CopyScreenToBlock`, `StartGrid` |
| `$7282` | `CellsPlay` (`HudPicture`+642) | 574 | row 0, column 2: the room's first cell (RoomCells `$92F4` writes 28 x 18) | `BuildSpans`, `CellAt`, `CellAtRow`, `CellUnderFeet`, `DissolveHud` +3 | `BuildSpans`, `CopyScreenToBlock`, `PutBlock`, `StartGrid` |
| `$74C0` | `CellsFloor` (`HudPicture`+1216) | 32 | row 18 below the room: 32 bytes of `$FF` (StartGrid `$A35D`), a floor no actor falls through | `CellUnderFeet`, `DissolveHud`, `StartGrid` | `CopyScreenToBlock`, `StartGrid` |
| `$74E0` | `HeroRecord` (`HudPicture`+1248) | 1 | the hero's actor record (18 bytes; +0 X) | `BufferAddressDE`, `CellUnderFeet`, `CheckFirstRoomLeft`, `CheckGridPassages`, `CheckMedusaBarrier` +32 | `CopyScreenToBlock`, `HeroDeath`, `SetActorFrame`, `ShiftRoomColumns`, `SpawnActor` |
| `$74E1` | `HeroY` (`HudPicture`+1249) | 7 | +1 the hero's line | `BufferAddressDE`, `CellUnderFeet`, `CheckRoomExits`, `ClipActor`, `ColourActor` +18 | `CopyScreenToBlock`, `HeroDeath`, `SetActorFrame`, `ShiftRoomRows`, `SpawnActor` |
| `$74E8` | `HeroFrame` (`HudPicture`+1256) | 1 | +8 the frame number of the hero's set | `BufferAddressDE`, `CheckGridPassages`, `CheckHeroFooting`, `ClipActor`, `ColourActor` +18 | `CheckHeroFooting`, `CopyScreenToBlock`, `HeroFall`, `HeroJump`, `HeroLeap` +15 |
| `$74E9` | `HeroFlags` (`HudPicture`+1257) | 1 | +9 bit 7: facing left | `BufferAddressDE`, `CellUnderFeet`, `CheckFirstRoomLeft`, `CheckMedusaBarrier`, `ClipActor` +22 | `CopyScreenToBlock`, `HeroStand`, `HeroTurn`, `PlaceHeroBackGrid0`, `PlaceHeroBackGrid1` +3 |
| `$74EA` | `HeroState` (`HudPicture`+1258) | 2 | +`$0A` the hero's state (stage 1's numbering) | `ApplyEnergyChange`, `BufferAddressDE`, `CheckGridPassages`, `CheckHeroFooting`, `CheckRoomExits` +27 | `CopyScreenToBlock`, `HeroDeath`, `HeroFall`, `HeroJump`, `HeroLeap` +14 |
| `$74EC` | `HeroAttribute` (`HudPicture`+1260) | 1 | +`$0C` the hero's attribute | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +4 | `CopyScreenToBlock`, `HeroDeath`, `HeroUpdate`, `SetActorFrame`, `SpawnActor` |
| `$74ED` | `HeroBaseX` (`HudPicture`+1261) | 1 | +`$0D` the base column | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +9 | `CopyScreenToBlock`, `HeroDeath`, `HeroWalk`, `MoveBaseX`, `RespawnCountdown` +5 |
| `$74EE` | `HeroBaseY` (`HudPicture`+1262) | 2 | +`$0E` the base line | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +7 | `CopyScreenToBlock`, `HeroDeath`, `HeroFall`, `MoveActorY`, `RespawnCountdown` +3 |
| `$74F0` | `HeroCounter` (`HudPicture`+1264) | 2 | +`$10` the pause after a death | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +8 | `CopyScreenToBlock`, `HeroDeath`, `HeroStrikeMid`, `RespawnCountdown`, `SetActorFrame` +1 |
| `$74F2` | `Actors` (`HudPicture`+1266) | 216 | the 13 other actor records, 18 bytes each (`$74F2-$75DB`); +0 = `$FF` a free record | `AimedShot`, `BufferAddressDE`, `ClearActors`, `ClipActor`, `ColourActor` +57 | `ClearActors`, `CopyScreenToBlock`, `CycleItemInk`, `DropActor`, `ExtraLifeActor` +36 |
| `$75CA` | `LastActor` (`HudPicture`+1482) | 18 | the 13th record | `BufferAddressDE`, `ClearActors`, `ClipActor`, `ColourActor`, `CycleItemInk` +36 | `ClearActors`, `CopyScreenToBlock`, `CycleItemInk`, `DropActor`, `ExtraLifeActor` +19 |
| `$75DC` | `ActorsEnd` (`HudPicture`+1500) | 4 | 4 bytes past the records (written and read in rzx-r2: a 15th record's first bytes are tested as the list's end) | `DissolveHud` | `CopyScreenToBlock` |
| `$75E0` | `Missiles` (`HudPicture`+1504) | 32 | the 16 missile records, 6 bytes each (`$75E0-$763F`): +0 the column (`$FF` free), +1 the line, +2 the kind, +3 to +5 the kind's own | `AddMissile`, `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL` +12 | `AddMissile`, `AddMissileFrom`, `ClearShots`, `CopyScreenToBlock`, `RemoveActor` +4 |
| `$7600` | `HudColours` (`HudPicture`+1536) | 16 | the HUD's 192 colours as loaded (rows 0-5); in play the missile records 4-15 lie over them | `AddMissile`, `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL` +12 | `AddMissile`, `AddMissileFrom`, `ClearShots`, `EndStage`, `RemoveActor` +5 |
| `$7610` | `MissilesHigh` (`HudPicture`+1552) | 48 | missile records 8-15 (AddMissileHigh `$B3C5`) | `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL`, `ClearShots` +6 | `AddMissileFrom`, `ClearShots`, `EndStage`, `HeroDeath`, `RemoveActor` +3 |
| `$7640` | `DigitBuffer` (`HudPicture`+1600) | 96 | in play: the score's digit picture and a sprite's shifted copy (PreShiftSprite `$7F10`) | `CopyToScreen`, `PlotRow3`, `PlotRow4`, `ShiftLine1`, `ShiftLine4` +1 | `ClearShots`, `EndStage`, `PreShiftSprite`, `RenderDigits`, `RenderScore` +3 |
| `$76A0` | `SpanTable` (`HudPicture`+1696) | 32 | in play: the open spans CopyBuffer `$94A9` copies, 6 bytes each (the length, 0, the buffer address, the screen address), on to `$77B9` | `BuildSpans`, `StageSetUp` | `AddSpan`, `BuildSpans`, `EndStage`, `StageEntry` |
| `$76C0` | `SpanTableRest` | 250 | The span table's room past the HUD's colours: spans 6-46 (`$76C0-$77B9`). BuildSpans `$93B5` and AddSpan `$943D` write the spans from `$76A0` on; rzx-r2 fills them to `$77B9` (47 spans; stage 1's recordings reached `$779B`). Zero as loaded. | `BuildSpans` | `AddSpan`, `BuildSpans` |
| `$77BA` | `Unused77BA` | 70 | 70 bytes no code reads or writes (s2-right, rzx-r2); zero as loaded | - | - |

### Stage 2 (TZX block 43): render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7F53` | `ShiftRoutines` | 16 | The shift routine for 1-7 pixels (entry 0 unused). 0, ShiftLine1, ShiftLine2, ShiftLine3, ShiftLine4, ShiftLine5, ShiftLine6, ShiftLine7. Read by PreShiftSprite (`$7F3A`), which patches the CALL at PreShiftCall with entry +`$11` of the actor. | `PreShiftSprite` | - |
| `$8A59` | `RowPlotters` | 32 | The row plotter of each sprite width: word 2 x width + 1 when mirrored. Read by the sprite drawer at `$A62D` (LD BC,RowPlotters): index 2 x width + (facing left). Width 0 and the mirrored width 7 hold HangFlashBorder `$88B6` (a hang loop: border flicker and KeyHook forever), never reached with a valid frame. | `DrawActorSprite` | - |
| `$A8FC` | `ItemInks` | 4 | CycleItemInk's four attributes. Read by CycleItemInk `$A8F6`: `$42`, `$43`, `$41`, `$47`. As in stage 1 at `$A799`. | `CycleItemInk`, `SetActorFrame` | - |

### Stage 2 (TZX block 43): hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7A71` | `StarPixels` | 32 | The two pixel lines of a star, by speed (rows 1-4) and pixel (pairs 0-3). Four rows of 8 bytes, one a speed 1-4; each row holds 4 pairs (the two pixel lines of a star at pixel 0-3 of the byte). Read by MoveStar (`$7A39`). Read in rzx-r2 at the stage's exit. | `MoveStar` | - |
| `$7BE9` | `ScoreDigits` | 2 of 9 | The score as text: two unused bytes, ScoreHigh's two digits, Score's four digits, 0. Read by RenderDigits (IX = `$7BE9` from RenderScore, which skips the first two bytes); written by NumberToDigits and ByteToDigits. EndStage returns ScoreDigitsHigh in BC (EndStageSave `$7926`). | `RenderDigits`, `RenderScore`, `ShowScore` | `ByteToDigits`, `NumberToDigits` |
| `$7BEB` | `ScoreDigitsHigh` (`ScoreDigits`+2) | 2 | ScoreHigh's two digits (ByteToDigits); EndStage returns this address in BC | `RenderDigits`, `RenderScore`, `ShowScore` | `ByteToDigits` |
| `$7BED` | `ScoreDigitsLow` (`ScoreDigits`+4) | 4 | Score's four digits (NumberToDigits) | `RenderDigits`, `RenderScore` | `NumberToDigits` |
| `$7BF1` | `ScoreDigitsEnd` (`ScoreDigits`+8) | 1 | 0: the end mark | `RenderDigits`, `RenderScore` | - |
| `$9E19` | `BarMasks` | 8 | The left-aligned masks of 0-7 pixels for the bar's last byte. `$00`, `$80`, `$C0`, `$E0`, `$F0`, `$F8`, `$FC`, `$FE`, read by DrawEnergyBar `$9DD9` (only the even entries were read in the two recordings: the energy changes by 2). As in stage 1 at `$A41C`. | `DrawEnergyBar` | - |

### Stage 2 (TZX block 43): hero

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7CE1` | `WindowFrameColours` | 16 | The frame's 16 inks: 1 to 7 and back. 1-7, 7, 7, 6-1: CycleWindowFrame (`$7CC3`) takes entry PassCounter & 15 for the 12 cells over and under the item strip. | `CycleWindowFrame` | - |
| `$7D93` | `ItemCountText` | 5 | The count as text for RenderDigits: two unused bytes, two digits, 0. Written by FormatItemCount (`$7D75`, the two digits) and read by RenderDigits through ShowItemCount (`$7D3A`). | `RenderDigits`, `ShowItemCount` | `FormatItemCount` |
| `$7EDC` | `CarriedItems` | 12 | The item kind of each of the 12 slots (slots 0-3 hold 4, the blank icon; the first item at slot 6). Filled from StartItems by InitStageState (`$9776`); read by DrawItemStrip (`$7D0C`), AddItem (`$7E2C`, `$7E41`) and GetSelectedItem (`$7ECA`). | `AddItem`, `DrawItemStrip`, `GetSelectedItem` | `AddItem`, `InitStageState` |
| `$7EE8` | `CarriedCounts` | 12 | The amount of each slot's item (shown by ShowItemCount; AddItem adds). Read by FormatItemCount (`$7D71`) and GetSelectedItem (`$7ED5`, IX = the count's address), written by AddItem (`$7E47`) and InitStageState (`$97B8`: slot 7's count). All 0 as loaded. | `AddItem`, `DrawItemStrip`, `FormatItemCount`, `ThrowItem` | `AddItem`, `InitStageState`, `ThrowItem` |
| `$7EF4` | `StartItems` | 12 | The carried items at the stage's start, copied to CarriedItems by InitStageState: slot 6 item 3, slot 7 item 1. 4 4 4 4 (the blank icon) 0 0, then item 3 at slot 6 and item 1 at slot 7, then 0. Read by InitStageState (`$9773`, an LDIR of 12 bytes to CarriedItems). CarriedItems at `$7EDC` holds the same bytes as loaded. | `InitStageState` | - |
| `$7F00` | `ItemIcons` | 16 | The 16 x 16 icon of each item kind 0-7 (32 bytes each; kind 4 points to the blank BlankIcon `$8BCA`). Read by DrawItemIcon (`$7DEC`). Kinds 0-7: `$DE65`, `$DE85`, `$DEE5`, `$DEA5`, `$8BCA` (blank), `$DF05`, `$DEC5`, `$DF25`. Kind 5 is the artefact the stage's exit needs (CheckStageExit). | `DrawItemIcon` | - |
| `$87F4` | `RecoilSteps` | 7 | The hop's y change at steps 0-6. -5, -1, 0, 0, 1, 2, 3. Read by HeroRecoil (`$87E6`) with the step. | - | - |
| `$8F66` | `RespawnPoints` | 16 of 30 | Column, line of each room: grid 1 (8 rooms), grid 0 (6) at `$8F76`, grid 2 (1) at `$8F82`. 15 pairs, read by RespawnPoint (`$8F45-$8F64`). | `RespawnPoint` | - |
| `$8F76` | `RespawnPointsGrid0` (`RespawnPoints`+16) | 12 | grid 0, rooms 0-5 | `RespawnPoint` | - |
| `$8F82` | `RespawnPointsGrid2` (`RespawnPoints`+28) | 2 | grid 2, room 0 | - | - |
| `$AEDD` | `HeroStandSet` | 4 | SetActorFrame's parameters: the walk frame table `$D1F8`, its graphics `$CF2E` | `SetActorFrame` | - |
| `$AF82` | `HeroStrikeLowSet` | 4 | SetActorFrame's parameters: the strike frame table `$CABB`, its graphics `$C7FE` | `SetActorFrame` | - |
| `$AF86` | `HeroStrikeLowFrames` | 6 | the strike set's frame for each pass of the low strike (+9 for the middle strike) | `HeroStrikeLow`, `HeroStrikeMid`, `SetActorFrame` | - |
| `$AFC4` | `HeroStrikeMidSet` | 4 | the strike frame table `$CABB`, its graphics `$C7FE` | `SetActorFrame` | - |
| `$B000` | `HeroStrikeHighSet` | 4 | the strike frame table `$CABB`, its graphics `$C7FE` | `SetActorFrame` | - |
| `$B004` | `HeroStrikeHighFrames` | 7 | the strike set's frame for each pair of passes of the high strike | `HeroStrikeHigh`, `SetActorFrame` | - |
| `$B0DE` | `HeroWalkSet` | 4 | the walk frame table `$D1F8` (`$0D` frames; `$0C` stands), its graphics `$CF2E` | `SetActorFrame` | - |
| `$B1F3` | `HeroJumpSet` | 4 | the jump frame table `$CEBC` (`$13` frames), its graphics `$CB03` | `SetActorFrame` | - |
| `$B230` | `HeroLeapSet` | 4 | the leap frame table `$EC92`, its graphics `$E9AC` | `SetActorFrame` | - |
| `$B24A` | `TurnSteps` | 12 | the base-column move of a turn at each walk frame. Read by HeroTurn: only `$B24C`, `$B24E`, `$B253`, `$B255` in the recordings. As in stage 1 at `$B106`. | `HeroTurn` | - |

### Stage 2 (TZX block 43): enemies

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$81AC` | `MedusaHeadFrames` | 28 | The head's frame at each of its 28 steps (frames 1-6 of the set at `$D36C`). Read by MedusaHeadActor (`$819B`) with the step +8 / 2. | `MedusaHeadActor` | - |
| `$81CB` | `MedusaFrameSet` | 4 | SetActorFrame's inline words: the frame table `$D4D3`, the set `$D36C` | `SetActorFrame` | - |
| `$81FA` | `MedusaHeadFallSteps` | 27 | The falling head's Y change at steps 1-26 (up, then down, a bounce at the end). Read by MedusaHeadFalls (`$81E8`) with the step 1-`$1A`; the byte at index 0 is not read. | `MedusaHeadActor` | - |
| `$846E` | `PieceFrames` | 4 | SetActorFrame's inline operands: the frame table `$DE29` and the graphics base `$DD41` | `SetActorFrame` | - |
| `$84A7` | `RiseSteps` | 30 | The rising piece's y change at each step 0-29. 30 signed bytes: 10 zeros, then up 1-6, back -4 to 4, -2 to 2 (the bob). Read by PieceRises (`$8491`) with the step. | `UpdatePieceActor` | - |
| `$8DE4` | `HarpyWingsFrameSet` | 4 | SetActorFrame's inline words: the frame table `$D949`, the set `$D797` | `SetActorFrame` | - |
| `$8EBA` | `HarpyBobSteps` | 5 | The harpy's Y change at bob steps 0-4: 1, 0, -1, -1, 1. Read by HarpyActor (`$8E99`) with +`$0D` / 2. | `HarpyActor` | - |
| `$8EBF` | `HarpyAttackFrames` | 14 | The harpy's frame at attack steps 0-13 (by pairs): `$D647`, `$D6B7`, `$D727` x 3, `$D6B7`, `$D647`. Read by HarpyActor (`$8E6D`) with +8 AND `$FE`; the word goes to +4/+5. | `HarpyActor` | - |
| `$9022` | `NoSpawnColumns` | 6 | The place no spirit may take in each room 0-5 of grid 0: 5, 5, 6, 5, 0, 0. Read by IsSpawnBarred (`$8FFE`) with RoomNumber. | `IsSpawnBarred` | - |
| `$9050` | `SpiritFrameSet` | 4 | SetActorFrame's inline words: the frame table `$C5A0`, the set `$C3D5` | `SetActorFrame` | - |
| `$90A1` | `SpiritBobSteps` | 20 | The spirit's Y change at bob steps 0-19 (down 1-3, back up). Read by SpiritFloat (`$906B`). | `SpiritActor` | - |
| `$90EF` | `SpiritShotDirections` | 6 | The six directions of a spirit's volley (ShotDirections' numbers; no straight up or down). Read by SpiritFires (`$90CC`). | `SpiritFires` | - |
| `$A113` | `HydraNeck1Poses` | 21 | The first neck's pose (0-9) at each step 0-`$14`. Read by HydraNeck1Step `$9F0B`: 4, 5, 6, 7, 8, 9, 9, 9, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3 (the long strike from step 0, the sway from `$0E`). | `HydraNeck1Step`, `UpdateHydraNecks` | - |
| `$A128` | `HydraNeck1Points` | 140 | The first neck's 10 poses: 7 points (pixel column, line) each, from the body out. Read by DrawNeckHigh / DrawNeckLow through IX (HydraNeck1Step `$9F1A`). The last point drawn is the head's place. | `DrawNeckHighLoop`, `DrawNeckLow`, `UpdateHydraNecks` | - |
| `$A1B4` | `HydraNeck2Poses` | 20 | The second neck's pose (1-9) at each step 0-`$13`. Read by HydraNeck2Step `$9F50`. | `HydraNeck2Step` | - |
| `$A1C8` | `HydraNeck2Points` | 242 | The second neck's poses 0-10: 11 points (pixel column, line) each. Read through IX from HydraNeck2Step `$9F5F`. The poses are 1-9: pose 0 (`$A1C8-$A1DD`) is read only at its last point (`$A1DC-$A1DD`, the head's place when no segment shows) and pose 10 (`$A2A4-$A2B9`) is never read (the recordings checked: s2-right, rzx-r2; no pose table holds 10). | `DrawNeckLow`, `UpdateHydraNecks` | - |
| `$A2BA` | `HydraNeck3Poses` | 19 | The third neck's pose (0-7) at each step 0-`$12`. Read by HydraNeck3Step `$9F94`. | `HydraNeck3Step`, `UpdateHydraNecks` | - |
| `$A2CD` | `HydraNeck3Points` | 112 | The third neck's 8 poses: 7 points (pixel column, line) each. Read through IX from HydraNeck3Step `$9FAC`. | `DrawNeckLow`, `UpdateHydraNecks` | - |
| `$A714` | `StatueSet` | 4 | SetActorFrame's parameters: the statues' frame table `$E0A4`, their graphics `$DF45`. Four frames: 0 the warrior's head (3 x 14), 1 his body with the shield (5 x 30), 2 his legs (3 x 18), 3 the kneeling statue (3 x 35). | `SetActorFrame` | - |
| `$A7BA` | `HarpyFlameFrames` | 40 | The flame's frame (of HarpyLampSet) for each pair of passes 0-`$27`. Read by HarpyFlameActor `$A7B7`: 24 x 5, then 6, 7, 8, 9, `$0A`, `$0B`, `$0A`, 9, 8, 9, `$0A`, `$0B`, `$0A`, 9, 7, 6. In the two recordings only `$A7BA-$A7BF` were read. | `HarpyFlameActor`, `SetActorFrame` | - |
| `$A7F2` | `HarpyLampSet` | 4 | SetActorFrame's parameters: the frame table `$E54F` (22 frames), the graphics `$E229`. Frame 0 the lamp (4 x 12), 1-4 the harpy asleep (3 x 8), 5-`$0B` the flame (1 x 3 to 2 x 8). | `SetActorFrame` | - |
| `$A879` | `HarpyRiseSet` | 4 | SetActorFrame's parameters: the frame table `$E211` (4 frames), the graphics `$E0BC` | `SetActorFrame` | - |
| `$A8BD` | `HarpyRiseFrames` | 23 of 46 | The rising harpy's frame (of HarpyRiseSet) at each step 0-`$16`, then 23 bytes for phase 2. Read by HarpyRiseActor `$A870` (+`$0B` the step): 0, 1, 0, 1, 0, 1, 0, 1, 2, 1, 2, 1, 2, 1, 2, 3, 3, 2, 3, 2, 3, 2, 3. `$A8D4` on: the frames `$0C-$15` that phase 2 reads at `$A83E` (with +8 at `$13-$16`: `$A8E7-$A8EA`), not executed. Read in the recordings: `$A8BE-$A8D3`. | `HarpyRiseActor`, `SetActorFrame` | - |
| `$A8D4` | `HarpyFallFrames` (`HarpyRiseFrames`+23) | 23 | phase 2's frames (HarpyRiseUp `$A83E`) | `SetActorFrame` | - |
| `$A990` | `DropSet` | 4 | SetActorFrame's parameters: the frame table `$ED59`, the graphics `$ECE6` | `SetActorFrame` | - |
| `$A9F1` | `StrikeableSet` | 4 | SetActorFrame's parameters: the urns' frame table `$C7CE`, their graphics `$C704` | `SetActorFrame` | - |
| `$ABBA` | `FragmentArc0` | 28 of 56 | The line change of each step of a fragment's arc 0 (28 signed bytes). Read by FragmentActor `$AAB4` (+`$0B` the step): up 8, 6, 4, 2, 1 lines, then down 1, 2, 4, 6, 8, a short second hop and the rest. Read in rzx-r2: `$ABBA-$ABD1` (44 reads); its last four bytes no recording read. | `FragmentActor`, `SetActorFrame` | - |
| `$ABD6` | `FragmentArc1` (`FragmentArc0`+28) | 28 | the arcs 1-3 (doubled for 2 and 3): a lower hop | `FragmentActor`, `SetActorFrame` | - |
| `$AC34` | `PoolSet` | 4 | SetActorFrame's parameters: the frame table `$E82C`, the graphics `$E61C` | `SetActorFrame` | - |
| `$AC38` | `PoolRuns` | 10 | Five runs of the pool's frames: the first frame and the length (0, 3), (3, 3), (6, 6), (`$0C`, 3), (`$0F`, 3). Read by PoolActor `$AC23` at the index (0-3) PoolPicks gives: the fifth run (`$AC40-$AC41`) no pick selects (never read). | `PoolActor` | - |
| `$AC42` | `PoolPicks` | 16 | The run (0-3) for each random 0-15: 0 ten times, 1 four, 2 and 3 once each. Read by PoolActor `$AC11`. | `PoolActor` | - |

### Stage 2 (TZX block 43): missiles

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$82CD` | `ShotFrames` | 20 | Frame records: graphics address, width, lines (`$C5D0` 2x5, `$C5DA` 1x15, `$C5E9` 1x15, `$C5F8` 2x13, `$C612` 2x13). Five 4-byte records: the bitmap's address, the width in bytes, the height in lines. Read by DrawShotFrame (`$82AB`) with the offset from ShotDirections (UpdateAimedShot) or 0 (UpdateHeroShot: the 2 x 5 bolt). Read in both recordings. | `ColourSprite`, `ColourSpriteMirrored`, `DrawShotFrame`, `DrawSprite`, `DrawSpriteMirrored` +1 | - |
| `$82E1` | `ShotDirections` | 32 | The 8 directions: dx, dy, the frame's offset in ShotFrames, 1 mirrored. Eight 4-byte records for directions 0-7 (up, up-right, right, down-right, down, down-left, left, up-left): dx in columns, dy in lines, the frame's offset (0, 4, 8, 12, 16), 1 when drawn mirrored. Read by UpdateAimedShot (`$827E`) with the shot's +4. | `UpdateAimedShot` | - |
| `$8664` | `PathSteps` | 134 | The flyer's path: dx (half columns), dy a step; `$64` `$64` ends. 66 pairs (dx, dy), then the end mark `$64` `$64` at `$86E8`. Read by UpdatePathFlyer (`$85CB`) with the step +4. | `UpdatePathFlyer` | - |
| `$B449` | `MissileHandlers` | 20 | The handler of each missile kind 0-9 (10 words; stage 1 has 12). 0 none (`$0000`), 1 UpdateAimedShot (the spirits' shots), 2 and 3 UpdateDriftLeft (the harpy's and the hydra heads' shots), 4 UpdateFloorShot (Medusa's head), 5 and 6 UpdateHeroMissile (item kind 6, left and right), 7 and 8 UpdatePathFlyer (the hero's death fragments), 9 UpdateHeroShot (ThrowItem's shot). Read by UpdateMissiles (`$B42F`) for every missile in use: s2-right and rzx-r2. | `UpdateMissiles` | - |
| `$B4F0` | `DriftColours` | 4 | The hydra shots' colours: bright red, bright magenta, bright red, magenta (`$42`, `$43`, `$42`, 3). Read by DriftShotColour (`$B4E9`): all four in rzx-r2; not in s2-right (no hydra there). | `DriftShotColour` | - |
| `$B509` | `CycleColours` | 8 | the colour cycle. `$45`, `$44`, `$43`, `$42`, `$41`, `$42`, `$43`, `$44`. Read through FlashPieces (`$850E`) and CycleColour (`$B503`): all 8 bytes in s2-right and rzx-r2. As in stage 1 at `$B3D2`. | `CycleColour`, `FlashPieces` | - |
| `$B5DF` | `FloorShotImage` | 4 | DrawSprite's descriptor for the floor shot: +2 = 1 byte wide, +3 = 12 lines (+0/+1 not read, 0). Read by DrawSprite and ColourSprite (+2 and +3) from DrawFloorShot: rzx-r2. | `ColourSprite`, `DrawSprite` | - |
| `$B608` | `HeroMissileImage` | 4 | DrawSprite's descriptor for the hero's missile: 1 byte x 12 lines (+0/+1 not read, 0). Read by DrawSprite / DrawSpriteMirrored and ColourSprite from DrawHeroMissile: rzx-r2. | `ColourSprite`, `DrawSpriteMirrored` | - |
| `$B6DD` | `ImageDescriptors` | 36 | Nine image descriptors (the image address, the width in bytes, the height in lines): 4 drift frames, 5 fade frames. `$E898`, `$E8BF`, `$E8E6`, `$E90D` (DriftShotSprites, 3 x 13) and `$E934`, `$E94C`, `$E964`, `$E97C`, `$E994` (DriftFadeSprites, 3 x 8). Stage 1 has the first four only. Read by UpdateDriftLeft (`$B653`, `$B6AB`) and DrawMissileMirrored: all 36 bytes in s2-right and rzx-r2. | `ColourSprite`, `ColourSpriteMirrored`, `DrawSpriteMirrored`, `UpdateDriftLeft`, `UpdatePathFlyer` | - |
| `$B701` | `DriftFallSteps` | 64 | Four fall curves of 16 line steps (1-5): a drifting shot's line step at fall step 0-15, the curve by its +5 AND 3. Read by UpdateDriftLeft (`$B681`): 56 of the 64 bytes in s2-right and rzx-r2. | `UpdateDriftLeft` | - |

### Stage 2 (TZX block 43): rooms

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$953E` | `Grid0` | 9 of 201 | Grid 0's record (the temple): 69 x 9 blocks, the start window at 0, 0, the room table Grid0Rooms, map offset 0, 6 rooms a grid row. A grid record, 9 bytes, as stage 1's: +0 the width and +1 the height in blocks, +2/+3 the start window's block column and row (StartGrid; StageEntry sets +2 = `$37` for the first build and puts 0 back), +4/+5 the room table, +6/+7 the grid's offset in the map section of StageGraphics, +8 the rooms a grid row. Unlike stage 1's block the three records come first, then the three room tables, then the placement lists. The room table, one byte a room: the exits, bit 0 right, bit 1 left, bit 2 up, bit 3 down (the edge checks). Read and partly written (the start window) in s2-right and rzx-r2: 146 and 189 of the map's 201 bytes read. The file map.txt holds the records, their room tables and the placement lists (tools/res_stage2.py); tools/fig_rooms.py draws the map and every room from it (docs/img/maps/stage2.png, stage2-rooms.png). LoadRoomActors puts each placement not done that lies in the room's window into a free actor record with its kind's row of ActorKinds. Grid 0: the urns (kinds 16-19), the pools' ripples (20), the statues (0, 1, 14, 15), the harpy's lamp, flame and rise (2, 13, 3). | `CheckRoomExits`, `ClearTakenFlags`, `HeroActor`, `LeaveRoomDown`, `LeaveRoomUp` +5 | `ClearTakenFlags`, `LeaveGrid1`, `MarkPlacementDone`, `ReviveAllPlacements` |
| `$9547` | `Grid1` (`Grid0`+9) | 9 | Grid 1 (the hydra's caves): 47 x 15 blocks, start 0, 0, map offset `$026D`, 4 rooms a grid row (8 rooms; EnterGrid1, LeaveGrid2) | `HeroActor`, `LeaveRoomDown`, `LeaveRoomUp`, `RoomCells`, `StartGrid` | - |
| `$9550` | `Grid2` (`Grid0`+18) | 9 | Grid 2 (Medusa's room): 14 x 9 blocks, one room, map offset `$052E` (EnterGrid2) | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9559` | `Grid0Rooms` (`Grid0`+27) | 6 | 6 rooms in a row: the exits of each | `CheckRoomExits` | - |
| `$955F` | `Grid1Rooms` (`Grid0`+33) | 8 | 8 rooms, 4 a row | `CheckRoomExits` | - |
| `$9567` | `Grid2Rooms` (`Grid0`+41) | 1 | 1 room, no exits | `CheckRoomExits` | - |
| `$9568` | `Grid0Placements` (`Grid0`+42) | 57 | grid 0's 18 placements: the kind (bit 7: done), X and Y in cells over the whole grid; `$FF` `$FF` `$FF` ends | `ClearTakenFlags`, `LoadRoomActors`, `MarkPlacementDone`, `ReviveAllPlacements` | `ClearTakenFlags`, `MarkPlacementDone`, `ReviveAllPlacements` |
| `$95A1` | `Grid1Placements` (`Grid0`+99) | 93 | grid 1's 30: urns, the pool (kinds 4, 5), the hydra's heads (7-10), the drops (6) | `ClearTakenFlags`, `LoadRoomActors`, `MarkPlacementDone` | `ClearTakenFlags`, `MarkPlacementDone` |
| `$95FE` | `Grid2Placements` (`Grid0`+192) | 9 | grid 2's 2: Medusa and her head (kinds 11, 12) | `ClearTakenFlags`, `LoadRoomActors` | `ClearTakenFlags` |
| `$B7D5` | `StageGraphics` | 3072 | The stage's tiles, blocks and map, RLE-packed (3072 bytes; 3852 unpacked: 195 tiles, 110 blocks, the three grids' map of 1452 bytes). RoomChange `$9257` unpacks it with Unrle `$A33D` into the play buffer at `$5B00` at every room change. Unrle as in stage 1: the first byte is the escape (`$C9` here); a byte other than the escape is itself, ESC n v is n copies of v, ESC ESC ends. The unpacked block: five words (the offsets of the tile kinds, pixels, attributes, blocks and map from `$5B0A`), then the five sections. The packer that made it is greedy (every run of 4 to 255 equal bytes is ESC n v) except one stretch of 8 zero bytes left as they are (unpacked offset 1397, a blank tile's pixels); with that one exception tools/res_stage.py packs the block again bit for bit. graphics.txt holds the escape, the stretch, the tile kinds, the blocks and the map (GRIDS['stage2'] in tools/res_stage.py: 69 x 9, 47 x 15, 14 x 9), tiles.png the tiles' pixels and colours. Read whole in s2-right and rzx-r2. | `Unrle` | - |

### Stage 2 (TZX block 43): util

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8BCA` | `BlankIcon` | 32 | 32 zero bytes: the blank icon (item kind 4) and the source of every clear done by copying with stride 0. Read through GameOverStep (`$8577`) and, as item kind 4's icon, through ItemIcons `$7F00` (DrawItemIcon). As in stage 1 at `$8BA3`. All 32 bytes read in s2-right and rzx-r2. | `CopyToScreen`, `DrawItemIcon`, `PlotRow1`, `PlotRow1Mirrored` | - |

### Stage 2 (TZX block 43): actors

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8D62` | `ClearRecordUnused` | 15 | Code no CALL or JP reaches: PUSH IY twice, POP HL, POP DE, LD BC,`$11`, LD (HL),0, INC DE, LDIR, RET (clears the 18-byte record at IY). No reader and no jump: the bytes between SpawnTimer and FindFreeActor. As code it would clear the actor record IY; stage 2 frees records with RemoveActor instead. | - | - |
| `$9607` | `ActorKinds` | 189 | The 21 placement kinds, 9 bytes each: the Y offset, the handler, 5 bytes for the record's +8 to +`$0C`, the record's +`$0F`. As stage 1's: LoadRoomActors (`$A499`) builds an actor from a placement with its kind's row: +1 Y = the placement's Y x 8 + the offset, +6/+7 the handler, +8 to +`$0C` (the counter, the flags, the state, the item, the attribute), +`$0F` (bit 0 shootable: ShotHitsActor; bit 1 kept over a room change: LoadRoomActors). The handlers: 0 KneelingStatueActor, 1, 14, 15 WarriorStatueActor, 2 HarpyLampActor, 3 HarpyRiseActor, 4 and 5 PoolActor, 6 DropActor, 7-10 HydraHead1Actor, HydraHead2Actor, HydraHead3Actor, HydraHead1LowActor, 11 MedusaActor, 12 MedusaHeadActor, 13 HarpyFlameActor, 16-19 StrikeableActor, 20 WaterActor. All 189 bytes read in rzx-r2 (117 in s2-right). | `LoadRoomActors` | - |
| `$96C4` | `ActorTemplates` | 18 of 162 | Nine whole actor records (18 bytes each, the first the hero's) that SpawnActor copies for the actors no placement makes. The handler at +6/+7 and the frame at +4/+5 as for a placed actor; the rest as an actor record (HeroRecord `$74E0`). All read in rzx-r2 (90 of 162 bytes in s2-right); ExtraLifeTemplateFlags written by ReleaseExtraLife. | `SpawnActor` | `ReleaseExtraLife` |
| `$96D6` | `SpiritTemplate` (`ActorTemplates`+18) | 18 | a spirit (SpawnRandomEnemy `$8FEB`): handler SpiritActor `$9028` | `SpawnActor` | - |
| `$96E8` | `HarpyWingsTemplate` (`ActorTemplates`+36) | 18 | the harpy's wings (SpawnHarpy `$8DB1`): handler HarpyWingsActor `$8DD2` | `SpawnActor` | - |
| `$96FA` | `HarpyTemplate` (`ActorTemplates`+54) | 18 | the harpy (SpawnHarpy `$8DBF`): 4 x 28, frame `$D647`, handler HarpyActor `$8DE8` | `SpawnActor` | - |
| `$970C` | `ItemTemplate` (`ActorTemplates`+72) | 18 | an item lying on the floor (SpawnItem `$9A7A`): 2 x 16, handler ItemHandler `$9ACD` | `SpawnActor` | - |
| `$971E` | `ExtraLifeTemplate` (`ActorTemplates`+90) | 9 | an urn's extra life (ReleaseExtraLife `$9A99`): handler ExtraLifeActor `$9AFA` | `SpawnActor` | - |
| `$9727` | `ExtraLifeTemplateFlags` (`ActorTemplates`+99) | 9 | its +9: `$80` (facing left) once ReleaseExtraLife has set it | `SpawnActor` | `ReleaseExtraLife` |
| `$9730` | `SparkleTemplate` (`ActorTemplates`+108) | 18 | the sparkle of a life taken (ExtraLifeSparkle `$8428`): handler SparkleActor `$9B4F` | `SpawnActor` | - |
| `$9742` | `PieceTemplate` (`ActorTemplates`+126) | 18 | a piece of the stage's artefact (SpawnBonus `$83F7`, `$840B`): handler UpdatePieceActor `$842E` | `SpawnActor` | - |
| `$9754` | `FragmentTemplate` (`ActorTemplates`+144) | 18 | a fragment of a broken statue (InitFragment `$AA6E`): 3 x 11, handler FragmentActor `$AA81` | `SpawnActor` | - |
| `$9804` | `Unused9804` | 12 | 12 bytes no code reads: 0, 1, 2, 2, 1, 0, 0, 1, 3, 3, 1, 0. No instruction reads or writes them (neither recording touches them, and no operand points into `$9804-$980F`). | - | - |
| `$9B5D` | `SparkleSet` | 4 | SetActorFrame's inline words: the frame table `$E5F8`, the graphics SparkleSprites `$E5D3`. Read by SetActorFrame from SparkleActor (`$9B5A`): rzx-r2 (all four bytes); not in s2-right. | `SetActorFrame` | - |
| `$9D8F` | `BurstLeftover` | 1 | An unreached RET byte after UpdateBurst's loop. No code jumps to `$9D8F` (UpdateBurst's loop leaves by RET Z at `$9CCB`). As stage 1's `$A392`. | - | - |
| `$9D96` | `ParticleInks` | 4 | The burst's four particle attributes, written by StartBurst. Ink C, bright ink C, ink B, bright ink B (StartBurst `$9BFA` writes them); a particle's +3 (0-3) picks one (UpdateBurst `$9D72`). As loaded: 2, `$42`, `$43`, 3. As in stage 1 at `$A399`. | `UpdateBurst` | `StartBurst` |
| `$9D9A` | `BurstSteps` | 20 of 40 | 20 (dx, dy) steps: 10 for the directions `$0A` and up (less `$0D`), 10 for the directions 0-9. Read by UpdateBurst `$9D06` (+ `$14` for the second set): signed dx (columns) and dy (cell rows, subtracted). The pairs 0, 2, 4, 6, 8 of each set: (0,0) (0,1) (0,0) (0,-1) (1,0)... As in stage 1's BurstSteps `$A39D`. Read in rzx-r2: `$9D9A-$9D9D`, `$9DA0-$9DA7`, `$9DAE-$9DB1`, `$9DB4-$9DBB`; the pairs at `$9D9E`, `$9DA8-$9DAD`, `$9DB2` and `$9DBC-$9DC1` no recording read. | `UpdateBurst` | - |
| `$9DAE` | `BurstStepsSecond` (`BurstSteps`+20) | 20 | the 10 steps of the directions 0-9 | `UpdateBurst` | - |

### Stage 2 (TZX block 43): graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C3D5` | `SpiritSprites` | 459 of 507 | The spirit: 8 frames, growing out of the floor (0-5) and flapping (6, 7) (SpiritActor `$9028`). SpiritFrameSet `$9050` (SetActorFrame's inline words). All 507 bytes read in s2-right and rzx-r2. | `PlotRow1`, `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$C5A0` | `SpiritFrameTable` (`SpiritSprites`+459) | 48 | 8 records | `SetActorFrame` | - |
| `$C5D0` | `ShotSmall` | 10 | A shot: 2 bytes x 5 lines (ShotFrames `$82CD`'s first record). The spirits' shots (UpdateAimedShot), ShotFrames `$82CD`: this one, two of 1 x 15 and two of 2 x 13, by direction. Read in s2-right and rzx-r2. | `DrawSprite`, `DrawSpriteMirrored`, `SetActorFrame` | - |
| `$C5DA` | `ShotUpright` | 30 | Two shots of 1 byte x 15 lines (the ones flying up and down). Not read in the recordings checked (s2-right, rzx-r2): SpiritShotDirections `$90EF` has no straight up or down; known only from the code (ShotFrames). | `SetActorFrame` | - |
| `$C5F8` | `ShotSlanted` | 52 | Two shots of 2 bytes x 13 lines (the slanted ones). Read in s2-right and rzx-r2. | `DrawSprite`, `DrawSpriteMirrored`, `OrNeckSegment`, `SetActorFrame` | - |
| `$C62C` | `RippleSprites` | 24 | The pool's ripple: 3 frames of 4 bytes x 2 lines (WaterActor `$8782`: `$C62C` + frame x 8). Read whole in s2-right and rzx-r2. | `DrawActorSprite`, `SetActorFrame` | - |
| `$C644` | `GameOverPicture` | 64 | GAME OVER: 8 bytes x 8 lines, drawn in the HUD's item strip (GameOverStep `$8585`). Read whole in s2-right (its game over); not in rzx-r2. | `CopyToScreen`, `SetActorFrame` | - |
| `$C684` | `NeckSegments` | 128 | A segment of a hydra's neck: 8 copies of 2 bytes x 8 lines, shifted 0-7 pixels (OrNeckSegment `$A066`). DrawNeckHighLoop (`$9FEC`) and DrawNeckLow (`$A0DB`) point BC at `$C684` + 16 x the shift. 124 of the 128 bytes read in rzx-r2; not in s2-right (no hydra). | `OrNeckSegment`, `SetActorFrame` | - |
| `$C704` | `StrikeableSprites` | 202 of 250 | The urns: 8 frames, two of each (whole, cracked) for the kinds 16-19 (StrikeableActor `$A9B8`). StrikeableSet `$A9F1`. Read whole in rzx-r2 (152 of 250 bytes in s2-right). | `DrawActorSprite`, `SetActorFrame` | - |
| `$C7CE` | `StrikeableFrameTable` (`StrikeableSprites`+202) | 48 | 8 records | `SetActorFrame` | - |
| `$C7FE` | `HeroStrikeSprites` | 701 of 767 | The hero's strikes: 11 frames (low, middle, high). HeroStrikeLowSet `$AF82`, HeroStrikeMidSet `$AFC4`, HeroStrikeHighSet `$B000`. Read whole in rzx-r2 (583 of 767 bytes in s2-right). | `DrawEnergyBar`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored` +5 | - |
| `$CABB` | `HeroStrikeFrameTable` (`HeroStrikeSprites`+701) | 66 | 11 records | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `SetActorFrame` | - |
| `$CAFD` | `EnergyBarPattern` | 6 | The energy bar's pattern: 6 bytes, one pixel line (DrawEnergyBar `$9DC2` draws Energy / 8 of them on 6 lines). Read in s2-right and rzx-r2 (three of the six bytes: the bar never runs out in them). | `DrawEnergyBar`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` | - |
| `$CB03` | `HeroJumpSprites` | 953 of 1067 | The hero's jump: 19 frames (HeroJumpSet `$B1F3`). Read whole in s2-right and rzx-r2. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` +2 | - |
| `$CEBC` | `HeroJumpFrameTable` (`HeroJumpSprites`+953) | 114 | 19 records | `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$CF2E` | `HeroWalkSprites` | 714 of 792 | The hero walking and standing: 13 frames (HeroWalkSet `$B0DE`, HeroStandSet `$AEDD`; frame 12 stands). Read whole in s2-right and rzx-r2. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` +2 | - |
| `$D1F8` | `HeroWalkFrameTable` (`HeroWalkSprites`+714) | 78 | 13 records | `PlotRow3`, `SetActorFrame` | - |
| `$D246` | `GraphicsLeftover` | 30 | 30 bytes between the walk set's frame table and FragmentSprites that no code reads. No instruction or table points into them and the recordings checked (s2-right, rzx-r2) read none; known only from the code. A leftover of the graphics block (stage 1 has no such gap here). | `PlotRow3`, `SetActorFrame` | - |
| `$D264` | `FragmentSprites` | 264 | A fragment of a broken statue: 8 copies of 3 bytes x 11 lines, shifted 0-7 pixels (MoveFragment `$ABA2`: `$D264` + 33 x shift). Read whole in rzx-r2 (the statues broken); not in s2-right. | `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$D36C` | `MedusaSprites` | 359 of 401 | Medusa: 7 frames, the statue, her head looking about and lying (MedusaSetFrame `$81C8`). MedusaFrameSet `$81CB` (SetActorFrame's inline words). Read whole in rzx-r2; not in s2-right (it never reaches grid 2). | `PlotRow2`, `PlotRow3`, `PreShiftSprite`, `SetActorFrame` | - |
| `$D4D3` | `MedusaFrameTable` (`MedusaSprites`+359) | 42 | 7 records | `PlotRow3`, `SetActorFrame` | - |
| `$D4FD` | `SpinShotSprites` | 132 | A spinning shot: 11 frames of 1 byte x 12 lines, spinning up (0-4), flying (5), breaking up (5-10). DrawFloorShot `$B5C6` (Medusa's head's shot) and DrawHeroMissile `$B5E3` (item 6's missile): `$D4FD` + 12 x frame. 108 of 132 bytes read in rzx-r2; not in s2-right. | `DrawSprite`, `DrawSpriteMirrored`, `PlotRow3` | - |
| `$D581` | `HydraHeadSprites` | 198 | A hydra head: 3 frames of 3 bytes x 22 lines, by its pose (PlaceHydraHead `$8100`: from `$D605`, the last frame, back 66 bytes a frame). Read whole in rzx-r2; not in s2-right. | `PlotRow3`, `PreShiftSprite` | - |
| `$D647` | `HarpySprites` | 112 of 336 | The harpy's body: 3 frames of 4 bytes x 28 lines (HarpyAttackFrames `$8EBF`; HarpyTemplate's frame). Read whole in s2-right and rzx-r2. | `PlotRow4` | - |
| `$D6B7` | `HarpySprite1` (`HarpySprites`+112) | 112 | - | `PlotRow4` | - |
| `$D727` | `HarpySprite2` (`HarpySprites`+224) | 112 | - | `PlotRow4` | - |
| `$D797` | `HarpyWingsSprites` | 434 of 464 | The harpy's wings: 5 frames (HarpyWingsActor `$8DD2`). HarpyWingsFrameSet `$8DE4`. Read whole in s2-right and rzx-r2. | `PlotRow4`, `PlotRow6`, `SetActorFrame` | - |
| `$D949` | `HarpyWingsFrameTable` (`HarpyWingsSprites`+434) | 30 | 5 records | `SetActorFrame` | - |
| `$D967` | `HydraBodyPicture` | 986 | The hydra's body: a row-packed picture of 112 lines (each a byte LEN x 16 + SKIP, then LEN bytes), drawn in rooms 7 and 3. DrawHydraBody `$9E21` draws it with DrawRowPicture `$8B2A` while the hydra lives: all 112 lines in room 7 from the buffer address `$5C12`, its top 48 lines at the bottom of room 3 from `$6712`. All 986 bytes read in rzx-r2; not in s2-right. | `DrawRowPicture` | - |
| `$DD41` | `PieceSprites` | 28 of 292 | A piece of the stage's artefact: 10 frames (UpdatePieceActor `$842E`); the first two (2 x 14) are also the HUD's piece pictures. ShowPieceTaken copies `$DD41` (the first piece) or `$DD5D` (the others) to the HUD. PieceFrames `$846E`. 286 of 292 bytes read in rzx-r2, 258 in s2-right. | `CopyToScreen`, `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$DD5D` | `PieceSprite1` (`PieceSprites`+28) | 204 | the second frame, the HUD's picture of a later piece | `CopyToScreen`, `PlotRow2`, `PlotRow3` | - |
| `$DE29` | `PieceFrameTable` (`PieceSprites`+232) | 60 | 10 records | `PlotRow2`, `SetActorFrame` | - |
| `$DE65` | `ItemIconSprites` | 32 of 224 | The item icons: 7 of 2 bytes x 16 lines (the first item kind 0's), for the HUD's strip and the items on the floor (ItemIcons `$7F00`). DrawItemIcon and the item actors (SpawnItem sets the icon as the frame). Kind 4's icon is BlankIcon `$8BCA` outside the block. 192 of 224 bytes read in rzx-r2, 96 in s2-right. | `DrawItemIcon`, `PlotRow2`, `SetActorFrame` | - |
| `$DE85` | `ItemIconKind1` (`ItemIconSprites`+32) | 32 | - | `DrawItemIcon`, `PlotRow2`, `SetActorFrame` | - |
| `$DEA5` | `ItemIconKind3` (`ItemIconSprites`+64) | 32 | - | `DrawItemIcon`, `PlotRow2`, `SetActorFrame` | - |
| `$DEC5` | `ItemIconKind6` (`ItemIconSprites`+96) | 32 | - | `DrawItemIcon`, `PlotRow2`, `SetActorFrame` | - |
| `$DEE5` | `ItemIconKind2` (`ItemIconSprites`+128) | 32 | - | `DrawItemIcon`, `PlotRow2`, `SetActorFrame` | - |
| `$DF05` | `ItemIconKind5` (`ItemIconSprites`+160) | 32 | the artefact | `DrawItemIcon`, `PlotRow2`, `SetActorFrame` | - |
| `$DF25` | `ItemIconKind7` (`ItemIconSprites`+192) | 32 | - | `SetActorFrame` | - |
| `$DF45` | `StatueSprites` | 351 of 375 | The statues: 4 frames (KneelingStatueActor `$A6EC`, WarriorStatueActor `$A718`). StatueSet `$A714`. Read whole in s2-right and rzx-r2. | `DrawActorSprite`, `SetActorFrame` | - |
| `$E0A4` | `StatueFrameTable` (`StatueSprites`+351) | 24 | 4 records | `SetActorFrame` | - |
| `$E0BC` | `HarpyRiseSprites` | 341 of 365 | The harpy rising out of its statue: 4 frames (HarpyRiseActor `$A7F6`). HarpyRiseSet `$A879`. Read whole in s2-right and rzx-r2. | `PlotRow3`, `PlotRow4`, `SetActorFrame` | - |
| `$E211` | `HarpyRiseFrameTable` (`HarpyRiseSprites`+341) | 24 | 4 records | `PlotRow3`, `PlotRow4`, `SetActorFrame` | - |
| `$E229` | `HarpyLampSprites` | 806 of 938 | The lamp, its flame and the extra life: 22 frames (HarpyLampActor `$A7E2`, HarpyFlameActor `$A760`, ExtraLifeActor `$9AFA` frames 18-21). HarpyLampSet `$A7F2`. 271 of 938 bytes read in rzx-r2, 183 in s2-right: most frames are never shown in them. | `PlotRow1`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored` +2 | - |
| `$E54F` | `HarpyLampFrameTable` (`HarpyLampSprites`+806) | 132 | 22 records | `PlotRow2`, `SetActorFrame` | - |
| `$E5D3` | `SparkleSprites` | 37 of 73 | The sparkle of a life taken: 6 frames (SparkleActor `$9B4F`). SparkleSet `$9B5D`. Read whole in rzx-r2; not in s2-right. | `PlotRow1`, `PlotRow2`, `SetActorFrame` | - |
| `$E5F8` | `SparkleFrameTable` (`SparkleSprites`+37) | 36 | 6 records | `SetActorFrame` | - |
| `$E61C` | `PoolSprites` | 528 of 636 | The bubbling pool's surface: 18 frames (PoolActor `$ABF2`). PoolSet `$AC34`. 576 of 636 bytes read in rzx-r2; not in s2-right (no pool in grid 0's first rooms). | `DrawActorSprite`, `PlotRow2Mirrored`, `SetActorFrame` | - |
| `$E82C` | `PoolFrameTable` (`PoolSprites`+528) | 108 | 18 records | `SetActorFrame` | - |
| `$E898` | `DriftShotSprites` | 39 of 156 | The drifting shots: 4 frames of 3 bytes x 13 lines (ImageDescriptors `$B6DD` 0-3, UpdateDriftLeft `$B639`). Read whole in s2-right and rzx-r2. | `DrawSpriteMirrored`, `UpdatePathFlyer` | - |
| `$E8BF` | `DriftShot1` (`DriftShotSprites`+39) | 39 | - | `DrawSpriteMirrored`, `UpdatePathFlyer` | - |
| `$E8E6` | `DriftShot2` (`DriftShotSprites`+78) | 39 | - | `DrawSpriteMirrored` | - |
| `$E90D` | `DriftShot3` (`DriftShotSprites`+117) | 39 | - | `DrawSpriteMirrored` | - |
| `$E934` | `DriftFadeSprites` | 24 of 120 | A drifting shot fading on the ground: 5 frames of 3 bytes x 8 lines (ImageDescriptors 4-8). Read whole in s2-right and rzx-r2. | `DrawSpriteMirrored` | - |
| `$E94C` | `DriftFade1` (`DriftFadeSprites`+24) | 24 | - | `DrawSpriteMirrored` | - |
| `$E964` | `DriftFade2` (`DriftFadeSprites`+48) | 24 | - | `DrawSpriteMirrored` | - |
| `$E97C` | `DriftFade3` (`DriftFadeSprites`+72) | 24 | - | `DrawSpriteMirrored` | - |
| `$E994` | `DriftFade4` (`DriftFadeSprites`+96) | 24 | - | `DrawSpriteMirrored` | - |
| `$E9AC` | `HeroLeapSprites` | 742 of 826 | The hero's leaps (back and up): 14 frames (HeroLeapSet `$B230`). 476 of 826 bytes read in rzx-r2; not in s2-right. | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$EC92` | `HeroLeapFrameTable` (`HeroLeapSprites`+742) | 84 | 14 records | `PlotRow2`, `SetActorFrame` | - |
| `$ECE6` | `DropSprites` | 115 of 193 | The drop: 13 frames, falling and splashing (DropActor `$A929`). DropSet `$A990`. 186 of 193 bytes read in s2-right and rzx-r2. | `PlotRow2`, `SetActorFrame` | - |
| `$ED59` | `DropFrameTable` (`DropSprites`+115) | 78 | 13 records | `SetActorFrame` | - |
| `$EDA7` | `ParticleGlyphs` | 32 | The burst's 4 particle glyphs, 1 byte x 8 lines each (UpdateBurst `$9C92`: BurstGlyphs[...] x 8 + `$EDA7`). Read whole in rzx-r2; not in s2-right (no burst in it). | `UpdateBurst` | - |
| `$EDC7` | `BurstGlyphs` | 35 | The glyph (0-3) of each burst step, indexed by the step + a random 0-3 (35 bytes). Read by UpdateBurst (`$9CAE`): 31 of 35 in rzx-r2. | `UpdateBurst` | - |
| `$EDEA` | `BurstDirections` | 192 | 6 rows of 32 indices into BurstSteps `$9D9A`: each particle direction's step at each burst step. Read by UpdateBurst (`$9CE6`): 179 of 192 in rzx-r2. | `UpdateBurst` | - |
| `$EEAA` | `BurstShapes` | 14 of 104 | The shapes a burst breaks up: 2 bytes x 12 lines read from six overlapping addresses (StartBurst `$9BFA` reads 24 bytes from the shape's address). `$EEAA` (CutHydraHead1-3), `$EEB8` (MedusaStruck `$8138`, UnusedBurst `$9B82`), `$EECA` (BreakStatue0 / 1), `$EEE2` (ScoreBurst20 `$99E1`, BurstSpirit `$9B92`), `$EEEE` (HydraDefeated, room 3), `$EEFA` (HydraDefeated, room 7): 104 bytes in all, which the file shows as 4 frames of 24 bytes and 8 bytes left over. Read whole in rzx-r2; not in s2-right. | `StartBurst`, `UpdateBurst` | - |
| `$EEB8` | `BurstShapeMedusa` (`BurstShapes`+14) | 18 | MedusaStruck's shape (also UnusedBurst's) | `StartBurst`, `UpdateBurst` | - |
| `$EECA` | `BurstShapeStatue` (`BurstShapes`+32) | 24 | the statues' shape | `StartBurst` | - |
| `$EEE2` | `BurstShape20` (`BurstShapes`+56) | 12 | ScoreBurst20's and BurstSpirit's shape | `StartBurst` | - |
| `$EEEE` | `BurstShapeHydraTop` (`BurstShapes`+68) | 12 | the hydra's top in room 3 | `StartBurst` | - |
| `$EEFA` | `BurstShapeHydraBody` (`BurstShapes`+80) | 24 | the hydra's body in room 7 | `StartBurst` | - |
| `$EF12` | `BlockEnd` | 301 | 301 zero bytes to the block's end (`$F03E`) that no code reads (s2-right, rzx-r2; known only from the code) | - | - |


## Stage 3 (TZX block 46) (`src/stage3/stage3.json`)

Myth: History in the Making, System 3 Software 1989: stage 3 (TZX block 46), 33 792 bytes loaded at `$6C3F` by the
resident stage loader over `$6C3F-$F03E` (tools/image.py). Its entries are `src/stage3/<module>.asm`, written from
`src/stage3/stage3.ann` by `kit/mkgame.py --part src/stage3/stage3.json`; the readers and writers from
`work/stage1/rec/s3-right`, `work/stage2/rec/rzx-r3`.

### Stage 3 (TZX block 46): variables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6C3F` | `PlayBufferTail` | 193 | The last 193 bytes of the play buffer PlayBuffer `$5B00-$6CFF` (character row 17's last lines). ClearBuffer `$9A7D` clears the play buffer to `$6CFF` with PUSH HL (SP from `$6D00`); RoomChange unpacks the stage's tiles and map into it from `$5B00` (4437 bytes, to `$6C54`: StageGraphics); the actors are drawn into it every pass. Zero as loaded. Read and written in rzx-r3 and s3-right (all 193 bytes written in rzx-r3). | `CopyBuffer`, `PlotRow2`, `PlotRow4`, `PlotRow4Mirrored`, `PutBlock` +1 | `DrawActorSprite`, `PlotRow2`, `PlotRow4`, `PlotRow4Mirrored`, `Unrle` +1 |
| `$6D00` | `ShadowAttributes` | 192 of 768 | The shadow of the screen's 768 attributes, the screen's layout; the play area from `$6DC2` (row 6, column 2). The HUD's colours are copied into rows 0-5 at the stage's set-up (StageSetUp `$970D`); RoomChange writes each cell's attribute into rows 6-23, the actors' colours are painted over them every pass, and UpdateAttributes copies the open cells to `$5800` (ShowShadowAttributes `$8B3E` the whole of it). FillShadowAttributes `$8B0E` paints rectangles into it with five bytes after its CALL. The two big pictures paint their colour tables into it with `$FF` cells left alone: the dragon's at `$6E92` (DragonAttributes, row 9 column 18) and the seated figure's at `$6E59` (ThroneAttributes, row 9 column `$19`). Zero as loaded. All 768 bytes read and written in rzx-r3 and s3-right. | `ClearShadowAttributes`, `FadeInStep`, `ShowScore`, `ShowShadowAttributes`, `StopRoomEffects` +2 | `ClearShadowAttributes`, `ColourActor`, `ColourSprite`, `ColourSpriteMirrored`, `DrawDragon` +9 |
| `$6DC0` | `PlayAttributes` (`ShadowAttributes`+192) | 2 | row 6: the first row of the play area (the room's 18 rows) | `ClearShadowAttributes`, `ShowShadowAttributes`, `StopRoomEffects`, `UpdateRain` | `ClearShadowAttributes`, `SaveAttributes`, `UpdateRain` |
| `$6DC2` | `PlayAttributesCell` (`ShadowAttributes`+194) | 151 | row 6, column 2: the room's first cell | `ClearShadowAttributes`, `FadeInStep`, `ShowShadowAttributes`, `StopRoomEffects`, `UpdateAttributes` +1 | `ClearShadowAttributes`, `ColourActor`, `ColourSprite`, `FillShadowAttributes`, `RoomChange` +3 |
| `$6E59` | `ThroneAttributesCell` (`ShadowAttributes`+345) | 57 | row 9, column 25: where the seated figure's colours (ThroneAttributes) go, 5 x 10 cells | `ClearShadowAttributes`, `FadeInStep`, `ShowShadowAttributes`, `StopRoomEffects`, `UpdateAttributes` +1 | `ClearShadowAttributes`, `ColourActor`, `ColourSprite`, `FillShadowAttributes`, `RoomChange` +4 |
| `$6E92` | `DragonAttributesCell` (`ShadowAttributes`+402) | 366 | row 9, column 18: where the dragon's colours (DragonAttributes) go, 9 x 9 cells | `ClearShadowAttributes`, `FadeInStep`, `ShowShadowAttributes`, `StopRoomEffects`, `UpdateAttributes` +1 | `ClearShadowAttributes`, `ColourActor`, `ColourSprite`, `ColourSpriteMirrored`, `DrawDragon` +6 |
| `$7000` | `HudPicture` | 64 of 1728 | The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their colours at `$7600` (6 rows of 32). DissolveHud `$8952` dissolves the 48 lines onto the screen's lines 0-47 and StageSetUp `$970D` copies the 192 colours into the shadow rows 0-5, once, at the stage's start. EndStage `$78B6` saves the screen's lines 0-47 back here (`$791B`) and the attributes `$5800-$58BF` to `$7600` (`$78CA`), so the next stage's block shows the HUD as the player left it. Between the two the bytes are the records labelled inside (RoomAttributes, Cells, HeroRecord, Actors, Missiles, DigitBuffer). The picture: the frame of the HUD, the energy bar's box, the score box, the item strip's box, the lives and pieces boxes. All 1728 bytes read and written in rzx-r3 and s3-right. | `AddMissileFrom`, `AddMissileHigh`, `AttrShadowAddress`, `AttrShadowAddressA`, `BogManActor` +134 | `AddMissileFrom`, `AddMissileHigh`, `BogManActor`, `BogManCheckSink`, `BogManRise` +78 |
| `$7040` | `RoomAttributes` (`HudPicture`+64) | 2 | `$7040-$727F`: the old room's play colours (SavePlayAttrs: 576 bytes, rows 6-23) and the cells' twins (`$7042` + row x 32 + column: PutBlock writes 0, UpdateAttributes reads the solid cells' colours); also the burst's particles (StartBurst `$A169`, 4 bytes each) | `AttrShadowAddressA`, `DissolveHud`, `DrawRainDrop`, `DrawRainShape`, `UpdateBurst` +1 | `CopyScreenToBlock`, `RainChance`, `StartBurst`, `StartRain`, `StopRoomEffects` +2 |
| `$7042` | `RoomAttributesCell` (`HudPicture`+66) | 574 | the twin of the cell `$7282` (576 bytes lower) | `AttrShadowAddressA`, `DissolveHud`, `DrawRainDrop`, `DrawRainShape`, `DrawRainSplash` +3 | `CopyScreenToBlock`, `PutBlock`, `RainChance`, `StartBurst`, `StartRain` +3 |
| `$7280` | `Cells` (`HudPicture`+640) | 2 | the room's cells: 19 rows of 32 (tile numbers, then their kinds after BuildSpans; bit 1 solid, bit 3 deadly) | `DissolveHud`, `StartGrid` | `CopyScreenToBlock`, `StartGrid` |
| `$7282` | `CellsPlay` (`HudPicture`+642) | 364 | row 0, column 2: the room's first cell (RoomCells writes 28 x 18) | `BuildSpans`, `CellAtRow`, `CellUnderFeet`, `DissolveHud`, `LightningStep` +3 | `BuildSpans`, `CopyScreenToBlock`, `PutBlock`, `StartGrid` |
| `$73EE` | `CellsDrawbridge` (`HudPicture`+1006) | 210 | row 11, column 14: the cells the drawbridge (kind 7, `$9369`) opens: written by it and by RoomChange, read by the hero's footing checks | `BuildSpans`, `CellAt`, `CellAtRow`, `CellAtSpan3`, `CellUnderFeet` +5 | `BuildSpans`, `CopyScreenToBlock`, `DrawbridgeActor`, `PutBlock`, `StartGrid` |
| `$74C0` | `CellsFloor` (`HudPicture`+1216) | 32 | row 18 below the room: 32 bytes of `$FF` (StartGrid `$A639`), a floor no actor falls through | `DissolveHud`, `StartGrid` | `CopyScreenToBlock`, `StartGrid` |
| `$74E0` | `HeroRecord` (`HudPicture`+1248) | 1 | the hero's actor record (18 bytes; +0 X) | `BogManActor`, `BufferAddressDE`, `CellUnderFeet`, `CheckGridPassages`, `CheckRoomExits` +34 | `CopyScreenToBlock`, `HeroDeath`, `SetActorFrame`, `ShiftRoomColumns`, `SpawnActor` |
| `$74E1` | `HeroY` (`HudPicture`+1249) | 2 | +1 the hero's line | `BogManActor`, `BufferAddressDE`, `CellUnderFeet`, `ClipActor`, `ColourActor` +16 | `CopyScreenToBlock`, `HeroDeath`, `SetActorFrame`, `SpawnActor` |
| `$74E3` | `HeroHeight` (`HudPicture`+1251) | 5 | +3 the hero's height in lines (`$16` at the stage's start, StageEntry) | `BufferAddressDE`, `CellUnderFeet`, `ClipActor`, `ColourActor`, `DissolveHud` +3 | `CopyScreenToBlock`, `PlaceHeroAtStart`, `SetActorFrame`, `SpawnActor`, `StageEntry` |
| `$74E8` | `HeroFrame` (`HudPicture`+1256) | 1 | +8 the frame number of the hero's set | `BufferAddressDE`, `CheckHeroFooting`, `ClipActor`, `ColourActor`, `DissolveHud` +13 | `CheckHeroFooting`, `CopyScreenToBlock`, `HeroFall`, `HeroFireHeld`, `HeroJump` +13 |
| `$74E9` | `HeroFlags` (`HudPicture`+1257) | 1 | +9 bit 7: facing left | `BufferAddressDE`, `CellUnderFeet`, `CheckSwampLeftEdge`, `ClipActor`, `ColourActor` +21 | `CopyScreenToBlock`, `HeroStand`, `HeroTurn`, `RespawnCountdown`, `SetActorFrame` +1 |
| `$74EA` | `HeroState` (`HudPicture`+1258) | 2 | +`$0A` 0 stand, 1 walk, 2 jump, 3 fall, ...; `$0F` dying (the hero's state handlers) | `BufferAddressDE`, `CheckGridPassages`, `CheckHeroFooting`, `CheckRoomExits`, `CheckStageExit` +16 | `CopyScreenToBlock`, `HeroDeath`, `HeroFall`, `HeroFireHeld`, `HeroJump` +14 |
| `$74EC` | `HeroAttribute` (`HudPicture`+1260) | 1 | +`$0C` the hero's attribute | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +4 | `CopyScreenToBlock`, `HeroColour`, `HeroDeath`, `SetActorFrame`, `SpawnActor` |
| `$74ED` | `HeroBaseX` (`HudPicture`+1261) | 1 | +`$0D` the base column (`$0D` at the stage's start) | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +8 | `CopyScreenToBlock`, `HeroDeath`, `HeroWalk`, `MoveBaseX`, `RespawnCountdown` +6 |
| `$74EE` | `HeroBaseY` (`HudPicture`+1262) | 2 | +`$0E` the base line | `BufferAddressDE`, `CheckWaterDeath`, `ClipActor`, `ColourActor`, `DissolveHud` +7 | `CopyScreenToBlock`, `HeroDeath`, `HeroFall`, `MoveActorY`, `RespawnCountdown` +2 |
| `$74F0` | `HeroCounter` (`HudPicture`+1264) | 2 | +`$10` the pause after a death (HeroDeath) | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +6 | `CopyScreenToBlock`, `HeroDeath`, `RespawnCountdown`, `SetActorFrame`, `SpawnActor` |
| `$74F2` | `Actors` (`HudPicture`+1266) | 1 | the 13 other actor records, 18 bytes each (`$74F2-$75DB`); +0 = `$FF` a free record | `BogManActor`, `BogManCheckGround`, `BogManCheckSink`, `BufferAddressDE`, `ClearActors` +27 | `ClearActors`, `CopyScreenToBlock`, `MoveFragment`, `RemoveActor`, `RemoveActorPair` +3 |
| `$74F3` | `ActorsY` (`HudPicture`+1267) | 215 | the first record's +1 | `BogManActor`, `BogManCheckGround`, `BogManCheckSink`, `BogManFrame`, `BogManRise` +57 | `BogManActor`, `BogManCheckSink`, `BogManRise`, `BogManSink`, `ClearActors` +31 |
| `$75CA` | `LastActor` (`HudPicture`+1482) | 18 | the 13th record | `BufferAddressDE`, `ClearActors`, `ClipActor`, `ColourActor`, `DissolveHud` +21 | `ClearActors`, `CopyScreenToBlock`, `LightningActor`, `LoadRoomActors`, `PyreFlameActor` +5 |
| `$75DC` | `ActorsEnd` (`HudPicture`+1500) | 4 | 4 bytes past the records: only the HUD picture's (DissolveHud, EndStage's save) bytes | `DissolveHud` | `CopyScreenToBlock` |
| `$75E0` | `Missiles` (`HudPicture`+1504) | 1 | the 16 missile records, 6 bytes each (`$75E0-$763F`): +0 the column (`$FF` free), +1 the line, +2 the kind, +3 to +5 the kind's own | `AddMissileFrom`, `AttrShadowAddressA`, `BufferAddressHL`, `ClearShots`, `DissolveHud` +3 | `AddMissileFrom`, `ClearShots`, `CopyScreenToBlock`, `RemoveActor`, `UpdateThroneShot` +1 |
| `$75E1` | `MissilesY` (`HudPicture`+1505) | 31 | the first record's +1 | `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL`, `ClearShots` +4 | `AddMissileFrom`, `ClearShots`, `CopyScreenToBlock`, `RemoveActor`, `UpdateThroneShot` +1 |
| `$7600` | `HudColours` (`HudPicture`+1536) | 16 | the HUD's 192 colours as loaded (rows 0-5); in play the missile records 4-15 lie over them | `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL`, `ClearShots` +4 | `AddMissileFrom`, `ClearShots`, `EndStageSave`, `RemoveActor`, `UpdateThroneShot` +1 |
| `$7610` | `MissilesHigh` (`HudPicture`+1552) | 1 | missile records 8-15 (the hero's death sparks) | `AddMissileFrom`, `AddMissileHigh`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL` +8 | `AddMissileFrom`, `AddMissileHigh`, `ClearShots`, `EndStageSave`, `HeroDeath` +4 |
| `$7611` | `MissilesHighY` (`HudPicture`+1553) | 47 | record 8's +1 | `AddMissileFrom`, `AddMissileHigh`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL` +8 | `AddMissileFrom`, `AddMissileHigh`, `ClearShots`, `EndStageSave`, `HeroDeath` +4 |
| `$7640` | `DigitBuffer` (`HudPicture`+1600) | 128 | in play: the score's digit picture (6 + 2 columns x 8 lines, RenderScore `$7B61`) and a sprite's shifted copy (PreShiftSprite `$7F43`) | `CopyToScreen`, `PlotRow5`, `PlotRow5Mirrored`, `ShiftLine1`, `ShiftLine4` +1 | `ClearShots`, `EndStageSave`, `PreShiftSprite`, `RenderDigits`, `ShiftLine1` +1 |
| `$76C0` | `Unused76C0` | 32 | 32 bytes between the HUD's colours and the span table that no code reads or writes (rzx-r3, s3-right); zero as loaded | - | - |
| `$76E0` | `SpanTable` | 288 | The open spans CopyBuffer copies, 6 bytes each (the length, 0, the buffer address, the screen address; SpanCount spans), on to `$77FF`. BuildSpans `$99B1` and AddSpan `$9A36` write the spans from here (stage 1 starts them at `$76A0`, over the HUD's colours; stage 3 keeps them clear of it); CopyBuffer `$9AA2` reads them. rzx-r3 writes `$76E0-$77A5` (33 spans), s3-right 26 spans; `$77A6-$77FF` (90 bytes) is never reached in the two recordings. Zero as loaded. | `BuildSpans` | `AddSpan`, `BuildSpans` |

### Stage 3 (TZX block 46): mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$78BD` | `EndPiecesBox` | 5 | FillAttributes' inline record: column 25, line 24, 6 x 2 cells, attribute 1 (the pieces boxes hidden). Read by FillAttributes `$8ADE` after the CALL at `$78BA`. Stage 1's EndPiecesBox at `$78A5` holds the same bytes. | `FillAttributes` | - |
| `$78C5` | `EndLivesBox` | 5 | FillAttributes' inline record: column 1, line 24, 6 x 2 cells, attribute 1 (the lives boxes hidden). Read by FillAttributes `$8ADE` after the CALL at `$78C2`. Stage 1's EndLivesBox at `$78AD` holds the same bytes. | `FillAttributes` | - |

### Stage 3 (TZX block 46): render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7F86` | `ShiftRoutines` | 16 | The shift routine for 1-7 pixels (entry 0 unused). Stage 1's ShiftRoutines at `$7F90` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `PreShiftSprite` | - |
| `$87CD` | `RowPlotters` | 32 | The row plotter of each sprite width: word 2 x width + 1 when mirrored. Read by the sprite drawer at `$A8C8` (LD BC,RowPlotters): index 2 x width + (facing left). Width 0 and the mirrored width 7 hold `$8629` (a hang loop: border flicker and KeyHook forever), never reached with a valid frame. Stage 1's RowPlotters at `$8910` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `DrawActorSprite` | - |
| `$A997` | `ItemInks` | 4 | CycleItemInk's four attributes. Stage 1's ItemInks at `$A799` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | - | - |
| `$B435` | `ColourCycle4` | 4 | ColourCyanCycle's four attributes: 5, `$44`, `$45`, 7. Read by ColourCyanCycle `$B427`. | `ColourCyanCycle` | - |
| `$B44A` | `GreenCycleColours` | 8 | SetGreenCycleColour's eight attributes: 4, 4, `$44`, 5, `$45`, `$45`, 5, `$44`. Read by SetGreenCycleColour `$B439` (all 8 in rzx-r3). | `SetGreenCycleColour` | - |
| `$B452` | `RedCycleColours` | 8 | Eight more attributes, the same cycle in red and magenta: no code reads them. 2, 2, `$42`, 3, `$43`, `$43`, 3, `$42`. No operand points here (SetGreenCycleColour adds only pass AND 7 to `$B44A`) and rw3.py `$B452` `$B45A` gives 0 reads. | - | - |
| `$B486` | `MissileColours` | 4 | bright red, bright magenta, bright red, magenta. Stage 1's MissileColours at `$B3B9` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `MissileColour` | - |
| `$B498` | `RedCycle4` | 4 | ColourRedCycle's four attributes: `$42`, `$43`, `$46`, 3; no recording read them (rw3.py: 0 reads) | - | - |
| `$B4B1` | `CycleColours` | 8 | the colour cycle. Stage 1's CycleColours at `$B3D2` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `CycleColour`, `FlashPieces` | - |
| `$B4B9` | `ImageDescriptors` | 16 | Four image descriptors: the image address, the width in bytes, the height in lines. `$EB20`, `$EB47`, `$EB6E` and `$EB95` (the four frames of DriftShotSprites), each 3 x 13. Read through HL from UpdatePathFlyer (`$84B3`). Stage 1's ImageDescriptors at `$B3EA` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `ColourSprite`, `UpdatePathFlyer` | - |

### Stage 3 (TZX block 46): util

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8A44` | `BlankIcon` | 32 | 32 zero bytes: the blank icon (item kind 4) and the source of every clear done by copying with stride 0. ItemIcons' kind 4 points here (DrawItemIcon `$7E07` reads all 32 bytes); CopyToScreen `$79BA` copies its first bytes with stride 0 to clear the play area (StageEntry), the HUD fields (EndStage) and the item strip (GameOverStep); the templates' frame word (`$9C76` and others) points here until SetActorFrame sets a frame. Stage 1's BlankIcon at `$8BA3` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `CopyToScreen`, `DrawActorSprite`, `DrawItemIcon`, `PlotRow1` | - |

### Stage 3 (TZX block 46): hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7AA8` | `StarPixels` | 32 | The two pixel lines of a star, by speed (rows 1-4) and pixel (pairs 0-3). Stage 1's StarPixels at `$7ABA` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `MoveStar` | - |
| `$7C0C` | `ScoreDigits` | 2 of 9 | The score as text: two unused bytes, ScoreHigh's two digits, Score's four digits, 0. Stage 1's ScoreDigits at `$7C1E` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `RenderDigits`, `ShowScore` | `ByteToDigits`, `NumberToDigits` |
| `$7C0E` | `ScoreDigitsHigh` (`ScoreDigits`+2) | 2 | as in stage 1 at `$7C20` (an operand of a matched routine) | `RenderDigits`, `ShowScore` | `ByteToDigits` |
| `$7C10` | `ScoreDigitsLow` (`ScoreDigits`+4) | 5 | as in stage 1 at `$7C22` (an operand of a matched routine) | `RenderDigits` | `NumberToDigits` |
| `$A392` | `BarMasks` | 8 | The left-aligned masks of 0-7 pixels for the bar's last byte. Stage 1's BarMasks at `$A41C` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `DrawEnergyBar` | - |

### Stage 3 (TZX block 46): hero

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7D04` | `WindowFrameColours` | 16 | The frame's 16 inks: 1 to 7 and back. Stage 1's WindowFrameColours at `$7D16` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `CycleWindowFrame` | - |
| `$7DB6` | `ItemCountText` | 5 | The count as text for RenderDigits: two unused bytes, two digits, 0. Stage 1's ItemCountText at `$7DC8` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `RenderDigits`, `ShowItemCount` | `FormatItemCount` |
| `$7EFC` | `CarriedItems` | 17 | The item kind of each of the 17 slots (slots 0-3 hold 4, the blank icon; the first item at slot 6). Filled from StartItems by InitStageState; AddItem `$7E4D` searches and extends it; DrawItemStrip and GetSelectedItem read it. Stage 1's CarriedItems at `$7F17` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `AddItem`, `DrawItemStrip`, `GetSelectedItem` | `AddItem`, `InitStageState` |
| `$7F0D` | `CarriedCounts` | 17 | The amount of each slot's item (shown by ShowItemCount; AddItem adds). Stage 1's CarriedCounts at `$7F23` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `AddItem`, `DrawItemStrip`, `FormatItemCount`, `ThrowAmmo`, `ThrowItem` +1 | `AddItem`, `ThrowAmmo`, `ThrowItem`, `UpdateRain` |
| `$7F1E` | `StartItems` | 17 | The kinds InitStageState copies into CarriedItems at the stage start. 4 4 4 4 0 0 3 0 ... 0: slots 0-3 the blank kind 4, slot 6 kind 3 (the first item, where ItemSelected starts). Read by InitStageState `$9D00` (LD HL,`$7F1E`: 17 bytes to CarriedItems). Stage 1's StartItems at `$7F2F` has 12 bytes. | `InitStageState` | - |
| `$7F2F` | `ItemIcons` | 20 | The 2 x 16 icon of each item kind 0-9 (10 words into ItemIconSprites `$EA00`; kind 4 points to BlankIcon `$8A44`). `$EAC0`, `$EB00`, `$EA00`, `$EA60`, `$8A44`, `$EAA0`, `$EA20`, `$EA80`, `$EAE0`, `$EA40`. Read by DrawItemIcon `$7E07` (the HUD strip). Stage 1's ItemIcons at `$7F3B` has 9 words. | `DrawItemIcon` | - |
| `$8609` | `RecoilSteps` | 7 | The hop's y change at steps 0-6. Stage 1's RecoilSteps at `$874C` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | - | - |
| `$961E` | `RespawnPoints` | 8 of 32 | Column, line of each room: grid 0 (18 rooms), grid 1 (3) at `$92C1`, grid 2 (1) at `$92C7`. Stage 1's RespawnPoints at `$929D` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `RespawnPoint` | - |
| `$9626` | `RespawnPointsGrid1` (`RespawnPoints`+8) | 22 | as in stage 1 at `$92C1` (an operand of a matched routine) | - | - |
| `$963C` | `RespawnPointsGrid2` (`RespawnPoints`+30) | 2 | as in stage 1 at `$92C7` (an operand of a matched routine) | - | - |
| `$AF1F` | `HeroStandSet` | 4 | SetActorFrame's words after HeroStandFrame's CALL: the walk frame table `$E8AA`, its graphics `$E620`. Read by SetActorFrame `$AC0A`. Frame `$0C` of the set is the standing hero. | `SetActorFrame` | - |
| `$AF99` | `HeroStrikeSet` | 4 | SetActorFrame's words: the strike frame table `$E206`, its graphics `$E0E9`. Read by SetActorFrame `$AC0A` after the CALL at `$AF96`. | `SetActorFrame` | - |
| `$AF9D` | `HeroStrikeFrames` | 7 | the strike set's frame for each pair of passes: 0, 1, 2, 3, 2, 1, 0. Read by HeroStrike `$AF61` (all 7 bytes in rzx-r3). | `HeroStrike`, `SetActorFrame` | - |
| `$B06B` | `HeroWalkSet` | 4 | SetActorFrame's words: the walk frame table `$E8AA` (`$0D` frames; `$0C` stands), its graphics `$E620`. Read by SetActorFrame `$AC0A` after the CALL at `$B068`. | `SetActorFrame` | - |
| `$B143` | `HeroJumpSet` | 4 | SetActorFrame's words: the jump frame table `$E5AE` (19 frames; `$10`-`$12` also the fall), its graphics `$E224`. Read by SetActorFrame `$AC0A` after JumpFrame's CALL at `$B140`. | `SetActorFrame` | - |
| `$B180` | `HeroLeapSet` | 4 | SetActorFrame's words: the leap frame table `$EE65` (14 frames), its graphics `$EBBC`. Read by SetActorFrame `$AC0A` after LeapFrame's CALL at `$B17D`. | `SetActorFrame` | - |
| `$B19A` | `TurnSteps` | 12 | the base-column move of a turn at each walk frame. Stage 1's TurnSteps at `$B106` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `HeroTurn` | - |

### Stage 3 (TZX block 46): missiles

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$805E` | `ThrownAmmoFrames` | 36 | UpdateThrownAmmo's 9 frame records: the graphics address, 1 byte wide, 4 lines. Indexed by +4 - 1 (8 down to 0): records 0-3 are `$D30C`, `$D308`, `$D304`, `$D300`, records 4-8 all `$D300`. Read by UpdateThrownAmmo at `$8025` (all 36 bytes read in rzx-r3). | `ColourSprite`, `DrawSprite`, `UpdateThrownAmmo` | - |
| `$80A4` | `ShotFrames` | 4 of 20 | Five frame records (graphics, width, lines); only the first, `$D2A4` 2 x 5, is read. `$D2A4` 2 x 5, `$D2AE` 1 x `$0F`, `$D2BD` 1 x `$0F`, `$D2CC` 2 x `$0D`, `$D2E6` 2 x `$0D`: the layout of stage 1's ShotFrames (`$813D`). DrawShotFrame (`$8088`) and UpdateBolt (`$826C`) read only the first record (BC = 0); records 1-4 are read by no code (rw3.py: 4 of the 20 bytes read; no operand points into `$80A8-$80B7`). | `ColourSprite`, `ColourSpriteMirrored`, `DrawSprite`, `DrawSpriteMirrored`, `UpdateBolt` +1 | - |
| `$80A8` | `ShotFramesUnused` (`ShotFrames`+4) | 16 | records 1-4: no code reads them (stage 1's aimed shot used them; stage 3 has no aimed shot) | - | - |
| `$8170` | `ThroneShotFrames` | 16 | The fireball's four frame records: `$D264`, `$D274`, `$D284`, `$D294`, each 2 bytes x 8 lines. Read by UpdateThroneShot at `$8160` (IX = `$8170` + 4 x the frame). | `ColourSprite`, `DrawSprite`, `UpdateThroneShot` | - |
| `$8180` | `ThroneShotPaths` | 55 of 159 | The four paths of the throne giant's fireball: line steps (signed), `$64` ends a path. Path 0 at `$8180`, path 1 ThroneShotPath1, path 2 ThroneShotPath2, path 3 ThroneShotPath3: each rises (-8 to -2 a pass) and falls faster and faster, the last step repeated at the `$64`. Read by UpdateThroneShot at `$813B` (138 of the 159 bytes read in rzx-r3). | `UpdateThroneShot` | - |
| `$81B7` | `ThroneShotPath1` (`ThroneShotPaths`+55) | 50 | path 1 | `UpdateThroneShot` | - |
| `$81E9` | `ThroneShotPath2` (`ThroneShotPaths`+105) | 31 | path 2 | `UpdateThroneShot` | - |
| `$8208` | `ThroneShotPath3` (`ThroneShotPaths`+136) | 23 | path 3 | `UpdateThroneShot` | - |
| `$84F0` | `PathSteps` | 118 | The flyer's path: dx (half columns), dy a step; `$64` `$64` ends. Stage 1's PathSteps at `$84EE` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `UpdatePathFlyer` | - |

### Stage 3 (TZX block 46): rooms

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9B37` | `Grid0` | 9 of 196 | Grid 0's record (stage 3: the longship): 47 x 9 blocks, the start window at block column 11, row 0, the room table Grid0Rooms, map offset 0, +8 = 6. A grid record, 9 bytes, as in stage 1: +0 the width and +1 the height in blocks, +2/+3 the start window's block column and row (where StartGrid `$A639` puts the window; the grid passages rewrite them), +4/+5 the room table, +6/+7 the grid's offset in the map section of the unpacked graphics, +8 the rooms a grid row of rooms (only the moves up and down read it; every stage-3 grid is one row of rooms, 9 blocks high, so +1 and +8 are read by no recording: grid 0's +8 = 6 does not match its 4 rooms and is never used). A room is a window of 14 x 9 blocks; the windows step 11 block columns, so neighbouring rooms share 3 columns of blocks. RoomGrid (`$FE23`) points at the record of the hero's grid (StageEntry sets `$9B37`); RoomCells reads +0, +6/+7. The room table, one byte a room: the exits, bit 0 right, bit 1 left, bit 2 up, bit 3 down. Grid 0: 4 rooms (1, 3, 3, 2: the deck from the stern to the prow); grid 1: 11 rooms (the swamp and the forest, right to the castle); grid 2: 1 room with no exit (the castle hall). Read in rzx-r3 and s3-right (StageEntry, RoomCells, StartGrid, the edge checks); grid 1's start column `$9B46` is written once in rzx-r3 (the passage from grid 0). rooms.txt holds the three records, their room tables and the placement lists; tools/fig_rooms.py draws the map and every room from it (docs/img/maps/stage3*.png). LoadRoomActors `$A6CA` puts each placement not done that lies in the room's window into a free actor record, with the kind's row of ActorKinds; bit 7 of the kind is set when the actor is beaten or taken, so it does not come back (48 placement bytes written in each recording). Grid 0: four of kind `$0C` (at X 16, 56, 96, 144, line 0: the lightning) and ten of kind 4 (the sea at the foot of the hull, Y 15). Grid 1: 34 placements: kinds 0-3 (urns and chests, 11), kind 4 (the water of the swamp, 15), kind 5 (Y 6), 6 (Y 8), 7 (the drawbridge, X 234), 8 and 9 (two each, X 120-131: the dragon's room), `$0A` and `$0B` (X 124). Grid 2: none. Read in rzx-r3 (140 of the 153 bytes) and s3-right (72). | `CheckRoomExits`, `ClearTakenFlags`, `HeroActor`, `LoadRoomActors`, `MarkPlacementDone` +3 | `CheckGridPassages`, `ClearTakenFlags`, `MarkPlacementDone`, `ReviveAllPlacements` |
| `$9B40` | `Grid0Rooms` (`Grid0`+9) | 4 | 4 rooms: the exits of each | `CheckRoomExits` | - |
| `$9B44` | `Grid1` (`Grid0`+13) | 9 | Grid 1 (stage 3: the swamp, the forest and the castle's wall): 124 x 9 blocks, start column 22, row 0, map offset `$01A7`, 11 rooms a row | `HeroActor`, `RoomCells`, `StartGrid` | `CheckGridPassages` |
| `$9B4D` | `Grid1Rooms` (`Grid0`+22) | 11 | 11 rooms | `CheckRoomExits` | - |
| `$9B58` | `Grid2` (`Grid0`+33) | 9 | Grid 2 (stage 3: the castle hall): 14 x 9 blocks, start 0, 0, map offset `$0603`, one room | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9B61` | `Grid2Rooms` (`Grid0`+42) | 1 | one room, no exit | `CheckRoomExits` | - |
| `$9B62` | `Grid0Placements` (`Grid0`+43) | 45 | grid 0's 14 placements: the kind (bit 7: done), X and Y in cells over the whole grid; `$FF` `$FF` `$FF` ends | `ClearTakenFlags`, `LoadRoomActors`, `ReviveAllPlacements` | `ClearTakenFlags`, `ReviveAllPlacements` |
| `$9B8F` | `Grid1Placements` (`Grid0`+88) | 105 | grid 1's 34 | `ClearTakenFlags`, `LoadRoomActors`, `MarkPlacementDone` | `ClearTakenFlags`, `MarkPlacementDone` |
| `$9BF8` | `Grid2Placements` (`Grid0`+193) | 3 | grid 2's: the end mark only | `ClearTakenFlags`, `LoadRoomActors` | - |
| `$9F7E` | `RoomEventsLeftover` | 1 | A RET no code reaches. Byte `$C9` after RoomEvents' last JP; no jump lands on it and no recording read it (rw3.py `$9F7E`: 0 reads). | - | - |
| `$A568` | `RainDropShapes` | 16 | The four slanted drop streaks (4 lines each), by the drop's pixel column. Read by DrawRainDrop `$A50A` through DrawRainShape (all 16 bytes, 59 295 drops in rzx-r3). | `DrawRainShape` | - |
| `$A578` | `RainSplashShapes` | 16 | The four splash steps (4 lines each): a drop's bounce spreading out. Read by DrawRainSplash `$A557` through DrawRainShape (all 16 bytes). | `DrawRainShape` | - |
| `$A5CD` | `LightningColours` | 5 | The sky's attribute at each LightningState 0-4: paper blue, cyan, white, cyan, blue (ink black). Read by LightningStep `$A588`. | `LightningStep` | - |

### Stage 3 (TZX block 46): enemies

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$82FA` | `PieceActorSet` | 4 | SetActorFrame's words after the CALL at `$82F7`: the frame table `$DFB3`, the graphics base `$DECB`. Read by SetActorFrame `$AC0A` each time the piece is drawn. | `SetActorFrame` | - |
| `$8333` | `RiseSteps` | 30 | The rising piece's y change at each step 0-29. Stage 1's RiseSteps at `$82AE` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `UpdatePieceActor` | - |
| `$8DCE` | `VikingBlockFrames` | 8 | The block's frames by step 0-7: 0, `$0D`, `$0D`, `$0E`, `$0D`, `$0D`, 0, 0. Read by VikingBlock at `$8DC7` (no read in the recordings: rw3.py). | - | - |
| `$8DFB` | `VikingStrikeFrames` | 15 | The swing's frames by step 0-14: 7 7 8 8 9 9 `$0A` `$0A` `$0B` `$0B` `$0C` `$0C` 0 0 0. Read by VikingStrike at `$8DF4` (all 15 bytes read in rzx-r3). | `VikingActor` | - |
| `$8E52` | `VikingHitFrames` | 4 | The stagger's frames: `$0F` four times. Read by VikingHit at `$8E4B`. | `VikingActor` | - |
| `$8EA0` | `VikingFrameSet` | 4 | SetActorFrame's inline words: the frame table `$D7F5`, the graphics base `$D368`. Read by SetActorFrame `$AC0A` after the CALL at `$8E9D`. | `SetActorFrame` | - |
| `$8F13` | `VikingTemplateLeft` | 18 | SpawnActor's template: a Viking facing left (handler VikingActor), spawned at the right edge. 18 bytes as an actor record: +2/+3 1 x 8, +4/+5 BlankIcon, +6/+7 VikingActor, +9 `$80` (facing left), +`$0C` 7 (white), +`$0F` `$23` (bits 0 shootable, 1, 5 a body), +`$11` `$80`. Read by SpawnActor `$A6AF` (SpawnVikingRight). | `SpawnActor` | - |
| `$8F25` | `VikingTemplateRight` | 18 | SpawnActor's template: a Viking facing right, spawned at the left edge. As VikingTemplateLeft with +9 = 0. Read by SpawnActor (SpawnVikingLeft). | `SpawnActor` | - |
| `$8F85` | `SwampSpawnRet` | 1 | A RET no code reaches (after the JP at `$8F82`). No jump, call or word points to `$8F85` (a scan of the skool's operands); not executed in any recording (rzx-r3, s3-right). | - | - |
| `$8F86` | `SwampSpawnRooms` | 8 of 11 | Per grid-1 room 0-10: 1 the room has bog men, 0 trolls. 0 1 0 1 0 0 1 0 1 0 1. Read by SwampSpawnTimer at `$8F4A` for rooms 0-7 (rw3.py: 7 bytes read; room 5 returns before); the bytes of rooms 8-10 no code reads (the CP `$08` at `$8F3A` returns first). | `SwampSpawnTimer` | - |
| `$8F8E` | `SwampSpawnRoomsUnread` (`SwampSpawnRooms`+8) | 3 | rooms 8-10: no code reads them | - | - |
| `$90B5` | `TrollFrameSet` | 4 | SetActorFrame's inline words: the frame table `$D23A`, the graphics base `$D0B6`. Read by SetActorFrame `$AC0A` after the CALL at `$90B2`. | `SetActorFrame` | - |
| `$9113` | `TrollSwingFrames` | 10 | The swing's frames by +`$0B` 9-0: 4 4 5 5 6 6 6 6 5 5 (read backwards). Read by TrollBodyActor at `$9102`; no swing ran in the recordings (rw3.py: no read). | - | - |
| `$920B` | `BogManFrameSet` | 4 | SetActorFrame's inline words: the frame table `$DE53`, the graphics base `$D861`. Read by SetActorFrame `$AC0A` after the CALL at `$9208`. | `SetActorFrame` | - |
| `$9238` | `BogManRiseSteps` | 12 | The rise's line changes by +`$0B` 0-11: -5 -4 -4 -3 -3 -2 -2 -1 -1 -1 0 1. Read by BogManRise at `$922A` (steps 1-11; all 12 bytes read in rzx-r3). | `BogManRise`, `SetActorFrame` | - |
| `$9312` | `DragonHeadSet` | 4 | SetActorFrame's inline words: the frame table `$CCC1`, the graphics base `$CB10`. Read by SetActorFrame `$AC0A` after the CALL at `$930F`. | `SetActorFrame` | - |
| `$9316` | `DragonHeadFrames` | 19 | The head's frame by breath step 0-`$12`: 1 1 2 2 3 x 9 2 2 1 1 0 0 (the jaws open and close). Read by DragonHeadActor at `$9308`. | `DragonHeadActor`, `SetActorFrame` | - |
| `$9365` | `DragonFlameSet` | 4 | SetActorFrame's inline words: the frame table `$D08C`, the graphics base `$CCD9`. Read by SetActorFrame `$AC0A` after the CALL at `$9362`. | `SetActorFrame` | - |
| `$93C4` | `DrawbridgeSet` | 4 | SetActorFrame's inline words: the frame table `$C73C`, the graphics base `$C5D0`. Read by SetActorFrame `$AC0A` after the CALL at `$93C1`. | `SetActorFrame` | - |
| `$941C` | `PyreFlameSet` | 4 | SetActorFrame's words after the CALL at `$9419`: the frame table `$C7F0`, the graphics base PyreFlameSprites `$C754`. Read by SetActorFrame `$AC0A` each time a pyre flame is drawn (458 times in rzx-r3). | `SetActorFrame` | - |
| `$944C` | `PyreBierSet` | 4 | SetActorFrame's words after the CALL at `$9449`: the frame table `$C909`, the graphics base `$C814`. Frame 0 the bier (5 x 15), frames 1-3 the body lying (5 x 11, 5 x 11, 5 x 12). Read by SetActorFrame `$AC0A` (the return address it pops). | `SetActorFrame` | - |
| `$94A8` | `PyreBodySet` | 4 | SetActorFrame's words after the CALL at `$94A5`: the same frame table `$C909` and base `$C814` as PyreBierSet. Read by SetActorFrame `$AC0A`. | `SetActorFrame` | - |
| `$9500` | `LightningFrames` | 20 | LightningActor's five shapes: the image address, the width in bytes, the height in lines. Indexed by LightningState x 4. Read by LightningActor `$94AC` (all 20 bytes in rzx-r3). | `LightningActor` | - |
| `$AA02` | `StrikeableActorSet` | 4 | SetActorFrame's words: the frame table `$E0B9`, the graphics base `$DFEF`. Read by SetActorFrame `$AC0A` after the CALL at `$A9FF`. | `SetActorFrame` | - |
| `$ABD2` | `FragmentArc0` | 28 of 56 | The line change of each step of a fragment's arc 0 (28 signed bytes). Read by FragmentActor `$AA94` (+`$0B` the step): up 8, 6, 4, 2, 1 lines, then down 1, 2, 4, 6, 8, a short second hop and the rest. rw3.py: 48 of the 56 bytes of both arcs read in rzx-r3. | `FragmentActor` | - |
| `$ABEE` | `FragmentArc1` (`FragmentArc0`+28) | 28 | the arcs 1-3 (doubled for 2 and 3): a lower hop | `FragmentActor` | - |

### Stage 3 (TZX block 46): actors

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9BFB` | `ActorKinds` | 117 | The 13 placement kinds, 9 bytes each: the Y offset, the handler, 5 bytes for the record's +8 to +`$0C`, the record's +`$0F`. LoadRoomActors `$A6CA` builds an actor from a placement with its kind's row, as in stage 1: +1 Y = the placement's Y x 8 + the offset, +6/+7 the handler, +8 to +`$0C` (the counter, the flags, the state, the item, the attribute), +`$0F`. Stage 3's kinds: 0-3 the urns and chests (StrikeableActor `$A9C2`, frames 6, 4, 2, 0 of StrikeableSprites, the item 1 / 1 / 1 / 1 inside), 4 the water (`$928E`: WaterRipple frames), 5 the dragon's head (DragonHeadActor `$92BF`), 6 its flame (DragonFlameActor `$9329`), 7 the drawbridge (DrawbridgeActor `$9369`), 8 and 9 the pyre's flames (PyreFlameActor `$93C8`, the Y offset 0 and 3), `$0A` the pyre's bier (PyreBierActor `$9420`), `$0B` the body on it (PyreBodyActor `$945E`), `$0C` the lightning (LightningActor `$94AC`). Read in rzx-r3 (all 117 bytes) and s3-right (18: kinds 4 and `$0C`). | `LoadRoomActors` | - |
| `$9C70` | `ActorTemplates` | 18 of 144 | Eight whole actor records (18 bytes each, the first the hero's: handler HeroActor `$AC46`) that SpawnActor copies for the actors no placement makes. The handler at +6/+7 and the frame at +4/+5 as for a placed actor; the rest as an actor record (HeroRecord `$74E0`). The frame word of all but the item is BlankIcon `$8A44` until SetActorFrame sets a frame. Read in rzx-r3 (all eight) and s3-right (the hero and the piece). | `SpawnActor` | - |
| `$9C82` | `ItemTemplate` (`ActorTemplates`+18) | 18 | an item lying on the floor: 2 x 16, the frame `$EA20`, handler `$A108` | `SpawnActor` | - |
| `$9C94` | `PieceTemplate` (`ActorTemplates`+36) | 18 | a piece of the stage's artefact (handler `$82B9`) | `SpawnActor` | - |
| `$9CA6` | `FragmentTemplate` (`ActorTemplates`+54) | 18 | a fragment of a broken urn (3 x 11, handler `$AA94`) | `SpawnActor` | - |
| `$9CB8` | `BogManTemplate` (`ActorTemplates`+72) | 18 | a bog man (handler BogManActor `$91AD`), facing right (SpawnBogMan, columns 16 and up) | `SpawnActor` | - |
| `$9CCA` | `BogManLeftTemplate` (`ActorTemplates`+90) | 18 | the same, facing left (+9 bit 7; SpawnBogMan, columns under 16) | `SpawnActor` | - |
| `$9CDC` | `TrollLegsTemplate` (`ActorTemplates`+108) | 18 | a troll's legs (handler TrollLegsActor `$9003`): +`$0B` = 4 hits, +`$0C` = 3 (magenta) | `SpawnActor` | - |
| `$9CEE` | `TrollBodyTemplate` (`ActorTemplates`+126) | 18 | a troll's body with the club (handler TrollBodyActor `$90C6`), +`$0C` = 3 (magenta) | `SpawnActor` | - |
| `$A308` | `BurstLeftover` | 1 | A RET after UpdateBurst's closing JP `$A23F`: no code reaches or reads it. rw3.py `$A308`: 0 reads, 0 writes; no jump in the image targets `$A308`. | - | - |
| `$A30F` | `ParticleInks` | 4 | The burst's four particle attributes, written by StartBurst. ink C, bright ink C, ink B, bright ink B; the particle's byte 3 (0-3) picks one. As loaded: 2, `$42`, `$43`, 3. Stage 1's ParticleInks at `$A399` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `UpdateBurst` | `StartBurst` |
| `$A313` | `BurstSteps` | 40 | 20 (dx, dy) steps: 10 for the left-byte particles, 10 for the right-byte ones. Read by UpdateBurst through BurstDirections' indices. Stage 1's BurstSteps at `$A39D` (found through the operands of the matched routines) has the same layout. | `UpdateBurst` | - |
| `$B3B8` | `MissileHandlers` | 20 | The handler of each missile kind 0-9. 10 words, kinds 0-9: 0, 1 and 6 HangFlashBorder `$8629` (no stage-3 code adds these kinds), 2 and 3 UpdateThrownAmmo `$7FF5` (the thrown objects, left and right), 4 UpdateThroneShot `$80F0` (the giant's shots), 5 UpdateBolt `$821F` (the hero's bolt), 7 and 8 UpdatePathFlyer `$842E`, 9 UpdateHeroShot `$80B8`. Read by UpdateMissiles (LD HL at `$B39E`). Stage 1's MissileHandlers at `$B31A` (found through the operands of the matched routines); the size and shape given here are stage 3's, from its bytes and readers. | `UpdateMissiles` | - |

### Stage 3 (TZX block 46): graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B556` | `StageGraphics` | 3231 | The stage's tiles, blocks and map, RLE-packed (3231 bytes; 4437 unpacked: 229 tiles, 118 blocks, the three grids' map). RoomChange unpacks it with Unrle `$A39A` into the play buffer at `$5B00` at every room change (the buffer is cleared again before the actors are drawn). Unrle: the first byte is the escape (`$F9` here); a byte other than the escape is itself, ESC n v is n copies of v, ESC ESC ends. Unpacked: five words, the offsets from `$5B0A` of the tile kinds (0), the tiles' pixels (`$E5`: 229 x 8 bytes), their attributes (`$080D`), the blocks (`$08F2`: 118 x 4 tile numbers) and the map (`$0ACA`: grid 0 47 x 9, grid 1 124 x 9, grid 2 14 x 9 block numbers, at the grid records' map offsets 0, `$01A7`, `$0603`). The packer that made it is greedy: every run of 4 to 255 equal bytes is ESC n v, except one stretch of 8 zero bytes left as they are (unpacked offset 1663: a blank tile's pixels). With that one exception tools/res_stage.py packs the block again bit for bit (graphics.txt, tiles.png). All 3231 bytes read in rzx-r3 and s3-right (each room change). | `Unrle` | - |
| `$C1F5` | `LightningBolt1` | 48 | The shortest lightning bolt: 2 bytes x 24 lines. The four bolts are drawn by the lightning (kind `$0C`) through LightningShapes `$9500` (the bitmap, the width, the height of each, and a blank 1 x 1 for no bolt). All four read in rzx-r3 and s3-right (the deck of the longship). | `DrawActorSprite` | - |
| `$C225` | `LightningBolt2` | 96 | A lightning bolt: 2 bytes x 48 lines | `DrawActorSprite` | - |
| `$C285` | `LightningBolt3` | 144 | A lightning bolt: 2 bytes x 72 lines | `DrawActorSprite` | - |
| `$C315` | `LightningBolt4` | 312 | The longest lightning bolt: 3 bytes x 104 lines | `DrawActorSprite` | - |
| `$C44D` | `ThronePicture` | 335 | The seated figure of the castle hall (grid 2): a row-packed picture of 79 lines (each a byte LEN x 16 + SKIP, then LEN bytes), drawn at buffer line `$F8` of character row 3 (`$5F18`). The grid-2 picture code (`$9514`, called every pass from MainLoop) draws it with DrawRowPicture `$89A4` while the figure stands (the hits counter `$FE65` under `$1E`), then paints its colours ThroneAttributes. Read in rzx-r3 (all 335 bytes; s3-right never reaches the castle). | `DrawRowPicture` | - |
| `$C59C` | `ThronePictureEnd` | 2 | 2 bytes past the picture's 79th line that no code reads (DrawRowPicture draws 79 lines; read in neither recording) | - | - |
| `$C59E` | `ThroneAttributes` | 50 | The seated figure's colours: 10 rows of 5 attributes (`$FF`: leave the cell), copied into the shadow at `$6E59`. The grid-2 picture code (`$9537`) copies them, or paints `$42` (bright red) where not `$FF` for one pass after a hit (`$9567`, `$FE66`). Read in rzx-r3 (all 50 bytes). | `ThroneBossStep` | - |
| `$C5D0` | `DrawbridgeSprites` | 364 of 388 | The castle's drawbridge: 4 frames, from raised (1 x 31) to lowered (4 x 30). The drawbridge (kind 7, `$9369`) shows the frames as it falls. Read in rzx-r3 (all 388 bytes). | `PlotRow1`, `PlotRow3`, `PlotRow4`, `SetActorFrame` | - |
| `$C73C` | `DrawbridgeFrameTable` (`DrawbridgeSprites`+364) | 24 | 4 records | `SetActorFrame` | - |
| `$C754` | `PyreFlameSprites` | 156 of 192 | The funeral pyre's flames: 6 frames of 2 bytes x 12-14 lines. Read in rzx-r3 (all 192 bytes) through the SetActorFrame call at `$9419` (kinds 8 and 9, PyreFlameActor `$93C8`; PyreFlameSet `$941C`). | `DrawActorSprite`, `SetActorFrame` | - |
| `$C7F0` | `PyreFlameFrameTable` (`PyreFlameSprites`+156) | 36 | 6 records | `DrawActorSprite`, `SetActorFrame` | - |
| `$C814` | `BierSprites` | 245 of 269 | 4 frames of 5 bytes x 11-15 lines: the pyre's bier (frame 0) and the body on it (frames 1-3). SetActorFrame calls at `$9449` (PyreBierActor `$9420`) and `$94A5` (PyreBodyActor `$945E`). Read in rzx-r3 (all 269 bytes). | `DrawActorSprite`, `SetActorFrame` | - |
| `$C909` | `BierFrameTable` (`BierSprites`+245) | 24 | 4 records | `SetActorFrame` | - |
| `$C921` | `DragonPicture` | 408 | The dragon (grid 1, room 8): a row-packed picture of 69 lines, drawn at buffer address `$6192` (character row 6, line 4, column 18). The dragon's picture code (`$8880`, every pass in room 8) draws it with DrawRowPicture `$89A4` while the dragon lives (the hits counter `$FE4D` under `$0F`), then paints its colours DragonAttributes. Read in rzx-r3 (all 408 bytes). | `DrawRowPicture` | - |
| `$CAB9` | `DragonPictureEnd` | 6 | 6 bytes past the picture's 69th line that no code reads (read in neither recording) | - | - |
| `$CABF` | `DragonAttributes` | 81 | The dragon's colours: 9 rows of 9 attributes (`$FF`: leave the cell), copied into the shadow at `$6E92`. The dragon's picture code (`$88A3`) copies them, or (`$88D2`) paints them red for one pass after a hit (`$FE4E`). Read in rzx-r3 (all 81 bytes). | `DrawDragon` | - |
| `$CB10` | `DragonHeadSprites` | 432 | The dragon's head: 4 frames of 4 bytes x 27 lines, the jaws from shut to wide open. SetActorFrame call at `$930F` (kind 5, DragonHeadActor `$92BF`; DragonHeadSet `$9312`) with the frame table DragonHeadFrameTable. The frames are one after another; the byte after them (`$CCC0`) is a stray, so the table is not right after them and the set is kept as bitmaps and a table. Read in rzx-r3 (all 432 bytes). | `PlotRow4` | - |
| `$CCC0` | `DragonHeadStray` | 1 | One zero byte between the head's frames and its table that no frame covers and no code reads (read in neither recording) | - | - |
| `$CCC1` | `DragonHeadFrameTable` | 24 | The dragon head's 4 frame records (dx, dy, width, height, offset from DragonHeadSprites). Read in rzx-r3 (all 24 bytes). | `SetActorFrame` | - |
| `$CCD9` | `BreathSprites` | 947 of 989 | The dragon's breath: 7 frames of a cloud of fire, from a puff (3 x 16) to the full cloud (6 x 44) and its last sparks. SetActorFrame call at `$9362` (kind 6, DragonFlameActor `$9329`; DragonFlameSet `$9365`). Read in rzx-r3 (all 989 bytes). | `PlotRow3`, `PlotRow4`, `PlotRow5`, `PlotRow6`, `SetActorFrame` | - |
| `$D08C` | `BreathFrameTable` (`BreathSprites`+947) | 42 | 7 records | `SetActorFrame` | - |
| `$D0B6` | `TrollSprites` | 388 of 430 | The troll: 7 frames, its legs walking (frames 0-3, 2 x 10-11) and its body with the club (4 club down, 5 and 6 the swing). SetActorFrame call at `$90B2` (TrollFrame `$90AF`, for TrollLegsActor `$9003` and TrollBodyActor `$90C6`; TrollFrameSet `$90B5`). Read in rzx-r3 (198 of 430 bytes: the small frames). | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow4`, `PlotRow4Mirrored`, `PreShiftSprite` +1 | - |
| `$D23A` | `TrollFrameTable` (`TrollSprites`+388) | 42 | 7 records | `SetActorFrame` | - |
| `$D264` | `FireballSprites` | 64 | The throne giant's fireball: four frames of 2 bytes x 8 lines (ThroneShotFrames `$8170`). Read by UpdateThroneShot (`$8160`) in rzx-r3 (all 64 bytes). | `DrawSprite` | - |
| `$D2A4` | `ShotSmall` | 10 | A shot: 2 bytes x 5 lines (the shot frames table `$80A4`'s first record). The shots' pictures, table `$80A4`: this one, two of 1 x 15 and two of 2 x 13, by direction. rzx-r3 reads only this one (10 bytes); the other four are known only from the code (`$80A4`). | `DrawSprite`, `DrawSpriteMirrored` | - |
| `$D2AE` | `ShotUpright` | 30 | Two shots of 1 byte x 15 lines (the ones flying up and down) | - | - |
| `$D2CC` | `ShotSlanted` | 52 | Two shots of 2 bytes x 13 lines (the slanted ones) | - | - |
| `$D300` | `ThrownAmmoSprites` | 16 | The thrown object: four frames of 1 byte x 4 lines, smallest last (ThrownAmmoFrames `$805E`: 9 records, frames 3, 2, 1, 0, then 0). Read by UpdateThrownAmmo (`$8025`) in rzx-r3 (all 16 bytes). | `DrawSprite` | - |
| `$D310` | `WaterRipple` | 16 | The water's surface (kind 4): 16 bytes, 4 bytes a line; a frame is 4 x 2 lines from `$D310`, `$D314` or `$D318` (3 frames 4 bytes apart, overlapping). `$928E` steps the frame 0-2 every second pass and points +4/+5 at `$D310` + 4 x the frame. Read in rzx-r3 and s3-right (all 16 bytes). | `DrawActorSprite` | - |
| `$D320` | `WaterRippleEnd` | 8 | 8 bytes past the ripple's frames that no code reads (the last frame ends at `$D31F`; read in neither recording) | - | - |
| `$D328` | `GameOverPicture` | 64 | GAME OVER: 8 bytes x 8 lines, drawn in the HUD's item strip (GameOverStep `$83F2`). Read in s3-right (all 64 bytes: its game over); rzx-r3 has none. | `CopyToScreen` | - |
| `$D368` | `VikingSprites` | 1165 of 1273 | The Viking warrior (a horned helmet, a round shield and an axe): 18 frames (stand, walk, block, strike, hit, death). SetActorFrame call at `$8E9D` (VikingFrame `$8E9A`, VikingFrameSet `$8EA0`) for VikingActor `$8C64`. Read in rzx-r3 (1129 of 1273 bytes) and s3-right (992). | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored`, `PlotRow4` +4 | - |
| `$D7F5` | `VikingFrameTable` (`VikingSprites`+1165) | 108 | 18 records | `SetActorFrame` | - |
| `$D861` | `BogManSprites` | 1522 of 1642 | The bog man: 20 frames, rising out of the swamp, wading and sinking flat. SetActorFrame call at `$9208` (BogManFrame `$9203`, BogManFrameSet `$920B`) for BogManActor `$91AD`. Read in rzx-r3 (all 1642 bytes). | `PlotRow3`, `PlotRow3Mirrored`, `PlotRow4`, `PlotRow4Mirrored`, `PlotRow5` +2 | - |
| `$DE53` | `BogManFrameTable` (`BogManSprites`+1522) | 120 | 20 records | `PlotRow3`, `SetActorFrame` | - |
| `$DECB` | `PieceSprites` | 28 of 292 | A piece of the stage's artefact: 10 frames; the first two (2 x 14) are also the HUD's piece pictures. ShowPieceTaken copies `$DECB` (the first piece) or `$DEE7` (the others) to the HUD. Read in rzx-r3 (286 of 292 bytes) and s3-right (258). | `CopyToScreen`, `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$DEE7` | `PieceSprite1` (`PieceSprites`+28) | 204 | the second frame, the HUD's picture of a later piece | `CopyToScreen`, `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$DFB3` | `PieceFrameTable` (`PieceSprites`+232) | 60 | 10 records | `PlotRow3`, `SetActorFrame` | - |
| `$DFEF` | `StrikeableSprites` | 202 of 250 | The urns and chests: 8 frames, two of each (whole, cracked) for the kinds 0-3 (StrikeableActor `$A9C2`). Read in rzx-r3 (all 250 bytes). | `DrawActorSprite`, `PlotRow3`, `SetActorFrame` | - |
| `$E0B9` | `StrikeableFrameTable` (`StrikeableSprites`+202) | 48 | 8 records | `PlotRow3`, `SetActorFrame` | - |
| `$E0E9` | `HeroStrikeSprites` | 285 of 309 | The hero's strikes with a hammer: 4 frames. Read in rzx-r3 and s3-right (all 309 bytes). | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored`, `PlotRow4` +2 | - |
| `$E206` | `HeroStrikeFrameTable` (`HeroStrikeSprites`+285) | 24 | 4 records | `PlotRow3`, `SetActorFrame` | - |
| `$E21E` | `EnergyBarPattern` | 6 | The energy bar's pattern: 6 bytes, one pixel line (DrawEnergyBar draws Energy / 8 of them on 6 lines). Read in rzx-r3 and s3-right. | `DrawEnergyBar`, `PlotRow3` | - |
| `$E224` | `HeroJumpSprites` | 906 of 1020 | The hero's jump: 19 frames. Read in rzx-r3 and s3-right (all 1020 bytes). | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$E5AE` | `HeroJumpFrameTable` (`HeroJumpSprites`+906) | 114 | 19 records | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `SetActorFrame` | - |
| `$E620` | `HeroWalkSprites` | 650 of 728 | The hero walking and standing: 13 frames. Read in rzx-r3 and s3-right (all 728 bytes). | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$E8AA` | `HeroWalkFrameTable` (`HeroWalkSprites`+650) | 78 | 13 records | `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$E8F8` | `FragmentSprites` | 264 | A fragment of a broken urn: 8 copies of 3 bytes x 11 lines, shifted 0-7 pixels (`$E8F8` + 33 x shift). Read in rzx-r3 (all 264 bytes). | `DrawActorSprite`, `PlotRow3`, `PlotRow3Mirrored` | - |
| `$EA00` | `ItemIconSprites` | 32 of 288 | The item icons: 9 of 2 bytes x 16 lines (the first item kind 2's), for the HUD's strip and the items on the floor (ItemIcons `$7F2F`; kind 4 is BlankIcon `$8A44`). DrawItemIcon and the item actors. Read in rzx-r3 (all 288 bytes) and s3-right (64). | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EA20` | `ItemIconKind6` (`ItemIconSprites`+32) | 32 | - | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EA40` | `ItemIconKind9` (`ItemIconSprites`+64) | 32 | - | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EA60` | `ItemIconKind3` (`ItemIconSprites`+96) | 32 | - | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EA80` | `ItemIconKind7` (`ItemIconSprites`+128) | 32 | - | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EAA0` | `ItemIconKind5` (`ItemIconSprites`+160) | 32 | - | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EAC0` | `ItemIconKind0` (`ItemIconSprites`+192) | 32 | an empty box | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EAE0` | `ItemIconKind8` (`ItemIconSprites`+224) | 32 | - | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EB00` | `ItemIconKind1` (`ItemIconSprites`+256) | 32 | - | `DrawActorSprite`, `DrawItemIcon` | - |
| `$EB20` | `DriftShotSprites` | 39 of 156 | The drifting shots: 4 frames of 3 bytes x 13 lines (the frame words at `$B4B9`). Read in s3-right (78 of 156 bytes); not in rzx-r3. | `UpdatePathFlyer` | - |
| `$EB47` | `DriftShot1` (`DriftShotSprites`+39) | 39 | - | `UpdatePathFlyer` | - |
| `$EB6E` | `DriftShot2` (`DriftShotSprites`+78) | 39 | - | - | - |
| `$EB95` | `DriftShot3` (`DriftShotSprites`+117) | 39 | - | - | - |
| `$EBBC` | `HeroLeapSprites` | 681 of 765 | The hero's leaps (back and up): 14 frames. Read in rzx-r3 (434 of 765 bytes); not in s3-right. | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$EE65` | `HeroLeapFrameTable` (`HeroLeapSprites`+681) | 84 | 14 records | `SetActorFrame` | - |
| `$EEB9` | `ParticleGlyphs` | 32 | The burst's 4 particle glyphs, 1 byte x 8 lines each (UpdateBurst: BurstGlyphs[...] x 8 + `$EEB9`). Read in rzx-r3 (all 32 bytes). | `UpdateBurst` | - |
| `$EED9` | `BurstGlyphs` | 35 | The glyph (0-3) of each burst step, indexed by the step + a random 0-3 (35 bytes). Read in rzx-r3 (31 of 35 bytes). | `UpdateBurst` | - |
| `$EEFC` | `BurstDirections` | 192 | 6 rows of 32 indices into the burst's step table: each particle direction's step at each burst step. Read in rzx-r3 (177 of 192 bytes). | `UpdateBurst` | - |
| `$EFBC` | `BurstShapes` | 14 of 62 | The shapes a burst breaks up: 62 bytes, 2 bytes a line; each start reads 2 x 12 lines from its address. The shapes are read from `$EFBC` (`$A064`), `$EFCA` (`$9FEF`: 14 bytes on, overlapping the first's zero tail) and `$EFE2` (the dragon's and the figure's last hits, `$A01E`, `$A039`). Read in rzx-r3 (all 62 bytes). | `StartBurst` | - |
| `$EFCA` | `BurstShape2` (`BurstShapes`+14) | 24 | the second shape | `StartBurst` | - |
| `$EFE2` | `BurstShapeBoss` (`BurstShapes`+38) | 24 | the bosses' shape | `StartBurst` | - |
| `$EFFA` | `BlockEnd` | 69 | 69 zero bytes to the block's end (`$F03E`) that no code reads (rzx-r3, s3-right; known only from the code) | - | - |


## Stage 4 (TZX block 49) (`src/stage4/stage4.json`)

Myth: History in the Making, System 3 Software 1989: stage 4 (TZX block 49), 33 792 bytes loaded at `$6C3F` by the
resident stage loader over `$6C3F-$F03E` (tools/image.py). Its entries are `src/stage4/<module>.asm`, written from
`src/stage4/stage4.ann` by `kit/mkgame.py --part src/stage4/stage4.json`; the readers and writers from
`work/stage1/rec/s4-right`, `work/stage2/rec/rzx-r4`.

### Stage 4 (TZX block 49): variables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6C3F` | `PlayBufferTail` | 193 | The last 193 bytes of the play buffer PlayBuffer `$5B00-$6CFF` (character row 17's last lines). ClearBuffer `$9A28` clears the play buffer to `$6CFF` with PUSH HL (SP from `$6D00`); RoomChange `$97FB` unpacks the stage's tiles and map into it from `$5B00` (stage 4: 5331 bytes, to `$6FD2`, on over the shadow attributes; RoomCells `$9898` takes the map into Cells before RoomChange writes the room's colours); the actors are drawn into it every pass. Zero as loaded. Read and written in s4-right (all 193 bytes). | `CopyBuffer`, `PlotRow1`, `PlotRow2`, `PutBlock`, `RoomCells` | `DrawActorSprite`, `DrawSprite`, `PlotRow1`, `PlotRow2`, `Unrle` +1 |
| `$6D00` | `ShadowAttributes` | 192 of 768 | The shadow of the screen's 768 attributes, the screen's layout; the play area from `$6DC2` (row 6, column 2). The HUD's colours are copied into rows 0-5 at the stage's set-up (StageSetUp `$9715`); RoomChange `$97FB` writes each cell's attribute into rows 6-23, the actors' colours are painted over them every pass, and UpdateAttributes `$91D0` copies the open cells to `$5800` (ShowShadowAttributes `$91C3` the whole of it). FillShadowAttributes `$9193` paints rectangles into it with five bytes after its CALL. Zero as loaded. Read and written in s4-right (all 768 bytes). | `ClearShadowAttributes`, `FadeInStep`, `PutBlock`, `RoomCells`, `SavePlayAttrsGrid10` +3 | `ClearShadowAttributes`, `ColourActor`, `ColourSprite`, `ColourSpriteMirrored`, `DrawBossPicture` +9 |
| `$6DC0` | `PlayAttributes` (`ShadowAttributes`+192) | 2 | row 6: the first row of the play area (the room's 18 rows) | `ClearShadowAttributes`, `PutBlock`, `RoomCells`, `SavePlayAttrsGrid10`, `ShowShadowAttributes` | `ClearShadowAttributes`, `SaveAttributes`, `Unrle` |
| `$6DC2` | `PlayAttributesCell` (`ShadowAttributes`+194) | 574 | row 6, column 2: the room's first cell | `ClearShadowAttributes`, `FadeInStep`, `PutBlock`, `RoomCells`, `SavePlayAttrsGrid10` +2 | `ClearShadowAttributes`, `ColourActor`, `ColourSprite`, `ColourSpriteMirrored`, `DrawBossPicture` +6 |
| `$7000` | `HudPicture` | 64 of 1728 | The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their colours at `$7600` (6 rows of 32). DissolveHud `$8FD6` dissolves the 48 lines onto the screen's lines 0-47 and StageSetUp `$9715` copies the 192 colours into the shadow rows 0-5, once, at the stage's start. EndStage `$7898` saves the screen's lines 0-47 back here and the attributes `$5800-$58BF` to `$7600` (`$78B6`), so the next stage's block shows the HUD as the player left it; the copy is CopyScreenToBlock `$8FAE` called at `$7911` (its LDIR runs after EX DE,HL). Between the two the bytes are the records labelled inside (RoomAttributes, Cells, HeroRecord, Actors, Missiles, DigitBuffer, SpanTable). The picture: the frame of the HUD, the energy bar's box, the score box, the item strip's box, the lives and pieces boxes (docs/img). Read and written in s4-right (all 1728 bytes). | `ActorCellOffset`, `AddMissileFrom`, `AddMissileHigh`, `AltarDisc`, `AnkhShrine` +136 | `AddMissileFrom`, `AddMissileHigh`, `AddSpan`, `AltarDisc`, `AnkhShrine` +81 |
| `$7040` | `RoomAttributes` (`HudPicture`+64) | 2 | `$7040-$727F`: the old room's play colours (SavePlayAttrs `$A1A9`: 576 bytes, rows 6-23) and the cells' twins (`$7042` + row x 32 + column: PutBlock writes 0, UpdateAttributes reads the solid cells' colours); also the burst's particles (StartBurst `$A385`, 4 bytes each) | `AttrShadowAddressA`, `DissolveHud`, `UpdateBurst` | `CopyScreenToBlock`, `SavePlayAttrsGrid10`, `StartBurst`, `UpdateBurst` |
| `$7042` | `RoomAttributesCell` (`HudPicture`+66) | 574 | the twin of the cell `$7282` (576 bytes lower) | `AttrShadowAddressA`, `DissolveHud`, `UpdateAttributes`, `UpdateBurst` | `CopyScreenToBlock`, `PutBlock`, `SavePlayAttrsGrid10`, `StartBurst`, `UpdateBurst` |
| `$7280` | `Cells` (`HudPicture`+640) | 2 | the room's cells: 19 rows of 32 (tile numbers, then their kinds after BuildSpans `$9959`; bit 1 solid, bit 3 deadly, kind 7 a bridge slab) | `DissolveHud`, `StartGrid` | `CopyScreenToBlock`, `StartGrid` |
| `$7282` | `CellsPlay` (`HudPicture`+642) | 574 | row 0, column 2: the room's first cell (RoomCells `$9898` writes 28 x 18) | `BuildSpans`, `CellAt`, `CellUnderFeet`, `CheckDeadlyFloor`, `DissolveHud` +3 | `AltarDisc`, `BridgeLedge`, `BridgeLedgeForming`, `BuildSpans`, `CopyScreenToBlock` +4 |
| `$74C0` | `CellsFloor` (`HudPicture`+1216) | 32 | row 18 below the room: 32 bytes of `$FF` (StartGrid `$A5CC`), a floor no actor falls through | `DissolveHud`, `StartGrid` | `CopyScreenToBlock`, `StartGrid` |
| `$74E0` | `HeroRecord` (`HudPicture`+1248) | 1 | the hero's actor record (18 bytes; +0 X) | `AnkhShrine`, `BufferAddressDE`, `CellUnderFeet`, `CheckBarrier`, `CheckDeadlyFloor` +33 | `CopyScreenToBlock`, `HeroDeath`, `SetActorFrame`, `ShiftRoomColumns`, `SpawnActor` |
| `$74E1` | `HeroY` (`HudPicture`+1249) | 7 | +1 the hero's line | `BufferAddressDE`, `CellUnderFeet`, `CheckDeadlyFloor`, `CheckRoomExits`, `ClipActor` +21 | `CopyScreenToBlock`, `HeroDeath`, `SetActorFrame`, `ShiftRoomRows`, `SpawnActor` |
| `$74E8` | `HeroFrame` (`HudPicture`+1256) | 1 | +8 the frame number of the hero's set | `BufferAddressDE`, `CheckGridPassages`, `CheckHeroFooting`, `ClipActor`, `ColourActor` +20 | `CheckHeroFooting`, `CopyScreenToBlock`, `HeroFall`, `HeroJump`, `HeroLeap` +17 |
| `$74E9` | `HeroFlags` (`HudPicture`+1257) | 1 | +9 bit 7: facing left | `BufferAddressDE`, `CellUnderFeet`, `CheckBarrier`, `CheckDeadlyFloor`, `ClipActor` +21 | `CopyScreenToBlock`, `EnterGrid3`, `HeroStand`, `HeroTurn`, `RespawnCountdown` +3 |
| `$74EA` | `HeroState` (`HudPicture`+1258) | 2 | +`$0A` 0 stand, 1 walk, 2 jump, 3 fall, 4 leap back, 5-7 strikes, 9 leap up, `$0B` recoil, `$0F` dying (the hero's state handler) | `BufferAddressDE`, `CheckDeadlyFloor`, `CheckGridPassages`, `CheckHeroFooting`, `CheckRoomExits` +22 | `CheckWalkBarriers`, `CopyScreenToBlock`, `HeroDeath`, `HeroFall`, `HeroJump` +18 |
| `$74EC` | `HeroAttribute` (`HudPicture`+1260) | 1 | +`$0C` the hero's attribute | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +4 | `CopyScreenToBlock`, `HeroDeath`, `HeroUpdate`, `SetActorFrame`, `SpawnActor` |
| `$74ED` | `HeroBaseX` (`HudPicture`+1261) | 1 | +`$0D` the base column | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +8 | `CopyScreenToBlock`, `HeroDeath`, `HeroWalk`, `MoveBaseX`, `RespawnCountdown` +5 |
| `$74EE` | `HeroBaseY` (`HudPicture`+1262) | 2 | +`$0E` the base line | `BufferAddressDE`, `CheckFellOut`, `ClipActor`, `ColourActor`, `DissolveHud` +9 | `CopyScreenToBlock`, `HeroDeath`, `HeroFall`, `HeroRecoil`, `MoveActorY` +4 |
| `$74F0` | `HeroCounter` (`HudPicture`+1264) | 2 | +`$10` the pause after a death (the hero's death) | `BufferAddressDE`, `ClipActor`, `ColourActor`, `DissolveHud`, `DrawActorSprite` +8 | `CopyScreenToBlock`, `HeroDeath`, `HeroRecoil`, `HeroStrikeMid`, `RespawnCountdown` +3 |
| `$74F2` | `Actors` (`HudPicture`+1266) | 216 | the 13 other actor records, 18 bytes each (`$74F2-$75DB`); +0 = `$FF` a free record | `ActorCellOffset`, `AnkhShrine`, `BarrierFrame`, `BarrierPillarActor`, `BossMouth` +57 | `AnkhShrine`, `BarrierPillarActor`, `BossMouth`, `Brazier`, `BridgeLedge` +29 |
| `$75CA` | `LastActor` (`HudPicture`+1482) | 18 | the 13th record | `ActorCellOffset`, `AltarDisc`, `BarrierBlockActor`, `BarrierFrame`, `Brazier` +27 | `AltarDisc`, `Brazier`, `ClearActors`, `CopyScreenToBlock`, `CrumblingLedge` +15 |
| `$75DC` | `ActorsEnd` (`HudPicture`+1500) | 4 | 4 bytes past the records: only the HUD picture's (DissolveHud, EndStage's save) bytes | `DissolveHud` | `CopyScreenToBlock` |
| `$75E0` | `Missiles` (`HudPicture`+1504) | 32 | the 16 missile records, 6 bytes each (`$75E0-$763F`): +0 the column (`$FF` free), +1 the line, +2 the kind (MissileHandlers `$B4E0`), +3 to +5 the kind's own | `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL`, `ClearShots` +6 | `AddMissileFrom`, `ClearShots`, `CopyScreenToBlock`, `HeadShot`, `RemoveActor` +1 |
| `$7600` | `HudColours` (`HudPicture`+1536) | 16 | the HUD's 192 colours as loaded (rows 0-5); in play the missile records 4-15 lie over them | `AddMissileFrom`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL`, `ClearShots` +6 | `AddMissileFrom`, `ClearShots`, `EndStage`, `HeadShot`, `RemoveActor` +2 |
| `$7610` | `MissilesHigh` (`HudPicture`+1552) | 48 | missile records 8-15 (AddMissileHigh `$B45C`: the hero's death sparks) | `AddMissileFrom`, `AddMissileHigh`, `AttrShadowAddress`, `AttrShadowAddressA`, `BufferAddressHL` +9 | `AddMissileFrom`, `AddMissileHigh`, `ClearKind2Missiles`, `ClearShots`, `EndStage` +6 |
| `$7640` | `DigitBuffer` (`HudPicture`+1600) | 96 | in play: the score's digit picture (6 + 2 columns x 8 lines, the score's renderer, RevealScore `$97CD`) and a sprite's shifted copy (PreShiftSprite `$7F89`) | `CopyToScreen`, `PlotRow3`, `ShiftLine1`, `ShiftLine4`, `StageSetUp` | `ClearShots`, `EndStage`, `PreShiftSprite`, `RenderDigits`, `RenderScore` +3 |
| `$76A0` | `SpanTable` (`HudPicture`+1696) | 32 | in play: the open spans CopyBuffer copies, 6 bytes each (the length, 0, the buffer address, the screen address; SpanCount spans), on to `$779B` | `BuildSpans`, `StageSetUp` | `AddSpan`, `BuildSpans`, `EndStage`, `StageEntry` |
| `$76C0` | `SpanTableRest` | 220 | The span table's room past the HUD's colours: spans 6-42 (`$76C0-$779B`). BuildSpans `$9959` and AddSpan `$99E1` write the spans from `$76A0` on; a room of many short runs reaches into this space. Zero as loaded. In s4-right 196 of its bytes are written (to `$7783`) and 31 read. | `BuildSpans` | `AddSpan`, `BuildSpans` |
| `$779C` | `Unused779C` | 100 | 100 bytes no code reads or writes (s4-right; known only from the code: no operand in the block points into it); zero as loaded. After SpanTableRest, up to the code at `$7800`; no instruction of the block names an address in it. Not read or written in any recording (the recordings checked: s4-right, rzx-r4); known only from the code. | - | - |

### Stage 4 (TZX block 49): mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7982` | `PaceWaits` | 96 | The busy-wait rounds of each place: word GridNumber x 3 + RoomNumber (48 words). Read by PacePass `$7974` (LD HL,PaceWaits; the word at + 2 x (GridNumber x 3 + RoomNumber)). Words 0 and 1 (grid 0 rooms 0 and 1): `$0258` and `$0640`; words 12 and 13 (grid 4 rooms 0 and 1): `$04B0`; all the others 1. Three words a grid is fewer than the rooms of some grids (grid 3 has a room 3, grid 4 a room 4), so those rooms read the next grid's words; they are all 1 there. Read every pass in both recordings. | `PacePass` | - |

### Stage 4 (TZX block 49): render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7FCC` | `ShiftRoutines` | 16 | The shift routine for 1-7 pixels (entry 0 unused). Read by PreShiftSprite `$7FB3`: ShiftLine1 to ShiftLine7. Read in s4-right (42 times). | `PreShiftSprite` | - |
| `$8F0B` | `RowPlotters` | 32 | The row plotter of each sprite width: word 2 x width + 1 when mirrored. Read by the sprite drawer at `$A850` (LD BC,RowPlotters): index 2 x width + (facing left). Width 0 and the mirrored width 7 hold HangFlashBorder, never reached with a valid frame. Read in both recordings. | `DrawActorSprite` | - |
| `$B62D` | `ImageDescriptors` | 36 | Nine image descriptors: the image address, the width in bytes, the height in lines. `$E4C3`, `$E4EA`, `$E511`, `$E538` (3 x 13) and `$E55F`, `$E577`, `$E58F`, `$E5A7`, `$E5BF` (3 x 8). Only the first two are read: IX = `$B62D` or `$B631` by the bit 0 of the missile's +5 (`$8509`, `$8514`, kinds 5 and 6, the thrown item); the other seven have no reader. | `ColourSprite`, `UpdatePathFlyer` | - |
| `$B651` | `SpeedRamps` | 64 | Four rows of 16 rising steps 1-5: no reader found (known only from the code). No instruction or word of the image refers to `$B651`; it takes the place of stage 1's SpeedSteps (`$B3FA`). | - | - |

### Stage 4 (TZX block 49): hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7AE6` | `StarPixels` | 32 | The two pixel lines of a star, by speed (rows 1-4) and pixel (pairs 0-3). Read by MoveStar `$7AAE` (LD HL,StarPixels; + (speed - 1) x 8 + pixel x 2): speed 1 a single pixel, speed 2 two pixels on one line, speeds 3-4 two pixels on two lines. Read in rzx-r4 (the stage exit). | `MoveStar` | - |
| `$7B27` | `StageExitBox` | 5 | FillAttributes' inline record: column 2, line `$30`, 28 x 18 cells, attribute 0. The inline record after the CALL at `$7B24`, read by FillAttributes (it returns past it). Read in rzx-r4 (1 call). | `FillAttributes` | - |
| `$7C5E` | `ScoreDigits` | 2 of 9 | The score as text: two unused bytes, ScoreHigh's two digits, Score's four digits, 0. RenderScore's record for RenderDigits (IX = ScoreDigits, the first two bytes skipped). EndStageSave returns ScoreDigitsHigh in BC. Read every pass in both recordings. | `RenderDigits`, `RenderScore`, `ShowScore` | `ByteToDigits`, `NumberToDigits` |
| `$7C60` | `ScoreDigitsHigh` (`ScoreDigits`+2) | 2 | ScoreHigh's two digits (ByteToDigits) | `RenderDigits`, `RenderScore`, `ShowScore` | `ByteToDigits` |
| `$7C62` | `ScoreDigitsLow` (`ScoreDigits`+4) | 4 | Score's four digits (NumberToDigits) | `RenderDigits`, `RenderScore` | `NumberToDigits` |
| `$7C66` | `ScoreDigitsEnd` (`ScoreDigits`+8) | 1 | 0: the end mark | `RenderDigits`, `RenderScore` | - |
| `$844A` | `GameOverBox` | 5 | FillAttributes' inline record: column 12, line 24, 8 x 2 cells, the colour (patched). The inline record after the CALL at `$8447`, read by FillAttributes (it returns past it). Read in s4-right (169 calls). | `FillAttributes` | `GameOverStep` |
| `$A5A4` | `BarMasks` | 8 | The left-aligned masks of 0-7 pixels for the bar's last byte. 0, `$80`, `$C0`, `$E0`, `$F0`, `$F8`, `$FC`, `$FE`; read by DrawEnergyBar. | `DrawEnergyBar` | - |

### Stage 4 (TZX block 49): hero

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7CBB` | `SelectedBoxRecord` | 5 | FillAttributes' inline record: column 15, line 24, 2 x 2 cells, the colour (patched). The inline record after the CALL at `$7CB8`, read by FillAttributes (it returns past it). Read in rzx-r4 and s4-right (110 calls). | `FillAttributes` | `FlashSelectedBoxFrame` |
| `$7D56` | `WindowFrameColours` | 16 | The frame's 16 inks: 1 to 7 and back. Read by CycleWindowFrame `$7D38` (+ PassCounter & 15). Read in rzx-r4 (the item window). | `CycleWindowFrame` | - |
| `$7E08` | `ItemCountText` | 5 | The count as text for RenderDigits: two unused bytes, two digits, 0. Written by FormatItemCount (`$7DFA`, `$7DFD`) and read by RenderDigits and ShowItemCount (`$7DB5`, `$7DC2`). Read in rzx-r4 (758 times). | `RenderDigits`, `ShowItemCount` | `FormatItemCount` |
| `$7F51` | `CarriedItems` | 12 | The item kind of each of the 12 slots (slots 0-3 hold 4, the blank icon; the first item at slot 6). Copied from StartItems by InitStageState `$9F81`; read by GetSelectedItem, DrawItemStrip, AddItem and FindUrnCount. As loaded: the same as StartItems. Read in both recordings. | `AddItem`, `DrawItemStrip`, `FindUrnCount`, `GetSelectedItem` | `AddItem`, `InitStageState` |
| `$7F5D` | `CarriedCounts` | 12 | The amount of each slot's item (shown by ShowItemCount; AddItem adds). InitStageState sets slot 7 (item 2) to 6 (`$9FD0`); every other count is 0 at the start. Read in both recordings (GetSelectedItem's IX). | `AddItem`, `AltarDisc`, `DrainKind9`, `DrawItemStrip`, `FireKind1` +5 | `AddItem`, `DrainKind9`, `FireKind1`, `FireKind3`, `HeroThrowMissile` +1 |
| `$7F69` | `StartItems` | 12 | The carried items at the stage's start, copied to CarriedItems by InitStageState: slot 6 item 7, slot 7 item 2. Read by InitStageState `$9F7E` (LDIR of 12 bytes). Slots 0-3 hold 4 (the blank icon), 4-5 and 8-11 hold 0. ItemLast starts at 7 (`$9FCB`). | `FormatItemCount`, `InitStageState` | `AddItem` |
| `$7F75` | `ItemIcons` | 20 | The 16 x 16 icon of each item kind 0-9 (32 bytes each; kind 4 points to BlankIcon). Read by DrawItemIcon `$7E61`. Ten words: kinds 0-3 `$E443`, `$E463`, `$E403`, `$E3E3`; kind 4 BlankIcon; kinds 5-9 `$E483`, `$E423`, `$E4A3`, `$E3C3`, `$E3A3` (in the stage's graphics). Kind 5 is the exit item (CheckStageExit), 6 the disc (AltarDisc's picture), 8 an ankh-like cross (AnkhShrine), 9 the urn (FindUrnCount). Read in both recordings (the strip). | `DrawItemIcon` | - |
| `$8B6C` | `RecoilSteps` | 7 | The hop's y change at steps 0-6. Read by HeroRecoil `$8B5E`: -5, -1, 0, 0, 1, 2, 3. Read in s4-right. | `HeroRecoil` | - |
| `$9491` | `RespawnPoints` | 132 | The respawn point of each grid's six rooms, 11 grids: the base column, the base line. 66 pairs (column, line), read by RespawnPoint `$9477` with the index GridNumber x 6 + RoomNumber; (0, 0) for the rooms a grid lacks. Column `$14` with line `$19`, `$21`, `$31` or `$41` are the common points. | `RespawnPoint` | - |
| `$AF11` | `HeroStandSet` | 4 | SetActorFrame's parameters: the walk frame table `$E10B`, its graphics `$DEA4` (13 frames; `$0C` stands). Inline after HeroStandFrame's CALL SetActorFrame `$ABBD`. Read in s4-right (17 passes) and rzx-r4 (294). | `SetActorFrame` | - |
| `$AF5E` | `StrikeLeftover` | 1 | An unreached RET byte after HeroFireHeld. HeroFireHeld leaves by its own jumps; nothing jumps to this byte. Not executed in any recording (the recordings checked: s4-right, rzx-r4); known only from the code. | `SetActorFrame` | - |
| `$AFB5` | `HeroStrikeLowSet` | 4 | SetActorFrame's parameters: the strike frame table `$DA7B`, its graphics `$D785` (16 frames). Inline after HeroStrikeLow's CALL SetActorFrame `$ABBD`. Read in rzx-r4 (208 passes); not in s4-right. | `SetActorFrame` | - |
| `$AFB9` | `HeroStrikeLowFrames` | 8 | the strike set's frame (less 4) for each pass of the low strike. Read by HeroStrikeLow (LD HL,HeroStrikeLowFrames + the pass). Read in rzx-r4 (208 passes); not in s4-right. | `HeroStrikeLow`, `SetActorFrame` | - |
| `$AFFC` | `HeroStrikeMidSet` | 4 | the strike frame table `$DA7B`, its graphics `$D785`. Inline after HeroStrikeMid's CALL SetActorFrame `$ABBD`. Read in rzx-r4 (54 passes); not in s4-right. | `SetActorFrame` | - |
| `$B000` | `HeroStrikeMidFrames` | 10 | the strike set's frame (less 6) for each pass of the middle strike. Read by HeroStrikeMid (LD HL,HeroStrikeMidFrames + the pass). Read in rzx-r4 (54 passes); not in s4-right. | `HeroStrikeMid`, `SetActorFrame` | - |
| `$B046` | `HeroStrikeHighSet` | 4 | the strike frame table `$DA7B`, its graphics `$D785`. Inline after HeroStrikeHigh's CALL SetActorFrame `$ABBD`. Read in s4-right (10 passes); not in rzx-r4. | `SetActorFrame` | - |
| `$B04A` | `HeroStrikeHighFrames` | 11 | the strike set's frame for each pair of passes of the high strike. Read by HeroStrikeHigh (LD HL,HeroStrikeHighFrames + half the pass count). Read in s4-right (10 passes); not in rzx-r4. | `HeroStrikeHigh`, `SetActorFrame` | - |
| `$B092` | `HeroThrowSet` | 4 | the strike frame table `$DA7B`, its graphics `$D785`. Inline after HeroThrow's CALL SetActorFrame `$ABBD`. Read in rzx-r4 (200 passes); not in s4-right. | `SetActorFrame` | - |
| `$B0A2` | `HeroThrowFrames` | 12 | the strike set's frame for each pair of passes of the throw: 9, `$0A`, `$0B`, `$0C`, `$0D`, `$0E`, `$0C`, `$0F`, `$0C`, `$0B`, `$0A`, 9. Read by HeroThrow (LD HL,HeroThrowFrames + half the pass count). Read in rzx-r4 (200 passes); not in s4-right. | `HeroThrow`, `SetActorFrame` | - |
| `$B17E` | `HeroWalkSet` | 4 | the walk frame table `$E10B`, its graphics `$DEA4`. Inline after HeroWalkShow's CALL SetActorFrame `$ABBD`. Read in s4-right (117 passes) and rzx-r4 (1973). | `SetActorFrame` | - |
| `$B25D` | `HeroJumpSet` | 4 | the jump frame table `$DE32`, its graphics `$DAE1` (19 frames). Inline after JumpFrame's CALL SetActorFrame `$ABBD`. Read in s4-right (56 passes) and rzx-r4 (1160). | `SetActorFrame` | - |
| `$B29A` | `HeroLeapSet` | 4 | the leap frame table `$E7DC`, its graphics `$E5D7` (14 frames). Inline after LeapFrame's CALL SetActorFrame `$ABBD`. Read in rzx-r4 (800 passes); not in s4-right. | `SetActorFrame` | - |
| `$B2B4` | `TurnSteps` | 12 | the base-column move of a turn at each walk frame. Read by HeroTurn (LD HL,TurnSteps + the walk frame). Read in rzx-r4 (4 turns); not in s4-right. | `HeroTurn` | - |

### Stage 4 (TZX block 49): missiles

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8098` | `ShotFrames` | 20 | Frame records: graphics address, width, lines (`$CF29` 2x5, `$CF33` 1x15, `$CF42` 1x15, `$CF51` 2x13, `$CF6B` 2x13). Read by DrawShotFrame `$8076` (IX = ShotFrames + C). Five records of 4 bytes: the graphics word, the width in bytes, the lines. Read in rzx-r4 (UpdateHeroShot). | `ColourSprite`, `ColourSpriteMirrored`, `DrawShotRecord`, `DrawSprite`, `DrawSpriteMirrored` | - |
| `$80AC` | `ShotDirections` | 32 | The 8 directions: dx, dy, the frame's offset in ShotFrames, 1 mirrored. Read by UpdateAimedShot `$8049` (+ 4 x the direction): 0 up, 1 up-right, 2 right, 3 down-right, 4 down, 5 down-left, 6 left, 7 up-left (dy 8 lines a step). Read in neither recording (UpdateAimedShot did not run). | - | - |
| `$8169` | `HeroBoltFrames` | 12 | Three frame records (graphics, width, lines): `$CF85`, `$CF95`, `$CFA5`, each 2 x 8. Read by UpdateHeroBolt `$815D` (IX = HeroBoltFrames + 4 x +3). Read in rzx-r4. | `ColourSprite`, `DrawShotRecord`, `DrawSprite` | - |
| `$8546` | `PathSteps` | 134 | The flyer's path: dx (half columns), dy a step; `$64` `$64` ends. Read by UpdatePathFlyer `$84AD` (+ 2 x the step). 66 pairs and the end mark `$64` `$64` at `$85CA`. Read in s4-right. | `UpdatePathFlyer` | - |
| `$B604` | `HeadShotImages` | 20 | Five image descriptors (address, width, height): `$CFB5`, `$CFC5`, `$CFD5`, `$CFE5`, `$CFF5`, each 2 x 8. Read by HeadShot (LD IX,HeadShotImages + 4 x the direction). Read in rzx-r4 (2178 passes); not in s4-right. | `ColourSprite`, `DrawSprite`, `HeadShot` | - |
| `$B618` | `HeadShotSteps` | 5 | The line change a pass for directions 0-4: -2, 0, 2, 5, 8. Read by HeadShot (LD HL,HeadShotSteps + the direction). Read in rzx-r4 (2220 passes); not in s4-right. | `HeadShot` | - |

### Stage 4 (TZX block 49): rooms

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9AE2` | `Grid0` | 9 of 713 | Grid 0's record (GridNumber 0: the palm beach, the pyramid's steps and the barrier): 25 x 9 blocks, start window 0, 0, the room table Grid0Rooms, map offset 0. A grid record, 9 bytes, as in stage 1: +0 the width and +1 the height in blocks, +2/+3 the start window's block column and row (StartGrid `$A5CC` copies them to RoomColumn and RoomRow; the grid passages rewrite them, Grid1 +2 at ReturnToGrid1 `$8D23` and Grid8 +2 at ReturnToGrid8 `$8CE0`), +4/+5 the room table, +6/+7 the grid's offset in the map section of the unpacked graphics, +8 the rooms a grid row of rooms (meaningful only in a grid of more than one row of rooms: Grid1). A room is a window of 14 x 9 blocks; the windows step 11 block columns and 6 block rows. RoomGrid points at the record of the hero's grid. Stage 4 has nine grids, where stage 1 has three. They are named by the GridNumber (`$FE47`) the grid passages give them (EnterGrid1 `$8B8C` to EnterGrid10 `$969C`), not by their order: the records lie in the order 0, 9, 2, 1, 3, 4, 5, 8, 10 (GridNumber 6 and 7 do not exist); tools/fig_rooms.py numbers them 0-8 in that order. Stage 4 keeps their nine records together, then the nine room tables (Grid0Rooms `$9B33`), then the nine placement lists (Grid0Placements `$9B50`): stage 1 puts each room table after its record. The resource is rooms-split.txt (tools/res_stage4.py), in rooms.txt's language; tools/fig_rooms.py draws the map and every room from it (docs/img/maps/stage4.png, stage4-rooms.png). Read in s4-right (RoomCells `$9898`, StartGrid `$A5CC`, LeaveRoomDown `$A06A`, the hero's room checks); the start columns written only by the grid passages, which s4-right did not run. Read by the hero's room checks (CheckRoomExits `$AC9E`) in s4-right. As in stage 1: LoadRoomActors `$A654` puts each placement not done that lies in the room's window into a free actor record, with its kind's row of ActorKinds; MarkPlacementDone `$A616` sets bit 7 when the actor is beaten or taken; ResetObjectLists `$942B` clears the bits at the stage's start. 62 placements are kind 4 at X 250, Y 0, each right after a trap's or a switch's: X 250 lies outside every window, so LoadRoomActors never builds them; they keep the next placement's index even, so each trap's slot (+`$10` / 2 in TrapSlots, TrapSlotAddress) is its own (known from the code: no reader of the X 250 records). Read and written in s4-right (LoadRoomActors, MarkPlacementDone, ReviveAllPlacements `$A629`, ResetObjectLists). | `CheckRoomExits`, `ClearTakenFlags`, `HeroActor`, `LeaveRoomDown`, `LoadRoomActors` +4 | `ClearTakenFlags`, `MarkPlacementDone`, `ReturnToGrid1`, `ReturnToGrid8`, `ReviveAllPlacements` |
| `$9AEB` | `Grid9` (`Grid0`+9) | 9 | Grid 9 (the hall beyond the boss's bridge, where the exit item is given; EnterGrid9 `$8BBD`): 14 x 9 blocks, one room, map offset 225 | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9AF4` | `Grid2` (`Grid0`+18) | 9 | Grid 2 (the tomb behind the hub's first door; EnterGrid2 `$8BF1`): 47 x 9 blocks, 4 rooms, map offset 351 | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9AFD` | `Grid1` (`Grid0`+27) | 9 | Grid 1 (the hub: two rooms one above the other, the lower one with the four doors at columns 8, `$0A`, `$0C`, `$0E`; EnterGrid1 `$8B8C`): 14 x 15 blocks, map offset 774, 1 room a grid row | `HeroActor`, `LeaveRoomDown`, `RoomCells`, `StartGrid` | `ReturnToGrid1` |
| `$9B06` | `Grid3` (`Grid0`+36) | 9 | Grid 3 (the second door's tomb, entered in its room 3; EnterGrid3 `$8C20`): 47 x 9 blocks, 4 rooms, start window at block column 33, map offset 984 | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9B0F` | `Grid4` (`Grid0`+45) | 9 | Grid 4 (the third door's tomb, entered in its room 2; EnterGrid4 `$8C53`): 58 x 9 blocks, 5 rooms, start window at block column 22, map offset 1407 | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9B18` | `Grid5` (`Grid0`+54) | 9 | Grid 5 (the fourth door's tomb; EnterGrid5 `$8C82`): 58 x 9 blocks, 5 rooms, map offset 1929 | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9B21` | `Grid8` (`Grid0`+63) | 9 | Grid 8 (the boss's hall: the boss in room 2, the crumbling ledges, the urns, the bridge; the stage's exit in room 1; EnterGrid8 `$8CB1`): 36 x 9 blocks, 3 rooms, map offset 2451 | `HeroActor`, `RoomCells`, `StartGrid` | `ReturnToGrid8` |
| `$9B2A` | `Grid10` (`Grid0`+72) | 9 | Grid 10 (the mummy's corridor: no placement, the mummy comes from its template; EnterGrid10 `$969C`): 36 x 9 blocks, 3 rooms, map offset 2775 | `HeroActor`, `RoomCells`, `StartGrid` | - |
| `$9B33` | `Grid0Rooms` (`Grid0`+81) | 2 | the nine room tables, one exit byte a room (bit 0 right, bit 1 left, bit 2 up, bit 3 down): grid 0's 2 rooms | `CheckRoomExits` | - |
| `$9B35` | `Grid9Rooms` (`Grid0`+83) | 1 | grid 9's room (no exit: left through ReturnToGrid8) | `CheckRoomExits` | - |
| `$9B36` | `Grid2Rooms` (`Grid0`+84) | 4 | grid 2's 4 rooms | `CheckRoomExits` | - |
| `$9B3A` | `Grid1Rooms` (`Grid0`+88) | 2 | grid 1's 2 rooms: the top one's exit is down | `CheckRoomExits` | - |
| `$9B3C` | `Grid3Rooms` (`Grid0`+90) | 4 | - | `CheckRoomExits` | - |
| `$9B40` | `Grid4Rooms` (`Grid0`+94) | 5 | - | `CheckRoomExits` | - |
| `$9B45` | `Grid5Rooms` (`Grid0`+99) | 5 | - | `CheckRoomExits` | - |
| `$9B4A` | `Grid8Rooms` (`Grid0`+104) | 3 | - | `CheckRoomExits` | - |
| `$9B4D` | `Grid10Rooms` (`Grid0`+107) | 3 | - | `CheckRoomExits` | - |
| `$9B50` | `Grid0Placements` (`Grid0`+110) | 18 | grid 0's 5 placements: the kind (bit 7: done), X and Y in cells over the whole grid; `$FF` `$FF` `$FF` ends | `ClearTakenFlags`, `LoadRoomActors`, `ReviveAllPlacements` | `ClearTakenFlags`, `ReviveAllPlacements` |
| `$9B62` | `Grid9Placements` (`Grid0`+128) | 9 | grid 9's 2: two braziers (kind 12) | `ClearTakenFlags`, `LoadRoomActors` | `ClearTakenFlags` |
| `$9B6B` | `Grid2Placements` (`Grid0`+137) | 111 | grid 2's 36: urns, switches, pendulums, falling columns, crumbling slabs, braziers | `ClearTakenFlags`, `LoadRoomActors`, `MarkPlacementDone` | `ClearTakenFlags`, `MarkPlacementDone` |
| `$9BDA` | `Grid1Placements` (`Grid0`+248) | 12 | grid 1's 3: two braziers and the altar disc (kind 13) | `LoadRoomActors` | - |
| `$9BE6` | `Grid3Placements` (`Grid0`+260) | 117 | grid 3's 38 | `LoadRoomActors`, `MarkPlacementDone` | `MarkPlacementDone` |
| `$9C5B` | `Grid4Placements` (`Grid0`+377) | 117 | grid 4's 38 (with the ankh shrine, kind 19) | `LoadRoomActors`, `MarkPlacementDone` | `MarkPlacementDone` |
| `$9CD0` | `Grid5Placements` (`Grid0`+494) | 150 | grid 5's 49 | `LoadRoomActors`, `MarkPlacementDone` | `MarkPlacementDone` |
| `$9D66` | `Grid8Placements` (`Grid0`+644) | 66 | grid 8's 21: crumbling ledges (14, 15), the boss's mouth (16), the urn markers (17), the bridge ledges (18) | `LoadRoomActors` | - |
| `$9DA8` | `Grid10Placements` (`Grid0`+710) | 3 | grid 10's: none | `LoadRoomActors` | - |
| `$9DAB` | `TrapSlots` | 32 of 112 | The trap slots: 16 a grid (GridNumber 0-6), one byte an actor: 0 idle, 1 triggered, 2 done; zero as loaded. TrapSlotAddress `$8786` gives `$9DAB` + GridNumber x 16 + the actor's +`$10` / 2 (the placement's index / 2). The switches set them (FloorSwitch `$865C`, CrumblingSlab `$869B`), the traps read them (SwitchedSpikes `$86FF`, FallingColumn `$87AC`, Pendulum `$888F`). StartTrapChain / TrapChainStep (`$82FA`, `$830C`) set grid 3's slots 6 down to 0 (`$9DDB` on), LinkTrapSlots (`$8324`) joins grid 3's slots 12-15 (`$9DE7`), grid 4's 5-10 (`$9DF0`) and grid 5's 4-6 (`$9DFF`). InitStageState `$9F71` clears the 112 bytes at the stage's start. Read and written in rzx-r4 (the switches and traps); in s4-right only InitStageState's clear ran over them. | `CrumblingSlab`, `InitStageState`, `LeaveRoomLeft`, `LinkTrapSlots`, `PressSwitch` +1 | `CrumblingSlab`, `FallingColumn`, `InitStageState`, `LeaveRoomLeft`, `LinkTrapSlots` +3 |
| `$9DCB` | `TrapSlotsGrid2` (`TrapSlots`+32) | 16 | grid 2's 16 slots | `CrumblingSlab`, `InitStageState`, `PressSwitch`, `TrapSlotState` | `CrumblingSlab`, `FallingColumn`, `InitStageState`, `PressSwitch` |
| `$9DDB` | `TrapSlotsGrid3` (`TrapSlots`+48) | 12 | grid 3's 16 slots: 0-6 the trap chain, 12-15 linked at `$9DE7` | `InitStageState`, `PressSwitch`, `TrapSlotState` | `FallingColumn`, `InitStageState`, `PressSwitch`, `SwitchedSpikes`, `TrapChainStep` |
| `$9DE7` | `TrapSlotsGrid3Linked` (`TrapSlots`+60) | 4 | grid 3's slots 12-15 | `InitStageState`, `LinkTrapSlots`, `PressSwitch` | `InitStageState`, `LinkTrapSlots`, `PressSwitch` |
| `$9DEB` | `TrapSlotsGrid4` (`TrapSlots`+64) | 5 | grid 4's 16 slots: 5-10 linked at `$9DF0` | `CrumblingSlab`, `InitStageState`, `PressSwitch`, `TrapSlotState` | `FallingColumn`, `InitStageState`, `PressSwitch` |
| `$9DF0` | `TrapSlotsGrid4Linked` (`TrapSlots`+69) | 11 | grid 4's slots 5-10 | `InitStageState`, `LeaveRoomLeft`, `LinkTrapSlots`, `PressSwitch`, `TrapSlotState` | `FallingColumn`, `InitStageState`, `LeaveRoomLeft`, `PressSwitch` |
| `$9DFB` | `TrapSlotsGrid5` (`TrapSlots`+80) | 4 | grid 5's 16 slots: 4-6 linked at `$9DFF` | `CrumblingSlab`, `InitStageState`, `PressSwitch`, `TrapSlotState` | `CrumblingSlab`, `FallingColumn`, `InitStageState`, `PressSwitch` |
| `$9DFF` | `TrapSlotsGrid5Linked` (`TrapSlots`+84) | 28 | grid 5's slots 4-6 | `CrumblingSlab`, `InitStageState`, `LinkTrapSlots`, `PressSwitch`, `TrapSlotState` | `CrumblingSlab`, `FallingColumn`, `InitStageState`, `PressSwitch` |
| `$B77F` | `StageGraphics` | 3366 | The stage's tiles, blocks and map, RLE-packed (3366 bytes; 5331 unpacked: 179 tiles, 108 blocks, the nine grids' map). RoomChange `$97FB` unpacks it with Unrle `$A5AC` to `$5B00` at every room change (escape byte `$C1`). Unpacked: five offset words from `$5B0A` (the tile kinds 179 bytes, the tile pixels 1432, the tile colours 179, the blocks 108 x 4, the map 3099 bytes: the nine grids in the order of their records, Grid0 25 x 9 first). The unpacked block reaches `$6FD2`, over the shadow attributes; RoomCells `$9898` takes the room's blocks into Cells before RoomChange writes the room's colours. The packer left one stretch of 9 equal bytes unpacked at offset 285 (graphics.txt's `literal`). Read in s4-right and rzx-r4 (Unrle: all 3366 bytes, at every room change). | `Unrle` | - |

### Stage 4 (TZX block 49): enemies

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$82A0` | `PieceFrames` | 4 | SetActorFrame's inline words: the frame table `$E367` and the graphics base `$E27F`. Ten frame records: 0 and 1 the piece (2 x 14), 2-9 the sparkle. Read by SetActorFrame `$ABBD` after the CALL at `$829D`. Read in rzx-r4. | `SetActorFrame` | - |
| `$82DC` | `RiseSteps` | 30 | The rising piece's y change at each step 0-29. Read by PieceRises `$82C6` (+ the step). Ten 0s, then up 1 to 6, down 4 to up 4, down 2 to up 2. Read in rzx-r4. | `UpdatePieceActor` | - |
| `$86FB` | `CrumblingSlabFrames` | 4 | SetActorFrame's inline words: the frame table `$CB0B` and the graphics base `$C825`. Read by SetActorFrame `$ABBD` after the CALL at `$86F8`. The set has 25 records: 0-8 the slab crumbling (2 x 7), 9-16 spikes rising (2 x 3 to 2 x 9), 17 a column 2 x 63, 18 its lower half 2 x 29, 19-24 the dust at a column's foot (4 x 1 to 4 x 4). Read in rzx-r4. | `SetActorFrame` | - |
| `$873E` | `SwitchedSpikesFrames` | 4 | SetActorFrame's inline words: the frame table `$CB0B` and the graphics base `$C825`. The inline words after the CALL at `$873B`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (2624 calls). | `SetActorFrame` | - |
| `$87A8` | `FloorSwitchFrames` | 4 | SetActorFrame's inline words: the frame table `$CB0B` and the graphics base `$C825`. The inline words after the CALL at `$87A5`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (11448 calls). | `SetActorFrame` | - |
| `$8822` | `ColumnDropSteps` | 35 | The falling column's y change at each step 1-33, `$64` ends. Read by FallingColumn `$8804` (+ +`$0B`): 1, 1, 2, 2, ... 8 (the fall), then -6 to 6 and -3 to 3 (the bounces), `$64` at `$8844`. Read in rzx-r4. | `FallingColumn`, `SetActorFrame` | - |
| `$888B` | `FallingColumnFrames` | 4 | SetActorFrame's inline words: the frame table `$CB0B` and the graphics base `$C825`. The inline words after the CALL at `$8888`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (8055 calls). | `SetActorFrame` | - |
| `$88C0` | `PendulumFrames` | 4 | SetActorFrame's inline words: the frame table `$CECF` and the graphics base `$CBAD`. The inline words after the CALL at `$88BD`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (1774 calls). | `SetActorFrame` | - |
| `$88C4` | `PendulumSequence` | 25 | The pendulum's frame at each step +`$0B`: 0-11, 10 down to 3 (steps 0-19), then 14, 13, 12, 13, 14 (steps 20-24). Read by Pendulum `$88B8` (+ +`$0B`). Steps 3-24 are the swing loop. Read in rzx-r4. | `Pendulum`, `SetActorFrame` | - |
| `$890C` | `ColumnDustFrames` | 4 | SetActorFrame's inline words: the frame table `$CB0B` and the graphics base `$C825`. The inline words after the CALL at `$8909`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (219 calls). | `SetActorFrame` | - |
| `$892D` | `BrazierFrames` | 4 | SetActorFrame's inline words: the frame table `$C80D` and the graphics base `$C763`. The inline words after the CALL at `$892A`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (5259 calls). | `SetActorFrame` | - |
| `$8A1E` | `LedgeFrames` | 4 | SetActorFrame's inline words: the frame table `$D651` and the graphics base `$D5A0`. The inline words after the CALL at `$8A1B`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (3207 calls). | `SetActorFrame` | - |
| `$8A55` | `BridgeLedgeFormingFrames` | 4 | SetActorFrame's inline words: the frame table `$D651` and the graphics base `$D5A0`. The inline words after the CALL at `$8A52`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (1246 calls). | `SetActorFrame` | - |
| `$8A84` | `BridgeLedgeFrames` | 4 | SetActorFrame's inline words: the frame table `$D651` and the graphics base `$D5A0`. The inline words after the CALL at `$8A81`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (260 calls). | `SetActorFrame` | - |
| `$8B0E` | `BossMouthFrames` | 4 | SetActorFrame's inline words: the frame table `$D588` and the graphics base `$D508`. The inline words after the CALL at `$8B0B`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (458 calls). | `SetActorFrame` | - |
| `$8B12` | `BossMouthSequence` | 8 | The mouth's frame at each step +8 / 2: 0, 0, 0, 1, 2, 3, 2, 1. Read by BossMouth `$8B06`. Read in rzx-r4. | `BossMouth`, `SetActorFrame` | - |
| `$8B35` | `UrnMarkerFrames` | 4 | SetActorFrame's inline words: the frame table `$D74F` and the graphics base `$D68F`. The inline words after the CALL at `$8B32`, read by SetActorFrame `$ABBD` (it returns past them). Read in rzx-r4 (4684 calls). | `SetActorFrame` | - |
| `$934D` | `ScorpionSet` | 4 | SetActorFrame's parameters: the frame table `$D4CC`, the graphics `$D451` (10 frames). Two inline words after ScorpionActor's CALL SetActorFrame `$ABBD`, which skips them on return. Read in rzx-r4 (2189 passes of the scorpions); not in s4-right. | `SetActorFrame` | - |
| `$93AE` | `MummySet` | 4 | SetActorFrame's parameters: the frame table `$D421`, the graphics `$D115` (8 frames of 30 lines). Inline after MummyActor's CALL SetActorFrame `$ABBD`. Read in rzx-r4 (321 passes of the mummy in grid 10); not in s4-right. | `SetActorFrame` | - |
| `$93B2` | `MummyFrames` | 40 | The mummy's frame for each of its 40 steps: 0, 0, 1, 1, 2 (x 18), 3, 3, 4, 4, 5, 5, 6 (x 12), 7, 7. Read by MummyActor (LD HL,MummyFrames, + the step) before SetActorFrame. Read in rzx-r4 (321 passes); not in s4-right. | `MummyActor` | - |
| `$9711` | `BarrierSet` | 4 | SetActorFrame's parameters: the frame table `$D0F7`, the graphics `$D05D` (5 frames: the block, the pillar at four heights). Inline after BarrierFrame's CALL SetActorFrame `$ABBD`. Read in s4-right (1864 passes) and rzx-r4 (101). | `SetActorFrame` | - |
| `$A993` | `StrikeableActorSet` | 4 | SetActorFrame's parameters: the frame table `$D74F`, the graphics `$D68F` (9 frames). Inline after StrikeableActor's CALL SetActorFrame `$ABBD` (the column dust and the other actors the hero's strike hits). Read in rzx-r4 (4488 passes); not in s4-right. | `SetActorFrame` | - |
| `$AB85` | `FragmentArc0` | 28 of 56 | The line change of each step of a fragment's arc 0 (28 signed bytes). Read by FragmentActor `$AA7F` (+`$0B` the step): up 8, 6, 4, 2, 1 lines, then down 1, 2, 4, 6, 8, a short second hop and the rest. | - | - |
| `$ABA1` | `FragmentArc1` (`FragmentArc0`+28) | 28 | arc 1-3: the same shape, flatter (up 5 to 1, down 1 to 5), read from `$AA89` | - | - |
| `$B44C` | `HeadShotDirections` | 8 | The direction (0-4) of each shot of the head in turn: 0, 1, 2, 3, 4, 3, 2, 1. Read by HeadShots (LD HL,HeadShotDirections + the shot's number). Read in rzx-r4 (110 shots of the boss's head); not in s4-right. | `HeadShots` | - |

### Stage 4 (TZX block 49): util

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$90CA` | `BlankIcon` | 32 | 32 zero bytes: the blank icon (item kind 4) and the source of every clear done by copying with stride 0. ItemIcons' kind 4 points here (DrawItemIcon reads all 32 bytes); GameOverStep `$8425` copies its first bytes with stride 0 to clear the item strip; the templates' frame word (`$9EE5` and others) points here until SetActorFrame sets a frame. Read in both recordings. | `CopyToScreen`, `DrawItemIcon`, `PlotRow1` | - |

### Stage 4 (TZX block 49): actors

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$92BB` | `SpawnTable` | 60 | The rooms where a walker comes in: one byte a room, 6 a grid (10 grids), the line / 8 or 0. Read by SpawnPick `$929D`. Non-zero: grid 1 room 1 (`$0D`), grid 2 rooms 0 and 1 (`$0B`, `$0D`), grid 3 rooms 0, 2 and 3 (`$0D`), grid 4 rooms 1 and 3 (`$0B`). The value x 8 is the line E; the walker (template `$9F4D`, handler `$9319`) comes in at column `$1A` (`$92F7`: the branch at `$92B5` always takes it, since A is set to 0 before AND 1; the left-facing spawn `$9306` is never reached). Read in both recordings (57 picks in rzx-r4). | `SpawnTimer` | - |
| `$9E1B` | `ActorKinds` | 198 | The 22 placement kinds, 9 bytes each: the Y offset, the handler, 5 bytes for the record's +8 to +`$0C`, the record's +`$0F`. LoadRoomActors `$A654` builds an actor from a placement with its kind's row, as in stage 1: +1 Y = the placement's Y x 8 + the offset, +6/+7 the handler, +8 to +`$0C` (the counter, the flags, the state, the item, the attribute), +`$0F` (bit 1: kept over a room change). Stage 4's kinds: 0-2 urns and chests that break at the low strike (StrikeableActor `$A938`; +`$0B` the item inside: 5, 3, 1), 3 an object that leaves item 9, an urn (StrikeableKind9 `$A997`), 4 the water's surface (WaterRipple `$8629`; also the 62 X-250 fillers of the placement lists), 5 a floor switch (FloorSwitch `$865C`), 6 and 10 a pendulum (Pendulum `$888F`), 7 a falling column (FallingColumn `$87AC`), 8 a crumbling slab (CrumblingSlab `$869B`), 9 switched spikes (SwitchedSpikes `$86FF`), 11 an inert actor (InertActor `$8B39`), 12 a brazier (Brazier `$8917`), 13 the altar disc (AltarDisc `$8931`), 14 and 15 crumbling ledges (CrumblingLedge `$89A8`; 15 starts with +`$0A` = `$64` and does not crumble), 16 the boss's mouth (BossMouth `$8AD4`), 17 an urn marker (UrnMarker `$8B1A`), 18 a bridge ledge (BridgeLedge `$8A59`), 19 the ankh shrine (AnkhShrine `$8A88`), 20 and 21 the barrier's block and pillar (BarrierBlockActor `$96CB`, BarrierPillarActor `$96DD`; +`$0F` bit 0). Read in s4-right and rzx-r4 (LoadRoomActors: all 22 rows; every kind's handler ran in rzx-r4). | `LoadRoomActors` | - |
| `$9EE1` | `ActorTemplates` | 18 of 144 | Eight whole actor records (18 bytes each, the first the hero's) that SpawnActor `$A639` copies for the actors no placement makes. The handler at +6/+7 and the frame at +4/+5 as for a placed actor; the rest as an actor record (HeroRecord `$74E0`). Read in s4-right and rzx-r4 (SpawnActor; the dust, the ledges forming and the scorpion's and mummy's templates only in rzx-r4). | `SpawnActor` | - |
| `$9EF3` | `ItemTemplate` (`ActorTemplates`+18) | 18 | an item lying on the floor (SpawnItem `$A2A5`): 2 x 16, handler ItemHandler `$A32F` | `SpawnActor` | - |
| `$9F05` | `PieceTemplate` (`ActorTemplates`+36) | 18 | a piece of the stage's artefact (SpawnBonus `$822C`): handler UpdatePieceActor `$8260` | `SpawnActor` | - |
| `$9F17` | `FragmentTemplate` (`ActorTemplates`+54) | 18 | a fragment (3 x 11, SpawnFragments `$AA02`): handler FragmentActor `$AA4C` | - | - |
| `$9F29` | `ColumnDustTemplate` (`ActorTemplates`+72) | 18 | the dust at a fallen column's foot (FallingColumn `$87AC`): handler ColumnDustActor `$88FE` | `SpawnActor` | - |
| `$9F3B` | `BridgeLedgeTemplate` (`ActorTemplates`+90) | 18 | a ledge of the bridge forming after the boss (the boss beaten, `$A24C`): handler BridgeLedgeForming `$8A22` | `SpawnActor` | - |
| `$9F4D` | `ScorpionTemplate` (`ActorTemplates`+108) | 18 | a scorpion (SpawnScorpion `$92F7`): handler ScorpionActor `$9319` | `SpawnActor` | - |
| `$9F5F` | `MummyTemplate` (`ActorTemplates`+126) | 18 | the mummy of grid 10 (SpawnTimer `$9245` in grid 10): handler MummyActor `$9351` | `SpawnActor` | - |
| `$9FF1` | `LeftoverSteps` | 12 | 12 bytes 0, 1, 2, 2, 1, 0, 0, 1, 3, 3, 1, 0: no reader found (known only from the code). No instruction or word of the stage-4 image refers to `$9FF1`. | - | - |
| `$A51A` | `BurstLeftover` | 1 | An unreached RET byte after UpdateBurst's loop (its loop ends by RET Z at `$A456`). UpdateBurst leaves by RET Z inside its loop; nothing jumps to this byte. Not executed in any recording (the recordings checked: s4-right, rzx-r4); known only from the code. | - | - |
| `$A521` | `ParticleInks` | 4 | The burst's four particle attributes, written by StartBurst. ink C, bright ink C, ink B, bright ink B; the particle's byte 3 (0-3) picks one (UpdateBurst `$A4FD`). As loaded: 2, `$42`, `$43`, 3. | `UpdateBurst` | `StartBurst` |
| `$A525` | `BurstSteps` | 40 | 20 (dx, dy) steps: 10 for the left-byte particles, 10 for the right-byte ones. Read by UpdateBurst `$A491` (+`$14` for the right-byte directions). dx -1 to 1 columns, dy -1 to 1 rows. | `UpdateBurst` | - |
| `$B4E0` | `MissileHandlers` | 20 | The handler of each missile kind 0-9. 0 and 4 `$8D68`, 1 `$803A` (UpdateAimedShot), 2 `$80F4` (FireKind3's shot), 3 HeadShot `$B5C5`, 5 and 6 `$8450` (the thrown item, left and right), 7 and 8 `$8484` (UpdatePathFlyer; 7 the death burst), 9 `$80CC` (FireKind1's shot). Read by UpdateMissiles `$B4C6`. | `UpdateMissiles` | - |
| `$B57C` | `MissileColours` | 4 | bright red, bright magenta, bright red, magenta. Read by MissileColour (LD HL,MissileColours + FrameCounter AND 3), which no recording ran (the recordings checked: s4-right, rzx-r4); known only from the code. | - | - |
| `$B58E` | `ColourCycle4` | 4 | `$42`, `$43`, `$42`, 6. Read by ColourRedYellowCycle (LD HL,ColourCycle4 + the counter AND 3). Read in rzx-r4 (5259 passes); not in s4-right. | `ColourRedYellowCycle` | - |
| `$B5A0` | `HeadShotColours` | 8 | `$42`, `$43`, `$44`, `$45`, `$46`, `$45`, `$44`, `$43`. Read by HeadShotColour (LD HL,HeadShotColours + the counter AND 7). Read in rzx-r4 (2178 passes); not in s4-right. | `HeadShotColour` | - |
| `$B5BD` | `CycleColours` | 8 | the colour cycle. Read by CycleColourA (LD HL,CycleColours) in s4-right (170 passes) and rzx-r4 (7347), and by FlashPieces `$83A1` in rzx-r4 (540). | `CycleColour`, `CycleColourA`, `FlashPieces` | - |

### Stage 4 (TZX block 49): graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4A5` | `BossPicture` | 494 | The boss's face: a row-packed picture of 104 lines (each line a byte LEN x 16 + SKIP, then LEN bytes). DrawBossPicture `$8F2B` draws it with DrawRowPicture `$902A` into the play buffer at `$5F17` every pass in grid 8 room 2 while BossPhase is not 2. Read in rzx-r4 (458 passes); not in s4-right. | `DrawRowPicture` | - |
| `$C693` | `BossColours` | 104 | The boss picture's 8 x 13 attributes, normal. DrawBossPicture copies them into the shadow at `$6E58` (columns `$18-$1F`, rows 10-22). Read in rzx-r4. | `DrawBossPicture` | - |
| `$C6FB` | `BossHitColours` | 104 | The boss picture's 8 x 13 attributes while BossFlash runs (a hit). DrawBossPicture, instead of BossColours, while BossFlash is set. Read in rzx-r4 (20 hits). | `DrawBossPicture` | - |
| `$C763` | `BrazierSprites` | 194 | A brazier's flame: 4 frames (BrazierFrames `$892D`, Brazier `$8917`). Read in s4-right and rzx-r4. | `DrawActorSprite`, `SetActorFrame` | - |
| `$C825` | `TrapSprites` | 904 | The traps' set: 27 frames: the crumbling slab 0-8, the spikes 9-16, the falling column 17-18, the dust 19-24 and two more. The frame table `$CB0B` with the base `$C825` is named by five readers: CrumblingSlabFrames `$86FB`, SwitchedSpikesFrames `$873E`, FloorSwitchFrames `$87A8`, FallingColumnFrames `$888B`, ColumnDustFrames `$890C`. Read in rzx-r4 (and the switches' frame in s4-right). | `DrawActorSprite`, `PlotRow1`, `PlotRow4`, `SetActorFrame` | - |
| `$CBAD` | `PendulumSprites` | 892 | The pendulum: 15 frames (PendulumFrames `$88C0`, Pendulum `$888F`). Read in rzx-r4. | `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$CF29` | `ShotSmallBitmap` | 10 | A shot, 2 bytes x 5 lines (ShotFrames `$8098`'s first record). ShotFrames' record 0. Read by DrawShotRecord `$807C` for UpdateHeroShot `$80CC` (C = 0) in rzx-r4 (264 passes); not in s4-right. The other four records (`$CF33`, `$CF42`, `$CF51`, `$CF6B`) serve UpdateAimedShot `$803A` only. | `DrawSprite`, `DrawSpriteMirrored`, `SetActorFrame` | - |
| `$CF33` | `ShotUprightBitmaps` | 30 | Two shots, 1 byte x 15 lines (ShotFrames). ShotFrames' records 1 and 2; read by DrawShotRecord `$807C` only for UpdateAimedShot `$803A`, which no recording ran (the recordings checked: s4-right, rzx-r4); known only from the code. | `SetActorFrame` | - |
| `$CF51` | `ShotSlantedBitmaps` | 52 | Two shots, 2 bytes x 13 lines (ShotFrames). ShotFrames' records 3 and 4; read by DrawShotRecord `$807C` only for UpdateAimedShot `$803A`, which no recording ran (the recordings checked: s4-right, rzx-r4); known only from the code. | `SetActorFrame` | - |
| `$CF85` | `BoltBitmaps` | 48 | The hero's bolt: 3 frames of 2 bytes x 8 lines (HeroBoltFrames `$8169`). Read by UpdateHeroBolt in rzx-r4 (the bolts that hurt the boss). | `DrawSprite`, `SetActorFrame` | - |
| `$CFB5` | `HeadShotBitmaps` | 80 | The boss's shots: 5 frames of 2 bytes x 8 lines, one a direction (HeadShotImages `$B604`). Read in rzx-r4. | `DrawSprite`, `SetActorFrame` | - |
| `$D005` | `WaterBitmaps` | 24 | The water's surface: 3 frames of 4 bytes x 2 lines (WaterRipple `$8629` at `$8649`: `$D005` + 8 x the frame). Read in s4-right and rzx-r4. | `DrawActorSprite`, `SetActorFrame` | - |
| `$D01D` | `GameOverPicture` | 64 | GAME OVER: 8 bytes x 8 lines, drawn in the HUD's item strip (GameOverStep `$8414` at `$8433`). Read in s4-right (the game over). | `CopyToScreen`, `SetActorFrame` | - |
| `$D05D` | `BarrierSprites` | 184 | The barrier: 5 frames, the block and the pillar at four heights (BarrierSet `$9711`). Read in s4-right and rzx-r4. | `DrawActorSprite`, `SetActorFrame` | - |
| `$D115` | `MummySprites` | 828 | The mummy: 8 frames of 30 lines (MummySet `$93AE`, MummyActor `$9351`). Read in rzx-r4. | `PlotRow3`, `PlotRow4`, `SetActorFrame` | - |
| `$D451` | `ScorpionSprites` | 183 | The scorpion: 10 frames (ScorpionSet `$934D`, ScorpionActor `$9319`). Read in rzx-r4. | `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$D508` | `BossMouthSprites` | 152 | The boss's mouth: 4 frames (BossMouthFrames `$8B0E`, BossMouth `$8AD4`). Read in rzx-r4. | `DrawActorSprite`, `SetActorFrame` | - |
| `$D5A0` | `LedgeSprites` | 207 | The ledges: 5 frames (LedgeFrames `$8A1E`, BridgeLedgeFormingFrames `$8A55`, BridgeLedgeFrames `$8A84`). Read in rzx-r4. | `DrawActorSprite`, `PlotRow3`, `SetActorFrame` | - |
| `$D66F` | `DiscBitmap` | 32 | The altar's disc: 2 bytes x 16 lines (AltarDisc `$8931` at `$8963`). Read in rzx-r4. | `DrawActorSprite`, `SetActorFrame` | - |
| `$D68F` | `ObjectSprites` | 246 | The objects: 9 frames, urns and chests (StrikeableActorSet `$A993`), frame 7 the urn and frame 8 the cross of the urn markers (UrnMarkerFrames `$8B35`). Read in s4-right and rzx-r4. | `DrawActorSprite`, `PlotRow1`, `SetActorFrame` | - |
| `$D785` | `HeroStrikeSprites` | 854 | The hero's strikes and throw: 16 frames (HeroStrikeLowSet `$AFB5`, HeroStrikeMidSet `$AFFC`, HeroStrikeHighSet `$B046`, HeroThrowSet `$B092`). Read in s4-right and rzx-r4. | `PlotRow1`, `PlotRow2`, `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$DADB` | `EnergyBarPattern` | 6 | The energy bar's pattern: 6 bytes, one pixel line (DrawEnergyBar `$A54D` at `$A57B`). Read in s4-right and rzx-r4. | `DrawEnergyBar` | - |
| `$DAE1` | `HeroJumpSprites` | 963 | The hero's jump: 19 frames (HeroJumpSet `$B25D`). Read in s4-right and rzx-r4. | `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3`, `PlotRow3Mirrored`, `SetActorFrame` | - |
| `$DEA4` | `HeroWalkSprites` | 693 | The hero's walk and stand: 13 frames (HeroStandSet `$AF11`, HeroWalkSet `$B17E`). Read in s4-right and rzx-r4. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `PlotRow3` +3 | - |
| `$E159` | `UnreadBitmap` | 30 | 30 bytes no code reads: a picture of 2 bytes x 15 lines. No instruction or word of the block points into `$E159-$E176`, and neither recording read it (s4-right, rzx-r4); kept as a leftover. | `SetActorFrame` | - |
| `$E177` | `FragmentSprites` | 264 | A fragment: 8 copies of 3 bytes x 11 lines, shifted 0-7 pixels (MoveFragment `$AB35` at `$AB6D`: `$E177` + 33 x the shift). Read in s4-right and rzx-r4. | `SetActorFrame` | - |
| `$E27F` | `PieceSprites` | 28 of 292 | A piece of the stage's artefact: 10 frames (PieceFrames `$82A0`); the first two also the HUD's piece pictures. Read in rzx-r4 (the pieces) and s4-right (the HUD). | `CopyToScreen`, `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$E29B` | `PieceSprite1` (`PieceSprites`+28) | 264 | frame 1's bitmap, the HUD's taken piece | `CopyToScreen`, `PlotRow2`, `PlotRow3`, `SetActorFrame` | - |
| `$E3A3` | `ItemIconBitmaps` | 288 | The item icons: 9 of 2 bytes x 16 lines (ItemIcons `$7F75`: kinds 9, 8, 3, 2, 6, 0, 1, 5, 7 in memory order; kind 4 is BlankIcon). DrawItemIcon draws them in the HUD's strip and the item window; SpawnItem's callers give an item actor its icon (StrikeableKind9 `$A997`, DropItemKind1 `$A2D0` and the others). Read in s4-right and rzx-r4. | `DrawItemIcon`, `PlotRow2` | - |
| `$E4C3` | `ThrownBitmaps` | 156 | Thrown items: 4 frames of 3 bytes x 13 lines (ImageDescriptors `$B62D`). Only the first two are read (ImageDescriptors' first two records, the thrown item, missile kinds 5 and 6); the other two frames have no reader (known only from the code). | `UpdatePathFlyer` | - |
| `$E55F` | `ThrownSmallBitmaps` | 120 | 5 frames of 3 bytes x 8 lines (ImageDescriptors' last five records, which no code reads). No reader (known only from the code): ImageDescriptors names them but only its first two records are read. | - | - |
| `$E5D7` | `HeroLeapSprites` | 601 | The hero's leap: 14 frames (HeroLeapSet `$B29A`). Read in s4-right and rzx-r4. | `PlotRow1`, `PlotRow1Mirrored`, `PlotRow2`, `PlotRow2Mirrored`, `SetActorFrame` | - |
| `$E830` | `UnreadE830` | 10 | 10 bytes no code reads (`$00` `$00` `$00` `$00` `$05` `$02` `$00` `$00` `$00` `$00`). No instruction or word of the block points into `$E830-$E839`; neither recording read it. | - | - |
| `$E83A` | `ParticleGlyphs` | 32 | The burst's 4 particle glyphs, 1 byte x 8 lines each (UpdateBurst `$A41D`: BurstGlyphs[...] x 8 + `$E83A`). Read in s4-right and rzx-r4. | `UpdateBurst` | - |
| `$E85A` | `BurstGlyphs` | 35 | The glyph (0-3) of each burst step, indexed by the step + a random 0-3 (35 bytes). Read by UpdateBurst in s4-right and rzx-r4. | `UpdateBurst` | - |
| `$E87D` | `BurstDirections` | 192 | The step lists of the 6 burst directions, 32 bytes each (UpdateBurst: `$E87D` + direction x 32, indexed by the step). Read by UpdateBurst in s4-right and rzx-r4. | `UpdateBurst` | - |
| `$E93D` | `BossBurstShape` | 24 | The shape the beaten boss bursts into: 2 bytes x 12 lines (BossBeaten `$A24C` at `$A295`). Read in rzx-r4. | `StartBurst`, `UpdateBurst` | - |
| `$E955` | `UnreadE955` | 6 | 6 bytes after the boss's burst shape that StartBurst never reads (it reads 24). StartBurst reads 24 bytes of BurstBossShapes and stops before these. Not read in any recording (the recordings checked: s4-right, rzx-r4); known only from the code. | - | - |
| `$E95B` | `BurstShapes` | 48 | Two burst shapes of 2 bytes x 12 lines: `$E95B` (ScoreBurst20 `$A1C8`, ScoreBurst200 `$A221`) and `$E973` (ScoreBurst80 `$A1FB`, the mummy). StartBurst `$A385` reads 24 bytes from the shape's address. Read in s4-right and rzx-r4. | `StartBurst` | - |
| `$E98B` | `UnusedE98B` | 1716 | 1716 zero bytes to the block's end, which no code reads (s4-right, rzx-r4); zero as loaded | - | - |


## Stage 5 (TZX block 52) (`src/stage5/stage5.json`)

Myth: History in the Making, System 3 Software 1989: stage 5 (TZX block 52), 33 792 bytes loaded at `$6C3F` by the
resident stage loader over `$6C3F-$F03E` (tools/image.py). Its entries are `src/stage5/<module>.asm`, written from
`src/stage5/stage5.ann` by `kit/mkgame.py --part src/stage5/stage5.json`; the readers and writers from
`work/stage1/rec/s5-right`, `work/stage2/rec/rzx-r5`, `work/stage2/rec/ending`.

### Stage 5 (TZX block 52): variables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6C3F` | `PlayBufferTail` | 193 | The last 193 bytes of the play buffer PlayBuffer `$5B00-$6CFF`. ClearBuffer `$96AC` clears the play buffer to `$6CFF` with PUSH HL. In stage 5 the buffer holds the two text pages from PlayBuffer `$5B00` to `$68FF`; this tail is not written or read by stage 5's code (no recording reads or writes `$6C3F-$6CFF`: s5-right, rzx-r5, ending). Zero as loaded. | - | - |
| `$6D00` | `ShadowAttributes` | 192 of 768 | The shadow of the screen's 768 attributes, the screen's layout. StageSetUp `$95E4` copies the HUD's colours into rows 0-5 and shows the whole shadow (ShowShadowAttributes `$95B0`); FillShadowAttributes `$957F` paints its boxes into it (HudBox1-4, the play area black). The rest of stage 5 colours the screen's attributes directly (Attributes `$5800`). s5-right: 896 bytes written (`$6D00-$707F`, with the missile records), 9350 reads at most. Zero as loaded. | `ClearShadowAttributes`, `ShowShadowAttributes` | `ClearShadowAttributes`, `FillShadowAttributes`, `SaveAttributes`, `StageSetUp`, `HideLeadingZeros` (code) |
| `$6DC0` | `PlayAttributes` (`ShadowAttributes`+192) | 576 | row 6: the first row of the play area (AttrShadowAddress `$A000`, kept from stage 1, no caller) | `ClearShadowAttributes`, `ShowShadowAttributes` | `ClearShadowAttributes`, `FillShadowAttributes`, `SaveAttributes` |
| `$7000` | `HudPicture` | 48 of 1728 | The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their colours at `$7600` (6 rows of 32). The same 1728 bytes as stage 1's (src/res/stage1/picture-hud-32x48.png). DissolveHud `$941B` dissolves the 48 lines onto the screen's lines 0-47 and StageSetUp `$95E4` copies the 192 colours into the shadow rows 0-5, once, at the stage's start. EndStage `$78B5` saves the screen's lines 0-47 back here (`$78CC` copies the colours to HudColours `$7600`, CopyScreenToBlock `$93F3` the lines to `$7000`) before the next block is loaded. In play the picture's space holds the records below. s5-right reads `$6D00-$76BF` (the dissolve and the records) and writes `$7000-$707F` and `$75E0-$766F`. | `CheckShotHitsHero`, `ClearHeroShots`, `ClearMissiles`, `CopyToScreen`, `DissolveHud` +10 | `ClearHeroShots`, `ClearMissiles`, `DameronFire`, `FreeShot`, `HeroFire` +9 |
| `$7030` | `MissilesEnd` (`HudPicture`+48) | 208 | the stray ninth record FindFreeMissile `$8C6C` returns when all eight are busy; UpdateDameronMissiles `$804A` never reads it | `ClearMissiles`, `DissolveHud` | `ClearMissiles`, `DameronFire`, `NextDameronForm` |
| `$7100` | `Particles` (`HudPicture`+256) | 992 | in play, at the duel's end: the burst's particles, 4 bytes each, `$FF` ends the list (StartBurst `$91B9`, UpdateBurst) | `DissolveHud`, `UpdateBurst` | `StartBurst`, `UpdateBurst` |
| `$74E0` | `ActorRecords` (`HudPicture`+1248) | 256 | stage 1's hero and actor records (14 x 18 bytes): only stage 1's routines left in the block with no caller (SpawnActor `$9E9C`, RunActorHandlers `$9EB7`, ClearActors `$95BD`) touch them | `DissolveHud` | `ClearActors` (code) |
| `$75E0` | `HeroShots` (`HudPicture`+1504) | 32 | in play: the hero's 16 shot records, 8 bytes each (`$75E0-$765F`; +0 the column, `$FF` free, `$FE` ending; +1 the line; +2/+3 the screen address), ClearHeroShots `$7F02` | `ClearHeroShots`, `DissolveHud`, `DrawShots`, `FindShotSlot`, `HeroFire` +1 | `ClearHeroShots`, `HeroFire`, `MoveShots`, `ClearShots` (code) |
| `$7600` | `HudColours` (`HudPicture`+1536) | 16 | the HUD's 192 colours as loaded (rows 0-5); in play the hero's shot records 4-15 lie over them | `ClearHeroShots`, `DrawShots`, `FindShotSlot`, `HeroFire`, `MoveShots` +1 | `ClearHeroShots`, `HeroFire`, `MoveShots` |
| `$7610` | `HeroShots6` (`HudPicture`+1552) | 48 | shot record 6; stage 1's AddMissileHigh `$9F60` (kept, no caller) would write its missile records 8-15 here | `ClearHeroShots`, `DrawShots`, `FindShotSlot`, `HeroFire`, `MoveShots` +1 | `ClearHeroShots`, `HeroFire`, `MoveShots` |
| `$7640` | `DigitBuffer` (`HudPicture`+1600) | 32 | at the stage's start: the score's digit picture (RenderScore `$7B14`, RevealScore `$967E`), before ClearHeroShots fills `$75E0-$765F` with `$FF`; also the item count's digits (FormatItemCount, no caller from play) | `ClearHeroShots`, `CopyToScreen`, `DrawShots`, `FindShotSlot`, `HeroFire` +2 | `ClearHeroShots`, `HeroFire`, `MoveShots`, `RenderDigits` |
| `$7660` | `HudColoursRest` (`HudPicture`+1632) | 96 | the colours of rows 3-5 past the shot records | `CopyToScreen`, `StageSetUp` | `RenderDigits` |
| `$76C0` | `Unused76C0` | 320 | 320 bytes (`$76C0-$77FF`) no stage-5 code reads or writes. Stage 1's span table room (`$76A0-$779B`) and its unused tail. Stage 5 copies no spans: no operand of its code names `$7680-$77FF` (checked over the listing `$7800-$A366`), and no recording (s5-right, rzx-r5, ending) reads or writes any of it. Zero as loaded. | - | - |
| `$BA7E` | `HeroRecord` | 1 of 8 | The hero's record: +0 X in pixels, +1 the screen line, +4 the state, +5 the frame, +6 the game-over count. InitHero `$7EE9` sets X `$40`, line `$68`, state 0, the count `$5A`; HeroControl `$7F1E` moves it (X `$12-$66`, line `$40-$96`) and steps the explosion; DrawHero `$8576` and DrawHeroFrame `$9D85` draw it; CheckShotHitsHero `$A33E` tests the missiles against +0, +1. +2, +3 and +7 are read by no code. The bytes as loaded (`$CC` `$7F` `$C1` `$04` `$00` `$03` `$1F` `$2B`) are overwritten by InitHero before any read. s5-right: 16034 reads of +0/+1, the state 16187. | `ApplyEnergyChange`, `CheckShotHitsHero`, `DameronFire`, `DrawHero`, `DrawHeroFrame` +9 | `ApplyEnergyChange`, `HeroControl`, `HeroDown`, `HeroLeft`, `HeroRight` +3 |
| `$BA7F` | `HeroLine` (`HeroRecord`+1) | 1 | +1 the screen line | `CheckShotHitsHero`, `DrawHero`, `DrawHeroFrame`, `HeroDown`, `HeroFire` +1 | `HeroDown`, `HeroUp`, `InitHero` |
| `$BA80` | `HeroUnused2` (`HeroRecord`+2) | 2 | +2, +3: no reader | - | - |
| `$BA82` | `HeroState` (`HeroRecord`+4) | 1 | +4: 0 flying, 1 exploding, 2 re-forming, 3 game over | `ApplyEnergyChange`, `DameronFire`, `DrawHero`, `HeroControl`, `HeroFire` +1 | `ApplyEnergyChange`, `HeroControl`, `InitHero`, `LoseLife` (code) |
| `$BA83` | `HeroFrame` (`HeroRecord`+5) | 1 | +5 the explosion's frame | `DrawHeroFrame`, `HeroControl` | `HeroControl`, `InitHero` |
| `$BA84` | `HeroGameOverCount` (`HeroRecord`+6) | 1 | +6: `$5A`, - 1 on each even pass in state 3; at 0 MainLoop ends the stage (E = 0) | `HeroControl`, `StageEntry`, `MainLoop` (code) | `HeroControl`, `InitHero` |
| `$BA85` | `HeroUnused7` (`HeroRecord`+7) | 1 | +7: no reader | - | - |
| `$BA86` | `Stars` | 64 | The 16 stars, 4 bytes each: +0 X in pixels, +1 the screen line, +2 the speed (0 slow, 1 fast), +3 a counter. InitStars `$85F9` seeds them; MoveStars `$8627` moves them (4 or 8 pixels a pass to the left) and gives a wrapped star a new line; DrawStars `$8672` draws them. The bytes as loaded are overwritten by InitStars. s5-right: 13441 reads. | `DrawStar`, `DrawStars`, `MoveStars` | `InitStars`, `MoveStars` |

### Stage 5 (TZX block 52): entry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$960D` | `HudBox1` | 5 | FillShadowAttributes' data: column 6, line 8, width 6, height 1, colour `$41` (bright blue on black) | `FillShadowAttributes` | - |
| `$9615` | `HudBox2` | 5 | column 10, line 24, width 12, height 2, colour `$41` | `FillShadowAttributes` | - |
| `$961D` | `HudBox3` | 5 | column 15, line 8, width 2, height 1, colour `$41` | `FillShadowAttributes` | - |
| `$9625` | `HudBox4` | 5 | the play area: column 2, line 48, width 28, height 18, colour 0 (black) | `FillShadowAttributes` | - |

### Stage 5 (TZX block 52): mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$78BC` | `EndPiecesBox` | 5 | `$954E`'s inline record: column 25, line 24, 6 x 2 cells, attribute 1 (the pieces boxes hidden). Read by FillAttributes `$954E` (@inline 5) after the CALL at `$78B9`: column, line, width and height in cells, attribute. | - | - |
| `$78C4` | `EndLivesBox` | 5 | `$954E`'s inline record: column 1, line 24, 6 x 2 cells, attribute 1 (the lives boxes hidden). Read by FillAttributes `$954E` after the CALL at EndStageLives `$78C1`, in EndPiecesBox's format. | - | - |

### Stage 5 (TZX block 52): render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$938E` | `SpriteFrameOffsets` | 48 | The offset of each of the 24 sprite frames in the bank `$B3BA`. 0, `$30` ... `$150` (frames 0-7, 48 bytes each: 3 bytes x 16 lines), `$180`, `$19B`, `$1B6`, `$1D1` (frame 8 27 bytes after frame 7's 48; frames 8-11 27 bytes: 3 x 9), `$1EC`, `$234` (frames 12-13, 72 bytes: 3 x 24), `$27C` (frame 14, 144 bytes to the next), `$30C`, `$354` ... `$54C` (frames 15-23, 72 bytes apart). Read by SpriteFrameAddress (`$937F`). | `SpriteFrameAddress`, `UpdateBurst` | - |
| `$97A5` | `StageScreenLines` | 96 of 384 | The screen address of each of the 192 pixel lines (a copy of the resident ScreenLineTable `$FB00`). Words Screen `$4000`, `$4100` ... `$57E0`. Read from line 48 on (ScreenLinePlay) by `$8838` (Dameron's head) and MoveCurvedShot `$9E1E`: a play-area line Y is ScreenLinePlay + 2Y. s5-right read none of its bytes through LD (the head walks it with POP, which the recordings do not count as reads); rzx-r5 and ending read 284 of them (MoveCurvedShot). | `MoveCurvedShot` | - |
| `$9805` | `ScreenLinePlay` (`StageScreenLines`+96) | 288 | line 48: the play area's top line | `MoveCurvedShot` | - |
| `$9925` | `BlankTextLine` | 96 | 96 zero bytes: a blank text page, copied by ClearTextArea over the seven text lines. Read by ClearTextArea (`$8D49` ... `$8D7F`, seven times 96 bytes) when the intro ends. | `CopyTextLine`, `MoveCurvedShot` | - |
| `$9985` | `UnusedZeros1` | 272 | 272 zero bytes after BlankTextLine: no code reads them. No operand names `$9985-$9A94` and no recording (s5-right, rzx-r5, ending) read any of them. | - | - |
| `$9A95` | `PlayLineTable` | 96 of 384 | The screen address of each pixel line, 0 for the HUD's lines 0-47. 192 words: 48 zeros (lines 0-47), then `$40C0` ... `$57E0` (lines 48-191). Read by UpdateBurst (`$914B`) and EraseParticle (`$9355`) at the word of line row x 8: a particle in the HUD rows gets address 0 + X and writes into the ROM. | `EraseParticle`, `UpdateBurst` | - |
| `$9AF5` | `PlayLineTablePlay` (`PlayLineTable`+96) | 288 | line 48 | `EraseParticle`, `UpdateBurst` | - |
| `$9C15` | `UnusedZeros2` | 368 | 368 zero bytes after PlayLineTable: only the burst's overrun reads four of them. No operand names `$9C15-$9D84`. rzx-r5 and ending read `$9C15`/`$9C16` and `$9C25`/`$9C26`: UpdateBurst and EraseParticle look up the word of line row x 8 past the table's end for particles below the screen. The rest no code reads. | `EraseParticle`, `UpdateBurst` | - |
| `$A02F` | `CycleColours` | 8 | The colour cycle: bright yellow, cyan, green, magenta, red, magenta, green, cyan. `$46`, `$45`, `$44`, `$43`, `$42`, `$43`, `$44`, `$45` (bright ink on black). Read by CycleColour (`$A029`). | `CycleColour` | - |

### Stage 5 (TZX block 52): duel

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7AD7` | `FinalBurstShape` | 24 | The final burst's shape: 12 rows of 16 bits, bits 7-14 set (a block 8 fragments wide, 12 high). Read by StartBurst `$91B9` (IX = `$7AD7`, D = 12, E = 9, A = 1) from `$A0E2`, at phase 4 (Dameron beaten): each set bit (bit 7 of the first byte first) puts a burst fragment at column D + bit, row E + row. Every row is `$01`, `$FE`. | `StartBurst` | - |
| `$7AEF` | `FinalBurstShapeTail` | 4 | Two more rows of FinalBurstShape's pattern that no code reads. StartBurst `$91B9` reads 24 bytes (12 rows of 2); these 4 bytes (`$01`, `$FE`, `$01`, `$FE`) continue the pattern up to AddScore. No code reads them: no operand points into them, and StartBurst `$91B9` stops after 24 bytes. | - | - |
| `$8A28` | `DameronPath` | 256 | Dameron's path after the approach: 128 steps of (dX, dY), dX always 0, dY +1 or -1. Read by DuelStep at DameronPath + 2 x the path index DameronPathIndex `$FE40` (a byte, so 128 steps that repeat): X += dX, Y += dY each pass. Twice: up 20, down 6, up 6, down 20, up 6, down 6 (no net move). | `DuelStep` | - |
| `$8B28` | `DameronApproachStep` | 2 | The approach's step (dX 0, dY -1): Dameron climbs from Y `$8E` to `$14`. Read by DuelStep until the arrival flag DameronArrived `$FE3D` is set. | `DuelStep` | - |
| `$918A` | `UnusedRet` | 1 | A RET no code reaches. After UpdateBurst's JP UpdateBurstLoop; no CALL, JP or word in stage 5's block names `$918A` (work/stage2/stage5/B-raw.py). | - | - |
| `$9191` | `BurstSteps` | 20 of 40 | 20 (dx, dy) steps: 10 for the right-byte particles, 10 for the left-byte ones. Signed bytes (-1, 0, 1): dx added to the column, dy taken from the character row. UpdateBurst reads the pair BurstSteps + 2 x the index (`$90FA`; + `$14` for the directions 0-5). The same use as stage 1's BurstSteps `$A39D`. | `UpdateBurst` | - |
| `$91A5` | `BurstStepsLeft` (`BurstSteps`+20) | 20 | the second set: the shape's left-byte particles (directions 0-5) | `UpdateBurst` | - |
| `$9230` | `BurstGlyphs` | 32 of 56 | The burst's 8 x 8 particle glyphs: 0-3 from dense to sparse, 4-6 blank. UpdateBurst writes BurstGlyphs + 8 x BurstGlyphSteps[...] into ParticleGlyph (`$90AF`); the indexes 0-3 are the four patterns, 4-6 (read only on the extra step `$65`, see UpdateBurst) are blank. | `UpdateBurst` | - |
| `$9250` | `BurstGlyphBlank` (`BurstGlyphs`+32) | 24 | glyphs 4-6: zeros | `UpdateBurst` | - |
| `$9268` | `BurstUnused` | 4 | Four zero bytes between the glyphs and BurstGlyphSteps. No code reads them (UpdateBurst's glyph indexes stop at 6). | - | - |
| `$926C` | `BurstGlyphSteps` | 35 | The glyph (0-3) at each burst step: index = step + a Random 0-3. 35 bytes: 1, 0 at the first steps, then 1, 2 and 3, 2: the particles grow sparser as they fly. Read by UpdateBurst (`$90A2`: step 0-`$1B` + 0-3, the first 31 bytes; the extra step `$65` reads past the table). | `UpdateBurst` | - |
| `$928F` | `BurstDirections` | 160 | Six direction tables of 32 step indexes (0-6 into BurstSteps); the first five here. UpdateBurst reads BurstDirections + direction x 32 + (step + 0-3) (`$90DA`; the sum doubled in the small mode). The sixth table (direction 5, BurstDirectionsCut `$932F`) has only 26 bytes before EraseParticle's code at EraseParticle `$9349`: its indexes 26-31 read code bytes, and the small mode's doubled indexes up to 32 reach `$934F`. | `UpdateBurst` | - |
| `$932F` | `BurstDirectionsCut` | 26 | The sixth direction table (direction 5), cut to 26 bytes by EraseParticle's code. Its indexes 26-31 (and the small mode's doubled ones up to 32) would read the code bytes of EraseParticle `$9349` on: UpdateBurst does not check the table's end. rzx-r5 and ending read 13 of its bytes and 4 bytes of EraseParticle `$9349` on: the overrun happens. | `UpdateBurst` | - |
| `$A0E9` | `UnusedRet2` | 1 | A RET no code reaches. After NextDameronForm's JP StartBurst; no CALL, JP or word in stage 5's block names `$A0E9` (work/stage2/stage5/B-raw.py). | - | - |

### Stage 5 (TZX block 52): hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7BC2` | `ScoreDigits` | 2 of 9 | The score as text: two unused bytes, ScoreHigh's two digits, Score's four digits, 0. Written by RenderScore (NumberToDigits `$94F0` at ScoreDigitsLow, ByteToDigits `$9524` at ScoreDigitsHigh), read by RenderDigits and HideLeadingZeros; EndStage returns ScoreDigitsHigh in BC. Loaded as 0, 0, '000000', 0. | `RenderDigits` | `ByteToDigits`, `NumberToDigits` |
| `$7BC4` | `ScoreDigitsHigh` (`ScoreDigits`+2) | 2 | ScoreHigh's two digits (`$9524`); EndStage returns this address in BC | `RenderDigits` | `ByteToDigits` |
| `$7BC6` | `ScoreDigitsLow` (`ScoreDigits`+4) | 4 | Score's four digits (`$94F0`) | `RenderDigits` | `NumberToDigits` |
| `$7BCA` | `ScoreDigitsEnd` (`ScoreDigits`+8) | 1 | 0: the end mark | `RenderDigits` | - |
| `$7ED4` | `GameOverBox` | 5 | `$954E`'s inline record: column 12, line 24, 8 x 2 cells, the colour (patched). Read by FillAttributes `$954E` after the CALL at `$7ED1`; GameOverStep writes the colour (the last byte, `$7ED8`). | - | `GameOverColour` (code) |
| `$94B0` | `BlankIcon` | 32 | 32 zero bytes: a blank source for clears done by copying. Read by `$7EAF` (LD HL,`$94B0`, then BC = `$0A18`, DE = `$0C10`: a copy to the screen); s5-right read each of its bytes 9 times. Stage 1's BlankIcon `$8BA3` (the blank item icon and the source of the clears done by copying with stride 0). | `DrawItemIcon` | - |
| `$979D` | `BarMasks` | 8 | The bar's last byte: 0 to 7 pixels from the left (`$00`, `$80`, `$C0` ... `$FE`). Read by DrawEnergyBar (`$975B`) with Energy AND 7. | `DrawEnergyBar` | - |

### Stage 5 (TZX block 52): hero

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7C27` | `SelectedBoxRecord` | 5 | `$954E`'s inline record: column 15, line 24, 2 x 2 cells, the colour (patched). Read by FillAttributes `$954E` after the CALL at `$7C24`; FlashSelectedBox writes its last byte (the colour, 2 to 6). | `FillAttributes` | `FlashSelectedBoxFrame` |
| `$7CC2` | `WindowFrameColours` | 16 | The frame's 16 inks: 1 to 7 and back. 16 bytes, read by CycleWindowFrame at PassCounter AND 15: 1-7, 7, 7, 6-1. Read in no recording (s5-right, rzx-r5, ending). | - | - |
| `$7D7A` | `ItemCountText` | 5 | The count as text for RenderDigits: two unused bytes, two digits, 0. Written by FormatItemCount (+2 the tens, +3 the units), read by RenderDigits and ShowItemCount. Loaded as 0, 0, '00', 0. | - | - |
| `$7E67` | `CarriedItems` | 12 | The item kind of each of the 12 slots (slots 0-3 hold 4, the blank icon; slot 6 holds 8). Copied from StartItems by InitStageState `$96DD` at the start; read by DrawItemStrip (CarriedItems + ItemSelected - 3, 8 slots). Loaded as a copy of StartItems. | `DrawItemStrip` | `InitStageState` |
| `$7E73` | `CarriedCounts` | 12 | The amount of each slot's item (read by FormatItemCount). Read by FormatItemCount at CarriedCounts + ItemSelected. All 0; no stage-5 code writes them. | - | - |
| `$7E7F` | `StartItems` | 12 | The carried items at the stage's start, copied to CarriedItems by `$96DD`: slots 0-3 kind 4 (blank), slot 6 kind 8. The 12 bytes `$04`, `$04`, `$04`, `$04`, 0, 0, `$08`, 0, 0, 0, 0, 0. InitStageState `$96DD` copies them with LDIR to CarriedItems. | `InitStageState` | - |
| `$7E8B` | `ItemIcons` | 18 | The 16 x 16 icon of each item kind 0-8 (32 bytes each; kind 4 points to the blank `$94B0`). Read by DrawItemIcon at ItemIcons + 2 x kind: ItemIcon0 `$BA38`, ItemIcon1 `$B9F8`, ItemIcons16 `$B958`, ItemIcon3 `$B9B8`, BlankIcon `$94B0`, ItemIcon5 `$B998`, ItemIcon6 `$B978`, ItemIcons16 `$B958`, ItemIcon8 `$B9D8`. | `DrawItemIcon` | - |
| `$856C` | `ShotGraphic` | 10 | The hero's shot: 5 lines of 2 bytes. Read by DrawShots (LDI, 2 bytes a line). | `DrawShots` | - |
| `$85D9` | `HeroFrames` | 32 | The hero's 16 frames: 4 animation steps x 4 shifts (0, 2, 4, 6 pixels), 72 bytes each. Read by DrawHero at HeroFrames + ((PassCounter AND 7) / 2) x 8 + (X AND 6). Steps 0-2 at `$BB1C-$BE34`; step 3 repeats step 1 (`$BC3C-$BD14`). | `DrawHero` | - |

### Stage 5 (TZX block 52): missiles

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$840B` | `ArcSteps0` | 23 | The arcing shot's line step a pass, path 0: -4 x 4 ... +5, `$64` ends (23 bytes). Read by MoveCurvedShot `$9DC6` (kind 2) at ArcSteps + the step +4 for the path +3 = 0: the line +1 changes by the signed byte; `$64` holds the last step (+4 - 1 and read again). Paths 0-3 are chosen by DameronFire in form 3 ((PassCounter / 16) AND 3). | `MoveCurvedShot` | - |
| `$8422` | `ArcSteps1` | 18 | Path 1: -4 ... +5, `$64` ends (18 bytes). As ArcSteps0, for +3 = 1. | `MoveCurvedShot` | - |
| `$8434` | `ArcSteps2` | 14 | Path 2: -3 ... +5, `$64` ends (14 bytes). As ArcSteps0, for +3 = 2. | `MoveCurvedShot` | - |
| `$8442` | `ArcSteps3` | 34 | Path 3: -3, -2 x 4, -1 x 8, 0, +1 x 8 ... +5, `$64` ends (34 bytes). As ArcSteps0, for +3 = 3 (the longest, flattest arc). | `MoveCurvedShot` | - |
| `$9E94` | `CurvedShotFrames` | 8 | The curved shot's frames: 4, 5, 6, 7, then 7, 6, 5, 4. MoveCurvedShot reads the first four (`$9E3D`, PassCounter AND 3); the second four, the ping-pong's way back, are read by no code. | `MoveCurvedShot` | - |
| `$9FE7` | `MissileHandlers` | 2 | The handler of missile type 0: `$7EE2`. One word; a type 1 or more would read BufferAddressHL's code bytes as the handler. Read only by UpdateMissiles (`$9FCD`). | - | - |

### Stage 5 (TZX block 52): texts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8E0D` | `IntroText` | 12 of 108 | The intro's seven lines: each 3 header bytes, the characters, 0. Format of a line (DrawTextLine): byte 0 the start column in bytes (0-11) within the 12-byte line, byte 1 the start pixel offset (0-7), byte 2 a byte stored in TextScratch `$FE4B` and never used for the text, then ASCII characters (A-Z, space, `\` drawn as a full stop; digits would index past TextFont), then 0. All headers here are 0, 0, 0: every line starts at the left edge. The text, as printed (sic): HURTLING / ACROSS THE / VOID OF SPACE. / PRAPARE TO / CONFRONT THE / EVIL ANGEL OF / TIME.DAMERON. Read once by DrawIntroText through IY (DrawTextLine). | `DrawTextLine` | - |
| `$8E19` | `IntroLine2` (`IntroText`+12) | 14 | "ACROSS THE" | `DrawTextLine` | - |
| `$8E27` | `IntroLine3` (`IntroText`+26) | 18 | "VOID OF SPACE." | `DrawTextLine` | - |
| `$8E39` | `IntroLine4` (`IntroText`+44) | 14 | "PRAPARE TO" (sic) | `DrawTextLine` | - |
| `$8E47` | `IntroLine5` (`IntroText`+58) | 16 | "CONFRONT THE" | `DrawTextLine` | - |
| `$8E57` | `IntroLine6` (`IntroText`+74) | 17 | "EVIL ANGEL OF" | `DrawTextLine` | - |
| `$8E68` | `IntroLine7` (`IntroText`+91) | 17 | "TIME.DAMERON." | `DrawTextLine` | - |
| `$8E79` | `EndingText` | 14 of 100 | The ending's seven lines, in IntroText's format. WELL DONE. / YOUR TASK / IS COMPLETE. / HISTORY IS / RESTORED AND / DAMERON IS / BANISHED. Read once by DrawEndingText (DrawTextLine); shown by ShowEnding once Dameron is beaten (phase 4). The text is drawn into the second page at the stage start (read once in every recording); rzx-r5 and ending reached the ending page (ShowEnding `$8CEF` 841 and 3284 passes). | `DrawTextLine` | - |
| `$8E87` | `EndingLine2` (`EndingText`+14) | 13 | "YOUR TASK" | `DrawTextLine` | - |
| `$8E94` | `EndingLine3` (`EndingText`+27) | 16 | "IS COMPLETE." | `DrawTextLine` | - |
| `$8EA4` | `EndingLine4` (`EndingText`+43) | 14 | "HISTORY IS" | `DrawTextLine` | - |
| `$8EB2` | `EndingLine5` (`EndingText`+57) | 16 | "RESTORED AND" | `DrawTextLine` | - |
| `$8EC2` | `EndingLine6` (`EndingText`+73) | 14 | "DAMERON IS" | `DrawTextLine` | - |
| `$8ED0` | `EndingLine7` (`EndingText`+87) | 13 | "BANISHED." | `DrawTextLine` | - |
| `$8F96` | `TextFont` | 208 of 224 | The texts' proportional font: 28 glyphs of 8 bytes, A-Z, space, full stop. Each glyph: byte 0 the width mask (bits set from bit 7 for the glyph's pixel columns; the advance, 9 less the trailing zeros, adds the gap: `$FE` for A, B, D, N, O, Q, R, Y, Z; `$FC` for C, E, F, G, H, J, K, P, S, T, U, V, X; `$F8` for L and space; `$F0` for I and the full stop; `$FF` for M and W), then 7 rows of pixels (bit 7 the left). Read by DrawTextGlyph `$8F20` (TextFont + 8 x the index). Indexes 28-36 (the digits) would read past it into UpdateBurst's code; no text has a digit. | `DrawTextLine` | - |
| `$9066` | `TextFontSpace` (`TextFont`+208) | 8 | glyph 26: space (blank) | `DrawTextLine` | - |
| `$906E` | `TextFontStop` (`TextFont`+216) | 8 | glyph 27: the full stop, written `\` in the texts | `DrawTextLine` | - |

### Stage 5 (TZX block 52): graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A367` | `GameOverPicture` | 64 | GAME OVER: 8 bytes x 8 lines (the last line blank). GameOverStep `$7E9D` copies it to column 12, line `$1C` of the item strip (CopyToScreen `$7979`, BC = `$0C1C`, DE = `$0808`) when GameOverTimer reaches `$31`. Nothing in stage 5 sets GameOverTimer, so it is never shown: not read in s5-right; known only from the code (`$7EBD`). | - | - |
| `$A3A7` | `UnusedA3A7` | 89 | 89 zero bytes no code reads (no operand names `$A3A7-$A3FF`; no recording reads any) | - | - |
| `$A400` | `StarSlow` | 9 of 18 | The slow star: two frames of 3 bytes x 3 lines (`$A400`, `$A409`). DrawStar `$869C` draws a slow star (+2 = 0) with the frame at `$A400` when its X AND 7 is 0, else StarSlow1 `$A409` (the star is 4 pixels on, half a byte). Read in s5-right (21103 + 10077 runs of the copy). | `DrawStar` | - |
| `$A409` | `StarSlow1` (`StarSlow`+9) | 9 | frame 1: the star 4 pixels to the right | `DrawStar` | - |
| `$A412` | `StarFast` | 20 of 40 | The fast star: two frames of 4 bytes x 5 lines (`$A412`, `$A426`). DrawStar `$869C` draws a fast star (+2 = 1) with `$A412` on even passes and StarFast1 `$A426` on odd ones (PassCounter bit 0): a twinkle. Read in s5-right. | `DrawStar` | - |
| `$A426` | `StarFast1` (`StarFast`+20) | 20 | frame 1: the twinkle | `DrawStar` | - |
| `$A43A` | `DameronFace0` | 896 | Dameron's face, form 0: 7 bytes x 128 lines. DrawDameronFace `$8859` copies it (phase 0) at column (DameronX + `$78`) / 8, from line 48 + DameronY, with SP walking the line table; 128 lines, or `$36` while DameronY >= `$5A`. Read in s5-right (3259 passes). | `DrawDameronFace` | - |
| `$A7BA` | `DameronDome` | 512 | The middle of Dameron's head, forms 0-2: 4 bytes x 128 lines. DrawDameronDome `$894D`, at column (DameronX + `$B0`) / 8. Read in s5-right. | `DrawDameronDome` | - |
| `$A9BA` | `DameronBack` | 512 | The back of Dameron's head (the hair), every form: 4 bytes x 128 lines. DrawDameronBack `$899C`, at column (DameronX + `$D0`) / 8. Read in s5-right. | `DrawDameronBack` | - |
| `$ABBA` | `DameronFace1` | 896 | Dameron's face, form 1: 7 bytes x 128 lines. DrawDameronFace `$8859` in phase 1 (after the first 20 counted hits). Read in rzx-r5 and ending (896 bytes); s5-right counted no hit. | `DrawDameronFace` | - |
| `$AF3A` | `DameronFace2` | 640 | Dameron's face, form 2: 5 bytes x 128 lines (the skull). DrawDameronFace `$8859` in phase 2, two columns further right. Read in rzx-r5 and ending (640 bytes). | `DrawDameronFace` | - |
| `$B1BA` | `DameronDome3` | 512 | The middle of Dameron's head, form 3 (no face): 4 bytes x 128 lines. DrawDameronDome `$894D` in phase 3. Read in rzx-r5 and ending (512 bytes). | `DrawDameronDome` | - |
| `$B3BA` | `SpriteBank` | 384 | The sprite bank, frames 0-7: 3 bytes x 16 lines (fireballs 0-3, the curved shot 4-7). The bank holds 24 frames 3 bytes wide, found through SpriteFrameOffsets `$938E`: SpriteFrameAddress `$9378` gives DE = `$B3BA` + SpriteFrameOffsets[A]. Frames 0-3 are Dameron's fireball (FireballMissile, PassCounter AND 3), 4-7 the curved shot's (MoveCurvedShot `$9DC6` through CurvedShotFrames `$9E94`). s5-right read frames 0-3 only (`$B3BA-$B479`); rzx-r5 and ending read all eight. | `MoveCurvedShot`, `UpdateMissile` | - |
| `$B53A` | `SpriteBankBolts` | 108 | The sprite bank, frames 8-11: 3 bytes x 9 lines, the bolt. BoltMissile `$834E` (kind 3, forms 1 and 2). Read in rzx-r5 and ending (all 108 bytes). | `UpdateMissile` | - |
| `$B5A6` | `SpriteBankBursts` | 72 of 936 | The sprite bank, frames 12-23: 3 bytes x 24 lines, the hero's explosion and the bursts (13 blocks of 72 bytes). Frames 12-18 are the hero's explosion and re-forming (DrawHeroFrame `$9D85`: frame +5 + 12), `$13-$17` the bursts round Dameron at a form change (kind 4). Frame 14's offset (`$27C`) is followed by 144 bytes to frame 15 (`$30C`): the 72 bytes at SpriteBankSpare `$B67E` (SpriteBank `$B3BA` + `$2C4`) are a frame no offset names, read by no code. rzx-r5 read 360 bytes of the frames, ending 792; the spare frame was read in no recording. | `DrawHeroFrame`, `UpdateMissile` | - |
| `$B5EE` | `SpriteBank13` (`SpriteBankBursts`+72) | 72 | frame 13 | `DrawHeroFrame` | - |
| `$B636` | `SpriteBank14` (`SpriteBankBursts`+144) | 72 | frame 14 | `DrawHeroFrame` | - |
| `$B67E` | `SpriteBankSpare` (`SpriteBankBursts`+216) | 72 | 72 bytes between frames 14 and 15 that no offset names: a frame no code draws | - | - |
| `$B6C6` | `SpriteBank15` (`SpriteBankBursts`+288) | 648 | frame 15 | `DrawHeroFrame`, `UpdateMissile` | - |
| `$B94E` | `UnusedB94E` | 2 | 2 zero bytes no code reads | - | - |
| `$B950` | `BitMasks` | 8 | One bit a byte, bit 7 to bit 0 (`$80`, `$40` ... `$01`): no reader. No operand of stage 5's code names `$B950-$B957` and no word in the code area points there (checked over `$7800-$A366`); no recording (s5-right, rzx-r5, ending) reads any of it. Known only from the bytes. | - | - |
| `$B958` | `ItemIcons16` | 32 of 256 | The item icons: 8 icons of 2 bytes x 16 lines (32 bytes each). DrawItemIcon `$7DD0` copies the icon ItemIcons `$7E8B` names for the kind (kind 2 and 7 `$B958`, 6 ItemIcon6 `$B978`, 5 ItemIcon5 `$B998`, 3 ItemIcon3 `$B9B8`, 8 ItemIcon8 `$B9D8`, 1 ItemIcon1 `$B9F8`, 0 ItemIcon0 `$BA38`; kind 4 is the blank BlankIcon `$94B0`). The icon at ItemIconSpare `$BA18` has no kind: no word names it. s5-right reads ItemIcon8 `$B9D8` (kind 8, the item the hero starts with) and ItemIcon0 `$BA38`. | `DrawItemIcon` | - |
| `$B978` | `ItemIcon6` (`ItemIcons16`+32) | 32 | kind 6 | - | - |
| `$B998` | `ItemIcon5` (`ItemIcons16`+64) | 32 | kind 5 | - | - |
| `$B9B8` | `ItemIcon3` (`ItemIcons16`+96) | 32 | kind 3 | - | - |
| `$B9D8` | `ItemIcon8` (`ItemIcons16`+128) | 32 | kind 8: the starting item (StartItems slot 6) | `DrawItemIcon` | - |
| `$B9F8` | `ItemIcon1` (`ItemIcons16`+160) | 32 | kind 1 | - | - |
| `$BA18` | `ItemIconSpare` (`ItemIcons16`+192) | 32 | no kind names it | - | - |
| `$BA38` | `ItemIcon0` (`ItemIcons16`+224) | 32 | kind 0 | `DrawItemIcon` | - |
| `$BA58` | `UnusedBA58` | 32 | 32 zero bytes no code reads | - | - |
| `$BA78` | `EnergyBarPattern` | 6 | The energy bar's pattern: 6 bytes, the same on each of the bar's 6 lines. DrawEnergyBar `$9744` copies its whole bytes and a last partial byte (BarMasks `$979D`) to the HUD at EnergyBarScreen `$4134`, six lines, by the energy. Read in s5-right (138 lines drawn). | `DrawEnergyBar` | - |
| `$BAC6` | `UnusedWordTable` | 86 | 43 words no code reads: 1, 1000 x 3, 900, 800, 700, 600 x 4, 500 x 2, 400, 300, 200, 100, 60 x 6, 1 x 17, then 0. A falling table of numbers (a delay or speed schedule) that no stage-5 code uses: no operand names `$BAC6-$BB1B` and no word in the code area points there (checked over `$7800-$A366`); no recording (s5-right, rzx-r5, ending) reads any of it. Known only from the bytes. | - | - |
| `$BB1C` | `HeroSprites` | 864 | The hero: 12 frames of 3 bytes x 24 lines (3 animation steps x 4 shifts of 2 pixels). DrawHero `$8576` copies the frame HeroFrames `$85D9` names (step (PassCounter AND 7) / 2, step 3 the same as step 1; the shift X AND 6) straight to the screen, no mask. Read in s5-right (1858 reads a byte at most). | `DrawHero` | - |
| `$BE7C` | `UnusedBE7C` | 7742 | 7742 zero bytes (`$BE7C-$DCB9`) no code reads | - | - |
| `$DCBA` | `StrayByte` | 1 | A lone `$7F` among the zeros: no code reads it (no operand or word names it) | - | - |
| `$DCBB` | `UnusedDCBB` | 4996 | 4996 zero bytes to the block's end (`$DCBB-$F03E`) no code reads | - | - |


## The tape BASIC (TZX block 2) (`src/tape/basic.json`)

Myth: History in the Making, System 3 Software 1989: tape block 2, the BASIC program "MYTH" (4514 bytes at PROG
`$5CCB`, LINE 0). Its entries are `src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py
--part src/tape/basic.json`; the readers and writers from `work/stage1/c1`.

### The tape BASIC (TZX block 2): basic

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine0` | 2 of 59 | Line 0: INK 0 PAPER 0 RANDOMIZE USR ((PEEK 23635+256*PEEK 23636)+10), the 10 hiding 59. The ROM's line format: the line number high byte first, the length (55) low byte first, the tokens, `$0D`. Each number in the line is its digits followed by `$0E` and the five bytes the interpreter really uses: the digits 23635, 256 and 23636 carry their own numbers, the digits 10 carry 59. Read by the ROM's interpreter in c1; no machine code reads it. | - | - |
| `$5CCD` | `BasicLineLength` (`BasicLine0`+2) | 50 | the line's length after these four bytes, low byte first: 55 | - | - |
| `$5CFF` | `BasicHiddenNumber` (`BasicLine0`+52) | 7 | the five-byte number the interpreter adds: 59 (the shown digits say 10) | - | - |
| `$5D2A` | `ChainTape` | 4418 | The decryption chain as the tape holds it (4418 bytes, copied to `$EDE4`). The bytes of `$EDE4-$FF25` before any layer ran. src/loader/chain.asm is their plain view (each byte after the last layer that rewrites it); tools/speedlock.py tape turns the plain view back into these bytes, and tools/build.sh checks the whole tape against the original. Read by CopyChain's LDIR in c1. | `CopyChain` | - |
| `$6E6C` | `BasicEnd` | 1 | The block's last byte, past the copy: a zero no code reads. CopyChain copies 4418 bytes, `$5D2A-$6E6B`; the block's 4514 bytes end one byte later. Nothing reads the zero after the ROM's load (c1: CopyChain's LDIR stops at `$6E6B`), a byte of the BASIC block left over past the chain. | - | - |


## The decryption chain and the SpeedLock loader (`src/loader/chain.json`)

Myth: History in the Making, System 3 Software 1989: the BASIC's enciphered tail in its plain view, `$EDE4-$FF25`:
the 103 layers of the decryption chain as each one runs, then the SpeedLock 7 loader as the last layer leaves it.
tools/speedlock.py masters these bytes back into the tape's (src/tape/basic.asm INCBINs the result). Its entries are
`src/loader/<module>.asm`, written from `src/loader/chain.ann` by `kit/mkgame.py --part src/loader/chain.json`; the
readers and writers from `work/stage1/c1`.

### The decryption chain and the SpeedLock loader: chain

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$EE2D` | `Layer001Gap` | 2 | 2 bytes inside layer 1 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$EE2D`). | `Layer000` | `Layer000` |
| `$EF64` | `Layer010Gap` | 2 | 2 bytes inside layer 10 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$EF64`). | `Layer000` | `Layer000` |
| `$F09B` | `Layer019Gap` | 2 | 2 bytes inside layer 19 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$F09B`). | `Layer000` | `Layer000` |
| `$F1D2` | `Layer028Gap` | 2 | 2 bytes inside layer 28 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$F1D2`). | `Layer000`, `Layer028` | `Layer000`, `Layer028` |
| `$F309` | `Layer037Gap` | 2 | 2 bytes inside layer 37 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$F309`). | `Layer000`, `Layer028` | `Layer000`, `Layer028` |
| `$F440` | `Layer046Gap` | 2 | 2 bytes inside layer 46 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$F440`). | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042` | `Layer000`, `Layer028`, `Layer039PopIx` |
| `$F577` | `Layer055Gap` | 2 | 2 bytes inside layer 55 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$F577`). | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +1 | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053` |
| `$F6AE` | `Layer064Gap` | 2 | 2 bytes inside layer 64 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$F6AE`). | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +2 | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053`, `Layer060` |
| `$F7E5` | `Layer073Gap` | 2 | 2 bytes inside layer 73 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$F7E5`). | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +3 | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053`, `Layer060` |
| `$F91C` | `Layer082Gap` | 2 | 2 bytes inside layer 82 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$F91C`). | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +3 | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053`, `Layer060` |
| `$FA53` | `Layer091Gap` | 2 | 2 bytes inside layer 91 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$FA53`). | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +3 | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053`, `Layer060` |
| `$FB70` | `Layer099Gap` | 2 | 2 bytes inside layer 99 no instruction runs (DD E9). Not executed in the chain run (SkoolKit's simulator, every instruction of the 103 layers): the layer's loop jumps over them. Kept as bytes of the block; the layers before rewrite them like their neighbours. Known only from the code (`$FB70`). | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +3 | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053`, `Layer060` |

### The decryption chain and the SpeedLock loader: reveal

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FD07` | `CountdownCounter` | 4 | The four digits as pointers' low bytes into CountdownDigits (`$80` = 0, `$C8` = 9). Read and written by CountdownTask (c1: 212 decrements). Initially 0 2 1 1. | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +4 | `CountdownTask`, `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053` +1 |

### The decryption chain and the SpeedLock loader: reader

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FEEA` | `EdgeWindows` | 14 | The seven timed pairs after the sync: the start count and the bound, a pair a row. Read by LoadStream at `$FD68` (c1). (`$E9`,`$EA`), (`$D2`,`$E2`), (`$B6`,`$E0`) three times, (`$D2`,`$E2`), (`$EC`,`$ED`). | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +4 | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053`, `Layer060` +1 |

### The decryption chain and the SpeedLock loader: timing

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FEE9` | `FailFlag` | 1 | Non-zero when the timing check failed (1 or S2's high byte) or a table mark was wrong (`$7F`). Read by Sl1End (src/loader/sl1end.asm) and by the second stage's original end. c1: 0 at the end of the load. | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer042`, `Layer052` +3 | `Layer000`, `Layer028`, `Layer039PopIx`, `Layer053`, `Layer060` +3 |


## The second stage (TZX block 7) (`src/loader/sl1.json`)

Myth: History in the Making, System 3 Software 1989: the SpeedLock loader's second stage, tape block 7, run at
`$FF26`. Its entries are `src/loader/<module>.asm`, written from `src/loader/sl1.ann` by `kit/mkgame.py --part
src/loader/sl1.json`; the readers and writers from `work/stage1/c1`.

### The second stage (TZX block 7): sl1

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FF49` | `BlockTable` | 45 of 55 | The first block table: five bytes a row, the address, the length less one, the `$7FFD` value. Read by StoreLast's table walk (c1). Rows 0-4: `$8000` 768 bytes (the loading screen's attributes, revealed by AttrRevealStart), `$DE80` 1152 (the resident's piece `$F300-$F77F`, XORed with `$DF`), `$FDB5` 2 (the body key), `$FDE9` 4 (the last-byte key), `$FF49` 55 (this table again: block 23's rows 5-10 are `$DB80` 768, `$E300` 2176, `$FE76` 115 (Unxor), `$FF3A` 15 (Sl1End), `$5B00` 33 (Boot), the end). Rows 5-7 here (`$6000` 8192 page `$13`, `$4000` 6912 page `$12`, `$FB00` 512) are never read: block 23 rewrites them first. Row 8 is the end (a zero `$7FFD` value). src/tape/tape.txt has the blocks. | - | - |
| `$FF76` | `BlockTablePad` (`BlockTable`+45) | 10 | zeros up to the digits | - | - |
| `$FF80` | `CountdownDigits` | 80 | The countdown's digits 0-9, 8 bytes each. Read by the countdown in AttrRevealStart (src/loader/chain.asm, `$FC73`): a digit's glyph is `$FF80` + 8 x digit, the four digit pointers at `$FD07-$FD0A` hold the glyphs' low bytes. c1: the digits on the loading screen at character row 20, columns 13-18 (the last digit at `$5092`) while the blocks load. | - | - |


## Unxor (TZX block 29) (`src/loader/unxor.json`)

Myth: History in the Making, System 3 Software 1989: the SpeedLock loader's piece at `$FE76`, tape block 29. Its
entries are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/unxor.json`; the readers and writers from `work/stage1/c1`.

### Unxor (TZX block 29): unxor

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FE89` | `UnxorLeftover` | 96 | Bytes of block 29 no code runs: copies of Sl1End, Boot and the start of Sl1Start. Not executed in any recording (c1 checked): Unxor jumps away at `$FE86`. `$FE89-$FE97` are Sl1End's 15 bytes, `$FE98-$FEC6` Boot's 47 bytes, `$FEC7-$FEE8` the first 34 bytes of Sl1Start, as the mastering tool left them in the block. Known only from the code (`$FE89-$FEE8` against src/loader/sl1end.asm, boot.asm, sl1.asm). | - | - |


## Sl1End (TZX block 31) (`src/loader/sl1end.json`)

Myth: History in the Making, System 3 Software 1989: the SpeedLock loader's piece at `$FF3A`, tape block 31. Its
entries are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/sl1end.json`; the readers and writers from `work/stage1/c1`.


## Boot (TZX blocks 33 and 35) (`src/loader/boot.json`)

Myth: History in the Making, System 3 Software 1989: the SpeedLock loader's piece at `$5B00`, tape block 33 and 35.
Its entries are `src/loader/<module>.asm`, written from `src/loader/pieces.ann` by `kit/mkgame.py --part
src/loader/boot.json`; the readers and writers from `work/stage1/c1`.
