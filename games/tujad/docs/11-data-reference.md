# 11. Data reference

Every data entry of the game image `$60C0`-`$FDFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, `work/stage1/rec/energy-out`, local and not in the repository).
Written by `kit/refdocs.py`.

## cells

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$60C0` | `CellTable` | 576 | The cell table, rows 6-23 of the screen: 0 empty, 1 a wall, `$80`+ an item, `$FF` `$FF` a teleporter, bits 1-6 the movers' marks. Values: 0 empty; 1 a wall (DrawRoom `$6D8C`, where the room's attribute is not 0); an item's code on its 2 x 2 cells (DrawItem `$6E0D`: `$80` GEN 19, `$81` an energy source, `$C1-$C3` weapons 1-3, `$82-$B3` the ED pieces); `$FF` `$FF` on the two top cells of a teleporter (DrawRoom `$6DE3`). Marks a mover XORs in and out: bit 1 an enemy (MoveEnemy `$90E7` through XorCells `$7D87` with 2), bit 2 an object (4), bit 3 a patroller (8); the shots OR bits 4-6 (OrCells `$7DAE`: `$11`, `$21` and `$41` for weapons 3, 2 and 1), which the objects test against their kind (ObjectKind `$7C28`). Readers: CellAddr `$7CAA` (the droid's cell, the step tests), CellAddrXY `$7C94`, the touch test of MoveDroid (`$75C8`), MoveEnemy's spawn (`$911B`). The bytes in the image are the last room of the authors' session (no build reads them before DrawRoom writes the table: c1 frame 13580 calls DrawRoom first). | `CellBlockedColumn`, `CellBlockedRow`, `DroidExhaust`, `Fire`, `MoveDroid` +4 | `DrawItem`, `DrawRoom`, `MoveDroid`, `XorCells` |

