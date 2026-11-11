# 11. Data reference

Every data entry of the game image `$5B00`-`$FFA7`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/d1`, `work/f1`, `work/w1`, local and not in the repository), and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## lowdata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B00` | `ScannerSave` | 624 | The scanner's background: 48 pixel lines of 13 bytes, `$5049-$5055` on of the screen's bottom third. ScannerCopy `$990C` copies 13 bytes a line, 8 lines a row, 6 rows between the screen (`$5049`, the scanner ellipse of the dashboard) and here. ScannerSaveMode `$98A2` patches it to save the screen here (EX DE,HL, PUSH HL / POP HL in place of NOP, PUSH DE / POP DE), ScannerClear `$98CD` back to restore it every frame (f1: 554 runs). DashboardSave `$817E` also copies the dashboard's attributes (`$5A00-$5AFF`) to `$5B00`, and DashboardRestore `$8042` copies them back. The image's bytes are what the last copy left: attribute bytes (`$07`, `$17`) in the first page, then the mastering machine's system variables (03 3.10) to `$5D6F`. | `DashboardRestore`, `ScannerCopy` | `DashboardSave`, `ScannerCopy` |
| `$5D70` | `Font` | 728 | The character set: 91 glyphs of 8 bytes for the codes `$20-$7A`, read by PrintChar `$D499`. Codes `$20-$7A`, 8 bytes a glyph top line first. Most are ASCII letters, digits and signs; the codes `$21-$26`, `$2B` and `$3B-$3E` (! " # and so on) are the dashboard's frame pieces (slants, corners, bars), drawn by the same printer. | `PlotChar`, `PrintChar` | - |
| `$6048` | `ShipSlots` | 273 | The 8 ship slots, 39 bytes each: the objects in space. Eight records of `$27` bytes from `$6048` (slot n at `$6048` + 39 n), read and written by every ship routine (UpdateShips `$9CBB` walks them). The record: +`$00-$08` the position x, y, z (3 bytes each, sign in bit 7 of the top byte), +`$09-$1A` the orientation vectors, +`$1B` the speed, +`$20` / +`$21` the flags, +`$22` the energy, +`$23` / +`$24` the blueprint address, +`$25` / +`$26` the AI state (07-objects.md). The image's bytes are leftovers of a BASIC program in the developer's memory (" ***---", "3000"), overwritten when a game starts. | `ActionThargoids`, `AwayPart`, `ClearShips`, `Collide`, `CombineParts` +46 | `ActionThargoids`, `ClearShips`, `CombineParts`, `CreateAtOrigin`, `CreateShip` +27 |
| `$6159` | `Slot7` | 39 | Slot 7, the last of the eight: the player's missile in flight, the turning ship on the title. The code names it directly (TurnTitleShip, ActionTitleShip, the hostility test of UpdateSlot); it is no work copy: the ship routines work on each slot in place | `ActionTitleShip`, `CreateShip`, `DotProduct`, `DrawScanner`, `DrawShip` +14 | `ActionTitleShip`, `ClearShips`, `CreateShip`, `MoveAlongAxis`, `OrthogonalisePart` +4 |
| `$6180` | `Blueprints` | 76 | The blueprint table: 19 entries of `$C3`, the blueprint address and its class. CreateShip `$B898` reads entry A AND `$3F` (HL = `$6180` + 4 A + 1): the word is the blueprint. The first byte of each is `$C3` (a JP opcode; nothing jumps here). The last byte is the class the spawn code picks ships by: 0 the station and the missile, 1 debris (pod, plate, canister, splinter, asteroid), 2 traders (rock hermit, Viper, the trader Cobra and Python), 3 pirates and Thargoids, 4 the Sidewinder, Krait and Thargon (07-objects.md). | `CreateShip` | - |
| `$61CC` | `ShipAsp` | 23 | blueprint 13: the header (19 vertices, 28 edges, 12 faces) | `CreateShip`, `DrawEdges`, `DrawShip`, `FaceVisibility`, `ProjectVertices` +1 | - |
| `$61E3` | `ShipAspVertices` | 114 | the 19 vertices of blueprint 13 | `Project`, `ProjectVertex`, `RotateVertexScaled` | - |
| `$6255` | `ShipAspEdges` | 112 | the 28 edges of blueprint 13 | `DrawEdges` | - |
| `$62C5` | `ShipAspFaces` | 48 | the 12 faces of blueprint 13 | `FaceVisibility`, `RotateNormal` | - |
| `$62F5` | `ShipRockHermit` | 23 | blueprint 7: the header (9 vertices, 21 edges, 14 faces) | - | - |
| `$630C` | `ShipAsteroid` | 23 | blueprint 6: the header (9 vertices, 21 edges, 14 faces) | - | - |
| `$6323` | `ShipAsteroidVertices` | 54 | the 9 vertices of blueprint 6 | - | - |
| `$6359` | `ShipAsteroidEdges` | 84 | the 21 edges of blueprint 6 | - | - |
| `$63AD` | `ShipAsteroidFaces` | 56 | the 14 faces of blueprint 6 | - | - |
| `$63E5` | `ShipCanister` | 23 | blueprint 4: the header (10 vertices, 15 edges, 7 faces) | `CreateShip`, `DrawEdges`, `DrawShip`, `FaceVisibility`, `ProjectVertices` +1 | - |
| `$63FC` | `ShipCanisterVertices` | 60 | the 10 vertices of blueprint 4 | `Project`, `ProjectVertex`, `RotateVertexScaled` | - |
| `$6438` | `ShipCanisterEdges` | 60 | the 15 edges of blueprint 4 | `DrawEdges` | - |
| `$6474` | `ShipCanisterFaces` | 28 | the 7 faces of blueprint 4 | `FaceVisibility`, `RotateNormal` | - |
| `$6490` | `ShipCobraTrader` | 23 | blueprint 9: the header (28 vertices, 38 edges, 13 faces) | `DrawEdges`, `DrawShip`, `FaceVisibility`, `ProjectVertices`, `RotateNormal` | - |
| `$64A7` | `ShipCobraPirate` | 23 | blueprint 12: the header (28 vertices, 38 edges, 13 faces) | `RotateNormal`, `RotateVertexScaled` | - |
| `$64BE` | `ShipCobraVertices` | 168 | the 28 vertices of both Cobra blueprints | `Project`, `ProjectVertex`, `RotateNormal`, `RotateVertexReuse`, `RotateVertexScaled` +1 | - |
| `$6566` | `ShipCobraEdges` | 152 | the 38 edges of both Cobra blueprints | `DrawEdges` | - |
| `$65FE` | `ShipCobraFaces` | 52 | the 13 faces of both Cobra blueprints | `FaceVisibility`, `RotateNormal` | - |
| `$6632` | `ShipEscapePod` | 23 | blueprint 2: the header (4 vertices, 6 edges, 4 faces) | - | - |
| `$6649` | `ShipEscapePodVertices` | 24 | the 4 vertices of blueprint 2 | - | - |
| `$6661` | `ShipEscapePodEdges` | 24 | the 6 edges of blueprint 2 | - | - |
| `$6679` | `ShipEscapePodFaces` | 16 | the 4 faces of blueprint 2 | - | - |
| `$6689` | `ShipFerDeLance` | 23 | blueprint 14: the header (19 vertices, 27 edges, 10 faces) | - | - |
| `$66A0` | `ShipFerDeLanceVertices` | 114 | the 19 vertices of blueprint 14 | - | - |
| `$6712` | `ShipFerDeLanceEdges` | 108 | the 27 edges of blueprint 14 | - | - |
| `$677E` | `ShipFerDeLanceFaces` | 40 | the 10 faces of blueprint 14 | - | - |
| `$67A6` | `ShipMissile` | 23 | blueprint 1: the header (17 vertices, 24 edges, 9 faces) | - | - |
| `$67BD` | `ShipMissileVertices` | 102 | the 17 vertices of blueprint 1 | - | - |
| `$6823` | `ShipMissileEdges` | 96 | the 24 edges of blueprint 1 | - | - |
| `$6883` | `ShipMissileFaces` | 36 | the 9 faces of blueprint 1 | - | - |
| `$68A7` | `ShipPlate` | 23 | blueprint 3: the header (4 vertices, 4 edges, 0 faces) | `CreateShip`, `DrawEdges`, `DrawShip`, `FaceVisibility`, `ProjectVertices` +1 | - |
| `$68BE` | `ShipPlateVertices` | 24 | the 4 vertices of blueprint 3 | `Project`, `ProjectVertex`, `RotateVertexScaled` | - |
| `$68D6` | `ShipPlateEdges` | 16 | the 4 edges of blueprint 3 | `DrawEdges` | - |
| `$68E6` | `ShipPythonTrader` | 23 | blueprint 10: the header (11 vertices, 26 edges, 13 faces) | `CreateShip`, `DrawEdges`, `DrawShip`, `FaceVisibility`, `ProjectVertices` | - |
| `$68FD` | `ShipPythonPirate` | 23 | blueprint 11: the header (11 vertices, 26 edges, 13 faces) | `RotateVertexSmall` | - |
| `$6914` | `ShipPythonVertices` | 66 | the 11 vertices of both Python blueprints | `Project`, `ProjectVertex`, `RotateNormal`, `RotateVertexScaled`, `RotateVertexSmall` | - |
| `$6956` | `ShipPythonEdges` | 104 | the 26 edges of both Python blueprints | `DrawEdges` | - |
| `$69BE` | `ShipPythonFaces` | 52 | the 13 faces of both Python blueprints | `FaceVisibility`, `RotateNormal` | - |
| `$69F2` | `ShipSidewinder` | 23 | blueprint 16: the header (10 vertices, 15 edges, 7 faces) | - | - |
| `$6A09` | `ShipSidewinderVertices` | 60 | the 10 vertices of blueprint 16 | - | - |
| `$6A45` | `ShipSidewinderEdges` | 60 | the 15 edges of blueprint 16 | - | - |
| `$6A81` | `ShipSidewinderFaces` | 28 | the 7 faces of blueprint 16 | - | - |
| `$6A9D` | `ShipCoriolis` | 23 | blueprint 0: the header (16 vertices, 28 edges, 14 faces) | `Collide`, `DrawShip` | - |
| `$6AB4` | `ShipCoriolisVertices` | 96 | the 16 vertices of blueprint 0 | - | - |
| `$6B14` | `ShipCoriolisEdges` | 112 | the 28 edges of blueprint 0 | - | - |
| `$6B84` | `ShipCoriolisFaces` | 56 | the 14 faces of blueprint 0 | - | - |
| `$6BBC` | `ShipSplinter` | 23 | blueprint 5: the header (4 vertices, 6 edges, 4 faces) | - | - |
| `$6BD3` | `ShipSplinterVertices` | 24 | the 4 vertices of blueprint 5 | - | - |
| `$6BEB` | `ShipSplinterEdges` | 24 | the 6 edges of blueprint 5 | - | - |
| `$6C03` | `ShipSplinterFaces` | 16 | the 4 faces of blueprint 5 | - | - |
| `$6C13` | `ShipThargoid` | 23 | blueprint 15: the header (20 vertices, 26 edges, 10 faces) | `Collide`, `CreateShip`, `DrawEdges`, `DrawShip`, `FaceVisibility` +5 | - |
| `$6C2A` | `ShipThargoidVertices` | 120 | the 20 vertices of blueprint 15 | `Project`, `ProjectVertex`, `RotateNormal`, `RotateVertexReuse`, `RotateVertexScaled` +1 | - |
| `$6CA2` | `ShipThargoidEdges` | 104 | the 26 edges of blueprint 15 | `DrawEdges` | - |
| `$6D0A` | `ShipThargoidFaces` | 40 | the 10 faces of blueprint 15 | `FaceVisibility`, `RotateNormal` | - |
| `$6D32` | `ShipKrait` | 23 | blueprint 17: the header (17 vertices, 21 edges, 6 faces) | - | - |
| `$6D49` | `ShipKraitVertices` | 102 | the 17 vertices of blueprint 17 | - | - |
| `$6DAF` | `ShipKraitEdges` | 84 | the 21 edges of blueprint 17 | - | - |
| `$6E03` | `ShipKraitFaces` | 24 | the 6 faces of blueprint 17 | - | - |
| `$6E1B` | `ShipViper` | 23 | blueprint 8: the header (15 vertices, 20 edges, 7 faces) | - | - |
| `$6E32` | `ShipViperVertices` | 90 | the 15 vertices of blueprint 8 | - | - |
| `$6E8C` | `ShipViperEdges` | 80 | the 20 edges of blueprint 8 | - | - |
| `$6EDC` | `ShipViperFaces` | 28 | the 7 faces of blueprint 8 | - | - |
| `$6EF8` | `ShipThargon` | 23 | blueprint 18: the header (10 vertices, 15 edges, 7 faces) | - | - |
| `$6F0F` | `ShipThargonVertices` | 60 | the 10 vertices of blueprint 18 | - | - |
| `$6F4B` | `ShipThargonEdges` | 60 | the 15 edges of blueprint 18 | - | - |
| `$6F87` | `ShipThargonFaces` | 28 | the 7 faces of blueprint 18 | - | - |
| `$6FA3` | `BlueprintsSpare` | 79 | 79 zeros after the last blueprint | - | - |

## startup

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6FFB` | `ChartIcons` | 32 | The four sizes of a system's dot on the local chart, 8x8 each. DrawChartIcon `$ED27` picks one (DE = `$6FFB` + 8 n) and ORs it onto the chart. | `DrawSystemIcon` | - |
| `$701B` | `Commodities` | 68 | The 17 commodities: 4 bytes each, the market generator's table. MakeMarket `$E148` (d1: the Lave market) reads the 68 bytes from `$701B`: the base price, the economy factor (bit 7 its sign) with the unit in its top bits, the base quantity and the fluctuation mask (10-gameplay-logic.md). Firearms is entry 11: ZeroFirearms `$B7AC` zeroes its price when the special cargo mission needs it. | `MakeMarket` | `Gunsight`, `ClearFirearmPrices` (code) |
| `$705F` | `EquipmentPrices` | 42 | The prices of the equipment the Equip screen sells. Read by EquipShip `$E973` through EquipPricePtr `$EB2F` (t1 bought a missile at frame 1474: EquipShip 1 run). The fuel price at `$7060` is written by the hyperspace code (`$DC66`, `$DCAA`). | - | `JumpTick`, `EquipFuel` (code), `GalaxyJumpNext` (code), `JumpHyperspace` (code) |
| `$70DE` | `FillSP` | 2 | FillAttrs' saved stack pointer | `FillAttrs`, `FillAttrsPush` (code) | `FillAttrs`, `FillAttrsNow` (code) |
| `$70E3` | `ViewIndex` | 1 | The view: 0-3 the space views (front, rear, left, right), 4 and up the screens. SelectView `$80D3` sets it from the keys; below 4 the flight loop draws space, from 4 a status, market or chart screen is up (7 and 8 the charts: ChartCursorKeys `$71F3`). | `ChartCursorKeys`, `ConditionLight`, `DashboardTick`, `DrawCompass`, `DrawShip` +22 | `JumpEnd`, `JumpKeys`, `JumpTick`, `SceneLaunch`, `SetView` +7 |
| `$70E4` | `RollRate` | 1 | The roll rate this frame (bit 7 the sign), copied from the high byte of RollControl (`$FF09`) | `MovePosition`, `Stardust`, `UpdateShip`, `StardustPass` (code) | `CopyRates`, `SceneDock` (code) |
| `$70E5` | `PitchRate` | 1 | The pitch rate this frame, from the high byte of PitchControl (`$FF0B`) | `MovePosition`, `Stardust`, `UpdateShip`, `StardustPass` (code) | `CopyRates`, `SceneDock` (code) |
| `$70E6` | `SpeedRate` | 1 | The speed this frame, from the high byte of SpeedControl (`$FF0D`) | `MovePosition`, `Stardust`, `ActionMissileShip` (code), `ActionPod` (code), `CollideStationCrash` (code) +1 | `CopyRates`, `TitleNext`, `TunnelFrame`, `TunnelFrameText`, `GameOver` (code) +3 |
| `$70E7` | `BarDrawn` | 28 | The dashboard bars: 13 pairs of the length last drawn and the value, the fore shield first. DrawBars `$84D9` compares each value with the byte before it and draws only a changed bar; a value is 0-`$A0`, a quarter of it the length in pixels. The first 11 are solid bars (the shields, the fuel, the cabin and laser temperatures, the altitude, the speed, the four energy banks), the last two the roll and pitch markers. ResetDashboard `$9946` starts the shields, the altitude and the banks at `$A0`. | `ConditionLight`, `DashboardTick`, `DrainBanks`, `DrawBars`, `LaserCooling` +7 | `CopyRates`, `DashboardTick`, `DrainBanks`, `DrawBars`, `JumpEnd` +9 |
| `$70E8` | `BarForeShield` (`BarDrawn`+1) | 2 | The fore shield | `ConditionLight`, `DrawBars`, `ShieldGain`, `ShieldHit` | `DrawBars`, `ResetFlight`, `ShieldGain`, `ShieldHit` |
| `$70EA` | `BarAftShield` (`BarDrawn`+3) | 2 | The aft shield | `ConditionLight`, `DrawBars`, `ShieldGain`, `ShieldHit` | `DrawBars`, `ResetFlight`, `ShieldHit` |
| `$70EC` | `BarFuel` (`BarDrawn`+5) | 2 | The fuel | `DrawBars` | `SetFuel` |
| `$70EE` | `BarCabinTemp` (`BarDrawn`+7) | 2 | The cabin temperature (zero at a reset) | `DrawBars` | `DrawBars`, `JumpEnd`, `JumpTick`, `ResetFlight`, `DashDistancesSetSunNear` (code) |
| `$70F0` | `BarLaserTemp` (`BarDrawn`+9) | 2 | The laser temperature | `DrawBars`, `LaserCooling` | `DrawBars`, `LaserCooling`, `ResetFlight` |
| `$70F2` | `BarAltitude` (`BarDrawn`+11) | 2 | The altitude above the planet | `DrawBars` | `DrawBars`, `JumpEnd`, `JumpTick`, `ResetFlight`, `DashPlanet` (code) |
| `$70F4` | `BarSpeed` (`BarDrawn`+13) | 2 | The speed: SpeedRate * 5 + 5 | `DrawBars` | `CopyRates`, `DrawBars` |
| `$70F6` | `BarEnergy1` (`BarDrawn`+15) | 2 | Energy bank 1 | `DashboardTick`, `DrainBanks`, `DrawBars`, `Recharge` | `DashboardTick`, `DrainBanks`, `DrawBars`, `Recharge`, `ResetFlight` |
| `$70F8` | `BarEnergy2` (`BarDrawn`+17) | 2 | Energy bank 2 | `DrainBanks`, `DrawBars`, `Recharge` | `DrainBanks`, `DrawBars`, `Recharge`, `ResetFlight` |
| `$70FA` | `BarEnergy3` (`BarDrawn`+19) | 2 | Energy bank 3 | `DrainBanks`, `DrawBars`, `Recharge`, `CloakKey` (code) | `DrainBanks`, `DrawBars`, `Recharge`, `ResetFlight` |
| `$70FC` | `BarEnergy4` (`BarDrawn`+21) | 2 | Energy bank 4 | `DashboardTick`, `DrainBanks`, `DrawBars`, `MessageTick`, `Recharge` +2 | `DrainBanks`, `DrawBars`, `Recharge`, `ResetFlight` |
| `$70FE` | `BarRoll` (`BarDrawn`+23) | 2 | The roll marker: `$15` +/- the roll rate | `DrawBars` | `CopyRates`, `DrawBars` |
| `$7100` | `BarPitch` (`BarDrawn`+25) | 3 | The pitch marker: `$15` +/- the pitch rate | `DrawBars` | `CopyRates` |
| `$7103` | `WitchSpace` | 1 | Non-zero in witch space after a misjump (the hyperspace arrival, JumpArrive): no sun, no planet, no station, four stars, Thargoids | `MarketPrices`, `SceneLaunch`, `Stardust`, `TitleLoad`, `TitleNext` +6 | `JumpTick`, `TitleLoad`, `TitleNext`, `JumpArrive` (code), `JumpWitch` (code) |
| `$7104` | `Condition` | 1 | The condition light as an attribute: 0 docked, 4 green, 6 yellow, 2 red, `$63` red flashing. ConditionLight `$99A4` writes it to the dashboard's attributes (`$5A28`, `$5A48`) every frame and sets 4 again for the next: the distance code makes it 6 near the planet or the sun and `$63` very near (`$82D7`), a shield at zero makes it 2, and `$63` alternates between 0 and 2 (ConditionFlash `$99A3`). | `ConditionLight`, `ConditionYellow`, `DashboardTick`, `JumpKeys`, `SceneLaunch` +8 | `ConditionGreen`, `ConditionLight`, `ConditionYellow`, `DashboardTick`, `SceneLaunch` +4 |
| `$7105` | `StarSeed` | 2 | The stardust generator's seed (StarRandom `$7E86`) | `DamageItem`, `JumpTick`, `NewMarket`, `StarRespawn`, `TunnelFrame` +4 | `StarRespawnFront`, `StarRespawnMake` |
| `$7107` | `SunPosition` | 9 | The sun's position: x, y, z, 3 bytes each (sign in bit 7 of the top byte). DashDistances `$81A9` turns its distance into the cabin temperature (BarCabinTemp) and TooClose; DrawSunPlanet `$7584` draws it first, as a filled circle. | `CombineParts`, `DashDistances`, `DrawSunPlanet`, `MovePosition`, `SceneLaunch` | `CombineParts`, `JumpTick`, `MovePosition`, `NewGame`, `SceneLaunch` +1 |
| `$7110` | `PlanetPosition` | 9 | The planet's position: x, y, z. DashDistances turns its distance into the altitude (BarAltitude, `$A0` - distance) and the safe zone (SafeZone, all three coordinates below `$0200`). | `CombineParts`, `CompassDivideScale`, `CompassDivideSigned`, `DashDistances`, `DrawSunPlanet` +7 | `CombineParts`, `JumpTick`, `MovePosition`, `SceneLaunch`, `ZeroBytes` +1 |
| `$711C` | `SafeZone` | 1 | Non-zero inside the space station's safe zone: the planet's three coordinates below `$0200` | `DrawIndicators`, `UpdateShips`, `DockKeysComputer` (code) | `DashDistances`, `JumpTick`, `DashCompassFar` (code), `JumpWitch` (code) |
| `$711D` | `StationLaunch` | 1 | Non-zero while slot 0, the station, flies in after a launch | `DashDistances`, `StationRunIn`, `InSystemJump` (code) | `JumpTick`, `SceneLaunch`, `JumpArriveLoop` (code), `StationRunIn` (code), `StationRunInMove` (code) |
| `$711E` | `SunNear` | 1 | Non-zero when the sun's distance is below `$2000` (DashDistances `$81EC`) | `MessageTick`, `MessagePeriodic` (code) | `JumpEnd`, `JumpTick`, `TitleLoad`, `TitleNext`, `DashDistancesSetSunNear` (code) |
| `$711F` | `TooClose` | 1 | Non-zero when the ship has hit the planet or the sun | `Collide`, `Gunsight`, `TitleLoad`, `TitleNext`, `FlightLoopEnd` (code) | `DrainBanks`, `TitleNext`, `CollideTooHard` (code), `GameOverWait` (code), `SetTooClose` (code) +1 |
| `$7120` | `SunLarge` | 1 | Non-zero when the sun's circle radius is `$28` or more (DrawSunPlanet `$75A8`) | `UpdateShips` | `DrawSunPlanet`, `TitleNext`, `GameOver` (code) |
| `$7124` | `HoldRates` | 1 | Non-zero: FlightLoop keeps the control rates of the frame before | `TitleLoad`, `TitleNext`, `FlightLoop` (code) | `SceneLaunch`, `TitleNext`, `GameOver` (code), `GameOverWait` (code) |
| `$7128` | `SoundRequests` | 1 | The sound requests: one bit a sound, set by the game, served by SoundTick | `LaserCooling`, `ShipsWreck`, `SoundEnd`, `SoundPulsesNow`, `SoundTick` +7 | `LaserCooling`, `ShipsWreck`, `SoundEnd`, `SoundLaunch`, `SoundPlay` +9 |
| `$7129` | `AutoDocked` | 1 | 1 when the docking computer docked the ship (DockKeys `$71AE`) | `MessageTick`, `MessagePeriodic` (code) | `ResetFlight`, `DockKeysComputer` (code) |
| `$7221` | `CloakKeyCount` | 1 | Counts the frames down to the next look at the cloak key (every second frame) | `CloakKey` | `CloakKey` |
| `$72A2` | `ControlMethod` | 1 | The control method chosen on the title: 1 Kempston (left on port `$1F`, bit 5 clear), 2 Cursor (5 held), 3 Sinclair (6 held) | `OptionKeyboard` (code), `OptionKeyboardSwap` (code) | `TitleMethod` (code) |
| `$7470` | `TitleShipCount` | 1 | The title ship counter: the next title ship's blueprint | `TitleLoad`, `TitleNext` | `TitleLoad`, `TitleNext` |

## flightloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7578` | `TitleSP` | 2 | The stack pointer the title was entered with (the game overs take it back: PirateStation) | `BackToTitleMessage` (code) | `Title` (code) |
| `$757A` | `CircleVector` | 9 | The position DrawSunPlanet projects: x, y, z, 3 bytes each | `ProjectCircle` | `DrawSunPlanet`, `ProjectCircle` |
| `$7583` | `LastSunRadius` | 1 | The sun's radius the frame before (SunGrowth) | `SunGrowth` (code) | `TitleLoad`, `TitleNext`, `TunnelDone`, `SunGrowthStore` (code) |

## stardust

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7E8D` | `StarDots` | 80 | The 16 dots: X (bit 7 the sign), Y (bit 7 the sign), the depth, the X fraction, the Y fraction | `Stardust`, `StardustNext`, `StardustPassGetStarView` (code) | `StarPlot`, `StarRespawnFront`, `StarRespawnMake`, `StarRollPitch` |
| `$7EDD` | `StarWarp` | 1 | 1: the next Stardust draws the jump's two fast passes | `Stardust` | `InSystemJumpSetStarWarp` (code), `Stardust` (code) |
| `$7F6F` | `StarRoll` | 1 | The roll rate for the dots (bit 7 moved to StarSigns) | `StarPlot`, `StarRollPitch`, `Stardust`, `StardustFront`, `StardustNextGetStarRoll` (code) +1 | `Stardust`, `StardustNextGetStarRoll` (code), `StardustPass` (code), `StardustPassSetStarY` (code) |
| `$7F70` | `StarPitch` | 1 | The pitch rate for the dots | `StarRespawn`, `StarRollPitch`, `Stardust`, `StarRespawnGetStarPitch` (code), `StarRespawnIfNotZero3` (code) +2 | `Stardust`, `StardustNextGetStarRoll` (code), `StardustPass` (code), `StardustPassGetStarPitch` (code) |
| `$7F71` | `StarRollWork` | 1 | StarRollWork | `StarRollPitch` | `StarRollPitch` |
| `$7F72` | `StarFlags` | 1 | StarFlags | `StardustNext` | `Stardust`, `StardustNextIfNotZero` (code), `StardustPass` (code) |
| `$7F73` | `StarPointer` | 2 | The dot being moved | `StarPlot`, `StarRespawn`, `StarRollPitch`, `StardustNext` | `StarPlot`, `StarRespawnFront`, `StarRespawnMake`, `StarRollPitch`, `Stardust` +1 |
| `$7F75` | `StarSpeed` | 1 | The speed for the dots: SpeedRate / 2 + 1 | `StardustFront`, `StardustNextGetStarDepth` (code) | `Stardust`, `StardustPass` (code) |
| `$7F76` | `StarXFrac` | 1 | StarXFrac | `StarPlot`, `StarRollPitch`, `StardustFront` | `Stardust`, `StardustFront`, `StardustNext`, `StardustPassSetStarY` (code) |
| `$7F77` | `StarX` | 1 | StarX | `StarAddress`, `StarPlot`, `StarRollPitch`, `StardustFront`, `StardustNextGetStarX` (code) +1 | `StarRollPitch`, `Stardust`, `StardustFront`, `StardustNext`, `StardustPassSetStarX` (code) |
| `$7F78` | `StarYFrac` | 1 | StarYFrac | `StarPlot`, `StarRollPitch`, `StardustFront` | `Stardust`, `StardustFront`, `StardustNext`, `StardustPassSetStarY` (code) |
| `$7F79` | `StarY` | 1 | StarY | `StarAddress`, `StarPlot`, `StarRollPitch`, `StardustFront`, `StarRollScaleGetStarY` (code) | `StarRollPitch`, `Stardust`, `StardustFront`, `StardustNext`, `StarRollScaleSetStarY` (code) +1 |
| `$7F7A` | `StarDepth` | 1 | StarDepth | `StarPlot`, `StarRollPitch`, `StardustFront`, `StardustNextGetStarDepth` (code) | `StarRollPitch`, `Stardust`, `StardustFront`, `StardustNext`, `StardustPassSetStarY` (code) |
| `$7F7B` | `StarView` | 1 | The view the dots were made for | `Stardust`, `StardustPassGetStarView` (code) | `Stardust`, `StardustPassGetStarView` (code) |
| `$7F7C` | `StarCount` | 1 | Dots left in this pass | `StardustNext`, `StarShuffle` (code) | `Stardust`, `StardustNext`, `StardustPass` (code) |
| `$7F7D` | `StarListPointer` | 2 | The next free entry of StarList | `StarPlot`, `StarRollPitch` | `StarPlot`, `StarRollPitch`, `Stardust`, `StardustPassGetStarView` (code) |
| `$7F7F` | `StarSigns` | 1 | Bit 7 X negative, bit 6 Y negative, bit 5 the rear view, bits 4 and 3 the roll and pitch signs | `NegateX`, `NegateY`, `StarAddress`, `StarPlot`, `StarRespawn` +6 | `NegateX`, `NegateY`, `StarRollPitch`, `Stardust`, `StardustNext` +1 |
| `$7F80` | `StarListCount` | 1 | The number of dots StarList holds (0 at the start of each pass) | `StarPlot`, `StarPlotAll`, `StarRollPitch` | `StarPlot`, `StarRollPitch`, `Stardust`, `StardustPass` (code) |
| `$7F81` | `JumpToggle` | 1 | Rotated by every J jump: every second one may bring a ship | `InSystemJump` (code), `StarRespawnGetJumpToggle` (code), `StarRespawnIfNotZero5` (code) | `InSystemJump` (code), `StarRespawnGetJumpToggle` (code), `StarRespawnIfNotZero5` (code) |
| `$7F82` | `StarList` | 60 | The dots of this pass: the back buffer address and the mask of each, 16 of 3 bytes | `StarPlotAll` | `StarPlot`, `StarRollPitch` |

## backbuffer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$80D1` | `ClearViewSP` | 2 | ClearView's and CallScreen's saved stack pointer | `CallScreen`, `ClearView`, `CallScreenCall` (code) | `CallScreen`, `ClearView` |

## dashboard

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$81A3` | `DashWork` | 6 | DashDistances' results: SunClose, PlanetClose, the compass x and y offsets, the compass behind flag | `DrawCompass`, `InSystemJump` (code) | `DashDistances`, `DashCompassPlanetXY` (code), `DashCompassSide` (code), `DashCompassStore` (code) |
| `$81A4` | `SunClose` (`DashWork`+1) | 1 | 1 when the sun's coordinates are all below `$0100` (its distance was measured) | `InSystemJump` (code) | `DashDistances` |
| `$81A5` | `PlanetClose` (`DashWork`+2) | 1 | 1 when the planet's are all below `$0200` | `InSystemJump` (code) | `DashDistances` |
| `$81A6` | `CompassX` (`DashWork`+3) | 1 | The compass dot's x offset (bit 7 the sign) | `DrawCompass` | `DashDistances`, `DashCompassPlanetXY` (code) |
| `$81A7` | `CompassY` (`DashWork`+4) | 1 | The compass dot's y offset | `DrawCompass` | `DashDistances`, `DashCompassStore` (code) |
| `$81A8` | `CompassBehind` (`DashWork`+5) | 1 | 1 when the target is behind (z negative): the hollow dot | `DrawCompass` | `DashDistances`, `DashCompassSide` (code) |
| `$8477` | `CompassAddress` | 2 | The screen address of the dot's top line | `DrawCompass` | `DrawCompass` |
| `$8479` | `CompassDot` | 8 | The dot being drawn: 4 lines of 2 bytes, shifted into place | `DrawCompass` | `DrawCompass` |
| `$8481` | `CompassDotFront` | 8 | The dot for a target in front (4 lines of 2 bytes) | `DrawCompass` | - |
| `$8489` | `CompassDotBehind` | 8 | The dot for a target behind | `DrawCompass` | - |
| `$8491` | `CompassDial` | 72 | The compass dial: 24 lines of 3 bytes | `DrawCompassDialArt` | - |
| `$8523` | `BarMarkerMode` | 1 | 1 while the two markers are drawn | `BarByte`, `DrawBarRows` | `DrawBars` |
| `$8524` | `BarAddresses` | 28 | The screen address of each bar's top line: 6 on the left, the speed, the 4 banks, the roll and the pitch | `DrawBarRows` | - |

## circles

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8619` | `CircleZero` | 1 | One byte no code reads (known from the code only) | - | - |
| `$861A` | `CircleY` | 1 | The centre's offset from the view's centre, down or up by CircleQuadrant bit 1 | `DrawCircleShape` | `DrawChartCircle`, `ProjectCircle`, `TunnelFrame`, `TunnelFrameText`, `HitFlashSlot` (code) |
| `$861B` | `CircleX` | 1 | The centre's offset across, by bit 0 | `DrawCircleShape` | `DrawChartCircle`, `ProjectCircle`, `TunnelFrame`, `TunnelFrameText`, `HitFlashSlot` (code) |
| `$861C` | `CircleQuadrant` | 1 | Bit 0 x positive (right), bit 1 y positive (up), bits 2 and 3 the centre off the view across or down | `CircleArc`, `DrawCircleShape`, `FillClipped`, `FillCorner`, `ArcSeed` (code) +2 | `DrawChartCircle`, `ProjectCircle`, `TunnelFrame`, `TunnelFrameText`, `HitFlashSlot` (code) |
| `$861D` | `CircleRadius` | 1 | The radius in pixels (9 and more drawn) | `CircleArc`, `DrawCircle`, `DrawCircleShape`, `FillCorner`, `ArcSeed` (code) +6 | `DrawChartCircle`, `ProjectCircleStore`, `TunnelFrame`, `TunnelFrameText`, `HitFlashGrow` (code) +2 |
| `$861E` | `CircleRowOffset` | 1 | DrawCircleShape's working copy of CircleY, clipped to the edge it meets | `SpanStep`, `ArcSeed` (code) | `DrawCircleShape` |
| `$861F` | `CircleColOffset` | 1 | Its copy of CircleX | `SpanStep`, `ArcSeed` (code) | `DrawCircleShape`, `FillClippedOtherTop` (code), `FillClippedTop` (code), `FillSidesOtherTop` (code), `FillSidesTop` (code) |
| `$8620` | `CircleScreenY` | 1 | The centre's row: 64 - or + CircleY | `CircleArc`, `FillClipped`, `FillCorner`, `SpanEndLeft` (code), `SpanEndRight` (code) | `DrawCircleShape`, `FillCorner` |
| `$8621` | `CircleScreenX` | 1 | The centre's column: 128 + or - CircleX | `CircleArc`, `FillCorner` | `DrawCircleShape` |
| `$8622` | `ClipHalfWidth` | 1 | The half width of the circle at the clipping row (HalfChord) | `FillClipped`, `FillCorner`, `SpanStep` | `FillClipped`, `FillCorner` |
| `$8623` | `CircleSP` | 2 | The stack pointer saved while the fills PUSH and the chart patches POP | `CircleAbort`, `DrawChartCircle`, `OutlinePixels`, `FillPushes1` (code), `FillPushes1Loop3` (code) +11 | `DrawChartCircle`, `OutlinePlotSide`, `OutlinePlotTop`, `FillRunDown` (code), `FillRunUp` (code) +4 |
| `$8625` | `HalfChordTarget` | 2 | HalfChord's radius² - row² | `HalfChord` | `HalfChord` |
| `$8627` | `CirclePointX` | 1 | PointRight's x | `MaskLeft`, `PointRightLoop` (code) | `PointRight` |
| `$8628` | `RunRight` | 1 | 1 while the run being plotted grows x (the right half), 0 while it shrinks x; the fills read it to pick the edge test | `OutlinePixel`, `OutlinePixels`, `OutlinePlotSide`, `OutlinePlotTop`, `FillPushes1` (code) +8 | `ArcRunLeft`, `ArcRunRight`, `OutlineRunUpLeft`, `OutlineRunUpRight`, `OutlineRunDownLeft` (code) +1 |
| `$8629` | `CircleMode` | 1 | 0 a filled circle (the sun), 1 an outline (the planet) | `ArcRunLeft`, `ArcRunRight`, `OutlineEdgeDown`, `OutlineEdgeUp`, `OutlineRunUpLeft` +10 | `DrawCircleOutline`, `DrawCircleDI` (code) |
| `$862A` | `ChartPatchCount` | 1 | The 32 bytes DrawChartCircle patches and puts back | `DrawChartCircle` | - |
| `$8E8D` | `ChartPatch` | 32 | The 32 code bytes for the chart screens | `DrawChartCircle` | - |
| `$8EAD` | `ViewPatch` | 32 | The 32 code bytes for the 3D view | `DrawChartCircle` | - |
| `$8ECD` | `CirclePatchSites` | 64 | The 32 code addresses DrawChartCircle patches | - | - |
| `$8FB4` | `CircleSpare` | 2 | Two zeros | - | - |
| `$8FB6` | `FillWord` | 2 | `$FFFF`: AF for the PUSH chains | - | - |
| `$928B` | `CircleUnused` | 1 | One unused byte | - | - |

## tunnel

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$93D0` | `TunnelRingCount` | 1 | The number of rings (16 for the jump, 8 for the launch and the dock) | `TunnelFrame`, `TunnelFrameText` | `SceneLaunch`, `TunnelStart` |
| `$93D1` | `TunnelRingsLeft` | 1 | TunnelRingsLeft | `TunnelFrame`, `TunnelFrameText` | `TunnelFrame`, `TunnelFrameText` |
| `$93D2` | `TunnelTop` | 1 | The frames left | `TunnelFrame`, `TunnelFrameText`, `TunnelCount` (code) | `SceneLaunch`, `TunnelFrame`, `TunnelFrameText`, `TunnelStart`, `TunnelCount` (code) |
| `$93D3` | `TunnelRings` | 16 | The 16 ring distances of the jump tunnel, 2.5 apart | `TunnelFrame` | `TunnelFrame` |
| `$93E3` | `LaunchRings` | 10 | The 8 ring distances of the launch and dock tunnel, and two spare bytes | `TunnelFrame`, `TunnelFrameText` | `TunnelFrame`, `TunnelFrameText` |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9522` | `SoundMode` | 1 | The generator playing: 0 none, 1 sweep, 2 noise, 3 pulses; bit 7 a second phase | `SoundLaunch`, `SoundPlay`, `SoundPulsesNow`, `SoundTick` | `SoundArmHit`, `SoundArmLaser`, `SoundArmLaunch`, `SoundArmScene`, `SoundArmTwoPhase` +6 |
| `$9523` | `SoundPitch` | 2 | E: the passes left, D: the pitch (the delay count) | `SoundPulses`, `SoundSweep`, `SoundNoise` (code) | `SoundPassEnd`, `SoundPulsesNow`, `SoundSecond`, `SoundSweepNow` |
| `$9525` | `SoundSource` | 2 | The pulse and noise generators read their levels from this address (the ROM) | `SoundPulses`, `SoundNoise` (code) | `SoundPassEnd`, `SoundPulsesNow`, `SoundSecond`, `SoundSweepNow` |
| `$96BF` | `SoundBit` | 6 | The request bit playing; five spare bytes | `DrawScanner`, `ScannerRestore`, `SoundEnd`, `SoundPulsesNow` | `DrawScanner`, `ScannerRestore`, `SoundTick` |

## scanner

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9945` | `ScannerSpare` | 1 | ScannerSpare | - | - |
| `$99A3` | `ConditionFlash` | 1 | The flashing's counter: bit 1 picks red or black | `ConditionLight` | `ConditionLight` |
| `$9ADA` | `HitCount` | 1 | The hits that went through the shields, +5 each, cooling by one a frame | `ShieldHit` | `ShieldHit` |
| `$9B62` | `IndicatorCodes` | 18 | The bar letters (`$26`, `$24`) and the indicators: E on, E off, S on, S off (frame pieces when off) | `PrintNext` | - |
| `$9C1B` | `MissileLaunchFlag` | 1 | Cleared by ResetFlight; used by the next routine | `EscapePod` | `ResetFlight`, `EscapePodKey` (code) |

## shipmotion

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9C7B` | `EscapePodSpare` | 5 | EscapePodSpare | - | - |
| `$9C92` | `ShipVarSpare` | 1 | ShipVarSpare | - | - |
| `$9C93` | `JumpEncounter` | 1 | Counts down every pass (UpdateShips); at 0 (every 256 passes) a new ship may come (SpawnShip) | `LaserCooling`, `UpdateShips`, `UpdateSlot` | `UpdateShips`, `InSystemJump` (code) |
| `$9C94` | `ShipsAbout` | 1 | Non-zero while a ship that is not passive is about (refuses the in-system jump) | `UpdateSlotNext`, `InSystemJump` (code) | `UpdateShips`, `UpdateSlot` |
| `$9C95` | `BombKill` | 1 | Set by the energy bomb: UpdateShips destroys every ship but the station and Thargoids' motherships | `UpdateSlot` | `UpdateSlotNext`, `EnergyBomb` (code) |
| `$9C96` | `ShipsPresent` | 1 | Non-zero while any slot is in use (the scanner is drawn) | `DrawScanner`, `HitFlash` | `UpdateShips`, `UpdateSlot` |
| `$9C97` | `SightTarget` | 1 | The slot in the gunsight (the missile's lock) | `LaserCooling`, `MissileKeys` (code) | `DrawShip`, `UpdateShips` |
| `$9C98` | `ShipVarSpare2` | 1 | ShipVarSpare2 | - | - |
| `$9C99` | `AllHostile` | 1 | Set when a protected ship turns hostile: every ship turns hostile while it (or the player's missile, slot 7) is about | `UpdateSlot` | `ClearShips`, `UpdateSlotNext`, `CloakKey` (code), `UpdateSlotAngry` (code) |
| `$9C9A` | `Docked` | 1 | Non-zero while docked | `DockKeys` | `SceneLaunch`, `CollideStation` (code), `DockKeys` (code) |
| `$9C9B` | `ECMActive` | 1 | Non-zero while an ECM is on (the E indicator) | `DrawIndicators`, `Gunsight`, `Tactics`, `MissileHoming` (code) | `ResetFlight`, `GunsightECMKey` (code), `GunsightECMOff` (code), `SceneDock` (code), `TacticsECMOn` (code) |
| `$9CA2` | `EnergyDrain` | 1 | The energy taken from the banks this frame | `DashboardTick`, `LaserCooling`, `DamageShields` (code), `GunsightECMOn` (code) | `LaserCooling`, `UpdateShips`, `GunsightECMOn` (code) |
| `$9CA3` | `FrontHits` | 1 | The hits on the front shield this frame | `DashboardTick`, `TacticsAim`, `CollideShipFront` (code), `CollideStationCrash` (code), `DamageShields` (code) | `TacticsAim`, `UpdateShips`, `CollideShipFront` (code), `CollideStationCrash` (code) |
| `$9CA4` | `AftHits` | 1 | The hits on the aft shield this frame | `DashboardTick`, `TacticsAim`, `CollideShipSound` (code), `DamageShields` (code) | `TacticsAim`, `UpdateShips`, `CollideShipSound` (code) |
| `$9CAE` | `NonStationPresent` | 1 | Non-zero while a ship other than the station is about (the condition yellow) | `ConditionYellow` | `UpdateShips`, `UpdateSlot` |
| `$9CB2` | `MissionShip` | 1 | The cloak ship (an Asp, role bit 6, MissionFlags bit 1): 0 none, 1 about and cloaked (DrawShip draws only its laser), 2 hurt below `$34` and seen, 3 destroyed with its canister out (scooped: the cloaking device) | `DrawShip`, `SpawnShip`, `Tactics`, `CollideScoopMission` (code), `CollideShip` (code) +2 | `JumpEnd`, `JumpTick`, `CollideScoopMission` (code), `CollideShip` (code), `InSystemJump` (code) +3 |
| `$9CB3` | `ActiveShips` | 1 | The ships in slots 1-6 with tactics on | `UpdateShips`, `TacticsStation` (code) | `UpdateShips` |
| `$9CB4` | `ShipLoopCount` | 1 | UpdateShips's slot counter (8 down to 1) | `RemoveShip` | `UpdateSlot` |
| `$9F80` | `TurnRates` | 2 | The roll (low) and pitch (high) of the ship being turned | `TurnAxis`, `TurnOwn` | `MoveShip`, `TurnTitleShip`, `UpdateShip` |

## tactics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A28B` | `RateSpare` | 2 | Two zero bytes no code reads (known from the code only) | - | - |
| `$A2B8` | `TargetVector` | 8 | The vector to the target (three words), its length after Normalise (`$A2BE`) | `DivideComponent`, `DotProduct`, `SquareComponent`, `TacticsAim`, `MissileSeekLoop` (code) | `DivideComponent`, `Tactics`, `TacticsAim`, `MissileSeekLoop` (code), `TacticsSteerAway` (code) +1 |
| `$A6DE` | `DotProductSpare` | 1 | DotProductSpare | `ExplosionPoint` (code) | `DrawShip` |

## drawships

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A8FA` | `ProjectedPoints` | 138 | The screen points of the vertices: x, y and the quadrant (`$FF` hidden), 3 bytes each | `PointOf` | `ProjectAdd` |
| `$A984` | `FaceVisible` | 16 | One byte per face: non-zero visible (FaceVisibility) | `FaceIsVisible` | `FaceVisibility` |
| `$A994` | `ViewMatrix` | 36 | The ship's axes in the view's order: three rows of three sign and magnitude words, then the vertex's rotated parts (+`$12`-+`$17`) | `MultiplyScaled`, `RotateNormal`, `RotateVertexReuse`, `RotateVertexScaled` | `RotateNormal`, `RotateVertexReuse`, `RotateVertexScaled`, `ViewMatrixSetup` |
| `$A9B8` | `ShipDistance` | 1 | The depth's high byte (then the detail level) | `DrawEdges`, `DrawShip`, `FaceVisibility`, `Project`, `ProjectVertex` +1 | `DrawShip`, `DrawWireframeDetail` (code) |
| `$A9B9` | `ShipDistanceHigh` | 1 | ShipDistanceHigh | `DrawShip`, `DrawWireframe` (code) | `DrawShip` |
| `$A9BA` | `PointOffset` | 1 | The current vertex's offset into ProjectedPoints | `ProjectAdd`, `ProjectVertex` | `DrawShip`, `ProjectVertex`, `DrawWireframeDetail` (code) |
| `$A9BB` | `VertexX` | 2 | The rotated vertex plus the ship's position | `ProjectAdd` | `Project`, `ProjectAdd`, `RotateVertexSmall` |
| `$A9BD` | `VertexY` | 2 | VertexY | `ProjectAdd` | `Project`, `ProjectAdd`, `RotateVertexSmall` |
| `$A9BF` | `VertexZ` | 2 | VertexZ | `ProjectAdd` | `Project`, `ProjectAdd`, `RotateVertexSmall` |
| `$A9C1` | `ScreenX` | 1 | The ship's or the vertex's screen point and quadrant | `DrawShip`, `ProjectAdd`, `DrawLaserOnly` (code), `ExplosionPoint` (code) | `DrawShip`, `ProjectAdd` |
| `$A9C2` | `ScreenY` | 1 | ScreenY | `DrawShip`, `ProjectAdd`, `DrawLaserOnly` (code), `ExplosionPoint` (code) | `DrawShip`, `ProjectAdd` |
| `$A9C3` | `ScreenQuadrant` | 1 | ScreenQuadrant | `DrawShip`, `ProjectAdd`, `DrawLaserOnly` (code), `ExplosionPoint` (code) | `DrawShip`, `ProjectAdd` |
| `$A9C4` | `VertexSignX` | 1 | VertexSignX | `ProjectAdd` | `ProjectAdd` |
| `$A9C5` | `VertexSignY` | 1 | VertexSignY | `ProjectAdd` | `ProjectAdd` |
| `$A9C6` | `VertexSignZ` | 1 | VertexSignZ | `ProjectAdd` | `ProjectAdd` |
| `$A9C7` | `VertexScale` | 1 | The shift that keeps the vertex's parts in 8 bits | `MultiplyScaled`, `RotateVertexScaled` | `Project` |
| `$A9C8` | `VertexCached` | 1 | Zero when the vertex repeats the last one's magnitudes: the products are reused | `RotateVertexScaled`, `RotateVertexSmall` | `ProjectAdd`, `ProjectVertex` |
| `$AC9F` | `VertexHigh` | 3 | The rotated vertex's top bytes | `ProjectAdd` | `Project`, `ProjectAdd`, `RotateVertexSmall` |
| `$AFF0` | `LineSteps` | 80 | DrawLine's step table: per octant the screen moves | `DrawLine` | - |

## linedraw

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B040` | `ClipSave` | 2 | ClipLine's saved outcodes and slope | `ClipLine` | `ClipLine` |
| `$B042` | `ClipSlope` | 2 | ClipSlope | `ClipLine` | `ClipLine` |
| `$B4D5` | `LinesSpare` | 1 | LinesSpare | - | - |
| `$B4D6` | `LaserBeam` | 1 | LaserBeam | `LaserBeams` | `LaserBeams` |

## combat

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B4D7` | `LaserFired` | 1 | The laser fired last frame (LaserCooling); B4D6 the beam's random bits | `LaserCooling` | `LaserCooling` |
| `$B7AA` | `RandomSeed` | 2 | RandomSeed | `Random` | `Random` |
| `$B83D` | `ShipTemplateSpare` | 1 | ShipTemplateSpare | - | - |
| `$B83E` | `ShipTemplate` | 31 | The first 31 bytes of every new ship: the position `$3200` on each axis, the unit axes, zeros | `CreateShip` | - |
| `$B85D` | `TitleShipAxes` | 9 | The title ship's nine axis high bytes | `ActionTitleShip` | - |
| `$B866` | `FlipToggle` | 1 | FlipShip's two ways, in turn | `FlipShip` (code) | `FlipShip` (code) |
| `$BCC8` | `FaceBlueprint` | 2 | FaceVisibility's work: the blueprint, the normals' scale, the rotated normal and its signs | `FaceVisibility` | `FaceVisibility` |
| `$BCCA` | `FaceScale` | 1 | FaceScale | `NormalPart` | `FaceVisibility` |
| `$BCCB` | `FaceNormal` | 6 | FaceNormal | `FaceDot` | `FaceVisibility` |
| `$BCD1` | `FaceSigns` | 3 | FaceSigns | `FaceDot` | `FaceVisibility` |

## squaretable

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BE00` | `SquaresLow` | 256 | n² AND `$FF` for n = 0-255 (Square, Multiply8, VectorLength, SquareRoot). c1 reads the table back as n² for every n at frame 18018; f1, w1 and d1 read it in every multiplication. | `Multiply8`, `Square`, `SquareComponent` | - |
| `$BF00` | `SquaresHigh` | 256 | n² / 256 for n = 0-255 | `Multiply8`, `Multiply8High`, `Square`, `SquareComponent`, `TidyAxis` | - |
| `$C000` | `BackBuffer` | 4096 | The 3D view's back buffer (`$C000-$CFFF`, the layout of `$4000-$4FFF`): ClearView clears it, the lines and the circles draw into it, CopyBackBuffer copies it to the screen; docked, its last bytes are the screens' stack (CallScreen sets SP to `$D000`) | `CopyThirdLine`, `DashboardRestore`, `LineDownX`, `LineDownY`, `LineUpX` +8 | `DashboardSave`, `IM2Entry`, `LineDownX`, `LineDownY`, `LineUpX` +8 |

## gamestate

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D03F` | `TunnelOn` | 1 | A launch or dock tunnel is running | `ChartCursorKeys`, `JumpTick`, `SetView`, `TunnelFrameText`, `DockKeysComputer` (code) | `JumpKeys`, `SceneLaunch`, `TunnelFrame`, `TunnelFrameText`, `TunnelEnd` (code) +1 |
| `$D040` | `TunnelLoop` | 1 | The tunnel's frames run inside one call; the views are locked meanwhile | `SelectView`, `TunnelFrame`, `TunnelFrameText`, `TunnelStart` | `JumpEnd`, `JumpTick`, `SceneLaunch`, `TunnelFrame`, `TunnelFrameText` +3 |
| `$D041` | `CloakOn` | 1 | Non-zero while the cloaking device is on (CloakKey): the view tinted blue, the energy drain one more; ENERGY LOW turns it off | `CloakRestore`, `DashboardTick`, `FillAttrs`, `Tactics`, `CloakKey` (code) +1 | `MessageTick`, `SceneLaunch`, `TitleLoad`, `TitleNext`, `CloakKey` (code) +1 |
| `$D045` | `TextColumn` | 1 | The print position: the column and the row | `PlotChar`, `PrintChar`, `DeleteCharColumn` (code), `MessageDestroyed` (code), `SaveCursor` (code) | `ColumnZero`, `DrawFrame`, `DrawIndicators`, `DrawMissiles`, `JumpTick` +22 |
| `$D046` | `TextRow` | 1 | TextRow | `LabelSystem`, `NewLine`, `PlotChar`, `PrintChar`, `PrintIfRowFree` +3 | `DrawFrame`, `DrawIndicators`, `DrawMissiles`, `JumpTick`, `LabelSystem` +17 |
| `$D047` | `MissileState` | 1 | 0 off, 1 armed, 2 locked | `ConditionLight`, `MissileKeys`, `RemoveShip` | `JumpEnd`, `JumpTick`, `ResetFlight`, `MissileKeys` (code), `RemoveShipNext` (code) |
| `$D04B` | `PrintTarget` | 2 | The address of the printer's plot byte (`$D548`): `$A9` (XOR C) mixes a glyph into the screen, `$00` (NOP) writes it over (the dashboard's indicators) | `DrawIndicators`, `DrawMissiles`, `ConditionText` (code), `ConditionTextCells` (code) | - |
| `$D04D` | `PrintSpare` | 1 | PrintSpare | - | - |
| `$D051` | `CrossX` | 1 | The chart's crosshair: x, y and the circle's radius | `DrawChartCircle`, `DrawCross`, `DrawCrossEnd` | `ChartCross`, `GalacticChart`, `ShortRangeChart`, `BuyCargo` (code) |
| `$D052` | `CrossY` | 1 | CrossY | `DrawChartCircle`, `DrawCross`, `DrawCrossEnd` | `ChartCross`, `GalacticChart`, `ShortRangeChart`, `BuyCargo` (code) |
| `$D053` | `ChartRadius` | 1 | ChartRadius | `DrawChartCircle` | `GalacticChart`, `ShortRangeChart`, `BuyCargo` (code) |
| `$D054` | `CommanderName` | 11 | The commander record: the name, 10 letters and a zero | `PrintCodes` | `NewGame` |
| `$D05F` | `LegalStatus` | 1 | 0 clean, up to 49 an offender, 50 or more a fugitive; bit 6 set by a protected kill | `JumpTick`, `StatusScreen`, `AddCargoLegal` (code), `JumpHyperspace` (code), `UpdateSlotFree` (code) | `JumpTick`, `NewGame`, `EscapePodKey` (code), `GalaxyJumpNext` (code), `JumpHyperspace` (code) +1 |
| `$D060` | `CombatScore` | 3 | The combat score (the rating): the low byte, then two | `StatusScreen`, `TacticsAim`, `AddCargoSpecial` (code), `AddCombat` (code), `MissionDone` (code) +3 | `NewGame`, `AddCargoSpecial` (code), `AddCombat` (code), `MissionDone` (code), `SellCargo` (code) |
| `$D063` | `CommanderRest` | 8 | The jumps, the galaxy, the cash and the price fluctuation | `ControlGalaxy`, `JumpTick`, `MakeMarket`, `PrintCash`, `AddCredits` (code) +10 | `NewGame`, `NewMarket`, `AddCredits` (code), `AddThousands` (code), `GalaxyJumpNext` (code) +6 |
| `$D06B` | `CargoHold` | 17 | The tons (or kg, g) of each commodity | `SpawnShip` | `NewGame`, `SellCargo` (code) |
| `$D07C` | `FreeSpace` | 1 | The hold's free space in tons | `AddCargo` (code), `BuyCheckPay` (code), `CollideInside` (code), `DamageItemCargo` (code), `EquipCargoBay` (code) +2 | `NewGame`, `AddCargo` (code), `BuyCargo` (code), `DamageItemCargo` (code), `EquipCargoBay` (code) +3 |
| `$D07D` | `LaserMounts` | 4 | The laser of each view: 0 none, 1 pulse, 2 beam, 3 military, 4 mining | `Gunsight`, `LaserCooling`, `PrintLaser` | `NewGame` |
| `$D081` | `NovaMission` | 1 | The record's +`$2D`: 1 in the system whose sun goes nova (JumpArrive after 32 jumps), until the jump out; the red tint, the refugees' question (RefugeeQuestion) | `FillAttrs`, `JumpTick`, `MessageTick`, `NovaSunGrows`, `NovaTint` +7 | `NewGame`, `GalaxyJump` (code), `MissionNova` (code) |
| `$D082` | `Fuel` | 1 | The fuel in tenths of a light year | `ControlFuelValue`, `GalacticChart`, `JumpKeys`, `JumpTick`, `ShortRangeChart` +3 | `NewGame`, `SetFuel` |
| `$D083` | `Missiles` | 1 | The missiles fitted (0-4) | `DrawMissiles`, `MissileKeys`, `EquipMissile` (code) | `NewGame`, `MissileGone` (code) |
| `$D084` | `Equipment` | 10 | The equipment flags: the large cargo bay, ECM, two spare, the fuel scoop, the escape pod, the energy bomb, the energy unit, the docking computer, the galactic hyperdrive | `DamageItem`, `Gunsight`, `Recharge`, `ResetFlight`, `StatusBomb` +11 | `NewGame`, `BuyCargo` (code), `EscapePodKey` (code), `GalaxyJumpNext` (code), `GunsightECMOff` (code) +2 |
| `$D08E` | `Seeds` | 16 | The spare bytes, the galaxy's three seeds, the system's three seeds | `ChartCross`, `CopySeeds`, `FindNearestNow`, `GalacticChart`, `JumpTick` +9 | `JumpTick`, `NewGame`, `JumpArrive` (code), `JumpArriveCursor` (code), `JumpWitch` (code) |
| `$D09E` | `MarketStock` | 17 | The station's stock of each commodity | `MarketRow` | `MakeMarket`, `NewGame` |
| `$D0AF` | `MissionState` | 1 | The Thargoid mission: 0 none, 1 the MAYDAY heard, 2 not yet answered, 3 accepted, 4 in the galaxy's first system (the station a Thargoid base), `$0C` its station destroyed, 5 rewarded at the next dock | `DataScreen`, `MessageTick`, `Tactics`, `UpdateShips`, `ArrivalScreens` (code) +6 | `NewGame`, `GalaxyJump` (code), `MissionAccept` (code), `MissionDone` (code), `MissionQuestion` (code) +2 |
| `$D0B0` | `MissionFlags` | 1 | Bit 0 the nova started (32 jumps), 1 the cloak ship due (128 jumps), 2 the Thargoid MAYDAY started (254 jumps), 3 the Thargoid mission done, 5 refugees aboard, 6 the cloaking device owned, 7 the Thargoid mission accepted (the ECM jammer) | `Gunsight`, `StatusBomb`, `StatusScreen`, `AddCargoSpecial` (code), `BuyCargo` (code) +11 | `NewGame`, `AddCargoSpecial` (code), `BuyCargoLoop` (code), `EscapePodCargo` (code), `MissionAccept` (code) +1 |
| `$D0B1` | `RecordTail` | 9 | The record's last nine bytes: the system docked at (`$D0B2`, `$D0B3`) and the sun's place | - | `EscapePodHold` (code) |
| `$D0BA` | `SunGrows` | 1 | Past the record: the sun's growth | `SunGrowth`, `MessagePeriodicDue` (code) | `TitleLoad`, `TitleNext`, `GalaxyJump` (code), `NovaSunGrows` (code) |
| `$D0BB` | `ChartCursorX` | 1 | The chart cursor (galaxy coordinates) | `ChartCross`, `ChartLeft`, `JumpTick`, `SquaredDistance`, `ChartRight` (code) +2 | `ChartLeft`, `JumpTick`, `NewGame`, `SystemData`, `ChartHome` (code) +2 |
| `$D0BC` | `ChartCursorY` | 1 | ChartCursorY | `ChartCross`, `JumpTick`, `SquaredDistance`, `ChartDown` (code), `ChartUp` (code) +2 | `JumpTick`, `NewGame`, `SystemData`, `ChartDownStore` (code), `ChartHome` (code) +2 |
| `$D0BD` | `Messages` | 20 | Ten message slots (MessageTick): a column (bit 7 the request) and a standard code each. 0 MISSILE JAMMED, 1 INCOMING MISSILE, 2 TARGET LOST, 3 an item DESTROYED (DamageItem), 4 a bounty in CR (AddCash), 5 a scooped item's name (AddCargo writes the code), 6 RIGHT ON COMMANDER (a new rating), 9 FUEL LEAK (FuelLeak); slots 7 and 8 (`$D0CB-$D0CE`) are the number printer's work bytes and never requested. | `ClearMessages`, `MessageTick`, `PadNumber`, `PrintDigit`, `PrintNumber` +7 | `ClearMessages`, `ControlGalaxy`, `DataScreen`, `JumpTick`, `MarketRow` +17 |
| `$D0D1` | `PrintCase` | 1 | The printer's case state: the mode, the capital-next flags, the word buffering | `PrintChar` | `SetCase`, `ViewTexts`, `JumpDocked` (code), `TapeMessage` (code) |
| `$D0D2` | `PrintCapital` | 1 | PrintCapital | `PrintChar` | `JustifyChar`, `NewLine`, `PrintChar`, `PrintIfRowFree`, `PrintUnit` +2 |
| `$D0D3` | `PrintCapitalNext` | 1 | PrintCapitalNext | `PrintChar` | `CapitalNext`, `PrintChar` |
| `$D0D4` | `PrintBuffering` | 1 | PrintBuffering | `PrintChar` | `JustifyOff`, `JustifyOn` |
| `$D0D5` | `PrintPointer` | 2 | The printer's patched address | `PlainText`, `TitleElite`, `TitleNext`, `TitleTextPrint`, `GameOverFrame` (code) | - |
| `$D0E3` | `MissileTarget` | 1 | The slot the missile is locked on | `MissileFire` (code), `MissileKeys` (code), `RemoveShipNext` (code) | `MissileArm` (code) |
| `$D0F0` | `VectorSpare` | 3 | VectorSpare | - | - |
| `$D232` | `DefaultCommander` | 93 | The new game's commander: JAMESON, 100.0 Cr, 7.0 light years of fuel, a pulse laser, 3 missiles, galaxy 1 at Lave | `NewGame` | - |
| `$D28F` | `DefaultSun` | 9 | The new game's sun and planet place | `NewGame` | - |

## textprint

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D2DC` | `NumberLeft` | 2 | The number being printed, less the digits printed so far | `PrintDigit`, `PrintNumberUnits` | `PrintDigit`, `PrintNumber` |
| `$D31C` | `PointCode` | 1 | The "." printed by PrintNumberPoint's CALL PrintInline | `PrintInline` | - |
| `$D420` | `OtherSetOn` | 1 | Zero: PrintOtherChar's codes go to the standard set | `PrintOtherChar` | `SetOtherSet` |
| `$D5F5` | `Synonyms` | 38 | The first other token of each row of five synonyms | `RandomToken` | - |
| `$D61B` | `ClearScreenSP` | 2 | ClearScreenSP | `ClearScreen` | `ClearScreen` |
| `$D675` | `JustifyLine` | 68 | The justified text's line (32 bytes), the next word (`$D695`, 31), the counts (`$D6B3`, `$D6B4`) and two pointers (`$D6B5`, `$D6B7`) | `ControlPeople`, `JustifyAddSpace`, `JustifyBackWord`, `JustifyChar`, `JustifyNewLine` +1 | `ControlPeople`, `JustifyAddSpace`, `JustifyBackWord`, `JustifyChar`, `JustifyNewLine` +1 |
| `$D7C3` | `TokenControls` | 28 | The standard set's 14 control codes: 0 nothing, 1 the galaxy's number, 2 the current system, 3 the selected system, 4 the commander, 5 the fuel, 6 capitals, 7 the cash, 8 sentence case, 9 a new line, 10 the other set on, 11 the galaxy's first system, 12 and 13 nothing | `JumpTable` | - |
| `$D7DF` | `OtherControls` | 64 | The other set's 32: 0 nothing, 1 capitals, 2 sentence case, 3 the selected system, 4 the commander, 5 and 6 the other set on and off, 7 a beep, 8 tab, 9 a clear page, 10 the column 0, 11 the rule, 12 a new line, 13 capital then small, 14 and 15 the justified text, 16 the galaxy's first system, 17 the system's people (-ian), 18 a random name, 19 a capital next, 21 the text area cleared, 22 and 24 waits, 23 and 29 rows 10 and 6, 25 a wait | `JumpTable` | - |
| `$D83F` | `FuelSpace` | 1 | The space after "FUEL:" | `PrintInline` | - |
| `$D87E` | `TabColumn` | 1 | TabColumn | `ColumnInline` | - |
| `$D8AD` | `ControlSpare` | 1 | ControlSpare | - | - |
| `$D8DC` | `PeopleSuffix` | 4 | "IAN" and the vowels it replaces | `PrintCodes` | - |
| `$D8E0` | `Vowels` | 5 | Vowels | `ControlPeople` | - |
| `$D8FF` | `ControlData` | 3 | Three bytes no code reads (known from the code only) | - | - |

## commander

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D902` | `MenuBands` | 5 | The menu page's colour bands for ColourBands: one cell and a gap of 4 rows, two cells and 2 rows twice, two cells and 3 rows, sixteen cells and the end | - | - |
| `$D907` | `TapeLoaded` | 1 | 1 once a commander has been loaded: CommanderMenu returns it | `CommanderMenuExit` (code) | `CommanderMenu` (code), `LoadCommanderBlock` (code) |
| `$D908` | `MenuStack` | 2 | SP at the menu's start: every pass and every error path starts again from it | `CommanderMenuKey` (code) | `CommanderMenu` (code) |
| `$DA72` | `MessageTimer` | 1 | Counts 70 passes between the periodic messages | `MessageTick`, `MessagePeriodic` (code) | `MessageTick` |
| `$DA73` | `MessageShown` | 1 | The passes the message on the line has left (14 from MessageShow) | `MessageTick` | `JumpKeys`, `MessageShow`, `MessageTick` |
| `$DA74` | `MessagePass` | 1 | Toggled each pass: the slots are scanned on even passes, the periodic messages on odd ones | `MessageTick` | `MessageTick` |
| `$DA75` | `MessageColumn` | 1 | The message's column on row 14 | `MessageTick`, `MessagePrint` (code) | `MessageSet` |
| `$DA76` | `MessageToken` | 1 | The message's standard code: `$FD` (token `$5D`, " DESTROYED") after MessageItem, `$E2` (token `$42`, " CR") after MessageNumber, 0 none | `DamageItem`, `MessageTick`, `MessagePrint` (code), `MessagePrintCode` (code) | `ClearMessages`, `MessageSet` |
| `$DA77` | `MessageNumber` | 2 | The bounty AddCash shows, in tenths | `MessageBounty` (code) | `AddCash` (code) |
| `$DA79` | `MessageItem` | 1 | The item DamageItem destroyed, a standard code (equipment `$6C` on, cargo `$CC` on) | `MessageDestroyed` (code) | `DamageItemMessage` (code) |
| `$DBA1` | `JumpCountdown` | 1 | The hyperspace countdown (twice the seconds shown); 0 when no jump is pending | `JumpKeys`, `JumpTick` | `JumpKeys`, `JumpTick`, `NewGame` |

## galaxy

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DEB9` | `GalaxySpare` | 1 | One byte no code reads (known from the code only) | - | - |
| `$DEBA` | `SelectedSeeds` | 6 | The selected system's seeds s0, s1, s2 (SystemData) | `DataScreen`, `JumpTick`, `PrintRadius`, `PrintSpecies`, `JumpArriveLoop` (code) | `SystemData` |
| `$DEC0` | `SystemSeeds` | 6 | The seeds being twisted: the system the loops are at | `CopySeeds`, `DrawSystemIcon`, `EachSystemInWindow`, `FindNearestNow`, `NamePair` +5 | `CopySeeds`, `Twist` |
| `$DEC6` | `BestSeeds` | 6 | FindNearest's best system so far; FindSystem's place in the walk | `CopySeeds` | `CopySeeds` |
| `$DECC` | `TextSeeds` | 4 | The four bytes TextRandom shifts for the planet's description (from s1 and s2) | `TextRandom` | `DataScreen`, `TextRandom` |
| `$DED0` | `NameInput` | 11 | The name typed: the commander's (JAMESON) or a planet's (FindSystem), zero-ended | `LoadCommanderName` (code) | - |
| `$DEDB` | `NameBuffer` | 9 | The name SystemName builds (up to eight letters, zero-ended) | `KeepName`, `LabelSystem`, `PrintCodes` | `NamePair`, `SystemName` |
| `$DEE4` | `CurrentName` | 9 | The current system's name (LAVE) | `PrintCodes` | `JumpTick`, `NewGame`, `JumpWitch` (code) |
| `$DEED` | `SelectedName` | 9 | The selected system's name | `ControlPeople`, `JumpTick`, `NewGame`, `PrintCodes` | `JumpTick`, `KeepName`, `JumpWitch` (code) |
| `$DEF6` | `JumpRange` | 2 | The distance to the selected system in 0.1 light years (FindNearest, JumpDistance) | `JumpKeys`, `JumpTick`, `PrintDistance`, `JumpHyperspace` (code) | `JumpDistance` |
| `$DEF8` | `Economy` | 1 | The selected system's economy, 0-7 (0 rich industrial, 7 poor agricultural) | `JumpTick`, `MakeMarket`, `PrintEconomy`, `SystemData`, `JumpHyperspace` (code) | `SystemData` |
| `$DEF9` | `Government` | 1 | Its government, 0-7 (0 anarchy, 7 corporate state) | `DataScreen`, `JumpTick`, `SystemData`, `JumpArrive` (code) | `SystemData` |
| `$DEFA` | `TechLevel` | 1 | Its tech level less one, 0-14 | `DataScreen`, `JumpTick`, `JumpArrive` (code) | `SystemData` |
| `$DEFB` | `Population` | 1 | Its population in 100 millions | `DataScreen`, `SystemData` | `SystemData` |
| `$DEFC` | `Productivity` | 2 | Its productivity in millions of credits | `DataScreen` | `SystemData` |
| `$DEFE` | `SystemSpare` | 2 | Two bytes no code reads (known from the code only) | - | - |
| `$DF00` | `SystemCount` | 1 | FindSystem's count of the systems tried (256 then not found) | `FindSystemMiss` (code) | `FindSystem` (code), `FindSystemMiss` (code) |
| `$DF01` | `NamePointer` | 2 | SystemName's next letter | `NamePair` | `NamePair`, `SystemName` |
| `$DF5E` | `BestDistance` | 2 | FindNearest's smallest squared distance so far | `FindNearestNow` | `FindNearestNow` |
| `$E1BB` | `PriceBase` | 2 | Two bytes before Prices: the market screens' pointers start here and step 2 first | - | - |
| `$E1BD` | `Prices` | 34 | The 17 commodities' prices in tenths of a credit (MakeMarket) | `FirearmsPrice`, `MarketRow` | `MakeMarket` |
| `$E1DF` | `MarketItem` | 1 | The market screens' row: the commodity (0-16), which also picks the unit (t, kg, g) | `MarketPrices`, `MarketRow`, `PrintUnit`, `BuyCargoItem` (code), `BuyCheckHold` (code) +5 | `DataScreen`, `MarketPrices`, `BuyCargoItem` (code), `InventoryHold` (code), `InventoryHoldLoop` (code) +2 |
| `$E1E0` | `HoldPointer` | 2 | The trading pages' pointer into the hold (`$D06B` on), stepped first | `BuyCargoRow` (code), `BuyCheckHold` (code), `HoldRow` (code), `RestoreTrade` (code), `SaveTrade` (code) +1 | `BuyCargoRow` (code), `HoldRow` (code), `InventoryHold` (code), `TradePointers` (code) |
| `$E1E2` | `PricePointer` | 2 | Their pointer into Prices | `MarketRow`, `BuyCheckPay` (code), `SellCargoRow` (code), `SellCheckLoop` (code) | `MarketPrices`, `MarketRow`, `SellCargoRow` (code), `TradePointers` (code) |
| `$E1E4` | `StockPointer` | 2 | Their pointer into MarketStock (buying) or the hold, stepped first | `MarketRow`, `BuyCheck` (code), `RestoreTrade` (code), `SaveTrade` (code) | `MarketPrices`, `MarketRow`, `BuyCargoPage` (code) |
| `$E1E6` | `SavedCursor` | 2 | The text position SaveCursor keeps | `RestoreCursor` (code) | `SaveCursor` (code) |

## menuhelpers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E394` | `InputLength` | 1 | ReadLine: the letters typed | `PlanetNamePrompt` (code), `ReadLineDelete` (code), `ReadLineLetter` (code) | `ReadLine` (code), `ReadLineDelete` (code), `ReadLineLetter` (code) |
| `$E395` | `InputPointer` | 2 | ReadLine: the next letter's place | `ReadLineDelete` (code), `ReadLineEnd` (code), `ReadLineLetter` (code) | `ReadLine` (code), `ReadLineDelete` (code), `ReadLineLetter` (code) |
| `$E397` | `InputKey` | 1 | ReadLine: the last key's code | `ReadLineKey` (code) | `ReadLineKey` (code) |
| `$E3C9` | `InputPrompt` | 1 | ReadLine's prompt (an other token) | `ReadLine` (code) | `ReadLine` (code) |
| `$E3CA` | `InputStart` | 2 | ReadLine's buffer | `ReadLine` (code) | `ReadLine` (code) |

## chartcursor

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E52B` | `CrossSize` | 1 | The cross's length in pixels (16 or 24 for the current system's, 10 or 16 for the cursor's) | `ChartCross`, `DrawCross`, `DrawCrossEnd` | `GalacticChart`, `ShortRangeChart` |
| `$E52C` | `CrossTop` | 1 | The chart's first pixel row (24) | `DrawCrossEnd` | `GalacticChart`, `ShortRangeChart` |
| `$E52D` | `CrossBottom` | 1 | The chart's last pixel row (152 galactic, 167 short range) | `DrawCrossEnd` | `GalacticChart`, `ShortRangeChart` |
| `$E6AD` | `CrossSpare` | 1 | One byte no code reads (known from the code only) | - | - |

## market

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E6F8` | `MarketBands` | 2 | The trading pages' colour bands: 30 cells and a gap of a row, 30 cells | - | - |
| `$E8A4` | `SavedTenths` | 2 | SaveTrade's copy of the cash's tenths (`$D068`) | `RestoreTrade` (code) | `SaveTrade` (code) |
| `$E8A6` | `SavedThousands` | 2 | Its copy of the thousands (`$D066`) | `RestoreTrade` (code) | `SaveTrade` (code) |
| `$E8A8` | `SavedHold` | 1 | The hold byte | `RestoreTrade` (code) | `SaveTrade` (code) |
| `$E8A9` | `SavedStock` | 1 | The stock byte | `RestoreTrade` (code) | `SaveTrade` (code) |
| `$E8AA` | `SavedSpace` | 1 | The free space | `RestoreTrade` (code) | `SaveTrade` (code) |
| `$E8AB` | `Quantity` | 1 | The quantity typed (or the equipment item, the laser's view) | `BuyCheck` (code), `BuyCheckPay` (code), `EquipFitted` (code), `EquipFlag` (code), `EquipLaserKind` (code) +4 | `QuantityFirst` (code), `QuantityFirstKey` (code) |
| `$E8AC` | `QuantityCheck` | 2 | The check QuantityKeys runs (CallCheck) | `QuantityFirstKey` (code), `QuantitySecond` (code) | `QuantityKeys` (code) |
| `$E8D8` | `SellBands` | 1 | 30 cells to the end | - | - |
| `$EB5E` | `EquipCount` | 1 | The items listed | `EquipShipAsk` (code), `EquipShipRow` (code) | `EquipShipSetEquipCount` (code) |
| `$EB5F` | `EquipRow` | 1 | The item being listed (or the view) | `EquipLaserView` (code), `EquipShipRow` (code) | `EquipLaserView` (code), `EquipShipRow` (code) |
| `$EB60` | `EquipPointer` | 2 | The next price in EquipPrices | `EquipShipRow` (code) | `EquipShip` (code), `EquipShipRow` (code) |
| `$EB62` | `FitLaserKind` | 1 | The laser being fitted | `EquipLaserView` (code) | `EquipLaserKind` (code) |

## dockedscreens

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$EC11` | `ClearBlockCount` | 1 | ClearBlock's A (the rows of 32 bytes) | `ClearBlock` | `ClearBlock` |
| `$EC12` | `ClearBlockStack` | 2 | ClearBlock's saved SP | `ClearBlock` | `ClearBlock` |
| `$EC40` | `RowsUsed` | 24 | The short range chart's text rows that hold a name (255), one byte a row | `PrintIfRowFree` | `PrintIfRowFree`, `ShortRangeChart` |
| `$ED75` | `LabelSpare` | 2 | Two bytes no code reads (known from the code only) | - | - |
| `$ED77` | `LabelLength` | 1 | LabelSystem writes 8 - the name's length here, and no code reads it (known from the code only) | - | `LabelSystem` |
| `$EF86` | `StatusLaserView` | 1 | The view the status page's laser line is at (0-3) | `PrintLaser` | `PrintLaser`, `StatusBomb` |
| `$F0AE` | `RatingScores` | 6 | The rating's thresholds for the score's middle byte (8, 16, 32, 64, 128, end `$FF`) | `StatusScreen` | - |
| `$F0B4` | `RatingHigh` | 4 | Those for its top byte (2, 10, 25, end `$FF`) | - | - |

## keyboard

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F117` | `TextSpare` | 3 | Three bytes no code reads (known from the code only) | - | - |
| `$F11A` | `TokenTable` | 2 | The standard tokens' address (`$F11E`): PrintCode skips n zero-ended strings from it | `PrintCode` | - |
| `$F11C` | `OtherTable` | 2 | The other tokens' address (`$F4F5`): PrintOther skips n - 1 | `PrintOther` | - |
| `$F11E` | `StdTokens` | 983 | The standard set's 149 strings (tools/tokens.py --set std), each ended by a zero | `PrintCode` | - |
| `$F4F5` | `OtherTokens` | 1803 | The other set's 263 strings (tools/tokens.py --set other): the missions, the planet descriptions, the commander menu | `PrintOther` | - |
| `$FC00` | `TokensSpare` | 8 | Eight zero bytes after the tables (known from the code only) | - | - |
| `$FC08` | `KeyScreens` | 1 | Keys down: ENTER 1, L 2, K 4, P 8, O `$10`, I `$20`, 0 `$40` (the joystick's fire), Y `$80` (the cloak) | `CloakKey`, `KeyPressed`, `ScanJoystick`, `SelectView` | `CloakKey`, `KeyPressed`, `PauseMenu`, `SelectViewDone`, `ZeroBytes` +1 |
| `$FC09` | `KeySteer` | 1 | N 1 (roll left), M 2 (roll right), X 4 (climb), S 8 (dive), SPACE `$10` (faster), SYMBOL SHIFT `$20` (slower): the joystick's bits 0-3 | `ChartCursorKeys`, `KeyPressed`, `ReadControls`, `ScanJoystick`, `TitleLoad` +2 | `ChartCursorKeys`, `KeyPressed`, `PauseMenu`, `ReadControls`, `ReadControlsSpeed` +4 |
| `$FC0A` | `KeyViews` | 1 | 1-4 bits 0-3 (the views, docked the launch and the trading screens), H `$10` (hyperspace), G `$20` (galactic), J `$40` (the jump drive), CAPS SHIFT `$80` (pause) | `InSystemJump`, `JumpKeys`, `KeyPressed`, `PauseMenu`, `ScanJoystick` +1 | `InSystemJump`, `JumpKeys`, `KeyPressed`, `PauseMenu`, `ScanJoystick` +3 |
| `$FC0B` | `KeyCombat` | 1 | A 1 (fire), T 2 (target a missile), F 4 (fire the missile), U 8 (unarm), E `$10` (E.C.M.), W `$20` (energy bomb), Q `$40` (escape pod), C `$80` (docking computer) | `DashboardTick`, `DockKeys`, `EnergyBomb`, `EscapePod`, `Gunsight` +4 | `DashboardTick`, `DockKeys`, `Gunsight`, `KeyPressed`, `LaserCooling` +4 |
| `$FC0C` | `KeyChart` | 1 | B `$10` (the cursor home), D `$20` (the distance), R `$40` (a planet's name) | `ChartCursorKeys`, `KeyPressed` | `ChartCursorKeys`, `KeyPressed`, `PauseMenu`, `ZeroBytes`, `ClearKeys` (code) |
| `$FC0D` | `KeyCode` | 1 | The last key's character (KeyCodes); `$FF` none, `$FE` DELETE (CAPS SHIFT with 0) | `PauseMenu`, `TitleLoad`, `TitleNext`, `LoadFailed` (code), `ReadLineRelease` (code) +1 | `KeyPressed`, `ScanKeyboard`, `ScanJoystickSteer` (code) |
| `$FC0E` | `Options` | 1 | The pause menu's options: bits 0-1 the controls (0 keyboard, 1 Kempston, 2 Cursor, 3 Sinclair), 2 recentring (R), 3 damping (D), 4 both axes reversed, 5 the vertical axis reversed, 6 the misjump (F), 7 sound | `Click`, `JumpTick`, `OptionBit6`, `ReadControls`, `ScanJoystick` +8 | `OptionBit6`, `TitleLoad`, `TitleNext` |
| `$FC0F` | `KeyDigits` | 1 | 9 1, 5 2, 8 4, 6 8, 7 `$10`: the Cursor and Sinclair joysticks' keys | `TitleLoad`, `TitleNext`, `ScanJoystickDigits` (code) | `ScanKeyboard` |
| `$FCEA` | `VectorFiller` | 87 | `$FE` bytes: what is left of a 257-byte IM2 table `$FD00-$FE00` (the bytes past `$FD00` still give `$FEFE` for a low bus byte) | - | - |
| `$FD41` | `KeyCodes` | 40 | Each key's character by the index: SPACE, ENTER, P, 0, 1, Q, A, CAPS SHIFT (0), then the next bit of each row | `KeyPressed` | - |
| `$FD8A` | `LaserItems` | 4 | The equipment item of each laser kind 1-4 (5 pulse, 6 beam, 13 military, 14 mining): read at `$FD89` + kind | - | - |
| `$FD8E` | `StatusBands` | 8 | The status page's colour bands (ColourBands: cells x 8 + rows, a row 0 ends) | `ColourBands` | - |
| `$FD96` | `InventoryBands` | 3 | The inventory's | - | - |
| `$FD99` | `OtherPairs` | 26 | The other set's 13 two-letter pairs (codes `$D7` on); ControlRandomName uses those from `$FD9B` | `PrintPairNow` | - |
| `$FDB3` | `StdPairs` | 64 | The standard set's 32 pairs (codes `$80-$9F`), also the system names' syllables: AL LE XE GE ZA CE BI SO US ES AR MA IN DI RE A? ER AT EN BE RA LA VE TI ED OR QU AN TE IS RI ON, as BBC Elite's | `NamePair`, `PrintPairNow` | - |
| `$FDF3` | `DataBands` | 8 | The data screen's colour bands | `ColourBands` | - |
| `$FDFB` | `MarketBands2` | 3 | The market prices' colour bands | `ColourBands` | - |
| `$FDFE` | `VectorByte` | 1 | `$FE` (the filler's last byte) | - | - |
| `$FDFF` | `IM2Vector` | 2 | `$FEFE`: the IM2 vector for the bus byte `$FF` (I = `$FD`), the handler's JR at `$FEFE` | `IM2Entry` | - |
| `$FF08` | `RollControl` | 2 | The roll accumulator (sign and magnitude): its high byte `$FF09` is the roll rate CopyRates takes | `CopyRates`, `ReadControls` | `ReadControls`, `ZeroBytes` |
| `$FF0A` | `PitchControl` | 2 | The pitch accumulator, the rate in `$FF0B` | `CopyRates`, `ReadControls` | `ReadControls`, `ReadControlsSpeed`, `ZeroBytes` |
| `$FF0C` | `SpeedControl` | 2 | The speed accumulator, the speed in `$FF0D` | `CopyRates`, `ReadControls`, `ReadControlsSpeed` | `ReadControls`, `ReadControlsSpeed`, `ResetControls`, `ZeroBytes`, `EscapePodKey` (code) +1 |
| `$FF56` | `IM2SavedSP` | 2 | The interrupted program's SP | `IM2Entry`, `IM2Handler` (code) | `IM2Entry`, `IM2Handler` (code) |
| `$FF58` | `KeyTable` | 80 | Each key's (offset from `$FC08`, mask) by the index; Z and V have the mask 0 | `KeyPressed` | - |
