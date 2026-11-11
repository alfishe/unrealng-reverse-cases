# 11. Data reference

Every data entry of the game image `$5B00`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1g`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: Bank 3, Bank 4, Bank 6, Bank 7, Tape BASIC, Decryption chain and
loader, Loader stage 2, Loader block 37, Loader block 39) follow the game, each under its own heading with its
modules, its source, its annotations and its recordings.

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
| `$6798` | `GameVars` | 1 of 38 | Game variables: the completion flags, world values, the control device | `CameraSinCosAgain`, `ClipPolyNear`, `DrawObject`, `GridVectors`, `GroundDots` +27 | `ClipPolyNear`, `FillFaceListClipped`, `NearClipLine`, `OpFillPolysClipped`, `ReadKeys` +6 |
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
| `$68A8` | `PanelGauges` | 3 of 76 | The panel's gauges: five 6-byte records from `$68AB`, then the four slots' records from `$68C9`. DrawWeaponBars `$72F9` redraws a record whose first byte (the value) changed; FlickerPlayer `$6B1D` tests `$68BD` (record 3) below 16. | `BoxRect`, `BoxRect16`, `BoxSquare`, `ClipPolyNear`, `ClockTick` +23 | `ClockTick`, `DrawObject`, `FillFaceListClipped`, `MissionTimeSetup`, `OpFillFaces` +12 |
| `$68AB` | `GaugeRecords` (`PanelGauges`+3) | 30 | - | `DrawRadar`, `FlickerPlayer`, `PlayerHit`, `DrawDamagePanel` (`stage1/play`), `DrawWeaponBars` (`stage1/play`) | `PlayerHit`, `DrawWeaponBars` (`stage1/play`) |
| `$68C9` | `SlotGauges` (`PanelGauges`+33) | 25 | - | `DrawSlotIcons`, `PlayerHit`, `UpdateAmmoBars`, `DrawDamagePanel` (`stage1/play`), `DrawWeaponBars` (`stage1/play`) +2 | `PlayerHit`, `UpdateAmmoBars`, `DrawWeaponBars` (`stage1/play`) |
| `$68E2` | `MissionScore` (`PanelGauges`+58) | 6 | the mission's score, 4 bytes (AddKillScore `$B692` adds `$1E`) | `BoxRect`, `BoxRect16`, `BoxSquare`, `AddKillScore` (`stage1/death`), `BoxSquareTurret` (`stage1/missions`) +3 | `DrawObject`, `AddKillScore` (`stage1/death`), `BoxSquareTurret` (`stage1/missions`), `DrawEntry` (`stage1/play2`), `l_AA5B` (`stage1/missions`) +2 |
| `$68E8` | `GoalFlag` (`PanelGauges`+64) | 2 | set by the mission's goal hook (`$6A66`): PickupMessage, the pickup | `PickupAnnounce`, `BoxSquareTurret` (`stage1/missions`), `ArmourDestroyed` (code), `HelicarrierHit` (code) | - |
| `$68EA` | `MissionClock` (`PanelGauges`+66) | 10 | seconds, minutes, hours (ClockTick `$7DFB`); minutes and hours printed by PrintClock | `ClockTick`, `TimeOfDay`, `PrintClock` (`stage1/missions`) | `ClockTick`, `MissionTimeSetup` |

## missionflow

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CE68` | `DevMissionLoader` | 1 of 60 | A development loader for "MISSHDR:0:" that nothing calls. `$CE68`-`$CEA3`: IX = `$CE93`, DE = 17, LD-BYTES through `$86C1` with A = `$FF`, and the 10-byte name "MISSHDR:0:". No routine calls it; a leftover of the development. | `PlayerStep` | `PlayerStep`, `TerrainCollision`, `TerrainScan` (`stage1/missions`), `l_CC98` (code) |
| `$CE69` | `TerrainType` (`DevMissionLoader`+1) | 59 | TerrainCollision stores the terrain type here, PlayerStep reads it (a byte of the dead loader reused) | `PlayerStep` | `PlayerStep`, `TerrainCollision`, `TerrainScan` (`stage1/missions`), `l_CC98` (code) |
| `$D5D0` | `HelicarrierData` | 164 | The Helicarrier's data. The Helicarrier's model and state bytes; `$D5D7` is CopyHelicarrierState's store. | `BoxHeights` (`stage1/play2`), `BoxRect` (`stage1/play2`), `FillFaceList` (`stage1/play2`), `OpNative` (`stage1/play2`), `OpProject` (`stage1/play2`) +5 | `CopyHelicarrierState` (`stage1/play2`), `StartMission` (code) |
| `$DA8C` | `HelicarrierTemplate` | 31 | Bytes before the Helicarrier's collision handler: a small table, then a CPL loop over `$6760`. `$DA8C`-`$DA9E` data; `$DA9F`: `LD HL,$6760` / `LD B,8` / CPL each byte / RET (no recording runs it). | - | - |
| `$DB97` | `PickupText` | 46 | The pickup text. PrintString: `$07` codes and "MISSION:COMPLETE:PROCEED:TO:"; the word "PICKUP" from `$DBB6` on is taken as code by the walk (bank 6 CALL target `$DBB6` from `$6BCA`). | - | - |
| `$DBC5` | `MissionHeader` | 8906 | The mission block: the header `$DBC5-$DBFF`, the vertices, segments, objects, templates, code and models (zeros in the image: side 2 loads it). LoadMissionBlock `$855B` loads the block here; every reader indexes from `$DBC5` (header fields `$DBC5-$DBE9`, docs/07-objects.md 7.2, src/res/missions/README.md). The part a reload restores ends at the header's word (`$FB3F` for Blast Em Mission); the rows `$FC00-$FF7F` above are the 3D engine's work rows. | `ActivateMissionObjects`, `BoundaryCheck`, `BoxHeights`, `BoxRect`, `BoxRect16` +47 | `ActivateMissionObjects`, `BoxHeights`, `BoxRect`, `BoxRect16`, `BoxSquare` +19 |
| `$FEBB` | `data_FEBB` | 325 | data_FEBB | `ClipPolyNear`, `CodeSmallAt`, `CodeSmallFont`, `FetchVertexDepth`, `OpFillPolysClipped` +12 | `BoxHeights`, `BoxRect`, `BoxRect16`, `BoxSquare`, `InterruptHandler` +5 |

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
| `$74E6` | `ScreenList` | 146 of 150 | The menu screens: the current pointer, then pairs of words (draw routine, zone table). Read and moved by `SetScreen` `$7060`. | `DrawObject`, `SetAwolState`, `SetScreen`, `StartMission`, `ScreenZero` (`stage1/death`) +1 | `DrawObject`, `FillFaceListClipped`, `LoadMission`, `OpFillFaces`, `OpFillPolys` +12 |
| `$7578` | `AwolState` (`ScreenList`+146) | 4 | the AWOL state: 0 inside, 1 beyond the extent (GOING AWOL), 2 more than 4 beyond (desertion); SetAwolState `$D4E9` | `DrawObject`, `SetAwolState`, `StartMission`, `DrawModel` (code) | `DrawObject`, `FillFaceListClipped`, `LoadMission`, `OpFillFaces`, `OpFillPolys` +10 |
| `$75CA` | `IconTable` | 38 | The addresses of the 19 weapon icons (bank 6), read by DrawIcon. 19 words at `$75CA-$75EF`: icon n at word n-1. | `DrawIcon` | - |
| `$75F0` | `ObjectTable` | 5 of 1440 | The 24 object records, 60 bytes each: 0 the player, 1-20 the mission's objects, 21 the Helicarrier, 22 projectiles (23 never allocated). +0 list index, +1 type, +2 state (bit 7 present, 6 wreck, 5 drawn, 2 on the radar), +3 handler flags, +4 colour, +5 height, +7 speed, +8 wreck model, +`$0B` box half-sizes, +`$13` hit points, +`$14` damage, +`$16` radius, +`$18` step handler, +`$1A` collision handler, +`$1C` model, +`$1E` score, +`$22` heading, +`$23` X (24 bits), +`$26` Y (24 bits), +`$2A` pitch, +`$2B` view position, +`$31` timer, +`$32` AI state, +`$3B` collision slot. +1 is the type, +2 to +`$1F` come from the type's template, +`$20` is the serial. Read by RunObjectHandlers `$C026`, written by the world code (frag of bank 2 / 0, docs 05-07). Witness: every play build reads and writes `$75F0-$7B8F`. | `ActivateMissionObjects`, `BearingTo`, `BounceDecay`, `CameraToPlayer`, `CollisionPass` +58 | `ActivateMissionObjects`, `BounceDecay`, `CameraToPlayer`, `CopyHeading`, `CopyPosition` +38 |
| `$75F5` | `PlayerHeight` (`ObjectTable`+5) | 2 | - | `CollisionPass`, `RecordByIndex`, `RegisterCollision`, `RunObjectHandlers`, `SetCamera` +2 | - |
| `$75F7` | `PlayerSpeed` (`ObjectTable`+7) | 17 | - | `BounceDecay`, `CollisionPass`, `EngineTone`, `MoveObject`, `PlayerHit` +9 | `BounceDecay`, `PlayerHit`, `PlayerStep`, `ResetPlayerHandler` |
| `$7608` | `PlayerHandler` (`ObjectTable`+24) | 10 | - | `CollisionPass`, `MoveObject`, `RecordByIndex`, `RegisterCollision`, `RunObjectHandlers` +2 | `MissionTimeSetup`, `ResetPlayerHandler`, `SetBounce`, `PlayerStep` (`stage1/missions`) |
| `$7612` | `PlayerHeading` (`ObjectTable`+34) | 1 | - | `CollisionPass`, `MoveObject`, `PlayerSteering`, `RecordByIndex`, `RegisterCollision` +11 | `MissionTimeSetup`, `PlayerSteering`, `PlayerStep` (`stage1/missions`) |
| `$7613` | `PlayerX` (`ObjectTable`+35) | 3 | - | `BearingTo`, `CollisionPass`, `MoveObject`, `RecordByIndex`, `RegisterCollision` +6 | `MissionTimeSetup`, `MoveObject` |
| `$7616` | `PlayerY` (`ObjectTable`+38) | 1222 | - | `ActivateMissionObjects`, `BearingTo`, `CollisionPass`, `DrawObject`, `FindFreeObject` +45 | `ActivateMissionObjects`, `CopyHeading`, `CopyPosition`, `MissionTimeSetup`, `MoveObject` +28 |
| `$7ADC` | `HelicarrierRecord` (`ObjectTable`+1260) | 173 | - | `RegisterCollision`, `RunObjectHandlers`, `TransformObjects`, `BearingTo` (`stage1/play`), `CollisionPass` (`stage1/play`) +10 | `TransformObjects`, `HelicarrierInit` (`stage1/play`), `LaunchProjectile` (`stage1/play`), `MortarShellStep` (`stage1/play`), `MoveObject` (`stage1/play`) +4 |
| `$7B89` | `StoreTypes` (`ObjectTable`+1433) | 7 | the store-type table base: 8 bytes a type, types 1-13 from `$7B91` (words 0 K, 1 J, 2 fire, 3 select) | - | - |
| `$7B90` | `PlayWorkspace` | 105 of 201 | The per-store-type table and play variables, then the interrupt's stack (top `$7C49`) and the fuel word `$7C57`. `$7B89` + 8 x type (type 1-13, from `$7B91`): the aim, fire and select routines of each weapon store; `$7BF9` the failure reason text pointer; the interrupt handler's stack below `$7C49`; `$7C57` the fuel (reset to `$3F00` by bank 6 `$CC1B`). | `DrawRadar`, `PlayerStep`, `PlotBackBuffer`, `PlotRadarPixel`, `PointerFire` +5 | `CopyMissionText`, `CopyPointer`, `PlayerStep`, `RadarAddBlip`, `TransformObjects` +4 |
| `$7BF9` | `FailReason` (`PlayWorkspace`+105) | 94 | - | `DrawRadar`, `PlotBackBuffer`, `PlotRadarPixel`, `PointerFire`, `RadarAddBlip` +3 | `CopyMissionText`, `CopyPointer`, `RadarAddBlip`, `TransformObjects`, `HelicarrierHit` (code) +4 |
| `$7C57` | `Fuel` (`PlayWorkspace`+199) | 2 | - | `PlayerStep` | `PlayerStep` |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7DC0` | `PointerPos` | 2 | The pointer's X and Y (copied to `$7C51` / `$7C53` by `$897E`) | `ClampStep`, `CopyPointer` | `ClampStep` |
| `$7E2C` | `LoadedMission` | 2 of 3 | Two spare bytes and the mission loaded last (`$7E2E`, `$FF` none) | `LoadMission` | `LoadMission`, `MissionSetup` (`stage1/play2`) |
| `$7E2E` | `LastLoadedMission` (`LoadedMission`+2) | 1 | - | `LoadMission` | `LoadMission`, `MissionSetup` (`stage1/play2`) |
| `$7E2F` | `ClockText` | 11 | The clock's string: position codes and "00:00", `$FF` | `CodeAt` (`stage1/missions`), `CodeAtColumn` (`stage1/missions`), `CodeInk` (`stage1/missions`), `PrintString` (`stage1/missions`) | `PrintClock` (`stage1/missions`) |
| `$7E82` | `MissionParams` | 382 | 12 bytes of the mission header (`$DBF1`), copied by `$8598` | `BearingTo`, `BoxHeights` (`stage1/play`), `BoxRect` (`stage1/play`), `FillFaceList` (`stage1/play2`), `HelicarrierWait` (`stage1/play`) +9 | `LoadMission`, `PlayerStep`, `MissionSetup` (`stage1/play2`), `BrakeKey` (code) |
| `$87F0` | `BlankMessage` | 12 | The empty message line | `CodeSmallAt`, `CodeSmallFont`, `PrintString` | - |
| `$88EE` | `DayBox` | 5 | An attribute box record (AttrBox) | `PrintString` | - |
| `$88F3` | `NightBox` | 5 | NightBox | `PrintString`, `AttrBox` (`stage1/play`), `AttrBoxAt` (`stage1/play`) | - |
| `$88F8` | `HourTable` | 16 | Four rows: the hour, two attributes, the light value for `$757A` | `PrintString`, `SkyColours`, `TimeOfDay`, `ToggleNight`, `AttrBoxAt` (`stage1/play`) | - |
| `$8908` | `SkyBoxes` | 8 | SkyBoxes | `AttrBoxAt`, `PrintString` | - |
| `$8950` | `KeyCodes` | 40 | 40 key codes, by half row and bit | `PrintString`, `ScanKeyboard` | - |
| `$8978` | `KeyState` | 1 of 6 | KeyFlags (bit 0 new or repeated, bit 1 a key is down), KeyCode, the repeat count, the raw key, the row | `KeyRepeat`, `PlayKeys`, `PlayerStep`, `PrintString`, `ScanKeyboard` +2 | `KeyRepeat`, `ScanKeyboard` |
| `$8979` | `KeyCode` (`KeyState`+1) | 1 | - | `KeyRepeat`, `PlayKeys`, `PlayerStep`, `PrintString`, `DamageKeys` (`stage1/play`) +1 | `KeyRepeat` |
| `$897A` | `KeyRepeatCount` (`KeyState`+2) | 4 | - | `KeyRepeat`, `PrintString` | `KeyRepeat`, `ScanKeyboard` |

## bootstrap

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8044` | `LoadAttrLeftover` | 317 | The rest of the loading screen's attributes (`$8044-$8180`): never read in play. The loader loads the attributes to `$8000-$82FF` (tape block 15); the game's stack and vector table overwrite the end. | - | `InterruptHandler` (`stage1/menu`) |
| `$8181` | `ImJump` | 3 | Unused: JP `$8383` at the IM 2 vector table's target; every vector byte is `$83`, so no interrupt jumps here. The menus' stack overwrites it (lowest `$8149`). | - | `Entry`, `InterruptHandler` (`stage1/missions`) |
| `$8184` | `Stack` | 124 | The main stack, top `$8200` (SP = `$81FF` at the entry). Measured down to `$8149` (menu), `$816B` (play), `$8199` (c1 at the mission load): below `$8184` it runs over ImJump and the end of LoadAttrLeftover (L1 byte_use bit 3, docs/02-architecture.md 2.6). | - | `InterruptHandler` |
| `$8200` | `Im2Table` | 257 | The IM 2 vector table: 257 bytes of `$83` (I = `$82`), filled by Entry | `Entry`, `InterruptHandler` | `Entry` |
| `$8301` | `Armour` | 4 of 73 | The armour: `$8301-$8303` the sides 1-3 (HitSide), `$8304` the top; also Bootstrap's copy destination | `DrawSegments`, `PlayerHit`, `TerrainCollision`, `PrintString` (`stage1/death`), `TerrainScan` (`stage1/missions`) | `PlayerHit`, `SegmentVisibility`, `DrawSegments` (`stage1/missions`) |
| `$8305` | `WorldWork` (`Armour`+4) | 69 | - | `DrawSegments`, `PlayerHit`, `TerrainCollision`, `PrintString` (`stage1/death`), `TerrainScan` (`stage1/missions`) | `SegmentVisibility`, `DrawSegments` (`stage1/missions`) |
| `$834A` | `DamageBoardRecords` | 30 of 57 | Nine 6-byte records of the damage board (icons `$10`, `$11`, `$12`, `$0F`, `$0E`, then the four slots). Records 5-8 are the WeaponSlots `$8368`, written by FitOrRemoveWeapon. StoresToGauges sets gauge k (`$68AB` + 6k) to `$5F` when record k is not 0, else 0. 54 bytes, `$834A-$837F`. | `DrawSlotIcons`, `UpdateAmmoBars`, `ConsumeAmmo` (`stage1/play`), `DrawDamagePanel` (`stage1/play`), `PrintString` (`stage1/death`) +1 | `ConsumeAmmo` (`stage1/play`) |
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
| `$9715` | `ClickState` | 1 of 5 | The click position (X, Y), the fire timer (on, count), the frames per step | `PointerFire`, `PointerZones`, `ReadKeys`, `DecodeDirections` (`stage1/menu`) | `PointerFire`, `SetBinoculars`, `StartMission` |
| `$9716` | `ClickY` (`ClickState`+1) | 1 | - | `PointerZones` | `PointerFire` |
| `$9717` | `FireHeld` (`ClickState`+2) | 1 | - | `PointerFire` | `PointerFire` |
| `$9718` | `FireCount` (`ClickState`+3) | 1 | - | `PointerFire` | `PointerFire` |
| `$9719` | `StepFrames` (`ClickState`+4) | 1 | - | `ReadKeys`, `DecodeDirections` (`stage1/menu`) | `SetBinoculars`, `StartMission` |
| `$9723` | `DeviceReaders` | 10 | Five readers: Sinclair, cursor, Kempston mouse, Kempston joystick, keyboard | `CallTableEntry` | - |
| `$985C` | `InputState` | 2 of 6 | The mouse's last position, the X and Y steps, the token table base. `$9860`: PrintString's token table base (PrintString `$6FDB` uses StepY+1); its words are this table's bytes, not string pointers, and the token path is never taken (play2: the branch at `$6FBA` taken 0 of 3797). | `PlayerSteering`, `PlayerStep`, `PointerTick`, `ReadKeys`, `ClipBothEnds` (`stage1/missions`) +2 | `ReadKeys`, `ClipBothEnds` (`stage1/missions`), `ClipLineCodes` (`stage1/missions`), `DecodeDirections` (`stage1/menu`), `l_A201` (code) +2 |
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
| `$C527` | `WeaponVars` | 13 of 24 | The weapon variables: the rounds shown, the ammunition pointers `$C534`, the current slot `$C53C`. `$C534` holds the four pointers `$836D`, `$8373`, `$8379`, `$837F` (+5 of each slot), `$C53C` the slot 0-3, `$C53D` the address of the slot hook's CALL operand (`$6A46` + 5n). | `RefreshWeaponPanel`, `AutoFireOff` (`stage1/play`), `CodeNumber` (`stage1/play`), `DropMine` (`stage1/play2`), `FireBansheeIr` (`stage1/play2`) +21 | `LoadMission`, `ConsumeAmmo` (`stage1/play`), `DropMine` (`stage1/play2`), `MissionSetup` (`stage1/play2`), `SelectWeapon` (`stage1/play`) +2 |
| `$C534` | `AmmoPointers` (`WeaponVars`+13) | 8 | the four slots' ammunition bytes `$836D`, `$8373`, `$8379`, `$837F` | `SelectAmmoPointer` (`stage1/play`) | - |
| `$C53C` | `CurrentSlot` (`WeaponVars`+21) | 3 | 0-3 | `AutoFireOff` (`stage1/play`), `DropMine` (`stage1/play2`), `FireBansheeIr` (`stage1/play2`), `FireBansheeRr` (`stage1/play`), `FireCannon` (`stage1/play2`) +18 | `SelectWeapon` (`stage1/play`) |
| `$C618` | `DamagedText` | 26 | "DAMAGED IN COMBAT". PrintString text: `$07` position codes and "DAMAGED", "IN", "COMBAT". | - | - |
| `$CBBD` | `HitVars` | 9 | Variables of PlayerHit. `$FF` in the image. | - | - |
| `$CC05` | `PushBackWork` | 4 | Work bytes of PushBack. Zero in the image. | `l_CBDA` (code), `l_CBF6` (code) | `CollisionPass` |
| `$CC2B` | `HeadingAwayCode` | 8 | Code no recording runs (heading + `$80`). `CALL $67C1` / `ADD A,$80` / `LD (IX+$22),A`: turn away from the hitter. | - | - |
| `$CFF4` | `MineTimerCode` | 8 | The mine timer up (not run). `LD A,n` (n = `$CFF5`, the mine timer), `INC A`, `CP $78`, `JR C`, `XOR A`: the up key's copy of SetMineTimer. | `CodeNumber` (`stage1/play2`), `MineFall` (`stage1/play2`), `SetMineTimer` (`stage1/play2`), `MineArm` (code) | `SetMineTimer` (`stage1/play2`), `StoreMineTimer` (code) |
| `$D0AB` | `MineHudText` | 7 | The mine HUD's text. PrintString codes for the mine's HUD. | `CodeNumber` (`stage1/play2`), `CodeSmallAt` (`stage1/play2`), `CodeSmallFont` (`stage1/play2`), `PrintString` (`stage1/play2`) | `DropMine` (`stage1/play2`), `SelectWeapon` (`stage1/play`) |
| `$D114` | `SlotShown` | 1 | The slot whose rounds are shown. PrintAmmo `$C510` compares `$D114` with the current slot `$C53C`; the slot hooks (SlamFire, SpectreCode, the Phantasm's `$D3E6`) store their slot here and put the old value back after. | `PrintAmmo` (`stage1/play`), `PhantasmCode` (code), `SpectreCode` (code) | `SelectWeapon` (`stage1/play`), `SlamFire` (code), `l_D3DF` (code), `sub_D330` (code), `sub_D3E6` (code) |
| `$D21B` | `data_D21B` | 48 | data_D21B | `SlamFire` (code) | - |
| `$D485` | `HudCopyCode` | 31 | Code no recording runs: copy 24 rows to `$FD00` through `$D49B` | - | - |
| `$D512` | `AwolBlankText` | 13 of 28 | The blank that clears the AWOL warning, and the head of the warning. PrintString text: `$07` `$8D` `$10`, ten blanks, `$FF` (the warning cleared); `$D51F` starts "GOING AWOL" (`$07` `$8D` `$10` then the text at `$D521`). | - | - |
| `$D51F` | `AwolWarningText` (`AwolBlankText`+13) | 15 | the start of "GOING AWOL"; its text from `$D521` on is taken as code by the walk (a bank 6 CALL target `$D521` from `$6B35`) | - | - |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B3C9` | `WeaponTemplates` | 1 of 391 | The resident templates of the projectile types `$80-$8C`: 13 records of 30 bytes from `$B3CA`. ObjectSetType `$BD41` copies record (type - `$80`) when the type has bit 7: the 30 bytes become +2..+`$1F` of the object (the type itself is +1) (flags, colour, height, speed, box, hit points, damage, radius, step handler, collision handler, model, score). `$80` K-40 mortar shell (step `$B5E8`), `$81` cannon shell (`$B592`), `$82` Banshee RR, `$83` Phoenix RR, `$84` Banshee IR, `$85` Phoenix IR, `$86` Dragonfly, `$87` K-90 cluster bomb (`$CF4A`), `$88` Sleeper mine, `$89` Skeet bomb, `$8A` Phantasm (the decoy of the homing shell type 28), `$8B` Spectre, `$8C` the Helicarrier. The byte at `$B3C9` (`$C9`) is the RET of the routine before. | `ObjectSetType` (`stage1/play`) | - |
| `$B3CA` | `ShellTemplate80` (`WeaponTemplates`+1) | 390 | template `$80`, the K-40 mortar shell; 30 bytes a type up to `$8C` | `ObjectSetType` (`stage1/play`) | - |
| `$B9DE` | `BearingTable` | 24 | The arctangent table of BearingTo. 24 bytes of angles read by BearingLookup `$B95A`. | `BearingLookup`, `SetCamera` | `CameraToPlayer`, `LaunchDragonfly` (`stage1/play`), `DragonflyRetake` (code) |
| `$BBF0` | `ActivateIndexSave` | 1 | Saved operand of ActivateMissionObjects. The byte before ActivateMissionObjects; its index operands are `$BBF2` / `$BBFA`. | `ActivateMissionObjects` | `ActivateMissionObjects`, `Bootstrap` |
| `$BF20` | `DepthTreeVars` | 4 | Variables of the depth tree. Zero in the image; the walk of the tree keeps its stack depth here. | `DepthInsert` | `Bootstrap`, `ClearDepthTree`, `DepthInsert` |
| `$C648` | `CollisionTables` | 372 | The collision pair timers, the slot list `$C775`, the row pointers `$C78C`. Filled with `$FF` by `$6928` before a mission. | `CollisionPass`, `RegisterCollision`, `ResetCollisionTables`, `UnregisterCollision` | `CollisionPass`, `RegisterCollision`, `ResetCollisionTables`, `UnregisterCollision` |

## world

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AE5A` | `SegmentWalkCount` | 2 | The segments left in the walk and the walk index. Written by ResetSegmentWalk `$AE42`. | `SegmentVisibility` | `ResetSegmentWalk`, `SegmentVisibility` |
| `$AE82` | `SegmentScratch` | 30 | 30 bytes of scratch for the segment draw. Zero in every image; the segment drawing keeps its working values here (the word at `$AE9E` is read by DrawSegmentTail `$B18A`). | `StoreVertex`, `TransformSegmentEnds`, `ClipDiagonalSide` (`stage1/m2erbe`), `ClipSegmentDiagonal` (`stage1/missions`), `DrawSegmentTail` (`stage1/missions`) +3 | `DrawSegments`, `StoreVertex`, `ClipDiagonalSide` (`stage1/m2erbe`), `ClipSegmentAxisY` (`stage1/missions`), `ClipSegmentDiagonal` (`stage1/missions`) +2 |
| `$BA6E` | `ViewTexts` | 12 of 62 | The view labels: IR:SIGHT, REAR:VIEW, BINOC:X2 and their blanks. Strings for PrintString `$6FB3` (`$07` position code, `$FF` end): `$BA6E` "IR:SIGHT", `$BA7A` blank, `$BA86` "REAR:VIEW", `$BA93` "BINOC:X2" (the digit at `$BA9D`), `$BA9F` blank. | `CodeSmallAt`, `CodeSmallFont`, `PrintString` | `Bootstrap`, `l_CF18` (code) |
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
| `$D674` | `AYRegs` | 14 of 30 | The AY register shadow R0-R13, written by WriteAY `$D7DC` | `EngineTone`, `SetNoise`, `SoundFrame` | `EngineTone`, `SetNoise`, `SilenceAY`, `SoundEffectA`, `SoundExplosion` +12 |
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
| `$D68D` | `SweepCount` (`AYRegs`+25) | 1 | - | `SoundFrame` | `SoundSweep` (code), `l_D781` (code) |
| `$D68E` | `SirenCount` (`AYRegs`+26) | 3 | - | `SoundFrame` | `l_D7A7` (code), `l_D891` (code) |
| `$D691` | `SoundMaster` (`AYRegs`+29) | 1 | 1 in the image, never written | `SoundFrame` | - |
| `$D8A0` | `SoundFireVar` | 1 | A spare byte after SoundFire. `$0A`, after the RET of SoundFire; no routine of this fragment reads it. | - | - |


## Bank 3 (`src/bank3/bank3.json`)

Battle Command, Ocean 1990: RAM bank 3, paged at `$C000`, as its tape block loads it. Its entries are
`src/bank3/<module>.asm`, written from `src/bank3/bank3.ann` by `kit/mkgame.py --part src/bank3/bank3.json`; the
readers and writers from `work/stage1/c1g`, `work/stage1/menu`, `work/stage1/missions`, `work/stage1/play`,
`work/stage1/play2`, `work/stage1/death`, `work/stage1/m2ocean`, `work/stage1/m2erbe`, `work/stage1/search`,
`work/stage1/m10`.

### Bank 3: raster3

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C99F` | `data_C99F` | 4 | data_C99F | - | - |
| `$CA89` | `LinePixelBit` | 2 | DrawLine's start pixel bit number, and a spare byte | `DrawVerticalLine`, `DrawLine` (`stage1/menu`) | `DrawLine` |
| `$CA8B` | `SharedModels` | 1346 | Shared 3D model scripts (RunScript format), 1346 bytes: six models and their parts. `$CA8B` (a building with two halves ordered by face 0: parts `$CAA7`, `$CCDA`), `$CAA7` (32 vertices, 24 faces, nested parts with OpCall to `$CDF8`), `$CCDA`, `$CDF8` (a sub-model called twice), `$CE47`, `$CED1` (`$CB39` of bank 6 draws it), `$CF26`. Each starts with a box generator (`00 F7 67` = BoxRect). Read by RunScript `$990F` in all 11 recordings. | - | - |

### Bank 3: debris

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CFEC` | `DebrisRecords` | 160 | The eight fragment records, 20 bytes each (zero at the entry). +0 flags (bit 7 live, bit 5 drawn this frame; 0 = free), +1 x (fraction, then a word), +4 z (fraction, word), +7 y (word), +`$0A` the turn, +`$0B` the distance word from `$BBBC`, +`$0D` y relative to the camera, +`$0F` x speed, +`$10` z speed, +`$11` y speed, +`$12` and +`$13` the two turn steps. Written by `$B74B` / `$B75C` (death, play2), MoveDebris and DrawDebris. Witness: death, play2 (MoveDebris runs 661 times); the other recordings only read the flags. | `DrawDebrisNext`, `MoveAllDebris`, `DebrisInView` (`stage1/play2`), `DrawDebris` (`stage1/play2`), `MoveDebris` (`stage1/play2`) | `DrawDebrisNext`, `DrawDebris` (`stage1/play2`), `MoveDebris` (`stage1/play2`) |
| `$D203` | `PushLeftover` | 509 | 509 bytes `$E5` (PUSH HL) to the end of the block: never run, never read. No recording reads or runs `$D203-$D3FF`; it looks like the tail of an unrolled PUSH clear (as ClearBackBuffer `$96F1`) left from development (known only from the code). | - | - |


## Bank 4 (`src/bank4/bank4.json`)

Battle Command, Ocean 1990: RAM bank 4, paged at `$C000`, as its tape block loads it. Its entries are
`src/bank4/<module>.asm`, written from `src/bank4/bank4.ann` by `kit/mkgame.py --part src/bank4/bank4.json`; the
readers and writers from `work/stage1/c1g`, `work/stage1/menu`, `work/stage1/missions`, `work/stage1/play`,
`work/stage1/play2`, `work/stage1/death`, `work/stage1/m2ocean`, `work/stage1/m2erbe`, `work/stage1/search`,
`work/stage1/m10`.

### Bank 4: music

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C05A` | `ChannelRecords` | 39 of 120 | The three channels' records, 39 bytes each: A at `$C05A`, B at `$C081`, C at `$C0A8`. Fields: +0 flags (bit 0 the vibrato's half phase, bit 1 set by command `$8D`, bit 2 slide, bit 3 bend, bit 5 the volume envelope runs, bit 7 bend up), +1 the pattern pointer, +3 the order list pointer, +5 the order list's start, +7 the slide's sum, +9 the ornament (start), +`$0B` the ornament (now), +`$0D` the slide step, +`$0E` the slide delay, +`$0F` the instrument's speed, +`$10` the frames left of the note, +`$11` the fixed duration, +`$12` the note, +`$13` the volume, +`$14` the instrument, +`$16` its envelope pointer, +`$18` its volume now, +`$19` its speed count, +`$1A` the vibrato depth, +`$1B` its step, +`$1C` its position, +`$1D` the vibrato mode (`$40` on, `$C0` every other frame, bit 5 the direction), +`$1E` noise follows the note, +`$1F` the drum (bit 7 a hit pending), +`$20` the pattern's transpose, +`$21` the repeat count, +`$22` the repeat's start, +`$24` durations inline, +`$25` take the next pattern, +`$26` the channel's mixer bits (`$09`, `$12`, `$24`). Zero at the entry but the mixer bits. | `ChannelSound`, `ChannelStep`, `CmdHold`, `CmdTone`, `CmdToneNoise` +8 | `ChannelSound`, `ChannelStep`, `CmdDrumOff`, `CmdHold`, `CmdInlineDurations` +18 |
| `$C081` | `ChannelB` (`ChannelRecords`+39) | 39 | - | `ChannelSound`, `ChannelStep`, `CmdHold`, `CmdTone`, `NextPattern` +3 | `ChannelSound`, `ChannelStep`, `CmdDrumOff`, `CmdHold`, `CmdInlineDurations` +11 |
| `$C0A8` | `ChannelC` (`ChannelRecords`+78) | 39 | - | `ChannelSound`, `ChannelStep`, `CmdToneNoise`, `NextPattern`, `ReadStream` +3 | `ChannelSound`, `ChannelStep`, `CmdDrumOff`, `CmdInlineDurations`, `CmdToneNoise` +8 |
| `$C0CF` | `SpeedCount` (`ChannelRecords`+117) | 1 | frames to the next step of the patterns | `MusicTick` | `MusicTick`, `StartTune` |
| `$C0D0` | `MusicOn` (`ChannelRecords`+118) | 1 | - | `MusicTick` | `StartTune`, `StopMusicCore` |
| `$C0D1` | `EffectOn` (`ChannelRecords`+119) | 1 | - | `EffectTick`, `MusicTick`, `l_C2F5` (code), `l_C5FD` (code) | `StartTune`, `StopMusicCore`, `EffectTick` (code), `StartEffect` (code), `l_C5FD` (code) |
| `$C1C7` | `CommandOffsets` | 20 | The commands `$80-$93`: each byte the distance from itself to the command's routine. Read by Command (`$C362`: HL = `$C147` + the command byte, so `$80` reads `$C1C7`). | `Command` | - |
| `$C47B` | `AYShadow` | 6 of 25 | The AY registers 0-11 as MusicTick writes them, then the effect's values. `$C47B`-`$C480` the three tone periods, `$C481` noise, `$C482` mixer, `$C483`-`$C485` the volumes, `$C486` register 11. `$C488`-`$C492` the effect's tone A, tone C, noise, mixer mask and volumes (StartEffect, EffectTick). | `ChannelSound`, `MusicTick`, `l_C68B` (code), `l_C6A5` (code), `l_C6B2` (code) +2 | `ChannelSound`, `MusicTick`, `StopMusicCore`, `l_C5FD` (code), `l_C674` (code) +5 |
| `$C481` | `AYNoise` (`AYShadow`+6) | 1 | - | `MusicTick` | `MusicTick` |
| `$C482` | `AYMixer` (`AYShadow`+7) | 1 | - | `ChannelSound`, `MusicTick` | `ChannelSound`, `EffectMix` (code) |
| `$C483` | `AYVolumes` (`AYShadow`+8) | 5 | - | `MusicTick` | `MusicTick`, `StopMusicCore` |
| `$C488` | `EffectRegs` (`AYShadow`+13) | 12 | - | `EffectMix` (code), `l_C68B` (code), `l_C6A5` (code), `l_C6B2` (code), `l_C6C8` (code) +1 | `l_C5FD` (code), `l_C674` (code), `l_C68B` (code), `l_C6A5` (code), `l_C6B2` (code) +2 |
| `$C494` | `NoteTable` | 192 | The AY tone periods of 96 notes, 8 octaves from `$0EF8` down to `$000F`. Read by ChannelSound (`$C3BD`). | `ChannelSound` | - |
| `$C6DC` | `EffectTable` | 2 of 19 | The effects' addresses: one effect, at `$C6DE` | - | - |
| `$C6DE` | `Effect0` (`EffectTable`+2) | 17 | 17 bytes: time, speed, tone A, tone C, envelope, mixer mask, slides, repeats | - | - |
| `$C6EF` | `EffectState` | 19 | The running effect: a copy of its 17 bytes and the speed count `$C700` | `EffectTick` (code), `l_C5FD` (code), `l_C652` (code), `l_C674` (code), `l_C68B` (code) +3 | `l_C5FD` (code), `l_C652` (code), `l_C68B` (code) |
| `$C71D` | `RandomSeed` | 4 | The generator's 32 bits | `NextRandom`, `l_C652` (code) | `NextRandom` |
| `$C721` | `OrnamentOffsets` | 7 | The ornaments: each byte the distance from itself to the ornament. Read by Command (`$C32D`). | `Command` | - |
| `$C728` | `Ornaments` | 50 | Seven ornaments: semitone offsets, a byte with bit 7 ends one (its low bits the last offset) | `ChannelSound` | - |
| `$C75A` | `Instruments` | 26 | Thirteen instruments' envelope addresses (each with its speed in the byte before) | `Command` | - |
| `$C774` | `InstrumentData` | 245 | The instruments' volume envelopes | `ChannelSound`, `Command`, `ReadStream` | - |
| `$C869` | `TuneTable` | 7 | The only tune: its speed and the order lists of channels A, B, C | `StartTune` | - |
| `$C870` | `PatternTable` | 34 | The 17 patterns' addresses | `NextPattern` | - |
| `$C892` | `OrderLists` | 122 | The three channels' order lists | `NextPattern` | - |
| `$C90C` | `Patterns` | 600 | The 17 patterns: notes, durations, commands | `CmdVibrato`, `ReadStream`, `SetDuration`, `CmdDuration` (`stage1/menu`) | - |
| `$CB64` | `CatalogueSpace` | 668 | Where the mission catalogue loads (`$CB64`, 7124 bytes): `$E5` bytes and zeros on the tape. LoadDirectory (`$715D`, bank 5) reads the DIRECTORY block here with LdBytes (`$8617`; writes `$CB64-$E737` in menu); the tape's bank 4 block carries only `$E5` filler, three zeros and 16 zeros at the end. | - | - |


## Bank 6 (`src/bank6/bank6.json`)

Battle Command, Ocean 1990: RAM bank 6, paged at `$C000`, as its tape block loads it. Its entries are
`src/bank6/<module>.asm`, written from `src/bank6/bank6.ann` by `kit/mkgame.py --part src/bank6/bank6.json`; the
readers and writers from `work/stage1/c1g`, `work/stage1/menu`, `work/stage1/missions`, `work/stage1/play`,
`work/stage1/play2`, `work/stage1/death`, `work/stage1/m2ocean`, `work/stage1/m2erbe`, `work/stage1/search`,
`work/stage1/m10`.

### Bank 6: pointer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C000` | `PointerShapes` | 16 of 32 | The two pointer shapes: 8 lines of a mask byte and a pixel byte each. Line n is two bytes: the mask (`AND` with the screen, shifted in with ones) and the pixels (`OR`). ShiftPointer `$D282` reads the shape its operand `$D283` points at. The arrow at `$C000` is set by the catalogue, the briefing and the stores; the boxed shape at `$C010` by ShowWaitPointer `$CBF4` when a screen is left, so it shows while the next one is drawn. | `ShiftPointer` | - |
| `$C010` | `WaitPointer` (`PointerShapes`+16) | 16 | the boxed shape shown between screens | `ShiftPointer` | - |
| `$C020` | `PointerBackground` | 16 | The 8 x 2 screen bytes under the pointer. Written by SavePointerBackground `$D0CA` (from the screen) and CopyViewUnderPointer `$D142` (from the back buffer), put back by RestorePointerBackground `$D251`. | `RestorePointerBackground` | `CopyViewUnderPointer`, `SavePointerBackground` |
| `$D2D1` | `ShiftedPointer` | 32 | The pointer shifted to the pixel: 8 lines of mask (2 bytes) and pixels (2 bytes). Written by ShiftPointer, read by PutPointer and DrawPointerInView. | `DrawPointerInView`, `PutPointer` | `ShiftPointer` |
| `$D32B` | `PointerLimits` | 4 of 12 | Three records of the pointer's limits: X min, X max, Y min, Y max. Copied to `$7D99`, `$7D9B`, `$7DA4`, `$7DA6` by SetPointerLimits: `$D32B` the catalogue, `$D32F` the stores, `$D333` the title. | `SetPointerLimits`, `CataloguePointerLimits` (`stage1/m2ocean`) | - |
| `$D32F` | `StoresLimits` (`PointerLimits`+4) | 4 | - | `SetPointerLimits` | - |
| `$D333` | `TitleLimits` (`PointerLimits`+8) | 4 | - | `SetPointerLimits` | - |

### Bank 6: catalogue

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C851` | `CatalogueZones` | 31 | Zone table of the catalogue. LoadMissionHeader `$84FE`, LoadMissionIfAllowed `$759A`, ScreenOfMission `$757C`, `$67EE` (ScreenFour: the mission status), SelectMissionLine `$D013` (the list). | - | - |
| `$C881` | `CatalogueMagic` | 13 | "MISSION:TAPE:": the first 7 bytes are compared with the catalogue's head. Read by IsCatalogueLoaded. | `IsCatalogueLoaded` | - |
| `$C8A0` | `DiskTexts` | 18 of 216 | Texts: "INCORRECT DISK", "INSERT DISK AND PRESS SPACE", the tape messages. Small-font texts (code 7 at a line and column), `:` is the blank, `[` a full stop. `$C8A0` read by ShowWrongDisk; `$C8B2` and `$C90D` by nothing in bank 6. | - | - |
| `$C8B2` | `InsertDiskText` (`DiskTexts`+18) | 35 | - | - | - |
| `$C8D5` | `CataloguePos` (`DiskTexts`+53) | 4 | code 7 to line `$20`, column 5 (MissionCatalogueScreen `$C825`) | - | - |
| `$C8D9` | `RewindText` (`DiskTexts`+57) | 52 | "REWIND MISSION TAPE TO START AND PRESS PLAY" | - | - |
| `$C90D` | `FoundCatalogueText` (`DiskTexts`+109) | 49 | "FOUND MISSION CATALOGUE AND NOW LOADING" | - | - |
| `$C93E` | `BlankTapeText` (`DiskTexts`+158) | 58 | three blank lines: PrintRewind `$719B` | - | - |
| `$C978` | `TickGraphic` | 8 | The tick of a completed mission, 1 x 8. CopyGraphic source of MissionCatalogueScreen `$C7F7`. | - | - |
| `$C980` | `BriefingBoxes` | 5 of 10 | Two attribute box records of the briefing. Read by BriefingScreen `$C9AB` and `$C9B1`. | - | - |
| `$C985` | `BriefingBoxB` (`BriefingBoxes`+5) | 5 | - | - | - |
| `$CFEF` | `ListLinePos` | 4 | Text: code 7 to line `$41` (moved for every line), column 5. Written and printed by PrintMissionList. | `PrintMissionList` | `PrintMissionList` |
| `$D00E` | `SelectedPos` | 5 | Text: code 7 to line `$2A`, column 5; a zero byte. Printed by PrintSelectedMission. | - | - |
| `$D09A` | `DescriptionPos` | 6 | Text: code 9, code 7 to line `$88`, column `$12`. Printed by PrintMissionDescription. | - | - |

### Bank 6: statusview

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C089` | `BriefPageBoxRecord` | 5 | An attribute box record (width, height, column, attribute, row) for the unused variant `$C08E`. Read only by BriefPageBoxSmall. | - | - |
| `$C0AC` | `BriefPageBoxes` | 5 of 20 | Four attribute box records of the briefing texts. `$C0AC` read by BriefPageBoxLarge, `$C0B1` by BriefPageBox, `$C0B6` by BriefingTextOnce (`$70A8`), `$C0BB` by BriefPageText (`$70C0`); none of the four is read inside bank 6. | - | - |
| `$C0B1` | `BriefPageBoxB` (`BriefPageBoxes`+5) | 5 | - | - | - |
| `$C0B6` | `BriefPageBoxC` (`BriefPageBoxes`+10) | 5 | - | - | - |
| `$C0BB` | `BriefPageBoxD` (`BriefPageBoxes`+15) | 5 | - | - | - |
| `$C101` | `GridText` | 19 | Text: the two positions "00:00" at line `$50` and line `$70`, column 1. Control code 2 (a pixel line and a column), code 13 (attribute `$47`); the digits at `$C106` and `$C10E` are written by FormatGridPosition. | - | `FormatGridPosition` (`stage1/missions`) |

### Bank 6: stores

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C257` | `StoresMessageBox` | 5 | The attribute box of the error message line. Read by FitOrRemoveWeapon at `$C23E`. | - | - |
| `$C2F9` | `PayloadLineBox` | 5 | The attribute box of the payload lines. Read by StoresMessageTimer `$C2DE`. | - | - |
| `$C371` | `CurrentWeapon` | 2 | The record of the shown weapon (WeaponRecords + 1 + 11n). Set by StoresScreen `$CAE3`, moved by NextWeapon and PreviousWeapon, read by ShowWeapon and FitOrRemoveWeapon. | `ShowWeapon`, `SlotZoneA`, `FitOrRemoveWeapon` (`stage1/play`), `NextWeapon` (`stage1/play`), `PreviousWeapon` (code) | `StoresScreen`, `NextWeapon` (`stage1/play`), `PreviousWeapon` (code), `PreviousWeaponStep` (code) |
| `$C373` | `WeaponRecords` | 1 of 145 | `$FF`, the 13 weapon records of 11 bytes, `$FF`. A record: +0 the type (1-13; IconTable `$75CA` entry type - 1), +1 the ammunition, +2 the most the four slots may hold, +3 the weight in kg (word), +5 the 3 x 24 icon, +7 the description text, +9 the model script (bank 3 `$CExx`, or bank 2). The `$FF` before and after stop NextWeapon and PreviousWeapon. The Sleeper mine's record says 300 kg, its text 290 KG. | `ShowWeapon`, `SlotZoneA`, `FitOrRemoveWeapon` (`stage1/play`), `NextWeapon` (`stage1/play`) | - |
| `$C374` | `WeaponTurret` (`WeaponRecords`+1) | 11 | type 4 Turret: ammo 80, max 1, 400 kg, icon `$F444` | `ShowWeapon`, `SlotZoneA`, `FitOrRemoveWeapon` (`stage1/play2`) | - |
| `$C37F` | `WeaponBansheeRRSS` (`WeaponRecords`+12) | 11 | type 2: ammo 8, max 2, 300 kg | `FitOrRemoveWeapon` (`stage1/play`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C38A` | `WeaponBansheeIRSS` (`WeaponRecords`+23) | 11 | type 6: ammo 6, max 2, 300 kg | `FitOrRemoveWeapon` (`stage1/play2`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C395` | `WeaponPhoenixRRSA` (`WeaponRecords`+34) | 11 | type 1: ammo 8, max 2, 250 kg | `FitOrRemoveWeapon` (`stage1/play2`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C3A0` | `WeaponPhoenixIRSA` (`WeaponRecords`+45) | 11 | type 5: ammo 6, max 2, 250 kg | `FitOrRemoveWeapon` (`stage1/play2`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C3AB` | `WeaponK40Mortar` (`WeaponRecords`+56) | 11 | type 3: ammo 20, max 2, 250 kg | `FitOrRemoveWeapon` (`stage1/play`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C3B6` | `WeaponSleeperMine` (`WeaponRecords`+67) | 11 | type 9: ammo 5, max 2, 300 kg | `FitOrRemoveWeapon` (`stage1/play2`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C3C1` | `WeaponDragonfly` (`WeaponRecords`+78) | 11 | type 7: ammo 3, max 2, 500 kg | `FitOrRemoveWeapon` (`stage1/play`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C3CC` | `WeaponK90Cluster` (`WeaponRecords`+89) | 11 | type 8: ammo 20, max 4, 250 kg | `FitOrRemoveWeapon` (`stage1/play2`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C3D7` | `WeaponSpectre` (`WeaponRecords`+100) | 11 | type 13: ammo 12, max 2, 100 kg | `FitOrRemoveWeapon` (`stage1/play2`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C3E2` | `WeaponPhantasm` (`WeaponRecords`+111) | 11 | type 12: ammo 8, max 2, 100 kg | `FitOrRemoveWeapon` (`stage1/play`), `NextWeapon` (`stage1/play`), `ShowWeapon` (`stage1/play`) | - |
| `$C3ED` | `WeaponSkeetBomb` (`WeaponRecords`+122) | 11 | type 11: ammo 12, max 2, 200 kg | `FitOrRemoveWeapon` (`stage1/play2`), `NextWeapon` (`stage1/play2`), `ShowWeapon` (`stage1/play2`) | - |
| `$C3F8` | `WeaponSlamLaser` (`WeaponRecords`+133) | 12 | type 10: ammo 40, max 1, 250 kg | `FitOrRemoveWeapon` (`stage1/play2`), `NextWeapon` (`stage1/play2`), `ShowWeapon` (`stage1/play2`) | - |
| `$C404` | `TitleBox` | 5 | The attribute box of the title menu's 3D window. Read by TitleMenu `$C4A7`. | - | - |
| `$CBC4` | `StoresZones` | 43 | Zone table of the stores. ScreenFromClick `$7055` (start), NextWeapon, PreviousWeapon, SlotZoneA, SlotZoneB, SlotZoneC, SlotZoneD. | - | - |
| `$CBEF` | `StoresSpareBox` | 5 | An attribute box record no routine reads. Known only from the code. | - | - |
| `$D6DA` | `WeaponTexts` | 42 of 165 | The weapon descriptions (Phoenix RRSA, Phoenix IRSA, Banshee IRSS, Dragonfly): name, weight, ammo, max. Printed by ShowWeapon through the records' +7. Code 13 (attribute), code 2 (at a line and column), code 9, code 11 (new line). | - | - |
| `$D704` | `TextPhoenixIRSA` (`WeaponTexts`+42) | 42 | - | - | - |
| `$D72E` | `TextBansheeIRSS` (`WeaponTexts`+84) | 42 | - | - | - |
| `$D758` | `TextDragonfly` (`WeaponTexts`+126) | 39 | - | - | - |
| `$D7BB` | `WeaponTextsB` | 42 | The Banshee RRSS description. Printed by ShowWeapon. | - | - |
| `$D7E5` | `PanelBoxes` | 5 of 15 | Attribute box records of the panel. `$D7EA` and `$D7EF` read by PanelAttributes; `$D7E5` by nothing. | - | - |
| `$D7EA` | `PanelBoxA` (`PanelBoxes`+5) | 5 | - | - | - |
| `$D7EF` | `PanelBoxB` (`PanelBoxes`+10) | 5 | - | - | - |
| `$D7F4` | `WeaponTextsC` | 41 of 322 | The descriptions of SLAM Laser, Sleeper mine, Skeet bomb, Spectre, K-40 Mortar, Turret, Phantasm, K-90 Cluster. Printed by ShowWeapon. | - | - |
| `$D81D` | `TextSleeperMine` (`WeaponTextsC`+41) | 42 | - | - | - |
| `$D847` | `TextSkeetBomb` (`WeaponTextsC`+83) | 41 | - | - | - |
| `$D870` | `TextSpectre` (`WeaponTextsC`+124) | 38 | - | - | - |
| `$D896` | `TextK40Mortar` (`WeaponTextsC`+162) | 42 | - | - | - |
| `$D8C0` | `TextTurret` (`WeaponTextsC`+204) | 37 | - | - | - |
| `$D8E5` | `TextPhantasm` (`WeaponTextsC`+241) | 38 | - | - | - |
| `$D90B` | `TextK90Cluster` (`WeaponTextsC`+279) | 43 | - | - | - |
| `$D936` | `PayloadLineText` | 45 of 124 | Texts of the payload: "MAX PAYLOAD 1000KG", "PAYLOAD WGT 0KG", the two errors, the weight. `$D936` printed by StoresScreen and StoresMessageTimer, the errors by FitOrRemoveWeapon, PayloadText by PrintPayloadWeight. | `NumberToDigits`, `FormatGridPosition` (`stage1/missions`) | `DigitOf`, `NumberToDigits` |
| `$D963` | `PayloadExceededText` (`PayloadLineText`+45) | 45 | - | - | - |
| `$D990` | `MaxNumberText` (`PayloadLineText`+90) | 24 | - | - | - |
| `$D9A8` | `PayloadText` (`PayloadLineText`+114) | 3 | - | - | - |
| `$D9AB` | `PaddedDigits` (`PayloadLineText`+117) | 7 | five digits, written by NumberToDigits | `NumberToDigits`, `FormatGridPosition` (`stage1/missions`) | `DigitOf`, `NumberToDigits` |

### Bank 6: title

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C4DC` | `StatusScreenZones` | 13 | Zone table of the mission status screen: x1, x2, y1, y2, routine. Read by PointerZones `$6D42` on MissionStatusScreen (node `$756A`): ScreenZero `$705A` (ShowPassword) and ScreenTwo `$705E` (back to the catalogue). A 0 ends it. | - | - |
| `$C4E9` | `TitleZones` | 19 | Zone table of the title menu. ScreenZero (the catalogue), `$67EE` (ApiVector16, ScreenFour: the options) and ScreenTwo (the password entry). | - | - |

### Bank 6: password

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C53E` | `PasswordMessages` | 22 of 58 | Texts: "INVALID PASSWORD", then two blank lines that clear it and the entry. Printed by PasswordScreen at `$C5A5`, `$C5AE` and `$C5B4`. | - | - |
| `$C554` | `InvalidBlank` (`PasswordMessages`+22) | 22 | - | - | - |
| `$C56A` | `EntryBlank` (`PasswordMessages`+44) | 14 | - | - | - |
| `$C5EE` | `PasswordPrompt` | 32 | Text: "Type in your level entry:-". Printed by PasswordScreen `$C57B`. | - | - |
| `$C60E` | `PasswordBuffer` | 10 | The ten characters typed (EditLine's line). Filled with spaces by PasswordScreen, written by EditLine, read by CharsToPassword. The image holds leftover code bytes here. | `CharsToPassword` (`stage1/menu`), `PrintRawString` (`stage1/menu`) | `EditLine` (`stage1/menu`), `PasswordScreen` (`stage1/menu`) |
| `$C618` | `PasswordLeftover` | 8 | The buffer's end marks, then leftover bytes "...DAMAG": never read. EditLine writes its end marks to `$C618-$C619`; no routine reads `$C61A-$C61F`. | `PrintRawString` (`stage1/menu`) | `EditLine` (`stage1/menu`) |
| `$C6FA` | `CursorAttrPtr` | 2 | EditLine's cursor attribute address. Written and read by EditLine. | `EditLine` (`stage1/menu`), `EditLengthOp` (code), `EditMaxOp` (code), `EditNextKey` (code) | `EditLine` (`stage1/menu`), `EditLineStart` (code), `EditMaxOp` (code), `EditNextKey` (code) |
| `$C727` | `EditLineBuffer` | 2 | EditLine's buffer address. Written by EditLine `$C64E`, read at `$C673`. | `EditLine` (`stage1/menu`), `EditEnter` (code), `EditRedraw` (code) | `EditLine` (`stage1/menu`), `EditLineAt` (code) |
| `$C729` | `PasswordZones` | 1 | Zone table of the password screen: empty. PointerZones finds the end at once. | - | - |
| `$C72A` | `EntryStringText` | 32 | Text: "THIS IS YOUR ENTRY STRING.". Printed by ShowPassword. | - | - |
| `$C74A` | `MenuBoxes` | 5 of 21 | Attribute box records: the whole menu screen and the catalogue's titles. `$C74A` read by ClearMenuScreen, `$C74F` and `$C754` by DrawCatalogueTitles, `$C759` by MissionCatalogueScreen. `$C75E` is a 0 byte. | - | - |
| `$C74F` | `CatalogueTitleBoxA` (`MenuBoxes`+5) | 5 | - | - | - |
| `$C754` | `CatalogueTitleBoxB` (`MenuBoxes`+10) | 5 | - | - | - |
| `$C759` | `CatalogueListBox` (`MenuBoxes`+15) | 6 | - | - | - |
| `$CE7D` | `DecodedFlags` | 10 | The ten completion flags DecodePassword makes. Copied to MissionsDone by PasswordScreen. | `PasswordScreen` (`stage1/menu`) | `DecodePassword` (`stage1/menu`) |
| `$CE87` | `DecodedScore` | 4 | The score DecodePassword makes. Copied to Score by PasswordScreen. | `DecodePassword` (`stage1/menu`), `PasswordScreen` (`stage1/menu`) | `DecodePassword` (`stage1/menu`) |
| `$CEF6` | `PasswordText` | 5 of 16 | Text: the password line; its ten characters at `$CEFB`. Written by EncodePassword, PasswordToChars and CharsToPassword (the values), printed by ShowPassword. | `DecodePassword` (`stage1/menu`), `PasswordToChars` (`stage1/menu`) | `CharsToPassword` (`stage1/menu`), `EncodePassword` (`stage1/menu`), `PasswordToChars` (`stage1/menu`) |
| `$CEFB` | `PasswordValues` (`PasswordText`+5) | 11 | - | `DecodePassword` (`stage1/menu`), `PasswordToChars` (`stage1/menu`) | `CharsToPassword` (`stage1/menu`), `EncodePassword` (`stage1/menu`), `PasswordToChars` (`stage1/menu`) |
| `$CF5F` | `PasswordAlphabet` | 36 | The 36 password characters: "9876543210ZYXWVUTSRQPONMLKJIHABCDEFG". Read by PasswordToChars and CharsToPassword. | `CharsToPassword` (`stage1/menu`), `PasswordToChars` (`stage1/menu`) | - |
| `$CF83` | `CatalogueHead` | 2 of 38 | Two zero bytes, then the catalogue's first 32 bytes copied by CopyCatalogueHead. `$CF85-$CFA4` is written by CopyCatalogueHead `$70C6`, compared by IsCatalogueLoaded and printed (the title) by MissionCatalogueScreen. The image holds leftover code bytes here; `$CFA5-$CFA8` are never read. | `IsCatalogueLoaded` | - |
| `$CF85` | `CatalogueTitle` (`CatalogueHead`+2) | 36 | - | `IsCatalogueLoaded` | - |

### Bank 6: briefing

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CA10` | `BriefingZones` | 19 | Zone table of the briefing. `$709E` (BriefingTextOnce), ShowBriefingMapOnce `$7084` (the map), ScreenZero (back). | - | - |
| `$CA86` | `StoresTitleBox` | 5 | The attribute box of the stores screen. Read by StoresScreen `$CB1C`. | - | - |

### Bank 6: results

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CC79` | `Score` | 4 | The 32-bit score of the missions completed. Added to by MissionCompleteScreen, set from a password by PasswordScreen, printed by PrintScore, coded by EncodePassword. | `EncodePassword` (`stage1/menu`), `PrintScore` (`stage1/menu`), `ScoreBits` (`stage1/menu`), `MissionCompleteScreen` (code) | `PasswordScreen` (`stage1/menu`), `MissionCompleteScreen` (code) |
| `$CC93` | `MissionsCompleted` | 1 | The number of missions completed. Counted by PasswordScreen and MissionCompleteScreen, printed through code 8 of StatusText. | `MissionCompleteScreen` (code) | `PasswordScreen` (`stage1/menu`), `MissionCompleteScreen` (code) |
| `$CC94` | `FailedTexts` | 23 of 138 | Texts: "MISSION FAILED." and the five reasons. `$CC94` printed by MissionFailedScreen; the reason (the pointer `$7BF9`, set by the play code) is one of the five. | - | - |
| `$CCAB` | `UnitDestroyedText` (`FailedTexts`+23) | 19 | - | - | - |
| `$CCBE` | `NoPickupText` (`FailedTexts`+42) | 26 | - | - | - |
| `$CCD8` | `DesertionText` (`FailedTexts`+68) | 21 | - | - | - |
| `$CCED` | `OutOfFuelText` (`FailedTexts`+89) | 20 | - | - | - |
| `$CD01` | `BridgeText` (`FailedTexts`+109) | 29 | - | - | - |
| `$CD70` | `EndZones` | 7 | Zone table of the two mission end screens. ScreenZero. | - | - |
| `$CDB5` | `StatusBoxes` | 5 of 10 | Two attribute box records of the mission status card. Read by MissionStatusScreen `$CDE6` and `$CDEC`. | - | - |
| `$CDBA` | `StatusBoxB` (`StatusBoxes`+5) | 5 | - | - | - |
| `$CE12` | `SpareZones` | 13 | A zone table no routine reads: ScreenZero and ScreenTwo. Known only from the code. | - | - |

### Bank 6: panel

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D3EA` | `StatusMessages` | 23 of 46 | Texts: "TANK HAS BEEN HIT", "COLLISION OCCURED". Read by StatusViewMessage. | - | - |
| `$D401` | `CollisionText` (`StatusMessages`+23) | 23 | - | - | - |
| `$D418` | `FinalScoreText` | 73 of 84 | Text: "MISSION COMPLETED:-", a blank line, "FINAL SCORE:-" and ten digits at `$D461`. Printed only by PrintFinalScore (unused). | - | - |
| `$D461` | `FinalScoreDigits` (`FinalScoreText`+73) | 11 | - | - | - |
| `$D46C` | `StatusText` | 46 of 57 | Text: "MISSIONS COMPLETED" (code 8: MissionsCompleted), "SCORE TO DATE" and nine digits at `$D49A`. Printed by PrintScore; the digits by LongToDigits and DotLeadingZeros. | `DotLeadingZeros` (`stage1/menu`) | `DotLeadingZeros` (`stage1/menu`), `LongDigitOf` (`stage1/menu`), `LongToDigits` (`stage1/menu`) |
| `$D49A` | `ScoreDigits` (`StatusText`+46) | 11 | - | `DotLeadingZeros` (`stage1/menu`) | `DotLeadingZeros` (`stage1/menu`), `LongDigitOf` (`stage1/menu`), `LongToDigits` (`stage1/menu`) |
| `$D501` | `DamageBoxes` | 28 | AttrBoxAt records of the damage board (height, column, attribute, row). Read by ShowDamageColours. | - | - |
| `$D51D` | `DamageColourTable` | 4 | The values of the four damage steps. Read by DamageColour. | `DamageColour` (`stage1/play`) | - |
| `$D6A3` | `BarShapesA` | 55 | Bar shapes of DrawBarB. Read by DrawBarB (`$D6A3-$D6D9`). | `DrawBearing` | - |
| `$D77F` | `BarShapesB` | 60 | Bar shapes of DrawSpeedBar. Read by DrawSpeedBar (`$D77F-$D7BA`). | `DrawHeadingStrip` | - |

### Bank 6: map

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DA5E` | `QuitText` | 46 | Text: "Are you sure you want to quit?" and "Yes/No.". Printed by QuitPrompt. | - | - |
| `$DAA1` | `StatusLegendText` | 32 | Text: the map's legend "Roads." and "Rivers." with their glyphs `$80` and `$81`. Printed by StatusMapLegend `$7241`. | - | - |
| `$DAC1` | `StatusLegendBoxes` | 5 of 10 | Attribute box records of the status legend. `$DAC1` read by StatusMapLegend, `$DAC6` by StatusMapFrame. | - | - |
| `$DAC6` | `StatusLegendBoxB` (`StatusLegendBoxes`+5) | 5 | - | - | - |
| `$DAE1` | `BriefingLegendText` | 32 | Text: "Roads." and "Rivers." for the briefing map. Printed by BriefingMapLegend `$722C`. | - | - |
| `$DB01` | `BriefingLegendBoxes` | 5 of 20 | Attribute box records of the briefing map and the status map. `$DB01` and `$DB0B` read by BriefingMapLegend, `$DB06` by BriefingMapFrame, `$DB10` by StatusMapLegend. | - | - |
| `$DB06` | `BriefingLegendBoxB` (`BriefingLegendBoxes`+5) | 5 | - | - | - |
| `$DB0B` | `BriefingLegendBoxC` (`BriefingLegendBoxes`+10) | 5 | - | - | - |
| `$DB10` | `StatusLegendBoxC` (`BriefingLegendBoxes`+15) | 5 | - | - | - |
| `$DBA8` | `MapDepth` | 2 | The depth word of every vertex DrawMapObjects and DrawMarkerModel make. Written by DrawStatusMap. | `DrawMarkerModel` (`stage1/menu`), `ProjectMapPoint` (`stage1/menu`) | `DrawStatusMap` (`stage1/menu`) |
| `$DBDF` | `Bank6FillA` | 20 | 20 fill bytes (`$E5`, one `$00`) of the tape block: never read | - | - |
| `$DBF3` | `MissionData` | 1 of 2048 | The mission's catalogue entry: the number of map objects, the marker positions, the coordinate tables, the object list. Written by CopyMissionText `$70F6` (2048 bytes, zero in the image). `$DBF3` the number of objects, MarkerPosA and MarkerPosB two marker positions (3-byte X and Y), MapCoordX and MapCoordY the coordinates by index, MapObjects 6-byte object records (two indices, the angle, the model kind). | `StoresScreen`, `DrawMapObjects` (`stage1/menu`), `ReadMapCoord` (`stage1/menu`) | `StoresScreen`, `SaveLoadedMission` (`stage1/missions`) |
| `$DBF4` | `MarkerPosA` (`MissionData`+1) | 6 | - | `ReadMapCoord` (`stage1/menu`) | - |
| `$DBFA` | `MarkerPosB` (`MissionData`+7) | 6 | - | `ReadMapCoord` (`stage1/menu`) | - |
| `$DC00` | `MapCoordX` (`MissionData`+13) | 64 | - | `DrawMapObjects` (`stage1/menu`) | - |
| `$DC40` | `MapCoordY` (`MissionData`+77) | 64 | - | `DrawMapObjects` (`stage1/menu`) | - |
| `$DC80` | `MapObjects` (`MissionData`+141) | 1907 | - | `StoresScreen`, `DrawMapObjects` (`stage1/menu`) | `StoresScreen`, `SaveLoadedMission` (`stage1/missions`) |
| `$E5B2` | `MarkerPointLists` | 6 | The point lists of the three markers. Read by DrawMarkerModel. | `DrawMarkerModel` (`stage1/menu`) | - |
| `$E5B8` | `MarkerScripts` | 6 | The scripts of the three markers; the third blinks (BlinkMarker). Read by DrawMarkerModel; `$E5BC` toggled by BlinkMarker. | `BlinkMarker` (`stage1/missions`), `DrawMarkerModel` (`stage1/menu`) | `BlinkMarker` (`stage1/missions`) |

### Bank 6: models

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E512` | `MapModels` | 12 of 79 | The scripts of the map objects. Run by DrawMapObjects. `$E54F` is read by nothing. | - | - |
| `$E51E` | `MapModelNegative` (`MapModels`+12) | 12 | - | - | - |
| `$E52A` | `MapModelOther` (`MapModels`+24) | 10 | - | - | - |
| `$E534` | `MapModelKind6` (`MapModels`+34) | 27 | - | - | - |
| `$E54F` | `MapModelSpare` (`MapModels`+61) | 18 | - | - | - |
| `$E5D5` | `MarkerModels` | 10 of 46 | The scripts of the markers. Run by DrawMarkerModel. | - | - |
| `$E5DF` | `MarkerModelB` (`MarkerModels`+10) | 14 | - | - | - |
| `$E5ED` | `MarkerModelC` (`MarkerModels`+24) | 10 | - | - | - |
| `$E5F7` | `MarkerModelD` (`MarkerModels`+34) | 12 | - | - | - |
| `$E603` | `MarkerPoints` | 9 of 33 | The markers' points: a count, then X, Y byte pairs. Read by DrawMarkerModel. | `DrawMarkerModel` (`stage1/menu`) | - |
| `$E60C` | `MarkerPointsB` (`MarkerPoints`+9) | 15 | - | `DrawMarkerModel` (`stage1/menu`) | - |
| `$E61B` | `MarkerPointsC` (`MarkerPoints`+24) | 9 | - | `DrawMarkerModel` (`stage1/menu`) | - |

### Bank 6: graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E624` | `StatusGraphicA` | 320 | 10 x 32 graphic of the mission status card. CopyGraphic source of MissionStatusScreen `$CDD7`. | - | - |
| `$E764` | `CatalogueGraphicA` | 288 | 9 x 32 graphic of the catalogue's titles. DrawCatalogueTitles `$C765`. | - | - |
| `$E884` | `StoresGraphicA` | 96 | 4 x 24 graphic of the stores. StoresScreen `$CAEF`. | - | - |
| `$E8E4` | `StoresGraphicB` | 96 | 4 x 24 graphic of the stores. StoresScreen `$CAFE`. | - | - |
| `$E944` | `TitleGraphicB` | 176 | 11 x 16 graphic of the title menu. TitleMenu `$C446`. | - | - |
| `$E9F4` | `TitleGraphicA` | 176 | 11 x 16 graphic of the title menu. TitleMenu `$C437`. | - | - |
| `$EAA4` | `SpareGraphic` | 176 | 176 bytes no routine reads (an 11 x 16 graphic by its size). Known only from the code. | - | - |
| `$EB54` | `CatalogueGraphicB` | 176 | 11 x 16 graphic of the catalogue. MissionCatalogueScreen `$C7B1`. | - | - |
| `$EC04` | `StatusGraphicB` | 176 | 11 x 16 graphic of the mission status card. MissionStatusScreen `$CDC8`. | - | - |
| `$ECB4` | `StoresGraphicC` | 192 | 12 x 16 graphic of the stores. StoresScreen `$CB0D`. | - | - |
| `$ED74` | `BriefingGraphicC` | 112 | 7 x 16 graphic of the briefing. BriefingScreen `$C9D5`. | - | - |
| `$EDE4` | `BriefingGraphicB` | 112 | 7 x 16 graphic of the briefing. BriefingScreen `$C9C6`. | - | - |
| `$EE54` | `BriefingGraphicA` | 112 | 7 x 16 graphic of the briefing. BriefingScreen `$C9B7`. | - | - |
| `$EEC4` | `SpareGraphicB` | 112 | 112 bytes no routine reads (a fourth 7 x 16 graphic by its size). Known only from the code. | - | - |
| `$EF34` | `PanelIcons` | 72 of 1368 | The 3 x 24 icons: 18 of IconTable's 19 and one unused, 72 bytes each. IconTable `$75CA` entry t - 1 is the icon of type t; the weapon types 1-13 are the stores' too (WeaponRecords +5). Entry 19 lies apart, Icon19 `$F59C`. | `DrawSlotIcon` | - |
| `$EF7C` | `IconSpare` (`PanelIcons`+72) | 72 | - | - | - |
| `$EFC4` | `Icon17` (`PanelIcons`+144) | 72 | - | - | - |
| `$F00C` | `Icon18` (`PanelIcons`+216) | 72 | - | - | - |
| `$F054` | `Icon14` (`PanelIcons`+288) | 72 | - | - | - |
| `$F09C` | `IconK40Mortar` (`PanelIcons`+360) | 72 | - | `DrawSlotIcon` (`stage1/play`) | - |
| `$F0E4` | `Icon15` (`PanelIcons`+432) | 72 | - | - | - |
| `$F12C` | `IconSlamLaser` (`PanelIcons`+504) | 72 | - | `DrawSlotIcon` (`stage1/play2`) | - |
| `$F174` | `IconBansheeIRSS` (`PanelIcons`+576) | 72 | - | `DrawSlotIcon` (`stage1/play2`) | - |
| `$F1BC` | `IconBansheeRRSS` (`PanelIcons`+648) | 72 | - | `DrawSlotIcon` (`stage1/play`) | - |
| `$F204` | `IconPhoenixIRSA` (`PanelIcons`+720) | 72 | - | `DrawSlotIcon` (`stage1/play2`) | - |
| `$F24C` | `IconPhoenixRRSA` (`PanelIcons`+792) | 72 | - | `DrawSlotIcon` (`stage1/play2`) | - |
| `$F294` | `IconSleeperMine` (`PanelIcons`+864) | 72 | - | `DrawSlotIcon` (`stage1/play2`) | - |
| `$F2DC` | `IconDragonfly` (`PanelIcons`+936) | 72 | - | `DrawSlotIcon` (`stage1/play`) | - |
| `$F324` | `IconSpectre` (`PanelIcons`+1008) | 72 | - | `DrawSlotIcon` (`stage1/play2`) | - |
| `$F36C` | `IconK90Cluster` (`PanelIcons`+1080) | 72 | - | `DrawSlotIcon` (`stage1/play2`) | - |
| `$F3B4` | `IconPhantasm` (`PanelIcons`+1152) | 72 | - | `DrawSlotIcon` (`stage1/play`) | - |
| `$F3FC` | `IconSkeetBomb` (`PanelIcons`+1224) | 72 | - | `DrawSlotIcon` (`stage1/play2`) | - |
| `$F444` | `IconTurret` (`PanelIcons`+1296) | 72 | - | `DrawSlotIcon` | - |
| `$F48C` | `TitleGraphicC` | 128 | 8 x 16 graphic of the title menu. TitleMenu `$C455`. | - | - |
| `$F50C` | `CatalogueGraphicC` | 144 | 9 x 16 graphic of the catalogue's titles. DrawCatalogueTitles `$C774`. | - | - |
| `$F59C` | `Icon19` | 72 | The 3 x 24 icon of IconTable entry 19. Read by DrawIcon through IconTable. | - | - |

### Bank 6: font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F5E4` | `Font8x8` | 784 | The 8x8 font: characters `$20-$81`. Read by PrintString's PrintChar (`$6EE1`) and by PrintRawString (`$C707`, `$C716`). | `PrintRawString` (`stage1/menu`) | - |

### Bank 6: options

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F935` | `OptionLines` | 10 | The attribute bytes of the five device lines inside OptionsText. Read by OptionsScreen. | `OptionsScreen` | - |
| `$F93F` | `OptionsText` | 132 | Text: "SELECT CONTROL SYSTEM." and the five devices. 1 Sinclair Joystick, 2 Cursor Keys, 3 Kempston Mouse, 4 Kempston Joystick, 5 Keyboard. Printed by OptionsScreen; the attribute after code 13 of each line is written by it. | - | `OptionsScreen` |
| `$F9C3` | `Bank6FillB` | 61 | 61 fill bytes (`$E5`, one `$00`) of the tape block: never read | `CopyMissionTextOld` (code) | - |


## Bank 7 (`src/bank7/bank7.json`)

Battle Command, Ocean 1990: RAM bank 7, paged at `$C000`, as its tape block loads it. Its entries are
`src/bank7/<module>.asm`, written from `src/bank7/bank7.ann` by `kit/mkgame.py --part src/bank7/bank7.json`; the
readers and writers from `work/stage1/c1g`, `work/stage1/menu`, `work/stage1/missions`, `work/stage1/play`,
`work/stage1/play2`, `work/stage1/death`, `work/stage1/m2ocean`, `work/stage1/m2erbe`, `work/stage1/search`,
`work/stage1/m10`.

### Bank 7: pictures

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C000` | `PicDamageBoard` | 1811 | Packed screen: the damage board with the tank drawings and twelve boxes (the key D, DamageLoop). Unpacked by DamageLoop (`$6C9E`, `LD DE,$C000`). Block of 1811 bytes: size word `$070F`, 1327 tokens. Witness: play (1808 bytes read), c1. | `GetBits` (`stage1/play`), `StartBits` (`stage1/play`), `UnpackPicture` (`stage1/play`) | - |
| `$C713` | `PicStores` | 1462 | Packed screen: the stores and weapons modules folder with the payload status. Unpacked by bank 6 `$CAAC` (the stores screen of the mission menu). Block of 1462 bytes, 1052 tokens. Witness: death, m2erbe, missions, play, play2 (1459 bytes read). | `GetBits`, `StartBits`, `UnpackPicture` | - |
| `$CCC9` | `PicMissionSelect` | 1628 | Packed screen: the clipboard with the mission list, the tank photo and the red folder. Unpacked by bank 6 `$C7AB` (the mission catalogue screen). Block of 1628 bytes, 1180 tokens. Witness: every read build (1625 bytes read). | `GetBits`, `StartBits`, `UnpackPicture` | - |
| `$D325` | `PicGridPanel` | 1067 | Packed screen: the panel with TIME, GRID Y and GRID X and the blank screen (the status view). Unpacked by StatusLoop (`$6BD0`, `LD DE,$D325`). Block of 1067 bytes, 701 tokens. Witness: m2erbe, missions, play (1064 bytes read). | `GetBits` (`stage1/missions`), `StartBits` (`stage1/missions`), `UnpackPicture` (`stage1/missions`) | - |
| `$D750` | `Bank7Free` | 1573 | 1573 zero bytes between the fourth and fifth pictures: never read. No recording reads `$D750-$DD74` (byte_counts of page 7); the tape block carries them as zeros. | - | - |
| `$DD75` | `PicCockpit` | 1961 | Packed screen: the tank's cockpit, the 3D view's frame and the dashboard. Unpacked by StartMission (`$696D`, `LD DE,$DD75`) at the start of every mission and on the way back to the 3D view. Block of 1961 bytes, 1533 tokens. Witness: death, m2erbe, missions, play, play2 (1958 bytes read). | `GetBits`, `StartBits`, `UnpackPicture` | - |
| `$E51E` | `PicCompletion` | 1067 | Packed screen: the completion report folder, CLASSIFIED. Unpacked by bank 6 `$CD21` and `$CD87` (the end of a mission). Block of 1067 bytes, 712 tokens. Witness: the fuel recording (MissionFailedScreen, frame 7862), m1complete (MissionCompleteScreen, frame 21560) and m4complete (21301); c1 completes no mission and does not run either screen (corrected by docs, see doc 03 3.8). | - | - |
| `$E949` | `PicBriefing` | 825 | Packed screen: the briefing notes folder with the red star. Unpacked by bank 6 `$C9A5` (the briefing). Block of 825 bytes, 553 tokens. Witness: menu (822 bytes read), c1. | `GetBits` (`stage1/menu`), `StartBits` (`stage1/menu`), `UnpackPicture` (`stage1/menu`) | - |
| `$EC82` | `PicMissionStatus` | 2143 | Packed screen: the mission status card with the commander's photo over the tank drawings. Unpacked by bank 6 `$CDC2`. Block of 2143 bytes, 1577 tokens. Witness: m10, menu, missions (2140 bytes read). | `GetBits` (`stage1/menu`), `StartBits` (`stage1/menu`), `UnpackPicture` (`stage1/menu`) | - |
| `$F4E1` | `PicTitle` | 1260 | Packed screen: the BATTLE COMMAND title lettering over black. Unpacked by the title menu, bank 6 `$C431`. Block of 1260 bytes, 1066 tokens. Witness: m2erbe, menu, missions, play, play2 (1257 bytes read). | `GetBits`, `StartBits`, `UnpackPicture` | - |
| `$F9CD` | `PicMapFrame` | 1218 | Packed screen: the monitor frame with its grey screen around the Dragonfly's flight view. Unpacked by DragonflyViewLoop (`$6AC3`, `LD DE,$F9CD`). Block of 1218 bytes, 885 tokens. Witness: play (1215 bytes read). | `GetBits` (`stage1/play`), `StartBits` (`stage1/play`), `UnpackPicture` (`stage1/play`) | - |

### Bank 7: unpack

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FE8F` | `UnpackVars` | 2 of 6 | UnpackPicture's pointers: `$FE8F` and `$FE93` the common-byte table, `$FE91` the bit stream. Written by UnpackPicture `$FEA7`-`$FEB6`; `$FE93` is read for every common byte (`$FEF0`, `$FF70`), `$FE91` by StartBits; `$FE8F` is written and never read (known only from the code). Zero in the image. | `StartBits`, `UnpackPicture` | `UnpackPicture` |
| `$FE91` | `StreamPtr` (`UnpackVars`+2) | 2 | - | `StartBits` | `UnpackPicture` |
| `$FE93` | `TablePtr` (`UnpackVars`+4) | 2 | - | `UnpackPicture` | `UnpackPicture` |
| `$FFF7` | `BitMasks` | 9 | The masks of 0-7 low bits: `$00`, `$01`, `$03` ... `$7F`. Read by StartBits. | `StartBits` | - |


## Tape BASIC (`src/tape/basic.json`)

Battle Command, Ocean 1990: tape block 2, the BASIC program "BATTLE" (4917 bytes at PROG `$5CCB`, LINE 0). Its
entries are `src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part
src/tape/basic.json`; the readers and writers from `work/stage1/c1l`.

### Tape BASIC: basic

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine0` | 59 | Line 0: RANDOMIZE USR ((PEEK 23635+256*PEEK 23636)+10), the 10 standing for 59. USR (PROG+59): PEEK 23635 + 256*PEEK 23636 is PROG, the system variable at `$5C53`. The number's digits say 10, its hidden five-byte form says 59 (`$3B`), the offset of Stage1. Known from the bytes and c1 (Stage1 entered at frame 2028). | - | - |
| `$5D2A` | `ChainTape` | 4821 | The decryption chain as the tape holds it (4821 bytes, copied to `$AC38`). tools/speedlock.py master writes these bytes from the plain view src/loader/chain.asm: every layer's rewrite undone, in reverse order. The build INCBINs build/chain-tape.bin. | `Stage1` | - |
| `$6FFF` | `BasicEnd` | 1 | The program's last byte, `$55`, past the copy: no code reads it. Stage1 copies 4821 bytes and the program is 4917: this byte after them is never copied or read (c1: no L1 read). Kept as it is. | - | - |


## Decryption chain and loader (`src/loader/chain.json`)

Battle Command, Ocean 1990: the BASIC's enciphered tail in its plain view, `$AC38-$BF0C`. The 103 layers of the
decryption chain as each one runs, then the SpeedLock 7 loader as the last layer leaves it. tools/speedlock.py
masters these bytes back into the tape's (src/tape/basic.asm INCBINs the result). Its entries are
`src/loader/<module>.asm`, written from `src/loader/chain.ann` by `kit/mkgame.py --part src/loader/chain.json`; the
readers and writers from `work/stage1/c1l`.

### Decryption chain and loader: loader

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B9FB` | `NoticeText` | 505 | The copyright notice and the FAST warning, zero-ended strings. Read by PrintString (c1: L1 reads). Shown during the whole load. | `Layer000`, `LoaderMain`, `PrintString` | `Layer000`, `LoadBlocks`, `LoaderMain` |
| `$BC5A` | `data_BC5A` | 4 | data_BC5A | `Layer000` | `Layer000`, `LoadBlocks` |
| `$BCEE` | `data_BCEE` | 4 | data_BCEE | `Layer000`, `l_BCBD` (code) | `Layer000`, `LoadBlocks` |
| `$BED0` | `TimeFailed` | 1 of 15 | Non-zero when the timing check failed (the mark check at `$BE0D` stores `$7F` when a mark's second group is not `$7F`; TimeCheck's `$BECC` stores 1) | `Layer000`, `LoadBlocks`, `LoaderMain` | `Layer000`, `LoadBlocks`, `l_BE00` (code), `l_BECC` (code) |
| `$BED1` | `EdgeLimits` (`TimeFailed`+1) | 14 | seven pairs read by LoadBlocks `$BD4C`: the edge counter's start value and the count it must pass | `Layer000`, `LoadBlocks` | `Layer000`, `LoadBlocks` |


## Loader stage 2 (`src/loader/stage2.json`)

Battle Command, Ocean 1990: the SpeedLock loader's second stage, tape block 7, run at `$BF0D`. Its entries are
`src/loader/<module>.asm`, written from `src/loader/stage2.ann` by `kit/mkgame.py --part src/loader/stage2.json`;
the readers and writers from `work/stage1/c1l`.

### Loader stage 2: stage2

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BF30` | `BlockTable` | 40 of 80 | The first block table: five bytes a row, the address, the length less one, the `$7FFD` value. Rows: `$8000` 768 bytes (the attributes), `$BD9C` 2 (the body key), `$BDD0` 4 (the last-byte key), `$BF30` 75 (the table again, src/tape/side1.txt has the new rows), `$6000` 8192 and `$4000` 6912 with pages `$13` / `$12` and `$FB00` 512, never read (the new table replaces them first), and the end row of zeros. Read by the table walk in LoadBlocks (c1). | - | - |
| `$BF58` | `BlockTablePad` (`BlockTable`+40) | 40 | zeros up to the font | - | - |
| `$BF80` | `CountdownFont` | 80 | The countdown's digits 0-9, 8 bytes each. Read by WaitTask's countdown (c1: the digits at the top right of the screen during the load). | - | - |


## Loader block 37 (`src/loader/final-be5d.json`)

Battle Command, Ocean 1990: the SpeedLock loader's last piece at `$BE5D`, the timing check, tape block 37. Its
entries are `src/loader/<module>.asm`, written from `src/loader/final.ann` by `kit/mkgame.py --part
src/loader/final-be5d.json`; the readers and writers from `work/stage1/c1l`.

### Loader block 37: final

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BE70` | `FinalLeftover` | 96 | Bytes no code runs: a test of TimeFailed, a wipe and a copy of the bootstrap. Never executed in c1. They look like an earlier version of TimeEnd and of the bootstrap at `$8000` (the same LDIR of `$3CFF` bytes from bank 1 and JP `$68F4`); kept as bytes of the block. | - | - |


## Loader block 39 (`src/loader/final-bf21.json`)

Battle Command, Ocean 1990: the SpeedLock loader's last piece at `$BF21`, the stage's new end, tape block 39. Its
entries are `src/loader/<module>.asm`, written from `src/loader/final.ann` by `kit/mkgame.py --part
src/loader/final-bf21.json`; the readers and writers from `work/stage1/c1l`.