## start

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6303` | `Enemies` | 36 | The four enemy records of 9 bytes. Record k (k = 0-3) at `$6303` + 9k: +0 the timer (passes to the next step), +1 the state (bits 0-1 the direction 0 right, 1 down, 2 left, 3 up; bit 6 materialising; bit 7 hit, the explosion; `$40` with +0 = 1 or 2 a spawn waiting), +2 x in pixels (up to `$F0`; a spawn writes Random OR `$20` AND `$F8`, `$20-$D0`), +3 y in pixels (up to `$B0`), +4/+5 the graphic pointer, +6 the frame, +7 the frames, +8 the attribute. DrawRoom `$6B40` zeroes byte 0 of each and, by the bits of the room's enemy mask, sets +0 to 1 or 2, +1 to `$40` and the graphic to BlankGraphic `$6609`. MainLoop calls MoveEnemy `$90E7` with each record (L1 18 579 passes). | `CellBlockedColumn`, `CellBlockedRow`, `Interrupt`, `MoveEnemy`, `StepDown` +3 | `DrawRoom`, `Interrupt`, `MoveEnemy`, `StepDown`, `StepLeft` +2 |
| `$6327` | `Objects` | 20 | The room's two object records of 10 bytes. Object 1 at `$6327`, object 2 at `$6331`: +0 the kind (bits 4-7, ObjectKind) and a 2-pass move timer (bits 0-1; 0: no object), +1 the state (bits 0-1 the direction, bit 4 dead (MoveObject returns at once), bit 5 stopped by another weapon (cleared again when its own weapon kills it: MoveObjectDying RES 5), bit 6 just entered, bit 7 dying), +2 x (pixels), +3 y, +4/+5 the graphic, +6 the frame, +7 the frames, +8 the weapon mark it dies to, +9 the attribute. DrawRoom copies the room's records from the alien map into these (LDIR at `$6C2B`), SaveRoomObjects `$6ADC` writes them back when the droid leaves the room, so an object keeps its place and its life. MainLoop calls MoveObject `$809D` for each (L1 18 579). | `CellBlockedColumn`, `CellBlockedRow`, `MoveObject`, `SaveRoomObjects`, `StepDown` +3 | `DrawRoom`, `MoveObject`, `SaveRoomObjects`, `StepDown`, `StepLeft` +2 |
| `$633B` | `Patrollers` | 30 | The three patroller records of 8 bytes, and their pointers. A patroller moves along a fixed row through several rooms: +0 bit 7 not drawn (DrawRoom sets it on every room change), the frame; +1 y and the direction; +2 the column; +3 the room it is in; +4/+5 the room and column where it turns right; +6/+7 where it turns left. MovePatrollers `$6AAD` takes one a pass through PatrollerPtrs. The bytes in the image are the start state (no NewGame resets them). | `DrawRoom`, `MovePatroller`, `MovePatrollers`, `PatrollerStep` | `DrawRoom`, `MovePatroller`, `PatrollerStep` |
| `$6359` | `DroidVars` | 39 | The droid, the shot, the room and the energy counters. x (column 0-`$1D`), y (pixel row `$30-$98` in steps of 2), the flags (bit 0 facing left, bit 1 turning, bit 2 in the air (no wall under the feet), bit 3 moving, bit 4 the shield (down held alone: FlagPointer `$0000`, EnergyReload 10, HazardFlash), bit 6 the step frame, bit 7 the sprite list's collision bit), the frame 0-13, the width in bytes. The image's bytes from `$6359` are Leftover text (the authors' source): PlaceDroid `$7A6D` and NewGame `$7A2F` write every byte before play. | `CellBlockedColumn`, `DeathEffect`, `DrainTimer`, `DrawHud`, `DrawRoom` +24 | `DeathEffect`, `DrainTimer`, `DrawRoom`, `EdPickup`, `EnemyKind` +16 |
| `$6380` | `InitialVars` | 28 | The start values of `$6364-$637F`, copied by NewGame. NewGame `$7A59` copies these 28 bytes to ControlsLatch (L1 4 new games, LDIR 112 runs). Energy timer `$FA`, weapon 0, ammunition 3 3 3, lives 3, energy 99, move delay 1, the drain reload `$FA`, DroidGraphic BlankGraphic, TurnGraphic DroidFrames' first (`$9C40`), TurnStep TurnSequence, FlagPointer DroidFlags. | `NewGame` | - |
| `$639C` | `RoomVars` | 54 | The room's items, teleporter and the scratch words. From the room's alien record (DrawRoom `$6B6C`): the two items' positions and kinds, the teleporter's position and target room; then the random number, the patroller pointer, the item cell found and scratch words of the movers and the shots. The image's bytes are Leftover text (the authors' source). | `DrawRoom`, `DroidExhaust`, `ExhaustRow`, `ExhaustRowLeft`, `Interrupt` +18 | `CellBlockedColumn`, `DrawRoom`, `DroidExhaust`, `EnemyKind`, `ExhaustRow` +25 |

## messages

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$63D2` | `Messages` | 476 | The ten messages: a priority byte, the text, '.'. Readers: QueueMessage `$6ACD` (the priority), the interrupt's scroller `$96A0` (the text: L1 reads `$63D2-$65AD`). Queued by: Restart `$690A` (TUJAD FROM ORPHEUS), WinTest `$69F3` (EDS COMPLETED), EnergyTick `$7AC9` (WARNING ENERGY LOW), the pickups `$7687` / `$766A` / `$7671` (ENERGY SOURCE ABSORBED, WEAPON LOCATED AND STORED, GEN 19 COLLECTED), Teleport `$778B` (TRANSPORTING), LoseLife `$6A51` (GEN 19 DESTROYED), the win `$6A10` (CONGRATULATIONS) and the game over `$6A94` (COMPUTER MALFUNCTION). | `Interrupt`, `QueueMessage` | - |

