# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, the original tape at signal speed, the first play). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
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

### `ToneBeep` (`$5B66`)

**The refusal tone: 500 cycles of the speaker, 48 + 16 DJNZ loops a cycle (the beep of a refused tool)**

No inputs. The speaker on with L = `$30` DJNZ loops, off with H = `$10`, 500 times (DE = `$01F4`): 500 cycles of 889 T, 444 500 T uncontended, 127 ms; measured 164 ms (8.2 frames, tools frame 13 434), with contention and the interrupts. It is not gated by SoundOn. Reached by JP ToneBeep from Refuse `$71E4` when a placement is refused (a tool too dear is refused silently by SelectTool's RET M). L1 3: 2 in tools (the occupied cell at frame 13 434 traced, the other not located), 1 in bankrupt.

[Animation: `ToneBeep` at work](img/routines/ToneBeep.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/tools` 2, `stage1/rec/bankrupt` 1) |

## input

`src/game/input.asm`

### `ReadPort1F` (`$5B80`)

**A = the Kempston port's bits inverted, or `$FF` when no interface**

Output: A = NOT IN (`$1F`) when KempstonFound, else `$FF` (CPL of 0). Called by ReadKempston `$7A01` from the interrupt (L1 413 183, one a frame).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 255,976 t-states own (0.02 %) |
| Called from | `ReadKempston` |
| Reads | `$5B7F` (`KempstonFound`) |
| Ports in | `$011F` |

### `ScanKey` (`$5BB3`)

**Find the first key down in the nine rows: KeyFound = its index (carry clear), or `$FF` (carry set)**

Reads KeyRows `$5B00-$5B08`; CAPS SHIFT is ignored in the first row (D = `$FE` masks it). Output: carry set and KeyFound = `$FF` when no key is down, else carry clear and KeyFound = 5 row + column. L1 5451.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5 calls, 3,031 t-states own (0.00 %) |
| Called from | `KeyToChar` |
| Reads | `$5B00`-`$5B04` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 1 more) |
| Writes | `$5BB2` (`KeyFound`) |

### `KeyToChar` (`$5BDF`)

**A = the character of the key down (KeyChars), carry set when none**

Used by the typed input: the city name (InputName `$A6F9`), the gene digits and the tool shortcut keys (ToolKeys `$6D2D`). L1 5451, 1193 with a key.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5 calls, 721 t-states own (0.00 %) |
| Called from | `ToolKeys` |
| Calls | `ScanKey` |
| Reads | `$5B9A`-`$5BB2` (`KeyChars+16`, `KeyFound`) |

### `AnyKey` (`$5BEF`)

**Z clear when any key of the nine rows is down**

Output: A = the first row's bits inverted (NZ) or 0 with Z. L1 2523 (the menus' key repeat, NumberRepeat `$6A31`).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 18 calls, 8,299 t-states own (0.00 %) |
| Called from | `DrawOverview` |
| Reads | `$5B00`-`$5B08` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 5 more) |

## screen

`src/game/screen.asm`

### `ScreenAddr` (`$5BFE`)

**HL = the display file address of character row B (0-23), column C (0-31)**

No other register changes but A. L1 451 620: every print and drawing routine calls it.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 4,472 calls, 336,501 t-states own (0.02 %) |
| Called from | `DrawIcon`, `DrawPointer`, `InvertBox`, `PrintInline`, `DrawBoxRow`, `PrintPadded`, `DrawViewRowPass`, `PrintNumberVar`, `PrintMenuText`, `Interrupt` |
| Calls | `DrawPointer` |

### `AttrAddr` (`$5C0D`)

**HL = the attribute address of row B, column C (C kept, B = `$58`)**

L1 1024 (the menu highlight HighlightLine `$6933` and the maps window's HighlightMapKey / HighlightLayer).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 10 calls, 1,077 t-states own (0.00 %) |
| Called from | `HighlightLine`, `HighlightMapKey`, `HighlightLayer` |

### `NextPixelLine` (`$5C19`)

**HL = the display file address one pixel line down**

The usual three cases: inside the character (INC H), into the next character row (L + 32, H - 8), into the next third (L + 32 with carry). L1 3 121 944.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 30,886 calls, 1,156,811 t-states own (0.08 %) |
| Called from | `DrawPointer`, `ErasePointer`, `InvertBox`, `DrawOverview`, `Interrupt` |
| Calls | `DrawPointer`, `ErasePointer`, `InvertBox` |

### `DrawIcon` (`$5C28`)

**Draw icon tile A (8 bytes at IconTiles + 8 A) at row B, column C, with its attribute from IconAttrs**

Sets PrintAddr to the cell, copies the eight bytes down the cell and the attribute IconAttrs + A (`$F4F8` + A) through PutAttr `$F774`. Used for the tool palette, the box frames and the window graphics. L1 36 344.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 392 calls, 242,529 t-states own (0.02 %) |
| Called from | `DrawIcon2x2` (tail), `Interrupt` |
| Calls | `ScreenAddr`, `PrintGlyph` (tail) |
| Reads | `$6462`-`$6463` (`TileIndex`); `$E850`-`$EA0F` (`IconTiles`); `$F4F8`-`$F52F` (`IconAttrs`); `$F74F`-`$F750` (`PrintAddr`) |
| Writes | `$4022`-`$405D` (screen); `$4122`-`$415D` (screen); `$4222`-`$425D` (screen); `$4322`-`$435D` (screen); `$4422`-`$445D` (screen); `$4522`-`$455D` (screen); 4 more ranges |

### `DrawIconHere` (`$5C57`)

**Draw icon tile A at PrintAddr with the current PrintAttr (no position, no own attribute)**

Then JP PrintGlyphAttr `$F76E` (PrintAttr `$FF` leaves the attribute). L1 27 668 (the box frames of DrawBoxRow).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 616 calls, 281,173 t-states own (0.02 %) |
| Called from | `DrawBoxRow`, `Interrupt` |
| Calls | `PrintGlyph` (tail) |
| Reads | `$EA10`-`$EA67` (`IconTiles+448`); `$F74F`-`$F750` (`PrintAddr`) |
| Writes | `$4000`-`$4007` (screen); `$4020`-`$4027` (screen); `$4040`-`$4047` (screen); `$4060`-`$57FF` (screen) |

### `ClearTopBlack` (`$5C70`)

**Clear the top third (`$4000-$47FF`) and give it attribute `$38`**

A = `$38` (white paper, black ink) into `$5800-$58FF`. L1 40.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 330 t-states own (0.00 %) |
| Called from | `ClearForMaps`, `MapsWindow`, `UiTask` |
| Calls | `ClearTopWhite` |
| Writes | `$4000` (screen) |

### `ClearTopWhite` (`$5C74`)

**Clear the top third with attribute `$07` (black paper, white ink)**

L1 28.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 180,822 t-states own (0.01 %) |
| Called from | `ClearTopBlack`, `Interrupt` |
| Calls | `ClearViewArea` |
| Reads | `$4000`-`$47FE` (screen); `$5800`-`$58FE` (screen) |
| Writes | `$4001`-`$47FF` (screen); `$5800`-`$58FF` (screen) |

### `ClearViewArea` (`$5C8F`)

**Clear the screen's rows 8-23 (`$4800-$57FF`), attribute `$47` (bright white on black)**

The map view's area, cleared before a window or a dialog is drawn over it. L1 223.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 7 calls, 874,306 t-states own (0.06 %) |
| Called from | `ClearTopWhite`, `ClearWindowArea`, `NewLandscape`, `Interrupt` |
| Calls | `ClearForMaps`, `MapsWindow` |
| Reads | `$4800`-`$57FE` (screen); `$5900`-`$5AFE` (screen) |
| Writes | `$4800`-`$57FF` (screen); `$5900`-`$5AFF` (screen) |

### `ClearForMaps` (`$5CAA`)

**Clear the top third black on white, then every attribute row: 8 columns `$07`, 24 columns `$21`**

Called by the maps window (`$7A9E`) before it draws a map: the left 8 columns keep a black key, the 24 on the right are blue on red (`$21`). L1 5.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 29,348 t-states own (0.00 %) |
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
| Called from | `Discs`, `AnimateFire`, `AnimateFlood`, `RandomDisaster` |
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
| Called from | `ScreenAddr`, `NextPixelLine`, `UiTask`, `Interrupt` |
| Calls | `ScreenAddr`, `NextPixelLine`, `UiTask` |
| Reads | `$401A`-`$483D` (screen); `$4915`-`$493D` (screen); `$4A15`-`$4A3D` (screen); `$4B15`-`$4B3D` (screen); `$4C15`-`$4C3D` (screen); `$4D15`-`$4D3D` (screen); 3 more ranges |
| Writes | `$401A`-`$483D` (screen); `$4915`-`$493D` (screen); `$4A15`-`$4A3D` (screen); `$4B15`-`$4B3D` (screen); `$4C15`-`$4C3D` (screen); `$4D15`-`$4D3D` (screen); 3 more ranges |

### `ErasePointer` (`$5D3E`)

**Put the 8 saved bytes back at PointerAt**

L1 158 076.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 1,001,470 t-states own (0.07 %) |
| Called from | `NextPixelLine`, `UiTask`, `Interrupt` |
| Calls | `NextPixelLine`, `UiTask` |
| Reads | `$5D34`-`$5D3D` (`PointerSave`, `PointerAt`) |
| Writes | `$401A`-`$483D` (screen); `$4915`-`$493D` (screen); `$4A15`-`$4A3D` (screen); `$4B15`-`$4B3D` (screen); `$4C15`-`$4C3D` (screen); `$4D15`-`$4D3D` (screen); 2 more ranges |

### `TrackBox` (`$5D55`)

**Work out the pointer's view cell; when the tool's box fits on the view, invert it there**

Output: PointerInView, BoxCell, BoxShown; the box is the BoxSize cells from the pointer's cell, inverted by InvertBox (twice a pass: on, then off once drawn). L1 316 156, 40 592 on the view.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3,554 calls, 307,604 t-states own (0.02 %) |
| Called from | `UiTask`, `Interrupt` |
| Calls | `InvertBox`, `UiTask` |
| Reads | `$5CFC`-`$5CFD` (`PointerX`, `PointerY`); `$5D4F`-`$5D50` (`BoxSize`) |
| Writes | `$5D51`-`$5D54` (`BoxCell`, `PointerInView`, `BoxShown`) |

### `InvertBox` (`$5D8F`)

**Invert (XOR `$FF`) the BoxSize box at row B, column C of the screen**

The tool palette's highlight (ShowTool) and the map cursor (TrackBox). L1 41 241.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 101 calls, 556,592 t-states own (0.04 %) |
| Called from | `NextPixelLine`, `TrackBox`, `ShowTool`, `Interrupt` |
| Calls | `ScreenAddr`, `NextPixelLine`, `UiTask` |
| Reads | `$4024`-`$487F` (screen); `$4915`-`$497F` (screen); `$4A15`-`$4A7F` (screen); `$4B15`-`$4B7F` (screen); `$4C15`-`$4C7F` (screen); `$4D15`-`$4D7F` (screen); 3 more ranges |
| Writes | `$4024`-`$497F` (screen); `$4A15`-`$4A7F` (screen); `$4B15`-`$4B7F` (screen); `$4C15`-`$4C7F` (screen); `$4D15`-`$4D7F` (screen); `$4E15`-`$4E7F` (screen); 2 more ranges |

### `DrawIcon2x2` (`$5DB3`)

**Draw icon tiles A, A+1 (row B) and A+2, A+3 (row B+1) at columns C, C+1**

L1 9086.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 98 calls, 25,493 t-states own (0.00 %) |
| Called from | `DrawToolIcons`, `Interrupt`, `PrintGlyph` |
| Calls | `DrawIcon` (tail) |

### `DrawToolIcons` (`$5DD2`)

**The tool palette: 14 icons of 2 x 2 tiles at row 1, columns 2-28, tiles 0, 4, 8 ...**

L1 649 (each tool change redraws it).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 7 calls, 11,207 t-states own (0.00 %) |
| Called from | `DrawStatusItems`, `ToolKeys`, `FundsChanged`, `PrintGlyph` |
| Calls | `DrawIcon2x2`, `DrawStatusItems`, `ToolClick`, `FundsChanged` |

## print

`src/game/print.asm`

### `PrintChar` (`$5DEB`)

**Print character A at PrintAddr (JP to PrintGlyph `$F754`)**

L1 163 852.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,416 calls, 45,290 t-states own (0.00 %) |
| Called from | `PrintInline`, `PrintDigit`, `PrintDigitB`, `PrintMenuText`, `PrintGlyph` |
| Calls | `PrintInline`, `PrintDigit`, `PrintDigitB`, `PrintGlyph` |

### `PrintInline` (`$5DEF`)

**Print the codes that follow the CALL, up to `$FE`, then return after them**

The codes: `$FF` row column (position), `$FB` attribute (PrintAttr), `$FD` row column width height (a box, DrawBox), `$FC` number (printed as up to 3 digits; not used in any recording), `$FE` the end (JP to the byte after it); any other byte a character. PrintCol counts up. Used for every fixed text and window frame (L1 371 calls).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 11 calls, 48,173 t-states own (0.00 %) |
| Called from | `PrintChar`, `PrintDigit` (tail), `DrawStatusPanel`, `DrawStatusBox`, `DrawNameFunds`, `ClearWindowArea`, `DrawMapsFrame`, `DrawMapsKeys` |
| Calls | `ScreenAddr`, `PrintChar`, `NextColumn`, `PrintDigit` (tail) |
| Reads | `$5F16`-`$5F4C` (`StatusBarText`, `DrawStatusBox`, `StatusBoxText`); `$5F63`-`$5F7E` (`CityNameAt`, `CityName`); `$673E`-`$6745` (`WindowAreaText`); `$7AA4`-`$7B4E` (`MapsFrameText`, `DrawMapsKeys`, `MapsKeysText`) |
| Writes | `$F74F`-`$F753` (`PrintAddr`, `PrintCol`, `PrintRow`, `PrintAttr`) |

### `NextColumn` (`$5E12`)

**PrintAddr and PrintCol one column on**

L1 450 406.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3,422 calls, 258,960 t-states own (0.02 %) |
| Called from | `PrintInline`, `PrintPadded`, `PrintNumber24`, `PrintDigitB` (tail), `PrintMenuText` (tail), `Interrupt` |
| Calls | `PrintNumber24` |
| Reads | `$F74F`-`$F751` (`PrintAddr`, `PrintCol`) |
| Writes | `$F74F`-`$F751` (`PrintAddr`, `PrintCol`) |

### `PrintNumberAt` (`$5E35`)

**HL in 5 digits at PrintCol, PrintRow**

L1 2 (the gene's 5 digits).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |

### `Print5Digits` (`$5E41`)

**HL in 5 digits, leading zeros printed**

L1 4.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/menus` 4) |

### `Print4Digits` (`$5E47`)

**HL in 4 digits (the year)**

L1 9921.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 113 calls, 4,415 t-states own (0.00 %) |
| Called from | `PrintDate` |
| Calls | `PrintDigitOf` |

### `Print3Digits` (`$5E4D`)

**HL in 3 digits (menus' numbers, the tax rate)**

L1 11 961.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 11,716 t-states own (0.00 %) |
| Called from | `PrintDigit` |
| Calls | `PrintDigitOf`, `PrintDigit`, `PrintDate` |

### `PrintDigitOf` (`$5E5E`)

**One digit: count how often DE (a negative power of ten) goes into HL, then print it**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 339 calls, 53,498 t-states own (0.00 %) |
| Called from | `Print4Digits`, `Print3Digits`, `Interrupt` |
| Calls | `PrintDigit` |

### `PrintDigit` (`$5E66`)

**Print the digit A (0-9) at PrintAddr and step on**

L1 45 808.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 452 calls, 57,838 t-states own (0.00 %) |
| Called from | `PrintChar`, `PrintInline` (tail), `Print3Digits`, `PrintDigitOf`, `DrawBox` |
| Calls | `PrintChar`, `PrintInline` (tail), `Print3Digits`, `DrawBox`, `DrawStatusBox`, `DrawStatusItems`, `DrawNameFundsEnd`, `ClearWindowAreaEnd`, `DrawMapsKeys`, `DrawMapsEnd` |
| Reads | `$F74F`-`$F750` (`PrintAddr`) |
| Writes | `$F74E`-`$F750` (`PrintCharCode`, `PrintAddr`) |

### `DrawBox` (`$5E97`)

**Draw a window frame from icon tiles `$38-$3F`: row, column, width, height at (HL)**

The corners and edges are icon tiles: top `$38` `$39` `$3A`, sides `$3F` `$3B`, bottom `$3E` `$3D` `$3C`; the inside is left alone. Sets PrintCol/PrintRow at the corner. It also patches `$5F0F` (BoxRowRight+9) with the box's column, a fourth self-modified operand. L1 193.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 7,041 t-states own (0.00 %) |
| Called from | `PrintDigit`, `DrawBoxRow` |
| Calls | `PrintDigit`, `DrawBoxRow` |
| Reads | `$5E96` (`BoxDims+1`); `$5F46`-`$5F49` (`StatusBoxText+3`); `$6741`-`$6744` (`WindowAreaText+3`); `$7AA7`-`$7AB4` (`MapsFrameText+3`); `$F751` (`PrintCol`) |
| Writes | `$5E95`-`$5E96` (`BoxDims`); `$5F0F` (`BoxRowRight+9`); `$F751`-`$F752` (`PrintCol`, `PrintRow`) |

### `DrawBoxRow` (`$5ED3`)

**One row of a frame: tile A, BoxDims-2 tiles B (a space: skipped), tile C, then PrintRow + 1**

The three tiles are written into the operands of the three LD A,n below (self-modified, `$5EE9`, `$5EF9`, `$5F07`). L1 3154.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 83 calls, 215,546 t-states own (0.01 %) |
| Called from | `DrawBox`, `DrawMenu`, `Interrupt`, `PrintGlyph` |
| Calls | `ScreenAddr`, `DrawIconHere`, `DrawBox` |
| Reads | `$5E95` (`BoxDims`); `$F74F`-`$F752` (`PrintAddr`, `PrintCol`, `PrintRow`) |
| Writes | `$5EE9`-`$5F07` (`BoxRowLeft+1`, `BoxRowMiddle`, `BoxRowFill`, `BoxRowRight`); `$F74F`-`$F752` (`PrintAddr`, `PrintCol`, `PrintRow`) |

### `DrawStatusPanel` (`$5F13`)

**Draw the menu bar, the status box, the city name, funds, tool palette, tool name and date**

The menu bar "SYSTEM OPTIONS DISASTERS WINDOWS" at row 0 (attribute 7), the box rows 3-7, then DrawNameFunds, DrawToolIcons, ShowTool, PrintToolName, PrintDate, PrintFunds. L1 34 (the first draw and after each window).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 34 t-states own (0.00 %) |
| Called from | `MapsWindow`, `UiTask` |
| Calls | `PrintInline` |

### `DrawStatusBox` (`$5F40`)

**The status box: rows 3-7 of the top third (attribute `$38`), then the name, the tools, the date, the funds**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 38 t-states own (0.00 %) |
| Called from | `PrintDigit` |
| Calls | `PrintInline` |

### `DrawStatusItems` (`$5F4D`)

**The name, the funds, the tool palette, the tool name and the date**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 342 t-states own (0.00 %) |
| Called from | `DrawToolIcons`, `PrintDigit`, `PrintFunds` |
| Calls | `DrawToolIcons`, `DrawNameFunds`, `PrintFunds`, `PrintDate`, `PrintToolName`, `ShowTool`, `MapsWindow` |

### `DrawNameFunds` (`$5F60`)

**Print the city name (12 letters, CityName `$5F68`) at row 5, column 1, and "FUNDS" with the dollar sign at row 5, column 17**

CityName lies inside the inline text: typing a name writes these bytes (InputName `$A6F9`), so the text prints the current name. L1 35.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 54 t-states own (0.00 %) |
| Called from | `DrawStatusItems` |
| Calls | `PrintInline` |

### `DrawNameFundsEnd` (`$5F7F`)

**RET**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 24 t-states own (0.00 %) |
| Called from | `PrintDigit` |

### `PrintFunds` (`$5F80`)

**Print Funds (`$8F97`, 24 bits) at row 5, column 24**

L1 9918: every month and every purchase.

[Animation: `PrintFunds` at work](img/routines/PrintFunds.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 114 calls, 7,649 t-states own (0.00 %) |
| Called from | `DrawStatusItems`, `PrintNumber24`, `Periodic` (tail) |
| Calls | `DrawStatusItems`, `PrintNumberVar`, `UiTask` |

### `PrintDate` (`$5FAE`)

**Print the month (MonthNames by Month `$8F9B`) at row 4, column 23 and the year (`$8F9C`) after it**

L1 9917.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 113 calls, 16,419 t-states own (0.00 %) |
| Called from | `Print3Digits`, `DrawStatusItems`, `PrintPadded`, `Periodic` (tail) |
| Calls | `Print4Digits`, `FindText`, `PrintPadded`, `UiTask` |
| Reads | `$8F9B`-`$8F9D` (`Month`, `Year`) |

### `PrintToolName` (`$6305`)

**Print the current tool's name and price (GameTexts by CurrentTool) at row 4, column 1, padded to 20 columns**

L1 99.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5 calls, 615 t-states own (0.00 %) |
| Called from | `DrawStatusItems`, `FindText`, `ToolClick` |
| Calls | `FindText`, `PrintPadded`, `ShowTool` |
| Reads | `$6D50` (`CurrentTool`) |

### `FindText` (`$6317`)

**HL = the A-th (from 0) bit-7-ended string of the table at HL**

L1 14 996.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 174 calls, 783,759 t-states own (0.05 %) |
| Called from | `PrintDate`, `PrintToolName`, `ShowAdvice`, `Interrupt` |
| Calls | `PrintToolName`, `ShowAdvice` |
| Reads | `$5F8A`-`$5FA1` (`MonthNames`); `$5FC6`-`$60C1` (`GameTexts`) |

### `PrintPadded` (`$632A`)

**Print the string at HL at row B, column C, then spaces to A + 1 columns (C counts down from A for each letter but the last)**

L1 14 996.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 174 calls, 420,546 t-states own (0.03 %) |
| Called from | `PrintDate`, `PrintToolName`, `ShowAdvice` (tail), `PrintGlyph` |
| Calls | `ScreenAddr`, `NextColumn`, `PrintDate`, `Periodic`, `PrintGlyph` |
| Reads | `$5F8A`-`$5FA4` (`MonthNames`); `$5FD1`-`$5FD8` (`GameTexts+11`); `$5FFB`-`$6028` (`GameTexts+53`); `$60C1`-`$60DE` (`GameTexts+251`) |
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
| Called from | `UiTask`, `Interrupt` |
| Calls | `PointerRight`, `PointerLeft`, `PointerUp`, `PointerDown`, `UiTask` |
| Reads | `$5B01`-`$5B05` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 1 more) |

### `PointerRight` (`$637D`)

**PointerX + 1 up to 62**

L1 1895.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 22 calls, 1,700 t-states own (0.00 %) |
| Called from | `MovePointer` |
| Reads | `$5CFC` (`PointerX`) |
| Writes | `$5CFC` (`PointerX`) |

### `PointerLeft` (`$638A`)

**PointerX - 1 down to 0**

L1 2044.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 1,081 t-states own (0.00 %) |
| Called from | `MovePointer` |
| Reads | `$5CFC` (`PointerX`) |
| Writes | `$5CFC` (`PointerX`) |

### `PointerUp` (`$6397`)

**PointerY - 2 down to 0**

The test of key 6 on the view (KeyRow0 bit 4) leads to a branch no recording ran (PointerUpStop, L1 -), which stops at row `$40`.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 54 calls, 5,779 t-states own (0.00 %) |
| Called from | `MovePointer` |
| Reads | `$5B04` (`KeyRow0`); `$5CFD` (`PointerY`) |
| Writes | `$5CFD` (`PointerY`) |

### `PointerDown` (`$63B8`)

**PointerY + 2 up to 184**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 38 calls, 2,782 t-states own (0.00 %) |
| Called from | `MovePointer` |
| Reads | `$5CFD` (`PointerY`) |
| Writes | `$5CFD` (`PointerY`) |

### `Click` (`$63CD`)

**SPACE pressed: take the pointer's cell, then the tool palette, the scroll arrows, the menu bar, the map**

With SwitchOff set (no task switch while the UI changes the screen and the map): ToolClick `$6D51`, ScrollClick `$6CBF`, MenuClick `$6401`, MapClick `$7012`. L1 609 (the presses of the recordings).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 72,263 t-states own (0.00 %) |
| Called from | `UiTask` |
| Calls | `MenuClick`, `ScrollClick`, `ToolClick`, `MapClick` |
| Reads | `$5B07` (`KeyRowSpace`); `$5CFC`-`$5CFD` (`PointerX`, `PointerY`) |
| Writes | `$63C9`-`$63CA` (`ClickCell`); `$F705` (`SwitchOff`) |

### `WaitSpaceUp` (`$63F9`)

**Wait until SPACE is released**

L1 709 255 loop runs, 196 calls.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 335,193 t-states own (0.02 %) |
| Called from | `MenuClick` (tail) |
| Reads | `$5B07` (`KeyRowSpace`) |

### `MenuClick` (`$6401`)

**On row 0, open the menu under the pointer and wait for SPACE up**

L1 609, 69 on row 0.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 12 calls, 415 t-states own (0.00 %) |
| Called from | `Click` |
| Calls | `WaitSpaceUp` (tail), `OpenMenuAt` |
| Reads | `$63CA` (`ClickCell+1`) |

### `OpenMenuAt` (`$640E`)

**The menu by the pointer's column: SYSTEM (below 14), OPTIONS (below 30), DISASTERS (below 48), WINDOWS**

IX = SystemMenu `$A02B`, OptionsMenu `$A32F`, DisastersMenu `$A43E` or WindowsMenu `$A4C2`, then ShowMenu `$66F2`. L1 69.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 130 t-states own (0.00 %) |
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
| Called from | `UiTask` |
| Calls | `ScreenAddr`, `DrawView` (tail), `MapAddr` |
| Reads | `$6507`-`$6508` (`ViewCol`, `ViewRow`); `$8F9F` (`PassCount`) |
| Writes | `$6433` (`Blink`); `$6482`-`$6483` (`DrawTileAt+1`) |

### `DrawBlankCell` (`$6464`)

**Draw cell tile `$3B` (the "no power" lightning) instead: the on phase of the blink of an unpowered zone or building**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,038 calls (`stage1/rec/tools` 417, `stage1/rec/disasters` 207, `stage1/rec/ports` 178 and 4 more) |

### `DrawCell` (`$6468`)

**Draw one view cell: map byte in A (or the building row in progress), tile and attribute**

A map byte below `$80` is a cell tile at CellTiles `$EA68` + 8 n with its attribute at CellAttrs `$F530` + n; inside a building row (BuildingLeft not 0) the next building tile is drawn instead (DrawBuildingTile). Cells `$54-$56` blink (BlinkCell); roads 7 and 8 show their traffic (RoadTraffic). The tile goes to ViewAt (`$6482`), the attribute through PutAttr. L1 5 379 061.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 58,912 calls, 36,494,172 t-states own (2.42 %) |
| Called from | `DrawView`, `Interrupt` |
| Calls | `BlinkCell`, `RoadTraffic`, `PrintGlyph` (tail) |
| Reads | `$6462`-`$6463` (`TileIndex`); `$6505`-`$6506` (`CellAttrPtr`); `$6558` (`BuildingLeft`); `$EA68`-`$EA9F` (`CellTiles`); `$EC40`-`$EC47` (`CellTiles+472`); `$ECB0`-`$ECEF` (`CellTiles+584`); 3 more ranges |
| Writes | `$4800`-`$57FF` (screen); `$6462`-`$6463` (`TileIndex`) |

### `BlinkCell` (`$6499`)

**Cells `$54-$56` (the unpowered zone centres) blink: with PassCount bit 5 set they show tile `$3B` (the lightning)**

L1 4 249 059, 11 661 blanked.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 58,912 calls, 1,472,731 t-states own (0.10 %) |
| Called from | `DrawCell` |
| Reads | `$8F9F` (`PassCount`) |

### `RoadTraffic` (`$64A9`)

**Road cells 7 and 8: heavy traffic shows tile `$34` / `$36`, medium blinks to `$35` / `$37`**

Reads the traffic map at the cell (MapToRowCol `$7635`, TrafficAt `$7581`): `$DC` or more heavy, `$96-$DB` medium (the second tile when Blink is set). L1 668 762.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 59,776 calls, 3,780,176 t-states own (0.25 %) |
| Called from | `DrawCell`, `OverviewCell`, `Interrupt` |
| Calls | `OverviewCell` |

### `DrawBuildingTile` (`$64D6`)

**The next tile of the building row in progress: BuildingTiles `$ED58` + 8 n, attribute `$F58E` + n**

With PassCount bit 5, the first drawn cell of a building row whose start byte AND `$F0` is `$A0` (a top row, power bit 4 clear) shows tile `$3B`, the lightning. IX then points at BuildingDummy, so the row's other cells and the lower rows never blink: only the top-left cell of an unpowered building does. L1 1 130 002.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawView` (`$650B`)

**Draw the whole view: 16 rows of 32 cells from the map at ViewCol, ViewRow**

L1 627 (after every scroll, window and dialog).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 4 calls, 16,510,296 t-states own (1.10 %) |
| Called from | `DrawViewRowPass` (tail), `ShowMenu`, `IndustrialTool` (tail), `MapsWindow` (tail), `UiTask`, `PrintGlyph` |
| Calls | `DrawCell`, `MapAddr`, `UiTask` |
| Reads | `$6482`-`$6483` (`DrawTileAt+1`); `$6507`-`$6508` (`ViewCol`, `ViewRow`); `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`); `$D24E`-`$D56D` (`CityMap+3582`); `$D5AE`-`$D5CD` (`CityMap+4446`); `$D60E`-`$D62D` (`CityMap+4542`); 5 more ranges |
| Writes | `$6482`-`$6483` (`DrawTileAt+1`); `$6505`-`$650A` (`CellAttrPtr`, `ViewCol`, `ViewRow`, `ViewCellPtr`); `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`) |

