# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/c2` (the first play recording: level 1 from the start, 1500 frames), `work/r1` (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames), `work/zyB/w1` (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames), `work/zyB/w2` (tools/podbot.py with homing missiles to the end of level 0, 7600 frames), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`tilecopy`](11-data-reference.md#tilecopy) | `$61A8`-`$67FF` | 0 of 1 |
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
| [`scroll`](#scroll) | `$8912`-`$8C3A` | 19 of 20 |
| [`levels`](#levels) | `$8C3B`-`$8D34` | 1 of 1 |
| [`scenery`](#scenery) | `$8D35`-`$8EDA` | 11 of 12 |
| [`sprites`](#sprites) | `$8EDB`-`$90B4` | 22 of 22 |
| [`objgrid`](#objgrid) | `$90B5`-`$91EB` | 5 of 5 |
| [`waves`](#waves) | `$91EC`-`$9462` | 7 of 7 |
| [`movers`](#movers) | `$9463`-`$9929` | 31 of 32 |
| [`objutil`](#objutil) | `$992A`-`$9A5A` | 14 of 14 |
| [`player`](#player) | `$9A5B`-`$9C82` | 6 of 6 |
| [`weapons`](#weapons) | `$9C83`-`$9F87` | 16 of 16 |
| [`enemies`](#enemies) | `$9F88`-`$A0EA` | 3 of 3 |
| [`objects`](#objects) | `$A0EB`-`$A320` | 7 of 8 |
| [`print`](#print) | `$A321`-`$A488` | 26 of 27 |
| [`score`](#score) | `$A489`-`$A511` | 5 of 5 |
| [`menu`](#menu) | `$A512`-`$A6B5` | 11 of 11 |
| [`input`](#input) | `$A6B6`-`$A76E` | 2 of 2 |
| [`options`](#options) | `$A76F`-`$A7F6` | 3 of 3 |
| [`hiscore`](#hiscore) | `$A7F7`-`$A8BD` | 1 of 1 |
| [`panel`](#panel) | `$A8BE`-`$A9A0` | 3 of 5 |
| [`interrupts`](#interrupts) | `$A9A1`-`$AB12` | 11 of 11 |
| [`hud`](#hud) | `$AB13`-`$AC06` | 3 of 3 |
| [`events`](#events) | `$AC07`-`$AD65` | 27 of 27 |
| [`wavescript`](#wavescript) | `$AD66`-`$AF48` | 30 of 30 |
| [`rounds`](#rounds) | `$AF49`-`$B0FE` | 13 of 14 |
| [`mainloop`](#mainloop) | `$B0FF`-`$B2EF` | 19 of 20 |
| [`effects`](#effects) | `$B2F0`-`$B445` | 23 of 23 |
| [`tune`](#tune) | `$B446`-`$B4AE` | 1 of 3 |
| [`icons`](11-data-reference.md#icons) | `$B4AF`-`$B54E` | 0 of 1 |
| [`font`](11-data-reference.md#font) | `$B54F`-`$B6FE` | 0 of 1 |
| [`start`](#start) | `$B6FF`-`$B72E` | 1 of 1 |
| [`buffers`](11-data-reference.md#buffers) | `$B72F`-`$DFFF` | 0 of 4 |
| [`graphics`](11-data-reference.md#graphics) | `$E000`-`$F107` | 0 of 8 |
| [`records`](11-data-reference.md#records) | `$F108`-`$F7FF` | 0 of 10 |
| [`tables`](11-data-reference.md#tables) | `$F800`-`$FF00` | 0 of 8 |
| [`tunedata`](11-data-reference.md#tunedata) | `$FF01`-`$FFD3` | 0 of 6 |
| [`topcells`](11-data-reference.md#topcells) | `$FFD4`-`$FFFE` | 0 of 4 |

## gameentry

`src/game/gameentry.asm`

### `GameEntry` (`$8000`)

**JP Start: the loader's way in**

c1: entered once by the loader's relocation code at `$5B00` (frame 12323), a tail jump to Start (`$B6FF`). Nothing else jumps here.

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 1 call (`c1` 1) |
| Called from | `VectorTable` |
| Calls | `Start` (tail) |

## system

`src/game/system.asm`

### `SetUpInterrupts` (`$8516`)

**Install the IM 2 vector table and seed the random number generator**

Fills the 257 bytes `$FE00-$FF00` with `$FD`, writes JP `$A9E4` at `$FDFD`, sets I = `$FE` and IM 2. Interrupts stay disabled (DI on entry): the caller enables them.

Then seeds RandomSeed (`$7F71-$7F75`): each byte is R XOR the matching ROM byte at `$0000-$0004`.

Input: none. Output: A, B, DE, HL changed. Called once from the start-up (c1: 1 entry).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 1 call (`c1` 1) |
| Called from | `InterruptSetup` |

### `Random` (`$8544`)

**Next random number in A**

A shift-register generator over the five bytes `$7F71-$7F75`: rotates `$7F75` right through carry, mixes the neighbour bytes (nibble swap, XOR) and shifts the bytes down; the new `$7F71` byte is returned in A.

BC, DE and HL are preserved by storing them into the operands of the three loads at the end (`$8581`, `$8584`, `$8587`), so the routine needs no stack beyond its own return address (it is called while SP points into data, e.g. from InitStars).

Output: A random byte, F changed. Callers all over the game (stars, enemies, effects): the most called helper.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 303 calls, 105,190 t-states own (0.10 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 12,253 calls, 4,161,202 t-states own (0.08 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 546 calls, 188,830 t-states own (0.05 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 812 calls, 280,172 t-states own (0.05 %) |
| Called from | `InitStars`, `MoveStars`, `LaunchWave`, `PathOpRandomDirection`, `PathOpRandomSpeed`, `PathOpDive`, `ScatterDebris`, `EnemyFire` |
| Reads | `$7F71`-`$7F75` (`RandomSeed`) |
| Writes | `$7F71`-`$7F75` (`RandomSeed`); `$8582`-`$8589` (`RandomRestoreBC+1`, `RandomRestoreDE`, `RandomRestoreHL`) |

### `ClearScreen` (`$858B`)

**Fade out, then clear the attributes and the bitmap**

Calls FadeAttributes, waits for one frame, sets the border black, clears the attributes `$5800-$5AFF` to 0 and the bitmap `$4000-$57FF` to 0 (LD (HL),L with L = 0).

Input: none. Output: BC, DE, HL changed; interrupts enabled. c1: 4 entries (between the screens of the attract cycle and the game start).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 459,088 t-states own (0.44 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 22 calls, 5,049,962 t-states own (0.10 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 459,088 t-states own (0.09 %) |
| Runs (the other recordings) | 4 calls (`c1` 4) |
| Called from | `MenuScreenSetup`, `InterruptSetup`, `RoundPlaySetup`, `CreditsPage`, `HiScorePage` |
| Calls | `FadeAttributes` |
| Reads | `$4000`-`$5AFE` (screen); `$8599` (`ClearScreen+14`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$4000`-`$5AFF` (screen) |
| Ports out | `$00FE` |

### `FadeAttributes` (`$85AD`)

**Fade the whole attribute area to black in four steps**

Four passes over `$5800-$5AFF` (3 pages): each pass ANDs every attribute with the mask 7, 3, 1, 0 (the ink fades, paper and bright vanish at once), three frames (HALT) apart. Enables interrupts.

Output: BC, E, HL changed. Called by ClearScreen (c1: 4 entries).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 3 calls, 2,513,000 t-states own (2.40 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 33 calls, 27,636,614 t-states own (0.53 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3 calls, 2,512,552 t-states own (0.47 %) |
| Runs (the other recordings) | 4 calls (`c1` 4) |
| Called from | `ClearScreen`, `EndOfPlay` |
| Reads | `$5800`-`$5AFF` (screen); `$85B8`-`$85BA` (`FadeStep+6`, `FadeCell`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$5800`-`$5AFF` (screen) |

## playfield

`src/game/playfield.asm`

### `DrawPlayfield` (`$85CA`)

**Draw the 18 rows of the playfield**

Saves SP into the operand of RenderDone, clears the padding balance (the operand of RowEnd), sets RowsLeft (`$7F6F`) = 18 and IX = SP = `$F12C` (the first row record), then enters RowStart.

The rows run as a chain of RETs: RowStart pushes the attributes and returns into the row's head span node; each span handler returns into the next node; the sentinel node (`$85E4`) returns into RowEnd; RowEnd moves to the next record and jumps to RowStart or, after 18 rows, to RenderDone.

Called from the play interrupt `$A9ED` once a pass (two frames) while playing (c2: 659 entries in 1500 frames, all from `$A9ED`).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 659 calls, 60,206 t-states own (0.06 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 3,334,174 t-states own (0.06 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 273,041 t-states own (0.07 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 338,732 t-states own (0.06 %) |
| Called from | `PlayInterrupt` |
| Calls | `RowStart` (tail) |
| Writes | `$7F6F` (`RowsLeft`); `$85E1`-`$85E8` (`RenderDone+1`, `SentinelNode`, `RowEnd`) |

### `RenderDone` (`$85E0`)

**Restore the stack pointer and return to the frame handler**

The operand of LD SP is the SP that DrawPlayfield saved.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 659 calls, 13,428 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 760,264 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 65,546 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 79,754 t-states own (0.02 %) |
| Called from | `RowStar` (tail) |
| Calls | `PlayPass` |

### `RowEnd` (`$85E7`)

**End of a row: sprite strips, the star, padding, next row**

Reached by RET from the last span node. A = the padding balance (the operand, written at `$86BD`) + the row's glyph count (+8); kept in A'.

When the row has sprite strips (+`$15` the count, +`$16`/+`$17` the list) SP moves to the strip list and every strip entry is drawn by StripDraw; then RowStar draws the row's star.

Input: IX = the row record, B = the screen pixel high byte of the row. Output: falls through to the next row.

c2: 11592 entries (= 659 frames * 18 rows minus the frames cut short).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 11,592 calls, 1,072,154 t-states own (1.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 657,486 calls, 66,802,368 t-states own (1.27 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 53,586 calls, 4,814,059 t-states own (1.15 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 66,546 calls, 6,133,374 t-states own (1.15 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1`, `SpanDraw0` |
| Calls | `StripNext`, `RowStar` (tail) |
| Reads | `$F12F`-`$F363` (`RowRecords+3`) |

### `StripNext` (`$8602`)

**Return into the next strip entry**

SP points at a strip entry whose first word is StripDraw: the RET starts it. The DJNZ at `$8679` loops here once per strip.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 7,283 calls, 72,830 t-states own (0.07 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 502,608 calls, 5,026,080 t-states own (0.10 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 35,976 calls, 359,760 t-states own (0.09 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 48,513 calls, 485,130 t-states own (0.09 %) |
| Called from | `RowEnd`, `StripDraw` (tail) |
| Calls | `StripDraw` |

### `StripDraw` (`$8603`)

**Draw one sprite strip into a character row**

A strip entry (built by BuildObjectStrips) holds: the link to the next entry, a word B'/C' (C' = the sprite's colour), the start position (H = the column count, saved in the operand of StripCellsDone; L = the first attribute cell), then the cell bytes.

Per cell: an attribute whose low six bits are 0 (an empty cell) gets the sprite colour and the eight lines are written plainly (StripCellPlain); an attribute below 8 (black ink on black paper) is skipped (StripCellSkip); otherwise the lines are ANDed into the scenery (StripCellMask) and the cell keeps the scenery colour.

A' (the row's glyph count) is incremented for every drawn cell, so the padding counts strips as glyphs.

c2: 7168 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 7,168 calls, 5,781,900 t-states own (5.51 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 502,493 calls, 444,612,951 t-states own (8.48 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 35,865 calls, 27,914,455 t-states own (6.67 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 48,402 calls, 39,965,511 t-states own (7.52 %) |
| Called from | `StripNext` |
| Calls | `StripNext` (tail), `RowStar` |
| Reads | `$4022`-`$40FF` (screen); `$4122`-`$41FF` (screen); `$4222`-`$42FF` (screen); `$4322`-`$43FF` (screen); `$4422`-`$44FF` (screen); `$4522`-`$45FF` (screen); 10 more ranges |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 11 more ranges |

### `RowStar` (`$867B`)

**Draw the row's star, pad the row's time, step to the next row**

SP = the operand (saved at `$86E2`: the record + 8); SP + `$14` = the record + `$1C`: POP HL = the star's position (L) and screen high byte, POP AF = its flags (carry: visible) and colour.

A visible star on an empty attribute cell sets the attribute and writes a single dot on pixel line 3 (one byte B, the other lines cleared); on a used cell it XORs the dot into line 3 of the scenery.

Then the padding: A' - 4 left over is the new balance; a row cheaper than four glyphs waits 10 DJNZ loops per missing glyph. IX += 32, SP = IX; RowsLeft - 1; RowStart or RenderDone.

c2: 11592 entries (as RowEnd).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 11,862 calls, 3,562,032 t-states own (3.40 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 657,756 calls, 322,107,180 t-states own (6.14 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 53,856 calls, 24,938,496 t-states own (5.96 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 66,816 calls, 32,403,624 t-states own (6.10 %) |
| Called from | `RowEnd` (tail), `StripDraw` |
| Calls | `RenderDone` (tail), `RowStart` |
| Reads | `$4321`-`$43FF` (screen); `$4B00`-`$4BFF` (screen); `$5300`-`$535F` (screen); `$5820`-`$5A5F` (screen); `$7F6F` (`RowsLeft`); `$F12F`-`$F271` (`RowRecords+3`); 7 more ranges |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 12 more ranges |

### `RowStart` (`$86CE`)

**Start a row: beeper toggle, attributes, then the row's span nodes**

Toggles the beeper (RowBeep `$7F7E` XOR `$18`, AND the mask `$7F7F`, OUT `$FE`), 18 times a pass: the row part of the explosion noise. The mask is 0 (no sound) except for the 16 passes after an explosion or a big enemy's hit (SoundPattern1 `$7F80`).

A' = ShiftPage (`$7F6A`). POP DE = the map ring pointer (+0), HL = the attribute address of column 31 (+2), BC = the screen address of the row (+4), IY = the head node (+6); saves SP (the record + 8) in RowStar's operand.

SP = the attribute address + 1, then 16 PUSH DE of map bytes read downwards (DEC L wraps in the ring page): the 32 attributes of the row land in one go. A = C = the screen low byte (column 0), C = `$FF`. SP = IY: RET into the head node.

c2: 11862 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 11,862 calls, 9,033,641 t-states own (8.61 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 657,756 calls, 504,208,413 t-states own (9.62 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 53,856 calls, 41,204,649 t-states own (9.85 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 66,816 calls, 51,158,005 t-states own (9.63 %) |
| Called from | `DrawPlayfield` (tail), `RowStar` |
| Calls | `RowEnd`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1`, `SpanDraw0` |
| Reads | `$7F6A` (`ShiftPage`); `$7F7E`-`$7F7F` (`RowBeep`, `RowBeepMask`); `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`) |
| Writes | `$7F7E` (`RowBeep`); `$867C`-`$867D` (`RowStar+1`) |
| Ports out | `$00FE`, `$18FE` |

### `SpanDraw4` (`$873E`)

**Span node handler: a run of four glyphs**

Entered by RET with SP = node + 2. POP HL: L = the first glyph, H = the gap. A (the column) += gap, DE = the screen address, H = ShiftPage (A'): HL = the glyph's line 0.

Eight lines, the four bytes copied LDI, LDI, LDI, LD/INC on even lines and LDD back on odd lines (zigzag), INC H / INC D a line. Leaves A = the column after the run; POP HL = the next node, SP = it, RET.

The top cost of the game: c2 18726 entries, 123 per mille of all instructions.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 18,726 calls, 12,886,201 t-states own (12.28 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 460,312 calls, 308,016,042 t-states own (5.88 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 51,246 calls, 34,745,132 t-states own (8.31 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 51,246 calls, 34,738,844 t-states own (6.54 %) |
| Called from | `RowStart`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1` |
| Calls | `RowEnd`, `SpanDraw3`, `SpanDraw2`, `SpanDraw1`, `SpanDraw0` |
| Reads | `$C000`-`$DFFE` (`GlyphCache`, `WaveCellSource`, `GlyphCacheUpper`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 9 more ranges |

### `SpanDraw3` (`$8797`)

**Span node handler: a run of three glyphs**

As SpanDraw4 with three bytes a line. c2: 5790 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 5,790 calls, 2,983,964 t-states own (2.84 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 87,051 calls, 46,246,929 t-states own (0.88 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 18,186 calls, 9,440,875 t-states own (2.26 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 18,186 calls, 9,410,270 t-states own (1.77 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw2`, `SpanDraw1` |
| Calls | `RowEnd`, `SpanDraw4`, `SpanDraw2`, `SpanDraw1`, `SpanDraw0` |
| Reads | `$C000`-`$DFFE` (`GlyphCache`, `WaveCellSource`, `GlyphCacheUpper`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 9 more ranges |

### `SpanDraw2` (`$87E0`)

**Span node handler: a run of two glyphs**

As SpanDraw4 with two bytes a line. c2: 2306 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2,306 calls, 927,494 t-states own (0.88 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 89,368 calls, 34,606,194 t-states own (0.66 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 7,244 calls, 2,821,362 t-states own (0.67 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 7,244 calls, 2,815,176 t-states own (0.53 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw3`, `SpanDraw1` |
| Calls | `RowEnd`, `SpanDraw4`, `SpanDraw3`, `SpanDraw1`, `SpanDraw0` |
| Reads | `$C000`-`$DFFE` (`GlyphCache`, `WaveCellSource`, `GlyphCacheUpper`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 9 more ranges |

### `SpanDraw1` (`$8819`)

**Span node handler: one glyph**

As SpanDraw4 with one byte a line (LD A,(HL); LD (DE),A). c2: 5328 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 5,328 calls, 1,290,464 t-states own (1.23 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 110,470 calls, 26,625,232 t-states own (0.51 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 17,832 calls, 4,287,954 t-states own (1.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 17,832 calls, 4,287,051 t-states own (0.81 %) |
| Called from | `RowStart`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2` |
| Calls | `RowEnd`, `SpanDraw4`, `SpanDraw3`, `SpanDraw2`, `SpanDraw0` |
| Reads | `$C000`-`$DFFE` (`GlyphCache`, `WaveCellSource`, `GlyphCacheUpper`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 9 more ranges |

### `SpanDraw0` (`$8842`)

**Span node handler: an empty node**

A node whose last glyph has scrolled out but which still links the row: skips the glyph/gap word and returns into the next node. c2: 522 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 522 calls, 19,044 t-states own (0.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 12,697 calls, 457,344 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1,446 calls, 52,308 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1,447 calls, 52,344 t-states own (0.01 %) |
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
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 3,664 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 40,294 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 3,664 t-states own (0.00 %) |
| Called from | `LevelSetUp` |
| Calls | `Random` |
| Writes | `$8881`-`$8882` (`InitStarsDone+1`) |

### `StarsSwitch` (`$8884`)

**Turn the stars on (A = 1) or off (A = other) and restart them**

LD HL,`$81DA`; DEC A; set (A = 1) or reset PlayFlags bit 7; CALL InitStars. Not entered in c1 or c2: no caller found in the image (a leftover or a cheat entry).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MoveStars` (`$8894`)

**Move every star and respawn the ones that left the screen**

Writes the opcode of the dot-making instruction: XOR `$F8` gives SET n,B (PlayFlags bit 7 set: stars shown), XOR `$B8` gives RES n,B (no dot: the stars stay invisible). Saves SP into MoveStarsDone.

Per row (SP = the star fields): while scrolling (PlayFlags bit 5) the 16-bit position += speed (wrapping); a position below `$1000` respawns the star (new random colour and speed). The pixel bit within the byte comes from the position's low bits (written into StarDot's opcode), the screen byte from its high bits.

Called by the frame handler (c2: 659 entries, 37 per mille).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 659 calls, 3,877,411 t-states own (3.70 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 214,262,766 t-states own (4.09 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 17,480,363 t-states own (4.18 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 21,702,379 t-states own (4.09 %) |
| Called from | `PlayInterrupt` |
| Calls | `Random` |
| Reads | `$81DA` (`PlayFlags`); `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`) |
| Writes | `$88F5`-`$88FA` (`StarDotOpcode+1`, `StarDot`); `$890F`-`$8910` (`MoveStarsDone+1`) |

## scroll

`src/game/scroll.asm`

### `AllocGlyphs` (`$8912`)

**Find C free glyph slots in a row of the glyph bitmap**

Starting from the last position (GlyphAllocMask `$8015` = the slot index, `$8016`/`$8017` = the bitmap byte and the bit mask), scans GlyphBitmap `$FFE0-$FFFF` for a clear bit, wrapping to `$FFE0` and rotating the mask. When the run of C slots would pass slot 255 it restarts at slot 0.

Output: E = the first slot (the glyph index), H/L = its bit mask and bitmap address, D = `$C0`; the allocator state advanced by C.

Called by NewSpanNode (c2: 307 entries).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 307 calls, 58,627 t-states own (0.06 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 5,559 calls, 1,066,067 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 684 calls, 130,898 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 684 calls, 130,806 t-states own (0.02 %) |
| Called from | `NewSpanNode` |
| Reads | `$8015`-`$8017` (`GlyphAlloc`, `GlyphAllocByte`, `GlyphAllocBit`); `$FEFF`-`$FF00` (`VectorTable+255`); `$FFE0`-`$FFFF` (`ColumnFlags`, `work space $FFFF+`) |
| Writes | `$8015`-`$8017` (`GlyphAlloc`, `GlyphAllocByte`, `GlyphAllocBit`) |

### `StartColumn` (`$894D`)

**Set up the column builder for a new column**

Returns at once unless PlayFlags bit 5 (scrolling) is set. Writes the builder's operands: IX = `$F34C` (the record of row 17), HL = ScrollColumn + `$880` (row 17's cell 8 pages on, + `$80`), 18 rows to go.

Called from the frame handler cycle (c2: 229 entries, one per scroll step).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 229 calls, 32,223 t-states own (0.03 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 9,658 calls, 1,183,829 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 748 calls, 77,032 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 976 calls, 107,266 t-states own (0.02 %) |
| Called from | `PlayInterrupt`, `ReplayStep` |
| Reads | `$801C`-`$801D` (`ScrollColumn`); `$81DA` (`PlayFlags`) |
| Writes | `$896F`-`$8975` (`BuildColumn+2`, `BuildColumnCell`, `BuildColumnLeft`) |

### `BuildColumn` (`$896D`)

**Build up to six cells of the new column, bottom row first**

Spreads the 18 rows of a column over three frames: B = 6 rows a call. Per row calls BuildCell, then IX -= 32 (the record above), L += `$80` and H - 1 every second row (two rows a ring page).

The operands keep the state between calls: the record (IX), the map pointer (HL) and the rows left (C). Returns at once with C = 0.

c2: 688 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 688 calls, 582,970 t-states own (0.56 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 28,975 calls, 1,419,437 t-states own (0.03 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,244 calls, 110,762 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,929 calls, 143,478 t-states own (0.03 %) |
| Called from | `ChainBuildColumn1`, `ChainBuildColumn2`, `ChainBuildColumn3`, `ReplayRoundEnd` |
| Calls | `BuildColumnLoop`, `BuildCell` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$896F`-`$8975` (`BuildColumn+2`, `BuildColumnCell`, `BuildColumnLeft`) |

### `BuildColumnLoop` (`$897A`)

**BuildColumnLoop**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 138,858 calls, 4,979,328 t-states own (0.09 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 8,412 calls, 308,198 t-states own (0.07 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 12,048 calls, 438,180 t-states own (0.08 %) |
| Called from | `BuildColumn`, `BuildColumnBack` (tail), `BuildColumnStep` (tail) |
| Calls | `BuildCell` |

### `BuildColumnBack` (`$897E`)

**BuildColumnBack**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 5 calls, 6,720,140 t-states own (0.13 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1 call, 869,766 t-states own (0.21 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 1,241,542 t-states own (0.23 %) |
| Called from | `BuildCellDone`, `GlyphShift2`, `GlyphMarkBits`, `GlyphBuilt` |
| Calls | `BuildColumnLoop` (tail), `BuildColumnStep`, `ChainStep1End` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$896F`-`$8975` (`BuildColumn+2`, `BuildColumnCell`, `BuildColumnLeft`) |

### `BuildColumnStep` (`$8987`)

**BuildColumnStep**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 138,859 calls, 7,575,510 t-states own (0.14 %) |
| Called from | `BuildColumnBack`, `PlayInterruptExit` |
| Calls | `BuildColumnLoop` (tail), `ChainStep1End` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$896F`-`$8975` (`BuildColumn+2`, `BuildColumnCell`, `BuildColumnLeft`) |

### `BuildCell` (`$899E`)

**Turn one map cell of the new column into a glyph**

A = the cell's tile code. 0 (empty): when the row's previous column had a tile (+`$14` bit 7) the gap starts and the following cell's flag byte is set to "no attribute" (bit 7 set, bit 2 clear) when it is empty too; otherwise the empty-column count +`$13` grows (up to 32).

A tile: BuildGlyph. Input: IX = the row record, HL = the map cell. c2: 3948 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 3,948 calls, 302,926 t-states own (0.29 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 138,859 calls, 10,867,098 t-states own (0.21 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 8,412 calls, 663,742 t-states own (0.16 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 12,048 calls, 945,074 t-states own (0.18 %) |
| Called from | `BuildColumn`, `BuildColumnLoop`, `PlayInterruptExit` |
| Calls | `BuildGlyph` (tail) |
| Reads | `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`); `$F12C`-`$F2AC` (`RowRecords`); `$F2BF`-`$F2CC` (`RowRecords+403`); `$F2DF`-`$F2EC` (`RowRecords+435`); `$F2FF`-`$F30C` (`RowRecords+467`); `$F31F`-`$F32C` (`RowRecords+499`); 3 more ranges |
| Writes | `$B702`-`$BFFE` (`Start+3`, `MapRingSpace`, `TileSource`); `$F13F`-`$F2A0` (`RowRecords+19`); `$F2BF`-`$F2C0` (`RowRecords+403`); `$F2DF`-`$F2E0` (`RowRecords+435`); `$F2FF`-`$F300` (`RowRecords+467`); `$F31F`-`$F320` (`RowRecords+499`); 2 more ranges |

### `BuildCellDone` (`$89C4`)

**BuildCellDone**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1 call, 80,403 t-states own (0.00 %) |
| Called from | `GlyphBuilt` |
| Calls | `BuildColumnBack` |
| Reads | `$F140`-`$F280` (`RowRecords+20`); `$F2A0` (`RowRecords+372`); `$F2C0` (`RowRecords+404`); `$F2E0` (`RowRecords+436`); `$F300` (`RowRecords+468`); `$F320` (`RowRecords+500`); 2 more ranges |
| Writes | `$F140`-`$F280` (`RowRecords+20`); `$F2A0` (`RowRecords+372`); `$F2C0` (`RowRecords+404`); `$F2E0` (`RowRecords+436`); `$F300` (`RowRecords+468`); `$F320` (`RowRecords+500`); 2 more ranges |

### `BuildGlyph` (`$89C9`)

**Build one glyph of the new column in all four shifts**

The left neighbour is the row's last glyph (+`$0F`) when the previous column had a tile (+`$14` bit 7), else a blank line of the tile set. Takes a new span node and glyph run when the current run is used up (+`$12`, NewSpanNode).

The cell's flag byte (the map byte at the row pointer + 1): bit 0 = upside down (source + `$700` and DEC D instead of INC D at GlyphLineStep), bit 1 = mirrored (each line through BitReverse `$FB00`: the LD A,(HL) at GlyphMirror, else NOP).

Writes the 8 lines at shift 0 (page `$C0` + line), shift 2 (SET 3,D), shift 4 (SET 4,D) and shift 6 (RES 3,D), each the 16-bit pair left:new shifted left 2, 4, 6 pixels. Sets the slot's bit in GlyphBitmap and +`$14` bit 6 (glyph added: the scroll step widens the tail node).

c2: 1025 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1,025 calls, 2,165,679 t-states own (2.06 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 19,108 calls, 6,524,131 t-states own (0.12 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,254 calls, 781,514 t-states own (0.19 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,254 calls, 781,848 t-states own (0.15 %) |
| Called from | `BuildCell` (tail) |
| Calls | `GlyphLine`, `NewSpanNode` |
| Reads | `$5C00`-`$5DBA` (system); `$5E00`-`$5EBA` (system); `$5F00`-`$5FBA` (system); `$6000`-`$60BA` (system); `$6100`-`$61BA` (`TileCopyTail`); `$6200`-`$62BA` (`TileCopyTail+88`); 11 more ranges |
| Writes | `$8A1D`-`$8A1F` (`GlyphLineStep`, `GlyphMirror`); `$C000`-`$DFFE` (`GlyphCache`, `WaveCellSource`, `GlyphCacheUpper`); `$F13B`-`$F2A0` (`RowRecords+15`); `$F2BB`-`$F2C0` (`RowRecords+399`); `$F2DB`-`$F2E0` (`RowRecords+431`); `$F2FB`-`$F300` (`RowRecords+463`); 4 more ranges |

### `GlyphLine` (`$8A1C`)

**GlyphLine**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 152,864 calls, 7,163,268 t-states own (0.14 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 18,032 calls, 1,466,891 t-states own (0.35 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 18,032 calls, 2,673,844 t-states own (0.50 %) |
| Called from | `BuildGlyph`, `GlyphShift2` (tail), `GlyphShift4` (tail) |
| Calls | `GlyphShift2`, `GlyphShift4` |
| Reads | `$5C00`-`$5EDB` (system); `$5EF8`-`$5FDB` (system); `$5FF8`-`$60DB` (system); `$60F8`-`$61DB` (`TileCopyTail`); `$61F8`-`$62DB` (`TileCopyTail+80`); `$62F8`-`$63DB` (`TileCopyTail+336`); 8 more ranges |
| Writes | `$C000`-`$CFFE` (`GlyphCache`, `WaveCellSource`, `GlyphCacheUpper`); `$D800`-`$DFFE` (`GlyphCacheUpper+4096`) |

### `GlyphShift2` (`$8A25`)

**GlyphShift2**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 152,865 calls, 15,439,416 t-states own (0.29 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 2,514,180 t-states own (0.60 %) |
| Called from | `GlyphLine`, `PlayInterruptExit` |
| Calls | `BuildColumnBack`, `GlyphLine` (tail), `GlyphShift4` |
| Reads | `$F13C`-`$F220` (`RowRecords+16`); `$F29C`-`$F2A0` (`RowRecords+368`); `$F2BC`-`$F2C0` (`RowRecords+400`); `$F2DC`-`$F2E0` (`RowRecords+432`); `$F2FC`-`$F300` (`RowRecords+464`); `$F31C`-`$F320` (`RowRecords+496`); 4 more ranges |
| Writes | `$C800`-`$DFFE` (`GlyphCacheUpper`); `$F13C`-`$F220` (`RowRecords+16`); `$F29D`-`$F2A0` (`RowRecords+369`); `$F2BD`-`$F2C0` (`RowRecords+401`); `$F2DC`-`$F2E0` (`RowRecords+432`); `$F2FC`-`$F300` (`RowRecords+464`); 4 more ranges |

### `GlyphShift4` (`$8A34`)

**GlyphShift4**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 152,865 calls, 9,171,973 t-states own (0.17 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 18,033 calls, 1,081,939 t-states own (0.20 %) |
| Called from | `GlyphLine`, `GlyphShift2`, `PlayInterruptExit` |
| Calls | `GlyphLine` (tail), `GlyphMarkBits` |
| Reads | `$F13C`-`$F29D` (`RowRecords+16`); `$F2BC`-`$F2BD` (`RowRecords+400`); `$F2DC`-`$F2DD` (`RowRecords+432`); `$F2FC`-`$F2FD` (`RowRecords+464`); `$F31C`-`$F31D` (`RowRecords+496`); `$F33C`-`$F33D` (`RowRecords+528`); 2 more ranges |
| Writes | `$D000`-`$D7FE` (`GlyphCacheUpper+2048`) |

### `GlyphMarkBits` (`$8A46`)

**GlyphMarkBits**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 19,109 calls, 1,652,046 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,255 calls, 222,945 t-states own (0.04 %) |
| Called from | `GlyphShift4`, `PlayInterruptExit` |
| Calls | `BuildColumnBack`, `GlyphBuilt` |
| Reads | `$F13C`-`$F2A0` (`RowRecords+16`); `$F2BC`-`$F2C0` (`RowRecords+400`); `$F2DC`-`$F2E0` (`RowRecords+432`); `$F2FC`-`$F300` (`RowRecords+464`); `$F31C`-`$F320` (`RowRecords+496`); `$F33C`-`$F340` (`RowRecords+528`); 2 more ranges |
| Writes | `$F13C`-`$F2A0` (`RowRecords+16`); `$F2BC`-`$F2C0` (`RowRecords+400`); `$F2DC`-`$F2E0` (`RowRecords+432`); `$F2FC`-`$F300` (`RowRecords+464`); `$F31C`-`$F320` (`RowRecords+496`); `$F33C`-`$F340` (`RowRecords+528`); 2 more ranges |

### `GlyphBuilt` (`$8A59`)

**GlyphBuilt**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 19,109 calls, 244,099 t-states own (0.00 %) |
| Called from | `GlyphMarkBits`, `PlayInterruptExit` |
| Calls | `BuildColumnBack`, `BuildCellDone` |

### `NewSpanNode` (`$8A5A`)

**Link a new span node at the row's tail and reserve its glyph run**

Takes a node from the pool (PopNode), links it after the tail (+`$0D`/+`$0E`), sets its gap = the empty-column count (+`$13`), width 0, handler SpanDraw0, counts it (+`$0A`), resets +`$13` to 1. The link store in the previous node is done with interrupts off (DI unless the frame phase `$7F65` is 4).

Measures the run of tiles that follows in the map (up to 4) into +`$12` and reserves as many glyph slots (AllocGlyphs); the first glyph index goes to the node (+2), the slot mask and address to +`$10`/+`$11`.

c2: 307 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 307 calls, 244,420 t-states own (0.23 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 5,559 calls, 4,436,634 t-states own (0.08 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 684 calls, 542,860 t-states own (0.13 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 684 calls, 542,113 t-states own (0.10 %) |
| Called from | `BuildGlyph` |
| Calls | `AllocGlyphs`, `PopNode` |
| Reads | `$7F65` (`PassPhase`); `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`); `$F132`-`$F2FF` (`RowRecords+6`); `$F312`-`$F31F` (`RowRecords+486`); `$F332`-`$F33F` (`RowRecords+518`); `$F352`-`$F35F` (`RowRecords+550`); 2 more ranges |
| Writes | `$F132`-`$F2FF` (`RowRecords+6`); `$F312`-`$F31F` (`RowRecords+486`); `$F332`-`$F33F` (`RowRecords+518`); `$F352`-`$F35F` (`RowRecords+550`); `$F800`-`$FA36` (`NodePool`) |

### `PopNode` (`$8AD0`)

**Take a span node from the free list**

Output: DE = the node, NodeFreeList (`$7F68`) = the node's link. HL preserved. c2: 307 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 307 calls, 34,044 t-states own (0.03 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 5,559 calls, 618,050 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 684 calls, 76,128 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 684 calls, 76,265 t-states own (0.01 %) |
| Called from | `NewSpanNode` |
| Reads | `$7F68`-`$7F69` (`NodeFreeList`); `$F800`-`$FA31` (`NodePool`) |
| Writes | `$7F68`-`$7F69` (`NodeFreeList`) |

### `PushNode` (`$8ADF`)

**Return the span node HL to the free list**

The node's first word = the old NodeFreeList, NodeFreeList = HL. DE preserved. c2: 230 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 230 calls, 21,578 t-states own (0.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 5,193 calls, 483,204 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 695 calls, 64,645 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 695 calls, 64,645 t-states own (0.01 %) |
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

Called from the frame handler cycle (c2: 228 entries).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 228 calls, 1,871,733 t-states own (1.78 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 9,647 calls, 62,617,919 t-states own (1.19 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 748 calls, 4,185,653 t-states own (1.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 975 calls, 5,685,917 t-states own (1.07 %) |
| Called from | `PlayInterrupt`, `ReplayRoundEnd` |
| Calls | `PushNode`, `SetSpanHandler` |
| Reads | `$7F70` (`EmptyRows`); `$801C`-`$8022` (`ScrollColumn`, `ScriptColumn`, `ScriptRoom`, `ScriptBusy` and 2 more); `$81DA`-`$81DC` (`PlayFlags`, `ScrollCount`); `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`); `$F12C`-`$F360` (`RowRecords`); `$F802`-`$FA36` (`NodePool+2`); 2 more ranges |
| Writes | `$7F70` (`EmptyRows`); `$801C`-`$8022` (`ScrollColumn`, `ScriptColumn`, `ScriptRoom`, `ScriptBusy` and 2 more); `$81DB`-`$81DC` (`ScrollCount`); `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`); `$F12C`-`$F360` (`RowRecords`); `$F802`-`$FA36` (`NodePool+2`); 1 more ranges |

### `SetSpanHandler` (`$8C1C`)

**Point the node IY at the handler for its width**

Handler = SpanHandlers[(IY+6)] into the node's first word. c2: 1559 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1,559 calls, 192,424 t-states own (0.18 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 31,867 calls, 3,921,354 t-states own (0.07 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 3,860 calls, 474,791 t-states own (0.11 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,860 calls, 474,786 t-states own (0.09 %) |
| Called from | `ScrollStep` |
| Reads | `$8C33`-`$8C3A` (`SpanHandlers+2`); `$F806`-`$FA36` (`NodePool+6`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$F800`-`$FA31` (`NodePool`) |

## levels

`src/game/levels.asm`

### `LevelSetUp` (`$8C3B`)

**Reset the playfield model at the start of a level or life**

Chains the 95 nodes of the pool `$F800` (the free list in `$7F68`, `$FAF8` = `$FFFF` the end), clears the 576 bytes of RowRecords (`$F12C-$F36B`) and fills each of the 18 records: +0/+1 the map pointer (`$B71F`, `$B79F`, `$B81F`, ... two rows a page), +2/+3 the attribute address of column 31 (`$583F` + 32 row), +4/+5 the screen address (`$4020` ...), +6/+7 the head SentinelNode, +`$0D`/+`$0E` the tail = record + 2, +`$13` = 32 empty columns, +`$12` = 1.

Clears the map ring `$B700-$BFFF`, ScrollColumn = `$B760`, `$8022` = `$B730`, GlyphBitmap `$FFE0-$FFFF` = 0; builds BitReverse (`$FB00`: each byte with its bits reversed).

Sets the six fields `$8075` + 3k to `$FF`, `$8072-$8074` = 5, 6, 3, clears `$8087`, `$8024`, `$8025`, `$80BD`, `$80BE` and the six bytes `$7EFF` + 16k; then, with interrupts off, calls `$91C6` and InitStars.

Called from the level start `$AF49` (c2: 1 entry).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 130,873 t-states own (0.12 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 1,439,982 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 130,873 t-states own (0.02 %) |
| Called from | `LevelStart` |
| Calls | `InitStars`, `ClearHitGrid` |
| Reads | `$B700`-`$BFFE` (`Start+1`, `MapRingSpace`, `TileSource`); `$F12C`-`$F36A` (`RowRecords`); `$FEFF`-`$FF00` (`VectorTable+255`); `$FFE0`-`$FFFE` (`ColumnFlags`) |
| Writes | `$7EFF`-`$7F4F` (`SpriteCacheUse1`, `SpriteCacheRecord2`, `SpriteCacheRecord3`, `SpriteCacheRecord4` and 2 more); `$7F68`-`$7F69` (`NodeFreeList`); `$801C`-`$8025` (`ScrollColumn`, `ScriptColumn`, `ScriptRoom`, `ScriptBusy` and 4 more); `$8072`-`$8087` (`FreeEnemySlots`, `WavesAllowed`, `EnemyShotsLeft`, `WaveRecords` and 1 more); `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`); 3 more ranges |

## scenery

`src/game/scenery.asm`

### `StartScript` (`$8D35`)

**Set up the scenery coroutine for a level**

Script stack top `$FDFB` holds the entry ScriptMain, ScriptSP (`$801A`) = `$FDFB`, ScriptBusy (`$8020`) = 0; falls into ResumeScript. Called from the level start `$AF49` (c2: 1 entry).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 69 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 759 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 69 t-states own (0.00 %) |
| Called from | `LevelStart` |
| Calls | `ResumeScript` |
| Writes | `$801A`-`$8020` (`ScriptSP`, `ScrollColumn`, `ScriptColumn`, `ScriptRoom` and 1 more); `$FDFB`-`$FDFC` (`ScriptStackTop`) |

### `ResumeScript` (`$8D45`)

**Run the scenery script when 16 more columns have scrolled**

When ScriptBusy is 0: returns unless ScriptRoom >= 16; then ScriptRoom - 16, ScriptColumn + 16, ScriptBusy = `$FF`. Saves the main SP (`$8018`), switches to ScriptSP and RETs into the script; it returns here through YieldScript.

Called from the frame handler cycle `$AA96` (c2: 524 entries) and from the catch-up loop `$AF90`/`$AF96`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 524 calls, 35,639 t-states own (0.03 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 19,842 calls, 1,298,532 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1,495 calls, 97,644 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,000 calls, 129,958 t-states own (0.02 %) |
| Called from | `StartScript`, `PlayPass`, `ReplayRound` |
| Calls | `ScriptMain` |
| Reads | `$801A`-`$8020` (`ScriptSP`, `ScrollColumn`, `ScriptColumn`, `ScriptRoom` and 1 more); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$8018`-`$8020` (`MainSP`, `ScriptSP`, `ScrollColumn`, `ScriptColumn` and 2 more) |

### `YieldScript` (`$8D69`)

**Switch from the script back to the main stack**

ScriptSP = SP, SP = the main SP: the RET returns to ResumeScript's caller. c2: 90 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 90 calls, 4,889 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,557 calls, 84,437 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 176 calls, 9,611 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 189 calls, 10,159 t-states own (0.00 %) |
| Called from | `ScriptStep`, `DrawGroup` |
| Calls | `PlayChain`, `ReplayScroll`, `ReplayRoundEnd` |
| Reads | `$8018`-`$8019` (`MainSP`) |
| Writes | `$801A`-`$801B` (`ScriptSP`) |

### `ScriptMain` (`$8D72`)

**The coroutine's body: run the level's script for ever**

A = ScriptNumber (`$81DD`), RunScript, again. Its first RET came from StartScript; c2 shows no entry because the loop never ends during a level (1 dispatch at the start).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 30 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 78 calls, 2,670 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 6 calls, 210 t-states own (0.00 %) |
| Called from | `ResumeScript`, `ScriptMainAgain` (tail) |
| Calls | `RunScript` |
| Reads | `$81DD` (`ScriptNumber`) |

### `ScriptMainAgain` (`$8D78`)

**ScriptMainAgain**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 936 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 72 t-states own (0.00 %) |
| Called from | `ScriptStep` |
| Calls | `ScriptMain` (tail) |

### `RunScript` (`$8D7A`)

**Run the script A**

HL = the script's address from the word table `$72E1`, then ScriptStep. c2: 4 entries (the main script and its sub-scripts).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 4 calls, 249 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 127 calls, 7,988 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 3 calls, 192 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 10 calls, 639 t-states own (0.00 %) |
| Called from | `ScriptMain`, `ScriptStep` |
| Calls | `ScriptStep` |
| Reads | `$72E3`-`$732E` (`SceneryScriptTable+2`) |

### `ScriptStep` (`$8D86`)

**Interpret the script bytes at HL**

Below `$80`: DrawGroup n, ScriptBusy = 0, YieldScript, go on. `$FF`: return. `$80` n: call script n (ScriptVariant saved and restored, ScriptReturn). `$A0-$AF`: ScriptVariant = the low nibble moved to the high nibble. Other `$81-$9F`: ScriptSetCell (the pattern n AND 7).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 6 calls, 2,392 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 160 calls, 68,851 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 37 calls, 3,916 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 14 calls, 5,637 t-states own (0.00 %) |
| Called from | `RunScript`, `ScriptReturn` (tail) |
| Calls | `YieldScript`, `ScriptMainAgain`, `RunScript`, `DrawGroup`, `ScriptSetCell` |
| Reads | `$732F`-`$73DB` (`SceneryScripts`); `$7401`-`$7499` (`SceneryScripts+210`); `$8020`-`$8021` (`ScriptBusy`, `ScriptVariant`) |
| Writes | `$8020`-`$8021` (`ScriptBusy`, `ScriptVariant`) |

### `ScriptReturn` (`$8DC3`)

**ScriptReturn**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 90 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,485 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 180 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 180 t-states own (0.00 %) |
| Calls | `ScriptStep` (tail) |
| Writes | `$8021` (`ScriptVariant`) |

### `DrawGroup` (`$8DCA`)

**Place the object group A into the map ring**

Returns at once when SkipDraw (`$7F76`) bit 0 is set (the catch-up after a life lost runs the scripts without drawing).

The group (word table `$749A`) is a list: a byte with bit 7 set and not `$FF` = a sub-group (the next byte) taken only when its bit 6 AND ScriptVariant is non-zero (recursion); `$FF` = end; otherwise an object of 3 bytes: the first byte (bits 0-4 the row, bits 5-7 the flags: bit 0 = flipped, bit 1 = mirrored), a variant/column byte (low nibble the column; ANDed with ScriptVariant), the shape number (the word table `$7783`).

For each object the shape's cells are written column by column (PlaceColumn), with the direction of the row and column steps written into `$8E94`, `$8EBF` and `$8EC0` for the flip and mirror, then YieldScript after every column, so the placement spreads over the frames.

c2: 15 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 15 calls, 66,220 t-states own (0.06 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 488 calls, 1,016,316 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 29 calls, 126,377 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 42 calls, 128,181 t-states own (0.02 %) |
| Called from | `ScriptStep` |
| Calls | `YieldScript`, `PlaceColumn` |
| Reads | `$749A`-`$799B` (`GroupTable`, `ObjectGroups`, `ShapeTable`, `Shapes`); `$79CA`-`$7AC7` (`Shapes+425`); `$7AF2`-`$7B16` (`Shapes+721`); `$7B41`-`$7BA3` (`Shapes+800`); `$7BD9`-`$7C31` (`Shapes+952`); `$7C5E`-`$7DB5` (`Shapes+1085`); 5 more ranges |
| Writes | `$8E94` (`ObjectRowStep`); `$8EAD` (`PlaceFlags+1`); `$8EBF`-`$8EC0` (`PlaceStepE`, `PlaceStepC`) |

### `PlaceColumn` (`$8EA1`)

**Write one shape column into the map ring**

The column's header byte: bit 0 set = an attribute follows from the table at H = `$FF` (OR with the flags at PlaceFlags, stored into PlaceAttr). Then per cell a bit of the mask byte: set = the tile code goes to (DE) and the attribute to (BC); E and C step by PlaceStepE/PlaceStepC (INC or DEC, written by DrawGroup). A 0 bit ends the column.

c2: 209 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 209 calls, 111,149 t-states own (0.11 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 3,394 calls, 1,749,260 t-states own (0.03 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 374 calls, 190,935 t-states own (0.05 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 374 calls, 190,958 t-states own (0.04 %) |
| Called from | `DrawGroup` |
| Reads | `$7822`-`$78A6` (`Shapes+1`); `$78BE`-`$7DD9` (`Shapes+157`); `$7DFD`-`$7E33` (`Shapes+1500`); `$7E4A`-`$7E59` (`Shapes+1577`); `$FEFF`-`$FF00` (`VectorTable+255`); `$FFD8`-`$FFDE` (`WorkGlyph`) |
| Writes | `$8EBB` (`PlaceAttr+1`); `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`); `$FDE9`-`$FDEA` (`ScriptStack+89`) |

### `ScriptSetCell` (`$8EC5`)

**Copy the 8-byte cell pattern A to WorkCell**

HL = `$72A9` + 8A, 8 bytes to `$FFD8`. c2: 1 entry.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 257 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 17 calls, 4,440 t-states own (0.00 %) |
| Called from | `ScriptStep` |
| Reads | `$72A9`-`$72E0` (`CellPatterns`) |
| Writes | `$FFD8`-`$FFDF` (`WorkGlyph`) |

## sprites

`src/game/sprites.asm`

### `BuildCellSprite` (`$8EDB`)

**Build a column-major sprite of C columns of B cells, complemented, with blank borders**

DE - 8 gets a blank (FillBlankCell), then per column B cells of 8 bytes copied from HL complemented (CPL), and a blank cell after every column; then B blank cells at the end.

Input: HL = the source glyphs, DE = the destination, B = the cells a column, C = the columns. c2: 5 entries (frames 102-1274, from `$ACD9`), writing `$E748-$E757` and `$E760-$E76F` from `$64E0-$64FF` and `$65E0-$65FF`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 5 calls, 9,281 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 338 calls, 630,863 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 26 calls, 49,004 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 30 calls, 56,579 t-states own (0.01 %) |
| Called from | `LoadCellSprite` |
| Calls | `FillBlankCell` |
| Reads | `$6400`-`$653F` (`TileCopyTail+600`); `$6560`-`$65BF` (`TileCopyTail+952`); `$65E0`-`$65FF` (`TileCopyTail+1080`); `$6620`-`$66DF` (`TileCopyTail+1144`) |
| Writes | `$E748`-`$E787` (`SpriteCacheImages`); `$E988`-`$E9AF` (`SpriteCacheImages+576`); `$EBC8`-`$EC07` (`SpriteCacheImages+1152`); `$EE08`-`$EE2F` (`SpriteCacheImages+1728`) |

### `FillBlankCell` (`$8EFF`)

**Write a blank cell: eight `$FF` bytes at DE**

A and BC preserved. c2: 30 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 30 calls, 7,939 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,201 calls, 588,956 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 157 calls, 41,754 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 181 calls, 48,431 t-states own (0.01 %) |
| Called from | `BuildCellSprite`, `BuildBigSprite` |
| Writes | `$C000`-`$C0B7` (`GlyphCache`); `$C0E0`-`$C0E7` (`GlyphCache+224`); `$C118`-`$C11F` (`GlyphCache+280`); `$C150`-`$C1FF` (`GlyphCache+336`); `$E740`-`$E7A7` (`BallSprite+248`, `SpriteCacheImages`); `$E980`-`$E9CF` (`SpriteCacheImages+568`); 2 more ranges |

### `BuildBigSprite` (`$8F0C`)

**Build a 7 x 9 cell image at `$C000` from a one-bit cell map**

A = 1: the glyphs come from `$66E0` (linear, INC HL) and the cell map from the 9 bytes at `$8098`; otherwise from the tile set at `$5CDC` (interleaved: INC H, then LD H,C; INC L after each glyph) and the map at `$80A1`. The step instructions are written into BigSpriteStep and BigSpriteNext. Not run in c1/c2; r1 runs it 6 times (frames 16855-66273), from LoadCellSprite `$ACD9` for the big enemies (kinds `$14` and up).

Each map bit (7 a byte, 9 bytes) set = the next glyph complemented (BigSpriteCell), clear = a blank cell. Called from `$ACD9` when its A >= `$14`. Not entered in c1 or c2: probably the end-of-level guardian.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 6 calls, 23,039 t-states own (0.00 %) |
| Called from | `LoadCellSprite` |
| Calls | `FillBlankCell`, `BigSpriteCell` |
| Reads | `$8098`-`$80A9` (`BigSpriteMap1`, `BigSpriteMap2`) |
| Writes | `$8F52`-`$8F57` (`BigSpriteStep`, `BigSpriteNext`) |

### `BigSpriteCell` (`$8F4B`)

**Copy one glyph complemented to DE**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 216 calls, 83,525 t-states own (0.00 %) |
| Called from | `BuildBigSprite` |
| Reads | `$5CDC`-`$5DFF` (system); `$5EDC`-`$5EFF` (system); `$5FDC`-`$5FFF` (system); `$60DC`-`$60FF` (system); `$61DC`-`$61FF` (`TileCopyTail+52`); `$62DC`-`$62FF` (`TileCopyTail+308`); 2 more ranges |
| Writes | `$C018`-`$C037` (`GlyphCache+24`); `$C048`-`$C06F` (`GlyphCache+72`); `$C080`-`$C0A7` (`GlyphCache+128`); `$C0B8`-`$C17F` (`GlyphCache+184`); `$C190`-`$C1B7` (`GlyphCache+400`) |

### `RotateSprite` (`$8F5A`)

**Rotate a column-major image one pixel right, the last bit wrapping to the first byte**

Input: HL = the image, C = its height in lines (also the column stride), B = its width in bytes. Each line is shifted right one pixel across its B bytes; the bit that falls out of the last byte goes into bit 7 of the first.

Called from `$AD44` (c2: 35 entries).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 35 calls, 385 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,408 calls, 9,651 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 182 calls, 2,002 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 210 calls, 2,310 t-states own (0.00 %) |
| Called from | `SpriteShiftCopy` |
| Calls | `RotateSpriteRows`, `RotateLine` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `RotateSpriteRows` (`$8F5B`)

**RotateSpriteRows**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,409 calls, 16,856 t-states own (0.00 %) |
| Called from | `RotateSprite`, `PlayInterruptExit` |
| Calls | `RotateLine` |

### `RotateLine` (`$8F5D`)

**RotateLine**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 840 calls, 22,753 t-states own (0.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,140 calls, 687,177 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 4,368 calls, 117,663 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 5,040 calls, 135,541 t-states own (0.03 %) |
| Called from | `RotateSprite`, `RotateSpriteRows`, `RotateNextByte` (tail), `RotateLineNext` (tail), `RotateLineCount` (tail), `PlayInterruptExit` |
| Calls | `RotateLineSave`, `RotateByte` |

### `RotateLineSave` (`$8F5E`)

**RotateLineSave**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,139 calls, 678,894 t-states own (0.01 %) |
| Called from | `RotateLine`, `PlayInterruptExit` |
| Calls | `RotateLineCarry` |

### `RotateLineCarry` (`$8F5F`)

**RotateLineCarry**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,137 calls, 236,582 t-states own (0.00 %) |
| Called from | `RotateLineSave`, `PlayInterruptExit` |
| Calls | `RotateByte` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `RotateByte` (`$8F60`)

**RotateByte**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2,520 calls, 85,718 t-states own (0.08 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 192,411 calls, 769,554 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 13,277 calls, 53,126 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 15,291 calls, 61,209 t-states own (0.01 %) |
| Called from | `RotateLine`, `RotateLineCarry`, `RotateNextByte` (tail), `PlayInterruptExit` |
| Calls | `RotateByteShift`, `RotateNextByte` |
| Reads | `$E790`-`$E987` (`SpriteCacheImages+72`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$E790`-`$E987` (`SpriteCacheImages+72`) |

### `RotateByteShift` (`$8F61`)

**RotateByteShift**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 192,366 calls, 2,886,008 t-states own (0.06 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 13,274 calls, 398,464 t-states own (0.10 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 15,291 calls, 229,377 t-states own (0.04 %) |
| Called from | `RotateByte`, `PlayInterruptExit` |
| Calls | `RotateByteOut`, `RotateNextByte` |
| Reads | `$C200`-`$CFC7` (`GlyphCache+512`, `WaveCellSource`, `GlyphCacheUpper`); `$E790`-`$EBC7` (`SpriteCacheImages+72`); `$EC10`-`$F047` (`SpriteCacheImages+1224`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$C200`-`$CFC7` (`GlyphCache+512`, `WaveCellSource`, `GlyphCacheUpper`); `$E790`-`$EBC7` (`SpriteCacheImages+72`); `$EC10`-`$F047` (`SpriteCacheImages+1224`) |

### `RotateByteOut` (`$8F63`)

**RotateByteOut**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 192,392 calls, 2,890,036 t-states own (0.06 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 15,291 calls, 229,719 t-states own (0.04 %) |
| Called from | `RotateByteShift`, `PlayInterruptExit` |
| Calls | `RotateNextByte` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `RotateNextByte` (`$8F65`)

**RotateNextByte**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2,522 calls, 79,981 t-states own (0.08 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 192,604 calls, 2,205,969 t-states own (0.04 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 13,288 calls, 150,810 t-states own (0.04 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 15,309 calls, 173,620 t-states own (0.03 %) |
| Called from | `RotateByte`, `RotateByteShift`, `RotateByteOut`, `PlayInterruptExit` |
| Calls | `RotateLine` (tail), `RotateByte` (tail), `RotateLineWrap`, `SpriteShiftNext` |
| Reads | `$E790`-`$E7A7` (`SpriteCacheImages+72`); `$E7D8`-`$E7EF` (`SpriteCacheImages+144`); `$E820`-`$E837` (`SpriteCacheImages+216`); `$E868`-`$E87F` (`SpriteCacheImages+288`); `$E8B0`-`$E8C7` (`SpriteCacheImages+360`); `$E8F8`-`$E90F` (`SpriteCacheImages+432`); 2 more ranges |
| Writes | `$E790`-`$E7A7` (`SpriteCacheImages+72`); `$E7D8`-`$E7EF` (`SpriteCacheImages+144`); `$E820`-`$E837` (`SpriteCacheImages+216`); `$E868`-`$E87F` (`SpriteCacheImages+288`); `$E8B0`-`$E8C7` (`SpriteCacheImages+360`); `$E8F8`-`$E90F` (`SpriteCacheImages+432`); 1 more ranges |

### `RotateLineWrap` (`$8F67`)

**RotateLineWrap**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,138 calls, 804,476 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 4,369 calls, 57,334 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 5,041 calls, 244,693 t-states own (0.05 %) |
| Called from | `RotateNextByte`, `PlayInterruptExit` |
| Calls | `RotateLineMerge`, `RotateLineCount` |
| Reads | `$E790`-`$E99F` (`SpriteCacheImages+72`); `$E9D0`-`$E9FF` (`SpriteCacheImages+648`); `$EA18`-`$EA2F` (`SpriteCacheImages+720`); `$EA60`-`$EA77` (`SpriteCacheImages+792`); `$EAA8`-`$EABF` (`SpriteCacheImages+864`); `$EAF0`-`$EB07` (`SpriteCacheImages+936`); 3 more ranges |
| Writes | `$E790`-`$E99F` (`SpriteCacheImages+72`); `$E9D0`-`$E9FF` (`SpriteCacheImages+648`); `$EA18`-`$EA2F` (`SpriteCacheImages+720`); `$EA60`-`$EA77` (`SpriteCacheImages+792`); `$EAA8`-`$EABF` (`SpriteCacheImages+864`); `$EAF0`-`$EB07` (`SpriteCacheImages+936`); 2 more ranges |

### `RotateLineMerge` (`$8F68`)

**RotateLineMerge**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,140 calls, 414,009 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 4,370 calls, 61,171 t-states own (0.01 %) |
| Called from | `RotateLineWrap`, `PlayInterruptExit` |
| Calls | `RotateLineStore`, `RotateLineNext` |
| Reads | `$C200`-`$C42F` (`GlyphCache+512`, `WaveCellSource`); `$C5F0`-`$C627` (`WaveCellSource+496`); `$C7E8`-`$C81F` (`WaveCellSource+1000`, `GlyphCacheUpper`); `$C9E0`-`$CA17` (`GlyphCacheUpper+480`); `$CBD8`-`$CC0F` (`GlyphCacheUpper+984`); `$CDD0`-`$CE07` (`GlyphCacheUpper+1488`); 2 more ranges |
| Writes | `$E790`-`$E99F` (`SpriteCacheImages+72`); `$E9D0`-`$EA2F` (`SpriteCacheImages+648`); `$EA60`-`$EA77` (`SpriteCacheImages+792`); `$EAA8`-`$EABF` (`SpriteCacheImages+864`); `$EAF0`-`$EB07` (`SpriteCacheImages+936`); `$EB38`-`$EB4F` (`SpriteCacheImages+1008`); 1 more ranges |

### `RotateLineStore` (`$8F69`)

**RotateLineStore**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,139 calls, 413,990 t-states own (0.01 %) |
| Called from | `RotateLineMerge`, `PlayInterruptExit` |
| Calls | `RotateLineNext` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$C200`-`$C42F` (`GlyphCache+512`, `WaveCellSource`); `$C5F0`-`$C627` (`WaveCellSource+496`); `$C7E8`-`$C81F` (`WaveCellSource+1000`, `GlyphCacheUpper`); `$C9E0`-`$CA17` (`GlyphCacheUpper+480`); `$CBD8`-`$CC0F` (`GlyphCacheUpper+984`); `$CDD0`-`$CE07` (`GlyphCacheUpper+1488`); 1 more ranges |

### `RotateLineNext` (`$8F6A`)

**RotateLineNext**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,138 calls, 354,873 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 4,369 calls, 146,834 t-states own (0.04 %) |
| Called from | `RotateLineMerge`, `RotateLineStore`, `PlayInterruptExit` |
| Calls | `RotateLine` (tail), `RotateLineRestore`, `SpriteShiftNext` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `RotateLineRestore` (`$8F6B`)

**RotateLineRestore**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,139 calls, 686,844 t-states own (0.01 %) |
| Called from | `RotateLineNext`, `PlayInterruptExit` |
| Calls | `RotateLineCount` |

### `RotateLineCount` (`$8F6C`)

**RotateLineCount**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 59,137 calls, 958,947 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 61,625 t-states own (0.01 %) |
| Called from | `RotateLineWrap`, `RotateLineRestore`, `PlayInterruptExit` |
| Calls | `RotateLine` (tail), `SpriteShiftNext` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `ClearStripCounts` (`$8F70`)

**Clear the sprite-strip count of the 18 row records**

0 into +`$15` of every record (`$F141` + 32k). c2: 660 entries (from ObjectStrips).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 660 calls, 231,598 t-states own (0.22 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,543 calls, 12,755,783 t-states own (0.24 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 1,046,463 t-states own (0.25 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,713 calls, 1,297,193 t-states own (0.24 %) |
| Called from | `ObjectStrips` |
| Writes | `$F141` (`RowRecords+21`); `$F161` (`RowRecords+53`); `$F181` (`RowRecords+85`); `$F1A1` (`RowRecords+117`); `$F1C1` (`RowRecords+149`); `$F1E1` (`RowRecords+181`); 12 more ranges |

### `ObjectStrips` (`$8F9B`)

**Cut every active object into sprite strips**

ClearStripCounts, then the 16 objects from IY = `$F600` down by 44 bytes: an active object (+8 bit 7) goes through BuildObjectStrips. One beeper toggle per object (ObjectBeep `$7F82` XOR `$18`, AND the mask `$7F83`): the strip part of the explosion noise, silent while the mask is 0.

Called from the frame handler cycle `$AA96` (c2: 660 entries).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 660 calls, 1,571,099 t-states own (1.50 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,543 calls, 85,014,184 t-states own (1.62 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 7,060,699 t-states own (1.69 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,713 calls, 8,643,955 t-states own (1.63 %) |
| Called from | `PlayPass` |
| Calls | `ClearStripCounts`, `BuildObjectStrips` |
| Reads | `$7F82`-`$7F83` (`ObjectBeep`, `ObjectBeepMask`); `$F374`-`$F4D4` (`PlayerObject+8`, `EnemyObjects`, `EnemyShots`); `$F500` (`LaserShots+8`); `$F52C` (`LaserShots+52`); `$F558` (`LaserShots+96`); `$F584` (`LaserShots+140`); 3 more ranges |
| Writes | `$7F82` (`ObjectBeep`) |
| Ports out | `$00FE`, `$18FE` |

### `BuildObjectStrips` (`$8FC2`)

**Link the strips of the object IY into the row records**

The object's sprite definition (+0/+1) is a list of words read with POP: the base image, the frame stride (times the frame +2), a stride and mask for the sub-frame (+3 bits 5-7), the height and the line length. The rows are clipped against the playfield (+4 - 16, 32 rows); an object fully out has +8 bit 5 cleared (BuildStripsOff), else it is set (visible).

The column (+5 bits 5-7) moves the start; +6 gives the shift; +`$25` the colour. The strip entries go onto the object's strip buffer (+9/+10, as a stack); +`$0B` is a bit mask of the rows the object covers: each set bit adds a strip to that row's list (+`$15` count + 1, +`$16`/+`$17` linked).

Saves SP into BuildStripsDone. c2: 3327 entries, 46 per mille.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 3,327 calls, 4,845,376 t-states own (4.62 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 198,736 calls, 309,524,067 t-states own (5.90 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 18,019 calls, 25,226,711 t-states own (6.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 20,984 calls, 31,272,884 t-states own (5.89 %) |
| Called from | `ObjectStrips` |
| Reads | `$90A5`-`$90A6` (`BuildStripsDone+1`); `$F141`-`$F2A3` (`RowRecords+21`); `$F2C1`-`$F2C3` (`RowRecords+405`); `$F2E1`-`$F2E3` (`RowRecords+437`); `$F301`-`$F303` (`RowRecords+469`); `$F321`-`$F323` (`RowRecords+501`); 10 more ranges |
| Writes | `$9093`-`$9094` (`StripListHead+2`); `$90A5`-`$90A6` (`BuildStripsDone+1`); `$F141`-`$F2A3` (`RowRecords+21`); `$F2C1`-`$F2C3` (`RowRecords+405`); `$F2E1`-`$F2E3` (`RowRecords+437`); `$F301`-`$F303` (`RowRecords+469`); 11 more ranges |

## objgrid

`src/game/objgrid.asm`

### `FindFreeObjectSlot` (`$90B5`)

**find a free record among the 16 from `$F36C` (unused)**

IY = the first of the 16 records of 44 bytes from `$F36C` whose +`$08` bit 7 (active) is clear, NC; carry when all 16 are in use. Nothing in the image calls or jumps here and no recording ran it (0 executions in c1, c2): a left-over; the wave launcher uses TakeEnemySlot (`$938D`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MarkEnemyGrid` (`$90CB`)

**mark the 8 enemy slots' collision bits in the grid**

Called from PlayPass `$AA96` in the odd phases (1 and 3), every other pass (331 entries in c2's 659 passes). C = the collision bit, 1 for the slot `$F398` and rotated left for each next slot, so slot n owns bit n. For each active and visible slot (+`$08` bits 7 and 5): its sprite descriptor (+0/+1, IX) gives the width +`$0B` and the height +`$08`; the X position (+3/+4, in 1/4 columns) picks the first of the X bytes at `$FC00`, every 4th byte over the width plus the last gets the bit; the Y position (+5/+6, in 1/8 rows) picks the Y byte at `$FD00`, every 8th byte over the height gets the bit, the rows whose bit in the row mask +`$0B` is clear excepted (a big enemy's rows out of play).

Reads the records with SP (POP IX, POP HL); SP is kept in the operand at `$9144`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 331 calls, 599,463 t-states own (0.57 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 18,277 calls, 41,740,213 t-states own (0.80 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1,496 calls, 2,698,499 t-states own (0.65 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1,857 calls, 3,458,768 t-states own (0.65 %) |
| Called from | `PlayPass` |
| Reads | `$7EA9`-`$7EAC` (`ExplosionAnim+8`); `$7EC3`-`$7EC6` (`PodAnim+8`); `$7EDD`-`$7F4D` (`ShotDescriptor+8`, `SpriteCache`); `$F3A0`-`$F3A3` (`EnemyObjects+8`); `$F3CC`-`$F3CF` (`EnemyObjects+52`); `$F3F8`-`$F3FB` (`EnemyObjects+96`); 7 more ranges |
| Writes | `$9144`-`$9145` (`MarkGridRestoreSp+1`); `$FC34`-`$FCDE` (`MenuColours+20`); `$FD00`-`$FD96` (`HitGridY`, `ScriptStack`) |

### `TestHitGrid` (`$9150`)

**the overlap masks of the player, the shots and the weapons**

Called from `$A9ED` in phases 2-4 (494 entries in c2's 659 passes, 2 % of play's time). For the 8 records from `$F36C` (the player, then `$F4F8` = `$F36C` + `$018C` and every 44 bytes on: the four laser shots, the plasma/missile slots `$F5A8` and `$F5D4`, the sight `$F600`): OR of the X bytes over the width (the player's width less one) and OR of the Y bytes over the height (4 bytes an eighth of a row step, read with POP); the AND of both is the set of enemy bits this record touches, stored in +`$0D`. The union for the first five records (the player and the lasers), active ones only, goes into `$80BB`, the laser-hit mask the enemy handlers test. SP is kept in the operand at `$91C3`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 494 calls, 2,115,709 t-states own (2.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 27,404 calls, 117,375,966 t-states own (2.24 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,244 calls, 9,609,447 t-states own (2.30 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,784 calls, 11,923,962 t-states own (2.24 %) |
| Called from | `PlayInterrupt` |
| Reads | `$7E9C`-`$7E9F` (`ShipDescriptor+8`); `$7EB6`-`$7EB9` (`SightDescriptor+8`); `$7ED0`-`$7EE0` (`LaserDescriptor+8`, `ShotDescriptor`); `$F373`-`$F374` (`PlayerObject+7`); `$F4FF`-`$F500` (`LaserShots+7`); `$F52B`-`$F52C` (`LaserShots+51`); 5 more ranges |
| Writes | `$80BB` (`LaserHitMask`); `$91C3`-`$91C4` (`TestGridRestoreSp+1`); `$F379` (`PlayerHitMask`); `$F505` (`LaserShots+13`); `$F531` (`LaserShots+57`); `$F55D` (`LaserShots+101`); 4 more ranges |

### `ClearHitGrid` (`$91C6`)

**clear the collision grid `$FC00-$FD8F`**

Pushes 200 zero words down from `$FD90` (20 x 10 PUSH HL): the X bytes `$FC00-$FCFF` and the Y bytes `$FD00-$FD8F`. Called from `$8C3B`, `$A9ED` and `$B03A` (496 entries in c2). SP is kept in the operand at `$91DF`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 496 calls, 1,250,924 t-states own (1.19 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 27,426 calls, 69,168,495 t-states own (1.32 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,244 calls, 5,659,368 t-states own (1.35 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,786 calls, 7,026,304 t-states own (1.32 %) |
| Called from | `LevelSetUp`, `PlayInterrupt`, `RoundPlaySetup` |
| Writes | `$91DF`-`$91E0` (`ClearGridRestoreSp+1`) |

### `JumpTable` (`$91E2`)

**jump to the word number A of the table at HL**

HL = the word at HL + 2A, JP (HL); DE is spoilt. The routine reached returns to JumpTable's caller. Used by the object loop (`$80FA`), the path interpreter (`$8114`, `$8124`), the player's side weapon (`$80EA`), the pod (`$80F0`) and the routines at `$AC0E`, `$AD66`, `$ADF4`, `$B0FF` and `$B21C`. 6080 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 6,080 calls, 328,320 t-states own (0.31 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 392,407 calls, 21,189,978 t-states own (0.40 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 26,551 calls, 1,433,754 t-states own (0.34 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 35,623 calls, 1,923,642 t-states own (0.36 %) |
| Called from | `RunObjects`, `RunPath`, `PathOpExtended`, `PlayerHandler`, `PodStep`, `EventAny`, `WaveScriptStep`, `ScriptTest`, `EndOfPlay` |
| Calls | `PathOpExtended`, `PathOpAccelerate`, `PathOpSetLoop`, `PathOpSetInterval`, `PathOpBounce`, `PathOpHomePlayer`, `PathOpSetDirection`, `PathOpHomeTarget`, `PathOpScroll`, `PathOpRandomDirection`, `PathOpLoop`, `PathOpDriftMiddle`, `PathOpAimPlayer`, `PathOpMove`, `PathOpToCentre`, `PathOpLand`, `PathOpRandomSpeed`, `PathOpBounceArena`, `PathOpDive`, `PathOpMoveFragile`, `PathOpWait`, `PlayerHandler`, `PlasmaFrame`, `HomingFrame`, `SeekerFrame`, `PodSpeedUp`, `PodLaser`, `PodPlasma`, `PodHoming`, `PodSeeker`, `SightHandler`, `LaserHandler`, `PlasmaHandler`, `MissileHandler`, `SeekerHandler`, `EnemyHandler`, `LockableHandler`, `BigEnemyHandler`, `ExplosionStep`, `PodStep`, `EnemyShotStep`, `PodIconJob`, `EffectJob`, `ScoreJob`, `SpriteBuildJob`, `CondNonZero`, `CmdNop`, `CmdScrollStop`, `CmdLevelEnd`, `CmdStore`, `CmdDecrement`, `CmdCheckpoint`, `CmdResetRecords`, `CmdEnemyEscape`, `CmdEnemiesLeft`, `PlayerDied`, `LevelDone` |
| Reads | `$80EA`-`$8143` (`SideWeaponFrames`, `PodActions`, `KindHandlers`, `PathOps` and 1 more); `$81C7`-`$81D6` (`EventHandlers`); `$81FF`-`$8228` (`ScriptCommands`, `ScriptConditions`); `$B111`-`$B114` (`EndHandlers`) |

## waves

`src/game/waves.asm`

### `LaunchWave` (`$91EC`)

**start wave A: the template, the wave record, the objects**

A = the wave number. Refused (NC) when no enemy slot is free (`$8072` = 0) or no wave record is allowed (`$8073` = 0); else `$8073` - 1, the first free wave record at `$8075` (first byte `$FF`) is taken with count 0 and its index kept in A'. `$6926`[A] = the index n; at `$6943` + 2n: the bonus byte (record +1: bits 6-7 the drop type, bits 0-5 the bonus score), then the sprite kind (bit 7: all objects take the next byte as their path, else the kind itself) and the object count; the path numbers fill `$806A`.

The template `$803E` is zeroed, its target (+`$29`) = the player `$F36C`; `$6A65` + 8 x kind gives +`$18`, the speed level (combined with the weapon rating `$80E9` to pick 3 bytes of `$6B15` for +`$19`, +`$20`/+`$21`, +`$22`), the score index (+`$0C`) and the speed (+`$17`) nibbles, the X acceleration (+`$10`), the Y acceleration (+`$14`), the handler kind (+`$07`), the colour (+`$25`) and the hit points (+`$0D`). GetSpriteCache gives the descriptor (+0/+1), its +`$0F` goes to +`$23` and its +`$0C` to the row mask +`$0B`; +`$02` = 1, +`$1A` = the wave record.

Then for each object: TakeEnemySlot, count + 1, the template copied over the slot (bytes +`$09`/+`$0A` and the slot's own collision bit +`$24` kept), the target of the next object = this one, the path pointer from `$6800`/`$681C`, the start delay +`$1B` = D (each next object E frames later), active and visible, X and Y from the stream (a Y of `$FF` = a random row). At the end the descriptor's use count +`$0D` grows by the objects launched, the border/speaker gets OUT (`$FE`),0, carry. 9 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 9 calls, 52,177 t-states own (0.05 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 754 calls, 3,319,949 t-states own (0.06 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 30 calls, 200,902 t-states own (0.05 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 64 calls, 312,282 t-states own (0.06 %) |
| Called from | `WaveScriptStep` |
| Calls | `Random`, `TakeEnemySlot`, `GetSpriteCache` |
| Reads | `$6800`-`$681B` (`PathStarts`); `$6926`-`$6B29` (`WaveIndex`, `WaveDefinitions`, `EnemyKinds`, `KindColours`); `$7EEE`-`$7F51` (`SpriteCache+12`, `SpriteCacheRecord1`, `SpriteCacheUse1`, `SpriteCacheRecord2` and 4 more); `$803E`-`$8081` (`WaveTemplate`, `WavePaths`, `FreeEnemySlots`, `WavesAllowed` and 2 more); `$80E9` (`WeaponRatingLevel`); `$F3A0` (`EnemyObjects+8`); 5 more ranges |
| Writes | `$7EEF`-`$7F4F` (`SpriteCache+13`, `SpriteCacheRecord1`, `SpriteCacheUse1`, `SpriteCacheRecord2` and 4 more); `$803E`-`$8083` (`WaveTemplate`, `WavePaths`, `FreeEnemySlots`, `WavesAllowed` and 2 more); `$931B`-`$931C` (`LaunchWavePathList+1`); `$F398`-`$F473` (`EnemyObjects`) |
| Ports out | `$00FE` |

### `TakeEnemySlot` (`$938D`)

**take one free enemy slot from `$F398` on**

NC (Z) when `$8072`, the free enemy slots, is 0; else `$8072` - 1 and IY = the first record from `$F398` whose +`$08` bit 7 is clear, carry. The count guarantees one is found. 25 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 25 calls, 5,101 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,568 calls, 268,288 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 89 calls, 16,590 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 147 calls, 26,579 t-states own (0.01 %) |
| Called from | `LaunchWave` |
| Reads | `$8072` (`FreeEnemySlots`); `$F3A0` (`EnemyObjects+8`); `$F3CC` (`EnemyObjects+52`); `$F3F8` (`EnemyObjects+96`); `$F424` (`EnemyObjects+140`); `$F450` (`EnemyObjects+184`) |
| Writes | `$8072` (`FreeEnemySlots`) |

### `GetSpriteCache` (`$93A7`)

**the sprite descriptor of kind A, cached or queued**

A = the kind. From `$14` up: HL = `$7EE2` (record 0) with a load queued each time. Else the 6 records from `$7EF2` are searched for a used one (+`$0D` not 0) of this kind (+`$0E` & `$7F`); found: HL = that record. Not found: a free record is picked from `$8088` by the use mask `$8087` (the low nibble, the high one for kinds with bit 4), the least used record evicted (EvictSpriteCache) when none is free; the record is queued for building (QueueSpriteLoad), +`$0E` = kind | `$80`, +`$0F` + `$10`, and its bit set in `$8087`. 7 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 7 calls, 4,232 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 599 calls, 324,333 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 30 calls, 21,207 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 52 calls, 27,647 t-states own (0.01 %) |
| Called from | `LaunchWave` |
| Calls | `SpriteCacheRecord` (tail), `SpriteCacheRet` (tail), `QueueSpriteLoad` |
| Reads | `$7EFF`-`$7F51` (`SpriteCacheUse1`, `SpriteCacheRecord2`, `SpriteCacheRecord3`, `SpriteCacheRecord4` and 2 more); `$8087`-`$8094` (`SpriteCacheMask`, `SpriteCacheFree`) |
| Writes | `$7F00`-`$7F51` (`SpriteCacheUse1+1`, `SpriteCacheRecord2`, `SpriteCacheRecord3`, `SpriteCacheRecord4` and 2 more); `$8087` (`SpriteCacheMask`) |

### `SpriteCacheRecord` (`$940A`)

**HL = `$7EE2` + 16 x B**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 7 calls, 273 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 593 calls, 33,255 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 30 calls, 1,338 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 52 calls, 2,460 t-states own (0.00 %) |
| Called from | `GetSpriteCache` (tail) |
| Calls | `SpriteCacheRet` |

### `SpriteCacheRet` (`$9413`)

**SpriteCacheRet**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 12 calls, 148 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 931 calls, 12,694 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 56 calls, 855 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 82 calls, 1,146 t-states own (0.00 %) |
| Called from | `GetSpriteCache` (tail), `SpriteCacheRecord` |

### `EvictSpriteCache` (`$9414`)

**free the least used sprite-cache record**

The used record with the smallest use count +`$0D` among the 6 from `$7EF2` (read at `$7EFF` + 16 n) is cleared and its number (+`$0F` low nibble) removed from the use mask `$8087`. Not run in c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `QueueSpriteLoad` (`$9441`)

**queue the sprite record DE of kind C for building**

The ring at `$8026` (8 entries of 3 bytes: the kind, the record address), index `$8025` + 1 mod 8; bit 7 of `$81C5` tells the renderer a request is waiting. HL = the record on return. 5 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 5 calls, 1,132 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 344 calls, 75,199 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 26 calls, 5,809 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 30 calls, 6,611 t-states own (0.00 %) |
| Called from | `GetSpriteCache` |
| Reads | `$8025` (`DrawQueueWrite`); `$81C5` (`EventRequests`) |
| Writes | `$8025`-`$803D` (`DrawQueueWrite`, `DrawQueue`); `$81C5` (`EventRequests`) |

## movers

`src/game/movers.asm`

### `RunObjects` (`$9463`)

**run every active object's handler, with the slot toggle of the explosion noise**

Called once a pass from `$AA96` (659 entries in c2, 5.7 % of play's time without the handlers). The landing flag `$974C` is freed (bit 7), the player (`$F36C`) runs by its kind, then the 15 slots from `$F600` down in steps of -44 (DE = `$FFD4`); C counts the slots not active.

After the loop the per-frame hit masks are cleared: `$80BB` (lasers and player), `$80E3` (the homing missile), `$80E4` (the sight), `$80E5` (plasma and seeker), the player's +`$0D` (`$F379`) and the +`$0D` of the 7 records from `$F4F8` (lasers, side weapons, sight; `$F505` on).

[Animation: `RunObjects` at work](img/routines/RunObjects.gif)

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 659 calls, 5,942,216 t-states own (5.66 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 298,726,790 t-states own (5.70 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 23,139,922 t-states own (5.53 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 30,933,653 t-states own (5.82 %) |
| Called from | `PlayPass` |
| Calls | `JumpTable` |
| Reads | `$7F86`-`$7F87` (`SlotBeep`, `SlotBeepMask`); `$974C` (`LandingFlag`); `$F373` (`PlayerObject+7`); `$F39F`-`$F4D4` (`EnemyObjects+7`, `EnemyShots`); `$F4FF`-`$F500` (`LaserShots+7`); `$F52B`-`$F52C` (`LaserShots+51`); 5 more ranges |
| Writes | `$7F86` (`SlotBeep`); `$80BB` (`LaserHitMask`); `$80E3`-`$80E5` (`MissileHitMask`, `SightMask`, `PlasmaHitMask`); `$974C` (`LandingFlag`); `$F379` (`PlayerHitMask`); `$F505` (`LaserShots+13`); 6 more ranges |
| Ports out | `$00FE`, `$18FE` |

### `RunPath` (`$94CB`)

**run the path bytecode of the object IY for one frame**

Frames left +`$1B` - 1: 0 fetches the next command; a count that was already 0 (forever) stays 0. The command +`$1C` goes to JumpTable(`$8114`) with C = the command: carry from the routine runs RunPath again (the next command in the same frame), NC ends it. Called by EnemyHandler, LockableHandler and BigEnemyHandler (1405 entries in c2).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1,405 calls, 192,569 t-states own (0.18 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 98,490 calls, 13,190,721 t-states own (0.25 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,836 calls, 384,985 t-states own (0.09 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 5,855 calls, 801,175 t-states own (0.15 %) |
| Called from | `EnemyHandler`, `LockableHandler`, `BigEnemyHandler` |
| Calls | `JumpTable` |
| Reads | `$681C`-`$6918` (`PathCode`); `$F3B3`-`$F3B6` (`EnemyObjects+27`); `$F3DF`-`$F3E2` (`EnemyObjects+71`); `$F40B`-`$F40E` (`EnemyObjects+115`); `$F437`-`$F43A` (`EnemyObjects+159`); `$F463`-`$F466` (`EnemyObjects+203`) |
| Writes | `$F3B3`-`$F3B6` (`EnemyObjects+27`); `$F3DF`-`$F3E2` (`EnemyObjects+71`); `$F40B`-`$F40E` (`EnemyObjects+115`); `$F437`-`$F43A` (`EnemyObjects+159`); `$F463`-`$F466` (`EnemyObjects+203`) |

### `PathOpExtended` (`$9509`)

**command 7: bits 3-6 pick one of 16 routines from `$8124`**

1151 executions in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 75,596 t-states own (0.07 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 4,847,339 t-states own (0.09 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 127,172 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 304,779 t-states own (0.06 %) |
| Called from | `JumpTable` |
| Calls | `JumpTable` |

### `PathReadWord` (`$9516`)

**DE = the next word of the path**

Used by PathOpLoop for its jump target. Not run in c1/c2; r1 (all levels) runs it: 180 entries.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 180 calls, 24,279 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2 calls, 266 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 133 t-states own (0.00 %) |
| Called from | `PathOpLoop` |
| Reads | `$6840`-`$6841` (`PathCode+36`); `$6875`-`$6876` (`PathCode+89`); `$6897`-`$68A5` (`PathCode+123`); `$68BA`-`$68BB` (`PathCode+158`); `$68E3`-`$68E4` (`PathCode+199`); `$F3B5`-`$F3B6` (`EnemyObjects+29`); 4 more ranges |
| Writes | `$F3B5`-`$F3B6` (`EnemyObjects+29`); `$F3E1`-`$F3E2` (`EnemyObjects+73`); `$F40D`-`$F40E` (`EnemyObjects+117`); `$F439`-`$F43A` (`EnemyObjects+161`); `$F465`-`$F466` (`EnemyObjects+205`) |

### `PathOpAccelerate` (`$9529`)

**command 0: accelerate by the flags in C, then move**

C bit 3: Vx += Ax; bit 4: Vx -= Ax; bit 5: Vy += Ay; bit 6: Vy -= Ay. Then X += Vx, Y += Vy; NC. Also the plain move of the player (C from the joystick), PathOpBounce, PathOpDriftMiddle, PathOpToCentre and PlasmaHandler (C = `$20`, gravity). 1918 executions in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1,684 calls, 784,805 t-states own (0.75 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 67,062 calls, 31,351,459 t-states own (0.60 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 5,130 calls, 2,407,450 t-states own (0.58 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 5,345 calls, 2,523,576 t-states own (0.48 %) |
| Called from | `JumpTable`, `PathOpBounce`, `PathOpDriftMiddle`, `PathOpToCentre`, `PlayerHandler`, `PlasmaHandler` |
| Reads | `$F36F`-`$F381` (`PlayerObject+3`, `PlayerHitMask`, `PlayerAccelX`, `PlayerAccelY`); `$F39B`-`$F3AD` (`EnemyObjects+3`); `$F3C7`-`$F3D9` (`EnemyObjects+47`); `$F3F3`-`$F405` (`EnemyObjects+91`); `$F41F`-`$F431` (`EnemyObjects+135`); `$F44B`-`$F45D` (`EnemyObjects+179`); 2 more ranges |
| Writes | `$F36F`-`$F37F` (`PlayerObject+3`, `PlayerHitMask`, `PlayerAccelX`); `$F39B`-`$F3AB` (`EnemyObjects+3`); `$F3C7`-`$F3D7` (`EnemyObjects+47`); `$F3F3`-`$F403` (`EnemyObjects+91`); `$F41F`-`$F42F` (`EnemyObjects+135`); `$F44B`-`$F45B` (`EnemyObjects+179`); 2 more ranges |

### `PathOpSetLoop` (`$9591`)

**command 1: the loop counter +`$1F` = P**

Carry: an instant command. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 8,604 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 56 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 112 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Writes | `$F3B7` (`EnemyObjects+31`); `$F3E3` (`EnemyObjects+75`); `$F40F` (`EnemyObjects+119`); `$F43B` (`EnemyObjects+163`); `$F467` (`EnemyObjects+207`) |

### `PathOpSetInterval` (`$959C`)

**command 2: the homing interval +`$27` = +`$28` = P**

Carry. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 8,850 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 2,400 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Writes | `$F3BF`-`$F3C0` (`EnemyObjects+39`); `$F3EB`-`$F3EC` (`EnemyObjects+83`); `$F417`-`$F418` (`EnemyObjects+127`); `$F443`-`$F444` (`EnemyObjects+171`); `$F46F`-`$F470` (`EnemyObjects+215`) |

### `PathOpBounce` (`$95AA`)

**command 3: move, bouncing off the scenery**

With scenery under the object (SceneryAt6): only X moves. Else Y moves with the Y acceleration added (C = `$20`, a fall); if that lands it on the scenery or below row 15 the move is undone and Vy reversed (a bounce). NC. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 2,035,992 t-states own (0.04 %) |
| Called from | `JumpTable` |
| Calls | `PathOpAccelerate`, `SceneryAt6` |
| Reads | `$F39B`-`$F3AB` (`EnemyObjects+3`); `$F3C7`-`$F3D7` (`EnemyObjects+47`); `$F3F3`-`$F403` (`EnemyObjects+91`); `$F41F`-`$F42F` (`EnemyObjects+135`); `$F44B`-`$F45B` (`EnemyObjects+179`) |
| Writes | `$F39B`-`$F3AB` (`EnemyObjects+3`); `$F3C7`-`$F3D7` (`EnemyObjects+47`); `$F3F3`-`$F403` (`EnemyObjects+91`); `$F41F`-`$F42F` (`EnemyObjects+135`); `$F44B`-`$F45B` (`EnemyObjects+179`) |

### `PathOpHomePlayer` (`$95FC`)

**command 4: home on the player, turn rate P**

The target +`$29`/+`$2A` = the player `$F36C`, the turn rate +`$2B` = P, then PathOpHome. NC. Not run in c1/c2; r1 (all levels) runs it: 1 entries.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1 call, 5,616 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 3,872 t-states own (0.00 %) |
| Called from | `JumpTable`, `PathOpHomeTarget` (tail) |
| Calls | `PathHomeSetRate`, `PathOpHome` |
| Writes | `$F3C1`-`$F3C3` (`EnemyObjects+41`); `$F3ED`-`$F3EF` (`EnemyObjects+85`); `$F419`-`$F41B` (`EnemyObjects+129`); `$F445`-`$F447` (`EnemyObjects+173`); `$F471`-`$F473` (`EnemyObjects+217`) |

### `PathHomeSetRate` (`$9605`)

**PathHomeSetRate**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 176 calls, 12,878 t-states own (0.00 %) |
| Called from | `PathOpHomePlayer`, `PathOpHomeTarget` (tail) |
| Calls | `PathOpHome` |
| Writes | `$F3C3` (`EnemyObjects+43`); `$F3EF` (`EnemyObjects+87`); `$F41B` (`EnemyObjects+131`); `$F447` (`EnemyObjects+175`); `$F473` (`EnemyObjects+219`) |

### `PathOpSetDirection` (`$9613`)

**command 5: direction (C & `$78`) / 2, then move**

+`$16` = P x 4 (0-60), velocities from the speed +`$17` (SetVelocity), one move; NC. 20 executions in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 2,098 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 139,560 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 7,971 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 12,179 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PathOpMove`, `SetVelocity` |
| Reads | `$F3AF` (`EnemyObjects+23`); `$F3DB` (`EnemyObjects+67`); `$F407` (`EnemyObjects+111`); `$F433` (`EnemyObjects+155`); `$F45F` (`EnemyObjects+199`) |
| Writes | `$F3AE` (`EnemyObjects+22`); `$F3DA` (`EnemyObjects+66`); `$F406` (`EnemyObjects+110`); `$F432` (`EnemyObjects+154`); `$F45E` (`EnemyObjects+198`) |

### `PathOpHomeTarget` (`$9625`)

**command 6: home on the target, the player once it is gone**

The target record +`$29`: no longer active, or of kind 3, makes it PathOpHomePlayer; else turn rate P and PathOpHome. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 8,330 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PathOpHomePlayer` (tail), `PathHomeSetRate` (tail) |
| Reads | `$F373`-`$F374` (`PlayerObject+7`); `$F39F`-`$F3A0` (`EnemyObjects+7`); `$F3C1`-`$F3C2` (`EnemyObjects+41`); `$F445`-`$F446` (`EnemyObjects+173`) |

### `PathOpScroll` (`$9640`)

**extended 0: move with the landscape when it scrolls**

Bit 0 of `$7F6C` set (a frame the playfield scrolls one step): X - `$40` (a quarter column); NC. 251 executions in c2: the ground objects.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 172 calls, 35,916 t-states own (0.03 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 15,486 calls, 2,264,213 t-states own (0.04 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,632 calls, 187,123 t-states own (0.04 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,456 calls, 273,811 t-states own (0.05 %) |
| Called from | `JumpTable`, `PathOpDive`, `PodStep` |
| Reads | `$7F6C` (`ScrollThisPass`); `$F39B`-`$F39C` (`EnemyObjects+3`); `$F3C7`-`$F3C8` (`EnemyObjects+47`); `$F3F3`-`$F3F4` (`EnemyObjects+91`); `$F41F`-`$F420` (`EnemyObjects+135`); `$F44B`-`$F44C` (`EnemyObjects+179`) |
| Writes | `$F39B`-`$F39C` (`EnemyObjects+3`); `$F3C7`-`$F3C8` (`EnemyObjects+47`); `$F3F3`-`$F3F4` (`EnemyObjects+91`); `$F41F`-`$F420` (`EnemyObjects+135`); `$F44B`-`$F44C` (`EnemyObjects+179`) |

### `PathOpStop` (`$9658`)

**extended 1: stop**

Vx = Vy = 0; the flags of XOR A: NC. Not run in c1/c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpRandomDirection` (`$9666`)

**extended 2: a random direction, then move**

+`$16` = random & `$3F`, the velocities for the speed +`$17`, one move; NC. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 3,640 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `Random`, `PathOpMove`, `SetVelocity` |
| Reads | `$F3AF` (`EnemyObjects+23`); `$F3DB` (`EnemyObjects+67`); `$F407` (`EnemyObjects+111`); `$F433` (`EnemyObjects+155`); `$F45F` (`EnemyObjects+199`) |
| Writes | `$F3AE` (`EnemyObjects+22`); `$F3DA` (`EnemyObjects+66`); `$F406` (`EnemyObjects+110`); `$F432` (`EnemyObjects+154`); `$F45E` (`EnemyObjects+198`) |

### `PathOpLoop` (`$9679`)

**extended 3: loop back to the word target while +`$1F` counts down**

Reads the target word; +`$1F` - 1: not 0 = the path pointer goes to the target; carry either way (the next command runs at once). Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 17,995 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 202 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 101 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PathReadWord` |
| Reads | `$F3B7` (`EnemyObjects+31`); `$F3E3` (`EnemyObjects+75`); `$F40F` (`EnemyObjects+119`); `$F43B` (`EnemyObjects+163`); `$F467` (`EnemyObjects+207`) |
| Writes | `$F3B5`-`$F3B7` (`EnemyObjects+29`); `$F3E1`-`$F3E3` (`EnemyObjects+73`); `$F40D`-`$F40F` (`EnemyObjects+117`); `$F439`-`$F43B` (`EnemyObjects+161`); `$F465`-`$F467` (`EnemyObjects+205`) |

### `PathOpDriftMiddle` (`$9689`)

**extended 4: accelerate towards row 8**

Above row 8: C = `$20` (Vy + Ay), else `$40` (Vy - Ay); PathOpAccelerate; NC. 1071 executions in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 91,094 t-states own (0.09 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,217,893 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 101,283 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 117,090 t-states own (0.02 %) |
| Called from | `JumpTable` |
| Calls | `PathOpAccelerate` |
| Reads | `$F39E` (`EnemyObjects+6`); `$F3CA` (`EnemyObjects+50`); `$F3F6` (`EnemyObjects+94`); `$F422` (`EnemyObjects+138`); `$F44E` (`EnemyObjects+182`) |

### `PathOpAimPlayer` (`$9699`)

**extended 5: the direction to the player**

+`$16` = DirectionTo the player, velocities for the speed; carry. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 11,745 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `DirectionTo`, `SetVelocity` |
| Reads | `$F3AF` (`EnemyObjects+23`); `$F3DB` (`EnemyObjects+67`); `$F407` (`EnemyObjects+111`); `$F433` (`EnemyObjects+155`); `$F45F` (`EnemyObjects+199`) |

### `PathOpMove` (`$96A8`)

**extended 7: X += Vx, Y += Vy**

NC. Also the move of SetDirection, RandomDirection, PathOpHome and MoveFragile. 38 executions in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 38 calls, 10,110 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 12,011 calls, 9,459,489 t-states own (0.18 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1,891 calls, 612,910 t-states own (0.15 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1,494 calls, 1,126,524 t-states own (0.21 %) |
| Called from | `JumpTable`, `PathOpSetDirection`, `PathOpRandomDirection`, `PathOpHome`, `PathOpMoveFragile` |
| Reads | `$F39B`-`$F3D7` (`EnemyObjects+3`); `$F3F3`-`$F403` (`EnemyObjects+91`); `$F41F`-`$F42F` (`EnemyObjects+135`); `$F44B`-`$F45B` (`EnemyObjects+179`); `$F477`-`$F487` (`EnemyShots+3`); `$F4A3`-`$F4B3` (`EnemyShots+47`); 2 more ranges |
| Writes | `$F39B`-`$F3CA` (`EnemyObjects+3`); `$F3F3`-`$F3F6` (`EnemyObjects+91`); `$F41F`-`$F422` (`EnemyObjects+135`); `$F44B`-`$F44E` (`EnemyObjects+179`); `$F477`-`$F47A` (`EnemyShots+3`); `$F4A3`-`$F4A6` (`EnemyShots+47`); 2 more ranges |

### `PathOpScrollAlways` (`$96D0`)

**extended 6: X - `$40` every pass**

NC. Not run in c1/c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathOpHome` (`$96E2`)

**extended 8: turn towards the target, then move**

Every +`$28` frames (+`$27` counts down): the direction to the target (+`$29`/+`$2A`) by DirectionTo; a difference up to the turn rate +`$2B` is taken at once, else the direction turns by +`$2B` the shorter way round (mod 64), and SetVelocity for the speed +`$17`. Then PathOpMove; NC. 18 executions in c2; the homing missile and the seeker use it too.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 18 calls, 1,327 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 10,266 calls, 943,249 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1,818 calls, 214,367 t-states own (0.05 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1,380 calls, 134,375 t-states own (0.03 %) |
| Called from | `PathOpHomePlayer`, `PathHomeSetRate`, `MissileHandler`, `SeekerHandler`, `EnemyShotStep` |
| Calls | `PathOpMove`, `DirectionTo`, `SetVelocity` |
| Reads | `$F3AE`-`$F3EF` (`EnemyObjects+22`); `$F406`-`$F41B` (`EnemyObjects+110`); `$F432`-`$F447` (`EnemyObjects+154`); `$F45E`-`$F473` (`EnemyObjects+198`); `$F48A`-`$F49F` (`EnemyShots+22`); `$F4B6`-`$F4CB` (`EnemyShots+66`); 2 more ranges |
| Writes | `$F3AE` (`EnemyObjects+22`); `$F3BF`-`$F3EB` (`EnemyObjects+39`); `$F406` (`EnemyObjects+110`); `$F417` (`EnemyObjects+127`); `$F432` (`EnemyObjects+154`); `$F443` (`EnemyObjects+171`); 10 more ranges |

### `PathOpToCentre` (`$972E`)

**extended 9: accelerate towards column 32 and row 8**

X below 32: C = 8 (Vx + Ax), else `$10`; Y below 8: `$20`, else `$40`; PathOpAccelerate; NC. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,115,506 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 3,142 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 33,883 t-states own (0.01 %) |
| Called from | `JumpTable` |
| Calls | `PathOpAccelerate` |
| Reads | `$F39C`-`$F39E` (`EnemyObjects+4`); `$F3C8`-`$F3CA` (`EnemyObjects+48`); `$F3F4`-`$F3F6` (`EnemyObjects+92`); `$F420`-`$F422` (`EnemyObjects+136`); `$F44C`-`$F44E` (`EnemyObjects+180`) |

### `PathOpLand` (`$974D`)

**extended 10: put the object on the ground below it**

One object a frame (bit 7 of LandingFlag). After 8 failed tries in a row, or when another object landed this frame, it is parked at X = 0, Y = 0 (off the playfield, it leaves). Else Y fraction = `$E0`, Y goes down out of any scenery, then on down to the first row with all 4 cells under it filled: Y one up there, the repeat count 1, the tries reset; a row that is filled only in part parks it. NC. 1 execution in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 598 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 792,952 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 7,321 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 7,337 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SceneryAt6`, `SceneryCell` |
| Reads | `$974C` (`LandingFlag`); `$B800`-`$BFFF` (`MapRingSpace+209`, `TileSource`); `$F39E` (`EnemyObjects+6`); `$F3CA` (`EnemyObjects+50`); `$F3F6` (`EnemyObjects+94`); `$F422` (`EnemyObjects+138`); 1 more ranges |
| Writes | `$974C` (`LandingFlag`); `$F39C`-`$F39E` (`EnemyObjects+4`); `$F3B3` (`EnemyObjects+27`); `$F3C8`-`$F3CA` (`EnemyObjects+48`); `$F3DF` (`EnemyObjects+71`); `$F3F4`-`$F3F6` (`EnemyObjects+92`); 5 more ranges |

### `PathOpRandomSpeed` (`$97B3`)

**extended 11: the speed +`$17` one up or down at random**

A random byte below `$55` keeps it, below `$AA` + 1, else - 1; kept in 1-7 (0 refused). Carry. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 28,295 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 2,947 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `Random` |
| Reads | `$F3AF` (`EnemyObjects+23`); `$F3DB` (`EnemyObjects+67`); `$F407` (`EnemyObjects+111`); `$F433` (`EnemyObjects+155`); `$F45F` (`EnemyObjects+199`) |
| Writes | `$F3AF` (`EnemyObjects+23`); `$F3DB` (`EnemyObjects+67`); `$F407` (`EnemyObjects+111`); `$F433` (`EnemyObjects+155`); `$F45F` (`EnemyObjects+199`) |

### `PathOpBounceArena` (`$97CD`)

**extended 12: move, bouncing off the scenery and the edges**

X + Vx: outside columns 16-45 or on scenery: X back, Vx = -Vx. Y + Vy: Y 17 or more (also a negative Y) or on scenery: Y back, Vy = -Vy. NC. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 9,772,567 t-states own (0.19 %) |
| Called from | `JumpTable` |
| Calls | `SceneryAt6` |
| Reads | `$F39B`-`$F3AB` (`EnemyObjects+3`); `$F3C7`-`$F3D7` (`EnemyObjects+47`); `$F3F3`-`$F403` (`EnemyObjects+91`); `$F41F`-`$F42F` (`EnemyObjects+135`); `$F44B`-`$F45B` (`EnemyObjects+179`) |
| Writes | `$F39B`-`$F3AB` (`EnemyObjects+3`); `$F3C7`-`$F3D7` (`EnemyObjects+47`); `$F3F3`-`$F403` (`EnemyObjects+91`); `$F41F`-`$F42F` (`EnemyObjects+135`); `$F44B`-`$F45B` (`EnemyObjects+179`) |

### `PathOpDive` (`$9837`)

**extended 13: scroll along, dive at the player when close**

PathOpScroll, then, once its column is no more than the player's plus half the row distance between them and a random byte is below 200: one frame of Vy = -`$80`, Vx = -`$40` (a dive up and back). Else on scenery: SelfDestruct. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 687,779 t-states own (0.01 %) |
| Called from | `JumpTable` |
| Calls | `Random`, `PathOpScroll`, `SelfDestruct`, `SceneryAt6` |
| Reads | `$F370`-`$F372` (`PlayerObject+4`); `$F39C`-`$F39E` (`EnemyObjects+4`); `$F3C8`-`$F3CA` (`EnemyObjects+48`); `$F3F4`-`$F3F6` (`EnemyObjects+92`); `$F420`-`$F422` (`EnemyObjects+136`); `$F44C`-`$F44E` (`EnemyObjects+180`) |
| Writes | `$F3A6`-`$F3B3` (`EnemyObjects+14`); `$F3D2`-`$F3DF` (`EnemyObjects+58`); `$F3FE`-`$F40B` (`EnemyObjects+102`); `$F42A`-`$F437` (`EnemyObjects+146`); `$F456`-`$F463` (`EnemyObjects+190`) |

### `PathOpMoveFragile` (`$9874`)

**extended 14: move; destroyed on scenery or leaving the playfield**

PathOpMove; Y 17 or more, X outside 16-46, or scenery under it: SelfDestruct. NC. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 44,545 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PathOpMove`, `SelfDestruct`, `SceneryAt6` |
| Reads | `$F39C`-`$F39E` (`EnemyObjects+4`); `$F3C8`-`$F3CA` (`EnemyObjects+48`); `$F3F4`-`$F3F6` (`EnemyObjects+92`); `$F420`-`$F422` (`EnemyObjects+136`); `$F44C`-`$F44E` (`EnemyObjects+180`) |

### `PathOpWait` (`$9890`)

**extended 15: do nothing this frame**

NC. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 9,842 t-states own (0.00 %) |
| Called from | `JumpTable` |

### `SelfDestruct` (`$9892`)

**mark the object as hit by the player's laser**

+`$0D` = 1 (one hit point) and its bit (+`$24`) into `$80BB`: the enemy handler's laser test kills it this frame. Not run in c1/c2; r1 (all levels) runs it: 36 entries.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36 calls, 2,656 t-states own (0.00 %) |
| Called from | `PathOpDive`, `PathOpMoveFragile` |
| Reads | `$80BB` (`LaserHitMask`); `$F3BC` (`EnemyObjects+36`); `$F3E8` (`EnemyObjects+80`); `$F414` (`EnemyObjects+124`); `$F440` (`EnemyObjects+168`); `$F46C` (`EnemyObjects+212`) |
| Writes | `$80BB` (`LaserHitMask`); `$F3A5` (`EnemyObjects+13`); `$F3D1` (`EnemyObjects+57`); `$F3FD` (`EnemyObjects+101`); `$F429` (`EnemyObjects+145`); `$F455` (`EnemyObjects+189`) |

### `DirectionTo` (`$989F`)

**A = the direction 0-63 from the object IY to IX**

The rounded column and row distances; their signs pick the octant, the ratio of the smaller to the larger (by subtraction in 8 steps) the direction inside it. Used by PathOpAimPlayer, PathOpHome and `$A0EB`. Not run in c1/c2; r1 (all levels) runs it: 1431 entries: the homing interval of the objects there never ran out.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,431 calls, 658,847 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 362 calls, 183,194 t-states own (0.04 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 161 calls, 81,821 t-states own (0.02 %) |
| Called from | `PathOpAimPlayer`, `PathOpHome`, `EnemyFire` |
| Reads | `$F36F`-`$F372` (`PlayerObject+3`); `$F39B`-`$F3CA` (`EnemyObjects+3`); `$F3F4`-`$F3F6` (`EnemyObjects+92`); `$F420`-`$F422` (`EnemyObjects+136`); `$F44C`-`$F44E` (`EnemyObjects+180`); `$F478`-`$F47A` (`EnemyShots+4`); 3 more ranges |

### `SetVelocity` (`$98F1`)

**the velocities for direction A and speed B**

Vx = B x sine[A] and Vy = B x sine[(A - 16) & `$3F`] with the 64-entry signed sine table `$8144` (B additions, so B is 1-7 in practice). 21 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 21 calls, 8,399 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,720 calls, 1,193,533 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 321 calls, 130,495 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 246 calls, 106,039 t-states own (0.02 %) |
| Called from | `PathOpSetDirection`, `PathOpRandomDirection`, `PathOpAimPlayer`, `PathOpHome`, `SeekerFrame`, `EnemyFire` |
| Reads | `$8144`-`$8183` (`SineTable`) |
| Writes | `$F3A6`-`$F3D7` (`EnemyObjects+14`); `$F3FE`-`$F403` (`EnemyObjects+102`); `$F42A`-`$F42F` (`EnemyObjects+146`); `$F456`-`$F45B` (`EnemyObjects+190`); `$F482`-`$F487` (`EnemyShots+14`); `$F4AE`-`$F4B3` (`EnemyShots+58`); 2 more ranges |

## objutil

`src/game/objutil.asm`

### `FreeEnemySlot` (`$992A`)

**an enemy slot back: `$8072` + 1, its bit out of `$80BD`/`$80BE`**

Its collision bit (+`$24`) is cleared from the masks `$80BD` and `$80BE` (the harmless enemies, set at `$8D1A` and by `$A2C4`/`$A30E`) and the slot deactivated. Used by the enemy handlers and `$A1C8`, `$A1FD`, `$A2D6`. 26 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 26 calls, 3,401 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,212 calls, 157,702 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 84 calls, 11,122 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 116 calls, 15,164 t-states own (0.00 %) |
| Called from | `EnemyHandler`, `LockableHandler`, `ExplosionStep` (tail), `PodStep`, `ExplosionToPod` (tail), `CmdEnemyEscape` |
| Reads | `$8072` (`FreeEnemySlots`); `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F3A0` (`EnemyObjects+8`); `$F3BC`-`$F3CC` (`EnemyObjects+36`); `$F3E8`-`$F3F8` (`EnemyObjects+80`); `$F414`-`$F424` (`EnemyObjects+124`); 2 more ranges |
| Writes | `$8072` (`FreeEnemySlots`); `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F3A0` (`EnemyObjects+8`); `$F3CC` (`EnemyObjects+52`); `$F3F8` (`EnemyObjects+96`); `$F424` (`EnemyObjects+140`); 1 more ranges |

### `FreeObject` (`$9941`)

**deactivate the object and `$8074` + 1**

Used by `$A263` (the kind 5 handler); `$8074` is set at `$8D0D` and read at `$A113`. 1 entry in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 59 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 514 calls, 28,045 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 59 calls, 3,388 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 52 calls, 3,040 t-states own (0.00 %) |
| Called from | `EnemyShotStep` |
| Reads | `$8074` (`EnemyShotsLeft`); `$F47C` (`EnemyShots+8`); `$F4A8` (`EnemyShots+52`); `$F4D4` (`EnemyShots+96`) |
| Writes | `$8074` (`EnemyShotsLeft`); `$F47C` (`EnemyShots+8`); `$F4A8` (`EnemyShots+52`); `$F4D4` (`EnemyShots+96`) |

### `EnemyEscaped` (`$994A`)

**the object left the playfield: count its wave down, no bonus**

C = `$FF`: the wave record gets bit 7 (an escape), so the wave pays no bonus. 7 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 7 calls, 133 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 408 calls, 7,752 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 33 calls, 627 t-states own (0.00 %) |
| Called from | `EnemyHandler`, `LockableHandler`, `CmdEnemyEscape` |
| Calls | `EnemyGone` (tail) |

### `EnemyKilled` (`$994E`)

**the object was destroyed: count its wave down**

+`$26` = 0 (no drop), C = 0, then EnemyGone. 9 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 9 calls, 234 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 789 calls, 20,514 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 86 calls, 28,858 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 84 calls, 2,184 t-states own (0.00 %) |
| Called from | `EnemyHandler`, `LockableHandler`, `BigEnemyHandler` |
| Calls | `EnemyGone`, `AddScore` |
| Reads | `$7EFF`-`$7F11` (`SpriteCacheUse1`, `SpriteCacheRecord2`); `$7F3F`-`$7F41` (`SpriteCacheRecord5+13`); `$8073`-`$8087` (`WavesAllowed`, `EnemyShotsLeft`, `WaveRecords`, `SpriteCacheMask`); `$F398`-`$F399` (`EnemyObjects`); `$F3B2`-`$F3C5` (`EnemyObjects+26`); `$F3DE`-`$F3F1` (`EnemyObjects+70`); 3 more ranges |
| Writes | `$7EFF`-`$7F0F` (`SpriteCacheUse1`, `SpriteCacheRecord2`); `$7F3F` (`SpriteCacheRecord5+13`); `$8073`-`$8087` (`WavesAllowed`, `EnemyShotsLeft`, `WaveRecords`, `SpriteCacheMask`); `$F3BE` (`EnemyObjects+38`); `$F3EA` (`EnemyObjects+82`); `$F416` (`EnemyObjects+126`); 2 more ranges |

### `EnemyGone` (`$9954`)

**EnemyGone**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 16 calls, 4,590 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,197 calls, 369,981 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 117 calls, 35,651 t-states own (0.01 %) |
| Called from | `EnemyEscaped` (tail), `EnemyKilled` |
| Calls | `AddScore` |
| Reads | `$7ECA` (`LaserDescriptor+2`); `$7EEF`-`$7F51` (`SpriteCache+13`, `SpriteCacheRecord1`, `SpriteCacheUse1`, `SpriteCacheRecord2` and 4 more); `$8073`-`$8087` (`WavesAllowed`, `EnemyShotsLeft`, `WaveRecords`, `SpriteCacheMask`); `$F398`-`$F399` (`EnemyObjects`); `$F3B2`-`$F3C5` (`EnemyObjects+26`); `$F3DE`-`$F3F1` (`EnemyObjects+70`); 3 more ranges |
| Writes | `$7EEF`-`$7F4F` (`SpriteCache+13`, `SpriteCacheRecord1`, `SpriteCacheUse1`, `SpriteCacheRecord2` and 4 more); `$8073`-`$8087` (`WavesAllowed`, `EnemyShotsLeft`, `WaveRecords`, `SpriteCacheMask`); `$F3BE` (`EnemyObjects+38`); `$F3EA` (`EnemyObjects+82`); `$F416` (`EnemyObjects+126`); `$F442` (`EnemyObjects+170`); 1 more ranges |

### `SceneryAt1` (`$99A9`)

**carry if the cell under the object is not empty**

Used by PlasmaHandler, SeekerHandler and `$A263`. 18 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 18 calls, 918 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 10,226 calls, 469,322 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,826 calls, 137,514 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1,332 calls, 66,462 t-states own (0.01 %) |
| Called from | `PlasmaHandler`, `SeekerHandler`, `EnemyShotStep` |
| Calls | `SceneryCell` |
| Reads | `$B706`-`$B75A` (`Start+7`, `MapRingSpace`); `$B76F`-`$BFE5` (`MapRingSpace+64`, `TileSource`) |

### `SceneryAt2` (`$99B1`)

**carry if one of the 2 cells (X, X + 1) is not empty**

Used by LaserHandler (869 entries in c2).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 869 calls, 52,135 t-states own (0.05 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 38,542 calls, 2,219,265 t-states own (0.04 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 5,414 calls, 320,792 t-states own (0.08 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,719 calls, 222,120 t-states own (0.04 %) |
| Called from | `LaserHandler` |
| Calls | `SceneryCell` |
| Reads | `$B700`-`$B7CD` (`Start+1`, `MapRingSpace`); `$B7E0`-`$BFFF` (`MapRingSpace+177`, `TileSource`) |

### `SceneryAt4` (`$99BB`)

**carry if one of 2 x 2 cells is not empty**

Used by `$A2D6`. 2 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 258 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 239 calls, 31,128 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 29 calls, 3,842 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 28 calls, 3,852 t-states own (0.00 %) |
| Called from | `ExplosionToPod` |
| Calls | `SceneryCell` |
| Reads | `$B7A3`-`$B7A4` (`MapRingSpace+116`); `$B823`-`$B824` (`MapRingSpace+244`); `$B842`-`$B87C` (`MapRingSpace+275`); `$B8D5`-`$B8DB` (`MapRingSpace+422`); `$B8F3`-`$B8F4` (`MapRingSpace+452`); `$B90E`-`$BEFF` (`MapRingSpace+479`, `TileSource`); 7 more ranges |

### `SceneryAt6` (`$99D5`)

**carry if one of 2 x 3 cells is not empty**

The ship's and most movers' test: rows Y, Y + 1, Y + 2 of columns X and X + 1 (a row is 128 bytes: + `$80`, with the carry into H on every second row). 1227 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1,227 calls, 92,222 t-states own (0.09 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 134,520 calls, 10,086,924 t-states own (0.19 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 5,996 calls, 447,976 t-states own (0.11 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 7,436 calls, 559,282 t-states own (0.11 %) |
| Called from | `PathOpBounce`, `PathOpLand`, `PathOpBounceArena`, `PathOpDive`, `PathOpMoveFragile`, `PlayerHandler` |
| Calls | `SceneryAt6Row2`, `SceneryCell` |
| Reads | `$B700`-`$BF10` (`Start+1`, `MapRingSpace`, `TileSource`); `$BF26`-`$BF27` (`TileSource+806`); `$BF50`-`$BFB7` (`TileSource+848`); `$BFCE`-`$BFD6` (`TileSource+974`); `$BFEB`-`$BFEC` (`TileSource+1003`); `$F372` (`PlayerObject+6`); 5 more ranges |

### `SceneryAt6Row2` (`$99E4`)

**SceneryAt6Row2**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1,227 calls, 157,374 t-states own (0.15 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 134,520 calls, 17,253,141 t-states own (0.33 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 5,996 calls, 766,288 t-states own (0.18 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 7,436 calls, 952,975 t-states own (0.18 %) |
| Called from | `SceneryAt6` |
| Reads | `$B700`-`$C010` (`Start+1`, `MapRingSpace`, `TileSource`); `$C026`-`$C027` (`GlyphCache+38`); `$C050`-`$C0B7` (`GlyphCache+80`); `$C0CE`-`$C0D6` (`GlyphCache+206`); `$C0EB`-`$C0EC` (`GlyphCache+235`); `$F372` (`PlayerObject+6`); 5 more ranges |

### `SceneryCell` (`$99FF`)

**HL = the scenery cell of the object IY**

HL = (`$8022`) + Y x 128 + X with the integer parts +`$06` and +`$04`. 2118 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2,118 calls, 222,913 t-states own (0.21 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 187,305 calls, 19,707,390 t-states own (0.38 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 14,289 calls, 1,504,521 t-states own (0.36 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 12,539 calls, 1,322,602 t-states own (0.25 %) |
| Called from | `PathOpLand`, `SceneryAt1`, `SceneryAt2`, `SceneryAt4`, `SceneryAt6` |
| Reads | `$8022`-`$8023` (`ScrollMap`); `$F370`-`$F47A` (`PlayerObject+4`, `EnemyObjects`, `EnemyShots`); `$F4A4`-`$F4A6` (`EnemyShots+48`); `$F4D0`-`$F4D2` (`EnemyShots+92`); `$F4FC`-`$F4FE` (`LaserShots+4`); `$F528`-`$F52A` (`LaserShots+48`); 3 more ranges |

### `ClampRow` (`$9A13`)

**keep the object in rows 0-15**

A negative row: Y = 0.0; 16 or more: Y = 15 + `$E0`/256. 2028 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2,028 calls, 107,254 t-states own (0.10 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 135,057 calls, 7,036,872 t-states own (0.13 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 5,959 calls, 313,872 t-states own (0.08 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 9,601 calls, 502,905 t-states own (0.09 %) |
| Called from | `PlayerHandler`, `ScatterDebris`, `MissileHandler`, `SeekerHandler`, `EnemyHandler`, `LockableHandler`, `BigEnemyHandler` |
| Reads | `$F372` (`PlayerObject+6`); `$F39E` (`EnemyObjects+6`); `$F3CA` (`EnemyObjects+50`); `$F3F6` (`EnemyObjects+94`); `$F422` (`EnemyObjects+138`); `$F44E` (`EnemyObjects+182`); 1 more ranges |
| Writes | `$F371`-`$F372` (`PlayerObject+5`); `$F39D`-`$F39E` (`EnemyObjects+5`); `$F3C9`-`$F3CA` (`EnemyObjects+49`); `$F3F5`-`$F3F6` (`EnemyObjects+93`); `$F421`-`$F422` (`EnemyObjects+137`); `$F44D`-`$F44E` (`EnemyObjects+181`) |

### `ClampColumn` (`$9A2F`)

**keep the player in columns 16-45**

Below 16: X = 16.0; 46 or more: X = 45 + `$E0`/256. Only the player uses it (613 entries in c2).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 613 calls, 33,887 t-states own (0.03 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 2,000,737 t-states own (0.04 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 164,314 t-states own (0.04 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 207,260 t-states own (0.04 %) |
| Called from | `PlayerHandler` |
| Reads | `$F370` (`PlayerObject+4`) |
| Writes | `$F36F`-`$F370` (`PlayerObject+3`) |

### `CycleColour` (`$9A4C`)

**the next ink colour 1-7 in +`$25` (bits 3-5)**

The flash of the missiles, the plasma and the hit big enemy. Not run in c1/c2; r1 (all levels) runs it: 291 entries.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 291 calls, 21,718 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 587 calls, 44,344 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 35 calls, 2,600 t-states own (0.00 %) |
| Called from | `PlasmaHandler`, `MissileHandler`, `SeekerHandler`, `BigEnemyHandler` |
| Reads | `$F3BD` (`EnemyObjects+37`); `$F5CD` (`PlasmaBall2+37`); `$F5F9` (`SideShot+37`) |
| Writes | `$F3BD` (`EnemyObjects+37`); `$F5CD` (`PlasmaBall2+37`); `$F5F9` (`SideShot+37`) |

## player

`src/game/player.asm`

### `PlayerHandler` (`$9A5B`)

**kind 0: the ship for one frame**

Not alive (`$7F7B` not `$FF`): PlayerDying. Else the fuel count; `$A6B6`; the input `$8186` (bits 0/1 right/left, 2/3 down/up): up or down sets Vy = the speed - `$20` at once, left or right accelerate X up to the speed + `$20` (the acceleration masked at the limit), no horizontal input brakes Vx to 0. PathOpAccelerate moves, ClampRow and ClampColumn keep it on the screen, scenery under the ship undoes the row move (to the row's edge). A moving ship writes its position into the ring of 8 at `$80C0` (index `$80BF`): the sight follows it from there.

The colour +`$25`: `$70`, or the flashing `$7F79` x 8 + `$40` while fire has been held 8 frames or more (`$8184`, the pod-collect signal). The side weapon's frame routine from `$80EA` by +`$08` - 2; a fire press (`$8185` = `$FF`) FireLaser; then the hit test. 659 executions in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 613,496 t-states own (0.58 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 32,438,068 t-states own (0.62 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 2,948,480 t-states own (0.70 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 3,718,481 t-states own (0.70 %) |
| Called from | `JumpTable` |
| Calls | `JumpTable`, `PathOpAccelerate`, `SceneryAt6`, `ClampRow`, `ClampColumn`, `ScatterDebris`, `FuelOut`, `FireLaser`, `ReadControls` |
| Reads | `$7F63` (`PassBit`); `$7F79`-`$7F7B` (`SpinnerColour`, `SpinnerColourStep`, `DeathTimer`); `$7F99`-`$7FA7` (`PlayerRecord`, `Players`, `Player1`); `$80BD`-`$80BF` (`HarmlessMaskA`, `HarmlessMaskB`, `ShipHistoryIndex`); `$80E6` (`Fuel`); `$8184`-`$8186` (`FireHeld`, `FireChanged`, `ControlBits`); 9 more ranges |
| Writes | `$7F7B`-`$7F7C` (`DeathTimer`, `EndPending`); `$80BF`-`$80E6` (`ShipHistoryIndex`, `ShipHistory`, `LockTarget`, `LockMask` and 4 more); `$F371`-`$F4D4` (`PlayerObject+5`, `EnemyObjects`, `EnemyShots`); `$F500` (`LaserShots+8`); `$F52C` (`LaserShots+52`); `$F558` (`LaserShots+96`); 4 more ranges |

### `KillPlayer` (`$9B5F`)

**the ship destroyed: the timer and the explosion**

`$7F7B` = `$16` (22 frames), all 16 records from `$F36C` deactivated, ScatterDebris. 2 executions in c2.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WeaponRating` (`$9B75`)

**the weapon rating `$80E7-$80E9` for the enemy fire and the wave colours**

L = laser level + side weapon: `$80E7` = `$FF`, `$30` from 4; `$80E9` = 0, 8 from 7; `$80E8` = ((speed / 32 + L) x 4) & `$F0` + (`$81DE`). LaunchWave adds `$80E9` to a kind's colour select (the KindColours set); EnemyFire reads `$80E7` (the first shot's column) and `$80E8` (the fire chance), so a well armed, fast ship draws more fire. Called from `$AC7A` and `$B03A` (10 entries in c2).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 10 calls, 2,508 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 914 calls, 229,050 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 106 calls, 26,241 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 100 calls, 24,875 t-states own (0.00 %) |
| Called from | `ScoreJob`, `ScoreJobRating`, `RoundPlaySetup` |
| Reads | `$7F99`-`$7FA7` (`PlayerRecord`, `Players`, `Player1`); `$81DE` (`ScriptLevelBias`) |
| Writes | `$80E7`-`$80E9` (`WeaponRatingMask`, `WeaponRatingValue`, `WeaponRatingLevel`) |

### `ScatterDebris` (`$9BAB`)

**the 5 records from `$F398` as debris around IY**

Each at a random column X - 1 + 0-3 and a random row near Y, active, +`$26` = 0, `$A293` (the explosion picture), ClampRow, +`$27` = random 0-3; `$8072` = 0, so no wave starts until they are gone. Used by KillPlayer and BigEnemyHandler. 2 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 3,767 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 5 calls, 8,971 t-states own (0.00 %) |
| Called from | `PlayerHandler`, `BigEnemyHandler` |
| Calls | `Random`, `ClampRow`, `StartExplosion` |
| Reads | `$F370`-`$F372` (`PlayerObject+4`); `$F39C`-`$F3A0` (`EnemyObjects+4`); `$F3CC` (`EnemyObjects+52`); `$F3F8` (`EnemyObjects+96`); `$F424` (`EnemyObjects+140`); `$F450` (`EnemyObjects+184`) |
| Writes | `$8072` (`FreeEnemySlots`); `$F39C`-`$F3A0` (`EnemyObjects+4`); `$F3BE`-`$F3CC` (`EnemyObjects+38`); `$F3EA`-`$F3F8` (`EnemyObjects+82`); `$F416`-`$F424` (`EnemyObjects+126`); `$F442`-`$F450` (`EnemyObjects+170`); 1 more ranges |

### `FuelOut` (`$9C03`)

**the fuel ran out: `$80E6` = `$5A`, laser - 1, speed - `$20`**

The laser level +`$0A` of IX does not go below 0, the speed +`$0B` not below `$40`. Also called at `$B119`. 1 entry in c2; measured, see the module notes.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 97 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 33 calls, 4,042 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2 calls, 237 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 5 calls, 622 t-states own (0.00 %) |
| Called from | `PlayerHandler`, `PlayerDied` |
| Reads | `$7FA6`-`$7FA7` (`Player1LaserLevel`, `Player1Speed`) |
| Writes | `$7FA6`-`$7FA7` (`Player1LaserLevel`, `Player1Speed`); `$80E6` (`Fuel`) |

### `FireLaser` (`$9C1D`)

**fire a laser shot from the ship**

`$80BA` counts the shots not in flight (4 at most, set at `$B2D1`; LaserHandler gives one back): a shot is fired only when `$80BA` + the laser level is 4 or more, so level 0 has one shot in the air, level 3 four. The first free of the 4 slots at `$F4F8`: X + 1 column, Y + `$1E0`/256 for two shots out of three, + `$20`/256 for the third (+`$26` counts the guns); sound effect 2 (`$B2F0`); `$7F77` = 6 when 0. 564 entries in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 564 calls, 74,369 t-states own (0.07 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,480 calls, 6,935,239 t-states own (0.13 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 769 calls, 248,100 t-states own (0.06 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1,041 calls, 215,251 t-states own (0.04 %) |
| Called from | `PlayerHandler` |
| Calls | `RequestEffect` |
| Reads | `$7F77` (`PanelBurst`); `$7F99`-`$7FA6` (`PlayerRecord`, `Players`, `Player1`); `$80BA` (`LaserShotsFree`); `$F36F`-`$F372` (`PlayerObject+3`); `$F392` (`PlayerAccelY+18`); `$F500` (`LaserShots+8`); 2 more ranges |
| Writes | `$7F77` (`PanelBurst`); `$80BA` (`LaserShotsFree`); `$F392` (`PlayerAccelY+18`); `$F4FB`-`$F500` (`LaserShots+3`); `$F527`-`$F52C` (`LaserShots+47`); `$F553`-`$F558` (`LaserShots+91`) |

## weapons

`src/game/weapons.asm`

### `PlasmaFrame` (`$9C83`)

**side weapon 2: a plasma ball after 3 frames of fire**

Fire held exactly 3 frames: `$F5D4` when free, else with the double plasma (+`$09` = 1) `$F5A8` when free; active, Vy = 0, 3 bounces (+`$26`), PlaceAtPlayer. Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 52,689 t-states own (0.01 %) |
| Called from | `JumpTable` |
| Calls | `PlaceAtPlayer` |
| Reads | `$7FA5` (`Player1DoublePlasma`); `$8184` (`FireHeld`); `$F5B0` (`PlasmaBall2+8`); `$F5DC` (`SideShot+8`) |
| Writes | `$F5B0`-`$F5BB` (`PlasmaBall2+8`); `$F5CE`-`$F5E7` (`PlasmaBall2+38`, `SideShot`); `$F5FA` (`SideShot+38`) |

### `PlaceAtPlayer` (`$9CB0`)

**the object IX two columns ahead of the ship, one row down**

Copies the ship's X (+2 columns) and Y (+1 row) from `$F36F`. Used by PlasmaFrame, HomingFrame, SeekerFrame. Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 42 calls, 6,514 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 153 t-states own (0.00 %) |
| Called from | `PlasmaFrame`, `HomingFrame`, `SeekerFrame` |
| Reads | `$F36F`-`$F372` (`PlayerObject+3`) |
| Writes | `$F5AB`-`$F5AE` (`PlasmaBall2+3`); `$F5D7`-`$F5DA` (`SideShot+3`) |

### `HomingFrame` (`$9CCA`)

**side weapon 3: a homing missile at the locked target**

Fire held, `$F5D4` free and a lock (`$80E2` not 0): active, the target +`$29` = (`$80E0`), colour `$38`, direction 0 (ahead), life +`$26` = `$4B` (75 frames), the turn interval 1. Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 36,473 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 229,690 t-states own (0.04 %) |
| Called from | `JumpTable` |
| Calls | `PlaceAtPlayer` |
| Reads | `$80E0`-`$80E2` (`LockTarget`, `LockMask`); `$8184` (`FireHeld`); `$F5DC` (`SideShot+8`) |
| Writes | `$F5DC`-`$F5FE` (`SideShot+8`) |

### `SeekerFrame` (`$9CFE`)

**side weapon 4: the seeker after 7 frames of fire**

Fire held exactly 7 frames and the weapon still 4: a new seeker at the ship flying ahead (direction 0, the speed +`$17`); an active one with +`$26` = 0 is re-armed. +`$26` = 1 and the target = the first enemy slot `$F398`: SeekerHandler hunts from there. Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 39,560 t-states own (0.01 %) |
| Called from | `JumpTable` |
| Calls | `SetVelocity`, `PlaceAtPlayer` |
| Reads | `$7F99`-`$7FA4` (`PlayerRecord`, `Players`, `Player1`); `$8184` (`FireHeld`); `$F5DC`-`$F5FC` (`SideShot+8`) |
| Writes | `$F5DC`-`$F5FE` (`SideShot+8`) |

### `PodSpeedUp` (`$9D4C`)

**pod 0: fuel `$BB` and the speed one step up, to `$A0`**

Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 87 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Reads | `$7FA7` (`Player1Speed`) |
| Writes | `$7FA7` (`Player1Speed`); `$80E6` (`Fuel`) |

### `PodLaser` (`$9D5D`)

**pod 1: the laser one level up, to 3**

Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 64 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Reads | `$7FA6` (`Player1LaserLevel`) |
| Writes | `$7FA6` (`Player1LaserLevel`) |

### `PodPlasma` (`$9D68`)

**pod 2: plasma (a second plasma pod: double)**

+`$09` = 1 when the weapon is already plasma; +`$08` = 2; the sight `$F600` off; both slots `$F5D4` and `$F5A8` set up as plasma balls (ResetPlasmaBall). Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 268 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ResetPlasmaBall` |
| Reads | `$7FA4` (`Player1SideWeapon`); `$F608` (`SightObject+8`) |
| Writes | `$7FA4`-`$7FA5` (`Player1SideWeapon`, `Player1DoublePlasma`); `$F608` (`SightObject+8`) |

### `ResetPlasmaBall` (`$9D87`)

**the slot IX as an idle plasma ball**

Inactive, kind 9, Vx = `$40`, the X acceleration 0, the Y acceleration `$10` (its gravity). Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 4 calls, 689 t-states own (0.00 %) |
| Called from | `PodPlasma` |
| Reads | `$F5B0` (`PlasmaBall2+8`); `$F5DC` (`SideShot+8`) |
| Writes | `$F5AF`-`$F5BD` (`PlasmaBall2+7`); `$F5DB`-`$F5E9` (`SideShot+7`) |

### `PodHoming` (`$9DA5`)

**pod 3: homing missiles and the sight**

+`$08` = 3, no double, the slot `$F5A8` off; `$F5D4` idle as kind 10 with speed 4, the turn interval 1 and the turn rate 2; the sight `$F600` on (PlaceSight); no lock (`$80E0` = 0, `$80E2` = 0). Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 283 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 271 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PlaceSight` |
| Reads | `$F5B0` (`PlasmaBall2+8`); `$F5DC` (`SideShot+8`); `$F608` (`SightObject+8`) |
| Writes | `$7FA4`-`$7FA5` (`Player1SideWeapon`, `Player1DoublePlasma`); `$80E0`-`$80E2` (`LockTarget`, `LockMask`); `$F5B0` (`PlasmaBall2+8`); `$F5DB`-`$F5EB` (`SideShot+7`); `$F5FC`-`$F608` (`SideShot+40`, `SightObject`) |

### `PodSeeker` (`$9DDD`)

**pod 4: the seeker**

The sight off, +`$08` = 4, no double; `$F5D4` idle as kind 7, speed 4, the turn interval 1, the turn rate 2. The second plasma slot `$F5A8` is not cleared here (PodHoming does it). Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 194 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Reads | `$F5DC` (`SideShot+8`); `$F608` (`SightObject+8`) |
| Writes | `$7FA4`-`$7FA5` (`Player1SideWeapon`, `Player1DoublePlasma`); `$F5DB`-`$F5EB` (`SideShot+7`); `$F5FC`-`$F608` (`SideShot+40`, `SightObject`) |

### `SightHandler` (`$9E03`)

**kind 6: the homing sight ahead of the ship**

Colour `$78` without a lock, `$70` with one; its overlap mask +`$0D` into `$80E4` (the lockable enemies test it); then PlaceSight. Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 42,282 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 245,669 t-states own (0.05 %) |
| Called from | `JumpTable` |
| Calls | `PlaceSight` |
| Reads | `$80E2` (`LockMask`); `$F60D` (`SightObject+13`) |
| Writes | `$80E4` (`SightMask`); `$F625` (`SightObject+37`) |

### `PlaceSight` (`$9E16`)

**the sight at the ship's position of the history ring, 10 columns ahead**

The entry of the ring `$80C0` at the index `$80BF` (the oldest one: the sight lags the ship by 8 moves) into `$F603-$F606`, X + 10 columns.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 487 calls, 75,655 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,824 calls, 438,587 t-states own (0.08 %) |
| Called from | `PodHoming`, `SightHandler` |
| Reads | `$80BF`-`$80DF` (`ShipHistoryIndex`, `ShipHistory`) |
| Writes | `$F603`-`$F606` (`SightObject+3`) |

### `LaserHandler` (`$9E32`)

**kind 1: a laser shot**

Gone on an enemy in its overlap mask (the harmless enemies of `$80BD`/`$80BE` and bits 5-7 excepted) or scenery (SceneryAt2), and at column 48: `$80BA` + 1 (the shot back). Else X + `$140`/256 (1.25 columns) a frame. 882 executions in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 201,636 t-states own (0.19 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 8,689,155 t-states own (0.17 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 1,261,785 t-states own (0.30 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 874,992 t-states own (0.16 %) |
| Called from | `JumpTable` |
| Calls | `SceneryAt2` |
| Reads | `$80BA`-`$80BE` (`LaserShotsFree`, `LaserHitMask`, `ColourCycle`, `HarmlessMaskA` and 1 more); `$F4FB`-`$F505` (`LaserShots+3`); `$F527`-`$F531` (`LaserShots+47`); `$F553`-`$F55D` (`LaserShots+91`) |
| Writes | `$80BA` (`LaserShotsFree`); `$F4FB`-`$F500` (`LaserShots+3`); `$F527`-`$F52C` (`LaserShots+47`); `$F553`-`$F558` (`LaserShots+91`) |

### `PlasmaHandler` (`$9E67`)

**kind 9: a plasma ball, falling and bouncing**

Flashes every second frame; its mask into `$80E5` (a kill for any enemy it overlaps). Gone at column 48, below row 16 or after its bounces (+`$26`, 3). Each frame Vy + the gravity; a landing on scenery (SceneryAt1): sound effect 3, Vy = -Vy / 2, a bounce counted; still in the scenery after the bounce: gone. Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 367,974 t-states own (0.09 %) |
| Called from | `JumpTable` |
| Calls | `PathOpAccelerate`, `SceneryAt1`, `CycleColour`, `RequestEffect` |
| Reads | `$7F62` (`PassCount`); `$80E5` (`PlasmaHitMask`); `$F5AC`-`$F5BB` (`PlasmaBall2+4`); `$F5CE`-`$F5E7` (`PlasmaBall2+38`, `SideShot`); `$F5FA` (`SideShot+38`) |
| Writes | `$80E5` (`PlasmaHitMask`); `$F5AD`-`$F5BB` (`PlasmaBall2+5`); `$F5CE`-`$F5E7` (`PlasmaBall2+38`, `SideShot`); `$F5FA` (`SideShot+38`) |

### `MissileHandler` (`$9ED7`)

**kind 10: the homing missile**

Life +`$26` - 1, flashing. No lock: it burns out (MissileFade). Its mask into `$80E3`; overlapping the locked enemy (`$80E2`): gone (the enemy handler sees the hit in `$80E3`). Else PathOpHome on the target, ClampRow, gone outside columns 16-47. Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 7,904 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `PathOpHome`, `ClampRow`, `CycleColour` |
| Reads | `$80E2` (`LockMask`); `$F5D8`-`$F5E1` (`SideShot+4`); `$F5F9`-`$F5FA` (`SideShot+37`) |
| Writes | `$80E3` (`MissileHitMask`); `$F5DC` (`SideShot+8`); `$F5F9`-`$F5FA` (`SideShot+37`) |

### `SeekerHandler` (`$9F13`)

**kind 7: the seeker, killing enemy after enemy**

Flashes. A target (+`$29`) that is active and of kind 2: PathOpHome on it, its mask into `$80E5` (a kill), ClampRow, gone on scenery or outside columns 16-47. A lost target with +`$26` not 0: the next active kind-2 slot after +`$26` (up to 5) becomes the target, none: the player, +`$26` = 0 (it comes home). The kind test is written twice (CP `$02` ... CP `$02`): the second was probably meant for another kind (11 shares the handler of 2). Not run in c1/c2.

| | |
| --- | --- |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 45,886 t-states own (0.01 %) |
| Called from | `JumpTable` |
| Calls | `PathOpHome`, `SceneryAt1`, `ClampRow`, `CycleColour` |
| Reads | `$80E5` (`PlasmaHitMask`); `$F373`-`$F374` (`PlayerObject+7`); `$F39F`-`$F3A0` (`EnemyObjects+7`); `$F3CB`-`$F3CC` (`EnemyObjects+51`); `$F3F8` (`EnemyObjects+96`); `$F424` (`EnemyObjects+140`); 3 more ranges |
| Writes | `$80E5` (`PlasmaHitMask`); `$F5DC` (`SideShot+8`); `$F5FA`-`$F5FE` (`SideShot+38`) |

## enemies

`src/game/enemies.asm`

### `EnemyHandler` (`$9F88`)

**kinds 2 and 11: a common enemy**

1412 executions in c2.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 305,329 t-states own (0.29 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 18,787,283 t-states own (0.36 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 594,576 t-states own (0.14 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 1,106,513 t-states own (0.21 %) |
| Called from | `JumpTable` |
| Calls | `RunPath`, `FreeEnemySlot`, `EnemyEscaped`, `EnemyKilled`, `ClampRow`, `EnemyFire`, `StartExplosion`, `AddScore` |
| Reads | `$80BB` (`LaserHitMask`); `$80E5` (`PlasmaHitMask`); `$F39C`-`$F3A5` (`EnemyObjects+4`); `$F3BC`-`$F3D1` (`EnemyObjects+36`); `$F3E8`-`$F3FD` (`EnemyObjects+80`); `$F414`-`$F429` (`EnemyObjects+124`); 2 more ranges |
| Writes | `$F3A5` (`EnemyObjects+13`); `$F3D1` (`EnemyObjects+57`); `$F3FD` (`EnemyObjects+101`); `$F429` (`EnemyObjects+145`); `$F455` (`EnemyObjects+189`) |

### `LockableHandler` (`$9FC8`)

**kind 8: an enemy the homing sight can lock**

As EnemyHandler without the plasma kill; with no lock (`$80E2` = 0) and its bit in the sight's mask `$80E4` it becomes the lock (`$80E0` = IY, `$80E2` = its bit) and flashes (`$7F79` x 8 + `$40`). The locked one dies of a missile hit (`$80E3`); lasers take hit points. Leaving play clears its lock bit. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 947,997 t-states own (0.02 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 43,939 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 27,386 t-states own (0.01 %) |
| Called from | `JumpTable` |
| Calls | `RunPath`, `FreeEnemySlot`, `EnemyEscaped`, `EnemyKilled`, `ClampRow`, `EnemyFire`, `StartExplosion`, `AddScore` |
| Reads | `$7F79` (`SpinnerColour`); `$80BB` (`LaserHitMask`); `$80E2`-`$80E4` (`LockMask`, `MissileHitMask`, `SightMask`); `$F39C`-`$F3A5` (`EnemyObjects+4`); `$F3BC`-`$F3D1` (`EnemyObjects+36`); `$F3E8`-`$F3FD` (`EnemyObjects+80`); 3 more ranges |
| Writes | `$80E0`-`$80E2` (`LockTarget`, `LockMask`); `$F3A5` (`EnemyObjects+13`); `$F3BD` (`EnemyObjects+37`); `$F3D1` (`EnemyObjects+57`); `$F3FD` (`EnemyObjects+101`); `$F429` (`EnemyObjects+145`); 1 more ranges |

### `BigEnemyHandler` (`$A03E`)

**kind 12: the big (boss) enemy**

Columns 7-55. Its row mask +`$0B` = `$FE` shifted left once per row below row 11 (its lower rows out of the collision grid near the floor). Lockable as kind 8; a missile hit takes 4 hit points and the lock, a laser hit one with a colour flash. Every hit sets the sound pointers `$7F80` = `$FD00`, `$7F84` = `$EDB2`, `$7F88` = `$D6ED` (the hit noise). Below 0 hit points: EnemyKilled, X + 2, ScatterDebris (the debris of a big explosion) and the score. Not run in c1/c2; r1 (all levels) runs it.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,504,025 t-states own (0.03 %) |
| Called from | `JumpTable` |
| Calls | `RunPath`, `EnemyKilled`, `ClampRow`, `CycleColour`, `ScatterDebris`, `EnemyFire`, `AddScore` |
| Reads | `$80BB` (`LaserHitMask`); `$80E2`-`$80E4` (`LockMask`, `MissileHitMask`, `SightMask`); `$F39C`-`$F3A5` (`EnemyObjects+4`); `$F3BC` (`EnemyObjects+36`) |
| Writes | `$7F80`-`$7F89` (`SoundPattern1`, `ObjectBeep`, `ObjectBeepMask`, `SoundPattern2` and 3 more); `$80E2` (`LockMask`); `$F39C`-`$F3A5` (`EnemyObjects+4`) |

## objects

`src/game/objects.asm`

### `EnemyFire` (`$A0EB`)

**Let the enemy at IY fire a shot**

IY: an enemy record. An enemy fires when its fire rate +`$18` is not zero and either it has not fired yet (+8 bit 6 clear) and stands in the trigger column `$80E7`, or in a pass its bit +`$24` selects (`$7F63` PassBit) a random number (Random `$8544`) less `$80E8` is below the rate.

A shot costs one of the shots left in `$8074` (none left: no shot) and takes the first free of the three shot records at `$F474` (44 bytes each, +8 bit 7 the busy flag). It starts at the enemy's position + `$0180` (1.5 cells right and down, Y clamped to row 15), takes its speed from +`$19` (bits 0-2 the step, bits 3-7 the speed index), its colour from +`$20`, its lifetime from +`$22` and its direction from +`$21`:

+`$21` bits 0-1 = 00: the fixed direction in bits 2-7; 10: a random direction (`$7F71` & `$3F`); x1: aimed at the player (DirectionTo `$989F` from the shot to the player record `$F36C`), with bit 1 set spread by -4..+3 (`$7F71` & 7 - 4). The direction (0-63) goes to +`$16`, SetVelocity `$98F1` turns it into the velocity, sound 1 (StartSound `$B2F0`) plays, the enemy's +8 bit 6 records the shot.

Callers: the enemy movers at `$9FA2`, `$9FEB` and `$A06E` (EnemyHandler). Evidence: c2 L1 entries at `$A0EB` during waves with firing enemies; the record layout read off the stores below.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1,405 calls, 215,050 t-states own (0.21 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 98,490 calls, 10,653,700 t-states own (0.20 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,836 calls, 428,675 t-states own (0.10 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 5,855 calls, 653,160 t-states own (0.12 %) |
| Called from | `EnemyHandler`, `LockableHandler`, `BigEnemyHandler` |
| Calls | `Random`, `DirectionTo`, `SetVelocity`, `RequestEffect` |
| Reads | `$7F63`-`$7F71` (`PassBit`, `PassDepth`, `PassPhase`, `ChainStep` and 8 more); `$8074` (`EnemyShotsLeft`); `$80E7`-`$80E8` (`WeaponRatingMask`, `WeaponRatingValue`); `$F39B`-`$F48B` (`EnemyObjects+3`, `EnemyShots`); `$F4A8`-`$F4B7` (`EnemyShots+52`); `$F4D4`-`$F4E3` (`EnemyShots+96`) |
| Writes | `$8074` (`EnemyShotsLeft`); `$F3A0` (`EnemyObjects+8`); `$F3CC` (`EnemyObjects+52`); `$F3F8` (`EnemyObjects+96`); `$F424` (`EnemyObjects+140`); `$F450` (`EnemyObjects+184`); 1 more ranges |

### `ExplosionStep` (`$A1C8`)

**Advance an explosion (object kind 3)**

IY: the explosion. Runs in odd passes only (`$7F62` bit 0). +`$27` counts down the passes a frame is held: while it lasts the colour +`$25` is 0 (the frame is drawn black, a flash); when it runs out the animation frame +2 advances.

After frame 8 the explosion ends: removed (RemoveObject `$992A`) when +`$26` is 0, otherwise it leaves a weapon pod (ExplosionToPod). Handler pointer at `$8100`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 32,812 t-states own (0.03 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,319,791 t-states own (0.03 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 141,482 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 138,474 t-states own (0.03 %) |
| Called from | `JumpTable` |
| Calls | `FreeEnemySlot` (tail), `ExplosionToPod` (tail) |
| Reads | `$7F62` (`PassCount`); `$F39A` (`EnemyObjects+2`); `$F3BD`-`$F3C6` (`EnemyObjects+37`); `$F3E9`-`$F3F2` (`EnemyObjects+81`); `$F415`-`$F41E` (`EnemyObjects+125`); `$F441`-`$F44A` (`EnemyObjects+169`); 1 more ranges |
| Writes | `$F39A` (`EnemyObjects+2`); `$F3BD`-`$F3C6` (`EnemyObjects+37`); `$F3E9`-`$F3F2` (`EnemyObjects+81`); `$F415`-`$F41E` (`EnemyObjects+125`); `$F441`-`$F44A` (`EnemyObjects+169`); `$F46D`-`$F46F` (`EnemyObjects+213`) |

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

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 22,659 t-states own (0.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,456,894 t-states own (0.03 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 335,353 t-states own (0.08 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 317,697 t-states own (0.06 %) |
| Called from | `JumpTable` |
| Calls | `JumpTable`, `PathOpScroll`, `FreeEnemySlot`, `AddScore`, `RequestEffect` |
| Reads | `$7F99`-`$7FA3` (`PlayerRecord`, `Players`, `Player1`); `$80BC` (`ColourCycle`); `$80E6` (`Fuel`); `$8184` (`FireHeld`); `$81C5` (`EventRequests`); `$F379` (`PlayerHitMask`); 6 more ranges |
| Writes | `$7FA3` (`Player1PodSelector`); `$80E6` (`Fuel`); `$81C5` (`EventRequests`); `$F3BD` (`EnemyObjects+37`); `$F3E9` (`EnemyObjects+81`); `$F415` (`EnemyObjects+125`); 2 more ranges |

### `EnemyShotStep` (`$A263`)

**Move an enemy shot (object kind 5)**

IY: the shot. It ends (FreeShot `$9941`) when its lifetime +`$26` runs out, when it hits the player (`$F379` AND +`$24`), when the playfield collision test `$99A9` reports carry, or when after the move (MoveObject `$96E2`) its Y is outside rows 0-16 or its X is outside columns 16-48 (the visible window). Handler pointer at `$8104`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 4,139 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 2,238,080 t-states own (0.04 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 384,065 t-states own (0.09 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 301,424 t-states own (0.06 %) |
| Called from | `JumpTable` |
| Calls | `PathOpHome`, `FreeObject`, `SceneryAt1` |
| Reads | `$F379` (`PlayerHitMask`); `$F478`-`$F47A` (`EnemyShots+4`); `$F498`-`$F4A6` (`EnemyShots+36`); `$F4C4`-`$F4D2` (`EnemyShots+80`); `$F4F0`-`$F4F2` (`EnemyShots+124`) |
| Writes | `$F49A` (`EnemyShots+38`); `$F4C6` (`EnemyShots+82`); `$F4F2` (`EnemyShots+126`) |

### `StartExplosion` (`$A293`)

**Turn the object at IY into an explosion**

Sets the three sound bit patterns (`$7F80` = `$FD00`, `$7F84` = `$EDB2`, `$7F88` = `$D6ED`, shifted one bit a pass by PlayInterrupt: the explosion noise), kind 3, the animation record `$7EA1` from frame 1, +`$0B` = `$E0`, +`$27` = 0, colour `$70` and X fraction 0. The object's bit +`$24` leaves the mask `$80BD` and joins `$80BE` (from the shootable to the harmless objects).

Callers: the hit handling at ScatterDebris and the enemy movers (EnemyHandler).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 19 calls, 6,600 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 809 calls, 275,451 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 86 calls, 29,829 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 84 calls, 29,063 t-states own (0.01 %) |
| Called from | `ScatterDebris`, `EnemyHandler`, `LockableHandler` |
| Reads | `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F3BC` (`EnemyObjects+36`); `$F3E8` (`EnemyObjects+80`); `$F414` (`EnemyObjects+124`); `$F440` (`EnemyObjects+168`); `$F46C` (`EnemyObjects+212`) |
| Writes | `$7F80`-`$7F89` (`SoundPattern1`, `ObjectBeep`, `ObjectBeepMask`, `SoundPattern2` and 3 more); `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F398`-`$F3A3` (`EnemyObjects`); `$F3BD`-`$F3CF` (`EnemyObjects+37`); `$F3E9`-`$F3FB` (`EnemyObjects+81`); `$F415`-`$F427` (`EnemyObjects+125`); 2 more ranges |

### `ExplosionToPod` (`$A2D6`)

**Turn the finished explosion at IY into a weapon pod**

Rounds the Y to the nearest cell (+5 bit 7 carries into +6), then asks `$99BB` whether the cell is free (carry: no room, the object is removed). Otherwise: +`$0B` = `$C0`, kind 4, +`$26` down by 2, the pod animation `$7EBB` (both branches of the JR Z load the same record), the bit +`$24` back from `$80BE` to `$80BD`, colour 8, sound 4.

Used by ExplosionStep.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 772 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 239 calls, 85,737 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 29 calls, 10,253 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 28 calls, 10,807 t-states own (0.00 %) |
| Called from | `ExplosionStep` (tail) |
| Calls | `FreeEnemySlot` (tail), `SceneryAt4`, `RequestEffect` |
| Reads | `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F39D`-`$F39E` (`EnemyObjects+5`); `$F3BC`-`$F3CA` (`EnemyObjects+36`); `$F3E8`-`$F3F6` (`EnemyObjects+80`); `$F414`-`$F422` (`EnemyObjects+124`); `$F440`-`$F44E` (`EnemyObjects+168`); 1 more ranges |
| Writes | `$80BD`-`$80BE` (`HarmlessMaskA`, `HarmlessMaskB`); `$F398`-`$F3A3` (`EnemyObjects`); `$F3BD`-`$F3CF` (`EnemyObjects+37`); `$F3E9`-`$F3FB` (`EnemyObjects+81`); `$F415`-`$F427` (`EnemyObjects+125`); `$F441`-`$F453` (`EnemyObjects+169`); 1 more ranges |

## print

`src/game/print.asm`

### `PrintChar` (`$A321`)

**Print a character or take a print code**

A: a byte. When a code is pending (`$80AD` below `$20`) A is its operand and the code's routine from PrintControlTable runs (codes 7-`$1F` do nothing), then the pending mark goes back to `$20`.

Otherwise a byte below `$20` becomes the pending code; a byte from `$20` is printed at the print position `$80AA` with the attribute `$80AC`, the position moves one cell right. All registers are kept.

Callers: PrintString, PrintBcd, PrintKeyName, HighScoreEntry.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 122 calls, 84,490 t-states own (0.08 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7,774 calls, 110,266 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 848 calls, 616,985 t-states own (0.15 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 842 calls, 608,634 t-states own (0.11 %) |
| Runs (the other recordings) | 1,566 calls (`c1` 1,566) |
| Called from | `PrintString`, `PrintBcd`, `PrintBcdLeading`, `PrintBcdOut` |
| Calls | `PrintCharSave`, `PrintSetAttr`, `PrintSetColumn`, `PrintSetRow`, `PrintColumnRight`, `PrintRowDown` |
| Reads | `$80AA`-`$80AD` (`PrintPos`, `PrintAttr`, `PrintPending`); `$A3A9`-`$A3AC` (`PrintControlTable+6`) |
| Writes | `$4002`-`$401D` (screen); `$4102`-`$411D` (screen); `$4202`-`$461D` (screen); `$4702`-`$471D` (screen); `$4827`-`$4838` (screen); `$486C`-`$4873` (screen); 12 more ranges |

### `PrintCharSave` (`$A322`)

**PrintCharSave**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7,775 calls, 605,189 t-states own (0.01 %) |
| Called from | `PrintChar`, `PlayInterruptExit` |
| Calls | `PrintCharTest`, `PrintSetColumn`, `PrintSetRow` |
| Reads | `$80AD` (`PrintPending`); `$A3A9`-`$A3AC` (`PrintControlTable+6`); `$FEFF`-`$FF00` (`VectorTable+255`) |

### `PrintCharTest` (`$A32E`)

**PrintCharTest**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7,731 calls, 54,129 t-states own (0.00 %) |
| Called from | `PrintCharSave`, `PlayInterruptExit` |
| Calls | `PrintCharKind` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `PrintCharKind` (`$A330`)

**PrintCharKind**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7,731 calls, 998,127 t-states own (0.02 %) |
| Called from | `PrintCharTest`, `PlayInterruptExit` |
| Calls | `PrintCharGlyph`, `PrintCharDone` (tail) |
| Reads | `$80AA`-`$80AC` (`PrintPos`, `PrintAttr`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$5802`-`$581D` (screen); `$5927`-`$5938` (screen); `$596C`-`$5973` (screen); `$80AA`-`$80AB` (`PrintPos`) |

### `PrintCharGlyph` (`$A34D`)

**PrintCharGlyph**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7,688 calls, 276,715 t-states own (0.01 %) |
| Called from | `PrintCharKind`, `PlayInterruptExit` |
| Calls | `PrintRomGlyph` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `PrintRomGlyph` (`$A357`)

**PrintRomGlyph**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7,687 calls, 576,364 t-states own (0.01 %) |
| Called from | `PrintCharGlyph`, `PlayInterruptExit` |
| Calls | `PrintCharRow` |
| Writes | `$4002`-`$401D` (screen); `$4102`-`$411D` (screen); `$4827`-`$4838` (screen); `$486C`-`$4873` (screen); `$4927`-`$4938` (screen); `$496C`-`$4973` (screen) |

### `PrintCharRow` (`$A365`)

**PrintCharRow**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 46,116 calls, 184,483 t-states own (0.00 %) |
| Called from | `PrintRomGlyph`, `PrintCharBold` (tail) |
| Calls | `PrintCharBold` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `PrintCharBold` (`$A366`)

**PrintCharBold**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 46,117 calls, 2,184,763 t-states own (0.04 %) |
| Called from | `PrintCharRow`, `PlayInterruptExit` |
| Calls | `PrintCharRow` (tail), `PrintCharDone` |
| Writes | `$4202`-`$461D` (screen); `$4702`-`$471D` (screen); `$4A27`-`$4A73` (screen); `$4B27`-`$4B73` (screen); `$4C27`-`$4C73` (screen); `$4D27`-`$4D73` (screen); 2 more ranges |

### `PrintCharDone` (`$A36E`)

**PrintCharDone**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7,730 calls, 646,051 t-states own (0.01 %) |
| Called from | `PrintCharKind` (tail), `PrintCharBold` |
| Calls | `PrintBcdLeadNext`, `PrintBcdRestNext` |
| Writes | `$80AD` (`PrintPending`) |

### `PrintCodeDone` (`$A399`)

**End a print code: nothing pending**

The return of every print code routine (pushed by PrintChar): `$80AD` = `$20`, the registers PrintChar saved restored.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 4 calls, 371 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 44 calls, 4,081 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 4 calls, 371 t-states own (0.00 %) |
| Runs (the other recordings) | 404 calls (`c1` 404) |
| Called from | `PrintSetAttr`, `PrintSetColumn`, `PrintSetRow`, `PrintColumnRight` |
| Writes | `$80AD` (`PrintPending`) |

### `PrintSetAttr` (`$A3B1`)

**Print code 0: the attribute**

C: the attribute byte for the next characters (`$80AC`).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings run into, not called (`c1`) |
| Called from | `PrintChar` |
| Calls | `PrintCodeDone` |

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
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 98 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,078 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 98 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`c1`) |
| Called from | `PrintChar`, `PrintCharSave` |
| Calls | `PrintCodeDone` |
| Reads | `$80AA` (`PrintPos`) |
| Writes | `$80AA` (`PrintPos`) |

### `PrintSetRow` (`$A3D6`)

**Print code 4: the row**

C: the row 0-23: the print position's high byte `$58` + C / 8, bits 5-7 of the low byte C AND 7; the column is kept. Also the end of PrintRowDown.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 206 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 2,266 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 206 t-states own (0.00 %) |
| Runs (the other recordings) | 132 calls (`c1` 132) |
| Called from | `PrintChar`, `PrintCharSave`, `PrintRowDown` (tail) |
| Calls | `PrintCodeDone` |
| Reads | `$80AA`-`$80AB` (`PrintPos`) |
| Writes | `$80AA`-`$80AB` (`PrintPos`) |

### `PrintColumnRight` (`$A3ED`)

**Print code 5: move the column**

C: the columns to add (a negative operand, `$FE`, moves left).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings run into, not called (`c1`) |
| Called from | `PrintChar` |
| Calls | `PrintCodeDone` |

### `PrintRowDown` (`$A3F4`)

**Print code 6: move the row**

C: the rows to add to the current row (the position's row from bits 5-9 of its offset).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings run into, not called (`c1`) |
| Called from | `PrintChar` |
| Calls | `PrintSetRow` (tail) |

### `PrintString` (`$A401`)

**Print a string**

HL: the string. Bytes go to PrintChar; `$FF` ends the string, `$1B` n prints message n (PrintMessage) and goes on. The byte after a print code is its operand, never taken as `$FF` or `$1B`. HL is kept.

Callers: PrintMessage and the title loop (HiScorePage).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 3,666 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 22 calls, 40,326 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 3,666 t-states own (0.00 %) |
| Runs (the other recordings) | 103 calls (`c1` 103) |
| Called from | `PrintMessage`, `HiScorePage` |
| Calls | `PrintChar`, `PrintMessage` |
| Reads | `$80AD` (`PrintPending`); `$84B2`-`$84D7` (`Messages+452`, `PlayerDigit`) |

### `PrintMessage` (`$A423`)

**Print message A**

A: the message number. The messages are the `$FF`-terminated strings from `$82EE` (after the `$FF` at `$82ED`); message n starts after the n+1-th `$FF` from `$82ED`. Registers kept.

Callers: PrintString, the menu screens (RedefineKeys, PrintKeyName, SelectPlayers, HighScoreEntry) and LevelStart, CreditsPage, HiScorePage. The list of the messages: work/stage1/texts.txt.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 20,152 t-states own (0.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 22 calls, 221,672 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 20,152 t-states own (0.00 %) |
| Runs (the other recordings) | 98 calls (`c1` 98) |
| Called from | `PrintString`, `LevelStart`, `CreditsPage`, `HiScorePage` |
| Calls | `PrintString` |
| Reads | `$82ED`-`$84BC` (`MessageListBase`, `Messages`); `$FEFF`-`$FF00` (`VectorTable+255`) |

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
| Runs (the first play recording: level 1 from the start, 1500 frames) | 11 calls, 13,079 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 925 calls, 181,913 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 106 calls, 123,437 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 101 calls, 117,400 t-states own (0.02 %) |
| Runs (the other recordings) | 9 calls (`c1` 9) |
| Called from | `PrintPlayerScore`, `CreditsPage`, `HiScorePage` |
| Calls | `PrintChar`, `PrintBcdLeading` |
| Reads | `$7F9C`-`$7F9F` (`Player1`); `$7FCC`-`$7FCF` (`Player2`); `$7FFC`-`$7FFF` (`BcdScratch`) |
| Writes | `$7FFC`-`$7FFF` (`BcdScratch`); `$80AC` (`PrintAttr`) |

### `PrintBcdLeading` (`$A452`)

**PrintBcdLeading**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 3,849 calls, 378,348 t-states own (0.01 %) |
| Called from | `PrintBcd`, `PrintBcdLeadNext` (tail) |
| Calls | `PrintChar`, `PrintBcdOut` (tail) |
| Reads | `$7FFC`-`$7FFF` (`BcdScratch`) |
| Writes | `$7FFC`-`$7FFF` (`BcdScratch`); `$80AC` (`PrintAttr`) |

### `PrintBcdLeadNext` (`$A46B`)

**PrintBcdLeadNext**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 3 calls, 50,115 t-states own (0.00 %) |
| Called from | `PrintCharDone` |
| Calls | `PrintBcdLeading` (tail), `PrintBcdRest` |
| Writes | `$80AC` (`PrintAttr`) |

### `PrintBcdRest` (`$A474`)

**PrintBcdRest**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 3,551 calls, 215,641 t-states own (0.00 %) |
| Called from | `PrintBcdLeadNext`, `PrintBcdRestNext` (tail) |
| Calls | `PrintBcdOut` |
| Reads | `$7FFD`-`$7FFF` (`BcdScratch+1`) |
| Writes | `$7FFD`-`$7FFF` (`BcdScratch+1`) |

### `PrintBcdOut` (`$A47E`)

**PrintBcdOut**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 4,465 calls, 107,937 t-states own (0.00 %) |
| Called from | `PrintBcdLeading` (tail), `PrintBcdRest` |
| Calls | `PrintChar` |

### `PrintBcdRestNext` (`$A482`)

**PrintBcdRestNext**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 4 calls, 122,074 t-states own (0.00 %) |
| Called from | `PrintCharDone` |
| Calls | `PrintBcdRest` (tail), `PrintPlayerScoreDone` |
| Reads | `$7FFF` (`BcdScratch+3`) |
| Writes | `$7FFF` (`BcdScratch+3`) |

## score

`src/game/score.asm`

### `AddScore` (`$A489`)

**Add award A to the current player's score**

A: the award number 0-11 of the points table `$8231` (4 BCD bytes each: 0, 25, 50, 75, 100, 150, 200, 250, 500, 1000, 2000, 5000). The award is added from the low byte up to the score of player `$7F98` (the low byte at `$7F9F` or `$7FCF`); bit 1 of `$81C5` asks for the panel score redraw.

Callers: the enemy kill (EnemyGone), the enemy movers (EnemyHandler), PodStep.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 9 calls, 2,964 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,003 calls, 324,270 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 113 calls, 37,622 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 111 calls, 36,710 t-states own (0.01 %) |
| Called from | `EnemyKilled`, `EnemyGone`, `EnemyHandler`, `LockableHandler`, `BigEnemyHandler`, `PodStep` |
| Reads | `$7F98`-`$7F9F` (`CurrentPlayer`, `PlayerRecord`, `Players`, `Player1`); `$81C5` (`EventRequests`); `$8235`-`$825C` (`PointsTable+4`) |
| Writes | `$7F9C`-`$7F9F` (`Player1`); `$81C5` (`EventRequests`) |

### `PrintPlayerScore` (`$A4AE`)

**Print player A's score on the panel**

A: the player, 1 or 2. Player 1's score at column 2, player 2's at column 22 of the top row; bright white (`$47`) for the player in play, dark cyan (`$05`) for the other, leading zeros as spaces. Callers: the panel drawing (ScoreJob) and the player change (RoundPlaySetup).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 11 calls, 2,065 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 925 calls, 151,690 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 106 calls, 19,943 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 101 calls, 18,949 t-states own (0.00 %) |
| Called from | `ScoreJob`, `RoundPlaySetup` |
| Calls | `PrintBcd` |
| Reads | `$7F98` (`CurrentPlayer`) |
| Writes | `$80AA`-`$80AC` (`PrintPos`, `PrintAttr`) |

### `PrintPlayerScoreDone` (`$A4D8`)

**PrintPlayerScoreDone**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7 calls, 22,295 t-states own (0.00 %) |
| Called from | `PrintBcdRestNext` |
| Calls | `ScoreJobRating` |

### `CompareScore` (`$A4DA`)

**Is the score at DE above the score at HL?**

DE, HL: 4 BCD bytes each. Carry set when DE's score is greater (equal scores: no carry). Registers kept. Used by HighScoreEntry.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawLives` (`$A4EF`)

**Draw the current player's lives on the panel**

Six life marks from the attribute `$5AD8` (row 22, column 24), the steps between them in `$81C0`: the first record+4 marks red on black (`$42`), the rest black. Callers: ScoreJob, RoundPlaySetup.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 552 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 16 calls, 8,304 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 1,085 t-states own (0.00 %) |
| Called from | `ScoreJob`, `ScoreJobRating`, `RoundPlaySetup` |
| Reads | `$7F99`-`$7FA0` (`PlayerRecord`, `Players`, `Player1`); `$81C0`-`$81C5` (`LifeSteps`, `EventRequests`) |
| Writes | `$5A98`-`$5A99` (screen); `$5AB8`-`$5AB9` (screen); `$5AD8`-`$5AD9` (screen) |

## menu

`src/game/menu.asm`

### `MenuRasterInterrupt` (`$A512`)

**Interrupt handler of the menu screens: a colour per scan line**

Saves every register and SP (into the LD SP at `$A575`), sets the border black, waits about 61 x 15 DJNZ for the beam, then for each of `$80B0` scan lines takes a colour from the table at (`$80AE`) and PUSHes it into 20 attribute cells ending at HL (HL steps a row of 32 every 8 lines: A' rotates a single bit). Both paths of a line take the same time. Then SP back, `$80B9` (frames left, counted by WaitMenuRasterEnd) down by one unless 0, EI.

Installed by SetMenuRaster in the interrupt handler pointer `$FDFE`. Evidence: c2 L1 has `$A512` in frames 690-765 (the selections screen), 26 permille of the frame time.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 76 calls, 2,720,324 t-states own (2.59 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 836 calls, 29,923,238 t-states own (0.57 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 76 calls, 2,720,312 t-states own (0.51 %) |
| Called from | `InterruptJump` (tail) |
| Reads | `$581A`-`$589A` (screen); `$58BA` (screen); `$58DA` (screen); `$58FA` (screen); `$591A` (screen); `$593A` (screen); 4 more ranges |
| Writes | `$80B9` (`RasterFrames`); `$A576`-`$A577` (`MenuRasterSavedSp+1`) |
| Ports out | `$00FE` |

### `SetMenuRaster` (`$A58D`)

**Install MenuRasterInterrupt as the interrupt handler**

Writes `$A512` to the handler pointer `$FDFE`, EI. Callers: MenuScreenSetup, SelectPlayers.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 40 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 440 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 40 t-states own (0.00 %) |
| Called from | `MenuScreenSetup` |
| Writes | `$FDFE`-`$FDFF` (`InterruptHandler`) |

### `WaitMenuRasterEnd` (`$A595`)

**Wait for the menu raster's frames to run out, then the title interrupt**

Waits (HALT) until `$80B9` is 0, clears the colour buffer, then installs TitleInterrupt (`$A9E4`) in `$FDFE`. Callers: RedefineKeys, SelectPlayers, HighScoreEntry, RoundPlaySetup.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 1,105,430 t-states own (1.05 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 20,024,954 t-states own (0.38 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 1,928,326 t-states own (0.36 %) |
| Called from | `RoundPlaySetup` |
| Calls | `ClearColourBuffer` |
| Reads | `$80B9` (`RasterFrames`); `$A596`-`$A5A0` (`WaitMenuRasterEnd+1`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$FDFE`-`$FDFF` (`InterruptHandler`) |

### `ClearColourBuffer` (`$A5A7`)

**Clear the raster colour buffer `$FC00-$FCFF`**

Callers: WaitMenuRasterEnd, MenuScreenSetup, SelectPlayers.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 11,824 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 22 calls, 130,064 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 11,824 t-states own (0.00 %) |
| Called from | `WaitMenuRasterEnd`, `MenuScreenSetup` |
| Writes | `$FC00`-`$FCFF` (`HitGridX`, `MenuColours`) |

### `ExpandNextColours` (`$A5B0`)

**Expand the colour list (`$80B1`) into the buffer at DE**

As ExpandColours with HL from `$80B1`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ExpandColours` (`$A5B3`)

**Expand a run-length colour list into the buffer**

HL: the list; DE: the destination; B: the bytes to write. A byte below `$80` is a colour, `$80`+n followed by a colour is n of that colour, `$FF` starts the list again (it repeats until B bytes are written). Returns DE past the bytes, HL at the list's start.

Callers: MenuScreenSetup, SelectPlayers, RedefineKeys (by ExpandNextColours).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 17,082 t-states own (0.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 22 calls, 187,902 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 17,082 t-states own (0.00 %) |
| Called from | `MenuScreenSetup` |
| Reads | `$82A7`-`$82D6` (`ColoursTop`, `ColoursMenu`) |
| Writes | `$FC20`-`$FCC7` (`MenuColours`) |

### `RedefineKeys` (`$A5D1`)

**The key definition screen (menu key 3)**

MenuScreenSetup, message 13 (KEYBOARD DEFINITION), then for each of the five keys of the key table `$8188` (fire, up, down, left, right; a half-row port high byte and a bit mask each): its prompt (messages 14-18), its current name, a new key (WaitKeyPress), the new name, 10 frames, the key stored; the line's 8 scan lines get the highlight colours (`$82D7` expanded into `$FC60` + 24 a key).

After the last key: 100 frames, WaitMenuRasterEnd, ClearScreen `$858B`. Used by MenuKeys.

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
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 202 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 2,205 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 202 t-states own (0.00 %) |
| Called from | `LevelStart` |
| Calls | `ClearScreen`, `SetMenuRaster`, `ClearColourBuffer`, `ExpandColours` |
| Writes | `$80AE`-`$80B0` (`RasterTable`, `RasterLines`) |

### `WaitFrames` (`$A6AE`)

**Wait A frames**

A: the frames (HALT A times, interrupts enabled). Callers: RedefineKeys, HighScoreEntry, EndOfPlay.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 3,838,981 t-states own (3.66 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 38,349,918 t-states own (0.73 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 3,486,390 t-states own (0.66 %) |
| Called from | `EndOfPlay` |
| Reads | `$A6B2` (`WaitFramesLoop+1`); `$FEFF`-`$FF00` (`VectorTable+255`) |

## input

`src/game/input.asm`

### `ReadControls` (`$A6B6`)

**Read the controls into `$8184-$8186`**

C collects the five keys of `$8188` (fire into bit 4, then up, down, left, right), ORed with the joystick bits. `$8184` counts the passes fire is held, `$8185` = `$FF` when fire was pressed or released since the last read, `$8186` the direction bits (fire removed). Registers kept.

Callers: the player mover (PlayerHandler) and HighScoreEntry. Evidence: the bits and counters seen in c2 while the bot plays.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 613 calls, 399,178 t-states own (0.38 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 23,808,021 t-states own (0.45 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 1,972,864 t-states own (0.47 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 2,457,093 t-states own (0.46 %) |
| Called from | `PlayerHandler` |
| Reads | `$8184`-`$8191` (`FireHeld`, `FireChanged`, `ControlBits`, `JoystickFlags` and 1 more) |
| Writes | `$8184`-`$8187` (`FireHeld`, `FireChanged`, `ControlBits`, `JoystickFlags`) |
| Ports in | `$011F`, `$7FFE`, `$DFFE`, `$FBFE`, `$FDFE` |

### `TitleFireCheck` (`$A748`)

**Is fire pressed on the title screen? Also picks the Kempston**

Carry set when the Kempston reads exactly fire (`$10`: then `$8187` bit 0 stays set and the game uses the Kempston), or, with the Kempston flag cleared, when the fire key (`$8188`) or 0 is down. Callers: HighScoreEntry and the title loop (CreditsPage, HiScorePage, Pause, TitleTune).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 875 calls (`c1` 875) |
| Called from | `CreditsPage`, `HiScorePage`, `TitleTune` |
| Ports in | `$001F`, `$081F`, `$0F1F`, `$DD1F`, `$DF1F`, `$E11F`, `$E31F`, `$E51F`, `$E71F`, `$E91F`, `$EB1F`, `$ED1F`, `$EF1F`, `$F11F`, `$F31F`, `$FF1F` |

## options

`src/game/options.asm`

### `MenuKeys` (`$A76F`)

**Read the menu keys 1-3**

1: SelectOnePlayer, 2: SelectTwoPlayers, 3: RedefineKeys. Registers kept. Used by the title loop (CreditsPage).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 1 call (`c1` 1) |
| Called from | `CreditsPage` |
| Ports in | `$F7FE` |

### `SelectOnePlayer` (`$A788`)

**Select the one player game**

A = 1, then as SelectTwoPlayers.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SelectTwoPlayers` (`$A78D`)

**Select the two player game**

SelectPlayers with A = 2.

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

| | |
| --- | --- |
| Runs | not reached in the recordings |

## panel

`src/game/panel.asm`

### `DrawSpinner` (`$A8BE`)

**Draw a 2x2 cell spinner frame**

HL: the attribute address of the top left cell; A: its attribute (four cells); C: the frame 0-15. The frame's offset from SpinnerFrames picks the shape in SpinnerImages: an even offset is the start of a shape read top down, an odd one the last byte of a shape read bottom up (the shape flipped upside down). Each row is drawn as the byte and its mirror (the bit-reverse table `$FB00`) side by side.

Callers: the panel update PanelFrame (`$AB97`, `$AB9F`).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1,318 calls, 2,058,285 t-states own (1.96 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 73,084 calls, 114,155,973 t-states own (2.18 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 5,984 calls, 9,353,332 t-states own (2.24 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 7,424 calls, 11,590,806 t-states own (2.18 %) |
| Called from | `PanelFrame` |
| Reads | `$A919`-`$A978` (`SpinnerFrames`, `SpinnerImages`); `$FB03`-`$FBC0` (`BitReverse+3`); `$FBE0` (`BitReverse+224`) |
| Writes | `$5081`-`$50BE` (screen); `$5181`-`$51BE` (screen); `$5281`-`$52BE` (screen); `$5381`-`$53BE` (screen); `$5481`-`$54BE` (screen); `$5581`-`$55BE` (screen); 5 more ranges |

### `RestorePanel` (`$A979`)

**Restore the bottom third and the panel attributes from `$E748`**

`$E748` -> `$5000` (2048 bytes) and `$EF48` -> `$5A60` (160 bytes, attribute rows 19-23). Called at `$B04F` (the player change, RoundPlaySetup).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 56,671 t-states own (0.05 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 623,381 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 56,671 t-states own (0.01 %) |
| Called from | `RoundPlaySetup` |
| Reads | `$E748`-`$EFE7` (`SpriteCacheImages`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$5000`-`$57FF` (screen); `$5A60`-`$5AFF` (screen) |

### `SavePanel` (`$A98D`)

**Save the bottom third and the panel attributes into `$E748`**

The reverse of RestorePanel. Called at `$B1F9`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 97,379 t-states own (0.09 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 532,107 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 48,374 t-states own (0.01 %) |
| Called from | `PlayLoopTest`, `PlayLoopBranch` |
| Reads | `$5000`-`$57FF` (screen); `$5A60`-`$5AFF` (screen); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$E748`-`$EFE7` (`SpriteCacheImages`) |

## interrupts

`src/game/interrupts.asm`

### `ScrollControl` (`$A9A1`)

**Start, stop and step the fine scroll**

At phase 4 when the restart flag `$81E3` is `$FF`: it becomes 0 and the scroll starts (`$81DA` bit 5). When `$7F7B` is not `$FF` the scroll stops (bit 5 cleared). Otherwise with the scroll on, or still between two cells (`$7F6A` not `$C0`), the fine scroll counter steps: `$7F6B` toggles `$08`/`$10` and `$7F6A` takes it by XOR, a 2-bit Gray code `$C0`, `$C8`, `$D8`, `$D0`; `$7F6C` = `$FF` says the pass scrolls (0: it does not).

Called by PlayPass. Evidence: TTD c2 frames 300-316: `$7F6A` C8, D8, D0, C0, `$7F6B` 08/10, `$7F6C` FF.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 659 calls, 130,431 t-states own (0.12 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 7,067,427 t-states own (0.13 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 555,976 t-states own (0.13 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 699,237 t-states own (0.13 %) |
| Called from | `PlayPass` |
| Reads | `$7F65`-`$7F7B` (`PassPhase`, `ChainStep`, `NodeFreeList`, `ShiftPage` and 12 more); `$81DA`-`$81E3` (`PlayFlags`, `ScrollCount`, `ScriptNumber`, `ScriptLevelBias` and 4 more) |
| Writes | `$7F6A`-`$7F6C` (`ShiftPage`, `FineScrollToggle`, `ScrollThisPass`); `$81DA` (`PlayFlags`) |

### `TitleInterrupt` (`$A9E4`)

**Interrupt handler of the title and between screens**

Only sets the interrupt flag `$7F96` = `$80`. Installed by WaitMenuRasterEnd and the game's screens (`$852D`, `$ABE6`, `$ABF8`, `$B18B`, `$B1F2`).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 106 calls, 5,830 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,089 calls, 59,895 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 99 calls, 5,445 t-states own (0.00 %) |
| Runs (the other recordings) | 577 calls (`c1` 577) |
| Called from | `InterruptJump` (tail) |
| Writes | `$7F96` (`EffectTick`) |

### `PlayInterrupt` (`$A9ED`)

**Interrupt handler in play: one phase of a game pass**

Saves all registers. Phase 4 (a pass whose chain has not ended): nothing more. Otherwise `$7F62` +1 (PassCount), `$7F63` rotated (PassBit, the object bit of this pass), `$7F64` +1 (depth), the phase `$7F65` +1; `$7F96` = `$FF`; the colour cycle `$80BC` 8, `$10`, `$18`; the three sound bit patterns `$7F80`, `$7F84`, `$7F88` shift one bit, the bit out into `$7F7F`, `$7F83`, `$7F87`.

Phase 1: `$8AED`, the chain from its start (`$7F66` = `$AAE5`), the three DI; RET restored, `$894D`, a wait of 2 (scroll on) or `$26` x 16 DJNZ. Phases 2-3: `$9150`, `$91C6`, a wait of 5. Then `$8894`, the panel update `$AB13`, a wait, the border black, `$85CA`, and PlayPass.

Installed at `$B1DF`. Evidence: c2 L1 659 entries, 12 permille own time.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 659 calls, 1,295,432 t-states own (1.23 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 83,050,319 t-states own (1.58 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 7,780,182 t-states own (1.86 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 9,318,851 t-states own (1.75 %) |
| Called from | `InterruptJump` (tail) |
| Calls | `DrawPlayfield`, `MoveStars`, `StartColumn`, `ScrollStep`, `TestHitGrid`, `ClearHitGrid`, `PanelFrame` |
| Reads | `$7F62`-`$7F65` (`PassCount`, `PassBit`, `PassDepth`, `PassPhase`); `$7F80`-`$7F89` (`SoundPattern1`, `ObjectBeep`, `ObjectBeepMask`, `SoundPattern2` and 3 more); `$80BC` (`ColourCycle`); `$81DA` (`PlayFlags`) |
| Writes | `$7F62`-`$7F67` (`PassCount`, `PassBit`, `PassDepth`, `PassPhase` and 1 more); `$7F7F`-`$7F96` (`RowBeepMask`, `SoundPattern1`, `ObjectBeep`, `ObjectBeepMask` and 11 more); `$80BC` (`ColourCycle`); `$AAED`-`$AAF8` (`ChainStep1End`, `ChainBuildColumn2`, `ChainBuildColumn3`) |
| Ports out | `$00FE` |

### `PlayPass` (`$AA96`)

**The play logic of a phase**

`$ABD5`, ScrollControl, `$9463`, `$8F9B`; in odd phases `$90CB`, in phase 2 `$AD66`; at depth 1 in phases 2-3 `$8D45`. Falls into PlayChain.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 644 calls, 144,544 t-states own (0.14 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,527 calls, 7,873,699 t-states own (0.15 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,977 calls, 645,401 t-states own (0.15 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,697 calls, 802,476 t-states own (0.15 %) |
| Called from | `RenderDone` |
| Calls | `ResumeScript`, `ObjectStrips`, `MarkEnemyGrid`, `RunObjects`, `ScrollControl`, `PlayChain`, `CheckPauseAndEnd`, `WaveScriptStep` |
| Reads | `$7F64`-`$7F65` (`PassDepth`, `PassPhase`) |

### `PlayChain` (`$AAC3`)

**Advance the drawing chain**

A wait, the border black, the chain step `$7F66` + 5. At depth 1 the step runs (RunChainStep) and returns to PlayInterruptExit; nested, the DI; RET before the step are replaced by two NOPs so the interrupted step continues into it.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 393 calls, 235,607 t-states own (0.22 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 19,761 calls, 12,957,520 t-states own (0.25 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1,673 calls, 1,052,068 t-states own (0.25 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2,044 calls, 1,304,733 t-states own (0.25 %) |
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
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 6,894 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 194,062 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 15,002 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 18,787 t-states own (0.00 %) |
| Called from | `PlayChain` |
| Calls | `BuildColumn`, `PlayInterruptExit` |

### `ChainStep1End` (`$AAED`)

**ChainStep1End**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 6 calls, 168,340 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1 call, 12,741 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 15,600 t-states own (0.00 %) |
| Called from | `BuildColumnBack`, `BuildColumnStep` |
| Calls | `ChainBuildColumn2`, `PlayInterruptExit` |

### `ChainBuildColumn2` (`$AAEF`)

**Chain step 2: build cells of the new column**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 6,855 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 6 calls, 366,226 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 1 call, 28,616 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 35,339 t-states own (0.01 %) |
| Called from | `PlayChain`, `ChainStep1End` |
| Calls | `BuildColumn`, `PlayInterruptExit` |

### `ChainBuildColumn3` (`$AAF4`)

**Chain step 3: build cells of the new column**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 6,626 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 366,758 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 28,142 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 35,071 t-states own (0.01 %) |
| Called from | `PlayChain` |
| Calls | `BuildColumn`, `PlayInterruptExit` |

### `ChainEnd` (`$AAF9`)

**The end of the chain: phase 0**

DI, `$7F65` = 0, so the next interrupt starts a new pass.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 5,818 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 315,052 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 25,202 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 31,243 t-states own (0.01 %) |
| Called from | `PlayChain` |
| Calls | `PlayInterruptExit` |
| Writes | `$7F65` (`PassPhase`) |

### `PlayInterruptExit` (`$AAFF`)

**Leave the play interrupt**

Depth `$7F64` down by one, all registers back, EI.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 649 calls, 122,141 t-states own (0.12 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,532 calls, 6,625,887 t-states own (0.13 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,981 calls, 517,189 t-states own (0.12 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,702 calls, 641,395 t-states own (0.12 %) |
| Called from | `PlayChain` (tail), `ChainBuildColumn1`, `ChainStep1End`, `ChainBuildColumn2`, `ChainBuildColumn3`, `ChainEnd` |
| Calls | `BuildColumnStep`, `BuildCell`, `GlyphShift2`, `GlyphShift4`, `GlyphMarkBits`, `GlyphBuilt`, `RotateSpriteRows`, `RotateLine`, `RotateLineSave`, `RotateLineCarry`, `RotateByte`, `RotateByteShift`, `RotateByteOut`, `RotateNextByte`, `RotateLineWrap`, `RotateLineMerge`, `RotateLineStore`, `RotateLineNext`, `RotateLineRestore`, `RotateLineCount`, `PrintCharSave`, `PrintCharTest`, `PrintCharKind`, `PrintCharGlyph`, `PrintRomGlyph`, `PrintCharBold`, `EventDispatch`, `EventPending`, `EventEnabled`, `EventAny`, `IconLine`, `SpriteBuildEmpty`, `SpriteShiftTest`, `SpriteShiftCopy`, `SpriteShiftLoop`, `PlayLoopPass`, `PlayLoopCheck`, `PlayLoopTest`, `PlayLoopBranch`, `PlayLoopAgain`, `EffectFirstLen`, `EffectPeriod`, `EffectHalves`, `EffectSpeakerOn`, `EffectHalf`, `EffectOut`, `EffectWait`, `EffectWait1`, `EffectWait2`, `EffectWait3`, `EffectSwap`, `EffectLow`, `EffectHalfNext`, `EffectHalfLoop`, `EffectTickCheck`, `EffectTickRead`, `EffectTickTest`, `EffectTickBranch`, `EffectRestore` |
| Reads | `$7F64` (`PassDepth`) |
| Writes | `$7F64` (`PassDepth`) |

## hud

`src/game/hud.asm`

### `PanelFrame` (`$AB13`)

**the panel's attribute work of one pass of play**

Called from PlayInterrupt `$A9ED` (at `$AA87`) once a pass; c2: 659 entries in 659 passes, 630704 T own (6 permille of the recording). Reads PassCount `$7F62`, the player record (`$7F99`: +`$0B` speed), Fuel `$80E6`, `$7F77-$7F7A`; writes only the attribute rows 20-23.

1. The ink of `$5AC6-$5AC7` + 1 every fourth pass (PassCount & 3 = 0), kept in 0-7 with the paper and bright bits (AND `$C7` drops the carry into paper).

2. The speed bar: `$5AEE-$5AF1` = `$01`, then (speed >> 5) - 1 cells of `$31` from `$5AEE`: one lit cell at `$40` up to four at `$A0`, the top speed (FuelOut keeps it from going below `$40`, which would make B = 0 and the DJNZ write 256 cells).

3. The fuel lamps: DE = `$3131` at `$5AC1` and `$5ADD`; Fuel < `$40` darkens D, < `$20` darkens E too.

4. The two colour blocks: PanelPhase `$7F78` + (PassCount & 1) in 0-15 (C), PanelBounce `$7F79` + PanelStep `$7F7A` on odd passes, the step reversed at 7 or 1 of the low 3 bits; `$A8BE` draws A at `$5A81` and `$5A9D` with C.

5. On even passes: rows 21-22 columns 11-20 (`$5AAB`, `$5ACB`) cleared; PanelBurst `$7F77` not 0: counted down, its new value n written as the attribute at columns 15+n and 16-n of both rows (the pair moves out as n falls and goes black at 0).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 659 calls, 630,704 t-states own (0.60 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 35,117,718 t-states own (0.67 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 2,898,791 t-states own (0.69 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 3,545,542 t-states own (0.67 %) |
| Called from | `PlayInterrupt` |
| Calls | `DrawSpinner` |
| Reads | `$5AC6`-`$5AC7` (screen); `$7F62` (`PassCount`); `$7F77`-`$7F7A` (`PanelBurst`, `SpinnerFrame`, `SpinnerColour`, `SpinnerColourStep`); `$7F99`-`$7FA7` (`PlayerRecord`, `Players`, `Player1`); `$80E6` (`Fuel`) |
| Writes | `$5AAB`-`$5AF1` (screen); `$7F77`-`$7F7A` (`PanelBurst`, `SpinnerFrame`, `SpinnerColour`, `SpinnerColourStep`) |

### `CheckPauseAndEnd` (`$ABD5`)

**key 4 pauses; a pending end code ends the play loop**

Called by the play interrupt once a pass (the phase dispatch in the routine at `$AA96`; c2: 659 entries in 659 passes). Key 4 (half row `$F7FE`, bit 3) calls Pause (`$B197`). Then a pending end code in EndPending (`$7F7C`: 1 a life lost, 2 the level done, 4 abort) is moved to EndCode (`$7F7D`), which ends the play loop at `$B1E9`, the interrupt handler (`$FDFE`) becomes TitleInterrupt `$A9E4` (it only sets `$7F96` = `$80`, no frame work) and StopAndSettle silences the effect. Returns with A = 0 when nothing is pending.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 659 calls, 42,852 t-states own (0.04 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 36,542 calls, 2,388,289 t-states own (0.05 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 2,992 calls, 200,922 t-states own (0.05 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,712 calls, 252,041 t-states own (0.05 %) |
| Called from | `PlayPass` |
| Calls | `StopAndSettle` |
| Reads | `$7F7C` (`EndPending`) |
| Writes | `$7F7D` (`EndCode`); `$FDFE`-`$FDFF` (`InterruptHandler`) |
| Ports in | `$F7FE` |

### `StopAndSettle` (`$ABF0`)

**silence the effect and let two frames pass under TitleInterrupt**

Requests effect 0 (RequestEffect `$B2F0` takes 0 as `$80`: the stop), keeps InterruptHandler (`$FDFE`), installs TitleInterrupt `$A9E4`, two HALTs with interrupts on, DI and Handler back. Called by CheckPauseAndEnd and Pause; c2: 2 entries (one pause and one end in the play recording).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 278,742 t-states own (0.27 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 933,558 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 85,003 t-states own (0.02 %) |
| Called from | `CheckPauseAndEnd` |
| Calls | `RequestEffect` |
| Reads | `$AC00`-`$AC01` (`StopAndSettle+16`); `$FDFE`-`$FDFF` (`InterruptHandler`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$FDFE`-`$FDFF` (`InterruptHandler`) |

## events

`src/game/events.asm`

### `EventDispatch` (`$AC07`)

**run the highest requested and enabled job; carry set when one ran**

In: EventRequests `$81C5`, EventMask `$81C6`. Out: NC (Z) when nothing was pending; carry after a handler ran. Clobbers AF, BC, DE, HL and what the handler uses. Callers: the play loop (`$B1E6`, c2: 68083 calls) and the effect player's tone loop (`$B376`, so a long effect does not stop the scheduler). The handler is jumped to through `$91E2` with the index of the bit (0 = bit 7), its bit cleared in EventRequests first.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 68,560 calls, 685,745 t-states own (0.65 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,924,873 calls, 29,259,036 t-states own (0.56 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 323,437 calls, 3,235,774 t-states own (0.77 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 669,671 calls, 6,698,996 t-states own (1.26 %) |
| Called from | `PlayInterruptExit`, `PlayLoopPass`, `EffectTickTest`, `EffectTickBranch` |
| Calls | `EventPending` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EventPending` (`$AC0A`)

**EventPending**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 68,552 calls, 891,421 t-states own (0.85 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,924,937 calls, 38,029,390 t-states own (0.73 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 323,464 calls, 4,205,978 t-states own (1.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 669,689 calls, 8,708,102 t-states own (1.64 %) |
| Called from | `PlayInterruptExit`, `EventDispatch` |
| Calls | `EventEnabled` |
| Reads | `$81C5` (`EventRequests`); `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EventEnabled` (`$AC0D`)

**EventEnabled**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 68,557 calls, 479,746 t-states own (0.46 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,924,872 calls, 20,467,383 t-states own (0.39 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 323,474 calls, 2,263,480 t-states own (0.54 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 669,728 calls, 4,686,318 t-states own (0.88 %) |
| Called from | `PlayInterruptExit`, `EventPending` |
| Calls | `EventAny` |
| Reads | `$81C6` (`EventMask`); `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EventAny` (`$AC0E`)

**EventAny**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 68,530 calls, 936,005 t-states own (0.89 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,923,881 calls, 40,855,638 t-states own (0.78 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 323,344 calls, 4,485,518 t-states own (1.07 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 669,462 calls, 9,255,619 t-states own (1.74 %) |
| Called from | `PlayInterruptExit`, `EventEnabled` |
| Calls | `JumpTable`, `PlayLoopCheck`, `EffectAfterJobs` |
| Reads | `$81C6` (`EventMask`) |
| Writes | `$81C5` (`EventRequests`) |

### `EventDone` (`$AC25`)

**EventDone**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 38 calls, 2,564 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,984 calls, 142,200 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 212 calls, 16,938 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 234 calls, 15,456 t-states own (0.00 %) |
| Called from | `IconLine`, `EffectJobDone`, `ScoreJobRating`, `SpriteBuildNext`, `SpriteBuildEmpty` |
| Calls | `PlayLoopCheck`, `EffectAfterJobs` |
| Writes | `$81C6` (`EventMask`) |

### `EventNone` (`$AC2B`)

**the handler of the unused bits 6-3: RET**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PodIconJob` (`$AC2C`)

**event bit 2: the pod selector's icon and its colours**

Allows only bit 7 meanwhile (EventMask AND `$80`). Attributes `$46` (bright yellow) at `$5A86-$5A87` and `$45` (bright cyan) at `$5AA6-$5AA7`; the 16 x 16 icon n = the player record's +7 (0-4, the selected pod) from PodIcons + 32 n drawn as two 2-cell rows at `$5086` and `$50A6` (screen third 2, rows 20-21, columns 6-7) by IconRow. c2: entries through `$91E2` (indirect); posted by the play loop's start (`$B1C7`) and by the pod pick-up (`$A243`).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 224 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 36,388 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 5,535 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 4,775 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `IconRow` |
| Reads | `$7F99`-`$7FA3` (`PlayerRecord`, `Players`, `Player1`); `$81C6` (`EventMask`) |
| Writes | `$5A86`-`$5A87` (screen); `$5AA6`-`$5AA7` (screen); `$81C6` (`EventMask`) |

### `IconLowerRow` (`$AC5A`)

**IconLowerRow**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1 call, 2,445 t-states own (0.00 %) |
| Called from | `IconLine` |
| Calls | `IconRow` |

### `IconRow` (`$AC5E`)

**two character cells of 8 lines from DE to the screen at HL**

In: DE the bytes (8 of the left cell, then 8 of the right), HL the screen address of the left cell. Out: DE past the 16 bytes, HL two cells right. Called twice by PodIconJob (the second time by falling in).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 1,380 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 326 calls, 2,282 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 46 calls, 33,647 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 40 calls, 29,262 t-states own (0.01 %) |
| Called from | `PodIconJob`, `IconLowerRow` |
| Calls | `IconCell` |
| Reads | `$B4AF`-`$B54E` (`PodIcons`) |
| Writes | `$5086`-`$50A7` (screen); `$5186`-`$51A7` (screen); `$5286`-`$52A7` (screen); `$5386`-`$53A7` (screen); `$5486`-`$54A7` (screen); `$5586`-`$55A7` (screen); 2 more ranges |

### `IconCell` (`$AC60`)

**IconCell**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 652 calls, 13,834 t-states own (0.00 %) |
| Called from | `IconRow`, `IconLine` (tail) |
| Calls | `IconLine` |

### `IconLine` (`$AC63`)

**IconLine**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 653 calls, 220,189 t-states own (0.00 %) |
| Called from | `PlayInterruptExit`, `IconCell` |
| Calls | `EventDone`, `IconLowerRow`, `IconCell` (tail) |
| Reads | `$B4AF`-`$B54E` (`PodIcons`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$5086`-`$50A7` (screen); `$5186`-`$51A7` (screen); `$5286`-`$52A7` (screen); `$5386`-`$53A7` (screen); `$5486`-`$54A7` (screen); `$5586`-`$55A7` (screen); 2 more ranges |

### `EffectJob` (`$AC6F`)

**event bit 0: play the requested sound effect**

Drops bit 0 from the mask (a second effect request waits; the effect player posts no more of itself) and calls the effect player `$B30C`, which keeps the scheduler going from its tone loop. Posted by RequestEffect (`$B2F0`).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 2,365 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 102,275 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 13,234 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 11,374 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `EffectPlay` |
| Reads | `$81C6` (`EventMask`) |
| Writes | `$81C6` (`EventMask`) |

### `EffectJobDone` (`$AC79`)

**EffectJobDone**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 33 calls, 588 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,633 calls, 23,959 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 186 calls, 2,890 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 204 calls, 2,631 t-states own (0.00 %) |
| Called from | `EffectEnd` |
| Calls | `EventDone` |

### `ScoreJob` (`$AC7A`)

**event bit 1: print the score, the extra life**

Allows only bit 7 meanwhile. Prints the current player's score (PrintPlayerScore `$A4AE` with A = CurrentPlayer `$7F98`) and recomputes WeaponRating (`$9B75`: how fast the next waves fly). The extra life: when the record's +1 (the score's high part) is at least ExtraLifeScores[+`$0C`] (`$800F`: 1, 3, 5, 7, 9, then `$FF`), +`$0C` steps on, the lives (+4) + 1 and DrawLives `$A4EF` shows them. Posted by the score adder (`$A4AB`).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 1,796 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 59,456 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 21,024 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 19,661 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `WeaponRating`, `PrintPlayerScore`, `DrawLives` |
| Reads | `$7F98`-`$7FA8` (`CurrentPlayer`, `PlayerRecord`, `Players`, `Player1`); `$800F`-`$8010` (`ExtraLifeScores`); `$81C6` (`EventMask`) |
| Writes | `$7FA0`-`$7FA8` (`Player1Lives`, `Player1LivesLost`, `Player1LevelIndex`, `Player1PodSelector` and 5 more); `$81C6` (`EventMask`) |

### `ScoreJobRating` (`$AC87`)

**ScoreJobRating**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 7 calls, 121,600 t-states own (0.00 %) |
| Called from | `PrintPlayerScoreDone` |
| Calls | `WeaponRating`, `DrawLives`, `EventDone` |
| Reads | `$7F99`-`$7FA8` (`PlayerRecord`, `Players`, `Player1`); `$800F`-`$8014` (`ExtraLifeScores`) |
| Writes | `$7FA0`-`$7FA8` (`Player1Lives`, `Player1LivesLost`, `Player1LevelIndex`, `Player1PodSelector` and 5 more) |

### `SpriteBuildJob` (`$ACA6`)

**event bit 7: build the sprites waiting in the ring**

Sets the mask to 0 (nothing interrupts it), then builds every entry between DrawQueueRead (`$8024`) and DrawQueueWrite (`$8025`): entry k at `$8026` + 3 k is the kind and the descriptor's address; LoadCellSprite the image, SpriteBuildShifts the shifted copies, then bit 7 of the descriptor's +`$0E` (waiting) is cleared. The read index wraps at 8 (RES 3). c2: 5 builds (BuildCellSprite 5 entries, RotateSprite 35).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 155 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 10,664 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 806 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 930 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SpriteBuildNext` |
| Reads | `$81C6` (`EventMask`) |
| Writes | `$81C6` (`EventMask`) |

### `SpriteBuildNext` (`$ACAD`)

**SpriteBuildNext**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 10 calls, 1,271 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 688 calls, 20,659 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 52 calls, 1,598 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 60 calls, 7,604 t-states own (0.00 %) |
| Called from | `SpriteBuildJob`, `SpriteBuildDone` (tail) |
| Calls | `EventDone`, `SpriteBuildEmpty`, `LoadCellSprite`, `SpriteBuildShifts` |
| Reads | `$8024`-`$803D` (`DrawQueueRead`, `DrawQueueWrite`, `DrawQueue`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$8024` (`DrawQueueRead`) |

### `SpriteBuildEmpty` (`$ACB4`)

**SpriteBuildEmpty**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 689 calls, 66,342 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 54 calls, 5,035 t-states own (0.00 %) |
| Called from | `PlayInterruptExit`, `SpriteBuildNext` |
| Calls | `EventDone`, `LoadCellSprite`, `SpriteBuildShifts` |
| Reads | `$8024`-`$803D` (`DrawQueueRead`, `DrawQueueWrite`, `DrawQueue`) |
| Writes | `$8024` (`DrawQueueRead`) |

### `SpriteBuildDone` (`$ACD0`)

**SpriteBuildDone**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 5 calls, 314 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 343 calls, 21,914 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 26 calls, 1,606 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 30 calls, 1,869 t-states own (0.00 %) |
| Called from | `SpriteShiftNext`, `SpriteShiftLoop` |
| Calls | `SpriteBuildNext` (tail) |
| Reads | `$7EF0`-`$7F50` (`SpriteCache+14`, `SpriteCacheRecord1`, `SpriteCacheUse1`, `SpriteCacheRecord2` and 4 more) |
| Writes | `$7EF0`-`$7F50` (`SpriteCache+14`, `SpriteCacheRecord1`, `SpriteCacheUse1`, `SpriteCacheRecord2` and 4 more) |

### `LoadCellSprite` (`$ACD9`)

**build a kind's image from its glyphs**

In: A the kind, HL the descriptor (+0/+1 the image's address). Kinds `$14` and up go to BuildBigSprite `$8F0C` with kind - `$13` (not reached in c1 or c2; r1: 6 entries, frames 16855-66273: the big enemies). Else the glyphs are at `$6400` + 32 kind (kinds 16-19: 48 bytes each, + 16 (kind - 16) + 32 more), B = 2 cells a column, C = 2 columns or 3 for bit 4 of the kind; BuildCellSprite `$8EDB` builds the complemented image with blank borders. HL is kept. c2: 5 entries.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 5 calls, 1,410 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 344 calls, 96,317 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 26 calls, 7,429 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 30 calls, 8,532 t-states own (0.00 %) |
| Called from | `SpriteBuildNext`, `SpriteBuildEmpty` |
| Calls | `BuildCellSprite`, `BuildBigSprite` |
| Reads | `$7EF2`-`$7F43` (`SpriteCacheRecord1`, `SpriteCacheUse1`, `SpriteCacheRecord2`, `SpriteCacheRecord3` and 3 more) |

### `SpriteBuildShifts` (`$AD16`)

**the pre-shifted copies of a sprite: seven one-pixel shifts, a new copy where the pattern says**

In: HL the descriptor. Its +4/+5 (the image's length), +9 (the shift pattern) and +`$0A`/+`$0B` (BC for RotateSprite: B the width in bytes, C the height in lines) are written into the operands of LD HL (`$AD3E`), LD A (`$AD47`) and LD BC (`$AD4A`): self-modified code. DE = the image (+0/+1). Seven rounds, one a pixel: the first always, and later each set bit of the pattern (RRA), copy the current image to the next slot (LDIR of the length) and continue on the copy; then RotateSprite `$8F5A` shifts it one pixel right. A clear bit shifts the last copy on without a new slot, so the pattern chooses which of the 8 pixel positions get an image (8, 4 or 2 copies). c2: 5 entries, RotateSprite 35 times (7 a sprite).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 5 calls, 993 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 344 calls, 68,350 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 26 calls, 5,126 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 30 calls, 5,922 t-states own (0.00 %) |
| Called from | `SpriteBuildNext`, `SpriteBuildEmpty` |
| Calls | `SpriteShiftRound` |
| Reads | `$7EE2`-`$7F4D` (`SpriteCache`, `SpriteCacheRecord1`, `SpriteCacheUse1`, `SpriteCacheRecord2` and 4 more) |
| Writes | `$AD3E`-`$AD4B` (`SpriteShiftLength+1`, `SpriteShiftCopy`) |

### `SpriteShiftRound` (`$AD38`)

**SpriteShiftRound**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 35 calls, 2,103 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,408 calls, 37,680 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 182 calls, 10,834 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 210 calls, 12,539 t-states own (0.00 %) |
| Called from | `SpriteBuildShifts`, `SpriteShiftNext` (tail), `SpriteShiftLoop` (tail) |
| Calls | `SpriteShiftTest`, `SpriteShiftCopy` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `SpriteShiftTest` (`$AD3A`)

**SpriteShiftTest**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,409 calls, 105,952 t-states own (0.00 %) |
| Called from | `PlayInterruptExit`, `SpriteShiftRound` |
| Calls | `SpriteShiftCopy` |

### `SpriteShiftCopy` (`$AD44`)

**SpriteShiftCopy**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 38 calls, 55,100 t-states own (0.05 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,509 calls, 4,184,182 t-states own (0.08 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 193 calls, 289,679 t-states own (0.07 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 222 calls, 333,640 t-states own (0.06 %) |
| Called from | `PlayInterruptExit`, `SpriteShiftRound`, `SpriteShiftTest` |
| Calls | `RotateSprite` |
| Reads | `$C008`-`$CDCF` (`GlyphCache+8`, `WaveCellSource`, `GlyphCacheUpper`); `$E748`-`$EB7F` (`SpriteCacheImages`); `$EBC8`-`$EFFF` (`SpriteCacheImages+1152`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$C200`-`$CFC7` (`GlyphCache+512`, `WaveCellSource`, `GlyphCacheUpper`); `$E790`-`$EBC7` (`SpriteCacheImages+72`); `$EC10`-`$F047` (`SpriteCacheImages+1224`) |

### `SpriteShiftNext` (`$AD50`)

**SpriteShiftNext**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 1,564 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 357 calls, 73,816 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 27 calls, 8,077 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 32 calls, 9,337 t-states own (0.00 %) |
| Called from | `RotateNextByte`, `RotateLineNext`, `RotateLineCount` |
| Calls | `SpriteBuildDone`, `SpriteShiftRound` (tail), `SpriteShiftLoop` |

### `SpriteShiftLoop` (`$AD53`)

**SpriteShiftLoop**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,409 calls, 33,255 t-states own (0.00 %) |
| Called from | `PlayInterruptExit`, `SpriteShiftNext` |
| Calls | `SpriteBuildDone`, `SpriteShiftRound` (tail) |

### `RestoreCheckpoint` (`$AD56`)

**the wave script's state back from the player record**

Copies the player record's +`$0D`-+`$2F` (35 bytes, the checkpoint that CmdCheckpoint `$AED2` and SetLevelStart `$B062` write) to the VM state ScriptState `$81D7-$81F9`. Called by RoundSetup (`$B023`), so a level restarts at its last checkpoint after a lost life. c2: 1 entry.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 852 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 9,407 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 855 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Reads | `$7F99`-`$7FCB` (`PlayerRecord`, `Players`, `Player1`) |
| Writes | `$81D7`-`$81F9` (`ScriptState`, `ScriptPC`, `PlayFlags`, `ScrollCount` and 8 more) |

## wavescript

`src/game/wavescript.asm`

### `WaveScriptStep` (`$AD66`)

**one frame of the level's script**

Called from the play interrupt at phase 2 (`$AA96`; c2: 165 entries, one in four of its 659 passes), returns at once unless DeathTimer (`$7F7B`) is `$FF`. When the wait counter (`$81E1`) equals the delay byte at the PC (`$81D8`): the counter is zeroed, the opcode is read and run, and the next instruction is looked at at once; else the counter + 1 and return. Callees: JumpTable `$91E2` (commands), LaunchWave `$91EC` (waves), ScriptWord, ScriptByte, ScriptTest.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 165 calls, 19,047 t-states own (0.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 9,138 calls, 1,556,056 t-states own (0.03 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 748 calls, 126,781 t-states own (0.03 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 928 calls, 163,032 t-states own (0.03 %) |
| Called from | `PlayPass` |
| Calls | `JumpTable`, `LaunchWave`, `ScriptWord`, `ScriptByte`, `ScriptTest` |
| Reads | `$6B8D`-`$6FA6` (`LevelScripts`); `$6FCA`-`$72A7` (`LevelScripts+1085`); `$7F7B` (`DeathTimer`); `$81D8`-`$81E1` (`ScriptPC`, `PlayFlags`, `ScrollCount`, `ScriptNumber` and 3 more) |
| Writes | `$81D8`-`$81E1` (`ScriptPC`, `PlayFlags`, `ScrollCount`, `ScriptNumber` and 3 more) |

### `ScriptSaveFlags` (`$ADD3`)

**keep F of the last word command for the conditions**

PUSH AF / POP HL takes F into L, stored in ScriptFlags `$81E2` (the conditions read `$81E2`/`$81E3` as an AF pair). Called by the word commands 9-12 and 17.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 165 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,176 calls, 92,311 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 121 calls, 8,468 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 149 calls, 10,684 t-states own (0.00 %) |
| Called from | `CmdDecrement`, `CmdEnemiesLeft` |
| Writes | `$81E2` (`ScriptFlags`) |

### `ScriptWord` (`$ADDC`)

**DE = the next word of the script**

Reads the word at the PC (`$81D8`) and steps the PC past it; HL kept.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 6 calls, 598 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,042 calls, 198,942 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 192 calls, 17,359 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 248 calls, 22,897 t-states own (0.00 %) |
| Called from | `WaveScriptStep`, `CmdStore`, `CmdDecrement` |
| Reads | `$6B92`-`$6BA6` (`LevelScripts+5`); `$6BC6`-`$6C52` (`LevelScripts+57`); `$6C70`-`$6CAD` (`LevelScripts+227`); `$6CC4`-`$6D42` (`LevelScripts+311`); `$6D57`-`$6F2A` (`LevelScripts+458`); `$6F4E`-`$6FA8` (`LevelScripts+961`); 3 more ranges |
| Writes | `$81D8`-`$81D9` (`ScriptPC`) |

### `ScriptByte` (`$ADE9`)

**C = the next byte of the script**

Reads the byte at the PC and steps it; HL kept.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 9 calls, 773 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 754 calls, 63,369 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 30 calls, 2,566 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 64 calls, 5,436 t-states own (0.00 %) |
| Called from | `WaveScriptStep` |
| Reads | `$6B8F`-`$6BFB` (`LevelScripts+2`); `$6C22`-`$6EE1` (`LevelScripts+149`); `$6F08`-`$6F6C` (`LevelScripts+891`); `$6FCC`-`$701F` (`LevelScripts+1087`); `$7044`-`$70D7` (`LevelScripts+1207`); `$70F8`-`$7162` (`LevelScripts+1387`); 3 more ranges |
| Writes | `$81D8`-`$81D9` (`ScriptPC`) |

### `ScriptTest` (`$ADF4`)

**carry when the condition A holds**

In: A the condition (0-6). Out: carry when it holds; A, BC, DE, HL kept (A is the condition again). The saved flags `$81E2`/`$81E3` are loaded into AF' and the test routine (ScriptConditions `$8223` through `$91E2`) takes them with EX AF,AF'.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 425 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,176 calls, 245,176 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 121 calls, 21,575 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 149 calls, 27,330 t-states own (0.01 %) |
| Called from | `WaveScriptStep` |
| Calls | `JumpTable` |
| Reads | `$81E2`-`$81E3` (`ScriptFlags`, `ScrollRestart`) |

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
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 55 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 27,885 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 2,382 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 3,041 t-states own (0.00 %) |
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
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 28 t-states own (0.00 %) |
| Called from | `JumpTable` |

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
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 725 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 43 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 70 t-states own (0.00 %) |
| Called from | `JumpTable`, `CmdLevelEnd` |
| Reads | `$81DA` (`PlayFlags`) |
| Writes | `$81DA` (`PlayFlags`) |

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
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,231 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 109 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `CmdScrollStop` |
| Reads | `$7F99`-`$7F9A` (`PlayerRecord`) |
| Writes | `$7F7C` (`EndPending`); `$7FA4`-`$7FA5` (`Player1SideWeapon`, `Player1DoublePlasma`) |

### `CmdNop2` (`$AE54`)

**command 6: nothing (never used)**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdStore` (`$AE55`)

**command 7: (word 1) = word 2 (80 uses, all on the counter `$81E4`)**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 88 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 5,704 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 237 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 411 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ScriptWord` |
| Writes | `$81E4`-`$81E5` (`ScriptCounter`) |

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
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 324 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 112,823 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 9,422 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 13,223 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ScriptSaveFlags`, `ScriptWord` |
| Reads | `$81E4`-`$81E5` (`ScriptCounter`) |
| Writes | `$81E4`-`$81E5` (`ScriptCounter`) |

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

Copies the VM state `$81D7-$81F9` (35 bytes, PC past this instruction) to the player record's +`$0D`: a lost life restarts the level here (RestoreCheckpoint, then LevelStart replays the scroll count). Measured (work/f4/invuln.py): level 0's checkpoint moved from `$6B8D` (replay `$40`) to `$6BC4` with the replay count `$122` between frames 1000 and 2000; with no checkpoint passed a death restarted the script at `$6B8D`.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 18,125 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 1,177 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 1,177 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Reads | `$7F99`-`$7F9A` (`PlayerRecord`); `$81D7`-`$81F9` (`ScriptState`, `ScriptPC`, `PlayFlags`, `ScrollCount` and 8 more) |
| Writes | `$7FA9`-`$7FCB` (`Player1LevelState`) |

### `CmdResetRecords` (`$AEE3`)

**command 15: reset the 18 records of 32 bytes at `$F12C` (8 uses)**

For each record: +8 = 0, +6/+7 = `$85E4`; then of the 32 bytes below its pointer (+0/+1) every one whose byte `$40` higher is 0 is cleared. F6's buffers at `$F12C`; the pointers lead into the map work space.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 214,426 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 26,923 t-states own (0.01 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 26,914 t-states own (0.01 %) |
| Called from | `JumpTable` |
| Reads | `$B700`-`$BFFF` (`Start+1`, `MapRingSpace`, `TileSource`); `$F12C`-`$F26D` (`RowRecords`); `$F28C`-`$F28D` (`RowRecords+352`); `$F2AC`-`$F2AD` (`RowRecords+384`); `$F2CC`-`$F2CD` (`RowRecords+416`); `$F2EC`-`$F2ED` (`RowRecords+448`); 3 more ranges |
| Writes | `$B700`-`$BF03` (`Start+1`, `MapRingSpace`, `TileSource`); `$BF1E`-`$BF7F` (`TileSource+798`); `$BF93`-`$BFD7` (`TileSource+915`); `$BFEC`-`$BFFF` (`TileSource+1004`); `$F132`-`$F274` (`RowRecords+6`); `$F292`-`$F294` (`RowRecords+358`); 6 more ranges |

### `CmdEnemyEscape` (`$AF16`)

**command 16: when the enemy record `$F398` is active, EnemyEscaped `$994A` and FreeEnemySlot `$992A` (5 uses)**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 320 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `FreeEnemySlot`, `EnemyEscaped` |
| Reads | `$F3A0` (`EnemyObjects+8`) |

### `CmdEnemiesLeft` (`$AF26`)

**command 17: NZ while one of the five enemies at `$F398` lives (15 uses)**

A record counts when +8 has bits 5 and 7 set and +`$0D` is not `$FF`. The flags go to ScriptFlags: the script's 'jump NZ' back waits for the wave to be shot down.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 92,206 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 7,958 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 16,729 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `ScriptSaveFlags` |
| Reads | `$F3A0`-`$F3A5` (`EnemyObjects+8`); `$F3CC`-`$F3D1` (`EnemyObjects+52`); `$F3F8`-`$F3FD` (`EnemyObjects+96`); `$F424`-`$F429` (`EnemyObjects+140`); `$F450`-`$F455` (`EnemyObjects+184`) |

## rounds

`src/game/rounds.asm`

### `LevelStart` (`$AF49`)

**the level banner and the scroll to the start point**

LevelSetUp `$8C3B` (the playfield model, the map buffer), MenuScreenSetup `$A685`, sets the print position (`$80B0` = `$60`, `$80B9` = `$4B`), prints message `$18` (`$A423`), sets `$801F` = `$10` and `$801E` = `$60`, StartScript `$8D35` (the scenery script); then ReplayScroll. Called by RoundSetup; c2: 1 entry.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 176 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 1,885 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 176 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Calls | `LevelSetUp`, `StartScript`, `PrintMessage`, `MenuScreenSetup` |
| Writes | `$801E`-`$801F` (`ScriptColumn`, `ScriptRoom`); `$80B0`-`$80B9` (`RasterLines`, `RasterList`, `RasterSpare`, `RasterFrames`) |

### `ReplayScroll` (`$AF6B`)

**ReplayScroll**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 131 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 1,720 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 156 t-states own (0.00 %) |
| Called from | `YieldScript` |
| Calls | `ReplayStep` (tail) |
| Reads | `$81DB`-`$81DC` (`ScrollCount`) |
| Writes | `$7F76` (`SkipDraw`); `$81DB`-`$81DC` (`ScrollCount`) |

### `ReplayColumns` (`$AF90`)

**scroll BC columns, ReplayFast = A**

A is stored in ReplayFast (`$7F76`, read by `$8DCA`: `$FF` skips the drawing). Each column: StartColumn `$894D` and three rounds of ResumeScript `$8D45` (the scenery script) and BuildColumn `$896D`, then ScrollStep `$8AED` scrolls one column (and counts `$81DB` up). c2: AF9F 192 rounds at a level start.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReplayStep` (`$AF9A`)

**ReplayStep**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 1,662 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 13,300 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 1,211 t-states own (0.00 %) |
| Called from | `ReplayScroll` (tail) |
| Calls | `StartColumn`, `ReplayRound` |

### `ReplayRound` (`$AF9F`)

**ReplayRound**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 192 calls, 6,211 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,560 calls, 50,549 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 144 calls, 4,705 t-states own (0.00 %) |
| Called from | `ReplayStep`, `ReplayRoundEnd` (tail) |
| Calls | `ResumeScript` |

### `ReplayRoundEnd` (`$AFA3`)

**ReplayRoundEnd**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 25 calls, 12,856 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 57 calls, 103,675 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 2 calls, 9,565 t-states own (0.00 %) |
| Called from | `YieldScript` |
| Calls | `BuildColumn`, `ScrollStep`, `ReplayRound` (tail), `RoundPlaySetup` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `InterruptSetup` (`$AFB0`)

**the IM 2 table and a clear screen, once at the start**

SetUpInterrupts `$8516` (the IM 2 table) and ClearScreen `$858B`; called once by MainLoop (c1: 1 entry).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 1 call (`c1` 1) |
| Called from | `MainLoop` |
| Calls | `SetUpInterrupts`, `ClearScreen` |

### `PlayersSetup` (`$AFB7`)

**both player records and the level order of a new game**

CurrentPlayer `$7F98` = 1, PlayerRecord `$7F99` = `$7F9C`; both records (96 bytes from `$7F9C`) zeroed; player 1's lives = 2, player 2's = 3 when Players (`$7F9B`) is 2, else 0; the speed +`$0B` = `$40` and the laser level +`$0A` = 1 for both; SetLevelStart for each (both at level 0). Then LevelOrder `$8006-$800B`: six different numbers 3-8 drawn from Random `$8544` (one game measured: 07 06 05 04 08 03, work/f4/invuln.py). Called by MainLoop.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RoundSetup` (`$B023`)

**a level's start: the checkpoint, the objects, the banner, the panel**

RestoreCheckpoint, EnemiesSetup, ShotsSetup, PlayerSetup; the player's digit '0' + Player at `$84BB` (the banner's text), LevelStart; then RoundPlaySetup (`$B03A`). Called by MainLoop before each play loop (c2: 1 entry).

WaitMenuRasterEnd `$A595`, ClearHitGrid `$91C6` with interrupts off, Fuel = `$5A`, DeathTimer = `$FF` (the script runs), ClearScreen `$858B`, RestorePanel `$A979`, both scores (PrintPlayerScore `$A4AE` with 1 and 2), the lives (DrawLives `$A4EF`), WeaponRating `$9B75`.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 139 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 1,543 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 139 t-states own (0.00 %) |
| Called from | `MainLoopEnd` |
| Calls | `RestoreCheckpoint`, `LevelStart`, `PlayerSetup`, `EnemiesSetup`, `ShotsSetup` |
| Reads | `$7F98` (`CurrentPlayer`) |
| Writes | `$84BB` (`PlayerDigit`) |

### `RoundPlaySetup` (`$B03A`)

**RoundPlaySetup**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 249 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 2,735 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 247 t-states own (0.00 %) |
| Called from | `ReplayRoundEnd` |
| Calls | `ClearScreen`, `ClearHitGrid`, `WeaponRating`, `PrintPlayerScore`, `DrawLives`, `WaitMenuRasterEnd`, `RestorePanel`, `MainLoopPlay` |
| Writes | `$7F7B` (`DeathTimer`); `$80E6` (`Fuel`) |

### `SetLevelStart` (`$B062`)

**a level's start into a player record's checkpoint**

In: IX the record. +5 = 0, `$81E3` = 0; the record's +`$0D` gets the 8 bytes of the level entry `$6B2D` + 8 * LevelOrder[+6] (the ScriptState `$81D7-$81DE`: +1 the PC, +3 the scroll flags `$FF`, +4 the replay count), then the 5 bytes at `$81FA` (the stack pointer `$81F6`, zeros). Called by PlayersSetup for both players and by LevelDone.

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 8,444 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 664 t-states own (0.00 %) |
| Called from | `LevelDone` |
| Reads | `$6B35`-`$6B8C` (`LevelTable+8`); `$7FA2` (`Player1LevelIndex`); `$8004`-`$800E` (`LevelOrder+1`); `$81FA`-`$81FE` (`ScriptStateInit`) |
| Writes | `$7FA1`-`$7FB5` (`Player1LivesLost`, `Player1LevelIndex`, `Player1PodSelector`, `Player1SideWeapon` and 5 more); `$81E3` (`ScrollRestart`) |

### `CreditsPage` (`$B095`)

**the title page with both players' scores and the tune**

ClearScreen `$858B`, PrintMessage `$15`, the scores of both players at `$5AA0` and `$5AB8` (PrintBcd `$A43E` of record +0, C = '0') with the colour `$05`, plays the title tune (TitleTune `$B446`, until fire or keys 1-5), MenuKeys `$A76F`, then TitleFireCheck (`$A748`: carry = fire). c1: 2 entries. Called by MainLoop.

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 2 calls (`c1` 2) |
| Called from | `MainLoop` |
| Calls | `ClearScreen`, `PrintMessage`, `PrintBcd`, `TitleFireCheck`, `MenuKeys`, `TitleTune` |

### `HiScorePage` (`$B0C9`)

**the high score table, 500 frames or fire**

ClearScreen, PrintMessage `$16`, the five entries of HiScoreTable `$8261` (14 bytes each: the 10-byte print string with the initials through PrintString `$A401`, then the 4 BCD bytes through PrintBcd `$A43E` with C = '.') in `$46`; then 500 HALTs with TitleFireCheck polled. Out: carry when fire was pressed. c1: 1 entry, 30 permille of the recording (the page's 10 s wait).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 1 call (`c1` 1) |
| Called from | `MainLoop` |
| Calls | `ClearScreen`, `PrintString`, `PrintMessage`, `PrintBcd`, `TitleFireCheck` |

## mainloop

`src/game/mainloop.asm`

### `EndOfPlay` (`$B0FF`)

**after the play loop: dispatch on the end code**

In: A the end code (1-4). WaitFrames `$A6AE` for 50 frames, FadeAttributes `$85AD`, then EndHandlers (`$B111`) through `$91E2` with code - 1. Out: carry when the game is over (from PlayerDied). Called by MainLoop.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 144 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 1,222 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 109 t-states own (0.00 %) |
| Called from | `MainLoopEnd` |
| Calls | `FadeAttributes`, `JumpTable`, `WaitFrames` |

### `PlayerDied` (`$B119`)

**end code 1: a life lost**

The record's deaths +5 + 1, +8 and +9 zeroed (the side weapon and the double plasma are lost), FuelOut `$9C03` (Fuel = `$5A`, the laser level and the speed one step down). With no lives left: HighScoreEntry `$A7F7`, NextPlayer, and carry when the lives went negative (the game is over); with lives: NextPlayer and NC. c2: 1 entry (indirect).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | run into, not called, 205 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `FuelOut`, `NextPlayer` |
| Reads | `$7F99`-`$7FA1` (`PlayerRecord`, `Players`, `Player1`) |
| Writes | `$7FA1`-`$7FA5` (`Player1LivesLost`, `Player1LevelIndex`, `Player1PodSelector`, `Player1SideWeapon` and 1 more) |

### `NextPlayer` (`$B149`)

**the other player's turn, one life less**

One player: the life is taken from the current record. Two: when the other record has lives, it becomes PlayerRecord and Player flips (1 <-> 2); a life of the record in play then is taken (`$B170`).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 80 t-states own (0.00 %) |
| Called from | `PlayerDied` |
| Reads | `$7F9B`-`$7FA0` (`Players`, `Player1`) |
| Writes | `$7FA0` (`Player1Lives`) |

### `LevelDone` (`$B174`)

**end code 2: the next level**

The record's +6 + 1, wrapping from 12 to 0, SetLevelStart. Not in c1 or c2; r1 (the long bot run, 75001 frames) ran it 11 times (frames 6257-67115); seen in work/f4/invuln.py (Invulnerable on, 30000 frames): level 0 ended near frame 6500, 1 near 14500, 2 near 20500, 3 near 27500, and with LevelOrder 00 01 02 07 06 05 04 08 03 09 0A 0B the scripts ran `$6B8D`, `$6C1A`, `$6C97`, `$70F6` (order 7), `$7068` (order 6).

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | run into, not called, 1,751 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | run into, not called, 163 t-states own (0.00 %) |
| Called from | `JumpTable` |
| Calls | `SetLevelStart` |
| Reads | `$7F99`-`$7FA2` (`PlayerRecord`, `Players`, `Player1`) |
| Writes | `$7FA2` (`Player1LevelIndex`) |

### `AbortGame` (`$B18A`)

**end codes 3 and 4: back to the title pages**

DI, TitleInterrupt `$A9E4`, SP = `$5C00` (whatever the stack held), JP MainLoopTitle: CreditsPage comes next. Code 4 is set by key Q in the pause.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Pause` (`$B197`)

**the pause: fire resumes, Q aborts**

StopAndSettle, then a loop: a delay of `$2000` rounds, TitleFireCheck (`$A748`: fire, back to play), key Q (half row `$FBFE`, bit 0): EndPending = 4 (the play loop ends, AbortGame). Called by CheckPauseAndEnd on key 4, inside the play interrupt: the whole game stands. Measured (work/f4/pause.py): after key 4, PassCount `$7F62` stayed `$4D` and the script PC `$6B96` for 400 frames; Q gave `$7F7C`/`$7F7D` = 4/4, Handler `$A9E4` and the credits page.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlayLoop` (`$B1B4`)

**a life or a level of play**

FrameRate `$7F6A` = `$C8`, `$7F6B` = 8; EventRequests = 0 and EventMask = `$FF`, then bit 2 posted (the pod icon); `$7F65` (the interrupt phase), `$7F64`, CurrentEffect `$7F97`, EndPending, EndCode and `$974C` zeroed; one frame, the play handler `$A9ED`; then EventDispatch round after round (c2: 68083) until EndCode is set. The play interrupt does the frame's work meanwhile. Then TitleInterrupt, SavePanel `$A98D`, and A = EndCode. Called by MainLoop.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 21,595 t-states own (0.02 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 237,768 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 21,602 t-states own (0.00 %) |
| Called from | `MainLoopPlay` |
| Calls | `PlayLoopPass` |
| Reads | `$81C5` (`EventRequests`); `$B1DE` (`PlayLoop+42`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$7F64`-`$7F6B` (`PassDepth`, `PassPhase`, `ChainStep`, `NodeFreeList` and 2 more); `$7F7C`-`$7F7D` (`EndPending`, `EndCode`); `$7F97` (`CurrentEffect`); `$81C5`-`$81C6` (`EventRequests`, `EventMask`); `$974C` (`LandingFlag`); `$FDFE`-`$FDFF` (`InterruptHandler`) |

### `PlayLoopPass` (`$B1E6`)

**PlayLoopPass**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 68,083 calls, 1,344,154 t-states own (1.28 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,894,567 calls, 58,001,436 t-states own (1.11 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 321,168 calls, 6,386,878 t-states own (1.53 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 667,362 calls, 13,369,997 t-states own (2.52 %) |
| Called from | `PlayInterruptExit`, `PlayLoop`, `PlayLoopAgain` (tail) |
| Calls | `EventDispatch` |

### `PlayLoopCheck` (`$B1E9`)

**PlayLoopCheck**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 148 calls, 954,572 t-states own (0.91 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 5,380 calls, 40,902,188 t-states own (0.78 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 598 calls, 4,520,452 t-states own (1.08 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1,045 calls, 9,428,971 t-states own (1.78 %) |
| Called from | `PlayInterruptExit`, `EventAny`, `EventDone` |
| Calls | `PlayLoopTest` |
| Reads | `$7F7D` (`EndCode`); `$FEFF`-`$FF00` (`VectorTable+255`) |

### `PlayLoopTest` (`$B1EC`)

**PlayLoopTest**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 68,079 calls, 749,140 t-states own (0.71 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,894,519 calls, 11,574,063 t-states own (0.22 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 321,154 calls, 1,284,186 t-states own (0.31 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 667,327 calls, 2,668,535 t-states own (0.50 %) |
| Called from | `PlayInterruptExit`, `PlayLoopCheck` |
| Calls | `SavePanel`, `PlayLoopBranch`, `PlayLoopAgain`, `MainLoopEnd` |
| Reads | `$7F7D` (`EndCode`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$FDFE`-`$FDFF` (`InterruptHandler`) |

### `PlayLoopBranch` (`$B1ED`)

**PlayLoopBranch**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,893,497 calls, 20,276,374 t-states own (0.39 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 321,039 calls, 2,249,539 t-states own (0.54 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 667,130 calls, 4,674,054 t-states own (0.88 %) |
| Called from | `PlayInterruptExit`, `PlayLoopTest` |
| Calls | `SavePanel`, `PlayLoopAgain`, `MainLoopEnd` |
| Reads | `$7F7D` (`EndCode`); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$FDFE`-`$FDFF` (`InterruptHandler`) |

### `PlayLoopAgain` (`$B1EF`)

**PlayLoopAgain**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 68,070 calls, 817,222 t-states own (0.78 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 2,894,587 calls, 34,742,197 t-states own (0.66 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 321,157 calls, 3,854,933 t-states own (0.92 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 667,342 calls, 8,009,963 t-states own (1.51 %) |
| Called from | `PlayInterruptExit`, `PlayLoopTest`, `PlayLoopBranch` |
| Calls | `PlayLoopPass` (tail) |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `MainLoop` (`$B200`)

**the game's top loop**

Entered from Start (`$B72C`). InterruptSetup, then the title pages until fire, PlayersSetup, and the rounds of RoundSetup, PlayLoop and EndOfPlay. Never returns.

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 1 call (`c1` 1) |
| Called from | `Start` (tail) |
| Calls | `InterruptSetup`, `CreditsPage`, `HiScorePage` |

### `MainLoopPlay` (`$B212`)

**MainLoopPlay**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 17 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 187 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 17 t-states own (0.00 %) |
| Called from | `RoundPlaySetup` |
| Calls | `PlayLoop` |

### `MainLoopEnd` (`$B215`)

**MainLoopEnd**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 2 calls, 63 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 561 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 46 t-states own (0.00 %) |
| Called from | `PlayLoopTest`, `PlayLoopBranch` |
| Calls | `RoundSetup`, `EndOfPlay` |

### `PlayerSetup` (`$B21C`)

**the player's ship and the objects tied to it**

The ship's record `$F36C`: X 0/`$14`, Y 0/8, active (bit 7 of +8), +`$25` = `$68`; `$F37C` = `$20`, `$F380` = `$40`; the record `$F600` inactive; `$80BF` = 0. Then eight pairs of words below `$80E0` written by PUSHes with SP moved there (DE = `$0800`, HL = `$1400`: 32 bytes `$80C0-$80DF`) with interrupts off. `$F5D4` and `$F5A8` inactive. When the record's side weapon +8 is 2 or more (2 plasma, 3 homing missiles, 4 seeker), +8 = 0 and its pod action runs again through the pod table `$80F0` (PodPlasma, PodHoming, PodSeeker), which arms it anew for the new ship. Called by RoundSetup.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 717 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 7,911 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 717 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Reads | `$7F99`-`$7FA4` (`PlayerRecord`, `Players`, `Player1`); `$F374` (`PlayerObject+8`); `$F5B0` (`PlasmaBall2+8`); `$F5DC` (`SideShot+8`); `$F608` (`SightObject+8`) |
| Writes | `$80BF` (`ShipHistoryIndex`); `$B263`-`$B264` (`FillRestoreSP+1`); `$F36F`-`$F380` (`PlayerObject+3`, `PlayerHitMask`, `PlayerAccelX`, `PlayerAccelY`); `$F391` (`PlayerAccelY+17`); `$F5B0` (`PlasmaBall2+8`); `$F5DC` (`SideShot+8`); 1 more ranges |

### `EnemiesSetup` (`$B28B`)

**the five enemy records inactive, then the pod objects**

The five records of `$2C` bytes at `$F398`: inactive (bit 7 of +8), +`$26` = `$E0`, +`$27` = `$80`. Then PodsSetup. Called by RoundSetup.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 689 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 7,621 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 689 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Calls | `PodsSetup` |
| Reads | `$F3A0` (`EnemyObjects+8`); `$F3CC` (`EnemyObjects+52`); `$F3F8` (`EnemyObjects+96`); `$F424` (`EnemyObjects+140`); `$F450` (`EnemyObjects+184`) |
| Writes | `$F3A0` (`EnemyObjects+8`); `$F3BE`-`$F3CC` (`EnemyObjects+38`); `$F3EA`-`$F3F8` (`EnemyObjects+82`); `$F416`-`$F424` (`EnemyObjects+126`); `$F442`-`$F450` (`EnemyObjects+170`); `$F46E`-`$F46F` (`EnemyObjects+214`) |

### `PodsSetup` (`$B2AA`)

**the three objects at `$F474` tied to the ship**

Three records of `$2C` bytes at `$F474`: +`$25` = `$48`, kind +7 = 5, inactive, +`$29`/+`$2A` = `$F36C` (the ship's record).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 567 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 6,163 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 567 t-states own (0.00 %) |
| Called from | `EnemiesSetup` |
| Reads | `$F47C` (`EnemyShots+8`); `$F4A8` (`EnemyShots+52`); `$F4D4` (`EnemyShots+96`) |
| Writes | `$F47B`-`$F47C` (`EnemyShots+7`); `$F499`-`$F4A8` (`EnemyShots+37`); `$F4C5`-`$F4D4` (`EnemyShots+81`); `$F4F1`-`$F4F6` (`EnemyShots+125`) |

### `ShotsSetup` (`$B2CF`)

**the four shot records inactive**

`$80BA` = 4; four records of `$2C` bytes at `$F4F8`: +`$0B` = `$80`, +`$25` = `$78`, inactive.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 1 call, 554 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11 calls, 6,176 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 1 call, 554 t-states own (0.00 %) |
| Called from | `RoundSetup` |
| Reads | `$F500` (`LaserShots+8`); `$F52C` (`LaserShots+52`); `$F558` (`LaserShots+96`); `$F584` (`LaserShots+140`) |
| Writes | `$80BA` (`LaserShotsFree`); `$F500`-`$F503` (`LaserShots+8`); `$F51D`-`$F52F` (`LaserShots+37`); `$F549`-`$F55B` (`LaserShots+81`); `$F575`-`$F587` (`LaserShots+125`); `$F5A1` (`LaserShots+169`) |

## effects

`src/game/effects.asm`

### `RequestEffect` (`$B2F0`)

**ask for effect A (0 = stop), taken when not below the one playing**

In: A the effect, 0 is stored as `$80` (above every effect: a stop always wins). Taken when A >= CurrentEffect (`$7F97`): CurrentEffect = A, EffectTick = `$80` (new effect), event bit 0 posted. HL kept. Callers (c2): FireLaser `$9C1D` x61, `$A2D6` x2, `$A0EB` x1, StopAndSettle x2; in the listing also A = 1 (`$A1C2`), 2 (`$9C75`, the laser: FireLaser), 4 (`$A31B`), 5 (`$A224`, a pod) and 6 (`$A21D`).

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 66 calls, 9,024 t-states own (0.01 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 10,281 calls, 1,383,656 t-states own (0.03 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 587 calls, 73,374 t-states own (0.02 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 395 calls, 51,277 t-states own (0.01 %) |
| Called from | `FireLaser`, `PlasmaHandler`, `EnemyFire`, `PodStep`, `ExplosionToPod`, `StopAndSettle` |
| Reads | `$7F97` (`CurrentEffect`); `$81C5` (`EventRequests`) |
| Writes | `$7F96`-`$7F97` (`EffectTick`, `CurrentEffect`); `$81C5` (`EventRequests`) |

### `EffectPlay` (`$B30C`)

**play CurrentEffect until it ends or a new request**

Entered from EffectJob (event bit 0; c2: 106 entries in 73 frames, 45 from EffectJob and 61 restarts by a new request at `$B388`). n = CurrentEffect & `$1F`, 0 ends at once; the entry `$7E5A` + 8 (n - 1) is copied to the effect state `$7F8A-$7F90` (+0-+6) and its byte 7 split into SegLenA `$7F91` and SegLenB `$7F92`; the pitches PitchA `$7F93` and PitchB `$7F94` start from +0 and +2, the frame counter `$7F95` from SegLenA. The tone loop runs until an interrupt sets EffectTick, then calls EventDispatch (the jobs run) and steps the pitches; at a segment's end the segment's changes apply. Ends (CurrentEffect = 0) when the segments run out or a job ran (the carry from EventDispatch: an effect stops for the redraw jobs and the next effect request starts it again). EffectTick = `$80` restarts with the new effect.

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 106 calls, 49,692 t-states own (0.05 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 11,165 calls, 4,836,111 t-states own (0.09 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 634 calls, 269,188 t-states own (0.06 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 514 calls, 248,893 t-states own (0.05 %) |
| Called from | `EffectJob`, `EffectAfterJobs` (tail), `EffectRestore` (tail) |
| Calls | `EffectFirstLen`, `EffectPeriod`, `EffectEnd` (tail) |
| Reads | `$7E5A`-`$7E89` (`EffectTable`); `$7F8A`-`$7F97` (`EffectState`, `SegLenA`, `SegLenB`, `PitchA` and 4 more); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$7F8A`-`$7F95` (`EffectState`, `SegLenA`, `SegLenB`, `PitchA` and 2 more) |

### `EffectFirstLen` (`$B345`)

**EffectFirstLen**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 10,850 calls, 733,667 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 15,278 t-states own (0.00 %) |
| Called from | `PlayInterruptExit`, `EffectPlay` |
| Calls | `EffectPeriod` |
| Writes | `$7F95` (`EffectFrames`) |

### `EffectPeriod` (`$B358`)

**EffectPeriod**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 9,788 calls, 39,178 t-states own (0.04 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 992,841 calls, 3,971,125 t-states own (0.08 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 58,187 calls, 232,739 t-states own (0.06 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 60,954 calls, 243,806 t-states own (0.05 %) |
| Called from | `PlayInterruptExit`, `EffectPlay`, `EffectFirstLen`, `EffectTickTest` (tail), `EffectTickBranch` (tail), `EffectAfterJobs` (tail), `EffectRestore` (tail) |
| Calls | `EffectHalves` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectHalves` (`$B359`)

**EffectHalves**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 9,787 calls, 137,047 t-states own (0.13 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 992,680 calls, 6,950,604 t-states own (0.13 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 58,181 calls, 407,355 t-states own (0.10 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 60,944 calls, 426,879 t-states own (0.08 %) |
| Called from | `PlayInterruptExit`, `EffectPeriod` |
| Calls | `EffectSpeakerOn`, `EffectHalf` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectSpeakerOn` (`$B35B`)

**EffectSpeakerOn**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 992,760 calls, 6,956,627 t-states own (0.13 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 58,185 calls, 407,602 t-states own (0.10 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 60,957 calls, 426,841 t-states own (0.08 %) |
| Called from | `PlayInterruptExit`, `EffectHalves` |
| Calls | `EffectHalf` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectHalf` (`$B35D`)

**EffectHalf**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 19,577 calls, 146,812 t-states own (0.14 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,986,257 calls, 15,058,773 t-states own (0.29 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 116,399 calls, 882,394 t-states own (0.21 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 121,910 calls, 923,106 t-states own (0.17 %) |
| Called from | `PlayInterruptExit`, `EffectHalves`, `EffectSpeakerOn`, `EffectHalfLoop` (tail) |
| Calls | `EffectOut` |
| Reads | `$7F93`-`$7F94` (`PitchA`, `PitchB`); `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectOut` (`$B35E`)

**EffectOut**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 19,572 calls, 243,380 t-states own (0.23 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,985,443 calls, 24,926,222 t-states own (0.48 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 116,372 calls, 1,473,233 t-states own (0.35 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 121,897 calls, 1,543,083 t-states own (0.29 %) |
| Called from | `PlayInterruptExit`, `EffectHalf` |
| Calls | `EffectWait` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |
| Ports out | `$00FE`, `$18FE` |

### `EffectWait` (`$B360`)

**EffectWait**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 479,160 calls, 1,917,054 t-states own (1.83 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 41,284,083 calls, 165,150,782 t-states own (3.15 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 3,068,697 calls, 12,276,457 t-states own (2.93 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,030,241 calls, 12,123,029 t-states own (2.28 %) |
| Called from | `PlayInterruptExit`, `EffectOut`, `EffectWait3` (tail) |
| Calls | `EffectWait1` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectWait1` (`$B361`)

**EffectWait1**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 479,013 calls, 1,917,073 t-states own (1.83 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 41,273,629 calls, 165,147,894 t-states own (3.15 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 3,067,931 calls, 12,275,830 t-states own (2.93 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,029,514 calls, 12,121,566 t-states own (2.28 %) |
| Called from | `PlayInterruptExit`, `EffectWait` |
| Calls | `EffectWait2` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectWait2` (`$B362`)

**EffectWait2**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 479,014 calls, 1,917,168 t-states own (1.83 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 41,273,480 calls, 165,163,816 t-states own (3.15 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 3,067,896 calls, 12,276,096 t-states own (2.93 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,029,435 calls, 12,123,105 t-states own (2.28 %) |
| Called from | `PlayInterruptExit`, `EffectWait1` |
| Calls | `EffectWait3` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectWait3` (`$B363`)

**EffectWait3**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 479,020 calls, 6,132,414 t-states own (5.85 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 41,274,317 calls, 526,847,808 t-states own (10.05 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 3,067,914 calls, 39,317,346 t-states own (9.40 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 3,029,520 calls, 38,789,916 t-states own (7.30 %) |
| Called from | `PlayInterruptExit`, `EffectWait2` |
| Calls | `EffectWait` (tail), `EffectSwap` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectSwap` (`$B365`)

**EffectSwap**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 19,571 calls, 78,299 t-states own (0.07 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,985,485 calls, 7,943,690 t-states own (0.15 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 116,369 calls, 465,565 t-states own (0.11 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 121,894 calls, 487,707 t-states own (0.09 %) |
| Called from | `PlayInterruptExit`, `EffectWait3` |
| Calls | `EffectLow` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectLow` (`$B366`)

**EffectLow**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 19,571 calls, 137,028 t-states own (0.13 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,985,435 calls, 13,900,270 t-states own (0.27 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 116,365 calls, 814,753 t-states own (0.19 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 121,893 calls, 853,397 t-states own (0.16 %) |
| Called from | `PlayInterruptExit`, `EffectSwap` |
| Calls | `EffectHalfNext` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectHalfNext` (`$B368`)

**EffectHalfNext**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 19,572 calls, 78,318 t-states own (0.07 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,985,470 calls, 7,942,987 t-states own (0.15 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 116,371 calls, 465,603 t-states own (0.11 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 121,895 calls, 487,783 t-states own (0.09 %) |
| Called from | `PlayInterruptExit`, `EffectLow` |
| Calls | `EffectHalfLoop` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectHalfLoop` (`$B369`)

**EffectHalfLoop**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 19,572 calls, 186,010 t-states own (0.18 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,985,398 calls, 18,872,807 t-states own (0.36 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 116,367 calls, 1,105,933 t-states own (0.26 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 121,897 calls, 1,158,259 t-states own (0.22 %) |
| Called from | `PlayInterruptExit`, `EffectHalfNext` |
| Calls | `EffectHalf` (tail), `EffectTickCheck` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectTickCheck` (`$B36B`)

**EffectTickCheck**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 9,786 calls, 179,771 t-states own (0.17 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 992,778 calls, 3,978,474 t-states own (0.08 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 58,185 calls, 232,925 t-states own (0.06 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 60,948 calls, 243,882 t-states own (0.05 %) |
| Called from | `PlayInterruptExit`, `EffectHalfLoop` |
| Calls | `EffectTickRead`, `EffectTickTest` |
| Reads | `$7F96` (`EffectTick`); `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectTickRead` (`$B36C`)

**EffectTickRead**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 993,066 calls, 14,559,330 t-states own (0.28 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 58,190 calls, 848,953 t-states own (0.20 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 60,948 calls, 889,273 t-states own (0.17 %) |
| Called from | `PlayInterruptExit`, `EffectTickCheck` |
| Calls | `EffectTickTest` |
| Reads | `$7F96` (`EffectTick`); `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectTickTest` (`$B36F`)

**EffectTickTest**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 9,788 calls, 186,470 t-states own (0.18 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 992,867 calls, 3,970,931 t-states own (0.08 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 58,192 calls, 232,754 t-states own (0.06 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 60,961 calls, 243,806 t-states own (0.05 %) |
| Called from | `PlayInterruptExit`, `EffectTickCheck`, `EffectTickRead` |
| Calls | `EventDispatch`, `EffectPeriod` (tail), `EffectTickBranch` |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectTickBranch` (`$B370`)

**EffectTickBranch**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 992,669 calls, 13,788,428 t-states own (0.26 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 58,181 calls, 832,259 t-states own (0.20 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 60,944 calls, 869,180 t-states own (0.16 %) |
| Called from | `PlayInterruptExit`, `EffectTickTest` |
| Calls | `EventDispatch`, `EffectPeriod` (tail) |
| Reads | `$FEFF`-`$FF00` (`VectorTable+255`) |

### `EffectAfterJobs` (`$B379`)

**EffectAfterJobs**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 4 calls, 157,783 t-states own (0.15 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 275 calls, 372,600 t-states own (0.01 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 19 calls, 643,985 t-states own (0.15 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 19 calls, 732,018 t-states own (0.14 %) |
| Called from | `EventAny`, `EventDone` |
| Calls | `EffectPlay` (tail), `EffectPeriod` (tail), `EffectRestore` (tail), `EffectEnd` (tail) |
| Reads | `$7F8A`-`$7F96` (`EffectState`, `SegLenA`, `SegLenB`, `PitchA` and 3 more); `$FEFF`-`$FF00` (`VectorTable+255`) |
| Writes | `$7F8B`-`$7F96` (`EffectState+1`, `SegLenA`, `SegLenB`, `PitchA` and 3 more) |

### `EffectRestore` (`$B37A`)

**EffectRestore**

| | |
| --- | --- |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 30,372 calls, 8,067,507 t-states own (0.15 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | run into, not called, 23,478 t-states own (0.01 %) |
| Called from | `PlayInterruptExit`, `EffectAfterJobs` (tail) |
| Calls | `EffectPlay` (tail), `EffectPeriod` (tail), `EffectEnd` (tail) |
| Reads | `$7F8A`-`$7F96` (`EffectState`, `SegLenA`, `SegLenB`, `PitchA` and 3 more) |
| Writes | `$7F8B`-`$7F96` (`EffectState+1`, `SegLenA`, `SegLenB`, `PitchA` and 3 more) |

### `EffectEnd` (`$B441`)

**EffectEnd**

| | |
| --- | --- |
| Runs (the first play recording: level 1 from the start, 1500 frames) | 45 calls, 1,462 t-states own (0.00 %) |
| Runs (all 12 levels, played by tools/bot.py with the developer switch `$FFD7` set, 75000 frames) | 1,941 calls, 60,442 t-states own (0.00 %) |
| Runs (tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames) | 256 calls, 7,558 t-states own (0.00 %) |
| Runs (tools/podbot.py with homing missiles to the end of level 0, 7600 frames) | 223 calls, 6,689 t-states own (0.00 %) |
| Called from | `EffectPlay` (tail), `EffectAfterJobs` (tail), `EffectRestore` (tail) |
| Calls | `EffectJobDone` |
| Writes | `$7F97` (`CurrentEffect`) |

## tune

`src/game/tune.asm`

### `TitleTune` (`$B446`)

**play the title tune until fire or a key 1-5**

DI; for each of the 7 patterns of TuneOrder: the notes until `$FF`, the length commands, the keys checked before each byte. EI and return. Called by CreditsPage (`$B0BF`). Reads `$FF1C-$FFD3`, TunePeriods, TuneDuration; ports: IN `$F7FE`, OUT `$FE` (bit 4 only: `$00`, `$10`).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 2 calls (`c1` 2) |
| Called from | `CreditsPage` |
| Calls | `TitleFireCheck` |
| Ports in | `$F7FE` |
| Ports out | `$00FE`, `$10FE` |

## start

`src/game/start.asm`

### `Start` (`$B6FF`)

**the start: the code below the screen, the complemented graphics, the main loop**

Entered by the loader's jump (`$B6FF`). DI, SP = `$5C00`; `$BC00-$C7FF` (3072 bytes) copied to `$5C00-$67FF` (the code and data the tape put above, now in their run place below `$6800`); the bytes `$E000-$E747` (1864) and `$F048-$F107` (192) complemented (the tape holds them inverted); JP MainLoop. Overwritten from `$B700` on by the playfield buffer at the first level start, so no restart comes back here (AbortGame jumps to MainLoopTitle).

| | |
| --- | --- |
| Runs | not reached in `c2`, `r1`, `zyB/w1`, `zyB/w2`; in the other recordings 1 call (`c1` 1) |
| Called from | `GameEntry` (tail) |
| Calls | `MainLoop` (tail) |