## buffers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$65AE` | `ExhaustPtrs` | 8 | The four exhaust rows' pattern records. ExhaustStep `$8E7E` steps the four rows through ExhaustRow / ExhaustRowLeft with these (L1 18 571 passes). The image's values point at the first four ExhaustPatterns. | `ExhaustStep` | `ExhaustStep` |
| `$65B6` | `ExhaustPatterns` | 32 | Eight exhaust pattern records: a life counter, three bytes of pixels. ExhaustRow `$8EC7` rotates a record's three bytes one pixel a pass; when its counter runs out ExhaustPick `$8EAC` takes a random record whose counter is 0 and gives it 8-39 passes (Random `$7DC9`: L1 5 012 tries, 3 134 picks). | `ExhaustPick`, `ExhaustRow`, `ExhaustRowLeft` | `ExhaustPick`, `ExhaustRow`, `ExhaustRowLeft` |
| `$65D6` | `ExhaustMasks` | 4 | The masks of the exhaust rows: `$FF` `$00` (frames 11 and the walk), `$0F` `$F0` (frame 12). ExhaustMask `$8F1B` ANDs the three bytes of each row with (mask 1, `$FF`, mask 2): `$65D6` for frame 11 and the walk, `$65D8` for frame 12 (the droid seen from the front). | `ExhaustMask` | - |
| `$65DA` | `WeaponColours` | 3 | The attributes of the weapon items 1-3 (DrawItem `$6E65`). `$43`, `$44`, `$46`: the same attributes ShowWeapon `$79D5` gives the HUD icons of weapons 1-3. DrawItem reads WeaponColours - 1 + the weapon number (L1 25 reads). | - | - |
| `$65DD` | `ShotGraphic0` | 8 | Weapon 0's shot: one byte, 8 rows (a short dash on the top row). FireBasic `$8767` puts it in the shot (L1 734 shots); the interrupt XORs it as a 1 x 1 sprite. | - | - |
| `$65E5` | `ExhaustRows` | 36 | The exhaust's 8 rows of 3 bytes as drawn, then the four pattern rows (`$65FD`). ExhaustMask `$8F1B` writes the masked rows here; DroidExhaust `$8DD2` XORs them under the droid twice a pass. Leftover text in the image. | `DroidExhaust`, `ExhaustMask`, `ExhaustRow`, `ExhaustRowLeft`, `NewGame` | `ExhaustMask`, `ExhaustRow`, `ExhaustRowLeft`, `NewGame` |
| `$6609` | `BlankGraphic` | 120 | 120 zero bytes: the frame of an empty or materialising sprite. NewGame zeroes it; DrawRoom gives it to the waiting enemies (`$6BB0`), the droid starts with it (InitialVars), ShowWeapon `$7A17` prints it to blank the ammunition. | `MoveDroid`, `MoveEnemy`, `NewGame`, `ShiftGraphic3` | `NewGame` |
| `$6681` | `EdFlags` | 11 | The ED pieces taken: ten bytes, bits 0-4 of each, 50 pieces. EdPickup `$7703` sets the bit of a piece; WinTest `$69E3` waits for all ten bytes to be `$1F`; ProgressScreen `$8F53` shows them. NewGame zeroes them. | `NewGame`, `ProgressScreen`, `WinTest` | `NewGame`, `ProgressScreen` |
| `$668C` | `DroidSave` | 120 | The droid's frame as last drawn: 120 bytes. MoveDroid `$72AD` copies the frame graphic here each pass, so the interrupt can XOR the old image out with the same bytes it drew (L1 15 289). | `Interrupt` | `MoveDroid` |
| `$6704` | `EnemyBufferPtrs` | 4 | The enemy buffers in use: the draw buffer, the erase buffer. MainLoop sets both before each MoveEnemy call (`$6938-$6977`). The image's four bytes are Leftover text ("l", 6, "lookup"), not addresses. | `MoveEnemy` | `MainLoop`, `Setup` |
| `$6708` | `EnemyBuffers` | 384 | Four pairs of 48-byte buffers: an enemy's graphic shifted to its pixel x, as drawn and as to erase. Enemy k uses `$6708` + 96k and `$6738` + 96k (MainLoop). MoveEnemy shifts the enemy's graphic into one (ShiftGraphic3 `$7EBB`) and hands both to the sprite list. | `Interrupt` | `MoveEnemy` |

