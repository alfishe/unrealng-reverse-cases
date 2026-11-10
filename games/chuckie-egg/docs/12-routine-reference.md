# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/game` (the first recording's game window). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the entries they cover. An entry no recording reached says so.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`tables`](11-data-reference.md#tables) | `$8214`-`$84EF` | 0 of 5 |
| [`graphics`](11-data-reference.md#graphics) | `$84F0`-`$911D` | 0 of 6 |
| [`hens`](#hens) | `$911E`-`$9537` | 7 of 10 |
| [`render`](#render) | `$9538`-`$962F` | 3 of 4 |
| [`screens`](11-data-reference.md#screens) | `$9630`-`$9857` | 0 of 6 |
| [`mainloop`](#mainloop) | `$9858`-`$9A4B` | 2 of 3 |
| [`sprite`](#sprite) | `$9A4C`-`$9C3F` | 2 of 3 |
| [`sound`](#sound) | `$9C40`-`$9D07` | 5 of 9 |
| [`harry`](#harry) | `$9D08`-`$A013` | 5 of 10 |
| [`lifts`](#lifts) | `$A014`-`$A0C7` | 4 of 5 |
| [`duck`](#duck) | `$A0C8`-`$A1B7` | 1 of 2 |
| [`timers`](#timers) | `$A1B8`-`$A21B` | 1 of 2 |
| [`jump`](#jump) | `$A21C`-`$A3A6` | 7 of 9 |
| [`score`](#score) | `$A3A7`-`$A40F` | 1 of 2 |
| [`flow`](#flow) | `$A410`-`$A80B` | 9 of 9 |
| [`hiscore`](#hiscore) | `$A80C`-`$A8EB` | 1 of 1 |
| [`effects`](#effects) | `$A8EC`-`$AA48` | 10 of 10 |
| [`keys`](#keys) | `$AA49`-`$AB5F` | 5 of 5 |
| [`menudata`](#menudata) | `$AB60`-`$AE9B` | 5 of 11 |
| [`level`](#level) | `$AE9C`-`$B15E` | 3 of 3 |
| [`leveldata`](#leveldata) | `$B15F`-`$C8AF` | 1 of 14 |
| [`speech`](11-data-reference.md#speech) | `$C8B0`-`$CBE7` | 0 of 3 |

## hens

`src/game/hens.asm`

### `MoveHen` (`$911E`)

**Move the next hen one step**

Returns at once on levels 9-16 (Level 8-15). Otherwise it takes one random bit (RandomPtr steps through the ROM's first 256 bytes: C = 1 when bit 0 of the byte is 0), advances HenTurn (0-4) and takes that hen's record (x, y, state; x = `$FF`: no hen, return). It erases the hen (DrawHen with A = 0, which also tests Harry), then by the state:

7 or 8 (pecking): back to 1 or 2, the peck is erased and the hen drawn standing. 1 or 2 (walking left / right): when x AND 4 is 0 it first tries HenEatGrain, then turns (state 3 - state) when the next step x - 8 / x + 8 leaves the screen or the cell under it (y - 1) is neither a ladder nor a brick; then x moves 4 pixels and the hen is drawn; at a column where x AND 4 is set, and when the random bit allows, it goes onto a ladder: state 3 (down) when the cell 8 below is a ladder's left half, 4 (up) when the cell 16 above is (bit 1 of the random byte picks which it tests first).

3 or 4 (climbing down / up): when y AND 4 is 0 and the next cell is no ladder it turns (7 - state); y moves 4 pixels; at y AND 4 clear (the new y a multiple of 8) and the random bit it steps off onto a brick 8 left (state 1) or 16 right (state 2), the row 8 below.

Inputs: the hen records. Outputs: the record moved; the screen. Side effects: RandomPtr, HenTurn; DrawHen may end the life (it unwinds the stack to the caller of MainLoop). Witness: 38 158 calls in the eight builds (c1 801); turns `$91A1` 979, onto a ladder `$91DB` 324 and `$91EF` 228, off a ladder `$924C` 213 and `$9261` 307, meals `$9281` 82.

[Animation: `MoveHen` at work](img/routines/MoveHen.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 801 calls, 292,489 t-states own (0.12 %) |
| Called from | `MainLoop` |
| Calls | `HenEatGrain`, `DrawHen`, `MapCellPeek`, `PhraseVector` |
| Reads | `$6EEB` (system); `$7356`-`$736D` (system); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$7356`-`$736D` (system); `$FF3A`-`$FF3B` (`work space $FF3A+`) |

### `HenEatGrain` (`$9265`)

**Eat the grain in front of a walking hen**

Input: HL the hen's state byte, E its x, D its y. The cell at (x + 8, y) for state 2 or (x - 8, y) for state 1 (MapCellAt `$9E34`): when it is grain (4) the cell becomes empty, the state becomes 7 or 8 (pecking) and the peck is drawn (8 pixels left for state 7); then it drops its own frame and MoveHen's (three POPs) and returns to MainLoop: the hen does not move this turn. Otherwise it returns with the registers kept.

Witness: 6 746 calls, 82 meals (`$9281`); the grain is gone from LiveMap, so Harry can no longer take it.

Known only from the code: when the peck's DrawHen finds Harry touching the hen, its six POPs are counted for MoveHen's stack, not this one's, so its RET takes the BC pushed at `$9265` (B the state, C the random bit) as the return address. Only a left peck can get here (a right peck is drawn where MoveHen's erase has just tested the same box), so B = 1 and the RET goes to ROM `$0100` or `$0101`. No build reached it. Tried on a clone (work/docs/ceC/heg.py, level 8, a hen at (160, 8) walking left, grain at (19, 1), Harry at (152, 23)): the PC goes to `$0051`, the ROM calculator, the RAM fill `$11DE-$11ED`, and the Spectrum resets to the copyright screen at frame 121; with Harry at 153 the normal kill and the death tune follow.

| | |
| --- | --- |
| Runs (the first recording's game window) | 87 calls, 14,763 t-states own (0.01 %) |
| Called from | `MoveHen` |
| Calls | `DrawHen`, `MapCellAt` |
| Reads | `$7359`-`$735D` (system) |
| Writes | `$63D7` (system); `$7359` (system) |

### `DrawHen` (`$929C`)

**Test a hen against Harry, then draw or erase it**

Inputs: L the hen's x, H its y, A the frame (0: erase). First the box test against Harry: Harry's x within x - 7 .. x + 5 and his y within y + 1 .. y + `$1C`. A touch drops six words from the stack (DrawHen's four, its return and MoveHen's) and returns to the caller of MainLoop: the life ends (`$92BC`: c1 1, idle-1p 5, gameover-name 5, 11 in all).

A > 0: the frame from HenSprites (see there) is ORed onto the screen, 16 lines from (x, y) up (ScreenAddr `$9404`; one byte at x >= `$F9`), and a block of attribute 5 (cyan) of 1-2 columns by 2-3 rows is set (AttrAddrHen `$93DD`). A = 0: the 2 x 3 map cells under the hen (1 x 3 at x >= `$F8`) are drawn again from LiveMap with their glyphs and CellAttributes. IX is HarryX at the end. Measured in levels-1-3 frames 600-900: a hen read blank by the beam in 7 of 44 steps.

Witness: 44 867 calls.

[Animation: `DrawHen` at work](img/routines/DrawHen.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 643 calls, 2,418,055 t-states own (0.95 %) |
| Called from | `MoveHen`, `HenEatGrain` |
| Calls | `AttrAddrHen`, `MapCellAddrKeepA`, `ScreenAddr`, `PhraseVector` |
| Reads | `$40A8`-`$50E0` (screen); `$510A`-`$51E0` (screen); `$520A`-`$52E0` (screen); `$530A`-`$53E0` (screen); `$540A`-`$54E0` (screen); `$550A`-`$55E0` (screen); 15 more ranges |
| Writes | `$4088`-`$51E0` (screen); `$520A`-`$52E0` (screen); `$530A`-`$53E0` (screen); `$540A`-`$54E0` (screen); `$550A`-`$55E0` (screen); `$560A`-`$56E0` (screen); 9 more ranges |

### `AttrAddrHen` (`$93DD`)

**HL = the attribute address of pixel (L, H)**

Input: L = x, H = y. Output: HL = `$5800` + x / 8 + 32 x ((191 - y) / 8). AF and DE kept. Witness: 44 856 calls (DrawHen). The same code is CellAttrAddr `$9584` (into DE) and SpriteAttrAddr `$9BDE`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 642 calls, 111,123 t-states own (0.04 %) |
| Called from | `DrawHen` |
| Calls | `PhraseVector` |
| Reads | `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$FF2A`-`$FF2B` (`work space $FF2A+`) |

### `MapCellAddrKeepA` (`$93FE`)

**HL = the map cell address of (L, H), A kept**

MapCellAt `$9E34` with AF saved: HL = the cell's address in LiveMap. Witness: 22 474 calls (EraseHen).

| | |
| --- | --- |
| Runs (the first recording's game window) | 322 calls, 15,456 t-states own (0.01 %) |
| Called from | `DrawHen` |
| Calls | `MapCellAt` |

### `ScreenAddr` (`$9404`)

**HL = the screen address of pixel (L, H)**

Input: L = x, H = y (0 at the bottom). Output: HL = the display file byte of that pixel row (the third from y / 64, the character row from y AND `$38`, the line from (y AND 7) XOR 7). AF, BC and DE kept. Witness: 44 856 calls (DrawHen).

| | |
| --- | --- |
| Runs (the first recording's game window) | 642 calls, 167,458 t-states own (0.07 %) |
| Called from | `DrawHen` |
| Calls | `PhraseVector` |
| Reads | `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$FF28`-`$FF29` (`work space $FF28+`) |

### `MapCellPeek` (`$9438`)

**A = the map cell at (L, H), HL kept**

MapCellAt `$9E34` with HL saved. Witness: 19 822 calls (MoveHen's floor and ladder tests).

| | |
| --- | --- |
| Runs (the first recording's game window) | 282 calls, 13,555 t-states own (0.01 %) |
| Called from | `MoveHen` |
| Calls | `PhraseVector`, `MapCellAt` |

## render

`src/game/render.asm`

### `PaintCells` (`$9538`)

**Paint the attributes of the 3 x 3 map cells at (L, H)**

Input: L = x, H = y of a sprite. From the cell under (x, y) down, three rows of three cells (two columns at x >= `$F1`, two rows at y < `$11`) get their attribute from CellAttributes (code 9 and up: 6). Only the attributes are painted: DrawSprite `$9A4C` redraws the pixels with the background. Registers kept.

Callers: MainLoop before Harry moves, JumpStep before each step, MoveDuck before the duck moves. Witness: 147 583 calls.

[Animation: `PaintCells` at work](img/routines/PaintCells.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,837 calls, 4,436,128 t-states own (1.75 %) |
| Called from | `MainLoop`, `MoveDuck`, `JumpStep`, `JumpFall` |
| Calls | `CellAttrAddr`, `MapCellAddr`, `PhraseVector` |
| Reads | `$61AF`-`$6240` (system); `$63C9`-`$63CB` (system); `$63E9`-`$63EB` (system); `$6409`-`$640B` (system); `$984F`-`$9854` (`CellAttributes`); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$5881`-`$5883` (screen); `$58A1`-`$58A3` (screen); `$58C1`-`$58C3` (screen); `$5A67`-`$5AFA` (screen); `$FF26`-`$FF33` (`work space $FF26+`) |

### `CellAttrAddr` (`$9584`)

**DE = the attribute address of pixel (L, H)**

As AttrAddrHen `$93DD`, the result in DE. Witness: 147 583 calls (PaintCells).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,837 calls, 502,187 t-states own (0.20 %) |
| Called from | `PaintCells` |
| Calls | `PhraseVector` |
| Reads | `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$FF2C`-`$FF2D` (`work space $FF2C+`) |

### `MapCellAddr` (`$95A6`)

**HL = the LiveMap address of the cell at pixel (L, H)**

Output: HL = LiveMap + x / 8 + 4 x (y AND `$F8`): row y / 8 from the bottom, 32 cells a row. Witness: 147 583 calls (PaintCells).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,837 calls, 470,980 t-states own (0.19 %) |
| Called from | `PaintCells` |
| Calls | `PhraseVector` |
| Reads | `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$FF2A`-`$FF2D` (`work space $FF2A+`) |

## mainloop

`src/game/mainloop.asm`

### `MainLoop` (`$9858`)

**One pass of the game: the jump every pass, the rest every 130th pass**

1. ERR_SP must be 1 (tape block 3): otherwise the game hangs at `$985E`. 2. The pickup sound: every 16 passes, while SoundSweep is not 0, it counts down and every fourth count beeps (H = (SoundSweep AND `$1F`) + 6, two cycles). 3. While JumpState is not 0: a click whose pitch follows HarryY on the pass before the slow tick, JumpStep `$A21C`, and after a vertical step the hens are tested against Harry (HenTouches `$9E66`): a touch returns (the life ends).

4. PassCounter counts 130 passes; then the slow tick: CAPS SHIFT + H holds the game until S, CAPS SHIFT + A aborts to Start `$A410`; the bonus every 50 ticks (CountDown B = 0), the duck every 12 (MoveDuck `$A0C8`), the lifts every 2 (MoveLifts `$A014`; Harry on a lift rises one pixel and dies at y `$A5`), the pickup (TakeEggOrGrain `$99DF`), the time every 10 with a tick (CountDown B = 1), one hen every 3 ticks (2 from level 33; MoveHen `$911E`), PaintCells at Harry.

5. Then Harry: on foot, a jump key starts a jump (JumpState 2, JumpCount `$8C`, JumpDy 1, OnLift 0; the direction from left / right, else straight up); otherwise LeaveLadder `$9F60`, WalkHarry `$9D08` unless climbing, FallOffEdge `$B34C` unless on a lift, and ClimbLadder `$9E98` (also in the air: a jump catches a ladder).

Witness: 14 873 212 passes in the eight builds, 113 934 slow ticks (`$99D9`); 477 jumps started (`$9975`); 920 lift steps with Harry on board (`$991E`). The hold and abort keys (`$98C8-$98E5`): hold-abort, HOLD entered at frame 1100 T 54 699 and left at 1300 T 305, ABORT to Start `$A410` at 1400 T 29 350. Known only from the code: the faster hens (`$9944`).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 52,356,726 t-states own (20.68 %) |
| Called from | `SetupLevel` (tail) |
| Calls | `MoveHen`, `PaintCells`, `TakeEggOrGrain`, `PhraseVector`, `Beep`, `WalkHarry`, `HenTouches`, `ClimbLadder`, `LeaveLadder`, `MoveLifts`, `MoveDuck`, `CountDown`, `JumpStep`, `FallOffEdge` |
| Reads | `$5C3D`-`$5C3E` (system); `$6EEB` (system); `$72D8`-`$72DC` (system); `$7325`-`$7370` (system); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$72DB`-`$72DC` (system); `$7325`-`$732A` (system); `$733C`-`$7355` (system); `$736B`-`$7370` (system); `$FF3C`-`$FF3D` (`work space $FF3C+`) |
| Ports in | `$7FFE`, `$DFFE`, `$F7FE`, `$FEFE` |

### `TakeEggOrGrain` (`$99DF`)

**Take the egg or the grain at Harry's feet**

The cell at (HarryX + 8, HarryY - 8): an egg (3) is emptied and scores 100 x (1 + min(Level / 4, 9)) (AddScore `$A3A7` with B = 10 x that), SoundSweep = `$FF`, EggsLeft - 1; the twelfth egg returns from MainLoop too (two returns: the level is complete). Grain (4) is emptied and scores 50, BonusDelay and TimeDelay become `$FF` (the bonus and the time stop for 255 slow ticks), SoundSweep = `$FF`.

Witness: 114 442 calls; 16 levels completed (`$9A15`), 65 grains (`$9A1A`). The cell is emptied in LiveMap only: the next DrawSprite draws the background without it.

[Animation: `TakeEggOrGrain` at work](img/routines/TakeEggOrGrain.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,401 calls, 246,755 t-states own (0.10 %) |
| Called from | `MainLoop` |
| Calls | `PhraseVector`, `MapCellAt`, `AddScore` |
| Reads | `$72D8`-`$72D9` (system); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$61DD` (system); `$7345`-`$7346` (system); `$7370` (system); `$FF3A`-`$FF3B` (`work space $FF3A+`) |

## sprite

`src/game/sprite.asm`

### `DrawSprite` (`$9A4C`)

**Draw sprite frame A at (L, H) over the map's background**

Inputs: A the frame (Sprites), L = x, H = y. The frame's 16 rows of 2 bytes go to SpriteBuffer as rows of 3, shifted right by x AND 7. CellBuffer gets the glyphs of the 3 x 3 map cells under (x, y) (LiveMap, CharacterSet), 24 lines of 3 bytes; the buffer is ORed with the 16 background lines that match y AND 7, and the 16 rows of 3 bytes are written from (x, y) down the screen. So a sprite erases its old self with the background as it moves one pixel. Then the attribute 6 (yellow) on 3 x 3 cells (2 columns at x >= `$F1`, 2 rows when y is on a cell or below `$11`).

Then the duck test: DuckX within HarryX - 7 .. HarryX + 8 and DuckY within HarryY - 8 .. HarryY + 9 kills: it drops the five saved words and every word on the stack until one is `$A410` or more (the return into PlayLevel, `$A656`) and returns there. Known only from the code: no build was killed by the duck (`$9BC6` never ran). The test runs for every draw, also while the duck is caged on levels 1-8: a Harry at x 0-15 and y 143-160 would touch the caged duck at (8, 152).

Witness: 134 270 calls (WalkHarry, ClimbLadder, JumpStep, MoveDuck, CatchLift); 18 652-18 859 T unshifted, + about 1244 T a pixel of shift (levels-1-3 frames 600-612). Measured in levels-1-3 frames 600-900: Harry never read blank by the beam.

[Animation: `DrawSprite` at work](img/routines/DrawSprite.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,942 calls, 72,384,045 t-states own (28.58 %) |
| Called from | `WalkHarry`, `ClimbLadder`, `MoveDuck`, `DrawHarryFrame` |
| Calls | `SpriteAttrAddr`, `PhraseVector` |
| Reads | `$61AF`-`$6240` (system); `$63C9`-`$63CB` (system); `$63E9`-`$63EB` (system); `$6409`-`$640B` (system); `$72A0`-`$7321` (system); `$7348` (system); 5 more ranges |
| Writes | `$40A1`-`$47A3` (screen); `$5087`-`$51DA` (screen); `$5287`-`$52DA` (screen); `$5387`-`$53DA` (screen); `$5487`-`$55DA` (screen); `$5667`-`$56DA` (screen); 7 more ranges |

### `SpriteAttrAddr` (`$9BDE`)

**HL = the attribute address of pixel (L, H)**

As AttrAddrHen `$93DD`. Witness: 134 267 calls (DrawSprite).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,942 calls, 509,194 t-states own (0.20 %) |
| Called from | `DrawSprite` |
| Calls | `PhraseVector` |
| Reads | `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$FF28`-`$FF29` (`work space $FF28+`) |

## sound

`src/game/sound.asm`

### `PrintChar` (`$9C40`)

**Print character A at row H (from the bottom), column L**

Four NOPs (room for a patch), then: the screen address of character row H (0 = row 23 at the bottom, 23 = the top) and column L, the glyph CharacterSet + 8 x A, eight bytes down the cell. Registers kept. Witness: 33 112 calls (the map, the HUD, the pages, the scrollers).

[Animation: `PrintChar` at work](img/routines/PrintChar.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,684 calls, 1,124,123 t-states own (0.44 %) |
| Called from | `Start`, `TitlePage`, `DrawHiScores`, `SetupLevel` |
| Calls | `PhraseVector` |
| Reads | `$84F0`-`$851F` (`CharacterSet`); `$8548`-`$8597` (`CharacterSet`); `$85C8`-`$85DF` (`CharacterSet`); `$85F0`-`$8627` (`CharacterSet`); `$8650`-`$86BF` (`CharacterSet`); `$86E8`-`$87BF` (`CharacterSet`); 3 more ranges |
| Writes | `$4000`-`$57FF` (screen); `$FF32`-`$FF3D` (`work space $FF32+`) |

### `PhraseVector` (`$9C9C`)

**The IM 2 entry: jump to PhraseInterrupt**

VectorTable `$B200` holds `$9C9C` at every place (I = `$B2`, Start `$A410`), so every interrupt comes here. Witness: 127 166 interrupts in the eight builds.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,104 calls, 31,040 t-states own (0.01 %) |
| Called from | `MoveHen`, `DrawHen`, `AttrAddrHen`, `ScreenAddr`, `MapCellPeek`, `PaintCells`, `CellAttrAddr`, `MapCellAddr`, `MainLoop`, `TakeEggOrGrain`, `DrawSprite`, `SpriteAttrAddr`, `PrintChar`, `Beep`, `WalkHarry`, `MapCellAt`, `ClimbLadder`, `LeaveLadder`, `MoveDuck`, `CountDown`, `JumpStep`, `JumpFall`, `TitlePage`, `Delay`, `ScrollLine`, `ClearScreen`, `DrawHiScores`, `SetupLevel` |
| Calls | `PhraseInterrupt` (tail) |

### `Beep` (`$9CA4`)

**Sound the speaker: L cycles of half period H**

OUT (`$FE`) `$10` (the speaker bit, black border), wait H, OUT 0, wait H, L times. B and L used, A = 0 at the end. Calls: the walk (`$2805` and `$2806` every 4 pixels), the climb (`$1E14`, `$1E15`), the jump click, the time tick (`$0402`), the pickup sweep, the bonus count (`$1E04`). One cycle 26 H + 47 T (high 13 H + 14, low 13 H + 33): 3 500 000 / (26 H + 47) Hz; levels-1-3 edges match to the T-state but for the ULA's wait on OUT (`$FE`). Witness: 127 975 calls.

[Animation: `Beep` at work](img/routines/Beep.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 493 calls, 1,418,685 t-states own (0.56 %) |
| Called from | `MainLoop`, `WalkHarry` |
| Calls | `PhraseVector` |
| Reads | `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$FF38`-`$FF3B` (`work space $FF38+`) |
| Ports out | `$00FE`, `$10FE` |

### `PhraseInterrupt` (`$9CC2`)

**The interrupt: send the phrase's next allophone to port `$9F`**

PhraseTimer `$FF`: nothing to do. Otherwise it counts down; at 0 it takes the next pair at PhrasePtr: the first byte is the new timer (in interrupts; `$FF` ends the phrase), the second goes to port `$9F` (an SP0256-AL2 allophone, sound/Phrases.txt). EI and RETI; no keyboard scan (the ROM's KSTATE stands still under IM 2, which is why EnterHiScore switches to IM 1). Witness: 127 166 calls, one an interrupt.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,104 calls, 298,629 t-states own (0.12 %) |
| Called from | `PhraseVector` (tail) |
| Reads | `$7373`-`$7375` (system); `$C99C`-`$C9AA` (`PhraseTable`); `$CA78`-`$CABC` (`PhraseTable`); `$CAFA`-`$CB12` (`PhraseTable`) |
| Writes | `$7373`-`$7375` (system) |
| Ports out | `$009F`, `$079F`, `$099F`, `$0B9F`, `$0E9F`, `$119F`, `$149F`, `$159F`, `$179F`, `$1A9F`, `$289F`, `$2B9F`, `$2C9F`, `$2E9F`, `$2F9F`, `$379F` |

### `StartPhrase` (`$9CEB`)

**Start phrase A unless one is playing**

Input: A the phrase number 1-33. When PhraseTimer is `$FF`: PhrasePtr = the phrase's address from PhraseTable (PhraseTable - 2 + 2A), PhraseTimer = 1 (the first pair goes at the next interrupt). Otherwise the call is lost. Callers: the title (20), the instructions (24), a player's turn (25 + player), the name entry (7), LevelPhrase, DeathPhrase, LiftPhrase. Witness: 106 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 1,628 t-states own (0.00 %) |
| Called from | `TitlePage`, `LevelPhrase` (tail) |
| Reads | `$7373` (system); `$C8D6`-`$C8D7` (`PhraseTable`); `$C8EE`-`$C8F7` (`PhraseTable`) |
| Writes | `$7373`-`$7375` (system) |

## harry

`src/game/harry.asm`

### `WalkHarry` (`$9D08`)

**Walk Harry left or right one pixel, or stand**

Left key: unless x = 1 or the cells to the left (at his feet and above, LiveMap) are bricks: x - 1, HarryDir 4, a step sound (`$2805`) every 4 pixels. Right key: unless x >= `$EE` or the cells to the right are bricks: x + 1, HarryDir 0, a sound (`$2806`). No key: HarryFrame 3 (the next is 0, standing). Then the frame steps (0-3) and DrawSprite draws him. On a lift: when x leaves LiftX - 9 .. LiftX + 9 he walks off (JumpState 1, JumpDx his direction, JumpCount 4: the drift of FallOffEdge).

Witness: 95 138 calls; left steps `$9D59` 5 749, right `$9D95` 6 073, standing `$9DAB` 83 316. Known only from the code: walking off a lift (`$9DDB` never ran).

[Animation: `WalkHarry` at work](img/routines/WalkHarry.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,252 calls, 1,135,087 t-states own (0.45 %) |
| Called from | `MainLoop` |
| Calls | `DrawSprite`, `PhraseVector`, `Beep` |
| Reads | `$61D0`-`$6202` (system); `$72D8`-`$72DB` (system); `$7332`-`$7335` (system); `$7355` (system); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$72D8`-`$72DB` (system); `$FF3A`-`$FF3B` (`work space $FF3A+`) |
| Ports in | `$DFFE` |

### `MapCellAt` (`$9E34`)

**A = the map cell at pixel (L, H), HL its address**

Output: HL = LiveMap + x / 8 + 4 x (y AND `$F8`), A = the code there (0 empty, 1 and 2 a ladder, 3 an egg, 4 grain, 5 a brick, `$A8-$B5` the cage). BC and DE kept. Witness: 264 678 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 5,252 calls, 968,431 t-states own (0.38 %) |
| Called from | `HenEatGrain`, `MapCellAddrKeepA`, `MapCellPeek`, `TakeEggOrGrain`, `JumpFall`, `FallOffEdge` |
| Calls | `PhraseVector` |
| Reads | `$61B7`-`$6278` (system); `$6291`-`$6298` (system); `$62B2` (system); `$62D1`-`$62D4` (system); `$62F1`-`$62F4` (system); `$6311`-`$63F2` (system); 2 more ranges |
| Writes | `$FF26`-`$FF35` (`work space $FF26+`) |

### `HenTouches` (`$9E66`)

**A = 1 when the hen at (E, D) touches Harry**

The box test of DrawHen `$929C` (Harry's x within x - 7 .. x + 5, y within y + 1 .. y + `$1C`), without the kill: A = 1 touch, 0 none; HL kept. MainLoop calls it for the five hens after each vertical jump step. Witness: 29 382 calls (none in idle-1p, where Harry never jumps).

| | |
| --- | --- |
| Runs (the first recording's game window) | 184 calls, 19,886 t-states own (0.01 %) |
| Called from | `MainLoop` |
| Reads | `$72D8`-`$72D9` (system) |

### `ClimbLadder` (`$9E98`)

**Climb up or down a ladder one pixel**

Only at x AND 7 = 0 (Harry over a column). Up key with a ladder's left half (1) in the cell above his head (y + 1): HarryDir `$0D`, y + 1, a sound (`$1E14`) every 4. Else down key with a ladder below his feet (two rows down, three when y is on a cell): HarryDir `$0D`, y - 1, a sound (`$1E15`). Either way the frame steps and JumpState becomes 0: a jump that meets a ladder with up or down held is caught. Then DrawSprite. Witness: 113 934 calls; up `$9ED7` 3 570, down `$9F11` 1 810.

[Animation: `ClimbLadder` at work](img/routines/ClimbLadder.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,396 calls, 193,734 t-states own (0.08 %) |
| Called from | `MainLoop` |
| Calls | `DrawSprite`, `PhraseVector` |
| Reads | `$61B0`-`$61C0` (system); `$61D1`-`$61DF` (system); `$61F2`-`$61FE` (system); `$6210`-`$6220` (system); `$6232`-`$623E` (system); `$72D8`-`$72DB` (system); 2 more ranges |
| Writes | `$FF3A`-`$FF3B` (`work space $FF3A+`) |
| Ports in | `$FBFE`, `$FDFE` |

### `LeaveLadder` (`$9F60`)

**Step off a ladder onto a floor, left or right**

Only when y + 1 is on a cell boundary. Left key: the cell to the left and the one above it must not be bricks, and the one under them must be a floor (1-8): HarryDir 4. Right key: the same to the right: HarryDir 0. The changed HarryDir lets WalkHarry run on the same tick. Witness: 100 660 calls; left `$9FAF` 4 663, right `$9FDA` 5 530.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,252 calls, 773,165 t-states own (0.31 %) |
| Called from | `MainLoop` |
| Calls | `PhraseVector` |
| Reads | `$61AF`-`$6202` (system); `$72D8`-`$72D9` (system); `$7332`-`$7335` (system); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$72DB` (system); `$FF3A`-`$FF3B` (`work space $FF3A+`) |
| Ports in | `$DFFE` |

## lifts

`src/game/lifts.asm`

### `MoveLifts` (`$A014`)

**Move both lift platforms up one pixel**

Nothing when LiftX is `$FF`. For each platform: DrawLift with 0 (erase) at its address, its row count + 1; at 166 the platform restarts from LiftTable's record (platform 1 takes the address, x and row, then row 3; platform 2 copies 3 bytes, so Lift2Row holds LiftX until LD A,`$03` sets row 3); the address one line up (LineUp `$A0A9`), DrawLift with `$FF`. Witness: 57 158 calls; restarts `$A02E` 164 and `$A05C` 167.

[Animation: `MoveLifts` at work](img/routines/MoveLifts.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,199 calls, 38,870 t-states own (0.02 %) |
| Called from | `MainLoop` |
| Reads | `$7350` (system) |

### `DrawLift` (`$A07B`)

**Draw (C = `$FF`) or erase (C = 0) a platform at screen address HL**

Clears the byte left of HL and the byte right of the platform (unless that is column 0), then four lines of two bytes of C going down the screen (LineDown). HL kept. Witness: 109 600 calls (only in the builds with lifts: levels-1-3, gameover-name, levels-1-9).

[Animation: `DrawLift` at work](img/routines/DrawLift.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LineDown` (`$A096`)

**HL one screen line down**

The display file's line order: H + 1, and across a character row or a third. Witness: 438 400 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LineUp` (`$A0A9`)

**HL one screen line up**

Witness: 54 800 calls (MoveLifts).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## duck

`src/game/duck.asm`

### `MoveDuck` (`$A0C8`)

**Steer the duck toward Harry and move it**

Every 12 slow ticks. DuckDx and DuckDy move one step toward Harry's x and y (each held within -5 .. 5). DrawSprite with frame 12 erases it, PaintCells repaints the cells (measured in levels-1-3 frames 600-900: the caged duck read blank by the beam in 10 of 28 redraws); DuckX + DuckDx bounces at 0 and `$EE`, DuckY + DuckDy at `$14` and `$A6` (the speed becomes 5 or -5). On levels 1-8 (Level < 8) the position is set back to (8, `$98`), the cage. Then DrawSprite draws frame 8 + DuckFrame (Harry right of it or level with it) or 10 + DuckFrame (left), and DuckFrame flips. DrawSprite's duck test applies.

Witness: 9 553 calls; held in the cage `$A175` 9 418, free 135 (levels-1-9, level 9). Known only from the code: the bounces (`$A12F`, `$A140`, `$A157`, `$A161`).

[Animation: `MoveDuck` at work](img/routines/MoveDuck.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 201 calls, 138,158 t-states own (0.05 %) |
| Called from | `MainLoop` |
| Calls | `PaintCells`, `DrawSprite`, `PhraseVector` |
| Reads | `$6EEB` (system); `$72D8`-`$72D9` (system); `$7348`-`$734D` (system); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$7348`-`$734D` (system); `$FF3A`-`$FF3B` (`work space $FF3A+`) |

## timers

`src/game/timers.asm`

### `CountDown` (`$A1B8`)

**Take one from the bonus (B = 0) or the time (B = 1) and print it**

The last of the three digits (BonusDigits + 2 or TimeDigits + 2) goes down by one, borrowing from the digits before. Under 000: the bonus sets BonusRunning to 0 and stops; the time drops MainLoop's return address and returns to its caller (the life ends; LifeLost prints OUT OF TIME, the digits are `$FF` 9 9). Otherwise the three digits are printed with HudCharacters at `$4053` (the bonus) or `$405D` (the time).

Witness: 17 679 calls; 20 under-runs (`$A1CE`): 19 of the bonus (`$A1D2`), one of the time (tour-redefine).

[Animation: `CountDown` at work](img/routines/CountDown.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 260 calls, 394,782 t-states own (0.16 %) |
| Called from | `MainLoop` |
| Calls | `PhraseVector` |
| Reads | `$733F`-`$7344` (system); `$89E0`-`$8A2F` (`HudCharacters`); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$4053`-`$405F` (screen); `$4153`-`$415F` (screen); `$4253`-`$425F` (screen); `$4353`-`$435F` (screen); `$4453`-`$445F` (screen); `$4553`-`$455F` (screen); 4 more ranges |

## jump

`src/game/jump.asm`

### `JumpStep` (`$A21C`)

**One step of the jump or the fall**

On the pass before the slow tick (PassCounter 1): PaintCells, x + JumpDx (bouncing at 0 and `$EE`), CatchLift for both platforms, then JumpDrift. On the other passes: in the air, the vertical step (JumpFall). Witness: 1 760 022 calls (0 in idle-1p).

| | |
| --- | --- |
| Runs (the first recording's game window) | 19,048 calls, 1,009,552 t-states own (0.40 %) |
| Called from | `MainLoop` |
| Calls | `PaintCells`, `PhraseVector`, `CatchLift`, `JumpFall` (tail) |
| Reads | `$72D8`-`$72DC` (system); `$7325`-`$7326` (system); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$72D8` (system); `$FF38`-`$FF39` (`work space $FF38+`) |

### `CatchLift` (`$A256`)

**Land Harry on the lift platform whose row count is at HL**

Nothing without a lift. When HarryX is within LiftX - 9 .. LiftX + 9 and HarryY is within six pixels under the row + 16: OnLift 1, JumpState 0, Harry erased (frame 12), HarryY = row + `$11`, and the rest of JumpStep is dropped (POP); LiftPhrase speaks. Witness: 26 662 calls, 50 landings (`$A278`).

[Animation: `CatchLift` at work](img/routines/CatchLift.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 288 calls, 9,320 t-states own (0.00 %) |
| Called from | `JumpStep` |
| Reads | `$7350` (system) |

### `JumpDrift` (`$A294`)

**JumpState 1: count the drift; at its end the fall starts**

JumpCount - 1; not 0: JumpLand. At 0: JumpState 2, JumpDx 0, JumpCount `$FA`, JumpDy `$FF`, and Harry is drawn. JumpState 2 goes on to JumpFall. Witness: the fall starts `$A2A2` 63 times.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JumpFall` (`$A2B5`)

**The vertical step of a jump or a fall**

JumpDelay counts passes. Rising (JumpDy 1): JumpCount + 10 each step, from `$8C`; after 12 steps (it wraps to 4) the top: JumpDy 0; at y `$A7` and over the jump turns down. At the top the next step starts the fall: JumpDy `$FF`, delay 250, then 10 less a step, down to 40 (the fall speeds up). y + JumpDy; under y `$10` the life ends (two POPs: back from MainLoop; fall-death, `$A309` 1). Then JumpLand.

Witness: the top `$A2F6` 243, the fall starts `$A2CC` 279.

[Animation: `JumpFall` at work](img/routines/JumpFall.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 19,048 calls, 687,271 t-states own (0.27 %) |
| Called from | `JumpStep` (tail) |
| Calls | `PaintCells`, `PhraseVector`, `MapCellAt`, `DrawHarryFrame` |
| Reads | `$61B0`-`$61BD` (system); `$61D0`-`$61FF` (system); `$72D8`-`$72DB` (system); `$7326`-`$732A` (system); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$72D9` (system); `$7325`-`$732A` (system); `$FF38`-`$FF39` (`work space $FF38+`) |

### `JumpLand` (`$A30F`)

**Draw Harry in the air; bounce off walls; land on a floor**

Draws frame 1 of his direction (DrawHarryFrame). The cell under his feet (MapCellAt - `$3F`): not rising and moving sideways, a brick beside him reverses JumpDx (101 bounces, `$A34E`). A brick, or a ladder with a brick beside it, under his feet, with y + 1 on a cell boundary: JumpState 0 (landed; a climbing frame becomes 0). Witness: 813 landings (`$A36A`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawHarryFrame` (`$A37F`)

**DrawSprite frame A + HarryDir at Harry**

Witness: 10 532 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 92 calls, 6,083 t-states own (0.00 %) |
| Called from | `JumpFall` |
| Calls | `DrawSprite` |
| Reads | `$72D8`-`$72DB` (system) |

### `LiftPhrase` (`$A389`)

**Speak one of the eight LiftPhrases (R AND 7)**

Witness: 50 calls (the lift landings).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## score

`src/game/score.asm`

### `AddScore` (`$A3A7`)

**Add B x 10 points; an extra life every 10 000; print the score**

Input: B the tens to add (0: only print). The tens digit (Score + 4) goes up B times with the carry through the digits before. When the 10 000s digit (Score + 1) differs from LastTenThousands: the player's lives + 1, and with fewer than six an icon `$B6` at row 22, column 4 + lives + 7 x (player - 1). Then the six digits are printed at ScoreScreenAddr with CharacterSet's digits (from `$8670`).

Witness: 5 659 calls; the 10 000s digit changed 6 times (`$A3C4`), one icon drawn (`$A3D7`; levels-1-9, level 4: lives 5 to 6, as the stage 1 notes saw). Known only from the code: no limit; past 999 990 the carry leaves Score and increments `$6EC7`, the last byte of LiveMap slot 4.

[Animation: `AddScore` at work](img/routines/AddScore.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 5,444 t-states own (0.00 %) |
| Called from | `TakeEggOrGrain`, `SetupLevel` |
| Reads | `$6EC8`-`$6ECD` (system); `$733D`-`$733E` (system); `$736E` (system); `$8670`-`$8677` (`CharacterSet`); `$8698`-`$869F` (`CharacterSet`) |
| Writes | `$4005`-`$400A` (screen); `$4105`-`$410A` (screen); `$4205`-`$420A` (screen); `$4305`-`$430A` (screen); `$4405`-`$440A` (screen); `$4505`-`$450A` (screen); 3 more ranges |

## flow

`src/game/flow.asm`

### `Start` (`$A410`)

**The entry: key type 1, IM 2, the title page**

Entered by the loader's JP `$A410` (c1 frame 5292) and by the abort key. KeyType 6, TitleTuneDone 0, I = `$B2` (VectorTable), IM 2. Witness: c1 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 18,473 t-states own (0.01 %) |
| Calls | `PrintChar`, `FillAttrBlock`, `PlayTune`, `ClearScreen`, `DrawHiScores` |
| Reads | `$736F` (system); `$9630`-`$9763` (`TitleText`) |
| Writes | `$732D` (system); `$736F` (system) |

### `TitlePage` (`$A420`)

**Draw the title page and the high scores**

ClearScreen, TitleText at rows 2-23 columns 0-13, DrawHiScores, the colours of the left half (magenta, yellow, green bands), the title tune and phrase 20 the first time only (TitleTuneDone), row 23 cyan, TextIndex at the end of the text. Then TitleLoop. Witness: 4 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 14,152,615 t-states own (5.59 %) |
| Calls | `PrintChar`, `PhraseVector`, `StartPhrase`, `LifeLost` (tail), `Delay`, `BoxWipe`, `WaitPhrase`, `FillAttrBlock`, `ScrollLine`, `ClearScreen`, `SetupLevel` |
| Reads | `$6EC8`-`$6ECD` (system); `$6EE6` (system); `$732B`-`$733B` (system); `$7373` (system); `$8390`-`$84EF` (`InstructionsText`); `$AC7C`-`$AC9E` (`MenuTexts`); 4 more ranges |
| Writes | `$4000`-`$57FF` (screen); `$5940`-`$595F` (screen); `$59C0`-`$59DF` (screen); `$5AE0`-`$5AFF` (screen); `$61A8`-`$6EF3` (system); `$732B`-`$733B` (system); 3 more ranges |
| Ports in | `$DFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### `TitleLoop` (`$A47D`)

**Scroll the title text; S starts, R redefines, I shows the instructions**

ScrollLine at the bottom row, Delay 500; every 8 shifts the next of TitleScroller's 78 characters enters at column 30. Keys: S StartGame, R RedefineKeys, I InstructionsPage. Witness: every build starts here.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `InstructionsPage` (`$A4C8`)

**Draw the instructions page, scroll its text, take the key type**

ClearScreen; InstructionsText's 11 rows at rows 3, 5 .. 23; the colour bands; TextIndex at the end, KeyType 10 (no type shown, so the first key 1-3 marks one); WaitPhrase and phrase 24. The loop scrolls InstructionsScroller (87 characters); S (once the phrase ends) StartGame, R RedefineKeys; keys 1, 2, 3 set KeyType and move the flashing bar to the type's row (`$5940`, `$5980`, `$59C0`). A KeyType of 10 left as it is plays as type 1 (SetupLevel takes `$8250` for anything but 5 and 3).

Witness: c1, idle-1p, tour-type2 (key 2, `$A56D`), tour-redefine.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StartGame` (`$A59D`)

**Take the number of players and set up the game**

BoxWipe in colours, the screen cleared, BoxWipe in black; the players prompt scrolls in and keys 1-4 set Players (Player 1). Five copies of level 1's map into LiveMap; the scores 0, levels 0, eggs 12, lives 5; LevelDigits "01" (`$9F9E`: the HUD codes of 0 and 1); WaitPhrase. Then PlayerTurn. Witness: 7 games in the eight builds.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlayerTurn` (`$A62C`)

**Announce the player (two players or more) and play**

With more than one player: phrase 25 + player, "PLAYER n" scrolled in (Message), Delay 65536. Then PlayLevel. The LD BC,`$AD49` at `$A63A` is overwritten at once (C = 8): a leftover. Witness: 14 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlayLevel` (`$A653`)

**Play a level: SetupLevel and MainLoop; then the level end or the life lost**

CALL SetupLevel (which jumps to MainLoop); MainLoop returns here at `$A656`. WaitPhrase, the score into the player's slot, IM 2 (again after a name entry). Eggs left: LifeLost. Else the bonus is counted into the score (CountDown, then AddScore 10, a beep, on every step: the step that takes the bonus past 000 still adds 10, so a bonus of N is paid as N + 10), a pause, BoxZoom; the level + 1, "LEVEL nn" (the number is level + 1 mod 100), the next map (LevelMaps + 672 x (Level AND 7)) into the map in play, 12 eggs, and the next level.

Witness: 5 375 bonus steps (`$A675`); 16 levels completed.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LifeLost` (`$A6FE`)

**A life lost: the tune, the next player with lives, or the game over**

DeathTune, DeathPhrase, WaitPhrase, a pause, ClearScreen; OUT OF TIME when the time digits are `$FF` 9 9; the map in play into the player's slot, the eggs and the level into his; lives - 1; at 0 "GAME OVER" (with "PLAYER n" when more play). Then the next player with lives (in turn) is loaded (level, eggs, score, map) and PlayerTurn; none left: GameOver.

Witness: 14 lives lost (`$A6FE`), out of time 1 (`$A725`, tour-redefine), game over 2 (`$A7BC`: idle-1p, gameover-name).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 27 t-states own (0.00 %) |
| Called from | `TitlePage` (tail) |
| Calls | `PlayTune` |

### `GameOver` (`$A7BC`)

**The end of the game: each player's score against the table**

BoxWipe, the pixels cleared, BoxWipe; the 24 score digits become ASCII; for each player his digit at `$AD72` (Congratulations) and EnterHiScore; BoxZoom after an entry. Then TitlePage. Witness: 2 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## hiscore

`src/game/hiscore.asm`

### `EnterHiScore` (`$A80C`)

**Put the score at HL in the table and take a name**

Compares the score with the ten entries (CompareScore); not greater than any: D = 1, return. Else the entries below shift down, the name is cleared, the six digits copied; the Congratulations page (11 rows of 15, rows 23, 21 .. 3), DrawHiScores, colours, phrase 7. Then IM 1: the cursor `$B7` at the entry's row (2 x rank + 1), column 16; HALT until KSTATE4 shows a new key; LAST_K ENTER ends, DELETE (12) erases back, codes `$20` and up are stored and printed, nine at most. IM 2, D = 2.

Witness: gameover-name (one entry, three characters `$A8D5`, ENTER `$A8E4`); 2 calls. DELETE (`$A8C3`): name-delete, CAPS SHIFT + 0 at frame 63 T 3322.

[Animation: `EnterHiScore` at work](img/routines/EnterHiScore.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

## effects

`src/game/effects.asm`

### `DrawBox` (`$A8EC`)

**An attribute rectangle of colour TextIndex**

Inputs: H, L a corner (row from the bottom, column), D the height, E the width. The four sides between (H, L) and (H - D, L + E) (AttrAddr `$AA23`). Registers kept. Witness: 1 056 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 24 calls, 46,788 t-states own (0.02 %) |
| Called from | `BoxWipe` |
| Calls | `AttrAddr` |
| Reads | `$732C` (system) |
| Writes | `$5800`-`$5AFF` (screen) |

### `Delay` (`$A921`)

**Count BC down**

Witness: 39 283 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,123 calls, 17,441,119 t-states own (6.89 %) |
| Called from | `TitlePage`, `BoxWipe` |
| Calls | `PhraseVector` |
| Reads | `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$FF36`-`$FF3B` (`work space $FF36+`) |

### `BoxWipe` (`$A929`)

**Twelve nested boxes from the edge in; IXh 2 in colours, 1 in black**

Colours from `$12` stepping by 9 (IXh 2), or 3 throughout (IXh 1); Delay 5000 between boxes. Witness: 20 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 3,837 t-states own (0.00 %) |
| Called from | `TitlePage` |
| Calls | `DrawBox`, `Delay` |
| Writes | `$732C` (system) |

### `WaitPhrase` (`$A960`)

**Wait until no phrase plays**

Witness: 1 662 374 loops.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 113 t-states own (0.00 %) |
| Called from | `TitlePage` |
| Reads | `$7373` (system) |

### `BoxZoom` (`$A968`)

**Boxes growing from the middle in four quadrants, twice**

The first round in colours (from 9, + 9 a box), the pixels cleared, the second in green (4). Delay 10000 a step. Witness: 17 calls (the level ends, a name entered).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Message` (`$A9CE`)

**Scroll C characters from DE across row 11, then out**

Rows 11-14 green; ScrollLine at row 11 with the next character printed at column 30 every 8 shifts, then 256 shifts more. Witness: 22 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoxZoomBox` (`$A9FA`)

**DrawBox, the colour + 9 first in the colour round**

Witness: 204 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CompareScore` (`$AA0C`)

**A = 1 when the score at HL is greater than the one at DE**

Six digits, the most significant first. Witness: 11 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AttrAddr` (`$AA23`)

**HL = the attribute address of row H (from the bottom), column L**

HL = `$5B00` - 32 x (H + 1) + L. Witness: 2 112 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 48 calls, 25,128 t-states own (0.01 %) |
| Called from | `DrawBox` |

### `FillAttrBlock` (`$AA37`)

**C rows of B attributes A from HL**

Witness: 24 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 7 calls, 32,943 t-states own (0.01 %) |
| Called from | `Start`, `TitlePage` |
| Writes | `$5800`-`$5AFF` (screen) |

## keys

`src/game/keys.asm`

### `RedefineKeys` (`$AA49`)

**Take five new keys into key set 3**

ClearScreen, KeyType 3, ten bytes of KeySet3 cleared (the second jump key stays), the prompt and the five labels (MenuTexts), row 6 green; waits for no key; RedefineOne for up, down, left, right and jump (the attribute bar at `$592A` + 64 k, the name into InstructionsText's row 3, printed at row 14 - 2k column 22). Then the title scroller (JP TitleScrollerStart) over this page. Witness: tour-redefine 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `KeyUsed` (`$AABA`)

**B = 1 when the key just stored is already in key set 3**

Finds the set's last stored pair (the first zero after it) and compares it with the pairs before. B ends as the new pair's number (1-5) plus 1, so the walk back also compares the two pairs just before KeySet3: KeySet2's jump keys 4 (17 F7) and 9 (1D EF), which can never be chosen. KeySet3's sixth pair (the second jump key, 1) is never compared. Witness: 5 calls; redefine-odd, 9 refused at frame 112.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DeathPhrase` (`$AAE4`)

**Speak one of the eight DeathPhrases (R AND 7)**

Witness: 13 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadAnyKey` (`$AAF4`)

**The one key held: L its row bits, H its port row, E the row number; HL = 0 for none or two rows**

Scans the eight rows `$FEFE` .. `$7FFE`. Witness: 24 310 calls.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RedefineOne` (`$AB19`)

**Take one key into (IX), name it into (BC), print it at DE**

The bar (13 bytes of attribute 3 at HL), a key (ReadAnyKey) stored as (mask, port row); the name from KeyNames (row E, the bit of the key); a key already used is taken again; the name printed; waits for the release. Witness: 5 calls.

[Animation: `RedefineOne` at work](img/routines/RedefineOne.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

## menudata

`src/game/menudata.asm`

### `PlayTune` (`$AB60`)

**Play the tune at HL through the ROM's BEEP**

Each note: C the duration in tenths of a second (0 ends), B the pitch in semitones; STACK-A C, the calculator divides it by 10 (TuneCalc), STACK-A B, BEEP. Interrupts are off while BEEP runs. Witness: 393 notes (TitleTune in c1 and after a game, DeathTune at a life lost).

| | |
| --- | --- |
| Runs (the first recording's game window) | 68 calls, 6,008 t-states own (0.00 %) |
| Called from | `Start`, `LifeLost`, `PlayTuneNote` (tail) |
| Reads | `$AE0C`-`$AE93` (`TitleTune`, `DeathTune`) |

### `PlayTuneNote` (`$AB70`)

**The pitch, BEEP, the next note**

Witness: 379 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 4,668 t-states own (0.00 %) |
| Calls | `PlayTune` (tail) |

### `ScrollLine` (`$AB7B`)

**Shift a character row of 30 bytes from HL one pixel left**

Eight lines, each byte takes bit 7 of the next. Registers kept. Witness: 49 502 calls (the scrollers and the messages).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,571 calls, 29,051,944 t-states own (11.47 %) |
| Called from | `TitlePage` |
| Calls | `PhraseVector` |
| Reads | `$4861`-`$4F7F` (screen); `$50E1`-`$57FF` (screen); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$4861`-`$4F7E` (screen); `$50E1`-`$57FE` (screen); `$FF36`-`$FF37` (`work space $FF36+`) |

### `ClearScreen` (`$AB9E`)

**Clear the 6912 bytes of the screen**

Witness: 20 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 604,987 t-states own (0.24 %) |
| Called from | `Start`, `TitlePage` |
| Calls | `PhraseVector` |
| Reads | `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$4000`-`$5AFF` (screen); `$FF3C`-`$FF3D` (`work space $FF3C+`) |

### `DrawHiScores` (`$ABAD`)

**Print the high score table on the right half**

MenuTexts' title at row 23 column 16, the ten entries at rows 21, 19 .. 3, attribute `$17` on columns 16-31 of rows 0-20. Witness: 4 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 19,114 t-states own (0.01 %) |
| Called from | `Start` |
| Calls | `PrintChar`, `PhraseVector` |
| Reads | `$97AF`-`$984E` (`HiScoreTable`); `$ABF2`-`$AC01` (`MenuTexts`); `$B2FF`-`$B300` (`VectorTable`) |
| Writes | `$5810`-`$59BF` (screen); `$59D0`-`$59DF` (screen); `$59F0`-`$59FF` (screen); `$5A10`-`$5A1F` (screen); `$5A30`-`$5A3F` (screen); `$5A50`-`$5A5F` (screen); 3 more ranges |

## level

`src/game/level.asm`

### `SetupLevel` (`$AE9C`)

**Draw the level, set it up and enter MainLoop**

ClearScreen; the 21 rows of the map in play (LiveMap) at rows 0-20; the HUD digits into HudText: the level (Level + 1 in BCD), the bonus's thousands min(Level + 1, 9), the time's hundreds 9 - min(Level / 16, 5), the player; HudText printed; every player's score printed (AddScore B = 0 with ScoreScreenAddr per player), then the score in play reloaded; LastTenThousands. The hens: Hens set to `$FF`, then the HenTable row (none on Level 8-15, all 20 bytes from 24). HenDelay 1 and the low byte of RandomPtr 0 (one word store at `$AFB0`). The life icons (six at most) per player.

The colours: the HUD rows, the player's column white on red (`$17`, others `$0F`); the map's cells (CellAttributes). Harry at (`$64`, `$17`), the duck at (8, `$98`), the jump, the duck's speeds, the counters; BonusRunning, BonusDelay, TimeDelay, DuckDelay and PassCounter 1. KeyTable from the key set of KeyType; ScoreScreenAddr; LiftTable's record for the level into the first and into Lift1, Lift2 one third higher, Lift2Row `$43`. LevelPhrase, a pause, the icon of the life in play erased, JP MainLoop.

Witness: 35 calls.

[Animation: `SetupLevel` at work](img/routines/SetupLevel.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 8,223,603 t-states own (3.25 %) |
| Called from | `TitlePage` |
| Calls | `MainLoop` (tail), `PrintChar`, `PhraseVector`, `AddScore`, `FillAttrRow`, `LevelPhrase` |
| Reads | `$61A8`-`$6447` (system); `$6EC9`-`$6ED3` (system); `$6EEB`-`$6EF0` (system); `$732D`-`$734F` (system); `$8268`-`$8273` (`KeySets`); `$9470`-`$9478` (`HenTable`); 3 more ranges |
| Writes | `$4000`-`$5AFF` (screen); `$6EC8`-`$6ECD` (system); `$72D8`-`$72DC` (system); `$7325`-`$7370` (system); `$976B`-`$978A` (`HudText`, `LiftTable`); `$FF38`-`$FF3D` (`work space $FF38+`) |

### `FillAttrRow` (`$B130`)

**B attributes A on row H (0-2 from the top), from column L**

Witness: 252 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 7 calls, 2,707 t-states own (0.00 %) |
| Called from | `SetupLevel` |
| Writes | `$5800`-`$580A` (screen); `$5820`-`$585F` (screen) |

### `LevelPhrase` (`$B14F`)

**Speak one of the eight LevelPhrases (R AND 7)**

Witness: 35 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 84 t-states own (0.00 %) |
| Called from | `SetupLevel` |
| Calls | `StartPhrase` (tail) |
| Reads | `$B160` (`LevelPhrases`) |

## leveldata

`src/game/leveldata.asm`

### `FallOffEdge` (`$B34C`)

**Start a fall when Harry walks off a platform's edge**

Only when x AND 7 is not 0. The cell under his feet (MapCellAt - `$3F`): a brick or more, or a ladder, keeps him. Else (empty, an egg, grain) JumpState 1, JumpDx his direction, JumpCount 4: he drifts four slow ticks, then falls (JumpStep `$A21C`). MainLoop calls it on foot when not on a lift (`$99D6`).

Witness: 98 837 calls, 63 falls (`$B368`). This routine lies inside the leftover text: the code runs at `$911E-$B15E` and `$B34C-$B380`.

[Animation: `FallOffEdge` at work](img/routines/FallOffEdge.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,252 calls, 242,949 t-states own (0.10 %) |
| Called from | `MainLoop` |
| Calls | `MapCellAt` |
| Reads | `$61B0`-`$61C1` (system); `$72D8`-`$72D9` (system) |