### `StartBuilding` (`$655B`)

**A map byte `$80` or more: work out the building's tile number and the cells left**

From a `$C0-$FF` byte it steps back to the row's first byte (FindBuildingStart). Width = first AND 7, n = (second AND `$3F`) x 8 + (third AND 7) + the cells stepped back. L1 356 616.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 356,616 calls (`stage1/rec/city2` 114,966, `stage1/rec/metro` 101,052, `stage1/rec/city` 87,826 and 5 more) |

### `FindBuildingStart` (`$6593`)

**Step IX back over the `$C0-$FF` bytes to the row's `$80-$BF` byte, counting them**

L1 34 254 (the buildings cut by the view's left edge).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 34,254 calls (`stage1/rec/metro` 17,141, `stage1/rec/city2` 8,907, `stage1/rec/city` 5,677 and 3 more) |

## arith

`src/game/arith.asm`

### `PrintNumberHL` (`$65A5`)

**HL (C = 0) in up to 7 digits at row B, column C**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11,064 calls (`stage1/rec/menus` 10,015, `stage1/rec/city` 621, `stage1/rec/bankrupt` 414 and 3 more) |

### `PrintNumberVar` (`$65B3`)

**The 24-bit number at (HL) (low, middle, high) at row B, column C**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 114 calls, 48,556 t-states own (0.00 %) |
| Called from | `PrintFunds` |
| Calls | `ScreenAddr`, `PrintSign`, `Digit24` |
| Reads | `$8F97`-`$8F99` (`Funds`) |
| Writes | `$664D`-`$664E` (`NumberFlags`); `$F74F`-`$F750` (`PrintAddr`) |

### `PrintNumber24` (`$65C1`)

**CHL as a signed decimal, leading zeros left out and made up as trailing spaces**

Powers of ten from 1 000 000 down, each a 24-bit subtraction loop (Digit24). Used by every money and population figure. L1 28 400.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 45,965 t-states own (0.00 %) |
| Called from | `NextColumn`, `Interrupt`, `PrintGlyph` |
| Calls | `NextColumn`, `PrintFunds`, `Digit24`, `PrintDigitB`, `PrintGlyph` |
| Reads | `$664E` (`NumberFlags+1`); `$F74F`-`$F750` (`PrintAddr`) |
| Writes | `$65A3`-`$65A4` (`NumberEnd`) |

### `PrintSign` (`$662C`)

**A negative CHL (bit 7 of C): print "-" and negate it**

L1 7 (the budget's negative balances).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 114 calls, 2,233 t-states own (0.00 %) |
| Called from | `PrintNumberVar` |

### `Digit24` (`$664F`)

**B = how often B'DE' (a negative power of ten) goes into C'HL'; print it unless a leading zero**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 680 calls, 214,011 t-states own (0.01 %) |
| Called from | `PrintNumberVar`, `PrintNumber24`, `Interrupt` |
| Calls | `PrintDigitB` |
| Reads | `$664D`-`$664E` (`NumberFlags`) |
| Writes | `$664D`-`$664E` (`NumberFlags`) |

### `PrintDigitB` (`$666F`)

**Print the digit B**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 565 calls, 38,301 t-states own (0.00 %) |
| Called from | `PrintChar`, `PrintNumber24`, `Digit24` |
| Calls | `PrintChar`, `NextColumn` (tail) |
| Writes | `$F74E` (`PrintCharCode`) |

### `Sub24` (`$6680`)

**CHL = CHL - BDE (24 bits); carry and sign as the high byte left them**

The one 24-bit subtraction: prices against Funds and the city class's thresholds both use it (stage 1: the POKE file's NOP NOP at `$6681` breaks both). L1 25 262.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 104 calls, 5,107 t-states own (0.00 %) |
| Called from | `ToolKeys`, `GreyUnaffordable`, `Spend` |

### `Add24` (`$6687`)

**CHL = CHL + BDE (24 bits)**

L1 39 110.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 144 calls, 5,809 t-states own (0.00 %) |
| Called from | `AddValue` |

### `Mul16` (`$668C`)

**CHL = HL x DE (24-bit product), shift and add**

L1 16 721.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 160 calls, 243,386 t-states own (0.02 %) |
| Called from | `AssessCity`, `AddValue` |

### `Div24By8` (`$66B6`)

**CHL = CHL / A, remainder in A**

L1 5831.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,831 calls (`stage1/rec/menus` 5,015, `stage1/rec/city` 373, `stage1/rec/bankrupt` 231 and 6 more) |

### `Div16` (`$66D0`)

**HL = HL / DE; HL = 0 when DE is 0**

L1 5092.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 72 calls, 3,785 t-states own (0.00 %) |
| Called from | `Averages`, `DecayPollution`, `DecayTraffic`, `Averages2` |

## menus

`src/game/menus.asm`

### `ShowMenu` (`$66F2`)

**A pull-down menu at IX: the window area cleared, the items drawn, run, then the view redrawn**

L1 76.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 98 t-states own (0.00 %) |
| Called from | `OpenMenuAt` (tail) |
| Calls | `DrawView`, `ClearWindowArea`, `DrawMenu`, `RunMenu` |
| Writes | `$F753` (`PrintAttr`) |

### `ShowInlineWindow` (`$6704`)

**A window whose description follows the CALL (POP IX), then ShowWindow**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27 calls (`stage1/rec/menus` 20, `stage1/rec/levels` 2, `stage1/rec/bankrupt` 1 and 4 more) |

### `ShowWindow` (`$6706`)

**Draw the window at IX: a menu-sized one (first byte 8 or more) over the view, else full screen**

L1 54.

[Animation: `ShowWindow` at work](img/routines/ShowWindow.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 52 calls (`stage1/rec/menus` 23, `stage1/rec/bankrupt` 7, `stage1/rec/city2` 6 and 3 more) |

### `ShowFullWindowItems` (`$6727`)

**ShowFullWindowItems**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/bankrupt`, `stage1/rec/city2`, `stage1/rec/metro` and 3 more) |

### `ClearWindowArea` (`$6738`)

**Clear rows 8-23 and frame them (attribute `$44`, a 32 x 16 box at row 8)**

L1 116.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 102 t-states own (0.00 %) |
| Called from | `ShowMenu`, `NewLandscape`, `UiTask` |
| Calls | `ClearViewArea`, `PrintInline` |

### `ClearWindowAreaEnd` (`$6746`)

**RET**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 30 t-states own (0.00 %) |
| Called from | `PrintDigit` |

### `DrawMenu` (`$67C3`)

**Draw the items of the menu at IX, line by line, and collect the selectable ones**

Item kinds (first byte): 0 a text line, 1 a toggle (a flag address, then ON or OFF), 2 an action (an address to run), 3 a separator line (tiles `$40-$42`), 4 the end, 8 a number field (selectable). L1 143.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 8,343 t-states own (0.00 %) |
| Called from | `ShowMenu`, `NewLandscape`, `UiTask` |
| Calls | `DrawBoxRow`, `AddMenuItem`, `PrintMenuText` |
| Reads | `$6749` (`MenuLine`); `$A4C2`-`$A51D` (`WindowsMenu`, `MapsDue`, `MapsItem`, `Level` and 2 more); `$A539`-`$A56A` (`LevelMenuText+29`); `$A583`-`$A58C` (`LevelMenuText+103`); `$A5A8` (`LevelMenuText+140`); `$A6A4`-`$A6A5` (`CreatingText`); 2 more ranges |
| Writes | `$5E95` (`BoxDims`); `$6747`-`$6756` (`MenuState`, `MenuLine`, `MenuItems`); `$67C2` (`MenuCount`); `$F751`-`$F752` (`PrintCol`, `PrintRow`) |

### `AddMenuItem` (`$6806`)

**Put the line and IX into the next MenuItems slot**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 1,354 t-states own (0.00 %) |
| Called from | `DrawMenu` |
| Reads | `$6749` (`MenuLine`); `$67C2` (`MenuCount`) |
| Writes | `$674A`-`$6755` (`MenuItems`); `$67C2` (`MenuCount`) |

### `DrawMenuToggle` (`$684C`)

**A toggle item: its text, then ON or OFF by its flag**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawMenuToggleOn` (`$6871`)

**DrawMenuToggleOn**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/city`, `stage1/rec/growth` and 5 more) |

### `DrawMenuToggleNext` (`$687D`)

**DrawMenuToggleNext**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/disasters`, `stage1/rec/bankrupt` and 4 more) |

### `PrintMenuText` (`$6882`)

**The item's text at its line, column 1: bit 7 ends it; codes `$21` (to column 24), 5, 6, 7 (numbers)**

Codes: `$21` moves to column 24 (MenuTab), 6 a 16-bit number (5 digits) at an address, 7 an 8-bit one (3 digits), 5 a 24-bit one; a nonzero byte after the code registers the field for editing (MenuField). L1 1677.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 27 calls, 42,486 t-states own (0.00 %) |
| Called from | `DrawMenu` |
| Calls | `ScreenAddr`, `PrintChar`, `NextColumn` (tail) |
| Reads | `$6749` (`MenuLine`); `$A4C4`-`$A5A7` (`WindowsMenu+2`, `MapsDue`, `MapsItem`, `Level` and 2 more); `$A6A6`-`$A6D6` (`CreatingText+2`) |
| Writes | `$F74F`-`$F750` (`PrintAddr`) |

### `MenuValueSlot` (`$6905`)

**HL = MenuValues + 3 A**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 41 calls (`stage1/rec/bankrupt` 25, `stage1/rec/menus` 10, `stage1/rec/city` 6) |

### `MenuField` (`$6910`)

**Remember the column and the address of the number field on this line**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rec/bankrupt` 24, `stage1/rec/menus` 8, `stage1/rec/city` 4) |

### `MenuTab` (`$6922`)

**PrintCol 24 on this line**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 166 calls (`stage1/rec/menus` 79, `stage1/rec/bankrupt` 28, `stage1/rec/city` 15 and 6 more) |

### `HighlightLine` (`$6933`)

**XOR `$46` into the attributes of row B, columns 1-30: the menu bar's highlight**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 6 calls, 7,844 t-states own (0.00 %) |
| Called from | `ToggleMenuLine` |
| Calls | `AttrAddr` |
| Reads | `$5961`-`$599E` (screen); `$59C1`-`$59DE` (screen) |
| Writes | `$5961`-`$599E` (screen); `$59C1`-`$59DE` (screen) |

### `RunMenu` (`$6944`)

**Move the highlight with Q / A every 8 frames (HALT), SPACE selects: run, toggle or edit the item**

L1 132. The menus are opened from Click (or BudgetWindow, EvaluationWindow), which set SwitchOff `$F705` = 1: the simulation is frozen while a menu is open (MapsWindow has no menu and leaves SwitchOff to LayerOf, per cell: the simulation runs on there), and each HALT waits one frame.

[Animation: `RunMenu` at work](img/routines/RunMenu.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 46,767,785 t-states own (3.11 %) |
| Called from | `ShowMenu`, `UiTask` |
| Calls | `CallMenuHook`, `NumberRepeat` (tail), `MenuUp`, `ToggleMenuLine`, `MenuDown`, `SelectedItem` |
| Reads | `$5B01`-`$5B07` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 3 more); `$674B`-`$674C` (`MenuItems+1`); `$67C2` (`MenuCount`); `$6956` (`RunMenuHalt+1`); `$A4D8` (`WindowsMenu+22`); `$A53C` (`LevelMenuText+32`) |
| Writes | `$6A7D` (`MenuSelected`) |

### `EditNumber` (`$6996`)

**Q / A count the field up and down (to EditMax), with a key repeat; SPACE ends**

L1 5 (the tax rate and the budget windows).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditUp` (`$69EC`)

**EditUp**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,248 calls (`stage1/rec/menus` 1,241, `stage1/rec/city` 7) |

### `EditDown` (`$69FA`)

**EditDown**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 45 calls (`stage1/rec/city` 25, `stage1/rec/bankrupt` 20) |

### `PrintEditField` (`$6A16`)

**Print the field's value in 3 digits at its position**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,842 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 106, `stage1/rec/bankrupt` 65) |

### `CallMenuHook` (`$6A2A`)

**JP (MenuHook) unless 0**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 95 t-states own (0.00 %) |
| Called from | `RunMenu` |
| Reads | `$6942`-`$6943` (`MenuHook`) |

### `NumberRepeat` (`$6A31`)

**The key repeat: no key, delay 10; a key held, count it down**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 68 t-states own (0.00 %) |
| Called from | `RunMenu` (tail) |
| Calls | `MapsItem`, `SetLevel` |
| Reads | `$A4D9`-`$A4DA` (`WindowsMenu+23`); `$A53D`-`$A53E` (`LevelMenuText+33`) |

### `MenuUp` (`$6A54`)

**The highlight one item up**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 57 t-states own (0.00 %) |
| Called from | `RunMenu` |
| Calls | `ToggleMenuLine` |
| Reads | `$6A7D` (`MenuSelected`) |
| Writes | `$6A7D` (`MenuSelected`) |

### `ToggleMenuLine` (`$6A60`)

**XOR the highlight of the selected item's line**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 6 calls, 600 t-states own (0.00 %) |
| Called from | `RunMenu`, `MenuUp`, `MenuDown` (tail) |
| Calls | `HighlightLine`, `SelectedItem` |
| Reads | `$674A`-`$674D` (`MenuItems`) |

### `MenuDown` (`$6A6C`)

**The highlight one item down**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 83 t-states own (0.00 %) |
| Called from | `RunMenu` |
| Calls | `ToggleMenuLine` (tail) |
| Reads | `$67C2` (`MenuCount`); `$6A7D` (`MenuSelected`) |
| Writes | `$6A7D` (`MenuSelected`) |

### `SelectedItem` (`$6A7E`)

**HL = MenuItems + 3 MenuSelected**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 626 t-states own (0.00 %) |
| Called from | `RunMenu`, `ToggleMenuLine` |
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
| Called from | `UiTask` |
| Calls | `ClearViewArea`, `ClearWindowArea`, `DrawMenu`, `Discs`, `MakeCoast`, `StartSimulation` |
| Reads | `$6A8C`-`$6A8D` (`Gene`); `$C450`-`$E84E` (`CityMap`) |
| Writes | `$5CC4`-`$5CC5` (`RandomSeed`); `$6C05`-`$6C06` (`DiscCell`, `DiscOver`); `$C450`-`$E84F` (`CityMap`) |

### `Discs` (`$6ADB`)

**B discs of cell C, radius 2 to E (random), centre 16-79, each with a random shape from DiscShapes**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 58,836 t-states own (0.00 %) |
| Called from | `NewLandscape` |
| Calls | `Random`, `Disc` |
| Reads | `$6AD3`-`$6ADA` (`DiscShapes`) |
| Writes | `$6AE8` (`DiscsLoop+5`); `$6C02`-`$6C08` (`DiscVars`, `DiscY`, `DiscRadius`, `DiscCell` and 2 more) |

### `MakeCoast` (`$6BA5`)

**Every water cell next to land whose neighbour mask is in CoastPatterns becomes its coast cell**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 2,259,445 t-states own (0.15 %) |
| Called from | `NewLandscape` |
| Calls | `MapAddrChecked`, `LandNeighbours` |
| Reads | `$6B21`-`$6BA1` (`CoastPatterns`, `CoastCells`); `$C4B1`-`$E84F` (`CityMap+97`) |
| Writes | `$C882`-`$CC59` (`CityMap+1074`); `$CCE4`-`$D27A` (`CityMap+2196`); `$D39B`-`$D640` (`CityMap+3915`); `$D6C3`-`$D99F` (`CityMap+4723`); `$DA60`-`$DE81` (`CityMap+5648`); `$DEFD`-`$E0BE` (`CityMap+6829`); 2 more ranges |

### `MapAddrChecked` (`$6BDB`)

**HL = CityMap + 96 B + C for row B, column C below 96 (carry set); else carry clear**

L1 2 928 251.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 98,175 calls, 5,044,853 t-states own (0.34 %) |
| Called from | `MakeCoast`, `Disc`, `IsLand` |
| Calls | `MapAddr` |
| Writes | `$6BDA` (`MapEdge`) |

### `MapAddr` (`$6BE6`)

**HL = CityMap + 96 B + C**

L1 3 488 641.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 99,199 calls, 18,182,738 t-states own (1.21 %) |
| Called from | `DrawViewRowPass`, `DrawView`, `MapAddrChecked`, `ClickMapAddr` (tail) |

### `Disc` (`$6C09`)

**Draw a disc of DiscCell: 49 steps of a shift-based circle, each a horizontal run across it**

The run's ends come from the circle drawing x -= y >> s1, y += x >> s2 (the two shifts of DiscShapes), in 8.8 fixed point from (radius, 0): an ellipse when the shifts differ. L1 1920.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 160 calls, 11,949,707 t-states own (0.79 %) |
| Called from | `Discs` |
| Calls | `MapAddrChecked` |
| Reads | `$6C02`-`$6C08` (`DiscVars`, `DiscY`, `DiscRadius`, `DiscCell` and 2 more); `$6C1B` (`DiscX1+2`); `$C948`-`$CEA0` (`CityMap+1272`); `$CF5E`-`$CF5F` (`CityMap+2830`); `$CFBE`-`$D0DF` (`CityMap+2926`); `$D185`-`$DC39` (`CityMap+3381`); 4 more ranges |
| Writes | `$6C1A`-`$6C1E` (`DiscX1+1`, `DiscY1`); `$C883`-`$C884` (`CityMap+1075`); `$C8E0`-`$C8E7` (`CityMap+1168`); `$C8FB`-`$C8FC` (`CityMap+1195`); `$C93F`-`$C96E` (`CityMap+1263`); `$C99F`-`$C9D9` (`CityMap+1359`); 2 more ranges |

### `IsLand` (`$6C75`)

**Carry set when the cell at row B, column C is on the map and holds land (`$02`)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 36,264 calls, 3,298,982 t-states own (0.22 %) |
| Called from | `LandNeighbours` |
| Calls | `MapAddrChecked` |
| Reads | `$C450`-`$CCBA` (`CityMap`); `$CCE3`-`$DFBC` (`CityMap+2195`); `$DFFD`-`$E01B` (`CityMap+7085`); `$E05D`-`$E07A` (`CityMap+7181`); `$E0BD`-`$E0D9` (`CityMap+7277`); `$E11D`-`$E84F` (`CityMap+7373`) |

### `LandNeighbours` (`$6C84`)

**D = the land bits of the eight neighbours of (B, C), the row above first**

L1 54 876.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 4,533 calls, 1,562,252 t-states own (0.10 %) |
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
| Called from | `Click` |
| Reads | `$63C9`-`$63CA` (`ClickCell`) |

### `ScrollLeft` (`$6D05`)

**ViewCol - 1 down to 0**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/tools` 3) |

### `ScrollRight` (`$6D0F`)

**ViewCol + 1 up to 63**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20 calls (`stage1/rec/metro` 17, `stage1/rec/tools` 3) |

### `ScrollUp` (`$6D19`)

**ViewRow - 1 down to 0**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/tools` 3) |