## droidtables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6888` | `DroidFrames` | 28 | The droid's 14 frame graphics. MoveDroid `$752D`: DroidGraphic = DroidFrames[DroidFrame], DroidWidth = DroidWidths[DroidFrame] (L1 15 293). The graphics are DroidGraphics `$9C40-$A257`. | `MoveDroid` | - |
| `$68A4` | `DroidWidths` | 14 | The width in bytes of each frame | `MoveDroid` | - |
| `$68B2` | `TurnSequence` | 6 | The frames of the turn-round: 8, 9, 10, 9, 8, then `$FF`. TurnRound `$7866` plays it (L1 538 steps). | `TurnRound` | - |
| `$68B8` | `EnemyFrameCounts` | 9 | The frames of each of the nine enemy kinds. EnemyKind `$90C8` reads EnemyFrameCounts - 1 + the kind (1-9): 4, 3, then 4 for kinds 3-9. | `EnemyKind` | - |
| `$68C1` | `EnemyGraphics` | 18 | The graphics of the nine enemy kinds (`$A74E-$AEC4`). EnemyKind returns HL = EnemyGraphics - 2 + 2 x kind. Each frame is 49 bytes: the shift byte, then 16 rows of 3 bytes (ShiftGraphic3). | `MoveEnemy` | - |
| `$68D3` | `ExplosionFrames` | 8 | The four frames of an enemy's explosion | `MoveEnemy` | - |
| `$68DB` | `MaterialiseFrames` | 8 | The four frames of an enemy's materialising | `MoveEnemy` | - |
| `$68E3` | `ObjectDeathFrames` | 8 | The four frames of an object's death. The first word (ObjectDeath `$B6BA`) is never read: the dying states (state AND `$0C` = `$04`, `$08`, `$0C`) select offsets 2, 4, 6; `$00` ends the death first (MoveObjectDying `$8236`). | - | - |
| `$68EB` | `Weapon3Frames` | 8 | The four frames of weapon 3's shot | - | - |

## rooms

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6EA8` | `TileGraphics` | 697 | The graphics of tiles 1-70 (and a 71st no room uses). DrawRoom reads TileGraphics - 2 + 2 x tile (`$6CC9`). Tile 49 is 0 (no room uses it); the 71st word (`$6F34`, `$FDDC`) is never read. A graphic is a width in bytes, a height in pixel rows, then the rows (TileData `$E822-$FDDF`). The editable form: src/res/tiles/. | `DrawRoom` | - |

## weapons

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8814` | `ShotGraphics` | 64 | The bolt graphics of weapons 1 and 2: 2 x 8, two frames each. Fire `$86CA` / `$870B` start the shot at `$8824` (weapon 1) or `$8844` (weapon 2); MoveShotStraight steps the graphic 16 bytes up or down a pass by its direction, so `$8814` and `$8834` are the frames the shot alternates with. | `Interrupt` | - |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8BF5` | `HudAttrs` | 8 | The attributes of the HUD's rows 1-4 from column 2: two cells `$47`, a gap, two `$45`, a gap, two `$42`. DrawHud `$8B79` copies them four times (L1 reads). | `DrawHud` | - |
| `$8BFD` | `HudGraphics` | 88 | The HUD frame's characters: the top and bottom edges, the left and right edges, four corners, the divider. DrawHud draws each with Print8. The editable form: src/res/graphics/HudGraphics.png. | `Print8` | - |
| `$8C55` | `HudIcons` | 224 | Seven 16 x 16 icons: weapons 0-3, GEN 19, the energy (HUD), the energy source. ShowWeapon `$79CB-$79EF` and DrawItem `$6E58` read the weapon icons (`$8C55` + 32 x weapon); DrawItem `$6E4A` GEN 19 (`$8CD5`) and `$6E51` the energy source (`$8D15`); DrawHud the GEN 19 and energy icons (`$8CF5`). The editable form: src/res/sprites/HudIcons.png. | `Blit16` | - |
| `$8D35` | `MenuLogoAt` | 2 | The screen address MenuLogo draws at | `MenuLogo` | `Menu` |
| `$8D37` | `PrintAttr` | 1 | PrintText's colour | `PrintText` | `PrintText` |
| `$8D38` | `MenuTexts` | 94 | The menu's texts, each ending in '.', and a copyright line never printed. Menu `$88F6-$8922` prints the five texts. `$8D85` (a `$7F`, the copyright sign in the ROM font, then " 1986 ORPHEUS LTD") is read by no build: a leftover. The editable form: src/res/text/MenuTexts.txt. | `PrintText` | - |
| `$8D96` | `MenuLogoAttrs` | 28 | The logo's colours: 7 rows of 4 | `MenuLogo` | - |
| `$8DB2` | `MenuLogoGraphic` | 32 | The logo's block: 16 rows of 2 bytes (a diamond); the lower half is used alone. MenuLogo `$89E9` draws it three times as 16 rows and twice from `$8DC2` as 8. | `Blit2` | - |

## progress

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9072` | `ProgressText` | 33 | YOU HAVE COMPLETED   % OF TUJAD. (the digits at +19 and +20) | `ProgressScreen` | `ProgressScreen` |

