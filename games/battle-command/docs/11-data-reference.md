# 11. Data reference

Every data entry of the game image `$5B00`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1g`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## system

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B00` | `LoadLeftover5B00` | 256 | Leftover bytes of the load in the 128K ROM's system area. No routine of the game reads or runs `$5B00-$5BFF` in any recording after the entry (the L1 of every play and menu build; controls runs the ROM's own SWAP here only after the reset at frame 331, `case.json` "overwritten"). Kept as a documented leftover. | - | - |

## mathtables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5C00` | `LogFraction` | 256 | log2 fractions: byte n = 256 * frac(log2 n), n = 1..255. 256 bytes in octave runs: `$5C01`, `$5C02-$5C03`, `$5C04-$5C07`, ... `$5C80-$5CFF` (n = 128..255: `$00 $03 $06 ... $FF`). `$5C00` is 0 (log of 0 is not taken). With LogInteger, log2 n = `$5D00`[n] + `$5C00`[n] / 256 in 8.8. Readers: Divide `$A687` / DivideByLog `$A6D2` (`LD H,$5C` / `INC H`), bank 3 `$C959` (the polygon slopes). L1 play: `$A6D2` reads `$5C00-$5EFF`. | `Divide`, `DivideByLog` | - |
| `$5D00` | `LogInteger` | 256 | log2 integer parts: byte n = floor(log2 n); `$5D00` = `$F0`. 256 bytes: 0 for n = 1, 1 for 2-3, 2 for 4-7, ... 7 for 128-255; byte 0 is `$F0` (a large negative log, so a zero numerator gives a zero quotient). Read beside LogFraction by `$A687`, `$A6D2`, bank 3 `$C959`. | `Divide`, `DivideByLog` | - |
| `$5E00` | `ExpFraction` | 256 | Antilogs: byte n = 256 * (2^(n / 256) - 1). 256 bytes `$00 $01 $01 $02 ... $FD $FF`: the 8-bit mantissa of 2^(n/256), with an implied leading 1 (`LD H,$01` after the lookup). Readers: DivideByLog `$A6D2` (`LD H,$5E`), bank 3 `$C959`. | `DivideByLog` | - |
| `$5F00` | `SquareLow` | 256 | Squares of the signed bytes, low bytes: `$5F00`[i] = low(i*i), i = -128..127 as a byte. With SquareHigh the 16-bit square of the signed byte i: `$5F00`+i low, `$6000`+i high (i = `$81` gives 127 squared, i = `$80` 128 squared). Readers: the quarter-square multiplies MulSigned `$A7BF`, MulFrac `$A7F2`, MulWordByte `$A82C` (L1 play: `$5F00-$60FF`). | `MulFrac`, `MulSigned`, `MulWordByte` | - |
| `$6000` | `SquareHigh` | 256 | Squares of the signed bytes, high bytes: `$6000`[i] = high(i*i). Rises `$00`..`$3F` for i = 0..127, `$40` at i = `$80`, falls back for i = `$81`..`$FF` (the squares of -127..-1). | `MulFrac`, `MulSigned`, `MulWordByte` | - |
| `$6100` | `Sine16Low` | 256 | Sine, 16 bits, low bytes: sin(2 pi n / 256) * `$2000`. 256 entries, low byte here and high byte at Sine16High `$6200` (`$6140`/`$6240` = `$2000`, `$61C0`/`$62C0` = `$E000`). Read by SinCos16 `$A8A5` (the 16-bit box BoxRect16 `$AAF5`). | `SinCos16` | - |
| `$6200` | `Sine16High` | 256 | Sine, 16 bits, high bytes. See Sine16Low `$6100`. | `SinCos16` | - |
| `$6300` | `Sine8` | 256 | Sine, 8 bits: sin(2 pi n / 256) * 127, signed. 256 bytes `$00 $03 $06 ... $7F ... $81 ...`; the cosine is the entry n + `$40`. Readers: SinCos8 `$A899` (the mission vector `$67E8`), the boxes `$AA63`, `$AB7B`, `$ABFF`, the polar points `$A119`, SinCosHalf `$A8B2`. | `BoxSquare`, `SinCos8`, `SinCosHalf` | - |
| `$6400` | `Sine8Half` | 256 | Sine, 8 bits, half a step on: sin(2 pi (n + 0.5) / 256) * 127. 256 bytes `$02 $05 $08 ...`. Read only by SinCosHalf `$A8B2` when the angle word has its half-step bit (bit 7 of L) set; no recording reads it (known only from the code). | - | - |
| `$6500` | `ScreenRowTable` | 384 | The screen address of each pixel row, rows 0..191. 192 words `$4000`, `$4100`, ... `$57E0`. The view blits pop them with `SP` pointed into the table: ViewBlitFront `$8999` from `$6540` (row 32), ViewBlitWide `$8A41` from `$6580` (row 64), ViewBlitNarrow `$8A98` from `$6550` (row 40). | `BarLines`, `CopyGraphic`, `PlotRadarPixel`, `PrintChar`, `PrintSmallChar` +4 | - |
| `$6680` | `PolyXClipped` | 40 | Polygon work: the list clipped in X, two bytes a vertex (x, y). Written by the X clip of bank 3 (`$C218` and its states) for the span filler `$C4C4` / `$C542`, which also marks the top vertex (bit 7 of its y) and copies the list once more behind itself (`LDIR` at `$C514`) so the edge walkers can run round it. Up to 20 vertices. | - | - |
| `$66A8` | `PolyYClipped` | 36 | Polygon work: the list clipped in Y, three bytes a vertex (x word, y byte). Written by the Y clip of bank 3 (`$C000`, `$C02F`, `$C0DE`, `$C17B`) from PolyVerts `$6700`, read by the X clip `$C218`. | - | - |
| `$66CC` | `PolyClipVars` | 3 | The near-plane clip's state: the first vertex (`$66CC`), the vertex count (`$66CD`), spare. Set by FillFacesClipped `$9E20` / FillPolysClipped `$A07E` and read by ClipPolyNear `$A509`. | `ClipPolyNear` | `ClearPointerState`, `ClipPolyNear`, `FillFaceListClipped`, `OpFillPolysClipped`, `PlayerSteering` +2 |
| `$66CF` | `PolyWorkSpare` | 6 | Unused bytes before the vertex counter | `DepthInsert`, `DrawObjectsInOrder`, `TransformObjects`, `FindMissileTarget` (`stage1/play`) | `ClearDepthTree`, `DepthInsert`, `TransformObjects` |
| `$66D5` | `PolyOutCount` | 1 | The number of vertices ClipPolyNear `$A509` / AppendPolyVertex `$A677` put in PolyVerts | `AppendPolyVertex`, `FillFaceListClipped`, `OpFillPolysClipped` | `AppendPolyVertex`, `FillFaceListClipped`, `OpFillPolysClipped` |
| `$66D6` | `FillPatterns` | 26 | Fill patterns: two bytes for each colour 0..12 (`$66D6` + 2c). The span filler `$C86A` (bank 3) takes (a, b) = (`$66D6`+2c, `$66D7`+2c) for the colour c in `$7579`: the row byte is b on one row and b XOR a on the next (the `XOR $00` at `$C931` is patched to a), so each colour is a 2-row dither: 0 `00/00` black, 1 `00/FF` row stripes, 2 `00/AA`, 3 `FF/FF` solid ink, 4 `FF/AA`, 5 `AA/AA`, 6 `AA/55` checker, 7 `FF/33`, 8 `55/11`, 9 `FF/55`, 10 `11/01`, 11 `33/11`, 12 `44/44`. The model scripts use colours 0-9. With `$757A` = 0 every colour is solid ink (`LD B,$FF` at `$C875`). | - | - |
| `$66F0` | `RightEdgeMasks` | 8 | Keep masks right of a span end: `$7F $3F ... $00` for x AND 7 = 0..7. Read by the span filler `$C86A` at the span's right end. | - | - |
| `$66F8` | `LeftEdgeMasks` | 8 | Keep masks left of a span start: `$00 $80 $C0 ... $FE`. Read by the span filler `$C86A` at the span's left end and for a one-byte span (`$C93C`). | - | - |
| `$6700` | `PolyVerts` | 32 | Polygon work: the screen vertices of the face being filled, four bytes each (x word, y word). Filled by the face renderers (`$9D99`, `$9E20`, `$9ECD`, `$A07E`, ClipPolyNear `$A509`) from ProjectedPoints `$FC00`; the vertex count goes to `$68A9`, the colour to `$7579`, then `$7290` pages bank 3 and calls the filler `$C4C4`. Up to 8 vertices (`$6700-$671F`). | - | `AppendPolyVertex`, `FillFaceListClipped`, `OpFillFaces`, `OpFillPolys`, `OpFillPolysClipped` +1 |
| `$6720` | `FaceWorkSpare` | 8 | Bytes between the polygon list and the face flags | - | - |
| `$6728` | `FaceFlags` | 112 | The visibility flag of each face slot 0..39: `$FF` front-facing, `$00` back-facing. Written by TestFaces `$9BAF` (opcode 5) at `$6728` + slot (the slot base from the opcode's first operand): `$FF` when the screen cross product of three vertices is negative (counter-clockwise on screen), or when one or two of them are behind the eye; `$00` when all three are behind. Read by the face renderers, the edge lists (opcodes 4, 17) and the branches (opcodes 6, 7, 8, 10). | `DrawRadar`, `FillFaceListClipped`, `OpFillFaces`, `OpOrderByFace`, `FillFaceList` (`stage1/missions`) | `DrawRadar`, `RadarAddBlip`, `StoreFaceFlag`, `HelicarrierInit` (`stage1/play`), `OpTestFaces` (`stage1/menu`) |

## gamevars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6798` | `GameVars` | 38 | Game variables: the completion flags, world values, the control device | `CameraSinCosAgain`, `ClipPolyNear`, `DrawObject`, `GridVectors`, `GroundDots` +27 | `ClipPolyNear`, `FillFaceListClipped`, `NearClipLine`, `OpFillPolysClipped`, `ReadKeys` +6 |
| `$6799` | `MissionsDone` (`GameVars`+1) | 10 | ten flags, one per mission 1-10 (MissionCompleteScreen writes `$6799` + mission, EncodePassword reads all ten); the first nine all non-zero unlock Grand Finale (LoadMissionIfAllowed `$759A`) | `MissionDone`, `LoadMissionIfAllowed` (`stage1/missions`) | - |
| `$67A3` | `WorldVars` (`GameVars`+11) | 19 | - | `CameraSinCosAgain`, `DrawObject`, `GridVectors`, `GroundDots`, `NearClipLine` +19 | `NearClipLine`, `SetCamera`, `ClipPolyNear` (`stage1/missions`) |
| `$67B6` | `ControlDevice` (`GameVars`+30) | 1 | the chosen device 0-4 (ReadControls) | `ReadControls` | - |
| `$67B7` | `RepeatY` (`GameVars`+31) | 1 | frames to the next Y step (DecodeDirections, docs/05-controls.md 5.3) | `ReadKeys`, `DecodeDirections` (`stage1/menu`) | `ReadKeys`, `DecodeDirections` (`stage1/menu`) |
| `$67B8` | `LastDirections` (`GameVars`+32) | 2 | the last direction bits | `ReadKeys`, `DecodeDirections` (`stage1/menu`) | `ReadKeys`, `DecodeDirections` (`stage1/menu`) |
| `$67BA` | `RepeatX` (`GameVars`+34) | 1 | frames to the next X step | `ReadKeys`, `DecodeDirections` (`stage1/menu`) | `ReadKeys`, `DecodeDirections` (`stage1/menu`) |
| `$67BB` | `MousePos` (`GameVars`+35) | 2 | the mouse's X and Y (ReadMouse) | `ReadMouse` (code) | `ReadMouse` (code) |
| `$67BD` | `MouseDelta` (`GameVars`+37) | 1 | shared: the mouse delta (ReadMouse) and the polygon fill's bottom row (FillPolygon, bank 3) | - | `ReadMouse` (code) |

## apivectors

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$67EB` | `ApiVector15` | 3 | ApiVector15 | - | - |
| `$6800` | `PlayWork` | 168 | Play work area `$6800-$68A7` (play writes `$6800-$682F`) | `DepthInsert`, `DrawEntry`, `DrawObjectsInOrder`, `FindMissileTarget` (`stage1/play`), `MissileSeek` (`stage1/play2`) +1 | `ClearDepthTree`, `DepthInsert` |
| `$68A8` | `PanelGauges` | 76 | The panel's gauges: five 6-byte records from `$68AB`, then the four slots' records from `$68C9`. DrawWeaponBars `$72F9` redraws a record whose first byte (the value) changed; FlickerPlayer `$6B1D` tests `$68BD` (record 3) below 16. | `BoxRect`, `BoxRect16`, `BoxSquare`, `ClipPolyNear`, `ClockTick` +23 | `ClockTick`, `DrawObject`, `FillFaceListClipped`, `MissionTimeSetup`, `OpFillFaces` +12 |
| `$68AB` | `GaugeRecords` (`PanelGauges`+3) | 30 | - | `DrawRadar`, `FlickerPlayer`, `PlayerHit`, `DrawDamagePanel` (`stage1/play`), `DrawWeaponBars` (`stage1/play`) | `PlayerHit`, `DrawWeaponBars` (`stage1/play`) |
| `$68C9` | `SlotGauges` (`PanelGauges`+33) | 25 | - | `DrawSlotIcons`, `PlayerHit`, `UpdateAmmoBars`, `DrawDamagePanel` (`stage1/play`), `DrawWeaponBars` (`stage1/play`) +2 | `PlayerHit`, `UpdateAmmoBars`, `DrawWeaponBars` (`stage1/play`) |
| `$68E2` | `MissionScore` (`PanelGauges`+58) | 6 | the mission's score, 4 bytes (AddKillScore `$B692` adds `$1E`) | `BoxRect`, `BoxRect16`, `BoxSquare`, `AddKillScore` (`stage1/death`), `BoxSquareTurret` (`stage1/missions`) +3 | `DrawObject`, `AddKillScore` (`stage1/death`), `BoxSquareTurret` (`stage1/missions`), `DrawEntry` (`stage1/play2`), `l_AA5B` (`stage1/missions`) +2 |
| `$68E8` | `GoalFlag` (`PanelGauges`+64) | 2 | set by the mission's goal hook (`$6A66`): PickupMessage, the pickup | `PickupAnnounce`, `BoxSquareTurret` (`stage1/missions`), `ArmourDestroyed` (code), `HelicarrierHit` (code) | - |
| `$68EA` | `MissionClock` (`PanelGauges`+66) | 10 | seconds, minutes, hours (ClockTick `$7DFB`); minutes and hours printed by PrintClock | `ClockTick`, `TimeOfDay`, `PrintClock` (`stage1/missions`) | `ClockTick`, `MissionTimeSetup` |

## missionflow

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CE68` | `DevMissionLoader` | 60 | A development loader for "MISSHDR:0:" that nothing calls. `$CE68`-`$CEA3`: IX = `$CE93`, DE = 17, LD-BYTES through `$86C1` with A = `$FF`, and the 10-byte name "MISSHDR:0:". No routine calls it; a leftover of the development. | `PlayerStep` | `PlayerStep`, `TerrainCollision`, `TerrainScan` (`stage1/missions`), `l_CC98` (code) |
| `$CE69` | `TerrainType` (`DevMissionLoader`+1) | 59 | TerrainCollision stores the terrain type here, PlayerStep reads it (a byte of the dead loader reused) | `PlayerStep` | `PlayerStep`, `TerrainCollision`, `TerrainScan` (`stage1/missions`), `l_CC98` (code) |
| `$D5D0` | `HelicarrierData` | 164 | The Helicarrier's data. The Helicarrier's model and state bytes; `$D5D7` is CopyHelicarrierState's store. | `BoxHeights` (`stage1/play2`), `BoxRect` (`stage1/play2`), `FillFaceList` (`stage1/play2`), `OpNative` (`stage1/play2`), `OpProject` (`stage1/play2`) +5 | `CopyHelicarrierState` (`stage1/play2`), `StartMission` (code) |
| `$DA8C` | `HelicarrierTemplate` | 31 | Bytes before the Helicarrier's collision handler: a small table, then a CPL loop over `$6760`. `$DA8C`-`$DA9E` data; `$DA9F`: `LD HL,$6760` / `LD B,8` / CPL each byte / RET (no recording runs it). | - | - |
| `$DB97` | `PickupText` | 46 | The pickup text. PrintString: `$07` codes and "MISSION:COMPLETE:PROCEED:TO:"; the word "PICKUP" from `$DBB6` on is taken as code by the walk (bank 6 CALL target `$DBB6` from `$6BCA`). | - | - |
| `$DBC5` | `MissionHeader` | 8906 | The mission block: the header `$DBC5-$DBFF`, the vertices, segments, objects, templates, code and models (zeros in the image: side 2 loads it). LoadMissionBlock `$855B` loads the block here; every reader indexes from `$DBC5` (header fields `$DBC5-$DBE9`, docs/07-objects.md 7.2, src/res/missions/README.md). The part a reload restores ends at the header's word (`$FB3F` for Blast Em Mission); the rows `$FC00-$FF7F` above are the 3D engine's work rows. | `ActivateMissionObjects`, `BoundaryCheck`, `BoxHeights`, `BoxRect`, `BoxRect16` +47 | `ActivateMissionObjects`, `BoxHeights`, `BoxRect`, `BoxRect16`, `BoxSquare` +18 |
| `$FEBB` | `data_FEBB` | 325 | data_FEBB | `ClipPolyNear`, `CodeSmallAt`, `CodeSmallFont`, `FetchVertexDepth`, `OpFillPolysClipped` +12 | `BoxHeights`, `BoxRect`, `BoxRect16`, `BoxSquare`, `InterruptHandler` +4 |

## text

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6CE4` | `PatchSpace` | 7 | Seven zero bytes (NOP) before BorderBlack: room for a patch | - | - |
| `$6CEF` | `BorderNext` | 5 | BorderNext | - | `BorderBlack`, `l_6CF4` (code) |
| `$6E9F` | `ShiftRoutines` | 8 | The four shift routines of PrintSmallChar (shift 0, 6, 4, 2 bits) | `PrintSmallChar` | - |
| `$6F2D` | `NumberText` | 4 | Three digits and `$FF`: the buffer of CodeNumber | `PrintString` (`stage1/menu`) | `CodeNumber` (`stage1/menu`), `DivideDigit` (`stage1/menu`) |
| `$6F8F` | `ControlCodes` | 36 | The 18 control code routines of PrintString (codes 0-17). Read by `PrintString` at `$6FC7`: code n calls the word n. 14 used, 4 zero. | `PrintString`, `CopyHudGlyphsB` (`stage1/play`) | - |
| `$7C59` | `SmallFont` | 220 | The small font: 44 glyphs "0" to "[", 5 rows of a byte each, ink 0 (the glyphs are stored inverted). Read by SmallGlyph `$6DDA` (HL = `$7C59` + 5 (code - "0")) for the panel's numbers and short words; the 5 pixels a row are the high bits, the low three always 1. Witness: every read build (185 of the 220 bytes read; "@", ":", "<" ... never). | `PrintSmallChar` | - |
| `$7D35` | `SmallFontLeftover` | 28 | 28 bytes after the font that no routine reads or writes (leftover of an earlier build) | - | - |

## screens

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$709E` | `BriefingTextOnce` | 24 | BriefingTextOnce | `BriefPageText` (`stage1/play`) | `CopyMissionText`, `ShowBriefingMapOnce` (`stage1/menu`) |

## catalogue

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$71CB` | `MissionBlockName` | 9 | "MISSION::", the name a mission block starts with | - | - |
| `$71D4` | `MissionHeaderName` | 9 | "MISSHDR:", the name of a mission header | `CompareB` | - |
| `$71DD` | `DirectoryName` | 9 | "DIRECTORY" | `CompareB`, `CompareNine` (`stage1/menu`) | - |
| `$71E6` | `CatalogueName` | 11 | "MISSION:T", the start of the catalogue | `CompareB`, `CompareNine` (`stage1/menu`) | - |

## tape

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8739` | `ModelMine` | 60 | The model of template `$88`, the Sleeper mine. Read by the model code (BoxRect, FillFaceList) through the template's model word. | `BoxHeights` (`stage1/play`), `BoxRect` (`stage1/play`), `FillFaceList` (`stage1/play2`), `OpFillFaces` (`stage1/play`), `OpNative` (`stage1/play`) +6 | - |
| `$8775` | `ModelMissile` | 97 | The model of templates `$82-$86`, the missiles and the Dragonfly | `BoxHeights` (`stage1/play`), `BoxRect` (`stage1/play`), `ClipPolyNear` (`stage1/play`), `FillFaceList` (`stage1/play2`), `FillFaceListClipped` (`stage1/play`) +9 | - |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$733E` | `data_733E` | 5 | data_733E | - | - |
| `$735E` | `data_735E` | 4 | data_735E | - | - |
| `$74E6` | `ScreenList` | 150 | The menu screens: the current pointer, then pairs of words (draw routine, zone table). Read and moved by `SetScreen` `$7060`. | `DrawObject`, `SetAwolState`, `SetScreen`, `StartMission`, `ScreenZero` (`stage1/death`) +1 | `DrawObject`, `FillFaceListClipped`, `LoadMission`, `OpFillFaces`, `OpFillPolys` +12 |
| `$7578` | `AwolState` (`ScreenList`+146) | 4 | the AWOL state: 0 inside, 1 beyond the extent (GOING AWOL), 2 more than 4 beyond (desertion); SetAwolState `$D4E9` | `DrawObject`, `SetAwolState`, `StartMission`, `DrawModel` (code) | `DrawObject`, `FillFaceListClipped`, `LoadMission`, `OpFillFaces`, `OpFillPolys` +10 |
| `$75CA` | `IconTable` | 38 | The addresses of the 19 weapon icons (bank 6), read by DrawIcon. 19 words at `$75CA-$75EF`: icon n at word n-1. | `DrawIcon` | - |
| `$75F0` | `ObjectTable` | 1440 | The 24 object records, 60 bytes each: 0 the player, 1-20 the mission's objects, 21 the Helicarrier, 22 projectiles (23 never allocated). +0 list index, +1 type, +2 state (bit 7 present, 6 wreck, 5 drawn, 2 on the radar), +3 handler flags, +4 colour, +5 height, +7 speed, +8 wreck model, +`$0B` box half-sizes, +`$13` hit points, +`$14` damage, +`$16` radius, +`$18` step handler, +`$1A` collision handler, +`$1C` model, +`$1E` score, +`$22` heading, +`$23` X (24 bits), +`$26` Y (24 bits), +`$2A` pitch, +`$2B` view position, +`$31` timer, +`$32` AI state, +`$3B` collision slot. +1 is the type, +2 to +`$1F` come from the type's template, +`$20` is the serial. Read by RunObjectHandlers `$C026`, written by the world code (frag of bank 2 / 0, docs 05-07). Witness: every play build reads and writes `$75F0-$7B8F`. | `ActivateMissionObjects`, `BearingTo`, `BounceDecay`, `CameraToPlayer`, `CollisionPass` +57 | `ActivateMissionObjects`, `BounceDecay`, `CameraToPlayer`, `CopyHeading`, `CopyPosition` +37 |
| `$75F5` | `PlayerHeight` (`ObjectTable`+5) | 2 | - | `CollisionPass`, `RecordByIndex`, `RegisterCollision`, `RunObjectHandlers`, `SetCamera` +2 | - |
| `$75F7` | `PlayerSpeed` (`ObjectTable`+7) | 17 | - | `BounceDecay`, `CollisionPass`, `EngineTone`, `MoveObject`, `PlayerHit` +9 | `BounceDecay`, `PlayerHit`, `PlayerStep`, `ResetPlayerHandler` |
| `$7608` | `PlayerHandler` (`ObjectTable`+24) | 10 | - | `CollisionPass`, `MoveObject`, `RecordByIndex`, `RegisterCollision`, `RunObjectHandlers` +2 | `MissionTimeSetup`, `ResetPlayerHandler`, `SetBounce`, `PlayerStep` (`stage1/missions`) |
| `$7612` | `PlayerHeading` (`ObjectTable`+34) | 1 | - | `CollisionPass`, `MoveObject`, `PlayerSteering`, `RecordByIndex`, `RegisterCollision` +11 | `MissionTimeSetup`, `PlayerSteering`, `PlayerStep` (`stage1/missions`) |
| `$7613` | `PlayerX` (`ObjectTable`+35) | 3 | - | `BearingTo`, `CollisionPass`, `MoveObject`, `RecordByIndex`, `RegisterCollision` +6 | `MissionTimeSetup`, `MoveObject` |
| `$7616` | `PlayerY` (`ObjectTable`+38) | 1222 | - | `ActivateMissionObjects`, `BearingTo`, `CollisionPass`, `DrawObject`, `FindFreeObject` +45 | `ActivateMissionObjects`, `CopyHeading`, `CopyPosition`, `MissionTimeSetup`, `MoveObject` +28 |
| `$7ADC` | `HelicarrierRecord` (`ObjectTable`+1260) | 180 | - | `RegisterCollision`, `RunObjectHandlers`, `TransformObjects`, `BearingTo` (`stage1/play`), `CollisionPass` (`stage1/play`) +10 | `TransformObjects`, `HelicarrierInit` (`stage1/play`), `LaunchProjectile` (`stage1/play`), `MortarShellStep` (`stage1/play`), `MoveObject` (`stage1/play`) +4 |
| `$7B90` | `PlayWorkspace` | 201 | The per-store-type table and play variables, then the interrupt's stack (top `$7C49`) and the fuel word `$7C57`. `$7B89` + 8 x type (type 1-13, from `$7B91`): the aim, fire and select routines of each weapon store; `$7BF9` the failure reason text pointer; the interrupt handler's stack below `$7C49`; `$7C57` the fuel (reset to `$3F00` by bank 6 `$CC1B`). | `DrawRadar`, `PlayerStep`, `PlotBackBuffer`, `PlotRadarPixel`, `PointerFire` +5 | `CopyMissionText`, `CopyPointer`, `PlayerStep`, `RadarAddBlip`, `TransformObjects` +4 |
| `$7BF9` | `FailReason` (`PlayWorkspace`+105) | 94 | - | `DrawRadar`, `PlotBackBuffer`, `PlotRadarPixel`, `PointerFire`, `RadarAddBlip` +3 | `CopyMissionText`, `CopyPointer`, `RadarAddBlip`, `TransformObjects`, `HelicarrierHit` (code) +4 |
| `$7C57` | `Fuel` (`PlayWorkspace`+199) | 2 | - | `PlayerStep` | `PlayerStep` |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7DC0` | `PointerPos` | 2 | The pointer's X and Y (copied to `$7C51` / `$7C53` by `$897E`) | `ClampStep`, `CopyPointer` | `ClampStep` |
| `$7E2C` | `LoadedMission` | 3 | Two spare bytes and the mission loaded last (`$7E2E`, `$FF` none) | `LoadMission` | `LoadMission`, `MissionSetup` (`stage1/play2`) |
| `$7E2E` | `LastLoadedMission` (`LoadedMission`+2) | 1 | - | `LoadMission` | `LoadMission`, `MissionSetup` (`stage1/play2`) |
| `$7E2F` | `ClockText` | 11 | The clock's string: position codes and "00:00", `$FF` | `CodeAt` (`stage1/missions`), `CodeAtColumn` (`stage1/missions`), `CodeInk` (`stage1/missions`), `PrintString` (`stage1/missions`) | `PrintClock` (`stage1/missions`) |
| `$7E82` | `MissionParams` | 382 | 12 bytes of the mission header (`$DBF1`), copied by `$8598` | `BearingTo`, `BoxHeights` (`stage1/play`), `BoxRect` (`stage1/play`), `FillFaceList` (`stage1/play2`), `HelicarrierWait` (`stage1/play`) +9 | `LoadMission`, `PlayerStep`, `MissionSetup` (`stage1/play2`), `BrakeKey` (code) |
| `$87F0` | `BlankMessage` | 12 | The empty message line | `CodeSmallAt`, `CodeSmallFont`, `PrintString` | - |
| `$88EE` | `DayBox` | 5 | An attribute box record (AttrBox) | `PrintString` | - |
| `$88F3` | `NightBox` | 5 | NightBox | `PrintString`, `AttrBox` (`stage1/play`), `AttrBoxAt` (`stage1/play`) | - |
| `$88F8` | `HourTable` | 16 | Four rows: the hour, two attributes, the light value for `$757A` | `PrintString`, `SkyColours`, `TimeOfDay`, `ToggleNight`, `AttrBoxAt` (`stage1/play`) | - |
| `$8908` | `SkyBoxes` | 8 | SkyBoxes | `AttrBoxAt`, `PrintString` | - |
| `$8950` | `KeyCodes` | 40 | 40 key codes, by half row and bit | `PrintString`, `ScanKeyboard` | - |
| `$8978` | `KeyState` | 6 | KeyFlags (bit 0 new or repeated, bit 1 a key is down), KeyCode, the repeat count, the raw key, the row | `KeyRepeat`, `PlayKeys`, `PlayerStep`, `PrintString`, `ScanKeyboard` +2 | `KeyRepeat`, `ScanKeyboard` |
| `$8979` | `KeyCode` (`KeyState`+1) | 1 | - | `KeyRepeat`, `PlayKeys`, `PlayerStep`, `PrintString`, `DamageKeys` (`stage1/play`) +1 | `KeyRepeat` |
| `$897A` | `KeyRepeatCount` (`KeyState`+2) | 4 | - | `KeyRepeat`, `PrintString` | `KeyRepeat`, `ScanKeyboard` |

## bootstrap

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8044` | `LoadAttrLeftover` | 317 | The rest of the loading screen's attributes (`$8044-$8180`): never read in play. The loader loads the attributes to `$8000-$82FF` (tape block 15); the game's stack and vector table overwrite the end. | - | `InterruptHandler` (`stage1/menu`) |
| `$8181` | `ImJump` | 3 | Unused: JP `$8383` at the IM 2 vector table's target; every vector byte is `$83`, so no interrupt jumps here. The menus' stack overwrites it (lowest `$8149`). | - | `Entry`, `InterruptHandler` (`stage1/missions`) |
| `$8184` | `Stack` | 124 | The main stack, top `$8200` (SP = `$81FF` at the entry). Measured down to `$8149` (menu), `$816B` (play), `$8199` (c1 at the mission load): below `$8184` it runs over ImJump and the end of LoadAttrLeftover (L1 byte_use bit 3, docs/02-architecture.md 2.6). | - | `InterruptHandler` |
| `$8200` | `Im2Table` | 257 | The IM 2 vector table: 257 bytes of `$83` (I = `$82`), filled by Entry | `AbsA`, `ActivateMissionObjects`, `ApiVector00`, `ApiVector08`, `ApiVector09` +192 | `Entry` |
| `$8301` | `Armour` | 73 | The armour: `$8301-$8303` the sides 1-3 (HitSide), `$8304` the top; also Bootstrap's copy destination | `DrawSegments`, `PlayerHit`, `TerrainCollision`, `PrintString` (`stage1/death`), `TerrainScan` (`stage1/missions`) | `PlayerHit`, `SegmentVisibility`, `DrawSegments` (`stage1/missions`) |
| `$8305` | `WorldWork` (`Armour`+4) | 69 | - | `DrawSegments`, `PlayerHit`, `TerrainCollision`, `PrintString` (`stage1/death`), `TerrainScan` (`stage1/missions`) | `SegmentVisibility`, `DrawSegments` (`stage1/missions`) |
| `$834A` | `DamageBoardRecords` | 57 | Nine 6-byte records of the damage board (icons `$10`, `$11`, `$12`, `$0F`, `$0E`, then the four slots). Records 5-8 are the WeaponSlots `$8368`, written by FitOrRemoveWeapon. StoresToGauges sets gauge k (`$68AB` + 6k) to `$5F` when record k is not 0, else 0. 54 bytes, `$834A-$837F`. | `DrawSlotIcons`, `UpdateAmmoBars`, `ConsumeAmmo` (`stage1/play`), `DrawDamagePanel` (`stage1/play`), `PrintString` (`stage1/death`) +1 | `ConsumeAmmo` (`stage1/play`) |
| `$8368` | `WeaponSlots` (`DamageBoardRecords`+30) | 27 | four 6-byte slot records, the ammunition at +5 | `DrawSlotIcons`, `UpdateAmmoBars`, `ConsumeAmmo` (`stage1/play`), `DrawDamagePanel` (`stage1/play`), `PrintString` (`stage1/death`) +1 | `ConsumeAmmo` (`stage1/play`) |

## missionload

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8547` | `HeaderMission` | 1 | HeaderMission | `RemarkMission`, `PrintString` (`stage1/death`) | `LoadMissionHeader` |

## raster

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8AF1` | `BackBuffer` | 3072 | The 3D view's back buffer: 96 rows of 32 bytes (256 x 96 pixels, row 0 at the top). Cleared by ClearBackBuffer `$96F1`, drawn by the span filler (bank 3 `$C86A`), the line drawer (bank 3 `$C9A7`) and PlotBackBuffer `$AA27`, read by the three blits. Row y starts at `$8AF1` + 32y. Its last 113 bytes (`$9680-$96F0`) are what game.ann calls InputLeftover: they are back-buffer rows 92-95, zeroed every pass. | `ClearClipRow`, `CodeInk`, `CodeLeftMargin`, `CodeSmallAt`, `CodeSmallFont` +12 | `ClearClipRow`, `ClearMarkColumn`, `CopyCatalogueHead`, `CopyMissionText`, `LdBytes` +3 |

## input

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9715` | `ClickState` | 5 | The click position (X, Y), the fire timer (on, count), the frames per step | `PointerFire`, `PointerZones`, `ReadKeys`, `DecodeDirections` (`stage1/menu`) | `PointerFire`, `SetBinoculars`, `StartMission` |
| `$9716` | `ClickY` (`ClickState`+1) | 1 | - | `PointerZones` | `PointerFire` |
| `$9717` | `FireHeld` (`ClickState`+2) | 1 | - | `PointerFire` | `PointerFire` |
| `$9718` | `FireCount` (`ClickState`+3) | 1 | - | `PointerFire` | `PointerFire` |
| `$9719` | `StepFrames` (`ClickState`+4) | 1 | - | `ReadKeys`, `DecodeDirections` (`stage1/menu`) | `SetBinoculars`, `StartMission` |
| `$9723` | `DeviceReaders` | 10 | Five readers: Sinclair, cursor, Kempston mouse, Kempston joystick, keyboard | `CallTableEntry` | - |
| `$985C` | `InputState` | 6 | The mouse's last position, the X and Y steps, the token table base. `$9860`: PrintString's token table base (PrintString `$6FDB` uses StepY+1); its words are this table's bytes, not string pointers, and the token path is never taken (play2: the branch at `$6FBA` taken 0 of 3797). | `PlayerSteering`, `PlayerStep`, `PointerTick`, `ReadKeys`, `ClipBothEnds` (`stage1/missions`) +2 | `ReadKeys`, `ClipBothEnds` (`stage1/missions`), `ClipLineCodes` (`stage1/missions`), `DecodeDirections` (`stage1/menu`), `l_A201` (code) +2 |
| `$985E` | `StepX` (`InputState`+2) | 1 | - | `PlayerSteering`, `PointerTick`, `ReadKeys`, `DecodeDirections` (`stage1/menu`), `DragonflyStep` (`stage1/play`) +1 | `ReadKeys`, `DecodeDirections` (`stage1/menu`) |
| `$985F` | `StepY` (`InputState`+3) | 3 | - | `PlayerStep`, `PointerTick`, `ReadKeys`, `DecodeDirections` (`stage1/menu`), `DragonflyStep` (`stage1/play`) | `ReadKeys`, `DecodeDirections` (`stage1/menu`) |
| `$9862` | `KeyTable` | 18 | The five keys of ReadKeys: half-row high byte and bit mask | `ReadKeys` | - |

## render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$98E1` | `OpcodeTable` | 46 | The 23 script opcodes' handlers, indexed by the opcode byte. 0 `$992D` native call, 1 `$9938` vertex program, 2 `$9A43` project, 3 `$9AD8` lines, 4 `$9B38` lines by faces, 5 `$9BAF` face test, 6 `$9CB1` jump if face visible, 7 `$9CE8` the same, 8 `$9D28` branch on face, 9 `$9D1E` return, 10 `$9D5A` order by face, 11 `$9D0D` call, 12 `$9D8F` fill faces, 13 `$9E1E` fill faces with the near clip, 14 `$9ECD` fill polygons, 15 `$9F37` fill back faces, 16 `$9F43` lines with the near clip, 17 `$9FC3` lines by faces with the near clip, 18 `$A049` translate, 19 `$A07E` fill polygons with the near clip, 20 `$A114` fill back faces with the near clip, 21 `$A119` polar points, 22 `$B7E5` draw the carried object. Opcodes 4, 6, 7, 8, 17 are in no model of the recordings. | `RunScript` | - |
| `$9C9A` | `data_9C9A` | 9 | data_9C9A | - | - |
| `$9CD7` | `data_9CD7` | 17 | data_9CD7 | - | - |
| `$A039` | `data_A039` | 16 | data_A039 | - | - |
| `$A0FF` | `data_A0FF` | 10 | data_A0FF | - | - |
| `$A17C` | `ClipWindow` | 8 | The 2D clip window: x max (`$FF`), y max (`$5F`), and the clipper's work words. `$A17C` = 255 (bank 6 `$CA8B` sets 95 for the narrow console view), `$A17E` = 95; `$A180-$A183` hold the two points while ClipLine2D bisects. | `OutCode`, `ClipBothEnds` (`stage1/missions`), `ClipLineCodes` (`stage1/death`), `ClipOneEnd` (`stage1/missions`), `ClipToBottom` (`stage1/missions`) +3 | `ClipLineCodes` (`stage1/death`), `ClipOneEnd` (`stage1/missions`) |
| `$ABFD` | `BoxTiltPitch` | 2 | Spare byte; the pitch of BoxTilted (`$ABFE`, from the object record +`$2A` by DrawObject `$B827`) | `BoxTilted` (`stage1/play2`) | `DrawObject`, `DrawEntry` (`stage1/play2`), `DrawModel` (code) |
| `$AD04` | `RollSinCos` | 2 | The sine and cosine of the roll for RotatePair | `RotatePair` (`stage1/play2`) | `BoxTilted` (`stage1/play2`) |

## player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A9FD` | `FireCooldown` | 1 | The fire cooldown, passes until the next shot. Counted down by PlayerSteering `$A986`, set by SetFireCooldown `$A9F7`. | `PlayerSteering`, `PlayerStep` (`stage1/missions`) | `PlayerSteering`, `PlayerStep` (`stage1/missions`), `SetFireCooldown` (`stage1/play`), `l_C38B` (code), `l_C408` (code) |
| `$B8B9` | `MortarElevationUp` | 11 | Raise the mortar elevation (no recording runs it). `LD A,n` / `INC A` / `CP $40` / `RET NC` / `LD ($B8BA),A`: the elevation is the operand at `$B8BA`, 32 at start. Only the down key ran in the recordings. | `MortarElevationDown` (`stage1/play`), `ShowMortarRange` (`stage1/play`) | `MortarElevationDown` (`stage1/play`) |
| `$B8FC` | `IrViewHeight` | 13 | The height used by the IR view, and its setter. `$B8FC`-`$B8FD` are spare, `$B8FE` `LD HL,0` (its operand `$B8FF` the IR camera height), `$B901` adds 8 and stores it: raise the IR view. AimLimit `$B909` lowers it. | `AimLimit` (`stage1/play2`), `CodeNumber` (`stage1/play`), `SetCamera` (`stage1/play2`) | `ShowMortarRange` (`stage1/play`), `AimLimit` (code), `LaunchMissile` (code) |
| `$C113` | `WeightText` | 11 | A print of the weight and its text. `LD HL,$C119` / `JP $6FB3` then the string at `$C119`: code the recordings do not run, with the operand `$C11B` (the stores weight, used by bank 6's stores screen). | - | - |
| `$C199` | `TargetInConeRet` | 1 | The RET the gate jumps to. `RET`. | - | - |
| `$C31B` | `DragonflyCode` | 35 | Dragonfly code no recording runs. The Dragonfly's set-up bytes: `$C33E` into `$A9B9`, handler `$C391`. | - | - |
| `$C453` | `MissileCode` | 50 | Missile step code no recording runs. Missile step: MoveObject, turn toward the target (TurnToward `$C485`), lifetime +`$31`. | - | - |
| `$C527` | `WeaponVars` | 24 | The weapon variables: the rounds shown, the ammunition pointers `$C534`, the current slot `$C53C`. `$C534` holds the four pointers `$836D`, `$8373`, `$8379`, `$837F` (+5 of each slot), `$C53C` the slot 0-3, `$C53D` the slot record. | `RefreshWeaponPanel`, `CodeNumber` (`stage1/play`), `DropMine` (`stage1/play2`), `FireBansheeIr` (`stage1/play2`), `FireBansheeRr` (`stage1/play`) +18 | `LoadMission`, `ConsumeAmmo` (`stage1/play`), `DropMine` (`stage1/play2`), `MissionSetup` (`stage1/play2`), `SelectWeapon` (`stage1/play`) +1 |
| `$C534` | `AmmoPointers` (`WeaponVars`+13) | 8 | the four slots' ammunition bytes `$836D`, `$8373`, `$8379`, `$837F` | `SelectAmmoPointer` (`stage1/play`) | - |
| `$C53C` | `CurrentSlot` (`WeaponVars`+21) | 3 | 0-3 | `DropMine` (`stage1/play2`), `FireBansheeIr` (`stage1/play2`), `FireBansheeRr` (`stage1/play`), `FireCannon` (`stage1/play2`), `FireCluster13` (`stage1/play2`) +15 | `SelectWeapon` (`stage1/play`) |
| `$C618` | `DamagedText` | 26 | "DAMAGED IN COMBAT". PrintString text: `$07` position codes and "DAMAGED", "IN", "COMBAT". | - | - |
| `$CBBD` | `HitVars` | 9 | Variables of PlayerHit. `$FF` in the image. | - | - |
| `$CC05` | `PushBackWork` | 4 | Work bytes of PushBack. Zero in the image. | `l_CBDA` (code), `l_CBF6` (code) | `CollisionPass` |
| `$CC2B` | `HeadingAwayCode` | 8 | Code no recording runs (heading + `$80`). `CALL $67C1` / `ADD A,$80` / `LD (IX+$22),A`: turn away from the hitter. | - | - |
| `$CFF4` | `MineTimerCode` | 8 | The mine timer up (not run). `LD A,n` (n = `$CFF5`, the mine timer), `INC A`, `CP $78`, `JR C`, `XOR A`: the up key's copy of SetMineTimer. | `CodeNumber` (`stage1/play2`), `MineFall` (`stage1/play2`), `SetMineTimer` (`stage1/play2`), `MineArm` (code) | `SetMineTimer` (`stage1/play2`), `StoreMineTimer` (code) |
| `$D0AB` | `MineHudText` | 7 | The mine HUD's text. PrintString codes for the mine's HUD. | `CodeNumber` (`stage1/play2`), `CodeSmallAt` (`stage1/play2`), `CodeSmallFont` (`stage1/play2`), `PrintString` (`stage1/play2`) | `DropMine` (`stage1/play2`), `SelectWeapon` (`stage1/play`) |
| `$D0EA` | `data_D0EA` | 26 | data_D0EA | - | - |
| `$D114` | `SlotShown` | 140 | The slot whose rounds are shown (`$D114`), then weapon code no recording runs. PrintAmmo `$C510` compares `$D114` with the current slot `$C53C`; the code after it stores it and calls SelectAmmoPointer `$D3C6`. | `PrintAmmo` (`stage1/play`) | `SelectWeapon` (`stage1/play`) |
| `$D1A0` | `RecordScanCode` | 47 | Code no recording runs: LD HL,`$762E` / LD DE,60 / LD BC,`$39`, a pass over the records | - | - |
| `$D1CF` | `RecordScanCodeB` | 38 | Code no recording runs (the scan's second part) | - | - |
| `$D1F5` | `RecordSortCode` | 86 | Code no recording runs: a sort of the list at `$D21B`, then its work area | - | - |
| `$D2E4` | `SlotSetupCode` | 39 | Code no recording runs: the slot record set to `$D3D6`, the HUD text `$FDD7` | - | - |
| `$D324` | `Cluster13Code` | 29 | Type 13 code no recording runs (the slot `$D114` saved around `$D330`) | - | - |
| `$D3D6` | `PhantasmCode` | 33 | Phantasm code no recording runs (the slot `$D114` saved around `$D3E6`) | - | - |
| `$D485` | `HudCopyCode` | 31 | Code no recording runs: copy 24 rows to `$FD00` through `$D49B` | - | - |
| `$D512` | `AwolBlankText` | 28 | The blank that clears the AWOL warning, and the head of the warning. PrintString text: `$07` `$8D` `$10`, ten blanks, `$FF` (the warning cleared); `$D51F` starts "GOING AWOL" (`$07` `$8D` `$10` then the text at `$D521`). | - | - |
| `$D51F` | `AwolWarningText` (`AwolBlankText`+13) | 15 | the start of "GOING AWOL"; its text from `$D521` on is taken as code by the walk (a bank 6 CALL target `$D521` from `$6B35`) | - | - |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B3C9` | `WeaponTemplates` | 391 | The resident templates of the projectile types `$80-$8C`: 13 records of 30 bytes from `$B3CA`. ObjectSetType `$BD41` copies record (type - `$80`) when the type has bit 7: the 30 bytes become +2..+`$1F` of the object (the type itself is +1) (flags, colour, height, speed, box, hit points, damage, radius, step handler, collision handler, model, score). `$80` K-40 mortar shell (step `$B5E8`), `$81` cannon shell (`$B592`), `$82` Banshee RR, `$83` Phoenix RR, `$84` Banshee IR, `$85` Phoenix IR, `$86` Dragonfly, `$87` K-90 cluster bomb (`$CF4A`), `$88` Sleeper mine, `$89` Skeet bomb, `$8A` Phantasm (the decoy of the homing shell type 28), `$8B` Spectre, `$8C` the Helicarrier. The byte at `$B3C9` (`$C9`) is the RET of the routine before. | `ObjectSetType` (`stage1/play`) | - |
| `$B3CA` | `ShellTemplate80` (`WeaponTemplates`+1) | 390 | template `$80`, the K-40 mortar shell; 30 bytes a type up to `$8C` | `ObjectSetType` (`stage1/play`) | - |
| `$B8A8` | `DrawModelTail` | 3 | A CALL `$C506` no recording runs. `CALL $C506` (ResetSightTimer) at the end of the routine before; no recording takes that path. | - | - |
| `$B9DE` | `BearingTable` | 24 | The arctangent table of BearingTo. 24 bytes of angles read by BearingLookup `$B95A`. | `BearingLookup`, `SetCamera` | `CameraToPlayer`, `LaunchDragonfly` (`stage1/play`) |
| `$BBF0` | `ActivateIndexSave` | 1 | Saved operand of ActivateMissionObjects. The byte before ActivateMissionObjects; its index operands are `$BBF2` / `$BBFA`. | `ActivateMissionObjects` | `ActivateMissionObjects`, `Bootstrap` |
| `$BF20` | `DepthTreeVars` | 4 | Variables of the depth tree. Zero in the image; the walk of the tree keeps its stack depth here. | `DepthInsert` | `Bootstrap`, `ClearDepthTree`, `DepthInsert` |
| `$C4A5` | `TurnTowardTail` | 31 | The rest of TurnToward, not run. The missile's hit and lifetime code. | - | - |
| `$C648` | `CollisionTables` | 372 | The collision pair timers, the slot list `$C775`, the row pointers `$C78C`. Filled with `$FF` by `$6928` before a mission. | `CollisionPass`, `RegisterCollision`, `ResetCollisionTables`, `UnregisterCollision` | `CollisionPass`, `RegisterCollision`, `ResetCollisionTables`, `UnregisterCollision` |

## world

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AE5A` | `SegmentWalkCount` | 2 | The segments left in the walk and the walk index. Written by ResetSegmentWalk `$AE42`. | `SegmentVisibility` | `ResetSegmentWalk`, `SegmentVisibility` |
| `$AE82` | `SegmentScratch` | 30 | 30 bytes of scratch for the segment draw. Zero in every image; the segment drawing keeps its working values here (the word at `$AE9E` is read by DrawSegmentTail `$B18A`). | `StoreVertex`, `TransformSegmentEnds`, `ClipDiagonalSide` (`stage1/m2erbe`), `ClipSegmentDiagonal` (`stage1/missions`), `DrawSegmentTail` (`stage1/missions`) +3 | `DrawSegments`, `StoreVertex`, `ClipDiagonalSide` (`stage1/m2erbe`), `ClipSegmentAxisY` (`stage1/missions`), `ClipSegmentDiagonal` (`stage1/missions`) +2 |
| `$BA6E` | `ViewTexts` | 62 | The view labels: IR:SIGHT, REAR:VIEW, BINOC:X2 and their blanks. Strings for PrintString `$6FB3` (`$07` position code, `$FF` end): `$BA6E` "IR:SIGHT", `$BA7A` blank, `$BA86` "REAR:VIEW", `$BA93` "BINOC:X2" (the digit at `$BA9D`), `$BA9F` blank. | `CodeSmallAt`, `CodeSmallFont`, `PrintString` | `Bootstrap`, `l_CF18` (code) |
| `$BA7A` | `IrSightBlank` (`ViewTexts`+12) | 12 | - | `CodeSmallAt`, `CodeSmallFont`, `PrintString` | - |
| `$BA86` | `RearViewText` (`ViewTexts`+24) | 13 | "REAR:VIEW" | `CodeSmallAt`, `CodeSmallFont`, `PrintString` | - |
| `$BA93` | `BinocularText` (`ViewTexts`+37) | 12 | "BINOC:X2", the digit at `$BA9D` set by ShowBinocularZoom | `CodeSmallAt`, `CodeSmallFont`, `PrintString` | `Bootstrap`, `l_CF18` (code) |
| `$BA9F` | `ViewTextBlank` (`ViewTexts`+49) | 13 | - | `CodeSmallAt`, `CodeSmallFont`, `PrintString` | `Bootstrap` |
| `$D8D4` | `BinocularIcons` | 440 | The binocular zoom icons. Starts with the binocular zoom icons that ShowBinocularZoom `$CEF7` draws from `$D8B4` + 32 * n, n = 1-3: `$D8D4`, `$D8F4`, `$D914`, 32 bytes each. The rest up to `$DA08` is read by no routine of this fragment. | `BoxHeights` (`stage1/play`), `BoxRect` (`stage1/play`), `OpLines` (`stage1/play`), `OpNative` (`stage1/play`), `OpProject` (`stage1/play`) +2 | - |

## enemies

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B611` | `NullHandler` | 1 | A RET used as a null handler. The collision handler of objects that ignore collisions; vector `$67EB` points here. | - | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D674` | `AYRegs` | 30 | The AY register shadow R0-R13, written by WriteAY `$D7DC` | `EngineTone`, `SetNoise`, `SoundFrame` | `EngineTone`, `SetNoise`, `SilenceAY`, `SoundEffectA`, `SoundExplosion` +11 |
| `$D682` | `SelectCount` (`AYRegs`+14) | 1 | the weapon select counter (SoundSelect) | `SoundFrame` | `SilenceAY`, `SoundFrame` (`stage1/play`), `SoundSelect` (`stage1/play`) |
| `$D683` | `ExplosionCount` (`AYRegs`+15) | 1 | - | `SoundFrame` | `SilenceAY`, `SoundExplosion`, `SoundFrame` |
| `$D684` | `KillCount` (`AYRegs`+16) | 1 | - | `SoundFrame` | `SilenceAY`, `SoundFrame` (`stage1/death`), `SoundKill` (`stage1/death`) |
| `$D685` | `ToneC8Count` (`AYRegs`+17) | 1 | - | `SoundFrame` | `SilenceAY`, `SoundToneC8` (code), `l_D6F4` (code) |
| `$D686` | `FireSoundCount` (`AYRegs`+18) | 1 | the shot sound counter (SoundFire; FireCount `$9718` is the fire key's) | `SoundFrame` | `SilenceAY`, `SoundFire` (`stage1/play`), `SoundFrame` (`stage1/play`) |
| `$D687` | `MissileCount` (`AYRegs`+19) | 1 | - | `SoundFrame` | `SilenceAY`, `SoundMissile` (code), `l_D70E` (code) |
| `$D688` | `NoisePriority` (`AYRegs`+20) | 1 | zeroed each frame, set only by the steady noise path | `SetNoise`, `l_D75F` (code) | `SilenceAY`, `SoundFrame` |
| `$D689` | `SoundGate` (`AYRegs`+21) | 1 | non-zero: SoundFrame returns; SilenceAY leaves `$0E` | `SoundFrame` | `SilenceAY`, `StartMission`, `QuitKey` (`stage1/missions`) |
| `$D68A` | `RandomToneFlag` (`AYRegs`+22) | 1 | - | `SoundFrame` | `SoundRandomTone` (code), `l_D726` (code) |
| `$D68B` | `MessageSoundCount` (`AYRegs`+23) | 1 | - | `SoundFrame` | `SoundEffectA`, `SoundFrame` |
| `$D68C` | `SteadyNoiseCount` (`AYRegs`+24) | 1 | - | `SoundFrame` | `l_D75F` (code), `l_D849` (code) |
| `$D68D` | `SweepCount` (`AYRegs`+25) | 1 | - | `SoundFrame` | `l_D781` (code) |
| `$D68E` | `SirenCount` (`AYRegs`+26) | 3 | - | `SoundFrame` | `l_D7A7` (code), `l_D891` (code) |
| `$D691` | `SoundMaster` (`AYRegs`+29) | 1 | 1 in the image, never written | `SoundFrame` | - |
| `$D839` | `data_D839` | 8 | data_D839 | - | - |
| `$D8A0` | `SoundFireVar` | 1 | A spare byte after SoundFire. `$0A`, after the RET of SoundFire; no routine of this fragment reads it. | - | - |