### `ScrollDown` (`$6D23`)

**ViewRow + 1 up to 79**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 19 calls (`stage1/rec/metro` 16, `stage1/rec/tools` 3) |

### `ToolKeys` (`$6D2D`)

**SYMBOL SHIFT with a digit picks a tool: 1-9 tools 0-8, 0 tool 9**

L1 158 072; 30 with SYMBOL SHIFT (the tools recording's shortcuts).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 121,921 t-states own (0.01 %) |
| Called from | `UiTask`, `Interrupt` |
| Calls | `KeyToChar`, `DrawToolIcons`, `Sub24`, `ToolPrice`, `UiTask` |
| Reads | `$5B00`-`$5B07` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 4 more); `$6D50` (`CurrentTool`); `$8F97`-`$8F99` (`Funds`) |
| Writes | `$6D50` (`CurrentTool`) |

### `ToolClick` (`$6D51`)

**A click on the palette (rows 1-2, columns 2-29) picks tool (column - 2) / 2**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 12 calls, 850 t-states own (0.00 %) |
| Called from | `DrawToolIcons`, `Click` |
| Calls | `PrintToolName` |
| Reads | `$63C9`-`$63CA` (`ClickCell`) |

### `ShowTool` (`$6D90`)

**Highlight the current tool's icon and set the map box to its size (ToolSizes)**