## patrollers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9484` | `StartPositions` | 256 | Where the droid starts in each of the 128 rooms: (x, y). PlaceDroid `$7A7B` reads StartPositions + 2 x Room after a life lost and at a new game (room `$54`). The editable form is part of src/res/rooms/ (the start of each room). | `PlaceDroid` | - |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$95C1` | `ExitToBasic` | 15 | Never run: LD A,`$3F`; LD I,A; IM 1; EI; CALL `$0D6B` (CLS); LD A,7; OUT (`$FE`),A; RET. The way back to BASIC that no code reaches (L1: no run, no read): the I register and IM 1 restored, the screen cleared, the border white. A leftover of development. | - | - |

## bitreverse

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$96FE` | `ZeroFill1` | 846 | 846 zero bytes no code reads or writes. L1, c1-c4 and the win recording: no read, no write in `$96FE-$9A4B`. A space the authors left between the code and the tables. | - | - |
| `$9A4C` | `BitReverse` | 256 | Each byte with its bits reversed: BitReverse[n] = n with bit 0 as bit 7 ... bit 7 as bit 0. TurnMirror2 / TurnMirror3 (`$7866`) look up each graphic byte here (L = byte, H = `$9A`). Checked: all 256 entries are the exact bit reversal of their index. L1: 137 of the 256 entries read, 180 464 reads. | `TurnRound` | - |
| `$9B4C` | `ZeroFill2` | 244 | 244 zero bytes no code reads or writes. L1: no read, no write in `$9B4C-$9C3F`. | - | - |

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9C40` | `DroidGraphics` | 1560 | The droid's 14 frames, 40 rows each: frames 0-9 and 11-13 3 bytes wide, frame 10 2 bytes wide. DroidFrames `$6888` points at each frame, DroidWidths `$68A4` gives its width: 0-7 the walk (3 bytes, 120 each), 8 and 9 the turn-round (2 bytes), 10 the front, also the teleport beam (2 bytes, DroidFront), 11-13 the side move while falling (3 bytes). TurnRound `$7866` mirrors `$9C40-$A45F` in place, all but DroidFront, so the image holds the right-facing set and play turns it; PlaceDroid `$7A6D` reads DroidGraphics + 4 (`$70` in the right-facing set) to know which way the frames face. L1: all 1 560 bytes read (3 586 417 reads), 1 480 written (127 784 writes: the mirroring; DroidFront's 80 bytes never). | `Interrupt`, `MoveDroid`, `PlaceDroid`, `TurnRound` | `TurnRound` |
| `$A258` | `DroidMirrorSpare` | 600 | 600 zero bytes inside the mirrored range. TurnRound's 3-byte pass runs to `$A45F`, so it mirrors these zeros too (L1: 600 bytes, 52 680 reads and as many writes, all zeros); no frame points here. | `TurnRound` | `TurnRound` |
| `$A4B0` | `ZeroFill3` | 670 | 670 zero bytes no code reads or writes. L1: no access in `$A4B0-$A74D`. | - | - |
| `$A74E` | `EnemyGraphicsData` | 1911 | The nine enemy kinds: 35 frames of 49 bytes (shift byte, 16 rows of 3 bytes). EnemyGraphics `$68C1` points at each kind's first frame, EnemyFrameCounts `$68B8` gives its frames (4, 3, then 4). ShiftGraphic3 shifts a frame in place to the enemy's x. L1: every byte of `$A74E-$AEC4` read (1 244 984 reads) and written (375 902 writes). | `MoveEnemy`, `ShiftGraphic3` | `ShiftGraphic3` |
| `$AEC5` | `MaterialiseGraphics` | 192 | An enemy materialising: 4 frames of 48 bytes (16 rows of 3, no shift byte). MaterialiseFrames `$68DB`. The frames are drawn at a byte column, so they are not shifted. L1: 192 bytes, 178 998 reads, no write. | `MoveEnemy`, `ShiftGraphic3` | - |
| `$AF85` | `ProbeGraphics` | 196 | Weapon 3's probe: 4 frames of 49 bytes (shift byte, 16 rows of 3). FireWeapon3 (`$861C`) and MoveShot3Frame (`$8298` on) point the shot at frame (ShotFrame AND 3): 0, 1, 2, 3, then back down. L1: only the recordings rzx-040000, rzx-052000 and rzx-070000 fire weapon 3; they read frames 2 and 3 (`$AFB6-$B017`, 291 reads), so frames 1 and 4 are known only from the code there. The recording probe-shield (tjB, doc 05 5.8) shows frames 2 and 4 too (rows at `$AFB7` and `$B019`, counting from 1 as above), so only frame 1 is known only from the code. No write: the shift was 0 each time. | - | - |
| `$B049` | `ObjectGraphics` | 2233 | The five object kinds: 17 frames of 97 bytes (shift byte, 24 rows of 4 bytes). ObjectKind `$7C28` by the kind bits: bit 4 `$B049` (3 frames), bit 5 `$B16C` (4), bit 6 `$B2F0` (3), bit 7 `$B413` (4), none `$B597` (3). ShiftGraphic4 shifts a frame in place to the object's x. L1: all 1 649 bytes read (355 694 reads), 1 358 written (69 341 writes: `$B049-$B2EF` and `$B413-$B6B9`; kind 6 at `$B2F0` never shifted). | `Interrupt`, `ShiftGraphic4` | `ShiftGraphic4` |
| `$B902` | `PatrolRight` | 768 | A patroller going right: 4 frames of 96 bytes (24 rows of 4). MovePatrollers `$6AAD` takes this set for a patroller moving right (direction bit 0 of +1 clear) and PatrolLeft for one moving left. Not shifted: a patroller moves a byte column at a time. L1: 768 bytes, 96 192 reads, no write. | - | - |
| `$BC02` | `MenuFrameTopEdge` | 256 | The menu screen's frame: 8 blocks of 16 x 16 pixels (16 rows of 2 bytes). Menu `$8854` draws the frame with Blit16: the top edge 14 times along row 0, the bottom edge along row 22, the left and right edges 10 times down columns 0 and 30, and the four corners. L1 reads 4 992 (4 menus x 1 248). | `Blit16` | - |
| `$BD02` | `ZeroFill4` | 4 | 4 zero bytes no code reads | - | - |

