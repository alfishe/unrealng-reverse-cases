# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, the original tape at signal speed, the first play), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`entry`](#entry) | `$5B00`-`$5B47` | 1 of 2 |
| [`beeper`](#beeper) | `$5B48`-`$5B7E` | 2 of 2 |
| [`input`](#input) | `$5B7F`-`$5BFD` | 4 of 7 |
| [`screen`](#screen) | `$5BFE`-`$5CC3` | 9 of 9 |
| [`random`](#random) | `$5CC4`-`$5CEB` | 1 of 2 |
| [`cursor`](#cursor) | `$5CEC`-`$5DEA` | 6 of 10 |
| [`print`](#print) | `$5DEB`-`$635B` | 21 of 29 |
| [`clicks`](#clicks) | `$635C`-`$6432` | 9 of 10 |
| [`renderer`](#renderer) | `$6433`-`$65A2` | 9 of 15 |
| [`arith`](#arith) | `$65A3`-`$66F1` | 11 of 13 |
| [`menus`](#menus) | `$66F2`-`$6A8B` | 27 of 36 |
| [`landscape`](#landscape) | `$6A8C`-`$6CBE` | 8 of 13 |
| [`tools`](#tools) | `$6CBF`-`$753B` | 49 of 77 |
| [`cityaccess`](#cityaccess) | `$753C`-`$7734` | 21 of 27 |
| [`movers`](#movers) | `$7735`-`$7A00` | 14 of 18 |
| [`joysticks`](#joysticks) | `$7A01`-`$7A9D` | 3 of 3 |
| [`maps`](#maps) | `$7A9E`-`$7B85` | 4 of 7 |
| [`simulation`](#simulation) | `$7B86`-`$8F96` | 102 of 152 |
| [`uitask`](#uitask) | `$8F97`-`$90A6` | 6 of 9 |
| [`disasters`](#disasters) | `$90A7`-`$9193` | 10 of 11 |
| [`budget`](#budget) | `$9194`-`$95B7` | 14 of 19 |
| [`evaluation`](#evaluation) | `$95B8`-`$9B4D` | 15 of 24 |
| [`overview`](#overview) | `$9B4E`-`$9E08` | 9 of 14 |
| [`saveload`](#saveload) | `$9E09`-`$9F3F` | 6 of 9 |
| [`dialogs`](#dialogs) | `$9F40`-`$A883` | 30 of 54 |
| [`workspace`](11-data-reference.md#workspace) | `$A884`-`$E84F` | 0 of 10 |
| [`graphics`](11-data-reference.md#graphics) | `$E850`-`$F681` | 0 of 6 |
| [`tasks`](#tasks) | `$F682`-`$F74D` | 1 of 8 |
| [`system`](#system) | `$F74E`-`$FE00` | 6 of 10 |

## entry

`src/game/entry.asm`

### `Entry` (`$5B1B`)

**The game's entry: stack, black border, the Kempston test, IM 2 with I = `$FD`, then UiTask**

MoveCode2 `$5000` jumps here. SP = `$F6C2` (the top of the UI task's stack UiStack), the border black, SwitchOff `$F705` = 1 (no task switch until the simulation task is set up), then the Kempston test: port `$1F` is read up to 32 768 times; a value `$1F` or more (a floating bus gives `$FF`) means no interface, otherwise KempstonFound = 1. Then I = `$FD` (the vector table VectorTable `$FD00`, every vector `$FCFC`), IM 2, EI and JP UiTask `$8FA0`.

c1: L1 1 at frame 16 280; the loop ran 32 768 times (every read below `$1F`: c1's setup has a Kempston interface, KempstonFound = 1). No other code changes I or the mode.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 2,071,767 t-states own (0.14 %) |
| Calls | `UiTask` (tail) |
| Writes | `$5B7F` (`KempstonFound`); `$F705` (`SwitchOff`) |
| Ports in | `$001F`, `$791F`, `$7A1F`, `$7B1F`, `$7C1F`, `$7D1F`, `$7E1F`, `$7F1F`, `$F81F`, `$F91F`, `$FA1F`, `$FB1F`, `$FC1F`, `$FD1F`, `$FE1F`, `$FF1F` |
| Ports out | `$00FE` |

## beeper

`src/game/beeper.asm`

### `NoiseBurst` (`$5B48`)

**The disaster noise: 200 loops of the beeper from Random, gated by the SOUND option**

Input: E the pitch mask (each loop sends a new random speaker bit when D AND E is 0: E = 0 every loop, 1 every second ...). Interrupts are off while it plays (DI ... EI), so the frame's interrupt is held and the task switch waits. Returns at once when SoundOn (`$A32D`) is 0, but after the DI: with SOUND off it returns with interrupts off, and they stay off until the next EI (a bug of the original). Callers: the disasters (Disaster `$78BD`, the fire and flood spread `$9108`, `$9116`).

L1 764 (the disasters recording: 127-255 calls a disaster), 30 406 random bits sent.

[Animation: `NoiseBurst` at work](img/routines/NoiseBurst.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 764 calls (`stage1/rec/disasters` 764) |
| Called from | `CrashNoise`, `FireNoise`, `FloodNoise`, `Earthquake` |
| Calls | `Random` |
| Reads | `$A32D` (`SoundOn`) |
| Ports out | `$00FE`, `$10FE` |

### `ToneBeep` (`$5B66`)

**The refusal tone: 500 cycles of the speaker, 48 + 16 DJNZ loops a cycle (the beep of a refused tool)**

No inputs. The speaker on with L = `$30` DJNZ loops, off with H = `$10`, 500 times (DE = `$01F4`): 500 cycles of 889 T, 444 500 T uncontended, 127 ms; measured 164 ms (8.2 frames, tools frame 13 434), with contention and the interrupts. It is not gated by SoundOn. Reached by JP ToneBeep from Refuse `$71E4` when a placement is refused (a tool too dear is refused silently by SelectTool's RET M). L1 3: 2 in tools (the occupied cell at frame 13 434 traced, the other not located), 1 in bankrupt.

[Animation: `ToneBeep` at work](img/routines/ToneBeep.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/tools` 2, `stage1/rec/bankrupt` 1) |
| Called from | `Refuse` (tail) |
| Ports out | `$00FE`, `$10FE` |

## input

`src/game/input.asm`

### `ReadPort1F` (`$5B80`)

**A = the Kempston port's bits inverted, or `$FF` when no interface**

Output: A = NOT IN (`$1F`) when KempstonFound, else `$FF` (CPL of 0). Called by ReadKempston `$7A01` from the interrupt (L1 413 183, one a frame).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 255,976 t-states own (0.02 %) |
| Runs (the other recordings) | 407,959 calls (`stage1/rec/metro` 96,503, `stage1/rec/city2` 82,011, `stage1/rec/city` 77,592 and 7 more) |
| Called from | `ReadKempston` |
| Reads | `$5B7F` (`KempstonFound`) |
| Ports in | `$011F` |

### `ScanKey` (`$5BB3`)

**Find the first key down in the nine rows: KeyFound = its index (carry clear), or `$FF` (carry set)**

Reads KeyRows `$5B00-$5B08`; CAPS SHIFT is ignored in the first row (D = `$FE` masks it). Output: carry set and KeyFound = `$FF` when no key is down, else carry clear and KeyFound = 5 row + column. L1 5451.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5 calls, 3,031 t-states own (0.00 %) |
| Runs (the other recordings) | 5,446 calls (`stage1/rec/menus` 4,574, `stage1/rec/levels` 847, `stage1/rec/tools` 25) |
| Called from | `KeyToChar` |
| Reads | `$5B00`-`$5B08` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 5 more) |
| Writes | `$5BB2` (`KeyFound`) |

### `KeyToChar` (`$5BDF`)

**A = the character of the key down (KeyChars), carry set when none**

Used by the typed input: the city name (InputName `$A6F9`), the gene digits and the tool shortcut keys (ToolKeys `$6D2D`). L1 5451, 1193 with a key.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5 calls, 721 t-states own (0.00 %) |
| Runs (the other recordings) | 5,446 calls (`stage1/rec/menus` 4,574, `stage1/rec/levels` 847, `stage1/rec/tools` 25) |
| Called from | `ToolKeys`, `InputLine` |
| Calls | `ScanKey` |
| Reads | `$5B95`-`$5BB2` (`KeyChars+11`, `KeyFound`) |

### `AnyKey` (`$5BEF`)

**Z clear when any key of the nine rows is down**

Output: A = the first row's bits inverted (NZ) or 0 with Z. L1 2523 (the menus' key repeat, NumberRepeat `$6A31`).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 18 calls, 8,299 t-states own (0.00 %) |
| Runs (the other recordings) | 2,505 calls (`stage1/rec/menus` 1,946, `stage1/rec/city2` 196, `stage1/rec/metro` 195 and 2 more) |
| Called from | `NumberRepeat`, `DrawOverview`, `Interrupt` |
| Calls | `DrawOverview` |
| Reads | `$5B00`-`$5B08` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 5 more) |

## screen

`src/game/screen.asm`

### `ScreenAddr` (`$5BFE`)

**HL = the display file address of character row B (0-23), column C (0-31)**

No other register changes but A. L1 451 620: every print and drawing routine calls it.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 4,472 calls, 336,501 t-states own (0.02 %) |
| Runs (the other recordings) | 447,188 calls (`stage1/rec/metro` 114,475, `stage1/rec/city` 83,815, `stage1/rec/city2` 77,045 and 7 more) |
| Called from | `DrawIcon`, `DrawPointer`, `InvertBox`, `PrintNumberAt`, `PrintDigit`, `DrawBoxRow`, `PrintPadded`, `DrawViewRowPass`, `PrintNumberHL`, `PrintNumberVar`, `PrintMenuText`, `MenuTab`, `PrintEditField`, `GreyIcon`, `DrawMover`, `PrintProblem`, `PrintPercent`, `ShowInput`, `Interrupt` |
| Calls | `DrawIcon`, `DrawPointer`, `InvertBox`, `DrawBoxRow`, `PrintPadded`, `PrintNumberVar` |

### `AttrAddr` (`$5C0D`)

**HL = the attribute address of row B, column C (C kept, B = `$58`)**

L1 1024 (the menu highlight HighlightLine `$6933` and the maps window's HighlightMapKey / HighlightLayer).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 10 calls, 1,077 t-states own (0.00 %) |
| Runs (the other recordings) | 1,014 calls (`stage1/rec/menus` 473, `stage1/rec/city2` 155, `stage1/rec/metro` 148 and 7 more) |
| Called from | `HighlightLine`, `HighlightMapKey`, `HighlightLayer` |

### `NextPixelLine` (`$5C19`)

**HL = the display file address one pixel line down**

The usual three cases: inside the character (INC H), into the next character row (L + 32, H - 8), into the next third (L + 32 with carry). L1 3 121 944.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 30,886 calls, 1,156,811 t-states own (0.08 %) |
| Runs (the other recordings) | 3,092,514 calls (`stage1/rec/metro` 827,671, `stage1/rec/city` 578,021, `stage1/rec/city2` 558,040 and 7 more) |
| Called from | `DrawPointer`, `ErasePointer`, `InvertBox`, `GreyIcon`, `DrawMover`, `DrawOverview`, `Interrupt` |
| Calls | `DrawPointer`, `ErasePointer`, `InvertBox`, `GreyIcon`, `DrawMover`, `DrawOverview` |

### `DrawIcon` (`$5C28`)

**Draw icon tile A (8 bytes at IconTiles + 8 A) at row B, column C, with its attribute from IconAttrs**

Sets PrintAddr to the cell, copies the eight bytes down the cell and the attribute IconAttrs + A (`$F4F8` + A) through PutAttr `$F774`. Used for the tool palette, the box frames and the window graphics. L1 36 344.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 392 calls, 242,529 t-states own (0.02 %) |
| Runs (the other recordings) | 35,953 calls (`stage1/rec/city` 9,745, `stage1/rec/metro` 9,408, `stage1/rec/growth` 5,264 and 7 more) |
| Called from | `ScreenAddr`, `DrawIcon2x2` (tail), `Interrupt` |
| Calls | `ScreenAddr`, `PrintGlyph` (tail) |
| Reads | `$6462`-`$6463` (`TileIndex`); `$E850`-`$EA0F` (`IconTiles`); `$F4F8`-`$F52F` (`IconAttrs`); `$F74F`-`$F750` (`PrintAddr`) |
| Writes | `$4022`-`$415D` (screen); `$4222`-`$425D` (screen); `$4322`-`$435D` (screen); `$4422`-`$445D` (screen); `$4522`-`$455D` (screen); `$4622`-`$465D` (screen); 3 more ranges |

### `DrawIconHere` (`$5C57`)

**Draw icon tile A at PrintAddr with the current PrintAttr (no position, no own attribute)**

Then JP PrintGlyphAttr `$F76E` (PrintAttr `$FF` leaves the attribute). L1 27 668 (the box frames of DrawBoxRow).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 616 calls, 281,173 t-states own (0.02 %) |
| Runs (the other recordings) | 27,052 calls (`stage1/rec/menus` 10,184, `stage1/rec/metro` 3,076, `stage1/rec/city2` 2,920 and 7 more) |
| Called from | `DrawBoxRow`, `Interrupt` |
| Calls | `PrintGlyph` (tail) |
| Reads | `$EA10`-`$EA67` (`IconTiles+448`); `$F74F`-`$F750` (`PrintAddr`) |
| Writes | `$4000`-`$57FF` (screen) |

### `ClearTopBlack` (`$5C70`)

**Clear the top third (`$4000-$47FF`) and give it attribute `$38`**

A = `$38` (white paper, black ink) into `$5800-$58FF`. L1 40.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 330 t-states own (0.00 %) |
| Runs (the other recordings) | 37 calls (`stage1/rec/menus` 9, `stage1/rec/city2` 7, `stage1/rec/metro` 7 and 3 more) |
| Called from | `ClearForMaps`, `ShowFullWindowItems`, `MapsWindow`, `UiTask`, `LoadCity`, `LoadMap` |
| Calls | `ClearTopWhite` (tail) |
| Writes | `$4000` (screen) |

### `ClearTopWhite` (`$5C74`)

**Clear the top third with attribute `$07` (black paper, white ink)**

L1 28.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 180,822 t-states own (0.01 %) |
| Runs (the other recordings) | 28 calls (`stage1/rec/bankrupt` 6, `stage1/rec/city2` 5, `stage1/rec/metro` 5 and 3 more) |
| Called from | `ClearTopBlack` (tail), `ShowWindow`, `LoadCity`, `Interrupt` |
| Calls | `ClearViewArea` (falls into) |
| Reads | `$4000`-`$47FE` (screen); `$5800`-`$58FE` (screen) |
| Writes | `$4000`-`$47FF` (screen); `$5800`-`$58FF` (screen) |

### `ClearViewArea` (`$5C8F`)

**Clear the screen's rows 8-23 (`$4800-$57FF`), attribute `$47` (bright white on black)**

The map view's area, cleared before a window or a dialog is drawn over it. L1 223.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 7 calls, 874,306 t-states own (0.06 %) |
| Runs (the other recordings) | 216 calls (`stage1/rec/menus` 92, `stage1/rec/metro` 22, `stage1/rec/city2` 21 and 7 more) |
| Called from | `ClearTopWhite` (falls into), `ShowWindow`, `ClearWindowArea`, `NewLandscape`, `Interrupt` |
| Calls | `ClearForMaps`, `MapsWindow` |
| Reads | `$4800`-`$57FE` (screen); `$5900`-`$5AFE` (screen) |
| Writes | `$4800`-`$57FF` (screen); `$5900`-`$5AFF` (screen) |

### `ClearForMaps` (`$5CAA`)

**Clear the top third black on white, then every attribute row: 8 columns `$07`, 24 columns `$21`**

Called by the maps window (`$7A9E`) before it draws a map: the left 8 columns keep a black key, the 24 on the right are blue on red (`$21`). L1 5.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 29,348 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/menus` 2, `stage1/rec/metro` 1, `stage1/rec/city2` 1) |
| Called from | `ClearViewArea`, `DrawMapsFrame` |
| Calls | `ClearTopBlack`, `DrawMapsFrame` |
| Writes | `$5800`-`$5AFF` (screen) |

## random

`src/game/random.asm`

### `Random` (`$5CC6`)

**The generator: seed' = (254 (seed + 1) - 1) mod 65 537, 254 a primitive root: period 65 536; A = the seed's low byte**

RandomSeed `$5CC4` holds the seed. The arithmetic: H = the seed's low byte, L = `$FD`, so A:HL = 256 seed + 253; two SBC HL,DE take 2 seed off (254 seed + 253 in 24 bits), then the high byte is subtracted from the low 16 bits, which is mod 65537 because 65536 = -1; a borrow adds 1. Registers but A are kept. L1 343 327: the noise, the landscape, the simulation's random choices, the disasters.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 975 calls, 267,763 t-states own (0.02 %) |
| Runs (the other recordings) | 342,369 calls (`stage1/rec/metro` 115,862, `stage1/rec/city2` 63,975, `stage1/rec/disasters` 61,796 and 7 more) |
| Called from | `NoiseBurst`, `Discs`, `ParkTool`, `MoveTrain`, `StartTrain`, `Meltdown`, `StartTornado`, `MoveTornado`, `PickRouteStart`, `TripStep`, `RadiationCell`, `FireCell`, `Spread`, `PickFrameCell`, `ResidentialStep`, `ComBuildingStep`, `IndBuildingStep`, `AnimateFire`, `AnimateFlood`, `StartFires`, `StartFlood`, `RandomDisaster`, `Poll`, `Interrupt` |
| Calls | `AnimateFire`, `AnimateFlood`, `StartFires`, `StartFlood`, `RandomDisaster` |
| Reads | `$5CC4`-`$5CC5` (`RandomSeed`) |
| Writes | `$5CC4`-`$5CC5` (`RandomSeed`) |

## cursor

`src/game/cursor.asm`

### `DrawPointer` (`$5CFE`)

**Draw the pointer at its character cell: save the 8 bytes under it, AND the mask, OR the arrow**

The cell is row PointerY / 8, column PointerX / 2: the pointer moves on the character grid (no shift), though its coordinates are finer. The saved bytes go to PointerSave `$5D34`, the address to PointerAt `$5D3C`. Called by the UI loop every pass with ErasePointer after the pass's drawing (L1 158 080).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 2,591,123 t-states own (0.17 %) |
| Runs (the other recordings) | 156,333 calls (`stage1/rec/metro` 38,779, `stage1/rec/city2` 34,791, `stage1/rec/city` 31,399 and 7 more) |
| Called from | `ScreenAddr`, `NextPixelLine`, `UiTask`, `Interrupt` |
| Calls | `ScreenAddr`, `NextPixelLine`, `UiTask` |
| Reads | `$4002`-`$51DF` (screen); `$5200`-`$52DF` (screen); `$5300`-`$53DF` (screen); `$5400`-`$54DF` (screen); `$5500`-`$55DF` (screen); `$5600`-`$56DF` (screen); 2 more ranges |
| Writes | `$4002`-`$51DF` (screen); `$5200`-`$52DF` (screen); `$5300`-`$53DF` (screen); `$5400`-`$54DF` (screen); `$5500`-`$55DF` (screen); `$5600`-`$56DF` (screen); 2 more ranges |

### `ErasePointer` (`$5D3E`)

**Put the 8 saved bytes back at PointerAt**

L1 158 076.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 1,001,470 t-states own (0.07 %) |
| Runs (the other recordings) | 156,315 calls (`stage1/rec/metro` 38,773, `stage1/rec/city2` 34,787, `stage1/rec/city` 31,398 and 7 more) |
| Called from | `NextPixelLine`, `UiTask`, `Interrupt` |
| Calls | `NextPixelLine`, `UiTask` |
| Reads | `$5D34`-`$5D3D` (`PointerSave`, `PointerAt`) |
| Writes | `$4002`-`$51DF` (screen); `$5200`-`$52DF` (screen); `$5300`-`$53DF` (screen); `$5400`-`$54DF` (screen); `$5500`-`$55DF` (screen); `$5600`-`$56DF` (screen); 1 more ranges |

### `TrackBox` (`$5D55`)

**Work out the pointer's view cell; when the tool's box fits on the view, invert it there**

Output: PointerInView, BoxCell, BoxShown; the box is the BoxSize cells from the pointer's cell, inverted by InvertBox (twice a pass: on, then off once drawn). L1 316 156, 40 592 on the view.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3,554 calls, 307,604 t-states own (0.02 %) |
| Runs (the other recordings) | 312,633 calls (`stage1/rec/metro` 77,541, `stage1/rec/city2` 69,575, `stage1/rec/city` 62,794 and 7 more) |
| Called from | `UiTask`, `Interrupt` |
| Calls | `InvertBox` (falls into), `UiTask` |
| Reads | `$5CFC`-`$5CFD` (`PointerX`, `PointerY`); `$5D4F`-`$5D50` (`BoxSize`) |
| Writes | `$5D51`-`$5D54` (`BoxCell`, `PointerInView`, `BoxShown`) |

### `InvertBox` (`$5D8F`)

**Invert (XOR `$FF`) the BoxSize box at row B, column C of the screen**

The tool palette's highlight (ShowTool) and the map cursor (TrackBox). L1 41 241.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 101 calls, 556,592 t-states own (0.04 %) |
| Runs (the other recordings) | 41,145 calls (`stage1/rec/metro` 20,755, `stage1/rec/tools` 6,643, `stage1/rec/city` 4,673 and 7 more) |
| Called from | `ScreenAddr`, `NextPixelLine`, `TrackBox` (falls into), `ShowTool`, `Interrupt` |
| Calls | `ScreenAddr`, `NextPixelLine`, `ShowTool`, `UiTask` |
| Reads | `$4022`-`$51DF` (screen); `$5200`-`$52DF` (screen); `$5300`-`$53DF` (screen); `$5400`-`$54DF` (screen); `$5500`-`$55DF` (screen); `$5600`-`$56DF` (screen); 2 more ranges |
| Writes | `$4022`-`$51DF` (screen); `$5200`-`$52DF` (screen); `$5300`-`$53DF` (screen); `$5400`-`$54DF` (screen); `$5500`-`$55DF` (screen); `$5600`-`$56DF` (screen); 2 more ranges |

### `DrawIcon2x2` (`$5DB3`)

**Draw icon tiles A, A+1 (row B) and A+2, A+3 (row B+1) at columns C, C+1**

L1 9086.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 98 calls, 25,493 t-states own (0.00 %) |
| Runs (the other recordings) | 9,000 calls (`stage1/rec/city` 2,437, `stage1/rec/metro` 2,357, `stage1/rec/growth` 1,319 and 7 more) |
| Called from | `DrawToolIcons`, `Interrupt`, `PrintGlyph` |
| Calls | `DrawIcon` (tail) |

### `DrawToolIcons` (`$5DD2`)

**The tool palette: 14 icons of 2 x 2 tiles at row 1, columns 2-28, tiles 0, 4, 8 ...**

L1 649 (each tool change redraws it).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 7 calls, 11,207 t-states own (0.00 %) |
| Runs (the other recordings) | 642 calls (`stage1/rec/city` 174, `stage1/rec/metro` 168, `stage1/rec/growth` 94 and 7 more) |
| Called from | `DrawStatusItems`, `ToolClick`, `FundsChanged`, `Interrupt`, `PrintGlyph` |
| Calls | `DrawIcon2x2`, `DrawStatusItems`, `ToolClick`, `FundsChanged` |

## print

`src/game/print.asm`

### `PrintChar` (`$5DEB`)

**Print character A at PrintAddr (JP to PrintGlyph `$F754`)**

L1 163 852.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,416 calls, 45,290 t-states own (0.00 %) |
| Runs (the other recordings) | 162,467 calls (`stage1/rec/menus` 49,294, `stage1/rec/metro` 27,159, `stage1/rec/city2` 26,725 and 7 more) |
| Called from | `PrintInline`, `PrintDigit`, `PrintSign`, `PrintDigitB`, `PrintMenuText`, `PrintZero`, `Interrupt`, `PrintGlyph` |
| Calls | `PrintInline`, `PrintDigit`, `PrintDigitB`, `PrintGlyph` |

### `PrintInline` (`$5DEF`)

**Print the codes that follow the CALL, up to `$FE`, then return after them**

The codes: `$FF` row column (position), `$FB` attribute (PrintAttr), `$FD` row column width height (a box, DrawBox), `$FC` number (printed as up to 3 digits; not used in any recording), `$FE` the end (JP to the byte after it); any other byte a character. PrintCol counts up. Used for every fixed text and window frame (L1 371 calls).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 11 calls, 48,173 t-states own (0.00 %) |
| Runs (the other recordings) | 360 calls (`stage1/rec/menus` 153, `stage1/rec/metro` 38, `stage1/rec/city2` 37 and 7 more) |
| Called from | `PrintChar`, `NextColumn` (tail), `PrintDigit` (tail), `DrawStatusPanel`, `DrawStatusBox`, `DrawNameFunds`, `ShowWindow`, `ClearWindowArea`, `DrawMenuToggle`, `DrawMenuToggleOn`, `DrawMapsFrame`, `DrawMapsKeys`, `LoadCity`, `LoadHeader`, `PrintFound` |
| Calls | `PrintChar`, `NextColumn`, `PrintDigit` (tail) |
| Reads | `$5F16`-`$5F7E` (`StatusBarText`, `DrawStatusBox`, `StatusBoxText`, `DrawStatusItems` and 2 more); `$671F`-`$6726` (`FullFrameText`); `$673E`-`$6745` (`WindowAreaText`); `$686E`-`$687C` (`OnText`, `DrawMenuToggleOn`, `OffText`); `$7AA4`-`$7B4E` (`MapsFrameText`, `DrawMapsKeys`, `MapsKeysText`); `$9E77`-`$9E88` (`SearchingText`); 2 more ranges |
| Writes | `$F74F`-`$F753` (`PrintAddr`, `PrintCol`, `PrintRow`, `PrintAttr`) |

### `NextColumn` (`$5E12`)

**PrintAddr and PrintCol one column on**

L1 450 406.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3,422 calls, 258,960 t-states own (0.02 %) |
| Runs (the other recordings) | 447,036 calls (`stage1/rec/menus` 163,108, `stage1/rec/metro` 66,216, `stage1/rec/city` 60,853 and 7 more) |
| Called from | `PrintInline`, `PrintPadded`, `PrintNumber24`, `PrintSign`, `PrintDigitB` (tail), `PrintMenuText` (tail), `PrintZero`, `PrintFileName`, `ShowInput`, `Interrupt` |
| Calls | `PrintInline` (tail), `PrintPadded`, `PrintNumber24` |
| Reads | `$F74F`-`$F751` (`PrintAddr`, `PrintCol`) |
| Writes | `$F74F`-`$F751` (`PrintAddr`, `PrintCol`) |

### `PrintNumberAt` (`$5E35`)

**HL in 5 digits at PrintCol, PrintRow**

L1 2 (the gene's 5 digits).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |
| Called from | `InputGene` |
| Calls | `ScreenAddr`, `Print5Digits` (falls into) |
| Reads | `$F751`-`$F752` (`PrintCol`, `PrintRow`) |
| Writes | `$F74F`-`$F750` (`PrintAddr`) |

### `Print5Digits` (`$5E41`)

**HL in 5 digits, leading zeros printed**

L1 4.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/menus` 4) |
| Called from | `PrintNumberAt` (falls into), `PrintMenuText` |
| Calls | `PrintDigitOf` |

### `Print4Digits` (`$5E47`)

**HL in 4 digits (the year)**

L1 9921.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 113 calls, 4,415 t-states own (0.00 %) |
| Runs (the other recordings) | 9,809 calls (`stage1/rec/metro` 2,431, `stage1/rec/city2` 2,181, `stage1/rec/city` 1,968 and 7 more) |
| Called from | `PrintDate`, `Interrupt` |
| Calls | `PrintDigitOf` |

### `Print3Digits` (`$5E4D`)

**HL in 3 digits (menus' numbers, the tax rate)**

L1 11 961.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 11,716 t-states own (0.00 %) |
| Runs (the other recordings) | 2,140 calls (`stage1/rec/menus` 1,691, `stage1/rec/city` 156, `stage1/rec/bankrupt` 93 and 6 more) |
| Called from | `PrintDigit`, `PrintMenuText`, `PrintEditField`, `PrintProblem`, `PrintPercent` (tail), `Interrupt` |
| Calls | `PrintDigitOf`, `PrintDigit`, `PrintDate` |

### `PrintDigitOf` (`$5E5E`)

**One digit: count how often DE (a negative power of ten) goes into HL, then print it**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 339 calls, 53,498 t-states own (0.00 %) |
| Runs (the other recordings) | 33,513 calls (`stage1/rec/metro` 7,379, `stage1/rec/city2` 6,630, `stage1/rec/city` 6,175 and 7 more) |
| Called from | `Print5Digits`, `Print4Digits`, `Print3Digits`, `Interrupt` |
| Calls | `PrintDigit` (falls into) |

### `PrintDigit` (`$5E66`)

**Print the digit A (0-9) at PrintAddr and step on**

L1 45 808.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 452 calls, 57,838 t-states own (0.00 %) |
| Runs (the other recordings) | 45,360 calls (`stage1/rec/metro` 9,854, `stage1/rec/city2` 8,855, `stage1/rec/city` 8,280 and 7 more) |
| Called from | `PrintChar`, `PrintInline` (tail), `Print3Digits`, `PrintDigitOf` (falls into), `DrawBox`, `Interrupt` |
| Calls | `ScreenAddr`, `PrintChar`, `PrintInline` (tail), `Print3Digits`, `DrawBox`, `DrawStatusBox`, `DrawStatusItems`, `DrawNameFundsEnd`, `ShowFullWindowItems`, `ClearWindowAreaEnd`, `DrawMenuToggleOn`, `DrawMenuToggleNext`, `DrawMapsKeys`, `DrawMapsEnd`, `LoadHeader`, `LoadMap`, `PrintFileName` |
| Reads | `$F74F`-`$F750` (`PrintAddr`) |
| Writes | `$F74E`-`$F750` (`PrintCharCode`, `PrintAddr`) |

### `DrawBox` (`$5E97`)

**Draw a window frame from icon tiles `$38-$3F`: row, column, width, height at (HL)**

The corners and edges are icon tiles: top `$38` `$39` `$3A`, sides `$3F` `$3B`, bottom `$3E` `$3D` `$3C`; the inside is left alone. Sets PrintCol/PrintRow at the corner. It also patches `$5F0F` (BoxRowRight+9) with the box's column, a fourth self-modified operand. L1 193.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 7,041 t-states own (0.00 %) |
| Runs (the other recordings) | 185 calls (`stage1/rec/menus` 71, `stage1/rec/metro` 23, `stage1/rec/city2` 22 and 7 more) |
| Called from | `PrintDigit`, `DrawBoxRow` |
| Calls | `PrintDigit`, `DrawBoxRow` |
| Reads | `$5E96` (`BoxDims+1`); `$5F46`-`$5F49` (`StatusBoxText+3`); `$6722`-`$6725` (`FullFrameText+3`); `$6741`-`$6744` (`WindowAreaText+3`); `$7AA7`-`$7AB4` (`MapsFrameText+3`); `$9E78`-`$9E7B` (`SearchingText+1`); 1 more ranges |
| Writes | `$5E95`-`$5E96` (`BoxDims`); `$5F0F` (`BoxRowRight+9`); `$F751`-`$F752` (`PrintCol`, `PrintRow`) |

### `DrawBoxRow` (`$5ED3`)

**One row of a frame: tile A, BoxDims-2 tiles B (a space: skipped), tile C, then PrintRow + 1**

The three tiles are written into the operands of the three LD A,n below (self-modified, `$5EE9`, `$5EF9`, `$5F07`). L1 3154.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 83 calls, 215,546 t-states own (0.01 %) |
| Runs (the other recordings) | 3,071 calls (`stage1/rec/menus` 1,177, `stage1/rec/metro` 353, `stage1/rec/city2` 335 and 7 more) |
| Called from | `ScreenAddr`, `DrawBox`, `AddMenuItem`, `Interrupt`, `PrintGlyph` |
| Calls | `ScreenAddr`, `DrawIconHere`, `DrawBox` |
| Reads | `$5E95` (`BoxDims`); `$F74F`-`$F752` (`PrintAddr`, `PrintCol`, `PrintRow`) |
| Writes | `$5EE9`-`$5F07` (`BoxRowLeft+1`, `BoxRowMiddle`, `BoxRowFill`, `BoxRowRight`); `$F74F`-`$F752` (`PrintAddr`, `PrintCol`, `PrintRow`) |

### `DrawStatusPanel` (`$5F13`)

**Draw the menu bar, the status box, the city name, funds, tool palette, tool name and date**

The menu bar "SYSTEM OPTIONS DISASTERS WINDOWS" at row 0 (attribute 7), the box rows 3-7, then DrawNameFunds, DrawToolIcons, ShowTool, PrintToolName, PrintDate, PrintFunds. L1 34 (the first draw and after each window).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 34 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/rec/bankrupt` 6, `stage1/rec/menus` 6, `stage1/rec/city2` 6 and 3 more) |
| Called from | `ShowFullWindowItems` (tail), `MapsWindow`, `UiTask`, `LoadMap` |
| Calls | `PrintInline` |

### `DrawStatusBox` (`$5F40`)

**The status box: rows 3-7 of the top third (attribute `$38`), then the name, the tools, the date, the funds**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 38 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/city2`, `stage1/rec/metro`, `stage1/rec/bankrupt` and 3 more) |
| Called from | `PrintDigit` |
| Calls | `PrintInline` |

### `DrawStatusItems` (`$5F4D`)

**The name, the funds, the tool palette, the tool name and the date**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 342 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/city2`, `stage1/rec/menus`, `stage1/rec/metro` and 3 more) |
| Called from | `DrawToolIcons`, `PrintDigit`, `PrintFunds`, `PrintDate`, `PrintToolName` |
| Calls | `DrawToolIcons`, `DrawNameFunds`, `PrintFunds`, `PrintDate`, `PrintToolName`, `ShowTool`, `MapsWindow` |

### `DrawNameFunds` (`$5F60`)

**Print the city name (12 letters, CityName `$5F68`) at row 5, column 1, and "FUNDS" with the dollar sign at row 5, column 17**

CityName lies inside the inline text: typing a name writes these bytes (InputName `$A6F9`), so the text prints the current name. L1 35.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 54 t-states own (0.00 %) |
| Runs (the other recordings) | 33 calls (`stage1/rec/city2` 6, `stage1/rec/metro` 6, `stage1/rec/bankrupt` 6 and 4 more) |
| Called from | `DrawStatusItems`, `SetLevel` |
| Calls | `PrintInline` |

### `DrawNameFundsEnd` (`$5F7F`)

**RET**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 24 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/metro`, `stage1/rec/bankrupt`, `stage1/rec/city2` and 4 more) |
| Called from | `PrintDigit` |

### `PrintFunds` (`$5F80`)

**Print Funds (`$8F97`, 24 bits) at row 5, column 24**

L1 9918: every month and every purchase.

[Animation: `PrintFunds` at work](img/routines/PrintFunds.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 114 calls, 7,649 t-states own (0.00 %) |
| Runs (the other recordings) | 9,804 calls (`stage1/rec/metro` 2,429, `stage1/rec/city2` 2,180, `stage1/rec/city` 1,967 and 7 more) |
| Called from | `DrawStatusItems`, `PrintNumber24`, `Periodic` (tail), `Interrupt` |
| Calls | `DrawStatusItems`, `PrintNumberVar`, `UiTask` |

### `PrintDate` (`$5FAE`)

**Print the month (MonthNames by Month `$8F9B`) at row 4, column 23 and the year (`$8F9C`) after it**

L1 9917.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 113 calls, 16,419 t-states own (0.00 %) |
| Runs (the other recordings) | 9,804 calls (`stage1/rec/metro` 2,429, `stage1/rec/city2` 2,180, `stage1/rec/city` 1,967 and 7 more) |
| Called from | `Print3Digits`, `DrawStatusItems`, `FindText`, `PrintPadded`, `Periodic` (tail), `Interrupt` |
| Calls | `Print4Digits`, `DrawStatusItems`, `FindText`, `PrintPadded`, `UiTask` |
| Reads | `$8F9B`-`$8F9D` (`Month`, `Year`) |

### `PrintToolName` (`$6305`)

**Print the current tool's name and price (GameTexts by CurrentTool) at row 4, column 1, padded to 20 columns**

L1 99.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5 calls, 615 t-states own (0.00 %) |
| Runs (the other recordings) | 94 calls (`stage1/rec/tools` 22, `stage1/rec/menus` 14, `stage1/rec/metro` 14 and 5 more) |
| Called from | `DrawStatusItems`, `FindText`, `PrintPadded`, `ToolClick` |
| Calls | `DrawStatusItems`, `FindText`, `PrintPadded`, `ShowTool` |
| Reads | `$6D50` (`CurrentTool`) |

### `FindText` (`$6317`)

**HL = the A-th (from 0) bit-7-ended string of the table at HL**

L1 14 996.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 174 calls, 783,759 t-states own (0.05 %) |
| Runs (the other recordings) | 14,824 calls (`stage1/rec/metro` 3,664, `stage1/rec/city2` 3,283, `stage1/rec/city` 2,968 and 7 more) |
| Called from | `PrintDate`, `PrintToolName`, `PrintEvalFigures`, `ShowAdvice`, `Interrupt` |
| Calls | `PrintDate`, `PrintToolName`, `ShowAdvice` |
| Reads | `$5F8A`-`$5FAA` (`MonthNames`); `$5FC6`-`$62F4` (`GameTexts`) |

### `PrintPadded` (`$632A`)

**Print the string at HL at row B, column C, then spaces to A + 1 columns (C counts down from A for each letter but the last)**

L1 14 996.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 174 calls, 420,546 t-states own (0.03 %) |
| Runs (the other recordings) | 14,822 calls (`stage1/rec/metro` 3,664, `stage1/rec/city2` 3,283, `stage1/rec/city` 2,968 and 7 more) |
| Called from | `ScreenAddr`, `NextColumn`, `PrintDate`, `PrintToolName`, `PrintEvalFigures`, `ShowAdvice` (tail), `Interrupt`, `PrintGlyph` |
| Calls | `ScreenAddr`, `NextColumn`, `PrintDate`, `PrintToolName`, `Periodic`, `PrintGlyph` |
| Reads | `$5F8A`-`$5FAD` (`MonthNames`); `$5FC6`-`$60A0` (`GameTexts`); `$60C1`-`$6116` (`GameTexts+251`); `$6146`-`$6170` (`GameTexts+384`); `$61A3`-`$61B9` (`GameTexts+477`); `$61D3`-`$61EF` (`GameTexts+525`); 3 more ranges |
| Writes | `$F74F`-`$F750` (`PrintAddr`) |

## clicks

`src/game/clicks.asm`

### `MovePointer` (`$635C`)

**Move the pointer by the keys: O left, P right, Q up, A down (the joysticks come in as these)**

One step a pass for each key held. L1 158 076.

[Animation: `MovePointer` at work](img/routines/MovePointer.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 284,912 t-states own (0.02 %) |
| Runs (the other recordings) | 156,326 calls (`stage1/rec/metro` 38,777, `stage1/rec/city2` 34,789, `stage1/rec/city` 31,404 and 7 more) |
| Called from | `PointerLeft`, `PointerUp`, `PointerDown`, `DrawView`, `UiTask`, `Interrupt` |
| Calls | `PointerRight`, `PointerLeft`, `PointerUp`, `PointerDown`, `UiTask` |
| Reads | `$5B01`-`$5B05` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 1 more) |

### `PointerRight` (`$637D`)

**PointerX + 1 up to 62**

L1 1895.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 22 calls, 1,700 t-states own (0.00 %) |
| Runs (the other recordings) | 1,873 calls (`stage1/rec/city` 473, `stage1/rec/metro` 425, `stage1/rec/growth` 278 and 5 more) |
| Called from | `MovePointer` |
| Reads | `$5CFC` (`PointerX`) |
| Writes | `$5CFC` (`PointerX`) |

### `PointerLeft` (`$638A`)

**PointerX - 1 down to 0**

L1 2044.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 1,081 t-states own (0.00 %) |
| Runs (the other recordings) | 2,029 calls (`stage1/rec/city` 473, `stage1/rec/metro` 425, `stage1/rec/menus` 292 and 7 more) |
| Called from | `MovePointer`, `Interrupt` |
| Calls | `MovePointer`, `DrawView` (tail) |
| Reads | `$5CFC` (`PointerX`) |
| Writes | `$5CFC` (`PointerX`) |

### `PointerUp` (`$6397`)

**PointerY - 2 down to 0**

The test of key 6 on the view (KeyRow0 bit 4) leads to a branch no recording ran (PointerUpStop, L1 -), which stops at row `$40`.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 54 calls, 5,779 t-states own (0.00 %) |
| Runs (the other recordings) | 10,387 calls (`stage1/rec/tools` 2,576, `stage1/rec/city` 2,031, `stage1/rec/metro` 1,881 and 4 more) |
| Called from | `MovePointer`, `Interrupt` |
| Calls | `MovePointer` |
| Reads | `$5B04` (`KeyRow0`); `$5CFD` (`PointerY`) |
| Writes | `$5CFD` (`PointerY`) |

### `PointerDown` (`$63B8`)

**PointerY + 2 up to 184**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 38 calls, 2,782 t-states own (0.00 %) |
| Runs (the other recordings) | 10,438 calls (`stage1/rec/tools` 2,652, `stage1/rec/city` 2,032, `stage1/rec/metro` 1,882 and 4 more) |
| Called from | `MovePointer`, `Interrupt` |
| Calls | `MovePointer` |
| Reads | `$5CFD` (`PointerY`) |
| Writes | `$5CFD` (`PointerY`) |

### `Click` (`$63CD`)

**SPACE pressed: take the pointer's cell, then the tool palette, the scroll arrows, the menu bar, the map**

With SwitchOff set (no task switch while the UI changes the screen and the map): ToolClick `$6D51`, ScrollClick `$6CBF`, MenuClick `$6401`, MapClick `$7012`. L1 609 (the presses of the recordings).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 72,263 t-states own (0.00 %) |
| Runs (the other recordings) | 156,312 calls (`stage1/rec/metro` 38,776, `stage1/rec/city2` 34,787, `stage1/rec/city` 31,396 and 7 more) |
| Called from | `WaitSpaceUp`, `ToolClick`, `ShowTool`, `UiTask`, `Interrupt` |
| Calls | `MenuClick`, `ScrollClick`, `ToolClick`, `MapClick`, `UiTask` |
| Reads | `$5B07` (`KeyRowSpace`); `$5CFC`-`$5CFD` (`PointerX`, `PointerY`) |
| Writes | `$63C9`-`$63CA` (`ClickCell`); `$F705` (`SwitchOff`) |

### `WaitSpaceUp` (`$63F9`)

**Wait until SPACE is released**

L1 709 255 loop runs, 196 calls.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 335,193 t-states own (0.02 %) |
| Runs (the other recordings) | 585,969 calls (`stage1/rec/menus` 266,387, `stage1/rec/growth` 81,605, `stage1/rec/metro` 80,528 and 7 more) |
| Called from | `MenuClick` (tail), `ToolClick`, `Interrupt` |
| Calls | `Click`, `ToolClick` |
| Reads | `$5B07` (`KeyRowSpace`) |

### `MenuClick` (`$6401`)

**On row 0, open the menu under the pointer and wait for SPACE up**

L1 609, 69 on row 0.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 12 calls, 415 t-states own (0.00 %) |
| Runs (the other recordings) | 597 calls (`stage1/rec/city` 160, `stage1/rec/metro` 152, `stage1/rec/menus` 99 and 7 more) |
| Called from | `Click`, `ShowMenu` |
| Calls | `WaitSpaceUp` (tail), `OpenMenuAt` |
| Reads | `$63CA` (`ClickCell+1`) |

### `OpenMenuAt` (`$640E`)

**The menu by the pointer's column: SYSTEM (below 14), OPTIONS (below 30), DISASTERS (below 48), WINDOWS**

IX = SystemMenu `$A02B`, OptionsMenu `$A32F`, DisastersMenu `$A43E` or WindowsMenu `$A4C2`, then ShowMenu `$66F2`. L1 69.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 130 t-states own (0.00 %) |
| Runs (the other recordings) | 68 calls (`stage1/rec/menus` 30, `stage1/rec/city2` 7, `stage1/rec/metro` 7 and 7 more) |
| Called from | `MenuClick` |
| Calls | `ShowMenu` (tail) |
| Reads | `$5CFC` (`PointerX`) |

## renderer

`src/game/renderer.asm`

### `DrawViewRowPass` (`$6434`)

**Draw one of the view's 16 rows, the one PassCount AND 15 picks**

So the view is redrawn every 16 passes of the UI loop, a row a pass, and the blinking cells change with PassCount bits 4 and 5. L1 158 073.

[Animation: `DrawViewRowPass` at work](img/routines/DrawViewRowPass.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 457,423 t-states own (0.03 %) |
| Runs (the other recordings) | 156,296 calls (`stage1/rec/metro` 38,766, `stage1/rec/city2` 34,786, `stage1/rec/city` 31,395 and 7 more) |
| Called from | `UiTask` |
| Calls | `ScreenAddr`, `DrawView` (tail), `MapAddr` |
| Reads | `$6507`-`$6508` (`ViewCol`, `ViewRow`); `$8F9F` (`PassCount`) |
| Writes | `$6433` (`Blink`); `$6482`-`$6483` (`DrawTileAt+1`) |

### `DrawBlankCell` (`$6464`)

**Draw cell tile `$3B` (the "no power" lightning) instead: the on phase of the blink of an unpowered zone or building**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,038 calls (`stage1/rec/tools` 417, `stage1/rec/disasters` 207, `stage1/rec/ports` 178 and 4 more) |
| Called from | `DrawBuildingTile` (tail) |
| Calls | `DrawCell` (tail) |

### `DrawCell` (`$6468`)

**Draw one view cell: map byte in A (or the building row in progress), tile and attribute**

A map byte below `$80` is a cell tile at CellTiles `$EA68` + 8 n with its attribute at CellAttrs `$F530` + n; inside a building row (BuildingLeft not 0) the next building tile is drawn instead (DrawBuildingTile). Cells `$54-$56` blink (BlinkCell); roads 7 and 8 show their traffic (RoadTraffic). The tile goes to ViewAt (`$6482`), the attribute through PutAttr. L1 5 379 061.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 58,912 calls, 36,494,172 t-states own (2.42 %) |
| Runs (the other recordings) | 5,320,157 calls (`stage1/rec/metro` 1,333,458, `stage1/rec/city2` 1,119,597, `stage1/rec/city` 1,084,514 and 7 more) |
| Called from | `DrawBlankCell` (tail), `BlinkCell`, `RoadTraffic`, `DrawBuildingTile` (tail), `DrawView`, `Interrupt` |
| Calls | `BlinkCell`, `RoadTraffic`, `PrintGlyph` (tail) |
| Reads | `$6462`-`$6463` (`TileIndex`); `$64D5` (`BuildingDummy`); `$6505`-`$6506` (`CellAttrPtr`); `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`); `$8F9F` (`PassCount`); `$D261`-`$D553` (`CityMap+3601`); 10 more ranges |
| Writes | `$4800`-`$57FF` (screen); `$6462`-`$6463` (`TileIndex`); `$6505`-`$6506` (`CellAttrPtr`); `$6558` (`BuildingLeft`); `$8F97`-`$8F99` (`Funds`) |

### `BlinkCell` (`$6499`)

**Cells `$54-$56` (the unpowered zone centres) blink: with PassCount bit 5 set they show tile `$3B` (the lightning)**

L1 4 249 059, 11 661 blanked.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 58,912 calls, 1,472,731 t-states own (0.10 %) |
| Runs (the other recordings) | 4,190,153 calls (`stage1/rec/metro` 1,020,914, `stage1/rec/city` 805,975, `stage1/rec/city2` 757,202 and 7 more) |
| Called from | `DrawCell`, `Interrupt` |
| Calls | `DrawCell` |
| Reads | `$8F9F` (`PassCount`) |

### `RoadTraffic` (`$64A9`)

**Road cells 7 and 8: heavy traffic shows tile `$34` / `$36`, medium blinks to `$35` / `$37`**

Reads the traffic map at the cell (MapToRowCol `$7635`, TrafficAt `$7581`): `$DC` or more heavy, `$96-$DB` medium (the second tile when Blink is set). L1 668 762.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 59,776 calls, 3,780,176 t-states own (0.25 %) |
| Runs (the other recordings) | 4,222,224 calls (`stage1/rec/metro` 1,030,275, `stage1/rec/city` 805,975, `stage1/rec/city2` 766,609 and 7 more) |
| Called from | `DrawCell`, `Grid48`, `MapToRowCol`, `OverviewCell`, `Interrupt` |
| Calls | `DrawCell`, `TrafficAt`, `MapToRowCol`, `OverviewCell` |
| Reads | `$6433` (`Blink`); `$6509`-`$650A` (`ViewCellPtr`); `$B29E` (`Pollution+1230`); `$B418` (`Pollution+1608`); `$BA71`-`$BA72` (`Traffic+929`); `$BA9F`-`$BAAC` (`Traffic+975`); 6 more ranges |

### `DrawBuildingTile` (`$64D6`)

**The next tile of the building row in progress: BuildingTiles `$ED58` + 8 n, attribute `$F58E` + n**

With PassCount bit 5, the first drawn cell of a building row whose start byte AND `$F0` is `$A0` (a top row, power bit 4 clear) shows tile `$3B`, the lightning. IX then points at BuildingDummy, so the row's other cells and the lower rows never blink: only the top-left cell of an unpowered building does. L1 1 130 002.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/city2`, `stage1/rec/metro`, `stage1/rec/city` and 1 more) |
| Called from | `Interrupt` |
| Calls | `DrawBlankCell` (tail), `DrawCell` (tail) |
| Reads | `$64D5` (`BuildingDummy`); `$6559`-`$655A` (`BuildingTile`); `$8F9F` (`PassCount`); `$D26A` (`CityMap+3610`); `$D2CA`-`$D50A` (`CityMap+3706`); `$D66F`-`$D747` (`CityMap+4639`); 4 more ranges |
| Writes | `$6462`-`$6463` (`TileIndex`); `$6505`-`$6506` (`CellAttrPtr`) |

### `DrawView` (`$650B`)

**Draw the whole view: 16 rows of 32 cells from the map at ViewCol, ViewRow**

L1 627 (after every scroll, window and dialog).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 4 calls, 16,510,296 t-states own (1.10 %) |
| Runs (the other recordings) | 623 calls (`stage1/rec/metro` 182, `stage1/rec/city` 156, `stage1/rec/menus` 97 and 7 more) |
| Called from | `PointerLeft` (tail), `DrawViewRowPass` (tail), `StartBuilding`, `ShowMenu`, `CrossNetwork`, `PlaceNetwork` (tail), `Bulldoze` (tail), `ParkTool` (tail), `ResidentialTool` (tail), `CommercialTool` (tail), `IndustrialTool` (tail), `PoliceTool` (tail), `FireTool` (tail), `StadiumTool` (tail), `PowerPlantTool` (tail), `SeaportTool` (tail), `AirportTool` (tail), `ShiftScroll` (tail), `MapsWindow` (tail), `UiTask`, `BudgetWindow` (tail), `EvaluationWindow` (tail), `Interrupt`, `PrintGlyph` |
| Calls | `MovePointer`, `DrawCell`, `StartBuilding`, `ShowMenu`, `MapAddr`, `UiTask` |
| Reads | `$6482`-`$6483` (`DrawTileAt+1`); `$6507`-`$6508` (`ViewCol`, `ViewRow`); `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`); `$D24E`-`$DE1E` (`CityMap+3582`) |
| Writes | `$6482`-`$6483` (`DrawTileAt+1`); `$6505`-`$650A` (`CellAttrPtr`, `ViewCol`, `ViewRow`, `ViewCellPtr`); `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`) |

### `StartBuilding` (`$655B`)

**A map byte `$80` or more: work out the building's tile number and the cells left**

From a `$C0-$FF` byte it steps back to the row's first byte (FindBuildingStart). Width = first AND 7, n = (second AND `$3F`) x 8 + (third AND 7) + the cells stepped back. L1 356 616.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 356,616 calls (`stage1/rec/city2` 114,966, `stage1/rec/metro` 101,052, `stage1/rec/city` 87,826 and 5 more) |
| Called from | `DrawView`, `Interrupt` |
| Calls | `DrawView` |
| Reads | `$6592` (`BuildingBack`); `$D261`-`$D50C` (`CityMap+3601`); `$D553`-`$D555` (`CityMap+4355`); `$D566`-`$D568` (`CityMap+4374`); `$D5C6`-`$D749` (`CityMap+4470`); `$D9E0`-`$DA5A` (`CityMap+5520`); 3 more ranges |
| Writes | `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`); `$6592` (`BuildingBack`) |

### `FindBuildingStart` (`$6593`)

**Step IX back over the `$C0-$FF` bytes to the row's `$80-$BF` byte, counting them**

L1 34 254 (the buildings cut by the view's left edge).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 34,254 calls (`stage1/rec/metro` 17,141, `stage1/rec/city2` 8,907, `stage1/rec/city` 5,677 and 3 more) |
| Called from | `BuildingValue`, `FillBuilding` |
| Reads | `$6592` (`BuildingBack`); `$D26A` (`CityMap+3610`); `$D386`-`$D3EB` (`CityMap+3894`); `$D434`-`$D448` (`CityMap+4068`); `$D4F4`-`$D508` (`CityMap+4260`); `$D5C6`-`$D5C8` (`CityMap+4470`); 7 more ranges |
| Writes | `$6592` (`BuildingBack`) |

## arith

`src/game/arith.asm`

### `PrintNumberHL` (`$65A5`)

**HL (C = 0) in up to 7 digits at row B, column C**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11,064 calls (`stage1/rec/menus` 10,015, `stage1/rec/city` 621, `stage1/rec/bankrupt` 414 and 3 more) |
| Called from | `PrintBudget`, `ScoreOf` |
| Calls | `ScreenAddr`, `PrintNumber24` |
| Writes | `$F74F`-`$F750` (`PrintAddr`) |

### `PrintNumberVar` (`$65B3`)

**The 24-bit number at (HL) (low, middle, high) at row B, column C**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 114 calls, 48,556 t-states own (0.00 %) |
| Runs (the other recordings) | 17,239 calls (`stage1/rec/menus` 6,983, `stage1/rec/metro` 2,444, `stage1/rec/city` 2,394 and 7 more) |
| Called from | `ScreenAddr`, `PrintFunds`, `PrintBudget`, `PrintEvalFigures`, `Interrupt` |
| Calls | `ScreenAddr`, `PrintNumber24` (falls into) |
| Reads | `$81E0`-`$81E2` (`CityValueLast`); `$8E8A`-`$8E8C` (`LastPop`); `$8F97`-`$8F99` (`Funds`); `$930E`-`$9328` (`TaxIncome`, `TransportCost`, `PoliceCost`, `FireCost` and 7 more); `$978F`-`$9791` (`Migration`) |
| Writes | `$664D`-`$664E` (`NumberFlags`); `$F74F`-`$F750` (`PrintAddr`) |

### `PrintNumber24` (`$65C1`)

**CHL as a signed decimal, leading zeros left out and made up as trailing spaces**

Powers of ten from 1 000 000 down, each a 24-bit subtraction loop (Digit24). Used by every money and population figure. L1 28 400.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 45,965 t-states own (0.00 %) |
| Runs (the other recordings) | 27,236 calls (`stage1/rec/menus` 16,998, `stage1/rec/city` 3,009, `stage1/rec/metro` 2,449 and 3 more) |
| Called from | `NextColumn`, `PrintNumberHL`, `PrintNumberVar` (falls into), `PrintSign`, `PrintDigitB`, `Interrupt`, `PrintGlyph` |
| Calls | `NextColumn`, `PrintFunds`, `PrintSign`, `Digit24`, `PrintDigitB`, `PrintGlyph` |
| Reads | `$664E` (`NumberFlags+1`); `$F74F`-`$F750` (`PrintAddr`) |
| Writes | `$65A3`-`$65A4` (`NumberEnd`); `$664D`-`$664E` (`NumberFlags`) |

### `PrintSign` (`$662C`)

**A negative CHL (bit 7 of C): print "-" and negate it**

L1 7 (the budget's negative balances).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 114 calls, 2,233 t-states own (0.00 %) |
| Runs (the other recordings) | 28,302 calls (`stage1/rec/menus` 16,998, `stage1/rec/city` 3,009, `stage1/rec/metro` 2,465 and 7 more) |
| Called from | `PrintNumber24`, `Interrupt` |
| Calls | `PrintChar`, `NextColumn`, `PrintNumber24` |

### `Digit24` (`$664F`)

**B = how often B'DE' (a negative power of ten) goes into C'HL'; print it unless a leading zero**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 680 calls, 214,011 t-states own (0.01 %) |
| Runs (the other recordings) | 169,764 calls (`stage1/rec/menus` 101,989, `stage1/rec/city` 18,073, `stage1/rec/metro` 14,700 and 7 more) |
| Called from | `PrintNumber24`, `Interrupt` |
| Calls | `PrintDigitB` (falls into) |
| Reads | `$664D`-`$664E` (`NumberFlags`) |
| Writes | `$664D`-`$664E` (`NumberFlags`) |

### `PrintDigitB` (`$666F`)

**Print the digit B**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 565 calls, 38,301 t-states own (0.00 %) |
| Runs (the other recordings) | 97,235 calls (`stage1/rec/menus` 36,593, `stage1/rec/city2` 15,327, `stage1/rec/city` 15,310 and 7 more) |
| Called from | `PrintChar`, `PrintNumber24`, `Digit24` (falls into), `Interrupt` |
| Calls | `PrintChar`, `NextColumn` (tail), `PrintNumber24` |
| Reads | `$664E` (`NumberFlags+1`) |
| Writes | `$664E` (`NumberFlags+1`); `$F74E` (`PrintCharCode`) |

### `Sub24` (`$6680`)

**CHL = CHL - BDE (24 bits); carry and sign as the high byte left them**

The one 24-bit subtraction: prices against Funds and the city class's thresholds both use it (stage 1: the POKE file's NOP NOP at `$6681` breaks both). L1 25 262.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 104 calls, 5,107 t-states own (0.00 %) |
| Runs (the other recordings) | 25,159 calls (`stage1/rec/menus` 14,581, `stage1/rec/city` 3,590, `stage1/rec/metro` 2,769 and 7 more) |
| Called from | `ToolClick`, `GreyUnaffordable`, `Spend`, `BudgetTotals`, `CapTransport`, `CapPolice`, `CapFire`, `CategoryOf`, `PrintEvalFigures`, `Interrupt` |
| Calls | `GreyUnaffordable` |

### `Add24` (`$6687`)

**CHL = CHL + BDE (24 bits)**

L1 39 110.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 144 calls, 5,809 t-states own (0.00 %) |
| Runs (the other recordings) | 38,966 calls (`stage1/rec/menus` 10,669, `stage1/rec/metro` 8,745, `stage1/rec/city` 5,829 and 6 more) |
| Called from | `AddValue`, `AddPopulation`, `BudgetTotals`, `CapTransport`, `CapPolice`, `CapFire` |

### `Mul16` (`$668C`)

**CHL = HL x DE (24-bit product), shift and add**

L1 16 721.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 160 calls, 243,386 t-states own (0.02 %) |
| Runs (the other recordings) | 16,561 calls (`stage1/rec/menus` 5,475, `stage1/rec/city` 2,523, `stage1/rec/city2` 2,262 and 6 more) |
| Called from | `AssessCity`, `AddValue`, `TaxIncomeOf`, `Percent` |

### `Div24By8` (`$66B6`)

**CHL = CHL / A, remainder in A**

L1 5831.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,831 calls (`stage1/rec/menus` 5,015, `stage1/rec/city` 373, `stage1/rec/bankrupt` 231 and 6 more) |
| Called from | `TaxIncomeOf`, `Percent` (tail) |

### `Div16` (`$66D0`)

**HL = HL / DE; HL = 0 when DE is 0**

L1 5092.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 72 calls, 3,785 t-states own (0.00 %) |
| Runs (the other recordings) | 5,020 calls (`stage1/rec/city2` 1,040, `stage1/rec/city` 1,011, `stage1/rec/metro` 974 and 6 more) |
| Called from | `Averages`, `DecayPollution`, `DecayTraffic`, `Averages2`, `ApplyFunding` |

## menus

`src/game/menus.asm`

### `ShowMenu` (`$66F2`)

**A pull-down menu at IX: the window area cleared, the items drawn, run, then the view redrawn**

L1 76.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 98 t-states own (0.00 %) |
| Runs (the other recordings) | 75 calls (`stage1/rec/menus` 31, `stage1/rec/metro` 8, `stage1/rec/growth` 8 and 7 more) |
| Called from | `OpenMenuAt` (tail), `DrawView`, `NumberRepeat`, `PowerPlantTool` |
| Calls | `MenuClick`, `DrawView`, `ClearWindowArea`, `DrawMenu`, `RunMenu` |
| Writes | `$F753` (`PrintAttr`) |

### `ShowInlineWindow` (`$6704`)

**A window whose description follows the CALL (POP IX), then ShowWindow**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27 calls (`stage1/rec/menus` 20, `stage1/rec/levels` 2, `stage1/rec/bankrupt` 1 and 4 more) |
| Called from | `Confirm`, `AboutWindow`, `LoadMenu`, `SaveMenu`, `FileNameWindow`, `TapeWindow`, `SpeedMenu`, `LevelMenu`, `SetLevel` |
| Calls | `ShowWindow` (falls into) |
| Reads | `$9FD3` (`ConfirmMenu`); `$A51C` (`LevelMenuText`) |

### `ShowWindow` (`$6706`)

**Draw the window at IX: a menu-sized one (first byte 8 or more) over the view, else full screen**

L1 54.

[Animation: `ShowWindow` at work](img/routines/ShowWindow.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 52 calls (`stage1/rec/menus` 23, `stage1/rec/bankrupt` 7, `stage1/rec/city2` 6 and 3 more) |
| Called from | `ShowInlineWindow` (falls into), `BudgetWindow`, `EvaluationWindow` |
| Calls | `ClearTopWhite`, `ClearViewArea`, `PrintInline`, `ClearWindowArea`, `DrawMenu`, `RunMenu` (tail) |
| Reads | `$91BC` (`BudgetWindowText`); `$95D7` (`EvaluationText`); `$9FD3` (`ConfirmMenu`); `$A0CA` (`AboutText`); `$A1F6`-`$A30C` (`LoadMenuText`, `SaveMenu`, `SaveMenuText`, `FileNameWindow` and 6 more); `$A3AF` (`SpeedMenuText`); 2 more ranges |

### `ShowFullWindowItems` (`$6727`)

**ShowFullWindowItems**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/bankrupt`, `stage1/rec/city2`, `stage1/rec/metro` and 3 more) |
| Called from | `PrintDigit` |
| Calls | `ClearTopBlack`, `DrawStatusPanel` (tail), `DrawMenu`, `RunMenu` |
| Writes | `$F753` (`PrintAttr`) |

### `ClearWindowArea` (`$6738`)

**Clear rows 8-23 and frame them (attribute `$44`, a 32 x 16 box at row 8)**

L1 116.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 102 t-states own (0.00 %) |
| Runs (the other recordings) | 113 calls (`stage1/rec/menus` 55, `stage1/rec/growth` 10, `stage1/rec/metro` 9 and 7 more) |
| Called from | `ShowMenu`, `ShowWindow`, `NewLandscape`, `UiTask` |
| Calls | `ClearViewArea`, `PrintInline` |

### `ClearWindowAreaEnd` (`$6746`)

**RET**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 30 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/menus`, `stage1/rec/growth`, `stage1/rec/city` and 7 more) |
| Called from | `PrintDigit` |

### `DrawMenu` (`$67C3`)

**Draw the items of the menu at IX, line by line, and collect the selectable ones**

Item kinds (first byte): 0 a text line, 1 a toggle (a flag address, then ON or OFF), 2 an action (an address to run), 3 a separator line (tiles `$40-$42`), 4 the end, 8 a number field (selectable). L1 143.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 8,343 t-states own (0.00 %) |
| Runs (the other recordings) | 140 calls (`stage1/rec/menus` 58, `stage1/rec/metro` 14, `stage1/rec/growth` 14 and 7 more) |
| Called from | `ShowMenu`, `ShowWindow`, `ShowFullWindowItems`, `DrawMenuToggleOn` (tail), `DrawMenuToggleNext` (tail), `NewLandscape`, `UiTask` |
| Calls | `AddMenuItem` |
| Reads | `$6749` (`MenuLine`); `$684B` (`ToggleValue`); `$91BC`-`$930D` (`BudgetWindowText`, `TaxRate`, `TransportPercent`, `PolicePercent` and 1 more); `$95D7`-`$9736` (`EvaluationText`); `$9F41`-`$A5A8` (`PlantMenu`, `NoPlant`, `ChooseNuclear`, `Confirm` and 32 more); `$A5E5`-`$A671` (`OldLandscapeMenu`, `GeneShown`); 1 more ranges |
| Writes | `$5E95` (`BoxDims`); `$6747`-`$6762` (`MenuState`, `MenuLine`, `MenuItems`); `$67C2` (`MenuCount`); `$684B` (`ToggleValue`); `$F751`-`$F752` (`PrintCol`, `PrintRow`) |

### `AddMenuItem` (`$6806`)

**Put the line and IX into the next MenuItems slot**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 1,354 t-states own (0.00 %) |
| Runs (the other recordings) | 554 calls (`stage1/rec/menus` 256, `stage1/rec/disasters` 48, `stage1/rec/bankrupt` 45 and 7 more) |
| Called from | `DrawMenu`, `DrawMenuToggle` |
| Calls | `DrawBoxRow`, `PrintMenuText` |
| Reads | `$6749` (`MenuLine`); `$67C2` (`MenuCount`) |
| Writes | `$674A`-`$6761` (`MenuItems`); `$67C2` (`MenuCount`) |

### `DrawMenuToggle` (`$684C`)

**A toggle item: its text, then ON or OFF by its flag**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `PrintInline`, `AddMenuItem`, `PrintMenuText`, `MenuTab` |

### `DrawMenuToggleOn` (`$6871`)

**DrawMenuToggleOn**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/city`, `stage1/rec/growth` and 5 more) |
| Called from | `PrintDigit` |
| Calls | `PrintInline`, `DrawMenu` (tail) |

### `DrawMenuToggleNext` (`$687D`)

**DrawMenuToggleNext**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/disasters`, `stage1/rec/bankrupt` and 4 more) |
| Called from | `PrintDigit` |
| Calls | `DrawMenu` (tail) |

### `PrintMenuText` (`$6882`)

**The item's text at its line, column 1: bit 7 ends it; codes `$21` (to column 24), 5, 6, 7 (numbers)**

Codes: `$21` moves to column 24 (MenuTab), 6 a 16-bit number (5 digits) at an address, 7 an 8-bit one (3 digits), 5 a 24-bit one; a nonzero byte after the code registers the field for editing (MenuField). L1 1677.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 27 calls, 42,486 t-states own (0.00 %) |
| Runs (the other recordings) | 1,650 calls (`stage1/rec/menus` 610, `stage1/rec/metro` 198, `stage1/rec/city2` 186 and 7 more) |
| Called from | `AddMenuItem`, `DrawMenuToggle` |
| Calls | `ScreenAddr`, `PrintChar`, `NextColumn` (tail), `Print5Digits`, `Print3Digits`, `MenuField`, `MenuTab` |
| Reads | `$6749` (`MenuLine`); `$91BE`-`$930C` (`BudgetWindowText+2`, `TaxRate`, `TransportPercent`, `PolicePercent` and 1 more); `$95D9`-`$9735` (`EvaluationText+2`); `$9F43`-`$A2DA` (`PlantMenu+2`, `NoPlant`, `ChooseNuclear`, `Confirm` and 12 more); `$A30E`-`$A5A7` (`TapeText+2`, `AutoBulldoze`, `OptionsMenu`, `Speed` and 12 more); `$A5E7`-`$A670` (`OldLandscapeMenu+2`, `GeneShown`); 1 more ranges |
| Writes | `$F74F`-`$F750` (`PrintAddr`) |

### `MenuValueSlot` (`$6905`)

**HL = MenuValues + 3 A**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 41 calls (`stage1/rec/bankrupt` 25, `stage1/rec/menus` 10, `stage1/rec/city` 6) |
| Called from | `MenuField`, `EditNumber` |

### `MenuField` (`$6910`)

**Remember the column and the address of the number field on this line**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rec/bankrupt` 24, `stage1/rec/menus` 8, `stage1/rec/city` 4) |
| Called from | `PrintMenuText` |
| Calls | `MenuValueSlot` |
| Reads | `$6749` (`MenuLine`); `$F751` (`PrintCol`) |
| Writes | `$6783`-`$6785` (`MenuValues+9`); `$679B`-`$67A3` (`MenuValues+33`) |

### `MenuTab` (`$6922`)

**PrintCol 24 on this line**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 166 calls (`stage1/rec/menus` 79, `stage1/rec/bankrupt` 28, `stage1/rec/city` 15 and 6 more) |
| Called from | `DrawMenuToggle`, `PrintMenuText` |
| Calls | `ScreenAddr` |
| Reads | `$6749` (`MenuLine`) |
| Writes | `$F74F`-`$F752` (`PrintAddr`, `PrintCol`, `PrintRow`) |

### `HighlightLine` (`$6933`)

**XOR `$46` into the attributes of row B, columns 1-30: the menu bar's highlight**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 6 calls, 7,844 t-states own (0.00 %) |
| Runs (the other recordings) | 598 calls (`stage1/rec/menus` 273, `stage1/rec/bankrupt` 73, `stage1/rec/city` 48 and 7 more) |
| Called from | `ToggleMenuLine` |
| Calls | `AttrAddr` |
| Reads | `$5861`-`$587E` (screen); `$5961`-`$5A7E` (screen); `$5AC1`-`$5ADE` (screen) |
| Writes | `$5861`-`$587E` (screen); `$5961`-`$5A7E` (screen); `$5AC1`-`$5ADE` (screen) |

### `RunMenu` (`$6944`)

**Move the highlight with Q / A every 8 frames (HALT), SPACE selects: run, toggle or edit the item**

L1 132. The menus are opened from Click (or BudgetWindow, EvaluationWindow), which set SwitchOff `$F705` = 1: the simulation is frozen while a menu is open (MapsWindow has no menu and leaves SwitchOff to LayerOf, per cell: the simulation runs on there), and each HALT waits one frame.

[Animation: `RunMenu` at work](img/routines/RunMenu.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 46,767,785 t-states own (3.11 %) |
| Runs (the other recordings) | 130 calls (`stage1/rec/menus` 54, `stage1/rec/metro` 14, `stage1/rec/growth` 13 and 7 more) |
| Called from | `ShowMenu`, `ShowWindow` (tail), `ShowFullWindowItems`, `EditDown` (tail), `UiTask`, `SetLevel` (tail), `InputGene` (tail) |
| Calls | `CallMenuHook`, `NumberRepeat` (tail), `MenuUp`, `ToggleMenuLine`, `MenuDown`, `SelectedItem` |
| Reads | `$5B01`-`$5B07` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 3 more); `$674A`-`$675E` (`MenuItems`); `$6783`-`$6785` (`MenuValues+9`); `$67C2` (`MenuCount`); `$6956` (`RunMenuHalt+1`); `$6995` (`EditRepeat`); 13 more ranges |
| Writes | `$6990`-`$6995` (`EditMax`, `EditPtr`, `EditPos`, `EditRepeat`); `$6A7D` (`MenuSelected`); `$F753` (`PrintAttr`) |

### `EditNumber` (`$6996`)

**Q / A count the field up and down (to EditMax), with a key repeat; SPACE ends**

L1 5 (the tax rate and the budget windows).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `MenuValueSlot`, `EditUp`, `EditDown`, `PrintEditField`, `CallMenuHook`, `NumberRepeat`, `ToggleMenuLine`, `SelectedItem` |

### `EditUp` (`$69EC`)

**EditUp**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,248 calls (`stage1/rec/menus` 1,241, `stage1/rec/city` 7) |
| Called from | `EditNumber` |
| Reads | `$6990`-`$6992` (`EditMax`, `EditPtr`); `$91E4` (`TaxRate`) |
| Writes | `$91E4` (`TaxRate`) |

### `EditDown` (`$69FA`)

**EditDown**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 45 calls (`stage1/rec/city` 25, `stage1/rec/bankrupt` 20) |
| Called from | `EditNumber` |
| Calls | `RunMenu` (tail), `PrintEditField` |
| Reads | `$6991`-`$6992` (`EditPtr`); `$91E4` (`TaxRate`) |
| Writes | `$91E4` (`TaxRate`) |

### `PrintEditField` (`$6A16`)

**Print the field's value in 3 digits at its position**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,842 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 106, `stage1/rec/bankrupt` 65) |
| Called from | `EditNumber`, `EditDown` |
| Calls | `ScreenAddr`, `Print3Digits` |
| Reads | `$6991`-`$6994` (`EditPtr`, `EditPos`); `$91E4` (`TaxRate`) |
| Writes | `$F74F`-`$F750` (`PrintAddr`) |

### `CallMenuHook` (`$6A2A`)

**JP (MenuHook) unless 0**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 95 t-states own (0.00 %) |
| Runs (the other recordings) | 1,959 calls (`stage1/rec/menus` 1,718, `stage1/rec/city` 114, `stage1/rec/bankrupt` 72 and 7 more) |
| Called from | `RunMenu`, `EditNumber` |
| Calls | `BudgetHook`, `Evaluate` |
| Reads | `$6942`-`$6943` (`MenuHook`) |

### `NumberRepeat` (`$6A31`)

**The key repeat: no key, delay 10; a key held, count it down**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 68 t-states own (0.00 %) |
| Runs (the other recordings) | 1,837 calls (`stage1/rec/menus` 1,669, `stage1/rec/city` 104, `stage1/rec/bankrupt` 64) |
| Called from | `RunMenu` (tail), `EditNumber` |
| Calls | `AnyKey`, `ShowMenu`, `BudgetWindow`, `EvaluationWindow`, `SaveCity`, `LoadCity`, `ChooseNuclear`, `ConfirmNo`, `ExitSimCity`, `AboutWindow`, `LoadMenu`, `SaveMenu`, `SpeedMenu`, `SetSpeedItem`, `PickDisaster`, `MapsItem`, `SetLevel`, `InputGene` |
| Reads | `$6995` (`EditRepeat`); `$92F2`-`$92F3` (`FirePercent+106`); `$972C`-`$972D` (`EvaluationText+341`); `$9F62`-`$9F63` (`PlantMenu+33`); `$9F84`-`$9F85` (`PlantMenu+67`); `$9FF6`-`$A092` (`ConfirmMenu+35`, `ConfirmNo`, `SystemMenu`); 13 more ranges |
| Writes | `$6995` (`EditRepeat`); `$A32B`-`$A32E` (`AutoBulldoze`, `AutoBudget`, `SoundOn`, `DemolishWait`); `$A43D` (`DisastersOff`) |

### `MenuUp` (`$6A54`)

**The highlight one item up**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 57 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/levels` 4) |
| Called from | `RunMenu` |
| Calls | `ToggleMenuLine` (falls into) |
| Reads | `$6A7D` (`MenuSelected`) |
| Writes | `$6A7D` (`MenuSelected`) |

### `ToggleMenuLine` (`$6A60`)

**XOR the highlight of the selected item's line**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 6 calls, 600 t-states own (0.00 %) |
| Runs (the other recordings) | 598 calls (`stage1/rec/menus` 273, `stage1/rec/bankrupt` 73, `stage1/rec/city` 48 and 7 more) |
| Called from | `RunMenu`, `EditNumber`, `MenuUp` (falls into), `MenuDown` (tail), `SetLevel`, `InputGene` |
| Calls | `HighlightLine`, `SelectedItem` |
| Reads | `$674A`-`$675C` (`MenuItems`) |

### `MenuDown` (`$6A6C`)

**The highlight one item down**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 83 t-states own (0.00 %) |
| Runs (the other recordings) | 304 calls (`stage1/rec/menus` 178, `stage1/rec/bankrupt` 31, `stage1/rec/growth` 22 and 7 more) |
| Called from | `RunMenu` |
| Calls | `ToggleMenuLine` (tail) |
| Reads | `$67C2` (`MenuCount`); `$6A7D` (`MenuSelected`) |
| Writes | `$6A7D` (`MenuSelected`) |

### `SelectedItem` (`$6A7E`)

**HL = MenuItems + 3 MenuSelected**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 626 t-states own (0.00 %) |
| Runs (the other recordings) | 743 calls (`stage1/rec/menus` 330, `stage1/rec/bankrupt` 85, `stage1/rec/city` 65 and 7 more) |
| Called from | `RunMenu`, `EditNumber`, `ToggleMenuLine` |
| Reads | `$6A7D` (`MenuSelected`) |

## landscape

`src/game/landscape.asm`

### `NewLandscape` (`$6A8E`)

**Make the landscape from Gene: the map all water, 128 land discs, the coasts, 32 tree discs**

Resets the simulation (StartSimulation `$830C`), clears CityMap `$C450` to 0 (water), shows "CREATING LANDSCAPE" (`$A6A4`), seeds Random with Gene, draws 128 discs of land (`$02`) with radius 2-7 at x, y 16-79 (Disc), cuts the coast (MakeCoast), then 32 discs of trees (`$06`) of radius 2-3 drawn only over land. L1 12 (the menus recording's genes 12345 and 00003, the level starts).

[Animation: `NewLandscape` at work](img/routines/NewLandscape.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 205,955 t-states own (0.01 %) |
| Runs (the other recordings) | 11 calls (`stage1/rec/menus` 4, `stage1/rec/levels` 2, `stage1/rec/bankrupt` 1 and 4 more) |
| Called from | `UiTask`, `ExitSimCity` (tail) |
| Calls | `ClearViewArea`, `ClearWindowArea`, `DrawMenu`, `Discs`, `MakeCoast`, `StartSimulation` |
| Reads | `$6A8C`-`$6A8D` (`Gene`); `$C450`-`$E84E` (`CityMap`) |
| Writes | `$5CC4`-`$5CC5` (`RandomSeed`); `$6C05`-`$6C06` (`DiscCell`, `DiscOver`); `$C450`-`$E84F` (`CityMap`) |

### `Discs` (`$6ADB`)

**B discs of cell C, radius 2 to E (random), centre 16-79, each with a random shape from DiscShapes**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 58,836 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/menus` 8, `stage1/rec/levels` 4, `stage1/rec/bankrupt` 2 and 4 more) |
| Called from | `NewLandscape` |
| Calls | `Random`, `Disc` |
| Reads | `$6AD3`-`$6ADA` (`DiscShapes`) |
| Writes | `$6AE8` (`DiscsLoop+5`); `$6C02`-`$6C08` (`DiscVars`, `DiscY`, `DiscRadius`, `DiscCell` and 2 more) |

### `MakeCoast` (`$6BA5`)

**Every water cell next to land whose neighbour mask is in CoastPatterns becomes its coast cell**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 2,259,445 t-states own (0.15 %) |
| Runs (the other recordings) | 11 calls (`stage1/rec/menus` 4, `stage1/rec/levels` 2, `stage1/rec/bankrupt` 1 and 4 more) |
| Called from | `NewLandscape` |
| Calls | `MapAddrChecked`, `LandNeighbours` |
| Reads | `$6B21`-`$6BA4` (`CoastPatterns`, `CoastCells`); `$C4B1`-`$E84F` (`CityMap+97`) |
| Writes | `$C760`-`$C7FD` (`CityMap+784`); `$C828` (`CityMap+984`); `$C853`-`$D9BE` (`CityMap+1027`); `$D9FC`-`$DA1F` (`CityMap+5548`); `$DA5D`-`$E477` (`CityMap+5645`) |

### `MapAddrChecked` (`$6BDB`)

**HL = CityMap + 96 B + C for row B, column C below 96 (carry set); else carry clear**

L1 2 928 251.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 98,175 calls, 5,044,853 t-states own (0.34 %) |
| Runs (the other recordings) | 2,830,076 calls (`stage1/rec/metro` 726,824, `stage1/rec/city` 437,394, `stage1/rec/city2` 425,624 and 7 more) |
| Called from | `MakeCoast`, `Disc`, `IsLand`, `IsNetwork`, `DrawMovers`, `Irradiate`, `MoveTornado`, `ScanRingCell`, `ScanInsideCell`, `IsConductive`, `Interrupt` |
| Calls | `MapAddr` (falls into) |
| Writes | `$6BDA` (`MapEdge`) |

### `MapAddr` (`$6BE6`)

**HL = CityMap + 96 B + C**

L1 3 488 641.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 99,199 calls, 18,182,738 t-states own (1.21 %) |
| Runs (the other recordings) | 3,389,442 calls (`stage1/rec/metro` 958,639, `stage1/rec/city2` 559,629, `stage1/rec/city` 538,535 and 7 more) |
| Called from | `DrawViewRowPass`, `DrawView`, `MapAddrChecked` (falls into), `ClickMapAddr` (tail), `FixNetworkCell`, `PutZoneBuilding`, `NeighbourAddr`, `MoveTrain`, `StartTornado`, `MoveTornado`, `MakeTrip`, `Spread`, `GrowCell`, `DeclineCell`, `ComRevert`, `IndRevert`, `Interrupt` |
| Calls | `DrawMovers` |

### `Disc` (`$6C09`)

**Draw a disc of DiscCell: 49 steps of a shift-based circle, each a horizontal run across it**

The run's ends come from the circle drawing x -= y >> s1, y += x >> s2 (the two shifts of DiscShapes), in 8.8 fixed point from (radius, 0): an ellipse when the shifts differ. L1 1920.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 160 calls, 11,949,707 t-states own (0.79 %) |
| Runs (the other recordings) | 1,760 calls (`stage1/rec/menus` 640, `stage1/rec/levels` 320, `stage1/rec/city` 160 and 4 more) |
| Called from | `Discs` |
| Calls | `MapAddrChecked` |
| Reads | `$6C02`-`$6C08` (`DiscVars`, `DiscY`, `DiscRadius`, `DiscCell` and 2 more); `$6C1B` (`DiscX1+2`); `$C948`-`$CEAA` (`CityMap+1272`); `$CF08`-`$CF0B` (`CityMap+2744`); `$CF4B`-`$CF6C` (`CityMap+2811`); `$CFA8`-`$D0FD` (`CityMap+2904`); 1 more ranges |
| Writes | `$6C1A`-`$6C1E` (`DiscX1+1`, `DiscY1`); `$C761`-`$C762` (`CityMap+785`); `$C797`-`$C79A` (`CityMap+839`); `$C7C0`-`$C7C3` (`CityMap+880`); `$C7F5`-`$C827` (`CityMap+933`); `$C854`-`$C889` (`CityMap+1028`); 2 more ranges |

### `IsLand` (`$6C75`)

**Carry set when the cell at row B, column C is on the map and holds land (`$02`)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 36,264 calls, 3,298,982 t-states own (0.22 %) |
| Runs (the other recordings) | 402,744 calls (`stage1/rec/menus` 147,680, `stage1/rec/levels` 73,744, `stage1/rec/bankrupt` 36,264 and 4 more) |
| Called from | `LandNeighbours` |
| Calls | `MapAddrChecked` |
| Reads | `$C450`-`$CCCA` (`CityMap`); `$CCDB`-`$DFBC` (`CityMap+2187`); `$DFD4`-`$E01B` (`CityMap+7044`); `$E034`-`$E07A` (`CityMap+7140`); `$E094`-`$E0DB` (`CityMap+7236`); `$E0F4`-`$E84F` (`CityMap+7332`) |

### `LandNeighbours` (`$6C84`)

**D = the land bits of the eight neighbours of (B, C), the row above first**

L1 54 876.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 4,533 calls, 1,562,252 t-states own (0.10 %) |
| Runs (the other recordings) | 50,343 calls (`stage1/rec/menus` 18,460, `stage1/rec/levels` 9,218, `stage1/rec/bankrupt` 4,533 and 4 more) |
| Called from | `MakeCoast` |
| Calls | `IsLand` |

## tools

`src/game/tools.asm`

### `ScrollClick` (`$6CBF`)

**A click on row 2, column 0: scroll the view with the keys until SPACE (not run in any recording)**

ScrollMode: O, P, Q, A scroll by a cell a frame, the view redrawn each time, until SPACE. No recording clicked there (L1 - from `$6CCA`; the scroll of the recordings goes through CAPS SHIFT + 5-8, ShiftScroll `$7A6F`; the pointer at the view's edge only redraws the view, it does not scroll).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 12 calls, 547 t-states own (0.00 %) |
| Runs (the other recordings) | 597 calls (`stage1/rec/city` 160, `stage1/rec/metro` 152, `stage1/rec/menus` 99 and 7 more) |
| Called from | `Click` |
| Reads | `$63C9`-`$63CA` (`ClickCell`) |

### `ScrollLeft` (`$6D05`)

**ViewCol - 1 down to 0**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/tools` 3) |
| Called from | `ShiftScroll` |
| Reads | `$6507` (`ViewCol`) |
| Writes | `$6507` (`ViewCol`) |

### `ScrollRight` (`$6D0F`)

**ViewCol + 1 up to 63**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20 calls (`stage1/rec/metro` 17, `stage1/rec/tools` 3) |
| Called from | `ShiftScroll` |
| Reads | `$6507` (`ViewCol`) |
| Writes | `$6507` (`ViewCol`) |

### `ScrollUp` (`$6D19`)

**ViewRow - 1 down to 0**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/tools` 3) |
| Called from | `ShiftScroll` |
| Reads | `$6508` (`ViewRow`) |
| Writes | `$6508` (`ViewRow`) |

### `ScrollDown` (`$6D23`)

**ViewRow + 1 up to 79**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 19 calls (`stage1/rec/metro` 16, `stage1/rec/tools` 3) |
| Called from | `ShiftScroll` |
| Reads | `$6508` (`ViewRow`) |
| Writes | `$6508` (`ViewRow`) |

### `ToolKeys` (`$6D2D`)

**SYMBOL SHIFT with a digit picks a tool: 1-9 tools 0-8, 0 tool 9**

L1 158 072; 30 with SYMBOL SHIFT (the tools recording's shortcuts).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 121,921 t-states own (0.01 %) |
| Runs (the other recordings) | 156,323 calls (`stage1/rec/metro` 38,782, `stage1/rec/city2` 34,790, `stage1/rec/city` 31,397 and 7 more) |
| Called from | `UiTask`, `Interrupt` |
| Calls | `KeyToChar`, `ToolClick` (tail), `UiTask` |
| Reads | `$5B00`-`$5B07` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 4 more); `$6D50` (`CurrentTool`); `$8F97`-`$8F99` (`Funds`) |
| Writes | `$6D50` (`CurrentTool`) |

### `ToolClick` (`$6D51`)

**A click on the palette (rows 1-2, columns 2-29) picks tool (column - 2) / 2**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 12 calls, 850 t-states own (0.00 %) |
| Runs (the other recordings) | 597 calls (`stage1/rec/city` 160, `stage1/rec/metro` 152, `stage1/rec/menus` 99 and 7 more) |
| Called from | `DrawToolIcons`, `Click`, `WaitSpaceUp`, `ToolKeys` (tail) |
| Calls | `DrawToolIcons`, `PrintToolName`, `Click`, `WaitSpaceUp`, `Sub24`, `ToolPrice`, `UiTask` |
| Reads | `$63C9`-`$63CA` (`ClickCell`); `$6D50` (`CurrentTool`); `$8F97`-`$8F99` (`Funds`) |
| Writes | `$6D50` (`CurrentTool`) |

### `ShowTool` (`$6D90`)

**Highlight the current tool's icon and set the map box to its size (ToolSizes)**

L1 649.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5 calls, 1,510 t-states own (0.00 %) |
| Runs (the other recordings) | 619 calls (`stage1/rec/city` 172, `stage1/rec/metro` 166, `stage1/rec/growth` 91 and 7 more) |
| Called from | `InvertBox`, `DrawStatusItems`, `PrintToolName`, `GreyUnaffordable`, `FundsChanged` (tail), `Interrupt` |
| Calls | `InvertBox`, `Click`, `ToolSize`, `GreyUnaffordable`, `UiTask` |
| Reads | `$6D50` (`CurrentTool`) |
| Writes | `$5D4F`-`$5D50` (`BoxSize`) |

### `ToolSize` (`$6DCB`)

**DE = ToolSizes[CurrentTool]**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 9 calls, 889 t-states own (0.00 %) |
| Runs (the other recordings) | 1,247 calls (`stage1/rec/city` 352, `stage1/rec/metro` 338, `stage1/rec/growth` 180 and 7 more) |
| Called from | `ShowTool`, `CheckSite`, `PutBuilding` |
| Reads | `$6D50` (`CurrentTool`); `$6DAF`-`$6DCA` (`ToolSizes`) |

### `GreyUnaffordable` (`$6DDA`)

**Grey the palette icon of every tool whose price is more than Funds**

For the 14 tools: Funds - ToolPrice < 0 (Sub24) greys the icon (GreyIcon). Input: none. Side effect: the palette's pixels. L1 649.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 7 calls, 17,103 t-states own (0.00 %) |
| Runs (the other recordings) | 642 calls (`stage1/rec/city` 174, `stage1/rec/metro` 168, `stage1/rec/growth` 94 and 7 more) |
| Called from | `Sub24`, `ShowTool`, `GreyIcon`, `ToolPrice`, `Interrupt` |
| Calls | `Sub24`, `ShowTool`, `GreyIcon`, `ToolPrice` |
| Reads | `$8F97`-`$8F99` (`Funds`) |

### `GreyIcon` (`$6DFD`)

**AND a checker (`$AA` / `$55`) into the 2 x 2 icon of tool C (row 1, column 2 + 2 C)**

L1 196.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 196 calls (`stage1/rec/bankrupt` 92, `stage1/rec/tools` 72, `stage1/rec/ports` 17 and 2 more) |
| Called from | `NextPixelLine`, `GreyUnaffordable`, `Interrupt` |
| Calls | `ScreenAddr`, `NextPixelLine`, `GreyUnaffordable` |
| Reads | `$4022`-`$415D` (screen); `$4222`-`$425D` (screen); `$4322`-`$435D` (screen); `$4422`-`$445D` (screen); `$4522`-`$455D` (screen); `$4622`-`$465D` (screen); 1 more ranges |
| Writes | `$4022`-`$405D` (screen); `$4122`-`$415D` (screen); `$4222`-`$425D` (screen); `$4322`-`$435D` (screen); `$4422`-`$445D` (screen); `$4522`-`$455D` (screen); 2 more ranges |

### `ToolPrice` (`$6E3A`)

**DE = ToolPrices[A]**

L1 9176 (GreyUnaffordable and SelectTool).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 103 calls, 8,819 t-states own (0.00 %) |
| Runs (the other recordings) | 9,075 calls (`stage1/rec/city` 2,447, `stage1/rec/metro` 2,364, `stage1/rec/growth` 1,326 and 7 more) |
| Called from | `ToolClick`, `GreyUnaffordable`, `Interrupt` |
| Calls | `GreyUnaffordable` |
| Reads | `$6E1E`-`$6E39` (`ToolPrices`); `$6E7E`-`$6E7F` (`ClickToMapBC+6`) |

### `Spend` (`$6E46`)

**Funds = Funds - DE, unless that goes below 0: then carry set and Funds kept**

Every tool pays through here. Input: DE the price. Output: carry set when refused (nothing paid). L1 693.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 216 t-states own (0.00 %) |
| Runs (the other recordings) | 692 calls (`stage1/rec/metro` 256, `stage1/rec/city` 181, `stage1/rec/growth` 89 and 4 more) |
| Called from | `CrossNetwork`, `CheckSite`, `PlaceNetwork`, `Bulldoze`, `ParkTool`, `ResidentialTool`, `CommercialTool`, `IndustrialTool`, `PoliceTool`, `FireTool`, `StadiumTool`, `PowerPlantTool`, `SeaportTool`, `AirportTool` |
| Calls | `Sub24` |
| Reads | `$8F97`-`$8F99` (`Funds`) |
| Writes | `$8F97`-`$8F99` (`Funds`) |

### `ClickMapAddr` (`$6E6A`)

**BC = the clicked map cell (ClickToMap), kept in ClickMapCell; HL = its map address**

L1 1713.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 226 t-states own (0.00 %) |
| Runs (the other recordings) | 1,710 calls (`stage1/rec/city` 531, `stage1/rec/metro` 499, `stage1/rec/growth` 243 and 4 more) |
| Called from | `CrossNetwork`, `CheckSite`, `PutBuilding`, `PlaceNetwork`, `Bulldoze`, `ParkTool` |
| Calls | `MapAddr` (tail), `ClickToMap` |
| Writes | `$6E67`-`$6E68` (`ClickMapCell`) |

### `ClickToMap` (`$6E74`)

**BC = the map cell under ClickCell: column + ViewCol, row - 8 + ViewRow**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 430 t-states own (0.00 %) |
| Runs (the other recordings) | 1,710 calls (`stage1/rec/city` 531, `stage1/rec/metro` 499, `stage1/rec/growth` 243 and 4 more) |
| Called from | `ClickMapAddr` |
| Calls | `ClickToMapBC` (falls into) |
| Reads | `$63C9`-`$63CA` (`ClickCell`); `$6507`-`$6508` (`ViewCol`, `ViewRow`); `$6E69` (`MapCoordsGiven`) |

### `ClickToMapBC` (`$6E78`)

**BC (a view cell, screen row) to the map cell, unless MapCoordsGiven**

L1 3978.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,904 calls (`stage1/rec/city` 1,281, `stage1/rec/metro` 1,193, `stage1/rec/growth` 564 and 3 more) |
| Called from | `ClickToMap` (falls into), `FixNetworkCell` |
| Reads | `$6507`-`$6508` (`ViewCol`, `ViewRow`); `$6E69` (`MapCoordsGiven`) |

### `FixNetworkAt` (`$6E8A`)

**FixNetwork round map cell BC (MapCoordsGiven set while it runs)**

Used by the bridge (L1 - : no recording built a bridge).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FixNetworkClick` (`$6E97`)

**FixNetwork round the clicked cell**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 324 calls (`stage1/rec/city` 106, `stage1/rec/metro` 98, `stage1/rec/menus` 46 and 3 more) |
| Called from | `CrossNetwork`, `PlaceNetwork`, `Bulldoze` |
| Reads | `$63C9`-`$63CA` (`ClickCell`) |
| Writes | `$6F10` (`NetworkFlag`) |

### `FixNetwork` (`$6E9B`)

**Re-shape the network cells of kind NetworkKind at BC and its four neighbours**

A road, rail or power line cell takes the shape (kind + NetworkShapes[mask]) of the neighbours of its own kind (the 4-bit mask of NeighbourMask). Input: BC, NetworkKind. Side effect: the map. L1 324.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `NetworkBit`, `FixNetworkCell` |

### `NetworkBit` (`$6EBE`)

**A = the CellFlags bit that marks the kind as crossable: road (7) 4, rail (`$14`) 2, power (`$21`) 8**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 324 calls (`stage1/rec/city` 106, `stage1/rec/metro` 98, `stage1/rec/growth` 46 and 3 more) |
| Called from | `FixNetwork` |
| Reads | `$6ED2` (`NetworkKind`) |

### `FixNetworkCell` (`$6EE3`)

**The cell at BC: when it is of NetworkKind, make it kind + its shape (not when CellFlags bit 0 keeps it)**

L1 1620.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,620 calls (`stage1/rec/city` 530, `stage1/rec/metro` 490, `stage1/rec/menus` 230 and 3 more) |
| Called from | `FixNetwork` |
| Calls | `MapAddr`, `ClickToMapBC`, `IsNetwork`, `NeighbourMask`, `CellFlagsOf` |
| Reads | `$6ED2`-`$6EE2` (`NetworkKind`, `NetworkShapes`); `$D24E`-`$D48F` (`CityMap+3582`); `$D4EE`-`$D4F5` (`CityMap+4254`); `$D54E`-`$D568` (`CityMap+4350`); `$D5AE`-`$D5C3` (`CityMap+4446`); `$D60E`-`$D66F` (`CityMap+4542`); 11 more ranges |
| Writes | `$D24E`-`$D48E` (`CityMap+3582`); `$D4EE` (`CityMap+4254`); `$D54E`-`$D568` (`CityMap+4350`); `$D5AE`-`$D5C3` (`CityMap+4446`); `$D60E`-`$D66E` (`CityMap+4542`); `$D6CE` (`CityMap+4734`); 10 more ranges |

### `IsNetwork` (`$6F12`)

**Carry set when the cell at BC is of NetworkKind (kind to kind + 10) or (not BridgeMode) crossable by its flags**

L1 4200.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,200 calls (`stage1/rec/city` 1,410, `stage1/rec/metro` 1,306, `stage1/rec/growth` 594 and 3 more) |
| Called from | `FixNetworkCell`, `NeighbourMask` |
| Calls | `MapAddrChecked`, `CellFlagsOf` |
| Reads | `$6ED2` (`NetworkKind`); `$6F10`-`$6F11` (`NetworkFlag`, `BridgeMode`); `$D1EE`-`$D1EF` (`CityMap+3486`); `$D24D`-`$D495` (`CityMap+3581`); `$D4ED`-`$D508` (`CityMap+4253`); `$D54D`-`$D569` (`CityMap+4349`); 7 more ranges |

### `NeighbourMask` (`$6F3C`)

**D = 4 bits: IsNetwork of the cells up, left, right, down of BC**

L1 645.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 645 calls (`stage1/rec/city` 220, `stage1/rec/metro` 204, `stage1/rec/growth` 91 and 3 more) |
| Called from | `FixNetworkCell` |
| Calls | `IsNetwork` |

### `BridgeLine` (`$6F5F`)

**From the click, step (D, E) over water writing BridgeCell, each cell paid at BridgePrice**

Stops with carry clear on a cell of BulldozeKeep (a coast or bridge end); carry set on anything else not water (the bridge refused). The first pass (BridgeCell 0) only tests; the second writes. L1 - (no recording built a bridge): known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MapClick` (`$7012`)

**A click on the view with the box shown: the crossing, the site check, the tool's routine**

Only for ClickCell rows 8 and up with BoxShown. A road, rail or power line over another network goes to CrossNetwork; else CheckSite refuses (Refuse) or the tool's handler from ToolHandlers runs (a CALL whose operand ToolCall is written). Then it waits for SPACE up, unless a direction key is held: the drag that lays a road cell by cell. L1 607.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 12 calls, 918 t-states own (0.00 %) |
| Runs (the other recordings) | 595 calls (`stage1/rec/city` 160, `stage1/rec/metro` 151, `stage1/rec/menus` 98 and 7 more) |
| Called from | `Click` |
| Calls | `CrossNetwork`, `CheckSite`, `Refuse`, `Bulldoze`, `RoadTool`, `RailTool`, `PowerLineTool`, `ParkTool`, `ResidentialTool`, `CommercialTool`, `IndustrialTool`, `PoliceTool`, `FireTool`, `StadiumTool`, `PowerPlantTool`, `SeaportTool`, `AirportTool` |
| Reads | `$5B01`-`$5B07` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 3 more); `$5D54` (`BoxShown`); `$63CA` (`ClickCell+1`); `$6D50` (`CurrentTool`); `$6FF6`-`$7011` (`ToolHandlers`) |
| Writes | `$7040`-`$7041` (`ToolCall+1`) |

### `CrossNetwork` (`$7086`)

**A road, rail or power line clicked on another network: pay, write the crossing cell, reshape; carry set when done**

Road 10, rail 20, power 5. L1 470; the crossings themselves L1 47 (`$70E3`, power).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 157 t-states own (0.00 %) |
| Runs (the other recordings) | 469 calls (`stage1/rec/city` 143, `stage1/rec/metro` 135, `stage1/rec/growth` 67 and 4 more) |
| Called from | `MapClick` |
| Calls | `DrawView`, `Spend`, `ClickMapAddr`, `FixNetworkClick` |
| Reads | `$6D50` (`CurrentTool`); `$7062`-`$707F` (`Crossings`); `$D24E`-`$D48E` (`CityMap+3582`); `$D4EE` (`CityMap+4254`); `$D54E`-`$D568` (`CityMap+4350`); `$D5AE`-`$D5C3` (`CityMap+4446`); 14 more ranges |
| Writes | `$6ED2` (`NetworkKind`); `$D36E` (`CityMap+3870`); `$D3D5` (`CityMap+3973`); `$D555` (`CityMap+4357`); `$D60E` (`CityMap+4542`); `$D97F` (`CityMap+5423`); 1 more ranges |

### `CheckSite` (`$7103`)

**Carry set when the tool's box at the click may not be built; clears trees at 1 dollar a cell**

On water, or with AutoBulldoze (`$A32B`) on: every cell of the box must be in SiteCells (water only for road, rail and power); each cell not in FreeCells costs 1 and becomes land 2. With AutoBulldoze off and a clicked cell that is not water: StrictSite, every cell must be land 2. That jump comes before the bulldozer's test at `$7118`, so with AUTO-BULLDOZE off the bulldozer is refused everywhere but on a water click; with AutoBulldoze on, or on water, it always passes. When Spend cannot pay 1 for clearing a cell, the cell is left as it is and the site still passes. L1 464.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 3,120 t-states own (0.00 %) |
| Runs (the other recordings) | 463 calls (`stage1/rec/city` 141, `stage1/rec/metro` 133, `stage1/rec/growth` 65 and 4 more) |
| Called from | `MapClick` |
| Calls | `ToolSize`, `Spend`, `ClickMapAddr` |
| Reads | `$6D50` (`CurrentTool`); `$70FA`-`$7102` (`FreeCells`, `SiteCells`, `SiteWater`); `$A32B` (`AutoBulldoze`); `$D24E`-`$D4AD` (`CityMap+3582`); `$D4EE`-`$D6E9` (`CityMap+4254`); `$D72E`-`$D749` (`CityMap+4830`); 5 more ranges |
| Writes | `$7102` (`SiteWater`); `$7137` (`CheckSiteRow+2`); `$D24E` (`CityMap+3582`); `$D2AE`-`$D2AF` (`CityMap+3678`); `$D30E`-`$D30F` (`CityMap+3774`); `$D36E`-`$D37E` (`CityMap+3870`); 12 more ranges |

### `PutBuilding` (`$7197`)

**Copy the building pattern at IX (ToolSize width x height) into the map at the click**

L1 145.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 1,127 t-states own (0.00 %) |
| Runs (the other recordings) | 144 calls (`stage1/rec/metro` 37, `stage1/rec/city` 37, `stage1/rec/bankrupt` 23 and 4 more) |
| Called from | `ResidentialTool`, `CommercialTool`, `IndustrialTool`, `PoliceTool`, `FireTool`, `StadiumTool`, `PowerPlantTool`, `SeaportTool`, `AirportTool`, `ComRevert` (tail), `IndRevert` (tail) |
| Calls | `ToolSize`, `ClickMapAddr`, `ZoneStep` |
| Reads | `$73F1`-`$742D` (`ResidentialZone`, `ResidentialTool`, `CommercialZone`, `CommercialTool` and 1 more); `$743F`-`$7447` (`PoliceBuilding`); `$7459`-`$7461` (`FireBuilding`); `$7473`-`$7482` (`StadiumBuilding`); `$7494`-`$74B3` (`CoalPlant`, `NuclearPlant`); `$74E6`-`$74F5` (`SeaportBuilding`); 3 more ranges |
| Writes | `$71A5` (`PutBuildingRow+2`); `$D24F`-`$D4AD` (`CityMap+3583`); `$D4EF`-`$D749` (`CityMap+4255`); `$D860`-`$D93A` (`CityMap+5136`); `$D9E0`-`$D9FA` (`CityMap+5520`); `$DA40`-`$DA5A` (`CityMap+5616`); 3 more ranges |

### `PlaceNetwork` (`$71BC`)

**Lay one cell of road, rail or power: HL the price, DE the bridge price, A the kind**

On water the Bridge; on land (2) pay, write the kind, FixNetwork, redraw; on anything else Refuse. L1 312.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 312 calls (`stage1/rec/city` 104, `stage1/rec/metro` 96, `stage1/rec/menus` 46 and 3 more) |
| Called from | `RoadTool` (tail), `RailTool` (tail), `PowerLineTool` (tail) |
| Calls | `DrawView` (tail), `Spend`, `ClickMapAddr`, `FixNetworkClick` |
| Reads | `$6ED2` (`NetworkKind`); `$71B8`-`$71B9` (`NetPrice`); `$D24E`-`$D48E` (`CityMap+3582`); `$D4EE` (`CityMap+4254`); `$D54E`-`$D568` (`CityMap+4350`); `$D5AE`-`$D5C3` (`CityMap+4446`); 12 more ranges |
| Writes | `$6ED2` (`NetworkKind`); `$71B8`-`$71BB` (`NetPrice`, `BridgePrice`); `$D24E`-`$D48E` (`CityMap+3582`); `$D4EE` (`CityMap+4254`); `$D54E`-`$D568` (`CityMap+4350`); `$D5AE`-`$D5C3` (`CityMap+4446`); 12 more ranges |

### `Refuse` (`$71E4`)

**The refusal: ToneBeep, but only when no direction key (A, Q, P, O) is held**

Three refusals beep: MapClick's after CheckSite (the site), PlaceNetwork's (a network on a building or a zone) and ParkTool's (map column 2); while the pointer is dragged with a key held the beep is left out. L1 3: 2 in tools, 1 in bankrupt.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/tools` 2, `stage1/rec/bankrupt` 1) |
| Called from | `MapClick` |
| Calls | `ToneBeep` (tail) |
| Reads | `$5B01`-`$5B05` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 1 more) |

### `Bridge` (`$721E`)

**A network clicked on water: find the direction from the network next to it, test the line, then build it**

The cost is BridgePrice a cell (road 50, rail 100, power 25). Two BridgeLine passes: a dry run, then with kind + offset. L1 - : known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Bulldoze` (`$7276`)

**Tool 0: clear the clicked cell**

A building goes to BulldozeBuilding, a zone centre (`$51-$56`) to BulldozeZone, a bridge to water (`$72CA`), cells `$3C-$50` through the flags to rubble or land, the rest to land 2 at 1 dollar, then the networks round it are reshaped. L1 2.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/tools` 2) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `ClickMapAddr`, `FixNetworkClick` |
| Reads | `$726B`-`$7275` (`BulldozeKeep`, `BulldozeNothing`); `$D3DD`-`$D3DE` (`CityMap+3981`) |
| Writes | `$6ED2` (`NetworkKind`); `$D3DD`-`$D3DE` (`CityMap+3981`) |

### `ConfirmHold` (`$72ED`)

**With ZONE DEMOLISH WAIT (`$A32E`, on in the image): Z only when SPACE is held through 40 000 loops; NZ at once when it is up**

Clearing a building or a zone needs SPACE held about a second; with the option off it goes at once. L1 - (no recording bulldozed a building or zone): known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BulldozeBuilding` (`$7308`)

**Clear a whole building: find its top row, pay size squared, fill it with rubble `$46`, animate**

L1 - (no recording bulldozed a building): known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BulldozeZone` (`$7367`)

**a zone: 9, its 3 x 3 from the cell up and left**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RubbleStep` (`$7383`)

**Advance every rubble cell of the 12 rows round the click one step (RubbleSteps)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RoadTool` (`$73B2`)

**Tool 1: PlaceNetwork with 10, bridge 50, cell 7**

L1 at the click only (no entry count kept: reached through ToolHandlers).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 269 calls (`stage1/rec/city` 92, `stage1/rec/metro` 84, `stage1/rec/menus` 46 and 2 more) |
| Called from | `MapClick` |
| Calls | `PlaceNetwork` (tail) |

### `RailTool` (`$73BD`)

**Tool 3: 20, bridge 100, cell `$14`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/tools` 2) |
| Called from | `MapClick` |
| Calls | `PlaceNetwork` (tail) |

### `PowerLineTool` (`$73C8`)

**Tool 2: 5, bridge 25, cell `$21`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 41 calls (`stage1/rec/ports` 15, `stage1/rec/metro` 12, `stage1/rec/city` 12 and 1 more) |
| Called from | `MapClick` |
| Calls | `PlaceNetwork` (tail) |

### `ParkTool` (`$73D4`)

**Tool 4: 10, a park `$38` (one in eight `$39`); refused (Refuse) when the map column is 2**

The CP `$02` tests A, which ClickMapAddr leaves as the column (MapAddr's LD A,C), not the cell: a park on map column 2 always beeps, any other site takes the park (CheckSite has cleared it already). Known only from the code; L1 1.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/tools` 1) |
| Called from | `MapClick` |
| Calls | `Random`, `DrawView` (tail), `Spend`, `ClickMapAddr` |
| Writes | `$D31A` (`CityMap+3786`) |

### `ResidentialTool` (`$73FA`)

**Tool 5: 100, the zone at the click**

L1 77.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 77 calls (`stage1/rec/bankrupt` 23, `stage1/rec/metro` 18, `stage1/rec/city` 17 and 3 more) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

### `CommercialTool` (`$7414`)

**Tool 6: 100**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage1/rec/metro` 8, `stage1/rec/city` 8, `stage1/rec/menus` 3 and 2 more) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

### `IndustrialTool` (`$742E`)

**Tool 7: 100**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 114 t-states own (0.00 %) |
| Runs (the other recordings) | 23 calls (`stage1/rec/metro` 8, `stage1/rec/city` 8, `stage1/rec/menus` 3 and 2 more) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

### `PoliceTool` (`$7448`)

**Tool 8: 500**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/metro` 1, `stage1/rec/tools` 1, `stage1/rec/menus` 1 and 2 more) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

### `FireTool` (`$7462`)

**Tool 9: 500**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/city` 1, `stage1/rec/metro` 1, `stage1/rec/growth` 1 and 2 more) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

### `StadiumTool` (`$7483`)

**Tool 10: 3000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/city` 1, `stage1/rec/ports` 1) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

### `PowerPlantTool` (`$74B4`)

**Tool 11: when the low 16 bits of Funds are 3000 or more (LD HL,(Funds): the high byte is ignored), the menu `$9F41` asks coal (3000) or nuclear (5000); SelectTool already refused it below the palette's 4000**

L1 8.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/tools` 3, `stage1/rec/growth` 1, `stage1/rec/city` 1 and 3 more) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `ShowMenu`, `Spend`, `PutBuilding` |
| Reads | `$8F97`-`$8F98` (`Funds`); `$9F40` (`PlantChoice`) |

### `SeaportTool` (`$74F6`)

**Tool 12: 5000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/ports` 1) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

### `AirportTool` (`$752B`)

**Tool 13: 10 000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/tools` 1) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

## cityaccess

`src/game/cityaccess.asm`

### `Grid48` (`$753E`)

**A = GridBase[48 (B / 2) + C / 2]: a 48 x 48 array over 2 x 2 cells**

HL its address. L1 763 487.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 762,097 calls (`stage1/rec/metro` 240,252, `stage1/rec/city2` 219,301, `stage1/rec/city` 192,736 and 4 more) |
| Called from | `PollutionAt` (tail), `TrafficAt` (tail), `LayerOf`, `Interrupt` |
| Calls | `RoadTraffic` |
| Reads | `$753C`-`$753D` (`GridBase`); `$ADD0`-`$B126` (`Pollution`); `$B145`-`$B425` (`Pollution+885`); `$B6D0`-`$B897` (`Traffic`); `$BA70`-`$BB9E` (`Traffic+928`); `$BBF8`-`$BC35` (`Traffic+1320`); 1 more ranges |

### `Grid24` (`$755A`)

**A = GridBase[24 (B / 4) + C / 4]: a 24 x 24 array over 4 x 4 cells**

L1 40 571.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 39,049 calls (`stage1/rec/metro` 16,026, `stage1/rec/city2` 9,902, `stage1/rec/city` 6,268 and 3 more) |
| Called from | `PoliceAt` (tail), `FireAt` (tail), `LayerOf` |
| Reads | `$753C`-`$753D` (`GridBase`); `$A950`-`$A9BB` (`FireCover`); `$AA65` (`FireCover+277`); `$AA7A` (`FireCover+298`); `$AADF` (`FireCover+399`); `$AB90`-`$ABFB` (`PoliceCover`); 7 more ranges |

### `PollutionAt` (`$7579`)

**Grid48 of Pollution `$ADD0`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 55,020 calls (`stage1/rec/metro` 23,596, `stage1/rec/city2` 13,179, `stage1/rec/city` 10,252 and 6 more) |
| Called from | `StampPollutionIX`, `ZonePollution` |
| Calls | `Grid48` (tail) |
| Reads | `$753C`-`$753D` (`GridBase`); `$B14B` (`Pollution+891`); `$B171`-`$B17B` (`Pollution+929`); `$B1D2`-`$B1DB` (`Pollution+1026`); `$B231`-`$B23B` (`Pollution+1121`) |
| Writes | `$753C`-`$753D` (`GridBase`) |

### `TrafficAt` (`$7581`)

**Grid48 of Traffic `$B6D0`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 693,155 calls (`stage1/rec/metro` 213,632, `stage1/rec/city2` 203,098, `stage1/rec/city` 182,484 and 4 more) |
| Called from | `RoadTraffic`, `ZoneTraffic`, `AddTripTraffic` |
| Calls | `Grid48` (tail) |
| Writes | `$753C`-`$753D` (`GridBase`) |

### `PoliceAt` (`$7589`)

**Grid24 of PoliceCover `$AB90`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,484 calls (`stage1/rec/metro` 13,724, `stage1/rec/city2` 7,735, `stage1/rec/city` 6,227 and 6 more) |
| Called from | `StampPolice`, `CrimeOf` |
| Calls | `Grid24` (tail) |
| Reads | `$753C`-`$753D` (`GridBase`); `$AC70`-`$AC75` (`PoliceCover+224`); `$AC89`-`$AC8D` (`PoliceCover+249`); `$ACA0`-`$ACA5` (`PoliceCover+272`); `$ACB9` (`PoliceCover+297`) |
| Writes | `$753C`-`$753D` (`GridBase`) |

### `FireAt` (`$7591`)

**Grid24 of FireCover `$A950`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 943 calls (`stage1/rec/disasters` 718, `stage1/rec/metro` 94, `stage1/rec/city2` 55 and 2 more) |
| Called from | `StampFire`, `FireCell` |
| Calls | `Grid24` (tail) |
| Writes | `$753C`-`$753D` (`GridBase`) |

### `CellFlagsOf` (`$7599`)

**A = CellFlags[A] for a cell below `$80`, `$99` for a building byte**

L1 11 343 551, the most run routine.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 154,012 calls, 24,185,437 t-states own (1.61 %) |
| Runs (the other recordings) | 11,189,539 calls (`stage1/rec/metro` 2,419,048, `stage1/rec/city2` 2,316,302, `stage1/rec/city` 2,217,057 and 7 more) |
| Called from | `FixNetworkCell`, `IsNetwork`, `BuildingValue`, `MoveTrain`, `MoveTornado`, `ScanRingCell`, `ScanInsideCell`, `IsConductive`, `MakeTrip`, `TripStep`, `CellStep`, `Spread`, `GrowCell`, `DeclineCell`, `Ignite`, `LayerOf`, `Interrupt` |
| Calls | `Ignite` |
| Reads | `$6F9C`-`$6FF5` (`CellFlags`) |
| Writes | `$8F97`-`$8F98` (`Funds`) |

### `PutZoneBuilding` (`$75B0`)

**Write a 3 x 3 building of tile base DE + 9 A at the map address HL's cell: rows `$B3`, `$83`, `$83`**

The zones' growth writes its buildings here. L1 3235.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,235 calls (`stage1/rec/metro` 1,481, `stage1/rec/city2` 871, `stage1/rec/city` 646 and 2 more) |
| Called from | `ComBuildingStep` (tail), `IndBuildingStep` |
| Calls | `MapAddr`, `WriteBuildingRow`, `ZoneStep` |

### `WriteBuildingRow` (`$75CD`)

**One row: A, then the three tile bytes `$C0` | (n >> 3) and `$C0` | (n AND 7) pairs; HL the next row**

L1 9705.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,705 calls (`stage1/rec/metro` 4,443, `stage1/rec/city2` 2,613, `stage1/rec/city` 1,938 and 2 more) |
| Called from | `PutZoneBuilding` |
| Writes | `$D3CF`-`$D4A9` (`CityMap+3967`); `$D4F4`-`$D505` (`CityMap+4260`); `$D66F`-`$D749` (`CityMap+4639`); `$D9E0`-`$DA5A` (`CityMap+5520`); `$DAA0`-`$DABA` (`CityMap+5712`); `$DC80`-`$DC9A` (`CityMap+6192`); 2 more ranges |

### `PowerBit` (`$75F1`)

**HL = the byte of the power bitmap PowerMap (`$BFD0`, 12 bytes a row) for cell (B, C); E its bit, D its mask**

L1 1 380 041.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,380,041 calls (`stage1/rec/metro` 576,820, `stage1/rec/city2` 342,039, `stage1/rec/city` 269,346 and 5 more) |
| Called from | `IsConductive`, `PowerCell`, `LayerOf` |
| Reads | `$5B11`-`$5B18` (`BitMasks`) |

### `PowerBitAt` (`$7615`)

**The same for a map address in HL**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 2,499 t-states own (0.00 %) |
| Runs (the other recordings) | 35,524 calls (`stage1/rec/metro` 14,295, `stage1/rec/city2` 8,120, `stage1/rec/city` 6,693 and 6 more) |
| Called from | `BuildingPower`, `ZonePower` |
| Reads | `$5B11`-`$5B18` (`BitMasks`) |

### `MapToRowCol` (`$7635`)

**B = row, C = column of the map address HL**

L1 669 924.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 669,926 calls (`stage1/rec/metro` 202,533, `stage1/rec/city2` 196,996, `stage1/rec/city` 178,073 and 5 more) |
| Called from | `RoadTraffic`, `PowerFlood`, `Interrupt` |
| Calls | `RoadTraffic` |

### `Div8` (`$7647`)

**HL = HL / A, remainder in A**

L1 16 469.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 32 calls, 32,725 t-states own (0.00 %) |
| Runs (the other recordings) | 16,437 calls (`stage1/rec/metro` 6,851, `stage1/rec/city2` 4,168, `stage1/rec/city` 3,224 and 6 more) |
| Called from | `CommercialScore`, `IndustrialScore`, `ServiceNeeds` |

### `Max2x2` (`$7668`)

**A = the largest of the 2 x 2 bytes of a 48-wide array at HL**

L1 27 088.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27,088 calls (`stage1/rec/metro` 11,029, `stage1/rec/city2` 6,161, `stage1/rec/city` 4,943 and 5 more) |
| Called from | `ZonePollution`, `ZoneTraffic` |
| Reads | `$B170`-`$B29C` (`Pollution+928`); `$B2F8`-`$B425` (`Pollution+1320`); `$BA70`-`$BB9C` (`Traffic+928`); `$BBF8`-`$BC35` (`Traffic+1320`); `$BC58`-`$BC65` (`Traffic+1416`); `$BC88`-`$BCC5` (`Traffic+1464`); 1 more ranges |

### `BuildingValue` (`$768E`)

**A = the value of the cell at HL for its neighbours: a building's kind class, 9 for a developed zone cell; carry for nothing**

A type missing from the table returns with RET Z and BC still pushed: unreachable, every placed type is in the table. L1 191 120.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 191,120 calls (`stage1/rec/metro` 94,554, `stage1/rec/city2` 49,162, `stage1/rec/city` 34,076 and 3 more) |
| Called from | `TripArrived` |
| Calls | `FindBuildingStart`, `CellFlagsOf` |
| Reads | `$7682`-`$768D` (`BuildingValues`); `$8813`-`$8860` (`BuildingKinds`); `$D266`-`$D2CA` (`CityMap+3606`); `$D30E`-`$D3E9` (`CityMap+3774`); `$D433`-`$D4A6` (`CityMap+4067`); `$D4F3`-`$D508` (`CityMap+4259`); 5 more ranges |

### `NeighbourAddr` (`$76E4`)

**HL = the map address of the neighbour A of BC (BC moved)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 340,249 calls (`stage1/rec/metro` 167,108, `stage1/rec/city2` 88,192, `stage1/rec/city` 60,770 and 4 more) |
| Called from | `MoveTrain`, `TripStep`, `TripArrived` |
| Calls | `MapAddr`, `StepDir` |

### `StepDir` (`$76ED`)

**BC = BC + Directions[A]**

L1 392 992.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 392,992 calls (`stage1/rec/metro` 191,451, `stage1/rec/city2` 101,053, `stage1/rec/city` 69,698 and 4 more) |
| Called from | `NeighbourAddr`, `MoveTrain`, `MoveTornado`, `TripStep`, `Spread` |
| Reads | `$76DC`-`$76E3` (`Directions`) |

### `PushCell` (`$76FE`)

**Put BC on CellStack**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 37,898 calls (`stage1/rec/metro` 17,964, `stage1/rec/city2` 10,027, `stage1/rec/city` 7,104 and 3 more) |
| Called from | `MakeTrip`, `TripStep` |
| Calls | `CellStackTop` |
| Reads | `$76FD` (`CellStackCount`) |
| Writes | `$76FD` (`CellStackCount`); `$801F`-`$803E` (`CellStack+2`) |

### `PopCell` (`$7709`)

**Take BC from CellStack**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21,950 calls (`stage1/rec/metro` 10,329, `stage1/rec/city2` 5,680, `stage1/rec/city` 4,198 and 3 more) |
| Called from | `AddTripTraffic` |
| Calls | `CellStackTop` |
| Reads | `$76FD` (`CellStackCount`); `$801F`-`$803A` (`CellStack+2`) |
| Writes | `$76FD` (`CellStackCount`) |

### `CellStackTop` (`$7714`)

**HL = the free slot of CellStack**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 59,848 calls (`stage1/rec/metro` 28,293, `stage1/rec/city2` 15,707, `stage1/rec/city` 11,302 and 3 more) |
| Called from | `PushCell`, `PopCell` |
| Reads | `$76FD` (`CellStackCount`) |

### `NextMonth` (`$7720`)

**Month + 1; after December the year + 1**

L1 934 in c1's simulation. Month `$8F9B`, Year `$8F9C`.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 434 t-states own (0.00 %) |
| Runs (the other recordings) | 926 calls (`stage1/rec/city2` 218, `stage1/rec/metro` 204, `stage1/rec/city` 189 and 6 more) |
| Called from | `SimTask` |
| Reads | `$8F9B`-`$8F9D` (`Month`, `Year`) |
| Writes | `$8F9B`-`$8F9D` (`Month`, `Year`) |

## movers

`src/game/movers.asm`

### `DrawMover` (`$7735`)

**Draw the 16 x 16 sprite A (MoverSprites `$A884`) at map cell (B, C), if it is in the view and its row is drawn this pass**

The sprite is ORed in. The "mask" computed from the screen byte, byte AND (byte OR byte shifted), is the byte itself, so nothing is cut. L1 2297.

[Animation: `DrawMover` at work](img/routines/DrawMover.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,297 calls (`stage1/rec/tools` 1,869, `stage1/rec/disasters` 428) |
| Called from | `NextPixelLine`, `DrawMovers`, `Interrupt` |
| Calls | `ScreenAddr`, `NextPixelLine`, `DrawMovers` |
| Reads | `$484A`-`$496C` (screen); `$4A4A`-`$4A6C` (screen); `$4B4A`-`$4B6C` (screen); `$4C4A`-`$4C6C` (screen); `$4D4A`-`$4D6C` (screen); `$4E4A`-`$4E6C` (screen); 4 more ranges |
| Writes | `$484A`-`$496C` (screen); `$4A4A`-`$4A6C` (screen); `$4B4A`-`$4B6C` (screen); `$4C4A`-`$4C6C` (screen); `$4D4A`-`$4D6C` (screen); `$4E4A`-`$4E6C` (screen); 1 more ranges |

### `DrawMovers` (`$778F`)

**Each pass: the train (not under a rail bridge), the plane and the tornado, if they are out**

The plane is sprite 0, the train 3 or 4 (by its direction), the tornado 1 or 2 at random (LD A,R). L1 158 076.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 385,103 t-states own (0.03 %) |
| Runs (the other recordings) | 156,317 calls (`stage1/rec/metro` 38,771, `stage1/rec/city2` 34,787, `stage1/rec/city` 31,398 and 7 more) |
| Called from | `MapAddr`, `DrawMover`, `UiTask`, `Interrupt` |
| Calls | `MapAddrChecked`, `DrawMover`, `UiTask` |
| Reads | `$77D3`-`$77D6` (`TrainCell`, `TrainSprite`, `TrainOut`); `$7879`-`$787B` (`PlaneOut`, `PlaneCell`); `$7995`-`$7997` (`TornadoCell`, `TornadoOut`); `$D318`-`$D319` (`CityMap+3784`) |

### `MoveTrain` (`$77DC`)

**Move the train one cell along the rails (CellFlags bit 1), never straight back; gone when it finds none**

Called through MoveDisasters by Periodic on every 16th UI pass (PassCount AND `$0F` = 0; L1 9884 against 158 073 UI passes); it moved in c1 (L1 442 at MoveTrainTry). A stuck move adds 1 to TrainSteps, a good one does not clear it: every fifth stuck move sets TrainBack 5 so the train may reverse.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 3,190 t-states own (0.00 %) |
| Runs (the other recordings) | 9,788 calls (`stage1/rec/metro` 2,424, `stage1/rec/city2` 2,183, `stage1/rec/city` 1,969 and 7 more) |
| Called from | `MoveDisasters` (tail), `Interrupt` |
| Calls | `Random`, `MapAddr`, `CellFlagsOf`, `NeighbourAddr`, `StepDir`, `Periodic` |
| Reads | `$77D3`-`$77DB` (`TrainCell`, `TrainSprite`, `TrainOut`, `TrainBack` and 4 more); `$D2B8`-`$D2B9` (`CityMap+3688`); `$D317`-`$D31A` (`CityMap+3783`); `$D378`-`$D379` (`CityMap+3880`) |
| Writes | `$77D3`-`$77DB` (`TrainCell`, `TrainSprite`, `TrainOut`, `TrainBack` and 4 more) |

### `StartTrain` (`$785D`)

**From a rail cell (RailCell `$8903`): when no train is out, 1 in 64 starts one there**

The `$9312` compare's result is lost (AND A follows): a dead test. L1 134.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 134 calls (`stage1/rec/tools` 134) |
| Called from | `RailCell` |
| Calls | `Random` |
| Reads | `$77D6` (`TrainOut`); `$8785`-`$8786` (`CurCell`); `$9312` (`TransportCost+1`) |
| Writes | `$77D3`-`$77D6` (`TrainCell`, `TrainSprite`, `TrainOut`) |

### `MovePlane` (`$787E`)

**Fly the plane a column left; when the timer runs out, crash: burn a 2 x 2 (CrashCell) and the noise (CrashNoise)**

L1 9884; the crash L1 0 in the disaster recording? see NOTES.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 4,614 t-states own (0.00 %) |
| Runs (the other recordings) | 9,781 calls (`stage1/rec/metro` 2,432, `stage1/rec/city2` 2,174, `stage1/rec/city` 1,963 and 7 more) |
| Called from | `MoveDisasters`, `Interrupt` |
| Calls | `MoveDisasters` |
| Reads | `$7879` (`PlaneOut`) |

### `CrashCell` (`$78B4`)

**Ignite (`$90C4`) at BC**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CrashNoise` (`$78BD`)

**255 NoiseBurst calls with a rising gate: the disaster noise**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `NoiseBurst` |

### `StartPlane` (`$78CA`)

**With no plane out, 1 in 2 (Random AND 1): a plane from the airport's row at the right edge (column `$60`) or at the airport**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AirCrash` (`$78FE`)

**The AIR CRASH disaster: only when the last pass counted a working airport (LastAirports `$849E`: powered, transport in its ring, no trip lost), message `$19` (AIR CRASH !!!) and a crash timer of 7-22**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |
| Called from | `RunDisaster` (tail) |
| Reads | `$849E` (`LastAirports`) |

### `NuclearMeltdown` (`$7913`)

**With a nuclear plant (`$84A0`): message `$12` (NUCLEAR MELTDOWN), MeltdownPending, the noise**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |
| Called from | `RunDisaster` (tail) |
| Calls | `SetAdvice` |
| Reads | `$84A0` (`LastNuclear`) |
| Writes | `$7924` (`MeltdownPending`) |

### `Meltdown` (`$7925`)

**The plant catches fire (cell `$45` over it all) and 1 in 16 of the 45 x 45 cells round it turn to radiation `$59`**

L1 890 (the test).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 890 calls (`stage1/rec/metro` 393, `stage1/rec/city2` 219, `stage1/rec/city` 211 and 2 more) |
| Called from | `NuclearStep` |
| Calls | `Random`, `Irradiate`, `FillBuilding` |
| Reads | `$7924` (`MeltdownPending`); `$8785`-`$8788` (`CurCell`, `CurAddr`) |
| Writes | `$7924` (`MeltdownPending`); `$8998` (`SpreadCode`) |

### `Irradiate` (`$795E`)

**A non-water cell below `$80` at BC becomes `$59`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 112 calls (`stage1/rec/disasters` 112) |
| Called from | `Meltdown` |
| Calls | `MapAddrChecked` |
| Reads | `$CB3F`-`$CD1E` (`CityMap+1775`); `$CD93`-`$D0D7` (`CityMap+2371`); `$D152`-`$D25C` (`CityMap+3330`); `$D2C7`-`$D6D7` (`CityMap+3703`); `$D756`-`$D8B8` (`CityMap+4870`); `$D927`-`$DA58` (`CityMap+5335`); 2 more ranges |
| Writes | `$CB3F`-`$CD1E` (`CityMap+1775`); `$CD93`-`$D0D7` (`CityMap+2371`); `$D152`-`$D25C` (`CityMap+3330`); `$D2C7`-`$D2DA` (`CityMap+3703`); `$D3FA`-`$D6D7` (`CityMap+4010`); `$D756`-`$D8B8` (`CityMap+4870`); 2 more ranges |

### `StartTornado` (`$796C`)

**The TORNADO disaster: message `$1A`, the tornado on a random land cell of rows and columns 16-79**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |
| Called from | `RunDisaster` (tail) |
| Calls | `Random`, `MapAddr`, `SetAdvice` |
| Reads | `$D398` (`CityMap+3912`) |
| Writes | `$7995`-`$7997` (`TornadoCell`, `TornadoOut`) |

### `MoveTornado` (`$7998`)

**Move the tornado: 1 in 8 toward the city centre (`$84A2`), else a random step; off when Random gives 0**

The cell down and right of it is hit: a building burns (BurnBuilding), a flammable cell (CellFlags bit 7) becomes `$3A`. It stops at water. Its step uses MapAddr, not MapAddrChecked: no edge check, so from the top row it can walk into the ROM rows (`$23F0` on) and wrap at the column edges (only the hit cell is checked). L1 9884; the work L1 27.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 3,768 t-states own (0.00 %) |
| Runs (the other recordings) | 9,784 calls (`stage1/rec/metro` 2,423, `stage1/rec/city2` 2,180, `stage1/rec/city` 1,968 and 7 more) |
| Called from | `MoveDisasters`, `Interrupt` |
| Calls | `Random`, `MapAddrChecked`, `MapAddr`, `CellFlagsOf`, `StepDir`, `MoveDisasters` |
| Reads | `$7995`-`$7997` (`TornadoCell`, `TornadoOut`); `$D156`-`$D158` (`CityMap+3334`); `$D1B4`-`$D1B9` (`CityMap+3428`); `$D213`-`$D21A` (`CityMap+3523`); `$D274`-`$D27A` (`CityMap+3620`); `$D2DA`-`$D2DB` (`CityMap+3722`); 3 more ranges |
| Writes | `$7995`-`$7997` (`TornadoCell`, `TornadoOut`) |

## joysticks

`src/game/joysticks.asm`

### `ReadKempston` (`$7A01`)

**Fold the Kempston bits into KeyRows: right -> P, left -> O, down -> A, up -> Q, fire -> SPACE**

Called by ReadInput (`$F792`) every interrupt; KempstonFound decides its use. L1 413 183.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 626,880 t-states own (0.04 %) |
| Runs (the other recordings) | 407,959 calls (`stage1/rec/metro` 96,503, `stage1/rec/city2` 82,011, `stage1/rec/city` 77,592 and 7 more) |
| Called from | `ReadInput` |
| Calls | `ReadPort1F` |
| Reads | `$5B01`-`$5B07` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 3 more) |
| Writes | `$5B01`-`$5B07` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 3 more) |

### `ReadSinclair` (`$7A32`)

**With SYMBOL SHIFT and CAPS SHIFT up: keys 7 -> P, 6 -> O, 8 -> A, 9 -> Q, 0 -> SPACE**

The Sinclair (Interface 2, port 2) joystick on keys 6-0: 6 left, 7 right, 8 down, 9 up, 0 fire. Run every interrupt (L1 413 183); with a shift down it is skipped, so SYMBOL SHIFT + digit stays the tool keys. Open point 2.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 864,754 t-states own (0.06 %) |
| Runs (the other recordings) | 407,959 calls (`stage1/rec/metro` 96,503, `stage1/rec/city2` 82,011, `stage1/rec/city` 77,592 and 7 more) |
| Called from | `ReadInput` (tail) |
| Reads | `$5B00`-`$5B07` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 4 more) |
| Writes | `$5B07` (`KeyRowSpace`) |

### `ShiftScroll` (`$7A6F`)

**CAPS SHIFT with 5, 6, 7, 8: scroll the view a cell left, down, up, right, then redraw**

L1 158 073.

[Animation: `ShiftScroll` at work](img/routines/ShiftScroll.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 72,462 t-states own (0.00 %) |
| Runs (the other recordings) | 156,296 calls (`stage1/rec/metro` 38,767, `stage1/rec/city2` 34,787, `stage1/rec/city` 31,395 and 7 more) |
| Called from | `UiTask` |
| Calls | `DrawView` (tail), `ScrollLeft`, `ScrollRight`, `ScrollUp`, `ScrollDown` |
| Reads | `$5B00`-`$5B04` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 1 more) |

## maps

`src/game/maps.asm`

### `DrawMapsFrame` (`$7A9E`)

**The maps window: clear, the frame, the legend and the keys 1-9 (inline texts)**

L1 5.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 34 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/menus` 2, `stage1/rec/city2` 1, `stage1/rec/metro` 1) |
| Called from | `ClearForMaps`, `MapsWindow` |
| Calls | `ClearForMaps`, `PrintInline` |

### `DrawMapsKeys` (`$7B09`)

**DrawMapsKeys**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 17 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/menus`, `stage1/rec/city2`, `stage1/rec/metro`) |
| Called from | `PrintDigit` |
| Calls | `PrintInline` |

### `DrawMapsEnd` (`$7B4F`)

**RET**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 14 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/menus`, `stage1/rec/city2`, `stage1/rec/metro`) |
| Called from | `PrintDigit` |
| Calls | `MapsWindow` |

### `MapsWindow` (`$7B51`)

**The MAPS menu item: show the overview map, pick a layer with the digit keys, until SPACE**

L1 5. The overview draws through `$9B60`, `$9B76` and `$9C57`.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 278 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/menus` 2, `stage1/rec/city2` 1, `stage1/rec/metro` 1) |
| Called from | `ClearViewArea`, `DrawStatusItems`, `DrawMapsEnd`, `UiTask`, `MapsKeys`, `DrawOverview` |
| Calls | `ClearTopBlack`, `DrawStatusPanel`, `DrawView` (tail), `DrawMapsFrame`, `HighlightMapKey`, `HighlightLayer`, `MapsKeys`, `DrawOverview` |
| Reads | `$5B07` (`KeyRowSpace`); `$7B50` (`MapsCounter`); `$8E93` (`BudgetDue`) |
| Writes | `$7B50` (`MapsCounter`); `$A511` (`MapsDue`) |

## simulation

`src/game/simulation.asm`

### `FillBuilding` (`$7B86`)

**Fill the whole building at HL with the cell SpreadCode (`$8998`)**

L1 8.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/disasters` 8) |
| Called from | `Meltdown`, `SpreadTo` (tail) |
| Calls | `FindBuildingStart` |
| Reads | `$8998` (`SpreadCode`); `$D26A` (`CityMap+3610`); `$D3EA` (`CityMap+3994`); `$D66F`-`$D67E` (`CityMap+4639`); `$D6D2`-`$D6DB` (`CityMap+4738`); `$D735`-`$D73B` (`CityMap+4837`) |
| Writes | `$7BA5` (`FillBuildingRow+3`); `$D26A`-`$D2CD` (`CityMap+3610`); `$D32A`-`$D32D` (`CityMap+3802`); `$D38A`-`$D38D` (`CityMap+3898`); `$D3EA`-`$D3ED` (`CityMap+3994`); `$D44A`-`$D44D` (`CityMap+4090`); 3 more ranges |

### `BurnBuilding` (`$7BBB`)

**Fill the whole building at HL with the fire cell `$3A` (L1 -)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StampFire` (`$7C09`)

**Add the fire station's coverage (FireStrength through CoverKernel) into FireCover round the cell**

No clipping at the map edge: the kernel origin is grid cell - 50 (Grid24) or - `$62` (Grid48). L1 228.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 228 calls (`stage1/rec/metro` 94, `stage1/rec/city2` 55, `stage1/rec/city` 41 and 2 more) |
| Called from | `CoverFire` |
| Calls | `FireAt`, `AddFire` |
| Reads | `$8785`-`$8786` (`CurCell`) |

### `StampPolice` (`$7C32`)

**Add the police coverage into PoliceCover**

No clipping at the map edge: the kernel origin is grid cell - 50 (Grid24) or - `$62` (Grid48). L1 233.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 233 calls (`stage1/rec/metro` 93, `stage1/rec/city2` 55, `stage1/rec/city` 42 and 2 more) |
| Called from | `CoverPolice` |
| Calls | `PoliceAt`, `AddPolice` |
| Reads | `$8785`-`$8786` (`CurCell`) |

### `AddPolice` (`$7C5A`)

**One cell: A = strength >> (kernel - 1), added and clamped to 15**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,825 calls (`stage1/rec/metro` 2,325, `stage1/rec/city2` 1,375, `stage1/rec/city` 1,050 and 2 more) |
| Called from | `StampPolice` |
| Calls | `AddFire` (tail) |
| Reads | `$7C31` (`PoliceStrength`) |

### `AddFire` (`$7C5F`)

**AddFire**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,700 calls (`stage1/rec/metro` 2,350, `stage1/rec/city2` 1,375, `stage1/rec/city` 1,025 and 2 more) |
| Called from | `StampFire`, `AddPolice` (tail) |
| Reads | `$7BEF`-`$7C08` (`CoverKernel`, `FireStrength`); `$AA33`-`$AB11` (`FireCover+227`); `$AC58`-`$AC8F` (`PoliceCover+200`); `$ACA0`-`$ACA7` (`PoliceCover+272`); `$ACB8`-`$ACC1` (`PoliceCover+296`); `$ACD5`-`$ACD9` (`PoliceCover+325`); 3 more ranges |
| Writes | `$AA33`-`$AB11` (`FireCover+227`); `$AC58`-`$AC8F` (`PoliceCover+200`); `$ACA0`-`$ACA7` (`PoliceCover+272`); `$ACB8`-`$ACC1` (`PoliceCover+296`); `$ACD5`-`$ACD9` (`PoliceCover+325`); `$ACED`-`$ACF1` (`PoliceCover+349`); 2 more ranges |

### `StampPollution` (`$7CC0`)

**Add PollutionStrength through the kernel at IX into Pollution round the current cell**

No clipping at the map edge: the kernel origin is grid cell - 50 (Grid24) or - `$62` (Grid48). L1 8425.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,425 calls (`stage1/rec/metro` 3,401, `stage1/rec/city2` 1,979, `stage1/rec/city` 1,535 and 5 more) |
| Called from | `RadiationCell` (tail), `IndBuildingStep` (tail), `CoalStep` (tail), `NuclearStep` (tail) |
| Calls | `StampPollutionIX` (falls into) |
| Reads | `$8785`-`$8786` (`CurCell`) |

### `StampPollutionIX` (`$7CC8`)

**StampPollutionIX**

L1 30 375.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 30,278 calls (`stage1/rec/metro` 13,730, `stage1/rec/city2` 7,659, `stage1/rec/city` 5,733 and 3 more) |
| Called from | `StampPollution` (falls into), `AddTripTraffic` |
| Calls | `PollutionAt`, `AddPollutionCell`, `ZoneStep`, `CellStep` |

### `AddPollutionCell` (`$7CE8`)

**One cell: A = PollutionStrength >> (kernel - 1), added, clamped to `$FF`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,093,483 calls (`stage1/rec/metro` 494,280, `stage1/rec/city2` 275,724, `stage1/rec/city` 206,388 and 5 more) |
| Called from | `StampPollutionIX` |
| Reads | `$7C77`-`$7CBF` (`PollutionKernel`, `TrafficKernel`, `PollutionStrength`); `$AF35`-`$B0CC` (`Pollution+357`); `$B0E1`-`$B4B8` (`Pollution+785`); `$BA3D`-`$BC2E` (`Traffic+877`); `$BC93`-`$BCC8` (`Traffic+1475`); `$BCF3`-`$BCF8` (`Traffic+1571`); 3 more ranges |
| Writes | `$AF35`-`$B0CC` (`Pollution+357`); `$B0E1`-`$B4B8` (`Pollution+785`); `$BA3D`-`$BC2E` (`Traffic+877`); `$BC93`-`$BCC8` (`Traffic+1475`); `$BCF3`-`$BCF8` (`Traffic+1571`); `$BD23`-`$BD28` (`Traffic+1619`); 2 more ranges |

### `ZonePollution` (`$7CFE`)

**ZonePollutionMax = the largest Pollution of the 2 x 2 at the current cell; summed into PollutionSum (`$847A`, `$847C`)**

L1 24 645.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24,645 calls (`stage1/rec/metro` 9,866, `stage1/rec/city2` 5,520, `stage1/rec/city` 4,519 and 5 more) |
| Called from | `ResidentialStep`, `ComBuildingStep` |
| Calls | `PollutionAt`, `Max2x2` |
| Reads | `$847A`-`$847D` (`PollutionSum`, `PollutionCount`); `$8785`-`$8786` (`CurCell`) |
| Writes | `$7EBF` (`ZonePollutionMax`); `$847A`-`$847D` (`PollutionSum`, `PollutionCount`) |

### `ZoneTraffic` (`$7D1D`)

**ZoneTrafficMax = the largest Traffic of the 2 x 2 at the current cell**

L1 2443.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,443 calls (`stage1/rec/metro` 1,163, `stage1/rec/city2` 641, `stage1/rec/city` 424 and 3 more) |
| Called from | `LandValueOf` |
| Calls | `TrafficAt`, `Max2x2` |
| Reads | `$8785`-`$8786` (`CurCell`) |
| Writes | `$7EC0` (`ZoneTrafficMax`) |

### `ScanRingSize` (`$7D2F`)

**ScanRing for a building of size HL**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 623 calls (`stage1/rec/city2` 220, `stage1/rec/metro` 206, `stage1/rec/city` 167 and 1 more) |
| Called from | `StadiumStep` |
| Calls | `ScanRing` (tail) |
| Writes | `$7D2D`-`$7D2E` (`RingSize`) |

### `ScanRing` (`$7D34`)

**Look at the ring of cells round the zone at BC (3 x 3) and its inside**

The ring (ScanRingCell): roads and rails count in RingTransport (one of them becomes RouteStart at random), parks (`$38`, `$39`) in RingParks, water in RingWater, trees in RingTrees, each adding to RingAmenity (12 for transport, 14 a park, 16 water or trees), capped at `$7F`. The inside (ScanInsideCell) adds the developed cells' density (cell - `$3B`) to Density `$8869`. L1 32 092 + 623.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 32,092 calls (`stage1/rec/metro` 13,238, `stage1/rec/city2` 7,460, `stage1/rec/city` 5,975 and 5 more) |
| Called from | `ScanRingSize` (tail), `ResidentialStep`, `ComBuildingStep`, `IndBuildingStep` |
| Calls | `ScanRingCell`, `ScanInsideCell` |
| Reads | `$7D2D`-`$7D2E` (`RingSize`) |
| Writes | `$7D2B`-`$7D2E` (`RouteStart`, `RingSize`); `$7E17`-`$7E1B` (`RingParks`, `RingWater`, `RingTrees`, `RingTransport` and 1 more) |

### `ScanRingCell` (`$7D88`)

**One ring cell: count it by kind into the Ring counters**

L1 395 063.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 395,064 calls (`stage1/rec/metro` 162,152, `stage1/rec/city2` 93,040, `stage1/rec/city` 74,372 and 5 more) |
| Called from | `ScanRing` |
| Calls | `MapAddrChecked`, `CellFlagsOf`, `PickRouteStart` |
| Reads | `$7E18`-`$7E1B` (`RingWater`, `RingTrees`, `RingTransport`, `RingAmenity`); `$D1EF`-`$D9FB` (`CityMap+3487`); `$DA3F`-`$DA5B` (`CityMap+5615`); `$DA9F`-`$DC3A` (`CityMap+5711`); `$DC7F`-`$DD5B` (`CityMap+6191`); `$DDA0`-`$DDBA` (`CityMap+6480`) |
| Writes | `$7E18`-`$7E1B` (`RingWater`, `RingTrees`, `RingTransport`, `RingAmenity`) |

### `PickRouteStart` (`$7DD8`)

**The first transport cell, then each next one with 1 in 2, becomes RouteStart**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 115,099 calls (`stage1/rec/metro` 49,821, `stage1/rec/city2` 28,191, `stage1/rec/city` 22,209 and 3 more) |
| Called from | `ScanRingCell` |
| Calls | `Random` |
| Reads | `$7D2B` (`RouteStart`) |
| Writes | `$7D2B`-`$7D2C` (`RouteStart`) |

### `ScanInsideCell` (`$7DEA`)

**A developed cell (CellFlags bit 6) inside the zone adds cell - `$3B` to Density**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 298,789 calls (`stage1/rec/metro` 122,438, `stage1/rec/city2` 70,660, `stage1/rec/city` 56,447 and 5 more) |
| Called from | `ScanRing` |
| Calls | `MapAddrChecked`, `CellFlagsOf` |
| Reads | `$8869` (`Density`); `$D24F`-`$D388` (`CityMap+3583`); `$D3CF`-`$D5C9` (`CityMap+3967`); `$D611`-`$D628` (`CityMap+4545`); `$D66F`-`$D749` (`CityMap+4639`); `$D860`-`$D93A` (`CityMap+5136`); 3 more ranges |
| Writes | `$8869` (`Density`) |

### `CentreDistance` (`$7E03`)

**A = |CityCentre row - B| + |CityCentre column - C|: B the row, C the column**

CityCentre is (column, row), so H is its row and L its column. Both callers pass BC = (row, column) loaded from a (column, row) word: CentreCloseness from CurCell `$8785`, LayerCrime from OverviewCellAt `$9C31`.

L1 27 944.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27,944 calls (`stage1/rec/metro` 12,026, `stage1/rec/city2` 6,879, `stage1/rec/city` 5,396 and 3 more) |
| Called from | `CentreCloseness` |
| Reads | `$84A2`-`$84A3` (`CityCentre`) |

### `LandValueOf` (`$7E1D`)

**LandValue = 127 - CentreDistance + RingAmenity, for a powered zone with transport and a trip (or traffic 50+); else 0**

Summed into LandValueSum (`$8472`, count `$8474`). L1 33 251.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,251 calls (`stage1/rec/metro` 13,631, `stage1/rec/city2` 7,680, `stage1/rec/city` 6,185 and 6 more) |
| Called from | `ZoneScoreOf` |
| Calls | `ZoneTraffic`, `CentreCloseness` |
| Reads | `$7E1A`-`$7E1B` (`RingTransport`, `RingAmenity`); `$8472`-`$8475` (`LandValueSum`, `LandValueCount`); `$8568` (`TripMade`); `$86C5` (`ZonePowered`) |
| Writes | `$7E1C` (`LandValue`); `$8472`-`$8475` (`LandValueSum`, `LandValueCount`) |

### `CentreCloseness` (`$7E5A`)

**A = 127 - CentreDistance, 0 when farther**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27,944 calls (`stage1/rec/metro` 12,026, `stage1/rec/city2` 6,879, `stage1/rec/city` 5,396 and 3 more) |
| Called from | `LandValueOf` |
| Calls | `CentreDistance` |
| Reads | `$8785`-`$8786` (`CurCell`) |

### `CrimeOf` (`$7E6A`)

**Crime = (255 - LandValue) / 16 - PoliceCover here, not below 0; summed into CrimeSum (`$846E`, `$8470`)**

L1 33 251.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,251 calls (`stage1/rec/metro` 13,631, `stage1/rec/city2` 7,680, `stage1/rec/city` 6,185 and 6 more) |
| Called from | `ZoneScoreOf` |
| Calls | `PoliceAt` |
| Reads | `$7E1C` (`LandValue`); `$846E`-`$8471` (`CrimeSum`, `CrimeCount`); `$8785`-`$8786` (`CurCell`) |
| Writes | `$7E69` (`Crime`); `$846E`-`$8471` (`CrimeSum`, `CrimeCount`) |

### `TaxPenaltyOf` (`$7E9B`)

**TaxPenalty = 8 x TaxRate (`$91E4`); 10 x on medium (Level 1), 9 x on difficult (Level 2) (`$A518`)**

The second addition is skipped by CP `$02` / RET Z (`$7EB4`) on Level 2 only, so the difficult level pays less than the medium one. L1 33 251.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,251 calls (`stage1/rec/metro` 13,631, `stage1/rec/city2` 7,680, `stage1/rec/city` 6,185 and 6 more) |
| Called from | `ZoneScoreOf` |
| Reads | `$7E9A` (`TaxPenalty`); `$91E4` (`TaxRate`); `$A518` (`Level`) |
| Writes | `$7E9A` (`TaxPenalty`) |

### `ZoneScoreOf` (`$7EC4`)

**ZoneScore = LandValue - Pollution - Crime - TaxPenalty + ZoneDemand, clamped 0-255; 0 with pollution 28+ or no land value**

The heart of the growth: a zone grows when its score is high. L1 33 251.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,251 calls (`stage1/rec/metro` 13,631, `stage1/rec/city2` 7,680, `stage1/rec/city` 6,185 and 6 more) |
| Called from | `ResidentialScore`, `CommercialScore`, `IndustrialScore`, `CoalStep`, `NuclearStep` |
| Calls | `LandValueOf`, `CrimeOf`, `TaxPenaltyOf`, `Clamp8` |
| Reads | `$7E1C` (`LandValue`); `$7E69` (`Crime`); `$7E9A` (`TaxPenalty`); `$7EBF`-`$7EC3` (`ZonePollutionMax`, `ZoneTrafficMax`, `ZoneScore`, `ZoneDemand`) |
| Writes | `$7EC1` (`ZoneScore`) |

### `Clamp8` (`$7F04`)

**L = HL clamped to 0-255 (negative 0, above 255 255)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21,592 calls (`stage1/rec/metro` 8,995, `stage1/rec/city2` 5,562, `stage1/rec/city` 4,366 and 3 more) |
| Called from | `ZoneScoreOf` |

### `ResidentialScore` (`$7F12`)

**ResLevel = (ZoneScore - 128) / 16 (0 below 128... `$0F`), ResTile = ZoneScore / 2, or 16 ResLevel + `$50` from 128 up**

L1 17 800.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17,800 calls (`stage1/rec/metro` 6,797, `stage1/rec/city2` 3,731, `stage1/rec/city` 3,180 and 5 more) |
| Called from | `ResidentialStep` |
| Calls | `ZoneScoreOf` |
| Reads | `$7EC1` (`ZoneScore`) |
| Writes | `$7F10`-`$7F11` (`ResLevel`, `ResTile`) |

### `CommercialScore` (`$7F45`)

**CommercialScore**

L1 6845.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,845 calls (`stage1/rec/metro` 3,069, `stage1/rec/city2` 1,789, `stage1/rec/city` 1,339 and 2 more) |
| Called from | `ComBuildingStep` |
| Calls | `Div8`, `ZoneScoreOf` |
| Reads | `$7EC1` (`ZoneScore`) |
| Writes | `$7F43`-`$7F44` (`ComLevel`, `ComTile`) |

### `IndustrialScore` (`$7F5F`)

**IndustrialScore**

L1 7446.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,446 calls (`stage1/rec/metro` 3,372, `stage1/rec/city2` 1,941, `stage1/rec/city` 1,455 and 2 more) |
| Called from | `IndBuildingStep` |
| Calls | `Div8`, `ZoneScoreOf` |
| Reads | `$7EC1` (`ZoneScore`) |
| Writes | `$7F5D`-`$7F5E` (`IndLevel`, `IndTile`) |

### `FindPlants` (`$7F98`)

**Scan the map for 4 x 4 building tops (`$B4`) of type 6 (coal) or 8 (nuclear) into PowerPlants**

Finds only top row bytes `$B4` (powered, width 4) of type 6 (coal) or 8 (nuclear) (LD A,`$B4` / CPIR at `$7FA2`). L1 1101 (once a simulation pass).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 3,499,233 t-states own (0.23 %) |
| Runs (the other recordings) | 1,084 calls (`stage1/rec/city2` 219, `stage1/rec/city` 216, `stage1/rec/metro` 205 and 7 more) |
| Called from | `PowerFlood` |
| Reads | `$C450`-`$E850` (`CityMap`, `IconTiles`) |
| Writes | `$7F78`-`$7F7D` (`PowerPlants`) |

### `PowerFlood` (`$7FCD`)

**Clear PowerMap, then flood the power from each station over conducting cells: nuclear 1350 cells, coal 450**

L1 1101. Every powered cell costs one of the station's budget; a station that runs out stops its flood (Brownout + 1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 441,699 t-states own (0.03 %) |
| Runs (the other recordings) | 1,084 calls (`stage1/rec/city2` 219, `stage1/rec/city` 216, `stage1/rec/metro` 205 and 7 more) |
| Called from | `SimTask` |
| Calls | `MapToRowCol`, `FindPlants`, `FloodFill` |
| Reads | `$7F78`-`$7F7D` (`PowerPlants`); `$BFD0`-`$C44E` (`PowerMap`); `$D262`-`$D26B` (`CityMap+3602`); `$DC9C` (`CityMap+6220`) |
| Writes | `$7FCC` (`Brownout`); `$8017`-`$801A` (`FloodStart`, `FloodBudget`); `$BFD0`-`$C44F` (`PowerMap`) |

### `FloodFill` (`$811D`)

**A scan-line flood fill from FloodStart over IsConductive cells, each made powered (PowerCell)**

FloodPush silently drops a span when CellStack is full; a plant whose top cell an earlier plant's flood powered floods nothing (IsConductive fails at once), so its budget is lost. L1 1162.

[Animation: `FloodFill` at work](img/routines/FloodFill.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,162 calls (`stage1/rec/metro` 393, `stage1/rec/city2` 219, `stage1/rec/city` 211 and 5 more) |
| Called from | `PowerFlood` |
| Calls | `FloodMark`, `FloodPush`, `FloodPop`, `IsConductive`, `PowerCell` |
| Reads | `$8017`-`$8018` (`FloodStart`) |
| Writes | `$8015`-`$801C` (`FloodAbove`, `FloodBelow`, `FloodStart`, `FloodBudget` and 1 more) |

### `FloodMark` (`$816D`)

**Queue the cell above or below once per run of conducting cells (flag at HL)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 640,716 calls (`stage1/rec/metro` 269,864, `stage1/rec/city2` 158,118, `stage1/rec/city` 124,710 and 5 more) |
| Called from | `FloodFill` |
| Calls | `FloodPush` (falls into), `IsConductive` |
| Reads | `$8015`-`$8016` (`FloodAbove`, `FloodBelow`) |
| Writes | `$8015`-`$8016` (`FloodAbove`, `FloodBelow`) |

### `FloodPush` (`$8177`)

**Push BC on the span stack, unless it is full (`$811D`)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18,267 calls (`stage1/rec/metro` 6,910, `stage1/rec/city2` 4,380, `stage1/rec/city` 3,559 and 5 more) |
| Called from | `FloodFill`, `FloodMark` (falls into) |
| Writes | `$801D`-`$802E` (`CellStack`) |

### `FloodPop` (`$818F`)

**BC from the span stack**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18,267 calls (`stage1/rec/metro` 6,910, `stage1/rec/city2` 4,380, `stage1/rec/city` 3,559 and 5 more) |
| Called from | `FloodFill` |
| Reads | `$801D`-`$802E` (`CellStack`) |

### `IsConductive` (`$819A`)

**Z set when the cell at BC is on the map, not powered yet and a building or CellFlags bit 3**

L1 1 057 667.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,057,667 calls (`stage1/rec/metro` 440,928, `stage1/rec/city2` 261,924, `stage1/rec/city` 206,991 and 5 more) |
| Called from | `FloodFill`, `FloodMark` |
| Calls | `MapAddrChecked`, `CellFlagsOf`, `PowerBit` |
| Reads | `$C183`-`$C309` (`PowerMap+435`); `$D1EE`-`$D7A9` (`CityMap+3486`); `$D7FF`-`$D81A` (`CityMap+5039`); `$D85E`-`$D87B` (`CityMap+5134`); `$D8BE`-`$D99A` (`CityMap+5230`); `$D9DE`-`$DBDB` (`CityMap+5518`); 2 more ranges |

### `PowerCell` (`$81C2`)

**Set the cell's bit in PowerMap and count FloodBudget down; at 0 leave the flood (SP back) with Brownout + 1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 320,358 calls (`stage1/rec/metro` 134,932, `stage1/rec/city2` 79,059, `stage1/rec/city` 62,355 and 5 more) |
| Called from | `FloodFill` |
| Calls | `PowerBit` |
| Reads | `$8019`-`$801A` (`FloodBudget`); `$C18F`-`$C22F` (`PowerMap+447`); `$C251`-`$C2FD` (`PowerMap+641`) |
| Writes | `$8019`-`$801A` (`FloodBudget`); `$C18F`-`$C22F` (`PowerMap+447`); `$C251`-`$C2FD` (`PowerMap+641`) |

### `AssessCity` (`$81E3`)

**CityValue = rails x 5 + roads x 10 + police x 1000 + fire x 1000 + hospitals x 400 + stadiums x 3000 + seaports x 5000 + airports x 10 000 + coal x 3000 + nuclear x 6000**

L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 8,192 t-states own (0.00 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Calls | `Mul16`, `AddValue` (falls into) |
| Reads | `$81DD`-`$81DF` (`CityValue`); `$844C`-`$846D` (`PoliceCount`, `FireCount`, `ChurchCount`, `HospitalCount` and 13 more) |
| Writes | `$81DD`-`$81E2` (`CityValue`, `CityValueLast`) |

### `AddValue` (`$824F`)

**CityValue = CityValue + HL x DE**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 144 calls, 16,454 t-states own (0.00 %) |
| Runs (the other recordings) | 9,657 calls (`stage1/rec/city2` 1,971, `stage1/rec/city` 1,935, `stage1/rec/metro` 1,845 and 6 more) |
| Called from | `AssessCity` (falls into) |
| Calls | `Add24`, `Mul16` |
| Reads | `$81DD`-`$81DF` (`CityValue`) |
| Writes | `$81DD`-`$81DF` (`CityValue`) |

### `PopBalanceOf` (`$8267`)

**PopBalanceOf**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 2,144 t-states own (0.00 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Reads | `$8446`-`$844B` (`ResPop`, `ComPop`, `IndPop`) |
| Writes | `$8265`-`$8266` (`PopBalance`) |

### `DemandOf` (`$8282`)

**R = 8 (C + I - R) + 4 stadiums - 26; C = 8 ((R + I) / 2 - C) + 4 airports - 30; I = 8 ((R + C) / 2 - I) + 4 seaports - 30**

R, C, I are the populations ResPop `$8446`, ComPop `$8448`, IndPop `$844A`. L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 10,896 t-states own (0.00 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Reads | `$8446`-`$845D` (`ResPop`, `ComPop`, `IndPop`, `PoliceCount` and 8 more) |
| Writes | `$827C`-`$8281` (`ResDemand`, `ComDemand`, `IndDemand`) |

### `AddPopulation` (`$82EE`)

**Population (`$8443`, 24 bits) = Population + 16 DE**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17,801 calls (`stage1/rec/metro` 6,798, `stage1/rec/city2` 3,731, `stage1/rec/city` 3,180 and 5 more) |
| Called from | `ResidentialStep` |
| Calls | `Add24` |
| Reads | `$8443`-`$8445` (`Population`) |
| Writes | `$8443`-`$8445` (`Population`) |

### `StartSimulation` (`$830C`)

**Make the simulation task (entry SimTask, SP `$F6EE`), the date January 1902, Funds by the level: 20 000, 10 000, 5000**

L1 13.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 428 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/rec/menus` 4, `stage1/rec/levels` 2, `stage1/rec/bankrupt` 1 and 4 more) |
| Called from | `NewLandscape`, `UiTask` |
| Calls | `InitSimulation` |
| Reads | `$A518` (`Level`) |
| Writes | `$8F97`-`$8F9D` (`Funds`, `FundsSpare`, `Month`, `Year`); `$F702`-`$F70A` (`SimEntry`, `TaskNow`, `SwitchOff`, `UiSP`) |

### `SimTask` (`$835F`)

**The simulation task: init, then for ever one pass over the city; a month every MonthMask + 1 passes**

A pass: ClearCounters, SetSpeed, PowerFlood, ScanCity (the growth), CoverStations (every 4th), DecayPollution, DecayTraffic, DemandOf, Averages2, AssessCity, PopBalanceOf, ServiceNeeds, Advise (`$99AD`), Averages; when SimPass AND MonthMask is 0, MonthEnd (`$8E94`) and NextMonth. L1 (c1 and the ten recordings together, not c1 alone): 12 entries, 1101 passes started at SimTaskPass (c1 17, doc 4.8), 1089 of them run to the month test (a recording ends inside a pass).

[Animation: `SimTask` at work](img/routines/SimTask.gif)

[Animation: `SimTask` at work, growth](img/routines/SimTask-growth.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 5,325 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/city2`, `stage1/rec/city`, `stage1/rec/metro` and 7 more) |
| Called from | `Interrupt` |
| Calls | `NextMonth`, `PowerFlood`, `AssessCity`, `PopBalanceOf`, `DemandOf`, `InitSimulation`, `ClearCounters`, `Averages`, `DecayPollution`, `DecayTraffic`, `CoverStations`, `ScanCity`, `MonthEnd`, `Averages2`, `ServiceNeeds`, `SetSpeed`, `Advise` |
| Reads | `$835E` (`SimPass`); `$8F6B` (`MonthMask`) |
| Writes | `$835E` (`SimPass`) |

### `InitSimulation` (`$83A1`)

**Clear the arrays `$A950-$C44F`, the counters and the disasters; city centre 32, 32; strengths `$0F`**

L1 25.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 437,712 t-states own (0.03 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/menus` 8, `stage1/rec/levels` 4, `stage1/rec/bankrupt` 2 and 4 more) |
| Called from | `StartSimulation`, `SimTask` |
| Reads | `$A950`-`$C44E` (`FireCover`, `PoliceCover`, `Pollution`, `Traffic` and 1 more) |
| Writes | `$77D6` (`TrainOut`); `$7879`-`$787D` (`PlaneOut`, `PlaneCell`, `PlaneTarget`, `PlaneTimer`); `$7924` (`MeltdownPending`); `$7997` (`TornadoOut`); `$7C08` (`FireStrength`); `$7C31` (`PoliceStrength`); 13 more ranges |

### `ClearCounters` (`$8480`)

**Zero `$8443-$847F`; the city's extent to empty (min `$FF`, max 0)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 23,205 t-states own (0.00 %) |
| Runs (the other recordings) | 1,084 calls (`stage1/rec/city2` 219, `stage1/rec/city` 216, `stage1/rec/metro` 205 and 7 more) |
| Called from | `SimTask` |
| Reads | `$8443`-`$847E` (`Population`, `ResPop`, `ComPop`, `IndPop` and 26 more) |
| Writes | `$8443`-`$847F` (`Population`, `ResPop`, `ComPop`, `IndPop` and 26 more); `$87C8`-`$87CB` (`ExtentCols`, `ExtentRows`) |

### `Averages` (`$84A4`)

**CityCentre = the middle of the extent; the last-pass copies; AvgPollution = PollutionSum / count**

CityCentre = (max + min) / 2 of ExtentCols and ExtentRows, the box of every zone and building ZoneStep met this pass (WidenExtent). InitSimulation starts it at 32, 32; a pass with no zones leaves the cleared box 0, `$FF` and gives 127, 127. L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 4,448 t-states own (0.00 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Calls | `Div16` |
| Reads | `$8454`-`$845B` (`NuclearCount`, `CoalCount`, `StadiumCount`, `AirportCount`); `$847A`-`$847F` (`PollutionSum`, `PollutionCount`, `FireCells`); `$87C8`-`$87CB` (`ExtentCols`, `ExtentRows`) |
| Writes | `$849C`-`$84A3` (`LastFireCells`, `LastAirports`, `LastNuclear`, `CityCentre`); `$84DD` (`AvgPollution`) |

### `DecayPollution` (`$84DE`)

**Every second pass: each Pollution byte - 64? (`$4000`: D 64, floor E 0); AvgPollution = average / 4**

L1 1089 (542 decays).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 1,126,091 t-states own (0.07 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Calls | `Div16` |
| Reads | `$835E` (`SimPass`); `$847A`-`$847D` (`PollutionSum`, `PollutionCount`); `$ADD0`-`$B6CF` (`Pollution`) |
| Writes | `$84DD` (`AvgPollution`); `$ADD0`-`$B6CF` (`Pollution`) |

### `ClearCover` (`$850C`)

**Zero FireCover and PoliceCover (`$A950-$ADCF`)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 4 calls, 96,883 t-states own (0.01 %) |
| Runs (the other recordings) | 274 calls (`stage1/rec/city2` 55, `stage1/rec/city` 54, `stage1/rec/metro` 51 and 7 more) |
| Called from | `CoverStations` |
| Reads | `$A950`-`$ADCE` (`FireCover`, `PoliceCover`) |
| Writes | `$A950`-`$ADCF` (`FireCover`, `PoliceCover`) |

### `DecayTraffic` (`$851B`)

**Sum the traffic, then each Traffic byte: below 24 to 0, 200 and up - 34, else - 24**

L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 3,652,357 t-states own (0.24 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Calls | `Div16` |
| Reads | `$8476`-`$8479` (`TrafficSum`, `TrafficCount`); `$B6D0`-`$BFCF` (`Traffic`) |
| Writes | `$8476`-`$8479` (`TrafficSum`, `TrafficCount`); `$851A` (`AvgTraffic`); `$B6D0`-`$BFCF` (`Traffic`) |

### `MakeTrip` (`$856A`)

**From RouteStart walk the roads or rails (TripWalk) to a zone of the wanted kind; on success the path gets traffic**

L1 9735.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,735 calls (`stage1/rec/metro` 4,344, `stage1/rec/city2` 2,656, `stage1/rec/city` 1,939 and 3 more) |
| Called from | `ResidentialStep`, `ComBuildingStep`, `IndBuildingStep` |
| Calls | `MapAddr`, `CellFlagsOf`, `PushCell`, `AddTripTraffic`, `TripWalk` |
| Reads | `$7D2B`-`$7D2C` (`RouteStart`); `$7E1A` (`RingTransport`); `$D36F`-`$D389` (`CityMap+3871`); `$D3D4`-`$D3E3` (`CityMap+3972`); `$D554`-`$D565` (`CityMap+4356`); `$D60F`-`$D629` (`CityMap+4543`); 4 more ranges |
| Writes | `$76FD` (`CellStackCount`); `$8568`-`$8569` (`TripMade`, `TripMask`) |

### `AddTripTraffic` (`$8599`)

**A road trip: each cell of the path + 20 Traffic (to `$F0`) and pollution (strength 5, TrafficKernel)**

L1 7281.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,281 calls (`stage1/rec/metro` 3,181, `stage1/rec/city2` 2,016, `stage1/rec/city` 1,515 and 3 more) |
| Called from | `MakeTrip` |
| Calls | `TrafficAt`, `PopCell`, `StampPollutionIX` |
| Reads | `$76FD` (`CellStackCount`); `$8569` (`TripMask`); `$BA9F`-`$BAAC` (`Traffic+975`); `$BB02`-`$BB0A` (`Traffic+1074`); `$BB2F`-`$BB3C` (`Traffic+1119`); `$BB90`-`$BB9C` (`Traffic+1216`); 3 more ranges |
| Writes | `$7CBF` (`PollutionStrength`); `$BA9F`-`$BAAC` (`Traffic+975`); `$BB02`-`$BB0A` (`Traffic+1074`); `$BB2F`-`$BB3C` (`Traffic+1119`); `$BB90`-`$BB9C` (`Traffic+1216`); `$BC28`-`$BC35` (`Traffic+1368`); 2 more ranges |

### `TripWalk` (`$85D6`)

**Up to 30 steps of TripStep, each checked for arrival (TripArrived); carry when lost**

A dead end drops one pushed cell without counting a step or moving; with no way on, the trip is lost. L1 9735.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,735 calls (`stage1/rec/metro` 4,344, `stage1/rec/city2` 2,656, `stage1/rec/city` 1,939 and 3 more) |
| Called from | `MakeTrip`, `GrowCell` (tail), `DeclineCell` (tail) |
| Calls | `TripStep`, `TripArrived` |
| Reads | `$76FD` (`CellStackCount`); `$85D5` (`TripSteps`) |
| Writes | `$76FD` (`CellStackCount`); `$85D4`-`$85D5` (`TripBack`, `TripSteps`) |

### `TripStep` (`$8609`)

**One step: from a random direction try the four, not back, onto a cell with TripMask; every second step pushed**

L1 67 734.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 67,734 calls (`stage1/rec/metro` 33,018, `stage1/rec/city2` 17,764, `stage1/rec/city` 12,173 and 3 more) |
| Called from | `TripWalk` |
| Calls | `Random`, `CellFlagsOf`, `NeighbourAddr`, `StepDir`, `PushCell` |
| Reads | `$8569` (`TripMask`); `$85D4`-`$85D5` (`TripBack`, `TripSteps`); `$8606`-`$8608` (`TripTurn`, `TripDir`, `TripTries`); `$D30E`-`$D3E9` (`CityMap+3774`); `$D433`-`$D448` (`CityMap+4067`); `$D4F3`-`$D508` (`CityMap+4259`); 7 more ranges |
| Writes | `$85D4` (`TripBack`); `$8606`-`$8608` (`TripTurn`, `TripDir`, `TripTries`) |

### `TripArrived` (`$8660`)

**Carry clear when a neighbour's BuildingValue is one of TripTargets**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 49,623 calls (`stage1/rec/metro` 24,342, `stage1/rec/city2` 12,861, `stage1/rec/city` 8,928 and 3 more) |
| Called from | `TripWalk` |
| Calls | `BuildingValue`, `NeighbourAddr` |
| Reads | `$865E`-`$865F` (`TripTargets`) |

### `CoverStations` (`$8680`)

**Every 4th pass: ClearCover, then each powered top row byte (AND `$F0` = `$B0`, any width: police type 0, fire type 1) stamps its coverage**

L1 1090 (273 stamping).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 2,186,224 t-states own (0.15 %) |
| Runs (the other recordings) | 1,074 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 7 more) |
| Called from | `SimTask` |
| Calls | `ClearCover`, `CoverPolice`, `CoverFire` |
| Reads | `$835E` (`SimPass`); `$C450`-`$E84F` (`CityMap`) |
| Writes | `$8785`-`$8786` (`CurCell`) |

### `CoverPolice` (`$86B7`)

**CoverPolice**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 233 calls (`stage1/rec/metro` 93, `stage1/rec/city2` 55, `stage1/rec/city` 42 and 2 more) |
| Called from | `CoverStations` |
| Calls | `StampPolice` |

### `CoverFire` (`$86BF`)

**CoverFire**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 228 calls (`stage1/rec/metro` 94, `stage1/rec/city2` 55, `stage1/rec/city` 41 and 2 more) |
| Called from | `CoverStations` |
| Calls | `StampFire` |

### `ScanCity` (`$86C9`)

**Every map cell: buildings' power (BuildingPower), zones' power (ZonePower), then their step (ZoneStep) and the plain cells (CellStep)**

L1 1101; 10 084 466 cells.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 31,752,426 t-states own (2.11 %) |
| Runs (the other recordings) | 1,084 calls (`stage1/rec/city2` 219, `stage1/rec/city` 216, `stage1/rec/metro` 205 and 7 more) |
| Called from | `SimTask` |
| Calls | `BuildingPower`, `ZonePower`, `ZoneStep`, `CellStep` |
| Reads | `$835D` (`SimPaused`); `$86C6` (`CellKind`); `$C450`-`$E84F` (`CityMap`) |
| Writes | `$86C5`-`$86C8` (`ZonePowered`, `CellKind`, `BuildingType`, `ZoneCentre`) |

### `BuildingPower` (`$870C`)

**A building's top-left byte: bit 4 = powered (PowerMap), ZonePowered; BuildingType; the power plants (types 6, 8) skip both: their top byte keeps the prefab's `$B4` and ZonePowered stays 0**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14,526 calls (`stage1/rec/metro` 6,048, `stage1/rec/city2` 3,718, `stage1/rec/city` 2,811 and 5 more) |
| Called from | `ScanCity` |
| Calls | `PowerBitAt` |
| Reads | `$C1BF`-`$C1CE` (`PowerMap+495`); `$C1FE`-`$C216` (`PowerMap+558`); `$C282`-`$C285` (`PowerMap+690`); `$C2D6`-`$C2D9` (`PowerMap+774`); `$D262`-`$D26B` (`CityMap+3602`); `$D3CF`-`$D3EB` (`CityMap+3967`); 6 more ranges |
| Writes | `$86C5`-`$86C7` (`ZonePowered`, `CellKind`, `BuildingType`); `$D3CF`-`$D3EA` (`CityMap+3967`); `$D433`-`$D446` (`CityMap+4067`); `$D5C6` (`CityMap+4470`); `$D61F`-`$D623` (`CityMap+4559`); `$D66F`-`$D687` (`CityMap+4639`); 2 more ranges |

### `ZonePower` (`$873C`)

**A zone centre: `$51-$53` when powered, `$54-$56` (blinking) when not**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 4,214 t-states own (0.00 %) |
| Runs (the other recordings) | 22,158 calls (`stage1/rec/metro` 8,640, `stage1/rec/city2` 4,621, `stage1/rec/city` 4,093 and 5 more) |
| Called from | `ScanCity` |
| Calls | `PowerBitAt` |
| Reads | `$873B` (`ZoneCentreCell`); `$C19C`-`$C1AA` (`PowerMap+460`); `$C1CC`-`$C1F3` (`PowerMap+508`); `$C208`-`$C223` (`PowerMap+568`); `$C25E`-`$C261` (`PowerMap+654`); `$C28E`-`$C291` (`PowerMap+702`); 12 more ranges |
| Writes | `$86C5`-`$86C8` (`ZonePowered`, `CellKind`, `BuildingType`, `ZoneCentre`); `$873B` (`ZoneCentreCell`); `$D2B0`-`$D2C8` (`CityMap+3680`); `$D315`-`$D324` (`CityMap+3781`); `$D430`-`$D448` (`CityMap+4064`); `$D495`-`$D4A4` (`CityMap+4165`); 7 more ranges |

### `ZoneStep` (`$8789`)

**A zone or building: count it powered or not, widen the extent, then the zone's growth or the building's routine**

L1 36 698.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 3,108 t-states own (0.00 %) |
| Runs (the other recordings) | 36,684 calls (`stage1/rec/metro` 14,688, `stage1/rec/city2` 8,339, `stage1/rec/city` 6,904 and 6 more) |
| Called from | `PutBuilding`, `PutZoneBuilding`, `StampPollutionIX`, `ScanCity`, `GrowZone`, `DeclineZone`, `CommercialStep`, `ComBuildingStep`, `IndustrialStep`, `PoliceStep`, `FireStep`, `StadiumStep`, `SeaportStep`, `AirportStep` |
| Calls | `CountPowered`, `WidenExtent`, `BuildingStep` (tail) |
| Reads | `$86C6`-`$86C8` (`CellKind`, `BuildingType`, `ZoneCentre`) |
| Writes | `$8785`-`$8788` (`CurCell`, `CurAddr`); `$8869` (`Density`) |

### `CountPowered` (`$87AA`)

**PoweredZones or UnpoweredZones + 1**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 1,288 t-states own (0.00 %) |
| Runs (the other recordings) | 36,684 calls (`stage1/rec/metro` 14,688, `stage1/rec/city2` 8,339, `stage1/rec/city` 6,904 and 6 more) |
| Called from | `ZoneStep` |
| Reads | `$845E`-`$8461` (`UnpoweredZones`, `PoweredZones`); `$86C5` (`ZonePowered`) |
| Writes | `$845E`-`$8461` (`UnpoweredZones`, `PoweredZones`) |

### `WidenExtent` (`$87CC`)

**ExtentCols and ExtentRows take in CurCell**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 882 t-states own (0.00 %) |
| Runs (the other recordings) | 36,684 calls (`stage1/rec/metro` 14,688, `stage1/rec/city2` 8,339, `stage1/rec/city` 6,904 and 6 more) |
| Called from | `ZoneStep` |
| Calls | `MinMax` (falls into) |
| Reads | `$8785`-`$8786` (`CurCell`) |

### `MinMax` (`$87DB`)

**(HL) = max, (HL+1) = min with A**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 28 calls, 1,568 t-states own (0.00 %) |
| Runs (the other recordings) | 73,368 calls (`stage1/rec/metro` 29,376, `stage1/rec/city2` 16,678, `stage1/rec/city` 13,808 and 6 more) |
| Called from | `WidenExtent` (falls into) |
| Reads | `$87C8`-`$87CB` (`ExtentCols`, `ExtentRows`) |
| Writes | `$87C8`-`$87CB` (`ExtentCols`, `ExtentRows`) |

### `ZoneByKind` (`$87E4`)

**Density 0; the R, C or I zone's growth**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ResidentialStep` (tail), `CommercialStep` (tail), `IndustrialStep` (tail) |

### `BuildingStep` (`$886B`)

**Look up the building's type in BuildingKinds and jump to its routine**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14,526 calls (`stage1/rec/metro` 6,048, `stage1/rec/city2` 3,718, `stage1/rec/city` 2,811 and 5 more) |
| Called from | `ZoneStep` (tail) |
| Calls | `ComBuildingStep`, `IndBuildingStep`, `CoalStep`, `NuclearStep`, `PoliceStep`, `FireStep`, `StadiumStep`, `SeaportStep`, `AirportStep` |
| Reads | `$86C7` (`BuildingType`); `$87FB`-`$8862` (`BuildingRoutines`, `BuildingKinds`) |
| Writes | `$8869`-`$886A` (`Density`, `BuildingLevel`) |

### `CellStep` (`$8898`)

**A plain cell: fire `$45`, flood `$44`, radiation `$59`; roads and rails counted and decayed**

L1 10 084 463.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 153,148 calls, 30,948,037 t-states own (2.06 %) |
| Runs (the other recordings) | 9,931,315 calls (`stage1/rec/city2` 2,021,395, `stage1/rec/city` 1,985,416, `stage1/rec/metro` 1,889,671 and 7 more) |
| Called from | `StampPollutionIX`, `ScanCity`, `RoadCell`, `RailCell`, `ToRubble`, `ToLand`, `Spread` |
| Calls | `CellFlagsOf`, `RadiationCell` (tail), `FireCell` (tail), `FloodCell` (tail) |
| Reads | `$8464`-`$846D` (`TransportUpkeep`, `PoliceUpkeep`, `FireUpkeep`, `RoadCount` and 1 more); `$8787`-`$8788` (`CurAddr`); `$88C5` (`RoadDecay`); `$8902` (`RailDecay`); `$C450`-`$E84F` (`CityMap`) |
| Writes | `$8464`-`$846D` (`TransportUpkeep`, `PoliceUpkeep`, `FireUpkeep`, `RoadCount` and 1 more); `$8785`-`$8788` (`CurCell`, `CurAddr`); `$8F97`-`$8F98` (`Funds`) |

### `RoadCell` (`$88C6`)

**Count the road (RoadCount, upkeep + 1, a bridge + 3); with RoadDecay it may crumble to `$3A`**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `CellStep` |

### `RailCell` (`$8903`)

**Count the rail (RailCount, upkeep + 4, a bridge + 6), StartTrain; with RailDecay it may crumble**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `StartTrain`, `CellStep` |

### `RadiationCell` (`$8942`)

**`$59`: with 1 in 4096 rubble, else pollution `$40` round it**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 538 calls (`stage1/rec/disasters` 538) |
| Called from | `CellStep` (tail) |
| Calls | `Random`, `StampPollution` (tail) |
| Reads | `$5CC4`-`$5CC5` (`RandomSeed`) |
| Writes | `$7CBF` (`PollutionStrength`) |

### `ToRubble` (`$8956`)

**the cell becomes `$3A`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 104 calls (`stage1/rec/disasters` 104) |
| Called from | `FireCell` (tail), `Spread` (tail) |
| Calls | `CellStep` |
| Reads | `$8787`-`$8788` (`CurAddr`) |
| Writes | `$D26A`-`$D2CC` (`CityMap+3610`); `$D32B`-`$D32D` (`CityMap+3803`); `$D38A`-`$D38D` (`CityMap+3898`); `$D3EA`-`$D3ED` (`CityMap+3994`); `$D44A`-`$D44D` (`CityMap+4090`); `$D4AB`-`$D4AD` (`CityMap+4187`); 2 more ranges |

### `ToLand` (`$895C`)

**the cell becomes land 2**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `CellStep` |

### `FireCell` (`$8962`)

**`$45`: FireCells + 1; put out with a chance of (FireCover + 1) / 16, else Spread**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 715 calls (`stage1/rec/disasters` 715) |
| Called from | `CellStep` (tail) |
| Calls | `Random`, `FireAt`, `ToRubble` (tail), `Spread` (tail) |
| Reads | `$847E`-`$847F` (`FireCells`) |
| Writes | `$847E`-`$847F` (`FireCells`); `$8998`-`$8999` (`SpreadCode`, `SpreadFlood`) |

### `FloodCell` (`$8986`)

**`$44`: while FloodLeft, spread the water; then the cell dries to land**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 146 calls (`stage1/rec/disasters` 146) |
| Called from | `CellStep` (tail) |
| Calls | `Spread` (tail) |
| Reads | `$8787`-`$8788` (`CurAddr`); `$8985` (`FloodLeft`) |
| Writes | `$8985` (`FloodLeft`); `$8998`-`$8999` (`SpreadCode`, `SpreadFlood`); `$C882` (`CityMap+1074`); `$C9BE`-`$CA7F` (`CityMap+1390`); `$CE37`-`$CF5A` (`CityMap+2535`); `$D45D`-`$D69F` (`CityMap+4109`); 4 more ranges |

### `Spread` (`$899B`)

**Each of the four neighbours that burns (flags bit 7, a building) or floods: 1 in 8 catches; a fire with nothing round dies with 1 in 4**

No edge check: the JR NC,SpreadNext after MapAddr is dead, because MapAddr always sets carry. From row 0 the step up lands in the ROM (`$23F0` + column), from row 95 the step down in IconTiles (`$E850` + column); from column 95 the step right is column 0 of the next row, from column 0 the step left is column 63 two rows down. Known only from the code.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 768 calls (`stage1/rec/disasters` 768) |
| Called from | `FireCell` (tail), `FloodCell` (tail) |
| Calls | `Random`, `MapAddr`, `CellFlagsOf`, `StepDir`, `CellStep`, `ToRubble` (tail), `SpreadTo` |
| Reads | `$8785`-`$8786` (`CurCell`); `$8999`-`$899A` (`SpreadFlood`, `SpreadCount`); `$D209`-`$D20D` (`CityMap+3513`); `$D266`-`$D2CD` (`CityMap+3606`); `$D326`-`$D32E` (`CityMap+3798`); `$D388`-`$D38E` (`CityMap+3896`); 4 more ranges |
| Writes | `$899A` (`SpreadCount`) |

### `SpreadTo` (`$89EA`)

**The neighbour at HL takes SpreadCode: a whole building (FillBuilding), else the cell (not the bridges, not water for floods)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 136 calls (`stage1/rec/disasters` 136) |
| Called from | `Spread` |
| Calls | `FillBuilding` (tail) |
| Reads | `$726B`-`$7272` (`BulldozeKeep`); `$8998`-`$8999` (`SpreadCode`, `SpreadFlood`); `$C822` (`CityMap+978`); `$C9BE`-`$CA7F` (`CityMap+1390`); `$CE37`-`$CF5A` (`CityMap+2535`); `$D269`-`$D2C9` (`CityMap+3609`); 6 more ranges |
| Writes | `$C9BE`-`$CA7F` (`CityMap+1390`); `$CE37`-`$CF5A` (`CityMap+2535`); `$D269`-`$D2C9` (`CityMap+3609`); `$D388`-`$D3E9` (`CityMap+3896`); `$D448`-`$D7A2` (`CityMap+4088`); `$DADD`-`$DADE` (`CityMap+5773`); 2 more ranges |

### `PickFrameCell` (`$8A20`)

**BC = a random one of the eight frame cells round CurCell; IX its ZoneFrame row**

L1 51 171.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 51,171 calls (`stage1/rec/metro` 18,814, `stage1/rec/bankrupt` 10,520, `stage1/rec/city2` 7,261 and 5 more) |
| Called from | `GrowZone`, `DeclineZone` |
| Calls | `Random` |
| Reads | `$8785`-`$8786` (`CurCell`); `$8A08`-`$8A1E` (`ZoneFrame`) |

### `GrowZone` (`$8A40`)

**GrowTries (`$8F67`) times: a frame cell one house up (GrowCell); stop at the first that grows**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,667 calls (`stage1/rec/metro` 2,691, `stage1/rec/city2` 1,652, `stage1/rec/city` 1,528 and 3 more) |
| Called from | `ResidentialStep` (tail) |
| Calls | `ZoneStep`, `PickFrameCell`, `GrowCell` |
| Reads | `$8F67` (`GrowTries`) |

### `GrowCell` (`$8A53`)

**A frame cell (CellFlags bit 4): the empty frame becomes house `$3C`, a house `$3C-$42` one more; `$43` full (carry)**

L1 6862.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,862 calls (`stage1/rec/metro` 2,748, `stage1/rec/city2` 1,727, `stage1/rec/city` 1,589 and 3 more) |
| Called from | `GrowZone` |
| Calls | `MapAddr`, `CellFlagsOf`, `TripWalk` (tail) |
| Reads | `$8A0A`-`$8A1F` (`ZoneFrame+2`); `$D24F`-`$D326` (`CityMap+3583`); `$D374`-`$D383` (`CityMap+3876`); `$D4EF`-`$D5C9` (`CityMap+4255`); `$D614`-`$D625` (`CityMap+4548`); `$D674`-`$D685` (`CityMap+4644`); 5 more ranges |
| Writes | `$D24F`-`$D326` (`CityMap+3583`); `$D374`-`$D383` (`CityMap+3876`); `$D4EF`-`$D5C9` (`CityMap+4255`); `$D614`-`$D625` (`CityMap+4548`); `$D674`-`$D685` (`CityMap+4644`); `$D860`-`$D8DA` (`CityMap+5136`); 3 more ranges |

### `DeclineZone` (`$8A70`)

**GrowTries times: a frame cell one house down (DeclineCell)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11,133 calls (`stage1/rec/metro` 4,106, `stage1/rec/city2` 2,079, `stage1/rec/city` 1,652 and 5 more) |
| Called from | `ResidentialStep` (tail) |
| Calls | `ZoneStep`, `PickFrameCell`, `DeclineCell` |
| Reads | `$8F67` (`GrowTries`) |

### `DeclineCell` (`$8A83`)

**A house one down; `$3C` goes back to the empty frame cell; an empty frame cell does not decline (carry)**

L1 44 309.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 44,309 calls (`stage1/rec/metro` 16,066, `stage1/rec/bankrupt` 10,520, `stage1/rec/growth` 5,831 and 5 more) |
| Called from | `DeclineZone` |
| Calls | `MapAddr`, `CellFlagsOf`, `TripWalk` (tail) |
| Reads | `$8A0A`-`$8A1F` (`ZoneFrame+2`); `$D24F`-`$D388` (`CityMap+3583`); `$D434`-`$D448` (`CityMap+4068`); `$D494`-`$D4A8` (`CityMap+4164`); `$D4EF`-`$D5C9` (`CityMap+4255`); `$D611`-`$D628` (`CityMap+4545`); 7 more ranges |
| Writes | `$D24F`-`$D326` (`CityMap+3583`); `$D374`-`$D383` (`CityMap+3876`); `$D4EF`-`$D5C9` (`CityMap+4255`); `$D614`-`$D625` (`CityMap+4548`); `$D674`-`$D685` (`CityMap+4644`); `$D860`-`$D87A` (`CityMap+5136`); 4 more ranges |

### `ResidentialStep` (`$8AA3`)

**The R zone: ResPop + 1, Population + 16 Density, a trip to C or I (when Random AND 63 < Density), the score; grow or decline**

Grows while Density < ResTile (ZoneScore / 2), else declines; a full zone (Density 63+) becomes a 3 x 3 building: a ChurchNeed or HospitalNeed building first (`$1B`, `$12`), else the residential block (tile `$88`). L1 17 802.

[Animation: `ResidentialStep` at work](img/routines/ResidentialStep.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17,802 calls (`stage1/rec/metro` 6,798, `stage1/rec/city2` 3,731, `stage1/rec/city` 3,180 and 5 more) |
| Called from | `ZoneByKind` (tail) |
| Calls | `Random`, `ZonePollution`, `ScanRing`, `ResidentialScore`, `AddPopulation`, `MakeTrip`, `GrowZone` (tail), `DeclineZone` (tail) |
| Reads | `$7E1A` (`RingTransport`); `$7F11` (`ResTile`); `$827C`-`$827D` (`ResDemand`); `$8446`-`$8447` (`ResPop`); `$8785`-`$8786` (`CurCell`); `$8869` (`Density`) |
| Writes | `$7EC2`-`$7EC3` (`ZoneDemand`); `$8446`-`$8447` (`ResPop`); `$8568` (`TripMade`); `$865E`-`$865F` (`TripTargets`) |

### `ResBuildingStep` (`$8B37`)

**A residential block (types `$11-$14`): count, the trip, the score; with the growth chance a block of level ResLevel / 2, or back to a full zone**

Below score 128 (ResLevel `$0F`) the block goes back to the houses zone ResRevertZone. It copies only the low byte of ResDemand into ZoneDemand (LD A,(ResDemand) at `$8B6F`), so the high byte left by the previous zone decides the sign; it acts on the IndChance mask and does not test power. No bot recording ran it; a block grew in the stage 2 ceiling run (work/stage2/ceiling.log, frame 80 000, R blocks 1), so ResBuildingStep runs there.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ResRevert` (`$8BA9`)

**Put ResRevertZone (or, from `$8BAD`, the pattern at IX) at the building**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CommercialStep` (`$8BC4`)

**The C zone: ComPop + 1; powered: ring, a trip to R or I (1 in 32 - Density), the score; with the C chance a building of its level, or back to an empty zone**

L1 2575.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,575 calls (`stage1/rec/metro` 1,056, `stage1/rec/city2` 548, `stage1/rec/city` 541 and 4 more) |
| Called from | `ZoneByKind` (tail) |
| Calls | `ZoneStep`, `ComBuildingStep` (tail) |
| Reads | `$8448`-`$8449` (`ComPop`); `$86C5` (`ZonePowered`); `$8785`-`$8786` (`CurCell`) |
| Writes | `$8448`-`$8449` (`ComPop`); `$8785`-`$8786` (`CurCell`) |

### `ComBuildingStep` (`$8BE0`)

**a commercial building (types `$15-$18`): the same from the building's corner**

A building that reverts mid-scan is counted twice in the pass: the reverted 3 x 3 zone is met again by ScanCity.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 2 more) |
| Called from | `BuildingStep`, `CommercialStep` (tail) |
| Calls | `Random`, `PutZoneBuilding` (tail), `ZonePollution`, `ScanRing`, `CommercialScore`, `MakeTrip`, `ZoneStep`, `NoGrowthAlone` |
| Reads | `$7E1A` (`RingTransport`); `$7F43` (`ComLevel`); `$827E`-`$827F` (`ComDemand`); `$8448`-`$8449` (`ComPop`); `$8785`-`$8786` (`CurCell`); `$8869` (`Density`); 2 more ranges |
| Writes | `$7EC2`-`$7EC3` (`ZoneDemand`); `$8448`-`$8449` (`ComPop`); `$8568` (`TripMade`); `$865E`-`$865F` (`TripTargets`) |

### `ComRevert` (`$8C4A`)

**Put ComEmptyZone at the zone**

L1 126.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `MapAddr`, `PutBuilding` (tail) |

### `IndustrialStep` (`$8C5B`)

**The I zone: IndPop + 1; powered: ring, a trip to R, the score (pollution not counted); with the I chance a building of its level, or back; pollution 4 x IndLevel**

L1 1795.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 1,134 t-states own (0.00 %) |
| Runs (the other recordings) | 1,781 calls (`stage1/rec/metro` 786, `stage1/rec/city` 372, `stage1/rec/city2` 342 and 4 more) |
| Called from | `ZoneByKind` (tail) |
| Calls | `ZoneStep`, `IndBuildingStep` (tail) |
| Reads | `$844A`-`$844B` (`IndPop`); `$86C5` (`ZonePowered`); `$8785`-`$8786` (`CurCell`) |
| Writes | `$844A`-`$844B` (`IndPop`); `$8785`-`$8786` (`CurCell`) |

### `IndBuildingStep` (`$8C77`)

**an industrial building (types `$1A-$1D`)**

A building that reverts mid-scan is counted twice in the pass: the reverted 3 x 3 zone is met again by ScanCity (IndPop 12 with 8 I zones, city frame 29 000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 2 more) |
| Called from | `BuildingStep`, `IndustrialStep` (tail) |
| Calls | `Random`, `PutZoneBuilding`, `StampPollution` (tail), `ScanRing`, `IndustrialScore`, `MakeTrip`, `NoGrowthAlone` |
| Reads | `$7E1A` (`RingTransport`); `$7F5D` (`IndLevel`); `$8280`-`$8281` (`IndDemand`); `$844A`-`$844B` (`IndPop`); `$8785`-`$8786` (`CurCell`); `$8869` (`Density`); 1 more ranges |
| Writes | `$7CBF` (`PollutionStrength`); `$7EBF`-`$7EC3` (`ZonePollutionMax`, `ZoneTrafficMax`, `ZoneScore`, `ZoneDemand`); `$844A`-`$844B` (`IndPop`); `$8568` (`TripMade`); `$865E`-`$865F` (`TripTargets`) |

### `NoGrowthAlone` (`$8CE0`)

**A = 0 when last month's population (LastPop) was 0, else A kept: a city of nobody falls back**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,080 calls (`stage1/rec/metro` 1,898, `stage1/rec/city2` 1,097, `stage1/rec/city` 795 and 2 more) |
| Called from | `ComBuildingStep`, `IndBuildingStep` |
| Reads | `$8E8A`-`$8E8C` (`LastPop`) |

### `IndRevert` (`$8CFA`)

**Put IndEmptyZone at the zone**

L1 719.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `MapAddr`, `PutBuilding` (tail) |

### `CoalStep` (`$8D0B`)

**A coal station: CoalCount + 1, pollution `$FF` round it**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/growth`, `stage1/rec/menus`, `stage1/rec/tools` and 1 more) |
| Called from | `BuildingStep` |
| Calls | `StampPollution` (tail), `ZoneScoreOf` |
| Reads | `$8456`-`$8457` (`CoalCount`) |
| Writes | `$7CBF` (`PollutionStrength`); `$7E1B` (`RingAmenity`); `$7EBF`-`$7EC2` (`ZonePollutionMax`, `ZoneTrafficMax`, `ZoneScore`, `ZoneDemand`); `$8456`-`$8457` (`CoalCount`); `$8568` (`TripMade`) |

### `NuclearStep` (`$8D2F`)

**A nuclear station: NuclearCount + 1, Meltdown (when pending), pollution `$30`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 2 more) |
| Called from | `BuildingStep` |
| Calls | `Meltdown`, `StampPollution` (tail), `ZoneScoreOf` |
| Reads | `$8454`-`$8455` (`NuclearCount`) |
| Writes | `$7CBF` (`PollutionStrength`); `$7E1B` (`RingAmenity`); `$7EBF`-`$7EC2` (`ZonePollutionMax`, `ZoneTrafficMax`, `ZoneScore`, `ZoneDemand`); `$8454`-`$8455` (`NuclearCount`); `$8568` (`TripMade`) |

### `PoliceStep` (`$8D56`)

**A police station: PoliceUpkeep (`$8466`) + 100 (saturating, before the power test); powered, PoliceCount + 1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 4 more) |
| Called from | `BuildingStep` |
| Calls | `ZoneStep` |
| Reads | `$844C`-`$844D` (`PoliceCount`); `$8466`-`$8467` (`PoliceUpkeep`); `$86C5` (`ZonePowered`) |
| Writes | `$844C`-`$844D` (`PoliceCount`); `$8466`-`$8467` (`PoliceUpkeep`) |

### `FireStep` (`$8D73`)

**A fire station: FireUpkeep (`$8468`) + 100 (saturating, before the power test); powered, FireCount + 1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 4 more) |
| Called from | `BuildingStep` |
| Calls | `ZoneStep` |
| Reads | `$844E`-`$844F` (`FireCount`); `$8468`-`$8469` (`FireUpkeep`); `$86C5` (`ZonePowered`) |
| Writes | `$844E`-`$844F` (`FireCount`); `$8468`-`$8469` (`FireUpkeep`) |

### `ChurchStep` (`$8D90`)

**Type 2: ChurchCount + 1; unpowered, with the IndChance mask back to an empty R zone (a church stands in ceiling-end.szx)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HospitalStep` (`$8DB5`)

**Type 3: HospitalCount + 1; the same**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StadiumStep` (`$8DDA`)

**A powered stadium with transport: 1 in 32 a trip to R; StadiumCount + 1 unless a trip was tried and failed**

StadiumCount + 1 only when powered, with transport in the 4 x 4 ring, and unless a trip was tried and lost. The city recording's stadium is never counted (StadiumCount 0 in all 311 samples). L1 648.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/city2`, `stage1/rec/metro`, `stage1/rec/city` and 2 more) |
| Called from | `BuildingStep` |
| Calls | `ScanRingSize`, `ZoneStep` |
| Reads | `$7E1A` (`RingTransport`); `$86C5` (`ZonePowered`); `$8785`-`$8786` (`CurCell`) |

### `SeaportStep` (`$8E10`)

**A powered seaport with water and transport round it: 1 in 32 a trip to I; SeaportCount + 1; pollution `$60`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/ports`) |
| Called from | `BuildingStep` |
| Calls | `ZoneStep` |
| Reads | `$86C5` (`ZonePowered`) |

### `AirportStep` (`$8E52`)

**A powered airport (6 x 6): 1 in 32 a trip to C; AirportCount + 1; StartPlane**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/tools`) |
| Called from | `BuildingStep` |
| Calls | `ZoneStep` |
| Reads | `$86C5` (`ZonePowered`) |

### `MonthEnd` (`$8E94`)

**LastPop; in December: the year's populations, the costs to the budget (`$9311-$9315`), the budget (shown, or auto), Funds**

L1 934; the December branch L1 77.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 776 t-states own (0.00 %) |
| Runs (the other recordings) | 926 calls (`stage1/rec/city2` 218, `stage1/rec/metro` 204, `stage1/rec/city` 189 and 6 more) |
| Called from | `SimTask` |
| Calls | `TaxIncomeOf`, `BudgetFigures`, `ApplyFunding` |
| Reads | `$8443`-`$8445` (`Population`); `$8464`-`$8469` (`TransportUpkeep`, `PoliceUpkeep`, `FireUpkeep`); `$8E90`-`$8E93` (`PopLastYear`, `BudgetDue`); `$8F9B` (`Month`); `$9326`-`$9328` (`FundsAfter`); `$A32C` (`AutoBudget`) |
| Writes | `$8E8A`-`$8E93` (`LastPop`, `PopYearBefore`, `PopLastYear`, `BudgetDue`); `$8F97`-`$8F99` (`Funds`); `$9311`-`$9316` (`TransportCost`, `PoliceCost`, `FireCost`) |

### `Averages2` (`$8F05`)

**AvgCrime, AvgLandValue, LastBuildings**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 3,360 t-states own (0.00 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Calls | `Div16` |
| Reads | `$8462`-`$8475` (`BuildingCount`, `TransportUpkeep`, `PoliceUpkeep`, `FireUpkeep` and 6 more) |
| Writes | `$8F01`-`$8F04` (`AvgCrime`, `AvgLandValue`, `LastBuildings`) |

### `ServiceNeeds` (`$8F31`)

**ServiceNeeds**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 4,224 t-states own (0.00 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Calls | `Div8` |
| Reads | `$8446`-`$8453` (`ResPop`, `ComPop`, `IndPop`, `PoliceCount` and 3 more) |
| Writes | `$8F2F`-`$8F30` (`HospitalNeed`, `ChurchNeed`) |

### `SetSpeed` (`$8F80`)

**Copy SpeedTable[Speed `$A3AB`] to GrowTries-MonthMask**

L1 1101.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 3,247 t-states own (0.00 %) |
| Runs (the other recordings) | 1,084 calls (`stage1/rec/city2` 219, `stage1/rec/city` 216, `stage1/rec/metro` 205 and 7 more) |
| Called from | `SimTask` |
| Reads | `$8F6C`-`$8F7F` (`SpeedTable`); `$A3AB` (`Speed`) |
| Writes | `$8F67`-`$8F6B` (`GrowTries`, `IndChance`, `ComChance`, `SpeedSpare` and 1 more) |

## uitask

`src/game/uitask.asm`

### `UiTask` (`$8FA0`)

**The UI task's start: the simulation task made, the status panel, the start menu (A51C), the landscape, the view; then the UI loop**

L1 1 (after the mover).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 93,074,671 t-states own (6.18 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 7 more) |
| Called from | `Entry` (tail), `DrawPointer`, `ErasePointer`, `TrackBox`, `InvertBox`, `PrintFunds`, `PrintDate`, `MovePointer`, `Click`, `DrawView`, `ToolKeys`, `ToolClick`, `ShowTool`, `DrawMovers`, `Periodic`, `FundsChanged`, `AnimateFire`, `AnimateFlood`, `StartFires`, `StartFlood`, `RandomDisaster`, `RunDisaster`, `Interrupt` |
| Calls | `ClearTopBlack`, `DrawPointer`, `ErasePointer`, `TrackBox`, `DrawStatusPanel`, `MovePointer`, `Click`, `DrawViewRowPass`, `DrawView`, `ClearWindowArea`, `DrawMenu`, `RunMenu`, `NewLandscape`, `ToolKeys`, `DrawMovers`, `ShiftScroll`, `MapsWindow`, `StartSimulation`, `Periodic`, `FundsChanged`, `AnimateFire`, `AnimateFlood`, `BudgetWindow` |
| Reads | `$5B06` (`KeyRowEnter`); `$8E93` (`BudgetDue`); `$8F9F` (`PassCount`); `$A511` (`MapsDue`) |
| Writes | `$8F9F` (`PassCount`); `$F705` (`SwitchOff`); `$F753` (`PrintAttr`) |

### `Periodic` (`$901D`)

**By PassCount: the advice every 32, the movers every 16, and in the 16-pass cycle Funds, the date, two tile animations, a disaster, the disaster draw**

L1 158 073.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 287,075 t-states own (0.02 %) |
| Runs (the other recordings) | 156,331 calls (`stage1/rec/metro` 38,769, `stage1/rec/city2` 34,793, `stage1/rec/city` 31,408 and 7 more) |
| Called from | `PrintPadded`, `MoveTrain`, `UiTask`, `Interrupt` |
| Calls | `PrintFunds` (tail), `PrintDate` (tail), `UiTask`, `MoveDisasters`, `AnimateFire` (tail), `AnimateFlood` (tail), `RandomDisaster` (tail), `RunDisaster` (tail), `ShowAdvice` |
| Reads | `$8F9F` (`PassCount`); `$ED38`-`$ED57` (`CellTiles+720`) |
| Writes | `$EC88`-`$EC97` (`CellTiles+544`) |

### `MoveDisasters` (`$904D`)

**The plane, the tornado, the train**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 4,928 t-states own (0.00 %) |
| Runs (the other recordings) | 9,772 calls (`stage1/rec/metro` 2,423, `stage1/rec/city2` 2,174, `stage1/rec/city` 1,963 and 7 more) |
| Called from | `MovePlane`, `MoveTornado`, `Periodic`, `Interrupt` |
| Calls | `MoveTrain` (tail), `MovePlane`, `MoveTornado` |

### `FundsChanged` (`$9058`)

**When Funds changed: redraw the palette and the tool**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,776 calls, 117,374 t-states own (0.01 %) |
| Runs (the other recordings) | 156,339 calls (`stage1/rec/metro` 38,783, `stage1/rec/city2` 34,796, `stage1/rec/city` 31,402 and 7 more) |
| Called from | `DrawToolIcons`, `UiTask`, `Interrupt` |
| Calls | `DrawToolIcons`, `ShowTool` (tail), `UiTask` |
| Reads | `$8F97`-`$8F98` (`Funds`); `$9056`-`$9057` (`LastFunds`) |
| Writes | `$9056`-`$9057` (`LastFunds`) |

### `AnimateFire` (`$906D`)

**Tile `$45` (fire, `$EC90`) from one of two frames (`$ED38`, `$ED40`) by PassCount bit 4: the Random 0-3 added first never carries into it at the Periodic call (PassCount AND 15 = 2)**

[Animation: `AnimateFire` at work](img/routines/AnimateFire.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 30,179 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 6 more) |
| Called from | `Random`, `UiTask`, `Periodic` (tail), `Interrupt` |
| Calls | `Random`, `UiTask` |
| Reads | `$8F9F` (`PassCount`); `$ED38`-`$ED47` (`CellTiles+720`) |
| Writes | `$EC90`-`$EC97` (`CellTiles+552`) |

### `AnimateFlood` (`$908A`)

**Tile `$44` (flood, `$EC88`) from `$ED48` or `$ED50`**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 113 calls, 30,179 t-states own (0.00 %) |
| Runs (the other recordings) | 1,686 calls (`stage1/rec/growth` 1,387, `stage1/rec/menus` 299) |
| Called from | `Random`, `UiTask`, `Periodic` (tail), `Interrupt` |
| Calls | `Random`, `UiTask` |
| Reads | `$8F9F` (`PassCount`); `$ED48`-`$ED57` (`CellTiles+736`) |
| Writes | `$EC88`-`$EC8F` (`CellTiles+544`) |

## disasters

`src/game/disasters.asm`

### `FireDisaster` (`$90A7`)

**message `$16` (FIRES HAVE BEEN DETECTED), the noise, Ignite 1 in 128 cells**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |
| Called from | `RunDisaster` (tail) |
| Calls | `FireNoise`, `SetAdvice` |

### `StartFires` (`$90AF`)

**Every map cell: 1 in 128 Ignite**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |
| Called from | `Random`, `Ignite`, `Earthquake`, `Interrupt` |
| Calls | `Random`, `UiTask`, `Ignite`, `Earthquake` |

### `Ignite` (`$90C4`)

**A flammable cell (flags bit 7) but trees: fire `$45`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 137 calls (`stage1/rec/disasters` 137) |
| Called from | `CellFlagsOf`, `StartFires`, `Interrupt` |
| Calls | `CellFlagsOf`, `StartFires` |
| Reads | `$C459`-`$C7B4` (`CityMap+9`); `$C84B`-`$CE61` (`CityMap+1019`); `$CFAD`-`$DA83` (`CityMap+2909`); `$DB34`-`$DE2E` (`CityMap+5860`); `$DF08`-`$E23C` (`CityMap+6840`); `$E328`-`$E5DD` (`CityMap+7896`); 2 more ranges |
| Writes | `$D2C6` (`CityMap+3702`); `$D55B` (`CityMap+4363`); `$D796` (`CityMap+4934`) |

### `FloodDisaster` (`$90D5`)

**message `$17` (COASTAL FLOODING DETECTED), the noise, the coast floods**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |
| Called from | `RunDisaster` (tail) |
| Calls | `FloodNoise`, `SetAdvice` |

### `StartFlood` (`$90DD`)

**Every coast cell (1-5): 1 in 32 flood `$44`; FloodLeft = 50**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/disasters` 2) |
| Called from | `Random`, `FloodNoise`, `Earthquake` (tail), `Interrupt` |
| Calls | `Random`, `UiTask` |
| Reads | `$C450`-`$E84F` (`CityMap`) |
| Writes | `$8985` (`FloodLeft`); `$C882` (`CityMap+1074`); `$C9DA`-`$CA20` (`CityMap+1418`); `$CE98`-`$CEF9` (`CityMap+2632`); `$D45F` (`CityMap+4111`); `$D93D` (`CityMap+5357`); 3 more ranges |

### `FireNoise` (`$9108`)

**127 NoiseBursts, gate falling**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |
| Called from | `FireDisaster` |
| Calls | `NoiseBurst` |

### `FloodNoise` (`$9116`)

**127 NoiseBursts, gate rising**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |
| Called from | `FloodDisaster`, `Interrupt` |
| Calls | `NoiseBurst`, `StartFlood` |

### `Earthquake` (`$9125`)

**message `$18` (MAJOR EARTHQUAKE DETECTED), a long noise, fires and the flood**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/disasters`) |
| Called from | `StartFires`, `Interrupt` |
| Calls | `NoiseBurst`, `StartFires`, `StartFlood` (tail), `SetAdvice` |

### `RandomDisaster` (`$9144`)

**Unless disasters are off (`$A43D`): a gate of 1 in 2048 (seed AND `$07FF` = 0), then Random AND 7 picks 1-6 (6 with a further 1 in 8); the gate fixes that draw, so only the seed `$0000` (next `$00FD`, 5) starts a disaster: always the tornado, about 1 in 65 536 a try**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 111 calls, 9,176 t-states own (0.00 %) |
| Runs (the other recordings) | 9,772 calls (`stage1/rec/metro` 2,423, `stage1/rec/city2` 2,175, `stage1/rec/city` 1,963 and 7 more) |
| Called from | `Random`, `Periodic` (tail), `Interrupt` |
| Calls | `Random`, `UiTask` |
| Reads | `$5CC4`-`$5CC5` (`RandomSeed`); `$A43D` (`DisastersOff`) |

### `RunDisaster` (`$916E`)

**1 fire, 2 flood, 3 earthquake, 4 air crash, 5 tornado, 6 meltdown**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 111 calls, 3,552 t-states own (0.00 %) |
| Runs (the other recordings) | 9,771 calls (`stage1/rec/metro` 2,423, `stage1/rec/city2` 2,175, `stage1/rec/city` 1,962 and 7 more) |
| Called from | `Periodic` (tail) |
| Calls | `AirCrash` (tail), `NuclearMeltdown` (tail), `StartTornado` (tail), `UiTask`, `FireDisaster` (tail), `FloodDisaster` (tail) |
| Reads | `$916D` (`DisasterDue`) |
| Writes | `$916D` (`DisasterDue`) |

## budget

`src/game/budget.asm`

### `BudgetWindow` (`$9194`)

**The year's budget window (the UI task, when BudgetDue): BudgetFigures, the window `$91BC` with the hook `$9346`; then the view**

L1 9.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rec/bankrupt` 5, `stage1/rec/menus` 1) |
| Called from | `NumberRepeat`, `UiTask` |
| Calls | `DrawView` (tail), `ShowWindow`, `TaxIncomeOf`, `BudgetFigures` |
| Writes | `$6942`-`$6943` (`MenuHook`); `$8E93` (`BudgetDue`); `$F705` (`SwitchOff`) |

### `TaxIncomeOf` (`$9329`)

**TaxIncome = PopLastYear / 100 x TaxRate**

L1 77.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 77 calls (`stage1/rec/city2` 18, `stage1/rec/metro` 17, `stage1/rec/city` 16 and 6 more) |
| Called from | `MonthEnd`, `BudgetWindow` |
| Calls | `Mul16`, `Div24By8` |
| Reads | `$8E90`-`$8E92` (`PopLastYear`); `$91E4` (`TaxRate`) |
| Writes | `$930E`-`$9310` (`TaxIncome`) |

### `BudgetHook` (`$9346`)

**The budget window's menu hook: recompute and print the figures while the player edits them**

[Animation: `BudgetHook` at work](img/routines/BudgetHook.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/city`, `stage1/rec/bankrupt`) |
| Called from | `CallMenuHook` |
| Calls | `BudgetFigures`, `PrintBudget` |
| Writes | `$F753` (`PrintAttr`) |

### `BudgetFigures` (`$9358`)

**FundsBefore, the three fundings (request x percent), each capped so the money does not go below 0, the totals**

L1 1918.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |
| Called from | `MonthEnd`, `BudgetWindow`, `BudgetHook` |
| Calls | `FundTransport`, `FundPolice`, `FundFire`, `BudgetTotals`, `CapTransport`, `CapPolice`, `CapFire` |
| Reads | `$8F97`-`$8F99` (`Funds`) |
| Writes | `$9323`-`$9325` (`FundsBefore`) |

### `FundTransport` (`$937C`)

**FundTransport**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |
| Called from | `BudgetFigures` |
| Calls | `Percent` |
| Reads | `$9256` (`TransportPercent`); `$9311`-`$9312` (`TransportCost`) |
| Writes | `$9317`-`$9318` (`TransportFunded`) |

### `FundPolice` (`$9389`)

**FundPolice**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |
| Called from | `BudgetFigures` |
| Calls | `Percent` |
| Reads | `$926F` (`PolicePercent`); `$9313`-`$9314` (`PoliceCost`) |
| Writes | `$9319`-`$931A` (`PoliceFunded`) |

### `FundFire` (`$9396`)

**FundFire**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |
| Called from | `BudgetFigures` |
| Calls | `Percent` |
| Reads | `$9288` (`FirePercent`); `$9315`-`$9316` (`FireCost`) |
| Writes | `$931B`-`$931C` (`FireFunded`) |

### `BudgetTotals` (`$93A3`)

**FundedTotal, CashFlow, FundsAfter = Funds - FundedTotal + TaxIncome**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |
| Called from | `BudgetFigures` |
| Calls | `Sub24`, `Add24` |
| Reads | `$8F97`-`$8F99` (`Funds`); `$930E`-`$931F` (`TaxIncome`, `TransportCost`, `PoliceCost`, `FireCost` and 4 more) |
| Writes | `$931D`-`$9328` (`FundedTotal`, `CashFlow`, `FundsBefore`, `FundsAfter`) |

### `CapTransport` (`$93F9`)

**TransportFunded at most FundsBefore + TaxIncome**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |
| Called from | `BudgetFigures` |
| Calls | `Sub24`, `Add24` |
| Reads | `$930E`-`$9325` (`TaxIncome`, `TransportCost`, `PoliceCost`, `FireCost` and 6 more) |
| Writes | `$93F6`-`$93F8` (`CapWork`) |

### `CapPolice` (`$9429`)

**PoliceFunded at most what is left after the transport**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |
| Called from | `BudgetFigures` |
| Calls | `Sub24`, `Add24` |
| Reads | `$930E`-`$9325` (`TaxIncome`, `TransportCost`, `PoliceCost`, `FireCost` and 6 more) |
| Writes | `$93F6`-`$93F8` (`CapWork`) |

### `CapFire` (`$9462`)

**FireFunded at most what is left after both**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |
| Called from | `BudgetFigures` |
| Calls | `Sub24`, `Add24` |
| Reads | `$930E`-`$9325` (`TaxIncome`, `TransportCost`, `PoliceCost`, `FireCost` and 6 more) |
| Writes | `$93F6`-`$93F8` (`CapWork`) |

### `PrintBudget` (`$94A4`)

**Print the figures into the budget window**

L1 1841.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,841 calls (`stage1/rec/menus` 1,669, `stage1/rec/city` 103, `stage1/rec/bankrupt` 69) |
| Called from | `BudgetHook` |
| Calls | `PrintNumberHL`, `PrintNumberVar` |
| Reads | `$9311`-`$931C` (`TransportCost`, `PoliceCost`, `FireCost`, `TransportFunded` and 2 more) |

### `Percent` (`$94FF`)

**HL = HL x A / 100**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,754 calls (`stage1/rec/menus` 5,013, `stage1/rec/city` 357, `stage1/rec/bankrupt` 225 and 6 more) |
| Called from | `FundTransport`, `FundPolice`, `FundFire` |
| Calls | `Mul16`, `Div24By8` (tail) |

### `ApplyFunding` (`$952A`)

**The year's fundings to the city: RoadDecay and RailDecay, PoliceStrength, FireStrength by the share granted**

A request below 20 counts as fully paid. The fire branch tests TransportCost against 20, not FireCost (a slip: with transport costs below 20 the fire is always fully strong, FireStrength = 15 whatever the funding). BUG: with transport at 20 or more and no fire station, FireCost / 8 = 0 and Div16 by zero returns 0, so FireStrength = 0 (city recording, frame 8 500, JAN 1903). L1 74.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 74 calls (`stage1/rec/city2` 18, `stage1/rec/metro` 17, `stage1/rec/city` 15 and 6 more) |
| Called from | `MonthEnd` |
| Calls | `Div16` |
| Reads | `$9311`-`$931C` (`TransportCost`, `PoliceCost`, `FireCost`, `TransportFunded` and 2 more); `$9512`-`$9522` (`DecayMasks+8`, `StrengthLevels`) |
| Writes | `$7C08` (`FireStrength`); `$7C31` (`PoliceStrength`); `$88C5` (`RoadDecay`); `$8902` (`RailDecay`) |

## evaluation

`src/game/evaluation.asm`

### `EvaluationWindow` (`$95B8`)

**The WINDOWS menu's EVALUATION: the window `$95D7` with the hook Evaluate**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/growth` and 2 more) |
| Called from | `NumberRepeat` |
| Calls | `DrawView` (tail), `ShowWindow` |
| Writes | `$6942`-`$6943` (`MenuHook`); `$F705` (`SwitchOff`) |

### `Evaluate` (`$9737`)

**The evaluation hook: the category, the figures; with a population, the problems, the score and the poll**

L1 18.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/city2`, `stage1/rec/metro`, `stage1/rec/growth` and 2 more) |
| Called from | `CallMenuHook` |
| Calls | `CategoryOf`, `PrintEvalFigures`, `Problems`, `ScoreOf`, `Poll` |
| Reads | `$8E8A`-`$8E8C` (`LastPop`) |

### `CategoryOf` (`$9760`)

**Category = how many CategoryLimits PopLastYear exceeds (a limit equal to it does not count)**

Only the evaluation window computes it, from the population at the last year's end: the category changes nothing in the game. L1 18.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |
| Called from | `Evaluate` |
| Calls | `Sub24` |
| Reads | `$8E90`-`$8E92` (`PopLastYear`); `$9750`-`$975F` (`CategoryLimits`, `Category`) |
| Writes | `$975F` (`Category`) |

### `PrintEvalFigures` (`$9792`)

**The level, the category, the population, the migration, the assessed value (CityValueLast) followed by 000 (x 1000: two CALL PrintZero and a fall-through)**

POPULATION is LastPop (last month's), not the year's population.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |
| Called from | `Evaluate` |
| Calls | `FindText`, `PrintPadded`, `PrintNumberVar`, `Sub24`, `PrintZero` (falls into) |
| Reads | `$65A3`-`$65A4` (`NumberEnd`); `$8E8D`-`$8E92` (`PopYearBefore`, `PopLastYear`); `$975F` (`Category`); `$A518` (`Level`) |
| Writes | `$978F`-`$9791` (`Migration`); `$F74F`-`$F750` (`PrintAddr`) |

### `PrintZero` (`$97F8`)

**Print "0" and step on**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 54 calls (`stage1/rec/city2` 15, `stage1/rec/metro` 15, `stage1/rec/growth` 12 and 2 more) |
| Called from | `PrintEvalFigures` (falls into) |
| Calls | `PrintChar`, `NextColumn` |

### `Problems` (`$9803`)

**Each problem 0-100 printed (red from 20): traffic AvgTraffic / 2, pollution / 2, crime / 4, fire 5 FireCells, taxes 4 (rate - 3), house prices AvgLandValue, unemployment PopBalance; plus UnpoweredZones / 4 and 4 for an advice**

L1 18.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/metro` 5, `stage1/rec/city2` 5, `stage1/rec/growth` 4 and 2 more) |
| Called from | `Evaluate` |
| Calls | `Clamp100`, `PrintProblem` |
| Reads | `$8265`-`$8266` (`PopBalance`); `$845E`-`$845F` (`UnpoweredZones`); `$849C` (`LastFireCells`); `$84DD` (`AvgPollution`); `$851A` (`AvgTraffic`); `$8F01`-`$8F02` (`AvgCrime`, `AvgLandValue`); 3 more ranges |
| Writes | `$9801`-`$9802` (`ProblemSum`) |

### `Clamp100` (`$98E4`)

**HL to 0-100**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 126 calls (`stage1/rec/city2` 35, `stage1/rec/metro` 35, `stage1/rec/growth` 28 and 2 more) |
| Called from | `Problems` |

### `ScoreOf` (`$98FC`)

**CityScore = 4 (250 - 3 ProblemSum), 0-1000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |
| Called from | `Evaluate` |
| Calls | `PrintNumberHL`, `Clamp1000` |
| Reads | `$9801`-`$9802` (`ProblemSum`) |
| Writes | `$98FA`-`$98FB` (`CityScore`) |

### `Clamp1000` (`$9919`)

**Clamp1000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |
| Called from | `ScoreOf` |

### `Poll` (`$9931`)

**Poll**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |
| Called from | `Evaluate` |
| Calls | `Random`, `PrintPercent` |
| Reads | `$5CC4`-`$5CC5` (`RandomSeed`); `$98FA`-`$98FB` (`CityScore`); `$992F`-`$9930` (`PollYes`, `PollNo`) |
| Writes | `$992F`-`$9930` (`PollYes`, `PollNo`) |

### `PrintProblem` (`$9970`)

**HL in 3 digits at BC, attribute `$42` (red) from 20**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 126 calls (`stage1/rec/metro` 35, `stage1/rec/city2` 35, `stage1/rec/growth` 28 and 2 more) |
| Called from | `Problems` |
| Calls | `ScreenAddr`, `Print3Digits` |
| Writes | `$F74F`-`$F753` (`PrintAddr`, `PrintCol`, `PrintRow`, `PrintAttr`) |

### `PrintPercent` (`$998B`)

**HL in 3 digits at BC**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rec/city2` 10, `stage1/rec/metro` 10, `stage1/rec/growth` 8 and 2 more) |
| Called from | `Poll` |
| Calls | `ScreenAddr`, `Print3Digits` (tail) |
| Writes | `$F74F`-`$F750` (`PrintAddr`) |

### `ShowAdvice` (`$9997`)

**Print GameTexts[23 + Advice] at row 6, column 1, padded to 30 columns**

L1 4944.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 56 calls, 4,144 t-states own (0.00 %) |
| Runs (the other recordings) | 4,889 calls (`stage1/rec/metro` 1,211, `stage1/rec/city2` 1,087, `stage1/rec/city` 982 and 7 more) |
| Called from | `FindText`, `Periodic`, `Interrupt` |
| Calls | `FindText`, `PrintPadded` (tail) |
| Reads | `$9996` (`Advice`) |

### `Advise` (`$99AD`)

**The advice: the first rule that fires sets Advice (the later ones may overwrite, CALL NC)**

In order: R at most a quarter of all zones (1), C at most an eighth (2), I (3); then, with people: roads fewer than zones from 10 zones (4), rails from 50 (5), no power station from 10 (6), no stadium from 20 R (7), no seaport from 30 I (8), no airport from 30 C (9), no fire station from 30 zones (10), no police from 25 (11), tax 12+ (12), transport underfunded (13), fire (14), police (15), 10+ unpowered zones (16), a brownout (17), pollution 60+ (19), crime 20+ (20), traffic 60+ (21). L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 3,440 t-states own (0.00 %) |
| Runs (the other recordings) | 1,073 calls (`stage1/rec/city2` 219, `stage1/rec/city` 215, `stage1/rec/metro` 205 and 6 more) |
| Called from | `SimTask` |
| Calls | `SetAdvice` (tail) |
| Reads | `$7C08` (`FireStrength`); `$7C31` (`PoliceStrength`); `$7FCC` (`Brownout`); `$8446`-`$846D` (`ResPop`, `ComPop`, `IndPop`, `PoliceCount` and 16 more); `$84DD` (`AvgPollution`); `$851A` (`AvgTraffic`); 5 more ranges |
| Writes | `$9996` (`Advice`); `$99AB`-`$99AC` (`AllZones`) |

### `SetAdvice` (`$9B4A`)

**Advice = A (the disasters' messages too)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 368 t-states own (0.00 %) |
| Runs (the other recordings) | 584 calls (`stage1/rec/metro` 367, `stage1/rec/bankrupt` 65, `stage1/rec/menus` 42 and 4 more) |
| Called from | `NuclearMeltdown`, `StartTornado`, `FireDisaster`, `FloodDisaster`, `Earthquake`, `Advise` (tail) |
| Writes | `$9996` (`Advice`) |

## overview

`src/game/overview.asm`

### `HighlightMapKey` (`$9B60`)

**Flip the bright bit of the current key's attribute**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 242 t-states own (0.00 %) |
| Runs (the other recordings) | 208 calls (`stage1/rec/menus` 100, `stage1/rec/city2` 56, `stage1/rec/metro` 52) |
| Called from | `MapsWindow` |
| Calls | `AttrAddr` |
| Reads | `$5883` (screen); `$9B4E`-`$9B4F` (`MapKeyCells`); `$9C2B` (`MapArea`) |
| Writes | `$5883` (screen) |

### `HighlightLayer` (`$9B76`)

**XOR `$46` over the current layer's row of the legend**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 758 t-states own (0.00 %) |
| Runs (the other recordings) | 208 calls (`stage1/rec/menus` 100, `stage1/rec/city2` 56, `stage1/rec/metro` 52) |
| Called from | `MapsWindow` |
| Calls | `AttrAddr` |
| Reads | `$5920`-`$5927` (screen); `$5940`-`$5947` (screen); `$5960`-`$5967` (screen); `$5980`-`$5987` (screen); `$59A0`-`$59A7` (screen); `$59C0`-`$59C7` (screen); 3 more ranges |
| Writes | `$5920`-`$5927` (screen); `$5940`-`$5947` (screen); `$5960`-`$5967` (screen); `$5980`-`$5987` (screen); `$59A0`-`$59A7` (screen); `$59C0`-`$59C7` (screen); 2 more ranges |

### `MapsKeys` (`$9B8B`)

**Every 4th loop: Q / A change the layer; SYMBOL SHIFT + a digit 1-9 the map area (MapsKeysDigit returns if SYMBOL SHIFT is up)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 100 calls (`stage1/rec/menus` 48, `stage1/rec/city2` 27, `stage1/rec/metro` 25) |
| Called from | `MapsWindow`, `Interrupt` |
| Calls | `MapsWindow` |
| Reads | `$5B01`-`$5B07` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 3 more); `$7B50` (`MapsCounter`); `$9D43` (`MapLayer`) |
| Writes | `$9D43` (`MapLayer`) |

### `OverviewCell` (`$9BC3`)

**Draw one cell as 4 x 4 pixels: every second pixel of every second line of its tile (or the building tile)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 864 calls, 171,222 t-states own (0.01 %) |
| Runs (the other recordings) | 32,068 calls (`stage1/rec/menus` 13,298, `stage1/rec/city2` 9,409, `stage1/rec/metro` 9,361) |
| Called from | `RoadTraffic`, `ShrinkLine`, `DrawOverview`, `Interrupt` |
| Calls | `RoadTraffic`, `ShrinkLine` (tail) |
| Reads | `$6558` (`BuildingLeft`) |

### `ShrinkLine` (`$9BF9`)

**One tile line pair to 4 pixels: bits 7, 5, 3, 1, into the left or right nibble**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3,456 calls, 713,430 t-states own (0.05 %) |
| Runs (the other recordings) | 128,271 calls (`stage1/rec/menus` 53,190, `stage1/rec/city2` 37,636, `stage1/rec/metro` 37,445) |
| Called from | `OverviewCell` (tail), `Interrupt` |
| Calls | `OverviewCell`, `DrawOverview` |
| Reads | `$4008`-`$497F` (screen); `$4A08`-`$4A7F` (screen); `$4B08`-`$4B7F` (screen); `$4C08`-`$4C7F` (screen); `$4D08`-`$4D7F` (screen); `$4E08`-`$4E7F` (screen); 3 more ranges |
| Writes | `$4008`-`$497F` (screen); `$4A08`-`$4A7F` (screen); `$4B08`-`$4B7F` (screen); `$4C08`-`$4C7F` (screen); `$4D08`-`$4D7F` (screen); `$4E08`-`$4E7F` (screen); 1 more ranges |

### `DrawOverview` (`$9C57`)

**Draw the 48 x 48 cells of MapArea at 4 x 4 pixels, coloured by the layer; stop at a key**

L1 105.

[Animation: `DrawOverview` at work](img/routines/DrawOverview.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 242,116 t-states own (0.02 %) |
| Runs (the other recordings) | 104 calls (`stage1/rec/menus` 50, `stage1/rec/city2` 28, `stage1/rec/metro` 26) |
| Called from | `AnyKey`, `NextPixelLine`, `MapsWindow`, `ShrinkLine`, `PutLayerAttr`, `LayerOf`, `Interrupt` |
| Calls | `AnyKey`, `NextPixelLine`, `MapsWindow`, `OverviewCell`, `PutLayerAttr`, `LayerOf` |
| Reads | `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`); `$9BD7`-`$9BD8` (`OverviewAt+1`); `$9C2B`-`$9C34` (`MapArea`, `OverviewSpare2`, `OverviewOrigin`, `RightNibble` and 2 more); `$9C45`-`$9C46` (`MapAreaCells`); `$C450`-`$CA7F` (`CityMap`); `$CAB0`-`$CADF` (`CityMap+1632`); 6 more ranges |
| Writes | `$6433` (`Blink`); `$6509`-`$650A` (`ViewCellPtr`); `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`); `$9BD7`-`$9BD8` (`OverviewAt+1`); `$9C2E`-`$9C32` (`OverviewOrigin`, `RightNibble`, `OverviewCellAt`) |

### `LayerColour` (`$9D02`)

**The attribute LayerColours[A] (0: none) for the cell**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21,456 calls (`stage1/rec/menus` 11,088, `stage1/rec/metro` 5,232, `stage1/rec/city2` 5,136) |
| Called from | `LayerOf` (tail) |
| Calls | `LayerOf` |

### `PutLayerAttr` (`$9D0C`)

**The attribute C at the overview cell's attribute address**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 866 calls, 58,237 t-states own (0.00 %) |
| Runs (the other recordings) | 32,073 calls (`stage1/rec/menus` 13,298, `stage1/rec/city2` 9,415, `stage1/rec/metro` 9,360) |
| Called from | `DrawOverview`, `Interrupt` |
| Calls | `DrawOverview` |
| Reads | `$9BD7`-`$9BD8` (`OverviewAt+1`) |
| Writes | `$5808`-`$597F` (screen) |

### `LayerOf` (`$9D44`)

**The overlay of the layer for the overview cell**

L1 32 928.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 864 calls, 277,193 t-states own (0.02 %) |
| Runs (the other recordings) | 32,085 calls (`stage1/rec/menus` 13,308, `stage1/rec/city2` 9,414, `stage1/rec/metro` 9,363) |
| Called from | `DrawOverview`, `LayerColour`, `Interrupt` |
| Calls | `Grid48`, `Grid24`, `CellFlagsOf`, `PowerBit`, `DrawOverview`, `LayerColour` (tail) |
| Reads | `$6509`-`$650A` (`ViewCellPtr`); `$753C`-`$753D` (`GridBase`); `$9C31`-`$9C32` (`OverviewCellAt`); `$9D43` (`MapLayer`); `$BFD0`-`$C0B9` (`PowerMap`); `$C450`-`$C95F` (`CityMap`); 7 more ranges |
| Writes | `$753C`-`$753D` (`GridBase`); `$F705` (`SwitchOff`) |

## saveload

`src/game/saveload.asm`

### `SaveCity` (`$9E09`)

**SAVE TO TAPE: the name, START TAPE, then a 31-byte header (flag `$FF`) and the 9216-byte map (flag `$FF`)**

The header SaveHeader: the 12-letter file name, Funds, its spare byte, Month, Year (7 bytes), a spare byte, the city name (12). Nothing else is saved: not the tax, the fundings, the options or the arrays. Known only from the code (stage 1's save recording ran it: L1 at `$9E09` none, as the save was reached through the menu action; see NOTES).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `NumberRepeat` |
| Calls | `FileNameWindow`, `WaitTapeStart`, `InputName`, `TapeSave`, `TapePause` |
| Reads | `$5F68`-`$5F73` (`CityName`); `$8F97`-`$8F9D` (`Funds`, `FundsSpare`, `Month`, `Year`) |
| Writes | `$A6D8`-`$A6DB` (`InputAt`, `InputBuffer`); `$A93C`-`$A94F` (`SaveFunds`, `SaveSpare`) |
| Ports out | `$00FE` |

### `LoadCity` (`$9E5A`)

**LOAD FROM TAPE: the name, SEARCHING, a 31-byte header (any name if the typed one is blank), then the map; only the first city on the tape loads**

Both blocks of a save carry flag `$FF`, and LoadHeader asks for 31 bytes with flag `$FF`. After a header whose name does not match, the next load meets that file's map block, takes its first 31 bytes as a header, fails the parity (the block is longer) and shows LoadErrorWindow: the search never reaches a second file, so the tape must stand at the wanted city. Known only from the code.

PopLastYear and LastPop are not restored: the previous city's values remain until the next month end.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `NumberRepeat` |
| Calls | `ClearTopBlack`, `ClearTopWhite`, `PrintInline`, `FileNameWindow`, `InputName` |
| Writes | `$A6D8`-`$A6DB` (`InputAt`, `InputBuffer`) |

### `LoadHeader` (`$9E89`)

**LoadHeader**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `PrintDigit` |
| Calls | `PrintInline`, `PrintFound`, `TapeLoad` |
| Reads | `$A924`-`$A93B` (`SaveName`, `SaveHeader`) |

### `LoadMap` (`$9ECC`)

**The map; on success Funds, the date and the name from the header**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `PrintDigit` |
| Calls | `ClearTopBlack`, `DrawStatusPanel`, `TapeLoad` |
| Reads | `$A93C`-`$A94F` (`SaveFunds`, `SaveSpare`) |
| Writes | `$5F68`-`$5F73` (`CityName`); `$8F97`-`$8F9D` (`Funds`, `FundsSpare`, `Month`, `Year`) |
| Ports out | `$00FE` |

### `PrintFound` (`$9F1A`)

**FOUND :- and the header's name**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/menus` 1) |
| Called from | `LoadHeader` |
| Calls | `PrintInline` |

### `PrintFileName` (`$9F2A`)

**The 12 letters at SaveName**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `PrintDigit` |
| Calls | `NextColumn`, `PrintGlyph` |
| Reads | `$A930`-`$A93B` (`SaveHeader`) |

## dialogs

`src/game/dialogs.asm`

### `NoPlant` (`$9FBE`)

**NONE: PlantChoice 0 (not run in the recordings)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ChooseNuclear` (`$9FC4`)

**PlantChoice 1**

L1 3.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/tools`, `stage1/rec/city`, `stage1/rec/growth` and 3 more) |
| Called from | `NumberRepeat` |
| Writes | `$9F40` (`PlantChoice`) |

### `Confirm` (`$9FD0`)

**ARE YOU SURE ?: carry set for YES**

L1 5.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/menus` 4, `stage1/rec/levels` 1) |
| Called from | `ExitSimCity` |
| Calls | `ShowInlineWindow` |

### `ConfirmNo` (`$A027`)

**OR A**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/levels`) |
| Called from | `NumberRepeat` |

### `ExitSimCity` (`$A0B1`)

**EXIT SIMCITY: confirmed, a new city with a new landscape**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/levels`) |
| Called from | `NumberRepeat` |
| Calls | `NewLandscape` (tail), `Confirm`, `LevelMenu` |
| Reads | `$5CC4`-`$5CC5` (`RandomSeed`) |
| Writes | `$6A8C`-`$6A8D` (`Gene`) |

### `AboutWindow` (`$A0C7`)

**ABOUT SIM CITY**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `NumberRepeat` |
| Calls | `ShowInlineWindow` |

### `LoadMenu` (`$A1F3`)

**LOADING MENU**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `NumberRepeat` |
| Calls | `ShowInlineWindow` |

### `SaveMenu` (`$A247`)

**SAVING MENU**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `NumberRepeat` |
| Calls | `ShowInlineWindow` |

### `FileNameWindow` (`$A29A`)

**TYPE FILE NAME, THEN PRESS ENTER**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |
| Called from | `SaveCity`, `LoadCity` |
| Calls | `ShowInlineWindow` |

### `LoadErrorWindow` (`$A2DC`)

**TAPE LOADING ERROR**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WaitTapeStart` (`$A2FE`)

**START TAPE AND PRESS SPACE: wait for SPACE**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/menus` 1) |
| Called from | `SaveCity` |
| Calls | `TapeWindow` |
| Ports in | `$7FFE` |

### `TapeWindow` (`$A309`)

**TapeWindow**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/menus` 1) |
| Called from | `WaitTapeStart` |
| Calls | `ShowInlineWindow` |

### `SpeedMenu` (`$A3AC`)

**SIMULATION SPEED**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/bankrupt`, `stage1/rec/city` and 3 more) |
| Called from | `NumberRepeat` |
| Calls | `ShowInlineWindow` |

### `SetSpeedItem` (`$A40D`)

**Speed = A; the asterisk moved to (HL)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/menus` 5) |
| Called from | `NumberRepeat` |
| Writes | `$A3AB` (`Speed`); `$A3D0`-`$A3F3` (`SpeedMarkFast`, `SpeedMarkNormal`, `SpeedMarkSlow`, `SpeedMarkPaused`) |

### `PickDisaster` (`$A4BA`)

**DisasterDue = the item + 1**

L1 6.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/disasters`) |
| Called from | `NumberRepeat` |
| Reads | `$6A7D` (`MenuSelected`) |
| Writes | `$916D` (`DisasterDue`) |

### `MapsItem` (`$A512`)

**MapsItem**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 30 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/city2`, `stage1/rec/menus`, `stage1/rec/metro`) |
| Called from | `NumberRepeat` |
| Writes | `$A511` (`MapsDue`) |

### `LevelMenu` (`$A519`)

**SELECT DIFFICULTY LEVEL**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/menus` 3, `stage1/rec/levels` 1) |
| Called from | `ExitSimCity` |
| Calls | `ShowInlineWindow` |

### `SetLevel` (`$A5A9`)

**Level = the item**

L1 12.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 36 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/levels`, `stage1/rec/menus`, `stage1/rec/bankrupt` and 4 more) |
| Called from | `NumberRepeat` |
| Calls | `DrawNameFunds`, `ShowInlineWindow`, `RunMenu` (tail), `ToggleMenuLine`, `InputName` |
| Reads | `$6A7D`-`$6A8D` (`MenuSelected`, `SelectedItem`, `Gene`) |
| Writes | `$A518` (`Level`); `$A61B`-`$A61C` (`GeneShown`); `$A6D8`-`$A6DB` (`InputAt`, `InputBuffer`); `$A7B9`-`$A7C1` (`ShowInputLoop+3`) |

### `InputGene` (`$A672`)

**INPUT NEW GENE: 5 digits at row 11, column 25**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |
| Called from | `NumberRepeat` |
| Calls | `PrintNumberAt`, `RunMenu` (tail), `ToggleMenuLine`, `InputLine` |
| Reads | `$6A8C`-`$6A8D` (`Gene`) |
| Writes | `$6A7D` (`MenuSelected`); `$A6D8`-`$A6DE` (`InputAt`, `InputBuffer`, `InputCursor`, `InputDigits` and 1 more); `$F751`-`$F752` (`PrintCol`, `PrintRow`) |

### `InputName` (`$A6F9`)

**Edit an 11-letter text at InputAt (InputLength = 11: CityName's twelfth letter cannot be typed) (letters, digits, space; CAPS SHIFT 5 / 8 cursor, 0 blanks the cursor cell and the one before it)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/menus` 2, `stage1/rec/levels` 1) |
| Called from | `SaveCity`, `LoadCity`, `SetLevel` |
| Calls | `InputLine` (falls into) |
| Reads | `$A6DD` (`InputDigits`) |
| Writes | `$A6DC`-`$A6DE` (`InputCursor`, `InputDigits`, `InputLength`) |

### `InputLine` (`$A6FF`)

**The line editor; with InputDigits a number (5 digits, carry when too large)**

L1 5.

[Animation: `InputLine` at work](img/routines/InputLine.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/menus` 4) |
| Called from | `InputGene`, `InputName` (falls into), `CursorLeft` |
| Calls | `KeyToChar`, `ShowInput`, `NumberToInput`, `PutDigit` (tail), `ReadInput` |
| Reads | `$5B00` (`KeyRows`); `$A6DA`-`$A6DE` (`InputBuffer`, `InputCursor`, `InputDigits`, `InputLength`); `$A6EF`-`$A6F0` (`InputDelay`) |
| Writes | `$5F68`-`$5F6C` (`CityName`); `$A6DC`-`$A6F0` (`InputCursor`, `InputDigits`, `InputLength`, `InputText` and 1 more); `$A924`-`$A933` (`SaveName`, `SaveHeader`) |

### `InputBlank` (`$A786`)

**A space at the cursor**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CursorLeft` (`$A793`)

**CursorLeft**

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `InputLine` |

### `ShowInput` (`$A7A3`)

**The text at InputAt, the cursor's letter inverse (`$C7`)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,416 calls (`stage1/rec/menus` 4,570, `stage1/rec/levels` 846) |
| Called from | `InputLine` |
| Calls | `ScreenAddr`, `NextColumn`, `PrintGlyph` |
| Reads | `$5F68`-`$5F72` (`CityName`); `$A6D8`-`$A6E3` (`InputAt`, `InputBuffer`, `InputCursor`, `InputDigits` and 2 more); `$A924`-`$A93A` (`SaveName`, `SaveHeader`) |
| Writes | `$F74F`-`$F753` (`PrintAddr`, `PrintCol`, `PrintRow`, `PrintAttr`) |

### `NumberToInput` (`$A7D4`)

**The 16-bit number at (InputBuffer) as digits into InputText**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |
| Called from | `InputLine` |
| Calls | `NumberDigits` |
| Reads | `$A6DF`-`$A6E9` (`InputText`) |
| Writes | `$A6DA`-`$A6EA` (`InputBuffer`, `InputCursor`, `InputDigits`, `InputLength` and 1 more) |

### `NumberDigits` (`$A7ED`)

**NumberDigits**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |
| Called from | `NumberToInput` |
| Calls | `NumberDigit`, `PutDigit` |
| Reads | `$6A8C`-`$6A8D` (`Gene`); `$A6DA`-`$A6DE` (`InputBuffer`, `InputCursor`, `InputDigits`, `InputLength`) |
| Writes | `$A7EB`-`$A7EC` (`NumberAt`) |

### `NumberDigit` (`$A81E`)

**NumberDigit**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/menus` 8) |
| Called from | `NumberDigits` |
| Calls | `PutDigit` (falls into) |

### `PutDigit` (`$A82A`)

**PutDigit**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`stage1/rec/menus` 10) |
| Called from | `InputLine` (tail), `NumberDigits`, `NumberDigit` (falls into) |
| Calls | `InputToNumber` |
| Reads | `$A6DD` (`InputDigits`); `$A7EB`-`$A7EC` (`NumberAt`) |
| Writes | `$6A8C`-`$6A8D` (`Gene`); `$A6DF`-`$A6E3` (`InputText`); `$F74E` (`PrintCharCode`) |

### `DigitValue` (`$A849`)

**A = E - '0', carry when E is not a digit**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20 calls (`stage1/rec/menus` 20) |
| Called from | `InputToNumber` |

### `InputToNumber` (`$A854`)

**HL = the decimal digits of InputText, carry on overflow**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |
| Called from | `PutDigit` |
| Calls | `DigitValue` |
| Reads | `$A6DF`-`$A6E4` (`InputText`) |

## tasks

`src/game/tasks.asm`

### `Interrupt` (`$F70B`)

**IM 2: save all registers, ReadInput, then (unless SwitchOff) swap the stack with the other task's**

Each interrupt, 50 a second, gives the other task the CPU: the UI and the simulation run turn by turn, one frame each. c1: L1 407 762, 128 197 / 256 388 switches.

[Animation: `Interrupt` at work](img/routines/Interrupt.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 1,822,178 t-states own (0.12 %) |
| Runs (the other recordings) | 402,538 calls (`stage1/rec/metro` 96,503, `stage1/rec/city2` 82,011, `stage1/rec/city` 77,592 and 7 more) |
| Called from | `InterruptJump` (tail) |
| Calls | `AnyKey`, `ScreenAddr`, `NextPixelLine`, `DrawIcon`, `DrawIconHere`, `ClearTopWhite`, `ClearViewArea`, `Random`, `DrawPointer`, `ErasePointer`, `TrackBox`, `InvertBox`, `DrawIcon2x2`, `DrawToolIcons`, `PrintChar`, `NextColumn`, `Print4Digits`, `Print3Digits`, `PrintDigitOf`, `PrintDigit`, `DrawBoxRow`, `PrintFunds`, `PrintDate`, `FindText`, `PrintPadded`, `MovePointer`, `PointerLeft`, `PointerUp`, `PointerDown`, `Click`, `WaitSpaceUp`, `DrawCell`, `BlinkCell`, `RoadTraffic`, `DrawBuildingTile`, `DrawView`, `StartBuilding`, `PrintNumberVar`, `PrintNumber24`, `PrintSign`, `Digit24`, `PrintDigitB`, `Sub24`, `MapAddrChecked`, `MapAddr`, `ToolKeys`, `ShowTool`, `GreyUnaffordable`, `GreyIcon`, `ToolPrice`, `Grid48`, `CellFlagsOf`, `MapToRowCol`, `DrawMover`, `DrawMovers`, `MoveTrain`, `MovePlane`, `MoveTornado`, `SimTask`, `UiTask`, `Periodic`, `MoveDisasters`, `FundsChanged`, `AnimateFire`, `AnimateFlood`, `StartFires`, `Ignite`, `StartFlood`, `FloodNoise`, `Earthquake`, `RandomDisaster`, `ShowAdvice`, `MapsKeys`, `OverviewCell`, `ShrinkLine`, `DrawOverview`, `PutLayerAttr`, `LayerOf`, `PrintGlyph`, `ReadInput` |
| Reads | `$F704`-`$F70A` (`TaskNow`, `SwitchOff`, `UiSP`) |
| Writes | `$F704`-`$F70A` (`TaskNow`, `SwitchOff`, `UiSP`) |

## system

`src/game/system.asm`

### `PrintGlyph` (`$F754`)

**Character A from the ROM font, made bold (byte OR byte >> 1), at PrintAddr, with PrintAttr unless `$FF`**

L1 496 214.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3,874 calls, 5,956,817 t-states own (0.40 %) |
| Runs (the other recordings) | 492,409 calls (`stage1/rec/menus` 169,406, `stage1/rec/metro` 76,064, `stage1/rec/city` 69,141 and 7 more) |
| Called from | `DrawIcon` (tail), `DrawIconHere` (tail), `PrintChar`, `PrintPadded`, `DrawCell` (tail), `PrintNumber24`, `PrintFileName`, `ShowInput`, `Interrupt` |
| Calls | `DrawIcon2x2`, `DrawToolIcons`, `PrintChar`, `DrawBoxRow`, `PrintPadded`, `DrawView`, `PrintNumber24` |
| Reads | `$F74F`-`$F753` (`PrintAddr`, `PrintCol`, `PrintRow`, `PrintAttr`) |
| Writes | `$4000`-`$57DE` (screen); `$5800`-`$5AFF` (screen) |

### `ReadInput` (`$F781`)

**Read the eight half rows into KeyRows, then the Kempston and Sinclair joysticks into them**

L1 413 183.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 2,220,200 t-states own (0.15 %) |
| Runs (the other recordings) | 407,959 calls (`stage1/rec/metro` 96,503, `stage1/rec/city2` 82,011, `stage1/rec/city` 77,592 and 7 more) |
| Called from | `InputLine`, `Interrupt` |
| Calls | `ReadKempston`, `ReadSinclair` (tail) |
| Writes | `$5B00`-`$5B07` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 4 more) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `TapeLoad` (`$F79F`)

**LD-BYTES through the ROM (border `$0F`): IX, DE, A flag, carry set**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |
| Called from | `LoadHeader`, `LoadMap` |
| Ports out | `$0FFE` |

### `TapeSave` (`$F7AA`)

**SA-BYTES through the ROM**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |
| Called from | `SaveCity` |

### `TapePause` (`$F7AD`)

**B x 5000 loops**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/menus` 1) |
| Called from | `SaveCity` |

### `InterruptJump` (`$FCFC`)

**JP Interrupt: the IM 2 vector `$FCFC`**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 52,240 t-states own (0.00 %) |
| Runs (the other recordings) | 402,538 calls (`stage1/rec/metro` 96,503, `stage1/rec/city2` 82,011, `stage1/rec/city` 77,592 and 7 more) |
| Entered by | the interrupt, 407,762 times in 221 routines |
| Calls | `Interrupt` (tail) |
| Reads | `$FDFF`-`$FE00` (`VectorTable+255`) |
| Writes | `$F6A4`-`$F6C1` (`UiStack+34`); `$F6E8`-`$F701` (`SimStack+38`, `SimFrame`) |