L1 649.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5 calls, 1,510 t-states own (0.00 %) |
| Called from | `DrawStatusItems`, `PrintToolName`, `FundsChanged` (tail) |
| Calls | `InvertBox`, `ToolSize`, `GreyUnaffordable`, `UiTask` |
| Reads | `$6D50` (`CurrentTool`) |
| Writes | `$5D4F`-`$5D50` (`BoxSize`) |

### `ToolSize` (`$6DCB`)

**DE = ToolSizes[CurrentTool]**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 9 calls, 889 t-states own (0.00 %) |
| Called from | `ShowTool`, `CheckSite`, `PutBuilding` |
| Reads | `$6D50` (`CurrentTool`); `$6DB1`-`$6DBE` (`ToolSizes+2`) |

### `GreyUnaffordable` (`$6DDA`)

**Grey the palette icon of every tool whose price is more than Funds**

For the 14 tools: Funds - ToolPrice < 0 (Sub24) greys the icon (GreyIcon). Input: none. Side effect: the palette's pixels. L1 649.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 7 calls, 17,103 t-states own (0.00 %) |
| Called from | `ShowTool` |
| Calls | `Sub24`, `ToolPrice` |
| Reads | `$8F97`-`$8F99` (`Funds`) |

### `GreyIcon` (`$6DFD`)

**AND a checker (`$AA` / `$55`) into the 2 x 2 icon of tool C (row 1, column 2 + 2 C)**

L1 196.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 196 calls (`stage1/rec/bankrupt` 92, `stage1/rec/tools` 72, `stage1/rec/ports` 17 and 2 more) |

### `ToolPrice` (`$6E3A`)

**DE = ToolPrices[A]**

L1 9176 (GreyUnaffordable and SelectTool).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 103 calls, 8,819 t-states own (0.00 %) |
| Called from | `ToolKeys`, `GreyUnaffordable` |
| Reads | `$6E1E`-`$6E39` (`ToolPrices`) |

### `Spend` (`$6E46`)

**Funds = Funds - DE, unless that goes below 0: then carry set and Funds kept**

Every tool pays through here. Input: DE the price. Output: carry set when refused (nothing paid). L1 693.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 216 t-states own (0.00 %) |
| Called from | `IndustrialTool` |
| Calls | `Sub24` |
| Reads | `$8F97`-`$8F99` (`Funds`) |
| Writes | `$8F97`-`$8F99` (`Funds`) |

### `ClickMapAddr` (`$6E6A`)

**BC = the clicked map cell (ClickToMap), kept in ClickMapCell; HL = its map address**

L1 1713.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 226 t-states own (0.00 %) |
| Called from | `CheckSite`, `PutBuilding` |
| Calls | `MapAddr` (tail), `ClickToMap` |
| Writes | `$6E67`-`$6E68` (`ClickMapCell`) |

### `ClickToMap` (`$6E74`)

**BC = the map cell under ClickCell: column + ViewCol, row - 8 + ViewRow**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3 calls, 430 t-states own (0.00 %) |
| Called from | `ClickMapAddr` |
| Reads | `$63C9`-`$63CA` (`ClickCell`); `$6507`-`$6508` (`ViewCol`, `ViewRow`); `$6E69` (`MapCoordsGiven`) |

### `ClickToMapBC` (`$6E78`)

**BC (a view cell, screen row) to the map cell, unless MapCoordsGiven**

L1 3978.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,904 calls (`stage1/rec/city` 1,281, `stage1/rec/metro` 1,193, `stage1/rec/growth` 564 and 3 more) |

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

### `FixNetwork` (`$6E9B`)

**Re-shape the network cells of kind NetworkKind at BC and its four neighbours**

A road, rail or power line cell takes the shape (kind + NetworkShapes[mask]) of the neighbours of its own kind (the 4-bit mask of NeighbourMask). Input: BC, NetworkKind. Side effect: the map. L1 324.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NetworkBit` (`$6EBE`)

**A = the CellFlags bit that marks the kind as crossable: road (7) 4, rail (`$14`) 2, power (`$21`) 8**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 324 calls (`stage1/rec/city` 106, `stage1/rec/metro` 98, `stage1/rec/growth` 46 and 3 more) |

### `FixNetworkCell` (`$6EE3`)

**The cell at BC: when it is of NetworkKind, make it kind + its shape (not when CellFlags bit 0 keeps it)**

L1 1620.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,620 calls (`stage1/rec/city` 530, `stage1/rec/metro` 490, `stage1/rec/menus` 230 and 3 more) |

### `IsNetwork` (`$6F12`)

**Carry set when the cell at BC is of NetworkKind (kind to kind + 10) or (not BridgeMode) crossable by its flags**

L1 4200.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,200 calls (`stage1/rec/city` 1,410, `stage1/rec/metro` 1,306, `stage1/rec/growth` 594 and 3 more) |

### `NeighbourMask` (`$6F3C`)

**D = 4 bits: IsNetwork of the cells up, left, right, down of BC**

L1 645.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 645 calls (`stage1/rec/city` 220, `stage1/rec/metro` 204, `stage1/rec/growth` 91 and 3 more) |

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
| Called from | `Click` |
| Calls | `CrossNetwork`, `CheckSite`, `IndustrialTool` |
| Reads | `$5B01`-`$5B07` (`KeyRowA`, `KeyRowQ`, `KeyRow1`, `KeyRow0` and 3 more); `$5D54` (`BoxShown`); `$63CA` (`ClickCell+1`); `$6D50` (`CurrentTool`); `$7004`-`$7005` (`ToolHandlers+14`) |
| Writes | `$7040`-`$7041` (`ToolCall+1`) |

### `CrossNetwork` (`$7086`)

**A road, rail or power line clicked on another network: pay, write the crossing cell, reshape; carry set when done**

Road 10, rail 20, power 5. L1 470; the crossings themselves L1 47 (`$70E3`, power).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 157 t-states own (0.00 %) |
| Called from | `MapClick` |
| Reads | `$6D50` (`CurrentTool`) |

### `CheckSite` (`$7103`)

**Carry set when the tool's box at the click may not be built; clears trees at 1 dollar a cell**

On water, or with AutoBulldoze (`$A32B`) on: every cell of the box must be in SiteCells (water only for road, rail and power); each cell not in FreeCells costs 1 and becomes land 2. With AutoBulldoze off and a clicked cell that is not water: StrictSite, every cell must be land 2. That jump comes before the bulldozer's test at `$7118`, so with AUTO-BULLDOZE off the bulldozer is refused everywhere but on a water click; with AutoBulldoze on, or on water, it always passes. When Spend cannot pay 1 for clearing a cell, the cell is left as it is and the site still passes. L1 464.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 3,120 t-states own (0.00 %) |
| Called from | `MapClick` |
| Calls | `ToolSize`, `ClickMapAddr` |
| Reads | `$6D50` (`CurrentTool`); `$70FA`-`$70FC` (`FreeCells`, `SiteCells`); `$A32B` (`AutoBulldoze`); `$D2C3`-`$D2C5` (`CityMap+3699`); `$D323`-`$D325` (`CityMap+3795`); `$D383`-`$D385` (`CityMap+3891`) |
| Writes | `$7102` (`SiteWater`); `$7137` (`CheckSiteRow+2`) |

### `PutBuilding` (`$7197`)

**Copy the building pattern at IX (ToolSize width x height) into the map at the click**

L1 145.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 1,127 t-states own (0.00 %) |
| Called from | `IndustrialTool` |
| Calls | `ToolSize`, `ClickMapAddr` |
| Reads | `$7425`-`$742D` (`IndustrialZone`) |
| Writes | `$71A5` (`PutBuildingRow+2`); `$D2C3`-`$D2C5` (`CityMap+3699`); `$D323`-`$D325` (`CityMap+3795`); `$D383`-`$D385` (`CityMap+3891`) |

### `PlaceNetwork` (`$71BC`)

**Lay one cell of road, rail or power: HL the price, DE the bridge price, A the kind**

On water the Bridge; on land (2) pay, write the kind, FixNetwork, redraw; on anything else Refuse. L1 312.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 312 calls (`stage1/rec/city` 104, `stage1/rec/metro` 96, `stage1/rec/menus` 46 and 3 more) |

### `Refuse` (`$71E4`)

**The refusal: ToneBeep, but only when no direction key (A, Q, P, O) is held**

Three refusals beep: MapClick's after CheckSite (the site), PlaceNetwork's (a network on a building or a zone) and ParkTool's (map column 2); while the pointer is dragged with a key held the beep is left out. L1 3: 2 in tools, 1 in bankrupt.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/tools` 2, `stage1/rec/bankrupt` 1) |

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

### `RailTool` (`$73BD`)

**Tool 3: 20, bridge 100, cell `$14`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/tools` 2) |

### `PowerLineTool` (`$73C8`)

**Tool 2: 5, bridge 25, cell `$21`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 41 calls (`stage1/rec/ports` 15, `stage1/rec/metro` 12, `stage1/rec/city` 12 and 1 more) |

### `ParkTool` (`$73D4`)

**Tool 4: 10, a park `$38` (one in eight `$39`); refused (Refuse) when the map column is 2**

The CP `$02` tests A, which ClickMapAddr leaves as the column (MapAddr's LD A,C), not the cell: a park on map column 2 always beeps, any other site takes the park (CheckSite has cleared it already). Known only from the code; L1 1.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/tools` 1) |

### `ResidentialTool` (`$73FA`)

**Tool 5: 100, the zone at the click**

L1 77.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 77 calls (`stage1/rec/bankrupt` 23, `stage1/rec/metro` 18, `stage1/rec/city` 17 and 3 more) |

### `CommercialTool` (`$7414`)

**Tool 6: 100**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage1/rec/metro` 8, `stage1/rec/city` 8, `stage1/rec/menus` 3 and 2 more) |

### `IndustrialTool` (`$742E`)

**Tool 7: 100**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 114 t-states own (0.00 %) |
| Called from | `MapClick` |
| Calls | `DrawView` (tail), `Spend`, `PutBuilding` |

### `PoliceTool` (`$7448`)

**Tool 8: 500**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/metro` 1, `stage1/rec/tools` 1, `stage1/rec/menus` 1 and 2 more) |

### `FireTool` (`$7462`)

**Tool 9: 500**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/city` 1, `stage1/rec/metro` 1, `stage1/rec/growth` 1 and 2 more) |

### `StadiumTool` (`$7483`)

**Tool 10: 3000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/city` 1, `stage1/rec/ports` 1) |

### `PowerPlantTool` (`$74B4`)

**Tool 11: when the low 16 bits of Funds are 3000 or more (LD HL,(Funds): the high byte is ignored), the menu `$9F41` asks coal (3000) or nuclear (5000); SelectTool already refused it below the palette's 4000**

L1 8.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/tools` 3, `stage1/rec/growth` 1, `stage1/rec/city` 1 and 3 more) |

### `SeaportTool` (`$74F6`)

**Tool 12: 5000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/ports` 1) |

### `AirportTool` (`$752B`)