## roomdata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BD06` | `RoomLayouts` | 256 | The layout offsets: room n's tiles at RoomLayouts + RoomLayouts[n]. DrawRoomLayout `$6C93` reads it (L1 285 rooms drawn; 224 of the 256 bytes read, 560 reads). The offsets of the 102 full rooms rise in room order: the records are contiguous. | `DrawRoom` | - |
| `$BE06` | `RoomLayoutRecords` | 7501 | The layouts: (column, row, tile) triples, ended by a byte with bit 7 set (`$80`). DrawRoomLayout `$6C93` draws tile n (TileGraphics `$6EA8`, TileAttrs `$6F36`) with its top-left character at column, row (row from the top of the play area). L1: 7 343 of the 7 501 bytes read (19 362 reads; the rest are rooms no recording entered). The tiles of a room also make its cells (CellTable `$60C0`): bit 0 of a cell marks a wall. | `DrawRoom` | - |
| `$DB53` | `AlienMap` | 256 | The alien map offsets: room n's record at AlienMap + AlienMap[n]. RoomRecord `$7B8F` (L1 4 746 calls), DrawRoom (279), SaveRoomObjects `$6ADC` (276), the item pickup (50). L1: all 256 bytes read, 9 184 reads. | `DrawRoom`, `MoveDroid`, `RoomRecord`, `SaveRoomObjects` | - |
| `$DC53` | `AlienRecords` | 941 | The alien records: items, teleporter, enemies and objects of each room. A record: item 1's position byte (0: none; else its kind follows), item 2's position (0 or position and kind), the teleporter's position (0 or position and target room), the enemy mask (bit k: enemy k may spawn here), object 1 (0, or its 10-byte record as Objects holds it), object 2 (the same). A position byte is (column / 2) x 16 + the row in cells (ItemCell `$6E88`). The records change in play: ScrambleRooms `$7BA0` moves the item kinds, SaveRoomObjects writes the objects back, a pickup zeroes a position; the image holds the start of a game as the authors saved it. L1: 937 of 941 bytes read (17 272 reads), 326 written (3 155 writes). | `DrawRoom`, `InitRooms`, `MoveDroid`, `SaveRoomObjects`, `ScrambleRooms` | `InitRooms`, `MoveDroid`, `SaveRoomObjects`, `ScrambleRooms` |
| `$E000` | `FontPad` | 2 | 2 zero bytes before the font; the scroller reads `$E001` as line 0 of a space. Interrupt `$95D0` takes Font - 257 + 8 x code + ScrollLine, so line 0 of a character is the last line of the one before it; for a space that is `$E001` (L1 772 reads). `$E000` is unread. | `Interrupt` | - |
| `$E002` | `Font` | 480 | The font: 60 characters of 8 bytes, codes `$20-$5B` (space to '['). PrintText `$8AB4` (LD BC,Font - 256: Font - `$100` + 8 x code), the scroller (Font - 257 + 8 x code + the line). L1: 282 of the 480 bytes read (25 630 reads); the characters no text uses stay unread. | `Interrupt`, `Print8` | - |
| `$E1E2` | `EdPieces` | 1600 | The picture the ED pieces make: 50 tiles of 16 x 16 pixels (16 rows of 2 bytes), 10 x 5. Tile row x 10 + column. Piece n (kind `$81` + n) is the tile at column (n - 1) / 5, row (n - 1) % 5, so EdFlags byte (n - 1) / 5 is a column of the picture and its bit (n - 1) % 5 the row. DrawItem `$6E0D` draws a piece lying in a room (LD HL,EdPieces - 352 at `$6E34`, then 32 a column and 320 a row; worked out for n = 1-50); ProgressScreen `$8F53` draws the found tiles at `$4886`. L1: all 1 600 bytes read, 28 384 reads. | `Blit16` | - |
| `$E822` | `TileData` | 5598 | The tile graphics: blocks of [width in bytes][height in pixel rows][width x height bytes, top row first]. TileGraphics `$6EA8` points at each tile's block; DrawRoomLayout draws them (DrawTilePixels `$6CE8`: the rows go down the screen, a byte column at a time; bytes over the HUD rows are skipped). The 70 blocks the table points at do not overlap and do not follow the tile order. Two parts no code reads: the 56 zero bytes `$F8A6-$F8DD` between blocks, and the block of the 71st table word, `$FDDC-$FDFD` (2 x 16, a graphic no room uses: the word itself is never read), then 2 bytes `$FDFE-$FDFF`. L1: 4 728 of the 5 598 bytes read (479 258 reads); `$FDDC-$FDFF`: no access. | `DrawRoom` | - |
