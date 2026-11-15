# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a table jump or
by running on: L1 books its time to the routine it runs in) gives the runs of its first instruction, as its witness
line counts them.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`zones`](11-data-reference.md#zones) | `$6000`-`$75FF` | 0 of 6 |
| [`rooms`](#rooms) | `$7600`-`$90FF`, `$950A`-`$9722`, `$A89A`-`$AD27` | 15 of 44 |
| [`entry`](#entry) | `$9100`-`$9225` | 3 of 5 |
| [`interrupt`](#interrupt) | `$9226`-`$9509`, `$CBF9`-`$CC7F` | 10 of 17 |
| [`menu`](#menu) | `$9723`-`$A193` | 31 of 45 |
| [`renderer`](#renderer) | `$A194`-`$A899`, `$C9EA`-`$CBF8` | 24 of 33 |
| [`objects`](#objects) | `$AD28`-`$B3EA`, `$BC96`-`$C9E9` | 121 of 140 |
| [`matt`](#matt) | `$B3EB`-`$BC95` | 55 of 60 |
| [`sprites`](11-data-reference.md#sprites) | `$CC80`-`$DF7F` | 0 of 24 |
| [`buffers`](11-data-reference.md#buffers) | `$DF80`-`$FDFF` | 0 of 11 |

## rooms

`src/game/rooms.asm`

### `CharGlyph` (`$96BE`)

**HL = the 5-byte glyph of character A (letters, digits, '.', ':', space)**

Witness: L1 40146 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,718 calls, 567,606 t-states own (0.04 %) |
| Runs (the other recordings) | 36,428 calls (`stage2/rec/play2` 3,540, `stage1/rec/rzx-16000` 3,344, `stage1/rec/rzx-12000` 2,869 and 13 more) |
| Called from | `PrintChar`, `ScrollerNextChar` |

### `DrawRoom` (`$A89D`)

**Draw the screen RoomScreen of room RoomNumber and set up its objects, pick-ups and message**

Room 15 at screen 5 is the end: Ending `$ADF6`. Clears objects 2-7 (3-7 while the chaser lives), expands the 8 x 5 blocks into the character map, SwapZone, marks every cell dirty and flushes, sets EnemyKind `$BFB0` from RoomTable byte 6 + screen, then MoonMasks `$ADD2`, AnimatedCharList `$AB6B`, FindLift `$AA75`, PlaceTurrets `$AC42`, FindSpawnPoints `$ACA0`, FindBlockItems `$ACEA`, FindFloorRow `$AC80`, PlacePickupsInScreen `$A9BE`, EffectStops+1 = `$FF` and RoomMessage `$AD28`. Before the blocks: a new room (RoomNumber not MapPointer+2) clears ChaserState, ShotOff `$BD7F` ends Matt's shot, and with ChaserState set only objects 3-7 are cleared (the chaser survives a screen change).

Witness: L1 87 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

[Animation: `DrawRoom` at work, decode](img/routines/DrawRoom-decode.gif)

[Animation: `DrawRoom` at work, heaviest](img/routines/DrawRoom-heaviest.gif)

[Animation: `DrawRoom` at work, room0](img/routines/DrawRoom-room0.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 32,470 t-states own (0.00 %) |
| Runs (the other recordings) | 86 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-32000` 10, `stage1/rec/rzx-12000` 10 and 12 more) |
| Called from | `NewGame`, `LeftEdge`, `RightEdge`, `Teleport` (tail), `PasswordWarp` (tail) |
| Calls | `SwapZone`, `FlushDirty`, `PlacePickupsInScreen`, `FindLift`, `AnimatedCharList`, `PlaceTurrets`, `FindFloorRow`, `FindSpawnPoints`, `FindBlockItems`, `RoomMessage` (tail), `MoonMasks`, `Ending` (tail), `ShotOff` |
| Reads | `$7600`-`$775F` (`Room0Map`, `Room1Map`); `$7780`-`$778F` (`Room1Map+144`); `$77B0`-`$77BF` (`Room1Map+192`); `$77F0`-`$786F` (`Room2Map+16`); `$7880`-`$789F` (`Room2Map+160`); `$78B0`-`$78D7` (`Room2Map+208`, `Room3Map`); 34 more ranges |
| Writes | `$946D` (`EffectStops+1`); `$950B`-`$950C` (`RoomRecord`); `$A2CE` (`FirstSpriteChar`); `$A48B` (`Enemies`); `$A4AA`-`$A4B1` (`Enemies+31`); `$A4D0`-`$A4D7` (`Enemies+69`); 9 more ranges |

### `PlacePickupsInScreen` (`$A9BE`)

**Make the icons of this screen's untaken masks (PickupTable) as characters**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 111 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-12000` 10, `stage1/rec/rzx-32000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Calls | `PlacePickup` (falls into) |
| Reads | `$950A`-`$950D` (`RoomNumber`, `RoomRecord`, `RoomScreen`) |

### `PlacePickup` (`$A9DA`)

**One pick-up: its icon from MaskIcons `$D580` + 32 x kind, coloured MaskColours[kind]**

Witness: L1 172 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 calls, 2,828 t-states own (0.00 %) |
| Runs (the other recordings) | 170 calls (`stage1/rec/rzx-00000` 26, `stage1/rec/rzx-32000` 20, `stage1/rec/rzx-12000` 20 and 12 more) |
| Called from | `PlacePickupsInScreen` (falls into) |
| Calls | `FindPickup` |
| Reads | `$950F`-`$9535` (`PickupTable+1`); `$A2CE` (`FirstSpriteChar`); `$AF1B`-`$AF25` (`PickupRecords`); `$AF47`-`$AF4E` (`MaskColours+1`); `$D5A0`-`$D5BF` (`MaskIcons+32`); `$D600`-`$D69F` (`MaskIcons+128`) |
| Writes | `$A2CE` (`FirstSpriteChar`); `$AF1B`-`$AF2A` (`PickupRecords`); `$E800`-`$E83F` (`SpriteChars`); `$EE00`-`$EE07` (`Zone1Attrs`) |

### `FindPickup` (`$AA59`)

**The PickupTable record of this room at Matt's place**

Witness: L1 172 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 calls, 220 t-states own (0.00 %) |
| Runs (the other recordings) | 170 calls (`stage1/rec/rzx-00000` 26, `stage1/rec/rzx-32000` 20, `stage1/rec/rzx-12000` 20 and 12 more) |
| Called from | `PlacePickup` |
| Reads | `$950E`-`$953A` (`PickupTable`) |

### `FindLift` (`$AA75`)

**Zone 0: find character `$34` in the screen (the lift), else none**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 28,921 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-32000` 10, `stage1/rec/rzx-12000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Reads | `$A194` (`ZoneSlots`); `$F0C0`-`$F2FF` (`CharMap+64`) |
| Writes | `$AA72`-`$AA74` (`LiftPlace`) |

### `AnimatedCharList` (`$AB6B`)

**List the cells of the zone's animated characters (AnimatedChars) into AnimatedCells**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 64,607 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-32000` 10, `stage1/rec/rzx-12000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Reads | `$A194` (`ZoneSlots`); `$AB69`-`$AB6A` (`AnimatedCells+200`); `$ABB5`-`$ABFB` (`AnimatedChars`); `$F0C0`-`$F2FF` (`CharMap+64`) |
| Writes | `$AAA1`-`$AAE2` (`AnimatedCells`); `$AB69`-`$AB6A` (`AnimatedCells+200`); `$AB8A`-`$AB8B` (`l_AB89+1`) |

### `FindBlock` (`$ABFD`)

**B, C = the place of the first block A in the screen's map**

Witness: L1 258 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3 calls, 4,688 t-states own (0.00 %) |
| Runs (the other recordings) | 255 calls (`stage1/rec/rzx-00000` 39, `stage1/rec/rzx-12000` 30, `stage1/rec/rzx-32000` 30 and 12 more) |
| Called from | `PlaceTurrets`, `FindSpawnPoints`, `FindBlockItems` |
| Calls | `l_AC16` (tail) |
| Reads | `$7600`-`$778F` (`Room0Map`, `Room1Map`); `$77B0`-`$77BF` (`Room1Map+192`); `$77F0`-`$786F` (`Room2Map+16`); `$7880`-`$789F` (`Room2Map+160`); `$78B0`-`$78D7` (`Room2Map+208`, `Room3Map`); `$78F0`-`$7907` (`Room3Map+32`); 19 more ranges |
| Writes | `$ABFC` (`AnimatedChars+71`) |

### `l_AC16` (`$AC16`)

**l_AC16**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`stage1/rec/rzx-16000` 6, `stage1/rec/rzx-20000` 4, `stage2/rec/door` 4 and 1 more) |
| Called from | `FindBlock` (tail), `FindNextBlock` (tail) |

### `FindNextBlock` (`$AC2F`)

**The next one**

Witness: L1 19 (door, rzx- x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 19 calls (`stage1/rec/rzx-16000` 4, `stage1/rec/rzx-20000` 4, `stage2/rec/door` 4 and 5 more) |
| Called from | `PlaceTurrets`, `FindSpawnPoints`, `FindBlockItems` |
| Calls | `l_AC16` (tail) |
| Reads | `$767F` (`Room0Map+127`); `$76A8`-`$76AF` (`Room0Map+168`); `$76D8`-`$76DF` (`Room0Map+216`); `$7788`-`$778F` (`Room1Map+152`); `$77B8`-`$77BF` (`Room1Map+200`); `$7932`-`$7937` (`Room3Map+98`); 11 more ranges |

### `PlaceTurrets` (`$AC42`)

**Every block `$12` of the screen becomes a turret object (kind 4, template 2: animation 3, so it bobs at once), the next slot reserved (`$40`); the SUB `$02` at `$AC55` is dead (LD A,C follows), so y is the block's row**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 57 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-12000` 10, `stage1/rec/rzx-32000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Calls | `FindBlock`, `FindNextBlock`, `SetupObject` |
| Reads | `$C0D6` (`ChaserState`) |
| Writes | `$A48B`-`$A4B1` (`Enemies`); `$A4D7`-`$A4FD` (`Enemies+76`) |

### `FindFloorRow` (`$AC80`)

**FloorRow from the attributes (bit 7)**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 766 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-32000` 10, `stage1/rec/rzx-12000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Reads | `$EF00`-`$EF23` (`ZoneAttrs`); `$EF3E` (`ZoneAttrs+62`); `$EF53`-`$EF88` (`ZoneAttrs+83`); `$EF9A`-`$EFA8` (`ZoneAttrs+154`); `$EFE2`-`$EFFD` (`ZoneAttrs+226`); `$F0C0`-`$F1E0` (`CharMap+64`); 7 more ranges |
| Writes | `$AC7F` (`FloorRow`) |

### `FindSpawnPoints` (`$ACA0`)

**Up to two blocks `$61` into SpawnPoints**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 77 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-12000` 10, `stage1/rec/rzx-32000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Calls | `FindBlock`, `FindNextBlock` |
| Writes | `$AC9C`-`$AC9F` (`SpawnPoints`) |

### `PasswordPods` (`$ACBC`)

**Room 0's four door lamps at map `$7628` (screen 5, top row): blocks `$45`/`$46` shut, `$1E`/`$1F` lit for each password entered**

Witness: L1 21 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 360 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-04000` 2, `stage1/rec/rzx-24000` 2 and 11 more) |
| Called from | `NewGame` (tail) |
| Reads | `$9F6D`-`$9F70` (`PasswordFlags`) |
| Writes | `$7628`-`$762F` (`Room0Map+40`) |

### `FindBlockItems` (`$ACEA`)

**The block-`$1B` items into BlockItems**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 249 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-12000` 10, `stage1/rec/rzx-32000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Calls | `FindBlock`, `FindNextBlock` |
| Writes | `$ACDA`-`$ACE6` (`BlockItems`) |

## entry

`src/game/entry.asm`

### `GameEntry` (`$9100`)

**The entry from the loader: the parked zone 1, IM 2, the Kempston test, then GameStart**

Copies Zone1CharsLow `$F000` to `$5B00` (1280 bytes) and Zone1Attrs `$EE00` to `$6300` (256), so that zone 1 is whole in the first parked slot; sets R = `$FF` (the random generator Random `$92C6` reads R), SP = StackTop, I = `$FE` and fills ImTable `$FE00-$FF00` with `$FF`; writes JR (ImJr `$FFFF` = `$18`) and JP Interrupt `$9226` at ImJump `$FFF4`, then IM 2. Clears the first attribute of each zone set (`$EF00`, `$6300`, `$6C00`, `$7500`). KempstonTest `$9F62` sets ControlMethod `$A13A` to 0 (Kempston) when an interface answers. Then JP GameStart `$CBF9`.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 40,306 t-states own (0.00 %) |
| Calls | `KempstonTest`, `GameStart` (tail) |
| Reads | `$EE00`-`$EEFF` (`Zone1Attrs`); `$F000`-`$F4FF` (`Zone1CharsLow`, `CharMap`, `MirrorBuffer`, `DirtyMap`); `$FE00`-`$FEFF` (`work space $FE00+`) |
| Writes | `$5B00`-`$5FFF` (`ParkedZone1`); `$6300`-`$63FF` (`Zone1AttrsLeftover`); `$6C00` (`Zone2Attrs`); `$7500` (`Zone3Attrs`); `$A13A` (`ControlMethod`); `$EF00` (`ZoneAttrs`); 2 more ranges |

### `NewGame` (`$915B`)

**A new game: Matt in room 0, full energy, empty masks, the pick-ups and the maps restored**

Room 0, screen 0 (RoomNumber `$950A`, RoomScreen `$950D`); Energy `$AEA6` = `$FF`; Matt (Objects `$A43F`) at x `$48`, y `$28`, state `$0B`, facing right; clears bit 7 (taken) of every PickupTable `$950E` record; empties the four MaskSlots `$AF2B` and selects the first; ShowMaskName EMPTY; turns the map blocks `$2B` back to `$12` and `$47` back to `$1B` in RoomMaps `$7600-$84FF` (so the maps' own `$2B`, room 5 screen 0 and room 6 screen 2, become turrets too after the first new game: rzx-16000 frame 3194); clears the end-of-level and effect flags and the Score `$AE41`. BuildTables `$A860` makes the sprite tables first. Ends in DrawRoom `$A89D` and PasswordPods `$ACBC`.

Witness: L1 21 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 277,516 t-states own (0.02 %) |
| Runs (the other recordings) | 20 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-32000` 2, `stage1/rec/rzx-24000` 2 and 11 more) |
| Called from | `GameStart` |
| Calls | `BuildTables`, `DrawRoom`, `PasswordPods` (tail), `DrawAllSlots` |
| Reads | `$7600`-`$84FF` (`Room0Map`, `Room1Map`, `Room2Map`, `Room3Map` and 12 more); `$950E`-`$953A` (`PickupTable`) |
| Writes | `$767E` (`Room0Map+126`); `$775F`-`$779D` (`Room1Map+111`); `$7931`-`$797E` (`Room3Map+97`); `$7A6E`-`$7B14` (`Room4Map+174`, `Room5Map`); `$7BE3` (`Room6Map+67`); `$7D1E`-`$7D2E` (`Room7Map+142`); 16 more ranges |

### `HangLoop` (`$9208`)

**Never run: DI, then flash the border forever (the kind-0 slot of ObjectJumps `$C326` jumps here)**

XOR 7, OUT (`$FE`), JP HangLoop. Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## interrupt

`src/game/interrupt.asm`

### `Interrupt` (`$9226`)

**The IM 2 handler (via ImJump `$FFF4`): keys or menu, music and effects, scroller, BREAK**

Saves every register; FrameCounter `$9224` + 1, OUT BorderColour. In play (MenuFlag `$970E` = 0) CheatCheck `$BB4C`; in the menu MenuInterrupt `$9899`. On a 128K (MachineFlag `$FFFE` = 0): pages RAM 4 (`$7FFD` = `$14`), starts TuneRequest `$9222` (MusicStart) or StopRequest `$9223` (MusicStop), runs StopEffects `$946F` and StartEffects `$9421`, MusicPlay `$C003`; in the menu (NotInPlay `$970D`) it restarts tune 1 when MusicTune ends; pages RAM 0 back (`$10`). On a 48K: StopBeeper `$949F` and BeeperTick `$94C8`. In play: Scroller `$AF82`, and CAPS SHIFT + SPACE (BREAK) aborts to GameStart `$CBF9`.

Witness: L1 63268 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

[Animation: `Interrupt` at work](img/routines/Interrupt.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 7,279 calls, 4,967,164 t-states own (0.31 %) |
| Runs (the other recordings) | 55,989 calls (`stage2/rec/play2` 7,370, `stage1/rec/rzx-16000` 3,999, `stage1/rec/rzx-24000` 3,999 and 13 more) |
| Calls | `StartEffects`, `StopEffects`, `StopBeeper`, `BeeperTick`, `MenuInterrupt`, `Scroller`, `CheatCheck`, `GameStart` (tail) |
| Reads | `$9222`-`$9225` (`TuneRequest`, `StopRequest`, `FrameCounter`, `BorderColour`); `$970D`-`$970E` (`NotInPlay`, `MenuFlag`); `$FFFE` (`work space $FFFE+`) |
| Writes | `$9222`-`$9224` (`TuneRequest`, `StopRequest`, `FrameCounter`) |
| Ports in | `$7FFE`, `$FEFE` |
| Ports out | `$00FE`, `$7FFD` |

### `Random` (`$92C6`)

**A = a pseudo-random byte from RandomSeed and R**

Witness: L1 100334 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 13,421 calls, 2,161,199 t-states own (0.14 %) |
| Runs (the other recordings) | 86,913 calls (`stage2/rec/play2` 10,379, `stage1/rec/rzx-16000` 8,261, `stage1/rec/rzx-00000` 7,290 and 13 more) |
| Called from | `l_9F2E`, `Dissolve`, `Explosion`, `Spawn`, `SpawnFlyer`, `SetupObject`, `SpawnFaller`, `SpawnWave`, `SpawnRiser`, `Explode`, `KindTurret`, `KindWalker`, `KindEleven`, `KindFourteen`, `KindSixteen`, `KindSeventeen`, `AnimateZone1` |
| Reads | `$92C3`-`$92C5` (`RandomSeed`) |
| Writes | `$92C3`-`$92C5` (`RandomSeed`) |

### `PlayEffect` (`$93DC`)

**Start sound effect A: an AY channel slot on a 128K, the beeper on a 48K**

128K: record + `$0A` picks the slot (1 EffectSlotA `$941B`, 2 `$941D`, else `$941F`) that StartEffects `$9421` reads at the next interrupt. 48K: BeeperStart `$94AF`.

Witness: L1 638 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 6 calls, 1,842 t-states own (0.00 %) |
| Runs (the other recordings) | 632 calls (`stage1/rec/rzx-32000` 141, `stage1/rec/rzx-08000` 113, `stage1/rec/rzx-16000` 78 and 12 more) |
| Called from | `StartWarp`, `PodStart`, `Death`, `Explosion`, `FireMask`, `Penetrator`, `SpawnKind6`, `Explode` (tail), `KindWave`, `KindChaser`, `KindEleven` (tail), `KindSixteen` |
| Calls | `BeeperState` |
| Reads | `$92F8` (`EffectTable+24`); `$9314`-`$9330` (`EffectTable+52`); `$934C` (`EffectTable+108`); `$9368`-`$93AE` (`EffectTable+136`); `$93CA`-`$93D8` (`EffectTable+234`); `$FFFE` (`work space $FFFE+`) |
| Writes | `$941B`-`$9420` (`EffectSlots`) |

### `StartEffects` (`$9421`)

**Interrupt, 128K: hand each waiting effect to the AY player (EffectStart with IX = the channel block)**

Witness: L1 26094 (c1, cheat, door, door3, kind6, masks, play2).

[Animation: `StartEffects` at work](img/routines/StartEffects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 7,279 calls, 779,189 t-states own (0.05 %) |
| Runs (the other recordings) | 18,815 calls (`stage2/rec/play2` 7,370, `stage2/rec/door3` 3,003, `stage2/rec/kind6` 2,275 and 3 more) |
| Called from | `Interrupt` |
| Reads | `$92F9`-`$92FB` (`EffectTable+25`); `$9315`-`$9333` (`EffectTable+53`); `$934D`-`$934F` (`EffectTable+109`); `$9369`-`$9395` (`EffectTable+137`); `$93CB`-`$93DB` (`EffectTable+235`); `$941B`-`$9420` (`EffectSlots`) |
| Writes | `$941B`-`$9420` (`EffectSlots`) |

### `StopEffects` (`$946F`)

**Interrupt, 128K: silence each channel whose EffectStops flag is set (writes the player's block +6)**

Channel C's test is inverted (RET NZ at `$9493`): it zeroes channel C's hold every interrupt while its flag is clear and does nothing when it is set. Inaudible: channel C's envelopes end by themselves (docs/09-sound.md, 9.9).

Witness: L1 26094 (c1, cheat, door, door3, kind6, masks, play2).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 7,279 calls, 968,145 t-states own (0.06 %) |
| Runs (the other recordings) | 18,815 calls (`stage2/rec/play2` 7,370, `stage2/rec/door3` 3,003, `stage2/rec/kind6` 2,275 and 3 more) |
| Called from | `Interrupt` |
| Reads | `$946C`-`$946E` (`EffectStops`) |
| Writes | `$946C`-`$946E` (`EffectStops`); `$94AB` (`BeeperState`) |

### `StopBeeper` (`$949F`)

**Interrupt, 48K: the beeper's version of StopEffects**

Witness: L1 37174 (rzx- x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 37,174 calls (`stage1/rec/rzx-24000` 3,999, `stage1/rec/rzx-08000` 3,999, `stage1/rec/rzx-16000` 3,999 and 7 more) |
| Called from | `Interrupt` |
| Reads | `$946C` (`EffectStops`) |
| Writes | `$946C` (`EffectStops`); `$94AB` (`BeeperState`) |

### `BeeperStart` (`$94B0`)

**48K: LD (`$94AE`),HL and the effect's count and pitch (entered at `$94AF`)**

Witness: L1 541 (rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 541 runs of its first instruction, entered by a jump (`stage1/rec/rzx-32000` 141, `stage1/rec/rzx-08000` 113, `stage1/rec/rzx-16000` 78 and 6 more) |

### `BeeperOff` (`$94C3`)

**Never run: clear the beeper count**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BeeperTick` (`$94C8`)

**Interrupt, 48K: one burst of the beeper effect on bits 3-4 of port `$FE`**

The low half of the period is not reloaded: the JR NZ at `$9505` has no DEC before it, so the low half never waits (docs/09-sound.md, 9.7 and 9.9).

Witness: L1 37174 (rzx- x10).

[Animation: `BeeperTick` at work](img/routines/BeeperTick.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 37,174 calls (`stage1/rec/rzx-16000` 3,999, `stage1/rec/rzx-24000` 3,999, `stage1/rec/rzx-08000` 3,999 and 7 more) |
| Called from | `Interrupt` |
| Reads | `$9225` (`BorderColour`); `$92E7`-`$9312` (`EffectTable+7`); `$933B`-`$9366` (`EffectTable+91`); `$9381`-`$93BA` (`EffectTable+161`); `$94AB`-`$94AF` (`BeeperState`, `BeeperRecord`) |
| Writes | `$94AB`-`$94AD` (`BeeperState`) |
| Ports out | `$00FE`, `$18FE` |

### `GameStart` (`$CBF9`)

**The menu, a new game, then the main loop**

Witness: L1 19 (c1, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 531,207 t-states own (0.03 %) |
| Runs (the other recordings) | 18 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-04000` 2, `stage1/rec/rzx-24000` 2 and 9 more) |
| Called from | `GameEntry` (tail), `Interrupt` (tail), `Ending` (tail), `GameOver` (tail) |
| Calls | `NewGame`, `Menu`, `ReadControls`, `DrawObjects`, `DrawScore`, `DrawEnergyBar`, `DrawCurrentSlot`, `MaskKeys`, `Hazards`, `MattStep`, `Death` (tail), `FireMask`, `MoveShot`, `RunObjects`, `AnimateZone` |
| Reads | `$A43F` (`Objects`); `$AEA6` (`Energy`); `$AF0C` (`PassCounter`); `$B2F8` (`DeathFlag`); `$CC5C` (`PassBcd`) |
| Writes | `$A2CF` (`DissolveCount`); `$A43F`-`$A44F` (`Objects`); `$AF0C` (`PassCounter`); `$BAA7` (`Dying`); `$CC5C` (`PassBcd`) |

## menu

`src/game/menu.asm`

### `Menu` (`$9723`)

**The menu: wipe, logo, strings; MenuLoop until fire, then the play screen's panel and tune 3**

Witness: L1 19 (c1, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 14,359,188 t-states own (0.91 %) |
| Runs (the other recordings) | 18 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-28000` 2, `stage1/rec/rzx-32000` 2 and 9 more) |
| Called from | `GameStart` |
| Calls | `MenuWipe`, `ClearScreen`, `DrawGraphic`, `SaveHud` |
| Reads | `$9710` (`HudSaved`); `$9781` (`l_9780+1`); `$A081`-`$A08F` (`KeysIf2`, `KeysCursor`, `KeysUser`); `$A13A` (`ControlMethod`); `$A150`-`$A154` (`KeysNow`); `$F2F0`-`$F33F` (`CharMap+624`, `MirrorBuffer`); 1 more ranges |
| Writes | `$52E0`-`$52FF` (screen); `$5A40`-`$5AFF` (screen); `$9222` (`TuneRequest`); `$970D`-`$9710` (`NotInPlay`, `MenuFlag`, `HudSaved`); `$A08B`-`$A08F` (`KeysUser`); `$A13A` (`ControlMethod`); 4 more ranges |

### `MenuLoop` (`$9775`)

**MenuLoop**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 5 calls (`stage2/rec/play2` 4, `stage2/rec/cheat` 1) |
| Called from | `EnterPassword` (tail) |
| Calls | `DrawGraphic`, `PrintChar`, `DrawMenu`, `ClearMenuArea`, `DefineKeys`, `ColourScroll`, `KempstonTest`, `EnterPassword` (tail), `ScreenWipe`, `KeyPressed`, `ReadKeyCode`, `ReadControls` |
| Reads | `$9781` (`l_9780+1`); `$A086`-`$A08A` (`KeysCursor`); `$A13A` (`ControlMethod`); `$FC64`-`$FD23` (`PanelAttrs`) |
| Writes | `$5A40`-`$5AFF` (screen); `$9222` (`TuneRequest`); `$970D`-`$970E` (`NotInPlay`, `MenuFlag`); `$9F6D`-`$9F70` (`PasswordFlags`); `$A13A` (`ControlMethod`); `$A150`-`$A154` (`KeysNow`); 2 more ranges |

### `MenuWipe` (`$984D`)

**Wipe the attributes diagonally (PokeAttr)**

Witness: L1 19 (c1, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 2,678,366 t-states own (0.17 %) |
| Runs (the other recordings) | 18 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-28000` 2, `stage1/rec/rzx-24000` 2 and 9 more) |
| Called from | `Menu` |
| Calls | `MenuWipeStep` |
| Reads | `$9853` (`l_984F+4`) |

### `MenuWipeStep` (`$985A`)

**One diagonal of the wipe**

Witness: L1 1330 (c1, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 70 calls, 667,380 t-states own (0.04 %) |
| Runs (the other recordings) | 1,260 calls (`stage2/rec/play2` 210, `stage1/rec/rzx-24000` 140, `stage1/rec/rzx-28000` 140 and 9 more) |
| Called from | `MenuWipe` |
| Calls | `PokeAttr` |

### `PokeAttr` (`$9876`)

**Set the attribute at row D, column E to A when they are on the screen**

Witness: L1 323612 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 26,488 calls, 3,299,418 t-states own (0.21 %) |
| Runs (the other recordings) | 297,124 calls (`stage2/rec/play2` 58,676, `stage1/rec/rzx-28000` 31,780, `stage1/rec/rzx-32000` 29,308 and 12 more) |
| Called from | `MenuWipeStep`, `MenuInterrupt`, `DrawMenu` |
| Writes | `$5800`-`$5AFF` (screen) |

### `MenuInterrupt` (`$9899`)

**The menu's interrupt: the logo's raster colours, the lit control icon, the border bars, the colour scroll**

Witness: L1 16790 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,248 calls, 60,724,608 t-states own (3.84 %) |
| Runs (the other recordings) | 13,542 calls (`stage2/rec/play2` 4,526, `stage1/rec/rzx-08000` 1,355, `stage1/rec/rzx-28000` 1,204 and 12 more) |
| Called from | `Interrupt` |
| Calls | `PokeAttr`, `LogoRaster`, `ColourScroll`, `l_9F2E` (tail) |
| Reads | `$9711`-`$9721` (`MenuColours`, `MenuColourCount`); `$9D01`-`$9D0B` (`ControlIconPlaces`); `$A13A` (`ControlMethod`); `$F0C0`-`$F0C9` (`CharMap+64`); `$F110`-`$F119` (`CharMap+144`); `$F160`-`$F169` (`CharMap+224`); 5 more ranges |
| Writes | `$580B`-`$5814` (screen); `$582B`-`$5834` (screen); `$584B`-`$5854` (screen); `$586B`-`$5874` (screen); `$588B`-`$5894` (screen); `$58AB`-`$58B4` (screen); 2 more ranges |
| Ports out | `$00FE`, `$04FE` |

### `ClearScreen` (`$992F`)

**Clear the bitmap and the attributes**

Witness: L1 19 (c1, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 187,864 t-states own (0.01 %) |
| Runs (the other recordings) | 18 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-04000` 2, `stage1/rec/rzx-24000` 2 and 9 more) |
| Called from | `Menu` |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |

### `LogoRaster` (`$9951`)

**Colour the logo line by line (LDI from the buffer at `$F0CA` in time with the beam)**

Witness: L1 16790 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,248 calls, 87,310,546 t-states own (5.52 %) |
| Runs (the other recordings) | 13,542 calls (`stage2/rec/play2` 4,526, `stage1/rec/rzx-08000` 1,355, `stage1/rec/rzx-28000` 1,204 and 12 more) |
| Called from | `MenuInterrupt` |
| Reads | `$F0CA`-`$F2EF` (`CharMap+74`) |
| Writes | `$580B`-`$5814` (screen); `$582B`-`$5834` (screen); `$584B`-`$5854` (screen); `$586B`-`$5874` (screen); `$588B`-`$5894` (screen); `$58AB`-`$58B4` (screen); 1 more ranges |
| Ports out | `$00FE` |

### `ScreenAddr` (`$999E`)

**HL = the screen address of character row D, column E**

Witness: L1 1013 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 56 calls, 6,328 t-states own (0.00 %) |
| Runs (the other recordings) | 957 calls (`stage2/rec/play2` 233, `stage1/rec/rzx-08000` 120, `stage1/rec/rzx-28000` 78 and 12 more) |
| Called from | `DrawGraphic`, `PrintString`, `DrawMenu`, `EnterPassword`, `SlowPrint` |

### `DrawGraphic` (`$99B8`)

**Draw B x C characters from HL at row D, column E**

Witness: L1 351 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 18 calls, 103,563 t-states own (0.01 %) |
| Runs (the other recordings) | 333 calls (`stage2/rec/play2` 75, `stage1/rec/rzx-08000` 39, `stage1/rec/rzx-28000` 28 and 12 more) |
| Called from | `Menu`, `MenuLoop`, `DrawMenu` |
| Calls | `ScreenAddr` |
| Reads | `$99F0`-`$9C9F` (`MenuLogo`, `MenuBadge`, `MenuBanner`); `$CC80`-`$CD5F` (`ControlIcons`); `$F600`-`$FBFF` (`PlayPanel`, `Dilate`, `ShiftTables`) |
| Writes | `$400B`-`$57FF` (screen); `$99DF`-`$99E8` (`l_99CE+17`, `l_99E7`) |

### `SaveHud` (`$9CA0`)

**Keep screen rows 18-23 at `$F600` and their attributes at `$FC64` (the play panel, restored at the start)**

Witness: L1 18 (door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-04000` 2, `stage1/rec/rzx-28000` 2 and 9 more) |
| Called from | `Menu` |
| Reads | `$5040`-`$50FF` (screen); `$5140`-`$51FF` (screen); `$5240`-`$52FF` (screen); `$5340`-`$53FF` (screen); `$5440`-`$54FF` (screen); `$5540`-`$55FF` (screen); 3 more ranges |
| Writes | `$F600`-`$FBFF` (`PlayPanel`, `Dilate`, `ShiftTables`); `$FC64`-`$FD23` (`PanelAttrs`) |

### `PrintString` (`$9CBF`)

**Print the bit-7-terminated string at HL at row D, column E**

Witness: L1 601 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 36 calls, 21,980 t-states own (0.00 %) |
| Runs (the other recordings) | 565 calls (`stage2/rec/play2` 143, `stage1/rec/rzx-08000` 75, `stage1/rec/rzx-28000` 45 and 11 more) |
| Called from | `DrawMenu`, `DefineKeys`, `AskKey`, `EnterPassword` |
| Calls | `ScreenAddr`, `PrintChar` |
| Reads | `$9D6E`-`$9E0F` (`MenuStrings+2`); `$9E90`-`$9EA9` (`DefinePrompts`); `$9FF9`-`$A008` (`PasswordDots`) |

### `PrintChar` (`$9CD9`)

**Print character A (5-row glyph, attribute `$47`)**

Witness: L1 37418 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,598 calls, 1,324,164 t-states own (0.08 %) |
| Runs (the other recordings) | 33,821 calls (`stage1/rec/rzx-16000` 3,256, `stage2/rec/play2` 3,217, `stage1/rec/rzx-12000` 2,777 and 13 more) |
| Called from | `MenuLoop`, `PrintString`, `EnterPassword`, `Ending`, `PrintBcdByte` (tail), `SlowPrint`, `PrintSpace` |
| Calls | `CharGlyph` |
| Reads | `$95FB`-`$96BD` (`Font`) |
| Writes | `$4087`-`$4099` (screen); `$4187`-`$4199` (screen); `$4287`-`$4699` (screen); `$4787`-`$4799` (screen); `$4801`-`$481B` (screen); `$4838`-`$485D` (screen); 25 more ranges |

### `DrawMenu` (`$9D1A`)

**The 15 menu strings, the high score and the control icons**

Witness: L1 39 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 calls, 5,654 t-states own (0.00 %) |
| Runs (the other recordings) | 37 calls (`stage2/rec/play2` 9, `stage1/rec/rzx-08000` 5, `stage1/rec/rzx-20000` 3 and 11 more) |
| Called from | `MenuLoop` |
| Calls | `PokeAttr`, `ScreenAddr`, `DrawGraphic`, `PrintString`, `PrintBcd` |
| Reads | `$9D01`-`$9D19` (`ControlIconPlaces`, `Hiscore`); `$9D6C`-`$9DED` (`MenuStrings`); `$9DFE`-`$9DFF` (`MenuStrings+146`) |

### `ClearMenuArea` (`$9E10`)

**Clear the menu's text area**

Witness: L1 12 (c1, cheat, play2).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 calls, 127,806 t-states own (0.01 %) |
| Runs (the other recordings) | 10 calls (`stage2/rec/play2` 8, `stage2/rec/cheat` 2) |
| Called from | `MenuLoop`, `DefineKeys`, `EnterPassword` |
| Writes | `$40E0`-`$40FF` (screen); `$41E0`-`$41FF` (screen); `$42E0`-`$42FF` (screen); `$43E0`-`$43FF` (screen); `$44E0`-`$44FF` (screen); `$45E0`-`$45FF` (screen); 9 more ranges |

### `DefineKeys` (`$9E3B`)

**DEFINE KEYS: FIRE, UP, DOWN, LEFT, RIGHT, each a key not taken yet**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 300 t-states own (0.00 %) |
| Called from | `MenuLoop` |
| Calls | `PrintString`, `ClearMenuArea`, `AskKey` |
| Writes | `$A150`-`$A154` (`KeysNow`) |

### `AskKey` (`$9E7B`)

**Wait for a key that is not one of the keys chosen so far**

Witness: L1 5 (c1).

[Animation: `AskKey` at work](img/routines/AskKey.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 5 calls, 1,230 t-states own (0.00 %) |
| Called from | `DefineKeys` |
| Calls | `PrintString`, `WaitKey` |
| Reads | `$A150`-`$A154` (`KeysNow`) |

### `ColourScroll` (`$9EAF`)

**The menu's colour bars, a random sequence a cycle**

Witness: L1 16815 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,250 calls, 37,778,057 t-states own (2.39 %) |
| Runs (the other recordings) | 13,565 calls (`stage2/rec/play2` 4,533, `stage1/rec/rzx-08000` 1,356, `stage1/rec/rzx-28000` 1,206 and 12 more) |
| Called from | `MenuLoop`, `MenuInterrupt` |
| Reads | `$F2F0`-`$F330` (`CharMap+624`, `MirrorBuffer`) |
| Writes | `$F0C0`-`$F2EF` (`CharMap+64`) |

### `l_9F2E` (`$9F2E`)

**l_9F2E**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,248 calls, 5,597,448 t-states own (0.35 %) |
| Runs (the other recordings) | 13,542 calls (`stage2/rec/play2` 4,526, `stage1/rec/rzx-08000` 1,355, `stage1/rec/rzx-28000` 1,204 and 12 more) |
| Called from | `MenuInterrupt` (tail) |
| Calls | `Random` |
| Reads | `$9ED3`-`$9F2D` (`ColourSequences`); `$F2F1`-`$F33B` (`CharMap+625`, `MirrorBuffer`) |
| Writes | `$9ED3`-`$9ED4` (`ColourSequences`); `$F2F0`-`$F33B` (`CharMap+624`, `MirrorBuffer`) |

### `KempstonTest` (`$9F62`)

**Z when port `$1F` reads with bits 5-7 clear 256 times (a Kempston interface)**

Witness: L1 5 (c1, play2, rzx-08000, rzx-28000).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 9,232 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/rzx-08000` 2, `stage2/rec/play2` 1, `stage1/rec/rzx-28000` 1) |
| Called from | `GameEntry`, `MenuLoop` |
| Ports in | `$001F`, `$301F` |

### `EnterPassword` (`$9F82`)

**ENTER PASSWORD: 16 keys, compared with the four passwords (key codes)**

Each matching password sets its flag; PETALS OF DOOM sets `$9F70` only when the other three are set (the AND at `$9FE9-$9FF2`). Witness: work/stage2/rec/play2 types the four passwords in order: each compare matches once, the four flags are written once each, and the next NewGame's PasswordPods `$ACBC` writes the open blocks `$1E`/`$1F` for all four doors (ACD1 run 4 times a call, ACC9 never). The flags let Matt into a door (MattWalk `$B48D-$B4BB`: room 0, screen 5, standing on character `$1C`, down held).

Witness: L1 5 (cheat, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage2/rec/play2` 4, `stage2/rec/cheat` 1) |
| Called from | `MenuLoop` (tail) |
| Calls | `MenuLoop` (tail), `ScreenAddr`, `PrintString`, `PrintChar`, `ClearMenuArea`, `StringMatch`, `WaitKey` |
| Reads | `$9F6D`-`$9F6F` (`PasswordFlags`) |
| Writes | `$9F6D`-`$9F7F` (`PasswordFlags`, `PasswordBuffer`) |

### `StringMatch` (`$A033`)

**Z when the buffer at HL equals the 0-terminated code string at DE**

Witness: L1 20 (cheat, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20 calls (`stage2/rec/play2` 16, `stage2/rec/cheat` 4) |
| Called from | `EnterPassword` |
| Reads | `$9F71`-`$9F7F` (`PasswordBuffer`); `$A009`-`$A032` (`Passwords`) |

### `ScreenWipe` (`$A040`)

**Close the screen from the top and the bottom, one line pair a HALT (88 steps)**

Witness: L1 21 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 358,866 t-states own (0.02 %) |
| Runs (the other recordings) | 20 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-24000` 2, `stage1/rec/rzx-32000` 2 and 11 more) |
| Called from | `MenuLoop` |
| Calls | `ClearLine` (falls into) |
| Reads | `$A04A` (`l_A049+1`) |

### `ClearLine` (`$A076`)

**Clear one pixel line**

Witness: L1 3717 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 177 calls, 173,460 t-states own (0.01 %) |
| Runs (the other recordings) | 3,540 calls (`stage2/rec/play2` 531, `stage1/rec/rzx-04000` 354, `stage1/rec/rzx-24000` 354 and 11 more) |
| Called from | `ScreenWipe` (falls into) |
| Writes | `$4000`-`$57BF` (screen) |

### `KeyPressed` (`$A090`)

**NZ when key code A is down (patches its own port and bit)**

Witness: L1 103894 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 10,808 calls, 1,822,305 t-states own (0.12 %) |
| Runs (the other recordings) | 93,086 calls (`stage1/rec/rzx-20000` 9,063, `stage1/rec/rzx-08000` 8,758, `stage1/rec/rzx-28000` 8,033 and 13 more) |
| Called from | `MenuLoop`, `l_A155` |
| Writes | `$A0AA`-`$A0AF` (`KeyPressed+26`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FEFE` |

### `ScanKeyboard` (`$A0B2`)

**The first key down as a key code, or none**

Witness: L1 34726 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 5,735 calls, 3,005,953 t-states own (0.19 %) |
| Runs (the other recordings) | 28,991 calls (`stage2/rec/play2` 17,862, `stage2/rec/cheat` 4,691, `stage1/rec/rzx-08000` 1,231 and 12 more) |
| Called from | `ReadKeyCode` |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `ReadKeyCode` (`$A0C9`)

**A key code from ScanKeyboard**

Witness: L1 34726 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 5,735 calls, 364,678 t-states own (0.02 %) |
| Runs (the other recordings) | 28,991 calls (`stage2/rec/play2` 17,862, `stage2/rec/cheat` 4,691, `stage1/rec/rzx-08000` 1,231 and 12 more) |
| Called from | `MenuLoop`, `WaitKey` |
| Calls | `ScanKeyboard` |

### `WaitKey` (`$A0E5`)

**Wait for a key: A the character, A' the key code**

Witness: L1 2470 (c1, cheat, play2).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 5 calls, 86,260 t-states own (0.01 %) |
| Runs (the other recordings) | 54 calls (`stage2/rec/play2` 42, `stage2/rec/cheat` 12) |
| Called from | `AskKey`, `EnterPassword` |
| Calls | `ReadKeyCode` |
| Reads | `$A0F2`-`$A117` (`KeyChars+1`) |

### `KeyCodeToChar` (`$A119`)

**A = the character of key code A**

Witness: L1 271 (c1, cheat, door, door3, play2, rzx- x5).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 212 calls (`stage1/rec/rzx-00000` 38, `stage1/rec/rzx-04000` 38, `stage1/rec/rzx-12000` 38 and 4 more) |
| Called from | `BuildMessage` |
| Reads | `$A0F5`-`$A117` (`KeyChars+4`) |

### `ReadControls` (`$A13B`)

**Controls from the Kempston port or the chosen keys; right beats left, down beats up**

Witness: L1 27243 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

[Animation: `ReadControls` at work](img/routines/ReadControls.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 4,433 calls, 787,998 t-states own (0.05 %) |
| Runs (the other recordings) | 22,810 calls (`stage2/rec/play2` 3,223, `stage1/rec/rzx-08000` 2,108, `stage1/rec/rzx-28000` 1,843 and 13 more) |
| Called from | `MenuLoop`, `GameStart` |
| Reads | `$A138`-`$A13A` (`Controls`, `ControlsLast`, `ControlMethod`); `$A150`-`$A154` (`KeysNow`) |
| Writes | `$A138`-`$A139` (`Controls`, `ControlsLast`) |
| Ports in | `$001F` |

### `l_A155` (`$A155`)

**l_A155**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,729 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 18,456 runs of its first instruction, entered by a jump (`stage1/rec/rzx-20000` 1,825, `stage1/rec/rzx-08000` 1,702, `stage1/rec/rzx-28000` 1,649 and 13 more) |
| Calls | `KeyPressed` |

## renderer

`src/game/renderer.asm`

### `SwapZone` (`$A198`)

**Make zone A live: swap its parked `$900` bytes with ZoneChars/ZoneAttrs, under DI**

Also writes TurretStems `$A1EC`[zone] into TurretStem `$C26E`. Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9); the per-frame trace of a room change is in work/stage2/NOTES.md.

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 28 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-12000` 10, `stage1/rec/rzx-32000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Reads | `$5B00`-`$75FF` (`Zone1CharsHigh`, `Zone1AttrsLeftover`, `Zone2Chars`, `Zone2Attrs` and 2 more); `$A194`-`$A197` (`ZoneSlots`); `$A1EC`-`$A1EF` (`TurretStems`); `$E000`-`$E7FF` (`ZoneChars`); `$EF00`-`$EFFF` (`ZoneAttrs`) |
| Writes | `$5B00`-`$75FF` (`Zone1CharsHigh`, `Zone1AttrsLeftover`, `Zone2Chars`, `Zone2Attrs` and 2 more); `$A194`-`$A197` (`ZoneSlots`); `$C26E` (`TurretStem`); `$E000`-`$E7FF` (`ZoneChars`); `$EF00`-`$EFFF` (`ZoneAttrs`) |

### `FlushDirty` (`$A1F0`)

**Draw every dirty cell (from `$F5FF` down to the sentinel `$F3BF`) and clear its mark**

Witness: L1 15472 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 71,676 t-states own (0.00 %) |
| Runs (the other recordings) | 13,843 calls (`stage1/rec/rzx-16000` 1,608, `stage1/rec/rzx-00000` 1,322, `stage1/rec/rzx-12000` 1,292 and 12 more) |
| Called from | `DrawObjects`, `DrawRoom`, `MattNoEnergy`, `Death`, `Explosion` |
| Calls | `l_A1FC` (falls into) |
| Writes | `$F3BF` (`MirrorBuffer+191`) |

### `l_A1FC` (`$A1FC`)

**l_A1FC**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 41,737,037 t-states own (2.64 %) |
| Runs (the other recordings) | 13,843 calls (`stage1/rec/rzx-16000` 1,608, `stage1/rec/rzx-00000` 1,322, `stage1/rec/rzx-12000` 1,292 and 12 more) |
| Called from | `FlushDirty` (falls into) |
| Reads | `$E000`-`$ECC7` (`ZoneChars`, `SpriteChars`); `$EE00`-`$EE98` (`Zone1Attrs`); `$EF00`-`$EFFF` (`ZoneAttrs`); `$F0C0`-`$F2FF` (`CharMap+64`); `$F3BF`-`$F5FF` (`MirrorBuffer+191`, `LeftoverF500`) |
| Writes | `$4000`-`$503F` (screen); `$5100`-`$513F` (screen); `$5200`-`$523F` (screen); `$5300`-`$533F` (screen); `$5400`-`$543F` (screen); `$5500`-`$553F` (screen); 4 more ranges |

### `DrawObjects` (`$A2D0`)

**The last step of a pass: place pick-ups, draw the 8 objects, flush, restore the backgrounds**

Witness: L1 15361 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

[Animation: `DrawObjects` at work](img/routines/DrawObjects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 14,412,816 t-states own (0.91 %) |
| Runs (the other recordings) | 13,732 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,309, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `Death`, `GameStart` |
| Calls | `FlushDirty`, `l_A307` (falls into), `SelectFrame`, `DrawObject`, `PlacePickups` |
| Reads | `$A253`-`$A2CF` (`PickupSaves`, `PickupSavePtr`, `NextSpriteChar`, `FirstSpriteChar` and 1 more); `$A43F`-`$A474` (`Objects`, `MattShot`); `$A48B`-`$A49A` (`Enemies`); `$A4B1`-`$A4C0` (`Enemies+38`); `$A4D7`-`$A4E6` (`Enemies+76`); `$A4FD`-`$A50C` (`Enemies+114`); 2 more ranges |
| Writes | `$A2CD` (`NextSpriteChar`); `$A442`-`$A46C` (`Objects+3`, `MattShot`); `$A492` (`Enemies+7`); `$A4B8` (`Enemies+45`); `$A4DE` (`Enemies+83`); `$A504` (`Enemies+121`); 9 more ranges |

### `l_A307` (`$A307`)

**l_A307**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 13,024 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,236 calls (`stage1/rec/rzx-12000` 10,236) |
| Called from | `DrawObjects` (falls into), `l_A33C` (tail) |
| Calls | `l_A33C` (falls into) |
| Reads | `$A253`-`$A2B9` (`PickupSaves`); `$A43F`-`$A474` (`Objects`, `MattShot`); `$A48B`-`$A49A` (`Enemies`); `$A4B1`-`$A4C0` (`Enemies+38`); `$A4D7`-`$A4E6` (`Enemies+76`); `$A4FD`-`$A50C` (`Enemies+114`); 2 more ranges |
| Writes | `$A446`-`$A46C` (`Objects+7`, `MattShot`); `$A492` (`Enemies+7`); `$A4B8` (`Enemies+45`); `$A4DE` (`Enemies+83`); `$A504` (`Enemies+121`); `$A52A` (`Enemies+159`); 2 more ranges |

### `l_A33C` (`$A33C`)

**l_A33C**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 13,024 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,237 calls (`stage1/rec/rzx-12000` 10,237) |
| Called from | `l_A307` (falls into) |
| Calls | `l_A307` (tail), `RestorePickups` (tail) |

### `SelectFrame` (`$A349`)

**The object's frame address from its mode (+`$19`), animation (+`$18`) and mask (+`$1A`); Matt's from his state and x**

Witness: L1 104259 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 11,406 calls, 756,434 t-states own (0.05 %) |
| Runs (the other recordings) | 92,853 calls (`stage1/rec/rzx-16000` 10,604, `stage1/rec/rzx-00000` 9,119, `stage1/rec/rzx-12000` 8,978 and 12 more) |
| Called from | `DrawObjects` |
| Calls | `Dissolve` (tail), `FrameByMode` (tail) |
| Reads | `$A2CF` (`DissolveCount`); `$A43F`-`$A442` (`Objects`); `$A458`-`$A47E` (`Objects+25`, `MattShot`); `$A4A4` (`Enemies+25`); `$A4CA` (`Enemies+63`); `$A4F0` (`Enemies+101`); 3 more ranges |
| Writes | `$A44B`-`$A44C` (`Objects+12`) |

### `Dissolve` (`$A3A5`)

**Copy a frame to `$DF80` through a random mask from R (the dissolve)**

Witness: L1 3404 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

[Animation: `Dissolve` at work](img/routines/Dissolve.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 107 calls, 614,943 t-states own (0.04 %) |
| Runs (the other recordings) | 3,297 calls (`stage1/rec/rzx-00000` 499, `stage2/rec/door3` 407, `stage2/rec/play2` 321 and 11 more) |
| Called from | `SelectFrame` (tail) |
| Calls | `Random` |
| Reads | `$A44B`-`$A44C` (`Objects+12`); `$CD60`-`$D25F` (`MattRun`, `MattJump`, `MattCrouch`); `$DF80`-`$DFFF` (`DissolveBuffer`) |
| Writes | `$A44B`-`$A44C` (`Objects+12`); `$DF80`-`$DFFF` (`DissolveBuffer`) |

### `FrameByMode` (`$A3E2`)

**FrameByMode**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 8 calls, 1,568 t-states own (0.00 %) |
| Runs (the other recordings) | 63,036 calls (`stage1/rec/rzx-16000` 9,004, `stage1/rec/rzx-12000` 7,698, `stage1/rec/rzx-04000` 6,574 and 11 more) |
| Called from | `SelectFrame` (tail) |
| Reads | `$A47B`-`$A47F` (`MattShot+22`); `$A4A1`-`$A4A5` (`Enemies+22`); `$A4C7`-`$A4CB` (`Enemies+60`); `$A4ED`-`$A4F1` (`Enemies+98`); `$A513`-`$A517` (`Enemies+136`); `$A539`-`$A53D` (`Enemies+174`); 1 more ranges |
| Writes | `$A3ED` (`l_A3EC+1`); `$A471`-`$A472` (`MattShot+12`); `$A497`-`$A498` (`Enemies+12`); `$A4BD`-`$A4BE` (`Enemies+50`); `$A4E3`-`$A4E4` (`Enemies+88`); `$A509`-`$A50A` (`Enemies+126`); 2 more ranges |

### `l_A3F2` (`$A3F2`)

**l_A3F2**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,016 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 3,853, `stage1/rec/rzx-04000` 2,812, `stage1/rec/rzx-20000` 1,684 and 7 more) |

### `l_A3F6` (`$A3F6`)

**l_A3F6**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 8 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 36,878 runs of its first instruction, entered by a jump (`stage1/rec/rzx-12000` 5,567, `stage1/rec/rzx-00000` 5,128, `stage1/rec/rzx-28000` 4,806 and 9 more) |

### `DrawObject` (`$A56F`)

**Draw object IX as fresh characters from `$E800`: copy backgrounds, mask, mirror, shift, OR in**

Witness: L1 104259 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 11,406 calls, 139,068,684 t-states own (8.79 %) |
| Runs (the other recordings) | 92,853 calls (`stage1/rec/rzx-16000` 10,604, `stage1/rec/rzx-00000` 9,119, `stage1/rec/rzx-12000` 8,978 and 12 more) |
| Called from | `DrawObjects`, `l_A62D` (tail) |
| Calls | `l_A62D` (falls into), `l_A655` (tail) |
| Reads | `$A2CB`-`$A2CD` (`PickupSavePtr`, `NextSpriteChar`); `$A441`-`$A56E` (`Objects+2`, `MattShot`, `Enemies`); `$CD60`-`$D39F` (`MattRun`, `MattJump`, `MattCrouch`, `SpriteFaller` and 1 more); `$D440`-`$D57F` (`SpriteExplosion`, `SpriteExplosion2`); `$D6E0`-`$E74F` (`SpriteShots`, `SpriteTurret`, `SpriteTurretShot`, `SpriteWave` and 12 more); `$E800`-`$ECA3` (`SpriteChars`); 9 more ranges |
| Writes | `$950A`-`$950D` (`RoomNumber`, `RoomRecord`, `RoomScreen`); `$A253`-`$A2CF` (`PickupSaves`, `PickupSavePtr`, `NextSpriteChar`, `FirstSpriteChar` and 1 more); `$A442`-`$A49E` (`Objects+3`, `MattShot`, `Enemies`); `$A4AF`-`$A4C4` (`Enemies+36`); `$A4D5`-`$A4EA` (`Enemies+74`); `$A4FB`-`$A510` (`Enemies+112`); 9 more ranges |

### `l_A62D` (`$A62D`)

**l_A62D**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 128,718 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 122,435 calls (`stage1/rec/rzx-16000` 122,435) |
| Called from | `DrawObject` (falls into), `l_A655` (tail) |
| Calls | `DrawObject` (tail), `l_A66C` (tail) |
| Reads | `$A446`-`$A49E` (`Objects+7`, `MattShot`, `Enemies`); `$A4AF`-`$A4C4` (`Enemies+36`); `$A4D5`-`$A4EA` (`Enemies+74`); `$A4FB`-`$A510` (`Enemies+112`); `$A521`-`$A536` (`Enemies+150`); `$A547`-`$A55C` (`Enemies+188`); 1 more ranges |
| Writes | `$A2CB`-`$A2CD` (`PickupSavePtr`, `NextSpriteChar`); `$A446`-`$A49E` (`Objects+7`, `MattShot`, `Enemies`); `$A4AF`-`$A4C4` (`Enemies+36`); `$A4D5`-`$A4EA` (`Enemies+74`); `$A4FB`-`$A510` (`Enemies+112`); `$A521`-`$A536` (`Enemies+150`); 2 more ranges |

### `l_A655` (`$A655`)

**l_A655**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 89,147 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 73,994 calls (`stage1/rec/rzx-16000` 73,994) |
| Called from | `DrawObject` (tail) |
| Calls | `l_A62D` (tail) |

### `l_A66C` (`$A66C`)

**l_A66C**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 11,406 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,604 calls (`stage1/rec/rzx-16000` 10,604) |
| Called from | `l_A62D` (tail) |
| Calls | `MakeMask`, `MirrorFrame` |
| Reads | `$A441`-`$A472` (`Objects+2`, `MattShot`); `$A48D`-`$A498` (`Enemies+2`); `$A4B3`-`$A4BE` (`Enemies+40`); `$A4D9`-`$A4E4` (`Enemies+78`); `$A4FF`-`$A50A` (`Enemies+116`); `$A525`-`$A530` (`Enemies+154`); 16 more ranges |
| Writes | `$A446`-`$A46D` (`Objects+7`, `MattShot`); `$A492`-`$A493` (`Enemies+7`); `$A4B8`-`$A4B9` (`Enemies+45`); `$A4DE`-`$A4DF` (`Enemies+83`); `$A504`-`$A505` (`Enemies+121`); `$A52A`-`$A52B` (`Enemies+159`); 2 more ranges |

### `MakeMask` (`$A777`)

**The frame's mask, each byte dilated through the table `$F700`, into `$F000`**

Witness: L1 104260 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 11,406 calls, 34,694,467 t-states own (2.19 %) |
| Runs (the other recordings) | 92,854 calls (`stage1/rec/rzx-16000` 10,604, `stage1/rec/rzx-00000` 9,119, `stage1/rec/rzx-12000` 8,978 and 12 more) |
| Called from | `l_A66C` |
| Reads | `$A444`-`$A472` (`Objects+5`, `MattShot`); `$A490`-`$A498` (`Enemies+5`); `$A4B6`-`$A4BE` (`Enemies+43`); `$A4DC`-`$A4E4` (`Enemies+81`); `$A502`-`$A50A` (`Enemies+119`); `$A528`-`$A530` (`Enemies+157`); 6 more ranges |
| Writes | `$F000`-`$F0BF` (`Zone1CharsLow`, `CharMap`) |

### `MirrorFrame` (`$A7F3`)

**The frame mirrored through the bit-reverse table `$F600` into `$F300`**

Witness: L1 9519 (c1, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 208 calls, 992,880 t-states own (0.06 %) |
| Runs (the other recordings) | 9,311 calls (`stage1/rec/rzx-28000` 2,616, `stage1/rec/rzx-12000` 1,174, `stage1/rec/rzx-00000` 1,063 and 6 more) |
| Called from | `l_A66C` |
| Reads | `$A444`-`$A44C` (`Objects+5`); `$A490`-`$A498` (`Enemies+5`); `$A4B6`-`$A4BE` (`Enemies+43`); `$A4DC`-`$A4E4` (`Enemies+81`); `$A502`-`$A50A` (`Enemies+119`); `$A528`-`$A530` (`Enemies+157`); 4 more ranges |
| Writes | `$A44B`-`$A44C` (`Objects+12`); `$A497`-`$A498` (`Enemies+12`); `$A4BD`-`$A4BE` (`Enemies+50`); `$A4E3`-`$A4E4` (`Enemies+88`); `$A509`-`$A50A` (`Enemies+126`); `$A52F`-`$A530` (`Enemies+164`); 3 more ranges |

### `BuildTables` (`$A860`)

**Build the dilate table `$F700`, the shift tables `$F800-$FDFF` and the bit-reverse table `$F600`**

Witness: L1 21 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 140,114 t-states own (0.01 %) |
| Runs (the other recordings) | 20 calls (`stage2/rec/play2` 3, `stage2/rec/door3` 2, `stage1/rec/rzx-04000` 2 and 11 more) |
| Called from | `NewGame` |
| Writes | `$F600`-`$FDFF` (`PlayPanel`, `LeftoverFC00`, `PanelAttrs`, `LeftoverFD24`) |

### `Twinkle` (`$C9EA`)

**One line in each of 8 characters from `$E710` (chars `$E2-$E9`; from `$E728`, chars `$E5-$EC`, in zone 3) set to `$FF` or 0 in turn (TwinkleSteps)**

Witness: L1 15361 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 2,414,583 t-states own (0.15 %) |
| Runs (the other recordings) | 13,732 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,309, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `AnimateZone` (tail), `AnimateZone1` (tail), `l_CBBB` (tail) |
| Reads | `$A194` (`ZoneSlots`); `$CA35`-`$CA3C` (`TwinkleSteps`) |
| Writes | `$CA30`-`$CA3C` (`l_CA2A+6`, `TwinkleSteps`); `$E710`-`$E766` (`ZoneChars+1808`) |

### `AnimateLift` (`$CA3D`)

**Zone 0: move the lift (characters `$69` / `$6B`) up and down its shaft**

Witness: L1 15361 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 57,015 t-states own (0.00 %) |
| Runs (the other recordings) | 13,732 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,309, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `AnimateZone` |
| Reads | `$AA72`-`$AA74` (`LiftPlace`); `$F227`-`$F238` (`CharMap+423`) |
| Writes | `$AA72`-`$AA74` (`LiftPlace`); `$F228`-`$F237` (`CharMap+424`); `$F248`-`$F257` (`CharMap+456`); `$F528`-`$F537` (`LeftoverF500+40`); `$F548`-`$F557` (`LeftoverF500+72`) |

### `MarkAnimated` (`$CAAD`)

**Mark every AnimatedCells cell dirty**

Witness: L1 15361 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 100,998 t-states own (0.01 %) |
| Runs (the other recordings) | 13,732 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,309, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `AnimateZone` |
| Reads | `$AAA1`-`$AAE2` (`AnimatedCells`) |
| Writes | `$F3C3`-`$F3FC` (`DirtyMap+3`); `$F441`-`$F442` (`DirtyMap+129`); `$F45B`-`$F45E` (`DirtyMap+155`); `$F481`-`$F482` (`DirtyMap+193`); `$F499`-`$F53F` (`DirtyMap+217`, `LeftoverF500`); `$F551`-`$F55A` (`LeftoverF500+81`); 1 more ranges |

### `AnimateZone` (`$CACD`)

**Each pass: copy the zone's next animation frames into its live characters, the lift, the twinkle**

Witness: L1 15361 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

[Animation: `AnimateZone` at work](img/routines/AnimateZone.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 4,028,187 t-states own (0.25 %) |
| Runs (the other recordings) | 13,732 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,309, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `Death`, `GameStart` |
| Calls | `Twinkle` (tail), `AnimateLift`, `MarkAnimated` |
| Reads | `$A194` (`ZoneSlots`); `$CABD`-`$CAC5` (`AnimSteps`); `$CB41` (`AnimLast`); `$E210`-`$E2CF` (`ZoneChars+528`); `$E400`-`$E4FF` (`ZoneChars+1024`); `$E560`-`$E6FF` (`ZoneChars+1376`); 1 more ranges |
| Writes | `$CABD`-`$CABF` (`AnimSteps`); `$CB41` (`AnimLast`); `$E288`-`$E297` (`ZoneChars+648`); `$E300`-`$E31F` (`ZoneChars+768`); `$E388`-`$E397` (`ZoneChars+904`); `$E4E0`-`$E4EF` (`ZoneChars+1248`); 5 more ranges |

### `AnimateZone1` (`$CB42`)

**AnimateZone1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,740 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-12000` 1,080, `stage1/rec/rzx-00000` 617 and 5 more) |
| Calls | `Random`, `Twinkle` (tail), `l_CBBB` (tail) |

### `l_CBBB` (`$CBBB`)

**l_CBBB**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,669 calls (`stage1/rec/rzx-00000` 617, `stage2/rec/door3` 360, `stage1/rec/rzx-32000` 311 and 2 more) |
| Called from | `AnimateZone1` (tail) |
| Calls | `Twinkle` (tail) |
| Reads | `$CABE`-`$CACC` (`AnimSteps+1`); `$E3A0`-`$E3BF` (`ZoneChars+928`); `$E580`-`$E6FF` (`ZoneChars+1408`) |
| Writes | `$E360`-`$E367` (`ZoneChars+864`); `$E700`-`$E71F` (`ZoneChars+1792`) |

## objects

`src/game/objects.asm`

### `RoomMessage` (`$AD28`)

**Screen 0 messages: room 0 GOOD LUCK MATT; rooms 3, 7, 10, 11 CODE BROKEN and a password**

Room 11 shows MAYHEM, 3 TRANSMOGRIFY, 7 VALKYR, 10 PETALS OF DOOM, built by BuildMessage `$ADBF` and scrolled by ShowMessage `$B0FF`.

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 59 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-12000` 10, `stage1/rec/rzx-32000` 10 and 12 more) |
| Called from | `DrawRoom` (tail) |
| Calls | `BuildMessage`, `ShowMessage` (tail) |
| Reads | `$950A`-`$950D` (`RoomNumber`, `RoomRecord`, `RoomScreen`) |

### `BuildMessage` (`$ADBF`)

**Copy the password text after PASSWORD IS**

Witness: L1 23 (door, door3, rzx- x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage1/rec/rzx-00000` 4, `stage1/rec/rzx-04000` 4, `stage1/rec/rzx-12000` 4 and 4 more) |
| Called from | `RoomMessage` |
| Calls | `KeyCodeToChar` |
| Reads | `$A009`-`$A032` (`Passwords`); `$ADB4`-`$ADBC` (`Messages+56`) |
| Writes | `$ADAF`-`$ADBC` (`Messages+51`) |

### `MoonMasks` (`$ADD2`)

**Zone 2: every PENETRATOR (kind 1) slot becomes EMPTY**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 31 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-12000` 10, `stage1/rec/rzx-32000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Calls | `DrawAllSlots` (tail) |
| Reads | `$A194` (`ZoneSlots`); `$AF2C`-`$AF38` (`MaskSlots+1`) |

### `Ending` (`$ADF6`)

**Room 15, screen 5: YOU HAVE FOUND SCOTT, WELL DONE, then GameStart**

Jumps to GameStart without the high-score test of GameOver: the score of a won game is not kept (rzx-36000: 31 004 points, then the menu shows HISCORE 00000000).

Witness: L1 1 (play2).

[Animation: `Ending` at work](img/routines/Ending.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/play2` 1) |
| Called from | `DrawRoom` (tail) |
| Calls | `PrintChar`, `SlowPrint`, `GameStart` (tail) |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |

### `AddScore` (`$AE45`)

**Score + DE (BCD)**

Witness: L1 84 (kind6, rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 84 calls (`stage1/rec/rzx-16000` 18, `stage1/rec/rzx-12000` 17, `stage1/rec/rzx-04000` 10 and 7 more) |
| Called from | `AwardScore` (tail) |
| Reads | `$AE41`-`$AE44` (`Score`) |
| Writes | `$AE41`-`$AE44` (`Score`) |

### `DrawScore` (`$AE60`)

**The score's eight digits (Digits `$D3A0`) at `$5077`**

Witness: L1 15175 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

[Animation: `DrawScore` at work](img/routines/DrawScore.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 594,737 t-states own (0.04 %) |
| Runs (the other recordings) | 13,546 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `GameStart` |
| Calls | `DrawDigit` |
| Reads | `$AE41`-`$AE44` (`Score`) |

### `DrawDigit` (`$AE78`)

**One digit**

Witness: L1 121401 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 13,032 calls, 8,857,217 t-states own (0.56 %) |
| Runs (the other recordings) | 108,369 calls (`stage1/rec/rzx-16000` 12,800, `stage1/rec/rzx-00000` 10,480, `stage1/rec/rzx-12000` 10,240 and 12 more) |
| Called from | `DrawScore` |
| Reads | `$D3A0`-`$D43F` (`Digits`) |
| Writes | `$5077`-`$509E` (screen); `$5177`-`$519E` (screen); `$5277`-`$527E` (screen); `$5297`-`$529E` (screen); `$5377`-`$537E` (screen); `$5397`-`$539E` (screen); 8 more ranges |

### `DrawEnergyBar` (`$AEA8`)

**The 8-cell energy bar at `$506D`, partial cells from EnergyParts**

Witness: L1 15170 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 104,664 t-states own (0.01 %) |
| Runs (the other recordings) | 13,541 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `GameStart` |
| Calls | `FillCell` |
| Reads | `$AEA6`-`$AEA7` (`Energy`, `EnergyShown`); `$AF04`-`$AF0B` (`EnergyParts`) |
| Writes | `$AEA7` (`EnergyShown`) |

### `FillCell` (`$AEE5`)

**Fill a cell's three lines with C**

Witness: L1 1360 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 8 calls, 3,514 t-states own (0.00 %) |
| Runs (the other recordings) | 1,352 calls (`stage1/rec/rzx-16000` 504, `stage1/rec/rzx-20000` 216, `stage2/rec/door` 112 and 12 more) |
| Called from | `DrawEnergyBar` |
| Writes | `$506D`-`$5074` (screen); `$508D`-`$5094` (screen); `$50AD`-`$50B4` (screen); `$516D`-`$5174` (screen); `$518D`-`$5194` (screen); `$51AD`-`$51B4` (screen); 18 more ranges |

### `DrawCurrentSlot` (`$AF53`)

**Blink the slot in use and redraw its charges**

Witness: L1 15390 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,639 calls, 224,600 t-states own (0.01 %) |
| Runs (the other recordings) | 13,751 calls (`stage1/rec/rzx-16000` 1,628, `stage1/rec/rzx-00000` 1,340, `stage1/rec/rzx-12000` 1,294 and 12 more) |
| Called from | `DrawAllSlots`, `MaskKeys`, `GameStart` |
| Calls | `PrintBcd` (falls into), `DrawIcon` |
| Reads | `$AF2B`-`$AF39` (`MaskSlots`); `$AF51`-`$AF52` (`CurrentSlot`) |

### `PrintBcd` (`$AF6B`)

**Print the BCD bytes at HL; its only caller is the menu's HISCORE (`$9D35`), the score in play is DrawScore `$AE60`**

Witness: L1 15546 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,647 calls, 88,995 t-states own (0.01 %) |
| Runs (the other recordings) | 10,931 calls (`stage1/rec/rzx-12000` 1,298, `stage1/rec/rzx-20000` 1,112, `stage1/rec/rzx-04000` 1,068 and 11 more) |
| Called from | `DrawMenu`, `DrawCurrentSlot` (falls into) |
| Calls | `PrintBcdByte` (falls into) |

### `PrintBcdByte` (`$AF74`)

**Two digits**

Witness: L1 31091 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,294 calls, 102,152 t-states own (0.01 %) |
| Runs (the other recordings) | 27,797 calls (`stage1/rec/rzx-16000` 3,256, `stage1/rec/rzx-00000` 2,679, `stage1/rec/rzx-12000` 2,596 and 13 more) |
| Called from | `PrintBcd` (falls into) |
| Calls | `PrintChar` (tail) |

### `Scroller` (`$AF82`)

**Interrupt: scroll the message line (row 23) one step**

Witness: L1 45122 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,955 calls, 1,822,607 t-states own (0.12 %) |
| Runs (the other recordings) | 41,071 calls (`stage1/rec/rzx-16000` 3,999, `stage1/rec/rzx-12000` 3,710, `stage1/rec/rzx-00000` 3,654 and 13 more) |
| Called from | `Interrupt` |
| Calls | `ScrollerNextChar` |
| Reads | `$51E1`-`$51EB` (screen); `$52E1`-`$52EB` (screen); `$53E1`-`$53EB` (screen); `$54E1`-`$54EB` (screen); `$55E1`-`$55EB` (screen); `$56E1`-`$56EB` (screen); 2 more ranges |
| Writes | `$51E1`-`$51EB` (screen); `$52E1`-`$52EB` (screen); `$53E1`-`$53EB` (screen); `$54E1`-`$54EB` (screen); `$55E1`-`$55EB` (screen); `$56E1`-`$56EB` (screen); 1 more ranges |

### `ScrollerNextChar` (`$AFE0`)

**The next character's glyph into `$AF15`**

Witness: L1 2728 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 120 calls, 26,400 t-states own (0.00 %) |
| Runs (the other recordings) | 2,608 calls (`stage2/rec/play2` 323, `stage2/rec/door3` 298, `stage1/rec/rzx-32000` 235 and 12 more) |
| Called from | `Scroller` |
| Calls | `CharGlyph` |
| Reads | `$95FB`-`$9677` (`Font`); `$96AF`-`$96BD` (`Font+180`); `$AD7C`-`$ADBC` (`Messages`); `$AF0F`-`$AF11` (`ScrollerLeft`, `ScrollerPtr`); `$B197`-`$B1FA` (`MaskNames`) |
| Writes | `$AF0F`-`$AF19` (`ScrollerLeft`, `ScrollerPtr`, `ScrollerShift`) |

### `DrawAllSlots` (`$AFFA`)

**The four slots' icons and charges**

Witness: L1 38 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 calls, 1,150 t-states own (0.00 %) |
| Runs (the other recordings) | 36 calls (`stage1/rec/rzx-00000` 6, `stage1/rec/rzx-28000` 5, `stage2/rec/door3` 4 and 12 more) |
| Called from | `NewGame`, `MoonMasks` (tail), `CheckPickups`, `WarpBonus` (tail) |
| Calls | `DrawCurrentSlot` |
| Reads | `$AF0C` (`PassCounter`); `$AF51`-`$AF52` (`CurrentSlot`) |
| Writes | `$AF0C` (`PassCounter`); `$AF51`-`$AF52` (`CurrentSlot`) |

### `DrawIcon` (`$B024`)

**A mask icon (MaskIcons `$D580` + 32 x kind) at slot IX**

While PassCounter bit 3 is set the current slot gets icon 0 (EMPTY, 32 zero bytes, a blank): the blink of the slot in use.

Witness: L1 15390 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,639 calls, 2,159,694 t-states own (0.14 %) |
| Runs (the other recordings) | 13,751 calls (`stage1/rec/rzx-16000` 1,628, `stage1/rec/rzx-00000` 1,340, `stage1/rec/rzx-12000` 1,294 and 12 more) |
| Called from | `DrawCurrentSlot` |
| Reads | `$AF0C` (`PassCounter`); `$AF46`-`$AF50` (`MaskColours`); `$D580`-`$D6DF` (`MaskIcons`) |
| Writes | `$5061`-`$506B` (screen); `$5081`-`$508B` (screen); `$5161`-`$516B` (screen); `$5181`-`$518B` (screen); `$5261`-`$526B` (screen); `$5281`-`$528B` (screen); 12 more ranges |

### `MaskKeys` (`$B089`)

**Keys 1-4 (port `$F7FE`) choose the slot, not while dying**

Witness: L1 15175 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 109,687 t-states own (0.01 %) |
| Runs (the other recordings) | 13,546 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `GameStart` |
| Calls | `DrawCurrentSlot`, `ShowMaskName` (falls into), `EndPenetrator` |
| Reads | `$AF0E` (`MaskNameShown`); `$AF2C`-`$AF38` (`MaskSlots+1`); `$BAA7` (`Dying`) |
| Writes | `$AF0C`-`$AF0E` (`PassCounter`, `MaskNameShown`); `$AF51`-`$AF52` (`CurrentSlot`); `$B0FE` (`MessageState+3`) |
| Ports in | `$F7FE` |

### `ShowMaskName` (`$B0CE`)

**Scroll the name of mask kind A**

Witness: L1 79 (c1, door3, masks, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3 calls, 210 t-states own (0.00 %) |
| Runs (the other recordings) | 50 calls (`stage1/rec/rzx-16000` 21, `stage1/rec/rzx-00000` 9, `stage1/rec/rzx-32000` 9 and 4 more) |
| Called from | `MaskKeys` (falls into), `ShowNameKeep`, `UseCharge`, `ShowLifterName` |
| Calls | `l_B0EA` (falls into) |
| Reads | `$AF0E`-`$AF12` (`MaskNameShown`, `ScrollerLeft`, `ScrollerPtr`, `ScrollerShift`) |
| Writes | `$AF0E`-`$AF12` (`MaskNameShown`, `ScrollerLeft`, `ScrollerPtr`, `ScrollerShift`); `$B0FE` (`MessageState+3`) |

### `l_B0EA` (`$B0EA`)

**l_B0EA**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 calls, 138 t-states own (0.00 %) |
| Runs (the other recordings) | 46 calls (`stage1/rec/rzx-00000` 7, `stage1/rec/rzx-32000` 7, `stage1/rec/rzx-12000` 6 and 7 more) |
| Called from | `ShowMaskName` (falls into), `ShowMessage` (tail) |
| Reads | `$AF12` (`ScrollerShift`) |
| Writes | `$AF0F`-`$AF12` (`ScrollerLeft`, `ScrollerPtr`, `ScrollerShift`) |

### `ShowMessage` (`$B0FF`)

**Start scrolling the message at HL**

Witness: L1 25 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 904 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage2/rec/door3` 3, `stage2/rec/play2` 3, `stage2/rec/door` 2 and 11 more) |
| Called from | `RoomMessage` (tail) |
| Calls | `l_B0EA` (tail) |
| Reads | `$AD7C`-`$ADBC` (`Messages`); `$AF12` (`ScrollerShift`) |
| Writes | `$AF0E`-`$AF12` (`MaskNameShown`, `ScrollerLeft`, `ScrollerPtr`, `ScrollerShift`); `$B0FB`-`$B0FE` (`MessageState`) |

### `CheckPickupsDown` (`$B11B`)

**Matt pressing down (state 4) takes the pick-up under him**

Witness: L1 1254 (c1, door, door3, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 12 calls, 540 t-states own (0.00 %) |
| Runs (the other recordings) | 1,242 calls (`stage1/rec/rzx-20000` 230, `stage1/rec/rzx-12000` 167, `stage1/rec/rzx-04000` 149 and 9 more) |
| Called from | `MattCrouchState` (tail) |
| Calls | `CheckPickups` (falls into) |

### `CheckPickups` (`$B126`)

**Take the mask at Matt's place into a slot with 99 charges and its kind's level**

The slot: the current one if EMPTY (its name shown), else the first EMPTY slot, else the current one, whose mask is replaced (there is no test for a slot of the same kind: rzx-16000 frame 49, BLASTER replaced by HEALER).

Witness: L1 2508 (c1, door, door3, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 24 calls, 2,390 t-states own (0.00 %) |
| Runs (the other recordings) | 2,484 calls (`stage1/rec/rzx-20000` 460, `stage1/rec/rzx-12000` 334, `stage1/rec/rzx-04000` 298 and 9 more) |
| Called from | `CheckPickupsDown` (falls into) |
| Calls | `DrawAllSlots`, `FindEmptySlot`, `ShowNameKeep` |
| Reads | `$950D`-`$9532` (`RoomScreen`, `PickupTable`); `$A442` (`Objects+3`); `$AF1C`-`$AF52` (`PickupRecords+1`, `MaskSlots`, `MaskLevels`, `MaskColours` and 1 more) |
| Writes | `$950E`-`$9532` (`PickupTable`); `$AF1C`-`$AF3A` (`PickupRecords+1`, `MaskSlots`) |

### `FindEmptySlot` (`$B174`)

**The first EMPTY slot**

Witness: L1 5 (rzx-00000, rzx-16000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/rzx-00000` 3, `stage1/rec/rzx-16000` 2) |
| Called from | `CheckPickups` |
| Reads | `$AF2C`-`$AF38` (`MaskSlots+1`); `$AF51`-`$AF52` (`CurrentSlot`) |

### `ShowNameKeep` (`$B18E`)

**ShowMaskName keeping AF and BC**

Witness: L1 7 (c1, rzx- x5).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 73 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/rec/rzx-00000` 2, `stage1/rec/rzx-08000` 1, `stage1/rec/rzx-24000` 1 and 2 more) |
| Called from | `CheckPickups` |
| Calls | `ShowMaskName` |

### `UseCharge` (`$B210`)

**Take A charges (BCD) from the slot in use; at none it becomes EMPTY; carry when there were not enough**

Witness: L1 649 (c1, cheat, door3, masks, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 5 calls, 695 t-states own (0.00 %) |
| Runs (the other recordings) | 644 calls (`stage1/rec/rzx-00000` 217, `stage1/rec/rzx-16000` 156, `stage1/rec/rzx-20000` 53 and 9 more) |
| Called from | `MattLongJump`, `FireMask`, `HeldMasks` (tail), `Penetrator` |
| Calls | `ShowMaskName` |
| Reads | `$AF2D`-`$AF39` (`MaskSlots+2`); `$AF51`-`$AF52` (`CurrentSlot`); `$BB77` (`CheatOn`) |
| Writes | `$AF2C`-`$AF39` (`MaskSlots+1`) |

### `MaskEffect` (`$B239`)

**Never run: ULTRA FLASH flashes the border, HEALER gives 1 energy a charge**

Known only from the code: no instruction calls `$B239`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlacePickups` (`$B276`)

**Draw the pick-up icons into the character map, keeping the backgrounds**

Witness: L1 15361 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 149,906 t-states own (0.01 %) |
| Runs (the other recordings) | 13,732 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,309, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `DrawObjects` |
| Calls | `PlaceOnePickup` (falls into) |
| Writes | `$A2CB`-`$A2CC` (`PickupSavePtr`) |

### `PlaceOnePickup` (`$B28B`)

**One icon**

Witness: L1 46083 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 4,887 calls, 1,063,064 t-states own (0.07 %) |
| Runs (the other recordings) | 41,196 calls (`stage1/rec/rzx-16000` 4,800, `stage1/rec/rzx-00000` 3,927, `stage1/rec/rzx-12000` 3,840 and 12 more) |
| Called from | `PlacePickups` (falls into) |
| Reads | `$AF1C`-`$AF2A` (`PickupRecords+1`); `$F1CC`-`$F1DD` (`CharMap+332`); `$F24C`-`$F257` (`CharMap+460`); `$F26C`-`$F277` (`CharMap+492`) |
| Writes | `$A253`-`$A25E` (`PickupSaves`); `$F1CC`-`$F1FD` (`CharMap+332`); `$F24C`-`$F257` (`CharMap+460`); `$F26C`-`$F277` (`CharMap+492`); `$F4CC`-`$F4FD` (`DirtyMap+268`); `$F54C`-`$F557` (`LeftoverF500+76`); 1 more ranges |

### `RestorePickups` (`$B2C5`)

**The backgrounds back**

Witness: L1 15357 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,628 calls, 89,597 t-states own (0.01 %) |
| Runs (the other recordings) | 13,729 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,309, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `l_A33C` (tail) |
| Calls | `RestoreOnePickup` (falls into) |

### `RestoreOnePickup` (`$B2D3`)

**One**

Witness: L1 30714 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3,256 calls, 529,575 t-states own (0.03 %) |
| Runs (the other recordings) | 27,458 calls (`stage1/rec/rzx-16000` 3,200, `stage1/rec/rzx-00000` 2,618, `stage1/rec/rzx-12000` 2,560 and 12 more) |
| Called from | `RestorePickups` (falls into) |
| Reads | `$A253`-`$A25A` (`PickupSaves`); `$AF1C`-`$AF27` (`PickupRecords+1`) |
| Writes | `$F1CC`-`$F1FD` (`CharMap+332`); `$F24C`-`$F257` (`CharMap+460`); `$F26C`-`$F277` (`CharMap+492`) |

### `Hazards` (`$B2F1`)

**The deadly floor and the items under Matt**

Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 71,695 t-states own (0.00 %) |
| Runs (the other recordings) | 13,549 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `GameStart` |
| Calls | `DeadlyFloor`, `TakeBlockItem` |

### `DeadlyFloor` (`$B2F9`)

**Matt on character `$EA` (`$ED` in zone 3) dies**

Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 309,624 t-states own (0.02 %) |
| Runs (the other recordings) | 13,549 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `Hazards` |
| Calls | `MoonFloor` |
| Reads | `$A194` (`ZoneSlots`); `$B3E8`-`$B3E9` (`MattPlace+2`); `$BB77` (`CheatOn`); `$F140`-`$F2DF` (`CharMap+192`); `$F4E3`-`$F4E4` (`DirtyMap+291`); `$F503`-`$F504` (`LeftoverF500+3`); 1 more ranges |
| Writes | `$B2F8` (`DeathFlag`) |

### `MoonFloor` (`$B32C`)

**Zone 2: the character under Matt from `$FE` up kills**

Witness: L1 522 (door3, rzx-28000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 522 calls (`stage2/rec/door3` 360, `stage1/rec/rzx-28000` 162) |
| Called from | `DeadlyFloor` |
| Reads | `$B3E8`-`$B3E9` (`MattPlace+2`); `$F140`-`$F144` (`CharMap+192`); `$F15C`-`$F166` (`CharMap+220`); `$F17B`-`$F22D` (`CharMap+251`); `$F242`-`$F24D` (`CharMap+450`); `$F263`-`$F26D` (`CharMap+483`); 3 more ranges |
| Writes | `$B2F8` (`DeathFlag`) |

### `TakeBlockItem` (`$B33D`)

**A block-`$1B` item touched: block `$47` in the map, an object, energy - `$19`**

The y test has only one bound (Matt's y + 20 at least the item's y). No recording took an item: the effect is known only from the code.

Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 697,326 t-states own (0.04 %) |
| Runs (the other recordings) | 13,549 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `Hazards` |
| Calls | `Explode` |
| Reads | `$A442`-`$A443` (`Objects+3`); `$A48B` (`Enemies`); `$A4B1` (`Enemies+38`); `$A4D7` (`Enemies+76`); `$A4FD` (`Enemies+114`); `$A523` (`Enemies+152`); 4 more ranges |
| Writes | `$7931` (`Room3Map+97`); `$A48E`-`$A48F` (`Enemies+3`); `$A4A6`-`$A4A7` (`Enemies+27`); `$A54C`-`$A54D` (`Enemies+193`); `$A564`-`$A565` (`Enemies+217`); `$ACDA` (`BlockItems`); 3 more ranges |

### `ShotHits` (`$BC96`)

**Z when Matt's shot overlaps object IX (not an explosion, not kind 10); +`$22` = the shot's power**

Witness: L1 91060 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 9,774 calls, 452,148 t-states own (0.03 %) |
| Runs (the other recordings) | 81,286 calls (`stage1/rec/rzx-16000` 9,600, `stage1/rec/rzx-00000` 7,860, `stage1/rec/rzx-12000` 7,680 and 12 more) |
| Called from | `RunObjects` |
| Reads | `$A465`-`$A469` (`MattShot`); `$A487`-`$A491` (`MattShot+34`, `Enemies`); `$A4B1`-`$A4B7` (`Enemies+38`); `$A4D7`-`$A4DD` (`Enemies+76`); `$A4FD`-`$A503` (`Enemies+114`); `$A523`-`$A529` (`Enemies+152`); 1 more ranges |
| Writes | `$A4AD` (`Enemies+34`); `$A4D3` (`Enemies+72`); `$A4F9` (`Enemies+110`); `$A51F` (`Enemies+148`); `$A545` (`Enemies+186`); `$A56B` (`Enemies+224`) |

### `FireMask` (`$BCE0`)

**Fire with the mask in use: kinds 1-4 while fire is held, kinds 5-10 shoot on a new press**

Kind 1 PENETRATOR: PenetratorOn, Matt dissolves and walks through walls, a charge every second pass (`$BE0E`). Kinds 2 ULTRA FLASH and 3 MIRAGE: RET (`$BE39`, `$BE3A`), nothing happens. Kind 4 HEALER: Energy + 2 for a charge. Kinds 5-10 fire Matt's shot (MattShot `$A465`, picture `$D6E0`, animation kind - 5, effect kind - 5, power = the slot's level) for a charge, LIFTER 8 charges; LIFTER's shot sets +`$22` = `$FF`. JACKRABBIT also jumps far (MattLongJump).

Witness: L1 15176 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

[Animation: `FireMask` at work, lifter](img/routines/FireMask-lifter.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 235,196 t-states own (0.01 %) |
| Runs (the other recordings) | 13,547 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `GameStart` |
| Calls | `PlayEffect`, `UseCharge`, `HeldMasks` (tail), `EndPenetrator` (tail) |
| Reads | `$A138`-`$A139` (`Controls`, `ControlsLast`); `$A43F`-`$A443` (`Objects`); `$A465` (`MattShot`); `$AF2C`-`$AF3A` (`MaskSlots+1`); `$AF51`-`$AF52` (`CurrentSlot`); `$BAA7` (`Dying`) |
| Writes | `$A465`-`$A469` (`MattShot`); `$A47B`-`$A487` (`MattShot+22`) |

### `ShotOff` (`$BD7F`)

**Matt's shot gone**

Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 27 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/rzx-00000` 13, `stage1/rec/rzx-12000` 10, `stage1/rec/rzx-32000` 10 and 12 more) |
| Called from | `DrawRoom` |
| Writes | `$A465` (`MattShot`) |

### `MoveShot` (`$BD84`)

**Matt's shot: x + dx; gone off `$38-$C3` or in a wall**

Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 219,101 t-states own (0.01 %) |
| Runs (the other recordings) | 13,549 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `GameStart` |
| Calls | `HitsWall` |
| Reads | `$A468` (`MattShot+3`); `$A480` (`MattShot+27`) |
| Writes | `$A465`-`$A468` (`MattShot`) |

### `HeldMasks` (`$BDA4`)

**HeldMasks**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,418 calls (`stage1/rec/rzx-16000` 381, `stage1/rec/rzx-28000` 360, `stage1/rec/rzx-00000` 342 and 2 more) |
| Called from | `FireMask` (tail) |
| Calls | `UseCharge` (tail), `EndPenetrator` (tail), `Penetrator` (tail), `UltraFlash` (tail), `Mirage` (tail) |
| Reads | `$A138` (`Controls`); `$A2CF` (`DissolveCount`); `$AEA6` (`Energy`); `$AF2C`-`$AF38` (`MaskSlots+1`); `$B3E8`-`$B3EA` (`MattPlace+2`, `PenetratorOn`); `$BE0D` (`PenetratorCost`); 1 more ranges |
| Writes | `$946C` (`EffectStops`); `$A2CF` (`DissolveCount`); `$AEA6` (`Energy`); `$B3EA` (`PenetratorOn`); `$BE0D` (`PenetratorCost`) |

### `EndPenetrator` (`$BDD1`)

**Fire released after PENETRATOR: Matt inside a wall dies (Explosion, GameOver)**

Witness: L1 1143 (c1, door, door3, masks, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 8 calls, 224 t-states own (0.00 %) |
| Runs (the other recordings) | 795 calls (`stage1/rec/rzx-16000` 290, `stage1/rec/rzx-32000` 154, `stage1/rec/rzx-00000` 152 and 7 more) |
| Called from | `MaskKeys`, `FireMask` (tail), `HeldMasks` (tail), `Penetrator` (tail) |
| Calls | `IsSolid`, `GameOver` (tail), `Explosion` |
| Reads | `$A2CF` (`DissolveCount`); `$B3E8`-`$B3EA` (`MattPlace+2`, `PenetratorOn`) |
| Writes | `$946C` (`EffectStops`); `$A2CF` (`DissolveCount`); `$B3EA` (`PenetratorOn`); `$BAA7` (`Dying`) |

### `Penetrator` (`$BE0E`)

**Penetrator**

[Animation: `Penetrator` at work](img/routines/Penetrator.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 268 calls (`stage1/rec/rzx-00000` 197, `stage2/rec/masks` 43, `stage1/rec/rzx-32000` 28) |
| Called from | `HeldMasks` (tail) |
| Calls | `PlayEffect`, `UseCharge`, `EndPenetrator` (tail) |
| Reads | `$AF2C`-`$AF38` (`MaskSlots+1`); `$B3EA` (`PenetratorOn`); `$BE0D` (`PenetratorCost`); `$CC5C` (`PassBcd`) |
| Writes | `$A2CF` (`DissolveCount`); `$B3EA` (`PenetratorOn`); `$BE0D` (`PenetratorCost`) |

### `UltraFlash` (`$BE39`)

**UltraFlash**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 calls (`stage2/rec/masks` 25) |
| Called from | `HeldMasks` (tail) |

### `Mirage` (`$BE3A`)

**Mirage**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 calls (`stage2/rec/masks` 25) |
| Called from | `HeldMasks` (tail) |

### `Spawn` (`$BF2B`)

**An empty object gets the screen's enemy kind (EnemyKind), every pass for kinds 5, 6, 8-10, else at random**

Witness: L1 91061 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

[Animation: `Spawn` at work](img/routines/Spawn.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 9,774 calls, 2,711,179 t-states own (0.17 %) |
| Runs (the other recordings) | 81,287 calls (`stage1/rec/rzx-16000` 9,600, `stage1/rec/rzx-00000` 7,860, `stage1/rec/rzx-12000` 7,680 and 12 more) |
| Called from | `RunObjects` |
| Calls | `Random`, `SpawnNothing` (tail), `SpawnJumps`, `SpawnJumps1`, `l_BFB7`, `l_BFBA`, `l_BFBD`, `l_BFC0`, `SpawnJump6`, `SpawnJumps7`, `l_BFC9`, `l_BFCC`, `SpawnJump10` |
| Reads | `$A48B` (`Enemies`); `$A4B1` (`Enemies+38`); `$A4D7` (`Enemies+76`); `$A4FD` (`Enemies+114`); `$A523` (`Enemies+152`); `$A549` (`Enemies+190`); 2 more ranges |
| Writes | `$A48B`-`$A491` (`Enemies`); `$A4B1`-`$A4B7` (`Enemies+38`); `$A4D7`-`$A4DD` (`Enemies+76`); `$A4FD`-`$A503` (`Enemies+114`); `$A523`-`$A529` (`Enemies+152`); `$A549`-`$A54F` (`Enemies+190`) |

### `SpawnNothing` (`$BF64`)

**SpawnNothing**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 9,214 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,368 calls (`stage1/rec/rzx-00000` 5,890, `stage1/rec/rzx-24000` 4,478) |
| Called from | `Spawn` (tail), `SpawnGuard` (tail), `SpawnBoss` (tail) |
| Reads | `$A48B` (`Enemies`) |
| Writes | `$A48B`-`$A491` (`Enemies`); `$A4B1`-`$A4B7` (`Enemies+38`); `$A4D7`-`$A4DD` (`Enemies+76`); `$A4FD`-`$A503` (`Enemies+114`); `$A523`-`$A529` (`Enemies+152`); `$A549`-`$A54F` (`Enemies+190`) |

### `ReviveObjects` (`$BF7F`)

**ReviveObjects**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 537,703 t-states own (0.03 %) |
| Runs (the other recordings) | 13,547 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `RunObjects` (tail) |
| Reads | `$A48B` (`Enemies`); `$A4B1` (`Enemies+38`); `$A4D7` (`Enemies+76`); `$A4FD` (`Enemies+114`); `$A523` (`Enemies+152`); `$A549` (`Enemies+190`) |

### `SpawnJumps` (`$BFB1`)

**SpawnJumps**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 560 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 5,600 t-states own (0.00 %) |
| Runs (the other recordings) | 3,325 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 415, `stage1/rec/rzx-12000` 298, `stage2/rec/play2` 294 and 12 more) |
| Called from | `Spawn` |

### `SpawnJumps1` (`$BFB4`)

**SpawnJumps1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 47 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 19, `stage1/rec/rzx-04000` 16, `stage1/rec/rzx-12000` 12) |
| Called from | `Spawn` |
| Calls | `SpawnFlyer` (tail) |

### `l_BFB7` (`$BFB7`)

**l_BFB7**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 139 runs of its first instruction, entered by a jump (`stage1/rec/rzx-32000` 32, `stage1/rec/rzx-00000` 28, `stage1/rec/rzx-28000` 27 and 5 more) |
| Called from | `Spawn` |
| Calls | `SpawnFaller` (tail) |

### `l_BFBA` (`$BFBA`)

**l_BFBA**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 runs of its first instruction, entered by a jump (`stage1/rec/rzx-12000` 16) |
| Called from | `Spawn` |
| Calls | `SpawnWave` (tail) |

### `l_BFBD` (`$BFBD`)

**l_BFBD**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 34 runs of its first instruction, entered by a jump (`stage1/rec/rzx-12000` 28, `stage1/rec/rzx-00000` 6) |
| Called from | `Spawn` |
| Calls | `SpawnWalker` (tail) |

### `l_BFC0` (`$BFC0`)

**l_BFC0**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 runs of its first instruction, entered by a jump (`stage1/rec/rzx-08000` 1, `stage1/rec/rzx-32000` 1) |
| Called from | `Spawn` |
| Calls | `SpawnChaser` (tail) |

### `SpawnJump6` (`$BFC3`)

**JP SpawnKind6 `$C0F7` (room 1, screen 2)**

No play recording reached room 1's screen 2, the only screen of kind 6 (src/res/tables/rooms.csv); work/stage2/rec/kind6 POKEs EnemyKind `$BFB0` = 6 in room 0 (a cheat, said so in its script).

Witness: L1 1919 (kind6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,919 runs of its first instruction, entered by a jump (`stage2/rec/kind6` 1,919) |
| Called from | `Spawn` |
| Calls | `SpawnKind6` (tail) |

### `SpawnJumps7` (`$BFC6`)

**SpawnJumps7**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 45 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 45) |
| Called from | `Spawn` |
| Calls | `SpawnRiser` (tail) |

### `l_BFC9` (`$BFC9`)

**l_BFC9**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,087 runs of its first instruction, entered by a jump (`stage1/rec/rzx-00000` 591, `stage1/rec/rzx-24000` 496) |
| Called from | `Spawn` |
| Calls | `SpawnGuard` (tail) |

### `l_BFCC` (`$BFCC`)

**l_BFCC**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,075 runs of its first instruction, entered by a jump (`stage1/rec/rzx-24000` 1,075) |
| Called from | `Spawn` |
| Calls | `SpawnBoss` (tail) |

### `SpawnJump10` (`$BFCF`)

**JP SpawnKind10 `$C1F3` (room 7, screens 2 and 3)**

No play recording reached room 7's screens 2-3, the only screens of kind 10; work/stage2/rec/door3 POKEs EnemyKind `$BFB0` = 10 in room 7, screen 0 (a cheat, said so in its script).

Witness: L1 1 (door3).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage2/rec/door3` 1) |
| Called from | `Spawn` |
| Calls | `SpawnKind10` (tail) |

### `SpawnFlyer` (`$BFD2`)

**SpawnFlyer**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 47 calls (`stage1/rec/rzx-16000` 19, `stage1/rec/rzx-04000` 16, `stage1/rec/rzx-12000` 12) |
| Called from | `SpawnJumps1` (tail) |
| Calls | `Random`, `SetupObject` (falls into) |
| Reads | `$A442` (`Objects+3`) |
| Writes | `$A48B`-`$A49C` (`Enemies`); `$A4B1`-`$A4C2` (`Enemies+38`); `$A4D7`-`$A4E8` (`Enemies+76`); `$A4FD`-`$A50E` (`Enemies+114`); `$A523`-`$A534` (`Enemies+152`); `$A549`-`$A55A` (`Enemies+190`) |

### `SetupObject` (`$BFF5`)

**Copy the 12-byte template at HL into object IX**

Witness: L1 634 (door, door3, kind6, rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 634 calls (`stage1/rec/rzx-16000` 120, `stage1/rec/rzx-32000` 79, `stage1/rec/rzx-24000` 64 and 9 more) |
| Called from | `PlaceTurrets`, `SpawnFlyer` (falls into), `SpawnFaller`, `SpawnWave` (tail), `SpawnWalker`, `SpawnChaser` (tail), `SpawnKind6` (tail), `SpawnRiser`, `SpawnGuard`, `SpawnBoss`, `SpawnKind10`, `Explode`, `KindTurret` (tail), `KindFourteen`, `KindSixteen` |
| Calls | `Random` |
| Reads | `$BE3B`-`$BF2A` (`EnemyTemplates`) |
| Writes | `$A48D`-`$A56A` (`Enemies+2`) |

### `SpawnFaller` (`$C04B`)

**SpawnFaller**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 139 calls (`stage1/rec/rzx-32000` 32, `stage1/rec/rzx-00000` 28, `stage1/rec/rzx-28000` 27 and 5 more) |
| Called from | `l_BFB7` (tail) |
| Calls | `Random`, `SetupObject` |
| Writes | `$A48B`-`$A48F` (`Enemies`); `$A4A6`-`$A4B5` (`Enemies+27`); `$A4CC`-`$A4DB` (`Enemies+65`); `$A4F2`-`$A501` (`Enemies+103`); `$A518`-`$A527` (`Enemies+141`); `$A53E`-`$A54D` (`Enemies+179`); 1 more ranges |

### `SpawnWave` (`$C07E`)

**SpawnWave**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 calls (`stage1/rec/rzx-12000` 16) |
| Called from | `l_BFBA` (tail) |
| Calls | `Random`, `SetupObject` (tail) |
| Reads | `$A442` (`Objects+3`) |
| Writes | `$A4B1`-`$A4C2` (`Enemies+38`); `$A4D7`-`$A4E8` (`Enemies+76`); `$A4FD`-`$A50E` (`Enemies+114`); `$A523`-`$A534` (`Enemies+152`); `$A549`-`$A55A` (`Enemies+190`) |

### `SpawnWalker` (`$C0A6`)

**SpawnWalker**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 34 calls (`stage1/rec/rzx-12000` 28, `stage1/rec/rzx-00000` 6) |
| Called from | `l_BFBD` (tail) |
| Calls | `SetupObject` |
| Reads | `$A4AA` (`Enemies+31`); `$A4D0` (`Enemies+69`); `$A4F6` (`Enemies+107`); `$A51C` (`Enemies+145`); `$A542` (`Enemies+183`); `$A568` (`Enemies+221`); 1 more ranges |
| Writes | `$A48B`-`$A568` (`Enemies`) |

### `SpawnChaser` (`$C0D9`)

**SpawnChaser**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/rzx-08000` 1, `stage1/rec/rzx-32000` 1) |
| Called from | `l_BFC0` (tail) |
| Calls | `SetupObject` (tail) |
| Reads | `$C0D6` (`ChaserState`) |
| Writes | `$A48B`-`$A48F` (`Enemies`); `$C0D6`-`$C0D8` (`ChaserState`) |

### `SpawnKind6` (`$C0F7`)

**Kind 6 (room 1, screen 2): object kind 16**

Run only with the EnemyKind POKE of work/stage2/rec/kind6 (frames 675-1891).

Witness: L1 1919 (kind6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,919 calls (`stage2/rec/kind6` 1,919) |
| Called from | `SpawnJump6` (tail) |
| Calls | `PlayEffect`, `SetupObject` (tail), `MarkOnce` |
| Reads | `$A4AA` (`Enemies+31`); `$A4D0` (`Enemies+69`); `$A4F6` (`Enemies+107`); `$A51C` (`Enemies+145`); `$A542` (`Enemies+183`); `$A568` (`Enemies+221`) |
| Writes | `$A48B`-`$A48F` (`Enemies`) |

### `SpawnRiser` (`$C116`)

**SpawnRiser**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 45 calls (`stage1/rec/rzx-16000` 45) |
| Called from | `SpawnJumps7` (tail) |
| Calls | `Random`, `SetupObject` |
| Reads | `$AC9C`-`$AC9F` (`SpawnPoints`) |
| Writes | `$A48B`-`$A565` (`Enemies`) |

### `SpawnGuard` (`$C167`)

**SpawnGuard**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,087 calls (`stage1/rec/rzx-00000` 591, `stage1/rec/rzx-24000` 496) |
| Called from | `l_BFC9` (tail) |
| Calls | `SpawnNothing` (tail), `SetupObject`, `MarkOnce` |
| Reads | `$A4AA` (`Enemies+31`); `$A4D0` (`Enemies+69`); `$A4F6` (`Enemies+107`); `$A51C` (`Enemies+145`); `$A542` (`Enemies+183`); `$A568` (`Enemies+221`) |
| Writes | `$A48B`-`$A4A7` (`Enemies`) |

### `MarkOnce` (`$C18C`)

**Set +`$1F` of the six objects**

Witness: L1 3 (kind6, rzx-00000, rzx-24000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/rzx-00000` 1, `stage1/rec/rzx-24000` 1, `stage2/rec/kind6` 1) |
| Called from | `SpawnKind6`, `SpawnGuard`, `SpawnBoss` |
| Writes | `$A4AA` (`Enemies+31`); `$A4D0` (`Enemies+69`); `$A4F6` (`Enemies+107`); `$A51C` (`Enemies+145`); `$A542` (`Enemies+183`); `$A568` (`Enemies+221`) |

### `SpawnBoss` (`$C19E`)

**SpawnBoss**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,075 calls (`stage1/rec/rzx-24000` 1,075) |
| Called from | `l_BFCC` (tail) |
| Calls | `IsSolid`, `SpawnNothing` (tail), `SetupObject`, `MarkOnce` |
| Reads | `$A4AA` (`Enemies+31`); `$A4D0` (`Enemies+69`); `$A4F6` (`Enemies+107`); `$A51C` (`Enemies+145`); `$A542` (`Enemies+183`); `$A568` (`Enemies+221`) |
| Writes | `$A48B`-`$A491` (`Enemies`); `$A4B1`-`$A4B5` (`Enemies+38`); `$A4D0` (`Enemies+69`) |

### `SpawnKind10` (`$C1F3`)

**Kind 10 (room 7, screens 2-3): a group of objects of kinds 18 and 19**

Run only with the EnemyKind POKE of work/stage2/rec/door3 (frame 1478).

Witness: L1 1 (door3).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/door3` 1) |
| Called from | `SpawnJump10` (tail) |
| Calls | `SetupObject` |
| Reads | `$A48B` (`Enemies`); `$A4AA`-`$A4AE` (`Enemies+31`) |
| Writes | `$A48B`-`$A4B5` (`Enemies`); `$A4CC`-`$A4DB` (`Enemies+65`); `$A4F2`-`$A501` (`Enemies+103`); `$A518`-`$A527` (`Enemies+141`); `$A53E`-`$A54D` (`Enemies+179`); `$A564` (`Enemies+217`) |

### `Explode` (`$C26F`)

**Object IX becomes an explosion (kind 3, 4 steps, template HL) with a random effect 11-14**

Witness: L1 272 (door, kind6, rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 272 calls (`stage1/rec/rzx-16000` 53, `stage1/rec/rzx-32000` 45, `stage1/rec/rzx-24000` 38 and 8 more) |
| Called from | `TakeBlockItem`, `KindFaller` (tail), `KindFlyer` (tail), `KindTurret`, `KindWave` (tail), `KindEleven`, `KindTwelve` (tail), `KindFifteen`, `KindSeventeen` (tail) |
| Calls | `Random`, `PlayEffect` (tail), `SetupObject` |
| Writes | `$A48B`-`$A49B` (`Enemies`); `$A4B1`-`$A4C1` (`Enemies+38`); `$A4D7`-`$A4E7` (`Enemies+76`); `$A4FD`-`$A50D` (`Enemies+114`); `$A523`-`$A533` (`Enemies+152`); `$A549`-`$A559` (`Enemies+190`) |

### `RunObjects` (`$C284`)

**The six objects: spawn, Matt's shot, the kind's routine; then ReviveObjects**

Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,629 calls, 1,997,705 t-states own (0.13 %) |
| Runs (the other recordings) | 13,549 calls (`stage1/rec/rzx-16000` 1,600, `stage1/rec/rzx-00000` 1,310, `stage1/rec/rzx-12000` 1,280 and 12 more) |
| Called from | `GameStart` |
| Calls | `ShotHits`, `Spawn`, `ReviveObjects` (tail), `RunKind` |
| Reads | `$A486` (`MattShot+33`); `$A4AC`-`$A4AD` (`Enemies+33`); `$A4D2`-`$A4D3` (`Enemies+71`); `$A4F8`-`$A4F9` (`Enemies+109`); `$A51E`-`$A51F` (`Enemies+147`); `$A544`-`$A545` (`Enemies+185`); 1 more ranges |
| Writes | `$A465` (`MattShot`); `$A486` (`MattShot+33`); `$A4AC`-`$A4AD` (`Enemies+33`); `$A4D2`-`$A4D3` (`Enemies+71`); `$A4F8`-`$A4F9` (`Enemies+109`); `$A51E`-`$A51F` (`Enemies+147`); 2 more ranges |

### `AwardScore` (`$C2C1`)

**Score + the object's +`$14`/+`$15`**

Witness: L1 84 (kind6, rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 84 calls (`stage1/rec/rzx-16000` 18, `stage1/rec/rzx-12000` 17, `stage1/rec/rzx-04000` 10 and 7 more) |
| Called from | `KindFaller`, `KindFlyer`, `KindTurret` (tail), `KindTurretShot`, `KindWave`, `KindChaser`, `ObjectShot`, `KindEleven`, `KindTwelve`, `KindFourteen`, `KindFifteen` |
| Calls | `AddScore` (tail) |
| Reads | `$A49F`-`$A4A0` (`Enemies+20`); `$A4C5`-`$A4C6` (`Enemies+58`); `$A4EB`-`$A4EC` (`Enemies+96`); `$A511`-`$A512` (`Enemies+134`); `$A537`-`$A538` (`Enemies+172`); `$A55D`-`$A55E` (`Enemies+210`) |

### `Damage` (`$C2CA`)

**Energy - the object's +`$1E` (not below 0)**

Witness: L1 133 (door, door3, kind6, rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 133 calls (`stage2/rec/door3` 53, `stage1/rec/rzx-00000` 13, `stage2/rec/door` 12 and 9 more) |
| Called from | `KindFaller`, `KindFlyer`, `KindTurret`, `KindTurretShot` (tail), `KindWave`, `KindWalker`, `KindChaser`, `KindEleven`, `KindTwelve`, `KindFourteen`, `KindFifteen`, `KindEighteen` (tail), `l_C9B8` |
| Reads | `$A4A9` (`Enemies+30`); `$A4CF` (`Enemies+68`); `$A4F5` (`Enemies+106`); `$A51B` (`Enemies+144`); `$A541` (`Enemies+182`); `$A567` (`Enemies+220`); 1 more ranges |
| Writes | `$AEA6` (`Energy`) |

### `TouchesMatt` (`$C2D9`)

**Z when object IX overlaps Matt (never while PENETRATOR is on)**

Witness: L1 12174 (door, door3, kind6, rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12,174 calls (`stage1/rec/rzx-12000` 1,544, `stage1/rec/rzx-00000` 1,433, `stage1/rec/rzx-20000` 1,341 and 9 more) |
| Called from | `KindFaller`, `KindFlyer`, `KindTurret`, `KindTurretShot`, `KindWave`, `KindWalker`, `KindChaser`, `KindEleven`, `KindTwelve`, `KindThirteen`, `KindFourteen`, `KindFifteen`, `KindSixteen`, `KindEighteen`, `l_C9B8` |
| Reads | `$A442`-`$A443` (`Objects+3`); `$A48E`-`$A491` (`Enemies+3`); `$A4B4`-`$A4B7` (`Enemies+41`); `$A4DA`-`$A4DD` (`Enemies+79`); `$A500`-`$A503` (`Enemies+117`); `$A526`-`$A529` (`Enemies+155`); 2 more ranges |

### `RunKind` (`$C315`)

**JP the routine of kind +0 & `$3F` through ObjectJumps**

Witness: L1 91060 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 9,774 calls, 361,695 t-states own (0.02 %) |
| Runs (the other recordings) | 81,286 calls (`stage1/rec/rzx-16000` 9,600, `stage1/rec/rzx-00000` 7,860, `stage1/rec/rzx-12000` 7,680 and 12 more) |
| Called from | `RunObjects` |
| Calls | `l_C329`, `l_C32C`, `l_C32F`, `l_C332`, `l_C335`, `l_C338`, `l_C33B`, `l_C33E`, `l_C344`, `l_C347`, `l_C34A`, `l_C34D`, `l_C350`, `l_C353`, `l_C356`, `l_C359`, `l_C35C`, `l_C35F` |
| Reads | `$A48B` (`Enemies`); `$A4B1` (`Enemies+38`); `$A4D7` (`Enemies+76`); `$A4FD` (`Enemies+114`); `$A523` (`Enemies+152`); `$A549` (`Enemies+190`) |

### `ObjectJumps` (`$C326`)

**JP of kinds 0-19: 0 HangLoop, 1 faller, 2 flyer, 3 explosion, 4 turret, 5 turret shot, 6 wave, 7 walker, 8 chaser, 9-19 the rest**

Kinds 9 and 11 never ran in a recording (known for those only from the code); kinds 16, 18 and 19 ran only after an EnemyKind POKE (work/stage2/rec/kind6, door3).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_C329` (`$C329`)

**l_C329**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,622 runs of its first instruction, entered by a jump (`stage1/rec/rzx-00000` 874, `stage1/rec/rzx-32000` 760, `stage1/rec/rzx-28000` 549 and 5 more) |
| Called from | `RunKind` |
| Calls | `KindFaller` (tail) |

### `l_C32C` (`$C32C`)

**l_C32C**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 858 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 424, `stage1/rec/rzx-04000` 235, `stage1/rec/rzx-12000` 199) |
| Called from | `RunKind` |
| Calls | `KindFlyer` (tail) |

### `l_C32F` (`$C32F`)

**l_C32F**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,072 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 206, `stage1/rec/rzx-32000` 179, `stage1/rec/rzx-24000` 152 and 8 more) |
| Called from | `RunKind` |
| Calls | `KindExplosion` (tail) |

### `l_C332` (`$C332`)

**l_C332**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,273 runs of its first instruction, entered by a jump (`stage2/rec/door` 786, `stage1/rec/rzx-20000` 647, `stage1/rec/rzx-12000` 264 and 5 more) |
| Called from | `RunKind` |
| Calls | `KindTurret` (tail) |

### `l_C335` (`$C335`)

**l_C335**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,159 runs of its first instruction, entered by a jump (`stage2/rec/door` 758, `stage1/rec/rzx-20000` 645, `stage1/rec/rzx-12000` 304 and 4 more) |
| Called from | `RunKind` |
| Calls | `KindTurretShot` (tail) |

### `l_C338` (`$C338`)

**l_C338**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 149 runs of its first instruction, entered by a jump (`stage1/rec/rzx-12000` 149) |
| Called from | `RunKind` |
| Calls | `KindWave` (tail) |

### `l_C33B` (`$C33B`)

**l_C33B**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 616 runs of its first instruction, entered by a jump (`stage1/rec/rzx-12000` 345, `stage1/rec/rzx-00000` 271) |
| Called from | `RunKind` |
| Calls | `KindWalker` (tail) |

### `l_C33E` (`$C33E`)

**l_C33E**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 146 runs of its first instruction, entered by a jump (`stage1/rec/rzx-08000` 78, `stage1/rec/rzx-32000` 68) |
| Called from | `RunKind` |
| Calls | `KindChaser` (tail) |

### `l_C344` (`$C344`)

**l_C344**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 78 runs of its first instruction, entered by a jump (`stage1/rec/rzx-12000` 78) |
| Called from | `RunKind` |
| Calls | `KindTen` (tail) |

### `l_C347` (`$C347`)

**l_C347**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 406 runs of its first instruction, entered by a jump (`stage2/rec/kind6` 406) |
| Called from | `RunKind` |
| Calls | `KindEleven` (tail) |

### `l_C34A` (`$C34A`)

**l_C34A**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 499 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 499) |
| Called from | `RunKind` |
| Calls | `KindTwelve` (tail) |

### `l_C34D` (`$C34D`)

**l_C34D**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 270 runs of its first instruction, entered by a jump (`stage1/rec/rzx-24000` 152, `stage1/rec/rzx-00000` 118) |
| Called from | `RunKind` |
| Calls | `KindThirteen` (tail) |

### `l_C350` (`$C350`)

**l_C350**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 217 runs of its first instruction, entered by a jump (`stage1/rec/rzx-24000` 217) |
| Called from | `RunKind` |
| Calls | `KindFourteen` (tail) |

### `l_C353` (`$C353`)

**l_C353**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 137 runs of its first instruction, entered by a jump (`stage1/rec/rzx-24000` 137) |
| Called from | `RunKind` |
| Calls | `KindFifteen` (tail) |

### `l_C356` (`$C356`)

**l_C356**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 488 runs of its first instruction, entered by a jump (`stage2/rec/kind6` 488) |
| Called from | `RunKind` |
| Calls | `KindSixteen` (tail) |

### `l_C359` (`$C359`)

**l_C359**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 75 runs of its first instruction, entered by a jump (`stage1/rec/rzx-08000` 25, `stage1/rec/rzx-24000` 25, `stage1/rec/rzx-32000` 25) |
| Called from | `RunKind` |
| Calls | `KindSeventeen` (tail) |

### `l_C35C` (`$C35C`)

**l_C35C**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 167 runs of its first instruction, entered by a jump (`stage2/rec/door3` 167) |
| Called from | `RunKind` |
| Calls | `KindEighteen` (tail) |

### `l_C35F` (`$C35F`)

**l_C35F**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 835 runs of its first instruction, entered by a jump (`stage2/rec/door3` 835) |
| Called from | `RunKind` |
| Calls | `l_C9B8` (tail) |

### `MoveXY` (`$C362`)

**y + dy, then x + dx**

Witness: L1 4423 (door, kind6, rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,423 calls (`stage1/rec/rzx-00000` 938, `stage1/rec/rzx-32000` 895, `stage1/rec/rzx-28000` 585 and 8 more) |
| Called from | `KindFaller`, `KindExplosion` (tail) |
| Calls | `MoveX` (falls into) |
| Reads | `$A48E`-`$A48F` (`Enemies+3`); `$A4A6`-`$A4B5` (`Enemies+27`); `$A4CC`-`$A4DB` (`Enemies+65`); `$A4F2`-`$A501` (`Enemies+103`); `$A518`-`$A527` (`Enemies+141`); `$A53E`-`$A54D` (`Enemies+179`); 1 more ranges |
| Writes | `$A48E`-`$A48F` (`Enemies+3`); `$A4B4`-`$A4B5` (`Enemies+41`); `$A4DA`-`$A4DB` (`Enemies+79`); `$A500`-`$A501` (`Enemies+117`); `$A526`-`$A527` (`Enemies+155`); `$A54C`-`$A54D` (`Enemies+193`) |

### `MoveX` (`$C36B`)

**MoveX**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,713 calls (`stage1/rec/rzx-00000` 1,209, `stage1/rec/rzx-12000` 855, `stage1/rec/rzx-16000` 649) |
| Called from | `MoveXY` (falls into), `KindWalker`, `KindTen`, `KindTwelve` |
| Reads | `$A48E` (`Enemies+3`); `$A4A6`-`$A4B4` (`Enemies+27`); `$A4CC`-`$A4DA` (`Enemies+65`); `$A4F2`-`$A500` (`Enemies+103`); `$A518`-`$A526` (`Enemies+141`); `$A53E`-`$A54C` (`Enemies+179`); 1 more ranges |
| Writes | `$A48E` (`Enemies+3`); `$A4B4` (`Enemies+41`); `$A4DA` (`Enemies+79`); `$A500` (`Enemies+117`); `$A526` (`Enemies+155`); `$A54C` (`Enemies+193`) |

### `KindFaller` (`$C375`)

**KindFaller**

[Animation: `KindFaller` at work](img/routines/KindFaller.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,622 calls (`stage1/rec/rzx-00000` 874, `stage1/rec/rzx-32000` 760, `stage1/rec/rzx-28000` 549 and 5 more) |
| Called from | `l_C329` (tail) |
| Calls | `Explode` (tail), `AwardScore`, `Damage`, `TouchesMatt`, `MoveXY`, `HitsWall` |
| Reads | `$A48F` (`Enemies+4`); `$A4A3`-`$A4B5` (`Enemies+24`); `$A4C9`-`$A4DB` (`Enemies+62`); `$A4EF`-`$A501` (`Enemies+100`); `$A515`-`$A527` (`Enemies+138`); `$A53B`-`$A54D` (`Enemies+176`); 1 more ranges |
| Writes | `$A4A3` (`Enemies+24`); `$A4C9` (`Enemies+62`); `$A4EF` (`Enemies+100`); `$A515` (`Enemies+138`); `$A53B` (`Enemies+176`); `$A561` (`Enemies+214`) |

### `KindFlyer` (`$C3A6`)

**KindFlyer**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 858 calls (`stage1/rec/rzx-16000` 424, `stage1/rec/rzx-04000` 235, `stage1/rec/rzx-12000` 199) |
| Called from | `l_C32C` (tail) |
| Calls | `Explode` (tail), `AwardScore`, `Damage`, `TouchesMatt`, `HitsWall` |
| Reads | `$A443` (`Objects+4`); `$A48E`-`$A56B` (`Enemies+3`) |
| Writes | `$A48E`-`$A48F` (`Enemies+3`); `$A4A3` (`Enemies+24`); `$A4B4`-`$A4B5` (`Enemies+41`); `$A4C9` (`Enemies+62`); `$A4DA`-`$A4DB` (`Enemies+79`); `$A4EF` (`Enemies+100`); 6 more ranges |

### `KindExplosion` (`$C3F1`)

**KindExplosion**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,072 calls (`stage1/rec/rzx-16000` 206, `stage1/rec/rzx-32000` 179, `stage1/rec/rzx-24000` 152 and 8 more) |
| Called from | `l_C32F` (tail) |
| Calls | `MoveXY` (tail) |
| Reads | `$A49B`-`$A4A3` (`Enemies+16`); `$A4C1`-`$A4C9` (`Enemies+54`); `$A4E7`-`$A4EF` (`Enemies+92`); `$A50D`-`$A515` (`Enemies+130`); `$A533`-`$A53B` (`Enemies+168`); `$A559`-`$A561` (`Enemies+206`) |
| Writes | `$A48B`-`$A561` (`Enemies`) |

### `HitsWall` (`$C401`)

**Carry when the object's corners touch a solid character**

Witness: L1 12137 (c1, cheat, door3, kind6, masks, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 665 calls, 213,858 t-states own (0.01 %) |
| Runs (the other recordings) | 11,472 calls (`stage1/rec/rzx-16000` 1,848, `stage1/rec/rzx-00000` 1,469, `stage1/rec/rzx-12000` 1,338 and 10 more) |
| Called from | `MoveShot`, `KindFaller`, `KindFlyer`, `KindEleven`, `KindTwelve` |
| Calls | `IsSolid` (tail) |
| Reads | `$A468`-`$A46B` (`MattShot+3`); `$A482`-`$A491` (`MattShot+29`, `Enemies`); `$A4A8`-`$A4B7` (`Enemies+29`); `$A4CE`-`$A4DD` (`Enemies+67`); `$A4F4`-`$A503` (`Enemies+105`); `$A51A`-`$A529` (`Enemies+143`); 2 more ranges |

### `KindTurret` (`$C457`)

**KindTurret**

[Animation: `KindTurret` at work](img/routines/KindTurret.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,273 calls (`stage2/rec/door` 786, `stage1/rec/rzx-20000` 647, `stage1/rec/rzx-12000` 264 and 5 more) |
| Called from | `l_C332` (tail) |
| Calls | `Random`, `SetupObject` (tail), `Explode`, `AwardScore` (tail), `Damage`, `TouchesMatt`, `ObjectCell` |
| Reads | `$A48E`-`$A4B1` (`Enemies+3`); `$A4D7`-`$A4DB` (`Enemies+76`); `$A4EF`-`$A4FD` (`Enemies+100`); `$A523` (`Enemies+152`); `$C26E` (`TurretStem`); `$CC5C` (`PassBcd`); 8 more ranges |
| Writes | `$767E` (`Room0Map+126`); `$775F` (`Room1Map+111`); `$7934` (`Room3Map+100`); `$797E` (`Room3Map+174`); `$7A6E` (`Room4Map+174`); `$7BE3` (`Room6Map+67`); 22 more ranges |

### `ObjectCell` (`$C503`)

**HL = the character map place of object IX**

Witness: L1 1891 (door, rzx- x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,891 calls (`stage2/rec/door` 637, `stage1/rec/rzx-20000` 539, `stage1/rec/rzx-12000` 214 and 5 more) |
| Called from | `KindTurret` |
| Reads | `$A48E`-`$A48F` (`Enemies+3`); `$A4DA`-`$A4DB` (`Enemies+79`) |

### `KindTurretShot` (`$C521`)

**KindTurretShot**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,159 calls (`stage2/rec/door` 758, `stage1/rec/rzx-20000` 645, `stage1/rec/rzx-12000` 304 and 4 more) |
| Called from | `l_C335` (tail) |
| Calls | `AwardScore`, `Damage` (tail), `TouchesMatt` |
| Reads | `$A48B` (`Enemies`); `$A4B1`-`$A4B4` (`Enemies+38`); `$A4C9`-`$A4DA` (`Enemies+62`); `$A4EF`-`$A500` (`Enemies+100`); `$A515`-`$A526` (`Enemies+138`); `$A53B`-`$A545` (`Enemies+176`) |
| Writes | `$A4B1`-`$A4B4` (`Enemies+38`); `$A4C9`-`$A4DA` (`Enemies+62`); `$A4EF`-`$A500` (`Enemies+100`); `$A515`-`$A526` (`Enemies+138`); `$A53B` (`Enemies+176`) |

### `KindWave` (`$C562`)

**KindWave**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 149 calls (`stage1/rec/rzx-12000` 149) |
| Called from | `l_C338` (tail) |
| Calls | `PlayEffect`, `Explode` (tail), `AwardScore`, `Damage`, `TouchesMatt` |
| Reads | `$A4B4`-`$A56B` (`Enemies+41`); `$AC7F` (`FloorRow`); `$C5B5`-`$C5D8` (`WaveHeights`) |
| Writes | `$A4B4`-`$A4C9` (`Enemies+41`); `$A4DA`-`$A4EF` (`Enemies+79`); `$A500`-`$A515` (`Enemies+117`); `$A526`-`$A53B` (`Enemies+155`); `$A54C`-`$A561` (`Enemies+193`) |

### `KindWalker` (`$C5D9`)

**KindWalker**

[Animation: `KindWalker` at work](img/routines/KindWalker.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 616 calls (`stage1/rec/rzx-12000` 345, `stage1/rec/rzx-00000` 271) |
| Called from | `l_C33B` (tail) |
| Calls | `Random`, `Damage`, `TouchesMatt`, `MoveX`, `ObjectShot` (tail) |
| Reads | `$A49D`-`$A4AD` (`Enemies+18`); `$A4C2`-`$A4D3` (`Enemies+55`); `$A4E8`-`$A4F9` (`Enemies+93`); `$A50E`-`$A51F` (`Enemies+131`); `$A535`-`$A545` (`Enemies+170`); `$A55B`-`$A56B` (`Enemies+208`) |
| Writes | `$A49D`-`$A4A7` (`Enemies+18`); `$A4C2`-`$A4CD` (`Enemies+55`); `$A4E8`-`$A4F3` (`Enemies+93`); `$A50E`-`$A519` (`Enemies+131`); `$A535`-`$A53F` (`Enemies+170`); `$A55B`-`$A565` (`Enemies+208`) |

### `KindChaser` (`$C64E`)

**KindChaser**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 146 calls (`stage1/rec/rzx-08000` 78, `stage1/rec/rzx-32000` 68) |
| Called from | `l_C33E` (tail) |
| Calls | `PlayEffect`, `AwardScore`, `Damage`, `TouchesMatt`, `ObjectGone` (tail) |
| Reads | `$950D` (`RoomScreen`); `$A443` (`Objects+4`); `$A48F` (`Enemies+4`); `$A4AC` (`Enemies+33`); `$B3EA` (`PenetratorOn`); `$C0D7`-`$C0D8` (`ChaserState+1`) |
| Writes | `$946D` (`EffectStops+1`); `$A48E`-`$A48F` (`Enemies+3`); `$C0D7`-`$C0D8` (`ChaserState+1`) |

### `KindNine` (`$C6B7`)

**RET: kind 9**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ObjectShot` (`$C6B8`)

**ObjectShot**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rec/rzx-12000` 6) |
| Called from | `KindWalker` (tail) |
| Calls | `AwardScore` |
| Reads | `$A48B` (`Enemies`); `$A4B1` (`Enemies+38`); `$A4D7` (`Enemies+76`); `$A4FD` (`Enemies+114`); `$A523` (`Enemies+152`); `$A549` (`Enemies+190`) |
| Writes | `$A48B` (`Enemies`); `$A49C`-`$A4B1` (`Enemies+17`); `$A4C2`-`$A4D7` (`Enemies+55`); `$A4E8`-`$A4FD` (`Enemies+93`); `$A50E`-`$A523` (`Enemies+131`); `$A534`-`$A549` (`Enemies+169`); 1 more ranges |

### `KindTen` (`$C6D4`)

**KindTen**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 78 calls (`stage1/rec/rzx-12000` 78) |
| Called from | `l_C344` (tail) |
| Calls | `MoveX` |
| Reads | `$A48F`-`$A49C` (`Enemies+4`); `$A4B5`-`$A4C2` (`Enemies+42`); `$A4DB`-`$A4E8` (`Enemies+80`); `$A501`-`$A50E` (`Enemies+118`); `$A527`-`$A534` (`Enemies+156`); `$A54D`-`$A55A` (`Enemies+194`) |
| Writes | `$A48B`-`$A48F` (`Enemies`); `$A4A7`-`$A4B5` (`Enemies+28`); `$A4CD`-`$A4DB` (`Enemies+66`); `$A4F3`-`$A501` (`Enemies+104`); `$A519`-`$A527` (`Enemies+142`); `$A53F`-`$A54D` (`Enemies+180`); 1 more ranges |

### `KindEleven` (`$C6F2`)

**Kind 11: kind 16's shot**

Run only in work/stage2/rec/kind6, where a POKE sets EnemyKind `$BFB0` = 6 in room 0: SpawnKind6's kind-16 objects fire kind 11 (KindSixteen `$C89B`).

Witness: L1 406 (kind6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 406 calls (`stage2/rec/kind6` 406) |
| Called from | `l_C347` (tail) |
| Calls | `Random`, `PlayEffect` (tail), `Explode`, `AwardScore`, `Damage`, `TouchesMatt`, `HitsWall` |
| Reads | `$A4B4`-`$A4B5` (`Enemies+41`); `$A4C9`-`$A4DB` (`Enemies+62`); `$A4EF`-`$A501` (`Enemies+100`); `$A515`-`$A527` (`Enemies+138`); `$A53B`-`$A54D` (`Enemies+176`); `$A561`-`$A56B` (`Enemies+214`) |
| Writes | `$A4B4`-`$A4B5` (`Enemies+41`); `$A4C9`-`$A4DB` (`Enemies+62`); `$A4EF`-`$A501` (`Enemies+100`); `$A515`-`$A527` (`Enemies+138`); `$A53B`-`$A54D` (`Enemies+176`); `$A561`-`$A565` (`Enemies+214`) |

### `KindTwelve` (`$C73F`)

**KindTwelve**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 499 calls (`stage1/rec/rzx-16000` 499) |
| Called from | `l_C34A` (tail) |
| Calls | `Explode` (tail), `AwardScore`, `Damage`, `TouchesMatt`, `MoveX`, `HitsWall` |
| Reads | `$A48F`-`$A56B` (`Enemies+4`) |
| Writes | `$A48F` (`Enemies+4`); `$A4A3`-`$A4B5` (`Enemies+24`); `$A4C9`-`$A4DB` (`Enemies+62`); `$A4EF`-`$A501` (`Enemies+100`); `$A515`-`$A527` (`Enemies+138`); `$A53B`-`$A54D` (`Enemies+176`); 1 more ranges |

### `KindThirteenRet` (`$C789`)

**A RET no branch reaches**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `KindThirteen` (`$C78A`)

**KindThirteen**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 270 calls (`stage1/rec/rzx-24000` 152, `stage1/rec/rzx-00000` 118) |
| Called from | `l_C34D` (tail) |
| Calls | `TouchesMatt`, `GuardBob` |
| Reads | `$A4AC`-`$A4AD` (`Enemies+33`); `$A4F8`-`$A4F9` (`Enemies+109`) |

### `GuardBob` (`$C7F4`)

**The guard's up and down**

Witness: L1 270 (rzx-00000, rzx-24000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 270 calls (`stage1/rec/rzx-24000` 152, `stage1/rec/rzx-00000` 118) |
| Called from | `KindThirteen` |
| Reads | `$A48F` (`Enemies+4`); `$A4A7` (`Enemies+28`); `$A4DB` (`Enemies+80`); `$A4F3` (`Enemies+104`) |
| Writes | `$A48F` (`Enemies+4`); `$A4A7` (`Enemies+28`); `$A4DB` (`Enemies+80`); `$A4F3` (`Enemies+104`) |

### `KindFourteen` (`$C81B`)

**KindFourteen**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 217 calls (`stage1/rec/rzx-24000` 217) |
| Called from | `l_C350` (tail) |
| Calls | `Random`, `SetupObject`, `AwardScore`, `Damage`, `TouchesMatt`, `ObjectGone` (tail) |
| Reads | `$A48B` (`Enemies`); `$A4B4`-`$A4B5` (`Enemies+41`); `$A4D2` (`Enemies+71`) |
| Writes | `$A48B`-`$A48F` (`Enemies`); `$A4B1` (`Enemies+38`) |

### `KindFifteen` (`$C860`)

**KindFifteen**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 137 calls (`stage1/rec/rzx-24000` 137) |
| Called from | `l_C353` (tail) |
| Calls | `Explode`, `AwardScore`, `Damage`, `TouchesMatt` |
| Reads | `$A48E` (`Enemies+3`); `$A4AC`-`$A4AD` (`Enemies+33`) |
| Writes | `$A48B`-`$A48E` (`Enemies`); `$A4A6`-`$A4A7` (`Enemies+27`) |

### `KindSixteen` (`$C89B`)

**Kind 16 (SpawnKind6's object)**

Run only in work/stage2/rec/kind6 (an EnemyKind POKE), frames 675-1891.

Witness: L1 488 (kind6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 488 calls (`stage2/rec/kind6` 488) |
| Called from | `l_C356` (tail) |
| Calls | `Random`, `PlayEffect`, `SetupObject`, `TouchesMatt` |
| Reads | `$A48B`-`$A48F` (`Enemies`); `$A4AC`-`$A4B1` (`Enemies+33`); `$A4D7` (`Enemies+76`); `$A4FD` (`Enemies+114`); `$A523` (`Enemies+152`); `$A549` (`Enemies+190`) |
| Writes | `$A48E` (`Enemies+3`); `$A4B1`-`$A4B5` (`Enemies+38`); `$A4D7`-`$A4DB` (`Enemies+76`); `$A4FD`-`$A501` (`Enemies+114`); `$A523`-`$A527` (`Enemies+152`); `$A549`-`$A54D` (`Enemies+190`) |

### `ObjectGone` (`$C8FD`)

**ObjectGone**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/rzx-08000` 1, `stage1/rec/rzx-24000` 1, `stage1/rec/rzx-32000` 1) |
| Called from | `KindChaser` (tail), `KindFourteen` (tail) |
| Reads | `$A48E`-`$A48F` (`Enemies+3`); `$A4B4`-`$A4B5` (`Enemies+41`) |
| Writes | `$A48B`-`$A4CA` (`Enemies`) |

### `KindSeventeen` (`$C922`)

**KindSeventeen**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 75 calls (`stage1/rec/rzx-24000` 25, `stage1/rec/rzx-32000` 25, `stage1/rec/rzx-08000` 25) |
| Called from | `l_C359` (tail) |
| Calls | `Random`, `Explode` (tail) |
| Reads | `$A48B`-`$A49D` (`Enemies`); `$A4B1`-`$A4C3` (`Enemies+38`); `$A4D7` (`Enemies+76`); `$A4FD` (`Enemies+114`); `$A523` (`Enemies+152`); `$A549` (`Enemies+190`) |
| Writes | `$A48B`-`$A49B` (`Enemies`); `$A4B1`-`$A4C1` (`Enemies+38`); `$A4DA`-`$A4DB` (`Enemies+79`); `$A500`-`$A501` (`Enemies+117`); `$A526`-`$A527` (`Enemies+155`); `$A54C`-`$A54D` (`Enemies+193`) |

### `KindEighteen` (`$C980`)

**Kinds 18 and 19 (SpawnKind10's group)**

Run only in work/stage2/rec/door3 (an EnemyKind POKE), frames 1478-1968.

Kind 18 (the head) has no hits test, so shots never kill it; a LIFTER hit runs ObjectShot and sets +`$1B` = -1. Each pass it keeps its y in +`$1C`, bobs (+`$12` grows for 8 passes and shrinks for 8, by bit 3 of +`$11`, and is added to y) and moves x - 1; a touch costs Damage and the head stays.

Kind 19 at `$C9B8` (the body) keeps its y in +`$1C`, takes the y the record before it had last pass (IX-`$0A`, that record's +`$1C`) and moves x - 1: the group follows the head as a chain, one pass behind each. A touch costs Damage. When its +`$1B` is non-zero (the tail) and x < `$38`, all six slots become the placeholder `$80`: the whole group leaves at once.

Witness: L1 167 (door3).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 167 calls (`stage2/rec/door3` 167) |
| Called from | `l_C35C` (tail) |
| Calls | `Damage` (tail), `TouchesMatt` |
| Reads | `$A48E`-`$A4AD` (`Enemies+3`) |
| Writes | `$A48E`-`$A4A7` (`Enemies+3`) |

### `l_C9B8` (`$C9B8`)

**l_C9B8**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 835 calls (`stage2/rec/door3` 835) |
| Called from | `l_C35F` (tail) |
| Calls | `Damage`, `TouchesMatt` |
| Reads | `$A4A7`-`$A4B5` (`Enemies+28`); `$A4CC`-`$A4DB` (`Enemies+65`); `$A4F2`-`$A501` (`Enemies+103`); `$A518`-`$A527` (`Enemies+141`); `$A53E`-`$A54D` (`Enemies+179`); `$A564` (`Enemies+217`) |
| Writes | `$A48B` (`Enemies`); `$A4B1`-`$A4B5` (`Enemies+38`); `$A4CD`-`$A4DB` (`Enemies+66`); `$A4F3`-`$A501` (`Enemies+104`); `$A519`-`$A527` (`Enemies+142`); `$A53F`-`$A54D` (`Enemies+180`); 1 more ranges |

## matt

`src/game/matt.asm`

### `MattStep` (`$B3EB`)

**Matt's pass: controls, edges, the state routine**

Clears `$F000-$F0BF`, sets DeathFlag when Matt falls below the play area, sets the facing from left / right.

Witness: L1 15289 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

[Animation: `MattStep` at work, jump](img/routines/MattStep-jump.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,630 calls, 3,976,767 t-states own (0.25 %) |
| Runs (the other recordings) | 13,659 calls (`stage1/rec/rzx-16000` 1,612, `stage1/rec/rzx-00000` 1,320, `stage1/rec/rzx-12000` 1,309 and 12 more) |
| Called from | `MattStepDown` (tail), `GameStart` |
| Calls | `l_B403` (falls into) |
| Writes | `$F000`-`$F0BF` (`Zone1CharsLow`, `CharMap`) |

### `l_B403` (`$B403`)

**l_B403**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,638 calls, 545,531 t-states own (0.03 %) |
| Runs (the other recordings) | 14,038 calls (`stage1/rec/rzx-16000` 1,657, `stage1/rec/rzx-00000` 1,365, `stage1/rec/rzx-12000` 1,345 and 12 more) |
| Called from | `MattStep` (falls into), `l_B8A7` (tail), `l_B9A9` (tail) |
| Calls | `l_B46C` (falls into), `MattCell`, `l_B72D` (tail) |
| Reads | `$A138` (`Controls`); `$A43F`-`$A443` (`Objects`); `$BAA7` (`Dying`) |
| Writes | `$A441`-`$A452` (`Objects+2`) |

### `l_B46C` (`$B46C`)

**l_B46C**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,561 calls, 64,213 t-states own (0.00 %) |
| Runs (the other recordings) | 8,636 calls (`stage1/rec/rzx-16000` 1,147, `stage1/rec/rzx-00000` 1,055, `stage1/rec/rzx-12000` 783 and 12 more) |
| Called from | `l_B403` (falls into), `MattStand` (tail) |
| Calls | `l_B4C0`, `Teleport` (tail), `l_B9A9`, `StartWarp` (tail) |
| Reads | `$950A`-`$950D` (`RoomNumber`, `RoomRecord`, `RoomScreen`); `$9F6E`-`$9F70` (`PasswordFlags+1`); `$A138` (`Controls`); `$A442` (`Objects+3`); `$B3E8`-`$B3E9` (`MattPlace+2`); `$F102`-`$F103` (`CharMap+130`); 3 more ranges |

### `l_B4C0` (`$B4C0`)

**l_B4C0**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 814 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 307,942 t-states own (0.02 %) |
| Runs (the other recordings) | 3,627 runs of its first instruction, entered by a jump (`stage1/rec/rzx-00000` 718, `stage1/rec/rzx-12000` 546, `stage1/rec/rzx-16000` 352 and 12 more) |
| Called from | `l_B46C` |
| Calls | `l_B647` (tail), `LeftEdge` (tail), `RightEdge` (tail), `l_B6E8` (tail), `FloorCheck`, `l_B72D` (tail), `JackrabbitJump` (tail), `IsSolid` |
| Reads | `$A138` (`Controls`); `$A441`-`$A452` (`Objects+2`); `$AF2C`-`$AF34` (`MaskSlots+1`); `$AF51`-`$AF52` (`CurrentSlot`); `$B3E6`-`$B3EA` (`MattPlace`, `PenetratorOn`) |
| Writes | `$A43F`-`$A45A` (`Objects`) |

### `MattCell` (`$B5FD`)

**MattPlace from x and y**

Witness: L1 15326 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,638 calls, 365,304 t-states own (0.02 %) |
| Runs (the other recordings) | 13,688 calls (`stage1/rec/rzx-16000` 1,657, `stage1/rec/rzx-00000` 1,365, `stage1/rec/rzx-12000` 1,295 and 12 more) |
| Called from | `l_B403` |
| Reads | `$A441`-`$A443` (`Objects+2`); `$F0C2`-`$F260` (`CharMap+66`); `$F465` (`DirtyMap+165`); `$F485` (`DirtyMap+197`); `$F4A2`-`$F4C0` (`DirtyMap+226`) |
| Writes | `$B3E6`-`$B3E9` (`MattPlace`) |

### `MattCellAhead` (`$B629`)

**The map place ahead of Matt**

Witness: L1 405 (c1, door, door3, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 40 calls, 6,400 t-states own (0.00 %) |
| Runs (the other recordings) | 365 calls (`stage1/rec/rzx-32000` 93, `stage1/rec/rzx-12000` 56, `stage1/rec/rzx-00000` 52 and 9 more) |
| Called from | `FloorCheck` |
| Reads | `$A443`-`$A452` (`Objects+4`) |
| Writes | `$B3E8`-`$B3E9` (`MattPlace+2`) |

### `l_B647` (`$B647`)

**l_B647**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 66 calls (`stage1/rec/rzx-12000` 20, `stage1/rec/rzx-24000` 8, `stage1/rec/rzx-00000` 7 and 7 more) |
| Called from | `l_B4C0` (tail) |
| Calls | `l_B72D` (tail) |
| Reads | `$A451` (`Objects+18`) |
| Writes | `$A43F`-`$A45A` (`Objects`) |

### `LeftEdge` (`$B659`)

**Off the left edge: the screen to the left, or the room RoomTable byte 0**

Witness: L1 38 (c1, rzx-00000, rzx-32000).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 16 calls, 1,376 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/rzx-32000` 20, `stage1/rec/rzx-00000` 2) |
| Called from | `l_B4C0` (tail) |
| Calls | `DrawRoom` |
| Reads | `$950B`-`$950D` (`RoomRecord`, `RoomScreen`); `$953B` (`RoomTable`) |
| Writes | `$950D` (`RoomScreen`); `$A442` (`Objects+3`) |

### `RightEdge` (`$B686`)

**Off the right edge: the next screen, or the room RoomTable byte 1**

Witness: L1 64 (door, door3, play2, rzx- x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 64 calls (`stage1/rec/rzx-12000` 15, `stage1/rec/rzx-00000` 9, `stage1/rec/rzx-16000` 8 and 9 more) |
| Called from | `l_B4C0` (tail), `MattStepDown` (tail), `MattJumpRise`, `JumpEdges`, `MattLongJump` (tail) |
| Calls | `DrawRoom` |
| Reads | `$950B`-`$950D` (`RoomRecord`, `RoomScreen`); `$956C`-`$9578` (`RoomTable+49`) |
| Writes | `$950A`-`$950D` (`RoomNumber`, `RoomRecord`, `RoomScreen`); `$A442` (`Objects+3`) |

### `Teleport` (`$B6B3`)

**A pod: the room RoomTable byte 2, arriving at the place of byte 5**

Witness: L1 4 (rzx-00000, rzx-04000, rzx-12000, rzx-20000).

[Animation: `Teleport` at work](img/routines/Teleport.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/rzx-00000` 1, `stage1/rec/rzx-04000` 1, `stage1/rec/rzx-12000` 1 and 1 more) |
| Called from | `l_B46C` (tail) |
| Calls | `DrawRoom` (tail) |
| Reads | `$950B`-`$950C` (`RoomRecord`); `$953D`-`$9540` (`RoomTable+2`); `$956D`-`$9570` (`RoomTable+50`); `$9585`-`$9588` (`RoomTable+74`); `$95B5`-`$95B8` (`RoomTable+122`) |
| Writes | `$950A`-`$950D` (`RoomNumber`, `RoomRecord`, `RoomScreen`); `$A442` (`Objects+3`) |

### `ExitByte3` (`$B6D8`)

**Never run: leave by RoomTable byte 3**

Known only from the code: byte 3 is `$FF` in every room.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_B6E8` (`$B6E8`)

**l_B6E8**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 calls, 286 t-states own (0.00 %) |
| Runs (the other recordings) | 44 calls (`stage1/rec/rzx-16000` 8, `stage2/rec/play2` 5, `stage1/rec/rzx-32000` 5 and 12 more) |
| Called from | `l_B4C0` (tail) |
| Calls | `l_B6FA` (falls into), `JackrabbitJump` (tail) |
| Reads | `$A451` (`Objects+18`); `$AF2C`-`$AF38` (`MaskSlots+1`); `$AF51`-`$AF52` (`CurrentSlot`) |
| Writes | `$A43F` (`Objects`); `$A450`-`$A45A` (`Objects+17`) |

### `l_B6FA` (`$B6FA`)

**l_B6FA**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 122 calls (`stage1/rec/rzx-16000` 19, `stage1/rec/rzx-24000` 18, `stage1/rec/rzx-32000` 18 and 6 more) |
| Called from | `l_B6E8` (falls into), `MattJumpRise` (tail) |
| Calls | `l_B72D` (tail) |
| Writes | `$A43F` (`Objects`); `$A450` (`Objects+17`) |

### `FloorCheck` (`$B706`)

**A = what is under Matt's feet**

Witness: L1 11688 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1,575 calls, 302,086 t-states own (0.02 %) |
| Runs (the other recordings) | 10,113 calls (`stage1/rec/rzx-16000` 1,370, `stage1/rec/rzx-00000` 1,168, `stage1/rec/rzx-12000` 910 and 12 more) |
| Called from | `l_B4C0`, `l_B8A7`, `MattLongJump`, `l_B9A9` |
| Calls | `MattCellAhead`, `IsSolid` |
| Reads | `$A452` (`Objects+19`); `$B3E8`-`$B3E9` (`MattPlace+2`) |

### `l_B72D` (`$B72D`)

**l_B72D**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 834 calls, 45,889 t-states own (0.00 %) |
| Runs (the other recordings) | 11,115 calls (`stage1/rec/rzx-16000` 1,388, `stage1/rec/rzx-20000` 988, `stage1/rec/rzx-12000` 903 and 12 more) |
| Called from | `l_B403` (tail), `l_B4C0` (tail), `l_B647` (tail), `l_B6FA` (tail) |
| Calls | `StateJumps`, `l_B73D`, `l_B740`, `l_B743`, `l_B746`, `l_B749`, `l_B74C`, `l_B74F`, `StateWarpJump`, `l_B755`, `l_B758` |

### `StateJumps` (`$B73A`)

**StateJumps**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 132 runs of its first instruction, entered by a jump (`stage1/rec/rzx-12000` 40, `stage1/rec/rzx-24000` 16, `stage1/rec/rzx-00000` 14 and 7 more) |
| Called from | `l_B72D` |
| Calls | `MattStepUp` (tail) |

### `l_B73D` (`$B73D`)

**l_B73D**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 30 t-states own (0.00 %) |
| Runs (the other recordings) | 306 runs of its first instruction, entered by a jump (`stage1/rec/rzx-12000` 84, `stage1/rec/rzx-20000` 45, `stage1/rec/rzx-16000` 36 and 12 more) |
| Called from | `l_B72D` |
| Calls | `MattStepDown` (tail) |

### `l_B740` (`$B740`)

**l_B740**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 13 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 130 t-states own (0.00 %) |
| Runs (the other recordings) | 1,320 runs of its first instruction, entered by a jump (`stage1/rec/rzx-20000` 236, `stage1/rec/rzx-12000` 178, `stage1/rec/rzx-04000` 155 and 9 more) |
| Called from | `l_B72D` |
| Calls | `MattCrouchState` (tail) |

### `l_B743` (`$B743`)

**l_B743**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 946 runs of its first instruction, entered by a jump (`stage1/rec/rzx-24000` 152, `stage1/rec/rzx-32000` 140, `stage1/rec/rzx-16000` 123 and 6 more) |
| Called from | `l_B72D` |
| Calls | `MattJumpRise` (tail) |

### `l_B746` (`$B746`)

**l_B746**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 14 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 140 t-states own (0.00 %) |
| Runs (the other recordings) | 1,099 runs of its first instruction, entered by a jump (`stage1/rec/rzx-32000` 155, `stage1/rec/rzx-24000` 148, `stage1/rec/rzx-28000` 133 and 12 more) |
| Called from | `l_B72D` |
| Calls | `MattFall` (tail) |

### `l_B749` (`$B749`)

**l_B749**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 630 runs of its first instruction, entered by a jump (`stage1/rec/rzx-20000` 207, `stage1/rec/rzx-08000` 160, `stage1/rec/rzx-16000` 150 and 3 more) |
| Called from | `l_B72D` |
| Calls | `MattLongJump` (tail) |

### `l_B74C` (`$B74C`)

**l_B74C**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 753 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 7,530 t-states own (0.00 %) |
| Runs (the other recordings) | 5,246 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 821, `stage2/rec/door3` 575, `stage2/rec/kind6` 484 and 12 more) |
| Called from | `l_B72D` |
| Calls | `MattStand` (tail) |

### `l_B74F` (`$B74F`)

**l_B74F**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 350 runs of its first instruction, entered by a jump (`stage1/rec/rzx-08000` 50, `stage1/rec/rzx-12000` 50, `stage1/rec/rzx-20000` 50 and 4 more) |
| Called from | `l_B72D` |
| Calls | `MattNoEnergy` (tail) |

### `StateWarpJump` (`$B752`)

**JP PasswordWarp `$B9D8`: state 10's slot**

Witness: L1 100 (door, door3).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 100 runs of its first instruction, entered by a jump (`stage2/rec/door` 50, `stage2/rec/door3` 50) |
| Called from | `l_B72D` |
| Calls | `PasswordWarp` (tail) |

### `l_B755` (`$B755`)

**l_B755**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 10 t-states own (0.00 %) |
| Runs (the other recordings) | 20 runs of its first instruction, entered by a jump (`stage2/rec/play2` 3, `stage1/rec/rzx-04000` 2, `stage1/rec/rzx-24000` 2 and 11 more) |
| Called from | `l_B72D` |
| Calls | `PodStart` (tail) |

### `l_B758` (`$B758`)

**l_B758**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 50 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 500 t-states own (0.00 %) |
| Runs (the other recordings) | 966 runs of its first instruction, entered by a jump (`stage2/rec/play2` 150, `stage1/rec/rzx-24000` 100, `stage1/rec/rzx-32000` 100 and 11 more) |
| Called from | `l_B72D` |
| Calls | `MattPodDissolve` (tail) |

### `MattStepUp` (`$B75B`)

**MattStepUp**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 132 calls (`stage1/rec/rzx-12000` 40, `stage1/rec/rzx-24000` 16, `stage1/rec/rzx-00000` 14 and 7 more) |
| Called from | `StateJumps` (tail) |
| Reads | `$A442`-`$A45A` (`Objects+3`) |
| Writes | `$A43F`-`$A44F` (`Objects`) |

### `MattStepDown` (`$B775`)

**MattStepDown**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 3 calls, 372 t-states own (0.00 %) |
| Runs (the other recordings) | 306 calls (`stage1/rec/rzx-12000` 84, `stage1/rec/rzx-20000` 45, `stage1/rec/rzx-16000` 36 and 12 more) |
| Called from | `l_B73D` (tail) |
| Calls | `MattStep` (tail), `RightEdge` (tail) |
| Reads | `$A442`-`$A45A` (`Objects+3`) |
| Writes | `$A43F`-`$A44F` (`Objects`) |

### `MattCrouchState` (`$B79E`)

**MattCrouchState**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 13 calls, 551 t-states own (0.00 %) |
| Runs (the other recordings) | 1,320 calls (`stage1/rec/rzx-20000` 236, `stage1/rec/rzx-12000` 178, `stage1/rec/rzx-04000` 155 and 9 more) |
| Called from | `l_B740` (tail) |
| Calls | `CheckPickupsDown` (tail) |
| Reads | `$A138` (`Controls`); `$A443` (`Objects+4`) |
| Writes | `$A43F`-`$A443` (`Objects`) |

### `MattJumpRise` (`$B7B5`)

**MattJumpRise**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 946 calls (`stage1/rec/rzx-24000` 152, `stage1/rec/rzx-32000` 140, `stage1/rec/rzx-16000` 123 and 6 more) |
| Called from | `l_B743` (tail) |
| Calls | `RightEdge`, `l_B6FA` (tail), `IsSolid`, `LavaDrain` (tail) |
| Reads | `$A194` (`ZoneSlots`); `$A442`-`$A45A` (`Objects+3`); `$AF0C` (`PassCounter`); `$B3E6`-`$B3EA` (`MattPlace`, `PenetratorOn`) |
| Writes | `$A43F`-`$A450` (`Objects`) |

### `MattFall` (`$B841`)

**MattFall**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 14 calls, 3,876 t-states own (0.00 %) |
| Runs (the other recordings) | 1,099 calls (`stage1/rec/rzx-32000` 155, `stage1/rec/rzx-24000` 148, `stage1/rec/rzx-28000` 133 and 12 more) |
| Called from | `l_B746` (tail) |
| Reads | `$A452`-`$A45A` (`Objects+19`); `$AF2C`-`$AF38` (`MaskSlots+1`); `$AF51`-`$AF52` (`CurrentSlot`); `$B3E6`-`$B3EA` (`MattPlace`, `PenetratorOn`) |

### `MattJumpRet` (`$B84F`)

**A RET no branch reaches, then the jump's shared steps**

The RET at `$B84F` never ran (known only from the code); the steps from `$B850` run in every jump (c1).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `JumpEdges`, `l_B8A7` (tail), `IsSolid` |

### `JumpEdges` (`$B87F`)

**The jump at the screen edges**

At an edge the branches jump into the fall step `$B8A7` inside MattFall's CALL; its RET returns to `$B87C`, which runs the step again: the pass that crosses a screen edge in the fall adds v to y and grows v twice (rzx-04000 frames 2696-2702: y `$0F` v 3 -> y `$16` v 5).

Witness: L1 719 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 12 calls, 1,116 t-states own (0.00 %) |
| Runs (the other recordings) | 707 calls (`stage1/rec/rzx-32000` 128, `stage1/rec/rzx-28000` 122, `stage1/rec/rzx-24000` 86 and 12 more) |
| Called from | `MattJumpRet` |
| Calls | `RightEdge`, `l_B8A7` (tail) |
| Reads | `$A442` (`Objects+3`); `$A45A` (`Objects+27`) |
| Writes | `$A442` (`Objects+3`) |

### `l_B8A7` (`$B8A7`)

**l_B8A7**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 14 calls, 2,230 t-states own (0.00 %) |
| Runs (the other recordings) | 1,110 calls (`stage1/rec/rzx-32000` 157, `stage1/rec/rzx-24000` 151, `stage1/rec/rzx-28000` 135 and 12 more) |
| Called from | `MattJumpRet` (tail), `JumpEdges` (tail) |
| Calls | `l_B403` (tail), `FloorCheck` |
| Reads | `$A194` (`ZoneSlots`); `$A443`-`$A450` (`Objects+4`); `$AF0C` (`PassCounter`) |
| Writes | `$A43F`-`$A450` (`Objects`) |

### `JackrabbitJump` (`$B8DE`)

**JackrabbitJump**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13 calls (`stage1/rec/rzx-20000` 4, `stage1/rec/rzx-16000` 3, `stage1/rec/rzx-08000` 2 and 3 more) |
| Called from | `l_B4C0` (tail), `l_B6E8` (tail) |
| Writes | `$A43F` (`Objects`); `$A450` (`Objects+17`) |

### `MattLongJump` (`$B8E7`)

**MattLongJump**

[Animation: `MattLongJump` at work](img/routines/MattLongJump.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 630 calls (`stage1/rec/rzx-20000` 207, `stage1/rec/rzx-08000` 160, `stage1/rec/rzx-16000` 150 and 3 more) |
| Called from | `l_B749` (tail) |
| Calls | `UseCharge`, `RightEdge` (tail), `FloorCheck`, `IsSolid`, `LavaDrain` |
| Reads | `$A138` (`Controls`); `$A194` (`ZoneSlots`); `$A442`-`$A452` (`Objects+3`); `$AF2C`-`$AF34` (`MaskSlots+1`); `$AF51`-`$AF52` (`CurrentSlot`); `$B3E6`-`$B3E9` (`MattPlace`) |
| Writes | `$A43F`-`$A450` (`Objects`) |

### `IsSolid` (`$B993`)

**Carry when the character at HL is solid (its ZoneAttrs bit 7)**

Witness: L1 81448 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 7,102 calls, 397,807 t-states own (0.03 %) |
| Runs (the other recordings) | 74,346 calls (`stage1/rec/rzx-16000` 10,641, `stage1/rec/rzx-00000` 9,539, `stage1/rec/rzx-12000` 8,579 and 12 more) |
| Called from | `l_B4C0`, `FloorCheck`, `MattJumpRise`, `MattJumpRet`, `MattLongJump`, `EndPenetrator`, `SpawnBoss`, `HitsWall` (tail) |
| Reads | `$EF00`-`$F001` (`ZoneAttrs`, `Zone1CharsLow`); `$F020`-`$F021` (`Zone1CharsLow+32`); `$F040`-`$F041` (`Zone1CharsLow+64`); `$F0BF`-`$F2DF` (`CharMap+63`); `$F462`-`$F463` (`DirtyMap+162`); `$F482`-`$F483` (`DirtyMap+194`); 2 more ranges |

### `MattStand` (`$B99B`)

**MattStand**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 753 calls, 38,482 t-states own (0.00 %) |
| Runs (the other recordings) | 5,246 calls (`stage1/rec/rzx-16000` 821, `stage2/rec/door3` 575, `stage2/rec/kind6` 484 and 12 more) |
| Called from | `l_B74C` (tail) |
| Calls | `l_B46C` (tail) |
| Reads | `$A138` (`Controls`) |
| Writes | `$A43F` (`Objects`) |

### `l_B9A9` (`$B9A9`)

**l_B9A9**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 747 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 30,646 t-states own (0.00 %) |
| Runs (the other recordings) | 5,003 runs of its first instruction, entered by a jump (`stage1/rec/rzx-16000` 795, `stage2/rec/door3` 566, `stage2/rec/kind6` 480 and 12 more) |
| Called from | `l_B46C` |
| Calls | `l_B403` (tail), `FloorCheck` |

### `MattNoEnergy` (`$B9B8`)

**MattNoEnergy**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 350 calls (`stage1/rec/rzx-08000` 50, `stage1/rec/rzx-12000` 50, `stage1/rec/rzx-20000` 50 and 4 more) |
| Called from | `l_B74F` (tail) |
| Calls | `FlushDirty`, `GameOver` (tail) |
| Reads | `$A44F` (`Objects+16`) |
| Writes | `$A44F` (`Objects+16`) |

### `StartWarp` (`$B9C5`)

**StartWarp**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage2/rec/door` 1, `stage2/rec/door3` 1) |
| Called from | `l_B46C` (tail) |
| Calls | `PlayEffect` |
| Writes | `$A2CF` (`DissolveCount`); `$A43F`-`$A44F` (`Objects`) |

### `PasswordWarp` (`$B9D8`)

**State 10: the warp through a room-0 password door to room 11, 3, 7 or 7**

Counts the dissolve down (IX+`$10`), then sets RoomNumber from WarpRooms `$BA1D`[door] (0B 03 07 07), RoomScreen 0, x `$42`, y + 8, state 8, and DrawRoom. Door 3 also calls WarpBonus `$BA21`. The door recording (work/stage2/rec/door, a POKE cheat for the password flags) took door 1 (x `$68`, state 10 at frame 845) to room 3 (frame 981); door3 (the same cheat, x `$A0`) took door 3 to room 7 and its LIFTER.

Witness: L1 100 (door, door3).

[Animation: `PasswordWarp` at work](img/routines/PasswordWarp.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 100 calls (`stage2/rec/door3` 50, `stage2/rec/door` 50) |
| Called from | `StateWarpJump` (tail) |
| Calls | `DrawRoom` (tail), `WarpBonus` |
| Reads | `$A2CF` (`DissolveCount`); `$A442`-`$A44F` (`Objects+3`); `$BA1E`-`$BA20` (`WarpRooms+1`) |
| Writes | `$950A`-`$950D` (`RoomNumber`, `RoomRecord`, `RoomScreen`); `$A2CF` (`DissolveCount`); `$A43F`-`$A44F` (`Objects`) |

### `WarpBonus` (`$BA21`)

**Door 3's bonus: BACKLASH to level 3, a LIFTER with 99 charges at level 1, its name**

FindLifterSlot `$BA3E` picks the first EMPTY or PENETRATOR slot (else slot 0), raising every BACKLASH slot it passes to level 3; the slot gets kind 6 (LIFTER), 99 charges, level 1; ShowLifterName `$BA60` when slot 0 was EMPTY; then DrawAllSlots.

Witness: L1 1 (door3).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/door3` 1) |
| Called from | `PasswordWarp` |
| Calls | `DrawAllSlots` (tail), `FindLifterSlot`, `ShowLifterName` |
| Reads | `$AF2C` (`MaskSlots+1`) |
| Writes | `$AF2C`-`$AF2E` (`MaskSlots+1`) |

### `FindLifterSlot` (`$BA3E`)

**IX = the first EMPTY or PENETRATOR slot, else slot 0; BACKLASH slots on the way get level 3**

Witness: L1 1 (door3).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/door3` 1) |
| Called from | `WarpBonus` |
| Reads | `$AF2C` (`MaskSlots+1`) |

### `ShowLifterName` (`$BA60`)

**ShowMaskName(LIFTER), keeping AF**

Witness: L1 1 (door3).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/door3` 1) |
| Called from | `WarpBonus` |
| Calls | `ShowMaskName` |

### `PodStart` (`$BA68`)

**State 11: the materialisation at a new game (effect 9), then the dissolve**

Witness: L1 21 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 1 call, 103 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage2/rec/play2` 3, `stage1/rec/rzx-04000` 2, `stage1/rec/rzx-24000` 2 and 11 more) |
| Called from | `l_B755` (tail) |
| Calls | `PlayEffect` |
| Reads | `$A43F` (`Objects`) |
| Writes | `$A2CF` (`DissolveCount`); `$A43F`-`$A44F` (`Objects`) |

### `MattPodDissolve` (`$BA7B`)

**MattPodDissolve**

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 50 calls, 3,688 t-states own (0.00 %) |
| Runs (the other recordings) | 966 calls (`stage2/rec/play2` 150, `stage1/rec/rzx-24000` 100, `stage1/rec/rzx-32000` 100 and 11 more) |
| Called from | `l_B758` (tail) |
| Reads | `$A2CF` (`DissolveCount`); `$A44F` (`Objects+16`) |
| Writes | `$A2CF` (`DissolveCount`); `$A43F`-`$A44F` (`Objects`) |

### `LavaDrain` (`$BA93`)

**Zone 1: 2 energy when Matt's head hits a solid character in a jump (MattJumpRise `$B83E`, JackrabbitJump `$B91C` / `$B925`)**

Witness: L1 51 (rzx-12000, rzx-16000, rzx-20000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 51 calls (`stage1/rec/rzx-20000` 43, `stage1/rec/rzx-16000` 7, `stage1/rec/rzx-12000` 1) |
| Called from | `MattJumpRise` (tail), `MattLongJump` |
| Reads | `$A194` (`ZoneSlots`); `$AEA6` (`Energy`) |
| Writes | `$AEA6` (`Energy`) |

### `Death` (`$BAA8`)

**Matt sinks for 32 passes, effect 8, then GameOver**

Witness: L1 6 (rzx-04000, rzx-24000, rzx-28000, rzx-32000).

[Animation: `Death` at work](img/routines/Death.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rec/rzx-04000` 2, `stage1/rec/rzx-28000` 2, `stage1/rec/rzx-24000` 1 and 1 more) |
| Called from | `GameStart` (tail) |
| Calls | `PlayEffect`, `FlushDirty`, `DrawObjects`, `AnimateZone` |
| Reads | `$9D16`-`$9D18` (`Hiscore`); `$A443` (`Objects+4`); `$AE41`-`$AE44` (`Score`); `$FFFE` (`work space $FFFE+`) |
| Writes | `$9222` (`TuneRequest`); `$946C` (`EffectStops`); `$9D16`-`$9D19` (`Hiscore`); `$A2CF` (`DissolveCount`); `$A443` (`Objects+4`); `$BAA7` (`Dying`) |

### `GameOver` (`$BACC`)

**GameOver**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/rzx-24000` 1, `stage1/rec/rzx-32000` 1, `stage2/rec/door3` 1 and 5 more) |
| Called from | `MattNoEnergy` (tail), `EndPenetrator` (tail) |
| Calls | `SlowPrint`, `GameStart` (tail) |
| Reads | `$9D16`-`$9D19` (`Hiscore`); `$AE41`-`$AE44` (`Score`); `$FFFE` (`work space $FFFE+`) |
| Writes | `$9222` (`TuneRequest`); `$946C` (`EffectStops`); `$9D16`-`$9D19` (`Hiscore`) |

### `SlowPrint` (`$BB13`)

**Print a string a character a few HALTs**

Witness: L1 17 (door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`stage1/rec/rzx-28000` 2, `stage1/rec/rzx-32000` 2, `stage1/rec/rzx-04000` 2 and 9 more) |
| Called from | `Ending`, `GameOver` |
| Calls | `ScreenAddr`, `PrintChar`, `PrintSpace` |
| Reads | `$AE1D`-`$AE40` (`EndTexts`); `$BB01`-`$BB35` (`GameOverText`, `SlowPrint`) |
| Writes | `$BFB0` (`EnemyKind`) |

### `PrintSpace` (`$BB38`)

**A space and a flash attribute at the cursor**

Witness: L1 341 (door3, kind6, masks, play2, rzx- x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 341 calls (`stage1/rec/rzx-24000` 38, `stage1/rec/rzx-04000` 38, `stage1/rec/rzx-28000` 38 and 9 more) |
| Called from | `SlowPrint` |
| Calls | `PrintChar` |
| Writes | `$5887`-`$5899` (screen); `$5901`-`$591B` (screen); `$5988`-`$5992` (screen) |

### `CheatCheck` (`$BB4C`)

**Interrupt, in play: compare PasswordBuffer with CheatCode; equal sets CheatOn `$BB77`**

HL = `$E406` + `$BB6B` = `$9F71` (PasswordBuffer, the sum overflows): typing JUDGE DREDD at ENTER PASSWORD sets CheatOn, which UseCharge `$B210` and DeadlyFloor `$B2F9` read: the masks keep their charges and the deadly floors do not kill. Witness: L1 46478 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10); the cheat's effect is in work/stage2/NOTES.md.

| | |
| --- | --- |
| Runs (c1: power-on, the original at ROM speed on the 128K, the menu, define keys, play on the first screens) | 4,031 calls, 455,503 t-states own (0.03 %) |
| Runs (the other recordings) | 42,447 calls (`stage1/rec/rzx-16000` 3,999, `stage1/rec/rzx-12000` 3,786, `stage1/rec/rzx-00000` 3,655 and 13 more) |
| Called from | `Interrupt` |
| Reads | `$9F71`-`$9F7C` (`PasswordBuffer`); `$BB6B`-`$BB76` (`CheatCode`) |
| Writes | `$BB77` (`CheatOn`) |

### `Explosion` (`$BB78`)

**200 dots fly out of Matt: the PENETRATOR's death in a wall**

Reached only from EndPenetrator `$BDF7`, when fire is released with Matt inside a wall (effects 16 and 17). Witness: work/stage2/rec/masks (PENETRATOR given by POKE, fire held walking right into the hill, released at frame 1249).

Witness: L1 1 (masks).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage2/rec/masks` 1) |
| Called from | `EndPenetrator` |
| Calls | `Random`, `PlayEffect`, `FlushDirty`, `PlotDot` |
| Reads | `$5800`-`$5AFF` (screen); `$A442`-`$A443` (`Objects+3`); `$BBFD` (`l_BBFB+2`); `$E800`-`$EBE7` (`SpriteChars`) |
| Writes | `$5800`-`$5957` (screen); `$5968`-`$5977` (screen); `$5990`-`$5997` (screen); `$59B0`-`$59B7` (screen); `$E800`-`$EBE7` (`SpriteChars`) |

### `PlotDot` (`$BC58`)

**XOR the dot at x E, y D**

Witness: L1 10085 (masks).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10,085 calls (`stage2/rec/masks` 10,085) |
| Called from | `Explosion` |
| Reads | `$4000`-`$513F` (screen); `$5200`-`$533F` (screen); `$5406`-`$553F` (screen); `$5605`-`$573F` (screen); `$BC8E`-`$BC95` (`DotBits`) |
| Writes | `$4000`-`$533F` (screen); `$5406`-`$553F` (screen); `$5605`-`$573F` (screen); `$BC89` (`l_BC68+33`) |
