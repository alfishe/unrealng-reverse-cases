# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/game` (c1's whole run (the load and 16 000 frames of seeded random play)). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`menu`](#menu) | `$6D60`-`$7144` | 10 of 21 |
| [`hiscore`](#hiscore) | `$7145`-`$7589` | 4 of 8 |
| [`mainloop`](#mainloop) | `$758A`-`$76D9` | 3 of 5 |
| [`sprites`](#sprites) | `$76DA`-`$7AE8` | 20 of 24 |
| [`input`](#input) | `$7AE9`-`$7C23` | 10 of 12 |
| [`beeper`](#beeper) | `$7C24`-`$7C5E` | 3 of 3 |
| [`colour`](#colour) | `$7C5F`-`$7D16` | 5 of 5 |
| [`tunes`](#tunes) | `$7D17`-`$8096` | 15 of 20 |
| [`player`](#player) | `$8097`-`$8484` | 18 of 34 |
| [`screens`](#screens) | `$8485`-`$8DF4` | 3 of 69 |
| [`hud`](#hud) | `$8DF5`-`$8E85` | 9 of 12 |
| [`objects`](#objects) | `$8E86`-`$9151` | 12 of 19 |
| [`mines`](#mines) | `$9152`-`$9207` | 3 of 6 |
| [`grenade`](#grenade) | `$9208`-`$92FA` | 6 of 8 |
| [`effects`](#effects) | `$92FB`-`$98B9` | 14 of 20 |
| [`pickups`](#pickups) | `$98BA`-`$9A22` | 6 of 9 |
| [`balls`](#balls) | `$9A23`-`$9BD5` | 10 of 12 |
| [`death`](#death) | `$9BD6`-`$9D7E` | 10 of 13 |
| [`guns`](#guns) | `$9D7F`-`$9E84` | 8 of 10 |
| [`passtime`](#passtime) | `$9E85`-`$9F70` | 8 of 15 |
| [`blasts`](#blasts) | `$9F71`-`$A029` | 4 of 6 |
| [`gameover`](#gameover) | `$A02A`-`$A239` | 7 of 12 |
| [`aliens`](#aliens) | `$A23A`-`$A816` | 15 of 25 |
| [`zoneend`](#zoneend) | `$A817`-`$AB96` | 5 of 11 |
| [`forcefield`](#forcefield) | `$AB97`-`$ACD0` | 6 of 12 |
| [`utils`](#utils) | `$ACD1`-`$ADE0` | 7 of 11 |
| [`text`](#text) | `$ADE1`-`$B100` | 16 of 16 |
| [`workarea`](11-data-reference.md#workarea) | `$B101`-`$B6D0` | 0 of 1 |
| [`music`](#music) | `$B6D1`-`$BF6C` | 18 of 21 |
| [`sound`](#sound) | `$BF6D`-`$C7B4` | 28 of 30 |
| [`cpc`](#cpc) | `$C7B5`-`$C7F3` | 2 of 2 |
| [`layouts`](11-data-reference.md#layouts) | `$C7F4`-`$D8DF` | 0 of 2 |
| [`graphics`](11-data-reference.md#graphics) | `$D8E0`-`$FF17` | 0 of 6 |
| [`leftover`](#leftover) | `$FF18`-`$FFFF` | 2 of 4 |

## menu

`src/game/menu.asm`

### `Start` (`$6D60`)

**The entry: the machine test, the new-game reset, then the menu (or the Hall of Fame after a name entry)**

Entered at load with DI (SP `$6D5E` from the loader), and again by GAME OVER and the name entry (`$A02A`, `$A13A` jump here). Sets SP to `$0000` (the stack grows down from `$FFFF`).

The machine test: A = (`$386E`) - `$FF`. The byte is `$FF` in the 48K ROM and `$DD` in the 128K's 48 BASIC ROM, so SoundIsAy `$6E16` = 0 on a 48K (the beeper) and non-zero on a 128K (the AY). c1 / c128: one image, the two paths.

The reset: border black and speaker off, `$9CE2`, `$9ED8`, the screen number `$8523` and the word `$9ED6` zeroed; TitleTunePending `$7D67` = 1; the screen line tables (BuildLineTables `$7BEF`) and the bit-reverse table (BuildReverseTable `$7B99`) built; the score `$AD8A` = "000000"; the lives `$8E7A` = 9.

Then ShowHallOfFame `$71F0`: non-zero after a name entry (h1: set by `$A13A`) goes to ShowHallOfFameFirst `$7145`, else falls into MainMenu. c1: 4 runs, c128: 2, every warp run 1.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,473 t-states own (0.00 %) |
| Called from | `GameOver` (tail) |
| Calls | `MainMenu`, `BuildReverseTable`, `BuildLineTables` |
| Reads | `$71F0` (`ShowHallOfFame`); `$AD8A`-`$AD8E` (`Score`) |
| Writes | `$6E16` (`SoundIsAy`); `$7D67` (`TitleTunePending`); `$8523` (`ScreenNumber`); `$8E7A` (`Lives`); `$9CE2` (`DeathTimer`); `$9ED6`-`$9ED8` (`BonusTicks`, `ExoSuit`); 1 more ranges |
| Ports out | `$00FE` |

### `MainMenu` (`$6DA1`)

**The main menu: draws it, plays the title tune once on a 48K, then waits for 1-5 while the stars twinkle**

Clears the screen (`$B04B`), the occupancy map `$6100` (`$8DF5`) and the foreground map `$5B00` (`$8E03`, filled with `$FF`; the LDIR here carries the fill 31 bytes further, over row 22 of the map). Prints MenuText `$6E17` (the logo, BY RAFFAELE CECCO, the five options, the copyright) and HighlightControl `$6F90` marks the current control type in bright white. `$B6EC` sets up the AY title music.

TitleTunePending `$7D67` (set by Start) is cleared on the first pass: on a 48K (SoundIsAy 0) PlayTune `$7D17` plays TitleTune `$7DA3` once on the beeper, any key stops it. A 128K skips it (c128: `$6DCB` never ran); its title music is the AY tune ticked by DrawSparkle.

Then the attribute copy `$5E00` (`$8E11`: ColourCells writes a sprite colour only where it holds 0), the sprite save buffers cleared (`$B0F3`) and the sparkle slots cleared (ClearMenuStars `$6F83`).

MenuLoop runs `$09C4` = 2500 passes: one MenuSparkles step, one key read (`$ACD1`, ASCII, 0 = none). 1 starts the game (StartGame `$758A`), 2 defines the keys (DefineKeys `$6FAB`), 3 / 4 / 5 set ControlType `$7B97` to 0 keyboard, 1 Interface 2, 2 Kempston and print the menu again with the new highlight. When the count runs out the Hall of Fame rolls (HallOfFameRoll `$7149`). c1: 3978 passes, x1 / m1: the options 2-5 and 1 taken.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 7 calls, 527,560 t-states own (0.03 %) |
| Called from | `Start`, `DefineKeys` (tail) |
| Calls | `MenuSparkles`, `ClearMenuStars`, `HighlightControl`, `DefineKeys` (tail), `StartGame` (tail), `PlayTune`, `ClearBlockMap`, `FillOpenMap`, `SaveAttributes`, `ReadKey`, `PrintString`, `ClearScreen`, `ClearWorkArea`, `TuneStart` |
| Reads | `$5DBF`-`$5DDD` (system); `$6E16` (`SoundIsAy`); `$7B97` (`ControlType`); `$7D67` (`TitleTunePending`) |
| Writes | `$5DC0`-`$5DDE` (system); `$7B97` (`ControlType`); `$7D67` (`TitleTunePending`) |

### `MenuSparkles` (`$6EA9`)

**One step of the menu's twinkling stars: twelve slots, each a 16-frame twinkle at a free place**

Walks SparkleSlots `$6F5E` (3 bytes a slot: x, y, frames left; `$FF` ends), IY the slot's 48-byte save buffer at `$B181` + 48 n. A slot with frames left draws its next frame (DrawSparkle `$6F1F`, sprite SparkleFrames[frames left] at x, y, erasing the previous one in place) and colours its 2x2 cells `$47` (ColourSprite `$7C8F`, only over attribute-0 cells). A free slot picks a random cell (`$AD36`): column (rnd AND `$1E`), row (rnd AND `$1F`) below 22; when the 2x2 cells there are all 0 in the occupancy map `$6100` (nothing printed: MenuText marks its cells 1) it takes x = 4 column (x counts 2-pixel steps), y = 8 row, 16 frames; else it waits for the next pass.

Called once a MainMenu pass (c1: 3978 runs, 47 736 slot visits). Keeps every register.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,978 calls, 16,711,132 t-states own (0.83 %) |
| Called from | `MainMenu` |
| Calls | `DrawSparkle`, `ColourSprite`, `CellOffset`, `Random` |
| Reads | `$6100`-`$63DF` (system); `$6F4E`-`$6F82` (`SparkleFrames`, `SparkleSlots`) |
| Writes | `$6F5E`-`$6F81` (`SparkleSlots`) |

### `DrawSparkle` (`$6F1F`)

**Draws one star frame (DrawSprite), and on a 128K ticks the AY title music every fourth draw**

A = the frame, DE = x, y, BC = the old x, y, HL = the save buffer: DrawSprite `$795C`. On a 128K (SoundIsAy set) AyTickCount `$6F4D` counts the draws and every fourth calls the AY music step `$B767` with every register saved: the 128K's title music runs at the pace of the menu's star draws (c128: 42 219 draws, 10 554 ticks; c1: none).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 42,144 calls, 3,644,333 t-states own (0.18 %) |
| Called from | `MenuSparkles` |
| Calls | `DrawSprite` |
| Reads | `$6E16` (`SoundIsAy`) |

### `ClearMenuStars` (`$6F83`)

**Frees the 12 star slots (36 zero bytes from SparkleSlots)**

Called by MainMenu and DefineKeys. B is 0 after LD BC,`$0023` (B = 0): the first byte is written 0, the LDIR copies it on.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 10 calls, 11,475 t-states own (0.00 %) |
| Called from | `MainMenu`, `DefineKeys` |
| Reads | `$6F5E`-`$6F80` (`SparkleSlots`) |
| Writes | `$6F5E`-`$6F81` (`SparkleSlots`) |

### `HighlightControl` (`$6F90`)

**Paints the current control option of the menu bright white (14 cells from column 11)**

Row 15 + 2 ControlType `$7B97` (KEYBOARD, INTERFACE 2 or KEMPSTON), columns 11-24 set to attribute `$47`. Called by MainMenu after each print of MenuText. c1 / x1 / m1 screens: the chosen option white, the others cyan.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 13 calls, 7,054 t-states own (0.00 %) |
| Called from | `MainMenu` |
| Calls | `CellOffset` |
| Reads | `$59EB`-`$59F7` (screen); `$5A2B`-`$5A37` (screen); `$5A6B`-`$5A77` (screen); `$7B97` (`ControlType`) |
| Writes | `$59EB`-`$59F8` (screen); `$5A2B`-`$5A38` (screen); `$5A6B`-`$5A78` (screen) |

### `DefineKeys` (`$6FAB`)

**Define keys: five prompts LEFT RIGHT JUMP DUCK FIRE, each key patched into ReadKeyboard; ZORBA toggles the infinite lives**

Silences the AY (`$B753`), clears the screen and the maps as MainMenu does, sets ControlType `$7B97` = 0 (the keyboard) and prints DefineKeysText `$7095`. For each of the five prompts (from row 9 column 15, two rows apart): a ? in attribute `$44`, wait for no key (`$AD18`), wait for a key (`$ACD1`: A = its ASCII, D = the half-row's port high byte, E = its bit mask), then D and E go into the key test of ReadKeyboard (IX = `$7AF0` + 10 n: LD B,row at +2, AND mask at +6), A into TypedKeys `$708B`. The key's name is printed in attribute `$43` (KeyNames: the character itself, or SPACE, ENTER, CAPS SHIFT, SYMBOL SHIFT for the codes `$20`, `$0D`, 1, 2) and BeeperNoise clicks (`$C8` pulses).

Then two delays of `$C350` (`$B0B7`) and TypedKeys is compared with CheatWord `$7090`: a difference goes back to MainMenu; ZORBA runs ZorbaCheat `$7046`.

m1: P O Q A M; exA1: Z O R B A (the cheat), then CS SS Q A M (the shift names ran: DefineKeyCapsShift, DefineKeySymbolShift).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3 calls, 705,654 t-states own (0.04 %) |
| Called from | `MainMenu` (tail) |
| Calls | `MainMenu` (tail), `ClearMenuStars`, `BeeperNoise`, `ClearBlockMap`, `FillOpenMap`, `SaveAttributes`, `ReadKey`, `WaitNoKey`, `PrintChar`, `PrintString`, `ClearScreen`, `Delay`, `ClearWorkArea`, `AySilence` |
| Reads | `$5DBF`-`$5DDD` (system); `$708B`-`$7090` (`TypedKeys`, `CheatWord`) |
| Writes | `$5DC0`-`$5DDE` (system); `$705B` (`KeyNames`); `$708B`-`$708F` (`TypedKeys`); `$7AF2`-`$7B1E` (`KeyLeftTest+2`, `KeyRightTest`, `KeyJumpTest`, `KeyDuckTest` and 1 more); `$7B97` (`ControlType`) |

### `DefineKeyCapsShift` (`$7014`)

**The CAPS SHIFT name, and the test for SYMBOL SHIFT (part of DefineKeys)**

LD HL,`$706F` (KeyNames: CAPS SHIFT) when the key's code is 1. Never ran in the given recordings (no prompt took CAPS SHIFT; the static walk does not take the fall-through); exA1 ran it once (CS at the first prompt of its second round).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DefineKeySymbolShift` (`$701B`)

**The SYMBOL SHIFT name, the name printed, the click, the loop, the cheat word check (part of DefineKeys)**

LD HL,`$707C` (KeyNames: SYMBOL SHIFT) when the key's code is 2: never ran in the given recordings, once in exA1 (SS at its second prompt). From `$701E` every prompt runs on here: the code stored in KeyNames' first byte, the name printed in attribute `$43` (each name ends with a move back to the next answer's place, so DE steps two rows down), BeeperNoise with B = `$C8`, the next prompt.

After the fifth: two delays of `$C350`, then TypedKeys `$708B` against CheatWord `$7090`, five bytes: the first difference goes back to MainMenu (c1: 3 times, m1 once); five equal bytes go on into ZorbaCheat `$7046` (exA1 once).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ZorbaCheat` (`$7046`)

**The cheat: keys defined as Z O R B A toggle the lives' DEC A at `$9D1D` to NOP and back, with a jingle when on**

The tail of the compare loop (INC HL / INC DE / DJNZ CheatCompare), then `$9D1D` XOR `$3D`: the lives decrement (`$9D1D`, the ZXDB POKE 40221) becomes NOP (0) or DEC A again. Turned on (the result 0, flag Z) it plays JingleTune `$7D68` (PlayTune, on the beeper on both machines). Then MainMenu. The keys stay defined as Z O R B A (left, right, jump, duck, fire).

Never ran in the given recordings (no definition spelled ZORBA). exA1 (exA's capture: 2, Z, O, R, B, A from entry.z80): the five compares passed, `$9D1D` became 0, the jingle played, and in play the instruction at `$9D1D` ran 10 times as NOP: ten deaths, no life lost.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## hiscore

`src/game/hiscore.asm`

### `ShowHallOfFameFirst` (`$7145`)

**After a name entry: clears ShowHallOfFame and rolls the Hall of Fame (into HallOfFameRoll)**

Start jumps here when ShowHallOfFame `$71F0` is set (`$A13A` sets it after the name). h1: once, after EXOLON was entered. Not in the case's code builds (h1 is a clone), so it was data in the cut.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HallOfFameRoll` (`$7149`)

**The Hall of Fame: a screen of planets, the 50 names and scores rolled up pixel line by pixel line**

Clears the screen with attribute `$44` (`$B04D`), prints HallOfFameScreen `$718D` (the logo, the planets), points HallOfFamePtr `$7588` at HallOfFame `$71F1` and sets the font `$D7E0` (`$ADEF`).

Then `$03C0` = 960 steps: every 16th step (C AND `$0F` = 0) PrintNextHallEntry prints the next entry on row 23, the other steps wait `$0400` (`$B0B7`); each step ScrollHallOfFame moves rows 4-23 of columns 8-23 up one pixel line. 16 lines an entry, so 60 entries' worth: the 50 entries, then 10 empty ones that roll the last up. A key ends it: 1 starts the game (StartGame), any other back to MainMenu; so does the end of the 960 steps.

Reached from MainMenu's timeout and from ShowHallOfFameFirst. h1: the whole roll (960 steps); c128: one step, then key 1; c1: never.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 1 call (`c128` 1) |

### `ScrollHallOfFame` (`$7522`)

**Moves screen lines 33-191 up one pixel line in columns 8-15 and 18-23, then clears the bottom line**

SP walks the line address table `$6700` (the address of column 8 of each line) from line 32: each line's 14 bytes (columns 8-15, then 18-23; columns 16-17 are skipped) are copied to the line above, 159 lines (`$08B2` LDIs, 14 a line). The last line's address is patched into ScrollDest each time. Then 17 bytes from the last destination's end are cleared (the bottom line of the window). SP is kept in SpriteSavedSP `$78DA`. h1: 960 runs, 152 640 lines.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 1 call (`c128` 1) |

### `PrintNextHallEntry` (`$7568`)

**Prints the next Hall of Fame entry (16 characters) on row 23 from column 8, then waits**

HallOfFamePtr `$7588`: at the end mark (`$FF`) only the wait (BC as the caller left it, `$0400`); else the 16 characters of the entry (name and score) through `$AE26` at row 23 column 8, the pointer advanced, then a wait of `$028E`. h1: 60 calls, 50 entries printed.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 1 call (`c128` 1) |

## mainloop

`src/game/mainloop.asm`

### `StartGame` (`$758A`)

**Starts a game: the player reset, ammunition 99, grenades 10, the HUD, the first screen; then the main loop**

Silences the AY (`$B753`), clears the screen, sets `$8269` = `$FF`, turns the player's frames back to facing right when PlayerFlipped `$7BDA` is set (FlipPlayerFrames), `$82F7` = 0, `$82FA` = 1, the player's X, Y (`$82F5`, `$82F6`) and the restart X, Y (`$82F3`, `$82F4`) = `$10`, `$70` (the LD HL is the constant `$7010`, not an address), ammunition `$8E5A` = 99, grenades `$8E66` = 10. DrawHud `$7690`, then `$8494` builds the screen (the screen number `$8523` is what Start left: 0).

MainLoop: one pass of the game, about 2 frames (x2: the fire count rises one every 2 frames). It zeroes `$9E98` and `$9EAE`, then calls in order: `$BF7E` (the AY sound step), ReadControls `$7B72`, `$81A4`, `$8485`, `$8338`, `$83DD`, `$90A2`, `$9CE3`, `$9152`, `$9208`, `$925F`, `$83DD`, `$9A23`, `$9C15`, `$9835`, `$9118`, `$9942`, `$955D`, `$83DD`, `$98BA`, `$BF7E`, `$925F` when `$925A` < `$13` (a grenade in its first frames), `$83DD`, `$90A2`, `$8F54`, `$8F95`, `$83DD`, `$925F` again under the same test, `$9D7F`, `$9DD6`, `$9EC1`, `$9EEE`, `$A553`, `$9FBD`, `$9F2D`, `$A26B`, `$A30B`, `$A360`, `$A7D6`, `$A817`, `$ABCF`, `$AC59`, `$AC7D`, `$90EA`, `$9BB4`, `$9C8B`, `$9E64`, `$A5F4`, `$AD21` (the pause), `$9A19`, a delay of `$01F4` (`$B0B7`), `$BF7E`, `$9E85`, `$9E99`.

At the end of a pass: ImmunityCount `$768D` down by one while non-zero, PassCount `$768C` up by one, the 16-bit pass count of the screen `$AC7B` up by one. It never leaves: GAME OVER and the round end jump out from the routines it calls. c1: 3263 passes, c128 4181, the warp runs 70 867.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 4,664,603 t-states own (0.23 %) |
| Called from | `MainMenu` (tail) |
| Calls | `DrawHud`, `ReadControls`, `MovePlayer`, `FireControl`, `MoveShots`, `ScreenChangeCheck`, `BuildScreen`, `AnimateFlames`, `AnimateTurrets`, `MoveShells`, `ShellsHitPlayer`, `ColourCycle`, `Mines`, `ThrowGrenade`, `MoveGrenade`, `MoveDebris`, `AnimatePuffs`, `Teleports`, `Pods`, `AbortKeys`, `MoveBalls`, `BallsTouchPlayer`, `Traps`, `TrapContact`, `PlayerDeath`, `Guns`, `MoveGunShots`, `GunShotsVsPlayer`, `PadXorSprites`, `PadSlotSprites`, `PayBonusTick`, `RunSparkles`, `ExoSuitBooth`, `RunBlasts`, `HomingMissileStep`, `PickupsVsPlayer`, `AliensStep`, `AlienSpawn`, `AliensVsPlayer`, `FlickerPadStep`, `ZoneEnd`, `ForceFieldStep`, `IdleMissileStart`, `IdleMissileStep`, `PauseKey`, `ClearScreen`, `Delay`, `AySilence`, `SoundEffectsTick` |
| Reads | `$768C`-`$768D` (`PassCount`, `ImmunityCount`); `$7BDA` (`PlayerFlipped`); `$925A` (`GrenadeTimer`); `$AC7B`-`$AC7C` (`IdleTime`) |
| Writes | `$768C`-`$768D` (`PassCount`, `ImmunityCount`); `$8269` (`PlayerFrameShown`); `$82F3`-`$82FA` (`RestartX`, `RestartY`, `PlayerX`, `PlayerY` and 4 more); `$8E5A`-`$8E66` (`Ammo`, `PrintGrenades`, `Grenades`); `$9E98` (`XorSpriteCount`); `$9EAE` (`SlotSpriteCount`); 1 more ranges |

### `StrayReti` (`$768E`)

**A lone RETI: no interrupt runs here (the game keeps DI) and no code jumps here**

Never ran in any recording. `$A897` loads its address into HL (LD HL,`$768E`) before code that does not seem to use it; perhaps an interrupt handler of a version with IM 2 (see SetupIm2 `$7BDB`). Unsure.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawHud` (`$7690`)

**Draws the HUD: AMMO GRENADES POINTS LIVES ZONES on row 22, the score on row 23, then the four counters**

Prints HudText `$76A2`, then `$8E4F`, `$8E5B`, `$8E67` and `$8E7B` print the ammunition, grenades, lives and the screen number (ZONES). Called by StartGame and by the round end (`$A8BB`).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 426 t-states own (0.00 %) |
| Called from | `StartGame` |
| Calls | `PrintAmmo`, `PrintGrenades`, `PrintLives`, `PrintZone` (tail), `PrintString` |

## sprites

`src/game/sprites.asm`

### `DrawBigSprite` (`$76DA`)

**Moves a 24x32 sprite (the player): erases its previous image, draws frame A at DE with masking and edge clipping**

A = the frame (96 bytes at `$EF80` + 96 A, 3 bytes a line, 32 lines), DE = the new x (2-pixel steps), y; BC = the old x, y; HL = the 128-byte buffer holding the previous image as drawn (HL = `$B101`, 128 zero bytes: nothing to erase, and the new image is not kept). Keeps every register.

Each line is shifted right by (2x AND 7) pixels into 4 bytes of ShiftBuffer `$78DC` through BigShiftJumps `$78CA` (shifts of 4 and 6 are done as 4 and 2 left shifts into the byte before). Then BigSpriteMask: the foreground map `$5B00` cells under the new place cut the image where they are 0, and x from `$75` on clips the columns past the right edge. Then the old image is XORed off at the old place and the new XORed on at the new, line by line, and the new image is copied into the buffer.

Called by `$8229` (the player). c1: 980 draws, the warp runs 35 344.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 980 calls, 405,630 t-states own (0.02 %) |
| Called from | `PlayerFrame` (tail) |
| Calls | `BigSpriteRow` |
| Reads | `$78CA`-`$78D7` (`BigShiftJumps`) |
| Writes | `$78DA`-`$78DB` (`SpriteSavedSP`) |

### `BigSpriteRow` (`$7712`)

**One line of a 24-wide frame: C, B, E = its three bytes, D = 0 for the fourth, then the shift routine**

The loop head of DrawBigSprite's shift: POP BC, POP DE, DEC SP takes three bytes, and JP (IX) runs the shift routine picked from BigShiftJumps; each ends by storing four bytes at HL and coming back here for 32 lines, then BigSpriteMask.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 31,360 calls, 1,521,994 t-states own (0.08 %) |
| Called from | `DrawBigSprite`, `BigShiftLeft2` (tail), `BigShiftNone` (tail) |
| Calls | `BigShiftLeft4`, `BigShiftLeft2`, `BigShiftRight2`, `BigShiftNone` |

### `BigShiftLeft4` (`$7719`)

**A 24-wide line shifted 4 pixels left into D C B E (a 4-pixel right shift from the byte before)**

Four rounds of RL E / RL B / RL C / RL D, then the store (BigShiftLeft2's tail). The entry at `$7721` (3 left) and `$7731` (1 left) are for odd pixel shifts, which x in 2-pixel steps never asks for.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 333,617 t-states own (0.02 %) |
| Called from | `BigSpriteRow` |
| Calls | `BigShiftLeft2` |

### `BigShiftLeft2` (`$7729`)

**A 24-wide line shifted 2 pixels left into D C B E (6 right from the byte before), stored D, C, B, E at HL**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4,288 calls, 1,005,755 t-states own (0.05 %) |
| Called from | `BigSpriteRow`, `BigShiftLeft4` |
| Calls | `BigSpriteRow` (tail), `BigSpriteMask` (tail) |
| Writes | `$78DC`-`$795B` (`ShiftBuffer`) |

### `BigShiftRight3` (`$7748`)

**An extra pixel of right shift (3 in all with BigShiftRight2): never ran, x counts 2-pixel steps so the shift is even**

RR C / RR B / RR E / RR D, then BigShiftRight2. BigShiftJumps' entry 3 points here; DrawBigSprite only picks the even entries 0, 2, 4, 6. Never ran in any recording.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BigShiftRight2` (`$7750`)

**A 24-wide line shifted 2 pixels right (C B E D), stored by BigShiftNone**

The entry at `$7758` (1 right) is for odd shifts, never asked.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 252,524 t-states own (0.01 %) |
| Called from | `BigSpriteRow` |
| Calls | `BigShiftNone` |

### `BigShiftNone` (`$7760`)

**Stores the line's four bytes C, B, E, D at HL; 32 lines, then BigSpriteMask**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,328 calls, 2,012,339 t-states own (0.10 %) |
| Called from | `BigSpriteRow`, `BigShiftRight2` |
| Calls | `BigSpriteRow` (tail), `BigSpriteMask` |
| Writes | `$78DC`-`$795B` (`ShiftBuffer`) |

### `BigSpriteMask` (`$776C`)

**DrawBigSprite's second half: the foreground mask, the right-edge clip, then the XOR erase and draw**

HL = the new place's screen address (`$B088`), patched into BigNewScreen. The foreground map `$5B00` (the cell = the screen address's third and low byte) is ANDed over the 4 x 4 cells (5 rows when y is not a multiple of 8): `$FF` means no foreground cell, else BigMaskRows cuts the image by the map, the first cell row for 8 - (y AND 7) lines, then full cell rows, the last for the rest (BigMaskTail).

x from `$75` on (the sprite reaching the right edge) masks the bytes that would wrap to the next line: `$75-$77` keeps three bytes, `$78-$7B` two, `$7C` and over only the first (w runs: 1444 times as the player walks off the right).

Then BigXorLoop: 32 lines, the new image (POP from ShiftBuffer) XORed at the new address in the alternate registers, the old one (the buffer at DE) XORed at the old address; then the 128 bytes copied into the buffer unless it is `$B101`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 980 calls, 16,139,315 t-states own (0.80 %) |
| Called from | `BigShiftLeft2` (tail), `BigShiftNone` |
| Calls | `BigMaskRows8`, `BigMaskRows`, `PixelAddress` |
| Reads | `$4844`-`$502B` (screen); `$5100`-`$512B` (screen); `$5200`-`$522B` (screen); `$5300`-`$532B` (screen); `$5400`-`$542B` (screen); `$5500`-`$552B` (screen); 12 more ranges |
| Writes | `$4844`-`$502B` (screen); `$5100`-`$512B` (screen); `$5200`-`$522B` (screen); `$5300`-`$532B` (screen); `$5400`-`$542B` (screen); `$5500`-`$552B` (screen); 6 more ranges |

### `BigMaskRows8` (`$789E`)

**BigMaskRows for a full cell row (B = 8)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,037 calls, 16,640 t-states own (0.00 %) |
| Called from | `BigSpriteMask` |
| Calls | `BigMaskRows` |

### `BigMaskRows` (`$78A0`)

**Cuts B lines of ShiftBuffer by one row of four foreground map cells**

HL = the map row: its 4 bytes are patched into the AND n of BigMaskLine (3) and C (the fourth); B lines of 4 bytes at DE ANDed with them (0 hides that column of the sprite behind the foreground). HL moves on to the next map row (`$1D` + 3).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,024 calls, 3,623,082 t-states own (0.18 %) |
| Called from | `BigSpriteMask`, `BigMaskRows8` |
| Reads | `$5C24`-`$5C27` (system); `$5C44`-`$5C47` (system); `$5C60`-`$5C8B` (system); `$5CA0`-`$5CAB` (system); `$5CC0`-`$5CCB` (system); `$5CE0`-`$5CEB` (system); 3 more ranges |
| Writes | `$78B2`-`$78BC` (`BigMask0+1`, `BigMask1`, `BigMask2`); `$78DC`-`$795B` (`ShiftBuffer`) |

### `DrawSprite` (`$795C`)

**Moves a 16x16 sprite: erases its previous image, draws frame A at DE masked by the foreground map**

A = the frame (32 bytes at `$F8E0` + 32 A, 2 bytes a line, 16 lines), DE = the new x (2-pixel steps), y; BC = the old x, y; HL = the 48-byte buffer of the previous image (`$B101`: nothing to erase, not kept). Keeps every register.

Each line is shifted into 3 bytes of ShiftBuffer through SpriteShiftJumps `$7AD9`, the foreground map `$5B00` cuts it (SpriteMask, MaskRows), then the old image is XORed off at the old place and the new on at the new one, and the 48 bytes are kept in the buffer. No right-edge clip.

Callers: DrawSparkle (the menu stars), `$9E99`, `$9FBD`, `$A26B`, `$A367`, `$A62D`, `$A7D6`, `$AC7D`. c1: 42 144 draws from the menu alone.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 61,703 calls, 23,396,110 t-states own (1.16 %) |
| Called from | `DrawSparkle`, `PadSlotSprites` |
| Calls | `SpriteRow` |
| Reads | `$7AD9`-`$7ADA` (`SpriteShiftJumps`) |
| Writes | `$78DA`-`$78DB` (`SpriteSavedSP`) |

### `SpriteRow` (`$7990`)

**One line of a 16-wide frame: E, D = its two bytes, A = 0 for the third, then the shift routine**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 987,248 calls, 24,825,820 t-states own (1.24 %) |
| Called from | `DrawSprite`, `ShiftNone` (tail) |
| Calls | `ShiftNone` |

### `ShiftLeft4` (`$7994`)

**A 16-wide line shifted 4 pixels left into A E D (4 right from the byte before)**

The entry at `$7999` (3 left) is for odd shifts, never asked.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings run into, not called (`x2`, `w/022`, `w/079` and 85 more) |

### `ShiftLeft2` (`$799E`)

**A 16-wide line shifted 2 pixels left into A E D, stored A, E, D at HL; 16 lines, then SpriteMask**

The entry at `$79A3` (1 left) is for odd shifts.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 487,344 calls (`x2` 81,472, `w/022` 19,696, `w/079` 18,592 and 78 more) |

### `ShiftRight3` (`$79B3`)

**An extra pixel of right shift (3 in all with ShiftRight2): never ran, x counts 2-pixel steps**

SRL E / RR D / RRA, then ShiftRight2. SpriteShiftJumps' entry 3; DrawSprite only picks the even entries. Never ran in any recording.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShiftRight2` (`$79B8`)

**A 16-wide line shifted 2 pixels right (E D A), stored by ShiftNone**

The entry at `$79BD` (1 right) is for odd shifts.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings run into, not called (`x2`, `w/026`, `w/119` and 79 more) |

### `ShiftNone` (`$79C2`)

**Stores the line's three bytes E, D, A at HL; 16 lines, then SpriteMask**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 473,112,825 t-states own (23.54 %) |
| Called from | `SpriteRow` |
| Calls | `SpriteRow` (tail), `MaskRows8`, `MaskRows`, `PixelAddress` |
| Reads | `$4000`-`$51E0` (screen); `$5200`-`$52E0` (screen); `$5300`-`$53E0` (screen); `$5400`-`$54E0` (screen); `$5500`-`$55E0` (screen); `$5600`-`$56E0` (screen); 7 more ranges |
| Writes | `$4000`-`$51E0` (screen); `$5200`-`$52E0` (screen); `$5300`-`$53E0` (screen); `$5400`-`$54E0` (screen); `$5500`-`$55E0` (screen); `$5600`-`$56E0` (screen); 5 more ranges |

### `SpriteMask` (`$79CA`)

**DrawSprite's second half: the foreground mask, then the XOR erase and draw**

As BigSpriteMask for 3 x 2 cells (3 rows when y is not a multiple of 8), without the edge clip: MaskRows cuts the image where a foreground cell is; then 16 lines XORed (the new from ShiftBuffer at SmallNewScreen, the old from the buffer) and the 48 bytes kept unless the buffer is `$B101`.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 604,078 calls (`c128` 67,584, `x2` 60,700, `w/119` 7,265 and 85 more) |

### `MaskRows8` (`$7AB7`)

**MaskRows for a full cell row (B = 8)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 993 calls, 8,729 t-states own (0.00 %) |
| Called from | `ShiftNone` |
| Calls | `MaskRows` |

### `MaskRows` (`$7AB9`)

**Cuts B lines of ShiftBuffer by one row of three foreground map cells**

HL = the map row: 2 bytes into the AND n of MaskLine and C the third; B lines of 3 bytes at DE ANDed; HL to the next map row (`$1E` + 2).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 1,986 calls, 1,988,605 t-states own (0.10 %) |
| Called from | `ShiftNone`, `MaskRows8` |
| Reads | `$5B06`-`$5B08` (system); `$5B26`-`$5B28` (system); `$5B46`-`$5B48` (system); `$5B66`-`$5B6A` (system); `$5B88`-`$5B8A` (system); `$5DBE`-`$5DC0` (system); 2 more ranges |
| Writes | `$78DC`-`$790B` (`ShiftBuffer`); `$7AC6`-`$7ACB` (`Mask0+1`, `Mask1`) |

## input

`src/game/input.asm`

### `ReadKeyboard` (`$7AE9`)

**Reads the five defined keys into ControlLeft..ControlFire (1 = pressed); DefineKeys patches each test**

Five tests of 10 bytes from `$7AF0` (INC HL / LD B,row / IN A,(C) / AND mask / JR NZ / LD (HL),D), D = 1, HL from `$7B91`: the half-row's port high byte and the bit are written by DefineKeys (+2 and +6). The image's keys: O (`$DF` bit 1) left, P (`$DF` bit 0) right, Q (`$FB` bit 0) jump, A (`$FD` bit 0) duck, M (`$7F` bit 2) fire.

Run by ReadControls when ControlType `$7B97` is 0. Never ran in any recording: every play chose Kempston (5) or Interface 2 (4) before starting, and DefineKeys only patches it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadInterface2` (`$7B22`)

**Reads the Interface 2 stick (keys 6-0, port `$EFFE`) into ControlLeft..ControlFire**

CPL, AND `$1F`: bit 0 (0) fire, bit 1 (9) jump, bit 2 (8) duck, bit 3 (7) right, bit 4 (6) left, each 0 / 1 through NextInputBit. ControlType 1. c1: 443 runs.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 443 calls, 104,908 t-states own (0.01 %) |
| Called from | `ReadControls` (tail) |
| Calls | `NextInputBit` |
| Writes | `$7B92`-`$7B96` (`ControlLeft`, `ControlRight`, `ControlJump`, `ControlDuck` and 1 more) |
| Ports in | `$EFFE` |

### `ReadKempston` (`$7B4A`)

**Reads the Kempston stick (port `$1F`) into ControlLeft..ControlFire**

Bit 0 right, 1 left, 2 duck (down), 3 jump (up), 4 fire. ControlType 2. c1: 2820 runs, c128 4181, all the warp runs.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,820 calls, 605,976 t-states own (0.03 %) |
| Called from | `ReadControls` (tail) |
| Calls | `NextInputBit` |
| Writes | `$7B92`-`$7B96` (`ControlLeft`, `ControlRight`, `ControlJump`, `ControlDuck` and 1 more) |
| Ports in | `$001F` |

### `NextInputBit` (`$7B6D`)

**A = bit 0 of D (0 or 1), D shifted right**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,315 calls, 476,517 t-states own (0.02 %) |
| Called from | `ReadInterface2`, `ReadKempston` |

### `ReadControls` (`$7B72`)

**Reads the chosen controls into ControlLeft..ControlFire (cleared first)**

ControlType `$7B97`: 0 ReadKeyboard, 1 ReadInterface2, else ReadKempston. Called by MainLoop, WaitKeyOrFire and the bonus screen (`$A92F`).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 307,002 t-states own (0.02 %) |
| Called from | `StartGame` |
| Calls | `ReadInterface2` (tail), `ReadKempston` (tail), `ClearControls` |
| Reads | `$7B97` (`ControlType`) |

### `ClearControls` (`$7B84`)

**Zeroes ControlLeft..ControlFire (5 bytes)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 497,486 t-states own (0.02 %) |
| Called from | `ReadControls` |
| Reads | `$7B92`-`$7B95` (`ControlLeft`, `ControlRight`, `ControlJump`, `ControlDuck`) |
| Writes | `$7B92`-`$7B96` (`ControlLeft`, `ControlRight`, `ControlJump`, `ControlDuck` and 1 more) |

### `BuildReverseTable` (`$7B99`)

**Builds the bit-reverse table at `$6400`: byte n holds n with its bits in reverse order**

Called once by Start. Read by FlipPlayerFrames.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 325,051 t-states own (0.02 %) |
| Called from | `Start` |
| Writes | `$6400`-`$64FF` (system) |

### `FlipPlayerFrames` (`$7BAA`)

**Mirrors the player's 24 frames in place (24x32 at `$EF80`) and toggles PlayerFlipped**

768 lines of 3 bytes from `$EF80`: each byte reversed through `$6400` and the outer two swapped. Called when the player turns (`$82B7`, `$82C5`), by `$9D12` and by StartGame (back to facing right). c1: 20 flips, c128: 24. Keeps every register.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 20 calls, 2,676,878 t-states own (0.13 %) |
| Called from | `Fall`, `PlayerDeath` |
| Reads | `$6400`-`$64FE` (system); `$7BDA` (`PlayerFlipped`); `$EF80`-`$F87F` (`PlayerFrames`) |
| Writes | `$7BDA` (`PlayerFlipped`); `$EF80`-`$F87F` (`PlayerFrames`) |

### `SetupIm2` (`$7BDB`)

**Sets IM 2 with a vector table of `$81` at `$8000-$8100`: never ran, nothing calls it, and it would overwrite live code**

LD HL,`$8000` / (`$81` x 257) / IM 2 / I = `$80`. The game runs with DI throughout and `$8000-$8100` holds the beeper engine's tail, the pitch table and live routines, so running this would break the game: a leftover of another build (compare the Amstrad keyboard code at `$C7B5`). Never ran in any recording.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BuildLineTables` (`$7BEF`)

**Builds the screen line tables: `$6500` / `$6600` the high / low address byte of each of 192 lines, `$6700` the word of column 8**

`$6500` + y, `$6600` + y: the address of pixel line y's first byte (read by `$B088` for every sprite and character). `$6700` + 2y: the address of line y's column 8 (ScrollHallOfFame). Called once by Start.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 181,720 t-states own (0.01 %) |
| Called from | `Start` |
| Calls | `NextPixelLine` |
| Writes | `$6500`-`$65BF` (system); `$6600`-`$66BF` (system); `$6700`-`$687F` (system) |

## beeper

`src/game/beeper.asm`

### `NoiseShort` (`$7C24`)

**BeeperNoise with B = `$37`: nothing calls it**

Never ran in any recording, no caller in the image.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BeeperNoise` (`$7C26`)

**A noise burst on the beeper: B pulses of random level, each shorter than the last (nothing on a 128K)**

Returns at once when SoundIsAy is set. Each of the B rounds: OUT (`$FE`) with R AND `$F8` (the speaker and MIC bits random, border 0), a wait of B + 1 loops, OUT 0. So the bursts rise in pitch as they end. Callers: DefineKeys' click (`$C8`), `$8338`, `$83DD`, `$9071`, `$9EC1`, `$9FBD`, `$A817`. c1: 644 calls.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 644 calls, 14,247,634 t-states own (0.71 %) |
| Called from | `DefineKeys`, `FireControl`, `FireShell` |
| Reads | `$6E16` (`SoundIsAy`) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE`, `$20FE`, `$28FE`, `$30FE`, `$38FE`, `$40FE`, `$48FE`, `$50FE`, `$58FE`, `$60FE`, `$68FE`, `$70FE`, `$78FE` |

### `BeeperSweep` (`$7C3C`)

**A falling beeper tone: 16 steps of 10 half-waves, the period from `$30` to `$3F` loops (nothing on a 128K)**

Called by Pods `$9942` five times a pod (AmmoPodChirps `$9996`, GrenadePodChirps `$99EC`). Keeps every register. Ran only in the warp runs (460 calls), never on a 128K path.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 460 calls (`w/076` 20, `w/089` 20, `w/108` 15 and 51 more) |

## colour

`src/game/colour.asm`

### `ColourBigSprite` (`$7C5F`)

**ColourCells for a 24x32 sprite: 3 x 4 cells (4 x 5 when not aligned)**

Called by `$8229` with DrawBigSprite. C = the attribute, DE = x, y.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,291 calls, 476,123 t-states own (0.02 %) |
| Called from | `PlayerFrame` |
| Calls | `ColourCells` (tail) |
| Writes | `$7CB6`-`$7CC8` (`ColourRowSkip+1`, `ColourWidth`, `ColourAligned`, `ColourHeight`) |

### `ColourCell` (`$7C77`)

**ColourCells for one 8x8 cell (2 x 2 when not aligned)**

Callers: `$9291`, `$955D`, `$9835`, `$9A7F`, `$9DD6` (shots and small objects).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 383,508 calls (`x2` 69,499, `w/065` 8,826, `w/040` 8,474 and 96 more) |

### `ColourSprite` (`$7C8F`)

**ColourCells for a 16x16 sprite: 2 x 2 cells (3 x 3 when not aligned)**

Callers: MenuSparkles (`$47`), `$9FBD`, `$A26B`, `$A367`, `$A7D6`, `$AC7D`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 42,144 calls, 6,096,832 t-states own (0.30 %) |
| Called from | `MenuSparkles` |
| Calls | `ColourCells` |
| Writes | `$7CB6`-`$7CC8` (`ColourRowSkip+1`, `ColourWidth`, `ColourAligned`, `ColourHeight`) |

### `ColourCells` (`$7CA7`)

**Writes attribute C over a sprite's cells where the background attribute copy `$5E00` is 0 (black)**

DE = x (2-pixel steps), y. HL = `$5E00` + the cell (`$80DA`), the screen attribute at HL - `$600`. The width (ColourWidth), the row step (ColourRowSkip) and the height (ColourHeight) are patched by the three entries above; one more column when x AND 3 is not 0, one more row when y AND 7 is not 0. A cell whose `$5E00` copy is non-zero keeps its colour: a sprite passing in front of coloured scenery takes the scenery's colour. Keeps every register.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 45,435 calls, 34,712,302 t-states own (1.73 %) |
| Called from | `ColourBigSprite` (tail), `ColourSprite` |
| Calls | `AttrShadowCell` |
| Reads | `$5E00`-`$60DF` (system) |
| Writes | `$5800`-`$5ADF` (screen); `$7CD0`-`$7CDD` (`ColourRowCells+1`, `ColourBlackCell`, `ColourNextCell`, `ColourRowStep`) |

### `WaitKeyOrFire` (`$7CEC`)

**The pause: waits for fire or any key (A = its ASCII from the table `$ACEF`, fire gives '0')**

Jumped to by `$AD21` after the pause key 3 (row `$F7` alone reads `$1B`), a delay and a wait for no key. ReadControls each round: fire ends it with A = '0'; else the keyboard's 40 keys are scanned half-row by half-row against the key table `$ACEF` until one is down. Never ran in the given recordings; exA1: 3 pressed in play, 4631 rounds, then Kempston fire resumed the game.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## tunes

`src/game/tunes.asm`

### `PlayTune` (`$7D17`)

**Plays a two-voice beeper tune (3 bytes a note) until its end or a key: HL = the tune**

Waits for no key, keeps the pointer in TunePointer `$7FEF`. Each note: a key down ends the tune; the length byte (0 ends) into TuneNoteLength `$7FEE`, then two note numbers: both 0 is a rest (PlayTuneRest), else D, E = their periods from the table `$8062` and `$803D` plays them together for the length. Plays on the beeper on both machines (no SoundIsAy test).

Callers: MainMenu (TitleTune, 48K only), ZorbaCheat (JingleTune), GAME OVER `$A02A` (JingleTune). c1: 7 calls (the title tune at each load, GAME OVER).

[Animation: `PlayTune` at work](img/routines/PlayTune.gif)

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 7 calls, 38,808,955 t-states own (1.93 %) |
| Called from | `MainMenu`, `GameOver` |
| Calls | `PlayTwoTones` |
| Reads | `$7D68`-`$7D88` (`JingleTune`); `$7DA3`-`$7E29` (`TitleTune`); `$7FEE`-`$7FF0` (`TuneNoteLength`, `TunePointer`); `$8072`-`$8094` (`NoteReloads+16`) |
| Writes | `$7FEE`-`$7FF0` (`TuneNoteLength`, `TunePointer`) |
| Ports in | `$00FE` |

### `PlayTuneRest` (`$7D45`)

**A rest: the silent twin `$8004` for the note's length, then the next note**

Never ran: neither tune holds a rest (both note numbers 0).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlayTuneNote` (`$7D4E`)

**A note: D = the period of the first number, E of the second (`$8062`), A = the length; `$803D` plays it**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BeeperRestHead` (`$7FF1`)

**The silent twin of the tone engine (the rest): the loop head, never ran**

`$7FF1-$802A` is the two-voice engine of `$802B-$8061` assembled again with each OUT (`$FE`),A replaced by three NOPs (12 T-states for 11): the same loops and timing, no sound. So a rest lasts as long as a note of the same length. Entered at BeeperRest `$8004` from PlayTuneRest. Never ran in any recording (no tune has a rest).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 133 t-states own (0.00 %) |
| Called from | `Sprites16` |
| Writes | `$4000`-`$4001` (screen) |

### `BeeperRest` (`$8004`)

**The silent twin's entry: H = the length, the same loop as `$803D` without the speaker writes (never ran)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 97 t-states own (0.00 %) |
| Calls | `PlayTwoTonesVoice2` |
| Reads | `$800A` (`BeeperRest+6`) |
| Ports out | `$00FE` |

### `BeeperToneHead` (`$802B`)

**The two-voice beeper engine's code before its entry `$803D`: the first voice's reload path**

Part of the engine entered at `$803D` (A = the length in 256-loop units, D and E the two periods from `$8062`). The voices are counters counting up to 0: on its overflow a voice flips the speaker (XOR C, C = `$10`) and reloads; `$802B` is reached from `$804D` (JR NZ) when the first voice has not overflowed. c1: 451 581 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlayTwoTonesVoice2` (`$802D`)

**The second voice's half of the PlayTwoTones loop (placed before the entry)**

Not called: the loop of PlayTwoTones (`$803D`) jumps here from `$804D` (JR NZ to `$802B`: the AND `$FF` there is the pad that equals the XOR C / LD E,IXL of the other branch) when voice 1's counter did not wrap. A' holds the speaker byte, C the speaker bit `$10`.

INC D counts voice 2 up; on the wrap to 0 the speaker bit is output and toggled (Voice2Toggle), and D is reloaded from L (Voice2Reload); then the 256-step inner count B and the duration H as at `$805B`.

The c1 and c128 L1 also list `$802D-$8061` as entries from frame 1808: that is the loading-screen code (picy) that sat at these addresses during the load, not the game.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 451,582 calls, 8,128,488 t-states own (0.40 %) |
| Called from | `BeeperRest`, `TwoTonesVoice1` |
| Calls | `Voice2Toggle`, `Voice2Reload`, `TwoTonesNext` (tail) |
| Writes | `$4000` (screen) |

### `Voice2Toggle` (`$8032`)

**Voice2Toggle**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 6,759 calls, 101,414 t-states own (0.01 %) |
| Called from | `PlayTwoTonesVoice2`, `TwoTonesVoice1` (tail) |
| Calls | `Voice2Reload` |
| Ports out | `$00FE`, `$10FE` |

### `Voice2Reload` (`$8035`)

**Voice2Reload**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 6,760 calls, 298,684 t-states own (0.01 %) |
| Called from | `PlayTwoTonesVoice2`, `Voice2Toggle` |
| Calls | `PlayTwoTonesSetUp`, `TwoTonesStep` (tail), `TwoTonesVoice1` (tail) |
| Reads | `$4000`-`$5AFE` (screen); `$8004`-`$8005` (`BeeperRest`) |
| Writes | `$4001`-`$5AFF` (screen) |

### `PlayTwoTones` (`$803D`)

**Play two square waves at once on the beeper for A units**

Input: A the duration (H: units of 256 loop steps), E voice 1's reload value, D voice 2's reload value (from NoteReloads `$8062`). Each voice counts its 8-bit counter up by one per loop step and toggles the speaker bit `$10` (C) when it wraps to 0, then reloads it: the period is (256 - reload) steps. A holds voice 1's level, A' voice 2's; both are sent to port `$FE` every step, which mixes the two tones. The OR A / AND A / AND `$FF` pads make every path through the loop the same length.

No border colour is kept (bits 0-2 of the OUT are 0). Called by the menu tune player at `$7D4E` (A = the note length from `$7FEE`, B and C the two note numbers looked up in NoteReloads); ran only in c1 and c128 (the warp runs start past the menu).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 79 calls, 316 t-states own (0.00 %) |
| Called from | `PlayTune` |
| Calls | `PlayTwoTonesSetUp` |

### `PlayTwoTonesSetUp` (`$803E`)

**PlayTwoTonesSetUp**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 80 calls, 2,853 t-states own (0.00 %) |
| Called from | `Voice2Reload`, `PlayTwoTones` |
| Calls | `TwoTonesStep`, `TwoTonesStepPad` |
| Reads | `$8006`-`$8007` (`BeeperRest+2`) |

### `TwoTonesStep` (`$8047`)

**TwoTonesStep**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 473,614 calls, 1,894,456 t-states own (0.09 %) |
| Called from | `Voice2Reload` (tail), `PlayTwoTonesSetUp`, `TwoTonesNext` (tail) |
| Calls | `TwoTonesStepPad` |

### `TwoTonesStepPad` (`$8048`)

**TwoTonesStepPad**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 473,615 calls, 1,894,467 t-states own (0.09 %) |
| Called from | `PlayTwoTonesSetUp`, `TwoTonesStep` |
| Calls | `TwoTonesVoice1` |

### `TwoTonesVoice1` (`$8049`)

**TwoTonesVoice1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 475,393 calls, 18,497,045 t-states own (0.92 %) |
| Called from | `Voice2Reload` (tail), `TwoTonesStepPad`, `TwoTonesNext` (tail) |
| Calls | `PlayTwoTonesVoice2`, `Voice2Toggle` (tail), `TwoTonesNext` |
| Reads | `$8008`-`$8009` (`BeeperRest+4`) |
| Ports out | `$00FE`, `$10FE` |

### `TwoTonesNext` (`$8057`)

**TwoTonesNext**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 468,634 calls, 15,970,570 t-states own (0.79 %) |
| Called from | `PlayTwoTonesVoice2` (tail), `TwoTonesVoice1` |
| Calls | `TwoTonesStep` (tail), `TwoTonesVoice1` (tail), `CellOffset` |
| Reads | `$4002`-`$4867` (screen); `$4878`-`$4A67` (screen); `$4A78`-`$4B67` (screen); `$4B78`-`$4C67` (screen); `$4C78`-`$4D67` (screen); `$4D78`-`$5AFE` (screen); 1 more ranges |
| Writes | `$4000`-`$5AFF` (screen) |
| Ports out | `$00FE`, `$10FE` |

## player

`src/game/player.asm`

### `CellOffset` (`$8097`)

**HL = 32 * D + E: the offset of cell row D, column E in a 32-column map**

D the row (signed: SRA keeps a negative row negative), E the column 0-31. Output HL; A destroyed. The base of every map lookup: the block map `$6100` (BlockMapCell `$80C1`), the attribute shadow `$5E00` (AttrShadowCell `$80DA`), the attributes `$5800` (the blinking cells `$9118`), and the object handlers (`$8F95` AnimateTurrets, `$91CF`, `$A23A`, `$A26B`, `$A2D5`, `$AB97`, `$ABCF`), and the menu's `$6EA9` and `$6F90`. c1: 1.26 million entries over the 104 recordings.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 76,848 calls, 5,609,883 t-states own (0.28 %) |
| Called from | `MenuSparkles`, `HighlightControl`, `TwoTonesNext`, `BlockMapCell`, `AttrShadowCell`, `AnimateTurrets`, `ColourCycle`, `DrawStars` |

### `BlockMapCell` (`$80C1`)

**HL = the block map (`$6100`) address of pixel position D (Y), E (X)**

Input: D the Y in pixels, E the X in units of 2 pixels (0-`$7F`: 4 units a character column). Output: HL = `$6100` + 32 (D / 8) + E / 4. AF and DE kept. The block map holds one byte per cell of the 22-row play area: 0 empty, 1 solid scenery, 2 and up an object cell kind (BuildScreen `$8494` and IndexObjectCells `$8E86`).

Called by the four collision tests (`$80F3`, `$8122`, `$814E`, `$8179`), SpawnShot `$8391`, the shots' wall tests `$9362` / `$9382`, `$93A2`, `$93C2` and the print code `$EB` of `$AF2B`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4,218 calls, 590,520 t-states own (0.03 %) |
| Called from | `TestRight`, `TestLeft`, `TestBelow`, `TestAbove`, `SpawnShot`, `ProbeRight` |
| Calls | `CellOffset` |

### `AttrShadowCell` (`$80DA`)

**HL = the attribute shadow (`$5E00`) address of pixel position D, E**

As BlockMapCell with the base `$5E00`: the copy of the screen's attributes SaveAttributes `$8E11` takes once a screen is built. Called by `$7CA7` (the player's colour: cells whose shadow attribute is 0, black, are painted white).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 45,435 calls, 6,360,900 t-states own (0.32 %) |
| Called from | `ColourCells` |
| Calls | `CellOffset` |

### `TestRight` (`$80F3`)

**Is the column right of the player (X, Y in E, D) blocked? NZ = blocked**

E the X, D the Y of the player's top left. X >= `$74`: never blocked (the player may walk off the right edge, PlayerFrame `$8229` sees X = `$80`). X not on a cell boundary (X AND 3 not 0): not blocked (only a whole cell step meets a wall). Otherwise ORs the block map bytes of the column at X / 4 + 3 over the player's 4 rows, and a 5th when Y is not a multiple of 8.

The player is 3 cells wide and 4 high (24 x 32 pixels). Output A (the OR of the bytes) and the Z flag; BC, DE, HL kept.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 60 calls, 10,172 t-states own (0.00 %) |
| Called from | `Fall` |
| Calls | `BlockMapCell` |
| Reads | `$62C6`-`$62CB` (system); `$62E6`-`$62EB` (system); `$6306`-`$630B` (system); `$6326`-`$632B` (system) |

### `TestLeft` (`$8122`)

**Is the column left of the player blocked? NZ = blocked**

X = 0: blocked (A = 1): the left edge is a wall, there is no way back to the previous screen. X not on a cell boundary: not blocked. Otherwise the block map column at X / 4 - 1 over 4 (or 5) rows. Walking left is rare in the random play: 354 entries in c1 and c128 only.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 160 calls, 23,510 t-states own (0.00 %) |
| Called from | `MovePlayer`, `Fall` |
| Calls | `BlockMapCell` |
| Reads | `$6280`-`$6281` (system); `$62A0`-`$62A1` (system); `$62C0`-`$62C6` (system); `$62E0`-`$62E6` (system); `$6300`-`$6306` (system); `$6320`-`$6326` (system) |

### `TestBelow` (`$814E`)

**Is there ground under the player's feet? NZ = ground**

Y not a multiple of 8: no ground (the player is between rows, still falling or jumping). Otherwise the block map row 4 below the top (+`$80`) at X / 4, then X / 4 + 1 and + 2, and + 3 when X is not on a cell boundary; at X >= `$74` only the first column (the part still on the screen). Also called by the death drop (`$9CE3`) and the respawn (`$9D3F`).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4,421 calls, 967,068 t-states own (0.05 %) |
| Called from | `MovePlayer`, `Fall`, `PlayerDeath` |
| Calls | `BlockMapCell` |
| Reads | `$62C4`-`$62C6` (system); `$62E4`-`$62E6` (system); `$6300`-`$630B` (system); `$6320`-`$632B` (system); `$6340`-`$634B` (system) |

### `TestAbove` (`$8179`)

**Is the row above the player's head blocked? NZ = blocked**

As TestBelow with the row above the top (-`$20`): a jump stops when its head meets scenery.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 72 calls, 10,669 t-states own (0.00 %) |
| Called from | `MovePlayer` |
| Calls | `BlockMapCell` |
| Reads | `$6260`-`$6266` (system); `$6282`-`$6286` (system); `$62A2`-`$62A6` (system) |

### `MovePlayer` (`$81A4`)

**One pass of the player's movement: fall, jump, crouch, walk; draws the player**

Called once a main loop pass (about 2 frames) from `$75CC`. SkipIfDying `$9D78` returns past it while the death timer runs. Clears ScreenChanged, takes DE = (PlayerX, PlayerY) and goes:

FallFlag set: Fall (`$8280`). JumpStep set: the jump goes on (`$81E3`). No ground under the feet (TestBelow): Fall. Down held (`$7B95`): crouch: CrouchOffset = -6 and frame `$0A`. Up held (`$7B94`) on the ground: a jump, JumpStep from 22. Otherwise Walk (`$8295` through `$8280`).

A jump step: dy = JumpSteps[JumpStep], JumpStep - 1; down steps test TestBelow, up steps TestAbove; a blocked step ends the jump (JumpStep = 0, Fall). Then the jump keeps its horizontal move MoveDir: TestRight / TestLeft and X + MoveDir. Frame 3 while in the air.

c1 checked: a jump at frame 17492 takes Y `$70` -> `$5E` (18 pixels up) and back in 22 passes (JumpStep `$15` down to 0 by frame 17542).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 451,733 t-states own (0.02 %) |
| Called from | `StartGame` |
| Calls | `TestLeft`, `TestBelow`, `TestAbove`, `PlayerFrame`, `Fall` (tail), `AbortIfDying` |
| Reads | `$7B94`-`$7B95` (`ControlJump`, `ControlDuck`); `$826A`-`$827F` (`JumpSteps`); `$8294` (`FallFlag`); `$82F5`-`$82F8` (`PlayerX`, `PlayerY`, `JumpStep`, `MoveDir`) |
| Writes | `$82F2`-`$82FB` (`ScreenChanged`, `RestartX`, `RestartY`, `PlayerX` and 6 more) |

### `PlayerFrame` (`$8224`)

**Draw the player as frame A (+ the suit's frame base) at DE**

A the frame: 0-9 the walk, 3 in the air, 5 standing, 9 falling, `$0A` crouching, `$0B` the death; SuitFrames `$9ED8` (0, or `$0C` in the exoskeleton, toggled by `$9F2D`) is added. Falls into DrawPlayer `$8229`.

Called by MovePlayer and its branches, the teleport `$98BA`, the death `$9CAF` / `$9CE3` and the exoskeleton booth `$9F2D`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,291 calls, 611,145 t-states own (0.03 %) |
| Called from | `MovePlayer`, `Fall` (tail), `KillPlayer`, `PlayerDeath` (tail) |
| Calls | `DrawBigSprite` (tail), `ColourBigSprite` |
| Reads | `$8269`-`$826A` (`PlayerFrameShown`, `JumpSteps`); `$82F5`-`$82F6` (`PlayerX`, `PlayerY`); `$9ED8` (`ExoSuit`) |
| Writes | `$8269` (`PlayerFrameShown`); `$82F5`-`$82F6` (`PlayerX`, `PlayerY`) |

### `DrawPlayer` (`$8229`)

**Draw the player's frame A' at D, E; X = `$80` is the right edge: the next screen**

A the frame with the suit base (PickUpPods `$9942` enters here with the frame it saved). E = `$80`: NextScreen (`$8253`). Otherwise paints the player's cells white (`$7C5F` with C = `$47`: the cells whose attribute shadow is black), stores DE in PlayerX/PlayerY and, unless the frame and the position are both unchanged (PlayerFrameShown and the old X/Y), stores the frame and jumps to the sprite drawer `$76DA` (HL = `$B181`). A frame is 96 bytes (3 bytes by 32 lines) at `$EF80` + 96 A.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 40,726 calls (`x2` 6,558, `w/118` 742, `w/009` 734 and 51 more) |

### `NextScreen` (`$8253`)

**The player walked off the right edge: raise the screen number, ask for the new screen**

A the player's Y. PlayerY and RestartY = Y, ScreenChanged = Y (not 0: ScreenChangeCheck `$8485` builds the next screen in this pass), ScreenNumber + 1, PlayerFrameShown = `$FF` (redraw). The round end `$A8A5` calls it too, taking ScreenNumber from `$FF` to 0.

x2 (WALKTHROUGH 6.0): NextScreen runs at frames 743, 1471, 1770, 2419 and 2944 (ScreenNumber 0 -> 5), each when the player left the screen on the right; the builds end about 9 frames later (751, 1481, 1771, 2421, 2951).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 16 calls (`w/072` 3, `w/074` 3, `w/023` 2 and 5 more) |

### `Fall` (`$8280`)

**No jump: on the ground walk, in the air drop 4 pixels**

FallFlag = 0; TestBelow: ground -> Walk (`$8295`). No ground: Y + 4, FallFlag = 9 and frame 9 (the fall). While FallFlag is set MovePlayer comes straight here: no jump or crouch in the air, and no move sideways.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 1,528 calls, 199,096 t-states own (0.01 %) |
| Called from | `MovePlayer` (tail) |
| Calls | `FlipPlayerFrames`, `TestRight`, `TestLeft`, `TestBelow`, `PlayerFrame` (tail) |
| Reads | `$7B92`-`$7B93` (`ControlLeft`, `ControlRight`); `$7BDA` (`PlayerFlipped`); `$82F8`-`$82F9` (`MoveDir`, `WalkPhase`) |
| Writes | `$8269` (`PlayerFrameShown`); `$8294` (`FallFlag`); `$82F8`-`$82FA` (`MoveDir`, `WalkPhase`, `Facing`) |

### `Walk` (`$8295`)

**The walk: the left / right inputs move the player 1 unit (2 pixels) a pass**

MoveDir = left XOR right (`$7B92` / `$7B93` as one word): neither (or both): frame 5, standing. Facing = 1, left: MoveDir = Facing = `$FF`. A change of direction first mirrors the 24 player frames (`$7BAA` flips MirrorState `$7BDA`) and draws the standing frame for that pass (TurnAround). Then TestLeft / TestRight: blocked: frame 5; free: X + MoveDir, WalkPhase steps 0-9 and is the frame.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `XorShot` (`$82FC`)

**Draw or erase a shot at D (Y), E (X): 8 pixels of one line, XOR**

The pattern `$BD` (10111101) is shifted to the X's 2-pixel phase (HL = `$00BD` shifted left 2 ((NOT E AND 3) + 1) times) and XORed into the two screen bytes of the line (`$B088`: D the pixel line, E / 4 the column). When the attribute shadow of both cells is black the screen attributes of both become `$47` (bright white on black), so a shot shows on dark scenery.

AF, BC, DE, HL kept. Called by SpawnShot, MoveShots and the shot tests `$9B82`, `$9F71`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 848 calls, 344,727 t-states own (0.02 %) |
| Called from | `SpawnShot` (tail), `MoveShots` |
| Calls | `PixelAddress` |
| Reads | `$4CA7`-`$4CB5` (screen); `$4EE7`-`$4EF5` (screen); `$5FA7`-`$5FB5` (system); `$5FE7`-`$5FF5` (system) |
| Writes | `$4CA7`-`$4CB5` (screen); `$4EE7`-`$4EF5` (screen); `$59AA`-`$59B5` (screen); `$59EA`-`$59F5` (screen) |

### `FireControl` (`$8338`)

**The fire button: one shot a press (two in the exoskeleton), and the hold count for the grenade**

Once a pass from the main loop. SkipIfDying `$9D78`. X >= `$76` (no room for a shot on the right): clears `$7B98` (a byte past the inputs nobody reads) and returns. Fire (`$7B96`) up: FireHeld = 0. Fire held: FireHeld + 1, stopping at `$FF` (the grenade `$9208` throws at 15; FireHeld stays 15 or more while fire is held, so ThrowGrenade throws again each time GrenadeTimer is 0). A new press: FireHeld = 1; with ammunition left: a beep (`$7C26`, B = `$3C`), Ammo - 1 (the ZXDB POKE 33646 at `$836E`), the AY effect `$C177`, the HUD (`$8E4F`) and SpawnShot. In the exoskeleton (SuitFrames `$9ED8` not 0) a second shot 6 pixels lower.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 205,277 t-states own (0.01 %) |
| Called from | `StartGame` |
| Calls | `BeeperNoise`, `SpawnShot`, `PrintAmmo`, `AbortIfDying`, `PlaySfxShot` |
| Reads | `$7B96` (`ControlFire`); `$82F5` (`PlayerX`); `$83DC` (`FireHeld`); `$8E5A` (`Ammo`); `$9ED8` (`ExoSuit`) |
| Writes | `$83DC` (`FireHeld`); `$8E5A` (`Ammo`) |

### `SpawnShot` (`$8391`)

**Start a shot in the first free slot of ShotList at the player's gun**

No free slot (8 shots on the screen): nothing. The slot gets the direction Facing, Y = PlayerY + `$0E` (+ `$13` crouching), X = PlayerX + `$0C` facing right or - 4 facing left. Outside X 4-`$77` or with scenery in the cell or the next one (BlockMapCell): the slot is freed again. Otherwise drawn (XorShot).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 9 calls, 2,865 t-states own (0.00 %) |
| Called from | `FireControl` |
| Calls | `BlockMapCell`, `XorShot` (tail) |
| Reads | `$62A7`-`$62A8` (system); `$62E7`-`$62E8` (system); `$82F5`-`$82FB` (`PlayerX`, `PlayerY`, `JumpStep`, `MoveDir` and 3 more); `$845F`-`$8461` (`ShotList`) |
| Writes | `$845F`-`$8461` (`ShotList`) |

### `MoveShots` (`$83DD`)

**The shots' step: the object hit tests, then every shot 1 unit along**

Called 5 times a main loop pass (so a shot moves 10 pixels a pass). First the hit tests of the objects that can be shot (`$9B52`, `$9E37`, `$A5CA`, `$AC04`, each reading ShotList). Then for each live shot: erase (XorShot), the wall test of the cell ahead (`$9382` going left, `$9362` going right, on the block map; a hit plays `$C0E7` and goes to ShotHitWall); it dies at X `$7C` or 1, at PlayerX + `$40` (52 units from a right shot's start) or PlayerX - `$34` (48 units from a left one's); otherwise X + direction and redrawn.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 10,687,520 t-states own (0.53 %) |
| Called from | `StartGame` |
| Calls | `XorShot`, `ProbeRight`, `ShotsHitBalls`, `GunShotsVsShots`, `AliensVsShots`, `ForceFieldVsShots` |
| Reads | `$82F5` (`PlayerX`); `$845F`-`$8477` (`ShotList`) |
| Writes | `$845F`-`$8461` (`ShotList`) |

### `ClearShots` (`$8478`)

**Free all 8 shot slots (24 zero bytes, the end mark kept)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 2,100 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$845F`-`$8475` (`ShotList`) |
| Writes | `$845F`-`$8476` (`ShotList`) |

## screens

`src/game/screens.asm`

### `ScreenChangeCheck` (`$8485`)

**After the move: when the player left the screen, set X 0 and build the next screen**

ScreenChanged 0: return. Otherwise PlayerX = RestartX = 0 (the player enters on the left at the Y he left at), the ZONES number (`$8E7B`), and on into BuildScreen. Called from the main loop each pass and by the round end `$A8A5`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 91,364 t-states own (0.00 %) |
| Called from | `StartGame` |
| Reads | `$82F2` (`ScreenChanged`) |

### `BuildScreen` (`$8494`)

**Reset the objects and draw screen ScreenNumber from its element list**

Entered at the game start (`$75BB`) and from ScreenChangeCheck. Clears the per-screen state (`$AC7B`, the grenade `$925A`, `$768D`, `$AC78`), FillOpenMap, ClearBlockMap, ClearShots, ClearShells, the other object lists (`$91FA`, `$980F`, ResetTurretList, `$98AD`, `$9AFA`, `$9C7D`, `$9E0A`, `$9F20`, `$A545`, `$A01C`, `$A352`) and the screen (`$B061`: the 22 play rows).

Then the screen's list from the table at `$C7F4` (TableWord, index ScreenNumber): records of 3 bytes, row, column, element number, `$FF` the end. For each the element number goes to `$9487` (with IX = `$9437`: the enemies and objects that element brings), then the element's print string (ElementTable `$852E`) is printed at the row and column by `$AF2B` with the block map value 1 (solid; `$AE1B`), the open-cell value 0 (`$AE21`) and the attribute 0; the string's own codes change them.

At the end: IX's list closed, SaveAttributes, `$A2D5`, IndexObjectCells (the object cells the strings marked become the kinds' lists), `$9B07`, `$A645`, `$A23A`, and on to `$AB97`. 97 warp runs (w/NNN) built every screen 0-124 through here.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 9,116 t-states own (0.00 %) |
| Called from | `StartGame` |
| Calls | `ClearShots`, `TableWord`, `ClearBlockMap`, `FillOpenMap`, `SaveAttributes`, `IndexObjectCells`, `ResetTurretList`, `ClearShellList`, `ArmMines`, `AddDestructible`, `ClearDebris`, `ClearPuffs`, `ClearBalls`, `SpawnBalls`, `ClearTraps`, `ClearGunShots`, `ClearSparkles`, `ClearBlasts`, `HomingMissileStart`, `DrawStars`, `ClearPickups`, `ClearAliens`, `AliensSetUp`, `ForceFieldDraw` (tail), `PrintString`, `ClearPlayArea`, `ClearWorkArea` |
| Reads | `$8523` (`ScreenNumber`); `$C8EE`-`$C909` (`Screen000Layout`) |
| Writes | `$768D` (`ImmunityCount`); `$925A` (`GrenadeTimer`); `$9445` (`DestructibleList+14`); `$AC78`-`$AC7C` (`IdleMissileLive`, `IdleMissilePosition`, `IdleTime`); `$AE1B`-`$AE21` (`PrintCharLine+24`) |

### `TableWord` (`$8524`)

**HL = the word at BC + 2 A (an entry of a table of addresses)**

Used for the screen table `$C7F4` and ElementTable by BuildScreen, and by `$93E2` and `$99F8`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 40 calls, 2,680 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$8532`-`$8549` (`ElementTable+4`); `$856A`-`$8571` (`ElementTable+60`); `$C7F4`-`$C7F5` (`ScreenTable`) |

## hud

`src/game/hud.asm`

### `ClearBlockMap` (`$8DF5`)

**Zero the block map `$6100-$63BF` (22 rows of 32)**

Called by BuildScreen and by the menu (`$6DA1`) and the define-keys screen (`$6FAB`), which print through `$AF2B` too.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 253,135 t-states own (0.01 %) |
| Called from | `MainMenu`, `DefineKeys`, `BuildScreen` |
| Reads | `$6100`-`$63BE` (system) |
| Writes | `$6100`-`$63BF` (system) |

### `FillOpenMap` (`$8E03`)

**Fill the open-cell map `$5B00-$5DBF` with `$FF` (all cells open)**

The printer writes 0 (or `$FF` after code `$EA`) into it for every glyph; the sprite drawers `$777F` / `$79DD` AND a sprite's cells: all `$FF` draws the fast way, a 0 cell means scenery in front.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 251,698 t-states own (0.01 %) |
| Called from | `MainMenu`, `DefineKeys`, `BuildScreen` |
| Reads | `$5B00`-`$5DBE` (system) |
| Writes | `$5B00`-`$5DBF` (system) |

### `SaveAttributes` (`$8E11`)

**Copy the screen attributes `$5800-$5AFF` to the shadow `$5E00-$60FF`**

The scenery's colours once a screen is built: the shot and shell drawers and the player's colouring look at it to colour only black cells.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 287,046 t-states own (0.01 %) |
| Called from | `MainMenu`, `DefineKeys`, `BuildScreen` |
| Reads | `$5800`-`$5AFF` (screen) |
| Writes | `$5E00`-`$60FF` (system) |

### `PrintTwoDigits` (`$8E1D`)

**Print A (0-99) as two digits at D, E in attribute C, in the main font `$D7E0`**

The hundreds are taken off without printing (`$8E37` with B = 100), then the tens and the units. BC, HL kept; E ends past the digits.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 79 calls, 11,850 t-states own (0.00 %) |
| Called from | `PrintAmmo` (tail), `PrintGrenades` (tail) |
| Calls | `HudDigit` |
| Writes | `$ADEF`-`$ADF0` (`PrintChar+14`) |

### `HudDigit` (`$8E37`)

**L = A / B, A = A mod B; print L as a digit at D, E and step E (not for B = 100)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 237 calls, 45,522 t-states own (0.00 %) |
| Called from | `PrintTwoDigits` |
| Calls | `PrintCharAttr` |

### `PrintAmmo` (`$8E4F`)

**Print Ammo on the HUD: row 23 column 1, bright white (`$47`)**

Called by the HUD `$7690`, FireControl, the pod pick-up `$9942` and the death `$9CE3`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 44 calls, 1,760 t-states own (0.00 %) |
| Called from | `DrawHud`, `FireControl`, `PlayerDeath` |
| Calls | `PrintTwoDigits` (tail) |
| Reads | `$8E5A` (`Ammo`) |

### `PrintGrenades` (`$8E5B`)

**Print Grenades on the HUD: row 23 column 8, bright red (`$43`)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 35 calls, 1,400 t-states own (0.00 %) |
| Called from | `DrawHud`, `PlayerDeath` |
| Calls | `PrintTwoDigits` (tail) |
| Reads | `$8E66` (`Grenades`) |

### `PrintLives` (`$8E67`)

**Print Lives as one digit on the HUD: row 23 column 23, bright yellow (`$46`)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 35 calls, 2,555 t-states own (0.00 %) |
| Called from | `DrawHud`, `PlayerDeath` |
| Calls | `PrintCharAttr` (tail) |
| Reads | `$8E7A` (`Lives`) |
| Writes | `$ADEF`-`$ADF0` (`PrintChar+14`) |

### `PrintZone` (`$8E7B`)

**Print ScreenNumber as ZONES on the HUD: row 23 column 28, bright yellow, three digits (`$B0C6`)**

Called by the HUD `$7690` and ScreenChangeCheck.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 160 t-states own (0.00 %) |
| Called from | `DrawHud` (tail) |
| Calls | `PrintNumber3` (tail) |
| Reads | `$8523` (`ScreenNumber`) |

## objects

`src/game/objects.asm`

### `IndexObjectCells` (`$8E86`)

**Turn the object cells the screen's strings marked in the block map into the kinds' lists**

First empties the 16 lists of KindTable (an `$FF` at each list's start, the write pointer back to it). Then walks the 704 bytes of the block map: each value 2-17 is an object cell (AddObjectCell). Called by BuildScreen once the elements are printed.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 164,001 t-states own (0.01 %) |
| Called from | `BuildScreen` |
| Calls | `AddObjectCell` |
| Reads | `$6100`-`$63BF` (system); `$8EF4`-`$8F4F` (`KindTable`) |
| Writes | `$8EF6`-`$8F51` (`KindTable+2`); `$8F89`-`$91B0` (`FlameList`, `FlamePhase`, `AnimateTurrets`, `TurretFrame` and 14 more); `$9930`-`$99F5` (`TeleportPads`, `CellToPixels`, `Pods`, `AmmoPod`); `$9B4B`-`$9C70` (`BallSpawners`, `ShotsHitBalls`, `BallHit`, `BallShot` and 4 more); `$9DC1` (`GunList`); `$9F6E` (`ExoBoothList`); 3 more ranges |

### `AddObjectCell` (`$8EAD`)

**Append cell HL (block map address) of kind A to its list; replace the map byte**

The cell's column and row: (HL - `$6100`) AND 31 and / 32 (`$8EB0` adds `$9F00` = -`$6100`). The kind's record in KindTable (`$8EE8` + 6 A, kinds from 2): the column and row are written at its write pointer, which moves on by the record size, and an `$FF` is put after them; the block map byte becomes the record's +5 value (0 for a cell that is not solid, 1 solid, or the kind kept: 3 and 13).

1838 entries over 103 recordings.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 36 calls, 15,068 t-states own (0.00 %) |
| Called from | `IndexObjectCells` |
| Reads | `$8EF6`-`$8F05` (`KindTable+2`) |
| Writes | `$61C1`-`$61C9` (system); `$6200`-`$620A` (system); `$6264`-`$6266` (system); `$62D4` (system); `$8EF6`-`$8F03` (`KindTable+2`); `$8F89`-`$8F8D` (`FlameList`); 2 more ranges |

### `AnimateFlames` (`$8F54`)

**Draw the jets (kind 2) one frame on: 2 glyphs below each marked cell, random bright colours**

Once a pass. FlamePhase steps 0, 1, 2; the glyphs `$15` + 2 phase and `$16` + 2 phase of the font `$DAB8` go one under the other below the marked cell (row + 1 and + 2) in a random ink (Random `$AD36` AND 7 OR `$42`: bright, on black). Plain print (`$AE26`): no map writes.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 1,351,814 t-states own (0.07 %) |
| Called from | `StartGame` |
| Calls | `Random`, `PrintCharAttr` |
| Reads | `$8F89`-`$8F94` (`FlameList`, `FlamePhase`) |
| Writes | `$8F94` (`FlamePhase`); `$ADEF`-`$ADF0` (`PrintChar+14`) |

### `AnimateTurrets` (`$8F95`)

**The gun turrets (kind 3): fire at random, animate the barrel, notice a destroyed one**

Once a pass, font `$DDD8`. For each turret with a state (1-9; 0 = gone): its block map cell is no longer 3 (the turret was destroyed: GrenadeBlast `$93E2` prints element 5, a destructible, again with printer 3, and this branch XORs off the barrel and the `$12`/`$13` pair): state 0 and the barrel XORed away (its frame, then the `$12`/`$13` pair, in attribute 0). State 1 is idle: 6 times in 256 (Random >= `$FA`) the turret fires (FireShell to the left, C = `$FF`) and its state becomes 9. States 9 to 2 count down one a pass: the frame of the old state is XORed off and the new one on (attributes `$46` and `$06`), through the glyph pairs `$10`, `$1E`, `$1C`, ... `$12`, `$10` of TurretFrames.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 990,552 t-states own (0.05 %) |
| Called from | `StartGame` |
| Calls | `CellOffset`, `TurretFrame`, `FireShell`, `Random`, `XorCharAttr` |
| Reads | `$62D4` (system); `$9019`-`$9025` (`TurretFrames`, `TurretList`) |
| Writes | `$9024` (`TurretList+2`); `$ADEF`-`$ADF0` (`PrintChar+14`) |

### `TurretFrame` (`$9010`)

**A = TurretFrames[A - 1] (the barrel glyph of state A); HL = its address**

The table is read from `$9018` + A (`$9013` LD BC,`$9018`: the byte before TurretFrames, the RET here, is state 0, never asked).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 500 calls, 24,500 t-states own (0.00 %) |
| Called from | `AnimateTurrets` |
| Reads | `$901A`-`$9021` (`TurretFrames+1`) |

### `ResetTurretList` (`$902F`)

**Fill TurretList's 12 bytes with 2: every turret starts in state 2**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,104 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$9022`-`$902C` (`TurretList`) |
| Writes | `$9022`-`$902D` (`TurretList`) |

### `XorShell` (`$903D`)

**Draw or erase a shell at D (Y), E (X): a 2 x 2 pixel dot, XOR**

The pair of bits `$C0` shifted to the X's 2-pixel phase on two pixel lines. When the shadow attributes of the dot's cell and the one left of it are black, the cell left of it becomes `$47` (one cell left of the dot: the shells fly left, into it). AF, BC, DE, HL kept.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 6,818 calls, 2,227,684 t-states own (0.11 %) |
| Called from | `FireShell`, `MoveShells`, `ShellsHitPlayer` |
| Calls | `PixelAddress` |
| Reads | `$4BC0`-`$4BD4` (screen); `$4CC0`-`$4CD4` (screen); `$5FBF`-`$5FD4` (system) |
| Writes | `$4BC0`-`$4BD4` (screen); `$4CC0`-`$4CD4` (screen); `$59C3`-`$59D2` (screen) |

### `FireShell` (`$9071`)

**Fire a shell from the cell at D (row), E (column) in direction C**

The first free slot of ShellList (none: no shell): direction C, Y = 8 row + 3, X = 4 column; drawn; then the shot sound: 10 noise bursts (`$7C26`, B = `$1E`) and the AY effect `$C148`. Called by AnimateTurrets with C = `$FF` (to the left).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 62 calls, 47,664 t-states own (0.00 %) |
| Called from | `AnimateTurrets` |
| Calls | `BeeperNoise`, `XorShell`, `PlaySfxBlast` (tail) |
| Reads | `$90CB`-`$90D3` (`ShellList`) |
| Writes | `$90CB`-`$90D3` (`ShellList`) |

### `MoveShells` (`$90A2`)

**Move every shell 1 unit (2 pixels); it ends at the screen edge (X >= `$7F`)**

Called twice a main loop pass. Shells do not stop at scenery.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 6,523 calls, 5,052,208 t-states own (0.25 %) |
| Called from | `StartGame` |
| Calls | `XorShell` |
| Reads | `$90CB`-`$90E9` (`ShellList`) |
| Writes | `$90CB`-`$90D1` (`ShellList`) |

### `ShellsHitPlayer` (`$90EA`)

**A shell that touches the player is erased and kills him (`$9CAF`)**

For each live shell the box test `$9BD6` (BC = 0) against the player; a hit frees the slot and jumps to the death `$9CAF` (which returns at once while the player is immune or already dying). Once a pass.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,365,170 t-states own (0.12 %) |
| Called from | `StartGame` |
| Calls | `XorShell`, `PlayerContact`, `KillPlayer` (tail) |
| Reads | `$90CB`-`$90E9` (`ShellList`) |
| Writes | `$90CD`-`$90D3` (`ShellList+2`) |

### `ClearShellList` (`$910B`)

**Empty the turrets' shell list ShellList `$90CB` (10 records of 3 bytes)**

Called by the screen builder `$8494` before it builds the object lists. Writes 30 zeros to `$90CB-$90E8`; `$90E9` keeps its `$FF` end mark. The list belongs to `$9071` (a missile fired, its record X, Y, speed), `$90A2` (moves them right) and `$90EA` (kills the player on contact).

c1: 4 runs (one per screen build).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 2,604 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$90CB`-`$90E7` (`ShellList`) |
| Writes | `$90CB`-`$90E8` (`ShellList`) |

### `ColourCycle` (`$9118`)

**Paint every cell of the colour-cycle list in the pass counter's ink, bright**

Main loop (every pass, c1: 3260). For each (column, row) of ColourCycleList: the attribute at `$5800` + 32 row + column = BRIGHT + ink (pass counter `$768C` AND 7), paper 0. The cells come from the screen builder: an element printed a 4 into the map `$6100` there (record 4 of `$8EF4`, the map cell then set to 0).

Screen 0: 6 cells (0,8) (5,8) (10,8) (4,11) (5,11) (6,11); screens 2, 6, 8: 8 cells, the pillars of the two teleport booths (t1 at frame 1000: the booth pillars of screen 14 blink through the inks).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,992,725 t-states own (0.15 %) |
| Called from | `StartGame` |
| Calls | `CellOffset` |
| Reads | `$768C` (`PassCount`); `$9135`-`$9141` (`ColourCycleList`) |
| Writes | `$5900`-`$590A` (screen); `$5964`-`$5966` (screen) |

## mines

`src/game/mines.asm`

### `Mines` (`$9152`)

**The mines: an armed one fires when the player stands on it, a spent one burns**

Main loop, every pass (c1: 3260 entries, the list always empty on screen 0; w clones: 51 682 records walked). Sets the font pointer of the character printer (the operand `$ADEF` of `$ADE1`) to `$DAB8`, the object glyphs, and flips MineFlameToggle between 0 and 2.

A record of MineList is (column, row, state). State 1 (set by ArmMines) is armed: MineArmed tests the player's position. State 0 is spent: two flame glyphs `$1D`/`$1E` (or `$1F`/`$20` on the other pass) are printed at (row, column) and (row, column + 1) in a random bright ink with bit 1 set (red, magenta, yellow or white).

The mine's own picture is part of the scenery element that put a 5 into the map `$6100` (record 5 of `$8EF4`: the map cell then 1, solid).

w030: 1 mine fired; 23 warp clones fired one each.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 309,700 t-states own (0.02 %) |
| Called from | `StartGame` |
| Reads | `$91AF`-`$91B0` (`MineFlameToggle`, `MineList`) |
| Writes | `$91AF` (`MineFlameToggle`); `$ADEF`-`$ADF0` (`PrintChar+14`) |

### `MineBlast` (`$91CF`)

**Throw the debris of a fired mine: ten blank XOR characters, each spawning two debris pieces**

In: D = the row above the mine, E = its column. Selects printer 3 (EraseBlockDebris `$AE95`, SetPrinter), takes the attribute of the cell two rows down (the floor under the mine) into the colour byte of MineBlastText, prints the text at (D, E), then selects printer 0 again.

The text prints two spaces five times at the same place: each character XORed on the screen (a blank glyph: no change), its cell marked in the maps `$5B00` / `$5E00` / `$6100`, and AddDebris called twice for it: 20 debris pieces in the colour of the floor.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 43 calls (`w/050` 4, `w/033` 3, `w/034` 3 and 21 more) |

### `ArmMines` (`$91FA`)

**Set the state byte of the mine records to 1 (armed)**

Called by the screen builder `$8494` before the lists are built: fills `$91B0-$91CD` with 1, so each record's third byte reads 1 once `$8EAD` has written its column and row.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 2,616 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$91B0`-`$91CC` (`MineList`) |
| Writes | `$91B0`-`$91CD` (`MineList`) |

## grenade

`src/game/grenade.asm`

### `ThrowGrenade` (`$9208`)

**Throw a grenade when fire has been held for 15 passes**

Main loop, every pass (c1: 3260). AbortIfDying first. No throw when the player's X (`$82F5`) is `$76` or more (the right edge), when no grenades are left (`$8E66`), when the fire-hold count `$83DC` is below 15 (it counts the passes the fire button is held, `$8338`), or when a grenade is in flight (GrenadeTimer not 0).

The throw: the timer `$20`, the position (player X + 4, player Y; 6 lower when crouching, ThrowFromCrouch), the direction from the facing `$82FA` (`$FF` left, 1 right), the frame 1 facing left, 0 facing right; GrenadeStart draws it, takes one grenade (the DEC A at `$9250` is ZXDB's grenades POKE 37456), plays `$C1BE` and prints the count (`$8E5B`).

Thrown in c128 (3), x2 (14), w030 (8) and 78 warp clones.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 200,890 t-states own (0.01 %) |
| Called from | `StartGame` |
| Calls | `AbortIfDying` |
| Reads | `$82F5` (`PlayerX`); `$83DC` (`FireHeld`); `$8E66` (`Grenades`) |

### `ThrowFromCrouch` (`$9233`)

**A grenade thrown while crouching starts 6 pixels lower**

Y + 6 when `$82FB` is set. Data in the mechanical cut: no recording of c1 / x / w threw from a crouch; exC's t1 did (the crouch + fire hold at frame 410: `$9221-$9245` ran once).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GrenadeStart` (`$9237`)

**Store the new grenade, draw it, count it off**

In: HL = the start (L = X, H = Y). Stores GrenadeX / GrenadeY, the direction (the facing `$82FA`) and the frame (1 when the direction is `$FF`, else 0), draws it with DrawSmallSprite, takes one grenade from `$8E66`, plays `$C1BE` and jumps to `$8E5B` to print the count.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MoveGrenade` (`$925F`)

**One step of the grenade: erase, move along the arc, test the walls and the floor, draw, a trail**

Main loop, up to three times a pass. Nothing when GrenadeTimer is 0. HL = GrenadeArc - 1 + timer (the vertical step), the timer counted down to 1. The grenade is erased (DrawSmallSprite XORs), and the flight ends (GrenadeEnd) at X `$7C` or 0 (the screen's edges), at a wall on its side (ProbeLeft / ProbeRight), when the step is not -1 and ProbeBelow finds a solid cell under it, or at Y `$A8` and more (the play area's bottom).

Else X moves one unit (2 pixels) in GrenadeDir, Y by the arc step; the grenade is drawn and its cells painted bright white (`$47`, `$7C77`). While the timer is `$13` or more a puff (AddPuff) is left 4 units behind it: the smoke trail of the climb.

c128: 199 steps; x2: 396; the end in c128 3 times.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 9,780 calls, 273,840 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$925A` (`GrenadeTimer`) |

### `GrenadeLeftWall` (`$928A`)

**A grenade moving left: the wall test on its left**

ProbeLeft at the grenade's position: a wall ends the flight, else the step goes on at GrenadeAdvance. Data in the cut: no recording threw a grenade to the left (the player faces right in every script; exC's t1 tried left + fire but the hold was too short for a throw).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GrenadeRightWall` (`$9291`)

**A grenade moving right: the wall test on its right, then the step**

ProbeRight; a wall ends the flight (GrenadeEnd). Then the rest of MoveGrenade's step: X + direction, the arc, the floor, the draw, the trail.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## effects

`src/game/effects.asm`

### `DrawSmallSprite` (`$92FB`)

**XOR an 8 x 8 sprite, pre-shifted, at a pixel position**

In: A = the frame, E = X in 2-pixel units (0-127), D = Y in pixels. Every register is kept. The frame is 64 bytes at `$ED40` + 64 A: four copies shifted by 0, 2, 4 and 6 pixels (E AND 3), 16 bytes each, 2 bytes a pixel line, 8 lines. `$B088` gives the screen address of the line; the bytes are read with POP (SP saved at `$78DA`), two lines per loop, the screen address moved down a line in the Spectrum layout (C = 7 the line mask).

Each call adds 1 to `$9E98`, the sprites drawn this pass (`$9E85` pads the pass with more draws, the main loop clears it). Frames seen in the code: 0 / 1 the grenade facing right / left, 2 a debris piece, 3-5 the puff, 6 blank, 7 the ball, 8 the gun's shot (the frames are SmallSprites `$ED40` in the image: 9 sprites of 4 pre-shifted 16-byte copies, up to `$EF7F`).

c1: 52 160 calls, the most called routine of this range.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 52,160 calls, 54,140,681 t-states own (2.69 %) |
| Called from | `PadXorSprites` |
| Calls | `PixelAddress` |
| Reads | `$4004`-`$4005` (screen); `$4104`-`$4105` (screen); `$4204`-`$4205` (screen); `$4304`-`$4305` (screen); `$4404`-`$4405` (screen); `$4504`-`$4505` (screen); 4 more ranges |
| Writes | `$4004`-`$4005` (screen); `$4104`-`$4105` (screen); `$4204`-`$4205` (screen); `$4304`-`$4305` (screen); `$4404`-`$4405` (screen); `$4504`-`$4505` (screen); 4 more ranges |

### `ProbeRight` (`$9362`)

**The map cells to the right of an 8 x 8 object**

In: E = X (2-pixel units), D = Y. Out: A = the map (`$6100`) byte of the cell right of the object's cell, OR the one below it when Y is not on a cell line; 0 when X is not on a cell column (the object is between cells, nothing to meet). NZ = blocked. BC, DE, HL kept. Callers: MoveGrenade, MoveBalls, the player's shots `$83DD`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 424 calls, 52,622 t-states own (0.00 %) |
| Called from | `MoveShots` |
| Calls | `BlockMapCell` |
| Reads | `$62A8`-`$62B5` (system); `$62E8`-`$62F5` (system) |

### `ProbeLeft` (`$9382`)

**The map cells to the left of an 8 x 8 object**

As ProbeRight with the cell on the left (L - 1). Callers: GrenadeLeftWall, MoveBalls, `$83DD`.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 84,338 calls (`x2` 19,068, `w/065` 3,770, `w/040` 3,617 and 50 more) |

### `ProbeBelow` (`$93A2`)

**The map cells under an 8 x 8 object**

In: E = X, D = Y. Out: A = the map byte of the cell under the object, OR the one under its right neighbour when X is not on a cell column; 0 when Y is not on a cell line. Callers: MoveGrenade, MoveBalls.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 109,761 calls (`x2` 22,594, `w/065` 4,420, `w/040` 4,235 and 89 more) |

### `ProbeAbove` (`$93C2`)

**The map cells above an 8 x 8 object**

As ProbeBelow one row up (HL - 32). Caller: MoveBalls (a ball going up).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 97,888 calls (`x2` 22,219, `w/065` 4,396, `w/040` 4,229 and 49 more) |

### `GrenadeBlast` (`$93E2`)

**The grenade's end: destroy the destructible scenery piece it is in**

In: E = X, D = Y of the grenade. Turns them into a cell (column = X / 4, row = Y / 8) and walks DestructibleList: the first record whose box holds the cell (x0 <= column < x1, y0 <= row < y1) and is not destroyed (`$80`) is: its element (the scenery string of `$852E`, the element number at +6) printed again at its place with printer 3 (EraseBlockDebris: XOR erases it, every character throws two debris pieces and clears its cells in the maps), the record marked `$80`, the explosion sound `$C148`, 150 points (`$ADA9`: "000150", AddScore `$AD53`).

A grenade that hits no such box ends silently. c128: 3 ends, x2 9 hits over 14 throws, 55 warp clones destroyed one.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 486 calls (`x2` 14, `w/014` 13, `w/035` 12 and 78 more) |

### `AddDestructible` (`$9487`)

**A scenery element of a destructible kind gets a box in DestructibleList**

Called by the screen builder (`$84EF`) for each element of the screen with A = the element, E = its column, D = its row, IX = the next free record. A kind found in DestructibleKinds writes the record (the box from the kind's offsets and sizes) and moves IX on by 7. AF, BC, HL kept.

c1: 36 elements over its 4 builds of screen 0 (9 a build), 8 destructible (2 a build: the turret and the spire).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 36 calls, 24,452 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$94C6`-`$94F8` (`DestructibleKinds`) |
| Writes | `$9437`-`$9444` (`DestructibleList`) |

### `AddDebris` (`$94F9`)

**Start one debris piece flying from a character cell**

Called twice per character by EraseBlockDebris `$AE95` (printer 3: the mine blast, the grenade blast). In: D = row, E = column, C = the attribute (the printer's colour). Takes the first free record of DebrisList (state 0; none free: nothing): state 1, X = 4 column, Y = 8 row, dx and dy from DebrisSpeeds by random numbers (dy doubled; drawn again until not both 0), draws frame 2 there, colour C AND `$47`.

c128: 98 pieces, x2 370.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 5,362 calls (`x2` 370, `w/000` 282, `w/124` 250 and 66 more) |

### `DebrisSpeed` (`$9548`)

**A = DebrisSpeeds[A] (A = 0-7)**

HL and BC kept.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 11,130 calls (`x2` 763, `w/000` 584, `w/124` 519 and 66 more) |

### `MoveDebris` (`$955D`)

**Move every debris piece; a beeper crackle on the 48K**

Main loop, every pass (c1: 3260, empty). For each piece of state 1: frame 2 erased at (X, Y), X + dx (gone at `$78` and more), Y + dy (gone at `$A9` and more), drawn again, its cells painted in its colour (`$7C77`). On a 48K (flag `$6E16` = 0) each moved piece also sends X x 8 AND `$F8` to port `$FE`: bit 3 (MIC) and bit 4 (speaker) from X's bits 0-1, border black: the crackle of the debris. On a 128K the OUT is skipped (the AY branch at `$9597`; c128 ran `$95A5` 1134 times, never `$959D`).

A piece leaves at the play area's edges only; it flies through walls.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 21,630,100 t-states own (1.08 %) |
| Called from | `StartGame` |
| Reads | `$95B6`-`$980E` (`DebrisList`) |

### `ClearDebris` (`$980F`)

**Clear the debris list (600 bytes)**

Called by the screen builder `$8494`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 50,496 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$95B6`-`$980C` (`DebrisList`) |
| Writes | `$95B6`-`$980D` (`DebrisList`) |

### `AddPuff` (`$981D`)

**Start an explosion puff at a position**

In: E = X, D = Y (the small-sprite position). Takes the first record of PuffList with timer 0 and writes X, Y and the timer 10; the list full: nothing. HL kept. Callers: MoveGrenade (the trail), the player's shots at a wall (`$83DD`), BallHit, the gun shots hit (`$9E4F`), the teleport sparkle `$9EEE`, `$AC7D`.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 9,005 calls (`x2` 1,955, `w/000` 171, `w/007` 163 and 91 more) |

### `AnimatePuffs` (`$9835`)

**One frame step of every puff**

Main loop, every pass (c1: 3260, empty). For each puff with a timer t (10 down to 1): t - 1 stored, frame PuffFrames[t] XORed (it erases last pass's frame) then PuffFrames[t - 1] drawn, the cells painted in a random bright ink with bit 1 set (LD A,R). Frames by pass: 3, 4, 5, 3, 5, 4, 5, 5, 5 and blank (6): the first pass's XOR of frame 6 and the last's are on a blank frame, so nothing is left.

x2: 1955 puffs started.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 4,550,960 t-states own (0.23 %) |
| Called from | `StartGame` |
| Reads | `$9870`-`$98AC` (`PuffList`) |

### `ClearPuffs` (`$98AD`)

**Clear the puff list (60 bytes)**

Called by the screen builder `$8494`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 5,124 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$9870`-`$98AA` (`PuffList`) |
| Writes | `$9870`-`$98AB` (`PuffList`) |

## pickups

`src/game/pickups.asm`

### `Teleports` (`$98BA`)

**Up while standing in one teleport moves the player to the other**

Main loop, every pass. Up (`$7B94`, the Kempston bit 3 / the up key) not pressed: the latch TeleportLatch cleared. Pressed and the latch clear: the latch set, then if the player stands under pad 1 (his top line Y the line below the pad's row, his X within E-12..E+8) the teleport: a sparkle (`$9ED9`) at pad 1, the sound `$C162`, a sparkle at pad 2, the player put at pad 2 (X = pad X - 3, Y the line below its row, frame 5, `$8224`). Else the same test from pad 2 to pad 1.

A screen has at most one pair (map value 6: TeleportPads, the map cell set to 1). Screens 2, 6, 8 have one; w clones teleported 4 times (pad 1 to 2) and 32 times (pad 2 to 1).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 155,988 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$7B94` (`ControlJump`); `$9930`-`$9935` (`TeleportPads`, `TeleportPad2`, `TeleportLatch`) |
| Writes | `$9935` (`TeleportLatch`) |

### `CellToPixels` (`$9936`)

**E = 4 E, D = 8 D: a cell (column, row) to a position (X in 2-pixel units, Y in pixels)**

Every register but DE kept. Callers: Mines, Teleports, Pods, SpawnBalls, Guns, Traps, TrapContact, and `$9F2D`, `$A30B`, `$A7D6`, `$A817`, `$ABCF`, `$AC04`, PrintString `$B03E`.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 136,674 calls (`w/050` 5,996, `w/049` 5,426, `w/116` 5,113 and 94 more) |

### `Pods` (`$9942`)

**The ammunition pod and the grenade pod: walking into one refills**

Main loop, every pass. AmmoPod (map value 7) and GrenadePod (map value 8, `$99F5`) hold one cell each (`$FF`: none). A pod is taken when the player's X is within 12 units left of its (column + 1) and his top line Y is two rows above its row: the pod's picture is printed again with printer 4 (XorMarkPrinter `$AEE4`: XOR erases it) from the strings `$887E` (ammunition) / `$888F` (grenades) of the element table, the pod marked `$FF`, the ammunition set to 99 (`$8E5A`, printed by `$8E4F`, sound `$C0F4`) or the grenades to 10 (`$8E66`, `$8E5B`, sound `$C101`); the player redrawn (`$8269` forced to `$FF`, `$8229`) and five beeper sweeps `$7C3C` (48K only).

w clones: 53 ammunition and 33 grenade pods taken.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 257,540 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$99F2`-`$99F6` (`AmmoPod`, `GrenadePod`) |

### `SetPrinter` (`$99F8`)

**Select the character printer of PrintString: A = 0-4 from Printers**

Patches the four CALL operands of PrintString `$AF2B` (`$AF33`, `$AFC0`, `$AFD2`, `$AFFE`) with Printers[A]. 0: `$ADE1` (the plain printer, the maps written), 3: `$AE95` (XOR, the maps cleared, two debris pieces a character), 4: `$AEE4` (XOR, the maps cleared, no debris). Callers: MineBlast and GrenadeBlast (3), Pods (4); each sets 0 again after its print. BC, HL kept.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 498 calls (`x2` 24, `w/000` 18, `w/010` 14 and 76 more) |

### `AbortKeys` (`$9A19`)

**7, 8, 9 and 0 held together restart the game**

Main loop, every pass (c1: 3260). Reads the keyboard half-row `$EFFE` (0 9 8 7 6); with the four keys 0, 9, 8, 7 down (bits 0-3 all 0) it falls into AbortGame.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 118,787 t-states own (0.01 %) |
| Called from | `StartGame` |
| Ports in | `$EFFE` |

### `AbortGame` (`$9A20`)

**JP `$6D60`: back to the game's entry (the menu)**

Data in the mechanical cut: no recording held the four keys; exC's t1 did (frame 1750) and the jump ran once.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## balls

`src/game/balls.asm`

### `MoveBalls` (`$9A23`)

**Move every ball: a random walk with bounces off the walls and the screen's edges**

Main loop, every pass (c1: 3260, empty on screen 0; w clones: 151 496 balls moved on 50 screens). A record of BallList: X, Y, state (1 alive), dx (+1 / -1). For each live ball: frame 7 erased; dx reversed at X 0 or `$7B`, at random (1 in about 7: a random byte `$DC` or more), or at a wall in its way (ProbeLeft / ProbeRight); X + dx kept in C; a vertical step +1 or -1 at random, 0 when ProbeBelow / ProbeAbove find a wall; Y + step (Y 0 becomes 1); frame 7 drawn at the new place in bright red (`$42`).

The eight balls of a spawner start on the same spot: their first erases there cancel in pairs (XOR).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 32,600 t-states own (0.00 %) |
| Called from | `StartGame` |
| Calls | `MoveBallsLoop` |

### `MoveBallsLoop` (`$9A26`)

**MoveBallsLoop**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 9,004,120 t-states own (0.45 %) |
| Called from | `MoveBalls` |
| Reads | `$9A99`-`$9AF9` (`BallList`) |

### `BallTopRow` (`$9A7E`)

**A ball that reached Y 0 is put on Y 1**

INC D. Data in the mechanical cut: no ball reached the top line in any recording.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BallDraw` (`$9A7F`)

**Draw the ball at its new place and store it**

The tail of MoveBalls: frame 7 at (C, D), bright red, the record's X and Y written.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearBalls` (`$9AFA`)

**Clear the ball list (96 bytes)**

Called by the screen builder `$8494`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 8,148 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$9A99`-`$9AF7` (`BallList`) |
| Writes | `$9A99`-`$9AF8` (`BallList`) |

### `SpawnBalls` (`$9B07`)

**Eight balls at each ball spawner of the screen**

Called by the screen builder (`$8517`). For each (column, row) of BallSpawners: the position (4 column + 2, 8 row + 3), then eight records of BallList there, each alive with a random dx of +1 or -1, frame 4 XORed eight times (no net picture). IX = the next record, `$FF` written after each.

The spawners are the scenery's hanging launchers (w030's screen 30: three of them, the red balls drifting below).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 200 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$9B4B` (`BallSpawners`) |

### `ShotsHitBalls` (`$9B52`)

**The player's shots against the balls**

Called first by the player's shot routine `$83DD` (several times a pass). For each live ball, BallShot tests the shots; a hit kills the ball (BallHit).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 29,541,036 t-states own (1.47 %) |
| Called from | `MoveShots` |
| Reads | `$9A99`-`$9AF9` (`BallList`) |

### `BallHit` (`$9B6B`)

**Kill a ball: erase it, a puff, the sound `$C155`, 50 points**

In: E = X, D = Y of the ball, HL past its record. The state set to 0, AddPuff at the ball, `$C155`, 50 points (`$AD97`: "000050", AddScore `$AD53`). Callers: ShotsHitBalls, BallsTouchPlayer.

w clones: 328 balls killed on 27 screens.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 336 calls (`w/018` 24, `w/066` 24, `w/019` 16 and 25 more) |

### `BallShot` (`$9B82`)

**Is one of the player's shots on this ball?**

In: E = X, D = Y of a ball (or a gun's shot: `$9E37`). Walks the shot list `$845F` (X, Y, direction; 0: free): a shot within X+2-4..X+1 and Y-1..Y+8 is erased (`$82FC`) and freed. Out: A = 1 for a hit, else 0. BC, DE, HL kept.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 1,062,847 calls (`x2` 222,400, `w/065` 44,045, `w/040` 42,326 and 61 more) |

### `BallsTouchPlayer` (`$9BB4`)

**A ball touching the player kills him (and itself)**

Main loop, every pass. PlayerContact with a box of 8 lines by 4 units for each live ball; a touch: BallHit, the sound `$C155` again, then KillPlayer (no exoskeleton test: a ball kills through it).

w030: 7 touches (immune clones).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 5,907,120 t-states own (0.29 %) |
| Called from | `StartGame` |
| Reads | `$9A99`-`$9AF9` (`BallList`) |

## death

`src/game/death.asm`

### `PlayerContact` (`$9BD6`)

**Does a box at a position overlap the player?**

In: E = X, D = Y of the box's top left, C = its width in 2-pixel units, B = its height in lines. Out: A = 1 when it overlaps the player (X `$82F5`, Y `$82F6`): his box is 12 units wide (X-12..X+C-1 holds the box) and 32 lines tall, 26 lines (Y+6 on) when crouching (`$82FB`). HL kept.

Callers: the missiles `$90EA`, BallsTouchPlayer, TrapContact, the gun shots `$9E64`, `$A26B`, `$A30B`, `$A5F4`, `$AC7D`. c1: 1719 tests, 59 hits; the crouched box (PlayerContactCrouched) 14 times in c1.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 1,719 calls, 174,849 t-states own (0.01 %) |
| Called from | `ShellsHitPlayer` |
| Reads | `$82F5`-`$82FB` (`PlayerX`, `PlayerY`, `JumpStep`, `MoveDir` and 3 more) |

### `Traps` (`$9C15`)

**The traps: probes that rise out of the floor, hold, and sink again**

Main loop, every pass. The ZXDB traps POKE (39957) puts a RET at the first byte: every warp clone ran with it, so the body (`$9C25-$9C6F`) is data in the mechanical cut; exC's t1 (screen 14, three traps, no traps POKE) ran it 1047 times.

A record of TrapList: column, row, counter. Each pass the counter goes up by one: below `$65` the trap rests, sunk; `$65-$68` it rises one row a pass; `$69-$73` it stays up; `$74-$77` it sinks one row a pass; at `$78` the counter restarts at `$14` + a random 0-63 (a wait of 25 to 81 passes). While it moves or stands up it is drawn each pass with `$76DA`: the big sprite `$18` moved from the old row to the new at the column, with the trap's own background buffer (IX: `$B201` for the first trap, `$80` bytes each), then its cells painted bright green (`$44`, `$7C5F`).

TrapContact kills the player on it.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 244,500 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$9C70` (`TrapList`) |

### `ClearTraps` (`$9C7D`)

**Fill the trap records with `$5F`, the counters' start**

Called by the screen builder `$8494` before the lists are built: `$5F` in `$9C70-$9C7B`; the builder then writes each trap's column and row over the first two bytes.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,104 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$9C70`-`$9C7A` (`TrapList`) |
| Writes | `$9C70`-`$9C7B` (`TrapList`) |

### `TrapContact` (`$9C8B`)

**A trap that is up kills the player it touches**

Main loop, every pass. For each trap with a counter of `$65` or more (rising, up or sinking): PlayerContact with a box of `$20` lines by `$0C` units at its current row; a touch jumps to ShieldedKill.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 117,360 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$9C70` (`TrapList`) |

### `TrapTouch` (`$9C9B`)

**The contact test of a moving trap**

Data in the mechanical cut (the traps POKE kept the counters from rising in every warp clone); exC's t1 ran it 294 times, 34 touches.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShieldedKill` (`$9CAA`)

**Kill the player unless he wears the exoskeleton**

In: the exoskeleton offset `$9ED8` (0, or `$0C` while it is worn: `$9F5D` toggles it, it shifts the player's frames by 12). Worn: return. Else into KillPlayer. Callers: Mines (MineFires), TrapContact. The ZXDB mines POKE (40110) is the RET NZ at `$9CAE` turned into RET: mines and traps never kill. w030 ran it once, t1 34 times.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 43 calls (`w/050` 4, `w/033` 3, `w/034` 3 and 21 more) |

### `KillPlayer` (`$9CAF`)

**Start the player's death**

Nothing while the death runs (DeathTimer) or while the guard `$768D` counts down (the main loop takes one off a pass, `$767A`). The ZXDB immunity POKE (40120) is the RET NZ at `$9CB8` turned into RET: no death at all.

Else: the screen time `$AC7B` cleared, `$82F7` (the jump state) and the fire-hold count `$83DC` cleared, DeathTimer 46, the guard 66 (46 + 20: the player cannot die again for 20 passes after he reappears), the player drawn with frame `$0B` at his place, Y rounded down to 4 lines (`$8224`). AF, DE kept.

c1: 59 calls, 31 deaths (x1, m1 and h1: 9 each, their nine lives).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 59 calls, 8,894 t-states own (0.00 %) |
| Called from | `ShellsHitPlayer` (tail) |
| Calls | `PlayerFrame` |
| Reads | `$768D` (`ImmunityCount`); `$82F5`-`$82F6` (`PlayerX`, `PlayerY`); `$9CE2` (`DeathTimer`) |
| Writes | `$768D` (`ImmunityCount`); `$82F7` (`JumpStep`); `$83DC` (`FireHeld`); `$9CE2` (`DeathTimer`); `$AC7B`-`$AC7C` (`IdleTime`) |

### `PlayerDeath` (`$9CE3`)

**One pass of the player's death: the leap, then a life lost and the restart**

Main loop, every pass (c1: 3263; 1426 death passes). DeathTimer t counted down. While t > 0: the vertical step DeathLeap[t] (HL = `$9D49` + t): a step of `$0A` or more (negative: up) moves him; a step below `$0A` (0 or down) moves him only when the floor test `$814E` finds nothing under him. Frame `$0B` at the new place (`$8224`).

At t = 0: the player's frames turned back to face right (`$7BDA` set: `$7BAA` mirrors them), the facing `$82FA` = 1, lives - 1 (`$8E7A`; the DEC A at `$9D1D` is ZXDB's lives POKE 40221), ammunition 99, grenades 10, the three printed (`$8E4F`, `$8E5B`, `$8E67`); no lives left: GAME OVER (`$A02A`). Else the player is put at the restart position `$82F3` / `$82F4` with frame 5, dropped to the floor first if there is none under it (DeathDropToFloor).

x1: 9 deaths, the ninth to GAME OVER.

[Animation: `PlayerDeath` at work](img/routines/PlayerDeath.gif)

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 288,695 t-states own (0.01 %) |
| Called from | `StartGame` |
| Calls | `FlipPlayerFrames`, `TestBelow`, `PlayerFrame` (tail), `PrintAmmo`, `PrintGrenades`, `PrintLives`, `GameOver` (tail) |
| Reads | `$7BDA` (`PlayerFlipped`); `$82F3`-`$82F6` (`RestartX`, `RestartY`, `PlayerX`, `PlayerY`); `$8E7A` (`Lives`); `$9CE2` (`DeathTimer`); `$9D4B`-`$9D77` (`DeathLeap+1`) |
| Writes | `$82FA` (`Facing`); `$8E5A`-`$8E66` (`Ammo`, `PrintGrenades`, `Grenades`); `$8E7A` (`Lives`); `$9CE2` (`DeathTimer`) |

### `DeathDropToFloor` (`$9D47`)

**No floor under the restart position: one line down and test again**

INC D, JR DeathRestartLoop. Data in the mechanical cut: the restart positions of every recording had a floor.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AbortIfDying` (`$9D78`)

**Return from the caller while the player dies**

DeathTimer not 0: POP the return address, so the RET returns from the caller. Called first by the movement `$81A4`, the fire `$8338`, ThrowGrenade and `$A553`. c1: 13 046 calls, 5642 of them during a death.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 13,046 calls, 444,276 t-states own (0.02 %) |
| Called from | `MovePlayer`, `FireControl`, `ThrowGrenade`, `AlienSpawn` |
| Reads | `$9CE2` (`DeathTimer`) |

## guns

`src/game/guns.asm`

### `Guns` (`$9D7F`)

**The gun emplacements fire at a player far enough to their left**

Main loop, every pass. For each gun of GunList, a random byte of `$F7` or more (9 in 256 a pass) is a shot, when the player's X is below the gun's (4 column - 2) - `$1E` (more than 60 pixels to its left; a player not left of it ends the routine for the rest of the guns this pass). The shot takes a free record of GunShots (X = 4 column - 2, Y = 8 row, dx = -2), drawn (frame 8) with the sound `$C13B`. No free record: the routine ends.

The guns are the scenery's cannons (w030's screen 30: the green cannon on its pedestal firing left). w clones: 426 shots on 46 screens.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 117,360 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$9DC1` (`GunList`) |

### `GunShotsFull` (`$9DA6`)

**No free shot record: POP HL, RET (the rest of the guns wait)**

Data in the mechanical cut: no recording filled the 10 shot records.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GunShotSlot` (`$9DA8`)

**The shot record search goes on; a free one gets the shot**

The next record (3 bytes; dx 0: free) back to GunFindShotLoop; a free one: dx -2, Y, X written, frame 8 drawn, the gun's sound `$C13B`, and Guns goes on with the next gun.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MoveGunShots` (`$9DD6`)

**Move every gun shot two units left**

Main loop, every pass (c1: 3260, empty). For each shot (dx not 0): frame 8 erased; at X 0 the record freed (dx 0); else X + dx, drawn, painted bright white (`$47`).

w clones: 16 331 steps, 224 shots off the left edge.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,464,560 t-states own (0.12 %) |
| Called from | `StartGame` |
| Reads | `$9E18`-`$9E36` (`GunShots`) |

### `ClearGunShots` (`$9E0A`)

**Clear the gun shot list (30 bytes)**

Called by the screen builder `$8494`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 2,616 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$9E18`-`$9E34` (`GunShots`) |
| Writes | `$9E18`-`$9E35` (`GunShots`) |

### `GunShotsVsShots` (`$9E37`)

**Tests every gun shot against the player's shots; a hit gun shot is destroyed**

Called by the shot step `$83DD` each pass (c1: 16 303 entries, five a main loop pass with its four other calls). Walks the shell list `$9E18` (3 bytes a shell: X, Y, the step; `$FF` ends; a step of 0 is a free record), skips the free ones, and asks `$9B82` whether one of the player's shots (`$845F`) overlaps the shell (A not 0: hit, the shot removed); then DestroyGunShot. Ends when E (the X byte) has bit 7 set, the list's `$FF`.

The shells are launched by the guns of tile 11 (`$9D7F`) and moved left by `$9DD6` (not in this range). Warp runs: DestroyGunShot 174 times in 27 runs, none in c1 (the random play never shot one).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 11,672,948 t-states own (0.58 %) |
| Called from | `MoveShots` |
| Reads | `$9E18`-`$9E36` (`GunShots`) |

### `DestroyGunShot` (`$9E4F`)

**Removes the gun shot at DE: XOR-erased, its record freed, an explosion there, sound 8, 50 points**

In: DE = the shell's X, Y; HL = the record's next byte (the shell's step + 1). XorSprite `$92FB` draws sprite 8 (the shell) over itself, the step byte goes to 0, `$981D` starts an explosion at DE, `$C155` asks the AY for effect 8, and AddScore adds Points50 (50). Callers: GunShotsVsShots, GunShotsVsPlayer: a gun shot that hits the player pays 50 too (w/006 frame 243 to 244).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 174 calls (`w/048` 19, `w/123` 15, `w/122` 14 and 24 more) |

### `GunShotsVsPlayer` (`$9E64`)

**Tests every gun shot against the player: a gun shot that touches him is destroyed and kills him**

Main loop (c1: 3260 entries, one a pass). The same walk as GunShotsVsShots; `$9BD6` with B = 8, C = 4 (the shell's size) answers 1 when the shell overlaps the player (`$82F5`, `$82F6`). Then DestroyGunShot, sound 8 again and KillPlayer `$9CAF` (which does nothing while the player is dying or immune: `$9CE2`, `$768D`).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,334,160 t-states own (0.12 %) |
| Called from | `StartGame` |
| Reads | `$9E18`-`$9E36` (`GunShots`) |

## passtime

`src/game/passtime.asm`

### `PadXorSprites` (`$9E85`)

**Burns the time of the XOR sprite draws this pass did not make, up to 16**

Main loop, at its end (`$766E`). XorSprite `$92FB` counts every draw in XorSpriteCount (+1 at `$9359`); the main loop zeroes the count at its start (`$75BF`). With fewer than 16 draws this pass, the rest are made with sprite 6 at whatever DE holds, so a pass takes about the same time whatever is on the screen (the game paces itself by the work, not by the frame). c1: 3260 entries, one a pass. Whether sprite 6 is blank was not checked; the screens show no trace of it.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 1,747,360 t-states own (0.09 %) |
| Called from | `StartGame` |
| Calls | `DrawSmallSprite` |
| Reads | `$9E98` (`XorSpriteCount`) |

### `PadSlotSprites` (`$9E99`)

**The same pad for the slot sprites of `$795C`: up to 6 draws of an empty frame**

Main loop (`$7671`), after PadXorSprites. SlotSpriteCount is zeroed at `$75C2` and never raised anywhere in the image (no other reference to `$9EAE`), so this always draws 6 times: frame 0 (empty) into the slot `$B101` with B = 6..1 as its Y. A pad whose counter was left out in this release (or never needed): its cost is constant.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 792,132 t-states own (0.04 %) |
| Called from | `StartGame` |
| Calls | `DrawSprite` |
| Reads | `$9EAE` (`SlotSpriteCount`) |

### `AddBonusTicks` (`$9EAF`)

**Adds A ticks of 25 points to the pending bonus and asks for AY effect 5**

In: A = the ticks. BonusTicks += A; `$C12E` asks the AY for effect 5. PayBonusTick then pays one tick a pass. Callers: HomingMissileStep (34 ticks, 850 points, a launcher destroyed), PickupsVsPlayer (40 ticks, 1000 points), the force field's end `$AC54` (40). Warp runs: 79 entries in 33 runs.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 82 calls (`w/045` 4, `w/080` 4, `w/120` 4 and 31 more) |

### `PayBonusTick` (`$9EC1`)

**One pending bonus tick a pass: 25 points and a click**

Main loop (`$7629`). While BonusTicks is not 0: BonusTicks - 1, AddScore Points25, Click `$7C26` with B = `$28` (the beeper only; it returns at once on a 128K). So a bonus counts up on the score 25 points a pass with a rattle, instead of at once.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 114,100 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$9ED6`-`$9ED7` (`BonusTicks`) |

### `StartSparkle` (`$9ED9`)

**Puts a sparkle of 20 passes at DE into the first free record of SparkleList**

In: DE = X, Y (pixels). Called twice by the teleport `$98BA`: one sparkle at the pad left, one at the pad reached. Full list: nothing. x2: 2 entries, warps: 72 in 30 runs.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 76 calls (`w/036` 4, `w/037` 4, `w/056` 4 and 29 more) |

### `RunSparkles` (`$9EEE`)

**Each pass, one explosion at a random point of each live sparkle's 4 x 16 box**

Main loop (`$762C`). For each record with passes left: passes - 1, then an explosion (`$981D`, the small explosion list) at X + (Random AND 3), Y + (Random AND 15). So a teleport shows a column of small explosions over the booth for 20 passes.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 1,004,080 t-states own (0.05 %) |
| Called from | `StartGame` |
| Reads | `$9F13`-`$9F1F` (`SparkleList`) |

### `ClearSparkles` (`$9F20`)

**Frees the 4 sparkle records (12 zeros), at every screen set-up**

Called by the screen set-up `$8494` (c1: 4 entries, the 4 games' first screens; warps: 223).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,092 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$9F13`-`$9F1D` (`SparkleList`) |
| Writes | `$9F13`-`$9F1E` (`SparkleList`) |

### `ExoSuitBooth` (`$9F2D`)

**The exoskeleton booth: up pressed while standing in it puts the suit on or takes it off**

Main loop (`$7635`). UP (`$7B94`) is taken on its edge: BoothUpLatch holds 1 while it stays pressed. The booth is the screen's tile 12, whose cell ExoBoothList holds (the screen builder's object table `$8EF4`: tile 12, 2 bytes, the cell kind 1 left in the map). The player must stand on the cell's row + 1 in pixel units (Y = 8 (row + 1)) with X - 4 col in [-12, +8]. Then ExoSuit XOR `$0C`, AY effect 2 (`$C0F4`), and `$8224` with A = 5 redraws the player in his new frames.

The same shape as the teleport `$98BA` (two booths of tile 6), which this agent leaves to its range. c1: 3260 entries, no toggle; of all the recordings only the warp run w/108 toggled the suit (`$9F59-$9F6C` executed).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 156,290 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$7B94` (`ControlJump`); `$9F6D`-`$9F6F` (`BoothUpLatch`, `ExoBoothList`) |
| Writes | `$9F6D` (`BoothUpLatch`) |

## blasts

`src/game/blasts.asm`

### `ShotHitsAlien` (`$9F71`)

**A = 1 when one of the player's shots overlaps the alien at DE (the shot is removed), else 0**

In: DE = the alien's X, Y. Walks the shot list `$845F` (X, Y, live; `$FF` ends): a live shot with shot X - (X + 2) in [-8, -1] and shot Y - Y - `$11` in [-18, -1] hits; `$82FC` removes the shot's image and its live byte goes to 0. BC, DE, HL kept. Caller: AliensVsShots (x2: 49 331 entries).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 443,481 calls (`x2` 49,331, `w/119` 14,876, `w/055` 14,465 and 77 more) |

### `StartBlast` (`$9FA3`)

**Starts a blast (the large explosion of 11 passes) at DE in the first free BlastList record**

In: DE = X, Y. AF and HL kept. Full list: nothing. Callers: HomingMissileStep, KillAlien, IdleMissileStep (its end). c128: 5, x2: 498, warps: 1331 entries.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 1,842 calls (`x2` 498, `w/026` 40, `w/042` 32 and 83 more) |

### `RunBlasts` (`$9FBD`)

**Draws each live blast in its sprite slot: the frame by the passes left, a random colour and a crackle**

Main loop (`$7632`). Blast n uses the sprite slot `$B401` + `$30` n (5 slots). Frame = BlastFrames[passes left] (5 5 6 6 7 7 8 8 9 9 then 0, the empty frame that clears the slot), ink `$42-$45` bright on black at random (`$7C8F`), then Click `$7C26` for 1-32 rounds (the beeper). Passes left - 1 each pass.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,412,400 t-states own (0.12 %) |
| Called from | `StartGame` |
| Reads | `$A00C`-`$A01B` (`BlastList`) |

### `ClearBlasts` (`$A01C`)

**Frees the 5 blast records (15 zeros), at every screen set-up**

Called by the screen set-up `$8494` (c1: 4, warps: 223).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,356 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$A00C`-`$A019` (`BlastList`) |
| Writes | `$A00C`-`$A01A` (`BlastList`) |

## gameover

`src/game/gameover.asm`

### `GameOver` (`$A02A`)

**GAME OVER: the text and tune, a pause, the Hall of Fame test, then a key or a timeout restarts**

Reached by the JP Z at `$9D38` when the last life is lost. Prints GameOverText (a bright yellow-on-red band, attribute `$56`, rows 9-11, columns 10-20), plays the tune `$7D68` through `$7D17`, waits two DelayBC of 65 536 rounds (the delay copies BC bytes from `$0000` to `$0000`: 65 536 x 21 T = 1 376 256 T, about 20 frames or 0.4 s each), then HallOfFameInsert: a score that enters the table asks for the name, and that path never comes back (it jumps to the entry). Else WaitNoKey, and up to 20 000 rounds of ReadKey: any key, or the count's end, jumps to the entry `$6D60` (the menu). c1: 3 game overs, c128: 1, x1, m1, h1: 1 each.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3 calls, 87,900 t-states own (0.00 %) |
| Called from | `PlayerDeath` (tail) |
| Calls | `Start` (tail), `PlayTune`, `HallOfFameInsert`, `ReadKey`, `WaitNoKey`, `PrintString`, `Delay` |

### `HallOfFameInsert` (`$A073`)

**Finds the place of the score in the 50-entry Hall of Fame; when it enters, makes room and asks for the name**

The table `$71F1`: 50 entries of 16 bytes (the name in 10, of which the entry writes 8; the score in 6 ASCII digits at +10), `$FF` at `$7511`. From the top entry: the score `$AD8A` is compared digit by digit with the entry's (HofDigitLoop); a smaller entry digit means the score is higher: HofMakeRoom; a larger one, the next entry (HofNextEntry); six equal digits also go on (an equal score goes under). The end of the table: RET (the score does not enter).

c1 (3 game overs, scores below 1000): 153 entries of HofEntryLoop = 3 x 51 (50 entries and the end). h1 (the score set to 9000): the first entry (RAFFAELE 001000) is lower: the name entry ran.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3 calls, 72 t-states own (0.00 %) |
| Called from | `GameOver` |
| Calls | `HofEntryLoop` |

### `HofEntryLoop` (`$A07A`)

**One Hall of Fame entry: IX = the entry, kept on the stack; bit 7 of its first byte: the end**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 153 calls, 12,623 t-states own (0.00 %) |
| Called from | `HallOfFameInsert`, `HofNextEntry` (tail) |
| Calls | `HofDigitLoop` |
| Reads | `$71F1`-`$7511` (`HallOfFame`) |

### `HofDigitLoop` (`$A08B`)

**Compares one score digit with the entry's: equal goes on, the entry's higher goes to the next entry**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 450 calls, 17,994 t-states own (0.00 %) |
| Called from | `HofEntryLoop`, `HofNextDigit` (tail) |
| Calls | `HofNextDigit` (tail), `HofNextEntry` (tail) |
| Reads | `$71FB`-`$750D` (`HallOfFame+10`); `$AD8A`-`$AD8C` (`Score`) |

### `HofMakeRoom` (`$A095`)

**POP HL: moves the entries down by 16 from this one, writes the score, asks for the name**

Ran only in h1 and exD's d1 (neither is a case.json build: h1 is left out for its NOP patch, WALKTHROUGH 4), so it is code from this c entry's walk; the CAPS delete `$A102-$A121` ran in no recording but d1 (no case.json run pressed CAPS). The score is higher than this entry (HL = the entry, from the stack): CPIR for the `$FF` (`$7511`) gives the bytes from the entry to the end; LDDR from `$7510` to `$7520` moves them down 16 (the last entry falls to `$7511-$7520`, past the end; the byte before the entry goes to its +15, then overwritten by the score), `$FF` goes back to `$7511`. The score's 6 digits go to the entry's +10. Then the name entry: ClearScreen `$B04B`, NameBuffer filled with 8 spaces, HofEntryText printed, the cursor "?" at row 15 column 12.

The name entry (HofNameKey): WaitNoKey, ReadKey until a key; SYMBOL SHIFT (2) is ignored; ENTER (13) ends; CAPS SHIFT (1) deletes (HofDelete); any other key's character is stored at the cursor and printed in bright yellow (`$46`), then the cursor moves on (8 places, columns 12-19; at column 19 it stays and the next key overwrites). A delete at column 19 over a character blanks it in place; elsewhere it prints "-" (`$47`, the field's dash) at the cursor, steps back and blanks the character there; at column 12 it does nothing. ENTER copies the 8 bytes of NameBuffer to the entry's name, sets HallOfFameFirst `$71F0` to 1, WaitNoKey, JP `$6D60`: the entry sees the flag and shows the Hall of Fame (`$7145`).

Evidence: h1 (E X O L O N, ENTER: the top entry EXOLON 009000). exD's d1 (work/ann/exD/d1, from entry-score.z80): E X, CAPS, O L O N A B C, CAPS, D, ENTER: every branch of the delete ran (`$A102-$A121`), and the table's top entry became EOLONABD 009000 (the X deleted, the C at the last place blanked and overwritten by D). The run's last RAM (frame 8500): `$71F1` = "EOLONABD  009000", NameBuffer = "EOLONABD".

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HofNextDigit` (`$A145`)

**The next digit of the score and of the entry; after six equal digits, the next entry**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 300 calls, 9,000 t-states own (0.00 %) |
| Called from | `HofDigitLoop` (tail) |
| Calls | `HofDigitLoop` (tail) |

### `HofNextEntry` (`$A14C`)

**The next entry (IX + 16 from the stack)**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 150 calls, 7,350 t-states own (0.00 %) |
| Called from | `HofDigitLoop` (tail) |
| Calls | `HofEntryLoop` (tail) |

## aliens

`src/game/aliens.asm`

### `HomingMissileStart` (`$A23A`)

**Launches a homing missile from the right edge at a random height, while the screen's launcher stands**

Called by the screen set-up `$8494` and by HomingMissileStep when no missile flies. Clears MissileLive; nothing when the screen has no launcher (MissileLauncher's `$FF`) or the player is dying (`$9CE2`). The launcher is tile 13: its cell in the map `$6100` still holds kind `$0D` (the screen builder left it so; a grenade that destroys it changes it). Then MissileLive = `$0D` and the missile at X = `$78` (the right edge), Y = `$20` + (Random AND `$7F`).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,264 calls, 182,784 t-states own (0.01 %) |
| Called from | `BuildScreen`, `HomingMissileStep` (tail) |
| Reads | `$A266`-`$A267` (`MissileLauncher`) |
| Writes | `$A26A` (`MissileLive`) |

### `HomingMissileStep` (`$A26B`)

**Moves the homing missile: left, faster on the left part, one step toward the player's height a pass**

Main loop (`$7638`; c1: 3260). No missile: HomingMissileStart. The launcher gone (kind not `$0D`): 34 bonus ticks (850 points: the launcher's destruction pays while the missile is in the air), a blast at the missile, the missile removed. Else X - 1 (frame `$0A`); from X < `$46` on, X - 2 (frame `$0B`); off the left edge (X = `$FF`): removed. Y moves 1 toward the player's Y (`$82F6`). Touching the player (`$9BD6`, B = `$10`, C = 8): KillPlayer, a blast, removed. Drawn in the slot `$B4F1` in white (`$47`).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 88,020 t-states own (0.00 %) |
| Called from | `StartGame` |
| Calls | `HomingMissileStart` (tail) |
| Reads | `$A26A` (`MissileLive`) |

### `DrawStars` (`$A2D5`)

**The star field: 3 tries a row on rows 0-21, a star (character 3 of font `$E840`) where the cell is empty**

Called by the screen set-up `$8494`. For rows 21 down to 0, three random columns (Random AND `$1F`): when the map `$5E00` holds 0 there (no scenery), PrintCharAttr `$AE26` draws glyph 3 of TileSetE840 (one pixel, line 4) in a random bright ink `$42`, `$43`, `$46` or `$47` (Random AND 7 OR `$42`). So up to 66 stars, new each time a screen is built.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 48,864 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Calls | `CellOffset`, `Random`, `PrintCharAttr` |
| Reads | `$5E02`-`$6075` (system); `$6089`-`$60BE` (system) |
| Writes | `$ADEF`-`$ADF0` (`PrintChar+14`) |

### `PickupsVsPlayer` (`$A30B`)

**The bonus pick-ups of tile 14: the player touching one collects it for 1000 points**

Main loop (`$763B`). Each live record of PickupList (column, row, live): the pixel box of the cell (`$9936`) against the player (`$9BD6`, B = 8, C = 4); on a touch the record dies, AY effect 5, and 40 bonus ticks (1000 points). The pick-up's picture is the screen's own tile; this code does not erase it (open question in exD.md).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 117,360 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$A333` (`PickupList`) |

### `ClearPickups` (`$A352`)

**Sets the first 12 bytes of PickupList to 1 (four records live by default), at every screen set-up**

The builder then overwrites the column and row of the records it fills and puts `$FF` after the last; records past the screen's pick-ups are cut off by that `$FF`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,104 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$A333`-`$A33D` (`PickupList`) |
| Writes | `$A333`-`$A33E` (`PickupList`) |

### `AliensStep` (`$A360`)

**Moves each live alien along its path and draws it**

Main loop (`$763E`; c1: 3260, AliensStepLoop 22 820). Alien n uses the slot `$B521` + `$30` n (6 aliens). A record of AlienList: +0 X, +1 Y, +2 live, +3/+4 the path's start, +5/+6 the path pointer, +7 the hold count, +8 the animation counter, +9 the colour. The path (AlienPaths): a pair dX, dY (signed) moves one pass; `$C4` n then a pair holds that move n passes; `$C3` starts the path again. Off the playfield (X >= `$80` or Y >= `$B0`): the alien dies and its slot is cleared. Frame = AlienFrame (patched per screen) + (animation AND 3), ink +9 (`$7C8F`).

[Animation: `AliensStep` at work](img/routines/AliensStep.gif)

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 78,240 t-states own (0.00 %) |
| Called from | `StartGame` |
| Calls | `AliensStepLoop` |

### `AliensStepLoop` (`$A367`)

**AliensStepLoop**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 22,820 calls, 1,473,520 t-states own (0.07 %) |
| Called from | `AliensStep`, `AliensNext` (tail) |
| Calls | `AliensNext` (tail) |
| Reads | `$A508`-`$A544` (`AlienList`) |

### `AliensNext` (`$A3F9`)

**AliensNext**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 19,560 calls, 1,290,960 t-states own (0.06 %) |
| Called from | `AliensStepLoop` (tail) |
| Calls | `AliensStepLoop` (tail) |

### `ClearAliens` (`$A545`)

**Frees the 6 alien records (60 zeros), at every screen set-up**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 5,136 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$A508`-`$A542` (`AlienList`) |
| Writes | `$A508`-`$A543` (`AlienList`) |

### `AlienSpawn` (`$A553`)

**Starts an alien from the right edge now and then, on the screens of AlienScreens**

Main loop (`$762F`). `$9D78` returns from here too while the player is dying. Nothing on a screen without aliens (AliensHere 0), during AlienSpawnDelay, or when the player is at X >= `$54` (the right part). A free record, then Random >= `$C8` (56 in 256 passes): the alien at X = `$78`, Y = the player's Y - 10 (Random >= `$AF`) or + 0..15, live, the path AlienPathStart (patched), hold 0, animation 3, the colour `$40` + (Random AND 7) (1 becomes 5, 0 becomes 4: never black or blue), and the delay AlienSpawnDelay = the screen's delay.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 107,640 t-states own (0.01 %) |
| Called from | `StartGame` |
| Calls | `AbortIfDying` |
| Reads | `$A676` (`AliensHere`) |

### `AliensVsShots` (`$A5CA`)

**The player's shots against each live alien: a hit kills it (150 points)**

Called by the shot step `$83DD`. ShotHitsAlien for each, KillAlien on a hit. x2: 205 kills, warps: 1185 in 78 runs; none in c1.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 14,607,488 t-states own (0.73 %) |
| Called from | `MoveShots` |
| Reads | `$A508`-`$A544` (`AlienList`) |

### `AliensVsPlayer` (`$A5F4`)

**Each live alien against the player: a touch kills both**

Main loop (`$765C`). The box from X + 2, Y + 4 (B = 8, C = 4); then KillAlien and KillPlayer `$9CAF`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,920,960 t-states own (0.15 %) |
| Called from | `StartGame` |
| Reads | `$A508`-`$A544` (`AlienList`) |

### `KillAlien` (`$A62D`)

**Kills the alien of record HL (slot IY): dead, the slot cleared, a blast, AY effect 8, 150 points**

In: HL = the record, IY = its slot. BC = X, Y for the blast.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 1,398 calls (`x2` 205, `w/026` 40, `w/114` 32 and 77 more) |

### `AliensSetUp` (`$A645`)

**Looks the screen up in AlienScreens: sets AliensHere and patches the path, the frame and the delay**

Called by the screen set-up `$8494`. A screen not in the table: AliensHere = 0 and no alien starts (the old patches stay, unused).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 20,436 t-states own (0.00 %) |
| Called from | `BuildScreen` |
| Reads | `$8523` (`ScreenNumber`); `$A677`-`$A7D5` (`AlienScreens`) |
| Writes | `$A676` (`AliensHere`) |

### `FlickerPadStep` (`$A7D6`)

**The flickering pad of tile 15: two sprites side by side, random frames `$1C-$1F` and random colours**

Main loop (`$7641`). When the screen has one (FlickerPadList), draws frame `$1C` + (Random AND 3) in the slot `$B641` at the cell's pixels and the next frame in the slot `$B671` 16 pixels right, in a random bright ink `$40-$47` (`$7C8F` both). Nothing else reads its cell: a decoration that is redrawn every pass (what it shows is an open question; exD.md).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 117,360 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$A814` (`FlickerPadList`) |

## zoneend

`src/game/zoneend.asm`

### `ZoneEnd` (`$A817`)

**The zone's end: the player at the end marker gets the lives and bravery bonuses, then the bonus screen**

Main loop (`$7644`). ZoneEndList holds the marker (tile 16) of the screens 24, 49, 74, 99 and 124 (the last of each zone of 25). When the player's X reaches the marker's (column x 4): ZoneBonusText (the panel BRAVERY BONUS 00000 / LIVES BONUS X 1000), the lives digit at row 12 column 13, the lives x 1000 points; when ExoSuit is 0 (the zone done without the exoskeleton), "1" at row 8 column 14 makes the bravery figure 10000 and 80 x 125 points are added with a click each (the count runs up on the HUD). Then RoundEnd.

Warp runs: 9 runs (the starts 24, 49, 74, 99, 124 and the runs that walked into them) reached BonusScreen.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 127,140 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$AAEF`-`$AAF0` (`ZoneEndList`) |

### `ZoneAddLife` (`$A8A1`)

**One life more at a zone's end, when below nine (never ran)**

The fall-through of the JP NC at `$A89F`: one more life when below nine. No recording ran it: the warp runs that reached a zone's end all had the lives POKE (nine lives).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ZoneRefill` (`$A8A5`)

**The next zone: the suit off, 99 ammunition, 10 grenades, the next screen built, the HUD, the player at the zone's start**

ExoSuit = 0, `$8E5A` = 99, `$8E66` = 10; `$8253` with A = `$88` (the player's Y `$88` for now, the screen number + 1: 25, 50, 75, 100, or 0 after RoundEnd's `$FF`), `$8485` builds it, `$7690` the HUD; `$82F7` = 0; ZoneStarts gives the start X, Y of the new screen into `$82F5` (the player) and `$82F3` (the restart point).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BonusScreen` (`$A8DB`)

**The bonus screen: a "*" steps down eight lines until fire; the odd lines pay 1000, 3000, 5000, 7000**

Six DelayBC of 65 536 (about 2.4 s; the zone's panel stays up 133 frames in w/124, from RoundEnd to BonusScreen), ClearScreen, BonusScreenText, WaitNoKey, a delay; then each round BonusPointer + 1, "*" (`$2A`, white) at row 13 + (BonusPointer AND 7), column 22, a space over the line before, ReadControls `$7B72`, DelayBC 6000; fire (`$7B96`) stops it. BonusPointer AND 7 odd: that many x 1000 points (the lines read 00000, 01000, 00000, 03000, ...: the odd ones are what they say). BonusPointer is never reset: the pointer goes on from where it stopped. 9 warp runs.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 9 calls (`w/023` 1, `w/049` 1, `w/074` 1 and 6 more) |

### `DeadNextLineCall` (`$AB94`)

**CALL NextPixelLine `$B099` that no jump or call reaches (never ran)**

Never ran in any recording, and cannot: a CALL of NextPixelLine `$B099` between ZoneBonusText's `$FF` and ForceFieldDraw; nothing in the image jumps to `$AB94`. A leftover.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## forcefield

`src/game/forcefield.asm`

### `ForceFieldDraw` (`$AB97`)

**Draws the screen's force field (tile 17): character `$25` down from under its cell to the first solid cell**

Jumped to at the end of the screen set-up (`$8520`). Font `$DAB8`; PrintChar's `$5B00` mark 0 and its `$6100` kind 1 (the cells become solid for the player); the column from row + 1 down while the map `$6100` is 0; ForceFieldHeight = the cells drawn; ForceFieldHits = 0.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 156 t-states own (0.00 %) |
| Called from | `BuildScreen` (tail) |
| Reads | `$ABCC`-`$ABCD` (`ForceFieldList`) |

### `ForceFieldStep` (`$ABCF`)

**The force field: a buzz, its column's colour cycling, and death for a player who walks into it**

Main loop (`$7647`). Sounds `$C1A9` (AY effects 1 and `$0B`), ink = `$768C` AND 7 bright on every cell of the column. The player at X + `$0C` = the field's X (column x 4): KillPlayer.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 127,140 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$ABCC`-`$ABCD` (`ForceFieldList`) |

### `ForceFieldVsShots` (`$AC04`)

**Counts the player's shots that reach the force field; the 25th destroys it**

Called by the shot step `$83DD`. A live shot of `$845F` whose X equals the field's (column - 1) x 4 counts once a pass in ForceFieldHits; from 25 on: ForceFieldDestroy. No recording got that far (the counter is reset with each screen).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 635,817 t-states own (0.03 %) |
| Called from | `MoveShots` |
| Reads | `$ABCC`-`$ABCD` (`ForceFieldList`) |

### `ForceFieldDestroy` (`$AC2B`)

**The force field's 25th hit: erased cell by cell, removed, AY effect 6, 1000 points**

Font `$DAB8`; for the ForceFieldHeight cells from under the field's cell, EraseBlockDebris `$AE95` draws character `$25` again in a random bright ink `$42`, `$43`, `$46` or `$47` (XOR: the field disappears, its cells' marks cleared and their kinds 0); ForceFieldList = `$FF`; AY effect 6 (`$C148`); JP AddBonusTicks with A = `$28` (40 ticks, 1000 points). Never ran in any recording: no run put 25 shots into one force field (ForceFieldHits is reset with each screen).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `IdleMissileStart` (`$AC59`)

**A player who stays 700 passes on one screen gets a missile from the right at his height**

Main loop (`$764A`). IdleTime (+1 each pass at `$7682`, 0 at a new screen `$8497`, a death `$9CAF` and `$9CBE`) reaching `$2BC` (700 passes, about 28 s at 2 frames a pass): the missile at X = `$78` and the player's Y. The time is not reset by the missile: one follows the other while he stays.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 254,280 t-states own (0.01 %) |
| Called from | `StartGame` |
| Reads | `$AC78`-`$AC7C` (`IdleMissileLive`, `IdleMissilePosition`, `IdleTime`) |

### `IdleMissileStep` (`$AC7D`)

**Moves the idle missile 2 left a pass, with smoke now and then, and kills the player it touches**

Main loop (`$764D`). At X = 0: the end. X < `$6F`: half the passes (`$AD36` >= `$80`) a small explosion behind it (X + 6, Y + 4). X - 2; frame `$24` in the slot `$B6A1`, white. A touch (`$9BD6`, B = `$10`, C = 8): KillPlayer. The end: the slot cleared, IdleMissileLive 0, a blast.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 91,280 t-states own (0.00 %) |
| Called from | `StartGame` |
| Reads | `$AC78` (`IdleMissileLive`) |

## utils

`src/game/utils.asm`

### `ReadKey` (`$ACD1`)

**The first key down on the keyboard, as KeyTable gives it (ASCII; 1 CAPS SHIFT, 2 SYMBOL SHIFT, 13 ENTER), 0 for none**

The rows `$FEFE` to `$7FFE` in turn, bits 0-4 of each; the first 0 bit gives KeyTable's byte. BC and HL kept; D and E changed. Callers: the menu (`$6DE0`), the define keys (`$6FE8`), the Hall of Fame display (`$717E`), GameOver, HofNameRead. The same scan is inlined in WaitKeyOrFire `$7CEC`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 22,019 calls, 40,177,227 t-states own (2.00 %) |
| Called from | `MainMenu`, `DefineKeys`, `GameOver` |
| Reads | `$ACF0`-`$AD17` (`KeyTable+1`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `WaitNoKey` (`$AD18`)

**Waits until no key of the keyboard is down**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 18 calls, 55,733,542 t-states own (2.77 %) |
| Called from | `DefineKeys`, `GameOver` |
| Ports in | `$00FE` |

### `PauseKey` (`$AD21`)

**Key 3 alone of the row 1-5 pauses the game until another key or fire**

Main loop (`$765F`). The row `$F7FE` AND `$1F` = `$1B`: only "3" down. Then PauseWait. c1 and the warps: 3260 / 61 667 passes, never "3" (the pause never ran in case.json's recordings). exD's d1 held "3" 20 frames in play, then P: PauseWait (`$AD2A-$AD35`) ran and WaitKeyOrFire `$7CEC` was entered once; the game went on after P.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 142,709 t-states own (0.01 %) |
| Called from | `StartGame` |
| Ports in | `$F7FE` |

### `PauseWait` (`$AD2A`)

**The pause: a short delay, wait for 3 up, then WaitKeyOrFire `$7CEC`**

A short delay, wait for "3" up, then WaitKeyOrFire returns (to the main loop) on any key or fire. Ran only in exD's d1 (not a case.json build): no case.json run pressed 3.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Random` (`$AD36`)

**A pseudo-random byte: Seed = 13 (Seed + 7), A = A XOR the seed's high byte**

The seed RandomSeed is a word; HL, DE, BC kept. The incoming A is XORed in (callers mostly then AND a mask). The game's one random source (c1: 20 875 calls).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 20,875 calls, 4,195,875 t-states own (0.21 %) |
| Called from | `MenuSparkles`, `AnimateFlames`, `AnimateTurrets`, `DrawStars` |
| Reads | `$AD51`-`$AD52` (`RandomSeed`) |
| Writes | `$AD51`-`$AD52` (`RandomSeed`) |

### `AddScore` (`$AD53`)

**Adds the 6 ASCII digits ending at DE to the score, then prints it on the HUD**

In: DE = the last digit of an addend of PointValues. The score's digits `$AD8A-$AD8F` from the last: digit + digit - "0" + carry, past "9" less 10 and a carry. A carry out of the sixth digit is lost (the score wraps at 1 000 000). Then PrintChar's `$5B00` mark 0 and ScoreText printed. All registers kept. Warps: 5614 entries.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 5,969 calls (`w/072` 223, `w/073` 222, `w/023` 216 and 87 more) |

### `BoxOverlap` (`$ADCD`)

**A = 1 when D - B and E - C are both in -6..+8, else 0: a box test nothing calls**

LD A,D / SUB B / SUB 9 / CP `$F1` / LD A,0 / RET C, the same for E and C, then INC A. Never ran in any recording: no CALL or JP in the image names `$ADCD` (dead code).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## text

`src/game/text.asm`

### `PrintChar` (`$ADE1`)

**Print one 8x8 glyph at a character cell, set its attribute and its three cell maps**

A the glyph code, D the row (0-23), E the column, C the attribute. Returns at once when bit 5 of E is set (a column 32-63 or a negative one from `$E0` up: the screen layouts place objects from off the left edge, ScreenLayouts). The glyph is 8 bytes at GlyphBase + 8A, where GlyphBase is the operand of the LD BC at `$ADEE` (PrintString code `$E6` and the callers write it: FontBase `$D7E0`, the tile sets from `$DAB8` on). The 8 bytes go down the cell's pixel lines (INC D), then C to the cell's attribute.

Then the cell's entries of two maps parallel to the attributes: attribute + `$0900` = the cell type map at `$6100` gets the operand at `$AE1B` (PrintString code `$E8` n; the screen builder sets 1 at `$84FA`, the score and text printers leave what was set), attribute + `$0900` + `$FA00` = the empty-cell map at `$5B00` gets the operand at `$AE21` (0 = a glyph is here, PrintString `$E9`; `$FF` = empty, `$EA`). The sprite drawers read `$5B00` (`$777F`, `$79DD`), the collision code `$6100` (`$80D3`).

Plot mode 0 of Printers `$9A0F` (set by SetPrinter `$99F8` into the four CALLs of PrintString). Called also directly: the define keys (`$6FE1`), the HUD (`$917C`, `$9181`), the name entry (`$A0E2`, `$A125`), the round end (`$A837`, `$A84F`), the bonus screen (`$A91A`, `$A92C`), `$ABB5`. c1: 158 963 calls from PrintString's `$AF32` alone.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4,053 calls, 2,598,177 t-states own (0.13 %) |
| Called from | `DefineKeys`, `PrintString` |
| Reads | `$D8E0`-`$D8E7` (`Font`); `$D950`-`$DAB7` (`Font+112`); `$DB38`-`$DB5F` (`TileGlyphs+128`); `$DBE8`-`$DE57` (`TileSetDBE8`, `TileSetDD38`, `TileSetDDD8`); `$DE68`-`$DE77` (`TileSetDDD8+144`); `$DED8`-`$E10F` (`TileSetDED8`, `TileSetDF78`, `TileSetE018`); 2 more ranges |
| Writes | `$4003`-`$5DFF` (screen); `$6103`-`$63FF` (system) |

### `PrintCharAttr` (`$AE26`)

**Print one glyph and its attribute, no clipping and no cell maps**

As PrintChar without the column test and the map writes: A the code, D the row, E the column, C the attribute, the glyph from GlyphBase (`$ADEF`). Plot mode 1 of Printers. Used for the HUD's numbers (PrintNumber3 `$B0E0`), `$7578`, `$8E49`, `$8E77`, the score glyphs `$8F7E`/`$8F83` (163 849 calls each in the runs), `$A300`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 13,392 calls, 7,710,927 t-states own (0.38 %) |
| Called from | `HudDigit`, `PrintLives` (tail), `AnimateFlames`, `DrawStars`, `PrintDigit` |
| Reads | `$ADEF`-`$ADF0` (`PrintChar+14`); `$D960`-`$D9AF` (`Font+128`); `$DB60`-`$DB8F` (`TileGlyphs+168`); `$E858`-`$E85F` (`TileSetE840+24`) |
| Writes | `$4002`-`$5A33` (screen); `$5AE1`-`$5AFE` (screen) |

### `XorCharAttr` (`$AE5D`)

**XOR one glyph onto a cell and set its attribute**

A the code, D the row, E the column, C the attribute, the glyph from GlyphBase. The glyph is XORed onto the screen (drawn twice it is gone). Plot mode 2 of Printers. Called from `$8FC0-$9009` (AnimateTurrets, 8 sites, 3580 and 14 208 calls each in the runs), with GlyphBase `$DDD8` set at `$8F95`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,000 calls, 1,267,913 t-states own (0.06 %) |
| Called from | `AnimateTurrets` |
| Reads | `$48D4`-`$48D5` (screen); `$49D4`-`$49D5` (screen); `$4AD4`-`$4AD5` (screen); `$4BD4`-`$4BD5` (screen); `$4CD4`-`$4CD5` (screen); `$4DD4`-`$4DD5` (screen); 4 more ranges |
| Writes | `$48D4`-`$48D5` (screen); `$49D4`-`$49D5` (screen); `$4AD4`-`$4AD5` (screen); `$4BD4`-`$4BD5` (screen); `$4CD4`-`$4CD5` (screen); `$4DD4`-`$4DD5` (screen); 3 more ranges |

### `EraseBlockDebris` (`$AE95`)

**XOR a glyph off a cell, mark the cell empty and throw two debris particles**

A the code, D the row, E the column (clipped as in PrintChar: bit 5 of E set returns). The glyph is XORed onto the screen, which takes off the same glyph drawn there before; the attribute is left. Then the cell's maps: `$5B00` = `$FF` (empty), `$5E00` (the attribute copy CopyAttributes `$8E11` made after the screen was built) = 0, `$6100` (the cell type) = 0: the cell is no longer solid. At the end two calls of `$94F9` (one CALL, one JP) with DE = the row and column: each starts a debris particle there (a 6-byte record of the list at `$95B6`, a random direction from `$AD36`, small sprite 2 of SmallSprites drawn by `$92FB`).

Plot mode 3 of Printers, reached only through PrintString's CALLs (`$AF32`: 2681 calls, `$AFFD`: 304, in the runs): the destructible scenery that a shot or a grenade breaks is erased by printing its object again in this mode. The caller selects it by SetPrinter `$99F8` with A = 3 (`$9418`, `$AC44` region).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 2,681 calls (`x2` 185, `w/000` 141, `w/124` 125 and 66 more) |

### `EraseBlock` (`$AEE4`)

**XOR a glyph off a cell and mark the cell empty, no clipping and no debris**

As EraseBlockDebris without the column test and without the particles: A the code, D the row, E the column; `$5B00` = `$FF`, `$5E00` = 0, `$6100` = 0 for the cell. Plot mode 4 of Printers, reached through PrintString's CALL at `$AF32` (368 calls in the warp runs).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 368 calls (`w/076` 16, `w/089` 16, `x2` 12 and 51 more) |

### `PrintString` (`$AF2B`)

**Print a string of glyph codes and control codes up to an end code**

HL the string, D the row, E the column, C the attribute. Each glyph is printed by the routine of the current plot mode (the CALLs at `$AF32`, `$AFBF`, `$AFD1`, `$AFFD`, written by SetPrinter `$99F8` from Printers `$9A0F`: PrintChar, PrintCharAttr, XorCharAttr, EraseBlockDebris, EraseBlock); the codes:

`$00-$60` a glyph, then the column + 1. `$61-$8F`: row += code - `$78` (-23..+23), then column += the next byte (a relative move). `$90-$CE`: the next row, column += code - `$AF` (-31..+31). `$CF-$DE`: the ink of C = code - `$CF`, 8-15 the bright inks 0-7 (C = C AND `$38` OR ink, BRIGHT for 8-15, FLASH dropped). `$DF` r c: row and column absolute. `$E0` a: the attribute. `$E1` n: repeat the bytes up to the next `$E2` n times (HL and BC pushed: the attribute comes back at every pass). `$E2`: the repeat's end. `$E3` lo hi: print the string at hi lo here, then go on with the row, column and attribute as before (a subroutine; the objects of ObjectTable `$852E` share parts so). `$E4` n g: glyph g n times to the right. `$E5` n g: glyph g n times down. `$E6` lo hi: GlyphBase = hi lo (the glyph set). `$E7`: a space of FontBase (the glyph set kept), column + 1. `$E8` n: the cell type the next glyphs write (`$AE1B`). `$E9`: the next glyphs mark their cells drawn (`$AE21` = 0). `$EA`: ... empty (`$AE21` = `$FF`). `$EB` n: the current cell's type = n (only in plot mode 0). Any other code (`$EC-$FF`; the strings end with `$FF`) returns, HL past it.

Callers: the menu (`$6DB2`, `$6E06`), the define keys (`$6FC3`), `$7023`, the Hall of Fame (`$7151`), `$7693`, the screen builder (`$8502`: every object of a screen, 2547 calls), `$91E6`, `$941D`, `$996C`, `$99C2`, the Hall of Fame entry (`$A02D`, `$A0D5`), the round end (`$A829`, `$A87D`), the bonus screen (`$A8FC`), the HUD score (`$AD7A`: 5969 calls).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 134 calls, 634,077 t-states own (0.03 %) |
| Called from | `MainMenu`, `DefineKeys`, `DrawHud`, `BuildScreen`, `GameOver` |
| Calls | `PrintChar` |
| Reads | `$6E17`-`$6EA8` (`MenuText`); `$705B`-`$7144` (`KeyNames`, `TypedKeys`, `CheatWord`, `DefineKeysText` and 2 more); `$76A2`-`$76D9` (`HudText`); `$85E0`-`$87D4` (`ElementLandingCraft`, `ElementPlanetRed4`, `ElementPlanetMagenta2`, `ElementGunTurret` and 9 more); `$8A07`-`$8A6C` (`ElementPlanetGreen3`, `ElementSporePod`, `ElementSporePodStand`, `ElementFloorStripYellow`); `$A057`-`$A072` (`GameOverText`); 1 more ranges |
| Writes | `$ADEF`-`$ADF0` (`PrintChar+14`); `$AE1B`-`$AE21` (`PrintCharLine+24`) |

### `ClearScreen` (`$B04B`)

**Clear the pixels and set every attribute to 0**

C = 0, falls into ClearScreenAttr. Callers: the menu (`$6DA1`), the define keys (`$6FAE`), the game start (`$758E`), the name entry (`$A0C2`), the round end (`$A877`), the bonus screen (`$A8F6`).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 2,567,516 t-states own (0.13 %) |
| Called from | `MainMenu`, `DefineKeys`, `StartGame` |
| Reads | `$4002`-`$5AFF` (screen) |
| Writes | `$4001`-`$5AFF` (screen) |

### `ClearScreenAttr` (`$B04D`)

**Clear the pixels and set every attribute to C**

`$5AFF` down to `$5800` = C, then `$57FF` down to `$4000` = 0 (two LDDRs). Called with C = `$44` by the Hall of Fame (`$714B`).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 7 calls (`c128` 7) |

### `ClearPlayArea` (`$B061`)

**Clear the top 22 character rows (pixels and attributes), the HUD rows 22-23 kept**

The attributes `$5800-$5ABF` = 0, then 176 pixel lines of 32 bytes from `$4000`, the next line by NextPixelLine `$B099`. Called by the screen builder (`$84D4`) before a screen is drawn (241 calls in the runs).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 733,843 t-states own (0.04 %) |
| Called from | `BuildScreen` |
| Calls | `NextPixelLine` |
| Reads | `$4000`-`$50BE` (screen); `$5100`-`$51BE` (screen); `$5200`-`$52BE` (screen); `$5300`-`$53BE` (screen); `$5400`-`$54BE` (screen); `$5500`-`$55BE` (screen); 3 more ranges |
| Writes | `$4000`-`$50BF` (screen); `$5100`-`$51BF` (screen); `$5200`-`$52BF` (screen); `$5300`-`$53BF` (screen); `$5400`-`$54BF` (screen); `$5500`-`$55BF` (screen); 3 more ranges |

### `PixelAddress` (`$B088`)

**The screen address of a pixel position from the line tables**

D the pixel line (0-191), E the X in 2-pixel units (0-127). HL = the address of line D from the tables built by `$7BEF` at `$6500` (high bytes) and `$6600` (low bytes), plus (E AND `$7C`) / 4 = the byte column. A and the flags kept. Callers: the sprite drawers `$7771`, `$77FF`, `$79CF`, `$7A22` (1.5 million calls), `$830F`, `$9041`, `$92FF` (SmallSprites).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 185,192 calls, 17,171,519 t-states own (0.85 %) |
| Called from | `BigSpriteMask`, `ShiftNone`, `XorShot`, `XorShell`, `DrawSmallSprite` |
| Reads | `$6500`-`$65A8` (system); `$6600`-`$66A8` (system) |

### `NextPixelLine` (`$B099`)

**HL to the screen address of the next pixel line down**

The standard step: H + 1; at a character row's end L + 32, and at a third's end H back by 8. Callers: the line table builder `$7C06`, `$7C1E`, ClearPlayArea.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,240 calls, 68,552 t-states own (0.00 %) |
| Called from | `BuildLineTables`, `ClearPlayArea` |

### `PrevPixelLine` (`$B0A8`)

**HL to the screen address of the pixel line above (never ran)**

The step up, the reverse of NextPixelLine: H - 1; at a character row's top L - 32, and when that does not borrow H + 8. No caller in the image and no recording ran it (in the cut it is data): a routine of the toolkit left unused.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Delay` (`$B0B7`)

**Wait BC times 21 T-states**

An LDIR of BC bytes from `$0000` to `$0000`: each byte copied onto itself (the ROM bytes go nowhere, the RAM bytes are written with their own values), 21 T a byte. BC, DE and HL kept. Callers: `$7033`, `$7036`, the Hall of Fame (`$716E`, BC = `$0400`), `$756E`, `$7585`, the main loop (`$7668`), the name entry (`$A039`, `$A03C`, `$A0E8`), the round end (`$A871-$A891`), the bonus screen (`$A8E4-$A948`).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,272 calls, 50,184,765 t-states own (2.50 %) |
| Called from | `DefineKeys`, `StartGame`, `GameOver` |
| Reads | `$4000`-`$FFFF` (`Start`, `MainMenu`, `SoundIsAy`, `MenuText` and 480 more) |
| Writes | `$4000`-`$FFFF` (`Start`, `MainMenu`, `SoundIsAy`, `MenuText` and 480 more) |

### `PrintNumber3` (`$B0C6`)

**Print A as three decimal digits at D, E with FontBase and attribute C**

GlyphBase = FontBase `$D7E0`, then the hundreds, the tens and the units by PrintDigit with B = 100, 10, 1; E advances by 3. Entered by the JP at `$8E83` (the HUD's ZONES and other counters, 249 runs). Leaves GlyphBase at FontBase.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 600 t-states own (0.00 %) |
| Called from | `PrintZone` (tail) |
| Calls | `PrintDigit` |
| Writes | `$ADEF`-`$ADF0` (`PrintChar+14`) |

### `PrintDigit` (`$B0E0`)

**Print the digit of A in base B, keep the remainder**

L = A / B (subtraction), the glyph '0' + L printed by PrintCharAttr at D, E with attribute C, E + 1; A = the remainder.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 12 calls, 1,080 t-states own (0.00 %) |
| Called from | `PrintNumber3` |
| Calls | `PrintCharAttr` |

### `ClearWorkArea` (`$B0F3`)

**Zero the work area `$B181-$B6D0` (1360 bytes)**

Called by the menu (`$6DD4`), the define keys (`$6FC9`) and the screen builder (`$84A4`): every screen starts with the object tables of WorkArea cleared.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 400,176 t-states own (0.02 %) |
| Called from | `MainMenu`, `DefineKeys`, `BuildScreen` |
| Reads | `$B181`-`$B6CF` (`WorkArea`) |
| Writes | `$B181`-`$B6D0` (`WorkArea`) |

## music

`src/game/music.asm`

### `TuneSetMaxVolumes` (`$B6D1`)

**The tune's channel volume limits: B = TuneVolume, A and C one more**

Channel record +8 (the volume ceiling): `$BED5` (B) = TuneVolume `$B6E0` (12), `$BE85` (A) and `$BF25` (C) = 13. Called by TuneStart.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 7 calls, 462 t-states own (0.00 %) |
| Called from | `TuneStart` |
| Reads | `$B6E0` (`TuneVolume`) |
| Writes | `$BE85` (`TuneChannels+8`); `$BED5` (`TuneChannelB+8`); `$BF25` (`TuneChannelC+8`) |

### `TuneStart` (`$B6EC`)

**Start the title tune: the three stream pointers, the channel records, the AY silenced**

TuneStopped = `$FF` while it works; the stream pointers = TuneStreamA `$BA01`, TuneStreamB `$BB7E`, TuneStreamC `$BD06`; TuneInitChannel for the records at `$BE7D`, `$BECD`, `$BF1D`; TuneSetMaxVolumes; AySilence; each record's +2 (the note count) = 1 so the first TuneTick reads every stream; TuneStopped = 0. Called once per menu entry (`$6DB8`, 117 calls in the runs); the tune then plays only on a 128K (TuneTick runs only with the AY flag `$6E16` set, DrawSparkle).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 7 calls, 2,142 t-states own (0.00 %) |
| Called from | `MainMenu` |
| Calls | `TuneSetMaxVolumes`, `TuneInitChannel`, `AySilence` |
| Writes | `$B6E4`-`$B6EB` (`TuneStopped`, `TuneMixer`, `TunePointerA`, `TunePointerB` and 1 more); `$BE7F` (`TuneChannels+2`); `$BECF` (`TuneChannelB+2`); `$BF1F` (`TuneChannelC+2`) |

### `TuneInitChannel` (`$B730`)

**Reset a tune channel record (IX)**

+3 the volume = TuneVolume; +9 the transpose, +`$0C` the call depth, +`$0D` the deferred flag, +0/+1 the period = 0; +2 the note count = 1; +4 and +5 = 5 (no reader in the player).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 21 calls, 4,158 t-states own (0.00 %) |
| Called from | `TuneStart` |
| Reads | `$B6E0` (`TuneVolume`) |
| Writes | `$BE7D`-`$BE8A` (`TuneChannels`); `$BECD`-`$BEDA` (`TuneChannelB`); `$BF1D`-`$BF2A` (`TuneChannelC`) |

### `AySilence` (`$B753`)

**Mixer `$B8` (tones on, noise off) and the three volumes 0**

TuneMixer = `$B8`; AY register 7 = `$B8`, registers 8, 9, 10 = 0 (AyWrite). Callers: the define keys (`$6FAB`), the game start (`$758B`), TuneStart, TuneEnd.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 3,066 t-states own (0.00 %) |
| Called from | `DefineKeys`, `StartGame`, `TuneStart` |
| Calls | `AyWrite` |
| Writes | `$B6E5` (`TuneMixer`) |

### `TuneTick` (`$B767`)

**One tick of the title tune: each channel's step (128K only)**

TuneStreamRead = 0; nothing while TuneStopped. Else channel A (IX = `$BE7D`, IY = TunePointerA), B (`$BECD`) and C (`$BF1D`), TuneChannelStep each, the pointer kept back. Called by DrawSparkle (`$6F40`) every fourth time the menu's animation draws a sprite (the count `$6F4D`), only when the AY flag `$6E16` is set: in c128 10 554 calls, in the 48K runs none (the routine is code by the static walk).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 10,554 calls (`c128` 10,554) |

### `TuneTickDone` (`$B79E`)

**The RET of TuneTick (also the end of TuneEnd's jump)**

TuneEnd (`$B9FE`) jumps here after dropping a return address, so the RET leaves TuneTick's caller's level.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 10,554 calls (`c128` 10,554) |

### `TuneChannelStep` (`$B79F`)

**One channel's tick: the next event when its note ends, the pitch and volume envelopes**

IX the channel record (80 bytes, TuneChannels `$BE7D`), IY its stream pointer. A deferred read (+`$0D` set: the channel's note ended while another channel had read its stream in this tick) is done now; else +2 (the note count) - 1, and at 0 TuneNextEvent is jumped to (this tick has no envelope step).

The pitch envelope: +`$1B` counts the ticks of a step; at 0 the offset +`$19` += the step +`$1D`, and +`$1C` (the steps of the segment) - 1; at 0 the next segment: +`$1A` += 3 (back to 0 at +`$1F`, the table's length), the three bytes at +`$20` + index copied to +`$1C` (steps), +`$1D` (step), +`$1E` (ticks a step) through the self-modified LD A,(IX+d) at `$B7E6-$B7F2`. Then +`$1B` = +`$1E`, and the period +0/+1 (when not 0) plus the signed offset is written to the tone registers +6 / +6 + 1 (AyWrite).

The volume envelope, the same with +`$36` (the ticks), +`$38` (the step), +`$37` (the steps of the segment), +`$35` (the index, step 3, to +`$3A` the length), entries from +`$3B` (`$B86C-$B878`): the volume +3 += +`$38`, kept in 0..+8 (the ceiling), written to the volume register +7. At the table's end the step is 0 and the counters `$FF` (hold).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 31,197 calls (`c128` 31,197) |

### `TuneNextEvent` (`$B88F`)

**Read a channel's stream: the codes up to the next note**

Only one channel reads its stream in a tick: when TuneStreamRead is set the read is deferred (+`$0D` = `$FF`) to the next TuneChannelStep. Then the codes at IY (TuneReadCode `$B89D`, the loop the other code handlers jump back to):

`$00-$31` a note: 0 or n + the transpose +9; the period = the word at `$C71B` + 2n (NotePeriods entry 24 + n: the tune is two octaves above the effects' note 0); +2 = the note's length +`$0A`; volume +3 = 0; the pitch envelope restarted (+`$19` = 0, +`$1A` = -3 so the first segment is index 0, +`$1B` = +`$1C` = 1, +`$1D` = 0); the volume envelope from its first entry (+`$37`/+`$38`/+`$39` = +`$3B`/+`$3C`/+`$3D`, +`$36` = +`$3D`, +`$35` = 0). Ends the read.

`$32-$63` n: the length +`$0A` = n, then the note code - `$32`. `$64`: TuneMixer XOR +`$0B` (the channel's tone and noise bits: A `$09`, B `$12`, C `$24`), register 7. `$79` n: register 6 (the noise period) = n. `$65-$74`: the ceiling +8 = code - `$65` (TuneSetCeiling, never ran). `$75` lo hi: call the stream at hi lo (TuneCall), `$76`: return. `$77` n: transpose (never ran). `$78` lo hi: jump (never ran). `$FF`: the tune's end (TuneEnd). `$89` n ...: n bytes of a pitch envelope to +`$1F` (never ran). `$8A` n ...: n bytes of a volume envelope to +`$3A`. Any other code: RET (TuneBadCode, never ran).

The tune's streams use only notes, `$64`, `$79`, `$75`/`$76` and `$8A` (tune.py over TuneStreamA-C).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 1,343 calls (`c128` 1,343) |

### `TuneSetCeiling` (`$B93D`)

**Stream codes `$65-$74`: the channel's volume ceiling (never ran)**

+8 = code - `$65`, then the next code. No stream of the image holds these codes (tune.py), no recording ran it; the stream reader goes on with `$B944` (`$75` and up) otherwise.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TuneCall` (`$B944`)

**Stream codes `$75` (call a sub-stream) and `$76` (return)**

`$75` lo hi: the return point (IY + 3) saved at +`$0E` + 2 * depth through the self-modified LD (IX+d),C / LD (IX+d),B at `$B965`/`$B968`, depth +`$0C` + 1, IY = hi lo. `$76`: depth - 1, IY from the slot (`$B989`/`$B98C`, the same self-modified offsets). The tune's patterns and its envelope settings are called so (TuneStreamA calls 40, B 42, C 57). Then the next code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TuneTranspose` (`$B999`)

**Stream code `$77` n: the channel's transpose (never ran)**

+9 = n (added to every note but 0). No stream of the image holds it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TuneCheckJump` (`$B9A6`)

**Stream code `$78`?**

Not `$78`: on to TuneCheckEnd.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TuneJump` (`$B9AA`)

**Stream code `$78` lo hi: go on reading at hi lo (never ran)**

No stream of the image holds it: the tune does not loop, it ends with `$FF`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TuneCheckEnd` (`$B9B6`)

**Stream codes `$FF` (the end) and `$89`?**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TunePitchEnvelope` (`$B9BE`)

**Stream code `$89` n b1..bn: the pitch envelope (never ran)**

n + 1 bytes (n and the entries) copied to +`$1F`: the length (a multiple of 3), then entries of 3 bytes (the steps, the step, the ticks a step). No stream of the image holds it; the records' pitch tables in the image keep what the composer's other tunes left.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TuneVolumeEnvelope` (`$B9D8`)

**Stream code `$8A` n b1..bn: the volume envelope**

n + 1 bytes copied to +`$3A`: the length, then entries of 3 bytes (the steps, the step, the ticks a step). In the tune's envelope sub-streams (`$BDE1-$BE7C`) and in its streams (11, 12 and 29 times).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TuneBadCode` (`$B9F6`)

**A stream code with no meaning: the read ends (never ran)**

The RET the chain of tests ends in for `$7A-$88`, `$8B-$FE`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TuneEnd` (`$B9F7`)

**Stream code `$FF`: the tune is over**

TuneStopped = `$FF`, AySilence, then the return address to TuneChannelStep (or TuneTick) dropped and TuneTickDone's RET: the rest of the tick is skipped. The first channel to reach its `$FF` stops the tune for all three.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## sound

`src/game/sound.asm`

### `AyWrite` (`$BF6D`)

**Write C to AY register A**

OUT (`$FFFD`),A selects the register, OUT (`$BFFD`),C writes it; AF, BC, HL kept. Runs on every machine: on a 48K the ports go nowhere (c1: 17 of 17 bytes executed). Callers: the tune (AySilence, TuneChannelStep, TuneNextEvent) and the effects (SoundEffectsTick, SfxWriteChannelA-C).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 27,713 calls, 3,270,134 t-states own (0.16 %) |
| Called from | `AySilence`, `SoundEffectsTick` (tail), `SfxWriteChannelA` (tail), `SfxWriteChannelB` (tail) |
| Ports out | `$BFFD`, `$FFFD` |

### `SoundEffectsTick` (`$BF7E`)

**One tick of the 16 sound effect slots: up to three of them to the AY channels**

SfxChannelIndex `$C5EA` = 0, SfxMixer `$C5E9` = `$BF` (all tones and noises off), SfxChannelBits `$C5E7` = `$F6` (tone A and noise A on). Each slot of SfxSlots `$C5EB` (16 bytes, 16 slots) that is active (+0 not `$FF`) steps (SfxSlotStep), and the channel bits rotate one place (RLC: B's, then C's). At the end register 6 = SfxNoise `$C5E8` and register 7 = SfxMixer.

The first three active slots in slot order get AY channels A, B and C (SfxToAyChannel); a fourth and later run on unheard. A slot that ends in this tick rotates the bits but takes no channel: the next slot's channel bits are then one place ahead of its channel (an engine quirk).

Called three times a main loop pass (`$75C5`, `$7601`, `$766B`; 237 645 times each in the runs), on the 48K too: the 48K hears the beeper routines `$7C26` / `$7C40` instead.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 9,783 calls, 21,301,881 t-states own (1.06 %) |
| Called from | `StartGame` |
| Calls | `AyWrite` (tail), `SfxSlotStep` |
| Reads | `$C5E7`-`$C6DB` (`SfxChannelBits`, `SfxNoise`, `SfxMixer`, `SfxChannelIndex` and 1 more) |
| Writes | `$C5E7`-`$C5EA` (`SfxChannelBits`, `SfxNoise`, `SfxMixer`, `SfxChannelIndex`) |

### `SfxSlotStep` (`$BFBF`)

**One effect slot's tick: the next note when the note ends, the volume decay**

IX the slot. +3 (the note's ticks) - 1, at 0 SfxReadStream. +6 (the decay counter) - 1, at 0 reloaded from +7 and the volume +4 (when not 0) - the step +8 (no floor: a step that does not divide the volume wraps it). Then SfxToAyChannel.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,760 calls, 218,347 t-states own (0.01 %) |
| Called from | `SoundEffectsTick` |
| Calls | `SfxReadStream`, `SfxToAyChannel` (tail) |
| Reads | `$C64E`-`$C653` (`SfxSlots+99`); `$C6DE`-`$C6E1` (`SfxSlots+243`) |
| Writes | `$C64E`-`$C651` (`SfxSlots+99`); `$C6DE`-`$C6E1` (`SfxSlots+243`) |

### `SfxReadStream` (`$BFE1`)

**Read an effect slot's stream up to its next note**

The codes at +1/+2: `$FF` the effect's end (+0 = `$FF`, the slot free; the return to SfxSlotStep dropped, so no channel this tick). `$FE` n: the start volume +5 = n. `$FD` p s: the decay (+7 = p, +6 = p / 2 + 1, +8 = s; SfxSetDecay, never ran). `$FC` m: the mixer mask +`$0B` (0 tone and noise, 7 noise only, `$38` tone only). `$FB` n: SfxNoise = n, and n is also the note that follows (the code falls into the note test with A = n). A note: below `$60` the note with the slot's length +`$0C`, `$60-$FA` the note code - `$60` and then a length byte (+`$0C`). The period +9/+`$0A` = NotePeriods[note], the note's ticks +3 = +`$0C`, the volume +4 = +5.

23 streams in SoundEffects `$C218` (sfx.py over every start the triggers name).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 1,458 calls, 649,203 t-states own (0.03 %) |
| Called from | `SfxSlotStep` |
| Reads | `$C305`-`$C33D` (`BlastSound`); `$C5A1`-`$C5B9` (`ShotSound`); `$C64C`-`$C657` (`SfxSlots+97`); `$C6DC`-`$C6E7` (`SfxSlots+241`); `$C703`-`$C73C` (`NotePeriods+24`, `NotePeriodsTune`) |
| Writes | `$C5E8` (`SfxNoise`); `$C64B`-`$C657` (`SfxSlots+96`); `$C6DB`-`$C6E7` (`SfxSlots+240`) |

### `SfxSetDecay` (`$C002`)

**Effect code `$FD` p s: the volume decay (never ran)**

+7 = p, +6 = p / 2 + 1, +8 = s. The streams with `$FD` (`$C53F`, `$C54D`, `$C55D`, `$C56D`, `$C577`, `$C585`, `$C593`, `$C5BA`, `$C5C8`) are those of the triggers that never ran (the ones at `$C10E`, `$C116`, `$C126`, `$C16F`, `$C17F`, `$C195`): no recording read them. The other effects decay with the slot's +6/+7/+8 as StartSoundEffect left them (+8 = 1) and the counters a previous effect left in the slot.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SfxCheckMixer` (`$C015`)

**Effect codes `$FC` (the mixer mask) and `$FB` (the noise period), then the note**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SfxToAyChannel` (`$C05A`)

**Hand an effect slot's period and volume to the next free AY channel**

SfxChannelIndex + 1; its old value picks SfxChannelWriters `$C077` (0 A, 1 B, 2 C, 3-15 SfxNoChannel), entered with DE = the period (+9/+`$0A`), C = the volume (+4).

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,697 calls, 426,126 t-states own (0.02 %) |
| Called from | `SfxSlotStep` (tail) |
| Calls | `SfxWriteChannelA`, `SfxWriteChannelB` |
| Reads | `$C077`-`$C07A` (`SfxChannelWriters`); `$C5EA` (`SfxChannelIndex`); `$C64F`-`$C655` (`SfxSlots+100`); `$C6DF`-`$C6E5` (`SfxSlots+244`) |
| Writes | `$C5EA` (`SfxChannelIndex`) |

### `SfxWriteChannelA` (`$C097`)

**AY channel A from an effect: the mixer bits, the volume and the period**

SfxMixer AND= (SfxChannelBits OR the slot's mask +`$0B`); register 8 = C, registers 0/1 = DE.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 327,180 t-states own (0.02 %) |
| Called from | `SfxToAyChannel` |
| Calls | `AyWrite` (tail) |
| Reads | `$C5E7`-`$C5E9` (`SfxChannelBits`, `SfxNoise`, `SfxMixer`); `$C656` (`SfxSlots+107`); `$C6E6` (`SfxSlots+251`) |
| Writes | `$C5E9` (`SfxMixer`) |

### `SfxWriteChannelB` (`$C0B1`)

**AY channel B: the mixer bits, register 9 = C, registers 2/3 = DE**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 4,662 t-states own (0.00 %) |
| Called from | `SfxToAyChannel` |
| Calls | `AyWrite` (tail) |
| Reads | `$C5E7`-`$C5E9` (`SfxChannelBits`, `SfxNoise`, `SfxMixer`); `$C6E6` (`SfxSlots+251`) |
| Writes | `$C5E9` (`SfxMixer`) |

### `SfxWriteChannelC` (`$C0CC`)

**AY channel C: the mixer bits, register 10 = C, registers 4/5 = DE**

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings run into, not called (`w/035`, `w/110`, `w/039` and 84 more) |

### `PlaySfxNoiseBurst` (`$C0E7`)

**Start effect NoiseBurstSound in slot 13**

A noise burst falling from volume 13 to 3. Called by MoveShots at `$8417` (419 calls in the runs), after `$9362` found a thing at the place of an entry of the table at `$845F`.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 407 calls (`w/048` 21, `x1` 19, `w/007` 15 and 83 more) |

### `PlaySfxAmmoRefill` (`$C0F4`)

**Start effect AmmoRefillSound in slot 2**

Called at `$9980` right after the ammunition `$8E5A` is set to 99 (a refill), and at `$9F65`.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 56 calls (`w/108` 3, `w/010` 2, `w/058` 2 and 45 more) |

### `PlaySfxGrenadeRefill` (`$C101`)

**Start effect GrenadeRefillSound in slot 2**

Called at `$99D6` right after the grenades `$8E66` are set to 10.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 37 calls (`w/030` 2, `w/076` 2, `w/089` 2 and 28 more) |

### `PlaySfxJingleA` (`$C10E`)

**Start effect JingleASound in slot 4 (never ran)**

No caller in the image and no recording ran it; with the next two, a trigger whose sound is a tune-like phrase of decaying notes (code `$FD`): left from the version this engine came from.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlaySfxJingleB` (`$C116`)

**Start effects JingleBSound (slot 14) and JingleBBassSound (slot 5) (never ran)**

No caller, never ran.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlaySfxWobble` (`$C126`)

**Start effect WobbleSound in slot 13 (never ran)**

No caller, never ran.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlaySfxTrill` (`$C12E`)

**Start effect TrillSound in slot 5**

Called by `$9EAF` (which adds A to the counter `$9ED6` the round end turns into a bonus) and by `$A32B` (PickupsVsPlayer). 156 calls in the runs.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 156 calls (`w/045` 8, `w/120` 8, `w/080` 7 and 31 more) |

### `PlaySfxNoiseSweep` (`$C13B`)

**Start effect NoiseSweepSound in slot 7**

Called at `$9DBB` right after small sprite 8 (the round shot of SmallSprites) is drawn at `$9DB8`: a shot fired by the scenery's guns.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 429 calls (`w/048` 46, `w/123` 44, `w/067` 43 and 44 more) |

### `PlaySfxBlast` (`$C148`)

**Start effect BlastSound in slot 6**

Noise with a falling tone, volume 15 down to 1. Callers: `$909F` (after ten beeper delays of FireShell), `$91A9`, `$9427`.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 62 calls, 5,332 t-states own (0.00 %) |
| Called from | `FireShell` (tail) |
| Calls | `StartSoundEffect` |

### `PlaySfxExplosion` (`$C155`)

**Start effect ExplosionSound in slot 8**

Called right after `$981D` and before a score is added (`$9B79`, `$9BD0`, `$9E5B`, `$9E7F`, `$A63C`): something shot and destroyed.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 2,340 calls (`x2` 205, `w/066` 71, `w/048` 62 and 84 more) |

### `PlaySfxPulse` (`$C162`)

**Start effect PulseSound in slot 13**

Called by Teleports (`$98F3`, `$9928`; 38 and 8 calls).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 38 calls (`w/036` 2, `w/037` 2, `w/056` 2 and 29 more) |

### `PlaySfxRise` (`$C16F`)

**Start effect RiseSound in slot 12 (never ran)**

No caller, never ran.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlaySfxShot` (`$C177`)

**Start effect ShotSound in slot 15**

Called by the fire routine FireControl at `$8372`, right after the ammunition `$8E5A` is decremented (2625 calls in the runs): the player's laser shot.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 9 calls, 243 t-states own (0.00 %) |
| Called from | `FireControl` |
| Calls | `StartSoundEffect` (tail) |

### `PlaySfxChord` (`$C17F`)

**Start effects ChordSound1-3 in slots 8, 9, 10 (never ran)**

A three-voice arpeggio. No caller, never ran.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlaySfxFanfare` (`$C195`)

**Start effects FanfareSound (slot 0) and FanfareBassSound (slot 15) (never ran)**

No caller, never ran.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlaySfxHum` (`$C1A9`)

**Start effects HumSoundA (slot 1) and HumSoundB (slot 11)**

Two low notes (periods `$0384` and `$0392`, 10 ticks, volume 12) beating against each other. Called by ForceFieldStep (`$ABD6`) on each of its passes while its object is on (9349 calls in the runs).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 9,349 calls (`w/035` 823, `w/110` 823, `w/068` 698 and 18 more) |

### `PlaySfxGrenade` (`$C1BE`)

**Start effects GrenadeSoundA (slot 9) and GrenadeSoundB (slot 15)**

Called when a grenade is thrown (`$9254`, after the grenades `$8E66` are decremented): two sweeps a fifth apart rising in volume then falling.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 487 calls (`x2` 14, `w/014` 13, `w/035` 12 and 78 more) |

### `StartSoundEffect` (`$C1D3`)

**Start the effect stream BC in slot A**

IX = SfxSlots + 16A; +0 = `$FF` while it is set up, +1/+2 = BC, +3 = 1 (read at the next tick), +4 = +5 = 15, +8 = 1, +9/+`$0A` = 0, +`$0B` = `$38` (tone only), +`$0C` = 1, then +0 = 0 (active). A slot already playing is restarted. +6/+7 are not set.

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 71 calls, 29,110 t-states own (0.00 %) |
| Called from | `PlaySfxBlast`, `PlaySfxShot` (tail) |
| Writes | `$C64B`-`$C657` (`SfxSlots+96`); `$C6DB`-`$C6E7` (`SfxSlots+240`) |

## cpc

`src/game/cpc.asm`

### `CpcReadKeyboard` (`$C7B5`)

**The Amstrad CPC keyboard scan, never run on the Spectrum**

The CPC's standard matrix read through its PPI (ports `$F4`xx / `$F6`xx / `$F7`xx) and the AY's register 14: DI, select PSG register 14, the PPI port A to input (`$92`), then rows 0-9 (bits 0-3 of port C, `$40` the PSG read) each read from port A into CpcKeyMatrix `$C7AB-$C7B4`; the PPI back to output (`$82`); row 9's bits 5-6 forced to 1; EI. On a Spectrum these ports are nothing the game uses, and no code of the image calls it: 0 of its 62 bytes ran in any recording. Left from the Amstrad CPC version (the AY sound engine around it is shared by both).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SfxNoChannel` (`$C7F3`)

**A RET: SfxChannelWriters' entry for the fourth and later active slots**

9023 indirect entries from `$C076` in the runs.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings run into, not called (`w/035`, `w/110`, `w/109` and 59 more) |

## leftover

`src/game/leftover.asm`

### `SerialDownloader` (`$FF78`)

**A development downloader over the ZX Interface 1 RS232 port, left in the image (never ran)**

DI, the checksum SerialSum `$FFDB` = 0, then blocks: a count byte (0 ends), the address high and low, the bytes to (HL) (the border shows each byte's low 3 bits). After the 0 one more byte is compared with the checksum of everything received: a mismatch is JP `$0000` (a reset), else EI and RET. Bytes come from SerialReadByte `$FFA7`. It lies over the UDGs E-P; no code of the game reaches it and no recording ran it: the transfer tool of the cross-development setup the code was sent with.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SerialReadByte` (`$FFA7`)

**SerialReadByte**

| | |
| --- | --- |
| Runs | not reached in the recordings |
