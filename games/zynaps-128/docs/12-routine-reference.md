# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/c1` (c1, the menu and six short games), `work/r1` (r1, the bot over level 1 with the weapons), `work/r2` (r2, homing missiles at the guardian). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the entries they cover. An entry no recording reached says so.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`leveldata`](11-data-reference.md#leveldata) | `$6800`-`$7E59` | 0 of 15 |
| [`effectdata`](11-data-reference.md#effectdata) | `$7E5A`-`$7F61` | 0 of 10 |
| [`gamevars`](11-data-reference.md#gamevars) | `$7F62`-`$7F9B` | 0 of 41 |
| [`playerdata`](11-data-reference.md#playerdata) | `$7F9C`-`$7FFF` | 0 of 3 |
| [`gameentry`](#gameentry) | `$8000`-`$8002` | 1 of 1 |
| [`systemvars`](11-data-reference.md#systemvars) | `$8003`-`$80E9` | 0 of 48 |
| [`handlertables`](11-data-reference.md#handlertables) | `$80EA`-`$8183` | 0 of 6 |
| [`controldata`](11-data-reference.md#controldata) | `$8184`-`$8230` | 0 of 15 |
| [`scoredata`](11-data-reference.md#scoredata) | `$8231`-`$82ED` | 0 of 6 |
| [`texts`](11-data-reference.md#texts) | `$82EE`-`$8515` | 0 of 1 |
| [`system`](#system) | `$8516`-`$85C9` | 4 of 4 |
| [`playfield`](#playfield) | `$85CA`-`$8845` | 12 of 13 |
| [`stars`](#stars) | `$8846`-`$8911` | 3 of 3 |
| [`scroll`](#scroll) | `$8912`-`$8C3A` | 15 of 16 |
| [`levels`](#levels) | `$8C3B`-`$8D34` | 1 of 1 |
| [`scenery`](#scenery) | `$8D35`-`$8EDA` | 11 of 12 |
| [`sprites`](#sprites) | `$8EDB`-`$90B4` | 21 of 21 |
| [`objgrid`](#objgrid) | `$90B5`-`$91EB` | 5 of 5 |
| [`waves`](#waves) | `$91EC`-`$9462` | 7 of 7 |
| [`movers`](#movers) | `$9463`-`$9929` | 30 of 31 |
| [`objutil`](#objutil) | `$992A`-`$9A5A` | 13 of 13 |
| [`player`](#player) | `$9A5B`-`$9C82` | 6 of 6 |
| [`weapons`](#weapons) | `$9C83`-`$9F87` | 16 of 16 |
| [`enemies`](#enemies) | `$9F88`-`$A0EA` | 3 of 3 |
| [`objects`](#objects) | `$A0EB`-`$A320` | 7 of 8 |
| [`print`](#print) | `$A321`-`$A488` | 23 of 24 |
| [`score`](#score) | `$A489`-`$A511` | 5 of 5 |
| [`menu`](#menu) | `$A512`-`$A6B5` | 12 of 12 |
| [`input`](#input) | `$A6B6`-`$A76E` | 2 of 2 |
| [`options`](#options) | `$A76F`-`$A7F6` | 3 of 3 |
| [`hiscore`](#hiscore) | `$A7F7`-`$A8BD` | 2 of 2 |
| [`panel`](#panel) | `$A8BE`-`$A9A0` | 3 of 5 |
| [`interrupts`](#interrupts) | `$A9A1`-`$AB12` | 13 of 13 |
| [`hud`](#hud) | `$AB13`-`$AC06` | 3 of 3 |
| [`events`](#events) | `$AC07`-`$AD65` | 21 of 21 |
| [`wavescript`](#wavescript) | `$AD66`-`$AF48` | 30 of 30 |
| [`rounds`](#rounds) | `$AF49`-`$B0FE` | 14 of 15 |
| [`mainloop`](#mainloop) | `$B0FF`-`$B2EF` | 21 of 22 |
| [`effects`](#effects) | `$B2F0`-`$B445` | 9 of 9 |
| [`tune`](#tune) | `$B446`-`$B4AE` | 3 of 5 |
| [`icons`](11-data-reference.md#icons) | `$B4AF`-`$B54E` | 0 of 1 |
| [`font`](11-data-reference.md#font) | `$B54F`-`$B6FE` | 0 of 1 |
| [`start`](#start) | `$B6FF`-`$B72E` | 1 of 1 |
| [`buffers`](11-data-reference.md#buffers) | `$B72F`-`$DFFF` | 0 of 4 |
| [`graphics`](11-data-reference.md#graphics) | `$E000`-`$F107` | 0 of 8 |
| [`records`](11-data-reference.md#records) | `$F108`-`$F7FF` | 0 of 10 |
| [`tables`](11-data-reference.md#tables) | `$F800`-`$FF00` | 0 of 8 |
| [`tunedata`](11-data-reference.md#tunedata) | `$FF01`-`$FFD3` | 0 of 6 |
| [`topcells`](11-data-reference.md#topcells) | `$FFD4`-`$FFFF` | 0 of 4 |

## gameentry

`src/game/gameentry.asm`

### `GameEntry` (`$8000`)

**JP Start: the set-up's way in**

Entered once by block 2's set-up after the move (JP GameStart at `$610B`; c1 frame 3313), a tail jump to Start (`$B6FF`). Nothing else jumps here. In the 48K the tape loader's relocation code jumped here.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1 call, 10 t-states own (0.00 %) |
| Calls | `Start` (tail) |

## system

`src/game/system.asm`

### `SetUpInterrupts` (`$8516`)

**Install the IM 2 vector table and seed the random number generator**

Fills the 257 bytes `$FE00-$FF00` with `$FD`, writes JP `$A9E4` at `$FDFD`, sets I = `$FE` and IM 2. Interrupts stay disabled (DI on entry): the caller enables them.

Then seeds RandomSeed (`$7F71-$7F75`): each byte is R XOR the matching ROM byte at `$0000-$0004`.

Input: none. Output: A, B, DE, HL changed. Called once from the start-up (48K c1: 1 entry).

With K-MOUSE the fill starts at `$FEE8` (the operand at `$851E`), past the mouse driver at `$FE00` (src/game/setup.asm).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1 call, 6,247 t-states own (0.00 %) |
| Called from | `InterruptSetup` |
| Writes | `$7F71`-`$7F75` (`RandomSeed`); `$FDFD`-`$FF00` (`InterruptJump`, `VectorTable`) |

### `Random` (`$8544`)

**Next random number in A**

A shift-register generator over the five bytes `$7F71-$7F75`: rotates `$7F75` right through carry, mixes the neighbour bytes (nibble swap, XOR) and shifts the bytes down; the new `$7F71` byte is returned in A.

BC, DE and HL are preserved by storing them into the operands of the three loads at the end (`$8581`, `$8584`, `$8587`), so the routine needs no stack beyond its own return address (it is called while SP points into data, e.g. from InitStars).

Output: A random byte, F changed. Callers all over the game (stars, enemies, effects): the most called helper.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,017 calls, 673,678 t-states own (0.09 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,116 calls, 372,744 t-states own (0.07 %) |
| Runs (r2, homing missiles at the guardian) | 21 calls, 7,014 t-states own (0.01 %) |
| Called from | `InitStars`, `MoveStars`, `LaunchWave`, `PathOpRandomSpeed`, `ScatterDebris`, `EnemyFire`, `PlayersSetup` |
| Reads | `$7F71`-`$7F75` (`RandomSeed`) |
| Writes | `$7F71`-`$7F75` (`RandomSeed`); `$8582`-`$8589` (`Random`) |

### `ClearScreen` (`$858B`)

**Fade out, then clear the attributes and the bitmap**

Calls FadeAttributes, waits for one frame, sets the border black, clears the attributes `$5800-$5AFF` to 0 and the bitmap `$4000-$57FF` to 0 (LD (HL),L with L = 0).

Input: none. Output: BC, DE, HL changed; interrupts enabled. 48K c1: 4 entries (between the screens of the attract cycle and the game start).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 54 calls, 10,275,128 t-states own (1.38 %) |
| Runs (r1, the bot over level 1 with the weapons) | 7 calls, 1,329,092 t-states own (0.24 %) |
| Called from | `MenuScreenSetup`, `SelectOnePlayer`, `HighScoreDone`, `RoundPlaySetup`, `CreditsPage`, `HiScorePage` |
| Calls | `FadeAttributes`, `InterruptJump` |
| Reads | `$4000`-`$5AFE` (screen); `$8599` (`ClearScreen`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$4000`-`$5AFF` (screen); `$5BEA`-`$5BFB` (system) |
| Ports out | `$00FE` |

### `FadeAttributes` (`$85AD`)

**Fade the whole attribute area to black in four steps**

Four passes over `$5800-$5AFF` (3 pages): each pass ANDs every attribute with the mask 7, 3, 1, 0 (the ink fades, paper and bright vanish at once), three frames (HALT) apart. Enables interrupts.

Output: BC, E, HL changed. Called by ClearScreen (48K c1: 4 entries).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 71 calls, 58,847,233 t-states own (7.90 %) |
| Runs (r1, the bot over level 1 with the weapons) | 8 calls, 6,589,436 t-states own (1.19 %) |
| Called from | `ClearScreen`, `EndOfPlay` |
| Calls | `InterruptJump` |
| Reads | `$5800`-`$5AFF` (screen); `$85B8`-`$85BA` (`FadeAttributes`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5800`-`$5AFF` (screen); `$5BE8`-`$5BF9` (system) |

## playfield

`src/game/playfield.asm`

### `DrawPlayfield` (`$85CA`)

**Draw the 18 rows of the playfield**

Saves SP into the operand of RenderDone, clears the padding balance (the operand of RowEnd), sets RowsLeft (`$7F6F`) = 18 and IX = SP = `$F12C` (the first row record), then enters RowStart.

The rows run as a chain of RETs: RowStart pushes the attributes and returns into the row's head span node; each span handler returns into the next node; the sentinel node (`$85E4`) returns into RowEnd; RowEnd moves to the next record and jumps to RowStart or, after 18 rows, to RenderDone.

Called from the play interrupt `$A9ED` once a pass (two frames) while playing (48K c2: 659 entries in 1500 frames, all from `$A9ED`).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 293,020 t-states own (0.04 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 314,678 t-states own (0.06 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 45,500 t-states own (0.06 %) |
| Called from | `l_A9FB` |
| Calls | `RowStart` (tail) |
| Writes | `$7F6F` (`RowsLeft`); `$85E1`-`$85E8` (`RenderDone`, `SentinelNode`, `RowEnd`) |

### `RenderDone` (`$85E0`)

**Restore the stack pointer and return to the frame handler**

The operand of LD SP is the SP that DrawPlayfield saved.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 64,400 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 69,160 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 10,000 t-states own (0.01 %) |
| Called from | `RowStar` (tail) |
| Calls | `PlayPass` |

### `RowEnd` (`$85E7`)

**End of a row: sprite strips, the star, padding, next row**

Reached by RET from the last span node. A = the padding balance (the operand, written at `$86BD`) + the row's glyph count (+8); kept in A'.

When the row has sprite strips (+`$15` the count, +`$16`/+`$17` the list) SP moves to the strip list and every strip entry is drawn by StripDraw; then RowStar draws the row's star.

Input: IX = the row record, B = the screen pixel high byte of the row. Output: falls through to the next row.

48K c2: 11592 entries (= 659 frames * 18 rows minus the frames cut short).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 57,960 calls, 5,129,728 t-states own (0.69 %) |
| Runs (r1, the bot over level 1 with the weapons) | 62,244 calls, 5,926,313 t-states own (1.07 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 779,431 t-states own (1.09 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1`, `SpanDraw0` |
| Calls | `StripNext`, `RowStar` (tail) |
| Reads | `$F12F`-`$F363` (`RowRecords`) |

### `StripNext` (`$8602`)

**Return into the next strip entry**

SP points at a strip entry whose first word is StripDraw: the RET starts it. The DJNZ at `$8679` loops here once per strip.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 28,797 calls, 287,970 t-states own (0.04 %) |
| Runs (r1, the bot over level 1 with the weapons) | 47,269 calls, 472,690 t-states own (0.09 %) |
| Runs (r2, homing missiles at the guardian) | 4,818 calls, 48,180 t-states own (0.07 %) |
| Called from | `RowEnd`, `StripDraw` (tail) |
| Calls | `StripDraw` |

### `StripDraw` (`$8603`)

**Draw one sprite strip into a character row**

A strip entry (built by BuildObjectStrips) holds: the link to the next entry, a word B'/C' (C' = the sprite's colour), the start position (H = the column count, saved in the operand of StripCellsDone; L = the first attribute cell), then the cell bytes.

Per cell: an attribute whose low six bits are 0 (an empty cell) gets the sprite colour and the eight lines are written plainly (StripCellPlain); an attribute below 8 (black ink on black paper) is skipped (StripCellSkip); otherwise the lines are ANDed into the scenery (StripCellMask) and the cell keeps the scenery colour.

A' (the row's glyph count) is incremented for every drawn cell, so the padding counts strips as glyphs.

48K c2: 7168 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 28,797 calls, 21,640,291 t-states own (2.91 %) |
| Runs (r1, the bot over level 1 with the weapons) | 47,269 calls, 36,802,408 t-states own (6.67 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 3,959,689 t-states own (5.52 %) |
| Called from | `StripNext` |
| Calls | `StripNext` (tail), `RowStar` |
| Reads | `$4062`-`$4065` (screen); `$4082`-`$4087` (screen); `$40A2`-`$40FF` (screen); `$4162`-`$4165` (screen); `$4182`-`$4187` (screen); `$41A2`-`$41FF` (screen); 34 more ranges |
| Writes | `$4039`-`$403F` (screen); `$4052`-`$40FF` (screen); `$4139`-`$413F` (screen); `$4152`-`$41FF` (screen); `$4239`-`$423F` (screen); `$4252`-`$42FF` (screen); 20 more ranges |

### `RowStar` (`$867B`)

**Draw the row's star, pad the row's time, step to the next row**

SP = the operand (saved at `$86E2`: the record + 8); SP + `$14` = the record + `$1C`: POP HL = the star's position (L) and screen high byte, POP AF = its flags (carry: visible) and colour.

A visible star on an empty attribute cell sets the attribute and writes a single dot on pixel line 3 (one byte B, the other lines cleared); on a used cell it XORs the dot into line 3 of the scenery.

Then the padding: A' - 4 left over is the new balance; a row cheaper than four glyphs waits 12 DJNZ loops per missing glyph (the Pentagon timing: 10 in the 48K). IX += 32, SP = IX; RowsLeft - 1; RowStart or RenderDone.

48K c2: 11592 entries (as RowEnd).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 57,960 calls, 16,928,243 t-states own (2.27 %) |
| Runs (r1, the bot over level 1 with the weapons) | 62,244 calls, 27,766,757 t-states own (5.03 %) |
| Runs (r2, homing missiles at the guardian) | 9,000 calls, 6,239,752 t-states own (8.70 %) |
| Called from | `RowEnd` (tail), `StripDraw` |
| Calls | `RenderDone` (tail), `RowStart` |
| Reads | `$435B`-`$43FF` (screen); `$4B01`-`$4BFF` (screen); `$5300`-`$531F` (screen); `$533F` (screen); `$5820`-`$5A5F` (screen); `$7F6F` (`RowsLeft`); 7 more ranges |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 12 more ranges |

### `RowStart` (`$86CE`)

**Start a row: beeper toggle, attributes, then the row's span nodes**

Toggles the beeper (RowBeep `$7F7E` XOR `$18`, AND the mask `$7F7F`, OUT `$FE`), 18 times a pass: the row part of the explosion noise. The mask is 0 (no sound) except for the 16 passes after an explosion or a big enemy's hit (SoundPattern1 `$7F80`).

A' = ShiftPage (`$7F6A`). POP DE = the map ring pointer (+0), HL = the attribute address of column 31 (+2), BC = the screen address of the row (+4), IY = the head node (+6); saves SP (the record + 8) in RowStar's operand.

SP = the attribute address + 1, then 16 PUSH DE of map bytes read downwards (DEC L wraps in the ring page): the 32 attributes of the row land in one go. A = C = the screen low byte (column 0), C = `$FF`. SP = IY: RET into the head node.

48K c2: 11862 entries.

On a 128K: the OUT (`$FE`),A at `$86D7` is made NOP: NOP: the row part of the explosion noise is gone (src/game/setup.asm, glue.asm; docs/13-differences-from-zynaps-48k.md).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 57,960 calls, 40,803,840 t-states own (5.48 %) |
| Runs (r1, the bot over level 1 with the weapons) | 62,244 calls, 43,819,776 t-states own (7.94 %) |
| Runs (r2, homing missiles at the guardian) | 9,000 calls, 6,336,000 t-states own (8.83 %) |
| Called from | `DrawPlayfield` (tail), `RowStar` |
| Calls | `RowEnd`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1`, `SpanDraw0` |
| Reads | `$7F6A` (`ShiftPage`); `$7F7E`-`$7F7F` (`RowBeep`, `RowBeepMask`); `$B700`-`$BFFF` (`Start`, `MapRingSpace`, `TileSource`) |
| Writes | `$7F7E` (`RowBeep`); `$867C`-`$867D` (`RowStar`) |

### `SpanDraw4` (`$873E`)

**Span node handler: a run of four glyphs**

Entered by RET with SP = node + 2. POP HL: L = the first glyph, H = the gap. A (the column) += gap, DE = the screen address, H = ShiftPage (A'): HL = the glyph's line 0.

Eight lines, the four bytes copied LDI, LDI, LDI, LD/INC on even lines and LDD back on odd lines (zigzag), INC H / INC D a line. Leaves A = the column after the run; POP HL = the next node, SP = it, RET.

The top cost of the game: 48K c2 18726 entries, 123 per mille of all instructions.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 89,153 calls, 55,096,554 t-states own (7.40 %) |
| Runs (r1, the bot over level 1 with the weapons) | 53,052 calls, 32,786,136 t-states own (5.94 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 265,740 t-states own (0.37 %) |
| Called from | `RowStart`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1` |
| Calls | `RowEnd`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1`, `SpanDraw0` |
| Reads | `$C000`-`$DFFE` (`TileSource`, `WaveCellSource`, `GlyphCacheUpper`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 17 more ranges |

### `SpanDraw3` (`$8797`)

**Span node handler: a run of three glyphs**

As SpanDraw4 with three bytes a line. 48K c2: 5790 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 16,481 calls, 8,075,690 t-states own (1.08 %) |
| Runs (r1, the bot over level 1 with the weapons) | 18,388 calls, 9,010,120 t-states own (1.63 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 36,260 t-states own (0.05 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw2`, `SpanDraw1` |
| Calls | `RowEnd`, `SpanDraw4`, `SpanDraw2`, `SpanDraw1`, `SpanDraw0` |
| Reads | `$C000`-`$DFFE` (`TileSource`, `WaveCellSource`, `GlyphCacheUpper`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 25 more ranges |

### `SpanDraw2` (`$87E0`)

**Span node handler: a run of two glyphs**

As SpanDraw4 with two bytes a line. 48K c2: 2306 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 13,283 calls, 4,808,446 t-states own (0.65 %) |
| Runs (r1, the bot over level 1 with the weapons) | 7,564 calls, 2,738,168 t-states own (0.50 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 2,896 t-states own (0.00 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw3`, `SpanDraw1` |
| Calls | `RowEnd`, `SpanDraw4`, `SpanDraw3`, `SpanDraw1`, `SpanDraw0` |
| Reads | `$C000`-`$DFFE` (`TileSource`, `WaveCellSource`, `GlyphCacheUpper`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 25 more ranges |

### `SpanDraw1` (`$8819`)

**Span node handler: one glyph**

As SpanDraw4 with one byte a line (LD A,(HL); LD (DE),A). 48K c2: 5328 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 23,556 calls, 5,512,104 t-states own (0.74 %) |
| Runs (r1, the bot over level 1 with the weapons) | 18,360 calls, 4,296,240 t-states own (0.78 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 59,436 t-states own (0.08 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2` |
| Calls | `RowEnd`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2`, `SpanDraw0` |
| Reads | `$C000`-`$DFFE` (`TileSource`, `WaveCellSource`, `GlyphCacheUpper`) |
| Writes | `$4020`-`$40C0` (screen); `$40DF`-`$40E0` (screen); `$40FF` (screen); `$4120`-`$41C0` (screen); `$41DF`-`$41E0` (screen); `$41FF` (screen); 41 more ranges |

### `SpanDraw0` (`$8842`)

**Span node handler: an empty node**

A node whose last glyph has scrolled out but which still links the row: skips the glyph/gap word and returns into the next node. 48K c2: 522 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,431 calls, 87,516 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,475 calls, 53,100 t-states own (0.01 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1` |
| Calls | `RowEnd` |

## stars

`src/game/stars.asm`

### `InitStars` (`$8846`)

**Give each of the 18 rows a random star**

Walks the records from the top with SP at record + `$20` and pushes, per row: +`$1E`/+`$1F` = F and the colour (`$47` XOR Random AND 3), +`$1C`/+`$1D` = L the row's screen low byte (`$20`, `$40`, ...) and H = `$20`, +`$1A`/+`$1B` = the speed (B = 16-47 from Random, C = `$E0`), +`$18`/+`$19` = E (Random bits 3-6 moved to 4-7, OR `$80`) and D = `$FF`.

MoveStars rewrites the fields every pass: +`$1C` = the cell's low byte and +`$1D` = the dot byte that RowStar draws, +`$1E` carry = visible.

Saves and restores SP through the operand of InitStarsDone. Output: all registers changed.

Called by LevelSetUp (`$8D30`) and StarsSwitch.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 65,772 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 7,308 t-states own (0.00 %) |
| Called from | `LevelSetUp` |
| Calls | `Random` |
| Writes | `$8881`-`$8882` (`InitStars`) |

### `StarsSwitch` (`$8884`)

**Turn the stars on (A = 1) or off (A = other) and restart them**

LD HL,`$81DA`; DEC A; set (A = 1) or reset PlayFlags bit 7; CALL InitStars. Not entered in 48K c1 or 48K c2: no caller found in the image (a leftover or a cheat entry).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MoveStars` (`$8894`)

**Move every star and respawn the ones that left the screen**

Writes the opcode of the dot-making instruction: XOR `$F8` gives SET n,B (PlayFlags bit 7 set: stars shown), XOR `$B8` gives RES n,B (no dot: the stars stay invisible). Saves SP into MoveStarsDone.

Per row (SP = the star fields): while scrolling (PlayFlags bit 5) the 16-bit position += speed (wrapping); a position below `$1000` respawns the star (new random colour and speed). The pixel bit within the byte comes from the position's low bits (written into StarDot's opcode), the screen byte from its high bits.

Called by the frame handler (48K c2: 659 entries, 37 per mille).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 18,917,129 t-states own (2.54 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 20,283,514 t-states own (3.67 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 2,882,497 t-states own (4.02 %) |
| Called from | `l_A9FB` |
| Calls | `Random` |
| Reads | `$81DA` (`ScriptState`); `$B700`-`$BFFF` (`Start`, `MapRingSpace`, `TileSource`) |
| Writes | `$88F5`-`$88FA` (`MoveStars`); `$890F`-`$8910` (`MoveStars`) |

## scroll

`src/game/scroll.asm`

### `AllocGlyphs` (`$8912`)

**Find C free glyph slots in a row of the glyph bitmap**

Starting from the last position (GlyphAllocMask `$8015` = the slot index, `$8016`/`$8017` = the bitmap byte and the bit mask), scans GlyphBitmap `$FFE0-$FFFF` for a clear bit, wrapping to `$FFE0` and rotating the mask. When the run of C slots would pass slot 255 it restarts at slot 0.

Output: E = the first slot (the glyph index), H/L = its bit mask and bitmap address, D = `$C0`; the allocator state advanced by C.

Called by NewSpanNode (48K c2: 307 entries).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,162 calls, 386,934 t-states own (0.05 %) |
| Runs (r1, the bot over level 1 with the weapons) | 761 calls, 136,109 t-states own (0.02 %) |
| Called from | `NewSpanNode` |
| Calls | `InterruptJump` |
| Reads | `$8015`-`$8017` (`GlyphAlloc`); `$FEFF`-`$FF00` (`VectorTable`); `$FFE0`-`$FFFF` (`ColumnFlags`) |
| Writes | `$5BE8`-`$5BE9` (system); `$8015`-`$8017` (`GlyphAlloc`) |

### `StartColumn` (`$894D`)

**Set up the column builder for a new column**

Returns at once unless PlayFlags bit 5 (scrolling) is set. Writes the builder's operands: IX = `$F34C` (the record of row 17), HL = ScrollColumn + `$880` (row 17's cell 8 pages on, + `$80`), 18 rows to go.

Called from the frame handler cycle (48K c2: 229 entries, one per scroll step).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,963 calls, 274,126 t-states own (0.04 %) |
| Runs (r1, the bot over level 1 with the weapons) | 977 calls, 126,340 t-states own (0.02 %) |
| Runs (r2, homing missiles at the guardian) | 125 calls, 4,797 t-states own (0.01 %) |
| Called from | `l_A9FB`, `ReplayStep` |
| Calls | `InterruptJump` |
| Reads | `$801C`-`$801D` (`ScrollColumn`); `$81DA` (`ScriptState`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF6`-`$5BF7` (system); `$896F`-`$8975` (`BuildColumn`) |

### `BuildColumn` (`$896D`)

**Build up to six cells of the new column, bottom row first**

Spreads the 18 rows of a column over three frames: B = 6 rows a call. Per row calls BuildCell, then IX -= 32 (the record above), L += `$80` and H - 1 every second row (two rows a ring page).

The operands keep the state between calls: the record (IX), the map pointer (HL) and the rows left (C). Returns at once with C = 0.

48K c2: 688 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,877 calls, 4,583,818 t-states own (0.62 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2,931 calls, 140,223 t-states own (0.03 %) |
| Runs (r2, homing missiles at the guardian) | 376 calls, 34,361 t-states own (0.05 %) |
| Called from | `ChainBuildColumn1`, `ChainBuildColumn2`, `ChainBuildColumn3`, `ReplayRoundEnd` |
| Calls | `BuildColumnLoop`, `BuildCell`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF4`-`$5BF5` (system); `$896F`-`$8975` (`BuildColumn`) |

### `BuildColumnLoop` (`$897A`)

**BuildColumnLoop**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 15,120 calls, 423,417 t-states own (0.08 %) |
| Called from | `BuildColumn`, `BuildColumnBack` (tail) |
| Calls | `BuildCell`, `InterruptJump` |

### `BuildColumnBack` (`$897E`)

**BuildColumnBack**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 1,511,331 t-states own (0.27 %) |
| Called from | `l_8A28` |
| Calls | `BuildColumnLoop` (tail), `ChainStep1End`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF4`-`$5BF5` (system); `$896F`-`$8975` (`BuildColumn`) |

### `BuildCell` (`$899E`)

**Turn one map cell of the new column into a glyph**

A = the cell's tile code. 0 (empty): when the row's previous column had a tile (+`$14` bit 7) the gap starts and the following cell's flag byte is set to "no attribute" (bit 7 set, bit 2 clear) when it is empty too; otherwise the empty-column count +`$13` grows (up to 32).

A tile: BuildGlyph. Input: IX = the row record, HL = the map cell. 48K c2: 3948 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 33,642 calls, 2,530,194 t-states own (0.34 %) |
| Runs (r1, the bot over level 1 with the weapons) | 15,120 calls, 1,151,911 t-states own (0.21 %) |
| Runs (r2, homing missiles at the guardian) | 114 calls, 10,419 t-states own (0.01 %) |
| Called from | `BuildColumn`, `BuildColumnLoop` |
| Calls | `BuildGlyph` (tail), `InterruptJump` |
| Reads | `$B700`-`$BFFF` (`Start`, `MapRingSpace`, `TileSource`); `$F12C`-`$F2CC` (`RowRecords`); `$F2DF`-`$F2EC` (`RowRecords`); `$F2FF`-`$F30C` (`RowRecords`); `$F31F`-`$F32C` (`RowRecords`); `$F33F`-`$F34C` (`RowRecords`); 2 more ranges |
| Writes | `$5BF0`-`$5BF1` (system); `$B702`-`$B92F` (`Start`, `MapRingSpace`); `$B94F`-`$B9A8` (`MapRingSpace`); `$B9D0`-`$BA28` (`MapRingSpace`); `$BA87`-`$BAA7` (`MapRingSpace`); `$BC37` (`TileSource`); 10 more ranges |

### `BuildGlyph` (`$89C9`)

**Build one glyph of the new column in all four shifts**

The left neighbour is the row's last glyph (+`$0F`) when the previous column had a tile (+`$14` bit 7), else a blank line of the tile set. Takes a new span node and glyph run when the current run is used up (+`$12`, NewSpanNode).

The cell's flag byte (the map byte at the row pointer + 1): bit 0 = upside down (source + `$700` and DEC D instead of INC D at GlyphLineStep), bit 1 = mirrored (each line through BitReverse `$FB00`: the LD A,(HL) at GlyphMirror, else NOP).

Writes the 8 lines at shift 0 (page `$C0` + line), shift 2 (SET 3,D), shift 4 (SET 4,D) and shift 6 (RES 3,D), each the 16-bit pair left:new shifted left 2, 4, 6 pixels. Sets the slot's bit in GlyphBitmap and +`$14` bit 6 (glyph added: the scroll step widens the tail node).

48K c2: 1025 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 7,118 calls, 14,836,425 t-states own (1.99 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2,509 calls, 844,123 t-states own (0.15 %) |
| Called from | `BuildCell` (tail) |
| Calls | `GlyphLine`, `NewSpanNode`, `InterruptJump` |
| Reads | `$5C00`-`$5E77` (system); `$5E98`-`$5F77` (system); `$5F98`-`$6077` (system); `$6098`-`$6177` (system); `$6198`-`$6277` (system); `$6298`-`$6377` (system); 18 more ranges |
| Writes | `$5BEC`-`$5BF1` (system); `$8A1D`-`$8A1F` (`GlyphLineStep`); `$C000`-`$DFFE` (`TileSource`, `WaveCellSource`, `GlyphCacheUpper`); `$F13B`-`$F220` (`RowRecords`); `$F29B`-`$F2C0` (`RowRecords`); `$F2DB`-`$F2E0` (`RowRecords`); 5 more ranges |

### `GlyphLine` (`$8A1C`)

**GlyphLine**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 20,072 calls, 140,523 t-states own (0.03 %) |
| Called from | `BuildGlyph`, `l_8A28` (tail) |
| Calls | `GlyphLineStep`, `InterruptJump` |
| Reads | `$5C00`-`$5E7E` (system); `$5E96`-`$5F7E` (system); `$5F96`-`$607E` (system); `$6096`-`$617E` (system); `$6196`-`$627E` (system); `$6296`-`$637E` (system); 2 more ranges |
| Writes | `$5BDC`-`$5BDD` (system) |

### `GlyphLineStep` (`$8A1D`)

**GlyphLineStep**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 20,073 calls, 1,154,461 t-states own (0.21 %) |
| Called from | `GlyphLine`, `l_AB07` |
| Calls | `l_8A28`, `InterruptJump` |
| Reads | `$5C00`-`$5D00` (system); `$5E00` (system); `$5F00` (system); `$6000` (system); `$6100` (system); `$6200` (system); 8 more ranges |
| Writes | `$5BDC`-`$5BDD` (system); `$5BEE`-`$5BEF` (system); `$C000`-`$C7FE` (`TileSource`, `WaveCellSource`) |

### `l_8A28` (`$8A28`)

**l_8A28**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 20,073 calls, 3,082,954 t-states own (0.56 %) |
| Called from | `GlyphLineStep`, `l_AB07` |
| Calls | `BuildColumnBack`, `GlyphLine` (tail), `InterruptJump` |
| Reads | `$F13C`-`$F220` (`RowRecords`); `$F29C`-`$F2A0` (`RowRecords`); `$F2BC`-`$F2C0` (`RowRecords`); `$F2DC`-`$F2E0` (`RowRecords`); `$F2FC`-`$F300` (`RowRecords`); `$F31C`-`$F320` (`RowRecords`); 4 more ranges |
| Writes | `$5BEC`-`$5BEF` (system); `$C800`-`$DFFE` (`GlyphCacheUpper`); `$F13C`-`$F220` (`RowRecords`); `$F29D`-`$F2A0` (`RowRecords`); `$F2BD`-`$F2C0` (`RowRecords`); `$F2DC`-`$F2E0` (`RowRecords`); 5 more ranges |

### `NewSpanNode` (`$8A5A`)

**Link a new span node at the row's tail and reserve its glyph run**

Takes a node from the pool (PopNode), links it after the tail (+`$0D`/+`$0E`), sets its gap = the empty-column count (+`$13`), width 0, handler SpanDraw0, counts it (+`$0A`), resets +`$13` to 1. The link store in the previous node is done with interrupts off (DI unless the frame phase `$7F65` is 4).

Measures the run of tiles that follows in the map (up to 4) into +`$12` and reserves as many glyph slots (AllocGlyphs); the first glyph index goes to the node (+2), the slot mask and address to +`$10`/+`$11`.

48K c2: 307 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,162 calls, 1,623,465 t-states own (0.22 %) |
| Runs (r1, the bot over level 1 with the weapons) | 761 calls, 570,764 t-states own (0.10 %) |
| Called from | `BuildGlyph` |
| Calls | `AllocGlyphs`, `PopNode`, `InterruptJump` |
| Reads | `$7F65` (`PassPhase`); `$B700`-`$B9FF` (`Start`, `MapRingSpace`); `$BA41`-`$BA68` (`MapRingSpace`); `$BAC1`-`$BAE7` (`MapRingSpace`); `$BC25`-`$BC2C` (`TileSource`); `$BC72`-`$BC77` (`TileSource`); 9 more ranges |
| Writes | `$5BEA`-`$5BED` (system); `$F132`-`$F21F` (`RowRecords`); `$F292`-`$F2BF` (`RowRecords`); `$F2D2`-`$F2DF` (`RowRecords`); `$F2F2`-`$F2FF` (`RowRecords`); `$F312`-`$F31F` (`RowRecords`); 3 more ranges |

### `PopNode` (`$8AD0`)

**Take a span node from the free list**

Output: DE = the node, NodeFreeList (`$7F68`) = the node's link. HL preserved. 48K c2: 307 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,162 calls, 209,733 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | 761 calls, 73,817 t-states own (0.01 %) |
| Called from | `NewSpanNode` |
| Calls | `InterruptJump` |
| Reads | `$7F68`-`$7F69` (`NodeFreeList`); `$F800`-`$FA19` (`NodePool`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BE8`-`$5BE9` (system); `$7F68`-`$7F69` (`NodeFreeList`) |

### `PushNode` (`$8ADF`)

**Return the span node HL to the free list**

The node's first word = the old NodeFreeList, NodeFreeList = HL. DE preserved. 48K c2: 230 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,294 calls, 120,342 t-states own (0.02 %) |
| Runs (r1, the bot over level 1 with the weapons) | 735 calls, 68,355 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 16 calls, 1,488 t-states own (0.00 %) |
| Called from | `ScrollStep` |
| Reads | `$7F68`-`$7F69` (`NodeFreeList`) |
| Writes | `$7F68`-`$7F69` (`NodeFreeList`); `$F800`-`$FA19` (`NodePool`) |

### `ScrollStep` (`$8AED`)

**Scroll the playfield model one step (two pixels) left**

Returns unless PlayFlags bit 5. ScrollCount (`$81DB`) + 1, ScriptRoom (`$801F`) + 1, EmptyRows (`$7F70`) = 0.

Per row record (IX from `$F12C`, C = 18): an empty row counts in EmptyRows. Else the head node's gap - 1; when it goes negative the leftmost glyph leaves: its bitmap bit is freed (+`$0B`/+`$0C`), the glyph count +8 - 1 and the node width - 1; a node of width 0 is unlinked and returned to the pool (PushNode), and when the row loses its last node the tail is reset to the record (+`$0D` = IX + 2). The handler follows the width (SetSpanHandler).

When the column builder added a glyph (+`$14` bit 6) the tail node grows by one.

The new leading attribute: the map byte at the row pointer + 1 is a flag byte; bit 2 set: bit 7 set = paper and bright from it, ink from the previous cell; bit 7 clear = ink from bits 3-5 and bright from bit 6, paper from the previous cell; bit 2 clear: bit 7 set = 0 (black), bit 7 clear = the previous cell's attribute. The pointer + 1.

Then ScrollColumn + 1, `$8022` + 1, the column 31 places ahead (the cell (ScrollColumn + `$1F`) AND `$3F` in all four quarters of the 9 ring pages) cleared, and a delay of EmptyRows - 9 units that pads the step's time.

Called from the frame handler cycle (48K c2: 228 entries).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,945 calls, 14,922,404 t-states own (2.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 975 calls, 7,010,309 t-states own (1.27 %) |
| Runs (r2, homing missiles at the guardian) | 125 calls, 51,349 t-states own (0.07 %) |
| Called from | `l_A9FB`, `ReplayRoundEnd` |
| Calls | `PushNode`, `SetSpanHandler`, `InterruptJump` |
| Reads | `$7F70` (`EmptyRows`); `$801C`-`$8022` (`ScrollColumn`, `ScriptColumn`, `ScriptRoom`, `ScriptBusy` and 2 more); `$81DA`-`$81DC` (`ScriptState`); `$B700`-`$BFFF` (`Start`, `MapRingSpace`, `TileSource`); `$F12C`-`$F360` (`RowRecords`); `$F802`-`$FA1E` (`NodePool`); 2 more ranges |
| Writes | `$5BF6`-`$5BF7` (system); `$7F70` (`EmptyRows`); `$801C`-`$8022` (`ScrollColumn`, `ScriptColumn`, `ScriptRoom`, `ScriptBusy` and 2 more); `$81DB`-`$81DC` (`ScriptState`); `$B700`-`$BFFF` (`Start`, `MapRingSpace`, `TileSource`); `$F12C`-`$F360` (`RowRecords`); 2 more ranges |

### `SetSpanHandler` (`$8C1C`)

**Point the node IY at the handler for its width**

Handler = SpanHandlers[(IY+6)] into the node's first word. 48K c2: 1559 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 10,057 calls, 1,237,448 t-states own (0.17 %) |
| Runs (r1, the bot over level 1 with the weapons) | 4,207 calls, 517,537 t-states own (0.09 %) |
| Runs (r2, homing missiles at the guardian) | 8 calls, 984 t-states own (0.00 %) |
| Called from | `ScrollStep` |
| Calls | `InterruptJump` |
| Reads | `$8C33`-`$8C3A` (`SpanHandlers`); `$F806`-`$FA1E` (`NodePool`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF4`-`$5BF5` (system); `$F800`-`$FA19` (`NodePool`) |

## levels

`src/game/levels.asm`

### `LevelSetUp` (`$8C3B`)

**Reset the playfield model at the start of a level or life**

Chains the 95 nodes of the pool `$F800` (the free list in `$7F68`, `$FAF8` = `$FFFF` the end), clears the 576 bytes of RowRecords (`$F12C-$F36B`) and fills each of the 18 records: +0/+1 the map pointer (`$B71F`, `$B79F`, `$B81F`, ... two rows a page), +2/+3 the attribute address of column 31 (`$583F` + 32 row), +4/+5 the screen address (`$4020` ...), +6/+7 the head SentinelNode, +`$0D`/+`$0E` the tail = record + 2, +`$13` = 32 empty columns, +`$12` = 1.

Clears the map ring `$B700-$BFFF`, ScrollColumn = `$B760`, `$8022` = `$B730`, GlyphBitmap `$FFE0-$FFFF` = 0; builds BitReverse (`$FB00`: each byte with its bits reversed).

Sets the six fields `$8075` + 3k to `$FF`, `$8072-$8074` = 5, 6, 3, clears `$8087`, `$8024`, `$8025`, `$80BD`, `$80BE` and the six bytes `$7EFF` + 16k; then, with interrupts off, calls `$91C6` and InitStars.

Called from the level start `$AF49` (48K c2: 1 entry).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 2,349,214 t-states own (0.32 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 261,028 t-states own (0.05 %) |
| Called from | `LevelStart` |
| Calls | `InitStars`, `ClearHitGrid`, `InterruptJump` |
| Reads | `$B700`-`$BFFE` (`Start`, `MapRingSpace`, `TileSource`); `$F12C`-`$F36A` (`RowRecords`); `$FEFF`-`$FF00` (`VectorTable`); `$FFE0`-`$FFFE` (`ColumnFlags`) |
| Writes | `$5BF8`-`$5BF9` (system); `$7EFF`-`$7F4F` (`SpriteCache`); `$7F68`-`$7F69` (`NodeFreeList`); `$801C`-`$8025` (`ScrollColumn`, `ScriptColumn`, `ScriptRoom`, `ScriptBusy` and 4 more); `$8072`-`$8087` (`FreeEnemySlots`, `WavesAllowed`, `EnemyShotsLeft`, `WaveRecords` and 1 more); `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); 4 more ranges |

## scenery

`src/game/scenery.asm`

### `StartScript` (`$8D35`)

**Set up the scenery coroutine for a level**

Script stack top `$FDFB` holds the entry ScriptMain, ScriptSP (`$801A`) = `$FDFB`, ScriptBusy (`$8020`) = 0; falls into ResumeScript. Called from the level start `$AF49` (48K c2: 1 entry).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 1,242 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 138 t-states own (0.00 %) |
| Called from | `LevelStart` |
| Calls | `ResumeScript` |
| Writes | `$801A`-`$8020` (`ScriptSP`, `ScrollColumn`, `ScriptColumn`, `ScriptRoom` and 1 more); `$FDFB`-`$FDFC` (`ScriptStackTop`) |

### `ResumeScript` (`$8D45`)

**Run the scenery script when 16 more columns have scrolled**

When ScriptBusy is 0: returns unless ScriptRoom >= 16; then ScriptRoom - 16, ScriptColumn + 16, ScriptBusy = `$FF`. Saves the main SP (`$8018`), switches to ScriptSP and RETs into the script; it returns here through YieldScript.

Called from the frame handler cycle `$AA96` (48K c2: 524 entries) and from the catch-up loop `$AF90`/`$AF96`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,084 calls, 328,692 t-states own (0.04 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2,066 calls, 131,582 t-states own (0.02 %) |
| Runs (r2, homing missiles at the guardian) | 251 calls, 14,809 t-states own (0.02 %) |
| Called from | `StartScript`, `PlayPass`, `ReplayRound` |
| Calls | `ScriptMain` |
| Reads | `$801A`-`$8020` (`ScriptSP`, `ScrollColumn`, `ScriptColumn`, `ScriptRoom` and 1 more) |
| Writes | `$8018`-`$8020` (`MainSP`, `ScriptSP`, `ScrollColumn`, `ScriptColumn` and 2 more) |

### `YieldScript` (`$8D69`)

**Switch from the script back to the main stack**

ScriptSP = SP, SP = the main SP: the RET returns to ResumeScript's caller. 48K c2: 90 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 784 calls, 39,200 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 227 calls, 11,350 t-states own (0.00 %) |
| Called from | `ScriptStep`, `DrawGroup` |
| Calls | `PlayChain`, `ReplayScroll`, `ReplayRoundEnd` |
| Reads | `$8018`-`$8019` (`MainSP`) |
| Writes | `$801A`-`$801B` (`ScriptSP`) |

### `ScriptMain` (`$8D72`)

**The coroutine's body: run the level's script for ever**

A = ScriptNumber (`$81DD`), RunScript, again. Its first RET came from StartScript; 48K c2 shows no entry because the loop never ends during a level (1 dispatch at the start).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 540 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 9 calls, 330 t-states own (0.00 %) |
| Called from | `ResumeScript`, `ScriptMainAgain` (tail) |
| Calls | `RunScript` |
| Reads | `$81DD` (`ScriptState`) |

### `ScriptMainAgain` (`$8D78`)

**ScriptMainAgain**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 108 t-states own (0.00 %) |
| Called from | `ScriptStep` |
| Calls | `ScriptMain` (tail) |

### `RunScript` (`$8D7A`)

**Run the script A**

HL = the script's address from the word table `$72E1`, then ScriptStep. 48K c2: 4 entries (the main script and its sub-scripts).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 38 calls, 2,280 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 15 calls, 900 t-states own (0.00 %) |
| Called from | `ScriptMain`, `ScriptStep` |
| Calls | `ScriptStep` |
| Reads | `$72E3`-`$72E6` (`SceneryScriptTable`); `$7321`-`$7326` (`SceneryScriptTable`) |

### `ScriptStep` (`$8D86`)

**Interpret the script bytes at HL**

Below `$80`: DrawGroup n, ScriptBusy = 0, YieldScript, go on. `$FF`: return. `$80` n: call script n (ScriptVariant saved and restored, ScriptReturn). `$A0-$AF`: ScriptVariant = the low nibble moved to the high nibble. Other `$81-$9F`: ScriptSetCell (the pattern n AND 7).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 40 calls, 20,406 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 19 calls, 7,290 t-states own (0.00 %) |
| Called from | `RunScript`, `ScriptReturn` (tail) |
| Calls | `YieldScript`, `ScriptMainAgain`, `RunScript`, `DrawGroup`, `ScriptSetCell` |
| Reads | `$732F`-`$733C` (`SceneryScripts`); `$745B`-`$7475` (`SceneryScripts`); `$8020`-`$8021` (`ScriptBusy`, `ScriptVariant`) |
| Writes | `$8020`-`$8021` (`ScriptBusy`, `ScriptVariant`) |

### `ScriptReturn` (`$8DC3`)

**ScriptReturn**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 90 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 180 t-states own (0.00 %) |
| Calls | `ScriptStep` (tail) |
| Writes | `$8021` (`ScriptVariant`) |

### `DrawGroup` (`$8DCA`)

**Place the object group A into the map ring**

Returns at once when SkipDraw (`$7F76`) bit 0 is set (the catch-up after a life lost runs the scripts without drawing).

The group (word table `$749A`) is a list: a byte with bit 7 set and not `$FF` = a sub-group (the next byte) taken only when its bit 6 AND ScriptVariant is non-zero (recursion); `$FF` = end; otherwise an object of 3 bytes: the first byte (bits 0-4 the row, bits 5-7 the flags: bit 0 = flipped, bit 1 = mirrored), a variant/column byte (low nibble the column; ANDed with ScriptVariant), the shape number (the word table `$7783`).

For each object the shape's cells are written column by column (PlaceColumn), with the direction of the row and column steps written into `$8E94`, `$8EBF` and `$8EC0` for the flip and mirror, then YieldScript after every column, so the placement spreads over the frames.

48K c2: 15 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 124 calls, 553,295 t-states own (0.07 %) |
| Runs (r1, the bot over level 1 with the weapons) | 53 calls, 148,290 t-states own (0.03 %) |
| Called from | `ScriptStep` |
| Calls | `YieldScript`, `PlaceColumn`, `InterruptJump` |
| Reads | `$749A`-`$749B` (`GroupTable`); `$74D6`-`$74E7` (`GroupTable`); `$7514` (`ObjectGroups`); `$7615`-`$76DD` (`ObjectGroups`); `$7785`-`$77BE` (`ShapeTable`); `$783A` (`Shapes`); 13 more ranges |
| Writes | `$8E94` (`DrawGroup`); `$8EAD` (`PlaceColumn`); `$8EBF`-`$8EC0` (`PlaceColumn`); `$FDEB`-`$FDEC` (`ScriptStack`) |

### `PlaceColumn` (`$8EA1`)

**Write one shape column into the map ring**

The column's header byte: bit 0 set = an attribute follows from the table at H = `$FF` (OR with the flags at PlaceFlags, stored into PlaceAttr). Then per cell a bit of the mask byte: set = the tile code goes to (DE) and the attribute to (BC); E and C step by PlaceStepE/PlaceStepC (INC or DEC, written by DrawGroup). A 0 bit ends the column.

48K c2: 209 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,601 calls, 823,941 t-states own (0.11 %) |
| Runs (r1, the bot over level 1 with the weapons) | 431 calls, 217,109 t-states own (0.04 %) |
| Called from | `DrawGroup` |
| Calls | `InterruptJump` |
| Reads | `$783B`-`$78A6` (`Shapes`); `$78BE`-`$7940` (`Shapes`); `$796A`-`$7A0F` (`Shapes`); `$FEFF`-`$FF00` (`VectorTable`); `$FFD8`-`$FFDE` (`WorkGlyph`) |
| Writes | `$8EBB` (`PlaceColumn`); `$B700`-`$BA26` (`Start`, `MapRingSpace`); `$BA41`-`$BA66` (`MapRingSpace`); `$BA81`-`$BAA5` (`MapRingSpace`); `$BAC1`-`$BAE5` (`MapRingSpace`); `$BC25`-`$BC35` (`TileSource`); 4 more ranges |

### `ScriptSetCell` (`$8EC5`)

**Copy the 8-byte cell pattern A to WorkCell**

HL = `$72A9` + 8A, 8 bytes to `$FFD8`. 48K c2: 1 entry.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 4,482 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 249 t-states own (0.00 %) |
| Called from | `ScriptStep` |
| Reads | `$72B9`-`$72C0` (`CellPatterns`) |
| Writes | `$FFD8`-`$FFDF` (`WorkGlyph`) |

## sprites

`src/game/sprites.asm`

### `BuildCellSprite` (`$8EDB`)

**Build a column-major sprite of C columns of B cells, complemented, with blank borders**

DE - 8 gets a blank (FillBlankCell), then per column B cells of 8 bytes copied from HL complemented (CPL), and a blank cell after every column; then B blank cells at the end.

Input: HL = the source glyphs, DE = the destination, B = the cells a column, C = the columns. 48K c2: 5 entries (frames 102-1274, from `$ACD9`), writing `$E748-$E757` and `$E760-$E76F` from `$64E0-$64FF` and `$65E0-$65FF`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 31 calls, 53,661 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 27 calls, 47,546 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 2,540 t-states own (0.00 %) |
| Called from | `LoadCellSprite` |
| Calls | `FillBlankCell` |
| Reads | `$6440`-`$645F` (system); `$64A0`-`$64FF` (system); `$6560`-`$657F` (system); `$65E0`-`$65FF` (system); `$66B0`-`$66DF` (system) |
| Writes | `$E748`-`$E787` (`SpriteCacheImages`); `$E988`-`$E9AF` (`SpriteCacheImages`) |

### `FillBlankCell` (`$8EFF`)

**Write a blank cell: eight `$FF` bytes at DE**

A and BC preserved. 48K c2: 30 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 186 calls, 47,616 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 163 calls, 41,728 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 7 calls, 1,792 t-states own (0.00 %) |
| Called from | `BuildCellSprite` |
| Writes | `$E740`-`$E747` (`BallSprite`); `$E758`-`$E75F` (`SpriteCacheImages`); `$E770`-`$E7A7` (`SpriteCacheImages`); `$E980`-`$E987` (`SpriteCacheImages`); `$E998`-`$E99F` (`SpriteCacheImages`); `$E9B0`-`$E9CF` (`SpriteCacheImages`) |

### `BuildBigSprite` (`$8F0C`)

**Build a 7 x 9 cell image at `$C000` from a one-bit cell map**

A = 1: the glyphs come from `$66E0` (linear, INC HL) and the cell map from the 9 bytes at `$8098`; otherwise from the tile set at `$5CDC` (interleaved: INC H, then LD H,C; INC L after each glyph) and the map at `$80A1`. The step instructions are written into BigSpriteStep and BigSpriteNext. Not run in 48K c1/c2; 48K r1 runs it 6 times (frames 16855-66273), from LoadCellSprite `$ACD9` for the big enemies (kinds `$14` and up).

Each map bit (7 a byte, 9 bytes) set = the next glyph complemented (BigSpriteCell), clear = a blank cell. Called from `$ACD9` when its A >= `$14`. Not entered in 48K c1 or 48K c2: probably the end-of-level guardian.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BigSpriteCell` (`$8F4B`)

**Copy one glyph complemented to DE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RotateSprite` (`$8F5A`)

**Rotate a column-major image one pixel right, the last bit wrapping to the first byte**

Input: HL = the image, C = its height in lines (also the column stride), B = its width in bytes. Each line is shifted right one pixel across its B bytes; the bit that falls out of the last byte goes into bit 7 of the first.

Called from `$AD44` (48K c2: 35 entries).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 217 calls, 2,387 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 189 calls, 2,079 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 7 calls, 77 t-states own (0.00 %) |
| Called from | `SpriteBuildShifts`, `SpriteShiftCopy` |
| Calls | `RotateLine` |

### `RotateLine` (`$8F5D`)

**RotateLine**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,209 calls, 57,326 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 4,542 calls, 49,915 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 168 calls, 4,368 t-states own (0.01 %) |
| Called from | `RotateSprite`, `RotateNextByte` (tail), `l_8F6D` (tail), `l_AB07` |
| Calls | `RotateLineSave`, `RotateByte`, `InterruptJump` |

### `RotateLineSave` (`$8F5E`)

**RotateLineSave**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,210 calls, 57,326 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 4,537 calls, 68,040 t-states own (0.01 %) |
| Called from | `RotateLine`, `l_AB07` |
| Calls | `RotateLineCarry`, `RotateByte`, `InterruptJump` |

### `RotateLineCarry` (`$8F5F`)

**RotateLineCarry**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,210 calls, 20,832 t-states own (0.00 %) |
| Called from | `RotateLineSave`, `l_AB07` |
| Calls | `RotateByte` |

### `RotateByte` (`$8F60`)

**RotateByte**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 15,626 calls, 62,515 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 13,783 calls, 55,142 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 672 calls, 22,867 t-states own (0.03 %) |
| Called from | `RotateLine`, `RotateLineSave`, `RotateLineCarry`, `RotateNextByte` (tail), `l_AB07` |
| Calls | `RotateByteShift`, `RotateNextByte`, `InterruptJump` |
| Reads | `$E7A8`-`$EA47` (`SpriteCacheImages`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BE6`-`$5BE7` (system); `$E7A8`-`$EA47` (`SpriteCacheImages`) |

### `RotateByteShift` (`$8F61`)

**RotateByteShift**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 15,625 calls, 234,493 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | 13,778 calls, 206,697 t-states own (0.04 %) |
| Called from | `RotateByte`, `l_AB07` |
| Calls | `RotateByteOut`, `InterruptJump` |
| Reads | `$E790`-`$EBC7` (`SpriteCacheImages`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BE6`-`$5BE7` (system); `$E790`-`$EBC7` (`SpriteCacheImages`) |

### `RotateByteOut` (`$8F63`)

**RotateByteOut**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 15,631 calls, 62,515 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 13,779 calls, 55,142 t-states own (0.01 %) |
| Called from | `RotateByteShift`, `l_AB07` |
| Calls | `l_8F64`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BE6`-`$5BE7` (system) |

### `l_8F64` (`$8F64`)

**l_8F64**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 15,625 calls, 171,902 t-states own (0.02 %) |
| Runs (r1, the bot over level 1 with the weapons) | 13,778 calls, 151,669 t-states own (0.03 %) |
| Called from | `RotateByteOut`, `l_AB07` |
| Calls | `RotateNextByte`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BE6`-`$5BE7` (system) |

### `RotateNextByte` (`$8F65`)

**RotateNextByte**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 15,625 calls, 229,209 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | 13,783 calls, 265,424 t-states own (0.05 %) |
| Runs (r2, homing missiles at the guardian) | 672 calls, 17,339 t-states own (0.02 %) |
| Called from | `RotateByte`, `l_8F64`, `l_AB07` |
| Calls | `RotateLine` (tail), `RotateByte` (tail), `RotateLineMerge`, `RotateLineNext`, `InterruptJump` |
| Reads | `$E790`-`$E99F` (`SpriteCacheImages`); `$E9D0`-`$E9FF` (`SpriteCacheImages`); `$EA18`-`$EA2F` (`SpriteCacheImages`); `$EA60`-`$EA77` (`SpriteCacheImages`); `$EAA8`-`$EABF` (`SpriteCacheImages`); `$EAF0`-`$EB07` (`SpriteCacheImages`); 3 more ranges |
| Writes | `$5BE6`-`$5BE9` (system); `$E790`-`$E99F` (`SpriteCacheImages`); `$E9D0`-`$EA2F` (`SpriteCacheImages`); `$EA60`-`$EA77` (`SpriteCacheImages`); `$EAA8`-`$EABF` (`SpriteCacheImages`); `$EAF0`-`$EB07` (`SpriteCacheImages`); 2 more ranges |

### `RotateLineMerge` (`$8F68`)

**RotateLineMerge**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,209 calls, 72,969 t-states own (0.01 %) |
| Called from | `RotateNextByte`, `l_AB07` |
| Calls | `RotateLineNext`, `InterruptJump` |
| Reads | `$E790`-`$E957` (`SpriteCacheImages`); `$E9D0`-`$E9E7` (`SpriteCacheImages`); `$EA18`-`$EA2F` (`SpriteCacheImages`); `$EA60`-`$EA77` (`SpriteCacheImages`); `$EAA8`-`$EABF` (`SpriteCacheImages`); `$EAF0`-`$EB07` (`SpriteCacheImages`); 3 more ranges |
| Writes | `$5BE8`-`$5BE9` (system); `$E790`-`$E957` (`SpriteCacheImages`); `$E9D0`-`$EA2F` (`SpriteCacheImages`); `$EA60`-`$EA77` (`SpriteCacheImages`); `$EAA8`-`$EABF` (`SpriteCacheImages`); `$EAF0`-`$EB07` (`SpriteCacheImages`); 2 more ranges |

### `RotateLineNext` (`$8F6A`)

**RotateLineNext**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,211 calls, 83,366 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 4,537 calls, 72,614 t-states own (0.01 %) |
| Called from | `RotateNextByte`, `RotateLineMerge`, `l_AB07` |
| Calls | `RotateLineCount`, `InterruptJump` |

### `RotateLineCount` (`$8F6C`)

**RotateLineCount**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,210 calls, 20,851 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 4,538 calls, 18,163 t-states own (0.00 %) |
| Called from | `RotateLineNext`, `l_AB07` |
| Calls | `l_8F6D`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BEA`-`$5BEB` (system) |

### `l_8F6D` (`$8F6D`)

**l_8F6D**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,209 calls, 61,449 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 4,537 calls, 53,620 t-states own (0.01 %) |
| Called from | `RotateLineCount`, `l_AB07` |
| Calls | `RotateLine` (tail), `l_8F6F`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BEA`-`$5BEB` (system) |

### `l_8F6F` (`$8F6F`)

**l_8F6F**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 218 calls, 2,170 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 190 calls, 1,890 t-states own (0.00 %) |
| Called from | `l_8F6D`, `l_AB07` |
| Calls | `SpriteShiftNext` |

### `ClearStripCounts` (`$8F70`)

**Clear the sprite-strip count of the 18 row records**

0 into +`$15` of every record (`$F141` + 32k). 48K c2: 660 entries (from ObjectStrips).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 1,117,340 t-states own (0.15 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 1,199,926 t-states own (0.22 %) |
| Runs (r2, homing missiles at the guardian) | 501 calls, 173,847 t-states own (0.24 %) |
| Called from | `ObjectStrips` |
| Writes | `$F141` (`RowRecords`); `$F161` (`RowRecords`); `$F181` (`RowRecords`); `$F1A1` (`RowRecords`); `$F1C1` (`RowRecords`); `$F1E1` (`RowRecords`); 12 more ranges |

### `ObjectStrips` (`$8F9B`)

**Cut every active object into sprite strips**

ClearStripCounts, then the 16 objects from IY = `$F600` down by 44 bytes: an active object (+8 bit 7) goes through BuildObjectStrips. One beeper toggle per object (ObjectBeep `$7F82` XOR `$18`, AND the mask `$7F83`): the strip part of the explosion noise, silent while the mask is 0.

Called from the frame handler cycle `$AA96` (48K c2: 660 entries).

On a 128K: the OUT (`$FE`),A at `$8FBD` is made NOP: NOP: the strip part of the explosion noise is gone (src/game/setup.asm, glue.asm; docs/13-differences-from-zynaps-48k.md).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 6,798,483 t-states own (0.91 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 7,561,284 t-states own (1.37 %) |
| Runs (r2, homing missiles at the guardian) | 501 calls, 1,065,495 t-states own (1.48 %) |
| Called from | `PlayPass` |
| Calls | `ClearStripCounts`, `BuildObjectStrips` |
| Reads | `$7F82`-`$7F83` (`ObjectBeep`, `ObjectBeepMask`); `$F374`-`$F4D4` (`PlayerObject`, `EnemyObjects`, `EnemyShots`); `$F500` (`LaserShots`); `$F52C` (`LaserShots`); `$F558` (`LaserShots`); `$F584` (`LaserShots`); 3 more ranges |
| Writes | `$7F82` (`ObjectBeep`) |

### `BuildObjectStrips` (`$8FC2`)

**Link the strips of the object IY into the row records**

The object's sprite definition (+0/+1) is a list of words read with POP: the base image, the frame stride (times the frame +2), a stride and mask for the sub-frame (+3 bits 5-7), the height and the line length. The rows are clipped against the playfield (+4 - 16, 32 rows); an object fully out has +8 bit 5 cleared (BuildStripsOff), else it is set (visible).

The column (+5 bits 5-7) moves the start; +6 gives the shift; +`$25` the colour. The strip entries go onto the object's strip buffer (+9/+10, as a stack); +`$0B` is a bit mask of the rows the object covers: each set bit adds a strip to that row's list (+`$15` count + 1, +`$16`/+`$17` linked).

Saves SP into BuildStripsDone. 48K c2: 3327 entries, 46 per mille.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 11,351 calls, 17,239,321 t-states own (2.32 %) |
| Runs (r1, the bot over level 1 with the weapons) | 20,078 calls, 29,533,290 t-states own (5.35 %) |
| Runs (r2, homing missiles at the guardian) | 2,000 calls, 3,067,768 t-states own (4.28 %) |
| Called from | `ObjectStrips` |
| Reads | `$90A5`-`$90A6` (`BuildObjectStrips`); `$F141`-`$F283` (`RowRecords`); `$F2A1`-`$F2A3` (`RowRecords`); `$F2C1`-`$F2C3` (`RowRecords`); `$F2E1`-`$F2E3` (`RowRecords`); `$F301`-`$F303` (`RowRecords`); 11 more ranges |
| Writes | `$9093`-`$9094` (`BuildObjectStrips`); `$90A5`-`$90A6` (`BuildObjectStrips`); `$F141`-`$F2A3` (`RowRecords`); `$F2C1`-`$F2C3` (`RowRecords`); `$F2E1`-`$F2E3` (`RowRecords`); `$F301`-`$F303` (`RowRecords`); 11 more ranges |

## objgrid

`src/game/objgrid.asm`

### `FindFreeObjectSlot` (`$90B5`)

**find a free record among the 16 from `$F36C` (unused)**

IY = the first of the 16 records of 44 bytes from `$F36C` whose +`$08` bit 7 (active) is clear, NC; carry when all 16 are in use. Nothing in the image calls or jumps here and no recording ran it (0 executions in 48K c1, 48K c2): a left-over; the wave launcher uses TakeEnemySlot (`$938D`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MarkEnemyGrid` (`$90CB`)

**mark the 8 enemy slots' collision bits in the grid**

Called from PlayPass `$AA96` in the odd phases (1 and 3), every other pass (331 entries in 48K c2's 659 passes). C = the collision bit, 1 for the slot `$F398` and rotated left for each next slot, so slot n owns bit n. For each active and visible slot (+`$08` bits 7 and 5): its sprite descriptor (+0/+1, IX) gives the width +`$0B` and the height +`$08`; the X position (+3/+4, in 1/4 columns) picks the first of the X bytes at `$FC00`, every 4th byte over the width plus the last gets the bit; the Y position (+5/+6, in 1/8 rows) picks the Y byte at `$FD00`, every 8th byte over the height gets the bit, the rows whose bit in the row mask +`$0B` is clear excepted (a big enemy's rows out of play).

Reads the records with SP (POP IX, POP HL); SP is kept in the operand at `$9144`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,615 calls, 2,574,391 t-states own (0.35 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,730 calls, 3,374,297 t-states own (0.61 %) |
| Runs (r2, homing missiles at the guardian) | 251 calls, 300,426 t-states own (0.42 %) |
| Called from | `PlayPass` |
| Reads | `$7EA9`-`$7EAC` (`ExplosionAnim`); `$7EC3`-`$7EC6` (`PodAnim`); `$7EDD`-`$7EE0` (`ShotDescriptor`); `$7EFA`-`$7F0D` (`SpriteCache`); `$7F3A`-`$7F3D` (`SpriteCache`); `$F3A0`-`$F3A3` (`EnemyObjects`); 9 more ranges |
| Writes | `$9144`-`$9145` (`MarkEnemyGrid`); `$FC38`-`$FCCA` (`HitGridX`); `$FD02`-`$FD8D` (`HitGridY`) |

### `TestHitGrid` (`$9150`)

**the overlap masks of the player, the shots and the weapons**

Called from `$A9ED` in phases 2-4 (494 entries in 48K c2's 659 passes, 2 % of play's time). For the 8 records from `$F36C` (the player, then `$F4F8` = `$F36C` + `$018C` and every 44 bytes on: the four laser shots, the plasma/missile slots `$F5A8` and `$F5D4`, the sight `$F600`): OR of the X bytes over the width (the player's width less one) and OR of the Y bytes over the height (4 bytes an eighth of a row step, read with POP); the AND of both is the set of enemy bits this record touches, stored in +`$0D`. The union for the first five records (the player and the lasers), active ones only, goes into `$80BB`, the laser-hit mask the enemy handlers test. SP is kept in the operand at `$91C3`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,409 calls, 10,319,518 t-states own (1.39 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2,593 calls, 11,105,799 t-states own (2.01 %) |
| Runs (r2, homing missiles at the guardian) | 375 calls, 1,606,252 t-states own (2.24 %) |
| Called from | `l_A9FB` |
| Reads | `$7E9C`-`$7E9F` (`ShipDescriptor`); `$7EB6`-`$7EB9` (`SightDescriptor`); `$7ED0`-`$7EE0` (`LaserDescriptor`, `ShotDescriptor`); `$F373`-`$F374` (`PlayerObject`); `$F4FF`-`$F500` (`LaserShots`); `$F52B`-`$F52C` (`LaserShots`); 5 more ranges |
| Writes | `$80BB` (`LaserHitMask`); `$91C3`-`$91C4` (`TestHitGrid`); `$F379` (`PlayerObject`); `$F505` (`LaserShots`); `$F531` (`LaserShots`); `$F55D` (`LaserShots`); 4 more ranges |

### `ClearHitGrid` (`$91C6`)

**clear the collision grid `$FC00-$FD8F`**

Pushes 200 zero words down from `$FD90` (20 x 10 PUSH HL): the X bytes `$FC00-$FCFF` and the Y bytes `$FD00-$FD8F`. Called from `$8C3B`, `$A9ED` and `$B03A` (496 entries in 48K c2). SP is kept in the operand at `$91DF`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,445 calls, 6,166,290 t-states own (0.83 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2,597 calls, 6,549,634 t-states own (1.19 %) |
| Runs (r2, homing missiles at the guardian) | 375 calls, 945,750 t-states own (1.32 %) |
| Called from | `LevelSetUp`, `l_A9FB`, `RoundPlaySetup` |
| Writes | `$91DF`-`$91E0` (`ClearHitGrid`) |

### `JumpTable` (`$91E2`)

**jump to the word number A of the table at HL**

HL = the word at HL + 2A, JP (HL); DE is spoilt. The routine reached returns to JumpTable's caller. Used by the object loop (`$80FA`), the path interpreter (`$8114`, `$8124`), the player's side weapon (`$80EA`), the pod (`$80F0`) and the routines at `$AC0E`, `$AD66`, `$ADF4`, `$B0FF` and `$B21C`. 6080 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 21,500 calls, 1,161,000 t-states own (0.16 %) |
| Runs (r1, the bot over level 1 with the weapons) | 37,551 calls, 2,027,754 t-states own (0.37 %) |
| Runs (r2, homing missiles at the guardian) | 2,773 calls, 149,742 t-states own (0.21 %) |
| Called from | `RunObjects`, `RunPath`, `PathOpExtended`, `PlayerHandler`, `EventAny`, `WaveScriptStep`, `ScriptTest`, `EndOfPlay`, `EffectAfterJobs` |
| Calls | `PathOpExtended`, `PathOpAccelerate`, `PathOpSetLoop`, `PathOpSetInterval`, `PathOpHomePlayer`, `PathOpSetDirection`, `PathOpScroll`, `PathOpLoop`, `PathOpDriftMiddle`, `PathOpMove`, `PathOpToCentre`, `PathOpLand`, `PathOpRandomSpeed`, `PlayerHandler`, `PlasmaFrame`, `HomingFrame`, `PodSpeedUp`, `PodPlasma`, `PodHoming`, `SightHandler`, `LaserHandler`, `PlasmaHandler`, `MissileHandler`, `EnemyHandler`, `LockableHandler`, `ExplosionStep`, `PodStep`, `EnemyShotStep`, `PodIconJob`, `ScoreJob`, `SpriteBuildJob`, `CondNonZero`, `CmdScrollStop`, `CmdLevelEnd`, `CmdStore`, `CmdDecrement`, `CmdCheckpoint`, `CmdResetRecords`, `CmdEnemiesLeft`, `PlayerDied`, `LevelDone` |
| Reads | `$80EA`-`$813B` (`SideWeaponFrames`, `PodActions`, `KindHandlers`, `PathOps` and 1 more); `$81C7`-`$81D4` (`EventHandlers`); `$8203`-`$8228` (`ScriptCommands`, `ScriptConditions`); `$B111`-`$B114` (`EndHandlers`) |

## waves

`src/game/waves.asm`

### `LaunchWave` (`$91EC`)

**start wave A: the template, the wave record, the objects**

A = the wave number. Refused (NC) when no enemy slot is free (`$8072` = 0) or no wave record is allowed (`$8073` = 0); else `$8073` - 1, the first free wave record at `$8075` (first byte `$FF`) is taken with count 0 and its index kept in A'. `$6926`[A] = the index n; at `$6943` + 2n: the bonus byte (record +1: bits 6-7 the drop type, bits 0-5 the bonus score), then the sprite kind (bit 7: all objects take the next byte as their path, else the kind itself) and the object count; the path numbers fill `$806A`.

The template `$803E` is zeroed, its target (+`$29`) = the player `$F36C`; `$6A65` + 8 x kind gives +`$18`, the speed level (combined with the weapon rating `$80E9` to pick 3 bytes of `$6B15` for +`$19`, +`$20`/+`$21`, +`$22`), the score index (+`$0C`) and the speed (+`$17`) nibbles, the X acceleration (+`$10`), the Y acceleration (+`$14`), the handler kind (+`$07`), the colour (+`$25`) and the hit points (+`$0D`). GetSpriteCache gives the descriptor (+0/+1), its +`$0F` goes to +`$23` and its +`$0C` to the row mask +`$0B`; +`$02` = 1, +`$1A` = the wave record.

Then for each object: TakeEnemySlot, count + 1, the template copied over the slot (bytes +`$09`/+`$0A` and the slot's own collision bit +`$24` kept), the target of the next object = this one, the path pointer from `$6800`/`$681C`, the start delay +`$1B` = D (each next object E frames later), active and visible, X and Y from the stream (a Y of `$FF` = a random row). At the end the descriptor's use count +`$0D` grows by the objects launched, the border/speaker gets OUT (`$FE`),0, carry. 9 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 39 calls, 226,771 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | 91 calls, 377,688 t-states own (0.07 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 3,711 t-states own (0.01 %) |
| Called from | `WaveScriptStep` |
| Calls | `Random`, `TakeEnemySlot`, `GetSpriteCache` |
| Reads | `$6802`-`$6813` (`PathStarts`); `$6928`-`$6939` (`WaveIndex`); `$6953`-`$695C` (`WaveDefinitions`); `$6973`-`$6996` (`WaveDefinitions`); `$69BB`-`$69C4` (`WaveDefinitions`); `$69D9`-`$69DE` (`WaveDefinitions`); 17 more ranges |
| Writes | `$7EFF`-`$7F0F` (`SpriteCache`); `$7F3F` (`SpriteCache`); `$803E`-`$8083` (`WaveTemplate`, `WavePaths`, `FreeEnemySlots`, `WavesAllowed` and 2 more); `$931B`-`$931C` (`LaunchWave`); `$F398`-`$F473` (`EnemyObjects`) |
| Ports out | `$00FE` |

### `TakeEnemySlot` (`$938D`)

**take one free enemy slot from `$F398` on**

NC (Z) when `$8072`, the free enemy slots, is 0; else `$8072` - 1 and IY = the first record from `$F398` whose +`$08` bit 7 is clear, carry. The count guarantees one is found. 25 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 97 calls, 18,893 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 181 calls, 30,524 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 107 t-states own (0.00 %) |
| Called from | `LaunchWave` |
| Reads | `$8072` (`FreeEnemySlots`); `$F3A0` (`EnemyObjects`); `$F3CC` (`EnemyObjects`); `$F3F8` (`EnemyObjects`); `$F424` (`EnemyObjects`); `$F450` (`EnemyObjects`) |
| Writes | `$8072` (`FreeEnemySlots`) |

### `GetSpriteCache` (`$93A7`)

**the sprite descriptor of kind A, cached or queued**

A = the kind. From `$14` up: HL = `$7EE2` (record 0) with a load queued each time. Else the 6 records from `$7EF2` are searched for a used one (+`$0D` not 0) of this kind (+`$0E` & `$7F`); found: HL = that record. Not found: a free record is picked from `$8088` by the use mask `$8087` (the low nibble, the high one for kinds with bit 4), the least used record evicted (EvictSpriteCache) when none is free; the record is queued for building (QueueSpriteLoad), +`$0E` = kind | `$80`, +`$0F` + `$10`, and its bit set in `$8087`. 7 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 39 calls, 25,005 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 67 calls, 27,474 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 732 t-states own (0.00 %) |
| Called from | `LaunchWave` |
| Calls | `SpriteCacheRecord`, `SpriteCacheRet` (tail), `QueueSpriteLoad` |
| Reads | `$7EFF`-`$7F4F` (`SpriteCache`); `$8087`-`$808A` (`SpriteCacheMask`, `SpriteCacheFree`) |
| Writes | `$7F00`-`$7F11` (`SpriteCache`); `$7F40`-`$7F41` (`SpriteCache`); `$8087` (`SpriteCacheMask`) |

### `SpriteCacheRecord` (`$940A`)

**HL = `$7EE2` + 16 x B**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 39 calls, 1,953 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 67 calls, 3,429 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 135 t-states own (0.00 %) |
| Called from | `GetSpriteCache` |
| Calls | `SpriteCacheRet` |

### `SpriteCacheRet` (`$9413`)

**SpriteCacheRet**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 71 calls, 710 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 94 calls, 940 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 2 calls, 20 t-states own (0.00 %) |
| Called from | `GetSpriteCache` (tail), `SpriteCacheRecord` |

### `EvictSpriteCache` (`$9414`)

**free the least used sprite-cache record**

The used record with the smallest use count +`$0D` among the 6 from `$7EF2` (read at `$7EFF` + 16 n) is cleared and its number (+`$0F` low nibble) removed from the use mask `$8087`. Not run in 48K c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `QueueSpriteLoad` (`$9441`)

**queue the sprite record DE of kind C for building**

The ring at `$8026` (8 entries of 3 bytes: the kind, the record address), index `$8025` + 1 mod 8; bit 7 of `$81C5` tells the renderer a request is waiting. HL = the record on return. 5 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 32 calls, 6,560 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 27 calls, 5,535 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 205 t-states own (0.00 %) |
| Called from | `GetSpriteCache` |
| Reads | `$8025` (`DrawQueueWrite`); `$81C5` (`EventRequests`) |
| Writes | `$8025`-`$803D` (`DrawQueueWrite`, `DrawQueue`); `$81C5` (`EventRequests`) |

## movers

`src/game/movers.asm`

### `RunObjects` (`$9463`)

**run every active object's handler, with the slot toggle of the explosion noise**

Called once a pass from `$AA96` (659 entries in 48K c2, 5.7 % of play's time without the handlers). The landing flag `$974C` is freed (bit 7), the player (`$F36C`) runs by its kind, then the 15 slots from `$F600` down in steps of -44 (DE = `$FFD4`); C counts the slots not active.

After the loop the per-frame hit masks are cleared: `$80BB` (lasers and player), `$80E3` (the homing missile), `$80E4` (the sight), `$80E5` (plasma and seeker), the player's +`$0D` (`$F379`) and the +`$0D` of the 7 records from `$F4F8` (lasers, side weapons, sight; `$F505` on).

On a 128K: the OUT (`$FE`),A at `$949C` is made NOP: NOP: the slot part of the explosion noise is gone (src/game/setup.asm, glue.asm; docs/13-differences-from-zynaps-48k.md).

[Animation: `RunObjects` at work](img/routines/RunObjects.gif)

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 36,507,398 t-states own (4.90 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 26,949,611 t-states own (4.88 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 5,421,297 t-states own (7.56 %) |
| Called from | `PlayPass` |
| Calls | `JumpTable` |
| Reads | `$7F86`-`$7F87` (`SlotBeep`, `SlotBeepMask`); `$974C` (`LandingFlag`); `$F373` (`PlayerObject`); `$F39F`-`$F4D4` (`EnemyObjects`, `EnemyShots`); `$F4FF`-`$F500` (`LaserShots`); `$F52B`-`$F52C` (`LaserShots`); 5 more ranges |
| Writes | `$7F86` (`SlotBeep`); `$80BB` (`LaserHitMask`); `$80E3`-`$80E5` (`MissileHitMask`, `SightMask`, `PlasmaHitMask`); `$974C` (`LandingFlag`); `$F379` (`PlayerObject`); `$F505` (`LaserShots`); 6 more ranges |

### `RunPath` (`$94CB`)

**run the path bytecode of the object IY for one frame**

Frames left +`$1B` - 1: 0 fetches the next command; a count that was already 0 (forever) stays 0. The command +`$1C` goes to JumpTable(`$8114`) with C = the command: carry from the routine runs RunPath again (the next command in the same frame), NC ends it. Called by EnemyHandler, LockableHandler and BigEnemyHandler (1405 entries in 48K c2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,066 calls, 670,615 t-states own (0.09 %) |
| Runs (r1, the bot over level 1 with the weapons) | 7,986 calls, 1,069,528 t-states own (0.19 %) |
| Runs (r2, homing missiles at the guardian) | 142 calls, 18,165 t-states own (0.03 %) |
| Called from | `EnemyHandler`, `LockableHandler` |
| Calls | `JumpTable` |
| Reads | `$6826`-`$682F` (`PathCode`); `$6856`-`$6866` (`PathCode`); `$687E`-`$688B` (`PathCode`); `$68AC`-`$68C1` (`PathCode`); `$F3B3`-`$F3B6` (`EnemyObjects`); `$F3DF`-`$F3E2` (`EnemyObjects`); 3 more ranges |
| Writes | `$F3B3`-`$F3B6` (`EnemyObjects`); `$F3DF`-`$F3E2` (`EnemyObjects`); `$F40B`-`$F40E` (`EnemyObjects`); `$F437`-`$F43A` (`EnemyObjects`); `$F463`-`$F466` (`EnemyObjects`) |

### `PathOpExtended` (`$9509`)

**command 7: bits 3-6 pick one of 16 routines from `$8124`**

1151 executions in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 260,820 t-states own (0.04 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 381,120 t-states own (0.07 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 720 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `JumpTable` |

### `PathReadWord` (`$9516`)

**DE = the next word of the path**

Used by PathOpLoop for its jump target. Not run in 48K c1/c2; 48K r1 (all levels) runs it: 180 entries.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 8 calls, 1,064 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 2 calls, 266 t-states own (0.00 %) |
| Called from | `PathOpLoop` |
| Reads | `$68BA`-`$68BB` (`PathCode`); `$F3B5`-`$F3B6` (`EnemyObjects`) |
| Writes | `$F3B5`-`$F3B6` (`EnemyObjects`) |

### `PathOpAccelerate` (`$9529`)

**command 0: accelerate by the flags in C, then move**

C bit 3: Vx += Ax; bit 4: Vx -= Ax; bit 5: Vy += Ay; bit 6: Vy -= Ay. Then X += Vx, Y += Vy; NC. Also the plain move of the player (C from the joystick), PathOpBounce, PathOpDriftMiddle, PathOpToCentre and PlasmaHandler (C = `$20`, gravity). 1918 executions in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,438 calls, 2,467,532 t-states own (0.33 %) |
| Runs (r1, the bot over level 1 with the weapons) | 5,643 calls, 2,897,122 t-states own (0.52 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 263,250 t-states own (0.37 %) |
| Called from | `JumpTable`, `PathOpDriftMiddle`, `PathOpToCentre`, `PlayerHandler`, `PlasmaHandler` |
| Reads | `$F36F`-`$F381` (`PlayerObject`); `$F39B`-`$F3AD` (`EnemyObjects`); `$F3C7`-`$F3D9` (`EnemyObjects`); `$F3F3`-`$F405` (`EnemyObjects`); `$F41F`-`$F431` (`EnemyObjects`); `$F44B`-`$F45D` (`EnemyObjects`); 1 more ranges |
| Writes | `$F36F`-`$F37F` (`PlayerObject`); `$F39B`-`$F3AB` (`EnemyObjects`); `$F3C7`-`$F3D7` (`EnemyObjects`); `$F3F3`-`$F403` (`EnemyObjects`); `$F41F`-`$F42F` (`EnemyObjects`); `$F44B`-`$F45B` (`EnemyObjects`); 1 more ranges |

### `PathOpSetLoop` (`$9591`)

**command 1: the loop counter +`$1F` = P**

Carry: an instant command. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 168 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 56 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Writes | `$F3B7` (`EnemyObjects`); `$F43B` (`EnemyObjects`) |

### `PathOpSetInterval` (`$959C`)

**command 2: the homing interval +`$27` = +`$28` = P**

Carry. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 3,750 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Writes | `$F3BF`-`$F3C0` (`EnemyObjects`); `$F3EB`-`$F3EC` (`EnemyObjects`); `$F417`-`$F418` (`EnemyObjects`); `$F443`-`$F444` (`EnemyObjects`); `$F46F`-`$F470` (`EnemyObjects`) |

### `PathOpBounce` (`$95AA`)

**command 3: move, bouncing off the scenery**

With scenery under the object (SceneryAt6): only X moves. Else Y moves with the Y acceleration added (C = `$20`, a fall); if that lands it on the scenery or below row 15 the move is undone and Vy reversed (a bounce). NC. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpHomePlayer` (`$95FC`)

**command 4: home on the player, turn rate P**

The target +`$29`/+`$2A` = the player `$F36C`, the turn rate +`$2B` = P, then PathOpHome. NC. Not run in 48K c1/c2; 48K r1 (all levels) runs it: 1 entries.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 6,050 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PathOpHome` |
| Writes | `$F3C1`-`$F3C3` (`EnemyObjects`); `$F3ED`-`$F3EF` (`EnemyObjects`); `$F419`-`$F41B` (`EnemyObjects`); `$F445`-`$F447` (`EnemyObjects`); `$F471`-`$F473` (`EnemyObjects`) |

### `PathOpSetDirection` (`$9613`)

**command 5: direction (C & `$78`) / 2, then move**

+`$16` = P x 4 (0-60), velocities from the speed +`$17` (SetVelocity), one move; NC. 20 executions in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 6,060 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 14,140 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PathOpMove`, `SetVelocity` |
| Reads | `$F3AF` (`EnemyObjects`); `$F3DB` (`EnemyObjects`); `$F407` (`EnemyObjects`); `$F433` (`EnemyObjects`); `$F45F` (`EnemyObjects`) |
| Writes | `$F3AE` (`EnemyObjects`); `$F3DA` (`EnemyObjects`); `$F406` (`EnemyObjects`); `$F432` (`EnemyObjects`); `$F45E` (`EnemyObjects`) |

### `PathOpHomeTarget` (`$9625`)

**command 6: home on the target, the player once it is gone**

The target record +`$29`: no longer active, or of kind 3, makes it PathOpHomePlayer; else turn rate P and PathOpHome. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpScroll` (`$9640`)

**extended 0: move with the landscape when it scrolls**

Bit 0 of `$7F6C` set (a frame the playfield scrolls one step): X - `$40` (a quarter column); NC. 251 executions in 48K c2: the ground objects.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 159 calls, 257,922 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | 691 calls, 158,700 t-states own (0.03 %) |
| Runs (r2, homing missiles at the guardian) | 316 calls, 10,428 t-states own (0.01 %) |
| Called from | `JumpTable`, `PodStep` |
| Reads | `$7F6C` (`ScrollThisPass`); `$F39B`-`$F39C` (`EnemyObjects`); `$F3C7`-`$F3C8` (`EnemyObjects`); `$F3F3`-`$F3F4` (`EnemyObjects`); `$F41F`-`$F420` (`EnemyObjects`); `$F44B`-`$F44C` (`EnemyObjects`) |
| Writes | `$F39B`-`$F39C` (`EnemyObjects`); `$F3C7`-`$F3C8` (`EnemyObjects`); `$F3F3`-`$F3F4` (`EnemyObjects`); `$F41F`-`$F420` (`EnemyObjects`); `$F44B`-`$F44C` (`EnemyObjects`) |

### `PathOpStop` (`$9658`)

**extended 1: stop**

Vx = Vy = 0; the flags of XOR A: NC. Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpRandomDirection` (`$9666`)

**extended 2: a random direction, then move**

+`$16` = random & `$3F`, the velocities for the speed +`$17`, one move; NC. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpLoop` (`$9679`)

**extended 3: loop back to the word target while +`$1F` counts down**

Reads the target word; +`$1F` - 1: not 0 = the path pointer goes to the target; carry either way (the next command runs at once). Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 762 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 202 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PathReadWord` |
| Reads | `$F3B7` (`EnemyObjects`) |
| Writes | `$F3B5`-`$F3B7` (`EnemyObjects`) |

### `PathOpDriftMiddle` (`$9689`)

**extended 4: accelerate towards row 8**

Above row 8: C = `$20` (Vy + Ay), else `$40` (Vy - Ay); PathOpAccelerate; NC. 1071 executions in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 201,700 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 125,186 t-states own (0.02 %) |
| Called from | `JumpTable` |
| Calls | `PathOpAccelerate` |
| Reads | `$F39E` (`EnemyObjects`); `$F3CA` (`EnemyObjects`); `$F3F6` (`EnemyObjects`); `$F422` (`EnemyObjects`); `$F44E` (`EnemyObjects`) |

### `PathOpAimPlayer` (`$9699`)

**extended 5: the direction to the player**

+`$16` = DirectionTo the player, velocities for the speed; carry. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpMove` (`$96A8`)

**extended 7: X += Vx, Y += Vy**

NC. Also the move of SetDirection, RandomDirection, PathOpHome and MoveFragile. 38 executions in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 204 calls, 53,856 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,236 calls, 1,352,472 t-states own (0.25 %) |
| Runs (r2, homing missiles at the guardian) | 186 calls, 51,744 t-states own (0.07 %) |
| Called from | `JumpTable`, `PathOpSetDirection`, `PathOpHome` |
| Reads | `$F39B`-`$F3AB` (`EnemyObjects`); `$F3C7`-`$F3D7` (`EnemyObjects`); `$F3F3`-`$F403` (`EnemyObjects`); `$F41F`-`$F42F` (`EnemyObjects`); `$F44B`-`$F45B` (`EnemyObjects`); `$F477`-`$F487` (`EnemyShots`); 3 more ranges |
| Writes | `$F39B`-`$F39E` (`EnemyObjects`); `$F3C7`-`$F3CA` (`EnemyObjects`); `$F3F3`-`$F3F6` (`EnemyObjects`); `$F41F`-`$F422` (`EnemyObjects`); `$F44B`-`$F44E` (`EnemyObjects`); `$F477`-`$F47A` (`EnemyShots`); 3 more ranges |

### `PathOpScrollAlways` (`$96D0`)

**extended 6: X - `$40` every pass**

NC. Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpHome` (`$96E2`)

**extended 8: turn towards the target, then move**

Every +`$28` frames (+`$27` counts down): the direction to the target (+`$29`/+`$2A`) by DirectionTo; a difference up to the turn rate +`$2B` is taken at once, else the direction turns by +`$2B` the shorter way round (mod 64), and SetVelocity for the speed +`$17`. Then PathOpMove; NC. 18 executions in 48K c2; the homing missile and the seeker use it too.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 144 calls, 15,836 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,096 calls, 94,978 t-states own (0.02 %) |
| Runs (r2, homing missiles at the guardian) | 186 calls, 37,029 t-states own (0.05 %) |
| Called from | `PathOpHomePlayer`, `MissileHandler`, `EnemyShotStep` |
| Calls | `PathOpMove`, `DirectionTo`, `SetVelocity` |
| Reads | `$F3AE`-`$F3C3` (`EnemyObjects`); `$F3DA`-`$F3EF` (`EnemyObjects`); `$F406`-`$F41B` (`EnemyObjects`); `$F432`-`$F447` (`EnemyObjects`); `$F45E`-`$F473` (`EnemyObjects`); `$F48A`-`$F49F` (`EnemyShots`); 3 more ranges |
| Writes | `$F3AE` (`EnemyObjects`); `$F3BF` (`EnemyObjects`); `$F3DA` (`EnemyObjects`); `$F3EB` (`EnemyObjects`); `$F406` (`EnemyObjects`); `$F417` (`EnemyObjects`); 10 more ranges |

### `PathOpToCentre` (`$972E`)

**extended 9: accelerate towards column 32 and row 8**

X below 32: C = 8 (Vx + Ax), else `$10`; Y below 8: `$20`, else `$40`; PathOpAccelerate; NC. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 41,400 t-states own (0.01 %) |
| Called from | `JumpTable` |
| Calls | `PathOpAccelerate` |
| Reads | `$F39C`-`$F39E` (`EnemyObjects`); `$F3C8`-`$F3CA` (`EnemyObjects`); `$F3F4`-`$F3F6` (`EnemyObjects`); `$F420`-`$F422` (`EnemyObjects`); `$F44C`-`$F44E` (`EnemyObjects`) |

### `PathOpLand` (`$974D`)

**extended 10: put the object on the ground below it**

One object a frame (bit 7 of LandingFlag). After 8 failed tries in a row, or when another object landed this frame, it is parked at X = 0, Y = 0 (off the playfield, it leaves). Else Y fraction = `$E0`, Y goes down out of any scenery, then on down to the first row with all 4 cells under it filled: Y one up there, the repeat count 1, the tries reset; a row that is filled only in part parks it. NC. 1 execution in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 10,166 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 7,774 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SceneryAt6`, `SceneryCell` |
| Reads | `$974C` (`LandingFlag`); `$BD00`-`$BD08` (`TileSource`); `$BD4F`-`$BD88` (`TileSource`); `$BDCF`-`$BDE2` (`TileSource`); `$BDFA`-`$BE29` (`TileSource`); `$BE9F`-`$BEC5` (`TileSource`); 6 more ranges |
| Writes | `$974C` (`LandingFlag`); `$F39D`-`$F39E` (`EnemyObjects`); `$F3B3` (`EnemyObjects`); `$F3C9`-`$F3CA` (`EnemyObjects`); `$F3DF` (`EnemyObjects`); `$F3F5`-`$F3F6` (`EnemyObjects`); 3 more ranges |

### `PathOpRandomSpeed` (`$97B3`)

**extended 11: the speed +`$17` one up or down at random**

A random byte below `$55` keeps it, below `$AA` + 1, else - 1; kept in 1-7 (0 refused). Carry. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 4,535 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `Random` |
| Reads | `$F3AF` (`EnemyObjects`); `$F3DB` (`EnemyObjects`); `$F407` (`EnemyObjects`); `$F433` (`EnemyObjects`); `$F45F` (`EnemyObjects`) |
| Writes | `$F3AF` (`EnemyObjects`); `$F3DB` (`EnemyObjects`); `$F407` (`EnemyObjects`); `$F433` (`EnemyObjects`); `$F45F` (`EnemyObjects`) |

### `PathOpBounceArena` (`$97CD`)

**extended 12: move, bouncing off the scenery and the edges**

X + Vx: outside columns 16-45 or on scenery: X back, Vx = -Vx. Y + Vy: Y 17 or more (also a negative Y) or on scenery: Y back, Vy = -Vy. NC. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpDive` (`$9837`)

**extended 13: scroll along, dive at the player when close**

PathOpScroll, then, once its column is no more than the player's plus half the row distance between them and a random byte is below 200: one frame of Vy = -`$80`, Vx = -`$40` (a dive up and back). Else on scenery: SelfDestruct. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpMoveFragile` (`$9874`)

**extended 14: move; destroyed on scenery or leaving the playfield**

PathOpMove; Y 17 or more, X outside 16-46, or scenery under it: SelfDestruct. NC. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpWait` (`$9890`)

**extended 15: do nothing this frame**

NC. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SelfDestruct` (`$9892`)

**mark the object as hit by the player's laser**

+`$0D` = 1 (one hit point) and its bit (+`$24`) into `$80BB`: the enemy handler's laser test kills it this frame. Not run in 48K c1/c2; 48K r1 (all levels) runs it: 36 entries.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DirectionTo` (`$989F`)

**A = the direction 0-63 from the object IY to IX**

The rounded column and row distances; their signs pick the octant, the ratio of the smaller to the larger (by subtraction in 8 steps) the direction inside it. Used by PathOpAimPlayer, PathOpHome and `$A0EB`. Not run in 48K c1/c2; 48K r1 (all levels) runs it: 1431 entries: the homing interval of the objects there never ran out.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 35 calls, 16,460 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 117 calls, 60,668 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 104 calls, 47,042 t-states own (0.07 %) |
| Called from | `PathOpHome`, `EnemyFire` |
| Reads | `$F36F`-`$F372` (`PlayerObject`); `$F39B`-`$F39E` (`EnemyObjects`); `$F3C8`-`$F3CA` (`EnemyObjects`); `$F3F4`-`$F3F6` (`EnemyObjects`); `$F420`-`$F422` (`EnemyObjects`); `$F44C`-`$F44E` (`EnemyObjects`); 4 more ranges |

### `SetVelocity` (`$98F1`)

**the velocities for direction A and speed B**

Vx = B x sine[A] and Vy = B x sine[(A - 16) & `$3F`] with the 64-entry signed sine table `$8144` (B additions, so B is 1-7 in practice). 21 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 80 calls, 29,664 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 242 calls, 106,050 t-states own (0.02 %) |
| Runs (r2, homing missiles at the guardian) | 70 calls, 31,062 t-states own (0.04 %) |
| Called from | `PathOpSetDirection`, `PathOpHome`, `EnemyFire` |
| Reads | `$8144`-`$8183` (`SineTable`) |
| Writes | `$F3A6`-`$F3AB` (`EnemyObjects`); `$F3D2`-`$F3D7` (`EnemyObjects`); `$F3FE`-`$F403` (`EnemyObjects`); `$F42A`-`$F42F` (`EnemyObjects`); `$F456`-`$F45B` (`EnemyObjects`); `$F482`-`$F487` (`EnemyShots`); 3 more ranges |

## objutil

`src/game/objutil.asm`

### `FreeEnemySlot` (`$992A`)

**an enemy slot back: `$8072` + 1, its bit out of `$80BD`/`$80BE`**

Its collision bit (+`$24`) is cleared from the masks `$80BD` and `$80BE` (the harmless enemies, set at `$8D1A` and by `$A2C4`/`$A30E`) and the slot deactivated. Used by the enemy handlers and `$A1C8`, `$A1FD`, `$A2D6`. 26 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 121 calls, 15,609 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 139 calls, 17,931 t-states own (0.00 %) |
| Called from | `EnemyHandler`, `LockableHandler`, `ExplosionStep` (tail), `PodStep` |
| Reads | `$8072` (`FreeEnemySlots`); `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F3A0` (`EnemyObjects`); `$F3BC`-`$F3CC` (`EnemyObjects`); `$F3E8`-`$F3F8` (`EnemyObjects`); `$F414`-`$F424` (`EnemyObjects`); 2 more ranges |
| Writes | `$8072` (`FreeEnemySlots`); `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F3A0` (`EnemyObjects`); `$F3CC` (`EnemyObjects`); `$F3F8` (`EnemyObjects`); `$F424` (`EnemyObjects`); 1 more ranges |

### `FreeObject` (`$9941`)

**deactivate the object and `$8074` + 1**

Used by `$A263` (the kind 5 handler); `$8074` is set at `$8D0D` and read at `$A113`. 1 entry in 48K c2.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 50 calls, 2,700 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 4 calls, 216 t-states own (0.00 %) |
| Called from | `EnemyShotStep` |
| Reads | `$8074` (`EnemyShotsLeft`); `$F47C` (`EnemyShots`); `$F4A8` (`EnemyShots`); `$F4D4` (`EnemyShots`) |
| Writes | `$8074` (`EnemyShotsLeft`); `$F47C` (`EnemyShots`); `$F4A8` (`EnemyShots`); `$F4D4` (`EnemyShots`) |

### `EnemyEscaped` (`$994A`)

**the object left the playfield: count its wave down, no bonus**

C = `$FF`: the wave record gets bit 7 (an escape), so the wave pays no bonus. 7 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 16 calls, 304 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 51 calls, 969 t-states own (0.00 %) |
| Called from | `EnemyHandler`, `LockableHandler` |
| Calls | `EnemyGone` (tail) |

### `EnemyKilled` (`$994E`)

**the object was destroyed: count its wave down**

+`$26` = 0 (no drop), C = 0, then EnemyGone. 9 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 25 calls, 650 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 88 calls, 2,288 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 456 t-states own (0.00 %) |
| Called from | `EnemyHandler`, `LockableHandler` |
| Calls | `EnemyGone`, `AddScore` |
| Reads | `$7F3F`-`$7F41` (`SpriteCache`); `$8073`-`$8076` (`WavesAllowed`, `EnemyShotsLeft`, `WaveRecords`); `$8087` (`SpriteCacheMask`); `$F398`-`$F399` (`EnemyObjects`); `$F3B2`-`$F3BB` (`EnemyObjects`) |
| Writes | `$7F3F` (`SpriteCache`); `$8073`-`$8075` (`WavesAllowed`, `EnemyShotsLeft`, `WaveRecords`); `$8087` (`SpriteCacheMask`); `$F3BE` (`EnemyObjects`); `$F3EA` (`EnemyObjects`); `$F416` (`EnemyObjects`); 2 more ranges |

### `EnemyGone` (`$9954`)

**EnemyGone**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 41 calls, 11,440 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 139 calls, 41,392 t-states own (0.01 %) |
| Called from | `EnemyEscaped` (tail), `EnemyKilled` |
| Calls | `AddScore` |
| Reads | `$7EFF`-`$7F11` (`SpriteCache`); `$7F3F`-`$7F41` (`SpriteCache`); `$8073`-`$8087` (`WavesAllowed`, `EnemyShotsLeft`, `WaveRecords`, `SpriteCacheMask`); `$F398`-`$F399` (`EnemyObjects`); `$F3B2`-`$F3C5` (`EnemyObjects`); `$F3DE`-`$F3F1` (`EnemyObjects`); 3 more ranges |
| Writes | `$7EFF`-`$7F0F` (`SpriteCache`); `$7F3F` (`SpriteCache`); `$8073`-`$8087` (`WavesAllowed`, `EnemyShotsLeft`, `WaveRecords`, `SpriteCacheMask`); `$F3BE` (`EnemyObjects`); `$F3EA` (`EnemyObjects`); `$F416` (`EnemyObjects`); 2 more ranges |

### `SceneryAt1` (`$99A9`)

**carry if the cell under the object is not empty**

Used by PlasmaHandler, SeekerHandler and `$A263`. 18 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 144 calls, 6,480 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,343 calls, 60,435 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 89 calls, 4,005 t-states own (0.01 %) |
| Called from | `PlasmaHandler`, `EnemyShotStep`, `l_B33C` |
| Calls | `SceneryCell` |
| Reads | `$B943` (`MapRingSpace`); `$B95F`-`$B9D6` (`MapRingSpace`); `$B9EA`-`$B9ED` (`MapRingSpace`); `$BA0D`-`$BA6D` (`MapRingSpace`); `$BA8E`-`$BAF7` (`MapRingSpace`); `$BB12`-`$BBF1` (`MapRingSpace`); 2 more ranges |

### `SceneryAt2` (`$99B1`)

**carry if one of the 2 cells (X, X + 1) is not empty**

Used by LaserHandler (869 entries in 48K c2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,297 calls, 72,632 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,589 calls, 200,984 t-states own (0.04 %) |
| Runs (r2, homing missiles at the guardian) | 350 calls, 19,639 t-states own (0.03 %) |
| Called from | `LaserHandler` |
| Calls | `SceneryCell` |
| Reads | `$B870`-`$B88F` (`MapRingSpace`); `$B902`-`$B9AA` (`MapRingSpace`); `$B9E5`-`$BE4A` (`MapRingSpace`, `TileSource`); `$BEAF`-`$BECE` (`TileSource`) |

### `SceneryAt4` (`$99BB`)

**carry if one of 2 x 2 cells is not empty**

Used by `$A2D6`. 2 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 4 calls, 513 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 29 calls, 3,725 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 129 t-states own (0.00 %) |
| Called from | `ExplosionToPod` |
| Calls | `SceneryCell` |
| Reads | `$B930`-`$B931` (`MapRingSpace`); `$B9B0`-`$B9B1` (`MapRingSpace`); `$BA13`-`$BA14` (`MapRingSpace`); `$BA6A`-`$BA6B` (`MapRingSpace`); `$BA93`-`$BA94` (`MapRingSpace`); `$BAC4`-`$BAEB` (`MapRingSpace`); 12 more ranges |

### `SceneryAt6` (`$99D5`)

**carry if one of 2 x 3 cells is not empty**

The ship's and most movers' test: rows Y, Y + 1, Y + 2 of columns X and X + 1 (a row is 128 bytes: + `$80`, with the carry into H on every second row). 1227 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,653 calls, 1,136,253 t-states own (0.15 %) |
| Runs (r1, the bot over level 1 with the weapons) | 6,929 calls, 1,392,729 t-states own (0.25 %) |
| Runs (r2, homing missiles at the guardian) | 1,000 calls, 201,000 t-states own (0.28 %) |
| Called from | `PathOpLand`, `PlayerHandler` |
| Calls | `SceneryCell` |
| Reads | `$B714`-`$B71B` (`Start`); `$B753`-`$B754` (`MapRingSpace`); `$B800`-`$B880` (`MapRingSpace`); `$B893`-`$BE57` (`MapRingSpace`, `TileSource`); `$BE6B`-`$BE6D` (`TileSource`); `$BE8E`-`$BEED` (`TileSource`); 6 more ranges |

### `SceneryCell` (`$99FF`)

**HL = the scenery cell of the object IY**

HL = (`$8022`) + Y x 128 + X with the integer parts +`$06` and +`$04`. 2118 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 7,132 calls, 741,728 t-states own (0.10 %) |
| Runs (r1, the bot over level 1 with the weapons) | 11,916 calls, 1,239,264 t-states own (0.22 %) |
| Runs (r2, homing missiles at the guardian) | 1,440 calls, 149,864 t-states own (0.21 %) |
| Called from | `PathOpLand`, `SceneryAt1`, `SceneryAt2`, `SceneryAt4`, `SceneryAt6` |
| Reads | `$8022`-`$8023` (`ScrollMap`); `$F370`-`$F422` (`PlayerObject`, `EnemyObjects`); `$F44C`-`$F44E` (`EnemyObjects`); `$F478`-`$F47A` (`EnemyShots`); `$F4A4`-`$F4A6` (`EnemyShots`); `$F4D0`-`$F4D2` (`EnemyShots`); 3 more ranges |

### `ClampRow` (`$9A13`)

**keep the object in rows 0-15**

A negative row: Y = 0.0; 16 or more: Y = 15 + `$E0`/256. 2028 entries in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 7,974 calls, 406,674 t-states own (0.05 %) |
| Runs (r1, the bot over level 1 with the weapons) | 11,444 calls, 583,644 t-states own (0.11 %) |
| Runs (r2, homing missiles at the guardian) | 742 calls, 37,842 t-states own (0.05 %) |
| Called from | `PlayerHandler`, `ScatterDebris`, `MissileHandler`, `EnemyHandler`, `LockableHandler` |
| Reads | `$F372` (`PlayerObject`); `$F39E` (`EnemyObjects`); `$F3CA` (`EnemyObjects`); `$F3F6` (`EnemyObjects`); `$F422` (`EnemyObjects`); `$F44E` (`EnemyObjects`); 1 more ranges |

### `ClampColumn` (`$9A2F`)

**keep the player in columns 16-45**

Below 16: X = 16.0; 46 or more: X = 45 + `$E0`/256. Only the player uses it (613 entries in 48K c2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,818 calls, 152,172 t-states own (0.02 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 186,732 t-states own (0.03 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 27,000 t-states own (0.04 %) |
| Called from | `PlayerHandler` |
| Reads | `$F370` (`PlayerObject`) |

### `CycleColour` (`$9A4C`)

**the next ink colour 1-7 in +`$25` (bits 3-5)**

The flash of the missiles, the plasma and the hit big enemy. Not run in 48K c1/c2; 48K r1 (all levels) runs it: 291 entries.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 125 calls, 9,284 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 101 calls, 7,504 t-states own (0.01 %) |
| Called from | `PlasmaHandler`, `MissileHandler` |
| Reads | `$F5F9` (`SideShot`) |
| Writes | `$F5F9` (`SideShot`) |

## player

`src/game/player.asm`

### `PlayerHandler` (`$9A5B`)

**kind 0: the ship for one pass**

Not alive (`$7F7B` not `$FF`): PlayerDying. Else the fuel count; `$A6B6`; the input `$8186` (bits 0/1 right/left, 2/3 down/up): up or down sets Vy = the speed - `$20` at once, left or right accelerate X up to the speed + `$20` (the acceleration masked at the limit), no horizontal input brakes Vx to 0. PathOpAccelerate moves, ClampRow and ClampColumn keep it on the screen, scenery under the ship undoes the row move (to the row's edge). A moving ship writes its position into the ring of 8 at `$80C0` (index `$80BF`): the sight follows it from there.

The colour +`$25`: `$70`, or the flashing `$7F79` x 8 + `$40` while fire has been held 8 passes or more (`$8184`, the pod-collect signal). The side weapon's frame routine from `$80EA` by +`$08` - 2; a fire press (`$8185` = `$FF`) FireLaser; then the hit test. 659 executions in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 2,813,241 t-states own (0.38 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 3,362,222 t-states own (0.61 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 510,099 t-states own (0.71 %) |
| Called from | `JumpTable` |
| Calls | `JumpTable`, `PathOpAccelerate`, `SceneryAt6`, `ClampRow`, `ClampColumn`, `ScatterDebris`, `FuelOut`, `FireLaser`, `ReadControls` |
| Reads | `$7F63` (`PassBit`); `$7F79`-`$7F7B` (`SpinnerColour`, `SpinnerColourStep`, `DeathTimer`); `$7F99`-`$7FA7` (`PlayerRecord`, `Players`, `Player1`); `$80BD`-`$80BF` (`HarmlessMaskA`, `HarmlessMaskB`, `ShipHistoryIndex`); `$80E6` (`Fuel`); `$8184`-`$8186` (`FireHeld`, `FireChanged`, `ControlBits`); 9 more ranges |
| Writes | `$7F7B`-`$7F7C` (`DeathTimer`, `EndPending`); `$80BF`-`$80E6` (`ShipHistoryIndex`, `ShipHistory`, `LockTarget`, `LockMask` and 4 more); `$F371`-`$F4D4` (`PlayerObject`, `EnemyObjects`, `EnemyShots`); `$F500` (`LaserShots`); `$F52C` (`LaserShots`); `$F558` (`LaserShots`); 4 more ranges |

### `KillPlayer` (`$9B5F`)

**the ship destroyed: the timer and the explosion**

`$7F7B` = `$16` (22 frames), all 16 records from `$F36C` deactivated, ScatterDebris. 2 executions in 48K c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WeaponRating` (`$9B75`)

**the weapon rating `$80E7-$80E9` for the enemy fire and the wave colours**

L = laser level + side weapon: `$80E7` = `$FF`, `$30` from 4; `$80E9` = 0, 8 from 7; `$80E8` = ((speed / 32 + L) x 4) & `$F0` + (`$81DE`). LaunchWave adds `$80E9` to a kind's colour select (the KindColours set); EnemyFire reads `$80E7` (the first shot's column) and `$80E8` (the fire chance), so a well armed, fast ship draws more fire. Called from `$AC7A` and `$B03A` (10 entries in 48K c2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 44 calls, 10,472 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 112 calls, 26,680 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 238 t-states own (0.00 %) |
| Called from | `ScoreJob`, `ScoreJobRating`, `RoundPlaySetup` |
| Reads | `$7F99`-`$7FA7` (`PlayerRecord`, `Players`, `Player1`); `$81DE` (`ScriptState`) |
| Writes | `$80E7`-`$80E9` (`WeaponRatingMask`, `WeaponRatingValue`, `WeaponRatingLevel`) |

### `ScatterDebris` (`$9BAB`)

**the 5 records from `$F398` as debris around IY**

Each at a random column X - 1 + 0-3 and a random row near Y, active, +`$26` = 0, `$A293` (the explosion picture), ClampRow, +`$27` = random 0-3; `$8072` = 0, so no wave starts until they are gone. Used by KillPlayer and BigEnemyHandler. 2 entries in 48K c2.

On a 128K: the LD (`$8072`),A at `$9BFF` becomes CALL HookShipLost (`$B354`): the store, then sounds `$14` + `$15` (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 31,932 t-states own (0.00 %) |
| Called from | `PlayerHandler` |
| Calls | `Random`, `ClampRow`, `StartExplosion`, `l_B33C` |
| Reads | `$F370`-`$F372` (`PlayerObject`); `$F3A0` (`EnemyObjects`); `$F3CC` (`EnemyObjects`); `$F3F8` (`EnemyObjects`); `$F424` (`EnemyObjects`); `$F450` (`EnemyObjects`) |
| Writes | `$F39C`-`$F3A0` (`EnemyObjects`); `$F3BE`-`$F3CC` (`EnemyObjects`); `$F3EA`-`$F3F8` (`EnemyObjects`); `$F416`-`$F424` (`EnemyObjects`); `$F442`-`$F450` (`EnemyObjects`); `$F46E`-`$F46F` (`EnemyObjects`) |

### `FuelOut` (`$9C03`)

**the fuel ran out: `$80E6` = `$5A`, laser - 1, speed - `$20`**

The laser level +`$0A` of IX does not go below 0, the speed +`$0B` not below `$40`. Also called at `$B119`. 1 entry in 48K c2; measured, see the module notes.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 17 calls, 1,925 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3 calls, 337 t-states own (0.00 %) |
| Called from | `PlayerHandler`, `PlayerDied` |
| Reads | `$7FA6`-`$7FA7` (`Player1`) |
| Writes | `$7FA6`-`$7FA7` (`Player1`); `$80E6` (`Fuel`) |

### `FireLaser` (`$9C1D`)

**fire a laser shot from the ship**

`$80BA` counts the shots not in flight (4 at most, set at `$B2D1`; LaserHandler gives one back): a shot is fired only when `$80BA` + the laser level is 4 or more, so level 0 has one shot in the air, level 3 four. The first free of the 4 slots at `$F4F8`: X + 1 column, Y + `$1E0`/256 for two shots out of three, + `$20`/256 for the third (+`$26` counts the guns); sound effect 2 (`$B2F0`); `$7F77` = 6 when 0. 564 entries in 48K c2.

On a 128K: its CALL RequestEffect at `$9C77` (effect 2) becomes CALL HookShot (`$B32F`): the page-4 engine plays sound `$0E` (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 134 calls, 49,712 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,909 calls, 287,722 t-states own (0.05 %) |
| Runs (r2, homing missiles at the guardian) | 262 calls, 30,136 t-states own (0.04 %) |
| Called from | `PlayerHandler` |
| Calls | `l_B32F` |
| Reads | `$7F77` (`PanelBurst`); `$7F99`-`$7FA6` (`PlayerRecord`, `Players`, `Player1`); `$80BA` (`LaserShotsFree`); `$F36F`-`$F372` (`PlayerObject`); `$F392` (`PlayerObject`); `$F500` (`LaserShots`); 1 more ranges |
| Writes | `$7F77` (`PanelBurst`); `$80BA` (`LaserShotsFree`); `$F392` (`PlayerObject`); `$F4FB`-`$F500` (`LaserShots`); `$F527`-`$F52C` (`LaserShots`) |

## weapons

`src/game/weapons.asm`

### `PlasmaFrame` (`$9C83`)

**side weapon 2: a plasma ball after 3 frames of fire**

Fire held exactly 3 frames: `$F5D4` when free, else with the double plasma (+`$09` = 1) `$F5A8` when free; active, Vy = 0, 3 bounces (+`$26`), PlaceAtPlayer. Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 19,406 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `EffectTickRead` |
| Reads | `$7FA5` (`Player1`); `$8184` (`FireHeld`); `$F36F`-`$F372` (`PlayerObject`); `$F5DC` (`SideShot`) |
| Writes | `$F5D7`-`$F5E7` (`SideShot`); `$F5FA` (`SideShot`) |

### `PlaceAtPlayer` (`$9CB0`)

**the object IX two columns ahead of the ship, one row down**

Copies the ship's X (+2 columns) and Y (+1 row) from `$F36F`. Used by PlasmaFrame, HomingFrame, SeekerFrame. Not run in 48K c1/c2.

On a 128K: its LD HL,`$F36F` becomes CALL HookSpecialLaunch (`$B36C`): the load, then sound `$18` (every bomb, homing missile and seeker launch; r1 frame 1113) (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (r2, homing missiles at the guardian) | 2 calls, 320 t-states own (0.00 %) |
| Called from | `l_B33C` |
| Calls | `EffectTickRead` |
| Reads | `$F36F`-`$F372` (`PlayerObject`) |
| Writes | `$F5D7`-`$F5DA` (`SideShot`) |

### `HomingFrame` (`$9CCA`)

**side weapon 3: a homing missile at the locked target**

Fire held, `$F5D4` free and a lock (`$80E2` not 0): active, the target +`$29` = (`$80E0`), colour `$38`, direction 0 (ahead), life +`$26` = `$4B` (75 frames), the turn interval 1. Not run in 48K c1/c2.

On a 128K: the CALL `$9CB0` at `$9CFA` becomes CALL HookHomingLaunch (`$B35C`): the launch, then sounds `$1A` + `$1B` (r2 frames 127 and 287) (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 144,604 t-states own (0.03 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 34,569 t-states own (0.05 %) |
| Called from | `JumpTable` |
| Calls | `l_B33C` |
| Reads | `$80E0`-`$80E2` (`LockTarget`, `LockMask`); `$8184` (`FireHeld`); `$F5DC` (`SideShot`) |
| Writes | `$F5DC`-`$F5FE` (`SideShot`) |

### `SeekerFrame` (`$9CFE`)

**side weapon 4: the seeker after 7 frames of fire**

Fire held exactly 7 frames and the weapon still 4: a new seeker at the ship flying ahead (direction 0, the speed +`$17`); an active one with +`$26` = 0 is re-armed. +`$26` = 1 and the target = the first enemy slot `$F398`: SeekerHandler hunts from there. Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PodSpeedUp` (`$9D4C`)

**pod 0: fuel `$BB` and the speed one step up, to `$A0`**

Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 87 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Reads | `$7FA7` (`Player1`) |
| Writes | `$7FA7` (`Player1`); `$80E6` (`Fuel`) |

### `PodLaser` (`$9D5D`)

**pod 1: the laser one level up, to 3**

Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PodPlasma` (`$9D68`)

**pod 2: plasma (a second plasma pod: double)**

+`$09` = 1 when the weapon is already plasma; +`$08` = 2; the sight `$F600` off; both slots `$F5D4` and `$F5A8` set up as plasma balls (ResetPlasmaBall). Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 127 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ResetPlasmaBall` |
| Reads | `$7FA4` (`Player1`); `$F608` (`SightObject`) |
| Writes | `$7FA4` (`Player1`); `$F608` (`SightObject`) |

### `ResetPlasmaBall` (`$9D87`)

**the slot IX as an idle plasma ball**

Inactive, kind 9, Vx = `$40`, the X acceleration 0, the Y acceleration `$10` (its gravity). Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 340 t-states own (0.00 %) |
| Called from | `PodPlasma` |
| Reads | `$F5B0` (`PlasmaBall2`); `$F5DC` (`SideShot`) |
| Writes | `$F5AF`-`$F5BD` (`PlasmaBall2`); `$F5DB`-`$F5E9` (`SideShot`) |

### `PodHoming` (`$9DA5`)

**pod 3: homing missiles and the sight**

+`$08` = 3, no double, the slot `$F5A8` off; `$F5D4` idle as kind 10 with speed 4, the turn interval 1 and the turn rate 2; the sight `$F600` on (PlaceSight); no lock (`$80E0` = 0, `$80E2` = 0). Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 271 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PlaceSight` |
| Reads | `$F5B0` (`PlasmaBall2`); `$F5DC` (`SideShot`); `$F608` (`SightObject`) |
| Writes | `$7FA4`-`$7FA5` (`Player1`); `$80E0`-`$80E2` (`LockTarget`, `LockMask`); `$F5B0` (`PlasmaBall2`); `$F5DB`-`$F5EB` (`SideShot`); `$F5FC`-`$F608` (`SideShot`, `SightObject`) |

### `PodSeeker` (`$9DDD`)

**pod 4: the seeker**

The sight off, +`$08` = 4, no double; `$F5D4` idle as kind 7, speed 4, the turn interval 1, the turn rate 2. The second plasma slot `$F5A8` is not cleared here (PodHoming does it). Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SightHandler` (`$9E03`)

**kind 6: the homing sight ahead of the ship**

Colour `$78` without a lock, `$70` with one; its overlap mask +`$0D` into `$80E4` (the lockable enemies test it); then PlaceSight. Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 166,605 t-states own (0.03 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 120,712 t-states own (0.17 %) |
| Called from | `JumpTable` |
| Calls | `PlaceSight` |
| Reads | `$80BF`-`$80E2` (`ShipHistoryIndex`, `ShipHistory`, `LockTarget`, `LockMask`); `$F60D` (`SightObject`) |
| Writes | `$80E4` (`SightMask`); `$F603`-`$F606` (`SightObject`); `$F625` (`SightObject`) |

### `PlaceSight` (`$9E16`)

**the sight at the ship's position of the history ring, 10 columns ahead**

The entry of the ring `$80C0` at the index `$80BF` (the oldest one: the sight lags the ship by 8 moves) into `$F603-$F606`, X + 10 columns.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 1,916 calls, 295,064 t-states own (0.05 %) |
| Called from | `PodHoming`, `SightHandler` |
| Reads | `$80BF`-`$80DF` (`ShipHistoryIndex`, `ShipHistory`) |
| Writes | `$F603`-`$F606` (`SightObject`) |

### `LaserHandler` (`$9E32`)

**kind 1: a laser shot**

Gone on an enemy in its overlap mask (the harmless enemies of `$80BD`/`$80BE` and bits 5-7 excepted) or scenery (SceneryAt2), and at column 48: `$80BA` + 1 (the shot back). Else X + `$140`/256 (1.25 columns) a frame. 882 executions in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 299,234 t-states own (0.04 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 836,477 t-states own (0.15 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 79,964 t-states own (0.11 %) |
| Called from | `JumpTable` |
| Calls | `SceneryAt2` |
| Reads | `$80BA`-`$80BE` (`LaserShotsFree`, `LaserHitMask`, `ColourCycle`, `HarmlessMaskA` and 1 more); `$F4FB`-`$F505` (`LaserShots`); `$F527`-`$F531` (`LaserShots`) |
| Writes | `$80BA` (`LaserShotsFree`); `$F4FB`-`$F500` (`LaserShots`); `$F527`-`$F52C` (`LaserShots`) |

### `PlasmaHandler` (`$9E67`)

**kind 9: a plasma ball, falling and bouncing**

Flashes every second frame; its mask into `$80E5` (a kill for any enemy it overlaps). Gone at column 48, below row 16 or after its bounces (+`$26`, 3). Each frame Vy + the gravity; a landing on scenery (SceneryAt1): sound effect 3, Vy = -Vy / 2, a bounce counted; still in the scenery after the bounce: gone. Not run in 48K c1/c2.

On a 128K: the CALL `$99A9` at `$9EC2`, after a bounce, becomes CALL HookBombBounce (`$B33C`): the call, then sound `$11` (r1: 22 bounces from frame 1141) (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 96,895 t-states own (0.02 %) |
| Called from | `JumpTable` |
| Calls | `PathOpAccelerate`, `SceneryAt1`, `CycleColour`, `RequestEffect`, `l_B33C` |
| Reads | `$7F62` (`PassCount`); `$80E5` (`PlasmaHitMask`); `$F5D8`-`$F5E7` (`SideShot`); `$F5FA` (`SideShot`) |
| Writes | `$80E5` (`PlasmaHitMask`); `$F5D9`-`$F5E7` (`SideShot`); `$F5FA` (`SideShot`) |

### `MissileHandler` (`$9ED7`)

**kind 10: the homing missile**

Life +`$26` - 1, flashing. No lock: it burns out (MissileFade). Its mask into `$80E3`; overlapping the locked enemy (`$80E2`): gone (the enemy handler sees the hit in `$80E3`). Else PathOpHome on the target, ClampRow, gone outside columns 16-47. Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs (r2, homing missiles at the guardian) | run into, not called, 21,677 t-states own (0.03 %) |
| Called from | `JumpTable` |
| Calls | `PathOpHome`, `ClampRow`, `CycleColour` |
| Reads | `$80E2` (`LockMask`); `$F5D8`-`$F5E1` (`SideShot`); `$F5F9`-`$F5FA` (`SideShot`) |
| Writes | `$80E3` (`MissileHitMask`); `$F5DC` (`SideShot`); `$F5F9`-`$F5FA` (`SideShot`) |

### `SeekerHandler` (`$9F13`)

**kind 7: the seeker, killing enemy after enemy**

Flashes. A target (+`$29`) that is active and of kind 2: PathOpHome on it, its mask into `$80E5` (a kill), ClampRow, gone on scenery or outside columns 16-47. A lost target with +`$26` not 0: the next active kind-2 slot after +`$26` (up to 5) becomes the target, none: the player, +`$26` = 0 (it comes home). The kind test is written twice (CP `$02` ... CP `$02`): the second was probably meant for another kind (11 shares the handler of 2). Not run in 48K c1/c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## enemies

`src/game/enemies.asm`

### `EnemyHandler` (`$9F88`)

**kinds 2 and 11: a common enemy**

1412 executions in 48K c2.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 1,042,388 t-states own (0.14 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 1,339,224 t-states own (0.24 %) |
| Called from | `JumpTable` |
| Calls | `RunPath`, `FreeEnemySlot`, `EnemyEscaped`, `EnemyKilled`, `ClampRow`, `EnemyFire`, `StartExplosion`, `AddScore` |
| Reads | `$80BB` (`LaserHitMask`); `$80E5` (`PlasmaHitMask`); `$F39C`-`$F3A5` (`EnemyObjects`); `$F3BC`-`$F3D1` (`EnemyObjects`); `$F3E8`-`$F3FD` (`EnemyObjects`); `$F414`-`$F429` (`EnemyObjects`); 2 more ranges |
| Writes | `$F3A5` (`EnemyObjects`); `$F3D1` (`EnemyObjects`); `$F3FD` (`EnemyObjects`); `$F429` (`EnemyObjects`); `$F455` (`EnemyObjects`) |

### `LockableHandler` (`$9FC8`)

**kind 8: an enemy the homing sight can lock**

As EnemyHandler without the plasma kill; with no lock (`$80E2` = 0) and its bit in the sight's mask `$80E4` it becomes the lock (`$80E0` = IY, `$80E2` = its bit) and flashes (`$7F79` x 8 + `$40`). The locked one dies of a missile hit (`$80E3`); lasers take hit points. Leaving play clears its lock bit. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 148,621 t-states own (0.03 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 42,255 t-states own (0.06 %) |
| Called from | `JumpTable` |
| Calls | `RunPath`, `FreeEnemySlot`, `EnemyEscaped`, `EnemyKilled`, `ClampRow`, `EnemyFire`, `StartExplosion`, `AddScore` |
| Reads | `$7F79` (`SpinnerColour`); `$80BB` (`LaserHitMask`); `$80E2`-`$80E4` (`LockMask`, `MissileHitMask`, `SightMask`); `$F39C`-`$F3A5` (`EnemyObjects`); `$F3BC` (`EnemyObjects`) |
| Writes | `$80E0`-`$80E2` (`LockTarget`, `LockMask`); `$F3A5` (`EnemyObjects`); `$F3BD` (`EnemyObjects`) |

### `BigEnemyHandler` (`$A03E`)

**kind 12: the big (boss) enemy**

Columns 7-55. Its row mask +`$0B` = `$FE` shifted left once per row below row 11 (its lower rows out of the collision grid near the floor). Lockable as kind 8; a missile hit takes 4 hit points and the lock, a laser hit one with a colour flash. Every hit sets the sound pointers `$7F80` = `$FD00`, `$7F84` = `$EDB2`, `$7F88` = `$D6ED` (the hit noise). Below 0 hit points: EnemyKilled, X + 2, ScatterDebris (the debris of a big explosion) and the score. Not run in 48K c1/c2; 48K r1 (all levels) runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## objects

`src/game/objects.asm`

### `EnemyFire` (`$A0EB`)

**Let the enemy at IY fire a shot**

IY: an enemy record. An enemy fires when its fire rate +`$18` is not zero and either it has not fired yet (+8 bit 6 clear) and stands in the trigger column `$80E7`, or in a pass its bit +`$24` selects (`$7F63` PassBit) a random number (Random `$8544`) less `$80E8` is below the rate.

A shot costs one of the shots left in `$8074` (none left: no shot) and takes the first free of the three shot records at `$F474` (44 bytes each, +8 bit 7 the busy flag). It starts at the enemy's position + `$0180` (1.5 cells right and down, Y clamped to row 15), takes its speed from +`$19` (bits 0-2 the step, bits 3-7 the speed index), its colour from +`$20`, its lifetime from +`$22` and its direction from +`$21`:

+`$21` bits 0-1 = 00: the fixed direction in bits 2-7; 10: a random direction (`$7F71` & `$3F`); x1: aimed at the player (DirectionTo `$989F` from the shot to the player record `$F36C`), with bit 1 set spread by -4..+3 (`$7F71` & 7 - 4). The direction (0-63) goes to +`$16`, SetVelocity `$98F1` turns it into the velocity, sound 1 (StartSound `$B2F0`) plays, the enemy's +8 bit 6 records the shot.

Callers: the enemy movers at `$9FA2`, `$9FEB` and `$A06E` (EnemyHandler). Evidence: 48K c2 L1 entries at `$A0EB` during waves with firing enemies; the record layout read off the stores below.

On a 128K: its CALL RequestEffect at `$A1C4` becomes CALL HookEnemyMissile (`$B374`): sound `$19` (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,066 calls, 755,551 t-states own (0.10 %) |
| Runs (r1, the bot over level 1 with the weapons) | 7,986 calls, 812,907 t-states own (0.15 %) |
| Runs (r2, homing missiles at the guardian) | 142 calls, 21,898 t-states own (0.03 %) |
| Called from | `EnemyHandler`, `LockableHandler` |
| Calls | `Random`, `DirectionTo`, `SetVelocity`, `l_B374` |
| Reads | `$7F63`-`$7F71` (`PassBit`, `PassDepth`, `PassPhase`, `ChainStep` and 8 more); `$8074` (`EnemyShotsLeft`); `$80E7`-`$80E8` (`WeaponRatingMask`, `WeaponRatingValue`); `$F39B`-`$F48B` (`EnemyObjects`, `EnemyShots`); `$F4A8`-`$F4B7` (`EnemyShots`); `$F4D4`-`$F4E3` (`EnemyShots`) |
| Writes | `$8074` (`EnemyShotsLeft`); `$F3A0` (`EnemyObjects`); `$F3CC` (`EnemyObjects`); `$F3F8` (`EnemyObjects`); `$F424` (`EnemyObjects`); `$F450` (`EnemyObjects`); 1 more ranges |

### `ExplosionStep` (`$A1C8`)

**Advance an explosion (object kind 3)**

IY: the explosion. Runs in odd passes only (`$7F62` bit 0). +`$27` counts down the passes a frame is held: while it lasts the colour +`$25` is 0 (the frame is drawn black, a flash); when it runs out the animation frame +2 advances.

After frame 8 the explosion ends: removed (RemoveObject `$992A`) when +`$26` is 0, otherwise it leaves a weapon pod (ExplosionToPod). Handler pointer at `$8100`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 202,883 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 140,049 t-states own (0.03 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 1,595 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `FreeEnemySlot` (tail), `ExplosionToPod` (tail) |
| Reads | `$7F62` (`PassCount`); `$F39A` (`EnemyObjects`); `$F3BD`-`$F3C6` (`EnemyObjects`); `$F3E9`-`$F3F2` (`EnemyObjects`); `$F415`-`$F41E` (`EnemyObjects`); `$F441`-`$F44A` (`EnemyObjects`); 1 more ranges |
| Writes | `$F39A` (`EnemyObjects`); `$F3BD`-`$F3C6` (`EnemyObjects`); `$F3E9`-`$F3F2` (`EnemyObjects`); `$F415`-`$F41E` (`EnemyObjects`); `$F441`-`$F44A` (`EnemyObjects`); `$F46D`-`$F46F` (`EnemyObjects`) |

### `ExplosionAdvance` (`$A1EC`)

**Store the explosion's frame and fade its colour**

A: the next frame (1-8). The colour +`$25` steps down by 8 (one INK step, the bright bit kept off by AND `$78`) until it reaches `$50`. Used by ExplosionStep.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PodStep` (`$A1FD`)

**A weapon pod (object kind 4): collected or carried by the scroll**

IY: the pod. Collected when the player's hit mask `$F379` has the pod's bit +`$24`. IX = the current player's record (`$7F99`).

Collecting with fire held for 8 or more passes (`$8184` FireHeld) activates the weapon the selector record+7 points at: the selector goes back to 0 and the weapon's routine from the table `$80F0` is called (CallFromTable `$91E2`), sound 6.

Collecting without fire moves the selector to the next weapon (sound 5); past the fifth it wraps to 0, awards 1000 points (AddScore 9) and sets the power timer `$80E6` to `$B4`. Either way the HUD bit 2 of `$81C5` is set, 100 points are awarded (AddScore 4) and the pod is removed.

Not collected: the pod moves with the scenery (ScrollObject `$9640`), its colour follows the colour cycle `$80BC`; once +8 bit 5 is clear (off the playfield) the power timer `$80E6` is halved and the pod is removed. Handler pointer at `$8102`.

On a 128K: the CALL `$91E2` at `$A21A` (a weapon selected) becomes CALL HookWeaponSelect (`$B379`): the call, then sound `$0F` (r1 frames 1097 and 1713); the CALL `$A489` at `$A247` becomes CALL HookPodTaken (`$B364`): the call, then sound `$16` (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 19,991 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 92,195 t-states own (0.02 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 39,184 t-states own (0.05 %) |
| Called from | `JumpTable` |
| Calls | `PathOpScroll`, `FreeEnemySlot`, `AddScore`, `RequestEffect`, `l_B33C`, `EffectAfterJobs` |
| Reads | `$7F99`-`$7FA3` (`PlayerRecord`, `Players`, `Player1`); `$80BC` (`ColourCycle`); `$80E6` (`Fuel`); `$8184` (`FireHeld`); `$81C5` (`EventRequests`); `$F379` (`PlayerObject`); 6 more ranges |
| Writes | `$7FA3` (`Player1`); `$80E6` (`Fuel`); `$81C5` (`EventRequests`); `$F3BD` (`EnemyObjects`); `$F3E9` (`EnemyObjects`); `$F415` (`EnemyObjects`); 2 more ranges |

### `EnemyShotStep` (`$A263`)

**Move an enemy shot (object kind 5)**

IY: the shot. It ends (FreeShot `$9941`) when its lifetime +`$26` runs out, when it hits the player (`$F379` AND +`$24`), when the playfield collision test `$99A9` reports carry, or when after the move (MoveObject `$96E2`) its Y is outside rows 0-16 or its X is outside columns 16-48 (the visible window). Handler pointer at `$8104`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 30,960 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 228,952 t-states own (0.04 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 18,982 t-states own (0.03 %) |
| Called from | `JumpTable` |
| Calls | `PathOpHome`, `FreeObject`, `SceneryAt1` |
| Reads | `$F379` (`PlayerObject`); `$F478`-`$F47A` (`EnemyShots`); `$F498`-`$F4A6` (`EnemyShots`); `$F4C4`-`$F4D2` (`EnemyShots`); `$F4F0`-`$F4F2` (`EnemyShots`) |
| Writes | `$F49A` (`EnemyShots`); `$F4C6` (`EnemyShots`); `$F4F2` (`EnemyShots`) |

### `StartExplosion` (`$A293`)

**Turn the object at IY into an explosion**

Sets the three sound bit patterns (`$7F80` = `$FD00`, `$7F84` = `$EDB2`, `$7F88` = `$D6ED`, shifted one bit a pass by PlayInterrupt: the explosion noise), kind 3, the animation record `$7EA1` from frame 1, +`$0B` = `$E0`, +`$27` = 0, colour `$70` and X fraction 0. The object's bit +`$24` leaves the mask `$80BD` and joins `$80BE` (from the shootable to the harmless objects).

Callers: the hit handling at ScatterDebris and the enemy movers (EnemyHandler).

On a 128K: its LD HL,`$D6ED` at `$A29F` becomes CALL HookExplosion (`$B386`): the load, then sound `$1D` (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 115 calls, 39,445 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 88 calls, 30,184 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 343 t-states own (0.00 %) |
| Called from | `ScatterDebris`, `EnemyHandler`, `LockableHandler` |
| Calls | `l_B386` |
| Reads | `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F3BC` (`EnemyObjects`); `$F3E8` (`EnemyObjects`); `$F414` (`EnemyObjects`); `$F440` (`EnemyObjects`); `$F46C` (`EnemyObjects`) |
| Writes | `$7F80`-`$7F89` (`SoundPattern1`, `ObjectBeep`, `ObjectBeepMask`, `SoundPattern2` and 3 more); `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F398`-`$F3A3` (`EnemyObjects`); `$F3BD`-`$F3CF` (`EnemyObjects`); `$F3E9`-`$F3FB` (`EnemyObjects`); `$F415`-`$F427` (`EnemyObjects`); 2 more ranges |

### `ExplosionToPod` (`$A2D6`)

**Turn the finished explosion at IY into a weapon pod**

Rounds the Y to the nearest cell (+5 bit 7 carries into +6), then asks `$99BB` whether the cell is free (carry: no room, the object is removed). Otherwise: +`$0B` = `$C0`, kind 4, +`$26` down by 2, the pod animation `$7EBB` (both branches of the JR Z load the same record), the bit +`$24` back from `$80BE` to `$80BD`, colour 8, sound 4.

Used by ExplosionStep.

On a 128K: its CALL RequestEffect at `$A31D` becomes CALL HookPodAppears (`$B381`): sound `$1C` (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 4 calls, 1,526 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 29 calls, 11,032 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 386 t-states own (0.00 %) |
| Called from | `ExplosionStep` (tail) |
| Calls | `SceneryAt4`, `EffectAfterJobs` |
| Reads | `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F39D`-`$F39E` (`EnemyObjects`); `$F3BC`-`$F3CA` (`EnemyObjects`); `$F3E8`-`$F3F6` (`EnemyObjects`); `$F414`-`$F422` (`EnemyObjects`); `$F440`-`$F44E` (`EnemyObjects`); 1 more ranges |
| Writes | `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F398`-`$F3A3` (`EnemyObjects`); `$F3BD`-`$F3CF` (`EnemyObjects`); `$F3E9`-`$F3FB` (`EnemyObjects`); `$F415`-`$F427` (`EnemyObjects`); `$F441`-`$F453` (`EnemyObjects`); 1 more ranges |

## print

`src/game/print.asm`

### `PrintChar` (`$A321`)

**Print a character or take a print code**

A: a byte. When a code is pending (`$80AD` below `$20`) A is its operand and the code's routine from PrintControlTable runs (codes 7-`$1F` do nothing), then the pending mark goes back to `$20`.

Otherwise a byte below `$20` becomes the pending code; a byte from `$20` is printed at the print position `$80AA` with the attribute `$80AC`, the position moves one cell right. All registers are kept.

Callers: PrintString, PrintBcd, PrintKeyName, HighScoreEntry.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5,293 calls, 2,421,478 t-states own (0.33 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,527 calls, 428,892 t-states own (0.08 %) |
| Runs (r2, homing missiles at the guardian) | 8 calls, 5,456 t-states own (0.01 %) |
| Called from | `PrintString`, `PrintBcd`, `PrintBcdLeading`, `PrintBcdOut` |
| Calls | `PrintCharRow`, `PrintCharDone` (tail), `PrintGlyph` (tail), `PrintSetAttr`, `PrintSetColumn`, `PrintSetRow`, `PrintColumnRight`, `PrintRowDown`, `InterruptJump` |
| Reads | `$80AA`-`$80AD` (`PrintPos`, `PrintAttr`, `PrintPending`); `$A3A3`-`$A3B0` (`PrintControlTable`); `$B54F`-`$B6FE` (`Glyphs`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$4002`-`$5A57` (screen); `$5A6B`-`$5A74` (screen); `$5A8C`-`$5AFF` (screen); `$5BB0`-`$5BB3` (system); `$5BCC`-`$5BED` (system); `$80AA`-`$80AD` (`PrintPos`, `PrintAttr`, `PrintPending`) |

### `PrintCharRow` (`$A365`)

**PrintCharRow**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 6,547 calls, 72,044 t-states own (0.01 %) |
| Called from | `PrintChar`, `l_A367` (tail), `l_AB07` |
| Calls | `l_A367`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BE4`-`$5BED` (system) |

### `l_A367` (`$A367`)

**l_A367**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 6,547 calls, 249,877 t-states own (0.05 %) |
| Called from | `PrintCharRow`, `l_AB07` |
| Calls | `PrintCharRow` (tail), `PrintCharDone`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$4202`-`$421D` (screen); `$4253`-`$47F6` (screen); `$4A27`-`$4FF7` (screen); `$522C`-`$53F0` (screen); `$542C`-`$54F0` (screen); `$552C`-`$55F0` (screen); 4 more ranges |

### `PrintCharDone` (`$A36E`)

**PrintCharDone**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 1,382 calls, 87,066 t-states own (0.02 %) |
| Called from | `PrintChar` (tail), `l_A367`, `PrintGlyph` (tail) |
| Calls | `PrintBcdLeadNext`, `PrintBcdRestNext` |
| Writes | `$80AD` (`PrintPending`) |

### `PrintGlyph` (`$A376`)

**PrintGlyph**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 146 calls, 48,326 t-states own (0.01 %) |
| Called from | `PrintChar` (tail) |
| Calls | `PrintCharDone` (tail) |
| Reads | `$B54F`-`$B63E` (`Glyphs`) |
| Writes | `$400D`-`$50F1` (screen); `$510A`-`$51F1` (screen); `$520A`-`$52F1` (screen); `$530A`-`$53F1` (screen); `$540A`-`$54F1` (screen); `$550A`-`$55F1` (screen); 2 more ranges |

### `PrintCodeDone` (`$A399`)

**End a print code: nothing pending**

The return of every print code routine (pushed by PrintChar): `$80AD` = `$20`, the registers PrintChar saved restored.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,110 calls, 77,700 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 145 calls, 10,150 t-states own (0.00 %) |
| Called from | `PrintSetAttr`, `PrintSetColumn`, `PrintSetRow`, `PrintColumnRight` |
| Writes | `$80AD` (`PrintPending`) |

### `PrintSetAttr` (`$A3B1`)

**Print code 0: the attribute**

C: the attribute byte for the next characters (`$80AC`).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 4,158 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 486 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCodeDone` |
| Writes | `$80AC` (`PrintAttr`) |

### `PrintSetInk` (`$A3B6`)

**Print code 1: the ink**

C: the ink 0-7 into the attribute `$80AC`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintSetPaper` (`$A3BF`)

**Print code 2: the paper**

C: the paper 0-7 into bits 3-5 of the attribute `$80AC`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintSetColumn` (`$A3CD`)

**Print code 3: the column**

C: the column 0-31 of the print position.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 7,875 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 855 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCodeDone` |
| Reads | `$80AA` (`PrintPos`) |
| Writes | `$80AA` (`PrintPos`) |

### `PrintSetRow` (`$A3D6`)

**Print code 4: the row**

C: the row 0-23: the print position's high byte `$58` + C / 8, bits 5-7 of the low byte C AND 7; the column is kept. Also the end of PrintRowDown.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 316 calls, 45,732 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 40 calls, 6,077 t-states own (0.00 %) |
| Called from | `PrintChar`, `PrintRowDown` (tail) |
| Calls | `PrintCodeDone` |
| Reads | `$80AA`-`$80AB` (`PrintPos`) |
| Writes | `$80AA`-`$80AB` (`PrintPos`) |

### `PrintColumnRight` (`$A3ED`)

**Print code 5: move the column**

C: the columns to add (a negative operand, `$FE`, moves left).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 12,806 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 1,862 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCodeDone` |
| Reads | `$80AA` (`PrintPos`) |
| Writes | `$80AA` (`PrintPos`) |

### `PrintRowDown` (`$A3F4`)

**Print code 6: move the row**

C: the rows to add to the current row (the position's row from bits 5-9 of its offset).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 25,280 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 3,200 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintSetRow` (tail) |
| Reads | `$80AA`-`$80AB` (`PrintPos`) |

### `PrintString` (`$A401`)

**Print a string**

HL: the string. Bytes go to PrintChar; `$FF` ends the string, `$1B` n prints message n (PrintMessage) and goes on. The byte after a print code is its operand, never taken as `$FF` or `$1B`. HL is kept.

Callers: PrintMessage and the title loop (HiScorePage).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 287 calls, 486,982 t-states own (0.07 %) |
| Runs (r1, the bot over level 1 with the weapons) | 45 calls, 61,575 t-states own (0.01 %) |
| Called from | `PrintMessage`, `HiScorePage` |
| Calls | `PrintChar`, `PrintMessage`, `InterruptJump` |
| Reads | `$80AD` (`PrintPending`); `$8261`-`$82A2` (`HiScoreTable`); `$82EE`-`$839D` (`Messages`); `$83FD`-`$84FD` (`Messages`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BBC`-`$5BBD` (system) |

### `PrintMessage` (`$A423`)

**Print message A**

A: the message number. The messages are the `$FF`-terminated strings from `$82EE` (after the `$FF` at `$82ED`); message n starts after the n+1-th `$FF` from `$82ED`. Registers kept.

Callers: PrintString, the menu screens (RedefineKeys, PrintKeyName, SelectPlayers, HighScoreEntry) and LevelStart, CreditsPage, HiScorePage. The list of the messages: ../zynaps/work/stage1/texts.txt.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 282 calls, 1,102,385 t-states own (0.15 %) |
| Runs (r1, the bot over level 1 with the weapons) | 40 calls, 134,481 t-states own (0.02 %) |
| Called from | `PrintString`, `SelectOnePlayer`, `HighScoreEntry`, `LevelStart`, `CreditsPage`, `HiScorePage`, `l_B33C` |
| Calls | `PrintString`, `InterruptJump` |
| Reads | `$82ED`-`$84F0` (`ColoursBar`, `Messages`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BC2`-`$5BEB` (system) |

### `PrintBcdSpaces` (`$A43C`)

**Print a BCD number with spaces for its leading zeros (no caller)**

LD C,`$20` before PrintBcd: an entry no code calls (the callers load C themselves).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintBcd` (`$A43E`)

**Print an 8-digit BCD number**

HL: 4 BCD bytes (the high digits first); C: the character printed for each leading zero; A': the attribute of the digits after the leading zeros (the zeros print with the attribute in `$80AC`). The number is copied to the scratch `$7FFC` and its digits are taken out a nibble at a time by RLD (the `$0F` put in by the first RLD marks a byte used up). Up to 7 leading zeros are replaced, the last digit always prints.

Returns HL past the number. Callers: PrintPlayerScore and the title loop (CreditsPage, HiScorePage).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 79 calls, 80,376 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 119 calls, 3,708 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 996 t-states own (0.00 %) |
| Called from | `PrintPlayerScore`, `CreditsPage`, `HiScorePage` |
| Calls | `PrintChar`, `l_A445`, `InterruptJump` |
| Reads | `$7F9C`-`$7F9F` (`Player1`); `$7FCC`-`$7FCF` (`Player2`); `$7FFC`-`$7FFF` (`BcdScratch`); `$826B`-`$82A6` (`HiScoreTable`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BEE`-`$5BEF` (system); `$7FFC`-`$7FFF` (`BcdScratch`); `$80AC` (`PrintAttr`) |

### `l_A445` (`$A445`)

**l_A445**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 120 calls, 15,589 t-states own (0.00 %) |
| Called from | `PrintBcd`, `l_AB07` |
| Calls | `PrintBcdLeading` |
| Reads | `$7F9C`-`$7F9F` (`Player1`); `$7FCC`-`$7FCF` (`Player2`); `$826B`-`$82A6` (`HiScoreTable`) |
| Writes | `$7FFC`-`$7FFF` (`BcdScratch`) |

### `PrintBcdLeading` (`$A452`)

**PrintBcdLeading**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 616 calls, 53,770 t-states own (0.01 %) |
| Called from | `l_A445`, `PrintBcdLeadNext` (tail) |
| Calls | `PrintChar`, `PrintBcdOut` (tail) |
| Reads | `$7FFC`-`$7FFF` (`BcdScratch`) |
| Writes | `$7FFC`-`$7FFF` (`BcdScratch`); `$80AC` (`PrintAttr`) |

### `PrintBcdLeadNext` (`$A46B`)

**PrintBcdLeadNext**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 8,560 t-states own (0.00 %) |
| Called from | `PrintCharDone` |
| Calls | `PrintBcdLeading` (tail), `PrintBcdRest` |
| Writes | `$80AC` (`PrintAttr`) |

### `PrintBcdRest` (`$A474`)

**PrintBcdRest**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 336 calls, 16,113 t-states own (0.00 %) |
| Called from | `PrintBcdLeadNext`, `PrintBcdRestNext` (tail) |
| Calls | `PrintBcdOut` |
| Reads | `$7FFD`-`$7FFF` (`BcdScratch`) |
| Writes | `$7FFD`-`$7FFF` (`BcdScratch`) |

### `PrintBcdOut` (`$A47E`)

**PrintBcdOut**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 452 calls, 9,492 t-states own (0.00 %) |
| Called from | `PrintBcdLeading` (tail), `PrintBcdRest` |
| Calls | `PrintChar` |

### `PrintBcdRestNext` (`$A482`)

**PrintBcdRestNext**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 11,611 t-states own (0.00 %) |
| Called from | `PrintCharDone` |
| Calls | `PrintBcdRest` (tail), `PrintPlayerScoreDone` |
| Reads | `$7FFF` (`BcdScratch`) |
| Writes | `$7FFF` (`BcdScratch`) |

## score

`src/game/score.asm`

### `AddScore` (`$A489`)

**Add award A to the current player's score**

A: the award number 0-11 of the points table `$8231` (4 BCD bytes each: 0, 25, 50, 75, 100, 150, 200, 250, 500, 1000, 2000, 5000). The award is added from the low byte up to the score of player `$7F98` (the low byte at `$7F9F` or `$7FCF`); bit 1 of `$81C5` asks for the panel score redraw.

Callers: the enemy kill (EnemyGone), the enemy movers (EnemyHandler), PodStep.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 26 calls, 8,216 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 118 calls, 37,288 t-states own (0.01 %) |
| Runs (r2, homing missiles at the guardian) | 2 calls, 632 t-states own (0.00 %) |
| Called from | `EnemyKilled`, `EnemyGone`, `EnemyHandler`, `LockableHandler`, `PodStep`, `l_B33C` |
| Reads | `$7F98`-`$7F9F` (`CurrentPlayer`, `PlayerRecord`, `Players`, `Player1`); `$81C5` (`EventRequests`); `$8235`-`$8258` (`PointsTable`) |
| Writes | `$7F9C`-`$7F9F` (`Player1`); `$81C5` (`EventRequests`) |

### `PrintPlayerScore` (`$A4AE`)

**Print player A's score on the panel**

A: the player, 1 or 2. Player 1's score at column 2, player 2's at column 22 of the top row; bright white (`$47`) for the player in play, dark cyan (`$05`) for the other, leading zeros as spaces. Callers: the panel drawing (ScoreJob) and the player change (RoundPlaySetup).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 62 calls, 11,156 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 114 calls, 17,704 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 175 t-states own (0.00 %) |
| Called from | `ScoreJob`, `RoundPlaySetup` |
| Calls | `PrintBcd` |
| Reads | `$7F98` (`CurrentPlayer`) |
| Writes | `$80AA`-`$80AC` (`PrintPos`, `PrintAttr`) |

### `PrintPlayerScoreDone` (`$A4D8`)

**PrintPlayerScoreDone**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 2,280 t-states own (0.00 %) |
| Called from | `PrintBcdRestNext` |
| Calls | `ScoreJobRating` |

### `CompareScore` (`$A4DA`)

**Is the score at DE above the score at HL?**

DE, HL: 4 BCD bytes each. Carry set when DE's score is greater (equal scores: no carry). Registers kept. Used by HighScoreEntry.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 25 calls, 4,710 t-states own (0.00 %) |
| Called from | `HighScoreEntry` |
| Reads | `$7F9C`-`$7F9E` (`Player1`); `$826B`-`$82A5` (`HiScoreTable`) |

### `DrawLives` (`$A4EF`)

**Draw the current player's lives on the panel**

Six life marks from the attribute `$5AD8` (row 22, column 24), the steps between them in `$81C0`: the first record+4 marks red on black (`$42`), the rest black. Callers: ScoreJob, RoundPlaySetup.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 9,216 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3 calls, 1,508 t-states own (0.00 %) |
| Called from | `RoundPlaySetup`, `l_B32F` |
| Reads | `$7F99`-`$7FA0` (`PlayerRecord`, `Players`, `Player1`); `$81C0`-`$81C5` (`LifeSteps`, `EventRequests`) |
| Writes | `$5A98`-`$5A99` (screen); `$5AB8`-`$5AB9` (screen); `$5AD8`-`$5AD9` (screen) |

## menu

`src/game/menu.asm`

### `MenuRasterInterrupt` (`$A512`)

**Interrupt handler of the menu screens: a colour per scan line**

Saves every register and SP (into the LD SP at `$A575`), sets the border black, waits about 77 x 15 DJNZ and 23 more for the beam (61 and 16 in the 48K: the Pentagon's interrupt comes at another place in the frame), then for each of `$80B0` scan lines takes a colour from the table at (`$80AE`) and PUSHes it into 20 attribute cells ending at HL (HL steps a row of 32 every 8 lines: A' rotates a single bit). Both paths of a line take the same time; a line is 12 T-states longer than the 48K's (LD B,(HL) twice, two NOPs and JR NZ where the 48K had three NOPs and JP NZ). Then SP back, `$80B9` (frames left, counted by WaitMenuRasterEnd) down by one unless 0, EI.

Installed by SetMenuRaster in the interrupt handler pointer `$FDFE`. Evidence: 48K c2 L1 has `$A512` in frames 690-765 (the selections screen), 26 permille of the frame time.

On a 128K: the glue makes the POP BC: POP DE: POP HL at `$A581` JP PlayAtA581 (`$5B28`): a frame of the engine, then the POPs (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,403 calls, 55,786,454 t-states own (7.49 %) |
| Runs (r1, the bot over level 1 with the weapons) | 411 calls, 17,104,694 t-states own (3.10 %) |
| Called from | `InterruptJump` (tail) |
| Reads | `$581A`-`$59BA` (screen); `$59DA` (screen); `$59FA` (screen); `$5A1A` (screen); `$5A3A` (screen); `$5A5A` (screen); 4 more ranges |
| Writes | `$80B9` (`RasterFrames`); `$A576`-`$A577` (`MenuRasterInterrupt`) |
| Ports out | `$00FE` |

### `l_A584` (`$A584`)

**l_A584**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,403 calls, 101,016 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 411 calls, 29,592 t-states own (0.01 %) |

### `SetMenuRaster` (`$A58D`)

**Install MenuRasterInterrupt as the interrupt handler**

Writes `$A512` to the handler pointer `$FDFE`, EI. Callers: MenuScreenSetup, SelectPlayers.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 23 calls, 920 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3 calls, 120 t-states own (0.00 %) |
| Called from | `MenuScreenSetup`, `SelectOnePlayer` |
| Writes | `$FDFE`-`$FDFF` (`InterruptJump`) |

### `WaitMenuRasterEnd` (`$A595`)

**Wait for the menu raster's frames to run out, then the title interrupt**

Waits (HALT) until `$80B9` is 0, clears the colour buffer, then installs TitleInterrupt (`$A9E4`) in `$FDFE`. Callers: RedefineKeys, SelectPlayers, HighScoreEntry, RoundPlaySetup.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 23 calls, 16,042,625 t-states own (2.15 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3 calls, 2,601,493 t-states own (0.47 %) |
| Called from | `SelectOnePlayer`, `RoundPlaySetup`, `l_B33C` |
| Calls | `ClearColourBuffer`, `InterruptJump` |
| Reads | `$80B9` (`RasterFrames`); `$A596`-`$A5A0` (`WaitMenuRasterEnd`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BEC`-`$5BFB` (system); `$FDFE`-`$FDFF` (`InterruptJump`) |

### `ClearColourBuffer` (`$A5A7`)

**Clear the raster colour buffer `$FC00-$FCFF`**

Callers: WaitMenuRasterEnd, MenuScreenSetup, SelectPlayers.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 46 calls, 271,722 t-states own (0.04 %) |
| Runs (r1, the bot over level 1 with the weapons) | 6 calls, 35,442 t-states own (0.01 %) |
| Called from | `WaitMenuRasterEnd`, `MenuScreenSetup`, `SelectOnePlayer` |
| Writes | `$FC00`-`$FCFF` (`HitGridX`) |

### `ExpandNextColours` (`$A5B0`)

**Expand the colour list (`$80B1`) into the buffer at DE**

As ExpandColours with HL from `$80B1`.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 256 calls, 4,096 t-states own (0.00 %) |
| Called from | `SelectOnePlayer` |
| Calls | `ExpandColours` |
| Reads | `$80B1`-`$80B2` (`RasterList`) |

### `ExpandColours` (`$A5B3`)

**Expand a run-length colour list into the buffer**

HL: the list; DE: the destination; B: the bytes to write. A byte below `$80` is a colour, `$80`+n followed by a colour is n of that colour, `$FF` starts the list again (it repeats until B bytes are written). Returns DE past the bytes, HL at the list's start.

Callers: MenuScreenSetup, SelectPlayers, RedefineKeys (by ExpandNextColours).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 46 calls, 392,380 t-states own (0.05 %) |
| Runs (r1, the bot over level 1 with the weapons) | 262 calls, 382,817 t-states own (0.07 %) |
| Called from | `ExpandNextColours`, `MenuScreenSetup`, `SelectOnePlayer` |
| Reads | `$82A7`-`$82EB` (`ColoursTop`, `ColoursMenu`, `ColoursHighlight`, `ColoursBar`) |
| Writes | `$FC20`-`$FCC7` (`HitGridX`) |

### `RedefineKeys` (`$A5D1`)

**The key definition screen (menu key 3)**

MenuScreenSetup, message 13 (KEYBOARD DEFINITION), then for each of the five keys of the key table `$8188` (fire, up, down, left, right; a half-row port high byte and a bit mask each): its prompt (messages 14-18), its current name, a new key (WaitKeyPress), the new name, 10 frames, the key stored; the line's 8 scan lines get the highlight colours (`$82D7` expanded into `$FC60` + 24 a key).

After the last key: 100 frames, WaitMenuRasterEnd, ClearScreen `$858B`. Used by MenuKeys.

On a 128K: the CALL `$A685` at `$A5D1` becomes CALL HookScreenWipe (`$B39C`): the music off, the wipe, sounds `$1E` + `$1F`; the glue makes the CALL `$858B` at `$A61F` CALL ClearThenMusic (`$5B46`): the screen cleared, the music on (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintKeyName` (`$A623`)

**Print the name of a key and come back to its place**

C: the half-row port high byte; B: the bit mask. The key number 5 x the half-row (the 0 bit of C) + the bit is looked up in the key names `$8198`: a letter prints as it is, 0-3 print the messages 9-12 (CS, SS, SP, EN). A space after it; the print position is put back.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WaitKeyPress` (`$A65B`)

**Wait for one key, then for its release**

Scans the six half-rows of `$8192` (`$FE` `$FD` `$FB` `$DF` `$BF` `$7F`) until exactly one key of a half-row is down. Returns C = its half-row port byte, B = its bit mask; waits until no key at all is down.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MenuScreenSetup` (`$A685`)

**Clear the screen and start the menu raster**

ClearScreen `$858B`, ClearColourBuffer, the colours `$82A7` (48 lines) into `$FC20` and `$82CE` (120 lines) into `$FC50`, 168 raster lines from `$FC20`, SetMenuRaster. Callers: RedefineKeys, HighScoreEntry, LevelStart.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 23 calls, 4,347 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 378 t-states own (0.00 %) |
| Called from | `LevelStart`, `l_B39C` |
| Calls | `ClearScreen`, `SetMenuRaster`, `ClearColourBuffer`, `ExpandColours` |
| Writes | `$80AE`-`$80B0` (`RasterTable`, `RasterLines`) |

### `WaitFrames` (`$A6AE`)

**Wait A frames**

A: the frames (HALT A times, interrupts enabled). Callers: RedefineKeys, HighScoreEntry, EndOfPlay.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 17 calls, 58,038,176 t-states own (7.79 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 3,477,650 t-states own (0.63 %) |
| Called from | `EndOfPlay` |
| Calls | `InterruptJump` |
| Reads | `$A6B2` (`WaitFrames`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF6`-`$5BF7` (system) |

## input

`src/game/input.asm`

### `ReadControls` (`$A6B6`)

**Read the controls into `$8184-$8186`**

C collects the five keys of `$8188` (fire into bit 4, then up, down, left, right), ORed with the joystick bits. `$8184` counts the passes fire is held, `$8185` = `$FF` when fire was pressed or released since the last read, `$8186` the direction bits (fire removed). Registers kept.

Callers: the player mover (PlayerHandler) and HighScoreEntry. Evidence: the bits and counters seen in 48K c2 while the bot plays.

With K-MOUSE the IN A,(`$1F`): AND `$1F` at `$A6D4` becomes CALL MouseRead (`$FE1D`): NOP: the mouse moves the ship (src/game/setup.asm).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,818 calls, 2,293,340 t-states own (0.31 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 2,813,806 t-states own (0.51 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 406,869 t-states own (0.57 %) |
| Called from | `PlayerHandler` |
| Reads | `$8184`-`$8191` (`FireHeld`, `FireChanged`, `ControlBits`, `JoystickFlags` and 1 more) |
| Writes | `$8184`-`$8187` (`FireHeld`, `FireChanged`, `ControlBits`, `JoystickFlags`) |
| Ports in | `$7FFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### `TitleFireCheck` (`$A748`)

**Is fire pressed on the title screen? Also picks the Kempston**

Carry set when the Kempston reads exactly fire (`$10`: then `$8187` bit 0 stays set and the game uses the Kempston), or, with the Kempston flag cleared, when the fire key (`$8188`) or 0 is down. Callers: HighScoreEntry and the title loop (CreditsPage, HiScorePage, Pause, TitleTune).

With K-MOUSE the start test at `$A74E` becomes LD A,`$FA`: IN A,(`$DF`): AND 2: the mouse's left button starts play (src/game/setup.asm).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 411 calls, 75,240 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 185 calls, 34,016 t-states own (0.01 %) |
| Called from | `HighScoreEntry`, `CreditsPage`, `l_B0C2`, `HiScorePage`, `TitleTune`, `TuneByte` |
| Reads | `$8187`-`$8189` (`JoystickFlags`, `KeyTable`) |
| Writes | `$8187` (`JoystickFlags`) |
| Ports in | `$001F`, `$011F`, `$081F`, `$0F1F`, `$DB1F`, `$DD1F`, `$DF1F`, `$E11F`, `$E31F`, `$E51F`, `$E71F`, `$E91F`, `$EB1F`, `$ED1F`, `$EF1F`, `$F11F`, `$F31F` |

## options

`src/game/options.asm`

### `MenuKeys` (`$A76F`)

**Read the menu keys 1-3**

1: SelectOnePlayer, 2: SelectTwoPlayers, 3: RedefineKeys. Registers kept. Used by the title loop (CreditsPage).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 6 calls, 924 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 161 t-states own (0.00 %) |
| Called from | `CreditsPage`, `l_B0C2` |
| Calls | `SelectOnePlayer` |
| Ports in | `$F7FE` |

### `SelectOnePlayer` (`$A788`)

**Select the one player game**

A = 1, then as SelectTwoPlayers.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 6,185,118 t-states own (1.12 %) |
| Called from | `MenuKeys` |
| Calls | `ClearScreen`, `PrintMessage`, `SetMenuRaster`, `WaitMenuRasterEnd`, `ClearColourBuffer`, `ExpandNextColours`, `ExpandColours`, `l_B386`, `InterruptJump` |
| Reads | `$7F9B` (`Players`); `$A7D9`-`$A7DA` (`SelectTwoPlayers`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BEA`-`$5BEB` (system); `$7F9B` (`Players`); `$80AE`-`$80B2` (`RasterTable`, `RasterLines`, `RasterList`) |

### `SelectTwoPlayers` (`$A78D`)

**Select the two player game**

SelectPlayers with A = 2.

On a 128K: the LD HL,`$82E0` at `$A7BB` becomes CALL HookSelections (`$B38F`): the music off, the load, then sounds `$1E` + `$1F` (r1 frame 23); the glue makes the CALL `$858B` at `$A7F2` CALL ClearThenMusic (`$5B46`) (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

Stores A in `$7F9B`, clears the screen, colours `$82A7` (48 lines) into `$FC20` and `$82D7` (64 lines) into `$FC50`, 112 raster lines, message 19 (SELECTIONS, 1 PLAYER, 2 PLAYERS). Then 8 x 16 steps of 2 frames: the bar `$82E0` expanded twice (32 lines) a line higher each step under the chosen line (`$FC68` one player, `$FC88` two), about 5 seconds. Then WaitMenuRasterEnd and ClearScreen.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## hiscore

`src/game/hiscore.asm`

### `HighScoreEntry` (`$A7F7`)

**Rank the current player's score, take the initials**

MenuScreenSetup, message 25 (ROLE OF HONOUR, PLAYER n). The score (the record (`$7F99`) + 0) is compared with the five entries from the top: below all of them message 26 (UNRANKED) for 150 frames or until fire.

Ranked: message 27 (ENTER YOUR INITIALS), the lower entries move down, the score is copied in, then three letters at row 13 column 13 (attribute `$59AD`, 2 cells apart): each starts at A, right/left (ReadControls) step it through A-Z with wrap-around every 5 frames, fire (or 100 steps without movement, 10 seconds) takes it and prints a dot after it; 20 frames between the letters, 50 after the last. Ends with WaitMenuRasterEnd, ClearScreen.

Used by the game over (PlayerDied).

On a 128K: its first CALL `$A685` (at `$A7F7`) becomes CALL HookScreenWipe (`$B39C`): the music off, the wipe, sounds `$1E` + `$1F`; the CALL `$A423` at `$A81B` becomes CALL HookHonour (`$B344`): the call, then sound `$12`; the CALL `$A595` at `$A8B7` becomes CALL HookHonourResult (`$B34C`): the call, then sounds `$14` + `$15` (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5 calls, 27,570 t-states own (0.00 %) |
| Called from | `PlayerDied` |
| Calls | `PrintMessage`, `CompareScore`, `TitleFireCheck`, `HighScoreDone` (tail), `l_B33C`, `l_B39C`, `InterruptJump` |
| Reads | `$7F99`-`$7F9A` (`PlayerRecord`); `$A821` (`HighScoreEntry`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF6`-`$5BF7` (system) |

### `HighScoreDone` (`$A8B7`)

**HighScoreDone**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5 calls, 220 t-states own (0.00 %) |
| Called from | `HighScoreEntry` (tail) |
| Calls | `ClearScreen`, `l_B33C` |

## panel

`src/game/panel.asm`

### `DrawSpinner` (`$A8BE`)

**Draw a 2x2 cell spinner frame**

HL: the attribute address of the top left cell; A: its attribute (four cells); C: the frame 0-15. The frame's offset from SpinnerFrames picks the shape in SpinnerImages: an even offset is the start of a shape read top down, an odd one the last byte of a shape read bottom up (the shape flipped upside down). Each row is drawn as the byte and its mirror (the bit-reverse table `$FB00`) side by side.

Callers: the panel update PanelFrame (`$AB97`, `$AB9F`).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 6,440 calls, 9,593,192 t-states own (1.29 %) |
| Runs (r1, the bot over level 1 with the weapons) | 6,916 calls, 10,301,704 t-states own (1.87 %) |
| Runs (r2, homing missiles at the guardian) | 1,000 calls, 1,490,224 t-states own (2.08 %) |
| Called from | `PanelFrame` |
| Reads | `$A919`-`$A978` (`SpinnerFrames`, `SpinnerImages`); `$FB03`-`$FBC0` (`BitReverse`); `$FBE0` (`BitReverse`) |
| Writes | `$5081`-`$50BE` (screen); `$5181`-`$51BE` (screen); `$5281`-`$52BE` (screen); `$5381`-`$53BE` (screen); `$5481`-`$54BE` (screen); `$5581`-`$55BE` (screen); 5 more ranges |

### `RestorePanel` (`$A979`)

**Restore the bottom third and the panel attributes from `$E748`**

`$E748` -> `$5000` (2048 bytes) and `$EF48` -> `$5A60` (160 bytes, attribute rows 19-23). Called at `$B04F` (the player change, RoundPlaySetup).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 835,524 t-states own (0.11 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 92,836 t-states own (0.02 %) |
| Called from | `RoundPlaySetup` |
| Reads | `$E748`-`$EFE7` (`SpriteCacheImages`) |
| Writes | `$5000`-`$57FF` (screen); `$5A60`-`$5AFF` (screen) |

### `SavePanel` (`$A98D`)

**Save the bottom third and the panel attributes into `$E748`**

The reverse of RestorePanel. Called at `$B1F9`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 17 calls, 789,296 t-states own (0.11 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 46,437 t-states own (0.01 %) |
| Called from | `PlayLoopBranch` |
| Calls | `InterruptJump` |
| Reads | `$5000`-`$57FF` (screen); `$5A60`-`$5AFF` (screen); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFA`-`$5BFB` (system); `$E748`-`$EFE7` (`SpriteCacheImages`) |

## interrupts

`src/game/interrupts.asm`

### `ScrollControl` (`$A9A1`)

**Start, stop and step the fine scroll**

At phase 4 when the restart flag `$81E3` is `$FF`: it becomes 0 and the scroll starts (`$81DA` bit 5). When `$7F7B` is not `$FF` the scroll stops (bit 5 cleared). Otherwise with the scroll on, or still between two cells (`$7F6A` not `$C0`), the fine scroll counter steps: `$7F6B` toggles `$08`/`$10` and `$7F6A` takes it by XOR, a 2-bit Gray code `$C0`, `$C8`, `$D8`, `$D0`; `$7F6C` = `$FF` says the pass scrolls (0: it does not).

Called by PlayPass. Evidence: TTD 48K c2 frames 300-316: `$7F6A` C8, D8, D0, C0, `$7F6B` 08/10, `$7F6C` FF.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 614,100 t-states own (0.08 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 673,078 t-states own (0.12 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 73,936 t-states own (0.10 %) |
| Called from | `PlayPass` |
| Reads | `$7F65`-`$7F7B` (`PassPhase`, `ChainStep`, `NodeFreeList`, `ShiftPage` and 12 more); `$81DA`-`$81E3` (`ScriptState`) |
| Writes | `$7F6A`-`$7F6C` (`ShiftPage`, `FineScrollToggle`, `ScrollThisPass`); `$81DA` (`ScriptState`) |

### `TitleInterrupt` (`$A9E4`)

**Interrupt handler of the title and between screens**

Only sets the interrupt flag `$7F96` = `$80`. Installed by WaitMenuRasterEnd and the game's screens (`$852D`, `$ABE6`, `$ABF8`, `$B18B`, `$B1F2`).

On a 128K: the glue makes the LD HL,`$7F96` at `$A9E5` CALL PlayAtA9E5 (`$5B21`): a frame of the engine, then the load (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 2,550 calls, 158,100 t-states own (0.02 %) |
| Runs (r1, the bot over level 1 with the weapons) | 372 calls, 23,098 t-states own (0.00 %) |
| Called from | `InterruptJump` (tail) |
| Writes | `$7F96` (`EffectTick`) |

### `PlayInterrupt` (`$A9ED`)

**Interrupt handler in play: one phase of a game pass**

Saves all registers. Phase 4 (a pass whose chain has not ended): nothing more. Otherwise `$7F62` +1 (PassCount), `$7F63` rotated (PassBit, the object bit of this pass), `$7F64` +1 (depth), the phase `$7F65` +1; `$7F96` = `$FF`; the colour cycle `$80BC` 8, `$10`, `$18`; the three sound bit patterns `$7F80`, `$7F84`, `$7F88` shift one bit, the bit out into `$7F7F`, `$7F83`, `$7F87`.

Phase 1: `$8AED`, the chain from its start (`$7F66` = `$AAE5`), the three DI; RET restored, `$894D`, a wait of `$0B` (scroll on) or `$2F` x 16 DJNZ. Phases 2-3: `$9150`, `$91C6`, a wait of `$10`. Then the wait before the border black is `$77` DJNZ. (The 48K: 2, `$26`, 5 and `$10`; the Pentagon's counts are larger, its interrupt comes earlier in the frame and nothing is contended.) Then `$8894`, the panel update `$AB13`, a wait, the border black, `$85CA`, and PlayPass.

Installed at `$B1DF`. Evidence: 48K c2 L1 659 entries, 12 permille own time.

On a 128K: the glue makes the PUSH IX: PUSH IY at `$A9F7` JP PlayAtA9F7 (`$5B31`) and a NOP: one engine step; with PlayAtAB03 the engine steps twice a pass in play (c1: 3220 times each), and a pass takes two TV frames, so one step a TV frame on average (src/game/setup.asm, glue.asm; docs/09-sound.md 9.8).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,221 calls, 341,331 t-states own (0.05 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,459 calls, 366,559 t-states own (0.07 %) |
| Runs (r2, homing missiles at the guardian) | 501 calls, 53,011 t-states own (0.07 %) |
| Called from | `InterruptJump` (tail) |

### `l_A9FB` (`$A9FB`)

**l_A9FB**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 18,141,021 t-states own (2.44 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 19,779,093 t-states own (3.58 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 3,661,241 t-states own (5.10 %) |
| Calls | `DrawPlayfield`, `MoveStars`, `StartColumn`, `ScrollStep`, `TestHitGrid`, `ClearHitGrid`, `PanelFrame` |
| Reads | `$7F62`-`$7F65` (`PassCount`, `PassBit`, `PassDepth`, `PassPhase`); `$7F80`-`$7F89` (`SoundPattern1`, `ObjectBeep`, `ObjectBeepMask`, `SoundPattern2` and 3 more); `$80BC` (`ColourCycle`); `$81DA` (`ScriptState`) |
| Writes | `$7F62`-`$7F67` (`PassCount`, `PassBit`, `PassDepth`, `PassPhase` and 1 more); `$7F7F`-`$7F96` (`RowBeepMask`, `SoundPattern1`, `ObjectBeep`, `ObjectBeepMask` and 11 more); `$80BC` (`ColourCycle`); `$AAED`-`$AAF8` (`ChainStep1End`, `ChainBuildColumn2`, `ChainBuildColumn3`) |
| Ports out | `$00FE` |

### `PlayPass` (`$AA96`)

**The play logic of a phase**

`$ABD5`, ScrollControl, `$9463`, `$8F9B`; in odd phases `$90CB`, in phase 2 `$AD66`; at depth 1 in phases 2-3 `$8D45`. Falls into PlayChain.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 649,677 t-states own (0.09 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 697,591 t-states own (0.13 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 272,373 t-states own (0.38 %) |
| Called from | `RenderDone` |
| Calls | `ResumeScript`, `ObjectStrips`, `MarkEnemyGrid`, `RunObjects`, `ScrollControl`, `PlayChain`, `ChainBuildColumn1`, `ChainBuildColumn2`, `ChainBuildColumn3`, `ChainEnd`, `CheckPauseAndEnd`, `WaveScriptStep` |
| Reads | `$7F64`-`$7F67` (`PassDepth`, `PassPhase`, `ChainStep`) |
| Writes | `$7F66`-`$7F67` (`ChainStep`) |
| Ports out | `$00FE` |

### `PlayChain` (`$AAC3`)

**Advance the drawing chain**

A wait, the border black, the chain step `$7F66` + 5. At depth 1 the step runs (RunChainStep) and returns to PlayInterruptExit; nested, the DI; RET before the step are replaced by two NOPs so the interrupted step continues into it.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,926 calls, 1,101,240 t-states own (0.15 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,928 calls, 1,182,664 t-states own (0.21 %) |
| Called from | `YieldScript`, `PlayPass` |
| Calls | `ChainBuildColumn1`, `ChainBuildColumn2`, `ChainBuildColumn3`, `ChainEnd`, `PlayInterruptExit` (tail) |
| Reads | `$7F64`-`$7F67` (`PassDepth`, `PassPhase`, `ChainStep`) |
| Writes | `$7F66`-`$7F67` (`ChainStep`); `$AAED`-`$AAEE` (`ChainStep1End`) |
| Ports out | `$00FE` |

### `ChainBuildColumn1` (`$AAEA`)

**Chain step 1: build cells of the new column**

CALL BuildColumn `$896D` then DI; RET (two NOPs when a nested pass chained step 2 on).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 25,141 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 14,705 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 3,875 t-states own (0.01 %) |
| Called from | `PlayPass`, `PlayChain` |
| Calls | `BuildColumn`, `PlayInterruptExit` |

### `ChainStep1End` (`$AAED`)

**ChainStep1End**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 12,098 t-states own (0.00 %) |
| Called from | `BuildColumnBack` |
| Calls | `ChainBuildColumn2`, `PlayInterruptExit` |

### `ChainBuildColumn2` (`$AAEF`)

**Chain step 2: build cells of the new column**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 24,986 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 26,815 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 3,875 t-states own (0.01 %) |
| Called from | `PlayPass`, `PlayChain`, `ChainStep1End` |
| Calls | `BuildColumn`, `PlayInterruptExit` |

### `ChainBuildColumn3` (`$AAF4`)

**Chain step 3: build cells of the new column**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 24,924 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 26,815 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 3,906 t-states own (0.01 %) |
| Called from | `PlayPass`, `PlayChain` |
| Calls | `BuildColumn`, `PlayInterruptExit` |

### `ChainEnd` (`$AAF9`)

**The end of the chain: phase 0**

DI, `$7F65` = 0, so the next interrupt starts a new pass.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 24,769 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 26,753 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 3,875 t-states own (0.01 %) |
| Called from | `PlayPass`, `PlayChain` |
| Calls | `PlayInterruptExit` |
| Writes | `$7F65` (`PassPhase`) |

### `PlayInterruptExit` (`$AAFF`)

**Leave the play interrupt**

Depth `$7F64` down by one, all registers back, EI.

On a 128K: the glue makes the POP IY: POP IX at `$AB03` JP PlayAtAB03 (`$5B3C`) and a NOP: a frame of the engine (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 99,820 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 107,198 t-states own (0.02 %) |
| Runs (r2, homing missiles at the guardian) | 125 calls, 15,531 t-states own (0.02 %) |
| Called from | `PlayChain` (tail), `ChainBuildColumn1`, `ChainStep1End`, `ChainBuildColumn2`, `ChainBuildColumn3`, `ChainEnd` |
| Reads | `$7F64` (`PassDepth`) |
| Writes | `$7F64` (`PassDepth`) |

### `l_AB07` (`$AB07`)

**l_AB07**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 328,440 t-states own (0.04 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 352,716 t-states own (0.06 %) |
| Runs (r2, homing missiles at the guardian) | 501 calls, 51,102 t-states own (0.07 %) |
| Calls | `GlyphLineStep`, `l_8A28`, `RotateLine`, `RotateLineSave`, `RotateLineCarry`, `RotateByte`, `RotateByteShift`, `RotateByteOut`, `l_8F64`, `RotateNextByte`, `RotateLineMerge`, `RotateLineNext`, `RotateLineCount`, `l_8F6D`, `l_8F6F`, `PrintCharRow`, `l_A367`, `l_A445`, `EventDispatch`, `EventPending`, `EventEnabled`, `EventAny`, `l_ACB0`, `SpriteShiftCopy`, `PlayLoopPass`, `PlayLoopCheck`, `PlayLoopTest`, `PlayLoopBranch`, `PlayLoopAgain` |

## hud

`src/game/hud.asm`

### `PanelFrame` (`$AB13`)

**the panel's attribute work of one pass of play**

Called from PlayInterrupt `$A9ED` (at `$AA87`) once a pass; 48K c2: 659 entries in 659 passes, 630704 T own (6 permille of the recording). Reads PassCount `$7F62`, the player record (`$7F99`: +`$0B` speed), Fuel `$80E6`, `$7F77-$7F7A`; writes only the attribute rows 20-23.

1. The ink of `$5AC6-$5AC7` + 1 every fourth pass (PassCount & 3 = 0), kept in 0-7 with the paper and bright bits (AND `$C7` drops the carry into paper).

2. The speed bar: `$5AEE-$5AF1` = `$01`, then (speed >> 5) - 1 cells of `$31` from `$5AEE`: one lit cell at `$40` up to four at `$A0`, the top speed (FuelOut keeps it from going below `$40`, which would make B = 0 and the DJNZ write 256 cells).

3. The fuel lamps: DE = `$3131` at `$5AC1` and `$5ADD`; Fuel < `$40` darkens D, < `$20` darkens E too.

4. The two colour blocks: PanelPhase `$7F78` + (PassCount & 1) in 0-15 (C), PanelBounce `$7F79` + PanelStep `$7F7A` on odd passes, the step reversed at 7 or 1 of the low 3 bits; `$A8BE` draws A at `$5A81` and `$5A9D` with C.

5. On even passes: rows 21-22 columns 11-20 (`$5AAB`, `$5ACB`) cleared; PanelBurst `$7F77` not 0: counted down, its new value n written as the attribute at columns 15+n and 16-n of both rows (the pair moves out as n falls and goes black at 0).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 2,702,190 t-states own (0.36 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 2,995,667 t-states own (0.54 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 425,871 t-states own (0.59 %) |
| Called from | `l_A9FB` |
| Calls | `DrawSpinner` |
| Reads | `$5AC6`-`$5AC7` (screen); `$7F62` (`PassCount`); `$7F77`-`$7F7A` (`PanelBurst`, `SpinnerFrame`, `SpinnerColour`, `SpinnerColourStep`); `$7F99`-`$7FA7` (`PlayerRecord`, `Players`, `Player1`); `$80E6` (`Fuel`) |
| Writes | `$5AAB`-`$5AF1` (screen); `$7F77`-`$7F7A` (`PanelBurst`, `SpinnerFrame`, `SpinnerColour`, `SpinnerColourStep`) |

### `CheckPauseAndEnd` (`$ABD5`)

**key 4 pauses; a pending end code ends the play loop**

Called by the play interrupt once a pass (the phase dispatch in the routine at `$AA96`; 48K c2: 659 entries in 659 passes). Key 4 (half row `$F7FE`, bit 3) calls Pause (`$B197`). Then a pending end code in EndPending (`$7F7C`: 1 a life lost, 2 the level done, 4 abort) is moved to EndCode (`$7F7D`), which ends the play loop at `$B1E9`, the interrupt handler (`$FDFE`) becomes TitleInterrupt `$A9E4` (it only sets `$7F96` = `$80`, no frame work) and StopAndSettle silences the effect. Returns with A = 0 when nothing is pending.

On a 128K: the glue makes the CALL Z,`$B197` (key 4) at `$ABDB` CALL Z,Key4MusicOff (`$5B7B`): the music off first (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,220 calls, 207,100 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3,458 calls, 221,372 t-states own (0.04 %) |
| Runs (r2, homing missiles at the guardian) | 500 calls, 32,000 t-states own (0.04 %) |
| Called from | `PlayPass` |
| Calls | `StopAndSettle` |
| Reads | `$7F7C` (`EndPending`) |
| Writes | `$7F7D` (`EndCode`); `$FDFE`-`$FDFF` (`InterruptJump`) |
| Ports in | `$F7FE` |

### `StopAndSettle` (`$ABF0`)

**silence the effect and let two frames pass under TitleInterrupt**

Requests effect 0 (RequestEffect `$B2F0` takes 0 as `$80`: the stop), keeps InterruptHandler (`$FDFE`), installs TitleInterrupt `$A9E4`, two HALTs with interrupts on, DI and Handler back. Called by CheckPauseAndEnd and Pause; 48K c2: 2 entries (one pause and one end in the play recording).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 17 calls, 1,505,179 t-states own (0.20 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 81,367 t-states own (0.01 %) |
| Called from | `CheckPauseAndEnd` |
| Calls | `RequestEffect`, `InterruptJump` |
| Reads | `$AC00`-`$AC01` (`StopAndSettle`); `$FDFE`-`$FDFF` (`InterruptJump`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BE0`-`$5BE3` (system); `$FDFE`-`$FDFF` (`InterruptJump`) |

## events

`src/game/events.asm`

### `EventDispatch` (`$AC07`)

**run the highest requested and enabled job; carry set when one ran**

In: EventRequests `$81C5`, EventMask `$81C6`. Out: NC (Z) when nothing was pending; carry after a handler ran. Clobbers AF, BC, DE, HL and what the handler uses. Callers: the play loop (`$B1E6`, 48K c2: 68083 calls) and the effect player's tone loop (`$B376`, so a long effect does not stop the scheduler). The handler is jumped to through `$91E2` with the index of the bit (0 = bit 7), its bit cleared in EventRequests first.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,271,264 calls, 12,712,921 t-states own (1.71 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,333,039 calls, 13,331,612 t-states own (2.42 %) |
| Runs (r2, homing missiles at the guardian) | 289,739 calls, 2,898,359 t-states own (4.04 %) |
| Called from | `l_AB07`, `PlayLoopPass` |
| Calls | `EventPending`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFA`-`$5BFB` (system) |

### `EventPending` (`$AC0A`)

**EventPending**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,270,996 calls, 16,526,784 t-states own (2.22 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,332,811 calls, 17,330,543 t-states own (3.14 %) |
| Runs (r2, homing missiles at the guardian) | 289,739 calls, 3,767,937 t-states own (5.25 %) |
| Called from | `l_AB07`, `EventDispatch` |
| Calls | `EventEnabled`, `InterruptJump` |
| Reads | `$81C5` (`EventRequests`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFA`-`$5BFB` (system) |

### `EventEnabled` (`$AC0D`)

**EventEnabled**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,271,093 calls, 8,899,184 t-states own (1.20 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,332,899 calls, 9,330,856 t-states own (1.69 %) |
| Runs (r2, homing missiles at the guardian) | 289,739 calls, 2,028,876 t-states own (2.83 %) |
| Called from | `l_AB07`, `EventPending` |
| Calls | `EventAny`, `InterruptJump` |
| Reads | `$81C6` (`EventMask`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFA`-`$5BFB` (system) |

### `EventAny` (`$AC0E`)

**EventAny**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,270,904 calls, 13,997,790 t-states own (1.88 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,332,628 calls, 14,698,036 t-states own (2.66 %) |
| Runs (r2, homing missiles at the guardian) | 289,739 calls, 3,188,447 t-states own (4.44 %) |
| Called from | `l_AB07`, `EventEnabled` |
| Calls | `JumpTable`, `PlayLoopCheck`, `InterruptJump` |
| Reads | `$81C6` (`EventMask`) |
| Writes | `$81C5`-`$81C6` (`EventRequests`, `EventMask`) |

### `EventDone` (`$AC25`)

**EventDone**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 30 calls, 2,812 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 29 calls, 5,994 t-states own (0.00 %) |
| Called from | `ScoreJobRating`, `SpriteBuildNext`, `l_ACB0` |
| Calls | `PlayLoopCheck` |
| Writes | `$81C6` (`EventMask`) |

### `EventNone` (`$AC2B`)

**the handler of the unused bits 6-3: RET**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PodIconJob` (`$AC2C`)

**event bit 2: the pod selector's icon and its colours**

Allows only bit 7 meanwhile (EventMask AND `$80`). Attributes `$46` (bright yellow) at `$5A86-$5A87` and `$45` (bright cyan) at `$5AA6-$5AA7`; the 16 x 16 icon n = the player record's +7 (0-4, the selected pod) from PodIcons + 32 n drawn as two 2-cell rows at `$5086` and `$50A6` (screen third 2, rows 20-21, columns 6-7) by IconRow. 48K c2: entries through `$91E2` (indirect); posted by the play loop's start (`$B1C7`) and by the pod pick-up (`$A243`).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 4,256 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 5,600 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `IconRow` |
| Reads | `$7F99`-`$7FA3` (`PlayerRecord`, `Players`, `Player1`); `$81C6` (`EventMask`) |
| Writes | `$5A86`-`$5A87` (screen); `$5AA6`-`$5AA7` (screen); `$81C6` (`EventMask`) |

### `IconRow` (`$AC5E`)

**two character cells of 8 lines from DE to the screen at HL**

In: DE the bytes (8 of the left cell, then 8 of the right), HL the screen address of the left cell. Out: DE past the 16 bytes, HL two cells right. Called twice by PodIconJob (the second time by falling in).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 38 calls, 26,220 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 50 calls, 34,500 t-states own (0.01 %) |
| Called from | `PodIconJob` |
| Reads | `$B4AF`-`$B54E` (`PodIcons`) |
| Writes | `$5086`-`$50A7` (screen); `$5186`-`$51A7` (screen); `$5286`-`$52A7` (screen); `$5386`-`$53A7` (screen); `$5486`-`$54A7` (screen); `$5586`-`$55A7` (screen); 2 more ranges |

### `EffectJob` (`$AC6F`)

**event bit 0: play the requested sound effect**

Drops bit 0 from the mask (a second effect request waits; the effect player posts no more of itself) and calls the effect player `$B30C`, which keeps the scheduler going from its tone loop. Posted by RequestEffect (`$B2F0`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScoreJob` (`$AC7A`)

**event bit 1: print the score, the extra life**

Allows only bit 7 meanwhile. Prints the current player's score (PrintPlayerScore `$A4AE` with A = CurrentPlayer `$7F98`) and recomputes WeaponRating (`$9B75`: the enemy fire and the waves' colours). The extra life: when the record's +1 (the score's high part) is at least ExtraLifeScores[+`$0C`] (`$800F`: 1, 3, 5, 7, 9, then `$FF`), +`$0C` steps on, the lives (+4) + 1 and DrawLives `$A4EF` shows them. Posted by the score adder (`$A4AB`).

On a 128K: the CALL `$A4EF` at `$ACA2`, after an extra life is given, becomes CALL HookExtraLife (`$B334`): the call, then sounds `$0F` + `$10` (witnessed in r1 frame 6590) (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 4,732 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 6,710 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 182 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `WeaponRating`, `PrintPlayerScore` |
| Reads | `$7F98`-`$7FA8` (`CurrentPlayer`, `PlayerRecord`, `Players`, `Player1`); `$800F` (`ExtraLifeScores`); `$81C6` (`EventMask`) |
| Writes | `$81C6` (`EventMask`) |

### `ScoreJobRating` (`$AC87`)

**ScoreJobRating**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 13,377 t-states own (0.00 %) |
| Called from | `PrintPlayerScoreDone` |
| Calls | `WeaponRating`, `EventDone`, `l_B32F` |
| Reads | `$7F99`-`$7FA8` (`PlayerRecord`, `Players`, `Player1`); `$800F`-`$8010` (`ExtraLifeScores`) |
| Writes | `$7FA0`-`$7FA8` (`Player1`) |

### `SpriteBuildJob` (`$ACA6`)

**event bit 7: build the sprites waiting in the ring**

Sets the mask to 0 (nothing interrupts it), then builds every entry between DrawQueueRead (`$8024`) and DrawQueueWrite (`$8025`): entry k at `$8026` + 3 k is the kind and the descriptor's address; LoadCellSprite the image, SpriteBuildShifts the shifted copies, then bit 7 of the descriptor's +`$0E` (waiting) is cleared. The read index wraps at 8 (RES 3). 48K c2: 5 builds (BuildCellSprite 5 entries, RotateSprite 35).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 961 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 837 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 31 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SpriteBuildNext` |
| Reads | `$81C6` (`EventMask`) |
| Writes | `$81C6` (`EventMask`) |

### `SpriteBuildNext` (`$ACAD`)

**SpriteBuildNext**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 62 calls, 7,285 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 54 calls, 559 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 2 calls, 235 t-states own (0.00 %) |
| Called from | `SpriteBuildJob`, `SpriteBuildDone` (tail) |
| Calls | `EventDone`, `l_ACB0`, `LoadCellSprite`, `SpriteBuildShifts`, `InterruptJump` |
| Reads | `$8024`-`$8034` (`DrawQueueRead`, `DrawQueueWrite`, `DrawQueue`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF6`-`$5BF7` (system); `$8024` (`DrawQueueRead`) |

### `l_ACB0` (`$ACB0`)

**l_ACB0**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 55 calls, 5,805 t-states own (0.00 %) |
| Called from | `l_AB07`, `SpriteBuildNext` |
| Calls | `EventDone`, `LoadCellSprite`, `SpriteBuildShifts` |
| Reads | `$8024`-`$803D` (`DrawQueueRead`, `DrawQueueWrite`, `DrawQueue`) |
| Writes | `$8024` (`DrawQueueRead`) |

### `SpriteBuildDone` (`$ACD0`)

**SpriteBuildDone**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 30 calls, 1,798 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 27 calls, 1,566 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 58 t-states own (0.00 %) |
| Called from | `SpriteShiftNext` |
| Calls | `SpriteBuildNext` (tail) |
| Reads | `$7F00`-`$7F10` (`SpriteCache`); `$7F40` (`SpriteCache`) |
| Writes | `$7F00`-`$7F10` (`SpriteCache`); `$7F40` (`SpriteCache`) |

### `LoadCellSprite` (`$ACD9`)

**build a kind's image from its glyphs**

In: A the kind, HL the descriptor (+0/+1 the image's address). Kinds `$14` and up go to BuildBigSprite `$8F0C` with kind - `$13` (not reached in 48K c1 or 48K c2; 48K r1: 6 entries, frames 16855-66273: the big enemies). Else the glyphs are at `$6400` + 32 kind (kinds 16-19: 48 bytes each, + 16 (kind - 16) + 32 more), B = 2 cells a column, C = 2 columns or 3 for bit 4 of the kind; BuildCellSprite `$8EDB` builds the complemented image with blank borders. HL is kept. 48K c2: 5 entries.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 31 calls, 7,905 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 27 calls, 6,909 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 279 t-states own (0.00 %) |
| Called from | `SpriteBuildNext`, `l_ACB0` |
| Calls | `BuildCellSprite` |
| Reads | `$7EF2`-`$7F03` (`SpriteCache`); `$7F32`-`$7F33` (`SpriteCache`) |

### `SpriteBuildShifts` (`$AD16`)

**the pre-shifted copies of a sprite: seven one-pixel shifts, a new copy where the pattern says**

In: HL the descriptor. Its +4/+5 (the image's length), +9 (the shift pattern) and +`$0A`/+`$0B` (BC for RotateSprite: B the width in bytes, C the height in lines) are written into the operands of LD HL (`$AD3E`), LD A (`$AD47`) and LD BC (`$AD4A`): self-modified code. DE = the image (+0/+1). Seven rounds, one a pixel: the first always, and later each set bit of the pattern (RRA), copy the current image to the next slot (LDIR of the length) and continue on the copy; then RotateSprite `$8F5A` shifts it one pixel right. A clear bit shifts the last copy on without a new slot, so the pattern chooses which of the 8 pixel positions get an image (8, 4 or 2 copies). 48K c2: 5 entries, RotateSprite 35 times (7 a sprite).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 31 calls, 5,766 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 27 calls, 5,022 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 15,374 t-states own (0.02 %) |
| Called from | `SpriteBuildNext`, `l_ACB0` |
| Calls | `RotateSprite`, `SpriteShiftRound` |
| Reads | `$7EF2`-`$7F0D` (`SpriteCache`); `$7F32`-`$7F3D` (`SpriteCache`); `$E748`-`$E9E7` (`SpriteCacheImages`) |
| Writes | `$AD3E`-`$AD4B` (`SpriteShiftRound`, `SpriteShiftCopy`); `$E7A8`-`$EA47` (`SpriteCacheImages`) |

### `SpriteShiftRound` (`$AD38`)

**SpriteShiftRound**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 217 calls, 12,803 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 189 calls, 11,151 t-states own (0.00 %) |
| Called from | `SpriteBuildShifts`, `SpriteShiftNext` (tail) |
| Calls | `SpriteShiftCopy` |

### `SpriteShiftCopy` (`$AD44`)

**SpriteShiftCopy**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 222 calls, 339,266 t-states own (0.05 %) |
| Runs (r1, the bot over level 1 with the weapons) | 196 calls, 299,068 t-states own (0.05 %) |
| Called from | `l_AB07`, `SpriteShiftRound` |
| Calls | `RotateSprite`, `InterruptJump` |
| Reads | `$E748`-`$EB7F` (`SpriteCacheImages`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF0`-`$5BF1` (system); `$E790`-`$EBC7` (`SpriteCacheImages`) |

### `SpriteShiftNext` (`$AD50`)

**SpriteShiftNext**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 25 calls, 9,486 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 33 calls, 8,262 t-states own (0.00 %) |
| Called from | `l_8F6F` |
| Calls | `SpriteBuildDone`, `SpriteShiftRound` (tail) |

### `RestoreCheckpoint` (`$AD56`)

**the wave script's state back from the player record**

Copies the player record's +`$0D`-+`$2F` (35 bytes, the checkpoint that CmdCheckpoint `$AED2` and SetLevelStart `$B062` write) to the VM state ScriptState `$81D7-$81F9`. Called by RoundSetup (`$B023`), so a level restarts at its last checkpoint after a lost life. 48K c2: 1 entry.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 14,346 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 1,594 t-states own (0.00 %) |
| Called from | `EffectPlay` |
| Reads | `$7F99`-`$7FCB` (`PlayerRecord`, `Players`, `Player1`) |
| Writes | `$81D7`-`$81F9` (`ScriptState`) |

## wavescript

`src/game/wavescript.asm`

### `WaveScriptStep` (`$AD66`)

**one frame of the level's script**

Called from the play interrupt at phase 2 (`$AA96`; 48K c2: 165 entries, one in four of its 659 passes), returns at once unless DeathTimer (`$7F7B`) is `$FF`. When the wait counter (`$81E1`) equals the delay byte at the PC (`$81D8`): the counter is zeroed, the opcode is read and run, and the next instruction is looked at at once; else the counter + 1 and return. Callees: JumpTable `$91E2` (commands), LaunchWave `$91EC` (waves), ScriptWord, ScriptByte, ScriptTest.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 806 calls, 81,683 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 865 calls, 135,077 t-states own (0.02 %) |
| Runs (r2, homing missiles at the guardian) | 125 calls, 29,424 t-states own (0.04 %) |
| Called from | `PlayPass` |
| Calls | `JumpTable`, `LaunchWave`, `ScriptWord`, `ScriptByte`, `ScriptTest` |
| Reads | `$6B8D`-`$6C48` (`LevelScripts`); `$7F7B` (`DeathTimer`); `$81D8`-`$81E1` (`ScriptState`) |
| Writes | `$81D8`-`$81E1` (`ScriptState`) |

### `ScriptSaveFlags` (`$ADD3`)

**keep F of the last word command for the conditions**

PUSH AF / POP HL takes F into L, stored in ScriptFlags `$81E2` (the conditions read `$81E2`/`$81E3` as an AF pair). Called by the word commands 9-12 and 17.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3 calls, 207 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 87 calls, 6,003 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 46 calls, 3,174 t-states own (0.00 %) |
| Called from | `CmdDecrement`, `CmdEnemiesLeft` |
| Writes | `$81E2` (`ScriptState`) |

### `ScriptWord` (`$ADDC`)

**DE = the next word of the script**

Reads the word at the PC (`$81D8`) and steps the PC past it; HL kept.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 40 calls, 3,560 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 162 calls, 14,418 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 71 calls, 6,319 t-states own (0.01 %) |
| Called from | `WaveScriptStep`, `CmdStore`, `CmdDecrement` |
| Reads | `$6B92`-`$6BA6` (`LevelScripts`); `$6BC6`-`$6BEB` (`LevelScripts`); `$6BFE`-`$6C4A` (`LevelScripts`); `$81D8`-`$81D9` (`ScriptState`) |
| Writes | `$81D8`-`$81D9` (`ScriptState`) |

### `ScriptByte` (`$ADE9`)

**C = the next byte of the script**

Reads the byte at the PC and steps it; HL kept.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 39 calls, 2,964 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 91 calls, 6,916 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 76 t-states own (0.00 %) |
| Called from | `WaveScriptStep` |
| Reads | `$6B8F`-`$6BFB` (`LevelScripts`); `$6C22`-`$6C42` (`LevelScripts`); `$81D8`-`$81D9` (`ScriptState`) |
| Writes | `$81D8`-`$81D9` (`ScriptState`) |

### `ScriptTest` (`$ADF4`)

**carry when the condition A holds**

In: A the condition (0-6). Out: carry when it holds; A, BC, DE, HL kept (A is the condition again). The saved flags `$81E2`/`$81E3` are loaded into AF' and the test routine (ScriptConditions `$8223` through `$91E2`) takes them with EX AF,AF'.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3 calls, 522 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 87 calls, 15,138 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 46 calls, 8,004 t-states own (0.01 %) |
| Called from | `WaveScriptStep` |
| Calls | `JumpTable` |
| Reads | `$81E2`-`$81E3` (`ScriptState`) |

### `CondAlways` (`$AE0C`)

**condition 0: always (SCF)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CondZero` (`$AE0E`)

**condition 1: Z of the saved flags**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CondNonZero` (`$AE13`)

**condition 2: NZ of the saved flags (the only one the scripts use)**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 57 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 1,701 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 874 t-states own (0.00 %) |
| Called from | `JumpTable` |

### `CondPositive` (`$AE18`)

**condition 5: P of the saved flags**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CondNegative` (`$AE1D`)

**condition 6: M of the saved flags**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CondCarry` (`$AE22`)

**condition 3: the saved carry**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CondNoCarry` (`$AE24`)

**condition 4: the saved carry inverted**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdNop` (`$AE27`)

**command 0: nothing (2 uses)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdSetFlag` (`$AE28`)

**command 1: `$81E3` = `$FF` (never used by the scripts)**

`$81E3` is the byte after ScriptFlags, so it is A of the AF pair the conditions load; SetLevelStart zeroes it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdScrollStop` (`$AE2E`)

**command 2: the scroll stops (bit 5 of `$81DA` cleared; 9 uses)**

Also called by CmdLevelEnd. The scroll (`$8AED` area) runs while bit 5 is set; a level's guardian section stops it.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 70 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 35 t-states own (0.00 %) |
| Called from | `JumpTable`, `CmdLevelEnd` |
| Reads | `$81DA` (`ScriptState`) |
| Writes | `$81DA` (`ScriptState`) |

### `CmdModeOn` (`$AE34`)

**command 3: bit 7 of the scroll flags `$81DA` set (never used)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdModeOff` (`$AE3A`)

**command 4: bit 7 of the scroll flags cleared (never used)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdLevelEnd` (`$AE40`)

**command 5: the level is done**

The scroll stops, EndPending (`$7F7C`) = 2 (the play loop ends with code 2: LevelDone `$B174` moves to the next level), the player record's +8 and +9 zeroed (the side weapon and the double plasma do not go on to the next level). The last instruction of all twelve scripts.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 109 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `CmdScrollStop` |
| Reads | `$7F99`-`$7F9A` (`PlayerRecord`) |
| Writes | `$7F7C` (`EndPending`); `$7FA4`-`$7FA5` (`Player1`) |

### `CmdNop2` (`$AE54`)

**command 6: nothing (never used)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdStore` (`$AE55`)

**command 7: (word 1) = word 2 (80 uses, all on the counter `$81E4`)**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 1,156 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 476 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 68 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ScriptWord` |
| Writes | `$81E4`-`$81E5` (`ScriptState`) |

### `CmdCopy` (`$AE60`)

**command 8: (word 1) = (word 2) (never used)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdDecrement` (`$AE6D`)

**command 9: (word) - 1, the flags kept for the conditions (65 uses)**

The word is read, ADC HL,DE with HL = `$FFFF` gives word - 1 with Z when it reaches 0 (and carry unless it was 0); the flags go to ScriptFlags. With a following 'jump NZ' it is the loop 'repeat n times'.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 426 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 8,662 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 3,266 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ScriptSaveFlags`, `ScriptWord` |
| Reads | `$81E4`-`$81E5` (`ScriptState`) |
| Writes | `$81E4`-`$81E5` (`ScriptState`) |

### `CmdIncrement` (`$AE84`)

**command 10: (word) + 1, the flags kept (never used)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdTest` (`$AE9B`)

**command 11: the flags of (word) (0 + word with ADC; never used)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdAdd` (`$AEAC`)

**command 12: the flags of (word 1) + word 2 (never used)**

It keeps the flags of the sum but stores word 2 itself, not the sum (LD (HL),E / LD (HL),D after POP HL): a command no script uses, so the slip never shows.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdReturn` (`$AEC3`)

**command 13: return from a script call (never used)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdCheckpoint` (`$AED2`)

**command 14: the checkpoint (11 uses)**

Copies the VM state `$81D7-$81F9` (35 bytes, PC past this instruction) to the player record's +`$0D`: a lost life restarts the level here (RestoreCheckpoint, then LevelStart replays the scroll count). Measured (../zynaps/work/f4/invuln.py): level 0's checkpoint moved from `$6B8D` (replay `$40`) to `$6BC4` with the replay count `$122` between frames 1000 and 2000; with no checkpoint passed a death restarted the script at `$6B8D`.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 801 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Reads | `$7F99`-`$7F9A` (`PlayerRecord`); `$81D7`-`$81F9` (`ScriptState`) |
| Writes | `$7FA9`-`$7FCB` (`Player1`) |

### `CmdResetRecords` (`$AEE3`)

**command 15: reset the 18 records of 32 bytes at `$F12C` (8 uses)**

For each record: +8 = 0, +6/+7 = `$85E4`; then of the 32 bytes below its pointer (+0/+1) every one whose byte `$40` higher is 0 is cleared. F6's buffers at `$F12C`; the pointers lead into the map work space.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 26,914 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 26,914 t-states own (0.04 %) |
| Called from | `JumpTable` |
| Reads | `$B75F`-`$BC7E` (`MapRingSpace`, `TileSource`); `$BCDF`-`$BCFE` (`TileSource`); `$BD5F`-`$BD7E` (`TileSource`); `$BDDF`-`$BDFE` (`TileSource`); `$BE5F`-`$BE7E` (`TileSource`); `$BEDF`-`$BEFE` (`TileSource`); 10 more ranges |
| Writes | `$B71F`-`$B8BE` (`Start`, `MapRingSpace`); `$B92E`-`$BCBE` (`MapRingSpace`, `TileSource`); `$BD1F`-`$BD3E` (`TileSource`); `$BDAE`-`$BDBE` (`TileSource`); `$BE1F`-`$BE3E` (`TileSource`); `$BE9F`-`$BEBE` (`TileSource`); 10 more ranges |

### `CmdEnemyEscape` (`$AF16`)

**command 16: when the enemy record `$F398` is active, EnemyEscaped `$994A` and FreeEnemySlot `$992A` (5 uses)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdEnemiesLeft` (`$AF26`)

**command 17: NZ while one of the five enemies at `$F398` lives (15 uses)**

A record counts when +8 has bits 5 and 7 set and +`$0D` is not `$FF`. The flags go to ScriptFlags: the script's 'jump NZ' back waits for the wave to be shot down.

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 4,002 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 3,266 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ScriptSaveFlags` |
| Reads | `$F3A0`-`$F3A5` (`EnemyObjects`); `$F3CC` (`EnemyObjects`); `$F3F8` (`EnemyObjects`); `$F424` (`EnemyObjects`); `$F450` (`EnemyObjects`) |

## rounds

`src/game/rounds.asm`

### `LevelStart` (`$AF49`)

**the level banner and the scroll to the start point**

LevelSetUp `$8C3B` (the playfield model, the map buffer), MenuScreenSetup `$A685`, sets the print position (`$80B0` = `$60`, `$80B9` = `$4B`), prints message `$18` (`$A423`), sets `$801F` = `$10` and `$801E` = `$60`, StartScript `$8D35` (the scenery script); then ReplayScroll. Called by RoundSetup; 48K c2: 1 entry.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 2,790 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 310 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Calls | `LevelSetUp`, `StartScript`, `PrintMessage`, `MenuScreenSetup` |
| Writes | `$801E`-`$801F` (`ScriptColumn`, `ScriptRoom`); `$80B0`-`$80B9` (`RasterLines`, `RasterList`, `RasterSpare`, `RasterFrames`) |

### `ReplayScroll` (`$AF6B`)

**ReplayScroll**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 2,358 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 287 t-states own (0.00 %) |
| Called from | `YieldScript` |
| Calls | `ReplayStep` (tail) |
| Reads | `$81DB`-`$81DC` (`ScriptState`) |
| Writes | `$7F76` (`SkipDraw`); `$81DB`-`$81DC` (`ScriptState`) |

### `ReplayColumns` (`$AF90`)

**scroll BC columns, ReplayFast = A**

A is stored in ReplayFast (`$7F76`, read by `$8DCA`: `$FF` skips the drawing). Each column: StartColumn `$894D` and three rounds of ResumeScript `$8D45` (the scenery script) and BuildColumn `$896D`, then ScrollStep `$8AED` scrolls one column (and counts `$81DB` up). 48K c2: AF9F 192 rounds at a level start.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReplayStep` (`$AF9A`)

**ReplayStep**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 27,648 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 2,688 t-states own (0.00 %) |
| Called from | `ReplayScroll` (tail) |
| Calls | `StartColumn`, `ReplayRound` |

### `ReplayRound` (`$AF9F`)

**ReplayRound**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 3,456 calls, 96,768 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 336 calls, 9,408 t-states own (0.00 %) |
| Called from | `ReplayStep`, `ReplayRoundEnd` (tail) |
| Calls | `ResumeScript` |

### `ReplayRoundEnd` (`$AFA3`)

**ReplayRoundEnd**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 450 calls, 205,832 t-states own (0.03 %) |
| Runs (r1, the bot over level 1 with the weapons) | 27 calls, 20,002 t-states own (0.00 %) |
| Called from | `YieldScript` |
| Calls | `BuildColumn`, `ScrollStep`, `ReplayRound` (tail), `RoundPlaySetup`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF8`-`$5BF9` (system) |

### `InterruptSetup` (`$AFB0`)

**the IM 2 table and a clear screen, once at the start**

SetUpInterrupts `$8516` (the IM 2 table) and ClearScreen `$858B`; called once by MainLoop (48K c1: 1 entry).

On a 128K: the glue makes the CALL `$858B` at `$AFB3` CALL ClearThenMusic (`$5B46`) (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1 call, 44 t-states own (0.00 %) |
| Called from | `MainLoop` |
| Calls | `SetUpInterrupts` |

### `PlayersSetup` (`$AFB7`)

**both player records and the level order of a new game**

CurrentPlayer `$7F98` = 1, PlayerRecord `$7F99` = `$7F9C`; both records (96 bytes from `$7F9C`) zeroed; player 1's lives = 2, player 2's = 3 when Players (`$7F9B`) is 2, else 0; the speed +`$0B` = `$40` and the laser level +`$0A` = 1 for both; SetLevelStart for each (both at level 0). Then LevelOrder `$8006-$800B`: six different numbers 3-8 drawn from Random `$8544` (one game measured: 07 06 05 04 08 03, ../zynaps/work/f4/invuln.py). Called by MainLoop.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 6 calls, 37,082 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 5,291 t-states own (0.00 %) |
| Called from | `MainLoop`, `l_B207` |
| Calls | `Random`, `SetLevelStart` |
| Reads | `$7F9B`-`$800B` (`Players`, `Player1`, `Player2`, `BcdScratch` and 2 more) |
| Writes | `$7F98`-`$800B` (`CurrentPlayer`, `PlayerRecord`, `Players`, `Player1` and 4 more) |

### `RoundSetup` (`$B023`)

**a level's start: the checkpoint, the objects, the banner, the panel**

RestoreCheckpoint, EnemiesSetup, ShotsSetup, PlayerSetup; the player's digit '0' + Player at `$84BB` (the banner's text), LevelStart; then RoundPlaySetup (`$B03A`). Called by MainLoop before each play loop (48K c2: 1 entry).

On a 128K: the glue makes the CALL `$AD56` at `$B023` CALL LevelStartSound (`$5B6D`): the music off, sound `$10` (the engine's `$C9A5`), then `$AD56` (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

WaitMenuRasterEnd `$A595`, ClearHitGrid `$91C6` with interrupts off, Fuel = `$5A`, DeathTimer = `$FF` (the script runs), ClearScreen `$858B`, RestorePanel `$A979`, both scores (PrintPlayerScore `$A4AE` with 1 and 2), the lives (DrawLives `$A4EF`), WeaponRating `$9B75`.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 2,124 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 236 t-states own (0.00 %) |
| Called from | `MainLoopRound` |
| Calls | `LevelStart`, `PlayerSetup`, `EnemiesSetup`, `ShotsSetup` |
| Reads | `$7F98` (`CurrentPlayer`) |
| Writes | `$84BB` (`Messages`) |

### `RoundPlaySetup` (`$B03A`)

**RoundPlaySetup**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 3,690 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 410 t-states own (0.00 %) |
| Called from | `ReplayRoundEnd` |
| Calls | `ClearScreen`, `ClearHitGrid`, `WeaponRating`, `PrintPlayerScore`, `DrawLives`, `WaitMenuRasterEnd`, `RestorePanel`, `MainLoopPlay` |
| Writes | `$7F7B` (`DeathTimer`); `$80E6` (`Fuel`) |

### `SetLevelStart` (`$B062`)

**a level's start into a player record's checkpoint**

In: IX the record. +5 = 0, `$81E3` = 0; the record's +`$0D` gets the 8 bytes of the level entry `$6B2D` + 8 * LevelOrder[+6] (the ScriptState `$81D7-$81DE`: +1 the PC, +3 the scroll flags `$FF`, +4 the replay count), then the 5 bytes at `$81FA` (the stack pointer `$81F6`, zeros). Called by PlayersSetup for both players and by LevelDone.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 12 calls, 5,880 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 3 calls, 1,494 t-states own (0.00 %) |
| Called from | `PlayersSetup`, `LevelDone` |
| Reads | `$6B2D`-`$6B3C` (`LevelTable`); `$7FA2` (`Player1`); `$7FD2` (`Player2`); `$8003`-`$8004` (`LevelOrder`); `$81FA`-`$81FE` (`ScriptStateInit`) |
| Writes | `$7FA1`-`$7FB5` (`Player1`); `$7FD1`-`$7FE5` (`Player2`); `$81E3` (`ScriptState`) |

### `CreditsPage` (`$B095`)

**the title page with both players' scores and the tune**

ClearScreen `$858B`, PrintMessage `$15`, the scores of both players at `$5AA0` and `$5AB8` (PrintBcd `$A43E` of record +0, C = '0') with the colour `$05`, plays the title tune (TitleTune `$B446`, until fire or keys 1-5), MenuKeys `$A76F`, then TitleFireCheck (`$A748`: carry = fire). 48K c1: 2 entries. Called by MainLoop.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 6 calls, 1,476 t-states own (0.00 %) |
| Called from | `MainLoop` |
| Calls | `ClearScreen`, `PrintMessage`, `PrintBcd`, `TitleFireCheck`, `MenuKeys`, `TitleTune` |
| Writes | `$80AA`-`$80AC` (`PrintPos`, `PrintAttr`) |

### `l_B0C2` (`$B0C2`)

**l_B0C2**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 44 t-states own (0.00 %) |
| Calls | `TitleFireCheck`, `MenuKeys` |

### `HiScorePage` (`$B0C9`)

**the high score table, 500 frames or fire**

ClearScreen, PrintMessage `$16`, the five entries of HiScoreTable `$8261` (14 bytes each: the 10-byte print string with the initials through PrintString `$A401`, then the 4 BCD bytes through PrintBcd `$A43E` with C = '.') in `$46`; then 500 HALTs with TitleFireCheck polled. Out: carry when fire was pressed. 48K c1: 1 entry, 30 permille of the recording (the page's 10 s wait).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1 call, 25,611,282 t-states own (3.44 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 12,569,066 t-states own (2.28 %) |
| Called from | `MainLoop`, `l_B207` |
| Calls | `ClearScreen`, `PrintString`, `PrintMessage`, `PrintBcd`, `TitleFireCheck`, `InterruptJump` |
| Reads | `$B0F2` (`HiScorePage`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFC`-`$5BFD` (system); `$80AC` (`PrintAttr`) |

## mainloop

`src/game/mainloop.asm`

### `EndOfPlay` (`$B0FF`)

**after the play loop: dispatch on the end code**

In: A the end code (1-4). WaitFrames `$A6AE` for 50 frames, FadeAttributes `$85AD`, then EndHandlers (`$B111`) through `$91E2` with code - 1. Out: carry when the game is over (from PlayerDied). Called by MainLoop.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 17 calls, 1,751 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 103 t-states own (0.00 %) |
| Called from | `MainLoopEnd` |
| Calls | `FadeAttributes`, `JumpTable`, `WaitFrames` |

### `PlayerDied` (`$B119`)

**end code 1: a life lost**

The record's deaths +5 + 1, +8 and +9 zeroed (the side weapon and the double plasma are lost), FuelOut `$9C03` (Fuel = `$5A`, the laser level and the speed one step down). With no lives left: HighScoreEntry `$A7F7`, NextPlayer, and carry when the lives went negative (the game is over); with lives: NextPlayer and NC. 48K c2: 1 entry (indirect).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 3,226 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `FuelOut`, `HighScoreEntry`, `NextPlayer` |
| Reads | `$7F99`-`$7FA1` (`PlayerRecord`, `Players`, `Player1`) |
| Writes | `$7FA1`-`$7FA5` (`Player1`) |

### `NextPlayer` (`$B149`)

**the other player's turn, one life less**

One player: the life is taken from the current record. Two: when the other record has lives, it becomes PlayerRecord and Player flips (1 <-> 2); a life of the record in play then is taken (`$B170`).

With INF.LIVES (on either machine) the set-up makes the DEC (IX+4) at `$B170` OR (IX+4): the lives never drop (src/game/setup.asm).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 17 calls, 1,054 t-states own (0.00 %) |
| Called from | `PlayerDied` |
| Reads | `$7F9B`-`$7FA0` (`Players`, `Player1`) |
| Writes | `$7FA0` (`Player1`) |

### `LevelDone` (`$B174`)

**end code 2: the next level**

The record's +6 + 1, wrapping from 12 to 0, SetLevelStart. Not in 48K c1 or 48K c2; 48K r1 (the long bot run, 75001 frames) ran it 11 times (frames 6257-67115); seen in ../zynaps/work/f4/invuln.py (Invulnerable on, 30000 frames): level 0 ended near frame 6500, 1 near 14500, 2 near 20500, 3 near 27500, and with LevelOrder 00 01 02 07 06 05 04 08 03 09 0A 0B the scripts ran `$6B8D`, `$6C1A`, `$6C97`, `$70F6` (order 7), `$7068` (order 6).

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 129 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SetLevelStart` |
| Reads | `$7F99`-`$7FA2` (`PlayerRecord`, `Players`, `Player1`) |
| Writes | `$7FA2` (`Player1`) |

### `AbortGame` (`$B18A`)

**end codes 3 and 4: back to the title pages**

DI, TitleInterrupt `$A9E4`, SP = `$5C00` (whatever the stack held), JP MainLoopTitle: CreditsPage comes next. Code 4 is set by key Q in the pause.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Pause` (`$B197`)

**the pause: fire resumes, Q aborts**

StopAndSettle, then a loop: a delay of `$2000` rounds, TitleFireCheck (`$A748`: fire, back to play), key Q (half row `$FBFE`, bit 0): EndPending = 4 (the play loop ends, AbortGame). Called by CheckPauseAndEnd on key 4, inside the play interrupt: the whole game stands. Measured (../zynaps/work/f4/pause.py): after key 4, PassCount `$7F62` stayed `$4D` and the script PC `$6B96` for 400 frames; Q gave `$7F7C`/`$7F7D` = 4/4, Handler `$A9E4` and the credits page.

On a 128K: the glue makes the LD (`$7F7C`),A at `$B1B0` JP Key4MusicOn (`$5B82`): the store, then the music on (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlayLoop` (`$B1B4`)

**a life or a level of play**

FrameRate `$7F6A` = `$C8`, `$7F6B` = 8; EventRequests = 0 and EventMask = `$FF`, then bit 2 posted (the pod icon); `$7F65` (the interrupt phase), `$7F64`, CurrentEffect `$7F97`, EndPending, EndCode and `$974C` zeroed; one frame, the play handler `$A9ED`; then EventDispatch round after round (48K c2: 68083) until EndCode is set. The play interrupt does the frame's work meanwhile. Then TitleInterrupt, SavePanel `$A98D`, and A = EndCode. Called by MainLoop.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 85,148 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 9,160 t-states own (0.00 %) |
| Called from | `MainLoopPlay` |
| Calls | `PlayLoopPass`, `InterruptJump` |
| Reads | `$81C5` (`EventRequests`); `$B1DE` (`PlayLoop`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFC`-`$5BFD` (system); `$7F64`-`$7F6B` (`PassDepth`, `PassPhase`, `ChainStep`, `NodeFreeList` and 2 more); `$7F7C`-`$7F7D` (`EndPending`, `EndCode`); `$7F97` (`CurrentEffect`); `$81C5`-`$81C6` (`EventRequests`, `EventMask`); `$974C` (`LandingFlag`); 1 more ranges |

### `PlayLoopPass` (`$B1E6`)

**PlayLoopPass**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,271,072 calls, 21,612,682 t-states own (2.90 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,332,849 calls, 22,662,893 t-states own (4.11 %) |
| Runs (r2, homing missiles at the guardian) | 289,739 calls, 4,927,159 t-states own (6.87 %) |
| Called from | `l_AB07`, `PlayLoop`, `PlayLoopAgain` (tail) |
| Calls | `EventDispatch`, `InterruptJump` |

### `PlayLoopCheck` (`$B1E9`)

**PlayLoopCheck**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,994 calls, 16,526,771 t-states own (2.22 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2,091 calls, 17,330,847 t-states own (3.14 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 3,768,070 t-states own (5.25 %) |
| Called from | `l_AB07`, `EventAny`, `EventDone` |
| Calls | `PlayLoopTest`, `InterruptJump` |
| Reads | `$7F7D` (`EndCode`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFC`-`$5BFD` (system) |

### `PlayLoopTest` (`$B1EC`)

**PlayLoopTest**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,271,093 calls, 5,085,305 t-states own (0.68 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,332,915 calls, 5,332,314 t-states own (0.97 %) |
| Runs (r2, homing missiles at the guardian) | 289,739 calls, 1,159,412 t-states own (1.62 %) |
| Called from | `l_AB07`, `PlayLoopCheck` |
| Calls | `PlayLoopBranch`, `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFC`-`$5BFD` (system) |

### `PlayLoopBranch` (`$B1ED`)

**PlayLoopBranch**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,270,805 calls, 8,900,660 t-states own (1.20 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,332,561 calls, 9,332,531 t-states own (1.69 %) |
| Runs (r2, homing missiles at the guardian) | 289,739 calls, 2,028,933 t-states own (2.83 %) |
| Called from | `l_AB07`, `PlayLoopTest` |
| Calls | `SavePanel`, `PlayLoopAgain`, `MainLoopEnd`, `InterruptJump` |
| Reads | `$7F7D` (`EndCode`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFC`-`$5BFD` (system); `$FDFE`-`$FDFF` (`InterruptJump`) |

### `PlayLoopAgain` (`$B1EF`)

**PlayLoopAgain**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1,270,894 calls, 15,255,483 t-states own (2.05 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1,332,711 calls, 15,997,139 t-states own (2.90 %) |
| Runs (r2, homing missiles at the guardian) | 289,739 calls, 3,478,179 t-states own (4.85 %) |
| Called from | `l_AB07`, `PlayLoopBranch` |
| Calls | `PlayLoopPass` (tail), `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BFC`-`$5BFD` (system) |

### `MainLoop` (`$B200`)

**the game's top loop**

Entered from Start (`$B72C`). InterruptSetup, then the title pages until fire, PlayersSetup, and the rounds of RoundSetup, PlayLoop and EndOfPlay. Never returns.

On a 128K: the glue makes the CALL `$AFB0` at `$B200` CALL MusicOn (`$5B49`, the music on); the menu loop's JR `$B203` at `$B21A` becomes JR `$B200`, so after a game it passes that CALL again: the music starts again (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

With K-MOUSE the CALL `$B1B4` at `$B212` becomes CALL MouseReset (`$FE00`) at a life's start (src/game/setup.asm).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 6 calls, 439 t-states own (0.00 %) |
| Called from | `MainLoopEnd` (tail), `Start` (tail) |
| Calls | `InterruptSetup`, `PlayersSetup`, `CreditsPage`, `HiScorePage` |

### `l_B207` (`$B207`)

**l_B207**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 41 t-states own (0.00 %) |
| Calls | `PlayersSetup`, `HiScorePage` |

### `MainLoopRound` (`$B20F`)

**MainLoopRound**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 12 calls, 306 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 34 t-states own (0.00 %) |
| Called from | `MainLoopEnd` (tail) |
| Calls | `RoundSetup` |

### `MainLoopPlay` (`$B212`)

**MainLoopPlay**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 306 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 34 t-states own (0.00 %) |
| Called from | `RoundPlaySetup` |
| Calls | `PlayLoop` |

### `MainLoopEnd` (`$B215`)

**MainLoopEnd**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 17 calls, 528 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 29 t-states own (0.00 %) |
| Called from | `PlayLoopBranch` |
| Calls | `EndOfPlay`, `MainLoop` (tail), `MainLoopRound` (tail) |

### `PlayerSetup` (`$B21C`)

**the player's ship and the objects tied to it**

The ship's record `$F36C`: X 0/`$14`, Y 0/8, active (bit 7 of +8), +`$25` = `$68`; `$F37C` = `$20`, `$F380` = `$40`; the record `$F600` inactive; `$80BF` = 0. Then eight pairs of words below `$80E0` written by PUSHes with SP moved there (DE = `$0800`, HL = `$1400`: 32 bytes `$80C0-$80DF`) with interrupts off. `$F5D4` and `$F5A8` inactive. When the record's side weapon +8 is 2 or more (2 plasma, 3 homing missiles, 4 seeker), +8 = 0 and its pod action runs again through the pod table `$80F0` (PodPlasma, PodHoming, PodSeeker), which arms it anew for the new ship. Called by RoundSetup.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 12,726 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 1,414 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Reads | `$7F99`-`$7FA4` (`PlayerRecord`, `Players`, `Player1`); `$F374` (`PlayerObject`); `$F5B0` (`PlasmaBall2`); `$F5DC` (`SideShot`); `$F608` (`SightObject`) |
| Writes | `$80BF` (`ShipHistoryIndex`); `$B263`-`$B264` (`PlayerSetup`); `$F36F`-`$F380` (`PlayerObject`); `$F391` (`PlayerObject`); `$F5B0` (`PlasmaBall2`); `$F5DC` (`SideShot`); 1 more ranges |

### `EnemiesSetup` (`$B28B`)

**the five enemy records inactive, then the pod objects**

The five records of `$2C` bytes at `$F398`: inactive (bit 7 of +8), +`$26` = `$E0`, +`$27` = `$80`. Then PodsSetup. Called by RoundSetup.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 11,593 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 1,286 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Calls | `PodsSetup`, `InterruptJump` |
| Reads | `$F3A0` (`EnemyObjects`); `$F3CC` (`EnemyObjects`); `$F3F8` (`EnemyObjects`); `$F424` (`EnemyObjects`); `$F450` (`EnemyObjects`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF8`-`$5BF9` (system); `$F3A0` (`EnemyObjects`); `$F3BE`-`$F3CC` (`EnemyObjects`); `$F3EA`-`$F3F8` (`EnemyObjects`); `$F416`-`$F424` (`EnemyObjects`); `$F442`-`$F450` (`EnemyObjects`); 1 more ranges |

### `PodsSetup` (`$B2AA`)

**the three objects at `$F474` tied to the ship**

Three records of `$2C` bytes at `$F474`: +`$25` = `$48`, kind +7 = 5, inactive, +`$29`/+`$2A` = `$F36C` (the ship's record).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 9,540 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 1,060 t-states own (0.00 %) |
| Called from | `EnemiesSetup` |
| Reads | `$F47C` (`EnemyShots`); `$F4A8` (`EnemyShots`); `$F4D4` (`EnemyShots`) |
| Writes | `$F47B`-`$F47C` (`EnemyShots`); `$F499`-`$F4A8` (`EnemyShots`); `$F4C5`-`$F4D4` (`EnemyShots`); `$F4F1`-`$F4F6` (`EnemyShots`) |

### `ShotsSetup` (`$B2CF`)

**the four shot records inactive**

`$80BA` = 4; four records of `$2C` bytes at `$F4F8`: +`$0B` = `$80`, +`$25` = `$78`, inactive.

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 9,487 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 1,052 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Calls | `InterruptJump` |
| Reads | `$F500` (`LaserShots`); `$F52C` (`LaserShots`); `$F558` (`LaserShots`); `$F584` (`LaserShots`); `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF8`-`$5BF9` (system); `$80BA` (`LaserShotsFree`); `$F500`-`$F503` (`LaserShots`); `$F51D`-`$F52F` (`LaserShots`); `$F549`-`$F55B` (`LaserShots`); `$F575`-`$F587` (`LaserShots`); 1 more ranges |

## effects

`src/game/effects.asm`

### `RequestEffect` (`$B2F0`)

**ask for effect A (0 = stop), taken when not below the one playing**

In: A the effect, 0 is stored as `$80` (above every effect: a stop always wins). Taken when A >= CurrentEffect (`$7F97`): CurrentEffect = A, EffectTick = `$80` (new effect), event bit 0 posted. HL kept. Callers (48K c2): FireLaser `$9C1D` x61, `$A2D6` x2, `$A0EB` x1, StopAndSettle x2; in the listing also A = 1 (`$A1C2`), 2 (`$9C75`, the laser: FireLaser), 4 (`$A31B`), 5 (`$A224`, a pod) and 6 (`$A21D`).

On a 128K: the glue makes its first byte a RET: the beeper effects are off (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 18 calls, 180 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 46 calls, 460 t-states own (0.00 %) |
| Called from | `PlasmaHandler`, `PodStep`, `StopAndSettle` |

### `EffectPlay` (`$B30C`)

**play CurrentEffect until it ends or a new request**

Entered from EffectJob (event bit 0; 48K c2: 106 entries in 73 frames, 45 from EffectJob and 61 restarts by a new request at `$B388`). n = CurrentEffect & `$1F`, 0 ends at once; the entry `$7E5A` + 8 (n - 1) is copied to the effect state `$7F8A-$7F90` (+0-+6) and its byte 7 split into SegLenA `$7F91` and SegLenB `$7F92`; the pitches PitchA `$7F93` and PitchB `$7F94` start from +0 and +2, the frame counter `$7F95` from SegLenA. The tone loop runs until an interrupt sets EffectTick, then calls EventDispatch (the jobs run) and steps the pitches; at a segment's end the segment's changes apply. Ends (CurrentEffect = 0) when the segments run out or a job ran (the carry from EventDispatch: an effect stops for the redraw jobs and the next effect request starts it again). EffectTick = `$80` restarts with the new effect.

On a 128K: the glue makes its first byte a RET, and the set-up copies the hook stubs over `$B30D-$B3A8` (src/game/stubs.asm) (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 56,490 t-states own (0.01 %) |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 112,140 t-states own (0.02 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 6,300 t-states own (0.01 %) |
| Called from | `l_B32F` (tail), `l_B33C` (tail), `EffectTickRead` (tail), `l_B374` (tail), `EffectAfterJobs` (tail), `l_B386` (tail), `l_B39C` (tail) |
| Calls | `RestoreCheckpoint` |
| Writes | `$B31F`-`$B320` (`EffectPlay`) |
| Ports out | `$7FFD` |

### `l_B32F` (`$B32F`)

**l_B32F**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 91 calls, 2,730 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 307 calls, 9,257 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 20 calls, 600 t-states own (0.00 %) |
| Called from | `FireLaser`, `ScoreJobRating` |
| Calls | `DrawLives`, `EffectPlay` (tail) |

### `l_B33C` (`$B33C`)

**l_B33C**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | run into, not called, 1,291 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 22 calls, 2,115 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 94 t-states own (0.00 %) |
| Called from | `ScatterDebris`, `HomingFrame`, `PlasmaHandler`, `PodStep`, `HighScoreEntry`, `HighScoreDone` |
| Calls | `SceneryAt1`, `PlaceAtPlayer`, `PrintMessage`, `AddScore`, `WaitMenuRasterEnd`, `EffectPlay` (tail) |
| Writes | `$8072` (`FreeEnemySlots`) |

### `EffectTickRead` (`$B36C`)

**EffectTickRead**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 9 calls, 360 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 2 calls, 80 t-states own (0.00 %) |
| Called from | `PlasmaFrame`, `PlaceAtPlayer` |
| Calls | `EffectPlay` (tail) |

### `l_B374` (`$B374`)

**l_B374**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 6 calls, 180 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 50 calls, 1,500 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 4 calls, 120 t-states own (0.00 %) |
| Called from | `EnemyFire` |
| Calls | `EffectPlay` (tail) |

### `EffectAfterJobs` (`$B379`)

**EffectAfterJobs**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1 call, 167 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 2 calls, 964 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | run into, not called, 30 t-states own (0.00 %) |
| Called from | `PodStep`, `ExplosionToPod` |
| Calls | `JumpTable`, `EffectPlay` (tail) |

### `l_B386` (`$B386`)

**l_B386**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 115 calls, 4,370 t-states own (0.00 %) |
| Runs (r1, the bot over level 1 with the weapons) | 88 calls, 3,403 t-states own (0.00 %) |
| Runs (r2, homing missiles at the guardian) | 1 call, 38 t-states own (0.00 %) |
| Called from | `StartExplosion`, `SelectOnePlayer` |
| Calls | `EffectPlay` (tail) |

### `l_B39C` (`$B39C`)

**l_B39C**

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 5 calls, 330 t-states own (0.00 %) |
| Called from | `HighScoreEntry` |
| Calls | `MenuScreenSetup`, `EffectPlay` (tail) |

## tune

`src/game/tune.asm`

### `TitleTune` (`$B446`)

**play the title tune until fire or a key 1-5**

DI; for each of the 7 patterns of TuneOrder: the notes until `$FF`, the length commands, the keys checked before each byte. EI and return. Called by CreditsPage (`$B0BF`). Reads `$FF1C-$FFD3`, TunePeriods, TuneDuration; ports: IN `$F7FE`, OUT `$FE` (bit 4 only: `$00`, `$10`).

On a 128K: the glue makes its DI a NOP (the tune runs with the interrupts on, so the engine keeps playing), and the OUT (`$FE`),A at `$B496` NOP: NOP: the tune is silent (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 6 calls, 11,847,884 t-states own (1.59 %) |
| Called from | `CreditsPage` |
| Calls | `TitleFireCheck`, `InterruptJump` |
| Reads | `$B4AD`-`$B4AE` (`TuneDuration`); `$FEFF`-`$FF41` (`VectorTable`, `TunePeriods`, `TuneOrder`, `TunePatternA`) |
| Writes | `$5BF4`-`$5BF5` (system); `$B4AE` (`TuneDuration`) |
| Ports in | `$F7FE` |

### `TuneByte` (`$B450`)

**TuneByte**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | 1 call, 87 t-states own (0.00 %) |
| Called from | `TunePass` (tail) |
| Calls | `TitleFireCheck` |
| Ports in | `$F7FE` |

### `TunePass` (`$B486`)

**TunePass**

| | |
| --- | --- |
| Runs (r1, the bot over level 1 with the weapons) | run into, not called, 576,202 t-states own (0.10 %) |
| Calls | `TuneByte` (tail), `InterruptJump` |
| Reads | `$FEFF`-`$FF00` (`VectorTable`) |
| Writes | `$5BF4`-`$5BF5` (system) |

## start

`src/game/start.asm`

### `Start` (`$B6FF`)

**the start: the code below the screen, the complemented graphics, the main loop**

Entered by GameEntry's jump (`$B6FF`). DI, SP = `$5C00`; `$BC00-$C7FF` (3072 bytes) copied to `$5C00-$67FF` (the code and data block 2 put above, now in their run place below `$6800`); the bytes `$E000-$E747` (1864) and `$F048-$F107` (192) complemented (block 2 holds them inverted); JP MainLoop. Overwritten from `$B700` on by the playfield buffer at the first level start, so no restart comes back here (AbortGame jumps to MainLoopTitle).

| | |
| --- | --- |
| Runs (c1, the menu and six short games) | 1 call, 167,391 t-states own (0.02 %) |
| Called from | `GameEntry` (tail) |
| Calls | `MainLoop` (tail) |
| Reads | `$BC00`-`$C7FF` (`TileSource`, `WaveCellSource`); `$E000`-`$E747` (`SpritePad`, `PlayerSprite`, `SightSprite`, `ExplosionFrames` and 2 more); `$F048`-`$F107` (`PodSprite`) |
| Writes | `$5C00`-`$67FF` (system); `$E000`-`$E747` (`SpritePad`, `PlayerSprite`, `SightSprite`, `ExplosionFrames` and 2 more); `$F048`-`$F107` (`PodSprite`) |
