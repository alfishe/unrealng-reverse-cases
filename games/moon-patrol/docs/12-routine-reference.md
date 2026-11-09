# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/game` (the first recording's game window). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the entries they cover. An entry no recording reached says so.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`leftover`](11-data-reference.md#leftover) | `$60F8`-`$6131` | 0 of 1 |
| [`graphicsa`](11-data-reference.md#graphicsa) | `$6132`-`$7F13` | 0 of 12 |
| [`interrupt`](#interrupt) | `$7F14`-`$7FFF` | 3 of 5 |
| [`menus`](#menus) | `$8000`-`$8865` | 29 of 41 |
| [`hiscores`](#hiscores) | `$8866`-`$8F0F` | 12 of 25 |
| [`gamestart`](#gamestart) | `$8F10`-`$9695` | 27 of 46 |
| [`course`](#course) | `$9696`-`$9B6A` | 39 of 41 |
| [`objects`](#objects) | `$9B6B`-`$9EBC` | 9 of 9 |
| [`enemies`](#enemies) | `$9EBD`-`$A4ED` | 24 of 26 |
| [`bonus`](#bonus) | `$A4EE`-`$A7CA` | 2 of 8 |
| [`play`](#play) | `$A7CB`-`$AFAA` | 40 of 45 |
| [`sprites`](#sprites) | `$AFAB`-`$B211` | 14 of 14 |
| [`variables`](11-data-reference.md#variables) | `$B212`-`$B2C1` | 0 of 74 |
| [`tables`](11-data-reference.md#tables) | `$B2C2`-`$B7E7` | 0 of 3 |
| [`courses`](#courses) | `$B7E8`-`$BEF7` | 2 of 5 |
| [`objectlist`](11-data-reference.md#objectlist) | `$BEF8`-`$C34F` | 0 of 3 |
| [`graphicsb`](11-data-reference.md#graphicsb) | `$C350`-`$EFFF` | 0 of 19 |
| [`printvars`](11-data-reference.md#printvars) | `$F000`-`$F0EF` | 0 of 17 |
| [`printing`](#printing) | `$F0F0`-`$FFFF` | 27 of 37 |

## interrupt

`src/game/interrupt.asm`

### `Im2Handler` (`$7F14`)

**The IM 2 interrupt handler: FRAMES + 1, one TunePlayer step, one Im2Clock step**

Entered from JP `$7F14` at `$FFF4` (the IM 2 vector `$FFFF`). DI, then pushes AF, BC, DE, HL, AF again (EXX does not swap AF, so AF' is never saved: neither the handler nor BEEPER uses it), BC', DE', HL', IX, IY: with the return address 22 bytes. FRAMES `$5C78` + 1, and FRAMES+2 (`$5C7A`, as IY+`$40` with the BASIC's IY = `$5C3A`) + 1 when the low word wraps. Then TunePlayer `$7F47` and Im2Clock `$7F98`, the registers back, EI, RET.

The stack: interrupted at the game's lowest SP `$C316`, the frame fills `$C300-$C315` (IY = `$5C3A` at `$C300`), CALL TunePlayer puts `$7F34` at `$C2FE`, TunePlayer's CALL BEEPER puts `$7F8D` at `$C2FC`, then CALL Im2Clock overwrites `$C2FE` with `$7F37`. So the words stage 1 saw at `$C2FC-$C311` (i1 frame 10000: `$7F8D`, `$7F37`, `$5C3A` ...) are one ordinary, non-nested frame: `$7F8D` left from the note, `$7F37` from the clock call (not the tune player call), `$5C3A` the pushed IY. `$C2FC` is the deepest the stack goes.

A nested entry is possible only at `$7F8D`: BEEPER ends EI, RET, so an interrupt still asserted when that RET ends would be taken before the DI at `$7F8D`. It would do no harm: it pushes a second frame below `$C2FC` (down to `$C2E6`), FRAMES + 1 and the clock + 1 are correct for the frame that passed, and the tune counter `$B240`, just reset to 0 by the outer pass, only goes to 1 (no second note, the tune pointer `$B23E` untouched). It does not happen (Interrupt module header; open point in the notes).

Witness: game 11 644 entries (frames 1560-16 759), a1 2090, g1 3351, p2 4612, h1 3351, i1 25 747 (264-30 439), i2 28 601, h2 288; t1 none. Each entry runs the whole body.

| | |
| --- | --- |
| Runs (the first recording's game window) | 11,644 calls, 4,298,176 t-states own (0.37 %) |
| Called from | `Im2Vector` (tail) |
| Calls | `TunePlayer`, `Im2Clock` |
| Reads | `$5C78`-`$5C79` (system) |
| Writes | `$5C78`-`$5C79` (system) |

### `TunePlayer` (`$7F47`)

**One step of the tune: every third entry the next word of the tune at `$B4E6`, a note through BEEPER or a rest**

`$B240` counts the handler's entries 0-2; on the third it goes back to 0 and one tune word is taken from the pointer `$B23E` (then pointer + 2): 0 is a rest, `$FFFF` sends the pointer back to `$B4E6` and takes the first word again, anything else is BEEPER's period + 1. With `$B288` bit 7 set (the tune off: the T key, `$AF15`) a note is a rest too, so the tune keeps its place while silent.

A note: HL = word - 1 (BEEPER's period), DE = the cycles: the smallest n with n x H >= 16 (H the period's high byte), so every note lasts about the same: 8 n (HL + 30) T. Over the tune's 16 periods (`$0230-$06CD`) that is 35 700-50 400 T, so a note started by an entry at the frame interrupt ends well inside that frame, never across the next interrupt. A rest is a delay loop of `$05C0` passes (about 38 000 T). After BEEPER (which ends EI) a DI at `$7F8D` before returning into the handler.

Witness: entered once per handler entry (i1 25 747); a word taken i1 8600 times, a note i1 7793 (BEEPER called from `$7F8A`), a rest i1 787; the tune wrapped at `$7F6D` i1 20 times, i2 22. a1: notes 341 of 626 words (the tune off 2540-2740).

| | |
| --- | --- |
| Runs (the first recording's game window) | 11,644 calls, 20,445,695 t-states own (1.77 %) |
| Called from | `Im2Handler` |
| Reads | `$B23E`-`$B240` (`TunePointer`, `TuneDivider`); `$B288` (`Player`); `$B4E6`-`$B775` (`Tune`) |
| Writes | `$B23E`-`$B240` (`TunePointer`, `TuneDivider`) |

### `Im2Clock` (`$7F98`)

**The play clock: every 50 entries the BCD seconds `$B285`/`$B286` + 1 and the HUD time marked stale**

`$B287` counts the handler's entries; at 50 it goes back to 0, `$B239` = 0 (the HUD redraws the time: `$922A`) and the BCD seconds `$B286` (low) / `$B285` (high) + 1. It counts handler entries, not frames: an interrupt that is not taken is not counted.

The branch `$7FA1-$7FAB` tests the tune counter `$B240` for 3 and would set `$B287` to 49 (the second one entry later); TunePlayer always leaves `$B240` at 0-2, so `$7FA8` never ran in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code.

Witness: one entry per handler entry; a second counted game 231 times, a1 41, i1 511, i2 570.

| | |
| --- | --- |
| Runs (the first recording's game window) | 11,644 calls, 627,326 t-states own (0.05 %) |
| Called from | `Im2Handler` |
| Reads | `$B240` (`TuneDivider`); `$B285`-`$B287` (`Player`) |
| Writes | `$B239` (`TimeShown`); `$B285`-`$B287` (`Player`) |

## menus

`src/game/menus.asm`

### `MenuEntry` (`$8000`)

**The game's entry (USR 32768): keeps the BASIC's SP at `$B25D`, then the title**

Runs once, from BASIC's USR (c1 frame 256; the stage-1 recordings start here from the entry snapshot). The SP saved at `$B25D` (`$C338` in c1) is the one every page reloads before jumping to the next, so the stack never grows over the pages, and the game never returns to BASIC.

Witness: game 1, a1 1, g1 1, t1 1, p2 1, h1 1, i1 1, i2 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 10,105 t-states own (0.00 %) |
| Calls | `MenuDelay`, `MenuCheckStart`, `MenuCheckHeroes`, `MenuCheckTape`, `MenuCheckAnyKey`, `CycleScreenColours`, `DrawPixelFrame`, `CycleFrameColours`, `ClearScreen`, `BlitRows`, `PrintText` |
| Reads | `$B25D`-`$B25E` (`BasicStack`) |
| Writes | `$B247`-`$B24A` (`BlitTop`, `BlitBottom`, `BlitX`, `BlitWidth`); `$B25D`-`$B25E` (`BasicStack`); `$F0A2` (`FontDescriptors`) |

### `TitlePage` (`$8004`)

**The title page: Moon Patrol, the copyright and the key list; 100 passes, then the options page**

SP = `$B25D`. The print variable `$F0A2` = 8, the screen cleared with attribute `$44` (`$9044`), the pixel frame (DrawPixelFrame) and its colours (CycleFrameColours). The two picture words through `$AFAB`: "Moon" from `$6132` (lines `$18-$30`, 10 bytes wide at x `$58`: `$B247`/`$B248` = `$18`/`$31`, `$B249`/`$B24A` = `$58`/`$0A`) and "Patrol" from `$622C` (lines `$37-$4F`, 14 bytes at x `$48`). Then TitleText `$8413`.

100 passes, each: MenuCheckStart (S or fire: the game), MenuCheckHeroes (H), MenuCheckTape (L, J, G), MenuCheckAnyKey (any other key: the options page), CycleScreenColours, CycleFrameColours, MenuDelay 100. Unlike the other pages it does not call MenuBreakTest. After the 100th pass it falls into OptionsPage.

Entered from MenuEntry, from HeroesPage at its end (`$81FF`) and from the abort `$AABF`. Witness: a1 2 (the start, the abort at 3190), h1 2, the others 1; the loop ran 100 passes and fell through only in t1 and h1 (`$8063`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `OptionsPage` (`$8064`)

**The options page: one or two players, the course, the controls; 100 passes, then the score advance table**

The screen cleared (attribute 0), the frame, OptionsText `$84FA`. The three normal colours of the option groups are reset (`$B25A` = 6, `$B25B` = `$46`, `$B25C` = 4) and OptionsHighlightLine marks the current choices in bright white: the players `$B257` (row `$19` + 8 x value), the course `$B258` (`$31` + 8 v), the controls `$B259` (`$49` + 8 v) and the line "S Start Game" (`$99`).

100 passes, each: MenuBreakTest (result unused), MenuCheckStart, MenuCheckHeroes, MenuCheckTape, CycleScreenColours, CycleColourRange over `$B25A-$B25C` (the un-highlight colours step through ColourCycle too, so a line un-highlighted later gets the current colour), CycleFrameColours, then one key from KEY_SCAN: a single key goes through OptionsSelect against OptionPlayerKeys (O, T), OptionCourseKeys (1, 2) and OptionControlKeys (Z X C V B K), which moves the highlight and stores the new value. MenuDelay 100. No MenuCheckAnyKey here: keys select. When the passes run out, ScoreAdvancePage.

The values (initial ones in the image): `$B257` 1 one player, 2 two players (1); `$B258` 1 Beginner, 2 Champion (1); `$B259` 1 Sinclair with 1 joystick (Z), 2 Kempston (X), 3 Cursor (C), 4 Old-type Fuller Box (V), 5 Sinclair with 2 joysticks (B), 6 Keyboard (K) (6). The play-time reading of `$B259` is `$AE17` / `$AE2C` (the table `$AE2E` indexed by `$B259` - 1); MenuCheckStart uses it for fire.

Entered from TitlePage and from MenuCheckAnyKey (`$832F`). Witness: a1 21 entries (414-21 155), t1 2, p2 1 (153-334), h1 1, i2 1 (the 2 key: Champion), game 3. a1 typed O, T, 1, 2, Z, X, C, V, B, K: OptionsSelect a1 2619 calls (537-18 573).

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 44,859 t-states own (0.00 %) |
| Called from | `MenuCheckAnyKey` (tail) |
| Calls | `OptionsHighlightLine`, `MenuDelay`, `MenuBreakTest`, `MenuCheckStart`, `MenuCheckHeroes`, `MenuCheckTape`, `CycleScreenColours`, `CycleColourRange`, `OptionsSelect`, `DrawPixelFrame`, `CycleFrameColours`, `ClearScreen`, `PrintText` |
| Reads | `$B257`-`$B25C` (`Players`, `Course`, `Controls`, `OptionColour1` and 2 more) |
| Writes | `$B257`-`$B25C` (`Players`, `Course`, `Controls`, `OptionColour1` and 2 more) |

### `ScoreAdvancePage` (`$8118`)

**The score advance table: the enemies drawn on a piece of ground with their points; 200 passes, then the demo**

Entered when OptionsPage runs out of passes. The screen cleared, the ground drawn by `$95B0` and `$9541` with `$B27D` forced to `$FF` for the drawing (then put back), three gaps cut into the ground line at row `$A0` (`$A7F4`: x `$22` 20 pixels, x `$3F` 10, x `$DE` 28), sixteen sprites from ScoreTableSprites through `$A826`, then ScoreAdvanceText `$8655` (the points in two rows: shot, jumped).

200 passes: MenuBreakTest, MenuCheckStart, MenuCheckHeroes, MenuCheckTape, MenuCheckAnyKey (any key: the options page), CycleScreenColours, MenuDelay 100. Then DemoPage.

Witness: a1 20 times, t1 once (`$8118`). The 200 passes ran out once (a1 `$8180`, about 19 800-20 800); the other 19 times a key went back to the options page.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DemoPage` (`$8180`)

**The demo: a life on the course run by the main loop for 100 passes, "DEMO" flashing; then the hi-score page**

The screen cleared, the clock zeroed (`$B285`/`$B286` = 0, `$B287` = 0), `$B27D` complemented (so successive demos alternate it), the life start `$90D3` (which sets IM 2), the tune off (`$B288` = `$80`) and `$B238` = `$80`, DemoText `$8706`.

100 passes, each one pass of the main loop's call list `$96FA`, then MenuBreakTest, MenuCheckStart, MenuCheckHeroes, MenuCheckTape, MenuCheckAnyKey (each leaves through SetIm1 `$A7CB`) and CycleColourRange over the five attributes `$58AE-$58B2` ("DEMO"). Then SetIm1 and HeroesPage.

Witness: a1 once (about 20 800, the 100 passes completed, `$81CD` 1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HeroesPage` (`$81D0`)

**The hi-score page: the heroes and the all-time heroes; 200 passes, then the title**

The screen cleared, the frame, HeroesDrawTables `$8AE0`. 200 passes: MenuBreakTest, MenuCheckStart, MenuCheckTape, MenuCheckAnyKey, CycleScreenColours, CycleFrameColours, MenuDelay 100 (no MenuCheckHeroes: H does nothing here). Then TitlePage.

Entered from MenuCheckHeroes (H), from DemoPage, from TapeLoadDone after a good load (`$831E`), and from the game over `$8F9F` after the hi-score entry. Witness: a1 2 (H at 153; the demo about 21 200), h1 1 (4524-6060), game 4; the 200 passes ran out only in h1 (`$81FE`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 620 t-states own (0.00 %) |
| Called from | `GameStart` (tail) |
| Calls | `MenuBreakTest`, `MenuCheckStart`, `MenuCheckTape`, `MenuCheckAnyKey`, `DrawPixelFrame`, `CycleFrameColours`, `HeroesDrawTables`, `ClearScreen` |

### `OptionsHighlightLine` (`$8202`)

**Marks an option line bright white: A = the value, B = the first line's pixel row**

Row = 8 A + B; LineAttrAddress, then HighlightLine28 (28 cells `$47` from the third column). Called four times by OptionsPage (the players, the course, the controls, and A = 0 for "S Start Game" at row `$99`). Witness: a1 84, game 12, t1 8, p2 4, h1 4, i2 4.

| | |
| --- | --- |
| Runs (the first recording's game window) | 12 calls, 720 t-states own (0.00 %) |
| Called from | `OptionsPage` |
| Calls | `LineAttrAddress`, `HighlightLine28` |

### `MenuDelay` (`$820D`)

**A delay of C x 256 DJNZ passes (C = 100 on the pages: about 333 000 T, near 5 frames)**

B = 0, C counted down. Called once a pass by every page and by the bonus screen `$A4EE`. Witness: a1 2327 calls, i1 142.

| | |
| --- | --- |
| Runs (the first recording's game window) | 191 calls, 63,789,269 t-states own (5.53 %) |
| Called from | `MenuEntry`, `OptionsPage` |
| Writes | `$C334`-`$C335` (`Stack`) |

### `MenuBreakTest` (`$8215`)

**Dead BREAK test: A bit 0 = 0 when CAPS SHIFT and SPACE are both held; no caller tests it**

Reads half-rows `$FE` (CAPS SHIFT) and `$7F` (SPACE), ORs them and keeps bit 0: 0 only when both keys are down. Every caller (OptionsPage, ScoreAdvancePage, DemoPage, HeroesPage, the tape message loop) goes on to its next call without looking at A or the flags, so CAPS+SPACE does nothing on the menus. It looks like the test that once led to MenuBreakToBasic `$8222`. Witness: a1 2424 calls, h1 296, t1 216.

| | |
| --- | --- |
| Runs (the first recording's game window) | 132 calls, 8,590 t-states own (0.00 %) |
| Called from | `OptionsPage`, `HeroesPage` |
| Ports in | `$7FFE`, `$FEFE` |

### `MenuBreakToBasic` (`$8222`)

**Unreferenced stub: IM 1, then RST 8 with report L (BREAK into program): back to BASIC**

CALL SetIm1 `$A7CB`, RST 8, DEFB `$14`. Nothing calls or jumps here (no operand `$8222` in the image) and no recording ran or read it (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code. With MenuBreakTest it would have made CAPS+SPACE leave the game for BASIC, a development aid left in.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MenuCheckStart` (`$8227`)

**S, or fire on the chosen joystick: IM 1 kept, SP reset, the game `$8F10`**

Half-row `$FD` alone with S (bit 1) held starts the game. Otherwise, unless the controls `$B259` are 6 (the keyboard), `$AE17` reads the chosen joystick and A = 1 (fire) starts it. Start: SetIm1 `$A7CB`, SP = `$B25D`, JP `$8F10`. Witness: called a1 2450 times; the joystick read ran game 55, a1 39 (a1 chose a joystick on the options page); the start game 5, a1 1 (1314), g1, p2, h1, i1, i2 1 each.

| | |
| --- | --- |
| Runs (the first recording's game window) | 199 calls, 15,855 t-states own (0.00 %) |
| Called from | `MenuEntry`, `OptionsPage`, `HeroesPage` |
| Calls | `GameStart` (tail), `SetIm1`, `ControlsRead` |
| Reads | `$B259`-`$B25E` (`Controls`, `OptionColour1`, `OptionColour2`, `OptionColour3` and 1 more) |
| Ports in | `$FDFE` |

### `MenuCheckHeroes` (`$8247`)

**H (half-row `$BF` bit 4): IM 1, SP reset, the hi-score page**

Witness: called a1 2365 times; taken a1 once (`$8250`, frame 153).

| | |
| --- | --- |
| Runs (the first recording's game window) | 192 calls, 8,422 t-states own (0.00 %) |
| Called from | `MenuEntry`, `OptionsPage` |
| Ports in | `$BFFE` |

### `MenuCheckTape` (`$825A`)

**L, J or G: load, save or verify the hi-score tables on tape, with ERR_SP hooked to TapeErrorHandler**

Half-row `$FD` bit 4 (G) and half-row `$BF` bits 1 (L) and 3 (J); nothing held returns. Otherwise: SP saved at `$B263`, the word at ERR_SP (where the ROM's error report returns) swapped for `$82F3` and kept at `$B265`, the keys kept at `$B23A`, then DE = `$12E` bytes, A = flag `$6C`:

L: LD_BYTES with carry set (load) into the buffer `$BEF8` (the object list, free on the menus). J: SA_BYTES from `$88AC` (the all-time tables, HiScores module), then ERR_SP put back, RET. G: LD_BYTES with carry clear (verify) against `$88AC`. When both run, L wins over J and G, and G over J.

After LD_BYTES (TapeLoadOrVerify), ERR_SP put back; carry set (the flag and the checksum good) goes to TapeLoadDone `$8309`. A failure (carry clear) prints a message: A = L, the last byte LD_BYTES read; when that was the flag byte, `$6B`, the block is a Robotron table (the flag byte Atarisoft's Robotron saves its table with) and RobotronWarningText `$873B` is printed, anything else gives TapeErrorText `$8716` "Tape error - hit any key." (TapeFailed). Then the message loop: the menu checks forever, any key goes to the options page.

Witness: t1 J (SA_BYTES 153-479), L and G (LD_BYTES 1077-2650): `$826B` 3, `$8290` 2 (not L), `$8299` 1 (J), `$82A9` 2 (L and G). LD_BYTES never returned in t1: it waits for a tape edge until SPACE is pressed (the ROM has no time-out there), and SPACE ended both with report D through TapeErrorHandler. So `$82AC-$82F2`, the failure messages and the message loop, never ran in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code.

| | |
| --- | --- |
| Runs (the first recording's game window) | 194 calls, 15,232 t-states own (0.00 %) |
| Called from | `MenuEntry`, `OptionsPage`, `HeroesPage` |
| Writes | `$C334`-`$C335` (`Stack`) |
| Ports in | `$BFFE`, `$FDFE` |

### `TapeErrorHandler` (`$82F3`)

**The ROM's error report during a tape operation returns here: wait for CAPS/SPACE up, unhook ERR_SP, back to the page**

Reached by the ROM's error exit (LD SP,(ERR_SP), RET) while MenuCheckTape has the hook in: report D (BREAK) from SA_BYTES or LD_BYTES. Waits until neither CAPS SHIFT nor SPACE (bit 0 of half-rows `$FE` and `$7F`) is held, puts the old word back at ERR_SP, reloads the SP MenuCheckTape saved at `$B263` and returns to the page that called MenuCheckTape.

Witness: t1 twice (the L and the G load stopped with SPACE, frames 1390-2670), the wait loop 65 060 instructions; no entry count because it is reached by RET.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TapeLoadDone` (`$8309`)

**A good tape block: after G (verify) back to the page; after L the buffer copied over the tables and the hi-score page**

MenuCheckTape's success path (`$82B9`). `$B23A` bit 4 clear (G held) returns. Otherwise (L) the `$12E` bytes loaded at `$BEF8` replace `$88AC-$89D9`, SP = `$B25D`, HeroesPage. The flag byte and the ROM's checksum are the only checks. Not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2; there is no tape of a saved table): known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MenuCheckAnyKey` (`$8321`)

**Any key (all half-rows at once): IM 1, SP reset, the options page**

Witness: called a1 445 times, h1 317; taken game 3, a1 21, t1 1, p2 1, i2 1 (`$8328`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 69 calls, 2,732 t-states own (0.00 %) |
| Called from | `MenuEntry`, `HeroesPage` |
| Calls | `OptionsPage` (tail), `SetIm1` |
| Reads | `$B25D`-`$B25E` (`BasicStack`) |
| Ports in | `$00FE` |

### `CycleScreenColours` (`$8332`)

**Every attribute of the screen found in ColourCycle steps to the next colour there**

`$5800-$5AFF`, each byte searched in the ten bytes of ColourCycle and replaced by the byte after it; other attributes stay. The menu texts are printed in these colours, so they change colour each pass. Witness: a1 2327 calls, h1 413.

| | |
| --- | --- |
| Runs (the first recording's game window) | 191 calls, 34,145,868 t-states own (2.96 %) |
| Called from | `MenuEntry`, `OptionsPage` |
| Reads | `$5800`-`$5AFF` (screen); `$8408`-`$8412` (`ColourCycle`) |
| Writes | `$5842`-`$5ABD` (screen); `$C334`-`$C335` (`Stack`) |

### `CycleColourRange` (`$8349`)

**As CycleScreenColours for the bytes DE to IX - 1 only**

Used by OptionsPage on its three normal colours `$B25A-$B25C`, by DemoPage on "DEMO" (`$58AE-$58B2`) and by the bonus screen `$A4EE`. Witness: a1 2103 calls, i1 125 (the bonus screens), i2 144.

| | |
| --- | --- |
| Runs (the first recording's game window) | 125 calls, 83,029 t-states own (0.01 %) |
| Called from | `OptionsPage` |
| Reads | `$8408`-`$8412` (`ColourCycle`); `$B25A`-`$B25C` (`OptionColour1`, `OptionColour2`, `OptionColour3`) |
| Writes | `$B25A`-`$B25C` (`OptionColour1`, `OptionColour2`, `OptionColour3`) |

### `OptionsSelect` (`$8360`)

**One option group: if key E is one of its B keys, highlight the new choice, un-highlight the old one, D = the new value**

IX = the group's table (records: key value, option value, pixel row), B = its records, C = the group's normal colour, D = the current value, E = the key. NZ: not this group's key. Z with D unchanged: the key's option is already chosen. Otherwise the new line goes bright white (HighlightLine28), the old value's line gets C in its 28 cells, D = the new value; the flags are those of AND A on it (NZ for every value the tables hold, 1-6), so the caller goes on to the next group.

Witness: a1 2619 calls (537-18 573), a new choice a1 10 times (`$836E`), game 2, p2 1, i2 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | 166 calls, 15,157 t-states own (0.00 %) |
| Called from | `OptionsPage` |
| Calls | `OptionsFindEntry`, `LineAttrAddress`, `HighlightLine28` |
| Reads | `$83BB`-`$83D7` (`OptionPlayerKeys`, `OptionCourseKeys`, `OptionControlKeys`) |
| Writes | `$5942`-`$595D` (screen); `$59E2`-`$59FD` (screen) |

### `OptionsFindEntry` (`$8394`)

**Searches B records of 3 bytes from HL for the byte A: Z and HL on it, or NZ (B = `$FF`)**

Witness: a1 2629 entries.

| | |
| --- | --- |
| Runs (the first recording's game window) | 168 calls, 23,215 t-states own (0.00 %) |
| Called from | `OptionsSelect` |
| Reads | `$83BA`-`$83D6` (`OptionPlayerKeys`, `OptionCourseKeys`, `OptionControlKeys`) |

### `LineAttrAddress` (`$839D`)

**HL = the attribute address of pixel row A (the line address table at `$7E00`), column 0**

Witness: a1 104 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 16 calls, 1,440 t-states own (0.00 %) |
| Called from | `OptionsHighlightLine`, `OptionsSelect` |
| Reads | `$FC42`-`$FC43` (`ScreenLineTable`); `$FC72`-`$FC73` (`ScreenLineTable`); `$FCA2`-`$FCB3` (`ScreenLineTable`); `$FCF2`-`$FCF3` (`ScreenLineTable`); `$FD32`-`$FD33` (`ScreenLineTable`) |

### `HighlightLine28` (`$83AF`)

**28 cells from HL + 2 set to `$47` (bright white on black)**

Witness: a1 94 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 14 calls, 12,939 t-states own (0.00 %) |
| Called from | `OptionsHighlightLine`, `OptionsSelect` |
| Writes | `$5882`-`$589D` (screen); `$58E2`-`$58FD` (screen); `$5942`-`$597D` (screen); `$59E2`-`$59FD` (screen); `$5A62`-`$5A7D` (screen) |

### `FrameHLine` (`$87AC`)

**Plots D pixels across from x H, row L (`$FD80` one pixel each)**

Witness: a1 400 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 144 calls, 2,047,887 t-states own (0.18 %) |
| Called from | `FrameRectangle` |
| Calls | `PlotPixel` |
| Writes | `$C328`-`$C32B` (`Stack`) |

### `FrameVLine` (`$87B7`)

**Plots D pixels down from x H, row L**

Witness: a1 400 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 144 calls, 1,513,281 t-states own (0.13 %) |
| Called from | `FrameRectangle` |
| Calls | `PlotPixel` |
| Writes | `$C32A`-`$C32B` (`Stack`) |

### `FrameRectangle` (`$87C2`)

**A rectangle inset B pixels from the left and right edges and C from the top and bottom of the 256 x 192 screen**

Top and bottom lines 256 - 2B wide, sides 192 - 2C high. Witness: a1 200 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 72 calls, 19,008 t-states own (0.00 %) |
| Called from | `FrameRectangles` |
| Calls | `FrameHLine`, `FrameVLine` |

### `FrameRectangles` (`$87F1`)

**D rectangles, each one pixel further in (B, C + 1)**

Witness: a1 200 entries (50 calls).

| | |
| --- | --- |
| Runs (the first recording's game window) | 18 calls, 4,554 t-states own (0.00 %) |
| Called from | `DrawPixelFrame` |
| Calls | `FrameRectangle` |

### `DrawPixelFrame` (`$87FC`)

**The pages' pixel frame: rectangles at insets 0-3 and 8-11, two four-pixel bands around the screen**

Called by TitlePage, OptionsPage, HeroesPage, TapeShowMessage and HiScoreEntry. Witness: a1 25, g1 2, t1 3, p2 3, h1 5, h2 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | 9 calls, 702 t-states own (0.00 %) |
| Called from | `MenuEntry`, `OptionsPage`, `HeroesPage`, `HiScoreEntry` |
| Calls | `FrameRectangles` |

### `PaintFrameAttrs` (`$880D`)

**The frame's two attribute rings: D on the outer cells (row 0, row 23, columns 0 and 31), E on the ring inside**

Witness: a1 2162 calls.

| | |
| --- | --- |
| Runs (the first recording's game window) | 212 calls, 1,120,439 t-states own (0.10 %) |
| Called from | `CycleFrameColours` |
| Writes | `$5800`-`$5A01` (screen); `$5A1E`-`$5A21` (screen); `$5A3E`-`$5A41` (screen); `$5A5E`-`$5A61` (screen); `$5A7E`-`$5A81` (screen); `$5A9E`-`$5AA1` (screen); 2 more ranges |

### `CycleFrameColours` (`$884D`)

**The frame colours one step on: `$B255` - 1 (0-7) picks a pair of FrameColourPairs for PaintFrameAttrs**

Called on every pass of TitlePage, OptionsPage, HeroesPage and the tape message, so the rings appear to move. Witness: a1 2162 calls, h1 422.

| | |
| --- | --- |
| Runs (the first recording's game window) | 212 calls, 26,288 t-states own (0.00 %) |
| Called from | `MenuEntry`, `OptionsPage`, `HeroesPage`, `HeroesDrawTables`, `HiScoreEntry` |
| Calls | `PaintFrameAttrs` |
| Reads | `$883D`-`$884C` (`FrameColourPairs`); `$B255` (`TitleColour`) |
| Writes | `$B255` (`TitleColour`) |

## hiscores

`src/game/hiscores.asm`

### `HeroesPrintRow` (`$8A4C`)

**One heroes line: rank (`$B256`), ")", the initials and the six-digit score at x D, row E; HL to the next record, E + 8**

The rank through `$9369` (B = 1, C = 6), the score through `$9367` (C = 6). Witness: a1 20 calls, h1 10.

| | |
| --- | --- |
| Runs (the first recording's game window) | 40 calls, 18,760 t-states own (0.00 %) |
| Called from | `HeroesDrawTables` |
| Calls | `PrintBcd4`, `PrintBcd`, `PrintChar` |
| Reads | `$8866`-`$88A7` (`HeroesTable`) |

### `AllTimePrintRow` (`$8A96`)

**One all-time line in the small font: rank, ")", initials, score at x D, row E; E + 6**

As HeroesPrintRow with narrower spacing and C = 4 for the print calls. Witness: a1 78 calls, h1 39.

| | |
| --- | --- |
| Runs (the first recording's game window) | 156 calls, 73,203 t-states own (0.01 %) |
| Called from | `HeroesDrawTables` |
| Calls | `PrintBcd4`, `PrintBcd`, `PrintChar` |
| Reads | `$88C9`-`$89D5` (`AllTimeTable`) |
| Writes | `$C330`-`$C331` (`Stack`) |

### `HeroesDrawTables` (`$8AE0`)

**The hi-score page's tables: heroes 1-5 and 6-10 in two columns, THE GREATEST, all-time 2-40 in three columns**

HeroesTitleText; ranks 1-5 at x `$1A` and 6-10 at x `$89` from row `$1C` (rank 10 as BCD `$10`); AllTimeTitleText, then THE GREATEST: GreatestName, its score six columns after the cursor, "(" its initials ")"; font 0, then the all-time ranks 2-`$14` at x `$14`, `$15-$27` at x `$5E`, `$28-$40` at x `$AA` from row `$59` (BCD counters); HeroesTapeKeysText; CycleFrameColours.

Called by HeroesPage only. Witness: game 4, a1 2 (174, 21 208), h1 1 (4545).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 17,968 t-states own (0.00 %) |
| Called from | `HeroesPage` |
| Calls | `CycleFrameColours`, `HeroesPrintRow`, `AllTimePrintRow`, `PrintBcd4`, `PrintChar`, `PrintText` |
| Reads | `$88C6`-`$88C8` (`GreatestInitials`); `$F000`-`$F001` (`PrintY`, `PrintX`) |
| Writes | `$B256` (`TableRow`) |

### `HiScoreEntry` (`$8B8F`)

**GAME OVER: a score for the tables asks for the initials (or THE GREATEST's name) and goes into the all-time and heroes tables**

Called by the game over `$8F9F` with the player's score at `$B272` and the player number at `$B271`. A score not over the last all-time score `$89D6` and not over the tenth hero `$88A8` returns at once. Otherwise: the screen cleared, the frame, `$93C5` and `$9136`, "CONGRATULATIONS PLAYER n"; a score over THE GREATEST's goes to GreatestEntry `$8E4E`. Else "YOU ARE AN ATARI MP HERO, PLEASE ENTER YOUR INITIALS", "3 LETTERS MAXIMUM" (the digit printed before the tail of "20 LETTERS MAXIMUM"), EntryFieldEdit with InitialsField (three letters into `$B289`).

Then the all-time table: a score over `$89D6` is placed by HiScoreFindSlot (39 records), the records below shift down 7 bytes (LDDR), the initials and score go in. Then HeroesInsert does the same for the heroes (ten records). Equal scores do not enter: the older record stays above.

Witness: entries game 4, g1 1 (4144), p2 1 (7830), h1 1 (4144-4524), h2 1 (488). The prompt: game, g1, p2, h1 (`$8BE0`); g1 and p2 never finished the initials (the scripts typed play keys, no ENTER); h1 did: all-time (`$8C1D`, place 40) and heroes (`$8C58`, place 1). game (c1's random play) entered once and only the heroes.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 1,826 t-states own (0.00 %) |
| Called from | `GameStart` |
| Calls | `DrawPixelFrame`, `CycleFrameColours`, `EntryFieldEdit`, `HiScoreFindSlot`, `ScoreCompare`, `ClearScreen`, `HudDraw`, `ClearCells`, `PrintChar`, `PrintText` |
| Reads | `$5880` (screen); `$8890`-`$88A4` (`HeroesTable`); `$8D4E`-`$8D52` (`InitialsField`); `$B250`-`$B251` (`HeroSlot`); `$B271`-`$B275` (`Player`); `$B289`-`$B28B` (`Player`) |
| Writes | `$5860` (screen); `$8890`-`$88AB` (`HeroesTable`); `$B24B`-`$B251` (`EntryLength`, `EntryBuffer`, `EntryY`, `EntryX` and 1 more) |

### `EntryFieldClear` (`$8C9C`)

**Clears ten pixel lines of 28 bytes from the field's row (`$B24E`)**

Witness: g1 121 calls, h2 11.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 8,405 t-states own (0.00 %) |
| Called from | `EntryFieldDraw` |
| Reads | `$B24E` (`EntryY`); `$FCF8`-`$FD0B` (`ScreenLineTable`) |
| Writes | `$4CE2`-`$4DFD` (screen); `$4EE2`-`$4EFD` (screen); `$4FE2`-`$501D` (screen); `$5102`-`$511D` (screen); `$5202`-`$521D` (screen); `$5302`-`$531D` (screen); 2 more ranges |

### `EntryFieldDraw` (`$8CBC`)

**Draws the field: cleared, AT x, y, its characters, a five-pixel line under the one at the cursor `$B254`**

The field descriptor is at `$B24B`: length, the buffer address, y, x (EntryFieldDescriptors). `$B252` counts the characters left, `$B253` the index. Witness: g1 121 calls, p2 615, h2 11.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 1,084 t-states own (0.00 %) |
| Called from | `EntryFieldEdit` |
| Calls | `EntryFieldClear`, `PlotPixel`, `PrintChar` |
| Reads | `$B24B`-`$B254` (`EntryLength`, `EntryBuffer`, `EntryY`, `EntryX` and 4 more); `$B289`-`$B28B` (`Player`); `$F000`-`$F001` (`PrintY`, `PrintX`) |
| Writes | `$B252`-`$B253` (`HeroCount`, `HeroIndex`) |

### `EntryFieldEdit` (`$8D0D`)

**Edits the field at `$B24B` with the ROM's LAST_K: characters, cursor left / right, DELETE; ENTER ends**

Cursor 0, FLAGS bit 3 and FLAGS2 bit 3 (CAPS LOCK: capitals) set, MODE 0. Draws the field, clears LAST_K and waits for the IM 1 handler to put a key there. ENTER returns. `$20-$5E`: stored at the cursor, cursor right (stops at the last place). 8 (cursor left): EditCursorLeft; 9 (cursor right): EditCursorRight; 12 (DELETE): EditDelete. Other codes are ignored. Typing over a longer old text leaves its tail (h2).

Witness: entries g1 1 (4172, never left: no ENTER), p2 1 (7859, never left), h1 1 (4172-4524), h2 2 (517-1141 the name, then the initials, not finished), game 1. Characters typed: g1 120, p2 614, h1 3, h2 9. The keys 8, 9 and 12 never came (`$8D5D`, `$8D7C` and the direct jump to `$8D6B` never ran in any recording: known only from the code).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 2,195,655 t-states own (0.19 %) |
| Called from | `HiScoreEntry` |
| Calls | `EntryFieldDraw` |
| Reads | `$5C08` (system); `$5C3B` (system); `$5C6A` (system) |
| Writes | `$5C08` (system); `$5C3B`-`$5C41` (system); `$5C6A` (system); `$B254` (`EntryCursor`); `$C332`-`$C333` (`Stack`) |

### `EditCursorLeft` (`$8D5D`)

**Cursor left (key 8, and after a DELETE), not below 0, then EntryFieldEdit's redraw**

Not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code. The labels below are EntryFieldEdit's other key paths.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EditCursorAddress` (`$8DA6`)

**HL = the field's buffer + the cursor `$B254`**

Witness: g1 120 calls, p2 614, h2 9.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GreatestEntry` (`$8E4E`)

**A score over THE GREATEST's: the name (20 letters, over the old one), the initials, the all-time table shifted down**

Jumped to from HiScoreEntry (`$8BDD`). Prints "YOU ARE THE GREATEST ATARI MP HERO, PLEASE ENTER YOUR NAME, 20 LETTERS MAXIMUM". The all-time records 2-39 shift down one place (the 40th is lost) and the old greatest's initials and score become number 2; its name is not kept: GreatestNameField edits GreatestName in place. Then "PLEASE ENTER YOUR INITIALS" (GreatestInitialsField into `$B289`); the score, the initials and the course point `$B27C` go to GreatestScore, GreatestInitials and GreatestPoint, and HeroesInsert puts the record into the heroes too.

Witness: h2 once (513-1141); the shift and the name ran (`$8E81` 266 bytes moved), the initials prompt was reached (the second EntryFieldEdit) but not finished, so `$8EC4-$8EE0` never ran in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HiScoreFindSlot` (`$8EE3`)

**Walks a table up from its last score HL for B records while the score DE is not less: HL = the score field of the new record's place**

Each step ScoreCompare; a record with a higher score stops the walk and the place is the one below it (HL + 7); `$B250` / `$B252` keep HL and DE. Witness: game 1, h1 2 (4524: all-time, then heroes).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1 call, 657 t-states own (0.00 %) |
| Called from | `HiScoreEntry` |
| Calls | `ScoreCompare` |
| Reads | `$B250`-`$B253` (`HeroSlot`, `HeroCount`, `HeroIndex`) |
| Writes | `$B250`-`$B253` (`HeroSlot`, `HeroCount`, `HeroIndex`) |

### `ScoreCompare` (`$8F06`)

**Compares the four BCD bytes at DE with those at HL, highest first: carry if (DE) < (HL), Z if equal**

Witness: game 16 calls, g1 2, p2 3, h1 16, h2 2.

| | |
| --- | --- |
| Runs (the first recording's game window) | 16 calls, 1,964 t-states own (0.00 %) |
| Called from | `HiScoreEntry`, `HiScoreFindSlot` |
| Reads | `$888C`-`$88AB` (`HeroesTable`); `$88C2`-`$88C3` (`GreatestScore`); `$89D6`-`$89D8` (`AllTimeTable`); `$B272`-`$B275` (`Player`) |

## gamestart

`src/game/gamestart.asm`

### `GameStart` (`$8F10`)

**The game start: both player records set, then the first life of player 1**

Entered by a JP from the options page (`$8244`) when S is pressed. Makes sure the record at `$B271` is player 1's (PlayerSwap if `$B271` holds 2), then fills both records, player 2 first (D = 2, 1): the player number, the score and the extra-life score 00010000 (`$B277` = 1), the course script `$B7E8` (Beginner, `$B27C` = 0) or `$BB24` (Champion, `$B27C` = `$20`, from the course choice `$B258`), the scenery, lamps and pointers zeroed, `$B283` = 1 (in the game), four lives, the time zeroed, and `$B288` cleared but for bit 7 (the tune off survives). A one-player game then zeroes player 2's `$B283` and lives, so the swaps after each life always come back to player 1.

GameStartLife `$8F71` is the start of every life: one life taken from the reserve (`$B284`), the screen cleared in white on black (ClearScreen `$9044`), "PLAYER n" printed (TextPlayer `$9073` and the digit) and held for 100 frames (Wait100Frames `$903D`, 300 frames in a two-player game), the screen cleared again, then LifePlay `$90CC`: the life start and the main loop until the buggy dies. It goes on at GameAfterLife `$8F9F`.

Witness: game 5 runs (1448-16318), a1 1 (1314), g1 1 (153), p2 1 (334), h1 1 (153), i1 1 (153), i2 1 (334). GameStartLife: g1 4 lives, p2 8 (four each of two players), i1 / i2 1 (immune).

| | |
| --- | --- |
| Runs (the first recording's game window) | 5 calls, 13,401 t-states own (0.00 %) |
| Called from | `MenuCheckStart` (tail) |
| Calls | `HeroesPage` (tail), `HiScoreEntry`, `PlayerSwap`, `Wait100Frames`, `ClearScreen`, `LifePlay`, `ClearCells`, `PrintChar`, `PrintText` |
| Reads | `$B257`-`$B258` (`Players`, `Course`); `$B271` (`Player`); `$B283`-`$B288` (`Player`) |
| Writes | `$B271`-`$B288` (`Player`) |

### `GameAfterLife` (`$8F9F`)

**After a life: the next player's turn, or GAME OVER, the hi-score entries and the heroes table**

Reached when LifePlay `$90CC` returns (the buggy has died: the main loop `$9696` returns after the death). With lives left the turn passes to the other player when that player is still in the game (`$B283`), else back to this one (`$8F6E` swaps the record back), and GameStartLife `$8F71` plays the next life.

No lives left: `$B283` = 0 (out of the game). One player: 8 cells cleared on rows 9 and 10 (`$484C`, `$486C`) and "GAME OVER" printed (TextGameOver `$9086`). Two players: 14 cells cleared and "GAME OVER PLAYER n" (TextGameOverPlayer `$909B` and the digit). 200 frames held. When the other player is still in the game, that player's next life is played. Else the game is over: one player, the record is put back to player 1 when needed and its hi-score entry run (`$8B8F`); two players, the entry of each player in turn. Then JP `$81D0`, the heroes table.

Witness: game 19 runs, a1 2, g1 4, p2 8, h1 4, h2 1 (the immune runs never die). GAME OVER: g1 1 (~3950), h1 1, h2 1, game 4; GAME OVER PLAYER: p2 2 (both players, the second at 7700). The two-player end GameOverBoth `$9006` ran in p2 once; the second player's entry `$9009-$900F` is not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): p2 stopped in the first entry. Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlayerSwap` (`$9022`)

**Swaps the current player record `$B271` with the other player's `$B28C` (27 bytes each, through `$B2A7`)**

`$B271` -> `$B2A7`, `$B28C` -> `$B271`, `$B2A7` -> `$B28C`, with the alternate registers so BC, DE, HL are kept. Called by GameStart (twice per record set-up), after each life and at GAME OVER, and twice by HudDraw `$9136` (to print the other player's score).

Witness: game 100 runs (1448-16320), a1 16, g1 22, p2 30, h1 22, i1 28, i2 28, h2 4.

| | |
| --- | --- |
| Runs (the first recording's game window) | 100 calls, 176,426 t-states own (0.02 %) |
| Called from | `GameStart`, `HudDraw` |
| Reads | `$B271`-`$B2C1` (`Player`, `OtherPlayer`, `SwapBuffer`) |
| Writes | `$B271`-`$B2C1` (`Player`, `OtherPlayer`, `SwapBuffer`); `$C334`-`$C335` (`Stack`) |

### `Wait100Frames` (`$903D`)

**Waits 100 frames: EI and 100 HALTs (the PLAYER n banner, GAME OVER, the bonus screen)**

Called by GameStart, GameAfterLife and the sector bonus screen `$A4EE`. Interrupts are on in IM 1 here (the ROM's handler): stage 1 of the power-on recording (WALKTHROUGH 1) is this loop resumed by the interrupt's RET.

Witness: game 28 runs (1452-16316), a1 3, g1 6, p2 28, h1 6, i1 6, i2 6, h2 2. The HALT `$9040`: 100 a call (game 2800, p2 2800, i1 600).

| | |
| --- | --- |
| Runs (the first recording's game window) | 28 calls, 192,068,004 t-states own (16.65 %) |
| Called from | `GameStart` |
| Reads | `$9041` (`Wait100Frames`) |
| Writes | `$C334`-`$C335` (`Stack`) |

### `ClearScreen` (`$9044`)

**Clears the screen: pixels to 0, the attributes to A; ATTR-P, BORDCR and the border follow A**

A = the attribute (7 white on black in the game, 0 for the title). ATTR-P `$5C8D` = A; BORDCR `$5C48` = A AND `$38` (the paper), with ink 7 added when the paper is dark (bit 5 clear); the border = the paper colour (OUT `$FE`); (`$5CC6`) = the paper colour XOR 7.

Called by the entry `$8000`, the title and menus (`$8064`, `$81D0`, `$825A`), the hi-score entry `$8B8F`, GameStart and the bonus screen `$A4EE`. Witness: game 49 runs (from 256), a1 52, g1 10, t1 4, p2 19, h1 13, i1 13, i2 14, h2 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | 49 calls, 9,158,698 t-states own (0.79 %) |
| Called from | `MenuEntry`, `OptionsPage`, `HeroesPage`, `HiScoreEntry`, `GameStart` |
| Reads | `$4000`-`$5AFF` (screen) |
| Writes | `$4000`-`$5B00` (screen); `$5C48` (system); `$5C8D` (system); `$5CC6` (system); `$C332`-`$C335` (`Stack`) |
| Ports out | `$00FE` |

### `LifePlay` (`$90CC`)

**One life: LifeStart, then the main loop until the buggy dies**

Witness: game 20 runs (1554-16323), a1 3, g1 4, p2 8, h1 4, i1 1, i2 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | 20 calls, 870 t-states own (0.00 %) |
| Called from | `GameStart` |
| Calls | `LifeStart`, `MainLoop` |

### `LifePlayDone` (`$90D2`)

**The return of LifePlay, reached when the main loop `$9696` returns after a death**

An entry of its own because h2 began in play with this address on the stack (h2: entered at 287). Witness: game 19 runs, a1 2, g1 4, p2 8, h1 4, h2 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LifeStart` (`$90D3`)

**The life start: the colours, the HUD, the backdrop, the buggy, the shots, IM 2**

SceneryColours `$95B0`, the lamps `$B27E` to 0, HudDraw `$9136`, ScenerySetup `$9541`. `$B223` = `$FF`; the buggy alive, not dying (`$B216` / `$B217` = `$FF`), its box at `$B212` = y `$92`, x `$38` (drawn at y `$89`, sprite `$00` through `$A826`). `$B237` (UFOs leave), `$B220`, `$B234`, `$B240` = 0. ShotBoxes `$9681` (21 bytes) copied to `$5B60` (the printer buffer). The ground pattern pointer `$B232` = `$A9AF` (the plain ground), `$B23E` = `$B4E6` (the tune). Four empty strings printed (`$7F00`, TextNoDate `$90B8`, `$A182`, `$B2C2`: build stamps cut off by a `$1F`). Then SetIm2 `$A7D4`: IM 2 for play.

Called by LifePlay, the title's demo `$8064` and the bonus screen `$A4EE` (after each sector). Witness: game 20 runs (1554-16323), a1 4, g1 4, p2 8, h1 4, i1 6, i2 6.

| | |
| --- | --- |
| Runs (the first recording's game window) | 20 calls, 17,915 t-states own (0.00 %) |
| Called from | `LifePlay` |
| Calls | `HudDraw`, `ScenerySetup`, `SceneryColours`, `SetIm2`, `DrawSprite`, `PrintText` |
| Reads | `$9681`-`$9695` (`ShotBoxes`) |
| Writes | `$5B60`-`$5B74` (system); `$B212`-`$B240` (`BuggyY`, `BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth` and 30 more); `$B27E` (`Player`); `$C332`-`$C333` (`Stack`) |

### `HudDraw` (`$9136`)

**Draws the HUD (rows 0-2): colours, icons, lamps, labels, scores, hi-score, TIME, POINT, the course name**

Attributes of rows 0-2 from HudAttributes `$9621`; the player icon HudPlayerIcon `$9469` at `$4000`; the HUD panel HudPanel `$9481` (64x24 pixels at x `$50`, the four buggy icons, the course marks and the progress bar frame) through `$AFAB` with `$B247` = `$1800` (lines 0-`$17`), `$B249` = `$0850` (x `$50`, 8 bytes a line); the lamp glyph HudLampGlyph `$9479` in column 27 of rows 0-2; HudTextLamps `$93D3` (DANGER! and CAUTION, ink = paper until HudLamps colours them); a few attributes of column 0 (rows 1-3).

Then HudLives `$9263`, HudLamps `$927E`, HudProgress `$92AA`; the label 1P (row 1 when two players, else row 2) and 2P (row 2), the current player's label inverted (two cells at `$4020` or `$4040`); the hi-score from the heroes table (`$88C2`, four BCD bytes at x `$10` y 1) with "-" and its point letter (`$88AC`); both players' scores (HudPrintScore `$92DA`, PlayerSwap, again, PlayerSwap); TIME and POINT (HudTextTimePoint `$93FF`) and the point letter (HudPrintPoint `$9247`); BEGINNER or CHAMPION from bit 5 of `$B27C` after 7 cells cleared at `$4053`; the time (HudPrintTime `$922A`, its flag `$B239` cleared first).

Called by LifeStart, the hi-score entry `$8B8F`, the bonus screen `$A4EE` and the course switches `$BB07` / `$BED4`. Witness: game 21 runs (1554-16321), a1 4, g1 5, p2 9, h1 5, i1 12, i2 12, h2 1. 2P and the inverted label: p2 only (`$93F9` read 9 times in p2).

| | |
| --- | --- |
| Runs (the first recording's game window) | 21 calls, 93,771 t-states own (0.01 %) |
| Called from | `HiScoreEntry`, `LifeStart` |
| Calls | `PlayerSwap`, `HudPrintTime`, `HudPrintPoint`, `HudPrintPointLetter`, `HudLives`, `HudLamps`, `HudProgress`, `HudPrintScore`, `PrintBcd4`, `ClearCells`, `BlitRows`, `PrintChar`, `PrintText` |
| Reads | `$88AC` (`GreatestPoint`); `$9469`-`$9480` (`HudPlayerIcon`, `HudLampGlyph`); `$9621`-`$9680` (`HudAttributes`); `$B257` (`Players`); `$B27C` (`Player`) |
| Writes | `$4000`-`$4001` (screen); `$401B`-`$405B` (screen); `$4100`-`$4101` (screen); `$411B`-`$415B` (screen); `$4200`-`$4201` (screen); `$421B`-`$425B` (screen); 13 more ranges |

### `HudPrintTime` (`$922A`)

**Prints the time `$B285-$B286` (4 digits at x `$B3` y 1) once after each clock change**

Does nothing while the flag `$B239` is non-zero; the clock `$7F98` clears it. Then sets it, clears 3 cells at `$4017` and prints the two BCD bytes of the time (`$9369`, 6 pixels a digit).

Called once a main-loop pass (`$96FA`) and by HudDraw. Witness: game 1597 runs, a1 296, g1 498, p2 673, h1 498, i1 3613, i2 3947, h2 41. Printing (`$9230`): i1 523 times, about once a second of play.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,597 calls, 74,664 t-states own (0.01 %) |
| Called from | `HudDraw`, `MainLoopCalls` |
| Calls | `PrintBcd`, `ClearCells` |
| Reads | `$B239` (`TimeShown`) |
| Writes | `$B239` (`TimeShown`) |

### `HudPrintPoint` (`$9247`)

**Prints the letter of the point reached (`$B27C`) on the HUD after POINT**

One cell cleared at `$4038`, the position from HudTextPointAt `$9427` (x `$C2` y 9, font 2), then falls into HudPrintPointLetter with A = `$B27C`.

Called by HudDraw and when a point is passed (ObjPoint `$9980`). Witness: game 21 runs, a1 4, g1 5, p2 9, h1 5, i1 37 (12 HUD draws + 25 points), i2 39, h2 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | 21 calls, 1,554 t-states own (0.00 %) |
| Called from | `HudDraw` |
| Calls | `HudPrintPointLetter`, `ClearCells`, `PrintText` |
| Reads | `$B27C` (`Player`) |

### `HudPrintPointLetter` (`$9258`)

**Prints the point letter of A: bits 0-4 the point number, 1 = A, O skipped**

A AND `$1F`, then `$40` added, plus 1 from 15 on: 1-14 are A-N, 15-25 are P-Z ('O' is no point). 0 prints '@' (no point passed yet). Called by HudPrintPoint, HudPrintScore (the score's point letter), HudDraw (the hi-score's) and the bonus screen `$A4EE`. Witness: game 88 runs, i1 382, i2 519.

| | |
| --- | --- |
| Runs (the first recording's game window) | 88 calls, 4,576 t-states own (0.00 %) |
| Called from | `HudDraw`, `HudPrintPoint`, `HudPrintScore` (tail) |
| Calls | `PrintChar` |

### `HudLives` (`$9263`)

**Shows the lives in reserve (`$B284`) as buggy icons: up to four, colour pairs at `$580A-$5811`**

Four pairs of cells on row 0 (columns 10-17, the icons of HudPanel): a pair whose index is below the lives gets attribute `$1F` (white on magenta, seen), the others `$1B` (ink = paper, hidden). Called by HudDraw and by ScoreAddBcd `$9311` when an extra life is given. Witness: game 21 runs, i1 14 (12 HUD draws + the two extra lives at 10000 and 30000), i2 15.

| | |
| --- | --- |
| Runs (the first recording's game window) | 21 calls, 6,570 t-states own (0.00 %) |
| Called from | `HudDraw` |
| Reads | `$B284` (`Player`) |
| Writes | `$580A`-`$5811` (screen) |

### `HudLamps` (`$927E`)

**Colours the warning lamps from `$B27E` (0-3): 3 rows of 5 attributes at `$581B` from HudLampColours**

The pattern is HudLampColours + 15 x (`$B27E` AND 3): column 27 the lamp, columns 28-31 the text. 0 lights the bottom lamp green; 1 the middle lamp yellow and CAUTION white; 2 the top lamp red and DANGER! white; 3 both, red and yellow. Called by HudDraw and by the lamp object ObjLamps `$99A3`. Witness: game 21 runs, i1 36, i2 41; the patterns read (HudLampColours reads) in i1: 0 15 times, 1 13, 2 6, 3 2; in i2: 13, 10, 10, 8.

| | |
| --- | --- |
| Runs (the first recording's game window) | 21 calls, 17,940 t-states own (0.00 %) |
| Called from | `HudDraw` |
| Reads | `$942D`-`$943B` (`HudLampColours`); `$B27E` (`Player`) |
| Writes | `$581B`-`$581F` (screen); `$583B`-`$583F` (screen); `$585B`-`$585F` (screen) |

### `HudProgress` (`$92AA`)

**Plots the course progress bar: a 2x2 dot every 2 pixels from x `$57` to 2 x point + `$56`, y `$13`**

Nothing at point 0. Uses HudPlot `$92CD` (the OR plot `$FD80`, H = x, L = y). Called by HudDraw and when a point is passed (ObjPoint). Witness: game 21 runs, i1 37, i2 39; the dots (`$92CD`) i1 1900.

| | |
| --- | --- |
| Runs (the first recording's game window) | 21 calls, 651 t-states own (0.00 %) |
| Called from | `HudDraw` |
| Reads | `$B27C` (`Player`) |

### `HudPlot` (`$92CD`)

**Plots one pixel at H = x, L = y (`$FD80`), keeping HL**

Witness: i1 1900 runs, i2 1912 (only from HudProgress, no dots at point 0).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScoreAdd` (`$92D3`)

**Adds DEBC (8 BCD digits) to the score, gives the extra lives, prints the score**

ScoreAddBcd `$9311`, then HudPrintScore `$92DA`. The values the callers pass (BC, DE = 0): 100 the rock shot or hit (ObjRock `$9A21`), 80 the rock jumped (`$9A3E`), 100 the crater jumped (`$9AD8`), 50 the mine jumped (`$9B36`), 25 the kill `$A7DD`; the other handlers from `$9B6B` on (annotator 03) and the bonus `$A4EE` pass their own.

Witness: game 25 runs (2029-16149), a1 4, g1 16, p2 16, h1 16, i1 291, i2 424, h2 3.

| | |
| --- | --- |
| Runs (the first recording's game window) | 25 calls, 1,100 t-states own (0.00 %) |
| Called from | `ObjRock`, `ObjCrater`, `BuggyKill` |
| Calls | `HudPrintScore`, `ScoreAddBcd` |

### `HudPrintScore` (`$92DA`)

**Prints the current player's score at x `$10` (row 1 for player 1 of two, else row 2), "-", the point letter**

E = y: `$11` (row 2), or 9 (row 1) for player 1 of a two-player game; the record of player 2 in a one-player game prints nothing. 8 cells cleared at `$4022` or `$4042`, the 8 digits (`$9364`, 6 pixels apart, leading zeros blank), "-", the point letter of `$B27C`. Witness: game 67 runs, a1 12, g1 26, p2 34, h1 26, i1 340, i2 475, h2 5. Player 1 of two (`$92EB`): p2 34.

| | |
| --- | --- |
| Runs (the first recording's game window) | 67 calls, 10,737 t-states own (0.00 %) |
| Called from | `HudDraw`, `ScoreAdd` |
| Calls | `HudPrintPointLetter` (tail), `HudPrintScoreDigits`, `ClearCells`, `PrintChar` |
| Reads | `$B257` (`Players`); `$B271`-`$B27C` (`Player`) |

### `ScoreAddBcd` (`$9311`)

**Adds DEBC to the score `$B272-$B275` (BCD) and gives an extra life each time it passes `$B276-$B279`**

C to `$B275`, B to `$B274`, E to `$B273`, D to `$B272`, each with DAA and the carry. Below 60000 points (`$B273` < 6) the score is compared with the extra-life score `$B276-$B279`: when reached, a life is added (`$B284`), HudLives shows it, and the extra-life score goes up 20000 (`$B277` + 2). The extra lives: 10000, 30000, 50000; none from 60000 on.

Witness: game 25 runs, i1 291, i2 424; the extra life (`$9344-$935D`) i1 2, i2 3. The carry into the top byte (`$932C`) and the carry of the extra-life score into `$B276` (`$935E-$9363`) are not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code.

| | |
| --- | --- |
| Runs (the first recording's game window) | 25 calls, 6,320 t-states own (0.00 %) |
| Called from | `ScoreAdd` |
| Reads | `$B272`-`$B277` (`Player`) |
| Writes | `$B272`-`$B275` (`Player`) |

### `HudPrintScoreDigits` (`$9364`)

**HL = the score `$B272`: falls into PrintBcd4**

Witness: game 46 runs, i1 328, i2 463.

| | |
| --- | --- |
| Runs (the first recording's game window) | 46 calls, 460 t-states own (0.00 %) |
| Called from | `HudPrintScore` |
| Calls | `PrintBcd4` |

### `PrintBcd4` (`$9367`)

**Prints 4 BCD bytes (8 digits) from HL: B = 4, then PrintBcd**

Also called by the hi-score tables (`$8A4C`, `$8A96`, `$8AE0`) and HudDraw. Witness: game 267 runs, a1 112, i1 340, i2 475.

| | |
| --- | --- |
| Runs (the first recording's game window) | 267 calls, 1,869 t-states own (0.00 %) |
| Called from | `HeroesPrintRow`, `AllTimePrintRow`, `HeroesDrawTables`, `HudDraw`, `HudPrintScoreDigits` |
| Calls | `PrintBcd` |

### `PrintBcd` (`$9369`)

**Prints B BCD bytes from HL at x D y E, C pixels a digit, leading zeros left blank (the last digit always shown)**

Each digit goes out as `$16` x y and the character through `$FDCC`. Called by PrintBcd4, HudPrintTime and the hi-score tables. Witness: routine entries game 711, a1 255, g1 96, p2 142, h1 195, i1 1017, i2 1248, h2 11 (PrintBcd4 falls into it, the time print calls it).

| | |
| --- | --- |
| Runs (the first recording's game window) | 711 calls, 418,246 t-states own (0.04 %) |
| Called from | `HeroesPrintRow`, `AllTimePrintRow`, `HudPrintTime`, `PrintBcd4` |
| Calls | `PrintChar`, `Im2Vector` |
| Reads | `$8869`-`$88AB` (`HeroesTable`); `$88C2`-`$89D9` (`GreatestScore`, `GreatestInitials`, `AllTimeTable`); `$B256` (`TableRow`); `$B272`-`$B286` (`Player`) |
| Writes | `$C32A`-`$C32D` (`Stack`) |

### `ClearCells` (`$93C5`)

**Clears C cells from the screen address HL (8 pixel lines each)**

Witness: game 345 runs, a1 61, g1 104, p2 156, h1 104, i1 1035, i2 1268, h2 15.

| | |
| --- | --- |
| Runs (the first recording's game window) | 345 calls, 346,897 t-states own (0.03 %) |
| Called from | `HiScoreEntry`, `GameStart`, `HudDraw`, `HudPrintTime`, `HudPrintPoint`, `HudPrintScore` |
| Writes | `$4000`-`$4873` (screen); `$494C`-`$4973` (screen); `$4A4C`-`$4A73` (screen); `$4B4C`-`$4B73` (screen); `$4C4C`-`$4C73` (screen); `$4D4C`-`$4D73` (screen); 3 more ranges |

### `ScenerySetup` (`$9541`)

**The backdrop: the mountains or the city for `$B27D`, drawn on rows 8-11 and the scroll pointers set**

Mountains (`$B27D` = 0): `$B22C` = `$E340`, `$B22E` = `$E780`, `$B22A` = `$E720`; the city: `$E780`, `$EBC0`, `$EB60`. `$B228` / `$B224` = 0, `$B226` = `$EFA0`. Draws 4 rows of 32 columns from `$EBC0` at `$4800` (rows 8-11) and 4 rows from (`$B22C`) at `$4880` (rows 12-15) with SceneryDrawRows `$9590`, then copies 32 bytes from the ROM at `$2000` to the pixel line `$5080` (row 20). The scrollers that use these pointers are the main loop's (`$A846`, `$A89A` ...).

Called by LifeStart and the title `$8064` (with `$B27D` = `$FF`). Witness: game 20 runs, a1 24, g1 4, t1 1, p2 8, h1 4, i1 6, i2 6. The city: game 0, i1 2 (the sectors from F and Q).

| | |
| --- | --- |
| Runs (the first recording's game window) | 20 calls, 19,240 t-states own (0.00 %) |
| Called from | `LifeStart` |
| Calls | `SceneryDrawRows` |
| Reads | `$B22C`-`$B22D` (`MiddleStart`); `$B27D` (`Player`) |
| Writes | `$5080`-`$509F` (screen); `$B224`-`$B22F` (`FarCountdown`, `HillsSpeed`, `FarColumn`, `MiddleCountdown` and 4 more) |

### `SceneryDrawRows` (`$9590`)

**Draws 32 columns x 4 rows of 8 lines from DE (column by column) at the screen address HL**

Witness: game 40 runs, i1 12 (two calls each ScenerySetup).

| | |
| --- | --- |
| Runs (the first recording's game window) | 40 calls, 1,917,788 t-states own (0.17 %) |
| Called from | `ScenerySetup` |
| Reads | `$E340`-`$E73F` (`MountainsStrip`); `$EBC0`-`$EFBF` (`HillsStrip`) |
| Writes | `$4800`-`$4FFF` (screen); `$C32C`-`$C32F` (`Stack`) |

### `SceneryColours` (`$95B0`)

**Picks the scenery colour set (`$B27D`: SceneryColourSets `$9617` or `$961C`) and paints rows 3-23**

`$B230` = the set. Rows 3-7 = set +0, 12-15 = +2, 16-19 = +3, 20-21 = +4, then SceneryColoursRepaint: rows 8-11 = +1, rows 22-23 = +4 paper only. Called by LifeStart and the title `$8064`. Witness: game 20 runs, a1 24, t1 1, i1 6, i2 6; the city set (`$95B9`) a1 21, i1 2, i2 2.

| | |
| --- | --- |
| Runs (the first recording's game window) | 20 calls, 248,832 t-states own (0.02 %) |
| Called from | `LifeStart` |
| Calls | `SceneryColoursRepaint` |
| Reads | `$5860`-`$58FF` (screen); `$5980`-`$5ABF` (screen); `$9617`-`$961B` (`SceneryColourSets`); `$B27D` (`Player`) |
| Writes | `$5860`-`$5900` (screen); `$5980`-`$5AC0` (screen); `$B230`-`$B231` (`ColourScheme`) |

### `SceneryColoursRepaint` (`$95F2`)

**Paints rows 8-11 with the set's colour +1 and rows 22-23 with the paper of +4, every main-loop pass**

Called once a pass from MainLoopCalls `$96FA` (so the colours the sprites leave there are wiped) and by SceneryColours. Witness: game 1596 runs, a1 315, g1 497, p2 672, h1 497, i1 3606, i2 3940, h2 40.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,596 calls, 8,333,974 t-states own (0.72 %) |
| Called from | `SceneryColours`, `MainLoopCalls` |
| Calls | `Im2Vector` |
| Reads | `$5900`-`$597E` (screen); `$5AC0`-`$5AFF` (screen); `$9618`-`$961B` (`SceneryColourSets`); `$B230`-`$B231` (`ColourScheme`) |
| Writes | `$5900`-`$597F` (screen); `$5AC0`-`$5B00` (screen); `$C32E`-`$C32F` (`Stack`) |

## course

`src/game/course.asm`

### `MainLoop` (`$9696`)

**The main loop of a life or a sector: reads a course segment when its time is up, runs the call list**

Saves SP at `$B25F` (the bonus screen `$A4EE` and the course switches `$BB07` / `$BED4` come back here with LD SP,(`$B25F`) / JP `$9696`), enables the object list (`$B238` = 0), starts it at `$BEF8` (`$B261` the write pointer) and sets the restart pointer `$B27F` to the course pointer `$B27A`. Then MainLoopSegment `$96AA` reads the next segment (CourseRun `$9751` with DE = the write pointer) and MainLoopPass runs MainLoopCalls.

MainLoopPass `$96BB`: when the buggy's death has run its course (`$B216` = 8): the last frame erased (sprite `$26` at y - 9), `$B216` / `$B217` = `$FF`, the course pointer back to the restart point `$B27F`, SetIm1 `$A7CB`, and RET: the life is over (LifePlay `$90CC` returns). Else the pass counter `$B23B` goes down by 1 and the segment time `$B23C` by 1; at 0 the segment start `$B281` = the course pointer and the next segment is read.

One pass has no frame sync: 3601 passes in about 30 175 frames of i1 (WALKTHROUGH 1). Witness: game 20 runs (1559-16753), a1 3, g1 4, p2 8, h1 4, i1 7, i2 7 (the life start, five bonus screens, the course switch); segments read (`$96AA`) i1 37, i2 40; deaths (`$96C5`) game 19, a1 2, g1 4, p2 8, h1 4, h2 1.

| | |
| --- | --- |
| Runs (the first recording's game window) | 20 calls, 206,769 t-states own (0.02 %) |
| Called from | `LifePlay` |
| Calls | `MainLoopCalls`, `CourseRun`, `SetIm1`, `DrawSprite`, `Im2Vector` |
| Reads | `$B212`-`$B216` (`BuggyY`, `BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth` and 1 more); `$B23B`-`$B23D` (`PassCount`, `SegmentWait`); `$B261`-`$B262` (`ObjectWrite`); `$B27A`-`$B280` (`Player`) |
| Writes | `$B216`-`$B217` (`DeathStep`, `WreckStep`); `$B238`-`$B23D` (`ObjectsOff`, `TimeShown`, `TapeKey`, `PassCount` and 1 more); `$B25F`-`$B262` (`LoopStack`, `ObjectWrite`); `$B27A`-`$B282` (`Player`); `$C332`-`$C333` (`Stack`) |

### `MainLoopPass` (`$96BB`)

**MainLoopPass**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MainLoopCalls` (`$96FA`)

**The call list of one main-loop pass: keys, the buggy, shots, scrollers, objects, ground, hold**

In order: the tune key `$AF15`, BreakKeyTest `$9737` (result ignored), `$ACF1`, HudPrintTime `$922A`, `$A846`, `$AAD3`, `$AA0F`, `$AB37`, `$AD61`, ObjectListRun `$9745`, SceneryColoursRepaint `$95F2`, `$AB37`, `$A8FD`, `$A89A`, `$AB37`, `$AF31`, the ground `$A932`, the hold key `$AECE`, `$AB37`, `$AF31`.

Called by MainLoopPass and the title's demo `$8064`. Witness: game 1576 runs (1559-16757), a1 292, g1 493, p2 664, h1 493, i1 3601, i2 3935, h2 40.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 551,634 t-states own (0.05 %) |
| Called from | `MainLoop` |
| Calls | `HudPrintTime`, `SceneryColoursRepaint`, `BreakKeyTest`, `ObjectListRun`, `ScrollFarBand`, `ScrollMiddleBand`, `ScrollNearBand`, `ScrollRoad`, `BuggyUpdate`, `BuggyErase`, `WheelsFly`, `FireShots`, `ShotsMove`, `HoldCheck`, `TuneToggleCheck`, `SpeedGovernor`, `Im2Vector` |

### `BreakKeyTest` (`$9737`)

**Reads the key '0' (row `$EFFE`): returns NZ when it is pressed; the caller ignores it**

IN of port `$EFFE`, OR `$FE`, INC A: Z when '0' is up. MainLoopCalls never tests the flag, and the stub CourseBreakToBasic `$9740` after it is never called: a debug exit left in (a1 pressed '0', nothing happened). Witness: game 1576 runs, a1 292, i1 3601, i2 3935.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 68,603 t-states own (0.01 %) |
| Called from | `MainLoopCalls` |
| Calls | `Im2Vector` |
| Writes | `$C32E`-`$C32F` (`Stack`) |
| Ports in | `$EFFE` |

### `ObjectListRun` (`$9745`)

**Runs the object list at `$BEF8` once (CourseRun), unless `$B238` is set**

`$B238` = 0 at MainLoop; the title's demo sets it to `$80` (`$819E`): the demo runs without objects. Witness: game 1576 runs, a1 291, g1 493, p2 664, h1 493, i1 3601, i2 3934, h2 40.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 93,098 t-states own (0.01 %) |
| Called from | `MainLoopCalls` |
| Calls | `CourseRun`, `Im2Vector` |
| Reads | `$B238` (`ObjectsOff`) |
| Writes | `$C32E`-`$C32F` (`Stack`) |

### `CourseRun` (`$9751`)

**The interpreter of the course script and the object list: runs the routine at the word (HL), HL past it**

IX = the word, HL += 2, CourseRun pushed as the return address, JP (IX). Each routine leaves HL past its data and returns into CourseRun, which runs the next word; the end word `$975E` (ListStop) pops that return and RETs to CourseRun's caller. Called by MainLoop (the script: DE = the object list write pointer, HL = the course pointer) and ObjectListRun (HL = `$BEF8`).

Witness: game 8038 runs, a1 967, g1 2799, p2 3352, h1 2799, i1 89827, i2 123263, h2 200.

| | |
| --- | --- |
| Runs (the first recording's game window) | 8,038 calls, 643,344 t-states own (0.06 %) |
| Called from | `MainLoop`, `ObjectListRun`, `SegmentLength`, `CmdPoint`, `CmdLamps`, `CmdRocks`, `CmdCraters`, `CmdUfos`, `ObjPoint`, `ObjLamps`, `ObjRockDone`, `ObjCraterDone`, `UfoRecordSkip` |
| Calls | `ListStop`, `SegmentEnd`, `SegmentLength`, `CmdPoint`, `CmdLamps`, `CmdRocks`, `CmdCraters`, `CmdUfos1`, `CmdUfos5`, `ObjPoint`, `ObjLamps`, `ObjRock`, `ObjRockExplode`, `ObjRockDone`, `ObjCrater`, `ObjCraterDone`, `UfoHandler`, `Im2Vector` |
| Reads | `$B7E8`-`$B810` (`BeginnerCourse`); `$BEF8`-`$BF19` (`ObjectList`); `$BF2C`-`$BF2D` (`ObjectList`); `$BF40`-`$BF41` (`ObjectList`); `$BF54`-`$BF55` (`ObjectList`); `$BF68`-`$BF69` (`ObjectList`) |
| Writes | `$C32C`-`$C32D` (`Stack`) |

### `ListStop` (`$975E`)

**The end of a list: drops CourseRun's return address and returns to its caller**

The word `$975E` ends the object list (SegmentEnd writes it). Witness: game 1598 runs, i1 3631, i2 3968 (the ends of the object-list passes, and SegmentEnd's JP).

| | |
| --- | --- |
| Runs (the first recording's game window) | 22 calls, 31,960 t-states own (0.00 %) |
| Called from | `CourseRun`, `SegmentEnd` (tail) |

### `SegmentEnd` (`$9760`)

**Script command: the end of a segment; writes the list end `$975E` at the write pointer (DE) and stops**

DE is not advanced: the next segment's objects go over the end word. Witness: game 22, a1 3, g1 6, p2 8, h1 6, i1 31, i2 34 (every segment read).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 1,188 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `ListStop` (tail) |
| Writes | `$BF10`-`$BF11` (`ObjectList`); `$BF68`-`$BF69` (`ObjectList`) |

### `SegmentLength` (`$976C`)

**Script command (word): the segment's time in main-loop passes into `$B23C`**

Every segment starts with it: `$7F` (127) passes, 63 or 64 in the short point segments before a sector end. Witness: as SegmentEnd: i1 31, i2 34.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 1,232 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CourseRun` |
| Reads | `$B7EA`-`$B7FB` (`BeginnerCourse`) |
| Writes | `$B23C`-`$B23D` (`SegmentWait`) |

### `CmdPoint` (`$9775`)

**Script command (delay, point): appends the point object ObjPoint and prints the coming point's letter at the bottom right**

Record: `$9978`, the delay, the point byte (bits 0-4 the point number, bit 5 the Champion course). Prints TextPointAt `$97A7` (x `$F9` y `$B1`, font 2) and the letter (the code of HudPrintPointLetter inlined), then inverts the cell at `$50DF` (row 22, column 31): the letter shows in reverse until ObjPoint passes it. The delay is `$3F` (63), or `$3E` in the segment before a sector end.

Witness: game 2 runs (8345-16173), g1 2, h1 2, i1 25 (A 1123 ... Z 28136: every Beginner point), i2 28 (the 25 Champion points and A-C of Beginner after the loop).

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 1,074 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CourseRun`, `PrintChar`, `PrintText` |
| Reads | `$50DF` (screen); `$51DF` (screen); `$52DF` (screen); `$53DF` (screen); `$54DF` (screen); `$55DF` (screen); 3 more ranges |
| Writes | `$50DF` (screen); `$51DF` (screen); `$52DF` (screen); `$53DF` (screen); `$54DF` (screen); `$55DF` (screen); 3 more ranges |

### `CmdLamps` (`$97AD`)

**Script command (delay, value pairs to `$FF`): appends warning-lamp objects ObjLamps**

Record: `$99A3`, the delay, the lamp value (0-3, HudLamps). Each point segment sets the lamps for what follows: 1 (CAUTION) with the UFO waves, 2 (DANGER!) with the CmdUfos11 waves and the boulders of Champion C and M, 3 with the low flyers from behind (Champion A, the segment after sector end P, Z) and a few mixed points (Beginner Y, Champion S, Y), 0 (all clear) in most points before a sector end (Beginner E, I, P, U; Champion E, J, P). Witness: game 2, g1 2, h1 2, i1 21, i2 27.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 328 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CourseRun` |
| Reads | `$B802`-`$B804` (`BeginnerCourse`) |
| Writes | `$BF14`-`$BF17` (`ObjectList`) |

### `CmdRocks` (`$97C5`)

**Script command (a delay a rock to `$FF`): appends rock objects ObjRock**

Record (8 bytes): `$99C3`, the delay, sprite `$0F`, y `$94`, x `$F4` (off the right edge: not drawn yet), height `$0C`, width `$0C`. Witness: game 20 runs (1559-16323), a1 3, g1 4, p2 8, h1 4, i1 13 (first 263: the start segment, two rocks), i2 16.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 7,720 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CourseRun` |
| Reads | `$B7F3`-`$B7F5` (`BeginnerCourse`) |
| Writes | `$BF00`-`$BF0F` (`ObjectList`) |

### `CmdCraters` (`$97E8`)

**Script command (a delay a crater to `$FF`): appends crater objects ObjCrater**

Record (4 bytes): `$9A92`, the delay, x 0 (the right edge, before the first move). Witness: game 20 runs, a1 3, g1 4, p2 8, h1 4, i1 16 (first 263), i2 9.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 5,160 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CourseRun` |
| Reads | `$B7EE`-`$B7F0` (`BeginnerCourse`) |
| Writes | `$BEF8`-`$BEFF` (`ObjectList`) |

### `CmdMines` (`$97FF`)

**Script command (a byte a mine to `$FF`: bits 0-6 the delay, bit 7 the blink phase): appends mine objects ObjMine**

Record (6 bytes): `$9AEB`, the delay, the phase (`$00` or `$80`; the sprite goes in its low bits), y `$A0`, x `$F8` (not drawn yet). Witness: i1 3 runs (11800-13545: the segment after sector end J, K, L), i2 5 (12337-28217); no other recording reaches the mines.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdUfos1` (`$9821`)

**Script command (a delay a UFO to `$FF`): UFO objects of type 1 (`$9B6B`), any height**

A' = 1 the type, `$B236` = 0; on at CmdUfos `$9832`. Witness: game 2, g1 2, h1 2, i1 10, i2 10.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 54 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CmdUfos` (tail) |

### `CmdUfos5` (`$9827`)

**Script command: UFO objects of type 5 (`$9B6B`), any height**

Witness: game 2, g1 2, h1 2, i1 10, i2 10.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 54 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CmdUfos` (tail) |

### `CmdUfos11` (`$982D`)

**Script command: UFO objects of type `$0B` (`$9B6B`), `$B236` = `$FF`: start no lower than y `$30`, bit 3 in field +9**

Witness: i1 6 (3828-27176: points D, H, M, T, X, Y), i2 7. The lamp set with these waves is 2 (DANGER!) at D, H, M, T, X; Y sets 3.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdUfos` (`$9832`)

**The UFO spawner: a 20-byte record per data byte, `$9B6B` with the type, a random start side and height**

Record: +0 `$9B6B`, +2 the delay, +3 the type, +4 `$FF`, +5 0, +6 dx (+2 from the left, -2 from the right), +7 y = (R XOR FRAMES) AND `$1F` + `$18` (capped to `$30` for CmdUfos11), +8 x = 0 or `$F0` (bit 6 of R XOR FRAMES), +9 8 or `$10` (`$B236` AND 8 + 8), +10 `$0F`, +11 R AND `$1F` + `$10`, +12 `$1D`, +13 `$FF`, +14 4, +15 4, +18 5, +19 5 (+16, +17 not written). What the handler `$9B6B` makes of the fields from +9 on is annotator 03's.

Witness: game 4 runs, g1 4, h1 4, i1 26, i2 27; the cap to y `$30` (`$9868`) i1 2, i2 6.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4 calls, 4,423 t-states own (0.00 %) |
| Called from | `CmdUfos1` (tail), `CmdUfos5` (tail) |
| Calls | `CourseRun` |
| Reads | `$5C78` (system); `$B236` (`UfoWave`); `$B807`-`$B80E` (`BeginnerCourse`) |
| Writes | `$B236` (`UfoWave`); `$BF18`-`$BF67` (`ObjectList`) |

### `CmdUfosLeave` (`$98AA`)

**Script command (a delay to `$FF`): appends `$9EA5`, which sets `$B237` when its delay is out: the UFOs fly off**

Record (3 bytes): `$9EA5`, the delay. `$9EA5` (annotator 03) sets `$B237` = `$FF`; the UFO handler `$9B6B` then moves each UFO 4 pixels a pass to the nearer edge and removes it off screen (`$9BE6`), and a new wave clears `$B237` (`$9B99`). In the script it comes after each UFO part of the course (points C, E, H, I, P, U, Y, Z of Beginner). Witness: i1 8 runs (2935-28136), i2 11.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdTanks` (`$98BE`)

**Script command (a delay to `$FF`): appends tank objects `$9EBD` (15 bytes)**

Record: `$9EBD`, the delay, `$13`, `$8F`, `$E7`, `$11`, `$14`, `$08`, `$00`, `$93`, `$C1`, `$03`, `$07`: by the shape the tank's sprite `$13`, y `$8F`, x `$E7`, box `$11` x `$14`, then a second sprite / box (y `$93`, x `$C1`, 3 x 7: its shell); the handler is annotator 03's (scores 250 / 200). Witness: i1 4 runs (23662-27176: the segment after sector end U, points V, W, Y), i2 9.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdFlyers` (`$98F3`)

**Script command (a delay to `$FF`): appends low flyer objects `$A03B` (Champion only)**

Record (9 bytes): `$A03B`, the delay, `$14`, (+4 not written), y `$91`, x 0 (from the left: behind the buggy), `$08`, `$0C`. Witness: i2 3 runs (1352-29178: Champion A, the sector after P, Z).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdBoulders40` (`$9917`)

**Script command: small boulders (sprite `$40`, 8x8) for `$A196`**

Witness: i2 3 runs (3117-28218).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdBoulders44` (`$991C`)

**Script command: medium boulders (sprite `$44`, 12x12)**

Witness: i2 5 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdBoulders4C` (`$9921`)

**Script command: big boulders (sprite `$4C`, 16x16)**

Witness: i2 5 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdBoulders` (`$9924`)

**The boulder spawner: an 8-byte record per data byte, `$A196` with the sprite, y, x and the size**

Size s = sprite - `$38` (- 4 more for `$4C`): 8, 12, 16. Record: `$A196`, the delay, the sprite, y = `$A0` - s, x = -s (enters from the right edge), height s, width s. Scores in `$A196` (annotator 03): 100 / 150 / 200 shot. Witness: i2 13 runs (3117-28218); Champion only.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdPlants` (`$9955`)

**Script command (a delay to `$FF`): appends green plant objects `$A2C6` (Champion only)**

Record (8 bytes): `$A2C6`, the delay, 0, y `$90`, x `$E4`, 0, 0. Witness: i2 8 runs (4011-28218).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ObjPoint` (`$9978`)

**Object: a point passed when the delay is out: `$B27C`, the restart point, the HUD**

HL = the delay. When out: `$B27C` = the point byte, the restart pointer `$B27F` = `$B281` (the start of the segment that holds the point: a death restarts there), HudPrintPoint `$9247`, HudProgress `$92AA`, HudPrintScore `$92DA`; then its word becomes ObjPointDone. Witness: game 11 runs, g1 51, h1 51, i1 1595; points passed (`$9980`) i1 25, i2 27.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 693 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CourseRun` |
| Reads | `$BF12` (`ObjectList`) |
| Writes | `$BF12` (`ObjectList`) |

### `ObjPointDone` (`$99A0`)

**Object skip: past a 4-byte record (the delay and one byte); the end of ObjPoint**

Witness: i1 7930 runs (1595 entries from ObjPoint's word), i2 8495.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ObjLamps` (`$99A3`)

**Object: sets the warning lamps when the delay is out (`$B27E` = value AND 3, HudLamps)**

The unmatched handler of stage 1: no enemy, the HUD's three lamps (HudLamps `$927E`) set at the course's own times. Then its word becomes ObjLampsDone. Witness: game 11 runs, g1 51, h1 51, i1 885, i2 841; set (`$99AB`) i1 24, i2 29.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 693 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `CourseRun` |
| Reads | `$BF16` (`ObjectList`) |
| Writes | `$BF16` (`ObjectList`) |

### `ObjLampsDone` (`$99C0`)

**Object skip: past a 4-byte record; the end of ObjLamps**

Witness: i1 7278 runs, i2 10082.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ObjRock` (`$99C3`)

**Object: a rock on the ground, moving with the scroll; kills the buggy on contact, 100 when shot or hit, 80 jumped**

When the delay is out, each pass: erases the sprite at its old place (not on the first pass, x `$F4`), moves x left by the scroll step `$B235` while the buggy is alive (x 0: removed, ObjRockRemove), then tests its box (y `$94`, x, 12 x 12) against the buggy's (`$B212`, `$A7FE`): contact calls the kill `$A7DD` and the rock explodes (ObjRockHit). Else against the forward shot at `$5B60`: a hit removes the shot (`$5B62` = `$FF`) and the rock explodes. ObjRockHit: the sprite `$2A`, the word ObjRockExplode, 100 points (ScoreAdd), `$B26F` = 0. Else when the buggy's x AND `$FC` equals the rock's x: 80 points (jumped). Then drawn at the new place (sprite `$0F` through `$AF74` / `$A826`).

The rock of the SCORE ADVANCE TABLE (100 / 80) and of NOTES' candidate 97C5: the script's rocks start at i1 263 (two in the start segment), seen at i1 1200. Witness: game 3060 runs, a1 374, g1 871, p2 1296, h1 871, i1 3080, i2 4289, h2 72. Contact (`$99F9`): game 1, g1 4, i1 17 (immune: the kill is a RET, the rock still explodes); shot (`$9A0B`): game 1, i2 1; jumped (`$9A37`): game 1, g1 2, i1 10, i2 11.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 325,743 t-states own (0.03 %) |
| Called from | `CourseRun` |
| Calls | `ScoreAdd`, `ObjRockExplode`, `ObjRockNext` (tail), `ObjRockDone` (tail), `ObjRockRemove` (tail), `BuggyKill`, `BoxOverlap`, `DrawSprite`, `ScrollAdjustIfAlive`, `Im2Vector` |
| Reads | `$B213`-`$B216` (`BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth`, `DeathStep`); `$B235` (`GroundSpeed`); `$BF02`-`$BF0D` (`ObjectList`) |
| Writes | `$5B62` (system); `$B26F` (`RockSeen`); `$BF00`-`$BF0D` (`ObjectList`); `$C328`-`$C32B` (`Stack`) |

### `ObjRockExplode` (`$9A51`)

**Object: a rock's explosion: sprites `$2B-$2E` moving with the ground, then removed**

Erases the previous frame (none after `$2A`), moves with the scroll while the buggy is alive, the next sprite; at `$2F` the record is removed (ObjRockRemove). Entered from ObjRockHit in the same pass and then by its word. Witness: game 10 runs, a1 5, g1 20, p2 20, h1 20, i1 85, i2 140, h2 5 (about 4-5 passes an explosion).

| | |
| --- | --- |
| Runs (the first recording's game window) | 2 calls, 2,212 t-states own (0.00 %) |
| Called from | `CourseRun`, `ObjRock` |
| Calls | `ObjRockRemove` (tail), `DrawSprite`, `ScrollAdjustIfAlive` |
| Reads | `$B216` (`DeathStep`); `$B235` (`GroundSpeed`); `$BF03`-`$BF05` (`ObjectList`) |
| Writes | `$BF03`-`$BF05` (`ObjectList`) |

### `ObjRockNext` (`$9A80`)

**The end of a rock pass: HL back to the record**

Reached by a jump from ObjRockMiss and by falling in from ObjRockExplode; an entry of the cut (the L1 builds record it as a routine entry). Witness: game 534, a1 62, g1 273, p2 244, h1 273, i1 1171, i2 1638, h2 35.

| | |
| --- | --- |
| Runs (the first recording's game window) | 526 calls, 5,340 t-states own (0.00 %) |
| Called from | `ObjRock` (tail) |
| Calls | `ObjRockDone` |

### `ObjRockDone` (`$9A81`)

**Object skip: past an 8-byte record (6 bytes after the delay); a rock's handler at its end**

Witness: i1 12370 runs, i2 13379.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,068 calls, 97,807 t-states own (0.01 %) |
| Called from | `CourseRun`, `ObjRock` (tail), `ObjRockNext`, `ObjRockRemove` (tail) |
| Calls | `CourseRun`, `Im2Vector` |
| Writes | `$C32A`-`$C32B` (`Stack`) |

### `ObjRockRemove` (`$9A86`)

**A rock or its explosion removed: its word becomes ObjRockDone**

Witness: game 3 runs, a1 1, g1 6, p2 4, h1 6, i1 25, i2 37.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3 calls, 210 t-states own (0.00 %) |
| Called from | `ObjRock` (tail), `ObjRockExplode` (tail) |
| Calls | `ObjRockDone` (tail) |
| Writes | `$BF00`-`$BF01` (`ObjectList`) |

### `ObjCrater` (`$9A92`)

**Object: a crater fed into the scrolling ground at the right edge; 100 when jumped**

No sprite: while the crater's x is above `$EC` (its first passes after the right edge) the ground pattern pointer `$B232` points at the crater's columns (`$A9CF` or `$A9EF`, by bit 3 of x), at x `$EC` back to the plain ground `$A9AF`; the ground scroller `$A932` copies from it. Then, as the crater moves left with the scroll (`$B235`, while the buggy is alive), the buggy's x AND `$FC` equal to its x scores 100 (jumped); at x 0 it is removed (its word ObjCraterDone). No contact test here: the buggy's fall into the crater is found elsewhere (the ground).

The crater of the SCORE ADVANCE TABLE (100 jumped) and of NOTES' candidate 97E8: first i1 263, seen at i1 450. Witness: game 3039 runs, a1 371, g1 812, p2 1288, h1 812, i1 5432, i2 2857, h2 66; the crater columns (`$9AB9`) i1 148; jumped (`$9AD2`) game 3, a1 1, g1 6, p2 4, h1 6, i1 43, i2 28.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 271,867 t-states own (0.02 %) |
| Called from | `CourseRun` |
| Calls | `ScoreAdd`, `ObjCraterDone`, `Im2Vector` |
| Reads | `$B213`-`$B216` (`BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth`, `DeathStep`); `$B235` (`GroundSpeed`); `$BEFA`-`$BEFF` (`ObjectList`) |
| Writes | `$B232`-`$B233` (`GroundProfile`); `$BEF8`-`$BEFF` (`ObjectList`); `$C328`-`$C32B` (`Stack`) |

### `ObjCraterDone` (`$9ADC`)

**Object skip: past a 4-byte record; the end of ObjCrater**

Witness: i1 18646 runs, i2 10593.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,039 calls, 69,344 t-states own (0.01 %) |
| Called from | `CourseRun`, `ObjCrater` |
| Calls | `CourseRun` |

### `ObjMine` (`$9AEB`)

**Object: a blinking mine on the ground; 50 when jumped**

On the first pass (x `$F8`) it clears 10 pixels of the line y `$A0` at x `$F6-$FF` (`$A7F4`, `$FD99`) and sets `$B288` bit 3, which the ground routine reads once and clears (`$A994`); later passes erase the sprite. Moves left with the scroll while the buggy is alive (x 0: removed, ObjMineRemove); the buggy's x AND `$FC` equal to its x scores 50 (jumped). Then the sprite `$11` / `$12` by bit 2 of the pass counter `$B23B` XOR the record's phase bit, drawn at y `$A0`. No contact test here.

The mines of the SCORE ADVANCE TABLE (50) and of NOTES: only in the segments after sector end J and at K, L (Beginner: 18 mines), and in Champion after sector end J and at K, L, V, Y. Witness: i1 2298 runs (11801-14790), i2 4455 (12338-28908); first passes (`$9B09`) i1 18, i2 35; jumped (`$9B2F`) i1 17, i2 34.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ObjMineDone` (`$9B5A`)

**Object skip: past a 6-byte record; the end of ObjMine**

Witness: i1 10169 runs, i2 19731.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## objects

`src/game/objects.asm`

### `UfoHandler` (`$9B6B`)

**The UFO handler: waits, then flies a saucer or the spinner, turns at random, leaves on the retreat flag, explodes when shot**

HL = record +2 (the fields are in the notes: +2 wait, +3 sprite, +4 turn timer, +5 dy, +6 dx, +7 y, +8 x, +9 height, +10 width, +11 to +19 the bomb). While the wait +2 counts down it only steps HL to the next record (UfoRecordSkip). Then each pass: `$B236` = `$FF` for the spinner (height +9 = 16) or 0 for a saucer; the first pass (turn timer `$FF`) gives a turn timer of 16-40 and clears the retreat flag `$B237` and `$B26D`; later passes erase the old sprite at (y, x) (UfoSetColour, then the sprite drawer `$A826`, which draws by XOR).

The move: when the turn timer runs out (reloaded with 16-72 from R) a UFO moving across starts moving up or down by 2, one moving up or down starts moving across by 2, the sign from bit 6 of R. x must stay below `$F1` (else it turns to an up / down move), y in `$18-$37` for a saucer, `$18-$2F` for the spinner (else it turns across). With the retreat flag `$B237` set (UfoRetreatTimer) it moves 4 a pass towards the nearer side, and past it (x >= `$F1`) the record goes on as the bomb alone (UfoSaucerGone).

Then the four upward shots ShotsUp `$5B65` are tested against its box (y, x, height, width) with `$A7FE`. A hit marks the shot spent (its byte +2 = `$FF`), stops the UFO, sets the first explosion sprite (`$26` saucer, `$2E` spinner), puts UfoExplodeHandler in the record and adds 100 (saucer) or 200 (spinner) to the score (`$92D3`, BC = `$0100` + `$0100` for the spinner), and clears `$B267`. Else the sprite steps on through its animation (saucer A 1-4, saucer B 5-10, spinner 11-14) and is drawn at the new place. Either way the bomb part (UfoBombHandler) runs after it in the same pass.

Witness: game 44 runs, g1 / h1 204 (only the wait: no UFO reached the screen in those runs), i1 13 759 (8172 active, frames 1125-30 439), i2 11 528 (445-33 813). UFOs shot: i1 37, i2 28 (`$9C42`). Turns: across to up / down i1 223, up / down to across i1 206. Retreat steps i1 462, i2 491.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 1,716 t-states own (0.00 %) |
| Called from | `CourseRun` |
| Calls | `UfoRecordSkip` (tail) |
| Reads | `$BF1A` (`ObjectList`); `$BF2E` (`ObjectList`); `$BF42` (`ObjectList`); `$BF56` (`ObjectList`) |
| Writes | `$BF1A` (`ObjectList`); `$BF2E` (`ObjectList`); `$BF42` (`ObjectList`); `$BF56` (`ObjectList`) |

### `UfoExplodeHandler` (`$9CA5`)

**The UFO's explosion: five frames in place, then the record goes on as its bomb alone**

HL = record +2. Erases the last frame (not on the first pass, sprite `$26` or `$2E`), steps the sprite +3 and draws it at (y, x): saucer `$26-$2A`, spinner `$2E-$32`. At `$2B` / `$33` the record becomes UfoBombHandler (UfoSaucerGone). Falls into UfoBombHandler: a bomb already falling falls on.

Put in the record by UfoHandler at a hit. Witness: i1 185 passes (frames 2236-30 297), i2 140 (994-33 311).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UfoBombPart` (`$9CDF`)

**UfoBombPart**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UfoBombHandler` (`$9CE0`)

**The UFO's bomb: dropped under the UFO, falls, explodes into a crater for the spinner, scores 5 / 10 when shot**

HL = record +2. The bomb's own wait +11 (16-47 from R) counts down first. Not dropped yet (+13 = `$FF`): when the UFO is gone too (the record's handler is UfoBombHandler) the record is spent (UfoRecordSkip from now on); else the bomb starts under the UFO, y + 8 (saucer) or y + 16 (spinner), x + 16, with sprite `$1D` and a timer of 8 (no drop when the UFO's x >= `$E7`). A bomb in flight is erased first.

It moves by dx 4, dy 4 for 8 passes, then falls straight down by 4 with sprite `$1E` (also at x >= `$F7`). At the ground (y >= `$A0`): a saucer's bomb ends; the spinner's bomb tests five places 4 apart from x - 5 on the screen rows 159 and 162 (`$5760`, `$5280`, the pixel masks from the table `$7D00`) and, when they are all clear, appends a crater record (`$9A92`, wait 0, x AND `$FC`) at the end of the object list (`$B261`) before the end marker `$975E`, clears 16 pixels of the ground's top row `$A0` (`$A7F4`) and draws the crater sprite `$10`.

In flight it is tested against the four upward shots ShotsUp `$5B65`, then the forward shot ShotForward `$5B60`: a hit spends the shot and adds 5 (saucer bomb) or 10 (spinner bomb), BC = 5 + (`$B236` AND 5). Then against the buggy (the box at `$B212`): a touch calls the kill `$A7DD`. Else it is drawn at (y, x + the band's scroll step, `$AF74`).

When the bomb ends: if the UFO is gone the record is spent, else the bomb is reloaded (wait 16-47, sprite `$1D`, not dropped) for the next drop.

Witness: i1 9546 passes (8319 as the record's handler, frames 1560-30 439), i2 8334 (771-33 813). Drops i1 143, i2 131; craters made i1 15, i2 16 (`$9DAD`); bombs shot i1 12, i2 18; bombs on the buggy i1 16, i2 17 (`$9E28`, the kill a RET in the immune clone).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UfoRecordSkip` (`$9E5F`)

**UfoRecordSkip**

| | |
| --- | --- |
| Runs (the first recording's game window) | 44 calls, 1,364 t-states own (0.00 %) |
| Called from | `UfoHandler` (tail) |
| Calls | `CourseRun` |

### `UfoSaucerGone` (`$9E81`)

**The UFO has left or exploded: the record's handler becomes UfoBombHandler, which runs at once**

Entered by a JP with the record +2 on the stack, from UfoHandler (the retreat past the side) and UfoExplodeHandler (the last frame). Witness: i1 72, i2 63 (frames 2266-30 297 in i1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UfoSetColour` (`$9E8E`)

**Picks the drawing colour of a UFO sprite into E' for the sprite drawer**

A = the sprite: below 5 (saucer A) `$44` bright green, below 11 (saucer B) `$06` yellow, below 15 (the spinner) `$05` cyan, else `$07` white (the bombs `$1D` / `$1E` and the explosions). Keeps the main registers. Called before each draw and erase of UfoHandler and UfoExplodeHandler: i1 16 491, i2 14 805; white i1 296.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UfoRetreatTimer` (`$9EA5`)

**The UFO retreat timer: after its wait sets the retreat flag `$B237`, and the UFOs fly off the screen**

The record (3 bytes, course command `$98AA`): the handler and a wait. When the wait runs out it sets `$B237` = `$FF` (UfoHandler then moves every UFO 4 a pass off the nearer side) and the record becomes UfoRetreatSkip. The flag is cleared by the life start (`$90F4`) and by the next UFO to enter the screen.

This is the unmatched handler of stage 1. Witness: the flag set i1 8 times, i2 10 (`$9EAD`): one per `$98AA` record, at the course points C E H I P U Y Z of Beginner and A E G H J P T U Y Z of Champion (course-commands.txt); handler runs i1 167 (frames 2937-28 403), i2 198.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UfoRetreatSkip` (`$9EBB`)

**UfoRetreatSkip**

| | |
| --- | --- |
| Runs | not reached in the recordings |

## enemies

`src/game/enemies.asm`

### `TankHandler` (`$9EBD`)

**The tank: rolls in from the right with the ground, fires its shell, 250 when shot, 200 when jumped**

Record (14 bytes): +2 wait, +3 sprite `$13`, +4 y `$8F`, +5 x `$E7`, +6 height `$11`, +7 width `$14`, +8 to +13 the shell (TankShellHandler). After the wait, each pass: erases the sprite (not on the first pass, x = `$E7`), x - the scroll step `$B235` while the buggy lives (off the left side: TankGone), then the tests: the buggy (the kill `$A7DD`) or the forward shot ShotForward `$5B60` (spent) both explode the tank: sprite `$32`, TankExplodeHandler in the record, 250 points (`$92D3`, BC = `$0250`), `$B270` cleared. Else 200 when the buggy's x AND `$FC`, less 1, equals the tank's x, and the sprite is drawn at x + the band's scroll step (`$AF74`). Then the shell part runs (TankShellHandler).

Witness: i1 912 runs (frames 23 663-28 206, Beginner V W Y), i2 2503 (2241-28 706, Champion B E I M N S T W Y). Shot i1 9, i2 19 (`$9F07`); touched i2 6 (`$9EF3`). The jump score `$9F32` was not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TankExplodeHandler` (`$9F4C`)

**The tank's explosion: five frames drawn 3 rows up, then the record goes on as the shell alone**

A shell still waiting to be fired (wait +8 not 0) is cancelled (`$FF`). Erases the last frame (not the first, `$32`), scrolls x with the ground while the buggy lives, steps the sprite +3 and draws it at (y - 3, x + the band's step): `$32-$36`. At `$37`: TankGone. Falls into TankShellHandler. Witness: i1 45 passes (frames 24 668-28 241), i2 125.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TankShellPart` (`$9F8E`)

**TankShellPart**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TankShellHandler` (`$9F8F`)

**The tank's shell: fired 8 passes after the tank appears, flies left, 20 when shot, 15 when jumped**

Shell fields: +8 wait (8 from the course command; 0 in flight, `$FF` done), +9 sprite (0 not yet fired, then `$3B`), +10 y `$93`, +11 x `$C1`, +12 height 3, +13 width 7. HL = record +2 on entry, back at the next record (+12) on return. In flight it is erased, moves left by 2 + the scroll step (`$B235` masked by `$B216` rotated left 3: the whole step while the buggy lives), and past the left side ends (+8 = `$FF`).

Tests: the buggy (the kill) or the forward shot (spent): 20 points (`$0020`), the shell ends. Else 15 (`$0015`) when the buggy's x AND `$FC`, less 1, equals its x, and it is drawn at x + the band's step.

Witness: i1 2961 runs (as the record's handler from frame 24 476), i2 5612. Fired i1 7, i2 24 (`$9FB1`); on the buggy i1 6, i2 19 (`$9FD3`; every 20 of the runs came from a touch: the shot path `$9FE7` was not executed in any recording); jumped i1 1, i2 4 (`$A000`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TankGone` (`$A022`)

**The tank has left or exploded: the record's handler becomes TankShellHandler, which runs at once**

Entered by a JP with the record +2 on the stack, from TankHandler (off the left side) and TankExplodeHandler (the last frame). The wait +2 is always 0 here, so the other choice, TankRecordSkip (`$A02A`), was not executed in any recording: known only from the code. Witness: i1 9, i2 25.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TankRecordSkip` (`$A036`)

**A tank record still waiting: steps HL 12 bytes to the next record**

Reached from TankHandler while the wait +2 counts down. Witness: i1 781, i2 1932.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LowFlyerHandler` (`$A03B`)

**The low flyer from behind: creeps in from the left, pauses, crosses the screen, 300 / 500 / 800 when shot, 125 when jumped**

Record (9 bytes): +2 wait, +3 sprite `$14`, +4 pause count, +5 y `$91`, +6 x 0, +7 height 8, +8 width `$0C`. Drawn in the ink of the current colour set (byte +3 of the set at `$B230`, in E'). Each pass after the wait: erases the sprite (not while x = 0), then the pace: x + 1 up to `$10`; at `$0F` a pause of 16-23 passes (FRAMES XOR R) and it waits at `$10`; then x + 4 a pass; at `$88` a pause of 4-11 and it waits at `$8C`; then x + 4 to `$F0`, where it is gone (LowFlyerGone). While the buggy is not alive (`$B216` not `$FF`) x also moves by the scroll step.

Tests: the buggy (the kill) or the forward shot (spent): sprite `$36`, LowFlyerExplodeHandler, a random score of 300, 500 or 800 (FRAMES XOR R AND 3, not 0, picks a bit of `$C0` rotated: BC = `$0300` / `$0500` / `$0800`), `$B26C` cleared: the ??? of the SCORE ADVANCE TABLE. Else 125 (`$0125`) when the buggy's x AND `$FC` equals its x, and it is drawn at x + the band's step (`$AF74`).

Champion only. Witness: i2 430 runs (frames 1353-29 538; the command `$98F3` at Champion A and Z). Exploded i2 4, all on the buggy (`$A0C4`); the shot path `$A0D8` was not executed in any recording; jumped i2 1 (`$A116`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LowFlyerExplodeHandler` (`$A13A`)

**The low flyer's explosion: frames `$36-$3A` in place, then the record is spent**

Erases the last frame (not the first, `$36`), steps the sprite and draws it at (y, x + the band's step) in the colour set's ink. At `$3B`: LowFlyerGone. Witness: i2 20 passes (frames 2100-29 565).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LowFlyerDone` (`$A170`)

**LowFlyerDone**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LowFlyerRecordSkip` (`$A171`)

**LowFlyerRecordSkip**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoulderHandler` (`$A196`)

**A boulder: one of three sizes rolls in with the ground, 100 / 150 / 200 when shot, 50 / 100 / 150 when jumped**

Record (8 bytes, commands `$9917` / `$991C` / `$9921`): +2 wait, +3 sprite (`$40` small, `$44` medium, `$4C` large), +4 y = `$A0` - size, +5 x = 256 - size, +6 height, +7 width = the size (8, 12, 16). Each pass after the wait: erases the sprite (not on the first pass, x + size = 0), x - the scroll step while the buggy lives (at x = 0: BoulderGone).

Tests: the buggy (the kill) or the forward shot (spent): the explosion sprite (`$7F` small, `$57` medium, `$5F` large), BoulderExplodeHandler, 100 / 150 / 200 points by the sprite (below `$44`, below `$4C`, else), `$B26E` cleared. Else 50 / 100 / 150 when the buggy's x AND `$FC` equals its x. Then, while the buggy lives, it rolls: the sprite steps through small `$40-$43`, medium `$44-$4B`, large `$4C-$57`; drawn at x + the band's step.

Champion only. Witness: i2 3448 runs (frames 3118-29 354, Champion C G M W Y). Exploded i2 26 (small 4, medium 10, large 12; 22 of them touches `$A1CD`, 4 shots `$A1E1`); jumped i2 9 (small 3, medium 3, large 3).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoulderExplodeHandler` (`$A268`)

**A boulder's explosion: five frames of its size, then the record is spent**

Frames small `$7F-$83`, medium `$57-$5B`, large `$5F-$63`; the frames `$60-$63` and `$7C-$7F` are drawn one row higher. Erases the last frame (not the first: sprite AND `$D7` = `$57`), scrolls x while the buggy lives, steps the sprite and draws it; when (sprite - `$5C`) AND `$D7` = 0 (`$5C`, `$64`, `$84`): BoulderGone. Witness: i2 130 passes (frames 3411-29 144).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoulderDone` (`$A2B4`)

**BoulderDone**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoulderRecordSkip` (`$A2B5`)

**BoulderRecordSkip**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoulderGone` (`$A2BA`)

**BoulderGone**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantHandler` (`$A2C6`)

**The green plant: grows and shrinks in a 15-frame cycle as it scrolls in, 500 when shot, 200 when jumped**

Record (8 bytes, command `$9955`): +2 wait, +3 frame (0 before the first pass, then 1-15), +4 y `$90`, +5 x `$E4`, +6 / +7 the hit box's height and width (set each pass). The plant is two sprites: the stem `$63` + frame at (y + 16, x), and in frames 5-11 the head `$6F` + frame at (y, x), with the head's attributes on rows 18-19 (PlantColourOn; PlantColourOff in the other frames).

The first pass clears 28 pixels of the ground's top row `$A0` from x `$E4` (`$A7F4`) and sets `$B288` bit 3 (tested and cleared at `$A994`), then draws frame 1. Later passes erase the sprites, x - the scroll step while the buggy lives (at 0: PlantGone), then the hit box from PlantHitBoxes by the frame: (y + dy, x + dx, dy, dx).

Tests: the buggy (the kill) or the forward shot (spent): frame `$7A`, PlantExplodeHandler, 500 points (`$0500`), `$B26A` cleared. Else 200 (`$0200`) when the buggy's x AND `$FC` equals its x (the SCORE ADVANCE TABLE says 250). Then the next frame (15 wraps to 1) is drawn at x + the band's step.

Champion only. Witness: i2 1497 runs (frames 4013-29 106, Champion D F K Q V X Y). Exploded i2 8, all touches (`$A358`; the shot path `$A36F` was not executed in any recording); jumped i2 4 (`$A3A8`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantExplodeHandler` (`$A3ED`)

**The green plant's explosion: frames `$7A-$7E` at (y + 4, x + 8) over the head's colours, then the record is spent**

The first pass (frame `$7A`) draws sprite `$73` at (y + 16, x) instead of erasing; later passes erase the last frame. Scrolls x while the buggy lives, steps the frame and draws it with PlantColourOn. At `$7F`: PlantGone puts the plain colours back. Witness: i2 40 passes (frames 4348-28 413).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantDone` (`$A443`)

**PlantDone**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantRecordSkip` (`$A444`)

**PlantRecordSkip**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantGone` (`$A449`)

**PlantGone**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantColourOn` (`$A458`)

**Colours the plant's head: 3 or 4 cells of rows 18 and 19 at the plant's column**

HL = (L y, H x). PlantAttrAddress gives the cell and the count; each cell of rows 18 and 19 gets the paper of the colour set's byte +3 with the colour set's byte +4 paper as ink (`$B230` the set), the next cell gets byte +3, and AttrRow20 `$5A80` (row 20, column 0) gets byte +4. Keeps A (in A'), DE and HL. Witness: i2 546 (frames 4112-29 099).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantColourLoop` (`$A474`)

**PlantColourLoop**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantColourOff` (`$A48D`)

**Puts the plain colour (the colour set's byte +3) back on the plant's cells of rows 18 and 19**

As PlantColourOn, with the one colour for every cell. Witness: i2 564 (frames 4083-29 106).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlantAttrAddress` (`$A49F`)

**HL = the attribute cell of row 18 under x, B = 3 cells, or 4 when x is not on a cell boundary**

In: H = x. HL = AttrRow18 `$5A40` + x / 8; B = 3, + 1 when bit 2 of x is set. Witness: i2 1110 (frames 4083-29 106).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## bonus

`src/game/bonus.asm`

### `SectorBonus` (`$A4EE`)

**The sector bonus screen: the times, the sector and time bonuses, the best time written back into the course script**

Entered by a jump from the course interpreter `$9751` at a sector-end record, HL just past the command word. Reads the record: TimeRequired `$B241` (BCD word, high byte first), SectorBonus `$B245` (one BCD byte, `$B246` = 0), the scenery flag `$B27D` (`$FF` / `$00`, alternate sectors: picks the hills graphics at the life start `$90D3` through `$95B0` / `$9541`), BestTime `$B243` (BCD word, `$0999` in the image), and leaves the course pointer `$B27A` just past the record.

SetIm1 `$A7CB` (the ROM's interrupt: the game's clock `$7F98` stops), clears the screen (`$9044`, colour 7), `$9136`, prints BonusHeaderText and the course letter (`$9258` with `$B27C`), then the time taken `$B285`, TimeRequired and BestTime (`$9369`, 2 BCD bytes at x `$C2`, y `$49` / `$51` / `$59`). Prints SectorBonusText and the bonus at x `$A0`, y `$69`, and adds it to the score: ScoreAdd `$92D3` with B = the bonus byte, C = 0 (`$10` = 1000 points). Plays BonusTune `$A773` (22 BEEPER notes), waits 50 frames.

The time bonus: TimeRequired - time taken in BCD. Not positive: NoTimeBonus (SORRY NO TIME BONUS and a low note). Positive: TimeBonusText, a two-note fanfare (BonusBeep `$A690`), 50 frames, then one pass of TimeBonusLoop a second of the difference: the bonus counter `$B245` + 100 shown at x `$A0`, y `$71`, 100 points to the score, a 15-half-cycle blip on the beeper with interrupts off (DI `$A5E5`, OUT `$A60A`, EI `$A610`), 4 frames. Only the low byte of the difference counts (DEC A / DAA to zero): a difference of 100 seconds or more would lose its hundreds (known only from the code: no time required in the scripts is over `$0150`).

Then the 100-frame wait `$903D` and the best time: if the time taken is below BestTime, BestTimeWrite stores it (DE = `$B285`, low byte `$B285` first, that is the same big-endian BCD order) over the record's last word, through the course pointer `$B27A` - 2: this is the writer of the script words `$B884`, `$B925`, `$B9AE`, `$BA51`, `$BB03` (Beginner) and `$BBC7`, `$BC95`, `$BD42`, `$BDF0`, `$BED0` (Champion). The AWESOME! BEST SECTOR TIME SO FAR!! text and the longer flash (50 passes, else 25) only when the old best is not the image's placeholder (high byte `$09`): the first finish of a sector records its time silently.

Last: BonusFlash 25 or 50 passes of `$8349` (the attribute cycle of the menu, here on `$5A03-$5A1D`) and the delay `$820D`; the time `$B285` / `$B286` and the tick counter `$B287` to zero, the screen cleared, the life start `$90D3`, SP back from `$B25F` and a jump to the main loop `$9696` with the course pointer at the next sector.

Witness: i1 5 and i2 5 runs (l1sum `$A4EE`, i1 frames 5176-29659, i2 5357-30694, the five sector ends of NOTES); TimeBonusLoop i1 134 seconds, i2 172; the blip OUT `$A60A` i1 2010 = 134 x 15; BestTimeWrite `$A659` i1 5, i2 5; the reads of `$B884` (i1 1). NoTimeBonus `$A620` and the AWESOME text `$A651` were not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code (both runs finished every sector in time, and no sector was finished twice).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BonusBeep` (`$A690`)

**Two BEEPER calls with the same note, 7 frames apart (the bonus fanfares)**

HL = the period, DE = the length, as for BEEPER `$03B5` (the ROM's). Called by SectorBonus with HL `$01B7`, DE `$00A8` (the time bonus) and with HL `$1BBA`, DE `$000B` (no time bonus; not executed in any recording). Witness: i1 5, i2 5 entries (i1 frames 5423-28918), the 7-frame wait `$A699` 35 times each.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## play

`src/game/play.asm`

### `SetIm1` (`$A7CB`)

**IM 1 with I = `$3F`: the ROM's frame interrupt (menus, death, hold, bonus)**

DI, IM 1, I = `$3F`, EI. Called from the menu code (`$81CD`, `$823D`, `$8250`, `$8328`), the death (`$96DF`), SectorBonus `$A50E`, the abort `$AACD` and the hold `$AEE0`. Witness: game 27, a1 28, g1 5, t1 1, p2 10, h1 5, i1 6, i2 7, h2 1 entries (a1 frames 153-21155).

| | |
| --- | --- |
| Runs (the first recording's game window) | 27 calls, 1,134 t-states own (0.00 %) |
| Called from | `MenuCheckStart`, `MenuCheckAnyKey`, `MainLoop` |

### `SetIm2` (`$A7D4`)

**IM 2 with I = `$3A`: the vector word at `$3AFF` in the ROM sends interrupts to `$FFFF`, the game's handler `$7F14`**

DI, I = `$3A`, IM 2, EI. Called from the life start (`$9132`) and the end of the hold (`$AF0E`). Witness: game 20, a1 5, g1 4, p2 8, h1 4, i1 6, i2 6 entries (a1 frames 1424-20428).

| | |
| --- | --- |
| Runs (the first recording's game window) | 20 calls, 840 t-states own (0.00 %) |
| Called from | `LifeStart` |

### `BuggyKill` (`$A7DD`)

**Kills the buggy: the death starts (state 0), 25 points, unless already dying**

Does nothing unless the buggy state `$B216` is `$FF` (alive). Else `$B216` = 0 (the first death frame: BuggyUpdate counts it to 8, the main loop `$96BB` ends the life there) and the wheel step `$B217` = 0 (WheelsFly starts), then ScoreAdd `$92D3` with DE = 0, BC = `$0025`: 25 points for the death (known only from the code: no run checked the score at a death). Keeps HL.

The immune clones (i1, i2) patch the first byte to RET. Callers, one a death cause each (l1sum of the CALL): the rock `$99F9` in `$99C3` (command `$97C5`; game 1, a1 1, g1 4, p2 4, h1 4, i1 17, i2 27, h2 1), the UFO bomb `$9E28` in `$9CE0` (dropped by the UFO handler `$9B6B` through `$9E81`; i1 16, i2 17), the tank `$9EF3` in `$9EBD` (command `$98BE`; i2 6), the tank shell `$9FD3` in `$9F8F` (installed by `$A022`; i1 6, i2 19), the low flyer `$A0C4` in `$A03B` (command `$98F3`; i2 4), the boulders `$A1CD` in `$A196` (commands `$9917` / `$991C` / `$9921`; i2 22), the green plant `$A358` in `$A2C6` (command `$9955`; i2 8), and the crater `$AA9C` in BuggyUpdate (the ground probe; game 18, a1 1, p2 4, i1 69, i2 67). The rock, bomb, tank, shell, flyer, boulder and plant handlers test their box against the buggy's with BoxOverlap `$A7FE` first.

The crater and mine handlers (`$9A92`, `$9AEB`) and the UFO saucers (`$9B6B`) never call it: a crater kills through the ground probe; how a mine kills (the probe or not at all) needs a run. Witness of the deaths that counted (not immune): game 19 = 1 rock + 18 craters, a1 2 = 1 + 1, g1 4 rocks, p2 8 = 4 + 4, h1 4 rocks, h2 1 rock (l1sum `$A7DD` entries: game frames 2029-16149).

| | |
| --- | --- |
| Runs (the first recording's game window) | 19 calls, 2,204 t-states own (0.00 %) |
| Called from | `ObjRock`, `BuggyUpdate` |
| Calls | `ScoreAdd` |
| Reads | `$B216` (`DeathStep`) |
| Writes | `$B216`-`$B217` (`DeathStep`, `WreckStep`) |

### `UnplotRun` (`$A7F4`)

**Clears E points left to right from (H = x, L = y) through UnplotPixel `$FD99`**

E = the count. Calls UnplotPixel `$FD99` for x, x + 1, ...; keeps L. Callers: `$8064` (the options page), the mine `$9AEB`, the bomb `$9CE0`, the plant `$A2C6`. Witness: a1 60 entries (frames 1218-18835), t1 3, i1 33, i2 63.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoxOverlap` (`$A7FE`)

**Do two boxes overlap? HL and HL' point at y, x, height, width; NC when they do**

B, C, D, E = the box at HL, B', C', D', E' = the box at HL' (the buggy `$B212` or a shot `$5B60` / `$5B65` for the object handlers). Carry as soon as one box ends above or left of the other: y + height < y', y' + height' < y, then the same with x and width. NC: they overlap. Witness: game 1055, a1 117, g1 518, p2 460, h1 518, i1 54 624, i2 54 655, h2 63 entries (i1 frames 604-30439).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,055 calls, 185,574 t-states own (0.02 %) |
| Called from | `ObjRock` |
| Calls | `Im2Vector` |
| Reads | `$5B60`-`$5B63` (system); `$B212`-`$B215` (`BuggyY`, `BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth`); `$BF04`-`$BF0F` (`ObjectList`) |
| Writes | `$C326`-`$C327` (`Stack`) |

### `DrawSprite` (`$A826`)

**Draws sprite A at H = x, L = y (XOR) through the sprite table `$B2D6`: drawer word, graphics word**

The table `$B2D6` holds 4 bytes a sprite: the drawer (one of the sprites module's DrawSprite16x4 ... DrawSprite40x23) and its graphics. Sprite 0 is the buggy (`$E140`, DrawSprite40x23), `$1F-$26` its death frames, `$3C-$3E` the three wheels, `$3B` the forward shot's DrawShotForward. The drawer gets HL = the position, DE = the graphics and returns through DrawSpriteDone, which restores BC and DE; HL is the drawer's. Drawn twice (XOR) to erase. Witness: game 7358, a1 1375, g1 2268, t1 16, p2 3220, h1 2268, i1 35 224, i2 42 588, h2 322 entries (i1 frames 262-30439).

| | |
| --- | --- |
| Runs (the first recording's game window) | 7,358 calls, 1,450,001 t-states own (0.13 %) |
| Called from | `LifeStart`, `MainLoop`, `ObjRock`, `ObjRockExplode`, `BuggyUpdate`, `BuggyErase`, `WheelsFly`, `WheelErase` |
| Calls | `DrawSprite16x9`, `DrawSprite24x12`, `DrawSprite40x23`, `Im2Vector` |
| Reads | `$B2D6`-`$B2D9` (`SpriteTable`); `$B312`-`$B315` (`SpriteTable`); `$B352`-`$B371` (`SpriteTable`); `$B382`-`$B391` (`SpriteTable`); `$B3C6`-`$B3D1` (`SpriteTable`) |
| Writes | `$C320`-`$C329` (`Stack`) |

### `DrawSpriteDone` (`$A843`)

**DrawSpriteDone**

| | |
| --- | --- |
| Runs (the first recording's game window) | 7,358 calls, 220,835 t-states own (0.02 %) |
| Called from | `DrawSprite16x9`, `DrawSprite24x12`, `DrawSprite40x23` |
| Calls | `Im2Vector` |

### `ScrollFarBand` (`$A846`)

**The far band (lines 64-95): one pixel left a pass, 8 new columns from HillsStrip `$EBC0` every 8 passes**

Only while the buggy is alive (`$B216` = `$FF`). The counter `$B224` runs 8 passes; at 0 the next 32 bytes of the mountains graphic (`$B226` + `$20`, from `$EBC0` up to `$F000` and round) go to FeedFarBand `$5B00`. Each pass every line of 64-95 (the line table at `$FC80`) rolls left one pixel through its 32 bytes, the new bit from the line's FeedFarBand byte. Witness: game 1576, a1 292, g1 493, p2 664, h1 493, i1 3601, i2 3935, h2 40 entries: once a main-loop pass.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 58,305,283 t-states own (5.05 %) |
| Called from | `MainLoopCalls` |
| Calls | `Im2Vector` |
| Reads | `$4800`-`$497F` (screen); `$4A00`-`$4A7F` (screen); `$4B00`-`$4B7F` (screen); `$4C00`-`$4C7F` (screen); `$4D00`-`$4D7F` (screen); `$4E00`-`$4E7F` (screen); 6 more ranges |
| Writes | `$4800`-`$497F` (screen); `$4A00`-`$4A7F` (screen); `$4B00`-`$4B7F` (screen); `$4C00`-`$4C7F` (screen); `$4D00`-`$4D7F` (screen); `$4E00`-`$4E7F` (screen); 4 more ranges |

### `ScrollMiddleBand` (`$A89A`)

**The middle band (lines 96-127): two pixels left a pass, 8 new columns from MountainsStrip or MoonBaseStrip every 4 passes**

As ScrollFarBand with the counter `$B228` (4 passes), the source `$B22A` going from `$B22C` to `$B22E` and round (set at the life start by `$95B0` from the scenery flag `$B27D`), the feed FeedMiddleBand `$5B20` and the lines 96-127 (`$FCC0`). Witness: the same counts as ScrollFarBand (i1 3600).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 112,319,432 t-states own (9.74 %) |
| Called from | `MainLoopCalls` |
| Calls | `Im2Vector` |
| Reads | `$4880`-`$49FF` (screen); `$4A80`-`$4AFF` (screen); `$4B80`-`$4BFF` (screen); `$4C80`-`$4CFF` (screen); `$4D80`-`$4DFF` (screen); `$4E80`-`$4EFF` (screen); 7 more ranges |
| Writes | `$4880`-`$49FF` (screen); `$4A80`-`$4AFF` (screen); `$4B80`-`$4BFF` (screen); `$4C80`-`$4CFF` (screen); `$4D80`-`$4DFF` (screen); `$4E80`-`$4EFF` (screen); 4 more ranges |

### `ScrollNearBand` (`$A8FD`)

**The band of lines 128-159: two pixels left while the buggy is in the air, else the same time in a delay**

Only while alive. BuggyAirborne `$AFA5` (buggy y < `$89`): the 32 lines from `$FD00` (line 128) roll two pixels left with zero bits coming in; on the ground the delay `$A929` (`$0AF5` loops) instead, so the pass takes about as long. ScrollAdjustX moves what is drawn in this band by 2 to match (it holds the buggy: drawn at y - 9 = `$89`). Witness: same counts as ScrollFarBand; the delay ran game 1114, i1 1524 of 3600 passes.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 104,958,311 t-states own (9.10 %) |
| Called from | `MainLoopCalls` |
| Calls | `BuggyAirborne`, `Im2Vector` |
| Reads | `$5000`-`$517F` (screen); `$5200`-`$527F` (screen); `$5300`-`$537F` (screen); `$5400`-`$547F` (screen); `$5500`-`$557F` (screen); `$5600`-`$567F` (screen); 3 more ranges |
| Writes | `$5000`-`$517F` (screen); `$5200`-`$527F` (screen); `$5300`-`$537F` (screen); `$5400`-`$547F` (screen); `$5500`-`$557F` (screen); `$5600`-`$567F` (screen); 2 more ranges |

### `ScrollRoad` (`$A932`)

**The road (lines 160-191): four pixels left a pass, new columns from RoadFeed every 2 passes; random texture on its top line**

Only while alive. The counter `$B234` runs 2 passes; at 0 the 32 bytes at `$B232` (RoadFeed `$A9AF`, its crater edge strips set by the crater handler `$9A92`) go to FeedRoad `$5B40`. Each pass the 32 lines from `$FD40` (line 160) roll four pixels left. Then random bits (FRAMES xor R, AND `$0F`, or AND `$03` once when `$B288` bit 3 is set, which it clears) are ORed into `$509F`, the last byte of line 160: the road's broken top edge.

Witness: same counts as ScrollFarBand (i1 3600). The h2 snapshot was taken inside it (PC `$A981`), which is why the cut had entries at `$A957` / `$A977` / `$A981`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 187,424,805 t-states own (16.25 %) |
| Called from | `MainLoopCalls` |
| Calls | `Im2Vector` |
| Reads | `$5080`-`$51FF` (screen); `$5280`-`$52FF` (screen); `$5380`-`$53FF` (screen); `$5480`-`$54FF` (screen); `$5580`-`$55FF` (screen); `$5680`-`$56FF` (screen); 8 more ranges |
| Writes | `$5080`-`$51FF` (screen); `$5280`-`$52FF` (screen); `$5380`-`$53FF` (screen); `$5480`-`$54FF` (screen); `$5580`-`$55FF` (screen); `$5680`-`$56FF` (screen); 4 more ranges |

### `RoadLine` (`$A957`)

**RoadLine**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RoadByte` (`$A977`)

**RoadByte**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RoadByteBits` (`$A981`)

**RoadByteBits**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BuggyUpdate` (`$AA0F`)

**The buggy each pass: the controls, the jump, left / right, the crater probe, the draw; the death frames; the BREAK abort**

Alive (`$B216` = `$FF`): ControlsRead `$AE17` into C. Jump (bit 1): the jump index `$B223` goes from `$FF` to 0 and then on, one step a pass even with the key up, through the arc at `$B221` (JumpArcs, chosen by SpeedGovernor) until its `$80` ends it (`$FF` again). The step adds to the buggy y `$B212`.

On the ground only: slow (bit 4) moves x `$B213` two pixels left down to `$29`, fast (bit 3) two right up to `$50`, neither drifts back to `$38` by two. Then the crater probe: five points x + 5, + 10, ... + 25 on the screen line 162 (`$5280`, just under the road's top line 160, through the pixel table `$FA00`): a set pixel there is a crater's wall, BuggyKill `$A7DD` and the crater flag `$B220` = `$FF`.

Then the draw at (x, y - 9) through ScrollAdjustIfAlive: sprite 0 alive, else the death frame: `$B216` + 1 stored, sprite `$1E` + `$B216` (`$1F-$26`). The main loop `$96BB` ends the life when `$B216` reaches 8.

Last the BREAK test: CAPS SHIFT (port `$FEFE` bit 0) and SPACE (port `$7FFE` bit 0) both down: SetIm1 and a jump to `$8004`, the title (a1 frame 3174, `$AACD` 1 time). The test runs in play and during the death frames.

Witness: game 1576, a1 292, g1 493, p2 664, h1 493, i1 3601, i2 3935, h2 40 entries (i1 frames 263-30438); jump started (AA2A) game 463, i1 3249 steps; the probe hits `$AA9C` game 18, a1 1, p2 4, i1 69, i2 67.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 1,268,194 t-states own (0.11 %) |
| Called from | `MainLoopCalls` |
| Calls | `BuggyKill`, `DrawSprite`, `ControlsRead`, `ScrollAdjustIfAlive`, `Im2Vector` |
| Reads | `$5286`-`$528B` (screen); `$AAF0`-`$AB36` (`JumpArcs`); `$B212`-`$B223` (`BuggyY`, `BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth` and 9 more); `$FA66`-`$FABB` (`PixelTable`) |
| Writes | `$B212`-`$B223` (`BuggyY`, `BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth` and 9 more); `$C32E`-`$C32F` (`Stack`) |
| Ports in | `$7FFE`, `$FEFE` |

### `BuggyErase` (`$AAD3`)

**Erases the buggy drawn last pass (XOR), alive or in a death frame**

HL = (x, y - 9). Alive: sprite 0. `$B216` = 0 (killed this pass): the position through ScrollAdjustX and sprite 0. Dying: sprite `$1E` + `$B216`, the frame BuggyUpdate drew. Witness: the same counts as BuggyUpdate (game 1576, i1 3601).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 173,683 t-states own (0.02 %) |
| Called from | `MainLoopCalls` |
| Calls | `DrawSprite`, `ScrollAdjustX`, `Im2Vector` |
| Reads | `$B212`-`$B216` (`BuggyY`, `BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth` and 1 more) |
| Writes | `$C32E`-`$C32F` (`Stack`) |

### `WheelsFly` (`$AB37`)

**At a death: the three wheels fly off for 32 steps along WheelPaths**

Only while dying (`$B216` not `$FF`), four calls a main-loop pass. At wheel step `$B217` = 0 the wheels start at y `$97` and x + 1, x + `$0A`, x + `$16` (`$B21A`, `$B21C`, `$B21E`; sprites `$3C`, `$3D`, `$3E`), the path pointer `$B218` = WheelPaths. Each step every wheel still on screen is erased (WheelErase), moved by its two bytes (y up by the first, x by the second) and drawn; the first leaves left, the third right (a carry out of x ends a wheel, its word = 0). `$B217` + 1.

Witness: game 6303, a1 1164, g1 1972, p2 2656, h1 1972, i1 14 401, i2 15 737, h2 161 entries (the calls); the work after the alive test ran only when a death counted: `$AB5F` game 611, a1 67, g1 140, p2 268, h1 140, h2 35, none in i1 / i2 (BuggyKill is RET there).

| | |
| --- | --- |
| Runs (the first recording's game window) | 6,303 calls, 631,149 t-states own (0.05 %) |
| Called from | `MainLoopCalls` |
| Calls | `DrawSprite`, `WheelErase`, `Im2Vector` |
| Reads | `$AC31`-`$AD00` (`WheelPaths`, `FireShots`); `$B213`-`$B21F` (`BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth`, `DeathStep` and 5 more) |
| Writes | `$B217`-`$B21F` (`WreckStep`, `WreckPath`, `WreckPiece1`, `WreckPiece2` and 1 more); `$C32E`-`$C32F` (`Stack`) |

### `WheelErase` (`$AC20`)

**Erases wheel sprite A at HL, except at step 0 (nothing drawn yet)**

Witness: game 1598, a1 176, g1 376, p2 716, h1 376, h2 88 entries (a1 frames 2010-2886); none in i1 / i2.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,598 calls, 166,711 t-states own (0.01 %) |
| Called from | `WheelsFly` |
| Calls | `DrawSprite` |
| Reads | `$B217` (`WreckStep`) |

### `FireShots` (`$ACF1`)

**Fire: a forward shot and an upward shot on each new press**

Only while alive. ControlsRead bit 0; up: `$B288` bit 1 cleared. A new press (bit 1 was clear) sets it, then: ShotForward `$5B60` free (`$FF`): y + 1, x + `$20`, the end x + `$80`, drawn (DrawShotForward). And an upward shot when no shot in ShotsUp is still below line `$6D`: a free one gets y - 12 (AND `$FC`) and x + 8, drawn (DrawShotUp). Witness: game 1576, i1 3601 entries; new presses `$AD06` game 153, a1 12, g1 42, p2 55, h1 42, i1 332, i2 367.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 164,291 t-states own (0.01 %) |
| Called from | `MainLoopCalls` |
| Calls | `DrawShotForward`, `DrawShotUp`, `ControlsRead`, `Im2Vector` |
| Reads | `$5B60`-`$5B71` (system); `$B212`-`$B216` (`BuggyY`, `BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth` and 1 more); `$B288` (`Player`) |
| Writes | `$5B60`-`$5B6E` (system); `$B288` (`Player`); `$C32E`-`$C32F` (`Stack`) |

### `ShotsMove` (`$AD61`)

**Moves the forward shot and the four upward shots**

ShotForwardMove then ShotsUpMove. Witness: game 1576, a1 291, g1 493, p2 664, h1 493, i1 3601, i2 3935, h2 40 entries.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 69,382 t-states own (0.01 %) |
| Called from | `MainLoopCalls` |
| Calls | `ShotForwardMove`, `ShotsUpMove`, `Im2Vector` |

### `ShotForwardMove` (`$AD68`)

**The forward shot: erase, 6 pixels right, end at its end x or when hit, draw**

Erased (DrawShotForward), first through ScrollAdjustX when the buggy was killed this pass by something else than a crater (`$B216` = 1, `$B220` = 0). Its height byte `$FF` (an object handler hit it): free (`$5B60` = `$FF`). Else height 3, x + 6; at the end x free, else drawn again. Witness: same entry counts as ShotsMove; moves `$AD9E` game 440, i1 2640.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 184,397 t-states own (0.02 %) |
| Called from | `ShotsMove` |
| Calls | `DrawShotForward`, `ScrollAdjustIfAlive`, `Im2Vector` |
| Reads | `$5B60`-`$5B64` (system); `$B216`-`$B220` (`DeathStep`, `WreckStep`, `WreckPath`, `WreckPiece1` and 3 more) |
| Writes | `$5B60`-`$5B62` (system); `$C32C`-`$C32D` (`Stack`) |

### `ShotsUpMove` (`$ADAC`)

**The four upward shots: ShotUpMove on each one in use**

Witness: same entry counts as ShotsMove.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 526,318 t-states own (0.05 %) |
| Called from | `ShotsMove` |
| Calls | `ShotUpMove`, `Im2Vector` |
| Reads | `$5B65`-`$5B71` (system) |
| Writes | `$C32A`-`$C32D` (`Stack`) |

### `ShotUpMove` (`$ADBF`)

**One upward shot: erase, 4 pixels up, end above line `$18` or when hit, draw**

As ShotForwardMove with height 4 and DrawShotUp. Witness: game 951, a1 271, g1 987, p2 1236, h1 987, i1 7833, i2 8636 entries.

| | |
| --- | --- |
| Runs (the first recording's game window) | 951 calls, 252,871 t-states own (0.02 %) |
| Called from | `ShotsUpMove` |
| Calls | `DrawShotUp`, `ScrollAdjustIfAlive`, `Im2Vector` |
| Reads | `$5B65`-`$5B6F` (system); `$B216`-`$B220` (`DeathStep`, `WreckStep`, `WreckPath`, `WreckPiece1` and 3 more) |
| Writes | `$5B65`-`$5B6F` (system); `$C328`-`$C329` (`Stack`) |

### `DrawShotForward` (`$ADF7`)

**The forward shot: 6 pixels across from (x, y + 1), XOR**

Also sprite `$3B` of the sprite table. Witness: game 936, a1 211, g1 709, p2 914, h1 709, i1 5642, i2 6103 entries.

| | |
| --- | --- |
| Runs (the first recording's game window) | 936 calls, 267,848 t-states own (0.02 %) |
| Called from | `FireShots`, `ShotForwardMove` |
| Calls | `ShotPlot`, `Im2Vector` |
| Writes | `$C32A`-`$C32B` (`Stack`) |

### `DrawShotUp` (`$AE04`)

**An upward shot: 4 pixels down from (x + 1, y), XOR**

Witness: game 1913, a1 545, g1 1980, p2 2483, h1 1980, i1 15 680, i2 17 284, h2 30 entries.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,913 calls, 375,043 t-states own (0.03 %) |
| Called from | `FireShots`, `ShotUpMove` |
| Calls | `ShotPlot`, `Im2Vector` |

### `ShotPlot` (`$AE11`)

**One pixel through `$FDB3`, HL kept**

Witness: game 13 268, a1 3566, i1 97 928 entries.

| | |
| --- | --- |
| Runs (the first recording's game window) | 13,268 calls, 637,168 t-states own (0.06 %) |
| Called from | `DrawShotForward`, `DrawShotUp` |
| Calls | `FlipPixel`, `Im2Vector` |

### `ControlsRead` (`$AE17`)

**Reads the chosen control (control type `$B259`, 1-6) and returns its bits active high: 0 fire, 1 up / jump, 2 down, 3 right / fast, 4 left / slow**

Jumps to ControlHandlers[`$B259` - 1]; each handler returns the five bits active low with the others 1, and ControlsReadDone inverts them (CPL): bits 5-7 come back 0. Bit 2 (down) is read by no caller. Callers: the options page (`$8227`: fire alone starts the game when the control is not the keyboard), BuggyUpdate, FireShots, the hold.

`$B259` is the third option of the options page (keys Z X C V B K, the text at `$8586`; 6 in the entry image). Witness: game 2939, a1 28 792, g1 922, p2 1208, h1 922, i1 7202, i2 7870, h2 64 entries; the handler of each run below.

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,939 calls, 299,892 t-states own (0.03 %) |
| Called from | `MenuCheckStart`, `BuggyUpdate`, `FireShots` |
| Calls | `JoySinclair1`, `JoyKempston`, `Im2Vector` |
| Reads | `$AE2E`-`$AE31` (`ControlHandlers`); `$B259` (`Controls`) |
| Writes | `$C32C`-`$C32D` (`Stack`) |

### `ControlsReadDone` (`$AE2C`)

**ControlsReadDone**

| | |
| --- | --- |
| Runs (the first recording's game window) | 2,939 calls, 41,184 t-states own (0.00 %) |
| Called from | `JoySinclair1`, `JoyKempston` |
| Calls | `Im2Vector` |
| Writes | `$C32C`-`$C32D` (`Stack`) |

### `JoySinclair1` (`$AE3A`)

**Control 1 (Z, Sinclair with 1 Joystick): both Interface 2 sticks, keys 6-0 and 1-5, ANDed**

Port `$EFFE` (6 left, 7 right, 8 down, 9 up, 0 fire: bits 4-0 already in the common order) into E; port `$F7FE` (1 left, 2 right, 3 down, 4 up, 5 fire) with its five bits reversed into C; C AND E OR `$E0`. Either stick drives the buggy. Witness: a1 8 runs (frames 779-833, the options page with Z chosen), game 2296 (c1's random keys chose it: frames 1395-13759). No joystick was moved: the paths ran with keys or nothing.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 445,111 t-states own (0.04 %) |
| Called from | `ControlsRead` |
| Calls | `ControlsReadDone`, `Im2Vector` |
| Writes | `$C32A`-`$C32B` (`Stack`) |
| Ports in | `$EFFE`, `$F7FE` |

### `JoySinclair2` (`$AE4F`)

**Control 5 (B, Sinclair with 2 Joysticks): one stick a player in a two-player game**

One player (`$B257` = 1): as JoySinclair1. Two players: player 1 (`$B271` = 1) reads port `$EFFE` (keys 6-0) only, player 2 port `$F7FE` (keys 1-5) only, through JoySinclairKeys1To5 with E = `$FF`. Witness: a1 8 runs (frames 1016-1069, the options page, one player); the two-player paths were not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code (p2 used the keyboard).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JoyKempston` (`$AE64`)

**Control 2 (X, Kempston Joystick): IN (`$1F`), active high bits 0 right, 1 left, 2 down, 3 up, 4 fire, put in the common order**

The five bits rotated through B into fire 0, up 1, down 2, right 3, left 4, then CPL and OR `$E0`: active low like the others. Witness: a1 8 runs (frames 841-894, the options page), game 643 (frames 13 766-16 753). The emulator had no Kempston input: the port read only what it gives when nothing is pressed.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 71,430 t-states own (0.01 %) |
| Called from | `ControlsRead` |
| Calls | `ControlsReadDone`, `Im2Vector` |
| Writes | `$C32A`-`$C32B` (`Stack`) |
| Ports in | `$021F` |

### `JoyCursor` (`$AE7E`)

**Control 3 (C, Cursor Joystick): 5 left, 6 down, 7 up, 8 right, 0 fire**

Port `$F7FE` bit 4 (5) to bit 4 left; port `$EFFE` bit 0 (0) fire, bit 3 (7) to bit 1 up, bit 4 (6) to bit 2 down, bit 2 (8) to bit 3 right. Witness: a1 7 runs (frames 902-947, the options page); never in play.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JoyFuller` (`$AE9D`)

**Control 4 (V, Old-type Fuller Box with Joystick): IN (`$7F`), active low bits 0 up, 1 down, 2 left, 3 right, 7 fire**

Rotated into fire 0, up 1, down 2, right 3, left 4 (the other bits 1). Witness: a1 8 runs (frames 955-1008, the options page); never in play.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `KeysQAOP` (`$AEB2`)

**Control 6 (K, Keyboard): P fire, O jump, Q fast, A slow**

Port `$FDFE` bit 0 (A) to bit 4, port `$FBFE` bit 0 (Q) to bit 3, port `$DFFE` bits 0 (P) and 1 (O) to bits 0 and 1. The only control of every play recording: a1 28 753 runs (frames 1424-21149), g1 922, p2 1208, h1 922, i1 7202, i2 7870, h2 64.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HoldCheck` (`$AECE`)

**The hold: H stops the game (IM 1, the clock frozen) until H again, S or fire**

Port `$BFFE` bit 4 (H). Up: `$B288` bit 4 cleared (HoldKeyUp). Down while bit 4 is set (still the same press): nothing. A new press: bit 4 set, SetIm1 (the game's handler and its clock `$7F98` stop), wait for H up, 5 frames, then HoldLoop until fire (ControlsRead bit 0: at once), S (port `$FDFE` bit 1: at once) or H (5 frames); SetIm2 `$A7D4` and back to the main loop.

Witness: game 1575, a1 291, g1 493, p2 664, h1 493, i1 3600, i2 3934, h2 41 entries; the hold itself only in a1 (a new press `$AEE0` 1 time, HoldWaitRelease 30 472 loops, HoldLoop 28 199, left with H through HoldResumeWait 5 HALTs: a1 frames 2060-2220 of NOTES). Leaving with S or fire was not executed in any recording: known only from the code.

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,575 calls, 128,249 t-states own (0.01 %) |
| Called from | `MainLoopCalls` |
| Calls | `Im2Vector` |
| Reads | `$B288` (`Player`) |
| Writes | `$B288` (`Player`); `$C32E`-`$C32F` (`Stack`) |
| Ports in | `$BFFE` |

### `TuneToggleCheck` (`$AF15`)

**T toggles the tune: `$B288` bit 7 flips on each new press**

Port `$FBFE` bit 4 (T). Up: `$B288` bit 0 cleared. A new press (bit 0 clear): bit 0 set and bit 7 flipped; the tune player `$7F47` is silent while bit 7 is set. Witness: game 1576, a1 292, g1 493, p2 664, h1 493, i1 3601, i2 3935, h2 40 entries; a1 pressed T at 2540 and 2740 (NOTES), the toggle path `$AF22-$AF29` a1 6 runs (292 - 286).

| | |
| --- | --- |
| Runs (the first recording's game window) | 1,576 calls, 140,112 t-states own (0.01 %) |
| Called from | `MainLoopCalls` |
| Calls | `Im2Vector` |
| Reads | `$B288` (`Player`) |
| Writes | `$B288` (`Player`); `$C32E`-`$C32F` (`Stack`) |
| Ports in | `$FBFE` |

### `SpeedGovernor` (`$AF31`)

**The pace of the game: a delay a pass and the jump arc chosen by the buggy's x**

x `$B213` against `$38`: forward (> `$38`) the index 0, centre 1, back (< `$38`) 2 into JumpSpeeds `$AF68`: the jump arc to `$B221` and the delay count, + `$1800` while dying. Then a busy loop of that many iterations: forward 1, centre `$02EE`, back `$05DC`. Called twice a main-loop pass (game 3151, a1 582, g1 986, p2 1328, h1 986, i1 7200, i2 7868, h2 81 entries).

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,151 calls, 110,417,797 t-states own (9.57 %) |
| Called from | `MainLoopCalls` |
| Calls | `Im2Vector` |
| Reads | `$AF68`-`$AF73` (`JumpSpeeds`); `$B213`-`$B216` (`BuggyX`, `BuggyBoxHeight`, `BuggyBoxWidth`, `DeathStep`) |
| Writes | `$B221`-`$B222` (`JumpArc`); `$C32E`-`$C32F` (`Stack`) |

### `ScrollAdjustIfAlive` (`$AF74`)

**ScrollAdjustX, only while the buggy is alive**

Witness: game 3474, a1 716, g1 2054, p2 2534, h1 2054, i1 19 540, i2 25 107, h2 90 entries.

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,474 calls, 79,165 t-states own (0.01 %) |
| Called from | `ObjRock`, `ObjRockExplode`, `BuggyUpdate`, `ShotForwardMove`, `ShotUpMove` |
| Calls | `ScrollAdjustX`, `Im2Vector` |
| Reads | `$B216` (`DeathStep`) |
| Writes | `$C326`-`$C327` (`Stack`) |

### `ScrollAdjustX` (`$AF79`)

**Adds the scroll step of y's band to x (H): what is drawn there moves with its band**

L = y: below `$40` nothing; `$40-$5F` the mountains' step `$B225` (1); `$60-$7F` the hills' `$B229` (2); `$80-$9F` the hills' step only while BuggyAirborne (the near band scrolls then); `$A0` and down the road's `$B235` (4). Returns through BuggyAirborne. Witness: game 3022, a1 672, g1 1932, p2 2277, h1 1932, h2 78 entries (falls in from ScrollAdjustIfAlive in i1 / i2, so no entries there).

| | |
| --- | --- |
| Runs (the first recording's game window) | 3,022 calls, 279,757 t-states own (0.02 %) |
| Called from | `BuggyErase`, `ScrollAdjustIfAlive` |
| Calls | `BuggyAirborne`, `Im2Vector` |
| Reads | `$B212` (`BuggyY`); `$B225`-`$B229` (`HillsSpeed`, `FarColumn`, `MiddleCountdown`, `MiddleSpeed`) |
| Writes | `$C326`-`$C32D` (`Stack`) |

### `BuggyAirborne` (`$AFA5`)

**Carry when the buggy is in the air: its y `$B212` below `$89` (on the ground `$92`)**

Witness: game 4445, a1 946, g1 2389, p2 2873, h1 2389, i1 23 140, i2 29 041, h2 109 entries.

| | |
| --- | --- |
| Runs (the first recording's game window) | 4,445 calls, 133,445 t-states own (0.01 %) |
| Called from | `ScrollNearBand`, `ScrollAdjustX` |
| Calls | `Im2Vector` |
| Reads | `$B212` (`BuggyY`) |
| Writes | `$C326`-`$C32D` (`Stack`) |

## sprites

`src/game/sprites.asm`

### `BlitRows` (`$AFAB`)

**Copies rows of bytes to the screen: rows `$B247` to `$B248` - 1, at x `$B249`, `$B24A` bytes a row, from HL**

The line table `$FC00` gives each row's address, the pixel table `$FA00` x's byte column. Callers: the title (`$8004`: two logos) and the HUD of each life start (`$9136`). Witness: game 23, a1 8, g1 7, t1 2, p2 11, h1 9, i1 14, i2 14, h2 1 entries (a1 frames 20-20424).

| | |
| --- | --- |
| Runs (the first recording's game window) | 23 calls, 212,955 t-states own (0.02 %) |
| Called from | `MenuEntry`, `HudDraw` |
| Reads | `$6132`-`$6389` (`TitleMoon`, `TitlePatrol`); `$9481`-`$9540` (`HudPanel`); `$B247`-`$B24A` (`BlitTop`, `BlitBottom`, `BlitX`, `BlitWidth`); `$FA90`-`$FAB0` (`PixelTable`); `$FC00`-`$FC9F` (`ScreenLineTable`) |
| Writes | `$400A`-`$4936` (screen); `$4A09`-`$4A36` (screen); `$4B09`-`$4B36` (screen); `$4C09`-`$4C36` (screen); `$4D09`-`$4D36` (screen); `$4E09`-`$4E36` (screen); 2 more ranges |

### `DrawSprite16x4` (`$AFDD`)

**A 2-byte, 4-line sprite: 8 shifted copies of 8 bytes**

Sprites `$11`, `$12`, `$1D`, `$1E`. Witness: a1, t1 (the score advance table), i1 8626, i2 9653 instructions at the entry.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSprite16x8` (`$B003`)

**A 2-byte, 8-line sprite: 4 shifted copies of 16 bytes**

Sprites `$40-$43`. Witness: a1 20, t1 1, i2 670 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSprite16x9` (`$B02A`)

**A 2-byte, 9-line sprite: 8 shifted copies of 18 bytes (the wheels)**

Sprites `$3C-$3E`. Witness: game 3118, a1 342, g1 728, p2 1392, h1 728, h2 170 runs: the deaths (WheelsFly); none in i1 / i2.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 4,135,488 t-states own (0.36 %) |
| Called from | `DrawSprite` |
| Calls | `DrawSpriteDone`, `Im2Vector` |
| Reads | `$4867`-`$57F0` (screen); `$6350`-`$6439` (`TitlePatrol`, `BuggyWreck1`, `BuggyWreck2`); `$644C`-`$645D` (`BuggyWreck2`); `$6470`-`$6481` (`BuggyWreck3`); `$6494`-`$64A5` (`BuggyWreck3`); `$64B8`-`$64C9` (`BuggyWreck3`); 8 more ranges |
| Writes | `$4867`-`$57F0` (screen); `$6F75`-`$6F76` (`BuggyExplosion`); `$77B5`-`$7D16` (`BurstLarge`, `Debris`, `BurstMedium`); `$8519`-`$851A` (`OptionsText`); `$C31E`-`$CB5C` (`Stack`, `BurstTiny`, `PlantFrames`) |

### `SpriteXor2Wide` (`$B052`)

**The rows of the 2-byte drawers: XOR 2 bytes a line, B lines**

Witness: game 28 062, i1 34 504 instructions at the entry.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSprite24x8Attr` (`$B069`)

**A 3-byte, 8-line sprite in colour: 4 shifted copies of 24 bytes; 3 x 2 cells set to E'**

Sprites 1-`$0A`, `$27-$2A`, `$37-$3A`. Witness: a1 40, t1 2, i1 13 327, i2 10 725 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSprite24x8` (`$B0BA`)

**A 3-byte, 8-line sprite: 8 shifted copies of 24 bytes**

Sprite `$14`. Witness: a1 20, t1 1, i2 374 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSprite24x12` (`$B0E2`)

**A 3-byte, 12-line sprite: 4 shifted copies of 36 bytes**

Sprites `$0F`, `$2B-$2E`, `$44`, `$45`. Witness: game 1049, a1 163, g1 546, p2 484, h1 546, i1 2342, i2 4368, h2 71 runs.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 2,240,858 t-states own (0.19 %) |
| Called from | `DrawSprite` |
| Calls | `DrawSpriteDone`, `Im2Vector` |
| Reads | `$5060`-`$5080` (screen); `$5160`-`$5180` (screen); `$5260`-`$5280` (screen); `$5360`-`$5480` (screen); `$5540`-`$5580` (screen); `$5640`-`$5680` (screen); 6 more ranges |
| Writes | `$5060`-`$5080` (screen); `$5160`-`$5180` (screen); `$5260`-`$5280` (screen); `$5360`-`$5480` (screen); `$5540`-`$5580` (screen); `$5640`-`$5680` (screen); 2 more ranges |

### `DrawSprite24x16` (`$B10D`)

**A 3-byte, 16-line sprite: 4 shifted copies of 48 bytes**

Sprite `$10`. Witness: a1 40, t1 2, i1 15, i2 1072 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSprite24x16Attr` (`$B115`)

**A 3-byte, 16-line sprite in colour: 4 shifted copies of 48 bytes; 3 x 3 cells set to E'**

Sprites `$0B-$0E`, `$2F-$32`. Witness: a1 20, t1 1, i1 3164, i2 4112 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SpriteSetup24` (`$B143`)

**The line table entry and the copy of a 3-byte, 16-line sprite (48 bytes a shift)**

Witness: a1 60, t1 3, i1 3179, i2 5184 entries.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SpriteXor3Wide` (`$B168`)

**The rows of the 3-byte drawers: XOR 3 bytes a line, B lines**

Witness: game 12 588, i1 185 584 instructions at the entry.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSprite32x16` (`$B184`)

**A 4-byte, 16-line sprite: 4 shifted copies of 64 bytes**

No sprite of `$00-$45` uses it. Witness: a1 20, t1 1, i2 1524 runs.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawSprite40x23` (`$B1C8`)

**A 5-byte, 23-line sprite: 4 shifted copies, 128 bytes apart (the buggy)**

Sprite 0 (the buggy, `$E140`), `$13`, the death frames `$1F-$26` and `$33-$36`. Witness: game 3191, a1 610, g1 994, t1 1, p2 1344, h1 994, i1 7524, i2 9168, h2 81 runs.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 17,464,226 t-states own (1.51 %) |
| Called from | `DrawSprite` |
| Calls | `DrawSpriteDone`, `Im2Vector` |
| Reads | `$48E7`-`$48EB` (screen); `$49E7`-`$49EB` (screen); `$4AE7`-`$4AEB` (screen); `$4BE7`-`$4BEB` (screen); `$4CE7`-`$4CEB` (screen); `$4DC7`-`$4DEB` (screen); 6 more ranges |
| Writes | `$48E7`-`$48EB` (screen); `$49E7`-`$49EB` (screen); `$4AE7`-`$4AEB` (screen); `$4BE7`-`$4BEB` (screen); `$4CE7`-`$4CEB` (screen); `$4DC7`-`$576C` (screen); 1 more ranges |

## courses

`src/game/courses.asm`

### `BeginnerToChampion` (`$BB07`)

**The end of the Beginner course: go on with the Champion course**

Run once, in i1 at frames 29659-29663, after point Z: LD A,`$20` into PlayerPoint (the Champion letters), CALL `$93C5` with HL `$4000` and C `$60`, CALL `$9136`, ChampionCourse `$BB24` into PlayerCourse, then LD SP,(LoopStack) and JP `$9696` restart the main loop.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ChampionToBeginner` (`$BED4`)

**The end of the Champion course: start the Beginner course again**

Run once, in i2 at frames 30694-30698: XOR A into PlayerPoint, the same two calls as BeginnerToChampion, BeginnerCourse `$B7E8` into PlayerCourse, the main loop restarted.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## printing

`src/game/printing.asm`

### `PrintAttrCheck` (`$F0F0`)

**Colour the glyph's cells unless the font is FontPlain or the ROM font, then draw it**

Entered from PrintGlyph `$FEF7` (`$FF92` JP `$F0F0`) with the first row's address on the stack and in PrintLines `$F012`. Bit 2 of the font base's high byte set: straight to the drawing at `$FFAD`; otherwise the first row's screen address to PrintColour `$FF95`. Run 5268 times in game (as often as PrintGlyph).

| | |
| --- | --- |
| Runs (the first recording's game window) | 5,268 calls, 279,768 t-states own (0.02 %) |
| Called from | `PrintGlyph` (tail) |
| Calls | `PrintColour` (tail), `PrintRowsOr` (tail) |
| Reads | `$F009`-`$F013` (`PrintFont`, `PrintState`, `PrintWidth`, `PrintLines`) |
| Writes | `$C31E`-`$C329` (`Stack`) |

### `PlotPixel` (`$FD80`)

**Set the pixel at x H, line L**

Address from PixelTable and ScreenLineTable, then OR the mask. Run 61349 times in game; called from `$87AE`, `$87B9`, `$8CF3` and `$92CE`.

| | |
| --- | --- |
| Runs (the first recording's game window) | 61,349 calls, 7,732,772 t-states own (0.67 %) |
| Called from | `FrameHLine`, `FrameVLine`, `EntryFieldDraw` |
| Reads | `$4000`-`$53E0` (screen); `$53FF`-`$57FF` (screen); `$FA00`-`$FD7F` (`PixelTable`, `ScreenLineTable`) |
| Writes | `$4000`-`$53E0` (screen); `$53FF`-`$57FF` (screen); `$C324`-`$C329` (`Stack`) |

### `UnplotPixel` (`$FD99`)

**Reset the pixel at x H, line L (AND NOT the mask)**

Run in a1 (1160), t1 (58), i1 (420) and i2 (942): called from `$A7F5`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FlipPixel` (`$FDB3`)

**Invert the pixel at x H, line L (XOR the mask)**

Called from `$AE12`; run in i1 97928 times.

| | |
| --- | --- |
| Runs (the first recording's game window) | 13,268 calls, 1,692,832 t-states own (0.15 %) |
| Called from | `ShotPlot` |
| Calls | `Im2Vector` |
| Reads | `$4067`-`$5008` (screen); `$5107`-`$5116` (screen); `$5207`-`$5217` (screen); `$5307`-`$5308` (screen); `$5407`-`$5537` (screen); `$5607`-`$5608` (screen); 4 more ranges |
| Writes | `$4067`-`$5008` (screen); `$5107`-`$5116` (screen); `$5207`-`$5217` (screen); `$5307`-`$5308` (screen); `$5407`-`$5537` (screen); `$5607`-`$5608` (screen); 2 more ranges |

### `PrintChar` (`$FDCC`)

**Print the code in A at the print position (or take it as a control code's parameter)**

Keeps BC, DE, HL and IX; works in the other register set. Sets IX = `$F000` and jumps to the handler in PrintState `$F00A` with a return to `$FDDD`. Run 13526 times in game.

| | |
| --- | --- |
| Runs (the first recording's game window) | 13,526 calls, 1,298,677 t-states own (0.11 %) |
| Called from | `HeroesPrintRow`, `AllTimePrintRow`, `HeroesDrawTables`, `HiScoreEntry`, `EntryFieldDraw`, `GameStart`, `HudDraw`, `HudPrintPointLetter`, `HudPrintScore`, `PrintBcd`, `CmdPoint`, `PrintText` |
| Calls | `PrintCharNormal`, `PrintInk`, `PrintPaper`, `PrintFlash`, `PrintBright`, `PrintAtX`, `PrintAtY`, `PrintMarginSet`, `PrintLimitSet`, `PrintFontSet`, `Im2Vector` |
| Reads | `$F00A`-`$F00B` (`PrintState`) |
| Writes | `$C322`-`$C32D` (`Stack`) |

### `PrintCharDone` (`$FDDD`)

**PrintCharDone**

| | |
| --- | --- |
| Runs (the first recording's game window) | 13,526 calls, 649,313 t-states own (0.06 %) |
| Called from | `PrintCharNormal`, `PrintInk`, `PrintPaper`, `PrintFlash`, `PrintBright`, `PrintAtX`, `PrintAtY`, `PrintMarginSet`, `PrintLimitSet`, `PrintFontSet`, `PrintRowsOr` |

### `PrintCharNormal` (`$FDE3`)

**The handler of a fresh code: a glyph, a new line, a control code or "?"**

`$80` and up print "!"; `$20-$7F` print the glyph; `$0D` a new line; `$10-$1A` put the code's parameter handler from PrintCodeTable `$F080` into PrintState (`$FE0A`); anything else prints "?". Run 8169 times in game.

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 705,408 t-states own (0.06 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone`, `PrintGlyph` (tail), `Im2Vector` |
| Reads | `$F000`-`$F010` (`PrintY`, `PrintX`, `PrintShift`, `PrintCode` and 7 more); `$F080`-`$F095` (`PrintCodeTable`) |
| Writes | `$C320`-`$C32D` (`Stack`); `$F000`-`$F00B` (`PrintY`, `PrintX`, `PrintShift`, `PrintCode` and 6 more) |

### `PrintNewline` (`$FE0F`)

**New line: PrintX to the left margin, then the next line**

Run in game (33) and a1 (231): the menus' multi-line texts.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintNextLine` (`$FE17`)

**Add the line step to the line at HL; past 184 wrap to the top**

Also called by TAB (`$FEA6`) and by PrintGlyph when a glyph would pass the limit (`$FF25`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintSwallow` (`$FE23`)

**The handler for codes `$14` and `$15`: back to PrintCharNormal and print "?" for the byte after them**

Not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code. The game's texts never use `$14` or `$15`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintInk` (`$FE2E`)

**INK n: PrintAttr's bits 0-2 = n AND 7 (game 82 runs)**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 5,822 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone`, `PrintTakeParam` |
| Reads | `$F004` (`PrintAttr`) |
| Writes | `$F004` (`PrintAttr`) |

### `PrintPaper` (`$FE3D`)

**PAPER n: bits 3-5 = n AND 7 (game 54)**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 5,130 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone`, `PrintTakeParam` |
| Reads | `$F004` (`PrintAttr`) |
| Writes | `$F004` (`PrintAttr`) |

### `PrintFlash` (`$FE52`)

**FLASH n: bit 7 = n AND 1 (game 5)**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 385 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone`, `PrintTakeParam` |
| Reads | `$F004` (`PrintAttr`) |
| Writes | `$F004` (`PrintAttr`) |

### `PrintBright` (`$FE65`)

**BRIGHT n: bit 6 = n AND 1 (game 82)**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 6,209 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone`, `PrintTakeParam` |
| Reads | `$F004` (`PrintAttr`) |
| Writes | `$F004` (`PrintAttr`) |

### `PrintAtX` (`$FE78`)

**AT x y, first parameter: PrintX = x, the next byte to PrintAtY (game 2489)**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 121,980 t-states own (0.01 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone`, `Im2Vector` |
| Writes | `$C320`-`$C321` (`Stack`); `$F001`-`$F00B` (`PrintX`, `PrintShift`, `PrintCode`, `PrintAttr` and 5 more) |

### `PrintAtY` (`$FE82`)

**AT, second parameter: PrintY = y, less 185 when 185 or more**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 169,291 t-states own (0.01 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone` |
| Writes | `$C320`-`$C327` (`Stack`); `$F000`-`$F00B` (`PrintY`, `PrintX`, `PrintShift`, `PrintCode` and 6 more) |

### `PrintTab` (`$FE92`)

**TAB x: PrintX = x; a new line when x is left of the old PrintX**

Run only in a1 (320) and t1 (16): the score advance table's columns.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintMarginSet` (`$FEAA`)

**MARGIN n: PrintMargin = n AND `$3F` (game 25)**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 1,175 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone`, `PrintTakeParam` |
| Writes | `$F005` (`PrintMargin`) |

### `PrintLimitSet` (`$FEB3`)

**LIMIT n: PrintLimit = n, with bit 7 forced and PrintError set when n is below `$80` (game 25)**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 1,700 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone` |
| Writes | `$F006`-`$F00B` (`PrintLimit`, `PrintError`, `PrintFont`, `PrintState`) |

### `PrintFontSet` (`$FEC7`)

**FONT n: copy descriptor n AND 3 to the metrics and the base (game 106)**

| | |
| --- | --- |
| Runs (the first recording's game window) | run into, not called, 29,680 t-states own (0.00 %) |
| Called from | `PrintChar` |
| Calls | `PrintCharDone`, `PrintTakeParam` |
| Reads | `$F096`-`$F0AD` (`FontDescriptors`) |
| Writes | `$F008`-`$F011` (`PrintFont`, `PrintState`, `PrintWidth`) |

### `PrintTakeParam` (`$FEE6`)

**Put PrintCharNormal back into PrintState and mask the parameter A with B - 1 (error bit when A >= B)**

Called by each control code handler that takes a number (game 354 runs).

| | |
| --- | --- |
| Runs (the first recording's game window) | 354 calls, 22,710 t-states own (0.00 %) |
| Called from | `PrintInk`, `PrintPaper`, `PrintFlash`, `PrintBright`, `PrintMarginSet`, `PrintFontSet` |
| Reads | `$F007` (`PrintError`) |
| Writes | `$F007`-`$F00B` (`PrintError`, `PrintFont`, `PrintState`) |

### `PrintGlyph` (`$FEF7`)

**Draw the glyph of the code in A at the print position and advance PrintX by its width**

The width: PrintWidthSpace for a space, PrintWidthI for "I", PrintWidthMW for "M" and "W", PrintWidth otherwise. A glyph that would pass PrintLimit starts a new line first. Then the row addresses into PrintLines (ScreenLineTable plus the byte column), the rows shifted right by PrintShift into PrintShifted, and PrintAttrCheck `$F0F0`. Run 5268 times in game.

| | |
| --- | --- |
| Runs (the first recording's game window) | 5,268 calls, 10,562,237 t-states own (0.92 %) |
| Called from | `PrintCharNormal` (tail) |
| Calls | `PrintAttrCheck` (tail), `Im2Vector` |
| Reads | `$F000`-`$F011` (`PrintY`, `PrintX`, `PrintShift`, `PrintCode` and 7 more); `$F022`-`$F02C` (`PrintShifted`); `$F108`-`$F10C` (`FontSmall`); `$F148`-`$F14C` (`FontSmall`); `$F180`-`$F1CC` (`FontSmall`); `$F208`-`$F2D4` (`FontSmall`); 5 more ranges |
| Writes | `$C31A`-`$C32B` (`Stack`); `$F002`-`$F02D` (`PrintShift`, `PrintCode`, `PrintAttr`, `PrintMargin` and 7 more) |

### `PrintColour` (`$FF95`)

**Set the 2x2 attribute cells under the glyph to PrintAttr, then draw it**

HL = the first row's screen address; the cell's attribute address from its high byte (`$58` + bits 3-4). Run 4055 times in game (fonts 0 and 1 only).

| | |
| --- | --- |
| Runs (the first recording's game window) | 4,055 calls, 497,280 t-states own (0.04 %) |
| Called from | `PrintAttrCheck` (tail) |
| Calls | `PrintRowsOr` |
| Reads | `$F004` (`PrintAttr`) |
| Writes | `$581C`-`$5820` (screen); `$583C`-`$5ADD` (screen); `$C31E`-`$C329` (`Stack`) |

### `PrintRowsOr` (`$FFAD`)

**OR the shifted rows onto the screen, two bytes a row, and advance PrintX by the width**

Run 5268 times in game.

| | |
| --- | --- |
| Runs (the first recording's game window) | 5,268 calls, 3,949,600 t-states own (0.34 %) |
| Called from | `PrintAttrCheck` (tail), `PrintColour` |
| Calls | `PrintCharDone`, `Im2Vector` |
| Reads | `$4084`-`$4119` (screen); `$4133`-`$46FD` (screen); `$4749`-`$4EFD` (screen); `$4F4C`-`$56BD` (screen); `$56DF`-`$56E0` (screen); `$5703`-`$577D` (screen); 1 more ranges |
| Writes | `$4084`-`$4119` (screen); `$4133`-`$46FD` (screen); `$4749`-`$4EFD` (screen); `$4F4C`-`$56BD` (screen); `$56DF`-`$56E0` (screen); `$5703`-`$577D` (screen); 2 more ranges |

### `PrintText` (`$FFD0`)

**Print the string at HL up to its `$1F`**

Run 4004 times in game. The build-date strings start with `$1F` and print nothing (BuildDate0335 `$7F00`).

| | |
| --- | --- |
| Runs (the first recording's game window) | 238 calls, 209,384 t-states own (0.02 %) |
| Called from | `MenuEntry`, `OptionsPage`, `HeroesDrawTables`, `HiScoreEntry`, `GameStart`, `LifeStart`, `HudDraw`, `HudPrintPoint`, `CmdPoint` |
| Calls | `PrintChar` |
| Reads | `$7F00` (`BuildDate0335`); `$8413`-`$8A4B` (`TitleText`, `OptionsText`, `ScoreAdvanceText`, `DemoText` and 19 more); `$8DB1`-`$8E3F` (`HiScoreTexts`); `$9073`-`$90B8` (`TextPlayer`, `TextGameOver`, `TextGameOverPlayer`, `TextNoDate`); `$93D3`-`$942C` (`HudTextLamps`, `HudText1P`, `HudText2P`, `HudTextTimePoint` and 3 more); `$97A7`-`$97AC` (`TextPointAt`); 2 more ranges |
| Writes | `$C32C`-`$C335` (`Stack`) |

### `PrintReset` (`$FFDA`)

**Reset the print state and print PrintResetText**

Not executed in any recording: known only from the code. Nothing calls it; the image's print state (font 3, the ROM font) is what this leaves, so it was the developer's.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Im2Jump` (`$FFF4`)

**The IM 2 interrupt's target: JP `$7F14`**

The game runs in IM 2 with I = `$3A` (`$A7D5`): the ROM's bytes at `$3A00-$3AFF` are `$FF`, so the vector is `$FFFF`, and the JR there (its offset is the ROM's `$F3` at `$0000`) lands here. Run 25747 times in i1.

| | |
| --- | --- |
| Runs | not reached in the recordings |