**Tool 13: 10 000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/tools` 1) |

## cityaccess

`src/game/cityaccess.asm`

### `Grid48` (`$753E`)

**A = GridBase[48 (B / 2) + C / 2]: a 48 x 48 array over 2 x 2 cells**

HL its address. L1 763 487.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 762,097 calls (`stage1/rec/metro` 240,252, `stage1/rec/city2` 219,301, `stage1/rec/city` 192,736 and 4 more) |

### `Grid24` (`$755A`)

**A = GridBase[24 (B / 4) + C / 4]: a 24 x 24 array over 4 x 4 cells**

L1 40 571.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 39,049 calls (`stage1/rec/metro` 16,026, `stage1/rec/city2` 9,902, `stage1/rec/city` 6,268 and 3 more) |

### `PollutionAt` (`$7579`)

**Grid48 of Pollution `$ADD0`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 55,020 calls (`stage1/rec/metro` 23,596, `stage1/rec/city2` 13,179, `stage1/rec/city` 10,252 and 6 more) |

### `TrafficAt` (`$7581`)

**Grid48 of Traffic `$B6D0`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 693,155 calls (`stage1/rec/metro` 213,632, `stage1/rec/city2` 203,098, `stage1/rec/city` 182,484 and 4 more) |

### `PoliceAt` (`$7589`)

**Grid24 of PoliceCover `$AB90`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,484 calls (`stage1/rec/metro` 13,724, `stage1/rec/city2` 7,735, `stage1/rec/city` 6,227 and 6 more) |

### `FireAt` (`$7591`)

**Grid24 of FireCover `$A950`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 943 calls (`stage1/rec/disasters` 718, `stage1/rec/metro` 94, `stage1/rec/city2` 55 and 2 more) |

### `CellFlagsOf` (`$7599`)

**A = CellFlags[A] for a cell below `$80`, `$99` for a building byte**

L1 11 343 551, the most run routine.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 154,012 calls, 24,185,437 t-states own (1.61 %) |
| Called from | `CellStep`, `LayerOf` |
| Reads | `$6F9C`-`$6FA2` (`CellFlags`); `$6FE5`-`$6FF2` (`CellFlags+73`) |

### `PutZoneBuilding` (`$75B0`)

**Write a 3 x 3 building of tile base DE + 9 A at the map address HL's cell: rows `$B3`, `$83`, `$83`**

The zones' growth writes its buildings here. L1 3235.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,235 calls (`stage1/rec/metro` 1,481, `stage1/rec/city2` 871, `stage1/rec/city` 646 and 2 more) |

### `WriteBuildingRow` (`$75CD`)

**One row: A, then the three tile bytes `$C0` | (n >> 3) and `$C0` | (n AND 7) pairs; HL the next row**

L1 9705.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,705 calls (`stage1/rec/metro` 4,443, `stage1/rec/city2` 2,613, `stage1/rec/city` 1,938 and 2 more) |

### `PowerBit` (`$75F1`)

**HL = the byte of the power bitmap PowerMap (`$BFD0`, 12 bytes a row) for cell (B, C); E its bit, D its mask**

L1 1 380 041.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,380,041 calls (`stage1/rec/metro` 576,820, `stage1/rec/city2` 342,039, `stage1/rec/city` 269,346 and 5 more) |

### `PowerBitAt` (`$7615`)

**The same for a map address in HL**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 2,499 t-states own (0.00 %) |
| Called from | `ZonePower` |
| Reads | `$5B15` (`BitMasks+4`) |

### `MapToRowCol` (`$7635`)

**B = row, C = column of the map address HL**

L1 669 924.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 669,926 calls (`stage1/rec/metro` 202,533, `stage1/rec/city2` 196,996, `stage1/rec/city` 178,073 and 5 more) |

### `Div8` (`$7647`)

**HL = HL / A, remainder in A**

L1 16 469.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 32 calls, 32,725 t-states own (0.00 %) |
| Called from | `ServiceNeeds` |

### `Max2x2` (`$7668`)

**A = the largest of the 2 x 2 bytes of a 48-wide array at HL**

L1 27 088.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27,088 calls (`stage1/rec/metro` 11,029, `stage1/rec/city2` 6,161, `stage1/rec/city` 4,943 and 5 more) |

### `BuildingValue` (`$768E`)

**A = the value of the cell at HL for its neighbours: a building's kind class, 9 for a developed zone cell; carry for nothing**

A type missing from the table returns with RET Z and BC still pushed: unreachable, every placed type is in the table. L1 191 120.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 191,120 calls (`stage1/rec/metro` 94,554, `stage1/rec/city2` 49,162, `stage1/rec/city` 34,076 and 3 more) |

### `NeighbourAddr` (`$76E4`)

**HL = the map address of the neighbour A of BC (BC moved)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 340,249 calls (`stage1/rec/metro` 167,108, `stage1/rec/city2` 88,192, `stage1/rec/city` 60,770 and 4 more) |

### `StepDir` (`$76ED`)

**BC = BC + Directions[A]**

L1 392 992.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 392,992 calls (`stage1/rec/metro` 191,451, `stage1/rec/city2` 101,053, `stage1/rec/city` 69,698 and 4 more) |

### `PushCell` (`$76FE`)

**Put BC on CellStack**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 37,898 calls (`stage1/rec/metro` 17,964, `stage1/rec/city2` 10,027, `stage1/rec/city` 7,104 and 3 more) |

### `PopCell` (`$7709`)

**Take BC from CellStack**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21,950 calls (`stage1/rec/metro` 10,329, `stage1/rec/city2` 5,680, `stage1/rec/city` 4,198 and 3 more) |

### `CellStackTop` (`$7714`)

**HL = the free slot of CellStack**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 59,848 calls (`stage1/rec/metro` 28,293, `stage1/rec/city2` 15,707, `stage1/rec/city` 11,302 and 3 more) |

### `NextMonth` (`$7720`)

**Month + 1; after December the year + 1**

L1 934 in c1's simulation. Month `$8F9B`, Year `$8F9C`.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 434 t-states own (0.00 %) |
| Called from | `SimTask` |
| Reads | `$8F9B` (`Month`) |
| Writes | `$8F9B` (`Month`) |

## movers

`src/game/movers.asm`

### `DrawMover` (`$7735`)

**Draw the 16 x 16 sprite A (MoverSprites `$A884`) at map cell (B, C), if it is in the view and its row is drawn this pass**

The sprite is ORed in. The "mask" computed from the screen byte, byte AND (byte OR byte shifted), is the byte itself, so nothing is cut. L1 2297.

[Animation: `DrawMover` at work](img/routines/DrawMover.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,297 calls (`stage1/rec/tools` 1,869, `stage1/rec/disasters` 428) |

### `DrawMovers` (`$778F`)

**Each pass: the train (not under a rail bridge), the plane and the tornado, if they are out**

The plane is sprite 0, the train 3 or 4 (by its direction), the tornado 1 or 2 at random (LD A,R). L1 158 076.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 385,103 t-states own (0.03 %) |
| Called from | `UiTask`, `Interrupt` |
| Calls | `UiTask` |
| Reads | `$77D6` (`TrainOut`); `$7879`-`$787B` (`PlaneOut`, `PlaneCell`); `$7995`-`$7997` (`TornadoCell`, `TornadoOut`) |

### `MoveTrain` (`$77DC`)

**Move the train one cell along the rails (CellFlags bit 1), never straight back; gone when it finds none**

Called through MoveDisasters by Periodic on every 16th UI pass (PassCount AND `$0F` = 0; L1 9884 against 158 073 UI passes); it moved in c1 (L1 442 at MoveTrainTry). A stuck move adds 1 to TrainSteps, a good one does not clear it: every fifth stuck move sets TrainBack 5 so the train may reverse.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 3,190 t-states own (0.00 %) |
| Called from | `MoveDisasters` (tail) |
| Reads | `$77D6` (`TrainOut`) |

### `StartTrain` (`$785D`)

**From a rail cell (RailCell `$8903`): when no train is out, 1 in 64 starts one there**

The `$9312` compare's result is lost (AND A follows): a dead test. L1 134.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 134 calls (`stage1/rec/tools` 134) |

### `MovePlane` (`$787E`)

**Fly the plane a column left; when the timer runs out, crash: burn a 2 x 2 (CrashCell) and the noise (CrashNoise)**

L1 9884; the crash L1 0 in the disaster recording? see NOTES.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 4,614 t-states own (0.00 %) |
| Called from | `MoveDisasters` |
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
| Runs | not reached in the recordings |

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

### `NuclearMeltdown` (`$7913`)

**With a nuclear plant (`$84A0`): message `$12` (NUCLEAR MELTDOWN), MeltdownPending, the noise**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |

### `Meltdown` (`$7925`)

**The plant catches fire (cell `$45` over it all) and 1 in 16 of the 45 x 45 cells round it turn to radiation `$59`**

L1 890 (the test).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 890 calls (`stage1/rec/metro` 393, `stage1/rec/city2` 219, `stage1/rec/city` 211 and 2 more) |

### `Irradiate` (`$795E`)

**A non-water cell below `$80` at BC becomes `$59`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 112 calls (`stage1/rec/disasters` 112) |

### `StartTornado` (`$796C`)

**The TORNADO disaster: message `$1A`, the tornado on a random land cell of rows and columns 16-79**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |

### `MoveTornado` (`$7998`)

**Move the tornado: 1 in 8 toward the city centre (`$84A2`), else a random step; off when Random gives 0**

The cell down and right of it is hit: a building burns (BurnBuilding), a flammable cell (CellFlags bit 7) becomes `$3A`. It stops at water. Its step uses MapAddr, not MapAddrChecked: no edge check, so from the top row it can walk into the ROM rows (`$23F0` on) and wrap at the column edges (only the hit cell is checked). L1 9884; the work L1 27.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 3,768 t-states own (0.00 %) |
| Called from | `MoveDisasters` |
| Reads | `$7997` (`TornadoOut`) |

## joysticks

`src/game/joysticks.asm`

### `ReadKempston` (`$7A01`)

**Fold the Kempston bits into KeyRows: right -> P, left -> O, down -> A, up -> Q, fire -> SPACE**

Called by ReadInput (`$F792`) every interrupt; KempstonFound decides its use. L1 413 183.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 626,880 t-states own (0.04 %) |
| Called from | `ReadInput` |
| Calls | `ReadPort1F` |

### `ReadSinclair` (`$7A32`)

**With SYMBOL SHIFT and CAPS SHIFT up: keys 7 -> P, 6 -> O, 8 -> A, 9 -> Q, 0 -> SPACE**

The Sinclair (Interface 2, port 2) joystick on keys 6-0: 6 left, 7 right, 8 down, 9 up, 0 fire. Run every interrupt (L1 413 183); with a shift down it is skipped, so SYMBOL SHIFT + digit stays the tool keys. Open point 2.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 864,754 t-states own (0.06 %) |
| Called from | `ReadInput` (tail) |
| Reads | `$5B00`-`$5B07` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 4 more) |

### `ShiftScroll` (`$7A6F`)

**CAPS SHIFT with 5, 6, 7, 8: scroll the view a cell left, down, up, right, then redraw**

L1 158 073.

[Animation: `ShiftScroll` at work](img/routines/ShiftScroll.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 72,462 t-states own (0.00 %) |
| Called from | `UiTask` |
| Reads | `$5B00` (`KeyRows`) |

## maps

`src/game/maps.asm`

### `DrawMapsFrame` (`$7A9E`)

**The maps window: clear, the frame, the legend and the keys 1-9 (inline texts)**

L1 5.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 34 t-states own (0.00 %) |
| Called from | `ClearForMaps`, `MapsWindow` |
| Calls | `ClearForMaps`, `PrintInline` |

### `DrawMapsKeys` (`$7B09`)

**DrawMapsKeys**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 17 t-states own (0.00 %) |
| Called from | `PrintDigit` |
| Calls | `PrintInline` |

### `DrawMapsEnd` (`$7B4F`)

**RET**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 14 t-states own (0.00 %) |
| Called from | `PrintDigit` |
| Calls | `MapsWindow` |

### `MapsWindow` (`$7B51`)

**The MAPS menu item: show the overview map, pick a layer with the digit keys, until SPACE**

L1 5. The overview draws through `$9B60`, `$9B76` and `$9C57`.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 278 t-states own (0.00 %) |
| Called from | `ClearViewArea`, `DrawStatusItems`, `DrawMapsEnd`, `UiTask`, `DrawOverview` |
| Calls | `ClearTopBlack`, `DrawStatusPanel`, `DrawView` (tail), `DrawMapsFrame`, `HighlightMapKey`, `HighlightLayer`, `DrawOverview` |
| Reads | `$5B07` (`KeyRowSpace`); `$8E93` (`BudgetDue`) |
| Writes | `$A511` (`MapsDue`) |

## simulation

`src/game/simulation.asm`

### `FillBuilding` (`$7B86`)

**Fill the whole building at HL with the cell SpreadCode (`$8998`)**

L1 8.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/disasters` 8) |

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

### `StampPolice` (`$7C32`)

**Add the police coverage into PoliceCover**

No clipping at the map edge: the kernel origin is grid cell - 50 (Grid24) or - `$62` (Grid48). L1 233.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 233 calls (`stage1/rec/metro` 93, `stage1/rec/city2` 55, `stage1/rec/city` 42 and 2 more) |

### `AddPolice` (`$7C5A`)

**One cell: A = strength >> (kernel - 1), added and clamped to 15**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,825 calls (`stage1/rec/metro` 2,325, `stage1/rec/city2` 1,375, `stage1/rec/city` 1,050 and 2 more) |

### `AddFire` (`$7C5F`)

**AddFire**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,700 calls (`stage1/rec/metro` 2,350, `stage1/rec/city2` 1,375, `stage1/rec/city` 1,025 and 2 more) |

### `StampPollution` (`$7CC0`)

**Add PollutionStrength through the kernel at IX into Pollution round the current cell**

No clipping at the map edge: the kernel origin is grid cell - 50 (Grid24) or - `$62` (Grid48). L1 8425.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8,425 calls (`stage1/rec/metro` 3,401, `stage1/rec/city2` 1,979, `stage1/rec/city` 1,535 and 5 more) |

### `StampPollutionIX` (`$7CC8`)

**StampPollutionIX**

L1 30 375.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 30,278 calls (`stage1/rec/metro` 13,730, `stage1/rec/city2` 7,659, `stage1/rec/city` 5,733 and 3 more) |

### `AddPollutionCell` (`$7CE8`)

**One cell: A = PollutionStrength >> (kernel - 1), added, clamped to `$FF`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,093,483 calls (`stage1/rec/metro` 494,280, `stage1/rec/city2` 275,724, `stage1/rec/city` 206,388 and 5 more) |

### `ZonePollution` (`$7CFE`)

**ZonePollutionMax = the largest Pollution of the 2 x 2 at the current cell; summed into PollutionSum (`$847A`, `$847C`)**

L1 24 645.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 24,645 calls (`stage1/rec/metro` 9,866, `stage1/rec/city2` 5,520, `stage1/rec/city` 4,519 and 5 more) |

### `ZoneTraffic` (`$7D1D`)

**ZoneTrafficMax = the largest Traffic of the 2 x 2 at the current cell**

L1 2443.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,443 calls (`stage1/rec/metro` 1,163, `stage1/rec/city2` 641, `stage1/rec/city` 424 and 3 more) |

### `ScanRingSize` (`$7D2F`)

**ScanRing for a building of size HL**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 623 calls (`stage1/rec/city2` 220, `stage1/rec/metro` 206, `stage1/rec/city` 167 and 1 more) |

### `ScanRing` (`$7D34`)

**Look at the ring of cells round the zone at BC (3 x 3) and its inside**

The ring (ScanRingCell): roads and rails count in RingTransport (one of them becomes RouteStart at random), parks (`$38`, `$39`) in RingParks, water in RingWater, trees in RingTrees, each adding to RingAmenity (12 for transport, 14 a park, 16 water or trees), capped at `$7F`. The inside (ScanInsideCell) adds the developed cells' density (cell - `$3B`) to Density `$8869`. L1 32 092 + 623.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 32,092 calls (`stage1/rec/metro` 13,238, `stage1/rec/city2` 7,460, `stage1/rec/city` 5,975 and 5 more) |

### `ScanRingCell` (`$7D88`)

**One ring cell: count it by kind into the Ring counters**

L1 395 063.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 395,064 calls (`stage1/rec/metro` 162,152, `stage1/rec/city2` 93,040, `stage1/rec/city` 74,372 and 5 more) |

### `PickRouteStart` (`$7DD8`)

**The first transport cell, then each next one with 1 in 2, becomes RouteStart**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 115,099 calls (`stage1/rec/metro` 49,821, `stage1/rec/city2` 28,191, `stage1/rec/city` 22,209 and 3 more) |

### `ScanInsideCell` (`$7DEA`)

**A developed cell (CellFlags bit 6) inside the zone adds cell - `$3B` to Density**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 298,789 calls (`stage1/rec/metro` 122,438, `stage1/rec/city2` 70,660, `stage1/rec/city` 56,447 and 5 more) |

### `CentreDistance` (`$7E03`)

**A = |CityCentre row - B| + |CityCentre column - C|: B the row, C the column**

CityCentre is (column, row), so H is its row and L its column. Both callers pass BC = (row, column) loaded from a (column, row) word: CentreCloseness from CurCell `$8785`, LayerCrime from OverviewCellAt `$9C31`.

L1 27 944.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27,944 calls (`stage1/rec/metro` 12,026, `stage1/rec/city2` 6,879, `stage1/rec/city` 5,396 and 3 more) |

### `LandValueOf` (`$7E1D`)

**LandValue = 127 - CentreDistance + RingAmenity, for a powered zone with transport and a trip (or traffic 50+); else 0**

Summed into LandValueSum (`$8472`, count `$8474`). L1 33 251.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,251 calls (`stage1/rec/metro` 13,631, `stage1/rec/city2` 7,680, `stage1/rec/city` 6,185 and 6 more) |

### `CentreCloseness` (`$7E5A`)

**A = 127 - CentreDistance, 0 when farther**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27,944 calls (`stage1/rec/metro` 12,026, `stage1/rec/city2` 6,879, `stage1/rec/city` 5,396 and 3 more) |

### `CrimeOf` (`$7E6A`)

**Crime = (255 - LandValue) / 16 - PoliceCover here, not below 0; summed into CrimeSum (`$846E`, `$8470`)**

L1 33 251.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,251 calls (`stage1/rec/metro` 13,631, `stage1/rec/city2` 7,680, `stage1/rec/city` 6,185 and 6 more) |

### `TaxPenaltyOf` (`$7E9B`)

**TaxPenalty = 8 x TaxRate (`$91E4`); 10 x on medium (Level 1), 9 x on difficult (Level 2) (`$A518`)**

The second addition is skipped by CP `$02` / RET Z (`$7EB4`) on Level 2 only, so the difficult level pays less than the medium one. L1 33 251.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,251 calls (`stage1/rec/metro` 13,631, `stage1/rec/city2` 7,680, `stage1/rec/city` 6,185 and 6 more) |

### `ZoneScoreOf` (`$7EC4`)

**ZoneScore = LandValue - Pollution - Crime - TaxPenalty + ZoneDemand, clamped 0-255; 0 with pollution 28+ or no land value**

The heart of the growth: a zone grows when its score is high. L1 33 251.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,251 calls (`stage1/rec/metro` 13,631, `stage1/rec/city2` 7,680, `stage1/rec/city` 6,185 and 6 more) |

### `Clamp8` (`$7F04`)

**L = HL clamped to 0-255 (negative 0, above 255 255)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21,592 calls (`stage1/rec/metro` 8,995, `stage1/rec/city2` 5,562, `stage1/rec/city` 4,366 and 3 more) |

