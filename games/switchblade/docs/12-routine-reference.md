# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: Bank 4: the AY player, the tunes, the story pages (128K only), The
loader's second stage) follow the game, each under its own heading with its modules, its source, its annotations and
its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`setup`](#setup) | `$5C00`-`$5D4E` | 6 of 10 |
| [`menu`](#menu) | `$5D4F`-`$6B5B`, `$A6EC`-`$A927` | 30 of 39 |
| [`vars`](11-data-reference.md#vars) | `$6B5C`-`$7047` | 0 of 12 |
| [`rooms`](#rooms) | `$7048`-`$72FD`, `$955A`-`$9614`, `$9F34`-`$A0C8`, `$A0C9`-`$A59A` | 70 of 77 |
| [`leftovers`](11-data-reference.md#leftovers) | `$72FE`-`$72FF`, `$D0F9`-`$D103` | 0 of 2 |
| [`tables`](11-data-reference.md#tables) | `$7300`-`$7BE4`, `$FD98`-`$FF00` | 0 of 29 |
| [`graphics`](11-data-reference.md#graphics) | `$7BE5`-`$80EA`, `$D104`-`$FD97` | 0 of 27 |
| [`text`](#text) | `$80EB`-`$8319`, `$8365`-`$844F` | 9 of 25 |
| [`mainloop`](#mainloop) | `$831A`-`$8338`, `$8456`-`$853E`, `$8DFE`-`$8F00`, `$9A4B`-`$9AFC`, `$A652`-`$A6EB` | 36 of 37 |
| [`render`](#render) | `$8339`-`$8364`, `$8803`-`$8A2E`, `$8A2F`-`$8DFD`, `$8F3B`-`$9022` | 58 of 61 |
| [`sound`](#sound) | `$8450`-`$8455`, `$853F`-`$872A` | 13 of 16 |
| [`ending`](#ending) | `$872B`-`$8802` | 3 of 3 |
| [`player`](#player) | `$8F01`-`$8F3A`, `$9023`-`$9347`, `$9514`-`$9528`, `$965F`-`$99E6`, `$9A27`-`$9A4A`, `$9AFD`-`$9F33` | 91 of 91 |
| [`enemies`](#enemies) | `$9348`-`$9513`, `$9529`-`$9559`, `$A59B`-`$A651` | 17 of 17 |
| [`panel`](#panel) | `$9615`-`$965E`, `$99E7`-`$9A26`, `$FF01`-`$FFFF` | 10 of 13 |
| [`roomdata`](11-data-reference.md#roomdata) | `$A928`-`$D0F8` | 0 of 126 |

## setup

`src/game/setup.asm`

### `GameOver` (`$5C42`)

**The game is lost: the GAME OVER banner, then the high-score entry and the title**

From LoseEnergy `$9651` (`JP M` when the lives run out). CALL `$831A`: ShowMessage `$66C8` with A = 4 (GAME OVER) and a wait of up to 40 x 5 frames or fire. Falls into EndOfGame.

Witness: L1 6 (gameover, hiscore, rzx x4). Ran once in gameover.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/gameover` 1) |
| Called from | `LoseEnergy` (tail) |
| Calls | `IntroScript`, `ShowGameOverWait`, `InsertHighScore` |

### `NewGame` (`$5C4D`)

**The title loop and a new game: title, cheat, globals, Hiro, the first room, the main loop**

1. SetTune `$5FC0` with A = `$80` (the title tune); the title sequence and high-score table `$A73E` returns when fire is pressed.

2. The cheat: MatchCheatName `$5C68` compares each of the ten high-score names (`$8126`, 21-byte records) with "SLOPPY    " (`$8214`). On a match the keys 1-4 (`$F7FE`) held then pick the start: 1 = row `$06` column `$0D`, 2 = `$09`/`$12`, 3 = `$0F`/`$0E`, 4 = `$0F`/`$14`; else (and without the name) row 0 column 3 (room 4). The pair goes to MapRow `$69DF` / MapColumn `$69E0`.

3. `$5C9A`: three NOPs on a 48K; on a 128K the bootstrap writes `CALL $85C5` here (the 128K intro with music, bank 4 `$D3D0`).

4. Clears `$6D00-$6EFF` (HavokStashB, TakenItems, RevealedZones, HavokStashA, GoneEnemies), copies GlobalsInit to `$6642`, sets the six bytes `$76D8` to 1.

5. SpawnActor `$A65D` for Hiro (page `$5D00`, kind `$24`, template `$65CA`, BC = `$4804`); Hiro +`$02` = 7; `$88AE` = 0; CLS (`$8339`); tune command 2 (`$8452`).

6. The first room: IY = Hiro, `$95C3` (the map lookup and build), `$8365` (the score line), PanelAttrs `$FFEB` (Z in room 4: the attributes `$46`, else 7, through `$835A`), then the tick on (`$845F` = 0) and `JP $8DFE`, the main loop.

Witness: L1 20 (deaths, gameover, havok, hiscore, menu, throw, c x2, opt x3, rzx x2, rzxroom x1).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 15,792 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/rec/menu` 2, `stage1/rec/opt4` 2, `stage1/rec/opt2` 2 and 4 more) |
| Called from | `BuildPageTails` (tail), `IntroGlyphs` (tail) |
| Calls | `MatchCheatName`, `IntroScript`, `TitleSequence` |
| Reads | `$5C00`-`$5C37` (`GlobalsInit`, `ScoreLineInit`); `$6D00`-`$6EFE` (`HavokStashB`, `SpriteSetsTail`, `PageTail61`) |
| Writes | `$5D02` (`Hiro+2`); `$6642`-`$6679` (`Vitality`, `VitalityShown`, `ChargeStep`, `Charge` and 19 more); `$69DF`-`$69E0` (`MapRow`, `MapColumn`); `$6D00`-`$6EFF` (`HavokStashB`, `SpriteSetsTail`, `PageTail61`); `$76D8`-`$76DD` (`GateClosed`); `$8452`-`$845F` (`TuneRequest`, `InterruptHandler`); 1 more ranges |

### `MatchCheatName` (`$5C68`)

**Compare 10 bytes at HL with the cheat name `$8214` ("SLOPPY    "); on a match choose the start room by the keys 1-4**

HL = a high-score name. DE runs from `$8213` (pre-incremented), BC = 10 with CPI: a byte that differs returns NZ (BC as left). After ten equal bytes it does not return: it reads `$F7FE` (keys 1-5) and jumps into NewGame at `$5C96` with the start pair (C = row, B = column), so the rest of the name loop's stack (BC) is left behind; NewGame never returns, so the extra word does not matter.

Witness: L1 150 (deaths, gameover, havok, hiscore, menu, play48, throw, c x1, opt x3, rzx x1, rzxroom x1). The key branch is known only from the code (no keyed recording has SLOPPY in the table).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 10 calls, 762 t-states own (0.00 %) |
| Runs (the other recordings) | 80 calls (`stage1/rec/menu` 20, `stage1/rec/gameover` 20, `stage1/rec/opt3` 10 and 3 more) |
| Called from | `NewGame` |
| Calls | `ClearScreen`, `FillPlayAttributes`, `PrintScore`, `EnvelopeTimeCount`, `MainLoop` (tail), `EnterRoom`, `InitActor`, `PanelAttrsRoom` |
| Reads | `$8126`-`$813B` (`HiScoreEntries+9`); `$8150`-`$8165` (`HiScoreEntries+51`); `$817A` (`HiScoreEntries+93`); `$818F` (`HiScoreEntries+114`); `$81A4` (`HiScoreEntries+135`); `$81B9` (`HiScoreEntries+156`); 3 more ranges |

### `GameEntry` (`$5CFA`)

**The game's entry: the control menu, the intro, the page tails and tables, then NewGame**

Jumped to by the bootstrap (`JP Z,$5CFA` at `$4054` on a 48K, `JP $5CFA` at `$4092` on a 128K). ControlMenu `$6A7B`; then GameEntryIntro `$5CFD`.

Witness: L1 2 (c x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 53 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/c48` 1) |
| Calls | `ControlMenu` |

### `GameEntryIntro` (`$5CFD`)

**CALL Intro48 (the 128K bootstrap writes three NOPs over it), then build the page tails**

`CALL $5D4F` (Intro48); a 128K bootstrap overwrites these three bytes with `00 00 00` (its intro runs in NewGame instead). Then A = 10 rows, HL = PageTailTemplate `$6B5C`, D = `$5D` and BuildPageTails `$5D07`.

An entry of its own: the address is a routine entry of the tape loader's BASIC code in the recordings.

Witness: L1 11 (deaths, gameover, hiscore, menu, throw, c x2, opt x3, rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/opt2`, `stage1/rec/opt3`, `stage1/rec/deaths` and 3 more) |
| Calls | `BuildPageTails` (falls into), `Intro48` |
| Reads | `$6B5C`-`$7047` (`PageTailTemplate`, `ItemRecords`, `WalkLists`, `WeaponRecords` and 8 more) |
| Writes | `$5D82`-`$5FFF` (`Intro48+51`, `IntroScene`, `IntroPictureText`, `IntroText` and 8 more); `$6082`-`$60FF` (`SizeClasses`); `$6182`-`$61FF` (`SizeClasses+256`, `PrintGlyphs`, `PrintGlyphsLoop`, `PrintGlyphsNext` and 1 more); `$6282`-`$62FF` (`IntroAttrsC+63`); `$6382`-`$63FF` (`IntroGlyphs+111`); `$6482`-`$64FF` (`IntroGlyphs+367`, `WeaponTemplate`); 3 more ranges |

### `BuildPageTails` (`$5D07`)

**Ten rows of 126 bytes from the template to +`$82`..+`$FF` of the pages `$5D-$66`, then the tables**

Each pass: BC = `$7E`, E = `$82`, LDIR (which leaves D one higher, the next page). Then:

- OutlineMask `$6F00`: for a = 0..255, NOT (a OR a<<1 OR a>>1) (the pixels next to none of a's), the mask for drawing a sprite's dark outline (`$8C0A`, `$8C0F`, `$8CAD`, `$A4D1`);

- RowBase `$7000`: 0, 20 ... 220, the first cell of each of the 12 rows (`$8EB5`, `$8F75`);

- NameBoxPlaces `$700C`: 5 rows x 6 words (E = `$34` + `$10` row, D = `$12` + 4 column), the screen places of the name entry's letter boxes;

- ClearRoomCells `$70EF` with C = `$DC`, B = `$24`: the cells `$DC-$FF` of the six planes (the spare cells and the row above) are cleared; `JP $5C4D` (NewGame).

An entry of its own: `$5D07` is also the BASIC line's code (the tape loader), so the recordings mark a routine entry here.

Witness: L1 122 (deaths, gameover, hiscore, menu, throw, c x2, opt x3, rzx x1, rzxroom x1).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 255,149 t-states own (0.02 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/c48` 2) |
| Called from | `GameEntryIntro` (falls into) |
| Calls | `NewGame` (tail), `ClearRoomCells`, `PanelAttrsRoom` (tail) |
| Reads | `$4000`-`$5AFE` (screen); `$5D37`-`$5E33` (`BuildBoxPlaceLoop+3`, `Intro48`, `IntroScene`, `IntroPictureText` and 6 more); `$6B5C`-`$7047` (`PageTailTemplate`, `ItemRecords`, `WalkLists`, `WeaponRecords` and 8 more) |
| Writes | `$4000`-`$5AFF` (screen); `$5D82`-`$5FFF` (`Intro48+51`, `IntroScene`, `IntroPictureText`, `IntroText` and 8 more); `$6082`-`$60FF` (`SizeClasses`); `$6182`-`$61FF` (`SizeClasses+256`, `PrintGlyphs`, `PrintGlyphsLoop`, `PrintGlyphsNext` and 1 more); `$6282`-`$62FF` (`IntroAttrsC+63`); `$6382`-`$63FF` (`IntroGlyphs+111`); 5 more ranges |
| Ports out | `$00FE`, `$7FFD` |

## menu

`src/game/menu.asm`

### `Intro48` (`$5D4F`)

**The 48K intro: five scenes from IntroScript, looping until fire is pressed**

Run only on a 48K (the 128K bootstrap removes the call at `$5CFD`). IY walks IntroScript `$5E4D` record by record:

1. CLS (`$8339` with A = 7); box (`$3090`, 8 x 5) round the eyes picture `$5E4D`, the text `$5E64` (FOR 10000 YEARS HE SLEPT ...), the text `$5EB5` (NOW HE HAS AWAKENED), the eye frames `$5F06`, `$5F10` (attribute `$42` at `$5A9C`), `$5F1A`, each with a wait of 1 x 5 frames, then 40 x 5 frames.

2. CLS; the attribute block IntroAttrsA `$6225` at `$5882` (5 rows of 3); box (`$0008`, 19 x 7) round the picture `$5F24` and the text `$5F56` (THE FIREBLADE SHATTERED ...); border white, IntroAttrsB `$6234`, a delay `$2000`, border black; the picture `$5FA0` and the text `$5FD2` (THEN THE SLAUGHTER BEGAN.).

3. CLS; IntroAttrsC `$6243` at `$5828` (13 rows of 16); box (`$0F00`, 18 x 15) round Havok's picture `$601E` (220 glyphs) and the text `$60FD` (NOW HAVOK REIGNS THE UNDERCITY.); the text `$6161` (I AM HIRO ...); a wait of 60 x 5 frames.

The waits `$831F`/`$8321` return Z when fire (`$8529`) is pressed: then it returns; else it starts again.

Witness: L1 3 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/c48` 1) |
| Called from | `GameEntryIntro` |
| Calls | `IntroScene`, `IntroPictureText`, `IntroText`, `IntroPictureWait`, `IntroPrint`, `CopyAttrBlock`, `WaitFireLong`, `WaitFireFrames`, `DelayBC`, `ClearScreen` |
| Ports out | `$00FE`, `$07FE` |

### `IntroScene` (`$5DD2`)

**A box, then the next picture and text of the script**

DE = the box's screen place, BC = its size: IntroBox `$5DFB`, then IntroPictureText.

Witness: L1 9 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rec/c48` 6) |
| Called from | `Intro48` |
| Calls | `IntroBox` |

### `IntroPictureText` (`$5DD5`)

**The next picture and text of the script, then a wait of 40 x 5 frames**

Witness: L1 12 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/c48` 2) |
| Called from | `Intro48` |
| Calls | `IntroPicture` |

### `IntroText` (`$5DD8`)

**The next text record of the script, then a wait of 40 x 5 frames (`$831F`)**

Witness: L1 15 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/c48` 2) |
| Called from | `Intro48` |
| Calls | `IntroPrint`, `WaitFireLong` (tail) |

### `IntroPictureWait` (`$5DDE`)

**The next picture record, then a wait of 1 x 5 frames**

H = 1 and `$8321`: the eye frames' step.

Witness: L1 9 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rec/c48` 6) |
| Called from | `Intro48` |
| Calls | `IntroPicture`, `WaitFireFrames` (tail) |

### `IntroPicture` (`$5DE6`)

**Draw the picture record at IY with IntroGlyphs; IY to the next record**

HL = IY, BC = IntroGlyphs `$6313`, PrintGlyphs `$61E5`.

Witness: L1 21 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14 calls (`stage1/rec/c48` 14) |
| Called from | `IntroPictureText`, `IntroPictureWait` |
| Calls | `IntroScriptNext` (tail), `PrintGlyphs` |

### `IntroPrint` (`$5DF1`)

**Print the text record at IY (`$837B`); IY to the next record**

Witness: L1 18 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 calls (`stage1/rec/c48` 12) |
| Called from | `Intro48`, `IntroText` |
| Calls | `PrintString` |

### `IntroScriptNext` (`$5DF7`)

**IY = HL, the record after the one just drawn**

Witness: L1 39 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 14 calls (`stage1/rec/c48` 14) |
| Called from | `IntroPicture` (tail) |

### `IntroBox` (`$5DFB`)

**Build a box of the font's frame glyphs as a text record at `$5B01` and print it**

DE = Y, X; B = the width, C = the height (in cells). The record: Y, X, style `$06` `$06`, the top row (`$22`, `$23` x (B-2), `$24`), `$FF`, C-2 side rows (`$25`, a skip of B-2 cells, `$25`, `$FF`), the bottom row (`$27`, `$28` x (B-2), `$29`), end; then `$837B` prints it.

Witness: L1 9 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rec/c48` 6) |
| Called from | `IntroScene` |
| Calls | `IntroBoxRow`, `IntroBoxSide`, `PrintString` |

### `IntroBoxRow` (`$5E34`)

**Store E, then B-2 times A, then D at HL (a box's top or bottom row)**

Witness: L1 18 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 calls (`stage1/rec/c48` 12) |
| Called from | `IntroBox` |

### `IntroBoxSide` (`$5E3F`)

**Store a box side row at HL: `$25`, a skip of B-2 cells, `$25`, `$FF`**

A code below `$20` in a text record skips that many cells (`$837B`).

Witness: L1 99 (c x1, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 66 calls (`stage1/rec/c48` 66) |
| Called from | `IntroBox` |

### `PrintGlyphs` (`$61E5`)

**Draw a picture record: B = Y, C = X, then glyph n at BC + 8(n-1), `$FF` a new line, 0 the end**

HL = the record, BC = the glyph set. The place is set by `$83CD`; each glyph is drawn by `$83F9` (8 bytes at BC + 8 (n-1)); `$FF` moves to the next line (`$83C6` holds the line start, `$83CD` again). Returns HL past the 0.

The entries PrintGlyphsLoop to PrintGlyphsLine are split off because stage 2's code occupies these addresses while the tape loads, and the recordings mark routine entries there.

Witness: L1 1141 (c x2, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 574 calls (`stage1/rec/c48` 574) |
| Called from | `IntroPicture`, `IntroScript` (falls into) |
| Calls | `IntroScript` (tail), `PrintGlyphsLoop` (falls into), `PrintGlyphsByte`, `SetPrintPosition` |

### `PrintGlyphsLoop` (`$61F0`)

**The next byte of the record**

Witness: L1 1086 (c x1, rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 724 calls (`stage1/rec/c48` 724) |
| Called from | `PrintGlyphs` (falls into), `PrintGlyphsRestore` (tail) |
| Calls | `PrintGlyphsNext` (falls into) |

### `PrintGlyphsNext` (`$61F1`)

**0 ends the record**

Witness: L1 1246 (c x2, rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 724 calls (`stage1/rec/c48` 724) |
| Called from | `PrintGlyphsLoop` (falls into) |
| Calls | `IntroScript` (tail), `PrintGlyphsByte` (falls into) |

### `PrintGlyphsByte` (`$61F5`)

**`$FF`: a new line; else the glyph's address**

Witness: L1 1227 (c x2, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 81 calls, 4,069 t-states own (0.00 %) |
| Runs (the other recordings) | 791 calls (`stage1/rec/c48` 791) |
| Called from | `IntroScript`, `PrintGlyphs`, `PrintGlyphsNext` (falls into) |
| Calls | `PrintGlyphsAddress` (falls into) |

### `PrintGlyphsAddress` (`$6200`)

**HL = 8(n-1) + the glyph set; draw it (`$83F9`)**

Witness: L1 1122 (c x2, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 82 calls, 590,837 t-states own (0.04 %) |
| Runs (the other recordings) | 719 calls (`stage1/rec/c48` 719) |
| Called from | `IntroScript`, `PrintGlyphsByte` (falls into), `CopyAttrBlock` (tail) |
| Calls | `PrintGlyphsRestore` (falls into), `PrintGlyph` |
| Reads | `$622B`-`$672A` (`IntroAttrsA+6`, `IntroAttrsB`, `IntroAttrsC`, `IntroGlyphs` and 2 more); `$6746`-`$6765` (`TitleColours+76`); `$6781`-`$67A0` (`TitleColours+135`); `$67BC`-`$67DB` (`TitleColours+194`); `$67F7`-`$6816` (`TitleColours+253`); `$6832`-`$6851` (`TitleColours+312`); 1 more ranges |
| Writes | `$4803`-`$49BC` (screen); `$49E0`-`$4ABC` (screen); `$4AE0`-`$4BBC` (screen); `$4BE0`-`$4CBC` (screen); `$4CE0`-`$4DBC` (screen); `$4DE0`-`$4EBC` (screen); 2 more ranges |

### `PrintGlyphsDone` (`$6205`)

**The glyph is drawn: the next byte**

Witness: L1 1065 (c x1, rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 78 calls (`stage1/rec/c48` 78) |
| Called from | `PrintGlyphsLine` (tail) |
| Calls | `PrintGlyphsRestore` (falls into) |

### `PrintGlyphsRestore` (`$6206`)

**POP BC, back to the loop**

Witness: L1 2295 (c x2, rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,325 calls (`stage1/rec/c48` 1,325) |
| Called from | `PrintGlyphsAddress` (falls into), `PrintGlyphsDone` (falls into), `CopyAttrBlock` (tail) |
| Calls | `PrintGlyphsLoop` (tail), `PrintGlyphsLine` (falls into) |

### `PrintGlyphsLine` (`$620D`)

**Set the print place to BC (`$83CD`), back to the loop**

Witness: L1 1347 (c x2, rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 693 calls (`stage1/rec/c48` 693) |
| Called from | `PrintGlyphsRestore` (falls into) |
| Calls | `PrintGlyphsDone` (tail), `CopyAttrBlock` (falls into), `SetPrintPosition` |

### `CopyAttrBlock` (`$6212`)

**Copy B rows of C bytes from HL to the attributes at DE (DE + 32 a row)**

From Intro48 (IntroAttrsA/B/C).

Witness: L1 1299 (c x2, rzx x1). Ran only in c48.

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 661 calls (`stage1/rec/c48` 661) |
| Called from | `Intro48`, `PrintGlyphsLine` (falls into), `CopyAttrBlockCarry` (tail) |
| Calls | `PrintGlyphsAddress` (tail), `PrintGlyphsRestore` (tail), `CopyAttrBlockCarry` (falls into) |

### `CopyAttrBlockCarry` (`$621F`)

**The high byte of DE + 32**

Witness: L1 71 (c x2, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 10,634,187 t-states own (0.81 %) |
| Runs (the other recordings) | 47 calls (`stage1/rec/c48` 47) |
| Called from | `IntroScript`, `CopyAttrBlock` (falls into) |
| Calls | `CopyAttrBlock` (tail) |
| Writes | `$5D31`-`$5D32` (`BuildBoxRowLoop`) |

### `GlyphBytesAsCode` (`$66CD`)

**Not code: IntroGlyphs bytes that the kit must list as instructions**

These are bytes of IntroGlyphs (`$66CD-$66F6`, glyphs 120-125). At run time the page tail of `$6600` puts ShowMessage's `RRA` at `$66CD`, and the image holds the same byte `$1F` there, so the recordings count a ran instruction at this address and the disassembly goes on through the glyph bytes to `$66F6`. Nothing jumps here in the image.

Witness: L1 13 (gameover, hiscore, menu, opt x3, rzx x5).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `PauseLong` (tail), `ActorUpdate`, `InitActor` |

### `ControlMenu` (`$6A7B`)

**The control menu: keys 1-4 choose joystick 1, joystick 2, Kempston or Protek / cursor; patch the input code**

CLS (A = 0), print ControlMenuText `$6ACB` (`$836E`), wait for one of the keys 1-4 (`$F7FE`, read until one is held; key 1 first). HL = ControlRecords `$6B0A` + 14 x (key - 1); the record patches the input read:

- +0 the fire mask, to `$84CA` and to FirePrevious's start value `$5C06`;

- +1 the direction mask, to `$850F` and `$8511`;

- +2 `RRA` or `NOP`, to `$8513`;

- +3..+6 the opcodes `DEC E` / `INC E` / `INC D` / `DEC D` in the record's direction order, to `$851A`, `$851E`, `$8522`, `$8526`;

- +7 on: 18 bytes of code copied to `$8529`, the fire test (Z when fire).

Called from GameEntry once (the menu is not shown again).

Witness: L1 2 (c x2). Ran in c1 and c48.

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 35,348,945 t-states own (2.68 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/c48` 1) |
| Called from | `GameEntry` |
| Calls | `ClearScreen`, `PrintStringTall` |
| Reads | `$6B34`-`$6B4C` (`ControlRecords+42`) |
| Writes | `$5C06` (`GlobalsInit+6`); `$84CA` (`TickInput+11`); `$850F`-`$853A` (`DecodeDirection+1`, `ReadInput`, `ReadInputSpace`) |
| Ports in | `$F7FE` |

### `ControlMenuKey` (`$6A91`)

**The next key (bit) of 1-4**

Witness: L1 9813588 (deaths, gameover, hiscore, menu, throw, c x2, opt x3, rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`, `stage1/rec/gameover`, `stage1/rec/opt4` and 3 more) |
| Reads | `$6B0A`-`$6B4C` (`ControlRecords`) |
| Writes | `$5C06` (`GlobalsInit+6`); `$84CA` (`TickInput+11`); `$850F`-`$853A` (`DecodeDirection+1`, `ReadInput`, `ReadInputSpace`) |
| Ports in | `$F7FE` |

### `ShowHighScores` (`$A6EC`)

**Hold the finished logo 4 s, then show the high-score table 4 s**

Reached from TitleSequence (`JP` at `$A7CA`) when the second wave of pieces is in. 40 times: the fire test (the hook `$A6EF`) and WaitFire `$8321` with H = 1 (5 frames); fire returns to the caller of TitleSequence (`$5C55`: the game starts).

Then the screen is cleared black and printed (`$837B` / `$836E`): the header `$80FB` "RANK SCORE NAME"; ten rank lines "NO.1" to "NO.10" from the record `$810F` (Y from `$14` in steps of 16, X 2), its two digits written at `$8116` / `$8117` (`" 1"`... `" 9"`, then `"10"` printed as E = '1', D = '0'); the table `$8119` (ten lines of score and name, the tall font) and the copyright line `$81F0`. WaitFire `$831F` (40 x 5 frames) returns on fire, else falls into TitleSequence.

26 runs (c48, gameover, menu).

Witness: L1 32 (gameover, havok, hiscore, menu, c x1, rzx x2, rzxroom x1).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `WaitFireLong`, `WaitFireFrames`, `ClearScreen`, `PrintStringTall`, `PrintString`, `ReadInput`, `SweepSpanHalf` |

### `TitleSequence` (`$A73E`)

**The title: the SWITCHBLADE logo assembled from flying pieces, until fire is pressed**

Called from `$5C52` (after the controls menu and after every game). Returns when fire is pressed (Z), to `$5C55`, which starts a game.

`$76D0` = `$B6` (the low byte of the pointer into the piece order `$76B6`), `$76D1` = 0 (the stage); the handler flag `$845F` = 1 (no game tick). The screen is cleared with the next attribute of the six at `$66FA-$66FF` (the operand of `LD HL,n` at `$A74A` steps through them and wraps): the logo's colour changes every cycle. The hook `$A75C` (128K: CALL `$85B3`, print the music or effects sign). LoadTitlePieces `$A7D7` sets up the first wave: 15 pieces from `$7600` into the pages `$5D00-$6B00`.

TitleStep `$A766`, once a pass: from the fourth piece on, the fire test (the hook `$A76F`; Z returns). IY = the page of the moving piece (`$76B6` + stage); its timer +`$3F` counts down; at 0 the effect `$0B` is asked (`$8454`) and the next piece moves (`$76D0`, `$76D1` + 1). The piece moves by its +`$40` (Y) and +`$41` (X) (`$9B71`), `$8F3B` places it, the rows of its area are cleared, and the pieces are drawn (`$8A79` with B = the piece count, `$8C68`).

Stage `$0F` (15 pieces in): the stage becomes `$10` and the second wave of 11 pieces is loaded from `$7669`. Stage `$1A`: `$65EE` (code put there at run time: the attributes `$59E0-$5ADF` = `$47`) on each pass. Stage `$1B`: ShowHighScores `$A6EC`.

38 runs; TitleStep 8666 (c1, c48, deaths, gameover, menu, opt2-4).

Witness: L1 47 (deaths, gameover, havok, hiscore, menu, throw, c x2, opt x3, rzx x2, rzxroom x1).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 436,804 t-states own (0.03 %) |
| Runs (the other recordings) | 12 calls (`stage1/rec/menu` 2, `stage1/rec/gameover` 2, `stage1/rec/opt2` 2 and 4 more) |
| Called from | `NewGame` |
| Calls | `IntroGlyphs`, `ClearScreen`, `ReadInput`, `SweepSpanHalf`, `SetEnvelopeState`, `DrawActors`, `BlitWindow`, `ActorBoxStore`, `AddMove`, `InitActor` |
| Reads | `$5D3F`-`$6541` (`BuildBoxPlaceLoop+11`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$663F`-`$6641` (`WeaponActor+63`); `$66FA`-`$66FF` (`TitleColours`); `$673F`-`$6741` (`TitleColours+69`); `$683F`-`$6841` (`TitleColours+325`); `$693F`-`$6941` (`EnemySlots+99`); 5 more ranges |
| Writes | `$5D0A`-`$6669` (`BuildPageTails+3`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$670A` (`TitleColours+16`); `$673F`-`$6769` (`TitleColours+69`); `$680A` (`TitleColours+272`); `$683F`-`$6869` (`TitleColours+325`); `$690A` (`EnemySlots+46`); 11 more ranges |

### `InsertHighScore` (`$A806`)

**Put the score into the high-score table and ask for the name**

Called from `$5C45` (the game's end; the game over `$5C42` comes in there too). The score's 8 ASCII digits `$665B-$6662` are compared with each entry's 8 digits (`$811D` + 21 i), from the top: an 8-byte subtraction with borrow from the last digit; the first entry the score is not below is the place (a tie goes above). Below the tenth: return.

Entries i to 8 move down one place (LDDR of 21 x (9 - i) bytes ending at `$81EE`; C counts it from `$BD` = 189 and ends at `$EB`), the digits go in, the name position `$A8C9` = 0, the handler flag `$845F` = 1, the screen is cleared black, EnterName `$A861`; the typed name (`$82C2-$82CB`, '-' turned into spaces) is copied into the entry's 10 name bytes.

1 run (gameover: the score was not high enough, `$A826` returned). The entry ran in the RZX run: segment r140000 (work/stage2/rzx/r140000), InsertHighScore at frame 1007 with the score 00342890 (place 1), EnterName at 1010.

Witness: L1 8 (gameover, havok, hiscore, rzx x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/gameover` 1) |
| Called from | `GameOver` |
| Reads | `$665B`-`$6662` (`ScoreDigits`); `$811D`-`$81E1` (`HiScoreEntries`) |
| Writes | `$A8C9` (`EnterNamePut+1`) |

### `EnterName` (`$A861`)

**Name entry: a grid of letters, a box moved with the controls, fire types**

The name buffer `$82C2-$82CB` = ten '-' (the empty-slot glyph, an underscore). Hiro's Y and X bytes are the cursor: `$5D00` the row (0-4), `$5D01` the column (0-5), set to 4, 5 (the END sign). The underline record `$82CD` = Y `$A0`, X `$12`. Printed: "WELL DONE! YOU HAVE A HIGH SCORE" / "PLEASE ENTER YOUR NAME" (`$822C`, the tall font), the grid `$826A` (A-Z, '!', a blank, '<' delete, '+' END, 6 x 5) and the box `$82AE`; ten delays `$8330` (about 2 s, so the fire that ended the game does not type).

The loop: the name `$82BE` (tall) and the underline `$82CD` (" / ": the '/' glyph is a bar under the next letter); then `$8529` (the chosen control's reader: Z = fire, A = the direction bits) and `$850E` (E = the row step, D = the column step, carry when one is pressed) until fire; a direction moves the box (MoveNameBox `$A8E2`).

Fire (`$A8A1`): a short delay; NameLetterIndex `$A91B`: 0-25 types 'A'-'Z', 26 '!', 27 a space, 28 deletes ('-' at the position and one back), 29 (END) returns. Typing writes at the position `$A8C9` (the operand of `LD A,n` at `$A8C8`) and moves on, at most to the tenth (the tenth can be typed over); the underline's X (`$82CE`) moves 2 a letter.

The hiscore recording (the score POKEd to 00500000 before the last life) enters ZX at frames 2517-3229; havok enters the RZX player's name; r140000 frames 1010-2000 (docs/img/play/name-entry.gif, docs/img/text/screens.png).

Witness: L1 7 (havok, hiscore, rzx x5).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MoveNameBox` (`$A8E2`)

**Move the name-entry box by E rows and D columns, inside the 6 x 5 grid**

A step out of the grid is ignored. The box is erased at its old place (its Y and X copied from `$82AE` into the blank record `$80EB`, printed), the new Y and X come from the word table `$700C` (2 bytes a sign, by NameLetterIndex) and the box is printed (`$82AE`); then a delay (`$8330`). hiscore: 10 runs, frames 2769-3183; r140000: 25 runs from frame 1187 (docs/img/routines/MoveNameBox.gif).

Witness: L1 17934 (hiscore, rzx x5).

[Animation: `MoveNameBox` at work](img/routines/MoveNameBox.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NameLetterIndex` (`$A91B`)

**A = row x 6 + column of the name-entry box (0-29)**

BC = (`$5D00`): C the row, B the column; `$8EDD` gives 6 x row. hiscore: 13 runs; r140000: called by the 25 MoveNameBox runs from frame 1187 (docs/img/routines/MoveNameBox.gif).

Witness: L1 87 (havok, hiscore, rzx x5).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## rooms

`src/game/rooms.asm`

### `ClearRoomCells` (`$70EF`)

**Clear B cells from C in the six room planes `$6700-$6C00`**

A = 0, L = C; for each cell the six planes `$67`-`$6C`. From BuildPageTails (`$DC`, `$24` cells: the spare cells and the row above), and the room build `$9F3D` (C = `$EC`, B = `$14`: the row above) and `$9F6A` (C = 0, B = `$DC`: the whole room).

Witness: L1 424 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x56, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7 calls, 87,912 t-states own (0.01 %) |
| Runs (the other recordings) | 47 calls (`stage1/rec/rooms` 14, `stage1/rec/deaths` 13, `stage1/rec/gameover` 5 and 5 more) |
| Called from | `BuildPageTails`, `BuildRoomPlanes`, `DecodeRoom` |
| Writes | `$6700`-`$6CFF` (`TitleColours+6`, `ControlMenu`, `ControlMenuKey`, `ControlMenuText` and 9 more) |

### `RoomPatch` (`$72DE`)

**Room opcode handler: fix-ups for rooms 1 and 8 in the cell property plane `$6C00`**

Reached through the room opcode table (`$73C7`, `JP (HL)` at `$A015`). Room 1: the ten cells `$78-$81` of `$6C00` get the property `$20`; room 8: the cells `$5A`, `$5B`, `$6E`, `$6F` get 0. Other rooms: nothing.

Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 297 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/rooms`, `stage1/rec/deaths`, `stage1/rec/menu` and 4 more) |
| Called from | `JumpViaTable` |
| Reads | `$6BDD` (`Room`) |
| Writes | `$6C5A`-`$6C5B` (`PageTail5F+2`); `$6C6E`-`$6C81` (`PageTail5F+22`) |

### `CheckRoomExit` (`$955A`)

**After a move of Hiro: cross into the next room when he reaches an edge**

Reached by `JP $955A` from AnimateAfterMove `$9B97` after every move of Hiro (kind `$24`), H = `$5D`: 2348 runs in the play recordings.

C = -(Hiro +`$3D`), the X offset an animation in progress has added, so the X test sees the true position.

**The rows.** Tested when Hiro is on a ladder (`$5D02` bit 3), or when his top is inside the room (`$5D20` bit 5 clear, set by `$9000` when the Y is past the top): so he leaves a room upwards only by a ladder or a jump that stays inside. Y = `$A0` steps the row down (`$69DF` + 1) and puts him at Y `$F0` (-16); Y = `$EC` (-20) steps it up and puts him at `$9C`.

**The columns.** X + C = `$9E` steps the column right (`$69E0` + 1) and puts him at X `$FC`; `$FA` steps it left and puts him at `$9C`. The Y goes back to its value before this move (the operand at `$95B4`, written by ApplyMove `$9B59`): the step's vertical part is undone.

**No edge.** `$8F75` (his box and clip bits again) and `$A569` (is the reveal block under or ahead of him new?): a new block is added to `$6DFF`, drawn (`$8855`) and its objects spawned (`JP $A59E`): the rooms are revealed block by block as Hiro walks.

**A crossing.** In Havok's room (123, `$7B`) `CALL $5FCB` first (code in actor page `$5F`); `$A58A` keeps the old room's reveal and taken bytes `$6DFE-$6DFF` and loads the next room's; then falls into EnterRoom `$95C3`. The c1 walk: 13 column crossings (c1, deaths, gameover, rooms), 2 row crossings (deaths, rooms).

Witness: L1 42125 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 235 calls, 61,255 t-states own (0.00 %) |
| Runs (the other recordings) | 2,113 calls (`stage1/rec/deaths` 949, `stage1/rec/rooms` 576, `stage1/rec/gameover` 144 and 4 more) |
| Called from | `AnimateAfterMove` (tail) |
| Calls | `RedrawCellsMasked`, `ActorScreenBox`, `RevealZone`, `SaveRoomState`, `SpawnZoneEnemies` (tail) |
| Reads | `$5D00`-`$5D02` (`Hiro`); `$5D20` (`BuildOutlineMaskLoop+12`); `$5D3D` (`BuildBoxPlaceLoop+9`); `$6651` (`Invulnerable`); `$69DF`-`$69E0` (`MapRow`, `MapColumn`); `$6BDD` (`Room`) |
| Writes | `$5D00`-`$5D01` (`Hiro`); `$69DF`-`$69E0` (`MapRow`, `MapColumn`); `$6BDC`-`$6BDD` (`RoomAbove`, `Room`) |

### `EnterRoom` (`$95C3`)

**Find the room at the map row and column and build it**

Falls in from CheckRoomExit `$955A` and is called by `$5C68` (the start of a game and of a life): 23 runs.

`$6BDC` = the room above (FindRoom `$95F9` of row - 1, 0 on row 0); `$6BDD` = the room (FindRoom of the row). Room 123 (`$7B`, Havok's) calls `$5FD4` first. Then BuildRoomPlanes `$9F34` (the cell planes), `$A41E`, `$8852` (draws the revealed cells), `$A59B` (spawns the objects of the revealed blocks), and when the energy ball or the death wait is on (`$6651` not 0) RestoreShield `$995C` puts it back around Hiro.

Out: A = the value BuildRoomPlanes returned (kept over the calls).

Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

[Animation: `EnterRoom` at work](img/routines/EnterRoom.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 804 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/menu` 2, `stage1/rec/deaths` 1, `stage1/rec/gameover` 1 and 3 more) |
| Called from | `MatchCheatName` |
| Calls | `RedrawRoomMasked`, `FindRoom`, `RestoreShield`, `BuildRoomPlanes`, `SetupRoomObjects`, `SpawnRoomEnemies` |
| Reads | `$6651` (`Invulnerable`); `$69DF` (`MapRow`); `$6BDD` (`Room`) |
| Writes | `$6BDC`-`$6BDD` (`RoomAbove`, `Room`) |

### `FindRoom` (`$95F9`)

**The room number at map row A and column `$69E0`**

A = the map row (0-19). `$70C7`+row is the number of rooms in the row, `$70DB`+row the offset of its first column in the column list `$7048`; CPIR searches that stretch for the column `$69E0`. Out: A = the position found + 1 - (`$7048` - 1): the room number 1-127, or 0 when the column has no room (`$9613`, the rooms recording's 4 failed lookups when it wrote the map variables by hand). B must be 0 (EnterRoom `$95C3`).

Witness: L1 375 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 645 t-states own (0.00 %) |
| Runs (the other recordings) | 25 calls (`stage1/rec/rooms` 11, `stage1/rec/deaths` 7, `stage1/rec/menu` 2 and 4 more) |
| Called from | `EnterRoom` |
| Reads | `$69E0` (`MapColumn`); `$7048`-`$7062` (`MapColumns`); `$70C7`-`$70DF` (`MapRowCounts`, `MapRowStarts`) |

### `BuildRoomPlanes` (`$9F34`)

**Decode the room (and the bottom row of the room above) into the cell planes**

From EnterRoom `$95E3`: 23 runs. With no room above (`$6BDC` = 0) the spare row `$EC-$FF` of the six planes is cleared (`$70EF`). Else the room above is decoded first (`$A3C9` gives its data, DecodeRoom with A = `$FF`: walls and object types below `$0D` only) and its bottom row (cells `$C8-$DB`) is copied to `$EC-$FF` in the planes `$68-$6B` (deaths, rooms: 2). Then the room `$6BDD` (DecodeRoom with A = 0). Out: A = 0.

Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

[Animation: `BuildRoomPlanes` at work](img/routines/BuildRoomPlanes.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 946 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/rooms` 7, `stage1/rec/deaths` 6, `stage1/rec/gameover` 2 and 4 more) |
| Called from | `EnterRoom` |
| Calls | `ClearRoomCells`, `DecodeRoom` (falls into), `RoomDataAddress` |
| Reads | `$68C8`-`$68DB` (`TitleColours+462`); `$69C8`-`$69DB` (`EnemySlots+236`); `$6AC8`-`$6ADB` (`ControlMenuPatch+47`, `ControlMenuText`); `$6BC8`-`$6BDD` (`ItemRecords+28`, `PageTail5E`, `RoomAbove`, `Room`); `$A9C6` (`Room4`); `$A9D8` (`Room5`) |
| Writes | `$68EC`-`$68FF` (`EnemySlots+16`); `$69EC`-`$69FF` (`FireHeld+9`); `$6AEB`-`$6AFF` (`ZoneRecords+10`); `$6BEC`-`$6BFF` (`CellProperty+9`) |

### `DecodeRoom` (`$9F63`)

**Decode a packed room at BC into the cell planes**

BC = the room's data (the table `$7100`, a word a room, `$A3C9`), A = `$FF` for the room above (`$6AEB`). All 220 cells of the six planes cleared (`$70EF`).

**The walls.** A header byte: bits 0-2, 3-5 and 6-7 count the runs of three groups (E = 3, 2, 1: the pattern starts 0, 1 or 2 entries later). A run: a byte (low nibble: a pattern in the table `$7300`; high nibble: the steps), the start cell. Each step reads a pattern byte: bit 7 set puts the tile pair 2, 3 in two cells, else tile 1, in plane `$68` with plane `$67` = 1 (`$A408`); bits 0-5 the step to the next cell; bit 6 goes back to the pattern's start.

**The objects** (NextObjectGroup `$9FD6`): groups of a type byte (low nibble the type, high nibble the count - 1) and their bytes, dispatched through the table `$73C7` (DispatchObject). The room above stops at type `$0D`.

Witness: L1 279 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 calls (`stage1/rec/rooms` 8, `stage1/rec/deaths` 7) |
| Called from | `BuildRoomPlanes` (falls into) |
| Calls | `ClearRoomCells`, `NextObjectGroup` (falls into), `OpHighNibble`, `PutTileMarkA` |
| Reads | `$6BDE` (`Room+1`); `$7300`-`$7344` (`RoomPatternStarts`, `RoomPatterns`, `DrawColumnPos`, `RoomPatternsMore`); `$A928`-`$A930` (`Room1`); `$A97D`-`$A983` (`Room2`); `$A9B0` (`Room3`); `$A9C6` (`Room4`); 8 more ranges |
| Writes | `$6AEB` (`ZoneRecords+10`); `$6BDE` (`Room+1`) |

### `NextObjectGroup` (`$9FD6`)

**An object group: the type and the count**

Also reached from `$A016`, `$A1F1` (the last of a group). Type `$0D`: the count is (high nibble & 1) + 2.

Witness: L1 1770 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9 calls, 981 t-states own (0.00 %) |
| Runs (the other recordings) | 112 calls (`stage1/rec/rooms` 57, `stage1/rec/deaths` 34, `stage1/rec/gameover` 6 and 4 more) |
| Called from | `DecodeRoom` (falls into), `ObjectLoop` (tail), `ObjectPattern` (tail), `RoomOpFillBack` (tail) |
| Calls | `NextObject` (falls into), `OpHighNibble` |
| Reads | `$A931`-`$A963` (`Room1+9`); `$A984`-`$A99E` (`Room2+7`); `$A9B1`-`$AA3B` (`Room3+1`, `Room4`, `Room5`, `Room6` and 2 more); `$AA54`-`$AA76` (`Room9+15`); `$AAFC`-`$AB29` (`Room11+19`); `$AC08`-`$AC3A` (`Room14+27`); 3 more ranges |
| Writes | `$6AE9`-`$6AEA` (`ZoneRecords+8`) |

### `NextObject` (`$9FEE`)

**The next object of the group**

Witness: L1 5695 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 236 calls (`stage1/rec/rooms` 167, `stage1/rec/deaths` 69) |
| Called from | `NextObjectGroup` (falls into), `RoomOpNext` (tail), `RoomOpLedge` (tail) |
| Calls | `ObjectLoop` (falls into) |

### `ObjectLoop` (`$9FEF`)

**Count the group; dispatch the type**

Witness: L1 5736 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 12 calls, 1,352 t-states own (0.00 %) |
| Runs (the other recordings) | 273 calls (`stage1/rec/rooms` 170, `stage1/rec/deaths` 75, `stage1/rec/menu` 8 and 4 more) |
| Called from | `NextObject` (falls into), `BuildSurface` (tail) |
| Calls | `NextObjectGroup` (tail), `JumpViaTable` (tail) |
| Reads | `$6AE9`-`$6AEB` (`ZoneRecords+8`); `$73CD`-`$73D0` (`RoomCodeHandlers+6`); `$73E5`-`$73E6` (`ActorKindHandlers`) |
| Writes | `$6AE9` (`ZoneRecords+8`) |

### `ObjectTypeB` (`$A006`)

**Type `$0B`: a second table `$75EF`, by bits 4-7 of the next byte**

Witness: L1 183 (bossgate, deaths, play48, rooms, poke-room x8, rzx x19, rzxroom x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `JumpViaTable` (falls into) |
| Reads | `$A956`-`$A958` (`Room1+46`); `$A99A` (`Room2+29`); `$AA2A`-`$AA2E` (`Room8+19`); `$AA6E`-`$AA72` (`Room9+41`); `$AC19`-`$AC1B` (`Room14+44`); `$ADB2` (`Room18+46`) |

### `JumpViaTable` (`$A00F`)

**JP (the word at HL + A)**

Witness: L1 4889 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 206 calls (`stage1/rec/rooms` 141, `stage1/rec/deaths` 65) |
| Called from | `ObjectLoop` (tail), `ObjectTypeB` (falls into) |
| Calls | `RoomPatch`, `ObjectTypeB`, `ObjectPattern`, `BuildSurface`, `ObjectRunH75AD`, `ObjectRunH7511`, `RoomOpStripDown`, `RoomOpStrip69`, `RoomOpStrip6A`, `RoomOpStrip68`, `SubOpPillar`, `SubOpColumn31`, `SubOpColumnTop30`, `SubOpClearMark`, `RoomOpFillBack`, `RoomOpLedge` |
| Reads | `$73CB`-`$73E6` (`RoomCodeHandlers+4`, `ActorKindHandlers`); `$75F3`-`$75FA` (`RoomCodeHandlersB+4`) |

### `ObjectPattern` (`$A016`)

**Types 0-3: tile patterns in plane `$68` + type**

For each of the group's objects (the count in E): a start cell, a pattern offset in page `$73` (PlotPattern), one byte skipped. Then the next group. 25 runs.

Witness: L1 208 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x13, rzx x39, rzxroom x13).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 1,393 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/rooms`, `stage1/rec/deaths`, `stage1/rec/menu` and 4 more) |
| Called from | `JumpViaTable` |
| Calls | `NextObjectGroup` (tail), `PlotPattern` |
| Reads | `$A949`-`$A955` (`Room1+33`); `$A98E`-`$A999` (`Room2+17`); `$A9BF`-`$A9DF` (`Room3+15`, `Room4`, `Room5`); `$A9F3`-`$A9F9` (`Room6+15`); `$AA0C`-`$AA10` (`Room7+10`); `$AA31`-`$AA39` (`Room8+26`); 4 more ranges |

### `PlotPattern` (`$A02E`)

**Put the tiles of the pattern DE from cell L on**

The pattern: a tile, then pairs of a step (a byte below `$80`) and a tile; a byte from `$80` ends it.

Witness: L1 1316 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x13, rzx x39, rzxroom x13).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 12 calls, 1,546 t-states own (0.00 %) |
| Runs (the other recordings) | 81 calls (`stage1/rec/rooms` 26, `stage1/rec/deaths` 23, `stage1/rec/menu` 10 and 4 more) |
| Called from | `ObjectPattern` |
| Reads | `$7313`-`$731A` (`RoomPatterns+3`); `$7345`-`$7394` (`RoomShapes`) |
| Writes | `$6AA4` (`ControlMenuPatch+11`); `$6AB8` (`ControlMenuPatch+31`); `$6B17`-`$6B33` (`ControlRecords+13`); `$6B45`-`$6B47` (`ControlRecords+59`); `$6B59`-`$6B83` (`ControlGap+12`, `PageTailTemplate`); `$6B9F`-`$6BBB` (`PageTailTemplate+67`, `ItemRecords`); 2 more ranges |

### `BuildSurface` (`$A039`)

**Type 4: the surface rooms' sky, horizon and ground**

Plane `$6C` cells 0-`$77` = `$20`; plane `$68` rows 0-3 = tiles `$33`, `$34`, `$35`, `$36`; row 4 = 20 bytes from `$74F5` + room (the horizon moves with the room); tile `$37` at cell 9 - room (rooms below 10), tile `$43` at `$54` - room (rooms from 5); a row of tiles `$3C-$3E` and a row of `$81-$83` in plane `$6B` (solid, attribute `$20`), each tile differing from the one before, the choice taken from the bytes of the ROM from `$0000` + 257 - room, the 48K keyword table (NextGroundVariant). Room 123 (Havok's) gets only the second row, 14 cells from `$C8`. 19 runs (c1 and the play recordings: rooms 1-7).

Witness: L1 41 (deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, rzx x2, rzxroom x6).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 26,427 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`, `stage1/rec/gameover` and 4 more) |
| Called from | `JumpViaTable` |
| Calls | `ObjectLoop` (tail), `NextGroundVariant`, `PutTileMarkPropA` |
| Reads | `$6BDD` (`Room`); `$74F6`-`$7511` (`RoomStrip`, `StructureSetD`) |
| Writes | `$6800`-`$6877` (`TitleColours+262`); `$6BE3` (`CellProperty`); `$6C00`-`$6C77` (`CellProperty+29`, `WalkLists`, `WeaponRecords`) |

### `NextGroundVariant` (`$A0AD`)

**A = 1-3 from the next data byte, not equal to D**

Reads bytes of the ROM from `$0000` + 257 - room as a source of variation (BC was reused: the `LDIR` at `$A070` leaves B = 0, `LD C,A` at `$A075` puts 256 - room in C): the 48K keyword table, the same on the 128K's ROM 1. Bits 0-1 (0 counts as 1), until it differs from the last (D). Out: D = A.

Witness: L1 2432 (deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, rzx x2, rzxroom x6).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 120 calls, 9,905 t-states own (0.00 %) |
| Runs (the other recordings) | 640 calls (`stage1/rec/deaths` 240, `stage1/rec/rooms` 120, `stage1/rec/gameover` 80 and 4 more) |
| Called from | `BuildSurface` |

### `ObjectRunH75AD` (`$A0B9`)

**Type 5: a horizontal run from the records at `$75AD`**

Witness: L1 68 (rooms, poke-room x1, rzx x11, rzxroom x4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `ObjectRunH` (tail) |

### `ObjectRunH7511` (`$A0BE`)

**Type `$0A`: a horizontal run from the records at `$7511`**

Witness: L1 1633 (bossgate, deaths, play48, rooms, poke-room x13, rzx x53, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `ObjectRunH` (falls into) |

### `ObjectRunH` (`$A0C1`)

**Carry set: a horizontal run (step 1); `$A0EE`, `$A101`**

The run's record (6 bytes: plane, end tiles, the middle tiles) is chosen by the high nibble (`$A0EE`); `$A109` lays it, step 1 with carry, `$14` (a column) without.

Witness: L1 1701 (bossgate, deaths, play48, rooms, poke-room x13, rzx x53, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 46 calls (`stage1/rec/rooms` 46) |
| Called from | `ObjectRunH75AD` (tail), `ObjectRunH7511` (falls into) |
| Calls | `StripFromRecord` (tail) |

### `ObjectRunV7400` (`$A0C4`)

**Type 6: a vertical run from the records at `$7400`**

`LD HL,$7400` / `JR $A0CC` (OR A: carry clear, step `$14`) into `$A0C9`'s tail. Reached only through the table `$73C7` (type 6); not run in the keyed recordings.

Witness: L1 298 (poke-room x3, rzx x26, rzxroom x7). Not run in the keyed recordings.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RoomOpStripDown` (`$A0C9`)

**Room opcode 9: a vertical strip from the strip records at `$7436`**

Opcode 9 of the room data (dispatch table `$73C7` entry 9). HL = the strip records `$7436` (16 records of 6 bytes), carry clear: the strip runs down (step 20). Falls into StripFromRecord `$A0CD`, which picks the record by the high nibble of the opcode byte, takes the layer page from the record and draws the run (DrawStrip `$A109`).

The neighbours `$A0B9` (opcode 5, `$75AD`, across), `$A0BE` (opcode 10, `$7511`, across) and `$A0C4` (opcode 6, `$7400`, down; not run in the keyed recordings) lie before this range and join here.

Witness: L1 1100 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14). Runs in deaths and rooms (45 in all).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`, `stage1/rec/deaths`) |
| Called from | `JumpViaTable` |
| Calls | `StripFromRecord` (falls into) |

### `StripFromRecord` (`$A0CD`)

**Draw a strip whose layer page is in its record**

In: HL = a strip table, carry = across (set) or down (clear), BC at the opcode byte. StripRecordAddress `$A0EE` points IX at record (high nibble of (BC)); StripPageFromRecord `$A101` takes the page from the record's byte 0 (bit 7 off) and DrawStrip `$A109` draws.

Callers: opcodes 5, 6, 9 and 10 (`$A0B9`, `$A0BE`, `$A0C4`, RoomOpStripDown `$A0C9`). 109 runs (deaths, rooms).

Witness: L1 3099 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 109 calls (`stage1/rec/rooms` 84, `stage1/rec/deaths` 25) |
| Called from | `ObjectRunH` (tail), `RoomOpStripDown` (falls into) |
| Calls | `StripRecordAddress` |
| Reads | `$7436`-`$745A` (`StructureSetB`); `$746C`-`$7478` (`StructureSetB+54`); `$748A`-`$7490` (`StructureSetB+84`); `$7511`-`$7553` (`StructureSetD`); `$75B3`-`$75BF` (`StructureSetF+6`) |

### `RoomOpStrip69` (`$A0D2`)

**Room opcode 7: a strip on layer `$6900` from the records at `$7571`**

A = `$69`, the layer page; joins StripOnLayer `$A0D8`. 9 runs (rooms).

Witness: L1 148 (rooms, poke-room x6, rzx x17, rzxroom x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `StripOnLayer` (tail) |

### `RoomOpStrip6A` (`$A0D6`)

**Room opcode 8: a strip on layer `$6A00` from the records at `$7571`**

A = `$6A`; falls into StripOnLayer `$A0D8`. 3 runs (deaths, rooms).

Witness: L1 133 (deaths, play48, rooms, poke-room x6, rzx x14, rzxroom x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `StripOnLayer` (falls into) |

### `StripOnLayer` (`$A0D8`)

**StripOnLayer**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11 calls (`stage1/rec/rooms` 11) |
| Called from | `RoomOpStrip69` (tail), `RoomOpStrip6A` (falls into) |
| Calls | `StripRecordAddress`, `DrawStrip` (tail) |

### `RoomOpStrip68` (`$A0E2`)

**Room opcode 12: a strip on the wall layer `$6800` from the records at `$7496`**

A = `$68`, HL = `$7496` (20 records). StripRecordAddress `$A0EE` returns A = the low byte of the record address: records below `$74DE` (the first 12) run across, the others down; then DrawStrip `$A109` with the page `$68`. 2 runs (rooms).

Witness: L1 106 (rooms, poke-room x1, rzx x14, rzxroom x4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `StripRecordAddress`, `DrawStrip` (tail) |

### `StripRecordAddress` (`$A0EE`)

**IX = a strip table + 6 x (the opcode byte's high nibble)**

In: HL = the table, A = the layer page (opcodes 7, 8, 12), BC = the opcode byte, F = the direction (kept). `OpHighNibble` `$A3E1` gives E = (BC) >> 4; `$8EDD` multiplies 6 x E; IX = HL + 6E. Out: IX = the record, H = the A given, A = the low byte of IX, the flags as given.

A strip record (6 bytes): +0 the layer page, bit 7 set to mark the cells (flags `$6700` bit 0, property `$6C00`); +1 the tile alone or after a wall; +2 the first tile; +3 and +4 the middle tiles, alternated; +5 the last tile.

Callers: StripFromRecord `$A0CD`, StripOnLayer `$A0D8`, RoomOpStrip68 `$A0E2`. 123 runs.

Witness: L1 3486 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 123 calls (`stage1/rec/rooms` 97, `stage1/rec/deaths` 26) |
| Called from | `StripFromRecord`, `StripOnLayer`, `RoomOpStrip68` |
| Calls | `Multiply8`, `DrawStrip` (falls into), `OpHighNibble` |

### `DrawStrip` (`$A109`)

**Draw a run of tiles: first, alternating middles, last; skip the cells where a wall stands**

In: IX = the strip record, H = the layer page, carry = across, BC at the opcode byte. StripStep `$6BDF` = 1 (across) or 20 (down). ReadRunLen16 `$A3D1`: E = the low nibble of (BC) (16 when 0), L = the next byte, the first cell.

One cell: the record's +1 tile (`$A15B`). Else +2 at the first cell, then for every next cell the middle tile, +3 and +4 by turns (the `LD D,(IX+n)` displacement at `$A125`, flipped by XOR 7); a cell whose wall layer `$6800` holds 1-`$1A` is left alone and the cell after it gets +1; the last cell gets +5. Across, every tile is written by PutStripTileMark `$A416` (marked when the record's bit 7 is set); down, only the first.

Ends at RoomOpNext `$A1EE`. 123 runs (deaths, rooms); the alternation `$A138` 179.

Witness: L1 3486 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 123 calls (`stage1/rec/rooms` 97, `stage1/rec/deaths` 26) |
| Called from | `StripOnLayer` (tail), `RoomOpStrip68` (tail), `StripRecordAddress` (falls into) |
| Calls | `RoomOpNext` (tail), `ReadRunLen16`, `PutStripTile`, `PutStripTileMark` |
| Reads | `$6816`-`$68D8` (`TitleColours+284`); `$6BDF` (`StripStep`); `$7438`-`$74AC` (`StructureSetB+2`, `StructureSetC`); `$7512`-`$7558` (`StructureSetD+1`); `$7578`-`$757C` (`StructureSetE+7`); `$75AF`-`$75C4` (`StructureSetF+2`); 1 more ranges |
| Writes | `$6BDF` (`StripStep`); `$A125` (`DrawStripMiddle+2`) |

### `SubOpRun77` (`$A164`)

**Room sub-opcode 0: a run of `$77` across the `$6B00` layer (`$76` over a `$75`)**

Sub-opcode 0 of opcode 11 (table `$75EF` entry 0). ReadRunLen16 `$A3D1`: E cells from cell L; each cell of `$6B00` gets `$77`, or `$76` where it holds `$75`. Unmarked. Then RoomOpNext `$A1EE`.

The mechanical cut took these bytes for data: no keyed recording ran them, the table `$75EF` points here. Not run in the keyed recordings; known only from the code.

Witness: L1 21 (bossgate, poke-room x1, rzx x8).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SubOpPillar` (`$A179`)

**Room sub-opcode 2: a pillar two cells wide, `$2D` / `$2E` on the `$6800` layer**

ReadRun `$A3D5` (E rows, L the top-left cell). The top row is written and marked (PutTileMark `$A407`), each row below written plain: `$2D` left, `$2E` right. The background fill (`$A2BF`) turns a shaded `$2E` into `$2F`. 3 runs (deaths, rooms).

Witness: L1 65 (deaths, play48, rooms, poke-room x5, rzx x9, rzxroom x4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `RoomOpNext` (tail), `ReadRun`, `PutTileMark` |

### `SubOpColumn31` (`$A197`)

**Room sub-opcode 3: a column two cells wide, `$31` / `$32` on the `$6B00` layer, property `$10`**

CellProperty `$6BE3` = `$10` for the run; ReadRun `$A3D5`; the top row marked and given the property (PutTileMarkProp `$A3F3`), the rows below the property only (PutTileProp `$A402`); then `$6BE3` = 0 and RoomOpNext `$A1EE`. 3 runs (rooms).

Witness: L1 50 (rooms, poke-room x6, rzx x8, rzxroom x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `RoomOpNext` (tail), `ReadRun`, `PutTileMarkProp`, `PutTileProp` |
| Writes | `$6BE3` (`CellProperty`) |

### `SubOpColumnTop30` (`$A1C5`)

**Room sub-opcode 4: the same column topped by `$30`, set one cell to the left**

CellProperty `$6BE3` = `$10`; `$30` at the first cell, `$31` one row down and one cell right, then SubOpColumnLoop `$A1B0` writes `$31` / `$32` pairs from the cell below the `$30` (the `$31` is overwritten by the `$32`, its mark stays). The deaths room shows `$30` at cell 26 and `$31` `$32` at 46, 47 with property `$10`. 1 run (deaths).

Witness: L1 11 (deaths, play48, rzx x4, rzxroom x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`) |
| Called from | `JumpViaTable` |
| Calls | `ReadRun`, `PutTileMarkProp` |
| Writes | `$6BE3` (`CellProperty`) |

### `SubOpMarkCell` (`$A1E2`)

**Room sub-opcode 1: set the cell flag `$6700` to 1**

D = 1, joins SubOpClearMark at `$A1E8`: the next byte is a cell, its flag byte in `$6700` is set to D. Not run in the keyed recordings (the mechanical cut took the bytes for data; table `$75EF` entry 1 points here).

Witness: L1 7 (rzx x2, rzxroom x2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SubOpClearMark` (`$A1E6`)

**Room sub-opcode 5: clear a cell's flag byte `$6700`**

D = 0; the cell is the next byte; `$6700` + cell = D. Falls into RoomOpNext. 8 runs (deaths, rooms).

Witness: L1 29 (deaths, play48, rooms, rzx x2, rzxroom x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `RoomOpNext` (falls into) |
| Reads | `$A957`-`$A959` (`Room1+47`); `$AA2B`-`$AA2F` (`Room8+20`) |
| Writes | `$677A`-`$6783` (`TitleColours+128`) |

### `RoomOpNext` (`$A1EE`)

**Back to the room opcode loop (`$9FEE`: the next byte, the opcode's count)**

`JP $9FEE`. The common exit of the strip and sub-opcode handlers. 138 runs.

Witness: L1 3669 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 138 calls (`stage1/rec/rooms` 103, `stage1/rec/deaths` 35) |
| Called from | `DrawStrip` (tail), `SubOpPillar` (tail), `SubOpColumn31` (tail), `SubOpClearMark` (falls into) |
| Calls | `NextObject` (tail) |

### `RoomOpFillBack` (`$A1F1`)

**Room opcode 13: fill the back wall from one or two start cells**

The opcode byte: bits 0-3 = 13, bit 4 one more start cell, bits 5-7 the back-wall set. `$6BE0` = the set (0-7); `$6AE9` (the opcode count less the one the loop took) start cells follow, each handed to FillBackFrom `$A20D`; then `JP $9FD6`, the next opcode.

9 runs (deaths, rooms).

Witness: L1 326 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`, `stage1/rec/deaths`) |
| Called from | `JumpViaTable` |
| Calls | `NextObjectGroup` (tail), `FillBackFrom` |
| Reads | `$6AE9` (`ZoneRecords+8`); `$A95A` (`Room1+50`); `$A99C` (`Room2+31`); `$AA39` (`Room8+34`); `$AA74` (`Room9+47`); `$AB26` (`Room11+61`); 3 more ranges |
| Writes | `$6BE0` (`BackWallSet`) |

### `FillBackFrom` (`$A20D`)

**Fill the back wall down and right of a start cell**

In: BC at the start cell. `$6BE1` = the row's start cell. From the cell left of it the routine walks left to the wall that bounds the area (a wall tile 1-`$1E` on `$6800`, the first column, or a `$FF` stop mark, which it clears), then fills that row rightwards with FillBackRow `$A265` and goes one row down (`$6BE1` + 20) while the start cell of the row is not a wall, up to cell 219.

A `$FF` met at the start of a row ends the fill: `$A22C` clears the `$FF` marks of that row up to `$6BE2` (set by FillBackRow when it met one).

Callers: RoomOpFillBack `$A1F1`. 12 runs.

Witness: L1 446 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 calls (`stage1/rec/rooms` 10, `stage1/rec/deaths` 2) |
| Called from | `RoomOpFillBack` |
| Calls | `FillBackRow`, `ShadeFirstColumn`, `IsSolid`, `IsRowStart` |
| Reads | `$6806`-`$68D8` (`TitleColours+268`); `$6BE1` (`FillRowStart`); `$A95B` (`Room1+51`); `$A99D` (`Room2+32`); `$AA3A` (`Room8+35`); `$AA75` (`Room9+48`); 4 more ranges |
| Writes | `$6BE1` (`FillRowStart`) |

### `FillBackRow` (`$A265`)

**Fill one row of the back wall rightwards from cell L**

Per cell of `$6800`: a wall (1-`$18`) ends the row; `$FF` is cleared and ends it (`$6BE2` = the cell below + 20, for FillBackFrom); an empty cell or a back tile (`$19` and up) is tested with IsSolid `$A32F` against the front layers:

- not solid (`$A27D`): ShadeCell `$A2B5`: the shading of the left, upper and upper-left neighbours; an empty cell gets the set's back tile `$1A` + `$6BE0` and the shading property;

- solid (a ladder, column or ledge stands here, `$A28D`): when the cell above holds a ledge (`$50-$52` on `$6B00`), the ladder or column tile here (`$57` on `$6B00`, `$80` on `$6900`, `$55` on `$6A00`, the pairs at `$72D8`) is turned into its top tile (one less).

The row ends at the last column (IsRowStart `$A3EA` on the next cell). 579 runs.

Witness: L1 18464 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 67 calls (`stage1/rec/rooms` 52, `stage1/rec/deaths` 15) |
| Called from | `FillBackFrom` |
| Calls | `ShadeCell`, `IsAboveInList`, `IsSolid`, `IsRowStart` |
| Reads | `$6807`-`$68DA` (`TitleColours+269`); `$690B`-`$69D6` (`EnemySlots+47`); `$6A0B`-`$6AB1` (`FireHeld+40`, `ControlMenu`, `ControlMenuKey`); `$6AD6` (`ControlMenuText+11`); `$6B0B`-`$6BB1` (`ControlRecords+1`, `ControlGap`, `PageTailTemplate`, `ItemRecords`); `$6BD6` (`ItemRecords+42`); 1 more ranges |
| Writes | `$695A` (`EnemySlots+126`); `$6988` (`EnemySlots+172`); `$69AA` (`EnemySlots+206`); `$6A60` (`FireHeld+125`); `$6A90` (`ControlMenuWait+8`); `$6AAB` (`ControlMenuPatch+18`) |

### `ShadeFirstColumn` (`$A2AB`)

**Shading of a cell in the first column: only the cell above counts**

B = 33, DE = `$7292` (the solid list with `$2E` on `$6800`); C = 3 when the cell above is solid (IsAboveInList `$A320`), else 0; joins ShadeCellApply `$A2B8`. 4 runs (rooms).

Witness: L1 468 (rooms, poke-room x7, rzx x47, rzxroom x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/rooms` 4) |
| Called from | `FillBackFrom` |
| Calls | `ShadeCellApply` (tail), `IsAboveInList` |

### `ShadeCell` (`$A2B5`)

**Shade a back cell from its neighbours, give an empty cell the back tile**

NeighbourShade `$A300` sets C (bit 2 left, bit 1 above, bit 0 above-left solid). Falls into ShadeCellApply `$A2B8`: an empty cell gets SetShadeProperty `$A2CD` and the back tile `$1A` + set (`$A2F6`); a back tile already there is shaded only when C is not 0, and a pillar's right half `$2E` with C 4 or 5 becomes `$2F`. 369 runs.

Witness: L1 14525 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 369 calls (`stage1/rec/rooms` 300, `stage1/rec/deaths` 69) |
| Called from | `FillBackRow` |
| Calls | `NeighbourShade` |
| Reads | `$6809`-`$683A` (`TitleColours+271`); `$6859`-`$68D3` (`TitleColours+351`); `$6BE0` (`BackWallSet`) |
| Writes | `$6809`-`$683A` (`TitleColours+271`); `$6859`-`$68D3` (`TitleColours+351`) |

### `ShadeCellApply` (`$A2B8`)

**ShadeCellApply**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rec/rooms` 4) |
| Called from | `ShadeFirstColumn` (tail) |
| Calls | `SetShadeProperty` (tail) |
| Reads | `$6807`-`$68C7` (`TitleColours+269`); `$6BE0` (`BackWallSet`) |
| Writes | `$6807`-`$68C7` (`TitleColours+269`) |

### `SetShadeProperty` (`$A2CD`)

**Write the shading shape C into the cell property, the corner overlay into `$6900`**

C = 4 (left only): `$65` into `$6900` when the cell is empty there; C = 2 (above only): `$66`; C 5-7 become 4-6; the low nibble of `$6C00` + L = the result (high nibble kept). Out: H = `$68`. 360 runs.

Witness: L1 14016 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 360 calls (`stage1/rec/rooms` 292, `stage1/rec/deaths` 68) |
| Called from | `ShadeCellApply` (tail), `PutOverlayIfEmpty` |
| Calls | `PutOverlayIfEmpty` |
| Reads | `$6C07`-`$6CD3` (`CellProperty+36`, `WalkLists`, `WeaponRecords`, `TouchZoneRecords` and 1 more) |
| Writes | `$6C07`-`$6CD3` (`CellProperty+36`, `WalkLists`, `WeaponRecords`, `TouchZoneRecords` and 1 more) |

### `PutOverlayIfEmpty` (`$A2EC`)

**Write B into layer H+1 at cell L when that cell is empty**

Callers: SetShadeProperty `$A2CD`. 25 runs, 22 writes.

Witness: L1 603 (bossgate, deaths, play48, rooms, poke-room x13, rzx x54, rzxroom x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 25 calls (`stage1/rec/rooms` 20, `stage1/rec/deaths` 5) |
| Called from | `SetShadeProperty` |
| Calls | `SetShadeProperty` |
| Reads | `$690F`-`$694D` (`EnemySlots+51`); `$6966`-`$6985` (`EnemySlots+138`); `$6996`-`$69C0` (`EnemySlots+186`) |
| Writes | `$690F`-`$6947` (`EnemySlots+51`); `$6966`-`$6969` (`EnemySlots+138`); `$697B`-`$6985` (`EnemySlots+159`); `$6996`-`$69A4` (`EnemySlots+186`); `$69BA`-`$69C0` (`EnemySlots+222`) |

### `NeighbourShade` (`$A300`)

**C = the solid bits of the left, upper and upper-left neighbours**

B = 33, DE = `$7292`, C = 0; TestCellSolid `$A334` on L-1, L-20, L-21, each shifting its result into C. C = 7 becomes 6. Out: C, H = `$68`. 369 runs.

Witness: L1 14525 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 369 calls (`stage1/rec/rooms` 300, `stage1/rec/deaths` 69) |
| Called from | `ShadeCell` |
| Calls | `TestCellSolid` |

### `IsAboveInList` (`$A320`)

**Is the cell above L in the B-entry tile list at DE?**

Carry and C = 3 when it is, else C = 0. Callers: FillBackRow `$A28D` (3 ledge pairs at `$72B4`), ShadeFirstColumn `$A2AB`. 153 runs.

Witness: L1 3158 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 153 calls (`stage1/rec/rooms` 109, `stage1/rec/deaths` 44) |
| Called from | `FillBackRow`, `ShadeFirstColumn` |
| Calls | `TestCellSolid` |

### `IsSolid` (`$A32F`)

**Is cell L solid: a wall, or a front tile from the list at `$7294`?**

B = 34, DE = `$7294` (the list less its first pair, `$2E` on `$6800`). Falls into TestCellSolid. 530 runs.

Witness: L1 17949 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 530 calls (`stage1/rec/rooms` 417, `stage1/rec/deaths` 113) |
| Called from | `FillBackFrom`, `FillBackRow`, `RoomOpLedge` |
| Calls | `TestCellSolid` (falls into) |

### `TestCellSolid` (`$A334`)

**Carry when cell L is a wall (1-`$19` on `$6800`) or holds a (page, tile) pair of the list at DE**

In: L = the cell, DE = the list of (page, tile) pairs, B = its length. A wall code 1-`$19` on `$6800` is solid at once; otherwise each pair is tried. Out: carry = solid, and the result shifted into C (`RL C`); HL, DE, B kept.

The list `$7292` (38 pairs): `$2E` on `$6800`; `$7F` `$80` `$40` `$42` `$3F` `$41` `$4C` `$4F` on `$6900`; `$54` `$55` `$40` `$42` `$3F` `$41` `$4C` `$4F` on `$6A00`; `$50-$52` `$32` `$30` `$27-$2C` `$57` `$56` `$81-$83` `$31` on `$6B00`; then `$2D` on `$6800` and the three top-tile pairs at `$72D8`. 1790 runs; the pair loop 39917.

Witness: L1 64682 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,790 calls (`stage1/rec/rooms` 1,426, `stage1/rec/deaths` 364) |
| Called from | `NeighbourShade`, `IsAboveInList`, `IsSolid` (falls into) |
| Reads | `$6801`-`$69D9` (`TitleColours+263`, `EnemySlots`); `$69F2`-`$6AD9` (`FireHeld+15`, `ControlMenu`, `ControlMenuKey`, `ControlMenuText`); `$6AF2`-`$6BD9` (`ZoneRecords+17`, `ControlRecords`, `ControlGap`, `PageTailTemplate` and 1 more); `$6BF2`-`$6BFD` (`CellProperty+15`); `$7292`-`$72D7` (`SolidTiles`, `LedgeTiles`) |

### `RoomOpLedge` (`$A357`)

**Room opcode 14: a ledge across the `$6B00` layer and its shadow**

ReadRunLen16 `$A3D1` (E cells, L the first). The previous byte's high nibble picks the tiles: `$20` gives IX = `$73BD` (`$70`, `$71` at a crossing of `$57` / `$56`), else `$73C1` (`$72`, `$73` at a crossing of `$75` / `$74`). Every cell gets its tile and the mark (PutTileMark `$A407`); the shading nibble of `$6C00` becomes 6 (7 after the first cell, 7 also at a first cell in the first column when its nibble was 0, kept 6 when it was 2).

The cell after the ledge, when it is in the same row and not solid, gets the shading 8 or 5 ORed in and the corner `$65` on `$6900`: the ledge's shadow. Then RoomOpNext. 7 runs (rooms).

Witness: L1 256 (bossgate, rooms, poke-room x11, rzx x38, rzxroom x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`) |
| Called from | `JumpViaTable` |
| Calls | `NextObject` (tail), `IsSolid`, `ReadRunLen16`, `IsRowStart`, `PutTileMark` |
| Reads | `$6B43`-`$6B48` (`ControlRecords+57`); `$6B6B`-`$6B6D` (`PageTailTemplate+15`); `$6B83`-`$6BA2` (`PageTailTemplate+39`); `$6BB6` (`ItemRecords+10`); `$6C43`-`$6C49` (`WalkLists+13`); `$6C6B`-`$6C6E` (`PageTail5F+19`); 6 more ranges |
| Writes | `$6949` (`EnemySlots+109`); `$696E` (`EnemySlots+146`); `$698F`-`$69A3` (`EnemySlots+179`); `$69B7` (`EnemySlots+219`); `$6C43`-`$6C49` (`WalkLists+13`); `$6C6B`-`$6C6E` (`PageTail5F+19`); 2 more ranges |

### `RoomDataAddress` (`$A3C9`)

**BC = the address of room A's data (the word table at `$7100`)**

BC = the word at `$7100` + 2A. Callers: `$9F34` (the room and the room above). 25 runs.

Witness: L1 279 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 129 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/rooms` 8, `stage1/rec/deaths` 7, `stage1/rec/menu` 2 and 4 more) |
| Called from | `BuildRoomPlanes` |
| Reads | `$7100`-`$7125` (`ClearRoomCellsLoop+15`, `RoomDataPointers`) |

### `ReadRunLen16` (`$A3D1`)

**E = the run length (low nibble of (BC), 16 when 0), L = the next byte (the first cell)**

Callers: DrawStrip `$A109`, RoomOpLedge `$A357`, SubOpRun77 `$A164`. Falls into ReadRunCommon. Out: BC at the cell byte.

Witness: L1 3763 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 130 calls (`stage1/rec/rooms` 104, `stage1/rec/deaths` 26) |
| Called from | `DrawStrip`, `RoomOpLedge` |
| Calls | `ReadRunCommon` (tail) |

### `ReadRun` (`$A3D5`)

**E = the low nibble of (BC) (0 kept when 0), L = the next byte**

Callers: SubOpPillar, SubOpColumn31, SubOpColumnTop30, SetupRoomObjects. 30 runs.

Witness: L1 332 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 178 t-states own (0.00 %) |
| Runs (the other recordings) | 27 calls (`stage1/rec/rooms` 11, `stage1/rec/deaths` 9, `stage1/rec/gameover` 2 and 4 more) |
| Called from | `SubOpPillar`, `SubOpColumn31`, `SubOpColumnTop30`, `SetupRoomObjects` |
| Calls | `ReadRunCommon` (falls into) |
| Reads | `$A9D5`-`$A9E2` (`Room4+15`, `Room5`) |

### `ReadRunCommon` (`$A3D7`)

**The shared body of ReadRun and ReadRunLen16**

Witness: L1 4095 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 150 calls (`stage1/rec/rooms` 115, `stage1/rec/deaths` 35) |
| Called from | `ReadRunLen16` (tail), `ReadRun` (falls into) |
| Reads | `$A933`-`$A947` (`Room1+11`); `$A95D`-`$A96B` (`Room1+53`); `$A986`-`$AA28` (`Room2+9`, `Room3`, `Room4`, `Room5` and 3 more); `$AA42`-`$AA43` (`Room8+43`); `$AA5C`-`$AA81` (`Room9+23`); `$AAFD`-`$AB37` (`Room11+20`); 4 more ranges |

### `OpHighNibble` (`$A3E1`)

**E = A = the high nibble of (BC)**

Callers: `$9F63`, `$9FD6`, StripRecordAddress `$A0EE`, SetupRoomObjects `$A41E`. 333 runs.

Witness: L1 7132 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 12 calls, 560 t-states own (0.00 %) |
| Runs (the other recordings) | 321 calls (`stage1/rec/rooms` 216, `stage1/rec/deaths` 77, `stage1/rec/menu` 8 and 4 more) |
| Called from | `DecodeRoom`, `NextObjectGroup`, `StripRecordAddress`, `SetupRoomObjects` |
| Reads | `$A929`-`$A96A` (`Room1+1`); `$A97E`-`$AA80` (`Room2+1`, `Room3`, `Room4`, `Room5` and 4 more); `$AAEA`-`$AB36` (`Room11+1`); `$ABEE`-`$AC48` (`Room14+1`); `$AD85`-`$ADCB` (`Room18+1`); `$C9F1`-`$CA47` (`Room103+70`, `Room104`) |

### `IsRowStart` (`$A3EA`)

**Z when cell L starts a row (20, 40, ... 240)**

Subtracts 20 up to 12 times. Cell 0 is not found (NZ). B is lost. 656 runs.

Witness: L1 23797 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 656 calls (`stage1/rec/rooms` 514, `stage1/rec/deaths` 142) |
| Called from | `FillBackFrom`, `FillBackRow`, `RoomOpLedge` |

### `PutTileMarkProp` (`$A3F3`)

**Write D at (HL), set the cell's flag `$6700` to 1 and its property to CellProperty**

Witness: L1 122 (deaths, play48, rooms, poke-room x6, rzx x10, rzxroom x3).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/rec/rooms` 6, `stage1/rec/deaths` 2) |
| Called from | `SubOpColumn31`, `SubOpColumnTop30` |
| Calls | `PutTileMarkPropA` (falls into) |

### `PutTileMarkPropA` (`$A3F4`)

**The same with the tile in A**

Caller: `$A039` (opcode 4, the outdoor rows). 388 runs.

Witness: L1 942 (deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x6, rzx x11, rzxroom x8).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 60 calls, 5,579 t-states own (0.00 %) |
| Runs (the other recordings) | 328 calls (`stage1/rec/deaths` 122, `stage1/rec/rooms` 66, `stage1/rec/menu` 40 and 4 more) |
| Called from | `BuildSurface`, `PutTileMarkProp` (falls into) |
| Calls | `MarkCellProp` (falls into) |
| Reads | `$6BE3` (`CellProperty`) |
| Writes | `$6778`-`$678B` (`TitleColours+126`); `$6B1A` (`ControlRecords+16`); `$6B2F` (`ControlRecords+37`); `$6B78`-`$6B8B` (`PageTailTemplate+28`); `$6BAB`-`$6BBD` (`PageTailTemplate+79`, `ItemRecords`); `$6C78`-`$6C8B` (`PageTail5F+32`, `TouchZoneRecords`) |

### `MarkCellProp` (`$A3F5`)

**`$6700` + L = 1, `$6C00` + L = CellProperty `$6BE3`**

Witness: L1 7172 (deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x11, rzx x47, rzxroom x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 357 calls (`stage1/rec/deaths` 182, `stage1/rec/rooms` 175) |
| Called from | `PutTileMarkPropA` (falls into), `PutStripTileMark` (tail) |
| Calls | `SetCellProp` (falls into) |
| Reads | `$6BE3` (`CellProperty`) |
| Writes | `$671A`-`$6732` (`TitleColours+32`); `$6745`-`$6798` (`TitleColours+75`); `$67AB`-`$67DB` (`TitleColours+177`); `$6C1B`-`$6C32` (`CellProperty+56`); `$6C50`-`$6C98` (`WalkLists+26`, `WeaponRecords`, `TouchZoneRecords`, `SetTuneCode`); `$6CAB`-`$6CDB` (`SetTuneCode+21`, `PageTail60`) |

### `SetCellProp` (`$A3FA`)

**`$6C00` + L = CellProperty `$6BE3` (HL on the stack)**

Witness: L1 7210 (deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x11, rzx x47, rzxroom x17).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 184 calls (`stage1/rec/deaths` 184) |
| Called from | `MarkCellProp` (falls into), `PutTileProp` (tail) |
| Reads | `$6BE3` (`CellProperty`) |
| Writes | `$6C1A` (`CellProperty+55`); `$6C2E`-`$6C2F` (`CellProperty+75`); `$6C45`-`$6C97` (`WalkLists+15`, `WeaponRecords`, `TouchZoneRecords`, `SetTuneCode`); `$6CD4`-`$6CD6` (`SetTuneCode+62`, `PageTail60`) |

### `PutTileProp` (`$A402`)

**Write D at (HL) and the cell property, no mark**

Witness: L1 38 (deaths, play48, rzx x5, rzxroom x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/deaths` 2) |
| Called from | `SubOpColumn31` |
| Calls | `SetCellProp` (tail) |
| Writes | `$6B2E`-`$6B2F` (`ControlRecords+36`) |

### `PutTileMark` (`$A407`)

**Write D at (HL) and set the cell flag `$6700` to 1**

Witness: L1 1283 (bossgate, deaths, play48, rooms, poke-room x11, rzx x41, rzxroom x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 28 calls (`stage1/rec/rooms` 24, `stage1/rec/deaths` 4) |
| Called from | `SubOpPillar`, `RoomOpLedge` |
| Calls | `PutTileMarkA` (falls into) |

### `PutTileMarkA` (`$A408`)

**The same with the tile in A**

Caller: `$9F63` (the room data's tile blocks). 847 runs.

Witness: L1 11476 (bossgate, deaths, play48, rooms, poke-room x15, rzx x54, rzxroom x14).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 847 calls (`stage1/rec/rooms` 770, `stage1/rec/deaths` 77) |
| Called from | `DecodeRoom`, `PutTileMark` (falls into) |
| Writes | `$6700`-`$68FF` (`TitleColours+6`, `EnemySlots`); `$6B43`-`$6B48` (`ControlRecords+57`); `$6B6B`-`$6B6D` (`PageTailTemplate+15`); `$6B83`-`$6BA2` (`PageTailTemplate+39`); `$6BB6` (`ItemRecords+10`) |

### `PutStripTile` (`$A410`)

**A middle or last strip tile: plain down, marked across**

Writes D; when StripStep `$6BDF` is even (down) that is all; across it goes on as PutStripTileMark.

Witness: L1 9126 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 294 calls (`stage1/rec/rooms` 210, `stage1/rec/deaths` 84) |
| Called from | `DrawStrip` |
| Calls | `PutStripTileMark` (falls into) |
| Reads | `$6BDF` (`StripStep`) |
| Writes | `$681E`-`$6880` (`TitleColours+292`); `$68AB`-`$68DB` (`TitleColours+433`); `$691E`-`$69D8` (`EnemySlots+66`); `$6A1F`-`$6AD7` (`FireHeld+60`, `ControlMenu`, `ControlMenuKey`, `ControlMenuText`); `$6B34`-`$6BD9` (`ControlRecords+42`, `ControlGap`, `PageTailTemplate`, `ItemRecords`) |

### `PutStripTileMark` (`$A416`)

**Write D, and mark the cell when the strip record's +0 has bit 7**

Witness: L1 8757 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 273 calls (`stage1/rec/rooms` 205, `stage1/rec/deaths` 68) |
| Called from | `DrawStrip`, `PutStripTile` (falls into) |
| Calls | `MarkCellProp` (tail) |
| Reads | `$7436`-`$745A` (`StructureSetB`); `$746C`-`$7490` (`StructureSetB+54`); `$74A2`-`$74A8` (`StructureSetC+12`); `$7511`-`$7553` (`StructureSetD`); `$7577` (`StructureSetE+6`); `$75AD`-`$75BF` (`StructureSetF`) |
| Writes | `$6815`-`$6883` (`TitleColours+283`); `$68AF`-`$68DB` (`TitleColours+437`); `$690A`-`$6999` (`EnemySlots+46`); `$6A0B`-`$6A6F` (`FireHeld+40`); `$6AA4`-`$6AAF` (`ControlMenuPatch+11`); `$6B20` (`ControlRecords+22`); 1 more ranges |

### `SetupRoomObjects` (`$A41E`)

**Read the room's zones, items and enemies; draw the items; restore the room's state**

Called from `$95C3` (the room lookup) with BC after the room's build data. BC is pushed and popped round the surface (BuildSurface); the variants do not read it. 23 runs (c1, deaths, gameover, menu, opt2-4, rooms).

1. The zones: up to 6 records, their addresses in `$6AE1` (count `$6AE0`). A record: a header (bits 4-6 n rectangles, bit 3 the last record, bits 0-2 m single cells), n pairs (first cell, last cell), m cells. A room without zones (first byte 0) gets the one record `$75FB`.

2. A count byte: low nibble the items, high nibble the enemies (`$6ADC`, `$6ADD`); the 2-byte records of both are copied to RoomObjectList `$5B01`, `$6ADE` = the start of the enemies.

3. Clears `$9A59`, byte +2 (active) of the actor pages `$5E00-$6600` (all but Hiro) and the enemy slots `$68DC-$68EB`; `$8F75`; BuildZones `$A4D1` (which also restores the room's state and reveals Hiro's zone).

4. The items: item i is skipped when bit i (from bit 7) of `$6DFE` (the room's taken items) is set; else its kind (bits 5-7 of the first byte) picks a (tile, page) pair at `$7BD8` (`$19`/`$1A`/`$8C` on `$6900`, `$8C`/`$8D`/`$19` on `$6A00`) and the tile goes into its cell (second byte); the cell flag gets bit 1 unless the tile is `$8C`.

Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 3,840 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/rooms` 7, `stage1/rec/deaths` 6, `stage1/rec/menu` 2 and 4 more) |
| Called from | `EnterRoom` |
| Calls | `ActorScreenBox`, `ReadRun`, `OpHighNibble`, `BuildZones` |
| Reads | `$5B01`-`$5B0E` (system); `$671C` (`TitleColours+34`); `$6730`-`$6738` (`TitleColours+54`); `$674B`-`$6772` (`TitleColours+81`); `$679B` (`TitleColours+161`); `$67AE`-`$67C7` (`TitleColours+180`); 13 more ranges |
| Writes | `$5B01`-`$5B18` (system); `$5E02`-`$5F02` (`IntroBox+7`, `IntroBoxRow`, `IntroBoxSide`, `IntroScript`); `$6002` (`HavokRoomEnter+46`); `$6102` (`SizeClasses+128`); `$6202` (`PrintGlyphsAddress+2`); `$6302` (`IntroAttrsC+191`); 18 more ranges |

### `BuildZones` (`$A4D1`)

**Write the zone bits into the cell flags; restore the room's state; reveal Hiro's zone**

Zone k (k = 0-5) gets the bit `$80` >> k. For each rectangle (first, last cell) the width and height are found by dividing (last - first) by 20 (`$A502`), and each cell whose flag is below 2 gets the bit; then each single cell of the record gets it over its zone bits (`AND 3` / `OR C`).

Then the room's two saved state bytes: `$6D00` + 2 (room - 1) to `$6DFE` (taken items) and `$6DFF` (revealed zones), `$6E00` + 2 (room - 1) to `$6EFE` / `$6EFF` (enemies gone); `JP RevealZone` `$A569`. 23 runs.

Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 39,721 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/rooms` 7, `stage1/rec/deaths` 6, `stage1/rec/menu` 2 and 4 more) |
| Called from | `SetupRoomObjects` |
| Calls | `RoomEnemyState`, `RoomItemState`, `RevealZone` (tail) |
| Reads | `$6700`-`$67DB` (`TitleColours+6`); `$6AE0`-`$6AE6` (`ZoneCount`, `ZoneRecords`); `$6D00`-`$6D23` (`HavokStashB`); `$6DFF`-`$6E23` (`RevealedZones`, `HavokStashA`); `$6EFF`-`$6F00` (`GoneEnemies+1`, `OutlineMask`); `$75FB`-`$75FD` (`EmptyObjectList`); 8 more ranges |
| Writes | `$6700`-`$67DB` (`TitleColours+6`); `$6DFE`-`$6DFF` (`TakenItems`, `RevealedZones`); `$6EFE`-`$6EFF` (`GoneEnemies`) |

### `RoomEnemyState` (`$A559`)

**HL = `$6E00` + 2 (room - 1), DE = `$6EFE`: the room's enemy bits**

Witness: L1 398 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 5 calls, 95 t-states own (0.00 %) |
| Runs (the other recordings) | 33 calls (`stage1/rec/rooms` 14, `stage1/rec/deaths` 11, `stage1/rec/gameover` 3 and 4 more) |
| Called from | `BuildZones`, `SaveRoomState` |
| Calls | `RoomStateAddress` (tail) |

### `RoomItemState` (`$A55D`)

**HL = `$6D00` + 2 (room - 1), DE = `$6DFE`: the room's item and zone bits**

Witness: L1 398 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 5 calls, 35 t-states own (0.00 %) |
| Runs (the other recordings) | 33 calls (`stage1/rec/rooms` 14, `stage1/rec/deaths` 11, `stage1/rec/gameover` 3 and 4 more) |
| Called from | `BuildZones`, `SaveRoomState` |
| Calls | `RoomStateAddress` (falls into) |

### `RoomStateAddress` (`$A55F`)

**L = 2 (room - 1), DE = H:`$FE`**

Witness: L1 796 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 10 calls, 471 t-states own (0.00 %) |
| Runs (the other recordings) | 66 calls (`stage1/rec/rooms` 28, `stage1/rec/deaths` 22, `stage1/rec/gameover` 6 and 4 more) |
| Called from | `RoomEnemyState` (tail), `RoomItemState` (falls into) |
| Reads | `$6BDD` (`Room`) |

### `RevealZone` (`$A569`)

**Add the zone under the actor's feet to the revealed zones; Z when it is new**

The operand of `LD HL,n` at `$A56D` holds two cells, written by `$8FCF` for the actor just placed: L when bit 7 of `$5D1B` is set, else H. The zone bits (`AND $FC`) of the flag byte one row below (`$6700` + cell + 20) are tested against RevealedZones `$6DFF`: already there gives NZ; a new zone is added and A = 0, Z.

Callers: `$955A` (every pass of play), BuildZones `$A4D1`. 2356 runs.

Witness: L1 42139 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 236 calls, 26,378 t-states own (0.00 %) |
| Runs (the other recordings) | 2,120 calls (`stage1/rec/deaths` 950, `stage1/rec/rooms` 576, `stage1/rec/gameover` 145 and 4 more) |
| Called from | `CheckRoomExit`, `BuildZones` (tail) |
| Reads | `$5D1B` (`BuildOutlineMaskLoop+7`); `$6714`-`$67D1` (`TitleColours+26`); `$6DFF` (`RevealedZones`) |
| Writes | `$6DFF` (`RevealedZones`) |

### `SaveRoomState` (`$A58A`)

**Copy `$6DFE-$6DFF` and `$6EFE-$6EFF` back to the room's entries in `$6D00` / `$6E00`**

Called from `$955A` when Hiro leaves a room. 15 runs (c1, deaths, gameover, rooms).

Witness: L1 192 (bossgate, deaths, gameover, hiscore, play48, rooms, c x1, poke-room x15, rzx x55, rzxroom x17).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 232 t-states own (0.00 %) |
| Runs (the other recordings) | 13 calls (`stage1/rec/rooms` 7, `stage1/rec/deaths` 5, `stage1/rec/gameover` 1) |
| Called from | `CheckRoomExit` |
| Calls | `RoomEnemyState`, `RoomItemState` |
| Reads | `$6DFE`-`$6DFF` (`TakenItems`, `RevealedZones`); `$6EFE`-`$6EFF` (`GoneEnemies`) |
| Writes | `$6D00`-`$6D23` (`HavokStashB`); `$6E00`-`$6E23` (`HavokStashA`) |

## text

`src/game/text.asm`

### `PrintScore` (`$8365`)

**Print the score string `$6657`, then the panel string `$6667`**

Callers: `$5C68`, `$9615` (the energy loss), `$97A3`, `$9801`, `$9E61`.

Witness: L1 262 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x1, opt x3, rzx x63, rzxroom x12).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 27 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/rec/deaths` 6, `stage1/rec/menu` 2, `stage1/rec/gameover` 1 and 3 more) |
| Called from | `MatchCheatName`, `LoseEnergy` (tail), `TouchHiro` (tail) |
| Calls | `PrintString` |

### `PrintPanelLine` (`$836B`)

**Print the panel string at `$6667` (the globals page)**

Caller: `$FF01` (each pass, when its value changed).

Witness: L1 455 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x1, opt x3, rzx x64, rzxroom x12).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 20 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/rec/deaths` 5, `stage1/rec/menu` 2, `stage1/rec/opt2` 1 and 3 more) |
| Called from | `PanelWeapon` |
| Calls | `PrintStringTall` (falls into) |
| Reads | `$6667` (`StatusLine`) |
| Writes | `$8411` (`PrintGlyphTop+10`) |

### `PrintStringTall` (`$836E`)

**Print the string at HL in the tall mode: one glyph row drawn twice**

The string's Y (HL+0) AND 7: 0 puts 0 into the operand at `$8411` (PrintGlyphTop repeats row 4 and row 7 is lost), else into `$841D` (the upper cell's last row is drawn again at the top of the lower cell: 9 rows). PrintString's end sets both back to `$FF`. Callers: the title `$6A7B` (the options), `$A6D9` (the high-score table), `$A861`.

Witness: L1 546 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x66, rzxroom x12).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 143 t-states own (0.00 %) |
| Runs (the other recordings) | 57 calls (`stage1/rec/menu` 36, `stage1/rec/gameover` 18, `stage1/rec/c48` 3) |
| Called from | `ControlMenu`, `PrintPanelLine` (falls into), `ShowHighScores` |
| Calls | `PrintString` (falls into) |
| Reads | `$6667` (`StatusLine`); `$6ACB` (`ControlMenuText`); `$8119` (`HiScoreTableHead`); `$81F0` (`CopyrightText`) |
| Writes | `$8411`-`$841D` (`PrintGlyphTop+10`, `PrintGlyphTopNext`) |

### `PrintString` (`$837B`)

**Print the string at HL: Y, X, two attributes, then glyph codes, `$FF` new line, 1-`$1F` skip, 0 end**

Header: B = Y in pixel lines, C = X in half characters (SRL C), the third byte to `$8436` (the attribute of the lower cell when the glyph straddles two), the fourth to `$83FB` (the attribute of the glyph's cell); `$FF` leaves the attributes. SetPrintPosition puts the screen address in DE and the next line's B + 8, C into the operand at `$83C6`. Codes: `$20` and up PrintGlyph from Font `$7BE5` + (code - `$20`) x 8; 1-`$1F` add to DE (skip columns); `$FF` new line; 0: the end, the attribute operands and the tall flags back to `$FF`. Returns HL past the end: the strings can be printed one after the other.

Callers: `$5DF1`, `$5DFB`, PrintScore, HavokFade, `$A6D9`, `$A861`, `$A8E2`, `$FF01`.

Witness: L1 2381 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x67, rzxroom x12).

[Animation: `PrintString` at work](img/routines/PrintString.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 14 calls, 162,851 t-states own (0.01 %) |
| Runs (the other recordings) | 1,410 calls (`stage1/rec/gameover` 1,048, `stage1/rec/menu` 261, `stage1/rec/c48` 32 and 4 more) |
| Called from | `IntroPrint`, `IntroBox`, `PrintScore`, `PrintStringTall` (falls into), `EffectEnvelope`, `ShowHighScores` |
| Calls | `SetPrintPosition`, `PrintGlyph` |
| Reads | `$5B01`-`$5B5E` (system); `$6657`-`$6679` (`ScoreLine`, `ScoreDigits`, `LivesDigits`, `StatusLine` and 1 more); `$6ACB`-`$6B09` (`ControlMenuText`, `ItemCount`, `EnemyCount`, `EnemyListPtr` and 2 more); `$80FB`-`$822B` (`HiScoreHeading`, `HiScoreRankText`, `HiScoreTableHead`, `HiScoreEntries` and 4 more) |
| Writes | `$83FB` (`PrintGlyph+2`); `$8411`-`$841D` (`PrintGlyphTop+10`, `PrintGlyphTopNext`); `$8436` (`PrintGlyphLowerLoop+7`) |

### `SetPrintPosition` (`$83CD`)

**DE = the screen address of pixel line B, column C / 2; the next line's B + 8, C kept at `$83C6`**

Caller: PrintString, `$61E5`, `$620D` (stage 2).

Witness: L1 4627 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x67, rzxroom x12).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 115 calls, 14,477 t-states own (0.00 %) |
| Runs (the other recordings) | 2,866 calls (`stage1/rec/gameover` 1,398, `stage1/rec/menu` 771, `stage1/rec/c48` 248 and 4 more) |
| Called from | `PrintGlyphs`, `PrintGlyphsLine`, `PrintString` |
| Calls | `ScreenAddress` (tail) |
| Writes | `$83C6`-`$83C7` (`PrintStringNewline+1`) |

### `CharCellAddress` (`$83E6`)

**DE = the screen address of character row B + 1, column C (D = 0: the top pixel line)**

Callers: CellScreenAddress `$8803`, SpriteScreenAddress `$8828`.

Witness: L1 179180 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,032 calls, 15,480 t-states own (0.00 %) |
| Runs (the other recordings) | 35,723 calls (`stage1/rec/rooms` 20,201, `stage1/rec/menu` 5,715, `stage1/rec/deaths` 4,444 and 5 more) |
| Called from | `CellScreenAddress`, `SpriteScreenAddress` |
| Calls | `ScreenAddress` (falls into) |

### `ScreenAddress` (`$83EA`)

**DE = the screen address of character row B, pixel line D, column C**

Witness: L1 183808 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,147 calls, 76,145 t-states own (0.01 %) |
| Runs (the other recordings) | 18,388 calls (`stage1/rec/menu` 6,486, `stage1/rec/gameover` 4,846, `stage1/rec/deaths` 4,566 and 4 more) |
| Called from | `SetPrintPosition` (tail), `CharCellAddress` (falls into) |

### `PrintGlyph` (`$83F9`)

**Draw the 8-byte glyph at HL at the screen address DE (any pixel line): DE + 1 on return**

The cell's attribute from the operand at `$83FB` (SetCellAttr). C = D AND 7: 8 - C rows into this cell, C rows into the cell below (DE + 32, a third crossed through the saved D); the lower cell's attribute from `$8436`. Tall mode: the operands at `$8411` / `$841D` (PrintStringTall). Callers: PrintString, `$6200`.

Witness: L1 34287 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x67, rzxroom x12).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,041 calls, 652,076 t-states own (0.05 %) |
| Runs (the other recordings) | 18,752 calls (`stage1/rec/menu` 6,416, `stage1/rec/gameover` 5,974, `stage1/rec/c48` 2,224 and 4 more) |
| Called from | `PrintGlyphsAddress`, `PrintString` |
| Calls | `SetCellAttr` |
| Reads | `$7BE5`-`$7CB4` (`Font`); `$7CED`-`$7DCB` (`Font+264`); `$7E0D`-`$7E1C` (`Font+552`); `$7F0D`-`$7F1B` (`MeterGlyphs`) |
| Writes | `$4000`-`$57F6` (screen) |

### `SetCellAttr` (`$843D`)

**Write A to the attribute of the screen address DE, unless A = `$FF`**

Witness: L1 44166 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x67, rzxroom x12).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,093 calls, 126,412 t-states own (0.01 %) |
| Runs (the other recordings) | 25,654 calls (`stage1/rec/menu` 10,800, `stage1/rec/gameover` 8,166, `stage1/rec/c48` 2,550 and 4 more) |
| Called from | `PrintGlyph` |
| Writes | `$5800`-`$5AFF` (screen) |

## mainloop

`src/game/mainloop.asm`

### `ShowGameOverWait` (`$831A`)

**Show message 4 (the game over) and wait up to 200 frames or for fire**

A = 4, CALL `$66C8` (the message actor in the globals page: message 4, run until it ends), then falls into WaitFireLong. Callers: the game over `$5C42` and the quit from the pause (`$668E`: fire while paused).

Witness: L1 10 (gameover, hiscore, menu, opt x3, rzx x4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/gameover` 1, `stage1/rec/menu` 1, `stage1/rec/opt2` 1 and 2 more) |
| Called from | `GameOver`, `IntroGlyphs` |
| Calls | `IntroGlyphs` |

### `WaitFireLong` (`$831F`)

**Wait 40 x 5 frames or until fire: Z = fire pressed**

H = `$28`, then WaitFireFrames. Callers: `$5D4F`, `$5DD8` (the title and intro), `$A73A` (the high-score table).

Witness: L1 122 (deaths, gameover, hiscore, menu, throw, c x2, opt x3, rzx x6).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 6 calls, 42 t-states own (0.00 %) |
| Runs (the other recordings) | 85 calls (`stage1/rec/menu` 28, `stage1/rec/gameover` 20, `stage1/rec/c48` 13 and 4 more) |
| Called from | `Intro48`, `IntroText` (tail), `ShowHighScores` |
| Calls | `WaitFireFrames` (falls into) |

### `WaitFireFrames` (`$8321`)

**Wait H x 5 frames (HALT) or until fire: Z = fire, NZ on time out**

Reads the input (ReadInput `$8529`, Z = fire), EI, 5 HALTs; returns Z at once on fire; H counts down; at 0 DEC H once more so the return is NZ. Callers: `$5D4F`, `$5DDE`, `$A6F5` (H = 1: 5 frames).

Witness: L1 6408 (deaths, gameover, havok, hiscore, menu, throw, c x2, opt x3, rzx x6, rzxroom x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 10 calls, 98,082,254 t-states own (7.43 %) |
| Runs (the other recordings) | 1,160 calls (`stage1/rec/menu` 677, `stage1/rec/gameover` 379, `stage1/rec/c48` 61 and 4 more) |
| Called from | `Intro48`, `IntroPictureWait` (tail), `WaitFireLong` (falls into), `ShowHighScores` |
| Calls | `ReadInput` |
| Reads | `$8328` (`WaitFireHalt+1`) |
| Writes | `$6642` (`Vitality`) |

### `PauseLong` (`$8330`)

**Busy-wait `$6000` loops (about 0.18 s)**

Witness: L1 144 (gameover, havok, hiscore, menu, opt x3, rzx x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage1/rec/menu` 3, `stage1/rec/gameover` 1, `stage1/rec/opt2` 1 and 2 more) |
| Called from | `GlyphBytesAsCode` (tail) |
| Calls | `DelayBC` (falls into) |

### `DelayBC` (`$8333`)

**Busy-wait BC loops of 26 T-states (BC = 0: 65 536)**

Callers: PauseLong, `$5D4F`, HavokFade `$8756`, `$66AB`.

Witness: L1 4580939 (deaths, gameover, havok, hiscore, menu, throw, c x2, opt x3, rzx x9).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 213,054 t-states own (0.02 %) |
| Runs (the other recordings) | 19 calls (`stage1/rec/menu` 7, `stage1/rec/gameover` 3, `stage1/rec/opt3` 2 and 4 more) |
| Called from | `Intro48`, `IntroGlyphs`, `PauseLong` (falls into) |

### `InterruptHandler` (`$8456`)

**The IM 2 handler: the game tick (when the flag at `$845F` is 0), the sound, every frame**

Entered through `$FDFD` (JP `$8456`) from the vector table `$FE00`. Saves HL, DE, BC, AF, IX, IY; LD A,n at `$845E`: the operand `$845F` is 0 in play (`$5CF4`) and 1 on the title, the high-score and the game-over screens (`$A747`, `$A842`), and only 0 runs GameTick; EffectPlayer `$853F` every frame (on a 128K the glue to bank 4); EI, RETI.

Witness: L1 222542 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

[Animation: `InterruptHandler` at work](img/routines/InterruptHandler.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2,614 calls, 524,397 t-states own (0.04 %) |
| Runs (the other recordings) | 49,277 calls (`stage1/rec/menu` 18,055, `stage1/rec/gameover` 9,844, `stage1/rec/deaths` 7,824 and 5 more) |
| Called from | `Im2Space` (tail) |
| Calls | `GameTick`, `EffectPlayer` |

### `GameTick` (`$8472`)

**The frame counter, the actor timers, the pause key, the input and the fire charge**

LD HL,n at `$8472`: n (`$8473`) is a 16-bit frame counter. For the ten pages `$5D00-$66FF` (H = `$5D-$66`, the nine actors and the message actor) whose +2 bit 0 is set: +`$1D` counted down to 0 every frame; unless paused (`$664C` bit 7) the word +`$1E` counted down and, at 0, +`$10` bit 5 set (and for page `$65` `$6651` cleared). P (port `$DFFE` bit 0) sets `$664C` = `$80` (the main loop calls the pause `$6682`).

The input: E = the last fire bit (`$6648`); A = ReadInput `$8529`, kept at `$850D` for ReadDirection; AND the fire mask (the operand at `$84CA`, 1, set by the options `$6A9B`); `$6648` = the fire bit (0 pressed). Fire held: if `$6652` bit 6 (the end text is up) set bit 7 (the main loop leaves for the end `$5C45`) and return; else the charge `$6645` += `$6644`, at most `$20`. Fire released this frame: C = the charge, the charge back to `$6647`; `$8E77` must return Z and the message actor (`$6602` bit 0) be off; then `$69E3` = C and the power `$6650` = 3 (charge `$19` or more), 2 (`$09-$18`) or 1.

Witness: L1 177113 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 975 calls, 758,991 t-states own (0.06 %) |
| Runs (the other recordings) | 16,354 calls (`stage1/rec/deaths` 6,185, `stage1/rec/rooms` 3,650, `stage1/rec/menu` 3,406 and 4 more) |
| Called from | `InterruptHandler` |
| Calls | `ReadInput`, `HiroBusy` |
| Reads | `$5D02`-`$5F02` (`Hiro+2`, `BuildPageTails`, `Intro48`, `IntroScene` and 10 more); `$5F1D`-`$5F1F` (`IntroScript+208`); `$6002` (`HavokRoomEnter+46`); `$601D`-`$601F` (`HavokRoomEnter+73`); `$6102` (`SizeClasses+128`); `$611D`-`$611F` (`SizeClasses+155`); 7 more ranges |
| Writes | `$5D1D` (`BuildOutlineMaskLoop+9`); `$5E1D` (`IntroBoxSides+3`); `$5F1D`-`$5F1F` (`IntroScript+208`); `$601D` (`HavokRoomEnter+73`); `$611D` (`SizeClasses+155`); `$6510`-`$651F` (`ActorPage9+16`); 5 more ranges |
| Ports in | `$DFFE` |

### `ReadDirection` (`$850C`)

**The direction of the input latched by GameTick: D, E = -1, 0 or +1, carry set when one is pressed**

LD A,n: n (`$850D`) is the raw input GameTick read this frame; falls into DecodeDirection. Caller: `$9333`.

Witness: L1 32293 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 260 calls, 1,820 t-states own (0.00 %) |
| Runs (the other recordings) | 3,677 calls (`stage1/rec/deaths` 1,458, `stage1/rec/menu` 926, `stage1/rec/rooms` 755 and 4 more) |
| Called from | `HiroControl` |
| Calls | `DecodeDirection` (falls into) |

### `DecodeDirection` (`$850E`)

**Decode the input byte A into D (right +1, left -1) and E (up -1, down +1); NC when no direction**

AND n / CP n (operands `$850F`, `$8511`, `$1E` for Sinclair 1): all released returns Z, NC. RRA drops the fire bit (the opcode at `$8513` is set per control: RRA here); then one RRA per direction and the four opcodes at `$851A`, `$851E`, `$8522`, `$8526` (DEC E, INC E, INC D, DEC D here) are written by the options `$6AA2-$6ABE`, so each joystick's bit order maps to the same moves. Returns SCF. Callers: ReadDirection, `$A861` (the name entry), the 128K glue `$85A3` (the title's toggle).

Witness: L1 680151 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 278 calls, 21,225 t-states own (0.00 %) |
| Runs (the other recordings) | 10,447 calls (`stage1/rec/menu` 5,725, `stage1/rec/gameover` 2,808, `stage1/rec/deaths` 1,476 and 3 more) |
| Called from | `ReadDirection` (falls into), `SweepSpanHalf` |

### `ReadInput` (`$8529`)

**Read the controls: A = the input bits (active low, bit 0 fire), Z = fire pressed (an 18-byte slot the options rewrite)**

As loaded: LD A,`$EF` / IN A,(`$FE`) / BIT 0,A, the 6-0 half row (Sinclair joystick 1: 0 fire, 9 up, 8 down, 7 right, 6 left). The options `$6AC2` copy 18 bytes from the 14-byte option records at `$6B0A` over `$8529-$853A` (option 3 Kempston: IN A,(`$1F`) and its fix-up, see opt3's L1 at `$8529`). Callers: WaitFireFrames, GameTick, `$A6EF`, `$A76F` (the 128K hooks call `$859E` there), `$A894`.

Witness: L1 833030 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,297 calls, 105,138 t-states own (0.01 %) |
| Runs (the other recordings) | 29,243 calls (`stage1/rec/menu` 10,136, `stage1/rec/deaths` 6,507, `stage1/rec/gameover` 4,778 and 5 more) |
| Called from | `IntroGlyphs`, `WaitFireFrames`, `GameTick`, `SweepSpanHalf`, `ShowHighScores`, `TitleSequence` |
| Ports in | `$001F`, `$101F`, `$B91F`, `$BA1F`, `$EFFE`, `$F7FE`, `$FF1F` |

### `MainLoop` (`$8DFE`)

**The main loop: the nine actors, the end, the pause, the per-pass jobs**

Entered by `JP $8DFE` at the start of play (`$5CF7`) and from `$5C68`; it never returns. Each pass: SP = `$5C00` (whatever a routine left on the stack is dropped); for the nine pages `$5D00`-`$6500` (B = 9, H stepped by `INC H`, L = 2 kept), ActorUpdate `$8E2B` when bit 0 of +`$02` (active) is set; then the end flag `$6652` bit 7 (set by the tick when fire is pressed after Havok's death, `$84D7`) jumps to the end `$5C45`; the pause flag `$664C` bit 7 (P, read by the tick) calls the pause `$6682`; `$79FF` not 0 calls `$66B6`; and the two jobs copied over the loader, `$FF01` and `$FF64`.

The tenth page `$6600` (Hiro's thrown weapon, kinds `$40-$46`) is not in this loop: RunActorSteps `$9A4B` runs it on every second call. Nothing waits for the frame: a pass costs about 2400-4000 T on average (518 T of the loop's own instructions; ActorUpdate 1566-1753 T a call, inclusive; `$FF01` and `$FF64` about 100 T each), so in light rooms the loop turns about 26 times a frame (c1: 25068 passes in the 975 frames of play). The room build runs inside an actor update (Hiro's move `$9B56` -> `$955A`) and stalls the loop 60-72 frames (WALKTHROUGH 1).

Counts: c1 25068 passes, 28339 actor updates (1.13 active actors a pass, Hiro alone in room 4); deaths 108018 passes, 225247 updates; rooms 78837 and 107204; menu 133076; opt2-4 about 15680 each.

Witness: L1 2036434 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 12,992,165 t-states own (0.98 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/menu` 2, `stage1/rec/deaths` 1, `stage1/rec/gameover` 1 and 3 more) |
| Called from | `MatchCheatName` (tail) |
| Reads | `$5D02`-`$5F02` (`Hiro+2`, `BuildPageTails`, `Intro48`, `IntroScene` and 10 more); `$6002` (`HavokRoomEnter+46`); `$6102` (`SizeClasses+128`); `$6202` (`PrintGlyphsAddress+2`); `$6302` (`IntroAttrsC+191`); `$6402` (`IntroGlyphs+239`); 3 more ranges |

### `MainLoopActors` (`$8E06`)

**The main loop continued: the actor scan, the end, the pause and the per-pass jobs**

The loop body of MainLoop `$8DFE` (an entry of its own: the `DJNZ` comes back here). H = the page, L = 2: +`$02` bit 0 (active) calls ActorUpdate `$8E2B`; after the ninth page the flags and the jobs, then `JR $8DFE`.

Witness: L1 18327840 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`) |
| Calls | `IntroGlyphs`, `ActorUpdate`, `PanelWeapon`, `PanelMeters` |
| Reads | `$5D02`-`$5F02` (`Hiro+2`, `BuildPageTails`, `Intro48`, `IntroScene` and 10 more); `$6002` (`HavokRoomEnter+46`); `$6102` (`SizeClasses+128`); `$6202` (`PrintGlyphsAddress+2`); `$6302` (`IntroAttrsC+191`); `$6402` (`IntroGlyphs+239`); 3 more ranges |
| Writes | `$69DF`-`$69E0` (`MapRow`, `MapColumn`) |

### `ActorUpdate` (`$8E2B`)

**One actor's update: one logic step (when its delay has run out) and the redraw of the actor that moved**

H = the actor page (L = 2), from MainLoop `$8E01` and from BossFire `$947D` (which runs page `$6000` to its end). HL and BC are kept.

1. RunActorSteps `$9A4B` sets IY to the page and runs at most one actor's logic: on every second call the weapon page `$6600` (or, with a boss in the room, the boss shot page `$6000`) first, then Hiro, then the pages with +`$02` bit 2, then this one, each only when its step delay +`$1D` is 0; the logic is a sequence step (+`$30`-`$38`) or the state handler at +`$03`/+`$04` (the `c` entries below). IY is then the actor that ran.

2. When that actor's +`$20` bit 0 (moved, redraw) is set: clear it, ActorBoxStore `$8F3B` (its screen box), and draw: kind `$25` (Havok) goes to `$872B` (his own draw and death count-down); a box wholly off the play window (ClipFlagsOff `$8E98` on the clip bits `$69DD`) or a Y of `$A8-$C7` (below the window) is not drawn; else the render's `$8907` with `$898C`, `$8A76` (every active actor, D = `$A0`, E = 1), `$8907` with `$8943`, `$8A73` (the actors with +`$02` bit 7, drawn over the rest) when any has it, and `$8C68`.

Only 1.4 % of the calls run logic (c1: 398 of 28339; deaths 4222 of 225247) and 1.1-1.3 % redraw (c1 308, deaths 2980): the step delays (+`$1A`, Hiro 3 frames) are counted by the IM 2 tick, so most passes find nothing to do.

Witness: L1 3898690 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

[Animation: `ActorUpdate` at work](img/routines/ActorUpdate.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 28,339 calls, 3,353,370 t-states own (0.25 %) |
| Runs (the other recordings) | 534,237 calls (`stage1/rec/deaths` 225,247, `stage1/rec/menu` 134,580, `stage1/rec/rooms` 107,204 and 4 more) |
| Called from | `IntroGlyphs`, `GlyphBytesAsCode`, `MainLoopActors` |
| Calls | `ComposeActorCells`, `DrawFrontActors`, `DrawActorsAll`, `BlitWindow`, `ClipFlagsOff`, `ActorBoxStore`, `RunActorSteps` |
| Reads | `$5D00` (`Hiro`); `$5D1C`-`$5D20` (`BuildOutlineMaskLoop+8`); `$5E00` (`IntroBox+5`); `$5E1C`-`$5E20` (`IntroBoxSides+2`); `$5F00` (`IntroScript+179`); `$5F1C`-`$5F20` (`IntroScript+207`); 9 more ranges |
| Writes | `$5D20` (`BuildOutlineMaskLoop+12`); `$5E20` (`IntroBoxSides+6`); `$5F20` (`IntroScript+211`); `$6020` (`HavokRoomEnter+76`); `$6120` (`SizeClasses+158`); `$6520` (`ActorPage9+32`); 2 more ranges |

### `HiroBusy` (`$8E77`)

**Is Hiro falling, hanging or in a sequence? NZ if so**

Called by the tick (`$84F1`) when fire is let go: the attack is taken (`$6650`, `$69E3`) only when this gives Z. NZ when Hiro's +`$02` has bit 1 (airborne) or bit 3 (hanging), or any of his sequence counters +`$30`-`$38` is not 0 (ActorInSequence `$8E89`).

Witness: L1 771 (bossgate, havok, menu, play48, throw, c x1, opt x3, poke-room x15, rzx x67, rzxroom x10).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 88 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/menu` 2, `stage1/rec/opt2` 2, `stage1/rec/opt3` 2 and 1 more) |
| Called from | `GameTick` |
| Calls | `ActorInSequence` (tail) |
| Reads | `$5D02` (`Hiro+2`) |

### `HiroBusyNoJump` (`$8E81`)

**Unreferenced: Hiro's sequences +`$31-$38` (all but the jump), NZ if any**

`LD H,$5D` / `LD L,$31` / `LD B,8` / `JR $8E8D` into ActorInSequence's loop. No code in the image calls or jumps here and no table holds the address (a search of the image for the word `$8E81`): a leftover variant of HiroBusy `$8E77`. Not run in the keyed recordings.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ActorInSequence` (`$8E89`)

**NZ when one of the actor's nine sequence counters +`$30-$38` is running**

H = the page. ORs +`$30`-`$38` and returns NZ at the first one that is not 0, else A = 0 and Z. Callers: HiroBusy `$8E77`, `$9BB6` (keeps the redraw bit while a sequence plays).

Witness: L1 163322 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 374 calls, 100,588 t-states own (0.01 %) |
| Runs (the other recordings) | 13,622 calls (`stage1/rec/menu` 5,277, `stage1/rec/deaths` 3,177, `stage1/rec/gameover` 3,008 and 5 more) |
| Called from | `HiroBusy` (tail), `AnimateActor` |
| Reads | `$5D30`-`$6538` (`BuildRowBaseLoop+10`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6630`-`$6638` (`WeaponActor+48`); `$6730`-`$6738` (`TitleColours+54`); `$6830`-`$6838` (`TitleColours+310`); `$6930`-`$6938` (`EnemySlots+84`); `$6A30`-`$6A38` (`FireHeld+77`); 1 more ranges |

### `ActorOffWindow` (`$8E95`)

**Z when the actor's box is wholly off the play window (+`$20`'s clip bits)**

A = +`$20`, then ClipFlagsOff `$8E98`. Called by the render's `$8A90` for each actor it draws.

Witness: L1 158778 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 387 calls, 5,805 t-states own (0.00 %) |
| Runs (the other recordings) | 19,617 calls (`stage1/rec/menu` 8,656, `stage1/rec/gameover` 4,860, `stage1/rec/deaths` 3,511 and 5 more) |
| Called from | `DrawActor` |
| Calls | `ClipFlagsOff` (falls into) |
| Reads | `$5D20`-`$6520` (`BuildOutlineMaskLoop+12`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6620` (`WeaponActor+32`); `$6720` (`TitleColours+38`); `$6820` (`TitleColours+294`); `$6920` (`EnemySlots+68`); `$6A20` (`FireHeld+61`); 1 more ranges |

### `ClipFlagsOff` (`$8E98`)

**Z when clip bits 7 and 6 are both set (off left and right) or 5 and 4 (off top and bottom)**

A = the clip bits made by ActorScreenBox `$8F75` (bit 7: the box starts past the right edge, bit 6: it ends past it, bit 5: it starts above the top, bit 4: it ends below the bottom). Z when (A AND `$C0`) = `$C0` or (A AND `$30`) = `$30`: nothing of the box is inside the window. L = the bits on return. Callers: ActorUpdate `$8E48` (with `$69DD`), ActorOffWindow `$8E95`.

Witness: L1 261190 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 695 calls, 36,125 t-states own (0.00 %) |
| Runs (the other recordings) | 23,719 calls (`stage1/rec/menu` 8,944, `stage1/rec/deaths` 6,491, `stage1/rec/gameover` 5,104 and 4 more) |
| Called from | `ActorUpdate`, `ActorOffWindow` (falls into) |

### `FrameRecord` (`$8EA3`)

**HL = `$D104` + (A - 1) x 24: the 24-byte record of graphic A**

A = a 1-based number; DE kept. Used by the render (`$89D9`, `$8A06`) to find a sprite's record in the table at `$D104` (24 bytes a record; the render reads it).

Witness: L1 549398 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,875 calls, 258,567 t-states own (0.02 %) |
| Runs (the other recordings) | 21,495 calls (`stage1/rec/deaths` 10,187, `stage1/rec/rooms` 4,520, `stage1/rec/menu` 2,045 and 4 more) |
| Called from | `ComposeTileWith`, `ComposeOverlay` |

### `CellIndex` (`$8EB5`)

**A = the room-cell index of the pixel at Y = L, X = H**

The play window is a grid of 20 columns of 8 pixels and rows of 16 pixels; RowBase `$7000` holds the index of each row's first cell (0, 20, 40 ... `$DC`). A = RowBase[L / 16] + H / 8. H is left `$70`. The index reads the room's cell arrays (`$6700`, `$6800`, `$6A00`) in the collision code. Callers: `$9C5B`, `$9C82`, `$9D81`, `$9E4C`.

Witness: L1 192856 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 872 calls, 69,191 t-states own (0.01 %) |
| Runs (the other recordings) | 11,485 calls (`stage1/rec/deaths` 8,304, `stage1/rec/rooms` 1,680, `stage1/rec/gameover` 591 and 4 more) |
| Called from | `CellSolid`, `ProbeCell` |
| Reads | `$7000`-`$700B` (`RowBase`) |

### `LastCellPixel` (`$8EC7`)

**DE = the pixel corner of the cell `$69E2` (the last cell CellIndex probed by `$9E3E`)**

Falls into CellPixel `$8ECA` with A = `$69E2`. Callers: `$965F`, `$9F29`.

Witness: L1 108 (bossgate, play48, throw, rzx x31, rzxroom x4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CellPixel` (`$8ECA`)

**Cell index A -> D = X (column x 8), E = Y (row x 16) of its top-left pixel**

Divides A by 20 by repeated subtraction (E counts from `$FF`). Caller: `$A5BF` (the room spawner), and LastCellPixel `$8EC7`.

Witness: L1 645 (bossgate, deaths, gameover, hiscore, play48, rooms, throw, c x1, poke-room x13, rzx x63, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 188 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/rooms` 12, `stage1/rec/deaths` 7, `stage1/rec/gameover` 1) |
| Called from | `SpawnEnemy` |

### `Multiply8` (`$8EDD`)

**HL = H x E (8 by 8 bits, shift and add)**

H and E unsigned; D is cleared, L ignored. Unrolled: eight `ADD HL,HL` / `ADD HL,DE` steps. Callers: the render `$8A90`, `$8B6A`, `$A0EE`, `$A91B`.

Witness: L1 239246 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 522 calls, 117,062 t-states own (0.01 %) |
| Runs (the other recordings) | 24,938 calls (`stage1/rec/menu` 10,420, `stage1/rec/gameover` 5,867, `stage1/rec/deaths` 4,861 and 5 more) |
| Called from | `DrawActor`, `ClipColumns`, `StripRecordAddress` |

### `RunActorSteps` (`$9A4B`)

**Run the next due actor step: the shot or the boss's shot, Hiro, the fallers, actor H**

Called by the actor update `$8E2B` with H = an active actor's page (562 575 runs). IY = that page.

Every other call (the operand at `$9A51` rotates `$AA`) the shot in page `$66` steps when it is active and due (the cyber-arm's shot moves at twice the rate); on the calls between, when a boss fight is on (`$9A59`), the actor in page `$60` (the boss's shot, BossFire). Bit 7 of `$6602` stops here. Then Hiro when due; then every page `$5E-$65` that is falling (+2 bit 2) and due; then actor H when due. Each "due" step (`$9A8E`) pops its caller's return, so the call ends after one step.

Witness: L1 3898691 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 28,339 calls, 16,170,457 t-states own (1.22 %) |
| Runs (the other recordings) | 534,237 calls (`stage1/rec/deaths` 225,247, `stage1/rec/menu` 134,580, `stage1/rec/rooms` 107,204 and 4 more) |
| Called from | `ActorUpdate` |
| Calls | `StepIfActive`, `StepIfDue`, `StepActor` (tail) |
| Reads | `$5D1D` (`BuildOutlineMaskLoop+9`); `$5E02`-`$5F02` (`IntroBox+7`, `IntroBoxRow`, `IntroBoxSide`, `IntroScript`); `$5F1D` (`IntroScript+208`); `$6002` (`HavokRoomEnter+46`); `$601D` (`HavokRoomEnter+73`); `$6102` (`SizeClasses+128`); 7 more ranges |
| Writes | `$6642`-`$664D` (`Vitality`, `VitalityShown`, `ChargeStep`, `Charge` and 8 more); `$69DF`-`$69E0` (`MapRow`, `MapColumn`); `$9A51` (`RunActorSteps+6`) |

### `StepIfActive` (`$9A89`)

**Step page D when it is active and due**

Witness: L1 2054144 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 14,169 calls, 459,030 t-states own (0.03 %) |
| Runs (the other recordings) | 267,120 calls (`stage1/rec/deaths` 112,623, `stage1/rec/menu` 67,290, `stage1/rec/rooms` 53,602 and 4 more) |
| Called from | `RunActorSteps` |
| Calls | `StepIfDue` (falls into) |
| Reads | `$6602` (`WeaponActor+2`) |

### `StepIfDue` (`$9A8E`)

**Step page D when its frame timer +`$1D` is zero**

Pops the caller's return (the call of RunActorSteps ends with this step), IY = HL = page D, falls into StepActor.

Witness: L1 3977795 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 28,338 calls, 948,729 t-states own (0.07 %) |
| Runs (the other recordings) | 533,067 calls (`stage1/rec/deaths` 225,366, `stage1/rec/menu` 133,829, `stage1/rec/rooms` 107,204 and 4 more) |
| Called from | `RunActorSteps`, `StepIfActive` (falls into) |
| Calls | `StepActor` (falls into) |
| Reads | `$5D1D` (`BuildOutlineMaskLoop+9`); `$5F1D` (`IntroScript+208`); `$661D` (`WeaponActor+29`) |

### `StepActor` (`$9A99`)

**One step of actor IY: the hold, the action slots, the falls, hurts and ends, the handler**

HL = IY = the actor. 8295 runs. The frame timer +`$1D` = the delay +`$1A`.

**Hold** (+`$28`): counted down, the step waits that many frames; when it ends and +`$0E` holds an animation, `JP $9087` (the actor turns towards Hiro and starts it: rooms, 3 runs).

StartLifetime `$9987`; the flag at `$9BE9` cleared.

**The action slots** +`$30-$38`: the first that is not 0 runs its handler from the table `$73E7` (+`$30` `$921C` the jump, +`$31` `$9238`, +`$32` `$91EE`, +`$33` `$91E1`, +`$34` `$91F4` the combat move, +`$35` `$920A` the fall damage, +`$36` `$9215`, +`$37` `$91A9` the end, +`$38` `$91D4`).

Else: in the air (+2 bit 1) FallStep `$9CD9`; hurt (+`$10` bit 4) `$904A`; expired (bit 5) `$9163`; bit 2 `$90A6`; Hiro with a combat move pending (`$6650`) `$926E`; else the handler at +3/+4 (RunHandler `$9AEC`).

Witness: L1 277931 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 398 calls, 240,369 t-states own (0.02 %) |
| Runs (the other recordings) | 7,897 calls (`stage1/rec/deaths` 4,222, `stage1/rec/rooms` 1,506, `stage1/rec/menu` 1,170 and 4 more) |
| Called from | `RunActorSteps` (tail), `StepIfDue` (falls into) |
| Calls | `FallSequenceStart` (tail), `TurnToHiro` (tail), `ActorExpired` (tail), `HiroAttack` (tail), `StartLifetime`, `RunHandler` (falls into), `FallStep` (tail) |
| Reads | `$5D02`-`$5D38` (`Hiro+2`, `BuildPageTails`); `$5E02`-`$5E38` (`IntroBox+7`, `IntroBoxRow`); `$5F02`-`$5F38` (`IntroScript+181`); `$6002`-`$6038` (`HavokRoomEnter+46`); `$6102`-`$6138` (`SizeClasses+128`); `$6502`-`$6538` (`ActorPage9+2`); 3 more ranges |
| Writes | `$5D1D` (`BuildOutlineMaskLoop+9`); `$5E1D`-`$5E28` (`IntroBoxSides+3`); `$5F1D`-`$5F28` (`IntroScript+208`); `$601D`-`$6028` (`HavokRoomEnter+73`); `$611D` (`SizeClasses+155`); `$651D` (`ActorPage9+29`); 2 more ranges |

### `RunHandler` (`$9AEC`)

**Jump to the actor's behaviour handler at +3/+4**

Reached from StepActor and by `JP $9AEC` from `$920A`, `$926E` (and the handler `$9216`). The handler runs with HL = IY = the actor.

Witness: L1 234521 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,217 calls (`stage1/rec/deaths` 3,217) |
| Called from | `FallDamageStep` (tail), `StepActor` (falls into) |
| Calls | `JumpToHandler` (falls into) |
| Reads | `$5D03`-`$5D04` (`Hiro+3`); `$5E03`-`$5E04` (`IntroBox+8`); `$5F03`-`$5F04` (`IntroScript+182`); `$6503`-`$6504` (`ActorPage9+3`) |

### `JumpToHandler` (`$9AF1`)

**JP (BC)**

Witness: L1 262694 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,021 calls (`stage1/rec/deaths` 4,021) |
| Called from | `RunHandler` (falls into) |
| Calls | `DeathStep`, `RiseStep`, `TurnStep`, `PoseStep`, `ActionStep`, `FallDamageStep`, `JumpStep`, `FallScriptStep`, `HiroControl`, `ChaserControl`, `StillControl`, `StalactiteControl`, `PatrolControl`, `PathControl` |

### `TemplateForKind` (`$A652`)

**DE = the actor template of kind A (the word table at `$7200`)**

DE = the word at `$7200` + 2 (A AND `$7F`). Callers: `$926E`, `$98B6`, `$9ED7`, SpawnEnemy. 22 runs.

Witness: L1 775 (bossgate, deaths, gameover, hiscore, play48, rooms, throw, c x1, poke-room x13, rzx x65, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 54 t-states own (0.00 %) |
| Runs (the other recordings) | 21 calls (`stage1/rec/rooms` 12, `stage1/rec/deaths` 8, `stage1/rec/gameover` 1) |
| Called from | `CollectPickup`, `SpawnEnemy` |
| Reads | `$7202`-`$720B` (`KindTemplates+2`); `$7234`-`$7235` (`KindTemplates+52`); `$7256`-`$7271` (`KindTemplates+86`) |

### `InitActor` (`$A65D`)

**Set up an actor page from an 18-byte template**

In: HL = the page (L ignored), C = Y, B = X, DE = the template, A = the kind. +0 Y, +1 X; `+$1C-$41` cleared; the template to +3-+`$14`; its last byte (+`$14`) is the frame: CopyFrameRecord `$A6D8` copies the frame's 5 bytes from `$6082` + 5 x frame to +`$15-$19`; +`$1A` = +`$1B` = 1; +`$3C` = the frame (the base); +2 = `$81` for kind `$2A`, else 1 (active); +`$1C` = the kind. Kinds `$25-$29` are kept in `$9A59` (read by the energy reload `$9615`).

Out: DE = page + `$1C`, A = the kind. Callers: `$5C68` (Hiro at the start), `$926E`, `$947D`, `$965F`, `$9962`, `$9ED7`, SpawnEnemy, the title (LoadTitlePieces `$A7D7`). 899 runs (every recording).

Witness: L1 2229 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x13, rzx x71, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 17 calls, 28,334 t-states own (0.00 %) |
| Runs (the other recordings) | 882 calls (`stage1/rec/menu` 451, `stage1/rec/gameover` 253, `stage1/rec/c48` 41 and 5 more) |
| Called from | `MatchCheatName`, `GlyphBytesAsCode`, `SpawnShield`, `SpawnEnemy`, `TitleSequence` |
| Calls | `CopyFrameRecord` |
| Reads | `$5D14`-`$6414` (`BuildOutlineMaskLoop`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6514` (`ActorPage9+20`); `$6594`-`$65ED` (`ActorPage9+148`, `SharedEnemyTemplate`, `HiroTemplate`, `TitlePieceTemplate`); `$6614` (`WeaponActor+20`); `$6714` (`TitleColours+26`); `$6814` (`TitleColours+282`); 3 more ranges |
| Writes | `$5D00`-`$6541` (`Hiro`, `BuildPageTails`, `Intro48`, `IntroScene` and 24 more); `$6600`-`$6641` (`WeaponActor`); `$6700`-`$6741` (`TitleColours+6`); `$6800`-`$6841` (`TitleColours+262`); `$6900`-`$6941` (`EnemySlots+36`); `$6A00`-`$6A41` (`FireHeld+29`); 1 more ranges |

### `ActorFrameBack` (`$A6A1`)

**Undo the X offset of the last frame step and show the base frame**

X (+1) -= +`$3D`, +`$3D` = 0; A = +`$3C` (the base frame); joins SetActorFrame `$A6D0`. Callers: `$9201`, `$9240`. 219 runs.

Witness: L1 4446 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9 calls, 711 t-states own (0.00 %) |
| Runs (the other recordings) | 210 calls (`stage1/rec/deaths` 147, `stage1/rec/rooms` 40, `stage1/rec/gameover` 5 and 4 more) |
| Called from | `SequenceEndDrop`, `FallMove` |
| Calls | `SetActorFrame` (tail) |
| Reads | `$5D01` (`Hiro+1`); `$5D3C`-`$5D3D` (`BuildBoxPlaceLoop+8`); `$5E01` (`IntroBox+6`); `$5E3C`-`$5E3D` (`IntroBoxRowLoop+4`); `$5F01` (`IntroScript+180`); `$5F3C`-`$5F3D` (`IntroScript+239`) |
| Writes | `$5D01` (`Hiro+1`); `$5D3D` (`BuildBoxPlaceLoop+9`); `$5E01` (`IntroBox+6`); `$5E3D` (`IntroBoxRowLoop+5`); `$5F01` (`IntroScript+180`); `$5F3D` (`IntroScript+240`) |

### `ActorFrameStep` (`$A6B1`)

**Show a frame from a 3-byte step at BC: X offset (by facing) and the frame**

+`$3D` = X; bit 7 of +`$1B` picks the first or the second byte as the X offset; X += it, +`$3D` = the offset; the third byte is the frame; BC moves past the step. Joins SetActorFrame. Caller: `$919F`. 284 runs.

Witness: L1 6615 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 11 calls, 1,529 t-states own (0.00 %) |
| Runs (the other recordings) | 273 calls (`stage1/rec/deaths` 190, `stage1/rec/rooms` 50, `stage1/rec/gameover` 9 and 4 more) |
| Called from | `SequenceTiming` |
| Calls | `SetActorFrame` (falls into) |
| Reads | `$5D01` (`Hiro+1`); `$5D1B` (`BuildOutlineMaskLoop+7`); `$5E01` (`IntroBox+6`); `$5E1B` (`IntroBoxSides+1`); `$5F01` (`IntroScript+180`); `$5F1B` (`IntroScript+206`); 12 more ranges |
| Writes | `$5D01` (`Hiro+1`); `$5D3D` (`BuildBoxPlaceLoop+9`); `$5E01` (`IntroBox+6`); `$5E3D` (`IntroBoxRowLoop+5`); `$5F01` (`IntroScript+180`); `$5F3D` (`IntroScript+240`); 2 more ranges |

### `SetActorFrame` (`$A6D0`)

**+`$14` = frame A, its 5-byte record to +`$15`**

Witness: L1 11061 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 20 calls, 971 t-states own (0.00 %) |
| Runs (the other recordings) | 483 calls (`stage1/rec/deaths` 337, `stage1/rec/rooms` 90, `stage1/rec/gameover` 14 and 4 more) |
| Called from | `ActorFrameBack` (tail), `ActorFrameStep` (falls into) |
| Calls | `CopyFrameRecordBody` (tail) |
| Writes | `$5D14` (`BuildOutlineMaskLoop`); `$5E14` (`IntroBox+25`); `$5F14` (`IntroScript+199`); `$6514` (`ActorPage9+20`) |

### `CopyFrameRecord` (`$A6D8`)

**Copy the 5 bytes of frame A from `$6082` + 5A to DE**

HL and BC kept. 899 runs.

Witness: L1 2229 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x13, rzx x71, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 17 calls, 192 t-states own (0.00 %) |
| Runs (the other recordings) | 882 calls (`stage1/rec/menu` 451, `stage1/rec/gameover` 253, `stage1/rec/c48` 41 and 5 more) |
| Called from | `InitActor` |
| Calls | `CopyFrameRecordBody` (falls into) |

### `CopyFrameRecordBody` (`$A6D9`)

**The copy itself (SetActorFrame joins here with HL already pushed)**

Witness: L1 13290 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 37 calls, 15,565 t-states own (0.00 %) |
| Runs (the other recordings) | 1,324 calls (`stage1/rec/menu` 457, `stage1/rec/deaths` 366, `stage1/rec/gameover` 267 and 4 more) |
| Called from | `SetActorFrame` (tail), `CopyFrameRecord` (falls into) |
| Reads | `$6082`-`$60F9` (`SizeClasses`) |
| Writes | `$5D15`-`$6519` (`BuildOutlineMaskLoop+1`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6615`-`$6619` (`WeaponActor+21`); `$6715`-`$6719` (`TitleColours+27`); `$6815`-`$6819` (`TitleColours+283`); `$6915`-`$6919` (`EnemySlots+57`); `$6A15`-`$6A19` (`FireHeld+50`); 1 more ranges |

## render

`src/game/render.asm`

### `ClearScreen` (`$8339`)

**Clear the screen: attributes to 0, pixels to 0, then the attributes to A**

Callers: `$5C68`, `$5D4F`, the title `$6A7B`, `$A6FD`, `$A73E`, `$A806`.

Witness: L1 140 (deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x7, rzxroom x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 6 calls, 983,218 t-states own (0.07 %) |
| Runs (the other recordings) | 100 calls (`stage1/rec/menu` 42, `stage1/rec/gameover` 25, `stage1/rec/c48` 10 and 4 more) |
| Called from | `MatchCheatName`, `Intro48`, `ControlMenu`, `ShowHighScores`, `TitleSequence` |
| Calls | `FillAttributes` (falls into), `BlackAttributes` |
| Reads | `$4000`-`$57FF` (screen) |
| Writes | `$4000`-`$5800` (screen) |

### `FillAttributes` (`$834A`)

**Fill all 768 attributes with A**

Witness: L1 280 (deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x7, rzxroom x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 12 calls, 360 t-states own (0.00 %) |
| Runs (the other recordings) | 200 calls (`stage1/rec/menu` 84, `stage1/rec/gameover` 50, `stage1/rec/c48` 20 and 4 more) |
| Called from | `ClearScreen` (falls into), `BlackAttributes` (tail) |
| Calls | `FillAttrRun` (falls into) |

### `FillAttrRun` (`$8353`)

**(HL) = A, then LDIR BC more bytes**

Witness: L1 294 (deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x7, rzxroom x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 13 calls, 268,465 t-states own (0.02 %) |
| Runs (the other recordings) | 187 calls (`stage1/rec/menu` 86, `stage1/rec/gameover` 51, `stage1/rec/opt3` 13 and 3 more) |
| Called from | `FillAttributes` (falls into), `FillPlayAttributes` (tail) |
| Reads | `$5800`-`$5AFE` (screen) |
| Writes | `$5800`-`$5AFF` (screen) |

### `BlackAttributes` (`$8357`)

**All attributes to 0**

Witness: L1 140 (deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, rzx x7, rzxroom x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 6 calls, 96 t-states own (0.00 %) |
| Runs (the other recordings) | 100 calls (`stage1/rec/menu` 42, `stage1/rec/gameover` 25, `stage1/rec/c48` 10 and 4 more) |
| Called from | `ClearScreen` |
| Calls | `FillAttributes` (tail) |

### `FillPlayAttributes` (`$835A`)

**Fill the attributes of character rows 1-22 (`$5820`, 704 bytes) with A**

Caller: `$5C68` (the start of a life).

Witness: L1 14 (deaths, gameover, havok, hiscore, menu, play48, throw, c x1, opt x3, rzx x1, rzxroom x1).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 42 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/menu` 2, `stage1/rec/deaths` 1, `stage1/rec/gameover` 1 and 3 more) |
| Called from | `MatchCheatName` |
| Calls | `FillAttrRun` (tail) |

### `CellScreenAddress` (`$8803`)

**DE = the screen address of tile-map cell A (20 a row, 12 x 16 pixels each), + 1**

E = A / 20 (the row), A = A mod 20 (the column); DrawColumnPos = column x 4; B = 2 x row, C = column x 1.5 (character columns), the half-character flag (column AND 1) into the operand at `$8879`; CharCellAddress (one character row down). Callers: RedrawCellMask `$8873`, ComposeCell.

Witness: L1 65975 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x61, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 660 calls, 185,321 t-states own (0.01 %) |
| Runs (the other recordings) | 22,246 calls (`stage1/rec/rooms` 19,306, `stage1/rec/deaths` 1,400, `stage1/rec/gameover` 440 and 4 more) |
| Called from | `RedrawCellMask`, `ComposeCell` |
| Calls | `CharCellAddress` |
| Writes | `$732A` (`DrawColumnPos`); `$8879` (`EraseCell+6`) |

### `SpriteScreenAddress` (`$8828`)

**DE = the screen address for X A (in 4-pixel units x 4), row E, with the phase table at `$FDF5`**

C = A / 4 x 1.5, CharCellAddress; E = (E AND `$E0`) + the column from DrawColumnPos and the byte `$FDF5` + (DrawColumnPos AND 7). Callers: DrawHavok, `$8C68`.

Witness: L1 113205 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 372 calls, 69,456 t-states own (0.01 %) |
| Runs (the other recordings) | 13,477 calls (`stage1/rec/menu` 5,275, `stage1/rec/deaths` 3,044, `stage1/rec/gameover` 3,008 and 5 more) |
| Called from | `BlitWindow` |
| Calls | `CharCellAddress` |
| Reads | `$732A` (`DrawColumnPos`); `$FDF5`-`$FDFC` (`UnitByteOffsets`) |

### `RedrawRoomMasked` (`$8852`)

**Redraw every cell with the reveal mask `$6DFF`**

Caller: the room lookup `$95C3`.

Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 55,656 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/rooms` 7, `stage1/rec/deaths` 6, `stage1/rec/gameover` 2 and 4 more) |
| Called from | `EnterRoom` |
| Calls | `RedrawCellsMasked` (falls into) |
| Reads | `$6DFF` (`RevealedZones`) |

### `RedrawCellsMasked` (`$8855`)

**For the 220 cells (20 x 11): RedrawCellMask with C = A AND `$FC`**

Caller: `$955A`.

Witness: L1 313 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x59, rzxroom x18).

[Animation: `RedrawCellsMasked` at work](img/routines/RedrawCellsMasked.gif)

[Animation: `RedrawCellsMasked` at work, zone](img/routines/RedrawCellsMasked-zone.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 95 calls (`stage1/rec/rooms` 88, `stage1/rec/deaths` 7) |
| Called from | `RedrawRoomMasked` (falls into), `CheckRoomExit` |
| Calls | `RedrawCell` |

### `RedrawCell` (`$8867`)

**A = C, then RedrawCellMask**

Witness: L1 68685 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x59, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 660 calls, 173,083 t-states own (0.01 %) |
| Runs (the other recordings) | 22,440 calls (`stage1/rec/rooms` 19,360, `stage1/rec/deaths` 1,540, `stage1/rec/gameover` 440 and 4 more) |
| Called from | `RedrawCellsMasked` |
| Reads | `$66F7`-`$67DB` (`CellColours`, `TitleColours`); `$6800`-`$68DB` (`TitleColours+262`); `$6900`-`$69DB` (`EnemySlots+36`); `$6A00`-`$6ADB` (`FireHeld+29`, `ControlMenu`, `ControlMenuKey`, `ControlMenuText`); `$6B00`-`$6BDB` (`ZoneRecords+31`, `ControlRecords`, `ControlGap`, `PageTailTemplate` and 1 more); `$6C00`-`$6CDA` (`CellProperty+29`, `WalkLists`, `WeaponRecords`, `TouchZoneRecords` and 2 more); 1 more ranges |
| Writes | `$5821`-`$5ADD` (screen) |

### `RedrawCellMask` (`$8868`)

**Cell L: when its flags (`$6700` + L) AND A are set draw it (layers), else erase it unless the reveal mask `$6DFF` covers it**

Caller: RedrawCell, `$9E61`.

Witness: L1 68736 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x61, rzxroom x18).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `CellScreenAddress`, `MaskCellRows` (falls into) |

### `MaskCellRows` (`$888D`)

**AND 8 pixel lines of two bytes at HL with D and E**

Witness: L1 78654 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x59, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 480 calls, 248,632 t-states own (0.02 %) |
| Runs (the other recordings) | 39,704 calls (`stage1/rec/rooms` 37,328, `stage1/rec/deaths` 1,256, `stage1/rec/gameover` 320 and 4 more) |
| Called from | `RedrawCellMask` (falls into) |
| Calls | `ComposeCell`, `BlitWindowAt` (tail) |
| Reads | `$4021`-`$42FE` (screen); `$4321`-`$43FE` (screen); `$4421`-`$44FE` (screen); `$4521`-`$45FE` (screen); `$4621`-`$46FE` (screen); `$4721`-`$57DE` (screen) |
| Writes | `$4021`-`$42FE` (screen); `$4321`-`$43FE` (screen); `$4421`-`$44FE` (screen); `$4521`-`$45FE` (screen); `$4621`-`$46FE` (screen); `$4721`-`$57DE` (screen) |

### `ComposeCell` (`$88DB`)

**Compose cell L into the buffer `$5D4A`: the back layers, then the front layers, 4 rows of `$10` pixel lines, DE = its screen address**

ComposeCellColumn with ComposeBackCell `$898C`, then with ComposeFrontCell `$8943`; `$8C76` = 4, `$8D27` = `$10` (the blitter's rows and lines); CellScreenAddress.

Witness: L1 26646 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x14, rzx x61, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 420 calls, 73,642 t-states own (0.01 %) |
| Runs (the other recordings) | 2,394 calls (`stage1/rec/deaths` 772, `stage1/rec/rooms` 642, `stage1/rec/gameover` 280 and 4 more) |
| Called from | `MaskCellRows` |
| Calls | `CellScreenAddress`, `ComposeCellColumn` |
| Writes | `$8C76` (`BlitWindowWidth+2`); `$8D27` (`PackRowLines+1`) |

### `ComposeCellColumn` (`$88F9`)

**One cell through the routine BC (stored as the CALL at `$8932`), 4 rows, buffer `$5D4A`**

Witness: L1 53293 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x14, rzx x61, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 840 calls, 49,560 t-states own (0.00 %) |
| Runs (the other recordings) | 4,788 calls (`stage1/rec/deaths` 1,544, `stage1/rec/rooms` 1,284, `stage1/rec/gameover` 560 and 4 more) |
| Called from | `ComposeCell` |
| Calls | `ComposeRows` (tail) |
| Writes | `$8933`-`$8934` (`ComposeRowLoop+9`) |

### `ComposeActorCells` (`$8907`)

**Compose the cells under an actor into its buffer (ComposeDest): rows (`$69DE`), cell (`$A56E`), phase (DrawColumnPos)**

BC = the routine (ComposeBackCell / ComposeFrontCell); L = the cell (`$A56E` operand), B = the rows (`$69DE`), C = (DrawColumnPos AND 3) x 6, A = the line count (`$8C76`), DE = ComposeDest. Caller: the actor update `$8E2B`.

Witness: L1 203037 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 616 calls, 86,714 t-states own (0.01 %) |
| Runs (the other recordings) | 9,774 calls (`stage1/rec/deaths` 5,960, `stage1/rec/rooms` 1,790, `stage1/rec/menu` 576 and 4 more) |
| Called from | `ActorUpdate` |
| Calls | `ComposeRows` (falls into) |
| Reads | `$69DE` (`BoxClip+1`); `$732A` (`DrawColumnPos`); `$74BA`-`$74BB` (`ComposeDest`); `$8C76` (`BlitWindowWidth+2`); `$A56E` (`RevealZone+5`) |
| Writes | `$8933`-`$8934` (`ComposeRowLoop+9`) |

### `ComposeRows` (`$8926`)

**B rows: the count A into `$892E`, then per row the routine, DE + 16, L + 20**

Witness: L1 256331 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,456 calls, 358,985 t-states own (0.03 %) |
| Runs (the other recordings) | 14,562 calls (`stage1/rec/deaths` 7,504, `stage1/rec/rooms` 3,074, `stage1/rec/menu` 1,136 and 4 more) |
| Called from | `ComposeCellColumn` (tail), `ComposeActorCells` (falls into) |
| Calls | `ComposeFrontCell`, `ComposeBackCell` |
| Writes | `$892E` (`ComposeRowLoop+4`); `$89F6` (`ComposeTileLoop+10`) |

### `ComposeFrontCell` (`$8943`)

**The front layers (`$6A00` / `$6B00`) of cell L, or the blank tile `$43` when the cell's flags AND `$6DFF` are clear**

Witness: L1 349517 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,002 calls, 454,988 t-states own (0.03 %) |
| Runs (the other recordings) | 10,623 calls (`stage1/rec/deaths` 5,113, `stage1/rec/rooms` 2,425, `stage1/rec/menu` 833 and 4 more) |
| Called from | `ComposeRows` |
| Calls | `ComposeTwoTiles`, `ComposeTile` |
| Reads | `$6700`-`$67DA` (`TitleColours+6`); `$6A00`-`$6ADA` (`FireHeld+29`, `ControlMenu`, `ControlMenuKey`, `ControlMenuText`); `$6B00`-`$6BDA` (`ZoneRecords+31`, `ControlRecords`, `ControlGap`, `PageTailTemplate` and 1 more); `$6DFF` (`RevealedZones`); `$89F6` (`ComposeTileLoop+10`) |
| Writes | `$89F6` (`ComposeTileLoop+10`) |

### `ComposeBackCell` (`$898C`)

**The back layers (`$6800` / `$6900`) of cell L: one tile, both (ComposeTwoTiles) or the blank tile `$43`**

Witness: L1 349509 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,002 calls, 223,134 t-states own (0.02 %) |
| Runs (the other recordings) | 10,623 calls (`stage1/rec/deaths` 5,113, `stage1/rec/rooms` 2,425, `stage1/rec/menu` 833 and 4 more) |
| Called from | `ComposeRows` |
| Calls | `ComposeTwoTiles`, `ComposeTileOverlay` |
| Reads | `$6800`-`$68DA` (`TitleColours+262`); `$6900`-`$69DA` (`EnemySlots+36`); `$89F6` (`ComposeTileLoop+10`) |

### `ComposeTwoTiles` (`$89B2`)

**Compose the tile (HL), then the tile B over it, keeping the column count at `$89F6`**

Witness: L1 21094 (bossgate, deaths, play48, rooms, poke-room x14, rzx x67, rzxroom x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 98 calls (`stage1/rec/deaths` 73, `stage1/rec/rooms` 25) |
| Called from | `ComposeFrontCell`, `ComposeBackCell` |
| Calls | `ComposeTile`, `ComposeTileWith` (tail) |
| Reads | `$681C`-`$6846` (`TitleColours+290`); `$685A`-`$686E` (`TitleColours+352`); `$68AD` (`TitleColours+435`); `$68C0`-`$68C4` (`TitleColours+454`); `$6A4C` (`FireHeld+105`); `$6A7C` (`ControlMenu+1`); 3 more ranges |
| Writes | `$89F6` (`ComposeTileLoop+10`) |

### `ComposeTile` (`$89CE`)

**Compose tile A: codes `$4B` and up through `$8C0A`, else ComposeTileOverlay**

Witness: L1 123014 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 362 calls, 14,842 t-states own (0.00 %) |
| Runs (the other recordings) | 3,010 calls (`stage1/rec/rooms` 882, `stage1/rec/deaths` 857, `stage1/rec/menu` 442 and 4 more) |
| Called from | `ComposeFrontCell`, `ComposeTwoTiles` |
| Calls | `ComposeTileOverlay` (falls into) |

### `ComposeTileOverlay` (`$89D2`)

**ComposeOverlay first (tiles `$1B` and up with an overlay nibble in `$6C00`), then the tile**

Witness: L1 365175 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,513 calls, 50,742 t-states own (0.00 %) |
| Runs (the other recordings) | 17,498 calls (`stage1/rec/deaths` 8,426, `stage1/rec/rooms` 3,555, `stage1/rec/menu` 1,603 and 4 more) |
| Called from | `ComposeBackCell`, `ComposeTile` (falls into) |
| Calls | `ComposeOverlay` |

### `ComposeTilePlain` (`$89D5`)

**Compose tile B with the 3-bit unpacker `$8BC8`**

Witness: L1 365175 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,289 calls (`stage1/rec/deaths` 1,077, `stage1/rec/rooms` 212) |
| Called from | `ComposeOverlay` |
| Calls | `ComposeTileWith` (falls into) |

### `ComposeTileWith` (`$89D9`)

**Compose a tile with the unpacker HL (stored as the CALL at `$89F0`): its packed data from `$8EA3`**

Witness: L1 452405 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,875 calls, 952,054 t-states own (0.07 %) |
| Runs (the other recordings) | 20,206 calls (`stage1/rec/deaths` 9,110, `stage1/rec/rooms` 4,308, `stage1/rec/menu` 2,045 and 4 more) |
| Called from | `ComposeTwoTiles` (tail), `ComposeTilePlain` (falls into) |
| Calls | `FrameRecord` |
| Writes | `$89F1`-`$89F6` (`ComposeTileLoop+5`); `$8C13`-`$8C1E` (`MaskedColumnRows+1`, `MaskedColumnStart`) |

### `ComposeTileRows` (`$89DF`)

**The unpacker's operands (`$8C1E` = `$50`, `$8C13` = `$0E`), then 2-byte rows into DE, C + 6 a column up to `$12`**

Witness: L1 549398 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,289 calls (`stage1/rec/deaths` 1,077, `stage1/rec/rooms` 212) |
| Called from | `ComposeOverlay` (tail) |
| Calls | `AndTileColumns`, `UnpackGroups`, `MaskedColumns` |
| Writes | `$69E0` (`MapColumn`); `$89F6` (`ComposeTileLoop+10`); `$8C13`-`$8C1E` (`MaskedColumnRows+1`, `MaskedColumnStart`) |

### `ComposeOverlay` (`$8A06`)

**Tiles `$1B` and up: when (`$6C00` + L) AND `$0F` is n, compose the tile, then tile `$43` + n ANDed in by AndTileColumns**

Witness: L1 365175 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,513 calls, 77,470 t-states own (0.01 %) |
| Runs (the other recordings) | 17,498 calls (`stage1/rec/deaths` 8,426, `stage1/rec/rooms` 3,555, `stage1/rec/menu` 1,603 and 4 more) |
| Called from | `ComposeTileOverlay` |
| Calls | `ComposeTilePlain`, `ComposeTileRows` (tail), `FrameRecord` |
| Reads | `$6C00`-`$6CD9` (`CellProperty+29`, `WalkLists`, `WeaponRecords`, `TouchZoneRecords` and 2 more); `$89F6` (`ComposeTileLoop+10`) |
| Writes | `$89F1`-`$89F6` (`ComposeTileLoop+5`) |

### `AndTileColumns` (`$8A2F`)

**AND a tile's columns into the chunk buffer (the shade of a cell)**

The AND variant of the column writer of DrawTileColumns `$89D9`: ShadeTile `$8A06` puts `$8A2F` in the call operand `$89F1`, finds the shade tile `$43` + n with TileAddress `$8EA3` and runs DrawTileColumns, which calls here once a 3-pixel column with HL = the chunk byte of its top line and DE = the column's packed bytes, B = the groups of 8 values (2 for a 16-line tile).

Each group of three bytes gives eight 3-bit values, most significant first (the same unpacking as UnpackGroups `$8BC8`); each value is ANDed into the buffer byte of its line (L + 1 a line). The shade tiles `$44-$4A` are dot patterns, so a shaded wall shows its texture through a grid of holes (ROOM-tmp/swroom.py draws them so; the c1 end screen agrees in every cell but the sprites').

Out: DE = the byte after the column, HL = the next buffer line.

The entry is one byte below the region `$8A30`: the loop is `$8A30`, the `EX DE,HL` before it swaps the pointers DrawTileColumns hands over.

Witness: L1 264980 (bossgate, deaths, play48, rooms, poke-room x14, rzx x67, rzxroom x13).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,507 calls (`stage1/rec/deaths` 2,791, `stage1/rec/rooms` 716) |
| Called from | `ComposeTileRows` |
| Reads | `$5D42`-`$5D79` (`BuildBoxPlaceLoop+14`, `Intro48`); `$5E42`-`$5E79` (`IntroBoxSide+3`, `IntroScript`); `$5F42`-`$5F79` (`IntroScript+245`); `$6042`-`$6079` (`HavokRoomEnter+110`); `$6142`-`$6169` (`SizeClasses+192`); `$6242`-`$6251` (`IntroAttrsB+14`, `IntroAttrsC`); 1 more ranges |
| Writes | `$5D42`-`$5D79` (`BuildBoxPlaceLoop+14`, `Intro48`); `$5E42`-`$5E79` (`IntroBoxSide+3`, `IntroScript`); `$5F42`-`$5F79` (`IntroScript+245`); `$6042`-`$6079` (`HavokRoomEnter+110`); `$6142`-`$6169` (`SizeClasses+192`); `$6242`-`$6251` (`IntroAttrsB+14`, `IntroAttrsC`) |

### `DrawFrontActors` (`$8A73`)

**Draw the actors that stand in front of the cells' front layer**

E = `$80` (actor flag +2 bit 7: drawn in front), D = `$20` (bit 5 set: not drawn), then DrawActorsAll `$8A76`. Called by ActorUpdate `$8E2B` (`CALL C,$8A73`) after the front pass of the cells, only when an actor of the window holds bit 7.

Witness: L1 11205 (bossgate, deaths, gameover, hiscore, menu, play48, opt x3, rzx x26).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 372 calls (`stage1/rec/menu` 201, `stage1/rec/gameover` 41, `stage1/rec/opt2` 41 and 3 more) |
| Called from | `ActorUpdate` |
| Calls | `DrawActorsAll` (falls into) |

### `DrawActorsAll` (`$8A76`)

**Draw the actors of all ten pages that overlap the window**

B = 10 pages from `$5D00` (`$5D-$66`), C = 0. Called by ActorUpdate `$8E2B` with DE = `$A001` (draw the active ones, flag +2 bit 0, unless bit 7 or 5 is set) between the back pass (DrawWindowCells `$8907` with DrawCellBack `$898C`) and the front pass (with DrawCellFront `$8943`), and by DrawFrontActors with DE = `$2080`.

Witness: L1 112726 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 308 calls, 3,080 t-states own (0.00 %) |
| Runs (the other recordings) | 5,259 calls (`stage1/rec/deaths` 2,987, `stage1/rec/rooms` 895, `stage1/rec/menu` 489 and 4 more) |
| Called from | `DrawFrontActors` (falls into), `ActorUpdate` |
| Calls | `DrawActors` (falls into) |
| Reads | `$5D02`-`$5F02` (`Hiro+2`, `BuildPageTails`, `Intro48`, `IntroScene` and 10 more); `$6002` (`HavokRoomEnter+46`); `$6102` (`SizeClasses+128`); `$6202` (`PrintGlyphsAddress+2`); `$6302` (`IntroAttrsC+191`); `$6402` (`IntroGlyphs+239`); 2 more ranges |

### `DrawActors` (`$8A79`)

**Draw the actors whose flags match E and not D into the window**

In: B = the number of actor pages from `$5D00`, D = the flags that skip an actor, E = the flags that select it, C = 0. For each page: C |= flag byte +2; when +2 AND E is not 0, DrawActor `$8A90`. Out: C = the OR of all the flag bytes (the caller tests bit 7 to know whether a front pass is needed).

Called directly by `$A73E` (`$A7B9`: the redraw of one actor's box after it moved, then BlitWindow `$8C68`).

Witness: L1 123592 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 372 calls, 369,424 t-states own (0.03 %) |
| Runs (the other recordings) | 12,957 calls (`stage1/rec/menu` 5,476, `stage1/rec/deaths` 3,051, `stage1/rec/gameover` 3,049 and 4 more) |
| Called from | `DrawActorsAll` (falls into), `TitleSequence` |
| Calls | `DrawActor` |
| Reads | `$5D02`-`$6502` (`Hiro+2`, `BuildPageTails`, `Intro48`, `IntroScene` and 24 more); `$6602` (`WeaponActor+2`); `$6702` (`TitleColours+8`); `$6802` (`TitleColours+264`); `$6902` (`EnemySlots+38`); `$6A02` (`FireHeld+31`); 1 more ranges |

### `DrawActor` (`$8A90`)

**Draw one actor, clipped to the window, into the chunk buffer**

In: HL = the actor's flag byte (+2), D = the flags that skip it. Out: nothing; IX, the patched operands of the column drawers changed.

**Skips.** A flag of D set; `$9A27` (no carry: the actor's box +`$2A-$2D` (left, right, top, bottom) does not meet the window's `$732A-$732D`); kind +`$1C` = `$25` (a giant: drawn by its own code).

**Removal.** State +`$20` bit 1 asks for removal: the bit is cleared, `$8E95` tests the state; when the actor is gone its flags +2 are cleared and, when +`$29` holds a cell number, that cell of layer `$68` (`$68DB` + n) is emptied and the reveal spawner `$A59B` runs.

**Vertical cull.** `$8E95`, then a Y (+0) in `$A0-$C7` (below the room) is not drawn.

**Clip.** BC = the window's left and right (`$732A`, `$732B`). E = the units cut off on the left (window left - X +`$2A`, 0 when the actor starts inside); the first chunk page = `$5D` + E. C = the first column of the frame drawn; mirrored actors (+`$20` bit 7) count the columns from their right edge. The number of columns = the window width (`$8C76`) - E - the units the actor's right edge (+`$2B`) lies left of the window's right edge. The first line = `$4A` + Y - the window top (the operand `$8B15`, written by `$8F75`).

**The frame.** IX = the set's address (+`$18`/`$19`) + frame (+`$23`) x bytes a frame (+`$17`) (Multiply `$8EDD`). Plain: ClipColumns `$8B6A`, then MaskedColumns `$8C0A` once a column. Mirrored (+`$1B` bit 7): the columns are walked from the right (DE = -bytes a column) through MirroredColumn `$8C51`.

Run 1440 times in c1 and 132818 times in the stage 1 recordings: every visible actor, every frame it moves.

Witness: L1 610301 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

[Animation: `DrawActor` at work](img/routines/DrawActor.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,440 calls, 496,672 t-states own (0.04 %) |
| Runs (the other recordings) | 131,378 calls (`stage1/rec/menu` 69,671, `stage1/rec/gameover` 38,726, `stage1/rec/deaths` 8,708 and 5 more) |
| Called from | `DrawActors` |
| Calls | `ClipColumns`, `MaskedColumns`, `MirroredColumn`, `ActorOffWindow`, `Multiply8`, `BoxesOverlap` |
| Reads | `$5D00`-`$652B` (`Hiro`, `BuildPageTails`, `Intro48`, `IntroScene` and 24 more); `$6600`-`$6602` (`WeaponActor`); `$6617`-`$662B` (`WeaponActor+23`); `$6700`-`$6702` (`TitleColours+6`); `$6717`-`$672B` (`TitleColours+29`); `$6800`-`$6802` (`TitleColours+262`); 9 more ranges |
| Writes | `$5E20` (`IntroBoxSides+6`); `$5F20` (`IntroScript+211`); `$6020` (`HavokRoomEnter+76`); `$6120` (`SizeClasses+158`); `$6602` (`WeaponActor+2`); `$6620` (`WeaponActor+32`); 1 more ranges |

### `ClipColumns` (`$8B6A`)

**Set up the column drawers for an actor's frame and its vertical clip**

In: H = the actor page, A = the first frame column drawn (Z when 0), IX = the frame's address. Rows +`$16`: B = rows / 4, E = rows x 3 / 8, the bytes a column; -E goes to DrawActorMirrorStep `$8B60`. IX += A x E skips the columns cut on the left.

ClipColumnsStart `$8B84` (the operands written by DrawActor): D = the first chunk page, E = the first buffer line, C = the columns to draw. A sprite whose top is above the window goes to ClipTop `$8BB7`; else SetColumnClip `$8B94` with A = `$50` (the first value of ColumnValues) and L = 0 (no line cut).

Witness: L1 157851 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 387 calls, 59,669 t-states own (0.00 %) |
| Runs (the other recordings) | 19,459 calls (`stage1/rec/menu` 8,558, `stage1/rec/gameover` 4,806, `stage1/rec/deaths` 3,511 and 5 more) |
| Called from | `DrawActor` |
| Calls | `SetColumnClip` (falls into), `ClipTop` (tail), `Multiply8` |
| Reads | `$5D16`-`$6516` (`BuildOutlineMaskLoop+2`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6616` (`WeaponActor+22`); `$6716` (`TitleColours+28`); `$6816` (`TitleColours+284`); `$6916` (`EnemySlots+58`); `$6A16` (`FireHeld+51`); 1 more ranges |
| Writes | `$8B61` (`DrawActorMirrorStep+1`) |

### `SetColumnClip` (`$8B94`)

**Set the first value and the line count of MaskedColumn**

In: A = the low byte of the first value drawn (`$50` + the lines cut at the top), B = rows / 4, L = the lines cut at the top, E = the first buffer line. Writes A into MaskedColumnStart `$8C1D` (`LD SP,ColumnValues+n`), B = rows / 8 (the groups UnpackColumn reads), and the loop count `$8C13` = rows - 2 - L, cut further when the sprite reaches below the window (`$8D27` + `$4A`).

Out: A = rows - 2 - L with its flags, HL = IX (the frame's columns).

Witness: L1 157851 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 387 calls, 69,383 t-states own (0.01 %) |
| Runs (the other recordings) | 19,459 calls (`stage1/rec/menu` 8,558, `stage1/rec/gameover` 4,806, `stage1/rec/deaths` 3,511 and 5 more) |
| Called from | `ClipColumns` (falls into), `ClipTop` |
| Reads | `$8D27` (`PackRowLines+1`) |
| Writes | `$8C13`-`$8C1E` (`MaskedColumnRows+1`, `MaskedColumnStart`) |

### `ClipTop` (`$8BB7`)

**A sprite that starts above the window: cut its top lines**

In: A = the lines above the window - 1 (negative). E = `$4A` (draw from the window's first line), L = the lines cut, A = `$50` + L, then SetColumnClip `$8B94`. When no line is left (`DEC A`, not positive) `POP IY` drops DrawActor's return: the actor is not drawn.

Witness: L1 12268 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 15 calls, 908 t-states own (0.00 %) |
| Runs (the other recordings) | 3,236 calls (`stage1/rec/menu` 1,753, `stage1/rec/gameover` 945, `stage1/rec/deaths` 211 and 5 more) |
| Called from | `ClipColumns` (tail) |
| Calls | `SetColumnClip` |

### `UnpackColumn` (`$8BC5`)

**Unpack one picture column into ColumnValues (`$5B50`)**

DE = `$5B50`, then UnpackGroups `$8BC8`.

Witness: L1 819989 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2,748 calls, 27,499 t-states own (0.00 %) |
| Runs (the other recordings) | 100,115 calls (`stage1/rec/menu` 44,169, `stage1/rec/gameover` 24,025, `stage1/rec/deaths` 15,365 and 5 more) |
| Called from | `MaskedColumns`, `MirroredColumn` |
| Calls | `UnpackGroups` (falls into) |

### `UnpackGroups` (`$8BC8`)

**Unpack B groups of three bytes into eight 3-bit values each**

In: HL = the packed bytes, DE = the output, B = the groups. Eight values a group, most significant bits first: byte 0 bits 7-5, 4-2, bits 1-0 with byte 1 bit 7, byte 1 bits 6-4, 3-1, bit 0 with byte 2 bits 7-6, byte 2 bits 5-3, 2-0. One output byte a value, E increments (no page crossing).

The format of every picture in the game: the tiles (DrawTileColumns `$89D9` calls here with DE = the chunk buffer line, so a tile overwrites the buffer), the sprites (UnpackColumn) and the title letters (the c48 recording reads `$F954-$FD97` through here at the title).

Out: HL = the byte after the groups, DE = the byte after the values.

Witness: L1 4265375 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7,180 calls, 5,812,136 t-states own (0.44 %) |
| Runs (the other recordings) | 146,553 calls (`stage1/rec/menu` 49,318, `stage1/rec/deaths` 38,505, `stage1/rec/gameover` 27,761 and 4 more) |
| Called from | `ComposeTileRows`, `UnpackColumn` (falls into) |
| Reads | `$D104`-`$D8FB` (`Tiles`); `$DA64`-`$DF8B` (`Tiles+2400`); `$E184`-`$E1CB` (`EnemyFrames+48`); `$E394`-`$E49B` (`EnemyFrames+576`); `$EA9C`-`$EC4B` (`HiroFrames+288`); `$EEBC`-`$F707` (`HiroFrames+1344`, `HiroFrames15`, `HiroFrames18`, `HiroFrames21`); 1 more ranges |
| Writes | `$5B68`-`$5BB9` (system); `$5D42`-`$5F79` (`BuildBoxPlaceLoop+14`, `Intro48`, `IntroScene`, `IntroPictureText` and 9 more); `$6042`-`$6079` (`HavokRoomEnter+110`); `$6142`-`$6179` (`SizeClasses+192`); `$6242`-`$6269` (`IntroAttrsB+14`, `IntroAttrsC`); `$6342`-`$6369` (`IntroGlyphs+47`); 2 more ranges |

### `MaskedColumns` (`$8C0A`)

**Draw one sprite column with its outline into the chunk buffer**

In: HL = the column's packed bytes, B = rows / 8, D = the chunk page, E = the first buffer line. UnpackColumn, then MaskedColumn `$8C0F`.

Witness: L1 597066 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x70, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2,272 calls, 102,797 t-states own (0.01 %) |
| Runs (the other recordings) | 92,427 calls (`stage1/rec/menu` 44,169, `stage1/rec/gameover` 23,945, `stage1/rec/deaths` 11,010 and 5 more) |
| Called from | `ComposeTileRows`, `DrawActor` |
| Calls | `UnpackColumn` |
| Reads | `$5D4A`-`$6669` (`BuildBoxPlaceLoop+22`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$674A`-`$6769` (`TitleColours+80`); `$684A`-`$6869` (`TitleColours+336`); `$694A`-`$6969` (`EnemySlots+110`); `$6A4A`-`$6A69` (`FireHeld+103`); `$6B4A`-`$6B69` (`ControlRecords+64`, `ControlGap`, `PageTailTemplate`); 2 more ranges |
| Writes | `$5B7D`-`$5B7E` (system); `$5D4A`-`$6669` (`BuildBoxPlaceLoop+22`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$674A`-`$6769` (`TitleColours+80`); `$684A`-`$6869` (`TitleColours+336`); `$694A`-`$6969` (`EnemySlots+110`); `$6A4A`-`$6A69` (`FireHeld+103`); 3 more ranges |

### `MaskedColumn` (`$8C0F`)

**OR the unpacked column into the buffer with a one-pixel black outline**

Reads the values back from ColumnValues with the stack: `LD SP,$5B50+n`, `POP BC` (C = value k, B = value k + 1), `DEC SP`, so each pop slides one value. The interrupts are off for each `POP` only (DI / EI around it): an interrupt would push onto the values. The caller's SP is kept in the operand `$8C4D`.

Line k of the buffer: buffer AND M[v(k - 1)] AND M[v(k)] AND M[v(k + 1)] OR v(k), with M the table at `$6F00` (FF FC F8 F8 F1 F0 F0 F0: the pixels of the value and those beside them in the unit cleared). The first line leaves M[v(0)] out (A starts at `$FF`), the last has no v(k + 1). So a sprite or a tile from `$4B` gets a black edge above, below and between its pixels, never past its unit's sides.

Entered from MaskedColumns and from MirroredColumn `$8C51` (`JR $8C0F`), both with the column's B and DE pushed. The tiles from `$4B` are drawn here too (`$89C9` -> MaskedColumns).

Out: HL = the next column's packed bytes.

Witness: L1 819986 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 476 calls, 7,869,234 t-states own (0.60 %) |
| Runs (the other recordings) | 7,688 calls (`stage1/rec/deaths` 4,355, `stage1/rec/rooms` 2,494, `stage1/rec/opt2` 253 and 3 more) |
| Called from | `MirroredColumn` (tail) |
| Reads | `$5D42`-`$6669` (`BuildBoxPlaceLoop+14`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$674A`-`$6769` (`TitleColours+80`); `$684A`-`$6869` (`TitleColours+336`); `$694A`-`$6969` (`EnemySlots+110`); `$6A4A`-`$6A69` (`FireHeld+103`); `$6B4A`-`$6B69` (`ControlRecords+64`, `ControlGap`, `PageTailTemplate`); 2 more ranges |
| Writes | `$5B68`-`$5B7E` (system); `$5D42`-`$6669` (`BuildBoxPlaceLoop+14`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$674A`-`$6769` (`TitleColours+80`); `$684A`-`$6869` (`TitleColours+336`); `$694A`-`$6969` (`EnemySlots+110`); `$6A4A`-`$6A69` (`FireHeld+103`); 3 more ranges |

### `MirroredColumn` (`$8C51`)

**Draw one sprite column mirrored left to right**

UnpackColumn, then each value through the table at `$7A00` (0 4 2 6 1 5 3 7: the 3 pixels reversed), in place from the last value down, then MaskedColumn `$8C0F`. DrawActor walks the columns from the right, so the frame is mirrored as a whole.

Witness: L1 222923 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, throw, c x1, opt x3, poke-room x8, rzx x71, rzxroom x17).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 476 calls, 566,621 t-states own (0.04 %) |
| Runs (the other recordings) | 7,688 calls (`stage1/rec/deaths` 4,355, `stage1/rec/rooms` 2,494, `stage1/rec/opt4` 253 and 3 more) |
| Called from | `DrawActor` |
| Calls | `UnpackColumn`, `MaskedColumn` (tail) |
| Reads | `$5B50`-`$5B6F` (system); `$7A00`-`$7A07` (`ReverseCodes`) |
| Writes | `$5B50`-`$5B6F` (system) |

### `BlitWindow` (`$8C68`)

**Copy the composed window from the chunk buffer to the screen**

E = the window top (`$732C`), A = its left (`$732A`), ScreenAddress `$8828` (DE = the screen byte), then BlitWindowAt `$8C72`.

Called by ActorUpdate `$8E2B` after each actor is redrawn and by `$A7B9`.

Witness: L1 112380 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 372 calls, 18,446 t-states own (0.00 %) |
| Runs (the other recordings) | 13,477 calls (`stage1/rec/menu` 5,275, `stage1/rec/deaths` 3,044, `stage1/rec/gameover` 3,008 and 5 more) |
| Called from | `ActorUpdate`, `TitleSequence` |
| Calls | `SpriteScreenAddress` |
| Reads | `$732A`-`$732C` (`DrawColumnPos`, `DrawRowPos`) |

### `BlitWindowAt` (`$8C72`)

**Pack the window's lines and copy them to the screen at DE**

In: DE = the screen address of the window's top-left byte. Entered by `JP $8C72` from `$88D8` (a cell drawn alone).

PackRow `$8CE5` packs every line of the window into the bytes at `$6F08` and returns A = the bytes a line. One byte: the blitter is BlitColumn `$8CD9`. More: BlitRows `$8CAD`, its `JR` into the LDI chain set to copy the bytes - 2 middle bytes. Then for each character row of the window (`$8D27` / 8) the blitter draws 8 lines; DE steps to the next character row (E + `$20`, D back unless the third changed).

Witness: L1 139027 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 420 calls, 343,207 t-states own (0.03 %) |
| Runs (the other recordings) | 2,394 calls (`stage1/rec/deaths` 772, `stage1/rec/rooms` 642, `stage1/rec/menu` 280 and 4 more) |
| Called from | `MaskCellRows` (tail) |
| Calls | `BlitRows`, `BlitColumn`, `PackRow` |
| Reads | `$8D27` (`PackRowLines+1`) |
| Writes | `$8CA0`-`$8CA1` (`BlitWindowCall+1`); `$8CB9` (`BlitRowsJump+1`) |

### `BlitRows` (`$8CAD`)

**Copy 8 packed lines of two or more bytes to the screen under the edge masks**

HL = the packed lines (`$6F08` on), DE = the screen. For each of 8 lines: the first byte = screen AND the left mask (operand `$8CB3`) OR the packed byte, the middle bytes by LDI (C = `$FF` keeps B clear of the LDI count), the last byte = screen AND the right mask (operand `$8CD0`) OR the packed byte; D + 1 to the next line. The masks keep the screen pixels outside the window.

Witness: L1 418215 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2,154 calls, 2,443,228 t-states own (0.18 %) |
| Runs (the other recordings) | 48,178 calls (`stage1/rec/menu` 18,042, `stage1/rec/gameover` 10,557, `stage1/rec/deaths` 9,855 and 5 more) |
| Called from | `BlitWindowAt` |
| Reads | `$4021`-`$51DD` (screen); `$5201`-`$52DD` (screen); `$5301`-`$53DD` (screen); `$5401`-`$54DD` (screen); `$5501`-`$55DD` (screen); `$5601`-`$56DD` (screen); 2 more ranges |
| Writes | `$4021`-`$52DD` (screen); `$5301`-`$53DD` (screen); `$5401`-`$54DD` (screen); `$5501`-`$55DD` (screen); `$5601`-`$56DD` (screen); `$5701`-`$57DD` (screen) |

### `BlitRowsLdiTail` (`$8CC4`)

**The last five LDI of the chain and the right edge**

The second half of the LDI chain of BlitRows (ten LDI in all, so up to 12 bytes a line), then the last byte under the right mask.

Witness: L1 6720 (gameover, havok, hiscore, menu, c x1, rzx x2, rzxroom x1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BlitColumn` (`$8CD9`)

**Copy 8 packed lines of one byte to the screen under both edge masks**

B = 8; for each line: screen AND the mask (operand `$8CDD`: the left mask OR the right mask) OR the packed byte, D + 1.

Witness: L1 8899 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x64, rzxroom x10).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 89 calls, 38,609 t-states own (0.00 %) |
| Runs (the other recordings) | 4,845 calls (`stage1/rec/menu` 2,545, `stage1/rec/gameover` 1,471, `stage1/rec/c48` 235 and 5 more) |
| Called from | `BlitWindowAt` |
| Reads | `$4021`-`$57C1` (screen); `$6F08`-`$6F37` (`OutlineMask+8`) |
| Writes | `$4021`-`$57C1` (screen) |

### `PackRow` (`$8CE5`)

**Pack every line of the window from the chunk buffer into screen bytes at `$6F08`**

In: H = `$5D` (the first chunk page), C = `$4A` (the first line), B = the window width in units, the window's left (`$732A`), the lines (`$8D27`). p = left AND 7 (the unit's place in a 3-byte group of 8 units).

The table PackerPhases `$FD98` gives for p the packer entry (into the CALL at `$8D2C`) and the left mask (into BlitRows `$8CB3`); its record p + B + 7 the address where the packing must stop and the right mask (into `$8CD0`; both masks OR-ed into BlitColumn `$8CDD`). PackRow plants a `RET` (`$C9`) at that stop address, keeps the byte it covered in the operand `$8D42` and its address in `$8D3F`, and puts it back at the end.

For each line: A = 0, CALL the packer (it reads the units across the pages, INC H, and writes whole bytes to BC), the partial last byte to (BC), the next line (L + 1).

Out: A = the bytes a line (BC - the start of the last line); DE as on entry (the screen).

Witness: L1 139027 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 792 calls, 2,657,131 t-states own (0.20 %) |
| Runs (the other recordings) | 15,871 calls (`stage1/rec/menu` 5,555, `stage1/rec/deaths` 3,816, `stage1/rec/gameover` 3,288 and 5 more) |
| Called from | `BlitWindowAt` |
| Calls | `PackUnits0`, `PackUnits1`, `PackUnits2`, `PackUnits3`, `PackUnits4`, `PackUnits5`, `PackUnits6`, `PackUnits7` |
| Reads | `$732A` (`DrawColumnPos`); `$8D49`-`$8DE6` (`PackUnits0+4`, `PackUnits1`, `PackUnits2`, `PackUnits3` and 5 more); `$8DFD` (`PackUnitsStop2`); `$FD98`-`$FDF4` (`PackerPhases`) |
| Writes | `$6F08`-`$6FE7` (`OutlineMask+8`, `TitleWhiteRowsCode`, `PageTail66`); `$8CB3` (`BlitRowsLeftMask+1`); `$8CD0`-`$8CDD` (`BlitRowsRightMask+1`, `BlitColumn`); `$8D2D`-`$8D2E` (`PackRowCall+1`); `$8D3F`-`$8DE6` (`PackRowRestore+1`, `PackUnits0`, `PackUnits1`, `PackUnits2` and 6 more); `$8DFD` (`PackUnitsStop2`) |

### `PackUnits0` (`$8D45`)

**The unrolled packer: 24 units of 3 pixels into 9 bytes; entry for a window starting at unit 0 of a group**

Each `PackUnitsN` entry starts a line at unit N of a 3-byte group (N = the window's left AND 7): unit 0 bits 7-5 of byte 0, 1 bits 4-2, 2 bits 1-0 and bit 7 of byte 1, 3 bits 6-4, 4 bits 3-1, 5 bit 0 and bits 7-6 of byte 2, 6 bits 5-3, 7 bits 2-0. In: HL = the chunk byte of the line in the first unit's page, BC = the output, A = 0 (the bits before the window). Each unit `INC H` to the next page; a full byte goes to (BC). The code runs on for three groups (`$8D45-$8DFD`) until the `RET` PackRow planted after the window's last unit.

The bytes `$8DE6` and `$8DFD` are `INC H` instructions that only a planted `RET` follows.

Witness: L1 753555 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 4,544 calls, 106,140 t-states own (0.01 %) |
| Runs (the other recordings) | 57,560 calls (`stage1/rec/deaths` 21,432, `stage1/rec/rooms` 15,800, `stage1/rec/menu` 8,512 and 5 more) |
| Called from | `PackRow` |
| Calls | `PackUnits1` (falls into) |
| Reads | `$5D4A`-`$5D71` (`BuildBoxPlaceLoop+22`, `Intro48`) |

### `PackUnits1` (`$8D4A`)

**Packer entry: the window starts at unit 1 of a group**

See PackUnits0 `$8D45`. Witness: L1 1158720 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 6,880 calls, 195,387 t-states own (0.01 %) |
| Runs (the other recordings) | 105,440 calls (`stage1/rec/deaths` 30,368, `stage1/rec/menu` 29,920, `stage1/rec/gameover` 19,104 and 5 more) |
| Called from | `PackRow`, `PackUnits0` (falls into) |
| Calls | `PackUnits2` (falls into) |
| Reads | `$5D4A`-`$5D81` (`BuildBoxPlaceLoop+22`, `Intro48`); `$5E4A`-`$5E71` (`IntroBoxSide+11`, `IntroScript`) |

### `PackUnits2` (`$8D50`)

**Packer entry: the window starts at unit 2 of a group**

See PackUnits0 `$8D45`. Witness: L1 1363472 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7,552 calls, 431,686 t-states own (0.03 %) |
| Runs (the other recordings) | 113,936 calls (`stage1/rec/deaths` 36,016, `stage1/rec/menu` 30,240, `stage1/rec/gameover` 19,776 and 5 more) |
| Called from | `PackRow`, `PackUnits1` (falls into) |
| Calls | `PackUnits3` (falls into) |
| Reads | `$5D4A`-`$5D71` (`BuildBoxPlaceLoop+22`, `Intro48`); `$5E4A`-`$5E81` (`IntroBoxSide+11`, `IntroScript`); `$5F4A`-`$5F71` (`IntroScript+253`) |
| Writes | `$6F08`-`$6FE1` (`OutlineMask+8`, `TitleWhiteRowsCode`, `PageTail66`) |

### `PackUnits3` (`$8D5C`)

**Packer entry: the window starts at unit 3 of a group**

See PackUnits0 `$8D45`. Witness: L1 1690190 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9,592 calls, 370,037 t-states own (0.03 %) |
| Runs (the other recordings) | 197,968 calls (`stage1/rec/menu` 71,008, `stage1/rec/deaths` 44,400, `stage1/rec/gameover` 43,248 and 5 more) |
| Called from | `PackRow`, `PackUnits2` (falls into) |
| Calls | `PackUnits4` (falls into) |
| Reads | `$5D4A`-`$5D79` (`BuildBoxPlaceLoop+22`, `Intro48`); `$5E4A`-`$5E71` (`IntroBoxSide+11`, `IntroScript`); `$5F4A`-`$5F71` (`IntroScript+253`); `$604A`-`$6071` (`HavokRoomEnter+118`) |
| Writes | `$69E0` (`MapColumn`) |

### `PackUnits4` (`$8D64`)

**Packer entry: the window starts at unit 4 of a group**

See PackUnits0 `$8D45`. Witness: L1 1838814 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 11,424 calls, 295,556 t-states own (0.02 %) |
| Runs (the other recordings) | 209,480 calls (`stage1/rec/menu` 78,000, `stage1/rec/gameover` 45,608, `stage1/rec/deaths` 43,736 and 5 more) |
| Called from | `PackRow`, `PackUnits3` (falls into) |
| Calls | `PackUnits5` (falls into) |
| Reads | `$5D4A`-`$5D71` (`BuildBoxPlaceLoop+22`, `Intro48`); `$5E4A`-`$5E79` (`IntroBoxSide+11`, `IntroScript`); `$5F4A`-`$5F71` (`IntroScript+253`); `$604A`-`$6071` (`HavokRoomEnter+118`); `$614A`-`$6171` (`SizeClasses+200`) |

### `PackUnits5` (`$8D69`)

**Packer entry: the window starts at unit 5 of a group**

See PackUnits0 `$8D45`. Witness: L1 1847488 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9,464 calls, 701,740 t-states own (0.05 %) |
| Runs (the other recordings) | 244,504 calls (`stage1/rec/menu` 98,648, `stage1/rec/gameover` 56,400, `stage1/rec/deaths` 42,056 and 5 more) |
| Called from | `PackRow`, `PackUnits4` (falls into) |
| Calls | `PackUnits6` (falls into) |
| Reads | `$5D4A`-`$5D79` (`BuildBoxPlaceLoop+22`, `Intro48`); `$5E4A`-`$5E71` (`IntroBoxSide+11`, `IntroScript`); `$5F4A`-`$5F79` (`IntroScript+253`); `$604A`-`$6071` (`HavokRoomEnter+118`); `$614A`-`$6171` (`SizeClasses+200`); `$624A`-`$6269` (`IntroAttrsC+7`) |
| Writes | `$6F08`-`$6FE2` (`OutlineMask+8`, `TitleWhiteRowsCode`, `PageTail66`) |

### `PackUnits6` (`$8D79`)

**Packer entry: the window starts at unit 6 of a group**

See PackUnits0 `$8D45`. Witness: L1 1883375 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9,320 calls, 295,562 t-states own (0.02 %) |
| Runs (the other recordings) | 263,208 calls (`stage1/rec/menu` 110,128, `stage1/rec/gameover` 62,392, `stage1/rec/deaths` 41,472 and 5 more) |
| Called from | `PackRow`, `PackUnits5` (falls into) |
| Calls | `PackUnits7` (falls into) |
| Reads | `$5D4A`-`$5D79` (`BuildBoxPlaceLoop+22`, `Intro48`); `$5E4A`-`$5E79` (`IntroBoxSide+11`, `IntroScript`); `$5F4A`-`$5F71` (`IntroScript+253`); `$604A`-`$6079` (`HavokRoomEnter+118`); `$614A`-`$6171` (`SizeClasses+200`); `$624A`-`$6269` (`IntroAttrsC+7`); 1 more ranges |

### `PackUnits7` (`$8D80`)

**Packer entry: the window starts at unit 7 of a group; then the second and third groups**

See PackUnits0 `$8D45`. Unit 7 completes byte 2 of the group (`OR (HL)`); the code goes on with the next two groups (`$8D84`, `$8DC3`), the same pattern.

Witness: L1 1900321 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9,904 calls, 732,584 t-states own (0.06 %) |
| Runs (the other recordings) | 260,400 calls (`stage1/rec/menu` 107,480, `stage1/rec/gameover` 60,736, `stage1/rec/deaths` 41,112 and 5 more) |
| Called from | `PackRow`, `PackUnits6` (falls into) |
| Reads | `$5D4A`-`$5E79` (`BuildBoxPlaceLoop+22`, `Intro48`, `IntroScene`, `IntroPictureText` and 9 more); `$5F4A`-`$6079` (`IntroScript+253`, `SetTune`, `HavokRoomLeave`, `HavokRoomEnter`); `$614A`-`$6179` (`SizeClasses+200`); `$624A`-`$6279` (`IntroAttrsC+7`); `$634A`-`$6379` (`IntroGlyphs+55`); `$644A`-`$6479` (`IntroGlyphs+311`); 8 more ranges |
| Writes | `$6F08`-`$6FE6` (`OutlineMask+8`, `TitleWhiteRowsCode`, `PageTail66`) |

### `PackUnitsTail` (`$8DE7`)

**The third group, units 5-7**

The end of the unrolled packer, reached by falling through when the stop lies further on (`$8DFD`): the widest windows, only at the menu and the game over in the stage 1 recordings. See PackUnits0 `$8D45`.

Witness: L1 2240 (gameover, havok, hiscore, menu, c x1, rzx x2, rzxroom x1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ActorBoxStore` (`$8F3B`)

**The actor's screen box at rest: +`$2A-$2F` and the clip bits in +`$20`**

IY = the actor. ActorScreenBox `$8F75` (the box with the last move, into the render's variables), then the box of the actor where it stands now (DE = 0): BoxColumns `$8FDD` on X gives +`$2E` (columns), +`$2A` (first) and +`$2B` (last column, 3-pixel units 0-79); BoxRows `$9000` on Y gives +`$2F` (rows), +`$2C` (first) and +`$2D` (last row, 8-pixel rows 0-21); the clip bits go to +`$20` bits 4-7 (bits 0-3 kept). Then `$74BA` (the row-pattern pointer the render reads at `$8922`) = `$5D4A`, or `$5D42` when the first row `$732C` is odd.

Callers: ActorUpdate `$8E3A` (after every move that needs a redraw), `$A73E`.

Witness: L1 114102 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 372 calls, 106,474 t-states own (0.01 %) |
| Runs (the other recordings) | 13,481 calls (`stage1/rec/menu` 5,275, `stage1/rec/deaths` 3,044, `stage1/rec/gameover` 3,008 and 5 more) |
| Called from | `ActorUpdate`, `TitleSequence` |
| Calls | `ActorScreenBox`, `BoxColumns`, `BoxRows` |
| Reads | `$5D00`-`$6520` (`Hiro`, `BuildPageTails`, `Intro48`, `IntroScene` and 24 more); `$6600`-`$6601` (`WeaponActor`); `$6620` (`WeaponActor+32`); `$6700`-`$6701` (`TitleColours+6`); `$6720` (`TitleColours+38`); `$6800`-`$6801` (`TitleColours+262`); 8 more ranges |
| Writes | `$5D20`-`$652F` (`BuildOutlineMaskLoop+12`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6620`-`$662F` (`WeaponActor+32`); `$6720`-`$672F` (`TitleColours+38`); `$6820`-`$682F` (`TitleColours+294`); `$6920`-`$692F` (`EnemySlots+68`); `$6A20`-`$6A2F` (`FireHeld+61`); 2 more ranges |

### `ActorScreenBox` (`$8F75`)

**The box the actor's redraw covers, the old place included: the render's variables**

IY = the actor; HL = IY on return. The box spans the last step: the X start is X less the X step +`$22` when that was to the right, the width grows by its size, and the Y start is Y less +`$21` (a quarter of the last Y step). BoxColumns `$8FDD` gives the columns: count to `$8C76`, first and last to `$732A`/`$732B`; the first row line (Y AND `$F8`, 0 when `$C8` or more) to the operand `$8B15`; BoxRows `$9000` gives the rows: count x 8 (pixel lines) to `$8D27`, first and last to `$732C`/`$732D`; the clip bits to `$69DD`; the first and last cell (RowBase `$7000`[first row / 2] + column / 4) to `$A56E`/`$A56F`; the number of 16-pixel rows to `$69DE`.

Callers: ActorBoxStore `$8F3B`, `$955A` (the room change), `$A41E`.

Witness: L1 156241 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 608 calls, 305,900 t-states own (0.02 %) |
| Runs (the other recordings) | 15,601 calls (`stage1/rec/menu` 5,364, `stage1/rec/deaths` 3,994, `stage1/rec/gameover` 3,153 and 5 more) |
| Called from | `ActorBoxStore`, `CheckRoomExit`, `SetupRoomObjects` |
| Calls | `BoxColumns`, `BoxRows` |
| Reads | `$5D00`-`$6501` (`Hiro`, `BuildPageTails`, `Intro48`, `IntroScene` and 24 more); `$6521`-`$6522` (`ActorPage9+33`); `$6600`-`$6601` (`WeaponActor`); `$6621`-`$6622` (`WeaponActor+33`); `$6700`-`$6701` (`TitleColours+6`); `$6721`-`$6722` (`TitleColours+39`); 9 more ranges |
| Writes | `$69DD`-`$69DE` (`BoxClip`); `$732A`-`$732D` (`DrawColumnPos`, `DrawRowPos`); `$8B15` (`DrawActorTop+1`); `$8C76` (`BlitWindowWidth+2`); `$8D27` (`PackRowLines+1`); `$A56E`-`$A56F` (`RevealZone+5`) |

### `BoxColumns` (`$8FDD`)

**The box's columns from X = A, step D: C = first, B = last (3-pixel units), A = count**

L = X, (IY... HL) the actor page for +`$15` (width in pixels). C = X / 2, or 0 with clip bit 7 when that is `$4F` or more (past the right edge); B = (X + |D| + width) / 2 - 1, or `$4F` with clip bit 6 when `$50` or more. Falls into BoxSpan `$901F` (A = B + 1 - C).

Callers: ActorBoxStore `$8F3B`, ActorScreenBox `$8F75`.

Witness: L1 270343 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 980 calls, 102,180 t-states own (0.01 %) |
| Runs (the other recordings) | 29,082 calls (`stage1/rec/menu` 10,639, `stage1/rec/deaths` 7,038, `stage1/rec/gameover` 6,161 and 5 more) |
| Called from | `ActorBoxStore`, `ActorScreenBox` |
| Calls | `BoxSpan` (tail) |
| Reads | `$5D15`-`$6515` (`BuildOutlineMaskLoop+1`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6615` (`WeaponActor+21`); `$6715` (`TitleColours+27`); `$6815` (`TitleColours+283`); `$6915` (`EnemySlots+57`); `$6A15` (`FireHeld+50`); 1 more ranges |

### `BoxRows` (`$9000`)

**The box's rows from Y = A (8-pixel rows): C = first, B = last, A = count**

C = Y / 8, or 0 with clip bit 5 when that is `$15` or more (Y wrapped above the window); B = (Y + height +`$16` - 1) / 8, or `$15` with clip bit 4 when `$16` or more. Falls into BoxSpan `$901F`. Callers: ActorBoxStore `$8F3B`, ActorScreenBox `$8F75`.

Witness: L1 270343 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 980 calls, 100,646 t-states own (0.01 %) |
| Runs (the other recordings) | 29,082 calls (`stage1/rec/menu` 10,639, `stage1/rec/deaths` 7,038, `stage1/rec/gameover` 6,161 and 5 more) |
| Called from | `ActorBoxStore`, `ActorScreenBox` |
| Calls | `BoxSpan` (falls into) |
| Reads | `$5D16`-`$6516` (`BuildOutlineMaskLoop+2`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6616` (`WeaponActor+22`); `$6716` (`TitleColours+28`); `$6816` (`TitleColours+284`); `$6916` (`EnemySlots+58`); `$6A16` (`FireHeld+51`); 1 more ranges |

### `BoxSpan` (`$901F`)

**B = A (the last), A = B + 1 - C (the count)**

The common tail of BoxColumns `$8FDD` and BoxRows `$9000`.

Witness: L1 540685 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,960 calls, 45,639 t-states own (0.00 %) |
| Runs (the other recordings) | 58,163 calls (`stage1/rec/menu` 21,278, `stage1/rec/deaths` 14,076, `stage1/rec/gameover` 12,322 and 5 more) |
| Called from | `BoxColumns` (tail), `BoxRows` (falls into) |

## sound

`src/game/sound.asm`

### `EffectPlayer` (`$853F`)

**The 48K sound, every frame: step the effect, copy its level to `$9BA3`**

Calls EffectFrame, then `$9BA3` (the operand of `$9BA2` LD A,n) = the current level (the operand at `$85CA`): `$9BA2` lets the footstep effect 7 start only while no effect sounds. On a 128K the bootstrap overwrites `$853F-$85E0` with the 162-byte glue to the AY player in bank 4 (AyGlue): the 48K bytes from `$85E1` and the table EffectTable stay but are not run.

Witness: L1 222542 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19). The 128K recordings' runs at `$853F-$85E0` are the glue's; the 48K player runs in c48 and the RZX builds.

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2,614 calls, 305,838 t-states own (0.02 %) |
| Runs (the other recordings) | 49,277 calls (`stage1/rec/menu` 18,055, `stage1/rec/gameover` 9,844, `stage1/rec/deaths` 7,824 and 5 more) |
| Called from | `InterruptHandler` |
| Calls | `EffectFrame`, `EffectState` |
| Reads | `$8450` (`SoundVars`) |
| Writes | `$9BA3` (`FootstepSound+1`) |
| Ports out | `$7FFD` |

### `EffectFrame` (`$8549`)

**Start a requested effect (EffectRequest not `$FF`), else sound the current one**

HL = EffectRequest, A = the request, the request back to `$FF`: `$FF` goes to EffectSound `$8634`, else StartEffect `$855B` (no sound that frame).

Witness: L1 222542 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,614 calls (`stage1/rec/c48` 2,614) |
| Called from | `EffectPlayer` |
| Calls | `EffectSound` (tail) |

### `StartEffect` (`$855B`)

**Start effect A: copy its 12-byte record's counters, set the mixer, the sweep start and the attack**

HL = EffectTable + 12 A (kept in the LD IY,n operand at `$863C`); the first 3 bytes to EffectTime, SweepDelay, SweepCount; EffectMixer OR 9, with bit 0 cleared when the record's +3 bit 0 is set (tone) and bit 3 when +3 bit 1 (noise). The sweep offset (`$8648`) = 0; DE = the sweep step (+4 high, +5 low); HL = DE x (+2) / 2 (shift-and-add over bits 4-0 of the period, the last half step by SRA D / RR E), negated into the LD HL,n operand at `$862E`: the sweep's restart value. The envelope state (the JR offset at `$85CC`) = 9: the attack. The level (`$85CA`) is not cleared: a new effect attacks from the level the old one left.

Witness: L1 62138 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19). 128K runs here are the glue's.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SweepSpanHalf` (`$859E`)

**The last half step of the span (DE / 2), then the negation (an entry only because the 128K glue's `$859E` hook lies here)**

Witness: L1 13167 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19). 128K runs here are the glue's.

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 19 calls, 1,112 t-states own (0.00 %) |
| Runs (the other recordings) | 7,533 calls (`stage1/rec/menu` 4,801, `stage1/rec/gameover` 2,656, `stage1/rec/opt2` 19 and 3 more) |
| Called from | `ShowHighScores`, `TitleSequence` |
| Calls | `DecodeDirection`, `ReadInput`, `SetEnvelopeState` (falls into), `EnvelopeTimeFF` (tail) |
| Writes | `$8455` (`SoundMode`) |

### `SetEnvelopeState` (`$85B2`)

**Store A as the envelope state (the JR offset at `$85CC`: 0 sustain, 9 attack, `$16` decay, `$2B` release)**

Witness: L1 8022 (bossgate, havok, play48, c x1, poke-room x15, rzx x71, rzxroom x19). 128K runs here are the glue's.

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 65 t-states own (0.00 %) |
| Runs (the other recordings) | 39 calls (`stage1/rec/c48` 39) |
| Called from | `SweepSpanHalf` (falls into), `EnvelopeTimeCount` (tail), `TitleSequence` |
| Reads | `$8455` (`SoundMode`) |

### `EffectEnvelope` (`$85B6`)

**One frame of the effect: the duration, the sweep, then the envelope step (attack, decay, sustain, release)**

A = EffectMixer: both channels off returns at once. EffectTime counted down unless 0 or `$FF`; EffectSweep; A = the level (LD A,n, operand `$85CA`); JR n (operand `$85CC`) to the state: attack `$85D6` adds +7 until +11 (the peak), then decay; decay `$85E3` adds +8 (negative) down to +9 (the sustain level); sustain `$85CD` holds until EffectTime is 0, then release; release `$85F8` adds +10 (negative) and at a negative level sets EffectMixer OR 9 (idle when the other bits are set) with the level 0.

Witness: L1 106023 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 458 calls (`stage1/rec/c48` 458) |
| Called from | `EffectSound` |
| Calls | `PrintString`, `EnvelopeTimeFF` (falls into) |

### `EnvelopeTimeFF` (`$85C3`)

**EffectTime `$FF`: no count-down (an entry only because the 128K glue's code starts here)**

Witness: L1 74157 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19). 128K runs here are the glue's.

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 19 calls, 322 t-states own (0.00 %) |
| Runs (the other recordings) | 7,560 calls (`stage1/rec/menu` 4,817, `stage1/rec/gameover` 2,664, `stage1/rec/opt2` 20 and 3 more) |
| Called from | `SweepSpanHalf` (tail), `EffectEnvelope` (falls into) |

### `EnvelopeTimeCount` (`$85C5`)

**EffectTime - 1 (an entry because the glue's `$85C5` hook lies here)**

Witness: L1 65807 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19). 128K runs here are the glue's.

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 127 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/menu` 2, `stage1/rec/gameover` 2, `stage1/rec/opt3` 1 and 3 more) |
| Called from | `MatchCheatName` |
| Calls | `SetEnvelopeState` (tail), `EffectSweep` |
| Writes | `$8450` (`SoundVars`) |
| Ports out | `$7FFD` |

### `EffectSweep` (`$8609`)

**The pitch sweep: after SweepDelay frames add the step (+4, +5) to the offset (`$8648`) each frame, restart every +2 frames**

SweepDelay 0: sweep now; `$FF`: never; else count down and, at 0, restart (SweepRestart) and sweep. The offset += the step; SweepCount - 1, at 0 reloaded from +2 (0: never) and the offset back to -(step x period / 2): a saw-tooth around the record's pitch.

Witness: L1 105058 (bossgate, havok, play48, c x1, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 458 calls (`stage1/rec/c48` 458) |
| Called from | `EnvelopeTimeCount` |

### `SweepRestart` (`$862D`)

**The sweep offset = the start value (LD HL,n, operand `$862E`, set by StartEffect)**

Witness: L1 11983 (bossgate, havok, play48, poke-room x15, rzx x72, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EffectSound` (`$8634`)

**Sound one frame of the effect on the beeper: a burst of C toggles at a carrier set by the pitch**

Idle (`$855A` = `$3F`) returns. IY = the record (LD IY,n, set by StartEffect); EffectEnvelope; L = +6 (the pitch) + the sweep offset (LD BC,n at `$8647`), only the low byte kept: PitchToDelay sets the DJNZ count B (bits 5-7, made odd: 1, 3, 5, 7); LevelToBurst sets C = ((level / 2) AND `$7C`) OR 4 (4-60 toggles). OUT (`$FE`),`$18`, then C times: B = n, XOR `$10`, OUT, DJNZ: 47 + 13 (B - 1) T a half cycle (47, 73, 99, 125 T: 37, 24, 18, 14 kHz); OUT (`$FE`),`$08`. A burst lasts at most 60 x 125 = 7500 T (11 % of a frame). On the speaker that is a 50 Hz buzz whose loudness follows the envelope: the pitch only picks one of four ultrasonic carriers.

Witness: L1 160413 (bossgate, havok, play48, c x1, poke-room x15, rzx x72, rzxroom x19).

[Animation: `EffectSound` at work](img/routines/EffectSound.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,576 calls (`stage1/rec/c48` 2,576) |
| Called from | `EffectFrame` (tail) |
| Calls | `EffectEnvelope`, `LevelToBurst`, `PitchToDelay` |
| Ports out | `$08FE`, `$18FE` |

### `LevelToBurst` (`$866D`)

**The burst length C (the operand at `$865B`) from the level A: ((A / 2) AND `$7C`) OR 4**

Witness: L1 105058 (bossgate, havok, play48, c x1, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 458 calls (`stage1/rec/c48` 458) |
| Called from | `EffectSound` |

### `PitchToDelay` (`$8676`)

**The DJNZ count (the operand at `$865D`) from the pitch byte A: bits 5-7, OR 1**

Witness: L1 105058 (bossgate, havok, play48, c x1, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 458 calls (`stage1/rec/c48` 458) |
| Called from | `EffectSound` |

## ending

`src/game/ending.asm`

### `HavokFade` (`$872B`)

**The end picture's actor: draw it, and once its timer has run out fade it, then the end text**

IY = the actor. While +`$10` bit 5 (its 16-bit timer, GameTick) is clear: DrawHavok. Then each pass the mask (the AND n operand at `$878F`, `$FF` at the start) - 1, effect 4 every 16 steps, DrawHavok with the mask; at 0: the actor off (+2 = 0), DelayBC 65 536, CALL `$9962`, `$6652` bit 6 set (fire now ends the game, GameTick), EndText printed. Returns with POP BC / POP HL / RET (out of the actor dispatch `$8E2B`).

Witness: L1 825 (havok, rzx x2): havok kills Havok with his hit points POKEd to 1 at frame 20.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrawHavok` (`$8769`)

**Draw the 48 x 80 picture from `$7F23` (or `$7F3B` when Y AND 7 = 0) at the actor's place, ANDed with the fade mask**

E = +`$2C`, A = +`$2A`: SpriteScreenAddress; ShiftHavokGraphic; 10 character rows of 8 lines of 6 bytes, each byte AND the mask at `$878F`.

Witness: L1 825 (havok, rzx x2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ShiftHavokGraphic` (`$87A6`)

**Rotate HavokPicture's 384 bytes left or right by the change of the actor's pixel phase**

The phase (3 x +`$2A`) AND 7 against the last one (the operand at `$87AC`): left by RL from `$80FC` down, right by RR from `$7F7D` up, one pass a pixel; DE back to the column (L / 8 added).

Witness: L1 825 (havok, rzx x2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## player

`src/game/player.asm`

### `RoomBarrier` (`$8F01`)

**Hiro meets an invisible wall: stop his X step (D = 0) at the room's barrier X**

From MoveActor `$9B56` for Hiro only, D = his X step. BarrierFind `$8F28` looks the room `$6BDD` up in BarrierRooms `$76D2` (6 bytes: rooms `$7B` (123, Havok), `$5D`, `$3A`, 8, `$27`, and `$88`, which is no room) and returns if it is not there. With the room's flag (`$76D8`+i) bit 0 set, the barrier X (`$76DE`+i: `$34`, `$28`, `$30`, `$48`, `$88`, `$88`) and side (`$76E4`+i: 0, 0, 0, 1, 1, 1) apply: side 0 stops Hiro facing left, side 1 facing right (+`$1B` of `$5D00`, `$5D1B`), when his X (`$5D01`) equals the barrier X. BarrierOpen `$8F22` clears the flag.

Witness: the RZX run's snapshot at frame 80 000 has the flags of rooms `$3A` and `$27` cleared (`work/stage2/rzx/snap-080000.z80`); deaths runs the test 95 times (in one of the rooms). Witness: L1 40810 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 232 calls, 4,001 t-states own (0.00 %) |
| Runs (the other recordings) | 2,062 calls (`stage1/rec/deaths` 935, `stage1/rec/rooms` 561, `stage1/rec/gameover` 141 and 4 more) |
| Called from | `ApplyMove` |
| Calls | `BarrierFind` |
| Reads | `$5D01` (`Hiro+1`); `$5D1B` (`BuildOutlineMaskLoop+7`); `$76DB`-`$76E7` (`GateClosed+3`, `GateX`, `GateSide`) |

### `BarrierOpen` (`$8F22`)

**Clear the current room's barrier flag (the wall goes away)**

BarrierFind `$8F28` (returns at once if the room has none), then (HL) = 0. Caller: `$97A8` (the routine at `$97A3`, outside this range). bossgate opens a giant's gate at frame 435 (its hit points POKEd to 1).

Witness: L1 1 (bossgate).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BarrierFind` (`$8F28`)

**HL = the barrier flag of room `$6BDD`; returns from the caller too when the room has none**

CPIR over the six rooms at BarrierRooms `$76D2`; found: HL = the match + 6 (`$76D8`+i, the flag) with BC = 5 and B = 0. Not found: `POP HL` drops the return address, so the `RET` leaves RoomBarrier `$8F01` or BarrierOpen `$8F22` as well.

Witness: L1 40811 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 232 calls, 44,590 t-states own (0.00 %) |
| Runs (the other recordings) | 2,062 calls (`stage1/rec/deaths` 935, `stage1/rec/rooms` 561, `stage1/rec/gameover` 141 and 4 more) |
| Called from | `RoomBarrier` |
| Reads | `$6BDD` (`Room`); `$76D2`-`$76D7` (`GateRooms`) |

### `ActorJump` (`$9023`)

**Up pressed: grab a ladder above, or start a jump (sequence +`$30`)**

From WalkStep `$9B05` when the Y step E is negative (Hiro's up; the enemies' walks never step up). HL = IY = the actor, D = the X step.

Standing (D = 0): `$9CA7` tests the cell 20 above (one row up) against the two ladder codes at `$73C5` (`$55`, `$54`) with X at a multiple of 8; a ladder goes to GrabLadder `$906C`. Otherwise the jump script: `$7B00` straight up (11 steps), `$7A51` running (12 steps), `$7A7A` when the run counter +`$24` is 4 or more (16 steps, the long jump); SequenceHeader `$919C` with L = `$30`, then the first step JumpStep `$9225`.

Witness: L1 885 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x64, rzxroom x9).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 220 t-states own (0.00 %) |
| Runs (the other recordings) | 49 calls (`stage1/rec/deaths` 31, `stage1/rec/rooms` 9, `stage1/rec/gameover` 3 and 3 more) |
| Called from | `MoveActor` (tail) |
| Calls | `SequenceHeader`, `JumpMove` (tail), `LadderAbove` |
| Reads | `$5D24` (`BuildOutlineMaskLoop+16`) |

### `FallSequenceStart` (`$904A`)

**+`$10` bit 4 (nothing below): the fall sequence +`$31`, or Hiro hanging climbs up**

From StepActor `$9AD3`. Hiro: script low byte from `$69DC` (`$18`, set by `$9878`), E = 4; when he hangs (+`$02` bit 3) LeaveLadder `$9078` instead. Other actors: the low byte from +`$08`. The page is +`$06`. SequenceHeader `$919C` with L = `$31`, then FallScriptStep `$9240`.

Two entry points: GrabLadder `$906C` (from ActorJump `$902B` and `$9B1D`): +`$02` bit 3 (hanging), script `$7AAF` (2 frames) in sequence +`$36`; LeaveLadder `$9078` (here and `$9C9E`): bit 3 cleared, X + 2, script `$7AE8` in the pose sequence +`$32`.

Witness: L1 797 (deaths, play48, rooms, rzx x58, rzxroom x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 27 calls (`stage1/rec/deaths` 22, `stage1/rec/rooms` 5) |
| Called from | `StepActor` (tail) |
| Calls | `SequenceHeader`, `FallMove` (tail) |
| Reads | `$5D02`-`$5D06` (`Hiro+2`); `$69DC` (`HiroFallScript`) |

### `TurnToHiro` (`$9087`)

**The hold count +`$28` ran out: face Hiro and play the +`$0E` script (sequence +`$32`)**

From StepActor `$9AB0` when +`$28` reaches 0 and +`$0E` is not 0. Direction +`$1B` = 2 when Hiro's X (`$5D2A` x 2, his box's first column) is at or right of the actor, else `$FE`; sound `$09` (`$8454`); the script `$7600` + +`$0E` in sequence +`$32` (StartPoseSeq `$90A1`).

Witness: L1 242 (bossgate, rooms, poke-room x6, rzx x53, rzxroom x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rec/rooms` 3) |
| Called from | `StepActor` (tail) |
| Calls | `StartPoseSeq` (falls into) |
| Reads | `$5D2A` (`BuildRowBaseLoop+4`); `$5E01`-`$5E0E` (`IntroBox+6`); `$5F01`-`$5F0E` (`IntroScript+180`) |
| Writes | `$5E1B` (`IntroBoxSides+1`); `$5F1B` (`IntroScript+206`); `$8454` (`EffectRequest`) |

### `StartPoseSeq` (`$90A1`)

**Start a script BC in the pose sequence +`$32` (landing, climbing, turning to Hiro, the shake)**

L = `$32`, StartSequence `$917E`. Callers: LeaveLadder `$9078`, TurnToHiro `$9087`, HiroLanded `$90C3`, StalactiteShake `$9112`.

Entry StartHurtSeq `$90A6` (from StepActor `$9ADD` when +`$10` bit 2 is set: Hiro touched the actor, `$9851`): the script +`$06`/+`$09` in the action sequence +`$34`.

Witness: L1 1308 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x6, rzx x69, rzxroom x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 17 calls (`stage1/rec/rooms` 17) |
| Called from | `TurnToHiro` (falls into), `HiroLanded` (tail) |
| Calls | `StartSequence` (tail) |

### `StartTurn` (`$90B1`)

**Reverse: the turn script +`$06`/+`$07` in sequence +`$33`, the run counters cleared**

From WalkStep `$9B0C` when the wanted X step has the other sign than +`$1B`. Clears +`$24` and +`$25`, then StartSequence `$917E` with L = `$33`; TurnStep `$91E1` flips +`$1B` halfway.

Witness: L1 1275 (bossgate, deaths, gameover, hiscore, play48, rooms, throw, c x1, opt x3, poke-room x2, rzx x69, rzxroom x11).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 4 calls, 316 t-states own (0.00 %) |
| Runs (the other recordings) | 116 calls (`stage1/rec/deaths` 91, `stage1/rec/rooms` 19, `stage1/rec/gameover` 3 and 3 more) |
| Called from | `MoveActor` (tail) |
| Calls | `StartSequence` (tail) |
| Reads | `$5D06`-`$5D07` (`Hiro+6`, `BuildPageTails`); `$5E06`-`$5E07` (`IntroBox+11`); `$5F06`-`$5F07` (`IntroScript+185`) |
| Writes | `$5D24`-`$5D25` (`BuildOutlineMaskLoop+16`); `$5E24`-`$5E25` (`IntroBoxSides+10`); `$5F24`-`$5F25` (`IntroScript+215`) |

### `HiroLanded` (`$90C3`)

**Hiro lands: a crouch, or fall damage when he fell 20 steps or more**

From `$9D3B` (a falling actor of kind `$24` finds the floor). +`$26` (the fall steps, counted by `$9CE8`) is read and cleared. 0: return (Z). 1-19: the caller's return is dropped and the landing script `$7AB6` (1 frame) plays in +`$32`. 20 or more: the damage count = steps - 17, at most 14; sound 1; the script `$7ABC` (speed byte, frames `$31`/`$32`) in sequence +`$35` with that count (StartSequenceCount `$9180`): FallDamageStep `$920A` takes 2 energy each step (so 6 to 28 energy; full energy is `$20`).

Witness: 157 landings in the keyed recordings, two of them hard (`$90CC` once in deaths, once in `play48`: 32 fall steps, 14 damage steps from frame 3016). Witness: L1 3091 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x16).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9 calls, 673 t-states own (0.00 %) |
| Runs (the other recordings) | 148 calls (`stage1/rec/deaths` 71, `stage1/rec/rooms` 42, `stage1/rec/opt4` 8 and 4 more) |
| Called from | `ProbeFloorCell` (tail) |
| Calls | `StartPoseSeq` (tail), `StartSequenceCount` (tail) |
| Reads | `$5D26` (`BuildRowBaseLoop`) |
| Writes | `$5D26` (`BuildRowBaseLoop`); `$8454` (`EffectRequest`) |

### `HiroMelee` (`$90EC`)

**Fire without a weapon: the strike `$6650` (1-3) in the action sequence +`$34`**

From HiroAttack `$9276` (`$664B` = 0). L = the strike (the fire key's hold time, set by the tick `$84FB`: under 9 frames 1, under 25 frames 2, else 3): 1 script `$7A46` (6 frames), 2 `$7ACE` (8), 3 `$7ADB` (8). +`$02` bit 4 arms the hit test (ActionStep `$91F4` calls `$9DCA` every step: blocks and enemies in reach, `$69E1` 3 reaches further).

Entry StartActionSeq `$9104` (also from HiroAttack after a throw): `$6650` = 0 (the request taken), sound `$0A`, the script in sequence +`$34`. The `$0B` stored to `$8454` at `$90FD` is overwritten by the `$0A` at `$910A` before anything reads it, so effect 11 is never heard from a strike; its only audible source is TitleMovePiece `$A775` (a title piece arrives).

Witness: L1 409 (bossgate, havok, menu, play48, c x1, opt x3, poke-room x15, rzx x56, rzxroom x8).

[Animation: `HiroMelee` at work](img/routines/HiroMelee.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 291 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/opt2` 1, `stage1/rec/opt3` 1, `stage1/rec/opt4` 1 and 1 more) |
| Called from | `HiroAttack` (tail) |
| Calls | `StartSequence` (tail) |
| Reads | `$5D02` (`Hiro+2`) |
| Writes | `$5D02` (`Hiro+2`); `$6650` (`FireRequest`); `$8454` (`EffectRequest`) |

### `DeathLeavesBonus` (`$911A`)

**The death script ended with +`$39` set: the actor becomes a bonus that rises 32 pixels**

From DeathStep `$91BC`, HL at +`$39`. +`$39` = 0; +`$02` bit 7 (drawn on top) set, bit 5 cleared; frame +`$23` = the old +`$39` - 1; MarkSpawnKilled `$9137`; +`$0F` = `$5D`; the header of `$7B5D` (8 steps, speed 4) in sequence +`$38`, then RiseStep `$91DB` (4 pixels up a step).

Witness: deaths 1 run. Witness: L1 16 (deaths, play48, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/deaths` 1) |
| Called from | `DeathStep` (tail) |
| Calls | `MarkSpawnKilled`, `SequenceHeader`, `RiseMove` (tail) |
| Reads | `$5F02` (`IntroScript+181`) |
| Writes | `$5F02`-`$5F0F` (`IntroScript+181`); `$5F23` (`IntroScript+214`); `$5F39` (`IntroScript+236`) |

### `MarkSpawnKilled` (`$9137`)

**The actor's room spawn slot +`$29` is set in the room's kill mask `$6EFE` (not respawned)**

+`$29` (1-based slot in the room's spawn list, 0 none) is read and cleared; bit (`$6ADD` - slot) of the 16-bit mask at `$6EFE`/`$6EFF` (first byte the high bits) is set: the room spawner `$A59E` skips the slots whose bit is set. Callers: DeathLeavesBonus `$911A`, DeathStep `$91CE`.

Entry DieOnLanding `$9159` (from `$9D44`: kinds `$20-$22` land): the caller's return is dropped, +`$0F` = `$37` (the death script `$7B37`) and +`$10` bit 5 (ActorExpired runs it).

Witness: L1 638 (bossgate, deaths, havok, play48, throw, rzx x67, rzxroom x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/deaths` 5) |
| Called from | `DeathLeavesBonus`, `DeathStep` |
| Reads | `$5F29` (`IntroScript+220`); `$6529` (`ActorPage9+41`); `$6ADD` (`EnemyCount`); `$6EFE`-`$6EFF` (`GoneEnemies`) |
| Writes | `$5F29` (`IntroScript+220`); `$6EFE`-`$6EFF` (`GoneEnemies`) |

### `ActorExpired` (`$9163`)

**+`$10` bit 5 (timer run out, or killed): the death script `$7B00` + +`$0F` in sequence +`$37`**

From StepActor `$9AD8`. Kind `$25` (Havok) only moves on (MoveActor `$9B56`, his end is `$872B`). +`$0F` = `$58` (the bonus pick-up's script) sets +`$02` bit 5 at once. The death script `$7B00` + +`$0F` (Hiro: `$7B26`) in sequence +`$37`; DeathStep `$91A9` ends it.

Witness: L1 1691 (bossgate, deaths, havok, play48, throw, rzx x68, rzxroom x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9 calls (`stage1/rec/deaths` 9) |
| Called from | `StepActor` (tail) |
| Calls | `StartSequence` (falls into) |
| Reads | `$5F02`-`$5F1C` (`IntroScript+181`); `$650F`-`$651C` (`ActorPage9+15`) |
| Writes | `$5F02` (`IntroScript+181`) |

### `StartSequence` (`$917E`)

**Start the script at BC in the sequence slot L: count, timing, first frame**

HL = the actor at the slot (+`$30`-`$38`), BC = the script: [count][speed][X offset facing left][X offset facing right][size class] then one frame a step (three bytes a step in the jump and fall scripts: frame, Y step, X step). The count to the slot, then StartSequenceCount `$9180`.

StartSequenceCount `$9180` (A = the count, BC at the speed byte; from HiroLanded `$90E1`): +`$22` = 0; SequenceTiming `$919F`; L = `$3B`; SequenceFrameAt `$9191`.

Witness: L1 4906 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9 calls, 671 t-states own (0.00 %) |
| Runs (the other recordings) | 195 calls (`stage1/rec/deaths` 135, `stage1/rec/rooms` 36, `stage1/rec/gameover` 6 and 4 more) |
| Called from | `StartPoseSeq` (tail), `StartTurn` (tail), `HiroMelee` (tail), `ActorExpired` (falls into) |
| Calls | `StartSequenceCount` (falls into) |
| Reads | `$76F3` (`ActorScripts+9`); `$792B` (`ActorScripts+577`); `$7A0F` (`ActorScriptsMore+7`); `$7AB6` (`LandScript`); `$7ACE`-`$7ADB` (`StrikeScript2`, `StrikeScript3`); `$7B50`-`$7B58` (`StandScript+80`) |
| Writes | `$5D22`-`$5D34` (`BuildOutlineMaskLoop+14`, `BuildRowBaseLoop`, `BuildBoxRowLoop`, `BuildBoxPlaceLoop`); `$5E22`-`$5E33` (`IntroBoxSides+8`); `$5F22`-`$5F32` (`IntroScript+213`) |

### `StartSequenceCount` (`$9180`)

**Start a sequence with the count in A (BC at the script's speed byte)**

The tail of StartSequence `$917E`, and HiroLanded's entry (`$90E1`, the damage count). (HL) = A; +`$22` = 0; SequenceTiming `$919F`; L = `$3B` and SequenceFrameAt `$9191` (the first frame).

Witness: L1 4920 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 136 calls (`stage1/rec/deaths` 136) |
| Called from | `HiroLanded` (tail), `StartSequence` (falls into) |
| Calls | `SequenceFrameAt` (tail), `SequenceTiming` |
| Writes | `$5D22`-`$5D35` (`BuildOutlineMaskLoop+14`, `BuildRowBaseLoop`, `BuildBoxRowLoop`, `BuildBoxPlaceLoop`); `$5E22` (`IntroBoxSides+8`); `$5E33` (`IntroBoxSides+25`); `$5F22` (`IntroScript+213`); `$5F33`-`$5F37` (`IntroScript+230`); `$6522` (`ActorPage9+34`); 1 more ranges |

### `SequenceNextFrame` (`$918C`)

**A sequence step: the next frame from the script pointer +`$3A`/+`$3B`**

The common tail of the frame-list handlers (DeathStep, TurnStep, PoseStep, ActionStep, FallDamageStep, HangStep): BC = +`$3A`/+`$3B`, then SequenceFrameAt `$9191`.

Witness: L1 11974 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 26 calls, 664 t-states own (0.00 %) |
| Runs (the other recordings) | 409 calls (`stage1/rec/deaths` 300, `stage1/rec/rooms` 63, `stage1/rec/opt2` 10 and 4 more) |
| Called from | `DeathStep` (tail), `PoseStep` (tail), `ActionStep` (tail), `FallDamageStep` (tail) |
| Calls | `SequenceFrameAt` (falls into) |
| Reads | `$5D3A`-`$5D3B` (`BuildBoxPlaceLoop+6`); `$5E3A`-`$5E3B` (`IntroBoxRowLoop+2`); `$5F3A`-`$5F3B` (`IntroScript+237`); `$653A`-`$653B` (`ActorPage9+58`) |

### `SequenceFrameAt` (`$9191`)

**Frame +`$23` = (BC), the pointer moves on to +`$3A`/+`$3B`; no move (MoveActor with DE = 0)**

Jumps to `$9B53` (DE = 0, MoveActor `$9B56`): the actor stands while the frame changes.

Witness: L1 16894 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 35 calls, 1,967 t-states own (0.00 %) |
| Runs (the other recordings) | 605 calls (`stage1/rec/deaths` 436, `stage1/rec/rooms` 99, `stage1/rec/opt2` 15 and 4 more) |
| Called from | `StartSequenceCount` (tail), `SequenceNextFrame` (falls into) |
| Calls | `ApplyNoMove` (tail) |
| Reads | `$76F8`-`$76FB` (`ActorScripts+14`); `$7930`-`$7933` (`ActorScripts+582`); `$7A14`-`$7A17` (`ActorScriptsMore+12`); `$7ABB`-`$7AE7` (`LandScript+5`, `HardLandScript`, `StrikeScript2`, `StrikeScript3`); `$7B55`-`$7B5D` (`StandScript+85`, `Script911A`) |
| Writes | `$5D23` (`BuildOutlineMaskLoop+15`); `$5D3A`-`$5D3B` (`BuildBoxPlaceLoop+6`); `$5E23` (`IntroBoxSides+9`); `$5E3A`-`$5E3B` (`IntroBoxRowLoop+2`); `$5F23` (`IntroScript+214`); `$5F3A`-`$5F3B` (`IntroScript+237`); 2 more ranges |

### `SequenceHeader` (`$919C`)

**Script header: the count to (HL), then the timing and offset (SequenceTiming)**

HL = the slot. Callers: ActorJump `$9044`, FallSequenceStart `$9066`, DeathLeavesBonus `$9131`.

Witness: L1 1695 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x69, rzxroom x11).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 40 t-states own (0.00 %) |
| Runs (the other recordings) | 77 calls (`stage1/rec/deaths` 54, `stage1/rec/rooms` 14, `stage1/rec/gameover` 3 and 3 more) |
| Called from | `ActorJump`, `FallSequenceStart`, `DeathLeavesBonus` |
| Calls | `SequenceTiming` (falls into) |
| Reads | `$7A18` (`ActorScriptsMore+16`); `$7A2F` (`ActorScriptsMore+39`); `$7A51` (`WalkScript`); `$7A7A` (`RunScript`); `$7B00` (`StandScript`); `$7B5D` (`Script911A`) |
| Writes | `$5D30`-`$5D31` (`BuildRowBaseLoop+10`, `BuildBoxRowLoop`); `$5F38` (`IntroScript+235`) |

### `SequenceTiming` (`$919F`)

**Script header: the speed to +`$1A`/+`$1D`, the X offset for the facing, the size class**

The speed byte (frames a step) to +`$1A` and +`$1D` (`$9C32`); `$A6B1`: the X offset of the facing (the first byte facing left, +`$1B` bit 7, else the second) is added to X and kept in +`$3D` (`$A6A1` takes it back at the end); the size class to +`$14` and its five bytes from SizeClasses `$6082` to +`$15`-`$19`. Out: A = 0, BC past the header.

Witness: L1 6615 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 11 calls, 736 t-states own (0.00 %) |
| Runs (the other recordings) | 273 calls (`stage1/rec/deaths` 190, `stage1/rec/rooms` 50, `stage1/rec/gameover` 9 and 4 more) |
| Called from | `StartSequenceCount`, `SequenceHeader` (falls into) |
| Calls | `SetFrameDelay`, `ActorFrameStep` |
| Reads | `$76F4` (`ActorScripts+10`); `$792C` (`ActorScripts+578`); `$7A10`-`$7A19` (`ActorScriptsMore+8`); `$7A30` (`ActorScriptsMore+40`); `$7A52` (`WalkScript+1`); `$7A7B` (`RunScript+1`); 4 more ranges |

### `DeathStep` (`$91A9`)

**Sequence +`$37` (the death script): frames, then the end of the actor**

SequenceHandlers `$73F5`; HL = +`$37`. Counts down with a frame a step. At 0: first +`$02` bit 5 is set and one more still step is made; on the next: +`$39` set -> DeathLeavesBonus `$911A`; else +`$02` = 0 (the actor is free), kind `$48` (the shield) clears the invulnerable flag `$6651`, MarkSpawnKilled `$9137`, and `$A59B` (the room spawner may fill the page again).

Witness: deaths 25 runs. Witness: L1 3660 (bossgate, deaths, havok, play48, throw, rzx x67, rzxroom x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`) |
| Called from | `JumpToHandler` |
| Calls | `DeathLeavesBonus` (tail), `MarkSpawnKilled`, `SequenceNextFrame` (tail), `ApplyNoMove` (tail), `SpawnRoomEnemies` (tail) |
| Reads | `$5F02` (`IntroScript+181`); `$5F37`-`$5F39` (`IntroScript+234`); `$6502` (`ActorPage9+2`); `$651C` (`ActorPage9+28`); `$6537`-`$6539` (`ActorPage9+55`) |
| Writes | `$5F37` (`IntroScript+234`); `$6502` (`ActorPage9+2`); `$6537` (`ActorPage9+55`); `$6651` (`Invulnerable`) |

### `RiseStep` (`$91D4`)

**Sequence +`$38` (the bonus rising): 4 pixels up a step**

SequenceHandlers `$73F7`. At 0 +`$02` bit 5 is set. RiseMove `$91DB` (DE = `$00FC`: Y - 4) -> MoveActor `$9B56`; also the first step from DeathLeavesBonus `$9134`.

Witness: L1 115 (deaths, play48, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`) |
| Called from | `JumpToHandler` |
| Calls | `RiseMove` (tail) |
| Reads | `$5F38` (`IntroScript+235`) |
| Writes | `$5F38` (`IntroScript+235`) |

### `RiseMove` (`$91DB`)

**Move the actor 4 pixels up (DE = `$00FC`): MoveActor**

From RiseStep `$91D4` and DeathLeavesBonus `$9134`.

Witness: L1 131 (deaths, play48, rzx x12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/deaths` 2) |
| Called from | `DeathLeavesBonus` (tail), `RiseStep` (tail) |
| Calls | `ApplyMove` (tail) |

### `TurnStep` (`$91E1`)

**Sequence +`$33` (the turn): the facing +`$1B` flips when 2 steps are left**

SequenceHandlers `$73ED`; HL = +`$33`. At count 2: +`$1B` negated. Then PoseStep `$91EE`.

Witness: L1 5090 (bossgate, deaths, gameover, hiscore, play48, rooms, throw, c x1, opt x3, poke-room x2, rzx x69, rzxroom x12).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 549 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`, `stage1/rec/gameover` and 3 more) |
| Called from | `JumpToHandler` |
| Calls | `PoseStep` (falls into) |
| Reads | `$5D1B` (`BuildOutlineMaskLoop+7`); `$5D33` (`BuildBoxRowLoop+2`); `$5E1B` (`IntroBoxSides+1`); `$5E33` (`IntroBoxSides+25`); `$5F1B` (`IntroScript+206`); `$5F33` (`IntroScript+230`) |
| Writes | `$5D1B` (`BuildOutlineMaskLoop+7`); `$5E1B` (`IntroBoxSides+1`); `$5F1B` (`IntroScript+206`) |

### `PoseStep` (`$91EE`)

**Sequence +`$32` (and the end of +`$33`): a frame a step, at 0 SequenceEndDrop**

SequenceHandlers `$73EB`.

Witness: L1 7652 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x8, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 16 calls, 526 t-states own (0.00 %) |
| Runs (the other recordings) | 456 calls (`stage1/rec/deaths` 361, `stage1/rec/rooms` 72, `stage1/rec/gameover` 11 and 3 more) |
| Called from | `TurnStep` (falls into), `JumpToHandler` |
| Calls | `SequenceNextFrame` (tail), `SequenceEndDrop` (tail) |
| Reads | `$5D32`-`$5D33` (`BuildBoxRowLoop+1`); `$5E32`-`$5E33` (`IntroBoxSides+24`); `$5F32`-`$5F33` (`IntroScript+229`) |
| Writes | `$5D32`-`$5D33` (`BuildBoxRowLoop+1`); `$5E32`-`$5E33` (`IntroBoxSides+24`); `$5F32`-`$5F33` (`IntroScript+229`) |

### `ActionStep` (`$91F4`)

**Sequence +`$34` (strike, throw, hurt): a frame a step, the hit test while +`$02` bit 4 is set**

SequenceHandlers `$73EF`. With +`$02` bit 4 (Hiro's strike armed by HiroMelee `$9102`): `$9DCA`, the reach test in front of him (it clears the bit on a hit). At 0: SequenceEndDrop `$9201`.

Witness: L1 5395 (bossgate, havok, menu, play48, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x13).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 942 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/menu`, `stage1/rec/opt2`, `stage1/rec/opt3` and 1 more) |
| Called from | `JumpToHandler` |
| Calls | `SequenceNextFrame` (tail), `SequenceEndDrop` (tail), `ProbeStrikeCell` |
| Reads | `$5D02` (`Hiro+2`); `$5D34` (`BuildBoxPlaceLoop`) |
| Writes | `$5D34` (`BuildBoxPlaceLoop`) |

### `SequenceEndDrop` (`$9201`)

**A sequence ended: the X offset back, then the floor test (falling if nothing below)**

`$A6A1` takes the header's X offset +`$3D` back and restores the size class +`$3C`; DE = 0; `$9CD5` sets +`$02` bits 1 and 2: the next step tests the floor and falls or stands (the fall steps +`$26` start again).

Witness: L1 3658 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 9 calls, 333 t-states own (0.00 %) |
| Runs (the other recordings) | 18 calls (`stage1/rec/opt2` 5, `stage1/rec/opt3` 5, `stage1/rec/opt4` 5 and 1 more) |
| Called from | `PoseStep` (tail), `ActionStep` (tail) |
| Calls | `StartFall` (tail), `ActorFrameBack` |

### `FallDamageStep` (`$920A`)

**Sequence +`$35` (the hard landing): 2 energy lost a step**

SequenceHandlers `$73F1`. LoseEnergy `$9615` with A = 2 (it ignores the loss while the shield `$6651` is up, and takes a life at 0). At 0: ResumeState `$9AEC` (the state handler).

Entry HangStep `$9215` (SequenceHandlers `$73F3`, sequence +`$36`, the ladder grab): the same count-down without the loss.

Witness: deaths 14 runs. Witness: L1 129 (deaths, play48, rzx x8, rzxroom x1).

[Animation: `FallDamageStep` at work](img/routines/FallDamageStep.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`) |
| Called from | `JumpToHandler` |
| Calls | `SequenceNextFrame` (tail), `LoseEnergy`, `RunHandler` (tail) |
| Reads | `$5D35` (`BuildBoxPlaceLoop+1`) |
| Writes | `$5D35` (`BuildBoxPlaceLoop+1`) |

### `JumpStep` (`$921C`)

**Sequence +`$30` (the jump): a frame and a Y, X step a script step**

SequenceHandlers `$73E7`; HL = +`$30`. At 0: `$9CD1` (+`$30` = 0, the fall starts). Else BC = +`$3A`/+`$3B`, then JumpMove `$9225`: MotionStep `$9253` reads frame, Y step E and X step D; on a rising step (D was 0 in the script) the head test `$9DF1` (a ceiling ends the jump: `$9CD1`); `$9CF8` (the floor test when +`$10` bit 1), MoveActor `$9B56`.

Witness: L1 6629 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x64, rzxroom x11).

[Animation: `JumpStep` at work](img/routines/JumpStep.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 563 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`, `stage1/rec/gameover` and 3 more) |
| Called from | `JumpToHandler` |
| Calls | `JumpMove` (falls into), `StartFallEndJump` (tail) |
| Reads | `$5D30`-`$5D3B` (`BuildRowBaseLoop+10`, `BuildBoxRowLoop`, `BuildBoxPlaceLoop`) |
| Writes | `$5D30` (`BuildRowBaseLoop+10`) |

### `JumpMove` (`$9225`)

**A jump step from the script at BC: MotionStep, the head test on a rising step, the floor test, MoveActor**

From JumpStep `$921C` and ActorJump `$9047` (the first step). D = 0 from MotionStep (no X step, or a wall): the head test `$9DF1`; a ceiling ends the jump (`$9CD1`, the fall).

Witness: L1 7241 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x64, rzxroom x11).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 14 calls, 1,174 t-states own (0.00 %) |
| Runs (the other recordings) | 442 calls (`stage1/rec/deaths` 254, `stage1/rec/rooms` 99, `stage1/rec/gameover` 47 and 3 more) |
| Called from | `ActorJump` (tail), `JumpStep` (falls into) |
| Calls | `MotionStep`, `ApplyMove` (tail), `StartFallEndJump` (tail), `ProbeVertical`, `ProbeCeiling` |

### `FallScriptStep` (`$9238`)

**Sequence +`$31` (the fall script): a frame and a step a script step; at 0 the fall goes on free**

SequenceHandlers `$73E9`. Like JumpStep with no head test. At 0 (FallSeqEnd `$9249`): `$A6A1`, +`$10` bit 4 cleared, `$9B53` (still).

Witness: L1 4577 (deaths, play48, rooms, rzx x58, rzxroom x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`, `stage1/rec/rooms`) |
| Called from | `JumpToHandler` |
| Calls | `FallMove` (falls into) |
| Reads | `$5D10` (`BuildPageTails+9`); `$5D31`-`$5D3B` (`BuildBoxRowLoop`, `BuildBoxPlaceLoop`) |
| Writes | `$5D10` (`BuildPageTails+9`); `$5D31` (`BuildBoxRowLoop`) |

### `FallMove` (`$9240`)

**A fall-script step from BC: MotionStep, the floor test, MoveActor**

From FallScriptStep `$9238` and FallSequenceStart `$9069` (the first step).

Witness: L1 4585 (deaths, play48, rooms, rzx x58, rzxroom x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 162 calls (`stage1/rec/deaths` 132, `stage1/rec/rooms` 30) |
| Called from | `FallSequenceStart` (tail), `FallScriptStep` (falls into) |
| Calls | `MotionStep`, `ApplyNoMove` (tail), `ApplyMove` (tail), `ProbeVertical`, `ActorFrameBack` |

### `MotionStep` (`$9253`)

**Read a jump or fall script step: frame +`$23`, E = Y step, D = X step (mirrored when facing left)**

BC = the step; +`$3A`/+`$3B` = BC + 3; then `$9D8E` (the wall test when +`$10` bit 0: a wall clears D; it also stops the kinds `$40-$46` there, `$97A3`). Callers: JumpMove `$9225`, FallMove `$9240`.

Witness: L1 11826 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x68, rzxroom x13).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 14 calls, 1,800 t-states own (0.00 %) |
| Runs (the other recordings) | 604 calls (`stage1/rec/deaths` 386, `stage1/rec/rooms` 129, `stage1/rec/gameover` 47 and 3 more) |
| Called from | `JumpMove`, `FallMove` |
| Calls | `ProbeWalls` (tail) |
| Reads | `$5D1B` (`BuildOutlineMaskLoop+7`); `$7A1D`-`$7A45` (`ActorScriptsMore+21`); `$7A56`-`$7AAE` (`WalkScript+5`, `RunScript`); `$7B05`-`$7B19` (`StandScript+5`) |
| Writes | `$5D23` (`BuildOutlineMaskLoop+15`); `$5D3A`-`$5D3B` (`BuildBoxPlaceLoop+6`) |

### `HiroAttack` (`$926E`)

**Hiro's fire (+`$6650` set): throw the weapon `$664B` (actor `$6600`) or strike**

From StepActor `$9AE9` for Hiro when `$6650` (the fire request) is not 0. `$69E1` = the strike (1-3). `$664B` = 0 (no weapon): HiroMelee `$90EC`. After Havok (`$6652` set): ResumeState `$9AEC`. The weapon page `$6600` active (+`$02` bit 0): nothing, one in flight at a time.

Else the weapon kind `$40` + `$664B` - 1: its 7-byte record (KindTemplates `$7200`, KindTemplate `$A652`) is patched into the template `$64EE` (bytes 2-3, 8-9, 12, 16-17: the path, the step, the death script, the size), SpawnActor `$A65D` on page `$6600` at Hiro's Y + `$0A`, X + 6 (+ the template's byte 8 when facing left), its +`$1B` = Hiro's, +`$3F` = 0, then per kind: below `$43` the life +`$3F` = the hold time `$69E3` x 4; `$43`: the step delay +`$0C` = 5 - (hold time / 8 AND 7), a longer hold flies faster; `$44`: +`$05` = `$F3` + 2 x (strike - 1). A weapon spawned at X `$9C` or more expires at once (`$97A3`). Without a boss (`$9A59` = 0) the count `$6649` loses one. Then the throw script `$7AEF` (8 frames) in +`$34` (StartActionSeq `$9104`).

Entry HiroEndWalk `$9321` (from HiroControl when `$6652` is set, the end after Havok): no input; with `$6652` bit 6 clear Hiro walks up (E = -1) and, at X `$58` or more, left: the end scene walks him.

Witness: L1 650 (bossgate, havok, menu, play48, throw, c x1, opt x3, poke-room x15, rzx x66, rzxroom x10).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 88 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/menu` 1, `stage1/rec/opt2` 1, `stage1/rec/opt3` 1 and 1 more) |
| Called from | `StepActor` (tail) |
| Calls | `HiroMelee` (tail) |
| Reads | `$664B` (`Weapon`) |
| Writes | `$69E1` (`Strike`) |

### `HiroControl` (`$9333`)

**Kind `$24`, Hiro's state handler: the directions read into a walk step**

The handler at +`$03` of Hiro (KindTemplates `$7200` entry `$24`, the template `$65CA`), from ResumeState `$9AEC` on each of his logic steps (every 3 frames: +`$1A` = 3). The end (`$6652` set): HiroEndWalk `$9321`. Else `ReadDirection` `$850C` (the input bits the tick left in `$850D`): none -> `$9C39` (stop: the run counters +`$24`/+`$25` cleared, no move); else the step D x 2, E x 4 (X 2 pixels, Y 4 pixels a step) -> `$9AFD` (hanging: `$9C4A`; else WalkStep `$9B05`).

Witness: c1 260 logic steps in 975 frames; deaths 1458. Witness: L1 32891 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

[Animation: `HiroControl` at work](img/routines/HiroControl.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 18,948 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/deaths`, `stage1/rec/menu`, `stage1/rec/rooms` and 4 more) |
| Called from | `JumpToHandler` |
| Calls | `ReadDirection`, `HiroMove` (tail), `StopActor` (tail) |
| Reads | `$6652` (`EndFlags`) |

### `WeaponControl` (`$9514`)

**Kinds `$40-$46`, the thrown weapon on page `$6600`: fly at 2 x the facing until +`$3F` runs out**

+`$3F` (the life, from HiroAttack: hold time x 4) counts down; D = 2 x +`$1B`, E = 0 -> `$9B28` (the wall test and move). At 0 WeaponExpire `$9523`: `$97A3` (+`$10` bit 5), still. The handler word of the template `$6F3A` (copied to `$64EE`). The throw recording throws the spinblade and the blade from our own keys (Weapon and WeaponCount POKEd), frames 1893-3039.

Witness: L1 2632 (bossgate, havok, throw, rzx x26, rzxroom x2).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SpawnSparks` (`$965F`)

**Three spark actors (kind `$47`) at the cell `$69E2` for 170 frames**

The cell last probed (`$69E2`, written by ProbeCell `$9E4F`) gives the position (`$8EC7`: Y = row x 16, X = column x 8, then X + 2), kept in the operand of `LD BC,nn` at `$9683`. Three times: the template `$6582` gets the bytes +5 to +7 from `$7B86-$7B88`, `$7B83-$7B85`, `$7B80-$7B82` (the animation `$7B89` and three different +7 bytes: `$A8`, `$9B`, `$8E`), FindFreeActor `$9F2C` looks for a free page among `$62-$65`, and SpawnActor `$A65D` puts a kind `$47` there with the 16-bit timer at 170 frames (`$9991`). The main registers are kept (EXX).

Callers: BreakBlock `$9E98` (a block smashed), CollectFragment `$990D` (a Fireblade fragment taken), StrikeEnemy `$976B` (a boss other than kind `$25` hit). Ran in `play48` at frame 1458 (a block broken in room 6, its item revealed) and in bossgate (the giant struck, StrikeEnemy `$976B`); no fragment in the keyed recordings.

Witness: L1 82 (bossgate, play48, throw, rzx x31, rzxroom x4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ActorInteractions` (`$9698`)

**The touches and strikes of actor H before it moves**

Called from ApplyMoveNoGate `$9B6A` before every move of every actor (5275 runs). H = the actor's page.

An actor hurt or expiring (+`$10` bits 4, 5) does nothing.

**Hiro** (H = `$5D`): only hand to hand (weapon `$664B` = 0; a shot strikes for itself), only while a combat move runs (+`$34`, the move's action slot) and before it has hit (+2 bit 4). His box is narrowed to the strike: the two columns at the side he faces (+`$1B`), one row: the second from the top, the third for the sweep (power 3, `$69E1`); StrikeAllActors `$96FF` tests it against the eight other actors; the box is put back. 48 strikes (c1, menu, opt2-4).

**The others** (`$96EB`): a falling actor (+2 bit 2) goes to FallingTouch `$9854`; kind 0 nothing; the shots (kinds `$40-$46`) strike like Hiro (falls into StrikeAllActors); every other kind tests its touch with Hiro (TouchHiro `$9801`).

Witness: L1 148167 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 305 calls, 34,316 t-states own (0.00 %) |
| Runs (the other recordings) | 4,970 calls (`stage1/rec/deaths` 3,099, `stage1/rec/rooms` 880, `stage1/rec/menu` 284 and 4 more) |
| Called from | `ApplyMoveNoGate` |
| Calls | `StrikeAllActors`, `TouchHiro` (tail) |
| Reads | `$5D02`-`$5D34` (`Hiro+2`, `BuildPageTails`); `$5E10`-`$5E1C` (`IntroBox+21`, `IntroBoxSides`); `$5F10`-`$5F1C` (`IntroScript+195`); `$6010`-`$601C` (`HavokRoomEnter+60`); `$6110`-`$611C` (`SizeClasses+142`); `$6510`-`$651C` (`ActorPage9+16`); 3 more ranges |
| Writes | `$5D2A`-`$5D2D` (`BuildRowBaseLoop+4`) |

### `StrikeAllActors` (`$96FF`)

**Test the strike or shot of actor H against the actors `$5E-$65`**

H = the striker (Hiro, or a shot of kinds `$40-$46` falling in from ActorInteractions `$96FC`); D steps the pages `$5E-$65` through StrikeActor `$970A`. A hit that ends the strike pops the return address of the loop (StrikeActor `$979F`), so one swing hits one actor; the scorchball (kind `$41`) goes on.

Witness: L1 4718 (bossgate, havok, menu, play48, throw, c x1, opt x3, poke-room x15, rzx x66, rzxroom x8).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 16 calls, 4,656 t-states own (0.00 %) |
| Runs (the other recordings) | 32 calls (`stage1/rec/menu` 8, `stage1/rec/opt2` 8, `stage1/rec/opt3` 8 and 1 more) |
| Called from | `ActorInteractions` |
| Calls | `StrikeActor` |

### `StrikeActor` (`$970A`)

**The strike of actor H against actor D: shield transforms, damage, kills**

D = the target's page, H = the striker's. No hit when the target is inactive, in its hold count (+`$28`), of a kind with bit 7 set (a pickup that has just popped out of a block), hurt or expiring (+`$10` bits 4, 5), or when the boxes do not overlap (BoxesOverlap `$9A27`). Kills in `play48` frames 1775 and 2219 (patrollers, 50 each).

**A pickup** (kind below `$23`): the power-up shield (kind `$19`) becomes the power-up reset shield (kind `$1C`, its frame and score from `$5ED6`), the speed-up shield (`$1A`) the speed-up reset shield (`$1D`, `$5EDA`): +`$0A`, +`$0B`, +`$1C` rewritten, +`$10` bit 7 cleared, sound 6; the manual's rule. Other pickups are not hit.

**A boss** (kinds `$25-$29`): `$97B5` = its kind (the operand KillActor reads); Hiro's own strikes do not reach it (only a shot), and a boss other than kind `$25` throws sparks (SpawnSparks `$965F`).

**Damage** (`$976E`): the striker's +`$13` (a shot's power), else the combat power `$69E1` (1 punch, 2 high kick, 3 sweep). A target with no hit points (+`$13` = 0) cannot be hurt (the hazards). Hit points - damage; at zero or below KillActor `$97A8`; else sound `$0C` and, when the target has a hurt animation (+`$08`), +`$10` bit 4 (it flinches, `$904A`).

**After a hit** (`$9795`): the striker's +2 bit 4 is cleared (the strike is spent); the scorchball returns to the loop, every other striker pops the loop's return (one hit a swing), and a shot expires (ExpireActor `$97A3`).

Witness: L1 36333 (bossgate, havok, menu, play48, throw, c x1, opt x3, poke-room x15, rzx x66, rzxroom x8).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 128 calls, 3,712 t-states own (0.00 %) |
| Runs (the other recordings) | 256 calls (`stage1/rec/menu` 64, `stage1/rec/opt2` 64, `stage1/rec/opt3` 64 and 1 more) |
| Called from | `StrikeAllActors` |
| Reads | `$5E02` (`IntroBox+7`); `$5F02` (`IntroScript+181`); `$6002` (`HavokRoomEnter+46`); `$6102` (`SizeClasses+128`); `$6202` (`PrintGlyphsAddress+2`); `$6302` (`IntroAttrsC+191`); 2 more ranges |

### `ExpireActor` (`$97A3`)

**Mark actor H expired: its next step runs its end**

Sets +`$10` bit 5; the actor's next step (StepActor `$9A99`, `JP NZ,$9163`) runs its death or vanishing animation from +`$0F`. The IM 2 tick sets the same bit when the 16-bit timer +`$1E` runs out.

Callers: TouchPickup `$98AD` (a pickup taken), KillActor `$97E2` (the boss gate), StrikeActor `$97A0` (a shot spent), ProbeWalls `$9DC7` (a shot at a wall), `$926E`, `$93EB`, `$947D`, `$9801` (deaths: 1 run).

Witness: L1 300 (bossgate, deaths, havok, play48, throw, rzx x45, rzxroom x4). KillActor's boss branch `$97B9` ran in bossgate at frame 435 (a giant killed, OpenGate `$97E2`, sound 3; its hit points POKEd to 1) and in havok at frame 29 (no gate: the win `$97CA`, the life bonus, GameWonSound `$97DE`).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/deaths` 1) |
| Called from | `TouchHiro` |
| Reads | `$5F10` (`IntroScript+195`) |
| Writes | `$5F10` (`IntroScript+195`) |

### `TouchHiro` (`$9801`)

**Actor H touches Hiro: a pickup, a hurt, or a stand on it**

H = the actor's page (from ActorInteractions `$96F7`/`$96FC` and FallingTouch `$9856`): 2585 runs. The two POKE files' "No interactions" writes `RET` here (38913 = 201; 46 puts the `LD L,n` back).

While Hiro's combat move runs (+`$34`) only kind `$2D` can touch him. Hiro's box is shrunk by his top row for the test (`$5D2C` + 1), BoxesOverlap `$9A27` with D = `$5D`; no overlap: done (2409 of 2585).

**Kinds below `$23`, the pickups** (`$98AD`): ExpireActor `$97A3` (it vanishes), CollectPickup `$98B6`, `JP $8365` (the panel's numbers). The pickups are taken even with the energy ball on.

**The others**: nothing while `$6651` is set (the energy ball or the death wait) or while Hiro is hurt (`$5D10` bit 4). Kinds below `$35` hurt Hiro (`$9860`); kind `$35` hurts; kind `$36` hurts when its +`$32` is `$0D` or more (its phase); kinds `$37-$3D` (`$983B`) are objects Hiro stands on: both get +`$10` bit 3, and when Hiro's Y - the object's Y is its +`$11` or +`$12` the object's +`$10` bit 2 is set (the crush offset, read by FallingTouch `$9854`); kinds from `$3E` nothing.

**HurtHiro** (`$9860`): the hurt animation `$69DC` = `$7A2F`'s low byte when Hiro and the attacker face the same way (+`$1B`), else `$18`; sound 0; LoseEnergy `$9615` with 4 (8 from kind `$2D`). When Hiro is in a jump or another action of slot +`$30` (low 3 bits not 0) the slot is kept and `$5D02` = 3 (in the air: he drops); else `$5D10` bit 4 (hurt: StepActor runs `$904A`). The loop at `$9895` tests A = 0 with `AND $01` and can never branch: the slots +`$31-$38` are never looked at. deaths: 27 hurts, 3 in the air.

Witness: L1 98469 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, throw, c x1, poke-room x9, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 73 calls, 9,745 t-states own (0.00 %) |
| Runs (the other recordings) | 2,512 calls (`stage1/rec/deaths` 2,133, `stage1/rec/rooms` 319, `stage1/rec/gameover` 60) |
| Called from | `ActorInteractions` (tail) |
| Calls | `PrintScore` (tail), `LoseEnergy`, `ExpireActor`, `CollectPickup`, `BoxesOverlap` |
| Reads | `$5D10`-`$5D1B` (`BuildPageTails+9`, `BuildOutlineMaskLoop`); `$5D2C`-`$5D34` (`BuildRowBaseLoop+6`, `BuildBoxRowLoop`, `BuildBoxPlaceLoop`); `$5E1B`-`$5E1C` (`IntroBoxSides+1`); `$5F1B`-`$5F1C` (`IntroScript+206`); `$601C` (`HavokRoomEnter+72`); `$611C` (`SizeClasses+154`); 2 more ranges |
| Writes | `$5D02`-`$5D10` (`Hiro+2`, `BuildPageTails`); `$5D2C`-`$5D30` (`BuildRowBaseLoop+6`); `$69DC` (`HiroFallScript`); `$8454` (`EffectRequest`) |

### `CollectPickup` (`$98B6`)

**The effect of the pickup of kind A (1-`$22`)**

A = the kind. Sound 8; `$A652` gives the kind's record (the table `$7200`, a word a kind) DE, 4 bytes: frame, score index (in the table at `$5D82`, AddScore `$99E7`), two bytes. In deaths 1 run (a kind below 7).

| Kind | Pickup (the manual) | Record | Effect |

| --- | --- | --- | --- |

| 1-5 | gems | `$5DD2-$5DE2` | 50, 100, 200, 400, 700 |

| 6 | the flask | `$5DE6` | 7000 (score index `$A2`; the manual says 700) |

| 7-11 | the letters E X T R A | `$5EA6-$5EB6` | LetterPickup `$9997` |

| 12-16 | the letters B O N U S | `$5EBA-$5ECA` | LetterPickup |

| `$11-$17` | the weapon shields: fist, blade, scorchball, dart, spinblade, needle bolts, trispike | `$5DF6`, `$5DFA`, `$5E82`, `$5E92`, `$5E96`, `$5E8E`, `$5E86` | SetWeapon `$98F3`: weapon 0-6 |

| `$18` | a Fireblade fragment | `$5E8A` | CollectFragment `$9908`: 10000, at 16 50000 and weapon 7 |

| `$19` | the power-up shield | `$5ECE` | minimum power `$6647` + 2, at most `$10` (eight) |

| `$1A` | the speed-up shield | `$5ED2` | the meter's rate `$6644` + 1, at most 3 |

| `$1B` | the bullet shield | `$5E9A` | 16 bullets with a weapon, else 50 |

| `$1C` | the power-up reset shield | `$5ED6` | `$6647` = 0, 400 |

| `$1D` | the speed-up reset shield | `$5EDA` | `$6644` = 1, 400 |

| `$1E` | vitality | `$5E9E` | `$6642` = `$20` |

| `$1F` | invulnerability | `$5EA2` | SpawnShield `$9962` for `$355` frames (17 s) |

| `$20-$22` | the orbs | `$5DEA-$5DF2` | 1000, 2000, 5000 |

Witness: L1 51 (bossgate, deaths, play48, rzx x31, rzxroom x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/deaths` 1) |
| Called from | `TouchHiro` |
| Calls | `TemplateForKind` |
| Reads | `$5DD3` (`IntroScene+1`) |
| Writes | `$8454` (`EffectRequest`) |

### `SetWeapon` (`$98F3`)

**Take the weapon of a shield record: the icon, the weapon, the bullets**

HL = the record + 2: the icon's first character (`$6671`, the second `$6672` = + 1: the weapon indicator's two characters), then the weapon `$664B`: 0 fist, 1 blade, 2 scorchball, 3 dart, 4 spinblade, 5 needle bolts, 6 trispike, 7 the Fireblade. The bullets `$6649` = 16 with a weapon, 0 with the fist.

Callers: PickupWeapon `$98F2` (a shield, or the 16th fragment: the Fireblade) and `$FF10` when the bullets run out (HL = `$5DF8`, the fist shield's record + 2): 12 runs, in c1 and c48 at the start of play.

Witness: L1 102 (bossgate, deaths, gameover, havok, hiscore, menu, play48, throw, c x1, opt x3, rzx x51, rzxroom x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 127 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/rec/deaths` 5, `stage1/rec/menu` 2, `stage1/rec/gameover` 1 and 3 more) |
| Called from | `PanelWeapon` |
| Reads | `$5DF8`-`$5DF9` (`WeaponDefaultItem`) |
| Writes | `$6649`-`$664B` (`WeaponCount`, `WeaponCountShown`, `Weapon`); `$6671`-`$6672` (`WeaponIcon`) |

### `CollectFragment` (`$9908`)

**A Fireblade fragment: 10000, sparks, the count, at 16 the Fireblade**

A = the record's score index (`$C2`, 10000). AddScore `$99E7`, SpawnSparks `$965F`, the fragment count `$664E` + 1 (shown by `$FF3C`). Below 16 the return address is popped and the weapon is not changed; at 16 AddScore `$C6` (50000) and back to `$98F2`, where SetWeapon `$98F3` gives weapon 7, the Fireblade (the manual: "Hiro's weapon will automatically switch over to the Fireblade"). Not run in the keyed recordings.

Witness: L1 4 (rzx x4). Not run in the keyed recordings.

[Animation: `CollectFragment` at work](img/routines/CollectFragment.gif)

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `AddScore` (tail) |

### `RestoreShield` (`$995C`)

**Put the energy ball back after a room change**

From EnterRoom `$95F4` when `$6651` is set: BC = the ball's 16-bit timer left (`$651E`), then SpawnShield `$9962`. deaths 2 runs.

Witness: L1 16 (deaths, play48, rzx x8, rzxroom x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rec/deaths` 2) |
| Called from | `EnterRoom` |
| Calls | `SpawnShield` (falls into) |
| Reads | `$651E`-`$651F` (`ActorPage9+30`) |

### `SpawnShield` (`$9962`)

**The energy ball (kind `$48`) in page `$65` for BC frames**

BC = the frames. The position: the ball's own (`$6500`) when it is already there, else Hiro's Y and X + 8. SpawnActor `$A65D` with the template `$6594`, kind `$48`; `$6651` = `$48` (LoseEnergy `$9615` and TouchHiro `$9824` ignore harm while it is set; the IM 2 tick clears it when the page-`$65` timer runs out, `$84AB`, and so does `$91CB`). Then the 16-bit timer (SetActorTimer `$9991`).

Callers: LoseEnergy `$9632` (170 frames after a lost life), CollectPickup `$98E8` (the invulnerability pickup, `$355` = 853 frames, 17 s at 50 Hz: the manual's "sixteen second period"), RestoreShield `$995C`, `$872B`. deaths and gameover 7 runs.

Witness: L1 113 (deaths, gameover, havok, hiscore, play48, rzx x53, rzxroom x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage1/rec/deaths` 6, `stage1/rec/gameover` 1) |
| Called from | `LoseEnergy`, `RestoreShield` (falls into) |
| Calls | `SetActorTimer` (tail), `InitActor` |
| Reads | `$5D00`-`$5D01` (`Hiro`); `$6500`-`$6502` (`ActorPage9`) |
| Writes | `$651E`-`$651F` (`ActorPage9+30`); `$6651` (`Invulnerable`) |

### `StartLifetime` (`$9987`)

**A kind with bit 7 set starts its life: bit 7 off, 255 frames**

HL = the actor's page (from StepActor `$9AB3`, every step: 8195 runs). A pickup that pops out of a broken block is spawned with kind + `$80` (BreakReveal `$9F1D`): StrikeActor leaves it alone until its first step, which clears the bit and gives it 255 frames before it vanishes. deaths 1 run.

Witness: L1 272892 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 398 calls, 12,230 t-states own (0.00 %) |
| Runs (the other recordings) | 7,797 calls (`stage1/rec/deaths` 4,198, `stage1/rec/rooms` 1,430, `stage1/rec/menu` 1,170 and 4 more) |
| Called from | `StepActor` |
| Calls | `SetActorTimer` (falls into) |
| Reads | `$5D1C` (`BuildOutlineMaskLoop+8`); `$5E1C` (`IntroBoxSides+2`); `$5F1C` (`IntroScript+207`); `$601C` (`HavokRoomEnter+72`); `$611C` (`SizeClasses+154`); `$651C` (`ActorPage9+28`); 1 more ranges |
| Writes | `$5F1C` (`IntroScript+207`) |

### `SetActorTimer` (`$9991`)

**The 16-bit timer +`$1E`/+`$1F` of page H = BC**

The IM 2 tick counts it down and sets +`$10` bit 5 at zero (`$8490-$84A3`).

Witness: L1 364 (bossgate, deaths, gameover, havok, hiscore, play48, throw, poke-room x2, rzx x64, rzxroom x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage1/rec/deaths` 7) |
| Called from | `SpawnShield` (tail), `StartLifetime` (falls into) |
| Writes | `$5F1E`-`$5F1F` (`IntroScript+209`); `$651E`-`$651F` (`ActorPage9+30`) |

### `MatchLetters` (`$99D9`)

**Do the five attributes at DE equal the five at HL?**

HL = `$5C3D` (five `$47`), DE = the word's attributes. Out: Z when all five match; DE kept; BC = 5 when they matched (B counted down, C = 5), the length the LDIR after it copies.

Witness: L1 9 (rzx x4, rzxroom x1). Not run in the keyed recordings.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoxesOverlap` (`$9A27`)

**Do the boxes of actors H and D overlap?**

The boxes are +`$2A` (left column), +`$2B` (right), +`$2C` (top row), +`$2D` (bottom), in cells (`$8F3B` writes them on every move). D's left - 1 must be below H's right and D's right not below H's left, the same for the rows; a D edge of 0 skips the first test of its axis. Out: carry set when they overlap. L and E changed. 134974 runs: TouchHiro, StrikeActor, `$8A90`.

Witness: L1 694628 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1,513 calls, 147,256 t-states own (0.01 %) |
| Runs (the other recordings) | 133,461 calls (`stage1/rec/menu` 69,470, `stage1/rec/gameover` 38,745, `stage1/rec/deaths` 10,777 and 5 more) |
| Called from | `DrawActor`, `TouchHiro` |
| Reads | `$5D2A`-`$652D` (`BuildRowBaseLoop+4`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$662A`-`$662D` (`WeaponActor+42`); `$672A`-`$672D` (`TitleColours+48`); `$682A`-`$682D` (`TitleColours+304`); `$692A`-`$692D` (`EnemySlots+78`); `$6A2A`-`$6A2D` (`FireHeld+71`); 2 more ranges |

### `HiroMove` (`$9AFD`)

**Hiro's move from the input: on a ladder, or walk / jump / climb**

From Hiro's handler `$9333` with D = dX x 2, E = dY x 4 from the controls (`$850C`). On a ladder (+2 bit 3) ClimbMove `$9C4A`; else MoveActor `$9B05`. 1102 runs.

Witness: L1 16670 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 167 calls, 5,527 t-states own (0.00 %) |
| Runs (the other recordings) | 935 calls (`stage1/rec/deaths` 363, `stage1/rec/rooms` 286, `stage1/rec/gameover` 72 and 4 more) |
| Called from | `HiroControl` (tail) |
| Calls | `MoveActor` (falls into) |
| Reads | `$5D02`-`$5D25` (`Hiro+2`, `BuildPageTails`) |
| Writes | `$5D24`-`$5D25` (`BuildOutlineMaskLoop+16`) |

### `MoveActor` (`$9B05`)

**Move actor HL by D, E: turn, jump or climb, walk, stand**

D = dX, E = dY (negative up). Used by Hiro (HiroMove) and the walkers' handlers (`$9348`, `$93AF`, ...): 2836 runs.

A D against the facing (+`$1B`) turns (`JP M,$90B1`, the turn animation). E negative: `$9023`, the jump (D = 0: the ladder above first, LadderAbove `$9CA7`). E positive: with a D the down is ignored; without it the ladder below (LadderBelow `$9CA1`) starts the climb down (`$906C`), else the actor stands (`$9B4A`). E = 0: walk: ProbeVertical `$9CF8` (the floor under), ProbeWalls `$9D8E` (D = 0 at a wall); Hiro with no X move stands; else the walk counters +`$24`, +`$25` count up (+`$24` is the run-up: 4 steps give the long jump, `$9038`). When Hiro stands on an object (+`$10` bit 3, TouchHiro) the flag is cleared, he is no longer in the air and does not move in X. Then ApplyMove `$9B56`.

Witness: L1 37599 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 228 calls, 43,916 t-states own (0.00 %) |
| Runs (the other recordings) | 2,394 calls (`stage1/rec/deaths` 1,872, `stage1/rec/rooms` 401, `stage1/rec/gameover` 121) |
| Called from | `ChaserControl` (tail), `PatrolControl` (tail), `HiroMove` (falls into) |
| Calls | `ActorJump` (tail), `StartTurn` (tail), `SetWalkCounters` (falls into), `ApplyMove` (tail), `LadderBelow`, `ProbeVertical`, `ProbeWalls` |
| Reads | `$5D10`-`$5D25` (`BuildPageTails+9`, `BuildOutlineMaskLoop`); `$5E10`-`$5E25` (`IntroBox+21`, `IntroBoxSides`); `$5F10`-`$5F25` (`IntroScript+195`) |
| Writes | `$5D24`-`$5D25` (`BuildOutlineMaskLoop+16`); `$5E24`-`$5E25` (`IntroBoxSides+10`); `$5F24`-`$5F25` (`IntroScript+215`) |

### `SetWalkCounters` (`$9B4B`)

**+`$24`, +`$25` = A, then ApplyMove**

Witness: L1 13601 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 47 calls, 1,917 t-states own (0.00 %) |
| Runs (the other recordings) | 677 calls (`stage1/rec/deaths` 363, `stage1/rec/rooms` 141, `stage1/rec/menu` 53 and 4 more) |
| Called from | `MoveActor` (falls into), `FallStep` (tail) |
| Calls | `ApplyMove` (tail) |
| Writes | `$5D24`-`$5D25` (`BuildOutlineMaskLoop+16`); `$5E24`-`$5E25` (`IntroBoxSides+10`); `$5F24`-`$5F25` (`IntroScript+215`) |

### `ApplyNoMove` (`$9B53`)

**ApplyMove with D = E = 0**

Witness: L1 19343 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 35 calls, 350 t-states own (0.00 %) |
| Runs (the other recordings) | 636 calls (`stage1/rec/deaths` 462, `stage1/rec/rooms` 104, `stage1/rec/gameover` 15 and 4 more) |
| Called from | `SequenceFrameAt` (tail), `DeathStep` (tail), `FallMove` (tail) |
| Calls | `ApplyMove` (falls into) |

### `ApplyMove` (`$9B56`)

**Move actor HL by D, E: the gate, the touches, the position, the frame**

The Y before the move goes to the operand at `$95B4` (CheckRoomExit undoes the step's vertical part at a column crossing). Hiro: `$8F01` (a gate of the room, the table `$76D2`: D = 0 at its X). Falls into ApplyMoveNoGate. 5141 runs.

Witness: L1 94606 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 305 calls, 51,220 t-states own (0.00 %) |
| Runs (the other recordings) | 4,836 calls (`stage1/rec/deaths` 2,965, `stage1/rec/rooms` 880, `stage1/rec/menu` 284 and 4 more) |
| Called from | `RiseMove` (tail), `JumpMove` (tail), `FallMove` (tail), `PathControl` (tail), `MoveActor` (tail), `SetWalkCounters` (tail), `ApplyNoMove` (falls into) |
| Calls | `RoomBarrier`, `ApplyMoveNoGate` (falls into) |
| Reads | `$5D00`-`$5D01` (`Hiro`); `$5E00`-`$5E01` (`IntroBox+5`); `$5F00`-`$5F01` (`IntroScript+179`); `$6000`-`$6001` (`HavokRoomEnter+44`); `$6100`-`$6101` (`SizeClasses+126`); `$6500` (`ActorPage9`); 1 more ranges |
| Writes | `$5D00`-`$5D01` (`Hiro`); `$5E00`-`$5E01` (`IntroBox+5`); `$5F00`-`$5F01` (`IntroScript+179`); `$6000`-`$6001` (`HavokRoomEnter+44`); `$6100`-`$6101` (`SizeClasses+126`); `$95B4` (`RoomExitSetX+5`) |

### `ApplyMoveNoGate` (`$9B66`)

**The touches and strikes, then the move**

ActorInteractions `$9698` (IY, HL, DE kept), then AddMove.

Witness: L1 148167 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,099 calls (`stage1/rec/deaths` 3,099) |
| Called from | `StillControl` (tail), `ApplyMove` (falls into) |
| Calls | `ActorInteractions`, `AddMove` (falls into) |

### `AddMove` (`$9B71`)

**Y + E, X + D, then the frame**

Also used by `$A73E`. 13932 runs.

Witness: L1 159028 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 369 calls, 17,731 t-states own (0.00 %) |
| Runs (the other recordings) | 12,683 calls (`stage1/rec/menu` 5,271, `stage1/rec/deaths` 3,163, `stage1/rec/gameover` 3,005 and 4 more) |
| Called from | `ApplyMoveNoGate` (falls into), `TitleSequence` |
| Calls | `AnimateAfterMove` (falls into) |
| Reads | `$5D00`-`$6501` (`Hiro`, `BuildPageTails`, `Intro48`, `IntroScene` and 24 more); `$6600`-`$6601` (`WeaponActor`); `$6700`-`$6701` (`TitleColours+6`); `$6800`-`$6801` (`TitleColours+262`); `$6900`-`$6901` (`EnemySlots+36`); `$6A00`-`$6A01` (`FireHeld+29`); 1 more ranges |
| Writes | `$5D00`-`$6501` (`Hiro`, `BuildPageTails`, `Intro48`, `IntroScene` and 24 more); `$6600`-`$6601` (`WeaponActor`); `$6700`-`$6701` (`TitleColours+6`); `$6800`-`$6801` (`TitleColours+262`); `$6900`-`$6901` (`EnemySlots+36`); `$6A00`-`$6A01` (`FireHeld+29`); 1 more ranges |

### `AnimateAfterMove` (`$9B7A`)

**Keep the last move, animate, then Hiro's room test**

+`$21` = E / 4 (signed), +`$22` = D; AnimateActor `$9BB6`. Outside play (the handler's flag `$845F` set: the title and high-score screens) done. Hiro: FootstepSound `$9BA2` and `JP $955A` (CheckRoomExit). Other kinds below `$47`: +`$20` bit 1. 13986 runs.

Witness: L1 160342 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 372 calls, 52,553 t-states own (0.00 %) |
| Runs (the other recordings) | 13,140 calls (`stage1/rec/menu` 5,275, `stage1/rec/deaths` 3,177, `stage1/rec/gameover` 3,008 and 4 more) |
| Called from | `AddMove` (falls into), `StopActor` (tail) |
| Calls | `CheckRoomExit` (tail), `FootstepSound`, `AnimateActor` |
| Reads | `$5D1C` (`BuildOutlineMaskLoop+8`); `$5E1C`-`$5E20` (`IntroBoxSides+2`); `$5F1C`-`$5F20` (`IntroScript+207`); `$601C`-`$6020` (`HavokRoomEnter+72`); `$611C`-`$6120` (`SizeClasses+154`); `$651C` (`ActorPage9+28`); 2 more ranges |
| Writes | `$5D21`-`$6522` (`BuildOutlineMaskLoop+13`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6620`-`$6622` (`WeaponActor+32`); `$6721`-`$6722` (`TitleColours+39`); `$6821`-`$6822` (`TitleColours+295`); `$6921`-`$6922` (`EnemySlots+69`); `$6A21`-`$6A22` (`FireHeld+62`); 1 more ranges |

### `FootstepSound` (`$9BA2`)

**Hiro's footstep: sound 7 on frames `$26` and `$28`**

The operand at `$9BA3` is the effect player's busy flag (written at `$8545`): no footstep over another effect. Frames `$26`, `$28` are the walk frames with a foot down. 2348 runs, 10 footsteps (c1, deaths, menu).

Witness: L1 42125 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 235 calls, 5,328 t-states own (0.00 %) |
| Runs (the other recordings) | 2,113 calls (`stage1/rec/deaths` 949, `stage1/rec/rooms` 576, `stage1/rec/gameover` 144 and 4 more) |
| Called from | `AnimateAfterMove` |
| Reads | `$5D23` (`BuildOutlineMaskLoop+15`) |
| Writes | `$8454` (`EffectRequest`) |

### `AnimateActor` (`$9BB6`)

**Choose the frame +`$23` and the frame delay**

An action slot that runs (`$8E89`: +`$30-$38` not all 0) animates by itself: +`$20` bit 0 stays set. Frozen (+`$10` bit 7): nothing; bit 6 freezes after this frame (bit 7 set). No walk animation (+6 = 0): the frame +`$0A`, the delay +`$0C`. In the air: +`$0A`, delay 1. On a ladder: delay 4, the frame from the Y (`$7AFB`[1 + (Y / 4) mod 4]). Walking: the delay +`$0C` (x 2 + 1 when the flag at `$9BE9` is set: walking into a wall, ProbeWalls), the frame = the table at +5/+6 [1 + +`$25`], +`$25` wrapping at the table's count. 13986 runs.

Witness: L1 162563 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 372 calls, 120,027 t-states own (0.01 %) |
| Runs (the other recordings) | 13,614 calls (`stage1/rec/menu` 5,275, `stage1/rec/deaths` 3,177, `stage1/rec/gameover` 3,008 and 5 more) |
| Called from | `AnimateAfterMove` |
| Calls | `ActorInSequence`, `SetFrameDelay` |
| Reads | `$5D02`-`$6525` (`Hiro+2`, `BuildPageTails`, `Intro48`, `IntroScene` and 24 more); `$6602`-`$6625` (`WeaponActor+2`); `$6706`-`$6720` (`TitleColours+12`); `$6806`-`$6820` (`TitleColours+268`); `$6906`-`$6920` (`EnemySlots+42`); `$6A06`-`$6A20` (`FireHeld+35`); 9 more ranges |
| Writes | `$5D02` (`Hiro+2`); `$5D20`-`$6525` (`BuildOutlineMaskLoop+12`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$6602` (`WeaponActor+2`); `$6620`-`$6625` (`WeaponActor+32`); `$6720`-`$6723` (`TitleColours+38`); `$6820`-`$6823` (`TitleColours+294`); 3 more ranges |

### `SetFrameDelay` (`$9C32`)

**+`$1A` and the frame timer +`$1D` = A**

Witness: L1 92498 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 336 calls, 13,177 t-states own (0.00 %) |
| Runs (the other recordings) | 12,571 calls (`stage1/rec/menu` 5,268, `stage1/rec/gameover` 2,956, `stage1/rec/deaths` 2,428 and 5 more) |
| Called from | `SequenceTiming`, `AnimateActor` |
| Writes | `$5D1A`-`$651D` (`BuildOutlineMaskLoop+6`, `Intro48`, `IntroScene`, `IntroPictureText` and 23 more); `$661A`-`$661D` (`WeaponActor+26`); `$671A`-`$671D` (`TitleColours+32`); `$681A`-`$681D` (`TitleColours+288`); `$691A`-`$691D` (`EnemySlots+62`); `$6A1A`-`$6A1D` (`FireHeld+55`); 1 more ranges |

### `StopActor` (`$9C39`)

**No input: Hiro stops, the walk counters cleared, the still frame**

From Hiro's handler `$933C` when the controls give nothing: walking (+`$24` not 0), the counters are cleared and AnimateAfterMove `$9B7A` runs with no move. 2835 runs, 54 stops.

Witness: L1 16221 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x15).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 93 calls, 2,820 t-states own (0.00 %) |
| Runs (the other recordings) | 2,742 calls (`stage1/rec/deaths` 1,095, `stage1/rec/menu` 886, `stage1/rec/rooms` 469 and 4 more) |
| Called from | `HiroControl` (tail) |
| Calls | `AnimateAfterMove` (tail) |
| Reads | `$5D24` (`BuildOutlineMaskLoop+16`) |
| Writes | `$5D24`-`$5D25` (`BuildOutlineMaskLoop+16`) |

### `LadderBelow` (`$9CA1`)

**Is there a ladder to climb down under the actor?**

From MoveActor `$9B1A` (down pressed with no X). ProbeBelow `$9CEE`: on a floor, the cell under (B) is tested by LadderCellTest. Out: NZ when the cell holds a ladder top (`$55` or `$54` in plane `$6A`, the list `$73C5`) and X is on the ladder (X mod 16 = 0 or 8). c1, menu: 31 runs, none found.

Witness: L1 1608 (bossgate, menu, play48, c x1, rzx x28).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 11 calls, 374 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/menu` 20) |
| Called from | `MoveActor` |
| Calls | `LadderAbove` (tail), `ProbeBelow` |
| Reads | `$6A81` (`ControlMenu+6`); `$73C5`-`$73C6` (`SpecialTiles`) |

### `LadderAbove` (`$9CA7`)

**Is there a ladder to climb up above the actor?**

From the jump `$9027` with no X. ProbeVertical `$9CF8` with E = 0, then the cell one row up (B - `$14`) is tested as in LadderBelow. Out: NZ: climb (`JP NZ,$906C`). 10 runs.

Witness: L1 484 (havok, play48, rooms, c x1, opt x3, rzx x40).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 1,726 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/opt2` 2, `stage1/rec/opt3` 2, `stage1/rec/opt4` 2 and 1 more) |
| Called from | `ActorJump`, `LadderBelow` (tail) |
| Calls | `ProbeVertical` |
| Reads | `$6A59` (`FireHeld+118`); `$6A6A`-`$6A7E` (`FireHeld+135`, `ControlMenu`); `$73C5`-`$73C6` (`SpecialTiles`) |

### `StartFallEndJump` (`$9CD1`)

**The jump slot ends: +`$30` = 0, then StartFall**

From `$921C` and `$9225`: 50 runs.

Witness: L1 884 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x64, rzxroom x11).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 36 t-states own (0.00 %) |
| Runs (the other recordings) | 48 calls (`stage1/rec/deaths` 31, `stage1/rec/rooms` 9, `stage1/rec/gameover` 2 and 3 more) |
| Called from | `JumpStep` (tail), `JumpMove` (tail) |
| Calls | `StartFall` (falls into) |
| Writes | `$5D30` (`BuildRowBaseLoop+10`) |

### `StartFall` (`$9CD5`)

**In the air (+2 bit 1), then FallStep**

From `$9201`: 242 runs.

Witness: L1 4542 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 11 calls, 260 t-states own (0.00 %) |
| Runs (the other recordings) | 231 calls (`stage1/rec/deaths` 156, `stage1/rec/rooms` 44, `stage1/rec/gameover` 7 and 4 more) |
| Called from | `SequenceEndDrop` (tail), `StartFallEndJump` (falls into) |
| Calls | `FallStep` (falls into) |
| Reads | `$5D02` (`Hiro+2`); `$5E02` (`IntroBox+7`); `$5F02` (`IntroScript+181`) |
| Writes | `$5D02` (`Hiro+2`); `$5E02` (`IntroBox+7`); `$5F02` (`IntroScript+181`) |

### `FallStep` (`$9CD9`)

**One step of a fall: 4 pixels down, the fall counter**

From StepActor `$9ACC` while in the air: 615 runs. +2 bit 2 (falling); ProbeBelow `$9CEE` (4 down): on landing E = 0 and the landing runs from there (`$90C3` for Hiro: a fall of `$14` steps or more, 80 pixels, starts the fall damage, 2 x (steps - `$11`) up to `$0E` steps of 2 energy; the orbs shatter, `$9159`). The fall counter +`$26`: + 1 a step, 0 after a landing (`$FF` + 1). Then SetWalkCounters `$9B4B` with 1 and the move.

Witness: L1 11152 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 39 calls, 3,728 t-states own (0.00 %) |
| Runs (the other recordings) | 576 calls (`stage1/rec/deaths` 303, `stage1/rec/rooms` 106, `stage1/rec/menu` 35 and 4 more) |
| Called from | `StepActor` (tail), `StartFall` (falls into) |
| Calls | `SetWalkCounters` (tail), `ProbeBelow` |
| Reads | `$5D02` (`Hiro+2`); `$5D26` (`BuildRowBaseLoop`); `$5E02` (`IntroBox+7`); `$5E26` (`IntroBoxSides+12`); `$5F02` (`IntroScript+181`); `$5F26` (`IntroScript+217`) |
| Writes | `$5D02` (`Hiro+2`); `$5D26` (`BuildRowBaseLoop`); `$5E02` (`IntroBox+7`); `$5E26` (`IntroBoxSides+12`); `$5F02` (`IntroScript+181`); `$5F26` (`IntroScript+217`) |

### `ProbeBelow` (`$9CEE`)

**ProbeVertical with E = 4 and C = the height - E**

Witness: L1 13043 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 50 calls, 2,472 t-states own (0.00 %) |
| Runs (the other recordings) | 596 calls (`stage1/rec/deaths` 303, `stage1/rec/rooms` 106, `stage1/rec/menu` 55 and 4 more) |
| Called from | `LadderBelow`, `FallStep` |
| Calls | `ProbeVerticalC` (tail) |
| Reads | `$5D16` (`BuildOutlineMaskLoop+2`); `$5E16` (`IntroBox+27`); `$5F16` (`IntroScript+201`) |

### `ProbeVertical` (`$9CF8`)

**The floor under the actor's move: land, start a fall, or go on**

C = the height +`$16` (the height - E from ProbeBelow), D, E = the move. Only for actors that stand on floors (+`$10` bit 1, tested at `$9CFB`) and when E is not negative (ProbeFloorCell). Out: HL = IY; Z when the move goes on, NZ when it stopped or started a fall.

Witness: L1 99089 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 225 calls, 4,304 t-states own (0.00 %) |
| Runs (the other recordings) | 3,142 calls (`stage1/rec/deaths` 2,252, `stage1/rec/rooms` 501, `stage1/rec/gameover` 162 and 4 more) |
| Called from | `JumpMove`, `FallMove`, `StillControl`, `MoveActor`, `LadderAbove` |
| Calls | `ProbeVerticalC` (falls into) |
| Reads | `$5D16` (`BuildOutlineMaskLoop+2`); `$5E16` (`IntroBox+27`); `$5F16` (`IntroScript+201`) |

### `ProbeVerticalC` (`$9CFB`)

**+`$10` bit 1: the actor stands on floors**

Witness: L1 112132 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 275 calls, 15,826 t-states own (0.00 %) |
| Runs (the other recordings) | 3,738 calls (`stage1/rec/deaths` 2,555, `stage1/rec/rooms` 607, `stage1/rec/gameover` 189 and 4 more) |
| Called from | `ProbeBelow` (tail), `ProbeVertical` (falls into) |
| Calls | `ProbeFloorCell` |
| Reads | `$5D10` (`BuildPageTails+9`); `$5E10` (`IntroBox+21`); `$5F10` (`IntroScript+195`) |

### `ProbeFloorCell` (`$9D0A`)

**At a cell boundary, the floor under the new position**

H = X + D, L = Y + E; only when Y + E + C is a multiple of 16 (the feet on a cell edge). FloorUnder `$9D58`; then returns to ProbeVertical's caller (the `POP HL`). No floor: on a ladder nothing, else +2 bits 1, 2 (in the air, falling). A floor (`$9D2B`): E = 0; when the actor was in the air the bits are cleared and it lands: Hiro `JP $90C3` (the landing, the fall damage), the orbs (kinds `$20-$22`) `JP $9159` (they shatter: the manual's "if they hit a floor, they will shatter"), the other kinds from `$23` nothing, the pickups (kinds below `$20`) stop turning (FreezeAnim `$9D50`) unless the cell is a breakable one (TestBreakable `$9EBB`).

Witness: L1 64304 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 263 calls, 44,227 t-states own (0.00 %) |
| Runs (the other recordings) | 3,533 calls (`stage1/rec/deaths` 2,448, `stage1/rec/rooms` 560, `stage1/rec/gameover` 174 and 4 more) |
| Called from | `ProbeVerticalC` |
| Calls | `HiroLanded` (tail), `FloorUnder`, `TestBreakable` |
| Reads | `$5D00`-`$5D02` (`Hiro`); `$5D1C` (`BuildOutlineMaskLoop+8`); `$5E00`-`$5E02` (`IntroBox+5`); `$5E1C` (`IntroBoxSides+2`); `$5F00`-`$5F1C` (`IntroScript+179`) |
| Writes | `$5D02` (`Hiro+2`); `$5E02` (`IntroBox+7`); `$5F02`-`$5F10` (`IntroScript+181`) |

### `FreezeAnim` (`$9D50`)

**Stop the actor's animation after this frame**

+`$10` bit 6 set, bit 7 cleared; A = 0. Also `$9112` (a hazard's trigger).

Witness: L1 1531 (bossgate, deaths, play48, throw, poke-room x3, rzx x38, rzxroom x9).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FloorUnder` (`$9D58`)

**Is there a solid cell under the actor's feet?**

HL = Y, X of the test; C = the height. Clipped at the left (+`$20` bit 6): the column at + 0; at the right (bit 7): + 8; else the middle (width / 2 - 1), then width / 2 when that one is free. Out: NZ when solid (CellSolid `$9D7A`).

Witness: L1 57081 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 241 calls, 27,160 t-states own (0.00 %) |
| Runs (the other recordings) | 3,092 calls (`stage1/rec/deaths` 2,229, `stage1/rec/rooms` 473, `stage1/rec/gameover` 129 and 4 more) |
| Called from | `ProbeFloorCell` |
| Calls | `CellSolid` (falls into) |
| Reads | `$5D15`-`$5D20` (`BuildOutlineMaskLoop+1`); `$5E15`-`$5E20` (`IntroBox+26`, `IntroBoxSides`); `$5F15`-`$5F20` (`IntroScript+200`) |

### `CellSolid` (`$9D7A`)

**Is the cell at Y + C, X + B solid?**

`$8EB5` gives the cell (the row from Y / 16 through the table `$7000`, the column X / 8). Out: B = A = the cell, NZ when plane `$67` bits 0-1 are set. HL kept.

Witness: L1 59319 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 246 calls, 26,224 t-states own (0.00 %) |
| Runs (the other recordings) | 3,177 calls (`stage1/rec/deaths` 2,273, `stage1/rec/rooms` 487, `stage1/rec/gameover` 135 and 4 more) |
| Called from | `FloorUnder` (falls into) |
| Calls | `CellIndex` |
| Reads | `$6714`-`$67E5` (`TitleColours+26`) |

### `ProbeWalls` (`$9D8E`)

**Stop an X move at a wall**

Only for actors with +`$10` bit 0 set, not at the room's right edge (X `$95` or more) or the left (X 5 or less going left), and with D not 0. Probes the side it moves to (X + 1 left, X + width - 2 right) at three heights (ProbeSide `$9E31`). A wall: D = 0, the walk animation slows (`$9BE9` = `$80`), and a shot (kinds `$40-$46`) expires (ExpireActor). 3252 runs, 190 walls.

Witness: L1 50771 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 225 calls, 40,409 t-states own (0.00 %) |
| Runs (the other recordings) | 3,027 calls (`stage1/rec/deaths` 2,136, `stage1/rec/rooms` 502, `stage1/rec/gameover` 162 and 4 more) |
| Called from | `MotionStep` (tail), `MoveActor` |
| Calls | `ProbeSide` |
| Reads | `$5D01`-`$5D1C` (`Hiro+1`, `BuildPageTails`); `$5E01`-`$5E1C` (`IntroBox+6`, `IntroBoxSides`); `$5F01`-`$5F1C` (`IntroScript+180`) |
| Writes | `$9BE9` (`AnimateFrame+26`) |

### `ProbeStrikeCell` (`$9DCA`)

**The cell Hiro's combat move hits (a breakable block?)**

From the combat move's slot `$91FB` while the strike can still hit (+2 bit 4). The column in front: X + width - 1 (right) or X + 1 (left), + 1 more for the sweep (power 3: `$0203` for `$0102`); the height: Y + 8, the sweep at the feet. ProbeCell `$9E3E` and through it BreakOrBlock `$9E61` (Hiro's move breaks a block). 42 runs.

Witness: L1 1774 (bossgate, havok, menu, play48, c x1, opt x3, poke-room x15, rzx x55, rzxroom x8).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 14 calls, 2,583 t-states own (0.00 %) |
| Runs (the other recordings) | 28 calls (`stage1/rec/menu` 7, `stage1/rec/opt2` 7, `stage1/rec/opt3` 7 and 1 more) |
| Called from | `ActionStep` |
| Calls | `ProbeStrikeHeight` |
| Reads | `$5D15`-`$5D1B` (`BuildOutlineMaskLoop+1`); `$69E1` (`Strike`) |

### `ProbeCeiling` (`$9DF1`)

**Stop an upward move at a ceiling**

ProbeCeilingE, HL = IY. From `$9225` (the jump) and ClimbMove. 223 runs.

Witness: L1 4780 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x64, rzxroom x11).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 14 calls, 745 t-states own (0.00 %) |
| Runs (the other recordings) | 209 calls (`stage1/rec/deaths` 112, `stage1/rec/rooms` 43, `stage1/rec/opt2` 14 and 3 more) |
| Called from | `JumpMove` |
| Calls | `ProbeCeilingE` |

### `ProbeCeilingE` (`$9DF8`)

**E negative: probe the head's corners; blocked: E = 0**

Witness: L1 4780 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x64, rzxroom x11).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 14 calls, 530 t-states own (0.00 %) |
| Runs (the other recordings) | 209 calls (`stage1/rec/deaths` 112, `stage1/rec/rooms` 43, `stage1/rec/opt2` 14 and 3 more) |
| Called from | `ProbeCeiling` |
| Calls | `ProbeHead` |

### `ProbeHead` (`$9E02`)

**Probe above the head: the left and right corners (or the one inside)**

Witness: L1 4307 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x64, rzxroom x11).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 12 calls, 1,320 t-states own (0.00 %) |
| Runs (the other recordings) | 197 calls (`stage1/rec/deaths` 109, `stage1/rec/rooms` 40, `stage1/rec/gameover` 12 and 3 more) |
| Called from | `ProbeCeilingE` |
| Calls | `ProbeHeadLeft`, `ProbeAtTop` (tail) |
| Reads | `$5D15`-`$5D20` (`BuildOutlineMaskLoop+1`) |

### `ProbeHeadLeft` (`$9E18`)

**X + 1**

Witness: L1 4283 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, opt x3, rzx x64, rzxroom x11).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 12 calls, 84 t-states own (0.00 %) |
| Runs (the other recordings) | 193 calls (`stage1/rec/deaths` 105, `stage1/rec/rooms` 40, `stage1/rec/gameover` 12 and 3 more) |
| Called from | `ProbeHead` |
| Calls | `ProbeAtTop` (falls into) |

### `ProbeAtTop` (`$9E1A`)

**ProbeCell at X offset A, Y + 8**

Witness: L1 53015 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 220 calls, 5,060 t-states own (0.00 %) |
| Runs (the other recordings) | 3,100 calls (`stage1/rec/deaths` 2,198, `stage1/rec/rooms` 486, `stage1/rec/gameover` 168 and 4 more) |
| Called from | `ProbeHead` (tail), `ProbeHeadLeft` (falls into), `ProbeSide` |
| Calls | `ProbeCell` (tail) |

### `ProbeStrikeHeight` (`$9E1F`)

**ProbeCell at X offset A: Y + 8, or the feet for the sweep**

Witness: L1 1774 (bossgate, havok, menu, play48, c x1, opt x3, poke-room x15, rzx x55, rzxroom x8).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 14 calls, 602 t-states own (0.00 %) |
| Runs (the other recordings) | 28 calls (`stage1/rec/menu` 7, `stage1/rec/opt2` 7, `stage1/rec/opt3` 7 and 1 more) |
| Called from | `ProbeStrikeCell` |
| Calls | `ProbeAtFoot` (tail), `ProbeCell` (tail) |
| Reads | `$69E1` (`Strike`) |

### `ProbeAtMiddle` (`$9E2B`)

**ProbeCell at Y + height / 2**

Witness: L1 40878 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 196 calls, 6,880 t-states own (0.00 %) |
| Runs (the other recordings) | 2,639 calls (`stage1/rec/deaths` 1,942, `stage1/rec/rooms` 377, `stage1/rec/gameover` 144 and 4 more) |
| Called from | `ProbeSide` |
| Calls | `ProbeCell` (tail) |
| Reads | `$5D16` (`BuildOutlineMaskLoop+2`); `$5E16` (`IntroBox+27`); `$5F16` (`IntroScript+201`) |

### `ProbeSide` (`$9E31`)

**Probe a side at three heights: Y + 8, the middle, the feet**

B = the X offset. Out: Z when one of them is a wall.

Witness: L1 44626 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 196 calls, 8,732 t-states own (0.00 %) |
| Runs (the other recordings) | 2,730 calls (`stage1/rec/deaths` 2,004, `stage1/rec/rooms` 406, `stage1/rec/gameover` 144 and 4 more) |
| Called from | `ProbeWalls` |
| Calls | `ProbeAtTop`, `ProbeAtMiddle`, `ProbeAtFoot` (falls into) |
| Reads | `$5D16` (`BuildOutlineMaskLoop+2`); `$5E16` (`IntroBox+27`); `$5F16` (`IntroScript+201`) |

### `ProbeAtFoot` (`$9E39`)

**ProbeCell at Y + height - 4**

Witness: L1 38556 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 203 calls, 5,278 t-states own (0.00 %) |
| Runs (the other recordings) | 177 calls (`stage1/rec/opt2` 59, `stage1/rec/opt3` 59, `stage1/rec/opt4` 59) |
| Called from | `ProbeStrikeHeight` (tail), `ProbeSide` (falls into) |
| Calls | `ProbeCell` (falls into) |
| Reads | `$5D16` (`BuildOutlineMaskLoop+2`); `$5E16` (`IntroBox+27`) |

### `ProbeCell` (`$9E3E`)

**Is the cell at Y + E + A, X + D + B a wall?**

A = the Y offset, B = the X offset. Off the room's bottom (Y `$E0` or more): no wall. The cell goes to `$69E2` (SpawnSparks's position); BreakOrBlock `$9E61` first; then plane `$68`: tiles 1-`$19` are walls. Out: Z = a wall. 8935 runs.

Witness: L1 133377 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 626 calls, 104,153 t-states own (0.01 %) |
| Runs (the other recordings) | 8,309 calls (`stage1/rec/deaths` 6,031, `stage1/rec/rooms` 1,194, `stage1/rec/gameover` 456 and 4 more) |
| Called from | `ProbeAtTop` (tail), `ProbeStrikeHeight` (tail), `ProbeAtMiddle` (tail), `ProbeAtFoot` (falls into) |
| Calls | `CellIndex`, `BreakOrBlock` |
| Reads | `$5D00`-`$5D01` (`Hiro`); `$5E00`-`$5E01` (`IntroBox+5`); `$5F00`-`$5F01` (`IntroScript+179`); `$6801`-`$6877` (`TitleColours+263`); `$68A3`-`$68BB` (`TitleColours+425`) |
| Writes | `$69E2` (`Strike+1`) |

### `BreakOrBlock` (`$9E61`)

**A breakable cell: broken by Hiro's move or a shot, else it may block**

L = the cell, IY = the actor. Hiro during a combat move (+`$34`) and the shots (kinds `$40-$46`) break: TestBreakable `$9EBB` finds the block, the strike is spent (+2 bit 4), sound `$0D`, BreakReveal `$9ED7` (a hidden pickup), the cell's tile is cleared (in the plane TestBreakable matched), the cell redrawn (`$8868`), sparks (SpawnSparks), 10 points (`$CE`), the panel; then the probe returns to its caller: free for the scorchball (it flies on), a wall for the others. The break ran in `play48` at frame 1458 (a block broken in room 6, its item revealed).

The other actors (`$9EB3`): a cell that blocks (TestBreakable's C = 1) is a wall for them (the return to ProbeCell is popped); else ProbeCell goes on. 8892 runs, 20 blocked (deaths, rooms).

Witness: L1 133232 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 626 calls, 68,447 t-states own (0.01 %) |
| Runs (the other recordings) | 8,308 calls (`stage1/rec/deaths` 6,031, `stage1/rec/rooms` 1,193, `stage1/rec/gameover` 456 and 4 more) |
| Called from | `ProbeCell` |
| Calls | `TestBreakable` |
| Reads | `$5D1C` (`BuildOutlineMaskLoop+8`); `$5D34` (`BuildBoxPlaceLoop`); `$5E1C` (`IntroBoxSides+2`); `$5F1C` (`IntroScript+207`) |

### `TestBreakable` (`$9EBB`)

**Does the cell L hold a breakable block?**

Plane `$69` tile `$19` or `$1A`: Z, C = 1; plane `$69` or `$6A` tile `$8C`: Z, C = 0; plane `$6A` tile `$8D` or `$19`: Z, C = 1. Else NZ. Out: H = the plane matched (BreakOrBlock clears the tile there), C = 1 when the block also stops the actors that cannot break it.

Witness: L1 133297 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 626 calls, 75,012 t-states own (0.01 %) |
| Runs (the other recordings) | 8,309 calls (`stage1/rec/deaths` 6,032, `stage1/rec/rooms` 1,193, `stage1/rec/gameover` 456 and 4 more) |
| Called from | `ProbeFloorCell`, `BreakOrBlock` |
| Reads | `$6901`-`$6977` (`EnemySlots+37`); `$69A3`-`$69BB` (`EnemySlots+199`); `$6A01`-`$6A77` (`FireHeld+30`); `$6AA3`-`$6ABB` (`ControlMenuPatch+10`) |

### `BreakReveal` (`$9ED7`)

**A block broken: mark it, and drop the pickup hidden in it**

L = the cell. Plane `$67` bit 1 of the cell cleared. The room's hidden-item list at `$5B02` (pairs: the cell, the content before it) is searched for the cell; the item's number B gives the bit `$80` >> (B - 1) set in `$6DFE` (the room's taken bits, saved per room by `$A58A`). Content & `$1F` = 0: nothing. Else the kind is kept in the operand at `$9F1C`; its record (`$A652`) gives the frame and score copied into the pickup template `$65BF-$65C0` (`$65C1` = 1, `$65C2` = 0); a free page among `$5E-$64` (FindFreeActorAtCell `$9F29`); SpawnActor `$A65D` with kind + `$80` (StartLifetime gives it 255 frames at its first step) at the cell; +2 bits 1, 2: it drops. Ran in `play48` at frame 1458 (a block broken in room 6, its item revealed).

Witness: L1 51 (bossgate, play48, throw, rzx x25, rzxroom x4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FindFreeActorAtCell` (`$9F29`)

**DE = the cell `$69E2`'s Y, X; then FindFreeActor**

Witness: L1 26 (bossgate, play48, throw, rzx x16, rzxroom x1). Ran in `play48` at frame 1458 (a block broken in room 6, its item revealed).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FindFreeActor` (`$9F2C`)

**The first inactive page among B pages from HL**

HL = page + 2 of the first. Out: carry clear and H = the free page; carry set when all B are active. Also used by `$A5BF`.

Witness: L1 2441 (bossgate, deaths, gameover, hiscore, play48, rooms, throw, c x1, poke-room x13, rzx x64, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 31 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/rooms` 12, `stage1/rec/deaths` 7, `stage1/rec/gameover` 1) |
| Called from | `SpawnEnemy` |
| Reads | `$5E02` (`IntroBox+7`); `$5F02` (`IntroScript+181`); `$6002` (`HavokRoomEnter+46`); `$6102` (`SizeClasses+128`) |

## enemies

`src/game/enemies.asm`

### `ChaserControl` (`$9348`)

**Kinds `$2C`, `$37-$3D`: walk toward Hiro, a few random steps when level with him**

The state handler of the walking enemies. +`$27` > 0: one step less, the same direction +`$1B`. Else Hiro's X (`$5D2A` x 2) against the actor's X: to his side, D = 2 or `$FE` toward him; level: a random direction from the frame counter `$8473` (bit 6) and +`$27` = 0-7 steps of it. The step goes to WalkStep `$9B05` (which also turns them: StartTurn `$90B1`).

Witness: rooms 82 runs (`$9348` only in rooms). Witness: L1 17816 (bossgate, rooms, poke-room x8, rzx x55, rzxroom x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`) |
| Called from | `JumpToHandler` |
| Calls | `MoveActor` (tail) |
| Reads | `$5D2A` (`BuildRowBaseLoop+4`); `$5E01` (`IntroBox+6`); `$5E27` (`IntroBoxSides+13`); `$5F01` (`IntroScript+180`); `$5F27` (`IntroScript+218`) |

### `StillControl` (`$937E`)

**Kinds `$00-$23`, `$2A` (pickups and objects): no step, only the floor test**

DE = 0; `$9CF8` (the floor test when +`$10` bit 1); `$9B66` (the move and the room-edge test without the barrier test). The items carry their number in the kind (bit 7 set: `$9987` starts a 255-frame life +`$1E` and clears it).

Witness: deaths 134 runs. Witness: L1 53561 (bossgate, deaths, play48, throw, poke-room x5, rzx x45, rzxroom x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/deaths`) |
| Called from | `JumpToHandler` |
| Calls | `ApplyMoveNoGate` (tail), `ProbeVertical` |

### `DecorControl` (`$9387`)

**Kind `$3E`: no move, +`$25` counts the steps (the animation)**

DE = 0, +`$25` + 1, then `$9B85` (the redraw and room test without a move). Template `$64DC`, from `$6F28` of the image. Not run in the keyed recordings (the RZX run has it).

Witness: L1 738 (rzx x5).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TriggerControl` (`$9390`)

**Kind `$3F`: when Hiro enters its zone, +`$0A` = 1 and +`$10` bit 6 (shown)**

HiroInZone `$9529` (zone +`$11` of TouchZones `$5FAC`). Hiro inside: the still frame +`$0A` = 1, `$9D50` (+`$10` bit 6 set, bit 7 cleared), `$9B85`. Outside: `$9B85` while +`$10` bit 7 is clear, else nothing. Template `$64CA`, from `$6F16`. Not run in the keyed recordings; the RZX snapshots hold kind `$3F` on pages `$5E-$63`.

Witness: L1 104705 (poke-room x1, rzx x17, rzxroom x5).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StalactiteControl` (`$93A8`)

**Kind `$36`: Hiro below it (zone 5) shakes it (`$7BB5`, 30 frames) and lets it fall**

HiroInZone `$9529` with zone 5 (Hiro 16 above to 31 below, within 16 pixels either side). Inside: StalactiteShake `$9112` (in StartPoseSeq): `$9D50` and the script `$7BB5` (speed 7, frames `$23`-`$26`) in +`$32`; at its end SequenceEndDrop `$9201` drops it (+`$02` bits 1, 2: the fall).

Witness: rooms 84 runs. Witness: L1 2693 (rooms, rzx x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`) |
| Called from | `JumpToHandler` |
| Calls | `HiroInZone` |

### `PatrolControl` (`$93AF`)

**Kind `$2B`: N steps right, N steps left (N = +`$12`, 16)**

First step: +`$12` moves to +`$3E` (cleared). +`$3F` counts the right steps (D = 2) down past 0, then +`$40` (N + 1) the left steps (D = `$FE`), then both are reloaded. WalkStep `$9B05`.

Witness: L1 3637 (deaths, gameover, hiscore, play48, rooms, c x1, rzx x3, rzxroom x5).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 5,605 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/deaths`, `stage1/rec/gameover`, `stage1/rec/rooms`) |
| Called from | `JumpToHandler` |
| Calls | `MoveActor` (tail) |
| Reads | `$5E12` (`IntroBox+23`); `$5E3E`-`$5E40` (`IntroBoxRowLoop+6`, `IntroBoxSide`); `$5F12` (`IntroScript+197`); `$5F3E`-`$5F40` (`IntroScript+241`) |
| Writes | `$5E12` (`IntroBox+23`); `$5E3E`-`$5E40` (`IntroBoxRowLoop+6`, `IntroBoxSide`); `$5F12` (`IntroScript+197`); `$5F3E`-`$5F40` (`IntroScript+241`) |

### `TrapControl` (`$93D6`)

**Kinds `$2E-$31`, `$34`: wait until Hiro enters zone +`$11`, then run the path**

+`$1B` = +`$12` (the direction). HiroInZone `$9529`: no zone (+`$11` = 0): PathControl `$93FB`; Hiro outside: no move (TrapStill `$93EB`); inside: +`$27` = +`$11`, +`$11` = 0, so it runs its path from the next step; PathRestart's end puts the zone back (TrapRearm `$93EE`). Templates `$62DC`, `$63EE`, `$6482`, `$6494`, `$64A6` (from `$6E2C`, `$6EBC`-`$6EF2`). Not run in the keyed recordings.

Witness: L1 1982 (rzx x5, rzxroom x4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TrapStill` (`$93EB`)

**No move this step (the waiting trap): `JP $9B53`**

From TrapControl `$93E1` (Hiro outside its zone) and its tails TrapRearm `$93EE` and ShotPathEnd `$93F6`. Not run in the keyed recordings.

Witness: L1 1100 (bossgate, havok, rzx x13, rzxroom x4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PathControl` (`$93FB`)

**Kinds `$25-$29`, `$32`, `$33`, `$35`, `$47`, `$48` and the boss shot `$2D`: follow the path +`$06`/+`$07`**

+`$1B` = 1 when +`$05` is `$46`, else +`$12` (the direction). Entry PathControlShot `$940A` (kind `$2D`, its direction already copied). The path (page +`$06`, offset +`$07`): a header (bits 0-5 the segment count to +`$40`, the whole to +`$3F`: bit 6 a random step delay +`$0C` per segment, bit 7 one per step, RandomSpeed `$9505`), then segments of [steps][Y step][X step]. +`$3E` counts a segment's steps, +`$3A`/+`$3B` points at its Y step. The X step is mirrored when +`$12` bit 7 is set. At a segment's start the bosses (kinds `$25-$29`) may fire (BossFire `$947D`). When the last segment ends: the traps `$93D6` re-arm, the shot `$940A` expires, the rest start the path again.

Each step: kind `$48` (the shield) steers to Hiro (ShieldFollow `$94E1`); +`$25` + 1; the shot (kind `$2D`) gets the wall test `$9D8E`; MoveActor `$9B56`.

Witness: L1 12290 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, opt x3, rzx x66, rzxroom x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rec/rooms`, `stage1/rec/menu`, `stage1/rec/deaths` and 4 more) |
| Called from | `JumpToHandler` |
| Calls | `BossFire`, `ShieldFollow`, `RandomSpeed`, `ApplyMove` (tail) |
| Reads | `$5E03`-`$5E25` (`IntroBox+8`, `IntroBoxSides`); `$5E3A`-`$5E40` (`IntroBoxRowLoop+2`, `IntroBoxSide`); `$5F03`-`$5F25` (`IntroScript+182`); `$5F3A`-`$5F40` (`IntroScript+237`); `$6003`-`$6025` (`HavokRoomEnter+47`); `$603A`-`$6040` (`HavokRoomEnter+102`); 9 more ranges |
| Writes | `$5E1B`-`$5E25` (`IntroBoxSides+1`); `$5E3A`-`$5E40` (`IntroBoxRowLoop+2`, `IntroBoxSide`); `$5F1B`-`$5F25` (`IntroScript+206`); `$5F3A`-`$5F40` (`IntroScript+237`); `$601B`-`$6025` (`HavokRoomEnter+71`); `$603A`-`$6040` (`HavokRoomEnter+102`); 6 more ranges |

### `BossFire` (`$947D`)

**A boss (kinds `$25-$29`) at the start of a path segment fires its shot (kind `$2D` on page `$6000`)**

D = the segments left +`$40`; HL = the actor; BC = the path. The boss's fire table lies in the path's page at +`$11`: [n] then n pairs [segment][shot path offset]. A match: the shot's path offset to `$61E0` (the template `$61DC`, its +`$07`); a shot still on page `$6000` is expired (`$97A3`) and run (ActorUpdate) until its page is free; the new one is spawned (SpawnActor `$A65D`, kind `$2D`) at the boss's Y + +`$09`, X + +`$0A`, facing as the boss (+`$1B` copied); sound 6. BC, HL kept.

Called at every segment start of every path mover (209 calls in deaths, gameover, menu, rooms, opt2-4), and the kind test passes in bossgate (3 shots) and havok (1): the fire itself is `$9487` on. The RZX run's snapshot at frame 136 000 has Havok (kind `$25`) on page `$5E` and a shot (kind `$2D`, handler PathControlShot `$940A`) on `$6000`.

Witness: L1 4894 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, opt x3, rzx x66, rzxroom x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 209 calls (`stage1/rec/rooms` 87, `stage1/rec/deaths` 64, `stage1/rec/menu` 26 and 4 more) |
| Called from | `PathControl` |
| Reads | `$5E1C` (`IntroBoxSides+2`); `$5E40` (`IntroBoxSide+1`); `$5F1C` (`IntroScript+207`); `$5F40` (`IntroScript+243`); `$601C` (`HavokRoomEnter+72`); `$6040` (`HavokRoomEnter+108`); 6 more ranges |

### `ShieldFollow` (`$94E1`)

**Kind `$48`: steer toward Hiro, E = +-4 and D = +-2 when outside a 32 x 8 window**

E = 4 (down) or `$FC` when Hiro's Y - Y + 16 is outside 0-31; D = 2 or `$FE` when his X - X + 4 is outside 0-7. The shield (kind `$48`, page `$6500`, spawned by `$9978` with `$6651` set) follows him until its life (+`$1E`) ends (the tick clears `$6651`).

Witness: L1 2516 (deaths, havok, play48, rzx x53, rzxroom x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 116 calls (`stage1/rec/deaths` 116) |
| Called from | `PathControl` |
| Reads | `$5D00`-`$5D01` (`Hiro`); `$6500`-`$6501` (`ActorPage9`) |

### `RandomSpeed` (`$9505`)

**With the path header +`$3F` AND A set: +`$0C` (the step delay) = a random 0-7**

A = `$40` (per segment) or `$80` (per step); `$A632` (15 rounds of the generator at `$8473`), AND 7. +`$0C` is the walk delay `$9BE5` puts into +`$1A`/+`$1D` after each move (frames to the next step): the mover changes speed at random. Callers: PathControl `$944D`, `$9457`.

Witness: L1 19642 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, opt x3, rzx x66, rzxroom x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 875 calls (`stage1/rec/rooms` 272, `stage1/rec/menu` 227, `stage1/rec/deaths` 180 and 4 more) |
| Called from | `PathControl` |
| Calls | `Random` |
| Reads | `$5E3F` (`IntroBoxSide`); `$5F3F` (`IntroScript+242`); `$603F` (`HavokRoomEnter+107`); `$613F` (`SizeClasses+189`); `$653F` (`ActorPage9+63`); `$663F` (`WeaponActor+63`) |
| Writes | `$610C` (`SizeClasses+138`) |

### `HiroInZone` (`$9529`)

**Is Hiro inside the proximity zone of actor H?**

H = the actor's page. Its byte +`$11` picks a zone record (1-based, 0 = no zone: returns with carry clear) in the 4-byte table that starts at `$5FAC` (`$5FA8` + 4 x index): dY low, dY high, dX low, dX high. dY = Hiro's Y (`$5D00`) - the actor's Y passes when dY >= low or dY < high (a range that may wrap below zero: `$F0`, `$01` is -16..0), the same for dX with the X bytes (`$5D01`). Out: carry set when both pass.

The only caller is the hazard handler at `$93A8` (`CALL $9529` / `JP C,$9112`): when Hiro comes close the hazard starts its animation `$7BB5`, the manual's proximity-sensing floor spikes. Run 84 times in the rooms recording; 3 tests reached the X bytes and none passed.

The table sits in actor page `$5F` above its record (bytes `$5FA8-$5FCB` in the play snapshots `c1/end.szx`).

Witness: L1 109380 (rooms, poke-room x1, rzx x28, rzxroom x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 84 calls (`stage1/rec/rooms` 84) |
| Called from | `StalactiteControl` |
| Reads | `$5D00`-`$5D01` (`Hiro`); `$5F00`-`$5F11` (`IntroScript+179`); `$5FBC`-`$5FBF` (`IntroScript+367`) |

### `SpawnRoomEnemies` (`$A59B`)

**Start the enemies standing in revealed zones**

A = RevealedZones `$6DFF` (callers `$8A90`, `$91A9`, `$95C3`); `$A59E` with A = a zone mask (from `$955A`, the zone just revealed).

For each of the `$6ADD` enemy records at (`$6ADE`), the 16 bits `$6EFE` / `$6EFF` shifted left give one bit an enemy: clear (not gone) calls SpawnEnemy `$A5BF`. 27 + 109 runs.

Witness: L1 830 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).

[Animation: `SpawnRoomEnemies` at work](img/routines/SpawnRoomEnemies.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 286 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/rec/deaths` 10, `stage1/rec/rooms` 7, `stage1/rec/gameover` 2 and 4 more) |
| Called from | `DeathStep` (tail), `EnterRoom` |
| Calls | `SpawnZoneEnemies` (falls into) |
| Reads | `$6ADD`-`$6ADF` (`EnemyCount`, `EnemyListPtr`); `$6DFF` (`RevealedZones`); `$6EFE`-`$6EFF` (`GoneEnemies`) |

### `SpawnZoneEnemies` (`$A59E`)

**SpawnZoneEnemies**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 99 calls (`stage1/rec/rooms` 88, `stage1/rec/deaths` 11) |
| Called from | `CheckRoomExit` (tail), `SpawnRoomEnemies` (falls into) |
| Calls | `SpawnEnemy` |
| Reads | `$6ADD`-`$6ADF` (`EnemyCount`, `EnemyListPtr`); `$6EFE`-`$6EFF` (`GoneEnemies`) |

### `SpawnEnemy` (`$A5BF`)

**Put an enemy into a free actor page when its zone is revealed**

IX = the enemy record (kind, cell), B = its number (counting down), C = the zone mask. Nothing when the cell's zone is not in C, or the slot `$68DB` + B is already set (the enemy is on), or none of the 7 pages `$5E00-$6400` is free (`$9F2C`).

The slot gets B; `$8ECA` turns the cell into the X and Y; TemplateForKind `$A652` gives the 18-byte template; kinds below `$20` and `$20-$22` use the shared template `$65B8` with its first two bytes copied from the kind's template to `$65BF` and `$65C1`/`$65C2` = `$03`/`$1F` (kinds below `$20`) or `$04`/`$3F` (`$20-$22`); InitActor `$A65D`; +`$29` = the enemy number; kinds with bit 7 or `$40` and up get +`$28` = Random `$A632` AND +`$0D`.

468 runs, 21 spawns (`$A5D0`).

Witness: L1 3701 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c x1, poke-room x14, rzx x68, rzxroom x17).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 573 t-states own (0.00 %) |
| Runs (the other recordings) | 467 calls (`stage1/rec/rooms` 446, `stage1/rec/deaths` 20, `stage1/rec/gameover` 1) |
| Called from | `SpawnZoneEnemies` |
| Calls | `CellPixel`, `FindFreeActor`, `Random`, `TemplateForKind`, `InitActor` |
| Reads | `$5B01`-`$5B18` (system); `$5DD2`-`$5DE3` (`IntroScene`, `IntroPictureText`, `IntroText`, `IntroPictureWait`); `$5E0D` (`IntroBox+18`); `$5ED2`-`$5ED3` (`IntroScript+133`); `$5F0D` (`IntroScript+192`); `$600D` (`HavokRoomEnter+57`); 3 more ranges |
| Writes | `$5E28`-`$5E29` (`IntroBoxSides+14`); `$5F28`-`$5F29` (`IntroScript+219`); `$6028`-`$6029` (`HavokRoomEnter+84`); `$6128`-`$6129` (`SizeClasses+166`); `$65BF`-`$65C2` (`SharedEnemyTemplate+7`); `$68DC`-`$68E2` (`EnemySlots`) |

### `Random` (`$A632`)

**Stir the 16-bit counter at `$8473` fifteen times; A = its new low byte**

The seed is the operand of the tick's `LD HL,n` (`$8472`, the frame counter). One step: HL = HL + swap(HL) + bytes, x 4, + DE, x 8, + DE; 15 steps. Callers: `$9505`, SpawnEnemy `$A5BF`. 92 runs.

Witness: L1 2482 (bossgate, deaths, gameover, hiscore, play48, rooms, c x1, poke-room x13, rzx x55, rzxroom x17).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 2,824 t-states own (0.00 %) |
| Runs (the other recordings) | 91 calls (`stage1/rec/rooms` 83, `stage1/rec/deaths` 7, `stage1/rec/gameover` 1) |
| Called from | `RandomSpeed`, `SpawnEnemy` |
| Reads | `$8473`-`$8474` (`GameTick+1`) |
| Writes | `$8473`-`$8474` (`GameTick+1`) |

## panel

`src/game/panel.asm`

### `LoseEnergy` (`$9615`)

**Take A from Hiro's vitality; at zero a life is lost**

A = the damage. Callers: HurtHiro `$988A` (4, 8 from kind `$2D`) and the fall-damage slot `$920A` (2 a step); the two POKE files' "Invincibility" puts `RET` here (38421).

Nothing happens while `$6651` is set (the energy ball of the invulnerability pickup, or the 170 frames after a lost life). The pending combat move `$6650` is cancelled. Vitality `$6642` - A; above zero it is stored.

**At zero or below** (`$962A`, deaths 4 runs, gameover 1; not during the end, `$6652` set): SpawnShield `$9962` with 170 frames (`$AA`): the manual's invulnerability after a lost life; 10 bytes from `$5C00` reload `$6642-$664B` (vitality `$20`, the meters' shown copies, the combat speed-ups `$6644` = 1, the power meter and its minimum 0, the weapon `$664B` = 0, the fist) or, during a boss fight (`$9A59` set), only 7: the weapon and its bullets `$6649-$664B` stay (the manual: Hiro keeps his weapon against a boss). Lives `$664D` - 1 (BCD); below zero `JP $5C42`, the game over (gameover frame 2429). Else the lives' digits `$6664-$6665` (BcdToDigits `$9A11`) and `JP $8365` (the panel's numbers).

The lives as BCD: the last life shows 00 and the game ends when it is lost. ZXDB's "Infinite Lives" (`$964B`) misses this release; `$964E` = 0 (the 1 of `SUB $01`) gives it (WALKTHROUGH 6.3).

Witness: L1 827 (deaths, gameover, hiscore, play48, rooms, rzx x60, rzxroom x7).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 45 calls (`stage1/rec/deaths` 39, `stage1/rec/rooms` 5, `stage1/rec/gameover` 1) |
| Called from | `FallDamageStep`, `TouchHiro` |
| Calls | `GameOver` (tail), `PrintScore` (tail), `SpawnShield`, `BcdToDigits` |
| Reads | `$5C00`-`$5C09` (`GlobalsInit`); `$6642`-`$6652` (`Vitality`, `VitalityShown`, `ChargeStep`, `Charge` and 13 more); `$9A59` (`RunActorSteps+14`) |
| Writes | `$6642`-`$6650` (`Vitality`, `VitalityShown`, `ChargeStep`, `Charge` and 11 more) |

### `AddScore` (`$99E7`)

**Add the score record E to the score**

E = a record of the score table in Hiro's page (`$5D82`, 4 bytes: a score sprite number, then three BCD bytes, the high first): `$82` 50, `$86` 100, `$8A` 200, `$8E` 400, `$92` 700, `$96` 1000, `$9A` 2000, `$9E` 5000, `$A2` 7000 (sprite numbers 1-9); then without a sprite `$A6` 50, `$AA` 100, `$AE` 200, `$B2` 250, `$B6` 300, `$BA` 350, `$BE` 5000, `$C2` 10000, `$C6` 50000, `$CA` 20000, `$CE` 10 (the snapshot `c1/end.szx`). The sprite number goes to (IY+`$39`) of the actor taken or killed. The three bytes are added to `$6654-$6656` with DAA, the carry into `$6653`; BcdToDigits `$9A11` writes the 8 digits `$665B-$6662`. deaths 1 run.

The enemies' values (their +`$0B`) match the manual: 50 spikelice, 100 cybats / mansnakes / spidorbs, 200, 250, 300, 350, 5000 the giants.

Witness: L1 130 (bossgate, deaths, havok, play48, throw, rzx x47, rzxroom x9).

[Animation: `AddScore` at work](img/routines/AddScore.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rec/deaths` 1) |
| Called from | `CollectFragment` (tail) |
| Calls | `BcdToDigits` |
| Reads | `$5D82`-`$5D85` (`Intro48+51`); `$6653`-`$6656` (`Score`) |
| Writes | `$5F39` (`IntroScript+236`); `$6653`-`$6656` (`Score`) |

### `BcdToDigits` (`$9A11`)

**Write B BCD bytes at HL as 2B ASCII digits at DE**

HL = the BCD bytes, high first; DE = the text. Out: HL, DE past them. Callers: AddScore (the score, 4 bytes to `$665B`), LoseEnergy and LetterPickup (the lives, 1 byte to `$6664`).

Witness: L1 609 (bossgate, deaths, havok, play48, throw, rzx x63, rzxroom x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5 calls (`stage1/rec/deaths` 5) |
| Called from | `LoseEnergy`, `AddScore` |
| Reads | `$664D`-`$6656` (`Lives`, `Fragments`, `FragmentsShown`, `FireRequest` and 3 more) |
| Writes | `$665B`-`$6665` (`ScoreDigits`, `LivesDigits`) |

### `PanelWeapon` (`$FF01`)

**The weapon bar and the fragment count, when they change**

WeaponCount `$6649` against WeaponCountShown: on a change it is stored; at 0 the default weapon comes back (`$98F3` with HL = WeaponDefaultItem `$5DF8`). The bar: 16 bytes at `$7F0D` (the pixel rows of glyphs `$85`/`$86`): 16 - count rows cleared, then count rows of `$0E` (count >= 9) or `$E0`, shifted one place on odd rows; StatusLine printed (`$836B`). The status line is printed tall at the aligned Y `$B8`, so row 7 of glyphs `$85`/`$86` is never drawn: units 1 and 9 of the bar are invisible (doc 08, 8.8).

Witness: L1 2036417 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 25,067 calls, 16,458,072 t-states own (1.25 %) |
| Runs (the other recordings) | 383,349 calls (`stage1/rec/menu` 133,075, `stage1/rec/deaths` 108,017, `stage1/rec/rooms` 78,837 and 4 more) |
| Called from | `MainLoopActors`, `Im2Space` (falls into), `PanelAttrsRoom` |
| Calls | `PrintPanelLine`, `SetWeapon`, `PanelMeters` (tail), `DrawMeterPartial`, `DrawMeterGradient` |
| Reads | `$6649`-`$664F` (`WeaponCount`, `WeaponCountShown`, `Weapon`, `PauseFlag` and 3 more) |
| Writes | `$664A`-`$664F` (`WeaponCountShown`, `Weapon`, `PauseFlag`, `Lives` and 2 more); `$7F0D`-`$7F1C` (`MeterGlyphs`) |
| Ports in | `$0AFE` |
| Ports out | `$0AFE` |

### `PanelMeters` (`$FF64`)

**The charge and energy meters, when they change**

Charge `$6645` / ChargeShown to the meter at `$51F8`, Vitality `$6642` / VitalityShown to `$51E0`, each through DrawMeter.

Witness: L1 2036423 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x18).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 25,071 calls, 17,130,764 t-states own (1.30 %) |
| Runs (the other recordings) | 383,348 calls (`stage1/rec/menu` 133,074, `stage1/rec/deaths` 108,017, `stage1/rec/rooms` 78,837 and 4 more) |
| Called from | `MainLoopActors`, `PanelWeapon` (tail), `DrawMeter` (tail) |
| Calls | `DrawMeter` (falls into), `DrawMeterPartial` |
| Reads | `$6642`-`$6646` (`Vitality`, `VitalityShown`, `ChargeStep`, `Charge` and 1 more); `$FFB7`-`$FFC6` (`MeterGradient`, `MeterStrip`, `MeterPartial`, `MeterEmpty`) |
| Writes | `$51E0`-`$51E7` (screen); `$52E0`-`$52E7` (screen); `$53E0`-`$53E7` (screen); `$54E0`-`$54E7` (screen); `$55E0`-`$55E7` (screen); `$56E0`-`$56E7` (screen); 2 more ranges |

### `DrawMeter` (`$FF7C`)

**Draw a meter of value A (0-`$20`) at the screen DE: 8 bytes x 6 pixel rows from MeterStrip**

Stores A at (HL), the shown copy. MeterPartial `$FFC2` = `$FF`; C = `$BB` (full, `$20`), `$C3` (empty, 0), or `$C2` - A / 4 with MeterPartial = MeterGradient[A AND 3]. The 8 bytes from `$FF00` + C are a window on MeterStrip: full bytes, the partial one, empty ones. Six rows (D + 1 a row).

The entries `$FF90`, `$FF94`, `$FFB2` are split off because the tape loader's LD-EDGE routines and its end lie at these addresses while it runs.

Witness: L1 10240 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x15).

[Animation: `DrawMeter` at work](img/routines/DrawMeter.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 53 calls, 16,461,216 t-states own (1.25 %) |
| Runs (the other recordings) | 197 calls (`stage1/rec/deaths` 45, `stage1/rec/opt2` 45, `stage1/rec/opt3` 45 and 3 more) |
| Called from | `PanelMeters` (falls into) |
| Calls | `PanelMeters` (tail), `DrawMeterPartial` (falls into), `DrawMeterGradient` (tail), `DrawMeterNext` |
| Reads | `$6643`-`$6646` (`VitalityShown`, `ChargeStep`, `Charge`, `ChargeShown`); `$FFB7`-`$FFCA` (`MeterGradient`, `MeterStrip`, `MeterPartial`, `MeterEmpty`) |
| Writes | `$4000`-`$5190` (screen); `$51E0`-`$51FF` (screen); `$52E0`-`$52FF` (screen); `$53E0`-`$53FF` (screen); `$54E0`-`$54FF` (screen); `$55E0`-`$55FF` (screen); 5 more ranges |

### `DrawMeterPartial` (`$FF90`)

**MeterGradient[A AND 3]**

Witness: L1 784281 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, rzx x70, rzxroom x15).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 421,420 calls, 10,538,441 t-states own (0.80 %) |
| Runs (the other recordings) | 353,571 calls (`stage1/rec/c48` 353,571) |
| Called from | `PanelWeapon`, `PanelMeters`, `DrawMeter` (falls into) |
| Calls | `DrawMeterGradient` (falls into) |

### `DrawMeterGradient` (`$FF94`)

**MeterPartial = the gradient byte; C = `$C2` - A / 4**

Witness: L1 1567338 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, rzx x70, rzxroom x15).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 847,396 calls, 978,548,104 t-states own (74.09 %) |
| Runs (the other recordings) | 710,652 calls (`stage1/rec/c48` 710,652) |
| Called from | `PanelWeapon`, `DrawMeter` (tail), `DrawMeterPartial` (falls into), `DrawMeterNext` (tail) |
| Calls | `DrawMeterNext` (falls into) |
| Reads | `$6646` (`ChargeShown`); `$FFB7`-`$FFCA` (`MeterGradient`, `MeterStrip`, `MeterPartial`, `MeterEmpty`) |
| Writes | `$51E0`-`$51FF` (screen); `$52E0`-`$52FF` (screen); `$53E0`-`$53FF` (screen); `$54E0`-`$54FF` (screen); `$55E0`-`$55E7` (screen); `$55F8`-`$55FF` (screen); 3 more ranges |
| Ports in | `$7FFE` |
| Ports out | `$08FE`, `$0AFE` |

### `DrawMeterNext` (`$FFB2`)

**The next pixel row**

Witness: L1 61447 (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x70, rzxroom x15).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 322 calls, 9,281 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/c48` 3) |
| Called from | `DrawMeter`, `DrawMeterGradient` (falls into) |
| Calls | `DrawMeterGradient` (tail) |
| Ports out | `$00FE` |

### `PanelAttrsRoom` (`$FFEB`)

**Panel attributes to `$5AE0`; `$88AE` = Room; Z when in room 4**

Called by NewGame `$5CE7` (and the room change). The Z result picks the play window's colour (`$46` in room 4, the start room, else 7).

Witness: L1 14 (deaths, gameover, havok, hiscore, menu, play48, throw, c x1, opt x3, rzx x1, rzxroom x1).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 1,082 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/menu` 2, `stage1/rec/deaths` 1, `stage1/rec/gameover` 1 and 3 more) |
| Called from | `MatchCheatName`, `BuildPageTails` (tail) |
| Calls | `IntroScript` (tail), `PanelWeapon` |
| Reads | `$6BDD` (`Room`); `$FFCB`-`$FFEA` (`PanelAttrs`) |
| Writes | `$5AE0`-`$5AFF` (screen); `$88AE` (`DrawCellLayers+18`) |


## Bank 4: the AY player, the tunes, the story pages (128K only) (`src/bank4/bank4.json`)

Switchblade, Gremlin Graphics 1991: TZX block 6, loaded on a 128K only into bank 4 at `$C000` (8441 bytes): the AY
music player, its tunes and the intro's story pages; the glue at `$853F` pages it in once a frame. Its entries are
`src/bank4/<module>.asm`, written from `src/bank4/bank4.ann` by `kit/mkgame.py --part src/bank4/bank4.json`; the
recordings: `work/stage1/c1` (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk),
and `work/stage1/rec/menu`, `work/stage1/rec/opt2`, `work/stage1/rec/opt3`, `work/stage1/rec/opt4`,
`work/stage1/rec/deaths`, `work/stage1/rec/gameover`, `work/stage1/rec/rooms`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`player`](#bank-4-the-ay-player-the-tunes-the-story-pages-128k-only-player) | `$C000`-`$C03E`, `$C0D7`-`$C4B7` | 11 of 12 |
| [`state`](11-data-reference.md#bank-4-the-ay-player-the-tunes-the-story-pages-128k-only-state) | `$C03F`-`$C0D6` | 0 of 7 |
| [`tunes`](11-data-reference.md#bank-4-the-ay-player-the-tunes-the-story-pages-128k-only-tunes) | `$C4B8`-`$D0D9` | 0 of 12 |
| [`ay`](#bank-4-the-ay-player-the-tunes-the-story-pages-128k-only-ay) | `$D0DA`-`$D3CF` | 12 of 12 |
| [`story`](#bank-4-the-ay-player-the-tunes-the-story-pages-128k-only-story) | `$D3D0`-`$E0F8` | 13 of 30 |

### Bank 4: the AY player, the tunes, the story pages (128K only): player

`src/bank4/player.asm`

#### `StartTuneVector` (`$C000`)

**JP StartTune: the player's entry table, slot 0**

The entry table of the player as Daglish built it: `$C000` start a tune (A = the tune), `$C003` play one frame, `$C006` the state byte, `$C007` start an effect, `$C00A` stop. The AY rips use `$C000` and `$C003` (init and interrupt). Switchblade's glue jumps to the routines themselves, so no recording runs the table.

Not run in the keyed recordings. Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PlayFrameVector` (`$C003`)

**JP PlayFrame: the entry table, slot 1**

Not run in the keyed recordings. Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PlayEffectVector` (`$C007`)

**JP PlayEffect: the entry table, slot 2**

Not run in the keyed recordings. Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `StopMusic` (`$C00A`)

**Stop the tune: MusicState 0, then Silence**

The entry table's slot 3. No code in the game calls it (the glue silences with Silence `$D182` directly and leaves MusicState alone).

Not run in the keyed recordings. Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PlayEffect` (`$C011`)

**Start sound effect A on channel A**

A = the effect number (0-13). IY = Effects `$CF60` + 13 x A, the record: its first ten bytes are an instrument, +`$0A`/+`$0B` the tone period, +`$0C` the gate time. StartNote `$D0DA` starts it on AyChannelA (IX = `$D09D`) with HL = the period and C = the gate time, then bit 7 of the channel's flags (+`$11`) locks the channel against the tune until the release ends (EnvRelease `$D358` clears it).

Called only by the glue's JP at `$859B`, with no tune playing (MusicState 0) and the request `$8454` not `$FF`. menu runs it 10 times (the records of effects 7, 10 and 11 are read), after its title page set the toggle `$8455` to effects.

Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`stage1/rec/menu` 10) |
| Calls | `StartNote` |
| Reads | `$CFC5`-`$CFC7` (`Effects+101`); `$CFEC`-`$CFFB` (`Effects+140`); `$D0AE` (`AyChannelA+17`) |
| Writes | `$D0AE` (`AyChannelA+17`) |

#### `StartTune` (`$C0D7`)

**Start tune A: silence the AY, point the three channels at the tune's order lists, reset the state**

A = the tune (0 title, 1 in-game, 2 start; the glue passes the request AND 15). Silence `$D182` first. The three order-list pointers of TuneTable `$CCF1` + 6 x A go to the records' +`$01`/+`$02`. Per channel: the transpose, the arpeggio, the slide switch and state and the drum switch cleared; the pattern-end flag `$FF`, the repeat count 1 and the event timer 1, so the first PlayFrame reads the order list at once; every slot of SlotTables set to instrument n; the instrument pointer at Instruments `$CED4` (record 0); the order list running (`$FF`); MusicState `$FF` and DrumTimer `$FF`.

Called by the glue at `$856A` (c1: 3 times, the title, the start jingle and the in-game tune).

Witness: L1 27 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 6,036 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/rec/menu` 5, `stage1/rec/gameover` 4, `stage1/rec/opt2` 4 and 3 more) |
| Calls | `Silence` |
| Reads | `$CCF1`-`$CD02` (`TuneTable`) |
| Writes | `$C006` (`MusicState`); `$C040`-`$C0D4` (`SeqChannelA+1`, `SlotTables`, `DrumPending`, `DrumLength` and 1 more) |

#### `PlayFrame` (`$C17D`)

**Play one frame: update and write the AY, then step the three sequencers**

The glue's every-frame call (JP at `$8571` or `$8597`; its RET returns to the glue at `$8549`). AyUpdate `$D1C3` first (envelopes, vibrato, the registers). Then, if MusicState `$C006` is not 0: MusicState = the three records' +`$0D` ORed (0 when every order list has ended); while some list runs, SequenceChannel `$C1C5` for A, B and C; when all have ended, MusicState stays 1 as long as a channel still sounds (AyMixer has a channel on) and becomes 0 when all are off.

Witness: L1 49267 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2,614 calls, 597,438 t-states own (0.05 %) |
| Runs (the other recordings) | 46,653 calls (`stage1/rec/menu` 18,045, `stage1/rec/gameover` 9,844, `stage1/rec/deaths` 7,824 and 4 more) |
| Calls | `SequenceChannel` (falls into), `AyUpdate` |
| Reads | `$C006` (`MusicState`); `$C04C` (`SeqChannelA+13`); `$C06D` (`SeqChannelB+13`); `$C08E` (`SeqChannelC+13`); `$D09C` (`AyMixer`) |
| Writes | `$C006` (`MusicState`) |

#### `SequenceChannel` (`$C1C5`)

**Step one channel's sequencer by a frame: the arpeggio, the slide, the patterns**

IY = the sequencer record, IX = the AY record. UpdateArpeggio `$C390` and UpdatePortamento `$C420` first. When the pattern has ended (+`$0B` not 0): one repeat less; while repeats remain the pattern starts again, else ReadOrderList reads the order list. Then the event timer +`$0C` counts down; while it runs, one pending command byte is taken ahead (so a pattern's end mark `$FF` is seen on the frame before the last note ends); at 0 the commands are read up to the next event: a note (0-`$7D`, then its length), `$7E` (a raw period word, then the length) or `$7F` (a rest: the length only; the playing note runs on to its release).

A note: the index + the transpose (+`$0E`) picks the period from NoteTable `$D016`; with the slide on, the slide's target is the note + interval (+`$18`) and its whole change goes to +`$1E`/+`$1F`. The arpeggio state becomes `$C0` + the arpeggio, the length goes to +`$0C`, IY becomes the instrument and, unless an effect holds the channel, StartNote `$D0DA` starts it (DrumPending = the drum switch).

The order list (ReadOrderList): `$00-$7F` play pattern n (PatternAddrLo/Hi `$CC97`/`$CCC4`), `$80-$BF` the next pattern n times (low five bits), `$C0-$FB` n, m slot n (low four bits) = instrument m, `$FC` one byte skipped, `$FD` a, b three bytes skipped, `$FE` t the transpose t, `$FF` the end (+`$0D` = 0, the channel stops reading). `$FC` and `$FD` are in no tune (the code at `$C1FC` and `$C206` ran in no recording).

Witness: L1 137559 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7,764 calls, 1,958,631 t-states own (0.15 %) |
| Runs (the other recordings) | 129,795 calls (`stage1/rec/menu` 44,361, `stage1/rec/gameover` 29,454, `stage1/rec/deaths` 23,394 and 4 more) |
| Called from | `PlayFrame` (falls into) |
| Calls | `ReadPatternCommand`, `UpdateArpeggio`, `UpdatePortamento`, `StartNote` (tail) |
| Reads | `$C03F`-`$C099` (`SeqChannelA`, `SeqChannelB`, `SeqChannelC`); `$C4B8`-`$CCED` (`Patterns`, `PatternAddrLo`, `PatternAddrHi`); `$CD03`-`$CE11` (`OrderLists`, `Tune0OrderB`, `Tune0OrderC`, `Tune1OrderA`); `$CE23`-`$CE8B` (`Tune1OrderB`, `Tune1OrderC`, `Tune2OrderA`, `Tune2OrderB` and 1 more); `$CEF4`-`$CF76` (`Instruments+32`, `Effects`); `$D018`-`$D0AE` (`NoteTable+2`, `AyMixer`, `AyChannelA`); 3 more ranges |
| Writes | `$C040`-`$C0D2` (`SeqChannelA+1`, `SlotTables`, `DrumPending`) |

#### `ReadPatternCommand` (`$C31F`)

**Take one pattern command byte at DE**

DE = the pattern pointer, A = (DE) >= `$80`. `$80-$8B`: instrument slot n (low four bits): +`$07`/+`$08` = Instruments `$CED4` + the slot's offset (SlotTables). `$FF`: the pattern's end (+`$0B` = `$FF`, DE stays on it). `$8C-$BF`: the arpeggio, low four bits (the tunes use `$90` + n). `$C0` a b c: the slide on, delay a, steps b, interval c semitones; `$C1`: the slide off. `$FC`: the drum off; `$FD` a b: the drum on, a burst of a frames at noise period b (DrumLength, DrumNoise; every note of the channel from now on). Others (`$C2-$FB`, `$FE`): skipped (the RET at `$C38F` ran in no recording).

Called by SequenceChannel `$C1C5` at `$C274` (ahead) and `$C283`.

Witness: L1 11309 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 666 calls, 94,594 t-states own (0.01 %) |
| Runs (the other recordings) | 10,643 calls (`stage1/rec/menu` 4,130, `stage1/rec/gameover` 2,711, `stage1/rec/deaths` 1,334 and 4 more) |
| Called from | `SequenceChannel` |
| Reads | `$C03F` (`SeqChannelA`); `$C060` (`SeqChannelB`); `$C081` (`SeqChannelC`); `$C0A2`-`$C0C9` (`SlotTables`); `$C4B8`-`$C71B` (`Patterns`, `Pattern01`, `Pattern02`, `Pattern03` and 10 more); `$C742`-`$C7B4` (`Pattern13+39`, `Pattern14`, `Pattern15`); 6 more ranges |
| Writes | `$C046`-`$C04E` (`SeqChannelA+7`); `$C05F`-`$C0A1` (`SeqChannelA+32`, `SeqChannelB`, `SeqChannelC`); `$C0D3`-`$C0D5` (`DrumLength`, `DrumTimer`, `DrumNoise`) |

#### `UpdateArpeggio` (`$C390`)

**Step the channel's arpeggio: a list of semitone offsets played over the note**

IY = the sequencer record, IX = the AY record. Nothing while an effect holds the channel or the state +`$14` has bit 7 clear. Arpeggio 0: none (bit 7 cleared). The first frame of a note (bit 6) and the end of a looping list start the list at Arpeggios-8 + 8 x n: its header byte gives the first step's frames (bits 3-5), the steps (bits 0-2, + 1) and the loop (bit 7); the first step plays the note itself. Each later step is one byte: bits 3-7 the offset in semitones, bits 0-2 the frames. A step writes the tone period of note + offset (NoteTable) to the AY record's +`$03`/+`$04`.

Every arpeggio of the tunes is a three-note chord stepped one frame a note (header `$8A`: the note, then two offsets).

Witness: L1 137559 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7,764 calls, 1,637,082 t-states own (0.12 %) |
| Runs (the other recordings) | 129,795 calls (`stage1/rec/menu` 44,361, `stage1/rec/gameover` 29,454, `stage1/rec/deaths` 23,394 and 4 more) |
| Called from | `SequenceChannel` |
| Reads | `$C04D`-`$C053` (`SeqChannelA+14`); `$C06E`-`$C074` (`SeqChannelB+14`); `$C08F`-`$C095` (`SeqChannelC+14`); `$CE8C`-`$CECE` (`Arpeggios`); `$D048`-`$D0AF` (`NoteTable+50`, `AyMixer`, `AyChannelA`); `$D0C2` (`AyChannelB+17`); 1 more ranges |
| Writes | `$C04F`-`$C053` (`SeqChannelA+16`); `$C070`-`$C074` (`SeqChannelB+16`); `$C091`-`$C095` (`SeqChannelC+16`); `$D0A0`-`$D0A1` (`AyChannelA+3`); `$D0B4`-`$D0B5` (`AyChannelB+3`); `$D0C8`-`$D0C9` (`AyChannelC+3`) |

#### `UpdatePortamento` (`$C420`)

**Step the channel's pitch slide**

IY = the sequencer record, IX = the AY record. State +`$19`: 0 off. `$FF` (set at the note): the step = the whole change +`$1E`/+`$1F` divided by the steps +`$1B` (a signed 16 by 8 bit division, done on the magnitude), state 1. Then the delay +`$1A` counts down; after it, each frame adds the step to the AY record's slide offset +`$12`/+`$13` until the steps run out; then the offset is the whole change exactly and the state 0. StartNote `$D0DA` clears the offset at every note.

Witness: L1 137559 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7,764 calls, 278,491 t-states own (0.02 %) |
| Runs (the other recordings) | 129,795 calls (`stage1/rec/menu` 44,361, `stage1/rec/gameover` 29,454, `stage1/rec/deaths` 23,394 and 4 more) |
| Called from | `SequenceChannel` |
| Reads | `$C058` (`SeqChannelA+25`); `$C079`-`$C07F` (`SeqChannelB+25`); `$C09A`-`$C0A0` (`SeqChannelC+25`); `$D0C3`-`$D0C4` (`AyChannelB+18`); `$D0D7`-`$D0D8` (`AyChannelC+18`) |
| Writes | `$C079`-`$C07D` (`SeqChannelB+25`); `$C09A`-`$C09E` (`SeqChannelC+25`); `$D0C3`-`$D0C4` (`AyChannelB+18`); `$D0D7`-`$D0D8` (`AyChannelC+18`) |

### Bank 4: the AY player, the tunes, the story pages (128K only): ay

`src/bank4/ay.asm`

#### `StartNote` (`$D0DA`)

**Start a note or an effect on an AY channel**

IX = the AY record, IY = the instrument (Instruments or Effects), HL = the tone period, C = the gate time. Sets the instrument, the period, the gate timer, the vibrato (delay +5, the first sweep half of +6, at least 1, step +7/+8, the offset 0) and clears the slide offset; the AY record's volume +`$05` is kept, so a note or effect attacks from the volume the channel had (doc 09, 9.11). The mixer: the channel off, then tone on if flags bit 0, noise on if bit 1, or noise on for a burst when DrumPending `$C0D2` is set (DrumChannel, DrumTimer = DrumLength). Flags bit 2 (hardware envelope, no instrument) sets the AY envelope: shape = +0, period high = +4, low 0, volume `$FF` (31: bit 4 = envelope mode) and leaves the phase alone; otherwise the phase is EnvAttack `$D308`.

Called by SequenceChannel `$C1C5` (JP at `$C30F`) and PlayEffect `$C011`.

Witness: L1 13915 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 813 calls, 528,254 t-states own (0.04 %) |
| Runs (the other recordings) | 13,102 calls (`stage1/rec/menu` 4,840, `stage1/rec/gameover` 3,168, `stage1/rec/deaths` 1,861 and 4 more) |
| Called from | `PlayEffect`, `SequenceChannel` (tail) |
| Reads | `$C0D2`-`$C0D3` (`DrumPending`, `DrumLength`); `$CED9`-`$CF5F` (`Instruments+5`); `$CFC0`-`$CFC4` (`Effects+96`); `$CFE7`-`$CFF8` (`Effects+135`); `$D09C`-`$D09F` (`AyMixer`, `AyChannelA`); `$D0B1`-`$D0B3` (`AyChannelB`); 1 more ranges |
| Writes | `$C0D2`-`$C0D6` (`DrumPending`, `DrumLength`, `DrumTimer`, `DrumNoise` and 1 more); `$D09C`-`$D0D8` (`AyMixer`, `AyChannelA`) |

#### `Silence` (`$D182`)

**Silence the AY: every channel off, the volumes 0, the effect locks off**

Mixer (register 7) all off (`$3F` set in AyMixer), registers 8-10 (volumes) 0, 11 = 1, 12 and 13 = 0; the AY records' flags (+`$11`) and volumes (+`$05`) to 0. Called by StartTune `$C0D7`, StopMusic `$C00A` and the glue at `$858D` (a request `$FF` while a tune plays; ran in no recording).

Witness: L1 27 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 909 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/rec/menu` 5, `stage1/rec/gameover` 4, `stage1/rec/opt2` 4 and 3 more) |
| Called from | `StartTune` |
| Calls | `AyPrepare`, `AyDone` (tail), `WriteAyRegister` |
| Reads | `$D09C` (`AyMixer`) |
| Writes | `$D09C`-`$D0D6` (`AyMixer`, `AyChannelA`) |

#### `AyUpdate` (`$D1C3`)

**Update the three AY channels by a frame and write registers 0-10**

Nothing when AyMixer has all six channel bits set (silent). UpdateChannel `$D2D6` for A, B, C; DrumTimer counts down and at its end turns the burst's noise off in AyMixer. Then the registers: 7 = AyMixer bits 0-5; 0/1 = 2 x (A's period + vibrato offset + slide offset); 2/3 and 4/5 the same for B and C without the doubling; for a channel with noise (flags bit 1) its period's low byte becomes NoisePeriod; 6 = DrumNoise while a burst runs, else NoisePeriod, rotated right three times; 8-10 = the volumes / 8. The LD HL,`$FFBF` lines are leftovers: HL is loaded again before it is read.

Called by PlayFrame `$C17D` at every frame of the glue.

Witness: L1 49267 (c1, deaths, gameover, menu, rooms, opt x3).

[Animation: `AyUpdate` at work, frames](img/routines/AyUpdate-frames.gif)

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2,614 calls, 3,168,619 t-states own (0.24 %) |
| Runs (the other recordings) | 46,653 calls (`stage1/rec/menu` 18,045, `stage1/rec/gameover` 9,844, `stage1/rec/deaths` 7,824 and 4 more) |
| Called from | `PlayFrame` |
| Calls | `UpdateChannel`, `AyPrepare`, `AyDone` (tail), `WriteAyRegister` |
| Reads | `$C0D4`-`$C0D6` (`DrumTimer`, `DrumNoise`, `DrumChannel`); `$D09C`-`$D0D9` (`AyMixer`, `AyChannelA`, `NoisePeriod`) |
| Writes | `$C0D4` (`DrumTimer`); `$D09C` (`AyMixer`); `$D0D9` (`NoisePeriod`) |

#### `UpdateChannel` (`$D2D6`)

**One AY channel's frame: the gate timer, the vibrato, the envelope phase**

IX = the AY record. Nothing when the channel is off in AyMixer. IY = its instrument. The gate timer +`$06` counts down (0 and `$FF` stay); UpdateVibrato `$D37E`; then the phase routine at +`$0D`/+`$0E` (JP (HL)), or for a hardware-envelope instrument the wait at `$D377`.

Witness: L1 138756 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7,833 calls, 2,056,106 t-states own (0.16 %) |
| Runs (the other recordings) | 130,923 calls (`stage1/rec/menu` 45,156, `stage1/rec/gameover` 29,520, `stage1/rec/deaths` 23,463 and 4 more) |
| Called from | `AyUpdate` |
| Calls | `EnvAttack`, `EnvDecay`, `EnvSustain`, `EnvRelease`, `UpdateVibrato` |
| Reads | `$CEDD`-`$CF5F` (`Instruments+9`); `$CFC4` (`Effects+100`); `$CFEB`-`$CFF8` (`Effects+139`); `$D09C`-`$D0D5` (`AyMixer`, `AyChannelA`) |
| Writes | `$D0A3` (`AyChannelA+6`); `$D0B7` (`AyChannelB+6`); `$D0CB` (`AyChannelC+6`) |

#### `EnvAttack` (`$D308`)

**The attack: volume + instrument +0 up to the peak (+4), then the decay**

Reached through the AY record's +`$0D`/+`$0E` (JP (HL) at `$D307`).

Witness: L1 14765 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 143,259 t-states own (0.01 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/menu`, `stage1/rec/gameover`, `stage1/rec/deaths` and 4 more) |
| Called from | `UpdateChannel` |
| Reads | `$CED4`-`$CF5A` (`Instruments`); `$CFBB`-`$CFBF` (`Effects+91`); `$CFE2`-`$CFF3` (`Effects+130`); `$D0A2` (`AyChannelA+5`); `$D0B6` (`AyChannelB+5`); `$D0CA` (`AyChannelC+5`) |
| Writes | `$D0A2`-`$D0D3` (`AyChannelA+5`, `AyChannelB`, `AyChannelC`) |

#### `EnvDecay` (`$D327`)

**The decay: volume + instrument +1 down to the sustain level (+2), then the sustain**

Witness: L1 111733 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 653,029 t-states own (0.05 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/menu`, `stage1/rec/gameover`, `stage1/rec/deaths` and 4 more) |
| Called from | `UpdateChannel` |
| Reads | `$CED5`-`$CF58` (`Instruments+1`); `$CFBC`-`$CFBD` (`Effects+92`); `$CFE3`-`$CFF1` (`Effects+131`); `$D0A2` (`AyChannelA+5`); `$D0B6` (`AyChannelB+5`); `$D0CA` (`AyChannelC+5`) |
| Writes | `$D0A2`-`$D0D3` (`AyChannelA+5`, `AyChannelB`, `AyChannelC`) |

#### `EnvSustain` (`$D349`)

**The sustain: hold until the gate timer is 0, then the release**

Witness: L1 7336 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 16,090 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/menu`, `stage1/rec/deaths`, `stage1/rec/gameover` and 4 more) |
| Called from | `UpdateChannel` |
| Reads | `$D0A3` (`AyChannelA+6`); `$D0B7` (`AyChannelB+6`); `$D0CB` (`AyChannelC+6`) |
| Writes | `$D0AA`-`$D0AB` (`AyChannelA+13`); `$D0BE`-`$D0BF` (`AyChannelB+13`); `$D0D2`-`$D0D3` (`AyChannelC+13`) |

#### `EnvRelease` (`$D358`)

**The release: volume + instrument +3 down to 0, then the channel off**

At 0: the channel's off bits into AyMixer and the effect lock (flags bit 7) cleared: the tune may use channel A again.

Witness: L1 199 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | run into, not called, 435 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/menu`, `stage1/rec/gameover`, `stage1/rec/rooms` and 4 more) |
| Called from | `UpdateChannel` |
| Reads | `$CED7` (`Instruments+3`); `$CEEB`-`$CEFF` (`Instruments+23`); `$CF13` (`Instruments+63`); `$CF31` (`Instruments+93`); `$CF59` (`Instruments+133`); `$CFBE` (`Effects+94`); 2 more ranges |
| Writes | `$D09C`-`$D0D6` (`AyMixer`, `AyChannelA`) |

#### `UpdateVibrato` (`$D37E`)

**Step the channel's vibrato: the offset + the step, the step reversed at each sweep's end**

IX = the AY record, IY = the instrument. The delay +`$07` first (`$FF`: stopped). Each frame: offset +`$09`/+`$0A` += step +`$0B`/+`$0C`; at the end of a sweep (+`$08` = 0): instrument +6 = 0 goes on (an endless slide), +6 negative stops (`$FF`), else +`$08` = +6 and the step is negated.

Witness: L1 134033 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7,709 calls, 1,762,051 t-states own (0.13 %) |
| Runs (the other recordings) | 126,324 calls (`stage1/rec/menu` 42,935, `stage1/rec/gameover` 28,901, `stage1/rec/deaths` 23,180 and 4 more) |
| Called from | `UpdateChannel` |
| Reads | `$CEDA`-`$CF20` (`Instruments+6`); `$CF34`-`$CF3E` (`Instruments+96`); `$CF52`-`$CF5C` (`Instruments+126`); `$CFC1` (`Effects+97`); `$CFE8`-`$CFF5` (`Effects+136`); `$D0A4`-`$D0D1` (`AyChannelA+7`, `AyChannelB`, `AyChannelC`) |
| Writes | `$D0A4`-`$D0D1` (`AyChannelA+7`, `AyChannelB`, `AyChannelC`) |

#### `AyPrepare` (`$D3C0`)

**Leftover set-up before AY writes: C = `$FD`, HL = `$FFBF`; falls into AyDone**

Neither value is read: WriteAyRegister loads BC itself. Called by StartNote, Silence and AyUpdate.

Witness: L1 46279 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2,614 calls, 44,438 t-states own (0.00 %) |
| Runs (the other recordings) | 43,665 calls (`stage1/rec/menu` 15,057, `stage1/rec/gameover` 9,844, `stage1/rec/deaths` 7,824 and 4 more) |
| Called from | `Silence`, `AyUpdate` |
| Calls | `AyDone` (falls into) |

#### `AyDone` (`$D3C5`)

**RET: the end of a batch of AY writes**

The tail of StartNote, Silence and AyUpdate jumps here; AyPrepare falls into it.

Witness: L1 92558 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 5,228 calls, 52,280 t-states own (0.00 %) |
| Runs (the other recordings) | 87,330 calls (`stage1/rec/menu` 30,114, `stage1/rec/gameover` 19,688, `stage1/rec/deaths` 15,648 and 4 more) |
| Called from | `Silence` (tail), `AyUpdate` (tail), `AyPrepare` (falls into) |

#### `WriteAyRegister` (`$D3C6`)

**Write A to AY register E**

OUT (`$FFFD`),E then OUT (`$BFFD`),A. BC is lost, E and A kept.

Witness: L1 508961 (c1, deaths, gameover, menu, rooms, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 28,742 calls, 1,465,842 t-states own (0.11 %) |
| Runs (the other recordings) | 480,219 calls (`stage1/rec/menu` 165,607, `stage1/rec/gameover` 108,268, `stage1/rec/deaths` 86,052 and 4 more) |
| Called from | `Silence`, `AyUpdate` |
| Ports out | `$BFFD`, `$FFFD` |

### Bank 4: the AY player, the tunes, the story pages (128K only): story

`src/bank4/story.asm`

#### `StoryPages` (`$D3D0`)

**Show the intro story: boxed pages of pictures and text, each waiting for key 0 or a time**

Page 1: the screen cleared to attribute 7, a box at Y `$90` X `$30` (8 x 5 characters), Hiro's closed eyes and "FOR 10000 YEARS HE SLEPT..."; after the wait "NOW HE HAS AWAKENED" over it, the eyes open in three frames five frames apart (attribute `$42` at `$5A9C` before the last), the wait. Page 2: StoryAttrs1 at `$5882`, a box at Y 8 X 0 (7 x 19), the whole Fireblade and "AS THE NIGHT BLED CRIMSON...", the wait; a flash (border 7, StoryAttrs2, a delay of `$2000` passes, border 0), the shattered blade and "THEN THE SLAUGHTER BEGAN.", the wait. Page 3: PortraitAttrs at `$5828`, a box at Y 0 X `$0F` (18 x 15), Havok's portrait and "THEY NEVER THOUGHT HE WOULD RETURN. NOW HAVOK REIGNS THE UNDERCITY.", the wait; "I AM HIRO, ... AND BRING THE DAWN...", the wait, and 300 frames more (WaitFire, H = `$3C`). A wait is WaitFireLong: 200 frames or key 0.

Called by the hook `$85C5` (main memory) at `$85D1`: c1 once, menu and gameover twice (two games).

Witness: L1 9 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 612 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/gameover` 2, `stage1/rec/menu` 2, `stage1/rec/deaths` 1 and 3 more) |
| Calls | `StoryBoxPage`, `StoryPicturePage`, `StoryTextPage`, `StoryFrame`, `PrintStoryText`, `CopyAttrBlock` |
| Ports out | `$00FE`, `$07FE` |

#### `StoryBoxPage` (`$D450`)

**Draw a box, then a picture, a text and wait**

DE = the box's position (E = Y in pixels, D = X in half columns), B = its width, C = its height in characters. DrawStoryBox `$D479`, then falls into StoryPicturePage.

Witness: L1 27 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 53 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/rec/menu` 6, `stage1/rec/gameover` 6, `stage1/rec/opt3` 3 and 3 more) |
| Called from | `StoryPages` |
| Calls | `DrawStoryBox` |

#### `StoryPicturePage` (`$D453`)

**Print the next picture string, then the next text and wait**

Witness: L1 36 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 82 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/gameover` 2, `stage1/rec/menu` 2, `stage1/rec/opt2` 1 and 3 more) |
| Called from | `StoryPages` |
| Calls | `PrintStoryPicture` |

#### `StoryTextPage` (`$D456`)

**Print the next text string and wait for key 0 or 200 frames**

Witness: L1 45 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 156 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/gameover` 2, `stage1/rec/menu` 2, `stage1/rec/deaths` 1 and 3 more) |
| Called from | `StoryPages` |
| Calls | `PrintStoryText` |

#### `StoryFrame` (`$D45C`)

**Print the next picture string and wait 5 frames (one frame of the eyes' opening)**

Witness: L1 27 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 102 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/rec/gameover` 6, `stage1/rec/menu` 6, `stage1/rec/deaths` 3 and 3 more) |
| Called from | `StoryPages` |
| Calls | `PrintStoryPicture` |

#### `PrintStoryPicture` (`$D464`)

**Print the picture string at IY in the story font; IY = the next string**

Witness: L1 63 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7 calls, 483 t-states own (0.00 %) |
| Runs (the other recordings) | 56 calls (`stage1/rec/menu` 14, `stage1/rec/gameover` 14, `stage1/rec/opt2` 7 and 3 more) |
| Called from | `StoryPicturePage`, `StoryFrame` |
| Calls | `NextStoryString` (tail), `PrintStoryString` |

#### `PrintStoryText` (`$D46F`)

**Print the text string at IY with PrintString; IY = the next string**

Witness: L1 54 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 6 calls, 304 t-states own (0.00 %) |
| Runs (the other recordings) | 48 calls (`stage1/rec/gameover` 12, `stage1/rec/menu` 12, `stage1/rec/deaths` 6 and 3 more) |
| Called from | `StoryPages`, `StoryTextPage` |

#### `NextStoryString` (`$D475`)

**IY = HL: the string after the one printed**

Witness: L1 117 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7 calls, 548 t-states own (0.00 %) |
| Runs (the other recordings) | 56 calls (`stage1/rec/menu` 14, `stage1/rec/gameover` 14, `stage1/rec/deaths` 7 and 3 more) |
| Called from | `PrintStoryPicture` (tail) |

#### `DrawStoryBox` (`$D479`)

**Build and print a box frame of B x C characters at DE**

Builds a PrintString record in BoxString `$5B01`: the position DE, style bytes 6 and 6, the top row (`$22`, `$23` x (B - 2), `$24`), C - 2 middle rows (`$25`, a skip of B - 2 columns, `$25`), the bottom row (`$27`, `$28` x (B - 2), `$29`), rows ended by `$FF`, the record by 0, and prints it: the frame glyphs `$22-$29` of the game font.

Witness: L1 27 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 2,877 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/rec/menu` 6, `stage1/rec/gameover` 6, `stage1/rec/opt2` 3 and 3 more) |
| Called from | `StoryBoxPage` |
| Calls | `BoxEdgeRow`, `BoxMiddleRow` |

#### `BoxEdgeRow` (`$D4B2`)

**Write a box row: E, then A x (B - 2), then D**

HL = the buffer; returns HL past the row.

Witness: L1 54 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 6 calls, 1,804 t-states own (0.00 %) |
| Runs (the other recordings) | 48 calls (`stage1/rec/gameover` 12, `stage1/rec/menu` 12, `stage1/rec/opt3` 6 and 3 more) |
| Called from | `DrawStoryBox` |

#### `BoxMiddleRow` (`$D4BD`)

**Write a box middle row: `$25`, a skip of B - 2, `$25`, `$FF`**

A code below `$20` in a PrintString text moves the print position by that many columns: the box's inside is left as it is.

Witness: L1 297 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 33 calls, 2,906 t-states own (0.00 %) |
| Runs (the other recordings) | 264 calls (`stage1/rec/gameover` 66, `stage1/rec/menu` 66, `stage1/rec/opt2` 33 and 3 more) |
| Called from | `DrawStoryBox` |

#### `PrintStoryString` (`$D863`)

**Print a picture string in the font at BC**

HL = the string (Y, X, then glyph codes: 0 the end, `$FF` the next line, n glyph n - 1 of the font), BC = the font. Uses PrintPosition and PrintGlyph of the main memory; returns HL past the 0.

Witness: L1 63 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 7 calls, 61,981 t-states own (0.00 %) |
| Runs (the other recordings) | 56 calls (`stage1/rec/gameover` 14, `stage1/rec/menu` 14, `stage1/rec/deaths` 7 and 3 more) |
| Called from | `PrintStoryPicture` |
| Reads | `$D4CB`-`$D4E1` (`StoryEyesClosed`); `$D584`-`$D5D3` (`StoryEyesOpen1`, `StoryEyesOpen2`, `StoryEyesOpen3`, `StoryFireblade`); `$D61E`-`$D64F` (`StoryBladeShattered`); `$D69C`-`$D77A` (`StoryPortrait`); `$FEFF`-`$FF00` |

#### `CopyAttrBlock` (`$D890`)

**Copy a block of C x B attributes from HL to the screen at DE**

C bytes a row, B rows, DE + 32 a row.

Witness: L1 207 (c1, deaths, gameover, menu, opt x3).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 3 calls, 9,416 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/rec/menu` 6, `stage1/rec/gameover` 6, `stage1/rec/deaths` 3 and 3 more) |
| Called from | `StoryPages` |
| Reads | `$D8A3`-`$D990` (`StoryAttrs1`, `StoryAttrs2`, `PortraitAttrs`) |


## The loader's second stage (`src/stage2/stage2.json`)

Switchblade, Gremlin Graphics 1991: TZX block 3, the loader's second stage, loaded to `$609C` by the loader the
BASIC copied to `$FF00`, run from `$609C`: it loads blocks 4, 5 and (on a 128K) 6, then jumps to the bootstrap. Its
entries are `src/stage2/<module>.asm`, written from `src/stage2/stage2.ann` by `kit/mkgame.py --part
src/stage2/stage2.json`; the recordings: `work/stage1/c1` (c1: power-on on a 128K, the load at signal speed, the
menu, the intro, a short walk), and `work/stage1/rec/c48` (`$609C`-`$68A7`).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`stage2`](#the-loaders-second-stage-stage2) | `$609C`-`$68A7` | 10 of 12 |

### The loader's second stage: stage2

`src/stage2/stage2-module.asm`

#### `Stage2` (`$609C`)

**The second stage: the title scroll, the load of the game, then the bootstrap**

From LoaderStart `$FFEE` (`JP $609C`). Stage2Title `$61B2`, LoadGame `$612F`, `JP $4000` (the bootstrap, block 5).

Witness: L1 2 (c x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 44 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/c48` 1) |
| Calls | `LoadGame`, `Stage2Title` |

#### `TapeWriter` (`$60A5`)

**A leftover of the mastering tool: read the blocks, then save the whole tape (never run)**

Not called from anywhere in the tape's code. HL, DE (pushed twice) are a block's address and length (stage 2 itself, by the order). First pass: ToolInit `$FE00`, ToolRead `$FE4D` on that block, a wait (Delay `$621F`, E = 6), then ToolRead on block 4 (`$6B5C`, `$92A1`), block 5 (`$4000`, `$1191`) and, between two SwapBank calls (bank 4), block 6 (`$8000`, `$20F9`). Then ToolStep `$5FA9` with A = 1.

Second pass, the tape in its order: a header (ToolSaBytes `$FECE`, flag 0, HeaderTemplate `$68A8`, 17 bytes), its data (ToolSaveBlock `$FECC` from `$68B9`, length = the header's parameter 2), the first block (the pushed HL, DE), block 4, block 5, block 6 (swapped through bank 4 again). The same addresses and lengths as LoadGame: this is how the tape was written.

What `$FE00`, `$FE4D`, `$5FA9` do is not known (they are not on the tape); the names are guesses from the calls.

Witness: L1 0 (). Not run in the keyed recordings.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `LoadGame` (`$612F`)

**Load block 4 to `$6B5C`, block 5 to `$4000` and, on a 128K, block 6 into bank 4**

1. LoadBlock `$FF00`: IX = `$6B5C`, DE = `$92A1` (block 4, the game from `$6B5C` to `$FDFC`: just past stage 2, which ends at `$68A7`, and below the tape loader at `$FF00`; the stack is still below `$5D37`).

2. The attributes cleared to 0 (the screen goes black), LoadBlock IX = `$4000`, DE = `$1191` (block 5 into the screen: the bootstrap and glue `$4000-$4145`, the resident code `$4146-$5092`, the panel code `$5093-$5190`).

3. Has128K `$618E`: on a 48K return. On a 128K: SwapBank (A = `$14`), LoadBlock IX = `$8000`, DE = `$20F9` (block 6), SwapBank again.

Witness: L1 2 (c x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 19,275 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/c48` 1) |
| Called from | `Stage2` |
| Calls | `SwapBank`, `Has128K` |
| Reads | `$5800`-`$5AFE` (screen) |
| Writes | `$5800`-`$5AFF` (screen) |

#### `SwapBank` (`$616A`)

**Page bank A, swap `$8000-$A0F8` with `$C000-$E0F8`, page bank 0 and the 48K ROM (`$10`)**

A = the `$7FFD` value (`$14`: bank 4, the 48K BASIC ROM). DI first. SwapBlock `$617B`, then `$10` to `$7FFD`.

Witness: L1 2 (c x1). Ran only in c1 (the 128K).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 212 t-states own (0.00 %) |
| Called from | `LoadGame` |
| Calls | `SwapBlock` |
| Ports out | `$7FFD` |

#### `SwapBlock` (`$617B`)

**Swap the `$20F9` bytes at `$8000` with those at `$C000`**

Witness: L1 2 (c x1). Ran only in c1.

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 2 calls, 1,002,719 t-states own (0.08 %) |
| Called from | `SwapBank` |
| Reads | `$8000`-`$A0F8` |
| Writes | `$8000`-`$A0F8` |

#### `Has128K` (`$618E`)

**Is there a 128K's paging? Z on a 48K; the answer also goes to the bootstrap (BootIs128K `$4052`)**

Takes the byte at `$C000`, pages bank 4 (`$14`), writes its complement, pages bank 0 (`$10`) and compares: unchanged means bank 4 is another bank (a 128K, E = 1); on a 48K the port does nothing, the byte read back is the complement (E = 0). The byte is put back; E is stored at `$4052`, the operand of the bootstrap's `LD A,$01` (block 5 was just loaded there), and A = E, Z on a 48K.

Witness: L1 2 (c x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 252 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/c48` 1) |
| Called from | `LoadGame` |
| Writes | `$4052` (screen) |
| Ports out | `$7FFD` |

#### `Stage2Title` (`$61B2`)

**The loading screen: the logo, then "COPYRIGHT GREMLIN GRAPHICS 1991" scrolls out and "LOADING" in**

Attributes all `$47` (white on black). Logo `$622B` at `$4803` (26 bytes x 48 rows, Blit with A = 6 character rows); Blit's source step (`$620B`) = `$1B`, so a row of ScrollText (59 bytes) shows 32 bytes; ScrollShow, a wait (Delay E = 5, about 2.4 s), then 80 steps: every row of ScrollText is shifted 4 pixels left (RLD from its right end, a 0 nibble in) and shown again. After 320 pixels "LOADING" stands in the window.

Witness: L1 2 (c x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 1,594,451 t-states own (0.12 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/c48` 1) |
| Called from | `Stage2` |
| Calls | `ScrollShow`, `Blit`, `Delay` |
| Reads | `$5800`-`$5AFE` (screen); `$670B`-`$68A7` (`ScrollText`) |
| Writes | `$5800`-`$5AFF` (screen); `$5D31`-`$5D32`; `$620B`-`$620C` (`BlitStep+1`); `$670B`-`$68A7` (`ScrollText`) |

#### `ScrollShow` (`$61F5`)

**Show 32 bytes of each of the 7 rows of ScrollText at `$48E0`**

HL = ScrollText `$670B`, DE = `$48E0`, B = 7 rows, C = 32 bytes, A = 1 character row; falls into Blit.

Witness: L1 872 (c x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 81 calls, 4,069 t-states own (0.00 %) |
| Called from | `Stage2Title` |
| Calls | `Blit` (falls into) |

#### `Blit` (`$6200`)

**Copy A character rows of B pixel rows x C bytes from HL to the screen at DE; HL += the step at `$620B` a row**

The inner loop copies one pixel row (LDIR), adds the source step (the operand at `$620B`, 0 for the logo, `$1B` for the scroll) and goes one pixel row down (INC D); after B rows E + 32, the next character row.

Witness: L1 806 (c x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 82 calls, 590,837 t-states own (0.04 %) |
| Called from | `Stage2Title`, `ScrollShow` (falls into) |
| Reads | `$622B`-`$672A` (`Logo`, `ScrollText`); `$6746`-`$6765` (`ScrollText+59`); `$6781`-`$67A0` (`ScrollText+118`); `$67BC`-`$67DB` (`ScrollText+177`); `$67F7`-`$6816` (`ScrollText+236`); `$6832`-`$6851` (`ScrollText+295`); 1 more ranges |
| Writes | `$4803`-`$49BC` (screen); `$49E0`-`$4ABC` (screen); `$4AE0`-`$4BBC` (screen); `$4BE0`-`$4CBC` (screen); `$4CE0`-`$4DBC` (screen); `$4DE0`-`$4EBC` (screen); 2 more ranges |

#### `Delay` (`$621F`)

**Wait E x 65536 loops (about 0.49 s each at 3.5 MHz)**

Witness: L1 48 (c x2).

| | |
| --- | --- |
| Runs (c1: power-on on a 128K, the load at signal speed, the menu, the intro, a short walk) | 1 call, 10,634,187 t-states own (0.81 %) |
| Called from | `Stage2Title` |
| Writes | `$5D31`-`$5D32` |
