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
| [`player`](#player) | `$A8C7`-`$A9FD`, `$B550`-`$B610`, `$B8AB`-`$B8B0`, `$B8B9`-`$B915`, `$BF24`-`$BF52`, `$C113`-`$C484`, `$C510`-`$C647`, `$CAA5`-`$CC3B`, `$CF26`-`$D52D` | 80 of 104 |
| [`objects`](#objects) | `$A9FE`-`$AA26`, `$B3C9`-`$B54F`, `$B766`-`$B8AA`, `$B8B1`-`$B8B8`, `$B916`-`$B9F5`, `$BBF0`-`$BF23`, `$BF53`-`$C112`, `$C485`-`$C50F`, `$C648`-`$CAA4` | 49 of 56 |
| [`world`](#world) | `$AD45`-`$B3C8`, `$B9F6`-`$BBEF`, `$CC3C`-`$CE67`, `$CEA4`-`$CF25`, `$D8D4`-`$DA8B` | 52 of 56 |
| [`enemies`](#enemies) | `$B611`-`$B765` | 11 of 12 |
| [`sound`](#sound) | `$D674`-`$D8D3` | 17 of 20 |

## apivectors

`src/game/apivectors.asm`

### `ApiVector00` (`$67BE`)

**The mission code's service vectors: 22 JP instructions, `$67BE-$67FF`**

Each vector is a `JP` to a resident routine in bank 2 or 5: `$67BE` `$BFD1`, `$67C1` `$B766`, `$67C4` `$BCDA`, `$67C7` `$BD41`, `$67CA` `$C957`, `$67CD` `$CA3B`, `$67D0` `$A779`, `$67D3` `$A7AE`, `$67D6` `$A799`, `$67D9` `$A82C`, `$67DC` `$B660`, `$67DF` `$B6D1`, `$67E2` `$B282`, `$67E5` `$B6BD`, `$67E8` `$A899`, `$67EB` `$B611`, `$67EE` `$7040`, `$67F1` `$CC3C`, `$67F4` `$AA63`, `$67F7` `$AB7B`, `$67FA` `$AAF5`, `$67FD` `$AA47`. The mission code calls them (play: `$67D9` 220 482 times, `$67D6` 179 580).

Witness: L1 15082 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 632 calls, 9,006 t-states own (0.00 %) |
| Runs (the other recordings) | 14,450 calls (`stage1/death` 8,892, `stage1/play2` 2,342, `stage1/play` 1,779 and 2 more) |
| Called from | `PlayerStep`, `CannonShellStep` (tail), `MortarShellStep`, `RunObjectHandlers`, `DragonflyStep` (tail), `PlayerHit`, `BounceDecay`, `ClusterRise`, `MineFall`, `DecoyStart`, `DecoyZigZag`, `Cluster13Step`, `Cluster13Burst`, `PhantasmStep`, `HelicarrierWait`, `MissionHeader` (tail) |
| Calls | `MoveObject` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `ApiVector01` (`$67C1`)

**ApiVector01**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 6,516 t-states own (0.00 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `TargetInCone`, `TurnToward`, `MissionHeader` |
| Calls | `BearingTo` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

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
| Called from | `FireCannon`, `LaunchProjectile`, `ActivateMissionObjects`, `LaunchDragonfly`, `FireDecoy`, `PlaceHelicarrier`, `MissionHeader` |
| Calls | `ObjectSetType` (tail) |

### `ApiVector04` (`$67CA`)

**ApiVector04**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 360 t-states own (0.00 %) |
| Runs (the other recordings) | 431 calls (`stage1/missions` 125, `stage1/death` 119, `stage1/play2` 103 and 2 more) |
| Called from | `FireCannon`, `LaunchProjectile`, `ActivateMissionObjects`, `LaunchDragonfly`, `FireDecoy`, `PlaceHelicarrier`, `MissionHeader` |
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
| Called from | `Debris`, `DebrisVelocity`, `DebrisVelocityB`, `PlayerHit`, `Cluster13Step`, `MissionHeader` |
| Calls | `Random` (tail) |

### `ApiVector07` (`$67D3`)

**ApiVector07**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 680 calls, 8,895 t-states own (0.00 %) |
| Runs (the other recordings) | 17,513 calls (`stage1/death` 9,455, `stage1/play` 3,393, `stage1/play2` 2,339 and 2 more) |
| Called from | `ResetViewOrigin`, `BearingOctant`, `CameraSinCos`, `RadarAddBlip`, `MissionHeader` |
| Calls | `NegateHL` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `ApiVector08` (`$67D6`)

**ApiVector08**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,328 calls, 77,311 t-states own (0.01 %) |
| Runs (the other recordings) | 173,252 calls (`stage1/death` 109,476, `stage1/play2` 22,376, `stage1/missions` 21,130 and 2 more) |
| Called from | `PlayerStep`, `TestVertexNearX`, `LaunchProjectile`, `ShowMortarRange`, `InRange`, `TargetInCone`, `TurnToward`, `TerrainDiagonal`, `BoundaryCheck`, `EngineTone`, `MissionHeader` |
| Calls | `AbsA` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `ApiVector09` (`$67D9`)

**ApiVector09**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 9,736 calls, 141,530 t-states own (0.02 %) |
| Runs (the other recordings) | 210,746 calls (`stage1/death` 120,834, `stage1/play2` 37,372, `stage1/play` 27,268 and 2 more) |
| Called from | `BoxRect16`, `RotateToView`, `MissionHeader` |
| Calls | `MulWordByte` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

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
| Called from | `TerrainCollision`, `TerrainScan`, `TerrainDiagonal`, `MissionHeader` |
| Calls | `ByteToWorld` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

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
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

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
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

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
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

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

Witness: L1 15 (menu, missions, search).

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

Witness: L1 27 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 83,923 t-states own (0.01 %) |
| Runs (the other recordings) | 26 calls (`stage1/missions` 16, `stage1/play` 4, `stage1/play2` 3 and 2 more) |
| Called from | `NextView` |
| Calls | `NextView`, `ClearClipRow`, `FlickerPlayer`, `PanelSetup`, `PlayKeys`, `NoAction`, `FirstFrameHook`, `PageShadowScreen`, `PageBank6`, `PageBank0`, `SaveBank`, `RestoreBank`, `Bank3Step`, `UpdateSlotBars`, `UpdateAmmoBars`, `DrawSlotIcons`, `DrawBank7Picture`, `MessageOnce`, `ToggleNight`, `StartViewPass`, `RequestViewBlit`, `SegmentVisibility`, `ResetSegmentWalk`, `SetupClipWindow`, `SetCamera`, `CameraSinCosAgain`, `ToggleRearView`, `GroundDots`, `ActivateMissionObjects`, `TransformObjects`, `DrawObjectsInOrder`, `RunObjectHandlers`, `DrawRadar`, `DrawSightOverlay`, `RefreshWeaponPanel`, `CollisionPass`, `SetBinoculars`, `PickupAnnounce`, `MissionHeader` |
| Reads | `$7578` (`AwolState`); `$82FF`-`$8300` (`Im2Table+255`); `$8475` (`BlinkLamp`); `$87FD` (`NightKey+1`); `$BA27` (`l_BA1F+8`); `$CEA8` (`ToggleBinoculars+1`); 1 more ranges |
| Writes | `$6952` (`StartMission+7`); `$6A6D` (`ViewChangeFlag+1`); `$7256` (`FirstFrameHook`); `$83E6`-`$83E7` (`MenuJobs+7`); `$8459` (`BlinkWarning`); `$8475` (`BlinkLamp`); 12 more ranges |

### `PlayLoop` (`$6A0C`)

**One frame of the 3D view: draw, keys, world, objects, enemies, HUD; loop until the view changes**

Calls in order: `$DB71`, the 3D frame (`$9882`), the play keys (`PlayKeys` `$6B3B`), `$B9F6`, the clipping marks (`ClearClipRow` `$6A9D`), `$BAAC`, the world (`$AD45`, `$AEA0`), `$BBF1`, `$BD98`, Bank3Step `$72A3` (bank 3 DrawDebris / MoveAllDebris), CameraSinCosAgain `$BA40`, DrawRadar `$C05E`, DrawObjectsInOrder `$BF53`, CollisionPass `$C7BC` and DrawSightOverlay `$C4CD` (bank 0), `$988D`, the message timer (`$7D5D`), the weapon bars (`$7327`), the object table (`$C026`), `$6B1D`, the mission's goal hook (`CALL LoopHook` at `$6A66`, its operand patched by the mission load: Blast Em Mission `$EB60`; LoopHook `$6A9C` is a `RET` in the image) and `$7256`, until the view flag `$6A6D` is non-zero; then the next view's loop through `$6A99`.

Witness: L1 410 (death, m2erbe, missions, play, play2).

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
| Calls | `PlayLoop` (tail), `NextView`, `FlickerPlayer`, `FirstFrameHook`, `PageBank6`, `UpdateSlotBars`, `MessageOnce`, `RequestViewBlit`, `RunObjectHandlers`, `MissionHeader` |
| Reads | `$8475` (`BlinkLamp`) |
| Writes | `$6952` (`StartMission+7`); `$8459` (`BlinkWarning`); `$8475` (`BlinkLamp`); `$87D7` (`MessageTimer+1`); `$D4B8` (`BoundaryCheck`); `$DB71` (`PickupAnnounce`) |

### `NextView` (`$6A91`)

**NextView**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 341 t-states own (0.00 %) |
| Runs (the other recordings) | 121 calls (`stage1/missions` 50, `stage1/menu` 33, `stage1/play2` 12 and 6 more) |
| Called from | `StartMission`, `PlayLoopTail`, `DragonflyViewLoop` (tail), `StatusLoop` (tail), `BriefPage` (tail), `DamageLoop` (tail) |
| Calls | `StartMission`, `DragonflyViewLoop`, `StatusLoop`, `BriefPage`, `DamageLoop` |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$8857` (`l_884C+11`) |

### `LoopHook` (`$6A9C`)

**LoopHook**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearClipRow` (`$6A9D`)

**Fill the 32 bytes `$90F1-$9110` with `$FF`**

The row of the back buffer `$90F1` (its line 75 + 16) set to `$FF` once a frame of every view loop, before the world is drawn. Witness: L1 3626 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 87,087 t-states own (0.01 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$90F1`-`$910F` (`BackBuffer+1536`) |
| Writes | `$90F1`-`$9110` (`BackBuffer+1536`) |

### `FillPanelRows` (`$6AAB`)

**Fill 24 character rows of 6 bytes of the screen through ScreenRowFill**

A = 0, C = 2, D = 6, E = `$18`, then `JP $6D22`. Called from bank 6 `$C53F` / `$D521`. Witness: L1 41 (death, m2erbe, missions, play, play2).

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
| Called from | `NextView` |
| Calls | `NextView` (tail), `ClearClipRow`, `FirstFrameHook`, `PageShadowScreen`, `PageBank6`, `PageBank0`, `DrawBank7Picture`, `StartViewPass`, `RequestViewBlit`, `SegmentVisibility`, `SetupClipWindow`, `SetCamera`, `CameraSinCosAgain`, `GroundDots`, `ActivateMissionObjects`, `TransformObjects`, `DrawObjectsInOrder`, `RunObjectHandlers`, `DrawSightOverlay`, `CollisionPass` |
| Reads | `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$7256` (`FirstFrameHook`); `$83E6`-`$83E7` (`MenuJobs+7`); `$8459` (`BlinkWarning`); `$87D7` (`MessageTimer+1`) |

### `FlickerPlayer` (`$6B1D`)

**Toggle the low nibble of object 0's byte +7 from a random number while `$68BD` is below 16**

HL = `$75F7` (object 0, +7): if the byte is non-zero, XOR its low nibble with a random nibble (`$67D0` -> `$A779`). Runs while `$68BD` < 16 (the damage of the tank? known only from the code). Witness: L1 3601 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 4,567 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoopTail` |
| Reads | `$68BD` (`GaugeRecords+18`); `$82FF`-`$8300` (`Im2Table+255`) |

### `PanelSetup` (`$6B32`)

**Page bank 6, call its panel set-up `$D521`, page bank 0 back**

Witness: L1 27 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 44 t-states own (0.00 %) |
| Runs (the other recordings) | 26 calls (`stage1/missions` 16, `stage1/play` 4, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission` |
| Calls | `PageBank6`, `PageBank0` (tail) |

### `PlayKeys` (`$6B3B`)

**The play keys: a new key code in `$8979` jumps to its action**

Returns unless bit 1 of `$8978` is set and the code differs from the last (`$6B45`, the operand of `LD C,0`). E: `$843F` (the quit prompt), K and J: the selected weapon's aim pair (the `JP` targets `$6B55` and `$6B50`, patched by SelectWeapon from `$7B89` + 8 x type, words 0 and 1; `$6BB0` NoAction in the image), M: the status view (`$705A`), D: the damage board (`$6BC2`), 1-4: weapons (bank 6 `$C53F`), H: `$D52E`, N: `$87FC`, R: `$BA45`, B: `$CEA7`, Z: `$CEE5`, C: remembered in `$6B45`.

Witness: L1 3602 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 20,428 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop` |
| Calls | `NoAction` (tail), `SelectDamage` (tail), `ScreenZero` (tail), `QuitKey` (tail), `NightKey` (tail), `MortarElevationDown` (tail), `AimLimit` (tail), `RearViewOff` (tail), `SelectWeapon` (tail), `ToggleBinoculars` (tail), `CycleBinocularZoom` (tail), `SetMineTimer` (tail), `PrintAimType10` (tail), `PrintSlotName` (tail), `PlaceHelicarrier` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$8978`-`$8979` (`KeyState`, `KeyCode`) |

### `DamageKeys` (`$6B95`)

**The keys of the damage board (called only from DamageLoop `$6CB9`): B to the status view `$6BC7`, C back to the 3D view, D the damage board again**

Witness: L1 3 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play` 3) |
| Called from | `DamageLoop` |
| Calls | `SelectLoop` |
| Reads | `$6B45` (`PlayKeys+10`); `$8978`-`$8979` (`KeyState`, `KeyCode`) |

### `NoAction` (`$6BB0`)

**A RET: the action of the keys with nothing to do**

Witness: L1 14403 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 478 calls, 4,937 t-states own (0.00 %) |
| Runs (the other recordings) | 13,925 calls (`stage1/death` 10,040, `stage1/play2` 1,641, `stage1/missions` 1,092 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `PlayKeys` (tail), `PlayerSteering` |

### `SelectLoop` (`$6BB4`)

**SelectLoop**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `DamageKeys`, `SelectDamage` (tail) |
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

Witness: L1 10 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/missions` 8, `stage1/m2erbe` 1, `stage1/play` 1) |
| Called from | `NextView` |
| Calls | `NextView` (tail), `StatusKeys`, `PrintStatusHelp`, `PageShadowScreen`, `PageBank6`, `PageBank0`, `DrawBank7Picture`, `PrintClock`, `SegmentVisibility`, `SetCamera`, `CameraSinCosAgain`, `ActivateMissionObjects`, `TransformObjects`, `RunObjectHandlers`, `CollisionPass` |
| Reads | `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$6C56` (`BriefPageOnce`); `$6C6A` (`StatusKeys+10`); `$7256` (`FirstFrameHook`); `$757A` (`AwolState+2`); `$7D8A` (`PointerTick+10`); `$83BF` (`PointerShown+1`); 3 more ranges |

### `BriefPage` (`$6C44`)

**The console's BRIEF page (node `$7544`, key B in the status view): the briefing text once (`$6C56`), then the clock and keys loop**

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `NextView` |
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

Witness: L1 530 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 530 calls (`stage1/play` 492, `stage1/missions` 34, `stage1/m2erbe` 4) |
| Called from | `StatusLoop`, `BriefPage` |
| Calls | `ScreenEight`, `ScreenZero` (tail), `InvertPanelA` |
| Reads | `$8978`-`$8979` (`KeyState`, `KeyCode`) |
| Writes | `$6C6A` (`StatusKeys+10`) |

### `PrintStatusHelp` (`$6C8B`)

**Print the help text `$6550` with attribute `$1A` through `$B7AE`**

Witness: L1 10 (play, play2).

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
| Called from | `NextView` |
| Calls | `NextView` (tail), `DamageKeys`, `PageBank0Main`, `PageShadowScreen`, `PageBank6`, `PageBank0`, `DrawSlotBarsLow`, `DrawSlotBars`, `DrawDamagePanel`, `DrawBank7Picture`, `SegmentVisibility`, `SetCamera`, `CameraSinCosAgain`, `ActivateMissionObjects`, `TransformObjects`, `RunObjectHandlers`, `CollisionPass` |
| Reads | `$6A6D` (`ViewChangeFlag+1`) |
| Writes | `$7D5D` (`MessageOnce`); `$87D7`-`$87E0` (`MessageTimer+1`) |

### `PlaceHelicarrier` (`$D52E`)

**Once (the RET / NOP gate `$D52E`), on the key H: call the Helicarrier, which then flies to the pad**

`$D52E` is `NOP` until it has run, then `RET` (`$D531` writes it; the mission load `$8598` clears it). Record 21 (`$7ADC`) gets type `$8C` at the pad `$7E89` / `$7E8C` (the block header's 12 bytes at `$DBF1` copied to `$7E82`).

Witness: L1 2 (play).

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

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `RunObjectHandlers` |
| Writes | `$6760`-`$6767` (`FaceFlags+56`); `$7AF4`-`$7AF5` (`HelicarrierRecord+24`) |

### `SetHelicarrierHandler` (`$DB15`)

**The Helicarrier handler's high byte**

`LD (IX+$19),$DB` / `RET`, the handler's high byte.

Witness: L1 1 (play).

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

Witness: L1 27 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 27 calls (`stage1/play` 27) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00`, `TurnToward` |
| Reads | `$7B00`-`$7B04` (`HelicarrierRecord+36`); `$7E89`-`$7E8D` (`MissionParams+7`) |

### `PickupAnnounce` (`$DB71`)

**Announce the pickup once the goal is met**

A NOP / RET gate at `$DB71`. When `$68E8` (the goal flag) is set: `$DB77` writes `RET` at `$DB71` and prints "MISSION:COMPLETE:PROCEED:TO:PICKUP" (`$DB97`). Runs once per 3D frame.

Witness: L1 3483 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 3,940 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop` |
| Reads | `$68E8` (`GoalFlag`); `$82FF`-`$8300` (`Im2Table+255`) |

### `l_FE8F` (`$FE8F`)

**l_FE8F**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/death`, `stage1/play2`, `stage1/play`) |
| Called from | `OpNative` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$FD00`-`$FD07` (`MissionHeader+8507`); `$FE00`-`$FE07` (`MissionHeader+8763`); `$FF00`-`$FF07` (`data_FEBB+69`) |

## text

`src/game/text.asm`

### `BorderBlack` (`$6CEB`)

**Border 0 (the stored colour `$6CF1` cleared)**

Witness: L1 66 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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

HL -> B (width), C (height), E (column), A (attribute), L (row); falls into AttrBoxAt. Witness: L1 350 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 9 calls, 132 t-states own (0.00 %) |
| Runs (the other recordings) | 337 calls (`stage1/missions` 153, `stage1/menu` 99, `stage1/play` 26 and 6 more) |
| Called from | `BriefPageText` (tail), `BriefingMapLegend`, `StatusMapLegend`, `NightColours` |
| Calls | `AttrBoxAt`, `LowTimes32` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$88F3` (`NightBox`) |
| Writes | `$5800`-`$5AFF` (screen) |

### `AttrBoxAt` (`$6CFD`)

**AttrBox with B already set (HL -> height, column, attribute, row)**

Witness: L1 319 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11 calls, 64,438 t-states own (0.01 %) |
| Runs (the other recordings) | 308 calls (`stage1/missions` 187, `stage1/play` 61, `stage1/play2` 27 and 2 more) |
| Called from | `AttrBox`, `SkyColours` |
| Calls | `AttrBoxRC`, `LowTimes32` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$88F4`-`$890F` (`NightBox+1`, `HourTable`, `SkyBoxes`) |
| Writes | `$5800`-`$5AFF` (screen) |

### `AttrBoxAtC` (`$6CFE`)

**AttrBoxAtC**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AttrBoxRC` (`$6D05`)

**Fill C rows of B attribute bytes with A' from row L, column E (`$5800` + 32L + E)**

Witness: L1 70 (c1, menu, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 70 calls (`stage1/play` 70) |
| Called from | `AttrBoxAt`, `IconFrame` (tail) |
| Calls | `LowTimes32` |
| Writes | `$5802`-`$5807` (screen); `$5822`-`$5AAC` (screen); `$5AC4`-`$5AFD` (screen) |

### `ScreenRowFill` (`$6D22`)

**Fill E pixel lines of D bytes with A from the line table `$6500`, column C**

Uses the line address table at `$6500` (2 bytes a pixel line). Witness: L1 200 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 265,848 t-states own (0.04 %) |
| Runs (the other recordings) | 193 calls (`stage1/missions` 65, `stage1/play2` 50, `stage1/menu` 36 and 6 more) |
| Called from | `FillPanelRows` (tail) |
| Reads | `$6500`-`$667F` (`ScreenRowTable`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$4000`-`$57FF` (screen) |

### `PointerZones` (`$6D42`)

**When the pointer is clicked, call the zone of the current screen that holds the pointer**

`LD A,n`: n (`$6D43`) is set by the fire test of the interrupt (`$7DC2`). The zone table (HL, the operand at `$6D47`, set per screen by `SetScreen` `$7060`) has 6-byte records x1, x2, y1, y2 and a routine; the first record with x1 <= X < x2 and y1 <= Y < y2 (X `$9715`, Y `$9716`) is called. A 0 byte ends the table. Witness: L1 30082532 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,746,889 calls, 46,341,318 t-states own (7.01 %) |
| Runs (the other recordings) | 28,335,628 calls (`stage1/play2` 5,182,205, `stage1/m10` 5,128,479, `stage1/missions` 4,951,614 and 6 more) |
| Calls | `ApiVector16`, `ScreenFromClick`, `ScreenZero`, `ScreenTwo`, `ShowBriefingMapOnce`, `ScreenOfMission`, `LoadMissionIfAllowed`, `LoadMissionHeader` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$9715`-`$9716` (`ClickState`, `ClickY`) |
| Writes | `$6D43` (`PointerZones+1`); `$6D71`-`$6D72` (`l_6D49+40`) |

### `CopyGraphic` (`$6D7F`)

**Copy a C x B graphic from HL' to the screen at pixel line A, column BC**

The line address table `$6500` again. Witness: L1 416 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 17 calls, 166,004 t-states own (0.03 %) |
| Runs (the other recordings) | 393 calls (`stage1/missions` 149, `stage1/menu` 82, `stage1/play2` 71 and 6 more) |
| Called from | `DrawIcon` (tail) |
| Reads | `$6500`-`$654F` (`ScreenRowTable`); `$6560`-`$65EF` (`ScreenRowTable+96`); `$6610`-`$667F` (`ScreenRowTable+272`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$400B`-`$4ADB` (screen); `$4B02`-`$4BDB` (screen); `$4C02`-`$4CDB` (screen); `$4D02`-`$4DDB` (screen); `$4E02`-`$4EDB` (screen); `$4F02`-`$4FDB` (screen); 1 more ranges |

### `CodeSmallFont` (`$6DA1`)

**Control code 7: switch to the small font, then CodeAt**

Witness: L1 1122 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 58 calls, 3,487 t-states own (0.00 %) |
| Runs (the other recordings) | 1,064 calls (`stage1/missions` 257, `stage1/menu` 252, `stage1/play2` 215 and 6 more) |
| Called from | `PrintString` |
| Calls | `SmallFontColumn`, `CodeSmallAt` |
| Reads | `$87F2` (`BlankMessage+2`); `$8C67`-`$8E86` (`BackBuffer+374`); `$BA70`-`$BAA1` (`ViewTexts+2`, `IrSightBlank`, `RearViewText`, `BinocularText` and 1 more); `$D0AD` (`MineHudText+2`); `$FDC2`-`$FFDD` (`MissionHeader+8701`, `l_FE8F`, `data_FEBB`) |

### `CodeSmallChars` (`$6DA6`)

**Control code 5: the small font's column (6-pixel cells) from the next byte; the font is not switched**

Witness: known only from the code (no string of the recordings uses code 5).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SmallFontColumn` (`$6DA9`)

**A = column in 6-pixel cells: the byte (`$6DFD`) and the bit shift (`$6DEC`)**

Witness: L1 1423 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 61 calls, 8,020 t-states own (0.00 %) |
| Runs (the other recordings) | 1,362 calls (`stage1/menu` 456, `stage1/missions` 312, `stage1/play2` 224 and 6 more) |
| Called from | `CodeSmallFont`, `SmallNewLine` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$6DEC` (`PrintSmallChar+4`); `$6DFD`-`$6DFE` (`PrintSmallChar+21`) |

### `SmallFontAdvance` (`$6DC0`)

**The next 6-pixel cell, a new line past column 32**

Witness: L1 17639 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 698 calls, 97,643 t-states own (0.01 %) |
| Runs (the other recordings) | 16,941 calls (`stage1/menu` 6,385, `stage1/missions` 3,959, `stage1/play2` 2,258 and 6 more) |
| Called from | `PrintSmallChar` |
| Reads | `$6DEC` (`PrintSmallChar+4`); `$6DFD` (`PrintSmallChar+21`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$6DEC` (`PrintSmallChar+4`); `$6DFD` (`PrintSmallChar+21`) |

### `SmallGlyph` (`$6DDA`)

**HL = SmallFont + 5 (A - "0")**

Witness: L1 17639 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 698 calls, 56,845 t-states own (0.01 %) |
| Runs (the other recordings) | 16,941 calls (`stage1/menu` 6,385, `stage1/missions` 3,959, `stage1/play2` 2,258 and 6 more) |
| Called from | `PrintSmallChar` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `PrintSmallChar` (`$6DE8`)

**Print a small-font character at the current cell: 5 lines, one of four shifts through `$6E9F`**

Witness: L1 17639 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 698 calls, 930,873 t-states own (0.14 %) |
| Runs (the other recordings) | 16,941 calls (`stage1/menu` 6,385, `stage1/missions` 3,959, `stage1/play2` 2,258 and 6 more) |
| Called from | `PrintString` |
| Calls | `SmallFontAdvance`, `SmallGlyph` |
| Reads | `$4022`-`$4E98` (screen); `$4EEA`-`$4F98` (screen); `$502C`-`$51B4` (screen); `$5203`-`$569E` (screen); `$570A`-`$579E` (screen); `$650A`-`$6529` (`ScreenRowTable+10`); 5 more ranges |
| Writes | `$4022`-`$4E98` (screen); `$4EEA`-`$4F98` (screen); `$502C`-`$51B4` (screen); `$5203`-`$569E` (screen); `$570A`-`$579E` (screen); `$6E06`-`$6E07` (`l_6E05+1`) |

### `CodeColumn` (`$6EA7`)

**Control code 0: the next byte is the column (`$6FF8`)**

Witness: known only from the code (no recording counts it: it is entered by the CALL patched at `$6FD6`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CodeAtColumn` (`$6EAE`)

**Control code 2: a row (CodeAt) then a column**

Witness: L1 859 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 315 t-states own (0.00 %) |
| Runs (the other recordings) | 851 calls (`stage1/play` 524, `stage1/missions` 202, `stage1/play2` 70 and 3 more) |
| Called from | `PrintString` |
| Calls | `CodeAt` |
| Reads | `$7E31` (`ClockText+2`) |
| Writes | `$6FF8` (`PrintChar+8`) |

### `CodeAt` (`$6EB3`)

**Control code 1: the next byte is the character row: its line pointers and attribute address**

Witness: L1 859 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 790 t-states own (0.00 %) |
| Runs (the other recordings) | 851 calls (`stage1/play` 524, `stage1/missions` 202, `stage1/play2` 70 and 3 more) |
| Called from | `CodeAtColumn` |
| Reads | `$7E30` (`ClockText+1`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$6F5D`-`$6F5E` (`CodeNewLine+16`); `$6FC2`-`$6FC3` (`PrintString+15`); `$6FFB`-`$6FFC` (`PrintChar+11`) |

### `GlyphAddress` (`$6ED7`)

**HL = the 8x8 glyph of character A: `$F5E4` + 8 (A - `$20`) (bank 6)**

Witness: L1 6525 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 128 calls, 13,146 t-states own (0.00 %) |
| Runs (the other recordings) | 6,189 calls (`stage1/play` 2,855, `stage1/missions` 1,576, `stage1/play2` 1,001 and 3 more) |
| Called from | `PrintChar` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `NextColumn` (`$6EE5`)

**The column one on, a new line after 31**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CodeNumber` (`$6EF1`)

**Control code 8: print the byte at the address that follows as three decimal digits**

Witness: L1 140 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 140 calls (`stage1/death` 62, `stage1/play2` 50, `stage1/play` 24 and 3 more) |
| Called from | `PrintString` |
| Calls | `DivideDigit`, `PrintString` |
| Reads | `$7A95` (`PlayerY+1151`); `$82FF`-`$8300` (`Im2Table+255`); `$B8FC` (`IrViewHeight`); `$C527` (`WeaponVars`); `$CFF5` (`MineTimerCode+1`); `$D0AF`-`$D0B0` (`MineHudText+4`); 2 more ranges |
| Writes | `$6F2F` (`NumberText+2`) |

### `CodeNumberA` (`$6EFB`)

**Control code 3: three decimal digits of a constant: LD A,`$5E` overwrites A, so it prints "094"; no string uses it**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CodeHex` (`$6F17`)

**Control code 4: two hexadecimal digits of the constant `$5E` (LD A,`$5E`): "5E"; no string uses it**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DivideDigit` (`$6F31`)

**A / B: C the quotient, A the rest; the digit stored at HL**

Witness: L1 280 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 280 calls (`stage1/death` 124, `stage1/play2` 100, `stage1/play` 48 and 3 more) |
| Called from | `CodeNumber` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$6F2D`-`$6F2E` (`NumberText`) |

### `DigitChar` (`$6F3D`)

**DigitChar**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CodeNewLine` (`$6F4D`)

**Control code 11: the next character row, column 0**

Witness: L1 156 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 10 calls, 1,732 t-states own (0.00 %) |
| Runs (the other recordings) | 130 calls (`stage1/play2` 64, `stage1/menu` 24, `stage1/play` 22 and 3 more) |
| Called from | `PrintString` |
| Reads | `$6FFB`-`$6FFC` (`PrintChar+11`) |
| Writes | `$6F5D`-`$6F5E` (`CodeNewLine+16`); `$6FF8`-`$6FFC` (`PrintChar+8`) |

### `SmallNewLine` (`$6F67`)

**Control code 10: the small font's next line (9 pixel lines down: ScreenRowTable + `$12`), column = the margin**

Witness: L1 301 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3 calls, 320 t-states own (0.00 %) |
| Runs (the other recordings) | 298 calls (`stage1/menu` 204, `stage1/missions` 55, `stage1/play` 15 and 6 more) |
| Called from | `PrintString` |
| Calls | `SmallFontColumn` |
| Reads | `$6DFA`-`$6DFB` (`PrintSmallChar+18`); `$6F58` (`CodeNewLine+11`) |
| Writes | `$6DFA`-`$6DFB` (`PrintSmallChar+18`) |

### `CodeLeftMargin` (`$6F79`)

**Control code 9: the next byte is the left margin (`$6F58`)**

Witness: L1 169 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 168 t-states own (0.00 %) |
| Runs (the other recordings) | 163 calls (`stage1/menu` 55, `stage1/missions` 42, `stage1/play2` 38 and 6 more) |
| Called from | `PrintString` |
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

Witness: L1 1325 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 18 calls, 846 t-states own (0.00 %) |
| Runs (the other recordings) | 1,295 calls (`stage1/play` 544, `stage1/missions` 326, `stage1/menu` 181 and 6 more) |
| Called from | `PrintString` |
| Reads | `$7E33` (`ClockText+4`); `$82FF`-`$8300` (`Im2Table+255`); `$93DA`-`$94F1` (`BackBuffer+2281`); `$FDC4`-`$FDEF` (`MissionHeader+8703`) |
| Writes | `$7025` (`l_7018+13`) |

### `PrintString` (`$6FB3`)

**Print the string at HL: characters, control codes below `$20`, tokens from `$82`, `$FF` the end**

Witness: L1 2130 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

[Animation: `PrintString` at work](img/routines/PrintString.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 60 calls, 114,900 t-states own (0.02 %) |
| Runs (the other recordings) | 2,068 calls (`stage1/play` 623, `stage1/missions` 446, `stage1/menu` 364 and 6 more) |
| Called from | `CodeNumber`, `BriefPageText`, `LoadDirectory`, `PrintRewind` (tail), `BriefingMapLegend` (tail), `StatusMapLegend`, `MessageOnce`, `PrintClock` (tail), `MessageTimer` (tail), `ToggleNight` (tail), `ShowMortarRange` (tail), `ToggleRearView` (tail), `WeaponSelectText` (tail), `SelectPlain`, `PrintAmmo` (tail), `PrintAmmoAt` (tail), `SetBinoculars` (tail), `PrintElevation`, `SetMineTimer` (tail), `MineHud`, `PrintAimType10`, `PrintSlotName` (tail), `PrintSlotAmmo` (tail), `SelectType10` (tail), `PrintType10` (tail) |
| Calls | `CodeSmallFont`, `PrintSmallChar`, `CodeAtColumn`, `CodeNumber`, `CodeNewLine`, `SmallNewLine`, `CodeLeftMargin`, `CodeInk`, `PrintChar` |
| Reads | `$6F2D`-`$6F30` (`NumberText`); `$6F93`-`$6FAA` (`ControlCodes+4`); `$7E2F`-`$7E39` (`ClockText`); `$82FF`-`$8EAF` (`Im2Table+255`, `Armour`, `DamageBoardRecords`, `InterruptHandler` and 45 more); `$93D9`-`$9502` (`BackBuffer+2280`); `$BA6E`-`$BAAB` (`ViewTexts`, `IrSightBlank`, `RearViewText`, `BinocularText` and 1 more); 2 more ranges |
| Writes | `$6FD7`-`$6FD8` (`CallControl+1`) |

### `CallControl` (`$6FD6`)

**CallControl**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintChar` (`$6FF0`)

**Print the 8x8 character A at the current cell and its attribute (`$7025`), then the next column**

In column 31 it writes no attribute and starts a new line (CodeNewLine) instead (`$700F`).

Witness: L1 6525 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 128 calls, 136,047 t-states own (0.02 %) |
| Runs (the other recordings) | 6,189 calls (`stage1/play` 2,855, `stage1/missions` 1,576, `stage1/play2` 1,001 and 3 more) |
| Called from | `PrintString` |
| Calls | `GlyphAddress` |
| Reads | `$6550`-`$65BF` (`ScreenRowTable+80`); `$65D0`-`$660F` (`ScreenRowTable+208`); `$6620`-`$662F` (`ScreenRowTable+288`); `$6640`-`$664F` (`ScreenRowTable+320`); `$6F5D`-`$6F5E` (`CodeNewLine+16`); `$6FF8` (`PrintChar+8`); 1 more ranges |
| Writes | `$40A1`-`$5110` (screen); `$514B`-`$5193` (screen); `$5208`-`$5210` (screen); `$524B`-`$5293` (screen); `$5308`-`$5310` (screen); `$534B`-`$5393` (screen); 17 more ranges |

### `CodeSmallAt` (`$7029`)

**Control code 6: the small font's line from the next byte**

Witness: L1 1122 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 58 calls, 8,130 t-states own (0.00 %) |
| Runs (the other recordings) | 1,064 calls (`stage1/missions` 257, `stage1/menu` 252, `stage1/play2` 215 and 6 more) |
| Called from | `CodeSmallFont` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$87F1` (`BlankMessage+1`); `$8C66`-`$8E85` (`BackBuffer+373`); `$BA6F`-`$BAA0` (`ViewTexts+1`, `IrSightBlank`, `RearViewText`, `BinocularText` and 1 more); `$D0AC` (`MineHudText+1`); `$FDC1`-`$FFDC` (`MissionHeader+8700`, `l_FE8F`, `data_FEBB`) |
| Writes | `$6DFA`-`$6DFB` (`PrintSmallChar+18`); `$6FC2`-`$6FC3` (`PrintString+15`) |

## screens

`src/game/screens.asm`

### `ScreenFour` (`$7040`)

**Remember key A, screen 2 (E = 4); the mission code's vector `$67EE`**

Witness: L1 9 (missions, play, play2).

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

Witness: L1 14 (missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 2 and 1 more) |
| Called from | `StatusKeys` |
| Calls | `SetScreen` (tail) |
| Writes | `$6B45` (`PlayKeys+10`) |

### `ScreenFromClick` (`$7055`)

**Key "C", screen 0**

Witness: L1 15 (menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 20 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/death` 1 and 2 more) |
| Called from | `PointerZones` |
| Calls | `ScreenZero` |
| Writes | `$6B45` (`PlayKeys+10`) |

### `ScreenZero` (`$705A`)

**Screen 0 (E = 0)**

Witness: L1 91 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 76 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/missions` 41, `stage1/menu` 17, `stage1/play2` 9 and 6 more) |
| Called from | `PlayKeys` (tail), `StatusKeys` (tail), `PointerZones`, `ScreenFromClick`, `LoadMissionIfAllowed` (tail) |
| Calls | `SetScreen` (tail) |
| Reads | `$74E6`-`$74ED` (`ScreenList`); `$7504`-`$751D` (`ScreenList+30`) |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$6A99`-`$6A9A` (`NextView+8`); `$6D47`-`$6D48` (`PointerZones+5`); `$74E6`-`$74E7` (`ScreenList`) |

### `ScreenTwo` (`$705E`)

**Screen 1 (E = 2)**

Witness: L1 12 (menu, missions, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12 calls (`stage1/menu` 12) |
| Called from | `PointerZones`, `ScreenOfMission` (tail) |
| Calls | `SetScreen` |

### `SetScreen` (`$7060`)

**Switch to entry E/2 of the screen list: the draw routine to `$6A99`, the zone table to `$6D47`**

Witness: L1 121 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 1,072 t-states own (0.00 %) |
| Runs (the other recordings) | 112 calls (`stage1/missions` 50, `stage1/menu` 33, `stage1/play2` 12 and 3 more) |
| Called from | `ScreenFour` (tail), `ScreenEight` (tail), `ScreenZero` (tail), `ScreenTwo` |
| Calls | `SetViewFlag` |
| Reads | `$74E6`-`$7549` (`ScreenList`); `$756A`-`$7571` (`ScreenList+132`) |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$6A99`-`$6A9A` (`NextView+8`); `$6D47`-`$6D48` (`PointerZones+5`); `$74E6`-`$74E7` (`ScreenList`) |

### `SetViewFlag` (`$707E`)

**`$6A6D` = `$FF`: the current loop ends**

Witness: L1 10 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/play` 10) |
| Called from | `SelectLoop` (tail), `SetScreen` |
| Writes | `$6A6D` (`ViewChangeFlag+1`) |

### `ShowBriefingMapOnce` (`$7084`)

**Once: the briefing map (bank 6's BriefingMapFrame `$DACB` and BriefingMap `$DB64`), then patched to RET**

Witness: L1 10 (menu, play, play2).

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

Pages bank 4, copies `$CB64` (32 bytes) via `$8AF1` to bank 6 `$CF85`, then `$CB84` (1024 bytes) to `$8AF1`. Witness: L1 32 (menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 24,215 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 6 more) |
| Calls | `PageBank4`, `PageBank6`, `SaveBank`, `RestoreBank` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$8AF1`-`$8B10` (`BackBuffer`) |
| Writes | `$8AF1`-`$8EF0` (`BackBuffer`) |

### `CopyMissionText` (`$70F6`)

**Copy mission (`$757D`)'s texts from the catalogue (bank 4) to bank 6 `$DBF3`**

Record n of the 8-byte index at `$CCA6`: the offset, two words stored at `$7143` and `$7151`, the end; the text is copied through `$8AF1` to `$DBF3`; `$70A3` and `$7C55` get the addresses of its two parts. Witness: L1 25 (menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 23,761 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/menu` 10, `stage1/missions` 8, `stage1/play2` 3 and 3 more) |
| Calls | `PageBank4`, `PageBank6`, `SaveBank`, `RestoreBank` (tail) |
| Reads | `$757D` (`ScreenOfMission+1`); `$82FF`-`$8300` (`Im2Table+255`); `$8AF1`-`$8DA3` (`BackBuffer`) |
| Writes | `$70A3`-`$70A4` (`BriefingTextOnce+5`); `$7143`-`$7152` (`CopyMissionText+77`); `$7C55`-`$7C56` (`FailReason+92`); `$8AF1`-`$8DA3` (`BackBuffer`) |

### `LoadDirectory` (`$715D`)

**Load the catalogue from side 2: the 17-byte header "DIRECTORY", then its block to bank 4 `$CB64`**

Loops until a header whose name is "DIRECTORY" (`$71B3`) loads, prints `$C90D` ("loading"), pages bank 4 and loads the block (length from the header `$8AFC`) to `$CB64`; retries until its first 9 bytes are "MISSION:T" (`$71BB`). Witness: L1 13 (c1, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 398 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/play2` 3, `stage1/play` 2, `stage1/menu` 1 and 6 more) |
| Calls | `PrintString`, `PrintRewind`, `IsDirectoryHeader`, `IsCatalogue`, `LoadBlock`, `PageBank4`, `PageBank6` |
| Reads | `$8AFC`-`$8AFD` (`BackBuffer+11`) |
| Writes | `$8AF1` (`BackBuffer`) |

### `PrintRewind` (`$719B`)

**Print bank 6 `$C93E`**

Witness: L1 25 (c1, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 86 t-states own (0.00 %) |
| Runs (the other recordings) | 23 calls (`stage1/play2` 6, `stage1/play` 3, `stage1/menu` 2 and 6 more) |
| Called from | `LoadDirectory` |
| Calls | `PrintString` (tail) |

### `IsMissionHeader` (`$71A1`)

**Z if the header at `$8AF2` starts "MISSHDR:" (8 bytes)**

Witness: L1 19 (c1, m10, m2erbe, m2ocean, missions, search).

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

Witness: L1 12 (c1, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 51 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/play2` 3, `stage1/m2ocean` 1, `stage1/death` 1 and 6 more) |
| Called from | `LoadDirectory` |
| Calls | `CompareNine` (tail) |

### `IsCatalogue` (`$71BB`)

**Z if the catalogue at `$CB64` starts "MISSION:T"**

Witness: L1 12 (c1, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 20 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/play2` 3, `stage1/death` 1, `stage1/m10` 1 and 6 more) |
| Called from | `LoadDirectory` |
| Calls | `CompareNine` |

### `CompareNine` (`$71C1`)

**B = 9, then CompareB**

Witness: L1 24 (c1, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 14 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/play2` 6, `stage1/menu` 2, `stage1/death` 2 and 6 more) |
| Called from | `IsDirectoryHeader` (tail), `IsCatalogue` |
| Calls | `CompareB` |
| Reads | `$71DD`-`$71EF` (`DirectoryName`, `CatalogueName`); `$8AF2`-`$8AFA` (`BackBuffer+1`) |

### `CompareB` (`$71C3`)

**Compare B bytes at DE and HL: Z when equal**

Witness: L1 41 (c1, m10, m2erbe, m2ocean, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3 calls, 1,283 t-states own (0.00 %) |
| Runs (the other recordings) | 38 calls (`stage1/missions` 11, `stage1/play2` 9, `stage1/m2ocean` 3 and 5 more) |
| Called from | `IsMissionHeader` (tail), `CompareNine` |
| Reads | `$71D5`-`$71EF` (`MissionHeaderName+1`, `DirectoryName`, `CatalogueName`); `$8AF2`-`$8AFA` (`BackBuffer+1`) |

## tape

`src/game/tape.asm`

### `LoadBlock` (`$71F1`)

**Load a tape block to IX, length DE, flag A (carry: load) with the sound and the menu's flag set aside**

Under `DI`, with bank 6 `$D27C` (the pointer's save) and `$D283` = `$C010`, calls `LdBytes` `$8617`; restores `$D283` = `$C000` and the border, carry = loaded. Witness: L1 68 (c1, m10, m2erbe, m2ocean, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 1,615 t-states own (0.00 %) |
| Runs (the other recordings) | 64 calls (`stage1/missions` 19, `stage1/m2ocean` 12, `stage1/play2` 10 and 6 more) |
| Called from | `LoadDirectory`, `LoadMission`, `LoadMissionHeader` |
| Calls | `BorderBlack`, `PageBank6`, `SaveBank`, `RestoreBank`, `LdBytes` |

### `LdBytes` (`$8617`)

**The game's copy of the ROM's LD-BYTES (`$0556`): IX, DE, A, carry; border stripes; NC on an error**

The timings are the ROM's; the border colours of the stripes come from C. A block shorter than DE ends in a time-out of the edge reader (`LdEdge2` `$869F`), `RET NC`: Ocean's mission 2 header asks for 6406 bytes, its block holds 6384 (src/tape/side2.txt), so `LoadMissionBlock` retries for ever (m2ocean). Witness: L1 68 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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

Witness: L1 1682113 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 122,820 calls, 2,702,040 t-states own (0.41 %) |
| Runs (the other recordings) | 1,559,293 calls (`stage1/missions` 520,787, `stage1/m2ocean` 269,839, `stage1/play2` 238,986 and 6 more) |
| Called from | `LdBytes` |
| Calls | `LdEdge1` |

### `LdEdge1` (`$86A3`)

**One edge (the ROM's LD-EDGE-1), SPACE breaks**

Witness: L1 3507210 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 255,183 calls, 300,007,693 t-states own (45.37 %) |
| Runs (the other recordings) | 3,252,027 calls (`stage1/missions` 1,067,529, `stage1/m2ocean` 563,928, `stage1/play2` 507,394 and 6 more) |
| Called from | `LdBytes`, `LdEdge2` |
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

Witness: L1 3742 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 124 calls, 611,226 t-states own (0.09 %) |
| Runs (the other recordings) | 3,614 calls (`stage1/death` 2,513, `stage1/play2` 425, `stage1/missions` 348 and 6 more) |
| Called from | `BriefingMapLegend`, `StatusMapLegend`, `FirstFrameHook` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$83BA` (`BlitRequest+1`) |

### `BriefingMapLegend` (`$722C`)

**The briefing map's legend: wait for the frame, the attribute boxes `$DB01` and `$DB0B`, the text `$DAE1` ("Roads." / "Rivers."); called by bank 6 BriefingMap `$DB64`**

Witness: L1 10 (menu, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10 calls (`stage1/menu` 10) |
| Calls | `AttrBox`, `PrintString` (tail), `WaitFrameDone` |

### `StatusMapLegend` (`$7241`)

**The status view map's legend: wait for the frame, the boxes `$DB10` and `$DAC1`, the text `$DAA1`; called by bank 6 StatusMap `$DB15`**

Witness: L1 40 (menu, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 40 calls (`stage1/missions` 34, `stage1/m2erbe` 4, `stage1/play` 2) |
| Calls | `AttrBox`, `PrintString`, `WaitFrameDone` |

### `FirstFrameHook` (`$7256`)

**A NOP the first time: WaitFrameDone, then patched to RET**

Witness: L1 6587 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 289 calls, 8,095 t-states own (0.00 %) |
| Runs (the other recordings) | 6,283 calls (`stage1/death` 2,637, `stage1/play2` 1,458, `stage1/missions` 1,171 and 6 more) |
| Called from | `StartMission`, `PlayLoopTail`, `DragonflyViewLoop` |
| Calls | `WaitFrameDone`, `PageBank0Main` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$7256` (`FirstFrameHook`) |

### `PageBank0Main` (`$725F`)

**A = 0 then PageMain**

Witness: L1 3735 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 124 calls, 633 t-states own (0.00 %) |
| Runs (the other recordings) | 3,607 calls (`stage1/death` 2,512, `stage1/play2` 425, `stage1/missions` 316 and 6 more) |
| Called from | `DamageLoop`, `FirstFrameHook` |
| Calls | `PageMain` |

### `PageMain` (`$7260`)

**Set the screen bit (`$7284`, the OR operand) to A and re-page the current bank**

Witness: L1 3878 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 130 calls, 5,516 t-states own (0.00 %) |
| Runs (the other recordings) | 3,740 calls (`stage1/death` 2,515, `stage1/play2` 440, `stage1/missions` 374 and 6 more) |
| Called from | `PageBank0Main`, `PageShadowScreen` (tail) |
| Calls | `PageOut` (tail) |
| Reads | `$728A` (`SaveBank+2`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$7284` (`PageOut+4`) |

### `PageShadowScreen` (`$7268`)

**A = 8 (the shadow screen bit of `$7FFD`) then PageMain**

Witness: L1 143 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6 calls, 149 t-states own (0.00 %) |
| Runs (the other recordings) | 133 calls (`stage1/missions` 58, `stage1/menu` 33, `stage1/play2` 15 and 6 more) |
| Called from | `StartMission`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `PageMain` (tail) |

### `PageBank3` (`$726C`)

**Page bank 3 at `$C000`**

Witness: L1 158933 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11,125 calls, 312,339 t-states own (0.05 %) |
| Runs (the other recordings) | 147,491 calls (`stage1/missions` 65,118, `stage1/play2` 34,565, `stage1/death` 24,252 and 6 more) |
| Called from | `Bank3SetObject`, `Bank3Step`, `Bank3Lookup`, `Bank3Render`, `Bank3Fill`, `LoadMission`, `Debris`, `DrawEntry` |
| Calls | `PageBankA` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `PageBank4` (`$7270`)

**Page bank 4 at `$C000`**

Witness: L1 76703 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,423 calls, 86,465 t-states own (0.01 %) |
| Runs (the other recordings) | 72,017 calls (`stage1/death` 15,296, `stage1/play2` 14,436, `stage1/missions` 14,068 and 6 more) |
| Called from | `CopyCatalogueHead`, `CopyMissionText`, `LoadDirectory`, `Bank4Start`, `Bank4Tick`, `Bank4Call` |
| Calls | `PageBankA` (tail) |

### `PageBank7` (`$7274`)

**Page bank 7 at `$C000`**

Witness: L1 122 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 95 t-states own (0.00 %) |
| Runs (the other recordings) | 115 calls (`stage1/missions` 50, `stage1/menu` 28, `stage1/play2` 12 and 6 more) |
| Called from | `DrawBank7Picture` |
| Calls | `PageBankA` (tail) |

### `PageBank6` (`$7278`)

**Page bank 6 at `$C000`**

Witness: L1 206018 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 12,131 calls, 236,130 t-states own (0.04 %) |
| Runs (the other recordings) | 193,204 calls (`stage1/missions` 39,950, `stage1/play2` 38,989, `stage1/death` 33,419 and 6 more) |
| Called from | `Entry`, `ResetCollisionTables` (tail), `StartMission`, `PlayLoopTail`, `DragonflyViewLoop`, `PanelSetup`, `StatusLoop`, `DamageLoop`, `ShowBriefingMapOnce`, `CopyCatalogueHead`, `CopyMissionText`, `LoadDirectory`, `LoadBlock`, `Bank3Render` (tail), `UpdateSlotBars`, `DrawBank7Picture`, `LoadMissionIfAllowed`, `PageBank6Kept` (tail), `QuitKey`, `LoadMission`, `LoadMissionHeader` (tail), `MissionSetup` |
| Calls | `PageBankA` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `PageBank0` (`$727C`)

**Page bank 0 at `$C000`**

Witness: L1 181126 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 12,132 calls, 58,229 t-states own (0.01 %) |
| Runs (the other recordings) | 168,750 calls (`stage1/missions` 69,617, `stage1/play2` 36,976, `stage1/death` 20,661 and 6 more) |
| Called from | `ResetCollisionTables`, `StartMission`, `DragonflyViewLoop`, `PanelSetup` (tail), `StatusLoop`, `DamageLoop`, `Bank0SoundOff`, `SoundTick`, `LoadMission`, `MissionSetup` |
| Calls | `PageBankA` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `PageBankA` (`$727D`)

**Page bank A: kept in `$728A`, OR the screen bit, OUT to `$7FFD`**

Witness: L1 870750 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 54,728 calls, 810,821 t-states own (0.12 %) |
| Runs (the other recordings) | 813,537 calls (`stage1/missions` 235,278, `stage1/play2` 172,428, `stage1/death` 143,043 and 6 more) |
| Called from | `PageBank3` (tail), `PageBank4` (tail), `PageBank7` (tail), `PageBank6` (tail), `PageBank0`, `RestoreBank`, `DrawBank7Picture` (tail), `PageBankKept` (tail) |
| Calls | `PageOut` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$728A` (`SaveBank+2`) |

### `PageOut` (`$7280`)

**PageOut**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 54,858 calls, 2,447,543 t-states own (0.37 %) |
| Runs (the other recordings) | 817,277 calls (`stage1/missions` 235,652, `stage1/play2` 172,868, `stage1/death` 145,558 and 6 more) |
| Called from | `PageMain` (tail), `PageBankA` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Ports out | `$7FFD` |

### `SaveBank` (`$7288`)

**Keep the current bank (`$728A`) in the operand `$729D` of RestoreBank**

Witness: L1 51896 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,278 calls, 201,645 t-states own (0.03 %) |
| Runs (the other recordings) | 48,310 calls (`stage1/death` 18,837, `stage1/play2` 10,541, `stage1/missions` 9,592 and 6 more) |
| Called from | `StartMission`, `ShowBriefingMapOnce`, `CopyCatalogueHead`, `CopyMissionText`, `LoadBlock`, `Bank3SetObject`, `Bank3Step`, `Bank3Lookup`, `Bank4Start`, `Bank0SoundOff`, `Bank4Call`, `UpdateSlotBars`, `Bank3Fill`, `QuitKey`, `Debris`, `DrawEntry` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$729D` (`RestoreBank+2`) |

### `Bank3SetObject` (`$7290`)

**Save the bank, call bank 3 `$C4C4` with A, restore**

Witness: L1 38817 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,908 calls, 262,067 t-states own (0.04 %) |
| Runs (the other recordings) | 35,608 calls (`stage1/death` 11,167, `stage1/play2` 8,320, `stage1/missions` 8,192 and 6 more) |
| Called from | `OpFillFaces`, `FillFaceList`, `FillFaceListClipped`, `OpFillPolys`, `OpFillPolysClipped` |
| Calls | `PageBank3`, `SaveBank` |

### `RestoreBank` (`$729B`)

**Page the bank SaveBank kept (A and the flags kept)**

Witness: L1 13069 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 370 calls, 217,836 t-states own (0.03 %) |
| Runs (the other recordings) | 12,693 calls (`stage1/death` 7,669, `stage1/play2` 2,220, `stage1/missions` 1,399 and 6 more) |
| Called from | `StartMission`, `ShowBriefingMapOnce`, `CopyCatalogueHead` (tail), `CopyMissionText` (tail), `LoadBlock`, `Bank3Step` (tail), `Bank3Lookup` (tail), `Bank4Start` (tail), `Bank0SoundOff` (tail), `Bank4Call` (tail), `UpdateSlotBars`, `Bank3Fill` (tail), `QuitKey`, `Debris` (tail), `DrawEntry` |
| Calls | `PageBankA` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `Bank3Step` (`$72A3`)

**Save the bank, call bank 3 `$D08C` and `$D1EC`, restore**

Witness: L1 3602 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 11,780 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop` |
| Calls | `PageBank3`, `SaveBank`, `RestoreBank` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `Bank3Lookup` (`$72B1`)

**Save the bank, call bank 3 `$C9A7` with A, restore**

Witness: L1 4996 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 12,282 t-states own (0.00 %) |
| Runs (the other recordings) | 4,882 calls (`stage1/death` 2,261, `stage1/play2` 1,192, `stage1/missions` 733 and 3 more) |
| Called from | `OpLines`, `OpLinesClipped` |
| Calls | `PageBank3`, `SaveBank`, `RestoreBank` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `Bank3Render` (`$72BE`)

**Page bank 3, run the 3D frame driver `$990F`, page bank 6**

Witness: L1 2954 (c1, death, m2erbe, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 171 calls, 12,136 t-states own (0.00 %) |
| Runs (the other recordings) | 2,768 calls (`stage1/play2` 1,045, `stage1/missions` 897, `stage1/play` 432 and 6 more) |
| Calls | `PageBank3`, `PageBank6` (tail), `RunScript` |

### `Bank4Start` (`$72C6`)

**Save the bank, call bank 4 `$C000` with A = 0, restore**

Witness: L1 21 (c1, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 225 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/missions` 8, `stage1/menu` 4, `stage1/play2` 3 and 2 more) |
| Calls | `PageBank4`, `SaveBank`, `RestoreBank` (tail) |

### `Bank4Tick` (`$72D2`)

**The interrupt's call of bank 4 `$C0D2`, the bank kept and restored**

Witness: L1 76552 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,415 calls, 274,701 t-states own (0.04 %) |
| Runs (the other recordings) | 71,878 calls (`stage1/death` 15,291, `stage1/play2` 14,418, `stage1/missions` 14,024 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `PageBank4`, `PageBank6Kept`, `PageBankKept` (tail) |

### `Bank0SoundOff` (`$72DE`)

**Save the bank, call bank 0 `$D807` (the sound off), restore**

Witness: L1 21 (c1, menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 145 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/missions` 8, `stage1/menu` 4, `stage1/play2` 3 and 2 more) |
| Calls | `PageBank0`, `SaveBank`, `RestoreBank` (tail), `SilenceAY` |

### `Bank4Call` (`$72E9`)

**Save the bank, call bank 4 `$C1A2`, restore**

Witness: L1 29 (c1, menu, missions, search).

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
| Calls | `DrawWeaponBars` |

### `DrawWeaponBars` (`$72F9`)

**Redraw each weapon record of `$68AB` whose value changed: its bar through DrawBar**

Witness: L1 4 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play` 4) |
| Called from | `DrawSlotBarsLow` (tail), `DrawSlotBars` |
| Calls | `DrawBar` |
| Reads | `$68AB`-`$68E1` (`GaugeRecords`, `SlotGauges`) |
| Writes | `$68AC`-`$68DC` (`GaugeRecords+1`, `SlotGauges`); `$7309` (`l_72FF+10`) |

### `UpdateSlotBars` (`$7327`)

**Bank 6 UpdatePanelBars `$D58C` (heading strip, bearing, speed, fuel), then UpdateAmmoBars**

Witness: L1 3601 (death, m2erbe, missions, play, play2).

[Animation: `UpdateSlotBars` at work](img/routines/UpdateSlotBars.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 11,794 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoopTail` |
| Calls | `PageBank6`, `SaveBank`, `RestoreBank`, `UpdateAmmoBars` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `UpdateAmmoBars` (`$7336`)

**For the four slots of `$8368`: a bar for each ammunition count that changed (records `$68C9`)**

Witness: L1 3628 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 94,726 t-states own (0.01 %) |
| Runs (the other recordings) | 3,509 calls (`stage1/death` 2,511, `stage1/play2` 416, `stage1/missions` 289 and 2 more) |
| Called from | `StartMission`, `UpdateSlotBars` |
| Calls | `DrawBar` |
| Reads | `$68C9`-`$68E0` (`SlotGauges`); `$82FF`-`$8300` (`Im2Table+255`); `$8368`-`$837A` (`WeaponSlots`) |
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
| Runs | not reached in the recordings |

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

Witness: L1 27 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 1,116 t-states own (0.00 %) |
| Runs (the other recordings) | 26 calls (`stage1/missions` 16, `stage1/play` 4, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission` |
| Calls | `DrawIcon` |
| Reads | `$68CD`-`$68E0` (`SlotGauges+4`); `$8368`-`$837A` (`WeaponSlots`) |

### `DrawIcon` (`$73E8`)

**Draw weapon icon A (1-19) from the icon table `$75CA` through CopyGraphic, 3 x 24**

Witness: L1 117 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 819 t-states own (0.00 %) |
| Runs (the other recordings) | 113 calls (`stage1/missions` 64, `stage1/play` 25, `stage1/play2` 12 and 2 more) |
| Called from | `DrawDamagePanel`, `DrawSlotIcons` |
| Calls | `CopyGraphic` (tail) |
| Reads | `$75CA`-`$75EF` (`IconTable`); `$82FF`-`$8300` (`Im2Table+255`) |
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

Witness: L1 3794 (death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 139 calls, 17,261 t-states own (0.00 %) |
| Runs (the other recordings) | 3,655 calls (`stage1/death` 2,523, `stage1/play2` 457, `stage1/missions` 362 and 2 more) |
| Calls | `BarLines` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$7476`-`$747D` (`BarLines+18`); `$7494`-`$7497` (`l_747E+22`) |

### `DrawBar` (`$744F`)

**A bar of A pixels on line E, `$F8` pattern, 24 wide**

Witness: L1 5389 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 12,389 t-states own (0.00 %) |
| Runs (the other recordings) | 5,270 calls (`stage1/death` 2,511, `stage1/play2` 1,418, `stage1/play` 1,009 and 2 more) |
| Called from | `DrawWeaponBars`, `UpdateAmmoBars` |
| Calls | `BarLines` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$7476`-`$747D` (`BarLines+18`); `$7494`-`$7497` (`l_747E+22`) |

### `BarLines` (`$7464`)

**The bar's pixel lines through the line table `$6500`, `$AA` / `$55` dither**

Witness: L1 9183 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 258 calls, 757,422 t-states own (0.11 %) |
| Runs (the other recordings) | 8,925 calls (`stage1/death` 5,034, `stage1/play2` 1,875, `stage1/play` 1,270 and 2 more) |
| Called from | `DrawBarWide` (tail), `DrawBar` |
| Reads | `$6500`-`$654F` (`ScreenRowTable`); `$6570`-`$659F` (`ScreenRowTable+112`); `$65C0`-`$65EF` (`ScreenRowTable+192`); `$6610`-`$665F` (`ScreenRowTable+272`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$400A`-`$4ADD` (screen); `$4B16`-`$4BDD` (screen); `$4C16`-`$4CDD` (screen); `$4D16`-`$4DDD` (screen); `$4E16`-`$4EDD` (screen); `$4F16`-`$4FDD` (screen); 2 more ranges |

### `DrawBank7Picture` (`$74AA`)

**Page bank 7 and run its picture routine `$FE95` with DE (a picture), then the bank back**

The panels and frames of the views are bank 7's pictures (DE = `$DD75` play, `$F9CD` map, `$D325` status, `$C000` Dragonfly). Clears `$83BF` (the play flag of the interrupt) and resets bank 6's `$D283` = `$C000`. Witness: L1 122 (c1, death, m2erbe, menu, missions, play, play2, search).

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

Witness: L1 15 (menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 19 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 1 and 2 more) |
| Calls | `Bank3Fill` (tail) |

### `Bank3Fill5F` (`$74CD`)

**A = `$5F` then Bank3Fill**

Witness: L1 15 (menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 7 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 2 more) |
| Calls | `Bank3Fill` |

### `Bank3Fill` (`$74CF`)

**Save the bank, call bank 3 `$CFCD` with A, restore**

Witness: L1 30 (menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 208 t-states own (0.00 %) |
| Runs (the other recordings) | 28 calls (`stage1/missions` 16, `stage1/play2` 6, `stage1/m2erbe` 2 and 2 more) |
| Called from | `Bank3FillFF` (tail), `Bank3Fill5F` |
| Calls | `PageBank3`, `SaveBank`, `RestoreBank` (tail) |

### `Bank0Call` (`$74DD`)

**Page bank 0, call `$CEA4`, page bank 6**

Witness: known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScreenOfMission` (`$757C`)

**Screen 1 unless the current mission (`$757D`) is `$FF` or not completed**

`LD A,n`: n (`$757D`) is the mission the tape gave (`$8528`: the header's digit - "1"). Witness: L1 10 (play).

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
| Runs | not reached in the recordings |

### `LoadMissionIfAllowed` (`$759A`)

**Load the mission the tape holds; mission 10 only when the nine completion flags are set**

If the current mission (C) is 9 (Grand Finale), the nine bytes `$6799-$67A1` are ANDed: if any is 0 the mission is refused (`RET Z` back into the catalogue's zone loop; recording m10: the catalogue stays on screen, 4972-7972). Otherwise `LoadMission` `$84C1`. Witness: L1 18 (m10, m2erbe, m2ocean, missions).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 232 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/missions` 9, `stage1/play2` 3, `stage1/m10` 1 and 4 more) |
| Called from | `PointerZones` |
| Calls | `ScreenZero` (tail), `PageBank6`, `MissionDone`, `LoadMission` |
| Reads | `$6799`-`$67A1` (`MissionsDone`); `$757D` (`ScreenOfMission+1`) |

### `MissionDone` (`$75BB`)

**A = the completion flag of the current mission (`$6799` + n): NZ when done**

Witness: L1 28 (m10, m2erbe, m2ocean, missions, play).

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

Witness: L1 61 (death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 20 calls, 1,464 t-states own (0.00 %) |
| Runs (the other recordings) | 41 calls (`stage1/play2` 40, `stage1/death` 1) |
| Called from | `PlayerHit` |
| Reads | `$762F` (`PlayerY+25`); `$7797` (`PlayerY+385`); `$77D3` (`PlayerY+445`); `$78C3` (`PlayerY+685`); `$7977` (`PlayerY+865`); `$79B3` (`PlayerY+925`); 4 more ranges |
| Writes | `$7D5D`-`$7D64` (`MessageOnce`) |

### `MessageOnce` (`$7D5D`)

**Once after SetMessage: the timer `$87D7` = 100; bit 4 of `$7D64` set: SoundExplosion `$D86B` and "TANK:HIT" `$FFCF`, clear: SoundEffectA `$D84E` and "COLLIDED" `$FFDB`; then RET again**

Patched to `RET` after one run. Witness: L1 3601 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 4,432 t-states own (0.00 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoopTail` |
| Calls | `PrintString`, `SoundEffectA`, `SoundExplosion` |
| Writes | `$7D5D` (`MessageOnce`); `$87D7` (`MessageTimer+1`) |

### `PointerTick` (`$7D80`)

**Read the controls, move the pointer within the screen, test the fire**

`ReadControls` `$971A`, the X and Y steps (`$985E`, `$985F`) added to the pointer (`$7DC0`, `$7DC1`) within 8-247 and 8-183, then `PointerFire` `$7DC2`. Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

[Animation: `PointerTick` at work](img/routines/PointerTick.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 625,584 t-states own (0.09 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `ClampStep`, `PointerFire`, `ReadControls` |
| Reads | `$83BF` (`PointerShown+1`); `$985E`-`$985F` (`StepX`, `StepY`) |
| Writes | `$66CE` (`PolyClipVars+2`) |

### `ClampStep` (`$7DA7`)

**ClampStep**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,180 calls, 400,749 t-states own (0.06 %) |
| Runs (the other recordings) | 92,258 calls (`stage1/missions` 19,996, `stage1/play2` 19,046, `stage1/menu` 13,868 and 6 more) |
| Called from | `PointerTick` |
| Reads | `$7DC0`-`$7DC1` (`PointerPos`) |
| Writes | `$7DC0`-`$7DC1` (`PointerPos`) |

### `PointerFire` (`$7DC2`)

**Carry (the fire) held: after 25 frames a click (`$6D43` = `$FF`) at the pointer, repeated every 5**

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 159,201 t-states own (0.02 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `PointerTick` |
| Reads | `$7C51`-`$7C53` (`FailReason+88`); `$9717`-`$9718` (`FireHeld`, `FireCount`) |
| Writes | `$6D43` (`PointerZones+1`); `$9715`-`$9718` (`ClickState`, `ClickY`, `FireHeld`, `FireCount`) |

### `ClockTick` (`$7DFB`)

**The mission clock: the first second after 50 interrupts, then one second for every interrupt taken (the reload at `$7E03` is 1): 50 game seconds a real second**

The seconds, minutes and hours are in `$68EA`. A `NOP` while it runs; the mission header's loader puts `RET` here (`$8612`) until play. Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 395,013 t-states own (0.06 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$68EA`-`$68EC` (`MissionClock`) |
| Writes | `$68EA`-`$68EC` (`MissionClock`); `$7DFD` (`ClockTick+2`) |

### `PrintClock` (`$7E3A`)

**Print the clock's minutes and hours (`$68EB`, `$68EC`) as two digit pairs**

Witness: L1 530 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 530 calls (`stage1/play` 492, `stage1/missions` 34, `stage1/m2erbe` 4) |
| Called from | `StatusLoop`, `BriefPage` |
| Calls | `PrintString` (tail) |
| Reads | `$68EB`-`$68EC` (`MissionClock+1`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$7E34`-`$7E38` (`ClockText+5`) |

### `SoundTick` (`$7E6E`)

**The interrupt's sound step: bank 0's driver `$D692`, the bank kept**

Witness: L1 69896 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 251,564 t-states own (0.04 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `PageBank0`, `PageBank6Kept`, `PageBankKept` (tail), `SoundFrame` |

### `ClearPointerState` (`$7E7A`)

**`$66CE` and the click flag cleared**

Witness: L1 2966 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 171 calls, 8,134 t-states own (0.00 %) |
| Runs (the other recordings) | 2,779 calls (`stage1/play2` 1,045, `stage1/missions` 898, `stage1/play` 433 and 6 more) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$66CE` (`PolyClipVars+2`); `$6D43` (`PointerZones+1`) |

### `InterruptHandler` (`$8383`)

**The IM 2 handler: own stack, the tick jobs, the play or menu jobs, RETI**

Witness: L1 69896 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 1,987,279 t-states own (0.30 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Entered by | the interrupt, 38,000 times in 209 routines |
| Calls | `Bank4Tick`, `PointerTick`, `ClockTick`, `SoundTick`, `ClearMarkColumn`, `HandlerExit` (tail), `PageBank6Kept`, `PageBankKept`, `BlinkWarning`, `BlinkLamp`, `KeyRepeat`, `MessageTimer`, `TimeOfDay`, `SkyColours`, `NightColours`, `CopyPointer`, `ViewBlitFront`, `ViewBlitWide`, `ViewBlitNarrow`, `ClearBlitRequest` |
| Reads | `$83BF` (`PointerShown+1`) |
| Writes | `$815D`-`$81FE` (`LoadAttrLeftover+281`, `ImJump`, `Stack`); `$842B`-`$842C` (`SavedSP+1`); `$FD00`-`$FD07` (`MissionHeader+8507`); `$FD42`-`$FD53` (`MissionHeader+8573`); `$FE00`-`$FE07` (`MissionHeader+8763`); `$FE42`-`$FE53` (`MissionHeader+8829`); 2 more ranges |

### `ClearMarkColumn` (`$83F1`)

**A RET; behind it the clear of three bytes every 33 for 48 lines from `$8AF1` (unused)**

Witness: L1 2959 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 171 calls, 336,408 t-states own (0.05 %) |
| Runs (the other recordings) | 2,773 calls (`stage1/play2` 1,042, `stage1/missions` 897, `stage1/play` 430 and 6 more) |
| Called from | `InterruptHandler` |
| Writes | `$8AF1`-`$8FF3` (`BackBuffer`); `$9011`-`$9013` (`BackBuffer+1312`); `$9031`-`$9033` (`BackBuffer+1344`); `$9051`-`$9053` (`BackBuffer+1376`); `$9071`-`$9073` (`BackBuffer+1408`); `$9091`-`$9093` (`BackBuffer+1440`); 2 more ranges |

### `HandlerExit` (`$841C`)

**HandlerExit**

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,205 calls, 698,006 t-states own (0.11 %) |
| Runs (the other recordings) | 22,173 calls (`stage1/death` 10,155, `stage1/play2` 4,476, `stage1/missions` 3,710 and 6 more) |
| Called from | `InterruptHandler` (tail) |

### `PageBank6Kept` (`$8431`)

**Keep the current bank in `$843B` and page bank 6**

Witness: L1 195831 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11,629 calls, 418,788 t-states own (0.06 %) |
| Runs (the other recordings) | 183,536 calls (`stage1/play2` 36,898, `stage1/missions` 36,833, `stage1/death` 30,572 and 6 more) |
| Called from | `Bank4Tick`, `SoundTick`, `InterruptHandler` |
| Calls | `PageBank6` (tail) |
| Reads | `$728A` (`SaveBank+2`) |
| Writes | `$843B` (`PageBankKept+1`) |

### `PageBankKept` (`$843A`)

**Page the bank PageBank6Kept kept**

Witness: L1 195831 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11,629 calls, 197,693 t-states own (0.03 %) |
| Runs (the other recordings) | 183,536 calls (`stage1/play2` 36,898, `stage1/missions` 36,833, `stage1/death` 30,572 and 6 more) |
| Called from | `Bank4Tick` (tail), `SoundTick` (tail), `InterruptHandler` |
| Calls | `PageBankA` (tail) |

### `QuitKey` (`$843F`)

**The key E: silence the AY (`$D807`), ask "Are you sure you want to quit?" (bank 6 QuitPrompt `$DA09`: Y to the title, N back), then clear SoundGate `$D689` and PickupAnnounce `$DB71`**

Witness: L1 13 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 1 more) |
| Called from | `PlayKeys` (tail) |
| Calls | `PageBank6`, `SaveBank`, `RestoreBank`, `SilenceAY` |
| Writes | `$D689` (`SoundGate`); `$DB71` (`PickupAnnounce`) |

### `BlinkWarning` (`$8459`)

**Every 12 frames flip the attribute bits `$30` of `$5758` and `$5078` (a RET while off)**

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 76,770 t-states own (0.01 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$5078` (screen); `$5758` (screen) |
| Writes | `$5078` (screen); `$5758` (screen); `$845B` (`BlinkWarning+2`) |

### `BlinkLamp` (`$8475`)

**Every 8 frames flip `$3C` on four pixel lines at `$525C` (a RET while off)**

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 41,240 t-states own (0.01 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$525C` (screen); `$535C` (screen); `$545C` (screen); `$555C` (screen) |
| Writes | `$525C` (screen); `$535C` (screen); `$545C` (screen); `$555C` (screen); `$8477` (`BlinkLamp+2`) |

### `KeyRepeat` (`$848F`)

**Scan the keyboard: a new key sets bit 0 of `$8978` at once, a held key after 17 frames, then every 2**

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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
| Calls | `ToggleNight` |

### `ToggleNight` (`$87FF`)

**Night sight on or off: the lamp attribute `$5ACF`, the text `$BA6E` / `$BA7A`, `$757A` from the table `$88F8`**

Witness: L1 33 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 151 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/missions` 16, `stage1/play` 10, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission`, `NightKey` |
| Calls | `PrintString` (tail) |
| Reads | `$88FB`-`$8907` (`HourTable+3`) |
| Writes | `$5ACF` (screen); `$6B45` (`PlayKeys+10`); `$757A` (`AwolState+2`); `$87FD` (`NightKey+1`); `$885F` (`SkyColours`); `$88CF` (`NightColours`) |

### `TimeOfDay` (`$8836`)

**Each interrupt: the hour (`$68EC`) against the four 4-byte rows of `$88F8`; a match arms `$885F`**

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 936,113 t-states own (0.14 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `InterruptHandler` |
| Reads | `$68EC` (`MissionClock+2`); `$88F8`-`$8904` (`HourTable`) |
| Writes | `$8823`-`$8824` (`l_8818+11`); `$8845` (`l_8841+4`); `$885F` (`SkyColours`); `$88D6` (`NightBoxSelect+1`) |

### `SkyColours` (`$885F`)

**Once per change: the sky and ground attributes of the hour's row, then the panel's copies**

Witness: L1 6657 (c1, death, m2erbe, missions, play, play2).

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
| Called from | `NightColours` (tail) |
| Reads | `$5940` (screen); `$5960`-`$596E` (screen); `$59A0`-`$59AA` (screen) |
| Writes | `$59C0`-`$59E2` (screen); `$59FD`-`$59FE` (screen) |

### `NightColours` (`$88CF`)

**Once: the night or day attribute box (`$88EE` / `$88F3`)**

Witness: L1 6657 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 291 calls, 3,192 t-states own (0.00 %) |
| Runs (the other recordings) | 6,349 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,213 and 6 more) |
| Called from | `InterruptHandler` |
| Calls | `AttrBox`, `CopySkyRows` (tail) |
| Writes | `$757A` (`AwolState+2`); `$88CF` (`NightColours`) |

### `NightBoxSelect` (`$88D5`)

**NightBoxSelect**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScanKeyboard` (`$8910`)

**Scan the eight half rows: the key's code from `$8950` to `$897B`, bit 1 of `$8978` set; CAPS SHIFT with 0 gives `$04` (the code entry's delete)**

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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

Witness: L1 49405 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,092 calls, 191,748 t-states own (0.03 %) |
| Runs (the other recordings) | 46,146 calls (`stage1/missions` 10,006, `stage1/play2` 9,526, `stage1/menu` 6,938 and 6 more) |
| Called from | `InterruptHandler` |
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

Pages bank 0, `$CC1E` with IX = `$75F0`; clears `$BA27`, `$CEA8`, `$87FD`, `$C4DC`. If the mission asked for (`$757D`) is the one loaded last (`$7E2E`), the bank-3 copy of `$DBDA`... is copied back to bank 0 (no tape). Else `$8551`: load the 17-byte header with "MISSHDR:" (`$84FE`), then the block of the header's length to `$DBC5`; SPACE stops. Then `$85F5` and `$8598` set the play state from the block. Witness: L1 16 (m10, m2erbe, m2ocean, missions).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 714,554 t-states own (0.11 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/death` 1 and 3 more) |
| Called from | `LoadMissionIfAllowed` |
| Calls | `LoadBlock`, `PageBank3`, `PageBank6`, `PageBank0`, `MissionSetup`, `SpacePressed`, `MissionTimeSetup`, `ResetPlayerHandler` |
| Reads | `$757D` (`ScreenOfMission+1`); `$7E2E` (`LastLoadedMission`); `$82FF`-`$8300` (`Im2Table+255`); `$DBC5` (`MissionHeader`); `$DBDA`-`$DBDC` (`MissionHeader+21`); `$DBED`-`$FB3E` (`MissionHeader+40`) |
| Writes | `$6952` (`StartMission+7`); `$757B` (`AwolState+3`); `$7E2E` (`LastLoadedMission`); `$7E82`-`$7E8D` (`MissionParams`); `$84E6`-`$84E7` (`LoadMission+37`); `$87FD` (`NightKey+1`); 7 more ranges |

### `LoadMissionHeader` (`$84FE`)

**Load 17-byte headers until one is "MISSHDR:"; its length to `$855C`, its digit - "1" to `$757D`, the mark on the clipboard**

Witness: L1 21 (m10, m2erbe, m2ocean, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 318 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/missions` 9, `stage1/play2` 3, `stage1/search` 3 and 5 more) |
| Called from | `PointerZones` |
| Calls | `IsMissionHeader`, `LoadBlock`, `PageBank6` (tail), `MarkMission` |
| Reads | `$8AFA`-`$8AFD` (`BackBuffer+9`) |
| Writes | `$58E3`-`$5902` (screen); `$5922` (screen); `$5942` (screen); `$5962` (screen); `$5982` (screen); `$59A2` (screen); 8 more ranges |

### `MarkMission` (`$8535`)

**The attribute C on the catalogue line of mission A (`$5902` + 32A)**

Witness: L1 24 (m10, m2erbe, m2ocean, missions, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 24 calls (`stage1/missions` 17, `stage1/play2` 5, `stage1/m2erbe` 2) |
| Called from | `LoadMissionHeader`, `RemarkMission` (tail) |
| Writes | `$5902` (screen); `$5922` (screen); `$5942`-`$5962` (screen); `$5982` (screen); `$59A2` (screen); `$59C2` (screen); 4 more ranges |

### `RemarkMission` (`$8548`)

**Mark the last header's mission again (`$C4`) unless none**

Witness: L1 32 (menu, missions, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 28 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/menu` 12, `stage1/missions` 9, `stage1/play2` 3 and 6 more) |
| Calls | `MarkMission` (tail) |
| Reads | `$8547` (`HeaderMission`) |

### `MissionSetup` (`$8598`)

**From the loaded block: 12 bytes to `$7E82`, `$DBFD` to `$CAAF`, the object count to bank 6, the objects copied to bank 3**

Witness: L1 3 (m2erbe, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play2` 3) |
| Called from | `LoadMission` |
| Calls | `PageBank6`, `PageBank0` |
| Reads | `$757D` (`ScreenOfMission+1`); `$82FF`-`$8300` (`Im2Table+255`); `$DBDC` (`MissionHeader+23`); `$DBF1`-`$DCBB` (`MissionHeader+44`) |
| Writes | `$6952` (`StartMission+7`); `$7E2E` (`LastLoadedMission`); `$7E82`-`$7E8D` (`MissionParams`); `$C529` (`WeaponVars+2`); `$CAAF` (`PlayerHit+10`); `$D52E` (`PlaceHelicarrier`) |

### `SpacePressed` (`$85EF`)

**NC when SPACE is held (port `$7FFE` bit 0)**

Witness: L1 8 (m2ocean, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/m2ocean` 8) |
| Called from | `LoadMission` |
| Ports in | `$7FFE` |

### `MissionTimeSetup` (`$85F5`)

**From the header: `$DBE1` to `$6A67`, 8 bytes `$DBE3` to `$7611`, the time limit `$DBFE` to `$68EB`, the clock stopped**

Witness: L1 15 (m10, m2erbe, m2ocean, missions).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 395 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/m2erbe` 1 and 2 more) |
| Called from | `LoadMission` |
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

Witness: L1 3600 (c1, death, m2erbe, missions, play, play2).

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

Witness: L1 458 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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

Witness: L1 6657 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 291 calls, 7,992 t-states own (0.00 %) |
| Runs (the other recordings) | 6,349 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,213 and 6 more) |
| Called from | `InterruptHandler` |
| Writes | `$83BA` (`BlitRequest+1`) |

### `ClearBackBuffer` (`$96F1`)

**Zero the back buffer `$8AF1-$96F0` with 1536 PUSH HL**

Under `DI`: `SP` saved at `$9711`, `SP` = `$96F1`, HL = 0, 96 x 16 `PUSH HL`, `SP` back, `EI`. An interrupt in this time is lost (WALKTHROUGH section 1). Once per 3D pass: its count is the number of passes (705 in play).

Witness: L1 6643 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

[Animation: `ClearBackBuffer` at work](img/routines/ClearBackBuffer.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 290 calls, 5,282,350 t-states own (0.80 %) |
| Runs (the other recordings) | 6,338 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,212 and 6 more) |
| Called from | `StartViewPass` |
| Writes | `$9711`-`$9712` (`l_96FE+19`) |

### `ClipLine2D` (`$A184`)

**Clip the line (HL, DE) - (HL', DE') (x, y words) to the window; carry = something to draw, H, L, D, E = the ends as bytes**

Witness: L1 6164 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 8,892 t-states own (0.00 %) |
| Runs (the other recordings) | 6,050 calls (`stage1/death` 2,494, `stage1/play2` 1,548, `stage1/missions` 975 and 3 more) |
| Called from | `OpLines`, `OpLinesClipped` |
| Calls | `ClipLineCodes` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `ClipLineCodes` (`$A192`)

**Cohen-Sutherland: both out codes (`$A3AC`), reject, accept, or cut an end by bisection (`$A1B3`, `$A218`)**

Witness: L1 6164 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 7,752 t-states own (0.00 %) |
| Runs (the other recordings) | 6,050 calls (`stage1/death` 2,494, `stage1/play2` 1,548, `stage1/missions` 975 and 3 more) |
| Called from | `ClipLine2D` |
| Calls | `ClipOneEnd`, `SwapLineEnds`, `ClipAccept` (tail), `ClipToRight` (tail), `ClipToBottom` (tail), `ClipToCorner` (tail), `ClipReject` (tail), `OutCode` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$A17E`-`$A17F` (`ClipWindow+2`) |
| Writes | `$985C`-`$985D` (`InputState`); `$A180`-`$A183` (`ClipWindow+4`); `$A277`-`$A28B` (`l_A26E+9`) |

### `ClipOneEnd` (`$A1B3`)

**One end outside: find the crossing of the window edge by bisection (`$A2BA`, `$A2CA`, `$A2F3`, `$A352`)**

Witness: L1 160 (missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 160 calls (`stage1/missions` 160) |
| Called from | `ClipLineCodes`, `ClipBothEnds` |
| Calls | `SwapLineEnds`, `ClipToRight` (tail), `ClipToBottom` (tail), `ClipToLeft` (tail), `ClipToCorner` (tail) |
| Reads | `$A17E`-`$A17F` (`ClipWindow+2`) |
| Writes | `$A180`-`$A183` (`ClipWindow+4`) |

### `SwapLineEnds` (`$A1F6`)

**Swap the two ends of the line between the register sets**

Witness: L1 273 (death, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 273 calls (`stage1/missions` 216, `stage1/death` 57) |
| Called from | `ClipLineCodes`, `ClipOneEnd` |

### `ClipBothEnds` (`$A218`)

**Both ends outside on different sides: bisect for the middle point, then clip each half**

Entered by a jump, never called (the survey counts 0 calls).

Witness: L1 0 (missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/missions`) |
| Calls | `ClipOneEnd`, `ClipAccept`, `ClipReject` (tail), `OutCode` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$985C`-`$985D` (`InputState`); `$A17C`-`$A17E` (`ClipWindow`) |
| Writes | `$985C`-`$985D` (`InputState`); `$A292`-`$A2A2` (`l_A26E+36`, `ClipAccept`) |

### `ClipAccept` (`$A29D`)

**Both ends inside: carry set**

Witness: L1 4885 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 1,596 t-states own (0.00 %) |
| Runs (the other recordings) | 4,771 calls (`stage1/death` 2,204, `stage1/play2` 1,192, `stage1/missions` 679 and 3 more) |
| Called from | `ClipLineCodes` (tail), `ClipBothEnds` |

### `ClipToRight` (`$A2BA`)

**Bisect the outside end towards the right edge**

Witness: L1 120 (death, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 120 calls (`stage1/missions` 99, `stage1/death` 21) |
| Called from | `ClipLineCodes` (tail), `ClipOneEnd` (tail) |
| Calls | `ClipBisectStep` |
| Reads | `$A180`-`$A183` (`ClipWindow+4`) |

### `ClipToBottom` (`$A2CA`)

**Bisect the outside end towards the bottom edge**

Witness: L1 80 (death, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 80 calls (`stage1/missions` 45, `stage1/death` 35) |
| Called from | `ClipLineCodes` (tail), `ClipOneEnd` (tail) |
| Calls | `ClipBisectStep` |
| Reads | `$A17C`-`$A183` (`ClipWindow`) |

### `ClipToLeft` (`$A2F3`)

**Bisect the outside end towards the left edge**

Witness: L1 14 (missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/missions` 14) |
| Called from | `ClipOneEnd` (tail) |
| Calls | `ClipBisectStep` |
| Reads | `$A17E`-`$A183` (`ClipWindow+2`) |

### `ClipToCorner` (`$A352`)

**Bisect the outside end towards a corner (two edges)**

Witness: L1 3 (death, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/missions` 2, `stage1/death` 1) |
| Called from | `ClipLineCodes` (tail), `ClipOneEnd` (tail) |
| Calls | `BisectToInside` |
| Reads | `$A17C`-`$A183` (`ClipWindow`) |

### `ClipReject` (`$A37F`)

**Both ends outside on one side: no carry**

Witness: L1 1168 (death, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,168 calls (`stage1/play2` 356, `stage1/play` 337, `stage1/missions` 242 and 1 more) |
| Called from | `ClipLineCodes` (tail), `ClipBothEnds` (tail) |

### `ClipBisectStep` (`$A381`)

**One bisection step of the outside end towards the window**

Witness: L1 214 (death, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 214 calls (`stage1/missions` 158, `stage1/death` 56) |
| Called from | `ClipToRight`, `ClipToBottom`, `ClipToLeft` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `OutCode` (`$A3AC`)

**The out code of the point (HL, DE): 8 x < 0, 4 x > `$A17C`, 2 y < 0, 1 y > `$A17E`**

Witness: L1 12480 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 228 calls, 30,096 t-states own (0.00 %) |
| Runs (the other recordings) | 12,252 calls (`stage1/death` 4,988, `stage1/play2` 3,096, `stage1/missions` 2,102 and 3 more) |
| Called from | `ClipLineCodes`, `ClipBothEnds` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$A17C`-`$A17E` (`ClipWindow`) |

### `BisectToInside` (`$A3E0`)

**Bisect the segment until the midpoint lies on the window edge**

Witness: L1 3 (death, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/missions` 2, `stage1/death` 1) |
| Called from | `ClipToCorner` |

### `NearClipLineEnd` (`$A422`)

**The other end of a line behind the eye too: no carry (skip the line); else NearClipLine**

Witness: L1 266 (death, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 266 calls (`stage1/missions` 220, `stage1/death` 46) |
| Called from | `OpLinesClipped` |
| Calls | `NearClipLine` (tail) |

### `NearClipLine` (`$A42B`)

**Cut the 3D segment V[B] - V[B'] at the near plane by bisection and project the cut: carry, HL / HL' = the screen point**

Reads both ends with `$A4D1` / `$A4F1` (vertex + the object position operands), halves the segment until depth - 96 is 0, then projects the point (Divide `$A687`, DivideByLog `$A6D2`, NegHL `$A771`) like OpProject. `$67B2-$67B5` hold the depths being halved.

Witness: L1 3110 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 146 calls, 514,607 t-states own (0.08 %) |
| Runs (the other recordings) | 2,964 calls (`stage1/death` 1,501, `stage1/missions` 737, `stage1/play` 422 and 2 more) |
| Called from | `OpLinesClipped`, `NearClipLineEnd` (tail), `ClipPolyNear` |
| Calls | `FetchVertexXY`, `FetchVertexDepth`, `Divide`, `DivideByLog`, `NegHL` |
| Reads | `$67B2`-`$67B5` (`WorldVars+15`); `$82FF`-`$8300` (`Im2Table+255`); `$9A72`-`$9A73` (`l_9A5E+20`); `$9AA3`-`$9AA4` (`l_9A9E+5`); `$9ABB`-`$9ABC` (`l_9A9E+29`) |
| Writes | `$67B2`-`$67B5` (`WorldVars+15`) |

### `FetchVertexXY` (`$A4D1`)

**x + `$9A8E` of V[B] to `$A503`, y + `$9AB3` to HL**

Witness: L1 6220 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 292 calls, 49,932 t-states own (0.01 %) |
| Runs (the other recordings) | 5,928 calls (`stage1/death` 3,002, `stage1/missions` 1,474, `stage1/play` 844 and 2 more) |
| Called from | `NearClipLine` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$FD00`-`$FD07` (`MissionHeader+8507`); `$FD30`-`$FD4B` (`MissionHeader+8555`); `$FE00`-`$FE07` (`MissionHeader+8763`); 1 more ranges |
| Writes | `$A503`-`$A504` (`FetchVertexDepth+18`) |

### `FetchVertexDepth` (`$A4F1`)

**z + `$9A6C` - 96 of the vertex: the signed distance to the near plane**

Witness: L1 6220 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 292 calls, 37,376 t-states own (0.01 %) |
| Runs (the other recordings) | 5,928 calls (`stage1/death` 3,002, `stage1/missions` 1,474, `stage1/play` 844 and 2 more) |
| Called from | `NearClipLine` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$9A6C`-`$9A73` (`l_9A5E+14`); `$FF00`-`$FF07` (`data_FEBB+69`); `$FF30`-`$FF4B` (`data_FEBB+117`) |

### `ClipPolyNear` (`$A509`)

**Cut a face at the near plane (Sutherland-Hodgman on depth = 96) into PolyVerts `$6700`**

Walks the face's point offsets from IX; at each in / out change calls NearClipLine `$A42B` and appends the cut with AppendPolyVertex `$A677`. Returns carry = the polygon is complete (fill it), Z = go on with the next point, NZ = nothing left.

Witness: L1 3987 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 73 calls, 50,982 t-states own (0.01 %) |
| Runs (the other recordings) | 3,914 calls (`stage1/death` 2,606, `stage1/play` 667, `stage1/missions` 364 and 2 more) |
| Called from | `FillFaceListClipped`, `OpFillPolysClipped` |
| Calls | `NearClipLine`, `AppendPolyVertex` |
| Reads | `$66CC`-`$66CD` (`PolyClipVars`); `$6798` (`GameVars`); `$67B1` (`WorldVars+14`); `$68A9` (`PanelGauges+1`); `$82FF`-`$8300` (`Im2Table+255`); `$87A6`-`$87A7` (`ModelMissile+49`); 11 more ranges |
| Writes | `$66CD` (`PolyClipVars+1`); `$6798` (`GameVars`); `$67B1` (`WorldVars+14`) |

### `AppendPolyVertex` (`$A677`)

**Append (BC, DE) to the polygon list at HL and count it in `$66D5`**

Witness: L1 4168 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 146 calls, 14,190 t-states own (0.00 %) |
| Runs (the other recordings) | 4,022 calls (`stage1/death` 2,109, `stage1/missions` 1,049, `stage1/play` 486 and 2 more) |
| Called from | `ClipPolyNear` |
| Reads | `$66D5` (`PolyOutCount`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$66D5` (`PolyOutCount`); `$6700`-`$6717` (`PolyVerts`) |

### `Divide` (`$A687`)

**HL = 256 HL / DE (signed HL, positive DE) by logarithms; DE = log2 of the divisor, kept for a second DivideByLog**

Normalises DE to an 8-bit mantissa and an exponent, looks up LogFraction / LogInteger `$5C00`, then falls into DivideByLog. 283 939 calls (11 recordings).

Witness: L1 283939 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 17,109 calls, 2,369,353 t-states own (0.36 %) |
| Runs (the other recordings) | 265,747 calls (`stage1/death` 133,852, `stage1/play2` 47,330, `stage1/missions` 42,707 and 6 more) |
| Called from | `OpProject`, `NearClipLine`, `ShowMortarRange`, `BearingLookup`, `PlotGroundDot` |
| Calls | `DivideByLog` |
| Reads | `$5C00`-`$5DFF` (`LogFraction`, `LogInteger`); `$82FF`-`$8300` (`Im2Table+255`) |

### `DivideByLog` (`$A6D2`)

**HL = 256 HL / 2^(DE / 256): log of |HL|, minus DE, antilog by ExpFraction `$5E00`, the sign back**

The shift of the 9-bit mantissa is a self-patched `JR` into an `ADD HL,HL` chain (`$A739`, `$A75A`). A result below 1 gives 0 (`$A765`), an overflow `$3EE4` and carry (`$A769`). The most called 3D routine: 475 056 entries, 45 permille.

Witness: L1 475056 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 30,613 calls, 8,889,499 t-states own (1.34 %) |
| Runs (the other recordings) | 442,277 calls (`stage1/death` 207,792, `stage1/play2` 81,736, `stage1/missions` 78,498 and 6 more) |
| Called from | `OpProject`, `NearClipLine`, `Divide`, `PlotGroundDot` |
| Calls | `ApplySign`, `ZeroQuotient` (tail) |
| Reads | `$5C00`-`$5EFF` (`LogFraction`, `LogInteger`, `ExpFraction`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$A73A` (`l_A739+1`); `$A75B` (`l_A75A+1`) |

### `ApplySign` (`$A745`)

**Negate HL when the sign saved in F' is set**

Witness: L1 425915 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28,656 calls, 1,028,625 t-states own (0.16 %) |
| Runs (the other recordings) | 397,259 calls (`stage1/death` 198,736, `stage1/play2` 75,218, `stage1/missions` 74,760 and 2 more) |
| Called from | `DivideByLog` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `ZeroQuotient` (`$A765`)

**HL = 0**

Witness: L1 24493 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,957 calls, 43,073 t-states own (0.01 %) |
| Runs (the other recordings) | 22,536 calls (`stage1/death` 9,056, `stage1/play2` 6,518, `stage1/missions` 3,738 and 2 more) |
| Called from | `DivideByLog` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `NegHL` (`$A771`)

**HL = -HL**

Witness: L1 308008 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 20,465 calls, 818,942 t-states own (0.12 %) |
| Runs (the other recordings) | 286,230 calls (`stage1/death` 124,659, `stage1/play2` 60,497, `stage1/missions` 50,225 and 6 more) |
| Called from | `OpProject`, `NearClipLine`, `BoxSquare`, `BoxHeights`, `BoxRect16`, `BoxRect`, `BoxTilted`, `GroundDots`, `PlotGroundDot`, `RotateToView`, `CollisionPass`, `HitSide` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `Random` (`$A779`)

**A = a pseudo-random byte: two additive words patched in place mixed with R (the mission vector `$67D0`)**

Witness: L1 584 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 52 calls, 9,412 t-states own (0.00 %) |
| Runs (the other recordings) | 532 calls (`stage1/play2` 168, `stage1/death` 159, `stage1/missions` 97 and 2 more) |
| Called from | `ApiVector06` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$A77C`-`$A788` (`Random+3`) |

### `AbsA` (`$A799`)

**A = |A| (the mission vector `$67D6`)**

Witness: L1 179580 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,328 calls, 125,956 t-states own (0.02 %) |
| Runs (the other recordings) | 173,252 calls (`stage1/death` 109,476, `stage1/play2` 22,376, `stage1/missions` 21,130 and 2 more) |
| Called from | `ApiVector08` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `NegDE` (`$A79E`)

**DE = -DE**

Witness: L1 2228 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 368 calls, 14,758 t-states own (0.00 %) |
| Runs (the other recordings) | 1,860 calls (`stage1/play2` 767, `stage1/death` 500, `stage1/missions` 378 and 2 more) |
| Called from | `BearingOctant` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `NegAbsHL` (`$A7A6`)

**HL = -|HL|**

Witness: known only from the code (no recording runs it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AbsHL` (`$A7AB`)

**HL = |HL|**

Witness: L1 2 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `PlaceHelicarrier` |
| Calls | `NegateHL` |

### `NegateHL` (`$A7AE`)

**HL = -HL (the mission vector `$67D3`)**

Witness: L1 18194 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 680 calls, 27,200 t-states own (0.00 %) |
| Runs (the other recordings) | 17,514 calls (`stage1/death` 9,455, `stage1/play` 3,394, `stage1/play2` 2,339 and 2 more) |
| Called from | `ApiVector07` (tail), `AbsHL` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `HighTimes32` (`$A7B6`)

**HL = H * 32 (the back-buffer row offset of row H)**

Witness: L1 71059 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,911 calls, 15,644 t-states own (0.00 %) |
| Runs (the other recordings) | 66,854 calls (`stage1/death` 33,069, `stage1/play2` 12,731, `stage1/missions` 10,050 and 6 more) |
| Called from | `PlotBackBuffer` |
| Calls | `LowTimes32` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `LowTimes32` (`$A7B7`)

**HL = L * 32**

Witness: L1 72315 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,986 calls, 287,265 t-states own (0.04 %) |
| Runs (the other recordings) | 68,020 calls (`stage1/death` 33,098, `stage1/play2` 13,048, `stage1/missions` 10,456 and 6 more) |
| Called from | `AttrBox`, `AttrBoxAt`, `AttrBoxRC`, `HighTimes32` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `MulSigned` (`$A7BF`)

**HL = A * E, signed bytes, by quarter squares: ((A+E)^2 - A^2 - E^2) / 2**

When A + E overflows it uses A^2 + E^2 - (A-E)^2 (`$A7DD`). Tables SquareLow / SquareHigh `$5F00`.

Witness: L1 107436 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 10,436 calls, 1,713,228 t-states own (0.26 %) |
| Runs (the other recordings) | 95,556 calls (`stage1/missions` 28,398, `stage1/play2` 23,764, `stage1/death` 16,546 and 6 more) |
| Called from | `OpTestFaces`, `TestFace` |
| Reads | `$5F00`-`$60FF` (`SquareLow`, `SquareHigh`); `$82FF`-`$8300` (`Im2Table+255`) |

### `MulFrac` (`$A7F2`)

**HL = A * E / 128 rounded, signed bytes: the product with a sine of Sine8**

Witness: L1 66079 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 3,614 calls, 653,683 t-states own (0.10 %) |
| Runs (the other recordings) | 62,281 calls (`stage1/death` 29,302, `stage1/play2` 14,652, `stage1/missions` 8,104 and 6 more) |
| Called from | `OpPolarPoints`, `BoxSquare`, `BoxRect`, `BoxTilted`, `RotatePair`, `ShowMortarRange`, `MoveObject` |
| Reads | `$5F00`-`$60FF` (`SquareLow`, `SquareHigh`); `$82FF`-`$8300` (`Im2Table+255`) |

### `MulWordByte` (`$A82C`)

**HL = HL * A / 128 for a signed word HL and a signed byte A (two quarter-square products)**

The mission vector `$67D9`: 220 482 calls in play, 37 permille, most of them from the mission code turning positions.

Witness: L1 220482 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 9,736 calls, 4,312,095 t-states own (0.65 %) |
| Runs (the other recordings) | 210,746 calls (`stage1/death` 120,834, `stage1/play2` 37,372, `stage1/play` 27,268 and 2 more) |
| Called from | `ApiVector09` (tail) |
| Reads | `$5F00`-`$60FF` (`SquareLow`, `SquareHigh`); `$82FF`-`$8300` (`Im2Table+255`) |

### `SinCos8` (`$A899`)

**A = Sine8[A], A' = Sine8[A + 64] (the mission vector `$67E8`)**

Witness: L1 58907 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,442 calls, 152,836 t-states own (0.02 %) |
| Runs (the other recordings) | 56,373 calls (`stage1/death` 29,045, `stage1/missions` 9,030, `stage1/play2` 8,907 and 6 more) |
| Called from | `ApiVector14` (tail) |
| Reads | `$6300`-`$63FF` (`Sine8`); `$82FF`-`$8300` (`Im2Table+255`) |

### `SinCos16` (`$A8A5`)

**DE = Sine16[A], BC = Sine16[A + 64]**

Witness: L1 4970 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 310 calls, 22,989 t-states own (0.00 %) |
| Runs (the other recordings) | 4,660 calls (`stage1/death` 2,236, `stage1/play2` 1,496, `stage1/play` 528 and 1 more) |
| Called from | `BoxRect16` |
| Reads | `$6100`-`$62FE` (`Sine16Low`, `Sine16High`) |

### `SinCosHalf` (`$A8B2`)

**E = A = sine, A = cosine of the angle word HL (H the angle, bit 7 of L the half step: Sine8Half `$6400`)**

Witness: L1 22941 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 870 calls, 73,773 t-states own (0.01 %) |
| Runs (the other recordings) | 22,071 calls (`stage1/death` 14,279, `stage1/play2` 3,322, `stage1/play` 2,329 and 2 more) |
| Called from | `BoxTilted`, `CameraSinCos`, `MoveObject` |
| Reads | `$6300`-`$63FF` (`Sine8`); `$82FF`-`$8300` (`Im2Table+255`) |

### `PlotBackBuffer` (`$AA27`)

**Set the pixel (x = L, y = H) in the back buffer (the bit masks at `$7C49`)**

Caller `$BB75` (points of the scenery). 37 012 calls.

Witness: L1 37012 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,516 calls, 237,466 t-states own (0.04 %) |
| Runs (the other recordings) | 35,496 calls (`stage1/death` 23,934, `stage1/play2` 5,450, `stage1/play` 3,192 and 2 more) |
| Called from | `PlotGroundDot` (tail) |
| Calls | `HighTimes32` |
| Reads | `$7C49`-`$7C50` (`FailReason+80`); `$82FF`-`$8300` (`Im2Table+255`); `$9111`-`$9130` (`BackBuffer+1568`); `$9152`-`$96CE` (`BackBuffer+1633`) |
| Writes | `$9111`-`$9130` (`BackBuffer+1568`); `$9152`-`$96CE` (`BackBuffer+1633`) |

## input

`src/game/input.asm`

### `ReadControls` (`$971A`)

**Read the chosen device: the reader of `$67B6` in the table `$9723`**

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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
| Calls | `InvertDirections` |
| Ports in | `$7FFE`, `$EFFE`, `$F7FE` |

### `InvertDirections` (`$9757`)

**CPL then DecodeDirections**

Witness: L1 1225 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,225 calls (`stage1/menu` 1,225) |
| Called from | `ReadSinclair` (tail), `ReadCursor` |
| Calls | `DecodeDirections` |

### `DecodeDirections` (`$9758`)

**Bits right, left, down, up, fire: the X and Y steps with acceleration (`$985E`, `$985F`), carry = fire**

Witness: L1 7771 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7,559 calls (`stage1/menu` 7,559) |
| Called from | `InvertDirections`, `ReadKeys` (tail) |
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

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,124 calls, 185,580 t-states own (0.03 %) |
| Runs (the other recordings) | 65,529 calls (`stage1/play2` 12,957, `stage1/missions` 12,811, `stage1/death` 12,655 and 6 more) |
| Called from | `ReadControls` (tail) |
| Calls | `ReadSinclair`, `ReadCursor`, `ReadKeys`, `TableEntry` |
| Reads | `$9723`-`$972C` (`DeviceReaders`) |

### `TableEntry` (`$987C`)

**HL = HL + 2A**

Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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

Witness: L1 6643 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 290 calls, 5,227,327 t-states own (0.79 %) |
| Runs (the other recordings) | 6,338 calls (`stage1/death` 2,636, `stage1/play2` 1,461, `stage1/missions` 1,212 and 6 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop` |
| Calls | `ClearBackBuffer` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$83BA` (`BlitRequest+1`) |

### `RequestViewBlit` (`$988D`)

**Ask the interrupt to blit the finished back buffer: `$83BA` = `$FF`**

Witness: L1 6658 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 291 calls, 8,730 t-states own (0.00 %) |
| Runs (the other recordings) | 6,350 calls (`stage1/death` 2,637, `stage1/play2` 1,461, `stage1/missions` 1,213 and 6 more) |
| Called from | `StartMission`, `PlayLoopTail`, `DragonflyViewLoop` |
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

Witness: L1 131277 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 7,859 calls, 995,308 t-states own (0.15 %) |
| Runs (the other recordings) | 122,646 calls (`stage1/death` 47,346, `stage1/play2` 28,155, `stage1/missions` 21,478 and 6 more) |
| Called from | `Bank3Render`, `ScriptNext` (tail), `OpTranslate` (tail), `TransformSegmentEnds`, `DrawSegmentStyle`, `DrawObject`, `DrawEntry` |
| Calls | `OpNative`, `OpVertexProgram`, `OpProject`, `OpLines`, `OpTestFaces`, `OpCall`, `OpReturn`, `OpOrderByFace`, `OpFillFaces`, `OpFillFacesClipped`, `OpFillPolys`, `OpFillBackFaces`, `OpLinesClipped`, `OpTranslate`, `OpFillPolysClipped`, `OpFillBackFacesClipped`, `OpPolarPoints`, `ScriptDrawCarried` |
| Reads | `$7E8F`-`$7FAF` (`MissionParams+13`); `$82FF`-`$8300` (`Im2Table+255`); `$8739`-`$87D5` (`ModelMine`, `ModelMissile`); `$98E1`-`$990E` (`OpcodeTable`); `$D5D0`-`$D673` (`HelicarrierData`); `$D934`-`$D9A4` (`BinocularIcons+96`); 3 more ranges |
| Writes | `$9928`-`$9929` (`sub_9927+1`) |

### `sub_9927` (`$9927`)

**sub_9927**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScriptNext` (`$992A`)

**The handlers' return: go on with the next opcode**

Witness: L1 104358 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 6,677 calls, 68,948 t-states own (0.01 %) |
| Runs (the other recordings) | 96,956 calls (`stage1/death` 32,614, `stage1/play2` 23,835, `stage1/missions` 18,315 and 6 more) |
| Called from | `OpVertexProgram` (tail), `OpProject` (tail), `OpLines` (tail), `OpTestFaces` (tail), `StoreFaceFlag` (tail), `OpCall`, `OpReturn` (tail), `OpOrderByFace` (tail), `OpFillFaces` (tail), `FillFaceList` (tail), `FillFaceListClipped` (tail), `OpFillPolys` (tail), `OpLinesClipped` (tail), `OpFillPolysClipped` (tail), `OpPolarPoints` (tail), `l_AA5B` (tail), `BoxHeights` (tail), `BoxTilted` (tail), `ScriptDrawCarried` (tail) |
| Calls | `RunScript` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `OpNative` (`$992D`)

**Opcode 0: jump to the native routine at the word operand**

IX on past the word, then `JP (HL)`: the routine reads its own operands through IX and returns to ScriptNext. The models call the box generators by the mission vectors `$67F4` (BoxSquare), `$67F7` (BoxRect), `$67FA` (BoxRect16), `$67FD` (BoxSquareTurret) and `$ABFF` (BoxTilted) with 3 operand bytes; other targets take none (`$F6B9` in mission 1 clears the tilt `$68E6`; `$D4A4`, `$D5C9`, `$E2C0`, `$EC2E`, `$EE06`, `$EE22`, `$FE8F` in bank 0).

Witness: L1 15260 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 944 calls, 59,070 t-states own (0.01 %) |
| Runs (the other recordings) | 14,270 calls (`stage1/death` 7,075, `stage1/play2` 3,366, `stage1/missions` 1,751 and 6 more) |
| Called from | `RunScript` |
| Calls | `ApiVector18`, `ApiVector19`, `ApiVector20`, `ApiVector21`, `BoxRect`, `BoxTilted`, `CopyHudGlyphs`, `CopyHelicarrierState`, `MissionHeader`, `l_FE8F` |
| Reads | `$7E90`-`$7F5D` (`MissionParams+14`); `$82FF`-`$8300` (`Im2Table+255`); `$873A`-`$8777` (`ModelMine+1`, `ModelMissile`); `$D5D1`-`$D5D5` (`HelicarrierData+1`); `$D935`-`$D93C` (`BinocularIcons+97`); `$E94E`-`$E94F` (`MissionHeader+3465`); 2 more ranges |

### `OpVertexProgram` (`$9938`)

**Opcode 1: build vertices from others with a byte program: load, store, midpoint, add, subtract, negate**

Under `DI` with `SP` used as a pointer into the vertex rows. The current point P = (DE, DE', BC') = (x, y, z). Bytes: `$00-$3F` n: P = V[n]; `$40-$7F`: V[n AND `$3F`] = P; `$80-$BF`: P = (P + V[n AND `$3F`]) / 2; `$C0` m: P = P + V[m]; `$E0` m: P = P - V[m]; `$F0`: P = -P; `$F8`: P.x = -P.x, P.z = -P.z (the half-turn about the vertical); any other byte (`$FF`) ends it, `SP` back, `EI`. With the box corners `V34-V41` from a box generator, midpoints and sums give every other vertex of the model in its turned axes.

Witness: L1 10819 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 855 calls, 7,298,543 t-states own (1.10 %) |
| Runs (the other recordings) | 9,854 calls (`stage1/play2` 2,724, `stage1/death` 2,520, `stage1/missions` 2,094 and 6 more) |
| Called from | `RunScript` |
| Calls | `ScriptNext` (tail) |
| Reads | `$7ED1`-`$7F74` (`MissionParams+79`); `$82FF`-`$8300` (`Im2Table+255`); `$8740`-`$8783` (`ModelMine+7`, `ModelMissile`); `$D5DA`-`$D612` (`HelicarrierData+10`); `$D93E`-`$D97E` (`BinocularIcons+106`); `$E954`-`$E95A` (`MissionHeader+3471`); 5 more ranges |
| Writes | `$99BE`-`$99C3` (`l_99AD+17`, `l_99C1`) |

### `OpProject` (`$9A43`)

**Opcode 2 (n, 2k): project n vertices from V[k] to screen points in ProjectedPoints `$FC00`**

For each vertex: depth = z + the operand at `$9A6C` (the object's z, `$0190` by default); if depth < 96 the point is marked behind the eye (`$FC00`+4i = `$8000`). Otherwise sx = 128 + 256 (x + `$9A8E`) / depth (shifted right by the count at `$9A93` first, the zoom), sy = 64 - 256 (y + `$9AB3`) / depth, through Divide `$A687` and DivideByLog `$A6D2` (one logarithm of the depth for both). Output: `$FC00`+4i = sx word, `$FC02`+4i = sy word.

Witness: L1 22966 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,168 calls, 6,885,988 t-states own (1.04 %) |
| Runs (the other recordings) | 21,720 calls (`stage1/death` 10,925, `stage1/play2` 3,909, `stage1/missions` 3,297 and 6 more) |
| Called from | `RunScript` |
| Calls | `ScriptNext` (tail), `Divide`, `DivideByLog`, `NegHL` |
| Reads | `$7E96`-`$7F86` (`MissionParams+20`); `$82FF`-`$8300` (`Im2Table+255`); `$8745`-`$8786` (`ModelMine+12`, `ModelMissile`); `$D614`-`$D615` (`HelicarrierData+68`); `$D980`-`$D981` (`BinocularIcons+172`); `$E95C`-`$E95D` (`MissionHeader+3479`); 4 more ranges |
| Writes | `$9AD6`-`$9AD7` (`l_9AD5+1`); `$FC00`-`$FCAF` (`MissionHeader+8251`) |

### `OpLines` (`$9AD8`)

**Opcode 3: a polyline: `$80`+v moves to point v, v draws a line to it, `$C0` ends**

A line is drawn only when both ends are in front of the eye; ClipLine2D `$A184` clips it to the window and `$72B1` draws it with bank 3 `$C9A7`.

Witness: L1 1542 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 64,657 t-states own (0.01 %) |
| Runs (the other recordings) | 1,428 calls (`stage1/play2` 563, `stage1/death` 359, `stage1/missions` 242 and 3 more) |
| Called from | `RunScript` |
| Calls | `Bank3Lookup`, `ScriptNext` (tail), `ClipLine2D` |
| Reads | `$7FA6`-`$7FAE` (`MissionParams+292`); `$82FF`-`$8300` (`Im2Table+255`); `$D983`-`$D9A3` (`BinocularIcons+175`); `$EBA7`-`$EBA9` (`MissionHeader+4066`); `$EC1F`-`$EC2B` (`MissionHeader+4186`); `$ED12`-`$ED14` (`MissionHeader+4429`); 5 more ranges |
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

Witness: L1 9372 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 816 calls, 89,342 t-states own (0.01 %) |
| Runs (the other recordings) | 8,478 calls (`stage1/play2` 2,590, `stage1/death` 2,050, `stage1/missions` 1,832 and 6 more) |
| Called from | `RunScript` |
| Calls | `ScriptNext` (tail), `TestFace`, `ScaleToBytes`, `MulSigned` |
| Reads | `$7E99`-`$7F77` (`MissionParams+23`); `$82FF`-`$8300` (`Im2Table+255`); `$8748`-`$8789` (`ModelMine+15`, `ModelMissile`); `$9BDA` (`TestFace+23`); `$D617`-`$D618` (`HelicarrierData+71`); `$E95F`-`$E960` (`MissionHeader+3482`); 5 more ranges |
| Writes | `$6728`-`$6749` (`FaceFlags`); `$9BDA` (`TestFace+23`); `$9C6B`-`$9C7B` (`StoreFaceFlag+1`, `l_9C79`) |

### `TestFace` (`$9BC3`)

**One face: the sign of the cross product (b - a) x (c - a) of three screen points into FaceFlags**

Counts the points behind the eye in `$9BDA`: 3 gives flag 0 (`$9CAA`), 1-2 give `$FF` (`$9CA3`, drawn and clipped later); else the two edge vectors are scaled to bytes (ScaleToBytes `$9C84`) and multiplied with MulSigned `$A7BF`: flag = `$FF` when ex1 * ey2 < ey1 * ex2.

Witness: L1 45290 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5,328 calls, 4,569,194 t-states own (0.69 %) |
| Runs (the other recordings) | 39,962 calls (`stage1/missions` 14,203, `stage1/play2` 12,266, `stage1/death` 8,757 and 1 more) |
| Called from | `OpTestFaces`, `StoreFaceFlag` (tail) |
| Calls | `StoreFaceFlag`, `ScaleToBytes`, `FacePartlyBehind` (tail), `FaceAllBehind` (tail), `MulSigned` |
| Reads | `$7E9B`-`$7F83` (`MissionParams+25`); `$82FF`-`$8300` (`Im2Table+255`); `$874A`-`$878F` (`ModelMine+17`, `ModelMissile`); `$9BDA` (`TestFace+23`); `$D619`-`$D630` (`HelicarrierData+73`); `$E961`-`$E96C` (`MissionHeader+3484`); 5 more ranges |
| Writes | `$9BDA` (`TestFace+23`) |

### `StoreFaceFlag` (`$9C6A`)

**Store the face flag B at `$6728` + slot, next slot, loop over the triples**

Witness: L1 45290 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5,328 calls, 330,495 t-states own (0.05 %) |
| Runs (the other recordings) | 39,962 calls (`stage1/missions` 14,203, `stage1/play2` 12,266, `stage1/death` 8,757 and 1 more) |
| Called from | `TestFace`, `FacePartlyBehind` (tail), `FaceAllBehind` (tail) |
| Calls | `ScriptNext` (tail), `TestFace` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$6728`-`$674F` (`FaceFlags`); `$9C6B` (`StoreFaceFlag+1`) |

### `ScaleToBytes` (`$9C84`)

**Halve the two words HL, DE together until both fit in a signed byte (C = the sign bias)**

The loop `$9C7C` shifts both right. Unreferenced code at `$9C9A` (another flag store) follows.

Witness: L1 107436 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 10,436 calls, 539,832 t-states own (0.08 %) |
| Runs (the other recordings) | 95,556 calls (`stage1/missions` 28,398, `stage1/play2` 23,764, `stage1/death` 16,546 and 6 more) |
| Called from | `OpTestFaces`, `TestFace` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `FacePartlyBehind` (`$9CA3`)

**A face with one or two points behind the eye: flag `$FF`**

Witness: L1 11 (c1, death).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 5 calls, 185 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/death` 6) |
| Called from | `TestFace` (tail) |
| Calls | `StoreFaceFlag` (tail) |

### `FaceAllBehind` (`$9CAA`)

**A face with all three points behind the eye: flag 0**

Witness: L1 1123 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 105 calls, 3,885 t-states own (0.00 %) |
| Runs (the other recordings) | 1,018 calls (`stage1/death` 478, `stage1/play2` 384, `stage1/play` 152 and 1 more) |
| Called from | `TestFace` (tail) |
| Calls | `StoreFaceFlag` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

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

Witness: L1 878 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 100 calls, 11,536 t-states own (0.00 %) |
| Runs (the other recordings) | 746 calls (`stage1/menu` 262, `stage1/missions` 236, `stage1/play2` 98 and 6 more) |
| Called from | `RunScript` |
| Calls | `ScriptNext` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `OpReturn` (`$9D1E`)

**Opcode 9: return from a script subroutine: IX popped from the stack**

Used to end the parts of OpCall `$9D0D` and OpOrderByFace `$9D5A`.

Witness: L1 12941 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 994 calls, 53,695 t-states own (0.01 %) |
| Runs (the other recordings) | 11,733 calls (`stage1/missions` 3,361, `stage1/play2` 3,037, `stage1/menu` 1,833 and 6 more) |
| Called from | `RunScript` |
| Calls | `ScriptNext` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
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

Witness: L1 6021 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 447 calls, 124,404 t-states own (0.02 %) |
| Runs (the other recordings) | 5,482 calls (`stage1/missions` 1,561, `stage1/play2` 1,470, `stage1/play` 838 and 6 more) |
| Called from | `RunScript` |
| Calls | `ScriptNext` (tail) |
| Reads | `$6728`-`$6748` (`FaceFlags`); `$82FF`-`$8300` (`Im2Table+255`); `$8791`-`$87AE` (`ModelMissile+28`); `$EBEC`-`$EC90` (`MissionHeader+4135`); `$F3C8`-`$F3CC` (`MissionHeader+6147`); `$F5B8`-`$F5BC` (`MissionHeader+6643`) |
| Writes | `$9D85`-`$9D86` (`l_9D84+1`) |

### `OpFillFaces` (`$9D8F`)

**Opcode 12 (n, n x face): fill the visible faces; face = (slot, length, k, colour, k point offsets)**

Patches `$9DB2` to `JP Z` (skip hidden faces) and `$9DAD` to fall through, then shares FillFaceList `$9D99`. A face with a point behind the eye is skipped (`$9E0B`).

Witness: L1 11209 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 806 calls, 2,334,904 t-states own (0.35 %) |
| Runs (the other recordings) | 10,296 calls (`stage1/play2` 3,011, `stage1/missions` 2,713, `stage1/death` 1,657 and 6 more) |
| Called from | `RunScript` |
| Calls | `Bank3SetObject`, `ScriptNext` (tail), `FillFaceList` |
| Reads | `$6728`-`$6749` (`FaceFlags`); `$68AA` (`PanelGauges+2`); `$7EA8`-`$7FA4` (`MissionParams+38`); `$82FF`-`$8300` (`Im2Table+255`); `$8757`-`$87CA` (`ModelMine+30`, `ModelMissile`); `$EC79`-`$ECAC` (`MissionHeader+4276`); 6 more ranges |
| Writes | `$6700`-`$6717` (`PolyVerts`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$9DAD`-`$9DB2` (`l_9DA6+7`); `$9E03`-`$9E04` (`l_9E02+1`) |

### `FillFaceList` (`$9D99`)

**Copy each chosen face's screen points to PolyVerts `$6700` and fill it with bank 3 `$C4C4` (via `$7290`)**

The colour to `$7579`, the count to `$68A9`, the face count in `$68AA`. A face whose flag fails the test is skipped by its length byte.

Witness: L1 5753 (missions, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5,753 calls (`stage1/play2` 3,023, `stage1/missions` 2,730) |
| Called from | `OpFillFaces`, `OpFillBackFaces` (tail) |
| Calls | `Bank3SetObject`, `ScriptNext` (tail) |
| Reads | `$6728`-`$674E` (`FaceFlags`); `$6760`-`$6767` (`FaceFlags+56`); `$68AA` (`PanelGauges+2`); `$7EA8`-`$7FA4` (`MissionParams+38`); `$82FF`-`$8300` (`Im2Table+255`); `$8757`-`$87CA` (`ModelMine+30`, `ModelMissile`); 6 more ranges |
| Writes | `$6700`-`$6717` (`PolyVerts`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$9E03`-`$9E04` (`l_9E02+1`) |

### `OpFillFacesClipped` (`$9E1E`)

**Opcode 13: fill the visible faces, clipping those that cross the near plane**

Witness: L1 2455 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 257 calls, 1,799 t-states own (0.00 %) |
| Runs (the other recordings) | 2,198 calls (`stage1/play2` 863, `stage1/death` 828, `stage1/play` 297 and 1 more) |
| Called from | `RunScript` |
| Calls | `FillFaceListClipped` |

### `FillFaceListClipped` (`$9E20`)

**As FillFaceList, but a point behind the eye calls ClipPolyNear `$A509` to cut the face at the near plane**

A = the opcode patched at `$9E40` (`JP Z` for opcode 13, `JP NZ` for 20). The first point offset is kept in `$66CC` for the closing edge.

Witness: L1 5778 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 296 calls, 1,231,798 t-states own (0.19 %) |
| Runs (the other recordings) | 5,482 calls (`stage1/play2` 2,334, `stage1/death` 1,645, `stage1/play` 1,248 and 1 more) |
| Called from | `OpFillFacesClipped`, `OpFillBackFacesClipped` (tail) |
| Calls | `Bank3SetObject`, `ScriptNext` (tail), `ClipPolyNear` |
| Reads | `$66D5` (`PolyOutCount`); `$6728`-`$672F` (`FaceFlags`); `$6748`-`$674F` (`FaceFlags+32`); `$68AA` (`PanelGauges+2`); `$82FF`-`$8300` (`Im2Table+255`); `$87A0`-`$87D3` (`ModelMissile+43`); 11 more ranges |
| Writes | `$66CC`-`$66D5` (`PolyClipVars`, `PolyWorkSpare`, `PolyOutCount`); `$6700`-`$671F` (`PolyVerts`); `$6798` (`GameVars`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$9E3B`-`$9E40` (`l_9E34+7`, `l_9E3C`); 1 more ranges |

### `OpFillPolys` (`$9ECD`)

**Opcode 14 (n, n x (k, colour, k point offsets)): fill polygons with no face test**

Witness: L1 5571 (c1, death, m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 114 calls, 95,470 t-states own (0.01 %) |
| Runs (the other recordings) | 5,457 calls (`stage1/death` 4,137, `stage1/play2` 493, `stage1/missions` 408 and 3 more) |
| Called from | `RunScript` |
| Calls | `Bank3SetObject`, `ScriptNext` (tail) |
| Reads | `$68AA` (`PanelGauges+2`); `$82FF`-`$8300` (`Im2Table+255`); `$EBA0`-`$EBA5` (`MissionHeader+4059`); `$EE6C`-`$EE71` (`MissionHeader+4775`); `$F0F8`-`$F0FD` (`MissionHeader+5427`); `$F9C4`-`$F9C9` (`MissionHeader+7679`); 3 more ranges |
| Writes | `$6700`-`$670F` (`PolyVerts`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$9F26`-`$9F27` (`l_9F25+1`) |

### `OpFillBackFaces` (`$9F37`)

**Opcode 15: fill the faces whose flag is 0 (`JP NZ` at `$9DB2`): the insides seen through an opening**

Witness: L1 29 (missions, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 29 calls (`stage1/missions` 17, `stage1/play2` 12) |
| Called from | `RunScript` |
| Calls | `FillFaceList` (tail) |
| Writes | `$9DAD`-`$9DB2` (`l_9DA6+7`) |

### `OpLinesClipped` (`$9F43`)

**Opcode 16: a polyline like opcode 3, a segment with an end behind the eye cut at the near plane (`$A422`, `$A42B`)**

Witness: L1 785 (death, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 785 calls (`stage1/death` 545, `stage1/missions` 240) |
| Called from | `RunScript` |
| Calls | `Bank3Lookup`, `ScriptNext` (tail), `ClipLine2D`, `NearClipLineEnd`, `NearClipLine` |
| Reads | `$6798` (`GameVars`); `$82FF`-`$8300` (`Im2Table+255`); `$F139`-`$F141` (`MissionHeader+5492`); `$FC00`-`$FC0F` (`MissionHeader+8251`); `$FC68`-`$FC6F` (`MissionHeader+8355`); `$FC80`-`$FC97` (`MissionHeader+8379`); 1 more ranges |
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
| Called from | `RunScript` |
| Calls | `RunScript` (tail) |
| Reads | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$EB98` (`MissionHeader+4051`); `$ED16` (`MissionHeader+4433`); `$FD00`-`$FD01` (`MissionHeader+8507`); 5 more ranges |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`) |

### `OpFillPolysClipped` (`$A07E`)

**Opcode 19 (n, n x (k, colour, k point offsets)): fill polygons, clipping at the near plane**

Witness: L1 7171 (c1, death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 294,901 t-states own (0.04 %) |
| Runs (the other recordings) | 6,933 calls (`stage1/death` 4,423, `stage1/play` 891, `stage1/play2` 826 and 2 more) |
| Called from | `RunScript` |
| Calls | `Bank3SetObject`, `ScriptNext` (tail), `ClipPolyNear` |
| Reads | `$66D5` (`PolyOutCount`); `$68AA` (`PanelGauges+2`); `$82FF`-`$8300` (`Im2Table+255`); `$F12F`-`$F137` (`MissionHeader+5482`); `$FC00`-`$FC0F` (`MissionHeader+8251`); `$FC70`-`$FC87` (`MissionHeader+8363`); 1 more ranges |
| Writes | `$66CC`-`$66D5` (`PolyClipVars`, `PolyWorkSpare`, `PolyOutCount`); `$6700`-`$6717` (`PolyVerts`); `$6798` (`GameVars`); `$68A9`-`$68AA` (`PanelGauges+1`); `$7579` (`AwolState+1`); `$A0F7`-`$A0F8` (`l_A0F6+1`) |

### `l_A109` (`$A109`)

**l_A109**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OpFillBackFacesClipped` (`$A114`)

**Opcode 20: fill the faces whose flag is 0, clipping at the near plane (FillFaceListClipped with `JP NZ`)**

Witness: L1 3323 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 39 calls, 682 t-states own (0.00 %) |
| Runs (the other recordings) | 3,284 calls (`stage1/play2` 1,471, `stage1/play` 951, `stage1/death` 817 and 1 more) |
| Called from | `RunScript` |
| Calls | `FillFaceListClipped` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `OpPolarPoints` (`$A119`)

**Opcode 21 (n, next, frame table): n vertices from (angle, radius, height) triples, turned by the heading**

The frame (`$A12C`, the object record's +4, set by DrawObject `$B827`) picks a word of the table at IX+3: the address of n triples. Each gives x = r sin(heading + angle) / 128, z = r cos(...) / 128, y = height, stored from V32 downwards. Then IX = next. Mission 1 uses it once (`$EFC5`, a barrel run out in five frames).

Witness: L1 4 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 4) |
| Called from | `RunScript` |
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

Witness: L1 483 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 175 calls, 90,613 t-states own (0.01 %) |
| Runs (the other recordings) | 308 calls (`stage1/play2` 164, `stage1/death` 83, `stage1/missions` 60 and 1 more) |
| Called from | `ApiVector18` (tail) |
| Calls | `NegHL`, `MulFrac`, `BoxHeights` |
| Reads | `$6300`-`$6393` (`Sine8`); `$63AE`-`$63FE` (`Sine8+174`); `$68E7` (`MissionScore+5`); `$82FF`-`$8300` (`Im2Table+255`); `$EC9F`-`$ECA0` (`MissionHeader+4314`); `$EEDB`-`$EEDC` (`MissionHeader+4886`); 2 more ranges |
| Writes | `$AAF3`-`$AAF4` (`l_AAF2+1`); `$FD44`-`$FD53` (`MissionHeader+8575`); `$FF44`-`$FF53` (`data_FEBB+137`) |

### `BoxHeights` (`$AAC2`)

**Last operand h: y = -h for V34-V37, +h for V38-V41; V33 = (0, 0, 0); return**

Witness: L1 9618 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 830 calls, 226,456 t-states own (0.03 %) |
| Runs (the other recordings) | 8,742 calls (`stage1/play2` 2,704, `stage1/death` 2,571, `stage1/missions` 1,665 and 6 more) |
| Called from | `BoxSquare`, `BoxRect16` (tail), `BoxRect` (tail) |
| Calls | `ScriptNext` (tail), `NegHL`, `l_AA5B` (tail) |
| Reads | `$7E94`-`$7F60` (`MissionParams+18`); `$82FF`-`$8300` (`Im2Table+255`); `$873E`-`$877A` (`ModelMine+5`, `ModelMissile`); `$D5D8` (`HelicarrierData+8`); `$D939` (`BinocularIcons+101`); `$E952` (`MissionHeader+3469`); 2 more ranges |
| Writes | `$FD42`-`$FD43` (`MissionHeader+8573`); `$FE42`-`$FE53` (`MissionHeader+8829`); `$FF42`-`$FF43` (`data_FEBB+135`) |

### `BoxRect16` (`$AAF5`)

**Native (half angle, radius, height): a rectangle box with 16-bit corners (Sine16), turned by the heading**

The corners lie at the radius r on the angles heading +/- b and their opposites, so b sets the aspect. Through MulWordByte `$67D9`. The mission vector `$67FA`.

Witness: L1 2485 (c1, death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 155 calls, 114,057 t-states own (0.02 %) |
| Runs (the other recordings) | 2,330 calls (`stage1/death` 1,118, `stage1/play2` 748, `stage1/play` 264 and 1 more) |
| Called from | `ApiVector20` (tail) |
| Calls | `ApiVector09`, `NegHL`, `SinCos16`, `BoxHeights` (tail) |
| Reads | `$68E7` (`MissionScore+5`); `$82FF`-`$8300` (`Im2Table+255`); `$E950`-`$E951` (`MissionHeader+3467`); `$EBA9`-`$EBAA` (`MissionHeader+4068`); `$EBF3`-`$EBF4` (`MissionHeader+4142`); `$ECBB`-`$ECBC` (`MissionHeader+4342`); 8 more ranges |
| Writes | `$AAF3`-`$AAF4` (`l_AAF2+1`); `$FD42`-`$FD53` (`MissionHeader+8573`); `$FE42`-`$FE43` (`MissionHeader+8829`); `$FF42`-`$FF53` (`data_FEBB+135`) |

### `BoxRect` (`$AB7B`)

**Native (half angle, radius, height): the same rectangle box with 8-bit corners (Sine8, MulFrac)**

The mission vector `$67F7`; the most used box (bank 3 models, mission 1: 22 of 31 models).

Witness: L1 6221 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 450 calls, 366,609 t-states own (0.06 %) |
| Runs (the other recordings) | 5,740 calls (`stage1/play2` 1,744, `stage1/death` 1,363, `stage1/missions` 1,288 and 6 more) |
| Called from | `ApiVector19` (tail), `OpNative` |
| Calls | `ApiVector14`, `NegHL`, `MulFrac`, `BoxHeights` (tail) |
| Reads | `$68E7` (`MissionScore+5`); `$7E92`-`$7F5F` (`MissionParams+16`); `$82FF`-`$8300` (`Im2Table+255`); `$873C`-`$8779` (`ModelMine+3`, `ModelMissile`); `$D5D6`-`$D5D7` (`HelicarrierData+6`); `$D937`-`$D938` (`BinocularIcons+99`); 5 more ranges |
| Writes | `$AAF3`-`$AAF4` (`l_AAF2+1`); `$FD42`-`$FD53` (`MissionHeader+8573`); `$FE42`-`$FE43` (`MissionHeader+8829`); `$FF42`-`$FF53` (`data_FEBB+135`) |

### `BoxTilted` (`$ABFF`)

**Native (half angle, radius, height): a rectangle box turned by the heading, the pitch `$ABFE` and the roll `$68E6`**

Rotates each corner pair with RotatePair `$AD06` (sine and cosine of the roll in `$AD04`); sets V0 = 0. Called from OpNative in death and play2 (a tilted vehicle).

Witness: L1 0 (death, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/death`, `stage1/play2`) |
| Called from | `OpNative` |
| Calls | `ApiVector14`, `ScriptNext` (tail), `NegHL`, `MulFrac`, `SinCosHalf`, `RotatePair` |
| Reads | `$68E6`-`$68E7` (`MissionScore+4`); `$82FF`-`$8300` (`Im2Table+255`); `$ABFE` (`BoxTiltPitch+1`); `$FD4C`-`$FD51` (`MissionHeader+8583`); `$FEC7`-`$FEC9` (`data_FEBB+12`); `$FF4C`-`$FF51` (`data_FEBB+145`) |
| Writes | `$AD02`-`$AD05` (`BoxTilted+259`, `RollSinCos`) |

### `RotatePair` (`$AD06`)

**Turn the pair (B, C) by the angle in `$AD04`: HL, DE = the two rotated words**

Witness: L1 1563 (death, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,563 calls (`stage1/death` 1,101, `stage1/play2` 462) |
| Called from | `BoxTilted` |
| Calls | `MulFrac` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$AD04`-`$AD05` (`RollSinCos`) |
| Writes | `$AD2F`-`$AD41` (`RotatePair+41`) |

## player

`src/game/player.asm`

### `PlayerStep` (`$A8C7`)

**The player's step handler: terrain, brake, fuel, boundary, move, the turret**

Record 0's step handler (+`$18` = `$A8C7`, run by RunObjectHandlers `$C026` with IX = `$75F0`). Calls TerrainCollision through `$67F1`; on a hit the terrain type `$CE69` decides: 2 or `$80` (a wall) negates the speed and sets the handler to BounceDecay `$CC09`; 0 or 6 (0 is the road, segment style 0) stores 1.25 x the speed (signed) in `$7E8E`; IX+7 is restored at once, so the tank's speed does not change and only bank 6 DrawSpeedBar `$D612` reads `$7E8E` (the speed bar) (`$A8F0`-`$A934`, docs/10-gameplay-logic.md 10.2). The S key branch `$A8F2` -> `$A9C0` makes BrakeKey `$A9C9` the step handler and ends the pass. When the speed is not 0: the fuel, `$7C57` -= (|speed| >> 4) OR 1 (on an underflow `$A94E` sets the failure reason `$7BF9` = `$CCED` ("RAN OUT OF FUEL") and calls `$7047`), then BoundaryCheck `$D4B8` (`$A95B`), then MoveObject. The Infinite Fuel POKE writes 42 at `$A958` (`LD ($7C57),HL` becomes `LD HL,($7C57)`). Then the turret and speed against the control state `$985F`.

Witness: L1 3503 (death, m2erbe, missions, play, play2).

[Animation: `PlayerStep` at work](img/routines/PlayerStep.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 102 calls, 41,430 t-states own (0.01 %) |
| Runs (the other recordings) | 3,503 calls (`stage1/death` 2,510, `stage1/play2` 390, `stage1/missions` 307 and 2 more) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00`, `ApiVector08`, `ApiVector17`, `PlayerSteering`, `FireCannon`, `FireMortar`, `FireBansheeRr`, `LaunchDragonfly`, `FirePhantasm`, `BoundaryCheck` |
| Reads | `$6A99`-`$6A9A` (`NextView+8`); `$6D43` (`PointerZones+1`); `$75F7` (`PlayerSpeed`); `$7612` (`PlayerHeading`); `$7C57`-`$7C58` (`Fuel`); `$82FF`-`$8300` (`Im2Table+255`); 5 more ranges |
| Writes | `$66CE` (`PolyClipVars+2`); `$6D43` (`PointerZones+1`); `$75F7` (`PlayerSpeed`); `$7608`-`$7612` (`PlayerHandler`, `PlayerHeading`); `$7C57`-`$7C58` (`Fuel`); `$7E8E` (`MissionParams+12`); 2 more ranges |

### `PlayerSteering` (`$A986`)

**Steering and the fire key: heading += turn / 2, the fire cooldown**

Adds half the turn input `$985E` to the heading `$7612`; counts down the fire cooldown `$A9FD`; when it is zero and the fire key bit of `$6D43` is set, calls the current weapon's fire routine through the operand at `$A9B9` (set from the store-type table `$7B89` + 8 * type, word 3). Output: a projectile record, the cooldown restarted.

Witness: L1 3521 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 115 calls, 14,742 t-states own (0.00 %) |
| Runs (the other recordings) | 409 calls (`stage1/play2` 409) |
| Called from | `PlayerStep`, `BounceDecay` (tail) |
| Calls | `NoAction`, `FireCannon`, `FirePhoenixRr`, `FirePhoenixIr`, `FireBansheeIr`, `FireClusterBomb`, `DropMine`, `FireDecoy`, `FireCluster13` |
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

Witness: L1 69 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 69 calls (`stage1/death` 60, `stage1/play2` 6, `stage1/play` 3) |
| Called from | `FireCannon` (tail), `LaunchProjectile`, `FireDecoy` (tail) |
| Writes | `$A9FD` (`FireCooldown`) |

### `ConsumeAmmo` (`$B550`)

**Take one round from the current slot; find a slot for the projectile**

Reads the slot's ammunition pointer (`$B551`, from SelectAmmoPointer `$D3C6`), DEC A and stores it (the Infinite Ammo POKE writes 0 at `$B554`, the DEC A becomes NOP). Returns M when empty. Then FindFreeObject `$BCD6`, the fire sound `$D898`, and prints the count at `$C527`.

Witness: L1 70 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 70 calls (`stage1/death` 60, `stage1/play2` 6, `stage1/play` 4) |
| Called from | `FireCannon`, `LaunchProjectile`, `LaunchDragonfly`, `FireDecoy` |
| Calls | `FindProjectileSlot`, `SoundFire` |
| Reads | `$836D`-`$837F` (`WeaponSlots+5`) |
| Writes | `$836D`-`$837F` (`WeaponSlots+5`); `$C527` (`WeaponVars`) |

### `FireCannon` (`$B568`)

**Fire the turret cannon (store type 4): projectile `$81`**

Ammunition, then ObjectSetType with `$81`, the position and heading of the player, +31 lifetime.

Witness: L1 61 (death, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 61 calls (`stage1/death` 60, `stage1/play2` 1) |
| Called from | `PlayerStep`, `PlayerSteering` |
| Calls | `ApiVector03`, `ApiVector04`, `SetFireCooldown` (tail), `ConsumeAmmo`, `PrintAmmo`, `SelectAmmoPointer` |
| Reads | `$67A5`-`$67AC` (`WorldVars+2`); `$C53C` (`CurrentSlot`) |
| Writes | `$764D`-`$76D5` (`PlayerY+55`); `$7701`-`$7711` (`PlayerY+235`); `$7779`-`$7789` (`PlayerY+355`); `$77B5`-`$77C5` (`PlayerY+415`); `$78A5`-`$78B5` (`PlayerY+655`); `$791D`-`$792D` (`PlayerY+775`); 3 more ranges |

### `CannonShellStep` (`$B592`)

**Step of a cannon shell: move, lifetime 100**

MoveObject `$BFD1`, counts +`$31` down from 100, removes the shell at 0 (RemoveObject `$B8B1`).

Witness: L1 5682 (death, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5,682 calls (`stage1/death` 5,582, `stage1/play2` 100) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` (tail), `RemoveObject` (tail) |
| Reads | `$765D`-`$7711` (`PlayerY+71`); `$7789` (`PlayerY+371`); `$77C5` (`PlayerY+431`); `$78B5` (`PlayerY+671`); `$792D` (`PlayerY+791`); `$79E1` (`PlayerY+971`); 3 more ranges |
| Writes | `$765D`-`$7711` (`PlayerY+71`); `$7789` (`PlayerY+371`); `$77C5` (`PlayerY+431`); `$78B5` (`PlayerY+671`); `$792D` (`PlayerY+791`); `$79E1` (`PlayerY+971`); 2 more ranges |

### `FireMortar` (`$B59F`)

**Fire the K-40 mortar (store type 3): projectile `$80`**

SelectAmmoPointer, A = `$80`, then LaunchProjectile `$B5A7`.

Witness: L1 2 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `PlayerStep` |
| Calls | `LaunchProjectile`, `SelectAmmoPointer` |
| Reads | `$C53C` (`CurrentSlot`) |

### `LaunchProjectile` (`$B5A7`)

**Spawn projectile type A at the player with the aim's elevation**

Input A = the template type (`$80`-`$8B`). ConsumeAmmo `$B550`, ObjectSetType `$BD41`, copies the player's heading and X / Y, the elevation from `$B5C5` / `$B5C8` (SetElevation `$CF32`). Returns M when out of rounds.

Witness: L1 7 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7 calls (`stage1/play2` 4, `stage1/play` 3) |
| Called from | `FireMortar`, `FireClusterBomb` (tail), `DropMine`, `FireCluster13` (tail), `LaunchPhantasm` |
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

Witness: L1 8 (death, play2).

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
| Calls | `ShowMortarRange` |
| Reads | `$B8BA` (`MortarElevationUp+1`) |
| Writes | `$B8BA` (`MortarElevationUp+1`) |

### `ShowMortarRange` (`$B8CC`)

**Print the mortar range for the elevation**

Prints the elevation's range in the HUD (play: 5 runs).

Witness: L1 5 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/play` 5) |
| Called from | `MortarElevationDown`, `SelectWeapon` |
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
| Called from | `FirePhoenixRr` (tail), `FireBansheeRr` (tail), `MissileLock` |
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
| Calls | `WeaponSelectText` |
| Writes | `$BA13` (`SetCamera+29`); `$C4DC` (`l_C4DB+1`) |

### `WeaponSelectText` (`$C126`)

**Print the selected weapon's name**

`LD HL,$FDC0` / `JP $6FB3`.

Witness: L1 8 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/play` 5, `stage1/play2` 3) |
| Called from | `SelectPhoenix`, `SelectPlain` (tail), `RefreshWeaponPanel` (tail) |
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
| Calls | `FindMissileTarget` (tail), `SelectAmmoPointer` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$C198` (`TargetInCone+1`); `$C53C` (`CurrentSlot`) |
| Writes | `$BF40`-`$BF41` (`l_BF3C+4`); `$C198` (`TargetInCone+1`); `$C41D` (`l_C408+21`) |

### `FireBansheeRr` (`$C14D`)

**Fire the Banshee RRSS: projectile `$82`**

A = `$82`, LaunchProjectile (play: 2 runs).

Witness: L1 2 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/play` 2) |
| Called from | `PlayerStep` |
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
| Calls | `ApiVector01`, `ApiVector08`, `TargetBearingCheck` |
| Reads | `$6804`-`$6829` (`PlayWork+4`); `$7612` (`PlayerHeading`); `$77D2`-`$77D6` (`PlayerY+444`); `$780E`-`$7812` (`PlayerY+504`); `$784A`-`$784E` (`PlayerY+564`); `$78C2`-`$78C6` (`PlayerY+684`); 5 more ranges |
| Writes | `$C16F`-`$C170` (`l_C16E+1`) |

### `TargetInConeBody` (`$C19A`)

**The body of TargetInCone (no recording runs it)**

Reads a node of the depth tree, IY = its record, checks the bearing within +-6 of `$7612` (BearingTo through `$67C1`) and the height.

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TargetBearingCheck` (`$C1ED`)

**Check a candidate's bearing and height**

Called for each candidate: |bearing - heading| < 6, height against `$C276`.

Witness: L1 28 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 28 calls (`stage1/play2` 21, `stage1/play` 7) |
| Called from | `TargetInCone`, `MissileSeek` |
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
| Calls | `MissileLock`, `SelectAmmoPointer` |
| Reads | `$C53C` (`CurrentSlot`) |

### `MissileLock` (`$C227`)

**Lock a missile on the target found**

Stores the limit `$C276` and the type `$C41D`, hooks MissileSeek into the tree walk (`$BF40` = `$C267`), searches (FindMissileTarget `$BF24`).

Witness: L1 4 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 4) |
| Called from | `FirePhoenixIr` (tail), `FireBansheeIr` |
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
| Called from | `PlayerStep` |
| Calls | `ApiVector03`, `ApiVector04`, `ConsumeAmmo`, `SelectAmmoPointer` |
| Reads | `$67A5`-`$67AC` (`WorldVars+2`); `$75F3` (`ObjectTable+3`); `$7612` (`PlayerHeading`); `$7AA3` (`PlayerY+1165`); `$C53C` (`CurrentSlot`) |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$6A99`-`$6A9A` (`NextView+8`); `$75F3` (`ObjectTable+3`); `$7AA0`-`$7AA3` (`PlayerY+1162`); `$7AC1`-`$7AD1` (`PlayerY+1195`); `$A9B9`-`$A9BA` (`l_A9A0+25`); 2 more ranges |

### `RecallDragonfly` (`$C33E`)

**Recall the Dragonfly**

The fire key with the Dragonfly out: `$A9B9` = LaunchDragonfly again, its handler `$67BE`, the screen routine `$694B`, the view flag `$6A6D`, CameraToPlayer (play: 1 run).

Witness: L1 1 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play` 1) |
| Called from | `DragonflyStep` (tail) |
| Calls | `CameraToPlayer` |
| Writes | `$6A6D` (`ViewChangeFlag+1`); `$6A99`-`$6A9A` (`NextView+8`); `$7AB8`-`$7AB9` (`PlayerY+1186`); `$A9B9`-`$A9BA` (`l_A9A0+25`) |

### `CameraToPlayer` (`$C357`)

**Point the camera back at the player**

`$B9F4` = `$75F0`. Also called when a mission starts (15 runs over five recordings).

Witness: L1 15 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 75 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/missions` 8, `stage1/play2` 3, `stage1/play` 2 and 2 more) |
| Called from | `ResetCollisionTables`, `RecallDragonfly` |
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
| Reads | `$6D43` (`PointerZones+1`); `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AC2`-`$7AD1` (`PlayerY+1196`); `$82FF`-`$8300` (`Im2Table+255`); `$985E`-`$985F` (`StepX`, `StepY`) |
| Writes | `$6D43` (`PointerZones+1`); `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AC2`-`$7AD1` (`PlayerY+1196`) |

### `LaunchMissile` (`$C3DE`)

**Launch a guided missile (no recording runs it)**

Reached from `$C171` and `$C25C` when a target was locked.

Known only from the code: no recording runs it (static walk).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintAmmo` (`$C510`)

**Print the current slot's rounds when it is the one shown**

When the slot shown (`$D114`) is the current `$C53C`, falls into PrintAmmoAt.

Witness: L1 86 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 86 calls (`stage1/death` 62, `stage1/play2` 17, `stage1/play` 7) |
| Called from | `FireCannon`, `LaunchProjectile`, `SelectWeapon` (tail), `DropMine` (tail) |
| Calls | `PrintString` (tail), `PrintAmmoAt` |
| Reads | `$C53C` (`CurrentSlot`); `$D114` (`SlotShown`) |

### `PrintAmmoAt` (`$C519`)

**Print the rounds at `$FDC0`**

Converts the rounds at `$C527` and prints at `$FDC0`.

Witness: L1 87 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 18 calls (`stage1/play2` 18) |
| Called from | `PrintAmmo`, `FireDecoy` |
| Calls | `PrintString` (tail) |

### `PrintSlotStatus` (`$C51F`)

**Print the slot's status**

Clears `$BA13` and `$C4DC` (the IR view and the sight overlay off) when a weapon is deselected.

Witness: L1 14 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/play2` 9, `stage1/play` 4, `stage1/death` 1) |
| Called from | `SelectWeapon` |
| Writes | `$BA13` (`SetCamera+29`); `$C4DC` (`l_C4DB+1`) |

### `SelectWeapon` (`$C53F`)

**Select a weapon slot with the keys 1-4**

Writes `$C53C`, the slot record `$C53D`, the select routine of the store type (`$7B89` + 8 * type, word 4); a slot whose status `$68C9` + 6n is 0 prints "DAMAGED IN COMBAT" (`$C618`).

Witness: L1 14 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/play2` 9, `stage1/play` 4, `stage1/death` 1) |
| Called from | `PlayKeys` (tail) |
| Calls | `FillPanelRows`, `InvertPanelB`, `ShowMortarRange`, `SelectPhoenix`, `SelectPlain`, `PrintAmmo` (tail), `PrintSlotStatus`, `PrintElevation`, `ElevationZero`, `RetType11`, `PrintSlotAmmo`, `SelectType10`, `PrintType10`, `SoundSelect` |
| Reads | `$68C9`-`$68DF` (`SlotGauges`); `$7B91`-`$7BF8` (`PlayWorkspace+1`); `$8368`-`$837F` (`WeaponSlots`); `$C529`-`$C53C` (`WeaponVars+2`, `AmmoPointers`, `CurrentSlot`) |
| Writes | `$6B45`-`$6B56` (`PlayKeys+10`); `$A9B9`-`$A9BA` (`l_A9A0+25`); `$B551`-`$B552` (`ConsumeAmmo+1`); `$C527`-`$C52B` (`WeaponVars`); `$C53C`-`$C53E` (`CurrentSlot`); `$C5D2` (`l_C5AA+40`); 4 more ranges |

### `RefreshWeaponPanel` (`$C632`)

**Redraw the weapon panel**

When `$C529` is set: InvertPanelB with `$6500`, then the slot's state at (`$0000` patched) chooses `$C605` (damaged) or WeaponSelectText.

Witness: L1 26 (death, m2erbe, missions, play, play2).

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

Witness: L1 41 (death, play2).

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

Witness: L1 25 (play2).

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

Witness: L1 23 (play2).

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

Witness: L1 19 (death, m2erbe, m2ocean, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4 calls, 268 t-states own (0.00 %) |
| Runs (the other recordings) | 19 calls (`stage1/missions` 8, `stage1/play2` 7, `stage1/death` 1 and 3 more) |
| Called from | `LoadMission`, `BounceDecay` (tail) |
| Writes | `$75F7` (`PlayerSpeed`); `$7608`-`$7609` (`PlayerHandler`) |

### `SetBounce` (`$CC33`)

**Set the handler to BounceDecay**

+`$18`/+`$19` = BounceDecay (play2: 4 runs).

Witness: L1 4 (play2).

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
| Calls | `SetElevation` |

### `SetElevation` (`$CF32`)

**The elevation's sin / cos to `$B5C5` / `$B5C8`**

A + `$C0` through `$67E8` (sin / cos) to `$B5C8` / `$B5C5`: the vertical and horizontal speed of the next launch.

Witness: L1 4 (play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 3, `stage1/play` 1) |
| Called from | `PrintElevation` (tail), `ElevationZero`, `FireCluster13`, `LaunchPhantasm` |
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
| Calls | `PrintString` (tail) |
| Reads | `$CFF5` (`MineTimerCode+1`) |
| Writes | `$CFF5` (`MineTimerCode+1`) |

### `StoreMineTimer` (`$CFFC`)

**Store the timer and print it**

`$CFF5` = A, prints `$FDF9` (play2: 4 runs).

Witness: L1 4 (play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

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

### `PrintAimType10` (`$D104`)

**Print the aim of store type 10**

Prints `$FDE1`, the slot record (`$C53D`) = `$6BB0` (a RET: type 10 has no fire routine) (play2: 3 runs).

Witness: L1 3 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/play2` 3) |
| Called from | `PlayKeys` (tail) |
| Calls | `PrintString` |
| Reads | `$C53D`-`$C53E` (`CurrentSlot+1`) |
| Writes | `$6A46`-`$6A47` (`PlayLoop+58`) |

### `RetType11` (`$D24B`)

**The select routine of store type 11 (none)**

`RET`: the select routine of store type 11.

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `SelectWeapon` |

### `FireDecoy` (`$D24C`)

**Fire store type 11: projectile `$89` behind**

SelectAmmoPointer, ConsumeAmmo, spawns `$89` behind (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `PlayerSteering` |
| Calls | `ApiVector03`, `ApiVector04`, `SetFireCooldown` (tail), `ConsumeAmmo`, `PrintAmmoAt`, `SelectAmmoPointer` |
| Reads | `$67A7`-`$67AC` (`WorldVars+4`); `$7612` (`PlayerHeading`); `$82FF`-`$8300` (`Im2Table+255`); `$C53C` (`CurrentSlot`) |
| Writes | `$7A64` (`PlayerY+1102`); `$7A86`-`$7A97` (`PlayerY+1136`) |

### `DecoyStart` (`$D28C`)

**The decoy's first leg**

MoveObject; +`$31` counts the leg, +`$33` the legs left; at 0 Explode.

Witness: L1 13 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/play2` 13) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$7A95`-`$7A97` (`PlayerY+1151`) |
| Writes | `$7A7C`-`$7A7D` (`PlayerY+1126`); `$7A95`-`$7A97` (`PlayerY+1151`) |

### `DecoyZigZag` (`$D2AE`)

**The decoy's zig-zag**

MoveObject; the heading += +`$32` each pass (the zig-zag), legs as DecoyStart.

Witness: L1 26 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 26 calls (`stage1/play2` 26) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$7A86`-`$7A97` (`PlayerY+1136`) |
| Writes | `$7A7C`-`$7A96` (`PlayerY+1126`) |

### `PrintSlotName` (`$D30B`)

**Mark a slot without a fire routine**

The slot record = `$6BB0`, prints `$FDCD`.

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
| Called from | `PlayerStep` |
| Calls | `LaunchPhantasm` (tail) |
| Reads | `$C53C` (`CurrentSlot`) |

### `FireCluster13` (`$D31F`)

**Fire store type 13: projectile `$8B`**

A = the slot, JR LaunchCluster13 (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `PlayerSteering` |
| Calls | `LaunchProjectile` (tail), `SetElevation`, `SelectAmmoPointer` |
| Reads | `$C53C` (`CurrentSlot`) |

### `LaunchCluster13` (`$D341`)

**Launch the type 13 cluster**

SelectAmmoPointer, the elevation `$1E` (SetElevation), A = `$8B`, LaunchProjectile.

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintSlotAmmo` (`$D34E`)

**Print a slot's name**

When the slot record is not `$D324`, prints `$FDCD` (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `SelectWeapon` |
| Calls | `PrintString` (tail) |
| Reads | `$6A50`-`$6A51` (`PlayLoop+68`); `$C53D`-`$C53E` (`CurrentSlot+1`) |

### `Cluster13Step` (`$D369`)

**The type 13 cluster's flight**

MoveObject; the height follows +`$31` (rising, then falling).

Witness: L1 19 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 19 calls (`stage1/play2` 19) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00`, `ApiVector06` |
| Reads | `$7A2D`-`$7A2E` (`PlayerY+1047`); `$7A59` (`PlayerY+1091`) |
| Writes | `$7A2D`-`$7A2F` (`PlayerY+1047`); `$7A40`-`$7A59` (`PlayerY+1066`) |

### `Cluster13Burst` (`$D3AD`)

**A submunition falls**

Height -= 8 each pass; below 0 RemoveObject (the submunitions).

Witness: L1 47 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 47 calls (`stage1/play2` 47) |
| Called from | `RunObjectHandlers` |
| Calls | `ApiVector00` |
| Reads | `$7A2D`-`$7A2E` (`PlayerY+1047`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$7A2D`-`$7A2E` (`PlayerY+1047`) |

### `SelectAmmoPointer` (`$D3C6`)

**The current slot's ammunition pointer to `$B551`**

A = the slot; `$C534` + 2A to `$B551` (78 runs).

Witness: L1 78 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 78 calls (`stage1/death` 60, `stage1/play2` 12, `stage1/play` 6) |
| Called from | `FireCannon`, `FireMortar`, `FirePhoenixRr`, `FireBansheeRr`, `FirePhoenixIr`, `FireBansheeIr`, `LaunchDragonfly`, `FireClusterBomb`, `DropMine`, `FireDecoy`, `FireCluster13`, `LaunchPhantasm` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$C534`-`$C53B` (`AmmoPointers`) |
| Writes | `$B551`-`$B552` (`ConsumeAmmo+1`) |

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

### `SelectType10` (`$D45E`)

**Select store type 10**

Prints `$FDE1` / `$FDD7` with the type 10 table `$D115` (play2: 1 run).

Witness: L1 1 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/play2` 1) |
| Called from | `SelectWeapon` |
| Calls | `PrintString` (tail) |
| Reads | `$6A46`-`$6A47` (`PlayLoop+58`); `$C53D`-`$C53E` (`CurrentSlot+1`) |

### `PrintType10` (`$D46A`)

**Print a slot's aim**

Prints `$FDCD` / `$FDD7` with `$D3D6` (play: 1 run).

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
| Calls | `CopyHudGlyphsB` |

### `CopyHudGlyphsB` (`$D4AE`)

**Copy one HUD glyph**

The 8-byte copy loop of CopyHudGlyphs.

Witness: L1 94 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 94 calls (`stage1/play` 94) |
| Called from | `CopyHudGlyphs` |
| Reads | `$6F8F`-`$6F9E` (`ControlCodes`) |
| Writes | `$FD00`-`$FD0F` (`MissionHeader+8507`); `$FE0E`-`$FE1F` (`MissionHeader+8777`) |

### `BoundaryCheck` (`$D4B8`)

**The map edge: AWOL warning, then desertion**

A NOP / RET gate byte at `$D4B8`. |`$BC12`| against (`$DBD0`) and |`$BC1D`| against (`$DBD1`): inside, the state `$7578` = 0; outside, "GOING AWOL" (`$D51F`); beyond the extent + 4, `$7BF9` = `$CCD8` "PLAYER DESERTION" and `$7047`.

Witness: L1 3096 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 43 calls, 8,428 t-states own (0.00 %) |
| Runs (the other recordings) | 3,096 calls (`stage1/death` 2,491, `stage1/play` 232, `stage1/missions` 176 and 2 more) |
| Called from | `PlayerStep` |
| Calls | `ApiVector08`, `SetAwolState` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$BC12`-`$BC1D` (`l_BBFB+23`); `$DBD0`-`$DBD1` (`MissionHeader+11`) |

### `SetAwolState` (`$D4E9`)

**Set the AWOL state AwolState `$7578` (0 inside, 1 GOING AWOL, 2 desertion)**

`$7578` = A unless already equal.

Witness: L1 3053 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 43 calls, 1,212 t-states own (0.00 %) |
| Runs (the other recordings) | 3,053 calls (`stage1/death` 2,491, `stage1/play` 227, `stage1/play2` 171 and 2 more) |
| Called from | `BoundaryCheck` |
| Reads | `$7578` (`AwolState`) |

## objects

`src/game/objects.asm`

### `PlotRadarPixel` (`$A9FE`)

**Plot one radar pixel through the row table `$6600`**

Input: the blip's x and y on the radar. Looks up the screen row in the table `$6600`, ORs the pixel mask (E = `$49` + x AND 7 gives the bit) into the screen at the radar window `$5036`. Called by DrawRadar `$C05E` for each blip in the list `$6768`.

Witness: L1 14562 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,045 calls, 182,838 t-states own (0.03 %) |
| Runs (the other recordings) | 14,562 calls (`stage1/death` 7,338, `stage1/play2` 3,902, `stage1/play` 1,861 and 2 more) |
| Called from | `DrawRadar` |
| Reads | `$5036`-`$509A` (screen); `$5136`-`$519A` (screen); `$5236`-`$529A` (screen); `$5336`-`$547A` (screen); `$5516`-`$557A` (screen); `$5616`-`$567A` (screen); 4 more ranges |
| Writes | `$5036`-`$509A` (screen); `$5136`-`$519A` (screen); `$5236`-`$529A` (screen); `$5336`-`$557A` (screen); `$5616`-`$567A` (screen); `$5716`-`$577A` (screen) |

### `BearingTo` (`$B766`)

**Bearing from IX to IY, a byte angle (vector `$67C1`)**

dx, dy of the two records, then the octant and the ratio (BearingOctant `$B916`, BearingRatio `$B94A`, the table `$B9DE`). Output A = 0-255.

Witness: L1 7491 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 193,080 t-states own (0.03 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `ApiVector01` (tail) |
| Calls | `BearingOctant` (tail) |
| Reads | `$7613`-`$7690` (`PlayerX`, `PlayerY`); `$76C7`-`$76CC` (`PlayerY+177`); `$7703`-`$7708` (`PlayerY+237`); `$773F`-`$78AC` (`PlayerY+297`); `$78E3`-`$7924` (`PlayerY+717`); `$795B`-`$7A50` (`PlayerY+837`); 5 more ranges |

### `InvertPanelA` (`$B7AE`)

**Invert the screen rows of the table `$6500` (a panel flash)**

HL = `$6500`, then InvertPanelRows `$B7BD`. Seen in m2erbe, missions and play (12 runs).

Witness: L1 12 (m2erbe, missions, play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12 calls (`stage1/missions` 8, `stage1/play` 3, `stage1/m2erbe` 1) |
| Called from | `StatusKeys`, `PrintStatusHelp` (tail) |
| Calls | `InvertPanelRows` (tail) |
| Reads | `$40BA`-`$40FE` (screen); `$41BA`-`$41FE` (screen); `$42BA`-`$42FE` (screen); `$43BA`-`$43FE` (screen); `$44BA`-`$44FE` (screen); `$45BA`-`$45FE` (screen); 4 more ranges |
| Writes | `$40BA`-`$40FE` (screen); `$41BA`-`$41FE` (screen); `$42BA`-`$42FE` (screen); `$43BA`-`$43FE` (screen); `$44BA`-`$44FE` (screen); `$45BA`-`$45FE` (screen); 3 more ranges |

### `InvertPanelB` (`$B7B6`)

**Invert the rows of the table `$6550`**

HL = `$6550` (or the caller's HL), then InvertPanelRows. RefreshWeaponPanel `$C632` calls it with `$6500`.

Witness: L1 26 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 26 calls (`stage1/play2` 15, `stage1/play` 10, `stage1/death` 1) |
| Called from | `SelectWeapon`, `RefreshWeaponPanel` |
| Calls | `InvertPanelRows` |
| Reads | `$400B`-`$405C` (screen); `$410B`-`$415C` (screen); `$420B`-`$425C` (screen); `$430B`-`$435C` (screen); `$440B`-`$445C` (screen); `$450B`-`$455C` (screen); 4 more ranges |
| Writes | `$400B`-`$405C` (screen); `$410B`-`$415C` (screen); `$420B`-`$425C` (screen); `$430B`-`$435C` (screen); `$440B`-`$445C` (screen); `$450B`-`$455C` (screen); 3 more ranges |

### `InvertPanelRows` (`$B7BD`)

**Invert N screen rows from a table of addresses**

Each table entry is a screen address; the row's bytes are complemented (a flash of the panel when a weapon is selected or hit).

Witness: L1 38 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/play` 13) |
| Called from | `InvertPanelA` (tail), `InvertPanelB` |
| Reads | `$400B`-`$48BE` (screen); `$497A`-`$49BE` (screen); `$4A7A`-`$4ABE` (screen); `$4B7A`-`$4BBE` (screen); `$4C7A`-`$4CBE` (screen); `$4D7A`-`$4DBE` (screen); 6 more ranges |
| Writes | `$400B`-`$48BE` (screen); `$497A`-`$49BE` (screen); `$4A7A`-`$4ABE` (screen); `$4B7A`-`$4BBE` (screen); `$4C7A`-`$4CBE` (screen); `$4D7A`-`$4DBE` (screen); 2 more ranges |

### `ScriptDrawCarried` (`$B7E5`)

**3D script opcode 22: draw the carried object when the flag `$B7EB` is set**

Called from the script interpreter `$990F` (opcode 22, `$98E1` table). Pops the return address into the `JP nn` at `$B824` (operand `$B825`); the operand of `LD A,n` at `$B7EB` is the flag. When it is set: saves `$9A8E` / `$9AB3` / `$9A6C`, pages bank 3 (`$726C`), DrawModel `$B82A` with the record from `$68E6`, restores the view values. In every recording the flag is 0 and only the `JP` back runs.

Witness: L1 4 (play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/play2` 4) |
| Called from | `RunScript` |
| Calls | `ScriptNext` (tail) |
| Writes | `$B825`-`$B826` (`ScriptDrawCarriedReturn+1`) |

### `DrawObject` (`$B827`)

**Draw one object: its model, or the wreck model**

Input IX = the record. +2 bit 6 picks the wreck model +8/+9 instead of +`$1C`/+`$1D`; falls into DrawModel `$B82A`.

Witness: L1 9194 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 559 calls, 364,258 t-states own (0.06 %) |
| Runs (the other recordings) | 9,194 calls (`stage1/death` 6,208, `stage1/play2` 1,689, `stage1/play` 758 and 2 more) |
| Called from | `DrawEntry` (tail) |
| Calls | `RunScript` |
| Reads | `$67A6` (`WorldVars+3`); `$757A` (`AwolState+2`); `$762E`-`$7A68` (`PlayerY+24`); `$7A80`-`$7AA4` (`PlayerY+1130`); `$7ABC`-`$7AE0` (`PlayerY+1190`, `HelicarrierRecord`); `$7AF8`-`$7B0C` (`HelicarrierRecord+28`); 1 more ranges |
| Writes | `$68E7` (`MissionScore+5`); `$757A` (`AwolState+2`); `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$A12C` (`OpPolarPoints+19`); 1 more ranges |

### `DrawModel` (`$B82A`)

**Project and draw a 3D model at the object's view-space position**

Loads the view x / depth (+`$2B`..+`$2E`) into `$9A8E` / `$9AB3`, the night-sight mode `$757A`, and calls the 3D engine (bank 2 `$990F`).

Witness: L1 9194 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RemoveObject` (`$B8B1`)

**Free a record: unregister its collision, clear +2**

Input IX. UnregisterCollision `$CA3B`, +2 = 0 (the slot is free for FindFreeObject).

Witness: L1 61 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 53 calls (`stage1/death` 50, `stage1/play` 2, `stage1/play2` 1) |
| Called from | `CannonShellStep` (tail), `MortarShellStep` (tail) |
| Calls | `ApiVector05` |
| Writes | `$762E`-`$76A6` (`PlayerY+24`); `$76E2` (`PlayerY+204`); `$775A` (`PlayerY+324`); `$7796` (`PlayerY+384`); `$7886` (`PlayerY+624`); `$78FE` (`PlayerY+744`); 5 more ranges |

### `BearingOctant` (`$B916`)

**BearingTo: the octant from the signs of dx, dy**

dx, dy signs give 8 octants; then BearingRatio.

Witness: L1 7491 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 46,321 t-states own (0.01 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `BearingTo` (tail) |
| Calls | `ApiVector07`, `NegDE`, `BearingRatio` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `BearingRatio` (`$B94A`)

**BearingTo: the ratio of the smaller to the larger delta**

Divides the smaller |delta| by the larger to an index of BearingTable.

Witness: L1 7491 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 32,321 t-states own (0.00 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `BearingOctant` |
| Calls | `BearingLookup` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `BearingLookup` (`$B95A`)

**BearingTo: the angle from the table `$B9DE`**

Adds the octant base to the table angle.

Witness: L1 7491 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 486 calls, 190,511 t-states own (0.03 %) |
| Runs (the other recordings) | 7,491 calls (`stage1/death` 3,232, `stage1/play2` 1,906, `stage1/play` 1,223 and 2 more) |
| Called from | `BearingRatio` (tail) |
| Calls | `Divide` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$B9DE`-`$B9F5` (`BearingTable`) |

### `ActivateMissionObjects` (`$BBF1`)

**Spawn the mission objects near the player, despawn the far ones (16 per call)**

Walks the (`$DBD9`) records of 8 bytes at (`$DBDA`), 16 per call (the index is kept in `$BBF2` / `$BBFA`). A live record (bit 7) not yet spawned within 9 coarse units (InRange `$BD67`) gets a slot (FindSlot `$BCFD`), its type (ObjectSetType `$BD41`), a collision slot (`$C957`), its heading and position (CopyHeading `$BCBA`, CopyPosition `$BCC6`), and bit 6. A spawned one out of range is freed (bit 6 cleared; the slot found by +0 = the index in `$BC33`).

Witness: L1 3550 (death, m2erbe, missions, play, play2).

[Animation: `ActivateMissionObjects` at work](img/routines/ActivateMissionObjects.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 549,568 t-states own (0.08 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `ApiVector03`, `ApiVector04`, `ApiVector05`, `CopyHeading`, `FindSlot`, `InRange` |
| Reads | `$75F0`-`$784A` (`ObjectTable`, `PlayerHeight`, `PlayerSpeed`, `PlayerHandler` and 3 more); `$7884`-`$7886` (`PlayerY+622`); `$78C0`-`$78C2` (`PlayerY+682`); `$78FC`-`$78FE` (`PlayerY+742`); `$7938`-`$7976` (`PlayerY+802`); `$79B2` (`PlayerY+924`); 9 more ranges |
| Writes | `$762C`-`$784A` (`PlayerY+22`); `$7884`-`$7886` (`PlayerY+622`); `$78C0`-`$78C2` (`PlayerY+682`); `$78FC`-`$78FE` (`PlayerY+742`); `$7938`-`$7976` (`PlayerY+802`); `$79B0`-`$79B2` (`PlayerY+922`); 13 more ranges |

### `CopyHeading` (`$BCBA`)

**Copy the list record's heading (+2) to the object**

The list record's +2 to the object's +`$22`.

Witness: L1 183 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 11 calls, 796 t-states own (0.00 %) |
| Runs (the other recordings) | 183 calls (`stage1/missions` 79, `stage1/death` 37, `stage1/play2` 36 and 2 more) |
| Called from | `ActivateMissionObjects` |
| Calls | `CopyPosition` |
| Reads | `$DCB2`-`$DD1C` (`MissionHeader+237`); `$DD32`-`$DD48` (`MissionHeader+365`); `$DD78`-`$DE96` (`MissionHeader+435`); `$DEBE` (`MissionHeader+761`); `$DEF4` (`MissionHeader+815`); `$DF16`-`$DF3C` (`MissionHeader+849`); 2 more ranges |
| Writes | `$764D`-`$786A` (`PlayerY+55`); `$78A5`-`$78A6` (`PlayerY+655`); `$78E1`-`$78E2` (`PlayerY+715`); `$791D`-`$791E` (`PlayerY+775`); `$7959`-`$7996` (`PlayerY+835`); `$79D1`-`$79D2` (`PlayerY+955`); 3 more ranges |

### `CopyPosition` (`$BCC6`)

**Copy the list record's X / Y words, << 2 into 24 bits (WordToWorld `$BD83`)**

+4/+5 and +6/+7 of the list record through WordToWorld `$BD83` to +`$23`-+`$25` and +`$26`-+`$28`.

Witness: L1 366 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 22 calls, 2,286 t-states own (0.00 %) |
| Runs (the other recordings) | 366 calls (`stage1/missions` 158, `stage1/death` 74, `stage1/play2` 72 and 2 more) |
| Called from | `CopyHeading` |
| Calls | `WordToWorld` |
| Reads | `$DCB4`-`$DD21` (`MissionHeader+239`); `$DD34`-`$DD4D` (`MissionHeader+367`); `$DD7A`-`$DE9B` (`MissionHeader+437`); `$DEC0`-`$DEC3` (`MissionHeader+763`); `$DEF6`-`$DEF9` (`MissionHeader+817`); `$DF18`-`$DF41` (`MissionHeader+851`); 2 more ranges |
| Writes | `$764F`-`$7870` (`PlayerY+57`); `$78A7`-`$78AC` (`PlayerY+657`); `$78E3`-`$78E8` (`PlayerY+717`); `$791F`-`$7924` (`PlayerY+777`); `$795B`-`$799C` (`PlayerY+837`); `$79D3`-`$79D8` (`PlayerY+957`); 3 more ranges |

### `FindProjectileSlot` (`$BCD6`)

**Find a free record for a projectile (up to record 23)**

D = `$17`, falls into FindFreeObject.

Witness: L1 70 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 70 calls (`stage1/death` 60, `stage1/play2` 6, `stage1/play` 4) |
| Called from | `ConsumeAmmo` |
| Calls | `FindFreeObjectD` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `FindFreeObject` (`$BCDA`)

**Find a free record 1-20 (vector `$67C4`)**

D = `$15`; carry set and IX = the record when found.

Witness: L1 219 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 17 calls, 9,784 t-states own (0.00 %) |
| Runs (the other recordings) | 219 calls (`stage1/missions` 74, `stage1/play2` 64, `stage1/play` 50 and 2 more) |
| Called from | `ApiVector02` (tail) |
| Calls | `FindFreeObjectD`, `FindFreeLoop` (tail) |
| Reads | `$762E`-`$78FE` (`PlayerY+24`); `$793A` (`PlayerY+804`); `$7976` (`PlayerY+864`); `$79B2` (`PlayerY+924`); `$79EE` (`PlayerY+984`); `$7A2A` (`PlayerY+1044`); 3 more ranges |

### `FindFreeObjectD` (`$BCDC`)

**Find a free record below D: +2 = 0**

Stores 23 - E in `$C95C` and the record in `$C973`.

Witness: L1 289 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 206 calls (`stage1/death` 82, `stage1/play2` 70, `stage1/play` 54) |
| Called from | `FindProjectileSlot` (tail), `FindFreeObject` |
| Calls | `FindFreeLoop` (tail) |
| Reads | `$762E`-`$793A` (`PlayerY+24`); `$7976` (`PlayerY+864`); `$79B2` (`PlayerY+924`); `$79EE` (`PlayerY+984`); `$7A2A` (`PlayerY+1044`); `$7A66` (`PlayerY+1104`); 3 more ranges |

### `FindFreeLoop` (`$BCF0`)

**The scan loop**

Steps 60 bytes per record until +2 = 0 or the limit.

Witness: L1 415 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 1,848 t-states own (0.00 %) |
| Runs (the other recordings) | 415 calls (`stage1/missions` 123, `stage1/death` 118, `stage1/play2` 100 and 2 more) |
| Called from | `FindFreeObject` (tail), `FindFreeObjectD` (tail), `FindSlot` (tail) |
| Writes | `$C95C` (`RegisterCollision+5`); `$C973`-`$C974` (`l_C96D+6`) |

### `FindSlot` (`$BCFD`)

**Find a slot for a list record: the first free or evictable record of 1-20**

One scan of records 1-20 (it does not call FindFreeObject): the first record that is free (+2 = 0) or holds an enemy shell (+3 AND `$50` = `$10`) is taken; an evicted shell is unregistered (`$67CD`) and its +2 cleared. Then the list index to +0. NC when none.

Witness: L1 185 (death, m2erbe, missions, play, play2).

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

Witness: L1 431 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 38,149 t-states own (0.01 %) |
| Runs (the other recordings) | 431 calls (`stage1/missions` 125, `stage1/death` 119, `stage1/play2` 103 and 2 more) |
| Called from | `ApiVector03` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$B3CA`-`$B405` (`ShellTemplate80`); `$B47E`-`$B54F` (`ShellTemplate80+180`); `$DBD7`-`$DBD8` (`MissionHeader+18`); `$DE5F`-`$DE7C` (`MissionHeader+666`); `$DEB9`-`$DEF4` (`MissionHeader+756`); 3 more ranges |
| Writes | `$762D`-`$7994` (`PlayerY+23`); `$79B1`-`$79D0` (`PlayerY+923`); `$79ED`-`$7A0C` (`PlayerY+983`); `$7A29`-`$7A48` (`PlayerY+1043`); `$7A65`-`$7A84` (`PlayerY+1103`); `$7AA1`-`$7AC0` (`PlayerY+1163`); 2 more ranges |

### `InRange` (`$BD67`)

**Is the list record within range of the player (4 coarse units for type 0, 9 for the others)**

|X word >> 8 - `$BC12`| and |Y - `$BC1D`| below the range: 4 for type 0 (trees), 9 for every other type (type 1 trees included). Called for each list record (70 373 runs).

Witness: L1 70373 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,613 calls, 227,113 t-states own (0.03 %) |
| Runs (the other recordings) | 70,373 calls (`stage1/death` 47,698, `stage1/play2` 9,278, `stage1/missions` 6,198 and 2 more) |
| Called from | `ActivateMissionObjects` |
| Calls | `ApiVector08` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `WordToWorld` (`$BD83`)

**A list word << 2 into a 24-bit coordinate**

HL << 2 with the carry into the third byte.

Witness: L1 366 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 22 calls, 1,906 t-states own (0.00 %) |
| Runs (the other recordings) | 366 calls (`stage1/missions` 158, `stage1/death` 74, `stage1/play2` 72 and 2 more) |
| Called from | `CopyPosition` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `TransformObjects` (`$BD98`)

**Make every present object camera-relative, cull it, insert it into the depth tree**

For each record with +2 bit 7: position minus camera, RotateToView `$BBBC`, depth cull, OnScreen `$BEA2` with the radius, then DepthInsert `$BEDE` into the tree at `$6800`; a blip for the radar (RadarAddBlip `$C0B2`).

Witness: L1 3550 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 1,790,960 t-states own (0.27 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `RotateToView`, `OnScreen`, `ClearDepthTree`, `DepthInsert`, `RadarAddBlip` |
| Reads | `$66D0`-`$66D3` (`PolyWorkSpare+1`); `$67A7`-`$67AE` (`WorldVars+4`); `$762E`-`$79F2` (`PlayerY+24`); `$7A0F`-`$7A14` (`PlayerY+1017`); `$7A2A`-`$7A2E` (`PlayerY+1044`); `$7A4B`-`$7A50` (`PlayerY+1077`); 10 more ranges |
| Writes | `$66CF`-`$66D3` (`PolyWorkSpare`); `$762E`-`$7A2A` (`PlayerY+24`); `$7A53`-`$7A66` (`PlayerY+1085`); `$7A8F`-`$7AA2` (`PlayerY+1145`); `$7ACB`-`$7ADE` (`PlayerY+1205`, `HelicarrierRecord`); `$7B07`-`$7B1A` (`HelicarrierRecord+43`); 5 more ranges |

### `OnScreen` (`$BEA2`)

**Is the object within the screen with its radius**

View x (+`$2B`/+`$2C`) against the depth with the radius +`$16`/+`$17`.

Witness: L1 32872 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,677 calls, 323,721 t-states own (0.05 %) |
| Runs (the other recordings) | 32,872 calls (`stage1/death` 18,315, `stage1/play2` 6,343, `stage1/play` 4,489 and 2 more) |
| Called from | `TransformObjects` |
| Calls | `OnScreenX` |
| Reads | `$7642`-`$7ACC` (`PlayerY+44`); `$7AF2`-`$7AF3` (`HelicarrierRecord+22`); `$7B07`-`$7B08` (`HelicarrierRecord+43`); `$82FF`-`$8300` (`Im2Table+255`) |

### `OnScreenX` (`$BEA8`)

**The x half of OnScreen**

The entry for the x test.

Witness: L1 32885 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 6,356 calls (`stage1/play2` 6,356) |
| Called from | `OnScreen`, `MissileSeek` |
| Reads | `$7642`-`$7A18` (`PlayerY+44`); `$7A3E`-`$7A3F` (`PlayerY+1064`); `$7A53`-`$7A54` (`PlayerY+1085`); `$7A7A`-`$7A7B` (`PlayerY+1124`); `$7A8F`-`$7A90` (`PlayerY+1145`); `$7AB6`-`$7AB7` (`PlayerY+1184`); 2 more ranges |

### `ClearDepthTree` (`$BED2`)

**Empty the depth tree at `$6800`**

Resets the node pointer and the root at `$6800`.

Witness: L1 3550 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 7,394 t-states own (0.00 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `TransformObjects` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$66D4` (`PolyWorkSpare+5`); `$6800` (`PlayWork`); `$BF22`-`$BF23` (`DepthTreeVars+2`) |

### `DepthInsert` (`$BEDE`)

**Insert a record into the depth tree (6-byte nodes: depth, left, right, record)**

Walks from the root, left when nearer, right when farther, and links a new 6-byte node.

Witness: L1 9829 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 562 calls, 222,304 t-states own (0.03 %) |
| Runs (the other recordings) | 9,829 calls (`stage1/death` 6,575, `stage1/play2` 1,843, `stage1/play` 783 and 2 more) |
| Called from | `TransformObjects` |
| Reads | `$66D4` (`PolyWorkSpare+5`); `$6800`-`$6850` (`PlayWork`); `$82FF`-`$8300` (`Im2Table+255`); `$BF20`-`$BF23` (`DepthTreeVars`) |
| Writes | `$66D4` (`PolyWorkSpare+5`); `$6800`-`$6859` (`PlayWork`); `$BF20`-`$BF23` (`DepthTreeVars`) |

### `DrawObjectsInOrder` (`$BF53`)

**Draw the objects far to near (in-order walk of the depth tree)**

Calls DrawEntry `$BF83` per node.

Witness: L1 3507 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 82,123 t-states own (0.01 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop` |
| Calls | `DrawEntry` |
| Reads | `$66D4` (`PolyWorkSpare+5`); `$6802`-`$6857` (`PlayWork+2`); `$82FF`-`$8300` (`Im2Table+255`) |

### `DrawEntry` (`$BF83`)

**Draw one tree entry: an object (DrawObject) or a debris particle**

A pointer at or above `$CF00` is a particle of the bank 3 list, drawn as a dot.

Witness: L1 9715 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 559 calls, 24,256 t-states own (0.00 %) |
| Runs (the other recordings) | 9,715 calls (`stage1/death` 6,575, `stage1/play2` 1,843, `stage1/play` 758 and 2 more) |
| Called from | `DrawObjectsInOrder` |
| Calls | `PageBank3`, `SaveBank`, `RestoreBank`, `RunScript`, `DrawObject` (tail) |
| Reads | `$67A6` (`WorldVars+3`); `$6804`-`$685B` (`PlayWork+4`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$68E7` (`MissionScore+5`); `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`); `$ABFE` (`BoxTiltPitch+1`) |

### `MoveObject` (`$BFD1`)

**Move an object by its speed along its heading (vector `$67BE`)**

X += speed * sin(heading), Y += speed * cos(heading), through `$A8B2` / `$A7F2`.

Witness: L1 14450 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 632 calls, 315,573 t-states own (0.05 %) |
| Runs (the other recordings) | 14,450 calls (`stage1/death` 8,892, `stage1/play2` 2,342, `stage1/play` 1,779 and 2 more) |
| Called from | `ApiVector00` (tail) |
| Calls | `MulFrac`, `SinCosHalf` |
| Reads | `$75F7`-`$7708` (`PlayerSpeed`, `PlayerHandler`, `PlayerHeading`, `PlayerX` and 1 more); `$775F`-`$7A8C` (`PlayerY+329`); `$7AA7` (`PlayerY+1169`); `$7AC1`-`$7AC8` (`PlayerY+1195`); `$7AE3` (`HelicarrierRecord+7`); `$7AFD`-`$7B04` (`HelicarrierRecord+33`); 2 more ranges |
| Writes | `$7613`-`$7708` (`PlayerX`, `PlayerY`); `$777B`-`$7A8C` (`PlayerY+357`); `$7AC3`-`$7AC8` (`PlayerY+1197`); `$7AFF`-`$7B04` (`HelicarrierRecord+35`); `$BBC8` (`RotateToView+12`) |

### `RunObjectHandlers` (`$C026`)

**Run each present object's step handler**

24 records from `$75F0`: when +2 bit 7 and +3 bit 0 are set, CALL (+`$18`) with IX = the record.

Witness: L1 3550 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 445,594 t-states own (0.07 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `StartMission`, `PlayLoopTail`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `ApiVector00`, `PlayerStep`, `CannonShellStep`, `MortarShellStep`, `DragonflyStep`, `BounceDecay`, `ClusterRise`, `ClusterParachute`, `ClusterBlast`, `MineFall`, `MineCountdown`, `DecoyStart`, `DecoyZigZag`, `Cluster13Step`, `Cluster13Burst`, `PhantasmStep`, `PhantasmSpin`, `HelicarrierInit`, `HelicarrierWait`, `MissionHeader` |
| Reads | `$75F2`-`$7AB9` (`ObjectTable+2`, `PlayerHeight`, `PlayerSpeed`, `PlayerHandler` and 3 more); `$7ADE`-`$7ADF` (`HelicarrierRecord+2`); `$7AF4`-`$7AF5` (`HelicarrierRecord+24`); `$7B1A` (`HelicarrierRecord+62`); `$7B56` (`HelicarrierRecord+122`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$C04B`-`$C050` (`l_C030+27`, `l_C04F`) |

### `DrawRadar` (`$C05E`)

**Draw the radar: clear it, plot the blip list `$6768`**

ClearRadar `$C094`, then RadarPlotList `$C079` (3483 runs, every 3D frame but the first).

Witness: L1 3483 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 117,822 t-states own (0.02 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop` |
| Calls | `PlotRadarPixel`, `ClearRadar` |
| Reads | `$6768`-`$6780` (`FaceFlags+64`); `$68C3` (`GaugeRecords+24`); `$7BFB`-`$7BFC` (`FailReason+2`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$6768`-`$6780` (`FaceFlags+64`); `$AA1A` (`PlotRadarPixel+28`) |

### `RadarPlotList` (`$C079`)

**Plot the list of blips and reset it**

Resets the list pointer `$7BFB`, sets `$AA1A`, plots each pair at `$6768` through PlotRadarPixel `$A9FE`.

Witness: L1 3483 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearRadar` (`$C094`)

**Clear 32 rows of 5 bytes at `$5036` with stack pushes**

SP = the radar's screen rows, PUSH of zeros (32 rows, 5 bytes each at `$5036`).

Witness: L1 3483 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 742,358 t-states own (0.11 %) |
| Runs (the other recordings) | 3,483 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `DrawRadar` |
| Writes | `$5036`-`$509A` (screen); `$5136`-`$519A` (screen); `$5236`-`$529A` (screen); `$5336`-`$539A` (screen); `$5416`-`$547A` (screen); `$5516`-`$557A` (screen); 3 more ranges |

### `RadarAddBlip` (`$C0B2`)

**Add an object to the radar list when within range**

Input: the object's offset from the player. RadarRange `$C104`, RadarScale `$C0D2`, RadarStoreBlip `$C0F7`.

Witness: L1 27405 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,378 calls, 952,507 t-states own (0.14 %) |
| Runs (the other recordings) | 27,405 calls (`stage1/death` 14,737, `stage1/play2` 5,403, `stage1/play` 3,936 and 2 more) |
| Called from | `TransformObjects` |
| Calls | `ApiVector07`, `RadarRange` |
| Reads | `$7BFB`-`$7BFC` (`FailReason+2`); `$82FF`-`$8300` (`Im2Table+255`); `$BA27` (`l_BA1F+8`) |
| Writes | `$6768`-`$677F` (`FaceFlags+64`); `$7BFB`-`$7BFC` (`FailReason+2`) |

### `RadarScale` (`$C0D2`)

**Scale the offsets to radar units**

SRA H / RR L 8 times on each offset.

Witness: L1 27405 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RadarStoreBlip` (`$C0F7`)

**Store the blip in the list at (`$7BFB`)**

Writes y, x to (`$7BFB`) and advances it.

Witness: L1 14952 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RadarRange` (`$C104`)

**Is the offset within the radar's range**

Carry set when the offset is out of the radar (|d| beyond the window).

Witness: L1 48723 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,474 calls, 140,602 t-states own (0.02 %) |
| Runs (the other recordings) | 48,723 calls (`stage1/death` 25,964, `stage1/play2` 9,762, `stage1/play` 7,064 and 2 more) |
| Called from | `RadarAddBlip` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `TurnToward` (`$C485`)

**Turn IX toward IY by at most 4 per pass**

Input IX, IY. BearingTo, the difference with +`$22`, |d| < 4 sets it, else +-4. Used by the Helicarrier (HelicarrierWait) and the missiles (545 runs).

Witness: L1 545 (death, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 13 calls, 1,368 t-states own (0.00 %) |
| Runs (the other recordings) | 545 calls (`stage1/death` 249, `stage1/play` 132, `stage1/play2` 99 and 1 more) |
| Called from | `HelicarrierWait`, `MissionHeader` (tail) |
| Calls | `ApiVector01`, `ApiVector08` |
| Reads | `$764E` (`PlayerY+56`); `$768A` (`PlayerY+116`); `$786A` (`PlayerY+596`); `$78E2` (`PlayerY+716`); `$791E` (`PlayerY+776`); `$795A` (`PlayerY+836`); 8 more ranges |
| Writes | `$764E` (`PlayerY+56`); `$768A` (`PlayerY+116`); `$786A` (`PlayerY+596`); `$78E2` (`PlayerY+716`); `$791E` (`PlayerY+776`); `$795A` (`PlayerY+836`); 6 more ranges |

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

Witness: L1 3507 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 5,310 t-states own (0.00 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$9000`-`$9101` (`BackBuffer+1295`); `$9120`-`$9121` (`BackBuffer+1583`); `$9140`-`$9141` (`BackBuffer+1615`); `$9160`-`$9161` (`BackBuffer+1647`); `$9180`-`$9181` (`BackBuffer+1679`); 5 more ranges |
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

Witness: L1 3550 (death, m2erbe, missions, play, play2).

[Animation: `CollisionPass` at work](img/routines/CollisionPass.gif)

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 118 calls, 1,717,826 t-states own (0.26 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `ApiVector10`, `NegHL`, `KillTree`, `Explode`, `RecordByIndex`, `PlayerHit`, `MissionHeader` |
| Reads | `$75F5`-`$7A4F` (`PlayerHeight`, `PlayerSpeed`, `PlayerHandler`, `PlayerHeading` and 2 more); `$7A69`-`$7A8B` (`PlayerY+1107`); `$7AA5`-`$7AC7` (`PlayerY+1167`); `$7AE7`-`$7B03` (`HelicarrierRecord+11`); `$82FF`-`$8300` (`Im2Table+255`); `$C649`-`$C743` (`CollisionTables+1`); 1 more ranges |
| Writes | `$C649`-`$C743` (`CollisionTables+1`); `$C7BD` (`CollisionPass+1`); `$C7FC`-`$C813` (`l_C7FB+1`); `$C8BE`-`$C8BF` (`l_C8AF+15`); `$C8D5`-`$C8D6` (`l_C8AF+38`); `$C918`-`$C929` (`l_C900+24`); 1 more ranges |

### `RecordByIndex` (`$C944`)

**HL = the record B (+2), A = its state**

Input B = the record number. Output HL = the record, A = +2.

Witness: L1 15176 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,292 calls, 254,279 t-states own (0.04 %) |
| Runs (the other recordings) | 15,176 calls (`stage1/play2` 5,062, `stage1/death` 4,648, `stage1/play` 3,086 and 2 more) |
| Called from | `CollisionPass` |
| Reads | `$75F2`-`$793A` (`ObjectTable+2`, `PlayerHeight`, `PlayerSpeed`, `PlayerHandler` and 3 more); `$7976` (`PlayerY+864`); `$79B2` (`PlayerY+924`); `$79EE` (`PlayerY+984`); `$7A2A` (`PlayerY+1044`); `$7A66` (`PlayerY+1104`); 3 more ranges |

### `RegisterCollision` (`$C957`)

**Give the record a collision slot (vector `$67CA`)**

Takes the first free entry of the slot list `$C775`, stores it in +`$3B`, sets the pair timers of the new row in `$C648`.

Witness: L1 431 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 28 calls, 131,565 t-states own (0.02 %) |
| Runs (the other recordings) | 431 calls (`stage1/missions` 125, `stage1/death` 119, `stage1/play2` 103 and 2 more) |
| Called from | `ApiVector04` (tail) |
| Reads | `$75F2`-`$79EF` (`ObjectTable+2`, `PlayerHeight`, `PlayerSpeed`, `PlayerHandler` and 3 more); `$7A2A`-`$7A2B` (`PlayerY+1044`); `$7A66`-`$7A67` (`PlayerY+1104`); `$7AA2`-`$7AA3` (`PlayerY+1164`); `$7ADE`-`$7ADF` (`HelicarrierRecord+2`); `$7B1A` (`HelicarrierRecord+62`); 6 more ranges |
| Writes | `$C649`-`$C789` (`CollisionTables+1`); `$C9BA` (`l_C9B4+6`); `$C9D9`-`$C9E0` (`l_C9D1+8`); `$CA14` (`l_CA0B+9`) |

### `CollisionFilter` (`$C9A7`)

**Which pairs collide: the state bits 2 / 4 / 6 / 7**

Inside CollisionPass: both +2 bytes decide whether the pair is tested (radar bit 2, bit 4 no-collide, wrecks bits 6 / 7).

Witness: L1 4065 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UnregisterCollision` (`$CA3B`)

**Free the record's collision slot (vector `$67CD`)**

Returns the slot of +`$3B` to the list and marks the row's timers `$FF`.

Witness: L1 230 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 13 calls, 18,294 t-states own (0.00 %) |
| Runs (the other recordings) | 230 calls (`stage1/death` 114, `stage1/play2` 51, `stage1/play` 48 and 2 more) |
| Called from | `ApiVector05` (tail) |
| Reads | `$7667`-`$7793` (`PlayerY+81`); `$77CF`-`$78FB` (`PlayerY+441`); `$7937`-`$7A63` (`PlayerY+801`); `$7A9F` (`PlayerY+1161`); `$7ADB` (`PlayerY+1221`); `$7B17` (`HelicarrierRecord+59`); 2 more ranges |
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

Witness: L1 3550 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 452,065 t-states own (0.07 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `ResetSegmentWalk` (tail), `TestVertexNear`, `TestVertexNearB` |
| Reads | `$67A8`-`$67AC` (`WorldVars+5`); `$7BFD`-`$7C06` (`FailReason+4`); `$82FF`-`$8300` (`Im2Table+255`); `$ADF7` (`l_ADEA+13`); `$AE5A`-`$AE5B` (`SegmentWalkCount`); `$DBDC`-`$DBDE` (`MissionHeader+23`); 1 more ranges |
| Writes | `$8305`-`$831D` (`WorldWork`); `$AD4C`-`$AD4D` (`SegmentVisibility+7`); `$ADF2`-`$ADF7` (`l_ADEA+8`); `$AE1A` (`l_AE0F+11`); `$AE5A`-`$AE5B` (`SegmentWalkCount`); `$BC12`-`$BC1D` (`l_BBFB+23`) |

### `ResetSegmentWalk` (`$AE42`)

**Reset the segment walk: `$DC80`, the count (`$DBDC`), the flags `$8305`**

Stores `$DC80` in the pointer `$AD4C`, the segment count in `$AE5A`, `$8305` in `$AD48` and clears `$AE5B`. Called before SegmentVisibility.

Witness: L1 3576 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 120 calls, 13,080 t-states own (0.00 %) |
| Runs (the other recordings) | 3,576 calls (`stage1/death` 2,511, `stage1/play2` 416, `stage1/missions` 323 and 2 more) |
| Called from | `StartMission`, `SegmentVisibility` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$DBDC` (`MissionHeader+23`) |
| Writes | `$AD48`-`$AD4D` (`SegmentVisibility+3`); `$AE5A`-`$AE5B` (`SegmentWalkCount`) |

### `TestVertexNear` (`$AE5C`)

**Test vertex A against the coarse player position: within 8 units**

EXX, then reads vertex X `$DC00`+A against `$BC12`; falls into TestVertexNearX `$AE61`. Carry out: the vertex is near.

Witness: L1 33063 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 19,992 t-states own (0.00 %) |
| Runs (the other recordings) | 33,063 calls (`stage1/death` 20,603, `stage1/missions` 5,978, `stage1/play2` 3,304 and 2 more) |
| Called from | `SegmentVisibility`, `DrawSegments` |
| Calls | `TestVertexNearX` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$BC12` (`l_BBFB+23`) |

### `TestVertexNearX` (`$AE61`)

**Compare one vertex coordinate with the player's, |d| < 8**

Input L = the vertex table offset, A = the player's coarse coordinate. Output carry set when |vertex - player| < 8. Used for both axes (TestVertexNearY `$AE79` adds `$40` to reach the Y table).

Witness: L1 58209 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,904 calls, 203,766 t-states own (0.03 %) |
| Runs (the other recordings) | 58,209 calls (`stage1/death` 35,965, `stage1/missions` 9,100, `stage1/play2` 6,608 and 2 more) |
| Called from | `TestVertexNear`, `TestVertexNearB` (tail), `TestVertexNearY` (tail) |
| Calls | `ApiVector08` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$DC00`-`$DC19` (`MissionHeader+59`); `$DC40`-`$DC5B` (`MissionHeader+123`); `$DC80` (`MissionHeader+187`); `$DCC0` (`MissionHeader+251`) |

### `TestVertexNearB` (`$AE78`)

**Test the segment's second vertex (EXX, then the Y test)**

EXX and falls into TestVertexNearY `$AE79`.

Witness: L1 24774 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 36,176 t-states own (0.01 %) |
| Runs (the other recordings) | 24,774 calls (`stage1/death` 15,362, `stage1/play2` 3,304, `stage1/missions` 2,832 and 2 more) |
| Called from | `SegmentVisibility`, `DrawSegments` |
| Calls | `TestVertexNearX` (tail), `TestVertexNearY` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$BC1D` (`l_BBFB+34`) |

### `TestVertexNearY` (`$AE79`)

**Test a vertex's Y (`$DC40`+i) against `$BC1D`**

L = vertex + `$40`, A = (`$BC1D`), then JP TestVertexNearX `$AE61`.

Witness: L1 25146 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4,280 calls (`stage1/missions` 3,122, `stage1/m2erbe` 1,158) |
| Called from | `TestVertexNearB`, `DrawSegments` |
| Calls | `TestVertexNearX` (tail) |
| Reads | `$BC1D` (`l_BBFB+34`) |

### `SetupClipWindow` (`$AEA0`)

**Build the clip window and the vertex buffers for the segment draw**

From the segment count (+5) sets the loop limit `$AEEA`, the clip window and the vertex buffers at `$FD00`-`$FF07` and `$990F`. Called once per frame before DrawSegments.

Witness: L1 3507 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 26,656 t-states own (0.00 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop` |
| Calls | `DrawSegments` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$BC12`-`$BC1D` (`l_BBFB+23`); `$DBDC` (`MissionHeader+23`) |
| Writes | `$AEEA` (`DrawSegmentLoop+2`); `$B2A4`-`$B2A7` (`l_B2A3+1`, `l_B2A6`); `$B2CD`-`$B2D0` (`l_B2CC+1`, `l_B2CF`) |

### `DrawSegments` (`$AEE1`)

**Draw every visible segment as a quad**

Walks the segments whose flag in `$8305` is set: transforms both vertices (TransformVertex `$B242`), clips them by the orientation byte +2 (one axis `$AFDE`, the other `$B000`, the diagonals `$B021`, `$B0E4`, `$B16A`), and draws the quad by the style byte +5 (DrawSegmentStyle `$B1B6`).

Witness: L1 36513 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,190 calls, 127,130 t-states own (0.02 %) |
| Runs (the other recordings) | 36,513 calls (`stage1/death` 25,100, `stage1/play2` 4,130, `stage1/missions` 3,927 and 2 more) |
| Called from | `SetupClipWindow`, `DrawSegmentLoop` (tail) |
| Calls | `TestVertexNear`, `TestVertexNearB`, `TestVertexNearY`, `DrawSegmentLoop`, `ClipSegmentAxisX`, `ClipSegmentAxisY`, `TransformSegmentEnds` (tail), `DrawSegmentStyle` (tail), `ClipTestX`, `ClipTestY` |
| Reads | `$82FF`-`$831C` (`Im2Table+255`, `Armour`); `$AE92`-`$AE9F` (`SegmentScratch+16`); `$DC80`-`$DCDF` (`MissionHeader+187`) |
| Writes | `$830D` (`WorldWork+8`); `$AE85` (`SegmentScratch+3`); `$AE98`-`$AE9F` (`SegmentScratch+22`); `$AFC4` (`l_AF83+65`); `$B1BA` (`DrawSegmentStyle+4`); `$B2E5`-`$B2F8` (`StoreVertex+1`) |

### `DrawSegmentLoop` (`$AEE8`)

**The loop of DrawSegments, entered again by DrawSegmentTail**

One pass per segment: reads the next 6-byte record, skips it when its flag is 0.

Witness: L1 36513 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,190 calls, 32,744 t-states own (0.00 %) |
| Runs (the other recordings) | 36,513 calls (`stage1/death` 25,100, `stage1/play2` 4,130, `stage1/missions` 3,927 and 2 more) |
| Called from | `DrawSegments`, `DrawSegmentTail` (tail), `TransformSegmentEnds` (tail) |
| Calls | `DrawSegments` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `ClipSegmentAxisX` (`$AFDE`)

**Clip an axis-aligned segment (orientation 0)**

The segment runs along one axis; its width is +3 (`$B2E5`), its height +4 (`$AFC4`). Seen only on the maps of missions 1 and 2 (missions, m2erbe).

Witness: L1 702 (m2erbe, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 702 calls (`stage1/missions` 538, `stage1/m2erbe` 164) |
| Called from | `DrawSegments` |
| Calls | `StoreVertex` (tail), `RotateToView` |
| Reads | `$67A7`-`$67AB` (`WorldVars+4`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`) |

### `ClipSegmentAxisY` (`$B000`)

**Clip a segment along the other axis (orientation bit 7)**

As ClipSegmentAxisX `$AFDE` for the other axis.

Witness: L1 744 (m2erbe, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 744 calls (`stage1/missions` 580, `stage1/m2erbe` 164) |
| Called from | `DrawSegments` |
| Calls | `ClipSegmentDiagonal`, `VertexByteToWorld` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$AE86`-`$AE8B` (`SegmentScratch+4`) |

### `ClipSegmentDiagonal` (`$B021`)

**Clip a diagonal segment**

Orientation other than 0 / `$80`: the two vertices give the slope; calls ClipDiagonalSide `$B0E4` and `$B16A`.

Witness: L1 744 (m2erbe, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 744 calls (`stage1/missions` 580, `stage1/m2erbe` 164) |
| Called from | `ClipSegmentAxisY` |
| Calls | `ClipDiagonalSide` (tail), `ClipDiagonalEnd`, `Negate24` |
| Reads | `$67A7`-`$67AD` (`WorldVars+4`); `$82FF`-`$8300` (`Im2Table+255`); `$AE85`-`$AE92` (`SegmentScratch+3`) |
| Writes | `$AE8C`-`$AE97` (`SegmentScratch+10`) |

### `ClipDiagonalSide` (`$B0E4`)

**Clip one side of a diagonal segment**

Part of ClipSegmentDiagonal `$B021`.

Witness: L1 594 (m2erbe, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 164 calls (`stage1/m2erbe` 164) |
| Called from | `ClipSegmentDiagonal` (tail) |
| Calls | `ClipDiagonalEnd` (tail) |
| Reads | `$67A7`-`$67AD` (`WorldVars+4`); `$82FF`-`$8300` (`Im2Table+255`); `$AE85`-`$AE8F` (`SegmentScratch+3`) |
| Writes | `$AE92`-`$AE97` (`SegmentScratch+16`) |

### `ClipDiagonalEnd` (`$B16A`)

**Clip the far end of a diagonal segment**

Part of ClipSegmentDiagonal `$B021`.

Witness: L1 2955 (m2erbe, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2,955 calls (`stage1/missions` 2,299, `stage1/m2erbe` 656) |
| Called from | `ClipSegmentDiagonal`, `ClipDiagonalSide` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `DrawSegmentTail` (`$B18A`)

**Continue the segment loop from the saved pointer `$AE9E`**

LD HL,(`$AE9E`) then JP DrawSegmentLoop `$AEE8`.

Witness: L1 6628 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,033 calls (`stage1/missions` 869, `stage1/m2erbe` 164) |
| Called from | `DrawSegmentStyle` (tail) |
| Calls | `DrawSegmentLoop` (tail) |
| Reads | `$AE9E`-`$AE9F` (`SegmentScratch+28`) |

### `TransformSegmentEnds` (`$B190`)

**Transform both corners of a segment into the vertex buffer `$FD00`**

Points the store `$B2F1` / `$B2F7` at `$FD00` / `$FD06`, transforms the first corner (TransformVertex `$B242`), copies the height `$AFC4` to `$B2E5`, then the second corner into `$FD02` / `$FD04`.

Witness: L1 6277 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 69,515 t-states own (0.01 %) |
| Runs (the other recordings) | 6,277 calls (`stage1/death` 3,878, `stage1/play` 891, `stage1/play2` 826 and 2 more) |
| Called from | `DrawSegments` (tail) |
| Calls | `RunScript`, `DrawSegmentLoop` (tail), `TransformVertex`, `ResetViewOrigin` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$AE9E`-`$AE9F` (`SegmentScratch+28`); `$AFC4` (`l_AF83+65`) |
| Writes | `$B2E5`-`$B2F8` (`StoreVertex+1`) |

### `DrawSegmentStyle` (`$B1B6`)

**Draw a segment by its style byte (+5)**

ResetViewOrigin `$B3B6`, then the style (the operand at `$B1BA`): 0 draws with IX = `$FF8C`, negative with `$FF80`, 1 with `$FF98`, 2 through `$B22C`, 4 / 5 / 6 set the `$FE00` constants first. The same byte is the terrain type TerrainCollision `$CC3C` returns in `$CE69`.

Witness: L1 6628 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 351 calls (`stage1/missions` 269, `stage1/m2erbe` 82) |
| Called from | `DrawSegments` (tail) |
| Calls | `RunScript`, `DrawSegmentTail` (tail), `ResetViewOrigin` |
| Reads | `$67AD`-`$67AE` (`WorldVars+10`); `$82FF`-`$8300` (`Im2Table+255`) |

### `TransformVertex` (`$B242`)

**Transform one map vertex to view space**

Input: the vertex index. Vertex minus camera (VertexRelative `$B265`), the rotation (`$B2FF`, `$B38E`), the stores through `$B2F1` / `$B2F7`.

Witness: L1 12554 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 476 calls, 86,666 t-states own (0.01 %) |
| Runs (the other recordings) | 12,554 calls (`stage1/death` 7,756, `stage1/play` 1,782, `stage1/play2` 1,652 and 2 more) |
| Called from | `TransformSegmentEnds` |
| Calls | `VertexRelative`, `StoreVertex` (tail), `RotateToView` |
| Reads | `$67A7`-`$67AB` (`WorldVars+4`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`) |

### `VertexRelative` (`$B265`)

**Vertex position minus the camera, 24-bit**

Byte * 1024 (ByteToWorld `$B282`) minus the camera X / Y `$67A8` / `$67AB`.

Witness: L1 25108 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 49,523 t-states own (0.01 %) |
| Runs (the other recordings) | 25,108 calls (`stage1/death` 15,512, `stage1/play` 3,564, `stage1/play2` 3,304 and 2 more) |
| Called from | `TransformVertex` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `Negate24` (`$B26F`)

**Negate a 24-bit value**

Seen only in missions (167 runs).

Witness: L1 167 (missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 167 calls (`stage1/missions` 167) |
| Called from | `ClipSegmentDiagonal` |
| Writes | `$B27C` (`Negate24+13`) |

### `VertexByteToWorld` (`$B27E`)

**A vertex byte to a 24-bit world coordinate (signed byte * 1024)**

Reads the vertex byte and falls into ByteToWorld `$B282`.

Witness: L1 1488 (m2erbe, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,488 calls (`stage1/missions` 1,160, `stage1/m2erbe` 328) |
| Called from | `ClipSegmentAxisY` |
| Calls | `ByteToWorld` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$DC00`-`$DC0C` (`MissionHeader+59`); `$DC40`-`$DC4C` (`MissionHeader+123`) |

### `ByteToWorld` (`$B282`)

**Signed byte to 24-bit: A * 1024 (vector `$67E2`)**

Input A, output the 24-bit value in A:HL. The mission code calls it through `$67E2` (the object list's X / Y words use the same scale).

Witness: L1 35297 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,932 calls, 142,457 t-states own (0.02 %) |
| Runs (the other recordings) | 35,297 calls (`stage1/death` 13,488, `stage1/play` 7,416, `stage1/missions` 6,801 and 2 more) |
| Called from | `ApiVector12` (tail), `VertexByteToWorld` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `ClipTestX` (`$B294`)

**Clip test of a view-space point against the window on X**

Carry out: outside.

Witness: L1 9467 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 357 calls, 35,105 t-states own (0.01 %) |
| Runs (the other recordings) | 9,467 calls (`stage1/death` 5,817, `stage1/play` 1,332, `stage1/play2` 1,239 and 2 more) |
| Called from | `DrawSegments` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$BC12` (`l_BBFB+23`); `$DC00`-`$DC17` (`MissionHeader+59`) |

### `ClipTestY` (`$B2BB`)

**Clip test of a view-space point on Y (depth)**

Carry out: outside.

Witness: L1 9364 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 357 calls, 37,623 t-states own (0.01 %) |
| Runs (the other recordings) | 9,364 calls (`stage1/death` 5,817, `stage1/play` 1,341, `stage1/play2` 1,239 and 2 more) |
| Called from | `DrawSegments` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$BC1D` (`l_BBFB+34`); `$DC40`-`$DC56` (`MissionHeader+123`) |

### `StoreVertex` (`$B2E4`)

**Store a transformed vertex through `$B2F1` / `$B2F7`**

The height operand `$B2E5` (from the segment's +3) is the vertex's height.

Witness: L1 13256 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 476 calls, 55,020 t-states own (0.01 %) |
| Runs (the other recordings) | 13,256 calls (`stage1/death` 7,756, `stage1/play` 1,782, `stage1/missions` 1,738 and 2 more) |
| Called from | `ClipSegmentAxisX` (tail), `TransformVertex` (tail) |
| Calls | `RotateVertex` |
| Reads | `$67A6`-`$67A7` (`WorldVars+3`); `$82FF`-`$8300` (`Im2Table+255`); `$AE84` (`SegmentScratch+2`) |
| Writes | `$AE84` (`SegmentScratch+2`) |

### `RotateVertex` (`$B2FF`)

**Rotate a camera-relative vertex by the view angle**

Through the camera sin / cos `$9A6C` / `$9A8E`.

Witness: L1 26512 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 35,262 t-states own (0.01 %) |
| Runs (the other recordings) | 26,512 calls (`stage1/death` 15,512, `stage1/play` 3,564, `stage1/missions` 3,476 and 2 more) |
| Called from | `StoreVertex` |
| Calls | `ApiVector14`, `SignExtendA`, `RotateAndStore` (tail), `RotateMulAdd` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$B1BA` (`DrawSegmentStyle+4`) |

### `SignExtendA` (`$B386`)

**Sign-extend A into HL (H = 0 or `$FF`)**

Seen only in missions.

Witness: L1 3624 (missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3,624 calls (`stage1/missions` 3,624) |
| Called from | `RotateVertex` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `RotateAndStore` (`$B38E`)

**Rotate by the sin / cos of A and store the pair**

EX AF,AF', sin / cos through `$67E8`, multiply by `$9A8E` (RotateMul `$B3A6`), clears the target.

Witness: L1 24700 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 952 calls, 112,374 t-states own (0.02 %) |
| Runs (the other recordings) | 24,700 calls (`stage1/death` 15,512, `stage1/play` 3,564, `stage1/play2` 3,304 and 2 more) |
| Called from | `RotateVertex` (tail) |
| Calls | `ApiVector14`, `RotateMul` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`) |
| Writes | `$FE00`-`$FE07` (`MissionHeader+8763`) |

### `RotateMul` (`$B3A6`)

**One product of the rotation (BC * the sin or cos)**

Part of RotateAndStore.

Witness: L1 49400 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1,904 calls, 148,588 t-states own (0.02 %) |
| Runs (the other recordings) | 49,400 calls (`stage1/death` 31,024, `stage1/play` 7,128, `stage1/play2` 6,608 and 2 more) |
| Called from | `RotateAndStore` |
| Calls | `RotateMulAdd` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$FD00`-`$FD07` (`MissionHeader+8507`); `$FF00`-`$FF07` (`data_FEBB+69`) |

### `RotateMulAdd` (`$B3AD`)

**The second product, added to the first**

Part of RotateAndStore.

Witness: L1 53024 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 6,952 calls (`stage1/missions` 6,952) |
| Called from | `RotateVertex` (tail), `RotateMul` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `ResetViewOrigin` (`$B3B6`)

**Reset the view origin before a segment is drawn**

Called by DrawSegmentStyle `$B1B6` once per drawn segment (6628 runs, as many as it).

Witness: L1 6628 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 24,731 t-states own (0.00 %) |
| Runs (the other recordings) | 6,628 calls (`stage1/death` 3,878, `stage1/play` 891, `stage1/missions` 869 and 2 more) |
| Called from | `TransformSegmentEnds`, `DrawSegmentStyle` |
| Calls | `ApiVector07` |
| Reads | `$67AD`-`$67AE` (`WorldVars+10`); `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$9AB3`-`$9AB4` (`l_9A9E+21`) |

### `SetCamera` (`$B9F6`)

**Set the camera from the viewed object (the player, a missile, the Dragonfly)**

Copies +`$21`..+`$28` (table select, heading, X, Y) of the record at (`$B9F4`) to `$67A5`-`$67AC`, the height +5/+6 (or the IR height `$B8FF` when `$BA13` is set) to `$67AD`. The rear view (`$BA27` set) adds `$80` to the heading. Then CameraSinCos `$BA32`.

Witness: L1 3550 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 41,463 t-states own (0.01 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `CameraSinCos` (tail) |
| Reads | `$67A5`-`$67A6` (`WorldVars+2`); `$75F5`-`$75F6` (`PlayerHeight`); `$7611`-`$7618` (`PlayerHandler+9`, `PlayerHeading`, `PlayerX`, `PlayerY`); `$7AA5`-`$7AA6` (`PlayerY+1167`); `$7AC1`-`$7AC8` (`PlayerY+1195`); `$82FF`-`$8300` (`Im2Table+255`); 2 more ranges |
| Writes | `$67A5`-`$67AE` (`WorldVars+2`) |

### `CameraSinCos` (`$BA32`)

**The camera heading's sine and cosine**

Reads the camera heading `$67A6`, sin / cos through `$67E8` (`$A899`), stores the pair in the operands `$BBBD` / `$BBC8` of RotateToView.

Witness: L1 7100 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 17,612 t-states own (0.00 %) |
| Runs (the other recordings) | 7,100 calls (`stage1/death` 5,020, `stage1/play2` 826, `stage1/missions` 614 and 2 more) |
| Called from | `SetCamera` (tail), `CameraSinCosAgain` (tail) |
| Calls | `ApiVector07`, `SinCosHalf` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |
| Writes | `$BBBD`-`$BBC8` (`RotateToView+1`) |

### `CameraSinCosAgain` (`$BA40`)

**CameraSinCos for the second pass**

CALL CameraSinCos for the second view pass.

Witness: L1 3550 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 3,399 t-states own (0.00 %) |
| Runs (the other recordings) | 3,550 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 307 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop`, `StatusLoop`, `DamageLoop` |
| Calls | `CameraSinCos` (tail) |
| Reads | `$67A5`-`$67A6` (`WorldVars+2`); `$82FF`-`$8300` (`Im2Table+255`) |

### `RearViewOff` (`$BA45`)

**Rear view off**

Clears `$BA27`, falls into ToggleRearView.

Witness: L1 5 (play).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/play` 5) |
| Called from | `PlayKeys` (tail) |
| Calls | `ToggleRearView` |
| Reads | `$BA27` (`l_BA1F+8`) |

### `ToggleRearView` (`$BA4A`)

**Rear view on or off: the flag `$BA27`, the text REAR:VIEW / :::**

Prints `$BA86` ("REAR:VIEW") or `$BA9F` (blank) with the attribute at `$5AD2`.

Witness: L1 31 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 69 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/missions` 16, `stage1/play` 9, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission`, `RearViewOff` |
| Calls | `PrintString` (tail) |
| Reads | `$CEA8` (`ToggleBinoculars+1`) |
| Writes | `$5AD2` (screen); `$BA27` (`l_BA1F+8`) |

### `GroundDots` (`$BAAC`)

**Draw the ground-plane dot grid**

The grid moves with the camera: GridVectors `$BB54`, then PlotGroundDot `$BB75` for each dot, GridStep `$BBA6` between rows.

Witness: L1 3507 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 119 calls, 1,324,405 t-states own (0.20 %) |
| Runs (the other recordings) | 3,507 calls (`stage1/death` 2,510, `stage1/play2` 413, `stage1/missions` 273 and 2 more) |
| Called from | `StartMission`, `PlayLoop`, `DragonflyViewLoop` |
| Calls | `NegHL`, `GridVectors`, `PlotGroundDot`, `GridStep`, `RotateToView` |
| Reads | `$67A7`-`$67AE` (`WorldVars+4`); `$82FF`-`$8300` (`Im2Table+255`); `$BB0B`-`$BB0F` (`l_BB0A+1`) |
| Writes | `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$BB0B`-`$BB0F` (`l_BB0A+1`); `$BB24`-`$BB4D` (`l_BB23+1`, `l_BB3E`); `$BB8B`-`$BB8C` (`PlotGroundDot+22`) |

### `GridVectors` (`$BB54`)

**The grid's step vectors for the camera heading**

The camera's sin / cos scaled to the grid spacing: the steps along a row and between rows.

Witness: L1 14028 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 476 calls, 77,668 t-states own (0.01 %) |
| Runs (the other recordings) | 14,028 calls (`stage1/death` 10,040, `stage1/play2` 1,652, `stage1/missions` 1,092 and 2 more) |
| Called from | `GroundDots` |
| Calls | `ApiVector14` |
| Reads | `$67A6` (`WorldVars+3`); `$82FF`-`$8300` (`Im2Table+255`) |

### `PlotGroundDot` (`$BB75`)

**Project one ground dot and plot it**

Rotates the dot to view space, divides by depth, plots through `$AA27` when on screen (117 517 runs).

Witness: L1 117517 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 4,638 calls, 567,501 t-states own (0.09 %) |
| Runs (the other recordings) | 117,517 calls (`stage1/death` 80,729, `stage1/play2` 16,501, `stage1/play` 10,267 and 2 more) |
| Called from | `GroundDots` |
| Calls | `Divide`, `DivideByLog`, `NegHL`, `PlotBackBuffer` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$9AA3`-`$9AA4` (`l_9A9E+5`); `$9ABB`-`$9ABC` (`l_9A9E+29`) |
| Writes | `$BBA2` (`PlotGroundDot+45`) |

### `GridStep` (`$BBA6`)

**Step to the next grid row**

Adds the row vector to the grid origin.

Witness: L1 7014 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 238 calls, 39,508 t-states own (0.01 %) |
| Runs (the other recordings) | 7,014 calls (`stage1/death` 5,020, `stage1/play2` 826, `stage1/missions` 546 and 2 more) |
| Called from | `GroundDots` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$BB0B`-`$BB0F` (`l_BB0A+1`) |
| Writes | `$BB0B`-`$BB0F` (`l_BB0A+1`) |

### `RotateToView` (`$BBBC`)

**Rotate dx, dy by the camera (sin `$BBBD`, cos `$BBC8`)**

Outputs the depth offset in `$9A6C` and the x offset in `$9A8E` (OpProject adds `$9A6C` to z and compares with 96).

Witness: L1 50296 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2,272 calls, 675,050 t-states own (0.10 %) |
| Runs (the other recordings) | 50,296 calls (`stage1/death` 29,081, `stage1/play2` 8,569, `stage1/play` 6,541 and 2 more) |
| Called from | `ClipSegmentAxisX`, `TransformVertex`, `GroundDots`, `TransformObjects` |
| Calls | `ApiVector09`, `NegHL` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`); `$9A6C`-`$9A6D` (`l_9A5E+14`); `$9A8E`-`$9A8F` (`l_9A85+9`); `$BBBD`-`$BBC8` (`RotateToView+1`) |
| Writes | `$BBDA`-`$BBDB` (`RotateToView+30`) |

### `TerrainCollision` (`$CC3C`)

**Does the object touch a visible segment; the style to `$CE69` (vector `$67F1`)**

Input IX = the object. Scans the segments flagged in `$8305` (TerrainScan `$CC4D`), tests the object's position against each one's box or diagonal (TerrainDiagonal `$CDB6`). Output carry set on a touch, the style +5 of the segment in `$CE69`. The mission code uses it through `$67F1` for the enemies.

Witness: L1 5854 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 381 calls, 850,642 t-states own (0.13 %) |
| Runs (the other recordings) | 5,854 calls (`stage1/death` 2,846, `stage1/play2` 1,264, `stage1/play` 842 and 2 more) |
| Called from | `ApiVector17` (tail) |
| Calls | `ApiVector12`, `TerrainScan`, `TerrainNegate24` |
| Reads | `$75F7`-`$7600` (`PlayerSpeed`); `$7613`-`$7618` (`PlayerX`, `PlayerY`); `$76AB` (`PlayerY+149`); `$775F`-`$77A4` (`PlayerY+329`); `$77B7`-`$77BC` (`PlayerY+417`); `$77D7`-`$77E0` (`PlayerY+449`); 16 more ranges |
| Writes | `$CCB2`-`$CCB9` (`l_CC98+26`); `$CCDF` (`l_CCD8+7`); `$CCFF` (`l_CCEB+20`); `$CD37`-`$CD3A` (`l_CD30+7`); `$CD4E`-`$CD72` (`l_CD30+30`, `l_CD5C`); `$CD86`-`$CD98` (`l_CD5C+42`, `l_CD94`); 1 more ranges |

### `TerrainScan` (`$CC4D`)

**The scan over the visible segments**

Sets the segment pointer and the count.

Witness: L1 62957 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12,396 calls (`stage1/missions` 9,920, `stage1/m2erbe` 2,476) |
| Called from | `TerrainCollision`, `TerrainScanLoop` (tail) |
| Calls | `ApiVector12`, `TerrainScanLoop`, `TerrainNext` (tail), `TerrainNegate24`, `TerrainDiagonal` (tail) |
| Reads | `$75FB`-`$7600` (`PlayerSpeed+4`); `$7613`-`$7618` (`PlayerX`, `PlayerY`); `$76AF`-`$76B0` (`PlayerY+153`); `$76C7`-`$76C9` (`PlayerY+177`); `$7763`-`$77F8` (`PlayerY+333`); `$7817`-`$781C` (`PlayerY+513`); 13 more ranges |
| Writes | `$CCB2`-`$CCB9` (`l_CC98+26`); `$CCDF` (`l_CCD8+7`); `$CCFF` (`l_CCEB+20`); `$CD37`-`$CD3A` (`l_CD30+7`); `$CD4E`-`$CD72` (`l_CD30+30`, `l_CD5C`); `$CD86`-`$CD98` (`l_CD5C+42`, `l_CD94`); 1 more ranges |

### `TerrainScanLoop` (`$CC51`)

**The scan loop**

One segment per pass (62 693 runs).

Witness: L1 62693 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12,310 calls (`stage1/missions` 9,844, `stage1/m2erbe` 2,466) |
| Called from | `TerrainScan`, `TerrainNext` (tail) |
| Calls | `TerrainScan` (tail) |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `TerrainNext` (`$CDA2`)

**Continue with the next segment**

Steps to the next record.

Witness: L1 11717 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2,837 calls (`stage1/missions` 2,127, `stage1/m2erbe` 710) |
| Called from | `TerrainScan` (tail), `TerrainDiagonal` (tail) |
| Calls | `TerrainScanLoop` (tail) |

### `TerrainNegate24` (`$CDA6`)

**Negate a 24-bit difference**

Negates the 24-bit value in A:HL.

Witness: L1 14955 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 749 calls, 55,426 t-states own (0.01 %) |
| Runs (the other recordings) | 14,955 calls (`stage1/death` 6,721, `stage1/play` 3,256, `stage1/play2` 2,765 and 2 more) |
| Called from | `TerrainCollision`, `TerrainScan`, `TerrainDiagonal` |
| Reads | `$82FF`-`$8300` (`Im2Table+255`) |

### `TerrainDiagonal` (`$CDB6`)

**Distance to a diagonal segment**

The perpendicular distance for orientation other than 0 / `$80` (missions, m2erbe).

Witness: L1 908 (m2erbe, missions).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 908 calls (`stage1/missions` 474, `stage1/m2erbe` 434) |
| Called from | `TerrainScan` (tail) |
| Calls | `ApiVector08`, `ApiVector12`, `TerrainNext` (tail), `TerrainNegate24` |
| Reads | `$7613`-`$7618` (`PlayerX`, `PlayerY`); `$76C7`-`$76CC` (`PlayerY+177`); `$77B7`-`$77F8` (`PlayerY+417`); `$782F`-`$7834` (`PlayerY+537`); `$786B`-`$7870` (`PlayerY+597`); `$78A7`-`$78AC` (`PlayerY+657`); 5 more ranges |
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
| Calls | `SetBinoculars` |

### `SetBinoculars` (`$CEAB`)

**Apply the binoculars flag: the zoom `$9A93`, the lamp, the key repeat, the text**

On: `$CEA8` = A, the zoom `$9A93` = 1, the lamp attribute `$5ACC` = `$42`, key repeat `$9719` = `$20`, prints "BINOC:X2" `$BA93`. Off: `$9A93` = 0, `$5ACC` = `$44`, `$9719` = 4, the blank `$BA9F`. The rear view (`$BA27`) blocks both.

Witness: L1 34 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 1 call, 119 t-states own (0.00 %) |
| Runs (the other recordings) | 34 calls (`stage1/missions` 16, `stage1/play` 12, `stage1/play2` 3 and 2 more) |
| Called from | `StartMission`, `ToggleBinoculars` |
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

Witness: L1 1 (death).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/death` 1) |
| Called from | `CollisionPass` |
| Calls | `ApiVector05`, `ApiVector11`, `AddKillScore` (tail), `HitPoints` |
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

Witness: L1 153 (death, missions, play2).

[Animation: `HitTest` at work](img/routines/HitTest.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 153 calls (`stage1/missions` 146, `stage1/death` 6, `stage1/play2` 1) |
| Called from | `ApiVector10` (tail) |
| Calls | `ApiVector05`, `ApiVector11`, `KillMissionObject` (tail), `HitPoints` |
| Reads | `$766B` (`PlayerY+85`); `$76A4`-`$76A7` (`PlayerY+142`); `$76E3` (`PlayerY+205`); `$771C` (`PlayerY+262`); `$7797` (`PlayerY+385`); `$77D0` (`PlayerY+442`); 3 more ranges |

### `KillMissionObject` (`$B67D`)

**A killed mission object: mark it in the list, leave the wreck**

MarkDestroyed `$B6BD`, sets the wreck bit 6 of +2 (the wreck model +8/+9 is drawn), clears the step handler bit.

Witness: L1 4 (death).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/death` 4) |
| Called from | `HitTest` (tail) |
| Calls | `ApiVector13`, `AddKillScore` |
| Reads | `$76A6`-`$76A7` (`PlayerY+144`); `$771E`-`$771F` (`PlayerY+264`); `$77D2`-`$77D3` (`PlayerY+444`); `$78C2`-`$78C3` (`PlayerY+684`) |
| Writes | `$76A6`-`$76A7` (`PlayerY+144`); `$771E`-`$771F` (`PlayerY+264`); `$77D2`-`$77D3` (`PlayerY+444`); `$78C2`-`$78C3` (`PlayerY+684`) |

### `AddKillScore` (`$B692`)

**Add the object's score (+`$1E`/+`$1F`) to the 32-bit score `$68E2`**

Adds the word to `$68E2`-`$68E5` and calls the kill sound `$D873`. Death: the score goes 0, `$FA`, `$1F4` (two kills of a 250-point type).

Witness: L1 5 (death).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/death` 5) |
| Called from | `KillTree` (tail), `KillMissionObject` |
| Calls | `SoundKill` |
| Reads | `$68E2`-`$68E5` (`MissionScore`); `$76C2`-`$76C3` (`PlayerY+172`); `$773A`-`$773B` (`PlayerY+292`); `$77EE`-`$77EF` (`PlayerY+472`); `$78DE`-`$78DF` (`PlayerY+712`); `$7956`-`$7957` (`PlayerY+832`) |
| Writes | `$68E2`-`$68E5` (`MissionScore`) |

### `HitPoints` (`$B6B1`)

**Subtract the hitter's damage from the hit points; carry = killed**

+`$13` of IX -= +`$14` of IY.

Witness: L1 7 (death).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7 calls (`stage1/death` 7) |
| Called from | `KillTree`, `HitTest` |
| Reads | `$767C` (`PlayerY+102`); `$76B7`-`$76B8` (`PlayerY+161`); `$76F4` (`PlayerY+222`); `$772F` (`PlayerY+281`); `$77A8` (`PlayerY+402`); `$77E3` (`PlayerY+461`); 4 more ranges |
| Writes | `$76B7` (`PlayerY+161`); `$772F` (`PlayerY+281`); `$77E3` (`PlayerY+461`); `$78D3` (`PlayerY+701`); `$794B` (`PlayerY+821`) |

### `MarkDestroyed` (`$B6BD`)

**Mark a mission object destroyed in the list (vector `$67E5`)**

Record (`$DBDA`) + 8 * (+0): sets bit 1 (destroyed), clears bit 7 (alive), so it is never spawned again. The goal hooks read this bit.

Witness: L1 4 (death).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4 calls (`stage1/death` 4) |
| Called from | `ApiVector13` (tail) |
| Reads | `$76A4` (`PlayerY+142`); `$771C` (`PlayerY+262`); `$77D0` (`PlayerY+442`); `$78C0` (`PlayerY+682`); `$DBDA`-`$DBDB` (`MissionHeader+21`); `$DD8C`-`$DDA4` (`MissionHeader+455`) |
| Writes | `$DD8C`-`$DDA4` (`MissionHeader+455`) |

### `Debris` (`$B6D1`)

**Throw 8 debris particles from the object (vector `$67DF`)**

Fills the bank 3 particle list at `$CFEC` (8 records of 20 bytes): the object's position, random velocities (DebrisVelocity `$B74B` / `$B75C`).

Witness: L1 13 (death, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/death` 12, `stage1/play2` 1) |
| Called from | `ApiVector11` (tail) |
| Calls | `ApiVector06`, `PageBank3`, `SaveBank`, `RestoreBank` (tail), `DebrisVelocity`, `DebrisVelocityB` |
| Reads | `$766A`-`$76E2` (`PlayerY+84`); `$771E`-`$7726` (`PlayerY+264`); `$7796` (`PlayerY+384`); `$77D2` (`PlayerY+444`); `$7886`-`$788E` (`PlayerY+624`); `$78A7`-`$78AC` (`PlayerY+657`); 6 more ranges |

### `DebrisVelocity` (`$B74B`)

**A random velocity component for a particle**

Random through `$67D0`.

Witness: L1 64 (death, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 64 calls (`stage1/death` 48, `stage1/play2` 16) |
| Called from | `Debris` |
| Calls | `ApiVector06` |

### `DebrisVelocityB` (`$B75C`)

**The second component (shares the code)**

The entry DebrisVelocity's second call uses for the other axis.

Witness: L1 64 (death, play2).

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

Witness: L1 65529 (death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).

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

Witness: L1 1449 (death, play2).

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

Witness: L1 30 (m2erbe, menu, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 2 calls, 3,962 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/missions` 16, `stage1/play2` 6, `stage1/menu` 4 and 2 more) |
| Called from | `Bank0SoundOff`, `QuitKey` |
| Writes | `$D674`-`$D689` (`AYRegs`, `SelectCount`, `ExplosionCount`, `KillCount` and 5 more); `$D7F0` (`l_D7E2+14`) |
| Ports out | `$BFFD`, `$FFFD` |

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

Witness: L1 21 (play2).

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

Witness: L1 14 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14 calls (`stage1/play2` 9, `stage1/play` 4, `stage1/death` 1) |
| Called from | `SelectWeapon` |
| Writes | `$D682` (`SelectCount`) |

### `SoundExplosion` (`$D86B`)

**Explosion sound**

`$D683` = `$20`: an explosion.

Witness frames (first-last frame of the recording, runs): c1 32618-33054 (5), death 8121-17902 (8), play2 8607-17180 (19).

Witness: L1 27 (death, play2).

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

Witness: L1 5 (death).

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

Witness: L1 70 (death, play, play2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 70 calls (`stage1/death` 60, `stage1/play2` 6, `stage1/play` 4) |
| Called from | `ConsumeAmmo` |
| Writes | `$D686` (`FireSoundCount`) |

### `EngineTone` (`$D8A1`)

**Engine tone from the speed**

|speed| through `$67D6` gives the tone period of channel A in the shadow (17 682 runs).

Witness frames (first-last frame of the recording, runs): c1 32219-33298 (982), death 7592-20038 (10012), m2erbe 7090-7522 (281), missions 7592-34068 (2195), play 8253-10693 (2004), play2 8184-23533 (3190).

Witness: L1 17682 (death, m2erbe, missions, play, play2).

| | |
| --- | --- |
| Runs (c1 from the game's entry at frame 23974, the loader left out: the title, the mission tape, Blast Em Mission played) | 982 calls, 227,299 t-states own (0.03 %) |
| Runs (the other recordings) | 17,682 calls (`stage1/death` 10,012, `stage1/play2` 3,190, `stage1/missions` 2,195 and 2 more) |
| Called from | `SoundFrame` |
| Calls | `ApiVector08` |
| Reads | `$75F7` (`PlayerSpeed`); `$D67B`-`$D67F` (`AYRegs+7`) |
| Writes | `$D674`-`$D681` (`AYRegs`); `$D7F0` (`l_D7E2+14`) |
