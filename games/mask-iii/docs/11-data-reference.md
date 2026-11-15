# 11. Data reference

Every data entry of the game image `$6000`-`$FDFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## zones

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6000` | `Zone1CharsHigh` | 768 | Zone 1's characters 160-255 (768 bytes), parked in the set at `$5B00`. Read by SwapZone `$A198` when a room of zone 1 is drawn. Witness: the RZX segments reach the caverns (work/stage1/rec/rzx-*). | `SwapZone` (`stage1/rec/rzx-12000`) | `SwapZone` (`stage1/rec/rzx-12000`) |
| `$6300` | `Zone1AttrsLeftover` | 256 | 256 bytes overwritten at the entry by Zone1Attrs `$EE00`: an older copy of zone 1's attributes. GameEntry `$9100` copies Zone1Attrs `$EE00` over these bytes before anything reads them; 255 of the 256 bytes equal the copy, only the first differs (`$00` here, `$47` at `$EE00`). Leftover, known only from the code. | `SwapZone` (`stage1/rec/rzx-12000`) | `GameEntry`, `SwapZone` (`stage1/rec/rzx-12000`) |
| `$6400` | `Zone2Chars` | 2048 | Zone 2's (the moon's) 256 characters, parked | `SwapZone` (`stage2/rec/door3`) | `SwapZone` (`stage2/rec/door3`) |
| `$6C00` | `Zone2Attrs` | 256 | Zone 2's attributes | `SwapZone` (`stage2/rec/door3`) | `GameEntry`, `SwapZone` (`stage2/rec/door3`) |
| `$6D00` | `Zone3Chars` | 2048 | Zone 3's 256 characters, parked | `SwapZone` (`stage1/rec/rzx-00000`) | `SwapZone` (`stage1/rec/rzx-00000`) |
| `$7500` | `Zone3Attrs` | 256 | Zone 3's attributes | `SwapZone` (`stage1/rec/rzx-00000`) | `GameEntry`, `SwapZone` (`stage1/rec/rzx-00000`) |

