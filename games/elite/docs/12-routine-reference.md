# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/d1` (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)), `work/f1` (launch, flight, hyperspace to Diso, the laser), `work/w1` (the witch-space trick: a jump into witch space and the Thargoids). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the entries they cover. An entry no recording reached says so.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`lowdata`](11-data-reference.md#lowdata) | `$5B00`-`$6FF1` | 0 of 72 |
| [`startup`](#startup) | `$6FF2`-`$7470` | 47 of 72 |
| [`flightloop`](#flightloop) | `$7471`-`$7897` | 11 of 14 |
| [`stardust`](#stardust) | `$7898`-`$7FBD` | 21 of 41 |
| [`backbuffer`](#backbuffer) | `$7FBE`-`$81A2` | 13 of 14 |
| [`dashboard`](#dashboard) | `$81A3`-`$8618` | 19 of 27 |
| [`circles`](#circles) | `$8619`-`$928B` | 54 of 76 |
| [`tunnel`](#tunnel) | `$928C`-`$9508` | 15 of 20 |
| [`sound`](#sound) | `$9509`-`$96D5` | 42 of 46 |
| [`scanner`](#scanner) | `$96D6`-`$9C1B` | 26 of 31 |
| [`shipmotion`](#shipmotion) | `$9C1C`-`$A28A` | 37 of 56 |
| [`tactics`](#tactics) | `$A28B`-`$A6DE` | 14 of 17 |
| [`drawships`](#drawships) | `$A6DF`-`$B03F` | 35 of 54 |
| [`linedraw`](#linedraw) | `$B040`-`$B4D6` | 13 of 17 |
| [`combat`](#combat) | `$B4D7`-`$BDFF` | 34 of 44 |
| [`squaretable`](11-data-reference.md#squaretable) | `$BE00`-`$CFFF` | 0 of 3 |
| [`gamestate`](#gamestate) | `$D000`-`$D2DB` | 45 of 85 |
| [`textprint`](#textprint) | `$D2DC`-`$D901` | 71 of 85 |
| [`commander`](#commander) | `$D902`-`$DBA1` | 18 of 29 |
| [`hyperspace`](#hyperspace) | `$DBA2`-`$DEB8` | 14 of 14 |
| [`galaxy`](#galaxy) | `$DEB9`-`$E1E7` | 23 of 49 |
| [`menuhelpers`](#menuhelpers) | `$E1E8`-`$E46E` | 35 of 40 |
| [`chartcursor`](#chartcursor) | `$E46F`-`$E6AD` | 13 of 17 |
| [`market`](#market) | `$E6AE`-`$EB7B` | 30 of 43 |
| [`dockedscreens`](#dockedscreens) | `$EB7C`-`$F116` | 28 of 36 |
| [`keyboard`](#keyboard) | `$F117`-`$FFA7` | 11 of 41 |

## startup

`src/game/startup.asm`

### `EnergyBombVector` (`$6FF2`)

**JP EnergyBomb (FlightLoop calls it every frame)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 1,124 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 8,187 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 4,017 t-states own (0.00 %) |
| Called from | `DashboardTick` |
| Calls | `EnergyBomb` (tail) |

### `FlashVector` (`$6FF5`)

**JP FlashScreen (known from the code only: no caller ran)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillAttrsVector` (`$6FF8`)

**JP FillAttrs**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 22 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 58 t-states own (0.00 %) |
| Called from | `TitleNext`, `TunnelDone`, `MessageTick` |
| Calls | `FillAttrs` (tail) |

### `EnergyBomb` (`$7089`)

**Detonate the energy bomb when its key is down and one is fitted**

Every frame (f1, w1, d1: 1076 runs) from FlightLoop through EnergyBombVector. KeyCombat `$FC0B` bit 5 is the bomb key; EnergyBombFitted `$D08A` non-zero is a bomb on board. The bomb is used up, BombKill `$9C95` = 1 makes UpdateShips destroy what it can, sound 0 is requested and the screen flashes 24 times (FlashScreen). k2 fired one at frame 3304 (FlashScreen 24 runs; the Thargoids unhurt), m1 and m2 one each.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 3,117 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 23,532 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 11,837 t-states own (0.00 %) |
| Called from | `EnergyBombVector` (tail) |
| Reads | `$FC0B` (`KeyCombat`) |

### `FlashScreen` (`$70A9`)

**One flash: the 3D view's attributes `$28`, then `$0F`**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillAttrs` (`$70B0`)

**Fill the 3D view's attributes (`$5800-$59FF`) with L after the next interrupt**

L is the attribute; with CloakOn `$D041` zero only its INK bits stay (AND 7). The entry FillAttrsTinted `$70BA` skips that step; with NovaMission `$D081` set the attribute is ANDed with `$3A`. After a HALT the stack pointer is put at `$59FF` and 16 rows of 15 PUSHes write the 512 bytes; FillSP keeps the real SP.

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 38,470 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 105,130 t-states own (0.02 %) |
| Called from | `FillAttrsVector` (tail) |
| Calls | `IM2Entry` |
| Reads | `$70C5` (`FillAttrsTinted`); `$70DE`-`$70DF` (`FillSP`); `$D041` (`CloakOn`); `$D081` (`NovaMission`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$70DE`-`$70DF` (`FillSP`); `$FFF7`-`$FFFC` (`work space $FFF7+`) |

### `FillAttrsTinted` (`$70BA`)

**FillAttrsTinted**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Start` (`$70E0`)

**The game's entry from the kickoff: JP Title**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawChartCircleVector` (`$7119`)

**JP DrawChartCircle**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 37 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 19 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 19 t-states own (0.00 %) |
| Called from | `GalacticChart`, `ShortRangeChart` |
| Calls | `DrawChartCircle` (tail) |

### `ConditionLightVector` (`$7121`)

**JP ConditionLight**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 145 calls, 2,390 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 693 calls, 10,360 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 391 calls, 6,071 t-states own (0.00 %) |
| Called from | `MessageTick`, `PageTitle`, `StatusScreen` |
| Calls | `ConditionLight` (tail) |

### `SoundTickVector` (`$7125`)

**JP SoundTick (the interrupt handler calls it)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,613 calls, 26,130 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4,571 calls, 45,710 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,214 calls, 62,140 t-states own (0.01 %) |
| Called from | `IM2Entry` |
| Calls | `SoundTick` (tail) |

### `AddDigitVector` (`$712A`)

**JP AddDigit (known from the code only, like the next two)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AttrFillVector` (`$712D`)

**JP DashAttrs `$9974`**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddDigit` (`$7130`)

**(HL) = (HL) * 10 + B: one typed digit into a number**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CopyRates` (`$713C`)

**Copy the control rates the interrupt built to this frame's rates and the indicators**

Every pass of FlightLoop (197283 runs over f1, w1, d1). The high bytes of RollControl, PitchControl and SpeedControl (`$FF09`, `$FF0B`, `$FF0D`) are what ReadControls `$FE01` accumulated in the interrupt: copied to RollRate, PitchRate and SpeedRate; the roll and pitch indicators get `$15` plus or minus the rate (a sign-magnitude byte), the speed indicator 5 * speed + 5.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 120,160 calls, 33,678,172 t-states own (17.78 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 38,713 calls, 10,714,807 t-states own (3.16 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 38,410 calls, 10,630,512 t-states own (2.27 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`); `$FF09`-`$FF0D` (`RollControl`, `PitchControl`, `SpeedControl`) |
| Writes | `$70E4`-`$7100` (`RollRate`, `PitchRate`, `SpeedRate`, `BarDrawn`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `DockKeys` (`$717B`)

**Dock: after the collision code docked the ship, or on the docking computer key in the safe zone**

Docked `$9C9A` is set by the collision code when the ship enters the station (`$B591`) and by the arrival code (`$9466`): cleared, and the docking sequence runs. Otherwise KeyCombat `$FC0B` bit 7 (the docking computer key, cleared here) docks when the ship is in the safe zone, DockingComputer `$D08C` is fitted, Condition is not 0, `$D03F` is 0 and slot 0's flag bit 2 is clear; AutoDocked is set. Then the front view, the dashboard, CentreMarkers and the docking scene (SceneDock `$93ED`). f1 and w1: 863 runs, no dock.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 93 calls, 9,212 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 644 calls, 69,257 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 126 calls, 12,699 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Reads | `$9C9A` (`Docked`); `$FC0B` (`KeyCombat`) |
| Writes | `$FC0B` (`KeyCombat`) |

### `CentreMarkers` (`$71C0`)

**Move the sun and the planet half way to slot 0's position (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CentreMarker` (`$71CE`)

**CentreMarker**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HalfDifference` (`$71E4`)

**HL = half the difference between a marker coordinate (IY) and the slot's (IX)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ChartCursorKeys` (`$71F3`)

**On the charts (ViewIndex 7, 8): a cursor key moves the cursor through the chart vector**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 120,067 calls, 9,303,995 t-states own (4.91 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 38,069 calls, 3,492,462 t-states own (1.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 38,069 calls, 3,492,462 t-states own (0.75 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `CallScreen`, `IM2Entry` |
| Reads | `$70E3` (`ViewIndex`); `$D03F` (`TunnelOn`); `$FC09`-`$FC0C` (`KeySteer`, `KeyViews`, `KeyCombat`, `KeyChart`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FC09`-`$FC0C` (`KeySteer`, `KeyViews`, `KeyCombat`, `KeyChart`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `CloakKey` (`$7222`)

**Every second frame: Y (KeyScreens `$FC08` bit 7) switches the cloaking device on or off once the mission has given it**

The device is MissionFlags bit 6 (AddCargoSpecial, the mission ship's canister). On: CloakOn = 1 while energy bank 3 (`$70FA`) is `$28` or more, the station's hostile bit cleared, AllHostile 0 and the view's attributes `$0F` (blue paper: FillAttrs keeps the paper while CloakOn is set); off: attributes 7. With bank 3 below `$28` the decrement leaves CloakOn at `$FF`, on but untinted (known from the code only). 1076 runs, the key never pressed with the device (no recording earned it, CloakOn 0 runs): the rest is known from the code only.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 1,218,650 t-states own (0.64 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 12,647,099 t-states own (3.73 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 5,736,193 t-states own (1.23 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `IM2Entry` |
| Reads | `$7221` (`CloakKeyCount`); `$7232` (`CloakKey`); `$FC08` (`KeyScreens`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7221` (`CloakKeyCount`); `$FC08` (`KeyScreens`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `NovaTint` (`$725C`)

**After the dashboard is redrawn (ClearView): the nova's red tint (attributes 2) again while NovaMission is set**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 79 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 41 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 41 t-states own (0.00 %) |
| Called from | `DashboardRestore` |
| Reads | `$D081` (`NovaMission`) |

### `CloakRestore` (`$7265`)

**After the dashboard is redrawn: the cloak's tint (`$0F`) again while CloakOn is set**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 50 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 60 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 60 t-states own (0.00 %) |
| Called from | `DashboardRestore` |
| Reads | `$D041` (`CloakOn`) |

### `NovaSunGrows` (`$726C`)

**At the launch (SceneLaunch): in the nova's system the sun starts to grow (SunGrows 1) and the view turns red**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 28 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 28 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 28 t-states own (0.00 %) |
| Called from | `SceneLaunch` |
| Reads | `$D081` (`NovaMission`) |

### `ArrivalScreens` (`$7278`)

**At the dock: the mission page MissionState asks for: 1 or 2 the briefing (MissionQuestion), 5 the award (MissionDone), 6 SHIP BOARDED BY THARGONS and the title**

No code sets state 6: the Thargon boarding is unreachable (known from the code only). The routine ran at each dock: dk 2, gx 1, m1 2, m2 1 (the briefing, MissionQuestion, at frame 2926).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PirateStation` (`$728D`)

**At the dock: a station whose roll counter's bit 7 is clear is pirate-held: SHIP BOARDED BY PIRATES, THEY SHOW NO MERCY, the title**

TitleNext sets bit 7 of slot 0's +`$1D` (the station's roll counter, bit 7 the direction); an arrival clears it with a chance that grows as the government falls (JumpArrive), so the station spins the other way: the only warning. Known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PauseMenu` (`$72A3`)

**The pause: hold the game while the key's bit is set and run the option keys**

KeyViews `$FC0A` bit 7 is the pause key (the keyboard scan sets it). The game waits for the key to be released, then reads keys until SPACE (resume) or 1 (back to the title, carry set): B reverse the joystick, D keyboard damping, F the option bit 6, K keyboard / joystick, Q sound off, R recentring, S sound on, Y the Y axis reversed; an unknown key beeps (ErrorBeep). Each toggles a bit of Options `$FC0E` (HL = `$FC0E`). w1 paused once and pressed F and SPACE.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 120,160 calls, 4,365,655 t-states own (2.31 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 38,713 calls, 1,356,793 t-states own (0.40 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 38,410 calls, 8,163,292 t-states own (1.75 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `OptionBit6`, `ErrorBeep`, `IM2Entry` |
| Reads | `$72AD`-`$72B4` (`PauseMenu`); `$FC0A`-`$FC0D` (`KeyViews`, `KeyCombat`, `KeyChart`, `KeyCode`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FC08`-`$FC0C` (`KeyScreens`, `KeySteer`, `KeyViews`, `KeyCombat` and 1 more); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `ClearKeys` (`$72F1`)

**Zero the five key bytes `$FC08-$FC0C`**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OptionReverse` (`$7304`)

**Key B: Options bit 4**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OptionDamping` (`$730A`)

**Key D: Options bit 3**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OptionBit6` (`$7310`)

**Key F: Options bit 6**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 35 t-states own (0.00 %) |
| Called from | `PauseMenu` |
| Reads | `$FC0E` (`Options`) |
| Writes | `$FC0E` (`Options`) |

### `OptionSoundOff` (`$7316`)

**Key Q: Options bit 7 off**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OptionRecentre` (`$731C`)

**Key R: Options bit 2**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OptionSoundOn` (`$7322`)

**Key S: Options bit 7 on, and the sound requests cleared**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OptionReverseY` (`$732B`)

**Key Y: Options bit 5**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OptionKeyboard` (`$7331`)

**Key K: between the keyboard and the control method chosen on the title**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ErrorBeep` (`$7344`)

**A short beep: 6 frames of 4 rising tones on the speaker**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 435,370 t-states own (0.09 %) |
| Called from | `PauseMenu` |
| Calls | `IM2Entry` |
| Reads | `$734A` (`ErrorBeep`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF7`-`$FFF8` (`work space $FFF7+`) |
| Ports out | `$00FE`, `$30FE` |

### `Title` (`$7366`)

**The title: the rotating ship, "Load new commander", then the control method**

SP is kept in TitleSP `$7578` for the game overs (PirateStation, ArrivalScreens). The ship action `$79` (DoShipAction `$9C9C`) places the title Cobra; then the title loop draws it each frame (DrawTitleShip `$9CAF`) until a key: Y (KeyCode `$FC0D` + 1 = `$5A`) opens the commander load menu (CommanderMenuVector `$D04E`). The second loop shows "PRESS SPACE, COMMANDER" with the next title ship each pass (TitleShipCount) and reads a joystick held left (Kempston: port `$1F` bit 1 with bit 5 clear; Cursor: 5, KeyDigits bit 1; Sinclair: 6, KeyDigits bit 3) or SPACE (the keyboard); then the new game (NewGameVector `$D033`) and FlightLoop. c1, f1, w1 and d1 all start here (d1 at frame 784 of w1's title loop).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TitleLoad` (`$7378`)

**TitleLoad**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 28,636,084 t-states own (15.12 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 10,183,513 t-states own (3.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 450 t-states own (0.00 %) |
| Calls | `CopyRates`, `DockKeys`, `ChartCursorKeys`, `CloakKey`, `PauseMenu`, `TitleNext` (tail), `TitleTextLoad`, `TitleTextPress`, `WhiteAttrs`, `DrawSunPlanet`, `MoveSunPlanet`, `StationRunIn`, `Stardust`, `InSystemJump`, `CopyBackBuffer`, `DashboardRestore`, `ClearView`, `SelectView`, `DashboardSave`, `DashDistances`, `DrawBars`, `HitFlash`, `TunnelStart`, `ResetControls`, `DrawScanner`, `DashboardTick`, `UpdateShipsVector`, `ShipActionVector`, `DrawTitleShipVector`, `ScreenStatus`, `NewGameVector`, `ViewTextsVector`, `JumpKeysVector`, `IM2Entry` |
| Reads | `$6065` (`ShipSlots`); `$70E3` (`ViewIndex`); `$7103`-`$7104` (`WitchSpace`, `Condition`); `$711F`-`$7124` (`TooClose`, `SunLarge`, `ConditionLightVector`, `HoldRates`); `$73D6` (`TitleNext`); `$7470` (`TitleShipCount`); 2 more ranges |
| Writes | `$6065` (`ShipSlots`); `$7103`-`$7104` (`WitchSpace`, `Condition`); `$711E` (`SunNear`); `$7470` (`TitleShipCount`); `$7583` (`LastSunRadius`); `$D041` (`CloakOn`); 3 more ranges |
| Ports in | `$FF1F` |

### `TitleNext` (`$739E`)

**TitleNext**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 23,840,742 t-states own (5.10 %) |
| Called from | `TitleLoad` (tail) |
| Calls | `FillAttrsVector`, `CopyRates`, `DockKeys`, `ChartCursorKeys`, `CloakKey`, `PauseMenu`, `TitleTextPress`, `WhiteAttrs`, `DrawSunPlanet`, `MoveSunPlanet`, `StationRunIn`, `Stardust`, `InSystemJump`, `CopyBackBuffer`, `DashboardRestore`, `ClearView`, `SelectView`, `DashboardSave`, `DashDistances`, `DrawBars`, `HitFlash`, `TunnelStart`, `ResetControls`, `ClearShips`, `SoundLaunch`, `SoundGameOver`, `DrawScanner`, `ScannerRestore`, `DashboardTick`, `UpdateShipsVector`, `ShipActionVector`, `ResetShipsVector`, `DrawTitleShipVector`, `ScreenStatus`, `NewGameVector`, `PrintOtherVector`, `ViewTextsVector`, `JumpKeysVector`, `IM2Entry` |
| Reads | `$6065` (`ShipSlots`); `$70E3` (`ViewIndex`); `$7103`-`$7104` (`WitchSpace`, `Condition`); `$711F`-`$7124` (`TooClose`, `SunLarge`, `ConditionLightVector`, `HoldRates`); `$73D6` (`TitleNext`); `$7470` (`TitleShipCount`); 5 more ranges |
| Writes | `$6065` (`ShipSlots`); `$70E6` (`SpeedRate`); `$7103`-`$7104` (`WitchSpace`, `Condition`); `$711E`-`$7124` (`SunNear`, `TooClose`, `SunLarge`, `ConditionLightVector` and 1 more); `$7470` (`TitleShipCount`); `$7583` (`LastSunRadius`); 5 more ranges |
| Ports in | `$FF1F` |

### `TitleTextLoad` (`$7426`)

**The title text and "LOAD NEW COMMANDER (Y/N)?" (other token 6, row 14, column 1)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 3 calls, 163 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 163 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 163 t-states own (0.00 %) |
| Called from | `TitleLoad` |
| Calls | `TitleTextPrint` (tail), `TitleElite` |

### `TitleTextPress` (`$7430`)

**The title text and "PRESS SPACE, COMMANDER" (other token 7, row 14, column 4)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 50 calls, 2,431 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 50 calls, 2,431 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 284 calls, 13,879 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `TitleTextPrint`, `TitleElite` |

### `TitleTextPrint` (`$7438`)

**TitleTextPrint**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 5,921 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 5,921 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 287 calls, 31,852 t-states own (0.01 %) |
| Called from | `TitleTextLoad` (tail), `TitleTextPress` |
| Calls | `PlainText` (tail), `PrintOtherVector` |
| Reads | `$D0D5`-`$D0D6` (`PrintPointer`); `$D50A` (`PlotChar`) |
| Writes | `$D045`-`$D046` (`TextColumn`, `TextRow`); `$D50A` (`PlotChar`) |

### `TitleElite` (`$7447`)

**"---- E L I T E ----" (code `$1D`: token `$8F`) at row 1, column 5, in the title colours**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 6,742 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 6,742 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 287 calls, 36,641 t-states own (0.01 %) |
| Called from | `TitleTextLoad`, `TitleTextPress` |
| Calls | `PrintCodeVector` |
| Reads | `$D0D5`-`$D0D6` (`PrintPointer`); `$D50A` (`PlotChar`) |
| Writes | `$D045`-`$D046` (`TextColumn`, `TextRow`); `$D50A` (`PlotChar`) |

### `PlainText` (`$7459`)

**Clear the title-colour bit the two title texts set**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 6,161 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 6,161 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 287 calls, 32,804 t-states own (0.01 %) |
| Called from | `TitleTextPrint` (tail) |
| Reads | `$D0D5`-`$D0D6` (`PrintPointer`); `$D50A` (`PlotChar`) |
| Writes | `$D50A` (`PlotChar`) |

### `WhiteAttrs` (`$7461`)

**The attributes of the top two thirds: white INK on black**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 3,081 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 92 calls, 3,081 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 93 calls, 3,108 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `FillAttrPage` |

### `FillAttrPage` (`$7467`)

**256 attributes `$07` from HL**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 184 calls, 1,527,052 t-states own (0.81 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 184 calls, 1,527,052 t-states own (0.45 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 186 calls, 1,541,263 t-states own (0.33 %) |
| Called from | `WhiteAttrs` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$5800`-`$59FF` (screen); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

## flightloop

`src/game/flightloop.asm`

### `FlightLoop` (`$7471`)

**The main loop: the controls, the view, the pause, the jump keys, the ships, the screen**

A pass: CopyRates (unless HoldRates), SelectView, PauseMenu (1 there goes back to the title), JumpKeysVector `$D042`. Docked (Condition 0) it only reads the chart cursor and the menu key (KeySteer `$FC09` bit 5: the commander load / save menu, CommanderMenuVector `$D04E`); in flight it runs DockKeys, the debug key (`$7EDE`), the sun and planet rotation, the station run-in, then for a space view: the dashboard, the 3D view cleared (ClearView `$8080`), the sun and the planet, the stardust, the screen texts, the ships (ShipsVector `$9C80`), the effects, the back buffer copied to the screen (CopyBackBuffer `$7FBE`), the debris, the bars, the flash, the dashboard keys and DashDistances. f1, w1, d1: 197283 passes. In space a pass takes 5.0 (no ships) to 6.5 frames (four Thargoids), its only wait the HALT in CloakKey every second pass; docked it spins with no HALT, about 91 passes a frame (d1 600-700: 9118 in 100 frames; runtime-analysis.md).

TooClose set (the ship hit the sun or the planet, or a fatal hit) ends the game: 30 frames of other token 9 over the stardust, 50 frames' pause, then the title (`$739E`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSunPlanet` (`$7584`)

**Project and draw the sun and the planet for the view**

Each position is copied to CircleVector and projected (ProjectCircle); the sun is drawn by DrawCircleDI `$86D0` (a sun radius of `$28` or more sets SunLarge), the planet by DrawCircle `$86DE`. f1, w1, d1: 895 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 103 calls, 71,321 t-states own (0.04 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 655 calls, 444,979 t-states own (0.13 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 137 calls, 92,475 t-states own (0.02 %) |
| Called from | `TitleLoad`, `TitleNext`, `SceneLaunch` |
| Calls | `SunGrowth`, `ProjectCircle`, `DrawCircle` (tail), `IM2Entry` |
| Reads | `$7107`-`$7118` (`SunPosition`, `PlanetPosition`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7120` (`SunLarge`); `$757A`-`$7582` (`CircleVector`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `SunGrowth` (`$75C0`)

**With SunGrows `$D0BA` set the sun's circle grows by 2 a frame; past 255 TooClose ends the game**

Known from the code only past the first test: SunGrows was 0 in every recording. NovaSunGrows `$726C` sets it when NovaMission `$D081` is set.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 103 calls, 3,196 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 655 calls, 20,103 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 137 calls, 4,247 t-states own (0.00 %) |
| Called from | `DrawSunPlanet` |
| Reads | `$D0BA` (`SunGrows`) |

### `ProjectCircle` (`$75E1`)

**Project CircleVector for the view: the centre, the quadrant bits and the radius, A = 1 if seen**

The view picks the axes: front x/z and y/z, rear the same with z's sign flipped, left and right with x and z exchanged. Each screen coordinate is Divide24 of the coordinate by the depth; the quadrant bits go to CircleQuadrant `$861C` (bit 0 x positive, bit 1 y positive), the centre to CircleX `$861B` and CircleY `$861A`, the radius (`$A000` / depth, DivideFraction) to CircleRadius `$861D`. A = 0 when the object is behind the view or too far (depth above `$A000`).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 206 calls, 135,001 t-states own (0.07 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,310 calls, 748,598 t-states own (0.22 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 274 calls, 174,650 t-states own (0.04 %) |
| Called from | `DrawSunPlanet` |
| Calls | `ProjectCircleStore` (tail), `Divide24`, `ProjectCircleNone` (tail), `DivideFractionE`, `IM2Entry` |
| Reads | `$70E3` (`ViewIndex`); `$757A`-`$7582` (`CircleVector`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7582` (`CircleVector`); `$861A`-`$861C` (`CircleY`, `CircleX`, `CircleQuadrant`); `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `ProjectCircleStore` (`$7793`)

**ProjectCircleStore**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 103 calls, 3,497 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 655 calls, 21,418 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 137 calls, 4,586 t-states own (0.00 %) |
| Called from | `ProjectCircle` (tail) |
| Writes | `$861D` (`CircleRadius`) |

### `Divide24` (`$77A0`)

**D = HL:C / DE:B as a fraction (24-bit numbers): the screen offset of a coordinate at a depth**

Shift and subtract. The alternate C counts the two calls (one for x, one for y): the first sets bit 2 of the alternate B, the second bit 3 when the coordinate is smaller than the depth. The result is in D (and A).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 206 calls, 212,873 t-states own (0.11 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,310 calls, 1,030,694 t-states own (0.30 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 274 calls, 277,069 t-states own (0.06 %) |
| Called from | `ProjectCircle` |
| Calls | `DivideFractionE`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF1`-`$FFF8` (`work space $FFF1+`) |

### `ProjectCircleNone` (`$782A`)

**ProjectCircleNone**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 103 calls, 1,556 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 655 calls, 9,936 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 137 calls, 2,069 t-states own (0.00 %) |
| Called from | `ProjectCircle` (tail) |
| Calls | `IM2Entry` |

### `DivideFraction` (`$783B`)

**D = A * 256 / B: an 8-bit fraction, B > A**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DivideFractionE` (`$783D`)

**DivideFractionE**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 309 calls, 169,975 t-states own (0.09 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,965 calls, 1,081,286 t-states own (0.32 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 411 calls, 220,648 t-states own (0.05 %) |
| Called from | `ProjectCircle`, `Divide24` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF7`-`$FFF8` (`work space $FFF7+`) |

### `MoveSunPlanet` (`$7853`)

**Rotate the sun's and the planet's positions by this frame's roll, pitch and speed**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 104 calls, 6,824 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 655 calls, 44,940 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 137 calls, 8,959 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext`, `SceneLaunch` |
| Calls | `MovePositionVector` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `StationRunIn` (`$7861`)

**After a launch: move slot 0 (the station) until it is behind the ship, then normal flight**

StationLaunch `$711D` set: slot 0 is moved (MoveShipVector `$9C83`) each frame until all three coordinates' top bytes are 0 (the station is at the ship); then StationLaunch is cleared and its energy `$F0`. Without it, a slot 0 whose energy is 0 is moved once with StationLaunch set to `$FF`.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 7,586 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 644 calls, 88,054 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 126 calls, 10,330 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `MovePositionVector`, `IM2Entry` |
| Reads | `$604A`-`$6050` (`ShipSlots`); `$606A` (`ShipSlots`); `$711D` (`StationLaunch`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFFB`-`$FFFC` (`work space $FFFB+`) |

## stardust

`src/game/stardust.asm`

### `Stardust` (`$7898`)

**Move and draw the 16 dots for the view; after a J jump, two fast passes first**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 139 calls, 103,458 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 691 calls, 512,648 t-states own (0.15 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 418 calls, 326,885 t-states own (0.07 %) |
| Called from | `TitleLoad`, `TitleNext`, `SceneLaunch` |
| Calls | `StardustFront`, `IM2Entry` |
| Reads | `$70E3`-`$70E6` (`ViewIndex`, `RollRate`, `PitchRate`, `SpeedRate`); `$7103` (`WitchSpace`); `$7E8D`-`$7E91` (`StarDots`); `$7EDD` (`StarWarp`); `$7F6F`-`$7F7B` (`StarRoll`, `StarPitch`, `StarRollWork`, `StarFlags` and 8 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7F6F`-`$7F80` (`StarRoll`, `StarPitch`, `StarRollWork`, `StarFlags` and 12 more); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `StardustPass` (`$78B1`)

**One pass: the rates into StarRoll and StarPitch, the speed halved + 1, then every dot**

StarCount `$7F7C` counts the dots (16, or 4 in witch space: WitchSpace); a change of view (StarView `$7F7B` against ViewIndex) reshuffles the table (StarShuffle). Each dot's 5 bytes are unpacked into StarX, StarY (sign in bit 7, moved to StarSigns bits 7 and 6), StarZ, StarXFrac, StarYFrac; the roll and pitch signs go to StarSigns bits 4 and 3.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StardustFront` (`$7943`)

**The front and rear views: a dot moves out by its depth, then by the roll and the pitch**

X += X * speed / depth (MulBits, then DivideShifted or DivideFrac8), Y the same, the depth decreases by the speed (the rear view: the other way). Then the roll turns X into Y and the pitch moves Y (StarRollPitch); the dot's address and mask are added to StarList (StarPlot `$7B5D`).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,224 calls, 2,427,023 t-states own (1.28 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 11,051 calls, 11,939,676 t-states own (3.52 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,748 calls, 4,039,352 t-states own (0.86 %) |
| Called from | `Stardust`, `StardustNext` (tail) |
| Calls | `StarRollScale`, `StarRollPitch`, `NegateX`, `NegateY`, `MulBits`, `DivideShifted`, `DivideFrac8`, `StarRespawn` (tail), `IM2Entry` |
| Reads | `$7F6F`-`$7F7F` (`StarRoll`, `StarPitch`, `StarRollWork`, `StarFlags` and 11 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7F76`-`$7F7A` (`StarXFrac`, `StarX`, `StarYFrac`, `StarY` and 1 more); `$FFF3`-`$FFFC` (`work space $FFF3+`) |

### `StarRollScale` (`$7AA5`)

**HL = the coordinate in A times the rate in C, 4 bits (MulBits), doubled and rounded**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 569 calls, 37,745 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 106 calls, 6,483 t-states own (0.00 %) |
| Called from | `StardustFront` |
| Calls | `MulBits` |

### `StarRollPitch` (`$7ABC`)

**Apply the roll and the pitch to the dot being moved**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,179 calls, 75,701 t-states own (0.04 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 10,509 calls, 5,820,997 t-states own (1.72 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,632 calls, 125,113 t-states own (0.03 %) |
| Called from | `StardustFront` |
| Calls | `StarPlot` (tail), `StardustNext`, `NegateX`, `MulBits`, `DivideFrac8`, `StarAddress`, `StarRespawn` (tail), `IM2Entry` |
| Reads | `$7F6F`-`$7F80` (`StarRoll`, `StarPitch`, `StarRollWork`, `StarFlags` and 12 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7E8D`-`$7EDC` (`StarDots`); `$7F71`-`$7FB1` (`StarRollWork`, `StarFlags`, `StarPointer`, `StarSpeed` and 12 more); `$FFF5`-`$FFFC` (`work space $FFF5+`) |

### `StarPlot` (`$7B5D`)

**Add the dot's back buffer address and mask (StarAddress) to StarList, or respawn it off the screen**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,179 calls, 1,093,382 t-states own (0.58 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,632 calls, 1,791,187 t-states own (0.38 %) |
| Called from | `StarRollPitch` (tail) |
| Calls | `StardustNext`, `StarAddress`, `StarRespawn` (tail), `IM2Entry` |
| Reads | `$7F6F`-`$7F80` (`StarRoll`, `StarPitch`, `StarRollWork`, `StarFlags` and 12 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7E8D`-`$7EDC` (`StarDots`); `$7F73`-`$7FB1` (`StarPointer`, `StarSpeed`, `StarXFrac`, `StarX` and 10 more); `$FFF5`-`$FFFC` (`work space $FFF5+`) |

### `StardustNext` (`$7BB3`)

**The next dot: its 5 bytes back into the table, then the next one in**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,224 calls, 854,804 t-states own (0.45 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 11,050 calls, 4,269,045 t-states own (1.26 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,748 calls, 1,363,980 t-states own (0.29 %) |
| Called from | `StarRollPitch`, `StarPlot`, `StarRespawnFront` (tail), `StarRespawnMake` (tail) |
| Calls | `StardustFront` (tail), `StarPlotAll` (tail), `IM2Entry` |
| Reads | `$7E92`-`$7EDC` (`StarDots`); `$7F72`-`$7F7F` (`StarFlags`, `StarPointer`, `StarSpeed`, `StarXFrac` and 8 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7F76`-`$7F7F` (`StarXFrac`, `StarX`, `StarYFrac`, `StarY` and 5 more); `$FFF5`-`$FFFC` (`work space $FFF5+`) |

### `StarPlotAll` (`$7C92`)

**Plot the dots of this pass: XOR each listed address with its mask (StardustNext jumps here after the last dot)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 139 calls, 194,891 t-states own (0.10 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 690 calls, 907,538 t-states own (0.27 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 418 calls, 325,687 t-states own (0.07 %) |
| Called from | `StardustNext` (tail) |
| Calls | `IM2Entry` |
| Reads | `$7F80`-`$7FB1` (`StarListCount`, `JumpToggle`, `StarList`); `$C021`-`$CFFE` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$C021`-`$CFFE` (`BackBuffer`); `$FFF5`-`$FFFC` (`work space $FFF5+`) |

### `NegateX` (`$7CA7`)

**A = -A and StarSigns bit 6 flipped (the dot crossed the axis)**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 43 calls, 3,238 t-states own (0.00 %) |
| Called from | `StardustFront`, `StarRollPitch` |
| Reads | `$7F7F` (`StarSigns`) |
| Writes | `$7F7F` (`StarSigns`) |

### `NegateY` (`$7CB4`)

**A = -A and StarSigns bit 7 flipped**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 168 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 118 t-states own (0.00 %) |
| Called from | `StardustFront` |
| Reads | `$7F7F` (`StarSigns`) |
| Writes | `$7F7F` (`StarSigns`) |

### `MulBits` (`$7CC1`)

**HL = A * C, the low B bits of C (shift and add)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8,816 calls, 3,002,554 t-states own (1.59 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 44,517 calls, 15,017,972 t-states own (4.43 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 14,880 calls, 4,997,782 t-states own (1.07 %) |
| Called from | `StardustFront`, `StarRollScale`, `StarRollPitch` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF1`-`$FFFA` (`work space $FFF1+`) |

### `DivideShifted` (`$7CD5`)

**D = A:L shifted left twice divided by B (StardustFront's depth division)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,138 calls, 957,970 t-states own (0.51 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 15,727 calls, 7,131,249 t-states own (2.10 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4,258 calls, 1,906,605 t-states own (0.41 %) |
| Called from | `StardustFront` |
| Calls | `DivideFrac8`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF3`-`$FFFA` (`work space $FFF3+`) |

### `DivideFrac8` (`$7CFB`)

**D = A * 256 / B for a small A**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4,372 calls, 2,271,786 t-states own (1.20 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 22,173 calls, 11,623,879 t-states own (3.43 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 7,325 calls, 3,793,629 t-states own (0.81 %) |
| Called from | `StardustFront`, `StarRollPitch`, `DivideShifted` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF3`-`$FFFA` (`work space $FFF3+`) |

### `StarAddress` (`$7D0F`)

**DE = the back buffer address of the dot, C = its pixel mask**

The centre is (128, 63): X added or subtracted by StarSigns bit 7, Y by bit 6 (bit 6 set: the lower half, D bit 3). D starts at `$C0`, the back buffer.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,137 calls, 854,086 t-states own (0.45 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 10,095 calls, 4,091,055 t-states own (1.21 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,539 calls, 1,403,199 t-states own (0.30 %) |
| Called from | `StarRollPitch`, `StarPlot` |
| Calls | `IM2Entry` |
| Reads | `$7F77`-`$7F7F` (`StarX`, `StarYFrac`, `StarY`, `StarDepth` and 4 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF3`-`$FFFA` (`work space $FFF3+`) |

### `StarRespawn` (`$7D55`)

**A dot left the screen: make it again at random for the view**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 87 calls, 9,349 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 912 calls, 107,995 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 202 calls, 21,332 t-states own (0.00 %) |
| Called from | `StardustFront` (tail), `StarRollPitch` (tail), `StarPlot` (tail) |
| Calls | `StarRespawnFront`, `StarRespawnMake` (tail), `IM2Entry` |
| Reads | `$70E3` (`ViewIndex`); `$7105`-`$7106` (`StarSeed`); `$7F70`-`$7F7F` (`StarPitch`, `StarRollWork`, `StarFlags`, `StarPointer` and 10 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7D7A`-`$7D83` (`StarRespawnMake`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `StarRespawnFront` (`$7D68`)

**StarRespawnFront**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 103 calls, 31,217 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 861 calls, 63,209 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 218 calls, 67,425 t-states own (0.01 %) |
| Called from | `StarRespawn`, `TunnelFrameText`, `TunnelFrame` |
| Calls | `StardustNext` (tail), `StarRespawnMake`, `StarRandom`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7105`-`$7106` (`StarSeed`); `$7D7A`-`$7D83` (`StarRespawnMake`); `$7E8D`-`$7EDA` (`StarDots`); `$7F73`-`$7F74` (`StarPointer`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `StarRespawnMake` (`$7D76`)

**StarRespawnMake**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 928 calls, 229,312 t-states own (0.07 %) |
| Called from | `StarRespawn` (tail), `StarRespawnFront` |
| Calls | `StardustNext` (tail), `StarRandom` |
| Writes | `$7105`-`$7106` (`StarSeed`); `$7E8D`-`$7EDA` (`StarDots`); `$7F73`-`$7F74` (`StarPointer`) |

### `StarShuffle` (`$7E6D`)

**After a change of view: renumber the dot table (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StarRandom` (`$7E86`)

**A = the next random byte of the dot generator (HL the seed)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 309 calls, 12,144 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,783 calls, 110,804 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 654 calls, 25,667 t-states own (0.01 %) |
| Called from | `StarRespawnFront`, `StarRespawnMake` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `InSystemJump` (`$7EDE`)

**The J key: move the sun, the planet and the station `$2000` closer when nothing is near**

KeyViews `$FC0A` bit 6 (cleared here). Refused while the sun or the planet is near (SunClose `$81A4`, PlanetClose `$81A5`), while another ship is about (ShipsAbout `$9C94`) or with StationLaunch clear. Then the ships of slots 1-6 are cleared (ClearShips `$9509`), every second jump a ship may follow (JumpEncounter `$9C93`), StarWarp is set and JumpCloser moves each of the three z coordinates. No recording pressed J.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 93 calls, 8,267 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 644 calls, 57,818 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 126 calls, 11,433 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `IM2Entry` |
| Reads | `$FC0A` (`KeyViews`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FC0A` (`KeyViews`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `JumpCloser` (`$7F2D`)

**The z coordinate at IX+6..8 moves `$2000` towards the ship (a far one by `$20` pages, a near one to `$2000` on the other side)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## backbuffer

`src/game/backbuffer.asm`

### `CopyBackBuffer` (`$7FBE`)

**Copy the back buffer `$C000-$CFFF` to the screen's top two thirds**

Four CopyThird calls of 1024 bytes: the even pixel lines of the top third (`$4000`), the even lines of the middle third (`$4800`), then the odd lines of both (`$4100`, `$4900`). The buffer address is the screen address with bit 15 set. It runs 1830 times in f1, w1, d1.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 210 calls, 45,335 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 829 calls, 181,394 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 791 calls, 169,618 t-states own (0.04 %) |
| Called from | `TitleLoad`, `TitleNext`, `TunnelFrameText`, `TunnelStart`, `TunnelFrame`, `SceneLaunch` |
| Calls | `CopyThird`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `CopyThird` (`$7FE3`)

**Copy every other pixel line of one third: 8 character rows of 4 lines of 32 LDI**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 840 calls, 7,282 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,316 calls, 29,531 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,164 calls, 27,103 t-states own (0.01 %) |
| Called from | `CopyBackBuffer` |
| Calls | `CopyThirdRow` |

### `CopyThirdRow` (`$7FE5`)

**CopyThirdRow**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 6,720 calls, 201,295 t-states own (0.11 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 26,528 calls, 798,261 t-states own (0.24 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 25,312 calls, 757,593 t-states own (0.16 %) |
| Called from | `CopyThird`, `CopyThirdLine` (tail) |
| Calls | `CopyThirdLine`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF5`-`$FFF8` (`work space $FFF5+`) |

### `CopyThirdLine` (`$7FEA`)

**CopyThirdLine**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 6,720 calls, 18,154,470 t-states own (9.59 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 26,528 calls, 71,759,733 t-states own (21.14 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 25,312 calls, 68,273,199 t-states own (14.60 %) |
| Called from | `CopyThirdRow` |
| Calls | `CopyThirdRow` (tail), `IM2Entry` |
| Reads | `$C000`-`$CFFF` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$4000`-`$4FFF` (screen); `$FFEF`-`$FFFA` (`work space $FFEF+`) |

### `DashboardRestore` (`$8042`)

**Put the dashboard back if a full-screen page wiped it (the top-left byte reads `$FF`)**

The screen byte `$4000` is `$FF` only while a full page is up (ClearScreen draws the frame). Then: SoundOff `$94FE`, the page cleared (ClearScreenVector `$D036`), the side attributes of the top two thirds zeroed (columns 0 and 31), the dashboard's pixels from DashSave `$C000` and its attributes from `$5B00`, the tints again, and the scanner put in save mode (ScannerSaveMode `$98A2`).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 93 calls, 65,489 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 645 calls, 83,595 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 343 calls, 73,608 t-states own (0.02 %) |
| Called from | `TitleLoad`, `TitleNext`, `SceneLaunch` |
| Calls | `NovaTint`, `CloakRestore`, `ClearKeyBytes`, `ScannerSaveOn` (tail), `ClearScreenVector`, `IM2Entry` |
| Reads | `$4000` (screen); `$5B00`-`$5BFF` (`ScannerSave`); `$C000`-`$C7FF` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$5000`-`$5800` (screen); `$581F`-`$5AFF` (screen); `$FFF7`-`$FFFC` (`work space $FFF7+`) |

### `DashboardRestoreNow` (`$804B`)

**DashboardRestoreNow**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearView` (`$8080`)

**Clear the back buffer with the view's frame: lines 0 and 127 solid, a pixel at each side**

With interrupts off and SP at `$D000` it PUSHes 4096 bytes: the bottom line `$FF`, 126 lines of `$01` ... `$80` (the side pixels), the top line `$FF`. f1, w1, d1: 1827 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 209 calls, 5,286,864 t-states own (2.79 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 828 calls, 20,945,088 t-states own (6.17 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 790 calls, 19,983,840 t-states own (4.27 %) |
| Called from | `TitleLoad`, `TitleNext`, `TunnelFrameText`, `TunnelStart`, `TunnelFrame`, `SceneLaunch` |
| Reads | `$80D1`-`$80D2` (`ClearViewSP`) |
| Writes | `$80D1`-`$80D2` (`ClearViewSP`) |

### `SelectView` (`$80D3`)

**Change the view or the screen on the keys 1-4, ENTER, L, K, P, O, I**

KeyViews `$FC0A` bits 0-3 are 1-4: in flight the views 0-3 (SetView); docked key 1 is the launch (SceneLaunch `$93ED`) and 2-4 the screens 4-6 (CallScreen). KeyScreens `$FC08` bits 5 to 0 are I, O, P, K, L and ENTER: the screens 7-12. Nothing while TunnelLoop `$D040` is set. The keys are cleared after (SelectViewDone).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 120,160 calls, 10,700,602 t-states own (5.65 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 38,713 calls, 3,446,429 t-states own (1.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 38,410 calls, 3,419,462 t-states own (0.73 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `SelectViewDone` (tail), `CallScreen`, `SetView`, `SceneLaunch`, `IM2Entry` |
| Reads | `$7104` (`Condition`); `$D040` (`TunnelLoop`); `$FC08`-`$FC0A` (`KeyScreens`, `KeySteer`, `KeyViews`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `SelectViewDone` (`$8136`)

**Clear the view keys**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 46 calls, 2,000 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 8 calls, 360 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 8 calls, 360 t-states own (0.00 %) |
| Called from | `SelectView` (tail), `SetView` (tail) |
| Writes | `$FC08`-`$FC0A` (`KeyScreens`, `KeySteer`, `KeyViews`) |

### `CallScreen` (`$813E`)

**Call the routine A of ScreenTable `$D000` with SP at `$D000` and the sound off after**

The CALL at `$8153` is patched to `$D000` + 3 A. The screens draw full pages; the dashboard comes back with DashboardRestore.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 540 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 9 calls, 1,215 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 9 calls, 1,215 t-states own (0.00 %) |
| Called from | `ChartCursorKeys`, `SelectView` |
| Calls | `ClearKeyBytes` (tail), `ScreenGalaxy`, `ScreenLocal`, `ScreenData`, `ScreenMarket`, `CursorLeft`, `CursorDistance` |
| Reads | `$80D1`-`$80D2` (`ClearViewSP`) |
| Writes | `$80D1`-`$80D2` (`ClearViewSP`); `$8154`-`$8155` (`CallScreenCall`) |

### `CallScreenCall` (`$8153`)

**CallScreenCall**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SetView` (`$815D`)

**ViewIndex = C unless it is already (a screen 7 and up is drawn again)**

A screen's key while that screen is up does nothing; `$D03F` set takes the other way (`$819A`: below 4 a view, else ViewIndex 0).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 49 calls, 3,460 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 8 calls, 576 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 8 calls, 576 t-states own (0.00 %) |
| Called from | `SelectView` |
| Calls | `SelectViewDone` (tail) |
| Reads | `$70E3` (`ViewIndex`); `$D03F` (`TunnelOn`) |
| Writes | `$70E3` (`ViewIndex`) |

### `DashboardSave` (`$817E`)

**Save the dashboard's pixels to DashSave `$C000` and its attributes to `$5B00`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 52,592 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 52,592 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 52,592 t-states own (0.01 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `ScannerRestore`, `IM2Entry` |
| Reads | `$5000`-`$57FF` (screen); `$5A00`-`$5AFF` (screen); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$5B00`-`$5BFF` (`ScannerSave`); `$C000`-`$C7FF` (`BackBuffer`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

## dashboard

`src/game/dashboard.asm`

### `DashDistances` (`$81A9`)

**The sun's and the planet's distances on the bars, the safe zone, the compass**

The sun: with all three top bytes clear its distance (VectorLength) gives the cabin temperature (BarCabinTemp, through DistanceBand) and below `$2000` SunNear; a distance below `$4000` in the other test sets TooClose (`$82D1`). The planet: below `$0200` on all axes its distance gives the altitude (`$A0` minus it, below `$4000` TooClose) and SafeZone. The compass points at the planet, or at slot 0 (the station) when SafeZone is set and StationLaunch is not `$FF`: each of x and y divided by the distance (CompassDivide) times 8, the sign kept; then DrawCompass. f1, w1, d1: 1076 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 52,410 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 321,837 t-states own (0.09 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 194,202 t-states own (0.04 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `CompassDivide`, `CompassDivideSigned`, `VectorLengthAbs`, `VectorLength`, `DrawCompass` (tail), `IM2Entry` |
| Reads | `$6050` (`ShipSlots`); `$7109`-`$711D` (`SunPosition`, `PlanetPosition`, `DrawChartCircleVector`, `SafeZone` and 1 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$711C` (`SafeZone`); `$81A4`-`$81A8` (`DashWork`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `CompassDivide` (`$8271`)

**A = the word at IX divided by DE, times 8, with the sign of IX+1**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 184 calls, 29,884 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 238 calls, 13,824 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 682 calls, 109,880 t-states own (0.02 %) |
| Called from | `DashDistances` |
| Calls | `CompassDivideScale` (tail), `Divide16Vector`, `IM2Entry` |
| Reads | `$6048`-`$604D` (`ShipSlots`) |

### `CompassDivideSigned` (`$82B0`)

**The same for a 3-byte coordinate at IX (the sign bit cleared first)**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,048 calls, 71,857 t-states own (0.02 %) |
| Called from | `DashDistances` |
| Calls | `CompassDivideScale` |
| Reads | `$7110`-`$7115` (`PlanetPosition`) |

### `CompassDivideScale` (`$82BB`)

**CompassDivideScale**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,286 calls, 134,115 t-states own (0.04 %) |
| Called from | `CompassDivide` (tail), `CompassDivideSigned` |
| Calls | `Divide16Vector` |
| Reads | `$604A`-`$604D` (`ShipSlots`); `$7112`-`$7115` (`PlanetPosition`) |

### `SetTooClose` (`$82D1`)

**TooClose = 1**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DistanceBand` (`$82D7`)

**HL = 1.5 * distance; set Condition yellow below `$50` pages, red flashing from `$78`**

Known from the code only: no recording came that close.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadVector` (`$8302`)

**DE, BC, HL = the three top words of the 9-byte vector at IX**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 11,782 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 89,417 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 45,282 t-states own (0.01 %) |
| Called from | `VectorLengthAbs`, `VectorLength` |
| Reads | `$6048`-`$604F` (`ShipSlots`); `$7111`-`$7118` (`PlanetPosition`) |

### `VectorLengthAbs` (`$8315`)

**VectorLength of the vector at IX with the three signs cleared**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 524 calls, 31,440 t-states own (0.01 %) |
| Called from | `DashDistances` |
| Calls | `LoadVector`, `VectorLengthShift` (tail) |

### `VectorLength` (`$8322`)

**HL = the length of the vector at IX: sqrt(x^2 + y^2 + z^2) on the top bytes**

The three words are shifted left together until one would overflow (A counts the shifts), the top bytes squared from the table at `$BE00` (Square `$87BF`) and summed, the square root taken (SqrtVector `$9C86`), and the result shifted back.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 89,692 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 119 calls, 2,856 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 266,762 t-states own (0.06 %) |
| Called from | `DashDistances` |
| Calls | `LoadVector`, `VectorLengthShift`, `Square`, `SquareRootVector`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF7`-`$FFFA` (`work space $FFF7+`) |

### `VectorLengthShift` (`$8327`)

**VectorLengthShift**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 553,278 t-states own (0.16 %) |
| Called from | `VectorLengthAbs` (tail), `VectorLength` |
| Calls | `Square`, `SquareRootVector` |

### `DrawCompass` (`$8390`)

**Draw the compass dial and its dot (the solid dot in front, the ring behind) in a space view**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 78,675 t-states own (0.04 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 580,971 t-states own (0.17 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 292,636 t-states own (0.06 %) |
| Called from | `DashDistances` (tail) |
| Calls | `NextLineDown`, `DrawCompassDialArt`, `IM2Entry` |
| Reads | `$5056`-`$5157` (screen); `$5256`-`$5257` (screen); `$5356`-`$5357` (screen); `$5456`-`$5457` (screen); `$5556`-`$5557` (screen); `$5656`-`$5657` (screen); 5 more ranges |
| Writes | `$5056`-`$5157` (screen); `$5256`-`$5257` (screen); `$5356`-`$5357` (screen); `$5456`-`$5457` (screen); `$5556`-`$5557` (screen); `$5656`-`$5657` (screen); 3 more ranges |

### `NextLineDown` (`$8445`)

**HL = the next pixel line's row start when L passed a character row (the screen's layout)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 283 calls, 12,735 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,136 calls, 96,215 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,573 calls, 70,842 t-states own (0.02 %) |
| Called from | `DrawCompass`, `DrawCompassDialArt`, `DrawScanner` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF7`-`$FFFA` (`work space $FFF7+`) |

### `NextLineUp` (`$844F`)

**The same going up (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawCompassDialArt` (`$8459`)

**Copy the 24-line dial (CompassDial) to `$5035`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 255,273 t-states own (0.13 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 1,796,834 t-states own (0.53 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 963,965 t-states own (0.21 %) |
| Called from | `DrawCompass` |
| Calls | `NextLineDown`, `IM2Entry` |
| Reads | `$8491`-`$84D8` (`CompassDial`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$5035`-`$5177` (screen); `$5235`-`$5277` (screen); `$5335`-`$5377` (screen); `$5435`-`$5477` (screen); `$5535`-`$5577` (screen); `$5635`-`$5677` (screen); 2 more ranges |

### `DrawBars` (`$84D9`)

**Redraw every dashboard bar whose value changed**

11 solid bars (DrawBar) then the roll and pitch markers (DrawMarker, with BarMarkerMode 1), each at its address of BarAddresses. f1, w1, d1: 1079 runs, 500 bars drawn.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 93 calls, 114,513 t-states own (0.06 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 644 calls, 799,031 t-states own (0.24 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 342 calls, 444,907 t-states own (0.10 %) |
| Called from | `TitleLoad`, `TitleNext`, `SceneLaunch` |
| Calls | `DrawMarker`, `DrawBar`, `IM2Entry` |
| Reads | `$70E7`-`$7100` (`BarDrawn`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$70E7`-`$70FF` (`BarDrawn`); `$8523` (`BarMarkerMode`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `DrawMarker` (`$8540`)

**Draw a roll or pitch marker: a 3-pixel mark at the value**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 132 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 39 calls, 2,574 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 16 calls, 1,056 t-states own (0.00 %) |
| Called from | `DrawBars` |
| Calls | `DrawBarRows` (tail) |
| Writes | `$856D` (`DrawBarRows`); `$8597` (`DrawBarRows`); `$85B9` (`DrawBarRows`) |

### `DrawBar` (`$854F`)

**Draw a bar: 5 bytes wide, A pixels long, 3 pixel lines**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 9 calls, 450 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 123 calls, 6,169 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 311 calls, 15,550 t-states own (0.00 %) |
| Called from | `DrawBars` |
| Calls | `DrawBarRows`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$856D` (`DrawBarRows`); `$8597` (`DrawBarRows`); `$85B9` (`DrawBarRows`); `$FFF5`-`$FFF6` (`work space $FFF5+`) |

### `DrawBarRows` (`$855B`)

**DrawBarRows**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 11 calls, 12,016 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 162 calls, 172,119 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 327 calls, 356,444 t-states own (0.08 %) |
| Called from | `DrawMarker` (tail), `DrawBar` |
| Calls | `BarByte`, `IM2Entry` |
| Reads | `$8523`-`$853D` (`BarMarkerMode`, `BarAddresses`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$5123`-`$53FC` (screen); `$5423`-`$54FC` (screen); `$5523`-`$55FC` (screen); `$FFF3`-`$FFF6` (`work space $FFF3+`) |

### `BarByte` (`$8606`)

**Write the bar's edge byte C; for a marker keep the frame pixel at the left**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 55 calls, 2,235 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 535 calls, 24,764 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,175 calls, 45,169 t-states own (0.01 %) |
| Called from | `DrawBarRows` |
| Calls | `IM2Entry` |
| Reads | `$8523` (`BarMarkerMode`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$5124`-`$52FC` (screen); `$5324`-`$537A` (screen); `$5399`-`$53FC` (screen); `$5424`-`$547A` (screen); `$5499`-`$54FC` (screen); `$5524`-`$557A` (screen); 2 more ranges |

## circles

`src/game/circles.asm`

### `OutlineRunUpRight` (`$862B`)

**Plot an outline run: up the screen, x growing (the alternate registers step it)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 24 calls, 2,088 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 70 calls, 6,090 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 70 calls, 6,090 t-states own (0.00 %) |
| Called from | `FillClipped` |
| Calls | `OutlinePlotTop` (tail) |
| Reads | `$8629` (`CircleMode`) |
| Writes | `$8628` (`RunRight`) |

### `OutlineRunUpLeft` (`$8643`)

**Plot an outline run: up the screen, x shrinking**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 24 calls, 2,016 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 70 calls, 5,880 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 70 calls, 5,880 t-states own (0.00 %) |
| Called from | `FillClipped` |
| Calls | `OutlinePlotTop` (tail) |
| Reads | `$8629` (`CircleMode`) |
| Writes | `$8628` (`RunRight`) |

### `OutlineRunDownRight` (`$865A`)

**The same, down the screen, x growing (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OutlineRunDownLeft` (`$8672`)

**The same, down the screen, x shrinking (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ArcRunRight` (`$8689`)

**Plot one arc run of the outline, x growing (31504 instructions in the recordings)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 329 calls, 28,642 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,440 calls, 125,318 t-states own (0.04 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,095 calls, 95,379 t-states own (0.02 %) |
| Called from | `CircleArcs` (tail) |
| Calls | `OutlinePlotSide` (tail), `IM2Entry` |
| Reads | `$8629` (`CircleMode`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$8628` (`RunRight`); `$FFED`-`$FFF4` (`work space $FFED+`) |

### `ArcRunLeft` (`$86A1`)

**Plot one arc run, x shrinking**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 329 calls, 27,636 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,442 calls, 121,128 t-states own (0.04 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,095 calls, 91,980 t-states own (0.02 %) |
| Called from | `CircleArcs`, `FillCorner` |
| Calls | `OutlinePlotSide` (tail) |
| Reads | `$8629` (`CircleMode`) |
| Writes | `$8628` (`RunRight`) |

### `OutlineEdgeUp` (`$86B8`)

**Plot an edge run going up, filled or outlined by CircleMode**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 24 calls, 840 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 70 calls, 2,469 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 70 calls, 2,450 t-states own (0.00 %) |
| Called from | `FillClipped` |
| Calls | `OutlineRunUp` (tail), `IM2Entry` |
| Reads | `$8629` (`CircleMode`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF3`-`$FFF4` (`work space $FFF3+`) |

### `OutlineEdgeDown` (`$86C4`)

**Plot an edge run going down**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 24 calls, 840 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 70 calls, 2,450 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 70 calls, 2,450 t-states own (0.00 %) |
| Called from | `FillClipped` |
| Calls | `OutlineRunDown` (tail) |
| Reads | `$8629` (`CircleMode`) |

### `DrawCircleDI` (`$86D0`)

**Draw a filled circle with interrupts off (the sun and HitFlash: k2's explosion drew 45; no grabbed frame shows a sun's disc)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawCircle` (`$86DE`)

**Draw an outlined circle (the planet), radius 9 or more**

f1, w1, d1: 899 calls, 2697 instructions. CircleMode = 1, then DrawCircleShape.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 105 calls, 2,625 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 656 calls, 16,400 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 138 calls, 3,450 t-states own (0.00 %) |
| Called from | `DrawSunPlanet` (tail), `DrawChartCircle` |
| Calls | `DrawCircleOutline` |
| Reads | `$861D` (`CircleRadius`) |

### `DrawCircleOutline` (`$86E4`)

**DrawCircleOutline**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 353 calls, 18,003 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,683 calls, 85,852 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,165 calls, 59,415 t-states own (0.01 %) |
| Called from | `DrawCircle`, `TunnelFrameText`, `TunnelFrame` |
| Calls | `DrawCircleShape`, `IM2Entry` |
| Writes | `$8629` (`CircleMode`) |

### `DrawCircleShape` (`$86EE`)

**Draw the circle CircleX, CircleY, CircleQuadrant, CircleRadius: sort it by the view's edges**

The screen centre is (128, 64): CircleScreenX `$8621` = 128 +/- CircleX, CircleScreenY `$8620` = 64 +/- CircleY by the quadrant bits; bits 2 and 3 of the quadrant (set by the projection) mark a centre off the view. From where the circle meets the edges (x against `$78`, y against `$40`) it goes to CircleArcs (all inside, 3028 of 3201 calls) or a clipped filler.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 353 calls, 96,269 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,683 calls, 457,326 t-states own (0.13 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,165 calls, 316,781 t-states own (0.07 %) |
| Called from | `DrawCircleOutline` |
| Calls | `Square`, `CircleArcs` (tail), `FillClipped` (tail), `FillCorner` (tail), `IM2Entry` |
| Reads | `$861A`-`$861D` (`CircleY`, `CircleX`, `CircleQuadrant`, `CircleRadius`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$861E`-`$8621` (`CircleRowOffset`, `CircleColOffset`, `CircleScreenY`, `CircleScreenX`); `$FFEF`-`$FFFA` (`work space $FFEF+`) |

### `Square` (`$87BF`)

**HL = A * A from the table of squares (`$BE00` low bytes, `$BF00` high bytes)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 700 calls, 42,000 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,893 calls, 173,580 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,701 calls, 222,079 t-states own (0.05 %) |
| Called from | `VectorLength`, `VectorLengthShift`, `DrawCircleShape`, `HalfChord`, `DrawScanner` |
| Calls | `IM2Entry` |
| Reads | `$BE00`-`$BE40` (`SquaresLow`); `$BE60` (`SquaresLow`); `$BE78`-`$BF40` (`SquaresLow`, `SquaresHigh`); `$BF60` (`SquaresHigh`); `$BF78`-`$BFFF` (`SquaresHigh`) |

### `CircleArcs` (`$87C8`)

**A circle wholly inside the view: the four quarter arcs**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 329 calls, 20,088 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,440 calls, 87,859 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,095 calls, 66,833 t-states own (0.01 %) |
| Called from | `DrawCircleShape` (tail) |
| Calls | `ArcRunRight` (tail), `ArcRunLeft`, `CircleArc`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEF`-`$FFF0` (`work space $FFEF+`) |

### `CircleArc` (`$87D4`)

**One quarter arc from the circle's top or bottom row, by the screen address of its first point**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 658 calls, 92,158 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,880 calls, 403,352 t-states own (0.12 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,190 calls, 306,809 t-states own (0.07 %) |
| Called from | `CircleArcs` |
| Calls | `PointLeft`, `PointRight` (tail), `IM2Entry` |
| Reads | `$861C`-`$8621` (`CircleQuadrant`, `CircleRadius`, `CircleRowOffset`, `CircleColOffset` and 2 more); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFED`-`$FFF4` (`work space $FFED+`) |

### `FillClipped` (`$87FE`)

**A circle cut by the view's top or bottom: the rows inside, each from its half width**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 24 calls, 7,560 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 70 calls, 22,050 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 70 calls, 22,050 t-states own (0.00 %) |
| Called from | `DrawCircleShape` (tail) |
| Calls | `OutlineRunUpRight`, `OutlineRunUpLeft`, `OutlineEdgeUp`, `OutlineEdgeDown`, `SpanStep`, `SpanStart`, `HalfChord` |
| Reads | `$861C`-`$8622` (`CircleQuadrant`, `CircleRadius`, `CircleRowOffset`, `CircleColOffset` and 3 more) |
| Writes | `$8622` (`ClipHalfWidth`) |

### `FillCorner` (`$893F`)

**A circle cut by two edges**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 630 t-states own (0.00 %) |
| Called from | `DrawCircleShape` (tail) |
| Calls | `ArcRunLeft`, `PointLeft`, `PointRight`, `HalfChord` |
| Reads | `$861C`-`$8622` (`CircleQuadrant`, `CircleRadius`, `CircleRowOffset`, `CircleColOffset` and 3 more) |
| Writes | `$8620`-`$8622` (`CircleScreenY`, `CircleScreenX`, `ClipHalfWidth`) |

### `SpanEndLeft` (`$8985`)

**One end of a row run, the left side (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SpanEndRight` (`$89A1`)

**The other end (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ArcSeed` (`$89C3`)

**The alternate registers for an arc: the Bresenham terms from the centre (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PointLeft` (`$89D4`)

**HL = the back buffer address of point (C, A), C = the mask of its leftmost pixel**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 658 calls, 47,376 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,882 calls, 207,542 t-states own (0.06 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,190 calls, 157,699 t-states own (0.03 %) |
| Called from | `CircleArc`, `FillCorner` |
| Calls | `MaskRight` (tail), `IM2Entry` |
| Reads | `$8629` (`CircleMode`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF1`-`$FFF2` (`work space $FFF1+`) |

### `PointRight` (`$89EF`)

**HL = the address of point (C, A), the mask of its rightmost pixel (B kept in CirclePointX)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 658 calls, 82,250 t-states own (0.04 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,882 calls, 360,383 t-states own (0.11 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,190 calls, 273,883 t-states own (0.06 %) |
| Called from | `CircleArc` (tail), `FillCorner` |
| Calls | `MaskLeft` (tail), `IM2Entry` |
| Reads | `$8629` (`CircleMode`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$8627` (`CirclePointX`); `$FFF3`-`$FFF8` (`work space $FFF3+`) |

### `SpanStep` (`$8A16`)

**The run's Bresenham step from the half width at the row**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 48 calls, 3,360 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 140 calls, 9,800 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 140 calls, 9,800 t-states own (0.00 %) |
| Called from | `FillClipped` |
| Reads | `$861E`-`$8622` (`CircleRowOffset`, `CircleColOffset`, `CircleScreenY`, `CircleScreenX` and 1 more) |

### `SpanStart` (`$8A25`)

**The run's start address and mask (outline mode goes to OutlineSpanStart `$8FF9`)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 48 calls, 1,296 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 140 calls, 3,780 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 140 calls, 3,780 t-states own (0.00 %) |
| Called from | `FillClipped` |
| Calls | `OutlineSpanStart` (tail) |
| Reads | `$8629` (`CircleMode`) |

### `HalfChord` (`$8ACD`)

**A = sqrt(radius^2 - row^2): the half width of the circle at a row, by bisection over the squares**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 24 calls, 20,310 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 72 calls, 60,888 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 70 calls, 59,164 t-states own (0.01 %) |
| Called from | `FillClipped`, `FillCorner` |
| Calls | `Square`, `IM2Entry` |
| Reads | `$8625`-`$8626` (`HalfChordTarget`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$8625`-`$8626` (`HalfChordTarget`); `$FFE7`-`$FFEE` (`work space $FFE7+`) |

### `FillPushes1` (`$8B33`)

**A chain of 16 PUSH AF: FillSpan1's patched JR enters it to write the run's whole bytes**

Known from the code only, like the five chains after it: the filled circle (the sun) was never drawn in a recording. The JR before each chain is patched with 16 minus the number of words; AF is `$FFFF` (FillWord `$8FB6`) and SP the run's end.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillPushes2` (`$8BD4`)

**The second chain of 16 PUSH AF**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillSpanTest2` (`$8BF8`)

**Test a filled run against the view, then fill it (the second engine)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillPushes3` (`$8C32`)

**The third chain**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillPushes4` (`$8CD4`)

**The fourth chain**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillSpanTest3` (`$8CF8`)

**Test a filled run against the view, then fill it (the third engine)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillPushes5` (`$8D34`)

**The fifth chain**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillPushes6` (`$8DCA`)

**The sixth chain**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CircleLineUp` (`$8DEE`)

**HL one pixel line up the back buffer (a character row boundary through CircleRowUp)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 717 calls, 18,115 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,464 calls, 88,344 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,246 calls, 56,742 t-states own (0.01 %) |
| Called from | `OutlinePlotTop`, `OutlinePixels` |
| Calls | `CircleRowUp`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEB`-`$FFF0` (`work space $FFEB+`) |

### `CircleRowUp` (`$8DF3`)

**DE one character row up**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,638 calls, 108,257 t-states own (0.06 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4,374 calls, 289,680 t-states own (0.09 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,715 calls, 245,420 t-states own (0.05 %) |
| Called from | `CircleLineUp`, `OutlinePixel` |
| Calls | `CircleAbort` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEF`-`$FFF0` (`work space $FFEF+`) |

### `CircleLineDown` (`$8E08`)

**HL one pixel line down**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 709 calls, 17,780 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,429 calls, 86,922 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,222 calls, 55,600 t-states own (0.01 %) |
| Called from | `OutlinePlotTop`, `OutlinePixels` |
| Calls | `CircleRowDown` |

### `CircleRowDown` (`$8E0D`)

**DE one character row down**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,346 calls, 89,291 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,425 calls, 228,098 t-states own (0.07 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,765 calls, 183,847 t-states own (0.04 %) |
| Called from | `CircleLineDown`, `OutlinePixel` |
| Calls | `CircleAbort` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF1`-`$FFF6` (`work space $FFF1+`) |

### `CircleAbort` (`$8E22`)

**Leave the circle code from inside a run: SP back from CircleSP**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 246 calls, 12,300 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 383 calls, 19,150 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 394 calls, 19,700 t-states own (0.00 %) |
| Called from | `CircleRowUp` (tail), `CircleRowDown` (tail) |
| Reads | `$8623`-`$8624` (`CircleSP`) |

### `DrawChartCircle` (`$8E29`)

**Draw the chart's range circle: the circle code patched for the screen, then back**

The centre is ChartCursorX / ChartCursorY (`$D051`, `$D052`) against the chart's centre (128, 96), the radius ChartRadius `$D053`. CirclePatchSites `$8ECD` lists 32 code bytes; ChartPatch `$8E8D` holds their values for the chart, ViewPatch `$8EAD` the values for the 3D view. d1: 4 runs (the charts).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 6,052 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 3,026 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 3,026 t-states own (0.00 %) |
| Called from | `DrawChartCircleVector` (tail) |
| Calls | `DrawCircle` |
| Reads | `$8623`-`$862A` (`CircleSP`, `HalfChordTarget`, `CirclePointX`, `RunRight` and 2 more); `$8E8D`-`$8ECC` (`ChartPatch`, `ViewPatch`); `$D051`-`$D053` (`CrossX`, `CrossY`, `ChartRadius`) |
| Writes | `$861A`-`$8624` (`CircleY`, `CircleX`, `CircleQuadrant`, `CircleRadius` and 6 more); `$86FB`-`$8744` (`DrawCircleShape`); `$87FF`-`$8804` (`FillClipped`); `$889A` (`FillClipped`); `$89B3`-`$8A1B` (`SpanEndRight`, `ArcSeed`, `PointLeft`, `PointRight` and 1 more); `$8DFE`-`$8E18` (`CircleRowUp`, `CircleLineDown`, `CircleRowDown`); 3 more ranges |

### `HitFlash` (`$8F0D`)

**Draw the growing red circles of the ships just hit, on the screen (HitFlashes `$9C96`)**

With HitFlashes set (the explosions; k2 frame 2572 on): the circle code is patched for the screen (CircleBase), and each slot whose flags (+`$20`) have bits 4 and 5 set gets 15 filled circles growing by 2 from its screen position (+`$1C`-+`$1F`) between two attribute fills (FillAttrsVector, L = `$0A` then `$0F`); then the base goes back to the back buffer.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 99,160 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 144,077 t-states own (0.04 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 367,966 t-states own (0.08 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `CircleBase`, `IM2Entry` |
| Reads | `$6068`-`$608F` (`ShipSlots`); `$60B6` (`ShipSlots`); `$60DD` (`ShipSlots`); `$6104` (`ShipSlots`); `$612B` (`ShipSlots`); `$6152` (`ShipSlots`); 3 more ranges |
| Writes | `$8A7D` (`SpanStart`); `$8F9B`-`$8FA6` (`CircleBase`); `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `CircleBase` (`$8F88`)

**Patch the circle code's screen base: HL and A the new page bytes**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 184 calls, 37,720 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 240 calls, 49,219 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 682 calls, 139,829 t-states own (0.03 %) |
| Called from | `HitFlash` |
| Calls | `IM2Entry` |
| Writes | `$89DA`-`$89DB` (`PointLeft`); `$89FB`-`$89FC` (`PointRight`); `$8A40`-`$8A41` (`SpanStart`); `$8A8B`-`$8A8C` (`SpanStart`); `$8AC8` (`SpanStart`); `$8B02`-`$8B09` (`HalfChord`); 4 more ranges |

### `OutlineEdgeStart` (`$8FB8`)

**The outline mode's edge set-up at a cell start (known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MaskRight` (`$8FE3`)

**B = the single pixel mask of column A (rotating right)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 658 calls, 86,667 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,882 calls, 347,525 t-states own (0.10 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,190 calls, 270,003 t-states own (0.06 %) |
| Called from | `PointLeft` (tail) |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFED`-`$FFF6` (`work space $FFED+`) |

### `MaskLeft` (`$8FED`)

**C = the single pixel mask of column CirclePointX (rotating left)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 658 calls, 90,525 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,882 calls, 370,036 t-states own (0.11 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,190 calls, 295,676 t-states own (0.06 %) |
| Called from | `PointRight` (tail) |
| Calls | `IM2Entry` |
| Reads | `$8627` (`CirclePointX`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFED`-`$FFF8` (`work space $FFED+`) |

### `OutlineSpanStart` (`$8FF9`)

**The outline mode's run set-up**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 48 calls, 2,208 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 140 calls, 6,440 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 140 calls, 6,440 t-states own (0.00 %) |
| Called from | `SpanStart` (tail) |

### `OutlineRunUp` (`$9004`)

**Plot an outline run going up (the stepping in the alternate registers)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 24 calls, 62,006 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 70 calls, 180,218 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 70 calls, 180,180 t-states own (0.04 %) |
| Called from | `OutlineEdgeUp` (tail) |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE9`-`$FFF0` (`work space $FFE9+`) |

### `OutlineRunDown` (`$9032`)

**Plot an outline run going down**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 24 calls, 60,145 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 70 calls, 174,777 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 70 calls, 174,796 t-states own (0.04 %) |
| Called from | `OutlineEdgeDown` (tail) |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE9`-`$FFF0` (`work space $FFE9+`) |

### `OutlinePlotTop` (`$9060`)

**Plot the outline from the top of the circle (the first engine)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 48 calls, 7,712 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 140 calls, 22,773 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 140 calls, 22,754 t-states own (0.00 %) |
| Called from | `OutlineRunUpRight` (tail), `OutlineRunUpLeft` (tail) |
| Calls | `CircleLineUp`, `CircleLineDown`, `OutlineStep` (tail), `IM2Entry` |
| Reads | `$8628` (`RunRight`); `$C441` (`BackBuffer`); `$CCA1` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$8623`-`$8624` (`CircleSP`); `$C441` (`BackBuffer`); `$CCA1` (`BackBuffer`); `$FFF1`-`$FFF2` (`work space $FFF1+`) |

### `OutlinePlotSide` (`$90FB`)

**Plot the outline along a side (5730 runs)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 658 calls, 55,601 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,882 calls, 243,543 t-states own (0.07 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,190 calls, 185,112 t-states own (0.04 %) |
| Called from | `ArcRunRight` (tail), `ArcRunLeft` (tail) |
| Calls | `OutlinePixel`, `IM2Entry` |
| Reads | `$8628` (`RunRight`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$8623`-`$8624` (`CircleSP`); `$FFF1`-`$FFF4` (`work space $FFF1+`) |

### `OutlinePixel` (`$9117`)

**OR the pixel C into (HL), step the row; the outline's inner loop (1787849 instructions)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8,975 calls, 3,576,404 t-states own (1.89 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 26,341 calls, 9,252,710 t-states own (2.73 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 21,603 calls, 7,709,145 t-states own (1.65 %) |
| Called from | `OutlinePlotSide`, `OutlineStep` (tail) |
| Calls | `CircleRowUp`, `CircleRowDown`, `OutlineStepX`, `IM2Entry` |
| Reads | `$40C5`-`$5751` (screen); `$8628` (`RunRight`); `$C002`-`$CFFD` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$40C5`-`$5751` (screen); `$C002`-`$CFFD` (`BackBuffer`); `$FFEB`-`$FFF8` (`work space $FFEB+`) |

### `OutlineStepX` (`$9144`)

**Rotate the mask: one pixel along x**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8,745 calls, 168,390 t-states own (0.09 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 26,006 calls, 497,572 t-states own (0.15 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 21,257 calls, 403,678 t-states own (0.09 %) |
| Called from | `OutlinePixel` |
| Calls | `OutlineStepY`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEB`-`$FFF4` (`work space $FFEB+`) |

### `OutlineStepY` (`$9148`)

**The Bresenham term for a step in y**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8,745 calls, 166,155 t-states own (0.09 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 26,006 calls, 494,190 t-states own (0.15 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 21,257 calls, 403,940 t-states own (0.09 %) |
| Called from | `OutlineStepX` |
| Calls | `OutlineStep`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF1`-`$FFF4` (`work space $FFF1+`) |

### `OutlineStep` (`$914B`)

**The Bresenham decision: a step in x, y or both**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8,761 calls, 293,591 t-states own (0.16 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 26,054 calls, 885,903 t-states own (0.26 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 21,305 calls, 722,118 t-states own (0.15 %) |
| Called from | `OutlinePlotTop` (tail), `OutlineStepY` |
| Calls | `OutlinePixel` (tail), `OutlinePixels` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFED`-`$FFF6` (`work space $FFED+`) |

### `OutlinePixels` (`$917B`)

**Plot the two mirrored pixels of a row and step (442222 instructions)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 444 calls, 829,677 t-states own (0.44 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,595 calls, 3,812,470 t-states own (1.12 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,892 calls, 2,750,447 t-states own (0.59 %) |
| Called from | `OutlineStep` (tail) |
| Calls | `CircleLineUp`, `CircleLineDown`, `IM2Entry` |
| Reads | `$4088`-`$4983` (screen); `$4BE1`-`$5770` (screen); `$8623`-`$8628` (`CircleSP`, `HalfChordTarget`, `CirclePointX`, `RunRight`); `$C009`-`$CFF1` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$4088`-`$4983` (screen); `$4BE1`-`$5770` (screen); `$C009`-`$CFF3` (`BackBuffer`); `$FFEB`-`$FFF6` (`work space $FFEB+`) |

## tunnel

`src/game/tunnel.asm`

### `TunnelFrameText` (`$928C`)

**The view's texts (ViewTexts), then a tunnel frame while TunnelOn is set**

The flight loop's and the scenes' per-frame call. 1220 runs over f1, w1, d1.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 48 calls, 88,346 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 48 calls, 2,448 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 48 calls, 2,448 t-states own (0.00 %) |
| Called from | `SceneLaunch` |
| Calls | `StarRespawnFront`, `CopyBackBuffer`, `ClearView`, `DrawCircleOutline`, `TunnelFrame` (tail), `TunnelDivide`, `ViewTextsVector` |
| Reads | `$7105`-`$7106` (`StarSeed`); `$93D0`-`$93D2` (`TunnelRingCount`, `TunnelRingsLeft`, `TunnelTop`); `$93E3`-`$93EA` (`LaunchRings`); `$D03F`-`$D040` (`TunnelOn`, `TunnelLoop`) |
| Writes | `$70E6` (`SpeedRate`); `$7D69`-`$7D6E` (`StarRespawnFront`); `$7E0E` (`StarRespawnMake`); `$861A`-`$861D` (`CircleY`, `CircleX`, `CircleQuadrant`, `CircleRadius`); `$9318` (`TunnelFrame`); `$93D1`-`$93D2` (`TunnelRingsLeft`, `TunnelTop`); 2 more ranges |

### `TunnelStart` (`$9296`)

**Start the hyperspace tunnel when TunnelLoop is set: the controls and the ships reset, 16 rings**

In witch space (WitchSpace non-zero) slot 0's energy is cleared and ship action 1 runs first. Then the view cleared, TunnelTop `$42`, the jump sound (SoundJump), the 16 rings of TunnelRings, the last frame at 1 and the end at TunnelStop: `$42` frames in one call. 2 runs (the jumps of f1 and w1).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 2,576 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 18,218 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 9,815 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `CopyBackBuffer`, `ClearView`, `TunnelFrame`, `ResetControls`, `ClearShips`, `SoundJump`, `ShipActionVector` |
| Reads | `$7103` (`WitchSpace`); `$D040` (`TunnelLoop`) |
| Writes | `$606A` (`ShipSlots`); `$92FA`-`$92FB` (`TunnelFrame`); `$9326`-`$932B` (`TunnelFrame`); `$93D0`-`$93D2` (`TunnelRingCount`, `TunnelRingsLeft`, `TunnelTop`) |

### `TunnelFrame` (`$92D6`)

**Draw the tunnel: every ring one step nearer, then show the frame**

With TunnelLoop set (the jump, the first frames of the launch and the dock) the frames loop here until TunnelTop passes the last frame; without it each call draws one frame and TunnelCount counts it.

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 49 calls, 260,492 t-states own (0.08 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 49 calls, 260,568 t-states own (0.06 %) |
| Called from | `TunnelFrameText` (tail), `TunnelStart` |
| Calls | `StarRespawnFront`, `CopyBackBuffer`, `ClearView`, `DrawCircleOutline`, `TunnelDivide`, `TunnelDone` (tail), `IM2Entry` |
| Reads | `$7105`-`$7106` (`StarSeed`); `$93D0`-`$93EA` (`TunnelRingCount`, `TunnelRingsLeft`, `TunnelTop`, `TunnelRings` and 1 more); `$D040` (`TunnelLoop`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$70E6` (`SpeedRate`); `$7D69`-`$7D6E` (`StarRespawnFront`); `$7E0E` (`StarRespawnMake`); `$861A`-`$861D` (`CircleY`, `CircleX`, `CircleQuadrant`, `CircleRadius`); `$9318` (`TunnelFrame`); `$93D1`-`$93EA` (`TunnelRingsLeft`, `TunnelTop`, `TunnelRings`, `LaunchRings`); 2 more ranges |

### `TunnelCount` (`$9337`)

**One frame of a tunnel drawn a frame a call: TunnelEnd when TunnelTop reaches 0**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TunnelStop` (`$9341`)

**The jump's tunnel over: both flags off, the 16 rings moved back by `$BE`, the view cleared and shown**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TunnelOver` (`$935E`)

**The launch's first frames over: TunnelLoop off, the stardust made again**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TunnelOff` (`$9364`)

**The dock's first frames over: TunnelLoop off (reached by a jump: dk, gx, m1, m2 docked)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TunnelEnd` (`$9369`)

**TunnelOn off and the 8 launch rings moved back by `$C0` for the next time**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StarsRenew` (`$937B`)

**Make all 16 dots again ahead of the ship (StarRespawnFront patched for it), speed 7**

StarRespawnFront's two range bytes become `$83` (from `$BF` and `$9F`) and the RET at its tail (`$7E0E`) replaces the JP, so each call places one dot from StarSeed; the bytes go back after the 16 dots.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TunnelDivide` (`$93AC`)

**C = A * 256 / B (A < B): a ring's radius from its distance**

A restoring division, eight bits of quotient; C starts at `$FE` so the carry out of RL C after eight bits ends it. 3648 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 512 calls, 202,264 t-states own (0.11 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,568 calls, 625,462 t-states own (0.18 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,568 calls, 625,424 t-states own (0.13 %) |
| Called from | `TunnelFrameText`, `TunnelFrame` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF3`-`$FFFA` (`work space $FFF3+`) |

### `TunnelDone` (`$93C0`)

**After the jump: the attributes white unless in the nova system (NovaMission `$D081`), LastSunRadius 0, the arrival sound**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 68 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 68 t-states own (0.00 %) |
| Called from | `TunnelFrame` (tail) |
| Calls | `FillAttrsVector`, `SoundArrive` (tail) |
| Reads | `$D081` (`NovaMission`) |
| Writes | `$7583` (`LastSunRadius`) |

### `SceneLaunch` (`$93ED`)

**The launch from the station (Condition 0) or the dock (in flight), with the tunnel**

Both: the 8 launch rings, TunnelTop `$40`, the last frame `$30`, TunnelOn and TunnelLoop set.

The launch (d1 at Lave, 3 runs over f1, w1, d1): Condition green, the views reset, the dashboard drawn and reset (ResetFlight `$9946`), the planet ahead (`$80` at z+1 of PlanetPosition, the sun's sign flipped), slot 0 the station just behind the ship (z = -`$F0`, its three axes the unit ones, `$7F`) with energy `$F0`, the bars, 16 frames in the first call (TunnelOver), 36 frames of the tunnel over the stardust and 11 with the sun and the planet.

The dock (dk docked by hand at frame 2190 and by the computer at 3408; gx, m1, m2 docked too): speed `$0C`, no roll or pitch, the controls held, the first call's frames end at TunnelOff, then 47 frames, Condition docked, the dashboard saved, the controls cleared, the mission screens (ArrivalScreens), PirateStation and the status screen (CallScreen 7).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 5,870 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 5,870 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 5,870 t-states own (0.00 %) |
| Called from | `SelectView` |
| Calls | `NovaSunGrows`, `DrawSunPlanet`, `MoveSunPlanet`, `Stardust`, `CopyBackBuffer`, `DashboardRestore`, `ClearView`, `DrawBars`, `TunnelFrameText`, `ResetControls`, `ZeroBytes`, `ClearShips`, `SoundLaunch`, `ResetFlight` |
| Reads | `$7103`-`$710F` (`WitchSpace`, `Condition`, `StarSeed`, `SunPosition`) |
| Writes | `$604E`-`$606A` (`ShipSlots`); `$70E3` (`ViewIndex`); `$7104`-`$7124` (`Condition`, `StarSeed`, `SunPosition`, `PlanetPosition` and 8 more); `$92FA`-`$92FB` (`TunnelFrame`); `$9326`-`$932B` (`TunnelFrame`); `$93D0`-`$93D2` (`TunnelRingCount`, `TunnelRingsLeft`, `TunnelTop`); 2 more ranges |

### `ResetControls` (`$94F4`)

**The control accumulators `$FF08-$FF0C` zeroed, SpeedControl `$0C00`, then the keys**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 88 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 132 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 132 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext`, `TunnelStart`, `SceneLaunch` |
| Calls | `ClearKeyBytes`, `ZeroBytes` |
| Writes | `$FF0D` (`SpeedControl`) |

### `ClearKeyBytes` (`$94FE`)

**Zero the five key bytes `$FC08-$FC0C`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 7 calls, 119 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 13 calls, 221 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 13 calls, 221 t-states own (0.00 %) |
| Called from | `DashboardRestore`, `CallScreen` (tail), `ResetControls` |
| Calls | `ZeroBytes` |

### `ZeroBytes` (`$9503`)

**Zero B bytes from HL**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 11 calls, 2,153 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 18 calls, 3,126 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 3,126 t-states own (0.00 %) |
| Called from | `SceneLaunch`, `ResetControls`, `ClearKeyBytes` |
| Writes | `$6048`-`$6062` (`ShipSlots`); `$7110`-`$7116` (`PlanetPosition`); `$FC08`-`$FC0C` (`KeyScreens`, `KeySteer`, `KeyViews`, `KeyCombat` and 1 more); `$FF08`-`$FF0C` (`RollControl`, `PitchControl`, `SpeedControl`) |

## sound

`src/game/sound.asm`

### `ClearShips` (`$9509`)

**The station not hostile (+`$21` bit 2) and slots 1-7 free (energy +`$22` zero), ShipCount 0**

Run by the launch and the jump: no ship survives them.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 424 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 829 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 1,243 t-states own (0.00 %) |
| Called from | `TitleNext`, `TunnelStart`, `SceneLaunch` |
| Calls | `IM2Entry` |
| Reads | `$6069` (`ShipSlots`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$6069` (`ShipSlots`); `$6091` (`ShipSlots`); `$60B8` (`ShipSlots`); `$60DF` (`ShipSlots`); `$6106` (`ShipSlots`); `$612D` (`ShipSlots`); 4 more ranges |

### `SoundLaunch` (`$9527`)

**The launch's and the dock's whistle: a pulse train played at once**

Called by the launch (SceneLaunchNow, as the tunnel starts), the dock (after SceneDock's frames) and GameOver: 4 runs, the launches of f1, w1 and d1 and the death of w1.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 1,754 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 55 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 110 t-states own (0.00 %) |
| Called from | `TitleNext`, `SceneLaunch` |
| Calls | `SoundPlay` (tail), `SoundPulses`, `SoundArmLaunch` |
| Reads | `$9522` (`SoundMode`); `$FC0E` (`Options`) |
| Writes | `$7128` (`SoundRequests`) |

### `SoundArrive` (`$9532`)

**The arrival from the jump (TunnelDone): a pulse train played at once**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 55 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 55 t-states own (0.00 %) |
| Called from | `TunnelDone` (tail) |
| Calls | `SoundPlay` (tail), `SoundArmArrive` |
| Reads | `$FC0E` (`Options`) |

### `SoundJump` (`$953D`)

**The jump's start (TunnelStart): a pulse train played at once**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 55 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 55 t-states own (0.00 %) |
| Called from | `TunnelStart` |
| Calls | `SoundPlay` (tail), `SoundArmJump` |
| Reads | `$FC0E` (`Options`) |

### `SoundGameOver` (`$9548`)

**Game Over's sound: SoundSecond's 160-level phase, played by SoundPlay with the interrupts on (1 run, the death of w1)**

The interrupt's SoundTick plays slices of the same effect while SoundPlay loops, and arms the explosion ShipsWreck requested in between. As SoundTick never set SoundBit for this effect, its SoundEnd flips the stale bit of the effect before (w1 frame 4308: the laser's bit 4 set again, SoundRequests `$14`); SoundPlay clears every request when it ends, so nothing is heard of it.

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 43 t-states own (0.00 %) |
| Called from | `TitleNext` |
| Calls | `SoundSecond` |
| Reads | `$FC0E` (`Options`) |

### `SoundPlay` (`$9551`)

**Play the armed effect to its end (the scene sounds have the interrupts off), then clear the requests and EI**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 2,875 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 4,736 t-states own (0.00 %) |
| Called from | `SoundLaunch` (tail), `SoundArrive` (tail), `SoundJump` (tail) |
| Calls | `SoundPulses` |
| Reads | `$9522` (`SoundMode`) |
| Writes | `$7128` (`SoundRequests`) |

### `SoundBomb` (`$9561`)

**SoundTable, bit 0: the energy bomb, falling pulses**

SoundTable is eight JPs, one per request bit; SoundTick computes the bit's number * 3. Bits 0, 1, 3 and 5 were set first in k2 (the bomb, the missile, a ship hit, the E.C.M.: SoundArmBomb, SoundArmMissile, SoundArmShipHit, SoundArmECM); bit 7 is never set and shares bit 6's code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundMissile` (`$9564`)

**SoundTable, bit 1: the missile launch, pulses**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundExplode` (`$9567`)

**SoundTable, bit 2: an explosion, two-phase pulses**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 10 t-states own (0.00 %) |
| Called from | `SoundTick` |
| Calls | `SoundArmTwoPhase` (tail) |

### `SoundShipHit` (`$956A`)

**SoundTable, bit 3: a ship hit, noise**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundLaser` (`$956D`)

**SoundTable, bit 4: the laser, a sweep**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 120 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 180 t-states own (0.00 %) |
| Called from | `SoundTick` |
| Calls | `SoundArmLaser` (tail) |

### `SoundECM` (`$9570`)

**SoundTable, bit 5: the ECM, a sweep**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundHit` (`$9573`)

**SoundTable, bit 6: the player hit, noise**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 480 t-states own (0.00 %) |
| Called from | `SoundTick` |
| Calls | `SoundArmHit` (tail) |

### `SoundSpare` (`$9576`)

**SoundTable, bit 7: as bit 6 (never requested)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundTick` (`$9579`)

**One slice of the effect playing, or arm the effect of the lowest request bit**

Runs once a frame from IM2Handler; with SoundMode 0 and no request it returns at once. The jump to SoundTable is computed (bit number * 3 + `$9561`), so the static walk does not see it.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,613 calls, 203,814 t-states own (0.11 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4,571 calls, 358,290 t-states own (0.11 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,214 calls, 496,805 t-states own (0.11 %) |
| Called from | `SoundTickVector` (tail) |
| Calls | `SoundExplode`, `SoundLaser`, `SoundHit`, `SoundPulses`, `SoundSweep` (tail) |
| Reads | `$7128` (`SoundRequests`); `$9522` (`SoundMode`); `$FC0E` (`Options`) |
| Writes | `$96BF` (`SoundBit`) |

### `SoundPulses` (`$95A6`)

**The pulse generator: 64 beeper levels from SoundSource, each held D loops; the pitch steps per pass**

The level is bit 3 or bit 4 of the ROM byte (the MIC and EAR bits of `$FE`), so the ROM's bytes give a rough waveform. The step added to D per pass is patched at `$95BD` and the 64 at `$95AE`. When E reaches 0: a second phase (bit 7, SoundSecond) or the end (SoundEnd).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 31 calls, 1,116 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 51 calls, 1,836 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 89 calls, 3,204 t-states own (0.00 %) |
| Called from | `SoundLaunch`, `SoundPlay`, `SoundTick` |
| Calls | `SoundPulsesNow` |
| Reads | `$9523`-`$9526` (`SoundPitch`, `SoundSource`) |

### `SoundPulsesNow` (`$95AD`)

**SoundPulsesNow**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 32 calls, 3,284,101 t-states own (1.73 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 54 calls, 8,795,291 t-states own (2.59 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 94 calls, 12,838,996 t-states own (2.75 %) |
| Called from | `SoundPulses`, `SoundArmPulse` (tail), `SoundArmLaunch` (tail) |
| Calls | `SoundSecond`, `SoundEnd` (tail), `IM2Entry` |
| Reads | `$7128` (`SoundRequests`); `$9522` (`SoundMode`); `$96BF` (`SoundBit`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$7128` (`SoundRequests`); `$9522`-`$9526` (`SoundMode`, `SoundPitch`, `SoundSource`); `$FFF9`-`$FFFA` (`work space $FFF9+`) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE` |

### `SoundSecond` (`$95CF`)

**The second phase of a two-phase effect: 160 levels a pass, pitch `$40`, 2 passes**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 212 t-states own (0.00 %) |
| Called from | `SoundGameOver`, `SoundPulsesNow` |
| Writes | `$9522`-`$9526` (`SoundMode`, `SoundPitch`, `SoundSource`); `$95AE` (`SoundPulsesNow`) |

### `SoundNoise` (`$95E7`)

**The noise generator: 100 pulses whose length is a ROM byte / 4 (or / 2 + 8), D passes**

SoundArmNoise patches the instruction at `$95F2`: SRL A (`$CB` `$3F`) for a ship hit, ADD A,`$10` (`$C6` `$10`) for the player hit, so the hit's pulses are longer. L steps through the ROM page in SoundSource.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundNoiseNow` (`$95EE`)

**SoundNoiseNow**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 48 calls, 7,479,770 t-states own (1.60 %) |
| Called from | `SoundArmHit` (tail) |
| Calls | `SoundPassEnd` |
| Ports out | `$00FE`, `$30FE` |

### `SoundPassEnd` (`$9607`)

**One pass done: D (or E) one less, the state saved, the end at 0**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 84 calls, 3,888 t-states own (0.00 %) |
| Called from | `SoundNoiseNow`, `SoundSweepNow` (tail) |
| Calls | `SoundEnd` |
| Writes | `$9523`-`$9526` (`SoundPitch`, `SoundSource`) |

### `SoundEnd` (`$9610`)

**The effect over: SoundMode 0 and its request bit cleared**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 15 calls, 2,197 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 72 calls, 12,939 t-states own (0.00 %) |
| Called from | `SoundPulsesNow` (tail), `SoundPassEnd`, `SoundSweepNow` |
| Reads | `$7128` (`SoundRequests`); `$96BF` (`SoundBit`) |
| Writes | `$7128` (`SoundRequests`); `$9522` (`SoundMode`) |

### `SoundSweep` (`$9624`)

**The sweep generator: 15 square cycles a pass, each pass's half period 2 E + the patched step**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 12 calls, 240 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 360 t-states own (0.00 %) |
| Called from | `SoundTick` (tail) |
| Calls | `SoundSweepNow` |
| Reads | `$9523`-`$9524` (`SoundPitch`) |

### `SoundSweepNow` (`$9628`)

**SoundSweepNow**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 24 calls, 2,359,703 t-states own (0.70 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 36 calls, 3,537,817 t-states own (0.76 %) |
| Called from | `SoundSweep`, `SoundArmLaser` (tail) |
| Calls | `SoundPassEnd` (tail), `SoundEnd` |
| Writes | `$9523`-`$9526` (`SoundPitch`, `SoundSource`) |
| Ports out | `$00FE`, `$30FE` |

### `SoundArmLaser` (`$9641`)

**Arm the laser: a sweep of step `$FD` (falling), 2 passes**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 12 calls, 888 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 1,332 t-states own (0.00 %) |
| Called from | `SoundLaser` (tail) |
| Calls | `SoundSweepNow` (tail) |
| Writes | `$9522` (`SoundMode`); `$962B` (`SoundSweepNow`) |

### `SoundArmECM` (`$9648`)

**Arm the ECM: a sweep of step `$D3`, 8 passes (k2: 10 runs from frame 2573)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundArmSweep` (`$964D`)

**The step into SoundSweep, SoundMode 1, the first pass at once**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundArmHit` (`$9657`)

**Arm the player hit: noise from the ROM at `$1A1A`, 1 pass**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 48 calls, 4,608 t-states own (0.00 %) |
| Called from | `SoundHit` (tail) |
| Calls | `SoundNoiseNow` (tail) |
| Writes | `$9522` (`SoundMode`); `$95F2`-`$95F3` (`SoundNoiseNow`) |

### `SoundArmShipHit` (`$965E`)

**Arm a ship hit: noise from the ROM at `$031A`, 1 pass (k2: 15 runs from frame 3187)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundArmNoise` (`$9663`)

**The instruction patched in, SoundSource = A * 256 + `$1A` (`$1A1A` or `$031A`), SoundMode 2, the first pulses at once**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundArmMissile` (`$9674`)

**Arm the missile's launch: pulses stepping by `$E4` a pass (k2: 1 run, frame 2542)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundArmExplode` (`$967F`)

**The first phase of the explosion: 64 levels, pitch `$40`, 8 passes**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SoundArmPulse` (`$9684`)

**Patch the level count (B) and the pitch step (C) into SoundPulses and play a pass**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 162 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 5 calls, 270 t-states own (0.00 %) |
| Called from | `SoundArmTwoPhase`, `SoundArmLaunch` (tail), `SoundArmScene` (tail) |
| Calls | `SoundPulsesNow` (tail) |
| Writes | `$95AE`-`$95BD` (`SoundPulsesNow`) |

### `SoundArmTwoPhase` (`$9692`)

**Arm the explosion: SoundMode `$83`, the pitch step 2**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 56 t-states own (0.00 %) |
| Called from | `SoundExplode` (tail) |
| Calls | `SoundArmPulse` |
| Writes | `$9522` (`SoundMode`) |

### `SoundArmLaunch` (`$969B`)

**Arm SoundLaunch: 80 levels, the step 2, pitch `$40`, `$20` passes, the interrupts off**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 110 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 56 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 112 t-states own (0.00 %) |
| Called from | `SoundLaunch` |
| Calls | `SoundPulsesNow` (tail), `SoundArmPulse` (tail) |
| Writes | `$9522` (`SoundMode`); `$95AE`-`$95BD` (`SoundPulsesNow`) |

### `SoundArmArrive` (`$96A9`)

**Arm SoundArrive: 192 levels, the step `$F0`, pitch `$C0`, 12 passes**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 20 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 20 t-states own (0.00 %) |
| Called from | `SoundArrive` |
| Calls | `SoundArmScene` |

### `SoundArmScene` (`$96AF`)

**SoundArmScene**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 72 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 72 t-states own (0.00 %) |
| Called from | `SoundArmArrive`, `SoundArmJump` (tail) |
| Calls | `SoundArmPulse` (tail) |
| Writes | `$9522` (`SoundMode`) |

### `SoundArmJump` (`$96B7`)

**Arm SoundJump: 192 levels, the step `$10`, pitch `$10`, 10 passes**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 32 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 32 t-states own (0.00 %) |
| Called from | `SoundJump` |
| Calls | `SoundArmScene` (tail) |

### `ShiftBC4` (`$96C5`)

**BC shifted right by 4 (ShiftBC3 by 3, ShiftBC2 by 2, ShiftBC1 by 1): the debris's scale**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 184 calls, 2,944 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 238 calls, 3,808 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,978 calls, 31,648 t-states own (0.01 %) |
| Called from | `DrawScanner` |
| Calls | `ShiftBC3` |

### `ShiftBC3` (`$96C9`)

**ShiftBC3**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 276 calls, 4,416 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 357 calls, 5,712 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,967 calls, 47,472 t-states own (0.01 %) |
| Called from | `ShiftBC4`, `DrawScanner` |
| Calls | `ShiftBC2` |

### `ShiftBC2` (`$96CD`)

**ShiftBC2**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 460 calls, 7,360 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 595 calls, 9,539 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4,945 calls, 79,196 t-states own (0.02 %) |
| Called from | `ShiftBC3`, `DrawScanner` |
| Calls | `ShiftBC1`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `ShiftBC1` (`$96D1`)

**ShiftBC1**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 552 calls, 14,371 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 714 calls, 18,602 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 5,934 calls, 154,379 t-states own (0.03 %) |
| Called from | `ShiftBC2`, `DrawScanner` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF9`-`$FFFA` (`work space $FFF9+`) |

## scanner

`src/game/scanner.asm`

### `ScannerNext` (`$96D6`)

**The next slot**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawScanner` (`$96D9`)

**Restore the scanner's background, then a dot and a stalk for each ship within range**

Nothing is drawn while no slot is in use (ShipsPresent `$9C96`); a free slot has energy (+`$22`) 0; 553 of 1076 calls drew in f1, w1 and d1. The coordinates go through Divide16 with DE = `$4000`, so a high byte of `$40` would be the scanner's edge.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 432,621 t-states own (0.23 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 589,386 t-states own (0.17 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 2,689,366 t-states own (0.58 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `NextLineDown`, `Square`, `ShiftBC4`, `ShiftBC3`, `ShiftBC2`, `ShiftBC1`, `ScannerLineDown`, `ScannerLineUp`, `ConditionYellow`, `ScannerRestore`, `Divide16Vector`, `IM2Entry` |
| Reads | `$50AE`-`$50B0` (screen); `$518F`-`$51B0` (screen); `$528F`-`$52B0` (screen); `$538F`-`$53AF` (screen); `$548E`-`$55AF` (screen); `$568E`-`$5690` (screen); 13 more ranges |
| Writes | `$5009`-`$5015` (screen); `$50AE`-`$50B0` (screen); `$5109`-`$5115` (screen); `$518F`-`$51B0` (screen); `$5209`-`$5215` (screen); `$528F`-`$52B0` (screen); 11 more ranges |

### `ScannerLineDown` (`$986A`)

**Down a character row; leaving the dashboard (`$58`xx) abandons the ship's stalk**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 21 calls, 1,092 t-states own (0.00 %) |
| Called from | `DrawScanner` |

### `ScannerLineUp` (`$987C`)

**Up a character row; above the scanner's first row abandons the ship's stalk**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 139 calls, 8,915 t-states own (0.00 %) |
| Called from | `DrawScanner` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `ConditionYellow` (`$988E`)

**Yellow while a ship other than the station is about, unless the condition is red or flashing**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 2,576 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 120 calls, 3,360 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 22,847 t-states own (0.00 %) |
| Called from | `DrawScanner` |
| Reads | `$7104` (`Condition`); `$9CAE` (`NonStationPresent`) |
| Writes | `$7104` (`Condition`) |

### `ScannerSaveOn` (`$98A2`)

**Patch ScannerCopy to save the screen into ScannerSave, then copy it (known from the code only: 3 runs after a new dashboard)**

The five patched bytes turn the copy around: EX DE,HL first, PUSH HL and POP HL in place of PUSH DE and POP DE, INC H for INC D. ScannerRestore puts the restore's bytes back.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 194 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 194 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 194 t-states own (0.00 %) |
| Called from | `DashboardRestore` (tail) |
| Calls | `ScannerRestore`, `ScannerCopy` (tail) |
| Writes | `$9912`-`$991A` (`ScannerCopy`); `$9935`-`$9940` (`ScannerCopy`) |

### `ScannerRestore` (`$98CD`)

**Once after a frame drew the scanner: clear the 11 x 8 bytes of the dashboard's middle and patch ScannerCopy back to a restore**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 94 calls, 244,655 t-states own (0.13 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 645 calls, 334,903 t-states own (0.10 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 344 calls, 918,037 t-states own (0.20 %) |
| Called from | `TitleNext`, `DashboardSave`, `DrawScanner`, `ScannerSaveOn` |
| Calls | `ScannerCopy`, `IM2Entry` |
| Reads | `$96C4` (`SoundBit`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$502A`-`$5134` (screen); `$522A`-`$5234` (screen); `$532A`-`$5334` (screen); `$542A`-`$5434` (screen); `$552A`-`$5534` (screen); `$562A`-`$5634` (screen); 5 more ranges |

### `ScannerCopy` (`$990C`)

**Copy the scanner's 13 x 48 bytes between ScannerSave and the screen (patched for the direction)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 1,406,564 t-states own (0.74 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 120 calls, 1,816,181 t-states own (0.54 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 342 calls, 4,994,785 t-states own (1.07 %) |
| Called from | `ScannerSaveOn` (tail), `ScannerRestore` |
| Calls | `IM2Entry` |
| Reads | `$5049`-`$52F5` (screen); `$5349`-`$53F5` (screen); `$5449`-`$54F5` (screen); `$5549`-`$55F5` (screen); `$5649`-`$56F5` (screen); `$5749`-`$57F5` (screen); 2 more ranges |
| Writes | `$5049`-`$52F5` (screen); `$5349`-`$53F5` (screen); `$5449`-`$54F5` (screen); `$5549`-`$55F5` (screen); `$5649`-`$56F5` (screen); `$5749`-`$57F5` (screen); 2 more ranges |

### `ResetFlight` (`$9946`)

**The new flight's dashboard: the missiles, the indicators, the bars full or empty, the scanner's colours**

The shields and the altitude full (`$A0`), the energy banks full, the cabin and laser temperatures 0, no missile armed, AutoDocked and ECMActive off. The two colour blocks either side of the scanner are 7 x 5 cells of `$17` (red paper) or `$1F` (magenta) with the escape pod (`$D089`). 3 runs (the launches).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 443 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 443 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 443 t-states own (0.00 %) |
| Called from | `SceneLaunch` |
| Calls | `FillBlock`, `DrawMissiles`, `ClearHighlightsVector` |
| Reads | `$70E3` (`ViewIndex`); `$D089` (`Equipment`) |
| Writes | `$70E8`-`$70FC` (`BarDrawn`); `$7129` (`AutoDocked`); `$9C1B` (`MissileLaunchFlag`); `$9C9B` (`ECMActive`); `$D047` (`MissileState`) |

### `FillBlock` (`$9995`)

**Fill 7 rows of 5 attribute cells with C (DE = 27 the row's rest)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 2,502 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 2,502 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 2,502 t-states own (0.00 %) |
| Called from | `ResetFlight` |
| Writes | `$5A23`-`$5A27` (screen); `$5A38`-`$5A47` (screen); `$5A58`-`$5A67` (screen); `$5A78`-`$5A87` (screen); `$5A98`-`$5AA7` (screen); `$5AB8`-`$5AC7` (screen); 2 more ranges |

### `ConditionLight` (`$99A4`)

**Light the condition: red with a shield down, flashing every two frames, the colour on the two cells**

In the menus and charts (views 4 and up) the condition is a text instead: tokens `$21-$24` at row 1, column `$1B` (known from the code only). The missile's light at `$5AE7` gets paper green when armed, red when locked.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 145 calls, 41,492 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 693 calls, 202,589 t-states own (0.06 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 391 calls, 116,585 t-states own (0.02 %) |
| Called from | `ConditionLightVector` (tail) |
| Calls | `ConditionGreen`, `IM2Entry` |
| Reads | `$70E3`-`$70EA` (`ViewIndex`, `RollRate`, `PitchRate`, `SpeedRate` and 1 more); `$7104` (`Condition`); `$99A3` (`ConditionFlash`); `$D047` (`MissileState`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$5A28`-`$5A29` (screen); `$5A48`-`$5A49` (screen); `$5AE7` (screen); `$7104` (`Condition`); `$99A3` (`ConditionFlash`); `$FFF7`-`$FFF8` (`work space $FFF7+`) |

### `ConditionGreen` (`$9A3A`)

**Condition green for the next frame**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 140 calls, 4,362 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 691 calls, 21,324 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 389 calls, 12,081 t-states own (0.00 %) |
| Called from | `ConditionLight` |
| Writes | `$7104` (`Condition`) |

### `DashboardTick` (`$9A40`)

**The flight views' dashboard: the indicators, the missile, the energy bomb, then the damage**

The missile keys are cleared after use (KeyCombat AND `$91` keeps A, E and C: T, F, U, W and Q are cleared).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 49,189 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 342,199 t-states own (0.10 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 114,206 t-states own (0.02 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `EnergyBombVector`, `DrainBanks`, `ShieldHit`, `Recharge`, `DrawIndicators`, `MissileKeys`, `EscapePod`, `IM2Entry` |
| Reads | `$70E3` (`ViewIndex`); `$70F6`-`$7104` (`BarDrawn`, `WitchSpace`, `Condition`); `$9CA2`-`$9CA4` (`EnergyDrain`, `FrontHits`, `AftHits`); `$D041` (`CloakOn`); `$FC0B` (`KeyCombat`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$70F6`-`$7104` (`BarDrawn`, `WitchSpace`, `Condition`); `$FC0B` (`KeyCombat`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `Damage` (`$9A59`)

**Flashing with the fourth bank not full; the recharge; the shields take the hits, the banks what the shields cannot**

Front hits (`$9CA3`) on the front shield, aft hits (`$9CA4`) on the aft one, the drain (`$9CA2`, one more with CloakOn `$D041`) on the energy banks. All four banks at 0 sets TooClose: the end (1 run, the death of d1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrainBanks` (`$9A8D`)

**Take C from each of B energy banks from E1 up; all empty ends the game**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 378 calls, 77,151 t-states own (0.02 %) |
| Called from | `DashboardTick`, `ShieldHit` |
| Reads | `$70F6`-`$70FC` (`BarDrawn`) |
| Writes | `$70F6`-`$70FC` (`BarDrawn`); `$711F` (`TooClose`) |

### `ShieldHit` (`$9AA7`)

**A shield (HL) loses 4 x the hit (C); past zero the banks lose the rest and the hit flash builds up**

A hit of `$46` or more, or a flash count past 12, calls DamageItem (DamageVector `$D0F3`): a random loss of fuel, equipment or cargo. No hit: the flash count (`$9ADA`) goes down by one.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 184 calls, 8,648 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,286 calls, 60,442 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 682 calls, 41,846 t-states own (0.01 %) |
| Called from | `DashboardTick` |
| Calls | `DrainBanks`, `DamageVector` (tail), `IM2Entry` |
| Reads | `$70E8`-`$70EA` (`BarDrawn`); `$9ADA` (`HitCount`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$70E8`-`$70EA` (`BarDrawn`); `$9ADA` (`HitCount`); `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `Recharge` (`$9ADB`)

**One recharge step, two with the energy unit (`$D08B`)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 25,923 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 179,176 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 83,862 t-states own (0.02 %) |
| Called from | `DashboardTick` |
| Calls | `ShieldGain`, `IM2Entry` |
| Reads | `$70F6`-`$70FC` (`BarDrawn`); `$D08B` (`Equipment`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$70F6`-`$70FC` (`BarDrawn`); `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `RechargeStep` (`$9AE2`)

**The topmost bank not full gains 1; all full, each shield gains 1**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShieldGain` (`$9AFB`)

**One more to a shield below `$A0`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 184 calls, 4,825 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,190 calls, 31,552 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 296 calls, 8,079 t-states own (0.00 %) |
| Called from | `Recharge` |
| Reads | `$70E8`-`$70EA` (`BarDrawn`) |
| Writes | `$70E8` (`BarDrawn`) |

### `DrawIndicators` (`$9B01`)

**The letters beside the bars and the two 2 x 2 indicators: E (ECM on) and S (the safe zone)**

Printed through PrintCode with the back-buffer switch (`$D04B`'s byte) off, at text positions (row, column) `$1108`, `$1208`, `$1607` and `$1615`.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 27,717 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 190,074 t-states own (0.06 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 102,766 t-states own (0.02 %) |
| Called from | `DashboardTick` |
| Calls | `PrintBlock`, `PrintCodeVector` |
| Reads | `$711C` (`SafeZone`); `$9C9B` (`ECMActive`); `$D04B`-`$D04C` (`PrintTarget`) |
| Writes | `$D045`-`$D046` (`TextColumn`, `TextRow`); `$D548` (`PlotChar`) |

### `PrintBlock` (`$9B4A`)

**Print two rows of two codes from DE at HL (row, column)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 184 calls, 3,128 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,286 calls, 21,862 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 682 calls, 11,594 t-states own (0.00 %) |
| Called from | `DrawIndicators` |
| Calls | `PrintPair` |

### `PrintPair` (`$9B4D`)

**Print two codes at HL, then the next row**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 368 calls, 25,024 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,572 calls, 174,896 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,364 calls, 92,752 t-states own (0.02 %) |
| Called from | `PrintBlock` |
| Calls | `PrintTwo` |
| Writes | `$D045`-`$D046` (`TextColumn`, `TextRow`) |

### `PrintTwo` (`$9B57`)

**Print the codes at DE and DE+1**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 368 calls, 6,256 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,572 calls, 43,724 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,364 calls, 23,188 t-states own (0.00 %) |
| Called from | `PrintPair` |
| Calls | `PrintNext` |

### `PrintNext` (`$9B5A`)

**Print the code at DE, DE+1**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 736 calls, 44,896 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 5,144 calls, 313,803 t-states own (0.09 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,728 calls, 166,408 t-states own (0.04 %) |
| Called from | `PrintTwo` |
| Calls | `PrintCodeVector`, `IM2Entry` |
| Reads | `$9B68`-`$9B73` (`IndicatorCodes`) |

### `DrawMissiles` (`$9B74`)

**The four missile cells at (row `$17`, column 2): a missile glyph (`$25`) for each left, a blank (`$40`) for the rest**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 375 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 375 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 375 t-states own (0.00 %) |
| Called from | `ResetFlight` |
| Calls | `PrintCodeVector` |
| Reads | `$D04B`-`$D04C` (`PrintTarget`); `$D083` (`Missiles`) |
| Writes | `$D045`-`$D046` (`TextColumn`, `TextRow`); `$D548` (`PlotChar`) |

### `MissileKeys` (`$9BA7`)

**T arms the missile, U disarms it, F fires it at the locked target; an armed missile locks on the ship in the sights**

MissileState `$D047`: 0 off, 1 armed, 2 locked on MissileTarget `$D0E3`. The lock beeps through the ROM's BEEPER (`$03B5`, HL `$70`, DE `$60`). A fired missile is a new ship (ShipAction `$9C9C` with the target in the high nibble and action 2); no free slot flashes the button (`$D0BD` bit 7). k2 armed one (T, frame 2485), locked it and fired it (F from 2519, launched at 2542); a Thargoid's E.C.M. destroyed it.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 13,248 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 92,611 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 49,104 t-states own (0.01 %) |
| Called from | `DashboardTick` |
| Calls | `IM2Entry` |
| Reads | `$D047` (`MissileState`); `$D083` (`Missiles`); `$FC0B` (`KeyCombat`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF9`-`$FFFA` (`work space $FFF9+`) |

## shipmotion

`src/game/shipmotion.asm`

### `EscapePod` (`$9C1C`)

**Q with an escape pod, not in witch space (WitchSpace): the pod is launched and the cargo, the pod and the legal status lost**

Clears the cargo hold (`$D06B`, 17 bytes) and the fugitive bit of `$D0B0`, empties the hold to 20 tons free, 35 with the large cargo bay (FreeSpace `$D07C`), launches ship `$17` (the pod as the player's ship) and counts 24 frames down to the arrival at the station (Arrived `$71BA`). m1 launched it at frame 2534 (Q), and m2 before its dock.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 5,980 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 41,795 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 22,184 t-states own (0.00 %) |
| Called from | `DashboardTick` |
| Calls | `IM2Entry` |
| Reads | `$9C1B` (`MissileLaunchFlag`); `$FC0B` (`KeyCombat`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `UpdateShipsVector` (`$9C80`)

**The ship vectors: UpdateShips, MovePosition, SquareRoot, Divide16, DrawLine, Laser**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 920 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 6,430 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 371 calls, 3,729 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `ShipsAndLaser` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `MovePositionVector` (`$9C83`)

**MovePositionVector**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 208 calls, 2,080 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,834 calls, 18,340 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 274 calls, 2,740 t-states own (0.00 %) |
| Called from | `MoveSunPlanet` (tail), `StationRunIn` |
| Calls | `MovePosition` (tail) |

### `SquareRootVector` (`$9C86`)

**SquareRootVector**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 920 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 647 calls, 6,470 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 345 calls, 3,450 t-states own (0.00 %) |
| Called from | `VectorLength`, `VectorLengthShift`, `JumpDistance` |
| Calls | `SquareRoot` (tail) |

### `Divide16Vector` (`$9C89`)

**Divide16Vector**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 460 calls, 4,600 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,643 calls, 16,430 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,649 calls, 36,509 t-states own (0.01 %) |
| Called from | `CompassDivide`, `CompassDivideScale`, `DrawScanner` |
| Calls | `Divide16` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF7`-`$FFF8` (`work space $FFF7+`) |

### `DrawLineVector` (`$9C8C`)

**DrawLineVector**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LaserVector` (`$9C8F`)

**LaserVector**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShipActionVector` (`$9C9C`)

**ShipAction: A = an action (low nibble) and its argument (high nibble)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 10 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 30 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext`, `TunnelStart` |
| Calls | `ShipAction` (tail) |

### `ResetShipsVector` (`$9C9F`)

**ResetShipsVector**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 10 t-states own (0.00 %) |
| Called from | `TitleNext` |
| Calls | `ShipsWreck` (tail) |

### `HalveSignedVector` (`$9CA5`)

**Vectors (known from the code only: nothing calls them)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UpdateShipVector` (`$9CA8`)

**UpdateShipVector**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TitleShipVector` (`$9CAB`)

**TitleShipVector**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawTitleShipVector` (`$9CAF`)

**The title's turning ship (TurnTitleShip `$A28D`)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 530 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 530 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 287 calls, 2,870 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `TurnTitleShip` (tail) |

### `ShipsAndLaser` (`$9CB5`)

**UpdateShips, then the gunsight and the laser (Laser `$B7B4`)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 2,484 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 17,361 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 371 calls, 10,017 t-states own (0.00 %) |
| Called from | `UpdateShipsVector` (tail) |
| Calls | `UpdateShips`, `Gunsight` (tail) |

### `UpdateShips` (`$9CBB`)

**Every slot once a frame: spawn, count, tactics, move, tidy, collide, draw, explode**

Before the loop: the station hostile in mission state 4 (`$D0AF`), the line drawing patched to OR (`$B1`) or XOR (`$A9`) by `$7120`, JumpEncounter counted, and a new ship tried when it reaches 0 outside the safe zone and with no jump running and fewer than 4 ships about. 1106 runs; 8848 slot passes, 1288 on a ship.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 67,628 t-states own (0.04 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 502,963 t-states own (0.15 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 371 calls, 298,705 t-states own (0.06 %) |
| Called from | `ShipsAndLaser` |
| Calls | `UpdateSlot`, `ShipAction`, `IM2Entry` |
| Reads | `$608F`-`$6091` (`ShipSlots`); `$60B6`-`$60B8` (`ShipSlots`); `$60DD`-`$60DF` (`ShipSlots`); `$6104`-`$6106` (`ShipSlots`); `$612D` (`ShipSlots`); `$6154` (`ShipSlots`); 6 more ranges |
| Writes | `$9C93`-`$9CB3` (`JumpEncounter`, `ShipsAbout`, `BombKill`, `ShipsPresent` and 17 more); `$B435` (`LineUpX`); `$B465` (`LineUpY`); `$B486` (`LineDownX`); `$B4B2` (`LineDownY`); `$FFF7`-`$FFFA` (`work space $FFF7+`) |

### `UpdateSlot` (`$9D38`)

**One slot: the flags, the bomb, the explosion's states, then tactics, moving, tidying, collisions and drawing**

A destroyed ship (+`$20` bits 4-5 = 01 or 11) skips the move; state 10 frees the slot, requests the explosion sound, ends the mission ship, pays the bounty (AddCash `$D0E7` with the blueprint's +`$08`) and the combat score (`$D0EA` with half of +`$15`), and a protected ship makes the player a fugitive (`$D05F` bit 6). k2 destroyed its missile, a Thargoid and a Thargon (AddCash 3 runs from frame 2612; the score 196560 to 197858); a protected ship is known from the code only.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 736 calls, 103,163 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 5,144 calls, 394,024 t-states own (0.12 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,968 calls, 940,492 t-states own (0.20 %) |
| Called from | `UpdateShips`, `UpdateSlotNext` (tail) |
| Calls | `UpdateSlotNext` (tail), `TidyAxis`, `UpdateShip`, `Tactics`, `DrawShip`, `Orthogonalise`, `Collide`, `IM2Entry` |
| Reads | `$6068`-`$6095` (`ShipSlots`); `$60B6`-`$60BC` (`ShipSlots`); `$60DD`-`$60E3` (`ShipSlots`); `$6104`-`$610A` (`ShipSlots`); `$612D` (`ShipSlots`); `$6154` (`ShipSlots`); 3 more ranges |
| Writes | `$6068` (`ShipSlots`); `$608F` (`ShipSlots`); `$60B6` (`ShipSlots`); `$60DD` (`ShipSlots`); `$6104` (`ShipSlots`); `$9C94`-`$9C96` (`ShipsAbout`, `BombKill`, `ShipsPresent`); 2 more ranges |

### `UpdateSlotNext` (`$9E5C`)

**The next slot; after the last the bomb is off and the station's anger ends when no ship is about**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 736 calls, 41,787 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 5,144 calls, 291,922 t-states own (0.09 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,968 calls, 164,269 t-states own (0.04 %) |
| Called from | `UpdateSlot` (tail) |
| Calls | `UpdateSlot` (tail), `IM2Entry` |
| Reads | `$9C94` (`ShipsAbout`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$9C95`-`$9C99` (`BombKill`, `ShipsPresent`, `SightTarget`, `ShipVarSpare2` and 1 more); `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `Normalise` (`$9E73`)

**Make a position vector (IX) a unit one: its length (SquareRoot of the sum of squares) and each part divided by it**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 215 calls, 54,825 t-states own (0.01 %) |
| Called from | `TacticsAim` |
| Calls | `SquareComponent`, `DivideComponent`, `SquareRoot` |

### `SquareComponent` (`$9E98`)

**The square of one 16-bit part (sign bit off) through the squares table: HL low, IX high, IX += 2**

(256 b + c)² = 65536 b² + 512 b c + c²: b c by Multiply8 `$AB34`, b² and c² from the table at `$BE00` (low bytes) and `$BF00` (high bytes).

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 645 calls, 209,017 t-states own (0.04 %) |
| Called from | `Normalise` |
| Calls | `Multiply8`, `IM2Entry` |
| Reads | `$A2B8`-`$A2BD` (`TargetVector`); `$BE00`-`$BFFF` (`SquaresLow`, `SquaresHigh`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE9`-`$FFEC` (`work space $FFE9+`) |

### `DivideComponent` (`$9ECF`)

**One part divided by the length (DE), halved, its sign put back**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 645 calls, 122,201 t-states own (0.03 %) |
| Called from | `Normalise` |
| Calls | `Divide16`, `IM2Entry` |
| Reads | `$A2B8`-`$A2BD` (`TargetVector`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$A2B8`-`$A2BD` (`TargetVector`); `$FFE9`-`$FFEC` (`work space $FFE9+`) |

### `SquareRoot` (`$9EF1`)

**HL = the square root of HL, scaled up or down to keep 12 bits of precision**

Below `$1000` the value is shifted up by 8 (or 4) and the root down by 4 (or 2). Two steps of Newton's iteration (SquareRootCore).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 12,236 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 647 calls, 15,537 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 560 calls, 48,834 t-states own (0.01 %) |
| Called from | `SquareRootVector` (tail), `Normalise` |
| Calls | `SquareRootCore` (tail), `SquareRootStep`, `SquareRootAdd`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFED`-`$FFEE` (`work space $FFED+`) |

### `SquareRootCore` (`$9F18`)

**Two Newton steps from `$8000`: r = (r + n / r) / 2**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 647 calls, 71,170 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 560 calls, 61,619 t-states own (0.01 %) |
| Called from | `SquareRoot` (tail) |
| Calls | `SquareRootStep`, `SquareRootAdd`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE7`-`$FFE8` (`work space $FFE7+`) |

### `SquareRootStep` (`$9F2B`)

**SquareRootStep**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 184 calls, 7,360 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,294 calls, 51,760 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,120 calls, 44,800 t-states own (0.01 %) |
| Called from | `SquareRoot`, `SquareRootCore` |
| Calls | `SquareRootAdd` |

### `SquareRootAdd` (`$9F35`)

**SquareRootAdd**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 276 calls, 21,804 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,941 calls, 153,358 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,680 calls, 132,815 t-states own (0.03 %) |
| Called from | `SquareRoot`, `SquareRootCore`, `SquareRootStep` |
| Calls | `Divide16`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE7`-`$FFEA` (`work space $FFE7+`) |

### `TidyAxis` (`$9F41`)

**Bring an axis back to unit length: each part times 1 - (x² + y² + z² - 1) / 2 from the high bytes**

The correction is the sum of the three high bytes' squares (the table `$BF00`, index 2 x) / 4, negated with the sign in bit 7; TidyPart multiplies each high byte by it. 4650 runs: the three axes of each ship drawn.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 382 calls, 80,161 t-states own (0.04 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 466 calls, 97,602 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,802 calls, 798,633 t-states own (0.17 %) |
| Called from | `UpdateSlot`, `TurnTitleShip` |
| Calls | `TidyPart`, `IM2Entry` |
| Reads | `$6052`-`$6062` (`ShipSlots`); `$6079`-`$6089` (`ShipSlots`); `$60A0`-`$60B0` (`ShipSlots`); `$60C7`-`$60D7` (`ShipSlots`); `$60EE`-`$60FE` (`ShipSlots`); `$6163`-`$616D` (`Slot7`); 2 more ranges |
| Writes | `$FFF3`-`$FFF4` (`work space $FFF3+`) |

### `TidyPart` (`$9F68`)

**One part times the correction (B), keeping its sign**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,146 calls, 157,166 t-states own (0.08 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,398 calls, 191,132 t-states own (0.06 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 11,406 calls, 1,568,162 t-states own (0.34 %) |
| Called from | `TidyAxis` |
| Calls | `Multiply8`, `IM2Entry` |
| Reads | `$6052`-`$6062` (`ShipSlots`); `$6079`-`$6089` (`ShipSlots`); `$60A0`-`$60B0` (`ShipSlots`); `$60C7`-`$60D7` (`ShipSlots`); `$60EE`-`$60FE` (`ShipSlots`); `$6163`-`$616D` (`Slot7`); 1 more ranges |
| Writes | `$6052`-`$6062` (`ShipSlots`); `$6079`-`$6089` (`ShipSlots`); `$60A0`-`$60B0` (`ShipSlots`); `$60C7`-`$60D7` (`ShipSlots`); `$60EE`-`$60FE` (`ShipSlots`); `$6163`-`$616D` (`Slot7`); 1 more ranges |

### `UpdateShip` (`$9F82`)

**Move one ship by the player, remove it when too far, turn it by its own counters and move it along its nose**

Too far: a high byte of x, y or z past 0 (z past `$60` for anything but the station) frees the slot quietly (RemoveShip `$B5DF`). Roll steps are angle `$0C`, pitch steps 8; the counters count down unless bit 7 is set.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 40,706 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 120 calls, 52,456 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,076 calls, 493,690 t-states own (0.11 %) |
| Called from | `UpdateSlot` |
| Calls | `MoveShip`, `TurnAxis`, `MovePosition`, `RemoveShip` (tail), `IM2Entry` |
| Reads | `$604A`-`$604D` (`ShipSlots`); `$6065`-`$6074` (`ShipSlots`); `$608C`-`$609B` (`ShipSlots`); `$60B3`-`$60C2` (`ShipSlots`); `$60DA`-`$60E9` (`ShipSlots`); `$6101`-`$610A` (`ShipSlots`); 2 more ranges |
| Writes | `$606A` (`ShipSlots`); `$608C`-`$608D` (`ShipSlots`); `$60B3`-`$60B4` (`ShipSlots`); `$60DA`-`$60DB` (`ShipSlots`); `$6101`-`$6102` (`ShipSlots`); `$9F80`-`$9F81` (`TurnRates`); 1 more ranges |

### `MoveShip` (`$9FFD`)

**The ship's own speed along its nose axis (three parts), then its axes turned by its own rates**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 145 calls, 42,865 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 172 calls, 50,860 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,363 calls, 403,166 t-states own (0.09 %) |
| Called from | `UpdateShip`, `TurnTitleShip` |
| Calls | `MoveAlongAxis`, `TurnOwn`, `IM2Entry` |
| Reads | `$6063`-`$6064` (`ShipSlots`); `$608A`-`$608B` (`ShipSlots`); `$60B1`-`$60B2` (`ShipSlots`); `$60D8`-`$60D9` (`ShipSlots`); `$60FF`-`$6100` (`ShipSlots`); `$6174`-`$6175` (`Slot7`) |
| Writes | `$9F81` (`TurnRates`) |

### `MoveAlongAxis` (`$A04B`)

**One position part plus speed x the axis part**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 435 calls, 121,312 t-states own (0.06 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 516 calls, 143,126 t-states own (0.04 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4,089 calls, 1,144,534 t-states own (0.24 %) |
| Called from | `MoveShip` |
| Calls | `MultiplySpeed`, `AddSigned`, `IM2Entry` |
| Reads | `$6048`-`$6056` (`ShipSlots`); `$606F`-`$607D` (`ShipSlots`); `$6096`-`$60A4` (`ShipSlots`); `$60BD`-`$60CB` (`ShipSlots`); `$60E4`-`$60F2` (`ShipSlots`); `$6159`-`$6167` (`Slot7`); 1 more ranges |
| Writes | `$6048`-`$6050` (`ShipSlots`); `$606F`-`$6077` (`ShipSlots`); `$6096`-`$609E` (`ShipSlots`); `$60BD`-`$60C5` (`ShipSlots`); `$60E4`-`$60EC` (`ShipSlots`); `$6159`-`$6161` (`Slot7`); 1 more ranges |

### `MultiplySpeed` (`$A076`)

**DE = speed (D) x the axis part's high byte (C), sign in D bit 7**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 435 calls, 169,253 t-states own (0.09 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 516 calls, 200,819 t-states own (0.06 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4,089 calls, 1,641,107 t-states own (0.35 %) |
| Called from | `MoveAlongAxis` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE9`-`$FFF0` (`work space $FFE9+`) |

### `AddSigned` (`$A098`)

**HL (a sign and magnitude part, the sign in B) plus DE (signed): the result's sign in B**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 435 calls, 22,130 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 516 calls, 26,288 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4,089 calls, 214,661 t-states own (0.05 %) |
| Called from | `MoveAlongAxis` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEB`-`$FFEC` (`work space $FFEB+`) |

### `TurnAxis` (`$A0AB`)

**Turn one axis by the player's roll and pitch: the four small-angle rotations y-z, x-y, y-x, z-y**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 276 calls, 128,228 t-states own (0.07 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 357 calls, 164,881 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,228 calls, 1,490,512 t-states own (0.32 %) |
| Called from | `UpdateShip` |
| Calls | `RotatePart`, `IM2Entry` |
| Reads | `$6052`-`$6062` (`ShipSlots`); `$6079`-`$6089` (`ShipSlots`); `$60A0`-`$60B0` (`ShipSlots`); `$60C7`-`$60D7` (`ShipSlots`); `$60EE`-`$60FE` (`ShipSlots`); `$9F80`-`$9F81` (`TurnRates`); 1 more ranges |
| Writes | `$6052`-`$6062` (`ShipSlots`); `$6079`-`$6089` (`ShipSlots`); `$60A0`-`$60B0` (`ShipSlots`); `$60C7`-`$60D7` (`ShipSlots`); `$60EE`-`$60FE` (`ShipSlots`); `$FFEF`-`$FFF2` (`work space $FFEF+`) |

### `RotatePart` (`$A0FD`)

**A = D + B x C / 256, in sign and magnitude, clamped at `$FF`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,844 calls, 437,074 t-states own (0.23 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,492 calls, 536,700 t-states own (0.16 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 29,268 calls, 4,497,500 t-states own (0.96 %) |
| Called from | `TurnAxis`, `TurnOwn` |
| Calls | `Multiply8High`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEB`-`$FFF0` (`work space $FFEB+`) |

### `TurnOwn` (`$A127`)

**Turn the ship's axes by its own roll and pitch (the nose and the side about the roof)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 435 calls, 189,542 t-states own (0.10 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 516 calls, 223,763 t-states own (0.07 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4,089 calls, 1,780,426 t-states own (0.38 %) |
| Called from | `MoveShip` |
| Calls | `RotatePart`, `IM2Entry` |
| Reads | `$6052`-`$6062` (`ShipSlots`); `$6079`-`$6089` (`ShipSlots`); `$60A0`-`$60B0` (`ShipSlots`); `$60C7`-`$60D7` (`ShipSlots`); `$60EE`-`$60FE` (`ShipSlots`); `$6163`-`$6173` (`Slot7`); 2 more ranges |
| Writes | `$6052`-`$6062` (`ShipSlots`); `$6079`-`$6089` (`ShipSlots`); `$60A0`-`$60B0` (`ShipSlots`); `$60C7`-`$60D7` (`ShipSlots`); `$60EE`-`$60FE` (`ShipSlots`); `$6163`-`$6173` (`Slot7`); 1 more ranges |

### `MovePosition` (`$A173`)

**Rotate a position about the origin by the player's roll and pitch, then move it along z by the player's speed**

x, y, z each three bytes; the four rotations use full precision (CombineParts). The speed step is 2 x (SpeedRate + 1) on the low byte of z, the far value clamped at `$7FFF` / `$8000`.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 300 calls, 122,840 t-states own (0.06 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,954 calls, 815,207 t-states own (0.24 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,350 calls, 557,491 t-states own (0.12 %) |
| Called from | `MovePositionVector` (tail), `UpdateShip` |
| Calls | `CombineParts`, `RateBits`, `IM2Entry` |
| Reads | `$604E`-`$6050` (`ShipSlots`); `$6075`-`$6077` (`ShipSlots`); `$609C`-`$609E` (`ShipSlots`); `$60C3`-`$60C5` (`ShipSlots`); `$60EA`-`$60EC` (`ShipSlots`); `$70E4`-`$70E6` (`RollRate`, `PitchRate`, `SpeedRate`); 2 more ranges |
| Writes | `$604E`-`$6050` (`ShipSlots`); `$6075`-`$6077` (`ShipSlots`); `$609C`-`$609E` (`ShipSlots`); `$60C3`-`$60C5` (`ShipSlots`); `$60EA`-`$60EC` (`ShipSlots`); `$710D`-`$7118` (`SunPosition`, `PlanetPosition`); 1 more ranges |

### `CombineParts` (`$A1EA`)

**part[HL] += part[DE] x rate (C), the 24-bit parts in sign and magnitude**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,198 calls, 877,430 t-states own (0.46 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 7,816 calls, 5,716,758 t-states own (1.68 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 5,400 calls, 3,947,106 t-states own (0.84 %) |
| Called from | `MovePosition` |
| Calls | `Multiply8High`, `Multiply8`, `IM2Entry` |
| Reads | `$6048`-`$6050` (`ShipSlots`); `$606F`-`$6077` (`ShipSlots`); `$6096`-`$609E` (`ShipSlots`); `$60BD`-`$60C5` (`ShipSlots`); `$60E4`-`$60EC` (`ShipSlots`); `$7107`-`$7118` (`SunPosition`, `PlanetPosition`); 1 more ranges |
| Writes | `$6048`-`$6050` (`ShipSlots`); `$606F`-`$6077` (`ShipSlots`); `$6096`-`$609E` (`ShipSlots`); `$60BD`-`$60C5` (`ShipSlots`); `$60E4`-`$60EC` (`ShipSlots`); `$7107`-`$7118` (`SunPosition`, `PlanetPosition`); 1 more ranges |

### `RateBits` (`$A281`)

**The pitch rate's bits shuffled into C for CombineParts**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 599 calls, 27,554 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,908 calls, 179,787 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,700 calls, 124,200 t-states own (0.03 %) |
| Called from | `MovePosition` |
| Calls | `IM2Entry` |

## tactics

`src/game/tactics.asm`

### `TurnTitleShip` (`$A28D`)

**Turn the title's ship (slot 7) by fixed rates, tidy its roof and side axes and draw it**

Roll `$94` (TurnRates) and pitch `$8C` (A) through MoveShip with the ship's own speed; 393 runs (the title of f1, w1, d1).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 11,390 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 11,390 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 287 calls, 61,896 t-states own (0.01 %) |
| Called from | `DrawTitleShipVector` (tail) |
| Calls | `TidyAxis`, `MoveShip`, `DrawShip` (tail), `Orthogonalise` |
| Reads | `$617C`-`$617D` (`Slot7`) |
| Writes | `$9F80` (`TurnRates`) |

### `Tactics` (`$A2C0`)

**Energy, launches, fleeing or bailing out, the station's traffic, then steering**

Energy: one more a pass (four more above `$F0` of the blueprint's maximum, +`$07`), up to it. A weak ship (energy x 2 below the maximum): with launches left (+`$20` bits 0-2) and the random byte below `$80` and no ECM it launches its payload: ship action 4 of the kind in the blueprint's +`$0A` high nibble (a Thargoid's Thargons, the station's ships), or a missile at the player (action 2) when the nibble is 0, a trader with a pod may bail out (action 7: the pod, then the ship becomes passive cargo), or cargo is dropped (action 6). The cloak ship (MissionShip `$9CB2`): 1 (cloaked) becomes 2 (seen) below `$34` energy, 2 goes back to 1 at `$50` and more. While the player is cloaked (CloakOn `$D041`) no ship runs its tactics. The station (role bit 2) launches a ship at random when fewer than 4 are active: a Viper (`$14` hostile, the station angry) or traffic (`$24` / `$44`).

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 215 calls, 170,464 t-states own (0.04 %) |
| Called from | `UpdateSlot` |
| Calls | `NearBox`, `AwayPart`, `TowardsPart`, `TacticsAim` (tail), `IM2Entry` |
| Reads | `$606A` (`ShipSlots`); `$6090`-`$6095` (`ShipSlots`); `$60B7`-`$60BC` (`ShipSlots`); `$60DE`-`$60E3` (`ShipSlots`); `$6105`-`$610A` (`ShipSlots`); `$617B` (`Slot7`); 5 more ranges |
| Writes | `$6091`-`$6095` (`ShipSlots`); `$60B8`-`$60BC` (`ShipSlots`); `$60DF`-`$60E3` (`ShipSlots`); `$6106`-`$610A` (`ShipSlots`); `$A2B8`-`$A2BD` (`TargetVector`) |

### `LaunchFromShip` (`$A403`)

**ShipAction A with IX and IY kept: a ship launched from this one**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NearBox` (`$A40F`)

**Carry when |x| and |y| are below DE and |z| below DE + `$200`: the ship is near the player**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 282 calls, 37,599 t-states own (0.01 %) |
| Called from | `Tactics` |
| Calls | `IM2Entry` |
| Reads | `$606F`-`$6076` (`ShipSlots`); `$6096`-`$609D` (`ShipSlots`); `$60BD`-`$60C4` (`ShipSlots`); `$60E4`-`$60EB` (`ShipSlots`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF3`-`$FFF4` (`work space $FFF3+`) |

### `TacticsSteer` (`$A42F`)

**Choose the target: towards the player (hostile, not fleeing) or away from it, then TacticsAim**

A legal-sensitive ship (+`$21` bit 1) turns hostile when `$D060` (the combat score's low byte, the record's +`$0C`) is `$28` or more. Near the player (within `$200`, or `$A00` with avoidance) a ship steers away; a hostile ship flees (+`$25` bit 7) when its state is below 8 with no station about or in mission state 4.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissileHoming` (`$A4B5`)

**The missile: an ECM destroys it; else it aims at its target and explodes when within `$40` of it**

The target is +`$25` (0 the player, else 8 - slot). Hitting the station in mission state 4 ends the mission's station (role bit 7, `$D0AF` bit 3) and takes a large combat score. k2's missile ran here once (frame 2571) before a Thargoid's E.C.M. destroyed it; m2 and fs had missiles fired at the player (37 and 1926 runs). Hitting the station is known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FarPart` (`$A537`)

**NZ when a part (HL, doubled) is `$40` or more: not yet at the target**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RelativePart` (`$A53F`)

**One part of (target - missile) / 2, through SubtractSigned `$AFC9`**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AwayPart` (`$A568`)

**One part of the ship's position, its sign flipped: the vector away from the player, halved**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 396 calls, 15,523 t-states own (0.00 %) |
| Called from | `Tactics` |
| Calls | `TowardsPartNow` (tail) |
| Reads | `$6071`-`$6077` (`ShipSlots`); `$6098`-`$609E` (`ShipSlots`); `$60BF`-`$60C5` (`ShipSlots`); `$60E6`-`$60EC` (`ShipSlots`) |

### `TowardsPart` (`$A56F`)

**One part of the ship's position, halved, its sign in bit 7: the vector to steer along**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 249 calls, 4,996 t-states own (0.00 %) |
| Called from | `Tactics` |
| Calls | `TowardsPartNow` |
| Reads | `$6071`-`$6077` (`ShipSlots`); `$6098`-`$609E` (`ShipSlots`); `$60BF`-`$60C5` (`ShipSlots`); `$60E6`-`$60EC` (`ShipSlots`) |

### `TowardsPartNow` (`$A572`)

**TowardsPartNow**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 645 calls, 71,963 t-states own (0.02 %) |
| Called from | `AwayPart` (tail), `TowardsPart` |
| Calls | `IM2Entry` |
| Reads | `$606F`-`$6076` (`ShipSlots`); `$6096`-`$609D` (`ShipSlots`); `$60BD`-`$60C4` (`ShipSlots`); `$60E4`-`$60EB` (`ShipSlots`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF1`-`$FFF2` (`work space $FFF1+`) |

### `TacticsAim` (`$A587`)

**Normalise the target vector, the dot products with the nose, the roof and the side: the roll, the pitch, the speed, the laser**

Roll from the side's product (up to 15 steps, its sign against the roof), pitch from the roof's when the roll is small, the acceleration 2 when fleeing. Ahead (the nose's product positive): accelerate when far (1 or 2), and a hostile ship facing the player (z and the nose's z of opposite signs) fires when a random byte is below its laser power (+`$02` of the blueprint, halved while `$D062`, the combat score's high byte, is 0) and the product is above `$0C`: the player is hit on the front or aft shield (7 more), the laser sound requested. Behind: brake (-1 or -2).

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 215 calls, 192,009 t-states own (0.04 %) |
| Called from | `Tactics` (tail) |
| Calls | `Normalise`, `DotProduct`, `Random`, `IM2Entry` |
| Reads | `$6077`-`$607D` (`ShipSlots`); `$608F`-`$60A4` (`ShipSlots`); `$60B6`-`$60CB` (`ShipSlots`); `$60DD`-`$60F2` (`ShipSlots`); `$6104`-`$610A` (`ShipSlots`); `$6C15` (`ShipThargoid`); 5 more ranges |
| Writes | `$608B`-`$608F` (`ShipSlots`); `$60B2`-`$60B6` (`ShipSlots`); `$60D9`-`$60DD` (`ShipSlots`); `$6100`-`$6104` (`ShipSlots`); `$7128` (`SoundRequests`); `$9CA3`-`$9CA4` (`FrontHits`, `AftHits`); 2 more ranges |

### `MultiplyHigh4` (`$A69D`)

**HL: H = the sign, A = -4 x A x B / 256 (the high bytes of two parts)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 435 calls, 36,105 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 519 calls, 43,096 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,024 calls, 500,011 t-states own (0.11 %) |
| Called from | `DotProduct` |
| Calls | `Multiply8High`, `IM2Entry` |

### `DotProduct` (`$A6AC`)

**A = the dot product of the axis at IX and the target vector at IY from their high bytes, sign in bit 7**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 145 calls, 42,486 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 173 calls, 50,685 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,008 calls, 592,083 t-states own (0.13 %) |
| Called from | `TacticsAim`, `Orthogonalise` |
| Calls | `MultiplyHigh4`, `AddSignedBytes`, `IM2Entry` |
| Reads | `$6052`-`$605C` (`ShipSlots`); `$6079`-`$6089` (`ShipSlots`); `$60A0`-`$60B0` (`ShipSlots`); `$60C7`-`$60D7` (`ShipSlots`); `$60EE`-`$60FE` (`ShipSlots`); `$6163`-`$616D` (`Slot7`); 2 more ranges |
| Writes | `$FFEB`-`$FFF0` (`work space $FFEB+`) |

## drawships

`src/game/drawships.asm`

### `DrawShip` (`$A6DF`)

**Draw one ship in the view: the depth, the screen position, the gunsight test, then the dot or the wireframe**

1681 runs. The ship in the gunsight is the one whose screen point is within its own size of the centre with depth below `$2C00` (SightTarget `$9C97`); a hostile ship with tactics that nears the player ahead turns off its avoidance (+`$26` bit 5). A destroyed ship (+`$20` bit 4) is not drawn: its screen point and size go into +`$1C`-+`$1F` for the explosion (ExplosionPoint). The mission's Asp is not drawn while the mission state is 1.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 145 calls, 79,089 t-states own (0.04 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 173 calls, 84,611 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,363 calls, 764,840 t-states own (0.16 %) |
| Called from | `UpdateSlot`, `TurnTitleShip` (tail) |
| Calls | `PlotPixel`, `DrawLaserOnly` (tail), `ProjectVertices`, `DividePoint`, `DrawEdges`, `PointOf`, `ViewMatrixSetup`, `DrawLine`, `Random`, `FaceVisibility`, `IM2Entry` |
| Reads | `$6048`-`$6050` (`ShipSlots`); `$6068`-`$607D` (`ShipSlots`); `$608F`-`$60A4` (`ShipSlots`); `$60B6`-`$60CB` (`ShipSlots`); `$60DD`-`$60F2` (`ShipSlots`); `$6104`-`$6105` (`ShipSlots`); 14 more ranges |
| Writes | `$608F` (`ShipSlots`); `$60B6` (`ShipSlots`); `$60E3` (`ShipSlots`); `$6104` (`ShipSlots`); `$9C97` (`SightTarget`); `$A6DE` (`DotProductSpare`); 3 more ranges |

### `PlotPixel` (`$A83C`)

**XOR one pixel at (C, B) into the back buffer through the ROM's PIXEL-ADD (`$22B1`) with H's bit 7 set**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 612 t-states own (0.00 %) |
| Called from | `DrawShip` |
| Reads | `$C7EF`-`$C7F0` (`BackBuffer`); `$C80F`-`$C810` (`BackBuffer`) |
| Writes | `$C7EF`-`$C7F0` (`BackBuffer`); `$C80F`-`$C810` (`BackBuffer`) |

### `DrawWireframe` (`$A84D`)

**The wireframe: the view's rotation (ViewMatrix), the distance as the detail level, the faces, the vertices, the edges and the laser**

The laser of a firing ship (+`$20` bit 3) is a line from its gun vertex (+`$14` of the blueprint) to a random point at the screen's edge, drawn with bit 7 of LineAddress's page byte (`$B348`) set, so into the back buffer whatever the page.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ExplosionPoint` (`$A8AC`)

**A destroyed ship: its screen point, its size and the quadrant into +`$1C`-+`$1F`, the state 11**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawLaserOnly` (`$A8DE`)

**A firing ship that is not drawn still fires: the beam from its screen point**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 36 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 25 calls, 835 t-states own (0.00 %) |
| Called from | `DrawShip` (tail) |
| Reads | `$6068` (`ShipSlots`); `$608F` (`ShipSlots`); `$60B6` (`ShipSlots`); `$60DD` (`ShipSlots`); `$6104` (`ShipSlots`) |

### `ProjectVertices` (`$A9C9`)

**Each vertex whose visibility distance passes and one of whose faces is visible is rotated and projected**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 7,390 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 7,390 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 502 calls, 72,296 t-states own (0.02 %) |
| Called from | `DrawShip` |
| Calls | `ProjectVertex`, `IM2Entry` |
| Reads | `$61CF`-`$61D9` (`ShipAsp`); `$63E8`-`$63F2` (`ShipCanister`); `$6493`-`$649D` (`ShipCobraTrader`); `$68AA`-`$68B4` (`ShipPlate`); `$68E9`-`$68F3` (`ShipPythonTrader`); `$6C16`-`$6C20` (`ShipThargoid`); 1 more ranges |
| Writes | `$FFED`-`$FFEE` (`work space $FFED+`) |

### `ProjectVertex` (`$A9DE`)

**ProjectVertex**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 638 calls, 102,876 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 638 calls, 102,876 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 8,288 calls, 1,415,355 t-states own (0.30 %) |
| Called from | `ProjectVertices`, `ProjectNext` (tail) |
| Calls | `EitherFace`, `Project` (tail), `ProjectNext` (tail), `IM2Entry` |
| Reads | `$61E6`-`$6254` (`ShipAspVertices`); `$63FF`-`$6436` (`ShipCanisterVertices`); `$64C1`-`$6564` (`ShipCobraVertices`); `$68C1`-`$68D4` (`ShipPlateVertices`); `$6917`-`$6955` (`ShipPythonVertices`); `$6C2D`-`$6CA1` (`ShipThargoidVertices`); 2 more ranges |
| Writes | `$A9BA`-`$A9C8` (`PointOffset`, `VertexX`, `VertexY`, `VertexZ` and 8 more); `$FFEB`-`$FFF4` (`work space $FFEB+`) |

### `EitherFace` (`$AA10`)

**NZ when one of the two faces in A's nibbles is visible**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,243 calls, 157,034 t-states own (0.08 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,243 calls, 157,034 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 22,776 calls, 1,594,975 t-states own (0.34 %) |
| Called from | `ProjectVertex`, `DrawEdges` |
| Calls | `FaceIsVisible`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEB`-`$FFF4` (`work space $FFEB+`) |

### `FaceIsVisible` (`$AA20`)

**NZ when face A is visible**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 3,381 calls, 172,450 t-states own (0.09 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,381 calls, 172,450 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 34,226 calls, 1,746,381 t-states own (0.37 %) |
| Called from | `EitherFace` |
| Calls | `IM2Entry` |
| Reads | `$A984`-`$A993` (`FaceVisible`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE9`-`$FFF4` (`work space $FFE9+`) |

### `RotateVertexScaled` (`$AA2B`)

**One rotated part of a scaled vertex: three products with a matrix row, summed; a repeat reuses the products with new signs**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,566 calls, 1,076,437 t-states own (0.57 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,566 calls, 1,076,437 t-states own (0.32 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 15,201 calls, 10,616,656 t-states own (2.27 %) |
| Called from | `Project` |
| Calls | `AddSignedBytes`, `MultiplyScaled`, `IM2Entry` |
| Reads | `$61DD`-`$6252` (`ShipAsp`, `ShipAspVertices`); `$63F6`-`$6435` (`ShipCanister`, `ShipCanisterVertices`); `$64B8`-`$6563` (`ShipCobraPirate`, `ShipCobraVertices`); `$68B8`-`$68D3` (`ShipPlate`, `ShipPlateVertices`); `$6914`-`$6953` (`ShipPythonVertices`); `$6C24`-`$6C9F` (`ShipThargoid`, `ShipThargoidVertices`); 2 more ranges |
| Writes | `$A9A6`-`$A9B7` (`ViewMatrix`); `$FFE7`-`$FFF0` (`work space $FFE7+`) |

### `AddSignedBytes` (`$AAFB`)

**A = L + E with the signs in H and D (bit 7), the sign out in H**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 7,856 calls, 349,290 t-states own (0.18 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 7,912 calls, 351,626 t-states own (0.10 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 74,954 calls, 3,381,822 t-states own (0.72 %) |
| Called from | `DotProduct`, `RotateVertexScaled`, `RotateVertexReuse`, `RotateNormal` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFDF`-`$FFEE` (`work space $FFDF+`) |

### `Multiply8High` (`$AB0B`)

**A = B x C / 256 by quarter squares (the high bytes)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 17,211 calls, 1,453,294 t-states own (0.77 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 24,646 calls, 2,070,984 t-states own (0.61 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 156,207 calls, 13,172,283 t-states own (2.82 %) |
| Called from | `RotatePart`, `CombineParts`, `MultiplyHigh4`, `MultiplyScaled`, `RotateNormal`, `OrthogonalisePart`, `MultiplyWord` |
| Calls | `IM2Entry` |
| Reads | `$BF00`-`$BFFB` (`SquaresHigh`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFDD`-`$FFEE` (`work space $FFDD+`) |

### `MultiplyScaled` (`$AB1E`)

**B shifted up by VertexScale, times a matrix byte's magnitude**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 3,609 calls, 462,867 t-states own (0.24 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,609 calls, 462,867 t-states own (0.14 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 36,873 calls, 5,010,885 t-states own (1.07 %) |
| Called from | `RotateVertexScaled` |
| Calls | `Multiply8High`, `IM2Entry` |
| Reads | `$A995`-`$A9A5` (`ViewMatrix`); `$A9C7` (`VertexScale`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE5`-`$FFEE` (`work space $FFE5+`) |

### `Multiply8` (`$AB34`)

**HL = B x C by quarter squares**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5,927 calls, 761,229 t-states own (0.40 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 19,415 calls, 2,489,209 t-states own (0.73 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 41,045 calls, 5,278,832 t-states own (1.13 %) |
| Called from | `SquareComponent`, `TidyPart`, `CombineParts`, `DifferenceOfProducts`, `MultiplyRound`, `MultiplyWord` |
| Calls | `IM2Entry` |
| Reads | `$BE00`-`$BFFE` (`SquaresLow`, `SquaresHigh`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFDB`-`$FFF0` (`work space $FFDB+`) |

### `AddDoubled` (`$AB4F`)

**HL (sign B) plus 2 x DE (sign D): a vertex part added to the ship's position**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,716 calls, 170,054 t-states own (0.09 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,716 calls, 170,054 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 20,289 calls, 2,061,891 t-states own (0.44 %) |
| Called from | `ProjectAdd` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE7`-`$FFEA` (`work space $FFE7+`) |

### `RotateVertexSmall` (`$AB73`)

**A vertex of small parts (no scale): the rotated parts from the face normals' routine, or reused**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 50 calls, 16,613 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 50 calls, 16,613 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,696 calls, 551,469 t-states own (0.12 %) |
| Called from | `Project` (tail) |
| Calls | `RotateVertexReuse`, `RotateNormal`, `ProjectAdd` (tail), `IM2Entry` |
| Reads | `$64E2`-`$64F0` (`ShipCobraVertices`); `$690E`-`$6915` (`ShipPythonPirate`, `ShipPythonVertices`); `$6C24`-`$6C9E` (`ShipThargoid`, `ShipThargoidVertices`); `$A9C8` (`VertexCached`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$A9BB`-`$A9C0` (`VertexX`, `VertexY`, `VertexZ`); `$AC9F`-`$ACA1` (`VertexHigh`); `$FFE9`-`$FFEC` (`work space $FFE9+`) |

### `RotateVertexReuse` (`$ABC0`)

**A repeat vertex: the last products with the new signs**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 9 calls, 3,246 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 9 calls, 3,246 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 477 calls, 170,598 t-states own (0.04 %) |
| Called from | `RotateVertexSmall` |
| Calls | `AddSignedBytes`, `IM2Entry` |
| Reads | `$64EB`-`$64F1` (`ShipCobraVertices`); `$6C8D`-`$6C9F` (`ShipThargoidVertices`); `$A9A6`-`$A9B7` (`ViewMatrix`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$A9A7`-`$A9B7` (`ViewMatrix`); `$FFE9`-`$FFEA` (`work space $FFE9+`) |

### `RotateNormal` (`$AC01`)

**One rotated part: three high-byte products of the parts with a matrix row**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,208 calls, 1,339,578 t-states own (0.71 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,208 calls, 1,339,578 t-states own (0.39 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 19,791 calls, 12,011,405 t-states own (2.57 %) |
| Called from | `RotateVertexSmall`, `NormalPart` |
| Calls | `AddSignedBytes`, `Multiply8High`, `IM2Entry` |
| Reads | `$62C5`-`$62F4` (`ShipAspFaces`); `$6474`-`$64EB` (`ShipCanisterFaces`, `ShipCobraTrader`, `ShipCobraPirate`, `ShipCobraVertices`); `$65FE`-`$6631` (`ShipCobraFaces`); `$6914`-`$6917` (`ShipPythonVertices`); `$69BE`-`$69F1` (`ShipPythonFaces`); `$6C2A`-`$6C8D` (`ShipThargoidVertices`); 3 more ranges |
| Writes | `$A9A6`-`$A9B7` (`ViewMatrix`); `$FFE1`-`$FFEA` (`work space $FFE1+`) |

### `DividePoint` (`$AC69`)

**C = the fraction (A H L) / (D E C'), DE scaled to 8 bits first: the perspective division**

128713 runs of the normalising loop. C = 256 x numerator / denominator, `$FF` when the numerator is not smaller.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,303 calls, 9,140 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,306 calls, 9,161 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 15,107 calls, 106,148 t-states own (0.02 %) |
| Called from | `DrawShip`, `ProjectAdd` |
| Calls | `DividePointNormalise`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF1`-`$FFF2` (`work space $FFF1+`) |

### `DividePointNormalise` (`$AC6B`)

**DividePointNormalise**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 9,885 calls, 39,559 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 9,891 calls, 39,583 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 108,937 calls, 436,166 t-states own (0.09 %) |
| Called from | `DividePoint`, `DividePointShift` (tail) |
| Calls | `DividePointShift`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEB`-`$FFF4` (`work space $FFEB+`) |

### `DividePointShift` (`$AC6C`)

**DividePointShift**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 9,885 calls, 699,333 t-states own (0.37 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 9,891 calls, 699,786 t-states own (0.21 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 108,937 calls, 7,692,661 t-states own (1.65 %) |
| Called from | `DividePointNormalise` |
| Calls | `DividePointNormalise` (tail), `DividePointLoop`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE9`-`$FFF4` (`work space $FFE9+`) |

### `DividePointLoop` (`$AC8B`)

**DividePointLoop**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,724 calls, 1,251,351 t-states own (0.66 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4,979 calls, 2,233,213 t-states own (0.66 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 25,012 calls, 11,494,781 t-states own (2.46 %) |
| Called from | `DividePointShift`, `LineFraction` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE1`-`$FFF2` (`work space $FFE1+`) |

### `Project` (`$ACA2`)

**Rotate one vertex into the view (scaled, small or reused), add the ship's position and divide by the depth**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 572 calls, 181,654 t-states own (0.10 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 572 calls, 181,654 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,763 calls, 1,824,956 t-states own (0.39 %) |
| Called from | `ProjectVertex` (tail) |
| Calls | `RotateVertexScaled`, `RotateVertexSmall` (tail), `ProjectAdd`, `IM2Entry` |
| Reads | `$61E3`-`$6251` (`ShipAspVertices`); `$63FC`-`$6434` (`ShipCanisterVertices`); `$64BE`-`$6562` (`ShipCobraVertices`); `$68BE`-`$68D2` (`ShipPlateVertices`); `$6914`-`$6952` (`ShipPythonVertices`); `$6C2A`-`$6C9E` (`ShipThargoidVertices`); 2 more ranges |
| Writes | `$A9BB`-`$A9C7` (`VertexX`, `VertexY`, `VertexZ`, `ScreenX` and 6 more); `$AC9F`-`$ACA1` (`VertexHigh`); `$FFEB`-`$FFF2` (`work space $FFEB+`) |

### `ProjectAdd` (`$ACDF`)

**The ship's position plus the rotated vertex, then the screen point by the view's axes, stored in ProjectedPoints**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 572 calls, 662,389 t-states own (0.35 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 572 calls, 662,389 t-states own (0.20 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,763 calls, 7,845,789 t-states own (1.68 %) |
| Called from | `RotateVertexSmall` (tail), `Project` |
| Calls | `AddDoubled`, `DividePoint`, `ProjectNext`, `IM2Entry` |
| Reads | `$606F`-`$6077` (`ShipSlots`); `$6096`-`$609E` (`ShipSlots`); `$60BD`-`$60C5` (`ShipSlots`); `$60E4`-`$60EC` (`ShipSlots`); `$6159`-`$6161` (`Slot7`); `$70E3` (`ViewIndex`); 3 more ranges |
| Writes | `$A8FA`-`$A94D` (`ProjectedPoints`); `$A9BB`-`$A9C8` (`VertexX`, `VertexY`, `VertexZ`, `ScreenX` and 7 more); `$AC9F`-`$ACA1` (`VertexHigh`); `$FFE9`-`$FFF4` (`work space $FFE9+`) |

### `ProjectNext` (`$ADF2`)

**The next vertex**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 639 calls, 30,807 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 639 calls, 30,807 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 8,288 calls, 392,454 t-states own (0.08 %) |
| Called from | `ProjectVertex` (tail), `ProjectAdd` |
| Calls | `ProjectVertex` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFED`-`$FFF6` (`work space $FFED+`) |

### `DrawEdges` (`$AE01`)

**Each edge with a visible face, its distance passing and both ends in front: a line between its two points**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 54 calls, 379,388 t-states own (0.20 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 54 calls, 379,388 t-states own (0.11 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 502 calls, 3,259,661 t-states own (0.70 %) |
| Called from | `DrawShip` |
| Calls | `EitherFace`, `PointOf`, `DrawLine`, `IM2Entry` |
| Reads | `$61D0`-`$61DB` (`ShipAsp`); `$6255`-`$62C4` (`ShipAspEdges`); `$63E9`-`$63F4` (`ShipCanister`); `$6438`-`$6473` (`ShipCanisterEdges`); `$6494`-`$649F` (`ShipCobraTrader`); `$6566`-`$65FD` (`ShipCobraEdges`); 7 more ranges |
| Writes | `$FFED`-`$FFF8` (`work space $FFED+`) |

### `PointOf` (`$AE50`)

**D, E, A = the screen point of vertex A; NZ when it is hidden**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,950 calls, 226,460 t-states own (0.12 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,950 calls, 226,460 t-states own (0.07 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 16,885 calls, 1,961,457 t-states own (0.42 %) |
| Called from | `DrawShip`, `DrawEdges` |
| Calls | `IM2Entry` |
| Reads | `$A8FA`-`$A94D` (`ProjectedPoints`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE9`-`$FFF4` (`work space $FFE9+`) |

### `Orthogonalise` (`$AE69`)

**Make the roof axis square to the nose: roof -= nose x (roof . nose)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 145 calls, 30,488 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 173 calls, 36,330 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,363 calls, 286,287 t-states own (0.06 %) |
| Called from | `UpdateSlot`, `TurnTitleShip` |
| Calls | `DotProduct`, `OrthogonalisePart`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF1`-`$FFF2` (`work space $FFF1+`) |

### `OrthogonalisePart` (`$AE8A`)

**One part of it, clamped**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 435 calls, 118,720 t-states own (0.06 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 519 calls, 141,334 t-states own (0.04 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4,089 calls, 1,112,752 t-states own (0.24 %) |
| Called from | `Orthogonalise` |
| Calls | `Multiply8High`, `IM2Entry` |
| Reads | `$6052`-`$605C` (`ShipSlots`); `$6079`-`$6083` (`ShipSlots`); `$60A0`-`$60AA` (`ShipSlots`); `$60C7`-`$60D1` (`ShipSlots`); `$60EE`-`$60F8` (`ShipSlots`); `$6163`-`$616D` (`Slot7`); 1 more ranges |
| Writes | `$6058`-`$605C` (`ShipSlots`); `$607F`-`$6083` (`ShipSlots`); `$60A6`-`$60AA` (`ShipSlots`); `$60CD`-`$60D1` (`ShipSlots`); `$60F4`-`$60F8` (`ShipSlots`); `$6169`-`$616D` (`Slot7`); 1 more ranges |

### `ViewMatrixSetup` (`$AECC`)

**The side axis as the roof x nose cross product (three DifferenceOfProducts), and ViewMatrix filled from the three axes**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 29,617 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 29,617 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 502 calls, 278,897 t-states own (0.06 %) |
| Called from | `DrawShip` |
| Calls | `DifferenceOfProducts` |
| Reads | `$6079`-`$6083` (`ShipSlots`); `$60A0`-`$60AA` (`ShipSlots`); `$60C7`-`$60D1` (`ShipSlots`); `$60EE`-`$60F8` (`ShipSlots`); `$6163`-`$616D` (`Slot7`) |
| Writes | `$6085`-`$6089` (`ShipSlots`); `$60AC`-`$60B0` (`ShipSlots`); `$60D3`-`$60D7` (`ShipSlots`); `$60FA`-`$60FE` (`ShipSlots`); `$616F`-`$6173` (`Slot7`); `$A995`-`$A9A5` (`ViewMatrix`) |

### `DifferenceOfProducts` (`$AF22`)

**HL = B x C - D x E with the signs, halved: a part of a cross product**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 159 calls, 42,043 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 159 calls, 42,043 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,506 calls, 399,042 t-states own (0.09 %) |
| Called from | `ViewMatrixSetup` |
| Calls | `Multiply8`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFEF`-`$FFF0` (`work space $FFEF+`) |

### `MultiplyUnused` (`$AF64`)

**A sum of three 8 x 16 products (known from the code only: nothing calls it)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Divide16` (`$AFA8`)

**BC = (H L A) / DE: a 16-bit quotient by shifts**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 736 calls, 1,092,908 t-states own (0.58 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,584 calls, 5,301,465 t-states own (1.56 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 5,974 calls, 8,853,663 t-states own (1.89 %) |
| Called from | `Divide16Vector` (tail), `DivideComponent`, `SquareRootAdd` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE1`-`$FFFA` (`work space $FFE1+`) |

### `SubtractSigned` (`$AFC9`)

**(HL - DE) / 2 in sign and magnitude**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddSignedHalf` (`$AFCD`)

**(HL + DE) / 2 in sign and magnitude**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,378 calls, 158,783 t-states own (0.08 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,378 calls, 158,783 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 10,120 calls, 1,168,776 t-states own (0.25 %) |
| Called from | `FaceDot` (tail) |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFDF`-`$FFE6` (`work space $FFDF+`) |

## linedraw

`src/game/linedraw.asm`

### `DrawLine` (`$B044`)

**Draw a line between two points of the view (D E and H L, quadrants in C), clipped to the window**

14814 runs. `$FF` in both coordinates of an end (a hidden point) draws nothing.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,343 calls, 483,667 t-states own (0.26 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,595 calls, 1,286,655 t-states own (0.38 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 9,876 calls, 3,537,962 t-states own (0.76 %) |
| Called from | `DrawShip`, `DrawEdges`, `LaserBeams` (tail), `Gunsight` |
| Calls | `LineSetup`, `ClipLine` (tail), `LineAddress`, `LineSkip` (tail), `LineOctant`, `IM2Entry` |
| Reads | `$AFF2`-`$B009` (`LineSteps`); `$B01B`-`$B03F` (`LineSteps`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE5`-`$FFFA` (`work space $FFE5+`) |

### `LineSetup` (`$B0E0`)

**Pick the loop by the octant and patch its direction bytes and the fraction, then jump into it**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,343 calls, 262,267 t-states own (0.14 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,595 calls, 703,696 t-states own (0.21 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 9,652 calls, 1,891,698 t-states own (0.40 %) |
| Called from | `DrawLine`, `LineSkip` (tail) |
| Calls | `LineUpX` (tail), `LineUpY` (tail), `LineDownX` (tail), `LineDownY` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$B43B`-`$B440` (`LineUpX`); `$B458`-`$B46B` (`LineUpX`, `LineUpY`); `$B48C`-`$B491` (`LineDownX`); `$B4A9`-`$B4B8` (`LineDownX`, `LineDownY`); `$B4D1` (`LineDownY`); `$FFEB`-`$FFFA` (`work space $FFEB+`) |

### `ClipLine` (`$B18A`)

**One or both ends outside: the crossing with the window's edge from the slope, then the visible part**

10 runs over f1, w1, d1 (the station near the edge).

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 10 calls, 5,716 t-states own (0.00 %) |
| Called from | `DrawLine` (tail) |
| Calls | `MultiplyRound`, `LineFraction`, `LineAddress`, `LineSkip` (tail), `LineOctant` |
| Reads | `$B040`-`$B043` (`ClipSave`, `ClipSlope`) |
| Writes | `$B040`-`$B043` (`ClipSave`, `ClipSlope`) |

### `MultiplyRound` (`$B2F0`)

**C = A x C / 256, rounded**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 196 t-states own (0.00 %) |
| Called from | `ClipLine` |
| Calls | `Multiply8` |

### `LineFraction` (`$B2FE`)

**C = A x 256 / B (A below B): the slope**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,420 calls, 88,078 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,672 calls, 227,740 t-states own (0.07 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 9,992 calls, 619,827 t-states own (0.13 %) |
| Called from | `ClipLine`, `LineSkip`, `LineOctant` |
| Calls | `DividePointLoop`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE5`-`$FFF2` (`work space $FFE5+`) |

### `LineAddress` (`$B308`)

**The start point's back-buffer address (HL'), its pixel (C') and the pixels to the next character row (B'); the page byte at `$B348` is `$C0`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,343 calls, 593,802 t-states own (0.31 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,595 calls, 1,685,949 t-states own (0.50 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 9,652 calls, 4,194,089 t-states own (0.90 %) |
| Called from | `DrawLine`, `ClipLine` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE7`-`$FFF6` (`work space $FFE7+`) |

### `LineSkip` (`$B362`)

**The pixels of the line before the window: the start moved in by the slope**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 70 calls, 12,803 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 70 calls, 12,803 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 266 calls, 50,211 t-states own (0.01 %) |
| Called from | `DrawLine` (tail), `ClipLine` (tail) |
| Calls | `LineSetup` (tail), `LineFraction`, `LineOctant` |

### `LineOctant` (`$B3A7`)

**The differences, the octant (B's bits 4-7) and the slope as a fraction (C)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,413 calls, 517,034 t-states own (0.27 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3,665 calls, 1,333,922 t-states own (0.39 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 9,929 calls, 3,674,242 t-states own (0.79 %) |
| Called from | `DrawLine`, `ClipLine`, `LineSkip` |
| Calls | `LineFraction`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE9`-`$FFF8` (`work space $FFE9+`) |

### `LineUpXRow` (`$B433`)

**The y-major loop going up: a row up a step, a pixel across on the fraction's carry**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LineUpX` (`$B434`)

**LineUpX**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 245 calls, 534,241 t-states own (0.28 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 796 calls, 826,366 t-states own (0.24 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,539 calls, 3,327,690 t-states own (0.71 %) |
| Called from | `LineSetup` (tail) |
| Calls | `IM2Entry` |
| Reads | `$C002` (`BackBuffer`); `$C020`-`$CEE7` (`BackBuffer`); `$CF00`-`$CFDE` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$C002` (`BackBuffer`); `$C020`-`$CEE7` (`BackBuffer`); `$CF00`-`$CFDE` (`BackBuffer`); `$FFEB`-`$FFF6` (`work space $FFEB+`) |

### `LineUpY` (`$B464`)

**The x-major loop going up: a pixel across a step, a row up on the carry**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 222 calls, 476,835 t-states own (0.25 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 222 calls, 476,835 t-states own (0.14 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,405 calls, 2,922,142 t-states own (0.62 %) |
| Called from | `LineSetup` (tail) |
| Calls | `IM2Entry` |
| Reads | `$C022`-`$CFDE` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$C022`-`$CFDE` (`BackBuffer`); `$FFEB`-`$FFF4` (`work space $FFEB+`) |

### `LineDownX` (`$B485`)

**The y-major loop going down**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 452 calls, 1,169,322 t-states own (0.62 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,006 calls, 1,499,304 t-states own (0.44 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,954 calls, 2,722,827 t-states own (0.58 %) |
| Called from | `LineSetup` (tail) |
| Calls | `IM2Entry` |
| Reads | `$C017`-`$CEDF` (`BackBuffer`); `$CF03`-`$CFDE` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$C017`-`$CEDF` (`BackBuffer`); `$CF03`-`$CFDE` (`BackBuffer`); `$FFEB`-`$FFFA` (`work space $FFEB+`) |

### `LineDownY` (`$B4B1`)

**The x-major loop going down**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 424 calls, 716,411 t-states own (0.38 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,571 calls, 1,581,560 t-states own (0.47 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,754 calls, 3,227,750 t-states own (0.69 %) |
| Called from | `LineSetup` (tail) |
| Calls | `IM2Entry` |
| Reads | `$C003`-`$CFDF` (`BackBuffer`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$C003`-`$CFDF` (`BackBuffer`); `$FFEB`-`$FFFA` (`work space $FFEB+`) |

## combat

`src/game/combat.asm`

### `Collide` (`$B4D8`)

**A ship inside the player's box: scooped, docked, or both hit**

The box is the blueprint's size (+`$01`; 180 for scoopables; z one more page for a missile with no target) on each axis, with z ahead only. Scoopable and below (y negative) with the fuel scoop (`$D088`): the slot is freed and the hold gains one of the cargo in the blueprint's +`$00` high nibble (or a random 0-7, or the mission's item) through AddCargo `$D0E4`, if the hold has room (`$D07C`). The station: ahead, upright (its nose's z negative, the roof's within `$3C`) and not hostile docks (Docked = 1); else a crash costs the front shield `$0C` + 2 x speed. Anything else is destroyed and its size hits the front or aft shield. The sun or the planet too near (TooClose) skips this. dk docked at frame 2190, cs scooped a plate at 910 (AddCargo); a crash is known from the code only.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 29,019 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 120 calls, 37,705 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,076 calls, 217,798 t-states own (0.05 %) |
| Called from | `UpdateSlot` |
| Calls | `IM2Entry` |
| Reads | `$6048`-`$604F` (`ShipSlots`); `$606E`-`$6070` (`ShipSlots`); `$6095`-`$609D` (`ShipSlots`); `$60BC`-`$60C4` (`ShipSlots`); `$60E3`-`$60E5` (`ShipSlots`); `$610A` (`ShipSlots`); 4 more ranges |
| Writes | `$FFF5`-`$FFF6` (`work space $FFF5+`) |

### `RemoveShip` (`$B5DF`)

**A ship gone: every missile aimed at it explodes, and the player's missile loses its lock on it**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 555 t-states own (0.00 %) |
| Called from | `UpdateShip` (tail) |
| Reads | `$6091` (`ShipSlots`); `$60B8` (`ShipSlots`); `$60DF` (`ShipSlots`); `$6106` (`ShipSlots`); `$612D` (`ShipSlots`); `$6154` (`ShipSlots`); 3 more ranges |

### `ShipsWreck` (`$B618`)

**The player's death: the explosion's sound, the front view, every slot free, then a canister and two plates near (actions `$16` and `$15`)**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 524 t-states own (0.00 %) |
| Called from | `ResetShipsVector` (tail) |
| Calls | `ShipAction` |
| Reads | `$7128` (`SoundRequests`) |
| Writes | `$606A` (`ShipSlots`); `$6091` (`ShipSlots`); `$60B8` (`ShipSlots`); `$60DF` (`ShipSlots`); `$6106` (`ShipSlots`); `$612D` (`ShipSlots`); 4 more ranges |

### `LaserCooling` (`$B63C`)

**The laser temperature falls by 2 a frame; A (the fire key, KeyCombat bit 0) fires the view's laser below `$90`**

LaserMounts `$D07D` (one byte per view): 1 pulse, 2 beam, 3 military, 4 mining (EquipLaser). A press fires at once; held, a pulse laser fires every other pass and a mining one every eighth (JumpEncounter's low bits, D = 1 or 7), a beam or military laser every pass. Each shot is drain 1, the laser sound and heat `$08` (pulse, mining) or `$0A` (beam, military), capped at `$A0`. The power is `$0F` (pulse, beam), `$17` (military), `$32` (mining). A hit on SightTarget turns it hostile, its tactics state down by 14, and its energy down by the power; at 0 it is destroyed (`$FF`), and gives a canister of alloys (action 6), an asteroid splinters (5), the mining laser on a Rock Hermit or a boulder plates (8), or ends the mission ship (3). 30 recorded frames fired; none hit.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 11,256 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 84,636 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 341 calls, 51,073 t-states own (0.01 %) |
| Called from | `Gunsight` |
| Calls | `LaserBeams` (tail) |
| Reads | `$70E3`-`$70F0` (`ViewIndex`, `RollRate`, `PitchRate`, `SpeedRate` and 1 more); `$7128` (`SoundRequests`); `$9C93`-`$9CA2` (`JumpEncounter`, `ShipsAbout`, `BombKill`, `ShipsPresent` and 8 more); `$B4D7` (`LaserFired`); `$D07D` (`LaserMounts`); `$FC0B` (`KeyCombat`) |
| Writes | `$70F0` (`BarDrawn`); `$7128` (`SoundRequests`); `$9CA2` (`EnergyDrain`); `$B4D7` (`LaserFired`); `$FC0B` (`KeyCombat`) |

### `LaserBeams` (`$B749`)

**Two or four random lines from the bottom corners (`$543F`, `$403F`) towards the centre: the beam**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 12 calls, 4,704 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 7,056 t-states own (0.00 %) |
| Called from | `LaserCooling` (tail) |
| Calls | `DrawLine` (tail), `Random` |
| Reads | `$B4D6` (`LaserBeam`) |
| Writes | `$B4D6` (`LaserBeam`) |

### `Random` (`$B799`)

**A = a random byte: the seed's two bytes added with the carry**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5 calls, 540 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 21 calls, 2,268 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 208 calls, 22,464 t-states own (0.00 %) |
| Called from | `TacticsAim`, `DrawShip`, `LaserBeams`, `CreateShip`, `ActionThargoids`, `RandomRoll`, `DebrisNear`, `SpawnShip` |
| Reads | `$B7AA`-`$B7AB` (`RandomSeed`) |
| Writes | `$B7AA`-`$B7AB` (`RandomSeed`) |

### `ClearFirearmPrices` (`$B7AC`)

**Dead: two bytes of the market (`$7043`, `$7044`) zeroed**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Gunsight` (`$B7B4`)

**The four lines of the cross when the view has a laser, the laser, then the ECM (E)**

The ECM on (ECMActive, 10 frames): each frame drain 1 and the ECM sound; at 0 the ECM is off. E (KeyCombat bit 4) turns it on with an ECM system fitted (`$D085`, bit 7 its state). It is not offered in mission state 4 with the mission flag set (`$D0B0` bit 7).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 92 calls, 42,464 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 643 calls, 296,735 t-states own (0.09 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 371 calls, 159,448 t-states own (0.03 %) |
| Called from | `ShipsAndLaser` (tail) |
| Calls | `DrawLine`, `LaserCooling`, `IM2Entry` |
| Reads | `$70E3` (`ViewIndex`); `$711F` (`TooClose`); `$9C9B` (`ECMActive`); `$D07D`-`$D085` (`LaserMounts`, `NovaMission`, `Fuel`, `Missiles` and 1 more); `$D0B0` (`MissionFlags`); `$FC0B` (`KeyCombat`); 1 more ranges |
| Writes | `$7043`-`$7044` (`Commodities`); `$FC0B` (`KeyCombat`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `ShipAction` (`$B867`)

**Do ship action A (low nibble) with argument C (high nibble)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 174 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 280 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 5 calls, 665 t-states own (0.00 %) |
| Called from | `ShipActionVector` (tail), `UpdateShips`, `ShipsWreck` |
| Calls | `ActionThargoids` (tail), `ActionPlates` (tail), `ActionCanister` (tail), `ActionTitleShip` (tail), `SpawnShip` (tail) |

### `CreateShip` (`$B898`)

**Fill slot IX for blueprint A (bits 0-5): the template, the blueprint's values, a random position unless hostile**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 1,365 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 1,365 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 9 calls, 13,356 t-states own (0.00 %) |
| Called from | `CreateAtOrigin`, `ActionThargoids`, `ActionTitleShip` |
| Calls | `Random` |
| Reads | `$6071`-`$6074` (`ShipSlots`); `$608F`-`$609B` (`ShipSlots`); `$60B6`-`$60C2` (`ShipSlots`); `$60DD`-`$60E9` (`ShipSlots`); `$6104`-`$6105` (`ShipSlots`); `$615B`-`$615E` (`Slot7`); 9 more ranges |
| Writes | `$606F`-`$610A` (`ShipSlots`); `$6159`-`$617F` (`Slot7`) |

### `LaunchShip` (`$B91E`)

**Create blueprint A in a free slot at ship IX's position and axes (27 bytes copied); NZ when no slot is free**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FreeSlot` (`$B936`)

**IX = the first free slot of 1-6 (Z), NZ when none**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 7 calls, 1,065 t-states own (0.00 %) |
| Called from | `CreateAtOrigin`, `ActionThargoids` |
| Reads | `$6091` (`ShipSlots`); `$60B8` (`ShipSlots`); `$60DF` (`ShipSlots`); `$6106` (`ShipSlots`) |

### `CreateAtOrigin` (`$B94A`)

**Create blueprint A in a free slot at the origin**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 683 t-states own (0.00 %) |
| Called from | `DebrisNear` |
| Calls | `CreateShip`, `FreeSlot` |
| Reads | `$607D`-`$6085` (`ShipSlots`); `$60A4`-`$60AC` (`ShipSlots`); `$60CB`-`$60D3` (`ShipSlots`) |
| Writes | `$606F`-`$6085` (`ShipSlots`); `$6096`-`$60AC` (`ShipSlots`); `$60BD`-`$60D3` (`ShipSlots`) |

### `CreateHere` (`$B950`)

**Create blueprint A in IX at the origin, its nose and side turned**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ActionThargoids` (`$B96B`)

**Action 1: three or four Thargoids with ECM, ahead at random**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 976 t-states own (0.00 %) |
| Called from | `ShipAction` (tail) |
| Calls | `Random`, `CreateShip`, `FreeSlot`, `RandomRoll` |
| Reads | `$6094` (`ShipSlots`); `$60BB` (`ShipSlots`); `$60E2` (`ShipSlots`); `$6109` (`ShipSlots`) |
| Writes | `$6070`-`$6076` (`ShipSlots`); `$6094`-`$609D` (`ShipSlots`); `$60BB`-`$60C4` (`ShipSlots`); `$60E2`-`$60EB` (`ShipSlots`); `$6109` (`ShipSlots`) |

### `ActionMissile` (`$B99F`)

**Action 2: a missile. C = 0: from ship IX at the player; else the player's, slot 7, below the view aimed at target C**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ActionLaunch` (`$B9E7`)

**Action 4: a ship from IX; C 1 a Viper, 2 a trader (Cobra or Python), 3 a Thargon, 4 a Thargoid, 5 a Sidewinder or a Krait**

The new ship is turned about (FlipShip) unless it leaves the station, and is hostile when its launcher is.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FlipShip` (`$BA27`)

**Turn a launched ship about one way or the other (in turn)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SwapAxisPair` (`$BA3F`)

**One pair of nose and roof parts swapped, the side's sign flipped**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RandomRoll` (`$BA83`)

**Random roll and pitch counters (bits 0-2 and 7)**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 7 calls, 681 t-states own (0.00 %) |
| Called from | `ActionThargoids`, `DebrisNear` |
| Calls | `Random` |
| Writes | `$6079`-`$607B` (`ShipSlots`); `$60A0`-`$60A2` (`ShipSlots`); `$60C7`-`$60C9` (`ShipSlots`); `$60EE`-`$60F0` (`ShipSlots`) |

### `ActionPlates` (`$BA94`)

**Action 5: two alloy plates; C bit 0 near the origin (PlateNear called, then fallen into), else from IX**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 37 t-states own (0.00 %) |
| Called from | `ShipAction` (tail) |
| Calls | `PlateNear` |

### `PlateNear` (`$BA9C`)

**A plate at a random place just ahead**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 14 t-states own (0.00 %) |
| Called from | `ActionPlates` |
| Calls | `DebrisNear` |

### `DebrisNear` (`$BA9E`)

**Debris A at a random place ahead (`$10-$4F` across, `$19` deep), spinning, at a random speed**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 1,252 t-states own (0.00 %) |
| Called from | `PlateNear`, `ActionCanister` (tail) |
| Calls | `Random`, `CreateAtOrigin`, `RandomRoll` |
| Reads | `$6079`-`$607B` (`ShipSlots`); `$608F` (`ShipSlots`); `$60A0`-`$60A2` (`ShipSlots`); `$60B6` (`ShipSlots`); `$60C7`-`$60C9` (`ShipSlots`); `$60DD` (`ShipSlots`) |
| Writes | `$606F`-`$6075` (`ShipSlots`); `$608A`-`$609C` (`ShipSlots`); `$60B1`-`$60C3` (`ShipSlots`); `$60D8`-`$60DD` (`ShipSlots`) |

### `ActionCanister` (`$BAF2`)

**Action 6: a canister; C bit 0 near, else from IX**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 34 t-states own (0.00 %) |
| Called from | `ShipAction` (tail) |
| Calls | `DebrisNear` (tail) |

### `ActionPod` (`$BAFA`)

**Action 7: the escape pod; C bit 0 the player's Cobra flying off in slot 6, else a pod from IX**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ActionSplinters` (`$BB4D`)

**Action 8: two splinters from IX**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DebrisFromShip` (`$BB55`)

**Debris A from IX, turned, passive, spinning for ever**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ActionTitleShip` (`$BB75`)

**Action 9: blueprint C + 2 in slot 7 for the title, its axes from TitleShipAxes, spinning**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 640 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 640 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 1,340 t-states own (0.00 %) |
| Called from | `ShipAction` (tail) |
| Calls | `CreateShip` |
| Reads | `$6179` (`Slot7`); `$B85D`-`$B865` (`TitleShipAxes`) |
| Writes | `$6159`-`$6179` (`Slot7`) |

### `SpawnShip` (`$BBBA`)

**Action 0: maybe a new ship: the mission's Asp, an asteroid, pirates, traders, hunters or Thargoids**

The danger C is (slaves + narcotics) x 2 + firearms in the hold (`$D06E`, `$D071`, `$D075`). A random byte below `$1E` with the mission's conditions (`$D0B0` AND `$42` = 2) brings the mission's Asp. Else a random byte less the danger: 80-89 an asteroid, 90 and up nothing; below 80, or below the danger (a borrow), SpawnDanger: a Thargoid in mission state 4, a Python in state 1, else by the government (`$D09D`: anarchies always) a lone pirate (`$0B-$0F`, the rarer the stronger, one in five with ECM), a trader or a Rock Hermit, or a group of two or three Sidewinders and Kraits.

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 338 t-states own (0.00 %) |
| Called from | `ShipAction` (tail) |
| Calls | `Random` |
| Reads | `$9CB2` (`MissionShip`); `$D06E`-`$D075` (`CargoHold`) |

### `SpawnMissionDone` (`$BBF2`)

**The Asp's own state after the mission spawn (m2 frame 7922: the cloak ship's Asp, MissionFlags `$07`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FaceVisibility` (`$BCD4`)

**Each face: visible when its rotated normal points at the player (the dot product with the ship's position is negative)**

A face whose visibility distance passes is tested; one that fails is hidden. A ship with no faces (+`$05` = 0) shows everything. 608 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 320,593 t-states own (0.17 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 320,593 t-states own (0.09 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 502 calls, 2,388,882 t-states own (0.51 %) |
| Called from | `DrawShip` |
| Calls | `FaceDot`, `NormalPart`, `IM2Entry` |
| Reads | `$61D1`-`$61DF` (`ShipAsp`); `$62C8`-`$62F4` (`ShipAspFaces`); `$63EA`-`$63F8` (`ShipCanister`); `$6477`-`$64A3` (`ShipCanisterFaces`, `ShipCobraTrader`); `$6601`-`$6631` (`ShipCobraFaces`); `$68AC`-`$68BA` (`ShipPlate`); 7 more ranges |
| Writes | `$A984`-`$A990` (`FaceVisible`); `$BCC8`-`$BCD3` (`FaceBlueprint`, `FaceScale`, `FaceNormal`, `FaceSigns`); `$FFE7`-`$FFF4` (`work space $FFE7+`) |

### `FaceDot` (`$BD5F`)

**The dot product of the rotated normal and the position, three terms summed**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 689 calls, 225,701 t-states own (0.12 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 689 calls, 225,701 t-states own (0.07 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 5,060 calls, 1,658,392 t-states own (0.35 %) |
| Called from | `FaceVisibility` |
| Calls | `AddSignedHalf` (tail), `MultiplyWord`, `IM2Entry` |
| Reads | `$BCCB`-`$BCD3` (`FaceNormal`, `FaceSigns`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFE1`-`$FFEC` (`work space $FFE1+`) |

### `MultiplyWord` (`$BD95`)

**A (sign and magnitude) times the word C E: two products summed**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,067 calls, 341,321 t-states own (0.18 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,067 calls, 341,321 t-states own (0.10 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 15,180 calls, 2,506,828 t-states own (0.54 %) |
| Called from | `FaceDot` |
| Calls | `Multiply8High`, `Multiply8`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFDF`-`$FFEA` (`work space $FFDF+`) |

### `NormalPart` (`$BDB4`)

**One rotated part of the normal, scaled by the blueprint's +`$13`, the ship's position part added**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,067 calls, 782,717 t-states own (0.41 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,067 calls, 782,717 t-states own (0.23 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 15,180 calls, 6,020,436 t-states own (1.29 %) |
| Called from | `FaceVisibility` |
| Calls | `RotateNormal`, `IM2Entry` |
| Reads | `$606F`-`$6077` (`ShipSlots`); `$6096`-`$609E` (`ShipSlots`); `$60BD`-`$60C5` (`ShipSlots`); `$60E4`-`$60EC` (`ShipSlots`); `$6159`-`$6161` (`Slot7`); `$BCCA` (`FaceScale`); 1 more ranges |
| Writes | `$FFE1`-`$FFEE` (`work space $FFE1+`) |

## gamestate

`src/game/gamestate.asm`

### `ScreenBuy` (`$D000`)

**ScreenTable 0: buy cargo (the key 2 docked)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScreenSell` (`$D003`)

**ScreenTable 1: sell cargo (3)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScreenEquip` (`$D006`)

**ScreenTable 2: equip the ship (4)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScreenGalaxy` (`$D009`)

**ScreenTable 3: the galactic chart (I)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Called from | `CallScreen` |
| Calls | `GalacticChart` (tail) |

### `ScreenLocal` (`$D00C`)

**ScreenTable 4: the local chart (O)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 10 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 10 t-states own (0.00 %) |
| Called from | `CallScreen` |
| Calls | `ShortRangeChart` (tail) |

### `ScreenData` (`$D00F`)

**ScreenTable 5: the data on a system (P)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Called from | `CallScreen` |
| Calls | `DataScreen` (tail) |

### `ScreenMarket` (`$D012`)

**ScreenTable 6: the market prices (K)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Called from | `CallScreen` |
| Calls | `MarketPrices` (tail) |

### `ScreenStatus` (`$D015`)

**ScreenTable 7: the commander's status (L), also after a dock**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 10 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 10 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `StatusScreen` (tail) |

### `ScreenInventory` (`$D018`)

**ScreenTable 8: the inventory (ENTER)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CursorLeft` (`$D01B`)

**ScreenTable 9-15: the chart keys (ChartCursorKeys): 9 left (N, KeySteer bit 0), the cursor one x less (ChartLeft)**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 6 calls, 60 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6 calls, 60 t-states own (0.00 %) |
| Called from | `CallScreen` |
| Calls | `ChartLeft` (tail) |

### `CursorRight` (`$D01E`)

**10: right (M), ChartRight**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CursorDown` (`$D021`)

**11: down (X), two y more, ChartDown**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CursorUp` (`$D024`)

**12: up (S), ChartUp**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CursorHome` (`$D027`)

**13: B (KeyChart bit 4), the cursor back on the current system (ChartHome)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CursorDistance` (`$D02A`)

**14: D (KeyChart bit 5), the nearest system's name and distance (ShowSelected)**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 20 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 20 t-states own (0.00 %) |
| Called from | `CallScreen` |
| Calls | `ShowSelected` (tail) |

### `PlanetNameVector` (`$D02D`)

**15: R (KeyChart bit 6), PLANET NAME? (PlanetNamePrompt)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NextGalaxyVector` (`$D030`)

**ScreenTable 16: NextGalaxy: no key and no caller asks for 16 (CallScreen gets 0-15), so it is never reached**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NewGameVector` (`$D033`)

**NewGame `$D298`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 10 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 10 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `NewGame` (tail) |

### `ClearScreenVector` (`$D036`)

**ClearScreen `$D61D`: the page cleared, its frame drawn**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 10 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 10 t-states own (0.00 %) |
| Called from | `DashboardRestore` |
| Calls | `ClearScreen` (tail) |

### `PrintOtherVector` (`$D039`)

**PrintOther `$D45F`: the other token set**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 53 calls, 530 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 53 calls, 530 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 317 calls, 3,170 t-states own (0.00 %) |
| Called from | `TitleNext`, `TitleTextPrint` |
| Calls | `PrintOther` (tail) |

### `ViewTextsVector` (`$D03C`)

**ViewTexts `$DA7A`: the view's texts and the countdown**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 140 calls, 1,400 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 691 calls, 6,910 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 389 calls, 3,890 t-states own (0.00 %) |
| Called from | `TitleLoad`, `TitleNext`, `TunnelFrameText` |
| Calls | `ViewTexts` (tail) |

### `JumpKeysVector` (`$D042`)

**JumpKeys `$DBA2`: the hyperspace keys (in the interrupt)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 120,160 calls, 1,201,600 t-states own (0.63 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 38,713 calls, 387,301 t-states own (0.11 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 38,410 calls, 384,100 t-states own (0.08 %) |
| Called from | `TitleLoad`, `TitleNext` |
| Calls | `JumpKeys` (tail), `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `PrintCodeVector` (`$D048`)

**PrintCode `$D425`: the standard token set**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 977 calls, 9,770 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 6,487 calls, 64,870 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3,701 calls, 37,010 t-states own (0.01 %) |
| Called from | `TitleElite`, `DrawIndicators`, `PrintNext`, `DrawMissiles` |
| Calls | `PrintCode` (tail) |

### `CommanderMenuVector` (`$D04E`)

**CommanderMenu `$D90A`: load or save a commander**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FullMessageVector` (`$D0D7`)

**Vectors: a full-page message, the dashboard keys off, the mission question**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearHighlightsVector` (`$D0DA`)

**ClearHighlightsVector**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 10 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 10 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 10 t-states own (0.00 %) |
| Called from | `ResetFlight` |
| Calls | `ClearMessages` (tail) |

### `MissionQuestionVector` (`$D0DD`)

**MissionQuestionVector**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TradeDoneVector` (`$D0E0`)

**TradeDoneVector**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddCargoVector` (`$D0E4`)

**AddCargo `$D190`: a scooped item**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddCashVector` (`$D0E7`)

**AddCash `$D1D9`: a bounty**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddCombatVector` (`$D0EA`)

**AddCombat `$D1C7`: the combat score**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissionDoneVector` (`$D0ED`)

**MissionDone `$D14D`**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DamageVector` (`$D0F3`)

**DamageItem `$D1E9`: a hit that went through the shields**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 25 calls, 250 t-states own (0.00 %) |
| Called from | `ShieldHit` (tail) |
| Calls | `DamageItem` (tail) |

### `FullMessage` (`$D0F6`)

**A game over page: SHIP BOARDED BY (other `$0B`), other token A (`$0D` PIRATE, `$D4` THARGON) and S, THEY SHOW NO MERCY... (other `$FF`), a click, a key, the page cleared**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissionQuestion` (`$D123`)

**WANTED BY GALCOP: A BRAVE COMMANDER FOR A SPECIAL MISSION, ARE YOU INTERESTED (Y/N)? (other `$DF`); Y: state 3, flag bit 7 and the briefing (other `$E0`); any other key: state 0**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissionText` (`$D148`)

**MissionText**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissionDone` (`$D14D`)

**The Thargoid mission's award: the combat score's high byte one more, state 0, flag bit 3, IN APPRECIATION OF YOUR EXCEPTIONAL COURAGE ... (other `$0A`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ColourPage` (`$D162`)

**Clear the page, other token `$5C` (a capital next), all 768 attributes E, the position HL, then other token D**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddCargoSpecial` (`$D183`)

**`$FF`: the cloak ship's canister: the cloaking device (flag bit 6), the combat score's high byte one more, CLOAKING DEVICE on the message line**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddCargo` (`$D190`)

**One unit of commodity A into the hold (one less free space), the message, and the legal cost of the contraband**

Firearms (`$0A`) cost 2, slaves (3) and narcotics (6) cost 4 on LegalStatus, up to `$FF`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddCargoContraband` (`$D1AD`)

**AddCargoContraband**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddCombat` (`$D1C7`)

**The combat score plus DE; a carry into the third byte flags the rating message (`$D0C9`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddCash` (`$D1D9`)

**The cash plus DE (a bounty) and the message (`$D0C5`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DamageItem` (`$D1E9`)

**A random loss: below 1 the fuel, 1-6 a piece of equipment, 7-16 a unit of cargo (StarSeed's bits)**

25 runs in f1 and w1 (the ships' lasers), none lost anything: every random pick was empty or 17 and above.

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 25 calls, 2,122 t-states own (0.00 %) |
| Called from | `DamageVector` (tail) |
| Calls | `AddAToHL` |
| Reads | `$7105` (`StarSeed`); `$D085` (`Equipment`); `$DA76` (`MessageToken`) |

### `NewGame` (`$D298`)

**The default commander copied in, the chart cursor on Lave, the prices made (MakeMarket with its stock store patched to a NOP: the stock is the record's), the sun placed**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 2,642 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 2,642 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 2,642 t-states own (0.00 %) |
| Called from | `NewGameVector` (tail) |
| Calls | `ClearMessages`, `FindNearestNow`, `MakeMarket` |
| Reads | `$D097`-`$D099` (`Seeds`); `$D232`-`$D297` (`DefaultCommander`, `DefaultSun`); `$DEED`-`$DEF4` (`SelectedName`) |
| Writes | `$7107`-`$710F` (`SunPosition`); `$D054`-`$D0BC` (`CommanderName`, `LegalStatus`, `CombatScore`, `CommanderRest` and 15 more); `$DBA1` (`JumpCountdown`); `$DEE4`-`$DEEB` (`CurrentName`); `$E1B0` (`MakeMarket`) |

## textprint

`src/game/textprint.asm`

### `PrintByteDot` (`$D2DE`)

**Print A as a number with one decimal place**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 32 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 16 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 16 t-states own (0.00 %) |
| Called from | `ControlFuelValue`, `DataScreen` |
| Calls | `PrintByteNow` (tail) |

### `PrintByte` (`$D2E1`)

**Print A as a number**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 14 calls, 56 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 20 calls, 80 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 20 calls, 80 t-states own (0.00 %) |
| Called from | `ControlGalaxy` (tail), `JumpTick` (tail), `MarketRow`, `DataScreen` |
| Calls | `PrintByteNow` |

### `PrintByteNow` (`$D2E2`)

**PrintByteNow**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 16 calls, 176 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 21 calls, 231 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 21 calls, 231 t-states own (0.00 %) |
| Called from | `PrintByteDot` (tail), `PrintByte` |
| Calls | `PrintNumber` |

### `PrintNumber` (`$D2E5`)

**Print HL in decimal (carry: the last digit after a point), padded to the width `$D0CE`**

Five digits by repeated subtraction (PrintDigit) from 10000 down, the leading zeros left out (`$D0CC` on until a non-zero digit). 1512 runs: the status, the market and the charts' numbers.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 36 calls, 8,520 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 24 calls, 5,316 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 24 calls, 5,316 t-states own (0.00 %) |
| Called from | `PrintByteNow`, `PrintCash` (tail), `PrintDistance`, `MarketRow`, `DataScreen`, `PrintRadius` (tail) |
| Calls | `PrintNumberUnits` (tail), `PrintDigit`, `PadNumber`, `PrintInline` |
| Reads | `$D0CC` (`Messages`) |
| Writes | `$D0CC` (`Messages`); `$D2DC`-`$D2DD` (`NumberLeft`) |

### `PrintNumberUnits` (`$D31D`)

**The last digit**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 16 calls, 2,916 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 20 calls, 1,944 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 20 calls, 1,944 t-states own (0.00 %) |
| Called from | `PrintNumber` (tail), `PrintChar`, `PlotChar` |
| Calls | `PrintDigitChar` |
| Reads | `$D2DC`-`$D2DD` (`NumberLeft`) |
| Writes | `$D0CC`-`$D0CE` (`Messages`) |

### `PrintCash` (`$D32D`)

**Print the cash: the thousands (`$D066`) and the rest (`$D068`, tenths), with the point**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 111 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 111 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 111 t-states own (0.00 %) |
| Called from | `ControlCash` |
| Calls | `PrintNumber` (tail) |
| Reads | `$D066`-`$D069` (`CommanderRest`) |
| Writes | `$D0CE` (`Messages`) |

### `PrintCashNow` (`$D334`)

**PrintCashNow**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintDigit` (`$D357`)

**One digit: how many DE fit in NumberLeft, printed unless a leading zero**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 144 calls, 24,595 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 96 calls, 12,658 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 96 calls, 12,658 t-states own (0.00 %) |
| Called from | `PrintNumber` |
| Calls | `PrintDigitChar`, `IM2Entry` |
| Reads | `$D0CC` (`Messages`); `$D2DC`-`$D2DD` (`NumberLeft`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF4`-`$CFF5` (`BackBuffer`); `$D0CC` (`Messages`); `$D2DC`-`$D2DD` (`NumberLeft`) |

### `PrintDigitChar` (`$D371`)

**Print digit A**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 90 calls, 1,530 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 32 calls, 544 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 32 calls, 544 t-states own (0.00 %) |
| Called from | `PrintNumberUnits`, `PrintDigit` |
| Calls | `PrintCode` (tail) |

### `PadNumber` (`$D37D`)

**Print the spaces (or zeros) that bring the number to the width**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 36 calls, 9,266 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 24 calls, 5,304 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 24 calls, 5,304 t-states own (0.00 %) |
| Called from | `PrintNumber` |
| Calls | `AtLeast`, `PrintCode` |
| Reads | `$D0CC`-`$D0CE` (`Messages`) |

### `AtLeast` (`$D3CE`)

**NC when HL is at least DE (HL kept)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 90 calls, 4,140 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 32 calls, 1,472 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 32 calls, 1,472 t-states own (0.00 %) |
| Called from | `PadNumber` |

### `AddCredits` (`$D3D3`)

**The cash's tenths plus DE, carrying 10000 into the thousands**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddThousands` (`$D3E7`)

**The thousands plus DE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TakeThousands` (`$D3EF`)

**The thousands less DE; carry when not enough**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TakeCredits` (`$D3FD`)

**The cash less DE tenths, borrowing a thousand; carry when not enough**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintInline` (`$D421`)

**Print the standard code in the byte after the CALL**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 45 calls, 1,530 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 18 calls, 612 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 612 t-states own (0.00 %) |
| Called from | `PrintNumber`, `ControlFuel`, `PrintDistance`, `MarketRow`, `PrintCapitals`, `PrintUnit`, `DataScreen`, `StatusScreen`, `StatusSystem` |
| Calls | `PrintCode` |
| Reads | `$D31C` (`PointCode`); `$D83F` (`FuelSpace`); `$E122` (`PrintDistance`); `$E24C` (`MarketRow`); `$E2FC` (`PrintCapitals`); `$E346` (`PrintUnit`); 3 more ranges |

### `PrintCode` (`$D425`)

**Print code A of the standard set: a control, a character, a pair or a token**

228436 runs over f1, w1, d1.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4,426 calls, 5,297,548 t-states own (2.80 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 16,471 calls, 16,957,588 t-states own (5.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 14,617 calls, 17,259,877 t-states own (3.69 %) |
| Called from | `PrintCodeVector` (tail), `PrintDigitChar` (tail), `PadNumber`, `PrintInline`, `PrintOtherChar` (tail), `ViewTexts`, `MarketRow`, `PrintCodeColon`, `PrintCodeSpace`, `PrintCodeNow` (tail), `PrintCodeLine`, `PrintCapitals` (tail), `PageTitle` (tail), `PrintCodes`, `PrintUnit`, `PrintUnitNow` (tail), `PrintEconomy`, `PrintSpecies` (tail), `PrintLaser` |
| Calls | `PrintChar` (tail), `PrintStdPair` (tail), `TokenControl` (tail), `PrintDistanceEnd`, `StatusScreen`, `IM2Entry` |
| Reads | `$F11A`-`$F4E4` (`TokenTable`, `OtherTable`, `StdTokens`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF0`-`$CFFB` (`BackBuffer`); `$FFEB`-`$FFFA` (`work space $FFEB+`) |

### `PrintOther` (`$D45F`)

**Print other token A: skip A - 1 strings of the other table, then each code**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 194 calls, 4,396,421 t-states own (2.32 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 168 calls, 3,812,392 t-states own (1.12 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 900 calls, 19,608,305 t-states own (4.19 %) |
| Called from | `PrintOtherVector` (tail), `PrintOtherChar` (tail), `RandomToken` (tail), `PrintOtherColon`, `ClearPageText` (tail), `DataScreen` (tail) |
| Calls | `PrintOtherChar`, `IM2Entry` |
| Reads | `$F11C`-`$F11D` (`OtherTable`); `$F4F5`-`$FA6E` (`OtherTokens`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFEC`-`$CFF9` (`BackBuffer`); `$FFF1`-`$FFF8` (`work space $FFF1+`) |

### `PrintOtherChar` (`$D470`)

**One code of an other string: a control, a character, a random pick, a token or a pair**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,270 calls, 100,895 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,158 calls, 92,269 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,342 calls, 505,171 t-states own (0.11 %) |
| Called from | `PrintOther` |
| Calls | `PrintCode` (tail), `PrintOther` (tail), `PrintChar` (tail), `PrintOtherPair` (tail), `RandomToken` (tail), `OtherControl` (tail) |
| Reads | `$D420` (`OtherSetOn`) |

### `PrintChar` (`$D499`)

**Print a character with the case rules, or buffer it for the justified text**

PrintCase `$D0D1`: 0 the sentence case (a capital after a non-letter), 1 all capitals, 2 the next letter capital then small.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5,494 calls, 862,157 t-states own (0.46 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 16,883 calls, 15,270,994 t-states own (4.50 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 20,545 calls, 18,736,496 t-states own (4.01 %) |
| Called from | `PrintCode` (tail), `PrintOtherChar` (tail), `PrintPairNow` (tail) |
| Calls | `PrintNumberUnits`, `PlotChar`, `JustifyChar` (tail), `ControlFuelValue`, `StatusScreen`, `StatusSystem`, `IM2Entry` |
| Reads | `$4027`-`$54F7` (screen); `$5514`-`$55F7` (screen); `$5614`-`$56F7` (screen); `$5714`-`$57F7` (screen); `$5D70`-`$5D77` (`Font`); `$5D90`-`$5E47` (`Font`); 9 more ranges |
| Writes | `$4027`-`$54F7` (screen); `$5514`-`$55F7` (screen); `$5614`-`$56F7` (screen); `$5714`-`$57F7` (screen); `$C022`-`$C738` (`BackBuffer`); `$C7EB`-`$C7F4` (`BackBuffer`); 4 more ranges |

### `PlotChar` (`$D4E1`)

**Plot character A at the next column (wrapping to a new line past 31), XOR into the screen**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5,509 calls, 4,181,777 t-states own (2.21 %) |
| Called from | `PrintChar`, `JustifyChar` |
| Calls | `PrintNumberUnits`, `ControlFuelValue`, `MarketRow`, `PrintUnit`, `DataScreen`, `StatusScreen`, `StatusSystem`, `IM2Entry` |
| Reads | `$4025`-`$57F7` (screen); `$5D70`-`$5D77` (`Font`); `$5D90`-`$5E47` (`Font`); `$5E68`-`$6047` (`Font`); `$C026`-`$C738` (`BackBuffer`); `$C8C2`-`$CFDC` (`BackBuffer`); 2 more ranges |
| Writes | `$4025`-`$57F7` (screen); `$C026`-`$C738` (`BackBuffer`); `$C8C2`-`$CFF9` (`BackBuffer`); `$D045` (`TextColumn`); `$FFEB`-`$FFF6` (`work space $FFEB+`) |

### `FillAttrRow` (`$D54F`)

**30 attributes of colour 5 from `$5AA1` (the dashboard's message line)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 63 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 63 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 63 t-states own (0.00 %) |
| Called from | `ShortRangeChart` |
| Calls | `FillBytes` |

### `FillAttrs30` (`$D554`)

**B = 30 attributes of A from HL, then HL past the row's edge**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HorizontalRule` (`$D55C`)

**The heading's rule: 32 bytes `$FF` at `$4340`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 30 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 10 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 10 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `FillRule` |

### `FillRule` (`$D55F`)

**32 bytes of `$FF` from HL**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 22 calls, 308 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 10 calls, 140 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 10 calls, 140 t-states own (0.00 %) |
| Called from | `HorizontalRule`, `DrawFrame`, `ScreenHeading` (tail), `GalacticChart` |
| Calls | `FillBytes` |

### `FillBytes` (`$D563`)

**B bytes of A from HL**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 45 calls, 38,967 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 20 calls, 15,583 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 20 calls, 15,583 t-states own (0.00 %) |
| Called from | `FillAttrRow`, `FillRule`, `ColourBands`, `ScreenHeading`, `GalacticChart` |
| Writes | `$4000`-`$401F` (screen); `$4340`-`$435F` (screen); `$4740`-`$475F` (screen); `$5060`-`$507F` (screen); `$57E0`-`$592A` (screen); `$5961`-`$596A` (screen); 2 more ranges |

### `ColourBands` (`$D568`)

**The page's colour bands from the list at DE: a width in 8ths and a gap of rows each, colour 5; the two corner cells white**

The status and the market pages call it with their lists (`$FD8E` and others).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 3 calls, 3,732 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 1,467 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 1,467 t-states own (0.00 %) |
| Called from | `DataScreen`, `MarketPrices`, `StatusScreen` |
| Calls | `FillBytes` |
| Reads | `$FD8E`-`$FD95` (`StatusBands`); `$FDF3`-`$FDFD` (`DataBands`, `MarketBands2`) |
| Writes | `$5822`-`$5823` (screen) |

### `PrintOtherPair` (`$D595`)

**Other pair A - `$D7` from `$FD99`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 234 calls, 6,786 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 216 calls, 6,264 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,182 calls, 34,278 t-states own (0.01 %) |
| Called from | `PrintOtherChar` (tail) |
| Calls | `PrintPairNow` (tail) |

### `PrintStdPair` (`$D59C`)

**Standard pair A - `$80` from `$FDB3`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 233 calls, 3,961 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 757 calls, 12,869 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 477 calls, 8,128 t-states own (0.00 %) |
| Called from | `PrintCode` (tail) |
| Calls | `PrintPairNow`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$FFF5`-`$FFF6` (`work space $FFF5+`) |

### `PrintPairNow` (`$D5A1`)

**Two characters, the second left out when it is "?"**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 467 calls, 49,521 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 973 calls, 103,157 t-states own (0.03 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,659 calls, 175,854 t-states own (0.04 %) |
| Called from | `PrintOtherPair` (tail), `PrintStdPair` |
| Calls | `PrintChar` (tail), `IM2Entry` |
| Reads | `$FDA1`-`$FE00` (`OtherPairs`, `StdPairs`, `DataBands`, `MarketBands2` and 2 more) |
| Writes | `$FFF5`-`$FFF6` (`work space $FFF5+`) |

### `RandomToken` (`$D5B4`)

**A random one of the five tokens of row A - `$5B` of Synonyms, by the text generator's next byte**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 12 calls, 1,951 t-states own (0.00 %) |
| Called from | `PrintOtherChar` (tail) |
| Calls | `PrintOther` (tail), `TextRandom` |
| Reads | `$D5F5`-`$D61A` (`Synonyms`) |

### `TextRandom` (`$D5E1`)

**The text generator: the four bytes at `$DECC` shifted and added; A its next byte**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 12 calls, 1,308 t-states own (0.00 %) |
| Called from | `RandomToken` |
| Reads | `$DECC`-`$DECF` (`TextSeeds`) |
| Writes | `$DECC`-`$DECF` (`TextSeeds`) |

### `ClearScreen` (`$D61D`)

**Clear the page by PUSHes: 768 attributes `$07`, 6144 pixel bytes 0; then the frame: both side columns, the top and bottom rules; print at row 1, column 0**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 3 calls, 565,070 t-states own (0.30 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 281,763 t-states own (0.08 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 281,763 t-states own (0.06 %) |
| Called from | `ClearScreenVector` (tail), `JumpTable`, `GalacticChart`, `ShortRangeChart` |
| Calls | `DrawFrame` |
| Reads | `$D61B`-`$D61C` (`ClearScreenSP`) |
| Writes | `$D61B`-`$D61C` (`ClearScreenSP`) |

### `DrawFrame` (`$D646`)

**The page's frame: bit 7 of column 0 and bit 0 of column 31 on 192 lines, the top and bottom lines solid**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8 calls, 142,534 t-states own (0.08 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 71,534 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 71,534 t-states own (0.02 %) |
| Called from | `ClearScreen`, `GalacticChart`, `StatusBomb` (tail) |
| Calls | `FillRule`, `IM2Entry` |
| Reads | `$4000`-`$5740` (screen); `$575F`-`$5760` (screen); `$577F`-`$5780` (screen); `$579F`-`$57A0` (screen); `$57BF`-`$57C0` (screen); `$57DF`-`$57E0` (screen); 2 more ranges |
| Writes | `$4000`-`$5720` (screen); `$573F`-`$5740` (screen); `$575F`-`$5760` (screen); `$577F`-`$5780` (screen); `$579F`-`$57A0` (screen); `$57BF`-`$57C0` (screen); 4 more ranges |

### `JustifyChar` (`$D6B9`)

**Buffer a character of the justified text; a full line is spread to 30 columns (spaces added between words) and printed**

The other set's control codes 14 and 15 start and end it (the mission texts and the data screen's description). 1025 runs (the data on Lave of d1).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 75 calls, 18,456 t-states own (0.01 %) |
| Called from | `PrintChar` (tail) |
| Calls | `PlotChar`, `JustifyNewLine`, `JustifyBackWord`, `JustifyAddSpace`, `NewLine`, `IM2Entry` |
| Reads | `$D676`-`$D694` (`JustifyLine`); `$D6B3`-`$D6B6` (`JustifyLine`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF0`-`$CFF1` (`BackBuffer`); `$D0D2` (`PrintCapital`); `$D676`-`$D699` (`JustifyLine`); `$D6B3`-`$D6B8` (`JustifyLine`) |

### `JustifyPrint` (`$D71A`)

**Print the 30 characters of the line, a new line, the capital off**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JustifyNewLine` (`$D732`)

**The carried word becomes the start of the next line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 6,080 t-states own (0.00 %) |
| Called from | `JustifyChar`, `JustifyOn` (tail) |
| Reads | `$D695`-`$D6B8` (`JustifyLine`) |
| Writes | `$D676`-`$D6B8` (`JustifyLine`) |

### `JustifyOn` (`$D75A`)

**Other control 14: buffering on, the buffers blank**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 900 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `JustifyNewLine` (tail) |
| Writes | `$D0D4` (`PrintBuffering`); `$D695`-`$D6B8` (`JustifyLine`) |

### `JustifyOff` (`$D776`)

**Other control 15: buffering off, the last line printed as it is**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 57 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Reads | `$D6B4` (`JustifyLine`) |
| Writes | `$D0D4` (`PrintBuffering`) |

### `JustifyBackWord` (`$D783`)

**Back to the space before the last word (or the line's start)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 10 calls, 2,790 t-states own (0.00 %) |
| Called from | `JustifyChar` |
| Reads | `$D675`-`$D693` (`JustifyLine`); `$D6B5`-`$D6B6` (`JustifyLine`) |
| Writes | `$D6B5`-`$D6B6` (`JustifyLine`) |

### `JustifyAddSpace` (`$D7A1`)

**One more space at the pointer: the rest of the line moved right by one**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8 calls, 4,880 t-states own (0.00 %) |
| Called from | `JustifyChar` |
| Reads | `$D67A`-`$D693` (`JustifyLine`); `$D6B5`-`$D6B6` (`JustifyLine`) |
| Writes | `$D67A`-`$D693` (`JustifyLine`) |

### `OtherControl` (`$D7B0`)

**Other control A through the table at `$D7DF`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 79 calls, 1,738 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 63 calls, 1,386 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 297 calls, 6,534 t-states own (0.00 %) |
| Called from | `PrintOtherChar` (tail) |
| Calls | `JumpTable` (tail) |

### `TokenControl` (`$D7B5`)

**Standard control A through the table at `$D7C3`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 50 calls, 500 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 45 calls, 450 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 45 calls, 450 t-states own (0.00 %) |
| Called from | `PrintCode` (tail) |
| Calls | `JumpTable` |

### `JumpTable` (`$D7B8`)

**Jump to the A-th address of the table at HL**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 129 calls, 7,482 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 108 calls, 6,264 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 342 calls, 19,836 t-states own (0.00 %) |
| Called from | `OtherControl` (tail), `TokenControl` |
| Calls | `HorizontalRule`, `ClearScreen`, `JustifyOn`, `JustifyOff`, `ControlCash`, `ControlCommander`, `ControlSentence`, `ControlFuel`, `ControlGalaxy`, `ControlCurrent`, `ControlSelected`, `ControlTab`, `CapitalNext`, `ControlMixed`, `ControlCapitals`, `ControlPeople`, `OtherOn`, `OtherOff`, `NewLine` |
| Reads | `$D7C5`-`$D806` (`TokenControls`, `OtherControls`) |

### `WaitControl` (`$D81F`)

**Other control 25: wait 36 frames**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ControlCash` (`$D822`)

**Standard 7: "CASH:" the cash and " CR", a new line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 60 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 60 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 60 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PrintCash`, `PrintLine` (tail), `PrintCodeColon` |

### `ControlCommander` (`$D82E`)

**Standard 4: the commander's name**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 22 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 22 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 22 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PrintString` (tail) |

### `ControlSentence` (`$D833`)

**Standard 8: sentence case**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 266 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 171 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 171 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SetCase` (tail) |

### `ControlFuel` (`$D837`)

**Standard 5: "FUEL:" the fuel with its point, " LIGHT YEARS", a new line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 41 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 41 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 41 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PrintInline`, `PrintCodeColon` |

### `ControlFuelValue` (`$D840`)

**ControlFuelValue**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 37 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 37 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 37 t-states own (0.00 %) |
| Called from | `PrintChar`, `PlotChar` |
| Calls | `PrintByteDot`, `PrintLine` |
| Reads | `$D082` (`Fuel`) |

### `PrintLine` (`$D848`)

**Print token A and a new line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 20 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 20 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 20 t-states own (0.00 %) |
| Called from | `ControlCash` (tail), `ControlFuelValue` |
| Calls | `PrintCodeLine` (tail) |

### `ControlGalaxy` (`$D84B`)

**Standard 1: the galaxy's number (1-8) in two places**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 47 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PrintByte` (tail) |
| Reads | `$D065` (`CommanderRest`) |
| Writes | `$D0CE` (`Messages`) |

### `ControlFirstSystem` (`$D857`)

**Standard 11: the name of the galaxy's first system (its seeds from the galaxy's)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ControlCurrent` (`$D86A`)

**Standard 2: the current system's name**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 78 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 39 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 39 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PrintString` (tail), `CapitalNext` |

### `ControlSelected` (`$D872`)

**Standard 3: the selected system's name**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 81 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 567 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 567 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PrintString`, `CapitalNext` |

### `PrintString` (`$D878`)

**Print the zero-ended string at HL**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 7 calls, 70 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 23 calls, 230 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 23 calls, 230 t-states own (0.00 %) |
| Called from | `ControlCommander` (tail), `ControlCurrent` (tail), `ControlSelected`, `ControlPeople` (tail) |
| Calls | `PrintCodes` (tail) |

### `ControlTab` (`$D87B`)

**Other 8: column 4**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 51 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 17 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 17 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ColumnInline` |

### `CapitalNext` (`$D87F`)

**Other 19: the next letter a capital**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 9 calls, 1,890 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 23 calls, 2,280 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 23 calls, 9,300 t-states own (0.00 %) |
| Called from | `JumpTable`, `ControlCurrent`, `ControlSelected`, `ControlPeople`, `SetColumn` |
| Writes | `$D0D3` (`PrintCapitalNext`) |

### `ControlNone` (`$D884`)

**Nothing**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ControlRandomName` (`$D885`)

**Other 18: a random name of one to four letter pairs (the pairs `$FD9B` on)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ControlMixed` (`$D8A9`)

**Other 13: a capital, then small**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 19 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SetCase` (tail) |

### `ControlCapitals` (`$D8AE`)

**Standard 6, other 1: capitals**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 119 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 70 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 70 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SetCase` |

### `SetCase` (`$D8B0`)

**PrintCase = A**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 32 calls, 755 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 19 calls, 437 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 19 calls, 437 t-states own (0.00 %) |
| Called from | `ControlSentence` (tail), `ControlMixed` (tail), `ControlCapitals` |
| Calls | `PrintCapitals`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFFA`-`$CFFB` (`BackBuffer`); `$D0D1` (`PrintCase`) |

### `ControlPeople` (`$D8B4`)

**Other 17: the system's name and "IAN", its last vowel dropped**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 219 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PrintString` (tail), `CapitalNext`, `PrintCodes` |
| Reads | `$D6B4`-`$D6B6` (`JustifyLine`); `$D8E0`-`$D8E1` (`Vowels`); `$DEF0` (`SelectedName`) |
| Writes | `$D6B4`-`$D6B6` (`JustifyLine`) |

### `OtherOn` (`$D8E5`)

**Standard 10, other 5: the other set on (OtherSetOn 1)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 19 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SetOtherSet` (tail) |

### `OtherOff` (`$D8E9`)

**Other 6: off**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | run into, not called, 7 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SetOtherSet` |

### `SetOtherSet` (`$D8EB`)

**SetOtherSet**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 46 t-states own (0.00 %) |
| Called from | `OtherOn` (tail), `OtherOff` |
| Writes | `$D420` (`OtherSetOn`) |

### `ControlRow6` (`$D8EF`)

**Other 29: row 6**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ControlRow10` (`$D8F3`)

**Other 23: row 10**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ControlRow` (`$D8F5`)

**ControlRow**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintPairChar` (`$D8F8`)

**A pair's character unless "?"**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## commander

`src/game/commander.asm`

### `CommanderMenu` (`$D90A`)

**The ACCESS MENU: 1 load, 2 save, 3 leave; returns A = 1 (NZ) when a commander was loaded**

The page is cleared, coloured (MenuBands, the message row, the top three attribute rows `$0F` and a rule at `$4740` by MenuTop), and other token 1 prints the three choices. The keys are read by WaitKey; the stack is reset from MenuStack before each, so a BREAK or an error deep in the tape code just comes back here.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadCommander` (`$D946`)

**1: the name to look for (empty: the first commander found), then blocks until the names agree**

The ROM's LD-BYTES is entered at `$0562`, after its own INC D / EX AF,AF' / DEC D / DI (copied here before the CALL), so it returns to the game and not through SA/LD-RET. The record is loaded in place over `$D054`: a block whose name differs is simply followed by the next one. FOUND COMMANDER (other `$D6`) names each block read.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveCommander` (`$D980`)

**2: the name into the record, the sun's place into its tail, START TAPE, SA-BYTES, then the security number**

SA-BYTES is entered at `$04C6`, past the PUSH of SA/LD-RET, so it comes back here with the border as it left it (set black at once) and the interrupts off (EI here). The nine bytes of SunPosition go into the record's tail `$D0B1` so a loaded commander gets its sun back.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SecurityNumber` (`$D9AC`)

**Print "SECURITY NUMBER:" and two five-digit numbers made from the combat score, the galaxy, two mission flags and the cash**

D takes the galaxy (bits 0-2) and the mission flags' bits 3 and 6, three places up, then the parities of E (the combat score's middle byte, doubled), H and L (the cash in thousands): Parity shifts each in from the top. The four bytes are then chained: D = L xor D + `$3D`, E = D xor E + `$66`, H = E xor H + `$8F`, L = H xor L + `$C7`, and DE and HL are printed. The game never reads the number back; a checker with the same chain can test a claimed rank and cash (inference: the code only prints it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `KeepCommander` (`$DA08`)

**The record becomes DefaultCommander (93 bytes), back to the menu**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Parity` (`$DA16`)

**The parity of A's eight bits into the top of D (C = the count of ones, its bit 0 shifted in)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LoadFailed` (`$DA25`)

**One frame, then BREAK if SPACE is held (FC0D = `$20`), else TAPE LOADING ERROR and the record back from DefaultCommander**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TapeBreak` (`$DA2D`)

**The message lines cleared and BREAK**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TapeError` (`$DA37`)

**TapeError**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TapeBlock` (`$DA49`)

**IX = the record, DE = 102, A = `$FF` (a data block)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadName` (`$DA53`)

**Read a name of up to 10 letters into HL after COMMANDER'S NAME? (other 8)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TapeMessage` (`$DA5A`)

**Other token A on the message row 22, after the row is cleared; a new line, a click**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ViewTexts` (`$DA7A`)

**The space view's name ("FRONT VIEW" and the like) into the back buffer, then MessageTick**

Called each pass (1220 times in c1). The name is plotted with SET 7 at `$D50A`, so PlotChar writes into the back buffer at `$C000` and the frame copy shows it on top of the stars. On the screens (view 4 and up) the plot byte `$D548` is set to write over (NOP) while MessageTick runs and back to mixing (XOR C) after.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 140 calls, 30,185 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 691 calls, 149,060 t-states own (0.04 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 389 calls, 83,630 t-states own (0.02 %) |
| Called from | `ViewTextsVector` (tail) |
| Calls | `PrintCode`, `MessageTick`, `PrintCodeLine`, `IM2Entry` |
| Reads | `$70E3` (`ViewIndex`); `$D50A` (`PlotChar`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$D045`-`$D046` (`TextColumn`, `TextRow`); `$D0D1` (`PrintCase`); `$D50A` (`PlotChar`); `$FFFB`-`$FFFC` (`work space $FFFB+`) |

### `MessageTick` (`$DAB4`)

**The jump countdown, the condition light, then the message line: show, scan the slots, or raise a periodic message**

The ten slots at `$D0BD` hold a column and a code each, bit 7 of the column a request (FullMessage and the market set them). On an even pass the first request found is taken (its bit cleared, a click) and shown for 14 passes. A shown message is plotted once a pass from its fourth pass on and only in the space views, so it blinks on as the screen copy overwrites it: XOR plotting twice would clear it.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 140 calls, 56,402 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 691 calls, 273,134 t-states own (0.08 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 389 calls, 149,513 t-states own (0.03 %) |
| Called from | `ViewTexts` |
| Calls | `FillAttrsVector`, `ConditionLightVector`, `MessageShow` (tail), `JumpTick`, `PrintCodeLine` (tail), `IM2Entry` |
| Reads | `$70E3` (`ViewIndex`); `$70FC` (`BarDrawn`); `$711E`-`$7129` (`SunNear`, `TooClose`, `SunLarge`, `ConditionLightVector` and 4 more); `$D081` (`NovaMission`); `$D0AF`-`$D0CF` (`MissionState`, `MissionFlags`, `RecordTail`, `SunGrows` and 3 more); `$DA72`-`$DA76` (`MessageTimer`, `MessageShown`, `MessagePass`, `MessageColumn` and 1 more); 1 more ranges |
| Writes | `$D041`-`$D046` (`CloakOn`, `JumpKeysVector`, `TextColumn`, `TextRow`); `$DA72`-`$DA74` (`MessageTimer`, `MessageShown`, `MessagePass`); `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `MessageShow` (`$DAE1`)

**Show standard code B at column C for 14 passes**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 20 t-states own (0.00 %) |
| Called from | `MessageTick` (tail) |
| Calls | `MessageSet` |
| Writes | `$DA73` (`MessageShown`) |

### `MessageSet` (`$DAE6`)

**Code B at column C, the count left as it is**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 44 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 88 t-states own (0.00 %) |
| Called from | `MessageShow`, `JumpKeys` |
| Writes | `$DA75`-`$DA76` (`MessageColumn`, `MessageToken`) |

### `MessagePeriodic` (`$DB2E`)

**Every 70 passes: ENERGY LOW, FUEL SCOOPS ON (and the fuel), DOCKING COMPUTERS ON, or the mission's MAYDAY**

In this order: the fourth energy bank below `$9F` gives ENERGY LOW (code `$64`) at once each odd pass and turns the cloak off (CloakOn 0); the sun near with a fuel scoop fitted adds 0.1 light years (SetFuel) and shows FUEL SCOOPS ON (code `$A0`); the docking computer on shows DOCKING COMPUTERS ON (code `$7B`). Otherwise MessageTimer counts 70 odd passes, then the mission state 1 shows its MAYDAY (code `$0F`, token `$81`: "... INVADED") and NovaMission (the second mission) "MAYDAY CORIOLIS IN DANGER" (code `$C2`) unless the sun is already growing.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearMessages` (`$DB91`)

**Every slot's request bit cleared and the line's code to 0**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 878 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 1,317 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 1,317 t-states own (0.00 %) |
| Called from | `ClearHighlightsVector` (tail), `NewGame`, `JumpTick` |
| Reads | `$D0BD`-`$D0CF` (`Messages`) |
| Writes | `$D0BD`-`$D0CF` (`Messages`); `$DA76` (`MessageToken`) |

## hyperspace

`src/game/hyperspace.asm`

### `JumpKeys` (`$DBA2`)

**H or G+H (KeyViews `$FC0A` bits 4, 5): a jump, unless one counts down; docked: DOCKED and the status screen**

Called each pass through JumpKeysVector (197283 runs, 4 with a key). The keys are cleared at once. A hyperspace needs the distance to the selected system (FindNearest, JumpDistance) above 0, below 25.6 light years and within the fuel, else HYPERSPACE RANGE ? (code `$C1`); a galactic jump needs the galactic hyperdrive (`$D08D`). Then TunnelOn 1 (a jump) or 2 (galactic), the countdown 21 and HYPERSPACE -- <system> (code `$C0`) or GALACTIC HYPERSPACE (code `$74`) on the message line, a click, and the front view if a space view was on.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 120,160 calls, 4,205,600 t-states own (2.22 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 38,713 calls, 1,355,328 t-states own (0.40 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 38,410 calls, 1,344,725 t-states own (0.29 %) |
| Called from | `JumpKeysVector` (tail) |
| Calls | `MessageSet`, `FindNearest`, `Click` |
| Reads | `$70E3` (`ViewIndex`); `$7104` (`Condition`); `$D082` (`Fuel`); `$DBA1` (`JumpCountdown`); `$DEF6`-`$DEF7` (`JumpRange`); `$FC0A` (`KeyViews`) |
| Writes | `$70E3` (`ViewIndex`); `$D03F` (`TunnelOn`); `$DA73` (`MessageShown`); `$DBA1` (`JumpCountdown`); `$FC0A` (`KeyViews`) |

### `JumpTick` (`$DC29`)

**Each MessageTick: the countdown (shown halved, two digits at 1,1), and at 0 the jump itself**

1220 runs in c1, f1 and w1; 42 counted, 2 jumped. The jump: the message slots cleared; a galactic jump (TunnelOn 2) or any jump out of the nova system goes to the next galaxy (GalaxyJump); a hyperspace takes the fuel (the distance), sets the fuel's refill price (`$7060` = 70 - the fuel left + 2 x the economy), halves the legal status, and either misjumps (JumpWitch) or arrives (JumpArrive).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 140 calls, 4,480 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 691 calls, 26,706 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 389 calls, 14,577 t-states own (0.00 %) |
| Called from | `MessageTick` |
| Calls | `PrintByte` (tail), `ClearMessages`, `JumpEnd` (tail), `SetFuel`, `NewMarket` |
| Reads | `$604F`-`$6050` (`ShipSlots`); `$7105`-`$7118` (`StarSeed`, `SunPosition`, `PlanetPosition`); `$D03F` (`TunnelOn`); `$D05F`-`$D065` (`LegalStatus`, `CombatScore`, `CommanderRest`); `$D081`-`$D082` (`NovaMission`, `Fuel`); `$D097`-`$D099` (`Seeds`); 5 more ranges |
| Writes | `$6048`-`$6062` (`ShipSlots`); `$7060` (`EquipmentPrices`); `$70E3`-`$70F2` (`ViewIndex`, `RollRate`, `PitchRate`, `SpeedRate` and 1 more); `$7103`-`$711E` (`WitchSpace`, `Condition`, `StarSeed`, `SunPosition` and 5 more); `$9CB2` (`MissionShip`); `$D040`-`$D047` (`TunnelLoop`, `CloakOn`, `JumpKeysVector`, `TextColumn` and 2 more); 6 more ranges |

### `GalaxyJump` (`$DC4E`)

**The next galaxy: the missions reset (the nova over, the Thargoids forgotten), the hyperdrive used up, the seeds twisted, the legal status clean, the system nearest the cursor**

The fuel price `$7060` gets the galaxy number (1-8) here. Each of the six seed bytes is rotated left one bit (TwistSeed) as BBC Elite does; the galaxy number wraps from 8 to 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TwistSeed` (`$DC83`)

**The two bytes at HL rotated left one bit each, HL two on**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JumpWitch` (`$DCC0`)

**The misjump: WitchSpace on, the current system half way to the selected one, no safe zone, no system names**

The current system's coordinates (`$D099`, `$D097`) and the cursor become the mid points; the names of the current and the selected system are emptied (`$DEE4`, `$DEED`), so the status page shows none. w1: F of the pause menu (option bit 6) forced it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JumpArrive` (`$DCE9`)

**The arrival: the selected system becomes the current one; the sun, the planet and the station from its seeds; the market**

The seeds (`$DEBA`) go to the current system (`$D096`), the selected name to the current name, the tech level and the government to `$D09C` and `$D09D`, NewMarket with a fresh fluctuation byte, the sun and the planet cleared, StationLaunch `$FF`. The coordinates' top bytes come from the seeds: the sun's x and y (s1, s2 high bytes AND `$83` OR 1: within ±3 pages, never 0) and z (s1 high OR low, AND 7, + 4, negative: behind), the planet's x and y the same way from s0 and s1's low bytes and z (s0 high OR low, AND 7, + 3) ahead. The station starts at the planet (slot 0 copied from PlanetPosition) and is moved about a page off along z or x (a seed bit picks; the middle byte's bit 7 set, the top byte one nearer or further), its axes set from the side it was moved to. f1: 1 run.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissionTriggers` (`$DDFD`)

**Outside galaxy 1: the Thargoid mission's stage, the jump count, the three triggers, the pirate station's chance**

MissionState 1 becomes 2 (the MAYDAY left unanswered), 4 becomes 3 (left the base); arriving in the galaxy's first system (IsFirstSystem) with the mission on makes it 4. The jump count at 32 starts the nova (flag bit 0, NovaMission, the red tint, FuelLeak), at 128 the cloak ship (bit 1), at 254 the MAYDAY (bit 2, MissionState 1). With no trigger the station turns pirate-held when StarSeed is at most (7 - government) / 2: one chance in 256 for a corporate state, four for an anarchy.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PirateChance` (`$DE39`)

**The station pirate-held (its roll counter's bit 7 cleared) with a chance by the government**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JumpEnd` (`$DE4C`)

**The tunnel next (TunnelLoop 1), the front view, the cabin temperature, SunNear, MissileState and MissionShip 0, the altitude `$A0`**

| | |
| --- | --- |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 131 t-states own (0.00 %) |
| Called from | `JumpTick` (tail) |
| Writes | `$70E3`-`$70F2` (`ViewIndex`, `RollRate`, `PitchRate`, `SpeedRate` and 1 more); `$711E` (`SunNear`); `$9CB2` (`MissionShip`); `$D040`-`$D047` (`TunnelLoop`, `CloakOn`, `JumpKeysVector`, `TextColumn` and 2 more) |

### `MissionNova` (`$DE67`)

**32 jumps: the sun goes nova: flag bit 0, NovaMission, the view red, a fuel leak**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissionCloak` (`$DE7E`)

**128 jumps: the cloak ship may come (flag bit 1)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MissionThargoids` (`$DE88`)

**254 jumps: the Thargoid MAYDAY (flag bit 2, MissionState 1)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FuelLeak` (`$DE97`)

**All the fuel lost, FUEL LEAK on the message line (slot 9), when there was any**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SetFuel` (`$DEA2`)

**The fuel = A, at most 70 (7.0 light years); the fuel bar 2.25 x A**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 95 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 95 t-states own (0.00 %) |
| Called from | `JumpTick` |
| Writes | `$70EC` (`BarDrawn`); `$D082` (`Fuel`) |

## galaxy

`src/game/galaxy.asm`

### `NextGalaxy` (`$DF03`)

**Screen 16 of ScreenTable, which nothing asks for: the galaxy number one more (wrapping at 8) and the galaxy's seeds twisted (unreachable; GalaxyJump does the same in the game)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TwistWord` (`$DF1A`)

**The two bytes at HL rotated left one bit each**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FindSystem` (`$DF24`)

**The system named in NameInput: walk the galaxy's 256 systems comparing NameBuffer; carry when none**

Found: the system becomes the selected one, the chart's cross is moved (EraseCross before and after SystemData), the name kept (KeepName) and the distance worked out (JumpDistanceNow). Called from the charts' PLANET NAME? prompt (PlanetNamePrompt), known from the code only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FindNearest` (`$DF60`)

**The system nearest the chart cursor becomes the selected one, with the cross redrawn on the charts**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 46 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 205 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 205 t-states own (0.00 %) |
| Called from | `JumpKeys`, `ShowSelected`, `DataScreen` |
| Calls | `FindNearestNow` (tail), `ChartCross` (tail) |
| Reads | `$70E3` (`ViewIndex`) |

### `FindNearestNow` (`$DF74`)

**Walk the 256 systems for the smallest dx^2 + (dy/2)^2 to the cursor (`$D0BB`, `$D0BC`), then its data, name and distance**

10 runs in f1 and d1 (a jump target and the charts). The y difference is halved because the charts are drawn half as tall as wide; the root of the best sum times 4 is the distance in 0.1 light years (JumpDistance), as the BBC's.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 80,532 t-states own (0.04 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 161,231 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 161,231 t-states own (0.03 %) |
| Called from | `NewGame`, `FindNearest` (tail) |
| Calls | `NextSystem`, `SquaredDistance`, `JumpDistance`, `SystemName`, `KeepName`, `SystemData`, `GalaxySeeds`, `SaveSeeds`, `RestoreSeeds`, `IM2Entry` |
| Reads | `$D097`-`$D099` (`Seeds`); `$DEC1`-`$DEC3` (`SystemSeeds`); `$DF5E`-`$DF5F` (`BestDistance`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF8`-`$CFF9` (`BackBuffer`); `$DF5E`-`$DF5F` (`BestDistance`); `$FFF7`-`$FFFA` (`work space $FFF7+`) |

### `NextSystem` (`$DFC4`)

**Four twists: the next system's seeds**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,270 calls, 274,415 t-states own (0.14 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,526 calls, 329,673 t-states own (0.10 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,526 calls, 329,673 t-states own (0.07 %) |
| Called from | `FindNearestNow`, `GalacticChart`, `EachSystemInWindow`, `DrawSystemIcon` (tail) |
| Calls | `Twist`, `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF6`-`$CFF7` (`BackBuffer`) |

### `SquaredDistance` (`$DFCE`)

**HL = (the cursor's x - B)^2 + ((the cursor's y - A) / 2)^2, B and A the system's x and y**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 514 calls, 88,960 t-states own (0.05 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1,028 calls, 177,958 t-states own (0.05 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1,028 calls, 177,958 t-states own (0.04 %) |
| Called from | `FindNearestNow` |
| Calls | `AbsDifference`, `MultiplyDA`, `IM2Entry` |
| Reads | `$D0BB`-`$D0BC` (`ChartCursorX`, `ChartCursorY`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF2`-`$CFF3` (`BackBuffer`) |

### `AbsDifference` (`$DFEA`)

**A = |A - B|**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,028 calls, 35,208 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,056 calls, 70,598 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,056 calls, 70,598 t-states own (0.02 %) |
| Called from | `SquaredDistance` |

### `JumpDistance` (`$DFF2`)

**JumpRange = 4 x the root of HL (`$FFFF` on a carry)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 260 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 8 calls, 700 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 8 calls, 700 t-states own (0.00 %) |
| Called from | `FindNearestNow` |
| Calls | `SquareRootVector` |
| Writes | `$DEF6`-`$DEF7` (`JumpRange`) |

### `MultiplyDA` (`$E009`)

**HL = D x A (shift and add, eight steps)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,032 calls, 454,770 t-states own (0.24 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2,064 calls, 910,493 t-states own (0.27 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2,064 calls, 910,493 t-states own (0.19 %) |
| Called from | `SquaredDistance`, `SystemData` |
| Calls | `IM2Entry` |
| Reads | `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF0`-`$CFF3` (`BackBuffer`); `$FFF1`-`$FFF2` (`work space $FFF1+`) |

### `SystemName` (`$E01C`)

**The name of the system in SystemSeeds into NameBuffer: four pairs when bit 6 of s0's low byte is set, else three**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 12 calls, 4,490 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 14 calls, 5,240 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 14 calls, 5,240 t-states own (0.00 %) |
| Called from | `FindNearestNow`, `LabelSystem` |
| Calls | `NamePair`, `Twist` (tail) |
| Reads | `$DEC0`-`$DEC1` (`SystemSeeds`) |
| Writes | `$DEDB`-`$DEE2` (`NameBuffer`); `$DF01`-`$DF02` (`NamePointer`) |

### `NamePair` (`$E03D`)

**One pair: s2's high byte AND `$1F` picks StdPairs entry (0: none), a "?" second letter left out; then a twist**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 38 calls, 6,794 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 44 calls, 7,660 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 44 calls, 7,660 t-states own (0.00 %) |
| Called from | `SystemName` |
| Calls | `Twist` |
| Reads | `$DEC4`-`$DEC5` (`SystemSeeds`); `$DF01`-`$DF02` (`NamePointer`); `$FDB5`-`$FDF2` (`StdPairs`) |
| Writes | `$DEDB`-`$DEE2` (`NameBuffer`); `$DF01`-`$DF02` (`NamePointer`) |

### `Twist` (`$E063`)

**s0, s1, s2 = s1, s2, s0 + s1 + s2**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5,128 calls, 861,656 t-states own (0.45 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 6,160 calls, 1,034,975 t-states own (0.30 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,160 calls, 1,034,975 t-states own (0.22 %) |
| Called from | `NextSystem`, `SystemName` (tail), `NamePair` |
| Calls | `IM2Entry` |
| Reads | `$DEC0`-`$DEC5` (`SystemSeeds`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF2`-`$CFF5` (`BackBuffer`); `$DEC0`-`$DEC5` (`SystemSeeds`); `$FFF1`-`$FFF2` (`work space $FFF1+`) |

### `KeepName` (`$E080`)

**NameBuffer becomes SelectedName**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 406 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 812 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 812 t-states own (0.00 %) |
| Called from | `FindNearestNow` |
| Reads | `$DEDB`-`$DEE2` (`NameBuffer`) |
| Writes | `$DEED`-`$DEF4` (`SelectedName`) |

### `SystemData` (`$E08C`)

**The selected system from SystemSeeds: its seeds, the cursor on it, the economy, government, tech level, population and productivity**

As BBC Elite: the government is s1's bits 3-5, the economy s0's high bits 0-2 (bit 1 set for governments 0 and 1); the tech level (7 - economy) + (s1 high AND 3) + government / 2 rounded up; the population 4 x tech + economy + government + 1; the productivity ((7 - economy) + 3) x (government + 4) x population x 8. 10 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 1,068 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 2,136 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 2,136 t-states own (0.00 %) |
| Called from | `FindNearestNow` |
| Calls | `MultiplyDA` |
| Reads | `$DEC0`-`$DEC5` (`SystemSeeds`); `$DEF8`-`$DEFB` (`Economy`, `Government`, `TechLevel`, `Population`) |
| Writes | `$D0BB`-`$D0BC` (`ChartCursorX`, `ChartCursorY`); `$DEBA`-`$DEBF` (`SelectedSeeds`); `$DEF8`-`$DEFD` (`Economy`, `Government`, `TechLevel`, `Population` and 1 more) |

### `PrintDistance` (`$E107`)

**DISTANCE: and the jump range with its point and LIGHT YEARS, then a new line (nothing at 0)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 46 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 258 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 258 t-states own (0.00 %) |
| Called from | `ShowSelected`, `DataScreen` |
| Calls | `PrintNumber`, `PrintInline`, `PrintCodeColon`, `NewLine` (tail) |
| Reads | `$DEF6`-`$DEF7` (`JumpRange`) |
| Writes | `$D0CE` (`Messages`) |

### `PrintDistanceEnd` (`$E123`)

**PrintDistanceEnd**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | run into, not called, 20 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | run into, not called, 20 t-states own (0.00 %) |
| Called from | `PrintCode` |
| Calls | `NewLine` (tail) |

### `GalaxySeeds` (`$E126`)

**SystemSeeds = the galaxy's seeds: the walk starts at its first system**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5 calls, 160 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 6 calls, 192 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6 calls, 192 t-states own (0.00 %) |
| Called from | `FindNearestNow`, `GalacticChart`, `EachSystemInWindow` |
| Calls | `CopySeeds` (tail) |

### `SaveSeeds` (`$E12E`)

**BestSeeds = SystemSeeds**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 128 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 15 calls, 480 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 15 calls, 480 t-states own (0.00 %) |
| Called from | `FindNearestNow` |
| Calls | `CopySeeds` (tail) |

### `RestoreSeeds` (`$E136`)

**SystemSeeds = BestSeeds**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 40 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 80 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 80 t-states own (0.00 %) |
| Called from | `FindNearestNow` |
| Calls | `CopySeeds` |

### `CopySeeds` (`$E13C`)

**Six bytes from HL to DE**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 11 calls, 1,551 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 25 calls, 3,525 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 25 calls, 3,525 t-states own (0.00 %) |
| Called from | `GalaxySeeds` (tail), `SaveSeeds` (tail), `RestoreSeeds` |
| Reads | `$D090`-`$D095` (`Seeds`); `$DEC0`-`$DECB` (`SystemSeeds`, `BestSeeds`) |
| Writes | `$DEC0`-`$DECB` (`SystemSeeds`, `BestSeeds`) |

### `NewMarket` (`$E142`)

**A new fluctuation byte (`$D06A`) from StarSeed, then MakeMarket**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 32 t-states own (0.00 %) |
| Called from | `JumpTick` |
| Calls | `MakeMarket` |
| Reads | `$7105` (`StarSeed`) |
| Writes | `$D06A` (`CommanderRest`) |

### `MakeMarket` (`$E148`)

**Each commodity's price (`$E1BD`) and the station's stock (`$D09E`) from Commodities, the economy and the fluctuation**

For each of the 17 entries (base price, factor, base quantity, mask): the product = economy x (factor AND `$1F`); the stock = base quantity + (fluctuation AND mask) less the product and one for a positive factor (INC A / NEG), plus the product for a negative one, 0 when negative, AND `$3F`; the price = (base price + (fluctuation AND mask) plus or minus the product) x 4, in tenths of a credit. The last commodity's stock (alien items) is forced to 0. 4 runs (d1 and the arrivals); tools/galaxy.py --market reproduces Diso's 17 prices and stocks of f1 exactly. NewGame turns the stock's store (`$E1AE`, LD (HL),A) into a NOP for its call, so the first market keeps the stock of the commander record.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 9,681 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 19,397 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 9,681 t-states own (0.00 %) |
| Called from | `NewGame`, `NewMarket` |
| Reads | `$701B`-`$705E` (`Commodities`); `$D06A` (`CommanderRest`); `$DEF8` (`Economy`) |
| Writes | `$D09E`-`$D0AE` (`MarketStock`); `$E1BD`-`$E1DE` (`Prices`) |

## menuhelpers

`src/game/menuhelpers.asm`

### `Click` (`$E1E8`)

**With the sound on (Options bit 7) a short beep through the ROM's BEEPER (HL = `$80`, DE = `$60`)**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 168 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 168 t-states own (0.00 %) |
| Called from | `JumpKeys`, `ShowSelected` (tail) |
| Reads | `$FC0E` (`Options`) |

### `WaitKey` (`$E1F7`)

**20 frames, the key bytes cleared, then wait for a key: A = its code (KeyCode `$FC0D`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearKeys4` (`$E205`)

**The four key bytes `$FC08-$FC0B` zeroed with the interrupts off**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MarketRow` (`$E212`)

**One commodity of the market: its name, the unit, the price (4 digits and the point), the stock and its unit; carry when the stock is 0 ("-")**

MarketItem picks the name (standard code `$D0` + item); the columns are 13, 15 and 23 (ColumnInline). The price comes through PricePointer, the stock through StockPointer, each stepped first.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 17 calls, 6,221 t-states own (0.00 %) |
| Called from | `PlotChar`, `SetColumn`, `MarketPrices` |
| Calls | `PrintByte`, `PrintNumber`, `PrintInline`, `PrintCode`, `PrintCodeLine`, `NewLine`, `ColumnInline`, `PrintUnit` |
| Reads | `$D09E`-`$D0AE` (`MarketStock`); `$E1BD`-`$E1E5` (`Prices`, `MarketItem`, `HoldPointer`, `PricePointer` and 1 more) |
| Writes | `$D0CE` (`Messages`); `$E1E2`-`$E1E5` (`PricePointer`, `StockPointer`) |

### `HoldRow` (`$E268`)

**One line of the hold: nothing (carry) for 0 units, else the name, column 13, the count (3 digits) and the unit**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintOtherColon` (`$E292`)

**Other token A and ":"**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5 calls, 145 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 58 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 58 t-states own (0.00 %) |
| Called from | `DataScreen`, `PrintEconomy`, `StatusScreen` |
| Calls | `PrintOther`, `PrintColon` (tail) |

### `PrintCodeColon` (`$E297`)

**Standard code A and ":"**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5 calls, 85 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 68 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 68 t-states own (0.00 %) |
| Called from | `ControlCash`, `ControlFuel`, `PrintDistance`, `DataScreen` |
| Calls | `PrintCode` |

### `PrintColon` (`$E29A`)

**PrintColon**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5 calls, 190 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 114 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 114 t-states own (0.00 %) |
| Called from | `PrintOtherColon` (tail) |
| Calls | `PrintCodeNow` (tail) |

### `PrintCodeSpace` (`$E29E`)

**Standard code A and a space**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 24 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 24 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 24 t-states own (0.00 %) |
| Called from | `PrintLaser` |
| Calls | `PrintCode`, `PrintCodeNow` |

### `PrintCodeNow` (`$E2A3`)

**PrintCodeNow**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 11 calls, 110 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 7 calls, 70 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 7 calls, 70 t-states own (0.00 %) |
| Called from | `PrintColon` (tail), `PrintCodeSpace` |
| Calls | `PrintCode` (tail) |

### `PrintCodeLine` (`$E2A6`)

**Standard code A and a new line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 156 calls, 2,652 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 715 calls, 12,174 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 424 calls, 7,227 t-states own (0.00 %) |
| Called from | `PrintLine` (tail), `ViewTexts`, `MessageTick` (tail), `MarketRow`, `PrintCodeGap`, `MarketPrices`, `StatusScreen`, `StatusSystem` (tail) |
| Calls | `PrintCode`, `IM2Entry` |

### `NewLine` (`$E2A9`)

**Column 0 of the next row (a capital next)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 30 calls, 13,596 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 7 calls, 48,199 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 7 calls, 28,993 t-states own (0.01 %) |
| Called from | `JustifyChar`, `JumpTable`, `PrintDistance` (tail), `PrintDistanceEnd` (tail), `MarketRow`, `ShowSelected`, `DataScreen`, `PrintCodeGap` (tail), `NewLineGap`, `NewLineGapSecond` (tail), `EquipmentLine` |
| Calls | `ColumnZero`, `SetRow` (tail), `IM2Entry` |
| Reads | `$D046` (`TextRow`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$D0D2` (`PrintCapital`); `$FFF9`-`$FFFA` (`work space $FFF9+`) |

### `NewLineRow` (`$E2B1`)

**NewLineRow**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ColumnZero` (`$E2B7`)

**Column 0**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 206 calls, 5,562 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 732 calls, 19,764 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 441 calls, 11,907 t-states own (0.00 %) |
| Called from | `NewLine`, `ClearInputRows` |
| Writes | `$D045` (`TextColumn`) |

### `ColumnInline` (`$E2BC`)

**The column from the byte after the CALL**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 59 calls, 2,006 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 5 calls, 170 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 5 calls, 170 t-states own (0.00 %) |
| Called from | `ControlTab`, `MarketRow`, `ScreenHeading`, `StatusScreen`, `StatusSystem` |
| Calls | `SetColumn` |
| Reads | `$D87E` (`TabColumn`); `$E21D`-`$E224` (`MarketRow`); `$E23D` (`MarketRow`); `$EB67` (`ScreenHeading`); `$EF9B` (`StatusScreen`); `$F0A5` (`StatusSystem`) |

### `SetColumn` (`$E2C0`)

**Column A; 32 and more is a new line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 61 calls, 1,891 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 7 calls, 217 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 7 calls, 217 t-states own (0.00 %) |
| Called from | `ColumnInline`, `EquipmentLine` (tail) |
| Calls | `CapitalNext`, `MarketRow`, `ScreenHeading`, `StatusScreen`, `StatusSystem` |
| Writes | `$D045` (`TextColumn`) |

### `SetRow` (`$E2C8`)

**Row A; 24 and more is row 1, column 0**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 209 calls, 6,498 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 734 calls, 22,773 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 443 calls, 13,752 t-states own (0.00 %) |
| Called from | `NewLine` (tail), `ClearInputRows`, `DataScreen`, `StatusScreen` |
| Calls | `StatusScreen`, `IM2Entry` |
| Writes | `$D046` (`TextRow`) |

### `DeleteChar` (`$E2D5`)

**One letter back on row 21 or 22 (ReadLine's DELETE): the cell's eight pixel rows cleared**

The screen address's low byte is written into the LD HL at `$E2ED` (the column - 1 plus `$A1` or `$C1`): the line editor's rows are rows 5 and 6 of the screen's last third.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintCapitals` (`$E2F8`)

**Standard code A in capitals (control 6), then sentence case (control 8)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5 calls, 360 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 3 calls, 216 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 3 calls, 216 t-states own (0.00 %) |
| Called from | `SetCase`, `PageTitle`, `ShowSelected`, `DataScreen` |
| Calls | `PrintInline`, `PrintCode` (tail) |

### `PageTitle` (`$E306`)

**A screen's title: code A in capitals, the condition light, and code `$77` (three new lines)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 204 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 51 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 51 t-states own (0.00 %) |
| Called from | `ScreenHeading`, `DataScreen`, `MarketPrices` |
| Calls | `ConditionLightVector`, `PrintCode` (tail), `PrintCapitals` |

### `PrintCodes` (`$E311`)

**The zero-ended standard codes at HL; carry at the end**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 18 calls, 8,106 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 33 calls, 13,360 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 33 calls, 13,360 t-states own (0.00 %) |
| Called from | `PrintString` (tail), `ControlPeople`, `PrintIfRowFree` (tail) |
| Calls | `PrintCode` |
| Reads | `$D054`-`$D05E` (`CommanderName`); `$D8DC`-`$D8DF` (`PeopleSuffix`); `$DEDB`-`$DEF1` (`NameBuffer`, `CurrentName`, `SelectedName`) |

### `PrintUnit` (`$E31E`)

**The unit of MarketItem in small letters: t (0-12, 16), kg (13, 14), g (15), km (17: the data screen's radius)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 30 calls, 2,406 t-states own (0.00 %) |
| Called from | `PlotChar`, `MarketRow`, `DataScreen` |
| Calls | `PrintInline`, `PrintCode`, `PrintUnitNow` |
| Reads | `$E1DF` (`MarketItem`) |
| Writes | `$D0D2` (`PrintCapital`) |

### `PrintUnitNow` (`$E349`)

**PrintUnitNow**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 30 calls, 300 t-states own (0.00 %) |
| Called from | `PrintUnit` |
| Calls | `PrintCode` (tail) |

### `IsTonnes` (`$E34C`)

**Carry when MarketItem is sold in tonnes (0-12 and 16): BuyCheck and SellCheck count only those against the free space**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Wait20` (`$E35A`)

**20 frames**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Wait36` (`$E35E`)

**36 frames**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WaitFrames` (`$E360`)

**B frames (HALT B times)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveCursor` (`$E364`)

**The text position into SavedCursor**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearInputRows` (`$E36B`)

**Rows 21 and 22 cleared, the position at row 21, column 0**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 164 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 164 t-states own (0.00 %) |
| Called from | `ShowSelected` |
| Calls | `ColumnZero`, `SetRow`, `ClearCells` |

### `ClearRow22` (`$E37A`)

**Row 22 (cells 1-30) cleared**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearCells` (`$E37D`)

**Eight pixel rows of 30 cells from HL set to A**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 29,624 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 29,624 t-states own (0.01 %) |
| Called from | `ClearInputRows` |
| Writes | `$50A1`-`$50DE` (screen); `$51A1`-`$51DE` (screen); `$52A1`-`$52DE` (screen); `$53A1`-`$53DE` (screen); `$54A1`-`$54DE` (screen); `$55A1`-`$55DE` (screen); 2 more ranges |

### `RestoreCursor` (`$E38D`)

**The text position from SavedCursor**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlanetNamePrompt` (`$E398`)

**PLANET NAME? (other `$0E`, 8 letters): the system found becomes the selected one, else "<name> NOT FOUND"**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadLine` (`$E3CC`)

**Read up to B letters into HL after the other token A on the cleared input rows; ENTER ends, DELETE takes one back**

B is written into the CP at `$E413` (the length check). Accepted: 0-9 and @, A-Z (codes `$30-$39`, `$40-$5A`); each is stored and printed. DELETE (`$FE`: CAPS SHIFT with 0, the keyboard scan's code) moves back one and clears the cell. ENTER or a full buffer ends the line with a zero; the editor waits for ENTER to be let go. Known from the code only (no recording typed a name).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowSelected` (`$E45B`)

**The system nearest the cursor: its name in capitals and its distance on the input rows, a click**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 204 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 204 t-states own (0.00 %) |
| Called from | `CursorDistance` (tail) |
| Calls | `FindNearest`, `PrintDistance`, `Click` (tail), `NewLine`, `PrintCapitals`, `ClearInputRows` |

## chartcursor

`src/game/chartcursor.asm`

### `ChartCross` (`$E46F`)

**The cursor's cross on the chart that is up, by CrossSize: 10 the galactic chart, else the short range one (nothing when off it)**

36 runs (f1, d1: the charts and their cursor). The short range point: x = 97 + 4 (cursor x - current x), y = 96 + 2 (cursor y - current y), refused on any overflow and outside rows 25-166.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 381 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 17 calls, 4,639 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 17 calls, 4,639 t-states own (0.00 %) |
| Called from | `FindNearest` (tail), `ChartLeft` (tail), `GalacticChart`, `ShortRangeChart` (tail) |
| Calls | `DrawCross` (tail) |
| Reads | `$D097`-`$D099` (`Seeds`); `$D0BB`-`$D0BC` (`ChartCursorX`, `ChartCursorY`); `$E52B` (`CrossSize`) |
| Writes | `$D051`-`$D052` (`CrossX`, `CrossY`) |

### `ChartUp` (`$E4D4`)

**S: the cursor two y up (stopping at 0)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ChartDown` (`$E4E6`)

**X: two y down (stopping at 255)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ChartLeft` (`$E4F9`)

**N: one x left (stopping at 1)**

| | |
| --- | --- |
| Runs (launch, flight, hyperspace to Diso, the laser) | 6 calls, 414 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6 calls, 414 t-states own (0.00 %) |
| Called from | `CursorLeft` (tail) |
| Calls | `ChartCross` (tail) |
| Reads | `$D0BB` (`ChartCursorX`) |
| Writes | `$D0BB` (`ChartCursorX`) |

### `ChartRight` (`$E509`)

**M: one x right (stopping at 254)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ChartHome` (`$E51A`)

**B: the cursor back on the current system**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawCross` (`$E52E`)

**Two XOR lines through (CrossX, CrossY): the horizontal one cut at the screen's edges, the vertical one at CrossTop and CrossBottom**

The horizontal line is drawn a byte at a time: a partial byte (a mask of the first bit on), whole bytes of `$FF`, a partial last byte; the three cases are the line inside the screen, cut at the left and cut at the right. The vertical line steps down the screen's pixel rows (NextRowDown) with one bit.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 944 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 18 calls, 4,248 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 4,248 t-states own (0.00 %) |
| Called from | `ChartCross` (tail), `GalacticChart`, `ShortRangeChart` |
| Calls | `DrawCrossLine` (tail), `PixelAddress` |
| Reads | `$D051`-`$D052` (`CrossX`, `CrossY`); `$E52B` (`CrossSize`) |

### `DrawCrossLine` (`$E5CF`)

**DrawCrossLine**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 479 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 18 calls, 1,989 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 1,989 t-states own (0.00 %) |
| Called from | `DrawCross` (tail) |
| Calls | `MaskTop`, `MaskLow`, `DrawCrossEnd` (tail) |
| Reads | `$4888`-`$488C` (screen); `$4A86`-`$4A87` (screen); `$4EA1`-`$4EA2` (screen) |
| Writes | `$4888`-`$488C` (screen); `$4A86`-`$4A87` (screen); `$4EA1`-`$4EA2` (screen) |

### `MaskTop` (`$E611`)

**E = a byte with its top E bits set (the leftmost E pixels)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 316 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 18 calls, 1,626 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 1,626 t-states own (0.00 %) |
| Called from | `DrawCrossLine` |

### `MaskLow` (`$E619`)

**D = a byte with its low D bits set (the rightmost D pixels)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 412 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 18 calls, 2,298 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 2,298 t-states own (0.00 %) |
| Called from | `DrawCrossLine` |

### `PixelAddress` (`$E621`)

**HL = the screen address of x A, row C (the cross's own; the plots use the ROM's PIXEL-ADD)**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8 calls, 960 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 36 calls, 4,320 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 36 calls, 4,320 t-states own (0.00 %) |
| Called from | `DrawCross`, `DrawCrossEnd` |

### `DrawCrossEnd` (`$E63F`)

**DrawCrossEnd**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 5,383 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 18 calls, 23,437 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 18 calls, 23,437 t-states own (0.01 %) |
| Called from | `DrawCrossLine` (tail) |
| Calls | `PixelAddress`, `NextRowDown` |
| Reads | `$4869`-`$48C2` (screen); `$4969`-`$49C2` (screen); `$4A67`-`$4AC2` (screen); `$4B67`-`$4BC2` (screen); `$4C4C`-`$4CC2` (screen); `$4D4C`-`$4DC2` (screen); 4 more ranges |
| Writes | `$4869`-`$48C2` (screen); `$4969`-`$49C2` (screen); `$4A67`-`$4AC2` (screen); `$4B67`-`$4BC2` (screen); `$4C4C`-`$4CC2` (screen); `$4D4C`-`$4DC2` (screen); 2 more ranges |

### `NextRowDown` (`$E6A3`)

**HL one character row down when the pixel row wrapped past a cell**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 8 calls, 360 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 37 calls, 1,665 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 37 calls, 1,665 t-states own (0.00 %) |
| Called from | `DrawCrossEnd` |

## market

`src/game/market.asm`

### `BuyCargo` (`$E6AE`)

**Key 2: the refugees' question in the nova's system, the inventory with refugees aboard, else the buy page**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FirearmsPrice` (`$E6FA`)

**The firearms' price back to 70.4 Cr (`$02C0` tenths) when ZeroFirearms cleared it**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 32 t-states own (0.00 %) |
| Called from | `MarketPrices` |
| Reads | `$E1D2` (`Prices`) |

### `FillAllAttrs` (`$E75E`)

**All 768 attributes set to A (no code calls it; known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FillPage256` (`$E767`)

**256 bytes of A from HL**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `QuantityDelete` (`$E76E`)

**DELETE after the first digit: the digit cleared, the trade undone, start again**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `QuantityKeys` (`$E776`)

**Read a quantity into Quantity, running the check at HL after each digit; carry: A = 1 again, 2 the next row, else leave**

The first key: ENTER is "next row" (A = 2), 1-9 a digit, any other key but DELETE ends the page; the second: ENTER accepts, 0-9 makes Quantity ten times more plus the digit (AddDigit) after the trade is undone and checked again, DELETE starts again. The check returns carry to refuse.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowCash` (`$E7CF`)

**Column 3 on the input row: CASH: and the cash (standard control 7), a click and a wait**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CallCheck` (`$E7DA`)

**JP (HL): the quantity check**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BuyCheck` (`$E7DB`)

**Buy Quantity of MarketItem: the stock, the price Quantity times, the free space (tonnes only), the hold, the legal cost**

Refused with QUANTITY? (more than the stock), CASH? (TakeCredits short) or CARGO? (no free space, or a hold count past 255). A unit of slaves, narcotics or firearms bought costs legal status as a scooped one does (AddCargo's tail at `$D1AD`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NoQuantity` (`$E818`)

**QUANTITY? (code `$B0`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NoCash` (`$E81C`)

**CASH? (code `$C5`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NoRoom` (`$E820`)

**CARGO? (code `$CE`)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClickWait` (`$E832`)

**A click, 36 frames, A = 1 and carry (the row asked again)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SaveTrade` (`$E83C`)

**The cash, the stock byte, the hold byte and the free space copied**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RestoreTrade` (`$E85D`)

**The copy put back**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `QuantityPrompt` (`$E87E`)

**QUANTITY OF <name>/<unit> ? on the cleared input rows**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SellCargo` (`$E8AE`)

**Key 3: with refugees aboard outside the nova's system the reward, else the sell page**

The reward: MissionFlags bit 5 cleared, the combat score's high byte one more, 100 units of gem-stones (`$D07A`) in the hold, the free space 35, YOU HAVE SAVED OUR LIVES! THANK YOU, COMMANDER... (other `$0F`) and the inventory.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TradePage` (`$E8D9`)

**ClearPageText, SellBands and the message row's colour**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearPageText` (`$E8E5`)

**Other `$96`: the page cleared, the rule, capitals, the tab**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 3 calls, 51 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 17 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 17 t-states own (0.00 %) |
| Called from | `DataScreen`, `MarketPrices`, `StatusScreen` |
| Calls | `PrintOther` (tail) |

### `SellCheck` (`$E935`)

**Sell Quantity: the hold less it (QUANTITY? if short), the free space back (tonnes), the price paid Quantity times**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TradePointers` (`$E962`)

**MarketItem 0, HoldPointer one before the hold, PricePointer at PriceBase**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EquipShip` (`$E973`)

**Key 4: EQUIP SHIP, the items the tech level allows with their prices, the cash, then the item's number**

The list has tech level + 3 items, all 14 from tech level 9 on (the count 12 or more becomes 14). EquipPrices `$705F` holds each item's price (a thousands byte, a tenths word): fuel (its price written by the jump), missile 30, large cargo bay 400, E.C.M. 600, pulse laser 400, beam laser 1000, fuel scoops 525, escape pod 1000, energy bomb 900, energy unit 1500, docking computers 1500, galactic hyperdrive 5000, military laser 6000, mining laser 800 Cr. The number typed picks the item (0 or past the list: the status page); the price is taken (CASH? when short).

A page of the four views (0-3, tokens `$60-$63` and VIEW), the key 0-3 picks the mount at LaserMounts `$D07D`; the laser that was there is paid back at its full price (LaserItems `$FD89` gives its item). Another key: the trade undone and the status page.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EquipAccept` (`$EB2D`)

**The equipment's quantity check: always accepted**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EquipPrice` (`$EB2F`)

**HL = EquipPrices + 3 (A - 1): item A's price**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EquipFlag` (`$EB38`)

**HL = `$D081` + Quantity: the item's equipment byte**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddAToHL` (`$EB3E`)

**HL = HL + A**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 13 calls, 416 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 13 calls, 416 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 14 calls, 448 t-states own (0.00 %) |
| Called from | `DamageItem`, `PrintIfRowFree` |

### `EquipFull` (`$EB43`)

**ALL PRESENT (missiles)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EquipFitted` (`$EB47`)

**<item> PRESENT**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScreenHeading` (`$EB63`)

**Column 6, the page title A (PageTitle), then MenuTop with `$17`**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 232 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 116 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 116 t-states own (0.00 %) |
| Called from | `SetColumn`, `GalacticChart`, `ShortRangeChart` |
| Calls | `FillRule` (tail), `FillBytes`, `ColumnInline`, `PageTitle` |

### `MenuTop` (`$EB6E`)

**The top three rows' attributes A and a rule at `$4740`**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## dockedscreens

`src/game/dockedscreens.asm`

### `GalacticChart` (`$EB7C`)

**Screen I: the 256 systems as dots, the current system's cross (16) and its fuel circle, the cursor's cross (10), GALACTIC CHART**

The chart is the galaxy at half height: a system's dot is at (x, y / 2 + 24), x = s1 high, y = s0 high, so rows 24-151 hold it (CrossTop 24, CrossBottom 152). The fuel circle's radius is the fuel / 4 (7.0 light years = 70 tenths: 17 pixels). The text rows 0-2 and 19-23 are cleared (ClearBlock), the bottom five rows coloured `$17` under a rule at `$5060` for the cursor's name and distance. 1 run.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 17,871 t-states own (0.01 %) |
| Called from | `ScreenGalaxy` (tail) |
| Calls | `DrawChartCircleVector`, `FillRule`, `FillBytes`, `ClearScreen`, `DrawFrame`, `NextSystem`, `GalaxySeeds`, `ChartCross`, `DrawCross`, `ScreenHeading`, `ClearBlock`, `PlotSystem` |
| Reads | `$D082` (`Fuel`); `$D097`-`$D099` (`Seeds`) |
| Writes | `$D051`-`$D053` (`CrossX`, `CrossY`, `ChartRadius`); `$E52B`-`$E52D` (`CrossSize`, `CrossTop`, `CrossBottom`) |

### `ClearBlock` (`$EBEE`)

**A x 32 bytes before HL cleared on each of the cell's eight pixel rows: SP at HL and PUSHes of zero, the interrupts off**

HL = `$4060`, A = 3 clears the character rows 0-2; HL = `$5100`, A = 5 the rows 19-23. PUSH writes below SP, so HL is the block's end. 2 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 27,453 t-states own (0.01 %) |
| Called from | `GalacticChart` |
| Reads | `$EC11`-`$EC13` (`ClearBlockCount`, `ClearBlockStack`) |
| Writes | `$EC11`-`$EC13` (`ClearBlockCount`, `ClearBlockStack`) |

### `PlotSystem` (`$EC14`)

**The dot of the system in SystemSeeds at (x, y / 2 + 24): PIXEL-ADD `$22AA`, its bit patched into the SET at `$EC35`**

PIXEL-ADD counts y from the bottom, so B = (y / 2 XOR 127) + 24 is 175 less the row. It returns the bit's place in the byte in A (0 the left); XOR 7, times 8, OR `$C0` is the second byte of SET n,B, written into the instruction. 256 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 256 calls, 44,590 t-states own (0.02 %) |
| Called from | `GalacticChart` |
| Calls | `IM2Entry` |
| Reads | `$4060`-`$40FD` (screen); `$4164`-`$41F5` (screen); `$4261`-`$43D3` (screen); `$446B`-`$45E6` (screen); `$4678`-`$46DA` (screen); `$4778`-`$533A` (screen); 4 more ranges |
| Writes | `$4060`-`$40FD` (screen); `$4164`-`$41F5` (screen); `$4261`-`$43D3` (screen); `$446B`-`$45E6` (screen); `$4678`-`$46DA` (screen); `$4778`-`$533A` (screen); 4 more ranges |

### `ClampLow` (`$EC3B`)

**A = 0: the window's low edge when cx - 19 or cy - 34 went below 0**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClampHigh` (`$EC3D`)

**A = 255: its high edge when cx + 19 or cy + 34 passed 255**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShortRangeChart` (`$EC58`)

**Screen O: SHORT RANGE CHART, the systems near the current one as icons with their names, the current system's cross (24), the fuel circle, the cursor's cross (16)**

The window is the current system's x ± 19 and y ± 34, written into the four CP operands of EachSystemInWindow (`$ECDF`, `$ECE3`, `$ECEA`, `$ECEE`). A system is 4 pixels a unit of x and 2 of y from the centre (97, 96); the fuel circle's radius is the fuel (70 pixels for 7.0 light years). Two walks: the icons (DrawSystemIcon) then the names (LabelSystem), so a name never lands under an icon drawn after it. 3 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 1,114 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 1,114 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 1,114 t-states own (0.00 %) |
| Called from | `ScreenLocal` (tail) |
| Calls | `DrawChartCircleVector`, `FillAttrRow`, `ClearScreen`, `ChartCross` (tail), `DrawCross`, `ScreenHeading`, `EachSystemInWindow` |
| Reads | `$D082` (`Fuel`); `$D097`-`$D099` (`Seeds`) |
| Writes | `$D051`-`$D053` (`CrossX`, `CrossY`, `ChartRadius`); `$E52B`-`$E52D` (`CrossSize`, `CrossTop`, `CrossBottom`); `$EC40`-`$EC57` (`RowsUsed`); `$ECDF`-`$ECEE` (`EachSystemInWindow`) |

### `EachSystemInWindow` (`$ECD2`)

**The 256 systems: those inside the window (x and y each low <= v < high) handed to the routine at HL (the CALL at `$ECF1` patched)**

6 runs (two a chart), 60 systems handed on: 10 a chart around Lave.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 52,638 t-states own (0.03 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 52,676 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 52,676 t-states own (0.01 %) |
| Called from | `ShortRangeChart` |
| Calls | `NextSystem`, `GalaxySeeds`, `DrawSystemIcon`, `LabelSystem`, `IM2Entry` |
| Reads | `$DEC1`-`$DEC3` (`SystemSeeds`); `$FDFF`-`$FE00` (`IM2Vector`) |
| Writes | `$CFF8`-`$CFFB` (`BackBuffer`); `$ECF2`-`$ECF3` (`EachSystemCall`) |

### `EachSystemCall` (`$ECF1`)

**EachSystemCall**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SystemPixel` (`$ECFD`)

**HL = the screen address of the system's icon (its top left at x 94 + 4 dx, row 93 + 2 dy from the current system), A its bit, B and C the coordinates**

dx and dy are the system's x and y less the current system's; the icon is 8 x 8, so its centre is the cross's (97, 96) for dx = dy = 0. 60 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 20 calls, 3,840 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 20 calls, 3,859 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 20 calls, 3,859 t-states own (0.00 %) |
| Called from | `DrawSystemIcon`, `LabelSystem` |
| Calls | `IM2Entry` |
| Reads | `$D097`-`$D099` (`Seeds`); `$DEC1`-`$DEC3` (`SystemSeeds`) |

### `DrawSystemIcon` (`$ED27`)

**One of the four ChartIcons (s2 high AND `$18`: 8 bytes each) XORed in at the system's place, shifted A bits across two bytes, then the next system**

The shift A is written into the LD B at `$ED47`. The icon's eight rows step down the screen's thirds as NextRowDown does. 30 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 10 calls, 23,240 t-states own (0.01 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 10 calls, 23,061 t-states own (0.01 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 10 calls, 23,061 t-states own (0.00 %) |
| Called from | `EachSystemInWindow` |
| Calls | `NextSystem` (tail), `SystemPixel`, `IM2Entry` |
| Reads | `$40A4`-`$46CC` (screen); `$4784`-`$5088` (screen); `$5134`-`$5168` (screen); `$5234`-`$5268` (screen); `$5334`-`$5368` (screen); `$5434`-`$5568` (screen); 6 more ranges |
| Writes | `$40A4`-`$46CC` (screen); `$4784`-`$5088` (screen); `$5134`-`$5168` (screen); `$5234`-`$5268` (screen); `$5334`-`$5368` (screen); `$5434`-`$5568` (screen); 4 more ranges |

### `LabelSystem` (`$ED78`)

**The system's name at the text cell right of its icon: its own row, else the row above (from row 3), else the row below (to row 22), else none**

The column is the icon's x / 8 + 1, the row 22 less the icon's B / 8 rounded up. 30 runs: the ten names around Lave (Diso, Leesti, Orrere, Reorte, Riedquat, Uszaa, Zaonce, Tionisla, Orerve and Lave itself) on each of three charts.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 10 calls, 3,999 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 10 calls, 3,999 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 10 calls, 3,999 t-states own (0.00 %) |
| Called from | `EachSystemInWindow` |
| Calls | `SystemName`, `SystemPixel`, `PrintIfRowFree` |
| Reads | `$D046` (`TextRow`); `$DEDB`-`$DEE3` (`NameBuffer`) |
| Writes | `$D045`-`$D046` (`TextColumn`, `TextRow`); `$ED77` (`LabelLength`) |

### `PrintIfRowFree` (`$EDC5`)

**The name in NameBuffer at TextRow unless RowsUsed has it: the row marked and the name printed (carry), else no carry**

39 runs for 30 names: nine names took a second row.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 13 calls, 1,286 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 13 calls, 1,286 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 13 calls, 1,286 t-states own (0.00 %) |
| Called from | `LabelSystem` |
| Calls | `PrintCodes` (tail), `AddAToHL` |
| Reads | `$D046` (`TextRow`); `$EC44`-`$EC53` (`RowsUsed`) |
| Writes | `$D0D2` (`PrintCapital`); `$EC44`-`$EC53` (`RowsUsed`) |

### `DataScreen` (`$EDDF`)

**Screen P: DATA ON <system> for the system nearest the cursor: the distance, the economy, government, tech level, population and species, productivity, radius, and its description**

The species is in brackets after the population; the productivity has " M CR", the radius " km" (PrintUnit with MarketItem 17). The description is other token 5 (TextRandom from TextSeeds = s1, s2), or IS RESISTING A THARGON INVASION (other `$DE`) for the galaxy's first system while a Thargoid mission is on (MissionState not 0). 1 run (d1, the data on Lave: Rich Agricultural, Dictatorship, Tech.Level 5, Population 2.5 Billion (Human Colonials), Gross Productivity 7000 M CR, Average Radius 4116 km).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 855 t-states own (0.00 %) |
| Called from | `ScreenData` (tail), `PlotChar` |
| Calls | `PrintByteDot`, `PrintByte`, `PrintNumber`, `PrintInline`, `PrintOther` (tail), `ColourBands`, `FindNearest`, `PrintDistance`, `PrintOtherColon`, `PrintCodeColon`, `NewLine`, `SetRow`, `PrintCapitals`, `PageTitle`, `PrintUnit`, `ClearPageText`, `PrintCodeGap`, `NewLineGap`, `PrintEconomy`, `PrintSpecies`, `PrintRadius` |
| Reads | `$D0AF` (`MissionState`); `$DEBC`-`$DEBF` (`SelectedSeeds`); `$DEF9`-`$DEFD` (`Government`, `TechLevel`, `Population`, `Productivity`) |
| Writes | `$D0CE` (`Messages`); `$DECC`-`$DECF` (`TextSeeds`); `$E1DF` (`MarketItem`) |

### `PrintCodeGap` (`$EE9D`)

**Standard code A, a new line and an empty line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5 calls, 145 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 39 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 39 t-states own (0.00 %) |
| Called from | `DataScreen`, `PrintEconomy` (tail), `StatusScreen` |
| Calls | `PrintCodeLine`, `NewLine` (tail), `NewLineGapSecond` (tail) |

### `NewLineGap` (`$EEA2`)

**A new line and an empty line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 3 calls, 51 t-states own (0.00 %) |
| Called from | `DataScreen` |
| Calls | `NewLine` |

### `NewLineGapSecond` (`$EEA5`)

**NewLineGapSecond**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 5 calls, 80 t-states own (0.00 %) |
| Called from | `PrintCodeGap` (tail) |
| Calls | `NewLine` (tail) |

### `PrintEconomy` (`$EEA8`)

**ECONOMY: and RICH / AVERAGE / POOR / MAINLY (codes `$AA-$AD`) and INDUSTRIAL or AGRICULTURAL (economy / 4: codes `$A8`, `$A9`)**

Economy 0-3 take `$AA` + e, 5-7 `$AA` + e - 5, 4 MAINLY: 0 rich, 1 average, 2 poor, 3 mainly industrial, 4 mainly, 5 rich, 6 average, 7 poor agricultural, as the BBC's.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 137 t-states own (0.00 %) |
| Called from | `DataScreen` |
| Calls | `PrintCode`, `PrintOtherColon`, `PrintCodeGap` (tail) |
| Reads | `$DEF8` (`Economy`) |

### `PrintSpecies` (`$EECE`)

**The system's people: HUMAN COLONIALS (s2 low below `$80`), else up to three adjectives and the kind, as the BBC's**

s2 high bits 2-4 below 3: LARGE, FIERCE, SMALL (codes `$E3-$E5`); bits 5-7 below 6: GREEN, RED, YELLOW, BLUE, BLACK, HARMLESS (`$E6-$EB`); (s0 high XOR s1 high) AND 7 below 6: SLIMY, BUG-EYED, HORNED, BONY, FAT, FURRY (`$EC-$F1`); the kind ((that + s2 high AND 3) AND 7): RODENTS to INSECTS (`$F2-$F9`). Lave's people: s2 low below `$80`.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 63 t-states own (0.00 %) |
| Called from | `DataScreen` |
| Calls | `PrintCode` (tail) |
| Reads | `$DEBE`-`$DEBF` (`SelectedSeeds`) |

### `PrintRadius` (`$EF21`)

**The radius in km: ((s2 high AND 15) + 11) x 256 + s1 high, five digits**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 92 t-states own (0.00 %) |
| Called from | `DataScreen` |
| Calls | `PrintNumber` (tail) |
| Reads | `$DEBC`-`$DEBF` (`SelectedSeeds`) |
| Writes | `$D0CE` (`Messages`) |

### `IsFirstSystem` (`$EF37`)

**No carry when the selected system is the galaxy's first (its six seeds the galaxy's)**

m2 ran it once, from JumpTick through MissionTriggers at frame 5183: the jump to Ausis, galaxy 2's first system, made MissionState 3 into 4 (the Thargoid base).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MarketPrices` (`$EF48`)

**Screen K: <system> MARKET PRICES, the heading line (code `$FF`) and the 17 commodities (MarketRow); in witch space only the heading**

1 run (the Lave market of d1).

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 1,320 t-states own (0.00 %) |
| Called from | `ScreenMarket` (tail) |
| Calls | `ColourBands`, `MarketRow`, `PrintCodeLine`, `PageTitle`, `FirearmsPrice`, `ClearPageText` |
| Reads | `$7103` (`WitchSpace`); `$E1DF` (`MarketItem`) |
| Writes | `$D045`-`$D046` (`TextColumn`, `TextRow`); `$E1DF`-`$E1E5` (`MarketItem`, `HoldPointer`, `PricePointer`, `StockPointer`) |

### `StatusScreen` (`$EF87`)

**Screen L: COMMANDER <name>, the present and the hyperspace systems, the fuel, the cash, the legal status, the rating, the equipment and the lasers**

The legal status: CLEAN (0), OFFENDER (1-49), FUGITIVE (50 and more). The rating: while the combat score's top byte is 0 its middle byte against 8, 16, 32, 64, 128 (HARMLESS, MOSTLY HARMLESS, POOR, AVERAGE, ABOVE AVERAGE: the first threshold at or above it, COMPETENT past 128), else the top byte against 2, 10, 25 (COMPETENT, DANGEROUS, DEADLY), ELITE past 25 (RatingScores). The equipment lines: LARGE CARGO BAY, FUEL SCOOPS, the E.C.M. SYSTEM JAMMER (MissionFlags bit 7) or E.C.M. SYSTEM, ENERGY BOMB, ENERGY UNIT, DOCKING COMPUTERS, GALACTIC HYPERSPACE, the four lasers (FRONT PULSE LASER...), CLOAKING DEVICE (bit 6). The escape pod (`$D089`) has no line. 3 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 651 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 651 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 651 t-states own (0.00 %) |
| Called from | `ScreenStatus` (tail), `PrintCode`, `PrintChar`, `PlotChar`, `SetColumn`, `SetRow`, `PrintIfFitted` |
| Calls | `ConditionLightVector`, `PrintInline`, `ColourBands`, `PrintOtherColon`, `PrintCodeLine`, `ColumnInline`, `SetRow`, `ClearPageText`, `PrintCodeGap`, `PrintIfFitted`, `EquipmentLine`, `StatusSystem` |
| Reads | `$D05F`-`$D062` (`LegalStatus`, `CombatScore`); `$D084`-`$D088` (`Equipment`); `$D0B0` (`MissionFlags`); `$F0AE` (`RatingScores`) |
| Writes | `$70E3` (`ViewIndex`) |

### `StatusBomb` (`$F02D`)

**StatusBomb**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1 call, 399 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 1 call, 399 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 1 call, 399 t-states own (0.00 %) |
| Called from | `PrintIfFitted` |
| Calls | `DrawFrame` (tail), `PrintIfFitted`, `PrintLaser` |
| Reads | `$D08A`-`$D08D` (`Equipment`); `$D0B0` (`MissionFlags`) |
| Writes | `$EF86` (`StatusLaserView`) |

### `PrintIfFitted` (`$F068`)

**A not 0: the code byte after the CALL on its own line at column 5; the return past the byte either way**

21 runs: seven equipment lines a status page.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 7 calls, 343 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 7 calls, 343 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 7 calls, 343 t-states own (0.00 %) |
| Called from | `StatusScreen`, `StatusBomb` |
| Calls | `StatusScreen`, `StatusBomb` |
| Reads | `$F00D`-`$F014` (`StatusScreen`); `$F02C`-`$F048` (`StatusScreen`, `StatusBomb`) |

### `EquipmentLine` (`$F072`)

**A new line, column 5**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 68 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 68 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 68 t-states own (0.00 %) |
| Called from | `StatusScreen`, `PrintLaser` (tail) |
| Calls | `NewLine`, `SetColumn` (tail) |

### `PrintLaser` (`$F07A`)

**The laser of the next view (StatusLaserView one more): FRONT / REAR / LEFT / RIGHT and PULSE / BEAM / MILITARY / MINING LASER; nothing for none**

Codes `$60` + view, then `$66` + kind for 1-2 (PULSE LASER `$67`, BEAM LASER `$68`), `$72` + kind for 3-4 (MILITARY `$75`, MINING `$76`). 12 runs: four a page.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 4 calls, 364 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4 calls, 364 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 4 calls, 364 t-states own (0.00 %) |
| Called from | `StatusBomb` |
| Calls | `PrintCode`, `PrintCodeSpace`, `EquipmentLine` (tail) |
| Reads | `$D07D`-`$D080` (`LaserMounts`); `$EF86` (`StatusLaserView`) |
| Writes | `$EF86` (`StatusLaserView`) |

### `StatusSystem` (`$F0A1`)

**Column 21, ":" and standard control A (2 the current system, 3 the selected one), a new line**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2 calls, 104 t-states own (0.00 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 2 calls, 104 t-states own (0.00 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 2 calls, 104 t-states own (0.00 %) |
| Called from | `PrintChar`, `PlotChar`, `SetColumn`, `StatusScreen` |
| Calls | `PrintInline`, `PrintCodeLine` (tail), `ColumnInline` |

### `InventoryScreen` (`$F0B8`)

**Screen ENTER: INVENTORY, the fuel, the cash, LARGE CARGO BAY (its line coloured), REFUGEES (MissionFlags bit 5), the hold (HoldRow for each commodity)**

t1 (3 runs from frame 848), dk and m1 showed it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## keyboard

`src/game/keyboard.asm`

### `ScanJoystick` (`$FC10`)

**ScanKeyboard's row loop end; after the last row the joystick's four bits replace KeySteer's, reversed as the options say**

Kempston (port `$1F`): bit 4 the fire (KeyCombat bit 0), bits 0-3 the directions, the axes' reversal options inverted. Cursor: KeyDigits / 2 (5 left, 8 right, 6 down, 7 up). Sinclair: 6 left, 7 right, 8 down, 9 up. Both: the 0 key fires. Option bit 4 swaps left with right and down with up, bit 5 down with up. With the keyboard, a steering key held clears CAPS SHIFT, F and C (keys a matrix can ghost from N, M, X, S held together; the reason is not stated in the code). Finally 0 with CAPS SHIFT is DELETE (`$FE` in KeyCode). 13398 runs, the keyboard only.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 20,904 calls, 895,330 t-states own (0.47 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 36,568 calls, 1,532,118 t-states own (0.45 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 49,712 calls, 2,072,124 t-states own (0.44 %) |
| Called from | `ScanKeyboardRow` (tail) |
| Calls | `ScanKeyboardRow` (tail) |
| Reads | `$FC08`-`$FC0E` (`KeyScreens`, `KeySteer`, `KeyViews`, `KeyCombat` and 3 more) |
| Writes | `$FC09`-`$FC0B` (`KeySteer`, `KeyViews`, `KeyCombat`) |

### `KeyPressed` (`$FCBA`)

**Key E (bit 5 - E) of row D (8 the CAPS SHIFT row): its character into KeyCode, its bit into its key byte**

The index is bit x 8 + row - 1: KeyCodes gives the character, KeyTable two bytes (the offset from `$FC08` and the mask). 1203 runs.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 153 calls, 35,955 t-states own (0.02 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 354 calls, 83,190 t-states own (0.02 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 696 calls, 163,560 t-states own (0.03 %) |
| Called from | `ScanKeyboardRow` |
| Reads | `$FC08`-`$FC0C` (`KeyScreens`, `KeySteer`, `KeyViews`, `KeyCombat` and 1 more); `$FD41`-`$FD62` (`KeyCodes`); `$FF58`-`$FF9B` (`KeyTable`) |
| Writes | `$FC08`-`$FC0D` (`KeyScreens`, `KeySteer`, `KeyViews`, `KeyCombat` and 2 more) |

### `ScanKeyboard` (`$FD69`)

**The eight half-rows from `$FEFE` to `$7FFE`: every key down through KeyPressed; KeyDigits 0 and KeyCode `$FF` first**

13398 runs (every interrupt of c1, f1, w1 and d1); 1203 keys seen down.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,613 calls, 133,263 t-states own (0.07 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4,571 calls, 233,121 t-states own (0.07 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,214 calls, 316,914 t-states own (0.07 %) |
| Called from | `IM2Entry` |
| Calls | `ScanKeyboardRow` |
| Writes | `$FC0D`-`$FC0F` (`KeyCode`, `Options`, `KeyDigits`) |

### `ScanKeyboardRow` (`$FD76`)

**ScanKeyboardRow**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 20,904 calls, 4,098,255 t-states own (2.16 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 36,568 calls, 7,169,806 t-states own (2.11 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 49,712 calls, 9,748,424 t-states own (2.08 %) |
| Called from | `ScanJoystick` (tail), `ScanKeyboard` |
| Calls | `ScanJoystick` (tail), `KeyPressed` |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `ReadControls` (`$FE01`)

**In a space view: the steering bits into the accumulators RollControl (N, M), PitchControl (X, S), SpeedControl (SPACE, SYMBOL SHIFT); KeySteer cleared**

The roll and the pitch are sign and magnitude words (bit 15 the sign): a key in the word's direction adds `$FF` (roll) or `$66` (pitch) a frame up to a magnitude below `$1000`, a key against it takes as much off (with recentring, option bit 2: straight to 0), and with neither key the magnitude falls by `$3C` or `$24` a frame (damping, option bit 3). The speed goes up `$A0` a frame with SPACE (below `$2000`) and down with SYMBOL SHIFT (to 0). 13398 runs, 11035 in a space view.

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,613 calls, 433,348 t-states own (0.23 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4,571 calls, 1,839,003 t-states own (0.54 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,214 calls, 2,569,649 t-states own (0.55 %) |
| Called from | `IM2Entry` |
| Calls | `ReadControlsSpeed` (tail) |
| Reads | `$70E3` (`ViewIndex`); `$FC09`-`$FC0E` (`KeySteer`, `KeyViews`, `KeyCombat`, `KeyChart` and 2 more); `$FF08`-`$FF0D` (`RollControl`, `PitchControl`, `SpeedControl`) |
| Writes | `$FC09` (`KeySteer`); `$FF08`-`$FF0D` (`RollControl`, `PitchControl`, `SpeedControl`) |

### `ReadControlsSpeed` (`$FEE8`)

**ReadControlsSpeed**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 1,200 calls, 144,410 t-states own (0.08 %) |
| Called from | `ReadControls` (tail) |
| Reads | `$FF0C`-`$FF0D` (`SpeedControl`) |
| Writes | `$FC09` (`KeySteer`); `$FF0A`-`$FF0D` (`PitchControl`, `SpeedControl`) |

### `IM2Entry` (`$FEFE`)

**The address the vector gives: JR IM2Handler**

| | |
| --- | --- |
| Runs (docked at Lave: status, market, data, the two charts, the launch (2560 frames from the title)) | 2,613 calls, 713,349 t-states own (0.38 %) |
| Runs (launch, flight, hyperspace to Diso, the laser) | 4,571 calls, 1,247,883 t-states own (0.37 %) |
| Runs (the witch-space trick: a jump into witch space and the Thargoids) | 6,214 calls, 1,696,422 t-states own (0.36 %) |
| Called from | `FillAttrs`, `CopyRates`, `ChartCursorKeys`, `CloakKey`, `PauseMenu`, `ErrorBeep`, `TitleLoad`, `TitleNext`, `FillAttrPage`, `DrawSunPlanet`, `ProjectCircle`, `Divide24`, `ProjectCircleNone`, `DivideFractionE`, `MoveSunPlanet`, `StationRunIn`, `Stardust`, `StardustFront`, `StarRollPitch`, `StarPlot`, `StardustNext`, `StarPlotAll`, `MulBits`, `DivideShifted`, `DivideFrac8`, `StarAddress`, `StarRespawn`, `StarRespawnFront`, `StarRandom`, `InSystemJump`, `CopyBackBuffer`, `CopyThirdRow`, `CopyThirdLine`, `DashboardRestore`, `SelectView`, `DashboardSave`, `DashDistances`, `CompassDivide`, `VectorLength`, `DrawCompass`, `NextLineDown`, `DrawCompassDialArt`, `DrawBars`, `DrawBar`, `DrawBarRows`, `BarByte`, `ArcRunRight`, `OutlineEdgeUp`, `DrawCircleOutline`, `DrawCircleShape`, `Square`, `CircleArcs`, `CircleArc`, `PointLeft`, `PointRight`, `HalfChord`, `CircleLineUp`, `CircleRowUp`, `CircleRowDown`, `HitFlash`, `CircleBase`, `MaskRight`, `MaskLeft`, `OutlineRunUp`, `OutlineRunDown`, `OutlinePlotTop`, `OutlinePlotSide`, `OutlinePixel`, `OutlineStepX`, `OutlineStepY`, `OutlineStep`, `OutlinePixels`, `TunnelFrame`, `TunnelDivide`, `ClearShips`, `SoundPulsesNow`, `ShiftBC2`, `ShiftBC1`, `DrawScanner`, `ScannerLineUp`, `ScannerRestore`, `ScannerCopy`, `ConditionLight`, `DashboardTick`, `ShieldHit`, `Recharge`, `PrintNext`, `MissileKeys`, `EscapePod`, `UpdateShipsVector`, `Divide16Vector`, `UpdateShips`, `UpdateSlot`, `UpdateSlotNext`, `SquareComponent`, `DivideComponent`, `SquareRoot`, `SquareRootCore`, `SquareRootAdd`, `TidyAxis`, `TidyPart`, `UpdateShip`, `MoveShip`, `MoveAlongAxis`, `MultiplySpeed`, `AddSigned`, `TurnAxis`, `RotatePart`, `TurnOwn`, `MovePosition`, `CombineParts`, `RateBits`, `Tactics`, `NearBox`, `TowardsPartNow`, `TacticsAim`, `MultiplyHigh4`, `DotProduct`, `DrawShip`, `ProjectVertices`, `ProjectVertex`, `EitherFace`, `FaceIsVisible`, `RotateVertexScaled`, `AddSignedBytes`, `Multiply8High`, `MultiplyScaled`, `Multiply8`, `AddDoubled`, `RotateVertexSmall`, `RotateVertexReuse`, `RotateNormal`, `DividePoint`, `DividePointNormalise`, `DividePointShift`, `DividePointLoop`, `Project`, `ProjectAdd`, `ProjectNext`, `DrawEdges`, `PointOf`, `Orthogonalise`, `OrthogonalisePart`, `DifferenceOfProducts`, `Divide16`, `AddSignedHalf`, `DrawLine`, `LineSetup`, `LineFraction`, `LineAddress`, `LineOctant`, `LineUpX`, `LineUpY`, `LineDownX`, `LineDownY`, `Collide`, `Gunsight`, `FaceVisibility`, `FaceDot`, `MultiplyWord`, `NormalPart`, `JumpKeysVector`, `PrintDigit`, `PrintCode`, `PrintOther`, `PrintChar`, `PlotChar`, `PrintStdPair`, `PrintPairNow`, `DrawFrame`, `JustifyChar`, `SetCase`, `ViewTexts`, `MessageTick`, `FindNearestNow`, `NextSystem`, `SquaredDistance`, `MultiplyDA`, `Twist`, `PrintCodeLine`, `NewLine`, `SetRow`, `PlotSystem`, `EachSystemInWindow`, `SystemPixel`, `DrawSystemIcon` |
| Calls | `SoundTickVector`, `ScanKeyboard`, `ReadControls` |
| Reads | `$FF56`-`$FF57` (`IM2SavedSP`) |
| Writes | `$FF56`-`$FF57` (`IM2SavedSP`) |

### `ReadControlsSlower` (`$FF0E`)

**ReadControlsSlower**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `IM2Handler` (`$FF25`)

**The interrupt: its own stack below `$FFBF`, the registers saved, ScanKeyboard, ReadControls and the sound (SoundTickVector)**

13398 runs: one a frame. SP is kept in IM2SavedSP.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `IM2On` (`$FF4C`)

**I = `$FD`, IM 2 (known from the code only: it ran before the recordings started)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `IM1On` (`$FF53`)

**IM 1 (for the tape routines in the ROM; known from the code only)**

| | |
| --- | --- |
| Runs | not reached in the recordings |
