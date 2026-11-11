# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1g` (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: Bank 3, Bank 4, Bank 6, Bank 7, Tape BASIC, Decryption chain and
loader, Loader stage 2, Loader block 37, Loader block 39) follow the game, each under its own heading with its
modules, its source, its annotations and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`system`](11-data-reference.md#system) | `$5B00`-`$5BFF` | 0 of 1 |
| [`mathtables`](11-data-reference.md#mathtables) | `$5C00`-`$6797` | 0 of 21 |
| [`gamevars`](11-data-reference.md#gamevars) | `$6798`-`$67BD` | 0 of 1 |
| [`apivectors`](#apivectors) | `$67BE`-`$68F3` | 21 of 24 |
| [`boot`](#boot) | `$68F4`-`$694A` | 2 of 2 |
| [`missionflow`](#missionflow) | `$694B`-`$6CE3`, `$CE68`-`$CEA3`, `$D52E`-`$D673`, `$DA8C`-`$FFFF` | 32 of 38 |
| [`text`](#text) | `$6CE4`-`$703F`, `$7C59`-`$7D50` | 34 of 41 |
| [`screens`](#screens) | `$7040`-`$70C5` | 10 of 11 |
| [`catalogue`](#catalogue) | `$70C6`-`$71F0` | 10 of 14 |
| [`tape`](#tape) | `$71F1`-`$7224`, `$8617`-`$87D5` | 5 of 7 |
| [`paging`](#paging) | `$7225`-`$72F3` | 24 of 24 |
| [`hud`](#hud) | `$72F4`-`$7C58` | 23 of 29 |
| [`interrupt`](#interrupt) | `$7D51`-`$7FFF`, `$8383`-`$84C0`, `$87D6`-`$898A` | 28 of 39 |
| [`bootstrap`](#bootstrap) | `$8000`-`$8382` | 1 of 7 |
| [`missionload`](#missionload) | `$84C1`-`$8616` | 7 of 8 |
| [`raster`](#raster) | `$898B`-`$9714`, `$A184`-`$A8C6`, `$AA27`-`$AA46` | 46 of 47 |
| [`input`](#input) | `$9715`-`$9881` | 10 of 14 |
| [`render`](#render) | `$9882`-`$A183`, `$AA47`-`$AD44` | 46 of 54 |
| [`player`](#player) | `$A8C7`-`$A9FD`, `$B550`-`$B610`, `$B8AB`-`$B8B0`, `$B8B9`-`$B915`, `$BF24`-`$BF52`, `$C113`-`$C484`, `$C510`-`$C647`, `$CAA5`-`$CC3B`, `$CF26`-`$D52D` | 99 of 115 |
| [`objects`](#objects) | `$A9FE`-`$AA26`, `$B3C9`-`$B54F`, `$B766`-`$B8AA`, `$B8B1`-`$B8B8`, `$B916`-`$B9F5`, `$BBF0`-`$BF23`, `$BF53`-`$C112`, `$C485`-`$C50F`, `$C648`-`$CAA4` | 51 of 56 |
| [`world`](#world) | `$AD45`-`$B3C8`, `$B9F6`-`$BBEF`, `$CC3C`-`$CE67`, `$CEA4`-`$CF25`, `$D8D4`-`$DA8B` | 52 of 56 |
| [`enemies`](#enemies) | `$B611`-`$B765` | 11 of 12 |
| [`sound`](#sound) | `$D674`-`$D8D3` | 18 of 20 |

## apivectors

`src/game/apivectors.asm`

### `ApiVector00` (`$67BE`)

**The mission code's service vectors: 22 JP instructions, `$67BE-$67FF`**

Each vector is a `JP` to a resident routine in bank 2 or 5: `$67BE` `$BFD1`, `$67C1` `$B766`, `$67C4` `$BCDA`, `$67C7` `$BD41`, `$67CA` `$C957`, `$67CD` `$CA3B`, `$67D0` `$A779`, `$67D3` `$A7AE`, `$67D6` `$A799`, `$67D9` `$A82C`, `$67DC` `$B660`, `$67DF` `$B6D1`, `$67E2` `$B282`, `$67E5` `$B6BD`, `$67E8` `$A899`, `$67EB` `$B611`, `$67EE` `$7040`, `$67F1` `$CC3C`, `$67F4` `$AA63`, `$67F7` `$AB7B`, `$67FA` `$AAF5`, `$67FD` `$AA47`. The mission code calls them (play: `$67D9` 220 482 times, `$67D6` 179 580).

Witness: L1 53953 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 632 calls, 9,006 t-states own (0.00 %) |
| Runs (the other recordings) | 14,450 calls (`stage1/death` 8,892, `stage1/play2` 2,342, `stage1/play` 1,779 and 2 more) |
| Called from | `PlayerStep`, `CannonShellStep` (tail), `MortarShellStep`, `RunObjectHandlers`, `DragonflyStep` (tail), `PlayerHit`, `BounceDecay`, `ClusterRise`, `MineFall`, `SkeetStraight`, `SkeetZigZag`, `SpectreStep`, `SpectreDrift`, `PhantasmStep`, `HelicarrierWait`, `MissionHeader` (tail) |
| Calls | `MoveObject` (tail) |

### `ApiVector01` (`$67C1`)

**ApiVector01**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 6,516 t-states own (0.00 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `TargetInConeBody`, `TurnToward`, `MissionHeader` |
| Calls | `BearingTo` (tail) |

### `ApiVector02` (`$67C4`)

**ApiVector02**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 17 calls, 183 t-states own (0.00 %) |
| Runs (the other recordings) | 219 calls (`stage1/missions` 74, `stage1/play2` 64, `stage1/play` 50 and 2 more) |
| Called from | `MissionHeader` |
| Calls | `FindFreeObject` (tail) |

### `ApiVector03` (`$67C7`)

**ApiVector03**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 357 t-states own (0.00 %) |
| Runs (the other recordings) | 431 calls (`stage1/missions` 125, `stage1/death` 119, `stage1/play2` 103 and 2 more) |
| Called from | `FireCannon`, `LaunchProjectile`, `ActivateMissionObjects`, `LaunchDragonfly`, `SkeetFire`, `PlaceHelicarrier`, `MissionHeader` |
| Calls | `ObjectSetType` (tail) |

### `ApiVector04` (`$67CA`)

**ApiVector04**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 360 t-states own (0.00 %) |
| Runs (the other recordings) | 431 calls (`stage1/missions` 125, `stage1/death` 119, `stage1/play2` 103 and 2 more) |
| Called from | `FireCannon`, `LaunchProjectile`, `ActivateMissionObjects`, `LaunchDragonfly`, `SkeetFire`, `PlaceHelicarrier`, `MissionHeader` |
| Calls | `RegisterCollision` (tail) |

### `ApiVector05` (`$67CD`)

**ApiVector05**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 13 calls, 188 t-states own (0.00 %) |
| Runs (the other recordings) | 230 calls (`stage1/death` 114, `stage1/play2` 51, `stage1/play` 48 and 2 more) |
| Called from | `KillTree`, `HitTest`, `RemoveObject`, `ActivateMissionObjects`, `FindSlot`, `PlaceHelicarrier`, `MissionHeader` |
| Calls | `UnregisterCollision` (tail) |

### `ApiVector06` (`$67D0`)

**ApiVector06**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 52 calls, 656 t-states own (0.00 %) |
| Runs (the other recordings) | 532 calls (`stage1/play2` 168, `stage1/death` 159, `stage1/missions` 97 and 2 more) |
| Called from | `Debris`, `DebrisVelocity`, `DebrisVelocityB`, `PlayerHit`, `SpectreStep`, `MissionHeader` |
| Calls | `Random` (tail) |

### `ApiVector07` (`$67D3`)

**ApiVector07**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 680 calls, 8,895 t-states own (0.00 %) |
| Runs (the other recordings) | 17,513 calls (`stage1/death` 9,455, `stage1/play` 3,393, `stage1/play2` 2,339 and 2 more) |
| Called from | `ResetViewOrigin`, `BearingOctant`, `CameraSinCos`, `RadarAddBlip`, `MissionHeader` |
| Calls | `NegateHL` (tail) |

### `ApiVector08` (`$67D6`)

**ApiVector08**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,328 calls, 77,311 t-states own (0.01 %) |
| Runs (the other recordings) | 173,252 calls (`stage1/death` 109,476, `stage1/play2` 22,376, `stage1/missions` 21,130 and 2 more) |
| Called from | `PlayerStep`, `TestVertexNearX`, `LaunchProjectile`, `ShowMortarRange`, `InRange`, `TargetInConeBody`, `TurnToward`, `TerrainDiagonal`, `BoundaryCheck`, `SetAwolState`, `EngineTone`, `MissionHeader` |
| Calls | `AbsA` (tail) |

### `ApiVector09` (`$67D9`)

**ApiVector09**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 9,736 calls, 141,530 t-states own (0.02 %) |
| Runs (the other recordings) | 210,746 calls (`stage1/death` 120,834, `stage1/play2` 37,372, `stage1/play` 27,268 and 2 more) |
| Called from | `BoxRect16`, `RotateToView`, `MissionHeader` |
| Calls | `MulWordByte` (tail) |

### `ApiVector10` (`$67DC`)

**ApiVector10**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 153 calls (`stage1/missions` 146, `stage1/death` 6, `stage1/play2` 1) |
| Called from | `CollisionPass`, `MissionHeader` (tail) |
| Calls | `HitTest` (tail) |

### `ApiVector11` (`$67DF`)

**ApiVector11**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/death` 12, `stage1/play2` 1) |
| Called from | `KillTree`, `HitTest`, `Explode` |
| Calls | `Debris` (tail) |

### `ApiVector12` (`$67E2`)

**ApiVector12**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,932 calls, 24,817 t-states own (0.00 %) |
| Runs (the other recordings) | 33,809 calls (`stage1/death` 13,488, `stage1/play` 7,416, `stage1/play2` 6,270 and 2 more) |
| Called from | `TerrainScanLoop`, `TerrainDiagonal`, `MissionHeader` |
| Calls | `ByteToWorld` (tail) |

### `ApiVector13` (`$67E5`)

**ApiVector13**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/death` 4) |
| Called from | `KillMissionObject` |
| Calls | `MarkDestroyed` (tail) |

### `ApiVector14` (`$67E8`)

**ApiVector14**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,442 calls, 35,842 t-states own (0.01 %) |
| Runs (the other recordings) | 56,373 calls (`stage1/death` 29,045, `stage1/missions` 9,030, `stage1/play2` 8,907 and 6 more) |
| Called from | `OpPolarPoints`, `BoxRect`, `BoxTilted`, `RotateVertex`, `RotateAndStore`, `ShowMortarRange`, `GridVectors`, `SetElevation`, `PlaceHelicarrier`, `MissionHeader` |
| Calls | `SinCos8` (tail) |

### `ApiVector16` (`$67EE`)

**ApiVector16**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/menu` 4, `stage1/missions` 1, `stage1/m10` 1) |
| Called from | `PointerZones` |
| Calls | `ScreenFour` (tail) |

### `ApiVector17` (`$67F1`)

**ApiVector17**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 381 calls, 4,820 t-states own (0.00 %) |
| Runs (the other recordings) | 5,854 calls (`stage1/death` 2,846, `stage1/play2` 1,264, `stage1/play` 842 and 2 more) |
| Called from | `PlayerStep`, `MissionHeader` |
| Calls | `TerrainCollision` (tail) |

### `ApiVector18` (`$67F4`)

**ApiVector18**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 2,235 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/missions` 17) |
| Called from | `OpNative`, `BoxSquareTurret` |
| Calls | `BoxSquare` (tail) |

### `ApiVector19` (`$67F7`)

**ApiVector19**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 5,421 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/play2`, `stage1/death`, `stage1/missions` and 6 more) |
| Called from | `OpNative` |
| Calls | `BoxRect` (tail) |

### `ApiVector20` (`$67FA`)

**ApiVector20**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 2,234 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/death`, `stage1/play2`, `stage1/play` and 1 more) |
| Called from | `OpNative` |
| Calls | `BoxRect16` (tail) |

### `ApiVector21` (`$67FD`)

**ApiVector21**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/missions`) |
| Called from | `OpNative` |
| Calls | `BoxSquareTurret` (tail) |

## boot

`src/game/boot.asm`

### `Entry` (`$68F4`)

**The game's entry from the bootstrap: stack, IM 2 table, border, then the title menu in bank 6**

Under `DI`: `SP` = `$81FF`, the 257-byte vector table `$8200-$8300` filled with `$83` (`I` = `$82`, every vector `$8383`), `JP $8383` at `$8181`, `IM 2`, `EI`; the border to black (`BorderBlack` `$6CEB`), bank 6 paged, `JP $C409` (the title menu). The eight `NOP`s at `$691A` are room left for a patch.

Witness: c1 frame 23974 (the bootstrap's `JP $68F4`, docs/03-build-and-load.md); no recording after the entry runs it (L1 0).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 6,195 t-states own (0.00 %) |
| Called from | `Bootstrap` |
| Calls | `BorderBlack`, `PageBank6` |
| Reads | `$8200`-`$82FF` (`Im2Table`) |
| Writes | `$8181`-`$8183` (`ImJump`); `$8200`-`$8300` (`Im2Table`) |

### `ResetCollisionTables` (`$6928`)

**Reset the collision tables of bank 0 before a mission: clear bit 7 of `$C774-$C78A`, fill `$C648-$C773` with `$FF`, point the camera at the player**

Called from bank 6 `$CA8B` (the catalogue screen): pages bank 0, clears bit 7 of `$C774-$C78A` (the slot list), sets the 300 bytes from `$C648` (CollisionTables) to `$FF`, calls CameraToPlayer `$C357` (bank 0: all three addresses are bank 0's, bank 6 holds code there), returns with bank 6 paged (`JP $7278`).

Witness: L1 19 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 17,718 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 1 and 2 more) |
| Calls | `PageBank6` (tail), `PageBank0`, `CameraToPlayer` |
| Reads | `$C774`-`$C78A` (`CollisionTables+300`) |
| Writes | `$C648`-`$C78A` (`CollisionTables`) |

## missionflow

`src/game/missionflow.asm`

### `StartMission` (`$694B`)

**Start the loaded mission: the play state from the header, the panel, the counters, then PlayLoop**

Reads the mission block's header (`$DBDA` -> `$BBF2`, `$DBD9` -> `$BBFA`), clears `$BC33`, sets the 3D view's blit (`$83E6` = `$8999`), draws the panel (`DrawBank7Picture` `$74AA` with DE = `$DD75`), resets the view parameters at `$9A6C`-`$9ABB`, calls the bank-6 set-up `$D521`, the weapon bars (`$7336`, `$73BA`), `$C632`, `$AE42`; clears the play flags (`$8459`, `$6A6D`, `$87E0`, `$D689`, `$D4B8`), prints `$D520` if `$7578` is set, then runs `$BA4A`, `$CEAB` and the play keys and falls into PlayLoop.

Witness: L1 31 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 83,923 t-states own (0.01 %) |
| Runs (the other recordings) | 26 calls (`stage1/missions` 16, `stage1/play` 4, `stage1/play2` 3 and 2 more) |
| Called from | `LoopHook` |
| Calls | `PanelSetup`, `PageShadowScreen`, `PageBank6`, `PageBank0`, `SaveBank`, `RestoreBank`, `UpdateAmmoBars`, `DrawSlotIcons`, `DrawBank7Picture`, `ToggleNight`, `ResetSegmentWalk`, `ToggleRearView`, `RefreshWeaponPanel`, `SetBinoculars` |
| Reads | `$7578` (`AwolState`); `$8475` (`BlinkLamp`); `$87FD` (`NightKey+1`); `$BA27` (`l_BA1F+8`); `$CEA8` (`ToggleBinoculars+1`); `$DBD9`-`$DBDB` (`MissionHeader+20`) |
| Writes | `$6952` (`StartMission+7`); `$6A6D` (`ViewChangeFlag+1`); `$7256` (`FirstFrameHook`); `$83E6`-`$83E7` (`MenuJobs+7`); `$8459` (`BlinkWarning`); `$8475` (`BlinkLamp`); 12 more ranges |

### `PlayLoop` (`$6A0C`)

**One frame of the 3D view: draw, keys, world, objects, enemies, HUD; loop until the view changes**

Calls in order: `$DB71`, the 3D frame (`$9882`), the play keys (`PlayKeys` `$6B3B`), `$B9F6`, the clipping marks (`ClearClipRow` `$6A9D`), `$BAAC`, the world (`$AD45`, `$AEA0`), `$BBF1`, `$BD98`, Bank3Step `$72A3` (bank 3 DrawDebris / MoveAllDebris), CameraSinCosAgain `$BA40`, DrawRadar `$C05E`, DrawObjectsInOrder `$BF53`, CollisionPass `$C7BC` and DrawSightOverlay `$C4CD` (bank 0), `$988D`, the message timer (`$7D5D`), the weapon bars (`$7327`), the object table (`$C026`), `$6B1D`, the mission's goal hook (`CALL LoopHook` at `$6A66`, its operand patched by the mission load: Blast Em Mission `$EB60`; LoopHook `$6A9C` is a `RET` in the image) and `$7256`, until the view flag `$6A6D` is non-zero; then the next view's loop through `$6A99`.

Witness: L1 9770 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

[Animation: `PlayLoop` at work](img/routines/PlayLoop.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 410 calls (`stage1/play2` 410) |
| Called from | `PlayLoopTail` (tail) |
| Calls | `ClearClipRow`, `PlayKeys`, `NoAction`, `Bank3Step`, `StartViewPass`, `SegmentVisibility`, `SetupClipWindow`, `SetCamera`, `CameraSinCosAgain`, `GroundDots`, `ActivateMissionObjects`, `TransformObjects`, `DrawObjectsInOrder`, `DrawRadar`, `DrawSightOverlay`, `CollisionPass`, `MineHud`, `PickupAnnounce` |
| Writes | `$7256` (`FirstFrameHook`); `$A8C8` (`PlayerStep+1`) |

### `PlayLoopTail` (`$6A57`)

**PlayLoopTail**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 23 calls (`stage1/play2` 23) |
| Called from | `MineHud` (tail) |
| Calls | `PlayLoop` (tail), `NextView` (falls into), `FlickerPlayer`, `FirstFrameHook`, `PageBank6`, `UpdateSlotBars`, `MessageOnce`, `RequestViewBlit`, `RunObjectHandlers`, `MissionHeader` |
| Reads | `$8475` (`BlinkLamp`) |
| Writes | `$6952` (`StartMission+7`); `$8459` (`BlinkWarning`); `$8475` (`BlinkLamp`); `$87D7` (`MessageTimer+1`); `$D4B8` (`BoundaryCheck`); `$DB71` (`PickupAnnounce`) |

### `NextView` (`$6A91`)

**NextView**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 341 t-states own (0.00 %) |
| Runs (the other recordings) | 121 calls (`stage1/missions` 50, `stage1/menu` 33, `stage1/play2` 12 and 6 more) |
| Called from | `PlayLoopTail` (falls into), `DragonflyViewLoop` (tail), `StatusLoop` (tail), `BriefPage` (tail), `DamageLoop` (tail) |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$8857` (`l_884C+11`) |

### `LoopHook` (`$6A9C`)

**LoopHook**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `StartMission`, `DragonflyViewLoop`, `StatusLoop`, `BriefPage`, `DamageLoop` |

### `ClearClipRow` (`$6A9D`)

**Fill the 32 bytes `$90F1-$9110` with `$FF`**

The row of the back buffer `$90F1` (its line 75 + 16) set to `$FF` once a frame of every view loop, before the world is drawn. Witness: L1 9794 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 87,087 t-states own (0.01 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop` |
| Reads | `$90F1`-`$910F` (`BackBuffer+1536`) |
| Writes | `$90F1`-`$9110` (`BackBuffer+1536`) |

### `FillPanelRows` (`$6AAB`)

**Fill 24 character rows of 6 bytes of the screen through ScreenRowFill**

A = 0, C = 2, D = 6, E = `$18`, then `JP $6D22`. Called from bank 6 `$C53F` / `$D521`. Witness: L1 48 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 100 t-states own (0.00 %) |
| Runs (the other recordings) | 40 calls (`stage1/missions` 16, `stage1/play2` 12, `stage1/play` 8 and 2 more) |
| Called from | `SelectWeapon` |
| Calls | `ScreenRowFill` (tail) |

### `DragonflyViewLoop` (`$6AB9`)

**The Dragonfly's flight view: the monitor frame from bank 7, the narrow blit, then the world and objects seen from the Dragonfly**

Entered only from LaunchDragonfly (`$C30F`, `LD HL,$6AB9` into NextView), after the camera `$B9F4` points at the Dragonfly's record; ScreenList node `$7572` names it, but no transition word leads there. Draws the monitor frame (`DrawBank7Picture` with DE = `$F9CD`), sets the blit to `$8A98`, then per frame `$9882`, `$B9F6`, `ClearClipRow`, `$BAAC`, `$AD45`, `$AEA0`, `$BBF1`, `$BD98`, `$BA40`, `$BF53`, `$C7BC`, `$C4CD`, `$988D`, `$C026`, `$7256` until `$6A6D`; then the 3D blit again and `NextView`.

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `LoopHook` |
| Calls | `NextView` (tail), `ClearClipRow`, `FirstFrameHook`, `PageShadowScreen`, `PageBank6`, `PageBank0`, `DrawBank7Picture`, `StartViewPass`, `RequestViewBlit`, `SegmentVisibility`, `SetupClipWindow`, `SetCamera`, `CameraSinCosAgain`, `GroundDots`, `ActivateMissionObjects`, `TransformObjects`, `DrawObjectsInOrder`, `RunObjectHandlers`, `DrawSightOverlay`, `CollisionPass` |
| Reads | `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$7256` (`FirstFrameHook`); `$83E6`-`$83E7` (`MenuJobs+7`); `$8459` (`BlinkWarning`); `$87D7` (`MessageTimer+1`) |

### `FlickerPlayer` (`$6B1D`)

**Toggle the low nibble of object 0's byte +7 from a random number while `$68BD` is below 16**

HL = `$75F7` (object 0, +7): if the byte is non-zero, XOR its low nibble with a random nibble (`$67D0` -> `$A779`). Runs while `$68BD` < 16 (the damage of the tank? known only from the code). Witness: L1 9769 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 4,567 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoopTail` |
| Reads | `$68BD` (`GaugeRecords+18`) |

### `PanelSetup` (`$6B32`)

**Page bank 6, call its panel set-up `$D521`, page bank 0 back**

Witness: L1 31 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 44 t-states own (0.00 %) |
| Runs (the other recordings) | 26 calls (`stage1/missions` 16, `stage1/play` 4, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission` |
| Calls | `PageBank6`, `PageBank0` (tail) |

### `PlayKeys` (`$6B3B`)

**The play keys: a new key code in `$8979` jumps to its action**

Returns unless bit 1 of `$8978` is set and the code differs from the last (`$6B45`, the operand of `LD C,0`). E: `$843F` (the quit prompt), K and J: the selected weapon's aim pair (the `JP` targets `$6B55` and `$6B50`, patched by SelectWeapon from `$7B89` + 8 x type, words 0 and 1; `$6BB0` NoAction in the image), M: the status view (`$705A`), D: the damage board (`$6BC2`), 1-4: weapons (bank 6 `$C53F`), H: `$D52E`, N: `$87FC`, R: `$BA45`, B: `$CEA7`, Z: `$CEE5`, C: remembered in `$6B45`.

Witness: L1 9770 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 20,428 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop` |
| Calls | `NoAction` (tail), `SelectDamage` (tail), `ScreenZero` (tail), `QuitKey` (tail), `NightKey` (tail), `MortarElevationDown` (tail), `AimLimit` (tail), `RearViewOff` (tail), `SelectWeapon` (tail), `ToggleBinoculars` (tail), `CycleBinocularZoom` (tail), `SetMineTimer` (tail), `SlamOff` (tail), `AutoFireOff` (tail), `PlaceHelicarrier` (tail) |
| Reads | `$8978`-`$8979` (`KeyState`, `KeyCode`) |

### `DamageKeys` (`$6B95`)

**The keys of the damage board (called only from DamageLoop `$6CB9`): B to the status view `$6BC7`, C back to the 3D view, D the damage board again**

Witness: L1 3 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play` 3) |
| Called from | `DamageLoop` |
| Reads | `$6B45` (`PlayKeys+10`); `$8978`-`$8979` (`KeyState`, `KeyCode`) |

### `NoAction` (`$6BB0`)

**A RET: the action of the keys with nothing to do**

Witness: L1 40369 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 478 calls, 4,937 t-states own (0.00 %) |
| Runs (the other recordings) | 13,925 calls (`stage1/death` 10,040, `stage1/play2` 1,641, `stage1/missions` 1,092 and 2 more) |
| Called from | `PlayLoop`, `PlayKeys` (tail), `PlayerSteering` |
| Calls | `SelectLoop` (falls into) |

### `SelectLoop` (`$6BB4`)

**SelectLoop**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `NoAction` (falls into), `SelectDamage` (tail) |
| Calls | `SetViewFlag` (tail) |
| Writes | `$6A99`-`$6A9A` (`NextView+8`); `$6B45` (`PlayKeys+10`) |

### `SelectDamage` (`$6BC2`)

**The key D: HL = `$6C93`, the damage board's loop, then SelectLoop**

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `PlayKeys` (tail) |
| Calls | `SelectLoop` (tail) |

### `StatusLoop` (`$6BC7`)

**The status view's loop: the panel through bank 7 and the status texts, no 3D frame**

Pages bank 6 for `$DBB6`, draws `DrawBank7Picture` DE = `$D325`, prints the help texts (`$6C8B`), sets the blit to `$DBBD`, then per frame the mission clock (`PrintClock` `$7E3A`), the world and objects and bank 6's `$DB15`, `$D3C9`, `$E5BE`, `$C0F7`, the keys (`StatusKeys` `$6C60`) until `$6A6D`.

Witness: L1 10 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/missions` 8, `stage1/m2erbe` 1, `stage1/play` 1) |
| Called from | `LoopHook` |
| Calls | `NextView` (tail), `StatusKeys`, `PrintStatusHelp`, `PageShadowScreen`, `PageBank6`, `PageBank0`, `DrawBank7Picture`, `PrintClock`, `SegmentVisibility`, `SetCamera`, `CameraSinCosAgain`, `ActivateMissionObjects`, `TransformObjects`, `RunObjectHandlers`, `CollisionPass` |
| Reads | `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$6C56` (`BriefPageOnce`); `$6C6A` (`StatusKeys+10`); `$7256` (`FirstFrameHook`); `$757A` (`AwolState+2`); `$7D8A` (`PointerTick+10`); `$83BF` (`PointerShown+1`); 3 more ranges |

### `BriefPage` (`$6C44`)

**The console's BRIEF page (node `$7544`, key B in the status view): the briefing text once (`$6C56`), then the clock and keys loop**

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `LoopHook` |
| Calls | `NextView` (tail), `BriefPageOnce`, `StatusKeys`, `PrintClock` |
| Reads | `$6A6D` (`ViewChangeFlag+1`) |

### `BriefPageOnce` (`$6C56`)

**A NOP patched to RET after the first call of `$70B6`; StatusLoop (`$6BF6`) puts the NOP back on each visit**

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `BriefPage` |
| Calls | `BriefPageText` |
| Writes | `$6C56` (`BriefPageOnce`) |

### `StatusKeys` (`$6C60`)

**The keys of the status view: C to the 3D view, B and M to `$704E` / `$705E`, then the help texts**

Witness: L1 530 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 530 calls (`stage1/play` 492, `stage1/missions` 34, `stage1/m2erbe` 4) |
| Called from | `StatusLoop`, `BriefPage` |
| Calls | `ScreenEight`, `ScreenZero` (tail), `InvertPanelA` |
| Reads | `$8978`-`$8979` (`KeyState`, `KeyCode`) |
| Writes | `$6C6A` (`StatusKeys+10`) |

### `PrintStatusHelp` (`$6C8B`)

**Print the help text `$6550` with attribute `$1A` through `$B7AE`**

Witness: L1 11 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/missions` 8, `stage1/play` 1, `stage1/m2erbe` 1) |
| Called from | `StatusLoop` |
| Calls | `InvertPanelA` (tail) |

### `DamageLoop` (`$6C93`)

**The damage board's loop (key D): PicDamageBoard from bank 7 at `$C000`, the weapon icons and bars, then world and objects**

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `LoopHook` |
| Calls | `NextView` (tail), `DamageKeys`, `PageBank0Main`, `PageShadowScreen`, `PageBank6`, `PageBank0`, `DrawSlotBarsLow`, `DrawSlotBars`, `DrawDamagePanel`, `DrawBank7Picture`, `SegmentVisibility`, `SetCamera`, `CameraSinCosAgain`, `ActivateMissionObjects`, `TransformObjects`, `RunObjectHandlers`, `CollisionPass` |
| Reads | `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$7D5D` (`MessageOnce`); `$87D7`-`$87E0` (`MessageTimer+1`) |

### `PlaceHelicarrier` (`$D52E`)

**Once (the RET / NOP gate `$D52E`), on the key H: call the Helicarrier, which then flies to the pad**

`$D52E` is `NOP` until it has run, then `RET` (`$D531` writes it; the mission load `$8598` clears it). Record 21 (`$7ADC`) gets type `$8C` at the pad `$7E89` / `$7E8C` (the block header's 12 bytes at `$DBF1` copied to `$7E82`).

Witness: L1 7 (m1complete, m4complete, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `PlayKeys` (tail) |
| Calls | `ApiVector03`, `ApiVector04`, `ApiVector05`, `ApiVector14`, `AbsHL` |
| Reads | `$67A8`-`$67A9` (`WorldVars+5`); `$7612` (`PlayerHeading`); `$7E89`-`$7E8D` (`MissionParams+7`) |
| Writes | `$7B00`-`$7B04` (`HelicarrierRecord+36`); `$8475` (`BlinkLamp`); `$C95C` (`RegisterCollision+5`); `$C973`-`$C974` (`l_C96D+6`); `$D52E` (`PlaceHelicarrier`) |

### `CopyHelicarrierState` (`$D5C9`)

**Copy the Helicarrier's state byte**

`$D5D7` = (IY+`$31`) (play2: 15 runs).

Witness: L1 15 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/play2`) |
| Called from | `OpNative` |
| Reads | `$7AD1` (`PlayerY+1211`) |
| Writes | `$D5D7` (`HelicarrierData+7`) |

### `HelicarrierHit` (`$DAAB`)

**The Helicarrier's collision handler: the tank drives into the parked Helicarrier**

Three branches on the hitter IY: +3 bit 7 clear (not the player's family) -> HitTest `$67DC`; else the goal flag `$68E8` set -> `$67EE` (mission complete); else ScreenSix `$7047` and `$7BF9` = `$CC94` (failure). There is no parked test.

Witness: m1complete frame 21558, m4complete 21299, one run each, then `$67EE` (work/stage2/complete-NOTES.md).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HelicarrierTurn` (`$DAC4`)

**The arrival's turn over the pad: heading + 8 a pass until within 8 of +`$31`, then the descent**

+`$22` += 8; |+`$22` - +`$31`| (`$67D6`) below 8 makes HelicarrierDescent `$DADE` the step. Witness: m1complete 17109-17205 (11 runs).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HelicarrierDescent` (`$DADE`)

**The Helicarrier's landing: down 8 a step to the pad, then parked**

The height goes 104, 96, ... 24 (one step a pass), then the handler `$6BB0` parks it. Witness: m1complete frames 17213-17311 (10 runs), m4complete 15510-15575 (10).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HelicarrierInit` (`$DB00`)

**The Helicarrier's set-up**

Clears `$6760`-`$6763`, `$FF` to `$6764`-`$6767`, the handler +`$18`/+`$19` = `$DB24` (play: 1 run).

Witness: L1 3 (m1complete, m4complete, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `RunObjectHandlers` |
| Writes | `$6760`-`$6767` (`FaceFlags+56`); `$7AF4`-`$7AF5` (`HelicarrierRecord+24`) |

### `SetHelicarrierHandler` (`$DB15`)

**The Helicarrier handler's high byte**

`LD (IX+$19),$DB` / `RET`, the handler's high byte.

Witness: L1 3 (m1complete, m4complete, play).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HelicarrierCode` (`$DB1A`)

**Code whose address PlaceHelicarrier writes into +`$31`/+`$32`; no recording runs it**

`LD IY,$75F0` / `LD HL,$67A8` / `EXX` / `JR $DB2C` into HelicarrierWait with the player as the target. PlaceHelicarrier stores `$DB1A` when |pad| - |camera| is below 8 on both axes; whether anything jumps to it is SUSPECTED (docs/10-gameplay-logic.md 10.9).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HelicarrierWait` (`$DB24`)

**The Helicarrier waits for the player**

Flies the Helicarrier to the pad: IY = the pseudo-record `$7E65` (its X / Y at `$7E88` / `$7E8B` are the pad), TurnToward, MoveObject; when the Helicarrier itself (not the tank) is within 3 units of X >> 8 and Y >> 8 (768 world units) of the pad on both axes, the arrival at `$DB61` (play: 27 runs; m1complete 16239-17099, 85 runs).

Witness: L1 220 (m1complete, m4complete, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 27 calls (`stage1/play` 27) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00`, `TurnToward` |
| Reads | `$7B00`-`$7B04` (`HelicarrierRecord+36`); `$7E89`-`$7E8D` (`MissionParams+7`) |

### `PickupAnnounce` (`$DB71`)

**Announce the pickup once the goal is met**

A NOP / RET gate at `$DB71`. When `$68E8` (the goal flag) is set: `$DB77` writes `RET` at `$DB71` and prints "MISSION:COMPLETE:PROCEED:TO:PICKUP" (`$DB97`). Runs once per 3D frame.

Witness: L1 9770 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 3,940 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop` |
| Reads | `$68E8` (`GoalFlag`) |

### `l_FE8F` (`$FE8F`)

**l_FE8F**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/death`, `stage1/play2`, `stage1/play`) |
| Called from | `OpNative` |
| Writes | `$FD00`-`$FD07` (`MissionHeader+8507`); `$FE00`-`$FE07` (`MissionHeader+8763`); `$FF00`-`$FF07` (`data_FEBB+69`) |

## text

`src/game/text.asm`

### `BorderBlack` (`$6CEB`)

**Border 0 (the stored colour `$6CF1` cleared)**

Witness: L1 80 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 418 t-states own (0.00 %) |
| Runs (the other recordings) | 61 calls (`stage1/missions` 19, `stage1/m2ocean` 11, `stage1/play2` 10 and 6 more) |
| Called from | `Entry`, `LoadBlock` |
| Writes | `$6CF1` (`BorderNext+2`) |
| Ports out | `$00FE` |

### `l_6CF4` (`$6CF4`)

**l_6CF4**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AttrBox` (`$6CFB`)

**Fill an attribute box from a 5-byte record: width, height, column, attribute, row**

HL -> B (width), C (height), E (column), A (attribute), L (row); falls into AttrBoxAt. Witness: L1 383 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 9 calls, 132 t-states own (0.00 %) |
| Runs (the other recordings) | 337 calls (`stage1/missions` 153, `stage1/menu` 99, `stage1/play` 26 and 6 more) |
| Called from | `BriefPageText` (tail), `BriefingMapLegend`, `StatusMapLegend`, `NightBoxSelect` |
| Calls | `AttrBoxAt` (falls into) |
| Reads | `$88F3` (`NightBox`) |
| Writes | `$5800`-`$5AFF` (screen) |

### `AttrBoxAt` (`$6CFD`)

**AttrBox with B already set (HL -> height, column, attribute, row)**

Witness: L1 474 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11 calls, 64,438 t-states own (0.01 %) |
| Runs (the other recordings) | 308 calls (`stage1/missions` 187, `stage1/play` 61, `stage1/play2` 27 and 2 more) |
| Called from | `AttrBox` (falls into), `SkyColours` |
| Reads | `$88F4`-`$890F` (`NightBox+1`, `HourTable`, `SkyBoxes`) |
| Writes | `$5800`-`$5AFF` (screen) |

### `AttrBoxAtC` (`$6CFE`)

**AttrBoxAtC**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `AttrBoxRC` (falls into) |

### `AttrBoxRC` (`$6D05`)

**Fill C rows of B attribute bytes with A' from row L, column E (`$5800` + 32L + E)**

Witness: L1 483 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 70 calls (`stage1/play` 70) |
| Called from | `AttrBoxAtC` (falls into), `IconFrame` (tail) |
| Calls | `LowTimes32` |
| Writes | `$5802`-`$5807` (screen); `$5822`-`$5AAC` (screen); `$5AC4`-`$5AFD` (screen) |

### `ScreenRowFill` (`$6D22`)

**Fill E pixel lines of D bytes with A from the line table `$6500`, column C**

Uses the line address table at `$6500` (2 bytes a pixel line). Witness: L1 224 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 265,848 t-states own (0.04 %) |
| Runs (the other recordings) | 193 calls (`stage1/missions` 65, `stage1/play2` 50, `stage1/menu` 36 and 6 more) |
| Called from | `FillPanelRows` (tail) |
| Reads | `$6500`-`$667F` (`ScreenRowTable`) |
| Writes | `$4000`-`$57FF` (screen) |

### `PointerZones` (`$6D42`)

**When the pointer is clicked, call the zone of the current screen that holds the pointer**

`LD A,n`: n (`$6D43`) is set by the fire test of the interrupt (`$7DC2`). The zone table (HL, the operand at `$6D47`, set per screen by `SetScreen` `$7060`) has 6-byte records x1, x2, y1, y2 and a routine; the first record with x1 <= X < x2 and y1 <= Y < y2 (X `$9715`, Y `$9716`) is called. A 0 byte ends the table. Witness: L1 36012878 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,746,889 calls, 46,341,318 t-states own (7.01 %) |
| Runs (the other recordings) | 28,335,628 calls (`stage1/play2` 5,182,205, `stage1/m10` 5,128,479, `stage1/missions` 4,951,614 and 6 more) |
| Calls | `ApiVector16`, `ScreenFromClick`, `ScreenZero`, `ScreenTwo`, `ShowBriefingMapOnce`, `ScreenOfMission`, `LoadMissionIfAllowed`, `LoadMissionHeader` |
| Reads | `$9715`-`$9716` (`ClickState`, `ClickY`) |
| Writes | `$6D43` (`PointerZones+1`); `$6D71`-`$6D72` (`l_6D49+40`) |

### `CopyGraphic` (`$6D7F`)

**Copy a C x B graphic from HL' to the screen at pixel line A, column BC**

The line address table `$6500` again. Witness: L1 470 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 17 calls, 166,004 t-states own (0.03 %) |
| Runs (the other recordings) | 393 calls (`stage1/missions` 149, `stage1/menu` 82, `stage1/play2` 71 and 6 more) |
| Called from | `DrawIcon` (tail) |
| Reads | `$6500`-`$654F` (`ScreenRowTable`); `$6560`-`$65EF` (`ScreenRowTable+96`); `$6610`-`$667F` (`ScreenRowTable+272`) |
| Writes | `$400B`-`$4ADB` (screen); `$4B02`-`$4BDB` (screen); `$4C02`-`$4CDB` (screen); `$4D02`-`$4DDB` (screen); `$4E02`-`$4EDB` (screen); `$4F02`-`$4FDB` (screen); 1 more ranges |

### `CodeSmallFont` (`$6DA1`)

**Control code 7: switch to the small font, then CodeAt**

Witness: L1 1405 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 58 calls, 3,487 t-states own (0.00 %) |
| Runs (the other recordings) | 1,064 calls (`stage1/missions` 257, `stage1/menu` 252, `stage1/play2` 215 and 6 more) |
| Called from | `CallControl` |
| Calls | `CodeSmallAt` |
| Reads | `$87F2` (`BlankMessage+2`); `$8C67`-`$8E86` (`BackBuffer+374`); `$BA70`-`$BAA1` (`ViewTexts+2`, `IrSightBlank`, `RearViewText`, `BinocularText` and 1 more); `$D0AD` (`MineHudText+2`); `$FDC2`-`$FFDD` (`MissionHeader+8701`, `l_FE8F`, `data_FEBB`) |

### `CodeSmallChars` (`$6DA6`)

**Control code 5: the small font's column (6-pixel cells) from the next byte; the font is not switched**

Witness: known only from the code (no string of the recordings uses code 5).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `SmallFontColumn` (falls into) |

### `SmallFontColumn` (`$6DA9`)

**A = column in 6-pixel cells: the byte (`$6DFD`) and the bit shift (`$6DEC`)**

Witness: L1 1731 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 61 calls, 8,020 t-states own (0.00 %) |
| Runs (the other recordings) | 1,362 calls (`stage1/menu` 456, `stage1/missions` 312, `stage1/play2` 224 and 6 more) |
| Called from | `CodeSmallChars` (falls into), `SmallNewLine` |
| Writes | `$6DEC` (`PrintSmallChar+4`); `$6DFD`-`$6DFE` (`PrintSmallChar+21`) |

### `SmallFontAdvance` (`$6DC0`)

**The next 6-pixel cell, a new line past column 32**

Witness: L1 21016 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 698 calls, 97,643 t-states own (0.01 %) |
| Runs (the other recordings) | 16,941 calls (`stage1/menu` 6,385, `stage1/missions` 3,959, `stage1/play2` 2,258 and 6 more) |
| Called from | `PrintSmallChar` |
| Reads | `$6DEC` (`PrintSmallChar+4`); `$6DFD` (`PrintSmallChar+21`) |
| Writes | `$6DEC` (`PrintSmallChar+4`); `$6DFD` (`PrintSmallChar+21`) |

### `SmallGlyph` (`$6DDA`)

**HL = SmallFont + 5 (A - "0")**

Witness: L1 21016 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 698 calls, 56,845 t-states own (0.01 %) |
| Runs (the other recordings) | 16,941 calls (`stage1/menu` 6,385, `stage1/missions` 3,959, `stage1/play2` 2,258 and 6 more) |
| Called from | `PrintSmallChar` |

### `PrintSmallChar` (`$6DE8`)

**Print a small-font character at the current cell: 5 lines, one of four shifts through `$6E9F`**

Witness: L1 21016 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 698 calls, 930,873 t-states own (0.14 %) |
| Runs (the other recordings) | 16,941 calls (`stage1/menu` 6,385, `stage1/missions` 3,959, `stage1/play2` 2,258 and 6 more) |
| Called from | `PrintString` |
| Calls | `SmallFontAdvance`, `SmallGlyph` |
| Reads | `$4022`-`$4E98` (screen); `$4EEA`-`$4F98` (screen); `$502C`-`$51B4` (screen); `$5203`-`$569E` (screen); `$570A`-`$579E` (screen); `$650A`-`$6529` (`ScreenRowTable+10`); 4 more ranges |
| Writes | `$4022`-`$4E98` (screen); `$4EEA`-`$4F98` (screen); `$502C`-`$51B4` (screen); `$5203`-`$569E` (screen); `$570A`-`$579E` (screen); `$6E06`-`$6E07` (`l_6E05+1`) |

### `CodeColumn` (`$6EA7`)

**Control code 0: the next byte is the column (`$6FF8`)**

Witness: known only from the code (no recording counts it: it is entered by the CALL patched at `$6FD6`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CodeAtColumn` (`$6EAE`)

**Control code 2: a row (CodeAt) then a column**

Witness: L1 873 (armour, c1, controls, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 315 t-states own (0.00 %) |
| Runs (the other recordings) | 851 calls (`stage1/play` 524, `stage1/missions` 202, `stage1/play2` 70 and 3 more) |
| Called from | `CallControl` |
| Calls | `CodeAt` |
| Reads | `$7E31` (`ClockText+2`) |
| Writes | `$6FF8` (`PrintChar+8`) |

### `CodeAt` (`$6EB3`)

**Control code 1: the next byte is the character row: its line pointers and attribute address**

Witness: L1 873 (armour, c1, controls, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 790 t-states own (0.00 %) |
| Runs (the other recordings) | 851 calls (`stage1/play` 524, `stage1/missions` 202, `stage1/play2` 70 and 3 more) |
| Called from | `CodeAtColumn` |
| Reads | `$7E30` (`ClockText+1`) |
| Writes | `$6F5D`-`$6F5E` (`CodeNewLine+16`); `$6FC2`-`$6FC3` (`PrintString+15`); `$6FFB`-`$6FFC` (`PrintChar+11`) |

### `GlyphAddress` (`$6ED7`)

**HL = the 8x8 glyph of character A: `$F5E4` + 8 (A - `$20`) (bank 6)**

Witness: L1 6723 (armour, c1, controls, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 128 calls, 13,146 t-states own (0.00 %) |
| Runs (the other recordings) | 6,189 calls (`stage1/play` 2,855, `stage1/missions` 1,576, `stage1/play2` 1,001 and 3 more) |
| Called from | `PrintChar` |

### `NextColumn` (`$6EE5`)

**The column one on, a new line after 31**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CodeNumber` (`$6EF1`)

**Control code 8: print the byte at the address that follows as three decimal digits**

Witness: L1 226 (armour, death, m10, m1complete, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 140 calls (`stage1/death` 62, `stage1/play2` 50, `stage1/play` 24 and 3 more) |
| Called from | `CallControl` |
| Reads | `$7A95` (`PlayerY+1151`); `$B8FC` (`IrViewHeight`); `$C527` (`WeaponVars`); `$CFF5` (`MineTimerCode+1`); `$D0AF`-`$D0B0` (`MineHudText+4`); `$FDCA`-`$FDCB` (`MissionHeader+8709`); 1 more ranges |
| Writes | `$6F2F` (`NumberText+2`) |

### `CodeNumberA` (`$6EFB`)

**Control code 3: three decimal digits of a constant: LD A,`$5E` overwrites A, so it prints "094"; no string uses it**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `DivideDigit`, `PrintString` |

### `CodeHex` (`$6F17`)

**Control code 4: two hexadecimal digits of the constant `$5E` (LD A,`$5E`): "5E"; no string uses it**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DivideDigit` (`$6F31`)

**A / B: C the quotient, A the rest; the digit stored at HL**

Witness: L1 452 (armour, death, m10, m1complete, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 280 calls (`stage1/death` 124, `stage1/play2` 100, `stage1/play` 48 and 3 more) |
| Called from | `CodeNumberA` |
| Writes | `$6F2D`-`$6F2E` (`NumberText`) |

### `DigitChar` (`$6F3D`)

**DigitChar**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CodeNewLine` (`$6F4D`)

**Control code 11: the next character row, column 0**

Witness: L1 164 (armour, c1, controls, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 10 calls, 1,732 t-states own (0.00 %) |
| Runs (the other recordings) | 130 calls (`stage1/play2` 64, `stage1/menu` 24, `stage1/play` 22 and 3 more) |
| Called from | `CallControl` |
| Reads | `$6FFB`-`$6FFC` (`PrintChar+11`) |
| Writes | `$6F5D`-`$6F5E` (`CodeNewLine+16`); `$6FF8`-`$6FFC` (`PrintChar+8`) |

### `SmallNewLine` (`$6F67`)

**Control code 10: the small font's next line (9 pixel lines down: ScreenRowTable + `$12`), column = the margin**

Witness: L1 326 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3 calls, 320 t-states own (0.00 %) |
| Runs (the other recordings) | 298 calls (`stage1/menu` 204, `stage1/missions` 55, `stage1/play` 15 and 6 more) |
| Called from | `CallControl` |
| Calls | `SmallFontColumn` |
| Reads | `$6DFA`-`$6DFB` (`PrintSmallChar+18`); `$6F58` (`CodeNewLine+11`) |
| Writes | `$6DFA`-`$6DFB` (`PrintSmallChar+18`) |

### `CodeLeftMargin` (`$6F79`)

**Control code 9: the next byte is the left margin (`$6F58`)**

Witness: L1 187 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 168 t-states own (0.00 %) |
| Runs (the other recordings) | 163 calls (`stage1/menu` 55, `stage1/missions` 42, `stage1/play2` 38 and 6 more) |
| Called from | `CallControl` |
| Reads | `$8C64`-`$8D07` (`BackBuffer+371`); `$8D43`-`$8D7E` (`BackBuffer+594`); `$8DC0` (`BackBuffer+719`); `$8E04` (`BackBuffer+787`); `$8E49`-`$8E83` (`BackBuffer+856`) |
| Writes | `$6F58` (`CodeNewLine+11`) |

### `CodeMarginHere` (`$6F80`)

**Control code 12: the margin = the current column**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CodeInk` (`$6F88`)

**Control code 13: the next byte is the attribute of the characters (`$7025`)**

Witness: L1 1463 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 18 calls, 846 t-states own (0.00 %) |
| Runs (the other recordings) | 1,295 calls (`stage1/play` 544, `stage1/missions` 326, `stage1/menu` 181 and 6 more) |
| Called from | `CallControl` |
| Reads | `$7E33` (`ClockText+4`); `$93DA`-`$94F1` (`BackBuffer+2281`); `$FDC4`-`$FDEF` (`MissionHeader+8703`) |
| Writes | `$7025` (`l_7018+13`) |

### `PrintString` (`$6FB3`)

**Print the string at HL: characters, control codes below `$20`, tokens from `$82`, `$FF` the end**

Witness: L1 34892 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

[Animation: `PrintString` at work](img/routines/PrintString.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 60 calls, 114,900 t-states own (0.02 %) |
| Runs (the other recordings) | 2,068 calls (`stage1/play` 623, `stage1/missions` 446, `stage1/menu` 364 and 6 more) |
| Called from | `CodeNumberA`, `BriefPageText`, `LoadDirectory`, `PrintRewind` (tail), `BriefingMapLegend` (tail), `StatusMapLegend`, `MessageOnce`, `PrintClock` (tail), `MessageTimer` (tail), `ToggleNight` (tail), `ShowMortarRange` (tail), `ToggleRearView` (tail), `WeaponSelectText` (tail), `SelectPlain`, `PrintAmmoAt` (tail), `SetBinoculars` (tail), `PrintElevation`, `StoreMineTimer` (tail), `MineHud`, `SlamOff`, `AutoFireOff` (tail), `SelectSpectre` (tail), `SelectPhantasm` (tail) |
| Calls | `PrintSmallChar`, `PrintChar` |
| Reads | `$6F2D`-`$6F30` (`NumberText`); `$6F93`-`$6FAA` (`ControlCodes+4`); `$7E2F`-`$7E39` (`ClockText`); `$8301`-`$8EAF` (`Armour`, `DamageBoardRecords`, `InterruptHandler`, `ClearMarkColumn` and 44 more); `$93D9`-`$9502` (`BackBuffer+2280`); `$BA6E`-`$BAAB` (`ViewTexts`, `IrSightBlank`, `RearViewText`, `BinocularText` and 1 more); 2 more ranges |
| Writes | `$6FD7`-`$6FD8` (`CallControl+1`) |

### `CallControl` (`$6FD6`)

**CallControl**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `CodeSmallFont`, `CodeAtColumn`, `CodeNumber`, `CodeNewLine`, `SmallNewLine`, `CodeLeftMargin`, `CodeInk` |

### `PrintChar` (`$6FF0`)

**Print the 8x8 character A at the current cell and its attribute (`$7025`), then the next column**

In column 31 it writes no attribute and starts a new line (CodeNewLine) instead (`$700F`).

Witness: L1 6723 (armour, c1, controls, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 128 calls, 136,047 t-states own (0.02 %) |
| Runs (the other recordings) | 6,189 calls (`stage1/play` 2,855, `stage1/missions` 1,576, `stage1/play2` 1,001 and 3 more) |
| Called from | `PrintString` |
| Calls | `GlyphAddress` |
| Reads | `$6550`-`$65BF` (`ScreenRowTable+80`); `$65D0`-`$660F` (`ScreenRowTable+208`); `$6620`-`$662F` (`ScreenRowTable+288`); `$6640`-`$664F` (`ScreenRowTable+320`); `$6F5D`-`$6F5E` (`CodeNewLine+16`); `$6FF8` (`PrintChar+8`) |
| Writes | `$40A1`-`$5110` (screen); `$514B`-`$5193` (screen); `$5208`-`$5210` (screen); `$524B`-`$5293` (screen); `$5308`-`$5310` (screen); `$534B`-`$5393` (screen); 17 more ranges |

### `CodeSmallAt` (`$7029`)

**Control code 6: the small font's line from the next byte**

Witness: L1 1405 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 58 calls, 8,130 t-states own (0.00 %) |
| Runs (the other recordings) | 1,064 calls (`stage1/missions` 257, `stage1/menu` 252, `stage1/play2` 215 and 6 more) |
| Called from | `CodeSmallFont` |
| Reads | `$87F1` (`BlankMessage+1`); `$8C66`-`$8E85` (`BackBuffer+373`); `$BA6F`-`$BAA0` (`ViewTexts+1`, `IrSightBlank`, `RearViewText`, `BinocularText` and 1 more); `$D0AC` (`MineHudText+1`); `$FDC1`-`$FFDC` (`MissionHeader+8700`, `l_FE8F`, `data_FEBB`) |
| Writes | `$6DFA`-`$6DFB` (`PrintSmallChar+18`); `$6FC2`-`$6FC3` (`PrintString+15`) |

## screens

`src/game/screens.asm`

### `ScreenFour` (`$7040`)

**Remember key A, screen 2 (E = 4); the mission code's vector `$67EE`**

Witness: L1 11 (c1, controls, m10, m1complete, m4complete, menu, missions).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 32 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/menu` 4, `stage1/missions` 1, `stage1/m10` 1) |
| Called from | `ApiVector16` (tail) |
| Calls | `SetScreen` (tail) |
| Writes | `$6B45` (`PlayKeys+10`) |

### `ScreenSix` (`$7047`)

**Remember key A, screen 3 (E = 6)**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScreenEight` (`$704E`)

**Remember key A, screen 4 (E = 8)**

Witness: L1 14 (m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 2 and 1 more) |
| Called from | `StatusKeys` |
| Calls | `SetScreen` (tail) |
| Writes | `$6B45` (`PlayKeys+10`) |

### `ScreenFromClick` (`$7055`)

**Key "C", screen 0**

Witness: L1 19 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 20 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/death` 1 and 2 more) |
| Called from | `PointerZones` |
| Calls | `ScreenZero` (falls into) |
| Writes | `$6B45` (`PlayKeys+10`) |

### `ScreenZero` (`$705A`)

**Screen 0 (E = 0)**

Witness: L1 108 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 76 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/missions` 41, `stage1/menu` 17, `stage1/play2` 9 and 6 more) |
| Called from | `PlayKeys` (tail), `StatusKeys` (tail), `PointerZones`, `ScreenFromClick` (falls into), `MissionLoaded` (tail) |
| Calls | `SetScreen` (tail) |
| Reads | `$74E6`-`$74ED` (`ScreenList`); `$7504`-`$751D` (`ScreenList+30`) |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$6A99`-`$6A9A` (`NextView+8`); `$6D47`-`$6D48` (`PointerZones+5`); `$74E6`-`$74E7` (`ScreenList`) |

### `ScreenTwo` (`$705E`)

**Screen 1 (E = 2)**

Witness: L1 13 (m4complete, menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12 calls (`stage1/menu` 12) |
| Called from | `PointerZones`, `ScreenOfMission` (tail) |
| Calls | `SetScreen` (falls into) |

### `SetScreen` (`$7060`)

**Switch to entry E/2 of the screen list: the draw routine to `$6A99`, the zone table to `$6D47`**

Witness: L1 148 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 1,072 t-states own (0.00 %) |
| Runs (the other recordings) | 112 calls (`stage1/missions` 50, `stage1/menu` 33, `stage1/play2` 12 and 3 more) |
| Called from | `ScreenFour` (tail), `ScreenEight` (tail), `ScreenZero` (tail), `ScreenTwo` (falls into) |
| Calls | `SetViewFlag` (falls into) |
| Reads | `$74E6`-`$7549` (`ScreenList`); `$756A`-`$7571` (`ScreenList+132`) |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$6A99`-`$6A9A` (`NextView+8`); `$6D47`-`$6D48` (`PointerZones+5`); `$74E6`-`$74E7` (`ScreenList`) |

### `SetViewFlag` (`$707E`)

**`$6A6D` = `$FF`: the current loop ends**

Witness: L1 150 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/play` 10) |
| Called from | `SelectLoop` (tail), `SetScreen` (falls into) |
| Writes | `$6A6D` (`ViewChangeFlag+1`) |

### `ShowBriefingMapOnce` (`$7084`)

**Once: the briefing map (bank 6's BriefingMapFrame `$DACB` and BriefingMap `$DB64`), then patched to RET**

Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/menu` 10) |
| Called from | `PointerZones` |
| Calls | `PageBank6`, `SaveBank`, `RestoreBank` |
| Writes | `$7084` (`ShowBriefingMapOnce`); `$709E` (`BriefingTextOnce`) |

### `BriefPageText` (`$70B6`)

**Once: bank 6's box `$C079`, the briefing text at (`$70A3`) in the console's screen, the attribute box `$C0BB`**

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `BriefPageOnce` |
| Calls | `AttrBox` (tail), `PrintString` |
| Reads | `$70A3`-`$70A4` (`BriefingTextOnce+5`) |

## catalogue

`src/game/catalogue.asm`

### `CopyCatalogueHead` (`$70C6`)

**Copy the catalogue's first 32 bytes to bank 6 `$CF85` and the 1 K from `$CB84` to the back buffer**

Pages bank 4, copies `$CB64` (32 bytes) via `$8AF1` to bank 6 `$CF85`, then `$CB84` (1024 bytes) to `$8AF1`. Witness: L1 36 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 24,215 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 6 more) |
| Calls | `PageBank4`, `PageBank6`, `SaveBank`, `RestoreBank` (tail) |
| Reads | `$8AF1`-`$8B10` (`BackBuffer`) |
| Writes | `$8AF1`-`$8EF0` (`BackBuffer`) |

### `CopyMissionText` (`$70F6`)

**Copy mission (`$757D`)'s texts from the catalogue (bank 4) to bank 6 `$DBF3`**

Record n of the 8-byte index at `$CCA6`: the offset, two words stored at `$7143` and `$7151`, the end; the text is copied through `$8AF1` to `$DBF3`; `$70A3` and `$7C55` get the addresses of its two parts. Witness: L1 29 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 23,761 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/menu` 10, `stage1/missions` 8, `stage1/play2` 3 and 3 more) |
| Calls | `PageBank4`, `PageBank6`, `SaveBank`, `RestoreBank` (tail) |
| Reads | `$757D` (`ScreenOfMission+1`); `$8AF1`-`$8DA3` (`BackBuffer`) |
| Writes | `$70A3`-`$70A4` (`BriefingTextOnce+5`); `$7143`-`$7152` (`CopyMissionText+77`); `$7C55`-`$7C56` (`FailReason+92`); `$8AF1`-`$8DA3` (`BackBuffer`) |

### `LoadDirectory` (`$715D`)

**Load the catalogue from side 2: the 17-byte header "DIRECTORY", then its block to bank 4 `$CB64`**

Loops until a header whose name is "DIRECTORY" (`$71B3`) loads, prints `$C90D` ("loading"), pages bank 4 and loads the block (length from the header `$8AFC`) to `$CB64`; retries until its first 9 bytes are "MISSION:T" (`$71BB`). Witness: L1 16 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 398 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/play2` 3, `stage1/play` 2, `stage1/menu` 1 and 6 more) |
| Calls | `PrintString`, `PrintRewind`, `IsDirectoryHeader`, `IsCatalogue`, `LoadBlock`, `PageBank4`, `PageBank6` |
| Reads | `$8AFC`-`$8AFD` (`BackBuffer+11`) |
| Writes | `$8AF1` (`BackBuffer`) |

### `PrintRewind` (`$719B`)

**Print bank 6 `$C93E`**

Witness: L1 31 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 86 t-states own (0.00 %) |
| Runs (the other recordings) | 23 calls (`stage1/play2` 6, `stage1/play` 3, `stage1/menu` 2 and 6 more) |
| Called from | `LoadDirectory` |
| Calls | `PrintString` (tail) |

### `IsMissionHeader` (`$71A1`)

**Z if the header at `$8AF2` starts "MISSHDR:" (8 bytes)**

Witness: L1 23 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 39 t-states own (0.00 %) |
| Runs (the other recordings) | 18 calls (`stage1/missions` 9, `stage1/play2` 3, `stage1/m2erbe` 1 and 5 more) |
| Called from | `LoadMissionHeader` |
| Calls | `CompareB` (tail) |

### `IsMissionBlock` (`$71AB`)

**Z if the block at `$DBC6` starts "MISSION::" (9 bytes)**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `IsDirectoryHeader` (`$71B3`)

**Z if the header at `$8AF2` is "DIRECTORY"**

Witness: L1 15 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 51 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/play2` 3, `stage1/m2ocean` 1, `stage1/death` 1 and 6 more) |
| Called from | `LoadDirectory` |
| Calls | `CompareNine` (tail) |

### `IsCatalogue` (`$71BB`)

**Z if the catalogue at `$CB64` starts "MISSION:T"**

Witness: L1 15 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 20 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/play2` 3, `stage1/death` 1, `stage1/m10` 1 and 6 more) |
| Called from | `LoadDirectory` |
| Calls | `CompareNine` (falls into) |

### `CompareNine` (`$71C1`)

**B = 9, then CompareB**

Witness: L1 30 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 14 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/play2` 6, `stage1/menu` 2, `stage1/death` 2 and 6 more) |
| Called from | `IsDirectoryHeader` (tail), `IsCatalogue` (falls into) |
| Calls | `CompareB` (falls into) |
| Reads | `$71DD`-`$71EF` (`DirectoryName`, `CatalogueName`); `$8AF2`-`$8AFA` (`BackBuffer+1`) |

### `CompareB` (`$71C3`)

**Compare B bytes at DE and HL: Z when equal**

Witness: L1 454 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3 calls, 1,283 t-states own (0.00 %) |
| Runs (the other recordings) | 38 calls (`stage1/missions` 11, `stage1/play2` 9, `stage1/m2ocean` 3 and 5 more) |
| Called from | `IsMissionHeader` (tail), `CompareNine` (falls into) |
| Reads | `$71D5`-`$71EF` (`MissionHeaderName+1`, `DirectoryName`, `CatalogueName`); `$8AF2`-`$8AFA` (`BackBuffer+1`) |

## tape

`src/game/tape.asm`

### `LoadBlock` (`$71F1`)

**Load a tape block to IX, length DE, flag A (carry: load) with the sound and the menu's flag set aside**

Under `DI`, with bank 6 `$D27C` (the pointer's save) and `$D283` = `$C010`, calls `LdBytes` `$8617`; restores `$D283` = `$C000` and the border, carry = loaded. Witness: L1 82 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 1,615 t-states own (0.00 %) |
| Runs (the other recordings) | 64 calls (`stage1/missions` 19, `stage1/m2ocean` 12, `stage1/play2` 10 and 6 more) |
| Called from | `LoadDirectory`, `LoadMissionHeader`, `RemarkMission` |
| Calls | `BorderBlack`, `PageBank6`, `SaveBank`, `RestoreBank`, `LdBytes` |

### `LdBytes` (`$8617`)

**The game's copy of the ROM's LD-BYTES (`$0556`): IX, DE, A, carry; border stripes; NC on an error**

The timings are the ROM's; the border colours of the stripes come from C. A block shorter than DE ends in a time-out of the edge reader (`LdEdge2` `$869F`), `RET NC`: Ocean's mission 2 header asks for 6406 bytes, its block holds 6384 (src/tape/side2.txt), so `LoadMissionBlock` retries for ever (m2ocean). Witness: L1 82 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 23,384,048 t-states own (3.54 %) |
| Runs (the other recordings) | 64 calls (`stage1/missions` 19, `stage1/m2ocean` 12, `stage1/play2` 10 and 6 more) |
| Called from | `LoadBlock` |
| Calls | `LdEdge2`, `LdEdge1` |
| Writes | `$8AF1`-`$8B01` (`BackBuffer`); `$DBC5`-`$FB3E` (`MissionHeader`) |
| Ports in | `$0FFE` |
| Ports out | `$0FFE` |

### `LdEdge2` (`$869F`)

**Two edges (the ROM's LD-EDGE-2)**

Witness: L1 2102599 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 122,820 calls, 2,702,040 t-states own (0.41 %) |
| Runs (the other recordings) | 1,559,293 calls (`stage1/missions` 520,787, `stage1/m2ocean` 269,839, `stage1/play2` 238,986 and 6 more) |
| Called from | `LdBytes` |
| Calls | `LdEdge1` (falls into) |

### `LdEdge1` (`$86A3`)

**One edge (the ROM's LD-EDGE-1), SPACE breaks**

Witness: L1 4378887 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 255,183 calls, 300,007,693 t-states own (45.37 %) |
| Runs (the other recordings) | 3,252,027 calls (`stage1/missions` 1,067,529, `stage1/m2ocean` 563,928, `stage1/play2` 507,394 and 6 more) |
| Called from | `LdBytes`, `LdEdge2` (falls into) |
| Ports in | `$7FFE` |
| Ports out | `$09FE`, `$0AFE`, `$0DFE`, `$0EFE` |

### `SaBytes` (`$86C1`)

**The game's copy of the ROM's SA-BYTES (`$04C2`): no recording runs it**

Witness: known only from the code (no caller found).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## paging

`src/game/paging.asm`

### `WaitFrameDone` (`$7225`)

**Wait until the interrupt clears `$83BA` (the 3D frame's blit is done)**

Witness: L1 3076073 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 124 calls, 611,226 t-states own (0.09 %) |
| Runs (the other recordings) | 3,614 calls (`stage1/death` 2,513, `stage1/play2` 425, `stage1/missions` 348 and 6 more) |
| Called from | `BriefingMapLegend`, `StatusMapLegend`, `FirstFrameHook` |
| Reads | `$83BA` (`BlitRequest+1`) |

### `BriefingMapLegend` (`$722C`)

**The briefing map's legend: wait for the frame, the attribute boxes `$DB01` and `$DB0B`, the text `$DAE1` ("Roads." / "Rivers."); called by bank 6 BriefingMap `$DB64`**

Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/menu` 10) |
| Calls | `AttrBox`, `PrintString` (tail), `WaitFrameDone` |

### `StatusMapLegend` (`$7241`)

**The status view map's legend: wait for the frame, the boxes `$DB10` and `$DAC1`, the text `$DAA1`; called by bank 6 StatusMap `$DB15`**

Witness: L1 40 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 40 calls (`stage1/missions` 34, `stage1/m2erbe` 4, `stage1/play` 2) |
| Calls | `AttrBox`, `PrintString`, `WaitFrameDone` |

### `FirstFrameHook` (`$7256`)

**A NOP the first time: WaitFrameDone, then patched to RET**

Witness: L1 13555 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 289 calls, 8,095 t-states own (0.00 %) |
| Runs (the other recordings) | 6,283 calls (`stage1/death` 2,637, `stage1/play2` 1,458, `stage1/missions` 1,171 and 6 more) |
| Called from | `PlayLoopTail`, `DragonflyViewLoop` |
| Calls | `WaitFrameDone`, `PageBank0Main` (falls into) |
| Writes | `$7256` (`FirstFrameHook`) |

### `PageBank0Main` (`$725F`)

**A = 0 then PageMain**

Witness: L1 9925 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 124 calls, 633 t-states own (0.00 %) |
| Runs (the other recordings) | 3,607 calls (`stage1/death` 2,512, `stage1/play2` 425, `stage1/missions` 316 and 6 more) |
| Called from | `DamageLoop`, `FirstFrameHook` (falls into) |
| Calls | `PageMain` (falls into) |

### `PageMain` (`$7260`)

**Set the screen bit (`$7284`, the OR operand) to A and re-page the current bank**

Witness: L1 10090 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 130 calls, 5,516 t-states own (0.00 %) |
| Runs (the other recordings) | 3,740 calls (`stage1/death` 2,515, `stage1/play2` 440, `stage1/missions` 374 and 6 more) |
| Called from | `PageBank0Main` (falls into), `PageShadowScreen` (tail) |
| Calls | `PageOut` (tail) |
| Reads | `$728A` (`SaveBank+2`) |
| Writes | `$7284` (`PageOut+4`) |

### `PageShadowScreen` (`$7268`)

**A = 8 (the shadow screen bit of `$7FFD`) then PageMain**

Witness: L1 165 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6 calls, 149 t-states own (0.00 %) |
| Runs (the other recordings) | 133 calls (`stage1/missions` 58, `stage1/menu` 33, `stage1/play2` 15 and 6 more) |
| Called from | `StartMission`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `PageMain` (tail) |

### `PageBank3` (`$726C`)

**Page bank 3 at `$C000`**

Witness: L1 266011 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11,125 calls, 312,339 t-states own (0.05 %) |
| Runs (the other recordings) | 147,491 calls (`stage1/missions` 65,118, `stage1/play2` 34,565, `stage1/death` 24,252 and 6 more) |
| Called from | `Bank3SetObject`, `Bank3Step`, `Bank3Lookup`, `Bank3Render`, `Bank3Fill`, `LoadMission`, `RemarkMission`, `Debris`, `DrawEntry` |
| Calls | `PageBankA` (tail) |

### `PageBank4` (`$7270`)

**Page bank 4 at `$C000`**

Witness: L1 135412 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,423 calls, 86,465 t-states own (0.01 %) |
| Runs (the other recordings) | 72,017 calls (`stage1/death` 15,296, `stage1/play2` 14,436, `stage1/missions` 14,068 and 6 more) |
| Called from | `CopyCatalogueHead`, `CopyMissionText`, `LoadDirectory`, `Bank4Start`, `Bank4Tick`, `Bank4Call` |
| Calls | `PageBankA` (tail) |

### `PageBank7` (`$7274`)

**Page bank 7 at `$C000`**

Witness: L1 142 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 95 t-states own (0.00 %) |
| Runs (the other recordings) | 115 calls (`stage1/missions` 50, `stage1/menu` 28, `stage1/play2` 12 and 6 more) |
| Called from | `DrawBank7Picture` |
| Calls | `PageBankA` (tail) |

### `PageBank6` (`$7278`)

**Page bank 6 at `$C000`**

Witness: L1 336465 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 12,131 calls, 236,130 t-states own (0.04 %) |
| Runs (the other recordings) | 193,204 calls (`stage1/missions` 39,950, `stage1/play2` 38,989, `stage1/death` 33,419 and 6 more) |
| Called from | `Entry`, `ResetCollisionTables` (tail), `StartMission`, `PlayLoopTail`, `DragonflyViewLoop`, `PanelSetup`, `StatusLoop`, `DamageLoop`, `ShowBriefingMapOnce`, `CopyCatalogueHead`, `CopyMissionText`, `LoadDirectory`, `LoadBlock`, `Bank3Render` (tail), `UpdateSlotBars`, `DrawBank7Picture`, `LoadMissionIfAllowed`, `PageBank6Kept` (tail), `QuitKey`, `LoadMissionHeader` (tail), `RemarkMission`, `MissionSetup` |
| Calls | `PageBankA` (tail) |

### `PageBank0` (`$727C`)

**Page bank 0 at `$C000`**

Witness: L1 263276 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 12,132 calls, 58,229 t-states own (0.01 %) |
| Runs (the other recordings) | 168,750 calls (`stage1/missions` 69,617, `stage1/play2` 36,976, `stage1/death` 20,661 and 6 more) |
| Called from | `ResetCollisionTables`, `StartMission`, `DragonflyViewLoop`, `PanelSetup` (tail), `StatusLoop`, `DamageLoop`, `Bank0SoundOff`, `SoundTick`, `LoadMission`, `RemarkMission`, `MissionSetup` |
| Calls | `PageBankA` (falls into) |

### `PageBankA` (`$727D`)

**Page bank A: kept in `$728A`, OR the screen bit, OUT to `$7FFD`**

Witness: L1 1454779 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 54,728 calls, 810,821 t-states own (0.12 %) |
| Runs (the other recordings) | 813,537 calls (`stage1/missions` 235,278, `stage1/play2` 172,428, `stage1/death` 143,043 and 6 more) |
| Called from | `PageBank3` (tail), `PageBank4` (tail), `PageBank7` (tail), `PageBank6` (tail), `PageBank0` (falls into), `RestoreBank`, `DrawBank7Picture` (tail), `PageBankKept` (tail) |
| Calls | `PageOut` (falls into) |
| Writes | `$728A` (`SaveBank+2`) |

### `PageOut` (`$7280`)

**PageOut**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 54,858 calls, 2,447,543 t-states own (0.37 %) |
| Runs (the other recordings) | 817,277 calls (`stage1/missions` 235,652, `stage1/play2` 172,868, `stage1/death` 145,558 and 6 more) |
| Called from | `PageMain` (tail), `PageBankA` (falls into) |
| Ports out | `$7FFD` |

### `SaveBank` (`$7288`)

**Keep the current bank (`$728A`) in the operand `$729D` of RestoreBank**

Witness: L1 134817 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,278 calls, 201,645 t-states own (0.03 %) |
| Runs (the other recordings) | 48,310 calls (`stage1/death` 18,837, `stage1/play2` 10,541, `stage1/missions` 9,592 and 6 more) |
| Called from | `StartMission`, `ShowBriefingMapOnce`, `CopyCatalogueHead`, `CopyMissionText`, `LoadBlock`, `Bank3SetObject`, `Bank3Step`, `Bank3Lookup`, `Bank4Start`, `Bank0SoundOff`, `Bank4Call`, `UpdateSlotBars`, `Bank3Fill`, `QuitKey`, `Debris`, `DrawEntry` |
| Writes | `$729D` (`RestoreBank+2`) |

### `Bank3SetObject` (`$7290`)

**Save the bank, call bank 3 `$C4C4` with A, restore**

Witness: L1 94721 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,908 calls, 262,067 t-states own (0.04 %) |
| Runs (the other recordings) | 35,608 calls (`stage1/death` 11,167, `stage1/play2` 8,320, `stage1/missions` 8,192 and 6 more) |
| Called from | `FillFaceList`, `FillFaceListClipped`, `OpFillPolys`, `OpFillPolysClipped` |
| Calls | `PageBank3`, `SaveBank` |

### `RestoreBank` (`$729B`)

**Page the bank SaveBank kept (A and the flags kept)**

Witness: L1 134816 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 370 calls, 217,836 t-states own (0.03 %) |
| Runs (the other recordings) | 12,693 calls (`stage1/death` 7,669, `stage1/play2` 2,220, `stage1/missions` 1,399 and 6 more) |
| Called from | `StartMission`, `ShowBriefingMapOnce`, `CopyCatalogueHead` (tail), `CopyMissionText` (tail), `LoadBlock`, `Bank3Step` (tail), `Bank3Lookup` (tail), `Bank4Start` (tail), `Bank0SoundOff` (tail), `Bank4Call` (tail), `UpdateSlotBars`, `Bank3Fill` (tail), `QuitKey`, `Debris` (tail), `DrawEntry` |
| Calls | `PageBankA` |

### `Bank3Step` (`$72A3`)

**Save the bank, call bank 3 `$D08C` and `$D1EC`, restore**

Witness: L1 9770 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 11,780 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop` |
| Calls | `PageBank3`, `SaveBank`, `RestoreBank` (tail) |

### `Bank3Lookup` (`$72B1`)

**Save the bank, call bank 3 `$C9A7` with A, restore**

Witness: L1 18311 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 12,282 t-states own (0.00 %) |
| Runs (the other recordings) | 4,882 calls (`stage1/death` 2,261, `stage1/play2` 1,192, `stage1/missions` 733 and 3 more) |
| Called from | `OpLines`, `OpLinesClipped` |
| Calls | `PageBank3`, `SaveBank`, `RestoreBank` (tail) |

### `Bank3Render` (`$72BE`)

**Page bank 3, run the 3D frame driver `$990F`, page bank 6**

Witness: L1 3712 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 171 calls, 12,136 t-states own (0.00 %) |
| Runs (the other recordings) | 2,768 calls (`stage1/play2` 1,045, `stage1/missions` 897, `stage1/play` 432 and 6 more) |
| Calls | `PageBank3`, `PageBank6` (tail), `RunScript` |

### `Bank4Start` (`$72C6`)

**Save the bank, call bank 4 `$C000` with A = 0, restore**

Witness: L1 22 (c1, controls, fuel, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 225 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/missions` 8, `stage1/menu` 4, `stage1/play2` 3 and 2 more) |
| Calls | `PageBank4`, `SaveBank`, `RestoreBank` (tail) |

### `Bank4Tick` (`$72D2`)

**The interrupt's call of bank 4 `$C0D2`, the bank kept and restored**

Witness: L1 135242 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,415 calls, 274,701 t-states own (0.04 %) |
| Runs (the other recordings) | 71,878 calls (`stage1/death` 15,291, `stage1/play2` 14,418, `stage1/missions` 14,024 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `PageBank4`, `PageBank6Kept`, `PageBankKept` (tail) |

### `Bank0SoundOff` (`$72DE`)

**Save the bank, call bank 0 `$D807` (the sound off), restore**

Witness: L1 26 (armour, c1, controls, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 145 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/missions` 8, `stage1/menu` 4, `stage1/play2` 3 and 2 more) |
| Calls | `PageBank0`, `SaveBank`, `RestoreBank` (tail), `SilenceAY` |

### `Bank4Call` (`$72E9`)

**Save the bank, call bank 4 `$C1A2`, restore**

Witness: L1 32 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 126 t-states own (0.00 %) |
| Runs (the other recordings) | 25 calls (`stage1/missions` 9, `stage1/menu` 5, `stage1/play2` 3 and 6 more) |
| Calls | `PageBank4`, `SaveBank`, `RestoreBank` (tail) |

## hud

`src/game/hud.asm`

### `DrawSlotBarsLow` (`$72F4`)

**A = 4 then DrawWeaponBars**

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `DamageLoop` |
| Calls | `DrawWeaponBars` (tail) |

### `DrawSlotBars` (`$72F8`)

**A = 0 then DrawWeaponBars**

Witness: L1 3 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play` 3) |
| Called from | `DamageLoop` |
| Calls | `DrawWeaponBars` (falls into) |

### `DrawWeaponBars` (`$72F9`)

**Redraw each weapon record of `$68AB` whose value changed: its bar through DrawBar**

Witness: L1 4 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play` 4) |
| Called from | `DrawSlotBarsLow` (tail), `DrawSlotBars` (falls into) |
| Calls | `DrawBar` |
| Reads | `$68AB`-`$68E1` (`GaugeRecords`, `SlotGauges`) |
| Writes | `$68AC`-`$68DC` (`GaugeRecords+1`, `SlotGauges`); `$7309` (`l_72FF+10`) |

### `UpdateSlotBars` (`$7327`)

**Bank 6 UpdatePanelBars `$D58C` (heading strip, bearing, speed, fuel), then UpdateAmmoBars**

Witness: L1 9769 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

[Animation: `UpdateSlotBars` at work](img/routines/UpdateSlotBars.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 11,794 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoopTail` |
| Calls | `PageBank6`, `SaveBank`, `RestoreBank`, `UpdateAmmoBars` (falls into) |

### `UpdateAmmoBars` (`$7336`)

**For the four slots of `$8368`: a bar for each ammunition count that changed (records `$68C9`)**

Witness: L1 9800 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 94,726 t-states own (0.01 %) |
| Runs (the other recordings) | 3,509 calls (`stage1/death` 2,511, `stage1/play2` 416, `stage1/missions` 289 and 2 more) |
| Called from | `StartMission`, `UpdateSlotBars` (falls into) |
| Reads | `$68C9`-`$68E0` (`SlotGauges`); `$8368`-`$837A` (`WeaponSlots`) |
| Writes | `$68CA`-`$68DC` (`SlotGauges+1`); `$737B` (`l_737A+1`) |

### `l_7343` (`$7343`)

**l_7343**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_7362` (`$7362`)

**l_7362**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `DrawBar` |

### `DrawDamagePanel` (`$7383`)

**The nine weapon icons of the damage board (`$834A` records) with their frames**

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `DamageLoop` |
| Calls | `DrawIcon`, `IconFrame` |
| Reads | `$68AD`-`$68DE` (`GaugeRecords+2`, `SlotGauges`); `$740D` (`IconFrame+6`); `$834A`-`$837A` (`DamageBoardRecords`, `WeaponSlots`) |

### `DrawSlotIcons` (`$73BA`)

**The icons of the four loaded slots (`$8368` records, `$68CD`) with their frames**

Witness: L1 31 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 1,116 t-states own (0.00 %) |
| Runs (the other recordings) | 26 calls (`stage1/missions` 16, `stage1/play` 4, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission` |
| Calls | `DrawIcon` |
| Reads | `$68CD`-`$68E0` (`SlotGauges+4`); `$8368`-`$837A` (`WeaponSlots`) |

### `DrawIcon` (`$73E8`)

**Draw weapon icon A (1-19) from the icon table `$75CA` through CopyGraphic, 3 x 24**

Witness: L1 133 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 819 t-states own (0.00 %) |
| Runs (the other recordings) | 113 calls (`stage1/missions` 64, `stage1/play` 25, `stage1/play2` 12 and 2 more) |
| Called from | `DrawDamagePanel`, `DrawSlotIcons` |
| Calls | `CopyGraphic` (tail) |
| Reads | `$75CA`-`$75EF` (`IconTable`) |
| Writes | `$7408`-`$740D` (`IconFrame+1`) |

### `IconFrame` (`$7407`)

**The attribute frame of an icon at column E, pixel line A**

Witness: L1 9 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 9 calls (`stage1/play` 9) |
| Called from | `DrawDamagePanel` |
| Calls | `AttrBoxRC` (tail) |
| Writes | `$5856`-`$585D` (screen); `$5876`-`$587D` (screen); `$5896`-`$589D` (screen); `$58F6`-`$58FD` (screen); `$5916`-`$591D` (screen); `$5936`-`$593D` (screen); 6 more ranges |

### `DrawBarWide` (`$7438`)

**A bar of A pixels on line E, `$7E` pattern, 32 wide**

Witness: L1 10058 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 139 calls, 17,261 t-states own (0.00 %) |
| Runs (the other recordings) | 3,655 calls (`stage1/death` 2,523, `stage1/play2` 457, `stage1/missions` 362 and 2 more) |
| Calls | `BarLines` (tail) |
| Writes | `$7476`-`$747D` (`BarLines+18`); `$7494`-`$7497` (`l_747E+22`) |

### `DrawBar` (`$744F`)

**A bar of A pixels on line E, `$F8` pattern, 24 wide**

Witness: L1 11561 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 12,389 t-states own (0.00 %) |
| Runs (the other recordings) | 5,270 calls (`stage1/death` 2,511, `stage1/play2` 1,418, `stage1/play` 1,009 and 2 more) |
| Called from | `DrawWeaponBars`, `l_7362` |
| Calls | `BarLines` (falls into) |
| Writes | `$7476`-`$747D` (`BarLines+18`); `$7494`-`$7497` (`l_747E+22`) |

### `BarLines` (`$7464`)

**The bar's pixel lines through the line table `$6500`, `$AA` / `$55` dither**

Witness: L1 21619 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 258 calls, 757,422 t-states own (0.11 %) |
| Runs (the other recordings) | 8,925 calls (`stage1/death` 5,034, `stage1/play2` 1,875, `stage1/play` 1,270 and 2 more) |
| Called from | `DrawBarWide` (tail), `DrawBar` (falls into) |
| Reads | `$6500`-`$654F` (`ScreenRowTable`); `$6570`-`$659F` (`ScreenRowTable+112`); `$65C0`-`$65EF` (`ScreenRowTable+192`); `$6610`-`$665F` (`ScreenRowTable+272`) |
| Writes | `$400A`-`$4ADD` (screen); `$4B16`-`$4BDD` (screen); `$4C16`-`$4CDD` (screen); `$4D16`-`$4DDD` (screen); `$4E16`-`$4EDD` (screen); `$4F16`-`$4FDD` (screen); 2 more ranges |

### `DrawBank7Picture` (`$74AA`)

**Page bank 7 and run its picture routine `$FE95` with DE (a picture), then the bank back**

The panels and frames of the views are bank 7's pictures (DE = `$DD75` play, `$F9CD` map, `$D325` status, `$C000` Dragonfly). Clears `$83BF` (the play flag of the interrupt) and resets bank 6's `$D283` = `$C000`. Witness: L1 142 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 888 t-states own (0.00 %) |
| Runs (the other recordings) | 115 calls (`stage1/missions` 50, `stage1/menu` 28, `stage1/play2` 12 and 6 more) |
| Called from | `StartMission`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `PageBank7`, `PageBank6`, `PageBankA` (tail) |
| Reads | `$728A` (`SaveBank+2`) |
| Writes | `$83BF` (`PointerShown+1`) |

### `Bank3FillFF` (`$74C9`)

**A = `$FF` then Bank3Fill**

Witness: L1 19 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 19 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 1 and 2 more) |
| Calls | `Bank3Fill` (tail) |

### `Bank3Fill5F` (`$74CD`)

**A = `$5F` then Bank3Fill**

Witness: L1 19 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 7 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 2 more) |
| Calls | `Bank3Fill` (falls into) |

### `Bank3Fill` (`$74CF`)

**Save the bank, call bank 3 `$CFCD` with A, restore**

Witness: L1 38 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 208 t-states own (0.00 %) |
| Runs (the other recordings) | 28 calls (`stage1/missions` 16, `stage1/play2` 6, `stage1/m2erbe` 2 and 2 more) |
| Called from | `Bank3FillFF` (tail), `Bank3Fill5F` (falls into) |
| Calls | `PageBank3`, `SaveBank`, `RestoreBank` (tail) |

### `Bank0Call` (`$74DD`)

**Page bank 0, call `$CEA4`, page bank 6**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScreenOfMission` (`$757C`)

**Screen 1 unless the current mission (`$757D`) is `$FF` or not completed**

`LD A,n`: n (`$757D`) is the mission the tape gave (`$8528`: the header's digit - "1"). Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/menu` 10) |
| Called from | `PointerZones` |
| Calls | `ScreenTwo` (tail), `MissionDone` |

### `MissionLoaded` (`$7588`)

**If a mission is loaded: bank 6 `$CBF4`, `$D27C`, `$CA23`, then screen 0**

Witness: known only from the code (entered by a jump from `$75B8`).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ScreenZero` (tail) |

### `LoadMissionIfAllowed` (`$759A`)

**Load the mission the tape holds; mission 10 only when the nine completion flags are set**

If the current mission (C) is 9 (Grand Finale), the nine bytes `$6799-$67A1` are ANDed: if any is 0 the mission is refused (`RET Z` back into the catalogue's zone loop; recording m10: the catalogue stays on screen, 4972-7972). Otherwise `LoadMission` `$84C1`. Witness: L1 22 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 232 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/missions` 9, `stage1/play2` 3, `stage1/m10` 1 and 4 more) |
| Called from | `PointerZones` |
| Calls | `PageBank6`, `MissionDone`, `LoadMission` |
| Reads | `$6799`-`$67A1` (`MissionsDone`); `$757D` (`ScreenOfMission+1`) |

### `MissionDone` (`$75BB`)

**A = the completion flag of the current mission (`$6799` + n): NZ when done**

Witness: L1 32 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 75 t-states own (0.00 %) |
| Runs (the other recordings) | 27 calls (`stage1/menu` 10, `stage1/missions` 9, `stage1/play2` 3 and 5 more) |
| Called from | `ScreenOfMission`, `LoadMissionIfAllowed` |
| Reads | `$6799`-`$67A2` (`MissionsDone`); `$757D` (`ScreenOfMission+1`) |

## interrupt

`src/game/interrupt.asm`

### `SetMessage` (`$7D51`)

**Store the message timer: the attribute (IY+3) to `$7D64`, the hook `$7D5D` enabled**

Witness: L1 116 (armour, c1, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 20 calls, 1,464 t-states own (0.00 %) |
| Runs (the other recordings) | 41 calls (`stage1/play2` 40, `stage1/death` 1) |
| Called from | `PlayerHit` |
| Reads | `$762F` (`PlayerY+25`); `$7797` (`PlayerY+385`); `$77D3` (`PlayerY+445`); `$78C3` (`PlayerY+685`); `$7977` (`PlayerY+865`); `$79B3` (`PlayerY+925`); 4 more ranges |
| Writes | `$7D5D`-`$7D64` (`MessageOnce`) |

### `MessageOnce` (`$7D5D`)

**Once after SetMessage: the timer `$87D7` = 100; bit 4 of `$7D64` set: SoundExplosion `$D86B` and "TANK:HIT" `$FFCF`, clear: SoundEffectA `$D84E` and "COLLIDED" `$FFDB`; then RET again**

Patched to `RET` after one run. Witness: L1 9769 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 4,432 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoopTail` |
| Calls | `PrintString`, `SoundEffectA`, `SoundExplosion` |
| Writes | `$7D5D` (`MessageOnce`); `$87D7` (`MessageTimer+1`) |

### `PointerTick` (`$7D80`)

**Read the controls, move the pointer within the screen, test the fire**

`ReadControls` `$971A`, the X and Y steps (`$985E`, `$985F`) added to the pointer (`$7DC0`, `$7DC1`) within 8-247 and 8-183, then `PointerFire` `$7DC2`. Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

[Animation: `PointerTick` at work](img/routines/PointerTick.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 625,584 t-states own (0.09 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `ClampStep` (falls into), `PointerFire`, `ReadControls` |
| Reads | `$83BF` (`PointerShown+1`); `$985E`-`$985F` (`StepX`, `StepY`) |
| Writes | `$66CE` (`PolyClipVars+2`) |

### `ClampStep` (`$7DA7`)

**ClampStep**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,180 calls, 400,749 t-states own (0.06 %) |
| Runs (the other recordings) | 92,258 calls (`stage1/missions` 19,996, `stage1/play2` 19,046, `stage1/menu` 13,868 and 6 more) |
| Called from | `PointerTick` (falls into) |
| Reads | `$7DC0`-`$7DC1` (`PointerPos`) |
| Writes | `$7DC0`-`$7DC1` (`PointerPos`) |

### `PointerFire` (`$7DC2`)

**Carry (the fire) held: after 25 frames a click (`$6D43` = `$FF`) at the pointer, repeated every 5**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 159,201 t-states own (0.02 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `PointerTick` |
| Reads | `$7C51`-`$7C53` (`FailReason+88`); `$9717`-`$9718` (`FireHeld`, `FireCount`) |
| Writes | `$6D43` (`PointerZones+1`); `$9715`-`$9718` (`ClickState`, `ClickY`, `FireHeld`, `FireCount`) |

### `ClockTick` (`$7DFB`)

**The mission clock: the first second after 50 interrupts, then one second for every interrupt taken (the reload at `$7E03` is 1): 50 game seconds a real second**

The seconds, minutes and hours are in `$68EA`. A `NOP` while it runs; the mission load puts `RET` here (`$8612`); bank 6 writes the `NOP` back at START MISSION (`$CBB1`, StoresScreen's exit) and in QuitYes (`$DA55`). Witness: L1 121656 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 395,013 t-states own (0.06 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$68EA`-`$68EC` (`MissionClock`) |
| Writes | `$68EA`-`$68EC` (`MissionClock`); `$7DFD` (`ClockTick+2`) |

### `PrintClock` (`$7E3A`)

**Print the clock's minutes and hours (`$68EB`, `$68EC`) as two digit pairs**

Witness: L1 530 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 530 calls (`stage1/play` 492, `stage1/missions` 34, `stage1/m2erbe` 4) |
| Called from | `StatusLoop`, `BriefPage` |
| Calls | `PrintString` (tail) |
| Reads | `$68EB`-`$68EC` (`MissionClock+1`) |
| Writes | `$7E34`-`$7E38` (`ClockText+5`) |

### `SoundTick` (`$7E6E`)

**The interrupt's sound step: bank 0's driver `$D692`, the bank kept**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 251,564 t-states own (0.04 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `PageBank0`, `PageBank6Kept`, `PageBankKept` (tail), `SoundFrame` |

### `ClearPointerState` (`$7E7A`)

**`$66CE` and the click flag cleared**

Witness: L1 3734 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 171 calls, 8,134 t-states own (0.00 %) |
| Runs (the other recordings) | 2,779 calls (`stage1/play2` 1,045, `stage1/missions` 898, `stage1/play` 433 and 6 more) |
| Writes | `$66CE` (`PolyClipVars+2`); `$6D43` (`PointerZones+1`) |

### `InterruptHandler` (`$8383`)

**The IM 2 handler: own stack, the tick jobs, the play or menu jobs, RETI**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 1,987,279 t-states own (0.30 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Entered by | the interrupt, 38,000 times in 209 routines |
| Calls | `Bank4Tick`, `PointerTick`, `ClockTick`, `SoundTick`, `ClearMarkColumn`, `HandlerExit` (tail), `PageBank6Kept`, `PageBankKept`, `BlinkWarning`, `BlinkLamp`, `KeyRepeat`, `MessageTimer`, `TimeOfDay`, `SkyColours`, `NightColours`, `CopyPointer`, `ViewBlitFront`, `ViewBlitWide`, `ViewBlitNarrow`, `ClearBlitRequest` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$83BF` (`PointerShown+1`) |
| Writes | `$815D`-`$81FE` (`LoadAttrLeftover+281`, `ImJump`, `Stack`); `$842B`-`$842C` (`SavedSP+1`); `$FD00`-`$FD07` (`MissionHeader+8507`); `$FD42`-`$FD53` (`MissionHeader+8573`); `$FE00`-`$FE07` (`MissionHeader+8763`); `$FE42`-`$FE53` (`MissionHeader+8829`); 2 more ranges |

### `ClearMarkColumn` (`$83F1`)

**A RET; behind it the clear of three bytes every 33 for 48 lines from `$8AF1` (unused)**

Witness: L1 3717 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 171 calls, 336,408 t-states own (0.05 %) |
| Runs (the other recordings) | 2,773 calls (`stage1/play2` 1,042, `stage1/missions` 897, `stage1/play` 430 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `HandlerExit` (tail), `PageBank6Kept`, `PageBankKept`, `CopyPointer` |
| Writes | `$8AF1`-`$8FF3` (`BackBuffer`); `$9011`-`$9013` (`BackBuffer+1312`); `$9031`-`$9033` (`BackBuffer+1344`); `$9051`-`$9053` (`BackBuffer+1376`); `$9071`-`$9073` (`BackBuffer+1408`); `$9091`-`$9093` (`BackBuffer+1440`); 2 more ranges |

### `HandlerExit` (`$841C`)

**HandlerExit**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,205 calls, 698,006 t-states own (0.11 %) |
| Runs (the other recordings) | 22,173 calls (`stage1/death` 10,155, `stage1/play2` 4,476, `stage1/missions` 3,710 and 6 more) |
| Called from | `InterruptHandler` (tail), `ClearMarkColumn` (tail) |

### `PageBank6Kept` (`$8431`)

**Keep the current bank in `$843B` and page bank 6**

Witness: L1 318515 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11,629 calls, 418,788 t-states own (0.06 %) |
| Runs (the other recordings) | 183,536 calls (`stage1/play2` 36,898, `stage1/missions` 36,833, `stage1/death` 30,572 and 6 more) |
| Called from | `Bank4Tick`, `SoundTick`, `InterruptHandler`, `ClearMarkColumn` |
| Calls | `PageBank6` (tail) |
| Reads | `$728A` (`SaveBank+2`) |
| Writes | `$843B` (`PageBankKept+1`) |

### `PageBankKept` (`$843A`)

**Page the bank PageBank6Kept kept**

Witness: L1 318515 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11,629 calls, 197,693 t-states own (0.03 %) |
| Runs (the other recordings) | 183,536 calls (`stage1/play2` 36,898, `stage1/missions` 36,833, `stage1/death` 30,572 and 6 more) |
| Called from | `Bank4Tick` (tail), `SoundTick` (tail), `InterruptHandler`, `ClearMarkColumn` |
| Calls | `PageBankA` (tail) |

### `QuitKey` (`$843F`)

**The key E: silence the AY (`$D807`), ask "Are you sure you want to quit?" (bank 6 QuitPrompt `$DA09`: Y to the title, N back), then clear SoundGate `$D689` and PickupAnnounce `$DB71`**

Witness: L1 13 (m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 1 more) |
| Called from | `PlayKeys` (tail) |
| Calls | `PageBank6`, `SaveBank`, `RestoreBank`, `SilenceAY` |
| Writes | `$D689` (`SoundGate`); `$DB71` (`PickupAnnounce`) |

### `BlinkWarning` (`$8459`)

**Every 12 frames flip the attribute bits `$30` of `$5758` and `$5078` (a RET while off)**

Witness: L1 121656 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 76,770 t-states own (0.01 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$5078` (screen); `$5758` (screen) |
| Writes | `$5078` (screen); `$5758` (screen); `$845B` (`BlinkWarning+2`) |

### `BlinkLamp` (`$8475`)

**Every 8 frames flip `$3C` on four pixel lines at `$525C` (a RET while off)**

Witness: L1 121656 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 41,240 t-states own (0.01 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$525C` (screen); `$535C` (screen); `$545C` (screen); `$555C` (screen) |
| Writes | `$525C` (screen); `$535C` (screen); `$545C` (screen); `$555C` (screen); `$8477` (`BlinkLamp+2`) |

### `KeyRepeat` (`$848F`)

**Scan the keyboard: a new key sets bit 0 of `$8978` at once, a held key after 17 frames, then every 2**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 327,948 t-states own (0.05 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `ScanKeyboard` |
| Reads | `$8978`-`$897A` (`KeyState`, `KeyCode`, `KeyRepeatCount`) |
| Writes | `$8978`-`$897A` (`KeyState`, `KeyCode`, `KeyRepeatCount`) |

### `MessageTimer` (`$87D6`)

**Count `$87D7` down; at 0 print the message line `$7C06` (or the blank `$87F0`)**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 102,614 t-states own (0.02 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `PrintString` (tail) |
| Writes | `$87D7` (`MessageTimer+1`) |

### `NightKey` (`$87FC`)

**The key N: LD A,n (n = `$87FD`), then ToggleNight**

Witness: L1 6 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 6 calls (`stage1/play` 6) |
| Called from | `PlayKeys` (tail) |
| Calls | `ToggleNight` (falls into) |

### `ToggleNight` (`$87FF`)

**Night sight on or off: the lamp attribute `$5ACF`, the text `$BA6E` / `$BA7A`, `$757A` from the table `$88F8`**

Witness: L1 37 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 151 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/missions` 16, `stage1/play` 10, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission`, `NightKey` (falls into) |
| Calls | `PrintString` (tail) |
| Reads | `$88FB`-`$8907` (`HourTable+3`) |
| Writes | `$5ACF` (screen); `$6B45` (`PlayKeys+10`); `$757A` (`AwolState+2`); `$87FD` (`NightKey+1`); `$885F` (`SkyColours`); `$88CF` (`NightColours`) |

### `TimeOfDay` (`$8836`)

**Each interrupt: the hour (`$68EC`) against the four 4-byte rows of `$88F8`; a match arms `$885F`**

Witness: L1 121656 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 936,113 t-states own (0.14 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$68EC` (`MissionClock+2`); `$88F8`-`$8904` (`HourTable`) |
| Writes | `$8823`-`$8824` (`l_8818+11`); `$8845` (`l_8841+4`); `$885F` (`SkyColours`); `$88D6` (`NightBoxSelect+1`) |

### `SkyColours` (`$885F`)

**Once per change: the sky and ground attributes of the hour's row, then the panel's copies**

Witness: L1 13586 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 291 calls, 4,367 t-states own (0.00 %) |
| Runs (the other recordings) | 6,349 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,213 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `AttrBoxAt` |
| Reads | `$5940` (screen); `$5960`-`$596E` (screen); `$59A0`-`$59AA` (screen); `$5A02` (screen); `$87FD` (`NightKey+1`); `$8823`-`$8824` (`l_8818+11`); 1 more ranges |
| Writes | `$59C0`-`$59E2` (screen); `$59FD`-`$59FE` (screen); `$757A` (`AwolState+2`); `$885F`-`$8861` (`SkyColours`) |

### `CopySkyRows` (`$88A8`)

**CopySkyRows**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play` 3) |
| Called from | `NightBoxSelect` (tail) |
| Reads | `$5940` (screen); `$5960`-`$596E` (screen); `$59A0`-`$59AA` (screen) |
| Writes | `$59C0`-`$59E2` (screen); `$59FD`-`$59FE` (screen) |

### `NightColours` (`$88CF`)

**Once: the night or day attribute box (`$88EE` / `$88F3`)**

Witness: L1 13586 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 291 calls, 3,192 t-states own (0.00 %) |
| Runs (the other recordings) | 6,349 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,213 and 6 more) |
| Called from | `InterruptHandler` |
| Writes | `$757A` (`AwolState+2`); `$88CF` (`NightColours`) |

### `NightBoxSelect` (`$88D5`)

**NightBoxSelect**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `AttrBox`, `CopySkyRows` (tail) |

### `ScanKeyboard` (`$8910`)

**Scan the eight half rows: the key's code from `$8950` to `$897B`, bit 1 of `$8978` set; CAPS SHIFT with 0 gives `$04` (the code entry's delete)**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 7,389,409 t-states own (1.12 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `KeyRepeat` |
| Reads | `$8950`-`$8978` (`KeyCodes`, `KeyState`) |
| Writes | `$8978`-`$897D` (`KeyState`, `KeyCode`, `KeyRepeatCount`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `CopyPointer` (`$897E`)

**The pointer's X and Y to `$7C51` and `$7C53`**

Witness: L1 61639 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,092 calls, 191,748 t-states own (0.03 %) |
| Runs (the other recordings) | 46,146 calls (`stage1/missions` 10,006, `stage1/play2` 9,526, `stage1/menu` 6,938 and 6 more) |
| Called from | `InterruptHandler`, `ClearMarkColumn` |
| Reads | `$7DC0`-`$7DC1` (`PointerPos`) |
| Writes | `$7C51`-`$7C53` (`FailReason+88`) |

## bootstrap

`src/game/bootstrap.asm`

### `Bootstrap` (`$8000`)

**The loader's last code: page bank 1, copy `$C301-$FFFF` to `$8301`, page bank 0, JP `$68F4`**

Runs once at c1 frame 23974 (docs/03-build-and-load.md); dead after the entry. Witness: c1 only (not a read build).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 30,344 t-states own (0.00 %) |
| Calls | `Entry` |
| Writes | `$BA93`-`$BFFF` (`BinocularText`, `GroundDots`, `GridVectors`, `PlotGroundDot` and 24 more) |
| Ports out | `$7FFD` |

## missionload

`src/game/missionload.asm`

### `LoadMission` (`$84C1`)

**The mission load: the same mission again from bank 3's copy, or the tape's next mission block**

Pages bank 0, `$CC1E` with IX = `$75F0`; clears `$BA27`, `$CEA8`, `$87FD`, `$C4DC`. If the mission asked for (`$757D`) is the one loaded last (`$7E2E`), the bank-3 copy of `$DBDA`... is copied back to bank 0 (no tape). Else `$8551`: load the 17-byte header with "MISSHDR:" (`$84FE`), then the block of the header's length to `$DBC5`; SPACE stops. Then `$85F5` and `$8598` set the play state from the block. Witness: L1 20 (armour, c1, death, fuel, m1complete, m2erbe, m2ocean, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 714,554 t-states own (0.11 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/death` 1 and 3 more) |
| Called from | `LoadMissionIfAllowed` |
| Calls | `PageBank3`, `PageBank0`, `MissionSetup` (tail), `MissionTimeSetup`, `ResetPlayerHandler` |
| Reads | `$757D` (`ScreenOfMission+1`); `$7E2E` (`LastLoadedMission`); `$DBC5` (`MissionHeader`); `$DBDA`-`$DBDC` (`MissionHeader+21`); `$DBED`-`$FB3E` (`MissionHeader+40`) |
| Writes | `$6952` (`StartMission+7`); `$757B` (`AwolState+3`); `$7E2E` (`LastLoadedMission`); `$7E82`-`$7E8D` (`MissionParams`); `$84E6`-`$84E7` (`LoadMission+37`); `$87FD` (`NightKey+1`); 7 more ranges |

### `LoadMissionHeader` (`$84FE`)

**Load 17-byte headers until one is "MISSHDR:"; its length to `$855C`, its digit - "1" to `$757D`, the mark on the clipboard**

Witness: L1 25 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 318 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/missions` 9, `stage1/play2` 3, `stage1/search` 3 and 5 more) |
| Called from | `PointerZones` |
| Calls | `IsMissionHeader`, `LoadBlock`, `PageBank6` (tail), `MarkMission` (falls into) |
| Reads | `$8AFA`-`$8AFD` (`BackBuffer+9`) |
| Writes | `$58E3`-`$5902` (screen); `$5922` (screen); `$5942` (screen); `$5962` (screen); `$5982` (screen); `$59A2` (screen); 8 more ranges |

### `MarkMission` (`$8535`)

**The attribute C on the catalogue line of mission A (`$5902` + 32A)**

Witness: L1 35 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 24 calls (`stage1/missions` 17, `stage1/play2` 5, `stage1/m2erbe` 2) |
| Called from | `LoadMissionHeader` (falls into), `RemarkMission` (tail) |
| Writes | `$5902` (screen); `$5922` (screen); `$5942`-`$5962` (screen); `$5982` (screen); `$59A2` (screen); `$59C2` (screen); 4 more ranges |

### `RemarkMission` (`$8548`)

**Mark the last header's mission again (`$C4`) unless none**

Witness: L1 36 (armour, c1, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 28 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 6 more) |
| Calls | `LoadBlock`, `PageBank3`, `PageBank6`, `PageBank0`, `MarkMission` (tail), `MissionSetup` (falls into), `SpacePressed`, `MissionTimeSetup` |
| Reads | `$8547` (`HeaderMission`) |

### `MissionSetup` (`$8598`)

**From the loaded block: 12 bytes to `$7E82`, `$DBFD` to `$CAAF`, the object count to bank 6, the objects copied to bank 3**

Witness: L1 19 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play2` 3) |
| Called from | `LoadMission` (tail), `RemarkMission` (falls into) |
| Calls | `PageBank6`, `PageBank0` |
| Reads | `$757D` (`ScreenOfMission+1`); `$DBDC` (`MissionHeader+23`); `$DBF1`-`$DCBB` (`MissionHeader+44`) |
| Writes | `$6952` (`StartMission+7`); `$7E2E` (`LastLoadedMission`); `$7E82`-`$7E8D` (`MissionParams`); `$C529` (`WeaponVars+2`); `$CAAF` (`PlayerHit+10`); `$D52E` (`PlaceHelicarrier`) |

### `SpacePressed` (`$85EF`)

**NC when SPACE is held (port `$7FFE` bit 0)**

Witness: L1 8 (m2ocean).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/m2ocean` 8) |
| Called from | `RemarkMission` |
| Ports in | `$7FFE` |

### `MissionTimeSetup` (`$85F5`)

**From the header: `$DBE1` to `$6A67`, 8 bytes `$DBE3` to `$7611`, the time limit `$DBFE` to `$68EB`, the clock stopped**

Witness: L1 19 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 395 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 2 more) |
| Called from | `LoadMission`, `RemarkMission` |
| Reads | `$DBE1`-`$DBEA` (`MissionHeader+28`); `$DBFE`-`$DBFF` (`MissionHeader+57`) |
| Writes | `$68EA`-`$68EC` (`MissionClock`); `$6A67`-`$6A68` (`PlayLoopTail+16`); `$7611`-`$7618` (`PlayerHandler+9`, `PlayerHeading`, `PlayerX`, `PlayerY`); `$7DFB` (`ClockTick`) |

## raster

`src/game/raster.asm`

### `ViewBlitLow` (`$898B`)

**Another entry of ViewBlitFront: the back buffer from its row 8 (`$8BF1`) to the screen from row 40, 71 rows full width, then the cockpit rows**

Saves `SP` at `$8A3E`, HL = `$8BF1`, the row count `$47`, `SP` = ScreenRowTable `$6550`, then `JR` into ViewBlitFront's loop at `$89A5`. PickupMessage `$DB77` (bank 0) stores it in the blit pointer `$83E6` once the goal flag `$68E8` is set (`$DB7C`); m1complete runs it 530 times after its goal (frame 16138 on).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ViewBlitFront` (`$8999`)

**Copy the back buffer to the screen rows 32-126: the front view with the cockpit cut-outs**

With `SP` on ScreenRowTable `$6540` (row 32): 79 rows of 32 bytes (`LDI` x 32), then 8 rows of 11 + 11 bytes (the middle 10 bytes skipped, the cockpit), then 8 rows of 2 + 2 bytes (the outer columns only). `SP` is saved at `$8A3E`. Runs under the interrupt (the routine pointer `$83E6`).

Input: none. Output: the screen bitmap `$4080-$4CCA` (L1). Cost: 97 permille of play (the heaviest single routine of the view).

Witness: L1 8222 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

[Animation: `ViewBlitFront` at work](img/routines/ViewBlitFront.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 6,496,678 t-states own (0.98 %) |
| Runs (the other recordings) | 3,482 calls (`stage1/death` 2,509, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `InterruptHandler` |
| Reads | `$8AF1`-`$95D3` (`BackBuffer`); `$95EE`-`$95F3` (`BackBuffer+2813`); `$960E`-`$9613` (`BackBuffer+2845`); `$962E`-`$9633` (`BackBuffer+2877`); `$964E`-`$9653` (`BackBuffer+2909`); `$966E`-`$9673` (`BackBuffer+2941`); 3 more ranges |
| Writes | `$4080`-`$48E2` (screen); `$48FD`-`$49E2` (screen); `$49FD`-`$4AE2` (screen); `$4AFD`-`$4BE2` (screen); `$4BFD`-`$4CE2` (screen); `$4CFD`-`$4DE2` (screen); 4 more ranges |

### `ViewBlitWide` (`$8A41`)

**Copy the 86 top rows of the back buffer to the screen rows 64-149, full width**

`SP` on ScreenRowTable `$6580` (row 64), 86 rows of 32 bytes. Used by the menus and the console views (11 recordings).

Witness: L1 768 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 52 calls, 2,796,700 t-states own (0.42 %) |
| Runs (the other recordings) | 389 calls (`stage1/menu` 135, `stage1/missions` 126, `stage1/play2` 51 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$8AF1`-`$95B0` (`BackBuffer`) |
| Writes | `$4800`-`$505F` (screen); `$5100`-`$515F` (screen); `$5200`-`$525F` (screen); `$5300`-`$535F` (screen); `$5400`-`$545F` (screen); `$5500`-`$555F` (screen); 3 more ranges |

### `ViewBlitNarrow` (`$8A98`)

**Copy 95 rows of 22 bytes (back-buffer columns 5-26) to the screen rows 40-134 at column 6**

`SP` on ScreenRowTable `$6550` (row 40); each row `INC E` x 6, 22 `LDI`, skip 10. Only the play recording runs it (the binoculars or the rear view).

Witness: L1 24 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 24 calls (`stage1/play` 24) |
| Called from | `InterruptHandler` |
| Reads | `$8AF6`-`$96CB` (`BackBuffer+5`) |
| Writes | `$40A6`-`$501B` (screen); `$5106`-`$511B` (screen); `$5206`-`$521B` (screen); `$5306`-`$531B` (screen); `$5406`-`$541B` (screen); `$5506`-`$551B` (screen); 2 more ranges |

### `ClearBlitRequest` (`$8AEC`)

**Clear the blit request `$83BA`: the interrupt's last job after a view blit**

Witness: L1 13586 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 291 calls, 7,992 t-states own (0.00 %) |
| Runs (the other recordings) | 6,349 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,213 and 6 more) |
| Called from | `InterruptHandler` |
| Writes | `$83BA` (`BlitRequest+1`) |

### `ClearBackBuffer` (`$96F1`)

**Zero the back buffer `$8AF1-$96F0` with 1536 PUSH HL**

Under `DI`: `SP` saved at `$9711`, `SP` = `$96F1`, HL = 0, 96 x 16 `PUSH HL`, `SP` back, `EI`. An interrupt in this time is lost (WALKTHROUGH section 1). Once per 3D pass: its count is the number of passes (705 in play).

Witness: L1 13569 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

[Animation: `ClearBackBuffer` at work](img/routines/ClearBackBuffer.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 290 calls, 5,282,350 t-states own (0.80 %) |
| Runs (the other recordings) | 6,338 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,212 and 6 more) |
| Called from | `StartViewPass` |
| Writes | `$9711`-`$9712` (`l_96FE+19`) |

### `ClipLine2D` (`$A184`)

**Clip the line (HL, DE) - (HL', DE') (x, y words) to the window; carry = something to draw, H, L, D, E = the ends as bytes**

Witness: L1 22892 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 8,892 t-states own (0.00 %) |
| Runs (the other recordings) | 6,050 calls (`stage1/death` 2,494, `stage1/play2` 1,548, `stage1/missions` 975 and 3 more) |
| Called from | `OpLines`, `OpLinesClipped` |
| Calls | `ClipLineCodes` |

### `ClipLineCodes` (`$A192`)

**Cohen-Sutherland: both out codes (`$A3AC`), reject, accept, or cut an end by bisection (`$A1B3`, `$A218`)**

Witness: L1 22892 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 7,752 t-states own (0.00 %) |
| Runs (the other recordings) | 6,050 calls (`stage1/death` 2,494, `stage1/play2` 1,548, `stage1/missions` 975 and 3 more) |
| Called from | `ClipLine2D` |
| Calls | `ClipOneEnd` (falls into), `ClipAccept` (tail), `ClipReject` (tail), `OutCode` |
| Reads | `$A17E`-`$A17F` (`ClipWindow+2`) |
| Writes | `$985C`-`$985D` (`InputState`); `$A180`-`$A183` (`ClipWindow+4`); `$A277`-`$A28B` (`l_A26E+9`) |

### `ClipOneEnd` (`$A1B3`)

**One end outside: find the crossing of the window edge by bisection (`$A2BA`, `$A2CA`, `$A2F3`, `$A352`)**

Witness: L1 4809 (death, m1complete, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 160 calls (`stage1/missions` 160) |
| Called from | `ClipLineCodes` (falls into), `ClipBothEnds` |
| Calls | `SwapLineEnds`, `ClipToRight` (tail), `ClipToBottom` (tail), `ClipToLeft` (tail), `ClipToCorner` (tail) |
| Reads | `$A17E`-`$A17F` (`ClipWindow+2`) |
| Writes | `$A180`-`$A183` (`ClipWindow+4`) |

### `SwapLineEnds` (`$A1F6`)

**Swap the two ends of the line between the register sets**

Witness: L1 5050 (death, m1complete, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 273 calls (`stage1/missions` 216, `stage1/death` 57) |
| Called from | `ClipOneEnd` |

### `ClipBothEnds` (`$A218`)

**Both ends outside on different sides: bisect for the middle point, then clip each half**

Entered by a jump, never called (the survey counts 0 calls).

Witness: L1 761 (m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/missions`) |
| Calls | `ClipOneEnd`, `ClipAccept` (falls into), `ClipReject` (tail), `OutCode` |
| Reads | `$985C`-`$985D` (`InputState`); `$A17C`-`$A17E` (`ClipWindow`) |
| Writes | `$985C`-`$985D` (`InputState`); `$A292`-`$A2A2` (`l_A26E+36`, `ClipAccept`) |

### `ClipAccept` (`$A29D`)

**Both ends inside: carry set**

Witness: L1 13978 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 1,596 t-states own (0.00 %) |
| Runs (the other recordings) | 4,771 calls (`stage1/death` 2,204, `stage1/play2` 1,192, `stage1/missions` 679 and 3 more) |
| Called from | `ClipLineCodes` (tail), `ClipBothEnds` (falls into) |

### `ClipToRight` (`$A2BA`)

**Bisect the outside end towards the right edge**

Witness: L1 400 (death, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 120 calls (`stage1/missions` 99, `stage1/death` 21) |
| Called from | `ClipOneEnd` (tail) |
| Calls | `ClipBisectStep` |
| Reads | `$A180`-`$A183` (`ClipWindow+4`) |

### `ClipToBottom` (`$A2CA`)

**Bisect the outside end towards the bottom edge**

Witness: L1 551 (death, m1complete, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 80 calls (`stage1/missions` 45, `stage1/death` 35) |
| Called from | `ClipOneEnd` (tail) |
| Calls | `ClipBisectStep` |
| Reads | `$A17C`-`$A183` (`ClipWindow`) |

### `ClipToLeft` (`$A2F3`)

**Bisect the outside end towards the left edge**

Witness: L1 171 (m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/missions` 14) |
| Called from | `ClipOneEnd` (tail) |
| Calls | `ClipBisectStep` |
| Reads | `$A17E`-`$A183` (`ClipWindow+2`) |

### `ClipToCorner` (`$A352`)

**Bisect the outside end towards a corner (two edges)**

Witness: L1 633 (death, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/missions` 2, `stage1/death` 1) |
| Called from | `ClipOneEnd` (tail) |
| Calls | `BisectToInside` |
| Reads | `$A17C`-`$A183` (`ClipWindow`) |

### `ClipReject` (`$A37F`)

**Both ends outside on one side: no carry**

Witness: L1 4581 (armour, death, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,168 calls (`stage1/play2` 356, `stage1/play` 337, `stage1/missions` 242 and 1 more) |
| Called from | `ClipLineCodes` (tail), `ClipBothEnds` (tail) |

### `ClipBisectStep` (`$A381`)

**One bisection step of the outside end towards the window**

Witness: L1 8285 (death, m1complete, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 214 calls (`stage1/missions` 158, `stage1/death` 56) |
| Called from | `ClipToRight`, `ClipToBottom`, `ClipToLeft` |

### `OutCode` (`$A3AC`)

**The out code of the point (HL, DE): 8 x < 0, 4 x > `$A17C`, 2 y < 0, 1 y > `$A17E`**

Witness: L1 46545 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 228 calls, 30,096 t-states own (0.00 %) |
| Runs (the other recordings) | 12,252 calls (`stage1/death` 4,988, `stage1/play2` 3,096, `stage1/missions` 2,102 and 3 more) |
| Called from | `ClipLineCodes`, `ClipBothEnds` |
| Reads | `$A17C`-`$A17E` (`ClipWindow`) |

### `BisectToInside` (`$A3E0`)

**Bisect the segment until the midpoint lies on the window edge**

Witness: L1 13621 (death, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/missions` 2, `stage1/death` 1) |
| Called from | `ClipToCorner` |

### `NearClipLineEnd` (`$A422`)

**The other end of a line behind the eye too: no carry (skip the line); else NearClipLine**

Witness: L1 5069 (death, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 266 calls (`stage1/missions` 220, `stage1/death` 46) |
| Called from | `OpLinesClipped` |
| Calls | `NearClipLine` (tail) |

### `NearClipLine` (`$A42B`)

**Cut the 3D segment V[B] - V[B'] at the near plane by bisection and project the cut: carry, HL / HL' = the screen point**

Reads both ends with `$A4D1` / `$A4F1` (vertex + the object position operands), halves the segment until depth - 96 is 0, then projects the point (Divide `$A687`, DivideByLog `$A6D2`, NegHL `$A771`) like OpProject. `$67B2-$67B5` hold the depths being halved.

Witness: L1 17666 (armour, c1, death, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 146 calls, 514,607 t-states own (0.08 %) |
| Runs (the other recordings) | 2,964 calls (`stage1/death` 1,501, `stage1/missions` 737, `stage1/play` 422 and 2 more) |
| Called from | `OpLinesClipped`, `NearClipLineEnd` (tail), `ClipPolyNear` |
| Calls | `FetchVertexXY`, `FetchVertexDepth`, `Divide`, `DivideByLog`, `NegHL` |
| Reads | `$67B2`-`$67B5` (`WorldVars+15`); `$9A72`-`$9A73` (`l_9A5E+20`); `$9AA3`-`$9AA4` (`l_9A9E+5`); `$9ABB`-`$9ABC` (`l_9A9E+29`) |
| Writes | `$67B2`-`$67B5` (`WorldVars+15`) |

### `FetchVertexXY` (`$A4D1`)

**x + `$9A8E` of V[B] to `$A503`, y + `$9AB3` to HL**

Witness: L1 35332 (armour, c1, death, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 292 calls, 49,932 t-states own (0.01 %) |
| Runs (the other recordings) | 5,928 calls (`stage1/death` 3,002, `stage1/missions` 1,474, `stage1/play` 844 and 2 more) |
| Called from | `NearClipLine` |
| Reads | `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$FD00`-`$FD07` (`MissionHeader+8507`); `$FD30`-`$FD4B` (`MissionHeader+8555`); `$FE00`-`$FE07` (`MissionHeader+8763`); `$FE30`-`$FE4B` (`MissionHeader+8811`) |
| Writes | `$A503`-`$A504` (`FetchVertexDepth+18`) |

### `FetchVertexDepth` (`$A4F1`)

**z + `$9A6C` - 96 of the vertex: the signed distance to the near plane**

Witness: L1 35332 (armour, c1, death, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 292 calls, 37,376 t-states own (0.01 %) |
| Runs (the other recordings) | 5,928 calls (`stage1/death` 3,002, `stage1/missions` 1,474, `stage1/play` 844 and 2 more) |
| Called from | `NearClipLine` |
| Reads | `$9A6C`-`$9A73` (`l_9A5E+14`); `$FF00`-`$FF07` (`data_FEBB+69`); `$FF30`-`$FF4B` (`data_FEBB+117`) |

### `ClipPolyNear` (`$A509`)

**Cut a face at the near plane (Sutherland-Hodgman on depth = 96) into PolyVerts `$6700`**

Walks the face's point offsets from IX; at each in / out change calls NearClipLine `$A42B` and appends the cut with AppendPolyVertex `$A677`. Returns carry = the polygon is complete (fill it), Z = go on with the next point, NZ = nothing left.

Witness: L1 13393 (armour, c1, death, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 73 calls, 50,982 t-states own (0.01 %) |
| Runs (the other recordings) | 3,914 calls (`stage1/death` 2,606, `stage1/play` 667, `stage1/missions` 364 and 2 more) |
| Called from | `FillFaceListClipped`, `l_A109` |
| Calls | `NearClipLine`, `AppendPolyVertex` |
| Reads | `$66CC`-`$66CD` (`PolyClipVars`); `$6798` (`GameVars`); `$67B1` (`WorldVars+14`); `$68A9` (`PanelGauges+1`); `$87A6`-`$87A7` (`ModelMissile+49`); `$87BF`-`$87C0` (`ModelMissile+74`); 10 more ranges |
| Writes | `$66CD` (`PolyClipVars+1`); `$6798` (`GameVars`); `$67B1` (`WorldVars+14`) |

### `AppendPolyVertex` (`$A677`)

**Append (BC, DE) to the polygon list at HL and count it in `$66D5`**

Witness: L1 15876 (armour, c1, death, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 146 calls, 14,190 t-states own (0.00 %) |
| Runs (the other recordings) | 4,022 calls (`stage1/death` 2,109, `stage1/missions` 1,049, `stage1/play` 486 and 2 more) |
| Called from | `ClipPolyNear` |
| Reads | `$66D5` (`PolyOutCount`) |
| Writes | `$66D5` (`PolyOutCount`); `$6700`-`$6717` (`PolyVerts`) |

### `Divide` (`$A687`)

**HL = 256 HL / DE (signed HL, positive DE) by logarithms; DE = log2 of the divisor, kept for a second DivideByLog**

Normalises DE to an 8-bit mantissa and an exponent, looks up LogFraction / LogInteger `$5C00`, then falls into DivideByLog. 283 939 calls (11 recordings).

Witness: L1 721062 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 17,109 calls, 2,369,353 t-states own (0.36 %) |
| Runs (the other recordings) | 265,747 calls (`stage1/death` 133,852, `stage1/play2` 47,330, `stage1/missions` 42,707 and 6 more) |
| Called from | `OpProject`, `NearClipLine`, `ShowMortarRange`, `BearingLookup`, `PlotGroundDot` |
| Calls | `DivideByLog` (falls into) |
| Reads | `$5C00`-`$5DFF` (`LogFraction`, `LogInteger`) |

### `DivideByLog` (`$A6D2`)

**HL = 256 HL / 2^(DE / 256): log of |HL|, minus DE, antilog by ExpFraction `$5E00`, the sign back**

The shift of the 9-bit mantissa is a self-patched `JR` into an `ADD HL,HL` chain (`$A739`, `$A75A`). A result below 1 gives 0 (`$A765`), an overflow `$3EE4` and carry (`$A769`). The most called 3D routine: 475 056 entries, 45 permille.

Witness: L1 1184207 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 30,613 calls, 8,889,499 t-states own (1.34 %) |
| Runs (the other recordings) | 442,277 calls (`stage1/death` 207,792, `stage1/play2` 81,736, `stage1/missions` 78,498 and 6 more) |
| Called from | `OpProject`, `NearClipLine`, `Divide` (falls into), `PlotGroundDot` |
| Calls | `ApplySign` (falls into), `ZeroQuotient` (tail) |
| Reads | `$5C00`-`$5EFF` (`LogFraction`, `LogInteger`, `ExpFraction`) |
| Writes | `$A73A` (`l_A739+1`); `$A75B` (`l_A75A+1`) |

### `ApplySign` (`$A745`)

**Negate HL when the sign saved in F' is set**

Witness: L1 1109957 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28,656 calls, 1,028,625 t-states own (0.16 %) |
| Runs (the other recordings) | 397,259 calls (`stage1/death` 198,736, `stage1/play2` 75,218, `stage1/missions` 74,760 and 2 more) |
| Called from | `DivideByLog` (falls into), `ZeroQuotient` |

### `ZeroQuotient` (`$A765`)

**HL = 0**

Witness: L1 74250 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,957 calls, 43,073 t-states own (0.01 %) |
| Runs (the other recordings) | 22,536 calls (`stage1/death` 9,056, `stage1/play2` 6,518, `stage1/missions` 3,738 and 2 more) |
| Called from | `DivideByLog` (tail) |
| Calls | `ApplySign` |

### `NegHL` (`$A771`)

**HL = -HL**

Witness: L1 786174 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 20,465 calls, 818,942 t-states own (0.12 %) |
| Runs (the other recordings) | 286,230 calls (`stage1/death` 124,659, `stage1/play2` 60,497, `stage1/missions` 50,225 and 6 more) |
| Called from | `OpProject`, `NearClipLine`, `BoxSquare`, `BoxHeights`, `BoxRect16`, `BoxRect`, `BoxTilted`, `GroundDots`, `PlotGroundDot`, `RotateToView`, `CollisionPass`, `HitSide` |

### `Random` (`$A779`)

**A = a pseudo-random byte: two additive words patched in place mixed with R (the mission vector `$67D0`)**

Witness: L1 2198 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 52 calls, 9,412 t-states own (0.00 %) |
| Runs (the other recordings) | 532 calls (`stage1/play2` 168, `stage1/death` 159, `stage1/missions` 97 and 2 more) |
| Called from | `ApiVector06` (tail) |
| Writes | `$A77C`-`$A788` (`Random+3`) |

### `AbsA` (`$A799`)

**A = |A| (the mission vector `$67D6`)**

Witness: L1 521328 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,328 calls, 125,956 t-states own (0.02 %) |
| Runs (the other recordings) | 173,252 calls (`stage1/death` 109,476, `stage1/play2` 22,376, `stage1/missions` 21,130 and 2 more) |
| Called from | `ApiVector08` (tail) |

### `NegDE` (`$A79E`)

**DE = -DE**

Witness: L1 12022 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 368 calls, 14,758 t-states own (0.00 %) |
| Runs (the other recordings) | 1,860 calls (`stage1/play2` 767, `stage1/death` 500, `stage1/missions` 378 and 2 more) |
| Called from | `BearingOctant` |

### `NegAbsHL` (`$A7A6`)

**HL = -|HL|**

Witness: known only from the code (no recording runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AbsHL` (`$A7AB`)

**HL = |HL|**

Witness: L1 6 (m1complete, m4complete, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `PlaceHelicarrier` |
| Calls | `NegateHL` (falls into) |

### `NegateHL` (`$A7AE`)

**HL = -HL (the mission vector `$67D3`)**

Witness: L1 51813 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 680 calls, 27,200 t-states own (0.00 %) |
| Runs (the other recordings) | 17,514 calls (`stage1/death` 9,455, `stage1/play` 3,394, `stage1/play2` 2,339 and 2 more) |
| Called from | `ApiVector07` (tail), `AbsHL` (falls into) |

### `HighTimes32` (`$A7B6`)

**HL = H * 32 (the back-buffer row offset of row H)**

Witness: L1 177524 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,911 calls, 15,644 t-states own (0.00 %) |
| Runs (the other recordings) | 66,854 calls (`stage1/death` 33,069, `stage1/play2` 12,731, `stage1/missions` 10,050 and 6 more) |
| Called from | `PlotBackBuffer` |
| Calls | `LowTimes32` (falls into) |

### `LowTimes32` (`$A7B7`)

**HL = L * 32**

Witness: L1 178905 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,986 calls, 287,265 t-states own (0.04 %) |
| Runs (the other recordings) | 68,020 calls (`stage1/death` 33,098, `stage1/play2` 13,048, `stage1/missions` 10,456 and 6 more) |
| Called from | `AttrBoxRC`, `HighTimes32` (falls into) |

### `MulSigned` (`$A7BF`)

**HL = A * E, signed bytes, by quarter squares: ((A+E)^2 - A^2 - E^2) / 2**

When A + E overflows it uses A^2 + E^2 - (A-E)^2 (`$A7DD`). Tables SquareLow / SquareHigh `$5F00`.

Witness: L1 240864 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 10,436 calls, 1,713,228 t-states own (0.26 %) |
| Runs (the other recordings) | 95,556 calls (`stage1/missions` 28,398, `stage1/play2` 23,764, `stage1/death` 16,546 and 6 more) |
| Called from | `TestFace` |
| Reads | `$5F00`-`$60FF` (`SquareLow`, `SquareHigh`) |

### `MulFrac` (`$A7F2`)

**HL = A * E / 128 rounded, signed bytes: the product with a sine of Sine8**

Witness: L1 205999 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,614 calls, 653,683 t-states own (0.10 %) |
| Runs (the other recordings) | 62,281 calls (`stage1/death` 29,302, `stage1/play2` 14,652, `stage1/missions` 8,104 and 6 more) |
| Called from | `OpPolarPoints`, `BoxSquare`, `BoxRect`, `BoxTilted`, `RotatePair`, `ShowMortarRange`, `MoveObject` |
| Reads | `$5F00`-`$60FF` (`SquareLow`, `SquareHigh`) |

### `MulWordByte` (`$A82C`)

**HL = HL * A / 128 for a signed word HL and a signed byte A (two quarter-square products)**

The mission vector `$67D9`: 220 482 calls in play, 37 permille, most of them from the mission code turning positions.

Witness: L1 643316 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 9,736 calls, 4,312,095 t-states own (0.65 %) |
| Runs (the other recordings) | 210,746 calls (`stage1/death` 120,834, `stage1/play2` 37,372, `stage1/play` 27,268 and 2 more) |
| Called from | `ApiVector09` (tail) |
| Reads | `$5F00`-`$60FF` (`SquareLow`, `SquareHigh`) |

### `SinCos8` (`$A899`)

**A = Sine8[A], A' = Sine8[A + 64] (the mission vector `$67E8`)**

Witness: L1 153909 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,442 calls, 152,836 t-states own (0.02 %) |
| Runs (the other recordings) | 56,373 calls (`stage1/death` 29,045, `stage1/missions` 9,030, `stage1/play2` 8,907 and 6 more) |
| Called from | `ApiVector14` (tail) |
| Reads | `$6300`-`$63FF` (`Sine8`) |

### `SinCos16` (`$A8A5`)

**DE = Sine16[A], BC = Sine16[A + 64]**

Witness: L1 12234 (armour, c1, death, fuel, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 310 calls, 22,989 t-states own (0.00 %) |
| Runs (the other recordings) | 4,660 calls (`stage1/death` 2,236, `stage1/play2` 1,496, `stage1/play` 528 and 1 more) |
| Called from | `BoxRect16` |
| Reads | `$6100`-`$62FE` (`Sine16Low`, `Sine16High`) |

### `SinCosHalf` (`$A8B2`)

**E = A = sine, A = cosine of the angle word HL (H the angle, bit 7 of L the half step: Sine8Half `$6400`)**

Witness: L1 75445 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 870 calls, 73,773 t-states own (0.01 %) |
| Runs (the other recordings) | 22,071 calls (`stage1/death` 14,279, `stage1/play2` 3,322, `stage1/play` 2,329 and 2 more) |
| Called from | `BoxTilted`, `CameraSinCos`, `MoveObject` |
| Reads | `$6300`-`$63FF` (`Sine8`) |

### `PlotBackBuffer` (`$AA27`)

**Set the pixel (x = L, y = H) in the back buffer (the bit masks at `$7C49`)**

Caller `$BB75` (points of the scenery). 37 012 calls.

Witness: L1 95537 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,516 calls, 237,466 t-states own (0.04 %) |
| Runs (the other recordings) | 35,496 calls (`stage1/death` 23,934, `stage1/play2` 5,450, `stage1/play` 3,192 and 2 more) |
| Called from | `PlotGroundDot` (tail) |
| Calls | `HighTimes32` |
| Reads | `$7C49`-`$7C50` (`FailReason+80`); `$9111`-`$9130` (`BackBuffer+1568`); `$9152`-`$96CE` (`BackBuffer+1633`) |
| Writes | `$9111`-`$9130` (`BackBuffer+1568`); `$9152`-`$96CE` (`BackBuffer+1633`) |

## input

`src/game/input.asm`

### `ReadControls` (`$971A`)

**Read the chosen device: the reader of `$67B6` in the table `$9723`**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 136,092 t-states own (0.02 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `PointerTick` |
| Calls | `CallTableEntry` (tail) |
| Reads | `$67B6` (`ControlDevice`) |

### `ReadSinclair` (`$972D`)

**Sinclair (Interface 2): port `$EFFE`**

Witness: menu, 11 runs in frames 115-140 after OPTIONS 1 (Sinclair selected; entered by `JP (HL)`, docs/05-controls.md 5.2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/menu`) |
| Called from | `CallTableEntry` |
| Calls | `InvertDirections` (tail) |
| Ports in | `$EFFE` |

### `ReadCursor` (`$9734`)

**Cursor keys: ports `$F7FE`, `$EFFE`, `$7FFE`**

Witness: known only from the code (entered by `JP (HL)`).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/menu`) |
| Called from | `CallTableEntry` |
| Calls | `InvertDirections` (falls into) |
| Ports in | `$7FFE`, `$EFFE`, `$F7FE` |

### `InvertDirections` (`$9757`)

**CPL then DecodeDirections**

Witness: L1 1225 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,225 calls (`stage1/menu` 1,225) |
| Called from | `ReadSinclair` (tail), `ReadCursor` (falls into) |
| Calls | `DecodeDirections` (falls into) |

### `DecodeDirections` (`$9758`)

**Bits right, left, down, up, fire: the X and Y steps with acceleration (`$985E`, `$985F`), carry = fire**

Witness: L1 121627 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7,559 calls (`stage1/menu` 7,559) |
| Called from | `InvertDirections` (falls into), `ReadKeys` (tail) |
| Reads | `$67B7`-`$67BA` (`RepeatY`, `LastDirections`, `RepeatX`); `$9719` (`StepFrames`); `$985E`-`$985F` (`StepX`, `StepY`) |
| Writes | `$67B7`-`$67BA` (`RepeatY`, `LastDirections`, `RepeatX`); `$985E`-`$985F` (`StepX`, `StepY`) |

### `ReadMouse` (`$9813`)

**Kempston mouse: X from `$FBDF`, Y from `$FFDF`, the deltas**

Reads X (`AND $7F`, doubled) and Y (inverted), stores them at `$67BB`, then the deltas over `$67BC-$67BD`: the delta word overwrites the new Y. It returns straight to the caller with A = the X delta and the carry of that subtraction: it never reaches `DecodeDirections`, so `$985E` / `$985F` keep their last values and `PointerFire` takes the carry for the fire button. Recording controls: 30 runs (frames 295-330) before the machine resets (see NOTES.md, open point 4). Witness: L1 0 (controls; entered by `JP (HL)`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadKempston` (`$9833`)

**Kempston joystick: port `$1F`, the bits reordered for DecodeDirections**

Witness: known only from the code (entered by `JP (HL)`; controls runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadKeys` (`$9844`)

**The keyboard: five keys from the table `$9862` (port, mask)**

Witness: known only from the code (entered by `JP (HL)`; every recording runs it).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 2,338,971 t-states own (0.35 %) |
| Runs (the other recordings) | run into, not called (`stage1/death`, `stage1/play2`, `stage1/missions` and 6 more) |
| Called from | `CallTableEntry` |
| Calls | `DecodeDirections` (tail) |
| Reads | `$67B7`-`$67BA` (`RepeatY`, `LastDirections`, `RepeatX`); `$9719` (`StepFrames`); `$985E`-`$986B` (`StepX`, `KeyTable`) |
| Writes | `$67B7`-`$67BA` (`RepeatY`, `LastDirections`, `RepeatX`); `$985E`-`$985F` (`StepX`, `StepY`) |
| Ports in | `$7FFE`, `$DFFE`, `$FBFE`, `$FDFE` |

### `CallTableEntry` (`$9874`)

**Jump to the word A of the table at HL**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 185,580 t-states own (0.03 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `ReadControls` (tail) |
| Calls | `ReadSinclair`, `ReadCursor`, `ReadKeys`, `TableEntry` |
| Reads | `$9723`-`$972C` (`DeviceReaders`) |

### `TableEntry` (`$987C`)

**HL = HL + 2A**

Witness: L1 121657 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 94,852 t-states own (0.01 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `CallTableEntry` |

## render

`src/game/render.asm`

### `StartViewPass` (`$9882`)

**Start a 3D pass: wait until the last blit is done (`$83BA` = 0), clear the back buffer**

Spins on `$83BA` (set to `$FF` by RequestViewBlit `$988D`, cleared by the interrupt after the blit, ClearBlitRequest `$8AEC`), then calls ClearBackBuffer `$96F1`. Callers: the play loops `$694B`, `$6A0C`, `$6AB9` and the bank 6 menu views `$C409`, `$C4AD`, `$CA8B`, `$DA09`, `$DB1C`. Its own time (18 permille) is the wait for the interrupt.

Witness: L1 13569 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 290 calls, 5,227,327 t-states own (0.79 %) |
| Runs (the other recordings) | 6,338 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,212 and 6 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop` |
| Calls | `ClearBackBuffer` |
| Reads | `$83BA` (`BlitRequest+1`) |

### `RequestViewBlit` (`$988D`)

**Ask the interrupt to blit the finished back buffer: `$83BA` = `$FF`**

Witness: L1 13587 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 291 calls, 8,730 t-states own (0.00 %) |
| Runs (the other recordings) | 6,350 calls (`stage1/death` 2,637, `stage1/play2` 1,461, `stage1/missions` 1,213 and 6 more) |
| Called from | `PlayLoopTail`, `DragonflyViewLoop` |
| Writes | `$83BA` (`BlitRequest+1`) |

### `ClearBackBufferOld` (`$9893`)

**Unused: clear 1792 bytes below `$98EF` and fill 1792 bytes below with `$AA`/`$55` rows, both by PUSH**

Sets `SP` = `$98F1` and calls two PUSH loops that take their return address off the stack first. As placed it would overwrite OpcodeTable `$98E1` and the code below it; no caller, a leftover of an earlier layout.

Witness: known only from the code (no recording runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_98A6` (`$98A6`)

**sub_98A6**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_98C2` (`$98C2`)

**sub_98C2**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RunScript` (`$990F`)

**Run the model script at IX until the byte `$FF`**

Reads the opcode at IX, IX+1, patches the `CALL` at `$9927` with OpcodeTable[opcode] and calls it; every handler returns to `$992A` (`JP $990F`), with IX past its operands. Input: IX = the script; bank of the script paged (bank 3 via `$72BE`, bank 0 for the mission models). Callers: DrawObject `$B827` (the objects), `$B190` (the ground and the sky, scripts at bank 0 `$FF80`, `$FF8C`, `$FF98`), `$72BE` (bank 6 views with bank 3 models), the mission code `$E3F3`, `$E561`, and ScriptTranslate `$A049`, which jumps back here.

Witness: L1 319386 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 7,859 calls, 995,308 t-states own (0.15 %) |
| Runs (the other recordings) | 122,646 calls (`stage1/death` 47,346, `stage1/play2` 28,155, `stage1/missions` 21,478 and 6 more) |
| Called from | `Bank3Render`, `ScriptNext` (tail), `OpTranslate` (tail), `DrawSegmentStyle`, `DrawModel`, `DrawEntry` |
| Reads | `$7E8F`-`$7FAF` (`MissionParams+13`); `$8739`-`$87D5` (`ModelMine`, `ModelMissile`); `$98E1`-`$990E` (`OpcodeTable`); `$D5D0`-`$D673` (`HelicarrierData`); `$D934`-`$D9A4` (`BinocularIcons+96`); `$E94D`-`$E98B` (`MissionHeader+3464`); 2 more ranges |
| Writes | `$9928`-`$9929` (`sub_9927+1`) |

### `sub_9927` (`$9927`)

**sub_9927**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `OpNative`, `OpVertexProgram`, `OpProject`, `OpLines`, `OpTestFaces`, `OpCall`, `OpReturn`, `OpOrderByFace`, `OpFillFaces`, `OpFillFacesClipped`, `OpFillPolys`, `OpFillBackFaces`, `OpLinesClipped`, `OpTranslate`, `OpFillPolysClipped`, `OpFillBackFacesClipped`, `OpPolarPoints`, `ScriptDrawCarried` |

### `ScriptNext` (`$992A`)

**The handlers' return: go on with the next opcode**

Witness: L1 266356 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,677 calls, 68,948 t-states own (0.01 %) |
| Runs (the other recordings) | 96,956 calls (`stage1/death` 32,614, `stage1/play2` 23,835, `stage1/missions` 18,315 and 6 more) |
| Called from | `OpVertexProgram` (tail), `OpProject` (tail), `OpLines` (tail), `StoreFaceFlag` (tail), `OpCall`, `OpReturn` (tail), `OpOrderByFace` (tail), `FillFaceList` (tail), `FillFaceListClipped` (tail), `OpFillPolys` (tail), `OpLinesClipped` (tail), `OpFillPolysClipped` (tail), `OpPolarPoints` (tail), `l_AA5B` (tail), `BoxHeights` (tail), `BoxTilted` (tail), `ScriptDrawCarried` (tail) |
| Calls | `RunScript` (tail) |

### `OpNative` (`$992D`)

**Opcode 0: jump to the native routine at the word operand**

IX on past the word, then `JP (HL)`: the routine reads its own operands through IX and returns to ScriptNext. The models call the box generators by the mission vectors `$67F4` (BoxSquare), `$67F7` (BoxRect), `$67FA` (BoxRect16), `$67FD` (BoxSquareTurret) and `$ABFF` (BoxTilted) with 3 operand bytes; other targets take none (`$F6B9` in mission 1 clears the tilt `$68E6`; `$D4A4`, `$D5C9`, `$E2C0`, `$EC2E`, `$EE06`, `$EE22`, `$FE8F` in bank 0).

Witness: L1 38166 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 944 calls, 59,070 t-states own (0.01 %) |
| Runs (the other recordings) | 14,270 calls (`stage1/death` 7,075, `stage1/play2` 3,366, `stage1/missions` 1,751 and 6 more) |
| Called from | `sub_9927` |
| Calls | `ApiVector18`, `ApiVector19`, `ApiVector20`, `ApiVector21`, `BoxRect`, `BoxTilted`, `CopyHudGlyphs`, `CopyHelicarrierState`, `MissionHeader`, `l_FE8F` |
| Reads | `$7E90`-`$7F5D` (`MissionParams+14`); `$873A`-`$8777` (`ModelMine+1`, `ModelMissile`); `$D5D1`-`$D5D5` (`HelicarrierData+1`); `$D935`-`$D93C` (`BinocularIcons+97`); `$E94E`-`$E94F` (`MissionHeader+3465`); `$EB26`-`$FA08` (`MissionHeader+3937`); 1 more ranges |

### `OpVertexProgram` (`$9938`)

**Opcode 1: build vertices from others with a byte program: load, store, midpoint, add, subtract, negate**

Under `DI` with `SP` used as a pointer into the vertex rows. The current point P = (DE, DE', BC') = (x, y, z). Bytes: `$00-$3F` n: P = V[n]; `$40-$7F`: V[n AND `$3F`] = P; `$80-$BF`: P = (P + V[n AND `$3F`]) / 2; `$C0` m: P = P + V[m]; `$E0` m: P = P - V[m]; `$F0`: P = -P; `$F8`: P.x = -P.x, P.z = -P.z (the half-turn about the vertical); any other byte (`$FF`) ends it, `SP` back, `EI`. With the box corners `V34-V41` from a box generator, midpoints and sums give every other vertex of the model in its turned axes.

Witness: L1 24235 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 855 calls, 7,298,543 t-states own (1.10 %) |
| Runs (the other recordings) | 9,854 calls (`stage1/play2` 2,724, `stage1/death` 2,520, `stage1/missions` 2,094 and 6 more) |
| Called from | `sub_9927` |
| Calls | `ScriptNext` (tail) |
| Reads | `$7ED1`-`$7F74` (`MissionParams+79`); `$8740`-`$8783` (`ModelMine+7`, `ModelMissile`); `$D5DA`-`$D612` (`HelicarrierData+10`); `$D93E`-`$D97E` (`BinocularIcons+106`); `$E954`-`$E95A` (`MissionHeader+3471`); `$EB2C`-`$EE67` (`MissionHeader+3943`); 4 more ranges |
| Writes | `$99BE`-`$99C3` (`l_99AD+17`, `l_99C1`) |

### `OpProject` (`$9A43`)

**Opcode 2 (n, 2k): project n vertices from V[k] to screen points in ProjectedPoints `$FC00`**

For each vertex: depth = z + the operand at `$9A6C` (the object's z, `$0190` by default); if depth < 96 the point is marked behind the eye (`$FC00`+4i = `$8000`). Otherwise sx = 128 + 256 (x + `$9A8E`) / depth (shifted right by the count at `$9A93` first, the zoom), sy = 64 - 256 (y + `$9AB3`) / depth, through Divide `$A687` and DivideByLog `$A6D2` (one logarithm of the depth for both). Output: `$FC00`+4i = sx word, `$FC02`+4i = sy word.

Witness: L1 56575 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,168 calls, 6,885,988 t-states own (1.04 %) |
| Runs (the other recordings) | 21,720 calls (`stage1/death` 10,925, `stage1/play2` 3,909, `stage1/missions` 3,297 and 6 more) |
| Called from | `sub_9927` |
| Calls | `ScriptNext` (tail), `Divide`, `DivideByLog`, `NegHL` |
| Reads | `$7E96`-`$7F86` (`MissionParams+20`); `$8745`-`$8786` (`ModelMine+12`, `ModelMissile`); `$D614`-`$D615` (`HelicarrierData+68`); `$D980`-`$D981` (`BinocularIcons+172`); `$E95C`-`$E95D` (`MissionHeader+3479`); `$EB58`-`$FA18` (`MissionHeader+3987`); 3 more ranges |
| Writes | `$9AD6`-`$9AD7` (`l_9AD5+1`); `$FC00`-`$FCAF` (`MissionHeader+8251`) |

### `OpLines` (`$9AD8`)

**Opcode 3: a polyline: `$80`+v moves to point v, v draws a line to it, `$C0` ends**

A line is drawn only when both ends are in front of the eye; ClipLine2D `$A184` clips it to the window and `$72B1` draws it with bank 3 `$C9A7`.

Witness: L1 5137 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 64,657 t-states own (0.01 %) |
| Runs (the other recordings) | 1,428 calls (`stage1/play2` 563, `stage1/death` 359, `stage1/missions` 242 and 3 more) |
| Called from | `sub_9927` |
| Calls | `Bank3Lookup`, `ScriptNext` (tail), `ClipLine2D` |
| Reads | `$7FA6`-`$7FAE` (`MissionParams+292`); `$D983`-`$D9A3` (`BinocularIcons+175`); `$EBA7`-`$EBA9` (`MissionHeader+4066`); `$EC1F`-`$EC2B` (`MissionHeader+4186`); `$ED12`-`$ED14` (`MissionHeader+4429`); `$EE73`-`$EE75` (`MissionHeader+4782`); 4 more ranges |
| Writes | `$9B36`-`$9B37` (`l_9B35+1`) |

### `OpLinesByFaces` (`$9B38`)

**Opcode 4: edges drawn when either of two faces is visible: (face a, face b, v) or `$80`+v, `$C0` ends**

The wire edge between faces a and b (flags `$6728`+a, +b) is drawn to point v when one of them faces the eye, else the pen moves to v. In no model of the recordings (one use in mission 1 at `$F99E`, its model not drawn in them).

Witness: known only from the code (no recording runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OpTestFaces` (`$9BAF`)

**Opcode 5 (slot, n, n x (a, b, c)): set the visibility flags of n faces from their screen winding**

Slot base to `$9C6B` (+`$28`), then TestFace `$9BC3` for each triple of point offsets (4 x vertex).

Witness: L1 24102 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 816 calls, 89,342 t-states own (0.01 %) |
| Runs (the other recordings) | 8,478 calls (`stage1/play2` 2,590, `stage1/death` 2,050, `stage1/missions` 1,832 and 6 more) |
| Called from | `sub_9927` |
| Calls | `TestFace` (falls into) |
| Reads | `$7E99`-`$7F77` (`MissionParams+23`); `$8748`-`$8789` (`ModelMine+15`, `ModelMissile`); `$9BDA` (`TestFace+23`); `$D617`-`$D618` (`HelicarrierData+71`); `$E95F`-`$E960` (`MissionHeader+3482`); `$EBC1`-`$EEE3` (`MissionHeader+4092`); 4 more ranges |
| Writes | `$6728`-`$6749` (`FaceFlags`); `$9BDA` (`TestFace+23`); `$9C6B`-`$9C7B` (`StoreFaceFlag+1`, `l_9C79`) |

### `TestFace` (`$9BC3`)

**One face: the sign of the cross product (b - a) x (c - a) of three screen points into FaceFlags**

Counts the points behind the eye in `$9BDA`: 3 gives flag 0 (`$9CAA`), 1-2 give `$FF` (`$9CA3`, drawn and clipped later); else the two edge vectors are scaled to bytes (ScaleToBytes `$9C84`) and multiplied with MulSigned `$A7BF`: flag = `$FF` when ex1 * ey2 < ey1 * ex2.

Witness: L1 133984 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5,328 calls, 4,569,194 t-states own (0.69 %) |
| Runs (the other recordings) | 39,962 calls (`stage1/missions` 14,203, `stage1/play2` 12,266, `stage1/death` 8,757 and 1 more) |
| Called from | `OpTestFaces` (falls into), `StoreFaceFlag` (tail) |
| Calls | `StoreFaceFlag` (falls into), `ScaleToBytes`, `FacePartlyBehind` (tail), `FaceAllBehind` (tail), `MulSigned` |
| Reads | `$7E9B`-`$7F83` (`MissionParams+25`); `$874A`-`$878F` (`ModelMine+17`, `ModelMissile`); `$9BDA` (`TestFace+23`); `$D619`-`$D630` (`HelicarrierData+73`); `$E961`-`$E96C` (`MissionHeader+3484`); `$EBC3`-`$EEEF` (`MissionHeader+4094`); 4 more ranges |
| Writes | `$9BDA` (`TestFace+23`) |

### `StoreFaceFlag` (`$9C6A`)

**Store the face flag B at `$6728` + slot, next slot, loop over the triples**

Witness: L1 133984 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5,328 calls, 330,495 t-states own (0.05 %) |
| Runs (the other recordings) | 39,962 calls (`stage1/missions` 14,203, `stage1/play2` 12,266, `stage1/death` 8,757 and 1 more) |
| Called from | `TestFace` (falls into), `FacePartlyBehind` (tail), `FaceAllBehind` (tail) |
| Calls | `ScriptNext` (tail), `TestFace` (tail) |
| Writes | `$6728`-`$674F` (`FaceFlags`); `$9C6B` (`StoreFaceFlag+1`) |

### `ScaleToBytes` (`$9C84`)

**Halve the two words HL, DE together until both fit in a signed byte (C = the sign bias)**

The loop `$9C7C` shifts both right. Unreferenced code at `$9C9A` (another flag store) follows.

Witness: L1 247063 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 10,436 calls, 539,832 t-states own (0.08 %) |
| Runs (the other recordings) | 95,556 calls (`stage1/missions` 28,398, `stage1/play2` 23,764, `stage1/death` 16,546 and 6 more) |
| Called from | `TestFace` |

### `FacePartlyBehind` (`$9CA3`)

**A face with one or two points behind the eye: flag `$FF`**

Witness: L1 1130 (c1, death, m1complete, m4complete).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 185 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/death` 6) |
| Called from | `TestFace` (tail) |
| Calls | `StoreFaceFlag` (tail) |

### `FaceAllBehind` (`$9CAA`)

**A face with all three points behind the eye: flag 0**

Witness: L1 12422 (armour, c1, death, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 105 calls, 3,885 t-states own (0.00 %) |
| Runs (the other recordings) | 1,018 calls (`stage1/death` 478, `stage1/play2` 384, `stage1/play` 152 and 1 more) |
| Called from | `TestFace` (tail) |
| Calls | `StoreFaceFlag` (tail) |

### `OpJumpIfVisible` (`$9CB1`)

**Opcode 6 (face, address): go on at the address when the face is visible, else skip 3 bytes**

Unreferenced code at `$9CD7` (the same with a return address pushed) follows.

Witness: known only from the code (no recording runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OpJumpIfVisible2` (`$9CE8`)

**Opcode 7 (face, address): the same as opcode 6**

Witness: known only from the code (no recording runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OpCall` (`$9D0D`)

**Opcode 11 (address): run the script at the address as a subroutine (IX pushed, opcode 9 returns)**

Witness: L1 1496 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 100 calls, 11,536 t-states own (0.00 %) |
| Runs (the other recordings) | 746 calls (`stage1/menu` 262, `stage1/missions` 236, `stage1/play2` 98 and 6 more) |
| Called from | `sub_9927` |
| Calls | `ScriptNext` |

### `OpReturn` (`$9D1E`)

**Opcode 9: return from a script subroutine: IX popped from the stack**

Used to end the parts of OpCall `$9D0D` and OpOrderByFace `$9D5A`.

Witness: L1 27230 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 994 calls, 53,695 t-states own (0.01 %) |
| Runs (the other recordings) | 11,733 calls (`stage1/missions` 3,361, `stage1/play2` 3,037, `stage1/menu` 1,833 and 6 more) |
| Called from | `sub_9927` |
| Calls | `ScriptNext` (tail) |
| Writes | `$9D26`-`$9D27` (`l_9D25+1`) |

### `OpBranchOnFace` (`$9D28`)

**Opcode 8 (face, visible, hidden): go on at one of two addresses, the return pushed (IX + 5)**

Witness: known only from the code (no recording runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OpOrderByFace` (`$9D5A`)

**Opcode 10 (face, part A, part B): draw the inline part and the two parts in an order set by the face**

Face visible: the inline part (IX + 5), then A, then B; hidden: A, then the inline part, then B. Each part ends with opcode 9; the two other entries are pushed as returns. This is how a model sorts its own parts (the turret before or behind the hull) without a depth sort.

Witness: L1 12854 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 447 calls, 124,404 t-states own (0.02 %) |
| Runs (the other recordings) | 5,482 calls (`stage1/missions` 1,561, `stage1/play2` 1,470, `stage1/play` 838 and 6 more) |
| Called from | `sub_9927` |
| Calls | `ScriptNext` (tail) |
| Reads | `$6728`-`$6748` (`FaceFlags`); `$8791`-`$87AE` (`ModelMissile+28`); `$EBEC`-`$EC90` (`MissionHeader+4135`); `$F3C8`-`$F3CC` (`MissionHeader+6147`); `$F5B8`-`$F5BC` (`MissionHeader+6643`) |
| Writes | `$9D85`-`$9D86` (`l_9D84+1`) |

### `OpFillFaces` (`$9D8F`)

**Opcode 12 (n, n x face): fill the visible faces; face = (slot, length, k, colour, k point offsets)**

Patches `$9DB2` to `JP Z` (skip hidden faces) and `$9DAD` to fall through, then shares FillFaceList `$9D99`. A face with a point behind the eye is skipped (`$9E0B`).

Witness: L1 27293 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 806 calls, 2,334,904 t-states own (0.35 %) |
| Runs (the other recordings) | 10,296 calls (`stage1/play2` 3,011, `stage1/missions` 2,713, `stage1/death` 1,657 and 6 more) |
| Called from | `sub_9927` |
| Calls | `FillFaceList` (falls into) |
| Reads | `$6728`-`$6749` (`FaceFlags`); `$68AA` (`PanelGauges+2`); `$7EA8`-`$7FA4` (`MissionParams+38`); `$8757`-`$87CA` (`ModelMine+30`, `ModelMissile`); `$EC79`-`$ECAC` (`MissionHeader+4276`); `$F15C`-`$F17C` (`MissionHeader+5527`); 5 more ranges |
| Writes | `$6700`-`$6717` (`PolyVerts`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$9DAD`-`$9DB2` (`l_9DA6+7`); `$9E03`-`$9E04` (`l_9E02+1`) |

### `FillFaceList` (`$9D99`)

**Copy each chosen face's screen points to PolyVerts `$6700` and fill it with bank 3 `$C4C4` (via `$7290`)**

The colour to `$7579`, the count to `$68A9`, the face count in `$68AA`. A face whose flag fails the test is skipped by its length byte.

Witness: L1 28219 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5,753 calls (`stage1/play2` 3,023, `stage1/missions` 2,730) |
| Called from | `OpFillFaces` (falls into), `OpFillBackFaces` (tail) |
| Calls | `Bank3SetObject`, `ScriptNext` (tail) |
| Reads | `$6728`-`$674E` (`FaceFlags`); `$6760`-`$6767` (`FaceFlags+56`); `$68AA` (`PanelGauges+2`); `$7EA8`-`$7FA4` (`MissionParams+38`); `$8757`-`$87CA` (`ModelMine+30`, `ModelMissile`); `$D632`-`$D672` (`HelicarrierData+98`); 5 more ranges |
| Writes | `$6700`-`$6717` (`PolyVerts`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$9E03`-`$9E04` (`l_9E02+1`) |

### `OpFillFacesClipped` (`$9E1E`)

**Opcode 13: fill the visible faces, clipping those that cross the near plane**

Witness: L1 6425 (armour, c1, controls, death, fuel, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 257 calls, 1,799 t-states own (0.00 %) |
| Runs (the other recordings) | 2,198 calls (`stage1/play2` 863, `stage1/death` 828, `stage1/play` 297 and 1 more) |
| Called from | `sub_9927` |
| Calls | `FillFaceListClipped` (falls into) |

### `FillFaceListClipped` (`$9E20`)

**As FillFaceList, but a point behind the eye calls ClipPolyNear `$A509` to cut the face at the near plane**

A = the opcode patched at `$9E40` (`JP Z` for opcode 13, `JP NZ` for 20). The first point offset is kept in `$66CC` for the closing edge.

Witness: L1 14717 (armour, c1, controls, death, fuel, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 296 calls, 1,231,798 t-states own (0.19 %) |
| Runs (the other recordings) | 5,482 calls (`stage1/play2` 2,334, `stage1/death` 1,645, `stage1/play` 1,248 and 1 more) |
| Called from | `OpFillFacesClipped` (falls into), `OpFillBackFacesClipped` (tail) |
| Calls | `Bank3SetObject`, `ScriptNext` (tail), `ClipPolyNear` |
| Reads | `$66D5` (`PolyOutCount`); `$6728`-`$672F` (`FaceFlags`); `$6748`-`$674F` (`FaceFlags+32`); `$68AA` (`PanelGauges+2`); `$87A0`-`$87D3` (`ModelMissile+43`); `$E96E`-`$E98A` (`MissionHeader+3497`); 10 more ranges |
| Writes | `$66CC`-`$66D5` (`PolyClipVars`, `PolyWorkSpare`, `PolyOutCount`); `$6700`-`$671F` (`PolyVerts`); `$6798` (`GameVars`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$9E3B`-`$9E40` (`l_9E34+7`, `l_9E3C`); 1 more ranges |

### `OpFillPolys` (`$9ECD`)

**Opcode 14 (n, n x (k, colour, k point offsets)): fill polygons with no face test**

Witness: L1 11527 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 95,470 t-states own (0.01 %) |
| Runs (the other recordings) | 5,457 calls (`stage1/death` 4,137, `stage1/play2` 493, `stage1/missions` 408 and 3 more) |
| Called from | `sub_9927` |
| Calls | `Bank3SetObject`, `ScriptNext` (tail) |
| Reads | `$68AA` (`PanelGauges+2`); `$EBA0`-`$EBA5` (`MissionHeader+4059`); `$EE6C`-`$EE71` (`MissionHeader+4775`); `$F0F8`-`$F0FD` (`MissionHeader+5427`); `$F9C4`-`$F9C9` (`MissionHeader+7679`); `$FC00`-`$FC0F` (`MissionHeader+8251`); 2 more ranges |
| Writes | `$6700`-`$670F` (`PolyVerts`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$9F26`-`$9F27` (`l_9F25+1`) |

### `OpFillBackFaces` (`$9F37`)

**Opcode 15: fill the faces whose flag is 0 (`JP NZ` at `$9DB2`): the insides seen through an opening**

Witness: L1 926 (armour, m1complete, m4complete, missions, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 29 calls (`stage1/missions` 17, `stage1/play2` 12) |
| Called from | `sub_9927` |
| Calls | `FillFaceList` (tail) |
| Writes | `$9DAD`-`$9DB2` (`l_9DA6+7`) |

### `OpLinesClipped` (`$9F43`)

**Opcode 16: a polyline like opcode 3, a segment with an end behind the eye cut at the near plane (`$A422`, `$A42B`)**

Witness: L1 5538 (death, m1complete, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 785 calls (`stage1/death` 545, `stage1/missions` 240) |
| Called from | `sub_9927` |
| Calls | `Bank3Lookup`, `ScriptNext` (tail), `ClipLine2D`, `NearClipLineEnd`, `NearClipLine` |
| Reads | `$6798` (`GameVars`); `$F139`-`$F141` (`MissionHeader+5492`); `$FC00`-`$FC0F` (`MissionHeader+8251`); `$FC68`-`$FC6F` (`MissionHeader+8355`); `$FC80`-`$FC97` (`MissionHeader+8379`); `$FF9C`-`$FFA0` (`data_FEBB+225`) |
| Writes | `$6798` (`GameVars`); `$9FB3`-`$9FB4` (`l_9FB2+1`) |

### `OpLinesByFacesClipped` (`$9FC3`)

**Opcode 17: opcode 4 with the near clip**

Its near-clip calls `$A039`, `$A041` are unreferenced. In no model of the recordings.

Witness: known only from the code (no recording runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OpTranslate` (`$A049`)

**Opcode 18 (2k): add vertex k to the projection's position operands `$9A8E`, `$9AB3`, `$9A6C`**

Then `JP $990F` (not RET): the handler's return address stays on the stack and is taken by the `RET Z` of the next `$FF`.

Witness: L1 32 (missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 32 calls (`stage1/missions` 32) |
| Called from | `sub_9927` |
| Calls | `RunScript` (tail) |
| Reads | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$EB98` (`MissionHeader+4051`); `$ED16` (`MissionHeader+4433`); `$FD00`-`$FD01` (`MissionHeader+8507`); 5 more ranges |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`) |

### `OpFillPolysClipped` (`$A07E`)

**Opcode 19 (n, n x (k, colour, k point offsets)): fill polygons, clipping at the near plane**

Witness: L1 15521 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 294,901 t-states own (0.04 %) |
| Runs (the other recordings) | 6,933 calls (`stage1/death` 4,423, `stage1/play` 891, `stage1/play2` 826 and 2 more) |
| Called from | `sub_9927` |
| Calls | `Bank3SetObject`, `ScriptNext` (tail) |
| Reads | `$66D5` (`PolyOutCount`); `$68AA` (`PanelGauges+2`); `$F12F`-`$F137` (`MissionHeader+5482`); `$FC00`-`$FC0F` (`MissionHeader+8251`); `$FC70`-`$FC87` (`MissionHeader+8363`); `$FF84`-`$FF96` (`data_FEBB+201`) |
| Writes | `$66CC`-`$66D5` (`PolyClipVars`, `PolyWorkSpare`, `PolyOutCount`); `$6700`-`$6717` (`PolyVerts`); `$6798` (`GameVars`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$A0F7`-`$A0F8` (`l_A0F6+1`) |

### `l_A109` (`$A109`)

**l_A109**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ClipPolyNear` |

### `OpFillBackFacesClipped` (`$A114`)

**Opcode 20: fill the faces whose flag is 0, clipping at the near plane (FillFaceListClipped with `JP NZ`)**

Witness: L1 8292 (armour, c1, death, fuel, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 39 calls, 682 t-states own (0.00 %) |
| Runs (the other recordings) | 3,284 calls (`stage1/play2` 1,471, `stage1/play` 951, `stage1/death` 817 and 1 more) |
| Called from | `sub_9927` |
| Calls | `FillFaceListClipped` (tail) |

### `OpPolarPoints` (`$A119`)

**Opcode 21 (n, next, frame table): n vertices from (angle, radius, height) triples, turned by the heading**

The frame (`$A12C`, the object record's +4, set by DrawObject `$B827`) picks a word of the table at IX+3: the address of n triples. Each gives x = r sin(heading + angle) / 128, z = r cos(...) / 128, y = height, stored from V32 downwards. Then IX = next. Mission 1 uses it once (`$EFC5`, a barrel run out in five frames).

Witness: L1 723 (armour, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 4) |
| Called from | `sub_9927` |
| Calls | `ApiVector14`, `ScriptNext` (tail), `MulFrac` |
| Reads | `$68E7` (`MissionScore+5`); `$EFC6`-`$EFCA` (`MissionHeader+5121`); `$EFDF`-`$EFE1` (`MissionHeader+5146`) |
| Writes | `$A16F`-`$A17B` (`l_A138+55`, `l_A179`); `$FD40`-`$FD41` (`MissionHeader+8571`); `$FE40`-`$FE41` (`MissionHeader+8827`); `$FF40`-`$FF41` (`data_FEBB+133`) |

### `BoxSquareTurret` (`$AA47`)

**BoxSquare with the second heading `$68E9` in place of `$68E7` (the mission vector `$67FD`): a turret**

Witness: L1 17 (missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 17 calls (`stage1/missions` 17) |
| Called from | `ApiVector21` (tail) |
| Calls | `ApiVector18` |
| Reads | `$68E7`-`$68E9` (`MissionScore+5`, `GoalFlag`) |
| Writes | `$68E7` (`MissionScore+5`); `$AA5C`-`$AA62` (`l_AA5B+1`) |

### `l_AA5B` (`$AA5B`)

**l_AA5B**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 17 calls (`stage1/missions` 17) |
| Called from | `BoxHeights` (tail) |
| Calls | `ScriptNext` (tail) |
| Writes | `$68E7` (`MissionScore+5`) |

### `BoxSquare` (`$AA63`)

**Native (turn, size, height): the 8 corners V34-V41 of a square box turned by the heading `$68E7` + turn, V33 = 0**

With S = size sin(a) / 128 and C = size cos(a) / 128: V34 = (C, -h, -S), V35 = (S, -h, C), V36 = (-C, -h, S), V37 = (-S, -h, -C), V38-V41 the same at y = +h. The mission vector `$67F4`.

Witness: L1 3795 (armour, c1, death, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 175 calls, 90,613 t-states own (0.01 %) |
| Runs (the other recordings) | 308 calls (`stage1/play2` 164, `stage1/death` 83, `stage1/missions` 60 and 1 more) |
| Called from | `ApiVector18` (tail) |
| Calls | `NegHL`, `MulFrac`, `BoxHeights` (falls into) |
| Reads | `$6300`-`$6393` (`Sine8`); `$63AE`-`$63FE` (`Sine8+174`); `$68E7` (`MissionScore+5`); `$EC9F`-`$ECA0` (`MissionHeader+4314`); `$EEDB`-`$EEDC` (`MissionHeader+4886`); `$F146`-`$F147` (`MissionHeader+5505`); 1 more ranges |
| Writes | `$AAF3`-`$AAF4` (`l_AAF2+1`); `$FD44`-`$FD53` (`MissionHeader+8575`); `$FF44`-`$FF53` (`data_FEBB+137`) |

### `BoxHeights` (`$AAC2`)

**Last operand h: y = -h for V34-V37, +h for V38-V41; V33 = (0, 0, 0); return**

Witness: L1 24903 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 830 calls, 226,456 t-states own (0.03 %) |
| Runs (the other recordings) | 8,742 calls (`stage1/play2` 2,704, `stage1/death` 2,571, `stage1/missions` 1,665 and 6 more) |
| Called from | `BoxSquare` (falls into), `BoxRect16` (tail), `BoxRect` (tail) |
| Calls | `ScriptNext` (tail), `NegHL`, `l_AA5B` (tail) |
| Reads | `$7E94`-`$7F60` (`MissionParams+18`); `$873E`-`$877A` (`ModelMine+5`, `ModelMissile`); `$D5D8` (`HelicarrierData+8`); `$D939` (`BinocularIcons+101`); `$E952` (`MissionHeader+3469`); `$EB2A`-`$EEDD` (`MissionHeader+3941`); 1 more ranges |
| Writes | `$FD42`-`$FD43` (`MissionHeader+8573`); `$FE42`-`$FE53` (`MissionHeader+8829`); `$FF42`-`$FF43` (`data_FEBB+135`) |

### `BoxRect16` (`$AAF5`)

**Native (half angle, radius, height): a rectangle box with 16-bit corners (Sine16), turned by the heading**

The corners lie at the radius r on the angles heading +/- b and their opposites, so b sets the aspect. Through MulWordByte `$67D9`. The mission vector `$67FA`.

Witness: L1 6117 (armour, c1, death, fuel, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 155 calls, 114,057 t-states own (0.02 %) |
| Runs (the other recordings) | 2,330 calls (`stage1/death` 1,118, `stage1/play2` 748, `stage1/play` 264 and 1 more) |
| Called from | `ApiVector20` (tail) |
| Calls | `ApiVector09`, `NegHL`, `SinCos16`, `BoxHeights` (tail) |
| Reads | `$68E7` (`MissionScore+5`); `$E950`-`$E951` (`MissionHeader+3467`); `$EBA9`-`$EBAA` (`MissionHeader+4068`); `$EBF3`-`$EBF4` (`MissionHeader+4142`); `$ECBB`-`$ECBC` (`MissionHeader+4342`); `$ECDB`-`$ECDC` (`MissionHeader+4374`); 7 more ranges |
| Writes | `$AAF3`-`$AAF4` (`l_AAF2+1`); `$FD42`-`$FD53` (`MissionHeader+8573`); `$FE42`-`$FE43` (`MissionHeader+8829`); `$FF42`-`$FF53` (`data_FEBB+135`) |

### `BoxRect` (`$AB7B`)

**Native (half angle, radius, height): the same rectangle box with 8-bit corners (Sine8, MulFrac)**

The mission vector `$67F7`; the most used box (bank 3 models, mission 1: 22 of 31 models).

Witness: L1 14991 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 450 calls, 366,609 t-states own (0.06 %) |
| Runs (the other recordings) | 5,740 calls (`stage1/play2` 1,744, `stage1/death` 1,363, `stage1/missions` 1,288 and 6 more) |
| Called from | `ApiVector19` (tail), `OpNative` |
| Calls | `ApiVector14`, `NegHL`, `MulFrac`, `BoxHeights` (tail) |
| Reads | `$68E7` (`MissionScore+5`); `$7E92`-`$7F5F` (`MissionParams+16`); `$873C`-`$8779` (`ModelMine+3`, `ModelMissile`); `$D5D6`-`$D5D7` (`HelicarrierData+6`); `$D937`-`$D938` (`BinocularIcons+99`); `$EB28`-`$EB9D` (`MissionHeader+3939`); 4 more ranges |
| Writes | `$AAF3`-`$AAF4` (`l_AAF2+1`); `$FD42`-`$FD53` (`MissionHeader+8573`); `$FE42`-`$FE43` (`MissionHeader+8829`); `$FF42`-`$FF53` (`data_FEBB+135`) |

### `BoxTilted` (`$ABFF`)

**Native (half angle, radius, height): a rectangle box turned by the heading, the pitch `$ABFE` and the roll `$68E6`**

Rotates each corner pair with RotatePair `$AD06` (sine and cosine of the roll in `$AD04`); sets V0 = 0. Called from OpNative in death and play2 (a tilted vehicle).

Witness: L1 1818 (armour, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/death`, `stage1/play2`) |
| Called from | `OpNative` |
| Calls | `ApiVector14`, `ScriptNext` (tail), `NegHL`, `MulFrac`, `SinCosHalf`, `RotatePair` |
| Reads | `$68E6`-`$68E7` (`MissionScore+4`); `$ABFE` (`BoxTiltPitch+1`); `$FD4C`-`$FD51` (`MissionHeader+8583`); `$FEC7`-`$FEC9` (`data_FEBB+12`); `$FF4C`-`$FF51` (`data_FEBB+145`) |
| Writes | `$AD02`-`$AD05` (`BoxTilted+259`, `RollSinCos`) |

### `RotatePair` (`$AD06`)

**Turn the pair (B, C) by the angle in `$AD04`: HL, DE = the two rotated words**

Witness: L1 5454 (armour, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,563 calls (`stage1/death` 1,101, `stage1/play2` 462) |
| Called from | `BoxTilted` |
| Calls | `MulFrac` |
| Reads | `$AD04`-`$AD05` (`RollSinCos`) |
| Writes | `$AD2F`-`$AD41` (`RotatePair+41`) |

## player

`src/game/player.asm`

### `PlayerStep` (`$A8C7`)

**The player's step handler: terrain, brake, fuel, boundary, move, the turret**

Record 0's step handler (+`$18` = `$A8C7`, run by RunObjectHandlers `$C026` with IX = `$75F0`). Calls TerrainCollision through `$67F1`; on a hit the terrain type `$CE69` decides: 2 or `$80` (a wall) negates the speed and sets the handler to BounceDecay `$CC09`; 0 or 6 (0 is the road, segment style 0) stores 1.25 x the speed (signed) in `$7E8E`; IX+7 is restored at once, so the tank's speed does not change and only bank 6 DrawSpeedBar `$D612` reads `$7E8E` (the speed bar) (`$A8F0`-`$A934`, docs/10-gameplay-logic.md 10.2). The S key branch `$A8F2` -> `$A9C0` makes BrakeKey `$A9C9` the step handler and ends the pass. When the speed is not 0: the fuel, `$7C57` -= (|speed| >> 4) OR 1 (on an underflow `$A94E` sets the failure reason `$7BF9` = `$CCED` ("RAN OUT OF FUEL") and calls `$7047`), then BoundaryCheck `$D4B8` (`$A95B`), then MoveObject. The Infinite Fuel POKE writes 42 at `$A958` (`LD ($7C57),HL` becomes `LD HL,($7C57)`). Then the turret and speed against the control state `$985F`.

Witness: L1 9769 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

[Animation: `PlayerStep` at work](img/routines/PlayerStep.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 102 calls, 41,430 t-states own (0.01 %) |
| Runs (the other recordings) | 3,503 calls (`stage1/death` 2,510, `stage1/play2` 390, `stage1/missions` 307 and 2 more) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00`, `ApiVector08`, `ApiVector17`, `PlayerSteering` (falls into), `BoundaryCheck` |
| Reads | `$6A99`-`$6A9A` (`NextView+8`); `$6D43` (`PointerZones+1`); `$75F7` (`PlayerSpeed`); `$7612` (`PlayerHeading`); `$7C57`-`$7C58` (`Fuel`); `$8978`-`$8979` (`KeyState`, `KeyCode`); 4 more ranges |
| Writes | `$66CE` (`PolyClipVars+2`); `$6D43` (`PointerZones+1`); `$75F7` (`PlayerSpeed`); `$7608`-`$7612` (`PlayerHandler`, `PlayerHeading`); `$7C57`-`$7C58` (`Fuel`); `$7E8E` (`MissionParams+12`); 2 more ranges |

### `PlayerSteering` (`$A986`)

**Steering and the fire key: heading += turn / 2, the fire cooldown**

Adds half the turn input `$985E` to the heading `$7612`; counts down the fire cooldown `$A9FD`; when it is zero and the fire key bit of `$6D43` is set, calls the current weapon's fire routine through the operand at `$A9B9` (set from the store-type table StoreTypes `$7B89` + 8 * type, word 2). Output: a projectile record, the cooldown restarted.

Witness: L1 9802 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 115 calls, 14,742 t-states own (0.00 %) |
| Runs (the other recordings) | 409 calls (`stage1/play2` 409) |
| Called from | `PlayerStep` (falls into), `BounceDecay` (tail) |
| Calls | `NoAction`, `FireCannon`, `FireMortar`, `FirePhoenixRr`, `FireBansheeRr`, `FirePhoenixIr`, `FireBansheeIr`, `LaunchDragonfly`, `FireClusterBomb`, `DropMine`, `SkeetFire`, `FirePhantasm`, `FireSpectre` |
| Reads | `$6A99`-`$6A9A` (`NextView+8`); `$6D43` (`PointerZones+1`); `$7612` (`PlayerHeading`); `$985E` (`StepX`); `$A9FD` (`FireCooldown`); `$BA27` (`l_BA1F+8`) |
| Writes | `$66CE` (`PolyClipVars+2`); `$6D43` (`PointerZones+1`); `$7612` (`PlayerHeading`); `$A9FD` (`FireCooldown`) |

### `BrakeKey` (`$A9C9`)

**The brake (the S key): the player's step handler while S is down: |speed| - 8 each pass, then 0 and PlayerStep again**

The S key (code `$53`) sets record 0's handler (+`$18`) to `$A9C9`. `LD A,(IX+7)` / `ABS` through `$67D6`, stores `$7E8E`; above 8 the speed loses 8 with its sign kept, then PlayerSteering; below 8 the speed is 0 and the handler is PlayerStep `$A8C7` again (docs/05-controls.md 5.9).

Known only from the code: no recording presses S in play (no L1 block of `$A9C9-$A9F6` in any recording).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SetFireCooldown` (`$A9F7`)

**Set the fire cooldown to 8 passes**

Writes 8 to the cooldown byte `$A9FD`, the delay before the next shot. Called by the fire routines after a launch.

Witness: L1 146 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 69 calls (`stage1/death` 60, `stage1/play2` 6, `stage1/play` 3) |
| Called from | `FireCannon` (tail), `LaunchProjectile`, `SkeetFire` (tail) |
| Writes | `$A9FD` (`FireCooldown`) |

### `ConsumeAmmo` (`$B550`)

**Take one round from the current slot; find a slot for the projectile**

Reads the slot's ammunition pointer (`$B551`, from SelectAmmoPointer `$D3C6`), DEC A and stores it (the Infinite Ammo POKE writes 0 at `$B554`, the DEC A becomes NOP). Returns M when empty. Then FindFreeObject `$BCD6`, the fire sound `$D898`, and prints the count at `$C527`.

Witness: L1 148 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 70 calls (`stage1/death` 60, `stage1/play2` 6, `stage1/play` 4) |
| Called from | `FireCannon`, `LaunchProjectile`, `LaunchDragonfly`, `SkeetFire` |
| Calls | `FindProjectileSlot`, `SoundFire` |
| Reads | `$836D`-`$837F` (`WeaponSlots+5`) |
| Writes | `$836D`-`$837F` (`WeaponSlots+5`); `$C527` (`WeaponVars`) |

### `FireCannon` (`$B568`)

**Fire the turret cannon (store type 4): projectile `$81`**

Ammunition, then ObjectSetType with `$81`, the position and heading of the player, +31 lifetime.

Witness: L1 139 (armour, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 61 calls (`stage1/death` 60, `stage1/play2` 1) |
| Called from | `PlayerSteering` |
| Calls | `ApiVector03`, `ApiVector04`, `SetFireCooldown` (tail), `ConsumeAmmo`, `PrintAmmo`, `SelectAmmoPointer` |
| Reads | `$67A5`-`$67AC` (`WorldVars+2`); `$C53C` (`CurrentSlot`) |
| Writes | `$764D`-`$76D5` (`PlayerY+55`); `$7701`-`$7711` (`PlayerY+235`); `$7779`-`$7789` (`PlayerY+355`); `$77B5`-`$77C5` (`PlayerY+415`); `$78A5`-`$78B5` (`PlayerY+655`); `$791D`-`$792D` (`PlayerY+775`); 3 more ranges |

### `CannonShellStep` (`$B592`)

**Step of a cannon shell: move, lifetime 100**

MoveObject `$BFD1`, counts +`$31` down from 100, removes the shell at 0 (RemoveObject `$B8B1`).

Witness: L1 11958 (armour, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5,682 calls (`stage1/death` 5,582, `stage1/play2` 100) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` (tail), `RemoveObject` (tail) |
| Reads | `$765D`-`$7711` (`PlayerY+71`); `$7789` (`PlayerY+371`); `$77C5` (`PlayerY+431`); `$78B5` (`PlayerY+671`); `$792D` (`PlayerY+791`); `$79E1` (`PlayerY+971`); 2 more ranges |
| Writes | `$765D`-`$7711` (`PlayerY+71`); `$7789` (`PlayerY+371`); `$77C5` (`PlayerY+431`); `$78B5` (`PlayerY+671`); `$792D` (`PlayerY+791`); `$79E1` (`PlayerY+971`); 2 more ranges |

### `FireMortar` (`$B59F`)

**Fire the K-40 mortar (store type 3): projectile `$80`**

SelectAmmoPointer, A = `$80`, then LaunchProjectile `$B5A7`.

Witness: L1 2 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `PlayerSteering` |
| Calls | `LaunchProjectile` (falls into), `SelectAmmoPointer` |
| Reads | `$C53C` (`CurrentSlot`) |

### `LaunchProjectile` (`$B5A7`)

**Spawn projectile type A at the player with the aim's elevation**

Input A = the template type (`$80`-`$8B`). ConsumeAmmo `$B550`, ObjectSetType `$BD41`, copies the player's heading and X / Y, the elevation from `$B5C5` / `$B5C8` (SetElevation `$CF32`). Returns M when out of rounds.

Witness: L1 7 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7 calls (`stage1/play2` 4, `stage1/play` 3) |
| Called from | `FireMortar` (falls into), `FireClusterBomb` (tail), `DropMine`, `LaunchSpectre` (tail), `LaunchPhantasm` |
| Calls | `ApiVector03`, `ApiVector04`, `ApiVector08`, `SetFireCooldown`, `ConsumeAmmo`, `PrintAmmo` |
| Reads | `$67A5`-`$67AC` (`WorldVars+2`); `$784B` (`PlayerY+565`); `$79EF` (`PlayerY+985`); `$7A2B` (`PlayerY+1045`); `$7A67` (`PlayerY+1105`); `$7AA3` (`PlayerY+1165`); 1 more ranges |
| Writes | `$784B`-`$784F` (`PlayerY+565`); `$7869`-`$7879` (`PlayerY+595`); `$79EF`-`$79F3` (`PlayerY+985`); `$7A0D`-`$7A2F` (`PlayerY+1015`); `$7A49`-`$7A6B` (`PlayerY+1075`); `$7A85`-`$7AA7` (`PlayerY+1135`); 3 more ranges |

### `MortarShellStep` (`$B5E8`)

**Step of a mortar shell: ballistic flight, removed at the ground**

MoveObject, then height += vertical speed (+`$31`, signed); a negative height removes the shell (RemoveObject `$B8B1`, no burst: only a hit damages); else the vertical speed falls by 5 a pass, kept when the subtraction overflows.

Witness: L1 68 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 68 calls (`stage1/play` 68) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00`, `RemoveObject` (tail) |
| Reads | `$79F1`-`$79F2` (`PlayerY+987`); `$7A1D` (`PlayerY+1031`); `$7AE1`-`$7AE2` (`HelicarrierRecord+5`); `$7B0D` (`HelicarrierRecord+49`) |
| Writes | `$79F1`-`$79F2` (`PlayerY+987`); `$7A1D` (`PlayerY+1031`); `$7AE1`-`$7AE2` (`HelicarrierRecord+5`); `$7B0D` (`HelicarrierRecord+49`) |

### `Explode` (`$B8AB`)

**Explode a projectile: debris and the explosion sound**

Debris `$B6D1`, the sound `$D86B`, then RemoveObject.

Witness: L1 24 (armour, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/death` 7, `stage1/play2` 1) |
| Called from | `CollisionPass`, `ClusterBlast` (tail) |
| Calls | `ApiVector11`, `SoundExplosion` |

### `MortarElevationDown` (`$B8C4`)

**Lower the mortar elevation**

Decrements the elevation `$B8BA` (play: 4 runs, the K-40 aim).

Witness: L1 4 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play` 4) |
| Called from | `PlayKeys` (tail) |
| Calls | `ShowMortarRange` (falls into) |
| Reads | `$B8BA` (`MortarElevationUp+1`) |
| Writes | `$B8BA` (`MortarElevationUp+1`) |

### `ShowMortarRange` (`$B8CC`)

**Print the mortar range for the elevation**

Prints the elevation's range in the HUD (play: 5 runs).

Witness: L1 5 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/play` 5) |
| Called from | `MortarElevationDown` (falls into), `SelectWeapon` |
| Calls | `ApiVector08`, `ApiVector14`, `PrintString` (tail), `Divide`, `MulFrac` |
| Reads | `$B8BA` (`MortarElevationUp+1`) |
| Writes | `$B5C5`-`$B5C8` (`LaunchProjectile+30`); `$B8FC`-`$B8FD` (`IrViewHeight`); `$FDF8` (`MissionHeader+8755`) |

### `AimLimit` (`$B909`)

**Clamp the aim within the weapon's limit**

`$B8FF` -= 8 unless it would go below 0 (play2: 5 runs). Lowers the camera of the IR view (Banshee IRSS).

Witness: L1 5 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/play2` 5) |
| Called from | `PlayKeys` (tail) |
| Reads | `$B8FF`-`$B900` (`IrViewHeight+3`) |

### `FindMissileTarget` (`$BF24`)

**Search the depth tree for a missile target**

Returns at once when `$66D4` is 0; else walks the nodes at `$6800` (the target search of TargetInCone `$C197`).

Witness: L1 8 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/play2` 6, `stage1/play` 2) |
| Called from | `FireBansheeRr` (tail), `MissileLock` |
| Calls | `TargetInCone`, `MissileSeek` |
| Reads | `$66D4` (`PolyWorkSpare+5`); `$6802`-`$6827` (`PlayWork+2`) |

### `SelectPhoenix` (`$C11E`)

**Select a Phoenix (store types 1 and 5): the IR view on (`$BA13`)**

The select of store types 1 and 5 in the store-type table `$7B89`. Prints the name (`$FDC0`), sets the sight overlay `$C4DC` and the IR view flag `$BA13` (play2: 2 runs).

Witness: L1 2 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play2` 2) |
| Called from | `SelectWeapon` |
| Calls | `WeaponSelectText` (falls into) |
| Writes | `$BA13` (`SetCamera+29`); `$C4DC` (`l_C4DB+1`) |

### `WeaponSelectText` (`$C126`)

**Print the selected weapon's name**

`LD HL,$FDC0` / `JP $6FB3`.

Witness: L1 8 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/play` 5, `stage1/play2` 3) |
| Called from | `SelectPhoenix` (falls into), `SelectPlain` (tail), `RefreshWeaponPanel` (tail) |
| Calls | `PrintString` (tail) |

### `SelectPlain` (`$C12C`)

**Select a store with no aim (types 2, 6, 7)**

The select of the Banshee RRSS, the Banshee IRSS and the Dragonfly in the store-type table `$7B89`. Prints the name, sets `$C4DC`, clears `$BA13` (play, play2).

Witness: L1 3 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play` 2, `stage1/play2` 1) |
| Called from | `SelectWeapon` |
| Calls | `PrintString`, `WeaponSelectText` (tail) |
| Writes | `$BA13` (`SetCamera+29`); `$C4DC` (`l_C4DB+1`) |

### `FirePhoenixRr` (`$C13E`)

**Fire the Phoenix RRSA: projectile `$83`**

Store type 1 in the store-type table `$7B89`; `$83` is the Phoenix RR resident type (step `$C4A5`, guided). SelectAmmoPointer, A = `$83`, LaunchProjectile `$B5A7` (play2: 2 runs).

Witness: L1 2 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play2` 2) |
| Called from | `PlayerSteering` |
| Calls | `SelectAmmoPointer` |
| Reads | `$C198` (`TargetInCone+1`); `$C53C` (`CurrentSlot`) |
| Writes | `$BF40`-`$BF41` (`l_BF3C+4`); `$C198` (`TargetInCone+1`); `$C41D` (`l_C408+21`) |

### `FireBansheeRr` (`$C14D`)

**Fire the Banshee RRSS: projectile `$82`**

A = `$82`, LaunchProjectile (play: 2 runs).

Witness: L1 2 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `PlayerSteering` |
| Calls | `FindMissileTarget` (tail), `SelectAmmoPointer` |
| Reads | `$C198` (`TargetInCone+1`); `$C53C` (`CurrentSlot`) |
| Writes | `$BF40`-`$BF41` (`l_BF3C+4`); `$C198` (`TargetInCone+1`); `$C41D` (`l_C408+21`) |

### `FindTypeInCone` (`$C174`)

**Find a present object of type C in the cone (no recording runs it)**

Called from `$C254` (the lock path).

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TargetInCone` (`$C197`)

**Look for a target within +-6 of the heading (gated: JR to RET or on)**

`JR d` whose d (`$C198`) is 0 (to the RET at `$C199`) or 1 (to the body `$C19A`); ResetSightTimer `$C506` writes 1. Recordings play and play2: 18 runs, the body never.

Witness: L1 18 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 18 calls (`stage1/play2` 11, `stage1/play` 7) |
| Called from | `FindMissileTarget` |
| Reads | `$6804`-`$6829` (`PlayWork+4`); `$7612` (`PlayerHeading`); `$77D2`-`$77D6` (`PlayerY+444`); `$780E`-`$7812` (`PlayerY+504`); `$784A`-`$784E` (`PlayerY+564`); `$78C2`-`$78C6` (`PlayerY+684`); 5 more ranges |
| Writes | `$C16F`-`$C170` (`l_C16E+1`) |

### `TargetInConeBody` (`$C19A`)

**The body of TargetInCone (no recording runs it)**

Reads a node of the depth tree, IY = its record, checks the bearing within +-6 of `$7612` (BearingTo through `$67C1`) and the height.

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ApiVector01`, `ApiVector08`, `TargetBearingCheck` |

### `TargetBearingCheck` (`$C1ED`)

**Check a candidate's bearing and height**

Called for each candidate: |bearing - heading| < 6, height against `$C276`.

Witness: L1 28 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 28 calls (`stage1/play2` 21, `stage1/play` 7) |
| Called from | `TargetInConeBody`, `MissileSeek` |
| Reads | `$67AD`-`$67AE` (`WorldVars+10`); `$75FD`-`$75FE` (`PlayerSpeed+6`); `$77DD`-`$77DE` (`PlayerY+455`); `$7819`-`$781A` (`PlayerY+515`); `$7855`-`$7856` (`PlayerY+575`); `$78CD`-`$78CE` (`PlayerY+695`); 5 more ranges |

### `FirePhoenixIr` (`$C20D`)

**Fire the Phoenix (IR): projectile `$85`**

A = `$85`, the height limit `$C276` = `$FF` (any height), MissileLock (play2).

Witness: L1 2 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play2` 2) |
| Called from | `PlayerSteering` |
| Calls | `MissileLock` (tail), `SelectAmmoPointer` |
| Reads | `$C53C` (`CurrentSlot`) |

### `FireBansheeIr` (`$C21D`)

**Fire the Banshee IRSS: projectile `$84`**

Store type 6 in the store-type table `$7B89`; `$84` is the Banshee IR resident type (step `$C4A5`). A = `$84` (play2).

Witness: L1 2 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play2` 2) |
| Called from | `PlayerSteering` |
| Calls | `MissileLock` (falls into), `SelectAmmoPointer` |
| Reads | `$C53C` (`CurrentSlot`) |

### `MissileLock` (`$C227`)

**Lock a missile on the target found**

Stores the limit `$C276` and the type `$C41D`, hooks MissileSeek into the tree walk (`$BF40` = `$C267`), searches (FindMissileTarget `$BF24`).

Witness: L1 4 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 4) |
| Called from | `FirePhoenixIr` (tail), `FireBansheeIr` (falls into) |
| Calls | `FindMissileTarget` |
| Reads | `$C268` (`MissileSeek+1`) |
| Writes | `$BF40`-`$BF41` (`l_BF3C+4`); `$C267`-`$C276` (`MissileSeek`); `$C41D` (`l_C408+21`) |

### `MissileSeek` (`$C267`)

**A guided missile's step: turn toward the target**

Called by the tree walk for each node: a target that passes TargetBearingCheck is taken (play2: 19 runs).

Witness: L1 19 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 19 calls (`stage1/play2` 19) |
| Called from | `FindMissileTarget` |
| Calls | `OnScreenX`, `TargetBearingCheck` |
| Reads | `$6804`-`$681D` (`PlayWork+4`); `$77D2`-`$77D6` (`PlayerY+444`); `$77FF`-`$7812` (`PlayerY+489`); `$783B`-`$784E` (`PlayerY+549`); `$7877`-`$7878` (`PlayerY+609`); `$78C2`-`$78C6` (`PlayerY+684`); 4 more ranges |
| Writes | `$C267` (`MissileSeek`) |

### `LaunchDragonfly` (`$C2BC`)

**Launch the Dragonfly: projectile `$86`, the camera follows it**

Spawns `$86`, the camera record `$B9F4` = the Dragonfly, the fire routine `$A9B9` = RecallDragonfly (play: 1 run).

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `PlayerSteering` |
| Calls | `ApiVector03`, `ApiVector04`, `ConsumeAmmo`, `SelectAmmoPointer` |
| Reads | `$67A5`-`$67AC` (`WorldVars+2`); `$75F3` (`ObjectTable+3`); `$7612` (`PlayerHeading`); `$7AA3` (`PlayerY+1165`); `$C53C` (`CurrentSlot`) |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$6A99`-`$6A9A` (`NextView+8`); `$75F3` (`ObjectTable+3`); `$7AA0`-`$7AA3` (`PlayerY+1162`); `$7AC1`-`$7AD1` (`PlayerY+1195`); `$A9B9`-`$A9BA` (`l_A9A0+25`); 2 more ranges |

### `sub_C30F` (`$C30F`)

**sub_C30F**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DragonflyRetake` (`$C31B`)

**Take the Dragonfly view back while a Dragonfly is out**

The fire word LaunchDragonfly leaves in `$A9B9`: CALL `$C30F` (NextView = DragonflyViewLoop, the view flag), the fire word = RecallDragonfly `$C33E`, the camera `$B9F4` = the Dragonfly (the operand `$C302`), its step = DragonflyStep `$C391`, the tank's +3 b0 cleared (the tank stops). DragonflyEnd puts LaunchDragonfly back when the fire word is still this one.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RecallDragonfly` (`$C33E`)

**Recall the Dragonfly**

The fire key with the Dragonfly out: `$A9B9` = LaunchDragonfly again, its handler `$67BE`, the screen routine `$694B`, the view flag `$6A6D`, CameraToPlayer (play: 1 run).

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `DragonflyStep` (tail) |
| Calls | `CameraToPlayer` (falls into) |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$6A99`-`$6A9A` (`NextView+8`); `$7AB8`-`$7AB9` (`PlayerY+1186`); `$A9B9`-`$A9BA` (`l_A9A0+25`) |

### `CameraToPlayer` (`$C357`)

**Point the camera back at the player**

`$B9F4` = `$75F0`. Also called when a mission starts (15 runs over five recordings).

Witness: L1 20 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 75 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 2 and 2 more) |
| Called from | `ResetCollisionTables`, `RecallDragonfly` (falls into) |
| Reads | `$75F3` (`ObjectTable+3`) |
| Writes | `$75F3` (`ObjectTable+3`); `$B9F4`-`$B9F5` (`BearingTable+22`) |

### `DragonflyStep` (`$C391`)

**The Dragonfly's flight: steered by the controls**

Turns by the control input, MoveObject, height from the up / down keys (play: 25 runs).

Witness: L1 25 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 25 calls (`stage1/play` 25) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` (tail), `RecallDragonfly` (tail) |
| Reads | `$6D43` (`PointerZones+1`); `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AC2`-`$7AD1` (`PlayerY+1196`); `$985E`-`$985F` (`StepX`, `StepY`) |
| Writes | `$6D43` (`PointerZones+1`); `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AC2`-`$7AD1` (`PlayerY+1196`) |

### `LaunchMissile` (`$C3DE`)

**Launch a guided missile (no recording runs it)**

Reached from `$C171` and `$C25C` when a target was locked.

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissileStep` (`$C453`)

**The flat missiles' step (`$82`, `$85`): move, turn to the target, lifetime**

MoveObject, MissileTurn `$C47C` (IY = the target +`$32`, TurnToward), MissileLife `$C465`: +`$31` less one; at 0, or when the target's +2 is 0, CALL `$B61E` and +2 = 0 (the missile ends). `$C45D` is the serial check HomingMissileStep calls: the serial seen at the launch (+`$35`) against the target's +`$20`; a reused record ends the missile.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissileSerialCheck` (`$C45D`)

**MissileSerialCheck**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissileLife` (`$C465`)

**MissileLife**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissileTurn` (`$C47C`)

**MissileTurn**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintAmmo` (`$C510`)

**Print the current slot's rounds when it is the one shown**

When the slot shown (`$D114`) is the current `$C53C`, falls into PrintAmmoAt.

Witness: L1 169 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 86 calls (`stage1/death` 62, `stage1/play2` 17, `stage1/play` 7) |
| Called from | `FireCannon`, `LaunchProjectile`, `SelectWeapon` (tail), `DropMine` (tail) |
| Calls | `PrintAmmoAt` (falls into) |
| Reads | `$C53C` (`CurrentSlot`); `$D114` (`SlotShown`) |

### `PrintAmmoAt` (`$C519`)

**Print the rounds at `$FDC0`**

Converts the rounds at `$C527` and prints at `$FDC0`.

Witness: L1 170 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 18 calls (`stage1/play2` 18) |
| Called from | `PrintAmmo` (falls into), `SkeetFire` |
| Calls | `PrintString` (tail) |

### `PrintSlotStatus` (`$C51F`)

**Print the slot's status**

Clears `$BA13` and `$C4DC` (the IR view and the sight overlay off) when a weapon is deselected.

Witness: L1 17 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/play2` 9, `stage1/play` 4, `stage1/death` 1) |
| Called from | `SelectWeapon` |
| Writes | `$BA13` (`SetCamera+29`); `$C4DC` (`l_C4DB+1`) |

### `SelectWeapon` (`$C53F`)

**Select a weapon slot with the keys 1-4**

Writes `$C53C`, `$C53D` = the address of the slot hook's CALL operand (`$6A46` + 5n), the store type's words 0-3 (StoreTypes `$7B89` + 8 * type: K, J, fire, then the select call, word 3); a slot whose status `$68C9` + 6n is 0 prints "DAMAGED IN COMBAT" (`$C618`).

Witness: L1 17 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/play2` 9, `stage1/play` 4, `stage1/death` 1) |
| Called from | `PlayKeys` (tail) |
| Calls | `FillPanelRows`, `InvertPanelB`, `ShowMortarRange`, `SelectPhoenix`, `SelectPlain`, `PrintAmmo` (tail), `PrintSlotStatus`, `PrintElevation`, `ElevationZero`, `RetType11`, `SelectSpectre`, `SelectSlam`, `SelectPhantasm`, `SoundSelect` |
| Reads | `$68C9`-`$68DF` (`SlotGauges`); `$7B91`-`$7BF8` (`PlayWorkspace+1`); `$8368`-`$837F` (`WeaponSlots`); `$C529`-`$C53C` (`WeaponVars+2`, `AmmoPointers`, `CurrentSlot`) |
| Writes | `$6B45`-`$6B56` (`PlayKeys+10`); `$A9B9`-`$A9BA` (`l_A9A0+25`); `$B551`-`$B552` (`ConsumeAmmo+1`); `$C527`-`$C52B` (`WeaponVars`); `$C53C`-`$C53E` (`CurrentSlot`); `$C5D2` (`l_C5AA+40`); 4 more ranges |

### `RefreshWeaponPanel` (`$C632`)

**Redraw the weapon panel**

When `$C529` is set: InvertPanelB with `$6500`, then the slot's state at (`$0000` patched) chooses `$C605` (damaged) or WeaponSelectText.

Witness: L1 31 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 28 t-states own (0.00 %) |
| Runs (the other recordings) | 26 calls (`stage1/missions` 16, `stage1/play` 4, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission` |
| Calls | `InvertPanelB`, `WeaponSelectText` (tail) |
| Reads | `$68D5`-`$68DB` (`SlotGauges+12`); `$C529` (`WeaponVars+2`) |

### `PlayerHit` (`$CAA5`)

**The player's collision handler: armour and subsystem damage**

Type 4 goes to `$CB6C`. Height >= `$30`: the top armour `$8304` -= damage; else the side (HitSide `$CB4C`) `$8301` + L, then a random subsystem from the nine pointers at `$8338`. An underflow goes to `$CB38`: `$7BF9` = `$CCBE` "FAILED TO MAKE PICKUP" when `$68E8` is set, else `$CCAB` "UNIT DESTROYED", JP `$7047`. The Infinite Damage POKEs write OR (HL) at `$CAC8`, `$CAE8`, `$CB18`.

Witness: L1 116 (armour, c1, death, m1complete, m4complete, play2).

[Animation: `PlayerHit` at work](img/routines/PlayerHit.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 20 calls, 12,196 t-states own (0.00 %) |
| Runs (the other recordings) | 41 calls (`stage1/play2` 40, `stage1/death` 1) |
| Called from | `CollisionPass` |
| Calls | `ApiVector00`, `ApiVector06`, `SetMessage`, `HitSide`, `SetBounce` (tail) |
| Reads | `$68AB`-`$68DB` (`GaugeRecords`, `SlotGauges`); `$75F7` (`PlayerSpeed`); `$762D`-`$7640` (`PlayerY+23`); `$7795`-`$77A8` (`PlayerY+383`); `$77C3`-`$77E4` (`PlayerY+429`); `$77FF`-`$7800` (`PlayerY+489`); 11 more ranges |
| Writes | `$68AB`-`$68DB` (`GaugeRecords`, `SlotGauges`); `$75F7` (`PlayerSpeed`); `$8301`-`$8304` (`Armour`) |

### `HitSide` (`$CB4C`)

**Which side was hit (1-3) from the bearing**

From the hitter's view-space x (+`$2F`/+`$30`, negated when `$BA27` is set): |x| <= `$60` is side 2 (the front), else positive x side 1 and negative side 3; there is no rear side (play2: 25 runs).

Witness: L1 86 (c1, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 18 calls, 1,521 t-states own (0.00 %) |
| Runs (the other recordings) | 25 calls (`stage1/play2` 25) |
| Called from | `PlayerHit` |
| Calls | `NegHL` |

### `PushBack` (`$CBC6`)

**Push the player away from a type-4 obstacle (no recording runs it)**

Called from `$CB71`: adds -40 or 560 to the box side +`$0B`/+`$0C` by the heading of IY and stops the player.

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BounceDecay` (`$CC09`)

**After a wall: halve the speed until it is 0, then PlayerStep again**

+7 >>= 1 (SRA); when it reaches -1 or 0 ResetPlayerHandler (play2: 23 runs).

Witness: L1 43 (c1, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 16 calls, 1,475 t-states own (0.00 %) |
| Runs (the other recordings) | 23 calls (`stage1/play2` 23) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00`, `PlayerSteering` (tail), `ResetPlayerHandler` (tail) |
| Reads | `$75F7` (`PlayerSpeed`) |
| Writes | `$75F7` (`PlayerSpeed`) |

### `ResetPlayerHandler` (`$CC1E`)

**Set the player's handler back to PlayerStep**

+`$18`/+`$19` = `$A8C7`; also called when a mission starts (19 runs).

Witness: L1 28 (armour, c1, death, fuel, m1complete, m2erbe, m2ocean, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 268 t-states own (0.00 %) |
| Runs (the other recordings) | 19 calls (`stage1/missions` 8, `stage1/play2` 7, `stage1/death` 1 and 3 more) |
| Called from | `LoadMission`, `BounceDecay` (tail) |
| Writes | `$75F7` (`PlayerSpeed`); `$7608`-`$7609` (`PlayerHandler`) |

### `SetBounce` (`$CC33`)

**Set the handler to BounceDecay**

+`$18`/+`$19` = BounceDecay (play2: 4 runs).

Witness: L1 11 (c1, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3 calls, 155 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/play2` 4) |
| Called from | `PlayerHit` (tail) |
| Writes | `$7608`-`$7609` (`PlayerHandler`) |

### `PrintElevation` (`$CF26`)

**Print the elevation**

Prints `$FDF9`, then A = `$1E` and SetElevation.

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `SelectWeapon` |
| Calls | `PrintString`, `SetElevation` (tail) |

### `ElevationZero` (`$CF30`)

**The elevation `$14` for a launch**

A = `$14`, then SetElevation.

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `SelectWeapon` |
| Calls | `SetElevation` (falls into) |

### `SetElevation` (`$CF32`)

**The elevation's sin / cos to `$B5C5` / `$B5C8`**

A + `$C0` through `$67E8` (sin / cos) to `$B5C8` / `$B5C5`: the vertical and horizontal speed of the next launch.

Witness: L1 4 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 3, `stage1/play` 1) |
| Called from | `PrintElevation` (tail), `ElevationZero` (falls into), `LaunchSpectre`, `LaunchPhantasm` |
| Calls | `ApiVector14` |
| Writes | `$B5C5`-`$B5C8` (`LaunchProjectile+30`) |

### `FireClusterBomb` (`$CF3F`)

**Fire store type 8: projectile `$87` (damage 127)**

SelectAmmoPointer, A = `$87`, LaunchProjectile (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `PlayerSteering` |
| Calls | `LaunchProjectile` (tail), `SelectAmmoPointer` |
| Reads | `$C53C` (`CurrentSlot`) |

### `ClusterRise` (`$CF4A`)

**The bomb rises**

Height up by +`$31` while it lasts, then the parachute handler.

Witness: L1 14 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/play2` 14) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AD1` (`PlayerY+1211`) |
| Writes | `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AB8`-`$7ABD` (`PlayerY+1186`); `$7AD1` (`PlayerY+1211`) |

### `ClusterParachute` (`$CF80`)

**The bomb comes down on its parachute**

Height down slowly to the burst height.

Witness: L1 19 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 19 calls (`stage1/play2` 19) |
| Called from | `RunObjectHandlers` |
| Reads | `$7AA5`-`$7AA6` (`PlayerY+1167`) |
| Writes | `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AB8`-`$7ABD` (`PlayerY+1186`); `$7AD1` (`PlayerY+1211`) |

### `ClusterBlast` (`$CFAE`)

**The blast grows, then Explode**

The radius +`$16`/+`$17` grows each pass; at the end Explode `$B8AB`.

Witness: L1 15 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 15 calls (`stage1/play2` 15) |
| Called from | `RunObjectHandlers` |
| Calls | `Explode` (tail) |
| Reads | `$7AA5`-`$7AB0` (`PlayerY+1167`); `$7AD1` (`PlayerY+1211`) |
| Writes | `$7AA5`-`$7AB0` (`PlayerY+1167`); `$7AD1` (`PlayerY+1211`) |

### `SetMineTimer` (`$CFE9`)

**Set the Sleeper mine's timer 0-`$78`**

`LD A,n` / `INC A` / `CP $78`: the timer `$CFF5` 0-`$78`, wraps (play2: 4 runs).

Witness: L1 4 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 4) |
| Called from | `PlayKeys` (tail) |
| Reads | `$CFF5` (`MineTimerCode+1`) |
| Writes | `$CFF5` (`MineTimerCode+1`) |

### `StoreMineTimer` (`$CFFC`)

**Store the timer and print it**

`$CFF5` = A, prints `$FDF9` (play2: 4 runs).

Witness: L1 4 (play2).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `PrintString` (tail) |

### `DropMine` (`$D005`)

**Drop a Sleeper mine behind: projectile `$88`**

SelectAmmoPointer, A = `$88`, LaunchProjectile; the mine is placed behind the tank (heading + `$80`) (play2: 2 runs).

Witness: L1 2 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play2` 2) |
| Called from | `PlayerSteering` |
| Calls | `LaunchProjectile`, `PrintAmmo` (tail), `SelectAmmoPointer` |
| Reads | `$7612` (`PlayerHeading`); `$7A2F` (`PlayerY+1049`); `$7A59` (`PlayerY+1091`); `$7A6B` (`PlayerY+1109`); `$7A95` (`PlayerY+1151`); `$C52A`-`$C52B` (`WeaponVars+3`); 1 more ranges |
| Writes | `$7A2F` (`PlayerY+1049`); `$7A4A`-`$7A6B` (`PlayerY+1076`); `$7A86`-`$7A99` (`PlayerY+1136`); `$C532`-`$C533` (`WeaponVars+11`); `$D0AF`-`$D0B0` (`MineHudText+4`) |

### `MineFall` (`$D048`)

**The mine falls to the ground**

MoveObject, height -= +`$31`; at the ground MineArm.

Witness: L1 40 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 40 calls (`stage1/play2` 40) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$7A2D`-`$7A2E` (`PlayerY+1047`); `$7A59`-`$7A6A` (`PlayerY+1091`); `$7A95`-`$7A99` (`PlayerY+1151`); `$CFF5` (`MineTimerCode+1`) |
| Writes | `$6A55`-`$6A56` (`PlayLoop+73`); `$7A2D`-`$7A2E` (`PlayerY+1047`); `$7A40`-`$7A41` (`PlayerY+1066`); `$7A59`-`$7A6A` (`PlayerY+1091`); `$7A7C`-`$7A7D` (`PlayerY+1126`); `$7A95` (`PlayerY+1151`) |

### `MineArm` (`$D08C`)

**The timer to +`$31`**

+`$31` = `$CFF5` (play2: 2 runs).

Witness: L1 2 (play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MineHud` (`$D093`)

**Print the mine's timer**

Pops the return address into `$D0A9`; when the slot record `$C53D` is this weapon's, prints `$D0AB`.

Witness: L1 23 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 23 calls (`stage1/play2` 23) |
| Called from | `PlayLoop` |
| Calls | `PlayLoopTail` (tail), `PrintString` |
| Reads | `$C53D`-`$C53E` (`CurrentSlot+1`) |
| Writes | `$D0A9`-`$D0AA` (`l_D0A8+1`) |

### `MineCountdown` (`$D0B2`)

**The mine counts down and explodes**

+`$31` counts down; at 0 the mine explodes (the slot's text reset `$B0`).

Witness: L1 37 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 37 calls (`stage1/play2` 37) |
| Called from | `RunObjectHandlers` |
| Reads | `$7A59` (`PlayerY+1091`); `$7A95` (`PlayerY+1151`) |
| Writes | `$7A59` (`PlayerY+1091`); `$7A95` (`PlayerY+1151`) |

### `MineBlast` (`$D0EA`)

**The mine's blast: lifetime +`$31` less one, then Explode**

The step the countdown leaves at +`$18`: +`$31` less one each pass; at 0 Explode `$B8AB`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlamOn` (`$D0F5`)

**SLAM on (K): the slot hook = SlamHook**

Writes SlamHook `$D115` into the slot hook whose CALL operand `$C53D` points at, prints `$FDD7` (on).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlamOff` (`$D104`)

**SLAM off (J): the slot hook = NoAction**

Prints `$FDE1` (off); the slot hook (its CALL operand's address in `$C53D`) gets NoAction `$6BB0` (play2: 3 runs).

Witness: L1 3 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play2` 3) |
| Called from | `PlayKeys` (tail) |
| Calls | `PrintString` |
| Reads | `$C53D`-`$C53E` (`CurrentSlot+1`) |
| Writes | `$6A46`-`$6A47` (`PlayLoop+58`) |

### `SlamHook` (`$D115`)

**The SLAM's slot hook, once a pass while on**

`PUSH AF` (the slot), CALL SlamFire, then `JP $D3DF`: SlotShown restored, SelectAmmoPointer for the selected slot.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlamFire` (`$D11C`)

**The SLAM: shoot down one enemy shell**

SlotShown = the slot, SelectAmmoPointer; SlamScan lists the shells; none (`$D21B` = `$FF`) or no round: return. Takes a round (PrintAmmo), SlamTimers, SlamPickShell; Debris (vector `$67DF`) and +2 = 0 for that record (no UnregisterCollision), the beam drawn to its view position (RunScript `$990F`, the script `$FEBB`), then the sound `$D839`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlamScan` (`$D1A0`)

**List the enemy shells for the SLAM**

Records 1-23 from `$762E` (+2 of record 1): present (+2 b7) and +3 AND `$50` = `$10` (a shell, not a weapon): +`$3B`, the collision slot, goes to the list `$D21B`; `$FF` ends it. After a match the scan goes on two bytes short (+`$3C` instead of +`$3E`: no `ADD HL,DE` on that path), so the next records are read from their +0 and +1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlamTimers` (`$D1CF`)

**The shells' pair timers for the SLAM**

For each slot in `$D21B`: its collision row (`$C78C` + 2 slot), |the row's timer - `$C7BD`| into `$D233`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SlamPickShell` (`$D1F5`)

**Pick the shell to shoot: A = its collision slot**

Meant as the minimum of `$D233` over the list, but the search starts with `LD DE,$0000` (nothing writes the operand `$D1FD`) and takes a value only when `CP E` carries, never with E = 0: D stays 0 and the first listed shell is returned (`$D21B` + 0). `$D21B` (24) and `$D233` (24) are its work area.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RetType11` (`$D24B`)

**The select routine of store type 11 (none)**

`RET`: the select routine of store type 11.

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `SelectWeapon` |

### `SkeetFire` (`$D24C`)

**Fire the Skeet (store 11): projectile `$89` behind**

SelectAmmoPointer, ConsumeAmmo, spawns `$89` behind (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `PlayerSteering` |
| Calls | `ApiVector03`, `ApiVector04`, `SetFireCooldown` (tail), `ConsumeAmmo`, `PrintAmmoAt`, `SelectAmmoPointer` |
| Reads | `$67A7`-`$67AC` (`WorldVars+4`); `$7612` (`PlayerHeading`); `$C53C` (`CurrentSlot`) |
| Writes | `$7A64` (`PlayerY+1102`); `$7A86`-`$7A97` (`PlayerY+1136`) |

### `SkeetStraight` (`$D28C`)

**The Skeet's straight leg**

MoveObject; +`$31` counts the leg, +`$33` the legs left; at 0 Explode.

Witness: L1 13 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/play2` 13) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$7A95`-`$7A97` (`PlayerY+1151`) |
| Writes | `$7A7C`-`$7A7D` (`PlayerY+1126`); `$7A95`-`$7A97` (`PlayerY+1151`) |

### `SkeetZigZag` (`$D2AE`)

**The Skeet's zig-zag**

MoveObject; the heading += +`$32` each pass (the zig-zag), legs as SkeetStraight.

Witness: L1 26 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 26 calls (`stage1/play2` 26) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$7A86`-`$7A97` (`PlayerY+1136`) |
| Writes | `$7A7C`-`$7A96` (`PlayerY+1126`) |

### `PhantasmAutoOn` (`$D2E4`)

**Phantasm auto-fire on (K): the slot hook = `$D3D6`**

Writes `$D3D6` (the Phantasm's auto-fire hook) into the slot hook, its counter `$D3EB` = 16, prints `$FDD7` (on).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SpectreAutoOn` (`$D2F7`)

**Spectre auto-fire on (K): the slot hook = SpectreCode**

Writes SpectreCode `$D324` into the slot hook, its counter `$D335` = 16, prints `$FDD7` (on).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AutoFireOff` (`$D30B`)

**Auto-fire off (J, the Phantasm and the Spectre): the slot hook = NoAction**

The slot hook = NoAction `$6BB0`, prints `$FDCD` (off).

Witness: L1 7 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7 calls (`stage1/play` 4, `stage1/play2` 3) |
| Called from | `PlayKeys` (tail) |
| Calls | `PrintString` (tail) |
| Reads | `$C53D`-`$C53E` (`CurrentSlot+1`) |
| Writes | `$6A50`-`$6A56` (`PlayLoop+68`) |

### `FirePhantasm` (`$D319`)

**Fire the Phantasm: projectile `$8A`**

A = the slot, JP LaunchPhantasm (play: 1 run).

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `PlayerSteering` |
| Calls | `LaunchPhantasm` (tail) |
| Reads | `$C53C` (`CurrentSlot`) |

### `FireSpectre` (`$D31F`)

**Fire the Spectre (store 13): projectile `$8B`**

A = the slot, JR LaunchSpectre (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `PlayerSteering` |
| Reads | `$C53C` (`CurrentSlot`) |

### `SpectreCode` (`$D324`)

**The Spectre's auto-fire hook, once a pass while on**

Saves SlotShown, then `$D330`: SlotShown = the slot, the counter `$D335` less one; below 0 it reloads 16 and falls into LaunchSpectre (a shot every 17 passes); then `JP $D3DF` (SlotShown restored, SelectAmmoPointer for the selected slot).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_D330` (`$D330`)

**sub_D330**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LaunchSpectre` (`$D341`)

**Launch the Spectre**

SelectAmmoPointer, the elevation `$1E` (SetElevation), A = `$8B`, LaunchProjectile.

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `LaunchProjectile` (tail), `SetElevation`, `SelectAmmoPointer` |

### `SelectSpectre` (`$D34E`)

**The Spectre's select: print its auto-fire on or off**

When the slot hook is not SpectreCode `$D324`, prints `$FDCD` (off), else `$FDD7` (on) (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `SelectWeapon` |
| Calls | `PrintString` (tail) |
| Reads | `$6A50`-`$6A51` (`PlayLoop+68`); `$C53D`-`$C53E` (`CurrentSlot+1`) |

### `SpectreStep` (`$D369`)

**The Spectre's climb**

MoveObject; the height follows +`$31` (rising, then falling).

Witness: L1 19 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 19 calls (`stage1/play2` 19) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00`, `ApiVector06` |
| Reads | `$7A2D`-`$7A2E` (`PlayerY+1047`); `$7A59` (`PlayerY+1091`) |
| Writes | `$7A2D`-`$7A2F` (`PlayerY+1047`); `$7A40`-`$7A59` (`PlayerY+1066`) |

### `SpectreDrift` (`$D3AD`)

**The Spectre drifts under its parachute**

MoveObject, height -= 8 each pass; below height 0 it is removed (RemoveObject `$B8B1`). The same record: no submunition.

Witness: L1 47 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 47 calls (`stage1/play2` 47) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$7A2D`-`$7A2E` (`PlayerY+1047`) |
| Writes | `$7A2D`-`$7A2E` (`PlayerY+1047`) |

### `SelectAmmoPointer` (`$D3C6`)

**The current slot's ammunition pointer to `$B551`**

A = the slot; `$C534` + 2A to `$B551` (78 runs).

Witness: L1 156 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 78 calls (`stage1/death` 60, `stage1/play2` 12, `stage1/play` 6) |
| Called from | `FireCannon`, `FireMortar`, `FirePhoenixRr`, `FireBansheeRr`, `FirePhoenixIr`, `FireBansheeIr`, `LaunchDragonfly`, `FireClusterBomb`, `DropMine`, `SkeetFire`, `LaunchSpectre`, `LaunchPhantasm` |
| Reads | `$C534`-`$C53B` (`AmmoPointers`) |
| Writes | `$B551`-`$B552` (`ConsumeAmmo+1`) |

### `PhantasmCode` (`$D3D6`)

**The Phantasm's auto-fire hook, once a pass while on**

Saves SlotShown, then `$D3E6`: SlotShown = the slot, the counter `$D3EB` less one; below 0 it reloads 16 and falls into LaunchPhantasm (a shot every 17 passes); `$D3DF` puts SlotShown back and calls SelectAmmoPointer for the selected slot (SlamHook and SpectreCode end there too).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_D3E6` (`$D3E6`)

**sub_D3E6**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LaunchPhantasm` (`$D3F7`)

**Launch the Phantasm**

SelectAmmoPointer, SetElevation `$1E`, A = `$8A`, LaunchProjectile.

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `FirePhantasm` (tail) |
| Calls | `LaunchProjectile`, `SetElevation`, `SelectAmmoPointer` |

### `PhantasmStep` (`$D405`)

**The Phantasm's climb**

MoveObject; the height by +`$31` until it turns negative, then PhantasmSpin.

Witness: L1 19 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 19 calls (`stage1/play` 19) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$784D`-`$784E` (`PlayerY+567`); `$7879` (`PlayerY+611`) |
| Writes | `$784D`-`$784E` (`PlayerY+567`); `$7860`-`$7865` (`PlayerY+586`); `$7879` (`PlayerY+611`) |

### `PhantasmSpin` (`$D43B`)

**The Phantasm's spinning descent**

The heading += 2, height -= 4 each pass: a spinning descent (play: 104 runs).

Witness: L1 104 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 104 calls (`stage1/play` 104) |
| Called from | `RunObjectHandlers` |
| Reads | `$784D`-`$784E` (`PlayerY+567`); `$786A` (`PlayerY+596`) |
| Writes | `$784D`-`$784E` (`PlayerY+567`); `$786A` (`PlayerY+596`) |

### `SelectSlam` (`$D45E`)

**The SLAM's select: print on or off**

Prints `$FDD7` (on) when the slot hook is SlamHook `$D115`, else `$FDE1` (off) (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `SelectWeapon` |
| Reads | `$6A46`-`$6A47` (`PlayLoop+58`); `$C53D`-`$C53E` (`CurrentSlot+1`) |

### `SelectPhantasm` (`$D46A`)

**The Phantasm's select: print its auto-fire on or off**

Prints `$FDD7` (on) when the slot hook is the Phantasm's `$D3D6`, else `$FDCD` (off) (play: 1 run).

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `SelectWeapon` |
| Calls | `PrintString` (tail) |
| Reads | `$6A55`-`$6A56` (`PlayLoop+73`); `$C53D`-`$C53E` (`CurrentSlot+1`) |

### `CopyHudGlyphs` (`$D4A4`)

**Copy HUD glyphs to `$FD00`**

From the control-code table `$6F8F` into `$FD00`, 8 bytes and a zero per glyph.

Witness: L1 47 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/play`) |
| Called from | `OpNative` |
| Calls | `CopyHudGlyphsB` (falls into) |

### `CopyHudGlyphsB` (`$D4AE`)

**Copy one HUD glyph**

The 8-byte copy loop of CopyHudGlyphs.

Witness: L1 94 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 94 calls (`stage1/play` 94) |
| Called from | `CopyHudGlyphs` (falls into) |
| Reads | `$6F8F`-`$6F9E` (`ControlCodes`) |
| Writes | `$FD00`-`$FD0F` (`MissionHeader+8507`); `$FE0E`-`$FE1F` (`MissionHeader+8777`) |

### `BoundaryCheck` (`$D4B8`)

**The map edge: AWOL warning, then desertion**

A NOP / RET gate byte at `$D4B8`. |`$BC12`| against (`$DBD0`) and |`$BC1D`| against (`$DBD1`): inside, the state `$7578` = 0; outside, "GOING AWOL" (`$D51F`); beyond the extent + 4, `$7BF9` = `$CCD8` "PLAYER DESERTION" and `$7047`.

Witness: L1 9082 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 43 calls, 8,428 t-states own (0.00 %) |
| Runs (the other recordings) | 3,096 calls (`stage1/death` 2,491, `stage1/play` 232, `stage1/missions` 176 and 2 more) |
| Called from | `PlayerStep` |
| Calls | `ApiVector08` |
| Reads | `$BC12`-`$BC1D` (`l_BBFB+23`); `$DBD0`-`$DBD1` (`MissionHeader+11`) |

### `SetAwolState` (`$D4E9`)

**Set the AWOL state AwolState `$7578` (0 inside, 1 GOING AWOL, 2 desertion)**

`$7578` = A unless already equal.

Witness: L1 9039 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 43 calls, 1,212 t-states own (0.00 %) |
| Runs (the other recordings) | 3,053 calls (`stage1/death` 2,491, `stage1/play` 227, `stage1/play2` 171 and 2 more) |
| Calls | `ApiVector08` |
| Reads | `$7578` (`AwolState`) |

## objects

`src/game/objects.asm`

### `PlotRadarPixel` (`$A9FE`)

**Plot one radar pixel through the row table `$6600`**

Input: the blip's x and y on the radar. Looks up the screen row in the table `$6600`, ORs the pixel mask (E = `$49` + x AND 7 gives the bit) into the screen at the radar window `$5036`. Called by DrawRadar `$C05E` for each blip in the list `$6768`.

Witness: L1 45560 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,045 calls, 182,838 t-states own (0.03 %) |
| Runs (the other recordings) | 14,562 calls (`stage1/death` 7,338, `stage1/play2` 3,902, `stage1/play` 1,861 and 2 more) |
| Called from | `RadarPlotList` |
| Reads | `$5036`-`$509A` (screen); `$5136`-`$519A` (screen); `$5236`-`$529A` (screen); `$5336`-`$547A` (screen); `$5516`-`$557A` (screen); `$5616`-`$567A` (screen); 3 more ranges |
| Writes | `$5036`-`$509A` (screen); `$5136`-`$519A` (screen); `$5236`-`$529A` (screen); `$5336`-`$557A` (screen); `$5616`-`$567A` (screen); `$5716`-`$577A` (screen) |

### `BearingTo` (`$B766`)

**Bearing from IX to IY, a byte angle (vector `$67C1`)**

dx, dy of the two records, then the octant and the ratio (BearingOctant `$B916`, BearingRatio `$B94A`, the table `$B9DE`). Output A = 0-255.

Witness: L1 29500 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 193,080 t-states own (0.03 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `ApiVector01` (tail) |
| Calls | `BearingOctant` (tail) |
| Reads | `$7613`-`$7690` (`PlayerX`, `PlayerY`); `$76C7`-`$76CC` (`PlayerY+177`); `$7703`-`$7708` (`PlayerY+237`); `$773F`-`$78AC` (`PlayerY+297`); `$78E3`-`$7924` (`PlayerY+717`); `$795B`-`$7A50` (`PlayerY+837`); 4 more ranges |

### `InvertPanelA` (`$B7AE`)

**Invert the screen rows of the table `$6500` (a panel flash)**

HL = `$6500`, then InvertPanelRows `$B7BD`. Seen in m2erbe, missions and play (12 runs).

Witness: L1 12 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12 calls (`stage1/missions` 8, `stage1/play` 3, `stage1/m2erbe` 1) |
| Called from | `StatusKeys`, `PrintStatusHelp` (tail) |
| Calls | `InvertPanelRows` (tail) |
| Reads | `$40BA`-`$40FE` (screen); `$41BA`-`$41FE` (screen); `$42BA`-`$42FE` (screen); `$43BA`-`$43FE` (screen); `$44BA`-`$44FE` (screen); `$45BA`-`$45FE` (screen); 3 more ranges |
| Writes | `$40BA`-`$40FE` (screen); `$41BA`-`$41FE` (screen); `$42BA`-`$42FE` (screen); `$43BA`-`$43FE` (screen); `$44BA`-`$44FE` (screen); `$45BA`-`$45FE` (screen); 3 more ranges |

### `InvertPanelB` (`$B7B6`)

**Invert the rows of the table `$6550`**

HL = `$6550` (or the caller's HL), then InvertPanelRows. RefreshWeaponPanel `$C632` calls it with `$6500`.

Witness: L1 29 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 26 calls (`stage1/play2` 15, `stage1/play` 10, `stage1/death` 1) |
| Called from | `SelectWeapon`, `RefreshWeaponPanel` |
| Calls | `InvertPanelRows` (falls into) |
| Reads | `$400B`-`$405C` (screen); `$410B`-`$415C` (screen); `$420B`-`$425C` (screen); `$430B`-`$435C` (screen); `$440B`-`$445C` (screen); `$450B`-`$455C` (screen); 3 more ranges |
| Writes | `$400B`-`$405C` (screen); `$410B`-`$415C` (screen); `$420B`-`$425C` (screen); `$430B`-`$435C` (screen); `$440B`-`$445C` (screen); `$450B`-`$455C` (screen); 3 more ranges |

### `InvertPanelRows` (`$B7BD`)

**Invert N screen rows from a table of addresses**

Each table entry is a screen address; the row's bytes are complemented (a flash of the panel when a weapon is selected or hit).

Witness: L1 41 (armour, death, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/play` 13) |
| Called from | `InvertPanelA` (tail), `InvertPanelB` (falls into) |
| Reads | `$400B`-`$48BE` (screen); `$497A`-`$49BE` (screen); `$4A7A`-`$4ABE` (screen); `$4B7A`-`$4BBE` (screen); `$4C7A`-`$4CBE` (screen); `$4D7A`-`$4DBE` (screen); 5 more ranges |
| Writes | `$400B`-`$48BE` (screen); `$497A`-`$49BE` (screen); `$4A7A`-`$4ABE` (screen); `$4B7A`-`$4BBE` (screen); `$4C7A`-`$4CBE` (screen); `$4D7A`-`$4DBE` (screen); 2 more ranges |

### `ScriptDrawCarried` (`$B7E5`)

**3D script opcode 22: draw the carried object when the flag `$B7EB` is set**

Called from the script interpreter `$990F` (opcode 22, `$98E1` table). Pops the return address into the `JP nn` at `$B824` (operand `$B825`); the operand of `LD A,n` at `$B7EB` is the flag. When it is set: saves `$9A8E` / `$9AB3` / `$9A6C`, pages bank 3 (`$726C`), DrawModel `$B82A` with the record from `$68E6`, restores the view values. In every recording the flag is 0 and only the `JP` back runs.

Witness: L1 237 (armour, m1complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 4) |
| Called from | `sub_9927` |
| Calls | `ScriptNext` (tail) |
| Writes | `$B825`-`$B826` (`ScriptDrawCarriedReturn+1`) |

### `DrawObject` (`$B827`)

**Draw one object: its model, or the wreck model**

Input IX = the record. +2 bit 6 picks the wreck model +8/+9 instead of +`$1C`/+`$1D`; falls into DrawModel `$B82A`.

Witness: L1 27342 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 559 calls, 364,258 t-states own (0.06 %) |
| Runs (the other recordings) | 9,194 calls (`stage1/death` 6,208, `stage1/play2` 1,689, `stage1/play` 758 and 2 more) |
| Called from | `DrawEntry` (tail) |
| Reads | `$67A6` (`WorldVars+3`); `$757A` (`AwolState+2`); `$762E`-`$7A68` (`PlayerY+24`); `$7A80`-`$7AA4` (`PlayerY+1130`); `$7ABC`-`$7AE0` (`PlayerY+1190`, `HelicarrierRecord`); `$7AF8`-`$7B0C` (`HelicarrierRecord+28`) |
| Writes | `$68E7` (`MissionScore+5`); `$757A` (`AwolState+2`); `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$A12C` (`OpPolarPoints+19`); 1 more ranges |

### `DrawModel` (`$B82A`)

**Project and draw a 3D model at the object's view-space position**

Loads the view x / depth (+`$2B`..+`$2E`) into `$9A8E` / `$9AB3`, the night-sight mode `$757A`, and calls the 3D engine (bank 2 `$990F`).

Witness: L1 27342 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `RunScript` |

### `MissileHit` (`$B8A8`)

**A missile's hit handler: reset the sight timer, then fall into Explode**

The collision handler (template +`$1A`) of the missiles `$82`-`$85`: CALL ResetSightTimer `$C506` (the radar lock's gate opens again), then falls into Explode `$B8AB`. No recording launches a missile.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RemoveObject` (`$B8B1`)

**Free a record: unregister its collision, clear +2**

Input IX. UnregisterCollision `$CA3B`, +2 = 0 (the slot is free for FindFreeObject).

Witness: L1 134 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 53 calls (`stage1/death` 50, `stage1/play` 2, `stage1/play2` 1) |
| Called from | `CannonShellStep` (tail), `MortarShellStep` (tail) |
| Calls | `ApiVector05` |
| Writes | `$762E`-`$76A6` (`PlayerY+24`); `$76E2` (`PlayerY+204`); `$775A` (`PlayerY+324`); `$7796` (`PlayerY+384`); `$7886` (`PlayerY+624`); `$78FE` (`PlayerY+744`); 5 more ranges |

### `BearingOctant` (`$B916`)

**BearingTo: the octant from the signs of dx, dy**

dx, dy signs give 8 octants; then BearingRatio.

Witness: L1 29500 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 46,321 t-states own (0.01 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `BearingTo` (tail) |
| Calls | `ApiVector07`, `NegDE`, `BearingRatio` |

### `BearingRatio` (`$B94A`)

**BearingTo: the ratio of the smaller to the larger delta**

Divides the smaller |delta| by the larger to an index of BearingTable.

Witness: L1 29500 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 32,321 t-states own (0.00 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `BearingOctant` |
| Calls | `BearingLookup` (tail) |

### `BearingLookup` (`$B95A`)

**BearingTo: the angle from the table `$B9DE`**

Adds the octant base to the table angle.

Witness: L1 29500 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 190,511 t-states own (0.03 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `BearingRatio` (tail) |
| Calls | `Divide` |
| Reads | `$B9DE`-`$B9F5` (`BearingTable`) |

### `ActivateMissionObjects` (`$BBF1`)

**Spawn the mission objects near the player, despawn the far ones (16 per call)**

Walks the (`$DBD9`) records of 8 bytes at (`$DBDA`), 16 per call (the index is kept in `$BBF2` / `$BBFA`). A live record (bit 7) not yet spawned within 9 coarse units (InRange `$BD67`) gets a slot (FindSlot `$BCFD`), its type (ObjectSetType `$BD41`), a collision slot (`$C957`), its heading and position (CopyHeading `$BCBA`, CopyPosition `$BCC6`), and bit 6. A spawned one out of range is freed (bit 6 cleared; the slot found by +0 = the index in `$BC33`).

Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

[Animation: `ActivateMissionObjects` at work](img/routines/ActivateMissionObjects.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 549,568 t-states own (0.08 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `ApiVector03`, `ApiVector04`, `ApiVector05`, `CopyHeading`, `FindSlot`, `InRange` |
| Reads | `$75F0`-`$784A` (`ObjectTable`, `PlayerHeight`, `PlayerSpeed`, `PlayerHandler` and 3 more); `$7884`-`$7886` (`PlayerY+622`); `$78C0`-`$78C2` (`PlayerY+682`); `$78FC`-`$78FE` (`PlayerY+742`); `$7938`-`$7976` (`PlayerY+802`); `$79B2` (`PlayerY+924`); 8 more ranges |
| Writes | `$762C`-`$784A` (`PlayerY+22`); `$7884`-`$7886` (`PlayerY+622`); `$78C0`-`$78C2` (`PlayerY+682`); `$78FC`-`$78FE` (`PlayerY+742`); `$7938`-`$7976` (`PlayerY+802`); `$79B0`-`$79B2` (`PlayerY+922`); 13 more ranges |

### `CopyHeading` (`$BCBA`)

**Copy the list record's heading (+2) to the object**

The list record's +2 to the object's +`$22`.

Witness: L1 365 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11 calls, 796 t-states own (0.00 %) |
| Runs (the other recordings) | 183 calls (`stage1/missions` 79, `stage1/death` 37, `stage1/play2` 36 and 2 more) |
| Called from | `ActivateMissionObjects` |
| Calls | `CopyPosition` (falls into) |
| Reads | `$DCB2`-`$DD1C` (`MissionHeader+237`); `$DD32`-`$DD48` (`MissionHeader+365`); `$DD78`-`$DE96` (`MissionHeader+435`); `$DEBE` (`MissionHeader+761`); `$DEF4` (`MissionHeader+815`); `$DF16`-`$DF3C` (`MissionHeader+849`); 2 more ranges |
| Writes | `$764D`-`$786A` (`PlayerY+55`); `$78A5`-`$78A6` (`PlayerY+655`); `$78E1`-`$78E2` (`PlayerY+715`); `$791D`-`$791E` (`PlayerY+775`); `$7959`-`$7996` (`PlayerY+835`); `$79D1`-`$79D2` (`PlayerY+955`); 3 more ranges |

### `CopyPosition` (`$BCC6`)

**Copy the list record's X / Y words, << 2 into 24 bits (WordToWorld `$BD83`)**

+4/+5 and +6/+7 of the list record through WordToWorld `$BD83` to +`$23`-+`$25` and +`$26`-+`$28`.

Witness: L1 730 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 22 calls, 2,286 t-states own (0.00 %) |
| Runs (the other recordings) | 366 calls (`stage1/missions` 158, `stage1/death` 74, `stage1/play2` 72 and 2 more) |
| Called from | `CopyHeading` (falls into) |
| Calls | `WordToWorld` |
| Reads | `$DCB4`-`$DD21` (`MissionHeader+239`); `$DD34`-`$DD4D` (`MissionHeader+367`); `$DD7A`-`$DE9B` (`MissionHeader+437`); `$DEC0`-`$DEC3` (`MissionHeader+763`); `$DEF6`-`$DEF9` (`MissionHeader+817`); `$DF18`-`$DF41` (`MissionHeader+851`); 2 more ranges |
| Writes | `$764F`-`$7870` (`PlayerY+57`); `$78A7`-`$78AC` (`PlayerY+657`); `$78E3`-`$78E8` (`PlayerY+717`); `$791F`-`$7924` (`PlayerY+777`); `$795B`-`$799C` (`PlayerY+837`); `$79D3`-`$79D8` (`PlayerY+957`); 3 more ranges |

### `FindProjectileSlot` (`$BCD6`)

**Find a free record for a projectile (up to record 23)**

D = `$17`, falls into FindFreeObject.

Witness: L1 148 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 70 calls (`stage1/death` 60, `stage1/play2` 6, `stage1/play` 4) |
| Called from | `ConsumeAmmo` |
| Calls | `FindFreeObjectD` (tail) |

### `FindFreeObject` (`$BCDA`)

**Find a free record 1-20 (vector `$67C4`)**

D = `$15`; carry set and IX = the record when found.

Witness: L1 1410 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 17 calls, 9,784 t-states own (0.00 %) |
| Runs (the other recordings) | 219 calls (`stage1/missions` 74, `stage1/play2` 64, `stage1/play` 50 and 2 more) |
| Called from | `ApiVector02` (tail) |
| Calls | `FindFreeObjectD` (falls into) |
| Reads | `$762E`-`$78FE` (`PlayerY+24`); `$793A` (`PlayerY+804`); `$7976` (`PlayerY+864`); `$79B2` (`PlayerY+924`); `$79EE` (`PlayerY+984`); `$7A2A` (`PlayerY+1044`); 2 more ranges |

### `FindFreeObjectD` (`$BCDC`)

**Find a free record below D: +2 = 0**

Stores 23 - E in `$C95C` and the record in `$C973`.

Witness: L1 1558 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 206 calls (`stage1/death` 82, `stage1/play2` 70, `stage1/play` 54) |
| Called from | `FindProjectileSlot` (tail), `FindFreeObject` (falls into) |
| Calls | `FindFreeLoop` (tail) |
| Reads | `$762E`-`$793A` (`PlayerY+24`); `$7976` (`PlayerY+864`); `$79B2` (`PlayerY+924`); `$79EE` (`PlayerY+984`); `$7A2A` (`PlayerY+1044`); `$7A66` (`PlayerY+1104`); 2 more ranges |

### `FindFreeLoop` (`$BCF0`)

**The scan loop**

Steps 60 bytes per record until +2 = 0 or the limit.

Witness: L1 1146 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 1,848 t-states own (0.00 %) |
| Runs (the other recordings) | 415 calls (`stage1/missions` 123, `stage1/death` 118, `stage1/play2` 100 and 2 more) |
| Called from | `FindFreeObjectD` (tail), `FindSlot` (tail) |
| Writes | `$C95C` (`RegisterCollision+5`); `$C973`-`$C974` (`l_C96D+6`) |

### `FindSlot` (`$BCFD`)

**Find a slot for a list record: the first free or evictable record of 1-20**

One scan of records 1-20 (it does not call FindFreeObject): the first record that is free (+2 = 0) or holds an enemy shell (+3 AND `$50` = `$10`) is taken; an evicted shell is unregistered (`$67CD`) and its +2 cleared. Then the list index to +0. NC when none.

Witness: L1 543 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11 calls, 6,912 t-states own (0.00 %) |
| Runs (the other recordings) | 185 calls (`stage1/missions` 79, `stage1/death` 37, `stage1/play2` 36 and 2 more) |
| Called from | `ActivateMissionObjects` |
| Calls | `ApiVector05`, `FindFreeLoop` (tail) |
| Reads | `$762E`-`$78FF` (`PlayerY+24`); `$793A`-`$793B` (`PlayerY+804`); `$7976`-`$7977` (`PlayerY+864`); `$79B2`-`$79B3` (`PlayerY+924`); `$79EE`-`$79EF` (`PlayerY+984`); `$7A2A`-`$7A2B` (`PlayerY+1044`); 2 more ranges |
| Writes | `$762E` (`PlayerY+24`); `$76E2` (`PlayerY+204`); `$784A` (`PlayerY+564`); `$793A` (`PlayerY+804`); `$7976` (`PlayerY+864`); `$79B2` (`PlayerY+924`); 5 more ranges |

### `ObjectSetType` (`$BD41`)

**Set the type and copy the 30-byte template (vector `$67C7`)**

Input A = type. Bit 7: the resident template `$B3CA` + 30 * (A - `$80`); else the mission's template table (`$DBD7`) + 30 * A. Stores the type at +1, copies the 30 template bytes to +2..+`$1F` and the serial to +`$20`.

Witness: L1 1235 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 38,149 t-states own (0.01 %) |
| Runs (the other recordings) | 431 calls (`stage1/missions` 125, `stage1/death` 119, `stage1/play2` 103 and 2 more) |
| Called from | `ApiVector03` (tail) |
| Reads | `$B3CA`-`$B405` (`ShellTemplate80`); `$B47E`-`$B54F` (`ShellTemplate80+180`); `$DBD7`-`$DBD8` (`MissionHeader+18`); `$DE5F`-`$DE7C` (`MissionHeader+666`); `$DEB9`-`$DEF4` (`MissionHeader+756`); `$DF09`-`$E1C4` (`MissionHeader+836`); 2 more ranges |
| Writes | `$762D`-`$7994` (`PlayerY+23`); `$79B1`-`$79D0` (`PlayerY+923`); `$79ED`-`$7A0C` (`PlayerY+983`); `$7A29`-`$7A48` (`PlayerY+1043`); `$7A65`-`$7A84` (`PlayerY+1103`); `$7AA1`-`$7AC0` (`PlayerY+1163`); 2 more ranges |

### `InRange` (`$BD67`)

**Is the list record within range of the player (4 coarse units for type 0, 9 for the others)**

|X word >> 8 - `$BC12`| and |Y - `$BC1D`| below the range: 4 for type 0 (trees), 9 for every other type (type 1 trees included). Called for each list record (70 373 runs).

Witness: L1 198222 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,613 calls, 227,113 t-states own (0.03 %) |
| Runs (the other recordings) | 70,373 calls (`stage1/death` 47,698, `stage1/play2` 9,278, `stage1/missions` 6,198 and 2 more) |
| Called from | `ActivateMissionObjects` |
| Calls | `ApiVector08` |

### `WordToWorld` (`$BD83`)

**A list word << 2 into a 24-bit coordinate**

HL << 2 with the carry into the third byte.

Witness: L1 730 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 22 calls, 1,906 t-states own (0.00 %) |
| Runs (the other recordings) | 366 calls (`stage1/missions` 158, `stage1/death` 74, `stage1/play2` 72 and 2 more) |
| Called from | `CopyPosition` |

### `TransformObjects` (`$BD98`)

**Make every present object camera-relative, cull it, insert it into the depth tree**

For each record with +2 bit 7: position minus camera, RotateToView `$BBBC`, depth cull, OnScreen `$BEA2` with the radius, then DepthInsert `$BEDE` into the tree at `$6800`; a blip for the radar (RadarAddBlip `$C0B2`).

Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 1,790,960 t-states own (0.27 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `RotateToView`, `OnScreen`, `ClearDepthTree`, `DepthInsert`, `RadarAddBlip` |
| Reads | `$66D0`-`$66D3` (`PolyWorkSpare+1`); `$67A7`-`$67AE` (`WorldVars+4`); `$762E`-`$79F2` (`PlayerY+24`); `$7A0F`-`$7A14` (`PlayerY+1017`); `$7A2A`-`$7A2E` (`PlayerY+1044`); `$7A4B`-`$7A50` (`PlayerY+1077`); 9 more ranges |
| Writes | `$66CF`-`$66D3` (`PolyWorkSpare`); `$762E`-`$7A2A` (`PlayerY+24`); `$7A53`-`$7A66` (`PlayerY+1085`); `$7A8F`-`$7AA2` (`PlayerY+1145`); `$7ACB`-`$7ADE` (`PlayerY+1205`, `HelicarrierRecord`); `$7B07`-`$7B1A` (`HelicarrierRecord+43`); 5 more ranges |

### `OnScreen` (`$BEA2`)

**Is the object within the screen with its radius**

View x (+`$2B`/+`$2C`) against the depth with the radius +`$16`/+`$17`.

Witness: L1 103866 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,677 calls, 323,721 t-states own (0.05 %) |
| Runs (the other recordings) | 32,872 calls (`stage1/death` 18,315, `stage1/play2` 6,343, `stage1/play` 4,489 and 2 more) |
| Called from | `TransformObjects` |
| Calls | `OnScreenX` (falls into) |
| Reads | `$7642`-`$7ACC` (`PlayerY+44`); `$7AF2`-`$7AF3` (`HelicarrierRecord+22`); `$7B07`-`$7B08` (`HelicarrierRecord+43`) |

### `OnScreenX` (`$BEA8`)

**The x half of OnScreen**

The entry for the x test.

Witness: L1 103879 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 6,356 calls (`stage1/play2` 6,356) |
| Called from | `OnScreen` (falls into), `MissileSeek` |
| Reads | `$7642`-`$7A18` (`PlayerY+44`); `$7A3E`-`$7A3F` (`PlayerY+1064`); `$7A53`-`$7A54` (`PlayerY+1085`); `$7A7A`-`$7A7B` (`PlayerY+1124`); `$7A8F`-`$7A90` (`PlayerY+1145`); `$7AB6`-`$7AB7` (`PlayerY+1184`); 1 more ranges |

### `ClearDepthTree` (`$BED2`)

**Empty the depth tree at `$6800`**

Resets the node pointer and the root at `$6800`.

Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 7,394 t-states own (0.00 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `TransformObjects` |
| Writes | `$66D4` (`PolyWorkSpare+5`); `$6800` (`PlayWork`); `$BF22`-`$BF23` (`DepthTreeVars+2`) |

### `DepthInsert` (`$BEDE`)

**Insert a record into the depth tree (6-byte nodes: depth, left, right, record)**

Walks from the root, left when nearer, right when farther, and links a new 6-byte node.

Witness: L1 29277 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 562 calls, 222,304 t-states own (0.03 %) |
| Runs (the other recordings) | 9,829 calls (`stage1/death` 6,575, `stage1/play2` 1,843, `stage1/play` 783 and 2 more) |
| Called from | `TransformObjects` |
| Reads | `$66D4` (`PolyWorkSpare+5`); `$6800`-`$6850` (`PlayWork`); `$BF20`-`$BF23` (`DepthTreeVars`) |
| Writes | `$66D4` (`PolyWorkSpare+5`); `$6800`-`$6859` (`PlayWork`); `$BF20`-`$BF23` (`DepthTreeVars`) |

### `DrawObjectsInOrder` (`$BF53`)

**Draw the objects far to near (in-order walk of the depth tree)**

Calls DrawEntry `$BF83` per node.

Witness: L1 9794 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 82,123 t-states own (0.01 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop` |
| Calls | `DrawEntry` |
| Reads | `$66D4` (`PolyWorkSpare+5`); `$6802`-`$6857` (`PlayWork+2`) |

### `DrawEntry` (`$BF83`)

**Draw one tree entry: an object (DrawObject) or a debris particle**

A pointer at or above `$CF00` is a particle of the bank 3 list, drawn as a dot.

Witness: L1 29160 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 559 calls, 24,256 t-states own (0.00 %) |
| Runs (the other recordings) | 9,715 calls (`stage1/death` 6,575, `stage1/play2` 1,843, `stage1/play` 758 and 2 more) |
| Called from | `DrawObjectsInOrder` |
| Calls | `PageBank3`, `SaveBank`, `RestoreBank`, `RunScript`, `DrawObject` (tail) |
| Reads | `$67A6` (`WorldVars+3`); `$6804`-`$685B` (`PlayWork+4`) |
| Writes | `$68E7` (`MissionScore+5`); `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$ABFE` (`BoxTiltPitch+1`) |

### `MoveObject` (`$BFD1`)

**Move an object by its speed along its heading (vector `$67BE`)**

X += speed * sin(heading), Y += speed * cos(heading), through `$A8B2` / `$A7F2`.

Witness: L1 53953 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 632 calls, 315,573 t-states own (0.05 %) |
| Runs (the other recordings) | 14,450 calls (`stage1/death` 8,892, `stage1/play2` 2,342, `stage1/play` 1,779 and 2 more) |
| Called from | `ApiVector00` (tail) |
| Calls | `MulFrac`, `SinCosHalf` |
| Reads | `$75F7`-`$7708` (`PlayerSpeed`, `PlayerHandler`, `PlayerHeading`, `PlayerX` and 1 more); `$775F`-`$7A8C` (`PlayerY+329`); `$7AA7` (`PlayerY+1169`); `$7AC1`-`$7AC8` (`PlayerY+1195`); `$7AE3` (`HelicarrierRecord+7`); `$7AFD`-`$7B04` (`HelicarrierRecord+33`); 1 more ranges |
| Writes | `$7613`-`$7708` (`PlayerX`, `PlayerY`); `$777B`-`$7A8C` (`PlayerY+357`); `$7AC3`-`$7AC8` (`PlayerY+1197`); `$7AFF`-`$7B04` (`HelicarrierRecord+35`); `$BBC8` (`RotateToView+12`) |

### `RunObjectHandlers` (`$C026`)

**Run each present object's step handler**

24 records from `$75F0`: when +2 bit 7 and +3 bit 0 are set, CALL (+`$18`) with IX = the record.

Witness: L1 9836 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 445,594 t-states own (0.07 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `PlayLoopTail`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `ApiVector00`, `PlayerStep`, `CannonShellStep`, `MortarShellStep`, `DragonflyStep`, `BounceDecay`, `ClusterRise`, `ClusterParachute`, `ClusterBlast`, `MineFall`, `MineCountdown`, `SkeetStraight`, `SkeetZigZag`, `SpectreStep`, `SpectreDrift`, `PhantasmStep`, `PhantasmSpin`, `HelicarrierInit`, `HelicarrierWait`, `MissionHeader` |
| Reads | `$75F2`-`$7AB9` (`ObjectTable+2`, `PlayerHeight`, `PlayerSpeed`, `PlayerHandler` and 3 more); `$7ADE`-`$7ADF` (`HelicarrierRecord+2`); `$7AF4`-`$7AF5` (`HelicarrierRecord+24`); `$7B1A` (`HelicarrierRecord+62`); `$7B56` (`HelicarrierRecord+122`) |
| Writes | `$C04B`-`$C050` (`l_C030+27`, `l_C04F`) |

### `DrawRadar` (`$C05E`)

**Draw the radar: clear it, plot the blip list `$6768`**

ClearRadar `$C094`, then RadarPlotList `$C079` (3483 runs, every 3D frame but the first).

Witness: L1 9770 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 117,822 t-states own (0.02 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop` |
| Calls | `ClearRadar` |
| Reads | `$6768`-`$6780` (`FaceFlags+64`); `$68C3` (`GaugeRecords+24`); `$7BFB`-`$7BFC` (`FailReason+2`) |
| Writes | `$6768`-`$6780` (`FaceFlags+64`); `$AA1A` (`PlotRadarPixel+28`) |

### `RadarPlotList` (`$C079`)

**Plot the list of blips and reset it**

Resets the list pointer `$7BFB`, sets `$AA1A`, plots each pair at `$6768` through PlotRadarPixel `$A9FE`.

Witness: L1 9770 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `PlotRadarPixel` |

### `ClearRadar` (`$C094`)

**Clear 32 rows of 5 bytes at `$5036` with stack pushes**

SP = the radar's screen rows, PUSH of zeros (32 rows, 5 bytes each at `$5036`).

Witness: L1 9770 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 742,358 t-states own (0.11 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `DrawRadar` |
| Writes | `$5036`-`$509A` (screen); `$5136`-`$519A` (screen); `$5236`-`$529A` (screen); `$5336`-`$539A` (screen); `$5416`-`$547A` (screen); `$5516`-`$557A` (screen); 3 more ranges |

### `RadarAddBlip` (`$C0B2`)

**Add an object to the radar list when within range**

Input: the object's offset from the player. RadarRange `$C104`, RadarScale `$C0D2`, RadarStoreBlip `$C0F7`.

Witness: L1 88141 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,378 calls, 952,507 t-states own (0.14 %) |
| Runs (the other recordings) | 27,405 calls (`stage1/death` 14,737, `stage1/play2` 5,403, `stage1/play` 3,936 and 2 more) |
| Called from | `TransformObjects` |
| Calls | `ApiVector07` |
| Reads | `$7BFB`-`$7BFC` (`FailReason+2`); `$BA27` (`l_BA1F+8`) |
| Writes | `$6768`-`$677F` (`FaceFlags+64`); `$7BFB`-`$7BFC` (`FailReason+2`) |

### `RadarScale` (`$C0D2`)

**Scale the offsets to radar units**

SRA H / RR L 8 times on each offset.

Witness: L1 88141 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `RadarRange` |

### `RadarStoreBlip` (`$C0F7`)

**Store the blip in the list at (`$7BFB`)**

Writes y, x to (`$7BFB`) and advances it.

Witness: L1 45950 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RadarRange` (`$C104`)

**Is the offset within the radar's range**

Carry set when the offset is out of the radar (|d| beyond the window).

Witness: L1 158626 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,474 calls, 140,602 t-states own (0.02 %) |
| Runs (the other recordings) | 48,723 calls (`stage1/death` 25,964, `stage1/play2` 9,762, `stage1/play` 7,064 and 2 more) |
| Called from | `RadarScale` |

### `TurnToward` (`$C485`)

**Turn IX toward IY by at most 4 per pass**

Input IX, IY. BearingTo, the difference with +`$22`; within 4 steps it leaves the heading as it is, else +-4. Used by the Helicarrier (HelicarrierWait) and the missiles (545 runs).

Witness: L1 2841 (armour, c1, death, fuel, m1complete, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 13 calls, 1,368 t-states own (0.00 %) |
| Runs (the other recordings) | 545 calls (`stage1/death` 249, `stage1/play` 132, `stage1/play2` 99 and 1 more) |
| Called from | `HelicarrierWait`, `MissionHeader` (tail) |
| Calls | `ApiVector01`, `ApiVector08` |
| Reads | `$764E` (`PlayerY+56`); `$768A` (`PlayerY+116`); `$786A` (`PlayerY+596`); `$78E2` (`PlayerY+716`); `$791E` (`PlayerY+776`); `$795A` (`PlayerY+836`); 7 more ranges |
| Writes | `$764E` (`PlayerY+56`); `$768A` (`PlayerY+116`); `$786A` (`PlayerY+596`); `$78E2` (`PlayerY+716`); `$791E` (`PlayerY+776`); `$795A` (`PlayerY+836`); 6 more ranges |

### `HomingMissileStep` (`$C4A5`)

**The height-following missiles' step (`$83`, `$84`)**

MissileTurn `$C47C`, MissileSerialCheck `$C45D` (with the lifetime), then the height = target + (own - target) / 16 (four `SRA H` / `RR L`: each pass closes 15/16 of the gap), stored by SetHeightAndMove `$C4C4`, which falls into MoveObject.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SetHeightAndMove` (`$C4C4`)

**Store the height (HL) and move the object**

Static only: `$7298` (a bank 3 call in bank 5) resolves here too, but bank 0's bytes at `$C4C4` are this tail.

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSightOverlay` (`$C4CD`)

**Draw the sight mask `$FD80` into the back buffer `$9000` while `$C4DC` is set**

The timer `$C4CE` counts down; at 0 ResetSightTimer. While `$C4DC` is set the 3D view gets the sight mask (3507 runs, every 3D frame).

Witness: L1 9793 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 5,310 t-states own (0.00 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop` |
| Reads | `$9000`-`$9101` (`BackBuffer+1295`); `$9120`-`$9121` (`BackBuffer+1583`); `$9140`-`$9141` (`BackBuffer+1615`); `$9160`-`$9161` (`BackBuffer+1647`); `$9180`-`$9181` (`BackBuffer+1679`); `$91A0`-`$91A1` (`BackBuffer+1711`); 4 more ranges |
| Writes | `$9000`-`$9101` (`BackBuffer+1295`); `$9120`-`$9121` (`BackBuffer+1583`); `$9140`-`$9141` (`BackBuffer+1615`); `$9160`-`$9161` (`BackBuffer+1647`); `$9180`-`$9181` (`BackBuffer+1679`); `$91A0`-`$91A1` (`BackBuffer+1711`); 2 more ranges |

### `ResetSightTimer` (`$C506`)

**Clear the sight timer `$C4CE` and open the target gate `$C198`**

`$C4CE` = 0, `$C198` = 1 (TargetInCone runs its body).

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CollisionPass` (`$C7BC`)

**Test the registered pairs and call both collision handlers**

For each pair whose timer is due: distance minus the radii, then the boxes; on an overlap calls IX's +`$1A` with IY the other, then the other way. The Immunity POKE writes 58 at `$C875` (`JP M,$C8AF` becomes `LD A,(nn)`, the overlap branch is gone).

Witness: L1 9836 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

[Animation: `CollisionPass` at work](img/routines/CollisionPass.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 1,717,826 t-states own (0.26 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `ApiVector10`, `NegHL`, `KillTree`, `Explode`, `RecordByIndex`, `PlayerHit`, `MissionHeader` |
| Reads | `$75F5`-`$7A4F` (`PlayerHeight`, `PlayerSpeed`, `PlayerHandler`, `PlayerHeading` and 2 more); `$7A69`-`$7A8B` (`PlayerY+1107`); `$7AA5`-`$7AC7` (`PlayerY+1167`); `$7AE7`-`$7B03` (`HelicarrierRecord+11`); `$C649`-`$C743` (`CollisionTables+1`); `$C775`-`$C7BD` (`CollisionTables+301`, `CollisionPass`) |
| Writes | `$C649`-`$C743` (`CollisionTables+1`); `$C7BD` (`CollisionPass+1`); `$C7FC`-`$C813` (`l_C7FB+1`); `$C8BE`-`$C8BF` (`l_C8AF+15`); `$C8D5`-`$C8D6` (`l_C8AF+38`); `$C918`-`$C929` (`l_C900+24`); 1 more ranges |

### `RecordByIndex` (`$C944`)

**HL = the record B (+2), A = its state**

Input B = the record number. Output HL = the record, A = +2.

Witness: L1 54430 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,292 calls, 254,279 t-states own (0.04 %) |
| Runs (the other recordings) | 15,176 calls (`stage1/play2` 5,062, `stage1/death` 4,648, `stage1/play` 3,086 and 2 more) |
| Called from | `CollisionPass` |
| Reads | `$75F2`-`$793A` (`ObjectTable+2`, `PlayerHeight`, `PlayerSpeed`, `PlayerHandler` and 3 more); `$7976` (`PlayerY+864`); `$79B2` (`PlayerY+924`); `$79EE` (`PlayerY+984`); `$7A2A` (`PlayerY+1044`); `$7A66` (`PlayerY+1104`); 2 more ranges |

### `RegisterCollision` (`$C957`)

**Give the record a collision slot (vector `$67CA`)**

Takes the first free entry of the slot list `$C775`, stores it in +`$3B`, sets the pair timers of the new row in `$C648`.

Witness: L1 1235 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 131,565 t-states own (0.02 %) |
| Runs (the other recordings) | 431 calls (`stage1/missions` 125, `stage1/death` 119, `stage1/play2` 103 and 2 more) |
| Called from | `ApiVector04` (tail) |
| Reads | `$75F2`-`$79EF` (`ObjectTable+2`, `PlayerHeight`, `PlayerSpeed`, `PlayerHandler` and 3 more); `$7A2A`-`$7A2B` (`PlayerY+1044`); `$7A66`-`$7A67` (`PlayerY+1104`); `$7AA2`-`$7AA3` (`PlayerY+1164`); `$7ADE`-`$7ADF` (`HelicarrierRecord+2`); `$7B1A` (`HelicarrierRecord+62`); 5 more ranges |
| Writes | `$C649`-`$C789` (`CollisionTables+1`); `$C9BA` (`l_C9B4+6`); `$C9D9`-`$C9E0` (`l_C9D1+8`); `$CA14` (`l_CA0B+9`) |

### `CollisionFilter` (`$C9A7`)

**Which pairs collide: the state bits 2 / 4 / 6 / 7**

Inside CollisionPass: both +2 bytes decide whether the pair is tested (radar bit 2, bit 4 no-collide, wrecks bits 6 / 7).

Witness: L1 12800 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UnregisterCollision` (`$CA3B`)

**Free the record's collision slot (vector `$67CD`)**

Returns the slot of +`$3B` to the list and marks the row's timers `$FF`.

Witness: L1 951 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 13 calls, 18,294 t-states own (0.00 %) |
| Runs (the other recordings) | 230 calls (`stage1/death` 114, `stage1/play2` 51, `stage1/play` 48 and 2 more) |
| Called from | `ApiVector05` (tail) |
| Reads | `$7667`-`$7793` (`PlayerY+81`); `$77CF`-`$78FB` (`PlayerY+441`); `$7937`-`$7A63` (`PlayerY+801`); `$7A9F` (`PlayerY+1161`); `$7ADB` (`PlayerY+1221`); `$7B17` (`HelicarrierRecord+59`); 1 more ranges |
| Writes | `$C649`-`$C789` (`CollisionTables+1`) |

### `StrikePlayer` (`$CA7C`)

**A unit strikes the tank with no shell: PlayerHit with the unit as the hitter, damage doubled**

IX = the unit. Saves its +3 and +`$14`, sets +3 b4 and doubles +`$14`, calls PlayerHit `$CAA5` with IY = the unit and IX = the tank (`$75F0`), then restores both bytes. Called by mission 8's type 10 at `$E1FC` (a direct strike while it is aligned, docs/07-objects.md 7.14); no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## world

`src/game/world.asm`

### `SegmentVisibility` (`$AD45`)

**Mark the segments near the player visible, 0 / `$FF` per segment at `$8305`**

Sets the coarse player position `$BC12` (X) and `$BC1D` (Y) = the camera words `$67A8` / `$67AB` >> 2, then for each of the (`$DBDC`) segments at `$DC80` tests both endpoints (TestVertexNear `$AE5C` / `$AE78`): visible if one lies within 8 coarse units on both axes. The flag goes to `$8305`+n. From the segment (`$DBDE`) on (the switchable ones) the flag is ANDed with the switch flags `$7BFD`, so a gate or bridge destroyed or opened by the mission script disappears.

Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 452,065 t-states own (0.07 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `ResetSegmentWalk` (tail), `TestVertexNear`, `TestVertexNearB` |
| Reads | `$67A8`-`$67AC` (`WorldVars+5`); `$7BFD`-`$7C06` (`FailReason+4`); `$ADF7` (`l_ADEA+13`); `$AE5A`-`$AE5B` (`SegmentWalkCount`); `$DBDC`-`$DBDE` (`MissionHeader+23`); `$DC80`-`$DD12` (`MissionHeader+187`) |
| Writes | `$8305`-`$831D` (`WorldWork`); `$AD4C`-`$AD4D` (`SegmentVisibility+7`); `$ADF2`-`$ADF7` (`l_ADEA+8`); `$AE1A` (`l_AE0F+11`); `$AE5A`-`$AE5B` (`SegmentWalkCount`); `$BC12`-`$BC1D` (`l_BBFB+23`) |

### `ResetSegmentWalk` (`$AE42`)

**Reset the segment walk: `$DC80`, the count (`$DBDC`), the flags `$8305`**

Stores `$DC80` in the pointer `$AD4C`, the segment count in `$AE5A`, `$8305` in `$AD48` and clears `$AE5B`. Called before SegmentVisibility.

Witness: L1 9868 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 120 calls, 13,080 t-states own (0.00 %) |
| Runs (the other recordings) | 3,576 calls (`stage1/death` 2,511, `stage1/play2` 416, `stage1/missions` 323 and 2 more) |
| Called from | `StartMission`, `SegmentVisibility` (tail) |
| Reads | `$DBDC` (`MissionHeader+23`) |
| Writes | `$AD48`-`$AD4D` (`SegmentVisibility+3`); `$AE5A`-`$AE5B` (`SegmentWalkCount`) |

### `TestVertexNear` (`$AE5C`)

**Test vertex A against the coarse player position: within 8 units**

EXX, then reads vertex X `$DC00`+A against `$BC12`; falls into TestVertexNearX `$AE61`. Carry out: the vertex is near.

Witness: L1 92716 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 19,992 t-states own (0.00 %) |
| Runs (the other recordings) | 33,063 calls (`stage1/death` 20,603, `stage1/missions` 5,978, `stage1/play2` 3,304 and 2 more) |
| Called from | `SegmentVisibility`, `DrawSegmentLoop` |
| Calls | `TestVertexNearX` (falls into) |
| Reads | `$BC12` (`l_BBFB+23`) |

### `TestVertexNearX` (`$AE61`)

**Compare one vertex coordinate with the player's, |d| < 8**

Input L = the vertex table offset, A = the player's coarse coordinate. Output carry set when |vertex - player| < 8. Used for both axes (TestVertexNearY `$AE79` adds `$40` to reach the Y table).

Witness: L1 170288 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,904 calls, 203,766 t-states own (0.03 %) |
| Runs (the other recordings) | 58,209 calls (`stage1/death` 35,965, `stage1/missions` 9,100, `stage1/play2` 6,608 and 2 more) |
| Called from | `TestVertexNear` (falls into), `TestVertexNearY` (tail) |
| Calls | `ApiVector08` |
| Reads | `$DC00`-`$DC19` (`MissionHeader+59`); `$DC40`-`$DC5B` (`MissionHeader+123`); `$DC80` (`MissionHeader+187`); `$DCC0` (`MissionHeader+251`) |

### `TestVertexNearB` (`$AE78`)

**Test the segment's second vertex (EXX, then the Y test)**

EXX and falls into TestVertexNearY `$AE79`.

Witness: L1 75268 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 36,176 t-states own (0.01 %) |
| Runs (the other recordings) | 24,774 calls (`stage1/death` 15,362, `stage1/play2` 3,304, `stage1/missions` 2,832 and 2 more) |
| Called from | `SegmentVisibility`, `DrawSegmentLoop` |
| Calls | `TestVertexNearY` (falls into) |
| Reads | `$BC1D` (`l_BBFB+34`) |

### `TestVertexNearY` (`$AE79`)

**Test a vertex's Y (`$DC40`+i) against `$BC1D`**

L = vertex + `$40`, A = (`$BC1D`), then JP TestVertexNearX `$AE61`.

Witness: L1 77572 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4,280 calls (`stage1/missions` 3,122, `stage1/m2erbe` 1,158) |
| Called from | `TestVertexNearB` (falls into), `DrawSegmentLoop` |
| Calls | `TestVertexNearX` (tail) |
| Reads | `$BC1D` (`l_BBFB+34`) |

### `SetupClipWindow` (`$AEA0`)

**Build the clip window and the vertex buffers for the segment draw**

From the segment count (+5) sets the loop limit `$AEEA`, the clip window and the vertex buffers at `$FD00`-`$FF07` and `$990F`. Called once per frame before DrawSegments.

Witness: L1 9794 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 26,656 t-states own (0.00 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop` |
| Calls | `DrawSegments` (falls into) |
| Reads | `$BC12`-`$BC1D` (`l_BBFB+23`); `$DBDC` (`MissionHeader+23`) |
| Writes | `$AEEA` (`DrawSegmentLoop+2`); `$B2A4`-`$B2A7` (`l_B2A3+1`, `l_B2A6`); `$B2CD`-`$B2D0` (`l_B2CC+1`, `l_B2CF`) |

### `DrawSegments` (`$AEE1`)

**Draw every visible segment as a quad**

Walks the segments whose flag in `$8305` is set: transforms both vertices (TransformVertex `$B242`), clips them by the orientation byte +2 (one axis `$AFDE`, the other `$B000`, the diagonals `$B021`, `$B0E4`, `$B16A`), and draws the quad by the style byte +5 (DrawSegmentStyle `$B1B6`).

Witness: L1 94909 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,190 calls, 127,130 t-states own (0.02 %) |
| Runs (the other recordings) | 36,513 calls (`stage1/death` 25,100, `stage1/play2` 4,130, `stage1/missions` 3,927 and 2 more) |
| Called from | `SetupClipWindow` (falls into), `DrawSegmentLoop` (tail) |
| Calls | `DrawSegmentLoop` (falls into) |
| Reads | `$8305`-`$831C` (`WorldWork`); `$AE92`-`$AE9F` (`SegmentScratch+16`); `$DC80`-`$DCDF` (`MissionHeader+187`) |
| Writes | `$830D` (`WorldWork+8`); `$AE85` (`SegmentScratch+3`); `$AE98`-`$AE9F` (`SegmentScratch+22`); `$AFC4` (`l_AF83+65`); `$B1BA` (`DrawSegmentStyle+4`); `$B2E5`-`$B2F8` (`StoreVertex+1`) |

### `DrawSegmentLoop` (`$AEE8`)

**The loop of DrawSegments, entered again by DrawSegmentTail**

One pass per segment: reads the next 6-byte record, skips it when its flag is 0.

Witness: L1 94909 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,190 calls, 32,744 t-states own (0.00 %) |
| Runs (the other recordings) | 36,513 calls (`stage1/death` 25,100, `stage1/play2` 4,130, `stage1/missions` 3,927 and 2 more) |
| Called from | `DrawSegments` (falls into), `DrawSegmentTail` (tail) |
| Calls | `TestVertexNear`, `TestVertexNearB`, `TestVertexNearY`, `DrawSegments` (tail), `ClipSegmentAxisX`, `ClipSegmentAxisY`, `TransformSegmentEnds` (tail), `DrawSegmentStyle` (tail), `ClipTestX`, `ClipTestY` |

### `ClipSegmentAxisX` (`$AFDE`)

**Clip an axis-aligned segment (orientation 0)**

The segment runs along one axis; its width is +3 (`$B2E5`), its height +4 (`$AFC4`). Seen only on the maps of missions 1 and 2 (missions, m2erbe).

Witness: L1 4566 (m2erbe, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 702 calls (`stage1/missions` 538, `stage1/m2erbe` 164) |
| Called from | `DrawSegmentLoop` |
| Calls | `StoreVertex` (tail), `RotateToView` |
| Reads | `$67A7`-`$67AB` (`WorldVars+4`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`) |

### `ClipSegmentAxisY` (`$B000`)

**Clip a segment along the other axis (orientation bit 7)**

As ClipSegmentAxisX `$AFDE` for the other axis.

Witness: L1 4608 (m2erbe, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 744 calls (`stage1/missions` 580, `stage1/m2erbe` 164) |
| Called from | `DrawSegmentLoop` |
| Calls | `ClipSegmentDiagonal`, `VertexByteToWorld` |
| Writes | `$AE86`-`$AE8B` (`SegmentScratch+4`) |

### `ClipSegmentDiagonal` (`$B021`)

**Clip a diagonal segment**

Orientation other than 0 / `$80`: the two vertices give the slope; calls ClipDiagonalSide `$B0E4` and `$B16A`.

Witness: L1 4608 (m2erbe, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 744 calls (`stage1/missions` 580, `stage1/m2erbe` 164) |
| Called from | `ClipSegmentAxisY` |
| Calls | `ClipDiagonalSide` (tail), `ClipDiagonalEnd`, `Negate24` |
| Reads | `$67A7`-`$67AD` (`WorldVars+4`); `$AE85`-`$AE92` (`SegmentScratch+3`) |
| Writes | `$AE8C`-`$AE97` (`SegmentScratch+10`) |

### `ClipDiagonalSide` (`$B0E4`)

**Clip one side of a diagonal segment**

Part of ClipSegmentDiagonal `$B021`.

Witness: L1 3647 (m2erbe, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 164 calls (`stage1/m2erbe` 164) |
| Called from | `ClipSegmentDiagonal` (tail) |
| Calls | `ClipDiagonalEnd` (tail) |
| Reads | `$67A7`-`$67AD` (`WorldVars+4`); `$AE85`-`$AE8F` (`SegmentScratch+3`) |
| Writes | `$AE92`-`$AE97` (`SegmentScratch+16`) |

### `ClipDiagonalEnd` (`$B16A`)

**Clip the far end of a diagonal segment**

Part of ClipSegmentDiagonal `$B021`.

Witness: L1 18411 (m2erbe, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2,955 calls (`stage1/missions` 2,299, `stage1/m2erbe` 656) |
| Called from | `ClipSegmentDiagonal`, `ClipDiagonalSide` (tail) |

### `DrawSegmentTail` (`$B18A`)

**Continue the segment loop from the saved pointer `$AE9E`**

LD HL,(`$AE9E`) then JP DrawSegmentLoop `$AEE8`.

Witness: L1 19364 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,033 calls (`stage1/missions` 869, `stage1/m2erbe` 164) |
| Called from | `DrawSegmentStyle` (tail) |
| Calls | `DrawSegmentLoop` (tail) |
| Reads | `$AE9E`-`$AE9F` (`SegmentScratch+28`) |

### `TransformSegmentEnds` (`$B190`)

**Transform both corners of a segment into the vertex buffer `$FD00`**

Points the store `$B2F1` / `$B2F7` at `$FD00` / `$FD06`, transforms the first corner (TransformVertex `$B242`), copies the height `$AFC4` to `$B2E5`, then the second corner into `$FD02` / `$FD04`.

Witness: L1 17081 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 69,515 t-states own (0.01 %) |
| Runs (the other recordings) | 6,277 calls (`stage1/death` 3,878, `stage1/play` 891, `stage1/play2` 826 and 2 more) |
| Called from | `DrawSegmentLoop` (tail) |
| Calls | `TransformVertex` |
| Reads | `$AE9E`-`$AE9F` (`SegmentScratch+28`); `$AFC4` (`l_AF83+65`) |
| Writes | `$B2E5`-`$B2F8` (`StoreVertex+1`) |

### `DrawSegmentStyle` (`$B1B6`)

**Draw a segment by its style byte (+5)**

ResetViewOrigin `$B3B6`, then the style (the operand at `$B1BA`): 0 draws with IX = `$FF8C`, negative with `$FF80`, 1 with `$FF98`, 2 through `$B22C`, 4 / 5 / 6 set the `$FE00` constants first. The same byte is the terrain type TerrainCollision `$CC3C` returns in `$CE69`.

Witness: L1 19364 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 351 calls (`stage1/missions` 269, `stage1/m2erbe` 82) |
| Called from | `DrawSegmentLoop` (tail) |
| Calls | `RunScript`, `DrawSegmentTail` (tail), `ResetViewOrigin` |
| Reads | `$67AD`-`$67AE` (`WorldVars+10`) |

### `TransformVertex` (`$B242`)

**Transform one map vertex to view space**

Input: the vertex index. Vertex minus camera (VertexRelative `$B265`), the rotation (`$B2FF`, `$B38E`), the stores through `$B2F1` / `$B2F7`.

Witness: L1 34162 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 476 calls, 86,666 t-states own (0.01 %) |
| Runs (the other recordings) | 12,554 calls (`stage1/death` 7,756, `stage1/play` 1,782, `stage1/play2` 1,652 and 2 more) |
| Called from | `TransformSegmentEnds` |
| Calls | `VertexRelative`, `StoreVertex` (tail), `RotateToView` |
| Reads | `$67A7`-`$67AB` (`WorldVars+4`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`) |

### `VertexRelative` (`$B265`)

**Vertex position minus the camera, 24-bit**

Byte * 1024 (ByteToWorld `$B282`) minus the camera X / Y `$67A8` / `$67AB`.

Witness: L1 68324 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 49,523 t-states own (0.01 %) |
| Runs (the other recordings) | 25,108 calls (`stage1/death` 15,512, `stage1/play` 3,564, `stage1/play2` 3,304 and 2 more) |
| Called from | `TransformVertex` |

### `Negate24` (`$B26F`)

**Negate a 24-bit value**

Seen only in missions (167 runs).

Witness: L1 960 (m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 167 calls (`stage1/missions` 167) |
| Called from | `ClipSegmentDiagonal` |
| Writes | `$B27C` (`Negate24+13`) |

### `VertexByteToWorld` (`$B27E`)

**A vertex byte to a 24-bit world coordinate (signed byte * 1024)**

Reads the vertex byte and falls into ByteToWorld `$B282`.

Witness: L1 9216 (m2erbe, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,488 calls (`stage1/missions` 1,160, `stage1/m2erbe` 328) |
| Called from | `ClipSegmentAxisY` |
| Calls | `ByteToWorld` (falls into) |
| Reads | `$DC00`-`$DC0C` (`MissionHeader+59`); `$DC40`-`$DC4C` (`MissionHeader+123`) |

### `ByteToWorld` (`$B282`)

**Signed byte to 24-bit: A * 1024 (vector `$67E2`)**

Input A, output the 24-bit value in A:HL. The mission code calls it through `$67E2` (the object list's X / Y words use the same scale).

Witness: L1 145759 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,932 calls, 142,457 t-states own (0.02 %) |
| Runs (the other recordings) | 35,297 calls (`stage1/death` 13,488, `stage1/play` 7,416, `stage1/missions` 6,801 and 2 more) |
| Called from | `ApiVector12` (tail), `VertexByteToWorld` (falls into) |

### `ClipTestX` (`$B294`)

**Clip test of a view-space point against the window on X**

Carry out: outside.

Witness: L1 27209 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 357 calls, 35,105 t-states own (0.01 %) |
| Runs (the other recordings) | 9,467 calls (`stage1/death` 5,817, `stage1/play` 1,332, `stage1/play2` 1,239 and 2 more) |
| Called from | `DrawSegmentLoop` |
| Reads | `$BC12` (`l_BBFB+23`); `$DC00`-`$DC17` (`MissionHeader+59`) |

### `ClipTestY` (`$B2BB`)

**Clip test of a view-space point on Y (depth)**

Carry out: outside.

Witness: L1 24034 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 357 calls, 37,623 t-states own (0.01 %) |
| Runs (the other recordings) | 9,364 calls (`stage1/death` 5,817, `stage1/play` 1,341, `stage1/play2` 1,239 and 2 more) |
| Called from | `DrawSegmentLoop` |
| Reads | `$BC1D` (`l_BBFB+34`); `$DC40`-`$DC56` (`MissionHeader+123`) |

### `StoreVertex` (`$B2E4`)

**Store a transformed vertex through `$B2F1` / `$B2F7`**

The height operand `$B2E5` (from the segment's +3) is the vertex's height.

Witness: L1 38728 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 476 calls, 55,020 t-states own (0.01 %) |
| Runs (the other recordings) | 13,256 calls (`stage1/death` 7,756, `stage1/play` 1,782, `stage1/missions` 1,738 and 2 more) |
| Called from | `ClipSegmentAxisX` (tail), `TransformVertex` (tail) |
| Calls | `RotateVertex` (falls into) |
| Reads | `$67A6`-`$67A7` (`WorldVars+3`); `$AE84` (`SegmentScratch+2`) |
| Writes | `$AE84` (`SegmentScratch+2`) |

### `RotateVertex` (`$B2FF`)

**Rotate a camera-relative vertex by the view angle**

Through the camera sin / cos `$9A6C` / `$9A8E`.

Witness: L1 77456 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 35,262 t-states own (0.01 %) |
| Runs (the other recordings) | 26,512 calls (`stage1/death` 15,512, `stage1/play` 3,564, `stage1/missions` 3,476 and 2 more) |
| Called from | `StoreVertex` (falls into) |
| Calls | `ApiVector14`, `SignExtendA`, `RotateAndStore` (tail), `RotateMulAdd` (tail) |
| Reads | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$B1BA` (`DrawSegmentStyle+4`) |

### `SignExtendA` (`$B386`)

**Sign-extend A into HL (H = 0 or `$FF`)**

Seen only in missions.

Witness: L1 40720 (m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3,624 calls (`stage1/missions` 3,624) |
| Called from | `RotateVertex` |

### `RotateAndStore` (`$B38E`)

**Rotate by the sin / cos of A and store the pair**

EX AF,AF', sin / cos through `$67E8`, multiply by `$9A8E` (RotateMul `$B3A6`), clears the target.

Witness: L1 57096 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 112,374 t-states own (0.02 %) |
| Runs (the other recordings) | 24,700 calls (`stage1/death` 15,512, `stage1/play` 3,564, `stage1/play2` 3,304 and 2 more) |
| Called from | `RotateVertex` (tail) |
| Calls | `ApiVector14`, `RotateMul` (falls into) |
| Reads | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`) |
| Writes | `$FE00`-`$FE07` (`MissionHeader+8763`) |

### `RotateMul` (`$B3A6`)

**One product of the rotation (BC * the sin or cos)**

Part of RotateAndStore.

Witness: L1 114192 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,904 calls, 148,588 t-states own (0.02 %) |
| Runs (the other recordings) | 49,400 calls (`stage1/death` 31,024, `stage1/play` 7,128, `stage1/play2` 6,608 and 2 more) |
| Called from | `RotateAndStore` (falls into) |
| Calls | `RotateMulAdd` (falls into) |
| Writes | `$FD00`-`$FD07` (`MissionHeader+8507`); `$FF00`-`$FF07` (`data_FEBB+69`) |

### `RotateMulAdd` (`$B3AD`)

**The second product, added to the first**

Part of RotateAndStore.

Witness: L1 154912 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 6,952 calls (`stage1/missions` 6,952) |
| Called from | `RotateVertex` (tail), `RotateMul` (falls into) |

### `ResetViewOrigin` (`$B3B6`)

**Reset the view origin before a segment is drawn**

Called by DrawSegmentStyle `$B1B6` once per drawn segment (6628 runs, as many as it).

Witness: L1 19364 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 24,731 t-states own (0.00 %) |
| Runs (the other recordings) | 6,628 calls (`stage1/death` 3,878, `stage1/play` 891, `stage1/missions` 869 and 2 more) |
| Called from | `DrawSegmentStyle` |
| Calls | `ApiVector07` |
| Reads | `$67AD`-`$67AE` (`WorldVars+10`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`) |

### `SetCamera` (`$B9F6`)

**Set the camera from the viewed object (the player, a missile, the Dragonfly)**

Copies +`$21`..+`$28` (table select, heading, X, Y) of the record at (`$B9F4`) to `$67A5`-`$67AC`, the height +5/+6 (or the IR height `$B8FF` when `$BA13` is set) to `$67AD`. The rear view (`$BA27` set) adds `$80` to the heading. Then CameraSinCos `$BA32`.

Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 41,463 t-states own (0.01 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `CameraSinCos` (tail) |
| Reads | `$67A5`-`$67A6` (`WorldVars+2`); `$75F5`-`$75F6` (`PlayerHeight`); `$7611`-`$7618` (`PlayerHandler+9`, `PlayerHeading`, `PlayerX`, `PlayerY`); `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AC1`-`$7AC8` (`PlayerY+1195`); `$B8FF`-`$B900` (`IrViewHeight+3`); 1 more ranges |
| Writes | `$67A5`-`$67AE` (`WorldVars+2`) |

### `CameraSinCos` (`$BA32`)

**The camera heading's sine and cosine**

Reads the camera heading `$67A6`, sin / cos through `$67E8` (`$A899`), stores the pair in the operands `$BBBD` / `$BBC8` of RotateToView.

Witness: L1 19674 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 17,612 t-states own (0.00 %) |
| Runs (the other recordings) | 7,100 calls (`stage1/death` 5,020, `stage1/play2` 826, `stage1/missions` 614 and 2 more) |
| Called from | `SetCamera` (tail), `CameraSinCosAgain` (tail) |
| Calls | `ApiVector07`, `SinCosHalf` |
| Writes | `$BBBD`-`$BBC8` (`RotateToView+1`) |

### `CameraSinCosAgain` (`$BA40`)

**CameraSinCos for the second pass**

CALL CameraSinCos for the second view pass.

Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 3,399 t-states own (0.00 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `CameraSinCos` (tail) |
| Reads | `$67A5`-`$67A6` (`WorldVars+2`) |

### `RearViewOff` (`$BA45`)

**Rear view off**

Clears `$BA27`, falls into ToggleRearView.

Witness: L1 5 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/play` 5) |
| Called from | `PlayKeys` (tail) |
| Calls | `ToggleRearView` (falls into) |
| Reads | `$BA27` (`l_BA1F+8`) |

### `ToggleRearView` (`$BA4A`)

**Rear view on or off: the flag `$BA27`, the text REAR:VIEW / :::**

Prints `$BA86` ("REAR:VIEW") or `$BA9F` (blank) with the attribute at `$5AD2`.

Witness: L1 36 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 69 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/missions` 16, `stage1/play` 9, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission`, `RearViewOff` (falls into) |
| Calls | `PrintString` (tail) |
| Reads | `$CEA8` (`ToggleBinoculars+1`) |
| Writes | `$5AD2` (screen); `$BA27` (`l_BA1F+8`) |

### `GroundDots` (`$BAAC`)

**Draw the ground-plane dot grid**

The grid moves with the camera: GridVectors `$BB54`, then PlotGroundDot `$BB75` for each dot, GridStep `$BBA6` between rows.

Witness: L1 9794 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 1,324,405 t-states own (0.20 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `PlayLoop`, `DragonflyViewLoop` |
| Calls | `NegHL`, `GridVectors`, `PlotGroundDot`, `GridStep`, `RotateToView` |
| Reads | `$67A7`-`$67AE` (`WorldVars+4`); `$BB0B`-`$BB0F` (`l_BB0A+1`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$BB0B`-`$BB0F` (`l_BB0A+1`); `$BB24`-`$BB4D` (`l_BB23+1`, `l_BB3E`); `$BB8B`-`$BB8C` (`PlotGroundDot+22`) |

### `GridVectors` (`$BB54`)

**The grid's step vectors for the camera heading**

The camera's sin / cos scaled to the grid spacing: the steps along a row and between rows.

Witness: L1 39176 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 476 calls, 77,668 t-states own (0.01 %) |
| Runs (the other recordings) | 14,028 calls (`stage1/death` 10,040, `stage1/play2` 1,652, `stage1/missions` 1,092 and 2 more) |
| Called from | `GroundDots` |
| Calls | `ApiVector14` |
| Reads | `$67A6` (`WorldVars+3`) |

### `PlotGroundDot` (`$BB75`)

**Project one ground dot and plot it**

Rotates the dot to view space, divides by depth, plots through `$AA27` when on screen (117 517 runs).

Witness: L1 324616 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,638 calls, 567,501 t-states own (0.09 %) |
| Runs (the other recordings) | 117,517 calls (`stage1/death` 80,729, `stage1/play2` 16,501, `stage1/play` 10,267 and 2 more) |
| Called from | `GroundDots` |
| Calls | `Divide`, `DivideByLog`, `NegHL`, `PlotBackBuffer` (tail) |
| Reads | `$9AA3`-`$9AA4` (`l_9A9E+5`); `$9ABB`-`$9ABC` (`l_9A9E+29`) |
| Writes | `$BBA2` (`PlotGroundDot+45`) |

### `GridStep` (`$BBA6`)

**Step to the next grid row**

Adds the row vector to the grid origin.

Witness: L1 19588 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 39,508 t-states own (0.01 %) |
| Runs (the other recordings) | 7,014 calls (`stage1/death` 5,020, `stage1/play2` 826, `stage1/missions` 546 and 2 more) |
| Called from | `GroundDots` |
| Reads | `$BB0B`-`$BB0F` (`l_BB0A+1`) |
| Writes | `$BB0B`-`$BB0F` (`l_BB0A+1`) |

### `RotateToView` (`$BBBC`)

**Rotate dx, dy by the camera (sin `$BBBD`, cos `$BBC8`)**

Outputs the depth offset in `$9A6C` and the x offset in `$9A8E` (OpProject adds `$9A6C` to z and compares with 96).

Witness: L1 154474 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,272 calls, 675,050 t-states own (0.10 %) |
| Runs (the other recordings) | 50,296 calls (`stage1/death` 29,081, `stage1/play2` 8,569, `stage1/play` 6,541 and 2 more) |
| Called from | `ClipSegmentAxisX`, `TransformVertex`, `GroundDots`, `TransformObjects` |
| Calls | `ApiVector09`, `NegHL` |
| Reads | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$BBBD`-`$BBC8` (`RotateToView+1`) |
| Writes | `$BBDA`-`$BBDB` (`RotateToView+30`) |

### `TerrainCollision` (`$CC3C`)

**Does the object touch a visible segment; the style to `$CE69` (vector `$67F1`)**

Input IX = the object. Scans the segments flagged in `$8305` (TerrainScan `$CC4D`), tests the object's position against each one's box or diagonal (TerrainDiagonal `$CDB6`). Output carry set on a touch, the style +5 of the segment in `$CE69`. The mission code uses it through `$67F1` for the enemies.

Witness: L1 20647 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 381 calls, 850,642 t-states own (0.13 %) |
| Runs (the other recordings) | 5,854 calls (`stage1/death` 2,846, `stage1/play2` 1,264, `stage1/play` 842 and 2 more) |
| Called from | `ApiVector17` (tail) |
| Calls | `TerrainScan` (falls into) |
| Reads | `$75F7`-`$7600` (`PlayerSpeed`); `$7613`-`$7618` (`PlayerX`, `PlayerY`); `$76AB` (`PlayerY+149`); `$775F`-`$77A4` (`PlayerY+329`); `$77B7`-`$77BC` (`PlayerY+417`); `$77D7`-`$77E0` (`PlayerY+449`); 16 more ranges |
| Writes | `$CCB2`-`$CCB9` (`l_CC98+26`); `$CCDF` (`l_CCD8+7`); `$CCFF` (`l_CCEB+20`); `$CD37`-`$CD3A` (`l_CD30+7`); `$CD4E`-`$CD72` (`l_CD30+30`, `l_CD5C`); `$CD86`-`$CD98` (`l_CD5C+42`, `l_CD94`); 1 more ranges |

### `TerrainScan` (`$CC4D`)

**The scan over the visible segments**

Sets the segment pointer and the count.

Witness: L1 208483 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12,396 calls (`stage1/missions` 9,920, `stage1/m2erbe` 2,476) |
| Called from | `TerrainCollision` (falls into), `TerrainScanLoop` (tail) |
| Calls | `TerrainScanLoop` (falls into) |
| Reads | `$75FB`-`$7600` (`PlayerSpeed+4`); `$7613`-`$7618` (`PlayerX`, `PlayerY`); `$76AF`-`$76B0` (`PlayerY+153`); `$76C7`-`$76C9` (`PlayerY+177`); `$7763`-`$77F8` (`PlayerY+333`); `$7817`-`$781C` (`PlayerY+513`); 13 more ranges |
| Writes | `$CCB2`-`$CCB9` (`l_CC98+26`); `$CCDF` (`l_CCD8+7`); `$CCFF` (`l_CCEB+20`); `$CD37`-`$CD3A` (`l_CD30+7`); `$CD4E`-`$CD72` (`l_CD30+30`, `l_CD5C`); `$CD86`-`$CD98` (`l_CD5C+42`, `l_CD94`); 1 more ranges |

### `TerrainScanLoop` (`$CC51`)

**The scan loop**

One segment per pass (62 693 runs).

Witness: L1 207509 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12,310 calls (`stage1/missions` 9,844, `stage1/m2erbe` 2,466) |
| Called from | `TerrainScan` (falls into), `TerrainNext` (tail) |
| Calls | `ApiVector12`, `TerrainScan` (tail), `TerrainNext` (tail), `TerrainNegate24`, `TerrainDiagonal` (tail) |

### `TerrainNext` (`$CDA2`)

**Continue with the next segment**

Steps to the next record.

Witness: L1 48694 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2,837 calls (`stage1/missions` 2,127, `stage1/m2erbe` 710) |
| Called from | `TerrainScanLoop` (tail), `TerrainDiagonal` (tail) |
| Calls | `TerrainScanLoop` (tail) |

### `TerrainNegate24` (`$CDA6`)

**Negate a 24-bit difference**

Negates the 24-bit value in A:HL.

Witness: L1 62388 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 749 calls, 55,426 t-states own (0.01 %) |
| Runs (the other recordings) | 14,955 calls (`stage1/death` 6,721, `stage1/play` 3,256, `stage1/play2` 2,765 and 2 more) |
| Called from | `TerrainScanLoop`, `TerrainDiagonal` |

### `TerrainDiagonal` (`$CDB6`)

**Distance to a diagonal segment**

The perpendicular distance for orientation other than 0 / `$80` (missions, m2erbe).

Witness: L1 5964 (m2erbe, m4complete, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 908 calls (`stage1/missions` 474, `stage1/m2erbe` 434) |
| Called from | `TerrainScanLoop` (tail) |
| Calls | `ApiVector08`, `ApiVector12`, `TerrainNext` (tail), `TerrainNegate24` |
| Reads | `$7613`-`$7618` (`PlayerX`, `PlayerY`); `$76C7`-`$76CC` (`PlayerY+177`); `$77B7`-`$77F8` (`PlayerY+417`); `$782F`-`$7834` (`PlayerY+537`); `$786B`-`$7870` (`PlayerY+597`); `$78A7`-`$78AC` (`PlayerY+657`); 4 more ranges |
| Writes | `$CE4F` (`l_CE4E+1`) |

### `BinocularsOff` (`$CEA4`)

**Binoculars off (called from `$74E0`)**

`XOR A` / `JR $CEAB`. `$74E0` calls it with bank 0 paged.

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ToggleBinoculars` (`$CEA7`)

**Binoculars on or off**

`LD A,n` whose n (`$CEA8`) is the flag, `XOR $FF`, falls into SetNightSight (8 runs in play).

Witness: L1 8 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/play` 8) |
| Called from | `PlayKeys` (tail) |
| Calls | `SetBinoculars` (falls into) |

### `SetBinoculars` (`$CEAB`)

**Apply the binoculars flag: the zoom `$9A93`, the lamp, the key repeat, the text**

On: `$CEA8` = A, the zoom `$9A93` = 1, the lamp attribute `$5ACC` = `$42`, key repeat `$9719` = `$20`, prints "BINOC:X2" `$BA93`. Off: `$9A93` = 0, `$5ACC` = `$44`, `$9719` = 4, the blank `$BA9F`. The rear view (`$BA27`) blocks both.

Witness: L1 39 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 119 t-states own (0.00 %) |
| Runs (the other recordings) | 34 calls (`stage1/missions` 16, `stage1/play` 12, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission`, `ToggleBinoculars` (falls into) |
| Calls | `PrintString` (tail) |
| Reads | `$BA27` (`l_BA1F+8`) |
| Writes | `$5ACC` (screen); `$9719` (`StepFrames`); `$9A93` (`l_9A85+14`); `$CEA8` (`ToggleBinoculars+1`) |

### `CycleBinocularZoom` (`$CEE5`)

**Step the binocular zoom 1-3 (x2, x4, x8)**

When the binoculars are on: `$CED4` + 1, wrapping 4 to 1, to the zoom `$9A93`; falls into ShowSightZoom (play: 6 runs).

Witness: L1 6 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 6 calls (`stage1/play` 6) |
| Called from | `PlayKeys` (tail) |
| Reads | `$CEA8` (`ToggleBinoculars+1`) |

### `ShowBinocularZoom` (`$CEF7`)

**Draw the zoom icon (`$D8B4` + 32 * n) and BINOC:X2 / X4 / X8**

Stores the zoom in `$CED4`, draws the 32-byte icon `$D8B4` + 32 * n through `$6D7F`, puts "0" + 2^n in `$BA9D` and prints `$BA93`. Called from `$6A01`.

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## enemies

`src/game/enemies.asm`

### `KillTree` (`$B612`)

**The hit handler of the trees (types 0, 1) and some scenery: any collider kills it**

HitPoints `$B6B1` with no weapon test, so any collider, the tank included (damage 0 against a tree's 0 hit points), knocks it down; on a kill unregisters the collision (`$67CD`), makes debris (`$67DF`) and joins `$B677` (+2 = 0, then AddKillScore), bypassing KillMissionObject, so the list record is not marked destroyed. Users: types 0 and 1 in all ten missions, mission 5 types 23-25, mission 6 types 27-29, mission 10 types 23-25, 30, 31, and the aircraft missiles at the end of their life (`$E632`) (docs/07-objects.md 7.5, 7.14).

Witness: L1 2 (armour, death).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/death` 1) |
| Called from | `CollisionPass` |
| Calls | `ApiVector05`, `ApiVector11`, `HitPoints` |
| Writes | `$793A` (`PlayerY+804`) |

### `KillSwitchObject` (`$B61E`)

**A collision handler no recording runs: hit, then switch a segment off**

HitTest through `$67DC`; on a kill, when the header's first switch object `$DBDD` is not 0: c = the list index (+0) - (`$DBDD`), two segment numbers from the table at (`$DBDF`) + c, each minus the first switchable segment (`$DBDE`), and the two switch flags at `$7BFD` + n cleared, so the bridge or post it guards vanishes from the map. Users: mission 5 type 29, mission 8 types 8 and 9 (the templates' hit handler word).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BridgeHit` (`$B64E`)

**The bridge's hit handler (mission 2 type 3): hit, then TANK DESTROYED ON BRIDGE if the tank touches a type 4 object**

HitTest `$B660`; no kill returns. On a kill, when PlayerStep's JR operand `$A8C8` is not 0 (HitObstacle `$CB6C` sets it to `$25` when the tank touches a type 4 object in the pass; PlayLoop clears it at `$6A37`), HL = `$CD01` ("TANK DESTROYED ON BRIDGE") and `JP $CB46`, the failure path of PlayerHit (docs/10-gameplay-logic.md 10.10).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HitTest` (`$B660`)

**Damage IX by IY's damage; on a kill score and remove (vector `$67DC`)**

Input IX = the hit object, IY = the hitter. HitPoints `$B6B1` (+`$13` -= the hitter's +`$14`); no kill returns NC. On a kill: UnregisterCollision `$CA3B`, Debris `$B6D1`; an object from the mission list (+0 != `$FF`) goes to KillMissionObject `$B67D`, the others are freed at `$B677`. Then AddKillScore `$B692`.

Witness: L1 1132 (armour, death, m1complete, m4complete, missions, play2).

[Animation: `HitTest` at work](img/routines/HitTest.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 153 calls (`stage1/missions` 146, `stage1/death` 6, `stage1/play2` 1) |
| Called from | `ApiVector10` (tail) |
| Calls | `ApiVector05`, `ApiVector11`, `KillMissionObject` (tail), `AddKillScore` (tail), `HitPoints` |
| Reads | `$766B` (`PlayerY+85`); `$76A4`-`$76A7` (`PlayerY+142`); `$76E3` (`PlayerY+205`); `$771C` (`PlayerY+262`); `$7797` (`PlayerY+385`); `$77D0` (`PlayerY+442`); 3 more ranges |

### `KillMissionObject` (`$B67D`)

**A killed mission object: mark it in the list, leave the wreck**

MarkDestroyed `$B6BD`, sets the wreck bit 6 of +2 (the wreck model +8/+9 is drawn), clears the step handler bit.

Witness: L1 9 (death, m1complete, m4complete).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/death` 4) |
| Called from | `HitTest` (tail) |
| Calls | `ApiVector13`, `AddKillScore` (falls into) |
| Reads | `$76A6`-`$76A7` (`PlayerY+144`); `$771E`-`$771F` (`PlayerY+264`); `$77D2`-`$77D3` (`PlayerY+444`); `$78C2`-`$78C3` (`PlayerY+684`) |
| Writes | `$76A6`-`$76A7` (`PlayerY+144`); `$771E`-`$771F` (`PlayerY+264`); `$77D2`-`$77D3` (`PlayerY+444`); `$78C2`-`$78C3` (`PlayerY+684`) |

### `AddKillScore` (`$B692`)

**Add the object's score (+`$1E`/+`$1F`) to the 32-bit score `$68E2`**

Adds the word to `$68E2`-`$68E5` and calls the kill sound `$D873`. Death: the score goes 0, `$FA`, `$1F4` (two kills of a 250-point type).

Witness: L1 12 (armour, death, m1complete, m4complete).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/death` 5) |
| Called from | `HitTest` (tail), `KillMissionObject` (falls into) |
| Calls | `SoundKill` |
| Reads | `$68E2`-`$68E5` (`MissionScore`); `$76C2`-`$76C3` (`PlayerY+172`); `$773A`-`$773B` (`PlayerY+292`); `$77EE`-`$77EF` (`PlayerY+472`); `$78DE`-`$78DF` (`PlayerY+712`); `$7956`-`$7957` (`PlayerY+832`) |
| Writes | `$68E2`-`$68E5` (`MissionScore`) |

### `HitPoints` (`$B6B1`)

**Subtract the hitter's damage from the hit points; carry = killed**

+`$13` of IX -= +`$14` of IY.

Witness: L1 23 (armour, death, m1complete, m4complete).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7 calls (`stage1/death` 7) |
| Called from | `KillTree`, `HitTest` |
| Reads | `$767C` (`PlayerY+102`); `$76B7`-`$76B8` (`PlayerY+161`); `$76F4` (`PlayerY+222`); `$772F` (`PlayerY+281`); `$77A8` (`PlayerY+402`); `$77E3` (`PlayerY+461`); 4 more ranges |
| Writes | `$76B7` (`PlayerY+161`); `$772F` (`PlayerY+281`); `$77E3` (`PlayerY+461`); `$78D3` (`PlayerY+701`); `$794B` (`PlayerY+821`) |

### `MarkDestroyed` (`$B6BD`)

**Mark a mission object destroyed in the list (vector `$67E5`)**

Record (`$DBDA`) + 8 * (+0): sets bit 1 (destroyed), clears bit 7 (alive), so it is never spawned again. The goal hooks read this bit.

Witness: L1 9 (death, m1complete, m4complete).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/death` 4) |
| Called from | `ApiVector13` (tail) |
| Reads | `$76A4` (`PlayerY+142`); `$771C` (`PlayerY+262`); `$77D0` (`PlayerY+442`); `$78C0` (`PlayerY+682`); `$DBDA`-`$DBDB` (`MissionHeader+21`); `$DD8C`-`$DDA4` (`MissionHeader+455`) |
| Writes | `$DD8C`-`$DDA4` (`MissionHeader+455`) |

### `Debris` (`$B6D1`)

**Throw 8 debris particles from the object (vector `$67DF`)**

Fills the bank 3 particle list at `$CFEC` (8 records of 20 bytes): the object's position, random velocities (DebrisVelocity `$B74B` / `$B75C`).

Witness: L1 36 (armour, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/death` 12, `stage1/play2` 1) |
| Called from | `ApiVector11` (tail) |
| Calls | `ApiVector06`, `PageBank3`, `SaveBank`, `RestoreBank` (tail), `DebrisVelocity`, `DebrisVelocityB` |
| Reads | `$766A`-`$76E2` (`PlayerY+84`); `$771E`-`$7726` (`PlayerY+264`); `$7796` (`PlayerY+384`); `$77D2` (`PlayerY+444`); `$7886`-`$788E` (`PlayerY+624`); `$78A7`-`$78AC` (`PlayerY+657`); 5 more ranges |

### `DebrisVelocity` (`$B74B`)

**A random velocity component for a particle**

Random through `$67D0`.

Witness: L1 196 (armour, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 64 calls (`stage1/death` 48, `stage1/play2` 16) |
| Called from | `Debris` |
| Calls | `ApiVector06` |

### `DebrisVelocityB` (`$B75C`)

**The second component (shares the code)**

The entry DebrisVelocity's second call uses for the other axis.

Witness: L1 196 (armour, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 64 calls (`stage1/death` 48, `stage1/play2` 16) |
| Called from | `Debris` |
| Calls | `ApiVector06` |

## sound

`src/game/sound.asm`

### `SoundFrame` (`$D692`)

**The sound step of a frame (the interrupt)**

Gated by `$D691` (1 in the image and never written: the test always passes) and `$D689`. EngineTone `$D8A1` from |`$75F7`|, then each effect counter `$D682`-`$D68B` counts down and sets its registers in the shadow `$D674`-`$D681`, then WriteAY `$D7DC` (B = `$FF` select port `$FFFD` at `$D7E4`, data port `$BFFD` at `$D7EB`). Called by the interrupt's `$7E6E` in every recording.

Witness frames (first-last frame of the recording, runs): c1 24005-33298 (4124), controls 0-330 (242), death 0-20038 (12655), m10 0-9028 (6434), m2erbe 0-7808 (3094), m2ocean 0-4799 (2244), menu 0-10996 (7559), missions 0-35997 (12811), play 0-10930 (5510), play2 0-23665 (12957), search 0-5043 (2265).

Witness: L1 121656 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 1,553,494 t-states own (0.23 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `SoundTick` |
| Calls | `SetNoise`, `EngineTone` |
| Reads | `$D674`-`$D691` (`AYRegs`, `SelectCount`, `ExplosionCount`, `KillCount` and 11 more) |
| Writes | `$D676`-`$D68B` (`AYRegs+2`, `SelectCount`, `ExplosionCount`, `KillCount` and 7 more); `$D7F0` (`l_D7E2+14`) |
| Ports out | `$BFFD`, `$FFFD` |

### `SetNoise` (`$D7F4`)

**Set the noise period and the volume of channel C, noise C on**

C as the noise period (`$D67A`; both callers pass C = A), A >> 1 as the volume of channel C (`$D67E`), the mixer's bit 5 cleared (noise C on); returns without a write when A >> 1 is not above NoisePriority `$D688` (death, play2).

Witness frames (first-last frame of the recording, runs): c1 32619-33091 (107), death 8122-18058 (896), play2 8608-17213 (553).

Witness: L1 3337 (armour, c1, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 107 calls, 9,739 t-states own (0.00 %) |
| Runs (the other recordings) | 1,449 calls (`stage1/death` 896, `stage1/play2` 553) |
| Called from | `SoundFrame` |
| Reads | `$D67B`-`$D688` (`AYRegs+7`, `SelectCount`, `ExplosionCount`, `KillCount` and 4 more) |
| Writes | `$D67A`-`$D67E` (`AYRegs+6`) |

### `SilenceAY` (`$D807`)

**Silence the AY**

Zeroes the 21 bytes from `$D674`, mixer `$3F` (all off), writes the 14 registers.

Witness frames (first-last frame of the recording, runs): c1 23974-24603 (2), controls 95-264 (2), m2erbe 7454-7522 (2), menu 95-1874 (4), missions 7955-34068 (16), play 10627-10693 (2), play2 9615-23533 (6).

Witness: L1 39 (armour, c1, controls, fuel, m1complete, m2erbe, m4complete, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 3,962 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/missions` 16, `stage1/play2` 6, `stage1/menu` 4 and 2 more) |
| Called from | `Bank0SoundOff`, `QuitKey` |
| Writes | `$D674`-`$D689` (`AYRegs`, `SelectCount`, `ExplosionCount`, `KillCount` and 5 more); `$D7F0` (`l_D7E2+14`) |
| Ports out | `$BFFD`, `$FFFD` |

### `SoundSweep` (`$D839`)

**Effect trigger: the sweep counter `$D68D` = `$1F`**

`PUSH AF` / `LD A,$1F` / `LD ($D68D),A` / `POP AF` / `RET`. SoundFrame then sweeps tone B down in pitch (doc 09).

Its one caller is SlamFire `$D11C` (`JP` at `$D19D`), when the SLAM laser shoots a shell. Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundNoise11` (`$D841`)

**Effect trigger: the steady noise counter `$D68C` = `$11`**

`PUSH AF` / `LD A,$11` / `JR` 3 bytes into SoundNoise23's store.

Known only from the code: no caller.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundNoise23` (`$D846`)

**Effect trigger: the steady noise counter `$D68C` = `$23`**

Known only from the code: no caller.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundEffectA` (`$D84E`)

**Effect trigger `$D68B`**

`$D68B` = `$1E` (play2: 21 runs).

Witness frames (first-last frame of the recording, runs): c1 32680-33293 (15), play2 8700-17195 (21).

Witness: L1 61 (c1, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 15 calls, 765 t-states own (0.00 %) |
| Runs (the other recordings) | 21 calls (`stage1/play2` 21) |
| Called from | `MessageOnce` |
| Writes | `$D68B` (`MessageSoundCount`) |

### `SoundRandomTone` (`$D856`)

**Effect trigger: the random tone flag `$D68A` = 1**

Known only from the code: no caller.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundSelectShort` (`$D85E`)

**Effect trigger: SelectCount `$D682` = 1**

`LD A,1` then `JR` into SoundSelect's store.

Known only from the code: no caller.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundSelect` (`$D863`)

**Weapon select sound**

`$D682` = `$12`: the weapon select.

Witness frames (first-last frame of the recording, runs): death 7705 (1), play 8425-9322 (4), play2 8362-23071 (9).

Witness: L1 17 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/play2` 9, `stage1/play` 4, `stage1/death` 1) |
| Called from | `SelectWeapon` |
| Writes | `$D682` (`SelectCount`) |

### `SoundExplosion` (`$D86B`)

**Explosion sound**

`$D683` = `$20`: an explosion.

Witness frames (first-last frame of the recording, runs): c1 32618-33054 (5), death 8121-17902 (8), play2 8607-17180 (19).

Witness: L1 63 (armour, c1, death, m1complete, m4complete, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 255 t-states own (0.00 %) |
| Runs (the other recordings) | 27 calls (`stage1/play2` 19, `stage1/death` 8) |
| Called from | `MessageOnce`, `Explode` |
| Writes | `$D683` (`ExplosionCount`) |

### `SoundKill` (`$D873`)

**Kill sound**

`$D684`: a kill (death: 5 runs).

Witness frames (first-last frame of the recording, runs): death 8187-17902 (5).

Witness: L1 12 (armour, death, m1complete, m4complete).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/death` 5) |
| Called from | `AddKillScore` |
| Writes | `$D684` (`KillCount`) |

### `SoundToneC8` (`$D87B`)

**Effect trigger: ToneC8Count `$D685` = 7**

Known only from the code: no caller.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundMissile` (`$D883`)

**Missile sound trigger**

`$D687` = `$1E`; JP from `$C450` (the missile).

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundSiren60` (`$D88B`)

**Effect trigger: the siren counter `$D68E`, meant to be `$60`**

Bug: `JR $D891` (`18 01`) lands on `LD A,$40`, so this entry stores `$40` too, never `$60`.

Known only from the code: no caller.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundSiren40` (`$D890`)

**Effect trigger: the siren counter `$D68E` = `$40`**

Known only from the code: no caller.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundFire` (`$D898`)

**Fire sound**

`$D686` = `$14`: a shot.

Witness frames (first-last frame of the recording, runs): death 7897-19694 (60), play 8800-9406 (4), play2 8442-16931 (6).

Witness: L1 147 (armour, death, m1complete, m4complete, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 70 calls (`stage1/death` 60, `stage1/play2` 6, `stage1/play` 4) |
| Called from | `ConsumeAmmo` |
| Writes | `$D686` (`FireSoundCount`) |

### `EngineTone` (`$D8A1`)

**Engine tone from the speed**

|speed| through `$67D6` gives the tone period of channel A in the shadow (17 682 runs).

Witness frames (first-last frame of the recording, runs): c1 32219-33298 (982), death 7592-20038 (10012), m2erbe 7090-7522 (281), missions 7592-34068 (2195), play 8253-10693 (2004), play2 8184-23533 (3190).

Witness: L1 56368 (armour, c1, death, fuel, m1complete, m2erbe, m4complete, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 982 calls, 227,299 t-states own (0.03 %) |
| Runs (the other recordings) | 17,682 calls (`stage1/death` 10,012, `stage1/play2` 3,190, `stage1/missions` 2,195 and 2 more) |
| Called from | `SoundFrame` |
| Calls | `ApiVector08` |
| Reads | `$75F7` (`PlayerSpeed`); `$D67B`-`$D67F` (`AYRegs+7`) |
| Writes | `$D674`-`$D681` (`AYRegs`); `$D7F0` (`l_D7E2+14`) |


## Bank 3 (`src/bank3/bank3.json`)

Battle Command, Ocean 1990: RAM bank 3, paged at `$C000`, as its tape block loads it. Its entries are
`src/bank3/<module>.asm`, written from `src/bank3/bank3.ann` by `kit/mkgame.py --part src/bank3/bank3.json`; the
recordings: `work/stage1/c1g` (c1 from the game's entry at frame 23974, the loader left out: the title, the mission
tape, Blast Em Mission played), and `work/stage1/menu`, `work/stage1/missions`, `work/stage1/play`,
`work/stage1/play2`, `work/stage1/death`, `work/stage1/m2ocean`, `work/stage1/m2erbe`, `work/stage1/search`,
`work/stage1/m10`, `work/stage1/c1`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`raster3`](#bank-3-raster3) | `$C000`-`$CFEB` | 25 of 28 |
| [`debris`](#bank-3-debris) | `$CFEC`-`$D3FF` | 6 of 8 |

### Bank 3: raster3

`src/bank3/raster3.asm`

#### `ClipPolyY` (`$C000`)

**Clip the polygon PolyVerts `$6700` (count `$68A9`) to rows 0..95 into PolyYClipped `$66A8`**

Sutherland-Hodgman by states: the last vertex inside (`$C17B`), below row 95 (`$C02F`) or above row 0 (`$C0DE`); the crossings by IntersectRow95 `$C40A` and IntersectRow0 `$C420`. Then the X clip `$C218`. Returns Z when nothing is left.

Witness: L1 38525 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,908 calls, 786,456 t-states own (0.12 %) |
| Runs (the other recordings) | 38,525 calls (`stage1/death` 11,168, `stage1/play2` 8,321, `stage1/missions` 8,193 and 7 more) |
| Called from | `FillPolygon` |
| Calls | `ClipYBelow` (falls into), `ClipYAbove` (tail), `ClipYInside` (tail) |
| Reads | `$6708`-`$671F` (`PolyVerts+8`); `$68A9` (`PanelGauges+1`) |

#### `ClipYBelow` (`$C02F`)

**Y clip state: the previous vertex below the window**

Witness: L1 3183 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 132 calls, 90,478 t-states own (0.01 %) |
| Runs (the other recordings) | 1,643 calls (`stage1/death` 799, `stage1/missions` 332, `stage1/play` 220 and 4 more) |
| Called from | `ClipPolyY` (falls into), `ClipYInside` (tail) |
| Calls | `ClipYInside` (tail), `ClipPolyX` (tail), `IntersectRow95` |
| Reads | `$6700`-`$6717` (`PolyVerts`) |
| Writes | `$66A8`-`$66B6` (`PolyYClipped`) |

#### `ClipYAbove` (`$C0DE`)

**Y clip state: the previous vertex above the window**

Witness: L1 1682 (c1, death, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 1,627 t-states own (0.00 %) |
| Runs (the other recordings) | 1,682 calls (`stage1/play2` 702, `stage1/death` 676, `stage1/play` 290 and 3 more) |
| Called from | `ClipPolyY` (tail), `ClipYAboveSkip` (tail), `ClipYInside` (tail) |
| Calls | `ClipYAboveSkip` (tail), `ClipYInside` (tail), `ClipPolyX` (tail), `IntersectRow0` |
| Reads | `$6700`-`$670F` (`PolyVerts`) |
| Writes | `$66A8`-`$66B3` (`PolyYClipped`) |

#### `ClipYAboveSkip` (`$C162`)

**Y clip: still above, skip the vertex**

Witness: L1 1530 (c1, death, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 137 t-states own (0.00 %) |
| Runs (the other recordings) | 1,530 calls (`stage1/play2` 688, `stage1/death` 547, `stage1/play` 289 and 3 more) |
| Called from | `ClipYAbove` (tail) |
| Calls | `ClipYAbove` (tail), `ClipPolyX` (tail) |
| Reads | `$6700`-`$670E` (`PolyVerts`) |

#### `ClipYInside` (`$C17B`)

**Y clip state: the previous vertex inside, output it**

Witness: L1 143574 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,910 calls, 4,326,536 t-states own (0.65 %) |
| Runs (the other recordings) | 38,107 calls (`stage1/death` 11,016, `stage1/missions` 8,200, `stage1/play2` 8,120 and 7 more) |
| Called from | `ClipPolyY` (tail), `ClipYBelow` (tail), `ClipYAbove` (tail) |
| Calls | `ClipYBelow` (tail), `ClipYAbove` (tail), `ClipPolyX` (falls into), `IntersectRow95`, `IntersectRow0` |
| Reads | `$66AE`-`$66B9` (`PolyYClipped+6`); `$6700`-`$671F` (`PolyVerts`) |
| Writes | `$66A8`-`$66BF` (`PolyYClipped`) |

#### `ClipPolyX` (`$C218`)

**Clip the Y-clipped list to columns 0..255 (the limit patched by SetClipWidth `$CFCD`) into PolyXClipped `$6680`**

States `$C245` (previous right of the window), `$C2E6` (left), `$C378` (inside); crossings by IntersectColRight `$C478`, IntersectCol0 `$C48E`; the count to `$68A9`.

Witness: L1 38524 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,908 calls, 4,384,410 t-states own (0.66 %) |
| Runs (the other recordings) | 38,068 calls (`stage1/death` 11,168, `stage1/play2` 8,320, `stage1/missions` 8,193 and 4 more) |
| Called from | `ClipYBelow` (tail), `ClipYAbove` (tail), `ClipYAboveSkip` (tail), `ClipYInside` (falls into) |
| Calls | `ClipXRight` (falls into), `ClipXLeft` (tail), `ClipXInside` (tail) |
| Reads | `$66A8`-`$66BF` (`PolyYClipped`) |
| Writes | `$6680`-`$668F` (`PolyXClipped`); `$68A9` (`PanelGauges+1`) |

#### `ClipXRight` (`$C245`)

**X clip state: the previous vertex right of the window**

Witness: L1 11998 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 94 calls (`stage1/m2erbe` 94) |
| Called from | `ClipPolyX` (falls into), `ClipXInside` (tail) |
| Calls | `ClipXInside` (tail), `IntersectColRight`, `IntersectCol0` |
| Reads | `$66A8`-`$66B3` (`PolyYClipped`) |
| Writes | `$6680`-`$6685` (`PolyXClipped`); `$68A9` (`PanelGauges+1`) |

#### `ClipXLeft` (`$C2E6`)

**X clip state: the previous vertex left of the window**

Witness: L1 13550 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 41 calls (`stage1/m2erbe` 41) |
| Called from | `ClipPolyX` (tail) |
| Calls | `ClipXInside` (tail), `IntersectColRight`, `IntersectCol0` |
| Reads | `$66A8`-`$66B3` (`PolyYClipped`) |
| Writes | `$6680`-`$6681` (`PolyXClipped`); `$68A9` (`PanelGauges+1`) |

#### `ClipXInside` (`$C378`)

**X clip state: the previous vertex inside**

Witness: L1 121481 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4,117 calls (`stage1/menu` 2,787, `stage1/m2erbe` 874, `stage1/m10` 152 and 2 more) |
| Called from | `ClipPolyX` (tail), `ClipXRight` (tail), `ClipXLeft` (tail) |
| Calls | `ClipXRight` (tail), `IntersectColRight`, `IntersectCol0` |
| Reads | `$66A8`-`$66B9` (`PolyYClipped`) |
| Writes | `$6680`-`$668B` (`PolyXClipped`); `$68A9` (`PanelGauges+1`) |

#### `IntersectRow95` (`$C40A`)

**The x where the edge crosses row 95 (exact when an end is on it)**

Witness: L1 3152 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 258 calls, 30,231 t-states own (0.00 %) |
| Runs (the other recordings) | 3,152 calls (`stage1/death` 1,506, `stage1/missions` 648, `stage1/play` 428 and 4 more) |
| Called from | `ClipYBelow`, `ClipYInside` |
| Calls | `IntersectRow0` (falls into) |

#### `IntersectRow0` (`$C420`)

**The x where the edge crosses row 0, by bisection**

Witness: L1 15203 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 260 calls, 190,554 t-states own (0.03 %) |
| Runs (the other recordings) | 3,285 calls (`stage1/death` 1,761, `stage1/missions` 656, `stage1/play` 430 and 3 more) |
| Called from | `ClipYAbove`, `ClipYInside`, `IntersectRow95` (falls into) |

#### `IntersectColRight` (`$C478`)

**The y where the edge crosses the right column (255)**

Witness: L1 5322 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 262 calls, 30,592 t-states own (0.00 %) |
| Runs (the other recordings) | 5,322 calls (`stage1/death` 1,962, `stage1/missions` 1,284, `stage1/play2` 968 and 3 more) |
| Called from | `ClipXRight`, `ClipXLeft`, `ClipXInside` |
| Calls | `IntersectCol0` (falls into) |

#### `IntersectCol0` (`$C48E`)

**The y where the edge crosses column 0, by bisection**

Witness: L1 67550 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,126 calls, 975,932 t-states own (0.15 %) |
| Runs (the other recordings) | 10,813 calls (`stage1/play2` 3,324, `stage1/death` 3,104, `stage1/missions` 1,886 and 4 more) |
| Called from | `ClipXRight`, `ClipXLeft`, `ClipXInside`, `IntersectColRight` (falls into) |

#### `FillPolygon` (`$C4C4`)

**Fill the polygon PolyVerts `$6700` in the colour `$7579`: clip, find the top and bottom, walk the edges, fill**

After the clips, fewer than 3 vertices return. Finds the lowest and highest row in `$6681`..., marks the top vertex, doubles the list, sets the bottom row `$67BD` (FillSpans starts there and walks up, DE = `$FFE0`; the byte is shared with MouseDelta) and the row count `$68A8`, and calls EdgeWalk `$C542`. Entered from bank 5 `$7290` (38 827 calls over the recordings).

Witness: L1 38525 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

[Animation: `FillPolygon` at work](img/routines/FillPolygon.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,908 calls, 2,907,394 t-states own (0.44 %) |
| Runs (the other recordings) | 38,525 calls (`stage1/death` 11,168, `stage1/play2` 8,321, `stage1/missions` 8,193 and 7 more) |
| Calls | `ClipPolyY`, `FillSpansThenReturn` (falls into), `EdgeWalk` (tail) |
| Reads | `$6680`-`$668F` (`PolyXClipped`); `$C4CC` (`FillPolygon+8`) |
| Writes | `$6681`-`$669F` (`PolyXClipped+1`); `$67BD` (`MouseDelta`); `$68A8` (`PanelGauges`); `$C4CC` (`FillPolygon+8`); `$C517` (`l_C4FE+25`) |

#### `FillSpansThenReturn` (`$C53E`)

**CALL FillSpans `$C86A` then RET (the edge walker jumps here when the spans are on the stack)**

Witness: L1 33753 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,395 calls, 51,813 t-states own (0.01 %) |
| Runs (the other recordings) | 33,753 calls (`stage1/death` 9,135, `stage1/missions` 7,698, `stage1/play2` 7,281 and 7 more) |
| Called from | `FillPolygon` (falls into), `EdgeWalk` (tail) |
| Calls | `FillSpans` |

#### `FillSpansReturn` (`$C541`)

**The RET after FillSpans**

Witness: L1 33753 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,395 calls, 27,487 t-states own (0.00 %) |
| Runs (the other recordings) | 33,753 calls (`stage1/death` 9,135, `stage1/missions` 7,698, `stage1/play2` 7,281 and 7 more) |
| Called from | `FillSpans` (tail) |

#### `EdgeWalk` (`$C542`)

**Walk the left and right edges from the top vertex down, pushing one (left, right) span per row on the stack**

`SP` saved at `$C7EA`; each edge's step from EdgeSlope `$C959`; the next edge on either side by `$C82D` (left, IX forward) and `$C7ED` (right, IY back); at the bottom it jumps to FillSpansThenReturn `$C53E`. The biggest block of bank 3: 385 instructions.

Witness: L1 31451 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,319 calls, 7,284,985 t-states own (1.10 %) |
| Runs (the other recordings) | 31,451 calls (`stage1/death` 8,139, `stage1/missions` 7,157, `stage1/play2` 7,146 and 7 more) |
| Called from | `FillPolygon` (tail) |
| Calls | `FillSpansThenReturn` (tail), `NextRightEdge`, `NextLeftEdge`, `EdgeSlope` |
| Reads | `$6680`-`$669F` (`PolyXClipped`) |
| Writes | `$C57F` (`l_C574+11`); `$C5BA` (`l_C5AF+11`); `$C7EA`-`$C7EB` (`l_C7E9+1`) |

#### `NextRightEdge` (`$C7ED`)

**Take the next edge on the right side (IY backwards): its rows and step**

Witness: L1 10893 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,039 calls, 356,706 t-states own (0.05 %) |
| Runs (the other recordings) | 10,893 calls (`stage1/missions` 3,023, `stage1/play2` 2,273, `stage1/menu` 1,565 and 7 more) |
| Called from | `EdgeWalk` |
| Calls | `EdgeSlope` |
| Reads | `$6682`-`$669D` (`PolyXClipped+2`) |
| Writes | `$C828` (`l_C81F+9`) |

#### `NextLeftEdge` (`$C82D`)

**Take the next edge on the left side (IX forwards): its rows and step**

Witness: L1 9734 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,060 calls, 349,979 t-states own (0.05 %) |
| Runs (the other recordings) | 9,734 calls (`stage1/missions` 2,639, `stage1/play2` 1,820, `stage1/menu` 1,559 and 7 more) |
| Called from | `EdgeWalk` |
| Calls | `EdgeSlope` |
| Reads | `$6682`-`$6699` (`PolyXClipped+2`) |
| Writes | `$C867` (`l_C85D+10`) |

#### `FillSpans` (`$C86A`)

**Pop the spans and fill them row by row in the back buffer with the colour's 2-row dither pattern**

The pattern from FillPatterns `$66D6` + 2 `$7579` (solid `$FF` when `$757A` = 0); the edges masked with RightEdgeMasks / LeftEdgeMasks `$66F0`; the middle bytes by a patched jump into 31 `LD (HL),B`. Writes `$8AF8-$96F0`; 85 permille of the recordings' time (the heaviest routine of the 3D view after the blit).

Witness: L1 33753 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

[Animation: `FillSpans` at work, mouse](img/routines/FillSpans-mouse.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,395 calls, 16,120,013 t-states own (2.44 %) |
| Runs (the other recordings) | 33,753 calls (`stage1/death` 9,135, `stage1/missions` 7,698, `stage1/play2` 7,281 and 7 more) |
| Called from | `FillSpansThenReturn` |
| Calls | `FillSpansReturn` (tail) |
| Reads | `$66D6`-`$66FF` (`FillPatterns`); `$67BD` (`MouseDelta`); `$68A8` (`PanelGauges`); `$7579`-`$757A` (`AwolState+1`); `$8AF8`-`$96F0` (`BackBuffer+7`) |
| Writes | `$8AF8`-`$96F0` (`BackBuffer+7`); `$C8DF` (`l_C8D6+9`); `$C932`-`$C93B` (`l_C930+2`) |

#### `EdgeSlope` (`$C959`)

**HL = 256 H / L by logarithms (LogFraction, LogInteger, ExpFraction): the x step per row; 0 or `$FFFF` at the limits**

Witness: L1 83529 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,737 calls, 1,721,898 t-states own (0.26 %) |
| Runs (the other recordings) | 83,529 calls (`stage1/missions` 19,976, `stage1/death` 19,084, `stage1/play2` 18,385 and 7 more) |
| Called from | `EdgeWalk`, `NextRightEdge`, `NextLeftEdge` |
| Reads | `$5C00`-`$5EFF` (`LogFraction`) |
| Writes | `$C981` (`l_C980+1`); `$C996` (`l_C995+1`) |

#### `l_C9A3` (`$C9A3`)

**l_C9A3**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawLine` (`$C9A7`)

**Draw a line from (H, L) to (D, E) (x, y bytes) into the back buffer by OR, Bresenham**

Special cases: vertical (`$CA60`), horizontal (`$CA4E`), 45 degrees (`$CA74`); the pixel bit of the start in `$CA89`. Entered from bank 5 `$72B1`.

Witness: L1 4996 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 54,400 t-states own (0.01 %) |
| Runs (the other recordings) | 4,996 calls (`stage1/death` 2,261, `stage1/play2` 1,192, `stage1/missions` 733 and 4 more) |
| Calls | `DrawVerticalLine` (tail) |
| Reads | `$8B00`-`$96EA` (`BackBuffer+15`); `$CA89` (`LinePixelBit`) |
| Writes | `$8B00`-`$96EA` (`BackBuffer+15`); `$CA6F` (`l_CA6E+1`); `$CA89` (`LinePixelBit`) |

#### `DrawVerticalLine` (`$CA60`)

**A vertical line: `SET n,(HL)` patched to the column's bit, down D + 1 rows**

Witness: L1 1262 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 29,458 t-states own (0.00 %) |
| Runs (the other recordings) | 114 calls (`stage1/c1` 114) |
| Called from | `DrawLine` (tail) |
| Reads | `$9138`-`$9189` (`BackBuffer+1607`); `$919B`-`$91A9` (`BackBuffer+1706`); `$CA89` (`LinePixelBit`) |
| Writes | `$9138`-`$9189` (`BackBuffer+1607`); `$919B`-`$91A9` (`BackBuffer+1706`); `$CA6F` (`l_CA6E+1`) |

#### `SetClipWidth` (`$CFCD`)

**Patch the X clip's limit (10 operands) with A: `$FF` full width, `$5F` the 96-pixel console view**

Called through `$74CF` (`$74C9` A = `$FF`, `$74CD` A = `$5F`) by bank 6 `$CA8B`.

Witness: L1 30 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 338 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/missions` 16, `stage1/play2` 6, `stage1/m2erbe` 2 and 3 more) |
| Writes | `$C23E` (`ClipPolyX+38`); `$C252` (`ClipXRight+13`); `$C288` (`l_C26E+26`); `$C2C9` (`l_C2B5+20`); `$C2F3` (`ClipXLeft+13`); `$C31A` (`ClipXLeft+52`); 3 more ranges |

### Bank 3: debris

`src/bank3/debris.asm`

#### `DrawDebris` (`$D08C`)

**Draw every live fragment that lies in front of the tank and inside the view**

For each of the 8 records (IX from `$CFEC`, the count in the operand `$D140`): clear bit 5; a live record's x and z minus the camera's (`$67A7`, `$67AA`) into the projection operands `$9A8E` and `$9A6C`; skip it when x is outside -`$20`..`$1F` (high byte; the bounds are the operands `$D0C6` / `$D0CE`) or z likewise; y minus `$67AD` to +`$0D`; `$BBBC` (bank 2) gives the distance (HL, kept in `$66D0`) and HL' to +`$0B`; DebrisInView; if in view, bit 5 set and the renderer `$BEDE` draws it.

Witness: L1 3602 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 4,969 t-states own (0.00 %) |
| Runs (the other recordings) | 3,602 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 3 more) |
| Calls | `DrawDebrisNext` (falls into) |
| Reads | `$66D0`-`$66D1` (`PolyWorkSpare+1`); `$67A7`-`$67AE` (`WorldVars+4`); `$CFEC`-`$D080` (`DebrisRecords`); `$D0C6`-`$D0CE` (`XBoundOp+1`, `XBoundNegOp`) |
| Writes | `$66D0`-`$66D1` (`PolyWorkSpare+1`); `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$CFEC`-`$D086` (`DebrisRecords`); `$D140` (`DebrisCountOp+1`) |

#### `DrawDebrisNext` (`$D095`)

**DrawDebrisNext**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 70,761 t-states own (0.01 %) |
| Runs (the other recordings) | 5,432 calls (`stage1/missions` 2,184, `stage1/play` 1,968, `stage1/c1` 952 and 1 more) |
| Called from | `DrawDebris` (falls into), `DrawDebrisSkip` (tail) |
| Calls | `DrawDebrisSkip` (tail), `DebrisInView` |
| Reads | `$CFEC`-`$D000` (`DebrisRecords`); `$D014` (`DebrisRecords+40`); `$D028` (`DebrisRecords+60`); `$D03C` (`DebrisRecords+80`); `$D050` (`DebrisRecords+100`); `$D064` (`DebrisRecords+120`); 1 more ranges |
| Writes | `$CFEC`-`$D000` (`DebrisRecords`); `$D014` (`DebrisRecords+40`); `$D028` (`DebrisRecords+60`); `$D03C` (`DebrisRecords+80`); `$D050` (`DebrisRecords+100`); `$D064` (`DebrisRecords+120`); 1 more ranges |

#### `DrawDebrisSkip` (`$D139`)

**DrawDebrisSkip**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 94,843 t-states own (0.01 %) |
| Runs (the other recordings) | 5,432 calls (`stage1/missions` 2,184, `stage1/play` 1,968, `stage1/c1` 952 and 1 more) |
| Called from | `DrawDebrisNext` (tail) |
| Calls | `DrawDebrisNext` (tail), `DebrisInView` (falls into) |
| Reads | `$D097`-`$D098` (`DrawDebrisNext+2`) |
| Writes | `$D140` (`DebrisCountOp+1`) |

#### `DebrisInView` (`$D148`)

**Carry set when the fragment is outside the view's cone: |x'| > z / 2 + 100**

Input: HL = the distance from `$BBBC`, IX the record (+`$0B` the side offset). Output: carry = not visible. Witness: L1 4263 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3,584 calls (`stage1/death` 3,010, `stage1/play2` 574) |
| Called from | `DrawDebrisNext`, `DrawDebrisSkip` (falls into) |
| Reads | `$CFF7`-`$D020` (`DebrisRecords+11`); `$D033`-`$D034` (`DebrisRecords+71`); `$D047`-`$D048` (`DebrisRecords+91`); `$D05B`-`$D05C` (`DebrisRecords+111`); `$D06F`-`$D070` (`DebrisRecords+131`); `$D083`-`$D084` (`DebrisRecords+151`); 1 more ranges |

#### `MoveDebris` (`$D16B`)

**Move one fragment: add the speeds to x, z, y; gravity on the y speed; free the record below the ground**

x += the signed +`$0F` (with carry into the word), z += +`$10`, y += +`$11`; y below 0: the record is freed (+0 = 0). Else the y speed drops by 5; when that subtraction overflows (below -128, `JP PO` not taken) the record is freed too. Then the turn +`$0A` grows by +`$12` and +`$13` (docs/10-gameplay-logic.md 10.8).

Witness: L1 661 (death, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 661 calls (`stage1/death` 500, `stage1/play2` 161) |
| Called from | `MoveAllDebris` |
| Reads | `$CFED`-`$D08B` (`DebrisRecords+1`) |
| Writes | `$CFEC`-`$D089` (`DebrisRecords`) |

#### `MoveAllDebris` (`$D1EC`)

**MoveDebris for each of the 8 records whose flags are non-zero**

Witness: L1 3602 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 94,653 t-states own (0.01 %) |
| Runs (the other recordings) | 3,602 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 3 more) |
| Calls | `MoveDebris` |
| Reads | `$CFEC`-`$D000` (`DebrisRecords`); `$D014` (`DebrisRecords+40`); `$D028` (`DebrisRecords+60`); `$D03C` (`DebrisRecords+80`); `$D050` (`DebrisRecords+100`); `$D064` (`DebrisRecords+120`); 1 more ranges |


## Bank 4 (`src/bank4/bank4.json`)

Battle Command, Ocean 1990: RAM bank 4, paged at `$C000`, as its tape block loads it. Its entries are
`src/bank4/<module>.asm`, written from `src/bank4/bank4.ann` by `kit/mkgame.py --part src/bank4/bank4.json`; the
recordings: `work/stage1/c1g` (c1 from the game's entry at frame 23974, the loader left out: the title, the mission
tape, Blast Em Mission played), and `work/stage1/menu`, `work/stage1/missions`, `work/stage1/play`,
`work/stage1/play2`, `work/stage1/death`, `work/stage1/m2ocean`, `work/stage1/m2erbe`, `work/stage1/search`,
`work/stage1/m10`, `work/stage1/c1`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`music`](#bank-4-music) | `$C000`-`$CDFF` | 34 of 50 |

### Bank 4: music

`src/bank4/music.asm`

#### `StartTune` (`$C000`)

**Start tune A: the tune's speed and three order lists from TuneTable, the channel records reset, the music on**

Input: A = the tune (7-byte records at TuneTable `$C869`; only tune 0 exists). Clears MusicOn and EffectOn, the speed into the operand `$C0FE`, then for each channel: transpose (+`$20`), repeat (+`$21`), duration count 1 (+`$10`), flags, vibrato and drum off, the order list into +`$03` and +`$05` (the restart point), +`$25` = 1 (take a pattern first); the global transpose `$C39D` = 0, SpeedCount and MusicOn = 1.

Witness frames (first-last frame of the recording, runs): c1 24005-24633 (2), controls 125-294 (2), m2erbe 7553-7554 (1), menu 125-1904 (4), missions 8062-34099 (8), play 10724 (1), play2 9718-23564 (3).

Witness: L1 19 (c1, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 1,976 t-states own (0.00 %) |
| Runs (the other recordings) | 19 calls (`stage1/missions` 8, `stage1/menu` 4, `stage1/play2` 3 and 3 more) |
| Reads | `$C869`-`$C86F` (`TuneTable`) |
| Writes | `$C05A`-`$C0D1` (`ChannelRecords`, `ChannelB`, `ChannelC`, `SpeedCount` and 2 more); `$C0FE` (`SpeedOp+1`); `$C39D` (`TransposeOp+1`) |

#### `MusicTick` (`$C0D2`)

**One frame of music: the effect, the patterns every SpeedCount frames, each channel's sound, the AY registers out**

Calls EffectTick; when MusicOn, counts SpeedCount down and at 0 steps the three channels (ChannelStep) and reloads it from the speed (`$C0FE`); then ChannelSound per channel into the tone words `$C47B`, `$C47D`, `$C47F` and the volumes `$C483`-`$C485`, and the noise period from `$C12A` into `$C481`. When EffectOn, the effect's tone A, tone C, noise, mixer and volumes replace the music's. If either is on, registers 11 down to 0 go out from `$C486` down (`OUT` on `$FFFD`, `OUTD` on `$BFFD`).

Witness frames (first-last frame of the recording, runs): c1 24005-33298 (4415), controls 0-330 (259), death 0-20038 (15291), m10 0-9028 (6442), m2erbe 0-7808 (3258), m2ocean 0-4799 (2252), menu 0-10996 (7704), missions 0-35997 (14024), play 0-10930 (6216), play2 0-23665 (14418), search 0-5043 (2273).

Witness: L1 76293 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

[Animation: `MusicTick` at work](img/routines/MusicTick.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,415 calls, 1,150,473 t-states own (0.17 %) |
| Runs (the other recordings) | 76,293 calls (`stage1/death` 15,291, `stage1/play2` 14,418, `stage1/missions` 14,024 and 7 more) |
| Calls | `ChannelStep`, `ChannelSound`, `EffectTick` |
| Reads | `$C0CF`-`$C0D1` (`SpeedCount`, `MusicOn`, `EffectOn`); `$C47B`-`$C486` (`AYShadow`, `AYNoise`, `AYMixer`, `AYVolumes`) |
| Writes | `$C0CF` (`SpeedCount`); `$C12A` (`NoiseOutOp+1`); `$C47B`-`$C485` (`AYShadow`, `AYNoise`, `AYMixer`, `AYVolumes`) |
| Ports out | `$BEFD`, `$FFFD` |

#### `WriteAY` (`$C17A`)

**Write E to AY register D**

Known only from the code as a routine of its own: called by StartEffect, which no recording runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MusicSilence` (`$C184`)

**Registers 13 down to 0 to zero, then the mixer (register 7) to `$3F`: all quiet**

Witness frames (first-last frame of the recording, runs): c1 24571-24716 (2), controls 61-224 (2), death 98 (1), m10 98 (1), m2erbe 98-7732 (2), m2ocean 98 (1), menu 61-2095 (5), missions 98-34256 (9), play 98-10891 (2), play2 98-17546 (3), search 98 (1).

Witness: L1 27 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 1,614 t-states own (0.00 %) |
| Runs (the other recordings) | 27 calls (`stage1/missions` 9, `stage1/menu` 5, `stage1/play2` 3 and 7 more) |
| Called from | `StopMusicCore` |
| Ports out | `$BFFD`, `$FFFD` |

#### `StopMusic` (`$C1A2`)

**StopMusicCore with every register saved**

Witness frames (first-last frame of the recording, runs): c1 24571-24716 (2), controls 61-224 (2), death 98 (1), m10 98 (1), m2erbe 98-7732 (2), m2ocean 98 (1), menu 61-2095 (5), missions 98-34256 (9), play 98-10891 (2), play2 98-17547 (3), search 98 (1).

Witness: L1 27 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 280 t-states own (0.00 %) |
| Runs (the other recordings) | 27 calls (`stage1/missions` 9, `stage1/menu` 5, `stage1/play2` 3 and 7 more) |
| Calls | `StopMusicCore` |

#### `StopMusicCore` (`$C1B2`)

**MusicOn and EffectOn off, MusicSilence, the three volumes to zero**

Witness: L1 27 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 200 t-states own (0.00 %) |
| Runs (the other recordings) | 27 calls (`stage1/missions` 9, `stage1/menu` 5, `stage1/play2` 3 and 7 more) |
| Called from | `StopMusic` |
| Calls | `MusicSilence` |
| Writes | `$C0D0`-`$C0D1` (`MusicOn`, `EffectOn`); `$C483`-`$C485` (`AYVolumes`) |

#### `CmdStop` (`$C1DB`)

**Command `$8E`: drop the return into the channel step and stop the music**

Witness: known only from the code (the tune never uses `$8E`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CmdNextPattern` (`$C1DF`)

**Command `$87`: the pattern is done, take the next one from the order list**

Witness: L1 19 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 20 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/menu`, `stage1/c1`, `stage1/play2` and 7 more) |
| Called from | `Command` |
| Calls | `NextPattern` (tail) |

#### `CmdNoise` (`$C1E2`)

**Command `$8B`: the channel plays noise only (its tone bit off in the mixer template), the noise follows the note**

The mixer template is the operand at `$C446`. Witness: L1 2 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/menu`) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Reads | `$C0CE` (`ChannelC+38`); `$C446` (`MixerTemplateOp+1`) |
| Writes | `$C0C6` (`ChannelC+30`); `$C446` (`MixerTemplateOp+1`) |

#### `CmdTone` (`$C1F7`)

**Command `$8A`: the channel plays tone only, the noise no longer follows the note**

Witness: L1 66 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 392 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/missions`, `stage1/menu`, `stage1/play2` and 7 more) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Reads | `$C080` (`ChannelRecords+38`); `$C0A7` (`ChannelB+38`); `$C0CE` (`ChannelC+38`); `$C446` (`MixerTemplateOp+1`) |
| Writes | `$C078` (`ChannelRecords+30`); `$C09F` (`ChannelB+30`); `$C0C6` (`ChannelC+30`); `$C446` (`MixerTemplateOp+1`) |

#### `CmdToneNoise` (`$C20B`)

**Command `$8C`: tone and noise both on for the channel, the noise follows the note**

Witness: L1 41 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 332 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/missions`, `stage1/menu`, `stage1/play2` and 7 more) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Reads | `$C0CE` (`ChannelC+38`); `$C446` (`MixerTemplateOp+1`) |
| Writes | `$C0C6` (`ChannelC+30`); `$C446` (`MixerTemplateOp+1`) |

#### `CmdSlide` (`$C21C`)

**Command `$84` step, delay: slide the frequency by step every delay frames**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CmdTranspose` (`$C232`)

**Command `$89` n: transpose every channel by n semitones (the operand `$C39D`)**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CmdVibrato` (`$C239`)

**Command `$88` step, depth: the vibrato's step and depth (its position starts at the depth)**

Witness: L1 38 (c1, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 380 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/missions`, `stage1/menu`, `stage1/play2` and 3 more) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Reads | `$CB0A`-`$CB0B` (`Patterns+510`); `$CB1C`-`$CB1D` (`Patterns+528`) |
| Writes | `$C074`-`$C076` (`ChannelRecords+26`); `$C09B`-`$C09D` (`ChannelB+26`) |

#### `CmdBendUp` (`$C248`)

**Command `$86`: the note rises one step a frame while it lasts**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CmdVibratoOff` (`$C252`)

**Command `$81`: no vibrato**

Witness: L1 28 (c1, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 124 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/menu`, `stage1/missions`, `stage1/c1` and 3 more) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Writes | `$C077` (`ChannelRecords+29`); `$C09E` (`ChannelB+29`); `$C0C5` (`ChannelC+29`) |

#### `CmdVibratoOn` (`$C257`)

**Command `$82`: vibrato every frame**

Witness: L1 38 (c1, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 124 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/missions`, `stage1/menu`, `stage1/play2` and 3 more) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Writes | `$C077` (`ChannelRecords+29`); `$C09E` (`ChannelB+29`) |

#### `CmdVibratoHalf` (`$C25D`)

**Command `$83`: vibrato every other frame**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CmdFlag1` (`$C263`)

**Command `$8D`: set bit 1 of the channel's flags, which no routine reads**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CmdRest` (`$C269`)

**Command `$80`: silence (volume 0, the envelope stopped) for a note's duration**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/menu`) |
| Called from | `Command` |
| Calls | `SetDuration` (tail) |
| Reads | `$C081` (`ChannelB`) |
| Writes | `$C081` (`ChannelB`); `$C094` (`ChannelB+19`) |

#### `CmdHold` (`$C272`)

**Command `$8F`: the envelope stops, the volume stays, for a note's duration**

Witness: L1 12 (c1, menu, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 140 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/menu`, `stage1/c1`, `stage1/play2`) |
| Called from | `Command` |
| Calls | `SetDuration` (tail) |
| Reads | `$C05A` (`ChannelRecords`); `$C081` (`ChannelB`) |
| Writes | `$C05A` (`ChannelRecords`); `$C081` (`ChannelB`) |

#### `CmdDrum` (`$C278`)

**Command `$90`: a drum hit (noise period 1 on the channel for a frame) on every note**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CmdDrumOff` (`$C27E`)

**Command `$91`: no drum**

Witness: L1 64 (c1, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 248 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/missions`, `stage1/menu`, `stage1/play2` and 3 more) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Writes | `$C079` (`ChannelRecords+31`); `$C0A0` (`ChannelB+31`); `$C0C7` (`ChannelC+31`) |

#### `CmdInlineDurations` (`$C283`)

**Command `$92`: each note is followed by its duration**

Witness: L1 66 (c1, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | run into, not called, 304 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/missions`, `stage1/menu`, `stage1/play2` and 3 more) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Writes | `$C07E` (`ChannelRecords+36`); `$C0A5` (`ChannelB+36`); `$C0CC` (`ChannelC+36`) |

#### `CmdDuration` (`$C28A`)

**Command `$93` n: every note lasts n steps**

Witness: L1 2 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/menu`) |
| Called from | `Command` |
| Calls | `ReadStream` (tail) |
| Reads | `$C910` (`Patterns+4`); `$C93C` (`Patterns+48`) |
| Writes | `$C06B` (`ChannelRecords+17`); `$C07E` (`ChannelRecords+36`); `$C092` (`ChannelB+17`); `$C0A5` (`ChannelB+36`) |

#### `ChannelStep` (`$C295`)

**Count the note down; at its end read the channel's next note and the commands before it**

Input: IX the channel record, B = 0. When +`$25` is set, the next pattern first (NextPattern). A note byte (below `$80`) plus the pattern's transpose is the note (+`$12`); a noise-following channel also sets the noise period (`$C0DD`); the ornament and the instrument's envelope restart; the duration from +`$11` or the next byte. Between notes a bend changes the note a step a frame (`$C30F`).

Witness: L1 15111 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,815 calls, 136,544 t-states own (0.02 %) |
| Runs (the other recordings) | 15,111 calls (`stage1/menu` 4,758, `stage1/missions` 4,158, `stage1/c1` 1,815 and 7 more) |
| Called from | `MusicTick` |
| Calls | `ReadStream` (falls into), `NextPattern` (tail) |
| Reads | `$C05A`-`$C06A` (`ChannelRecords`); `$C07F`-`$C091` (`ChannelRecords+37`, `ChannelB`); `$C0A6`-`$C0B8` (`ChannelB+37`, `ChannelC`); `$C0CD` (`ChannelC+37`) |
| Writes | `$C05A`-`$C06A` (`ChannelRecords`); `$C081`-`$C091` (`ChannelB`); `$C0A8`-`$C0B8` (`ChannelC`) |

#### `ReadStream` (`$C2AA`)

**ReadStream**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 145 calls, 33,115 t-states own (0.01 %) |
| Runs (the other recordings) | 1,393 calls (`stage1/missions` 397, `stage1/menu` 362, `stage1/play2` 178 and 7 more) |
| Called from | `CmdNoise` (tail), `CmdTone` (tail), `CmdToneNoise` (tail), `CmdVibrato` (tail), `CmdVibratoOff` (tail), `CmdVibratoOn` (tail), `CmdDrumOff` (tail), `CmdInlineDurations` (tail), `CmdDuration` (tail), `ChannelStep` (falls into), `Command` (tail), `NextPattern` (tail) |
| Calls | `SetDuration` (falls into), `Command` (tail) |
| Reads | `$C05A`-`$C0CC` (`ChannelRecords`, `ChannelB`, `ChannelC`); `$C775` (`InstrumentData+1`); `$C7BE` (`InstrumentData+74`); `$C7D3` (`InstrumentData+95`); `$C845`-`$C855` (`InstrumentData+209`); `$C90C`-`$C91F` (`Patterns`); 4 more ranges |
| Writes | `$C05A`-`$C0C1` (`ChannelRecords`, `ChannelB`, `ChannelC`); `$C0DD` (`NoiseOp+1`) |

#### `SetDuration` (`$C2E8`)

**SetDuration**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 91 calls, 14,287 t-states own (0.00 %) |
| Runs (the other recordings) | 415 calls (`stage1/menu` 229, `stage1/play2` 95, `stage1/c1` 91) |
| Called from | `CmdRest` (tail), `CmdHold` (tail), `ReadStream` (falls into) |
| Reads | `$C06B`-`$C07E` (`ChannelRecords+17`); `$C092`-`$C0A5` (`ChannelB+17`); `$C0C7`-`$C0CC` (`ChannelC+31`); `$C93A` (`Patterns+46`); `$C9B6`-`$C9DA` (`Patterns+170`); `$CAC1`-`$CB62` (`Patterns+437`) |
| Writes | `$C05B`-`$C06A` (`ChannelRecords+1`); `$C082`-`$C091` (`ChannelB+1`); `$C0A9`-`$C0B8` (`ChannelC+1`) |

#### `Command` (`$C320`)

**A pattern byte of `$80` and above: `$E0-$FF` an instrument, `$B0-$DF` an ornament, `$80-$AF` a command through CommandOffsets**

`$E0`+n: the instrument n from Instruments `$C75A`, its speed the byte before its data. `$B0`+n: the ornament n from OrnamentOffsets `$C721`. The branch at `$C342` (the tune's speed from a byte, `$C0FE`) is never taken: the sum `A + $50` always carries for a byte from `$B0` (known only from the code).

Witness: L1 595 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 58 calls, 5,468 t-states own (0.00 %) |
| Runs (the other recordings) | 595 calls (`stage1/missions` 176, `stage1/menu` 140, `stage1/play2` 85 and 7 more) |
| Called from | `ReadStream` (tail) |
| Calls | `CmdNextPattern`, `CmdNoise`, `CmdTone`, `CmdToneNoise`, `CmdVibrato`, `CmdVibratoOff`, `CmdVibratoOn`, `CmdRest`, `CmdHold`, `CmdDrumOff`, `CmdInlineDurations`, `CmdDuration`, `ReadStream` (tail) |
| Reads | `$C1C7`-`$C1DA` (`CommandOffsets`); `$C721`-`$C726` (`OrnamentOffsets`); `$C75A`-`$C774` (`Instruments`, `InstrumentData`); `$C7BD` (`InstrumentData+73`); `$C7D2` (`InstrumentData+94`); `$C844`-`$C854` (`InstrumentData+208`) |
| Writes | `$C063`-`$C06F` (`ChannelRecords+9`); `$C08A`-`$C096` (`ChannelB+9`); `$C0B1`-`$C0BD` (`ChannelC+9`) |

#### `ChannelSound` (`$C36A`)

**The channel's frequency (HL) and volume (A) this frame, and its mixer bits in AYShadow**

Input: IX the channel. The volume envelope steps every +`$0F` frames (the instrument's bytes until one with bit 7); the note plus the global transpose (`$C39D`) plus the ornament's byte (a byte with bit 7 ends the ornament and loops it) indexes NoteTable; the vibrato moves the frequency by its position (the depth in both directions); the slide adds its sum. The noise and tone bits go into the mixer `$C482` through the template `$C446`; a pending drum hit sets the noise period `$41`.

Witness: L1 15111 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,815 calls, 1,528,116 t-states own (0.23 %) |
| Runs (the other recordings) | 15,111 calls (`stage1/menu` 4,758, `stage1/missions` 4,158, `stage1/c1` 1,815 and 7 more) |
| Called from | `MusicTick` |
| Reads | `$C05A`-`$C0CE` (`ChannelRecords`, `ChannelB`, `ChannelC`); `$C482` (`AYMixer`); `$C4A6`-`$C4A7` (`NoteTable+18`); `$C4D2`-`$C507` (`NoteTable+62`); `$C518`-`$C519` (`NoteTable+132`); `$C728`-`$C747` (`Ornaments`); 3 more ranges |
| Writes | `$C05A`-`$C0C1` (`ChannelRecords`, `ChannelB`, `ChannelC`); `$C482` (`AYMixer`) |

#### `NextPattern` (`$C554`)

**Take the channel's next pattern from its order list**

The order list: a byte below `$80` is a pattern (PatternTable `$C870`); `$FF` n the pattern's transpose; `$FE` n repeat the following n times; `$FD` back to the list's start; `$FC` a word, jump there. Any other byte runs the trap at `$C5B1`: random border colours forever (a debugging aid of the music editor, known only from the code).

Witness: L1 76 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 8 calls, 2,856 t-states own (0.00 %) |
| Runs (the other recordings) | 76 calls (`stage1/missions` 25, `stage1/menu` 20, `stage1/play2` 11 and 7 more) |
| Called from | `CmdNextPattern` (tail), `ChannelStep` (tail) |
| Calls | `ReadStream` (tail) |
| Reads | `$C05D`-`$C05E` (`ChannelRecords+3`); `$C07B`-`$C085` (`ChannelRecords+33`, `ChannelB`); `$C0A2`-`$C0AC` (`ChannelB+33`, `ChannelC`); `$C0C9`-`$C0CB` (`ChannelC+33`); `$C870`-`$C893` (`PatternTable`, `OrderLists`); `$C8C2`-`$C8C3` (`OrderLists+48`); 1 more ranges |
| Writes | `$C05B`-`$C05E` (`ChannelRecords+1`); `$C07A`-`$C085` (`ChannelRecords+32`, `ChannelB`); `$C0A1`-`$C0AC` (`ChannelB+32`, `ChannelC`); `$C0C8`-`$C0CD` (`ChannelC+32`) |

#### `StartEffect` (`$C5E1`)

**Start sound effect A: its 17 bytes from EffectTable to EffectState, the envelope registers set**

Witness: known only from the code (no routine of the game calls it; the effects of play are bank 0's, `$D692`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `EffectTick` (`$C63E`)

**Step the random number; while an effect runs, its time, its repeats and its tone slides**

Witness: L1 76293 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,415 calls, 199,009 t-states own (0.03 %) |
| Runs (the other recordings) | 76,293 calls (`stage1/death` 15,291, `stage1/play2` 14,418, `stage1/missions` 14,024 and 7 more) |
| Called from | `MusicTick` |
| Calls | `NextRandom` |
| Reads | `$C0D1` (`EffectOn`) |

#### `NextRandom` (`$C702`)

**Shift the 32-bit generator at RandomSeed one step; A = its first byte**

Witness: L1 76293 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,415 calls, 653,679 t-states own (0.10 %) |
| Runs (the other recordings) | 76,293 calls (`stage1/death` 15,291, `stage1/play2` 14,418, `stage1/missions` 14,024 and 7 more) |
| Called from | `EffectTick` |
| Reads | `$C71D`-`$C720` (`RandomSeed`) |
| Writes | `$C71D`-`$C720` (`RandomSeed`) |


## Bank 6 (`src/bank6/bank6.json`)

Battle Command, Ocean 1990: RAM bank 6, paged at `$C000`, as its tape block loads it. Its entries are
`src/bank6/<module>.asm`, written from `src/bank6/bank6.ann` by `kit/mkgame.py --part src/bank6/bank6.json`; the
recordings: `work/stage1/c1g` (c1 from the game's entry at frame 23974, the loader left out: the title, the mission
tape, Blast Em Mission played), and `work/stage1/menu`, `work/stage1/missions`, `work/stage1/play`,
`work/stage1/play2`, `work/stage1/death`, `work/stage1/m2ocean`, `work/stage1/m2erbe`, `work/stage1/search`,
`work/stage1/m10`, `work/stage1/c1`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`pointer`](#bank-6-pointer) | `$C000`-`$C02F`, `$D0CA`-`$D352` | 13 of 17 |
| [`catalogue`](#bank-6-catalogue) | `$C030`-`$C078`, `$C75F`-`$C989`, `$CFA9`-`$D09F` | 13 of 21 |
| [`statusview`](#bank-6-statusview) | `$C079`-`$C113` | 5 of 8 |
| [`stores`](#bank-6-stores) | `$C114`-`$C125`, `$C165`-`$C408`, `$CA8B`-`$CC53`, `$D0A0`-`$D0C9`, `$D6DA`-`$D77E`, `$D7BB`-`$D9B1` | 20 of 32 |
| [`numbers`](#bank-6-numbers) | `$C126`-`$C164`, `$D353`-`$D3C8` | 4 of 4 |
| [`title`](#bank-6-title) | `$C409`-`$C4FB` | 2 of 4 |
| [`password`](#bank-6-password) | `$C4FC`-`$C75E`, `$CE2E`-`$CFA8` | 14 of 28 |
| [`briefing`](#bank-6-briefing) | `$C98A`-`$CA8A` | 3 of 5 |
| [`results`](#bank-6-results) | `$CC54`-`$CE2D` | 9 of 15 |
| [`panel`](#bank-6-panel) | `$D3C9`-`$D6D9`, `$D77F`-`$D7BA` | 9 of 16 |
| [`map`](#bank-6-map) | `$D9B2`-`$E511`, `$E561`-`$E5D4` | 16 of 26 |
| [`models`](11-data-reference.md#bank-6-models) | `$E512`-`$E560`, `$E5D5`-`$E623` | 0 of 3 |
| [`graphics`](11-data-reference.md#bank-6-graphics) | `$E624`-`$F5E3` | 0 of 18 |
| [`font`](11-data-reference.md#bank-6-font) | `$F5E4`-`$F8F3` | 0 of 1 |
| [`options`](#bank-6-options) | `$F8F4`-`$F9FF` | 1 of 4 |

### Bank 6: pointer

`src/bank6/pointer.asm`

#### `SavePointerBackground` (`$D0CA`)

**Save the 8 x 2 screen bytes under the pointer into PointerBackground**

The address from `$7C53` (Y) through the line table `$6500` and `$7C51` / 8 (X), which goes to the operand `$D2FC` for PutPointer. `$9719` = 4. Witness: L1 49363 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,097 calls, 3,726,119 t-states own (0.56 %) |
| Runs (the other recordings) | 49,363 calls (`stage1/missions` 10,042, `stage1/play2` 9,545, `stage1/menu` 6,973 and 7 more) |
| Called from | `FitOrRemoveWeapon`, `TitleMenu`, `MissionCatalogueScreen`, `BriefingScreen`, `StoresScreen`, `MissionStatusScreen`, `SelectMissionLine` |
| Reads | `$4022`-`$40FC` (screen); `$4122`-`$41FC` (screen); `$4222`-`$42FC` (screen); `$4322`-`$43FC` (screen); `$4422`-`$44FC` (screen); `$4522`-`$45FC` (screen); 4 more ranges |
| Writes | `$9719` (`StepFrames`); `$C020`-`$C02F` (`PointerBackground`); `$D2FC` (`PutPointer+11`) |

#### `SetStoresWindow` (`$D102`)

**The 3D window of the stores for CopyViewUnderPointer and DrawPointerInView**

Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 50 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/death` 1 and 3 more) |
| Called from | `StoresScreen` |
| Calls | `SetViewWindow` (tail) |
| Writes | `$D146`-`$D157` (`CopyViewUnderPointer+4`); `$D171` (`ViewUnderMiddle+4`); `$D184` (`ViewUnderBottom+1`); `$D1C2`-`$D1CD` (`DrawPointerInView+4`); `$D1EB` (`PointerInViewBottom+1`); `$D215` (`PointerInViewMiddle+7`) |

#### `SetTitleWindow` (`$D10E`)

**The 3D window of the title menu for the same two**

Witness: L1 19 (c1, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 76 t-states own (0.00 %) |
| Runs (the other recordings) | 19 calls (`stage1/missions` 8, `stage1/menu` 4, `stage1/play2` 3 and 3 more) |
| Called from | `TitleMenu` |
| Calls | `SetViewWindow` (falls into) |
| Writes | `$D146`-`$D157` (`CopyViewUnderPointer+4`); `$D171` (`ViewUnderMiddle+4`); `$D184` (`ViewUnderBottom+1`); `$D1C2`-`$D1CD` (`DrawPointerInView+4`); `$D1EB` (`PointerInViewBottom+1`); `$D215` (`PointerInViewMiddle+7`) |

#### `SetViewWindow` (`$D118`)

**Patch the window's limits into CopyViewUnderPointer and DrawPointerInView**

Input: A the bottom line, A' the top line. Witness: L1 34 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3 calls, 552 t-states own (0.00 %) |
| Runs (the other recordings) | 29 calls (`stage1/missions` 16, `stage1/play2` 6, `stage1/c1` 3 and 2 more) |
| Called from | `SetStoresWindow` (tail), `SetTitleWindow` (falls into) |
| Writes | `$D14C`-`$D157` (`CopyViewUnderPointer+10`); `$D171` (`ViewUnderMiddle+4`); `$D184` (`ViewUnderBottom+1`); `$D1C2`-`$D1CD` (`DrawPointerInView+4`); `$D1EB` (`PointerInViewBottom+1`); `$D215` (`PointerInViewMiddle+7`) |

#### `CopyViewUnderPointer` (`$D142`)

**Over the 3D window: take the pointer's background from the back buffer, not the screen**

Run by the interrupt. Clipped at the window's top and bottom (the operands set by SetViewWindow). Witness: L1 2944 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 171 calls, 46,285 t-states own (0.01 %) |
| Runs (the other recordings) | 2,944 calls (`stage1/play2` 1,042, `stage1/missions` 897, `stage1/play` 430 and 7 more) |
| Reads | `$7C51`-`$7C53` (`FailReason+88`); `$8AF8`-`$8BB9` (`BackBuffer+7`); `$8BFA`-`$9280` (`BackBuffer+265`); `$92C0`-`$96E5` (`BackBuffer+1999`); `$D153` (`CopyViewUnderPointer+17`) |
| Writes | `$C020`-`$C02F` (`PointerBackground`) |

#### `DrawPointerInView` (`$D1BE`)

**Over the 3D window: put the shifted pointer (ShiftedPointer) into the back buffer**

Run by the interrupt; clipped like CopyViewUnderPointer. Witness: L1 2944 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 171 calls, 113,159 t-states own (0.02 %) |
| Runs (the other recordings) | 2,944 calls (`stage1/play2` 1,042, `stage1/missions` 897, `stage1/play` 430 and 7 more) |
| Reads | `$7C51`-`$7C53` (`FailReason+88`); `$8AF8`-`$9280` (`BackBuffer+7`); `$92C0`-`$96E5` (`BackBuffer+1999`); `$D1C9` (`DrawPointerInView+11`); `$D2D1`-`$D2F0` (`ShiftedPointer`) |
| Writes | `$8AF8`-`$9280` (`BackBuffer+7`); `$92C0`-`$96E5` (`BackBuffer+1999`) |

#### `RestorePointerBackground` (`$D251`)

**Put PointerBackground back on the screen at the pointer's old place**

Witness: L1 49282 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,093 calls, 3,420,974 t-states own (0.52 %) |
| Runs (the other recordings) | 49,282 calls (`stage1/missions` 10,016, `stage1/play2` 9,536, `stage1/menu` 6,945 and 7 more) |
| Called from | `FitOrRemoveWeapon`, `MissionCatalogueScreen`, `SelectMissionLine` |
| Reads | `$6510`-`$667D` (`ScreenRowTable+16`); `$7C53`-`$7C54` (`FailReason+90`); `$C020`-`$C02F` (`PointerBackground`); `$D2FC` (`PutPointer+11`) |
| Writes | `$4022`-`$40FC` (screen); `$4122`-`$41FC` (screen); `$4222`-`$42FC` (screen); `$4322`-`$43FC` (screen); `$4422`-`$44FC` (screen); `$4522`-`$45FC` (screen); 2 more ranges |

#### `DrawPointer` (`$D27C`)

**ShiftPointer, then PutPointer**

Witness: L1 49399 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,100 calls, 83,709 t-states own (0.01 %) |
| Runs (the other recordings) | 49,399 calls (`stage1/missions` 10,059, `stage1/play2` 9,548, `stage1/menu` 6,964 and 7 more) |
| Called from | `ShowWaitPointer` (tail) |
| Calls | `ShiftPointer`, `PutPointer` (tail) |

#### `ShiftPointer` (`$D282`)

**Shift the shape at its operand `$D283` by X AND 7 into ShiftedPointer (mask with ones, pixels with zeros)**

Witness: L1 49399 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,100 calls, 5,602,866 t-states own (0.85 %) |
| Runs (the other recordings) | 49,399 calls (`stage1/missions` 10,059, `stage1/play2` 9,548, `stage1/menu` 6,964 and 7 more) |
| Called from | `DrawPointer` |
| Reads | `$7C51` (`FailReason+88`); `$C000`-`$C01F` (`PointerShapes`, `WaitPointer`) |
| Writes | `$D2A0` (`ShiftLoop+2`); `$D2B8` (`ShiftMaskDone+7`); `$D2D1`-`$D2F0` (`ShiftedPointer`) |

#### `PutPointer` (`$D2F1`)

**AND the mask and OR the pixels of ShiftedPointer into the screen**

Witness: L1 49399 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,100 calls, 5,474,780 t-states own (0.83 %) |
| Runs (the other recordings) | 49,399 calls (`stage1/missions` 10,059, `stage1/play2` 9,548, `stage1/menu` 6,964 and 7 more) |
| Called from | `DrawPointer` (tail) |
| Reads | `$4022`-`$40FC` (screen); `$4122`-`$41FC` (screen); `$4222`-`$42FC` (screen); `$4322`-`$43FC` (screen); `$4422`-`$44FC` (screen); `$4522`-`$45FC` (screen); 5 more ranges |
| Writes | `$4022`-`$40FC` (screen); `$4122`-`$41FC` (screen); `$4222`-`$42FC` (screen); `$4322`-`$43FC` (screen); `$4422`-`$44FC` (screen); `$4522`-`$45FC` (screen); 2 more ranges |

#### `StoresPointerLimits` (`$D337`)

**SetPointerLimits with `$D32F`**

Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 22 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/c1` 1 and 3 more) |
| Called from | `StoresScreen` |
| Calls | `SetPointerLimits` (tail) |

#### `CataloguePointerLimits` (`$D33C`)

**SetPointerLimits with `$D32B`**

Witness: L1 51 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3 calls, 30 t-states own (0.00 %) |
| Runs (the other recordings) | 51 calls (`stage1/missions` 17, `stage1/menu` 16, `stage1/play2` 6 and 7 more) |
| Called from | `TitleMenu`, `MissionCatalogueScreen` |
| Calls | `SetPointerLimits` (falls into) |
| Reads | `$D32B`-`$D32E` (`PointerLimits`) |
| Writes | `$7D99`-`$7DA6` (`PointerTick+25`) |

#### `SetPointerLimits` (`$D33F`)

**Copy the 4 limits at HL to the pointer routine's operands**

Witness: L1 85 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6 calls, 675 t-states own (0.00 %) |
| Runs (the other recordings) | 82 calls (`stage1/missions` 33, `stage1/menu` 20, `stage1/play2` 12 and 4 more) |
| Called from | `TitleMenu`, `StoresPointerLimits` (tail), `CataloguePointerLimits` (falls into) |
| Reads | `$D32B`-`$D336` (`PointerLimits`, `StoresLimits`, `TitleLimits`) |
| Writes | `$7D99`-`$7DA6` (`PointerTick+25`) |

### Bank 6: catalogue

`src/bank6/catalogue.asm`

#### `BuildMissionNames` (`$C030`)

**Copy the catalogue's head, then build the ten mission name lines at `$93D9` with their pointers at `$93B9`**

CopyCatalogueHead `$70C6` puts the catalogue's first 1 K into the back buffer at `$8AF1`. For each of the ten 27-byte names there: code 13 with the attribute `$46`, the name up to its 0 byte, spaces to 27 characters, code 11 and the end `$FF`; the line's address goes to the next word of `$93B9`.

Output: the strings in `$93D9-$950E` and the table `$93B9-$93CC` (in the back buffer, bank 2). Witness: L1 32 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 12,782 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 7 more) |
| Called from | `MissionCatalogueScreen` |
| Reads | `$8AF1`-`$8BB8` (`BackBuffer`); `$8BC9`-`$8BD0` (`BackBuffer+216`); `$8BE4`-`$8BF0` (`BackBuffer+243`) |
| Writes | `$93B9`-`$950E` (`BackBuffer+2248`) |

#### `WaitForClick` (`$C06F`)

**Wait until the interrupt's fire test sets ClickFlag `$6D43`, then clear it**

Known only from the code: nothing calls it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawCatalogueTitlesIf` (`$C75F`)

**Unused: return when no mission is chosen (`$757D` = `$FF`), else DrawCatalogueTitles**

Known only from the code: nothing calls it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawCatalogueTitles` (`$C765`)

**The catalogue's two title graphics and their attribute boxes**

CopyGraphic of CatalogueGraphicA (9 x 32 at line `$A0`) and CatalogueGraphicC (9 x 16 at line `$90`), AttrBox `$C74F` and `$C754`. Witness: L1 33 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 182 t-states own (0.00 %) |
| Runs (the other recordings) | 33 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 7 more) |
| Called from | `MissionCatalogueScreen` |

#### `MissionCatalogueScreen` (`$C790`)

**The mission catalogue: picture, the tape load if needed, the list, the ticks, then the zones**

The shadow screen, the pointer centred, DrawBank7Picture `$74AA` with `$CCC9` (PicMissionSelect), CatalogueGraphicB, DrawCatalogueTitles, the box `$C759`. When IsCatalogueLoaded says no: PrintRewind `$719B`, RewindText, LoadDirectory `$715D`. Then BuildMissionNames, PrintMissionList, a tick for every completed mission of MissionsDone, CataloguePointerLimits, the highlight of the selected line, the arrow pointer, the texts `$C93E`, `$C8D5` and the catalogue's title `$CF85`, RemarkMission `$8548`, PrintSelectedMission; then PointerZones until the view flag is set, ShowWaitPointer, NextView. Witness: L1 33 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 82,411,263 t-states own (12.46 %) |
| Runs (the other recordings) | 33 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 7 more) |
| Calls | `BuildMissionNames`, `DrawCatalogueTitles`, `IsCatalogueLoaded`, `ShowWaitPointer`, `PrintMissionList`, `PrintSelectedMission`, `HighlightLine`, `SavePointerBackground`, `RestorePointerBackground`, `CataloguePointerLimits` |
| Reads | `$6799`-`$67A2` (`MissionsDone`); `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$7C51`-`$7C53` (`FailReason+88`); `$7DC0`-`$7DC1` (`PointerPos`); `$83BF` (`PointerShown+1`); `$9715`-`$9716` (`ClickState`); `$D283`-`$D284` (`ShiftPointer+1`) |

#### `IsCatalogueLoaded` (`$C870`)

**Z when the catalogue head at `$CF85` starts with "MISSION"**

Compares 7 bytes with CatalogueMagic. Witness: L1 33 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 56 t-states own (0.00 %) |
| Runs (the other recordings) | 33 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 7 more) |
| Called from | `MissionCatalogueScreen` |
| Reads | `$C881`-`$C887` (`CatalogueMagic`); `$CF85`-`$CF8B` (`CatalogueTitle`) |

#### `ShowWrongDisk` (`$C88E`)

**Leftover of a disk version: "INCORRECT DISK" and a red attribute bar**

Known only from the code: nothing calls it; the texts `$C8A0` and `$C8B2` speak of a disk.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintMissionList` (`$CFA9`)

**Print the ten mission lines of `$93B9` (blanks as ":") 8 pixel lines apart from line `$41`**

Each line is copied over itself with spaces turned into `:` (the blank glyph of the small font) and printed after ListLinePos. Witness: L1 32 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 11,408 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 7 more) |
| Called from | `MissionCatalogueScreen` |
| Reads | `$93B9`-`$9501` (`BackBuffer+2248`); `$CFF0` (`ListLinePos+1`) |
| Writes | `$93D9`-`$9502` (`BackBuffer+2280`); `$CFC0`-`$CFC1` (`ListPtrOp+1`); `$CFE7`-`$CFF0` (`ListCountOp+1`, `ListLinePos`) |

#### `PrintSelectedMission` (`$CFF3`)

**Print the name of mission (`$757B`) at SelectedPos (none when negative)**

Witness: L1 32 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 61 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 7 more) |
| Called from | `MissionCatalogueScreen` |
| Reads | `$757B` (`AwolState+3`); `$93B9`-`$93CA` (`BackBuffer+2248`) |

#### `SelectMissionLine` (`$D013`)

**Zone: the list line under the pointer becomes the mission (`$757D`), highlighted, its description printed**

The line from the pointer's Y (`$9716`): (Y - `$40`) / 8; the pixel row into SelectedLineOp. HighlightLine, the pointer saved again. Witness: L1 29 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 207 t-states own (0.00 %) |
| Runs (the other recordings) | 29 calls (`stage1/menu` 10, `stage1/missions` 9, `stage1/play2` 3 and 7 more) |
| Calls | `HighlightLine`, `SavePointerBackground`, `RestorePointerBackground` |
| Reads | `$83BF` (`PointerShown+1`); `$9716` (`ClickY`) |
| Writes | `$757D` (`ScreenOfMission+1`); `$83BF` (`PointerShown+1`); `$C811` (`SelectedLineOp+1`) |

#### `HighlightLine` (`$D040`)

**Unhighlight the old line (attribute `$4D`), highlight row A (`$4E`), print the description**

The old row is the operand `$D026` (`$FF` none). Witness: L1 49 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 100 t-states own (0.00 %) |
| Runs (the other recordings) | 49 calls (`stage1/menu` 21, `stage1/missions` 17, `stage1/play2` 3 and 7 more) |
| Called from | `MissionCatalogueScreen`, `SelectMissionLine` |
| Calls | `FillAttrRow`, `PrintMissionDescription` (tail) |
| Reads | `$D026` (`SelectMissionLine+19`) |
| Writes | `$D026` (`SelectMissionLine+19`) |

#### `FillAttrRow` (`$D059`)

**Fill 12 attributes of row A/8 from column 3 with E**

Witness: L1 88 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 436 t-states own (0.00 %) |
| Runs (the other recordings) | 88 calls (`stage1/menu` 41, `stage1/missions` 33, `stage1/play2` 5 and 7 more) |
| Called from | `HighlightLine` |
| Reads | `$5903`-`$596D` (screen); `$5983`-`$598D` (screen); `$59A3`-`$59AD` (screen); `$59C3`-`$59CD` (screen); `$59E3`-`$59ED` (screen); `$5A03`-`$5A0D` (screen); 1 more ranges |
| Writes | `$5903`-`$596E` (screen); `$5983`-`$598E` (screen); `$59A3`-`$59AE` (screen); `$59C3`-`$59CE` (screen); `$59E3`-`$59EE` (screen); `$5A03`-`$5A0E` (screen); 1 more ranges |

#### `PrintMissionDescription` (`$D06C`)

**Clear the description area and print mission (`$757D`)'s description from the catalogue**

ScreenRowFill, DescriptionPos, then the text at `$8BFF` + the word `$8BFF`[mission]. Witness: L1 49 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 228 t-states own (0.00 %) |
| Runs (the other recordings) | 49 calls (`stage1/menu` 21, `stage1/missions` 17, `stage1/play2` 3 and 7 more) |
| Called from | `HighlightLine` (tail) |
| Reads | `$757D` (`ScreenOfMission+1`); `$8BFF`-`$8C14` (`BackBuffer+270`) |

### Bank 6: statusview

`src/bank6/statusview.asm`

#### `BriefPageBox` (`$C079`)

**The attribute box `$C0B1` and 8 cleared pixel lines behind the BRIEF page's text**

Called once by BriefPageText `$70B6`. AttrBox `$6CFB` with `$C0B1`, then ScreenRowFill `$6D22` of 8 lines of 18 bytes from line `$88`, column 7 (through BriefPageFill). Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |

#### `BriefPageBoxSmall` (`$C08E`)

**Variant: the box `$C089`, then the fill of BriefPageBoxLarge**

Known only from the code: nothing calls it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BriefPageBoxLarge` (`$C096`)

**Variant: the box `$C0AC` and 40 cleared lines at column 10**

Known only from the code: nothing calls it; its tail BriefPageFill is the one BriefPageBox jumps to.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `FormatGridPosition` (`$C0C0`)

**Format the map position: the two numbers in the operands `$C0C7` and `$C0E2` into GridText**

The operands are written by DrawStatusMap `$DB1C` from the view's position (`$9A6C` and `$9A8E`). Each goes through NumberToDigits `$C126` (leading zeros kept, C = `0`) into PaddedDigits `$D9AB`; digits 2-3 and 4-5 are copied around the colon of GridText. Witness: L1 40 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 40 calls (`stage1/missions` 34, `stage1/m2erbe` 4, `stage1/play` 2) |
| Called from | `PrintStatusGrid` |
| Calls | `NumberToDigits` |
| Reads | `$D9AC`-`$D9AF` (`PaddedDigits+1`) |
| Writes | `$C106`-`$C112` (`GridText+5`) |

#### `PrintStatusGrid` (`$C0F7`)

**Print the grid position of the status view**

Called every frame by StatusLoop `$6BC7`: FormatGridPosition, then PrintString `$6FB3` with GridText. Witness: L1 40 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 40 calls (`stage1/missions` 34, `stage1/m2erbe` 4, `stage1/play` 2) |
| Calls | `FormatGridPosition` |

### Bank 6: stores

`src/bank6/stores.asm`

#### `PrintPayloadWeight` (`$C114`)

**Print the payload's weight in kg on the payload line**

NumberToDigits `$C126` with C = `:` (the space of SmallFont `$7C59`) for the leading zeros into `$D9AB`, then PrintString `$6FB3` of PayloadText `$D9A8`. Witness: L1 24 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/play2` 9, `stage1/missions` 8, `stage1/play` 4 and 3 more) |
| Called from | `FitOrRemoveWeapon` |
| Calls | `NumberToDigits` |

#### `SlotZoneB` (`$C165`)

**Zone of the slot at the top right: C = `$24` (slot record `$836E`)**

Called through PointerZones `$6D42` (StoresZones). Witness: L1 3 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play2` 2, `stage1/play` 1) |
| Calls | `FitOrRemoveWeapon` (tail) |

#### `SlotZoneA` (`$C169`)

**Zone of the slot at the top left: C = `$1E` (slot record `$8368`)**

Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 873 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/c1` 1 and 3 more) |
| Calls | `FitOrRemoveWeapon` (tail) |
| Reads | `$8368`-`$837A` (`WeaponSlots`); `$C11B`-`$C11C` (`PayloadWeightOp+1`); `$C19C` (`SlotTypeOp+1`); `$C371`-`$C37A` (`CurrentWeapon`, `WeaponRecords`) |
| Writes | `$8368`-`$836D` (`WeaponSlots`); `$83BF` (`PointerShown+1`); `$C11B`-`$C11C` (`PayloadWeightOp+1`); `$C19C` (`SlotTypeOp+1`); `$C1D5`-`$C1D6` (`SlotWeightOp+1`); `$C1E7` (`SlotAmmoOp+1`) |

#### `SlotZoneC` (`$C16D`)

**Zone of the slot at the bottom left: C = `$2A` (slot record `$8374`)**

Witness: L1 3 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play2` 2, `stage1/play` 1) |
| Calls | `FitOrRemoveWeapon` (tail) |

#### `SlotZoneD` (`$C171`)

**Zone of the slot at the bottom right: C = `$30` (slot record `$837A`)**

Falls into FitOrRemoveWeapon. Witness: L1 3 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play2` 2, `stage1/play` 1) |
| Calls | `FitOrRemoveWeapon` (falls into) |

#### `FitOrRemoveWeapon` (`$C173`)

**Fit the shown weapon into slot `$834A`+C, or take out the weapon that is in it**

Three POKEs of the release's .pok patch it (bank 6, the stores screen): Ammo Number Is Not Exceeded 1 at `$C1AE` (`JP Z,$C235` becomes `LD BC,nn`), Infinite Payload Weight 0 at `$C1B9` (the `ADD HL,BC` of the weight becomes NOP), No Weight Limit 58 at `$C1C6` (`JP NC,$C23A` becomes `LD A,(nn)`).

Input: C the slot's offset from `$834A`. A slot record is the weapon's type, its weight (word), the icon's column and line, its ammunition. An empty slot: the weapon's count in the slots is compared with its maximum (record +2; equal: MaxNumberText `$D990`), the new total with 1001 kg (PayloadExceededText `$D963`); when both pass, the slot gets the type, weight and ammunition, DrawSlotIcon `$C263` draws the icon, and PrintPayloadWeight the new total. A full slot: RemoveWeapon clears it, subtracts its weight and blanks the icon (ClearSlotIcon `$C25C`).

Around every change the interrupt's pointer job is off (`$83BF` = 0) and the pointer is put back (RestorePointerBackground `$D251`, SavePointerBackground `$D0CA`). An error message stays for 60 frames (StoresMessageTimer `$C2C0`). Witness: L1 24 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/play2` 9, `stage1/play` 4) |
| Called from | `SlotZoneB` (tail), `SlotZoneA` (tail), `SlotZoneC` (tail), `SlotZoneD` (falls into) |
| Calls | `PrintPayloadWeight`, `DrawSlotIcon`, `SavePointerBackground`, `RestorePointerBackground` |
| Reads | `$8368`-`$837E` (`WeaponSlots`); `$C11B`-`$C11C` (`PayloadWeightOp+1`); `$C19C` (`SlotTypeOp+1`); `$C23A` (`PayloadExceeded`); `$C371`-`$C3FE` (`CurrentWeapon`, `WeaponRecords`) |
| Writes | `$8368`-`$837F` (`WeaponSlots`); `$83BF` (`PointerShown+1`); `$C11B`-`$C11C` (`PayloadWeightOp+1`); `$C19C` (`SlotTypeOp+1`); `$C1D5`-`$C1D6` (`SlotWeightOp+1`); `$C1E7` (`SlotAmmoOp+1`) |

#### `ClearSlotIcon` (`$C25C`)

**Draw a blank icon (the back buffer's `$92C1`) into the slot at column C', line A**

Falls into DrawSlotIcon with HL' = `$92C1`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawSlotIcon` (`$C263`)

**Draw the 3 x 24 icon at HL' into a slot: column C', pixel line A**

The line address table `$6500`. The first 8 lines are copied two bytes wide one column to the right, the next 16 three bytes wide. Witness: L1 24 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 4,606 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/play2` 9, `stage1/missions` 8, `stage1/play` 4 and 3 more) |
| Called from | `FitOrRemoveWeapon` |
| Reads | `$6560`-`$658F` (`ScreenRowTable+96`); `$65C0`-`$65EF` (`ScreenRowTable+192`); `$F09D`-`$F0E3` (`IconK40Mortar+1`); `$F12D`-`$F48B` (`IconSlamLaser+1`, `IconBansheeIRSS`, `IconBansheeRRSS`, `IconPhoenixIRSA` and 8 more) |
| Writes | `$40D3`-`$491E` (screen); `$4993`-`$499E` (screen); `$49B2`-`$4A1E` (screen); `$4A93`-`$4A9E` (screen); `$4AB2`-`$4B1E` (screen); `$4B93`-`$4B9E` (screen); 9 more ranges |

#### `ResetStores` (`$C2A1`)

**A RET: the slot clearing that follows is switched off**

Called by StoresScreen `$CACE`. The first byte is `RET`, so ResetStoresBody never runs; ClearSlots `$CC01` does the work instead. Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/c1` 1 and 3 more) |
| Called from | `StoresScreen` |

#### `ResetStoresBody` (`$C2A2`)

**Clear the 9 records at `$834A`, the payload weight and the hook `$A9B9`**

Known only from the code: behind the `RET` of ResetStores. Clears the first three bytes of nine 6-byte records from `$834A`, the weight `$C11B` = 0, `$A9B9` = `$6BB0` (NoAction).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `StoresMessageTimer` (`$C2C0`)

**Count down the error message; at 0 clear the message line and print the payload again**

Called every frame by StoresScreen. The counter is the operand `$C2C1` of the first instruction (60 after a message). At 0: ScreenRowFill `$6D22`, the box PayloadLineBox, PayloadLineText `$D936`, PrintPayloadWeight, the pointer put back. Witness: L1 2525 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 121 calls, 2,662 t-states own (0.00 %) |
| Runs (the other recordings) | 2,525 calls (`stage1/play2` 997, `stage1/missions` 780, `stage1/play` 412 and 3 more) |
| Called from | `StoresScreen` |

#### `ShowWeapon` (`$C2FE`)

**Show the weapon CurrentWeapon points at: its icon, its description, its model**

ClearWeaponPanel `$C363`, CopyGraphic `$6D7F` of the 3 x 24 icon (record +5) at line `$30`, column 2, PrintString of the description (record +7), and the model (record +9) into StoresModelOp, the operand `$CB3B` of the stores' 3D loop. Witness: L1 54 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 281 t-states own (0.00 %) |
| Runs (the other recordings) | 54 calls (`stage1/play2` 32, `stage1/play` 11, `stage1/missions` 8 and 3 more) |
| Called from | `NextWeapon` (tail), `StoresScreen` |
| Calls | `ClearWeaponPanel` |
| Reads | `$C371`-`$C402` (`CurrentWeapon`, `WeaponRecords`) |
| Writes | `$CB3B`-`$CB3C` (`StoresModelOp+2`) |

#### `NextWeapon` (`$C32E`)

**Zone: the next record of WeaponRecords (the first again after the end mark), then ShowWeapon**

Witness: L1 39 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 39 calls (`stage1/play2` 29, `stage1/play` 10) |
| Calls | `ShowWeapon` (tail) |
| Reads | `$C371`-`$C3F8` (`CurrentWeapon`, `WeaponRecords`) |
| Writes | `$C371`-`$C372` (`CurrentWeapon`) |

#### `PreviousWeapon` (`$C347`)

**Zone: the record before (the last one before the start mark), then ShowWeapon**

Known only from the code: in StoresZones (`$CBD0`), but no recording clicks it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ClearWeaponPanel` (`$C363`)

**Clear 48 pixel lines of 11 bytes at column 3 from line `$30` (the weapon's icon and text)**

ScreenRowFill `$6D22` with 0. Witness: L1 54 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 50 t-states own (0.00 %) |
| Runs (the other recordings) | 54 calls (`stage1/play2` 32, `stage1/play` 11, `stage1/missions` 8 and 3 more) |
| Called from | `ShowWeapon` |

#### `StoresScreen` (`$CA8B`)

**The stores: picture, slots, the weapon and its turning model, until the mission starts**

Pointer job off, the hooks `$7256`, `$9A93`, `$83F1` cleared, the arrow pointer, the clip mark `$A17C` = `$5F`, Bank3Fill5F `$74CD`, ClearSlots `$CC01`, DrawBank7Picture `$C713` (PicStores), the view parameters, ResetStores, the four play hooks `$6A46-$6A55` = NoAction `$6BB0`, the first weapon (ShowWeapon), PayloadLineText, StoresGraphicA-C, StoresTitleBox, StoresPointerLimits `$D337`, the stores blit (`$83E6` = BlitStoresView `$D0A0`), SetStoresWindow `$D102`.

StoresLoop: StartViewPass, the weapon's model by Bank3Render (IX = StoresModelOp's operand), RequestViewBlit, the turn `$68E7`, PointerZones, StoresMessageTimer, until the view flag. Then: ShowWaitPointer, the 3D blit back, ResetCollisionTables `$6928` (bank 0), StoresToGauges, the object table `$762C` cleared (23 records of 60 bytes, the first byte `$FF`), `$7BFD-$7C05` = `$FF`, NumberObjectRecords, the mission's header patched (`$7E2C`), the score `$68E2-$68E5` cleared, the clock stopped, Bank3FillFF, `$83F1` = `RET`, NextView (StartMission). Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 58,047 t-states own (0.01 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 1 and 3 more) |
| Calls | `ResetStores`, `StoresMessageTimer`, `ShowWeapon`, `ShowWaitPointer`, `ClearSlots`, `StoresToGauges`, `NumberObjectRecords`, `SavePointerBackground`, `SetStoresWindow`, `StoresPointerLimits` |
| Reads | `$68E7` (`MissionScore+5`); `$6A6D` (`ViewChangeFlag+1`); `$70A3`-`$70A4` (`BriefingTextOnce+5`); `$762C`-`$7B8F` (`PlayerY+22`); `$DCB1`-`$DCE3` (`MapObjects+49`); `$DD11`-`$DD13` (`MapObjects+145`) |
| Writes | `$68E2`-`$68E7` (`MissionScore`); `$6A46`-`$6A56` (`PlayLoop+58`); `$7256` (`FirstFrameHook`); `$762C`-`$7B90` (`PlayerY+22`); `$7BFD`-`$7C05` (`FailReason+4`); `$7DFB` (`ClockTick`); 10 more ranges |

#### `ShowWaitPointer` (`$CBF4`)

**Pointer job off, the boxed shape WaitPointer, DrawPointer**

Called when a screen is left. Witness: L1 97 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 265 t-states own (0.00 %) |
| Runs (the other recordings) | 97 calls (`stage1/missions` 34, `stage1/menu` 28, `stage1/play2` 12 and 7 more) |
| Called from | `TitleLoop`, `MissionCatalogueScreen`, `BriefingScreen`, `StoresScreen`, `MissionStatusScreen` |
| Calls | `DrawPointer` (tail) |
| Writes | `$83BF` (`PointerShown+1`); `$D283`-`$D284` (`ShiftPointer+1`) |

#### `ClearSlots` (`$CC01`)

**Empty the four slot records, the payload weight = 0, the hook `$A9B9` = NoAction**

Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 220 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/c1` 1 and 3 more) |
| Called from | `StoresScreen` |
| Writes | `$8368`-`$837A` (`WeaponSlots`); `$A9B9`-`$A9BA` (`l_A9A0+25`); `$C11B`-`$C11C` (`PayloadWeightOp+1`) |

#### `StoresToGauges` (`$CC1B`)

**The four damage values `$8301-$8304` = `$7F`, each weapon record of `$834A` to a gauge of `$68AB`**

Nine 6-byte records: a fitted one (non-zero) gives the gauge `$5F`, an empty one 0. `$7C57` = `$3F00`, `$7578` and `$68E8` cleared. Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 950 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 1 and 3 more) |
| Called from | `StoresScreen` |
| Reads | `$834A`-`$837A` (`DamageBoardRecords`) |
| Writes | `$68AB`-`$68E8` (`GaugeRecords`); `$7578` (`AwolState`); `$7C57`-`$7C58` (`Fuel`); `$8301`-`$8304` (`Armour`) |

#### `BlitStoresView` (`$D0A0`)

**The stores' blit: 48 lines of 9 bytes of the back buffer to the screen (line table `$65C0`)**

Run by the interrupt through ViewBlit `$83E6`; the stack walks the line address table. Witness: L1 2525 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 121 calls, 2,247,213 t-states own (0.34 %) |
| Runs (the other recordings) | 2,525 calls (`stage1/play2` 997, `stage1/missions` 780, `stage1/play` 412 and 3 more) |
| Reads | `$8AF4`-`$8FFC` (`BackBuffer+3`); `$9014`-`$901C` (`BackBuffer+1315`); `$9034`-`$903C` (`BackBuffer+1347`); `$9054`-`$905C` (`BackBuffer+1379`); `$9074`-`$907C` (`BackBuffer+1411`); `$9094`-`$909C` (`BackBuffer+1443`); 2 more ranges |
| Writes | `$4883`-`$502B` (screen); `$5103`-`$512B` (screen); `$5203`-`$522B` (screen); `$5303`-`$532B` (screen); `$5403`-`$542B` (screen); `$5503`-`$552B` (screen); 3 more ranges |

### Bank 6: numbers

`src/bank6/numbers.asm`

#### `NumberToDigits` (`$C126`)

**Write HL as five ASCII digits at HL', then replace the leading zeros at `$D9AB` with C'**

Input: HL the number, HL' the destination, C' the character for a leading zero. DigitOf `$C155` for 10000, 1000, 100 and 10, then the units. Then the five digits of PaddedDigits `$D9AB` from the left: each `0` becomes C' until the first other digit; a number 0 keeps its last `0`. Witness: L1 104 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 283 t-states own (0.00 %) |
| Runs (the other recordings) | 104 calls (`stage1/missions` 76, `stage1/play2` 9, `stage1/m2erbe` 9 and 3 more) |
| Called from | `FormatGridPosition`, `PrintPayloadWeight` |
| Calls | `DigitOf` |
| Reads | `$D9AB`-`$D9AD` (`PaddedDigits`) |
| Writes | `$D9AB`-`$D9AF` (`PaddedDigits`) |

#### `DigitOf` (`$C155`)

**One decimal digit: A = how many times DE goes into HL, stored at HL' as ASCII**

Input: HL, DE. Output: HL the remainder, HL' advanced. Witness: L1 416 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 484 t-states own (0.00 %) |
| Runs (the other recordings) | 416 calls (`stage1/missions` 304, `stage1/m2erbe` 36, `stage1/play2` 36 and 3 more) |
| Called from | `NumberToDigits` |
| Writes | `$D9AB`-`$D9AE` (`PaddedDigits`) |

#### `LongToDigits` (`$D353`)

**Write the 32-bit number HL'HL as ten ASCII digits at DE**

LongDigitOf `$D3B4` for each power of ten. Witness: L1 4 (m10, menu, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/menu` 2, `stage1/m10` 1, `stage1/missions` 1) |
| Called from | `PrintScore` |
| Calls | `LongDigitOf` |
| Writes | `$D4A3` (`ScoreDigits+9`) |

#### `LongDigitOf` (`$D3B4`)

**One digit of HL'HL by BC'BC, stored at DE**

Witness: L1 36 (m10, menu, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 36 calls (`stage1/menu` 18, `stage1/m10` 9, `stage1/missions` 9) |
| Called from | `LongToDigits` |
| Writes | `$D49A`-`$D4A2` (`ScoreDigits`) |

### Bank 6: title

`src/bank6/title.asm`

#### `TitleMenu` (`$C409`)

**The title menu: picture, graphics, pointer, then the turning model until a zone is clicked**

Sound off (Bank0SoundOff `$72DE`), the shadow screen, the view parameters (`$9A6C`, `$9A8E`, `$9AB3`, `$9ABB`), DrawBank7Picture `$74AA` with `$F4E1`, CopyGraphic of TitleGraphicA, TitleGraphicB and TitleGraphicC, the attributes `$5920-$5A1F` to `$47`, the title's pointer limits, the pointer centred, the wide blit (`$83E6` = `$8A41`), SetTitleWindow `$D10E`, Bank4Start `$72C6`, TitleBox.

TitleLoop: StartViewPass `$9882`, the model through Bank3Render `$72BE` (IX = `$CA8B` of bank 3), RequestViewBlit `$988D`, the turn (`$68E7` += 6), PointerZones `$6D42`, until the view flag `$6A6D` is set; then ShowWaitPointer, WaitFrameDone, Bank4Call and NextView `$6A91`. Witness: L1 19 (c1, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 30,434 t-states own (0.00 %) |
| Runs (the other recordings) | 19 calls (`stage1/missions` 8, `stage1/menu` 4, `stage1/play2` 3 and 3 more) |
| Calls | `SavePointerBackground`, `SetTitleWindow`, `CataloguePointerLimits`, `SetPointerLimits` |
| Reads | `$68E7` (`MissionScore+5`); `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$5920`-`$5A1F` (screen); `$68E7` (`MissionScore+5`); `$7256` (`FirstFrameHook`); `$757A` (`AwolState+2`); `$7DC0`-`$7DC1` (`PointerPos`); `$83BF` (`PointerShown+1`); 5 more ranges |

#### `TitleLoop` (`$C4AD`)

**TitleLoop**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/death`, `stage1/m10`, `stage1/m2ocean` and 1 more) |
| Calls | `ShowWaitPointer` |
| Reads | `$68E7` (`MissionScore+5`); `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$68E7` (`MissionScore+5`) |

### Bank 6: password

`src/bank6/password.asm`

#### `ShowPassword` (`$C4FC`)

**Show the password of the progress so far: "THIS IS YOUR ENTRY STRING." and the ten characters**

Screen node `$74FE` (from the mission status screen). ClearMenuScreen, EncodePassword, PasswordToChars, PrintString of EntryStringText and PasswordText `$CEF6`, a delay (Delay `$CD63`), a key, ScreenZero and NextView. Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/menu` 1) |
| Calls | `ClearMenuScreen`, `Delay`, `EncodePassword`, `PasswordToChars` |
| Reads | `$8978` (`KeyState`) |

#### `ClearMenuScreen` (`$C527`)

**Clear the shadow screen's pixels and fill its attributes from the box `$C74A`**

PageShadowScreen `$7268`, ScreenRowFill of 192 lines of 32 bytes with 0, AttrBox `$C74A`. Witness: L1 6 (c1, menu).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 94 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/menu` 5, `stage1/c1` 1) |
| Called from | `ShowPassword`, `PasswordScreen`, `OptionsScreen` |

#### `PasswordScreen` (`$C578`)

**The level entry screen: read ten characters, check them, take over the flags and the score**

Node `$74F8` (from the title). ClearMenuScreen, PasswordPrompt, the buffer filled with spaces, ReadPassword `$C620`; when the view flag is set (a click elsewhere), back. Otherwise CharsToPassword, DecodePassword: a bad checksum prints "INVALID PASSWORD" and asks again; a good one copies the score to Score `$CC79`, the ten flags to MissionsDone `$6799`, counts them into MissionsCompleted `$CC93`, ScreenZero and NextView. Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/menu` 1) |
| Calls | `ClearMenuScreen`, `ReadPassword`, `DecodePassword`, `CharsToPassword` |
| Reads | `$6799`-`$67A2` (`MissionsDone`); `$6A6D` (`ViewChangeFlag+1`); `$CE7D`-`$CE8A` (`DecodedFlags`, `DecodedScore`) |
| Writes | `$6799`-`$67A2` (`MissionsDone`); `$C60E`-`$C617` (`PasswordBuffer`); `$CC79`-`$CC7C` (`Score`); `$CC93` (`MissionsCompleted`) |

#### `ReadPassword` (`$C620`)

**A short delay, the key state cleared, then EditLine at the screen place of the entry**

EditLine `$C644` with HL = PasswordBuffer, DE = `$488A` (the pixel address), BC = `$598A` (the attribute address). Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `PasswordScreen` |
| Calls | `EditLine` |
| Writes | `$8979` (`KeyCode`) |

#### `EditLine` (`$C644`)

**Edit a line of up to 10 characters: keys add, DELETE takes back, ENTER ends when it is full**

Input: HL the buffer (set to `$C60E` here), DE the screen address, BC the cursor's attribute address. The state is in operands: the cursor's attribute address CursorAttrPtr, the end of the line (EditEndOp), the length (EditLengthOp), the maximum (EditMaxOp). Each key from WaitKey `$C6EC`: codes 0-1 ignored, 2 leaves through ScreenZero `$705A`, 3 (ENTER) ends when the length is the maximum, 4 (DELETE) takes one back, the others are added up to 14. PrintRawString `$C6FC` redraws the line after every key. Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `ReadPassword` |
| Reads | `$C6A0`-`$C6A1` (`EditEndOp+1`); `$C6B4` (`EditMaxOp+1`); `$C6E4` (`EditLengthOp+1`); `$C6FA`-`$C6FB` (`CursorAttrPtr`); `$C727`-`$C728` (`EditLineBuffer`) |
| Writes | `$598A`-`$5994` (screen); `$C60E`-`$C619` (`PasswordBuffer`, `PasswordLeftover`); `$C677`-`$C678` (`EditRedraw+4`); `$C6A0`-`$C6A1` (`EditEndOp+1`); `$C6B4` (`EditMaxOp+1`); `$C6E4` (`EditLengthOp+1`); 2 more ranges |

#### `EditLineAt` (`$C655`)

**Variant entry: A = the maximum, HL = the buffer, then EditLineStart**

Known only from the code: nothing calls it.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `WaitKey`, `PrintRawString` |

#### `EditAddSpace` (`$C6AC`)

**Unused: A = space, then the add path EditAddChar**

Known only from the code: no jump reaches it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `WaitKey` (`$C6EC`)

**Wait for a new key (bit 0 of KeyState `$8978`), clear the bit, A = the key code (`$8979`)**

Witness: L1 286697 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12 calls (`stage1/menu` 12) |
| Called from | `EditLineAt` |
| Reads | `$8978`-`$8979` (`KeyState`) |
| Writes | `$8978`-`$8979` (`KeyState`) |

#### `PrintRawString` (`$C6FC`)

**Draw the 0-terminated string at HL straight onto the screen at DE with the 8x8 font**

Characters `$20-$7F` take the glyph Font8x8 + 8 (c - `$20`), the others the space; 8 lines down the screen third, one column a character. No attributes, no control codes. Witness: L1 77 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 11 calls (`stage1/menu` 11) |
| Called from | `EditLineAt` |
| Reads | `$C60E`-`$C619` (`PasswordBuffer`, `PasswordLeftover`); `$F5E4`-`$F5EB` (`Font8x8`); `$F6AC`-`$F6B3` (`Font8x8+200`) |
| Writes | `$488A`-`$4894` (screen); `$498A`-`$4994` (screen); `$4A8A`-`$4A94` (screen); `$4B8A`-`$4B94` (screen); `$4C8A`-`$4C94` (screen); `$4D8A`-`$4D94` (screen); 2 more ranges |

#### `EncodePassword` (`$CE2E`)

**Pack MissionsDone and Score into the ten 5-bit values at `$CEFB`**

Eight values: 4 bits of the score (ScoreBits `$CF06`) and in bit 4 the flag of missions 1-8; the ninth and tenth: the flags of missions 9-10 (value 8 bits 0, 1) and an 8-bit checksum, the XOR of the score's four bytes, split as its low 3 bits in value 8 (bits 2-4) and its high 5 bits in value 9. Witness: L1 1 (menu).

A non-zero score: m1complete frame 22160 ("C5989999PB", score 500, mission 1), m4complete 21956 ("H59K9999PK", score 2500, missions 1 and 4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `ShowPassword` |
| Calls | `ScoreBits` |
| Reads | `$6799`-`$67A2` (`MissionsDone`); `$CC79`-`$CC7C` (`Score`) |
| Writes | `$CEFB`-`$CF04` (`PasswordValues`) |

#### `DecodePassword` (`$CE8B`)

**Unpack the ten values at `$CEFB` into DecodedFlags and DecodedScore; Z when the checksum agrees**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `PasswordScreen` |
| Reads | `$CE87`-`$CE8A` (`DecodedScore`); `$CEFB`-`$CF04` (`PasswordValues`) |
| Writes | `$CE7D`-`$CE8A` (`DecodedFlags`, `DecodedScore`) |

#### `ScoreBits` (`$CF06`)

**A = the next A bits of the score at HL' (E' bits left in the byte)**

Witness: L1 8 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/menu` 8) |
| Called from | `EncodePassword` |
| Reads | `$CC7A`-`$CC7D` (`Score+1`, `PrintScore`) |

#### `PasswordToChars` (`$CF1C`)

**Map the ten values at `$CEFB` to characters through PasswordAlphabet**

Twelve `NOP`s at `$CF26` are room left for a patch. Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `ShowPassword` |
| Reads | `$CEFB`-`$CF04` (`PasswordValues`); `$CF5F` (`PasswordAlphabet`) |
| Writes | `$CEFB`-`$CF04` (`PasswordValues`) |

#### `CharsToPassword` (`$CF3E`)

**Map the ten typed characters to their places in PasswordAlphabet**

An unknown character gives 4 (B = 0 after the search: 36 AND 31); D, E, F and G give 0-3 like 9876. Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/menu` 1) |
| Called from | `PasswordScreen` |
| Reads | `$C60E`-`$C617` (`PasswordBuffer`); `$CF5F` (`PasswordAlphabet`) |
| Writes | `$CEFB`-`$CF04` (`PasswordValues`) |

### Bank 6: briefing

`src/bank6/briefing.asm`

#### `BriefingScreen` (`$C98A`)

**The briefing: picture, three graphics, the mission text, then the zones with the map blit**

The shadow screen, ShowBriefingMapOnce armed (`$7084` = 0), the Dragonfly's title hook `$6C56` = `RET`, the arrow pointer, SetBriefingBlit `$DBAA`, CopyMissionText, DrawBank7Picture `$E949`, BriefingBoxes, BriefingGraphicA-C, PrintString (`$70A3`), the map blit (`$83E6` = BlitMapView `$DBBD`), PointerZones until the view flag; then the 3D blit back (`$8999`) and NextView. Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/menu` 10) |
| Calls | `ShowWaitPointer`, `SavePointerBackground`, `SetBriefingBlit` |
| Reads | `$6A6D` (`ViewChangeFlag+1`); `$70A3`-`$70A4` (`BriefingTextOnce+5`) |
| Writes | `$6C56` (`BriefPageOnce`); `$7084` (`ShowBriefingMapOnce`); `$83BF` (`PointerShown+1`); `$83E6`-`$83E7` (`MenuJobs+7`); `$D283`-`$D284` (`ShiftPointer+1`) |

#### `CopyMissionTextB6` (`$CA23`)

**CopyMissionText `$70F6` called from bank 6**

Called by LoadMissionIfAllowed `$759A`. Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 27 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/c1` 1 and 3 more) |

#### `CopyMissionTextOld` (`$CA27`)

**Unused: an older copy of the mission's texts from the back buffer to `$F9C4`**

Known only from the code: nothing calls it. Once per mission (the operand `$CA2E`), from the catalogue's copy at `$8AF1`; sets `$70A3`, `$7D3C`, `$7D39`, `$7C55` and calls `$7D35`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### Bank 6: results

`src/bank6/results.asm`

#### `PrintFinalScore` (`$CC54`)

**Unused: the mission's score as ten digits into `$D461`, then FinalScoreText**

Known only from the code: nothing calls it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DotLeadingZeros` (`$CC6A`)

**Replace the leading "0" of the nine digits at `$D49A` with "[" (a full stop in SmallFont `$7C59`)**

Witness: L1 4 (m10, menu, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/menu` 2, `stage1/m10` 1, `stage1/missions` 1) |
| Called from | `PrintScore` |
| Reads | `$D49A`-`$D4A2` (`ScoreDigits`) |
| Writes | `$D49A`-`$D4A2` (`ScoreDigits`) |

#### `PrintScore` (`$CC7D`)

**Print the missions completed and the score (StatusText `$D46C`)**

LongToDigits `$D353` of Score into `$D49A`, DotLeadingZeros, PrintString `$D46C`. Witness: L1 4 (m10, menu, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/menu` 2, `stage1/m10` 1, `stage1/missions` 1) |
| Called from | `MissionStatusScreen` |
| Calls | `DotLeadingZeros`, `LongToDigits` |
| Reads | `$CC79`-`$CC7C` (`Score`) |

#### `MissionCompleteScreen` (`$CD1E`)

**Mission completed: PicCompletion, the score added, the flag set, the mission's text**

Sound off, DrawBank7Picture `$E51E`, Score += the mission's score, MissionsDone[mission] = `$FF`, PrintString (`$7C55`), SaveLoadedMission `$CD77`, the main screen, Delay, MissionsCompleted + 1, then the key wait of MissionFailedScreen (EndScreenKey). The completion recordings run it on page 6:

Witness (not an L1 build of the json): m1complete frames 21560-21721, MissionsDone and Score written at 21590, 32 frames after HelicarrierHit; m4complete 21301-21462 (work/stage2/complete-NOTES.md).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Delay` (`$CD63`)

**A delay of five times 65535 loops**

Witness: L1 36 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 17,039,304 t-states own (2.58 %) |
| Runs (the other recordings) | 36 calls (`stage1/missions` 17, `stage1/play2` 4, `stage1/search` 3 and 7 more) |
| Called from | `ShowPassword` |

#### `SaveLoadedMission` (`$CD77`)

**Put LoadedMission's two bytes (`$7E2C`) into the mission's header (`$70A3` +1 and +3)**

Witness: L1 13 (m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 1 more) |
| Called from | `QuitPrompt` |
| Reads | `$70A3`-`$70A4` (`BriefingTextOnce+5`); `$7E2C`-`$7E2D` (`LoadedMission`) |
| Writes | `$DCB1`-`$DCE3` (`MapObjects+49`); `$DD11`-`$DD13` (`MapObjects+145`) |

#### `MissionFailedScreen` (`$CD84`)

**Mission failed: PicCompletion, "MISSION FAILED." and the reason, then a key**

Known only from the code: no recording runs it on page 6.

Seen in work/stage2/rec/fuel (a POKE recording, never the image: Fuel `$7C57` = 32 at frame 7704): the failure reason `$7BF9` = `$ED` by frame 7904, MissionFailedScreen at frame 7862 shows PicCompletion with "MISSION FAILED." / "RAN OUT OF FUEL.", SaveLoadedMission `$CD77` at 7892, then the title (SetTitleWindow `$D10E`, the music from Bank4Start) at 8051: a failure ends at the title, there are no lives.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `MissionStatusScreen` (`$CDBF`)

**The mission status card: PicMissionStatus, two graphics, the score, then the zones**

DrawBank7Picture `$EC82`, StatusGraphicB (11 x 16), StatusGraphicA (10 x 32), the boxes, PrintScore, the pointer, PointerZones (StatusScreenZones) until the view flag, ShowWaitPointer, NextView. Witness: L1 4 (m10, menu, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/menu` 2, `stage1/m10` 1, `stage1/missions` 1) |
| Calls | `ShowWaitPointer`, `PrintScore`, `SavePointerBackground` |
| Reads | `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$83BF` (`PointerShown+1`) |

#### `NumberObjectRecords` (`$CE1F`)

**Write 0-23 into the byte before each 60-byte record from `$762B`**

Called by StoresScreen after the object table is cleared. Witness: L1 15 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 928 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 3 more) |
| Called from | `StoresScreen` |
| Writes | `$762B`-`$79EB` (`PlayerY+21`); `$7A27` (`PlayerY+1041`); `$7A63` (`PlayerY+1101`); `$7A9F` (`PlayerY+1161`); `$7ADB` (`PlayerY+1221`); `$7B17` (`HelicarrierRecord+59`); 2 more ranges |

### Bank 6: panel

`src/bank6/panel.asm`

#### `StatusViewMessage` (`$D3C9`)

**Once per message: "TANK HAS BEEN HIT" or "COLLISION OCCURED", then MessageOnce off**

Returns when MessageOnce `$7D5D` is already a `RET`; else the timer `$87D7` = 100, the text by bit 4 of `$7D64`, and `$7D5D` = `RET`. Witness: L1 43 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 43 calls (`stage1/missions` 34, `stage1/play` 5, `stage1/m2erbe` 4) |
| Reads | `$7D5D` (`MessageOnce`) |

#### `ShowDamageColours` (`$D4A5`)

**Colour the Dragonfly's damage boxes by the four damage values `$8301-$8304`**

DamageColour for each, AttrBoxAt `$6CFD` with the records of DamageBoxes. Witness: L1 3 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play` 3) |
| Calls | `DamageColour` |
| Reads | `$8301`-`$8304` (`Armour`) |

#### `DamageColour` (`$D4EE`)

**B = DamageColourTable[A / 32]**

Witness: L1 12 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12 calls (`stage1/play` 12) |
| Called from | `ShowDamageColours` |
| Reads | `$D520` (`DamageColourTable+3`) |

#### `PanelAttributes` (`$D521`)

**The cockpit panel's attributes: a cleared box, two boxes and the gauge colours**

Called by PanelSetup `$6B32`. ScreenRowFill, AttrBox PanelBoxB and PanelBoxA, single attributes at `$5A48-$5AAA` and `$580A-$5859`, then FillPanelRows `$6AAB`. Witness: L1 27 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 583 t-states own (0.00 %) |
| Runs (the other recordings) | 27 calls (`stage1/missions` 16, `stage1/play` 4, `stage1/play2` 3 and 3 more) |
| Writes | `$580A`-`$5819` (screen); `$582A`-`$5839` (screen); `$584A`-`$5859` (screen); `$5A48`-`$5A4A` (screen); `$5A68`-`$5A6A` (screen); `$5A88`-`$5A8A` (screen); 1 more ranges |

#### `UpdatePanelBars` (`$D58C`)

**The four bars of the cockpit panel**

Called by UpdateSlotBars `$7327`. Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 7,198 t-states own (0.00 %) |
| Runs (the other recordings) | 3,601 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 3 more) |
| Calls | `DrawHeadingStrip`, `DrawSpeedBar`, `DrawFuelBar` (tail), `DrawBearing` |

#### `DrawHeadingStrip` (`$D598`)

**Redraw the compass strip from the heading `$7612` (`$75F0` + `$22`) when it changed**

Shapes from BarShapesB, shifted to the pixel, five lines 12 bytes apart. Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 39,813 t-states own (0.01 %) |
| Runs (the other recordings) | 3,601 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 3 more) |
| Called from | `UpdatePanelBars` |
| Reads | `$6664`-`$666D` (`ScreenRowTable+356`); `$7612` (`PlayerHeading`); `$D77F`-`$D7BA` (`BarShapesB`) |
| Writes | `$52D6`-`$52D9` (screen); `$53D6`-`$53D9` (screen); `$54D6`-`$54D9` (screen); `$55D6`-`$55D9` (screen); `$56D6`-`$56D9` (screen); `$D5A2` (`HeadingLastOp+1`); 2 more ranges |

#### `DrawSpeedBar` (`$D612`)

**The speed bar: `$7E8E` = abs(speed), line `$90` column 8, when it changed**

Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 5,103 t-states own (0.00 %) |
| Runs (the other recordings) | 3,601 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 3 more) |
| Called from | `UpdatePanelBars` |
| Reads | `$7E8E` (`MissionParams+12`) |
| Writes | `$D616` (`DrawSpeedBar+4`) |

#### `DrawFuelBar` (`$D629`)

**The fuel bar: Fuel high byte `$7C58` / 2, line `$90` column 10, redrawn every pass (no change test)**

Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 6,254 t-states own (0.00 %) |
| Runs (the other recordings) | 3,601 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 3 more) |
| Called from | `UpdatePanelBars` (tail) |
| Reads | `$7C58` (`Fuel+1`) |

#### `DrawBearing` (`$D637`)

**The bearing arrow: ApiVector01's bearing less the heading `$7612`, when it changed (shapes BarShapesA), x 32-55 y 138-142**

Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 43,813 t-states own (0.01 %) |
| Runs (the other recordings) | 3,601 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 3 more) |
| Called from | `UpdatePanelBars` |
| Reads | `$6614`-`$661D` (`ScreenRowTable+276`); `$7612` (`PlayerHeading`); `$D6A3`-`$D6D9` (`BarShapesA`) |
| Writes | `$5224`-`$5226` (screen); `$5324`-`$5326` (screen); `$5424`-`$5426` (screen); `$5524`-`$5526` (screen); `$5624`-`$5626` (screen); `$D646` (`DrawBearing+15`); 1 more ranges |

### Bank 6: map

`src/bank6/map.asm`

#### `ClearQuitArea` (`$D9B2`)

**Clear the screen lines of the quit prompt**

Witness: L1 13 (m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 1 and 1 more) |
| Called from | `QuitPrompt` |
| Reads | `$4080`-`$49CA` (screen); `$4A00`-`$4ACA` (screen); `$4B00`-`$4BCA` (screen); `$4C00`-`$4CCA` (screen); `$4D00`-`$4DCA` (screen); `$4E00`-`$4FAA` (screen); 1 more ranges |
| Writes | `$4080`-`$49E2` (screen); `$49FD`-`$4AE2` (screen); `$4AFD`-`$4BE2` (screen); `$4BFD`-`$4CE2` (screen); `$4CFD`-`$4DE2` (screen); `$4DFD`-`$4FC2` (screen); 1 more ranges |

#### `QuitPrompt` (`$DA09`)

**"Are you sure you want to quit? Yes/No.": Y ends the mission, N goes back**

ClearQuitArea, the attributes `$5880-$59CA` to `$47`, QuitText, a key: `Y` StartViewPass, the shadow screen, the clock stopped, SaveLoadedMission, ScreenEight `$704E`; `N` `$8822`, RequestViewBlit, `JP $8872`. Witness: L1 13 (m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 1 more) |
| Calls | `SaveLoadedMission`, `ClearQuitArea` |
| Reads | `$5880`-`$59C9` (screen); `$8978`-`$8979` (`KeyState`) |
| Writes | `$5880`-`$59E2` (screen); `$59FD`-`$59FE` (screen); `$7DFB` (`ClockTick`) |

#### `StatusMapFrame` (`$DA8C`)

**The status view's legend frame: the box `$DAC6` and 7 cleared lines**

Called by StatusLoop `$6BFC`. Witness: L1 10 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/missions` 8, `stage1/m2erbe` 1, `stage1/play` 1) |

#### `BriefingMapFrame` (`$DACB`)

**The briefing map's legend frame: the box `$DB06` and 10 cleared lines**

Called by ShowPauseOnce `$7084`. Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/menu` 10) |

#### `StatusMap` (`$DB15`)

**DrawStatusMap, then the legend (StatusMapLegend)**

Called by StatusLoop `$6C1D`. Witness: L1 40 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 40 calls (`stage1/missions` 34, `stage1/m2erbe` 4, `stage1/play` 2) |
| Calls | `DrawStatusMap` |

#### `DrawStatusMap` (`$DB1C`)

**The mission's map in the 3D window: a view from above, the objects and three markers**

The view (`$9A8E` = the operand `$DB1D`, `$9AB3` = `$DB23`, `$9A6C` = `$1B58`), MapDepth = 0, StartViewPass, DrawMapObjects, DrawMarker 0 at MarkerPosA, 1 at MarkerPosB and 2 at `$67A7` (the player), the view's position to GridXOp and GridYOp, RequestViewBlit. Witness: L1 50 (m2erbe, menu, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 50 calls (`stage1/missions` 34, `stage1/menu` 10, `stage1/m2erbe` 4 and 1 more) |
| Called from | `StatusMap`, `BriefingMap` |
| Calls | `DrawMarker`, `DrawMapObjects` |
| Reads | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A93` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$C0C7`-`$C0C8` (`GridYOp+1`); `$C0E2`-`$C0E3` (`GridXOp+1`); `$DBA8`-`$DBA9` (`MapDepth`) |

#### `BriefingMap` (`$DB64`)

**DrawStatusMap, then the briefing legend (BriefingMapLegend)**

Called by ShowPauseOnce `$7084`. Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/menu` 10) |
| Calls | `DrawStatusMap` |

#### `DrawMarker` (`$DB6B`)

**Marker A at the 24-bit position HL: the view moved there, DrawMarkerModel A**

Witness: L1 150 (m2erbe, menu, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 150 calls (`stage1/missions` 102, `stage1/menu` 30, `stage1/m2erbe` 12 and 1 more) |
| Called from | `DrawStatusMap` |
| Calls | `ReadMapCoord`, `DrawMarkerModel` |
| Reads | `$DB1D`-`$DB24` (`DrawStatusMap+1`) |
| Writes | `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`) |

#### `ReadMapCoord` (`$DB8D`)

**DE = the 24-bit coordinate at HL / 16**

Witness: L1 300 (m2erbe, menu, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 300 calls (`stage1/missions` 204, `stage1/menu` 60, `stage1/m2erbe` 24 and 1 more) |
| Called from | `DrawMarker` |
| Reads | `$67A7`-`$67AC` (`WorldVars+4`); `$DBF4`-`$DBFF` (`MarkerPosA`, `MarkerPosB`) |

#### `SetBriefingBlit` (`$DBAA`)

**BlitMapView from line table `$6550`, column 10**

Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/menu` 10) |
| Called from | `BriefingScreen` |
| Writes | `$DBC2`-`$DBCC` (`MapLinesOp+1`, `MapColumnOp`) |

#### `SetStatusBlit` (`$DBB6`)

**BlitMapView from line table `$6510`, column 7**

Called by StatusLoop `$6BCA`. Witness: L1 10 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/missions` 8, `stage1/m2erbe` 1, `stage1/play` 1) |
| Writes | `$DBC2`-`$DBCC` (`MapLinesOp+1`, `MapColumnOp`) |

#### `BlitMapView` (`$DBBD`)

**The map's blit: 96 lines of 18 bytes from the back buffer to the screen**

Run by the interrupt through ViewBlit `$83E6`; the stack walks the line address table (MapLinesOp), the column is MapColumnOp. Witness: L1 50 (m2erbe, menu, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 50 calls (`stage1/missions` 34, `stage1/menu` 10, `stage1/m2erbe` 4 and 1 more) |
| Reads | `$8AF1`-`$96E2` (`BackBuffer`) |
| Writes | `$4027`-`$501B` (screen); `$510A`-`$511B` (screen); `$520A`-`$521B` (screen); `$530A`-`$531B` (screen); `$540A`-`$541B` (screen); `$550A`-`$551B` (screen); 3 more ranges |

#### `DrawMapObjects` (`$E3F3`)

**Draw each object of MapObjects with its model (kind 0, 6, negative, other; 2 skipped)**

For each 6-byte record: X and Y from the coordinate tables, four corner vertices by ProjectMapPoint into the vertex buffers `$FD00`, and RunScript `$990F` with IX = MapModels (`$E512` kind 0, `$E534` kind 6, `$E51E` negative, `$E52A` other). Witness: L1 50 (m2erbe, menu, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 50 calls (`stage1/missions` 34, `stage1/menu` 10, `stage1/m2erbe` 4 and 1 more) |
| Called from | `DrawStatusMap` |
| Calls | `ProjectMapPoint` |
| Reads | `$DBF3`-`$DC1B` (`MissionData`, `MarkerPosA`, `MarkerPosB`, `MapCoordX`); `$DC40`-`$DC5B` (`MapCoordY`); `$DC80`-`$DD0F` (`MapObjects`); `$E46A`-`$E477` (`MapObjectLoop+110`) |
| Writes | `$E44D`-`$E477` (`MapObjectLoop+81`); `$E497` (`MapObjectLoop+155`); `$E4BE` (`MapObjectNext+2`); `$E4E8` (`ProjectXPositive+14`) |

#### `ProjectMapPoint` (`$E4CE`)

**One vertex: X and Y turned by the object's angle (through ApiVector14, SinCos8) into the vertex buffers**

Witness: L1 2448 (m2erbe, menu, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2,448 calls (`stage1/missions` 1,632, `stage1/menu` 480, `stage1/m2erbe` 256 and 1 more) |
| Called from | `DrawMapObjects` |
| Reads | `$DBA8`-`$DBA9` (`MapDepth`) |
| Writes | `$FD00`-`$FD07`; `$FE00`-`$FE07`; `$FF00`-`$FF07` |

#### `DrawMarkerModel` (`$E561`)

**Marker A: its points (MarkerPointLists) into the vertex buffers, then its script (MarkerScripts)**

Witness: L1 150 (m2erbe, menu, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 150 calls (`stage1/missions` 102, `stage1/menu` 30, `stage1/m2erbe` 12 and 1 more) |
| Called from | `DrawMarker` |
| Reads | `$DBA8`-`$DBA9` (`MapDepth`); `$E5B2`-`$E5BD` (`MarkerPointLists`, `MarkerScripts`); `$E603`-`$E623` (`MarkerPoints`, `MarkerPointsB`, `MarkerPointsC`) |
| Writes | `$E5AC`-`$E5AD` (`MarkerScriptOp+2`); `$FD00`-`$FD0D`; `$FE00`-`$FE0D`; `$FF00`-`$FF0D` |

#### `BlinkMarker` (`$E5BE`)

**Toggle the third marker's script between `$E5ED` and `$E5F7`**

Called by StatusLoop `$6C23`. Witness: L1 40 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 40 calls (`stage1/missions` 34, `stage1/m2erbe` 4, `stage1/play` 2) |
| Reads | `$E5BC`-`$E5BD` (`MarkerScripts+4`) |
| Writes | `$E5BC`-`$E5BD` (`MarkerScripts+4`) |

### Bank 6: options

`src/bank6/options.asm`

#### `OptionsScreen` (`$F8F4`)

**The options: print the devices, a key 1-5, the device to ControlDevice, its line highlighted**

ClearMenuScreen, OptionsText, the main screen; the key from KeyState `$8978` / `$8979`; the old line's attribute back to `$44` (HighlightedOp), the new line's to `$42`, ClickFlag cleared, ScreenZero, NextView. Witness: L1 4 (c1, menu).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 1,681,014 t-states own (0.25 %) |
| Runs (the other recordings) | 4 calls (`stage1/menu` 3, `stage1/c1` 1) |
| Calls | `ClearMenuScreen` |
| Reads | `$8978`-`$8979` (`KeyState`); `$F935`-`$F93E` (`OptionLines`) |
| Writes | `$67B6` (`ControlDevice`); `$6D43` (`PointerZones+1`); `$F913`-`$F914` (`HighlightedOp+1`); `$F960` (`OptionsText+33`); `$F978` (`OptionsText+57`); `$F9B7` (`OptionsText+120`) |


## Bank 7 (`src/bank7/bank7.json`)

Battle Command, Ocean 1990: RAM bank 7, paged at `$C000`, as its tape block loads it. Its entries are
`src/bank7/<module>.asm`, written from `src/bank7/bank7.ann` by `kit/mkgame.py --part src/bank7/bank7.json`; the
recordings: `work/stage1/c1g` (c1 from the game's entry at frame 23974, the loader left out: the title, the mission
tape, Blast Em Mission played), and `work/stage1/menu`, `work/stage1/missions`, `work/stage1/play`,
`work/stage1/play2`, `work/stage1/death`, `work/stage1/m2ocean`, `work/stage1/m2erbe`, `work/stage1/search`,
`work/stage1/m10`, `work/stage1/c1`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`pictures`](11-data-reference.md#bank-7-pictures) | `$C000`-`$FE8E` | 0 of 11 |
| [`unpack`](#bank-7-unpack) | `$FE8F`-`$FFFF` | 5 of 7 |

### Bank 7: unpack

`src/bank7/unpack.asm`

#### `UnpackPicture` (`$FE95`)

**Unpack the block at DE onto the screen from `$4000`, then set BRIGHT in every attribute**

Input: DE = a block of bank 7 (paged at `$C000`). Output: `$4000-$5AFF` the screen; BC, DE, HL, AF and the alternate set changed.

Clears the output count (`$FF9F`), takes the unpacked length into the compare at `$FEC5`, the table and stream addresses into UnpackVars, the extra offset bits into `$FF43`, the output pointer `$FF97` = `$4000`, the first byte through StartBits; then a token at a time (`$FECF`): 2 bits by GetBits, the type kept in `$FF36`. 01: 8 bits to PutByte. 11: 4 bits, the table's byte `NOT n AND $0F`. 0x: a count of 6 bits (0: 7 more bits, 1: 8 bits, 2: 8 + 6 bits); type 10 then an offset of 8 bits plus the extra bits, and the count bytes from output - offset; type 00 a bit: the run byte from the table (4 bits) or 8 bits, stored into `$FF8A`, count times. When the count reaches the length, `JP BrightenAttributes`.

Witness: L1 120 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

[Animation: `UnpackPicture` at work](img/routines/UnpackPicture.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 4,100,627 t-states own (0.62 %) |
| Runs (the other recordings) | 120 calls (`stage1/missions` 50, `stage1/menu` 28, `stage1/play2` 12 and 7 more) |
| Calls | `PutByte`, `BrightenAttributes` (tail), `GetBits`, `StartBits` |
| Reads | `$4000`-`$56CA` (screen); `$56E2`-`$578A` (screen); `$579C`-`$57BE` (screen); `$5800`-`$5ACB` (screen); `$C002`-`$C014` (`PicDamageBoard+2`); `$C715`-`$C727` (`PicStores+2`); 9 more ranges |
| Writes | `$FE8F`-`$FE94` (`UnpackVars`, `StreamPtr`, `TablePtr`); `$FEC6`-`$FEC7` (`LengthOp+1`); `$FF36`-`$FF43` (`TokenTypeOp+1`, `LongBitsOp`); `$FF8A`-`$FFA0` (`RunByteOp+1`, `PutByte`) |

#### `PutByte` (`$FF96`)

**Store A at the output pointer, advance it and count the byte**

Input: A. The pointer is the operand at `$FF97`, the count the operand at `$FF9F`. Output: HL = the new count.

Witness: L1 829440 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 34,560 calls, 3,445,979 t-states own (0.52 %) |
| Runs (the other recordings) | 829,440 calls (`stage1/missions` 345,600, `stage1/menu` 193,536, `stage1/play2` 82,944 and 7 more) |
| Called from | `UnpackPicture` |
| Writes | `$4000`-`$5AFF` (screen); `$FF97`-`$FFA0` (`PutByte+1`, `WrittenCountOp`) |

#### `BrightenAttributes` (`$FFA6`)

**OR `$40` (BRIGHT) into the 768 attributes `$5800-$5AFF`**

Every picture is shown bright; the blocks themselves keep BRIGHT off. Witness: L1 120 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 249,621 t-states own (0.04 %) |
| Runs (the other recordings) | 120 calls (`stage1/missions` 50, `stage1/menu` 28, `stage1/play2` 12 and 7 more) |
| Called from | `UnpackPicture` (tail) |
| Reads | `$5800`-`$5AFF` (screen) |
| Writes | `$5800`-`$5AFF` (screen) |

#### `GetBits` (`$FFB7`)

**Return the next A bits of the stream in A (low bits first), using the alternate set**

Input: A = 1-8. The alternate DE holds the bits not yet taken, HL' the next stream byte; the number of bits left in E' is the operand at `$FFBD`. When fewer are left than asked, the next byte goes into D' and DE' shifts right as far as the bits taken. Output: A = E' before the shift (the caller masks it). Witness: L1 359432 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 14,974 calls, 4,024,454 t-states own (0.61 %) |
| Runs (the other recordings) | 359,432 calls (`stage1/missions` 154,052, `stage1/menu` 72,804, `stage1/play2` 37,233 and 7 more) |
| Called from | `UnpackPicture` |
| Reads | `$C016`-`$C711` (`PicDamageBoard+22`); `$C729`-`$CCC7` (`PicStores+22`); `$CCDF`-`$D323` (`PicMissionSelect+22`); `$D33B`-`$D74E` (`PicGridPanel+22`); `$DD8B`-`$E51C` (`PicCockpit+22`); `$E95F`-`$EC80` (`PicBriefing+22`); 3 more ranges |
| Writes | `$FFBD` (`BitsLeftOp+1`) |

#### `StartBits` (`$FFE0`)

**Set the offset mask from A (the extra bits) and load the stream's first byte into E'**

Input: A = the extra offset bits. `$FF4B` = BitMasks + A, HL' = the stream (`$FE91`) and E' its first byte, `$FFBD` = 0. Witness: L1 120 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 725 t-states own (0.00 %) |
| Runs (the other recordings) | 120 calls (`stage1/missions` 50, `stage1/menu` 28, `stage1/play2` 12 and 7 more) |
| Called from | `UnpackPicture` |
| Reads | `$C015` (`PicDamageBoard+21`); `$C728` (`PicStores+21`); `$CCDE` (`PicMissionSelect+21`); `$D33A` (`PicGridPanel+21`); `$DD8A` (`PicCockpit+21`); `$E95E` (`PicBriefing+21`); 5 more ranges |
| Writes | `$FF4B` (`OffsetMaskOp+1`); `$FFBD` (`BitsLeftOp+1`) |


## Tape BASIC (`src/tape/basic.json`)

Battle Command, Ocean 1990: tape block 2, the BASIC program "BATTLE" (4917 bytes at PROG `$5CCB`, LINE 0). Its
entries are `src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part
src/tape/basic.json`; the recordings: `work/stage1/c1l` (c1 from power-on to the game's entry at frame 23974: the
load).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic`](#tape-basic-basic) | `$5CCB`-`$6FFF` | 1 of 4 |

### Tape BASIC: basic

`src/tape/basic-module.asm`

#### `Stage1` (`$5D06`)

**Clear the screen, copy the chain to `$AC38-$BF0C` and return into it**

Interrupts off; the screen and attributes (`$4000-$5AFF`) zeroed by LDIR, the border black. Then the 4821 bytes from PROG+95 (the address read from `$5C53`, so the copy works wherever PROG is) to `$AC38`, with SP = `$8000` and `$AC38` pushed as the return address: the RET enters the chain. c1: L1 1, frame 2028.

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 1 call, 298,561 t-states own (0.02 %) |
| Reads | `$4000`-`$5AFE` (screen); `$5C53`-`$5C54`; `$5D2A`-`$6FFE` (`ChainTape`) |
| Writes | `$4000`-`$5AFF` (screen) |
| Ports out | `$00FE` |


## Decryption chain and loader (`src/loader/chain.json`)

Battle Command, Ocean 1990: the BASIC's enciphered tail in its plain view, `$AC38-$BF0C`. The 103 layers of the
decryption chain as each one runs, then the SpeedLock 7 loader as the last layer leaves it. tools/speedlock.py
masters these bytes back into the tape's (src/tape/basic.asm INCBINs the result). Its entries are
`src/loader/<module>.asm`, written from `src/loader/chain.ann` by `kit/mkgame.py --part src/loader/chain.json`; the
recordings: `work/stage1/c1l` (c1 from power-on to the game's entry at frame 23974: the load).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`chain`](#decryption-chain-and-loader-chain) | `$AC38`-`$B8F8` | 115 of 115 |
| [`loader`](#decryption-chain-and-loader-loader) | `$B8F9`-`$BF0C` | 21 of 25 |

### Decryption chain and loader: chain

`src/loader/chain-module.asm`

#### `Layer000` (`$AC38`)

**Layer 0: rewrite the 4785 bytes `$AC5C-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AC5C-$BF0C` into p = NOT ((R XOR D) + c), D = `$F3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

[Animation: `Layer000` at work](img/routines/Layer000.gif)

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 1 call, 19,270,660 t-states own (1.13 %) |
| Reads | `$AC24`-`$AC41` (`Layer000`); `$AC58`-`$BF0C` (`Layer000Loop+8`, `Layer001`, `Layer002`, `Layer003` and 136 more) |
| Writes | `$AC23`-`$AC40` (`Layer000`); `$AC57`-`$BF0C` (`Layer000Loop+7`, `Layer001`, `Layer002`, `Layer003` and 136 more) |
| Ports in | `$003F`, `$F39F` |
| Ports out | `$001F`, `$017B`, `$01BB`, `$437F` |

#### `Layer001` (`$AC5D`)

**Layer 1: rewrite the 4768 bytes `$AC6D-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AC6D-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer002` (`$AC6E`)

**Layer 2: rewrite the 4733 bytes `$AC90-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AC90-$BF0C` into p = NOT ((R XOR D) + c), D = `$90` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer003` (`$AC91`)

**Layer 3: rewrite the 4702 bytes `$ACAF-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$ACAF-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer004` (`$ACB0`)

**Layer 4: rewrite the 4667 bytes `$ACD2-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$ACD2-$BF0C` into p = NOT ((R XOR D) + c), D = `$F1` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer005` (`$ACD3`)

**Layer 5: rewrite the 4650 bytes `$ACE3-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$ACE3-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer006` (`$ACE4`)

**Layer 6: rewrite the 4598 bytes `$AD17-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AD17-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_ACFB` (`$ACFB`)

**sub_ACFB**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer007` (`$AD11`)

**Layer 7: rewrite the 4568 bytes `$AD35-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AD35-$BF0C` into p = R + c - D, D = `$B2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer008` (`$AD36`)

**Layer 8: rewrite the 4537 bytes `$AD54-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AD54-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer009` (`$AD55`)

**Layer 9: rewrite the 4502 bytes `$AD77-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AD77-$BF0C` into p = NOT ((R XOR D) + c), D = `$93` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer010` (`$AD78`)

**Layer 10: rewrite the 4485 bytes `$AD88-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AD88-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer011` (`$AD89`)

**Layer 11: rewrite the 4450 bytes `$ADAB-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$ADAB-$BF0C` into p = NOT ((R XOR D) + c), D = `$B0` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer012` (`$ADAC`)

**Layer 12: rewrite the 4419 bytes `$ADCA-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$ADCA-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer013` (`$ADCB`)

**Layer 13: rewrite the 4384 bytes `$ADED-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$ADED-$BF0C` into p = NOT ((R XOR D) + c), D = `$91` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer014` (`$ADEE`)

**Layer 14: rewrite the 4367 bytes `$ADFE-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$ADFE-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer015` (`$ADFF`)

**Layer 15: rewrite the 4315 bytes `$AE32-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AE32-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_AE16` (`$AE16`)

**sub_AE16**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer016` (`$AE2C`)

**Layer 16: rewrite the 4285 bytes `$AE50-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AE50-$BF0C` into p = R + c - D, D = `$D2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer017` (`$AE51`)

**Layer 17: rewrite the 4254 bytes `$AE6F-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AE6F-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer018` (`$AE70`)

**Layer 18: rewrite the 4219 bytes `$AE92-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AE92-$BF0C` into p = NOT ((R XOR D) + c), D = `$B3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer019` (`$AE93`)

**Layer 19: rewrite the 4202 bytes `$AEA3-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AEA3-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer020` (`$AEA4`)

**Layer 20: rewrite the 4167 bytes `$AEC6-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AEC6-$BF0C` into p = NOT ((R XOR D) + c), D = `$D0` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer021` (`$AEC7`)

**Layer 21: rewrite the 4136 bytes `$AEE5-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AEE5-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer022` (`$AEE6`)

**Layer 22: rewrite the 4101 bytes `$AF08-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AF08-$BF0C` into p = NOT ((R XOR D) + c), D = `$B1` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer023` (`$AF09`)

**Layer 23: rewrite the 4084 bytes `$AF19-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AF19-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer024` (`$AF1A`)

**Layer 24: rewrite the 4032 bytes `$AF4D-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AF4D-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_AF31` (`$AF31`)

**sub_AF31**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer025` (`$AF47`)

**Layer 25: rewrite the 4002 bytes `$AF6B-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AF6B-$BF0C` into p = R + c - D, D = `$F2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer026` (`$AF6C`)

**Layer 26: rewrite the 3971 bytes `$AF8A-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AF8A-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer027` (`$AF8B`)

**Layer 27: rewrite the 3936 bytes `$AFAD-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AFAD-$BF0C` into p = NOT ((R XOR D) + c), D = `$D3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer028` (`$AFAE`)

**Layer 28: rewrite the 3919 bytes `$AFBE-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AFBE-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer029` (`$AFBF`)

**Layer 29: rewrite the 3884 bytes `$AFE1-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$AFE1-$BF0C` into p = NOT ((R XOR D) + c), D = `$F0` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer030` (`$AFE2`)

**Layer 30: rewrite the 3853 bytes `$B000-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B000-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer031` (`$B001`)

**Layer 31: rewrite the 3818 bytes `$B023-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B023-$BF0C` into p = NOT ((R XOR D) + c), D = `$D1` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer032` (`$B024`)

**Layer 32: rewrite the 3801 bytes `$B034-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B034-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer033` (`$B035`)

**Layer 33: rewrite the 3749 bytes `$B068-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B068-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B04C` (`$B04C`)

**sub_B04C**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer034` (`$B062`)

**Layer 34: rewrite the 3719 bytes `$B086-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B086-$BF0C` into p = R + c - D, D = `$92` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer035` (`$B087`)

**Layer 35: rewrite the 3688 bytes `$B0A5-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B0A5-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer036` (`$B0A6`)

**Layer 36: rewrite the 3653 bytes `$B0C8-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B0C8-$BF0C` into p = NOT ((R XOR D) + c), D = `$F3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer037` (`$B0C9`)

**Layer 37: rewrite the 3636 bytes `$B0D9-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B0D9-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer038` (`$B0DA`)

**Layer 38: rewrite the 3601 bytes `$B0FC-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B0FC-$BF0C` into p = NOT ((R XOR D) + c), D = `$90` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer039` (`$B0FD`)

**Layer 39: rewrite the 3570 bytes `$B11B-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B11B-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer040` (`$B11C`)

**Layer 40: rewrite the 3535 bytes `$B13E-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B13E-$BF0C` into p = NOT ((R XOR D) + c), D = `$F1` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer041` (`$B13F`)

**Layer 41: rewrite the 3518 bytes `$B14F-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B14F-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer042` (`$B150`)

**Layer 42: rewrite the 3466 bytes `$B183-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B183-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B167` (`$B167`)

**sub_B167**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer043` (`$B17D`)

**Layer 43: rewrite the 3436 bytes `$B1A1-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B1A1-$BF0C` into p = R + c - D, D = `$B2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer044` (`$B1A2`)

**Layer 44: rewrite the 3405 bytes `$B1C0-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B1C0-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer045` (`$B1C1`)

**Layer 45: rewrite the 3370 bytes `$B1E3-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B1E3-$BF0C` into p = NOT ((R XOR D) + c), D = `$93` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer046` (`$B1E4`)

**Layer 46: rewrite the 3353 bytes `$B1F4-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B1F4-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer047` (`$B1F5`)

**Layer 47: rewrite the 3318 bytes `$B217-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B217-$BF0C` into p = NOT ((R XOR D) + c), D = `$B0` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer048` (`$B218`)

**Layer 48: rewrite the 3287 bytes `$B236-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B236-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer049` (`$B237`)

**Layer 49: rewrite the 3252 bytes `$B259-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B259-$BF0C` into p = NOT ((R XOR D) + c), D = `$91` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer050` (`$B25A`)

**Layer 50: rewrite the 3235 bytes `$B26A-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B26A-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer051` (`$B26B`)

**Layer 51: rewrite the 3183 bytes `$B29E-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B29E-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B282` (`$B282`)

**sub_B282**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer052` (`$B298`)

**Layer 52: rewrite the 3153 bytes `$B2BC-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B2BC-$BF0C` into p = R + c - D, D = `$D2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer053` (`$B2BD`)

**Layer 53: rewrite the 3122 bytes `$B2DB-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B2DB-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer054` (`$B2DC`)

**Layer 54: rewrite the 3087 bytes `$B2FE-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B2FE-$BF0C` into p = NOT ((R XOR D) + c), D = `$B3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer055` (`$B2FF`)

**Layer 55: rewrite the 3070 bytes `$B30F-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B30F-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer056` (`$B310`)

**Layer 56: rewrite the 3035 bytes `$B332-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B332-$BF0C` into p = NOT ((R XOR D) + c), D = `$D0` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer057` (`$B333`)

**Layer 57: rewrite the 3004 bytes `$B351-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B351-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer058` (`$B352`)

**Layer 58: rewrite the 2969 bytes `$B374-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B374-$BF0C` into p = NOT ((R XOR D) + c), D = `$B1` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer059` (`$B375`)

**Layer 59: rewrite the 2952 bytes `$B385-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B385-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer060` (`$B386`)

**Layer 60: rewrite the 2900 bytes `$B3B9-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B3B9-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B39D` (`$B39D`)

**sub_B39D**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer061` (`$B3B3`)

**Layer 61: rewrite the 2870 bytes `$B3D7-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B3D7-$BF0C` into p = R + c - D, D = `$F2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer062` (`$B3D8`)

**Layer 62: rewrite the 2839 bytes `$B3F6-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B3F6-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer063` (`$B3F7`)

**Layer 63: rewrite the 2804 bytes `$B419-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B419-$BF0C` into p = NOT ((R XOR D) + c), D = `$D3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer064` (`$B41A`)

**Layer 64: rewrite the 2787 bytes `$B42A-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B42A-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer065` (`$B42B`)

**Layer 65: rewrite the 2752 bytes `$B44D-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B44D-$BF0C` into p = NOT ((R XOR D) + c), D = `$F0` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer066` (`$B44E`)

**Layer 66: rewrite the 2721 bytes `$B46C-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B46C-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer067` (`$B46D`)

**Layer 67: rewrite the 2686 bytes `$B48F-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B48F-$BF0C` into p = NOT ((R XOR D) + c), D = `$D1` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer068` (`$B490`)

**Layer 68: rewrite the 2669 bytes `$B4A0-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B4A0-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer069` (`$B4A1`)

**Layer 69: rewrite the 2617 bytes `$B4D4-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B4D4-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B4B8` (`$B4B8`)

**sub_B4B8**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer070` (`$B4CE`)

**Layer 70: rewrite the 2587 bytes `$B4F2-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B4F2-$BF0C` into p = R + c - D, D = `$92` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer071` (`$B4F3`)

**Layer 71: rewrite the 2556 bytes `$B511-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B511-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer072` (`$B512`)

**Layer 72: rewrite the 2521 bytes `$B534-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B534-$BF0C` into p = NOT ((R XOR D) + c), D = `$F3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer073` (`$B535`)

**Layer 73: rewrite the 2504 bytes `$B545-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B545-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer074` (`$B546`)

**Layer 74: rewrite the 2469 bytes `$B568-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B568-$BF0C` into p = NOT ((R XOR D) + c), D = `$90` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer075` (`$B569`)

**Layer 75: rewrite the 2438 bytes `$B587-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B587-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer076` (`$B588`)

**Layer 76: rewrite the 2403 bytes `$B5AA-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B5AA-$BF0C` into p = NOT ((R XOR D) + c), D = `$F1` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer077` (`$B5AB`)

**Layer 77: rewrite the 2386 bytes `$B5BB-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B5BB-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer078` (`$B5BC`)

**Layer 78: rewrite the 2334 bytes `$B5EF-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B5EF-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B5D3` (`$B5D3`)

**sub_B5D3**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer079` (`$B5E9`)

**Layer 79: rewrite the 2304 bytes `$B60D-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B60D-$BF0C` into p = R + c - D, D = `$B2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer080` (`$B60E`)

**Layer 80: rewrite the 2273 bytes `$B62C-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B62C-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer081` (`$B62D`)

**Layer 81: rewrite the 2238 bytes `$B64F-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B64F-$BF0C` into p = NOT ((R XOR D) + c), D = `$93` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer082` (`$B650`)

**Layer 82: rewrite the 2221 bytes `$B660-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B660-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer083` (`$B661`)

**Layer 83: rewrite the 2186 bytes `$B683-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B683-$BF0C` into p = NOT ((R XOR D) + c), D = `$B0` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer084` (`$B684`)

**Layer 84: rewrite the 2155 bytes `$B6A2-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B6A2-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer085` (`$B6A3`)

**Layer 85: rewrite the 2120 bytes `$B6C5-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B6C5-$BF0C` into p = NOT ((R XOR D) + c), D = `$91` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer086` (`$B6C6`)

**Layer 86: rewrite the 2103 bytes `$B6D6-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B6D6-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer087` (`$B6D7`)

**Layer 87: rewrite the 2051 bytes `$B70A-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B70A-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B6EE` (`$B6EE`)

**sub_B6EE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer088` (`$B704`)

**Layer 88: rewrite the 2021 bytes `$B728-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B728-$BF0C` into p = R + c - D, D = `$D2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer089` (`$B729`)

**Layer 89: rewrite the 1990 bytes `$B747-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B747-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer090` (`$B748`)

**Layer 90: rewrite the 1955 bytes `$B76A-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B76A-$BF0C` into p = NOT ((R XOR D) + c), D = `$B3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer091` (`$B76B`)

**Layer 91: rewrite the 1938 bytes `$B77B-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B77B-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer092` (`$B77C`)

**Layer 92: rewrite the 1903 bytes `$B79E-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B79E-$BF0C` into p = NOT ((R XOR D) + c), D = `$D0` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer093` (`$B79F`)

**Layer 93: rewrite the 1872 bytes `$B7BD-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B7BD-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer094` (`$B7BE`)

**Layer 94: rewrite the 1837 bytes `$B7E0-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B7E0-$BF0C` into p = NOT ((R XOR D) + c), D = `$B1` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer095` (`$B7E1`)

**Layer 95: rewrite the 1820 bytes `$B7F1-$BF0C` (DEC (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B7F1-$BF0C` into p = c - 1 (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer096` (`$B7F2`)

**Layer 96: rewrite the 1768 bytes `$B825-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B825-$BF0C` into p = ((R XOR IXh) - c) XOR IXl, IX the address after the CALL plus `$1C` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B809` (`$B809`)

**sub_B809**

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer097` (`$B81F`)

**Layer 97: rewrite the 1738 bytes `$B843-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B843-$BF0C` into p = R + c - D, D = `$F2` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer098` (`$B844`)

**Layer 98: rewrite the 1707 bytes `$B862-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B862-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer099` (`$B863`)

**Layer 99: rewrite the 1672 bytes `$B885-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B885-$BF0C` into p = NOT ((R XOR D) + c), D = `$D3` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer100` (`$B886`)

**Layer 100: rewrite the 1641 bytes `$B8A4-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B8A4-$BF0C` into p = R + c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer101` (`$B8A5`)

**Layer 101: rewrite the 1598 bytes `$B8CF-$BF0C` (ADD A,(HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B8CF-$BF0C` into p = (R XOR D) + c - `$07`, D = `$CD` (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Layer102` (`$B8D0`)

**Layer 102: rewrite the 1557 bytes `$B8F8-$BF0C` (SUB (HL)), run into them**

Shifts the 30 bytes up to its own LDDR down by one (the code already run is garbled), then rewrites each byte c of `$B8F8-$BF0C` into p = (R XOR E, E the count) - c (R the refresh register as LD A,R reads it). Known from the code and the chain run of tools/speedlock.py (all 103 layers, the tape masters back identical).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `sub_B8DF` (`$B8DF`)

**sub_B8DF**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### Decryption chain and loader: loader

`src/loader/loader.asm`

#### `LoaderStart` (`$B8F9`)

**Check for a Multiface, clear the RAM, print the notice and load the stage**

Interrupts off, SP = `$BFFF`. IN A,(`$3F`) and IN A,(`$9F`) are the Multiface's page-in ports: if either pages a ROM in, the byte at `$0000` is no longer the 128K ROM's DI (`$F3`) and JP `$0000` restarts the machine. The OUTs to `$1F`, `$7B` and `$BB` page such interfaces out again. Then PrintNotice and LoaderMain. Known from the code; c1: L1 1.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `PrintNotice`, `LoaderMain` (tail) |

#### `PrintNotice` (`$B935`)

**Print the copyright notice: the bars and the strings of NoticeText**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 1 call, 233 t-states own (0.00 %) |
| Called from | `LoaderStart` |
| Calls | `DrawBar`, `PrintString` (tail) |

#### `DrawBar` (`$B96C`)

**Draw a bar of A cells at the screen position BC, bright red attributes**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 2 calls, 4,836 t-states own (0.00 %) |
| Called from | `PrintNotice` |
| Calls | `CellAddress` |
| Writes | `$4028`-`$4037` (screen); `$4128`-`$4137` (screen); `$482C`-`$4832` (screen); `$492C`-`$4932` (screen); `$5828`-`$5837` (screen); `$592C`-`$5932` (screen) |

#### `PrintChar` (`$B995`)

**Print the character A (from `$20`) with the ROM font at `$3D00`**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 499 calls, 69,860 t-states own (0.00 %) |
| Called from | `PrintString` |
| Calls | `DrawGlyph` |

#### `DrawGlyph` (`$B9B1`)

**Copy the 8 bytes at HL to the screen cell DE, white attribute**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 499 calls, 205,729 t-states own (0.01 %) |
| Called from | `PrintChar` |
| Writes | `$4008`-`$50D7` (screen); `$5100`-`$51D7` (screen); `$5200`-`$52D7` (screen); `$5300`-`$53D7` (screen); `$5400`-`$54D7` (screen); `$5500`-`$55D7` (screen); 8 more ranges |

#### `CellAddress` (`$B9CD`)

**DE = the screen address of row B, column C**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 501 calls, 43,086 t-states own (0.00 %) |
| Called from | `DrawBar`, `PrintString` |

#### `PrintString` (`$B9E2`)

**Print the string at HL up to a zero, from row B column C, wrapping at column 32**

[Animation: `PrintString` at work](img/routines/PrintString.gif)

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 6 calls, 62,777 t-states own (0.00 %) |
| Called from | `PrintNotice` (tail) |
| Calls | `PrintChar`, `CellAddress` |
| Reads | `$B9FB`-`$BBF3` (`NoticeText`) |

#### `WaitTask` (`$BBF4`)

**The task the edge loop runs while it waits: the attribute reveal, then the countdown**

LoadBlocks calls it between two edges (CALL `$BBF4` at `$BDB6`); the task's own code is reached through the pointer at `$BDB7`, which each step rewrites. Known from the code; the screen shows the attributes coming in and a countdown at the top right in c1.

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 56,865 calls, 13,209,148 t-states own (0.78 %) |
| Called from | `StoreByte` |
| Calls | `sub_BCF8` (tail) |
| Reads | `$8000`-`$82FF` |
| Writes | `$5800`-`$5AFF` (screen); `$BD0C`-`$BD0E` (`l_BCFC+16`); `$BDB7`-`$BDB8` (`l_BDB2+5`) |

#### `l_BC5E` (`$BC5E`)

**l_BC5E**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `sub_BCF8` (tail) |

#### `LdEdge2` (`$BCF2`)

**Two edges: sample the EAR bit until it changes, twice**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 78 calls, 1,716 t-states own (0.00 %) |
| Called from | `LoadBlocks` |
| Calls | `sub_BCF6` (falls into) |

#### `sub_BCF6` (`$BCF6`)

**sub_BCF6**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 3,190 calls, 22,330 t-states own (0.00 %) |
| Called from | `LdEdge2` (falls into), `LoadBlocks` |
| Calls | `sub_BCF8` (falls into) |

#### `sub_BCF8` (`$BCF8`)

**sub_BCF8**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 714,204 calls, 1,287,441,746 t-states own (75.73 %) |
| Called from | `WaitTask` (tail), `l_BC5E` (tail), `sub_BCF6` (falls into), `LoadBlocks`, `StoreByte`, `ReadMark` |
| Ports in | `$7FFE` |
| Ports out | `$08FE`, `$09FE`, `$0AFE` |

#### `LoadBlocks` (`$BD13`)

**Read the pilot, the sync and the bytes of a block to IX, DE bytes**

[Animation: `LoadBlocks` at work](img/routines/LoadBlocks.gif)

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 2 calls, 77,211,967 t-states own (4.54 %) |
| Called from | `LoaderMain` |
| Calls | `LdEdge2`, `sub_BCF6`, `sub_BCF8` |
| Reads | `$BED1`-`$BEDE` (`EdgeLimits`); `$BF30`-`$BF7A` |
| Writes | `$4000`-`$BFCF` (`Layer000`, `Layer001`, `Layer002`, `Layer003` and 137 more) |
| Ports in | `$0AFE` |
| Ports out | `$0AFE`, `$7FFD` |

#### `StoreByte` (`$BD9C`)

**Store a byte: (L XOR k) + a, k and a the operands of this code**

The tape's block 17 rewrites k (`$BD9D`: `$C1`, then `$86`); a (`$BDA0`) stays `$11`. src/tape/side1.txt and tools/mktape.py use the same operands in the other direction.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `WaitTask`, `data_BC5A`, `sub_BCF8`, `LoadEnd` (tail) |

#### `StoreLast` (`$BDD0`)

**Store the last byte of a block the same way, with its own operands (block 19 rewrites them)**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ReadMark` |

#### `ReadMark` (`$BE47`)

**Read the bits of a mark between two blocks**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 45 calls, 30,690 t-states own (0.00 %) |
| Called from | `StoreLast` |
| Calls | `sub_BCF8` |

#### `TimeCheck` (`$BE5D`)

**Measure the tape's edges into TimeBuffer and compare them (replaced by tape block 37)**

After the stage (block 7): 255 samples of the EAR edges into TimeBuffer `$9000` (TimeSample, 18 447 T each), then TimeCompare unless the ROM byte `$006D` is `$28` (the +2A / +3 ROM 3). c1: TimeBuffer all zero at frame 2484 (the tape silent in the 2407 ms pause), passed.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TimeSample` (`$BE78`)

**Count the changes of EAR (port `$FE` bit 6) in 255 polls of 72 T into E**

Both paths of a poll take 72 T (the NOP / NOP / JP of the no-change path pads it).

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 255 calls, 4,738,973 t-states own (0.28 %) |
| Ports in | `$7FFE` |

#### `TimeCompare` (`$BE94`)

**S1 = samples 50-99, S2 = samples 205-254; TimeFailed = H when S2 >= `$0D00`, 1 when S2 - S1 >= 50**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 1 call, 7,047 t-states own (0.00 %) |
| Reads | `$9032`-`$9063`; `$90CD`-`$90FE` |

#### `LoadEnd` (`$BEDF`)

**The end of a stream of blocks: the XOR in H must be 0**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 2 calls, 94 t-states own (0.00 %) |
| Called from | `StoreByte` (tail) |
| Ports out | `$00FE` |

#### `LoaderMain` (`$BEEA`)

**Clear `$5D00-$BBF3` (the chain), load the stage at `$BF0D`, clear the screen and run it**

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 1 call, 741,151 t-states own (0.04 %) |
| Called from | `LoaderStart` (tail) |
| Calls | `LoadBlocks` |
| Reads | `$4001`-`$5AFF` (screen); `$5D00`-`$BBF2` (`Layer000`, `Layer001`, `Layer002`, `Layer003` and 119 more); `$BED0` (`TimeFailed`) |
| Writes | `$4000`-`$5AFF` (screen); `$5D00`-`$BBF3` (`Layer000`, `Layer001`, `Layer002`, `Layer003` and 119 more); `$BDCE`-`$BDCF` (`l_BDB2+28`) |


## Loader stage 2 (`src/loader/stage2.json`)

Battle Command, Ocean 1990: the SpeedLock loader's second stage, tape block 7, run at `$BF0D`. Its entries are
`src/loader/<module>.asm`, written from `src/loader/stage2.ann` by `kit/mkgame.py --part src/loader/stage2.json`;
the recordings: `work/stage1/c1l` (c1 from power-on to the game's entry at frame 23974: the load).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`stage2`](#loader-stage-2-stage2) | `$BF0D`-`$BFCF` | 1 of 3 |

### Loader stage 2: stage2

`src/loader/stage2-module.asm`

#### `Stage2Start` (`$BF0D`)

**Load the screen and the table's blocks; then the end of the stage**

AttrFlag := 0; IX = Screen, DE = `$17FF` (6144 bytes); LastStoreJump := StoreLast; CALL LoadBlocks reads the bitmap, then walks BlockTable to the end. If TimeFailed is set, WaitTask. Then the loop at `$BF2B` clears memory from `$4000` upwards for ever: block 39 replaces this end with TimeEnd (`$BF21`, src/loader/final.asm) before it is reached. c1: L1 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |


## Loader block 37 (`src/loader/final-be5d.json`)

Battle Command, Ocean 1990: the SpeedLock loader's last piece at `$BE5D`, the timing check, tape block 37. Its
entries are `src/loader/<module>.asm`, written from `src/loader/final.ann` by `kit/mkgame.py --part
src/loader/final-be5d.json`; the recordings: `work/stage1/c1l` (c1 from power-on to the game's entry at frame 23974:
the load).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`final`](#loader-block-37-final) | `$BE5D`-`$BECF` | 1 of 2 |

### Loader block 37: final

`src/loader/final.asm`

#### `Unxor5B00` (`$BE5D`)

**XOR the 9472 bytes of `$5B00-$7FFF` with `$AD`, then JP Bootstrap**

The tape's block 23 holds the game's `$5B00-$7FFF` XORed with `$AD` on top of the loader's cipher: this loop takes it off. c1: the bank-5 bytes change in frames 23962-23969 (memory_at every quarter frame), the game is entered at frame 23974.

| | |
| --- | --- |
| Runs (c1 from power-on to the game's entry at frame 23974: the load) | 2 calls, 530,437 t-states own (0.03 %) |
| Reads | `$5B00`-`$7FFF` |
| Writes | `$5B00`-`$7FFF`; `$9000`-`$90FE` |


## Loader block 39 (`src/loader/final-bf21.json`)

Battle Command, Ocean 1990: the SpeedLock loader's last piece at `$BF21`, the stage's new end, tape block 39. Its
entries are `src/loader/<module>.asm`, written from `src/loader/final.ann` by `kit/mkgame.py --part
src/loader/final-bf21.json`; the recordings: `work/stage1/c1l` (c1 from power-on to the game's entry at frame 23974:
the load).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`timeend`](#loader-block-39-timeend) | `$BF21`-`$BF2F` | 1 of 1 |

### Loader block 39: timeend

`src/loader/timeend.asm`

#### `TimeEnd` (`$BF21`)

**The stage's end: if TimeFailed, wipe the memory below `$C3EE`; else Unxor5B00**

c1: L1 1, TimeFailed zero, so JP Unxor5B00.

| | |
| --- | --- |
| Runs | not reached in the recordings |