## rooms

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7600` | `Room0Map` | 240 | Room 0: the surface (zone 0), the start, the password doors | `DrawRoom`, `FindBlock`, `NewGame`, `FindNextBlock` (`stage1/rec/rzx-00000`) | `PasswordPods`, `KindTurret` (`stage1/rec/rzx-00000`), `NewGame` (`stage1/rec/rzx-04000`) |
| `$76F0` | `Room1Map` | 240 | Room 1 (zone 0) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-04000`), `FindBlock` (`stage1/rec/rzx-04000`), `FindNextBlock` (`stage1/rec/rzx-04000`) | `KindTurret` (`stage1/rec/rzx-04000`), `NewGame` (`stage1/rec/rzx-04000`) |
| `$77E0` | `Room2Map` | 240 | Room 2 (zone 0) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-08000`), `FindBlock` (`stage1/rec/rzx-08000`) | - |
| `$78D0` | `Room3Map` | 240 | Room 3 (zone 0): the first code message | `NewGame`, `DrawRoom` (`stage1/rec/rzx-20000`), `FindBlock` (`stage1/rec/rzx-20000`), `FindNextBlock` (`stage1/rec/rzx-20000`) | `KindTurret` (`stage1/rec/rzx-20000`), `NewGame` (`stage1/rec/rzx-20000`), `TakeBlockItem` (`stage1/rec/rzx-20000`) |
| `$79C0` | `Room4Map` | 240 | Room 4 (zone 1) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-12000`), `FindBlock` (`stage1/rec/rzx-12000`), `FindNextBlock` (`stage1/rec/rzx-12000`) | `KindTurret` (`stage1/rec/rzx-12000`), `NewGame` (`stage1/rec/rzx-12000`) |
| `$7AB0` | `Room5Map` | 240 | Room 5 (zone 1) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-16000`), `FindBlock` (`stage1/rec/rzx-16000`), `FindNextBlock` (`stage1/rec/rzx-16000`) | `NewGame` |
| `$7BA0` | `Room6Map` | 240 | Room 6 (zone 1) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-16000`), `FindBlock` (`stage1/rec/rzx-16000`), `FindNextBlock` (`stage1/rec/rzx-16000`) | `NewGame`, `KindTurret` (`stage1/rec/rzx-16000`) |
| `$7C90` | `Room7Map` | 240 | Room 7 (zone 2, the moon) | `NewGame`, `DrawRoom` (`stage2/rec/door3`), `FindBlock` (`stage2/rec/door3`) | `NewGame` (`stage1/rec/rzx-32000`) |
| `$7D80` | `Room8Map` | 240 | Room 8 (zone 2) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-28000`), `FindBlock` (`stage1/rec/rzx-28000`) | - |
| `$7E70` | `Room9Map` | 240 | Room 9 (zone 2) | `NewGame` | - |
| `$7F60` | `Room10Map` | 240 | Room 10 (zone 3) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-00000`), `FindBlock` (`stage1/rec/rzx-00000`) | - |
| `$8050` | `Room11Map` | 240 | Room 11 (zone 3) | `NewGame` | `NewGame` (`stage1/rec/rzx-12000`) |
| `$8140` | `Room12Map` | 240 | Room 12 (zone 3) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-12000`), `FindBlock` (`stage1/rec/rzx-12000`) | - |
| `$8230` | `Room13Map` | 240 | Room 13 (zone 3) | `NewGame` | `NewGame` (`stage1/rec/rzx-28000`) |
| `$8320` | `Room14Map` | 240 | Room 14 (zone 3) | `NewGame`, `DrawRoom` (`stage1/rec/rzx-32000`), `FindBlock` (`stage1/rec/rzx-32000`) | - |
| `$8410` | `Room15Map` | 240 | Room 15 (zone 3): the last room, Scott at screen 5 | `NewGame` | - |
| `$8500` | `Blocks` | 3072 | The 192 blocks: 16 character codes each, 4 rows of 4 (the codes index the live zone's set). Read by DrawRoom `$A89D` for every block of a screen (`$A8E0-$A920`). Witness: every room drawn in c1 and the RZX segments. | `DrawRoom` | - |
| `$950A` | `RoomNumber` | 1 of 4 | The room, 0-15 | `CheckPickups`, `DrawRoom`, `LeftEdge`, `PlacePickupsInScreen`, `RoomMessage` +5 | `DrawRoom`, `NewGame`, `DrawObject` (`stage2/rec/play2`), `LeftEdge` (`stage1/rec/rzx-00000`), `PasswordWarp` (`stage2/rec/door`) +3 |
| `$950B` | `RoomRecord` (`RoomNumber`+1) | 2 | the room's RoomTable record | `DrawRoom`, `LeftEdge`, `RightEdge` (`stage1/rec/rzx-12000`), `Teleport` (`stage1/rec/rzx-00000`), `ExitByte3` (code) | `DrawRoom` |
| `$950D` | `RoomScreen` (`RoomNumber`+3) | 1 | 8 x the screen (0-5): the map column of the screen's left edge | `CheckPickups`, `DrawRoom`, `LeftEdge`, `PlacePickupsInScreen`, `RoomMessage` +3 | `NewGame`, `DrawObject` (`stage2/rec/play2`), `LeftEdge` (`stage1/rec/rzx-00000`), `PasswordWarp` (`stage2/rec/door`), `RightEdge` (`stage1/rec/rzx-00000`) +1 |
| `$950E` | `PickupTable` | 45 | The 11 masks lying in the rooms, 4 bytes each [room + bit 7 taken, mask kind, x, y], `$FF` at the end. PlacePickupsInScreen `$A9BE` shows the records of the room's screen that are not taken; CheckPickups `$B126` sets bit 7 when Matt takes one; NewGame clears the bits. Eleven pick-ups; kinds 2, 3, 9 and 10 (ULTRA FLASH, MIRAGE, LAVA SHOT, STREAMER) are in no record and cannot be had in play. Also src/res/tables/pickups.csv. | `CheckPickups`, `FindPickup`, `NewGame`, `PlacePickup` | `CheckPickups`, `NewGame` |
| `$953B` | `RoomTable` | 192 | 16 records of 12 bytes: left, right, pod, exit 3, zone, arrival, an enemy kind a screen. Bytes: 0 the room to the left, 1 to the right (`$FF` none), 2 the pod's destination (Teleport `$B6B3`), 3 an exit read only by the never-run ExitByte3 `$B6D8`, 4 the zone, 5 the arrival place after a pod: x = (b & `$1F`) x 4 + `$40`, RoomScreen = (b & `$E0`) / 4, 6-11 one enemy kind (EnemyKind `$BFB0`) for each of the six screens (DrawRoom `$A89D`). The table is also src/res/tables/rooms.csv (tools/res_formats.py writes it from these bytes). | `DrawRoom`, `LeftEdge`, `RightEdge` (`stage1/rec/rzx-12000`), `Teleport` (`stage1/rec/rzx-00000`) | - |
| `$95FB` | `Font` | 195 | 5-row glyphs: A-Z, then 0-9 at `$967D`, '.' `$96AF`, ':' `$96B4`, space `$96B9` | `PrintChar`, `ScrollerNextChar` | - |
| `$970D` | `NotInPlay` | 1 of 22 | `$FF` in the menu and the death sequence: no scroller, no BREAK, the menu tune loops | `Interrupt`, `Menu`, `MenuInterrupt` | `Menu`, `MenuInterrupt`, `MenuLoop` (`stage1/rec/rzx-00000`) |
| `$970E` | `MenuFlag` (`NotInPlay`+1) | 2 | non-zero: Interrupt runs MenuInterrupt instead of CheatCheck | `Interrupt` | `Menu`, `MenuLoop` (`stage1/rec/rzx-00000`) |
| `$9710` | `HudSaved` (`NotInPlay`+3) | 1 | `$FF` as loaded: the first Menu skips SaveHud (PlayPanel `$F600` still holds the loaded panel); Menu then sets 0, so every later Menu copies the screen's panel back to `$F600` (BuildTables overwrote it) | `Menu` | `Menu` |
| `$9711` | `MenuColours` (`NotInPlay`+4) | 16 | 16 colours for the menu's lit icon and bars | `MenuInterrupt` | - |
| `$9721` | `MenuColourCount` (`NotInPlay`+20) | 2 | the colour cycle's step | `MenuInterrupt` | `MenuInterrupt` |
| `$A89A` | `MapPointer` | 3 | RoomMaps + 240 x room + RoomScreen: the screen's first block | `DrawRoom`, `FindBlock` | `DrawRoom`, `NewGame` |
| `$AA72` | `LiftPlace` | 3 | The zone-0 lift's map address and direction (AnimateLift `$CA3D`) | `AnimateLift` | `FindLift`, `AnimateLift` (`stage1/rec/rzx-00000`) |
| `$AAA1` | `AnimatedCells` | 202 | The dirty-map addresses of the screen's animated characters, `$FF`xx at the end | `AnimatedCharList`, `MarkAnimated` | `AnimatedCharList` |
| `$ABB5` | `AnimatedChars` | 72 | The animated character codes of each zone, 0-terminated, and the four list pointers at `$ABF5` | `AnimatedCharList`, `FindNextBlock` (`stage1/rec/rzx-00000`) | `FindBlock` |
| `$AC7F` | `FloorRow` | 1 | the first character row with a solid attribute | `KindWave` (`stage1/rec/rzx-12000`), `SpawnWalker` (`stage1/rec/rzx-00000`) | `FindFloorRow` |
| `$AC9C` | `SpawnPoints` | 4 | Two map places of block `$61`, where kind-12 enemies rise | `SpawnRiser` (`stage1/rec/rzx-16000`) | `FindSpawnPoints` |
| `$ACDA` | `BlockItems` | 16 | Up to four block-`$1B` items of the screen (map address, place) | `TakeBlockItem` | `FindBlockItems`, `TakeBlockItem` (`stage1/rec/rzx-20000`) |

## entry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9210` | `BorderFlash` | 18 | BorderFlash | - | - |
| `$9222` | `TuneRequest` | 1 of 4 | The tune to start (1-4; 0 none), read by Interrupt on a 128K | `Interrupt`, `BeeperTick` (`stage1/rec/rzx-00000`) | `Interrupt`, `Menu`, `Death` (`stage1/rec/rzx-04000`), `GameOver` (`stage1/rec/rzx-08000`), `MenuLoop` (`stage1/rec/rzx-00000`) +1 |
| `$9223` | `StopRequest` (`TuneRequest`+1) | 1 | non-zero: MusicStop `$C00A` at the next interrupt; the game never writes it, its loaded `$FF` makes the first 128K interrupt call MusicStop once (c1) | `Interrupt` | `Interrupt` |
| `$9224` | `FrameCounter` (`TuneRequest`+2) | 1 | counted up by every interrupt; no instruction reads it | `Interrupt` | `Interrupt` |
| `$9225` | `BorderColour` (`TuneRequest`+3) | 1 | sent to `$FE` by every interrupt | `Interrupt`, `BeeperTick` (`stage1/rec/rzx-00000`) | `l_B257` (code) |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$92C3` | `RandomSeed` | 3 | Random's three bytes of state | `Random` | `Random` |
| `$92E0` | `EffectTable` | 252 | The 18 sound effects, 14 bytes each: the AY channel data, the channel choice (+`$0A`), the beeper pitch and length. PlayEffect `$93DC` picks record A; on a 128K bytes +`$0B`-+`$0D` go to the effect channel blocks of the player, on a 48K the record drives BeeperTick `$94C8`. The CSV is src/res/tables/effects.csv. | `PlayEffect`, `StartEffects`, `BeeperTick` (`stage1/rec/rzx-00000`) | - |
| `$941B` | `EffectSlots` | 6 | Three slots of (flag, record) for channels A, B and C | `StartEffects` | `PlayEffect`, `StartEffects` |
| `$946C` | `EffectStops` | 3 | Three flags: stop the effect of channel A, B, C at the next interrupt | `StopEffects`, `StopBeeper` (`stage1/rec/rzx-00000`) | `DrawRoom`, `StopEffects`, `Death` (`stage1/rec/rzx-04000`), `EndPenetrator` (`stage1/rec/rzx-00000`), `GameOver` (`stage1/rec/rzx-08000`) +3 |
| `$94AB` | `BeeperState` | 3 of 5 | The beeper effect: count, pitch, and the record pointer at `$94AE` that BeeperStart's own first instruction overwrites. BeeperStart at `$94AF` begins with the byte `$DD` of LD (`$94AE`),IX: the instruction stores the record's address over `$94AE-$94AF`, its own prefix. After the first effect the byte at `$94AF` is the record's high byte, so later calls run it as another instruction (SUB D or SUB E for the records at `$92`xx-`$93`xx) and then LD (`$94AE`),HL at `$94B0`: the store still happens. mkgame keeps `$94AB-$94AF` as data and the code from `$94B0` (known from the code and the 48K recording work/stage2/rec/c48). | `BeeperTick` (`stage1/rec/rzx-00000`) | `StopEffects`, `BeeperTick` (`stage1/rec/rzx-00000`), `StopBeeper` (`stage1/rec/rzx-00000`), `BeeperOff` (code), `BeeperStart` (code) |
| `$94AE` | `BeeperRecord` (`BeeperState`+3) | 2 | the record pointer (its high byte is BeeperStart's first byte) | `BeeperTick` (`stage1/rec/rzx-00000`) | `BeeperStart` (code) |
| `$CC5C` | `PassBcd` | 1 | A BCD pass counter (bit 0 times PENETRATOR's charges and the turret's bob) | `GameStart`, `HeldMasks` (`stage1/rec/rzx-28000`), `KindTurret` (`stage1/rec/rzx-00000`), `Penetrator` (`stage1/rec/rzx-00000`) | `GameStart` |
| `$CC5D` | `PassBcdSpare` | 35 | 35 zero bytes no routine reads | - | - |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$99F0` | `MenuLogo` | 480 | The menu's logo, 10 x 6 characters (Menu draws it at row 0, column 11) | `DrawGraphic` | - |
| `$9BD0` | `MenuBadge` | 16 | A 2 x 1 picture drawn at row 6, column 19 | `DrawGraphic` | - |
| `$9BE0` | `MenuBanner` | 192 | A 12 x 2 picture drawn at row 22, column 10 | `DrawGraphic` | - |
| `$9D01` | `ControlIconPlaces` | 21 of 25 | The menu rows and columns of the lit control icons | `DrawMenu`, `MenuInterrupt`, `Death` (`stage1/rec/rzx-04000`), `GameOver` (`stage1/rec/rzx-08000`) | `Death` (`stage1/rec/rzx-04000`), `GameOver` (`stage1/rec/rzx-08000`) |
| `$9D16` | `Hiscore` (`ControlIconPlaces`+21) | 4 | the high score, 4 BCD bytes | `DrawMenu`, `Death` (`stage1/rec/rzx-04000`), `GameOver` (`stage1/rec/rzx-08000`) | `Death` (`stage1/rec/rzx-04000`), `GameOver` (`stage1/rec/rzx-08000`) |
| `$9D6C` | `MenuStrings` | 164 | The 15 menu strings: two place bytes (column, then row: `$18`, `$09` for PROGRAM), the text with bit 7 on the last character. Includes "P.ENTER PASSWOID" as the bytes have it (the original's typo; the screen shows it, work/stage1/c1). | `DrawMenu`, `PrintString` | - |
| `$9E90` | `DefinePrompts` | 31 | "FIRE", "UP", "DOWN", "LEFT", "RIGHT" and "Press" | `PrintString` | - |
| `$9ED3` | `ColourSequences` | 91 | The colour sequences of ColourScroll | `l_9F2E` | `l_9F2E` |
| `$9F6D` | `PasswordFlags` | 4 of 21 | MAYHEM, TRANSMOGRIFY, VALKYR entered; `$9F70` PETALS OF DOOM (all three) | `CheatCheck`, `PasswordPods`, `EnterPassword` (`stage2/rec/play2`), `StringMatch` (`stage2/rec/play2`), `l_B46C` (`stage2/rec/door`) | `EnterPassword` (`stage2/rec/play2`), `MenuLoop` (`stage2/rec/door`) |
| `$9F71` | `PasswordBuffer` (`PasswordFlags`+4) | 17 | the 16 key codes typed, 0 at the end | `CheatCheck`, `StringMatch` (`stage2/rec/play2`) | `EnterPassword` (`stage2/rec/play2`) |
| `$9FF9` | `PasswordDots` | 16 | The 16 dots EnterPassword prints at row `$0A`, column `$08` | `PrintString` (`stage2/rec/play2`) | - |
| `$A009` | `Passwords` | 42 | MAYHEM, TRANSMOGRIFY, VALKYR, PETALS OF DOOM as key codes, each 0-terminated. Key code = row x 16 + bit (row 0 = port `$FEFE` ... row 7 = `$7FFE`). src/res/texts/passwords.txt has them as letters. | `BuildMessage` (`stage1/rec/rzx-00000`), `StringMatch` (`stage2/rec/play2`) | - |
| `$A081` | `KeysIf2` | 5 of 15 | Interface 2 keys (fire, up, down, left, right): 0 9 8 6 7 | `Menu`, `MenuLoop` (`stage2/rec/play2`) | `Menu` |
| `$A086` | `KeysCursor` (`KeysIf2`+5) | 5 | Cursor keys: 0 7 6 5 8 | `MenuLoop` (`stage2/rec/play2`) | - |
| `$A08B` | `KeysUser` (`KeysIf2`+10) | 5 | the keyboard set (DEFINE KEYS): SPACE P L Q W as loaded | `Menu` | `Menu` |
| `$A0F1` | `KeyChars` | 40 | The 40 keys' characters, by key code | `WaitKey`, `KeyCodeToChar` (`stage1/rec/rzx-00000`) | - |
| `$A138` | `Controls` | 1 of 3 | this pass's controls: bit 0 right, 1 left, 2 down, 3 up, 4 fire | `FireMask`, `MattCrouchState`, `MattStand`, `Menu`, `MenuInterrupt` +7 | `GameEntry`, `Menu`, `ReadControls`, `MenuLoop` (`stage2/rec/play2`), `l_A18E` (code) |
| `$A139` | `ControlsLast` (`Controls`+1) | 1 | the last pass's | `FireMask` | `ReadControls` |
| `$A13A` | `ControlMethod` (`Controls`+2) | 1 | 0 Kempston, 1 Interface 2, 2 Cursor, 3 keyboard | `Menu`, `MenuInterrupt`, `ReadControls`, `MenuLoop` (`stage1/rec/rzx-00000`) | `GameEntry`, `Menu`, `MenuLoop` (`stage2/rec/play2`) |
| `$A150` | `KeysNow` | 5 | The five keys in use (copied from KeysIf2, KeysCursor or KeysUser) | `AskKey`, `Menu`, `ReadControls`, `l_A155` (code), `l_A164` (code) +3 | `DefineKeys`, `Menu`, `MenuLoop` (`stage2/rec/play2`) |

## renderer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A194` | `ZoneSlots` | 4 | ZoneSlots[0] the live zone, [1-3] the zones parked at `$5B00`, `$6400`, `$6D00` | `AnimateZone`, `AnimatedCharList`, `DeadlyFloor`, `FindLift`, `MoonMasks` +6 | `SwapZone` (`stage1/rec/rzx-00000`) |
| `$A1EC` | `TurretStems` | 4 | One character a zone: the stem KindTurret draws under a turret (copied to TurretStem `$C26E`) | `SwapZone` (`stage1/rec/rzx-00000`) | - |
| `$A253` | `PickupSaves` | 120 of 125 | The backgrounds kept under the pick-up icons | `DrawObject`, `DrawObjects`, `MattPodDissolve`, `PlacePickup`, `RestoreOnePickup` +5 | `DrawObject`, `DrawObjects`, `DrawRoom`, `MattPodDissolve`, `NewGame` +12 |
| `$A2CB` | `PickupSavePtr` (`PickupSaves`+120) | 2 | the next free save | `DrawObject`, `DrawObjects` (`stage2/rec/kind6`) | `DrawObject`, `PlacePickups`, `l_A62D` (`stage1/rec/rzx-16000`) |
| `$A2CD` | `NextSpriteChar` (`PickupSaves`+122) | 1 | the next free sprite character | `DrawObject`, `DrawObjects` (`stage2/rec/kind6`) | `DrawObject`, `DrawObjects`, `l_A62D` (`stage1/rec/rzx-16000`) |
| `$A2CE` | `FirstSpriteChar` (`PickupSaves`+123) | 1 | the first sprite character of this pass | `DrawObjects`, `PlacePickup` | `DrawRoom`, `PlacePickup`, `DrawObject` (`stage2/rec/kind6`) |
| `$A2CF` | `DissolveCount` (`PickupSaves`+124) | 1 | non-zero: Matt is drawn dissolved (pods, penetrator, death) | `MattPodDissolve`, `SelectFrame`, `DrawObjects` (`stage2/rec/kind6`), `EndPenetrator` (`stage1/rec/rzx-00000`), `HeldMasks` (`stage1/rec/rzx-28000`) +1 | `MattPodDissolve`, `NewGame`, `PodStart`, `Death` (`stage1/rec/rzx-04000`), `DrawObject` (`stage2/rec/kind6`) +6 |
| `$A3EE` | `FrameJumpSpare` | 4 | Four unused bytes of the mode jump table | - | - |
| `$A3F4` | `FrameMode3Jump` | 2 | JR `$A3FE` (mode 3), never taken | - | - |
| `$A43F` | `Objects` | 38 of 304 | The 8 objects of `$26` bytes: Matt, Matt's shot `$A465`, the six others from `$A48B`. Fields: +0 kind (bit 7 placed; bit 6 only in the `$40` reservation after a turret, which DrawObjects and ShotHits skip with AND `$BF`), +2 direction (bit 7 left), +3 x (2 pixels a unit, column (x - `$40`) / 4), +4 y, +5 width and +6 height in characters, +9/+A buffer, +B first character, +C/+D frame, +E/+F save pointer, +10-+12 timers, +14/+15 the score it gives (BCD), +16/+17 the sprite base, +18 animation step, +19 mode (frame size), +1A animation mask, +1B dx, +1C dy, +1E damage to the energy, +1F once-a-room flag, +20 colour, +21 hits left, +22 hit by Matt's shot. Witness: read and written every pass (c1). | `CheckPickups`, `Dissolve`, `DrawObject`, `DrawObjects`, `FireMask` +74 | `Dissolve`, `DrawObject`, `DrawObjects`, `DrawRoom`, `FireMask` +74 |
| `$A465` | `MattShot` (`Objects`+38) | 38 | object 1: Matt's shot | `DrawObject`, `DrawObjects`, `FireMask`, `FrameByMode`, `HitsWall` +8 | `DrawObject`, `DrawObjects`, `FireMask`, `FrameByMode`, `MoveShot` +5 |
| `$A48B` | `Enemies` (`Objects`+76) | 228 | objects 2-7; as loaded and in room 0: state `$80`, x 1, y 0, w = h = 2, mode 0, frame `$0000`: drawn every pass off screen, about 12 300 T each | `DrawObject`, `DrawObjects`, `MakeMask`, `ReviveObjects`, `RunKind` +44 | `DrawObject`, `DrawObjects`, `DrawRoom`, `RunObjects`, `Spawn` +44 |
| `$CA35` | `TwinkleSteps` | 8 | The eight steps' states | `Twinkle` | `Twinkle` |
| `$CABD` | `AnimSteps` | 16 | Three counters: 0-7, 5-0, 0-11, and frame tables at `$CAC0` and `$CAC7` | `AnimateZone`, `l_CBBB` (`stage1/rec/rzx-00000`), `AnimateZone1` (code), `l_CB97` (code) | `AnimateZone` |
| `$CB41` | `AnimLast` | 1 | the last random frame (zone 1) | `AnimateZone` (`stage1/rec/rzx-12000`), `AnimateZone1` (code) | `AnimateZone` (`stage1/rec/rzx-12000`), `l_CB97` (code) |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AD7C` | `Messages` | 67 | GOOD LUCK MATT, CODE BROKEN, PASSWORD IS and the message buffer `$ADAF` | `ScrollerNextChar`, `ShowMessage`, `BuildMessage` (`stage1/rec/rzx-00000`) | `BuildMessage` (`stage1/rec/rzx-00000`) |
| `$AE1D` | `EndTexts` | 36 | YOU HAVE FOUND SCOTT and WELL DONE | `SlowPrint` (`stage1/rec/rzx-36000`) | - |
| `$AE41` | `Score` | 4 | 4 BCD bytes | `DrawScore`, `AddScore` (`stage1/rec/rzx-00000`), `Death` (`stage1/rec/rzx-04000`), `GameOver` (`stage1/rec/rzx-08000`) | `NewGame`, `AddScore` (`stage1/rec/rzx-00000`) |
| `$AEA6` | `Energy` | 1 of 2 | Matt's energy, `$FF` full, 0 dead | `DrawEnergyBar`, `GameStart`, `Damage` (`stage1/rec/rzx-00000`), `HeldMasks` (`stage1/rec/rzx-16000`), `LavaDrain` (`stage1/rec/rzx-12000`) +2 | `DrawEnergyBar`, `NewGame`, `Damage` (`stage1/rec/rzx-00000`), `HeldMasks` (`stage1/rec/rzx-16000`), `LavaDrain` (`stage1/rec/rzx-12000`) +2 |
| `$AEA7` | `EnergyShown` (`Energy`+1) | 1 | the energy last drawn | `DrawEnergyBar` | `DrawEnergyBar` |
| `$AF04` | `EnergyParts` | 8 of 79 | The 8 partial-cell patterns | `CheckPickups`, `DrawAllSlots`, `DrawCurrentSlot`, `DrawEnergyBar`, `DrawIcon` +25 | `CheckPickups`, `DrawAllSlots`, `GameStart`, `MaskKeys`, `Menu` +12 |
| `$AF0C` | `PassCounter` (`EnergyParts`+8) | 2 | counted up every main loop pass (the icon blink, the jump's timing) | `DrawAllSlots`, `DrawIcon`, `GameStart`, `MattJumpRise` (`stage1/rec/rzx-28000`), `l_B8A7` (`stage1/rec/rzx-28000`) | `DrawAllSlots`, `GameStart`, `MaskKeys` |
| `$AF0E` | `MaskNameShown` (`EnergyParts`+10) | 1 | the mask name on the scroller | `ShowMaskName`, `MaskKeys` (`stage1/rec/rzx-04000`) | `NewGame`, `ShowMaskName`, `ShowMessage`, `MaskKeys` (`stage1/rec/rzx-04000`) |
| `$AF0F` | `ScrollerLeft` (`EnergyParts`+11) | 1 | characters left to scroll | `Scroller`, `ScrollerNextChar` | `Menu`, `Scroller`, `ScrollerNextChar`, `l_B0EA`, `MenuLoop` (`stage1/rec/rzx-00000`) +2 |
| `$AF10` | `ScrollerPtr` (`EnergyParts`+12) | 2 | the next character | `ScrollerNextChar` | `Scroller`, `ScrollerNextChar`, `l_B0EA`, `ShowMaskName` (`stage1/rec/rzx-16000`), `ShowMessage` (`stage2/rec/play2`) |
| `$AF12` | `ScrollerShift` (`EnergyParts`+14) | 9 | the pixel step | `Scroller`, `l_B0EA`, `ShowMaskName` (`stage1/rec/rzx-16000`), `ShowMessage` (`stage2/rec/play2`) | `Menu`, `Scroller`, `ScrollerNextChar`, `l_B0EA`, `MenuLoop` (`stage1/rec/rzx-00000`) +2 |
| `$AF1B` | `PickupRecords` (`EnergyParts`+23) | 16 | two pick-up records of 8 bytes | `CheckPickups`, `PlaceOnePickup`, `PlacePickup`, `RestoreOnePickup` | `CheckPickups`, `PlacePickup` |
| `$AF2B` | `MaskSlots` (`EnergyParts`+39) | 16 | four slots [screen column, kind, BCD charges, level] | `CheckPickups`, `DrawCurrentSlot`, `FireMask`, `MaskKeys`, `MattFall` +10 | `CheckPickups`, `NewGame`, `UseCharge`, `DrawObject` (`stage2/rec/cheat`), `DrawObjects` (`stage2/rec/masks`) +1 |
| `$AF3B` | `MaskLevels` (`EnergyParts`+55) | 11 | the level a kind starts with, per kind 0-10 | `CheckPickups` | - |
| `$AF46` | `MaskColours` (`EnergyParts`+66) | 11 | the icon colour per kind | `DrawIcon`, `PlacePickup` | - |
| `$AF51` | `CurrentSlot` (`EnergyParts`+77) | 2 | the MaskSlots slot in use | `CheckPickups`, `DrawAllSlots`, `DrawCurrentSlot`, `FireMask`, `MattFall` +6 | `DrawAllSlots`, `MaskKeys`, `NewGame` |
| `$B0FB` | `MessageState` | 4 | the message scroller's state | `Scroller` | `Menu`, `ShowMaskName`, `ShowMessage`, `MaskKeys` (`stage1/rec/rzx-04000`), `MenuLoop` (`stage1/rec/rzx-00000`) |
| `$B197` | `MaskNames` | 121 | The 11 names of 11 characters: EMPTY, PENETRATOR, ULTRA FLASH, MIRAGE, HEALER, JACKRABBIT, LIFTER, BLASTER, BACKLASH, LAVA SHOT, STREAMER | `ScrollerNextChar` | - |
| `$B238` | `UnusedFlag` | 1 | A flag of the never-run MaskEffect | `MaskEffect` (code) | `MaskEffect` (code) |
| `$B2F8` | `DeathFlag` | 1 | non-zero: Matt dies this pass (MainLoop jumps to Death) | `GameStart` | `NewGame`, `DeadlyFloor` (`stage1/rec/rzx-04000`), `MoonFloor` (`stage1/rec/rzx-28000`), `l_B403` (code) |
| `$B3E6` | `MattPlace` | 4 of 5 | Matt's map places: `$B3E6` and `$B3E8` (character map addresses) | `DeadlyFloor`, `EndPenetrator`, `FloorCheck`, `MattFall`, `TakeBlockItem` +10 | `MattCell`, `MattCellAhead`, `NewGame`, `EndPenetrator` (`stage1/rec/rzx-00000`), `HeldMasks` (`stage1/rec/rzx-28000`) +1 |
| `$B3EA` | `PenetratorOn` (`MattPlace`+4) | 1 | non-zero while PENETRATOR is used: Matt walks through walls | `EndPenetrator`, `MattFall`, `TakeBlockItem`, `l_B4C0`, `HeldMasks` (`stage1/rec/rzx-28000`) +5 | `NewGame`, `EndPenetrator` (`stage1/rec/rzx-00000`), `HeldMasks` (`stage1/rec/rzx-28000`), `Penetrator` (`stage1/rec/rzx-00000`) |
| `$BE0D` | `PenetratorCost` | 1 | Extra charges of the next PENETRATOR step: KindChaser `$C68E` sets `$10` (BCD, 10 charges) every pass it runs while PenetratorOn; Penetrator `$BE23` adds it to (PassBcd AND 1) and clears it | `HeldMasks` (`stage1/rec/rzx-28000`), `Penetrator` (`stage1/rec/rzx-00000`) | `HeldMasks` (`stage1/rec/rzx-28000`), `Penetrator` (`stage1/rec/rzx-00000`), `l_C683` (code) |
| `$BE3B` | `EnemyTemplates` | 240 | 20 records of 12 bytes: score (BCD word), picture, damage, animation, mask, width, height, mode, hits, colour. Copied into an object by SetupObject `$BFF5`: +`$14`/+`$15`, +`$16`/+`$17`, +`$1E`, +`$18`, +`$1A`, +5, +6, +`$19`, +`$21`, +`$20` (bit 7 set: a random colour 1-7). Byte 10, the hits: 255 = never shot down (template 13, kind 10). Also src/res/tables/enemies.csv. | `SetupObject` (`stage1/rec/rzx-00000`) | - |
| `$BFB0` | `EnemyKind` | 1 | The screen's enemy kind (RoomTable bytes 6-11) | `Spawn` | `DrawRoom`, `DrawObject` (`stage2/rec/door3`), `DrawObjects` (`stage2/rec/kind6`), `SlowPrint` (`stage2/rec/door3`) |
| `$BFB2` | `SpawnJumpPad` | 2 | Two bytes after kind 0's RET | - | - |
| `$C0D6` | `ChaserState` | 3 | one chaser at a time, and its timer (`$0300`) | `DrawRoom`, `PlaceTurrets`, `Spawn`, `KindChaser` (`stage1/rec/rzx-08000`), `SpawnChaser` (`stage1/rec/rzx-08000`) | `DrawRoom`, `NewGame`, `KindChaser` (`stage1/rec/rzx-08000`), `SpawnChaser` (`stage1/rec/rzx-08000`) |
| `$C1F1` | `SpawnPad` | 2 | Two zero bytes | - | - |
| `$C26E` | `TurretStem` | 1 | The zone's turret stem character (SwapZone writes TurretStems[zone] here); KindTurret draws it under a turret | `KindTurret` (`stage1/rec/rzx-00000`) | `SwapZone` (`stage1/rec/rzx-00000`) |
| `$C341` | `KindNineJump` | 3 | KindNineJump | - | - |
| `$C5B5` | `WaveHeights` | 36 | 18 heights and 18 animation steps of the wave | `KindWave` (`stage1/rec/rzx-12000`) | - |

## matt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BA1D` | `WarpRooms` | 4 | The room behind each password door: 0B 03 07 07 | `PasswordWarp` (`stage2/rec/door`) | - |
| `$BAA7` | `Dying` | 1 | non-zero while Matt dies | `FireMask`, `MaskKeys`, `l_B403` | `NewGame`, `Death` (`stage1/rec/rzx-04000`), `EndPenetrator` (`stage2/rec/masks`), `GameStart` (`stage1/rec/rzx-08000`) |
| `$BB01` | `GameOverText` | 18 | MISSION TERMINATED | `SlowPrint` (`stage1/rec/rzx-04000`) | - |
| `$BB6B` | `CheatCode` | 12 of 13 | The cheat password JUDGE DREDD as key codes, 0-terminated, and CheatOn `$BB77` | `CheatCheck`, `DeadlyFloor`, `UseCharge` | `CheatCheck` |
| `$BB77` | `CheatOn` (`CheatCode`+12) | 1 | `$FF` when the cheat password was typed | `DeadlyFloor`, `UseCharge` | `CheatCheck` |
| `$BC8E` | `DotBits` | 8 | The eight pixel bits | `PlotDot` (`stage2/rec/masks`) | - |

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CC80` | `ControlIcons` | 224 | Seven 2 x 2 pictures: the four control icons of the menu and three more. DrawMenu `$9D1A` draws the icons of the four control methods; the lit one blinks in MenuInterrupt. Witness: c1 menu. | `DrawGraphic` | - |
| `$CD60` | `MattRun` | 1024 | Matt running: 8 frames of 4 x 4 characters (32 x 32 pixels). SelectFrame picks frame ((x / 4) & 7), backwards when he faces left. Witness: every pass of play (c1). | `DrawObject`, `MakeMask`, `MirrorFrame`, `Dissolve` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D160` | `MattJump` | 128 | Matt jumping or falling (states 8, 10, 12), 4 x 4 | `Dissolve`, `DrawObject`, `MakeMask`, `MirrorFrame`, `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D1E0` | `MattCrouch` | 128 | Matt crouching (state 4), 4 x 4 | `DrawObject`, `MakeMask`, `Dissolve` (`stage1/rec/rzx-32000`), `MirrorFrame` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D260` | `SpriteFaller` | 128 | Enemy kinds 1 and 12 (templates `$BE3B`, `$BE9B`): 4 frames of 2 x 2 | `MakeMask`, `DrawObject` (`stage1/rec/rzx-00000`), `MirrorFrame` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D2E0` | `SpriteFlyer` | 192 | Enemy kind 2 (`$BE47`): 4 frames of 3 x 2 | `DrawObject` (`stage1/rec/rzx-04000`), `MakeMask` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D3A0` | `Digits` | 160 | The score digits 0-9, 1 x 2 characters (16 bytes) each (DrawDigit `$AE78`) | `DrawDigit`, `MakeMask` (`stage1/rec/rzx-04000`) | - |
| `$D440` | `SpriteExplosion` | 128 | The explosion (`$BEFB`): 4 frames of 2 x 2 | `DrawObject` (`stage1/rec/rzx-00000`), `MakeMask` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D4C0` | `SpriteExplosion2` | 192 | The big explosion (`$BF07`): 4 frames of 3 x 2 | `DrawObject` (`stage1/rec/rzx-00000`), `MakeMask` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D580` | `MaskIcons` | 352 | The 11 mask icons (EMPTY and the ten masks), 2 x 2 each (DrawIcon `$B024`, PlacePickup `$A9DA`) | `DrawIcon`, `PlacePickup`, `MakeMask` (`stage1/rec/rzx-00000`) | - |
| `$D6E0` | `SpriteShots` | 192 | Matt's shots: 6 frames of 2 x 2, one a mask kind 5-10 (FireMask sets the animation to kind - 5) | `DrawObject`, `MakeMask`, `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D7A0` | `SpriteTurret` | 192 | The turret (kind 4, `$BE53`): 4 frames of 3 x 2 | `DrawObject` (`stage1/rec/rzx-00000`), `MakeMask` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D860` | `SpriteTurretShot` | 64 | The turret's shot (kind 5, `$BE5F`): 8 frames of 1 x 1 | `DrawObject` (`stage1/rec/rzx-00000`), `MakeMask` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | - |
| `$D8A0` | `SpriteWave` | 192 | The wave flyer (kind 6, `$BE6B`): 6 frames of 2 x 2 | `DrawObject` (`stage1/rec/rzx-00000`), `MakeMask` (`stage1/rec/rzx-00000`) | - |
| `$D960` | `SpriteWalker` | 128 | The walker (kind 7, `$BE77`): 4 frames of 2 x 2 | `DrawObject` (`stage1/rec/rzx-00000`), `MakeMask` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-28000`) | - |
| `$D9E0` | `SpriteChaser` | 192 | The chaser (kind 8, `$BE83`): one picture of 8 x 3 | `DrawObject` (`stage1/rec/rzx-08000`), `MakeMask` (`stage1/rec/rzx-00000`) | - |
| `$DAA0` | `SpriteKind16` | 192 | Kind 16's picture (`$BE8F`, spawned only by a POKE in work/stage2/rec/kind6): 4 frames of 2 x 3 | `DrawObject` (`stage2/rec/kind6`), `MakeMask` (`stage1/rec/rzx-08000`) | - |
| `$DB60` | `SpriteBig` | 96 | One 4 x 3 picture (`$BECB`) | `DrawObject` (`stage2/rec/kind6`), `MakeMask` (`stage2/rec/kind6`) | - |
| `$DBC0` | `SpriteGuard` | 128 | The guard (kind 13, `$BEA7`): one picture of 4 x 4 | `DrawObject` (`stage1/rec/rzx-00000`), `MakeMask` (`stage1/rec/rzx-00000`) | - |
| `$DC40` | `SpritePart1` | 288 | Kind 18's picture (`$BF13`): 4 frames of 3 x 3 | `DrawObject` (`stage1/rec/rzx-08000`), `MakeMask` (`stage1/rec/rzx-00000`) | - |
| `$DD60` | `SpritePart2` | 288 | Kind 19's picture (`$BF1F`): 4 frames of 3 x 3 | `DrawObject` (`stage1/rec/rzx-08000`), `MakeMask` (`stage1/rec/rzx-08000`) | - |
| `$DE80` | `SpriteSmall1` | 96 | Three 2 x 2 pictures (`$BED7`, `$BEE3`, `$BEEF`) | `DrawObject` (`stage2/rec/door3`), `MakeMask` (`stage1/rec/rzx-08000`) | - |
| `$DEE0` | `SpriteBoss` | 128 | The boss (kind 14, `$BEB3`): one picture of 4 x 4 | `DrawObject` (`stage1/rec/rzx-24000`), `MakeMask` (`stage1/rec/rzx-08000`) | - |
| `$DF60` | `SpriteBossShot` | 32 | The boss's shot (`$BEBF`): one picture of 2 x 2 | `DrawObject` (`stage1/rec/rzx-24000`), `MakeMask` (`stage1/rec/rzx-08000`) | - |

## buffers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DF80` | `DissolveBuffer` | 128 | 128 bytes: Dissolve's frame | `Dissolve`, `DrawObject`, `MakeMask`, `MirrorFrame` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-28000`) | `Dissolve` |
| `$E000` | `ZoneChars` | 2048 | The live zone's 256 characters: zone 0's as loaded | `AnimateZone`, `DrawObject`, `MakeMask`, `l_A1FC`, `SwapZone` (`stage1/rec/rzx-00000`) +1 | `AnimateZone`, `Twinkle`, `SwapZone` (`stage1/rec/rzx-00000`), `l_CBBB` (`stage1/rec/rzx-00000`) |
| `$E800` | `SpriteChars` | 1536 | The sprite characters DrawObject allocates; as loaded 1536 bytes of leftovers. DrawObject `$A56F` writes every sprite character from `$E800` up before FlushDirty reads it; the loaded bytes are never read (known only from the code). | `DrawObject`, `l_A1FC`, `Explosion` (`stage2/rec/masks`), `l_A66C` (`stage1/rec/rzx-16000`) | `DrawObject`, `PlacePickup`, `Explosion` (`stage2/rec/masks`), `l_A66C` (`stage1/rec/rzx-16000`) |
| `$EE00` | `Zone1Attrs` | 256 | Zone 1's attributes, copied to `$6300` by GameEntry; then the sprite characters' attributes | `DrawObject`, `GameEntry`, `l_A1FC` | `DrawObject`, `PlacePickup` |
| `$EF00` | `ZoneAttrs` | 256 | The live zone's attributes (bit 7 solid): zone 0's as loaded | `DrawObject`, `FindFloorRow`, `IsSolid`, `l_A1FC`, `SwapZone` (`stage1/rec/rzx-00000`) | `GameEntry`, `SwapZone` (`stage1/rec/rzx-00000`) |
| `$F000` | `Zone1CharsLow` | 128 of 1280 | Zone 1's characters 0-159, copied to `$5B00` by GameEntry; then the masks, the character map (`$F080`) and the dirty map (`$F3C0`) | `AnimatedCharList`, `ColourScroll`, `DeadlyFloor`, `DrawObject`, `DrawRoom` +17 | `ColourScroll`, `DrawObject`, `DrawObjects`, `DrawRoom`, `FlushDirty` +13 |
| `$F080` | `CharMap` (`Zone1CharsLow`+128) | 640 | at run time: the character map, 32 x 20 character codes; row 2 (`$F0C0`) is screen row 0 | `AnimatedCharList`, `ColourScroll`, `DeadlyFloor`, `DrawObject`, `FindFloorRow` +14 | `ColourScroll`, `DrawObject`, `DrawObjects`, `DrawRoom`, `MattStep` +9 |
| `$F300` | `MirrorBuffer` (`Zone1CharsLow`+768) | 192 | at run time: MirrorFrame's mirrored frame | `ColourScroll`, `DrawObject`, `GameEntry`, `MakeMask`, `Menu` +3 | `FlushDirty`, `Menu`, `MirrorFrame`, `l_9F2E`, `DrawObject` (`stage1/rec/rzx-00000`) +1 |
| `$F3C0` | `DirtyMap` (`Zone1CharsLow`+960) | 320 | at run time: the dirty marks, 32 x 18, one a shown cell (1 the zone character, 2 a sprite character), to `$F5FF` | `DrawObject`, `DrawRoom`, `GameEntry`, `l_A1FC`, `DeadlyFloor` (`stage1/rec/rzx-16000`) +2 | `DrawObject`, `DrawRoom`, `l_A1FC`, `KindTurret` (`stage1/rec/rzx-00000`), `MarkAnimated` (`stage1/rec/rzx-00000`) +1 |
| `$F500` | `LeftoverF500` | 256 | 256 bytes of leftovers, cleared as the dirty map before any read | `DrawObject`, `DrawRoom`, `l_A1FC`, `DeadlyFloor` (`stage1/rec/rzx-08000`), `IsSolid` (`stage1/rec/rzx-08000`) +1 | `DrawObject`, `DrawRoom`, `PlaceOnePickup`, `l_A1FC`, `AnimateLift` (`stage1/rec/rzx-00000`) +2 |
| `$F600` | `PlayPanel` | 256 of 1536 | The play panel (rows 18-23, 32 x 6 characters), drawn by Menu at the first start; then BuildTables' tables | `DrawGraphic`, `DrawObject`, `MakeMask`, `MirrorFrame`, `l_A66C` (`stage1/rec/rzx-16000`) | `BuildTables`, `SaveHud` (`stage1/rec/rzx-04000`) |
| `$F700` | `Dilate` (`PlayPanel`+256) | 256 | at run time: the dilate table of MakeMask | `DrawGraphic`, `MakeMask` | `BuildTables`, `SaveHud` (`stage1/rec/rzx-04000`) |
| `$F800` | `ShiftTables` (`PlayPanel`+512) | 1024 | at run time: three page pairs, each byte shifted 2, 4 or 6 pixels and the bits pushed out, to `$FDFF` | `DrawGraphic`, `DrawObject`, `l_A66C` (`stage1/rec/rzx-16000`) | `BuildTables`, `SaveHud` (`stage1/rec/rzx-04000`) |
| `$FC00` | `LeftoverFC00` | 100 | 100 bytes between the panel and its attributes (overwritten by BuildTables) | `DrawObject` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | `BuildTables` |
| `$FC64` | `PanelAttrs` | 192 | The panel's attributes, 6 rows of 32 | `Menu`, `DrawObject` (`stage1/rec/rzx-00000`), `MenuLoop` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | `BuildTables`, `SaveHud` (`stage1/rec/rzx-04000`) |
| `$FD24` | `LeftoverFD24` | 220 | 220 bytes of leftovers, overwritten by BuildTables' shift tables | `DrawObject` (`stage1/rec/rzx-00000`), `l_A66C` (`stage1/rec/rzx-16000`) | `BuildTables` |
