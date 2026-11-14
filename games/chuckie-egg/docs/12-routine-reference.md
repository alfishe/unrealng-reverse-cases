# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/game` (the first recording's game window), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
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

Inputs: the hen records. Outputs: the record moved; the screen. Side effects: RandomPtr, HenTurn; DrawHen may end the life (it unwinds the stack to `$A656`, the return of PlayLevel's CALL SetupLevel; SetupLevel enters MainLoop by JP `$B12D`). Witness: 38 158 calls in the eight builds (c1 801); turns `$91A1` 979, onto a ladder `$91DB` 324 and `$91EF` 228, off a ladder `$924C` 213 and `$9261` 307, meals `$9281` 82.

[Animation: `MoveHen` at work](img/routines/MoveHen.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 801 calls, 292,489 t-states own (0.12 %) |
| Runs (the other recordings) | 37,357 calls (`stage1/rec/gameover-name` 14,565, `stage1/rec/levels-1-9` 7,426, `stage1/rec/idle-1p` 5,204 and 4 more) |
| Called from | `MainLoop` |
| Calls | `HenEatGrain`, `DrawHen`, `MapCellPeek` |
| Reads | `$6EEB` (`Level`); `$7356`-`$736D` (`HenTurn`, `Hens`, `HenDelay`, `RandomPtr`) |
| Writes | `$7356`-`$736D` (`HenTurn`, `Hens`, `HenDelay`, `RandomPtr`) |

### `HenEatGrain` (`$9265`)

**Eat the grain in front of a walking hen**

Input: HL the hen's state byte, E its x, D its y. The cell at (x + 8, y) for state 2 or (x - 8, y) for state 1 (MapCellAt `$9E34`): when it is grain (4) the cell becomes empty, the state becomes 7 or 8 (pecking) and the peck is drawn (8 pixels left for state 7); then it drops its own frame and MoveHen's (three POPs) and returns to MainLoop: the hen does not move this turn. Otherwise it returns with the registers kept.

Witness: 6 746 calls, 82 meals (`$9281`); the grain is gone from LiveMap, so Harry can no longer take it.

Known only from the code: when the peck's DrawHen finds Harry touching the hen, its six POPs are counted for MoveHen's stack, not this one's, so its RET takes the BC pushed at `$9265` (B the state, C the random bit) as the return address. Only a left peck can get here (a right peck is drawn where MoveHen's erase has just tested the same box), so B = 1 and the RET goes to ROM `$0100` or `$0101`. No build reached it. Tried on a clone (work/docs/ceC/heg.py, level 8, a hen at (160, 8) walking left, grain at (19, 1), Harry at (152, 23)): the PC goes to `$0051`, the ROM calculator, the RAM fill `$11DE-$11ED`, and the Spectrum resets to the copyright screen at frame 121; with Harry at 153 the normal kill and the death tune follow.

| | |
| --- | --- |
| Runs (the first recording's game window) | 87 calls, 14,763 t-states own (0.01 %) |
| Runs (the other recordings) | 6,659 calls (`stage1/rec/gameover-name` 3,357, `stage1/rec/levels-1-9` 1,307, `stage1/rec/idle-1p` 676 and 4 more) |
| Called from | `MoveHen` |
| Calls | `DrawHen`, `MapCellAt` |
| Reads | `$7359`-`$7365` (`Hens+2`) |
| Writes | `$61C9`-`$61E6` (`LiveMap+33`); `$6249`-`$625F` (`LiveMap+161`); `$62D0`-`$62DF` (`LiveMap+296`); `$6349`-`$634C` (`LiveMap+417`); `$63B3` (`LiveMap+523`); `$63CE`-`$63DB` (`LiveMap+550`); 1 more ranges |

### `DrawHen` (`$929C`)

**Test a hen against Harry, then draw or erase it**

Inputs: L the hen's x, H its y, A the frame (0: erase). First the box test against Harry: Harry's x within x - 7 .. x + 5 and his y within y + 1 .. y + `$1C`. A touch drops six words from the stack (DrawHen's four, its return and MoveHen's) and returns to `$A656` in PlayLevel: the life ends (`$92BC`: c1 1, idle-1p 5, gameover-name 5, 11 in all).

A > 0: the frame from HenSprites (see there) is ORed onto the screen, 16 lines from (x, y) up (ScreenAddr `$9404`; at x >= `$F9` the DEC C at `$9309` skips both bytes and only the attributes are set, never reached: a hen turns at `$F8`), and a block of attribute 5 (cyan) of 1-2 columns by 2-3 rows is set (AttrAddrHen `$93DD`). A = 0: the 2 x 3 map cells under the hen (1 x 3 at x >= `$F8`) are drawn again from LiveMap with their glyphs and CellAttributes. IX is HarryX at the end. Measured in levels-1-3 frames 600-900: a hen read blank by the beam in 7 of 44 steps.

Witness: 44 867 calls.

[Animation: `DrawHen` at work](img/routines/DrawHen.gif)

[Animation: `DrawHen` at work, kill](img/routines/DrawHen-kill.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 643 calls, 2,418,055 t-states own (0.95 %) |
| Runs (the other recordings) | 44,224 calls (`stage1/rec/gameover-name` 22,271, `stage1/rec/levels-1-9` 8,902, `stage1/rec/idle-1p` 4,173 and 4 more) |
| Called from | `MoveHen`, `HenEatGrain` |
| Calls | `AttrAddrHen`, `MapCellAddrKeepA`, `ScreenAddr` |
| Reads | `$409B`-`$51E0` (screen); `$5201`-`$52E0` (screen); `$5301`-`$53E0` (screen); `$5401`-`$54E0` (screen); `$5501`-`$55E0` (screen); `$5601`-`$56E0` (screen); 7 more ranges |
| Writes | `$407B`-`$52E0` (screen); `$5300`-`$53E0` (screen); `$5400`-`$54E0` (screen); `$5500`-`$55E0` (screen); `$5600`-`$56E0` (screen); `$5700`-`$57E0` (screen); 1 more ranges |

### `AttrAddrHen` (`$93DD`)

**HL = the attribute address of pixel (L, H)**

Input: L = x, H = y. Output: HL = `$5800` + x / 8 + 32 x ((191 - y) / 8). AF and DE kept. Witness: 44 856 calls (DrawHen). The same code is CellAttrAddr `$9584` (into DE) and SpriteAttrAddr `$9BDE`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 642 calls, 111,123 t-states own (0.04 %) |
| Runs (the other recordings) | 44,214 calls (`stage1/rec/gameover-name` 22,266, `stage1/rec/levels-1-9` 8,902, `stage1/rec/idle-1p` 4,168 and 4 more) |
| Called from | `DrawHen` |

### `MapCellAddrKeepA` (`$93FE`)

**HL = the map cell address of (L, H), A kept**

MapCellAt `$9E34` with AF saved: HL = the cell's address in LiveMap. Witness: 22 474 calls (EraseHen).

| | |
| --- | --- |
| Runs (the first recording's game window) | 322 calls, 15,456 t-states own (0.01 %) |
| Runs (the other recordings) | 22,152 calls (`stage1/rec/gameover-name` 11,140, `stage1/rec/levels-1-9` 4,473, `stage1/rec/idle-1p` 2,089 and 4 more) |
| Called from | `DrawHen` |
| Calls | `MapCellAt` |

### `ScreenAddr` (`$9404`)

**HL = the screen address of pixel (L, H)**

Input: L = x, H = y (0 at the bottom). Output: HL = the display file byte of that pixel row (the third from y / 64, the character row from y AND `$38`, the line from (y AND 7) XOR 7). AF, BC and DE kept. Witness: 44 856 calls (DrawHen).

| | |
| --- | --- |
| Runs (the first recording's game window) | 642 calls, 167,458 t-states own (0.07 %) |
| Runs (the other recordings) | 44,214 calls (`stage1/rec/gameover-name` 22,266, `stage1/rec/levels-1-9` 8,902, `stage1/rec/idle-1p` 4,168 and 4 more) |
| Called from | `DrawHen` |

### `MapCellPeek` (`$9438`)

**A = the map cell at (L, H), HL kept**

MapCellAt `$9E34` with HL saved. Witness: 19 822 calls (MoveHen's floor and ladder tests).

| | |
| --- | --- |
| Runs (the first recording's game window) | 282 calls, 13,555 t-states own (0.01 %) |
| Runs (the other recordings) | 19,540 calls (`stage1/rec/gameover-name` 9,890, `stage1/rec/levels-1-9` 3,858, `stage1/rec/idle-1p` 1,836 and 4 more) |
| Called from | `MoveHen` |
| Calls | `MapCellAt` |

## render

`src/game/render.asm`

### `PaintCells` (`$9538`)

**Paint the attributes of the 3 x 3 map cells at (L, H)**

Input: L = x, H = y of a sprite. From the cell under (x, y) down, three rows of three cells (two columns at x >= `$F1`, as DrawSprite; two rows only at y < `$11`, with no y AND 7 test) get their attribute from CellAttributes (code 9 and up: 6). Only the attributes are painted: DrawSprite `$9A4C` redraws the pixels with the background. Registers kept.

Callers: MainLoop before Harry moves, JumpStep before each step, JumpFall `$A2BE` before each fall step, MoveDuck before the duck moves. Witness: 147 583 calls.

[Animation: `PaintCells` at work](img/routines/PaintCells.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,837 calls, 4,436,128 t-states own (1.75 %) |
| Runs (the other recordings) | 144,746 calls (`stage1/rec/gameover-name` 50,630, `stage1/rec/levels-1-9` 39,767, `stage1/rec/idle-1p` 16,900 and 4 more) |
| Called from | `MainLoop`, `MoveDuck`, `JumpStep`, `JumpFall` |
| Calls | `CellAttrAddr`, `MapCellAddr` |
| Reads | `$61A8`-`$645E` (`LiveMap`); `$646F`-`$647D` (`LiveMap+711`); `$984F`-`$9854` (`CellAttributes`) |
| Writes | `$5827`-`$5835` (screen); `$5847`-`$5AFD` (screen) |

### `CellAttrAddr` (`$9584`)

**DE = the attribute address of pixel (L, H)**

As AttrAddrHen `$93DD`, the result in DE. Witness: 147 583 calls (PaintCells).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,837 calls, 502,187 t-states own (0.20 %) |
| Runs (the other recordings) | 144,746 calls (`stage1/rec/gameover-name` 50,630, `stage1/rec/levels-1-9` 39,767, `stage1/rec/idle-1p` 16,900 and 4 more) |
| Called from | `PaintCells` |

### `MapCellAddr` (`$95A6`)

**HL = the LiveMap address of the cell at pixel (L, H)**

Output: HL = LiveMap + x / 8 + 4 x (y AND `$F8`): row y / 8 from the bottom, 32 cells a row. Witness: 147 583 calls (PaintCells).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,837 calls, 470,980 t-states own (0.19 %) |
| Runs (the other recordings) | 144,746 calls (`stage1/rec/gameover-name` 50,630, `stage1/rec/levels-1-9` 39,767, `stage1/rec/idle-1p` 16,900 and 4 more) |
| Called from | `PaintCells` |

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
| Runs (the other recordings) | 2,027,644 calls (`stage1/rec/idle-1p` 2,027,615, `stage1/rec/levels-1-9` 11, `stage1/rec/gameover-name` 8 and 4 more) |
| Called from | `SetupLevel` (tail) |
| Calls | `MoveHen`, `PaintCells`, `TakeEggOrGrain`, `Beep`, `WalkHarry`, `HenTouches`, `ClimbLadder`, `LeaveLadder`, `MoveLifts`, `MoveDuck`, `CountDown`, `JumpStep`, `FallOffEdge` |
| Reads | `$5C3D`-`$5C3E` (`ERR_SP`); `$6EEB` (`Level`); `$72D8`-`$72DC` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir` and 1 more); `$7325`-`$7370` (`JumpState`, `JumpDx`, `JumpCount`, `JumpDelay` and 33 more) |
| Writes | `$72D9`-`$72DC` (`HarryY`, `HarryFrame`, `HarryDir`, `PassCounter`); `$7325`-`$732A` (`JumpState`, `JumpDx`, `JumpCount`, `JumpDelay` and 1 more); `$733C`-`$7355` (`LiftDelay`, `ScoreScreenAddr`, `BonusDigits`, `TimeDigits` and 15 more); `$736B`-`$7370` (`HenDelay`, `RandomPtr`, `LastTenThousands`, `TitleTuneDone` and 1 more) |
| Ports in | `$7FFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FEFE` |

### `TakeEggOrGrain` (`$99DF`)

**Take the egg or the grain at Harry's feet**

The cell at (HarryX + 8, HarryY - 8): an egg (3) is emptied and scores 100 x (1 + min(Level / 4, 9)) (AddScore `$A3A7` with B = 10 x that), SoundSweep = `$FF`, EggsLeft - 1; the twelfth egg returns from MainLoop too (two returns: the level is complete). Grain (4) is emptied and scores 50, BonusDelay and TimeDelay become `$FF` (the bonus and the time stop for 255 slow ticks), SoundSweep = `$FF`.

Witness: 114 442 calls; 16 levels completed (`$9A15`), 65 grains (`$9A1A`). The cell is emptied in LiveMap only: the next DrawSprite draws the background without it.

[Animation: `TakeEggOrGrain` at work](img/routines/TakeEggOrGrain.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,401 calls, 246,755 t-states own (0.10 %) |
| Runs (the other recordings) | 112,041 calls (`stage1/rec/gameover-name` 43,684, `stage1/rec/levels-1-9` 22,274, `stage1/rec/idle-1p` 15,602 and 4 more) |
| Called from | `MainLoop` |
| Calls | `MapCellAt`, `AddScore` |
| Reads | `$6EE6`-`$6EEB` (`EggsLeft`, `PlayerEggs`, `Level`); `$72D8`-`$72D9` (`HarryX`, `HarryY`) |
| Writes | `$61C9`-`$61EE` (`LiveMap+33`); `$6212`-`$621C` (`LiveMap+106`); `$6230`-`$6275` (`LiveMap+136`); `$62A0`-`$62A1` (`LiveMap+248`); `$62B3`-`$62FF` (`LiveMap+267`); `$6321` (`LiveMap+377`); 5 more ranges |

## sprite

`src/game/sprite.asm`

### `DrawSprite` (`$9A4C`)

**Draw sprite frame A at (L, H) over the map's background**

Inputs: A the frame (Sprites), L = x, H = y. The frame's 16 rows of 2 bytes go to SpriteBuffer as rows of 3, shifted right by x AND 7. CellBuffer gets the glyphs of the 3 x 3 map cells under (x, y) (LiveMap, CharacterSet), 24 lines of 3 bytes; the buffer is ORed with the 16 background lines that match y AND 7, and the 16 rows of 3 bytes are written from (x, y) down the screen. So a sprite erases its old self with the background as it moves one pixel. Then the attribute 6 (yellow) on 3 x 3 cells (2 columns at x >= `$F1`, 2 rows when y is on a cell or below `$11`).

Then the duck test: DuckX within HarryX - 7 .. HarryX + 8 and DuckY within HarryY - 8 .. HarryY + 9 kills: it drops the five saved words and every word on the stack until one is `$A410` or more and returns there. From MainLoop's own draws that word is the return into PlayLevel (`$A656`). From a draw inside JumpStep (JumpLand on a drift tick, the fall start `$A2B1`, CatchLift `$A286`) MainLoop's PUSH AF at `$9898` lies on the stack first. Those draws all come on the x-step pass, after the jump click's Beep, which leaves F = `$42` (Z and N), so the word is JumpDelay x 256 + `$42`: with JumpDelay `$A4` or more it passes the test and the RET goes to an address in `$A442-$FF42`. Known only from the code: no build was killed by the duck (`$9BC6` never ran). The test runs for every draw, also while the duck is caged on levels 1-8: a Harry at x 0-15 and y 143-160 would touch the caged duck at (8, 152).

Witness: 134 270 calls (WalkHarry, ClimbLadder, JumpStep, MoveDuck, CatchLift); 18 652-18 859 T unshifted, + about 1244 T a pixel of shift (levels-1-3 frames 600-612). Measured in levels-1-3 frames 600-900: Harry never read blank by the beam.

[Animation: `DrawSprite` at work](img/routines/DrawSprite.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,942 calls, 72,384,045 t-states own (28.58 %) |
| Runs (the other recordings) | 131,328 calls (`stage1/rec/gameover-name` 51,046, `stage1/rec/levels-1-9` 26,350, `stage1/rec/idle-1p` 18,203 and 4 more) |
| Called from | `WalkHarry`, `ClimbLadder`, `MoveDuck`, `CatchLift`, `DrawHarryFrame` |
| Calls | `SpriteAttrAddr` |
| Reads | `$61A8`-`$645E` (`LiveMap`); `$646F`-`$647D` (`LiveMap+711`); `$72A0`-`$7321` (`SpriteBuffer`, `HarryX`, `HarryY`, `HarryFrame` and 3 more); `$7348`-`$7349` (`DuckX`, `DuckY`); `$84F0`-`$851F` (`CharacterSet`); `$8A48`-`$8A9F` (`HudCharacters+104`); 1 more ranges |
| Writes | `$4047`-`$4055` (screen); `$4067`-`$57DD` (screen); `$5827`-`$5835` (screen); `$5847`-`$5AE8` (screen); `$5AFA`-`$5AFD` (screen); `$72A0`-`$7324` (`SpriteBuffer`, `HarryX`, `HarryY`, `HarryFrame` and 3 more) |

### `SpriteAttrAddr` (`$9BDE`)

**HL = the attribute address of pixel (L, H)**

As AttrAddrHen `$93DD`. Witness: 134 267 calls (DrawSprite).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,942 calls, 509,194 t-states own (0.20 %) |
| Runs (the other recordings) | 131,325 calls (`stage1/rec/gameover-name` 51,046, `stage1/rec/levels-1-9` 26,350, `stage1/rec/idle-1p` 18,203 and 4 more) |
| Called from | `DrawSprite` |

## sound

`src/game/sound.asm`

### `PrintChar` (`$9C40`)

**Print character A at row H (from the bottom), column L**

Four NOPs (room for a patch), then: the screen address of character row H (0 = row 23 at the bottom, 23 = the top) and column L, the glyph CharacterSet + 8 x A, eight bytes down the cell. Registers kept. Witness: 33 112 calls (the map, the HUD, the pages, the scrollers).

[Animation: `PrintChar` at work](img/routines/PrintChar.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,684 calls, 1,124,123 t-states own (0.44 %) |
| Runs (the other recordings) | 31,428 calls (`stage1/rec/idle-1p` 8,201, `stage1/rec/levels-1-9` 7,946, `stage1/rec/gameover-name` 6,998 and 4 more) |
| Called from | `AddScore`, `TitlePage`, `TitleLoop`, `InstructionsPage`, `StartGame`, `EnterHiScore`, `Message`, `RedefineKeys`, `RedefineOne`, `DrawHiScores`, `SetupLevel` |
| Reads | `$84F0`-`$86BF` (`CharacterSet`); `$86E8`-`$87BF` (`CharacterSet+504`); `$87F8`-`$8B4F` (`CharacterSet+776`, `HudCharacters`) |
| Writes | `$4000`-`$57FF` (screen) |

### `PhraseVector` (`$9C9C`)

**The IM 2 entry: jump to PhraseInterrupt**

VectorTable `$B200` holds `$9C9C` at every place (I = `$B2`, Start `$A410`), so every interrupt comes here. Witness: 127 166 interrupts in the eight builds.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,104 calls, 31,040 t-states own (0.01 %) |
| Runs (the other recordings) | 124,062 calls (`stage1/rec/gameover-name` 39,861, `stage1/rec/idle-1p` 28,802, `stage1/rec/levels-1-9` 25,251 and 4 more) |
| Entered by | the interrupt, 126,786 times in 54 routines |
| Calls | `PhraseInterrupt` (tail) |
| Reads | `$B2FF`-`$B300` (`VectorTable+255`) |
| Writes | `$FF1E`-`$FF3F` (`work space $FF1E+`) |

### `Beep` (`$9CA4`)

**Sound the speaker: L cycles of half period H**

OUT (`$FE`) `$10` (the speaker bit, black border), wait H, OUT 0, wait H, L times. B and L used, A = 0 at the end. Calls: the walk (`$2805` and `$2806` every 4 pixels), the climb (`$1E14`, `$1E15`), the jump click, the time tick (`$0402`), the pickup sweep, the bonus count (`$1E04`). One cycle 26 H + 47 T (high 13 H + 14, low 13 H + 33): 3 500 000 / (26 H + 47) Hz; levels-1-3 edges match to the T-state but for the ULA's wait on OUT (`$FE`). Witness: 127 975 calls.

[Animation: `Beep` at work](img/routines/Beep.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 493 calls, 1,418,685 t-states own (0.56 %) |
| Runs (the other recordings) | 47,184 calls (`stage1/rec/levels-1-9` 24,429, `stage1/rec/gameover-name` 10,224, `stage1/rec/levels-1-3` 6,464 and 4 more) |
| Called from | `MainLoop`, `WalkHarry`, `ClimbLadder`, `PlayLevel` |
| Ports out | `$00FE`, `$10FE` |

### `PhraseInterrupt` (`$9CC2`)

**The interrupt: send the phrase's next allophone to port `$9F`**

PhraseTimer `$FF`: nothing to do. Otherwise it counts down; at 0 it takes the next pair at PhrasePtr: the first byte is the new timer (in interrupts; `$FF` ends the phrase), the second goes to port `$9F` (an SP0256-AL2 allophone, sound/Phrases.txt). EI and RETI; no keyboard scan (the ROM's KSTATE stands still under IM 2, which is why EnterHiScore switches to IM 1). Witness: 127 166 calls, one an interrupt.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,104 calls, 298,629 t-states own (0.12 %) |
| Runs (the other recordings) | 124,062 calls (`stage1/rec/gameover-name` 39,861, `stage1/rec/idle-1p` 28,802, `stage1/rec/levels-1-9` 25,251 and 4 more) |
| Called from | `PhraseVector` (tail) |
| Reads | `$7373`-`$7375` (`PhraseTimer`, `PhrasePtr`); `$C92C`-`$C964` (`PhraseTable+100`); `$C980`-`$CA08` (`PhraseTable+184`); `$CA2E`-`$CABC` (`PhraseTable+358`); `$CAD4`-`$CB12` (`PhraseTable+524`); `$CB2A`-`$CB4E` (`PhraseTable+610`); 2 more ranges |
| Writes | `$7373`-`$7375` (`PhraseTimer`, `PhrasePtr`) |
| Ports out | `$009F`, `$079F`, `$089F`, `$099F`, `$0B9F`, `$0C9F`, `$0E9F`, `$0F9F`, `$119F`, `$139F`, `$149F`, `$159F`, `$179F`, `$1A9F`, `$229F`, `$239F`, `$279F`, `$289F`, `$299F`, `$2B9F`, `$2C9F`, `$2D9F`, `$2E9F`, `$2F9F`, `$329F`, `$379F`, `$399F` |

### `StartPhrase` (`$9CEB`)

**Start phrase A unless one is playing**

Input: A the phrase number 1-33. When PhraseTimer is `$FF`: PhrasePtr = the phrase's address from PhraseTable (PhraseTable - 2 + 2A), PhraseTimer = 1 (the first pair goes at the next interrupt). Otherwise the call is lost. Callers: the title (20), the instructions (24), a player's turn (25 + player), the name entry (7), LevelPhrase, DeathPhrase, LiftPhrase. Witness: 106 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 1,628 t-states own (0.00 %) |
| Runs (the other recordings) | 103 calls (`stage1/rec/levels-1-9` 42, `stage1/rec/gameover-name` 24, `stage1/rec/levels-1-3` 14 and 4 more) |
| Called from | `LiftPhrase` (tail), `TitlePage`, `InstructionsPage`, `PlayerTurn`, `EnterHiScore`, `DeathPhrase` (tail), `LevelPhrase` (tail) |
| Reads | `$7373` (`PhraseTimer`); `$C8C8`-`$C907` (`PhraseTable`) |
| Writes | `$7373`-`$7375` (`PhraseTimer`, `PhrasePtr`) |

## harry

`src/game/harry.asm`

### `WalkHarry` (`$9D08`)

**Walk Harry left or right one pixel, or stand**

Left key: unless x = 1 or the cells to the left (at his feet and above, LiveMap) are bricks: x - 1, HarryDir 4, a step sound (`$2805`) every 4 pixels. Right key: unless x >= `$EE` or the cells to the right are bricks: x + 1, HarryDir 0, a sound (`$2806`). No key: HarryFrame 3 (the next is 0, standing). Then the frame steps (0-3) and DrawSprite draws him. On a lift: when x leaves LiftX - 9 .. LiftX + 9 he walks off (JumpState 1, JumpDx his direction, JumpCount 4: the drift of FallOffEdge). OnLift stays 1 (only the jump start and SetupLevel clear it), so until the next jump the lift steps still raise him and the top-row death test still applies.

Witness: 95 138 calls; left steps `$9D59` 5 749, right `$9D95` 6 073, standing `$9DAB` 83 316. Known only from the code: walking off a lift (`$9DDB` never ran).

[Animation: `WalkHarry` at work](img/routines/WalkHarry.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,252 calls, 1,135,087 t-states own (0.45 %) |
| Runs (the other recordings) | 92,886 calls (`stage1/rec/gameover-name` 40,580, `stage1/rec/idle-1p` 15,597, `stage1/rec/tour-redefine` 12,826 and 4 more) |
| Called from | `MainLoop` |
| Calls | `DrawSprite`, `Beep` |
| Reads | `$61C8`-`$62A7` (`LiveMap+32`); `$62B8`-`$631C` (`LiveMap+272`); `$6333`-`$6427` (`LiveMap+395`); `$72D8`-`$72DB` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir`); `$7332`-`$7335` (`KeyTable+4`); `$7350`-`$7355` (`LiftX`, `Lift1Row`, `Lift2`, `Lift2Row` and 1 more) |
| Writes | `$72D8`-`$72DB` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir`) |
| Ports in | `$DFFE`, `$EFFE`, `$F7FE` |

### `MapCellAt` (`$9E34`)

**A = the map cell at pixel (L, H), HL its address**

Output: HL = LiveMap + x / 8 + 4 x (y AND `$F8`), A = the code there (0 empty, 1 and 2 a ladder, 3 an egg, 4 grain, 5 a brick, `$A8-$B5` the cage). BC and DE kept. Witness: 264 678 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 5,252 calls, 968,431 t-states own (0.38 %) |
| Runs (the other recordings) | 259,426 calls (`stage1/rec/gameover-name` 109,371, `stage1/rec/levels-1-9` 46,361, `stage1/rec/idle-1p` 35,794 and 4 more) |
| Called from | `HenEatGrain`, `MapCellAddrKeepA`, `MapCellPeek`, `TakeEggOrGrain`, `JumpLand`, `FallOffEdge` |
| Reads | `$61A8`-`$645C` (`LiveMap`); `$646F`-`$647A` (`LiveMap+711`) |

### `HenTouches` (`$9E66`)

**A = 1 when the hen at (E, D) touches Harry**

The box test of DrawHen `$929C` (Harry's x within x - 7 .. x + 5, y within y + 1 .. y + `$1C`), without the kill: A = 1 touch, 0 none; HL kept. MainLoop calls it for the five hens after each vertical jump step. Witness: 29 382 calls (none in idle-1p, where Harry never jumps).

| | |
| --- | --- |
| Runs (the first recording's game window) | 184 calls, 19,886 t-states own (0.01 %) |
| Runs (the other recordings) | 29,198 calls (`stage1/rec/levels-1-9` 20,359, `stage1/rec/gameover-name` 3,909, `stage1/rec/levels-1-3` 3,909 and 3 more) |
| Called from | `MainLoop` |
| Reads | `$72D8`-`$72D9` (`HarryX`, `HarryY`) |

### `ClimbLadder` (`$9E98`)

**Climb up or down a ladder one pixel**

Only at x AND 7 = 0 (Harry over a column). Up key with a ladder's left half (1) in the cell above his head (y + 1): HarryDir `$0D`, y + 1, a sound (`$1E14`) every 4. Else down key with a ladder below his feet (two rows down, three when y is on a cell): HarryDir `$0D`, y - 1, a sound (`$1E15`). Either way the frame steps and JumpState becomes 0: a jump that meets a ladder with up or down held is caught. Then DrawSprite. Witness: 113 934 calls; up `$9ED7` 3 570, down `$9F11` 1 810.

[Animation: `ClimbLadder` at work](img/routines/ClimbLadder.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,396 calls, 193,734 t-states own (0.08 %) |
| Runs (the other recordings) | 111,538 calls (`stage1/rec/gameover-name` 43,594, `stage1/rec/levels-1-9` 21,979, `stage1/rec/idle-1p` 15,597 and 4 more) |
| Called from | `MainLoop` |
| Calls | `DrawSprite`, `Beep` |
| Reads | `$61A9`-`$645C` (`LiveMap+1`); `$6470`-`$647B` (`LiveMap+712`); `$72D8`-`$72DB` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir`); `$732E`-`$7331` (`KeyTable`) |
| Writes | `$72D9`-`$72DB` (`HarryY`, `HarryFrame`, `HarryDir`); `$7325` (`JumpState`) |
| Ports in | `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### `LeaveLadder` (`$9F60`)

**Step off a ladder onto a floor, left or right**

Only when y + 1 is on a cell boundary. Left key: the cell to the left and the one above it must not be bricks, and the one under them must be a floor (1-8): HarryDir 4. Right key: the same to the right: HarryDir 0. The changed HarryDir lets WalkHarry run on the same tick. Witness: 100 660 calls; left `$9FAF` 4 663, right `$9FDA` 5 530.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,252 calls, 773,165 t-states own (0.31 %) |
| Runs (the other recordings) | 98,408 calls (`stage1/rec/gameover-name` 41,733, `stage1/rec/idle-1p` 15,597, `stage1/rec/levels-1-9` 13,176 and 4 more) |
| Called from | `MainLoop` |
| Reads | `$61A8`-`$6427` (`LiveMap`); `$72D8`-`$72D9` (`HarryX`, `HarryY`); `$7332`-`$7335` (`KeyTable+4`) |
| Writes | `$72DB` (`HarryDir`) |
| Ports in | `$DFFE`, `$EFFE`, `$F7FE` |

## lifts

`src/game/lifts.asm`

### `MoveLifts` (`$A014`)

**Move both lift platforms up one pixel**

Nothing when LiftX is `$FF`. For each platform: DrawLift with 0 (erase) at its address, its row count + 1; at 166 the platform restarts from LiftTable's record (platform 1 takes the address, x and row, then row 3; platform 2 copies 3 bytes, so Lift2Row holds LiftX until LD A,`$03` sets row 3); the address one line up (LineUp `$A0A9`), DrawLift with `$FF`. A restart also passes LineUp, so after its first restart a platform is drawn one line above its row count (SetupLevel's start address has no LineUp). Witness: 57 158 calls; restarts `$A02E` 164 and `$A05C` 167.

[Animation: `MoveLifts` at work](img/routines/MoveLifts.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,199 calls, 38,870 t-states own (0.02 %) |
| Runs (the other recordings) | 55,959 calls (`stage1/rec/gameover-name` 21,827, `stage1/rec/levels-1-9` 11,118, `stage1/rec/idle-1p` 7,791 and 4 more) |
| Called from | `MainLoop` |
| Calls | `DrawLift`, `LineUp` |
| Reads | `$734E`-`$7354` (`Lift1`, `LiftX`, `Lift1Row`, `Lift2` and 1 more); `$9787`-`$978A` (`LiftTable`) |
| Writes | `$734E`-`$7354` (`Lift1`, `LiftX`, `Lift1Row`, `Lift2` and 1 more) |

### `DrawLift` (`$A07B`)

**Draw (C = `$FF`) or erase (C = 0) a platform at screen address HL**

Clears the byte left of HL and the byte right of the platform (unless that is column 0), then four lines of two bytes of C going down the screen (LineDown). HL kept. Witness: 109 600 calls (only in the builds with lifts: levels-1-3, gameover-name, levels-1-9).

[Animation: `DrawLift` at work](img/routines/DrawLift.gif)

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 109,600 calls (`stage1/rec/gameover-name` 80,928, `stage1/rec/levels-1-9` 22,844, `stage1/rec/levels-1-3` 5,828) |
| Called from | `MoveLifts` |
| Calls | `LineDown` |
| Writes | `$4087`-`$41FF` (screen); `$4267`-`$42FF` (screen); `$4367`-`$43FF` (screen); `$4467`-`$44FF` (screen); `$4567`-`$46FF` (screen); `$4767`-`$57FF` (screen) |

### `LineDown` (`$A096`)

**HL one screen line down**

The display file's line order: H + 1, and across a character row or a third. Witness: 438 400 calls.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 438,400 calls (`stage1/rec/gameover-name` 323,712, `stage1/rec/levels-1-9` 91,376, `stage1/rec/levels-1-3` 23,312) |
| Called from | `DrawLift` |

### `LineUp` (`$A0A9`)

**HL one screen line up**

Witness: 54 800 calls (MoveLifts).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 54,800 calls (`stage1/rec/gameover-name` 40,464, `stage1/rec/levels-1-9` 11,422, `stage1/rec/levels-1-3` 2,914) |
| Called from | `MoveLifts` |

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
| Runs (the other recordings) | 9,352 calls (`stage1/rec/gameover-name` 3,643, `stage1/rec/levels-1-9` 1,861, `stage1/rec/idle-1p` 1,303 and 4 more) |
| Called from | `MainLoop` |
| Calls | `PaintCells`, `DrawSprite` |
| Reads | `$6EEB` (`Level`); `$72D8`-`$72D9` (`HarryX`, `HarryY`); `$7348`-`$734D` (`DuckX`, `DuckY`, `DuckDx`, `DuckDy` and 2 more) |
| Writes | `$7348`-`$734D` (`DuckX`, `DuckY`, `DuckDx`, `DuckDy` and 2 more) |

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
| Runs (the other recordings) | 17,419 calls (`stage1/rec/levels-1-9` 6,296, `stage1/rec/gameover-name` 5,526, `stage1/rec/idle-1p` 1,863 and 4 more) |
| Called from | `MainLoop`, `PlayLevel` |
| Reads | `$733F`-`$7344` (`BonusDigits`, `TimeDigits`); `$89E0`-`$8A2F` (`HudCharacters`) |
| Writes | `$4053`-`$415F` (screen); `$4253`-`$425F` (screen); `$4353`-`$435F` (screen); `$4453`-`$445F` (screen); `$4553`-`$455F` (screen); `$4653`-`$465F` (screen); 2 more ranges |

## jump

`src/game/jump.asm`

### `JumpStep` (`$A21C`)

**One step of the jump or the fall**

On the pass before the slow tick (PassCounter 1): PaintCells, x + JumpDx (bouncing at 0 and `$EE`), CatchLift for both platforms, then JumpDrift. On the other passes: in the air, the vertical step (JumpFall). Witness: 1 760 022 calls (0 in idle-1p).

| | |
| --- | --- |
| Runs (the first recording's game window) | 19,048 calls, 1,009,552 t-states own (0.40 %) |
| Runs (the other recordings) | 1,740,974 calls (`stage1/rec/levels-1-9` 1,165,466, `stage1/rec/gameover-name` 247,448, `stage1/rec/levels-1-3` 247,448 and 3 more) |
| Called from | `MainLoop` |
| Calls | `PaintCells`, `CatchLift`, `JumpFall` (tail) |
| Reads | `$72D8`-`$72DC` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir` and 1 more); `$7325`-`$7327` (`JumpState`, `JumpDx`, `JumpCount`) |
| Writes | `$72D8` (`HarryX`); `$7325`-`$732A` (`JumpState`, `JumpDx`, `JumpCount`, `JumpDelay` and 1 more) |

### `CatchLift` (`$A256`)

**Land Harry on the lift platform whose row count is at HL**

Nothing without a lift. When HarryX is within LiftX - 9 .. LiftX + 9 and HarryY is within six pixels under the row + 16: OnLift 1, JumpState 0, Harry erased (frame 12), HarryY = row + `$11`, and the rest of JumpStep is dropped (POP); LiftPhrase speaks. Witness: 26 662 calls, 50 landings (`$A278`).

[Animation: `CatchLift` at work](img/routines/CatchLift.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 288 calls, 9,320 t-states own (0.00 %) |
| Runs (the other recordings) | 26,374 calls (`stage1/rec/levels-1-9` 17,670, `stage1/rec/gameover-name` 3,743, `stage1/rec/levels-1-3` 3,743 and 3 more) |
| Called from | `JumpStep` |
| Calls | `DrawSprite`, `LiftPhrase` |
| Reads | `$72D8`-`$72D9` (`HarryX`, `HarryY`); `$7350`-`$7354` (`LiftX`, `Lift1Row`, `Lift2`, `Lift2Row`) |
| Writes | `$72D9` (`HarryY`); `$7325` (`JumpState`); `$7355` (`OnLift`) |

### `JumpDrift` (`$A294`)

**JumpState 1: count the drift; at its end the fall starts**

JumpCount - 1; not 0: JumpLand. At 0: JumpState 2, JumpDx 0, JumpCount `$FA`, JumpDy `$FF`, and Harry is drawn. JumpState 2 goes on to JumpFall. Witness: the fall starts `$A2A2` 63 times.

| | |
| --- | --- |
| Runs (the first recording's game window) | 144 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 13,141 runs of its first instruction, entered by a jump (`stage1/rec/levels-1-9` 8,808, `stage1/rec/gameover-name` 1,862, `stage1/rec/levels-1-3` 1,862 and 3 more) |
| Calls | `JumpFall` (tail), `JumpLand` (tail), `DrawHarryFrame` |

### `JumpFall` (`$A2B5`)

**The vertical step of a jump or a fall**

JumpDelay counts passes. Rising (JumpDy 1): JumpCount + 10 each step, from `$8C`; after 12 steps (it wraps to 4) the top: JumpDy 0; at y `$A7` and over the jump turns down. At the top the next step starts the fall: JumpDy `$FF`, delay 250, then 10 less a step, down to 40 (the fall speeds up). y + JumpDy; under y `$10` the life ends (two POPs: back from MainLoop; fall-death, `$A309` 1). Then JumpLand.

Witness: the top `$A2F6` 243, the fall starts `$A2CC` 279.

[Animation: `JumpFall` at work](img/routines/JumpFall.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 19,048 calls, 687,271 t-states own (0.27 %) |
| Runs (the other recordings) | 1,708,164 calls (`stage1/rec/levels-1-9` 1,146,716, `stage1/rec/gameover-name` 241,718, `stage1/rec/levels-1-3` 241,718 and 3 more) |
| Called from | `JumpStep` (tail), `JumpDrift` (tail) |
| Calls | `PaintCells`, `JumpLand` (falls into) |
| Reads | `$61B0`-`$61BD` (`LiveMap+8`); `$61D0`-`$61FF` (`LiveMap+40`); `$72D8`-`$72DB` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir`); `$7326`-`$732A` (`JumpDx`, `JumpCount`, `JumpDelay`, `JumpDy`) |
| Writes | `$72D9` (`HarryY`); `$7325`-`$732A` (`JumpState`, `JumpDx`, `JumpCount`, `JumpDelay` and 1 more) |

### `JumpLand` (`$A30F`)

**Draw Harry in the air; bounce off walls; land on a floor**

Draws frame 1 of his direction (DrawHarryFrame). The cell under his feet (MapCellAt - `$3F`): not rising and moving sideways, a brick beside him reverses JumpDx (101 bounces, `$A34E`). A brick, or a ladder with a brick beside it, under his feet, with y + 1 on a cell boundary: JumpState 0 (landed; a climbing frame becomes 0). Witness: 813 landings (`$A36A`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 92 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,285 calls (`stage1/rec/levels-1-9` 6,911, `stage1/rec/gameover-name` 1,472, `stage1/rec/levels-1-3` 1,472 and 1 more) |
| Called from | `JumpDrift` (tail), `JumpFall` (falls into) |
| Calls | `MapCellAt`, `DrawHarryFrame` |
| Reads | `$61A9`-`$641E` (`LiveMap+1`); `$6430`-`$643C` (`LiveMap+648`); `$72D8`-`$72DB` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir`); `$7326`-`$732A` (`JumpDx`, `JumpCount`, `JumpDelay`, `JumpDy`) |
| Writes | `$72DB` (`HarryDir`); `$7325`-`$7326` (`JumpState`, `JumpDx`) |

### `DrawHarryFrame` (`$A37F`)

**DrawSprite frame A + HarryDir at Harry**

Witness: 10 532 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 92 calls, 6,083 t-states own (0.00 %) |
| Runs (the other recordings) | 10,440 calls (`stage1/rec/levels-1-9` 6,947, `stage1/rec/gameover-name` 1,483, `stage1/rec/levels-1-3` 1,483 and 3 more) |
| Called from | `JumpDrift`, `JumpLand` |
| Calls | `DrawSprite` |
| Reads | `$72D8`-`$72DB` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir`) |

### `LiftPhrase` (`$A389`)

**Speak one of the eight LiftPhrases (R AND 7)**

Witness: 50 calls (the lift landings).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 50 calls (`stage1/rec/levels-1-9` 30, `stage1/rec/gameover-name` 10, `stage1/rec/levels-1-3` 10) |
| Called from | `CatchLift` |
| Calls | `StartPhrase` (tail) |
| Reads | `$A399`-`$A3A0` (`LiftPhrases`) |

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
| Runs (the other recordings) | 5,657 calls (`stage1/rec/levels-1-9` 4,379, `stage1/rec/gameover-name` 577, `stage1/rec/levels-1-3` 573 and 4 more) |
| Called from | `TakeEggOrGrain`, `PlayLevel`, `SetupLevel` |
| Calls | `PrintChar` |
| Reads | `$6EC8`-`$6ECD` (`Score`); `$6EF0` (`PlayerLives`); `$733B`-`$733E` (`Player`, `LiftDelay`, `ScoreScreenAddr`); `$736E` (`LastTenThousands`); `$8670`-`$86BF` (`CharacterSet+384`) |
| Writes | `$4005`-`$411F` (screen); `$4205`-`$421F` (screen); `$4305`-`$431F` (screen); `$4405`-`$441F` (screen); `$4505`-`$451F` (screen); `$4605`-`$461F` (screen); 4 more ranges |

## flow

`src/game/flow.asm`

### `Start` (`$A410`)

**The entry: key type 1, IM 2, the title page**

Entered by the loader's JP `$A410` (c1 frame 5292) and by the abort key. KeyType 6, TitleTuneDone 0, I = `$B2` (VectorTable), IM 2. Witness: c1 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 18,473 t-states own (0.01 %) |
| Reads | `$736F` (`TitleTuneDone`); `$9630`-`$9763` (`TitleText`) |
| Writes | `$732D` (`KeyType`); `$736F` (`TitleTuneDone`) |

### `TitlePage` (`$A420`)

**Draw the title page and the high scores**

ClearScreen, TitleText at rows 2-23 columns 0-13, DrawHiScores, the colours of the left half (magenta, yellow, green bands), the title tune and phrase 20 while TitleTuneDone is 0 (set by Start: the first title and after an abort; silent after a game over), row 23 cyan, TextIndex at the end of the text. Then TitleLoop. Witness: 4 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 14,152,615 t-states own (5.59 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/idle-1p` 1, `stage1/rec/gameover-name` 1) |
| Called from | `GameOver` (tail), `RedefineKeys` (tail) |
| Calls | `PrintChar`, `StartPhrase`, `FillAttrBlock`, `PlayTune`, `ClearScreen`, `DrawHiScores` |
| Reads | `$6EC8`-`$6ECD` (`Score`); `$6EE6` (`EggsLeft`); `$732B`-`$733B` (`ScrollDelay`, `TextIndex`, `KeyType`, `KeyTable` and 2 more); `$736F`-`$7373` (`TitleTuneDone`, `SoundSweep`, `PhraseTimer`); `$8390`-`$84EF` (`InstructionsText`); `$9630`-`$9763` (`TitleText`); 3 more ranges |
| Writes | `$4000`-`$57FF` (screen); `$5940`-`$595F` (screen); `$59C0`-`$59DF` (screen); `$5AE0`-`$5AFF` (screen); `$61A8`-`$6EF3` (`LiveMap`, `Score`, `PlayerScores`, `EggsLeft` and 4 more); `$732B`-`$733B` (`ScrollDelay`, `TextIndex`, `KeyType`, `KeyTable` and 2 more); 2 more ranges |
| Ports in | `$DFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### `TitleLoop` (`$A47D`)

**Scroll the title text; S starts, R redefines, I shows the instructions**

ScrollLine at the bottom row, Delay 500; every 8 shifts the next of TitleScroller's 78 characters enters at column 30. Keys: S StartGame, R RedefineKeys, I InstructionsPage. Witness: every build starts here.

| | |
| --- | --- |
| Runs (the first recording's game window) | 531 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 37,270 runs of its first instruction, entered by a jump (`stage1/rec/idle-1p` 33,045, `stage1/rec/gameover-name` 3,327, `stage1/rec/tour-type2` 545 and 4 more) |
| Calls | `PrintChar`, `StartGame` (tail), `Delay`, `ScrollLine` |
| Reads | `$732B`-`$733B` (`ScrollDelay`, `TextIndex`, `KeyType`, `KeyTable` and 2 more); `$7373` (`PhraseTimer`); `$8390`-`$84EF` (`InstructionsText`); `$AC7C`-`$ACB9` (`TitleScroller`); `$ACCA`-`$ACF0` (`InstructionsScroller`); `$AD21`-`$AD3D` (`PlayersPrompt`); 1 more ranges |
| Writes | `$4000`-`$57FF` (screen); `$5940`-`$595F` (screen); `$5980`-`$599F` (screen); `$61A8`-`$6EF3` (`LiveMap`, `Score`, `PlayerScores`, `EggsLeft` and 4 more); `$732B`-`$733B` (`ScrollDelay`, `TextIndex`, `KeyType`, `KeyTable` and 2 more); `$AD50`-`$AD59` (`PlayerMessage+7`, `LevelMessage`, `LevelDigits`) |
| Ports in | `$DFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### `InstructionsPage` (`$A4C8`)

**Draw the instructions page, scroll its text, take the key type**

ClearScreen; InstructionsText's 11 rows at rows 3, 5 .. 23; the colour bands; TextIndex at the end, KeyType 10 (no type shown, so the first key 1-3 marks one); WaitPhrase and phrase 24. The loop scrolls InstructionsScroller (87 characters); S (once the phrase ends) StartGame, R RedefineKeys; keys 1, 2, 3 set KeyType and move the flashing bar to the type's row (`$5940`, `$5980`, `$59C0`). A KeyType of 10 left as it is plays as type 1 (SetupLevel takes `$8250` for anything but 5 and 3).

Witness: c1, idle-1p, tour-type2 (key 2, `$A56D`), tour-redefine.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 runs of its first instruction, entered by a jump (`stage1/rec/tour-redefine` 1, `stage1/rec/tour-type2` 1) |
| Calls | `PrintChar`, `StartPhrase`, `Delay`, `WaitPhrase`, `FillAttrBlock`, `RedefineKeys` (tail), `ScrollLine`, `ClearScreen` |

### `StartGame` (`$A59D`)

**Take the number of players and set up the game**

BoxWipe in colours, the screen cleared, BoxWipe in black; the players prompt scrolls in and keys 1-4 set Players (Player 1). Five copies of level 1's map into LiveMap; the scores 0, levels 0, eggs 12, lives 5; LevelDigits "01" (`$9F9E`: the HUD codes of 0 and 1); WaitPhrase. Then PlayerTurn. Witness: 7 games in the eight builds.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 5 calls (`stage1/rec/levels-1-9` 1, `stage1/rec/gameover-name` 1, `stage1/rec/levels-1-3` 1 and 2 more) |
| Called from | `TitleLoop` (tail) |
| Calls | `PrintChar`, `BoxWipe`, `WaitPhrase`, `ScrollLine` |
| Reads | `$61A8`-`$66E7` (`LiveMap`); `$6EC8`-`$6EF0` (`Score`, `PlayerScores`, `EggsLeft`, `PlayerEggs` and 3 more); `$733A`-`$7347` (`Players`, `Player`, `LiftDelay`, `ScoreScreenAddr` and 5 more); `$AD21`-`$AD3D` (`PlayersPrompt`); `$B3B0`-`$C8AF` (`LevelMaps`, `LevelMap2`, `LevelMap3`, `LevelMap4` and 4 more) |
| Writes | `$4000`-`$57FF` (screen); `$61A8`-`$6EF3` (`LiveMap`, `Score`, `PlayerScores`, `EggsLeft` and 4 more); `$733A`-`$733B` (`Players`, `Player`); `$AD58`-`$AD59` (`LevelDigits`); `$AD72` (`Congratulations+11`) |
| Ports in | `$F7FE` |

### `PlayerTurn` (`$A62C`)

**Announce the player (two players or more) and play**

With more than one player: phrase 25 + player, "PLAYER n" scrolled in (Message), Delay 65536. Then PlayLevel. The LD BC,`$AD49` at `$A63A` is overwritten at once (C = 8): a leftover. Witness: 14 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 5 calls (`stage1/rec/idle-1p` 4, `stage1/rec/tour-redefine` 1) |
| Called from | `LifeLost` (tail) |
| Calls | `StartPhrase`, `Delay`, `Message` |
| Reads | `$6EC8`-`$6ECD` (`Score`); `$6EE6` (`EggsLeft`); `$733A`-`$733B` (`Players`, `Player`) |
| Writes | `$6ECE`-`$6ED3` (`PlayerScores`); `$AD50` (`PlayerMessage+7`) |

### `PlayLevel` (`$A653`)

**Play a level: SetupLevel and MainLoop; then the level end or the life lost**

CALL SetupLevel (which jumps to MainLoop); MainLoop returns here at `$A656`. WaitPhrase, the score into the player's slot, IM 2 (again after a name entry). Eggs left: LifeLost. Else the bonus is counted into the score (CountDown, then AddScore 10, a beep, on every step: the step that takes the bonus past 000 still adds 10, so a bonus of N is paid as N + 10), a pause, BoxZoom; the level + 1, "LEVEL nn" (the number is level + 1 mod 100), the next map (LevelMaps + 672 x (Level AND 7)) into the map in play, 12 eggs, and the next level.

Witness: 5 375 bonus steps (`$A675`); 16 levels completed.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 34 runs of its first instruction, entered by a jump (`stage1/rec/levels-1-9` 11, `stage1/rec/gameover-name` 8, `stage1/rec/idle-1p` 5 and 4 more) |
| Calls | `Beep`, `CountDown`, `AddScore`, `LifeLost` (tail), `Delay`, `WaitPhrase`, `BoxZoom`, `Message`, `SetupLevel` |

### `LifeLost` (`$A6FE`)

**A life lost: the tune, the next player with lives, or the game over**

DeathTune, DeathPhrase, WaitPhrase, a pause, ClearScreen; OUT OF TIME when the time digits are `$FF` 9 9; the map in play into the player's slot, the eggs and the level into his; lives - 1; at 0 "GAME OVER" (with "PLAYER n" whenever Players > 1, the last player out included). Then the next player with lives (in turn) is loaded (level, eggs, score, map) and PlayerTurn; none left: GameOver.

Witness: 14 lives lost (`$A6FE`), out of time 1 (`$A725`, tour-redefine), game over 2 (`$A7BC`: idle-1p, gameover-name).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 27 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/rec/idle-1p` 5, `stage1/rec/tour-redefine` 1) |
| Called from | `PlayLevel` (tail) |
| Calls | `PlayerTurn` (tail), `Delay`, `WaitPhrase`, `Message`, `DeathPhrase`, `PlayTune`, `ClearScreen` |
| Reads | `$61A8`-`$6987` (`LiveMap`); `$6ECE`-`$6EF1` (`PlayerScores`, `EggsLeft`, `PlayerEggs`, `Level` and 2 more); `$733A`-`$7344` (`Players`, `Player`, `LiftDelay`, `ScoreScreenAddr` and 2 more) |
| Writes | `$4000`-`$57FF` (screen); `$61A8`-`$66E7` (`LiveMap`); `$6EC8`-`$6EF0` (`Score`, `PlayerScores`, `EggsLeft`, `PlayerEggs` and 3 more); `$733B` (`Player`); `$AD72` (`Congratulations+11`) |

### `GameOver` (`$A7BC`)

**The end of the game: each player's score against the table**

BoxWipe, the pixels cleared, BoxWipe; the 24 score digits become ASCII; for each player his digit at `$AD72` (Congratulations) and EnterHiScore; BoxZoom after an entry. Then TitlePage. Witness: 2 calls.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 2 runs of its first instruction, entered by a jump (`stage1/rec/gameover-name` 1, `stage1/rec/idle-1p` 1) |
| Calls | `TitlePage` (tail), `EnterHiScore`, `BoxWipe`, `BoxZoom` |

## hiscore

`src/game/hiscore.asm`

### `EnterHiScore` (`$A80C`)

**Put the score at HL in the table and take a name**

Compares the score with the ten entries (CompareScore); not greater than any: D = 1, return. Else the entries below shift down, the name is cleared, the six digits copied; the Congratulations page (11 rows of 15, rows 23, 21 .. 3), DrawHiScores, colours, phrase 7. Then IM 1: the cursor `$B7` at the entry's row (2 x rank + 1), column 16; HALT until KSTATE4 shows a new key; LAST_K ENTER ends, DELETE (12) erases back, codes `$20` and up are stored and printed, nine at most. IM 2, D = 2.

Witness: gameover-name (one entry, three characters `$A8D5`, ENTER `$A8E4`); 2 calls. DELETE (`$A8C3`): name-delete, CAPS SHIFT + 0 at frame 63 T 3322.

[Animation: `EnterHiScore` at work](img/routines/EnterHiScore.gif)

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 2 calls (`stage1/rec/gameover-name` 1, `stage1/rec/idle-1p` 1) |
| Called from | `GameOver` |
| Calls | `PrintChar`, `StartPhrase`, `WaitPhrase`, `CompareScore`, `FillAttrBlock`, `DrawHiScores` |
| Reads | `$5C04`-`$5C08` (`KSTATE4`, `LAST_K`); `$6ECE`-`$6ED3` (`PlayerScores`); `$97AF`-`$983E` (`HiScoreTable`); `$A8B1` (`EnterHiScoreWait+1`); `$AD67`-`$AE0B` (`Congratulations`) |
| Writes | `$97AF`-`$984E` (`HiScoreTable`) |

## effects

`src/game/effects.asm`

### `DrawBox` (`$A8EC`)

**An attribute rectangle of colour TextIndex**

Inputs: H, L a corner (row from the bottom, column), D the height, E the width. The four sides between (H, L) and (H - D, L + E) (AttrAddr `$AA23`). Registers kept. Witness: 1 056 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 24 calls, 46,788 t-states own (0.02 %) |
| Runs (the other recordings) | 1,032 calls (`stage1/rec/levels-1-9` 456, `stage1/rec/gameover-name` 240, `stage1/rec/levels-1-3` 168 and 4 more) |
| Called from | `BoxWipe`, `BoxZoom`, `BoxZoomBox` |
| Calls | `AttrAddr` |
| Reads | `$732C` (`TextIndex`) |
| Writes | `$5800`-`$5AFF` (screen) |

### `Delay` (`$A921`)

**Count BC down**

Witness: 39 283 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,123 calls, 17,441,119 t-states own (6.89 %) |
| Runs (the other recordings) | 38,160 calls (`stage1/rec/idle-1p` 33,099, `stage1/rec/gameover-name` 3,435, `stage1/rec/tour-type2` 880 and 4 more) |
| Called from | `TitleLoop`, `InstructionsPage`, `PlayerTurn`, `PlayLevel`, `LifeLost`, `BoxWipe`, `BoxZoom` |

### `BoxWipe` (`$A929`)

**Twelve nested boxes from the edge in; IXh 2 in colours, 1 in black**

Colours from `$12` stepping by 9 (IXh 2), or 3 throughout (IXh 1); Delay 5000 between boxes. Witness: 20 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 3,837 t-states own (0.00 %) |
| Runs (the other recordings) | 18 calls (`stage1/rec/gameover-name` 4, `stage1/rec/idle-1p` 4, `stage1/rec/fall-death` 2 and 4 more) |
| Called from | `StartGame`, `GameOver` |
| Calls | `DrawBox`, `Delay` |
| Writes | `$732C` (`TextIndex`) |

### `WaitPhrase` (`$A960`)

**Wait until no phrase plays**

Witness: 1 662 374 loops.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 113 t-states own (0.00 %) |
| Runs (the other recordings) | 53 calls (`stage1/rec/gameover-name` 16, `stage1/rec/levels-1-9` 12, `stage1/rec/idle-1p` 11 and 4 more) |
| Called from | `InstructionsPage`, `StartGame`, `PlayLevel`, `LifeLost`, `EnterHiScore` |
| Reads | `$7373` (`PhraseTimer`) |

### `BoxZoom` (`$A968`)

**Boxes growing from the middle in four quadrants, twice**

The first round in colours (from 9, + 9 a box), the pixels cleared, the second in green (4). Delay 10000 a step. Witness: 17 calls (the level ends, a name entered).

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 17 calls (`stage1/rec/levels-1-9` 9, `stage1/rec/gameover-name` 4, `stage1/rec/levels-1-3` 3 and 1 more) |
| Called from | `PlayLevel`, `GameOver` |
| Calls | `DrawBox`, `Delay`, `BoxZoomBox` |
| Writes | `$4000`-`$57FF` (screen); `$732C` (`TextIndex`) |

### `Message` (`$A9CE`)

**Scroll C characters from DE across row 11, then out**

Rows 11-14 green; ScrollLine at row 11 with the next character printed at column 30 every 8 shifts, then 256 shifts more. Witness: 22 calls.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 22 calls (`stage1/rec/levels-1-9` 9, `stage1/rec/gameover-name` 4, `stage1/rec/tour-redefine` 3 and 4 more) |
| Called from | `PlayerTurn`, `PlayLevel`, `LifeLost` |
| Calls | `PrintChar`, `ScrollLine` |
| Reads | `$AD3F`-`$AD66` (`GameOverMessage`, `PlayerMessage`, `LevelMessage`, `LevelDigits` and 1 more) |
| Writes | `$5960`-`$59DF` (screen) |

### `BoxZoomBox` (`$A9FA`)

**DrawBox, the colour + 9 first in the colour round**

Witness: 204 calls.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 204 calls (`stage1/rec/levels-1-9` 108, `stage1/rec/gameover-name` 48, `stage1/rec/levels-1-3` 36 and 1 more) |
| Called from | `BoxZoom` |
| Calls | `DrawBox` |
| Reads | `$732C` (`TextIndex`) |
| Writes | `$732C` (`TextIndex`) |

### `CompareScore` (`$AA0C`)

**A = 1 when the score at HL is greater than the one at DE**

Six digits, the most significant first. Witness: 11 calls.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 11 calls (`stage1/rec/idle-1p` 10, `stage1/rec/gameover-name` 1) |
| Called from | `EnterHiScore` |
| Reads | `$6ECE`-`$6ED0` (`PlayerScores`); `$97B9`-`$984B` (`HiScoreTable+10`) |

### `AttrAddr` (`$AA23`)

**HL = the attribute address of row H (from the bottom), column L**

HL = `$5B00` - 32 x (H + 1) + L. Witness: 2 112 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 48 calls, 25,128 t-states own (0.01 %) |
| Runs (the other recordings) | 2,064 calls (`stage1/rec/levels-1-9` 912, `stage1/rec/gameover-name` 480, `stage1/rec/levels-1-3` 336 and 4 more) |
| Called from | `DrawBox` |

### `FillAttrBlock` (`$AA37`)

**C rows of B attributes A from HL**

Witness: 24 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 7 calls, 32,943 t-states own (0.01 %) |
| Runs (the other recordings) | 17 calls (`stage1/rec/gameover-name` 6, `stage1/rec/tour-redefine` 4, `stage1/rec/tour-type2` 4 and 1 more) |
| Called from | `TitlePage`, `InstructionsPage`, `EnterHiScore` |
| Writes | `$5800`-`$5AFF` (screen) |

## keys

`src/game/keys.asm`

### `RedefineKeys` (`$AA49`)

**Take five new keys into key set 3**

ClearScreen, KeyType 3, ten bytes of KeySet3 cleared (the second jump key stays), the prompt and the five labels (MenuTexts), row 6 green; waits for no key; RedefineOne for up, down, left, right and jump (the attribute bar at `$592A` + 64 k, the name into InstructionsText's row 3, printed at row 14 - 2k column 22). Then the title scroller (JP TitleScrollerStart) over this page. Witness: tour-redefine 1.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 1 call (`stage1/rec/tour-redefine` 1) |
| Called from | `InstructionsPage` (tail) |
| Calls | `PrintChar`, `TitlePage` (tail), `ReadAnyKey`, `RedefineOne`, `ClearScreen` |
| Reads | `$AC02`-`$AC53` (`RedefinePrompt`, `KeyLabels`) |
| Writes | `$58C0`-`$58DF` (screen); `$732D` (`KeyType`); `$8268`-`$8271` (`KeySet3`) |

### `KeyUsed` (`$AABA`)

**B = 1 when the key just stored is already in key set 3**

Finds the set's last stored pair (the first zero after it) and compares it with the pairs before. B ends as the new pair's number (1-5) plus 1, so the walk back also compares the two pairs just before KeySet3: KeySet2's jump keys 4 (17 F7) and 9 (1D EF), which can never be chosen. KeySet3's sixth pair (the second jump key, 1) is never compared. Witness: 5 calls; redefine-odd, 9 refused at frame 112.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 5 calls (`stage1/rec/tour-redefine` 5) |
| Called from | `RedefineOne` |
| Reads | `$8265`-`$8271` (`KeySet2+9`, `KeySet3`) |

### `DeathPhrase` (`$AAE4`)

**Speak one of the eight DeathPhrases (R AND 7)**

Witness: 13 calls.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 13 calls (`stage1/rec/idle-1p` 5, `stage1/rec/gameover-name` 5, `stage1/rec/fall-death` 1 and 2 more) |
| Called from | `LifeLost` |
| Calls | `StartPhrase` (tail) |
| Reads | `$ABEA`-`$ABF1` (`DeathPhrases`) |

### `ReadAnyKey` (`$AAF4`)

**The one key held: L its row bits, H its port row, E the row number; HL = 0 for none or two rows**

Scans the eight rows `$FEFE` .. `$7FFE`. Witness: 24 310 calls.

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 24,310 calls (`stage1/rec/tour-redefine` 24,310) |
| Called from | `RedefineKeys`, `RedefineOne` |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `RedefineOne` (`$AB19`)

**Take one key into (IX), name it into (BC), print it at DE**

The bar (13 bytes of attribute 3 at HL), a key (ReadAnyKey) stored as (mask, port row); the name from KeyNames (row E, the bit of the key); a key already used is taken again; the name printed; waits for the release. Witness: 5 calls.

[Animation: `RedefineOne` at work](img/routines/RedefineOne.gif)

| | |
| --- | --- |
| Runs | not reached in `game`; in the other recordings 5 calls (`stage1/rec/tour-redefine` 5) |
| Called from | `RedefineKeys` |
| Calls | `PrintChar`, `KeyUsed`, `ReadAnyKey` |
| Reads | `$AC56`-`$AC72` (`KeyNames+2`) |
| Writes | `$592A`-`$5936` (screen); `$596A`-`$5976` (screen); `$59AA`-`$59B6` (screen); `$59EA`-`$59F6` (screen); `$5A2A`-`$5A36` (screen); `$8268`-`$8271` (`KeySet3`); 1 more ranges |

## menudata

`src/game/menudata.asm`

### `PlayTune` (`$AB60`)

**Play the tune at HL through the ROM's BEEP**

Each note: C the duration in tenths of a second (0 ends), B the pitch in semitones; STACK-A C, the calculator divides it by 10 (TuneCalc), STACK-A B, BEEP. Interrupts are off while BEEP runs. Witness: 393 notes (TitleTune in c1 and after a game, DeathTune at a life lost).

| | |
| --- | --- |
| Runs (the first recording's game window) | 68 calls, 6,008 t-states own (0.00 %) |
| Runs (the other recordings) | 325 calls (`stage1/rec/gameover-name` 125, `stage1/rec/idle-1p` 125, `stage1/rec/fall-death` 25 and 2 more) |
| Called from | `TitlePage`, `LifeLost`, `PlayTuneNote` (tail) |
| Reads | `$AE0C`-`$AE9B` (`TitleTune`, `DeathTune`) |

### `PlayTuneNote` (`$AB70`)

**The pitch, BEEP, the next note**

Witness: 379 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 67 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 4,668 t-states own (0.00 %) |
| Runs (the other recordings) | 312 runs of its first instruction, entered by a jump (`stage1/rec/gameover-name` 120, `stage1/rec/idle-1p` 120, `stage1/rec/fall-death` 24 and 2 more) |
| Calls | `PlayTune` (tail) |

### `ScrollLine` (`$AB7B`)

**Shift a character row of 30 bytes from HL one pixel left**

Eight lines, each byte takes bit 7 of the next. Registers kept. Witness: 49 502 calls (the scrollers and the messages).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,571 calls, 29,051,944 t-states own (11.47 %) |
| Runs (the other recordings) | 47,931 calls (`stage1/rec/idle-1p` 33,838, `stage1/rec/gameover-name` 5,059, `stage1/rec/levels-1-9` 3,311 and 4 more) |
| Called from | `TitleLoop`, `InstructionsPage`, `StartGame`, `Message` |
| Reads | `$4861`-`$4F7F` (screen); `$50E1`-`$57FF` (screen) |
| Writes | `$4861`-`$4F7E` (screen); `$50E1`-`$57FE` (screen) |

### `ClearScreen` (`$AB9E`)

**Clear the 6912 bytes of the screen**

Witness: 20 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 604,987 t-states own (0.24 %) |
| Runs (the other recordings) | 18 calls (`stage1/rec/idle-1p` 6, `stage1/rec/gameover-name` 6, `stage1/rec/tour-redefine` 3 and 3 more) |
| Called from | `TitlePage`, `InstructionsPage`, `LifeLost`, `RedefineKeys` |
| Writes | `$4000`-`$5AFF` (screen) |

### `DrawHiScores` (`$ABAD`)

**Print the high score table on the right half**

MenuTexts' title at row 23 column 16, the ten entries at rows 21, 19 .. 3, attribute `$17` on columns 16-31 of rows 0-20. Witness: 4 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 19,114 t-states own (0.01 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/gameover-name` 2, `stage1/rec/idle-1p` 1) |
| Called from | `TitlePage`, `EnterHiScore` |
| Calls | `PrintChar` |
| Reads | `$97AF`-`$984E` (`HiScoreTable`); `$ABF2`-`$AC01` (`MenuTexts`) |
| Writes | `$5810`-`$59BF` (screen); `$59D0`-`$59DF` (screen); `$59F0`-`$59FF` (screen); `$5A10`-`$5A1F` (screen); `$5A30`-`$5A3F` (screen); `$5A50`-`$5A5F` (screen); 2 more ranges |

## level

`src/game/level.asm`

### `SetupLevel` (`$AE9C`)

**Draw the level, set it up and enter MainLoop**

ClearScreen; the 21 rows of the map in play (LiveMap) at rows 0-20; the HUD digits into HudText: the level (Level + 1 in BCD), the bonus's thousands min(Level + 1, 9), the time's hundreds 9 - min(Level / 16, 5), the player; HudText printed; every player's score printed (AddScore B = 0 with ScoreScreenAddr per player), then the score in play reloaded; LastTenThousands. The hens: Hens set to `$FF`, then the HenTable row (none on Level 8-15, all 20 bytes from 24). HenDelay 1 and the low byte of RandomPtr 0 (one word store at `$AFB0`). The life icons (six at most) per player.

The colours: the HUD rows, the player's column white on red (`$17`, others `$0F`); the map's cells (CellAttributes). Harry at (`$64`, `$17`), the duck at (8, `$98`), the jump, the duck's speeds, the counters; BonusRunning, BonusDelay, TimeDelay, DuckDelay and PassCounter 1. KeyTable from the key set of KeyType; ScoreScreenAddr; LiftTable's record for the level into the first and into Lift1, Lift2 one third higher, Lift2Row `$43`. LevelPhrase, a pause, the icon of the life in play erased, JP MainLoop.

Witness: 35 calls.

[Animation: `SetupLevel` at work](img/routines/SetupLevel.gif)

[Animation: `SetupLevel` at work, spawn](img/routines/SetupLevel-spawn.gif)

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 8,223,603 t-states own (3.25 %) |
| Runs (the other recordings) | 34 calls (`stage1/rec/levels-1-9` 11, `stage1/rec/gameover-name` 8, `stage1/rec/idle-1p` 5 and 4 more) |
| Called from | `PlayLevel` |
| Calls | `MainLoop` (tail), `PrintChar`, `AddScore`, `FillAttrRow`, `LevelPhrase` |
| Reads | `$61A8`-`$6447` (`LiveMap`); `$6EC9`-`$6EF3` (`Score+1`, `PlayerScores`, `EggsLeft`, `PlayerEggs` and 3 more); `$732D`-`$734F` (`KeyType`, `KeyTable`, `Players`, `Player` and 14 more); `$8250`-`$8273` (`KeySets`, `KeySet2`, `KeySet3`); `$9470`-`$950F` (`HenTable+21`); `$9764`-`$97AA` (`HudText`, `LiftTable`); 1 more ranges |
| Writes | `$4000`-`$5AFF` (screen); `$6EC8`-`$6ECD` (`Score`); `$72D8`-`$72DC` (`HarryX`, `HarryY`, `HarryFrame`, `HarryDir` and 1 more); `$7325`-`$7370` (`JumpState`, `JumpDx`, `JumpCount`, `JumpDelay` and 33 more); `$976B`-`$978A` (`HudPlayer`, `LiftTable`) |

### `FillAttrRow` (`$B130`)

**B attributes A on row H (0-2 from the top), from column L**

Witness: 252 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 7 calls, 2,707 t-states own (0.00 %) |
| Runs (the other recordings) | 245 calls (`stage1/rec/levels-1-9` 77, `stage1/rec/gameover-name` 56, `stage1/rec/idle-1p` 35 and 4 more) |
| Called from | `SetupLevel` |
| Writes | `$5800`-`$585F` (screen) |

### `LevelPhrase` (`$B14F`)

**Speak one of the eight LevelPhrases (R AND 7)**

Witness: 35 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 84 t-states own (0.00 %) |
| Runs (the other recordings) | 34 calls (`stage1/rec/levels-1-9` 11, `stage1/rec/gameover-name` 8, `stage1/rec/idle-1p` 5 and 4 more) |
| Called from | `SetupLevel` |
| Calls | `StartPhrase` (tail) |
| Reads | `$B15F`-`$B166` (`LevelPhrases`) |

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
| Runs (the other recordings) | 96,585 calls (`stage1/rec/gameover-name` 41,463, `stage1/rec/idle-1p` 15,597, `stage1/rec/tour-redefine` 12,825 and 4 more) |
| Called from | `MainLoop` |
| Calls | `MapCellAt` |
| Reads | `$61A9`-`$61FC` (`LiveMap+1`); `$6220`-`$6263` (`LiveMap+120`); `$6280`-`$6283` (`LiveMap+216`); `$62A6`-`$62DC` (`LiveMap+254`); `$62F9`-`$62FC` (`LiveMap+337`); `$6313`-`$635B` (`LiveMap+363`); 2 more ranges |
| Writes | `$7325`-`$7327` (`JumpState`, `JumpDx`, `JumpCount`) |