### `ResidentialScore` (`$7F12`)

**ResLevel = (ZoneScore - 128) / 16 (0 below 128... `$0F`), ResTile = ZoneScore / 2, or 16 ResLevel + `$50` from 128 up**

L1 17 800.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17,800 calls (`stage1/rec/metro` 6,797, `stage1/rec/city2` 3,731, `stage1/rec/city` 3,180 and 5 more) |

### `CommercialScore` (`$7F45`)

**CommercialScore**

L1 6845.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,845 calls (`stage1/rec/metro` 3,069, `stage1/rec/city2` 1,789, `stage1/rec/city` 1,339 and 2 more) |

### `IndustrialScore` (`$7F5F`)

**IndustrialScore**

L1 7446.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,446 calls (`stage1/rec/metro` 3,372, `stage1/rec/city2` 1,941, `stage1/rec/city` 1,455 and 2 more) |

### `FindPlants` (`$7F98`)

**Scan the map for 4 x 4 building tops (`$B4`) of type 6 (coal) or 8 (nuclear) into PowerPlants**

Finds only top row bytes `$B4` (powered, width 4) of type 6 (coal) or 8 (nuclear) (LD A,`$B4` / CPIR at `$7FA2`). L1 1101 (once a simulation pass).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 3,499,233 t-states own (0.23 %) |
| Called from | `PowerFlood` |
| Reads | `$C450`-`$E850` (`CityMap`, `IconTiles`) |
| Writes | `$7F78`-`$7F79` (`PowerPlants`) |

### `PowerFlood` (`$7FCD`)

**Clear PowerMap, then flood the power from each station over conducting cells: nuclear 1350 cells, coal 450**

L1 1101. Every powered cell costs one of the station's budget; a station that runs out stops its flood (Brownout + 1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 441,699 t-states own (0.03 %) |
| Called from | `SimTask` |
| Calls | `FindPlants` |
| Reads | `$7F78`-`$7F79` (`PowerPlants`); `$BFD0`-`$C44E` (`PowerMap`) |
| Writes | `$7FCC` (`Brownout`); `$BFD0`-`$C44F` (`PowerMap`) |

### `FloodFill` (`$811D`)

**A scan-line flood fill from FloodStart over IsConductive cells, each made powered (PowerCell)**

FloodPush silently drops a span when CellStack is full; a plant whose top cell an earlier plant's flood powered floods nothing (IsConductive fails at once), so its budget is lost. L1 1162.

[Animation: `FloodFill` at work](img/routines/FloodFill.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,162 calls (`stage1/rec/metro` 393, `stage1/rec/city2` 219, `stage1/rec/city` 211 and 5 more) |

### `FloodMark` (`$816D`)

**Queue the cell above or below once per run of conducting cells (flag at HL)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 640,716 calls (`stage1/rec/metro` 269,864, `stage1/rec/city2` 158,118, `stage1/rec/city` 124,710 and 5 more) |

### `FloodPush` (`$8177`)

**Push BC on the span stack, unless it is full (`$811D`)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18,267 calls (`stage1/rec/metro` 6,910, `stage1/rec/city2` 4,380, `stage1/rec/city` 3,559 and 5 more) |

### `FloodPop` (`$818F`)

**BC from the span stack**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18,267 calls (`stage1/rec/metro` 6,910, `stage1/rec/city2` 4,380, `stage1/rec/city` 3,559 and 5 more) |

### `IsConductive` (`$819A`)

**Z set when the cell at BC is on the map, not powered yet and a building or CellFlags bit 3**

L1 1 057 667.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,057,667 calls (`stage1/rec/metro` 440,928, `stage1/rec/city2` 261,924, `stage1/rec/city` 206,991 and 5 more) |

### `PowerCell` (`$81C2`)

**Set the cell's bit in PowerMap and count FloodBudget down; at 0 leave the flood (SP back) with Brownout + 1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 320,358 calls (`stage1/rec/metro` 134,932, `stage1/rec/city2` 79,059, `stage1/rec/city` 62,355 and 5 more) |

### `AssessCity` (`$81E3`)

**CityValue = rails x 5 + roads x 10 + police x 1000 + fire x 1000 + hospitals x 400 + stadiums x 3000 + seaports x 5000 + airports x 10 000 + coal x 3000 + nuclear x 6000**

L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 8,192 t-states own (0.00 %) |
| Called from | `SimTask` |
| Calls | `Mul16`, `AddValue` |
| Reads | `$81DD`-`$81DF` (`CityValue`); `$844C`-`$846D` (`PoliceCount`, `FireCount`, `ChurchCount`, `HospitalCount` and 13 more) |
| Writes | `$81DD`-`$81E2` (`CityValue`, `CityValueLast`) |

### `AddValue` (`$824F`)

**CityValue = CityValue + HL x DE**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 144 calls, 16,454 t-states own (0.00 %) |
| Called from | `AssessCity` |
| Calls | `Add24`, `Mul16` |
| Reads | `$81DD`-`$81DF` (`CityValue`) |
| Writes | `$81DD`-`$81DF` (`CityValue`) |

### `PopBalanceOf` (`$8267`)

**PopBalanceOf**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 2,144 t-states own (0.00 %) |
| Called from | `SimTask` |
| Reads | `$8446`-`$844B` (`ResPop`, `ComPop`, `IndPop`) |
| Writes | `$8265`-`$8266` (`PopBalance`) |

### `DemandOf` (`$8282`)

**R = 8 (C + I - R) + 4 stadiums - 26; C = 8 ((R + I) / 2 - C) + 4 airports - 30; I = 8 ((R + C) / 2 - I) + 4 seaports - 30**

R, C, I are the populations ResPop `$8446`, ComPop `$8448`, IndPop `$844A`. L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 10,896 t-states own (0.00 %) |
| Called from | `SimTask` |
| Reads | `$8446`-`$845D` (`ResPop`, `ComPop`, `IndPop`, `PoliceCount` and 8 more) |
| Writes | `$827C`-`$8281` (`ResDemand`, `ComDemand`, `IndDemand`) |

### `AddPopulation` (`$82EE`)

**Population (`$8443`, 24 bits) = Population + 16 DE**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17,801 calls (`stage1/rec/metro` 6,798, `stage1/rec/city2` 3,731, `stage1/rec/city` 3,180 and 5 more) |

### `StartSimulation` (`$830C`)

**Make the simulation task (entry SimTask, SP `$F6EE`), the date January 1902, Funds by the level: 20 000, 10 000, 5000**

L1 13.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 428 t-states own (0.00 %) |
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
| Called from | `StartSimulation`, `SimTask` |
| Reads | `$A950`-`$C44E` (`FireCover`, `PoliceCover`, `Pollution`, `Traffic` and 1 more) |
| Writes | `$77D6` (`TrainOut`); `$7879`-`$787D` (`PlaneOut`, `PlaneCell`, `PlaneTarget`, `PlaneTimer`); `$7924` (`MeltdownPending`); `$7997` (`TornadoOut`); `$7C08` (`FireStrength`); `$7C31` (`PoliceStrength`); 13 more ranges |

### `ClearCounters` (`$8480`)

**Zero `$8443-$847F`; the city's extent to empty (min `$FF`, max 0)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 23,205 t-states own (0.00 %) |
| Called from | `SimTask` |
| Reads | `$8443`-`$847E` (`Population`, `ResPop`, `ComPop`, `IndPop` and 26 more) |
| Writes | `$8443`-`$847F` (`Population`, `ResPop`, `ComPop`, `IndPop` and 26 more); `$87C8`-`$87CB` (`ExtentCols`, `ExtentRows`) |

### `Averages` (`$84A4`)

**CityCentre = the middle of the extent; the last-pass copies; AvgPollution = PollutionSum / count**

CityCentre = (max + min) / 2 of ExtentCols and ExtentRows, the box of every zone and building ZoneStep met this pass (WidenExtent). InitSimulation starts it at 32, 32; a pass with no zones leaves the cleared box 0, `$FF` and gives 127, 127. L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 4,448 t-states own (0.00 %) |
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
| Called from | `SimTask` |
| Calls | `Div16` |
| Reads | `$835E` (`SimPass`); `$847A`-`$847D` (`PollutionSum`, `PollutionCount`); `$ADD0`-`$B6CF` (`Pollution`) |
| Writes | `$84DD` (`AvgPollution`); `$ADD0`-`$B6CF` (`Pollution`) |

### `ClearCover` (`$850C`)

**Zero FireCover and PoliceCover (`$A950-$ADCF`)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 4 calls, 96,883 t-states own (0.01 %) |
| Called from | `CoverStations` |
| Reads | `$A950`-`$ADCE` (`FireCover`, `PoliceCover`) |
| Writes | `$A950`-`$ADCF` (`FireCover`, `PoliceCover`) |

### `DecayTraffic` (`$851B`)

**Sum the traffic, then each Traffic byte: below 24 to 0, 200 and up - 34, else - 24**

L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 3,652,357 t-states own (0.24 %) |
| Called from | `SimTask` |
| Calls | `Div16` |
| Reads | `$8476`-`$8479` (`TrafficSum`, `TrafficCount`); `$B6D0`-`$BFCF` (`Traffic`) |
| Writes | `$851A` (`AvgTraffic`); `$B6D0`-`$BFCF` (`Traffic`) |

### `MakeTrip` (`$856A`)

**From RouteStart walk the roads or rails (TripWalk) to a zone of the wanted kind; on success the path gets traffic**

L1 9735.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,735 calls (`stage1/rec/metro` 4,344, `stage1/rec/city2` 2,656, `stage1/rec/city` 1,939 and 3 more) |

### `AddTripTraffic` (`$8599`)

**A road trip: each cell of the path + 20 Traffic (to `$F0`) and pollution (strength 5, TrafficKernel)**

L1 7281.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7,281 calls (`stage1/rec/metro` 3,181, `stage1/rec/city2` 2,016, `stage1/rec/city` 1,515 and 3 more) |

### `TripWalk` (`$85D6`)

**Up to 30 steps of TripStep, each checked for arrival (TripArrived); carry when lost**

A dead end drops one pushed cell without counting a step or moving; with no way on, the trip is lost. L1 9735.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9,735 calls (`stage1/rec/metro` 4,344, `stage1/rec/city2` 2,656, `stage1/rec/city` 1,939 and 3 more) |

### `TripStep` (`$8609`)

**One step: from a random direction try the four, not back, onto a cell with TripMask; every second step pushed**

L1 67 734.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 67,734 calls (`stage1/rec/metro` 33,018, `stage1/rec/city2` 17,764, `stage1/rec/city` 12,173 and 3 more) |

### `TripArrived` (`$8660`)

**Carry clear when a neighbour's BuildingValue is one of TripTargets**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 49,623 calls (`stage1/rec/metro` 24,342, `stage1/rec/city2` 12,861, `stage1/rec/city` 8,928 and 3 more) |

### `CoverStations` (`$8680`)

**Every 4th pass: ClearCover, then each powered top row byte (AND `$F0` = `$B0`, any width: police type 0, fire type 1) stamps its coverage**

L1 1090 (273 stamping).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 2,186,224 t-states own (0.15 %) |
| Called from | `SimTask` |
| Calls | `ClearCover` |
| Reads | `$835E` (`SimPass`); `$C450`-`$E84F` (`CityMap`) |

### `CoverPolice` (`$86B7`)

**CoverPolice**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 233 calls (`stage1/rec/metro` 93, `stage1/rec/city2` 55, `stage1/rec/city` 42 and 2 more) |

### `CoverFire` (`$86BF`)

**CoverFire**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 228 calls (`stage1/rec/metro` 94, `stage1/rec/city2` 55, `stage1/rec/city` 41 and 2 more) |

### `ScanCity` (`$86C9`)

**Every map cell: buildings' power (BuildingPower), zones' power (ZonePower), then their step (ZoneStep) and the plain cells (CellStep)**

L1 1101; 10 084 466 cells.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 17 calls, 31,752,426 t-states own (2.11 %) |
| Called from | `SimTask` |
| Calls | `ZonePower`, `ZoneStep`, `CellStep` |
| Reads | `$835D` (`SimPaused`); `$86C6` (`CellKind`); `$C450`-`$E84F` (`CityMap`) |
| Writes | `$86C5`-`$86C8` (`ZonePowered`, `CellKind`, `BuildingType`, `ZoneCentre`) |

### `BuildingPower` (`$870C`)

**A building's top-left byte: bit 4 = powered (PowerMap), ZonePowered; BuildingType; the power plants (types 6, 8) skip both: their top byte keeps the prefab's `$B4` and ZonePowered stays 0**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14,526 calls (`stage1/rec/metro` 6,048, `stage1/rec/city2` 3,718, `stage1/rec/city` 2,811 and 5 more) |

### `ZonePower` (`$873C`)

**A zone centre: `$51-$53` when powered, `$54-$56` (blinking) when not**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 4,214 t-states own (0.00 %) |
| Called from | `ScanCity` |
| Calls | `PowerBitAt` |
| Reads | `$873B` (`ZoneCentreCell`); `$C1AA` (`PowerMap+474`); `$D324` (`CityMap+3796`) |
| Writes | `$86C6`-`$86C8` (`CellKind`, `BuildingType`, `ZoneCentre`); `$873B` (`ZoneCentreCell`) |

### `ZoneStep` (`$8789`)

**A zone or building: count it powered or not, widen the extent, then the zone's growth or the building's routine**

L1 36 698.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 3,108 t-states own (0.00 %) |
| Called from | `ScanCity`, `IndustrialStep` |
| Calls | `CountPowered`, `WidenExtent`, `IndustrialStep` (tail) |
| Reads | `$86C6`-`$86C8` (`CellKind`, `BuildingType`, `ZoneCentre`) |
| Writes | `$8785`-`$8788` (`CurCell`, `CurAddr`); `$8869` (`Density`) |

### `CountPowered` (`$87AA`)

**PoweredZones or UnpoweredZones + 1**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 1,288 t-states own (0.00 %) |
| Called from | `ZoneStep` |
| Reads | `$845E`-`$845F` (`UnpoweredZones`); `$86C5` (`ZonePowered`) |
| Writes | `$845E`-`$845F` (`UnpoweredZones`) |

### `WidenExtent` (`$87CC`)

**ExtentCols and ExtentRows take in CurCell**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 882 t-states own (0.00 %) |
| Called from | `ZoneStep` |
| Calls | `MinMax` |
| Reads | `$8785`-`$8786` (`CurCell`) |

### `MinMax` (`$87DB`)

**(HL) = max, (HL+1) = min with A**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 28 calls, 1,568 t-states own (0.00 %) |
| Called from | `WidenExtent` |
| Reads | `$87C8`-`$87CB` (`ExtentCols`, `ExtentRows`) |
| Writes | `$87C8`-`$87CB` (`ExtentCols`, `ExtentRows`) |

### `ZoneByKind` (`$87E4`)

**Density 0; the R, C or I zone's growth**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BuildingStep` (`$886B`)

**Look up the building's type in BuildingKinds and jump to its routine**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14,526 calls (`stage1/rec/metro` 6,048, `stage1/rec/city2` 3,718, `stage1/rec/city` 2,811 and 5 more) |

### `CellStep` (`$8898`)

**A plain cell: fire `$45`, flood `$44`, radiation `$59`; roads and rails counted and decayed**

L1 10 084 463.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 153,148 calls, 30,948,037 t-states own (2.06 %) |
| Called from | `ScanCity` |
| Calls | `CellFlagsOf` |
| Reads | `$C450`-`$E84F` (`CityMap`) |
| Writes | `$8785`-`$8788` (`CurCell`, `CurAddr`) |

### `RoadCell` (`$88C6`)

**Count the road (RoadCount, upkeep + 1, a bridge + 3); with RoadDecay it may crumble to `$3A`**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RailCell` (`$8903`)

**Count the rail (RailCount, upkeep + 4, a bridge + 6), StartTrain; with RailDecay it may crumble**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RadiationCell` (`$8942`)

**`$59`: with 1 in 4096 rubble, else pollution `$40` round it**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 538 calls (`stage1/rec/disasters` 538) |

### `ToRubble` (`$8956`)

**the cell becomes `$3A`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 104 calls (`stage1/rec/disasters` 104) |

### `ToLand` (`$895C`)

**the cell becomes land 2**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FireCell` (`$8962`)

**`$45`: FireCells + 1; put out with a chance of (FireCover + 1) / 16, else Spread**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 715 calls (`stage1/rec/disasters` 715) |

### `FloodCell` (`$8986`)

**`$44`: while FloodLeft, spread the water; then the cell dries to land**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 146 calls (`stage1/rec/disasters` 146) |

### `Spread` (`$899B`)

**Each of the four neighbours that burns (flags bit 7, a building) or floods: 1 in 8 catches; a fire with nothing round dies with 1 in 4**

No edge check: the JR NC,SpreadNext after MapAddr is dead, because MapAddr always sets carry. From row 0 the step up lands in the ROM (`$23F0` + column), from row 95 the step down in IconTiles (`$E850` + column); from column 95 the step right is column 0 of the next row, from column 0 the step left is column 63 two rows down. Known only from the code.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 768 calls (`stage1/rec/disasters` 768) |

### `SpreadTo` (`$89EA`)

**The neighbour at HL takes SpreadCode: a whole building (FillBuilding), else the cell (not the bridges, not water for floods)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 136 calls (`stage1/rec/disasters` 136) |

### `PickFrameCell` (`$8A20`)

**BC = a random one of the eight frame cells round CurCell; IX its ZoneFrame row**

L1 51 171.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 51,171 calls (`stage1/rec/metro` 18,814, `stage1/rec/bankrupt` 10,520, `stage1/rec/city2` 7,261 and 5 more) |

### `GrowZone` (`$8A40`)

**GrowTries (`$8F67`) times: a frame cell one house up (GrowCell); stop at the first that grows**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,667 calls (`stage1/rec/metro` 2,691, `stage1/rec/city2` 1,652, `stage1/rec/city` 1,528 and 3 more) |

### `GrowCell` (`$8A53`)

**A frame cell (CellFlags bit 4): the empty frame becomes house `$3C`, a house `$3C-$42` one more; `$43` full (carry)**

L1 6862.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,862 calls (`stage1/rec/metro` 2,748, `stage1/rec/city2` 1,727, `stage1/rec/city` 1,589 and 3 more) |

### `DeclineZone` (`$8A70`)

**GrowTries times: a frame cell one house down (DeclineCell)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11,133 calls (`stage1/rec/metro` 4,106, `stage1/rec/city2` 2,079, `stage1/rec/city` 1,652 and 5 more) |

### `DeclineCell` (`$8A83`)

**A house one down; `$3C` goes back to the empty frame cell; an empty frame cell does not decline (carry)**

L1 44 309.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 44,309 calls (`stage1/rec/metro` 16,066, `stage1/rec/bankrupt` 10,520, `stage1/rec/growth` 5,831 and 5 more) |

### `ResidentialStep` (`$8AA3`)

**The R zone: ResPop + 1, Population + 16 Density, a trip to C or I (when Random AND 63 < Density), the score; grow or decline**

Grows while Density < ResTile (ZoneScore / 2), else declines; a full zone (Density 63+) becomes a 3 x 3 building: a ChurchNeed or HospitalNeed building first (`$1B`, `$12`), else the residential block (tile `$88`). L1 17 802.

[Animation: `ResidentialStep` at work](img/routines/ResidentialStep.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17,802 calls (`stage1/rec/metro` 6,798, `stage1/rec/city2` 3,731, `stage1/rec/city` 3,180 and 5 more) |

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

### `ComBuildingStep` (`$8BE0`)

**a commercial building (types `$15-$18`): the same from the building's corner**

A building that reverts mid-scan is counted twice in the pass: the reverted 3 x 3 zone is met again by ScanCity.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 2 more) |

### `ComRevert` (`$8C4A`)

**Put ComEmptyZone at the zone**

L1 126.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `IndustrialStep` (`$8C5B`)

**The I zone: IndPop + 1; powered: ring, a trip to R, the score (pollution not counted); with the I chance a building of its level, or back; pollution 4 x IndLevel**

L1 1795.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 14 calls, 1,134 t-states own (0.00 %) |
| Called from | `ZoneStep` (tail) |
| Calls | `ZoneStep` |
| Reads | `$844A`-`$844B` (`IndPop`); `$86C5` (`ZonePowered`) |
| Writes | `$844A`-`$844B` (`IndPop`) |

### `IndBuildingStep` (`$8C77`)

**an industrial building (types `$1A-$1D`)**

A building that reverts mid-scan is counted twice in the pass: the reverted 3 x 3 zone is met again by ScanCity (IndPop 12 with 8 I zones, city frame 29 000).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 2 more) |

### `NoGrowthAlone` (`$8CE0`)

**A = 0 when last month's population (LastPop) was 0, else A kept: a city of nobody falls back**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,080 calls (`stage1/rec/metro` 1,898, `stage1/rec/city2` 1,097, `stage1/rec/city` 795 and 2 more) |

### `IndRevert` (`$8CFA`)

**Put IndEmptyZone at the zone**

L1 719.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CoalStep` (`$8D0B`)

**A coal station: CoalCount + 1, pollution `$FF` round it**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/growth`, `stage1/rec/menus`, `stage1/rec/tools` and 1 more) |

### `NuclearStep` (`$8D2F`)

**A nuclear station: NuclearCount + 1, Meltdown (when pending), pollution `$30`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 2 more) |

### `PoliceStep` (`$8D56`)

**A police station: PoliceUpkeep (`$8466`) + 100 (saturating, before the power test); powered, PoliceCount + 1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 4 more) |

### `FireStep` (`$8D73`)

**A fire station: FireUpkeep (`$8468`) + 100 (saturating, before the power test); powered, FireCount + 1**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/city` and 4 more) |

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

### `SeaportStep` (`$8E10`)

**A powered seaport with water and transport round it: 1 in 32 a trip to I; SeaportCount + 1; pollution `$60`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/ports`) |

### `AirportStep` (`$8E52`)

**A powered airport (6 x 6): 1 in 32 a trip to C; AirportCount + 1; StartPlane**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/tools`) |

### `MonthEnd` (`$8E94`)

**LastPop; in December: the year's populations, the costs to the budget (`$9311-$9315`), the budget (shown, or auto), Funds**

L1 934; the December branch L1 77.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 8 calls, 776 t-states own (0.00 %) |
| Called from | `SimTask` |
| Reads | `$8443`-`$8445` (`Population`); `$8F9B` (`Month`) |
| Writes | `$8E8A`-`$8E8C` (`LastPop`) |

### `Averages2` (`$8F05`)

**AvgCrime, AvgLandValue, LastBuildings**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 3,360 t-states own (0.00 %) |
| Called from | `SimTask` |
| Calls | `Div16` |
| Reads | `$8462`-`$8475` (`BuildingCount`, `TransportUpkeep`, `PoliceUpkeep`, `FireUpkeep` and 6 more) |
| Writes | `$8F01`-`$8F04` (`AvgCrime`, `AvgLandValue`, `LastBuildings`) |

### `ServiceNeeds` (`$8F31`)

**ServiceNeeds**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 4,224 t-states own (0.00 %) |
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
| Called from | `SimTask` |
| Reads | `$8F71`-`$8F75` (`SpeedTable+5`); `$A3AB` (`Speed`) |
| Writes | `$8F67`-`$8F6B` (`GrowTries`, `IndChance`, `ComChance`, `SpeedSpare` and 1 more) |

## uitask

`src/game/uitask.asm`

### `UiTask` (`$8FA0`)

**The UI task's start: the simulation task made, the status panel, the start menu (A51C), the landscape, the view; then the UI loop**

L1 1 (after the mover).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 93,074,671 t-states own (6.18 %) |
| Called from | `Entry` (tail), `DrawPointer`, `ErasePointer`, `TrackBox`, `InvertBox`, `PrintFunds`, `PrintDate`, `MovePointer`, `DrawView`, `ToolKeys`, `ShowTool`, `DrawMovers`, `Periodic`, `FundsChanged`, `AnimateFlood`, `RunDisaster`, `Interrupt` |
| Calls | `ClearTopBlack`, `DrawPointer`, `ErasePointer`, `TrackBox`, `DrawStatusPanel`, `MovePointer`, `Click`, `DrawViewRowPass`, `DrawView`, `ClearWindowArea`, `DrawMenu`, `RunMenu`, `NewLandscape`, `ToolKeys`, `DrawMovers`, `ShiftScroll`, `MapsWindow`, `StartSimulation`, `Periodic`, `FundsChanged`, `AnimateFire`, `AnimateFlood` |
| Reads | `$5B06` (`KeyRowEnter`); `$8E93` (`BudgetDue`); `$8F9F` (`PassCount`); `$A511` (`MapsDue`) |
| Writes | `$8F9F` (`PassCount`); `$F705` (`SwitchOff`); `$F753` (`PrintAttr`) |

### `Periodic` (`$901D`)

**By PassCount: the advice every 32, the movers every 16, and in the 16-pass cycle Funds, the date, two tile animations, a disaster, the disaster draw**

L1 158 073.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,777 calls, 287,075 t-states own (0.02 %) |
| Called from | `PrintPadded`, `UiTask`, `Interrupt` |
| Calls | `PrintFunds` (tail), `PrintDate` (tail), `UiTask`, `MoveDisasters`, `AnimateFire` (tail), `AnimateFlood` (tail), `RandomDisaster` (tail), `RunDisaster` (tail), `ShowAdvice` |
| Reads | `$8F9F` (`PassCount`) |

### `MoveDisasters` (`$904D`)

**The plane, the tornado, the train**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 112 calls, 4,928 t-states own (0.00 %) |
| Called from | `Periodic` |
| Calls | `MoveTrain` (tail), `MovePlane`, `MoveTornado` |

### `FundsChanged` (`$9058`)

**When Funds changed: redraw the palette and the tool**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1,776 calls, 117,374 t-states own (0.01 %) |
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
| Called from | `UiTask`, `Periodic` (tail) |
| Calls | `Random` |
| Reads | `$8F9F` (`PassCount`); `$ED38`-`$ED47` (`CellTiles+720`) |
| Writes | `$EC90`-`$EC97` (`CellTiles+552`) |

### `AnimateFlood` (`$908A`)

**Tile `$44` (flood, `$EC88`) from `$ED48` or `$ED50`**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 113 calls, 30,179 t-states own (0.00 %) |
| Called from | `UiTask`, `Periodic` (tail), `Interrupt` |
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

### `StartFires` (`$90AF`)

**Every map cell: 1 in 128 Ignite**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |

### `Ignite` (`$90C4`)

**A flammable cell (flags bit 7) but trees: fire `$45`**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 137 calls (`stage1/rec/disasters` 137) |

### `FloodDisaster` (`$90D5`)

**message `$17` (COASTAL FLOODING DETECTED), the noise, the coast floods**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |

### `StartFlood` (`$90DD`)

**Every coast cell (1-5): 1 in 32 flood `$44`; FloodLeft = 50**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/disasters` 2) |

### `FireNoise` (`$9108`)

**127 NoiseBursts, gate falling**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |

### `FloodNoise` (`$9116`)

**127 NoiseBursts, gate rising**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/disasters` 1) |

### `Earthquake` (`$9125`)

**message `$18` (MAJOR EARTHQUAKE DETECTED), a long noise, fires and the flood**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RandomDisaster` (`$9144`)

**Unless disasters are off (`$A43D`): a gate of 1 in 2048 (seed AND `$07FF` = 0), then Random AND 7 picks 1-6 (6 with a further 1 in 8); the gate fixes that draw, so only the seed `$0000` (next `$00FD`, 5) starts a disaster: always the tornado, about 1 in 65 536 a try**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 111 calls, 9,176 t-states own (0.00 %) |
| Called from | `Periodic` (tail) |
| Calls | `Random` |
| Reads | `$5CC4`-`$5CC5` (`RandomSeed`); `$A43D` (`DisastersOff`) |

### `RunDisaster` (`$916E`)

**1 fire, 2 flood, 3 earthquake, 4 air crash, 5 tornado, 6 meltdown**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 111 calls, 3,552 t-states own (0.00 %) |
| Called from | `Periodic` (tail) |
| Calls | `UiTask` |
| Reads | `$916D` (`DisasterDue`) |

## budget

`src/game/budget.asm`

### `BudgetWindow` (`$9194`)

**The year's budget window (the UI task, when BudgetDue): BudgetFigures, the window `$91BC` with the hook `$9346`; then the view**

L1 9.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rec/bankrupt` 5, `stage1/rec/menus` 1, `stage1/rec/city` 0) |

### `TaxIncomeOf` (`$9329`)

**TaxIncome = PopLastYear / 100 x TaxRate**

L1 77.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 77 calls (`stage1/rec/city2` 18, `stage1/rec/metro` 17, `stage1/rec/city` 16 and 6 more) |

### `BudgetHook` (`$9346`)

**The budget window's menu hook: recompute and print the figures while the player edits them**

[Animation: `BudgetHook` at work](img/routines/BudgetHook.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/city`, `stage1/rec/bankrupt`) |

### `BudgetFigures` (`$9358`)

**FundsBefore, the three fundings (request x percent), each capped so the money does not go below 0, the totals**

L1 1918.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |

### `FundTransport` (`$937C`)

**FundTransport**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |

### `FundPolice` (`$9389`)

**FundPolice**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |

### `FundFire` (`$9396`)

**FundFire**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |

### `BudgetTotals` (`$93A3`)

**FundedTotal, CashFlow, FundsAfter = Funds - FundedTotal + TaxIncome**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |

### `CapTransport` (`$93F9`)

**TransportFunded at most FundsBefore + TaxIncome**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |

### `CapPolice` (`$9429`)

**PoliceFunded at most what is left after the transport**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |

### `CapFire` (`$9462`)

**FireFunded at most what is left after both**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,918 calls (`stage1/rec/menus` 1,671, `stage1/rec/city` 119, `stage1/rec/bankrupt` 75 and 6 more) |

### `PrintBudget` (`$94A4`)

**Print the figures into the budget window**

L1 1841.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,841 calls (`stage1/rec/menus` 1,669, `stage1/rec/city` 103, `stage1/rec/bankrupt` 69) |

### `Percent` (`$94FF`)

**HL = HL x A / 100**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,754 calls (`stage1/rec/menus` 5,013, `stage1/rec/city` 357, `stage1/rec/bankrupt` 225 and 6 more) |

### `ApplyFunding` (`$952A`)

**The year's fundings to the city: RoadDecay and RailDecay, PoliceStrength, FireStrength by the share granted**

A request below 20 counts as fully paid. The fire branch tests TransportCost against 20, not FireCost (a slip: with transport costs below 20 the fire is always fully strong, FireStrength = 15 whatever the funding). BUG: with transport at 20 or more and no fire station, FireCost / 8 = 0 and Div16 by zero returns 0, so FireStrength = 0 (city recording, frame 8 500, JAN 1903). L1 74.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 74 calls (`stage1/rec/city2` 18, `stage1/rec/metro` 17, `stage1/rec/city` 15 and 6 more) |

## evaluation

`src/game/evaluation.asm`

### `EvaluationWindow` (`$95B8`)

**The WINDOWS menu's EVALUATION: the window `$95D7` with the hook Evaluate**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/metro`, `stage1/rec/city2`, `stage1/rec/growth` and 2 more) |

### `Evaluate` (`$9737`)

**The evaluation hook: the category, the figures; with a population, the problems, the score and the poll**

L1 18.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/city2`, `stage1/rec/metro`, `stage1/rec/growth` and 2 more) |

### `CategoryOf` (`$9760`)

**Category = how many CategoryLimits PopLastYear exceeds (a limit equal to it does not count)**

Only the evaluation window computes it, from the population at the last year's end: the category changes nothing in the game. L1 18.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |

### `PrintEvalFigures` (`$9792`)

**The level, the category, the population, the migration, the assessed value (CityValueLast) followed by 000 (x 1000: two CALL PrintZero and a fall-through)**

POPULATION is LastPop (last month's), not the year's population.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |

### `PrintZero` (`$97F8`)

**Print "0" and step on**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 54 calls (`stage1/rec/city2` 15, `stage1/rec/metro` 15, `stage1/rec/growth` 12 and 2 more) |

### `Problems` (`$9803`)

**Each problem 0-100 printed (red from 20): traffic AvgTraffic / 2, pollution / 2, crime / 4, fire 5 FireCells, taxes 4 (rate - 3), house prices AvgLandValue, unemployment PopBalance; plus UnpoweredZones / 4 and 4 for an advice**

L1 18.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/metro` 5, `stage1/rec/city2` 5, `stage1/rec/growth` 4 and 2 more) |

### `Clamp100` (`$98E4`)

**HL to 0-100**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 126 calls (`stage1/rec/city2` 35, `stage1/rec/metro` 35, `stage1/rec/growth` 28 and 2 more) |

### `ScoreOf` (`$98FC`)

**CityScore = 4 (250 - 3 ProblemSum), 0-1000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |

### `Clamp1000` (`$9919`)

**Clamp1000**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |

### `Poll` (`$9931`)

**Poll**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rec/city2` 5, `stage1/rec/metro` 5, `stage1/rec/growth` 4 and 2 more) |

### `PrintProblem` (`$9970`)

**HL in 3 digits at BC, attribute `$42` (red) from 20**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 126 calls (`stage1/rec/metro` 35, `stage1/rec/city2` 35, `stage1/rec/growth` 28 and 2 more) |

### `PrintPercent` (`$998B`)

**HL in 3 digits at BC**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 36 calls (`stage1/rec/city2` 10, `stage1/rec/metro` 10, `stage1/rec/growth` 8 and 2 more) |

### `ShowAdvice` (`$9997`)

**Print GameTexts[23 + Advice] at row 6, column 1, padded to 30 columns**

L1 4944.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 56 calls, 4,144 t-states own (0.00 %) |
| Called from | `FindText`, `Periodic` |
| Calls | `FindText`, `PrintPadded` (tail) |
| Reads | `$9996` (`Advice`) |

### `Advise` (`$99AD`)

**The advice: the first rule that fires sets Advice (the later ones may overwrite, CALL NC)**

In order: R at most a quarter of all zones (1), C at most an eighth (2), I (3); then, with people: roads fewer than zones from 10 zones (4), rails from 50 (5), no power station from 10 (6), no stadium from 20 R (7), no seaport from 30 I (8), no airport from 30 C (9), no fire station from 30 zones (10), no police from 25 (11), tax 12+ (12), transport underfunded (13), fire (14), police (15), 10+ unpowered zones (16), a brownout (17), pollution 60+ (19), crime 20+ (20), traffic 60+ (21). L1 1089.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 3,440 t-states own (0.00 %) |
| Called from | `SimTask` |
| Calls | `SetAdvice` (tail) |
| Reads | `$8446`-`$844B` (`ResPop`, `ComPop`, `IndPop`); `$99AB`-`$99AC` (`AllZones`) |
| Writes | `$9996` (`Advice`); `$99AB`-`$99AC` (`AllZones`) |

### `SetAdvice` (`$9B4A`)

**Advice = A (the disasters' messages too)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 16 calls, 368 t-states own (0.00 %) |
| Called from | `Advise` (tail) |
| Writes | `$9996` (`Advice`) |

## overview

`src/game/overview.asm`

### `HighlightMapKey` (`$9B60`)

**Flip the bright bit of the current key's attribute**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 242 t-states own (0.00 %) |
| Called from | `MapsWindow` |
| Calls | `AttrAddr` |
| Reads | `$5883` (screen); `$9B4E`-`$9B4F` (`MapKeyCells`); `$9C2B` (`MapArea`) |
| Writes | `$5883` (screen) |

### `HighlightLayer` (`$9B76`)

**XOR `$46` over the current layer's row of the legend**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 2 calls, 758 t-states own (0.00 %) |
| Called from | `MapsWindow` |
| Calls | `AttrAddr` |
| Reads | `$59E0`-`$59E7` (screen); `$9D43` (`MapLayer`) |
| Writes | `$59E0`-`$59E7` (screen) |

### `MapsKeys` (`$9B8B`)

**Every 4th loop: Q / A change the layer; SYMBOL SHIFT + a digit 1-9 the map area (MapsKeysDigit returns if SYMBOL SHIFT is up)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 100 calls (`stage1/rec/menus` 48, `stage1/rec/city2` 27, `stage1/rec/metro` 25) |

### `OverviewCell` (`$9BC3`)

**Draw one cell as 4 x 4 pixels: every second pixel of every second line of its tile (or the building tile)**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 864 calls, 171,222 t-states own (0.01 %) |
| Called from | `RoadTraffic`, `ShrinkLine`, `DrawOverview` |
| Calls | `RoadTraffic`, `ShrinkLine` (tail) |
| Reads | `$6558` (`BuildingLeft`) |

### `ShrinkLine` (`$9BF9`)

**One tile line pair to 4 pixels: bits 7, 5, 3, 1, into the left or right nibble**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 3,456 calls, 713,430 t-states own (0.05 %) |
| Called from | `OverviewCell` (tail), `Interrupt` |
| Calls | `OverviewCell`, `DrawOverview` |
| Reads | `$4008`-`$481F` (screen); `$4908`-`$491F` (screen); `$4A08`-`$4A1F` (screen); `$4B08`-`$4B1F` (screen); `$4C08`-`$4C1F` (screen); `$4D08`-`$4D1F` (screen); 4 more ranges |
| Writes | `$4008`-`$481F` (screen); `$4908`-`$491F` (screen); `$4A08`-`$4A1F` (screen); `$4B08`-`$4B1F` (screen); `$4C08`-`$4C1F` (screen); `$4D08`-`$4D1F` (screen); 2 more ranges |

### `DrawOverview` (`$9C57`)

**Draw the 48 x 48 cells of MapArea at 4 x 4 pixels, coloured by the layer; stop at a key**

L1 105.

[Animation: `DrawOverview` at work](img/routines/DrawOverview.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 1 call, 242,116 t-states own (0.02 %) |
| Called from | `MapsWindow`, `ShrinkLine`, `PutLayerAttr`, `LayerOf`, `Interrupt` |
| Calls | `AnyKey`, `NextPixelLine`, `MapsWindow`, `OverviewCell`, `PutLayerAttr`, `LayerOf` |
| Reads | `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`); `$9BD7`-`$9BD8` (`OverviewAt+1`); `$9C2B`-`$9C34` (`MapArea`, `OverviewSpare2`, `OverviewOrigin`, `RightNibble` and 2 more); `$9C45`-`$9C46` (`MapAreaCells`); `$C450`-`$C83F` (`CityMap`); `$C870`-`$C89F` (`CityMap+1056`); 6 more ranges |
| Writes | `$6433` (`Blink`); `$6509`-`$650A` (`ViewCellPtr`); `$6558`-`$655A` (`BuildingLeft`, `BuildingTile`); `$9BD7`-`$9BD8` (`OverviewAt+1`); `$9C2E`-`$9C32` (`OverviewOrigin`, `RightNibble`, `OverviewCellAt`) |

### `LayerColour` (`$9D02`)

**The attribute LayerColours[A] (0: none) for the cell**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 21,456 calls (`stage1/rec/menus` 11,088, `stage1/rec/metro` 5,232, `stage1/rec/city2` 5,136) |

### `PutLayerAttr` (`$9D0C`)

**The attribute C at the overview cell's attribute address**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 866 calls, 58,237 t-states own (0.00 %) |
| Called from | `DrawOverview`, `Interrupt` |
| Calls | `DrawOverview` |
| Reads | `$9BD7`-`$9BD8` (`OverviewAt+1`) |
| Writes | `$5808`-`$591F` (screen) |

### `LayerOf` (`$9D44`)

**The overlay of the layer for the overview cell**

L1 32 928.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 864 calls, 277,193 t-states own (0.02 %) |
| Called from | `DrawOverview`, `Interrupt` |
| Calls | `CellFlagsOf`, `DrawOverview` |
| Reads | `$6509`-`$650A` (`ViewCellPtr`); `$753C`-`$753D` (`GridBase`); `$9D43` (`MapLayer`); `$C450`-`$C83F` (`CityMap`); `$C870`-`$C89F` (`CityMap+1056`); `$C8D0`-`$C8FF` (`CityMap+1152`); 5 more ranges |
| Writes | `$753C`-`$753D` (`GridBase`); `$F705` (`SwitchOff`) |

## saveload

`src/game/saveload.asm`

### `SaveCity` (`$9E09`)

**SAVE TO TAPE: the name, START TAPE, then a 31-byte header (flag `$FF`) and the 9216-byte map (flag `$FF`)**

The header SaveHeader: the 12-letter file name, Funds, its spare byte, Month, Year (7 bytes), a spare byte, the city name (12). Nothing else is saved: not the tax, the fundings, the options or the arrays. Known only from the code (stage 1's save recording ran it: L1 at `$9E09` none, as the save was reached through the menu action; see NOTES).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `LoadCity` (`$9E5A`)

**LOAD FROM TAPE: the name, SEARCHING, a 31-byte header (any name if the typed one is blank), then the map; only the first city on the tape loads**

Both blocks of a save carry flag `$FF`, and LoadHeader asks for 31 bytes with flag `$FF`. After a header whose name does not match, the next load meets that file's map block, takes its first 31 bytes as a header, fails the parity (the block is longer) and shows LoadErrorWindow: the search never reaches a second file, so the tape must stand at the wanted city. Known only from the code.

PopLastYear and LastPop are not restored: the previous city's values remain until the next month end.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `LoadHeader` (`$9E89`)

**LoadHeader**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `LoadMap` (`$9ECC`)

**The map; on success Funds, the date and the name from the header**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `PrintFound` (`$9F1A`)

**FOUND :- and the header's name**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/menus` 1) |

### `PrintFileName` (`$9F2A`)

**The 12 letters at SaveName**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

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
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/city`, `stage1/rec/metro`, `stage1/rec/tools`) |

### `Confirm` (`$9FD0`)

**ARE YOU SURE ?: carry set for YES**

L1 5.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/menus` 4, `stage1/rec/levels` 1) |

### `ConfirmNo` (`$A027`)

**OR A**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `ExitSimCity` (`$A0B1`)

**EXIT SIMCITY: confirmed, a new city with a new landscape**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `AboutWindow` (`$A0C7`)

**ABOUT SIM CITY**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `LoadMenu` (`$A1F3`)

**LOADING MENU**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `SaveMenu` (`$A247`)

**SAVING MENU**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `FileNameWindow` (`$A29A`)

**TYPE FILE NAME, THEN PRESS ENTER**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |

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

### `TapeWindow` (`$A309`)

**TapeWindow**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/menus` 1) |

### `SpeedMenu` (`$A3AC`)

**SIMULATION SPEED**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`, `stage1/rec/bankrupt`, `stage1/rec/city` and 3 more) |

### `SetSpeedItem` (`$A40D`)

**Speed = A; the asterisk moved to (HL)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/menus` 5) |

### `PickDisaster` (`$A4BA`)

**DisasterDue = the item + 1**

L1 6.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/disasters`) |

### `MapsItem` (`$A512`)

**MapsItem**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 30 t-states own (0.00 %) |
| Called from | `NumberRepeat` |
| Writes | `$A511` (`MapsDue`) |

### `LevelMenu` (`$A519`)

**SELECT DIFFICULTY LEVEL**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/menus` 3, `stage1/rec/levels` 1) |

### `SetLevel` (`$A5A9`)

**Level = the item**

L1 12.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | run into, not called, 36 t-states own (0.00 %) |
| Called from | `NumberRepeat` |
| Reads | `$6A7D` (`MenuSelected`) |
| Writes | `$A518` (`Level`) |

### `InputGene` (`$A672`)

**INPUT NEW GENE: 5 digits at row 11, column 25**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/menus`) |

### `InputName` (`$A6F9`)

**Edit an 11-letter text at InputAt (InputLength = 11: CityName's twelfth letter cannot be typed) (letters, digits, space; CAPS SHIFT 5 / 8 cursor, 0 blanks the cursor cell and the one before it)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/menus` 2, `stage1/rec/levels` 1) |

### `InputLine` (`$A6FF`)

**The line editor; with InputDigits a number (5 digits, carry when too large)**

L1 5.

[Animation: `InputLine` at work](img/routines/InputLine.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/menus` 4) |

### `InputBlank` (`$A786`)

**A space at the cursor**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CursorLeft` (`$A793`)

**CursorLeft**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShowInput` (`$A7A3`)

**The text at InputAt, the cursor's letter inverse (`$C7`)**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,416 calls (`stage1/rec/menus` 4,570, `stage1/rec/levels` 846) |

### `NumberToInput` (`$A7D4`)

**The 16-bit number at (InputBuffer) as digits into InputText**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |

### `NumberDigits` (`$A7ED`)

**NumberDigits**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |

### `NumberDigit` (`$A81E`)

**NumberDigit**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/menus` 8) |

### `PutDigit` (`$A82A`)

**PutDigit**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`stage1/rec/menus` 10) |

### `DigitValue` (`$A849`)

**A = E - '0', carry when E is not a digit**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 20 calls (`stage1/rec/menus` 20) |

### `InputToNumber` (`$A854`)

**HL = the decimal digits of InputText, carry on overflow**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |

## tasks

`src/game/tasks.asm`

### `Interrupt` (`$F70B`)

**IM 2: save all registers, ReadInput, then (unless SwitchOff) swap the stack with the other task's**

Each interrupt, 50 a second, gives the other task the CPU: the UI and the simulation run turn by turn, one frame each. c1: L1 407 762, 128 197 / 256 388 switches.

[Animation: `Interrupt` at work](img/routines/Interrupt.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 1,822,178 t-states own (0.12 %) |
| Called from | `InterruptJump` (tail) |
| Calls | `ScreenAddr`, `NextPixelLine`, `DrawIcon`, `DrawIconHere`, `ClearTopWhite`, `ClearViewArea`, `DrawPointer`, `ErasePointer`, `TrackBox`, `InvertBox`, `DrawIcon2x2`, `NextColumn`, `PrintDigitOf`, `DrawBoxRow`, `FindText`, `MovePointer`, `DrawCell`, `RoadTraffic`, `PrintNumber24`, `Digit24`, `ToolKeys`, `DrawMovers`, `SimTask`, `UiTask`, `Periodic`, `FundsChanged`, `AnimateFlood`, `ShrinkLine`, `DrawOverview`, `PutLayerAttr`, `LayerOf`, `PrintGlyph`, `ReadInput` |
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
| Called from | `DrawIcon` (tail), `DrawIconHere` (tail), `PrintChar`, `PrintPadded`, `DrawCell` (tail), `PrintNumber24`, `Interrupt` |
| Calls | `DrawIcon2x2`, `DrawToolIcons`, `PrintChar`, `DrawBoxRow`, `PrintPadded`, `DrawView`, `PrintNumber24` |
| Reads | `$F74F`-`$F753` (`PrintAddr`, `PrintCol`, `PrintRow`, `PrintAttr`) |
| Writes | `$4000`-`$54D9` (screen); `$5500`-`$55D9` (screen); `$5600`-`$5681` (screen); `$56A1` (screen); `$56C1`-`$56D9` (screen); `$5700`-`$5781` (screen); 3 more ranges |

### `ReadInput` (`$F781`)

**Read the eight half rows into KeyRows, then the Kempston and Sinclair joysticks into them**

L1 413 183.

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 2,220,200 t-states own (0.15 %) |
| Called from | `Interrupt` |
| Calls | `ReadKempston`, `ReadSinclair` (tail) |
| Writes | `$5B00`-`$5B07` (`KeyRows`, `KeyRowA`, `KeyRowQ`, `KeyRow1` and 4 more) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `TapeLoad` (`$F79F`)

**LD-BYTES through the ROM (border `$0F`): IX, DE, A flag, carry set**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |

### `TapeSave` (`$F7AA`)

**SA-BYTES through the ROM**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/menus` 2) |

### `TapePause` (`$F7AD`)

**B x 5000 loops**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/menus` 1) |

### `InterruptJump` (`$FCFC`)

**JP Interrupt: the IM 2 vector `$FCFC`**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at signal speed, the first play) | 5,224 calls, 52,240 t-states own (0.00 %) |
| Entered by | the interrupt, 5,224 times in 54 routines |
| Calls | `Interrupt` (tail) |
| Reads | `$FDFF`-`$FE00` (`VectorTable+255`) |
| Writes | `$F6AE`-`$F6C1` (`UiStack+44`); `$F6F4`-`$F701` (`SimFrame+6`) |
